//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 1993-2008 Raven Software
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
//  IBM DOS VGA graphics and key/mouse.
//

#include "doomdef.h"

#include <dos.h>
#include <conio.h>
#include <graph.h>

#include <stdlib.h>
#include <stdarg.h>
#include "d_main.h"
#include "doomstat.h"
#include "r_local.h"
#include "sounds.h"
#include "i_system.h"
#include "i_sound.h"
#include "g_game.h"
#include "m_misc.h"
#include "v_video.h"
#include "w_wad.h"
#include "z_zone.h"
#include "m_near.h"
void __interrupt I_KeyboardISR(void);
int16_t __near I_ResetMouse(void);
void __near I_StartupSound(void);


#define KBDQUESIZE 32
#define KEYBOARDINT 9


#define GC_INDEX                0x3CE
#define GC_SETRESET             0
#define GC_ENABLESETRESET       1
#define GC_COLORCOMPARE         2
#define GC_DATAROTATE           3
#define GC_READMAP              4
#define GC_MODE                 5
#define GC_MISCELLANEOUS        6
#define GC_COLORDONTCARE        7
#define GC_BITMASK              8


#define SC_INDEX                0x3C4
#define SC_RESET                0
#define SC_CLOCK                1
#define SC_MAPMASK              2
#define SC_CHARMAP              3
#define SC_MEMMODE              4

#define CRTC_INDEX              0x3D4
#define CRTC_H_TOTAL            0
#define CRTC_H_DISPEND          1
#define CRTC_H_BLANK            2
#define CRTC_H_ENDBLANK         3
#define CRTC_H_RETRACE          4
#define CRTC_H_ENDRETRACE       5
#define CRTC_V_TOTAL            6
#define CRTC_OVERFLOW           7
#define CRTC_ROWSCAN            8
#define CRTC_MAXSCANLINE        9
#define CRTC_CURSORSTART        10
#define CRTC_CURSOREND          11
#define CRTC_STARTHIGH          12
#define CRTC_STARTLOW           13
#define CRTC_CURSORHIGH         14
#define CRTC_CURSORLOW          15
#define CRTC_V_RETRACE          16
#define CRTC_V_ENDRETRACE       17
#define CRTC_V_DISPEND          18
#define CRTC_OFFSET             19
#define CRTC_UNDERLINE          20
#define CRTC_V_BLANK            21
#define CRTC_V_ENDBLANK         22
#define CRTC_MODE               23
#define CRTC_LINECOMPARE        24







int16_t __near M_CheckParm (int8_t *check);


//
// StartupMouse
//

void __near I_StartupMouse(void) {
	//
	// General mouse detection
	//
	mousepresent = 0;
	if (M_CheckParm("-nomouse") || !usemouse) {
		return;
	}

	if (I_ResetMouse() != 0xffffu) {
		DEBUG_PRINT("Mouse: not present\n", 0);
		return;
	}
	DEBUG_PRINT("Mouse: detected\n", 0);

	mousepresent = 1;

	//I_StartupCyberMan();
}


void __interrupt I_KeyboardISR(void);
void __near I_StartupKeyboard(void);


//
// I_StartupKeyboard
//
/*
*/

 
//
// I_Init
// hook interrupts and set graphics mode
//
void __near I_Init(void) {
	novideo = M_CheckParm("-nodraw");
	DEBUG_PRINT("I_StartupMouse\n");
	I_StartupMouse();
	DEBUG_PRINT("I_StartupKeyboard\n");
	I_StartupKeyboard();
	DEBUG_PRINT("I_StartupSound\n");
	I_StartupSound();

}
