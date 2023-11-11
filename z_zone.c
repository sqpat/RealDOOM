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
//      Zone Memory Allocation. Neat.
//

#include "z_zone.h"
#include "i_system.h"
#include "doomdef.h"

#include "m_menu.h"
#include "w_wad.h"
#include "r_data.h"

#include "doomstat.h"
#include "r_bsp.h"

#include "p_local.h"

#include <dos.h>
#include <stdlib.h>


//
// ZONE MEMORY ALLOCATION
//
// There is never any space between memblocks,
//  and there will never be two contiguous free memblocks.
// The rover can be left pointing at a non-empty block.
//
// It is of no value to free a cachable block,
//  because it will get overwritten automatically if needed.
// 




#define MINFRAGMENT         32
// we dont make many conventional allocations, only a small number of important ones
#define CONVENTIONAL_ALLOCATION_LIST_SIZE 12
// todo make this PAGE * PAGE SIZE 
#define MAX_ZMALLOC_SIZE 0x10000L

// demo commented out...
//#define STATIC_CONVENTIONAL_BLOCK_SIZE_1 65535
//#define STATIC_CONVENTIONAL_BLOCK_SIZE_2 32767

//#define STATIC_CONVENTIONAL_BLOCK_SIZE_1 1
#define STATIC_CONVENTIONAL_BLOCK_SIZE_2 24678
// DOOM SHAREWARE VALUE
#define STATIC_CONVENTIONAL_SPRITE_SIZE 7000u
#define SPRITE_ALLOCATION_LIST_SIZE 150
// SET TO 1 TO DISABLE
//#define STATIC_CONVENTIONAL_SPRITE_SIZE 1
//#define SPRITE_ALLOCATION_LIST_SIZE 1


// Currently bugged/not fully implemented, leave as 1 to not use
// todo calc actual sizeof mobj or whatever thinker is biggest...
// mobj sizeof is 97u
//#define STATIC_CONVENTIONAL_THINKER_SIZE 65535
//#define THINKER_ALLOCATION_LIST_SIZE 600

// equal to sizeof(mobj_t), the largest thinker. 
#define THINKER_BLOCK_SIZE 97
#define STATIC_CONVENTIONAL_THINKER_SIZE 1
#define THINKER_ALLOCATION_LIST_SIZE MAX_THINKERS+1

// DOOM SHAREWARE VALUE
#define STATIC_CONVENTIONAL_TEXTURE_INFO_SIZE (21552u+21552u+4963u+10u)
// SET TO 1 TO DISABLE
//#define STATIC_CONVENTIONAL_TEXTURE_INFO_SIZE 1

// #define TEXTUREINFO_ALLOCATION_LIST_SIZE 1
#define TEXTUREINFO_ALLOCATION_LIST_SIZE NUM_TEXTURE_CACHE * 3


// 8 MB worth. Letting us set 8 MB as a max lets us get away with 
// some smaller allocation_t sizes
#define MAX_PAGE_FRAMES 512

#define PAGE_FRAME_BITS 14

// high 9 bits
#define PAGE_MASK 0xFF800000
// low 23 bits
#define SIZE_MASK 0x007FFFFF
#define PAGE_AND_SIZE_SHIFT 23
#define MAKE_SIZE(x) (x & SIZE_MASK)
#define MAKE_PAGE(x) (x >> PAGE_AND_SIZE_SHIFT)

// bit 15, so we can still treat it as unsigned
#define USER_MASK 0x8000
#define INVERSE_USER_MASK 0x7FFF
#define IS_PURGEABLE(x) (x.tag >= PU_PURGELEVEL)
#define IS_FREE(x) (x.tag >= PU_PURGELEVEL)
#define HAS_USER(x) (x.backref_and_user & USER_MASK)

#define TAG_MASK 0xC000
#define OFFSET_MASK 0x3FFF
#define OFFSET_BITS 14

#define MAKE_OFFSET(x) (x.offset_and_tag & OFFSET_MASK)
#define MAKE_TAG(x) (x.offset_and_tag >> OFFSET_BITS)
#define SET_TAG(x, y) (x.offset_and_tag =  (y << OFFSET_BITS) + MAKE_OFFSET(x) )

// voodoo magic kinda messy...
// basically we are storing a 15 bit signed integer alongside a 1 bit flag...
// we use bit 15 to store the flag so bit 16 can still handle the negative,
// because we also special case that value based on if it's negative or not.
// Anyway when we want to convert the 15 bit signed integer to a 16 bit one
// for various operations, we must handle it differently depending on the sign
// flag.  This is only used in one or two spots so its not a big deal, and this
// charade helps us save 1000 more bytes of conventional mem..


//#define MAKE_BACKREF(x) ((x.backref_and_user & 0x4000) ? (x.backref_and_user | USER_MASK) : (x.backref_and_user & INVERSE_USER_MASK))

#define MAKE_BACKREF(x) (x.backref_and_user & INVERSE_USER_MASK)
#define SET_BACKREF(x, y) (x.backref_and_user = y + (x.backref_and_user & USER_MASK))
#define SET_BACKREF_ZERO(x) (x.backref_and_user &= USER_MASK)



typedef struct
{
	uint16_t	offset;

} allocation_static_conventional_t;

typedef struct
{
	uint8_t		active;

} allocation_thinker_conventional_t;

 

typedef struct
{
	uint16_t	offset; 
	// size needed due to deallocations? 
	// the only things that use these are thinkers and mobj which are smaller than 128 bytes so this works
	uint8_t	size;  
} allocation_dynamic_thinker_t;


// ugly... but it does work. I don't think we can ever make use of more than 2 so no need to listify
byte conventionalmemoryblock1[STATIC_CONVENTIONAL_BLOCK_SIZE_1];
byte conventionalmemoryblock2[STATIC_CONVENTIONAL_BLOCK_SIZE_2];
byte spritememoryblock[STATIC_CONVENTIONAL_SPRITE_SIZE];
byte thinkermemoryblock[STATIC_CONVENTIONAL_THINKER_SIZE];
byte textureinfomemoryblock[STATIC_CONVENTIONAL_TEXTURE_INFO_SIZE];

uint16_t remainingconventional1 = STATIC_CONVENTIONAL_BLOCK_SIZE_1;
uint16_t remainingconventional2 = STATIC_CONVENTIONAL_BLOCK_SIZE_2;
uint16_t remainingspriteconventional = STATIC_CONVENTIONAL_SPRITE_SIZE;
uint16_t remainingthinkerconventional = STATIC_CONVENTIONAL_THINKER_SIZE;
uint16_t remainingtextureinfoconventional = STATIC_CONVENTIONAL_TEXTURE_INFO_SIZE;

uint16_t conventional1head = 	  0;
uint16_t conventional2head = 	  0;
uint16_t spritehead = 	  0;
uint16_t thinkerhead = 	  0;
uint16_t textureinfohead = 	  0;

uint16_t conventional1headindex = 	  0;
uint16_t conventional2headindex = 	  0;
uint16_t spriteheadindex = 	  0;
uint16_t thinkerheadindex = 	  0;
uint16_t textureinfoheadindex = 	  0;


PAGEREF currentListHead = ALLOCATION_LIST_HEAD; // main rover


PAGEREF currentThinkerAllocationListHead = 1;

allocation_t allocations[EMS_ALLOCATION_LIST_SIZE];
allocation_thinker_conventional_t thinker_allocations[THINKER_ALLOCATION_LIST_SIZE];
boolean thinkerAllocationListFull = false;


allocation_static_conventional_t conventional_allocations1[CONVENTIONAL_ALLOCATION_LIST_SIZE];
allocation_static_conventional_t conventional_allocations2[CONVENTIONAL_ALLOCATION_LIST_SIZE];
allocation_static_conventional_t textureinfo_allocations[TEXTUREINFO_ALLOCATION_LIST_SIZE];
// todo turn these into dynamic allocations
allocation_static_conventional_t sprite_allocations[SPRITE_ALLOCATION_LIST_SIZE];
//allocation_thinker_conventional_t thinker_allocations[THINKER_ALLOCATION_LIST_SIZE];


int16_t activepages[NUM_EMS_PAGES];
int8_t pageevictorder[NUM_EMS_PAGES];
int8_t pagesize[NUM_EMS_PAGES];

// we do ref counts here. important to remember you can have a single page be marked "locked"
// from multiple different references at once. You dont want to remove the page's stickiness
// when other references are expecting it there.
// Also, if this goes to -1 then you were bad.
int8_t lockedpages[NUM_EMS_PAGES];


// 4 pages = 2 bits. Times 4 = 8 bits. least significant = least recent used
// default order is  11 10 01 00  = 228
//uint8_t pageevictorder = 228;

#ifdef _M_I86

	static int16_t emshandle;
	extern union REGS regs;

#else
	byte*			EMSArea;
#endif

#define NUM_THINKER_PAGES 6L

byte*			pageFrameArea;

// count allocations etc, can be used for benchmarking purposes.

int32_t numreads = 0;
int32_t pageins = 0;
int32_t pageouts = 0;
int32_t actualpageins = 0;
int32_t actualpageouts = 0;

#ifdef PROFILE_PAGE_COUNT
int32_t pagecount[40];
#endif

void Z_PageOutIfInMemory(uint32_t page_and_size);

void Z_ChangeTagEMS(MEMREF index, int16_t tag) {


	// if tag is equal to PU_PURGELEVEL
#ifdef CHECK_FOR_ERRORS
	if ((allocations[index].offset_and_tag & 0xC000) == 0xC000 && !HAS_USER(allocations[index])) {
		I_Error("Z_ChangeTagEMS: an owner is required for purgable blocks %i %i %i %i %i",
			allocations[index].offset_and_tag,
			tag,
			index,
			allocations[index].backref_and_user,
			HAS_USER(allocations[index]));
	}
#endif
	SET_TAG(allocations[index], tag);
}




void Z_FreeThinker(PAGEREF block){
	thinker_allocations[EMS_ALLOCATION_LIST_SIZE].active = false;
}

void Z_FreeEMS(PAGEREF block) {


	uint16_t         other;

#ifdef CHECK_FOR_ERRORS
	if (block == ALLOCATION_LIST_HEAD) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		I_Error("ERROR: Called Z_FreeEMS with 0! \n");
	}

	if (block >= EMS_ALLOCATION_LIST_SIZE) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		I_Error("ERROR: Called Z_FreeEMS with too big of size: max %i vs %i! \n", EMS_ALLOCATION_LIST_SIZE - 1, block);
	}
#endif

	// temp var use
	other = MAKE_BACKREF(allocations[block]);
	if (other > 0)


		if (other > BACKREF_LUMP_OFFSET) {
			// in lumpcache
			W_EraseLumpCache(other - BACKREF_LUMP_OFFSET);
		}
		else {
			// in compositeTextures
			R_EraseCompositeCache(other - 1); // 0 means no backref..

		}

	// if we dont page it out, this logical page can be re-allocated while the old one is already registered to a page frame.
	Z_PageOutIfInMemory(allocations[block].page_and_size);


	// mark as free
	allocations[block].offset_and_tag &= OFFSET_MASK; // PU_NOT_IN_USE;
	allocations[block].backref_and_user = 0;

	// at this point the block represents a free block of memory but you cant
	// make the allocation array index free, unless you join it with an adjacent
	// memory block.
	other = allocations[block].prev;



	// if two sequential blocks free, we can join them and free one spot in
	// the allocations array
	if (!HAS_USER(allocations[other]))
	{
		// extend other forward OVER block
		// merge with previous free block
		allocations[other].page_and_size += MAKE_SIZE(allocations[block].page_and_size);

		if (block == currentListHead)
			currentListHead = other;
		// link the blocks
		allocations[other].next = allocations[block].next;
		allocations[allocations[block].next].prev = other;

		// finally mark the array index unused.
		// this is where you have actually removed an array index
		allocations[block].prev = EMS_ALLOCATION_LIST_SIZE;
		SET_BACKREF_ZERO(allocations[block]);
		block = other;
	}

	other = allocations[block].next;
	// again, if two sequential blocks free, we can join them and free one spot in
	// the allocations array
	if (!HAS_USER(allocations[other]))
	{
		// extend block forward OVER other
		// merge the next free block onto the end
		allocations[block].page_and_size += MAKE_SIZE(allocations[other].page_and_size);

		if (other == currentListHead)
			currentListHead = block;

		// link the blocks
		allocations[block].next = allocations[other].next;
		allocations[allocations[other].next].prev = block;

		// finally mark the array index unused.
		// this is where you have actually removed an array index
		allocations[other].prev = EMS_ALLOCATION_LIST_SIZE;
		allocations[other].offset_and_tag &= OFFSET_MASK; // set tag to NOT_IN_USE
	}

#ifdef MEMORYCHECK
	Z_CheckEMSAllocations(block);
#endif
}


void
Z_FreeTagsEMS
(int16_t           tag)
{
	int16_t block;


	// Now check if consecutive empties
	for (block = allocations[ALLOCATION_LIST_HEAD].next; ; block = allocations[block].next) {

		/*
				if (block->tag >= lowtag && block->tag <= hightag)
					printf ("block:%p    size:%7i    user:%p    tag:%3i\n",
							block, block->size, block->user, block->tag);*/

		if (block == ALLOCATION_LIST_HEAD){
			// all blocks have been hit
			break;
		}

		// free block?
		if (!HAS_USER(allocations[block]))
			continue;

		if (MAKE_TAG(allocations[block]) == tag)
			Z_FreeEMS(block);
	}

}

void Z_MarkPageLRU(uint16_t pagenumber) {
	int16_t i;
	int16_t j;

#ifdef CHECK_FOR_ERRORS
	if (pagenumber >= NUM_EMS_PAGES) {
		I_Error("Z_MarkPageLRU: page number too big %u",  pagenumber);
	}
#endif

	for (i = NUM_EMS_PAGES - 1; i >= 0; i--) {
		if (pagenumber == pageevictorder[i]) {
			break;
		}
	}

#ifdef CHECK_FOR_ERRORS
	if (i == -1) {
		//I_Error("%i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3] );
		I_Error("(LRU) Could not find page number in LRU cache: %i %i %i %i", pagenumber, numreads, pageins, pageouts);
	}
#endif
	// i now represents where the page was in the cache. move it to the back and everything else up.
	for (j = i; j > 0; j--) {
		pageevictorder[j] = pageevictorder[j - 1];
	}

	pageevictorder[0] = pagenumber;

}


#ifdef CHECKREFS

void Z_PageDump(int8_t* string, int16_t numallocatepages) {

#if NUM_EMS_PAGES == 8
	char*  message = "\n %i %i %i %i %i %i %i %i\n %i %i %i %i %i %i %i %i\n %i %i %i %i %i %i %i %i\n %i %i %i %i %i %i %i %i";
	strcat(string, message);

	I_Error(string,
		numallocatepages,
		activepages[0], activepages[1], activepages[2], activepages[3], activepages[4], activepages[5], activepages[6], activepages[7],
		pagesize[0], pagesize[1], pagesize[2], pagesize[3], pagesize[4], pagesize[5], pagesize[6], pagesize[7],
		pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3], pageevictorder[4], pageevictorder[5], pageevictorder[6], pageevictorder[7],
		lockedpages[0], lockedpages[1], lockedpages[2], lockedpages[3], lockedpages[4], lockedpages[5], lockedpages[6], lockedpages[7]
	);
#else 
	char*  message = "\n %i %i %i %i\n %i %i %i %i\n %i %i %i %i\n %i %i %i %i";
	strcat(string, message);


	I_Error(string,
		numallocatepages,
		activepages[0], activepages[1], activepages[2], activepages[3],
		pagesize[0], pagesize[1], pagesize[2], pagesize[3],
		pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3],
		lockedpages[0], lockedpages[1], lockedpages[2], lockedpages[3]
	);
#endif
}

int16_t Z_RefIsActive2(MEMREF memref, int8_t* file, int32_t line) {
	//int16_t Z_RefIsActive2(MEMREF memref){
	int16_t pageframeindex;
	boolean allpagesgood;
	int16_t i;
	uint32_t size = MAKE_SIZE(allocations[memref].page_and_size);

	uint16_t numallocatepages;

	if (memref >= EMS_ALLOCATION_LIST_SIZE ) {
		if (memref >= (EMS_ALLOCATION_LIST_SIZE + 2 * CONVENTIONAL_ALLOCATION_LIST_SIZE)) {
			//I_Error("Z_RefIsActive: alloc too big %i ", memref);
		}
		return 1; // if its in conventional then its good.
	}

	if (size == 0) {
		numallocatepages = 1;
	}
	else {
		numallocatepages = 1 + ((size - 1) >> PAGE_FRAME_BITS);
	}

	for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
		if (activepages[pageframeindex] == MAKE_PAGE(allocations[memref].page_and_size)) {
			//printf("\nEMS CACHE HIT on page %i size %i", page, size);
			allpagesgood = true;

			for (i = 1; i < numallocatepages; i++) {
				if (activepages[pageframeindex + i] != MAKE_PAGE(allocations[memref].page_and_size) + i) {
					allpagesgood = false;
					break;
				}
			}

			if (allpagesgood) {
				return 1;
			}
		}
	}

	/*
		for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
			if (activepages[pageframeindex] == allocations[memref].page) {
				return 1;
			}
		}
		*/

		//Z_PageDump();

	I_Error("\nZ_RefIsActive: Found inactive ref! %i %li %s %i %i", memref, gametic, file, line, numallocatepages);

	return 0;
}

#endif

// marks page as most recently used
// error behavior if pagenumber not in the list?
//void Z_MarkPageMRU(uint16_t pagenumber, int8_t* file, int32_t line) {
void Z_MarkPageMRU(uint16_t pagenumber) {

	int16_t i;
	int16_t j;

#ifdef CHECK_FOR_ERRORS
	if (pagenumber >= NUM_EMS_PAGES) {
		I_Error("page number too big %i %i %i", pageevictorder, pagenumber);
	}
#endif

	for (i = NUM_EMS_PAGES - 1; i >= 0; i--) {
		if (pagenumber == pageevictorder[i]) {
			break;
		}
	}

#ifdef CHECK_FOR_ERRORS
	if (i == -1) {
		//I_Error("%i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3] );
		I_Error("(MRU) Could not find page number in LRU cache: %i %i %i %i %s %i", pagenumber, numreads, pageins, pageouts);
	}
#endif


	// i now represents where the page was in the cache. move it to the back and everything else up.

	for (j = i; j < NUM_EMS_PAGES - 1; j++) {
		pageevictorder[j] = pageevictorder[j + 1];
	}

	pageevictorder[NUM_EMS_PAGES - 1] = pagenumber;

}


void Z_DoPageOut(uint16_t pageframeindex, int16_t source) {
#ifdef _M_I86



	// swap OUT memory
	int16_t i = 0;
	// this already gets called once per page on the outside, no need to run an inner loop with numpages to swap

	// don't swap out an already swapped out page
	if (activepages[pageframeindex] == -1) {
		return;
	}
		
	actualpageouts++;
	pageouts ++;

	if (pageframeindex >= NUM_EMS_PAGES) {
		I_Error("bad page frame index %i", pageframeindex);
	}

	activepages[pageframeindex] = -1;
	pagesize[pageframeindex] = -1;
	Z_MarkPageLRU(pageframeindex);
	if (lockedpages[pageframeindex]) {
		I_Error("paging out locked %i", source);
		//Z_PageDump("paging out locked %i", source);
	}

	regs.h.al = pageframeindex+i;  // physical page
	regs.w.bx = 0xFFFF; // activepages[pageframeindex + i];    // logical page
	regs.w.dx = emshandle; // handle
	regs.h.ah = 0x44;
	intx86(EMS_INT, &regs, &regs);
	if (regs.h.ah != 0) {
		I_Error("Mapping failed on page out %i!\n", pageframeindex+i);
	}


#else

	// swap OUT memory
	int16_t i = 0;
	int16_t numPagesToSwap = pagesize[pageframeindex];
	byte* copysrc = pageFrameArea + (pageframeindex * PAGE_FRAME_SIZE);
	byte* copydst = EMSArea + (activepages[pageframeindex] * PAGE_FRAME_SIZE);

	// don't swap out an already swapped out page
	if (activepages[pageframeindex] == -1) {
		return;
	}

	if (numPagesToSwap <= 0) {
		numPagesToSwap = 1;
	}

	memcpy(copydst, copysrc, (int32_t)PAGE_FRAME_SIZE * numPagesToSwap);
	memset(copysrc, 0x00, (int32_t)PAGE_FRAME_SIZE * numPagesToSwap);

	actualpageouts++;
	pageouts += numPagesToSwap;
	for (i = 0; i < numPagesToSwap; i++) {
		activepages[pageframeindex + i] = -1;
		pagesize[pageframeindex + i] = -1;
		Z_MarkPageLRU(pageframeindex + i);
#ifdef CHECK_FOR_ERRORS
		if (lockedpages[pageframeindex + i]) {
			I_Error("paging out locked %i %i", source, numPagesToSwap);
			//Z_PageDump("paging out locked %i", source);
		}
#endif
}

#endif

}

void Z_DoPageIn(uint16_t logicalpage, uint16_t pageframeindex, uint16_t numallocatepages) {

#ifdef _M_I86

	int16_t i = 0;

	//todo implement multi-page pagination at once (ems 4.0?)

	for (i = 0; i < numallocatepages; i++) {

		regs.h.al = pageframeindex + i;				// physical page
		regs.w.bx = logicalpage + i;		// logical page
		regs.w.dx = emshandle;						// handle
		regs.h.ah = 0x44;
		intx86(EMS_INT, &regs, &regs);
		if (regs.h.ah != 0) {
			I_Error("Mapping failed on page in %i %i %u %u %li %li %li %li!\n", activepages[pageframeindex + i], i, pageframeindex, logicalpage, pageins, actualpageins, pageouts, actualpageouts);
		}


		activepages[pageframeindex + i] = logicalpage + i;

		if (i == 0) {
			pagesize[pageframeindex + i] = numallocatepages;
		}
		else {
			pagesize[pageframeindex + i] = -1;
		}

	}


#else


	int16_t i = 0;
	byte* copydst = pageFrameArea + pageframeindex * PAGE_FRAME_SIZE;
	byte* copysrc = EMSArea + logicalpage * PAGE_FRAME_SIZE;

	memcpy(copydst, copysrc, PAGE_FRAME_SIZE * numallocatepages);

	// mark the page size. needed for dealocating all pages later

	for (i = 0; i < numallocatepages; i++) {
		activepages[pageframeindex + i] = logicalpage + i;
		if (i == 0) {
			pagesize[pageframeindex + i] = numallocatepages;
		}
		else {
			pagesize[pageframeindex + i] = -1;
		}
		Z_MarkPageMRU(pageframeindex + i);
	}

#endif

}

void Z_PageOutIfInMemory(uint32_t page_and_size) {
	uint16_t logicalpage = MAKE_PAGE(page_and_size);
	uint32_t size = MAKE_SIZE(page_and_size);
	uint16_t pageframeindex;
	uint16_t numallocatepages;
	uint16_t i;


	if (size) {
		numallocatepages = 1 + ((size - 1) >> PAGE_FRAME_BITS);
	} else {
		numallocatepages = 1;
	}


	if (numallocatepages > 1) {
		for (i = 0; i < numallocatepages; i++) {
			for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
				if (activepages[pageframeindex] == logicalpage + i) {
					Z_DoPageOut(pageframeindex, 0);
				}
			}
		}

	}

}

// gets a page index for this EMS page.
// forces a page swap if necessary.

// "page frame" is the upper memory EMS page frame
// logical page is where it corresponds to in the big block of otherwise inaccessible memory..


//todo copy this into Z_LoadBytesFromEMS as thats the only place its called

//int16_t Z_GetEMSPageFrame(uint32_t page_and_size, boolean locked, int8_t* file, int32_t line) {  //todo allocations < 65k? if so size can be an uint16_t?
int16_t Z_GetEMSPageFrame(uint32_t page_and_size, boolean locked) {  //todo allocations < 65k? if so size can be an uint16_t?
	uint16_t logicalpage = MAKE_PAGE(page_and_size);
	uint32_t size = MAKE_SIZE(page_and_size);
	uint16_t pageframeindex;

	uint16_t numallocatepages;
	uint16_t i;
	uint8_t j;
	boolean skip;
	boolean allpagesgood;
	numreads++;


	if (size == 0) {
		numallocatepages = 1;
	}
	else {
		numallocatepages = 1 + ((size - 1) >> PAGE_FRAME_BITS);
	}


	/*
		I_Error("earlyest %i %i %i %i %i %i %i %i %i %i %i %i",
			activepages[0], activepages[1], activepages[2], activepages[3],
			pagesize[0], pagesize[1], pagesize[2], pagesize[3],
			pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3]
			);
		*/


	if (locked) {
		// when generating locked pages we always want to allocate first page to last page.
		// want to avoid fragmented locked pages that prevent larger allocations from finding
		// a larger contiguous block.

		// first check if its already in a locked page in memory, or if in a non locked page
		// (in which case we clear it out to move back)

		allpagesgood = true;

		for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {

			if (!lockedpages[pageframeindex]) {
				allpagesgood = false;
			}

			if (activepages[pageframeindex] == logicalpage) {
				// clear out the page from there?


				for (i = 0; i < numallocatepages; i++) {
					if (activepages[pageframeindex + i] != logicalpage + i) { // is the whole allocation here?
						if (lockedpages[pageframeindex + i]) {  // are all pages marked locked?
							allpagesgood = false;
							break;
						}
					}
				}

				if (allpagesgood) {
					return pageframeindex; // no need to do shenanigans, just return
				}
				else {
					// paging out the previous allocation
					for (i = 0; i < numallocatepages; i++) { 
						if (activepages[pageframeindex + i] >= 0) {
							Z_DoPageOut(pageframeindex + i, pageframeindex);
						}
					}
					break;
				}
			}
		}

		// now allocate the locked page..

		// force pages out if there is anything there
		for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
			if (lockedpages[pageframeindex]) {
				continue;
			}

			// found the first unlocked page - lets allocate.

			for (i = 0; i < numallocatepages; i++) {
#ifdef CHECK_FOR_ERRORS
				if (lockedpages[pageframeindex + i]) {
					// locked page in the middle? shouldn't happen but i guess fragmentation can happen with freeing of these pages
					// if this is really happening a lot... then redo in code where the pages are being locked to prevent this? but realistically page locking should grow/shrink in "stack" pattern

					I_Error("forcing out locked page? %i %i  %i", i, -1, MAKE_SIZE(allocations[i].page_and_size));

				}
#endif
				// page out what was there
				if (activepages[pageframeindex + i] >= 0) {
					Z_DoPageOut(pageframeindex + i, 2);
				}

			}

			/*
				for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++) {
					if (allocations[i].lockcount > 0) {
						I_Error("forcing out %i %i %i %i %i", i, -1, MAKE_SIZE(allocations[i].page_and_size), allocations[i].sourcehint, ((mobj_t*) (allocations[i].sourcehint))->type );
					}
				}
				*/

			Z_DoPageIn(logicalpage, pageframeindex, numallocatepages);
			pageins++;

			return pageframeindex;

		}

#ifdef CHECK_FOR_ERRORS
		I_Error("couldnt find page to deallocate for a locked page? %i %i  %i", i, -1, MAKE_SIZE(allocations[i].page_and_size));
#endif
	}


	// BEGIN NORMAL, NON-FORCED PAGE FINDING USING LRU ETC

	// loop to search for page alread in cache
	for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
		if (activepages[pageframeindex] == logicalpage) {
			//printf("\nEMS CACHE HIT on page %i size %i", page, size);
			allpagesgood = true;



			for (i = 1; i < numallocatepages; i++) {
				if (activepages[pageframeindex + i] != logicalpage + i) {
					allpagesgood = false;
					break;
				}
			}

			if (allpagesgood) {
				for (i = 0; i < numallocatepages; i++) {
					Z_MarkPageMRU(pageframeindex + i);
				}

				return pageframeindex;
			}
		}
	}


	// there are cases where a large allocation stretches over more than
	// one page - then there are other separate allocations in the
	// remaining portion of the final page. If those items are already
	// in an active page, and we wish to now allocate the larger item, 
	// we must take care to not create a duplicate active allocation of 
	// the final page. In this case we first remove the final page from 
	// the active pages

	// page not active

	// if its multi pages, lets see if the 2nd and further pages exist in cache
	// if so, evict those as they are about to be re-allocated.
	if (numallocatepages > 1) {
		for (i = 1; i < numallocatepages; i++) {
			for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
				if (activepages[pageframeindex] == logicalpage + i) {
					Z_DoPageOut(pageframeindex, 3);

				}
			}
		}

	}

	// decide on page to evict
	for (i = 0; i < NUM_EMS_PAGES + 1; i++) {
#ifdef CHECK_FOR_ERRORS
		if (i == NUM_EMS_PAGES) {

			I_Error("Could not find EMS page to evict!");
		}
#endif
		// lets go down the LRU cache and find the next index
		pageframeindex = pageevictorder[i];
		// break loop if there is enough space to dealloate..  
		// TODO: could this be improved? average evict orders for multiple pages?

		skip = false;

		for (j = 0; j < numallocatepages; j++) {
			if (lockedpages[pageframeindex + j]) {
				skip = true;
				break;
			}
		}
		if (skip) { // skip locked pages
			continue;
		}

		// should really be a for loop to check for locked pages? 
		if (numallocatepages + pageframeindex <= NUM_EMS_PAGES) {
			break;
		}

	}

	// update active EMS pages
	for (i = 0; i < numallocatepages; i++) {
		if (activepages[pageframeindex + i] >= 0) {
			Z_DoPageOut(pageframeindex + i, numallocatepages);
		}
	}





	// todo skip the copy if it was -1 ?

	// can do multiple pages in one go...
	// swap IN memory

#ifdef PROFILE_PAGE_COUNT
	pagecount[allocations[ref].sourcehint]++;
#endif
	Z_DoPageIn(logicalpage, pageframeindex, numallocatepages);
	pageins++;


	return pageframeindex;
}



int16_t Z_GetEMSPageFrameNoUpdate(uint32_t page_and_size, MEMREF ref) {  //todo allocations < 65k? if so size can be an uint16_t?
	uint16_t logicalpage = MAKE_PAGE(page_and_size);
	uint32_t size = MAKE_SIZE(page_and_size);
	uint16_t pageframeindex;

	uint16_t numallocatepages;
	uint16_t i;
	boolean allpagesgood;
	numreads++;

	if (size == 0) {
		//I_Error("why a zero allocation!?");
	}

 

	if (size == 0) {
		numallocatepages = 1;
	}
	else {
		numallocatepages = 1 + ((size - 1) >> PAGE_FRAME_BITS);
	}


	// loop to search for page alread in cache
	for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
		if (activepages[pageframeindex] == logicalpage) {
			//printf("\nEMS CACHE HIT on page %i size %i", page, size);
			allpagesgood = true;



			for (i = 1; i < numallocatepages; i++) {
				if (activepages[pageframeindex + i] != logicalpage + i) {
					allpagesgood = false;
					break;
				}
			}

			if (allpagesgood) {
				return pageframeindex;
			}
		}
	}

	//Z_PageDump();
	/*
	1 24 25 -1
	1  2 -1 -1
	3  0  1  2
	0  0  0  0

	*/

	// I_Error("page was not found for set locked! %i %i", ref, tag );
	return -1;
}


// assumes the page is already in memory. 
// todo add this as a Z_Malloc argument so we can avoid calls to Z_GetEMSPageFrame
void Z_SetUnlockedWithPage(MEMREF ref, boolean value, int16_t  pageframeindex) {
	//int16_t pageframeindex = Z_GetEMSPageFrameNoUpdate(allocations[ref].page_and_size, ref);
	uint8_t i;


#ifdef CHECK_FOR_ERRORS

	if (ref >= EMS_ALLOCATION_LIST_SIZE) {
		I_Error("index too big in set_locked: %i %i", ref);
	}

	if (pageframeindex == -1) {
		I_Error("page was not found for this locked");
	}
#endif

	// there is this unfortunate edge case where you have a reference that is in the 'left over' portion of a 
	// multi page allocation. imagine a 20k allocation with several items in the remaining 12k of page 2. in that
	// case, pagesize is going to be -1 for that 2nd page. we're hacking this to set the whole big allocation locked inthis case. however
	// i feel like there is a better way to architect this so it doesnt happen this way.
	if (pagesize[pageframeindex] == -1) {
		for (; ; pageframeindex--) {
			if (pagesize[pageframeindex] != -1) {
				break;
			}
#ifdef CHECK_FOR_ERRORS
			if (pageframeindex == 0) {
				I_Error("couldn't find the page to set locked?");
			}
#endif
		}
	}

	for (i = 0; i < pagesize[pageframeindex]; i++) {
		if (value) {
			lockedpages[pageframeindex + i]++;
		}
		else {
			lockedpages[pageframeindex + i]--;
		}
#ifdef CHECK_FOR_ERRORS
		if (lockedpages[pageframeindex + i] < 0)
			I_Error("over de-allocated! %i %i %i %i %i", ref, lockedpages[pageframeindex + i], pageframeindex, i);
#endif
	}


}



void Z_SetUnlocked(MEMREF ref) {
	int16_t pagenumber = MAKE_PAGE(allocations[ref].page_and_size);
	int16_t pageframeindex;
	if (ref >= EMS_ALLOCATION_LIST_SIZE) {
		return; // conventionals dont need to get locked;;
	}
	for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
		if (activepages[pageframeindex] == pagenumber) {
			Z_SetUnlockedWithPage(ref, PAGE_NOT_LOCKED, pageframeindex);
			return;
		}
	}
#ifdef CHECK_FOR_ERRORS
	I_Error("Tried to unlock inactive page %i", ref);
#endif
}

//void* Z_LoadBytesFromConventionalWithOptions2(MEMREF ref, boolean locked, int16_t type, int8_t* file, int32_t line) {
void* Z_LoadBytesFromConventionalWithOptions2(MEMREF ref, boolean locked, int16_t type) {
	if (ref < EMS_ALLOCATION_LIST_SIZE) {
		return Z_LoadBytesFromEMSWithOptions2(ref, locked);
	} else {
		ref -= EMS_ALLOCATION_LIST_SIZE;
		switch (type){
			case CA_TYPE_SPRITE:
#ifdef CHECK_FOR_ERRORS
				if (ref >= SPRITE_ALLOCATION_LIST_SIZE){
					I_Error ("caught c %u %s %li", ref);
				}
#endif
				// 0 0 6bce6b20
				//I_Error("getting thing %i %i %lx", ref, sprite_allocations[ref].offset, spritememoryblock);
				return spritememoryblock + sprite_allocations[ref].offset;
			case CA_TYPE_TEXTURE_INFO:
#ifdef CHECK_FOR_ERRORS
				if (ref >= TEXTUREINFO_ALLOCATION_LIST_SIZE) {
					I_Error("caught f %u %s %li", ref);
				}
#endif
				return textureinfomemoryblock + textureinfo_allocations[ref].offset;
			default:
#ifdef CHECK_FOR_ERRORS
				if (ref >= 2*CONVENTIONAL_ALLOCATION_LIST_SIZE){
					I_Error ("caught d %u %s %li", ref);
				}
#endif
				if (ref < CONVENTIONAL_ALLOCATION_LIST_SIZE)
					return conventionalmemoryblock1 + conventional_allocations1[ref].offset;
				else 
					return conventionalmemoryblock2 + conventional_allocations2[ref- CONVENTIONAL_ALLOCATION_LIST_SIZE].offset;
		}

	}

}

extern boolean playerSpawned;

 // called in between levels, frees level stuff like sectors, frees thinkers, etc.
void Z_FreeConventionalAllocations() {

	memset(conventional_allocations1, 0, CONVENTIONAL_ALLOCATION_LIST_SIZE * sizeof(allocation_static_conventional_t));
	memset(conventional_allocations2, 0, CONVENTIONAL_ALLOCATION_LIST_SIZE * sizeof(allocation_static_conventional_t));
	
	// todo if we change this from static to dynamic, change here...
	memset(thinker_allocations, 0, THINKER_ALLOCATION_LIST_SIZE * sizeof(allocation_thinker_conventional_t));
	currentThinkerAllocationListHead = 1;
	thinkerAllocationListFull = false;

	memset(&playerMobj, 0, sizeof(mobj_t));
	playerSpawned = false;
}



// mostly very easy because we just allocate sequentially and never remove except all at once. no fragmentation
//  EXCEPT thinkers
MEMREF Z_MallocConventional( 
	uint32_t           size,
		uint8_t           tag,
		int16_t				type,
		uint8_t user,
		uint8_t sourceHint){

	allocation_static_conventional_t *allocations;
	boolean useblock2 = false;
	int16_t loopamount;
	uint16_t* ref=0;
	uint16_t* blockhead;
	uint16_t refcopy;


	//return Z_MallocEMS(size, tag, user, sourceHint);

	if (type == CA_TYPE_LEVELDATA) {
		if (size > remainingconventional1) {
			if (size > remainingconventional2) {
				return Z_MallocEMS(size, tag, user, sourceHint);
			}
			useblock2 = true;
		}
	
		if (useblock2) {
			allocations = conventional_allocations2;
			remainingconventional2 -= size;
			blockhead = &conventional2head;
			ref = &conventional2headindex;
		} else {
			allocations = conventional_allocations1;
			remainingconventional1 -= size;
			blockhead = &conventional1head;
			ref = &conventional1headindex;
		}
		loopamount = CONVENTIONAL_ALLOCATION_LIST_SIZE;
	
	
	} else if (type == CA_TYPE_SPRITE){
		if (size > remainingspriteconventional){
			return Z_MallocEMS(size, tag, user, sourceHint);
		}
		allocations = sprite_allocations;
		remainingspriteconventional -= size;
		loopamount = SPRITE_ALLOCATION_LIST_SIZE;		
		blockhead = &spritehead;
		ref = &spriteheadindex;
	} else if (type == CA_TYPE_TEXTURE_INFO){
		if (size > remainingtextureinfoconventional){
			return Z_MallocEMS(size, tag, user, sourceHint);
		}
		allocations = textureinfo_allocations;
		remainingtextureinfoconventional -= size;
		loopamount = TEXTUREINFO_ALLOCATION_LIST_SIZE;		
		blockhead = &textureinfohead;
		ref = &textureinfoheadindex;
	}
	refcopy = *ref;
	*ref = *ref +1;
 
	if (refcopy == loopamount){
		I_Error("ran out of refs for conventional allocation  %i %i", type, sourceHint);
	}

	//allocations[ref].size = size;	
	allocations[refcopy].offset = *blockhead;

	 // ref and blockhead increament up ahead..
	*blockhead += size; 
	return (refcopy) + EMS_ALLOCATION_LIST_SIZE + ( useblock2 ? CONVENTIONAL_ALLOCATION_LIST_SIZE : 0);
	
	// the below wasnt working...
	//return (*ref++) + EMS_ALLOCATION_LIST_SIZE + ( useblock2 ? CONVENTIONAL_ALLOCATION_LIST_SIZE : 0);
}

// Unlike other conventional allocations, these are freed and cause fragmentation of the memory block

#define THINKERS_PER_PAGE (PAGE_FRAME_SIZE / THINKER_BLOCK_SIZE)

void* Z_LoadThinkerBytesFromEMS2(MEMREF ref) {
	uint16_t refcounter = ref;
	uint16_t pageframeindex;
	uint16_t offset;
	uint32_t page_and_size = 0;
	
	if (ref == PLAYER_MOBJ_REF) {
		return &playerMobj;
	}

	// 97 bytes or whatever doesnt go into 16384 cleanly, 
	// so we will skip bytes at the end of ems page this way
	while (refcounter > THINKERS_PER_PAGE) {
		page_and_size += (int32_t)0x800000; // 1 << PAGE_AND_SIZE_SHIFT
		refcounter -= THINKERS_PER_PAGE;
	}

	offset = (refcounter * THINKER_BLOCK_SIZE);
	page_and_size += THINKER_BLOCK_SIZE;

	pageframeindex = Z_GetEMSPageFrame(page_and_size, false);

	return (byte*)pageFrameArea
		+ PAGE_FRAME_SIZE * pageframeindex
		+ offset;

}

MEMREF Z_MallocThinkerEMS(
	uint8_t           size
) {

	if (thinkerAllocationListFull || (currentThinkerAllocationListHead > (MAX_THINKERS))) {
		// we've exhausted the first 1000 thinker allocations and now things are fragmented and we have to loop to find a free allocation
		int16_t i = 0;
		if (!thinkerAllocationListFull) {
			thinkerAllocationListFull = true;
			currentThinkerAllocationListHead = 1;
		}
		for (i = 0; i < MAX_THINKERS; i++) {
			if (currentThinkerAllocationListHead > MAX_THINKERS) {
				currentThinkerAllocationListHead = 1;
			}
			if (!thinker_allocations[currentThinkerAllocationListHead].active) {
				goto foundthinkerslot;
			}
				
			currentThinkerAllocationListHead++;
		}
		I_Error("out of thinkers");
	}
	foundthinkerslot:
	thinker_allocations[currentThinkerAllocationListHead].active = true;
	currentThinkerAllocationListHead++;

	// todo looping and freeing?
	// looping at memory page edge?
	return currentThinkerAllocationListHead -1;
}


void* Z_LoadBytesFromEMSWithOptions2(MEMREF ref, boolean locked) {
//void* Z_LoadBytesFromEMSWithOptions2(MEMREF ref, boolean locked) {
	uint16_t pageframeindex;

#ifdef CHECK_FOR_ERRORS
	if (ref >= EMS_ALLOCATION_LIST_SIZE) {
		//I_Error("out of bounds memref.. tick %li    %i %s %i", gametic, ref, file, line);
		I_Error("\nout of bounds memref.. tick %li    %i ", gametic, ref);
	}
	if (ref == 0) {
		//I_Error("out of bounds memref.. tick %li    %i %s %i", gametic, ref, file, line);
		I_Error("\ntried to load memref 0... tick %i    %i", gametic, ref);
	}
#endif

 
	pageframeindex = Z_GetEMSPageFrame(allocations[ref].page_and_size, locked);

	if (locked) {
		// todo pass in page frame index.
		Z_SetUnlockedWithPage(ref, PAGE_LOCKED, pageframeindex);
	}

	return (byte*)pageFrameArea
		+ PAGE_FRAME_SIZE * pageframeindex
		+ MAKE_OFFSET(allocations[ref]);

	
}

#ifdef MEMORYCHECK


int16_t getNumFreePages() {
	int16_t i = 0;
	int16_t total = 0;
	for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++) {
		if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE) {
			total++;
		}

	}
	return total;
}

int32_t getFreeMemoryByteTotal() {
	int16_t i = 0;
	int32_t total = 0;
	for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++) {
		if (!HAS_USER(allocations[i])) {

			total += allocations[i].size;
		}
	}
	return total;
}


int32_t getBiggestFreeBlock() {
	int16_t i = 0;
	int32_t total = 0;
	for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++) {
		if (!HAS_USER(allocations[i])) {

			if (allocations[i].size > total)
				total = allocations[i].size;
		}

	}
	return total;
}

int16_t getBiggestFreeBlockIndex() {
	int16_t i = 0;
	int32_t total = 0;
	int16_t totali = 0;
	for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++) {
		if (!HAS_USER(allocations[i])) {

			if (allocations[i].size > total) {
				total = allocations[i].size;
				totali = i;
			}
		}

	}
	return totali;
}

int16_t getNumPurgeableBlocks() {
	int16_t i = 0;
	int16_t total = 0;
	for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++) {
		if (!allocations[i].tag >= PU_PURGELEVEL && HAS_USER(allocations[i].user)) {
			total++;
		}

	}
	return total;
}
#endif

// Gets the next unused spot in the doubly linked list of allocations
// NOTE: this does not mean it gets the next "free block of memory"
// so we are not looking for an unused block of memory, but an unused
// array index. We use allocations[x].prev == [list size] to mark indices
// unused/unallocated

PAGEREF Z_GetNextFreeArrayIndex() {
	PAGEREF i;

	for (i = currentListHead + 1; i != currentListHead; i++) {
		if (i == EMS_ALLOCATION_LIST_SIZE) {
			i = 0;
		}

		if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE) {
			return i;
		}

	}


#ifdef CHECK_FOR_ERRORS
	I_Error("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ", -1, -1, -1);
#endif
	// error case

#ifdef MEMORYCHECK
	I_Error("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ", getNumFreePages(), getFreeMemoryByteTotal(), getBiggestFreeBlock());
#endif

	return -1;

}


MEMREF Z_MallocEMS
(uint32_t           size,
	uint8_t tag,
	uint8_t user,
	uint8_t sourceHint)
{
	return Z_MallocEMSWithBackRef(size, tag, user, sourceHint, -1);
}
MEMREF
Z_MallocEMSWithBackRef
(uint32_t           size,
	uint8_t           tag,
	uint8_t user,
	uint8_t sourceHint,
	int16_t backRef)
{
	int16_t base;
	int16_t start;
	int16_t newfreeblockindex;

	int32_t         extra;
	int16_t rover;
	uint16_t offsetToNextPage = 0;



#ifdef CHECK_FOR_ERRORS
	if (tag == 0) {
		I_Error("tag cannot be 0!");
	}
#endif
	// TODO : make use of sourceHint?
	// ideally alllocations with the same sourceHint try to be in the same block if possible
	// but even if they cannot be, the engine should not crash or anything


#ifdef CHECK_FOR_ERRORS

	if (size > MAX_ZMALLOC_SIZE) {
	//if (size & 0xffff0000) {
		I_Error("Z_MallocEMS: allocation too big! size was %i bytes %i %i %i", size, tag, user, sourceHint);
	}
#endif
	// todo get rid of this? 32 bit relic?
	size = (size + 3) & ~3;


	// algorithm:


		// scan through the block list,
		// looking for the first free block
		// of sufficient size,
		// throwing out any purgable blocks along the way.

	base = currentListHead;



	if (!HAS_USER(allocations[allocations[base].prev])) {
		base = allocations[base].prev;

	}


	rover = base;
	start = allocations[base].prev;

	offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t)allocations[base].offset_and_tag & 0x3FFF));
	if (offsetToNextPage == PAGE_FRAME_SIZE) {
		offsetToNextPage = 0;
	}



	do
	{

 

#ifdef CHECK_FOR_ERRORS
		if (rover == start) {
			// scanned all the way around the list
			I_Error("Z_MallocEMS: failed on allocation of %u bytes tag %i  and %i\n\n", size, tag, allocations[start].page_and_size);
		}
#endif

		// not empty but might be purgeable
		if (HAS_USER(allocations[rover])) {
			// not purgeable, reset



// problem is base (1) has a user. user should be 0


			if (allocations[rover].offset_and_tag < 0xC000) {  //  tag < PU_PURGELEVEL
				// hit a block that can't be purged,
				//  so move base past it
				base = rover = allocations[rover].next;


				// purgeable, so purge
			}
			else {  // tag is > PU_PURGELEVEL
			 // free this block (connect the links, add size to base)

				base = allocations[base].prev;
				Z_FreeEMS(rover);
				base = allocations[base].next;
				rover = allocations[base].next;
			}
			offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t)allocations[base].offset_and_tag & 0x3FFF)) % PAGE_FRAME_SIZE;

		}
		else {
			// empty, add to current block..
			rover = allocations[rover].next;
		}


	} while (HAS_USER(allocations[base]) || MAKE_SIZE(allocations[base].page_and_size) < size
		// problem: free block, and size is big enough but not aligned to page frame and we dont want to split page frame
		// so we must check that the block has enough free space when aligned to next page frame
		|| (size + (offsetToNextPage) > MAKE_SIZE(allocations[base].page_and_size))
		);



	// found a block big enough
	extra = MAKE_SIZE(allocations[base].page_and_size) - size;


	offsetToNextPage = (PAGE_FRAME_SIZE - (allocations[base].offset_and_tag & 0x3FFF));
	if (offsetToNextPage == PAGE_FRAME_SIZE) {
		offsetToNextPage = 0;
	}


	// handle the case where we push to the next frame. create a free block before it.
	if (offsetToNextPage != 0 && size > offsetToNextPage)
	{

		// insert a new free block here..

		newfreeblockindex = Z_GetNextFreeArrayIndex();



		allocations[newfreeblockindex].prev = allocations[base].prev;
		allocations[allocations[base].prev].next = newfreeblockindex;
		allocations[newfreeblockindex].next = base;
		allocations[base].prev = newfreeblockindex;


		allocations[newfreeblockindex].page_and_size = (allocations[base].page_and_size & PAGE_MASK) + offsetToNextPage;


		// using tag NOT_IN_USE
		allocations[newfreeblockindex].offset_and_tag = MAKE_OFFSET(allocations[base]);

		// implies -1 backref and 0 user
		allocations[newfreeblockindex].backref_and_user = (int16_t)INVERSE_USER_MASK;

		allocations[base].page_and_size -= offsetToNextPage;
		// todo are we okay with respect to not wrapping around? should never happen because initial size should be set in a way this doesnt happen?
		allocations[base].page_and_size += (int32_t)0x800000; // 1 << PAGE_AND_SIZE_SHIFT
		allocations[base].offset_and_tag = 0;

		extra = extra - offsetToNextPage;


	}



	// after this call, newfragment -> next is mainblock
	// base-> next is newfragment
	// base-> prev is the last newfragment in the last call




	offsetToNextPage = (PAGE_FRAME_SIZE - ((allocations[base].offset_and_tag) & 0x3FFF));
	// In this case, PAGE FRAME SIZE is ok/expected.


	if (extra > MINFRAGMENT)
	{


		// there will be a free fragment after the allocated block
		newfreeblockindex = Z_GetNextFreeArrayIndex();



		allocations[newfreeblockindex].prev = base;
		allocations[newfreeblockindex].next = allocations[base].next;
		allocations[allocations[newfreeblockindex].next].prev = newfreeblockindex;
		// implied tag NOT_IN_USE
		allocations[newfreeblockindex].offset_and_tag = (allocations[base].offset_and_tag + (size)) & 0x3FFF;
		// implies -1 backref and 0 user
		allocations[newfreeblockindex].backref_and_user = 0;





		allocations[newfreeblockindex].page_and_size =
			(allocations[base].page_and_size & PAGE_MASK) +
			(((MAKE_OFFSET(allocations[base]) + size) >> PAGE_FRAME_BITS) << PAGE_AND_SIZE_SHIFT)
			+ (extra);



		// divide by 16k

		allocations[base].next = newfreeblockindex;
		allocations[base].page_and_size =
			(allocations[base].page_and_size & PAGE_MASK) +
			(size);




	}

	if (user) {
		// mark as an in use block
		allocations[base].backref_and_user |= USER_MASK;


	}
	else {

#ifdef CHECK_FOR_ERRORS
		if (tag >= PU_PURGELEVEL)
			I_Error("Z_Malloc: an owner is required 4 purgable blocks");
#endif
		// mark as in use, but unowned  
		allocations[base].backref_and_user &= INVERSE_USER_MASK;

	}



	SET_TAG(allocations[base], tag);
	SET_BACKREF(allocations[base], backRef);
#ifdef PROFILE_PAGE_COUNT
	allocations[base].sourcehint = sourceHint;
#endif

	// next allocation will start looking here
	//mainzoneEMS->rover = base->next;
	// TODO   use rover.next or currentlisthead?
	currentListHead = allocations[base].next;




	// todo activate page
#ifdef MEMORYCHECK
	Z_CheckEMSAllocations(base, 0, 0, 0);
#endif



	return base;
	//return (void *) ((byte *)mainzoneEMS + ( allocations[base].page * PAGE_FRAME_SIZE + allocations[base].offset ) );

}

#ifdef MEMORYCHECK
int32_t GetBlockAddress(PAGEREF block) {
	return MAKE_PAGE(allocations[block].page_and_size) * PAGE_FRAME_SIZE + allocations[block].offset;
}

void Z_CheckEMSAllocations(PAGEREF block) {

	// all allocation entries should either be in the chain (linked list)
	// OR marked as a free index (prev = EMS_ALLOCATION_LIST_SIZE)

	int16_t unalloactedIndexCount = getNumFreePages();
	int16_t start = allocations[block].prev;
	int16_t iterCount = 1;
	while (start != block) {

		iterCount++;
#ifdef CHECK_FOR_ERRORS
		if (iterCount > EMS_ALLOCATION_LIST_SIZE) {
			I_Error("\nZ_CheckEMSAllocations: infinite loop detected with block start %i %i %i %i %i %i %i", start, iterCount, getNumFreePages(), getFreeMemoryByteTotal(), getNumPurgeableBlocks, getBiggestFreeBlock(), getBiggestFreeBlockIndex());
		}
#endif
		block = allocations[block].next;
	}

	/*    printf("\n0:  %i %i %i", allocations[0].prev, allocations[0].next, allocations[0].size);
		printf("\n1:  %i %i %i", allocations[1].prev, allocations[1].next, allocations[1].size);
		printf("\n2:  %i %i %i", allocations[2].prev, allocations[2].next, allocations[2].size);
	  */

#ifdef CHECK_FOR_ERRORS
	if (unalloactedIndexCount + iterCount != EMS_ALLOCATION_LIST_SIZE) {
		I_Error("\nZ_CheckEMSAllocations: %i unallocated indices, %i rover size, %i expected list size", unalloactedIndexCount, iterCount, EMS_ALLOCATION_LIST_SIZE);
	}
#endif


	// Now check if consecutive empties
	for (block = allocations[start].next; ; block = allocations[block].next) {

		/*
				if (block->tag >= lowtag && block->tag <= hightag)
					printf ("block:%p    size:%7i    user:%p    tag:%3i\n",
							block, block->size, block->user, block->tag);*/


		if (block == start)
		{
			// all blocks have been hit
			break;
		}

		if (GetBlockAddress(block) + allocations[block].size != GetBlockAddress(allocations[block].next) && GetBlockAddress(allocations[block].next) != 0) {
			I_Error("ERROR: block size does not touch the next block %i %i %i %i %i %i %i %i\n", GetBlockAddress(block), allocations[block].size, GetBlockAddress(allocations[block].next), block, start, allocations[block].next);
		}

		if (allocations[allocations[block].next].prev != block) {
			I_Error("ERROR: next block doesn't have proper back link\n");
		}

		if (!allocations[block].user && !allocations[allocations[block].next].user) {
			I_Error("ERROR: two consecutive free blocks\n");
		}
	}
}
#endif


#ifdef _M_I86
byte *I_ZoneBaseEMS(int32_t *size, int16_t *emshandle);
#else
byte *I_ZoneBaseEMS(int32_t *size);
#endif


void Z_InitEMS(void)
{

	int32_t size;
	int16_t i = 0;
	//todo figure this out based on settings, hardware, etc
	int32_t pageframeareasize = NUM_EMS_PAGES * PAGE_FRAME_SIZE;

#ifdef _M_I86
	pageFrameArea = I_ZoneBaseEMS(&size, &emshandle);
	
#else
	pageFrameArea = I_ZoneBaseEMS(&size);
	EMSArea = ((byte*)pageFrameArea + pageframeareasize);
#endif



	//printf("EMS zone location  %p\n", pageFrameArea);
	//printf("Allocated size in z_initEMS was %li or %p\n", size, size);
	// mark ems pages unused
	for (i = 0; i < NUM_EMS_PAGES; i++) {
		activepages[i] = -1;
		pageevictorder[i] = i;
		pagesize[i] = -1;
	}

	// prepare the link indices? as allocations and deallocations happen
	// the links wont be in order, but these presets 
	allocations[0].next = 1;
	allocations[0].prev = 1;
	// Start the allocation list and page (num thinker pages)
	allocations[0].page_and_size = NUM_THINKER_PAGES << PAGE_AND_SIZE_SHIFT;
	allocations[0].backref_and_user = USER_MASK;
	allocations[0].offset_and_tag = 0x4000;// PU_STATIC, 0 offset

	allocations[1].next = 0;
	allocations[1].prev = 0;
	allocations[1].backref_and_user = 0;
	// Start the allocation list and page (num thinker pages)
	allocations[1].page_and_size = size + (NUM_THINKER_PAGES << PAGE_AND_SIZE_SHIFT);

	allocations[1].offset_and_tag = 0x4000;// PU_STATIC, 0 offset

	// use this index to mark an unused block..
	for (i = 2; i < EMS_ALLOCATION_LIST_SIZE; i++) {
		allocations[i].prev = EMS_ALLOCATION_LIST_SIZE;
	}
	currentListHead = 1;
}



