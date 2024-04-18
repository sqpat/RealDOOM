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
#include "memory.h"

//#include <malloc.h>




extern union REGS regs;
extern struct SREGS segregs;
 
uint16_t EMS_PAGE;
// EMS STUFF


byte __far* I_ZoneBaseEMS(/*int32_t *size, */int16_t *emshandle)
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
		I_Error("91 %d", errorreg); // Couldn't init EMS, error %d
	}


	regs.h.ah = 0x46;
	intx86(EMS_INT, &regs, &regs);
	vernum = regs.h.al;
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		I_Error("90"); // EMS Error 0x46
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
		I_Error("89");/// EMS Error 0x41
	}




	regs.h.ah = 0x42;
	intx86(EMS_INT, &regs, &regs);
	pagesavail = regs.w.bx;
	pagestotal = regs.w.dx;
	DEBUG_PRINT("\n  %i pages total, %i pages available at page frame %p", pagestotal, pagesavail, pageframebase);

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
		I_Error("88 %i", errorreg);// EMS Error 0x43
	}


	// do initial page remapping


	for (j = 0; j < 4; j++) {
		regs.h.al = j;  // physical page
		regs.w.bx = j;    // logical page
		regs.w.dx = *emshandle; // handle
		regs.h.ah = 0x44;
		intx86(EMS_INT, &regs, &regs);
		if (regs.h.ah != 0) {
			I_Error("87"); // EMS Error 0x44
		}
	}


	//*size = numPagesToAllocate * PAGE_FRAME_SIZE;

	// EMS Handle
	EMS_PAGE = pageframebase;
	return  MK_FP(pageframebase, 0);




}

 
 

extern int16_t pagenum9000;
extern int16_t pageswapargs[total_pages];
extern int16_t pageswapargseg;
extern int16_t pageswapargoff;

  



void Z_GetEMSPageMap() {
	int16_t pagedata[256]; // i dont think it can get this big...
	int16_t __far* pointervalue = pagedata;
	int16_t errorreg, i, numentries;
 

	regs.w.ax = 0x5801;  // physical page
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	numentries = regs.w.cx;
	if (errorreg != 0) {
		I_Error("84 %i", errorreg);// \nCall 5801 failed with value %i!\n
	}
	DEBUG_PRINT("\n Found: %i mappable EMS pages (28+ required)", numentries);

	regs.w.ax = 0x5800;  // physical page
	segregs.es = (uint16_t)((uint32_t)pointervalue >> 16);
	regs.w.di = (uint16_t)(((uint32_t)pointervalue) & 0xffff);
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	//pagedata = MK_FP(sregs.es, regs.w.di);
	if (errorreg != 0) {
		I_Error("83 %i", errorreg);// \nCall 25 failed with value %i!\n
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
	pageswapargseg = (uint16_t)((uint32_t)pageswapargs >> 16);
	pageswapargoff = (uint16_t)(((uint32_t)pageswapargs) & 0xffff);
	 

	

	//					PHYSICS			RENDER					ST/HUD			DEMO		PALETTE			FWIPE				MENU		INTERMISSION
	// BLOCK
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// UMB BLOCK		
	// (0xE000)			level data
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// UMB HALF-BLOCK
	// 0xc800			sprite data
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//				some common vars	visplane stuff			screen4 0x9c00
	// 0x9000 block		thinkers		viewangles, drawsegs								palettebytes	fwipe temp data					screen1
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//									tex cache arrays
	// 									sprite stuff			
	//					screen0			visplane openings									screen0			screen 0						screen0
	// 0x8000 block		gamma table		texture memrefs?									gamma table		gamma table		
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// 0x7000 block		physics levdata render levdata			st graphics									screen 2		menu graphics	 
	//                                  flat cache?
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//				more physics levdata zlight																screen 3
	//                  rejectmatrix
	// 					nightnmarespawns textureinfo																		menu graphics	menu graphics
	// 0x6000 block		strings									strings															strings			strings
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//									flat cache
	//					events			events
	//                  states          states																[scratch buffer]				[scratch used
	// 0x5000 block		trig tables   	trig tables								demobuffer													for anims]
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//                  empty
	// 0x4000 block		lumpinfo		textures
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// NON EMS STUFF BELOW - ALWAYS MAPPED 
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// 0x3c00           (eventually) DS
	// 0x3200           sine/cosine/trig tables
	// 0x3000 block		
	// --------------------------------------------------------------------------------------------------------------------------------------------------


	for (i = 1; i < total_pages; i+= 2) {
		pageswapargs[i] += pagenum9000;
	}
	 


	Z_QuickmapLumpInfo5000();

	FAR_memcpy((byte __far *) 0x54000000, (byte __far *) 0x44000000, 49152u); // copy the wad lump stuff over. gross
	FAR_memset((byte __far *) 0x44000000, 0, 49152u);

	Z_QuickmapPhysics(); // map default page map
}

void Z_LinkEMSVariables() {
	/*
	// no longer linking dynamically, everything is statically allocated/defined...
	DEBUG_PRINT("\n  MEMORY AREA  Physics  Render  HU/ST    Demo    Menu");
	DEBUG_PRINT("\n   0x9000:      %05u   %05u   %05u   00000   00000", size_sectors_physics, size_texturewidthmasks, (ST_WIDTH*ST_HEIGHT));

 
 	 
	// 0xE000
	// 0xcc00
	// 0xb000
	// 0x9000  52791  59782  10240  00000  00000
	// 0x8000  65280  64764  00000  00000  00000
	// 0x7000  65442  63230  64248  00000  XXXXX
	// render 6c00-77ff completely full

	// 0x6000  65418  51846  16384  00000  XXXXX
	// 0x5000  15138  65535  00000  XXXXX  00000
	// 0x4000  00000  65535  00000  00000  00000
	// 0x3000  65514  
	
	DEBUG_PRINT("\n   0x8000:      %05u   %05u   00000   00000   00000", 64000u + (256 * 5), size_negonearray);
	DEBUG_PRINT("\n   0x7000:      %05u   %05u   %05u   00000   XXXXX", size_blockmaplump, size_spritetopoffsets + 32768u, 0 - 1288);
	DEBUG_PRINT("\n   0x6000:      %05u   %05u   %05u   00000   XXXXX", size_nightmarespawns+ 49152u, size_spanstart+ size_texturedefs_bytes, 16384);
	DEBUG_PRINT("\n   0x5000:      %05u   65535", size_sectors_physics);
	DEBUG_PRINT("\n   0x4000:      00000   XXXXX");
	DEBUG_PRINT("\n   0x3000:      %05u", size_events + baselowermemoryaddressStartingOffset, 0, 0);

	I_Error("done");
	*/
}

extern byte __far* pageFrameArea;
extern int16_t emshandle;

void Z_InitEMS(void) {
	//int32_t size;
	//todo figure this out based on settings, hardware, etc
	pageFrameArea = I_ZoneBaseEMS(&emshandle);
	//pageFrameArea = I_ZoneBaseEMS(&size, &emshandle);
}

void Z_LoadBinaries() {
	FILE* fp;
	// currently in physics region!
	fp = fopen("D_MBINFO.BIN", "rb"); 
	FAR_fread(mobjinfo, sizeof(mobjinfo_t), NUMMOBJTYPES, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_STATES.BIN", "rb");
	FAR_fread(states, sizeof(state_t), NUMSTATES, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_GAMMAT.BIN", "rb");
	FAR_fread(gammatable, 1, 5 * 256, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_FINES2.BIN", "rb");
	FAR_fread(finesine, 4, 10240, fp);
	fclose(fp);
	DEBUG_PRINT(".");

	fp = fopen("D_FINET4.BIN", "rb");
	FAR_fread(finetangentinner, 4, 2048, fp);
	fclose(fp);
	DEBUG_PRINT(".");


	//fp = fopen("D_TANTOA.BIN", "rb");
	//FAR_fread(tantoangle, 4, 2049, fp);
	//fclose(fp);
	DEBUG_PRINT(".");
	 
}




/*

// maybe move this into umb?
void Z_LinkConventionalVariables() {
	byte __near* offset = conventionallowerblock;

	//uint16_t size = MAX_TEXTURES * (sizeof(uint16_t) * 4 + 3 * sizeof(uint8_t));

	//conventionallowerblock = offset = malloc(size);
	//I_Error("\n%lx %u", conventionallowerblock, size);
	

	texturecolumn_offset = (uint16_t __near*)offset;
	offset += MAX_TEXTURES * sizeof(uint16_t);
	//texturedefs_offset = (uint16_t __near*)offset;
	//offset += MAX_TEXTURES * sizeof(uint16_t);
	//texturewidthmasks = offset;
	//offset += MAX_TEXTURES * sizeof(uint8_t);
	//textureheights = offset;
	//offset += MAX_TEXTURES * sizeof(uint8_t);
	texturecompositesizes = (uint16_t __near*)offset;
	offset += MAX_TEXTURES * sizeof(uint16_t);
	//flattranslation = offset;
	//offset += MAX_TEXTURES * sizeof(uint8_t);
	//texturetranslation = (uint16_t __near*)offset;
	//offset += MAX_TEXTURES * sizeof(uint16_t);
	texturepatchlump_offset = (uint16_t __near*)offset;
	offset += MAX_TEXTURES * sizeof(uint16_t);

	//I_Error("\n%lx %lx %lx %u", conventionallowerblock, offset, texturetranslation, size);


}
*/
