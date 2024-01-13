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

#include <dos.h>
#include <conio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <graph.h>
#include <malloc.h>
#include "d_main.h"
#include "doomstat.h"
#include "doomdef.h"
#include "r_local.h"
#include "sounds.h"
#include "i_system.h"
#include "i_sound.h"
#include "g_game.h"
#include "m_misc.h"
#include "v_video.h"
#include "w_wad.h"
#include "z_zone.h"

extern boolean novideo; 
extern boolean grmode;


extern byte far *pcscreen;
extern byte far *currentscreen;
extern byte far *destview; 
extern fixed_t_union destscreen;
extern void (__interrupt __far *oldkeyboardisr) ();

extern boolean mousepresent;
extern boolean usemouse;

extern void __interrupt I_KeyboardISR(void);
extern int32_t I_ResetMouse(void);
extern void I_StartupSound(void);


#define KBDQUESIZE 32
extern byte keyboardque[KBDQUESIZE];
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


extern union REGS regs;
extern struct SREGS segregs;



//
// Disk icon flashing
//

void I_InitDiskFlash(void)
{
	/*
	//todo: when re-implementing, pull this out
	byte diskgraphicbtyes[392];// cdrom is 328 and can fit in here too.

	void *pic;
	fixed_t_union temp;

	if (M_CheckParm("-cdrom"))
	{
		pic = W_CacheLumpNameEMSAsPatch("STCDDISK", PU_CACHE);
	}
	else
	{
		pic = W_CacheLumpNameEMSAsPatch("STDISK", PU_CACHE);
	}
	temp = destscreen;
	destscreen.w = 0xac000000;
	V_DrawPatchDirect(SCREENWIDTH - 16, SCREENHEIGHT - 16, pic);
	destscreen = temp;
	*/
}


//
// I_InitGraphics
//
void I_InitGraphics(void)
{
	if (novideo)
	{
		return;
	}
	grmode = true;
	regs.w.ax = 0x13;
	intx86(0x10, (union REGS *)&regs, &regs);
	pcscreen = currentscreen = (byte far*) 0xA0000000L;
	destscreen.w = 0xA0004000;

	outp(SC_INDEX, SC_MEMMODE);
	outp(SC_INDEX + 1, (inp(SC_INDEX + 1)&~8) | 4);
	outp(GC_INDEX, GC_MODE);
	outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~0x13);
	outp(GC_INDEX, GC_MISCELLANEOUS);
	outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~2);
	outpw(SC_INDEX, 0xf02);
	memset(pcscreen, 0, 0xFFFF);
	outp(CRTC_INDEX, CRTC_UNDERLINE);
	outp(CRTC_INDEX + 1, inp(CRTC_INDEX + 1)&~0x40);
	outp(CRTC_INDEX, CRTC_MODE);
	outp(CRTC_INDEX + 1, inp(CRTC_INDEX + 1) | 0x40);
	outp(GC_INDEX, GC_READMAP);
	I_SetPalette(0);
	I_InitDiskFlash();
}




//
// StartupMouse
//

void I_StartupMouse(void)
{
	//
	// General mouse detection
	//
	mousepresent = 0;
	if (M_CheckParm("-nomouse") || !usemouse)
	{
		return;
	}

	if (I_ResetMouse() != 0xffff)
	{
		printf("Mouse: not present\n", 0);
		return;
	}
	printf("Mouse: detected\n", 0);

	mousepresent = 1;

	//I_StartupCyberMan();
}





//
// I_StartupKeyboard
//
void I_StartupKeyboard(void) {
	int8_t i = 0;
	for (i = 0; i < KBDQUESIZE; i++) {
		keyboardque[i] = 0;
	}

	oldkeyboardisr = _dos_getvect(KEYBOARDINT);
	_dos_setvect(KEYBOARDINT, I_KeyboardISR);
}


void I_StartupDPMI(void);

//
// I_Init
// hook interrupts and set graphics mode
//
void I_Init(void)
{
	novideo = M_CheckParm("novideo");

 

	printf("I_StartupMouse\n");
	I_StartupMouse();
	printf("I_StartupKeyboard\n");
	I_StartupKeyboard();
	printf("I_StartupSound\n");
	I_StartupSound();
}
