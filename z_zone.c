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

char result[2000];
char result2[2000];



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
char pagesize[NUM_EMS_PAGES];


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
int actualpageins = 0;
int actualpageouts = 0;

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

    

    if ((unsigned)user > 0x100){
        userbyte = 0xff;
    } else {
        userbyte = (unsigned)user &0xff;
    }
	 
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




void Z_FreeEMSNew (PAGEREF block)
{


    short         other;
	short usedBackref;
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
            Z_FreeEMSNew ( block);
    }

   
}

void Z_MarkPageLRU(char pagenumber) {


	//int neworder = 0;
	//int bitpattern = 3;
	int i;
	int j;

	

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


int Z_RefIsActive2(MEMREF memref, char* file, int line){
	int pageframeindex; 
	
	if (memref > EMS_ALLOCATION_LIST_SIZE) {
		I_Error("Z_RefIsActive: alloc too big %i ", memref);
	}

	for (pageframeindex = 0; pageframeindex < NUM_EMS_PAGES; pageframeindex++) {
		if (activepages[pageframeindex] == allocations[memref].page) {
			return 1;
		}
	}

	printf("Z_RefIsActive: Found inactive ref! %i %s %i tick %i ", memref, file, line, gametic);
	I_Error("Z_RefIsActive: Found inactive ref! %i %s %i tick %i ", memref, file, line, gametic);

	return 0;
}

// marks page as most recently used
// error behavior if pagenumber not in the list?
void Z_MarkPageMRU(char pagenumber, char* file, int line) {

	//int neworder = 0;
	//int bitpattern = 3;
	int i;
	int j;

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
		I_Error("(MRU) Could not find page number in LRU cache: %i %i %i %i %s %i", pagenumber, numreads, pageins, pageouts, file, line);
	}

	

	// i now represents where the page was in the cache. move it to the back and everything else up.

	for (j = i; j < NUM_EMS_PAGES -1; j++) {
		pageevictorder[j] = pageevictorder[j + 1];
	}

	pageevictorder[NUM_EMS_PAGES - 1] = pagenumber;

}


void Z_DoPageOut(short pageframeindex) {
	// swap OUT memory
	int i = 0;
	int numPagesToSwap = pagesize[pageframeindex];
	byte* copysrc = copyPageArea + (pageframeindex * PAGE_FRAME_SIZE);
	byte* copydst = (byte*)mainzoneEMS + (activepages[pageframeindex] * PAGE_FRAME_SIZE);

	// don't swap out an already swapped out page
	if (activepages[pageframeindex] == -1) {
		return;
	}
	
	if (numPagesToSwap <= 0) {
		numPagesToSwap = 1;
	}

	memcpy(copydst, copysrc, PAGE_FRAME_SIZE * numPagesToSwap);
	memset(copysrc, 0x00, PAGE_FRAME_SIZE * numPagesToSwap);

	actualpageouts++;
	pageouts += numPagesToSwap;

	for (i = 0; i < numPagesToSwap; i++) {
		activepages[pageframeindex+i] = -1;
		pagesize[pageframeindex + i] = -1;
		Z_MarkPageLRU(pageframeindex + i);

	}

}

void Z_DoPageIn(short logicalpage, short pageframeindex, unsigned char numallocatepages) {

	int i = 0;
	byte* copydst = copyPageArea + pageframeindex * PAGE_FRAME_SIZE;
	byte* copysrc = (byte*)mainzoneEMS + logicalpage * PAGE_FRAME_SIZE;
	
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
		Z_MarkPageMRU(pageframeindex + i, "", 0);
	}

}


// gets a page index for this EMS page.
// forces a page swap if necessary.

// "page frame" is the upper memory EMS page frame
// logical page is where it corresponds to in the big block of otherwise inaccessible memory..

short Z_GetEMSPageFrame(short logicalpage, unsigned int size, char* file, int line){  //todo allocations < 65k? if so size can be an unsigned short?
    char pageframeindex;

	unsigned char extradeallocatepages = 0;
	unsigned char numallocatepages;
	unsigned char i;
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
					Z_MarkPageMRU(pageframeindex + i, file, line);
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
	
	//printf("\n new: %i %i %i %i", pageevictorder[0], pageevictorder[1], pageevictorder[2], pageevictorder[3]);
	//printf("\n new: %i %i %i %i", activepages[0], activepages[1], activepages[2], activepages[3]);

 

	
    return pageframeindex;
}

void* Z_LoadBytesFromEMS2(MEMREF ref, char* file, int line) {
    byte* memorybase;
	short pageframeindex;
    byte* address;
	mobj_t* thing;


 
 	if (ref > EMS_ALLOCATION_LIST_SIZE) {
		I_Error("out of bounds memref.. tick %i    %i %s %i", gametic, ref, file, line);
	}
	if (ref == 0) {
		I_Error("tried to load memref 0... tick %i    %i %s %i", gametic, ref, file, line);
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
 

	pageframeindex = Z_GetEMSPageFrame(allocations[ref].page, allocations[ref].size, file, line);
	memorybase = (byte*)copyPageArea;
 
	address = memorybase
		+ PAGE_FRAME_SIZE * pageframeindex
		+ allocations[ref].offset;


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
    printf("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ", getNumFreePages(), getFreeMemoryByteTotal(), getBiggestFreeBlock);
    I_Error ("Z_GetNextFreeArrayIndex: failed on allocation of %i pages %i bytes %i biggest %i ",  getNumFreePages(), getFreeMemoryByteTotal(), getBiggestFreeBlock);

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

    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)allocations[base].offset & 0x3FFF));
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



    
    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)(allocations[base].offset) & 0x3FFF));
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

int GetBlockAddress(PAGEREF block){
    return allocations[block].page * PAGE_FRAME_SIZE + allocations[block].offset;
}
#ifdef MEMORYCHECK

void Z_CheckEMSAllocations(PAGEREF block){

    // all allocation entries should either be in the chain (linked list)
    // OR marked as a free index (prev = EMS_ALLOCATION_LIST_SIZE)
    
	int unalloactedIndexCount = getNumFreePages();
    short start = allocations[block].prev;
    int iterCount = 1; 
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
    
