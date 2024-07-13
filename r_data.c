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
#include "m_memory.h"
#include "m_near.h"


//
// Graphics.
// DOOM graphics for walls and sprites
// is stored in vertical runs of opaque pixels (posts).
// A column is composed of zero or more posts,
// a patch or sprite is composed of zero or more columns.
// 

 

#ifdef DETAILED_BENCH_STATS
extern int16_t benchtexturetype;
extern int16_t spritecacheevictcount;
extern int16_t flatcacheevictcount;
extern int16_t patchcacheevictcount;
extern int16_t compositecacheevictcount ;

#endif
 



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


 






 

// numpages is 0-3 not 1-4
void __near R_MarkCacheLRU(int8_t index, int8_t numpages, int8_t cachetype) {
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

/*

int setval = 0;
uint16_t thechecksum = 0;
int cachecount = 0;
int origcachecount = 0;

int8_t checkchecksum(int16_t l){
	uint16_t checkchecksum = 0;
	uint16_t i;
	uint16_t __far* data =  MK_FP(0x9000, 0);
	if (setval < 2){
		return 0;
	}
	for (i = 0; i <32767; i++){
		checkchecksum += data[i];
	}

	//if (checkchecksum != 40411u){
	if (checkchecksum != thechecksum){
		I_Error("gametic is %li %u %u %i %i %i", gametic, thechecksum, checkchecksum, l, cachecount, origcachecount);
		//return 1;
	}
	return 0;

}
*/


uint8_t usedcompositetexturepagemem[NUM_TEXTURE_PAGES];
uint8_t usedpatchpagemem[NUM_PATCH_CACHE_PAGES];
uint8_t usedspritepagemem[NUM_SPRITE_CACHE_PAGES];


extern int8_t allocatedflatsperpage[NUM_FLAT_CACHE_PAGES];

// in this case numpages is 1-4, not 0-3
int8_t __near R_EvictCacheEMSPage(int8_t numpages, int8_t cachetype){
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
	uint8_t __far* cacherefpage;
	uint8_t __far* cacherefoffset;
	uint8_t __near* usedcacherefpage;

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
void __near R_DrawColumnInCache (column_t __far* patchcol, segment_t currentdestsegment, int16_t patchoriginy, int16_t textureheight) {
	while (patchcol->topdelta != 0xff) { 

		byte __far * source = (byte __far *)patchcol + 3;
		uint16_t     count = patchcol->length;
		int16_t     position = patchoriginy + patchcol->topdelta;


		patchcol = (column_t __far*)((byte  __far*)patchcol + count + 4);

		if (position < 0)
		{
			count += position;
			position = 0;
		}

		if (position + count > textureheight)
			count = textureheight - position;
		if (count > 0)
			FAR_memcpy(MK_FP(currentdestsegment, position), source, count);


	}
	//return totalsize;
}




 

void __near R_GetNextCompositeBlock(int16_t tex_index) {
	uint16_t size = texturecompositesizes[tex_index];
	uint8_t blocksize = size >> 8; // num 256-sized blocks needed
	int8_t numpages;
	uint8_t texpage, texoffset;
	int16_t i;
/*
	if (size == 0){
		return; // why does this happen...
	}
	*/
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


void __near R_GetNextPatchBlock(int16_t lump, uint16_t size) {
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



void __near R_GetNextSpriteBlock(int16_t lump) {
	uint16_t size = spritetotaldatasizes[lump-firstspritelump];
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
	} else {

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

#define realpatch7000  ((patch_t __far *)  MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0))

void __near R_GenerateComposite(uint16_t texnum, segment_t block_segment)
{
	texpatch_t __far*         patch;
	//patch_t __far*            realpatch;
	int16_t             x;
	int16_t             x1;
	int16_t             x2;
	int16_t             i;
	column_t __far*           patchcol;
	int16_t __far*            collump;
	uint8_t				textureheight;
	uint8_t				usetextureheight;
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
	segment_t currentdestsegment;
	segment_t testsegment;

/*
	FILE*fp;
	int8_t fname[15];
	uint16_t totalsize = 0;
	*/
	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);

	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	usetextureheight = textureheight + ((16 - (textureheight &0xF)) &0xF);
	usetextureheight = usetextureheight >> 4;
	texturepatchcount = texture->patchcount;

	// Composite the columns together.
	collump = &(texturecolumnlumps_bytes[texturepatchlump_offset[texnum]]);

	// check which 64k page this lives in

	Z_QuickMapScratch_7000();



	for (i = 0; i < texturepatchcount; i++) {

		patch = &texture->patches[i];
		lastusedpatch = patchpatch;
		patchpatch = patch->patch & PATCHMASK;
		index = patch->patch - firstpatch;
		currentRLEIndex = 0;


		if (lastusedpatch != patchpatch) {
			W_CacheLumpNumDirect(patchpatch, (byte __far*)realpatch7000);
		}
		patchoriginx = patch->originx *  (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);
		patchoriginy = patch->originy;


		x1 = patchoriginx;
		x2 = x1 + (realpatch7000->width);

		if (x1 < 0)
			x = 0;
		else
			x = x1;

		if (x2 > texturewidth)
			x2 = texturewidth;

		currentlump = collump[currentRLEIndex];
		nextcollumpRLE = collump[currentRLEIndex + 1] & 255;

		// increment starting texel index

		currentdestsegment = block_segment;

		// skip if x is 0, otherwise evaluate till break
		if (x){
			int16_t innercurrentRLEIndex = 0;
			int16_t innercurrentlump = collump[0];
			uint8_t innernextcollumpRLE = collump[1] & 255;
			uint8_t currentx = 0;
			uint8_t diffpixels = 0;

			while (true){ 
				if ((currentx + innernextcollumpRLE) < x){
					if (innercurrentlump == -1){
						diffpixels += (innernextcollumpRLE);
					}
					currentx += innernextcollumpRLE;
					innercurrentRLEIndex += 2;
					innercurrentlump = collump[innercurrentRLEIndex];
					innernextcollumpRLE = ((collump[innercurrentRLEIndex + 1]) & 255);
					continue;
				} else {
					if (innercurrentlump == -1){
						diffpixels += ((x - currentx));
					}
					break;
				}

			}
			currentdestsegment += FastMul8u8u(usetextureheight, diffpixels);
		}





		for (; x < x2; x++) {
			while (x >= nextcollumpRLE) {
				currentRLEIndex += 2;
				currentlump = collump[currentRLEIndex];
				nextcollumpRLE += collump[currentRLEIndex + 1] & 255;
			}

			// if there is a defined lump, then there are not multiple patches for the column
			if (currentlump >= 0) {
				continue;
			}
			
			patchcol = MK_FP(0x7000, realpatch7000->columnofs[x - x1]);

			// inlined R_DrawColumninCache
			R_DrawColumnInCache(patchcol,
				currentdestsegment,
				patchoriginy,
				textureheight);

				// TODO this should be inlined but watcom sucks at big functions - do later in asm

/*
			while (patchcol->topdelta != 0xff) { 

				byte __far * source = (byte __far *)patchcol + 3;
				uint16_t     count = patchcol->length;
				int16_t     position = patchoriginy + patchcol->topdelta;


				patchcol = (column_t __far*)((byte  __far*)patchcol + count + 4);

				if (position < 0)
				{
					count += position;
					position = 0;
				}

				if (position + count > textureheight)
					count = textureheight - position;
				if (count > 0)
					FAR_memcpy(MK_FP(currentdestsegment, position), source, count);


			}
			*/

			currentdestsegment += usetextureheight;

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

}




uint8_t __near gettexturepage(uint8_t texpage, uint8_t pageoffset, int8_t cachetype){
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
				activetexturepages[startpage+i] = pageswapargs[pageswapargs_rend_offset + ((startpage+i) << 1)] = -1; // unpaged
				activenumpages[startpage+i] = 0;
			}
		}
		activenumpages[startpage] = 0;


		activetexturepages[startpage] = pageswapargs[pageswapargs_rend_offset  + ( startpage << 1)] = pagenum; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;
		


		R_MarkCacheLRU(realtexpage, 0, cachetype);
		Z_QuickMapRenderTexture();
		cachedlump = -1;
		cachedtex = -1;
		cachedlump2 = -1;
		cachedtex2 = -1;
	

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
				activetexturepages[startpage + i] = pageswapargs[pageswapargs_rend_offset +   ((startpage + i) << 1)] = -1; // unpaged
				activenumpages[startpage + i] = 0;
			}
		}



		for (i = 0; i <= numpages; i++) {
			textureLRU[startpage + i] = 0;
			activetexturepages[startpage + i] = pageswapargs[pageswapargs_rend_offset +  ((startpage + i)<<1)] = pagenum + i;// FIRST_TEXTURE_LOGICAL_PAGE + pagenum + i;
			activenumpages[startpage + i] = numpages-i;

		}

		R_MarkCacheLRU(realtexpage, numpages, cachetype);
		Z_QuickMapRenderTexture();
		cachedlump = -1;
		cachedtex = -1;
		cachedlump2 = -1;
		cachedtex2 = -1;

		// paged in

		return startpage;

	}

}


uint8_t __near getspritepage(uint8_t texpage, uint8_t pageoffset) {
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
				activespritepages[startpage + i] = pageswapargs[pageswapargs_spritecache_offset +  ((startpage + i)<<1)] = -1; // unpaged

				activespritenumpages[startpage + i] = 0;
			}
		}
		activespritenumpages[startpage] = 0;


		activespritepages[startpage] = pageswapargs[pageswapargs_spritecache_offset +  (startpage<<1)] = pagenum; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;

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
				activespritepages[startpage + i] = pageswapargs[pageswapargs_spritecache_offset + ( (startpage + i)<<1)] = -1; // unpaged
				activespritenumpages[startpage + i] = 0;
			}
		}



		for (i = 0; i <= numpages; i++) {
			spriteLRU[startpage + i] = 0;
			activespritepages[startpage + i] = pageswapargs[pageswapargs_spritecache_offset +  ((startpage + i)<<1)] = pagenum + i;
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
segment_t __near getpatchtexture(int16_t lump, uint8_t maskedlookup) {

	int16_t index = lump - firstpatch;
	uint8_t texpage = patchpage[index];
	uint8_t texoffset = patchoffset[index];
	segment_t tex_segment;
	int8_t cachelump = false;
	boolean ismasked = maskedlookup != 0xFF;
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_PATCH;
#endif

	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		uint16_t size = ismasked ? masked_headers[maskedlookup].texturesize : patch_sizes[index];
		R_GetNextPatchBlock(lump, size);

		texpage = patchpage[index];
		texoffset = patchoffset[index];

		//gettexturepage ensures the page is active
		cachelump = true;
	}
	
	tex_segment = 0x9000 + pagesegments[gettexturepage(texpage, FIRST_PATCH_CACHE_LOGICAL_PAGE, CACHETYPE_PATCH)] + (texoffset << 4);

	if (cachelump){
		R_LoadPatchColumns(lump, tex_segment, ismasked);
	}
	// return
	return tex_segment;


}


segment_t getcompositetexture(int16_t tex_index) {
	
	uint8_t texpage = compositetexturepage[tex_index];
	uint8_t texoffset = compositetextureoffset[tex_index];
	int8_t cachelump = false;
	segment_t tex_segment;
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_COMPOSITE;
#endif


	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		R_GetNextCompositeBlock(tex_index);
		texpage = compositetexturepage[tex_index];
		texoffset = compositetextureoffset[tex_index];
		cachelump = true;
		//gettexturepage ensures the page is active

	}

		tex_segment = 0x9000 + pagesegments[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE, CACHETYPE_COMPOSITE)] + (texoffset << 4);

		// load it in
		if (cachelump){
			// could be inlined i guess.
			R_GenerateComposite(tex_index, tex_segment);
			
		}
		return tex_segment;

}

segment_t __near getspritetexture(int16_t index) {

	int16_t lump = index + firstspritelump;
	uint8_t texpage = spritepage[index];
	uint8_t texoffset = spriteoffset[index];
	int8_t cachelump = false;
	segment_t tex_segment;
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_SPRITE;
#endif


	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		R_GetNextSpriteBlock(lump);
		texpage = spritepage[index];
		texoffset = spriteoffset[index];
		cachelump = true;
		//gettexturepage ensures the page is active
	}

		
	tex_segment = 0x6800 + pagesegments[getspritepage(texpage, FIRST_SPRITE_CACHE_LOGICAL_PAGE)] + (texoffset << 4);

	if (cachelump){
		R_LoadSpriteColumns(lump, tex_segment);

	}
	// return
	return tex_segment;


} 
 
//
// R_GetColumn
//

/*
void setchecksum(){
	uint16_t i;
	uint16_t __far* data =  MK_FP(0x9000, 0);
	
	for (i = 0; i <32767; i++){
		thechecksum += data[i];
	}

	origcachecount = cachecount;
}*/




segment_t __near R_GetColumnSegment (int16_t tex, int16_t col) {
	int16_t         lump;
	int16_t __far* texturecolumnlump;
	int16_t n = 0;
	uint8_t texcol;

	uint8_t origcol;


	col &= texturewidthmasks[tex];
	texcol = col;
	texturecolumnlump = &(texturecolumnlumps_bytes[texturepatchlump_offset[tex]]);

	// todo: maybe unroll this in asm to the max RLE size of this operation?
	// todo: whats the max size of such a texture/rle thing

	// RLE stuff to figure out actual lump for column
	while (col >= 0) {
		lump = texturecolumnlump[n];
		col -= texturecolumnlump[n+1] & 255;
		if (lump >= 0){ // should be equiv to == -1?
			texcol -= (texturecolumnlump[n+1] & 255);
		}
		n += 2;
	}


	if (lump > 0){
		uint8_t lookup = masked_lookup[tex];
		uint8_t heightval = cachedbyteheight = texturecolumnlump[n-1] >> 8;
		if (cachedlump != lump){
			if (cachedlump2 != lump){
				cachedlump2 = cachedlump;
				cachedsegmentlump2 = cachedsegmentlump;
				cachedlump = lump;
				cachedsegmentlump = getpatchtexture(cachedlump, lookup);
			} else {
				// cycle cache so 2 = 1
				lump = cachedlump;
				cachedlump = cachedlump2;
				cachedlump2 = lump;
				lump = cachedsegmentlump;
				cachedsegmentlump = cachedsegmentlump2;
				cachedsegmentlump2 = lump;
			}
		}

		// todo what else can we reuse collength and cachedbyteheight here?

		origcol = col + (texturecolumnlump[n-1] & 255);

		if (lookup == 0xFF){
			return cachedsegmentlump + (FastMul8u8u(origcol , heightval) >> 4);
		} else {
			// Does this code ever run outside of draw masked?

			masked_header_t __far * maskedheader = &masked_headers[lookup];
			uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, maskedheader->pixelofsoffset);

			uint16_t ofs  = pixelofs[origcol];
			cachedcol = origcol;
		 
			return cachedsegmentlump + (ofs >> 4);
		}
	} else {
		uint8_t collength = textureheights[tex] + 1;

		if (cachedtex != tex){
			if (cachedtex2 != tex){
				cachedtex2 = cachedtex;
				cachedsegmenttex2 = cachedsegmenttex;
				cachedtex = tex;
				cachedsegmenttex = getcompositetexture(cachedtex);
			} else {
				// cycle cache so 2 = 1
				tex = cachedtex;
				cachedtex = cachedtex2;
				cachedtex2 = tex;
				tex = cachedsegmenttex;
				cachedsegmenttex = cachedsegmenttex2;
				cachedsegmenttex2 = tex;

			}

		}
			// todo reuse collength and cachedbyteheight here?

		collength += (16 - ((collength &0xF)) &0xF);
		cachedbyteheight = collength;
		return cachedsegmenttex + (FastMul8u8u(collength , texcol) >> 4);

	}

} 

// bypass the colofs cache stuff, store just raw pixel data at texlocation. 
//void R_LoadPatchColumns(uint16_t lump, byte __far * texlocation, boolean ismasked){
void R_LoadPatchColumns(uint16_t lump, segment_t texlocation_segment, boolean ismasked){
	patch_t __far *patch = (patch_t __far *)SCRATCH_ADDRESS_5000;
	int16_t col;
	uint16_t destoffset = 0;
	int16_t patchwidth;


	Z_QuickMapScratch_5000(); // render col info has been paged out..

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	patchwidth = patch->width;

	for (col = 0; col < patchwidth; col++){

		column_t __far * column = (column_t __far *)(SCRATCH_ADDRESS_5000 + patch->columnofs[col]);
		while (column->topdelta != 0xFF){
			uint8_t length = column->length;
			byte __far * sourcetexaddr = SCRATCH_ADDRESS_5000 + (((int32_t)column) + 3);
			FAR_memcpy(MK_FP(texlocation_segment,  destoffset), sourcetexaddr, length);
			destoffset += length;
			if (ismasked){

				// round up to the next paragraph for masked textures which do multiple renders
				// and thus the subrenders must also start paragraph aligned...
				// for non masked textures they are always overlapping - or really "should" be.. revisit for buggy gap pixels
				destoffset += (16 - ((length &0xF)) &0xF);
				
			}

	    	column = (column_t __far *)(  (byte  __far*)column + length + 4 );
		}
		if (!ismasked){
			destoffset += (16 - ((destoffset &0xF)) &0xF);
		}

	}

	Z_QuickMapColumnOffsets5000(); // put render info back

}

// bypass the colofs cache stuff, store just raw pixel data at texlocation. 
//void R_LoadPatchColumns(uint16_t lump, byte __far * texlocation, boolean ismasked){
void R_LoadPatchColumnsColormap0(uint16_t lump, segment_t texlocation_segment, boolean ismasked){
	patch_t __far *patch = (patch_t __far *)SCRATCH_ADDRESS_5000;
	int16_t col;
	uint16_t destoffset = 0;
	int16_t patchwidth;


	Z_QuickMapScratch_5000(); // render col info has been paged out..

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	patchwidth = patch->width;

	for (col = 0; col < patchwidth; col++){

		column_t __far * column = (column_t __far *)(SCRATCH_ADDRESS_5000 + patch->columnofs[col]);
		while (column->topdelta != 0xFF){
			uint8_t length = column->length;
			byte __far * sourcetexaddr = SCRATCH_ADDRESS_5000 + (((int32_t)column) + 3);
			byte __far * destaddr = MK_FP(texlocation_segment,  destoffset);
			byte __far * colormapzero = MK_FP(colormapssegment,  0);
			//FAR_memcpy(MK_FP(texlocation_segment,  destoffset), sourcetexaddr, length);
			uint8_t i;
			for (i = 0; i < length; i++){
				destaddr[i] = colormapzero[sourcetexaddr[i]];
			}

			destoffset += length;
			if (ismasked){

				// round up to the next paragraph for masked textures which do multiple renders
				// and thus the subrenders must also start paragraph aligned...
				// for non masked textures they are always overlapping - or really "should" be.. revisit for buggy gap pixels
				destoffset += (16 - ((length &0xF)) &0xF);
				
			}

	    	column = (column_t __far *)(  (byte  __far*)column + length + 4 );
		}
		if (!ismasked){
			destoffset += (16 - ((destoffset &0xF)) &0xF);
		}

	}

	Z_QuickMapColumnOffsets5000(); // put render info back

}

// we store this in the format;
// first 8 bytrs: regular patch_t
// for patch->width num rows:
//   4 bytes per colof as usual, EXCEPT -
//   rather than the inbetween words being 0, they are now postofs
// THEN
// array of all postof data
// THEN
// array of all pixel post runs, paragraph aligned.
// of course, the colofs and postofs have to be filled in at this time too.

void R_LoadSpriteColumns(uint16_t lump, segment_t destpatch_segment){
	patch_t __far * destpatch = MK_FP(destpatch_segment, 0);

	patch_t __far *patch = (patch_t __far *)SCRATCH_ADDRESS_5000;
	uint16_t __far * columnofs = (uint16_t __far *)&(destpatch->columnofs[0]);   // will be updated in place..
	uint16_t currentpixelbyte;
	uint16_t currentpostbyte;
	int16_t col;
	int16_t patchwidth;
	uint16_t __far * postdata;
	byte __far * pixeldataoffset;
	

	uint16_t destoffset;

	Z_QuickMapScratch_5000(); // render col info has been paged out..

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	patchwidth = patch->width;

	destpatch->width = patch->width;
	destpatch->height = patch->height;
	destpatch->leftoffset = patch->leftoffset;
	destpatch->topoffset = patch->topoffset;

 	destoffset = 8 + ( patchwidth << 2);
	currentpostbyte = destoffset;
	postdata = (uint16_t __far *)(((byte __far*)destpatch) + currentpostbyte);

	destoffset += spritepostdatasizes[lump-firstspritelump];
	destoffset += (16 - ((destoffset &0xF)) &0xF); // round up so first pixel data starts aligned of course.
	currentpixelbyte = destoffset;
	pixeldataoffset = ((byte __far *)(destpatch)) + currentpixelbyte;

	// 32, 368

	for (col = 0; col < patchwidth; col++){

		column_t __far * column = (column_t __far *)MK_FP(SCRATCH_PAGE_SEGMENT, patch->columnofs[col]);
		
		*columnofs = currentpixelbyte;	// colofs pointer
		columnofs++;
		*columnofs = currentpostbyte;	// postofs pointer
		columnofs++;

 		while (column->topdelta != 0xFF){

			uint8_t length = column->length;
			byte __far * sourcetexaddr = MK_FP(SCRATCH_PAGE_SEGMENT, (((int32_t)column) + 3));

			FAR_memcpy(pixeldataoffset, sourcetexaddr, length);

			length += ((16 - (length &0xF)) &0xF);
			currentpixelbyte += length;
			pixeldataoffset += length;

			*postdata = *((uint16_t __far*)column);
			postdata++;
			currentpostbyte +=2;

	    	column = (column_t __far *)(  ((byte  __far*)column) + column->length + 4 );
		}

 
		*postdata = 0xFFFF;
		postdata++;
		currentpostbyte +=2;

	}

	Z_QuickMapColumnOffsets5000(); // put render info back

}
