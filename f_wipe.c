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
#include "m_memory.h"
#include "m_near.h"
#include <conio.h>


#ifdef SKIPWIPE
#else

//
//                       SCREEN WIPE PACKAGE
//



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

 


int16_t __near wipe_initMelt (){
	int16_t i, r;
	int16_t __far* y = (int16_t __far*)0x7FA00000; // 7000:FA00
	uint16_t __far* mul160lookup = (uint16_t __far*)0x7FE00000; // 7000:FE00

    // copy start screen to main screen
    FAR_memcpy(screen0, screen2, 64000u);

    // makes this wipe faster (in theory)
    // to have stuff in column-major format
    wipe_shittyColMajorXform((int16_t __far*)screen2);
    wipe_shittyColMajorXform((int16_t __far*)screen3);
    
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
	r = 0;
    for (i=0;i<SCREENHEIGHT;i++) {
		mul160lookup[i] = r;
		r+= SCREENWIDTHOVER2;
    }



    return 0;
}

#define screen3_segment ((segment_t)(((int32_t) screen3) >> 16))
#define screen2_segment ((segment_t)(((int32_t) screen2) >> 16))
#define screen0_segment ((segment_t)(((int32_t) screen0) >> 16))

int16_t __far wipe_doMelt ( int16_t	ticks );

/*
int16_t __near wipe_doMelt2 ( int16_t	ticks ) {
    uint8_t		i;
    uint8_t		j;
    uint8_t		dy;
    uint16_t		idx;
	int16_t __far* y = (int16_t __far*)0x7FA00000; // 7000:FA00
	uint16_t __far* mul160lookup = (uint16_t __far*)0x7FE00000; // 7000:FE00
    int16_t	__far* source;
    int16_t	__far* dest;
    boolean	done = true;

	while (ticks--) {
		uint16_t mulI = 0;
		for (i=0;i< SCREENWIDTHOVER2;i++) {
			if (y[i]<0) {
				y[i]++; 
			done = false;
			} else if (y[i] < SCREENHEIGHT) {
				dy = (y[i] < 16) ? y[i]+1 : 8;
				if (y[i] + dy >= SCREENHEIGHT) {
					dy = SCREENHEIGHT - y[i];
				}
				//source = MK_FP(screen3_segment, 2*(	mulI+y[i]));
				//dest = MK_FP(screen0_segment, 2*(mul160lookup[y[i]] + i));
				source = &((int16_t __far*)screen3)	[mulI+y[i]];
				dest = &((int16_t __far*)screen0)	[mul160lookup[y[i]] + i];


				idx = 0;
				for (j=dy;j;j--) {
					dest[idx] = *(source++);
					idx += SCREENWIDTHOVER2;
				}
				y[i] += dy;

				//source = MK_FP(screen2_segment, 2*mulI);
				//dest = MK_FP(screen0_segment, 2*(mul160lookup[y[i]] + i));
				source = &((int16_t __far*)screen2)	[mulI];
				dest = &((int16_t __far*)screen0)	[mul160lookup[y[i]] + i];

				idx = 0;
				for (j= SCREENHEIGHT -y[i];j;j--) {
					dest[idx] = *(source++);
					idx += SCREENWIDTHOVER2;
				}
				done = false;
			}
			mulI+=SCREENHEIGHT;

		}
    }

    return done;

}
*/

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

	//wipe_scr_start = screen2;
    I_ReadScreen(screen2);



	Z_QuickMapPhysics();

    return 0;
}








void __far M_Drawer (int8_t isFromWipe);
void __far I_UpdateNoBlit(void);
void __far I_FinishUpdate(void);



#ifdef FPS_DISPLAY
extern int32_t fps_rendered_frames_since_last_measure;
#endif

extern int8_t hudneedsupdate;

void __far wipe_WipeLoop(){
	ticcount_t                         nowtime, wipestart;
	ticcount_t                         wiperealstart;
	boolean						done = false;
	int16_t                         tics;
	Z_QuickMapWipe();
	//wipe_EndScreen();
	//wipe_scr_end = screen3;
    I_ReadScreen(screen3);
    


	

	//	V_DrawBlock(0, 0,  SCREENWIDTH, SCREENHEIGHT, screen2); // restore start scr.
	V_MarkRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
	FAR_memcpy(screen0, screen2, SCREENWIDTH*SCREENHEIGHT);

	wipe_initMelt();

	wiperealstart = wipestart = ticcount - 1;


    do {
        do {
            nowtime = ticcount;
            tics = nowtime - wipestart;
        } while (!tics);
        wipestart = nowtime;
        
		dirtybox[BOXLEFT] = 0;
		dirtybox[BOXRIGHT] = SCREENWIDTH;
		dirtybox[BOXBOTTOM] = 0;
		dirtybox[BOXTOP] = SCREENHEIGHT;

		done = wipe_doMelt(tics);
        I_UpdateNoBlit ();
 		M_Drawer (true);                            // menu is drawn even on top of wipes
 		I_FinishUpdate();                      // page flip or blit buffer

    } while (!done);
	// i think the first draw or two dont write to the correct framebuffer? needs six
	hudneedsupdate = 6;

	Z_QuickMapPhysics();
	wipeduration = ticcount - wiperealstart;

}


#endif
