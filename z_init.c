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
#include "wi_stuff.h"

#include <dos.h>

#include <stdlib.h>
#include "m_memory.h"





extern union REGS regs;
extern struct SREGS segregs;
 
uint16_t EMS_PAGE;
// EMS STUFF
extern int16_t emshandle;


void near doerror(int16_t errnum, int16_t errorreg){
	I_Error("\n\n%d %d", errnum, errorreg); // Couldn't init EMS, error %d
}

byte __far* __near Z_InitEMS()
{

	// 4 mb
	// todo test 3, 2 MB, etc. i know we use less..
	//int16_t numPagesToAllocate = NUM_EMS4_SWAP_PAGES; //256; //  (4 * 1024 * 1024) / PAGE_FRAME_SIZE;
	int16_t pageframebase;


	// todo check for device...
	// char	emmname[9] = "EMMXXXX0";



	int16_t pagestotal, pagesavail;
	int16_t errorreg;
	uint8_t vernum;
	int16_t j;
	DEBUG_PRINT("  Checking EMS...");

	// used:
	/*
	40		1  Get Status                                     40h      
	41		2  Get Page Frame Segment Address                 41h       
	42		3  Get Unallocated Page Count                     42h       
	43		4  Allocate Pages                                 43h      
	44		removed 5  Map/Unmap Handle Page                          44h      
	45		6  Deallocate Pages                               45h       
	46		7  Get Version                                    46h       

          17 Map/Unmap Multiple Handle Pages
	5000	(Physical page number mode)                    5000h     
	          25 
	5800		Get Mappable Physical Address Array            5800h     
	5801		Get Mappable Physical Address Array Entries    5801h     
	
	*/

	regs.h.ah = 0x40;
	int86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	if (errorreg) {
		doerror(91, errorreg);
	}


	regs.h.ah = 0x46;
	intx86(EMS_INT, &regs, &regs);
	vernum = regs.h.al;
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		doerror(90, errorreg); // EMS Error 0x46
	}
	//DEBUG_PRINT("Version %i", vernum);
	if (vernum < 40) {
		doerror(92, vernum);
	}

	// get page frame address
	regs.h.ah = 0x41;
	intx86(EMS_INT, &regs, &regs);
	pageframebase = regs.w.bx;
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		doerror(89, errorreg);/// EMS Error 0x41
	}




	regs.h.ah = 0x42;
	intx86(EMS_INT, &regs, &regs);
	pagesavail = regs.w.bx;
	pagestotal = regs.w.dx;
	DEBUG_PRINT("\n  %i pages total, %i pages available at frame %p", pagestotal, pagesavail, pageframebase);

	if (pagesavail < NUM_EMS4_SWAP_PAGES) {
		I_Error("\nERROR: minimum of %i EMS pages required", NUM_EMS4_SWAP_PAGES);
	}


	regs.w.bx = NUM_EMS4_SWAP_PAGES; //numPagesToAllocate;
	regs.h.ah = 0x43;
	intx86(EMS_INT, &regs, &regs);
	emshandle = regs.w.dx;
	errorreg = regs.h.ah;
	if (errorreg != 0) {
		// Error 0 = 0x00 = no error
		// Error 137 = 0x89 = zero pages
		// Error 136 = 0x88 = OUT_OF_LOG
		doerror(88, errorreg);// EMS Error 0x43
	}


	// do initial page remapping

/*
	for (j = 0; j < 4; j++) {
		regs.h.al = j;  // physical page
		regs.w.bx = j;    // logical page
		regs.w.dx = emshandle; // handle
		regs.h.ah = 0x44;
		intx86(EMS_INT, &regs, &regs);
		if (regs.h.ah != 0) {
			I_Error("87"); // EMS Error 0x44
		}
	}
*/

	//*size = numPagesToAllocate * PAGE_FRAME_SIZE;

	// EMS Handle
	EMS_PAGE = pageframebase;
	return  MK_FP(pageframebase, 0);




}

 
 

extern int16_t pagenum9000;
extern int16_t pageswapargs[total_pages];
extern int16_t pageswapargoff;

  



void __near Z_GetEMSPageMap() {
	int16_t pagedata[256]; // i dont think it can get this big...
	int16_t __far* pointervalue = pagedata;
	int16_t errorreg, i, numentries;
 

	regs.w.ax = 0x5801;  // physical page
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	numentries = regs.w.cx;
	if (errorreg != 0) {
		doerror(84, errorreg);// Call 5801 failed with value %i!\n
	}
	DEBUG_PRINT("\n Found: %i mappable EMS pages (28+ required)", numentries);

	regs.w.ax = 0x5800;  // physical page
	segregs.es = FP_SEG(pointervalue);
	
	regs.w.di = FP_OFF(pointervalue);
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	//pagedata = MK_FP(sregs.es, regs.w.di);
	if (errorreg != 0) {
		doerror(83, errorreg);// Call 25 failed with value %i!\n
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
	//pageswapargseg = (uint16_t)((uint32_t)pageswapargs >> 16);
	pageswapargoff = FP_OFF(pageswapargs);
	 

	// todo this is old and out of date, but informative.
	// update!

	//					PHYSICS			RENDER					ST/HUD			DEMO		PALETTE			FWIPE				MENU		INTERMISSION
	// BLOCK
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// UMB BLOCK		
	// (0xE000)			level data
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// UMB HALF-BLOCK
	// 0xc800			sprite data
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//					lumpinfo		textures			screen4 0x9c00
	// 0x9000 block		empty											palettebytes	fwipe temp data					screen1
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//									tex cache arrays
	// 									sprite stuff			
	//					screen0			visplane openings									screen0			screen 0						screen0
	// 0x8000 block		gamma table		texture memrefs?									gamma table		gamma table		
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	// 0x7000 block		physics levdata render levdata			st graphics									screen 2		menu graphics	 
	//                                  flat cache?
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//					more physics levdata zlight																screen 3
	//                  rejectmatrix
	// 					nightnmarespawns textureinfo																		menu graphics	menu graphics
	// 0x6000 block		strings									strings															strings			strings
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//									flat cache
	//					events			events
	//                  states          states																[scratch buffer]				[scratch used
	// 0x5000 block		trig tables   	trig tables								demobuffer													for anims]
	// --------------------------------------------------------------------------------------------------------------------------------------------------
	//                  some common vars visplane stuff
	// 0x4000 block		thinkers		viewangles, drawsegs
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
	 

	Z_QuickMapLumpInfo5000();

	FAR_memcpy((byte __far *) 0x54000000, (byte __far *) lumpinfoinit, 49152u); // copy the wad lump stuff over. gross
	FAR_memset((byte __far *) lumpinfoinit, 0, 49152u);

	Z_QuickMapPhysics(); // map default page map
}


//extern byte __far* pageFrameArea;
extern int16_t emshandle;


void __far R_DrawColumn (void);
void __far R_DrawSpan (void);
void __far R_DrawFuzzColumn(int16_t count, byte __far * dest);

void PSetupEndFunc();
void __far P_SetupLevel (int8_t episode, int8_t map, skill_t skill);
boolean __far P_CheckSight (  mobj_t __far* t1, mobj_t __far* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos );
 
void __near Z_LoadBinaries() {
	int i;
	FILE* fp;
	// currently in physics region!
	fp = fopen("DOOMDATA.BIN", "rb"); 
	FAR_fread(InfoFuncLoadAddr, 1, SIZE_D_INFO, fp);

	// load R_DrawColumn into high memory near colormaps...
	FAR_memcpy(colfunc_function_area,
	(byte __far *)R_DrawColumn, 
	(byte __far *)R_DrawSpan - (byte __far *)R_DrawColumn);





	// 400
	FAR_fread(colfunc_jump_lookup,  2, SCREENHEIGHT * 2, fp);
	// 400
	//FAR_fread(dc_yl_lookup, 2, SCREENHEIGHT, fp);


	#ifdef MOVE_P_SIGHT
		FAR_memcpy(PSightFuncLoadAddr, (byte __far *)P_CheckSight, SIZE_PSight);
	#endif
	
	#ifdef MOVE_P_SETUP
		FAR_memcpy(PSetupFuncLoadAddr, (byte __far *)P_SetupLevel, SIZE_PSetup);
	#endif
	// copy psetup and pfunc..
	// 6736 bytes
	//FAR_memcpy(PSetupFuncLoadAddr, (byte __far *)P_SetupLevel, 0x1A50);
	//fclose(fp);


	// all data now in this file instead of spread out a
	
	//256
	FAR_fread(rndtable, 1, 256, fp);
	//128
	FAR_fread(scantokey, 1, 128, fp);
	
	//1507
	FAR_fread(mobjinfo, sizeof(mobjinfo_t), NUMMOBJTYPES, fp);
	DEBUG_PRINT(".");

	//5802
	FAR_fread(states, sizeof(state_t), NUMSTATES, fp);
	DEBUG_PRINT(".");

	//1280
	FAR_fread(gammatable, 1, 5 * 256, fp);
	DEBUG_PRINT(".");

	//40960
	FAR_fread(finesine, 4, 10240, fp);
	DEBUG_PRINT(".");

	//8192
	FAR_fread(finetangentinner, 4, 2048, fp);
	DEBUG_PRINT(".");

	//274
	FAR_fread(doomednum, 2, NUMMOBJTYPES, fp);

	// load consecutive memory contents in one call here
	Z_QuickMapIntermission();
	//760
	FAR_fread(lnodex, 1, 760, fp);

	// FOD3
	Z_QuickMapPalette();
	
	FAR_fread(spanfunc_jump_lookup_9000, 2, 80, fp);

	FAR_memcpy((byte __far *)spanfunc_function_area_9000, 
	(byte __far *)R_DrawSpan,
	 FP_OFF(R_FillBackScreen) - FP_OFF(R_DrawSpan));
	



	//I_Error("\n%i %i %i %i", epsd1animinfo[2].period, epsd1animinfo[2].loc.x, anims[1][2].period, anims[1][2].loc.x);
 
	Z_QuickMapRender();

	//2048
	FAR_fread(zlight, 1, 2048, fp);
	FAR_fread(fuzzoffset, 1, size_fuzzoffset, fp);

	Z_QuickMapMaskedExtraData();
		// load R_DrawFuzzColumn into high memory near colormaps_high...
	FAR_memcpy(drawfuzzcol_area,
	(byte __far *)R_DrawFuzzColumn, 
	(byte __far *)R_DrawMaskedSpriteShadow - (byte __far *)R_DrawFuzzColumn);



	Z_QuickMapPhysics();
	FAR_fread(pars, 2, 72, fp);  // 4*10 + 32 par times

	fclose(fp);

	DEBUG_PRINT("..");
 
	 

	

}



