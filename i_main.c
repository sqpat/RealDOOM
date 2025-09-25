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
//
// DESCRIPTION:
//  Main program, simply calls D_DoomMain high level loop.
//

#include "doomdef.h"

//#include "m_misc.h"
#include "i_system.h"
#include <dos.h>
#include "m_near.h"


void __near D_DoomMain();
/*
// REGS stuff used for int calls

#define USED_DS 0x3A80
// size of dgroup, about?
#define SIZE_TO_COPY 0x5200

void modify_ds_ss(int a, int b);
#pragma aux modify_ds_ss = \
	"mov ax, 3A80h", \
	"mov ds, ax", \
	"mov ss, ax", \
parm[] modify exact[ax];

void hackDS() {
	struct SREGS        sregs;
	int16_t ds;
	int16_t ss;
	int16_t ds_diff;
	

	
	segread(&sregs);
	ds = sregs.ds; // 2a56 2e06 c7a
	ss = sregs.ss; // 2a56 2e06 c7a
	FAR_memcpy(MK_FP(USED_DS, 0), MK_FP(ds, 0), SIZE_TO_COPY);

	modify_ds_ss(USED_DS, USED_DS);


}


void checkDS(int16_t a) {
	struct SREGS        sregs;
	uint16_t ds;
	uint16_t ss;
	//byte __far* someptr = malloc(1);
	return;
	segread(&sregs);
	ds = sregs.ds; // 2a56 2e06 c7a
	ss = sregs.ss; // 2a56 2e06 c7a

	if (ds != FIXED_DS_SEGMENT || ss != FIXED_DS_SEGMENT){
		I_Error("\nvalues chaged! %x %x %i\n", ds, ss, a);
	}

	//DEBUG_PRINT("%i\n", a);

}
*/

// seems to be all we need ? mostly fread buffers now.
// _WCRTDATA unsigned _WCDATA _amblksiz = 0x100;
_WCRTDATA unsigned _WCDATA _amblksiz = 0x700;


void __near hackDS();



int16_t main ( int16_t argc, int8_t** argv ) { 
    myargc = argc; 
    myargv = argv; 

	// set DS to FIXED_DS_SEGMENT. we must also do this in interrupts.
	hackDS();
    D_DoomMain (); 

    return 0;
} 

void D_INIT_STARTMARKER();
void __near G_BeginRecording (void);
void __near D_DoomLoop (void);

void __near P_Init(void);


// clears dead initialization code.
void __near Z_ClearDeadCode() {
	byte __far *startaddr =	(byte __far*)D_INIT_STARTMARKER;
	byte __far *endaddr =		(byte __far*)P_Init;
	
	// accurate enough

	//8830 bytes or so
	//8978 currently - 05/29/24
	//8342           - 06/01/24
	//9350           - 10/07/24
	//11222          - 01/18/25		at this point like 3000 bytes to save.
	//11284          - 06/30/25   
	//11470          - 08/26/25
	//9798           - 09/12/25	   ; note 8196 is "max". or "min". there are probably some funcs that can be moved into init like wad or file funcs only used in init though.
	//9398           - 09/13/25	
	//9602           - 09/20/25	   - added some extra code into that region. still need to do z_init, p_init
	//9570           - 09/25/25	   

	uint16_t size = endaddr - startaddr-16;
	FILE* fp;


	angle_t __far*  dest;
	
	tantoangle_segment = FP_SEG(startaddr) + 1;
	// I_Error("size: %i", size);
	dest =  (angle_t __far* )MK_FP(tantoangle_segment, 0);
	fp = fopen("DOOMDATA.BIN", "rb");
	fseek(fp, TANTOA_DOOMDATA_OFFSET, SEEK_SET);
	locallib_far_fread(dest, 4 * 2049, fp);
	fclose(fp);

}

void __near D_DoomMain2(void);
void __near I_InitGraphics(void);


