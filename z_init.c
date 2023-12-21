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

 

// EMS STUFF



#ifdef _M_I86
byte* I_ZoneBaseEMS(int32_t *size, int16_t *emshandle)
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
	return MK_FP(pageframebase, 0);




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





extern int16_t pagenum9000;
extern int16_t pageswapargs_phys[32];
extern int16_t pageswapargs_rend[32];
extern int16_t pageswapargs_stat[12];

extern int16_t pageswapargs_rend_temp_7000_to_6000[8];

extern int16_t pageswapargseg_phys;
extern int16_t pageswapargoff_phys;
extern int16_t pageswapargseg_rend;
extern int16_t pageswapargoff_rend;
extern int16_t pageswapargseg_stat;
extern int16_t pageswapargoff_stat;

extern byte* stringdata;

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

uint16_t leveldataoffset_phys = 0u;
uint16_t leveldataoffset_rend = 0u;

void Z_GetEMSPageMap() {
	int16_t pagedata[256]; // i dont think it can get this big...
	int16_t* far pointervalue = pagedata;
	int16_t errorreg, i, numentries;
	uint16_t segment;
	uint16_t offset_render;
	uint16_t offset_physics;
	uint16_t offset_status;

	FILE *fp;
	 
	/*
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

	//					PHYSICS			RENDER					ST/HUD
	// BLOCK
	// 0x9000 block		thinkers		visplane stuff			screen4 0x9c00
	//									viewangles, drawsegs
	// 0x8000 block		screen0			sprite stuff			
	//					gamma table		visplane openings
	//									texture memrefs?
	// 0x7000 block		physics levdata render levdata			st graphics
	//					
	//					
	// 0x6000 block		strings				texturedata			strings
	// 0x5000 block						textures
	//					trig tables
	// 0x4000 block						textures

	// todo loopify

	pageswapargs_phys[0] = 0;
	pageswapargs_phys[1] = pagenum9000;
	pageswapargs_phys[2] = 1;
	pageswapargs_phys[3] = pagenum9000 + 1;
	pageswapargs_phys[4] = 2;
	pageswapargs_phys[5] = pagenum9000 + 2;
	pageswapargs_phys[6] = 3;
	pageswapargs_phys[7] = pagenum9000 + 3;
	pageswapargs_phys[8] = 4;
	pageswapargs_phys[9] = pagenum9000 - 4;
	pageswapargs_phys[10] = 5;
	pageswapargs_phys[11] = pagenum9000 - 3;
	pageswapargs_phys[12] = 6;
	pageswapargs_phys[13] = pagenum9000 - 2;
	pageswapargs_phys[14] = 7;
	pageswapargs_phys[15] = pagenum9000 - 1;
	pageswapargs_phys[16] = 8;
	pageswapargs_phys[17] = pagenum9000 - 8;
	pageswapargs_phys[18] = 9;
	pageswapargs_phys[19] = pagenum9000 - 7;
	pageswapargs_phys[20] = 10;
	pageswapargs_phys[21] = pagenum9000 - 6;
	pageswapargs_phys[22] = 11;
	pageswapargs_phys[23] = pagenum9000 - 5;
	pageswapargs_phys[24] = 12;
	pageswapargs_phys[25] = pagenum9000 - 12;// strings;
	pageswapargs_phys[26] = 13;
	pageswapargs_phys[27] = pagenum9000 - 11;//empty
	pageswapargs_phys[28] = 14;
	pageswapargs_phys[29] = pagenum9000 - 10;//empty;
	pageswapargs_phys[30] = 15;
	pageswapargs_phys[31] = pagenum9000 - 9;;//empty


	pageswapargs_rend[0] = 16;
	pageswapargs_rend[1] = pagenum9000;
	pageswapargs_rend[2] = 17;
	pageswapargs_rend[3] = pagenum9000 + 1;
	pageswapargs_rend[4] = 18;
	pageswapargs_rend[5] = pagenum9000 + 2;
	pageswapargs_rend[6] = 19;
	pageswapargs_rend[7] = pagenum9000 + 3;
	pageswapargs_rend[8] = 20;
	pageswapargs_rend[9] = pagenum9000 - 4;
	pageswapargs_rend[10] = 21;
	pageswapargs_rend[11] = pagenum9000 - 3;
	pageswapargs_rend[12] = 22;
	pageswapargs_rend[13] = pagenum9000 - 2;
	pageswapargs_rend[14] = 23;
	pageswapargs_rend[15] = pagenum9000 - 1;
	pageswapargs_rend[16] = 24;
	pageswapargs_rend[17] = pagenum9000 - 8;
	pageswapargs_rend[18] = 25;
	pageswapargs_rend[19] = pagenum9000 - 7;
	pageswapargs_rend[20] = 26;
	pageswapargs_rend[21] = pagenum9000 - 6;
	pageswapargs_rend[22] = 27;
	pageswapargs_rend[23] = pagenum9000 - 5;
	pageswapargs_rend[24] = 28;
	pageswapargs_rend[25] = pagenum9000 - 12;
	pageswapargs_rend[26] = 29;
	pageswapargs_rend[27] = pagenum9000 - 11;
	pageswapargs_rend[28] = 30;
	pageswapargs_rend[29] = pagenum9000 - 10;
	pageswapargs_rend[30] = 31;
	pageswapargs_rend[31] = pagenum9000 - 9;

	pageswapargs_stat[0] = 32;
	pageswapargs_stat[1] = pagenum9000 + 3;
	pageswapargs_stat[2] = 33;
	pageswapargs_stat[3] = pagenum9000 - 8;
	pageswapargs_stat[4] = 34;
	pageswapargs_stat[5] = pagenum9000 - 7;
	pageswapargs_stat[6] = 35;
	pageswapargs_stat[7] = pagenum9000 - 6;
	pageswapargs_stat[8] = 36;
	pageswapargs_stat[9] = pagenum9000 - 5;
	pageswapargs_stat[10] = 15;
	pageswapargs_stat[11] = pagenum9000 - 12; // strings;

	pageswapargs_rend_temp_7000_to_6000[0] = 24;
	pageswapargs_rend_temp_7000_to_6000[1] = pagenum9000 - 12;
	pageswapargs_rend_temp_7000_to_6000[2] = 25;
	pageswapargs_rend_temp_7000_to_6000[3] = pagenum9000 - 11;
	pageswapargs_rend_temp_7000_to_6000[4] = 26;
	pageswapargs_rend_temp_7000_to_6000[5] = pagenum9000 - 10;
	pageswapargs_rend_temp_7000_to_6000[6] = 27;
	pageswapargs_rend_temp_7000_to_6000[7] = pagenum9000 - 9;


	// we're an OS now! let's directly allocate memory !

	segment = 0x9000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;
	//physics mapping
	thinkerlist = MK_FP(segment, 0);
	offset_physics += sizeof(thinker_t) * MAX_THINKERS;
	//states = MK_FP(segment, offset_physics);
	offset_physics += sizeof(state_t) * NUMSTATES;
	mobjinfo = MK_FP(segment, offset_physics);
	offset_physics += sizeof(mobjinfo_t) * NUMMOBJTYPES;

	//65269

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


	printf("\n  MEMORY AREA  Physics  Render  Status");
	printf("\n   0x9000:      %05u   %05u   %05u", offset_physics, offset_render, 0-offset_status);

	segment = 0x8000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	screen0 = MK_FP(segment, 0);
	offset_physics += 64000u;
	gammatable = MK_FP(segment, offset_physics);
	offset_physics += (256 * 5);

	// 65280

	openings = MK_FP(segment, 0);
	offset_render += sizeof(int16_t) * MAXOPENINGS;
	negonearray = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * (SCREENWIDTH);
	screenheightarray = MK_FP(segment, offset_render);
	offset_render += sizeof(int16_t) * (SCREENWIDTH);
	vissprites = MK_FP(segment, offset_render);
	offset_render += sizeof(vissprite_t) * (MAXVISSPRITES);
	scalelightfixed = MK_FP(segment, offset_render);
	offset_render += sizeof(lighttable_t*) * (MAXLIGHTSCALE);
	colormapbytes = MK_FP(segment, offset_render);
	offset_render += ((33 * 256) + 255);

	spritewidths = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * NUM_SPRITE_LUMPS_CACHE);
	spriteoffsets = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * NUM_SPRITE_LUMPS_CACHE);
	spritetopoffsets = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * NUM_SPRITE_LUMPS_CACHE);
	
	// from the top

	//   65269  64894  10240
	//   65280  60945  00000
	//   00000  00000  64208


	printf("\n   0x8000:      %05u   %05u   %05u", offset_physics, offset_render, 0-offset_status);
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


	printf("\n   0x7000:      %05u   %05u   %05u", offset_physics, offset_render, 0 - offset_status);
	segment = 0x6000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	stringdata = MK_FP(segment, offset_physics);
	offset_physics += 16384;

	textureinfomemoryblock = MK_FP(segment, offset_render);
	offset_render += (STATIC_CONVENTIONAL_TEXTURE_INFO_SIZE);

	printf("\n   0x6000:      %05u   %05u   %05u", offset_physics, offset_render, 0 - offset_status);

	
	// todo: scalelight and zlight. Hard because they are 2d arrays of pointers?
	//scalelight = MK_FP(0x8000, offset_render);
	//offset_render += sizeof(lighttable_t) * (LIGHTLEVELS * MAXLIGHTSCALE);
	//zlight = MK_FP(0x8000, offset_render);
	//offset_render += sizeof(lighttable_t) * (LIGHTLEVELS * MAXLIGHTZ);

	//I_Error("done");

	Z_QuickmapPhysics(); // map default page map
}

byte* far Z_GetNext0x7000Address(uint16_t size, int8_t pagetype) {

	uint16_t oldoffset;
	uint16_t *useoffset;
	byte* far returnvalue;
	switch (pagetype) {
		case PAGE_TYPE_PHYSICS:
			oldoffset = leveldataoffset_phys;
			useoffset = &leveldataoffset_phys;
			break;
		case PAGE_TYPE_RENDER:
			oldoffset = leveldataoffset_rend;
			useoffset = &leveldataoffset_rend;
			break;
	}

	*useoffset -= size;
	returnvalue = MK_FP(0x7000, *useoffset);

	if (oldoffset != 0 && (oldoffset < *useoffset)) {
		// wraparound
		I_Error("Allocated too much space in Z_GetNextPhysicsAddress (size %u) ", size);
	}
	return returnvalue;

}

void Z_Subtract0x7000Address(uint16_t size, int8_t pagetype) {

	switch (pagetype) {
		case PAGE_TYPE_PHYSICS:
			leveldataoffset_phys += size; 
			return;
		case PAGE_TYPE_RENDER:
			leveldataoffset_rend += size;
			return;
	}


}

void Z_LoadBinaries() {
	FILE* fp;

	// currently in physics region!

	fp = fopen("D_MBINFO.BIN", "rb"); 
	fread(mobjinfo, 1, sizeof(mobjinfo_t) * NUMMOBJTYPES, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_STATES.BIN", "rb");
	//fread(states, 1, sizeof(state_t) * NUMSTATES, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_GAMMAT.BIN", "rb");
	fread(gammatable, 1, 5 * 256, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	//I_Error("\n%lx %lx %hhu %hhu %hhu", gammatable, 0L, gammatable[0], gammatable[128], gammatable[256 * 1 + 128]);

}


