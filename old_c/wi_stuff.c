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
//	Intermission screens.
//

#include <stdio.h>

#include "z_zone.h"

#include "m_misc.h"

#include "i_system.h"

#include "w_wad.h"

#include "g_game.h"

#include "r_local.h"
#include "s_sound.h"

#include "doomstat.h"
#include "p_local.h"
// Data.
#include "sounds.h"

// Needs access to LFB.
#include "v_video.h"
#include "f_finale.h"

#include "wi_stuff.h"
#include "m_memory.h"
#include "m_near.h"

//
// Data needed to add patches to full screen intermission pics.
// Patches are statistics messages, and animations.
// Loads of by-pixel layout and placement, offsets etc.
//


//
// Different vetween registered DOOM (1994) and
//  Ultimate DOOM - Final edition (retail, 1995?).
// This is supposedly ignored for commercial
//  release (aka DOOM II), which had 34 maps
//  in one episode. So there.



// in tics
//U #define PAUSELEN		(TICRATE*2) 
//U #define SCORESTEP		100
//U #define ANIMPERIOD		32
// pixel distance from "(YOU)" to "PLAYER N"
//U #define STARDIST		10 
//U #define WK 1


// consider loading at startup...


//
// Animation locations for episode 0 (1).
// Using patches saves a lot of space,
//  as they replace 320x200 full screen frames.
//

// 16 bytes each, around 200-300 total.
 


//
// GENERAL DATA
//

//
// Locally used stuff.
//

 


// in seconds
//#define SHOWLASTLOCDELAY	SHOWNEXTLOCDELAY

patch_t __far* __near WI_GetPatch(int16_t i);
void __near maketwocharint(int16_t j, char __far *str );
void __near WI_slamBackground(void);
void __near WI_drawEL(void);
void __near WI_drawLF(void);

void __far  V_DrawPatch ( int16_t x, int16_t y, int8_t scrn, patch_t __far* patch);
patch_t __far* __near WI_GetAnimPatch(int16_t i);



/*
patch_t __far* __near WI_GetPatch(int16_t i) {
	return (patch_t __far*)(wigraphicspage0 + wioffsets[i]);
}

patch_t __far* __near WI_GetAnimPatch(int16_t i) {
	return (patch_t __far*)(wianimspage + wianimoffsets[i]);
}



//
// CODE
//

// slam background

void __near maketwocharint(int16_t j, char __far *str ){
	str[0] = '0' + j / 10;
	str[1] = '0' + j % 10;
	str[2] = '\0';

}


void __near WI_slamBackground(void) {
    FAR_memcpy(screen0, screen1, SCREENWIDTH * SCREENHEIGHT);
    V_MarkRect (0, 0, SCREENWIDTH, SCREENHEIGHT);
}



// Draws "<Levelname> Finished!"
void __near WI_drawLF(void) {
	int16_t y = WI_TITLEY;
	patch_t __far* finished = WI_GetPatch(5);
	// draw <LevelName> 
	patch_t __far* lname = (patch_t __far*)(wigraphicslevelname);

    V_DrawPatch((SCREENWIDTH - (lname->width))>>1, y, FB, lname);

    // draw "Finished!"
	y += (5 * (lname->height)) >>2;
    
    V_DrawPatch((SCREENWIDTH - (finished->width))>> 1, y, FB, finished);
}



// Draws "Entering <LevelName>"
void __near WI_drawEL(void) {
	patch_t __far* lname;
	int16_t y = WI_TITLEY;
	patch_t __far* entering = WI_GetPatch(27);
    // draw "Entering"
    V_DrawPatch((SCREENWIDTH - (entering->width))>>1, y, FB, entering);

	lname = (patch_t __far*)(wigraphicslevelname + NEXT_OFFSET);

    // draw level
    y += (5*(lname->height))>>2;


    V_DrawPatch((SCREENWIDTH - (lname->width))>>1, y, FB, lname);

}
*/
/*
void __near WI_drawOnLnode ( int16_t n, uint8_t* cRef ) {

    int16_t		i = 0;
    int16_t		left;
    int16_t		top;
    int16_t		right;
    int16_t		bottom;
    boolean	fits = false;
	patch_t __far* ci;
	int16_t index = wbs->epsd*10 + n;
	
	int16_t lnodeX = lnodex[index];
	int16_t lnodeY = lnodey[index];

    do {
		ci = WI_GetPatch(cRef[i]);
		left = lnodeX - (ci->leftoffset);
		top = lnodeY - (ci->topoffset);
		right = left + (ci->width);
		bottom = top + (ci->height);

		if (left >= 0
			&& right < SCREENWIDTH
			&& top >= 0
			&& bottom < SCREENHEIGHT) {
			fits = true;
		} else {
			i++;
		}
    } while (!fits && i!=2);

    if (fits && i<2) {
		V_DrawPatch(lnodeX, lnodeY, FB, (WI_GetPatch(cRef[i])));
    }
}

*/

/*

void __near WI_initAnimatedBack(void) {
    int16_t		i;
    wianim_t __far*	a;

    if (commercial){
		return;
	}

	if (wbs->epsd > 2){
		return;
	}


    for (i=0;i<NUMANIMS[wbs->epsd];i++) {
		a = &wianims[wbs->epsd][i];

		// init variables
		a->ctr = -1;

		// specify the next time to draw it
		if (a->type == ANIM_ALWAYS){
			a->nexttic = bcnt + 1 + (M_Random()%a->period);
		} else if (a->type == ANIM_RANDOM){
			a->nexttic = bcnt + 1 + 0+(M_Random()%a->data1);
		} else if (a->type == ANIM_LEVEL){
			a->nexttic = bcnt + 1;
		}
    }

}

*/
void __near WI_updateAnimatedBack(void);
void __near WI_drawAnimatedBack(void);
void __near WI_drawOnLnode ( int16_t n, uint8_t* cRef );


void __near WI_drawPercent ( int16_t x, int16_t y, int16_t p );
void __near WI_drawTime ( int16_t x, int16_t y, int16_t t );
void __near WI_initNoState(void);
void __near WI_initShowNextLoc(void);
void __near WI_updateShowNextLoc(void);
void __near WI_drawShowNextLoc(void);
void __near WI_drawNoState(void);
void __near WI_initStats(void);
void __near WI_checkForAccelerate(void);
void __near WI_updateStats(void);
void __near WI_loadData(void);
void __near WI_updateNoState(void);
void __near WI_drawStats(void);


/*
void __near WI_updateAnimatedBack(void) {
    int16_t		i;
    wianim_t __far*	a;

    if (commercial) {
		return;
	}

	if (wbs->epsd > 2){
		return;
	}

    for (i=0;i<NUMANIMS[wbs->epsd];i++) {
		a = &wianims[wbs->epsd][i];

		if (bcnt == a->nexttic) {
			switch (a->type) {
				case ANIM_ALWAYS:
					a->ctr++;
					if (a->ctr >= a->nanims) {
						a->ctr = 0;
					}
					a->nexttic = bcnt + a->period;
					break;

				case ANIM_RANDOM:
					a->ctr++;
					if (a->ctr == a->nanims) {
						a->ctr = -1;
						a->nexttic = bcnt+0+(M_Random()%a->data1);
					}
					else a->nexttic = bcnt + a->period;
					break;
				
				case ANIM_LEVEL:
					// gawd-awful hack for level anims
					if (!(state == StatCount && i == 7) && wbs->next == a->data1) {
						a->ctr++;
						if (a->ctr == a->nanims)  {
							a->ctr--;
						}
						a->nexttic = bcnt + a->period;
					}
					break;
			}
		}

    }

}

void __near WI_drawAnimatedBack(void) {
   
	int16_t i;
	wianim_t __far*anim;

	if (commercial) {
		return;
	}

	if (wbs->epsd > 2){
		return;
	}

	for (i = 0; i < NUMANIMS[wbs->epsd]; i++) {
		anim = &wianims[wbs->epsd][i];

		if (anim->ctr >= 0) {
			V_DrawPatch(anim->loc.x, anim->loc.y, FB, WI_GetAnimPatch(anim->pRef[anim->ctr]));
		}
	}

}
*/
//
// Draws a number.
// If digits > 0, then use that many digits minimum,
//  otherwise only use as many as necessary.
// Returns new x position.
//
/*

int16_t __near WI_drawNum ( int16_t x, int16_t y, int16_t n, int16_t digits ){
    
	int16_t		fontwidth = (WI_GetPatch(numRef[0]) ->width);
    int16_t		neg;
    int16_t		temp;

    if (digits < 0) {
		if (!n) {
			// make variable-length zeros 1 digit long
			digits = 1;
		} else {
			// figure out # of digits in #
			digits = 0;
			temp = n;

			while (temp) {
				temp /= 10;
				digits++;
			}
		}
    }

    neg = n < 0;
    if (neg){
		n = -n;
	}
    // if non-number, do not draw it
    if (n == 1994){
		return 0;
	}
    // draw the new number
    while (digits--) {
		x -= fontwidth;
		V_DrawPatch(x, y, FB, WI_GetPatch(numRef[ n % 10 ]));
		n /= 10;
    }

    // draw a minus sign if necessary
    if (neg){
		V_DrawPatch(x-=8, y, FB, WI_GetPatch(12));
	}
    return x;

}

void __near WI_drawPercent ( int16_t x, int16_t y, int16_t p ) {
    if (p < 0){
		return;
	}
    V_DrawPatch(x, y, FB, WI_GetPatch(13));
    WI_drawNum(x, y, p, -1);
}



//
// Display level completion time and par,
//  or "sucks" message if overflow.
//
void __near WI_drawTime ( int16_t x, int16_t y, int16_t t ) {

    int16_t		div;
    int16_t		n;
	patch_t __far* colon;
	patch_t __far* sucks;

    if (t<0){
		return;
	}
    if (t <= 61*59) {
		colon = WI_GetPatch(24);
		div = 1;
		do {
			n = (t / div) % 60;
			x = WI_drawNum(x, y, n, 2) - (colon->width);
			div *= 60;

			// draw
			if (div==60 || t / div)
			V_DrawPatch(x, y, FB, colon );
	    
		} while (t / div);
    } else {
		// "sucks"
		sucks = WI_GetPatch(25);
		V_DrawPatch(x - sucks->width, y, FB, sucks);
    }
}




void __near WI_initNoState(void) {
    state = NoState;
    acceleratestage = 0;
    cnt = 10;
}




void __near WI_initShowNextLoc(void) {
    state = ShowNextLoc;
    acceleratestage = 0;
    cnt = SHOWNEXTLOCDELAY * TICRATE;

    WI_initAnimatedBack();
}

void __near WI_updateShowNextLoc(void) {
    WI_updateAnimatedBack();

	if (!--cnt || acceleratestage) {
		WI_initNoState();
	} else {
		snl_pointeron = (cnt & 31) < 20;
	}
}

void __near WI_drawShowNextLoc(void) {

    int16_t		i;
    int16_t		last;

    WI_slamBackground();

    // draw animated background
    WI_drawAnimatedBack(); 

    if (!commercial) {
		if (wbs->epsd > 2) {
			WI_drawEL();
			return;
		}
	
		
		last = (wbs->last == 8) ? wbs->next - 1 : wbs->last;

		// draw a splat on taken cities.
		for (i = 0; i <= last; i++) {
			WI_drawOnLnode(i, &splatRef);
		}

		// splat the secret level?
		if (wbs->didsecret){
			WI_drawOnLnode(8, &splatRef);
		}

		// draw flashing ptr
		if (snl_pointeron){
			WI_drawOnLnode(wbs->next, yahRef); 
		}
    }

    // draws which level you are entering..
    if ( (!commercial) || wbs->next != 30){
		WI_drawEL();  
	}

}

void __near WI_drawNoState(void) {
    snl_pointeron = true;
    WI_drawShowNextLoc();
}
 


void __near WI_initStats(void) {
    state = StatCount;
    acceleratestage = 0;
    sp_state = 1;
    cnt_kills = cnt_items = cnt_secret = -1;
    cnt_time = cnt_par = -1;
    cnt_pause = TICRATE;

    WI_initAnimatedBack();
}


void __near WI_updateStats(void) {

    WI_updateAnimatedBack();

    if (acceleratestage && sp_state != 10) {
		acceleratestage = 0;
		cnt_kills = (plrs.skills * 100) / wbs->maxkills;
		cnt_items = (plrs.sitems * 100) / wbs->maxitems;
		cnt_secret = (plrs.ssecret * 100) / wbs->maxsecret;
		cnt_time = plrs.stime;
		cnt_par = wbs->partime / TICRATE;
		S_StartSound(0, sfx_barexp);
		sp_state = 10;
    }

	if (sp_state == 2) {
		cnt_kills += 2;

		if (!(bcnt&3)){
			S_StartSound(0, sfx_pistol);
		}
		if (cnt_kills >= (plrs.skills * 100) / wbs->maxkills) {
			cnt_kills = (plrs.skills * 100) / wbs->maxkills;
			S_StartSound(0, sfx_barexp);
			sp_state++;
		}
    } else if (sp_state == 4) {
		cnt_items += 2;

		if (!(bcnt&3)){
			S_StartSound(0, sfx_pistol);
		}
		if (cnt_items >= (plrs.sitems * 100) / wbs->maxitems) {
			cnt_items = (plrs.sitems * 100) / wbs->maxitems;
			S_StartSound(0, sfx_barexp);
			sp_state++;
		}
    } else if (sp_state == 6) {
		cnt_secret += 2;

		if (!(bcnt&3)){
			S_StartSound(0, sfx_pistol);
		}
		if (cnt_secret >= (plrs.ssecret * 100) / wbs->maxsecret) {
			cnt_secret = (plrs.ssecret * 100) / wbs->maxsecret;
			S_StartSound(0, sfx_barexp);
			sp_state++;
		}
    } else if (sp_state == 8) {
		if (!(bcnt&3)){
			S_StartSound(0, sfx_pistol);
		}
		cnt_time += 3;

		if (cnt_time >= plrs.stime){
			cnt_time = plrs.stime;
		}
		cnt_par += 3;

		if (cnt_par >= wbs->partime / TICRATE) {
			cnt_par = wbs->partime / TICRATE;

			if (cnt_time >= plrs.stime) {
				S_StartSound(0, sfx_barexp);
				sp_state++;
			}
		}
    }
    else if (sp_state == 10) {
		if (acceleratestage) {
			S_StartSound(0, sfx_sgcock);

			if (commercial) {
				WI_initNoState();
			} else {
				WI_initShowNextLoc();
			}
		}
    } else if (sp_state & 1) {
		if (!--cnt_pause) {
			sp_state++;
			cnt_pause = TICRATE;
		}
    }

}

void __near WI_drawStats(void) {
    // line height
	int16_t lh;

	patch_t __far* num0 = WI_GetPatch(numRef[0]);

    lh = (3*(num0->height))/2;

    WI_slamBackground();

    // draw animated background
    WI_drawAnimatedBack();
    
    WI_drawLF();

    V_DrawPatch(SP_STATSX, SP_STATSY, FB, WI_GetPatch(3));
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY, cnt_kills);

    V_DrawPatch(SP_STATSX, SP_STATSY+lh, FB, WI_GetPatch(4));
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY+lh, cnt_items);

    V_DrawPatch(SP_STATSX, SP_STATSY+2*lh, FB, WI_GetPatch(26));
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY+2*lh, cnt_secret);

    V_DrawPatch(SP_TIMEX, SP_TIMEY, FB, WI_GetPatch(9));
    WI_drawTime(SCREENWIDTH/2 - SP_TIMEX, SP_TIMEY, cnt_time);

	if (wbs->epsd < 3) {
		V_DrawPatch(SCREENWIDTH/2 + SP_TIMEX, SP_TIMEY, FB, WI_GetPatch(10));
		WI_drawTime(SCREENWIDTH - SP_TIMEX, SP_TIMEY, cnt_par);
    }

}

void __near WI_checkForAccelerate(void) {
 
	if (player.cmd.buttons & BT_ATTACK) {
		if (!player.attackdown){
			acceleratestage = 1;
		}
		player.attackdown = true;
	} else {
		player.attackdown = false;
	}
	if (player.cmd.buttons & BT_USE) {
		if (!player.usedown) {
			acceleratestage = 1;
		}
		player.usedown = true;
	} else {
		player.usedown = false;
	}
}



void __near WI_loadData(void) {
    int16_t		i;
	int8_t	name1[9] = "INTERPIC";
	int8_t	name2[9] = "WIMAP0";
	int8_t* name = name2;

    if (commercial){
		name = name1;
	} else {
		name2[5]+= wbs->epsd;
	}
	if (wbs->epsd == 3){
		name = name1;
	}

    // background
	V_DrawFullscreenPatch(name, 1); // scratch also used here

    if (!commercial) {

		// you are here
		yahRef[0] = 0;

		// you are here (alt.)
		yahRef[1] = 1;

		// splat
		splatRef = 2;
		
		if (wbs->epsd < 3) {
			wianim_t __far*	anim;
			int16_t j = 0;
			int16_t k = 0;
			uint16_t size = 0;
			uint16_t lumpsize = 0;
			int16_t lump;
			byte __far* dst = wianimspage;
			for (j=0;j<NUMANIMS[wbs->epsd];j++) {
				anim = &wianims[wbs->epsd][j];
				for (i=0;i<anim->nanims;i++) {
					// MONDO HACK!
					if (wbs->epsd != 1 || j != 8) {
						// animations

						int8_t numstring0[2];
						int8_t numstring1[3];
						int8_t numstring2[3];
						numstring0[0] = '0' + wbs->epsd;
						numstring0[1] = '\0';
						maketwocharint(j, numstring1);
						maketwocharint(i, numstring2);
						combine_strings(name, "WIA", numstring0);
						combine_strings(name, name, numstring1);
						combine_strings(name, name, numstring2);

						lump = W_GetNumForName(name);
						lumpsize = W_LumpLength(lump);
						W_CacheLumpNumDirect(lump, dst);
						wianimoffsets[k] = size;
						size += lumpsize;
						dst += lumpsize;
 
						anim->pRef[i] = k;
						k++;

					} else {
						// HACK ALERT!
						anim->pRef[i] = epsd1animinfo[4].pRef[i];
					}
				}
			}
		}


	}
	for (i = 0; i < 10; i++) {
		numRef[i] = 14 + i;
	}
        				    
 

}

     

//
// G_WorldDone 
//
void __near G_WorldDone (void)  { 
    gameaction = ga_worlddone; 

    if (secretexit) {
        player.didsecret = true; 
	}

    if ( commercial ) {
        switch (gamemap) {
			case 15:
			case 31:
				if (!secretexit)
					break;
			case 6:
			case 11:
			case 20:
			case 30:
		        Z_SetOverlay(OVERLAY_ID_FINALE);
				F_StartFinale ();
				break;
        }
    }
} 

void __near WI_unloadData(void){
	unloaded = true;
}
void __near WI_End(void) {
    WI_unloadData();
}

void __near WI_updateNoState(void) {

    WI_updateAnimatedBack();

    if (!--cnt) {
		WI_End();
		G_WorldDone();
    }

}



// Updates stuff each tick
void __far  WI_Ticker(void) {
	// counter for general background animation
	bcnt++;
	if (bcnt == 1) {
		// intermission music
		if (commercial){
			S_ChangeMusic(mus_dm2int, true);
		} else {
			S_ChangeMusic(mus_inter, true);
		}
	}

	Z_QuickMapIntermission();
	WI_checkForAccelerate();

	switch (state) {
		case StatCount:
			WI_updateStats();
			break;

		case ShowNextLoc:
			WI_updateShowNextLoc();
			break;

		case NoState:
			WI_updateNoState();
			break;
	}
	Z_QuickMapPhysics();

}

void __far WI_Drawer (void) {
	
	if (unloaded) {
		return;
	}

	Z_QuickMapIntermission();

    switch (state) {
		case StatCount:
			WI_drawStats();
			break;
	
		case ShowNextLoc:
			WI_drawShowNextLoc();
			break;
	
		case NoState:
			WI_drawNoState();
			break;
    }
	Z_QuickMapPhysics();
}
 

void __near WI_initVariables(wbstartstruct_t __near* wbstartstruct) {
	wbs = wbstartstruct;
	acceleratestage = 0;
	cnt = bcnt = 0;
	plrs = wbs->plyr;

	if (!wbs->maxkills){
		wbs->maxkills = 1;
	}

	if (!wbs->maxitems){
		wbs->maxitems = 1;
	}

	if (!wbs->maxsecret){
		wbs->maxsecret = 1;
	}
}
*/
/*
void __near WI_Init(void) {

	int16_t i = 0;
	int8_t j = 0;
	uint32_t size = 0;
	byte __far* dst = wigraphicspage0;
	int8_t	name[9];
	int16_t k = 0;
	int16_t lump;
	uint16_t lumpsize;


	for (i = 0; i < NUM_WI_ITEMS; i++, k+=9) {
		// this produces smaller code than the far strcpy call...
		for (j = 0; j < 9; j++){
			name[j]=wigraphics[k+j];
		}

		lump = W_GetNumForName(name);

		lumpsize = W_LumpLength(lump);
		
		W_CacheLumpNumDirect(lump, dst);
		wioffsets[i] = size;
		size += lumpsize;
		dst += lumpsize;

	}


	if (commercial) {
		int8_t temp[3];
		dst = wigraphicslevelname;
		maketwocharint(wbs->last, temp);
        combine_strings(name, "CWILV", temp);

		W_CacheLumpNameDirect(name, dst);

		maketwocharint(wbs->next, temp);
		dst = (byte __far *)(wigraphicslevelname + NEXT_OFFSET);
        combine_strings(name, "CWILV", temp);
		W_CacheLumpNameDirect(name, dst);

	} else {
		int8_t temp[2];
		temp[1] = '\0';
		dst = wigraphicslevelname;

		temp[0] = '0' + wbs->epsd;        
		combine_strings(name, "WILV", temp);
		temp[0] = '0' + wbs->last;
        combine_strings(name, name, temp);

		W_CacheLumpNameDirect(name, dst);

		dst = (byte __far *)(wigraphicslevelname + NEXT_OFFSET);
        
		temp[0] = '0' + wbs->epsd;        
		combine_strings(name, "WILV", temp);
		temp[0] = '0' + wbs->next;
        combine_strings(name, name, temp);

		
		W_CacheLumpNameDirect(name, dst);
	}
}	
*/
/*

void __far WI_Start(wbstartstruct_t __near* wbstartstruct) {
	unloaded = false;
	// called before WI_Start
	//Z_QuickMapIntermission();
	
	WI_initVariables(wbstartstruct);
	WI_Init();
	WI_loadData();
	WI_initStats();

	Z_QuickMapPhysics();

}


*/
