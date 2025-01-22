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
  
 

//byte __far*			pageFrameArea;

// count allocations etc, can be used for benchmarking purposes.

 

 

 

// EMS 4.0 functionality

// page for 0x9000 block where we will store thinkers in physics code, then visplanes etc in render code

//these offsets at runtime must have pagenum9000 added to them




//#define pageswapargs_scratch5000_offset pageswapargs_textinfo_offset + num_textinfo_params


#ifdef __SCAMP_BUILD

// corresponds to 2 MB worth of address lines/ems pages.
#define EMS_MEMORY_BASE   0x0080
 
#elif defined(__SCAT_BUILD)
	#define EMS_MEMORY_BASE   0x8080
#elif defined(__HT18_BUILD)
	#define EMS_MEMORY_BASE   0x0280
#else


// note: emm386 only supports up to 8 args at a time.
// its kind of infrequent that we go more than 8 at once, and thus not a big perf hit, 
// so let's just do this for simplicity

#define MAX_COUNT_ITER 8

void __near Z_QuickMap(uint16_t __near *offset, int8_t count){

	int8_t min;

/*
	if (setval){
		if (count == 4 && offset[1] == 24 && offset[2] != 35){
			if (offset[0] < 70 || offset[2] < 70 || offset[4] < 70 || offset[6] < 70){
				I_Error("catch %i %i %i %i %i",
				
				offset[0],
				offset[2],
				offset[4],

				);
			}
		}
	}


	if (setval){
		int8_t i = 0;
		FILE* fp = fopen("pages.txt", "ab");
		fprintf(fp, "%li\t\t", gametic);

		for (i = 0; i < count; i++){
			
			
			int16_t pagenum = offset[(i*2)+0];
			int16_t pageoff = offset[(i*2)+1];
			fprintf(fp, "%i %i\t", pagenum, pageoff);
			
			//if (pagenum == FIRST_FLAT_CACHE_LOGICAL_PAGE){
			//	I_Error("paged? %i %i %i %i", i, count, offset[(i*2)+1], setval);
			//}
		}
		fprintf(fp, "\n");
		fclose(fp);
	}
	*/

	// test if some of these fields can be pulled out
	while (count > 0){

		min = count > MAX_COUNT_ITER ? MAX_COUNT_ITER : count; 
		regs.w.ax = 0x5000;  
		regs.w.cx = min; // page count
		regs.w.dx = emshandle; // handle
		//This is a near var. and  DS should be near by default.
		//segregs.ds = pageswapargseg;
		regs.w.si = (int16_t)offset;
		intx86(EMS_INT, &regs, &regs);

		count -= MAX_COUNT_ITER;
		offset+= MAX_COUNT_ITER*PAGE_SWAP_ARG_MULT;
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
	current5000State = PAGE_5000_PHYSICS;
	current9000State = PAGE_9000_LUMPINFO_PHYSICS;

}


void __far Z_QuickMapDemo() {
	Z_QuickMap4AI(pageswapargs_demo_offset_size, INDEXED_PAGE_5000_OFFSET);


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_DEMO; // not sure about this
	current5000State = PAGE_5000_DEMOBUFFER;

}


void __far  Z_QuickMapRender7000() {


	Z_QuickMap4AI(pageswapargs_rend_offset_size + 12, INDEXED_PAGE_7000_OFFSET);


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


	current5000State = PAGE_5000_RENDER;
	current9000State = PAGE_9000_RENDER;
}

// leave off text and do 4000 in 9000 region. Used in p_setup...
void __far Z_QuickMapRender_4000To9000_9000Only(){
	Z_QuickMap4AI(pageswapargs_rend_other9000_size, INDEXED_PAGE_9000_OFFSET);  // 4000 as 9000
	current9000State = PAGE_9000_RENDER_4000;

}

void __far Z_QuickMapRender_4000To9000() {

	//todo

	Z_QuickMap16AI(pageswapargs_rend_offset_size+4, INDEXED_PAGE_5000_OFFSET); // 5000 thru 8000
	Z_QuickMapRender_4000To9000_9000Only();



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_RENDER;

	current5000State = PAGE_5000_RENDER;

}

void __far Z_QuickMapRender_9000To7000() {

	// sets texturedefs into 7000 (just like they are in the masked task)
	Z_QuickMap2AI(pageswapargs_spritecache_offset_size+4,     			INDEXED_PAGE_7000_OFFSET);
}

void __far Z_QuickMapRender_9000To6000() {

	// sets texturedefs into 6000
	Z_QuickMap2AI(pageswapargs_render_to_6000_size,     			INDEXED_PAGE_6000_OFFSET);
}



void __far Z_QuickMapRender4000() {

	Z_QuickMap4AI(pageswapargs_rend_offset_size, INDEXED_PAGE_4000_OFFSET);

}

void __far Z_QuickMapRender5000() {

	Z_QuickMap4AI(pageswapargs_rend_offset_size + 4, INDEXED_PAGE_5000_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	current5000State = PAGE_5000_RENDER;
}

void __far Z_QuickMapRender9000() {
	Z_QuickMap4AI(pageswapargs_rend_9000_size, INDEXED_PAGE_9000_OFFSET);
	
	current9000State = PAGE_9000_RENDER;

}


// sometimes needed when rendering sprites..
void __near Z_QuickMapRenderTexture() {
	// todo make this 8..
	Z_QuickMap8AI(pageswapargs_rend_texture_size, INDEXED_PAGE_5000_OFFSET);


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

	current5000State = PAGE_5000_RENDER;

}


// sometimes needed when rendering sprites..
void __far Z_QuickMapStatus() {

	//Z_QuickMap6(pageswapargs_stat_offset_size);

	Z_QuickMap1AI(pageswapargs_stat_offset_size,    INDEXED_PAGE_9C00_OFFSET);
	Z_QuickMap4AI(pageswapargs_stat_offset_size+1,  INDEXED_PAGE_7000_OFFSET);
	Z_QuickMap1AI(pageswapargs_stat_offset_size+5, INDEXED_PAGE_6000_OFFSET);



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_STATUS;
}

void __far Z_QuickMapStatusNoScreen4() {

	Z_QuickMap4AI(pageswapargs_stat_offset_size+1,  INDEXED_PAGE_7000_OFFSET);
	Z_QuickMap1AI(pageswapargs_stat_offset_size+5, INDEXED_PAGE_6000_OFFSET);



#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif
	currenttask = TASK_STATUS_NO_SCREEN4;
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

void __far Z_QuickMapScratch_4000() {

	Z_QuickMap4AI(pageswapargs_scratch4000_offset_size, INDEXED_PAGE_4000_OFFSET);

#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	scratchpageswitchcount++;

#endif
}

void __far Z_QuickMapScreen0() {
	Z_QuickMap4AI(pageswapargs_screen0_offset_size, INDEXED_PAGE_8000_OFFSET);
}

void __far Z_QuickMapRenderPlanes9000only(){
	Z_QuickMapRender9000();
	Z_QuickMap1AI(pageswapargs_renderplane_offset_size+3, INDEXED_PAGE_9C00_OFFSET);
	current9000State = PAGE_9000_RENDER_PLANES;

}


void __far Z_QuickMapRenderPlanes(){

	//Z_QuickMap8(pageswapargs_renderplane_offset_size);
	Z_QuickMap3AI(pageswapargs_renderplane_offset_size, INDEXED_PAGE_5000_OFFSET);
	Z_QuickMap1AI(pageswapargs_renderplane_offset_size+3, INDEXED_PAGE_9C00_OFFSET);
	Z_QuickMap4AI(pageswapargs_renderplane_offset_size+4, INDEXED_PAGE_7000_OFFSET);

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		flatpageswitchcount++;
	#endif

	current5000State = PAGE_5000_RENDER_PLANE;
	current9000State = PAGE_9000_RENDER_PLANES;
}


void __far Z_QuickMapRenderPlanesBack(){

	Z_QuickMap3AI(pageswapargs_renderplane_offset_size, INDEXED_PAGE_5000_OFFSET);

	#ifdef DETAILED_BENCH_STATS
		taskswitchcount++;
		flatpageswitchcount++;
	#endif
	current5000State = PAGE_5000_RENDER_PLANE;

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
	
	Z_QuickMap8AI(pageswapargs_rend_texture_size, INDEXED_PAGE_5000_OFFSET); // put texture cache fragment back in 5000...
	
	// this runs 4 over into z_quickmapsprite page

	// inlined quickmap maksed (colormaps high, sprite cache, Z_QuickMapMaskedExtraData)
	// todo combine maskeddata and spritecache into a single 7 page run by reordering
	Z_QuickMap4AI(pageswapargs_spritecache_offset_size,     			INDEXED_PAGE_9000_OFFSET); // put sprite cache in 9000
	Z_QuickMap4AI(pageswapargs_spritecache_offset_size+4,     			INDEXED_PAGE_7000_OFFSET); // remap 9000-97FF data to 7000-77FF
	Z_QuickMap3AI(pageswapargs_maskeddata_offset_size,   				INDEXED_PAGE_8400_OFFSET); // map sprite data and colormaps to 8400-8FFF


#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	flatpageswitchcount++;

#endif
	currenttask = TASK_RENDER_SPRITE; 
	current9000State = PAGE_9000_RENDER_SPRITE;
	current5000State = PAGE_5000_RENDER;
}


void __far Z_QuickMapMaskedExtraData() {

	Z_QuickMap2AI(pageswapargs_maskeddata_offset_size, INDEXED_PAGE_8400_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	spritepageswitchcount++;

#endif

}

void __far Z_QuickMapSpritePage() {

	Z_QuickMap4AI(pageswapargs_spritecache_offset_size, INDEXED_PAGE_9000_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
	spritepageswitchcount++;

#endif

	current9000State = PAGE_9000_RENDER_SPRITE;
}
 
void __far Z_QuickMapPhysics5000() {

	Z_QuickMap4AI(pageswapargs_phys_offset_size + 4, INDEXED_PAGE_5000_OFFSET);
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	current5000State = PAGE_5000_PHYSICS;
}

 



void __far Z_QuickMapScreen1(){
	Z_QuickMap4AI(pageswapargs_intermission_offset_size+12, INDEXED_PAGE_9000_OFFSET);

	current9000State = PAGE_9000_SCREEN1;
}

void __far Z_QuickMapLumpInfo() {
	
	switch (current9000State) {

		case PAGE_9000_UNMAPPED:
			// use conventional memory until set up...
			return;
	 
		case PAGE_9000_RENDER_SPRITE:
		case PAGE_9000_RENDER:
		case PAGE_9000_RENDER_4000:
		case PAGE_9000_SCREEN1:
		case PAGE_9000_RENDER_PLANES:
			Z_QuickMap4AI(pageswapargs_phys_offset_size+20, INDEXED_PAGE_9000_OFFSET);
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

/*
		case PAGE_9000_RENDER_PLANE:
			Z_QuickMap4AI(pageswapargs_phys_offset_size+20, INDEXED_PAGE_9000_OFFSET);
			#ifdef DETAILED_BENCH_STATS
					taskswitchcount++;
					lumpinfo9000switchcount++;
			#endif
		
			last9000State = current9000State;
			current9000State = PAGE_9000_LUMPINFO_PHYSICS;
			return;
			*/

void __far Z_UnmapLumpInfo() {


	switch (last9000State) {
		case PAGE_9000_RENDER:
			Z_QuickMapRender9000();
			break;
		case PAGE_9000_RENDER_4000:
			Z_QuickMapRender_4000To9000_9000Only();
			break;
		case PAGE_9000_SCREEN1:
			Z_QuickMapScreen1();
			break;
		case PAGE_9000_RENDER_PLANES:
			Z_QuickMapRenderPlanes9000only();
			break;
		case PAGE_9000_RENDER_SPRITE:
			Z_QuickMapSpritePage();
		default:
			break;
	}
	// doesn't really need cleanup - this isnt dual-called

}


void __far Z_QuickMapLumpInfo5000() {
	switch (current5000State) {

		case PAGE_5000_SCRATCH:
		case PAGE_5000_PHYSICS:
		case PAGE_5000_RENDER:
		case PAGE_5000_UNMAPPED:
		case PAGE_5000_DEMOBUFFER:
		case PAGE_5000_RENDER_PLANE:

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
		case PAGE_5000_RENDER:
			Z_QuickMapRender5000();
		case PAGE_5000_PHYSICS:
			Z_QuickMapPhysics5000();
			break;
		case PAGE_5000_DEMOBUFFER:
			Z_QuickMapDemo();
			break;
		case PAGE_5000_RENDER_PLANE:
			Z_QuickMapRenderPlanesBack();
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
	Z_QuickMap8AI(pageswapargs_menu_offset_size, INDEXED_PAGE_5000_OFFSET);
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
	Z_QuickMap8AI(pageswapargs_wipe_offset_size+4, INDEXED_PAGE_6000_OFFSET);
	
#ifdef DETAILED_BENCH_STATS
	taskswitchcount++;
#endif

	currenttask = TASK_WIPE;
}

//todo: figure out when this can ever be called. then make sure the task values match what is necessary
// seems to be palette calls andmenu? and V_DrawFullscreenPatch
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
//		case TASK_STATUS_NO_SCREEN4:
//			Z_QuickMapStatusNoScreen4();
//			break;
		case TASK_RENDER_SPRITE:
			// this happened once, weird...? might be corruption
			I_Error("this happened..?"); // todo remove TASK_RENDER_SPRITE if this never happens..?
			Z_QuickMapRender();
			Z_QuickMapUndoFlatCache();
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
	#if defined(__CHIPSET_BUILD)
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

void __far Z_QuickMapUnmapAll() {
	int16_t i;
	for (i = 0; i < 24; i++) {

		pageswapargs[i * PAGE_SWAP_ARG_MULT] = _NPR(i + PAGE_4000_OFFSET);
		#if defined(__CHIPSET_BUILD)
		#else
			pageswapargs[i * PAGE_SWAP_ARG_MULT + 1] = pagenum9000 + ems_backfill_page_order[i];
		#endif

		
	}

	Z_QuickMap24AI(0);


}


void __far Z_SetOverlay(int8_t wipeId){
	int16_t codesize;
	int32_t codeoffset;
	FILE* fp;
	if (currentoverlay == wipeId){
		return;
	}
	
	currentoverlay = wipeId;
	codeoffset = codestartposition[wipeId-1];

	fp = fopen("DOOMCODE.BIN", "rb"); 
	fseek(fp, codeoffset, SEEK_SET);
	fread(&codesize, 2, 1, fp);
	FAR_fread(code_overlay_start, codesize, 1, fp);
	fclose(fp);


	// runtime linking... yay
	switch(wipeId){
		case OVERLAY_ID_WIPE:
			break;
		
		case OVERLAY_ID_FINALE:
			{
				int16_t __far *  finaledata = (int16_t __far *)((int32_t)code_overlay_start);

				finaledata[0] = (int16_t)(hu_font);
				finaledata[1] = (int16_t)(&player);
			}
		case OVERLAY_ID_LOADGAME:
			{
				int16_t __far *  loaddata = (int16_t __far *)((int32_t)code_overlay_start);

				loaddata[0] = (int16_t)(&playerMobjRef);
				loaddata[1] = (int16_t)(&player);
			}

			break;
	}



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
