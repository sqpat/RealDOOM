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

#include "doomdef.h"
#include "z_zone.h"
#include "i_system.h"

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
#include "s_sound.h"
#include "f_finale.h"

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
	outp(0xED, 0xF0); // enabled page D000 as page frame

	;outp(0xEC, 0x10);
	;outp(0xED, 0xFF); // enable page D000 UMBs

	;outp(0xEC, 0x11);
	;outp(0xED, 0xAF); // enable page E000 UMBs. F000 read only.



	// set default pages
	for (i = 0xC; i < 0x24; i++){
		// initialize pages..
		outp(0xE8, i);
		outpw(0xEA, i+0x04); // set default EMS pages for global stuff...
	}


	;outp(0xE8, 4);	 
	;outpw(0xEA, EMS_MEMORY_PAGE_OFFSET + MUS_DATA_PAGES); // set default EMS pages for global stuff...
	;outp(0xE8, 5);	 
	;outpw(0xEA, 0x4D); // set default EMS pages for global stuff...
	;outp(0xE8, 6);	 
	;outpw(0xEA, 0x4E); // set default EMS pages for global stuff...
	outp(0xE8, 7);	 
	outpw(0xEA, EMS_MEMORY_PAGE_OFFSET + BSP_CODE_PAGE); // set default EMS page for bsp code?



	//todo do we disable config after?

	return MK_FP(EMS_PAGE, 0);
}

void __near Z_GetEMSPageMap() {
	int16_t i;

	// force cache clear
	currentpageframes[0] = 0xFF;
	currentpageframes[1] = 0xFF;
	currentpageframes[2] = 0xFF;
	currentpageframes[3] = 0xFF;

	for (i = 0; i <= ((numlumps-1) / LUMP_PER_EMS_PAGE); i++){
		Z_QuickMapWADPageFrame(i*LUMP_PER_EMS_PAGE);
		FAR_memcpy((byte __far *) lumpinfoD800, (byte __far *) lumpinfoinit + (i * 16384u), 16384u); // copy the wad lump stuff over. gross
	}

	Z_QuickMapMusicPageFrame(0);
	Z_QuickMapSFXPageFrame(0);
	Z_QuickMapWADPageFrame(0);
	// todo music driver?

	Z_QuickMapPhysics(); // map default page map
}
#elif defined(__SCAT_BUILD)


byte __far *__near Z_InitEMS() {
	EMS_PAGE = 0xD000; // hard coded
	return MK_FP(EMS_PAGE, 0);
}

void __near Z_GetEMSPageMap() {
	int16_t i;

	// force cache clear
	currentpageframes[0] = 0xFF;
	currentpageframes[1] = 0xFF;
	currentpageframes[2] = 0xFF;
	currentpageframes[3] = 0xFF;

	for (i = 0; i <= ((numlumps-1) / LUMP_PER_EMS_PAGE); i++){
		Z_QuickMapWADPageFrame(i*LUMP_PER_EMS_PAGE);
		FAR_memcpy((byte __far *) lumpinfoD800, (byte __far *) lumpinfoinit + (i * 16384u), 16384u); // copy the wad lump stuff over. gross
	}

	Z_QuickMapMusicPageFrame(0);
	Z_QuickMapSFXPageFrame(0);
	Z_QuickMapWADPageFrame(0);
	// todo music driver?

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

	// force cache clear
	currentpageframes[0] = 0xFF;
	currentpageframes[1] = 0xFF;
	currentpageframes[2] = 0xFF;
	currentpageframes[3] = 0xFF;

	for (i = 0; i <= ((numlumps-1) / LUMP_PER_EMS_PAGE); i++){
		Z_QuickMapWADPageFrame(i*LUMP_PER_EMS_PAGE);
		FAR_memcpy((byte __far *) lumpinfoD800, (byte __far *) lumpinfoinit + (i * 16384u), 16384u); // copy the wad lump stuff over. gross
	}

	Z_QuickMapMusicPageFrame(0);
	Z_QuickMapSFXPageFrame(0);
	Z_QuickMapWADPageFrame(0);
	// todo music driver?


	Z_QuickMapPhysics(); // map default page map
}

#else
byte __far *__near Z_InitEMS() {

	// 4 mb
	// todo test 3, 2 MB, etc. i know we use less..
	//int16_t numPagesToAllocate = NUM_EMS4_SWAP_PAGES; //256; //  (4 * 1024 * 1024) / PAGE_FRAME_SIZE;
	int16_t pageframebase;
	int8_t  i;
	reg_return_4word regresult;


	// todo check for device...
	// char	emmname[9] = "EMMXXXX0";


	int16_t_union result;

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

	result.hu = locallib_int86_67_1arg(0x4000);
	errorreg = result.bu.bytehigh;
	if (errorreg) {
		doerror(91, errorreg);
	}


	result.hu = locallib_int86_67_1arg(0x4600);
	vernum = result.bu.bytelow;
	errorreg = result.bu.bytehigh;
	if (errorreg != 0) {
		doerror(90, errorreg); // EMS Error 0x46
	}
	//DEBUG_PRINT("Version %i", vernum);
	if (vernum < 40) {
		doerror(92, vernum);
	}

	// get page frame address
	// regs.h.ah = 0x41;
	regresult.qword = locallib_int86_67_1arg_return(0x4100);

	pageframebase = regresult.w.bx;
	errorreg = regresult.h.ah;
	if (errorreg != 0) {
		doerror(89, errorreg);/// EMS Error 0x41
	}




	// regs.h.ah = 0x42;
	// intx86(EMS_INT, &regs, &regs);
	regresult.qword = locallib_int86_67_1arg_return(0x4200);
	// result.hu = locallib_int86_67_1arg(0x4200);
	pagesavail = regresult.w.bx;
	pagestotal = regresult.w.dx;
	DEBUG_PRINT("\n  %i pages total, %i pages available at frame %p", pagestotal, pagesavail, pageframebase);

	if (pagesavail < NUM_EMS4_SWAP_PAGES) {
		I_Error("\nERROR: minimum of %i EMS pages required", NUM_EMS4_SWAP_PAGES);
	}


	// regs.w.bx = NUM_EMS4_SWAP_PAGES; //numPagesToAllocate;
	// regs.h.ah = 0x43;
	// result.hu = locallib_int86_67_1arg(0x4300);
	// intx86(EMS_INT, &regs, &regs);
	regresult.qword = locallib_int86_67_3arg_return(0x4300, 0, NUM_EMS4_SWAP_PAGES);

	emshandle = regresult.w.dx;
	errorreg = regresult.h.ah;
	if (errorreg != 0) {
		// Error 0 = 0x00 = no error
		// Error 137 = 0x89 = zero pages
		// Error 136 = 0x88 = OUT_OF_LOG
		doerror(88, errorreg);// EMS Error 0x43
	}


	// do initial page remapping for ems page frame
	// regs.w.ax = 0x4400;  
	// regs.w.bx = MUS_DATA_PAGES;
	// regs.w.dx = emshandle; // handle
	// intx86(EMS_INT, &regs, &regs);
	locallib_int86_67(0x4400, emshandle, MUS_DATA_PAGES);

	// regs.w.ax = 0x4401;  
	// regs.w.bx = SFX_DATA_PAGES;
	// regs.w.dx = emshandle; // handle
	locallib_int86_67(0x4401, emshandle, SFX_DATA_PAGES);

	// regs.w.ax = 0x4402;
	// regs.w.bx = SFX_DATA_PAGES+1;
	// regs.w.dx = emshandle; // handle
	locallib_int86_67(0x4402, emshandle, FIRST_LUMPINFO_LOGICAL_PAGE);
	// intx86(EMS_INT, &regs, &regs);

	// DC00 bsp code setup
	// regs.w.ax = 0x4403;  
	// regs.w.bx = BSP_CODE_PAGE;
	// regs.w.dx = emshandle; // handle
	locallib_int86_67(0x4403, emshandle, BSP_CODE_PAGE);

	currentpageframes[0] = 0;
	currentpageframes[1] = NUM_MUSIC_PAGES;
	currentpageframes[2] = NUM_MUSIC_PAGES+1;	// todo
	currentpageframes[3] = NUM_MUSIC_PAGES+NUM_SFX_PAGES;

	// intx86(EMS_INT, &regs, &regs);


	//*size = numPagesToAllocate * PAGE_FRAME_SIZE;

	// EMS Handle
	EMS_PAGE = pageframebase;
	return  MK_FP(pageframebase, 0);



}

void __near Z_GetEMSPageMap() {
	int16_t pagedata[256]; // i dont think it can get this big...
	int16_t_union errorreg;
	int16_t i, numentries;

	reg_return_4word regresult;
 

	// regs.w.ax = 0x5801;  // physical page
	// intx86(EMS_INT, &regs, &regs);

	regresult.qword = locallib_int86_67_1arg_return(0x5801);
	
	numentries = regresult.w.cx;
	if (regresult.h.ah != 0) {
		doerror(84, regresult.h.ah);// Call 5801 failed with value %i!\n
	}

	// how weird. the call sometimes fails  if we dont do this?
	memset(pagedata, 0, 256);

	// regs.w.ax = 0x5800;  // physical page
	// segregs.es = segregs.ds;
	
	// regs.w.di = (int16_t)pagedata;
	// intx86(EMS_INT, &regs, &regs);
	
	// ax, di, es
	errorreg.hu= locallib_int86_67_esdi(0x5800, (uint16_t)pagedata, FIXED_DS_SEGMENT);

	//pagedata = MK_FP(sregs.es, regs.w.di);
	if (errorreg.bu.bytehigh != 0) {	
		doerror(83, errorreg.bu.bytehigh);// Call 25 failed with value %i!\n
	}
 
	for (i = 0; i < numentries; i++) {
		if (pagedata[i << 1] == 0x9000u) {
			pagenum9000 = pagedata[(i << 1) + 1];
			goto found;
		}
	}

	//I_Error("\nMappable page for segment 0x9000 NOT FOUND! EMS 4.0 features unsupported?\n");

found:

	 

	// todo this is old and out of date, but instructive.
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
	// 0x3CC0           (eventually) DS
	// 0x3200           sine/cosine/trig tables
	// 0x3000 block		
	// --------------------------------------------------------------------------------------------------------------------------------------------------


	for (i = 1; i < total_pages; i+= 2) {
		pageswapargs[i] += pagenum9000;
	}
	 

	
	for (i = 0; i <= ((numlumps-1) / LUMP_PER_EMS_PAGE); i++){
		Z_QuickMapWADPageFrame(i*LUMP_PER_EMS_PAGE);
		FAR_memcpy((byte __far *) lumpinfoD800, (byte __far *) lumpinfoinit + (i * 16384u), 16384u); // copy the wad lump stuff over. gross
	}

	Z_QuickMapPhysics(); // map default page map
}




#endif



 
void  __far P_InitThinkers (void);


void PSetupEndFunc();
void __far P_SetupLevel (int8_t episode, int8_t map, skill_t skill);
segment_t __far R_GetPatchTexture(int16_t lump, uint8_t maskedlookup) ;
segment_t __far R_GetCompositeTexture(int16_t tex_index) ;
void __far ST_Start(void) ;
void __far G_PlayerReborn ();



void __far G_ExitLevel (void);

 
void  __near SkipNextFileRegion(FILE* fp){
	uint16_t codesize;
	fread(&codesize, 2, 1, fp);
	fseek(fp, codesize, SEEK_CUR);
}

void  __near ReadFileRegionWithIndex(FILE* fp, int16_t index, uint32_t target_addr){
	uint16_t codesize;

	// low 8 bits of index is 
	// high 8 bits is total number
	//. i.e. 0x202 = 2nd of 2
	// function is kinda gross but serves to keep file size down for now.

	while (index >= 0)	{
		if ((index & 0xFF) == 0){
			fread(&codesize, 2, 1, fp);
			FAR_fread((byte __far*) target_addr, codesize, 1, fp);
		} else {
			fread(&codesize, 2, 1, fp);
			fseek(fp, codesize, SEEK_CUR);
		}

		index -= 0x101;
	}



}

void __near Z_RemapRenderFunctions(){


	#define  DRAWSPAN_AH_OFFSET  0x3F00
	#define  DRAWSPAN_BX_OFFSET  0x0FC0
	switch (columnquality){

		case 3:

			R_GetPatchTexture_addr =  			 (uint32_t) MK_FP(bsp_code_segment, R_GetPatchTextureFLOffset);
			R_GetCompositeTexture_addr =  		 (uint32_t) MK_FP(bsp_code_segment, R_GetCompositeTextureFLOffset);
			R_WriteBackMaskedFrameConstantsCallOffset  = R_WriteBackMaskedFrameConstantsFLOffset;
			R_DrawMaskedCallOffset =			 R_DrawMaskedFLOffset;
			R_RenderPlayerView = 				 MK_FP(bsp_code_segment,          		 R_RenderPlayerViewFLOffset);
			R_WriteBackViewConstantsMaskedCall = MK_FP(maskedconstants_funcarea_segment, R_WriteBackViewConstantsMaskedFLOffset);
			R_WriteBackViewConstants = 			 MK_FP(bsp_code_segment,          		 R_WriteBackViewConstantsFLOffset);

			break;

		case 2:

			R_GetPatchTexture_addr =  			 (uint32_t) MK_FP(bsp_code_segment, R_GetPatchTexture0Offset);
			R_GetCompositeTexture_addr =  		 (uint32_t) MK_FP(bsp_code_segment, R_GetCompositeTexture0Offset);
			R_WriteBackMaskedFrameConstantsCallOffset  = R_WriteBackMaskedFrameConstants0Offset;
			R_DrawMaskedCallOffset =			 R_DrawMasked0Offset;
			R_RenderPlayerView = 				 MK_FP(bsp_code_segment,          		 R_RenderPlayerView0Offset);
			R_WriteBackViewConstantsMaskedCall = MK_FP(maskedconstants_funcarea_segment, R_WriteBackViewConstantsMasked0Offset);
			R_WriteBackViewConstants = 			 MK_FP(bsp_code_segment,          		 R_WriteBackViewConstants0Offset);

			break;

		case 1:

			R_GetPatchTexture_addr =  			 (uint32_t) MK_FP(bsp_code_segment, R_GetPatchTexture16Offset);
			R_GetCompositeTexture_addr =  		 (uint32_t) MK_FP(bsp_code_segment, R_GetCompositeTexture16Offset);
			R_WriteBackMaskedFrameConstantsCallOffset  = R_WriteBackMaskedFrameConstants16Offset;
			R_DrawMaskedCallOffset =			 R_DrawMasked16Offset;
			R_RenderPlayerView = 				 MK_FP(bsp_code_segment,          		 R_RenderPlayerView16Offset);
			R_WriteBackViewConstantsMaskedCall = MK_FP(maskedconstants_funcarea_segment, R_WriteBackViewConstantsMasked16Offset);
			R_WriteBackViewConstants = 			 MK_FP(bsp_code_segment,          		 R_WriteBackViewConstants16Offset);
			break;



		// remap... todo

	}

	switch (spanquality){
		case 3:

			// remap this to the 16 bit version.
			R_DrawPlanesCallOffset = R_DrawPlanesFLOffset;
			R_WriteBackViewConstantsSpanCall = MK_FP(spanfunc_jump_lookup_segment, R_WriteBackViewConstantsSpanFLOffset);
			ds_source_offset = DRAWSPAN_AH_OFFSET;

			break;
		case 2:


			// remap this to the 16 bit version.
			R_DrawPlanesCallOffset = R_DrawPlanes0Offset;
			R_WriteBackViewConstantsSpanCall = MK_FP(spanfunc_jump_lookup_segment, R_WriteBackViewConstantsSpan0Offset);
			ds_source_offset = DRAWSPAN_AH_OFFSET;

			break;

		case 1:




			// remap this to the 16 bit version.
			R_DrawPlanesCallOffset = R_DrawPlanes16Offset;
			R_WriteBackViewConstantsSpanCall = MK_FP(spanfunc_jump_lookup_segment, R_WriteBackViewConstantsSpan16Offset);
			ds_source_offset = DRAWSPAN_BX_OFFSET;

			break;
		case 0:
		default:
			// remap this to the 24 bit version.
			R_DrawPlanesCallOffset = R_DrawPlanes24Offset;
			R_WriteBackViewConstantsSpanCall = MK_FP(spanfunc_jump_lookup_segment, R_WriteBackViewConstantsSpan24Offset);
			ds_source_offset = DRAWSPAN_AH_OFFSET;
	}


}

void __near Z_DoRenderCodeLoad(FILE* fp){

	// todo reorder so only two or three switches?

// todo R_GetCompositeTextureOffset

	// column stuff
	uint16_t codesize;
	int16_t usedcolumnvalue = 0x400;
	int16_t usedspanvalue = 0x400;
	if (columnquality <= 3){
		usedcolumnvalue += columnquality;		
	}
	if (spanquality <= 3){
		usedspanvalue += spanquality;
	}

	Z_RemapRenderFunctions();

	ReadFileRegionWithIndex(fp, usedcolumnvalue, (uint32_t)colfunc_jump_lookup_6800);




	// span stuff
	Z_QuickMapPalette();
	
		// dont love this defined here, but this will all be ASM soon enough anyway...
	ReadFileRegionWithIndex(fp, usedspanvalue, (uint32_t)spanfunc_jump_lookup_9000);


	// masked stuff
	Z_QuickMapMaskedExtraData();

	ReadFileRegionWithIndex(fp, usedcolumnvalue, (uint32_t)drawfuzzcol_area);
	ReadFileRegionWithIndex(fp, usedcolumnvalue, (uint32_t)maskedconstants_funcarea);

	Z_QuickMapRenderPlanes();

	fread(&codesize, 2, 1, fp);
	FAR_fread(drawskyplane_area, codesize, 1, fp);

	ReadFileRegionWithIndex(fp, usedcolumnvalue, (uint32_t)bsp_code_area);

}
 
void __near Z_LoadBinaries() {
	int16_t i;
	uint16_t codesize;
	FILE* fp = fopen("DOOMDATA.BIN", "rb"); 
	fseek(fp, DATA_DOOMDATA_OFFSET, SEEK_SET);
	// currently in physics region!
	
	FAR_fread(InfoFuncLoadAddr, 1, SIZE_D_INFO, fp);




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
	FAR_fread(doomednum_far, 2, NUMMOBJTYPES, fp);
	
	Z_QuickMapRender4000();
	// todo put in doomdata...
	for (i = 0; i < NUMSTATES; i++){
		states_render[i].sprite = states[i].sprite;
		states_render[i].frame  = states[i].frame;
	}


	//I_Error("\n%i %i %i %i", epsd1animinfo[2].period, epsd1animinfo[2].loc.x, anims[1][2].period, anims[1][2].loc.x);
 
	Z_QuickMapRender();

	//2048
	FAR_fread(zlight, 1, 2048, fp);

	fclose(fp);

	Z_QuickMapPhysics();


	fp = fopen("DOOMCODE.BIN", "rb"); 

	Z_DoRenderCodeLoad(fp);
	




	Z_QuickMapIntermission();
	fread(&codesize, 2, 1, fp);
	FAR_fread(wianim_codespace, codesize, 1, fp);
 
	Z_QuickMapPhysicsCode();
	fread(&codesize, 2, 1, fp);
	FAR_fread(psight_codespace, codesize, 1, fp);
	Z_QuickMapPhysics();


//todo should these be plus 2?
	codestartposition[0] = ftell(fp);

	fread(&codesize, 2, 1, fp);
	fseek(fp, codesize, SEEK_CUR);
	codestartposition[1] = ftell(fp);

	fread(&codesize, 2, 1, fp);
	fseek(fp, codesize, SEEK_CUR);
	codestartposition[2] = ftell(fp);

	fread(&codesize, 2, 1, fp);
	fseek(fp, codesize, SEEK_CUR);
	codestartposition[3] = ftell(fp);

	fread(&codesize, 2, 1, fp);
	fseek(fp, codesize, SEEK_CUR);
	codestartposition[4] = ftell(fp);

	for (i = 0; i < MUS_DRIVER_COUNT-1; i++){
		fread(&codesize, 2, 1, fp);
		fseek(fp, codesize, SEEK_CUR);
		musdriverstartposition[i] = ftell(fp);

	}




	//FAR_fread(code_overlay_start, codesize, 1, fp2);


	fclose(fp);







	DEBUG_PRINT("..");

	// manual runtime linking
 
	// set some function addresses for asm calls. 
	// as these move to asm and EMS memory space themselves, these references can go away
	// Z_QuickMapVisplanePage_addr = 	(uint32_t)(Z_QuickMapVisplanePage);
	
	// Z_QuickMapFlatPage_addr =   	(uint32_t)(Z_QuickMapFlatPage);
	
	W_CacheLumpNumDirect_addr = 	(uint32_t)(W_CacheLumpNumDirect);


	// Z_QuickMapPhysics_addr = 		(uint32_t)(Z_QuickMapPhysics);
	// Z_QuickMapWipe_addr = 			(uint32_t)(Z_QuickMapWipe);
	// Z_QuickMapScratch_5000_addr = 	(uint32_t)(Z_QuickMapScratch_5000);
	M_Random_addr = 				(uint32_t)(M_Random);
	NetUpdate_addr = 				(uint32_t)(NetUpdate);
	// I_UpdateNoBlit_addr = 			(uint32_t)(I_UpdateNoBlit);
	// I_FinishUpdate_addr = 			(uint32_t)(I_FinishUpdate);
	V_MarkRect_addr = 				(uint32_t)(V_MarkRect);
	M_Drawer_addr = 				(uint32_t)(M_Drawer);

	FixedMul_addr = 				(uint32_t)(FixedMul);
	FixedMul2432_addr = 			(uint32_t)(FixedMul2432);
	FixedDiv_addr =					(uint32_t)(FixedDiv);
	// FastDiv3232_addr = 				(uint32_t)(FastDiv3232FFFF);
	// R_GetPatchTexture_addr = 		(uint32_t)(R_GetPatchTexture);
	// R_GetCompositeTexture_addr = 	(uint32_t)(R_GetCompositeTexture);
	// R_GetSpriteTexture_addr = 		(uint32_t)(R_GetSpriteTexture);

	// todo think of a better solution for dynamic linking of func locations for overlaid code.
	V_DrawPatch_addr =			 		(uint32_t)(V_DrawPatch);
	locallib_toupper_addr =				(uint32_t)(locallib_toupper);
	S_ChangeMusic_addr =			 	(uint32_t)(S_ChangeMusic);
	V_DrawFullscreenPatch_addr =		(uint32_t)(V_DrawFullscreenPatch);
	getStringByIndex_addr =				(uint32_t)(getStringByIndex);
	locallib_strlen_addr =			 	(uint32_t)(locallib_strlen);
	// Z_QuickMapStatusNoScreen4_addr =	(uint32_t)(Z_QuickMapStatusNoScreen4);
	// Z_QuickMapRender7000_addr =		 	(uint32_t)(Z_QuickMapRender7000);
	// Z_QuickMapScreen0_addr =			(uint32_t)(Z_QuickMapScreen0);
	W_CacheLumpNameDirect_addr =		(uint32_t)(W_CacheLumpNameDirect);
	W_CacheLumpNumDirectFragment_addr =	(uint32_t)(W_CacheLumpNumDirectFragment);
	W_GetNumForName_addr =		 		(uint32_t)(W_GetNumForName);
	S_StartSound_addr =		 			(uint32_t)(S_StartSound);
	S_StartMusic_addr =		 			(uint32_t)(S_StartMusic);

	
	I_Error_addr =		 				(uint32_t)(I_Error);
	P_InitThinkers_addr =		 		(uint32_t)(P_InitThinkers);
	P_CreateThinker_addr =		 		(uint32_t)(P_CreateThinker);
	
	P_AddActiveCeiling_addr =		 	(uint32_t)(P_AddActiveCeiling);
	P_AddActivePlat_addr =		 		(uint32_t)(P_AddActivePlat);

	Z_SetOverlay_addr =	 				(uint32_t)(Z_SetOverlay);
	W_LumpLength_addr =	 				(uint32_t)(W_LumpLength);

	FixedMulTrigNoShift_addr =			(uint32_t)(FixedMulTrigNoShift);
	R_PointToAngle2_16_addr =			(uint32_t)(R_PointToAngle2_16);
	R_PointToAngle2_addr =				(uint32_t)(R_PointToAngle2);
	P_UseSpecialLine_addr =				(uint32_t)(P_UseSpecialLine);
	P_DamageMobj_addr =					(uint32_t)(P_DamageMobj);
	P_CrossSpecialLine_addr =			(uint32_t)(P_CrossSpecialLine);
	P_ShootSpecialLine_addr =			(uint32_t)(P_ShootSpecialLine);
	P_TouchSpecialThing_addr =			(uint32_t)(P_TouchSpecialThing);


	FixedMul16u32_addr =				(uint32_t)(FixedMul16u32);
	FastMul16u32u_addr =				(uint32_t)(FastMul16u32u);
	FastDiv3216u_addr =					(uint32_t)(FastDiv3216u);
	FixedMulTrigSpeedNoShift_addr =		(uint32_t)(FixedMulTrigSpeedNoShift);
	FixedMulTrigSpeed_addr =			(uint32_t)(FixedMulTrigSpeed);
	FixedMulTrig_addr =					(uint32_t)(FixedMulTrig);


	G_ExitLevel_addr =					(uint32_t)(G_ExitLevel);
	HU_Start_addr =						(uint32_t)(HU_Start);
	ST_Start_addr =						(uint32_t)(ST_Start);
	P_RemoveThinker_addr =				(uint32_t)(P_RemoveThinker);
	G_PlayerReborn_addr =				(uint32_t)(G_PlayerReborn);
	S_StopSoundMobjRef_addr =			(uint32_t)(S_StopSoundMobjRef);
 	EV_DoDoor_addr =					(uint32_t)(EV_DoDoor);
 	EV_DoFloor_addr =					(uint32_t)(EV_DoFloor);

}



