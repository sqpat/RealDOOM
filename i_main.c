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

	if (ds != 0x3C00 || ss != 0x3C00){
		I_Error("\nvalues chaged! %x %x %i\n", ds, ss, a);
	}

	//DEBUG_PRINT("%i\n", a);

}
*/


void hackDS();
void hackDSBack();

int16_t main ( int16_t argc, int8_t** argv ) { 
    myargc = argc; 
    myargv = argv; 

	hackDS();

    D_DoomMain (); 

    return 0;
} 
