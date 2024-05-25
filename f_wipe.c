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
//	Mission begin melt/wipe screen special effect.
//




#include "z_zone.h"
#include "i_system.h"
#include "v_video.h"
#include "m_misc.h"

#include "doomdef.h"

#include "f_wipe.h"
#include <dos.h>
#include "memory.h"
#include <conio.h>


#ifdef SKIPWIPE
#else

//
//                       SCREEN WIPE PACKAGE
//

// when zero, stop the wipe
static boolean	go = 0;

// screen 2
static byte __far*	wipe_scr_start;
// screen 3
static byte __far*	wipe_scr_end;
// screen 0, in 0x8000 region
static byte __far*	wipe_scr;


void __near wipe_shittyColMajorXform ( int16_t __far*	array ) {
    uint16_t		x;
    uint16_t		y;
    int16_t __far*	dest = MK_FP(SCRATCH_PAGE_SEGMENT, 0);
	
	Z_QuickMapScratch_5000();

    for(y=0;y<SCREENHEIGHT;y++)
		for (x = 0; x < SCREENWIDTHOVER2; x++) {
			uint16_t result = SCREENHEIGHT;
			uint16_t result2 = SCREENWIDTHOVER2;
			result *= x;
			result += y;
			result2 *= y;
			result2 += x;
			
			dest[result] = array[result2];
		}

	FAR_memcpy(array, dest, 64000u);
	

} 

 


int16_t __near wipe_initMelt ( 
  int16_t	ticks )
{
	int16_t i, r;
	int16_t __far* y = (int16_t __far*)0x7000FA00;

    // copy start screen to main screen
    FAR_memcpy(wipe_scr, wipe_scr_start, 64000u);

    // makes this wipe faster (in theory)
    // to have stuff in column-major format
    wipe_shittyColMajorXform((int16_t __far*)wipe_scr_start);
    wipe_shittyColMajorXform((int16_t __far*)wipe_scr_end);
    
    // setup initial column positions
    // (y<0 => not ready to scroll yet)

    y[0] = -(M_Random()%16);
    for (i=1;i<SCREENWIDTH;i++) {
		r = (M_Random()%3) - 1;
		y[i] = y[i-1] + r;
		if (y[i] > 0) {
			y[i] = 0;
		} else if (y[i] == -16) {
			y[i] = -15;
		}
    }



    return 0;
}

int16_t __near wipe_doMelt (
  int16_t	ticks )
{
    int16_t		i;
    int16_t		j;
    int16_t		dy;
    uint16_t		idx;
    
	int16_t __far* y = (int16_t __far*)0x7000FA00;
    int16_t	__far* s;
    int16_t	__far* d;
    boolean	done = true;

    
	 
	while (ticks--) {
		for (i=0;i< SCREENWIDTHOVER2;i++) {
			if (y[i]<0) {
				y[i]++; 
				done = false;
			} else if (y[i] < SCREENHEIGHT) {
				dy = (y[i] < 16) ? y[i]+1 : 8;
				if (y[i] + dy >= SCREENHEIGHT) {
					dy = SCREENHEIGHT - y[i];
				}
				s = &((int16_t __far*)wipe_scr_end)	[(uint16_t)i*(uint16_t)SCREENHEIGHT+(uint16_t)y[i]];
				d = &((int16_t __far*)wipe_scr)		[(uint16_t)y[i]* (uint16_t)SCREENWIDTHOVER2 + (uint16_t)i];
				idx = 0;
				for (j=dy;j;j--) {
					d[idx] = *(s++);
					idx += SCREENWIDTHOVER2;
				}
				y[i] += dy;
				s = &((int16_t __far*)wipe_scr_start)	[(uint16_t)i*(uint16_t)SCREENHEIGHT];
				d = &((int16_t __far*)wipe_scr)			[(uint16_t)y[i]* (uint16_t)SCREENWIDTHOVER2 + (uint16_t)i];
				idx = 0;
				for (j= SCREENHEIGHT -y[i];j;j--) {
					d[idx] = *(s++);
					idx += SCREENWIDTHOVER2;
				}
				done = false;
			}
		}
    }

    return done;

}

#define GC_INDEX                0x3CE
#define GC_READMAP              4
extern byte __far *currentscreen;

//
// I_ReadScreen
// Reads the screen currently displayed into a linear buffer.
//
void __near I_ReadScreen(byte __far *scr)
{
	uint16_t i;
	uint16_t j;


	outp(GC_INDEX, GC_READMAP);
    for (i = 0; i < 4; i++) {
		outp(GC_INDEX+1, i);
        for (j = 0; j < (uint16_t)SCREENWIDTH*(uint16_t)SCREENHEIGHT/4u; j++) {
			scr[i+j*4u] = currentscreen[j];
        }
    }

}


int16_t __far wipe_StartScreen( ) {
	Z_QuickMapWipe();

	wipe_scr_start = screen2;
    I_ReadScreen(wipe_scr_start);



	Z_QuickMapPhysics();

    return 0;
}




//
// V_DrawBlock
// Draw a linear block of pixels into the view buffer.
//
void __near V_DrawBlock (int16_t x, int16_t y, int16_t width, int16_t height, byte __far* src) {
	byte __far*	dest;


	V_MarkRect(x, y, width, height);

	dest = screen0 + y * SCREENWIDTH + x;

	while (height--)
	{
		FAR_memcpy(dest, src, width);
		src += width;
		dest += SCREENWIDTH;
	}
}



int16_t __near wipe_EndScreen () {
	Z_QuickMapWipe();

	wipe_scr_end = screen3;
    I_ReadScreen(wipe_scr_end);
    
	V_DrawBlock(0, 0,  SCREENWIDTH, SCREENHEIGHT, wipe_scr_start); // restore start scr.
 
	//Z_QuickMapPhysics();

    return 0;
}

int16_t __near wipe_ScreenWipe(int16_t	ticks ) {
	int16_t rc;

	
	Z_QuickMapWipe();

    // initial stuff
    if (!go) {
		go = 1;
		wipe_scr = screen0;
		wipe_initMelt(ticks);
	}


    // do a piece of wipe-in
    V_MarkRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
    rc = wipe_doMelt(ticks);

    // final stuff
    if (rc) {
		go = 0;
		
    }

	//Z_QuickMapPhysics();

    return !go;

}
uint16_t                         wipeduration = 0;
void __far M_Drawer();
void __far I_UpdateNoBlit(void);
void __far I_FinishUpdate(void);



#ifdef FPS_DISPLAY
extern int32_t fps_rendered_frames_since_last_measure;
#endif


void __far wipe_WipeLoop(){
	ticcount_t                         nowtime, wipestart;
	ticcount_t                         wiperealstart;
	boolean						done = false;
	int16_t                         tics;

	wipe_EndScreen();

	wiperealstart = wipestart = ticcount - 1;

    do {
        do {
            nowtime = ticcount;
            tics = nowtime - wipestart;
        } while (!tics);
        wipestart = nowtime;
        done = wipe_ScreenWipe(tics);
        I_UpdateNoBlit ();
 		M_Drawer ();                            // menu is drawn even on top of wipes
 		I_FinishUpdate();                      // page flip or blit buffer

    } while (!done);

	Z_QuickMapPhysics();
	wipeduration = ticcount - wiperealstart;

}


#endif
