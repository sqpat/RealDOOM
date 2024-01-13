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



#define USER_MASK 0x8000

extern union REGS regs;
extern struct SREGS segregs;

 

 
uint16_t EMS_PAGE;
// EMS STUFF



byte far* I_ZoneBaseEMS(int32_t *size, int16_t *emshandle)
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


	*size = numPagesToAllocate * PAGE_FRAME_SIZE;

	// EMS Handle
	EMS_PAGE = pageframebase;
	return  MK_FP(pageframebase, 0);




}

 
 
extern byte* spritedefs_bytes;

extern int16_t pagenum9000;
extern int16_t pageswapargs[total_pages];
extern int16_t pageswapargseg;
extern int16_t pageswapargoff;

  

//extern byte far* demobuffer;
//extern byte far* palettebytes;


uint8_t fontlen[63] = { 72, 100, 116, 128, 144, 132, 60, 
					   120, 120, 96, 76, 60, 80, 56, 100, 
					   132, 84, 140, 132, 116, 124, 132, 120, 
					   140, 132, 84, 72, 80, 80, 80, 128, 156,
					   132, 140, 140, 132, 132, 128, 132, 136, 
						72, 120, 140, 120, 148, 136, 124, 128, 
					   136, 140, 120, 120, 132, 108, 148, 160, 
						124, 128, 92, 100, 92, 96, 104 };
 
/*
int16_t facelen[42] = { 808, 808, 808, 880, 884, 844, 816, 824, 
						808, 808, 800, 888, 884, 844, 816, 824, 
						824, 828, 824, 896, 896, 844, 816, 824, 
						840, 836, 832, 908, 944, 844, 816, 824, 
						844, 836, 844, 908, 984, 844, 816, 824, 
						808, 836 };
						*/

uint8_t facelen[42] = { 8, 8, 8, 80, 84, 44, 16, 24,
						8, 8, 0, 88, 84, 44, 16, 24,
						24, 28, 24, 96, 96, 44, 16, 24,
						40, 36, 32, 108, 144, 44, 16, 24,
						44, 36, 44, 108, 184, 44, 16, 24,
						8, 36 };

 


extern  uint16_t		DEMO_SEGMENT;


void Z_GetEMSPageMap() {
	int16_t pagedata[256]; // i dont think it can get this big...
	int16_t far* pointervalue = pagedata;
	int16_t errorreg, i, numentries;
	int16_t index;

	/*
	FILE *fp;

	fp = fopen("d_gammat.bin", "wb"); // clear old file
	fwrite(gammatable, 5*256, 1, fp);
	I_Error("done");
	*/

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
	//            						visplane stuff			screen4 0x9c00
	// 0x9000 block		thinkers		viewangles, drawsegs								palettebytes	fwipe temp data					screen1
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//									tex cache arrays
	// 									sprite stuff			
	//					screen0			visplane openings									screen0			screen 0						screen0
	// 0x8000 block		gamma table		texture memrefs?									gamma table		gamma table		
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// 0x7000 block		physics levdata render levdata			st graphics									screen 2		menu graphics	 
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//				more physics levdata zlight																screen 3
	//                  rejectmatrix
	// 					nightnmarespawns textureinfo																		menu graphics	menu graphics
	// 0x6000 block		strings			flat cache				strings															strings			strings
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//                  states          states																[scratch buffer]				[scratch used
	// 0x5000 block		trig tables   	trig tables								demobuffer													for anims]
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// 0x4000 block						textures


	for (i = 1; i < total_pages; i+= 2) {
		pageswapargs[i] += pagenum9000;
	}
	 
	DEMO_SEGMENT = 0x5000u;

	 


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
 
	offset_physics = size_intercepts;

	//render mapping, mostly visplane stuff... can be swapped out for thinker, mobj data stuff for certain sprite render functions
	offset_render = size_ceilingclip;
	
	//palettebytes = MK_FP(segment, 0);




	// offset_render is 65534
	// now 64894

	offset_status -= (ST_WIDTH*ST_HEIGHT);

	//screen4 = MK_FP(segment, offset_status);

	printf("\n  MEMORY AREA  Physics  Render  HU/ST    Demo    Menu");
	printf("\n   0x9000:      %05u   %05u   %05u   00000   00000", offset_physics, offset_render, 0 - offset_status);

	segment = 0x8000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	offset_physics = 64000u + (256 * 5);
 

 	offset_render += size_usedpatchpagemem;

	// dynamic sizes from here on out - hard to configure these as #define at runtime unless we set upward bounds that also cover doom1/2 commercial bounds.
	//spritewidths = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * numspritelumps);
	spriteoffsets = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * numspritelumps);
	spritetopoffsets = MK_FP(segment, offset_render);
	offset_render += (sizeof(int16_t) * numspritelumps);


	compositetextureoffset = MK_FP(segment, offset_render);
	offset_render += numtextures * sizeof(uint8_t);
	compositetexturepage = MK_FP(segment, offset_render);
	offset_render += numtextures * sizeof(uint8_t);

	spritepage = MK_FP(segment, offset_render);
	offset_render += numspritelumps * sizeof(uint8_t);
	spriteoffset = MK_FP(segment, offset_render);
	offset_render += numspritelumps * sizeof(uint8_t);

	patchpage = MK_FP(segment, offset_render);
	offset_render += numpatches * sizeof(uint8_t);
	patchoffset = MK_FP(segment, offset_render);
	offset_render += numpatches * sizeof(uint8_t);

	flatindex = MK_FP(segment, offset_render);
	offset_render += numflats * sizeof(uint8_t);
	/*
	*/


	// from the top

	// 0x9000  40203  64894  10240  00000  00000
	// 0x8000  65280  64772  00000  00000  00000
	// 0x7000  XXXXX  XXXXX  64208  00000  XXXXX
	// 0x6000  24784  55063  16384  00000  XXXXX
	// 0x5000  63150  63150  00000  XXXXX  00000
	// 0x4000  00000  00000  00000  00000  00000

	printf("\n   0x8000:      %05u   %05u   %05u   00000   00000", offset_physics, offset_render, 0 - offset_status);
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	segment = 0x7000;
	//screen2 = MK_FP(segment, 0);


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
		offset_status -= (800+facelen[i]);
		faces[i] = MK_FP(segment, offset_status);
	}

	for (i = 0; i < 63; i++) {
		offset_status -= fontlen[i];
		hu_font[i] = MK_FP(segment, offset_status);
	}


	printf("\n   0x7000:      XXXXX   XXXXX   %05u   00000   XXXXX", 0 - offset_status);
	segment = 0x6000;


	offset_physics = 32768u + sizeof(mapthing_t) * MAX_THINKERS;
	offset_status = 16384;



	offset_render = size_texturedefs_bytes;

	printf("\n   0x6000:      %05u   %05u   %05u   00000   XXXXX", offset_physics, offset_render, offset_status);

	segment = 0x5000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	offset_physics += size_states;

	//demobuffer = MK_FP(segment, 0);


	printf("\n   0x5000:      %05u   %05u   XXXXX   XXXXX   00000", offset_physics, offset_physics);

	segment = 0x4000;
	offset_render = 0u;
	offset_physics = 0u;
	offset_status = 0u;

	printf("\n   0x4000:      %05u   XXXXX   %05u   00000   00000", offset_physics, offset_render, 0 - offset_status);



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


	fp = fopen("D_TANTOA.BIN", "rb");
	FAR_fread(tantoangle, 4, 2049, fp);
	fclose(fp);
	DEBUG_PRINT(".");
	 
}

byte near conventionallowerblock[1250];

void Z_LinkConventionalVariables() {
	byte near* offset = conventionallowerblock;
	//1250 now
	//uint16_t size = numtextures * (sizeof(uint16_t) * 3 + 4 * sizeof(uint8_t));

	//conventionallowerblock = offset = malloc(size);
	//I_Error("\n%lx %u", conventionallowerblock, size);
	

	texturecolumn_offset = (uint16_t near*)offset;
	offset += numtextures * sizeof(uint16_t);
	texturedefs_offset = (uint16_t near*)offset;
	offset += numtextures * sizeof(uint16_t);
	texturewidthmasks = offset;
	offset += numtextures * sizeof(uint8_t);
	textureheights = offset;
	offset += numtextures * sizeof(uint8_t);
	texturecompositesizes = (uint16_t near*)offset;
	offset += numtextures * sizeof(uint16_t);
	flattranslation = offset;
	offset += numtextures * sizeof(uint8_t);
	texturetranslation = offset;
	offset += numtextures * sizeof(uint8_t);
	//I_Error("\n%lx %lx %lx %u", conventionallowerblock, offset, texturetranslation, size);

	//memset(conventionallowerblock, 0x00, 1250);

}
