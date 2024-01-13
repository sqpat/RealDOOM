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

#include <dos.h>
#include <stdlib.h>
#include <malloc.h>





extern union REGS regs;


//
// Z_InitUMB
//





// based a bit off wolf3d and catacomb source code

void(*XMSaddr) (void);		// far pointer to XMS driver
uint16_t UMBbase = 0;
uint16_t UMBsize = 0;
uint16_t UMBbase2 = 0;
uint16_t UMBsize2 = 0;


#pragma aux XMS_GET_DRIVER = \
	"mov	ax, 0x4310",\
	"int	0x2f",\
	"mov[WORD PTR XMSaddr], bx",\
	"mov[WORD PTR XMSaddr + 2], es",\
	parm[] modify exact[ax bx es];


#pragma aux UMB_GET_BLOCK = \
		"mov    ah, 10h",          \
		"mov    dx, 0FFFh",          \
		"int    2Fh",                 \
		"call[DWORD PTR XMSaddr]",		\
		"or ax, ax",					\
		"jnz	gotone",				\
		"cmp	bl,0xb0",		\
		"jne	done",			\
	"gotone:",	\
		"mov[UMBbase],bx", \
		"mov[UMBsize],dx", \
	"done:",\
parm [  ] modify exact [ ax dx bx ];


#pragma aux CALL_5803_CHECK_CARRY = \
		"mov    ax, 5803h",          \
		"mov    bx, 0001h",          \
		"int    21h",                 \
		"call[DWORD PTR XMSaddr]",		\
		"or ax, ax",					\
		"jnz	gotone",				\
		"cmp	bl,0xb0",		\
		"jne	done",			\
	"gotone:",	\
		"mov[UMBbase],bx", \
		"mov[UMBsize],dx", \
	"done:",\
parm [  ] modify exact [ ax dx bx ];

 
// lets do only 60k.. .seems to be enough
#define DESIRED_UMB_SIZE 0x0EA6

void Z_InitUMBDOS(void) {

	uint16_t previousstrategy = 0;
	//uint16_t resultreg;
	uint16_t sizereg, umblinkstate;


	// GET UMB LINK STATE
	regs.w.ax = 0x5802;
	int86(DOSMM_INT, &regs, &regs);
	umblinkstate = regs.h.al;

	regs.w.ax = 0x5803;
	regs.w.bx = 0x0001;
	int86(DOSMM_INT, &regs, &regs);
	/* todo check carry flag for error
	resultreg = regs.w.ax;
	if (resultreg ) {
			I_Error("\n5803 error %p", 0, resultreg);
	}
	*/

	regs.w.ax = 0x5800;
	int86(DOSMM_INT, &regs, &regs);
	previousstrategy = regs.w.ax; // allocation strategy to restore on shutdown


	regs.w.ax = 0x5801;
	regs.w.bx = 0x0041;  // BEST_FIT_HIGHONLY  
	int86(DOSMM_INT, &regs, &regs);


	regs.w.ax = 0x4800;
	regs.w.bx = 0xffff;
	int86(DOSMM_INT, &regs, &regs);
	sizereg = regs.w.bx;

	UMBsize = DESIRED_UMB_SIZE << 4;


	DEBUG_PRINT("Found %lu bytes in UMB... looking for %u bytes", (16L * sizereg), UMBsize);

	if (sizereg < DESIRED_UMB_SIZE) {
		I_Error("\nError! Need 64k of UMB space! ");
	}

	regs.w.ax = 0x4800;
	regs.w.bx = DESIRED_UMB_SIZE;
	int86(DOSMM_INT, &regs, &regs);

	// todo check carry flag for error
	UMBbase = regs.w.ax;
	if (UMBbase < 0xA000) {
		I_Error("\nError! Allocated conventional instead of UMB space ");
	}
	
	DEBUG_PRINT("\n    Allocated %u at location... %p", UMBsize, 0, UMBbase);
	
	regs.w.ax = 0x4800;
	regs.w.bx = 0xffff;
	int86(DOSMM_INT, &regs, &regs);
	UMBsize2 = regs.w.bx;

	DEBUG_PRINT("\n  Remaining %lu bytes in UMB... looking for %u more bytes", (16L * UMBsize2), UMB2_SIZE);
	
	if ((UMBsize2) >= ((UMB2_SIZE >> 4) + 1)) {
		UMBsize2 = (UMB2_SIZE>>4) + 1; // enough for umb2 size

		regs.w.ax = 0x4800;
		regs.w.bx = UMBsize2;
		int86(DOSMM_INT, &regs, &regs);
		// todo check carry flag for error
		UMBbase2 = regs.w.ax;
		
		if (UMBbase2 < 0xA000) {
			I_Error("\nError! Allocated conventional instead of UMB space ");
		}
		
		UMBsize2 <<= 4;

		DEBUG_PRINT("\n    Allocated %u at location... %p", UMBsize2, 0, UMBbase2);

		regs.w.ax = 0x5801;
		regs.w.bx = previousstrategy;
		int86(DOSMM_INT, &regs, &regs);


	}
	else {
		// back to conventional
		regs.w.ax = 0x5803;
		regs.w.bx = 0;
		int86(DOSMM_INT, &regs, &regs);

		regs.w.ax = 0x5801;
		regs.w.bx = previousstrategy;
		int86(DOSMM_INT, &regs, &regs);

		regs.w.ax = 0x4800;
		regs.w.bx = 0xffff;
		int86(DOSMM_INT, &regs, &regs);
		UMBsize2 = regs.w.bx;
		DEBUG_PRINT("Not enough in UMB... \n  Remaining %u bytes in Conventional... ", UMBsize2 << 4);

		if ((UMBsize2 << 4) >= 7000) {
			UMBsize2 = 0x01B6; // enought for 0000
			regs.w.ax = 0x4800;
			regs.w.bx = UMBsize2;
			int86(DOSMM_INT, &regs, &regs);
			// todo check carry flag for error
			UMBbase2 = regs.w.ax; // technically not UMBs but...
			UMBsize2 <<= 4;
			DEBUG_PRINT("\n    Allocated %u at location... %p", UMBsize2, 0, UMBbase2);

		}
		else {
			I_Error("\nNot enough memory for sprites?! %u", UMBsize2 << 4);
		}
	}
 
	regs.w.ax = 0x5803;
	regs.w.bx = umblinkstate;
	int86(DOSMM_INT, &regs, &regs);
}


extern mobj_pos_t far* mobjposlist;
extern mobj_pos_t far* mobjposlist_render;
extern byte far*	   spritedefs_bytes;
void Z_InitUMB(void) {
	



	uint16_t offset = 0;
	DEBUG_PRINT("\n  Checking for UMB...");

	Z_InitUMBDOS();

	remainingconventional = STATIC_CONVENTIONAL_BLOCK_SIZE = UMBsize;
	conventionalmemoryblock = MK_FP(UMBbase, 0);

	spritedefs_bytes = MK_FP(UMBbase2, offset);
	offset += STATIC_CONVENTIONAL_SPRITE_SIZE;
	mobjposlist = MK_FP(UMBbase2, offset);
	offset += (MAX_THINKERS * sizeof(mobj_pos_t));

	


}

