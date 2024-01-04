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
byte* conventionalmemoryblock;

uint16_t remainingconventional = 0;
uint16_t conventional1head = 	  0;






// todo turn these into dynamic allocations
  


int16_t emshandle;
extern union REGS regs;
extern struct SREGS segregs;


byte*			pageFrameArea;

// count allocations etc, can be used for benchmarking purposes.

 
 

extern uint16_t leveldataoffset_phys;
extern uint16_t leveldataoffset_rend;
extern int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
 
extern uint8_t firstunusedflat; // they are always 4k sized, can figure out page and offset from that. 
extern int32_t totalpatchsize;


extern int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
extern int16_t textureLRU[4];
extern int16_t pageswapargs_textcache[8];

 // called in between levels, frees level stuff like sectors, frees thinkers, etc.
void Z_FreeConventionalAllocations() {
	int16_t i;

	// we should be paged to physics now - should be ok
	memset(thinkerlist, 0, MAX_THINKERS * sizeof(thinker_t));

	memset(conventionalmemoryblock, 0, STATIC_CONVENTIONAL_BLOCK_SIZE);

	// todo make this area less jank. We want to free all the ems 4.0 region level data...
	memset(MK_FP(0x7000, 0-leveldataoffset_phys), 0, leveldataoffset_phys);
	leveldataoffset_phys = 0;
	
	memset(MK_FP(0x7000, 0 - leveldataoffset_rend), 0, leveldataoffset_rend);
	leveldataoffset_rend = 0;

	remainingconventional = STATIC_CONVENTIONAL_BLOCK_SIZE;
	conventional1head = 0;

	
	memset(nightmarespawns, 0, sizeof(mapthing_t) * MAX_THINKERS);

	Z_QuickmapRender();

	//reset texturee cache
	memset(compositetexturepage, 0xFF, sizeof(uint8_t) * (numtextures));
	memset(compositetextureoffset,0xFF, sizeof(uint8_t) * (numtextures));
	memset(usedcompositetexturepagemem, 00, sizeof(uint8_t) * NUM_TEXTURE_PAGES);
	
	memset(patchpage, 0xFF, sizeof(uint8_t) * (numpatches));
	memset(patchoffset, 0xFF, sizeof(uint8_t) * (numpatches));
	memset(usedpatchpagemem, 00, sizeof(uint8_t) * NUM_PATCH_CACHE_PAGES);

	memset(spritepage, 0xFF, sizeof(uint8_t) * (numspritelumps));
	memset(spriteoffset, 0xFF, sizeof(uint8_t) * (numspritelumps));
	memset(usedspritepagemem, 00, sizeof(uint8_t) * NUM_SPRITE_CACHE_PAGES);

	memset(flatindex, 0xFF, sizeof(uint8_t) * numflats);
	firstunusedflat = 0;
	
	Z_QuickmapPhysics();

	totalpatchsize = 0;

	for (i = 0; i < 4; i++) {
		activetexturepages[i] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		textureLRU[i] = i;
		pageswapargs_textcache[i * 2] = FIRST_TEXTURE_LOGICAL_PAGE + i;
	}

}



// mostly very easy because we just allocate sequentially and never remove except all at once. no fragmentation
//  EXCEPT thinkers
void* far Z_MallocConventional( 
	uint16_t           size){
	byte* far returnvalue = conventionalmemoryblock + conventional1head;

	if (size > remainingconventional) {
		I_Error("out of conventional space %u %u", size, remainingconventional);
	}
	conventional1head += size;
	remainingconventional -= size;
	return returnvalue;
	
	
	
	 
	 
	
}

// Unlike other conventional allocations, these are freed and cause fragmentation of the memory block




  

byte *I_ZoneBaseEMS(int32_t *size, int16_t *emshandle);


void Z_InitEMS(void)
{

	int32_t size;
	int16_t i = 0;
	//todo figure this out based on settings, hardware, etc
	int32_t pageframeareasize = NUM_EMS_PAGES * PAGE_FRAME_SIZE;

	pageFrameArea = I_ZoneBaseEMS(&size, &emshandle);
	
}

// EMS 4.0 functionality

// page for 0x9000 block where we will store thinkers in physics code, then visplanes etc in render code
int16_t pagenum9000; 
int16_t pageswapargs_phys[40];
int16_t pageswapargs_rend[48];
int16_t pageswapargs_stat[12];
int16_t pageswapargs_demo[8];
int16_t pageswapargs_menu[16];
int16_t pageswapargs_wipe[26];
int16_t pageswapargs_palette[10];
int16_t pageswapargs_textcache[8];
int16_t pageswapargs_textinfo[8];
int16_t pageswapargs_scratch_4000[8]; // we use 0x5000 as a  'scratch' page frame for certain things
int16_t pageswapargs_scratch_5000[8]; // we use 0x5000 as a  'scratch' page frame for certain things
int16_t pageswapargs_scratch_stack[16]; // we use 0x5000 as a  'scratch' page frame for certain things
int16_t pageswapargs_rend_temp_7000_to_6000[8];
int16_t pageswapargs_flat[8];

int16_t pageswapargseg_phys;
int16_t pageswapargoff_phys;
int16_t pageswapargseg_rend;
int16_t pageswapargoff_rend;
int16_t pageswapargseg_stat;
int16_t pageswapargoff_stat;
int16_t pageswapargseg_demo;
int16_t pageswapargoff_demo;
int16_t pageswapargseg_menu;
int16_t pageswapargoff_menu;
int16_t pageswapargseg_wipe;
int16_t pageswapargoff_wipe;
int16_t pageswapargseg_palette;
int16_t pageswapargoff_palette;
int16_t pageswapargseg_textcache;
int16_t pageswapargoff_textcache;
int16_t pageswapargseg_textinfo;
int16_t pageswapargoff_textinfo;
int16_t pageswapargseg_scratch_4000;
int16_t pageswapargoff_scratch_4000;
int16_t pageswapargseg_scratch_5000;
int16_t pageswapargoff_scratch_5000;
int16_t pageswapargseg_scratch_stack;
int16_t pageswapargoff_scratch_stack;
int16_t pageswapargseg_flat;
int16_t pageswapargoff_flat;
int32_t taskswitchcount = 0;
int16_t currenttask = -1;
int16_t oldtask = -1;

void Z_QuickmapPhysics() {
	//int16_t errorreg;

	regs.w.ax = 0x5000;  
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_phys;
	regs.w.si = pageswapargoff_phys;
	intx86(EMS_INT, &regs, &regs);


	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_phys;
	regs.w.si = pageswapargoff_phys+32;
	intx86(EMS_INT, &regs, &regs);
	
	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_phys;
	regs.w.si = pageswapargoff_phys + 64;
	intx86(EMS_INT, &regs, &regs);

	/*
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		I_Error("Call 0x5000 failed with value %i!\n", errorreg);
	}
	*/
	taskswitchcount ++;
	currenttask = TASK_PHYSICS;
}
 

void Z_QuickmapDemo() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_demo;
	regs.w.si = pageswapargoff_demo;
	intx86(EMS_INT, &regs, &regs);

	taskswitchcount++;
	currenttask = TASK_DEMO; // not sure about this

}


// sometimes needed when rendering sprites..
void Z_QuickmapRender7000to6000() {

	uint16_t seg = (uint16_t)((uint32_t)pageswapargs_rend_temp_7000_to_6000 >> 16);
	uint16_t off = (uint16_t)(((uint32_t)pageswapargs_rend_temp_7000_to_6000) & 0xffff);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = seg;
	regs.w.si = off;
	intx86(EMS_INT, &regs, &regs);

	taskswitchcount++;
	currenttask = TASK_RENDER7000TO6000; // not sure about this
}

void Z_QuickmapRender() {
	regs.w.ax = 0x5000; 
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_rend;
	regs.w.si = pageswapargoff_rend;
	intx86(EMS_INT, &regs, &regs);

	// grumble... emm386 fails with 12, but not 8. its a silent failure. was very very annoying to debug
	// todo: test real ems hardware...

	regs.w.ax = 0x5000;
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_rend;
	regs.w.si = pageswapargoff_rend + 32;
	intx86(EMS_INT, &regs, &regs);
 
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_rend;
	regs.w.si = pageswapargoff_rend + 64;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;
	currenttask = TASK_RENDER;

}

// leave off 0x4000 region. Usually used in p_setup...
void Z_QuickmapRender_NoTex() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_rend;
	regs.w.si = pageswapargoff_rend;
	intx86(EMS_INT, &regs, &regs);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x08;  // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_rend;
	regs.w.si = pageswapargoff_rend + 32;
	intx86(EMS_INT, &regs, &regs);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_rend;
	regs.w.si = pageswapargoff_rend + 64;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;
	currenttask = TASK_RENDER;

}



// sometimes needed when rendering sprites..
void Z_QuickmapRenderTexture() {
//void Z_QuickmapRenderTexture(uint8_t offset, uint8_t count) {

	//pageswapargs_textcache[2];


	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_textcache;
	regs.w.si = pageswapargoff_textcache;
	intx86(EMS_INT, &regs, &regs);
	/*

	regs.w.ax = 0x5000;
	regs.w.cx = count; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_textcache;
	regs.w.si = pageswapargoff_textcache + (offset << 2);
	intx86(EMS_INT, &regs, &regs);
	*/

	taskswitchcount++;
	currenttask = TASK_RENDER_TEXT; // not sure about this
}


// sometimes needed when rendering sprites..
void Z_QuickmapStatus() {

	regs.w.ax = 0x5000;
	regs.w.cx = 0x06; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_stat;
	regs.w.si = pageswapargoff_stat;
	intx86(EMS_INT, &regs, &regs);

	taskswitchcount++;
	currenttask = TASK_STATUS;
}

void Z_QuickmapScratch_5000() {

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_scratch_5000;
	regs.w.si = pageswapargoff_scratch_5000;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;
}
void Z_QuickmapScratch_4000() {

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_scratch_4000;
	regs.w.si = pageswapargoff_scratch_4000;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;
}

void Z_QuickmapScreen0() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_phys;
	regs.w.si = pageswapargoff_phys+16;
	intx86(EMS_INT, &regs, &regs);
}

int8_t scratchstacklevel = 0;

void Z_PushScratchFrame() {

	scratchstacklevel++;
	if (scratchstacklevel == 1){
		regs.w.ax = 0x5000;
		regs.w.cx = 0x04; // page count
		regs.w.dx = emshandle; // handle
		segregs.ds = pageswapargseg_scratch_stack;
		regs.w.si = pageswapargoff_scratch_stack;
		intx86(EMS_INT, &regs, &regs);
		taskswitchcount++;
		oldtask = currenttask;
		currenttask = TASK_SCRATCH_STACK;
	}
	else {
		I_Error("double stack");
	}
}
 

void Z_PopScratchFrame() {

	scratchstacklevel--;
	if (scratchstacklevel == 0) {
		regs.w.ax = 0x5000;
		regs.w.cx = 0x04; // page count
		regs.w.dx = emshandle; // handle
		segregs.ds = pageswapargseg_scratch_stack;
		regs.w.si = pageswapargoff_scratch_stack + 16;
		intx86(EMS_INT, &regs, &regs);

		taskswitchcount++;
		currenttask = oldtask;
		
		pageswapargs_scratch_5000[0] = FIRST_SCRATCH_LOGICAL_PAGE;
		pageswapargs_scratch_5000[2] = FIRST_SCRATCH_LOGICAL_PAGE + 1;
		pageswapargs_scratch_5000[4] = FIRST_SCRATCH_LOGICAL_PAGE + 2;
		pageswapargs_scratch_5000[6] = FIRST_SCRATCH_LOGICAL_PAGE + 3;

	}
	else {
		I_Error("didnt clear - double stack");
	}
}

void Z_QuickMapFlatPage(int16_t page) {

	pageswapargs_flat[0] = page;

	// only use 3 pages? or what? dont want to clobber zlight..

	regs.w.ax = 0x5000;
	regs.w.cx = 0x01; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_flat;
	regs.w.si = pageswapargoff_flat;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;
}


void Z_QuickMapTextureInfoPage() {

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_textinfo;
	regs.w.si = pageswapargoff_textinfo;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;
}

void Z_RemapScratchFrame(uint8_t startpage) {
	pageswapargs_scratch_5000[0] = startpage;
	pageswapargs_scratch_5000[2] = startpage+1;
	pageswapargs_scratch_5000[4] = startpage+2;
	pageswapargs_scratch_5000[6] = startpage+3;

	regs.w.ax = 0x5000;
	regs.w.cx = 0x04; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_scratch_5000;
	regs.w.si = pageswapargoff_scratch_5000;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;
}

void Z_QuickmapPalette() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x05; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_palette;
	regs.w.si = pageswapargoff_palette;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;

	currenttask = TASK_PALETTE;
}
void Z_QuickmapMenu() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_menu;
	regs.w.si  = pageswapargoff_menu;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;

	currenttask = TASK_MENU;
}

void Z_QuickmapWipe() {
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_wipe;
	regs.w.si = pageswapargoff_wipe;
	intx86(EMS_INT, &regs, &regs);

	regs.w.ax = 0x5000;
	regs.w.cx = 0x05; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg_wipe;
	regs.w.si = pageswapargoff_wipe + 32;
	intx86(EMS_INT, &regs, &regs);
	taskswitchcount++;

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

/*
		case Z_QuickmapRender7000to6000:
			TASK_RENDER7000TO6000(); // technically probably buggy but probably unused
			break;

			*/
		default:
			I_Error("bad tasknum %hhi", tasknum);
	}
}
