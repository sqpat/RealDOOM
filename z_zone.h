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
#include "doomtype.h"
//
// ZONE MEMORY
// PU - purge tags.
// Tags < PU_PURGELEVEL are not overwritten until freed.

// NOTE: redid a lot of these. I think the values implied that there would be more
// aggressive freeing, etc of memory based on some of the allocation types. But
// in practice, PU_SOUND/PU_MUSIC are never handled differently in the code, LEVSPEC
// is never handled differently than LEVEL, PURGELEVEL is never used... etc
#define PU_UNUSED               0       // static entire execution time
#define PU_STATIC               1       // static entire execution time
#define PU_SOUND                1       // static while playing
#define PU_MUSIC                1
#define PU_LEVEL                2      // static until level exited
#define PU_LEVSPEC              2      // a special thinker in a level
// Tags >= PU_PURGELEVEL are purgable whenever needed.
// Note: codebase never actually allocates anything as PU_PURGE_LEVEL
#define PU_PURGELEVEL           3 
#define PU_CACHE                3

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

typedef uint16_t MEMREF;  //used externally for allocations list index
typedef uint16_t PAGEREF; //used internally for allocations list index

// Note: a memref of 0 refers to the empty (size = 0) 'head' of doubly linked list
// managing the pages, and this index can never be handed out, so it's safe to use
// as a 'null' or unused memref.
#define NULL_MEMREF 0



extern int32_t numreads;
extern int32_t pageins;
extern int32_t pageouts;
extern int32_t thebspnum;

typedef struct memblock_s
{
	int32_t                 size;   // including the header and possibly tiny fragments
    void**              user;   // NULL if a free block
	int32_t                 tag;    // purgelevel
	int32_t                 id;     // should be ZONEID
    struct memblock_s*  next;
    struct memblock_s*  prev;
} memblock_t;



void Z_InitEMS(void);
void Z_FreeTagsEMS (int32_t lowtag, int32_t hightag);
MEMREF Z_MallocEMSNew(int32_t size, uint8_t tag, uint8_t user, uint8_t sourceHint);
MEMREF Z_MallocEMSNewWithBackRef(int32_t size, uint8_t tag, uint8_t user, uint8_t sourceHint, int16_t backRef);
#ifdef MEMORYCHECK
void Z_CheckEMSAllocations(PAGEREF block, int32_t i, int32_t var2, int32_t var3);
#endif
void Z_ChangeTagEMSNew (MEMREF index, int16_t tag);
void Z_FreeEMSNew(PAGEREF block);


void* Z_LoadBytesFromEMS2(MEMREF index);
int32_t Z_RefIsActive2(MEMREF memref);

#define Z_LoadBytesFromEMS(a) Z_LoadBytesFromEMS2(a)
#define Z_RefIsActive(a) Z_RefIsActive2(a)

/*
int32_t Z_RefIsActive2(MEMREF memref, int8_t* file, int32_t line);
void* Z_LoadBytesFromEMS2 (MEMREF index, int8_t* file, int32_t line);

#define Z_LoadBytesFromEMS(a) Z_LoadBytesFromEMS2(a, __FILE__, __LINE__)
#define Z_RefIsActive(a) Z_RefIsActive2(a, __FILE__, __LINE__)
*/



#endif

 
