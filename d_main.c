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

#include <stdlib.h>
//#include <graph.h>
#include <direct.h>
#include <io.h>
#include <fcntl.h>

#include "doomdef.h"
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


#if (EXE_VERSION >= EXE_VERSION_FINAL)
boolean         plutonia;
boolean         tnt;
#endif


//int8_t            wadfile[64];          // primary wad file


void __near G_BuildTiccmd(int8_t index);
void __near D_DoAdvanceDemo (void);




//
// D_PostEvent
// Called by the I/O functions when input is detected
//
void __near D_PostEvent (event_t __far* ev)
{
    events[eventhead] = *ev;
    eventhead = (++eventhead)&(MAXEVENTS-1);
}


boolean __near G_Responder (event_t __far* ev);

//
// D_ProcessEvents
// Send all the events of the given timestamp down the responder chain
//
void __near D_ProcessEvents (void)
{
    event_t __far*     ev;
	for ( ; eventtail != eventhead ; eventtail = (++eventtail)&(MAXEVENTS-1) ) {
		ev = &events[eventtail];
		if (M_Responder(ev)) {
			continue;
		}

		G_Responder (ev);
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

// basically our own little custom version of far fstrncpy. we were only ever using it with size 8
void copystr8(int8_t __far* dst, int8_t __far* src){
	int8_t j;
	for (j = 0; j < 8; j++){
		dst[j] = src[j];
		if (dst[j] == '\0'){
			return;
		}
	}
}


extern patch_t __far* M_GetMenuPatch(int16_t i);
extern  boolean setsizeneeded;
extern  uint8_t             showMessages;


void __near R_ExecuteSetViewSize (void);





//
// D_StartTitle
//
void __far D_StartTitle(void)
{
	gameaction = ga_nothing;
	demosequence = -1;
    advancedemo = true;
}

extern mobj_t __far * SAVEDUNIT;
extern mobj_pos_t __far * SAVEDUNIT_POS;
//
// D_Display
//  draw current display, possibly wiping it from the previous
//

extern byte __far *currentscreen;
void __near I_UpdateBox(int16_t x, int16_t y, int16_t w, int16_t h);

//
// I_UpdateNoBlit
//
int16_t olddb[2][4];
void __far I_UpdateNoBlit(void) {
	int16_t realdr[4];
	int16_t x, y, w, h;
	// Set current screen
    currentscreen = (byte __far*) destscreen.w;

    // Update dirtybox size
    realdr[BOXTOP] = dirtybox[BOXTOP];
    if (realdr[BOXTOP] < olddb[0][BOXTOP]) {
        realdr[BOXTOP] = olddb[0][BOXTOP];
    }
    if (realdr[BOXTOP] < olddb[1][BOXTOP]) {
        realdr[BOXTOP] = olddb[1][BOXTOP];
    }

    realdr[BOXRIGHT] = dirtybox[BOXRIGHT];
    if (realdr[BOXRIGHT] < olddb[0][BOXRIGHT]) {
        realdr[BOXRIGHT] = olddb[0][BOXRIGHT];
    }
    if (realdr[BOXRIGHT] < olddb[1][BOXRIGHT]) {
        realdr[BOXRIGHT] = olddb[1][BOXRIGHT];
    }

    realdr[BOXBOTTOM] = dirtybox[BOXBOTTOM];
    if (realdr[BOXBOTTOM] > olddb[0][BOXBOTTOM]) {
        realdr[BOXBOTTOM] = olddb[0][BOXBOTTOM];
    }
    if (realdr[BOXBOTTOM] > olddb[1][BOXBOTTOM]) {
        realdr[BOXBOTTOM] = olddb[1][BOXBOTTOM];
    }

    realdr[BOXLEFT] = dirtybox[BOXLEFT];
    if (realdr[BOXLEFT] > olddb[0][BOXLEFT]) {
        realdr[BOXLEFT] = olddb[0][BOXLEFT];
    }
    if (realdr[BOXLEFT] > olddb[1][BOXLEFT]) {
        realdr[BOXLEFT] = olddb[1][BOXLEFT];
    }

    // Leave current box for next update
    memcpy(olddb[0], olddb[1], 8);
    memcpy(olddb[1], dirtybox, 8);

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

void __far I_FinishUpdate(void);

void __near D_Display (void)
{
    static  boolean             viewactivestate = false;
    static  boolean             menuactivestate = false;
    static  boolean             inhelpscreensstate = false;
    static  boolean             fullscreen = false;
    static  gamestate_t         oldgamestate = -1;
    static  uint8_t                 borderdrawcount;
	int16_t                         y;
    boolean                     wipe;
    boolean                     redrawsbar;
	if (nodrawers)
        return;                    // for comparative timing / profiling
 
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
        wipe_StartScreen();
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
        if (!gametic)
            break;
        if (automapactive)
            AM_Drawer ();
        if (wipe || (viewheight != 200 && fullscreen) )
            redrawsbar = true;
		if (inhelpscreensstate && !inhelpscreens) 
			redrawsbar = true;              // just put away the help screen
		
		if (inhelpscreens) {
			skipdirectdraws = true;
		
		}
		ST_Drawer (viewheight == 200, redrawsbar);
		skipdirectdraws = false;

 		fullscreen = viewheight == 200;
        break;

      case GS_INTERMISSION:
        WI_Drawer ();
		break;

      case GS_FINALE:
		Z_QuickMapStatus();
        F_Drawer ();
		Z_QuickMapPhysics();
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
    if (gamestate == GS_LEVEL && !automapactive && scaledviewwidth != 320)
    {
        if (menuactive || menuactivestate || !viewactivestate)
            borderdrawcount = 3;
        if (borderdrawcount)
        {
			if (!inhelpscreens)
            R_DrawViewBorder ();    // erase old menu stuff
            borderdrawcount--;
        }

    }

    menuactivestate = menuactive;
    viewactivestate = viewactive;
    inhelpscreensstate = inhelpscreens;
    oldgamestate = wipegamestate = gamestate;

    // draw pause pic
    if (paused) {
        if (automapactive)
            y = 4;
        else
            y = viewwindowy+4;
#ifndef __DEMO_ONLY_BINARY

		Z_QuickMapMenu();		
        V_DrawPatchDirect(viewwindowx+(scaledviewwidth-68)/2, y, M_GetMenuPatch(12));
		Z_QuickMapPhysics();
#endif
    }
	
    // menus go directly to the screen
	M_Drawer (false);          // menu is drawn even on top of everything

	NetUpdate ();         // send out any new accumulation

	// normal update
    if (!wipe)
    {
        I_FinishUpdate ();              // page flip or blit buffer
#ifdef DETAILED_BENCH_STATS
		renderpostplayerviewtics += ticcount - cachedrendertics;
#endif
		return;
    }


    
    // wipe update
#ifndef SKIPWIPE
	wipe_WipeLoop();


#endif
}
 
extern uint16_t demo_p;				// buffer

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
extern  boolean         demorecording;
// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
void __near I_InitGraphics(void);

void __near D_DoomLoop (void)
{
	// debugging stuff i need to find mem leaks...
#ifdef DEBUGLOG_TO_FILE
	//int8_t result2[100];
	//int32_t lasttick = 0;
	FILE* fp;
#endif

    if (demorecording)
        G_BeginRecording ();
                


    I_InitGraphics ();

    while (1)
    {
		// process one or more tics
		if (singletics) {
#ifdef DETAILED_BENCH_STATS
			othertics += ticcount - cachedtics;
			cachedtics = ticcount;
#endif
			I_StartTic ();
			D_ProcessEvents ();
			G_BuildTiccmd(maketic % BACKUPTICS);
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
		S_UpdateSounds (playerMobjRef);// move positional sounds
 		// Update display, next frame, with current state.

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

#ifdef DEBUGLOG_TO_FILE
				


//		if (gametic != lasttick) {
//			lasttick = gametic;
				

			//sprintf(result2, "%i %i %i \n", gametic, prndindex, SAV);
			//SAVEDUNIT = playerMobj;
			//SAVEDUNIT_POS = playerMobj_pos;
			SAVEDUNIT = &thinkerlist[222].data;
			SAVEDUNIT_POS = &mobjposlist[222];
			//SAVEDUNIT = &thinkerlist[playerMobjRef].data;
			//if (gametic == 1) {
			//	fp = fopen("debuglog.txt", "w"); // clear old file
			//} else {
				fp = fopen("debuglog.txt", "a");
			//}
			//sprintf(result2, "%li %hhu %li %li %li %li %li %l %l %i \n", gametic, prndindex, SAVEDUNIT->x, SAVEDUNIT->y, SAVEDUNIT->z, SAVEDUNIT->momx, SAVEDUNIT->momy, SAVEDUNIT->floorz, SAVEDUNIT->ceilingz, SAVEDUNIT->secnum);
			fprintf(fp, "%li %i  %li %li %li %li %li %i %i %i\n", gametic, prndindex,   SAVEDUNIT->momx, SAVEDUNIT->momy, SAVEDUNIT_POS->z.w, SAVEDUNIT_POS->x.w, SAVEDUNIT_POS->y.w,SAVEDUNIT_POS->stateNum, SAVEDUNIT->tics);
			//fprintf(result2, fp);
			fclose(fp);

			if (gametic == 400){
				I_Error("done blah");
			}
				
 
#endif
		
		
	}
}




//
// D_PageTicker
// Handles timing for warped projection
//
void __near D_PageTicker (void)
{
    if (--pagetic < 0)
	    advancedemo = true;
}



//
// D_PageDrawer
//
void __near D_PageDrawer (void)
{

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
 void __near D_DoAdvanceDemo (void)
{
    player.playerstate = PST_LIVE;  // not reborn
    advancedemo = false;
    usergame = false;               // no save / end game here
    paused = false;
    gameaction = ga_nothing;

#if (EXE_VERSION == EXE_VERSION_ULTIMATE) || (EXE_VERSION == EXE_VERSION_FINAL)
    demosequence = (demosequence+1)%7;
#else
    demosequence = (demosequence+1)%6;
#endif
    
    switch (demosequence)
    {
      case 0:
        if ( commercial )
            pagetic = 35 * 11;
        else
            pagetic = 170;
			gamestate = GS_DEMOSCREEN;
			pagename = "TITLEPIC"; 
        if ( commercial )
          S_StartMusic(mus_dm2ttl);
        else
          S_StartMusic (mus_intro);
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
        if ( commercial)
        {
            pagetic = 35 * 11;
            pagename = "TITLEPIC";
            S_StartMusic(mus_dm2ttl);
        }
        else
        {
            pagetic = 200;
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
            pagename = "CREDIT";
#else
            pagename = "HELP2";
#endif
        }
        break;
      case 5:
        G_DeferedPlayDemo ("demo3");
        break;
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
        // THE DEFINITIVE DOOM Special Edition demo
      case 6:
        G_DeferedPlayDemo ("demo4");
        break;
#endif
    }
}


 void __far D_DoomMain2(void);




extern void D_InitStrings();

extern angle_t __far* tantoangle;

// clears dead initialization code.
void __near Z_ClearDeadCode() {
	byte __far *startaddr =	(byte __far*)D_InitStrings;
	byte __far *endaddr =		(byte __far*)P_Init;
	
	//8830 bytes or so
	//8978 currently - 05/29/24
	//8342           - 06/01/24
	uint16_t size = endaddr - startaddr;
	FILE* fp;

	//I_Error("size: %u", size);

	FAR_memset(startaddr, 0, size);
	
	tantoangle = (angle_t __far* )startaddr;
	
	fp = fopen("D_TANTOA.BIN", "rb");
	FAR_fread(tantoangle, 4, 2049, fp);
	fclose(fp);

}
 void __near D_DoomMain(void) {
	 D_DoomMain2();
#ifdef DETAILED_BENCH_STATS
	 cachedtics = ticcount;
#endif
	 Z_ClearDeadCode();

	 D_DoomLoop();  // never returns
 }
