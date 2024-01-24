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

#include "p_local.h"

#include <dos.h>
#include <stdlib.h>
 


// 8 MB worth. 
#define MAX_PAGE_FRAMES 512
 


// ugly... but it does work. I don't think we can ever make use of more than 2 so no need to listify
uint16_t STATIC_CONVENTIONAL_BLOCK_SIZE = 0;
byte far* conventionalmemoryblock;

uint16_t remainingconventional = 0;
uint16_t conventional1head = 	  0;






// todo turn these into dynamic allocations
  


int16_t emshandle;
extern union REGS regs;
extern struct SREGS segregs;


byte far*			pageFrameArea;

// count allocations etc, can be used for benchmarking purposes.

 
 

extern uint16_t leveldataoffset_phys;
extern uint16_t leveldataoffset_rend;
extern int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
 
extern uint8_t firstunusedflat; // they are always 4k sized, can figure out page and offset from that. 
extern int32_t totalpatchsize;


extern int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
extern int16_t textureLRU[4];
extern uint8_t activenumpages[4]; // always gets reset to defaults at start of frame

 // called in between levels, frees level stuff like sectors, frees thinkers, etc.
void Z_FreeConventionalAllocations() {
	int16_t i;

	// we should be paged to physics now - should be ok
	FAR_memset(thinkerlist, 0, MAX_THINKERS * sizeof(thinker_t));

	FAR_memset(conventionalmemoryblock, 0, STATIC_CONVENTIONAL_BLOCK_SIZE);

	// todo make this area less jank. We want to free all the ems 4.0 region level data...
	FAR_memset(MK_FP(0x7000, 0-leveldataoffset_phys), 0, leveldataoffset_phys);
	leveldataoffset_phys = 0;
	
	FAR_memset(MK_FP(0x7000, 0 - leveldataoffset_rend), 0, leveldataoffset_rend);
	leveldataoffset_rend = 0;

	remainingconventional = STATIC_CONVENTIONAL_BLOCK_SIZE;
	conventional1head = 0;

	
	FAR_memset(nightmarespawns, 0, sizeof(mapthing_t) * MAX_THINKERS);

	Z_QuickmapRender();

	//reset texturee cache
	FAR_memset(compositetexturepage, 0xFF, sizeof(uint8_t) * (numtextures));
	FAR_memset(compositetextureoffset,0xFF, sizeof(uint8_t) * (numtextures));
	FAR_memset(usedcompositetexturepagemem, 00, sizeof(uint8_t) * NUM_TEXTURE_PAGES);
	
	FAR_memset(patchpage, 0xFF, sizeof(uint8_t) * (numpatches));
	FAR_memset(patchoffset, 0xFF, sizeof(uint8_t) * (numpatches));
	FAR_memset(usedpatchpagemem, 00, sizeof(uint8_t) * NUM_PATCH_CACHE_PAGES);

	FAR_memset(spritepage, 0xFF, sizeof(uint8_t) * (numspritelumps));
	FAR_memset(spriteoffset, 0xFF, sizeof(uint8_t) * (numspritelumps));
	FAR_memset(usedspritepagemem, 00, sizeof(uint8_t) * NUM_SPRITE_CACHE_PAGES);

	FAR_memset(flatindex, 0xFF, sizeof(uint8_t) * numflats);
	firstunusedflat = 0;
	
	Z_QuickmapPhysics();

	totalpatchsize = 0;

	for (i = 0; i < 4; i++) {
		activetexturepages[i] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		textureLRU[i] = i;
		pageswapargs[pageswapargs_rend_offset + 40 + i * 2] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		activenumpages[i] = 0;
	}

}



// mostly very easy because we just allocate sequentially and never remove except all at once. no fragmentation
//  EXCEPT thinkers
void far* Z_MallocConventional( 
	uint16_t           size){
	byte far* returnvalue = conventionalmemoryblock + conventional1head;

	if (size > remainingconventional) {
		I_Error("79 %u %u", size, remainingconventional);// out of conventional space %u %u
	}
	conventional1head += size;
	remainingconventional -= size;
	return returnvalue;
	
}

// Unlike other conventional allocations, these are freed and cause fragmentation of the memory block



 

// EMS 4.0 functionality

// page for 0x9000 block where we will store thinkers in physics code, then visplanes etc in render code
int16_t pagenum9000;

//these offsets at runtime must have pagenum9000 added to them

#define PAGE_9000_OFFSET + 0
#define PAGE_9400_OFFSET + 1
#define PAGE_9800_OFFSET + 2
#define PAGE_9C00_OFFSET + 3

#define PAGE_8000_OFFSET - 4
#define PAGE_8400_OFFSET - 3
#define PAGE_8800_OFFSET - 2
#define PAGE_8C00_OFFSET - 1

#define PAGE_7000_OFFSET - 8
#define PAGE_7400_OFFSET - 7
#define PAGE_7800_OFFSET - 6
#define PAGE_7C00_OFFSET - 5

#define PAGE_6000_OFFSET - 12
#define PAGE_6400_OFFSET - 11
#define PAGE_6800_OFFSET - 10
#define PAGE_6C00_OFFSET - 9

#define PAGE_5000_OFFSET - 16
#define PAGE_5400_OFFSET - 15
#define PAGE_5800_OFFSET - 14
#define PAGE_5C00_OFFSET - 13

#define PAGE_4000_OFFSET - 20
#define PAGE_4400_OFFSET - 19
#define PAGE_4800_OFFSET - 18
#define PAGE_4C00_OFFSET - 17

#define RENDER_7000_LOGICAL_PAGE  28


//#define pageswapargs_scratch5000_offset pageswapargs_textinfo_offset + num_textinfo_params



int16_t pageswapargs[total_pages] = {
	0,	PAGE_9000_OFFSET, 1,	PAGE_9400_OFFSET, 2,	PAGE_9800_OFFSET, 3,	PAGE_9C00_OFFSET,
	4,	PAGE_8000_OFFSET, 5,	PAGE_8400_OFFSET, 6,	PAGE_8800_OFFSET, 7,	PAGE_8C00_OFFSET,
	8,	PAGE_7000_OFFSET, 9,	PAGE_7400_OFFSET, 10,	PAGE_7800_OFFSET, 11,	PAGE_7C00_OFFSET,
	12, PAGE_6000_OFFSET, 13,	PAGE_6400_OFFSET, 14,	PAGE_6800_OFFSET, 15,	PAGE_6C00_OFFSET,
	16, PAGE_5000_OFFSET, 17,	PAGE_5400_OFFSET, 18,	PAGE_5800_OFFSET, 19,	PAGE_5C00_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE,	 PAGE_4400_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 1, PAGE_4800_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 2, PAGE_4C00_OFFSET,

	// render
	20,	PAGE_9000_OFFSET, 21,	PAGE_9400_OFFSET, 22,	PAGE_9800_OFFSET, 23,	PAGE_9C00_OFFSET,
	24,	PAGE_8000_OFFSET, 25,	PAGE_8400_OFFSET, 26,	PAGE_8800_OFFSET, 27,	PAGE_8C00_OFFSET,
	28,	PAGE_7000_OFFSET, 29,	PAGE_7400_OFFSET, 30,	PAGE_7800_OFFSET, 31,	PAGE_7C00_OFFSET,
	32, PAGE_6000_OFFSET, 33,	PAGE_6400_OFFSET, 34,	PAGE_6800_OFFSET, 35,	PAGE_6C00_OFFSET,
	16, PAGE_5000_OFFSET, 17,	PAGE_5400_OFFSET, 18,	PAGE_5800_OFFSET, 19,	PAGE_5C00_OFFSET,  // repeated trig tables

	FIRST_TEXTURE_LOGICAL_PAGE + 0,	PAGE_4000_OFFSET,
	FIRST_TEXTURE_LOGICAL_PAGE + 1,	PAGE_4400_OFFSET,
	FIRST_TEXTURE_LOGICAL_PAGE + 2,	PAGE_4800_OFFSET,
	FIRST_TEXTURE_LOGICAL_PAGE + 3,	PAGE_4C00_OFFSET,  // texture cache area

	// status/hud
	SCREEN4_LOGICAL_PAGE, PAGE_9C00_OFFSET,
	FIRST_STATUS_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	FIRST_STATUS_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	FIRST_STATUS_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	FIRST_STATUS_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,
	STRINGS_LOGICAL_PAGE, PAGE_6000_OFFSET,
	// demo
	FIRST_DEMO_LOGICAL_PAGE + 0, PAGE_5000_OFFSET,
	FIRST_DEMO_LOGICAL_PAGE + 1, PAGE_5400_OFFSET,
	FIRST_DEMO_LOGICAL_PAGE + 2, PAGE_5800_OFFSET,
	FIRST_DEMO_LOGICAL_PAGE + 3, PAGE_5C00_OFFSET,

 // textinfo

	TEXTURE_INFO_LOGICAL_PAGE + 0, PAGE_6000_OFFSET,
	TEXTURE_INFO_LOGICAL_PAGE + 1, PAGE_6400_OFFSET,
	TEXTURE_INFO_LOGICAL_PAGE + 2, PAGE_6800_OFFSET,
	TEXTURE_INFO_LOGICAL_PAGE + 3, PAGE_6C00_OFFSET,
// we use 0x5000 as a  'scratch' page frame for certain things
// scratch 5000
	FIRST_SCRATCH_LOGICAL_PAGE + 0, PAGE_5000_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 1, PAGE_5400_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 2, PAGE_5800_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 3, PAGE_5C00_OFFSET,

// but sometimes we need that in the 0x4000 segment..
// scratch 4000
	FIRST_SCRATCH_LOGICAL_PAGE + 0, PAGE_4000_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 1, PAGE_4400_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 2, PAGE_4800_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 3, PAGE_4C00_OFFSET,

	// scratch stack 
	FIRST_SCRATCH_LOGICAL_PAGE + 0, PAGE_5000_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 1, PAGE_5400_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 2, PAGE_5800_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 3, PAGE_5C00_OFFSET,
	FIRST_TRIG_TABLE_LOGICAL_PAGE + 0, PAGE_5000_OFFSET,
	FIRST_TRIG_TABLE_LOGICAL_PAGE + 1, PAGE_5400_OFFSET,
	FIRST_TRIG_TABLE_LOGICAL_PAGE + 2, PAGE_5800_OFFSET,
	FIRST_TRIG_TABLE_LOGICAL_PAGE + 3, PAGE_5C00_OFFSET,

// todo - we are only using one page at 0x5C00 currently
// flat cache
	FIRST_FLAT_CACHE_LOGICAL_PAGE + 0, PAGE_5C00_OFFSET,
	// palette
	SCREEN0_LOGICAL_PAGE + 0, PAGE_8000_OFFSET,
	SCREEN0_LOGICAL_PAGE + 1, PAGE_8400_OFFSET,
	SCREEN0_LOGICAL_PAGE + 2, PAGE_8800_OFFSET,
	SCREEN0_LOGICAL_PAGE + 3, PAGE_8C00_OFFSET,
	PALETTE_LOGICAL_PAGE, PAGE_9000_OFFSET,

	// 7000 to 6000
	RENDER_7000_LOGICAL_PAGE + 0, PAGE_6000_OFFSET,
	RENDER_7000_LOGICAL_PAGE + 1, PAGE_6400_OFFSET,
	RENDER_7000_LOGICAL_PAGE + 2, PAGE_6800_OFFSET,
	RENDER_7000_LOGICAL_PAGE + 3, PAGE_6C00_OFFSET,
// menu 
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,
	STRINGS_LOGICAL_PAGE ,	PAGE_6000_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 4, PAGE_6400_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 5, PAGE_6800_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 6, PAGE_6C00_OFFSET,

// task 
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 4, PAGE_6000_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 5, PAGE_6400_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 6, PAGE_6800_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 7, PAGE_6C00_OFFSET,
	SCREEN0_LOGICAL_PAGE + 0, PAGE_8000_OFFSET,
	SCREEN0_LOGICAL_PAGE + 1, PAGE_8400_OFFSET,
	SCREEN0_LOGICAL_PAGE + 2, PAGE_8800_OFFSET,
	SCREEN0_LOGICAL_PAGE + 3, PAGE_8C00_OFFSET,
	SCREEN1_LOGICAL_PAGE + 0, PAGE_9000_OFFSET,
	SCREEN1_LOGICAL_PAGE + 1, PAGE_9400_OFFSET,
	SCREEN1_LOGICAL_PAGE + 2, PAGE_9800_OFFSET,
	SCREEN1_LOGICAL_PAGE + 3, PAGE_9C00_OFFSET,
	// wipe

	FIRST_WIPE_LOGICAL_PAGE, PAGE_9000_OFFSET,
	SCREEN0_LOGICAL_PAGE + 0, PAGE_8000_OFFSET,
	SCREEN0_LOGICAL_PAGE + 1, PAGE_8400_OFFSET,
	SCREEN0_LOGICAL_PAGE + 2, PAGE_8800_OFFSET,
	SCREEN0_LOGICAL_PAGE + 3, PAGE_8C00_OFFSET,
	SCREEN2_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	SCREEN2_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	SCREEN2_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	SCREEN2_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,
	SCREEN3_LOGICAL_PAGE + 0, PAGE_6000_OFFSET,
	SCREEN3_LOGICAL_PAGE + 1, PAGE_6400_OFFSET,
	SCREEN3_LOGICAL_PAGE + 2, PAGE_6800_OFFSET,
	SCREEN3_LOGICAL_PAGE + 3, PAGE_6C00_OFFSET,

	FIRST_LUMPINFO_LOGICAL_PAGE,	PAGE_4400_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE +1, PAGE_4800_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE +2, PAGE_4C00_OFFSET,

	FIRST_LUMPINFO_LOGICAL_PAGE,	 PAGE_5400_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 1, PAGE_5800_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 2, PAGE_5C00_OFFSET



};

int16_t pageswapargseg;
int16_t pageswapargoff;

int8_t current5000flatpage = -1;
uint8_t current5000RemappedScratchPage = 0;

int8_t current4000State = PAGE_4000_UNMAPPED;
int8_t last4000State = PAGE_4000_UNMAPPED;
int8_t current5000State = PAGE_5000_UNMAPPED;
int8_t last5000State = PAGE_5000_UNMAPPED;


#ifdef DETAILED_BENCH_STATS
int32_t taskswitchcount = 0;
int32_t texturepageswitchcount = 0;
int32_t patchpageswitchcount = 0;
int32_t compositepageswitchcount = 0;
int32_t spritepageswitchcount = 0;
int16_t benchtexturetype = 0;
int32_t flatpageswitchcount = 0;
int32_t scratchpageswitchcount = 0;
int32_t scratchpoppageswitchcount = 0;
int32_t scratchpushpageswitchcount = 0;
int32_t scratchremapswitchcount = 0;
int32_t lumpinfo4000switchcount = 0;
int32_t lumpinfo5000switchcount = 0;

#endif
int16_t currenttask = -1;
int16_t oldtask = -1;

void Z_QuickmapPhysics() {
	//int16_t errorreg;

	regs.w.ax = 0x5000;  
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff;
	intx86(EMS_INT, &regs, &regs);


	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff+32;
	intx86(EMS_INT, &regs, &regs);
	
	regs.w.ax = 0x5000;
	regs.w.cx = 0x07; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff + 64;
	intx86(EMS_INT, &regs, &regs);

	/*
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		I_Error("Call 0x5000 failed with value %i!\n", errorreg);
	}
	*/
#ifdef DETAILED_BENCH_STATS
	taskswitchcount ++;
#endif
	currenttask = TASK_PHYSICS;
	current4000State = PAGE_4000_LUMPINFO;
	current5000State = PAGE_5000_TRIG;
}
 

void Z_QuickmapDemo() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_demo_offset_size;
	intx86(EMS_INT, &regs, &regs);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_DEMO; // not sure about this
	current5000State = PAGE_5000_DEMOBUFFER;

}


// sometimes needed when rendering sprites..
void Z_QuickmapRender7000to6000() {


	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_7000to6000_offset_size;
	intx86(EMS_INT, &regs, &regs);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_RENDER7000TO6000; // not sure about this
}

void Z_QuickmapRender() {
	regs.w.ax = 0x5000; 
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size;
	intx86(EMS_INT, &regs, &regs);

	// grumble... emm386 fails with 12, but not 8. its a silent failure. was very very annoying to debug
	// todo: test real ems hardware...

	regs.w.ax = 0x5000;
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size + 32;
	intx86(EMS_INT, &regs, &regs);
 
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size + 64;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_RENDER;


	current5000State = PAGE_5000_TRIG;
	current4000State = PAGE_4000_TEXTURE;
}

// leave off 0x4000 region. Usually used in p_setup...
void Z_QuickmapRender_NoTex() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size;
	intx86(EMS_INT, &regs, &regs);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size + 32;
	intx86(EMS_INT, &regs, &regs);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size + 64;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_RENDER;

	current5000State = PAGE_5000_TRIG;

}



// sometimes needed when rendering sprites..
void Z_QuickmapRenderTexture() {
//void Z_QuickmapRenderTexture(uint8_t offset, uint8_t count) {

	//pageswapargs_textcache[2];
	/*

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff_textcache;
	intx86(EMS_INT, &regs, &regs);
	*/

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size + 80;
	intx86(EMS_INT, &regs, &regs);
 
	/*

	regs.w.ax = 0x5000;
	regs.w.cx = count; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff_textcache + (offset << 2);
	intx86(EMS_INT, &regs, &regs);
	*/
	current4000State = PAGE_4000_TEXTURE;


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	texturepageswitchcount++;

	if (benchtexturetype == TEXTURE_TYPE_PATCH) {
		patchpageswitchcount++;
	} else if (benchtexturetype == TEXTURE_TYPE_COMPOSITE) {
		compositepageswitchcount++;
	} else if (benchtexturetype == TEXTURE_TYPE_SPRITE) {
		spritepageswitchcount++;
	}


#endif
	currenttask = TASK_RENDER_TEXT; // not sure about this
}


// sometimes needed when rendering sprites..
void Z_QuickmapStatus() {

	regs.w.ax = 0x5000;
	regs.w.cx = 0x06; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_stat_offset_size;
	intx86(EMS_INT, &regs, &regs);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_STATUS;
}

void Z_QuickmapScratch_5000() {

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_scratch5000_offset_size;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	scratchpageswitchcount++;
#endif

	current5000State = PAGE_5000_SCRATCH;

}
void Z_QuickmapScratch_4000() {

	if (current4000State != PAGE_4000_SCRATCH){
		regs.w.ax = 0x5000;
		regs.w.cx = 0x04; // page count
		regs.w.dx = emshandle; // handle
		segregs.ds = pageswapargseg;
		regs.w.si = pageswapargs_scratch4000_offset_size;
		intx86(EMS_INT, &regs, &regs);

		current4000State = PAGE_4000_SCRATCH;

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		scratchpageswitchcount++;

	#endif
	}
}

void Z_QuickmapScreen0() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff+16;
	intx86(EMS_INT, &regs, &regs);
}

int8_t scratchstacklevel = 0;

void Z_PushScratchFrame() {

	scratchstacklevel++;
	if (scratchstacklevel == 1){
		regs.w.ax = 0x5000;
		regs.w.cx = 0x04; // page count
		regs.w.dx = emshandle; // handle
		segregs.ds = pageswapargseg;
		regs.w.si = pageswapargs_scratchstack_offset_size;
		intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		scratchpushpageswitchcount++;

#endif
		oldtask = currenttask;
		currenttask = TASK_SCRATCH_STACK;
		current5000State = PAGE_5000_SCRATCH;
	}
	// doesnt come up
	/*
	else {
		I_Error("double stack");
	}
	*/
}
 

void Z_PopScratchFrame() {

	scratchstacklevel--;
	if (scratchstacklevel == 0) {
		regs.w.ax = 0x5000;
		regs.w.cx = 0x04; // page count
		regs.w.dx = emshandle; // handle
		segregs.ds = pageswapargseg;
		regs.w.si = pageswapargs_scratchstack_offset_size + 16;
		intx86(EMS_INT, &regs, &regs);

#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		scratchpoppageswitchcount++;

#endif
		// todo not doing 5000 page?

		currenttask = oldtask;
		
		pageswapargs[pageswapargs_scratch5000_offset + 0] = FIRST_SCRATCH_LOGICAL_PAGE;
		pageswapargs[pageswapargs_scratch5000_offset + 2] = FIRST_SCRATCH_LOGICAL_PAGE + 1;
		pageswapargs[pageswapargs_scratch5000_offset + 4] = FIRST_SCRATCH_LOGICAL_PAGE + 2;
		pageswapargs[pageswapargs_scratch5000_offset + 6] = FIRST_SCRATCH_LOGICAL_PAGE + 3;

	}
}

void Z_QuickMapFlatPage(int16_t page) {
	pageswapargs[pageswapargs_flatcache_offset] = page;

	// only use 3 pages? or what? dont want to clobber zlight..

	regs.w.ax = 0x5000;
	regs.w.cx = 0x01; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_flatcache_offset_size;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	flatpageswitchcount++;

#endif
	current5000State = PAGE_5000_TRIG_TEXTURE;
	current5000flatpage = page;
}


void Z_QuickMapTextureInfoPage() {

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_textinfo_offset_size;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
}

void Z_RemapScratchFrame(uint8_t startpage) {
	pageswapargs[pageswapargs_scratch5000_offset + 0] = startpage;
	pageswapargs[pageswapargs_scratch5000_offset + 2] = startpage+1;
	pageswapargs[pageswapargs_scratch5000_offset + 4] = startpage+2;
	pageswapargs[pageswapargs_scratch5000_offset + 6] = startpage+3;

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_scratch5000_offset_size;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	scratchremapswitchcount++;
#endif
	current5000State = PAGE_5000_SCRATCH_REMAP;
	current5000RemappedScratchPage = startpage;
}

void Z_QuickmapTrig() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_rend_offset_size + 64;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	current5000State = PAGE_5000_TRIG;
}

void Z_QuickmapLumpInfo() {
	
	switch (current4000State) {

		case PAGE_4000_UNMAPPED:
			// use conventional memory until set up...
			return;
	 
		case PAGE_4000_SCRATCH:
		case PAGE_4000_TEXTURE:
			regs.w.ax = 0x5000;
			regs.w.cx = 0x03; // page count
			regs.w.dx = emshandle; // handle
			segregs.ds = pageswapargseg;
			regs.w.si = pageswapargs_lumpinfo_offset_size;

			intx86(EMS_INT, &regs, &regs);
	#ifdef DETAILED_BENCH_STATS
			taskswitchcount++;
			lumpinfo4000switchcount++;
#endif
		
			last4000State = current4000State;
			current4000State = PAGE_4000_LUMPINFO;
 
			return;
		case PAGE_4000_LUMPINFO:
			last4000State = PAGE_4000_LUMPINFO;
			return;
		default:
			I_Error("bad state %i", current4000State);

	}
}

void Z_UnmapLumpInfo() {


	switch (last4000State) {
		case PAGE_4000_SCRATCH:
			Z_QuickmapScratch_4000();
			break;
		case PAGE_4000_TEXTURE:
			Z_QuickmapRenderTexture();
			break;
		default:
			break;
	}
	// doesn't really need cleanup - this isnt dual-called

}



void Z_QuickmapLumpInfo5000() {

	switch (current5000State) {

		case PAGE_5000_TRIG_TEXTURE:
		case PAGE_5000_SCRATCH:
		case PAGE_5000_TRIG:
		case PAGE_5000_UNMAPPED:
		case PAGE_5000_DEMOBUFFER:
		case PAGE_5000_SCRATCH_REMAP:
			regs.w.ax = 0x5000;
			regs.w.cx = 0x03; // page count
			regs.w.dx = emshandle; // handle
			segregs.ds = pageswapargseg;
			regs.w.si = pageswapargs_lumpinfo_5400_offset_size;

			intx86(EMS_INT, &regs, &regs);
	#ifdef DETAILED_BENCH_STATS
			taskswitchcount++;
			lumpinfo5000switchcount++;
	#endif

			last5000State = current5000State;
			current5000State = PAGE_5000_LUMPINFO;
			return;
		case PAGE_5000_LUMPINFO:
			last5000State = PAGE_5000_LUMPINFO;
			return;
		default:
			I_Error("bad state %i", current5000State);

	}
}

void Z_UnmapLumpInfo5000() {

	switch (last5000State) {
		case PAGE_5000_SCRATCH_REMAP:
			Z_RemapScratchFrame(current5000RemappedScratchPage);
			break;
		case PAGE_5000_SCRATCH:
			Z_QuickmapScratch_5000();
			break;
		case PAGE_5000_TRIG:
			Z_QuickmapTrig();
			break;
		case PAGE_5000_TRIG_TEXTURE:
			Z_QuickmapTrig();
			Z_QuickMapFlatPage(current5000flatpage);
			break;
		case PAGE_5000_DEMOBUFFER:
			Z_QuickmapDemo();
			break;
		case PAGE_5000_UNMAPPED:
		case PAGE_5000_LUMPINFO:
			default:
				break;
	}
	// doesn't really need cleanup - this isnt dual-called

}

void Z_QuickmapPalette() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x05; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_palette_offset_size;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_PALETTE;
}
void Z_QuickmapMenu() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si  = pageswapargs_menu_offset_size;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_MENU;
}

void Z_QuickmapIntermission() {
	/*
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_menu_offset_size;
	intx86(EMS_INT, &regs, &regs);
	*/

	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_intermission_offset_size;
	intx86(EMS_INT, &regs, &regs);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_intermission_offset_size + 32;
	intx86(EMS_INT, &regs, &regs);
 
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_INTERMISSION;
}

void Z_QuickmapWipe() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_wipe_offset_size;
	intx86(EMS_INT, &regs, &regs);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x05; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargs_wipe_offset_size + 32;
	intx86(EMS_INT, &regs, &regs);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_WIPE;
}

void Z_QuickmapByTaskNum(int8_t tasknum) {
	switch (tasknum) {
		case TASK_PHYSICS:
			Z_QuickmapPhysics();
			break;
		case TASK_RENDER:
			Z_QuickmapRender();
			break;
		case TASK_STATUS:
			Z_QuickmapStatus();
			break;
		case TASK_RENDER_TEXT:
			Z_QuickmapRender();
			Z_QuickmapRenderTexture(); // should be okay this way
			break;
		case TASK_MENU:
			Z_QuickmapMenu();
			break;
		case TASK_INTERMISSION:
			Z_QuickmapIntermission();
			break;
		default:
			I_Error("78 %hhi", tasknum); // bad tasknum
	}
}

extern void D_InitStrings();
extern void P_Init();

// clears dead initialization code.
void Z_ClearDeadCode() {
	byte far *startaddr =	(byte far*)D_InitStrings;
	byte far *endaddr =		(byte far*)P_Init;
	uint16_t size = endaddr - startaddr;
	FAR_memset(startaddr, 0, size);
	//13500 or so
	//DEBUG_PRINT("\nClearing out %u bytes of initialization code", size);
}

/*
void DUMP_MEMORY_TO_FILE() {
	int16_t segment = 0x4000;
	FILE*fp = fopen("MEM_DUMP.BIN", "wb");
	while (segment < 0xA000) {
		byte far * dest = MK_FP(segment, 0);
		FAR_fwrite(dest, 32768, 1, fp);
		segment += 0x0800;
	}
	fclose(fp);
	I_Error("\ndumped");
}
*/
