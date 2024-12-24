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
#include <conio.h>

#include <stdlib.h>
#include "m_memory.h"
#include "m_near.h"






// EMS STUFF

void near doerror(int16_t errnum, int16_t errorreg) {
	I_Error("\n\n%d %d", errnum, errorreg); // Couldn't init EMS, error %d
}

#ifdef __SCAMP_BUILD

byte __far *__near Z_InitEMS() {
	int8_t i;
	EMS_PAGE = 0xD000; // hard coded
	//. enable EMS and page D000 in chipset
	outp(0xFB, 0x00); // dummy write configuration enable
	
	outp(0xEC, 0x0B);
	outp(0xED, 0xC0); // enable EMS and backfill

	outp(0xEC, 0x0C);
	outp(0xED, 0xF0); // enabled page D000

	// set default pages
	for (i = 0xC; i < 0x24; i++){
		// initialize pages..
		outp(0xE8, i);
		outpw(0xEA, i+0x04); // set default EMS pages for global stuff...
	}



	//todo do we disable config after?

	return MK_FP(EMS_PAGE, 0);
}

void __near Z_GetEMSPageMap() {
	int16_t i;



	Z_QuickMapLumpInfo5000();

	FAR_memcpy((byte __far *)0x54000000, (byte __far *)lumpinfoinit, 49152u); // copy the wad lump stuff over. gross
	FAR_memset((byte __far *)lumpinfoinit, 0, 49152u);

	Z_QuickMapPhysics(); // map default page map
}
#elif defined(__SCAT_BUILD)


byte __far *__near Z_InitEMS() {
	EMS_PAGE = 0xD000; // hard coded
	return MK_FP(EMS_PAGE, 0);
}

void __near Z_GetEMSPageMap() {
	int16_t i;


	Z_QuickMapLumpInfo5000();

	FAR_memcpy((byte __far *)0x54000000, (byte __far *)lumpinfoinit, 49152u); // copy the wad lump stuff over. gross
	FAR_memset((byte __far *)lumpinfoinit, 0, 49152u);

	Z_QuickMapPhysics(); // map default page map
}
#elif defined(__HT18_BUILD)

byte __far *__near Z_InitEMS() {
	
	EMS_PAGE = 0xD000; // hard coded
	
	
	// set d000 pages to working values
	
	outp(0x1EE, 0x1C); 
	outp(0x1EC, 0x03C);
	
	outp(0x1EE, 0x1D); 
	outp(0x1EC, 0x03D);

	outp(0x1EE, 0x1E); 
	outp(0x1EC, 0x03E);

	outp(0x1EE, 0x1F); 
	outp(0x1EC, 0x03F);
	
	
	return MK_FP(EMS_PAGE, 0);

}

void __near Z_GetEMSPageMap() {
	int16_t i;


	Z_QuickMapLumpInfo5000();

	FAR_memcpy((byte __far *)0x54000000, (byte __far *)lumpinfoinit, 49152u); // copy the wad lump stuff over. gross
	FAR_memset((byte __far *)lumpinfoinit, 0, 49152u);

	Z_QuickMapPhysics(); // map default page map
}

#else
byte __far *__near Z_InitEMS() {

	// 4 mb
	// todo test 3, 2 MB, etc. i know we use less..
	//int16_t numPagesToAllocate = NUM_EMS4_SWAP_PAGES; //256; //  (4 * 1024 * 1024) / PAGE_FRAME_SIZE;
	int16_t pageframebase;


	// todo check for device...
	// char	emmname[9] = "EMMXXXX0";



	int16_t pagestotal, pagesavail;
	int16_t errorreg;
	uint8_t vernum;
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


	//*size = numPagesToAllocate * PAGE_FRAME_SIZE;

	// EMS Handle
	EMS_PAGE = pageframebase;
	return  MK_FP(pageframebase, 0);



}

void __near Z_GetEMSPageMap() {
	int16_t pagedata[256]; // i dont think it can get this big...
	int16_t errorreg, i, numentries;
 

	regs.w.ax = 0x5801;  // physical page
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	numentries = regs.w.cx;
	if (errorreg != 0) {
		doerror(84, errorreg);// Call 5801 failed with value %i!\n
	}

	// how weird. the call sometimes fails  if we dont do this?
	memset(pagedata, 0, 256);

	regs.w.ax = 0x5800;  // physical page
	segregs.es = segregs.ds;
	
	regs.w.di = (int16_t)pagedata;
	intx86(EMS_INT, &regs, &regs);
	errorreg = regs.h.ah;
	//pagedata = MK_FP(sregs.es, regs.w.di);
	if (errorreg != 0) {
		doerror(83, errorreg);// Call 25 failed with value %i!\n
	}
 
	for (i = 0; i < numentries; i++) {
		if (pagedata[i << 1] == 0x9000u) {
			pagenum9000 = pagedata[(i << 1) + 1];
			goto found;
		}
	}

	//I_Error("\nMappable page for segment 0x9000 NOT FOUND! EMS 4.0 features unsupported?\n");

found:

	 

	// todo this is old and out of date, but informative.
	// update! or make a script that does this.

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




#endif


 
 



void __far I_UpdateNoBlit(void);
void __far I_FinishUpdate(void);

void PSetupEndFunc();
void __far P_SetupLevel (int8_t episode, int8_t map, skill_t skill);
boolean __far P_CheckSight (  mobj_t __near* t1, mobj_t __near* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos );
 
void __near Z_LoadBinaries() {
	FILE* fp2;
	int16_t i;
	int16_t codesize;
	FILE* fp = fopen("DOOMDATA.BIN", "rb"); 
	fseek(fp, DATA_DOOMDATA_OFFSET, SEEK_SET);
	// currently in physics region!
	
	FAR_fread(InfoFuncLoadAddr, 1, SIZE_D_INFO, fp);


	fp2 = fopen("DOOMCODE.BIN", "rb"); 
	fread(&codesize, 2, 1, fp2);
	FAR_fread(colfunc_function_area_6800, codesize, 1, fp2);





	// 400
	FAR_fread(colfunc_jump_lookup_6800,  2, SCREENHEIGHT * 2, fp);
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
	fread(mobjinfo, sizeof(mobjinfo_t), NUMMOBJTYPES, fp);
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

	Z_QuickMapRender();

	//8192
	FAR_fread(finetangentinner, 4, 2048, fp);


	//  fixes an issue with garbage left over from other applications running.
	FAR_memset(visplanes_8400, 0x00,   0xC000);
	Z_QuickMapVisplanePage(3, 1);
	Z_QuickMapVisplanePage(4, 2);
	FAR_memset(visplanes_8800, 0x00,   0x8000);

	DEBUG_PRINT(".");
	Z_QuickMapPhysics();

	//274
	FAR_fread(doomednum, 2, NUMMOBJTYPES, fp);
	
	Z_QuickMapRender4000();
	// todo put in doomdata...
	for (i = 0; i < NUMSTATES; i++){
		states_render[i].sprite = states[i].sprite;
		states_render[i].frame  = states[i].frame;
	}


	// load consecutive memory contents in one call here. 
	Z_QuickMapIntermission();
	//760
	FAR_fread(lnodex, 1, 928, fp);

	// FOD3
	Z_QuickMapPalette();
	
	FAR_fread(spanfunc_jump_lookup_9000, 2, 80, fp);

/*
	FAR_memcpy((byte __far *)spanfunc_function_area_9000, 
	(byte __far *)R_DrawSpan,
	 FP_OFF(R_FillBackScreen) - FP_OFF(R_DrawSpan));
*/

	fread(&codesize, 2, 1, fp2);
	FAR_fread(spanfunc_function_area_9000, codesize, 1, fp2);



	//I_Error("\n%i %i %i %i", epsd1animinfo[2].period, epsd1animinfo[2].loc.x, anims[1][2].period, anims[1][2].loc.x);
 
	Z_QuickMapRender();

	//2048
	FAR_fread(zlight, 1, 2048, fp);
	fread(fuzzoffset, 1, size_fuzzoffset, fp);

	Z_QuickMapMaskedExtraData();
		// load R_DrawFuzzColumn into high memory near colormaps_high...

	fread(&codesize, 2, 1, fp2);
	FAR_fread(drawfuzzcol_area, codesize, 1, fp2);
	

	//fread(&codesize, 2, 1, fp2);
	//FAR_fread(drawmaskedfuncarea_sprite, codesize, 1, fp2);

/*
	{
		FILE* fp1 = fopen("log4.txt", "wb");
		byte __far* addr1 = MK_FP(drawfuzzcol_area_segment, 0);
	    FAR_fwrite((byte __far *)addr1, R_DrawFuzzColumnCodeSize, 1, fp1);
		fclose(fp1);

		I_Error("done %x %x\n %lx %lx", R_DrawFuzzColumnCodeSize, R_DrawFuzzColumnCodeSize,
		addr1, addr1 + R_DrawFuzzColumnCodeSize
		
		);

	}
*/

	Z_QuickMapRenderPlanes();

	fread(&codesize, 2, 1, fp2);
	FAR_fread(drawskyplane_area, codesize, 1, fp2);

	Z_QuickMapPhysics();

	fread(&codesize, 2, 1, fp2);
	FAR_fread(fwipe_code_area, codesize, 1, fp2);


	fclose(fp2);





	fclose(fp);


	DEBUG_PRINT("..");
 
	// set some function addresses for asm calls. 
	// as these move to asm and EMS memory space themselves, these references can go away
	Z_QuickMapVisplanePage_addr = 	(uint32_t)(Z_QuickMapVisplanePage);
	R_EvictFlatCacheEMSPage_addr = 	(uint32_t)(R_EvictFlatCacheEMSPage);
	Z_QuickMapFlatPage_addr =   	(uint32_t)(Z_QuickMapFlatPage);
	R_MarkL2FlatCacheLRU_addr = 	(uint32_t)(R_MarkL2FlatCacheLRU);
	W_CacheLumpNumDirect_addr = 	(uint32_t)(W_CacheLumpNumDirect);


	Z_QuickMapPhysics_addr = 		(uint32_t)(Z_QuickMapPhysics);
	Z_QuickMapWipe_addr = 			(uint32_t)(Z_QuickMapWipe);
	Z_QuickMapScratch_5000_addr = 	(uint32_t)(Z_QuickMapScratch_5000);
	M_Random_addr = 				(uint32_t)(M_Random);
	I_UpdateNoBlit_addr = 			(uint32_t)(I_UpdateNoBlit);
	I_FinishUpdate_addr = 			(uint32_t)(I_FinishUpdate);
	V_MarkRect_addr = 				(uint32_t)(V_MarkRect);
	M_Drawer_addr = 				(uint32_t)(M_Drawer);

	FixedMul_addr = 				(uint32_t)(FixedMul);
	FixedMul1632_addr = 			(uint32_t)(FixedMul1632);
	FastDiv3232_addr = 				(uint32_t)(FastDiv3232);
	R_GetMaskedColumnSegment_addr = (uint32_t)(R_GetMaskedColumnSegment);
	getspritetexture_addr = 		(uint32_t)(getspritetexture);



}



