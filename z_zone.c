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
#include "memory.h"



// 8 MB worth. 
#define MAX_PAGE_FRAMES 512
 


// ugly... but it does work. I don't think we can ever make use of more than 2 so no need to listify
//uint16_t STATIC_CONVENTIONAL_BLOCK_SIZE = 0;

//uint16_t remainingconventional = 0;
//uint16_t conventional1head = 	  0;






// todo turn these into dynamic allocations
  


int16_t emshandle;
extern union REGS regs;
extern struct SREGS segregs;


//byte __far*			pageFrameArea;

// count allocations etc, can be used for benchmarking purposes.

 

 

 

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



//#define pageswapargs_scratch5000_offset pageswapargs_textinfo_offset + num_textinfo_params



int16_t pageswapargs[total_pages] = {
	-1,	PAGE_4000_OFFSET, -1,	PAGE_4400_OFFSET, -1,	PAGE_4800_OFFSET, -1,	PAGE_4C00_OFFSET,
	-1,	PAGE_8000_OFFSET, -1,	PAGE_8400_OFFSET, -1,	PAGE_8800_OFFSET, -1,	PAGE_8C00_OFFSET,
	-1,	PAGE_7000_OFFSET, -1,	PAGE_7400_OFFSET, -1,	PAGE_7800_OFFSET, -1,	PAGE_7C00_OFFSET,
	-1, PAGE_6000_OFFSET, -1,	PAGE_6400_OFFSET, 13,	PAGE_6800_OFFSET, -1,	PAGE_6C00_OFFSET,
	-1, PAGE_5000_OFFSET, -1,	PAGE_5400_OFFSET, -1,	PAGE_5800_OFFSET, -1,	PAGE_5C00_OFFSET, 
	15, PAGE_9000_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE,	 PAGE_9400_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 1, PAGE_9800_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 2, PAGE_9C00_OFFSET,

 

	// render
	FIRST_TEXTURE_LOGICAL_PAGE + 0,	PAGE_9000_OFFSET,
	FIRST_TEXTURE_LOGICAL_PAGE + 1,	PAGE_9400_OFFSET,
	FIRST_TEXTURE_LOGICAL_PAGE + 2,	PAGE_9800_OFFSET,
	FIRST_TEXTURE_LOGICAL_PAGE + 3,	PAGE_9C00_OFFSET,  // texture cache area

	4,	PAGE_8000_OFFSET, 5,	PAGE_8400_OFFSET, 6,	PAGE_8800_OFFSET, EMS_VISPLANE_EXTRA_PAGE,	PAGE_8C00_OFFSET,
	7,	PAGE_7000_OFFSET, 8,	PAGE_7400_OFFSET, 9,	PAGE_7800_OFFSET, 10,	PAGE_7C00_OFFSET,
	11, PAGE_6000_OFFSET, 12,	PAGE_6400_OFFSET, 13,	PAGE_6800_OFFSET, -1,	PAGE_6C00_OFFSET,  // shared 6400 6800 with physics
	-1, PAGE_5000_OFFSET, -1,	PAGE_5400_OFFSET, -1,	PAGE_5800_OFFSET, 14,	PAGE_5C00_OFFSET,  // same as physics as its unused for physics..
	0,	PAGE_4000_OFFSET, 1,	PAGE_4400_OFFSET, 2,	PAGE_4800_OFFSET, 3,	PAGE_4C00_OFFSET,
	0,	PAGE_9000_OFFSET, 1,	PAGE_9400_OFFSET, 2,	PAGE_9800_OFFSET, 3,	PAGE_9C00_OFFSET,

	
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

 
// we use 0x5000 as a  'scratch' page frame for certain things
// scratch 5000
	FIRST_SCRATCH_LOGICAL_PAGE + 0, PAGE_5000_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 1, PAGE_5400_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 2, PAGE_5800_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 3, PAGE_5C00_OFFSET,

// but sometimes we need that in the 0x8000 segment..
// scratch 8000
	FIRST_SCRATCH_LOGICAL_PAGE + 0, PAGE_8000_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 1, PAGE_8400_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 2, PAGE_8800_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 3, PAGE_8C00_OFFSET,
		// and sometimes we need that in the 0x7000 segment..
	// scratch 7000
	FIRST_SCRATCH_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	FIRST_SCRATCH_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,

	// puts sky_texture in the right place, adjacent to flat cache for planes
	-1, PAGE_9000_OFFSET,
	-1, PAGE_9400_OFFSET,
	-1, PAGE_9800_OFFSET,
	
	PALETTE_LOGICAL_PAGE,       PAGE_6C00_OFFSET,      // SPAN CODE SHOVED IN HERE. used to be mobjposlist but thats unused during planes
														
	//PHYSICS_RENDER_6800_PAGE,     PAGE_6800_OFFSET,      // remap colormaps to be before drawspan code
														


	// flat cache
	FIRST_FLAT_CACHE_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	FIRST_FLAT_CACHE_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	FIRST_FLAT_CACHE_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	FIRST_FLAT_CACHE_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,

	// flat cache undo   NOTE: we just call it with seven params to set everything up for sprites
	RENDER_7800_PAGE, PAGE_7800_OFFSET,
	RENDER_7C00_PAGE, PAGE_7C00_OFFSET,
	EXTRA_MASKED_DATA_PAGE, PAGE_8800_OFFSET,
	PHYSICS_RENDER_6800_PAGE, PAGE_8C00_OFFSET, // put colormaps where vissprites used to be?


	// sprite cache
	FIRST_SPRITE_CACHE_LOGICAL_PAGE + 0, PAGE_6800_OFFSET,
	FIRST_SPRITE_CACHE_LOGICAL_PAGE + 1, PAGE_6C00_OFFSET,
	FIRST_SPRITE_CACHE_LOGICAL_PAGE + 2, PAGE_7000_OFFSET,
	FIRST_SPRITE_CACHE_LOGICAL_PAGE + 3, PAGE_7400_OFFSET,
	// palette
	SCREEN0_LOGICAL_PAGE, PAGE_8000_OFFSET,
	SCREEN0_LOGICAL_PAGE, PAGE_8400_OFFSET,
	SCREEN0_LOGICAL_PAGE, PAGE_8800_OFFSET,
	SCREEN0_LOGICAL_PAGE, PAGE_8C00_OFFSET,
	PALETTE_LOGICAL_PAGE, PAGE_9000_OFFSET,

 
// menu 
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,
	STRINGS_LOGICAL_PAGE ,	PAGE_6000_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 4, PAGE_6400_OFFSET,
	-1, PAGE_6800_OFFSET,
	FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 5, PAGE_6C00_OFFSET,

// intermission 
	SCREEN1_LOGICAL_PAGE + 0, PAGE_9000_OFFSET,
	SCREEN1_LOGICAL_PAGE + 1, PAGE_9400_OFFSET,
	SCREEN1_LOGICAL_PAGE + 2, PAGE_9800_OFFSET,
	SCREEN1_LOGICAL_PAGE + 3, PAGE_9C00_OFFSET,
	//SCREEN1_LOGICAL_PAGE_4,   PAGE_9C00_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 4, PAGE_6000_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 5, PAGE_6400_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 6, PAGE_6800_OFFSET,
	FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 7, PAGE_6C00_OFFSET,
// wipe/intermission, shared pages
	SCREEN0_LOGICAL_PAGE, PAGE_8000_OFFSET,
	SCREEN0_LOGICAL_PAGE, PAGE_8400_OFFSET,
	SCREEN0_LOGICAL_PAGE, PAGE_8800_OFFSET,
	SCREEN0_LOGICAL_PAGE, PAGE_8C00_OFFSET,

	SCREEN2_LOGICAL_PAGE + 0, PAGE_7000_OFFSET,
	SCREEN2_LOGICAL_PAGE + 1, PAGE_7400_OFFSET,
	SCREEN2_LOGICAL_PAGE + 2, PAGE_7800_OFFSET,
	SCREEN2_LOGICAL_PAGE + 3, PAGE_7C00_OFFSET,
	SCREEN3_LOGICAL_PAGE + 0, PAGE_6000_OFFSET,
	SCREEN3_LOGICAL_PAGE + 1, PAGE_6400_OFFSET, // shared with visplanes
	SCREEN3_LOGICAL_PAGE + 2, PAGE_6800_OFFSET, // shared with visplanes
	SCREEN3_LOGICAL_PAGE + 3, PAGE_6C00_OFFSET, // shared with visplanes
	//FIRST_WIPE_LOGICAL_PAGE, PAGE_9000_OFFSET,
	

	FIRST_LUMPINFO_LOGICAL_PAGE,	 PAGE_5400_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 1, PAGE_5800_OFFSET,
	FIRST_LUMPINFO_LOGICAL_PAGE + 2, PAGE_5C00_OFFSET,

	EMS_VISPLANE_EXTRA_PAGE, PAGE_8400_OFFSET



};

int16_t pageswapargseg;
int16_t pageswapargoff;

uint8_t current5000RemappedScratchPage = 0;

int8_t current5000State = PAGE_5000_UNMAPPED;
int8_t last5000State = PAGE_5000_UNMAPPED;
int8_t current9000State = PAGE_9000_UNMAPPED;
int8_t last9000State = PAGE_9000_UNMAPPED;


#ifdef DETAILED_BENCH_STATS
int32_t taskswitchcount = 0;
int32_t texturepageswitchcount = 0;
int32_t patchpageswitchcount = 0;
int32_t compositepageswitchcount = 0;
int32_t spritepageswitchcount = 0;
int16_t benchtexturetype = 0;
int32_t flatpageswitchcount = 0;
int32_t scratchpageswitchcount = 0;
int32_t lumpinfo5000switchcount = 0;
int32_t lumpinfo9000switchcount = 0;
int16_t spritecacheevictcount = 0;
int16_t flatcacheevictcount = 0;
int16_t patchcacheevictcount = 0;
int16_t compositecacheevictcount = 0;
int32_t visplaneswitchcount = 0;

#endif

int16_t currenttask = -1;
int16_t oldtask = -1;

void __near Z_QuickMap(int16_t offset, int8_t count){
	
	int8_t min;
	offset += pageswapargoff;
	// test if some of these fields can be pulled out
	while (count > 0){
		min = count > 8 ? 8 : count; // note: emm386 only supports up to 8 args at a time. Might other EMS drivers work with more at a time?
		regs.w.ax = 0x5000;  
		regs.w.cx = min; // page count
		regs.w.dx = emshandle; // handle
		//This is a near var. and  DS should be near by default.
		//segregs.ds = pageswapargseg;
		regs.w.si = offset;
		intx86(EMS_INT, &regs, &regs);

		count -= 8;
		offset+= 32;
	}


}

void __far Z_QuickMapPhysics() {
	//int16_t errorreg;

	Z_QuickMap(pageswapargs_phys_offset_size, 24);


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
	current5000State = PAGE_5000_COLUMN_OFFSETS;
	current9000State = PAGE_9000_LUMPINFO_PHYSICS;

}
 /*
// leave off text and do 4000 in 9000 region. Used in p_setup...
void __far Z Z_QuickMapPhysics_4000To9000() {
	
	Z_QuickMap(pageswapargs_phys_offset_size+8, 23);
 
#ifdef DETAILED_BENCH_STATS
	taskswitchcount ++;
#endif
	currenttask = TASK_PHYSICS;
	current5000State = PAGE_5000_COLUMN_OFFSETS;

}
*/

void __far Z_QuickMapDemo() {
	Z_QuickMap(pageswapargs_demo_offset_size, 4);


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_DEMO; // not sure about this
	current5000State = PAGE_5000_DEMOBUFFER;

}


void __far  Z_QuickMapRender7000() {


	Z_QuickMap(pageswapargs_rend_offset_size + 32, 4);


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

}

void __far  Z_QuickMapRender() {
	
	
	Z_QuickMap(pageswapargs_rend_offset_size, 24);



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_RENDER;


	current5000State = PAGE_5000_COLUMN_OFFSETS;
	current9000State = PAGE_9000_TEXTURE;
}

// leave off text and do 4000 in 9000 region. Used in p_setup...
void __far Z_QuickMapRender_4000To9000() {

	//todo

	Z_QuickMap(pageswapargs_rend_offset_size+16, 16);
	Z_QuickMap(pageswapargs_rend_offset_size+96, 4);



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_RENDER;

	current5000State = PAGE_5000_COLUMN_OFFSETS;
	current9000State = PAGE_9000_RENDER;

}


void __far Z_QuickMapRender4000() {

	Z_QuickMap(pageswapargs_rend_offset_size+80, 4);

	

}

void __far Z_QuickMapRender9000() {
	Z_QuickMap(pageswapargs_rend_offset_size+96, 4);
	current9000State = PAGE_9000_RENDER;

}


// sometimes needed when rendering sprites..
void __near Z_QuickMapRenderTexture() {
//void Z_QuickMapRenderTexture(uint8_t offset, uint8_t count) {

	//pageswapargs_textcache[2];
	
	
	Z_QuickMap(pageswapargs_rend_offset_size, 4);





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
	current9000State = PAGE_9000_TEXTURE;
}


// sometimes needed when rendering sprites..
void __far Z_QuickMapStatus() {


	Z_QuickMap(pageswapargs_stat_offset_size, 6);



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_STATUS;
}

void __far Z_QuickMapScratch_5000() {

	Z_QuickMap(pageswapargs_scratch5000_offset_size, 4);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	scratchpageswitchcount++;
#endif

	current5000State = PAGE_5000_SCRATCH;

}
void __far Z_QuickMapScratch_8000() {

	Z_QuickMap(pageswapargs_scratch8000_offset_size, 4);
	

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		scratchpageswitchcount++;

	#endif
	
}

void __far Z_QuickMapScratch_7000() {

	Z_QuickMap(pageswapargs_scratch7000_offset_size, 4);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	scratchpageswitchcount++;

#endif
}

void __far Z_QuickMapScreen0() {
	Z_QuickMap(pageswapargs_screen0_offset_size, 4);
}

void __far Z_QuickMapRenderPlanes(){

	Z_QuickMap(pageswapargs_renderplane_offset_size, 8);

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		flatpageswitchcount++;
	#endif

	current9000State = PAGE_9000_RENDER_PLANE;

}


void __far Z_QuickMapRenderPlanesBack(){

	Z_QuickMap(pageswapargs_renderplane_offset_size, 3);

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		flatpageswitchcount++;
	#endif
	current9000State = PAGE_9000_RENDER_PLANE;

}


void __far Z_QuickMapFlatPage(int16_t page, int16_t offset) {
	// offset 4 means reset defaults/current values.
	if (offset != 4) {
		pageswapargs[pageswapargs_flatcache_offset + 2 * offset] = page;
	}

	Z_QuickMap(pageswapargs_flatcache_offset_size, 4);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	flatpageswitchcount++;

#endif
}

void __far Z_QuickMapUndoFlatCache() {
	// also puts 9000 page back from skytexture
	Z_QuickMap(pageswapargs_rend_offset_size, 4);
	
	// this runs 4 over into z_quickmapsprite page
	Z_QuickMap(pageswapargs_flatcache_undo_offset_size, 8);


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	flatpageswitchcount++;

#endif
	currenttask = TASK_RENDER_TEXT; 
	current9000State = PAGE_9000_TEXTURE;
}

void __far Z_QuickMapSpritePage() {

	Z_QuickMap(pageswapargs_spritecache_offset_size, 4);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	spritepageswitchcount++;

#endif

}
 

 

void __far Z_QuickMapColumnOffsets5000() {

	Z_QuickMap(pageswapargs_rend_offset_size + 64, 4);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	current5000State = PAGE_5000_COLUMN_OFFSETS;
}

void __far Z_QuickMapScreen1(){
	Z_QuickMap(pageswapargs_intermission_offset_size, 4);

	current9000State = PAGE_9000_SCREEN1;
}

void __far Z_QuickMapLumpInfo() {
	
	switch (current9000State) {

		case PAGE_9000_UNMAPPED:
			// use conventional memory until set up...
			return;
	 
		case PAGE_9000_TEXTURE:
		case PAGE_9000_RENDER:
		case PAGE_9000_SCREEN1:
		
			Z_QuickMap(pageswapargs_phys_offset_size+80, 4);
	#ifdef DETAILED_BENCH_STATS
			taskswitchcount++;
			lumpinfo9000switchcount++;
	#endif
		
			last9000State = current9000State;
			current9000State = PAGE_9000_LUMPINFO_PHYSICS;
 
			return;
		case PAGE_9000_RENDER_PLANE:
			Z_QuickMap(pageswapargs_phys_offset_size+80, 4);
			#ifdef DETAILED_BENCH_STATS
					taskswitchcount++;
					lumpinfo9000switchcount++;
			#endif
		
			last9000State = current9000State;
			current9000State = PAGE_9000_LUMPINFO_PHYSICS;
			return;

		case PAGE_9000_LUMPINFO_PHYSICS:
			last9000State = PAGE_9000_LUMPINFO_PHYSICS;
			return;
			
		#ifdef CHECK_FOR_ERRORS
		default:
			I_Error("76 %i", current9000State);
		#endif

	}
}

void __far Z_UnmapLumpInfo() {


	switch (last9000State) {
		case PAGE_9000_TEXTURE:
			Z_QuickMapRenderTexture();
			break;
		case PAGE_9000_RENDER:
			Z_QuickMapRender9000();
			break;
		case PAGE_9000_RENDER_PLANE:
			Z_QuickMapRenderPlanesBack();
			break;
		case PAGE_9000_SCREEN1:
			Z_QuickMapScreen1();
			break;
		default:
			break;
	}
	// doesn't really need cleanup - this isnt dual-called

}


void __far Z_QuickMapLumpInfo5000() {
	switch (current5000State) {

		case PAGE_5000_SCRATCH:
		case PAGE_5000_COLUMN_OFFSETS:
		case PAGE_5000_UNMAPPED:
		case PAGE_5000_DEMOBUFFER:

			Z_QuickMap(pageswapargs_lumpinfo_5400_offset_size, 3);
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
		#ifdef CHECK_FOR_ERRORS
		default:
				I_Error("77 %i", current5000State);
		#endif

	}
}

void __far Z_UnmapLumpInfo5000() {

	switch (last5000State) {
		case PAGE_5000_SCRATCH:
			Z_QuickMapScratch_5000();
			break;
		case PAGE_5000_COLUMN_OFFSETS:
			Z_QuickMapColumnOffsets5000();
			break;
		case PAGE_5000_DEMOBUFFER:
			Z_QuickMapDemo();
			break;
		case PAGE_5000_UNMAPPED:
		case PAGE_5000_LUMPINFO:
			default:
				break;
	}
	// doesn't really need cleanup - this isnt dual-called

}

void __far Z_QuickMapPalette() {

	Z_QuickMap(pageswapargs_palette_offset_size, 5);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_PALETTE;
}
void __far Z_QuickMapMenu() {
	Z_QuickMap(pageswapargs_menu_offset_size, 8);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_MENU;
}



void __far Z_QuickMapIntermission() {
	Z_QuickMap(pageswapargs_intermission_offset_size, 16);
 
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_INTERMISSION;
	current9000State = PAGE_9000_SCREEN1;
}

void __far Z_QuickMapWipe() {
	Z_QuickMap(pageswapargs_wipe_offset_size, 12);
	
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_WIPE;
}

void __far Z_QuickMapByTaskNum(int8_t tasknum) {
	switch (tasknum) {
		case TASK_PHYSICS:
			Z_QuickMapPhysics();
			break;
		case TASK_RENDER:
			Z_QuickMapRender();
			break;
		case TASK_STATUS:
			Z_QuickMapStatus();
			break;
		case TASK_RENDER_TEXT:
			Z_QuickMapRender();
			Z_QuickMapRenderTexture(); // should be okay this way
			break;
		case TASK_MENU:
			Z_QuickMapMenu();
			break;
		case TASK_INTERMISSION:
			Z_QuickMapIntermission();
			break;
		#ifdef CHECK_FOR_ERRORS
		default:
			I_Error("78 %hhi", tasknum); // bad tasknum
		#endif
	}
}

extern int8_t visplanedirty;
extern int8_t skytextureloaded;

// virtual to physical page mapping. 
// 0 means unmapped. 1 means 8400, 2 means 8800, 3 means 8C00;
int8_t active_visplanes[5] = {1, 2, 3, 0, 0};

void __far Z_QuickMapVisplanePage(int8_t virtualpage, int8_t physicalpage){

	// physicalpage 0 = PAGE_8400_OFFSET
	// physicalpage 1 = PAGE_8800_OFFSET
	// physicalpage 2 = PAGE_8C00_OFFSET

	// virtual page 0 = original conventional at page 8400
	// virtual page 1 = original conventional at page 8800
	// virtual page 2 = original conventional at page 8C00 (extra ems page 0)
	// virtual page 3 = extra ems page 1
	// virtual page 4 = extra ems page 2

	int16_t usedpageindex = pagenum9000 + PAGE_8400_OFFSET + physicalpage;
	int16_t usedpagevalue;
	int8_t i;
	if (virtualpage < 2){
		usedpagevalue = FIRST_VISPLANE_PAGE + virtualpage;
	} else {
		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
	}


	pageswapargs[pageswapargs_visplanepage_offset+1] = usedpageindex;
	pageswapargs[pageswapargs_visplanepage_offset] = usedpagevalue;
	physicalpage++;
	
	// erase old virtual page map
	// page 1 is aways 1 and never gets changed, never need to bother erasing it
	for (i = 4; i > 0; i --){
		if (active_visplanes[i] == physicalpage){
			active_visplanes[i] = 0;
			break;
		}
	}
	// set new virtual page map
	active_visplanes[virtualpage] = physicalpage;
	
	
	Z_QuickMap(pageswapargs_visplanepage_offset_size, 1);
	
	visplanedirty = true;
#ifdef DETAILED_BENCH_STATS
	visplaneswitchcount++;

#endif


}

void __far Z_QuickMapVisplaneRevert(){
/*
	//I_Error("C");
	Z_QuickMap(pageswapargs_visplane_base_page_offset_size, 3);
	//active_visplanes[0] = 1;  // never changes 
	// todo make it two 16 bit writes?
	active_visplanes[1] = 2;
	active_visplanes[2] = 3;
	active_visplanes[3] = 0;
	active_visplanes[4] = 0;
	*/
	//Z_QuickMapVisplanePage(0, 0);
	Z_QuickMapVisplanePage(1, 1);
	Z_QuickMapVisplanePage(2, 2);
	

	visplanedirty = false;

#ifdef DETAILED_BENCH_STATS
	visplaneswitchcount++;
#endif

}
// todo do we need to do the page frame?
int8_t ems_backfill_page_order[24] = { 0, 1, 2, 3, -4, -3, -2, -1, -8, -7, -6, -5, -12, -11, -10, -9, -16, -15, -14, -13, -20, -19, -18, -17 };

void __far Z_QuickMapUnmapAll() {
	int16_t i;
	for (i = 0; i < 24; i++) {
		pageswapargs[i * 2 + 0] = -1;
		pageswapargs[i * 2 + 1] = pagenum9000 + ems_backfill_page_order[i];
	}

	Z_QuickMap(0, 24);


}


/*


void DUMP_4000_TO_FILE() {
	int16_t segment = 0x4000;
	FILE*fp = fopen("DUMP4000.BIN", "wb");
	while (segment < 0x5000) {
		byte __far * dest = MK_FP(segment, 0);
		FAR_fwrite(dest, 32768, 1, fp);
		segment += 0x0800;
	}
	fclose(fp);
	I_Error("\ndumped");
}


void DUMP_MEMORY_TO_FILE() {
	uint16_t segment = 0x4000;
#ifdef __COMPILER_WATCOM
	FILE*fp = fopen("MEM_DUMP.BIN", "wb");
#else
	FILE*fp = fopen("MEMDUMP2.BIN", "wb");
#endif
	while (segment < 0xA000) {
		byte __far * dest = MK_FP(segment, 0);
		//DEBUG_PRINT("\nloop %u", segment);
		FAR_fwrite(dest, 32768, 1, fp);
		segment += 0x0800;
	}
	fclose(fp);
	I_Error("\ndumped");
}
*/
