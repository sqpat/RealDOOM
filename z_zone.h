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
#include "doomdef.h"

//
// ZONE MEMORY
// PU - purge tags.
// Tags < PU_PURGELEVEL are not overwritten until freed.

// NOTE: redid a lot of these. I think the values implied that there would be more
// aggressive freeing, etc of memory based on some of the allocation types. But
// in practice, PU_SOUND/PU_MUSIC are never handled differently in the code, LEVSPEC
// is never handled differently than LEVEL, PURGELEVEL is never used... etc

// the block is unused
#define PU_NOT_IN_USE           0       // static entire execution time
// these are never freed in practice
#define PU_STATIC               1       // static entire execution time
#define PU_SOUND                1       // static while playing
#define PU_MUSIC                1
// these are sometimes free in practice
#define PU_LEVEL                2      // static until level exited
#define PU_LEVSPEC              2      // a special thinker in a level
// These essentially are freed when more memory starts to run out
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
#define ALLOC_TYPE_VISPLANE 28
#define ALLOC_TYPE_MOBJ 29

#define ALLOC_TYPE_STRINGS 30

#define ALLOC_TYPE_NIGHTMARE_SPAWN_DATA 31
#define ALLOC_TYPE_LINEOPENINGS 32

// most paged in order:
// as expected, we need to find a way to get lines segs verts sectors nodes into conventional to greatly improve perf.
//  lines, segments vertexes Sectors, nodes, cachelump(wad),  levspec (mobj)  ,  sprite, spritedefs

#define PAGE_LOCKED true
#define PAGE_NOT_LOCKED false

typedef uint16_t MEMREF;  //used externally for allocations list index
typedef uint16_t PAGEREF; //used internally for allocations list index

// Note: a memref of 0 refers to the empty (size = 0) 'head' of doubly linked list
// managing the pages, and this index can never be handed out, so it's safe to use
// as a 'null' or unused memref.
#define NULL_MEMREF 0

extern int32_t numreads;
extern int32_t pageins;
extern int32_t pageouts;

typedef struct memblock_s
{
	int32_t                 size;   // including the header and possibly tiny fragments
	void**              user;   // NULL if a free block
	int32_t                 tag;    // purgelevel
	int32_t                 id;     // should be ZONEID
	struct memblock_s*  next;
	struct memblock_s*  prev;
} memblock_t;

// these get cleared per level
#define CA_TYPE_LEVELDATA 1
// these are static
#define CA_TYPE_SPRITE 3
// mobjs and thinkers
#define CA_TYPE_THINKER 4
// texcols and tex
#define CA_TYPE_TEXTURE_INFO 5

//			   e1m1 = less
//			   e1m2 = 54078, 27412
//			   e1m3-e1m5 probably ok
//             e1m6 huge
// timedemo1 = e1m7 = 51556, 27431
//			   e1m8, m9 small


#define STATIC_CONVENTIONAL_BLOCK_SIZE_1 54208
//#define STATIC_CONVENTIONAL_BLOCK_SIZE_2 18892   // no lineopenings demo 3
#define STATIC_CONVENTIONAL_BLOCK_SIZE_2 30035  

extern byte conventionalmemoryblock1[STATIC_CONVENTIONAL_BLOCK_SIZE_1];
extern byte conventionalmemoryblock2[STATIC_CONVENTIONAL_BLOCK_SIZE_2];

void Z_InitEMS(void);
void Z_FreeTagsEMS(int16_t tag);
void Z_InitConventional(void);
void Z_FreeConventionalAllocations();

#define BACKREF_LUMP_OFFSET 2048
MEMREF Z_MallocEMS(uint32_t size, uint8_t tag, uint8_t user, uint8_t sourceHint);
MEMREF Z_MallocEMSWithBackRef(uint32_t size, uint8_t tag, uint8_t user, uint8_t sourceHint, int16_t backRef);
MEMREF Z_MallocConventional(uint32_t size, uint8_t tag, int16_t type, uint8_t user, uint8_t sourceHint);

#ifdef MEMORYCHECK
void Z_CheckEMSAllocations(PAGEREF block, int32_t i, int32_t var2, int32_t var3);
#endif
void Z_ChangeTagEMS(MEMREF index, int16_t tag);
void Z_FreeEMS(PAGEREF block);


void Z_SetUnlocked(MEMREF ref);
//void* Z_LoadBytesFromEMS2(MEMREF index);




void* Z_LoadBytesFromConventionalWithOptions2(MEMREF index, boolean locked, int16_t type);
#define Z_LoadSpriteFromConventional(a) Z_LoadBytesFromConventionalWithOptions2 (a, PAGE_NOT_LOCKED, CA_TYPE_SPRITE)
#define Z_LoadTextureInfoFromConventional(a) Z_LoadBytesFromConventionalWithOptions2 (a, PAGE_NOT_LOCKED, CA_TYPE_TEXTURE_INFO)
#define Z_LoadBytesFromConventionalWithOptions(a, b, c) Z_LoadBytesFromConventionalWithOptions2 (a, b, c)
#define Z_LoadBytesFromConventional(a) Z_LoadBytesFromConventionalWithOptions2(a, PAGE_NOT_LOCKED, CA_TYPE_LEVELDATA)
void* Z_LoadBytesFromEMSWithOptions2(MEMREF index, boolean locked);
#define Z_LoadBytesFromEMSWithOptions(a,b) Z_LoadBytesFromEMSWithOptions2(a, b)
#define Z_LoadBytesFromEMS(a) Z_LoadBytesFromEMSWithOptions2(a, PAGE_NOT_LOCKED)
/*
void* Z_LoadBytesFromConventionalWithOptions2(MEMREF index, boolean locked, int16_t type, int8_t* file, int32_t line);
#define Z_LoadSpriteFromConventional(a) Z_LoadBytesFromConventionalWithOptions2 (a, PAGE_NOT_LOCKED, CA_TYPE_SPRITE, __FILE__, __LINE__)
#define Z_LoadTextureInfoFromConventional(a) Z_LoadBytesFromConventionalWithOptions2 (a, PAGE_NOT_LOCKED, CA_TYPE_TEXTURE_INFO, __FILE__, __LINE__)
#define Z_LoadBytesFromConventionalWithOptions(a, b, c) Z_LoadBytesFromConventionalWithOptions2 (a, b, c, __FILE__, __LINE__)
#define Z_LoadBytesFromConventional(a) Z_LoadBytesFromConventionalWithOptions2(a, PAGE_NOT_LOCKED, CA_TYPE_LEVELDATA, __FILE__, __LINE__)
void* Z_LoadBytesFromEMSWithOptions2(MEMREF index, boolean locked, int8_t* file, int32_t line);
#define Z_LoadBytesFromEMSWithOptions(a,b) Z_LoadBytesFromEMSWithOptions2(a, b, __FILE__, __LINE__)
#define Z_LoadBytesFromEMS(a) Z_LoadBytesFromEMSWithOptions2(a, PAGE_NOT_LOCKED, __FILE__, __LINE__)
*/

#ifdef CHECKREFS
int16_t Z_RefIsActive2(MEMREF memref, int8_t* file, int32_t line);
#define Z_RefIsActive(a) Z_RefIsActive2(a, __FILE__, __LINE__)
#else
#define Z_RefIsActive(a) 
#endif
/*
void* Z_LoadBytesFromEMS2 (MEMREF index, int8_t* file, int32_t line);
#define Z_LoadBytesFromEMS(a) Z_LoadBytesFromEMS2(a, __FILE__, __LINE__)


	int16_t Z_RefIsActive2(MEMREF memref);
	#define Z_RefIsActive(a) Z_RefIsActive2(a)

*/

void Z_ShutdownEMS();

#define ALLOCATION_LIST_HEAD	0
#define EMS_ALLOCATION_LIST_SIZE 1000



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


#endif


