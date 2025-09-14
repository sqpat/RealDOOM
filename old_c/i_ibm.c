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
#include <graph.h>

#include <stdlib.h>
#include <stdarg.h>
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
#include "st_stuff.h"

#include "m_memory.h"
#include "m_near.h"




//#define NOKBD

//
// Code
//
 








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

#define KBDQUESIZE 32






//
// User input
//

//
// I_WaitVBL
//
void __far I_WaitVBL(int16_t vbls){
	int16_t stat;

    if (novideo) {
        return;
    }
    while (vbls--) {
        do {
            stat = inp(STATUS_REGISTER_1);
            if (stat & 8) {
                break;
            }
        } while (1);
        do {
            stat = inp(STATUS_REGISTER_1);
            if ((stat & 8) == 0) {
                break;
            }
        } while (1);
    }
}

//
// I_SetPalette
// Palette source must use 8 bit RGB elements.
//

/*
void __near I_SetPalette(int8_t paletteNumber) {
	byte __far* gammatablelookup;
	int16_t i;
	int16_t_union biggamma; 

	byte __far* palette = palettebytes + paletteNumber * 768u;
	//byte __far* palette = MK_FP(0x9000,  FastMul1616(paletteNumber, 768));
	int8_t savedtask = currenttask;
	
    if(novideo) {
        return;
    }

	I_WaitVBL(1);
	Z_QuickMapPalette();

	_outbyte(PEL_WRITE_ADR, 0);
	biggamma.b.bytelow = 0;
	biggamma.b.bytehigh = usegamma;
	gammatablelookup = MK_FP(gammatable_segment, biggamma.h);

	// todo outsb?
	for(i = 0; i < 768; i++) {
 		_outbyte(PEL_DATA, gammatablelookup[*palette] >> 2);
		palette++;
    }

	Z_QuickMapByTaskNum(savedtask);

}

//
// Graphics mode
//


//
// I_UpdateBox
//
void __near I_UpdateBox(int16_t x, int16_t y, int16_t w, int16_t h) {
	uint16_t i, j, k, count;
	int16_t sp_x1, sp_x2;
	uint16_t poffset;
	uint16_t offset;
	int16_t pstep;
	int16_t step;
	byte __far *dest;
	byte __far *source;
 
    sp_x1 = x >> 3;
    sp_x2 = (x + w) >> 3;
    count = sp_x2 - sp_x1 + 1;
    offset = (uint16_t)y * SCREENWIDTH + (sp_x1 << 3);
    step = SCREENWIDTH - (count << 3);
    poffset = offset >> 2;
    pstep = step >> 2;
	outp(SC_INDEX, SC_MAPMASK);
    for (i = 0; i < 4; i++) {
		outp(SC_INDEX + 1, 1 << i);
        source = &screen0[offset + i];
        dest = (byte __far*) (destscreen.w + poffset);

        for (j = 0; j < h; j++) {
            k = count;
            while (k--) {
				*(uint16_t __far *)dest = (uint16_t)(((*(source + 4)) << 8) + (*source));
                dest += 2;
                source += 8;
            }

            source += step;
            dest += pstep;
        }
    }
} 
//
// I_FinishUpdate
//
void __far I_FinishUpdate(void) {


	outpw(CRTC_INDEX, (destscreen.h.fracbits & 0xff00L) + 0xc);
    
	//Next plane
    destscreen.h.fracbits += 0x4000;
	if ((uint16_t)destscreen.h.fracbits == 0xc000) {
		destscreen.h.fracbits = 0x0000;
	}

    #ifdef FPS_DISPLAY
	    fps_rendered_frames_since_last_measure++;
    #endif
 
}
*/




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


 
//
// I_ReadMouse
//
void __near I_ReadMouse(void) {

    event_t ev;
	reg_return_4word regresult;

    //
    // mouse events
    //

    ev.type = ev_mouse;



	// 16 bit version
	// in.x.ax = 0x03;  // read buttons / position
	// int86(0x33, &in, &out);
	regresult.qword = locallib_int86_33(0x0003);



	ev.data1 = regresult.w.bx;
	// in.x.ax = 0x0B;  // read counters
	// int86(0x33, &in, &out);
	locallib_int86_33(0x000B);

	ev.data2 = regresult.w.cx;
	//ev.data3 = -out.x.dx; // dont use mouse forward/back movement
	ev.data3 = 0;
	D_PostEvent(&ev);


}

/*
void __near I_StartTic(void) {

	uint8_t k;
	event_t ev;
	
    if (mousepresent){
		I_ReadMouse();
	}


	//
	// keyboard events
	//
	while (kbdtail < kbdhead) {

		if (kbdtail > KBDQUESIZE && kbdhead > KBDQUESIZE) {
			kbdtail -= KBDQUESIZE;
			kbdhead -= KBDQUESIZE;
		}

		k = keyboardque[kbdtail&(KBDQUESIZE - 1)];
		kbdtail++;
		// extended keyboard shift key bullshit
		if ((k & 0x7f) == SC_LSHIFT || (k & 0x7f) == SC_RSHIFT) {
			if (keyboardque[(kbdtail - 2)&(KBDQUESIZE - 1)] == 0xe0) {
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

		if (k & 0x80) {
			ev.type = ev_keyup;
		} else {
			ev.type = ev_keydown;
		}
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
 */

//
// Timer interrupt
//


//
// I_TimerISR
//
void	resetDS();
// void I_TimerISR(void) {
// 	//resetDS();
//     ticcount++;
//     return ;
// }

//
// Keyboard
//


//
// I_KeyboardISR
//

/*
void __interrupt I_KeyboardISR(void) {
// Get the scan code
	byte value;
	resetDS();

	 value = _inbyte(0x60);
    keyboardque[kbdhead&(KBDQUESIZE - 1)] = value;

	kbdhead++;

// acknowledge the interrupt

    _outbyte(0x20, 0x20);
}
*/


 
 
 



void __near I_Shutdown(void);

 

//
// I_Error
//
void __far I_Error (int8_t __far *error, ...){
    va_list argptr;
	I_Shutdown();
    va_start(argptr, error);
    locallib_printf(error, argptr);
    va_end(argptr);
    locallib_putchar('\n');
	
    exit(1);

}

#ifdef ENABLE_DISK_FLASH
// draw disk icon
void __far I_BeginRead(void) {

    byte __far *src;
    byte __far *dest;
	int8_t y;
	int16_t oldval;

    if (!grmode) {
        return;
    }
    outp(SC_INDEX, SC_MAPMASK);
	oldval  = inp(SC_INDEX+1);

    // write through all planes
    outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, 15);
    // set write mode 1
    outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);
    // copy to backup
    src = currentscreen + 0x39CC; // 184 * 80 + 304 / 4;
	dest = ((byte __far*)0xac0039C8); //+ 0x39C8; // 184 * 80 + 288 / 4;
    for (y = 0; y<16; y++) {
		dest[0] = src[0];
        dest[1] = src[1];
        dest[2] = src[2];
        dest[3] = src[3];
        src += 80;
        dest += 80;
    }

    // copy disk over
    dest = currentscreen + 0x39CC;// + 184 * 80 + 304 / 4;
	src = ((byte __far*)0xac0039CC);// + 184 * 80 + 304 / 4;
    for (y = 0; y<16; y++) {
		dest[0] = src[0];
        dest[1] = src[1];
        dest[2] = src[2];
        dest[3] = src[3];
        src += 80;
        dest += 80;
    }

    outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, oldval);

    // set write mode 0
    outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
}

// erase disk icon
void __far I_EndRead(void) {

    byte __far *src, __far *dest;
	int8_t y;
	int16_t oldval;

    if (!grmode) {
        return;
    }

    outp(SC_INDEX, SC_MAPMASK);
	oldval  = inp(SC_INDEX+1);
    // write through all planes
    outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, 15);
    // set write mode 1
    outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);

    // copy disk over
    dest = currentscreen + 0x39CC;// 184 * 80 + 304 / 4;
	src = ((byte __far*)0xac0039C8);// + 184 * 80 + 288 / 4;
    for (y = 0; y<16; y++) {
		dest[0] = src[0];
        dest[1] = src[1];
        dest[2] = src[2];
        dest[3] = src[3];
        src += 80;
        dest += 80;
    }

    outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, oldval);

    // set write mode 0
    outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
	
}


//
// Disk icon flashing
//

void __near I_InitDiskFlash(void) {
    // cache the disk graphic
	fixed_t_union temp;
    W_CacheLumpNameDirect("STDISK", diskgraphicbytes);
	temp = destscreen;
	destscreen.w = 0xac000000;
	V_DrawPatchDirect(SCREENWIDTH - 16, SCREENHEIGHT - 16,  (patch_t __far*) diskgraphicbytes);
	destscreen = temp;
}

#else
void __far I_BeginRead(void){ }
void __far I_EndRead(void){ }
void __near I_InitDiskFlash(void){ }

#endif

//
// I_InitGraphics
//
void __near I_InitGraphics(void) {
	if (novideo) {
		return;
	}
	grmode = true;
	// regs.w.ax = 0x13;
	// intx86(0x10, (union REGS *)&regs, &regs);
	// set video mode
	locallib_int86_10(0x13, 0, 0);
	currentscreen = (byte __far*) 0xA0000000L;
	destscreen.w = 0xA0004000;

	outp(SC_INDEX, SC_MEMMODE);
	outp(SC_INDEX + 1, (inp(SC_INDEX + 1)&~8) | 4);
	outp(GC_INDEX, GC_MODE);
	outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~0x13);
	outp(GC_INDEX, GC_MISCELLANEOUS);
	outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~2);
	outpw(SC_INDEX, 0xF02);
	//FAR_memset(MK_FP(0xA000, 0), 0, 0xFFFFu);
	FAR_memset(currentscreen, 0, 0xFFFFu);
	outp(CRTC_INDEX, CRTC_UNDERLINE);
	outp(CRTC_INDEX + 1, inp(CRTC_INDEX + 1)&~0x40);
	outp(CRTC_INDEX, CRTC_MODE);
	outp(CRTC_INDEX + 1, inp(CRTC_INDEX + 1) | 0x40);
	outp(GC_INDEX, GC_READMAP);
	I_SetPalette(0);
#ifdef ENABLE_DISK_FLASH	
	I_InitDiskFlash();
#endif
}
