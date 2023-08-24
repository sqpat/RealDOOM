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


#define ZONEID  0x1d4a11
#define MAX_ZMALLOC_SIZE 64 * 1024
#define PAGE_FRAME_SIZE 0x4000
#define MINFRAGMENT             64
#define EMS_MINFRAGMENT         32
#define EMS_ALLOCATION_LIST_SIZE 4096
#define NUM_EMS_PAGES 32
// 16 is 384 139914 14 21
// 16 MB worth
#define MAX_PAGE_FRAMES 1024

// 16k pages times 256 = 4MB 1200 allocations =   at least 5 per..

//#define PAGE_FRAME_SIZE 262144
//#define PAGE_FRAME_SIZE 4194304

typedef struct
{
    // total bytes malloced, including header
    int         size;

    // start / end cap for linked list
    memblock_t  blocklist;
    
    memblock_t* rover;
    
} memzone_t;

// 20 bytes each. 40k total
// needs to be half... can tag be char?                                 - 3
// can size short, but max size = use an external int for main size?    - 2
// is user needed or can it be char or something? is it doing anything special?



typedef struct
{
    PAGEREF prev;    //2    using 16 bits but need 11...
	PAGEREF next;    //4    using 16 bits but need 11...         these 3 could fit in 32 bits?
	
					 // page and offset refer to internal EMS page and offset - in other words the keys
	// to find the real location in memory for this allocation
	unsigned short page;    //6    using 16 bits but need 9 or 10...
    unsigned short offset;  //8    using 16 bits but needs 14...
    int size;               //12   using, could probably drop to short with the external int for remaining main heap..

	unsigned char tag;      //13   could probably get away with fewer if we redid defines. maybe 4.
    unsigned char user;     //14

	short backRef;		    //16   // an external index used to mark external caches as invalid so they know to re-generate a MEMREF. Used in compositeTextures and wad lumps
							// we're going to cheat. a 0 value is unused, positive is lump index plus 1, negative is (negative of composite texture index plus 1). 
} allocation_t;


short currentListHead = 0; // main rover

allocation_t allocations[EMS_ALLOCATION_LIST_SIZE];


short activepages[NUM_EMS_PAGES];
char pageevictorder[NUM_EMS_PAGES];

// 4 pages = 2 bits. Times 4 = 8 bits. least significant = least recent used
// default order is  11 10 01 00  = 228
//unsigned char pageevictorder = 228;




memzone_t*      mainzoneEMS;
memzone_t*      mainzone;

byte*			copyPageArea;

static int freeCount;
static int plusAllocations = 0;
static int minusAllocations = 0;
static int totalAllocations = 0;

int numreads = 0;
int pageins = 0;
int pageouts = 0;

//
// Z_ClearZone
//
void Z_ClearZone (memzone_t* zone)
{
    memblock_t*         block;
        
    // set the entire zone to one free block
    zone->blocklist.next =
        zone->blocklist.prev	=
        block = (memblock_t *)( (byte *)zone + sizeof(memzone_t) );
    
    zone->blocklist.user = (void *)zone;
    zone->blocklist.tag = PU_STATIC;
    zone->rover = block;
        
    block->prev = block->next = &zone->blocklist;
    
    // NULL indicates a free block.
    block->user = NULL; 

    block->size = zone->size - sizeof(memzone_t);
}



//
// Z_Init
//
void Z_Init (void)
{
    int         size;
    memblock_t* block;


    printf ("\nattempting z_init\n ");

 
    mainzone = (memzone_t *)I_ZoneBase (&size);
    printf ("zone location  %p vs EMS  %p %p %p\n", mainzone, mainzoneEMS, size, mainzone->size );
    mainzone->size = size/2;

	copyPageArea = (byte*)mainzone + mainzone->size;

    printf ("zone location  %p vs EMS  %p %p %p\n", mainzone, mainzoneEMS, size, mainzone->size );
    printf ("allocated size in z_init was %i or %p\n", mainzone->size, mainzone->size);

    // set the entire zone to one free block
    mainzone->blocklist.next =
        mainzone->blocklist.prev =
        block = (memblock_t *)( (byte *)mainzone + sizeof(memzone_t) );

    mainzone->blocklist.user = (void *)mainzone;
    mainzone->blocklist.tag = PU_STATIC;
    mainzone->rover = block;
        
    block->prev = block->next = &mainzone->blocklist;

    // NULL indicates a free block.
    block->user = NULL;
    
    block->size = mainzone->size - sizeof(memzone_t);


}


//
// Z_Free
//
void Z_Free (void* ptr)
{
    memblock_t*         block;
    memblock_t*         other;
    minusAllocations++;
    totalAllocations++;
        
    block = (memblock_t *) ( (byte *)ptr - sizeof(memblock_t));

    if (block->id != ZONEID)
        I_Error ("Z_Free: freed a pointer without ZONEID");
                
    if (block->user > (void **)0x100)
    {
        // smaller values are not pointers
        // Note: OS-dependend?
        
        // clear the user's mark
        *block->user = 0;
    }

    // mark as free
    block->user = NULL; 
    block->tag = 0;
    block->id = 0;
        
    other = block->prev;

    if (!other->user)
    {
        // merge with previous free block
        other->size += block->size;
        other->next = block->next;
        other->next->prev = other;

        if (block == mainzone->rover)
            mainzone->rover = other;

        block = other;
    }
        
    other = block->next;
    if (!other->user)
    {
        // merge the next free block onto the end
        block->size += other->size;
        block->next = other->next;
        block->next->prev = block;

        if (other == mainzone->rover)
            mainzone->rover = block;
    }

   
}



//
// Z_Malloc
// You can pass a NULL user if the tag is < PU_PURGELEVEL.
//


void*
Z_Malloc
( int           size,
  int           tag,
  void*         user )
{


    int         extra;
    memblock_t* start;
    memblock_t* rover;
    memblock_t* newblock;
    memblock_t* base;


    unsigned char userbyte;


    int freememory = 0;
    plusAllocations++;
    totalAllocations++;

    
//    printf ("RESULT: %p\n", Z_MallocEMSNew(size, tag, user, 0));

    if ((unsigned)user > 0x100){
        userbyte = 0xff;
    } else {
        userbyte = (unsigned)user &0xff;
    }
    //Z_MallocEMSNew(size, tag, userbyte, 0);

/*
    if (totalAllocations > 9000){
        freememory = Z_FreeMemory();
        printf ("\nZ_Malloc free mem %i %p plus %i minus %i ", freememory, freememory, plusAllocations, minusAllocations);
        /// 1048544 by default
        // 976948   893 108  // LOAD GAME
        // 745980  1259 242  //LOAD GAME
        // 740880  1490 511  // STAGE 1 LOAD
        // 720304  1736 766  //STAGE 1
        // 776188  1919 1100 //STAGE 1 END/2
        // 590204  2501 1500 //STAGE 2
        

        // DEMO PLAY
        // 647380 2882 2130  // LOAD 2ND DEMO
        // 582756 3554 2448  // MID 2ND DEMO
        // 861544 4394 3609
        // 616016 5028 3973

        I_Error ("\nZ_Malloc free mem %i %p plus %i minus %i ", freememory, freememory, plusAllocations, minusAllocations);
    }
*/
    
    size = (size + 3) & ~3;

    // scan through the block list,
    // looking for the first free block
    // of sufficient size,
    // throwing out any purgable blocks along the way.

    // account for size of block header
    size += sizeof(memblock_t);
    
    // if there is a free block behind the rover,
    //  back up over them
    base = mainzone->rover;
    
    if (!base->prev->user)
        base = base->prev;
        
    rover = base;
    start = base->prev;

    if (size > MAX_ZMALLOC_SIZE) {
        printf ("Z_Malloc: allocation too big! size was %i bytes ", size);
        I_Error ("Z_Malloc: allocation too big! size was %i bytes ", size);
    }

        
    do 
    {
        if (rover == start) {
            // scanned all the way around the list
            I_Error ("Z_Malloc: failed on allocation of %i bytes", size);
        }
        
        if (rover->user) {
           
            if (rover->tag < PU_PURGELEVEL)
            {
                // hit a block that can't be purged,
                //  so move base past it
                base = rover = rover->next;
            }
            else
            {
                // free the rover block (adding the size to base)

                // the rover can be the base block
                base = base->prev;
                Z_Free ((byte *)rover+sizeof(memblock_t));
                base = base->next;
                rover = base->next;
            }
        }
        else
            rover = rover->next;

            
    } while (base->user || base->size < size);

    
    // found a block big enough
    extra = base->size - size;
    
    if (extra >  MINFRAGMENT)
    {
        // there will be a free fragment after the allocated block
        newblock = (memblock_t *) ((byte *)base + size );
        newblock->size = extra;
        
        // NULL indicates free block.
        newblock->user = NULL;  
        newblock->tag = 0;
        newblock->prev = base;
        newblock->next = base->next;
        newblock->next->prev = newblock;

        base->next = newblock;
        base->size = size;
    }
        
    if (user)
    {
        // mark as an in use block
        base->user = user;                      
        *(void **)user = (void *) ((byte *)base + sizeof(memblock_t));
    }
    else
    {
        if (tag >= PU_PURGELEVEL)
            I_Error ("Z_Malloc: an owner is required for purgable blocks");

        // mark as in use, but unowned  
        base->user = (void *)2;         
    }
    base->tag = tag;

    // next allocation will start looking here
    mainzone->rover = base->next;       
        
    base->id = ZONEID;

    return (void *) ((byte *)base + sizeof(memblock_t));
 
}



//
// Z_FreeTags
//
void
Z_FreeTags
( int           lowtag,
  int           hightag )
{

    
    memblock_t* block;
    memblock_t* next;
        
    for (block = mainzone->blocklist.next ;
         block != &mainzone->blocklist ;
         block = next)
    {
        // get link before freeing
        next = block->next;

        // free block?
        if (!block->user)
            continue;
        
        if (block->tag >= lowtag && block->tag <= hightag)
            Z_Free ( (byte *)block+sizeof(memblock_t));
    }


}



//
// Z_DumpHeap
// Note: TFileDumpHeap( stdout ) ?
//
void
Z_DumpHeap
( int           lowtag,
  int           hightag )
{
    memblock_t* block;
        
    printf ("zone size: %i  location: %p\n",
            mainzoneEMS->size,mainzone);
    
    printf ("tag range: %i to %i\n",
            lowtag, hightag);
        
    for (block = mainzoneEMS->blocklist.next ; ; block = block->next)
    {
        if (block->tag >= lowtag && block->tag <= hightag)
            printf ("block:%p    size:%7i    user:%p    tag:%3i\n",
                    block, block->size, block->user, block->tag);
                
        if (block->next == &mainzoneEMS->blocklist)
        {
            // all blocks have been hit
            break;
        }
        
        if ( (byte *)block + block->size != (byte *)block->next)
            printf ("ERROR: block size does not touch the next block\n");

        if ( block->next->prev != block)
            printf ("ERROR: next block doesn't have proper back link\n");

        if (!block->user && !block->next->user)
            printf ("ERROR: two consecutive free blocks\n");
    }
}


//
// Z_FileDumpHeap
//
void Z_FileDumpHeap (FILE* f)
{
    memblock_t* block;
        
    fprintf (f,"zone size: %i  location: %p\n",mainzoneEMS->size,mainzone);
        
    for (block = mainzoneEMS->blocklist.next ; ; block = block->next)
    {
        fprintf (f,"block:%p    size:%7i    user:%p    tag:%3i\n",
                 block, block->size, block->user, block->tag);
                
        if (block->next == &mainzoneEMS->blocklist)
        {
            // all blocks have been hit
            break;
        }
        
        if ( (byte *)block + block->size != (byte *)block->next)
            fprintf (f,"ERROR: block size does not touch the next block\n");

        if ( block->next->prev != block)
            fprintf (f,"ERROR: next block doesn't have proper back link\n");

        if (!block->user && !block->next->user)
            fprintf (f,"ERROR: two consecutive free blocks\n");
    }
}



//
// Z_CheckHeap
//
void Z_CheckHeap (void)
{
    memblock_t* block;
    int iter = 0;  

    for (block = mainzone->blocklist.next ; ; block = block->next)
    {

        iter++;

        if (iter == 100000){
           I_Error ("looping forever?");
        }


        if (block->next == &mainzone->blocklist)
        {
            // all blocks have been hit
            break;
        }
        
        if ( (byte *)block + block->size != (byte *)block->next)
            I_Error ("Z_CheckHeap: block size does not touch the next block %p %p %p\n", block, block->size, block->next);
        

        if ( block->next->prev != block)
            I_Error ("Z_CheckHeap: next block doesn't have proper back link %i %i %p %p %p %p %p %p %p\n", iter, freeCount, block, block->next, block->prev, &mainzone->blocklist,
        mainzone->blocklist.prev, mainzone->blocklist.next,  block->next->prev
            );

        if (!block->user && !block->next->user)
            I_Error ("Z_CheckHeap: two consecutive free blocks\n");
    }
}



//
// Z_ChangeTag
//
void
Z_ChangeTag2
( void*         ptr,
  int           tag )
{
    memblock_t* block;
        
    block = (memblock_t *) ( (byte *)ptr - sizeof(memblock_t));

    if (block->id != ZONEID)
        I_Error ("Z_ChangeTag: freed a pointer without ZONEID");

    if (tag >= PU_PURGELEVEL && (unsigned)block->user < 0x100)
        I_Error ("Z_ChangeTag: an owner is required for purgable blocks");

    block->tag = tag;

    
}

void Z_ChangeTagEMSNew (MEMREF index, short tag){
     
	if (allocations[index].tag >= PU_PURGELEVEL && allocations[index].user < 0xFF) {
		I_Error("Z_ChangeTagEMSNew: an owner is required for purgable blocks %i %i %i %i", allocations[index].tag, tag, index, allocations[index].user);
	}

    allocations[index].tag = tag;
    
}

void Z_PrintAllocationInfo(MEMREF index) {
	I_Error("Info: %i %i %i %i %i %i", index, allocations[index].tag, allocations[index].prev, allocations[index].size, allocations[index].page, allocations[index].offset, allocations[index].user);
}




//
// Z_FreeMemory
//
int Z_FreeMemory (void)
{
    memblock_t*         block;
    int                 free;
        
    free = 0;
    
    for (block = mainzone->blocklist.next ;
         block != &mainzone->blocklist;
         block = block->next)
    {
        if (!block->user || block->tag >= PU_PURGELEVEL)
            free += block->size;
    }
    return free;
}
 
// EMS STUFF





//
// Z_InitEMS
//


memblock_t* initInnerBlock(memblock_t* pointer, memblock_t* prevblock){
    memblock_t* block;
    memblock_t* currentPointer;

        block = (memblock_t *)( (byte *)pointer);

    block->prev = prevblock;
    block->user = NULL;
    block->size = PAGE_FRAME_SIZE;

    return block;
}

void Z_InitEMS (void)
{
/*

    memblock_t* block;
    int         size;

    mainzoneEMS = (memzone_t *)I_ZoneBaseEMS (&size);
    mainzoneEMS->size = size;

    // set the entire zone to one free block
    mainzoneEMS->blocklist.next =
        mainzoneEMS->blocklist.prev =
        block = (memblock_t *)( (byte *)mainzoneEMS + sizeof(memzone_t) );

    mainzoneEMS->blocklist.user = (void *)mainzoneEMS;
    mainzoneEMS->blocklist.tag = PU_STATIC;
    mainzoneEMS->rover = block;
        
    block->prev = block->next = &mainzoneEMS->blocklist;

    // NULL indicates a free block.
    block->user = NULL;
    
    block->size = mainzoneEMS->size - sizeof(memzone_t);

*/
    
    // kinda hacked to coexist with mainzone for now

    // NOTE: sizeof memblock_t is 32

    //memblock_t* block;
    //memblock_t* prevblock;
    //memblock_t* currentPointer;
    int size = mainzone->size - (NUM_EMS_PAGES * PAGE_FRAME_SIZE);
    int itercount = 0;
    int i = 0;

    printf ("\nattempting z_initEMS\n");
    printf ("EMS zone location  %p vs zone %p \n", mainzoneEMS, mainzone);

    mainzoneEMS = (memzone_t *)((byte*)copyPageArea + NUM_EMS_PAGES * PAGE_FRAME_SIZE);
    //mainzoneEMS->size = size;

    printf ("EMS zone location  %p vs zone %p \n", mainzoneEMS, mainzone);
    printf ("allocated size in z_initEMS was %i or %p\n", mainzoneEMS->size, size);

	// mark ems pages unused
	for (i = 0; i < NUM_EMS_PAGES; i++) {
		activepages[i] = -1;
		pageevictorder[i] = i;
		printf("\nallocated %i %i", activepages[i], pageevictorder[i]);
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

//    printf ("\ntopcheck %p %p\n", allocations[1].user, allocations[1].size);

    // use this index to mark an unused block..
    for (i = 2; i < EMS_ALLOCATION_LIST_SIZE; i++){
        allocations[i].prev = EMS_ALLOCATION_LIST_SIZE;
    }
    
 
    currentListHead = 1;
}




void Z_FreeEMSNew (short block, int error)
{


    short         other;
	short usedBackref;
	int val = 0;
	int val2 = 0;
	int val3 = 0;
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
		val += 1;
		val2 = block;
		val3 = other;
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
		val += 2;
    }

	val3 = error;
	Z_CheckEMSAllocations(block, val, val2, val3);

    
}


void
Z_FreeTagsEMS
( int           lowtag,
  int           hightag )
{
	short block;
    int iter = 0;
	short start = 0;

         
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
            Z_FreeEMSNew ( block, 8);
    }

   
}

// marks page as most recently used
// error behavior if pagenumber not in the list?
void Z_MarkPageMRU(char pagenumber) {

	//int neworder = 0;
	//int bitpattern = 3;
	int i;
	int j;

	if (pagenumber >= NUM_EMS_PAGES) {
		I_Error("page number too big %i %i", pageevictorder, pagenumber);
	}

	for (i = NUM_EMS_PAGES-1 ; i >= 0; i--) {
		if (pagenumber == pageevictorder[i]) {
			break;
		}
	}

	if (i == -1) {
		I_Error("%i %i %i %i",

			pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3]
		);
		//I_Error("Could not find page number in LRU cache: %i %i %i %i", pagenumber, numreads, pageins, pageouts);
	}

	

	// i now represents where the page was in the cache. move it to the back and everything else up.

	for (j = i; j < NUM_EMS_PAGES -1; j++) {
		pageevictorder[j] = pageevictorder[j + 1];
	}

	pageevictorder[NUM_EMS_PAGES - 1] = pagenumber;

}


// gets a page index for this EMS page.
// forces a page swap if necessary.

// "page frame" is the upper memory EMS page frame
// logical page is where it corresponds to in the big block of otherwise inaccessible memory..

short Z_GetEMSPageFrame(short logicalpage, unsigned int size){  //todo allocations < 65k? if so size can be an unsigned short?
    char pageframeindex;
	byte* copysrc;
	byte* copydst;

	int numallocatepages;
	int i;
	int oldpage;

	numreads++;

	// if its already active? then

	for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++){
        if (activepages[pageframeindex] == logicalpage){
			//printf("\nEMS CACHE HIT on page %i size %i", page, size);

			Z_MarkPageMRU(pageframeindex);
			return pageframeindex;
        }
    }


    // page not active
    // decide on page to evict


	// Note: if multiple pages, then we must evict multiple
	numallocatepages = 1 + (size >> 14);
	// numallocatepages = 1 + size / PAGE_FRAME_SIZE;


	for (i = 0; i< NUM_EMS_PAGES ; i++) {
		
		// lets go down the LRU cache and find the next index
		pageframeindex = pageevictorder[i];

		// break loop if there is enough space to dealloate..
		if (numallocatepages + pageframeindex <= NUM_EMS_PAGES) {
			break;
		}

	}
	
	//printf("\nEMS CACHE MISS on page %i size %i numallocatepages %i", logicalpage, size, numallocatepages);
	//printf("\n old: %i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3]);
	//printf("\n old: %i %i %i %i", activepages[0], activepages[1], activepages[2], activepages[3]);
	// update active EMS pages
	for (i = 0; i < numallocatepages; i++) {
		pageouts++;
		if (activepages[pageframeindex + i] >= 0){

			// swap OUT memory
			copysrc = copyPageArea + (pageframeindex + i) * PAGE_FRAME_SIZE;
			copydst = (byte*)mainzoneEMS + activepages[pageframeindex + i] * PAGE_FRAME_SIZE;
			//printf("\nPAGING OUT! page %i, from %p to %p", pageframeindex + i, copysrc, copydst);
			memcpy(copydst, copysrc, PAGE_FRAME_SIZE);
		}

		activepages[pageframeindex + i] = logicalpage + i;

		if (pageframeindex + i == NUM_EMS_PAGES) {
			I_Error("too big %i %i", numallocatepages, size);
		}
		Z_MarkPageMRU(pageframeindex + i);
	}


	// can do multiple pages in one go...
	// swap IN memory
	copydst = copyPageArea + pageframeindex * PAGE_FRAME_SIZE;
	copysrc = (byte*)mainzoneEMS + logicalpage * PAGE_FRAME_SIZE;
	//printf("\nPAGING in! page %i, from %p to %p", pageframeindex, copysrc, copydst);
	memcpy(copydst, copysrc, PAGE_FRAME_SIZE * numallocatepages);

	pageins++;

	//printf("\n new: %i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3]);
	//printf("\n new: %i %i %i %i", activepages[0], activepages[1], activepages[2], activepages[3]);


    return pageframeindex;
}


void* Z_LoadBytesFromEMS2(MEMREF ref, char* file, int line) {
    byte* memorybase;
	short pageframeindex;
    byte* address;


	//todo which was correct again?

//	if (ref > MAX_PAGE_FRAMES) {
	if (ref > EMS_ALLOCATION_LIST_SIZE) {

		I_Error("out of bounds memref.. %i %s %i", ref, file, line);
	}


	/*
	// NON EMS VERSION
	pagenumber = index;
    memorybase = (byte*)mainzoneEMS;
    
    address = memorybase
        + PAGE_FRAME_SIZE * allocations[pagenumber].page
        + allocations[pagenumber].offset;
		*/

	//EMS VERSION

	pageframeindex = Z_GetEMSPageFrame(allocations[ref].page, allocations[ref].size);
	memorybase = (byte*)copyPageArea;

	address = memorybase
		+ PAGE_FRAME_SIZE * pageframeindex
		+ allocations[ref].offset;




    
	//printf("returned address %p page number %i", address, pageframeindex);

    return (byte *)address;
    
}

 


short getNumFreePages(){
    int i = 0;
    short total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE){
            total++;
        }

    }
    return total;
}

int getFreeMemoryByteTotal(){
    int i = 0;
    int total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].user){

            total += allocations[i].size;
        }

    }
    return total;
}


int getBiggestFreeBlock(){
    int i = 0;
    int total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].user){

            if (allocations[i].size > total)
                total = allocations[i].size ;
        }

    }
    return total;
}

int getBiggestFreeBlockIndex(){
    int i = 0;
    int total = 0;
    int totali = 0;
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

int getNumPurgeableBlocks(){
   int i = 0;
    int total = 0;
    for (i = 0; i < EMS_ALLOCATION_LIST_SIZE; i++){
        if (!allocations[i].tag >= PU_PURGELEVEL && allocations[i].user){
            total ++;
        }

    }
    return total;
}


// Gets the next unused spot in the doubly linked list of allocations
// NOTE: this does not mean it gets the next "free block of memory"
// so we are not looking for an unused block of memory, but an unused
// array index. We use allocations[x].prev == [list size] to mark indices
// unused/unallocated

PAGEREF Z_GetNextFreeArrayIndex(){
    int start = currentListHead;
    int i;
    
    for (i = currentListHead + 1; i != currentListHead; i++){
        if (i == EMS_ALLOCATION_LIST_SIZE){
            i = 0;
        }
        
        if (allocations[i].prev == EMS_ALLOCATION_LIST_SIZE){
            return i;
        }

    }

    // error case
    printf("Z_GetNextFreeArrayIndex: Couldn't find a free index!");
    I_Error ("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ",  getNumFreePages(), getFreeMemoryByteTotal(), getBiggestFreeBlock);

    I_Error ("Z_GetNextFreeArrayIndex: Couldn't find a free index!");
    

    return -1;
    
}

MEMREF Z_MallocEMSNew
(int           size,
	unsigned char tag,
	unsigned char user,
	unsigned char sourceHint)
{
	return Z_MallocEMSNewWithBackRef(size, tag, user, sourceHint, -1);
}
MEMREF
Z_MallocEMSNewWithBackRef
( int           size,
  unsigned char           tag,
  unsigned char user,
  unsigned char sourceHint,
  short backRef)
{
    short internalpagenumber;
    short base;
    short start;
    short newfreeblockindex;
    
    int         extra;
    short rover;
    int currentEMSHandle = 0;
    int offsetToNextPage = 0;
    int extrasize = 0;
    int iter = 0;

    int varA = 0;
    int varB = 0;

    char result [2000];
    char result2 [2000];
	
    
    short iterator = 0;
    

    
// TODO : make use of sourceHint?
// ideally alllocations with the same sourceHint try to be in the same block if possible
// but even if they cannot be, the engine should not crash or anything

 

    if (size > MAX_ZMALLOC_SIZE){
		printf  ("Z_MallocEMS: allocation too big! size was %i bytes %i %i %i", size, tag, user, sourceHint);
		I_Error ("Z_MallocEMS: allocation too big! size was %i bytes %i %i %i", size, tag, user, sourceHint);
    }

    size = (size + 3) & ~3;



// algorithm:

// eventually look thru most recently used pages in order?
//    for (internalpagenumber = 3; internalpagenumber--; internalpagenumber >= 0){
//    }

// 
	 
    // scan through the block list,
    // looking for the first free block
    // of sufficient size,
    // throwing out any purgable blocks along the way.
	 
    base = currentListHead;

    if (!allocations[allocations[base].prev].user){
        //printf("\nchecked %p %i %i %p\n", allocations[0].user, allocations[base].prev, base, (void *)mainzoneEMS);
        base = allocations[base].prev;
    }

    rover = base;
    start = allocations[base].prev;

    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)allocations[base].offset & 0x3FFF));
    if (offsetToNextPage == PAGE_FRAME_SIZE){
        offsetToNextPage = 0;
    }

    //printf ("entering loop with base %i rover %i base.size %i", base, rover, allocations[base].size);
    //printf ("b:%is:%i", base, allocations[base].size);
    

  do 
    {
        //printf ("loop  % i   % i  %i\n", size, offsetToNextPage, allocations[base].size);
        iter++;

        if (iter == 4000){
            printf("looping forever?");
           I_Error ("looping forever?");
        }
        
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
                Z_FreeEMSNew (rover, 9);
                base = allocations[base].next;
                rover = allocations[base].next;
            }
            offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int) allocations[base].offset & 0x3FFF))% PAGE_FRAME_SIZE;
            
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

    
    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)allocations[base].offset & 0x3FFF));
    if (offsetToNextPage == PAGE_FRAME_SIZE){
        offsetToNextPage = 0;
    }



   // handle the case where we push to the next frame. create a free block before it.
    if (offsetToNextPage != 0 && size > offsetToNextPage)
    {
        //printf ("pfi: %i \n",base  );
        //printf ("pushing to next page: size %i offset %i\n", size, offsetToNextPage);
        //printf ("BEFORE\n");
        //printf ("base    pos %i size %i next %i prev %i\n", GetBlockAddress(base), allocations[base].size, GetBlockAddress(allocations[base].next), GetBlockAddress(allocations[base].prev));

        //printf ("AFTER\n");


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

 

        //printf ("newbloc pos %i size %i next %i prev %i\n", GetBlockAddress(newfreeblockindex), allocations[newfreeblockindex].size, GetBlockAddress(allocations[newfreeblockindex].next), GetBlockAddress(allocations[newfreeblockindex].prev));
        //printf ("base    pos %i size %i next %i prev %i\n", GetBlockAddress(base), allocations[base].size, GetBlockAddress(allocations[base].next), GetBlockAddress(allocations[base].prev));
		 


           
    }            



// todo: around here we would do  page allocation esp around multi page allocations..

    

// after this call, newfragment -> next is mainblock
// base-> next is newfragment
// base-> prev is the last newfragment in the last call



    
    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)(allocations[base].offset) & 0x3FFF));
// In this case, PAGE FRAME SIZE is ok/expected.
//    if (offsetToNextPage == PAGE_FRAME_SIZE){
//        offsetToNextPage = 0;
//    }


    if (extra >  EMS_MINFRAGMENT)
    {

        // check if remaining size in page frame is < minfragment. If so, push size to end of fragment.
//            4000              3950             64
    if ((offsetToNextPage - size) > 0 && (offsetToNextPage - size) < MINFRAGMENT){
            extrasize = (offsetToNextPage - size);
            //printf ("creating extrasize %p %p %p\n", size, offsetToNextPage, extrasize );
        }

        //printf ("creating new fragment after allocation %i %i %i %i\n", size, offsetToNextPage, extra, extrasize);
        
        //printf ("\nBEFORE:");
        //printf ("base    pos %i size %i next %i prev %i\n", GetBlockAddress(base), allocations[base].size, GetBlockAddress(allocations[base].next), GetBlockAddress(allocations[base].prev));

        //printf ("AFTER:");

        // there will be a free fragment after the allocated block
        newfreeblockindex = Z_GetNextFreeArrayIndex();
        allocations[newfreeblockindex].size = extra-extrasize;
        allocations[newfreeblockindex].user = 0;
        allocations[newfreeblockindex].prev = base;
        allocations[newfreeblockindex].next = allocations[base].next;
		allocations[newfreeblockindex].backRef = -1;
		allocations[allocations[newfreeblockindex].next].prev = newfreeblockindex;

        //TODO CHECK
        allocations[newfreeblockindex].offset = (allocations[base].offset + (size + extrasize)) &0x3FFF ;
        //printf ("page before  %i %i %i\n", allocations[newfreeblockindex].page, size + extrasize, (size + extrasize) >> 14);

        allocations[newfreeblockindex].page = allocations[base].page + ((allocations[base].offset + size + extrasize) >> 14);  // divide by 16k
        //printf ("page after %i %i\n", allocations[newfreeblockindex].page, allocations[base].page);
        

        allocations[base].next = newfreeblockindex;
        allocations[base].size = size + extrasize;

        //printf ("newbloc pos %i size %i next %i prev %i\n", GetBlockAddress(newfreeblockindex), allocations[newfreeblockindex].size, GetBlockAddress(allocations[newfreeblockindex].next), GetBlockAddress(allocations[newfreeblockindex].prev));
        //printf ("base    pos %i size %i next %i prev %i\n", GetBlockAddress(base), allocations[base].size, GetBlockAddress(allocations[base].next), GetBlockAddress(allocations[base].prev));
   
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

    Z_CheckEMSAllocations(base, 0, 0, 0);

//    if (allocations[currentListHead].page > 250){
//        I_Error("C: Last pages? %i %i %i %i %i %i", varA, varB, getNumFreePages(), getFreeMemoryByteTotal(), currentListHead, allocations[currentListHead].page);
//    }

	
	return base;
    //return (void *) ((byte *)mainzoneEMS + ( allocations[base].page * PAGE_FRAME_SIZE + allocations[base].offset ) );

}

int GetBlockAddress(PAGEREF block){
    return allocations[block].page * PAGE_FRAME_SIZE + allocations[block].offset;
}

void Z_CheckEMSAllocations(PAGEREF block, int var, int var2, int var3){

    // all allocation entries should either be in the chain (linked list)
    // OR marked as a free index (prev = EMS_ALLOCATION_LIST_SIZE)
    int unalloactedIndexCount = getNumFreePages();
    short start = allocations[block].prev;
    int iterCount = 1; 
    while (start != block){

        iterCount++;
        if (iterCount > EMS_ALLOCATION_LIST_SIZE){
            printf("\nZ_CheckEMSAllocations: infinite loop detected with block start %i %i %i %i %i %i %i %i %i %i", start, iterCount, getNumFreePages(), getFreeMemoryByteTotal(), getNumPurgeableBlocks, getBiggestFreeBlock(), getBiggestFreeBlockIndex(), var, var2, var3);
            I_Error("\nZ_CheckEMSAllocations: infinite loop detected with block start %i %i %i %i %i %i %i %i %i %i", start, iterCount, getNumFreePages(), getFreeMemoryByteTotal(), getNumPurgeableBlocks, getBiggestFreeBlock(), getBiggestFreeBlockIndex(), var, var2, var3);
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
    
