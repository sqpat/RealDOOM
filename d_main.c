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
#include <dos.h>
//#include <graph.h>
#include <direct.h>
#include <io.h>
#include <fcntl.h>
#include <alloca.h>

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
 

 
 

//
// D-DoomLoop()
// Not a globally visible function,
//  just included for source reference,
//  called by D_DoomMain, never exits.
// Manages timing and IO,
//  calls all ?_Responder, ?_Ticker, and ?_Drawer,
//  calls I_GetTime,  and I_StartTic
//


int8_t*           wadfiles[MAXWADFILES];


boolean         nomonsters;     // checkparm of -nomonsters
boolean         respawnparm;    // checkparm of -respawn
boolean         fastparm;       // checkparm of -fast

boolean         drone;

boolean         singletics = false; // debug flag to cancel adaptiveness




extern  boolean inhelpscreens;

skill_t         startskill;
int8_t             startepisode;
int8_t             startmap;
boolean         autostart;


boolean         advancedemo;

boolean         modifiedgame;

boolean         shareware;
boolean         registered;
boolean         commercial;

extern uint8_t     sfxVolume;
extern uint8_t     musicVolume;
int8_t      demosequence;

#if (EXE_VERSION >= EXE_VERSION_FINAL)
boolean         plutonia;
boolean         tnt;
#endif


int8_t            wadfile[1024];          // primary wad file
int8_t            basedefault[1024];      // default file


void G_BuildTiccmd(int8_t index);
//void G_BuildTiccmd (ticcmd_t* cmd);
void D_DoAdvanceDemo (void);


//
// EVENT HANDLING
//
// Events are asynchronous inputs generally generated by the game user.
// Events can be discarded if no responder claims them
//
event_t		events[MAXEVENTS];
int8_t		eventhead;
int8_t		eventtail;


//
// D_PostEvent
// Called by the I/O functions when input is detected
//
void D_PostEvent (event_t* ev)
{
    events[eventhead] = *ev;
    eventhead = (++eventhead)&(MAXEVENTS-1);
}

//
// D_ProcessEvents
// Send all the events of the given timestamp down the responder chain
//
void D_ProcessEvents (void)
{
    event_t*     ev;
	for ( ; eventtail != eventhead ; eventtail = (++eventtail)&(MAXEVENTS-1) ) {
		ev = &events[eventtail];
		if (M_Responder(ev)) {
			continue;
		}

		G_Responder (ev);
	}
}

#define MAX_STRINGS 306

uint16_t stringoffsets[MAX_STRINGS];
uint16_t stringbuffersize;
byte* stringdata;

int16_t getStringLength(int16_t stringindex) {
	return  stringoffsets[stringindex + 1] - stringoffsets[stringindex];
}

void getStringByIndex(int16_t stringindex, int8_t* returndata) {

	uint16_t stringoffset = stringoffsets[stringindex];
	uint16_t length = getStringLength(stringindex);
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
	memcpy(returndata, &(stringdata[stringoffset]), length);
	// add null terminator?
	returndata[length] = '\0';

	//return length;
}





// Fixme. __USE_C_FIXED__ or something.

fixed_t32 FixedMul (fixed_t32	a, fixed_t32 b) {
    // fixed_t_union fp;
    // fp.w = ((long long)a * (long long)b);
    // return fp.h.intbits;
    longlong_union llu;
    llu.l =  ((long long)a * (long long)b);
	return llu.productresult.usemid;
}

fixed_t32 FixedMul1632(int16_t	a, fixed_t32 b) {
	// fixed_t_union fp;
	// fp.w = ((long long)a * (long long)b);
	// return fp.h.intbits;
	longlong_union llu;
	llu.l = (a * (long long)b);
	return llu.productresult.usemid;
}

fixed_t32 FixedMul16u32(uint16_t	a, fixed_t32 b) {
	// fixed_t_union fp;
	// fp.w = ((long long)a * (long long)b);
	// return fp.h.intbits;
	longlong_union llu;
	llu.l = (a * (long long)b);
	return llu.productresult.usemid;
}

fixed_t32 FixedMulBig1632 (int16_t	a, fixed_t	b) {
    fixed_t_union biga;
	longlong_union llu;
	biga.h.intbits = a;
	biga.h.fracbits = 0;
	llu.l = (biga.w * (long long)b);
	return llu.productresult.usemid;
}

 

fixed_t32 FixedMul1616(int16_t	a, int16_t	b) {
	return (int32_t)a * b;
}




fixed_t32
FixedDiv2
(fixed_t32	a, fixed_t32	b
	//,int8_t* file, int32_t line
)
{
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

//fixed_t32 FixedDivinner(fixed_t32	a, fixed_t32 b int8_t* file, int32_t line)
fixed_t32 FixedDiv(fixed_t32	a, fixed_t32	b) {
	if ((labs(a) >> 14) >= labs(b))
		return (a^b) < 0 ? MINLONG : MAXLONG;
	//return FixedDiv2(a, b, file, line);
	return FixedDiv2(a, b);
}


extern patch_t* far M_GetMenuPatch(int16_t i);


boolean skipdirectdraws;
// wipegamestate can be set to -1 to force a wipe on the next draw
gamestate_t     wipegamestate = GS_DEMOSCREEN;
extern  boolean setsizeneeded;
extern  uint8_t             showMessages;
void R_ExecuteSetViewSize (void);

uint16_t                         wipeduration = 0;


#ifdef DETAILED_BENCH_STATS
uint16_t rendertics = 0;
uint16_t physicstics = 0;
uint16_t othertics = 0;
uint16_t cachedtics = 0;
uint16_t cachedrendertics = 0;
uint16_t rendersetuptics = 0;
uint16_t renderplayerviewtics = 0;
uint16_t renderpostplayerviewtics = 0;

uint16_t renderplayersetuptics = 0;
uint16_t renderplayerbsptics = 0;
uint16_t renderplayerplanetics = 0;
uint16_t renderplayermaskedtics = 0;
uint16_t cachedrenderplayertics = 0;
#endif

//
// D_Display
//  draw current display, possibly wiping it from the previous
//

void D_Display (void)
{
    static  boolean             viewactivestate = false;
    static  boolean             menuactivestate = false;
    static  boolean             inhelpscreensstate = false;
    static  boolean             fullscreen = false;
    static  gamestate_t         oldgamestate = -1;
    static  uint8_t                 borderdrawcount;
	ticcount_t                         nowtime, wipestart;
	ticcount_t                         wiperealstart;
	int16_t                         tics;
	int16_t                         y;
    boolean                     wipe;
    boolean                     redrawsbar;
	boolean						done = false;

	if (nodrawers)
        return;                    // for comparative timing / profiling
 
#ifdef DETAILED_BENCH_STATS
	cachedrendertics = ticcount;
#endif
    redrawsbar = false;


    // change the view size if needed
    if (setsizeneeded)
    {
        R_ExecuteSetViewSize ();
        oldgamestate = -1;                      // force background redraw
        borderdrawcount = 3;
    }

#ifndef SKIPWIPE

    // save the current screen if about to wipe
    if (gamestate != wipegamestate)
    {
        wipe = true;
        wipe_StartScreen();
    } else{
        wipe = false;
    }

#else
	wipe = false;  // turn wipes off
#endif
	if (gamestate == GS_LEVEL && gametic) {
		HU_Erase();
 	}

    // do buffered drawing
    switch (gamestate)
    {
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
		Z_QuickmapStatus();
        F_Drawer ();
		Z_QuickmapPhysics();
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
		Z_QuickmapMenu();		
        V_DrawPatchDirect(viewwindowx+(scaledviewwidth-68)/2, y, M_GetMenuPatch(12));
		Z_QuickmapPhysics();

    }

    // menus go directly to the screen
	M_Drawer ();          // menu is drawn even on top of everything

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
	wipeduration = ticcount - wiperealstart;
}
void checkstrings(int16_t j) {

	int16_t i = 0;
	uint32_t adder = 0;

	if (currenttask != TASK_PHYSICS) {
		I_Error("Bad task here %i %i", currenttask, j);

	}
	for (i = 0; i < 16384; i++) {
		adder += stringdata[i];
	}
	//I_Error("\n%lu", adder);
	if (adder != 1279414) {
		I_Error("Error here %li %i", gametic, j);
	}
	adder = 0;

	for (i = 0; i < MAX_STRINGS; i++) {
		adder += stringoffsets[i];
	}

	if (adder != 1583059) {
		I_Error("bad stringoffsets! %li %i %li", gametic, j, adder);
	}
}
 

//
//  D_DoomLoop
//
extern  boolean         demorecording;
// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
void I_InitGraphics(void);

void D_DoomLoop (void)
{
	// debugging stuff i need to find mem leaks...
#ifdef DEBUGLOG_TO_FILE
	//int8_t result2[100];
	//int32_t lasttick = 0;
	FILE* fp;
#endif


	//plat_t* plat;
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

   
#ifdef DEBUGLOG_TO_FILE
			
//		if (gametic != lasttick) {
//			lasttick = gametic;
				
			//sprintf(result2, "%i %i %i \n", gametic, prndindex, SAV);
			SAVEDUNIT = playerMobj;// Z_LoadThinkerBytesFromEMS(1483); // 1457
			//SAVEDUNIT = &thinkerlist[playerMobjRef].data;
			if (gametic == 1) {
				fp = fopen("debuglog.txt", "w"); // clear old file
			} else {
				fp = fopen("debuglog.txt", "a");
			}
			//sprintf(result2, "%li %hhu %li %li %li %li %li %l %l %i \n", gametic, prndindex, SAVEDUNIT->x, SAVEDUNIT->y, SAVEDUNIT->z, SAVEDUNIT->momx, SAVEDUNIT->momy, SAVEDUNIT->floorz, SAVEDUNIT->ceilingz, SAVEDUNIT->secnum);
			fprintf(fp, "%li %hhu %li %li %li %li %li %i %li %i \n", gametic, prndindex, SAVEDUNIT->x, SAVEDUNIT->y, SAVEDUNIT->z, SAVEDUNIT->momx, SAVEDUNIT->momy, SAVEDUNIT->health, SAVEDUNIT->angle, SAVEDUNIT->secnum);
			//fprintf(result2, fp);
			fclose(fp);
				
 
#endif
		
		
	}
}



//
//  DEMO LOOP
//
int8_t             demosequence;
int16_t             pagetic;
int8_t                    *pagename;


//
// D_PageTicker
// Handles timing for warped projection
//
void D_PageTicker (void)
{
    if (--pagetic < 0)
        D_AdvanceDemo ();
}



//
// D_PageDrawer
//
void D_PageDrawer (void)
{

	// we dont have various screen buffers anymore, so we cant draw to buffer in 'read this'
	// screen - this would draw direct to screen and overwrite the read this screen.
	// so we just dont draw titlepic in that situation
	if (inhelpscreens) { 
		return;
	}

	 V_DrawFullscreenPatch(pagename);
}


//
// D_AdvanceDemo
// Called after each demo or intro demosequence finishes
//
void D_AdvanceDemo (void)
{
    advancedemo = true;
}


//
// This cycles through the demo sequences.
// FIXME - version dependend demo numbers?
//
 void D_DoAdvanceDemo (void)
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


 void D_DoomMain2(void);


 void D_DoomMain(void) {
	 D_DoomMain2();
#ifdef DETAILED_BENCH_STATS
	 cachedtics = ticcount;
#endif
	 D_DoomLoop();  // never returns
 }
