



//
// Z_MallocEMS
// You can pass a NULL user if the tag is < PU_PURGELEVEL.
//

char    tempstringtext[80];
int BIGGEST_SIZE = 64 * 1024;
int pageFreeOrder = 0;  // 8 bit s = 4 pages, least significant is next to be evicted

static startingInt = 0;

void*
Z_MallocEMS
( int           size,
  int           tag,
  void*         user,
  int           sourceHint )
{
    

    int         extra;
    memblock_t* start;
    memblock_t* rover;
    memblock_t* newblock;
    memblock_t* newfreeblock;
    memblock_t* base;
    int currentEMSHandle = 0;
    int offsetToNextPage = 0;
    int extrasize = 0;
    int iter = 0;

    int varA = 0;
    int varB = 0;
    
// TODO : make use of sourceHint
// ideally alllocations with the same sourceHint try to be in the same block if possible
// but even if they cannot be, the engine should not crash or anything

/*
    if (startingInt == 0){
        startingInt = mainzoneEMS->rover;
    }
*/

    if (size > MAX_ZMALLOC_SIZE){
        I_Error ("Z_MallocEMS: allocation too big! size was %i bytes ", size);
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
    base = mainzoneEMS->rover;
    
    if (!base->prev->user)
        base = base->prev;

        
    rover = base;
    start = base->prev;

    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)base & 0x3FFF));
    if (offsetToNextPage == PAGE_FRAME_SIZE){
        offsetToNextPage = 0;
    }
    
    //printf ("attempting z_malloc of size %i or %p offset to %p\n", size, size, ((unsigned int) base )&0x3FFF);
    //printf ("base size %p position %p offset %p %i \n", base->size, base, offsetToNextPage, offsetToNextPage );
    //printf ("the check: %i vs %u \n", size + (   offsetToNextPage    ), base->size  );

        
  do 
    {
        //printf ("loop  % i   % i  %i\n", size, offsetToNextPage, base->size);
        iter++;

        if (iter == 100000){
           I_Error ("looping forever?");
        }
        
        if (rover == start) {
            // scanned all the way around the list
           printf("Z_Malloc: failed on allocation of %i bytes", size);
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
                Z_FreeEMS ((byte *)rover+sizeof(memblock_t));
                base = base->next;
                rover = base->next;
                
            }
            offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int) base & 0x3FFF))% PAGE_FRAME_SIZE;
        }
        else
            rover = rover->next;

            
    } while (base->user || base->size < size 
       // problem: free block, and size is big enough but not aligned to page frame and we dont want to split page frame
       // so we must check that the block has enough free space when aligned to next page frame
        || (size + (   offsetToNextPage   ) > base->size)
    );




    // found a block big enough
    extra = base->size - size;

    
    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)base & 0x3FFF));
    if (offsetToNextPage == PAGE_FRAME_SIZE){
        offsetToNextPage = 0;
    }



   // handle the case where we push to the next frame. create a free block before it.
    if (offsetToNextPage != 0 && size > offsetToNextPage)
    {
        //printf ("pushing to next page: size %p offset %p\n", size, offsetToNextPage);
        //printf ("BEFORE\n");
        //printf ("main    pos %p               next %p prev %p\n", &mainzoneEMS->blocklist, mainzoneEMS->blocklist.next, mainzoneEMS->blocklist.prev);
        //printf ("base    pos %p size %p next %p prev %p\n", base, base->size, base->next, base->prev);

        //printf ("AFTER\n");

        varA += 1;
        newfreeblock = base;
        base = (memblock_t *) ((byte *)newfreeblock + offsetToNextPage);

        base->user = NULL;  
        base->tag = 0; 
        base->size = newfreeblock->size - offsetToNextPage;
        base->prev = newfreeblock;
        base->next = newfreeblock->next;
        base->next->prev = base;

        newfreeblock->next = base;
        newfreeblock->size = offsetToNextPage;

        extra = extra - offsetToNextPage;

        //printf ("main    pos %p               next %p prev %p\n", &mainzoneEMS->blocklist, mainzoneEMS->blocklist.next, mainzoneEMS->blocklist.prev);
        //printf ("newfree pos %p size %p next %p prev %p\n", newfreeblock, newfreeblock->size, newfreeblock->next, newfreeblock->prev);
        //printf ("base    pos %p size %p next %p prev %p\n", base, base->size, base->next, base->prev);

//        startingInt++;
//     if (startingInt == 1)
//            I_Error("done");

    }            

// todo: around here we would do  page allocation esp around multi page allocations..

    

// after this call, newfragment -> next is mainblock
// base-> next is newfragment
// base-> prev is the last newfragment in the last call



    
    offsetToNextPage = (PAGE_FRAME_SIZE - ((unsigned int)(base) & 0x3FFF));
// In this case, PAGE FRAME SIZE is ok/expected.
//    if (offsetToNextPage == PAGE_FRAME_SIZE){
//        offsetToNextPage = 0;
//    }

    
    if (extra >  MINFRAGMENT)
    {

        // check if remaining size in page frame is < minfragment. If so, push size to end of fragment.
//            4000              3950             64
        if ((offsetToNextPage - size) > 0 && (offsetToNextPage - size) < MINFRAGMENT){
            extrasize = (offsetToNextPage - size);
            //printf ("creating extrasize %p %p %p\n", size, offsetToNextPage, extrasize );
        }


        varA += 2;

        //printf ("creating new fragment after allocation\n");
        //printf ("\nBEFORE\n");
        //printf ("main    pos %p               next %p prev %p\n", &mainzoneEMS->blocklist, mainzoneEMS->blocklist.next, mainzoneEMS->blocklist.prev);
        //printf ("base    pos %p size %p next %p prev %p\n", base, base->size, base->next, base->prev);

        //printf ("AFTER\n");

       

          // there will be a free fragment after the allocated block
        newblock = (memblock_t *) ((byte *)base + size + extrasize );
        newblock->size = extra - extrasize;
        
        // NULL indicates free block.
        newblock->user = NULL;  
        newblock->tag = 0;
        newblock->prev = base;
        newblock->next = base->next;
        newblock->next->prev = newblock;

        base->next = newblock;
        base->size = size + extrasize;

        //printf ("main    pos %p               next %p prev %p\n", &mainzoneEMS->blocklist, mainzoneEMS->blocklist.next, mainzoneEMS->blocklist.prev);
        //printf ("newbloc pos %p size %p next %p prev %p\n", newblock, newblock->size, newblock->next, newblock->prev);
        //printf ("base    pos %p size %p next %p prev %p\n", base, base->size, base->next, base->prev);

   
    }
    
    if (user)
    {
        varA += 4;
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
    mainzoneEMS->rover = base->next;       
        
    base->id = ZONEID;

    //printf ("z_malloc returning size %i at offset %i \n", size, base + sizeof(memblock_t));

    Z_CheckHeapA(iter, varA, base, newblock);

    return (void *) ((byte *)base + sizeof(memblock_t));

}


//
// Z_FreeEMS
//

// rather than taking a pointer, we send the EMS handle

//void Z_FreeEMS (int emsHandle)
void Z_FreeEMS (void* ptr)
{


    memblock_t*         block;
    memblock_t*         other;
    freeCount++;
     
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

        if (block == mainzoneEMS->rover)
            mainzoneEMS->rover = other;

        block = other;
    }
        
    other = block->next;
    if (!other->user)
    {
        // merge the next free block onto the end
        block->size += other->size;
        block->next = other->next;
        block->next->prev = block;

        if (other == mainzoneEMS->rover)
            mainzoneEMS->rover = block;
    }

    Z_CheckHeapB();

}

// TODO delete later
void Z_CheckHeapB (void)
{
    memblock_t* block;
    int iter = 0;  

    for (block = mainzoneEMS->blocklist.next ; ; block = block->next)
    {

        iter++;

        if (iter == 100000){
           I_Error ("looping forever?");
        }


        if (block->next == &mainzoneEMS->blocklist)
        {
            // all blocks have been hit
            break;
        }
        
        if ( (byte *)block + block->size != (byte *)block->next)
            I_Error ("Z_CheckHeapB: block size does not touch the next block %p %p %p\n", block, block->size, block->next);
        

        if ( block->next->prev != block)
            I_Error ("Z_CheckHeapB: next block doesn't have proper back link %i %i %p %p %p %p %p %p %p\n", iter, freeCount, block, block->next, block->prev, &mainzoneEMS->blocklist,
        mainzoneEMS->blocklist.prev, mainzoneEMS->blocklist.next,  block->next->prev
            );

        if (!block->user && !block->next->user)
            I_Error ("Z_CheckHeapB: two consecutive free blocks\n");
    }
}


// TODO delete later
void Z_CheckHeapA (int iterIn, int varA, memblock_t* inBlock, memblock_t* newBlock)
{
    memblock_t* block;
    int iter = 0;  

    for (block = mainzoneEMS->blocklist.next ; ; block = block->next)
    {

        iter++;

        if (iter == 100000){
           I_Error ("looping forever?");
        }


        if (block->next == &mainzoneEMS->blocklist)
        {
            // all blocks have been hit
            break;
        }
        
        if ( (byte *)block + block->size != (byte *)block->next)
            I_Error ("Z_CheckHeapA: block size does not touch the next block %p %p %p\n", block, block->size, block->next);
        



        if ( block->next->prev != block)
            I_Error ("Z_CheckHeapA: next block doesn't have proper back link %i %i %p %p %p %p %p %p %p\n\n%i %i %p %p %p %p %p %p %p %p", iter, freeCount, block, block->next, block->prev, &mainzoneEMS->blocklist,
        mainzoneEMS->blocklist.prev, mainzoneEMS->blocklist.next,  block->next->prev, iterIn, varA, inBlock, inBlock->prev, inBlock->next, newBlock, newBlock->prev, newBlock->next, inBlock->size, newBlock-> size
            );

        if (!block->user && !block->next->user)
            I_Error ("Z_CheckHeapA: two consecutive free blocks\n");
    }
}

