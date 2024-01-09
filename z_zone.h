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

 
// Note: a memref of 0 refers to the empty (size = 0) 'head' of doubly linked list
// managing the pages, and this index can never be handed out, so it's safe to use
// as a 'null' or unused memref.
#define NULL_THINKERREF 0

 
#ifdef DETAILED_BENCH_STATS
extern int32_t taskswitchcount;
extern int32_t texturepageswitchcount;
extern int32_t flatpageswitchcount;
extern int32_t scratchpageswitchcount;
extern int32_t scratchpoppageswitchcount;
extern int32_t scratchpushpageswitchcount;
extern int32_t scratchremapswitchcount;

#endif

 

 



#define ALLOCATION_LIST_HEAD	0


// DOOM SHAREWARE VALUE
#define STATIC_CONVENTIONAL_SPRITE_SIZE 6939u



#define MAX_THINKERS 840
#define SPRITE_ALLOCATION_LIST_SIZE 150

#define TEXTURE_CACHE_OVERHEAD_SIZE NUM_TEXTURE_PAGES + (numtextures * 2)
#define SPRITE_CACHE_OVERHEAD_SIZE NUM_SPRITE_CACHE_PAGES + (numspritelumps * 2)
#define PATCH_CACHE_OVERHEAD_SIZE NUM_PATCH_CACHE_PAGES + (numpatches * 2)
#define FLAT_CACHE_OVERHEAD_SIZE numflats
#define CACHE_OVERHEAD_SIZE (TEXTURE_CACHE_OVERHEAD_SIZE + SPRITE_CACHE_OVERHEAD_SIZE + PATCH_CACHE_OVERHEAD_SIZE + FLAT_CACHE_OVERHEAD_SIZE)


#define UMB2_SIZE STATIC_CONVENTIONAL_SPRITE_SIZE + (MAX_THINKERS * sizeof(mobj_pos_t)) 
extern uint16_t STATIC_CONVENTIONAL_BLOCK_SIZE;
extern uint16_t remainingconventional;
extern byte* conventionalmemoryblock;

extern uint16_t EMS_PAGE;



void Z_InitEMS(void);
void Z_InitUMB(void);
void Z_FreeConventionalAllocations();

#define BACKREF_LUMP_OFFSET EMS_ALLOCATION_LIST_SIZE
 
void far* Z_MallocConventional(uint16_t  size);
 

void Z_ShutdownEMS();
 

#define SCREEN0_LOGICAL_PAGE				4
#define STRINGS_LOGICAL_PAGE				12
#define FIRST_TRIG_TABLE_LOGICAL_PAGE		16
#define FIRST_RENDER_LOGICAL_PAGE			20
#define TEXTURE_INFO_LOGICAL_PAGE			FIRST_RENDER_LOGICAL_PAGE + 12
#define SCREEN4_LOGICAL_PAGE				TEXTURE_INFO_LOGICAL_PAGE + 4
#define FIRST_STATUS_LOGICAL_PAGE			SCREEN4_LOGICAL_PAGE + 1
#define PALETTE_LOGICAL_PAGE				FIRST_STATUS_LOGICAL_PAGE + 4
#define FIRST_DEMO_LOGICAL_PAGE				PALETTE_LOGICAL_PAGE + 1
#define	FIRST_MENU_GRAPHICS_LOGICAL_PAGE	FIRST_DEMO_LOGICAL_PAGE + 4
#define SCREEN2_LOGICAL_PAGE				FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 7
#define SCREEN3_LOGICAL_PAGE				SCREEN2_LOGICAL_PAGE + 4
#define FIRST_WIPE_LOGICAL_PAGE				SCREEN3_LOGICAL_PAGE + 4
#define FIRST_SCRATCH_LOGICAL_PAGE			FIRST_WIPE_LOGICAL_PAGE + 1
#define FIRST_PATCH_CACHE_LOGICAL_PAGE		FIRST_SCRATCH_LOGICAL_PAGE + 4
#define NUM_PATCH_CACHE_PAGES				40
#define FIRST_FLAT_CACHE_LOGICAL_PAGE		FIRST_PATCH_CACHE_LOGICAL_PAGE + NUM_PATCH_CACHE_PAGES
#define NUM_FLAT_CACHE_PAGES				8
#define MAX_FLATS_LOADED					NUM_FLAT_CACHE_PAGES * 4
#define FIRST_TEXTURE_LOGICAL_PAGE			FIRST_FLAT_CACHE_LOGICAL_PAGE + NUM_FLAT_CACHE_PAGES
#define NUM_TEXTURE_PAGES					24
#define FIRST_SPRITE_CACHE_LOGICAL_PAGE		FIRST_TEXTURE_LOGICAL_PAGE + NUM_TEXTURE_PAGES
#define NUM_SPRITE_CACHE_PAGES				36
#define NUM_EMS4_SWAP_PAGES					(int32_t)(FIRST_SPRITE_CACHE_LOGICAL_PAGE + NUM_SPRITE_CACHE_PAGES)
// 174 currently

#define TASK_PHYSICS 0
#define TASK_RENDER 1
#define TASK_STATUS 2
#define TASK_DEMO 3
#define TASK_PHYSICS9000 4
#define TASK_RENDER7000TO6000 5
#define TASK_RENDER_TEXT 6
#define TASK_SCRATCH_STACK 7
#define TASK_PALETTE 8
#define TASK_MENU 9
#define TASK_WIPE 10

#define SCRATCH_PAGE_SEGMENT 0x5000u

// EMS 4.0 stuff
void Z_QuickmapPhysics();
void Z_QuickmapRender();
void Z_QuickmapRender_NoTex();
void Z_QuickmapStatus();
void Z_QuickmapDemo();
void Z_QuickmapRender7000to6000();
void Z_QuickmapByTaskNum(int8_t task);
void Z_QuickmapRenderTexture();
//void Z_QuickmapRenderTexture(uint8_t offset, uint8_t count);
void Z_QuickmapScratch_5000();
void Z_QuickmapScratch_4000();
void Z_PushScratchFrame();
void Z_PopScratchFrame();
void Z_RemapScratchFrame(uint8_t startpage);
void Z_QuickMapFlatPage(int16_t page);
void Z_QuickMapTextureInfoPage();
void Z_QuickmapPalette();
void Z_QuickmapMenu();
void Z_QuickmapScreen0();
void Z_QuickmapWipe();


void Z_GetEMSPageMap();
void Z_LinkEMSVariables();
void Z_LinkConventionalVariables();
void Z_LoadBinaries();

#define PAGE_TYPE_PHYSICS 0
#define PAGE_TYPE_RENDER 1


extern int16_t currenttask;

#endif


