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
// Tags < PU_CACHE are not overwritten until freed.

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
#define PU_CACHE                3
 

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
extern int32_t taskswitchcount;

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


#define ALLOCATION_LIST_HEAD	0
#define EMS_ALLOCATION_LIST_SIZE 1050

//#define STATIC_CONVENTIONAL_BLOCK_SIZE_1 54208
#define STATIC_CONVENTIONAL_BLOCK_SIZE_2 5586
// 10343 extra in 1 still

extern uint16_t STATIC_CONVENTIONAL_BLOCK_SIZE_1;
extern uint16_t remainingconventional1;
extern byte* conventionalmemoryblock1;
extern byte* spritememoryblock;


//extern byte conventionalmemoryblock1[STATIC_CONVENTIONAL_BLOCK_SIZE_1];
extern byte conventionalmemoryblock2[STATIC_CONVENTIONAL_BLOCK_SIZE_2];

void Z_InitEMS(void);
void Z_FreeTagsEMS();
void Z_InitConventional(void);
void Z_InitUMB(void);
void Z_FreeConventionalAllocations();

#define BACKREF_LUMP_OFFSET EMS_ALLOCATION_LIST_SIZE
MEMREF Z_MallocEMS(uint16_t size, uint8_t tag, uint8_t user);
MEMREF Z_MallocEMSWithBackRef32(int32_t  size, uint8_t tag, uint8_t user, int16_t backRef);
MEMREF Z_MallocEMSWithBackRef16(uint16_t  size, uint8_t tag, uint8_t user, int16_t backRef);
MEMREF Z_MallocConventional(uint16_t  size, uint8_t tag, int16_t type, uint8_t forceblock);


void Z_ChangeTagEMS(MEMREF index, int16_t tag);
void Z_FreeEMS(PAGEREF block);


void Z_SetUnlocked(MEMREF ref);
//void* Z_LoadBytesFromEMS2(MEMREF index);




void* Z_LoadBytesFromConventional(MEMREF index);
void* Z_LoadSpriteFromConventional(MEMREF index);
void* Z_LoadTextureInfoFromConventional(MEMREF index);
//#define Z_LoadSpriteFromConventional(a) Z_LoadBytesFromConventionalWithOptions2 (a, PAGE_NOT_LOCKED, CA_TYPE_SPRITE)
//#define Z_LoadTextureInfoFromConventional(a) Z_LoadBytesFromConventionalWithOptions2 (a, PAGE_NOT_LOCKED, CA_TYPE_TEXTURE_INFO)
//#define Z_LoadBytesFromConventionalWithOptions(a, b, c) Z_LoadBytesFromConventionalWithOptions2 (a, b, c)
//#define Z_LoadBytesFromConventional(a) Z_LoadBytesFromConventionalWithOptions2(a, PAGE_NOT_LOCKED, CA_TYPE_LEVELDATA)
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



typedef struct
{
	PAGEREF prev;    //2    using 16 bits but need 11 or 12...
	PAGEREF next;    //4    using 16 bits but need 11 or 12...         these 3 could fit in 32 bits?

	// page and offset refer to internal EMS page and offset - in other words the keys
	// to find the real location in memory for this allocation

	// page;       using 9 bits... implies page max count of 512 (8 MB worth)
	// size;        use 23 bits implying max of 8MB-1 or 0x007FFFFF max free size,
	fixed_t_union page_and_size; // page is 9 high bits, size is 23 low bits
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

#define TASK_PHYSICS 0
#define TASK_PHYSICS9000 1
#define TASK_RENDER 2
#define TASK_STATUS 3
#define TASK_RENDER7000TO6000 4


// EMS 4.0 stuff
void Z_QuickmapPhysics();
void Z_QuickmapPhysics9000();
void Z_QuickmapRender();
void Z_QuickmapStatus();
void Z_QuickmapRender7000to6000();
void Z_GetEMSPageMap();
void Z_LoadBinaries();

#define PAGE_TYPE_PHYSICS 0
#define PAGE_TYPE_RENDER 1

byte* far Z_GetNext0x7000Address(uint16_t size, int8_t pagetype);
void Z_Subtract0x7000Address(uint16_t size, int8_t pagetype);
#define Z_GetNextPhysicsAddress(A) Z_GetNext0x7000Address(A, PAGE_TYPE_PHYSICS)
#define Z_GetNextRenderAddress(A) Z_GetNext0x7000Address(A, PAGE_TYPE_RENDER)
#define Z_SubtractRenderAddress(A) Z_Subtract0x7000Address(A, PAGE_TYPE_RENDER)
extern int16_t currenttask;

#endif


