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





extern union REGS regs;


//
// Z_InitUMB
//





// based a bit off wolf3d and catacomb source code

//void(*XMSaddr) (void);		// far pointer to XMS driver
//uint16_t UMBbase = 0;
//uint16_t UMBsize = 0;
//byte __far* conventional_far_bytes = NULL;


/*

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
*/
 
// 54769 is how much we need currently for doom2
// size in paragraphs
//#define DESIRED_UMB_SIZE 0x0D60

//#define DESIRED_UMB_SIZE 0x0FFE

