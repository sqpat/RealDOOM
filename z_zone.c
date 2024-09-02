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
#include <conio.h>

#include <stdlib.h>
#include "m_memory.h"
#include "m_near.h"



// 8 MB worth. 
#define MAX_PAGE_FRAMES 512
 


// ugly... but it does work. I don't think we can ever make use of more than 2 so no need to listify
//uint16_t STATIC_CONVENTIONAL_BLOCK_SIZE = 0;

//uint16_t remainingconventional = 0;
//uint16_t conventional1head = 	  0;




// todo turn these into dynamic allocations
  


extern union REGS regs;
extern struct SREGS segregs;


//byte __far*			pageFrameArea;

// count allocations etc, can be used for benchmarking purposes.

 

 

 

// EMS 4.0 functionality

// page for 0x9000 block where we will store thinkers in physics code, then visplanes etc in render code

//these offsets at runtime must have pagenum9000 added to them




//#define pageswapargs_scratch5000_offset pageswapargs_textinfo_offset + num_textinfo_params



#if defined(__SCAMP_BUILD) || defined(__SCAT_BUILD)

// these are prepared for calls to outsw with autoincrementing ems register on

uint16_t pageswapargs[total_pages] = {

	_NPR(PAGE_4000_OFFSET),	 _NPR(PAGE_4400_OFFSET),	 _NPR(PAGE_4800_OFFSET),	 _NPR(PAGE_4C00_OFFSET),	
	_NPR(PAGE_5000_OFFSET),  _NPR(PAGE_5400_OFFSET),	 _NPR(PAGE_5800_OFFSET),	 _NPR(PAGE_5C00_OFFSET),	 
	_NPR(PAGE_6000_OFFSET),  _NPR(PAGE_6400_OFFSET),	 _EPR(13),	                 _NPR(PAGE_6C00_OFFSET),	
	_NPR(PAGE_7000_OFFSET),	 _NPR(PAGE_7400_OFFSET),	 _NPR(PAGE_7800_OFFSET),	 _NPR(PAGE_7C00_OFFSET),	
	_NPR(PAGE_8000_OFFSET),	 _NPR(PAGE_8400_OFFSET),	 _NPR(PAGE_8800_OFFSET),	 _NPR(PAGE_8C00_OFFSET),	
	_EPR(15), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE)    , 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), 

	// render
	_EPR(0),				 _EPR(1),					 _EPR(2),					 _EPR(3),						
	_NPR(PAGE_5000_OFFSET),  _NPR(PAGE_5400_OFFSET),	 _NPR(PAGE_5800_OFFSET),	 _EPR(14),						  // same as physics as its unused for physics..
	_EPR(11), 				 _EPR(12),					 _EPR(13),					 _NPR(PAGE_6C00_OFFSET),		  // shared 6400 6800 with physics
	_EPR(7),				 _EPR(8),					 _EPR(9),					 _EPR(10),						
	_EPR(4),				 _EPR(5),					 _EPR(6),					 _EPR(EMS_VISPLANE_EXTRA_PAGE),
	_EPR(FIRST_TEXTURE_LOGICAL_PAGE + 0),	 _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 1),	 _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 2),	 _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 3),	  // texture cache area
	_EPR(0),				 _EPR(1),					 _EPR(2),					 _EPR(3),						

	
	// status/hud
	_NPR(PAGE_9C00_OFFSET), 		  //SCREEN4_LOGICAL_PAGE
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 0), 
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 1), 
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 2), 
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 3), 
	_NPR(PAGE_6000_OFFSET), 		  // STRINGS_LOGICAL_PAGE
	// demo
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 0), 
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 1), 
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 2), 
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 3), 

 
// we use 0x5000 as a  'scratch' page frame for certain things
// scratch 5000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), 

// but sometimes we need that in the 0x8000 segment..
// scratch 8000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), 
		// and sometimes we need that in the 0x7000 segment..
	// scratch 7000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), 

	// puts sky_texture in the right place, adjacent to flat cache for planes
	//  RenderPlane
	_NPR(PAGE_9000_OFFSET), 	
	_NPR(PAGE_9400_OFFSET), 	
	_NPR(PAGE_9800_OFFSET), 	
	
	_EPR(PALETTE_LOGICAL_PAGE),       // SPAN CODE SHOVED IN HERE. used to be mobjposlist but thats unused during planes
														
	//PHYSICS_RENDER_6800_PAGE,           // remap colormaps to be before drawspan code
														


	// flat cache
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 0), 
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 1), 
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 2), 
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 3), 

	// flat cache undo   NOTE: we just call it with seven params to set everything up for sprites
	_EPR(RENDER_7800_PAGE), 
	_EPR(RENDER_7C00_PAGE), 
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE), 
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE+1), 
	_EPR(PHYSICS_RENDER_6800_PAGE),  // put colormaps where vissprites used to be?


	// sprite cache
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 3), 
	// palette
	_NPR(PAGE_8000_OFFSET), 
	_NPR(PAGE_8400_OFFSET), 
	_NPR(PAGE_8800_OFFSET), 
	_NPR(PAGE_8C00_OFFSET),  // SCREEN0_LOGICAL_PAGE
	_EPR(PALETTE_LOGICAL_PAGE), 

 
// menu 
	_NPR(PAGE_6000_OFFSET) 				  	  ,  // STRINGS_LOGICAL_PAGE
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 4), 
	_NPR(PAGE_6800_OFFSET)  				  , 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 5), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 0), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 1), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 2), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 3), 

// intermission 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 4), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 5), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 6), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 7), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 0), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 1), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 2), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 3), 
// wipe/intermission, shared pages
	_NPR(PAGE_8000_OFFSET),  // SCREEN0_LOGICAL_PAGE
	_NPR(PAGE_8400_OFFSET), 
	_NPR(PAGE_8800_OFFSET), 
	_NPR(PAGE_8C00_OFFSET), 
	_EPR(SCREEN1_LOGICAL_PAGE + 0), 
	_EPR(SCREEN1_LOGICAL_PAGE + 1), 
	_EPR(SCREEN1_LOGICAL_PAGE + 2), 
	_EPR(SCREEN1_LOGICAL_PAGE + 3), 

	_EPR(SCREEN2_LOGICAL_PAGE + 0), 
	_EPR(SCREEN2_LOGICAL_PAGE + 1), 
	_EPR(SCREEN2_LOGICAL_PAGE + 2), 
	_EPR(SCREEN2_LOGICAL_PAGE + 3), 
	_EPR(SCREEN3_LOGICAL_PAGE + 0), 
	_EPR(SCREEN3_LOGICAL_PAGE + 1),  // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 2),  // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 3),  // shared with visplanes

	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE	), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), 

	_EPR(EMS_VISPLANE_EXTRA_PAGE)

};
#else

int16_t emshandle;
int16_t pagenum9000;

uint16_t pageswapargs[total_pages] = {
	_NPR(PAGE_4000_OFFSET),	PAGE_4000_OFFSET, _NPR(PAGE_4400_OFFSET),	PAGE_4400_OFFSET, _NPR(PAGE_4800_OFFSET),	PAGE_4800_OFFSET, _NPR(PAGE_4C00_OFFSET),	PAGE_4C00_OFFSET,
	_NPR(PAGE_5000_OFFSET), PAGE_5000_OFFSET, _NPR(PAGE_5400_OFFSET),	PAGE_5400_OFFSET, _NPR(PAGE_5800_OFFSET),	PAGE_5800_OFFSET, _NPR(PAGE_5C00_OFFSET),	PAGE_5C00_OFFSET, 
	_NPR(PAGE_6000_OFFSET), PAGE_6000_OFFSET, _NPR(PAGE_6400_OFFSET),	PAGE_6400_OFFSET, _EPR(13),	                PAGE_6800_OFFSET, _NPR(PAGE_6C00_OFFSET),	PAGE_6C00_OFFSET,
	_NPR(PAGE_7000_OFFSET),	PAGE_7000_OFFSET, _NPR(PAGE_7400_OFFSET),	PAGE_7400_OFFSET, _NPR(PAGE_7800_OFFSET),	PAGE_7800_OFFSET, _NPR(PAGE_7C00_OFFSET),	PAGE_7C00_OFFSET,
	_NPR(PAGE_8000_OFFSET),	PAGE_8000_OFFSET, _NPR(PAGE_8400_OFFSET),	PAGE_8400_OFFSET, _NPR(PAGE_8800_OFFSET),	PAGE_8800_OFFSET, _NPR(PAGE_8C00_OFFSET),	PAGE_8C00_OFFSET,
	_EPR(15), PAGE_9000_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE)    , PAGE_9400_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), PAGE_9800_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), PAGE_9C00_OFFSET,

 

	// render
	_EPR(0),				PAGE_4000_OFFSET, _EPR(1),					PAGE_4400_OFFSET, _EPR(2),					PAGE_4800_OFFSET, _EPR(3),						PAGE_4C00_OFFSET,
	_NPR(PAGE_5000_OFFSET), PAGE_5000_OFFSET, _NPR(PAGE_5400_OFFSET),	PAGE_5400_OFFSET, _NPR(PAGE_5800_OFFSET),	PAGE_5800_OFFSET, _EPR(14),						PAGE_5C00_OFFSET,  // same as physics as its unused for physics..
	_EPR(11), 				PAGE_6000_OFFSET, _EPR(12),					PAGE_6400_OFFSET, _EPR(13),					PAGE_6800_OFFSET, _NPR(PAGE_6C00_OFFSET),		PAGE_6C00_OFFSET,  // shared 6400 6800 with physics
	_EPR(7),				PAGE_7000_OFFSET, _EPR(8),					PAGE_7400_OFFSET, _EPR(9),					PAGE_7800_OFFSET, _EPR(10),						PAGE_7C00_OFFSET,
	_EPR(4),				PAGE_8000_OFFSET, _EPR(5),					PAGE_8400_OFFSET, _EPR(6),					PAGE_8800_OFFSET, _EPR(EMS_VISPLANE_EXTRA_PAGE),PAGE_8C00_OFFSET,
	_EPR(FIRST_TEXTURE_LOGICAL_PAGE + 0),	PAGE_9000_OFFSET, _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 1),	PAGE_9400_OFFSET, _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 2),	PAGE_9800_OFFSET, _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 3),	PAGE_9C00_OFFSET,  // texture cache area

	_EPR(0),				PAGE_9000_OFFSET, _EPR(1),					PAGE_9400_OFFSET, _EPR(2),					PAGE_9800_OFFSET, _EPR(3),						PAGE_9C00_OFFSET,

	
	// status/hud
	_NPR(PAGE_9C00_OFFSET), 		 PAGE_9C00_OFFSET, //SCREEN4_LOGICAL_PAGE
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,
	_NPR(PAGE_6000_OFFSET), 		 PAGE_6000_OFFSET, // STRINGS_LOGICAL_PAGE
	// demo
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 0), PAGE_5000_OFFSET,
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 1), PAGE_5400_OFFSET,
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 2), PAGE_5800_OFFSET,
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 3), PAGE_5C00_OFFSET,

 
// we use 0x5000 as a  'scratch' page frame for certain things
// scratch 5000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), PAGE_5000_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), PAGE_5400_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), PAGE_5800_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), PAGE_5C00_OFFSET,

// but sometimes we need that in the 0x8000 segment..
// scratch 8000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), PAGE_8000_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), PAGE_8400_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), PAGE_8800_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), PAGE_8C00_OFFSET,
		// and sometimes we need that in the 0x7000 segment..
	// scratch 7000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,

	// puts sky_texture in the right place, adjacent to flat cache for planes
	//  RenderPlane
	_NPR(PAGE_9000_OFFSET), 	PAGE_9000_OFFSET,
	_NPR(PAGE_9400_OFFSET), 	PAGE_9400_OFFSET,
	_NPR(PAGE_9800_OFFSET), 	PAGE_9800_OFFSET,
	
	_EPR(PALETTE_LOGICAL_PAGE), PAGE_6C00_OFFSET,      // SPAN CODE SHOVED IN HERE. used to be mobjposlist but thats unused during planes
														
	//PHYSICS_RENDER_6800_PAGE,     PAGE_6800_OFFSET,      // remap colormaps to be before drawspan code

	// flat cache
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,

	// flat cache undo   NOTE: we just call it with seven params to set everything up for sprites
	_EPR(RENDER_7800_PAGE), PAGE_7800_OFFSET,
	_EPR(RENDER_7C00_PAGE), PAGE_7C00_OFFSET,
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE), PAGE_8400_OFFSET,
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE+1), PAGE_8800_OFFSET,
	_EPR(PHYSICS_RENDER_6800_PAGE), PAGE_8C00_OFFSET, // put colormaps where vissprites used to be?


	// sprite cache
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 0), PAGE_6800_OFFSET,
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 1), PAGE_6C00_OFFSET,
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 2), PAGE_7000_OFFSET,
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 3), PAGE_7400_OFFSET,
	// palette
	_NPR(PAGE_8000_OFFSET), PAGE_8000_OFFSET,
	_NPR(PAGE_8400_OFFSET), PAGE_8400_OFFSET,
	_NPR(PAGE_8800_OFFSET), PAGE_8800_OFFSET,
	_NPR(PAGE_8C00_OFFSET), PAGE_8C00_OFFSET, // SCREEN0_LOGICAL_PAGE
	_EPR(PALETTE_LOGICAL_PAGE), PAGE_9000_OFFSET,

 
// menu 
	_NPR(PAGE_6000_OFFSET) 				  	  , PAGE_6000_OFFSET, // STRINGS_LOGICAL_PAGE
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 4), PAGE_6400_OFFSET,
	_NPR(PAGE_6800_OFFSET)  				  , PAGE_6800_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 5), PAGE_6C00_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,

// intermission 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 4), PAGE_6000_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 5), PAGE_6400_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 6), PAGE_6800_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 7), PAGE_6C00_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,
// wipe/intermission, shared pages
	_NPR(PAGE_8000_OFFSET), PAGE_8000_OFFSET, // SCREEN0_LOGICAL_PAGE
	_NPR(PAGE_8400_OFFSET), PAGE_8400_OFFSET,
	_NPR(PAGE_8800_OFFSET), PAGE_8800_OFFSET,
	_NPR(PAGE_8C00_OFFSET), PAGE_8C00_OFFSET,
	_EPR(SCREEN1_LOGICAL_PAGE + 0), PAGE_9000_OFFSET,
	_EPR(SCREEN1_LOGICAL_PAGE + 1), PAGE_9400_OFFSET,
	_EPR(SCREEN1_LOGICAL_PAGE + 2), PAGE_9800_OFFSET,
	_EPR(SCREEN1_LOGICAL_PAGE + 3), PAGE_9C00_OFFSET,

	_EPR(SCREEN2_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(SCREEN2_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(SCREEN2_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(SCREEN2_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,
	_EPR(SCREEN3_LOGICAL_PAGE + 0), PAGE_6000_OFFSET,
	_EPR(SCREEN3_LOGICAL_PAGE + 1), PAGE_6400_OFFSET, // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 2), PAGE_6800_OFFSET, // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 3), PAGE_6C00_OFFSET, // shared with visplanes
	//FIRST_WIPE_LOGICAL_PAGE, PAGE_9000_OFFSET,
	

	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE	), PAGE_5400_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), PAGE_5800_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), PAGE_5C00_OFFSET,

	_EPR(EMS_VISPLANE_EXTRA_PAGE), 		   PAGE_8400_OFFSET,



};

#endif

  

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

#ifdef __SCAMP_BUILD

// corresponds to 2 MB worth of address lines/ems pages.
#define EMS_MEMORY_BASE   0x0080
 
#elif defined(__SCAT_BUILD)
	#define EMS_MEMORY_BASE   0x8080


#else


#define MAX_COUNT_ITER 1

void __near Z_QuickMap(int16_t offset, int8_t count){

	int8_t min;
/*
	int8_t count2 = count;
	int16_t __near *offset2 = (int16_t*)(offset+pageswapargoff);
	FILE* fp = fopen ("mapa.txt", "a");
	int16_t lastax = 0x7000;
	while (count2){
		int16_t bx = offset2[0];
		int16_t ax = offset2[1];
		if (lastax != 0x7000){
			if (ax != lastax + 1){
				fprintf(fp, "wasn't increment! %i %i %x %i %i\n", ax, lastax, offset, count2, count);
				fclose(fp);
				I_Error("wasn't increment! %i %i %x %i %i\n",     ax, lastax, offset, count2, count);
			}
		}
		lastax = ax;

		fprintf(fp, "%x %x %i %x\n", bx, ax, count2, offset2);
		count2--;
		offset2++;
		offset2++;
	}
	fclose(fp);
	*/
	offset += pageswapargoff;
	// test if some of these fields can be pulled out
	while (count > 0){

 

		min = count > MAX_COUNT_ITER ? MAX_COUNT_ITER : count; // note: emm386 only supports up to 8 args at a time. Might other EMS drivers work with more at a time?
		regs.w.ax = 0x5000;  
		regs.w.cx = min; // page count
		regs.w.dx = emshandle; // handle
		//This is a near var. and  DS should be near by default.
		//segregs.ds = pageswapargseg;
		regs.w.si = offset;
		intx86(EMS_INT, &regs, &regs);

		count -= MAX_COUNT_ITER;
		offset+= MAX_COUNT_ITER*4;
	}

}
#endif

void __far Z_QuickMapPhysics() {
	//int16_t errorreg;

	Z_QuickMap24AI(pageswapargs_phys_offset_size);

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
	Z_QuickMap4AI(pageswapargs_demo_offset_size, INDEXED_PAGE_5000_OFFSET);


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_DEMO; // not sure about this
	current5000State = PAGE_5000_DEMOBUFFER;

}


void __far  Z_QuickMapRender7000() {


	Z_QuickMap4AI((pageswapargs_rend_offset_size + 12*AMTSIO16), INDEXED_PAGE_7000_OFFSET);


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

}

void __far  Z_QuickMapRender() {
	
	
	Z_QuickMap24AI(pageswapargs_rend_offset_size);



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

	Z_QuickMap16AI((pageswapargs_rend_offset_size+4*AMTSIO16), INDEXED_PAGE_5000_OFFSET); // 5000 to 8000
	Z_QuickMap4AI((pageswapargs_rend_offset_size+24*AMTSIO16), INDEXED_PAGE_9000_OFFSET);  // 4000 as 9000



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_RENDER;

	current5000State = PAGE_5000_COLUMN_OFFSETS;
	current9000State = PAGE_9000_RENDER;

}


void __far Z_QuickMapRender4000() {

	Z_QuickMap4AI(pageswapargs_rend_offset_size, INDEXED_PAGE_4000_OFFSET);

	

}

void __far Z_QuickMapRender9000() {
	Z_QuickMap4AI((pageswapargs_rend_offset_size+24*AMTSIO16), INDEXED_PAGE_9000_OFFSET);
	current9000State = PAGE_9000_RENDER;

}


// sometimes needed when rendering sprites..
void __near Z_QuickMapRenderTexture() {
//void Z_QuickMapRenderTexture(uint8_t offset, uint8_t count) {

	//pageswapargs_textcache[2];
	
	
	Z_QuickMap4AI((pageswapargs_rend_offset_size+20*AMTSIO16), INDEXED_PAGE_9000_OFFSET);





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

	//Z_QuickMap6(pageswapargs_stat_offset_size);

	Z_QuickMap1AI(pageswapargs_stat_offset_size,    INDEXED_PAGE_9C00_OFFSET);
	Z_QuickMap4AI(pageswapargs_stat_offset_size+1*AMTSIO16,  INDEXED_PAGE_7000_OFFSET);
	Z_QuickMap1AI(pageswapargs_stat_offset_size+5*AMTSIO16, INDEXED_PAGE_6000_OFFSET);



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_STATUS;
}

void __far Z_QuickMapScratch_5000() {

	Z_QuickMap4AI(pageswapargs_scratch5000_offset_size, INDEXED_PAGE_5000_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	scratchpageswitchcount++;
#endif

	current5000State = PAGE_5000_SCRATCH;

}
void __far Z_QuickMapScratch_8000() {

	Z_QuickMap4AI(pageswapargs_scratch8000_offset_size, INDEXED_PAGE_8000_OFFSET);
	

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		scratchpageswitchcount++;

	#endif
	
}

void __far Z_QuickMapScratch_7000() {

	Z_QuickMap4AI(pageswapargs_scratch7000_offset_size, INDEXED_PAGE_7000_OFFSET);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	scratchpageswitchcount++;

#endif
}

void __far Z_QuickMapScreen0() {
	Z_QuickMap4AI(pageswapargs_screen0_offset_size, INDEXED_PAGE_8000_OFFSET);
}

void __far Z_QuickMapRenderPlanes(){

	//Z_QuickMap8(pageswapargs_renderplane_offset_size);
	Z_QuickMap3AI(pageswapargs_renderplane_offset_size, INDEXED_PAGE_9000_OFFSET);
	Z_QuickMap5AI(pageswapargs_renderplane_offset_size+3*AMTSIO16, INDEXED_PAGE_6C00_OFFSET);

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		flatpageswitchcount++;
	#endif

	current9000State = PAGE_9000_RENDER_PLANE;

}


void __far Z_QuickMapRenderPlanesBack(){

	Z_QuickMap3AI(pageswapargs_renderplane_offset_size, INDEXED_PAGE_9000_OFFSET);

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		flatpageswitchcount++;
	#endif
	current9000State = PAGE_9000_RENDER_PLANE;

}


void __far Z_QuickMapFlatPage(int16_t page, int16_t offset) {
	// offset 4 means reset defaults/current values.
	if (offset != 4) {

		pageswapargs[pageswapargs_flatcache_offset + offset * PAGE_SWAP_ARG_MULT] = _EPR(page);
	}

	// todo change this to 1 with offset?
	Z_QuickMap4AI(pageswapargs_flatcache_offset_size, INDEXED_PAGE_7000_OFFSET);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	flatpageswitchcount++;

#endif
}

void __far Z_QuickMapUndoFlatCache() {
	// also puts 9000 page back from skytexture
	Z_QuickMap4AI((pageswapargs_rend_offset_size+20*AMTSIO16), INDEXED_PAGE_9000_OFFSET);
	
	// this runs 4 over into z_quickmapsprite page
	//Z_QuickMap9(pageswapargs_flatcache_undo_offset_size);

	Z_QuickMap2AI(pageswapargs_flatcache_undo_offset_size,     INDEXED_PAGE_7800_OFFSET);
	Z_QuickMap3AI(pageswapargs_flatcache_undo_offset_size+2*AMTSIO16,   INDEXED_PAGE_8400_OFFSET);
	Z_QuickMap4AI(pageswapargs_flatcache_undo_offset_size+5*AMTSIO16,  INDEXED_PAGE_6800_OFFSET);


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	flatpageswitchcount++;

#endif
	currenttask = TASK_RENDER_TEXT; 
	current9000State = PAGE_9000_TEXTURE;
}

void __far Z_QuickMapMaskedExtraData() {

	Z_QuickMap2AI(pageswapargs_maskeddata_offset_size, INDEXED_PAGE_8400_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	spritepageswitchcount++;

#endif

}

void __far Z_QuickMapSpritePage() {

	Z_QuickMap4AI(pageswapargs_spritecache_offset_size, INDEXED_PAGE_6800_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	spritepageswitchcount++;

#endif

}
 

 

void __far Z_QuickMapColumnOffsets5000() {

	Z_QuickMap4AI((pageswapargs_rend_offset_size + 4*AMTSIO16), INDEXED_PAGE_5000_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	current5000State = PAGE_5000_COLUMN_OFFSETS;
}

void __far Z_QuickMapScreen1(){
	Z_QuickMap4AI((pageswapargs_intermission_offset_size+12*AMTSIO16), INDEXED_PAGE_9000_OFFSET);

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
		
			Z_QuickMap4AI((pageswapargs_phys_offset_size+20*AMTSIO16), INDEXED_PAGE_9000_OFFSET);
	#ifdef DETAILED_BENCH_STATS
			taskswitchcount++;
			lumpinfo9000switchcount++;
	#endif
		
			last9000State = current9000State;
			current9000State = PAGE_9000_LUMPINFO_PHYSICS;
 
			return;
		case PAGE_9000_RENDER_PLANE:
			Z_QuickMap4AI((pageswapargs_phys_offset_size+20*AMTSIO16), INDEXED_PAGE_9000_OFFSET);
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

			Z_QuickMap3AI(pageswapargs_lumpinfo_5400_offset_size, INDEXED_PAGE_5400_OFFSET);
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

	Z_QuickMap5AI(pageswapargs_palette_offset_size, INDEXED_PAGE_8000_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_PALETTE;
}
void __far Z_QuickMapMenu() {
	Z_QuickMap8AI(pageswapargs_menu_offset_size, INDEXED_PAGE_6000_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_MENU;
}



void __far Z_QuickMapIntermission() {
	Z_QuickMap16AI(pageswapargs_intermission_offset_size, INDEXED_PAGE_6000_OFFSET);
 
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_INTERMISSION;
	current9000State = PAGE_9000_SCREEN1;
}

void __far Z_QuickMapWipe() {
	//Z_QuickMap12(pageswapargs_wipe_offset_size);
	Z_QuickMap4AI(pageswapargs_wipe_offset_size,    INDEXED_PAGE_9000_OFFSET);
	Z_QuickMap4AI(pageswapargs_wipe_offset_size+4*AMTSIO16, INDEXED_PAGE_7000_OFFSET);
	Z_QuickMap4AI(pageswapargs_wipe_offset_size+8*AMTSIO16, INDEXED_PAGE_6000_OFFSET);
	
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

		pageswapargs[pageswapargs_visplanepage_offset] = _EPR(usedpagevalue);
	#if defined(__SCAMP_BUILD) || defined(__SCAT_BUILD)
	#else
		pageswapargs[pageswapargs_visplanepage_offset+1] = usedpageindex;
	#endif

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
	
	
	Z_QuickMap1AI(pageswapargs_visplanepage_offset_size, usedpageindex);
	
	visplanedirty = true;
#ifdef DETAILED_BENCH_STATS
	visplaneswitchcount++;

#endif


}

void __far Z_QuickMapVisplaneRevert(){
 
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

		pageswapargs[i * PAGE_SWAP_ARG_MULT] = _NPR(i + PAGE_4000_OFFSET);
		#if defined(__SCAMP_BUILD) || defined(__SCAT_BUILD)
		#else
			pageswapargs[i * PAGE_SWAP_ARG_MULT + 1] = pagenum9000 + ems_backfill_page_order[i];
		#endif

		
	}

	Z_QuickMap24AI(0);


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
