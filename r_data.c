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
#include "memory.h"


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
 

#ifdef DETAILED_BENCH_STATS
extern int16_t benchtexturetype;
extern int16_t spritecacheevictcount;
extern int16_t flatcacheevictcount;
extern int16_t patchcacheevictcount;
extern int16_t compositecacheevictcount ;

#endif
 


int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
uint8_t activenumpages[4]; // always gets reset to defaults at start of frame
int16_t textureLRU[4];


int16_t activespritepages[4]; // always gets reset to defaults at start of frame
uint8_t activespritenumpages[4]; // always gets reset to defaults at start of frame
int16_t spriteLRU[4];

 



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


 




int8_t spritecache_head = -1;
int8_t spritecache_tail = -1;

int8_t flatcache_head = -1;
int8_t flatcache_tail = -1;

int8_t patchcache_head = -1;
int8_t patchcache_tail = -1;

int8_t texturecache_head = -1;
int8_t texturecache_tail = -1;


 

// numpages is 0-3 not 1-4
void R_MarkCacheLRU(int8_t index, int8_t numpages, int8_t cachetype) {
	int8_t prev;
	int8_t next;
	int8_t pagecount;

	cache_node_t far* nodelist;
	int8_t* nodetail;
	int8_t* nodehead;
	int8_t lastpagecount;
	int8_t lastindex;

	// cachetype 2

	switch (cachetype){
		case CACHETYPE_SPRITE:
			nodetail = &spritecache_tail;
			nodehead = &spritecache_head;
			nodelist = spritecache_nodes;
			break;
		case CACHETYPE_FLAT:
			nodetail = &flatcache_tail;
			nodehead = &flatcache_head;
			nodelist = flatcache_nodes;
			break;
		case CACHETYPE_PATCH:
 			nodetail = &patchcache_tail;
			nodehead = &patchcache_head;
			nodelist = patchcache_nodes;
			break;
		case CACHETYPE_COMPOSITE:
 			nodetail = &texturecache_tail;
			nodehead = &texturecache_head;
			nodelist = texturecache_nodes;
			break;
			
	}


	if (index == *nodehead) {
		return;
	}
	
	pagecount = nodelist[index].pagecount;
	if (pagecount == 1){
		// special case: 
		//updating element sharing the same page as the last page of a
		//multi-page allocation. to avoid eviction complications 
		//(from cases where one is in conventional memory and others
		// arent, and their lru statuses are different)
		//we are going to update the entire multi-page block as LRU
		lastpagecount = 0;
		
		while (nodelist[index].pagecount > lastpagecount){
		//todo head or tail or -1? want to avoid going out of bounds
			lastpagecount = nodelist[index].pagecount;

			//if (index == *nodetail){
			//	break;
			//}

			// shouldnt happen? todo remove later
			if (nodelist[index].prev == -1){
				// hit the end i guess?
				goto foundstartpage;
			}
			lastindex = index;			
			index = nodelist[index].prev;
		}
		index = lastindex;
		
		foundstartpage:
		// index now equal to the beginning of the multipage allocation
		pagecount = nodelist[index].pagecount;
		numpages = pagecount - 1;
		
	}

	if (numpages){
		pagecount = numpages + 1;
	}



	while (true){
		prev = nodelist[index].prev;
		next = nodelist[index].next;

		if (prev != -1) {
			nodelist[prev].next = next;
		} else {
			// no prev; may be a new allocation.
			if (*nodetail == -1){
				// first allocation. being set to 0
				*nodetail = index;
			} else {
				// it has a next, which means its allocated. tail becomes next
				if (next != -1){
					*nodetail = next;
				}
			}
		}

		if (next != -1) {
			nodelist[next].prev = prev;
		}

		// this says head has no prev!
		nodelist[index].prev = *nodehead;
		nodelist[index].next = -1;
		if (*nodehead != -1) {
			nodelist[*nodehead].next = index;
		}
		*nodehead = index;

		nodelist[index].pagecount = pagecount;

		if (numpages == 0)
			break; // done

		// continue to the next one
		numpages--;
		pagecount--;
		
		index++; // multipage are always consecutive pages...

	}




	 
}


uint8_t usedcompositetexturepagemem[NUM_TEXTURE_PAGES];
uint8_t usedpatchpagemem[NUM_PATCH_CACHE_PAGES];
uint8_t usedspritepagemem[NUM_SPRITE_CACHE_PAGES];


extern int8_t allocatedflatsperpage[NUM_FLAT_CACHE_PAGES];

// in this case numpages is 1-4, not 0-3
int8_t R_EvictCacheEMSPage(int8_t numpages, int8_t cachetype){
	int8_t evictedpage;
	int8_t j;
	uint8_t currentpage;
	int16_t k;
	int8_t offset;
	int8_t remainingpages;
	int8_t next, prev;
	cache_node_t far* nodelist;
	int8_t* nodetail;
	int8_t* nodehead;
	int8_t maxcachesize;
	int16_t maxitersize;
	uint8_t far* cacherefpage;
	uint8_t far* cacherefoffset;
	uint8_t far* usedcacherefpage;

	//I_Error("evicting %i", cachetype);

	switch (cachetype){
		case CACHETYPE_SPRITE:
			nodetail = &spritecache_tail;
			nodehead = &spritecache_head;
			nodelist = spritecache_nodes;
			maxcachesize = NUM_SPRITE_CACHE_PAGES;
			maxitersize = MAX_SPRITE_LUMPS;
			cacherefpage = spritepage;
			cacherefoffset = spriteoffset;
			usedcacherefpage = usedspritepagemem;
			#ifdef DETAILED_BENCH_STATS
			spritecacheevictcount++;
			#endif
	break;
		case CACHETYPE_FLAT:
			nodetail = &flatcache_tail;
			nodehead = &flatcache_head;
			nodelist = flatcache_nodes;
			maxcachesize = NUM_FLAT_CACHE_PAGES;
			maxitersize = MAX_FLATS;
			#ifdef DETAILED_BENCH_STATS
			flatcacheevictcount++;
			#endif
			break;
		case CACHETYPE_PATCH:
 			nodetail = &patchcache_tail;
			nodehead = &patchcache_head;
			nodelist = patchcache_nodes;
			maxcachesize = NUM_PATCH_CACHE_PAGES;
			maxitersize = MAX_PATCHES;
			cacherefpage = patchpage;
			cacherefoffset = patchoffset;
			usedcacherefpage = usedpatchpagemem;
			#ifdef DETAILED_BENCH_STATS
			patchcacheevictcount++;
			#endif
			break;
		case CACHETYPE_COMPOSITE:
 			nodetail = &texturecache_tail;
			nodehead = &texturecache_head;
			nodelist = texturecache_nodes;
			maxcachesize = NUM_TEXTURE_PAGES;
			maxitersize = MAX_TEXTURES;
			cacherefpage = compositetexturepage;
			cacherefoffset = compositetextureoffset;
			usedcacherefpage = usedcompositetexturepagemem;
			#ifdef DETAILED_BENCH_STATS
			compositecacheevictcount++;
			#endif

//			I_Error("confirm a");
			break;
	}
	 
	evictedpage = *nodetail;

	// for multipage evictions, need to make sure we are not trying to 
	// evict from the end of the cache, without enough room
	while ((maxcachesize-evictedpage) < numpages){
		evictedpage = nodelist[evictedpage].next;
 	}


	//I_Error("out of sprite");
	// need to evict at least numpages pages
	// we'll remove the tail, up to numpages...
	// if thats part of a multipage allocations, we'll remove that until the end
	// this can potentially remove something in an active page. 

	//printout();


	// todo update cache list including numpages situation

	for (j = 0; j < numpages+remainingpages; j++){
		currentpage = evictedpage+j;
		remainingpages = nodelist[currentpage].pagecount;
		
		if (remainingpages)
			remainingpages--;

		next = nodelist[currentpage].next;
		prev = nodelist[currentpage].prev;

		if (next != -1){
			nodelist[next].prev = prev;
		}

		if (prev != -1){
			nodelist[prev].next = next;
		}

		nodelist[currentpage].prev = -1;
		nodelist[currentpage].next = -1;
		nodelist[currentpage].pagecount = 0;

		if (currentpage == *nodetail){
			*nodetail = next;
		}
		if (currentpage == *nodehead){
			*nodehead = prev;
			 
			 // ok this happens... its gross, but basically when we need to evict to allocate multiple consecutive
			 // pages and it turns out that the least recently used and most recently used end up in the same
			 // contiguous block. Im not sure this is actually going to break anything, it's just a rare bad luck case
			 // of eviciting a recently used item. Just need to make sure to handle the node head right
		}



		// if its an active page... do we have to do anything? 
	}

	// handles the remainingpages thing - resets numpages
	numpages = j;

//todo clear cache data per type
	switch (cachetype){
		case CACHETYPE_SPRITE:
		case CACHETYPE_PATCH:
		case CACHETYPE_COMPOSITE:

			for (offset = 0; offset < numpages; offset++){
				currentpage = evictedpage + offset;
				for (k = 0; k < maxitersize; k++){
					if ((cacherefpage[k] >> 2) == currentpage){
						cacherefpage[k] = 0xFF;
						cacherefoffset[k] = 0xFF;
						//I_Error("deleted a page");
					}
				}
				usedcacherefpage[currentpage] = 0;

			}	
			break;
		case CACHETYPE_FLAT:

			allocatedflatsperpage[evictedpage] = 1;
			for (k = 0; k < maxitersize; k++){
				
				if ((flatindex[k] >> 2) == evictedpage){
					flatindex[k] = 0xFF;
				}

 
			}
 
			break;
	}

	return evictedpage;
}


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
 	//int16_t totalsize = 0;
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
	if (size == 0)
		return; // why does this happen...

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
				goto foundonepage;
			}
		}
		
		i = R_EvictCacheEMSPage(numpages, CACHETYPE_COMPOSITE);

		foundonepage:
		texpage = i << 2; // num pages 0
		texoffset = usedcompositetexturepagemem[i];
		usedcompositetexturepagemem[i] += blocksize;

	}
	else {
		// theres no deallocation so any page with 0 allocated will be followed by another 
		uint8_t numpagesminus1 = numpages - 1;

		for (i = 0; i < NUM_TEXTURE_PAGES-numpagesminus1; i++) {
			if (!usedcompositetexturepagemem[i]) {
				// need to check following pages for emptiness, or else after evictions weird stuff can happen
				if (!usedcompositetexturepagemem[i+1]) {
					if (numpagesminus1 < 2 || (!usedcompositetexturepagemem[i+2])) {
						if (numpagesminus1 < 3 || (!usedcompositetexturepagemem[i+3])) {					
							goto foundmultipage;
						}
					}
				}
			}
		}

		i = R_EvictCacheEMSPage(numpages, CACHETYPE_COMPOSITE);

		foundmultipage:

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
				goto foundonepage;


			}
		}

		i = R_EvictCacheEMSPage(numpages, CACHETYPE_PATCH);

		foundonepage:
		texpage = i << 2;
		texoffset = usedpatchpagemem[i];
		usedpatchpagemem[i] += blocksize;
	} else {
		// theres no deallocation so any page with 0 allocated will be followed by another 
		uint8_t numpagesminus1 = numpages - 1;

		for (i = 0; i < NUM_PATCH_CACHE_PAGES-numpagesminus1; i++) {
			if (!usedpatchpagemem[i]) {
				// need to check following pages for emptiness, or else after evictions weird stuff can happen
				if (!usedpatchpagemem[i+1]) {
					if (numpagesminus1 < 2 || (!usedpatchpagemem[i+2])) {
						if (numpagesminus1 < 3 || (!usedpatchpagemem[i+3])) {					
							goto foundmultipage;
						}
					}
				}
			}
		}

		i = R_EvictCacheEMSPage(numpages, CACHETYPE_PATCH);

		foundmultipage:
		
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
				goto foundonepage;
			}
		}

		// nothing found, evict cache
		i = R_EvictCacheEMSPage(numpages, CACHETYPE_SPRITE);
		
		foundonepage:
		
		texpage = i << 2;
		texoffset = usedspritepagemem[i];
		usedspritepagemem[i] += blocksize;
	}
	else {

		uint8_t numpagesminus1 = numpages - 1;
		for (i = 0; i < NUM_SPRITE_CACHE_PAGES-numpagesminus1; i++) {
			if (!usedspritepagemem[i]) {
				// need to check following pages for emptiness, or else after evictions weird stuff can happen
				if (!usedspritepagemem[i+1]) {
					if (numpagesminus1 < 2 || (!usedspritepagemem[i+2])) {
						if (numpagesminus1 < 3 || (!usedspritepagemem[i+3])) {					
							goto foundmultipage;
						}
					}
				}
			}
		}

		// nothing found, evict cache
		i = R_EvictCacheEMSPage(numpages, CACHETYPE_SPRITE);
		foundmultipage:

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

extern int8_t current5000State;

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
	int16_t currentlump;
	int16_t currentRLEIndex = 0;
	int16_t nextcollumpRLE = 0;
/*
	FILE*fp;
	int8_t fname[15];
	uint16_t totalsize = 0;
	*/
	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);

	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	texturepatchcount = texture->patchcount;

	// Composite the columns together.
	collump = &(texturecolumnlumps_bytes[texturepatchlump_offset[texnum]]);

	// check which 64k page this lives in
	if (texturecolumn_offset[texnum] >= 0x0800) {
		colofs = (uint16_t __far*)&(texturecolumnofs_bytes_2[(texturecolumn_offset[texnum] - 0x0800) << 4]);
	}
	else {
		colofs = (uint16_t __far*)&(texturecolumnofs_bytes_1[texturecolumn_offset[texnum] << 4]);
	}

	Z_QuickmapScratch_7000();



	for (i = 0; i < texturepatchcount; i++) {
		patch = &texture->patches[i];
		lastusedpatch = patchpatch;
		patchpatch = patch->patch & PATCHMASK;
		index = patch->patch - firstpatch;
		currentRLEIndex = 0;
		 


		if (lastusedpatch != patchpatch) {
			realpatch = (patch_t __far*) MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0);
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

	Z_QuickMapRender7000();
	//Z_QuickMapFlatPage();

}
uint8_t gettexturepage(uint8_t texpage, uint8_t pageoffset, int8_t cachetype){
	uint8_t realtexpage = texpage >> 2;
	uint8_t pagenum = pageoffset + realtexpage;
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

				R_MarkCacheLRU(realtexpage, 0, cachetype);
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
				activetexturepages[startpage+i] = pageswapargs[pageswapargs_rend_offset +2 * (startpage+i)] = -1; // unpaged
				activenumpages[startpage+i] = 0;
			}
		}
		activenumpages[startpage] = 0;


		activetexturepages[startpage] = pageswapargs[pageswapargs_rend_offset  + 2 * startpage] = pagenum; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;
		


		R_MarkCacheLRU(realtexpage, 0, cachetype);

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

			R_MarkCacheLRU(realtexpage, numpages, cachetype);
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

		// startpage is the ems page withing the 0x9000 block
		// pagenum is the EMS page offset within EMS texture pages



		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activenumpages[startpage] > numpages) {
			for (i = 1; i <= activenumpages[startpage]; i++) {
				activetexturepages[startpage + i] = pageswapargs[pageswapargs_rend_offset +  2 * (startpage + i)] = -1; // unpaged
				activenumpages[startpage + i] = 0;
			}
		}



		for (i = 0; i <= numpages; i++) {
			textureLRU[startpage + i] = 0;
			activetexturepages[startpage + i] = pageswapargs[pageswapargs_rend_offset +  2 * (startpage + i)] = pagenum + i;// FIRST_TEXTURE_LOGICAL_PAGE + pagenum + i;
			activenumpages[startpage + i] = numpages-i;

		}

		R_MarkCacheLRU(realtexpage, numpages, cachetype);
		Z_QuickmapRenderTexture();

		// paged in

		return startpage;

	}

}


uint8_t getspritepage(uint8_t texpage, uint8_t pageoffset) {
	uint8_t realtexpage = texpage >> 2;
	uint8_t pagenum = pageoffset + realtexpage;
	uint8_t numpages = (texpage & 0x03);
	int16_t bestpage = -1;
	int16_t bestpageindex = -1;
	uint8_t startpage = 0;
	int16_t i;

	if (!numpages) {
		// one page, most common case - lets write faster code here...

		for (i = 0; i < 4; i++) {


			if (activespritepages[i] == pagenum) {
				// todo faster, better lru? add to all can be just one op right?
				// cast to int16_t and add 0x0101?
				spriteLRU[0]++;
				spriteLRU[1]++;
				spriteLRU[2]++;
				spriteLRU[3]++;
				spriteLRU[i] = 0;
				R_MarkCacheLRU(realtexpage, 0, CACHETYPE_SPRITE);

				return i;
			}

		}
		// cache miss, find highest LRU cache index
		for (i = 0; i < 4; i++) {
			if (bestpage < spriteLRU[i]) {
				bestpage = spriteLRU[i];
				bestpageindex = i;
			}
		}

		// figure out startpage based on LRU

		startpage = bestpageindex;

		spriteLRU[0]++;
		spriteLRU[1]++;
		spriteLRU[2]++;
		spriteLRU[3]++;
		spriteLRU[startpage] = 0;

		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activespritenumpages[startpage]) {
			for (i = 1; i <= activespritenumpages[startpage]; i++) {
				activespritepages[startpage + i] = pageswapargs[pageswapargs_spritecache_offset + 2 * (startpage + i)] = -1; // unpaged

				activespritenumpages[startpage + i] = 0;
			}
		}
		activespritenumpages[startpage] = 0;


		activespritepages[startpage] = pageswapargs[pageswapargs_spritecache_offset + 2 * startpage] = pagenum; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;

		Z_QuickMapSpritePage();
		R_MarkCacheLRU(realtexpage, 0, CACHETYPE_SPRITE);


		return startpage;

	}
	else {
		int16_t j = 0;

		startpage = 0;

		for (i = 0; i < 4 - numpages; i++) {

			int8_t currentpage = 0;
			while (currentpage <= numpages) {
				if (activespritepages[i + currentpage] != pagenum + currentpage) {
					break;
				}
				currentpage++;

			}

			if (currentpage <= numpages) {
				continue;
			}


			// all pages were good

			// todo faster, better lru?
			spriteLRU[0]++;
			spriteLRU[1]++;
			spriteLRU[2]++;
			spriteLRU[3]++;
			// (can we do two int16_t adds of 0x0101)
			for (j = 0; j <= numpages; j++) {
				spriteLRU[i + j] = 0;
			}
			R_MarkCacheLRU(realtexpage, numpages, CACHETYPE_SPRITE);

			return i;
		}

		// need to page it in

		for (i = 0; i < 4 - numpages; i++) {
			if (bestpage < spriteLRU[i]) {
				bestpage = spriteLRU[i];
				bestpageindex = i;
			}
		}


		// figure out startpage based on LRU

		startpage = bestpageindex;

		// (can we do two int16_t adds of 0x0101)
		spriteLRU[0]++;
		spriteLRU[1]++;
		spriteLRU[2]++;
		spriteLRU[3]++;

		// prep args for quickmap;

		// startpage is the ems page withing the 0x9000 block
		// pagenum is the EMS page offset within EMS texture pages



		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activespritenumpages[startpage] > numpages) {
			for (i = 1; i <= activespritenumpages[startpage]; i++) {
				activespritepages[startpage + i] = pageswapargs[pageswapargs_spritecache_offset + 2 * (startpage + i)] = -1; // unpaged
				activespritenumpages[startpage + i] = 0;
			}
		}



		for (i = 0; i <= numpages; i++) {
			spriteLRU[startpage + i] = 0;
			activespritepages[startpage + i] = pageswapargs[pageswapargs_spritecache_offset + 2 * (startpage + i)] = pagenum + i;
			activespritenumpages[startpage + i] = numpages - i;

		}

		Z_QuickMapSpritePage();

		// paged in
		R_MarkCacheLRU(realtexpage, numpages, CACHETYPE_SPRITE);

		return startpage;

	}

}



// TODO - try different algos instead of first free block for populating cache pages
// get 0x9000 offset for texture
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
		addr = (byte __far*)MK_FP(0x9000, pageoffsets[gettexturepage(texpage, FIRST_PATCH_CACHE_LOGICAL_PAGE, CACHETYPE_PATCH)] + (texoffset << 8));
 
		W_CacheLumpNumDirect(lump, addr);
		// return
		return addr;
	} else {
		// has been allocated before. find and return
		addr = (byte __far*)MK_FP(0x9000, pageoffsets[gettexturepage(texpage, FIRST_PATCH_CACHE_LOGICAL_PAGE, CACHETYPE_PATCH)] + (texoffset << 8));

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


	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		R_GetNextCompositeBlock(tex_index);
		texpage = compositetexturepage[tex_index];
		texoffset = compositetextureoffset[tex_index];
		
		//gettexturepage ensures the page is active
		addr = (byte __far*)MK_FP(0x9000, pageoffsets[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE, CACHETYPE_COMPOSITE)] + (texoffset << 8));
		// load it in
		R_GenerateComposite(tex_index, addr);
		

		return addr;
	} else {
		// has been allocated before. find and return
		
		addr = (byte __far*)MK_FP(0x9000, pageoffsets[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE, CACHETYPE_COMPOSITE)] + (texoffset << 8));
		
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
		addr = (byte __far*)MK_FP(0x6800, pageoffsets[getspritepage(texpage, FIRST_SPRITE_CACHE_LOGICAL_PAGE)] + (texoffset << 8));
		W_CacheLumpNumDirect(lump, addr);
		// return
		return addr;
	}
	else {
		// has been allocated before. find and return
		addr = (byte __far*)MK_FP(0x6800, pageoffsets[getspritepage(texpage, FIRST_SPRITE_CACHE_LOGICAL_PAGE)] + (texoffset << 8));
		//I_Error("\nb %Fp  %hhu %hhu %u", addr, texpage, texoffset, pageoffsets[getspritepage(texpage, FIRST_SPRITE_CACHE_LOGICAL_PAGE)]);
		return addr;
	}

} 
 
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
	int16_t n = 0;
	col &= texturewidthmasks[tex];

	// check which 64k page this lives in
	if (texturecolumn_offset[tex] >= 0x0800) {
		ofs = ((uint16_t __far*)&(texturecolumnofs_bytes_2[(texturecolumn_offset[tex] - 0x0800) << 4]))[col];
	}
	else {
		ofs = ((uint16_t __far*)&(texturecolumnofs_bytes_1[texturecolumn_offset[tex] << 4]))[col];
	}

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



