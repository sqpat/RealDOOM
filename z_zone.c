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


#define ZONEID  0x1d4a11
#define PAGE_FRAME_SIZE 0x4000
#define MINFRAGMENT             64
#define EMS_MINFRAGMENT         32
#define EMS_ALLOCATION_LIST_SIZE 4096
#define NUM_EMS_PAGES 32
// todo make this PAGE * PAGE SIZE 
#define MAX_ZMALLOC_SIZE 64 * 1024

// demo commented out...



// 16 MB worth
#define MAX_PAGE_FRAMES 1024

// 16k pages times 256 = 4MB 1200 allocations =   at least 5 per..

//#define PAGE_FRAME_SIZE 262144
//#define PAGE_FRAME_SIZE 4194304



typedef struct
{
    // total bytes malloced, including header
	int32_t         size;

    // start / end cap for linked list
    memblock_t  blocklist;
    
    memblock_t* rover;
    
} memzone_t;

// 20 bytes each. 40k total
// needs to be half... can tag be char?                                 - 3
// can size short, but max size = use an external int32_t for main size?    - 2
// is user needed or can it be char or something? is it doing anything special?



typedef struct
{
    PAGEREF prev;    //2    using 16 bits but need 11...
	PAGEREF next;    //4    using 16 bits but need 11...         these 3 could fit in 32 bits?
	
					 // page and offset refer to internal EMS page and offset - in other words the keys
	// to find the real location in memory for this allocation
	uint16_t page;    //6    using 16 bits but need 9 or 10...
    uint16_t offset;  //8    using 16 bits but needs 14...
	int32_t size;               //12   using, could probably drop to int16_t with the external int32_t for remaining main heap..

	uint8_t tag;      //13   could probably get away with fewer if we redid defines. maybe 4.
    uint8_t user;     //14

	int16_t backRef;		    //16   // an external index used to mark external caches as invalid so they know to re-generate a MEMREF. Used in compositeTextures and wad lumps
							// we're going to cheat. a 0 value is unused, positive is lump index plus 1, negative is (negative of composite texture index plus 1). 
} allocation_t;


int16_t currentListHead = 0; // main rover

allocation_t allocations[EMS_ALLOCATION_LIST_SIZE];


int16_t activepages[NUM_EMS_PAGES];
int8_t pageevictorder[NUM_EMS_PAGES];
int8_t pagesize[NUM_EMS_PAGES];


// 4 pages = 2 bits. Times 4 = 8 bits. least significant = least recent used
// default order is  11 10 01 00  = 228
//uint8_t pageevictorder = 228;




memzone_t*      mainzoneEMS;

byte*			copyPageArea;

static int32_t freeCount;
static int32_t plusAllocations = 0;
static int32_t minusAllocations = 0;
static int32_t totalAllocations = 0;

int32_t numreads = 0;
int32_t pageins = 0;
int32_t pageouts = 0;
int32_t actualpageins = 0;
int32_t actualpageouts = 0;

void Z_PageOutIfInMemory(uint16_t logicalpage, uint32_t size);
 
void Z_ChangeTagEMSNew (MEMREF index, int16_t tag){
     
	if (allocations[index].tag >= PU_PURGELEVEL && allocations[index].user < 0xFF) {
		I_Error("Z_ChangeTagEMSNew: an owner is required for purgable blocks %i %i %i %i", allocations[index].tag, tag, index, allocations[index].user);
	}

    allocations[index].tag = tag;
    
}

 
// EMS STUFF





//
// Z_InitEMS
//

 

void Z_InitEMS (void)
{ 
    // kinda hacked to coexist with mainzone for now

    // NOTE: sizeof memblock_t is 32

    //memblock_t* block;
    //memblock_t* prevblock;
    //memblock_t* currentPointer;
	int32_t size;
	int32_t itercount = 0;
	int32_t i = 0;
	int32_t copypageareasize = NUM_EMS_PAGES * PAGE_FRAME_SIZE;
    printf ("\nattempting z_initEMS\n");
	
	mainzoneEMS = (memzone_t *)I_ZoneBase(&size);
	copyPageArea = (byte*)mainzoneEMS;

    mainzoneEMS = (memzone_t *)((byte*)copyPageArea + copypageareasize);
    mainzoneEMS->size = size - copypageareasize;

    printf ("EMS zone location  %p  \n", mainzoneEMS );
    printf ("allocated size in z_initEMS was %i or %p\n", mainzoneEMS->size, size);
	//I_Error("");
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
    allocations[0].size = 0;
    allocations[0].user = 102;

    allocations[0].tag = PU_STATIC;

    allocations[1].next = 0;
    allocations[1].prev = 0;
    allocations[1].size = size;
    allocations[1].user = 0;
    allocations[1].tag = PU_STATIC;
	 
    // use this index to mark an unused block..
    for (i = 2; i < EMS_ALLOCATION_LIST_SIZE; i++){
        allocations[i].prev = EMS_ALLOCATION_LIST_SIZE;
    }
    currentListHead = 1;
}


void Z_FreeEMSNew (PAGEREF block) {


    int16_t         other;
	int16_t usedBackref;
	freeCount++;

	if (block == 0) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		printf("ERROR: Called Z_FreeEMSNew with 0! \n");
		I_Error("ERROR: Called Z_FreeEMSNew with 0! \n");
	}

	if (block >= EMS_ALLOCATION_LIST_SIZE) {
		// 0 is the head of the list, its a special-case size 0 block that shouldnt ever get allocated or deallocated.
		printf("ERROR: Called Z_FreeEMSNew with too big of size: max %i vs %i! \n", EMS_ALLOCATION_LIST_SIZE -1, block);
		I_Error("ERROR: Called Z_FreeEMSNew with too big of size: max %i vs %i! \n", EMS_ALLOCATION_LIST_SIZE - 1, block);
	}
	


	if (allocations[block].backRef > 0) {
		// in lumpcache
		W_EraseLumpCache(allocations[block].backRef -1);

	} else if (allocations[block].backRef < 0) {
		// in compositeTextures
		R_EraseCompositeCache(-1*(allocations[block].backRef + 1));

	}

	// if we dont page it out, this logical page can be re-allocated while the old one is already registered to a page frame.
	Z_PageOutIfInMemory(allocations[block].page, allocations[block].size);


    // mark as free
    allocations[block].user = 0; 
    allocations[block].tag = 0;
	allocations[block].backRef = 0;

    // at this point the block represents a free block of memory but you cant
    // make the allocation array index free, unless you join it with an adjacent
    // memory block.
    other = allocations[block].prev;

	

    // if two sequential blocks free, we can join them and free one spot in
    // the allocations array
    if (!allocations[other].user)
    {
        // extend other forward OVER block
        // merge with previous free block
        allocations[other].size += allocations[block].size;

        if (block == currentListHead)
            currentListHead = other;
        // link the blocks
        allocations[other].next = allocations[block].next;
        allocations[allocations[block].next].prev = other;

        // finally mark the array index unused.
        // this is where you have actually removed an array index
        allocations[block].prev = EMS_ALLOCATION_LIST_SIZE;
		allocations[block].backRef = 0;
        block = other;
    }
    
    other = allocations[block].next;
    // again, if two sequential blocks free, we can join them and free one spot in
    // the allocations array
    if (!allocations[other].user)
    {
        // extend block forward OVER other
        // merge the next free block onto the end
        allocations[block].size += allocations[other].size;

        if (other == currentListHead)
            currentListHead = block;

        // link the blocks
        allocations[block].next = allocations[other].next;
        allocations[allocations[other].next].prev = block;

        // finally mark the array index unused.
        // this is where you have actually removed an array index
        allocations[other].prev = EMS_ALLOCATION_LIST_SIZE;
        allocations[other].user = 0;
        allocations[other].tag = 0;
    }

	

	#ifdef MEMORYCHECK
		Z_CheckEMSAllocations(block);
	#endif

    
}


void
Z_FreeTagsEMS
(int32_t           lowtag,
	int32_t           hightag )
{
	int16_t block;
	int32_t iter = 0;
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

        iter++;

        if (iter == 100000){
           I_Error ("looping forever?");
        }

        // get link before freeing

        // free block?
        if (!allocations[block].user)
            continue;
        
        if (allocations[block].tag >= lowtag && allocations[block].tag <= hightag)
            Z_FreeEMSNew ( block);
    }

   
}

void Z_MarkPageLRU(uint16_t pagenumber) {


	int32_t i;
	int32_t j;

	

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


//int32_t Z_RefIsActive2(MEMREF memref, int8_t* file, int32_t line) {
int32_t Z_RefIsActive2(MEMREF memref){
	int32_t pageframeindex;
	boolean allpagesgood;
	int32_t i;
	uint16_t numallocatepages = 1 + ((allocations[memref].size - 1) >> 14);
	if (numallocatepages > 100) {
		numallocatepages = 1;
	}

	if (memref > EMS_ALLOCATION_LIST_SIZE) {
		I_Error("Z_RefIsActive: alloc too big %i ", memref);
	}

	for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
		if (activepages[pageframeindex] == allocations[memref].page) {
			//printf("\nEMS CACHE HIT on page %i size %i", page, size);
			allpagesgood = true;



			for (i = 1; i < numallocatepages; i++) {
				if (activepages[pageframeindex + i] != allocations[memref].page + i) {
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

	int32_t i;
	int32_t j;

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
	int32_t i = 0;
	int32_t numPagesToSwap = pagesize[pageframeindex];
	byte* copysrc = copyPageArea + (pageframeindex * PAGE_FRAME_SIZE);
	byte* copydst = (byte*)mainzoneEMS + (activepages[pageframeindex] * PAGE_FRAME_SIZE);




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

	int32_t i = 0;
	byte* copydst = copyPageArea + pageframeindex * PAGE_FRAME_SIZE;
	byte* copysrc = (byte*)mainzoneEMS + logicalpage * PAGE_FRAME_SIZE;

/*
	if (logicalpage == 128) {
		I_Error("checking values: %i %x %x %i %i", pageframeindex, copysrc, copydst, logicalpage, numallocatepages);
	}
	*/


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


void Z_PageOutIfInMemory(uint16_t logicalpage, uint32_t size) {
	uint16_t pageframeindex;
	uint16_t numallocatepages = 1 + ((size - 1) >> 14);
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

int16_t Z_GetEMSPageFrame(uint16_t logicalpage, uint32_t size){  //todo allocations < 65k? if so size can be an uint16_t?
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
	numallocatepages = 1 + ((size - 1) >> 14);




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


/*
			if (setval == 1) {
				// 4 5 132 when paging back
				// 1 0 128 when paging out lines
				I_Error("paging out %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", 
					activepages[0], activepages[1], activepages[2], activepages[3], activepages[4],
					activepages[5], activepages[6], activepages[7], activepages[8], activepages[9],
					activepages[10], activepages[11], activepages[12], activepages[13], activepages[14],
					activepages[5]
					);

				// !!! 128 125 128 <--- 125 eats up mid page...
				I_Error("paging out %i %i %i %i %i %i %s %i %i", numallocatepages, pageframeindex, activepages[pageframeindex + i], allocations[1363].page, allocations[1363].size, pagesize[0], file, line, ref);
			}*/

			Z_DoPageOut(pageframeindex+i);
		}  
	}


 


	// todo skip the copy if it was -1 ?

	// can do multiple pages in one go...
	// swap IN memory


	Z_DoPageIn(logicalpage, pageframeindex, numallocatepages);
	pageins++;
	
	//printf("\n new: %i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3]);
	//printf("\n new: %i %i %i %i", activepages[0], activepages[1], activepages[2], activepages[3]);

 

	/*
	if (pageframeindex == 1 && logicalpage == 125) {
		
		I_Error("check: %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i \n \n %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
			pagesize[0], pagesize[1], pagesize[2], pagesize[3], pagesize[4],
			pagesize[5], pagesize[6], pagesize[7], pagesize[8], pagesize[9],
			pagesize[10], pagesize[11], pagesize[12], pagesize[13], pagesize[14],
			pagesize[15],
		 
			activepages[0], activepages[1], activepages[2], activepages[3], activepages[4],
			activepages[5], activepages[6], activepages[7], activepages[8], activepages[9],
			activepages[10], activepages[11], activepages[12], activepages[13], activepages[14],
			activepages[15]
		);

	}
	*/
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

 

	pageframeindex = Z_GetEMSPageFrame(allocations[ref].page, allocations[ref].size);
	memorybase = (byte*)copyPageArea;
 
	address = memorybase
		+ PAGE_FRAME_SIZE * pageframeindex
		+ allocations[ref].offset;

    return (byte *)address;
}

#ifdef MEMORYCHECK


int16_t getNumFreePages(){
	int32_t i = 0;
    int16_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE){
            total++;
        }

    }
    return total;
}

int32_t getFreeMemoryByteTotal(){
	int32_t i = 0;
	int32_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].user){

            total += allocations[i].size;
        }
    }
    return total;
}


int32_t getBiggestFreeBlock(){
	int32_t i = 0;
	int32_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].user){

            if (allocations[i].size > total)
                total = allocations[i].size ;
        }

    }
    return total;
}

int32_t getBiggestFreeBlockIndex(){
	int32_t i = 0;
	int32_t total = 0;
	int32_t totali = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].user){

            if (allocations[i].size > total){
                total = allocations[i].size ;
                totali = i;
            }
        }

    }
    return totali;
}

int32_t getNumPurgeableBlocks(){
	int32_t i = 0;
	int32_t total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].tag >= PU_PURGELEVEL && allocations[i].user){
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
	int32_t start = currentListHead;
	int32_t i;
    
    for (i = currentListHead + 1; i != currentListHead; i++){
        if (i == EMS_ALLOCATION_LIST_SIZE){
            i = 0;
        }
        
        if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE){
            return i;
        }

    }


	printf("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ", -1, -1, -1);
	I_Error("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ", -1, -1, -1);

    // error case

	#ifdef MEMORYCHECK

		printf("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ", getNumFreePages(), getFreeMemoryByteTotal(), getBiggestFreeBlock());
		I_Error ("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ",  getNumFreePages(), getFreeMemoryByteTotal(), getBiggestFreeBlock());
	#endif

    return -1;
    
}

MEMREF Z_MallocEMSNew
(int32_t           size,
	uint8_t tag,
	uint8_t user,
	uint8_t sourceHint)
{
	return Z_MallocEMSNewWithBackRef(size, tag, user, sourceHint, -1);
}
MEMREF
Z_MallocEMSNewWithBackRef
(int32_t           size,
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
	int32_t currentEMSHandle = 0;
	int32_t offsetToNextPage = 0;
	int32_t extrasize = 0;
	int32_t iter = 0;

	int32_t varA = 0;
	int32_t varB = 0;

	
    
    int16_t iterator = 0;
    

    
// TODO : make use of sourceHint?
// ideally alllocations with the same sourceHint try to be in the same block if possible
// but even if they cannot be, the engine should not crash or anything

 

    if (size > MAX_ZMALLOC_SIZE){
		printf  ("Z_MallocEMS: allocation too big! size was %i bytes %i %i %i", size, tag, user, sourceHint);
		I_Error ("Z_MallocEMS: allocation too big! size was %i bytes %i %i %i", size, tag, user, sourceHint);
    }

    size = (size + 3) & ~3;



// algorithm:
	 
	 
    // scan through the block list,
    // looking for the first free block
    // of sufficient size,
    // throwing out any purgable blocks along the way.
	 
    base = currentListHead;

	

    if (!allocations[allocations[base].prev].user){
         base = allocations[base].prev;
    }

    rover = base;
    start = allocations[base].prev;

    offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t)allocations[base].offset & 0x3FFF));
    if (offsetToNextPage == PAGE_FRAME_SIZE){
        offsetToNextPage = 0;
    }
	 

  do 
    {
         iter++;

		#ifdef LOOPCHECK

			if (iter > 2 * EMS_ALLOCATION_LIST_SIZE){
				printf("looping forever?");
			   I_Error ("looping forever?");
			}
        #endif	
        
        if (rover == start) {
            // scanned all the way around the list
           printf("Z_MallocEMSNew: failed on allocation of %i bytes", size);
		   I_Error("Z_MallocEMSNew: failed on allocation of %i bytes", size);
        }

        // not empty but might be purgeable
        if(allocations[rover].user){
            // not purgeable, reset
            if (allocations[rover].tag < PU_PURGELEVEL){
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
            offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t) allocations[base].offset & 0x3FFF))% PAGE_FRAME_SIZE;
            
        }
          else{
              // empty, add to current block..
                rover = allocations[rover].next;
          }
      
            
    } while (allocations[base].user || allocations[base].size < size 
       // problem: free block, and size is big enough but not aligned to page frame and we dont want to split page frame
       // so we must check that the block has enough free space when aligned to next page frame
        || (size + (   offsetToNextPage   ) > allocations[base].size)
    );




    // found a block big enough
    extra = allocations[base].size - size;

    
    offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t)allocations[base].offset & 0x3FFF));
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

        allocations[newfreeblockindex].size = offsetToNextPage;
        allocations[newfreeblockindex].user = 0;
        allocations[newfreeblockindex].tag = 0;
        allocations[newfreeblockindex].page = allocations[base].page;
        allocations[newfreeblockindex].offset = allocations[base].offset;
		allocations[newfreeblockindex].backRef = -1;

        allocations[base].size = allocations[base].size - offsetToNextPage;


		// todo are we okay with respect to not wrapping around? should never happen because initial size should be set in a way this doesnt happen?
        allocations[base].page = allocations[base].page + 1;
        allocations[base].offset = 0;
        
        extra = extra - offsetToNextPage;

  
           
    }            



// todo: around here we would do  page allocation esp around multi page allocations..

    

// after this call, newfragment -> next is mainblock
// base-> next is newfragment
// base-> prev is the last newfragment in the last call



    
    offsetToNextPage = (PAGE_FRAME_SIZE - ((uint32_t)(allocations[base].offset) & 0x3FFF));
// In this case, PAGE FRAME SIZE is ok/expected.


    if (extra >  EMS_MINFRAGMENT)
    {


        // there will be a free fragment after the allocated block
        newfreeblockindex = Z_GetNextFreeArrayIndex();
        allocations[newfreeblockindex].size = extra-extrasize;
        allocations[newfreeblockindex].user = 0;
        allocations[newfreeblockindex].prev = base;
        allocations[newfreeblockindex].next = allocations[base].next;
		allocations[newfreeblockindex].backRef = -1;
		allocations[allocations[newfreeblockindex].next].prev = newfreeblockindex;

        allocations[newfreeblockindex].offset = (allocations[base].offset + (size + extrasize)) &0x3FFF ;
        //printf ("page before  %i %i %i\n", allocations[newfreeblockindex].page, size + extrasize, (size + extrasize) >> 14);

        allocations[newfreeblockindex].page = allocations[base].page + ((allocations[base].offset + size + extrasize) >> 14);  // divide by 16k
        //printf ("page after %i %i\n", allocations[newfreeblockindex].page, allocations[base].page);
        
        allocations[base].next = newfreeblockindex;
        allocations[base].size = size + extrasize;
		 
    }

    if (user) {
        // mark as an in use block
        allocations[base].user = 0xFF;
    } else {

        if (tag >= PU_PURGELEVEL)
            I_Error ("Z_Malloc: an owner is required 4 purgable blocks");

        // mark as in use, but unowned  
        allocations[base].user = 2;         
    }
    allocations[base].tag = tag;
	allocations[base].backRef = backRef;

    // next allocation will start looking here
    //mainzoneEMS->rover = base->next;
    // TODO   use rover.next or currentlisthead?
    currentListHead = allocations[base].next;

 

    //printf ("z_malloc returning size %i at offset %i \n", size, base + sizeof(memblock_t));

    

    // todo activate page
	#ifdef MEMORYCHECK
		Z_CheckEMSAllocations(base, 0, 0, 0);
	#endif

//    if (allocations[currentListHead].page > 250){
//        I_Error("C: Last pages? %i %i %i %i %i %i", varA, varB, getNumFreePages(), getFreeMemoryByteTotal(), currentListHead, allocations[currentListHead].page);
//    }


	return base;
    //return (void *) ((byte *)mainzoneEMS + ( allocations[base].page * PAGE_FRAME_SIZE + allocations[base].offset ) );

}

int32_t GetBlockAddress(PAGEREF block){
    return allocations[block].page * PAGE_FRAME_SIZE + allocations[block].offset;
}
#ifdef MEMORYCHECK

void Z_CheckEMSAllocations(PAGEREF block){

    // all allocation entries should either be in the chain (linked list)
    // OR marked as a free index (prev = EMS_ALLOCATION_LIST_SIZE)
    
	int32_t unalloactedIndexCount = getNumFreePages();
    int16_t start = allocations[block].prev;
	int32_t iterCount = 1;
    while (start != block){

        iterCount++;
        if (iterCount > EMS_ALLOCATION_LIST_SIZE){
            printf("\nZ_CheckEMSAllocations: infinite loop detected with block start %i %i %i %i %i %i %i", start, iterCount, getNumFreePages(), getFreeMemoryByteTotal(), getNumPurgeableBlocks, getBiggestFreeBlock(), getBiggestFreeBlockIndex());
            I_Error("\nZ_CheckEMSAllocations: infinite loop detected with block start %i %i %i %i %i %i %i", start, iterCount, getNumFreePages(), getFreeMemoryByteTotal(), getNumPurgeableBlocks, getBiggestFreeBlock(), getBiggestFreeBlockIndex());
        }

        block = allocations[block].next;
    }

/*    printf("\n0:  %i %i %i", allocations[0].prev, allocations[0].next, allocations[0].size);
    printf("\n1:  %i %i %i", allocations[1].prev, allocations[1].next, allocations[1].size);
    printf("\n2:  %i %i %i", allocations[2].prev, allocations[2].next, allocations[2].size);
  */  

    if (unalloactedIndexCount + iterCount != EMS_ALLOCATION_LIST_SIZE){
        printf("\nZ_CheckEMSAllocations: %i unallocated indices, %i rover size, %i expected list size", unalloactedIndexCount, iterCount, EMS_ALLOCATION_LIST_SIZE);
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
            printf ("ERROR: block size does not touch the next block %i %i %i %i %i %i %i %i\n", GetBlockAddress(block), allocations[block].size, GetBlockAddress(allocations[block].next), block, start, allocations[block].next);
            I_Error ("ERROR: block size does not touch the next block %i %i %i %i %i %i %i %i\n", GetBlockAddress(block), allocations[block].size, GetBlockAddress(allocations[block].next), block, start, allocations[block].next);
        }

        if (allocations[allocations[block].next].prev != block){
            printf ("ERROR: next block doesn't have proper back link\n");
            I_Error("ERROR: next block doesn't have proper back link\n");
        }

        if (!allocations[block].user && !allocations[allocations[block].next].user){
            printf ("ERROR: two consecutive free blocks\n");
            I_Error("ERROR: two consecutive free blocks\n");
        }
    }
}
#endif
    
