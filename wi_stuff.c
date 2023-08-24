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

// Data.
#include "sounds.h"

// Needs access to LFB.
#include "v_video.h"

#include "wi_stuff.h"

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
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
#define NUMEPISODES	3
#else
#define NUMEPISODES	4
#endif
#define NUMMAPS		9


// in tics
//U #define PAUSELEN		(TICRATE*2) 
//U #define SCORESTEP		100
//U #define ANIMPERIOD		32
// pixel distance from "(YOU)" to "PLAYER N"
//U #define STARDIST		10 
//U #define WK 1


// GLOBAL LOCATIONS
#define WI_TITLEY		2
#define WI_SPACINGY    		33

// SINGPLE-PLAYER STUFF
#define SP_STATSX		50
#define SP_STATSY		50

#define SP_TIMEX		16
#define SP_TIMEY		(SCREENHEIGHT-32)


// NET GAME STUFF
#define NG_STATSY		50

#define NG_SPACINGX    		64


 



typedef enum
{
    ANIM_ALWAYS,
    ANIM_RANDOM,
    ANIM_LEVEL

} animenum_t;

typedef struct
{
    int		x;
    int		y;
    
} point_t;


//
// Animation.
// There is another anim_t used in p_spec.
//
typedef struct
{
    animenum_t	type;

    // period in tics between animations
    int		period;

    // number of animation frames
    int		nanims;

    // location of animation
    point_t	loc;

    // ALWAYS: n/a,
    // RANDOM: period deviation (<256),
    // LEVEL: level
    int		data1;

    // ALWAYS: n/a,
    // RANDOM: random base period,
    // LEVEL: n/a
    int		data2; 

    // actual graphics for frames of animations
    MEMREF	pRef[3]; 

    // following must be initialized to zero before use!

    // next value of bcnt (used in conjunction with period)
    int		nexttic;

    // last drawn animation frame
    int		lastdrawn;

    // next frame number to animate
    int		ctr;
    
    // used by RANDOM and LEVEL when animating
    int		state;  

} anim_t;


static point_t lnodes[NUMEPISODES][NUMMAPS] =
{
    // Episode 0 World Map
    {
	{ 185, 164 },	// location of level 0 (CJ)
	{ 148, 143 },	// location of level 1 (CJ)
	{ 69, 122 },	// location of level 2 (CJ)
	{ 209, 102 },	// location of level 3 (CJ)
	{ 116, 89 },	// location of level 4 (CJ)
	{ 166, 55 },	// location of level 5 (CJ)
	{ 71, 56 },	// location of level 6 (CJ)
	{ 135, 29 },	// location of level 7 (CJ)
	{ 71, 24 }	// location of level 8 (CJ)
    },

    // Episode 1 World Map should go here
    {
	{ 254, 25 },	// location of level 0 (CJ)
	{ 97, 50 },	// location of level 1 (CJ)
	{ 188, 64 },	// location of level 2 (CJ)
	{ 128, 78 },	// location of level 3 (CJ)
	{ 214, 92 },	// location of level 4 (CJ)
	{ 133, 130 },	// location of level 5 (CJ)
	{ 208, 136 },	// location of level 6 (CJ)
	{ 148, 140 },	// location of level 7 (CJ)
	{ 235, 158 }	// location of level 8 (CJ)
    },

    // Episode 2 World Map should go here
    {
	{ 156, 168 },	// location of level 0 (CJ)
	{ 48, 154 },	// location of level 1 (CJ)
	{ 174, 95 },	// location of level 2 (CJ)
	{ 265, 75 },	// location of level 3 (CJ)
	{ 130, 48 },	// location of level 4 (CJ)
	{ 279, 23 },	// location of level 5 (CJ)
	{ 198, 48 },	// location of level 6 (CJ)
	{ 140, 25 },	// location of level 7 (CJ)
	{ 281, 136 }	// location of level 8 (CJ)
    }

};


//
// Animation locations for episode 0 (1).
// Using patches saves a lot of space,
//  as they replace 320x200 full screen frames.
//
static anim_t epsd0animinfo[] =
{
    { ANIM_ALWAYS, TICRATE/3, 3, { 224, 104 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 184, 160 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 112, 136 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 72, 112 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 88, 96 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 64, 48 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 192, 40 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 136, 16 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 80, 16 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 64, 24 } }
};

static anim_t epsd1animinfo[] =
{
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 1 },
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 2 },
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 3 },
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 4 },
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 5 },
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 6 },
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 7 },
    { ANIM_LEVEL, TICRATE/3, 3, { 192, 144 }, 8 },
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 8 }
};

static anim_t epsd2animinfo[] =
{
    { ANIM_ALWAYS, TICRATE/3, 3, { 104, 168 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 40, 136 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 160, 96 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 104, 80 } },
    { ANIM_ALWAYS, TICRATE/3, 3, { 120, 32 } },
    { ANIM_ALWAYS, TICRATE/4, 3, { 40, 0 } }
};

static int NUMANIMS[NUMEPISODES] =
{
    sizeof(epsd0animinfo)/sizeof(anim_t),
    sizeof(epsd1animinfo)/sizeof(anim_t),
    sizeof(epsd2animinfo)/sizeof(anim_t)
};

static anim_t *anims[NUMEPISODES] =
{
    epsd0animinfo,
    epsd1animinfo,
    epsd2animinfo
};


//
// GENERAL DATA
//

//
// Locally used stuff.
//
#define FB 0


// States for single-player
#define SP_KILLS		0
#define SP_ITEMS		2
#define SP_SECRET		4
#define SP_FRAGS		6 
#define SP_TIME			8 
#define SP_PAR			ST_TIME

#define SP_PAUSE		1

// in seconds
#define SHOWNEXTLOCDELAY	4
//#define SHOWLASTLOCDELAY	SHOWNEXTLOCDELAY


// used to accelerate or skip a stage
static int		acceleratestage;

// wbs->pnum
static int		me;

 // specifies current state
static stateenum_t	state;

// contains information passed into intermission
static wbstartstruct_t*	wbs;

static wbplayerstruct_t* plrs;  // wbs->plyr[]

// used for general timing
static int 		cnt;  

// used for timing of background animation
static int 		bcnt;

// signals to refresh everything for one frame
static int 		firstrefresh; 

static int		cnt_kills[MAXPLAYERS];
static int		cnt_items[MAXPLAYERS];
static int		cnt_secret[MAXPLAYERS];
static int		cnt_time;
static int		cnt_par;
static int		cnt_pause;

// # of commercial levels
static int		NUMCMAPS; 


//
//	GRAPHICS
//

// background (map of levels).
static MEMREF		bgRef;

// You Are Here graphic
static MEMREF		yahRef[2];

// splat
static MEMREF		splatRef;

// %, : graphics
static MEMREF		percentRef;
static MEMREF		colonRef;

// 0-9 graphic
static MEMREF		numRef[10];

// minus sign
static MEMREF		wiminusRef;

// "Finished!" graphics
static MEMREF		finishedRef;

// "Entering" graphic
static MEMREF		enteringRef;

// "secret"
static MEMREF		sp_secretRef;

 // "Kills", "Scrt", "Items", "Frags"
static MEMREF		killsRef;
static MEMREF		secretRef;
static MEMREF		itemsRef;

// Time sucks.
static MEMREF		timeRef;
static MEMREF		parRef;
static MEMREF		sucksRef;


// "Total", your face, your dead face
static MEMREF		totalRef;
static MEMREF		starRef;
static MEMREF		bstarRef;

// "red P[1..MAXPLAYERS]"
static MEMREF		pRef[MAXPLAYERS];

// "gray P[1..MAXPLAYERS]"
static MEMREF		bpRef[MAXPLAYERS];

 // Name graphics of each level (centered)
MEMREF				lnamesRef;

//
// CODE
//

// slam background


void WI_slamBackground(void)
{
    memcpy(screens[0], screens[1], SCREENWIDTH * SCREENHEIGHT);
    V_MarkRect (0, 0, SCREENWIDTH, SCREENHEIGHT);
}

 

// Draws "<Levelname> Finished!"
void WI_drawLF(void)
{
	patch_t* lname;
    int y = WI_TITLEY;
	MEMREF* lnames = (MEMREF*)Z_LoadBytesFromEMS(lnamesRef);
	lname = (patch_t*)Z_LoadBytesFromEMS(lnames[wbs->last]);
	// draw <LevelName> 

//    V_DrawPatch((SCREENWIDTH - SHORT(lnames[wbs->last]->width))/2, y, FB, lnames[wbs->last]);

    // draw "Finished!"
	y += (5 * SHORT(lname ->height)) / 4;
    
//    V_DrawPatch((SCREENWIDTH - SHORT(finished->width))/2, y, FB, finished);
}



// Draws "Entering <LevelName>"
void WI_drawEL(void)
{
	patch_t* lname;
	int y = WI_TITLEY;
	MEMREF* lnames;
	patch_t* entering = (patch_t*)Z_LoadBytesFromEMS(enteringRef);
    // draw "Entering"
    V_DrawPatch(SCREENWIDTH - SHORT(entering->width)/2, y, FB, entering);


	lnames = (MEMREF*)Z_LoadBytesFromEMS(lnamesRef);
	lname = (patch_t*)Z_LoadBytesFromEMS(lnames[wbs->next]);

    // draw level
    y += (5*SHORT(lname->height))/4;


    V_DrawPatch((SCREENWIDTH - SHORT(lname->width))/2,
		y, FB, lname);

}

void
WI_drawOnLnode
( int		n,
  MEMREF*	cRef )
{

    int		i;
    int		left;
    int		top;
    int		right;
    int		bottom;
    boolean	fits = false;
	patch_t* ci;

    i = 0;
    do {
		ci = (patch_t*)Z_LoadBytesFromEMS(cRef[i]);
		left = lnodes[wbs->epsd][n].x - SHORT(ci->leftoffset);
		top = lnodes[wbs->epsd][n].y - SHORT(ci->topoffset);
		right = left + SHORT(ci->width);
		bottom = top + SHORT(ci->height);

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
		V_DrawPatch(lnodes[wbs->epsd][n].x, lnodes[wbs->epsd][n].y, FB, ((patch_t*)Z_LoadBytesFromEMS(cRef[i])));
    } else {
		// DEBUG
		printf("Could not place patch on level %d", n+1); 
    }
}



void WI_initAnimatedBack(void)
{
    int		i;
    anim_t*	a;

    if (commercial)
	return;

#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    if (wbs->epsd > 2)
	return;
#endif

    for (i=0;i<NUMANIMS[wbs->epsd];i++)
    {
	a = &anims[wbs->epsd][i];

	// init variables
	a->ctr = -1;

	// specify the next time to draw it
	if (a->type == ANIM_ALWAYS)
	    a->nexttic = bcnt + 1 + (M_Random()%a->period);
	else if (a->type == ANIM_RANDOM)
	    a->nexttic = bcnt + 1 + a->data2+(M_Random()%a->data1);
	else if (a->type == ANIM_LEVEL)
	    a->nexttic = bcnt + 1;
    }

}

void WI_updateAnimatedBack(void)
{
    int		i;
    anim_t*	a;

    if (commercial)
	return;

#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    if (wbs->epsd > 2)
	return;
#endif

    for (i=0;i<NUMANIMS[wbs->epsd];i++)
    {
	a = &anims[wbs->epsd][i];

	if (bcnt == a->nexttic)
	{
	    switch (a->type)
	    {
	      case ANIM_ALWAYS:
		if (++a->ctr >= a->nanims) a->ctr = 0;
		a->nexttic = bcnt + a->period;
		break;

	      case ANIM_RANDOM:
		a->ctr++;
		if (a->ctr == a->nanims)
		{
		    a->ctr = -1;
		    a->nexttic = bcnt+a->data2+(M_Random()%a->data1);
		}
		else a->nexttic = bcnt + a->period;
		break;
		
	      case ANIM_LEVEL:
		// gawd-awful hack for level anims
		if (!(state == StatCount && i == 7)
		    && wbs->next == a->data1)
		{
		    a->ctr++;
		    if (a->ctr == a->nanims) a->ctr--;
		    a->nexttic = bcnt + a->period;
		}
		break;
	    }
	}

    }

}

void WI_drawAnimatedBack(void)
{
    int			i;
    anim_t*		a;

    if (commercial)
	return;

#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    if (wbs->epsd > 2)
	return;
#endif

    for (i=0 ; i<NUMANIMS[wbs->epsd] ; i++)
    {
	a = &anims[wbs->epsd][i];

	if (a->ctr >= 0)
	    V_DrawPatch(a->loc.x, a->loc.y, FB, (patch_t*) Z_LoadBytesFromEMS( a->pRef[a->ctr]));
    }

}

//
// Draws a number.
// If digits > 0, then use that many digits minimum,
//  otherwise only use as many as necessary.
// Returns new x position.
//

int
WI_drawNum
( int		x,
  int		y,
  int		n,
  int		digits )
{

    int		fontwidth = SHORT(((patch_t*)Z_LoadBytesFromEMS(numRef[0])) ->width);
    int		neg;
    int		temp;

    if (digits < 0)
    {
	if (!n)
	{
	    // make variable-length zeros 1 digit long
	    digits = 1;
	}
	else
	{
	    // figure out # of digits in #
	    digits = 0;
	    temp = n;

	    while (temp)
	    {
		temp /= 10;
		digits++;
	    }
	}
    }

    neg = n < 0;
    if (neg)
	n = -n;

    // if non-number, do not draw it
    if (n == 1994)
	return 0;

    // draw the new number
    while (digits--)
    {
	x -= fontwidth;
	V_DrawPatch(x, y, FB, (patch_t*) Z_LoadBytesFromEMS(numRef[ n % 10 ]));
	n /= 10;
    }

    // draw a minus sign if necessary
    if (neg)
	V_DrawPatch(x-=8, y, FB, (patch_t*)Z_LoadBytesFromEMS(wiminusRef));

    return x;

}

void
WI_drawPercent
( int		x,
  int		y,
  int		p )
{
    if (p < 0)
	return;

    V_DrawPatch(x, y, FB, (patch_t*)Z_LoadBytesFromEMS(percentRef));
    WI_drawNum(x, y, p, -1);
}



//
// Display level completion time and par,
//  or "sucks" message if overflow.
//
void
WI_drawTime
( int		x,
  int		y,
  int		t )
{

    int		div;
    int		n;
	patch_t* colon;
	patch_t* sucks;

    if (t<0)
	return;

    if (t <= 61*59) {
		colon = (patch_t*)Z_LoadBytesFromEMS(colonRef);
		div = 1;
		do {
			n = (t / div) % 60;
			x = WI_drawNum(x, y, n, 2) - SHORT(colon->width);
			div *= 60;

			// draw
			if (div==60 || t / div)
			V_DrawPatch(x, y, FB, colon );
	    
		} while (t / div);
    } else {
		// "sucks"
		sucks = (patch_t*)Z_LoadBytesFromEMS(sucksRef);
		V_DrawPatch(x - sucks->width, y, FB, sucks);
    }
}


void WI_End(void)
{
    void WI_unloadData(void);
    WI_unloadData();
}

void WI_initNoState(void)
{
    state = NoState;
    acceleratestage = 0;
    cnt = 10;
}

void WI_updateNoState(void) {

    WI_updateAnimatedBack();

    if (!--cnt)
    {
	WI_End();
	G_WorldDone();
    }

}

static boolean		snl_pointeron = false;


void WI_initShowNextLoc(void)
{
    state = ShowNextLoc;
    acceleratestage = 0;
    cnt = SHOWNEXTLOCDELAY * TICRATE;

    WI_initAnimatedBack();
}

void WI_updateShowNextLoc(void)
{
    WI_updateAnimatedBack();

    if (!--cnt || acceleratestage)
	WI_initNoState();
    else
	snl_pointeron = (cnt & 31) < 20;
}

void WI_drawShowNextLoc(void)
{

    int		i;
    int		last;

    WI_slamBackground();

    // draw animated background
    WI_drawAnimatedBack(); 

    if (!commercial)
    {
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
  	if (wbs->epsd > 2)
	{
	    WI_drawEL();
	    return;
	}
#endif
	
	last = (wbs->last == 8) ? wbs->next - 1 : wbs->last;

	// draw a splat on taken cities.
	for (i = 0; i <= last; i++) {
		WI_drawOnLnode(i, &splatRef);
	}

	// splat the secret level?
	if (wbs->didsecret)
	    WI_drawOnLnode(8, &splatRef);

	// draw flashing ptr
	if (snl_pointeron)
	    WI_drawOnLnode(wbs->next, yahRef); 
    }

    // draws which level you are entering..
    if ( (!commercial)
	 || wbs->next != 30)
	WI_drawEL();  

}

void WI_drawNoState(void)
{
    snl_pointeron = true;
    WI_drawShowNextLoc();
}
 
static int ng_state;


static int	sp_state;

void WI_initStats(void)
{
    state = StatCount;
    acceleratestage = 0;
    sp_state = 1;
    cnt_kills[0] = cnt_items[0] = cnt_secret[0] = -1;
    cnt_time = cnt_par = -1;
    cnt_pause = TICRATE;

    WI_initAnimatedBack();
}

void WI_updateStats(void)
{

    WI_updateAnimatedBack();

    if (acceleratestage && sp_state != 10)
    {
	acceleratestage = 0;
	cnt_kills[0] = (plrs[me].skills * 100) / wbs->maxkills;
	cnt_items[0] = (plrs[me].sitems * 100) / wbs->maxitems;
	cnt_secret[0] = (plrs[me].ssecret * 100) / wbs->maxsecret;
	cnt_time = plrs[me].stime / TICRATE;
	cnt_par = wbs->partime / TICRATE;
	S_StartSound(0, sfx_barexp);
	sp_state = 10;
    }

    if (sp_state == 2)
    {
	cnt_kills[0] += 2;

	if (!(bcnt&3))
	    S_StartSound(0, sfx_pistol);

	if (cnt_kills[0] >= (plrs[me].skills * 100) / wbs->maxkills)
	{
	    cnt_kills[0] = (plrs[me].skills * 100) / wbs->maxkills;
	    S_StartSound(0, sfx_barexp);
	    sp_state++;
	}
    }
    else if (sp_state == 4)
    {
	cnt_items[0] += 2;

	if (!(bcnt&3))
	    S_StartSound(0, sfx_pistol);

	if (cnt_items[0] >= (plrs[me].sitems * 100) / wbs->maxitems)
	{
	    cnt_items[0] = (plrs[me].sitems * 100) / wbs->maxitems;
	    S_StartSound(0, sfx_barexp);
	    sp_state++;
	}
    }
    else if (sp_state == 6)
    {
	cnt_secret[0] += 2;

	if (!(bcnt&3))
	    S_StartSound(0, sfx_pistol);

	if (cnt_secret[0] >= (plrs[me].ssecret * 100) / wbs->maxsecret)
	{
	    cnt_secret[0] = (plrs[me].ssecret * 100) / wbs->maxsecret;
	    S_StartSound(0, sfx_barexp);
	    sp_state++;
	}
    }

    else if (sp_state == 8)
    {
	if (!(bcnt&3))
	    S_StartSound(0, sfx_pistol);

	cnt_time += 3;

	if (cnt_time >= plrs[me].stime / TICRATE)
	    cnt_time = plrs[me].stime / TICRATE;

	cnt_par += 3;

	if (cnt_par >= wbs->partime / TICRATE)
	{
	    cnt_par = wbs->partime / TICRATE;

	    if (cnt_time >= plrs[me].stime / TICRATE)
	    {
		S_StartSound(0, sfx_barexp);
		sp_state++;
	    }
	}
    }
    else if (sp_state == 10)
    {
	if (acceleratestage)
	{
	    S_StartSound(0, sfx_sgcock);

	    if (commercial)
		WI_initNoState();
	    else
		WI_initShowNextLoc();
	}
    }
    else if (sp_state & 1)
    {
	if (!--cnt_pause)
	{
	    sp_state++;
	    cnt_pause = TICRATE;
	}
    }

}

void WI_drawStats(void)
{
    // line height
    int lh;	

	patch_t* num0 = (patch_t*) Z_LoadBytesFromEMS(numRef[0]);

    lh = (3*SHORT(num0->height))/2;

    WI_slamBackground();

    // draw animated background
    WI_drawAnimatedBack();
    
    WI_drawLF();

    V_DrawPatch(SP_STATSX, SP_STATSY, FB, (patch_t*)Z_LoadBytesFromEMS(killsRef));
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY, cnt_kills[0]);

    V_DrawPatch(SP_STATSX, SP_STATSY+lh, FB, (patch_t*)Z_LoadBytesFromEMS(itemsRef));
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY+lh, cnt_items[0]);

    V_DrawPatch(SP_STATSX, SP_STATSY+2*lh, FB, (patch_t*)Z_LoadBytesFromEMS(sp_secretRef));
    WI_drawPercent(SCREENWIDTH - SP_STATSX, SP_STATSY+2*lh, cnt_secret[0]);

    V_DrawPatch(SP_TIMEX, SP_TIMEY, FB, (patch_t*)Z_LoadBytesFromEMS(timeRef));
    WI_drawTime(SCREENWIDTH/2 - SP_TIMEX, SP_TIMEY, cnt_time);

	#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
		if (wbs->epsd < 3)
	#endif
    {
		V_DrawPatch(SCREENWIDTH/2 + SP_TIMEX, SP_TIMEY, FB, (patch_t*)Z_LoadBytesFromEMS(parRef));
		WI_drawTime(SCREENWIDTH - SP_TIMEX, SP_TIMEY, cnt_par);
    }

}

void WI_checkForAccelerate(void)
{
    int   i;
    player_t  *player;

    // check for button presses to skip delays
    for (i=0, player = players ; i<MAXPLAYERS ; i++, player++)
    {
	if (playeringame[i])
	{
	    if (player->cmd.buttons & BT_ATTACK)
	    {
		if (!player->attackdown)
		    acceleratestage = 1;
		player->attackdown = true;
	    }
	    else
		player->attackdown = false;
	    if (player->cmd.buttons & BT_USE)
	    {
		if (!player->usedown)
		    acceleratestage = 1;
		player->usedown = true;
	    }
	    else
		player->usedown = false;
	}
    }
}



// Updates stuff each tick
void WI_Ticker(void)
{
	// counter for general background animation
	bcnt++;

	if (bcnt == 1)
	{
		// intermission music
		if (commercial)
			S_ChangeMusic(mus_dm2int, true);
		else
			S_ChangeMusic(mus_inter, true);
	}

	WI_checkForAccelerate();

	switch (state)
	{
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

}

void WI_loadData(void)
{
    int		i;
    int		j;
    char	name[9];
    anim_t*	a;
	MEMREF* lnames;

    if (commercial)
	strcpy(name, "INTERPIC");
    else 
	sprintf(name, "WIMAP%d", wbs->epsd);
    
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    if (wbs->epsd == 3)
	strcpy(name,"INTERPIC");
#endif


    // background
	// todo fix bigger than 64k
	//    bg = W_CacheLumpName(name, PU_CACHE);    
	//    V_DrawPatch(0, 0, 1, bg);   



    if (commercial)
    {
	NUMCMAPS = 32;								
	lnamesRef = Z_MallocEMSNew (sizeof(patch_t*) * NUMCMAPS,
				       PU_STATIC, 0, ALLOC_TYPE_LNAMES);
	lnames = (MEMREF *)Z_LoadBytesFromEMS(lnamesRef);

	for (i=0 ; i<NUMCMAPS ; i++)
	{								
	    sprintf(name, "CWILV%2.2d", i);
	    lnames[i] = W_CacheLumpNameEMS(name, PU_STATIC);
	}					
    }
    else
    {
	lnamesRef =  Z_MallocEMSNew (sizeof(patch_t*) * NUMMAPS,
				       PU_STATIC, 0, ALLOC_TYPE_LNAMES);
	lnames = (MEMREF *)Z_LoadBytesFromEMS(lnamesRef);

	for (i=0 ; i<NUMMAPS ; i++)
	{
	    sprintf(name, "WILV%d%d", wbs->epsd, i);
	    lnames[i] = W_CacheLumpNameEMS(name, PU_STATIC);
	}

	// you are here
	yahRef[0] = W_CacheLumpNameEMS("WIURH0", PU_STATIC);

	// you are here (alt.)
	yahRef[1] = W_CacheLumpNameEMS("WIURH1", PU_STATIC);

	// splat
	splatRef = W_CacheLumpNameEMS("WISPLAT", PU_STATIC);
	
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
	if (wbs->epsd < 3)
#endif
	{
	    for (j=0;j<NUMANIMS[wbs->epsd];j++)
	    {
		a = &anims[wbs->epsd][j];
		for (i=0;i<a->nanims;i++)
		{
		    // MONDO HACK!
		    if (wbs->epsd != 1 || j != 8) 
		    {
			// animations
			sprintf(name, "WIA%d%.2d%.2d", wbs->epsd, j, i);  
			a->pRef[i] = W_CacheLumpNameEMS(name, PU_STATIC);
		    }
		    else
		    {
			// HACK ALERT!
			a->pRef[i] = anims[1][4].pRef[i]; 
		    }
		}
	    }
	}
    }

    // More hacks on minus sign.
    wiminusRef = W_CacheLumpNameEMS("WIMINUS", PU_STATIC);

    for (i=0;i<10;i++)
    {
	 // numbers 0-9
	sprintf(name, "WINUM%d", i);     
	numRef[i] = W_CacheLumpNameEMS(name, PU_STATIC);
    }

    // percent sign
    percentRef = W_CacheLumpNameEMS("WIPCNT", PU_STATIC);

    // "finished"
    finishedRef = W_CacheLumpNameEMS("WIF", PU_STATIC);

    // "entering"
    enteringRef = W_CacheLumpNameEMS("WIENTER", PU_STATIC);

    // "kills"
    killsRef = W_CacheLumpNameEMS("WIOSTK", PU_STATIC);

    // "scrt"
    secretRef = W_CacheLumpNameEMS("WIOSTS", PU_STATIC);

     // "secret"
    sp_secretRef = W_CacheLumpNameEMS("WISCRT2", PU_STATIC);

    
	itemsRef = W_CacheLumpNameEMS("WIOSTI", PU_STATIC);

    // ":"
    colonRef = W_CacheLumpNameEMS("WICOLON", PU_STATIC);

    // "time"
    timeRef = W_CacheLumpNameEMS("WITIME", PU_STATIC);

    // "sucks"
    sucksRef = W_CacheLumpNameEMS("WISUCKS", PU_STATIC);

    // "par"
    parRef = W_CacheLumpNameEMS("WIPAR", PU_STATIC);

    // "total"
    totalRef = W_CacheLumpNameEMS("WIMSTT", PU_STATIC);

    // your face
    starRef = W_CacheLumpNameEMS("STFST01", PU_STATIC);

    // dead face
    bstarRef = W_CacheLumpNameEMS("STFDEAD0", PU_STATIC);

    for (i=0 ; i<MAXPLAYERS ; i++)
    {
	// "1,2,3,4"
	sprintf(name, "STPB%d", i);      
	pRef[i] = W_CacheLumpNameEMS(name, PU_STATIC);

	// "1,2,3,4"
	sprintf(name, "WIBP%d", i+1);     
	bpRef[i]  = W_CacheLumpNameEMS(name, PU_STATIC);
    }

}

void WI_unloadData(void)
{
    int		i;
    int		j;
	MEMREF*	lnames;
	lnames = (MEMREF*)Z_LoadBytesFromEMS(lnamesRef);

    Z_ChangeTagEMSNew(wiminusRef, PU_CACHE);

    for (i=0 ; i<10 ; i++)
		Z_ChangeTagEMSNew(numRef[i], PU_CACHE);
    
    if (commercial)
    {
		for (i = 0; i < NUMCMAPS; i++) {
			//Z_ChangeTagEMSNew(lnames[i], PU_CACHE);
		}
    }
    else
    {
		Z_ChangeTagEMSNew(yahRef[0], PU_CACHE);
		Z_ChangeTagEMSNew(yahRef[1], PU_CACHE);

		Z_ChangeTagEMSNew(splatRef, PU_CACHE);

	for (i = 0; i < NUMMAPS; i++) {
		//Z_ChangeTagEMSNew(lnames[i], PU_CACHE);
	}
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
	if (wbs->epsd < 3)
#endif
	{
	    for (j=0;j<NUMANIMS[wbs->epsd];j++)
	    {
		if (wbs->epsd != 1 || j != 8)
		    for (i=0;i<anims[wbs->epsd][j].nanims;i++)
				Z_ChangeTagEMSNew(anims[wbs->epsd][j].pRef[i], PU_CACHE);
	    }
	}
    }
    
    Z_FreeEMSNew(lnamesRef);

	Z_ChangeTagEMSNew(percentRef, PU_CACHE);
	Z_ChangeTagEMSNew(colonRef, PU_CACHE);
	Z_ChangeTagEMSNew(finishedRef, PU_CACHE);
	Z_ChangeTagEMSNew(enteringRef, PU_CACHE);
	Z_ChangeTagEMSNew(killsRef, PU_CACHE);
	Z_ChangeTagEMSNew(secretRef, PU_CACHE);
	Z_ChangeTagEMSNew(sp_secretRef, PU_CACHE);
	Z_ChangeTagEMSNew(itemsRef, PU_CACHE);
	Z_ChangeTagEMSNew(timeRef, PU_CACHE);
	Z_ChangeTagEMSNew(sucksRef, PU_CACHE);
	Z_ChangeTagEMSNew(parRef, PU_CACHE);

	Z_ChangeTagEMSNew(totalRef, PU_CACHE);
    //  Z_ChangeTagEMSNew(star, PU_CACHE);
    //  Z_ChangeTagEMSNew(bstar, PU_CACHE);
    
		Z_ChangeTagEMSNew(pRef[i], PU_CACHE);
		Z_ChangeTagEMSNew(bpRef[i], PU_CACHE);
}

void WI_Drawer (void)
{
    switch (state)
    {
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
}
#define RANGECHECKING
#define RNGCHECK(v,l,h) \
{ \
    if((v) < (l) || (v) > (h)) \
    { \
        I_Error("%s=%d in %s:%d", #v, (v), __FILE__, __LINE__); \
    } \
};

void WI_initVariables(wbstartstruct_t* wbstartstruct)
{

    wbs = wbstartstruct;

#ifdef RANGECHECKING
    if (!commercial)
    {
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
        RNGCHECK(wbs->epsd, 0, 2);
#else
        RNGCHECK(wbs->epsd, 0, 3);
#endif
        RNGCHECK(wbs->last, 0, 8);
        RNGCHECK(wbs->next, 0, 8);
    }
    RNGCHECK(wbs->pnum, 0, MAXPLAYERS);
    RNGCHECK(wbs->pnum, 0, MAXPLAYERS);
#endif

    acceleratestage = 0;
    cnt = bcnt = 0;
    firstrefresh = 1;
    me = wbs->pnum;
    plrs = wbs->plyr;

    if (!wbs->maxkills)
	wbs->maxkills = 1;

    if (!wbs->maxitems)
	wbs->maxitems = 1;

    if (!wbs->maxsecret)
	wbs->maxsecret = 1;
}

void WI_Start(wbstartstruct_t* wbstartstruct)
{

	WI_initVariables(wbstartstruct);
	WI_loadData();
	WI_initStats();
}
