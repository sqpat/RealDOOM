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


#define MINFRAGMENT             64
#define EMS_MINFRAGMENT         32
#define EMS_ALLOCATION_LIST_SIZE 2048
#define NUM_EMS_PAGES 4
// todo make this PAGE * PAGE SIZE 
#define MAX_ZMALLOC_SIZE 64 * 1024

// demo commented out...



// 8 MB worth. Letting us set 8 MB as a max lets us get away with 
// some smaller allocation_t sies
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
							
} allocation_t;

//#define OWNED_USER 2
//#define UNOWNED_USER 1



PAGEREF currentListHead = 0; // main rover

allocation_t allocations[EMS_ALLOCATION_LIST_SIZE];


int16_t activepages[NUM_EMS_PAGES];
int8_t pageevictorder[NUM_EMS_PAGES];
int8_t pagesize[NUM_EMS_PAGES];


// 4 pages = 2 bits. Times 4 = 8 bits. least significant = least recent used
// default order is  11 10 01 00  = 228
//uint8_t pageevictorder = 228;

#ifdef _M_I86

static uint16_t pageframebase;
static int16_t emshandle;

#else
#endif



uint32_t memsize;
byte*			pageFrameArea;
byte*			EMSArea;

// count allocations etc, can be used for benchmarking purposes.
static int32_t freeCount;
static int32_t plusAllocations = 0;
static int32_t minusAllocations = 0;
static int32_t totalAllocations = 0;

int32_t numreads = 0;
int32_t pageins = 0;
int32_t pageouts = 0;
int32_t actualpageins = 0;
int32_t actualpageouts = 0;

void Z_PageOutIfInMemory(uint32_t page_and_size);
 
void Z_ChangeTagEMSNew (MEMREF index, int16_t tag){


	// if tag is equal to PU_PURGELEVEL
	if ((allocations[index].offset_and_tag & 0xC000) == 0xC000  && !HAS_USER(allocations[index])) {
		I_Error("Z_ChangeTagEMSNew: an owner is required for purgable blocks %i %i %i %i %i", 
		allocations[index].offset_and_tag, 
		tag, 
		index, 
		allocations[index].backref_and_user,
		HAS_USER(allocations[index]));
	}

    SET_TAG(allocations[index], tag);
    

}

 
// EMS STUFF





//
// Z_InitEMS
//

 

void Z_InitEMS (void)
{ 
   
	int32_t size;
	int16_t i = 0;
	int32_t pageframeareasize = NUM_EMS_PAGES * PAGE_FRAME_SIZE;
    printf ("\nattempting z_initEMS\n");
	
	#ifdef _M_I86
	pageFrameArea = I_ZoneBaseEMS(&size, &emshandle);
	#else
	pageFrameArea = I_ZoneBaseEMS(&size);
	#endif
	memsize = size;

    EMSArea = ((byte*)pageFrameArea + pageframeareasize);


    printf ("EMS zone location  %p  \n", pageFrameArea );
    printf ("allocated size in z_initEMS was %i or %p\n", memsize, memsize);
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
    for (i = 2; i < EMS_ALLOCATION_LIST_SIZE; i++){
        allocations[i].prev = EMS_ALLOCATION_LIST_SIZE;
    }
    currentListHead = 1;
}


void Z_FreeEMSNew (PAGEREF block) {


    uint16_t         other;

	freeCount++;

	if (block == 0) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		I_Error("ERROR: Called Z_FreeEMSNew with 0! \n");
	}

	if (block >= EMS_ALLOCATION_LIST_SIZE) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		I_Error("ERROR: Called Z_FreeEMSNew with too big of size: max %i vs %i! \n", EMS_ALLOCATION_LIST_SIZE - 1, block);
	}
	
	// temp var use
	other = MAKE_BACKREF(allocations[block]); 
	if (other > 0)
	
	
	if (other > BACKREF_LUMP_OFFSET) {
		// in lumpcache
		W_EraseLumpCache(other - BACKREF_LUMP_OFFSET);
	} else { 
		// in compositeTextures
		R_EraseCompositeCache(other -1); // 0 means no backref..

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
(int16_t           tag )
{
	int16_t block;
	int16_t iter = 0;
	int16_t start = 0;

         
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


        // free block?
        if (!HAS_USER(allocations[block]))
            continue;
        
        if (MAKE_TAG(allocations[block]) == tag )
            Z_FreeEMSNew ( block);
    }

   
}

void Z_MarkPageLRU(uint16_t pagenumber) {


	int16_t i;
	int16_t j;

	

	if (pagenumber >= NUM_EMS_PAGES) {
		I_Error("Z_MarkPageLRU: page number too big %i %i", pageevictorder, pagenumber);
	}

	for (i = NUM_EMS_PAGES - 1; i >= 0; i--) {
		if (pagenumber == pageevictorder[i]) {
			break;
		}
	}

	if (i == -1) {
		//I_Error("%i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3] );
		I_Error("(LRU) Could not find page number in LRU cache: %i %i %i %i", pagenumber, numreads, pageins, pageouts);
	}

	// i now represents where the page was in the cache. move it to the back and everything else up.
	for (j = i; j > 0; j--) {
		pageevictorder[j] = pageevictorder[j - 1];
	}

	pageevictorder[0] = pagenumber;

}


//int16_t Z_RefIsActive2(MEMREF memref, int8_t* file, int32_t line) {
int16_t Z_RefIsActive2(MEMREF memref){
	int16_t pageframeindex;
	boolean allpagesgood;
	int16_t i;
	uint16_t numallocatepages = 1 + ((MAKE_SIZE(allocations[memref].page_and_size) - 1) >> PAGE_FRAME_BITS);
	if (numallocatepages > 100) {
		numallocatepages = 1;
	}

	if (memref > EMS_ALLOCATION_LIST_SIZE) {
		I_Error("Z_RefIsActive: alloc too big %i ", memref);
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

	I_Error("Z_RefIsActive: Found inactive ref! %i %s %i tick %i ", memref, gametic);

	return 0;
}

// marks page as most recently used
// error behavior if pagenumber not in the list?
//void Z_MarkPageMRU(uint16_t pagenumber, int8_t* file, int32_t line) {
void Z_MarkPageMRU(uint16_t pagenumber) {

	int16_t i;
	int16_t j;

	if (pagenumber >= NUM_EMS_PAGES) {
		I_Error("page number too big %i %i %i", pageevictorder, pagenumber);
	}

	for (i = NUM_EMS_PAGES-1 ; i >= 0; i--) {
		if (pagenumber == pageevictorder[i]) {
			break;
		}
	}

	if (i == -1) {
		//I_Error("%i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3] );
		I_Error("(MRU) Could not find page number in LRU cache: %i %i %i %i %s %i", pagenumber, numreads, pageins, pageouts);
	}

	

	// i now represents where the page was in the cache. move it to the back and everything else up.

	for (j = i; j < NUM_EMS_PAGES -1; j++) {
		pageevictorder[j] = pageevictorder[j + 1];
	}

	pageevictorder[NUM_EMS_PAGES - 1] = pagenumber;

}


void Z_DoPageOut(uint16_t pageframeindex) {
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
		activepages[pageframeindex+i] = -1;
		pagesize[pageframeindex + i] = -1;
		Z_MarkPageLRU(pageframeindex + i);

	}

}

void Z_DoPageIn(uint16_t logicalpage, uint16_t pageframeindex, uint16_t numallocatepages) {

	int16_t i = 0;
	byte* copydst = pageFrameArea + pageframeindex * PAGE_FRAME_SIZE;
	byte* copysrc = EMSArea + logicalpage * PAGE_FRAME_SIZE;

	memcpy(copydst, copysrc, PAGE_FRAME_SIZE * numallocatepages);
	
	// mark the page size. needed for dealocating all pages later
	pagesize[pageframeindex] = numallocatepages;

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

}


void Z_PageOutIfInMemory(uint32_t page_and_size) {
	uint16_t logicalpage = MAKE_PAGE(page_and_size);
	uint32_t size = MAKE_SIZE(page_and_size);
	uint16_t pageframeindex;
	uint16_t numallocatepages = 1 + ((size - 1) >> PAGE_FRAME_BITS);
	boolean allpagesgood;
	uint16_t i;


	//todo happens on size 0
	if (numallocatepages > 100) {
		numallocatepages = 1;
	}


	if (numallocatepages > 1) {
		for (i = 0; i < numallocatepages; i++) {
			for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
				if (activepages[pageframeindex] == logicalpage + i) {
					Z_DoPageOut(pageframeindex);

				}
			}
		}

	}
 
}

// gets a page index for this EMS page.
// forces a page swap if necessary.

// "page frame" is the upper memory EMS page frame
// logical page is where it corresponds to in the big block of otherwise inaccessible memory..

int16_t Z_GetEMSPageFrame(uint32_t page_and_size){  //todo allocations < 65k? if so size can be an uint16_t?
    uint16_t logicalpage = MAKE_PAGE(page_and_size);
	uint32_t size = MAKE_SIZE(page_and_size);
	uint16_t pageframeindex;

	uint16_t extradeallocatepages = 0;
	uint16_t numallocatepages;
	uint16_t i;
	boolean allpagesgood;
	numreads++;

	if (size == 0) {
		//I_Error("why a zero allocation!?");
	}



	// Note: if multiple pages, then we must evict multiple
	numallocatepages = 1 + ((size - 1) >> PAGE_FRAME_BITS);




	//todo happens on size 0
	if (numallocatepages > 100) {
		numallocatepages = 1;
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
				for (i = 0; i < numallocatepages; i++) {
					Z_MarkPageMRU(pageframeindex + i);
				}


				// linesref is page 2.. logical page 128

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
					Z_DoPageOut(pageframeindex);

				}
			}
		}

	}

    // decide on page to evict
	for (i = 0; i< NUM_EMS_PAGES ; i++) {
		
		// lets go down the LRU cache and find the next index
		pageframeindex = pageevictorder[i];

		// break loop if there is enough space to dealloate..  
		// TODO: could this be improved? average evict orders for multiple pages?
		if (numallocatepages + pageframeindex <= NUM_EMS_PAGES) {
			break;
		}

	}
	 
	// update active EMS pages
	for (i = 0; i < numallocatepages; i++) {
		if (activepages[pageframeindex + i] >= 0){
			Z_DoPageOut(pageframeindex+i);
		}  
	}


 


	// todo skip the copy if it was -1 ?

	// can do multiple pages in one go...
	// swap IN memory


	Z_DoPageIn(logicalpage, pageframeindex, numallocatepages);
	pageins++;
	
 
    return pageframeindex;
}

//void* Z_LoadBytesFromEMS2(MEMREF ref, int8_t* file, int32_t line) {
void* Z_LoadBytesFromEMS2(MEMREF ref) {
		byte* memorybase;
	uint16_t pageframeindex;
    byte* address;
	mobj_t* thing;
	line_t* lines;


 
 	if (ref > EMS_ALLOCATION_LIST_SIZE) {
		//I_Error("out of bounds memref.. tick %i    %i %s %i", gametic, ref, file, line);
		I_Error("out of bounds memref.. tick %i    %i %s %i", gametic, ref);
	}
	if (ref == 0) {
		I_Error("tried to load memref 0... tick %i    %i %s %i", gametic, ref);
//		I_Error("tried to load memref 0... tick %i    %i %s %i", gametic, ref, file, line);
	}

 

	pageframeindex = Z_GetEMSPageFrame(allocations[ref].page_and_size);
	memorybase = (byte*)pageFrameArea;
 
	address = memorybase
		+ PAGE_FRAME_SIZE * pageframeindex
		+ MAKE_OFFSET(allocations[ref]);

    return (byte *)address;
}

#ifdef MEMORYCHECK


int16_t getNumFreePages(){
	int16_t i = 0;
    int16_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE){
            total++;
        }

    }
    return total;
}

int32_t getFreeMemoryByteTotal(){
	int16_t i = 0;
	int32_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!HAS_USER(allocations[i])){

            total += allocations[i].size;
        }
    }
    return total;
}


int32_t getBiggestFreeBlock(){
	int16_t i = 0;
	int32_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!HAS_USER(allocations[i])){

            if (allocations[i].size > total)
                total = allocations[i].size ;
        }

    }
    return total;
}

int16_t getBiggestFreeBlockIndex(){
	int16_t i = 0;
	int32_t total = 0;
	int16_t totali = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!HAS_USER(allocations[i])){

            if (allocations[i].size > total){
                total = allocations[i].size ;
                totali = i;
            }
        }

    }
    return totali;
}

int16_t getNumPurgeableBlocks(){
	int16_t i = 0;
	int16_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].tag >= PU_PURGELEVEL && HAS_USER(allocations[i].user)){
            total ++;
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

PAGEREF Z_GetNextFreeArrayIndex(){
	PAGEREF start = currentListHead;
	PAGEREF i;
    
    for (i = currentListHead + 1; i != currentListHead; i++){
        if (i == EMS_ALLOCATION_LIST_SIZE){
            i = 0;
        }
        
        if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE){
            return i;
        }

    }


	I_Error("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ", -1, -1, -1);

    // error case

	#ifdef MEMORYCHECK

		I_Error ("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ",  getNumFreePages(), getFreeMemoryByteTotal(), getBiggestFreeBlock());
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
( uint32_t           size,
  uint8_t           tag,
  uint8_t user,
  uint8_t sourceHint,
  int16_t backRef)
{
    int16_t internalpagenumber;
    int16_t base;
    int16_t start;
    int16_t newfreeblockindex;
    
	int32_t         extra;
    int16_t rover;
	int16_t currentEMSHandle = 0;
	uint16_t offsetToNextPage = 0;
	int16_t iter = 0;
    
    int16_t iterator = 0;
    

	if (tag == 0){
		I_Error("tag cannot be 0!");
	}

    
// TODO : make use of sourceHint?
// ideally alllocations with the same sourceHint try to be in the same block if possible
// but even if they cannot be, the engine should not crash or anything

 

    if (size > MAX_ZMALLOC_SIZE){
		I_Error ("Z_MallocEMS: allocation too big! size was %i bytes %i %i %i", size, tag, user, sourceHint);
    }

    size = (size + 3) & ~3;



// algorithm:
	 
	 
    // scan through the block list,
    // looking for the first free block
    // of sufficient size,
    // throwing out any purgable blocks along the way.
	 
    base = currentListHead;

	

    if (!HAS_USER(allocations[allocations[base].prev])){
         base = allocations[base].prev;

    }


    rover = base;
    start = allocations[base].prev;

    offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t)allocations[base].offset_and_tag & 0x3FFF));
    if (offsetToNextPage == PAGE_FRAME_SIZE){
        offsetToNextPage = 0;
    }
	// 1 1 16384 0 1
	 // 1 1 102 0
/*	   I_Error("\nZ_MallocEMSNew: creating %i %i %i %i %i", 
		  allocations[newfreeblockindex].backref_and_user, 
		   allocations[base].backref_and_user,
		newfreeblockindex, base, backRef);
*/

 
	   
  do 
    {
         iter++;

		#ifdef LOOPCHECK

			if (iter > 2 * EMS_ALLOCATION_LIST_SIZE){
			   I_Error ("looping forever?");
			}
        #endif	
        
        if (rover == start) {
            // scanned all the way around the list
		   I_Error("Z_MallocEMSNew: failed on allocation of %u bytes tag %i iter %i and %i\n\n", size ,tag, iter, allocations[start].page_and_size);
        }

        // not empty but might be purgeable
        if(HAS_USER(allocations[rover])){
            // not purgeable, reset



// problem is base (1) has a user. user should be 0


			if (allocations[rover].offset_and_tag < 0xC000){  //  tag < PU_PURGELEVEL
                // hit a block that can't be purged,
                //  so move base past it
                base = rover = allocations[rover].next;


            // purgeable, so purge
            } else {  // tag is > PU_PURGELEVEL
                // free this block (connect the links, add size to base)
                   // printf ("freeing %p %i %i %i %i %i\n", allocations[base].user, base, allocations[base].size, size, plusAllocations, minusAllocations  );

                   // printf ("stats %i %i %i %i %i %i\n", base, allocations[base].prev, allocations[base].next, rover, allocations[rover].prev, allocations[rover].next);

                base = allocations[base].prev;
                Z_FreeEMSNew (rover);
                base = allocations[base].next;
                rover = allocations[base].next;
            }
            offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t) allocations[base].offset_and_tag & 0x3FFF))% PAGE_FRAME_SIZE;
            
        }
          else{
              // empty, add to current block..
                rover = allocations[rover].next;
          }
      
            
    } while (HAS_USER(allocations[base]) || MAKE_SIZE(allocations[base].page_and_size) < size 
       // problem: free block, and size is big enough but not aligned to page frame and we dont want to split page frame
       // so we must check that the block has enough free space when aligned to next page frame
        || (size + (   offsetToNextPage   ) > MAKE_SIZE(allocations[base].page_and_size))
    );



    // found a block big enough
    extra = MAKE_SIZE(allocations[base].page_and_size) - size;
	
    
    offsetToNextPage = (PAGE_FRAME_SIZE - (allocations[base].offset_and_tag & 0x3FFF));
    if (offsetToNextPage == PAGE_FRAME_SIZE){
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


    if (extra >  EMS_MINFRAGMENT)
    {


        // there will be a free fragment after the allocated block
        newfreeblockindex = Z_GetNextFreeArrayIndex();

        
		allocations[newfreeblockindex].prev = base;
        allocations[newfreeblockindex].next = allocations[base].next;
		allocations[allocations[newfreeblockindex].next].prev = newfreeblockindex;
        // implied tag NOT_IN_USE
		allocations[newfreeblockindex].offset_and_tag = (allocations[base].offset_and_tag + (size)) &0x3FFF ;
		// implies -1 backref and 0 user
		allocations[newfreeblockindex].backref_and_user = 0;
        

		
           

        allocations[newfreeblockindex].page_and_size = 
			(allocations[base].page_and_size & PAGE_MASK) +
			  (((MAKE_OFFSET(allocations[base]) + size ) >> PAGE_FRAME_BITS) << PAGE_AND_SIZE_SHIFT)
			+ (extra);
			  // divide by 16k


		
        allocations[base].next = newfreeblockindex;
        allocations[base].page_and_size = 
				(allocations[base].page_and_size & PAGE_MASK) +
				(size );



    }

    if (user) {
        // mark as an in use block
        allocations[base].backref_and_user |= USER_MASK;


    } else {

        if (tag >= PU_PURGELEVEL)
            I_Error ("Z_Malloc: an owner is required 4 purgable blocks");

        // mark as in use, but unowned  
        allocations[base].backref_and_user &= INVERSE_USER_MASK;

    }
	

		

    SET_TAG(allocations[base], tag);
	SET_BACKREF(allocations[base],  backRef);
 

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
int32_t GetBlockAddress(PAGEREF block){
    return MAKE_PAGE(allocations[block].page_and_size) * PAGE_FRAME_SIZE + allocations[block].offset;
}

void Z_CheckEMSAllocations(PAGEREF block){

    // all allocation entries should either be in the chain (linked list)
    // OR marked as a free index (prev = EMS_ALLOCATION_LIST_SIZE)
    
	int16_t unalloactedIndexCount = getNumFreePages();
    int16_t start = allocations[block].prev;
	int16_t iterCount = 1;
    while (start != block){

        iterCount++;
        if (iterCount > EMS_ALLOCATION_LIST_SIZE){
            I_Error("\nZ_CheckEMSAllocations: infinite loop detected with block start %i %i %i %i %i %i %i", start, iterCount, getNumFreePages(), getFreeMemoryByteTotal(), getNumPurgeableBlocks, getBiggestFreeBlock(), getBiggestFreeBlockIndex());
        }

        block = allocations[block].next;
    }

/*    printf("\n0:  %i %i %i", allocations[0].prev, allocations[0].next, allocations[0].size);
    printf("\n1:  %i %i %i", allocations[1].prev, allocations[1].next, allocations[1].size);
    printf("\n2:  %i %i %i", allocations[2].prev, allocations[2].next, allocations[2].size);
  */  

    if (unalloactedIndexCount + iterCount != EMS_ALLOCATION_LIST_SIZE){
        I_Error("\nZ_CheckEMSAllocations: %i unallocated indices, %i rover size, %i expected list size", unalloactedIndexCount, iterCount, EMS_ALLOCATION_LIST_SIZE);
    }



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
        
        if (GetBlockAddress(block) + allocations[block].size != GetBlockAddress(allocations[block].next) && GetBlockAddress(allocations[block].next) != 0){
            I_Error ("ERROR: block size does not touch the next block %i %i %i %i %i %i %i %i\n", GetBlockAddress(block), allocations[block].size, GetBlockAddress(allocations[block].next), block, start, allocations[block].next);
        }

        if (allocations[allocations[block].next].prev != block){
            I_Error("ERROR: next block doesn't have proper back link\n");
        }

        if (!allocations[block].user && !allocations[allocations[block].next].user){
            I_Error("ERROR: two consecutive free blocks\n");
        }
    }
}
#endif
    
