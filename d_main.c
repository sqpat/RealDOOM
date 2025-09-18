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
//  DOOM main program (D_DoomMain) and game loop (D_DoomLoop),
//  plus functions to determine game mode (shareware, registered),
//  parse command line parameters, configure game parameters (turbo),
//  and call the startup functions.
//

#include "doomdef.h"
#include <stdlib.h>
#include <stdarg.h>
#include <direct.h>
#include <io.h>
#include <fcntl.h>

#include "doomstat.h"

#include "dstrings.h"
#include "sounds.h"


#include "z_zone.h"
#include "w_wad.h"
#include "s_sound.h"
#include "v_video.h"

#include "f_finale.h"
#include "f_wipe.h"

#include "m_misc.h"
#include "m_menu.h"

#include "i_system.h"
#include "i_sound.h"

#include "g_game.h"

#include "hu_stuff.h"
#include "wi_stuff.h"
#include "st_stuff.h"
#include "am_map.h"

#include "p_setup.h"
#include "r_local.h"

#include "d_main.h"
#include "p_local.h"
 
#include <dos.h>

#include "m_memory.h"
#include "m_near.h"

 

 

//
// D-DoomLoop()
// Not a globally visible function,
//  just included for source reference,
//  called by D_DoomMain, never exits.
// Manages timing and IO,
//  calls all ?_Responder, ?_Ticker, and ?_Drawer,
//  calls I_GetTime,  and I_StartTic
//




//int8_t            wadfile[64];          // primary wad file


void __near G_BuildTiccmd(int8_t index);
void __near D_DoAdvanceDemo (void);




//
// D_PostEvent
// Called by the I/O functions when input is detected
//
void __near D_PostEvent (event_t __far* ev) {
    events[eventhead] = *ev;
    eventhead = (++eventhead)&(MAXEVENTS-1);
}


boolean __near G_Responder (event_t __far* ev);
void    __near ST_PrepareMapPosCheat();
//
// D_ProcessEvents
// Send all the events of the given timestamp down the responder chain
//
void __near D_ProcessEvents (void) {
	if (eventtail != eventhead){
	    
		int8_t oldtask = currenttask;
		Z_QuickMapMenu();


		for ( ; eventtail != eventhead ; eventtail = (++eventtail)&(MAXEVENTS-1) ) {
			event_t __far*     ev = &events[eventtail];
			if (M_Responder(ev)) {
				continue;
			}

			G_Responder (ev);
		}

		Z_QuickMapByTaskNum(oldtask);
		if (domapcheatthisframe){
			ST_PrepareMapPosCheat();
		}
	}
}




void __far getStringByIndex(int16_t stringindex, int8_t __far* returndata) {

	uint16_t stringoffset = stringoffsets[stringindex];
	uint16_t length = stringoffsets[stringindex + 1] - stringoffset;
	/*
	if (stringindex > MAX_STRINGS) {
		I_Error("bad string index! %li %i", gametic, stringindex);
	}
	*/
	/*
	int16_t index;

	if (stringoffset < stringbuffersizes[0]) {
		index = 0;
	
	} else {
		// todo havent actually tested this..
		index = 1;
		stringoffset -= stringbuffersizes[0];
	}
		*/


 
		// string ends at the start of the next string...
	FAR_memcpy(returndata, &(stringdata[stringoffset]), length);
	// add null terminator?
	returndata[length] = '\0';
}





/*

fixed_t32 FixedDiv2 (fixed_t32	a, fixed_t32	b
	//,int8_t* file, int32_t line
) {
	// all seem to work, but i think long long is probably the least problematic for 16 bit cpu for now. - sq

	long long c;
	//longlong_union c;
	c = ((long long)a << 16) / ((long long)b);


	//float c;
	//c = (((float)a) / ((float)b) * FRACUNIT);
	
	//double c;
	//c = (((double)a) / ((double)b) * FRACUNIT);

	return (fixed_t32) c;
}

//
// FixedDiv, C version.
//
*/


//fixed_t32 FixedDivinner(fixed_t32	a, fixed_t32 b int8_t* file, int32_t line)
/*
fixed_t32 FixedDiv(fixed_t32	a, fixed_t32	b) {
	if (FixedDiv10(a,b) != FixedDiv11(a, b)){
        I_Error("miss %li %li", a, b);
    }
    return FixedDiv11(a, b);
}
*/


// BIG TODO:
// asm all these. they arent super performance critical but the point is to make them small and take advantage of x86 string commands and such.





/*
void __near locallib_printhex (uint32_t number, boolean islong);
void __near locallib_printdecimal (int32_t number);
void __near locallib_printstringfar (int8_t __far *str);
void __near locallib_printstringnear (int8_t __near *str);

void __near locallib_printf (int8_t __far*str, va_list argptr){
    int16_t i = 0;
    int8_t longflag = false;
	
	while (str[i] != '\0'){
		for (; (str[i] != '%' && str[i] != '\0') && (!longflag); i++){
			putchar(str[i]);
		}
		if (str[i] == '\0'){
			break;
		}
		// i think this is always true.
		if (str[i] == '%' || longflag){
			switch  (str[i+1]){

				case '%':
					putchar('%');
					i+=2;
					continue;
				case 'l':
				case 'L':
				case 'f':
				case 'F':
					longflag = true;
					i++; 
					continue;
					 
				case 'x':
				case 'X':
				case 'p':
				case 'P':
					if (longflag){
						locallib_printhex(va_arg(argptr, uint32_t), true);
					} else {
						locallib_printhex((uint32_t)va_arg(argptr, uint16_t), false);
					}
					i+=2;
					longflag = false;
					continue;
				case 'i':
				case 'I':
					if (longflag){
						locallib_printdecimal(va_arg(argptr, int32_t ));
					} else {
						locallib_printdecimal((int32_t)va_arg(argptr, int16_t));
					}
					i+=2;
					longflag = false;
					continue;

				// case 'u':
				// case 'U':
				// 	locallib_printdecimal(va_arg(argptr, uint16_t));
				// 	i+=2;
				// 	continue;

				case 's':
				case 'S':
					if (longflag){
						locallib_printstringfar(va_arg(argptr, int8_t __far *));
					} else {
						locallib_printstringnear(va_arg(argptr, int8_t __near *));
					}
					i+=2;
					longflag = false;
					continue;
				
				case 'c':
				case 'C':
					putchar(va_arg(argptr, int8_t));
					i+=2;
					continue;
				
				default:
					i++;
			}
		}
		
	}

    
	

}
*/

// not sure whats going on yet. pulling this unused function makes 86box crash.
void __near locallib_printf2 (int8_t __far*str, va_list argptr){
    locallib_printf(str, argptr);
}





void __near R_ExecuteSetViewSize (void);





//
// D_StartTitle
//
/*
void __far D_StartTitle(void){

	gameaction = ga_nothing;
	demosequence = -1;
    advancedemo = true;
}
*/

//
// D_Display
//  draw current display, possibly wiping it from the previous
//

// void __near I_UpdateBox(int16_t x, int16_t y, int16_t w, int16_t h);

//
// I_UpdateNoBlit
//
// far because fwipe calls it. todo port local to fwipe
void __near I_UpdateNoBlit(void) ;

/*
void __near I_UpdateNoBlit(void) {
	int16_t realdr[4];
	int16_t x, y, w, h;
	// Set current screen
    currentscreen = (byte __far*) destscreen.w;

    // Update dirtybox size
    realdr[BOXTOP] = dirtybox[BOXTOP];

    if (realdr[BOXTOP] < olddb[0+BOXTOP]) {
        realdr[BOXTOP] = olddb[0+BOXTOP];
    }
    if (realdr[BOXTOP] < olddb[4+BOXTOP]) {
        realdr[BOXTOP] = olddb[4+BOXTOP];
    }

    realdr[BOXRIGHT] = dirtybox[BOXRIGHT];
    if (realdr[BOXRIGHT] < olddb[0+BOXRIGHT]) {
        realdr[BOXRIGHT] = olddb[0+BOXRIGHT];
    }
    if (realdr[BOXRIGHT] < olddb[4+BOXRIGHT]) {
        realdr[BOXRIGHT] = olddb[4+BOXRIGHT];
    }

    realdr[BOXBOTTOM] = dirtybox[BOXBOTTOM];
    if (realdr[BOXBOTTOM] > olddb[0+BOXBOTTOM]) {
        realdr[BOXBOTTOM] = olddb[0+BOXBOTTOM];
    }
    if (realdr[BOXBOTTOM] > olddb[4+BOXBOTTOM]) {
        realdr[BOXBOTTOM] = olddb[4+BOXBOTTOM];
    }

    realdr[BOXLEFT] = dirtybox[BOXLEFT];
    if (realdr[BOXLEFT] > olddb[0+BOXLEFT]) {
        realdr[BOXLEFT] = olddb[0+BOXLEFT];
    }
    if (realdr[BOXLEFT] > olddb[4+BOXLEFT]) {
        realdr[BOXLEFT] = olddb[4+BOXLEFT];
    }

    // Leave current box for next update
    olddb[0] = olddb[4];
    olddb[1] = olddb[5];
    olddb[2] = olddb[6];
    olddb[3] = olddb[7];
    olddb[4] = dirtybox[0];
    olddb[5] = dirtybox[1];
    olddb[6] = dirtybox[2];
    olddb[7] = dirtybox[3];
//	memcpy(olddb, olddb+4, 8);
//    memcpy(olddb+4, dirtybox, 8);


    // Update screen
    if (realdr[BOXBOTTOM] <= realdr[BOXTOP]) {
        x = realdr[BOXLEFT];
        y = realdr[BOXBOTTOM];
        w = realdr[BOXRIGHT] - realdr[BOXLEFT] + 1;
        h = realdr[BOXTOP] - realdr[BOXBOTTOM] + 1;
        I_UpdateBox(x, y, w, h); // todo inline, only use.
    }
	// Clear box

	dirtybox[BOXTOP] = dirtybox[BOXRIGHT] = MINSHORT;
	dirtybox[BOXBOTTOM] = dirtybox[BOXLEFT] = MAXSHORT;
}
*/

void __near I_FinishUpdate(void);




void __near D_Display (void);
/*
void __near D_Display (void) {
	int16_t                         y;
    boolean                     wipe = false;
    boolean                     redrawsbar;
	void (__far* WI_Drawer)() = 										 		  ((void    (__far *)())     							(MK_FP(wianim_codespace_segment, 		 WI_DrawerOffset)));
	void (__far* F_Drawer)() = 											  		  ((void    (__far *)())     							(MK_FP(code_overlay_segment, 		 	 F_DrawerOffset)));
	void (__far* wipe_WipeLoopCall)() = 										  ((void    (__far *)())     							(MK_FP(code_overlay_segment, 		 	 wipe_WipeLoopOffset)));
	void (__far* wipe_StartScreenCall)() = 										  ((void    (__far *)())     							(MK_FP(code_overlay_segment, 		 	 wipe_StartScreenOffset)));
	if (novideo){
        return;                    // for comparative timing / profiling
	}
#ifdef DETAILED_BENCH_STATS
	cachedrendertics = ticcount;
#endif
    redrawsbar = false;


    // change the view size if needed
    if (setsizeneeded) {
		R_ExecuteSetViewSize ();
        oldgamestate = -1;                      // force background redraw
        borderdrawcount = 3;
    }


#ifndef SKIPWIPE

    // save the current screen if about to wipe
    if (gamestate != wipegamestate) {
        wipe = true;
		Z_SetOverlay(OVERLAY_ID_WIPE);
        wipe_StartScreenCall();
    } else {
        wipe = false;
    }

#else
	wipe = false;  // turn wipes off
#endif
	if (gamestate == GS_LEVEL && gametic) {
		HU_Erase();
 	}
    // do buffered drawing
    switch (gamestate) {
      case GS_LEVEL:
        if (!gametic){
            break;
		}
        if (automapactive){
            AM_Drawer ();
		}
		if (wipe || (viewheight != 200 && fullscreen) ){
            redrawsbar = true;
		}
		if (inhelpscreensstate && !inhelpscreens) {
			redrawsbar = true;              // just put away the help screen
		}
		if (inhelpscreens) {{
			skipdirectdraws = true;
		}
		}
		ST_Drawer (viewheight == 200, redrawsbar);
		skipdirectdraws = false;

 		fullscreen = viewheight == 200;
        break;

      case GS_INTERMISSION:
		Z_QuickMapIntermission();
        WI_Drawer ();
	    Z_QuickMapPhysics();


		break;

      case GS_FINALE:
        Z_SetOverlay(OVERLAY_ID_FINALE);
        F_Drawer ();
		Z_QuickMapPhysics(); // put this here, instead of 3 spots in f_drawer...
        break;

      case GS_DEMOSCREEN:
        D_PageDrawer ();
 		break;
    }



	// draw buffered stuff to screen


	I_UpdateNoBlit (); // note: this accesses screen0 so it needs physics...
#ifdef DETAILED_BENCH_STATS
	rendersetuptics += ticcount - cachedrendertics;
	cachedrendertics = ticcount;
#endif

	// draw the view directly
	if (gamestate == GS_LEVEL && !automapactive && gametic) {
		if (!inhelpscreens) {
			R_RenderPlayerView();
		}
	}

#ifdef DETAILED_BENCH_STATS
	renderplayerviewtics += ticcount - cachedrendertics;
	cachedrendertics = ticcount;
#endif

	if (gamestate == GS_LEVEL && gametic) {
		if (!inhelpscreens) {
			HU_Drawer();
		}
 	}

    // clean up border stuff
	if (gamestate != oldgamestate && gamestate != GS_LEVEL) {
		I_SetPalette(0);
	}

    // see if the border needs to be initially drawn
    if (gamestate == GS_LEVEL && oldgamestate != GS_LEVEL) {
        viewactivestate = false;        // view was not active
        R_FillBackScreen ();    // draw the pattern into the back screen
    }

    // see if the border needs to be updated to the screen
    if (gamestate == GS_LEVEL && !automapactive && scaledviewwidth != 320) {
        if (menuactive || menuactivestate || !viewactivestate){
            borderdrawcount = 3;
		}
		if (borderdrawcount) {
			if (!inhelpscreens){
            	R_DrawViewBorder ();    // erase old menu stuff
			}
			borderdrawcount--;
			if (hudneedsupdate){
				hudneedsupdate++;
			}
        	

		}
	}

    menuactivestate = menuactive;
    viewactivestate = viewactive;
    inhelpscreensstate = inhelpscreens;
    oldgamestate = wipegamestate = gamestate;

    // draw pause pic
	Z_QuickMapMenu();		
    if (paused) {
		M_DrawPause();
    }
	

    // menus go directly to the screen
	M_Drawer ();          // menu is drawn even on top of everything
	Z_QuickMapPhysics();

	NetUpdate ();         // send out any new accumulation

	// normal update
    if (!wipe) {
        I_FinishUpdate ();              // page flip or blit buffer
#ifdef DETAILED_BENCH_STATS
		renderpostplayerviewtics += ticcount - cachedrendertics;
#endif
		return;
    }

    
    // wipe update
#ifndef SKIPWIPE
	Z_SetOverlay(OVERLAY_ID_WIPE);
	wipe_WipeLoopCall();
#endif
}
*/

 /*
 void __near locallib_putchar(int8_t c){
	// fputc(c, stdout);
	putchar(c);
 }
 */

void __near G_BeginRecording (void)  { 
	byte __far* demo_addr = (byte __far*)MK_FP(DEMO_SEGMENT, demo_p);
	Z_QuickMapDemo();

    demo_p = 0;
        
    *demo_addr++ = VERSION;
    *demo_addr++ = gameskill;
    *demo_addr++ = gameepisode;
    *demo_addr++ = gamemap;
    *demo_addr++ = false;
    *demo_addr++ = respawnparm;
    *demo_addr++ = fastparm;
    *demo_addr++ = nomonsters;
    *demo_addr++ = 0;

	*demo_addr++ = true;
	*demo_addr++ = false;
	*demo_addr++ = false;
	*demo_addr++ = false;
	
	demo_p = (demo_addr - demobuffer);
	Z_QuickMapPhysics();

} 

//
//  D_DoomLoop
//
// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
void __near I_InitGraphics(void);


void __near D_DoomLoop (void) {
	// debugging stuff i need to find mem leaks...
#ifdef DEBUGLOG_TO_FILE
	//int8_t result2[100];
	//int32_t lasttick = 0;
	FILE* fp;
#endif
	void (__far* S_ActuallyChangeMusic)() = 									  ((void    (__far *)())     							(MK_FP(code_overlay_segment, 		 	 S_ActuallyChangeMusicOffset)));

    if (demorecording){
        G_BeginRecording ();
	}


    I_InitGraphics ();

    while (1) {
		// process one or more tics
		if (singletics) {
#ifdef DETAILED_BENCH_STATS
			othertics += ticcount - cachedtics;
			cachedtics = ticcount;
#endif
			I_StartTic ();
			D_ProcessEvents ();
			G_BuildTiccmd(maketic & (BACKUPTICS-1));
			if (advancedemo) {
				D_DoAdvanceDemo();
			}

			M_Ticker ();

			G_Ticker ();

#ifdef DETAILED_BENCH_STATS
			physicstics += ticcount - cachedtics;
#endif
			gametic++;
            maketic++;

		} else {
            TryRunTics (); // will run at least one tic
        }
		S_UpdateSounds ();// move positional sounds
 		// Update display, next frame, with current state.
		if (pendingmusicenum){
			// todo should the default case be -1 instead of 0?
			Z_SetOverlay(OVERLAY_ID_MUS_LOADER);
			S_ActuallyChangeMusic();
		}


		

#ifdef DETAILED_BENCH_STATS
		cachedtics = ticcount;
#endif
		D_Display ();
#ifdef DETAILED_BENCH_STATS
		rendertics += ticcount - cachedtics;
		cachedtics = ticcount;
#endif
   
   /*
if (gametic == 200){
    I_Error("done");
}
*/

				


//		if (gametic != lasttick) {
//			lasttick = gametic;
				

			//sprintf(result2, "%i %i %i \n", gametic, prndindex, SAV);
			//SAVEDUNIT = playerMobj;
			//SAVEDUNIT_POS = playerMobj_pos;
{
			// FILE* fp = fopen("debuglog.txt", "ab");
			// fprintf(fp, "%li %i \n", gametic, prndindex);
			// fclose(fp);

			// if (gametic == 78){
			// 	I_Error("done blah");
			// }
}
 
		
		
	}
}

// int16_t counter = 0;
// int16_t setval = 0;

// void __far MainLogger (uint16_t ax, uint16_t dx, uint16_t bx, uint16_t cx){
// 	if (gametic == 77){
// 		// FILE* fp = fopen("tick.txt", "ab");
// 		// fprintf(fp, "%li %i %i %x %i %x\n", gametic, prndindex, counter, ax & 0xFF, dx, bx);
// 		// fclose(fp);

// 		counter++;
// 		if (counter == 91){
// 			setval = 1;
// 		}
// 	}
// }



//
// D_PageTicker
// Handles timing for warped projection
//
void __near D_PageTicker (void) {
    if (--pagetic < 0){
	    advancedemo = true;
	}
}



//
// D_PageDrawer
//
void __near D_PageDrawer (void) {

	// we dont have various screen buffers anymore, so we cant draw to buffer in 'read this'
	// screen - this would draw direct to screen and overwrite the read this screen.
	// so we just dont draw titlepic in that situation
	if (inhelpscreens) { 
		return;
	}

	 V_DrawFullscreenPatch(pagename, 0);
}

 

//
// This cycles through the demo sequences.
// FIXME - version dependend demo numbers?
//
 void __near D_DoAdvanceDemo (void) {
    player.playerstate = PST_LIVE;  // not reborn
    advancedemo = false;
    usergame = false;               // no save / end game here
    paused = false;
    gameaction = ga_nothing;

	if (is_ultimate){
    	demosequence = (demosequence+1)%7;
	} else{
    	demosequence = (demosequence+1)%6;
	}
    
    switch (demosequence) {
      case 0:
        if ( commercial ){
            pagetic = 35 * 11;
		} else {
            pagetic = 170;
		}
		gamestate = GS_DEMOSCREEN;
		pagename = "TITLEPIC"; 
		if ( commercial ){
        //   S_StartMusic(mus_dm2ttl);
			pendingmusicenum = mus_dm2ttl;
			pendingmusicenumlooping = 0;
		} else {
        //   S_StartMusic (mus_intro);
			pendingmusicenum = mus_intro;
			pendingmusicenumlooping = 0;
		}
		break;
      case 1:
        G_DeferedPlayDemo ("demo1");
        break;
      case 2:
        pagetic = 200;
        gamestate = GS_DEMOSCREEN;
        pagename = "CREDIT";
        break;
      case 3:
        G_DeferedPlayDemo ("demo2");
        break;
      case 4:
        gamestate = GS_DEMOSCREEN;
        if ( commercial) {
            pagetic = 35 * 11;
            pagename = "TITLEPIC";
            // S_StartMusic(mus_dm2ttl);
			pendingmusicenum = mus_dm2ttl;
			pendingmusicenumlooping = 0;

        } else {
            pagetic = 200;
			if (is_ultimate){
				pagename = "CREDIT";
			} else {
				pagename = "HELP2";
			}
        }
        break;
      case 5:
        G_DeferedPlayDemo ("demo3");
        break;
        // THE DEFINITIVE DOOM Special Edition demo
      case 6:
		if (is_ultimate){
			G_DeferedPlayDemo ("demo4");
			break;
		}
	}
}






void D_INIT_STARTMARKER();


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


 void __near D_DoomMain(void) {

	// FILE *fp = fopen("output9.bin", "wb");
	// locallib_far_fwrite(M_Random, (byte __far *)ST_STUFF_STARTMARKER - (byte __far *)M_Random, 1, fp);
	// fclose(fp);
	// exit(0);

	 D_DoomMain2();

#ifdef DETAILED_BENCH_STATS
	 cachedtics = ticcount;
#endif
	 Z_ClearDeadCode();

	 D_DoomLoop();  // never returns
 }
