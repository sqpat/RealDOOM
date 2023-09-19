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

#include <dos.h>
#include <stdlib.h>
#include <malloc.h>


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

// 20 11180047 16 1   14 health
// 20 11179909 16 1   14 health


// 13 11165535 17252 19333
// 12 11195222 26340 28968
// 12 11195029 26301 28909  < discrepency?
// 12 11195017 26301 28908  12% health
// 12 11194907 26331 28957  12% health
// 12 11187592 26278 28854  
// 12 11194989 26348 28980  12% health



// 13 11791514 17394 19472 14% 207
// 12 11791300 26025 28650 14% 207
// 11 11791407 39107 44269 14% 207
// 10 11790714 56451 65828 14% 207

// 9  11746226 75692 89281 207
// 8 11744336 123321 155180 207
// 7 11508909 176129 226035 207
// 6 11494858 232827 298074 207
// 5 11430693 347033 451908 207
// 4 11446037 645867 922684 207

// after sidedefs, lines

// 5 12873066 1300704 2714124 207  (2134 in 5639)
// 4 12987667 1617971 3137312 207  (2134 in 6062)

// after lots of wad stuff
// 4 14588095 2151855 4282095 207  (2134 in 8305new comp)

// after sectors
// 16 14918439 208260 295358 207 (2134 in 1859)
// 4 14918437 2361076 4498999 207 (2134 in 9112)

// 4 14918435 2361076 4498999 207 (2134 in 9225) after reducing code, incl function pointer changes
// 4 14918435 2363430 4501352 207 (2134 in 9223) major info.c changes
// 4 14870125 2361729 4499651 207 (2134 in 9263) enum removals and fastdoom netplay/code removal imports
// 4 14872259 2361729 4499651 207 (2134 in 9287) removed joystick code
// 4 14834692 2361729 4499651 207 (2134 in 9211) removed more code
// 4 14822330 1697415 2770423 207 (2134 in)		 after all the 32 to 16 bit stuff

// 4 17810546 2821496 4206470 207       <--- with EMS based visplanes. really rough hit.
// 4 14821970 1691340 2764279 207        <--- sector floor/ceil 16 bit
// 4 14821970 1691110 2764049 207        <--- tex w/h 8 bit
// 4 14821971 1691041 2763930 207     <--- a lot more fields reduced on sector line etc... no big difference in paging?
// 4 14821971 1685501 2389170 207 (2134 in 4935)    <--- some bounding box stuff made 16 bits
// 4 14821971 1447746 1993284 207 (2134 in 4200)    <---- node bounding box stuff made 16 bits
// 4 14199294 1142934 1517335 207 (2134 in 3685)    <----- got rid of multiplayer for good
// 4 14199294 1142934 1517335 207 (2134 in 3689)    <----- got rid of netplay
// 4 17197007 2259978 2948257 207 (2134 in 6579)    <----- tried ems visplanes again
// 4 16620699 2224028 2911385 207 (2134 in 6864)    <----- tried ems visplanes again, with fixed paging.

// 4 16624733 2224018 2911371 207 (2134 in 6903)    <----- ems visplanes again, with bugfixes
// 4 16632880 2228730 2917927 207 (2134 in 7135)    <----- ems visplanes, bugfixed for 4 pages

// 4 13653120 1145838 1520843 207 (2134 in 4087)    <----- conventional visplanes 4 pages 
// 4 17437089 2184185 2899356 207 (2134 in 6845)    <----- ems visplanes with mobj thinker sticky page
// 4 17433911 2184185 2899356 207 (2134 in 6868)    <----- ^^  
// 4 17415864 2184181 2899349 207 (2134 in 6781)    <----- ^^  
// 4 17526550 2184181 2899349 207 (2134 in 6812)    <----- ^^  
// 4 17431288 2204871 2928938 207 (2134 in 6831)    <----- ^^  

// 4 16293123 2766196 3489654 207 (2134 in 7961)    <- passing around mobj instead of ref. Fewer reads but more thrashing?? by a lot???
// 8 16284007 1068989 1174227 207 (2134 in 3271)    <- same as above but 8
// 8 13306434 994631  1094351 207 (2134 in 3023)    <- same as above with 8 but with conventional visplanes

// 4 16594448 2234408 2923606 207 (2134 in 6860)    <- back to pre-locking. ems visplanes
// 4 13616875 1151662 1526661 207 (2134 in 3843)    <- back to pre-locking. conventional visplanes
// 4 13616875 1151662 1526661 207 (2134 in 3843)    <- back to pre-locking. conventional visplanes


// 4 13315550 1684755 2094035 207 (2134 in 4959)    <- locking in PIT_
// 4 13522324 11193610 1568681 207 (2134 in 3926)    <- locking in R_ProjectSprite

// 4 16594448 2234441 2923661 207 (2134 in 6367)    <----- after removing the 16 bit warnings


// 4 13578495 1151503 1526490 207 (2134 in 3766)  <--- long long fixeddiv, index visplanes, removed cheats, removed translation tables
// 4 12154692 1144295 1515989 207 (2134 in 3918)  <--- cleaned up init code, memref arrays made static
// 4  9780880 1144286 1515980 207 (2134 in 3850)  <--- more static memref arrays
// 4  9784299 1145354 1518415 207 (2134 in 3771)
// 4  9783841 1145337 1518399 207 (2134 in 3812)
// 4  9783827 1145334 1518397 207 (2134 in 3823)
// 4  9707835 1094939 1468082 207 (2134 in 3721)  <- translation tables to memory
// 4  9727235 1095037 1468186 207 (2134 in 3804)  <- blockmaps as 16 bit?
// 4  9727235 1223378 1597109 207 (2134 in 4071)  <- line flags 8 bit, mapped in v1offset, slopetype in v2offset
// 4  9727235 1223379 1597109 207 (2134 in 4071)  <- line bounding boxes changed
// 4  9100444 584187  675843  207 (2134 in 2304)  <- lines fudged into conventional 
// 4  8460235 464178  532405  207 (2134 in 1863)  <- 64k conventional space first come first serve.

// 4  4527347 1637252 1995397 151 (2134 in 37821) <- first 16 bit run with d_display and text mode debug
// 4  4510266 1630139 1989477 151 (2134 in 34757) <- first 16 bit run with d_display and text mode debug

// 4  9688463 1219770 1591390 207 (2134 in 3662)  <- no conventional, post some cleanup, different cpu
// 4  9050016 732304  967816  207 (2134 in 2563)  <- after wad lump cleanup, some conventional freed up


// 8 13569197 422735  521499  207 (2134 in 1843)  <---- same as above with 8
// 8 13578495 422543  521292  207 (2134 in 1851)  <---- same as above with the EMS_PAGE check changed to 16. maybe it doesnt help performance at all?

 // CONCLUSION: page locking is not helping ? lru just wins?


// 64 14821801 279 262 207 (2134 in 2186)
// 64 14821801 279 262 207 (2134 in 2163)  // redo draws
// 32 14821801 47815 55080 207 (2134 in 2001)  // redo some net code and such
// 32 14821801 47815 55080 207 (2134 in 1869)  // some various optimizations copied over from fastdoom
   // 1828 after some r_bsp redos
   // 1782 multiplayer mostly removed
   // 1849 redid sine tables with function lookup

// demo 1
// 4 26890040 1545385 2221063 181
// 4 26693807 1545283 2220732 181

// 4 27529006 1413669 2119421 181

// after sidedefs:

// 4 27594330 2009571 2836062 181

// after lines
// 32 29792581      23 1       181
// 16 29792218  154693 207202  181
// 8 29789279  1169872 1868816 181
// 4 29785273  3061492 5564953 181


// after all but sectors:
// 4 33851350  3687662 6452365 181  5026 in 14811


// after sectors :
// 16 34504173 310429 398971 181 5026 in 4150
// 4  34506371 3893022 6696821 181 5026 in 15635

// demo 2 

// after all but sectors
// 4 22437957  3266557 6213387 75
// after sectors
// 4 22844306  3540729 6493412 75

#define ALLOCATION_LIST_HEAD	0

#define MINFRAGMENT             64
#define EMS_MINFRAGMENT         32
#define EMS_ALLOCATION_LIST_SIZE 2048
// we dont make many conventional allocations, only a small number of important ones
#define CONVENTIONAL_ALLOCATION_LIST_SIZE 16
// todo make this PAGE * PAGE SIZE 
#define MAX_ZMALLOC_SIZE 0x10000L

// demo commented out...



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
	PAGEREF prev;    //2    using 16 bits but need 11 or 12...
	PAGEREF next;    //4    using 16 bits but need 11 or 12...         these 3 could fit in 32 bits?

	// page and offset refer to internal EMS page and offset - in other words the keys
	// to find the real location in memory for this allocation

	// page;       using 9 bits... implies page max count of 512 (8 MB worth)
	// size;        use 23 bits implying max of 8MB-1 or 0x007FFFFF max free size,
	uint32_t page_and_size; // page is 9 high bits, size is 23 low bits
	// todo: optimize uses of the page 9 bits to use int_16t arithmetic instead of int_32t. Maybe using unions?

	// offset is the location within the page frame. 16kb page frame size means
	// 14 bits needed. Tag is a 2 bit field stored in the two high bits. Used to
	// managecaching behavior
	uint16_t offset_and_tag;  //10
	// user is sort of a standby of the old code but implies the block has an
	// "owner". it combines with the tag field to determine a couple behaviors. 
	// backref is an index passed to external caches when the allocation is
	// deleted so the caches can also be cleared. Used in compositeTextures
	// and wad lumps
	uint16_t backref_and_user;  //12 bytes per struct, dont think we can do better.

#ifdef PROFILE_PAGE_COUNT
	int8_t sourcehint;
#endif
} allocation_t;


typedef struct
{
	uint16_t size;
	void*	datalocation;
} allocation_conventional_t;


// ugly... but it does work. I don't think we can ever make use of more than 2 so no need to listify
void* conventionalmemoryblock1;
void* conventionalmemoryblock2;
uint16_t totalconventionalfree1;
uint16_t totalconventionalfree2;
uint16_t remainingconventional1;
uint16_t remainingconventional2;

PAGEREF currentListHead = ALLOCATION_LIST_HEAD; // main rover

allocation_t allocations[EMS_ALLOCATION_LIST_SIZE];
allocation_conventional_t conventional_allocations1[CONVENTIONAL_ALLOCATION_LIST_SIZE];
allocation_conventional_t conventional_allocations2[CONVENTIONAL_ALLOCATION_LIST_SIZE];


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
#endif

byte*			pageFrameArea;
byte*			EMSArea;

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

void Z_ChangeTagEMSNew(MEMREF index, int16_t tag) {


	// if tag is equal to PU_PURGELEVEL
#ifdef CHECK_FOR_ERRORS
	if ((allocations[index].offset_and_tag & 0xC000) == 0xC000 && !HAS_USER(allocations[index])) {
		I_Error("Z_ChangeTagEMSNew: an owner is required for purgable blocks %i %i %i %i %i",
			allocations[index].offset_and_tag,
			tag,
			index,
			allocations[index].backref_and_user,
			HAS_USER(allocations[index]));
	}
#endif
	SET_TAG(allocations[index], tag);
}



// CONVENTIONAL MEMORY ALLOCATION STUFF

uint16_t Z_GetFreeConventionalSize(void** block) {

	// around 20k 16 bit right now.
#ifdef _M_I86
	uint16_t size = MAX_CONVENTIONAL_ALLOCATION_SIZE;
#else
	size_t size = _memmax();
	if (size > MAX_CONVENTIONAL_ALLOCATION_SIZE) {
		size = MAX_CONVENTIONAL_ALLOCATION_SIZE;
	}
#endif
	while (size >= MIN_CONVENTIONAL_ALLOCATION_SIZE) {
#ifdef _M_I86
		*block = _fmalloc(size);
#else
		*block = _nmalloc(size);
#endif
		if (*block) {
			return size;
		}
		size -= 1024;
	}

	return 0;
}
void Z_InitConventional(void) {
	DEBUG_PRINT("Initializing conventional allocation blocks...");
	totalconventionalfree1 = Z_GetFreeConventionalSize(&conventionalmemoryblock1);
	remainingconventional1 = totalconventionalfree1;

	totalconventionalfree2 = Z_GetFreeConventionalSize(&conventionalmemoryblock2);
	remainingconventional2 = totalconventionalfree2;
	DEBUG_PRINT("\Conventional block sizes %u %u\n", totalconventionalfree1, totalconventionalfree2);
}

// EMS STUFF


//
// Z_InitEMS
//


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
	//printf("Allocated size in z_initEMS was %i or %p\n", size, size);
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
	allocations[0].page_and_size = 0;
	allocations[0].backref_and_user = USER_MASK;
	allocations[0].offset_and_tag = 0x4000;// PU_STATIC, 0 offset

	allocations[1].next = 0;
	allocations[1].prev = 0;
	allocations[1].backref_and_user = 0;
	allocations[1].page_and_size = size;
	allocations[1].offset_and_tag = 0x4000;// PU_STATIC, 0 offset

	// use this index to mark an unused block..
	for (i = 2; i < EMS_ALLOCATION_LIST_SIZE; i++) {
		allocations[i].prev = EMS_ALLOCATION_LIST_SIZE;
	}
	currentListHead = 1;
}


void Z_FreeEMSNew(PAGEREF block) {


	uint16_t         other;

#ifdef CHECK_FOR_ERRORS
	if (block == ALLOCATION_LIST_HEAD) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		I_Error("ERROR: Called Z_FreeEMSNew with 0! \n");
	}

	if (block >= EMS_ALLOCATION_LIST_SIZE) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		I_Error("ERROR: Called Z_FreeEMSNew with too big of size: max %i vs %i! \n", EMS_ALLOCATION_LIST_SIZE - 1, block);
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
			Z_FreeEMSNew(block);
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
			I_Error("Z_RefIsActive: alloc too big %i ", memref);
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
		I_Error("Mapping failed on page %i!\n", pageframeindex+i);
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
			I_Error("Mapping failed on page %i %i %i %i %i %i %i %i!\n", activepages[pageframeindex + i], i, pageframeindex, logicalpage, pageins, actualpageins, pageouts, actualpageouts);
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

void Z_ShutdownEMS() {


#ifdef _M_I86
	int16_t result;
	
	if (emshandle){

		regs.w.dx = emshandle; // handle
		regs.h.ah = 0x45;
		intx86(EMS_INT, &regs, &regs);
		result = regs.h.ah;
		if (result != 0) {
			printf("Failed deallocating EMS memory! %i!\n", result);
		}
	}
#endif

	free(conventionalmemoryblock1);
	free(conventionalmemoryblock2);

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

//int16_t Z_GetEMSPageFrame(uint32_t page_and_size, MEMREF ref, boolean locked, int8_t* file, int32_t line) {  //todo allocations < 65k? if so size can be an uint16_t?
int16_t Z_GetEMSPageFrame(uint32_t page_and_size, MEMREF ref, boolean locked) {  //todo allocations < 65k? if so size can be an uint16_t?
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

					I_Error("forcing out locked page? %i %i  %i", i, ref, MAKE_SIZE(allocations[i].page_and_size));

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
						I_Error("forcing out %i %i %i %i %i", i, ref, MAKE_SIZE(allocations[i].page_and_size), allocations[i].sourcehint, ((mobj_t*) (allocations[i].sourcehint))->type );
					}
				}
				*/

			Z_DoPageIn(logicalpage, pageframeindex, numallocatepages);
			pageins++;

			return pageframeindex;

		}

#ifdef CHECK_FOR_ERRORS
		I_Error("couldnt find page to deallocate for a locked page? %i %i  %i", i, ref, MAKE_SIZE(allocations[i].page_and_size));
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

			//Z_PageDump("Could not find EMS page to evict!  %i ", line);
			//Z_PageDump("Could not find EMS page to evict! %i ", (allocations[ref].sourcehint));
			//Z_PageDump("Could not find EMS page to evict! %i ", (allocations[ref].sourcehint));
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
				// linesref is page 2.. logical page 128
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



void* Z_LoadBytesFromConventionalWithOptions2(MEMREF ref, boolean locked, int8_t* file, int32_t line) {

	if (ref < EMS_ALLOCATION_LIST_SIZE) {
		return Z_LoadBytesFromEMSWithOptions2(ref, locked, file, line);
		//return Z_LoadBytesFromEMSWithOptions(ref, locked);
	}
	ref -= EMS_ALLOCATION_LIST_SIZE;

#ifdef CHECK_FOR_ERRORS
	if (ref >= 2* CONVENTIONAL_ALLOCATION_LIST_SIZE) {
		I_Error("Conventional allocation too big! %i", ref);
	}
#endif
	if (ref < CONVENTIONAL_ALLOCATION_LIST_SIZE)
		return conventional_allocations1[ref].datalocation;
	else 
		return conventional_allocations2[ref- CONVENTIONAL_ALLOCATION_LIST_SIZE].datalocation;

}

 
void Z_FreeConventionalAllocations() {
	int8_t i = 0;

	for (i = 0; i < CONVENTIONAL_ALLOCATION_LIST_SIZE; i++) {
		conventional_allocations1[i].datalocation = 0;
		conventional_allocations1[i].size = 0;
		conventional_allocations2[i].datalocation = 0;
		conventional_allocations2[i].size = 0;
	}

}

// very easy because we just do it linearly and never remove except all at once. no fragmentation
MEMREF Z_MallocConventional( 
	uint32_t           size,
		uint8_t           tag,
		uint8_t user,
		uint8_t sourceHint){

	int8_t ref;
	byte* datalocation;
	allocation_conventional_t *allocations;
	boolean useblock2 = false;
	
	if (size > remainingconventional1) {
		if (size > remainingconventional2) {
			return Z_MallocEMSNew(size, tag, user, sourceHint);
		}
		useblock2 = true;
	}
	if (useblock2) {
		datalocation = conventionalmemoryblock2;
		allocations = conventional_allocations2;
		remainingconventional2 -= size;
	} else {
		datalocation = conventionalmemoryblock1;
		allocations = conventional_allocations1;
		remainingconventional1 -= size;
	}

	for (ref = 0; ref < CONVENTIONAL_ALLOCATION_LIST_SIZE; ref++) {
		if (allocations[ref].size == 0) {
			break;
		}
		datalocation += allocations[ref].size;
 
	}

	allocations[ref].size = size;
	allocations[ref].datalocation = datalocation;
	 
	return ref + EMS_ALLOCATION_LIST_SIZE + ( useblock2 ? CONVENTIONAL_ALLOCATION_LIST_SIZE : 0);
}



void* Z_LoadBytesFromEMSWithOptions2(MEMREF ref, boolean locked, int8_t* file, int32_t line) {
//void* Z_LoadBytesFromEMSWithOptions2(MEMREF ref, boolean locked) {
	byte* memorybase;
	uint16_t pageframeindex;
	byte* address;

#ifdef CHECK_FOR_ERRORS
	if (ref >= EMS_ALLOCATION_LIST_SIZE) {
		I_Error("out of bounds memref.. tick %li    %i %s %i", gametic, ref, file, line);
		//I_Error("\nout of bounds memref.. tick %li    %i ", gametic, ref);
	}
	if (ref == 0) {
		I_Error("out of bounds memref.. tick %li    %i %s %i", gametic, ref, file, line);
		//I_Error("\ntried to load memref 0... tick %i    %i", gametic, ref);
	}
#endif

	/*
	if (allocations[ref].page_and_size == 0xf6800af4) {
		I_Error("blah found it");
	}
	I_Error("\nother first %lx %i %i", allocations[ref].page_and_size, ref, locked);
	*/

	pageframeindex = Z_GetEMSPageFrame(allocations[ref].page_and_size, ref, locked);
	memorybase = (byte*)pageFrameArea;

	if (locked) {
		// todo pass in page frame index.
		Z_SetUnlockedWithPage(ref, PAGE_LOCKED, pageframeindex);
	}

	address = memorybase
		+ PAGE_FRAME_SIZE * pageframeindex
		+ MAKE_OFFSET(allocations[ref]);

	return (byte *)address;
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


MEMREF Z_MallocEMSNew
(uint32_t           size,
	uint8_t tag,
	uint8_t user,
	uint8_t sourceHint)
{
	return Z_MallocEMSNewWithBackRef(size, tag, user, sourceHint, -1);
}
MEMREF
Z_MallocEMSNewWithBackRef
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
			I_Error("Z_MallocEMSNew: failed on allocation of %u bytes tag %i  and %i\n\n", size, tag, allocations[start].page_and_size);
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
				Z_FreeEMSNew(rover);
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


	if (extra > EMS_MINFRAGMENT)
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


