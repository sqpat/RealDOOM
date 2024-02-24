//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//      Preparation of data for rendering,
//      generation of lookups, caching, retrieval by name.
//

#include "i_system.h"
#include "z_zone.h"

#include "w_wad.h"

#include "doomdef.h"
#include "r_local.h"
#include "p_local.h"

#include "doomstat.h"
#include "r_data.h"
#include <dos.h>


//
// Graphics.
// DOOM graphics for walls and sprites
// is stored in vertical runs of opaque pixels (posts).
// A column is composed of zero or more posts,
// a patch or sprite is composed of zero or more columns.
// 


 
int16_t             firstflat;
int16_t             lastflat;
int16_t             numflats;

int16_t             firstpatch;
int16_t             lastpatch;
int16_t             numpatches;

int16_t             firstspritelump;
int16_t             lastspritelump;
int16_t             numspritelumps;

int16_t             numtextures;
 

byte __far*	 spritedefs_bytes;

 

uint16_t  __near *texturepatchlump_offset;
uint16_t  __near *texturecolumn_offset;
uint16_t  __near *texturedefs_offset;
uint8_t   __near *texturewidthmasks;
uint8_t   __near *textureheights;		    // uint8_t must be + 1 and then shifted to fracbits when used
uint16_t  __near *texturecompositesizes;	// uint16_t*
// for global animation
uint8_t	  __near *flattranslation; // can almost certainly be smaller
uint16_t  __near *texturetranslation;


// needed for pre rendering
//int16_t		*spritewidths;
//int16_t		 __far*spriteoffsets;
//int16_t		 __far*spritetopoffsets;


int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
uint8_t activenumpages[4]; // always gets reset to defaults at start of frame
int16_t textureLRU[4];

//uint8_t* usedcompositetexturepagemem; // defaults 00
//uint8_t __far* compositetextureoffset; //  defaults FF. high 6 bits are offset (256 byte aligned) within 16 kb page. low 2 bits are (page count-1)
//uint8_t __far* compositetexturepage; //  page index of the allocatiion

//uint8_t* usedpatchpagemem; // defaults 00
//uint8_t __far* patchpage; //  defaults FF. page index of the allocatiion
//uint8_t __far* patchoffset; //  defaults FF. high 6 bits are offset (256 byte aligned) within 16 kb page. low 2 bits are (page count-1)

//uint8_t* usedspritepagemem; // defaults 00
//uint8_t __far* spritepage;
//uint8_t __far* spriteoffset;

//uint8_t __far* flatindex;





uint8_t	 firstunusedflat = 0; // they are always 4k sized, can figure out page and offset from that. 
int32_t totalpatchsize = 0;



//
// MAPTEXTURE_T CACHING
// When a texture is first needed,
//  it counts the number of composite columns
//  required in the texture and allocates space
//  for a column directory and any new columns.
// The directory will simply point inside other patches
//  if there is only one patch in a given column,
//  but any columns with multiple patches
//  will have new column_ts generated.
//



//
// R_DrawColumnInCache
// Clip and draw a column
//  from a patch into a cached post.
//
// todo merge below
//int16_t
void
R_DrawColumnInCache
(column_t __far*     patch,
	byte __far*       cache,
	int16_t     originy,
	int16_t     cacheheight)
{
	int16_t     count;
	int16_t     position;
	byte __far*       source;
	byte __far*       dest;
	//int16_t totalsize = 0;
	dest = (byte __far*)cache + 3;
	while (patch->topdelta != 0xff)
	{ 

		source = (byte __far *)patch + 3;
		count = patch->length;
		position = originy + patch->topdelta;

		if (position < 0)
		{
			count += position;
			position = 0;
		}

		if (position + count > cacheheight)
			count = cacheheight - position;
		if (count > 0)
			FAR_memcpy(cache + position, source, count);
		//totalsize += count;

		patch = (column_t __far*)((byte  __far*)patch + patch->length + 4);
	}
	//return totalsize;
}




 

void R_GetNextCompositeBlock(int16_t tex_index) {
	uint16_t size = texturecompositesizes[tex_index];
	uint8_t blocksize = size >> 8; // num 256-sized blocks needed
	int8_t numpages;
	uint8_t texpage, texoffset;
	int16_t i;
	if (size & 0xFF) {
		blocksize++;
	}
	numpages = blocksize >> 6; // num EMS pages needed
	if (blocksize & 0x3F) {
		numpages++;
	}



	// tex_index 24 is size 32768

	// calculated the size, now lets find an open page
	if (numpages == 1) {
		// number of 256-byte block segments needed in an ems page
		uint8_t freethreshold = 64 - blocksize;
		for (i = 0; i < NUM_TEXTURE_PAGES; i++) {
			if (freethreshold >= usedcompositetexturepagemem[i]) {
				texpage = i << 2; // num pages 0
				texoffset = usedcompositetexturepagemem[i];
				usedcompositetexturepagemem[i] += blocksize;
				break;
			}
		}
#ifdef CHECK_FOR_ERRORS
		if (i == NUM_TEXTURE_PAGES) {
			I_Error("Couldn't find composite page a");
		}
#endif
	}
	else {
		// theres no deallocation so any page with 0 allocated will be followed by another 
		uint8_t numpagesminus1 = numpages - 1;

		for (i = 0; i < NUM_TEXTURE_PAGES-numpagesminus1; i++) {
			if (!usedcompositetexturepagemem[i]) {
				// empty page, we can assume the following pages are empty too
				usedcompositetexturepagemem[i] = 64;
				if (numpages >= 3) {
					usedcompositetexturepagemem[i + 1] = 64;
				}
				if (numpages == 4) {
					usedcompositetexturepagemem[i + 2] = 64;
				}
				if (blocksize & 0x3F) {
					usedcompositetexturepagemem[i + numpagesminus1] = blocksize & 0x3F;
				} else {
					usedcompositetexturepagemem[i + numpagesminus1] = 64;
				}
				texpage = (i << 2) + (numpagesminus1);
				texoffset = 0; // if multipage then its always aligned to start of its block
				


				break;
			}
		}

		#ifdef CHECK_FOR_ERRORS
		if (i == NUM_TEXTURE_PAGES - numpagesminus1) {
			I_Error("Couldn't find composite page b");
		}
		#endif		


	}


	compositetexturepage[tex_index] = texpage;
	compositetextureoffset[tex_index] = texoffset;
	

}


void R_GetNextPatchBlock(int16_t lump) {
	uint16_t size = W_LumpLength(lump);
	uint8_t blocksize = size >> 8; // num 256-sized blocks needed
	int8_t numpages;
	uint8_t texpage, texoffset;
	int16_t i;
	if (size & 0xFF) {
		blocksize++;
	}
	numpages = blocksize >> 6; // num EMS pages needed
	if (blocksize & 0x3F) {
		numpages++;
	}



	// calculated the size, now lets find an open page
	if (numpages == 1) {
		// number of 256-byte block segments needed in an ems page
		uint8_t freethreshold = 64 - blocksize;
		for (i = 0; i < NUM_PATCH_CACHE_PAGES; i++) {
			if (freethreshold >= usedpatchpagemem[i]) {
				texpage = i << 2;
				texoffset = usedpatchpagemem[i];
				usedpatchpagemem[i] += blocksize;
				break;
			}
		}
#ifdef CHECK_FOR_ERRORS
		if (i == NUM_PATCH_CACHE_PAGES) {
			I_Error("Couldn't find patch page a");
		}
#endif
	} else {
		// theres no deallocation so any page with 0 allocated will be followed by another 
		uint8_t numpagesminus1 = numpages - 1;

		for (i = 0; i < NUM_PATCH_CACHE_PAGES-(numpagesminus1) ; i++) {
			if (!usedpatchpagemem[i]) {
				// empty page, we can assume the following pages are empty too
				usedpatchpagemem[i] = 64;
				if (numpages >= 3) {
					usedpatchpagemem[i + 1] = 64;
				}
				if (numpages == 4) {
					usedpatchpagemem[i + 2] = 64;
				}


				if (blocksize & 0x3F) {
					usedpatchpagemem[i + numpagesminus1] = blocksize & 0x3F;
				} else {
					usedpatchpagemem[i + numpagesminus1] = 64;
				}

				texpage = (i << 2) + (numpagesminus1);
				texoffset = 0; // if multipage then its always aligned to start of its block

				break;
			}

		}

		#ifdef CHECK_FOR_ERRORS
		if (i == NUM_PATCH_CACHE_PAGES - numpagesminus1) {
			I_Error("Couldn't find patch page b");
		}
		#endif
 	
	}

	patchpage  [lump - firstpatch] = texpage;
	patchoffset[lump - firstpatch] = texoffset;

}



void R_GetNextSpriteBlock(int16_t lump) {
	uint16_t size = W_LumpLength(lump);
	uint8_t blocksize = size >> 8; // num 256-sized blocks needed
	int8_t numpages;
	uint8_t texpage, texoffset;
	int16_t i;
	if (size & 0xFF) {
		blocksize++;
	}
	numpages = blocksize >> 6; // num EMS pages needed
	if (blocksize & 0x3F) {
		numpages++;
	}



	// calculated the size, now lets find an open page
	if (numpages == 1) {
		// number of 256-byte block segments needed in an ems page
		uint8_t freethreshold = 64 - blocksize;
		for (i = 0; i < NUM_SPRITE_CACHE_PAGES; i++) {
			if (freethreshold >= usedspritepagemem[i]) {
				texpage = i << 2;
				texoffset = usedspritepagemem[i];
				usedspritepagemem[i] += blocksize;
				break;
			}
		}
		#ifdef CHECK_FOR_ERRORS
		if (i == NUM_SPRITE_CACHE_PAGES) {
			I_Error("Couldn't find sprite page a");
		}
		#endif
	}
	else {
		// theres no deallocation so any page with 0 allocated will be followed by another 
		uint8_t numpagesminus1 = numpages - 1;

		for (i = 0; i < NUM_SPRITE_CACHE_PAGES-numpagesminus1; i++) {
			if (!usedspritepagemem[i]) {
				// empty page, we can assume the following pages are empty too
				usedspritepagemem[i] = 64;
				if (numpages >= 3) {
					usedspritepagemem[i + 1] = 64;
				}
				if (numpages == 4) {
					usedspritepagemem[i + 2] = 64;
				}


				if (blocksize & 0x3F) {
					usedspritepagemem[i + numpagesminus1] = blocksize & 0x3F;
				}
				else {
					usedspritepagemem[i + numpagesminus1] = 64;
				}

				texpage = (i << 2) + (numpagesminus1);
				texoffset = 0; // if multipage then its always aligned to start of its block
				break;
			}

		}

		#ifdef CHECK_FOR_ERRORS
		if (i == NUM_SPRITE_CACHE_PAGES - numpagesminus1) {
			I_Error("Couldn't find sprite page b");
		}
		#endif
	}

	spritepage[lump - firstspritelump] = texpage;
	spriteoffset[lump - firstspritelump] = texoffset;

}
//
// R_GenerateComposite
// Using the texture definition,
//  the composite texture is created from the patches,
//  and each column is cached.
//



void R_GenerateComposite(uint16_t texnum, byte __far* block)
{
	texpatch_t __far*         patch;
	patch_t __far*            realpatch;
	int16_t             x;
	int16_t             x1;
	int16_t             x2;
	int16_t             i;
	column_t __far*           patchcol;
	int16_t __far*            collump;
	uint16_t __far*			colofs;
	int16_t				textureheight;
	int16_t				texturewidth;
	uint8_t				texturepatchcount;
	int16_t				patchpatch = -1;
	int16_t				patchoriginx;
	int8_t				patchoriginy;
	texture_t __far*			texture;
	int16_t				lastusedpatch = -1;
	int16_t				index;
	//uint8_t				currentpatchpage = 0;
	uint8_t pagenum;
	int16_t currentlump;
	int16_t currentRLEIndex = 0;
	int16_t nextcollumpRLE = 0;
/*
	FILE*fp;
	int8_t fname[15];
	uint16_t totalsize = 0;
	*/
	//Z_QuickMapTextureInfoPage();

	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);

	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	texturepatchcount = texture->patchcount;

	// Composite the columns together.
	collump = &(texturecolumnlumps_bytes[texturepatchlump_offset[texnum]]);
	colofs = (uint16_t __far*)&(texturecolumnofs_bytes[texturecolumn_offset[texnum] << 4]);

	Z_PushScratchFrame();
	for (i = 0; i < texturepatchcount; i++) {
		patch = &texture->patches[i];
		lastusedpatch = patchpatch;
		patchpatch = patch->patch & PATCHMASK;
		index = patch->patch - firstpatch;
		pagenum = patchpage[index];
		currentRLEIndex = 0;
		/*
		if (patchpage[index] == 0xFF) {
			size = W_LumpLength(lump);
			totalsize += size;

			patchpage[index] = oldpage = newpage;
			patchoffset[index] = totalsize & 16383;
			newpage = totalsize >> 14;


			// do we need to re-set the offset?
			if (newpage - oldpage > 3) {
				// re-base on oldpage
				Z_RemapScratchFrame(FIRST_PATCH_CACHE_LOGICAL_PAGE + oldpage);
				currentpatchpage = oldpage;
			}
			W_CacheLumpNumDirect(lump, MK_FP(SCRATCH_PAGE_SEGMENT, pageoffsets[oldpage] + patchoffset[index]));

		}

		// change the below to if calculated last page is greater than currentpatchpage + 3
		
		if (true) {
			Z_RemapScratchFrame(FIRST_PATCH_CACHE_LOGICAL_PAGE+pagenum);
			currentpatchpage = pagenum;
		}

		realpatch = (patch_t*)MK_FP(SCRATCH_PAGE_SEGMENT, pageoffsets[pagenum- currentpatchpages] + patchoffset[index]);
		*/

		// todo use cache lookup?
		// can one page be mapped twice?

		if (lastusedpatch != patchpatch) {
			realpatch = (patch_t __far*)MK_FP(SCRATCH_PAGE_SEGMENT, 0);
			W_CacheLumpNumDirect(patchpatch, (byte __far*)realpatch);
		}
		patchoriginx = patch->originx *  (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);
		patchoriginy = patch->originy;


		x1 = patchoriginx;
		x2 = x1 + (realpatch->width);

		if (x1 < 0)
			x = 0;
		else
			x = x1;

		if (x2 > texturewidth)
			x2 = texturewidth;

		currentlump = collump[currentRLEIndex];
		nextcollumpRLE = collump[currentRLEIndex + 1];
		

		for (; x < x2; x++) {
			// TODO PATCH
			while (x >= nextcollumpRLE) {
				currentRLEIndex += 2;
				currentlump = collump[currentRLEIndex];
				nextcollumpRLE += collump[currentRLEIndex + 1];
			}

			// if there is a defined lump, then there are not multiple patches for the column
			if (currentlump >= 0) {
				continue;
			}
			patchcol = (column_t  __far*)((byte  __far*)realpatch + (realpatch->columnofs[x - x1]));
			//totalsize+= 
			R_DrawColumnInCache(patchcol,
				block + colofs[x],
				patchoriginy,
				textureheight);

		}
	}

	/*
#ifdef __COMPILER_WATCOM
	sprintf(fname, "wtex%i.bin", texnum);
#else
	sprintf(fname, "gtex%i.bin", texnum);
#endif
	fp = fopen(fname, "wb");
	FAR_fwrite(block, totalsize, 1, fp);
	fclose(fp);
	*/

	Z_PopScratchFrame();
	//Z_QuickMapFlatPage();

}
uint8_t gettexturepage(uint8_t texpage, uint8_t pageoffset){
	uint8_t pagenum = pageoffset + (texpage >> 2);
	uint8_t numpages = (texpage& 0x03);
 	int16_t bestpage = -1;
	int16_t bestpageindex = -1;
	uint8_t startpage = 0;
	int16_t i;

 


	if (!numpages) {
		// one page, most common case - lets write faster code here...

		for (i = 0; i < 4; i++) {


			if (activetexturepages[i] == pagenum ) {
				// todo faster, better lru? add to all can be just one op right?
				// cast to int16_t and add 0x0101?
				textureLRU[0]++;
				textureLRU[1]++;
				textureLRU[2]++;
				textureLRU[3]++;
				textureLRU[i] = 0;

				return i;
			}

		}
		// cache miss, find highest LRU cache index
		for (i = 0; i < 4; i++) {
			if (bestpage < textureLRU[i]) {
				bestpage = textureLRU[i];
				bestpageindex = i;
			}
		}

		// figure out startpage based on LRU

		startpage = bestpageindex;

		textureLRU[0]++;
		textureLRU[1]++;
		textureLRU[2]++;
		textureLRU[3]++;
		textureLRU[startpage] = 0;

		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activenumpages[startpage]) {
			for (i = 1; i <= activenumpages[startpage]; i++) {
				activetexturepages[startpage+i] = pageswapargs[pageswapargs_rend_offset + 40+2 * (startpage+i)] = -1; // unpaged
				activenumpages[startpage+i] = 0;
			}
		}
		activenumpages[startpage] = 0;


		activetexturepages[startpage] = pageswapargs[pageswapargs_rend_offset + 40 + 2 * startpage] = pagenum; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;
		



		Z_QuickmapRenderTexture();


		return startpage;

	} else {
		int16_t j = 0;
		
		startpage = 0;

		for (i = 0; i < 4-numpages; i++) {

			int8_t currentpage = 0;
			while (currentpage <= numpages) {
				if (activetexturepages[i+ currentpage] != pagenum + currentpage) {
					break;
				}
				currentpage++;

			}

			if (currentpage <= numpages) {
				continue;
			}


			// all pages were good

			// todo faster, better lru?
			textureLRU[0]++;
			textureLRU[1]++;
			textureLRU[2]++;
			textureLRU[3]++;
			// (can we do two int16_t adds of 0x0101)
			for (j = 0; j <= numpages; j++) {
				textureLRU[i + j] = 0;
			}

			return i;
		}

		// need to page it in

		for (i = 0; i < 4-numpages; i++) {
			if (bestpage < textureLRU[i]) {
				bestpage = textureLRU[i];
				bestpageindex = i;
			}
		}


		// figure out startpage based on LRU

		startpage = bestpageindex;

		// (can we do two int16_t adds of 0x0101)
		textureLRU[0]++;
		textureLRU[1]++;
		textureLRU[2]++;
		textureLRU[3]++;

		// prep args for quickmap;

		// startpage is the ems page withing the 0x4000 block
		// pagenum is the EMS page offset within EMS texture pages



		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activenumpages[startpage] > numpages) {
			for (i = 1; i <= activenumpages[startpage]; i++) {
				activetexturepages[startpage + i] = pageswapargs[pageswapargs_rend_offset + 40 + 2 * (startpage + i)] = -1; // unpaged
				activenumpages[startpage + i] = 0;
			}
		}



		for (i = 0; i <= numpages; i++) {
			textureLRU[startpage + i] = 0;
			activetexturepages[startpage + i] = pageswapargs[pageswapargs_rend_offset + 40 + 2 * (startpage + i)] = pagenum + i;// FIRST_TEXTURE_LOGICAL_PAGE + pagenum + i;
			activenumpages[startpage + i] = numpages-i;

		}

		Z_QuickmapRenderTexture();
		//Z_QuickmapRenderTexture(startpage, numpages + 1);
		// paged in

		return startpage;

	}

}
#ifdef DETAILED_BENCH_STATS
extern int16_t benchtexturetype;
#endif

// TODO - try different algos instead of first free block for populating cache pages
// get 0x4000 offset for texture
byte __far* getpatchtexture(int16_t lump) {

	int16_t index = lump - firstpatch;
	uint8_t texpage = patchpage[index];
	uint8_t texoffset = patchoffset[index];
	byte __far* addr;
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_PATCH;
#endif

	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		R_GetNextPatchBlock(lump);

		texpage = patchpage[index];
		texoffset = patchoffset[index];

		//gettexturepage ensures the page is active
		addr = (byte __far*)MK_FP(0x4000, pageoffsets[gettexturepage(texpage, FIRST_PATCH_CACHE_LOGICAL_PAGE)] + (texoffset << 8));
		 
		W_CacheLumpNumDirect(lump, addr);
		// return
		return addr;
	} else {
		// has been allocated before. find and return
		addr = (byte __far*)MK_FP(0x4000, pageoffsets[gettexturepage(texpage, FIRST_PATCH_CACHE_LOGICAL_PAGE)] + (texoffset << 8));

		return addr;
	}
	
}


byte __far* getcompositetexture(int16_t tex_index) {
	
	uint8_t texpage = compositetexturepage[tex_index];
	uint8_t texoffset = compositetextureoffset[tex_index];
	byte __far* addr;
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_COMPOSITE;
#endif

	//addr = MK_FP(0x4000, 0);
	//R_GenerateComposite(tex_index, addr);
	//return addr;

	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		R_GetNextCompositeBlock(tex_index);
		texpage = compositetexturepage[tex_index];
		texoffset = compositetextureoffset[tex_index];
		
		//gettexturepage ensures the page is active
		addr = (byte __far*)MK_FP(0x4000, pageoffsets[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE)] + (texoffset << 8));
		// load it in

		R_GenerateComposite(tex_index, addr);
		
		return addr;
	} else {
		// has been allocated before. find and return
		
		addr = (byte __far*)MK_FP(0x4000, pageoffsets[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE)] + (texoffset << 8));
		
		return addr;
	}
}

byte __far* getspritetexture(int16_t lump) {

	int16_t index = lump - firstspritelump;
	uint8_t texpage = spritepage[index];
	uint8_t texoffset = spriteoffset[index];
	byte __far* addr;
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_SPRITE;
#endif


	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		R_GetNextSpriteBlock(lump);
		texpage = spritepage[index];
		texoffset = spriteoffset[index];

		//gettexturepage ensures the page is active
		addr = (byte __far*)MK_FP(0x4000, pageoffsets[gettexturepage(texpage, FIRST_SPRITE_CACHE_LOGICAL_PAGE)] + (texoffset << 8));

		W_CacheLumpNumDirect(lump, addr);
		// return
		return addr;
	}
	else {
		// has been allocated before. find and return
		addr = (byte __far*)MK_FP(0x4000, pageoffsets[gettexturepage(texpage, FIRST_SPRITE_CACHE_LOGICAL_PAGE)] + (texoffset << 8));

		return addr;
	}

}

/*
byte __far*
R_GetFlat
(int16_t flatlump) {
	int16_t index = flatlump - FIRST_LUMP_FLAT;
	boolean flatunloaded = true;
	byte   __far* addr;
	uint16_t usedflatindex = flatindex[index];
	uint16_t flatpageindex;
	if (usedflatindex == 0xFF) {
		// load if not loaded
		usedflatindex = flatindex[index] = firstunusedflat;
		firstunusedflat++;
		if (firstunusedflat > MAX_FLATS_LOADED) {
			I_Error("Too many flats!");
		}
		flatunloaded = true;
	}

	// flats 4k each in size. get texture takes in a size shifted 2 and num pages (0) in the bottom 2 bits
	flatpageindex = (usedflatindex & 0xFC) << 2;

	addr = MK_FP(0x4000, 
		pageoffsets[gettexturepage(flatpageindex, FIRST_FLAT_CACHE_LOGICAL_PAGE)] +
		MULT_4096[usedflatindex & 0x03]);

	// load if necessary
	if (flatunloaded) {
		
		if (flatlump < firstflat || flatlump > firstflat + numflats) {
			I_Error("bad flat? %i", flatlump);
		}

		W_CacheLumpNumDirect(flatlump, addr);
	}
	return addr;
}

*/
 
//
// R_GetColumn
//
byte __far*
R_GetColumn
(int16_t           tex,
	int16_t           col)
{
	int16_t         lump;
	uint16_t         ofs; 
	int16_t __far* texturecolumnlump;
	uint16_t __far* texturecolumnofs;
	int16_t n = 0;
	col &= texturewidthmasks[tex];

	texturecolumnofs = (uint16_t __far*)&(texturecolumnofs_bytes[texturecolumn_offset[tex] << 4]);
	ofs = texturecolumnofs[col];

	texturecolumnlump = &(texturecolumnlumps_bytes[texturepatchlump_offset[tex]]);
	
	// RLE stuff to figure out actual lump for column
	while (col >= 0) {
		lump = texturecolumnlump[n];
		col -= texturecolumnlump[n+1];
		n += 2;
	}


 
	if (lump > 0) {
		return getpatchtexture(lump) + ofs;
	} else {
		return getcompositetexture(tex) + ofs;

	}


}



