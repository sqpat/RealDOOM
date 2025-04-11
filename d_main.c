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
#include <stdarg.h>
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

//
// D_ProcessEvents
// Send all the events of the given timestamp down the responder chain
//
void __near D_ProcessEvents (void) {
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


// BIG TODO:
// asm all these. they arent super performance critical but the point is to make them small and take advantage of x86 string commands and such.


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


int16_t __far locallib_strlen(char __far *src){
	int16_t i = 0;
	while (src[i] != '\0'){
		i++;
	}
	return i;

}

uint8_t __far locallib_toupper(uint8_t ch){
	if (ch >=  0x61 && ch <= 0x7A){
		return ch - 0x20;
	}
	return ch;
}

void __far locallib_strcpy(char __far *dest, char __far *src){
	int16_t i = 0;
	while (src[i] != '\0'){
		dest[i] = src[i];
		i++;
	}
	dest[i] = '\0';

}

void __far locallib_strncpy(char __far *dest, char __far *src, int16_t n){
	int16_t i = 0;
	while (i < n){
        if (src[i] == '\0'){
        	while (i < n){
        		dest[i] = '\0';
                i++;
            }
            return;
        }
		dest[i] = src[i];
		i++;
	}
}


char __far locallib_printhexdigit (uint8_t digit, boolean printifzero){
	
	if (digit){
		if (digit < 0xA){
			digit = ('0' + digit);
		} else {
			digit = (55 + digit);
		}
	} else {
		if (printifzero){
			digit = ('0');
		} else {
			return 0;
		}
	}
	return(digit);
}




void __far locallib_printhex (uint32_t number, boolean islong, int8_t __near* outputtarget){
	uint32_t modder = 0xF000;
	int8_t shifter = 12;
	boolean printedonedigit = false;
	boolean printtostring = outputtarget != NULL;
	int8_t index = 0;
	int8_t thechar;

	if (islong){
		modder = 0xF0000000;
		shifter = 28;
	}
	while (shifter ){
		int8_t digit = (number&modder) >> shifter;
		thechar = locallib_printhexdigit(digit, printedonedigit);
		if (thechar){
			if (printtostring){
				outputtarget[index] = thechar;
				index++;
			} else {
				putchar(thechar);
			}
		}
		if (digit){
			printedonedigit = true;
		}
		modder >>= 4;
		shifter -=4;
	}
	
	

		thechar = locallib_printhexdigit((number&0x000F), true);
		if (printtostring){
			outputtarget[index] = thechar;
			outputtarget[index+1] = '\0';
		} else {
			putchar(thechar);
		}
	
}

 

void __far locallib_printdecimal (int32_t number){
	// 4 billion max


	if (number) {
		uint32_t positivenumber;
		boolean firstdigitprinted = false;
		int8_t i = 0;
		if (number < 0) {
			putchar('-');
			positivenumber = -number;
		} else {
			positivenumber = number;
		}

		for (i = 9; i >= 0; i--){
			uint32_t modder = 1;
			int8_t j = 0;
			for (j = 0; j < i; j++){
				modder = FastMul16u32u(10, modder);
			}
			j = 0;
			
			// modulo...
			while (positivenumber >= modder){
				positivenumber -= modder;
				j++;
			}

			if (j || firstdigitprinted){
				putchar('0' + j);
				firstdigitprinted = true;
			}

		}
	
	
	} else {
		putchar('0');
	}


}


void __far locallib_printstringfar (int8_t __far *str){
	int16_t i;
	for (i = 0; str[i] != '\0'; i++){
		putchar(str[i]);
	}
}

void __far locallib_printstringnear (int8_t __near *str){
	locallib_printstringfar(str);
}

void __far locallib_printf (int8_t __far*str, va_list argptr){
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
						locallib_printhex(va_arg(argptr, uint32_t), true, NULL);
					} else {
						locallib_printhex((uint32_t)va_arg(argptr, uint16_t), false, NULL);
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
/*
				case 'u':
				case 'U':
					locallib_printdecimal(va_arg(argptr, uint16_t));
					i+=2;
					continue;
*/
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


#if DEBUG_PRINTING


void __far DEBUG_PRINT (int8_t __far *error, ...){
    va_list argptr;
    
	va_start(argptr, error);
    locallib_printf(error, argptr);
    va_end(argptr);
}
#else
//void __far DEBUG_PRINT (int8_t *error, ...){ }
#endif

void locallib_strupr(char __far *str){
	int i = 0;
	while (str[i] != '\0'){
		if ((str[i] >= 'a') && (str[i] <= 'z')){
			str[i] -= 32;
		}
		i++;
	}
}
void locallib_strlwr(char __far *str){
	int i = 0;
	while (str[i] != '\0'){
		if ((str[i] >= 'A') && (str[i] <= 'Z')){
			str[i] += 32;
		}
		i++;
	}
}
void __far combine_strings(char __far *dest, char __far *src1, char __far *src2){
	int16_t i = 0;
	int16_t j = 0;
	while (src1[i] != '\0'){
		dest[i] = src1[i];
		i++;
	}
	while (src2[j] != '\0'){
		dest[i] = src2[j];
		i++;
		j++;
	}
	dest[i] = '\0';
}

int16_t __far locallib_strcmp(char __far *str1, char __far *str2){
	int16_t i = 0;
	while (str1[i]){
		int16_t b  = str1[i] - str2[i];
		if (b){
			return b;
		}
		i++;
	}
	return str1[i] - str2[i];
}


// todo leads to texture bugs, why?
int16_t __far locallib_strncasecmp(char __near *str1, char __far *str2, int16_t n){
	int8_t i = 0;
	while (i < n){
		int8_t a = locallib_toupper(str1[i]);
		int8_t b = locallib_toupper(str2[i]);
		int16_t diff = a - b;
		if (diff){
			return diff;
		}
		if (!a){
			return 0;
		}
		

		i++;
	}
	return 0;
}


/*

// not true to c standard
// optim assumption: str1 is always lowercase already
int16_t __far locallib_strcasecmp(char __far *str1, char __far *str2){
	int16_t i = 0;
	while (str1[i]){
		int16_t b  = str1[i] - tolower(str2[i]);
		if (b){
			return b;
		}
		i++;
	}
	return str1[i] - tolower(str2[i]);
}

*/


void __far makesavegamename(char __far *name, int8_t i){

        int8_t numstring[2];
        numstring[0] = '0' + i;
        numstring[1] = '\0';
        combine_strings(name, SAVEGAMENAME, numstring);
        combine_strings(name, name, ".dsg");

}

patch_t __far* M_GetMenuPatch(int16_t i);


void __near R_ExecuteSetViewSize (void);





//
// D_StartTitle
//
void __far D_StartTitle(void){

	gameaction = ga_nothing;
	demosequence = -1;
    advancedemo = true;
}

//
// D_Display
//  draw current display, possibly wiping it from the previous
//

void __near I_UpdateBox(int16_t x, int16_t y, int16_t w, int16_t h);

//
// I_UpdateNoBlit
//
void __far I_UpdateNoBlit(void) {
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
        I_UpdateBox(x, y, w, h);
    }
	// Clear box

	dirtybox[BOXTOP] = dirtybox[BOXRIGHT] = MINSHORT;
	dirtybox[BOXBOTTOM] = dirtybox[BOXLEFT] = MAXSHORT;
}

void __far I_FinishUpdate(void);




void __near D_Display (void) {
	int16_t                         y;
    boolean                     wipe;
    boolean                     redrawsbar;
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
    if (paused) {
        if (automapactive){
            y = 4;
		} else{
            y = viewwindowy+4;
		}
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
void checker(int16_t a);

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
		checker(gametic + 100);
		S_UpdateSounds (playerMobjRef);// move positional sounds
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

#ifdef DEBUGLOG_TO_FILE
				


//		if (gametic != lasttick) {
//			lasttick = gametic;
				

			//sprintf(result2, "%i %i %i \n", gametic, prndindex, SAV);
			//SAVEDUNIT = playerMobj;
			//SAVEDUNIT_POS = playerMobj_pos;
			SAVEDUNIT = &thinkerlist[222].data;
			SAVEDUNIT_POS = &mobjposlist_6800[222];
			//SAVEDUNIT = &thinkerlist[playerMobjRef].data;
			//if (gametic == 1) {
			//	fp = fopen("debuglog.txt", "w"); // clear old file
			//} else {
				fp = fopen("debuglog.txt", "a");
			//}
			//sprintf(result2, "%li %hhu %li %li %li %li %li %l %l %i \n", gametic, prndindex, SAVEDUNIT->x, SAVEDUNIT->y, SAVEDUNIT->z, SAVEDUNIT->momx, SAVEDUNIT->momy, SAVEDUNIT->floorz, SAVEDUNIT->ceilingz, SAVEDUNIT->secnum);
			fprintf(fp, "%li %i  %li %li %li %li %li %i %i %i\n", gametic, prndindex,   SAVEDUNIT->momx, SAVEDUNIT->momy, SAVEDUNIT_POS->z.w, SAVEDUNIT_POS->x.w, SAVEDUNIT_POS->y.w,SAVEDUNIT_POS->stateNum, SAVEDUNIT->tics);
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
          S_StartMusic(mus_dm2ttl);
		} else {
          S_StartMusic (mus_intro);
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
            S_StartMusic(mus_dm2ttl);
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


 void __far D_DoomMain2(void);




void D_InitStrings();


// clears dead initialization code.
void __near Z_ClearDeadCode() {
	byte __far *startaddr =	(byte __far*)D_InitStrings;
	byte __far *endaddr =		(byte __far*)P_Init;
	
	// accurate enough

	//8830 bytes or so
	//8978 currently - 05/29/24
	//8342           - 06/01/24
	//9350           - 10/07/24
	//11222          - 01/18/25		at this point like 3000 bytes to save.
	uint16_t size = endaddr - startaddr-16;
	FILE* fp;


	angle_t __far*  dest;
	
	tantoangle = FP_SEG(startaddr) + 1;
	//I_Error("size: %i", size);
	dest =  (angle_t __far* )MK_FP(tantoangle, 0);
	
	fp = fopen("DOOMDATA.BIN", "rb");
	fseek(fp, TANTOA_DOOMDATA_OFFSET, SEEK_SET);
	FAR_fread(dest, 4, 2049, fp);
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
