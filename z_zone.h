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
//      Zone Memory Allocation, perhaps NeXT ObjectiveC inspired.
//      Remark: this was the only stuff that, according
//       to John Carmack, might have been useful for
//       Quake.
//


#ifndef __Z_ZONE__
#define __Z_ZONE__

#include <stdio.h>

//
// ZONE MEMORY
// PU - purge tags.
// Tags < 100 are not overwritten until freed.
#define PU_STATIC               1       // static entire execution time
#define PU_SOUND                2       // static while playing
#define PU_MUSIC                3       // static while playing
#define PU_DAVE                 4       // anything else Dave wants static
#define PU_LEVEL                50      // static until level exited
#define PU_LEVSPEC              51      // a special thinker in a level
// Tags >= 100 are purgable whenever needed.
#define PU_PURGELEVEL   100
#define PU_CACHE                101

#define ALLOC_TYPE_TEXTURE 1
#define ALLOC_TYPE_CACHE_LUMP 2
#define ALLOC_TYPE_LEVSPEC 3
#define ALLOC_TYPE_FWIPE 4
#define ALLOC_TYPE_READFILE 5
#define ALLOC_TYPE_TEXTURE_TRANSLATION 6
#define ALLOC_TYPE_FLAT_TRANSLATION 7
#define ALLOC_TYPE_PCX 8
#define ALLOC_TYPE_SPRITE 9
#define ALLOC_TYPE_COLORMAP 10
#define ALLOC_TYPE_TRANSLATION_TABLES 11
#define ALLOC_TYPE_SPRITEDEFS 12
#define ALLOC_TYPE_SPRITEFRAMES 13
#define ALLOC_TYPE_VERTEXES 14
#define ALLOC_TYPE_SEGMENTS 15
#define ALLOC_TYPE_LINEBUFFER 16
#define ALLOC_TYPE_BLOCKLINKS 17
#define ALLOC_TYPE_NODES 18
#define ALLOC_TYPE_SOUND_CHANNELS 19
#define ALLOC_TYPE_DEMO_BUFFER 20
#define ALLOC_TYPE_LNAMES 21
#define ALLOC_TYPE_SCREEN 22
#define ALLOC_TYPE_THINKER 23
#define ALLOC_TYPE_SUBSECS 24
#define ALLOC_TYPE_SIDES 25
#define ALLOC_TYPE_LINES 26
#define ALLOC_TYPE_SECTORS 27

typedef unsigned short MEMREF;  //used externally for allocations list index
typedef unsigned short PAGEREF; //used internally for allocations list index

// Note: a memref of 0 refers to the empty (size = 0) 'head' of doubly linked list
// managing the pages, and this index can never be handed out, so it's safe to use
// as a 'null' or unused memref.
#define NULL_MEMREF 0



extern int numreads;
extern int pageins;
extern int pageouts;
extern int thebspnum;

void    Z_Init (void);
void*   Z_Malloc (int size, int tag, void *ptr);
void    Z_Free (void *ptr);
void    Z_FreeTags (int lowtag, int hightag);
void    Z_DumpHeap (int lowtag, int hightag);
void    Z_FileDumpHeap (FILE *f);
void    Z_CheckHeap (void);

void    Z_ChangeTag2 (void *ptr, int tag);
int     Z_FreeMemory (void);


typedef struct memblock_s
{
    int                 size;   // including the header and possibly tiny fragments
    void**              user;   // NULL if a free block
    int                 tag;    // purgelevel
    int                 id;     // should be ZONEID
    struct memblock_s*  next;
    struct memblock_s*  prev;
} memblock_t;



void Z_InitEMS(void);
void Z_FreeTagsEMS (int lowtag, int hightag);
void* Z_LoadBytesFromEMS2 (MEMREF index, char* file, int line);
MEMREF Z_MallocEMSNew(int size, unsigned char tag, unsigned char user, unsigned char sourceHint);
MEMREF Z_MallocEMSNewWithBackRef(int size, unsigned char tag, unsigned char user, unsigned char sourceHint, short backRef);
#ifdef MEMORYCHECK
void Z_CheckEMSAllocations(PAGEREF block, int i, int var2, int var3);
#endif
void Z_ChangeTagEMSNew (MEMREF index, short tag);
void Z_FreeEMSNew(PAGEREF block, int error);

int Z_RefIsActive2(MEMREF memref, char* file, int line);


//
// This is used to get the local FILE:LINE info from CPP
// prior to really call the function in question.
//
#define Z_ChangeTag(p,t) \
{ \
      if (( (memblock_t *)( (byte *)(p) - sizeof(memblock_t)))->id!=0x1d4a11) \
          I_Error("Z_CT at "__FILE__":%i",__LINE__); \
          Z_ChangeTag2(p,t); \
};

#define Z_LoadBytesFromEMS(a) Z_LoadBytesFromEMS2(a, __FILE__, __LINE__)
#define Z_RefIsActive(a) Z_RefIsActive2(a, __FILE__, __LINE__)



#endif

 
