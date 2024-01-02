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
#include "r_local.h"
#include "p_local.h"
#include "v_video.h"
#include "st_stuff.h"
#include "hu_stuff.h"

#include <dos.h>
#include <stdlib.h>
#include <malloc.h>



extern byte*			pageFrameArea;
extern byte*			EMSArea;
extern int16_t activepages[NUM_EMS_PAGES];
extern int8_t pageevictorder[NUM_EMS_PAGES];
extern int8_t pagesize[NUM_EMS_PAGES];
#define USER_MASK 0x8000



#ifdef _M_I86

extern union REGS regs;
extern struct SREGS segregs;

#else
#endif

 
extern PAGEREF currentListHead; // main rover
extern allocation_t allocations[EMS_ALLOCATION_LIST_SIZE];

 
uint16_t EMS_PAGE;
// EMS STUFF



#ifdef _M_I86
byte* far I_ZoneBaseEMS(int32_t *size, int16_t *emshandle)
{

	// 4 mb
	// todo test 3, 2 MB, etc. i know we use less..
	int16_t numPagesToAllocate = 256; //  (4 * 1024 * 1024) / PAGE_FRAME_SIZE;
	int16_t pageframebase;


	// todo check for device...
	// char	emmname[9] = "EMMXXXX0";



	int16_t pagestotal, pagesavail;
	int16_t errorreg;
	uint8_t vernum;
	int16_t j;
	DEBUG_PRINT("  Checking EMS...");



	regs.h.ah = 0x40;
	int86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	if (errorreg) {
		I_Error("Couldn't init EMS, error %d", errorreg);
	}


	regs.h.ah = 0x46;
	intx86(EMS_INT, &regs, &regs);
	vernum = regs.h.al;
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		I_Error("EMS Error 0x46");
	}
	//vernum = 10*(vernum >> 4) + (vernum&0xF);
	DEBUG_PRINT("Version %i", vernum);
	if (vernum < 40) {
		DEBUG_PRINT("Warning! EMS Version too low! Expected 4.0 , found %x", vernum);

	}

	// get page frame address
	regs.h.ah = 0x41;
	intx86(EMS_INT, &regs, &regs);
	pageframebase = regs.w.bx;
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		I_Error("EMS Error 0x41");
	}




	regs.h.ah = 0x42;
	intx86(EMS_INT, &regs, &regs);
	pagesavail = regs.w.bx;
	pagestotal = regs.w.dx;
	DEBUG_PRINT("\n  %i pages total, %i pages available at loc %p", pagestotal, pagesavail, 0, pageframebase);

	if (pagesavail < numPagesToAllocate) {
		DEBUG_PRINT("\nWarning: %i pages of memory recommended, only %i available.", numPagesToAllocate, pagesavail);
		numPagesToAllocate = pagesavail;
	}


	regs.w.bx = numPagesToAllocate;
	regs.h.ah = 0x43;
	intx86(EMS_INT, &regs, &regs);
	*emshandle = regs.w.dx;
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		// Error 0 = 0x00 = no error
		// Error 137 = 0x89 = zero pages
		// Error 136 = 0x88 = OUT_OF_LOG
		I_Error("EMS Error 0x43 %i", errorreg);
	}


	// do initial page remapping


	for (j = 0; j < 4; j++) {
		regs.h.al = j;  // physical page
		regs.w.bx = j;    // logical page
		regs.w.dx = *emshandle; // handle
		regs.h.ah = 0x44;
		intx86(EMS_INT, &regs, &regs);
		if (regs.h.ah != 0) {
			I_Error("EMS Error 0x44");
		}
	}


	*size = numPagesToAllocate * PAGE_FRAME_SIZE;

	// EMS Handle
	EMS_PAGE = pageframebase;
	return  MK_FP(pageframebase, 0);




}

#else

extern union REGS regs;
extern struct SREGS segregs;


byte* I_ZoneBaseEMS(int32_t *size) {

	// in 32 bit its ems fakery and emulation 

	int32_t meminfo[32];
	int32_t heap;
	byte *ptr;

	memset(meminfo, 0, sizeof(meminfo));
	segread(&segregs);
	segregs.es = segregs.ds;
	regs.w.ax = 0x500; // get memory info
	regs.x.edi = (int32_t)&meminfo;
	intx86x(0x31, &regs, &regs, &segregs);

	heap = meminfo[0];
	DEBUG_PRINT("DPMI memory: 0x%x", heap);

	do
	{
		heap -= 0x20000; // leave 128k alone
		// cap at 8M - 16384. 8 MB-1, or 0x7FFFFF at 23 bits is max addressable single region size in allocation_t. 
			// But subtract by a whole page frame worth of size to not have any weird situations.
		if (heap > 0x7FC000)
		{
			heap = 0x7FC000;
		}
		ptr = malloc(heap);
	} while (!ptr);

#ifdef DEBUG_PRINTING

	DEBUG_PRINT(", 0x%x allocated for zone\n", heap);
	if (heap < 0x180000)
	{
		DEBUG_PRINT("\n");
		DEBUG_PRINT("Insufficient memory!  You need to have at least 3.7 megabytes of total\n");

	}
#endif

	*size = heap;
	return ptr;
}

#endif


extern byte* texturecolumnlumps_bytes;
extern byte* texturecolumnofs_bytes;
extern byte* texturedefs_bytes;
extern byte* spritedefs_bytes;

extern int16_t pagenum9000;
extern int16_t pageswapargs_phys[40];
extern int16_t pageswapargs_rend[48];
extern int16_t pageswapargs_stat[12];
extern int16_t pageswapargs_demo[8];
extern int16_t pageswapargs_textcache[8];
extern int16_t pageswapargs_textinfo[8];
extern int16_t pageswapargs_scratch_4000[8];
extern int16_t pageswapargs_scratch_5000[8];
extern int16_t pageswapargs_scratch_stack[16];
extern int16_t pageswapargs_rend_temp_7000_to_6000[8];
extern int16_t pageswapargs_flat[8];

extern int16_t pageswapargseg_phys;
extern int16_t pageswapargoff_phys;
extern int16_t pageswapargseg_rend;
extern int16_t pageswapargoff_rend;
extern int16_t pageswapargseg_stat;
extern int16_t pageswapargoff_stat;
extern int16_t pageswapargseg_demo;
extern int16_t pageswapargoff_demo;
extern int16_t pageswapargseg_textcache;
extern int16_t pageswapargoff_textcache;
extern int16_t pageswapargseg_textinfo;
extern int16_t pageswapargoff_textinfo;
extern int16_t pageswapargseg_scratch_4000;
extern int16_t pageswapargoff_scratch_4000;
extern int16_t pageswapargseg_scratch_5000;
extern int16_t pageswapargoff_scratch_5000;
extern int16_t pageswapargseg_scratch_stack;
extern int16_t pageswapargoff_scratch_stack;
extern int16_t pageswapargseg_flat;
extern int16_t pageswapargoff_flat;

extern byte* stringdata;
extern byte* demobuffer;

uint8_t fontlen[63] = { 72, 100, 116, 128, 144, 132, 60, 
					   120, 120, 96, 76, 60, 80, 56, 100, 
					   132, 84, 140, 132, 116, 124, 132, 120, 
					   140, 132, 84, 72, 80, 80, 80, 128, 156,
					   132, 140, 140, 132, 132, 128, 132, 136, 
						72, 120, 140, 120, 148, 136, 124, 128, 
					   136, 140, 120, 120, 132, 108, 148, 160, 
						124, 128, 92, 100, 92, 96, 104 };
 

int16_t facelen[42] = { 808, 808, 808, 880, 884, 844, 816, 824, 
						808, 808, 800, 888, 884, 844, 816, 824, 
						824, 828, 824, 896, 896, 844, 816, 824, 
						840, 836, 832, 908, 944, 844, 816, 824, 
						844, 836, 844, 908, 944, 844, 816, 824, 
						808, 836 };


#define PAGE_9000 pagenum9000 + 0
#define PAGE_9400 pagenum9000 + 1
#define PAGE_9800 pagenum9000 + 2
#define PAGE_9C00 pagenum9000 + 3

#define PAGE_8000 pagenum9000 - 4
#define PAGE_8400 pagenum9000 - 3
#define PAGE_8800 pagenum9000 - 2
#define PAGE_8C00 pagenum9000 - 1

#define PAGE_7000 pagenum9000 - 8
#define PAGE_7400 pagenum9000 - 7
#define PAGE_7800 pagenum9000 - 6
#define PAGE_7C00 pagenum9000 - 5

#define PAGE_6000 pagenum9000 - 12
#define PAGE_6400 pagenum9000 - 11
#define PAGE_6800 pagenum9000 - 10
#define PAGE_6C00 pagenum9000 - 9

#define PAGE_5000 pagenum9000 - 16
#define PAGE_5400 pagenum9000 - 15
#define PAGE_5800 pagenum9000 - 14
#define PAGE_5C00 pagenum9000 - 13

#define PAGE_4000 pagenum9000 - 20
#define PAGE_4400 pagenum9000 - 19
#define PAGE_4800 pagenum9000 - 18
#define PAGE_4C00 pagenum9000 - 17


int8_t ems_backfill_page_order[24] = { 0, 1, 2, 3, -4, -3, -2, -1, -8, -7, -6, -5, -12, -11, -10, -9, -16, -15, -14, -13, -20, -19, -18, -17};

extern  uint16_t		DEMO_SEGMENT;


void Z_GetEMSPageMap() {
	int16_t pagedata[256]; // i dont think it can get this big...
	int16_t* far pointervalue = pagedata;
	int16_t errorreg, i, numentries;

	/*
	FILE *fp;

	fp = fopen("d_gammat.bin", "wb"); // clear old file
	fwrite(gammatable, 5*256, 1, fp);
	I_Error("done");
	*/

	//states = MK_FP(0x9000, 0);
/*
	fp = fopen("D_MBINFO.BIN", "r");
	fread(mobjinfo, sizeof(mobjinfo_t) * NUMMOBJTYPES, 1, fp);
	fclose(fp);
	DEBUG_PRINT(".");
	I_Error("\n%hhx %hhx %hhx %hhx",((byte*)mobjinfo)[20], ((byte*)mobjinfo)[200], ((byte*)mobjinfo)[250], ((byte*)mobjinfo)[520]);
	*/
	// 40 0 42 10

	//fp = fopen("D_STATES.BIN", "r");
	//fread(states, sizeof(state_t), NUMSTATES, fp);
	//fclose(fp);
	//DEBUG_PRINT(".");
	
 

	//I_Error("\n%hhx %hhx %hhx %hhx",((byte*)mobjinfo)[20], ((byte*)mobjinfo)[200], ((byte*)mobjinfo)[250], ((byte*)mobjinfo)[520]);

	regs.w.ax = 0x5801;  // physical page
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	numentries = regs.w.cx;
	if (errorreg != 0) {
		I_Error("\nCall 5801 failed with value %i!\n", errorreg);
	}
	printf("\n Found: %i mappable EMS pages (usually 28 for EMS 4.0 hardware)", numentries);

	regs.w.ax = 0x5800;  // physical page
	segregs.es = (uint16_t)((uint32_t)pointervalue >> 16);
	regs.w.di = (uint16_t)(((uint32_t)pointervalue) & 0xffff);
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	//pagedata = MK_FP(sregs.es, regs.w.di);
	if (errorreg != 0) {
		I_Error("\nCall 25 failed with value %i!\n", errorreg);
	}
 
	for (i = 0; i < numentries; i++) {
		if (pagedata[i * 2] == 0x9000u) {
			pagenum9000 = pagedata[(i * 2) + 1];
			goto found;
		}
	}

	//I_Error("\nMappable page for segment 0x9000 NOT FOUND! EMS 4.0 features unsupported?\n");

found:

	// cache these args
	pageswapargseg_phys = (uint16_t)((uint32_t)pageswapargs_phys >> 16);
	pageswapargoff_phys = (uint16_t)(((uint32_t)pageswapargs_phys) & 0xffff);
	pageswapargseg_rend = (uint16_t)((uint32_t)pageswapargs_rend >> 16);
	pageswapargoff_rend = (uint16_t)(((uint32_t)pageswapargs_rend) & 0xffff);
	pageswapargseg_stat = (uint16_t)((uint32_t)pageswapargs_stat >> 16);
	pageswapargoff_stat = (uint16_t)(((uint32_t)pageswapargs_stat) & 0xffff);
	pageswapargseg_demo = (uint16_t)((uint32_t)pageswapargs_demo >> 16);
	pageswapargoff_demo = (uint16_t)(((uint32_t)pageswapargs_demo) & 0xffff);
	pageswapargseg_textcache = (uint16_t)((uint32_t)pageswapargs_textcache >> 16);
	pageswapargoff_textcache = (uint16_t)(((uint32_t)pageswapargs_textcache) & 0xffff);
	pageswapargseg_textinfo = (uint16_t)((uint32_t)pageswapargs_textinfo >> 16);
	pageswapargoff_textinfo = (uint16_t)(((uint32_t)pageswapargs_textinfo) & 0xffff);
	pageswapargseg_flat = (uint16_t)((uint32_t)pageswapargs_flat >> 16);
	pageswapargoff_flat = (uint16_t)(((uint32_t)pageswapargs_flat) & 0xffff);

	pageswapargseg_scratch_stack = (uint16_t)((uint32_t)pageswapargs_scratch_stack >> 16);
	pageswapargoff_scratch_stack = (uint16_t)(((uint32_t)pageswapargs_scratch_stack) & 0xffff);
	pageswapargseg_scratch_5000 = (uint16_t)((uint32_t)pageswapargs_scratch_5000 >> 16);
	pageswapargoff_scratch_5000 = (uint16_t)(((uint32_t)pageswapargs_scratch_5000) & 0xffff);
	pageswapargseg_scratch_4000 = (uint16_t)((uint32_t)pageswapargs_scratch_4000 >> 16);
	pageswapargoff_scratch_4000 = (uint16_t)(((uint32_t)pageswapargs_scratch_4000) & 0xffff);

	

	//					PHYSICS			RENDER					ST/HUD			DEMO		   FWIPE
	// BLOCK
	// -------------------------------------------------------------------------------------------------------
	//            						visplane stuff			screen4 0x9c00
	// 0x9000 block		thinkers		viewangles, drawsegs
	// -------------------------------------------------------------------------------------------------------
	//									tex cache arrays
	// 									sprite stuff			
	//					screen0			visplane openings
	// 0x8000 block		gamma table		texture memrefs?
	// -------------------------------------------------------------------------------------------------------
	// 0x7000 block		physics levdata render levdata			st graphics
	// -------------------------------------------------------------------------------------------------------
	//				more physics levdata zlight											
	// 					nightnmarespawns textureinfo			
	//0x6000 block		strings			flat cache				strings						 
	// -------------------------------------------------------------------------------------------------------
	//                  states          states 
	// 0x5000 block		trig tables   	trig tables								demobuffer	
	// -------------------------------------------------------------------------------------------------------
	// 0x4000 block						textures

	 
	
	for (i = 0; i < 20; i++) {
		pageswapargs_phys[i * 2] = i;
		pageswapargs_rend[i * 2] = 20 + i;
		pageswapargs_phys[i * 2 + 1] = pagenum9000 + ems_backfill_page_order[i];
		pageswapargs_rend[i * 2 + 1] = pagenum9000 + ems_backfill_page_order[i];
	}

 

	// overwrite some fields
	pageswapargs_rend[32] = FIRST_TRIG_TABLE_LOGICAL_PAGE;    // 0x5000 trig stuff shared with physics (finesine/cos)
	pageswapargs_rend[34] = FIRST_TRIG_TABLE_LOGICAL_PAGE + 1;// 0x5400 trig stuff shared with physics (finesine/cos)
	pageswapargs_rend[36] = FIRST_TRIG_TABLE_LOGICAL_PAGE + 2;// 0x5800 trig stuff shared with physics (finesine/cos, finetan)
	pageswapargs_rend[38] = FIRST_TRIG_TABLE_LOGICAL_PAGE + 3;// 0x5c00 trig stuff shared with physics (tantoangle) 

	// overwrite some more fields (todo move to the for loop below)
	//pageswapargs_rend[24] = TEXTURE_INFO_LOGICAL_PAGE;    // 0x6000 texture info stuff
	//pageswapargs_rend[26] = TEXTURE_INFO_LOGICAL_PAGE + 1;// 0x6400 texture info stuff
	//pageswapargs_rend[28] = TEXTURE_INFO_LOGICAL_PAGE + 2;// 0x6800 texture info stuff
	//pageswapargs_rend[30] = TEXTURE_INFO_LOGICAL_PAGE + 3;// 0x6c00 texture info stuff also zlight table



	for (i = 20; i < 24; i++) {
		pageswapargs_rend[i * 2] = FIRST_TEXTURE_LOGICAL_PAGE + (i - 20);
		pageswapargs_rend[i * 2 + 1] = PAGE_4000 + (i - 20);
	}

	for (i = 1; i < 5; i++) {
		pageswapargs_stat[i * 2] = FIRST_STATUS_LOGICAL_PAGE + (i-1);
		pageswapargs_stat[i * 2 + 1] = PAGE_7000 + (i-1);
	}

	pageswapargs_stat[0] = SCREEN4_LOGICAL_PAGE;
	pageswapargs_stat[1] = PAGE_9C00;
	pageswapargs_stat[10] = STRINGS_LOGICAL_PAGE;
	pageswapargs_stat[11] = PAGE_6000; // strings;
	 

 

	for (i = 0; i < 4; i++) {
		pageswapargs_demo[i * 2] = FIRST_DEMO_LOGICAL_PAGE + i;
		pageswapargs_demo[i * 2 + 1] = PAGE_5000 + i;

		pageswapargs_textcache[i * 2] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		pageswapargs_textcache[i * 2 + 1] = PAGE_4000 + i;
		
		pageswapargs_textinfo[i * 2] = TEXTURE_INFO_LOGICAL_PAGE + i;
		pageswapargs_textinfo[i * 2 + 1] = PAGE_6000 + i;

		pageswapargs_scratch_5000[i * 2] = SCRATCH_LOGICAL_PAGE + i;
		pageswapargs_scratch_5000[i * 2 + 1] = PAGE_5000 + i;

		pageswapargs_scratch_4000[i * 2] = SCRATCH_LOGICAL_PAGE + i;
		pageswapargs_scratch_4000[i * 2 + 1] = PAGE_4000 + i;

		pageswapargs_scratch_stack[i * 2] = SCRATCH_LOGICAL_PAGE + i;
		pageswapargs_scratch_stack[i * 2 + 1] = PAGE_5000 + i; // 0x5000 area
		
		pageswapargs_scratch_stack[8 + i * 2] = FIRST_TRIG_TABLE_LOGICAL_PAGE + i;		// stack on scratch frame will always be trig pages etc..
		pageswapargs_scratch_stack[8 + i * 2 + 1] = PAGE_5000 + i; // 0x5000 area

		pageswapargs_flat[i * 2] = FIRST_FLAT_CACHE_LOGICAL_PAGE + i;
		pageswapargs_flat[i * 2 + 1] = PAGE_5C00 + i;

	}

	DEMO_SEGMENT = 0x5000u;

	for (i = 0; i < 4; i++) {
		pageswapargs_rend_temp_7000_to_6000[i * 2] = 28 + i;
		pageswapargs_rend_temp_7000_to_6000[i * 2 + 1] = PAGE_6000 + i;
		//pageswapargs_rend_temp_7000_to_6000[i * 2 + 1] = pagenum9000 + ems_backfill_page_order[i + 12];
	}


	Z_QuickmapPhysics(); // map default page map
}

void Z_LinkEMSVariables() {
	uint16_t segment;
	uint16_t offset_render;
	uint16_t offset_physics;
	uint16_t offset_status;
	int16_t i;

	// we're an OS now! let's directly allocate memory !

	segment = 0x9000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;
	//physics mapping
	thinkerlist = MK_FP(segment, offset_physics);
	offset_physics += sizeof(thinker_t) * MAX_THINKERS;
	mobjinfo = MK_FP(segment, offset_physics);
	offset_physics += sizeof(mobjinfo_t) * NUMMOBJTYPES;


	intercepts = MK_FP(segment, offset_physics);
	offset_physics += sizeof(intercept_t) * MAXINTERCEPTS;


	//render mapping, mostly visplane stuff... can be swapped out for thinker, mobj data stuff for certain sprite render functions
	visplanes = MK_FP(segment, 0);
	offset_render += sizeof(visplane_t) * MAXCONVENTIONALVISPLANES;
	visplaneheaders = MK_FP(segment, offset_render);
	offset_render += sizeof(visplaneheader_t) * MAXEMSVISPLANES;
	yslope = MK_FP(segment, offset_render);
	offset_render += sizeof(fixed_t) * SCREENHEIGHT;
	distscale = MK_FP(segment, offset_render);
	offset_render += sizeof(fixed_t) * SCREENWIDTH;
	cachedheight = MK_FP(segment, offset_render);
	offset_render += sizeof(fixed_t) * SCREENHEIGHT;
	cacheddistance = MK_FP(segment, offset_render);
	offset_render += sizeof(fixed_t) * SCREENHEIGHT;
	cachedxstep = MK_FP(segment, offset_render);
	offset_render += sizeof(fixed_t) * SCREENHEIGHT;
	cachedystep = MK_FP(segment, offset_render);
	offset_render += sizeof(fixed_t) * SCREENHEIGHT; // up to here r_plane only basically
	spanstart = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * SCREENHEIGHT;


	viewangletox = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * (FINEANGLES / 2);
	xtoviewangle = MK_FP(segment, offset_render);
	offset_render += sizeof(fineangle_t) * (SCREENWIDTH + 1);
	drawsegs = MK_FP(segment, offset_render);
	offset_render += sizeof(drawseg_t) * (MAXDRAWSEGS);
	floorclip = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * SCREENWIDTH;
	ceilingclip = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * SCREENWIDTH;




	// offset_render is 65534
	// now 64894

	offset_status -= (ST_WIDTH*ST_HEIGHT);
	screen4 = MK_FP(segment, offset_status);


	printf("\n  MEMORY AREA  Physics  Render  HU/ST    Demo");
	printf("\n   0x9000:      %05u   %05u   %05u   00000", offset_physics, offset_render, 0 - offset_status);

	segment = 0x8000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	screen0 = MK_FP(segment, 0);
	offset_physics += 64000u;
	gammatable = MK_FP(segment, offset_physics);
	offset_physics += (256 * 5);


	colormapbytes = MK_FP(segment, offset_render);
	offset_render += ((33 * 256));
	openings = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * MAXOPENINGS;
	negonearray = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * (SCREENWIDTH);
	screenheightarray = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * (SCREENWIDTH);
	vissprites = MK_FP(segment, offset_render);
	offset_render += sizeof(vissprite_t) * (MAXVISSPRITES);
	scalelightfixed = MK_FP(segment, offset_render);
	offset_render += sizeof(lighttable_t*) * (MAXLIGHTSCALE);

	spritewidths = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * numspritelumps);
	spriteoffsets = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * numspritelumps);
	spritetopoffsets = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * numspritelumps);

	// todo change all this to 16 bit pointers/lookups based on fixed 0x8000 colormapbytes segment.
	// then bring offset_render back up
	scalelight = MK_FP(segment, offset_render);
	offset_render += sizeof(lighttable_t* far) * (LIGHTLEVELS * MAXLIGHTSCALE);

	usedcompositetexturepagemem = MK_FP(segment, offset_render);
	offset_render += NUM_TEXTURE_PAGES * sizeof(uint8_t);
	compositetextureoffset = MK_FP(segment, offset_render);
	offset_render += numtextures * sizeof(uint8_t);
	compositetexturepage = MK_FP(segment, offset_render);
	offset_render += numtextures * sizeof(uint8_t);

	usedspritepagemem = MK_FP(segment, offset_render);
	offset_render += NUM_SPRITE_CACHE_PAGES * sizeof(uint8_t);
	spritepage = MK_FP(segment, offset_render);
	offset_render += numspritelumps * sizeof(uint8_t);
	spriteoffset = MK_FP(segment, offset_render);
	offset_render += numspritelumps * sizeof(uint8_t);

	usedpatchpagemem = MK_FP(segment, offset_render);
	offset_render += NUM_PATCH_CACHE_PAGES * sizeof(uint8_t);
	patchpage = MK_FP(segment, offset_render);
	offset_render += numpatches * sizeof(uint8_t);
	patchoffset = MK_FP(segment, offset_render);
	offset_render += numpatches * sizeof(uint8_t);

	flatindex = MK_FP(segment, offset_render);
	offset_render += numflats * sizeof(uint8_t);
	/*
	*/


	// from the top

	// 0x9000  40203  64894  10240
	// 0x8000  65280  64772  00000
	// 0x7000  XXXXX  XXXXX  64208
	// 0x6000  24784  55063  16384  
	// 0x5000  63150  63150  00000  XXXXX 
	// 0x4000  00000  00000  00000

	printf("\n   0x8000:      %05u   %05u   %05u   00000", offset_physics, offset_render, 0 - offset_status);
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	segment = 0x7000;


	offset_status = 0u;
	offset_status -= 320;
	tallnum[0] = MK_FP(segment, offset_status);
	offset_status -= 244;
	tallnum[1] = MK_FP(segment, offset_status);
	offset_status -= 336;
	tallnum[2] = MK_FP(segment, offset_status);
	offset_status -= 336;
	tallnum[3] = MK_FP(segment, offset_status);
	offset_status -= 316;
	tallnum[4] = MK_FP(segment, offset_status);
	offset_status -= 348;
	tallnum[5] = MK_FP(segment, offset_status);
	offset_status -= 340;
	tallnum[6] = MK_FP(segment, offset_status);
	offset_status -= 276;
	tallnum[7] = MK_FP(segment, offset_status);
	offset_status -= 348;
	tallnum[8] = MK_FP(segment, offset_status);
	offset_status -= 336;
	tallnum[9] = MK_FP(segment, offset_status);

	offset_status -= 68;
	shortnum[0] = MK_FP(segment, offset_status);
	offset_status -= 64;
	shortnum[1] = MK_FP(segment, offset_status);
	offset_status -= 76;
	shortnum[2] = MK_FP(segment, offset_status);
	offset_status -= 72;
	shortnum[3] = MK_FP(segment, offset_status);
	offset_status -= 60;
	shortnum[4] = MK_FP(segment, offset_status);
	offset_status -= 72;
	shortnum[5] = MK_FP(segment, offset_status);
	offset_status -= 72;
	shortnum[6] = MK_FP(segment, offset_status);
	offset_status -= 72;
	shortnum[7] = MK_FP(segment, offset_status);
	offset_status -= 76;
	shortnum[8] = MK_FP(segment, offset_status);
	offset_status -= 72;
	shortnum[9] = MK_FP(segment, offset_status);

	offset_status -= 328;
	tallpercent = MK_FP(segment, offset_status);


	offset_status -= 104;
	keys[0] = MK_FP(segment, offset_status);
	offset_status -= 104;
	keys[1] = MK_FP(segment, offset_status);
	offset_status -= 104;
	keys[2] = MK_FP(segment, offset_status);
	offset_status -= 120;
	keys[3] = MK_FP(segment, offset_status);
	offset_status -= 120;
	keys[4] = MK_FP(segment, offset_status);
	offset_status -= 120;
	keys[5] = MK_FP(segment, offset_status);

	offset_status -= 1648;
	armsbg[0] = MK_FP(segment, offset_status);

	offset_status -= 76;
	arms[0][0] = MK_FP(segment, offset_status);
	offset_status -= 72;
	arms[1][0] = MK_FP(segment, offset_status);
	offset_status -= 60;
	arms[2][0] = MK_FP(segment, offset_status);
	offset_status -= 72;
	arms[3][0] = MK_FP(segment, offset_status);
	offset_status -= 72;
	arms[4][0] = MK_FP(segment, offset_status);
	offset_status -= 72;
	arms[5][0] = MK_FP(segment, offset_status);

	offset_status -= 1408;
	faceback = MK_FP(segment, offset_status);

	offset_status -= 13128;
	sbar = MK_FP(segment, offset_status);

	for (i = 0; i < 42; i++) {
		offset_status -= facelen[i];
		faces[i] = MK_FP(segment, offset_status);
	}

	for (i = 0; i < 63; i++) {
		offset_status -= fontlen[i];
		hu_font[i] = MK_FP(segment, offset_status);
	}


	printf("\n   0x7000:      XXXXX   XXXXX   %05u   00000", 0 - offset_status);
	segment = 0x6000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	stringdata = MK_FP(segment, offset_physics);
	offset_physics += 16384;
	rejectmatrix = MK_FP(segment, offset_physics);
	offset_physics += 16384;
	offset_status += 16384;
	nightmarespawns = MK_FP(segment, offset_physics);
	offset_physics += sizeof(mapthing_t) * MAX_THINKERS;


	texturecolumnlumps_bytes = MK_FP(segment, 0);
	texturecolumnofs_bytes   = MK_FP(segment, 21552u);
	texturedefs_bytes	     = MK_FP(segment, 21552u + 21552u);
	offset_render += (21552u + 21552u + 3767u);



	zlight = MK_FP(segment, offset_render);
	offset_render += sizeof(lighttable_t* far) * (LIGHTLEVELS * MAXLIGHTZ);


	printf("\n   0x6000:      %05u   %05u   %05u   00000", offset_physics, offset_render, offset_status);




	//I_Error("done");

	segment = 0x5000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;


	finesine = MK_FP(segment, offset_physics);
	finecosine = MK_FP(segment, 8192u);
	offset_physics += 10240 * sizeof(int32_t);
	finetangentinner = MK_FP(segment, offset_physics);
	offset_physics += 2048 * sizeof(int32_t);
	tantoangle = MK_FP(segment, offset_physics);
	offset_physics += 2049 * sizeof(uint32_t);
	states = MK_FP(segment, offset_physics);
	offset_physics += sizeof(state_t) * NUMSTATES;

	demobuffer = MK_FP(segment, 0);


	printf("\n   0x5000:      %05u   %05u   XXXXX   XXXXX", offset_physics, offset_physics);

	segment = 0x4000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	printf("\n   0x4000:      %05u   XXXXX   %05u   00000", offset_physics, offset_render, 0 - offset_status);



}


void Z_LoadBinaries() {
	FILE* fp;
	int32_t checksummer = 0;
	int16_t i = 0;
	// currently in physics region!
	fp = fopen("D_MBINFO.BIN", "rb"); 
	fread(mobjinfo, sizeof(mobjinfo_t), NUMMOBJTYPES, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_STATES.BIN", "rb");
	fread(states, sizeof(state_t), NUMSTATES, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_GAMMAT.BIN", "rb");
	fread(gammatable, 1, 5 * 256, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_FINES2.BIN", "rb");
	fread(finesine, 4, 10240, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_FINET4.BIN", "rb");
	fread(finetangentinner, 4, 2048, fp);
	fclose(fp);
	DEBUG_PRINT(".");


	fp = fopen("D_TANTOA.BIN", "rb");
	fread(tantoangle, 4, 2049, fp);
	fclose(fp);
	DEBUG_PRINT(".");
	 
}

byte conventionallowerblock[1250];

void Z_LinkConventionalVariables() {
	byte* offset;
	//1250 now
	uint16_t size = numtextures * (sizeof(uint16_t) * 3 + 4 * sizeof(uint8_t));

	//conventionallowerblock = offset = malloc(size);
	//I_Error("\n%lx %u", conventionallowerblock, size);


	texturecolumn_offset = (uint16_t*)offset;
	offset += numtextures * sizeof(uint16_t);
	texturedefs_offset = (uint16_t*)offset;
	offset += numtextures * sizeof(uint16_t);
	texturewidthmasks = offset;
	offset += numtextures * sizeof(uint8_t);
	textureheights = offset;
	offset += numtextures * sizeof(uint8_t);
	texturecompositesizes = (uint16_t*)offset;
	offset += numtextures * sizeof(uint16_t);
	flattranslation = offset;
	offset += numtextures * sizeof(uint8_t);
	texturetranslation = offset;
	offset += numtextures * sizeof(uint8_t);
	//I_Error("\n%lx %lx %lx %u", conventionallowerblock, offset, texturetranslation, size);

	 

}
