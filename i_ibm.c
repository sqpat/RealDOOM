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

 


//#define NOKBD

//
// Code
//

void I_StartupNet(void);
void I_ShutdownNet(void);



void I_ReadMouse(void);

extern int32_t usemouse;




//
// Constants
//

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



#define ATR_INDEX               0x3c0
#define ATR_MODE                16
#define ATR_OVERSCAN            17
#define ATR_COLORPLANEENABLE    18
#define ATR_PELPAN              19
#define ATR_COLORSELECT         20

#define STATUS_REGISTER_1       0x3da

#define PEL_WRITE_ADR           0x3c8
#define PEL_READ_ADR            0x3c7
#define PEL_DATA                0x3c9
#define PEL_MASK                0x3c6

boolean grmode;


#define VBLCOUNTER 34000 // hardware tics to a frame


#define TIMERINT 8
#define KEYBOARDINT 9

#define CRTCOFF (_inbyte(STATUS_REGISTER_1)&1)
#define CLI     _disable()
#define STI     _enable()

#define _outbyte(x,y) (outp(x,y))
#define _outhword(x,y) (outpw(x,y))

#define _inbyte(x) (inp(x))
#define _inhword(x) (inpw(x))

#define MOUSEB1 1
#define MOUSEB2 2
#define MOUSEB3 4

boolean mousepresent;

volatile uint32_t ticcount;

// REGS stuff used for int calls
union REGS regs;
struct SREGS segregs;

boolean novideo; // if true, stay in text mode for debugging

#define KBDQUESIZE 32
byte keyboardque[KBDQUESIZE];
int32_t kbdtail, kbdhead;

#define KEY_LSHIFT      0xfe

#define KEY_INS         (0x80+0x52)
#define KEY_DEL         (0x80+0x53)
#define KEY_PGUP        (0x80+0x49)
#define KEY_PGDN        (0x80+0x51)
#define KEY_HOME        (0x80+0x47)
#define KEY_END         (0x80+0x4f)

#define SC_RSHIFT       0x36
#define SC_LSHIFT       0x2a
void I_WaitVBL(int16_t vbls);
void I_ShutdownSound(void);
void I_ShutdownTimer(void);

byte scantokey[128] =
{
//  0           1       2       3       4       5       6       7
//  8           9       A       B       C       D       E       F
        0  ,    27,     '1',    '2',    '3',    '4',    '5',    '6',
        '7',    '8',    '9',    '0',    '-',    '=',    KEY_BACKSPACE, 9, // 0
        'q',    'w',    'e',    'r',    't',    'y',    'u',    'i',
        'o',    'p',    '[',    ']',    13 ,    KEY_RCTRL,'a',  's',      // 1
        'd',    'f',    'g',    'h',    'j',    'k',    'l',    ';',
        39 ,    '`',    KEY_LSHIFT,92,  'z',    'x',    'c',    'v',      // 2
        'b',    'n',    'm',    ',',    '.',    '/',    KEY_RSHIFT,'*',
        KEY_RALT,' ',   0  ,    KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5,   // 3
        KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10,0  ,    0  , KEY_HOME,
        KEY_UPARROW,KEY_PGUP,'-',KEY_LEFTARROW,'5',KEY_RIGHTARROW,'+',KEY_END, //4
        KEY_DOWNARROW,KEY_PGDN,KEY_INS,KEY_DEL,0,0,             0,              KEY_F11,
        KEY_F12,0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0,        // 5
        0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0,
        0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0,        // 6
        0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0,
        0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0         // 7
};


#ifdef _M_I86
union REGS in, out;
#else
#endif

//
// User input
//

//
// I_WaitVBL
//
void I_WaitVBL(int16_t vbls)
{
	int16_t stat;

    if (novideo)
    {
        return;
    }
    while (vbls--)
    {
        do
        {
            stat = inp(STATUS_REGISTER_1);
            if (stat & 8)
            {
                break;
            }
        } while (1);
        do
        {
            stat = inp(STATUS_REGISTER_1);
            if ((stat & 8) == 0)
            {
                break;
            }
        } while (1);
    }
}

extern MEMREF palRef;
//
// I_SetPalette
// Palette source must use 8 bit RGB elements.
//
void I_SetPalette(int8_t paletteNumber)
{
	int16_t i;
    byte* palette = ((byte*) Z_LoadBytesFromEMS(palRef)) + paletteNumber * 768;

        if(novideo)
        {
                return;
        }
        I_WaitVBL(1);
#ifndef	SKIP_DRAW
		_outbyte(PEL_WRITE_ADR, 0);
#endif
        for(i = 0; i < 768; i++)
        {
#ifndef	SKIP_DRAW
//			_outbyte(PEL_DATA, (gammatable[usegamma][*palette++]) >> 2);
			_outbyte(PEL_DATA, gammatable[usegamma][*palette] >> 2);
			palette++;

#endif
        }
}

//
// Graphics mode
//

byte *pcscreen, *currentscreen, *destview;
fixed_t_union destscreen;

//
// I_UpdateBox
//
void I_UpdateBox(int16_t x, int16_t y, int16_t w, int16_t h)
{
	uint16_t i, j, k, count;
	int16_t sp_x1, sp_x2;
	uint16_t poffset;
	uint16_t offset;
	int16_t pstep;
	int16_t step;
    byte *dest, *source;
 
    sp_x1 = x / 8;
    sp_x2 = (x + w) / 8;
    count = sp_x2 - sp_x1 + 1;
    offset = (uint16_t)y * SCREENWIDTH + sp_x1 * 8;
    step = SCREENWIDTH - count * 8;
    poffset = offset / 4;
    pstep = step / 4;
#ifndef	SKIP_DRAW
	outp(SC_INDEX, SC_MAPMASK);
#endif
    for (i = 0; i < 4; i++)
    {
#ifndef	SKIP_DRAW
		outp(SC_INDEX + 1, 1 << i);
#endif
        source = &screen0[offset + i];
        dest = (byte*) (destscreen.w + poffset);
		TEXT_MODE_DEBUG_PRINT("I_UpdateBox to dest %lx", dest);

        for (j = 0; j < h; j++)
        {
            k = count;
            while (k--)
            {
#ifndef	SKIP_DRAW
				*(uint16_t *)dest = (uint16_t)(((*(source + 4)) << 8) + (*source));
#endif
                dest += 2;
                source += 8;
            }

            source += step;
            dest += pstep;
        }
    }
}

//
// I_UpdateNoBlit
//
int16_t olddb[2][4];
void I_UpdateNoBlit(void)
{
	int16_t realdr[4];
	int16_t x, y, w, h;
    // Set current screen
    currentscreen = (byte*) destscreen.w;

    // Update dirtybox size
    realdr[BOXTOP] = dirtybox[BOXTOP];
    if (realdr[BOXTOP] < olddb[0][BOXTOP])
    {
        realdr[BOXTOP] = olddb[0][BOXTOP];
    }
    if (realdr[BOXTOP] < olddb[1][BOXTOP])
    {
        realdr[BOXTOP] = olddb[1][BOXTOP];
    }

    realdr[BOXRIGHT] = dirtybox[BOXRIGHT];
    if (realdr[BOXRIGHT] < olddb[0][BOXRIGHT])
    {
        realdr[BOXRIGHT] = olddb[0][BOXRIGHT];
    }
    if (realdr[BOXRIGHT] < olddb[1][BOXRIGHT])
    {
        realdr[BOXRIGHT] = olddb[1][BOXRIGHT];
    }

    realdr[BOXBOTTOM] = dirtybox[BOXBOTTOM];
    if (realdr[BOXBOTTOM] > olddb[0][BOXBOTTOM])
    {
        realdr[BOXBOTTOM] = olddb[0][BOXBOTTOM];
    }
    if (realdr[BOXBOTTOM] > olddb[1][BOXBOTTOM])
    {
        realdr[BOXBOTTOM] = olddb[1][BOXBOTTOM];
    }

    realdr[BOXLEFT] = dirtybox[BOXLEFT];
    if (realdr[BOXLEFT] > olddb[0][BOXLEFT])
    {
        realdr[BOXLEFT] = olddb[0][BOXLEFT];
    }
    if (realdr[BOXLEFT] > olddb[1][BOXLEFT])
    {
        realdr[BOXLEFT] = olddb[1][BOXLEFT];
    }

    // Leave current box for next update
    memcpy(olddb[0], olddb[1], 8);
    memcpy(olddb[1], dirtybox, 8);
	/*
	olddb[0][0] = olddb[1][0];
	olddb[0][1] = olddb[1][1];
	olddb[0][2] = olddb[1][2];
	olddb[0][3] = olddb[1][3];
	olddb[1][0] = dirtybox[0];
	olddb[1][1] = dirtybox[1];
	olddb[1][2] = dirtybox[2];
	olddb[1][3] = dirtybox[3];
	*/

    // Update screen
    if (realdr[BOXBOTTOM] <= realdr[BOXTOP])
    {
        x = realdr[BOXLEFT];
        y = realdr[BOXBOTTOM];
        w = realdr[BOXRIGHT] - realdr[BOXLEFT] + 1;
        h = realdr[BOXTOP] - realdr[BOXBOTTOM] + 1;
        I_UpdateBox(x, y, w, h);
    }
	// Clear box

	dirtybox[BOXTOP] = dirtybox[BOXRIGHT] = MINSHORT;
	dirtybox[BOXBOTTOM] = dirtybox[BOXLEFT] = MAXSHORT;
}

//
// I_FinishUpdate
//
void I_FinishUpdate(void)
{

#ifndef	SKIP_DRAW
	outpw(CRTC_INDEX, (destscreen.h.fracbits & 0xff00L) + 0xc);

#endif
    //Next plane
    destscreen.h.fracbits += 0x4000;
	if ((uint16_t)destscreen.h.fracbits == 0xc000) {
		destscreen.h.fracbits = 0x0000;
	}
 
}


//
// I_ShutdownGraphics
//
void I_ShutdownGraphics(void)
{
    if (*(byte *)0x449 == 0x13) // don't reset mode if it didn't get set
    {
        regs.w.ax = 3;
#ifndef	SKIP_DRAW
		intx86(0x10, &regs, &regs); // back to text mode
		//I_Error("shutdown successful");
#endif
    }
}


#ifndef SKIPWIPE

//
// I_ReadScreen
// Reads the screen currently displayed into a linear buffer.
//
void I_ReadScreen(byte *scr)
{
	uint16_t i;
	uint16_t j;

#ifndef	SKIP_DRAW
	outp(GC_INDEX, GC_READMAP);
#endif
        for (i = 0; i < 4; i++)
        {
#ifndef	SKIP_DRAW
			outp(GC_INDEX+1, i);
#endif
                for (j = 0; j < SCREENWIDTH*SCREENHEIGHT/4; j++)
                {
#ifndef	SKIP_DRAW
					scr[i+j*4] = currentscreen[j];
#endif
                }
        }
}
#endif


//
// I_StartTic
//
// called by D_DoomLoop
// called before processing each tic in a frame
// can call D_PostEvent
// asyncronous interrupt functions should maintain private ques that are
// read by the syncronous functions to be converted into events
//


#define SC_UPARROW      0x48
#define SC_DOWNARROW    0x50
#define SC_LEFTARROW    0x4b
#define SC_RIGHTARROW   0x4d

void I_StartTic(void)
{
	uint8_t k;
	event_t ev;

	I_ReadMouse();


	//
	// keyboard events
	//
	while (kbdtail < kbdhead) {
		k = keyboardque[kbdtail&(KBDQUESIZE - 1)];
		kbdtail++;
		// extended keyboard shift key bullshit
		if ((k & 0x7f) == SC_LSHIFT || (k & 0x7f) == SC_RSHIFT) {
			if (keyboardque[(kbdtail - 2)&(KBDQUESIZE - 1)] == 0xe0)
			{
				continue;
			}
			k &= 0x80;
			k |= SC_RSHIFT;
		}

		if (k == 0xe0) {
			continue;   // special / pause keys
		}
		if (keyboardque[(kbdtail - 2)&(KBDQUESIZE - 1)] == 0xe1) {
			continue;   // pause key bullshit
		}
		if (k == 0xc5 && keyboardque[(kbdtail - 2)&(KBDQUESIZE - 1)] == 0x9d) {
			ev.type = ev_keydown;
			ev.data1 = KEY_PAUSE;
			D_PostEvent(&ev);
			continue;
		}

		if (k & 0x80)
			ev.type = ev_keyup;
		else
			ev.type = ev_keydown;
		k &= 0x7f;
		switch (k) {
			case SC_UPARROW:
				ev.data1 = KEY_UPARROW;
				break;
			case SC_DOWNARROW:
				ev.data1 = KEY_DOWNARROW;
				break;
			case SC_LEFTARROW:
				ev.data1 = KEY_LEFTARROW;
				break;
			case SC_RIGHTARROW:
				ev.data1 = KEY_RIGHTARROW;
				break;
			default:
				ev.data1 = scantokey[k];

				break;
		}
		D_PostEvent(&ev);
	}
}
 

//
// Timer interrupt
//


//
// I_TimerISR
//
void I_TimerISR(void)
{
    ticcount++;
    return ;
}

//
// Keyboard
//

void (__interrupt __far *oldkeyboardisr) () = NULL;


//
// I_KeyboardISR
//

void __interrupt I_KeyboardISR(void)
{
// Get the scan code
	byte value = _inbyte(0x60);
    keyboardque[kbdhead&(KBDQUESIZE - 1)] = value;

	kbdhead++;

// acknowledge the interrupt

    _outbyte(0x20, 0x20);
}



void I_ShutdownKeyboard(void)
{
        if (oldkeyboardisr)
                _dos_setvect (KEYBOARDINT, oldkeyboardisr);
        *(int16_t *)0x41c = *(int16_t *)0x41a;      // clear bios key buffer
}

void I_ShutdownMemory(void)
{
	Z_ShutdownEMS();
}

//
// Mouse
//

int32_t I_ResetMouse(void)
{
        regs.w.ax = 0; // reset
        intx86 (0x33, &regs, &regs);
        return regs.w.ax;
}



//
// ShutdownMouse
//
void I_ShutdownMouse(void)
{
    if (!mousepresent)
    {
        return;
    }

    I_ResetMouse();
}



#ifndef STATIC_ALLOCATED_SCREENS

uint32_t realstackseg;

#ifdef _M_I86
//
// I_AllocLow
//
byte *I_AllocLow(filelength_t length)
{
	byte *mem;
	mem = _fmalloc(length);
	if (mem == NULL) {
		I_Error("Error: Couldn't malloc length %li", length);
	}
	memset(mem, 0, length);
	return mem;
}

#else
//
// DPMIInt
//




//
// I_AllocLow
//
byte *I_AllocLow(int32_t length)
{
	byte *mem;

	// DPMI call 100h allocates DOS memory
	segread(&segregs);
	regs.w.ax = 0x0100; // DPMI allocate DOS memory
	regs.w.bx = (length + 15) / 16;
	intx86(DPMI_INT, &regs, &regs);
	//segment = regs.w.ax;
	//selector = regs.w.dx;
	if (regs.w.cflag != 0)
	{
		I_Error("I_AllocLow: DOS alloc of %i failed, %i free",
			length, regs.w.bx * 16);
	}

	mem = (void *)((regs.x.eax & 0xFFFF) << 4);

	memset(mem, 0, length);
	return mem;
}



//
// I_StartupDPMI
//

void I_StartupDPMI(void)
{
	extern int8_t __begtext;
	extern int8_t ___Argc;

	//
	// allocate a decent stack for real mode ISRs
	//
	realstackseg = (int32_t)I_AllocLow(1024) >> 4;

}



typedef struct
{
	uint32_t        edi, esi, ebp, reserved, ebx, edx, ecx, eax;
	uint16_t  flags, es, ds, fs, gs, ip, cs, sp, ss;
} dpmiregs_t;

extern dpmiregs_t dpmiregs;
dpmiregs_t dpmiregs;
#define REALSTACKSIZE 1024

void DPMIInt(int32_t i)
{
	dpmiregs.ss = realstackseg;
	dpmiregs.sp = REALSTACKSIZE - 4;

	segread(&segregs);
	regs.w.ax = 0x300;
	regs.w.bx = i;
	regs.w.cx = 0;
	regs.x.edi = (uint32_t)&dpmiregs;
	segregs.es = segregs.ds;
	intx86x(DPMI_INT, &regs, &regs, &segregs);
}


#endif

#endif


//
// I_ReadMouse
//
void I_ReadMouse(void)
{
    event_t ev;

    //
    // mouse events
    //
    if (!mousepresent)
    {
        return;
    }

    ev.type = ev_mouse;


#ifdef _M_I86

	// 16 bit version
	in.x.ax = 3;  // read buttons / position
	int86(0X33, &in, &out);

	ev.data1 = out.x.bx;

	in.x.ax = 11;  // read counters
	ev.data2 = out.x.cx;
	ev.data3 = -out.x.dx;
#else
	//32 bit version
	memset(&dpmiregs, 0, sizeof(dpmiregs));
	dpmiregs.eax = 3;   // read buttons / position
	DPMIInt(0x33);
	ev.data1 = dpmiregs.ebx;

	dpmiregs.eax = 11;  // read counters
	DPMIInt(0x33);
	ev.data2 = (int16_t)dpmiregs.ecx;
	ev.data3 = -(int16_t)dpmiregs.edx;


#endif



	D_PostEvent(&ev);


}

 




 


//
// I_Shutdown
// return to default system state
//
void I_Shutdown(void)
{
    I_ShutdownGraphics();
    I_ShutdownSound();
    I_ShutdownTimer();
    I_ShutdownMouse();
    I_ShutdownKeyboard();
	I_ShutdownMemory();
}

//
// I_Error
//
void I_Error (int8_t *error, ...)
{
    va_list argptr;
	printf(error, argptr);
    I_Shutdown();
    va_start(argptr, error);
    vprintf(error, argptr);
    va_end(argptr);
    printf("\n");
    exit(1);
}

//
// I_Quit
//
// Shuts down net game, saves defaults, prints the exit text message,
// goes to text mode, and exits.
//
void I_Quit(void)
{
    byte *scr;
	MEMREF scrRef;
    if (demorecording)
    {
        G_CheckDemoStatus();
    }

	M_SaveDefaults();
    scrRef = W_CacheLumpNameEMS("ENDOOM", PU_CACHE);
    I_ShutdownGraphics();
    I_ShutdownSound();
    I_ShutdownTimer();
    I_ShutdownMouse();
    I_ShutdownKeyboard();
	Z_ShutdownEMS();

	scr = Z_LoadBytesFromEMS(scrRef);
    memcpy((void *)0xb8000, scr, 80 * 25 * 2);
    regs.w.ax = 0x0200;
    regs.h.bh = 0;
    regs.h.dl = 0;
    regs.h.dh = 23;
	intx86(0x10, (union REGS *)&regs, &regs); // Set text pos

    printf("\n");

    exit(0);
}


// draw disk icon
void I_BeginRead(void)
{
	/*

    byte *src, *dest;
	int32_t y;

    if (!grmode)
    {
        return;
    }

#ifndef	SKIP_DRAW
	// write through all planes
    outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, 15);
    // set write mode 1
    outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);
#endif
    // copy to backup
    src = currentscreen + 184 * 80 + 304 / 4;
#ifdef _M_I86
	dest = 0xac000000 + 184 * 80 + 288 / 4;
#else
	dest = (byte *)0xac000 + 184 * 80 + 288 / 4;
#endif
    for (y = 0; y<16; y++)
    {
#ifndef	SKIP_DRAW
		dest[0] = src[0];
        dest[1] = src[1];
        dest[2] = src[2];
        dest[3] = src[3];
#endif
        src += 80;
        dest += 80;
    }

    // copy disk over
    dest = currentscreen + 184 * 80 + 304 / 4;
#ifdef _M_I86
	src = 0xac000000 + 184 * 80 + 304 / 4;
#else
	src = (byte *)0xac000 + 184 * 80 + 304 / 4;
#endif
    for (y = 0; y<16; y++)
    {
#ifndef	SKIP_DRAW
		dest[0] = src[0];
        dest[1] = src[1];
        dest[2] = src[2];
        dest[3] = src[3];
#endif
        src += 80;
        dest += 80;
    }


    // set write mode 0
#ifndef	SKIP_DRAW
	outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
#endif
	*/
}

// erase disk icon
void I_EndRead(void)
{
	/*
    byte *src, *dest;
	int32_t y;

    if (!grmode)
    {
        return;
    }

    // write through all planes
#ifndef	SKIP_DRAW
	outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, 15);
#endif
    // set write mode 1
#ifndef	SKIP_DRAW
	outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);
#endif

    // copy disk over
    dest = currentscreen + 184 * 80 + 304 / 4;
#ifdef _M_I86
	src = 0xac000000 + 184 * 80 + 288 / 4;
#else
	src = (byte *)0xac000 + 184 * 80 + 288 / 4;
#endif
    for (y = 0; y<16; y++)
    {
#ifndef	SKIP_DRAW
		dest[0] = src[0];
        dest[1] = src[1];
        dest[2] = src[2];
        dest[3] = src[3];
#endif
        src += 80;
        dest += 80;
    }

    // set write mode 0
#ifndef	SKIP_DRAW
	outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
#endif
	*/
}
