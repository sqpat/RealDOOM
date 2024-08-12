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
// DESCRIPTION:  the automap code
//

#include <stdio.h>

#include "z_zone.h"
#include "doomdef.h"
#include "st_stuff.h"
#include "p_local.h"
#include "w_wad.h"

#include "dutils.h"
#include "i_system.h"

// Needs access to LFB.
#include "v_video.h"

// State.
#include "doomstat.h"
#include "r_state.h"

// Data.
#include "dstrings.h"

#include "am_map.h"
#include "m_memory.h"


// For use if I do walls with outsides/insides
#define REDS		(256-5*16)
#define REDRANGE	16
#define BLUES		(256-4*16+8)
#define BLUERANGE	8
#define GREENS		(7*16)
#define GREENRANGE	16
#define GRAYS		(6*16)
#define GRAYSRANGE	16
#define BROWNS		(4*16)
#define BROWNRANGE	16
#define YELLOWS		(256-32+7)
#define YELLOWRANGE	1
#define BLACK		0
#define WHITE		(256-47)

// Automap colors
#define BACKGROUND	BLACK
#define YOURCOLORS	WHITE
#define YOURRANGE	0
#define WALLCOLORS	REDS
#define WALLRANGE	REDRANGE
#define TSWALLCOLORS	GRAYS
#define TSWALLRANGE	GRAYSRANGE
#define FDWALLCOLORS	BROWNS
#define FDWALLRANGE	BROWNRANGE
#define CDWALLCOLORS	YELLOWS
#define CDWALLRANGE	YELLOWRANGE
#define THINGCOLORS	GREENS
#define THINGRANGE	GREENRANGE
#define SECRETWALLCOLORS WALLCOLORS
#define SECRETWALLRANGE WALLRANGE
#define GRIDCOLORS	(GRAYS + GRAYSRANGE/2)
#define GRIDRANGE	0
#define XHAIRCOLORS	GRAYS

// drawing stuff
#define	FB		0

#define AM_PANDOWNKEY	KEY_DOWNARROW
#define AM_PANUPKEY	KEY_UPARROW
#define AM_PANRIGHTKEY	KEY_RIGHTARROW
#define AM_PANLEFTKEY	KEY_LEFTARROW
#define AM_ZOOMINKEY	'='
#define AM_ZOOMOUTKEY	'-'
#define AM_STARTKEY	KEY_TAB
#define AM_ENDKEY	KEY_TAB
#define AM_GOBIGKEY	'0'
#define AM_FOLLOWKEY	'f'
#define AM_GRIDKEY	'g'
#define AM_MARKKEY	'm'
#define AM_CLEARMARKKEY	'c'

#define AM_NUMMARKPOINTS 10

// scale on entry
//66846.72
//64250.98039215686
// 12 integer bits 4 frac bits
#define FRAC_SCALE_UNIT 1 << 12

#define INITSCALEMTOF (.2*FRACUNIT)


// how much the automap moves window per tic in frame-buffer coordinates
// moves 140 pixels in 1 second
#define SCREEN_PAN_INC	4L
// how much zoom-in per tic
// goes to 2x in 1 second

// FRAC_SCALE_UNIT * 1.02
#define M_ZOOMIN        4177
// how much zoom-out per tic
// pulls out to 0.5x in 1 second

// FRAC_SCALE_UNIT / 1.02
#define M_ZOOMOUT       4015

// translates between frame-buffer and map distances

#define FTOM16(x) FixedMul1632(x,scale_ftom.w)

 
// the following is crap
#define LINE_NEVERSEE ML_DONTDRAW

typedef struct
{
	int16_t x, y;
} fpoint_t;

typedef struct
{
    fpoint_t a, b;
} fline_t;

typedef struct
{
    int16_t		x,y;
} mpoint_t;

typedef struct
{
    mpoint_t a, b;
} mline_t;


boolean    	automapactive = false;
static fline_t fl;
static mline_t ml;
static mline_t l;


#ifdef __DEMO_ONLY_BINARY
void __far AM_Drawer(void) {
}

void __far AM_Ticker(void) {
}

boolean __far AM_Responder(event_t __far* ev){
	return false;
}

void __far AM_Stop(void) {
}

#else


 
//#define LINE_PLAYERRADIUS 16<<4

//
// The vector graphics for the automap.
//  A line drawing of the player pointing right,
//   starting from the middle.
//
//#define R ((8*LINE_PLAYERRADIUS)/7)
#define R 292
mline_t player_arrow[] = {
    { { -R+R/8, 0 }, { R, 0 } }, // -----
    { { R, 0 }, { R-R/2, R/4 } },  // ----->
    { { R, 0 }, { R-R/2, -R/4 } },
    { { -R+R/8, 0 }, { -R-R/8, R/4 } }, // >---->
    { { -R+R/8, 0 }, { -R-R/8, -R/4 } },
    { { -R+3*R/8, 0 }, { -R+R/8, R/4 } }, // >>--->
    { { -R+3*R/8, 0 }, { -R+R/8, -R/4 } }
};
#undef R
#define NUMPLYRLINES (sizeof(player_arrow)/sizeof(mline_t))

//#define R ((8*LINE_PLAYERRADIUS)/7)
#define R 292
mline_t cheat_player_arrow[] = {
    { { -R+R/8, 0 }, { R, 0 } }, // -----
    { { R, 0 }, { R-R/2, R/6 } },  // ----->
    { { R, 0 }, { R-R/2, -R/6 } },
    { { -R+R/8, 0 }, { -R-R/8, R/6 } }, // >----->
    { { -R+R/8, 0 }, { -R-R/8, -R/6 } },
    { { -R+3*R/8, 0 }, { -R+R/8, R/6 } }, // >>----->
    { { -R+3*R/8, 0 }, { -R+R/8, -R/6 } },
    { { -R/2, 0 }, { -R/2, -R/6 } }, // >>-d--->
    { { -R/2, -R/6 }, { -R/2+R/6, -R/6 } },
    { { -R/2+R/6, -R/6 }, { -R/2+R/6, R/4 } },
    { { -R/6, 0 }, { -R/6, -R/6 } }, // >>-dd-->
    { { -R/6, -R/6 }, { 0, -R/6 } },
    { { 0, -R/6 }, { 0, R/4 } },
    { { R/6, R/4 }, { R/6, -R/7 } }, // >>-ddt->
    { { R/6, -R/7 }, { R/6+R/32, -R/7-R/32 } },
    { { R/6+R/32, -R/7-R/32 }, { R/6+R/10, -R/7 } }
};
#undef R
#define NUMCHEATPLYRLINES (sizeof(cheat_player_arrow)/sizeof(mline_t))

#define R (1 << 4)
mline_t triangle_guy[] = {
    { { -.867*R, -.5*R }, { .867*R, -.5*R } },
    { { .867*R, -.5*R } , { 0, R } },
    { { 0, R }, { -.867*R, -.5*R } }
};
#undef R

#define R (1 << 4)
mline_t thintriangle_guy[] = {
    { { -.5*R, -.7*R }, { R, 0 } },
    { { R, 0 }, { -.5*R, .7*R } },
    { { -.5*R, .7*R }, { -.5*R, -.7*R } }
};
#undef R
#define NUMTHINTRIANGLEGUYLINES (sizeof(thintriangle_guy)/sizeof(mline_t))




static int8_t 	cheating = 0;
static int8_t 	grid = 0;



// size of window on screen
#define automap_screenwidth SCREENWIDTH
#define	automap_screenheight (SCREENHEIGHT - 32)


static mpoint_t m_paninc; // how far the window pans each tic (map coords)
static int16_t 	mtof_zoommul; // how far the window zooms in each tic (map coords)
static int16_t 	ftom_zoommul; // how far the window zooms in each tic (fb coords)

static int16_t 	screen_botleft_x, screen_botleft_y;   // LL x,y where the window is on the map (map coords)
static int16_t 	screen_topright_x, screen_topright_y; // UR x,y where the window is on the map (map coords)

//
// width/height of window on map (map coords)
//
static int16_t	screen_viewport_width;
static int16_t	screen_viewport_height;

// based on level size
static int16_t 	min_level_x;
static int16_t	min_level_y;
static int16_t 	max_level_x;
static int16_t	max_level_y;


// based on player size
static fixed_t_union 	min_scale_mtof; // used to tell when to stop zooming out
static fixed_t_union 	max_scale_mtof; // used to tell when to stop zooming in

// old stuff for recovery later
static int16_t old_screen_viewport_width, old_screen_viewport_height;
static int16_t old_screen_botleft_x, old_screen_botleft_y;

// old location used by the Follower routine
static mpoint_t screen_oldloc;

// used by MTOF to scale from map-to-frame-buffer coords

static fixed_t_union scale_mtof;

// used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof)
static fixed_t_union scale_ftom;

static mpoint_t markpoints[AM_NUMMARKPOINTS]; // where the points are
static int8_t markpointnum = 0; // next point to be assigned

static int8_t followplayer = 1; // specifies whether to follow the player around

static uint8_t cheat_amap_seq[] = {'i', 'd', 'd', 't', 0xff};
static cheatseq_t cheat_amap = { cheat_amap_seq, 0 };

static boolean stopped = true;

extern boolean viewactive;


fixed_16_t __near MTOF16(fixed_16_t x) {
	return FixedMul1632(x, scale_mtof.w);
}



fixed_16_t __near CXMTOF16(fixed_16_t x) {
	return MTOF16(x - screen_botleft_x);
}


fixed_16_t __near CYMTOF16(fixed_16_t y) {
	return automap_screenheight - MTOF16(y - screen_botleft_y);
}

 

void
V_MarkRect
( int16_t	x,
  int16_t	y,
  int16_t	width,
  int16_t	height );

 

//
//
//
void __near AM_activateNewScale(void)
{
 

    screen_botleft_x += screen_viewport_width/2;
    screen_botleft_y += screen_viewport_height/2;
    screen_viewport_width = FTOM16(automap_screenwidth);
    screen_viewport_height = FTOM16(automap_screenheight);
    screen_botleft_x -= screen_viewport_width /2;
    screen_botleft_y -= screen_viewport_height /2;
    screen_topright_x = screen_botleft_x + screen_viewport_width;
    screen_topright_y = screen_botleft_y + screen_viewport_height;

}


void __near AM_restoreScaleAndLoc(void)
{

    screen_viewport_width = old_screen_viewport_width;
    screen_viewport_height = old_screen_viewport_height;
    if (!followplayer) {
		screen_botleft_x = old_screen_botleft_x;
		screen_botleft_y = old_screen_botleft_y;
    } else {
		screen_botleft_x = (playerMobj_pos->x.h.intbits) - screen_viewport_width /2;
		screen_botleft_y = (playerMobj_pos->y.h.intbits) - screen_viewport_height /2;
    }
    screen_topright_x = screen_botleft_x + screen_viewport_width;
    screen_topright_y = screen_botleft_y + screen_viewport_height;

    // Change the scaling multipliers

    scale_mtof.w = FixedDivWholeA(automap_screenwidth, ((int32_t)screen_viewport_width << 16));
    scale_ftom.w = FixedDivWholeA(1, scale_mtof.w);
}

//
// adds a marker at the current location
//
void __near AM_addMark(void)
{
    markpoints[markpointnum].x = screen_botleft_x + screen_viewport_width /2;
    markpoints[markpointnum].y = screen_botleft_y + screen_viewport_height /2;
	 
	markpointnum = (markpointnum + 1) % AM_NUMMARKPOINTS;

}

//
// Determines bounding box of all vertices,
// sets global variables controlling zoom range.
//
void __near AM_findMinMaxBoundaries(void)
{
	int16_t i;
    fixed_t a;
    fixed_t b;
	int16_t temp;
	int16_t max_w; // max_level_x-min_level_x,
	int16_t max_h; // max_level_y-min_level_y
	min_level_x = min_level_y =  MAXSHORT;
    max_level_x = max_level_y = -MAXSHORT;

    for (i=0;i<numvertexes;i++) {

		temp = vertexes[i].x;

		if ((temp) < min_level_x)
			min_level_x = temp;
		else if ((temp) > max_level_x)
			max_level_x = temp;
    
		temp = vertexes[i].y;

		if (temp < min_level_y)
			min_level_y = temp;
		else if (temp > max_level_y)
			max_level_y = temp;

    }
  
    max_w = max_level_x - min_level_x;
    max_h = max_level_y - min_level_y;
	
	//todo this in theory can be better. but whoe cares, runs once
	a = FixedDiv(automap_screenwidth, max_w);
	b = FixedDiv(automap_screenheight, max_h);
  
    min_scale_mtof.w = a < b ? a : b;
	max_scale_mtof.w = FixedDiv(automap_screenheight, 2*16);

}


//
//
//
void __near AM_changeWindowLoc(void)
{
    if (m_paninc.x || m_paninc.y)
    {
	followplayer = 0;
	screen_oldloc.x = MAXSHORT;
    }

    screen_botleft_x += m_paninc.x;
    screen_botleft_y += m_paninc.y;

    if (screen_botleft_x + screen_viewport_width /2 > max_level_x)
		screen_botleft_x = max_level_x - screen_viewport_width /2;
    else if (screen_botleft_x + screen_viewport_width /2 < min_level_x)
		screen_botleft_x = min_level_x - screen_viewport_width /2;
  
    if (screen_botleft_y + screen_viewport_height /2 > max_level_y)
		screen_botleft_y = max_level_y - screen_viewport_height /2;
    else if (screen_botleft_y + screen_viewport_height /2 < min_level_y)
		screen_botleft_y = min_level_y - screen_viewport_height /2;

    screen_topright_x = screen_botleft_x + screen_viewport_width;
    screen_topright_y = screen_botleft_y + screen_viewport_height;
}


//
//
//
void __near AM_initVariables(void)
{
    static event_t st_notify = { ev_keyup, AM_MSGENTERED };

    automapactive = true;

    screen_oldloc.x = MAXSHORT;

    m_paninc.x = m_paninc.y = 0;
    ftom_zoommul = FRAC_SCALE_UNIT;
    mtof_zoommul = FRAC_SCALE_UNIT;

    screen_viewport_width = FTOM16(automap_screenwidth);
    screen_viewport_height = FTOM16(automap_screenheight);

  
	screen_botleft_x = (playerMobj_pos->x.h.intbits) - screen_viewport_width /2;
    screen_botleft_y = (playerMobj_pos->y.h.intbits) - screen_viewport_height /2;
    AM_changeWindowLoc();

    // for saving & restoring
    old_screen_botleft_x = screen_botleft_x;
    old_screen_botleft_y = screen_botleft_y;
    old_screen_viewport_width = screen_viewport_width;
    old_screen_viewport_height = screen_viewport_height;

    // inform the status bar of the change
    ST_Responder(&st_notify);

}

//
// 
//
// ehh.. gross but it's not worth setting up its own EMS page for.
//byte ammnumpatchbytes[524];
//uint16_t ammnumpatchoffsets[10];



void __near AM_clearMarks(void)
{
	int8_t i;

    for (i=0;i<AM_NUMMARKPOINTS;i++)
		markpoints[i].x = -1; // means empty
    markpointnum = 0;
}

//
// should be called at the start of every level
// right now, i figure it out myself
//
void __near AM_LevelInit(void)
{
	scale_mtof.w = INITSCALEMTOF;
    AM_clearMarks();

    AM_findMinMaxBoundaries();
    //todo should this be a fixedMul by 1/0.7 instead?
	scale_mtof.w = FixedDiv(min_scale_mtof.w, (int32_t) (0.7*FRACUNIT));
	if (scale_mtof.w > max_scale_mtof.w) {
		scale_mtof.w = min_scale_mtof.w;
	}
    scale_ftom.w = FixedDivWholeA(1, scale_mtof.w);
}




//
//
//
void __far AM_Stop (void)
{
    static event_t st_notify = { 0, ev_keyup, AM_MSGEXITED };

    automapactive = false;
    ST_Responder(&st_notify);
    stopped = true;
}

//
//
//
void __far AM_Start (void)
{
    static int8_t lastlevel = -1, lastepisode = -1;

    if (!stopped) 
		AM_Stop();
    stopped = false;
	
	if (lastlevel != gamemap || lastepisode != gameepisode) {
		AM_LevelInit();
		lastlevel = gamemap;
		lastepisode = gameepisode;
    }

	AM_initVariables();
 }

//
// set the window scale to the maximum size
//
void __near AM_minOutWindowScale(void)
{
    scale_mtof.w = min_scale_mtof.w;
    scale_ftom.w = FixedDivWholeA(1, scale_mtof.w);
    AM_activateNewScale();
}

//
// set the window scale to the minimum size
//
void __near AM_maxOutWindowScale(void)
{
    scale_mtof.w = max_scale_mtof.w;
    scale_ftom.w = FixedDivWholeA(1, scale_mtof.w);
    AM_activateNewScale();
}

 
//
// Handle events (user inputs) in automap mode
//
boolean
__far AM_Responder
( event_t __far*	ev )
{

	boolean rc;
    static int8_t bigstate=0;
	static int8_t buffer[20];
	int8_t text[100];

    rc = false;

    if (!automapactive) {
		if (ev->type == ev_keydown && ev->data1 == AM_STARTKEY) {
			AM_Start ();
			viewactive = false;
			rc = true;
		}
	} else if (ev->type == ev_keydown) {

		rc = true;
		switch(ev->data1) {
		  case AM_PANRIGHTKEY: // pan right
			if (!followplayer) m_paninc.x = FTOM16(SCREEN_PAN_INC);
			else rc = false;
			break;
		  case AM_PANLEFTKEY: // pan left
			if (!followplayer) m_paninc.x = -FTOM16(SCREEN_PAN_INC);
			else rc = false;
			break;
		  case AM_PANUPKEY: // pan up
			if (!followplayer) m_paninc.y = FTOM16(SCREEN_PAN_INC);
			else rc = false;
			break;
		  case AM_PANDOWNKEY: // pan down
			if (!followplayer) m_paninc.y = -FTOM16(SCREEN_PAN_INC);
			else rc = false;
			break;
		  case AM_ZOOMOUTKEY: // zoom out
			mtof_zoommul = M_ZOOMOUT;
			ftom_zoommul = M_ZOOMIN;
			break;
		  case AM_ZOOMINKEY: // zoom in
			mtof_zoommul = M_ZOOMIN;
			ftom_zoommul = M_ZOOMOUT;
			break;
		  case AM_ENDKEY:
			bigstate = 0;
			viewactive = true;
			AM_Stop ();
			break;
		  case AM_GOBIGKEY:
			bigstate = !bigstate;
			if (bigstate) {
				//AM_saveScaleAndLoc();
				old_screen_botleft_x = screen_botleft_x;
				old_screen_botleft_y = screen_botleft_y;
				old_screen_viewport_width = screen_viewport_width;
				old_screen_viewport_height = screen_viewport_height;

				AM_minOutWindowScale();
			} else {
				AM_restoreScaleAndLoc();
			}
			break;
		  case AM_FOLLOWKEY:
			followplayer = !followplayer;
			screen_oldloc.x = MAXSHORT;
			player.message = followplayer ? AMSTR_FOLLOWON : AMSTR_FOLLOWOFF;
			break;
		  case AM_GRIDKEY:
			grid = !grid;
			player.message = grid ? AMSTR_GRIDON : AMSTR_GRIDOFF;
			break;
		  case AM_MARKKEY:
			getStringByIndex(AMSTR_MARKEDSPOT, text);
			sprintf(buffer, "%s %d", text, markpointnum);
			player.messagestring = buffer;
			AM_addMark();
			break;
		  case AM_CLEARMARKKEY:
			AM_clearMarks();
			player.message = AMSTR_MARKSCLEARED;
			break;
		  default:
			rc = false;
		}
		if ( cht_CheckCheat(&cheat_amap, ev->data1)) {
			rc = false;
			cheating = (cheating+1) % 3;
		}
	} else if (ev->type == ev_keyup) {
		rc = false;
		switch (ev->data1) {
		  case AM_PANRIGHTKEY:
			if (!followplayer) m_paninc.x = 0;
			break;
		  case AM_PANLEFTKEY:
			if (!followplayer) m_paninc.x = 0;
			break;
		  case AM_PANUPKEY:
			if (!followplayer) m_paninc.y = 0;
			break;
		  case AM_PANDOWNKEY:
			if (!followplayer) m_paninc.y = 0;
			break;
		  case AM_ZOOMOUTKEY:
		  case AM_ZOOMINKEY:
			mtof_zoommul = FRAC_SCALE_UNIT;
			ftom_zoommul = FRAC_SCALE_UNIT;
			break;
		}
	}

    return rc;

}


//
// Zooming
//
void __near AM_changeWindowScale(void)
{

    // Change the scaling multipliers
    scale_mtof.w = FixedMul1632(mtof_zoommul, scale_mtof.w)<<4;
    scale_ftom.w = FixedDivWholeA(1, scale_mtof.w);

    if (scale_mtof.w < min_scale_mtof.w)
		AM_minOutWindowScale();
    else if (scale_mtof.w > max_scale_mtof.w)
		AM_maxOutWindowScale();
    else
		AM_activateNewScale();
}


//
//
//
void __near AM_doFollowPlayer(void) {


    if (screen_oldloc.x != playerMobj_pos->x.h.intbits || screen_oldloc.y != playerMobj_pos->y.h.intbits) {
		screen_botleft_x = (playerMobj_pos->x.h.intbits) - screen_viewport_width /2;
		screen_botleft_y = (playerMobj_pos->y.h.intbits) - screen_viewport_height /2;
		screen_topright_x = screen_botleft_x + screen_viewport_width;
		screen_topright_y= screen_botleft_y + screen_viewport_height;
		screen_oldloc.x = playerMobj_pos->x.h.intbits;
		screen_oldloc.y = playerMobj_pos->y.h.intbits;

    }

}

 

//
// Updates on Game Tick
//
void __far AM_Ticker (void)
{


	if (followplayer) {
		AM_doFollowPlayer();
	}

	// Change the zoom if necessary
	if (ftom_zoommul != FRAC_SCALE_UNIT) {
		AM_changeWindowScale();
	}
	// Change x,y location
	if (m_paninc.x || m_paninc.y) {
		AM_changeWindowLoc();
	}
    // Update light level
    // AM_updateLightLev();

}




//
// Automap clipping of lines.
//
// Based on Cohen-Sutherland clipping algorithm but with a slightly
// faster reject and precalculated slopes.  If the speed is needed,
// use a hash algorithm to handle  the common cases.
//

#define  LEFT	1
#define  RIGHT	2
#define  BOTTOM	4
#define  TOP	8


int16_t __near DOOUTCODE(int16_t oc, int16_t mx, int16_t my) {
	oc = 0; 
	if ((my) < 0) {
		oc |= TOP;
	} else if ((my) >= automap_screenheight) {
		oc |= BOTTOM;
	}
	if ((mx) < 0) {
		oc |= LEFT;
	} else if ((mx) >= automap_screenwidth) {
		oc |= RIGHT;
	}
	return oc;
}


boolean
__near AM_clipMline
( mline_t __near*	ml,
  fline_t __near*	fl )
{
    
    int16_t outcode1 = 0;
    int16_t outcode2 = 0;
    int16_t outside;
    
    fpoint_t	tmp;
    int16_t		dx;
	int16_t		dy;

    

    // do trivial rejects and outcodes
    if (ml->a.y > screen_topright_y)
		outcode1 = TOP;
    else if (ml->a.y < screen_botleft_y)
		outcode1 = BOTTOM;

    if (ml->b.y > screen_topright_y)
		outcode2 = TOP;
    else if (ml->b.y < screen_botleft_y)
		outcode2 = BOTTOM;
    
    if (outcode1 & outcode2)
		return false; // trivially outside

    if (ml->a.x < screen_botleft_x)
		outcode1 |= LEFT;
    else if (ml->a.x > screen_topright_x)
		outcode1 |= RIGHT;
    
    if (ml->b.x < screen_botleft_x)
		outcode2 |= LEFT;
    else if (ml->b.x > screen_topright_x)
		outcode2 |= RIGHT;
    
    if (outcode1 & outcode2)
		return false; // trivially outside

    // transform to frame-buffer coordinates.
    fl->a.x = CXMTOF16(ml->a.x);
    fl->a.y = CYMTOF16(ml->a.y);
    fl->b.x = CXMTOF16(ml->b.x);
    fl->b.y = CYMTOF16(ml->b.y);

	outcode1 = DOOUTCODE(outcode1, fl->a.x, fl->a.y);
	outcode2 = DOOUTCODE(outcode2, fl->b.x, fl->b.y);

    if (outcode1 & outcode2)
		return false;

    while (outcode1 | outcode2) {
		// may be partially inside box
		// find an outside point
		if (outcode1)
			outside = outcode1;
		else
			outside = outcode2;
	
		// clip to each side
		if (outside & TOP)
		{
			dy = fl->a.y - fl->b.y;
			dx = fl->b.x - fl->a.x;
			tmp.x = fl->a.x + (dx*(fl->a.y))/dy;
			tmp.y = 0;
		}
		else if (outside & BOTTOM)
		{
			dy = fl->a.y - fl->b.y;
			dx = fl->b.x - fl->a.x;
			tmp.x = fl->a.x + (dx*(fl->a.y-automap_screenheight))/dy;
			tmp.y = automap_screenheight-1;
		}
		else if (outside & RIGHT)
		{
			dy = fl->b.y - fl->a.y;
			dx = fl->b.x - fl->a.x;
			tmp.y = fl->a.y + (dy*(automap_screenwidth-1 - fl->a.x))/dx;
			tmp.x = automap_screenwidth-1;
		}
		else if (outside & LEFT)
		{
			dy = fl->b.y - fl->a.y;
			dx = fl->b.x - fl->a.x;
			tmp.y = fl->a.y + (dy*(-fl->a.x))/dx;
			tmp.x = 0;
		}

		if (outside == outcode1)
		{
			fl->a = tmp;
			outcode1 = DOOUTCODE(outcode1, fl->a.x, fl->a.y);
		}
		else
		{
			fl->b = tmp;
			outcode2 = DOOUTCODE(outcode2, fl->b.x, fl->b.y);
		}
	
		if (outcode1 & outcode2)
			return false; // trivially outside
		}

	return true;
}


//
// Classic Bresenham w/ whatever optimizations needed for speed
//
void
__near AM_drawFline
( fline_t __near*	fl,
  uint8_t		color )
{
    register int16_t x;
	register int16_t y;
	register int16_t dx;
	register int16_t dy;
	register int16_t sx;
	register int16_t sy;
	register int16_t ax;
	register int16_t ay;
    register int16_t d;
    
	 

#define PUTDOT(xx,yy,cc) screen0[(yy)*automap_screenwidth+(xx)]=(cc)

    dx = fl->b.x - fl->a.x;
    ax = 2 * (dx<0 ? -dx : dx);
    sx = dx<0 ? -1 : 1;

    dy = fl->b.y - fl->a.y;
    ay = 2 * (dy<0 ? -dy : dy);
    sy = dy<0 ? -1 : 1;

    x = fl->a.x;
    y = fl->a.y;

    if (ax > ay) {
		d = ay - ax/2;
		while (1) {
			PUTDOT(x,y,color);
			if (x == fl->b.x) return;
			if (d>=0)
			{
			y += sy;
			d -= ax;
			}
			x += sx;
			d += ay;
		}
	} else {
		d = ax - ay/2;
		while (1) {
			PUTDOT(x, y, color);
			if (y == fl->b.y) return;
			if (d >= 0)
			{
			x += sx;
			d -= ay;
			}
			y += sy;
			d += ax;
		}
    }



}


//
// Clip lines, draw visible part sof lines.
//
void __near AM_drawMline ( mline_t __near*	ml,
  uint8_t		color )
{

    if (AM_clipMline(ml, &fl))
		AM_drawFline(&fl, color); // draws it on frame buffer using fb coords
}



//
// Draws flat (floor/ceiling tile) aligned grid lines.
//
void __near AM_drawGrid()
{
    int16_t x, y;
	int16_t start, end;

    // Figure out start of vertical gridlines
	start = screen_botleft_x;
	
	if ((start - bmaporgx) % (0x80)) {
		start += (0x80) - ((start - bmaporgx) % (0x80));
	}
    end = (screen_botleft_x) + (screen_viewport_width);

    // draw vertical gridlines
	ml.a.y = screen_botleft_y;
	ml.b.y = screen_botleft_y +screen_viewport_height;
    for (x=start; x<end; x+=(0x80)) {
		ml.a.x = x;
		ml.b.x = x;
		AM_drawMline(&ml, GRIDCOLORS);
    }

    // Figure out start of horizontal gridlines
	start = screen_botleft_y;
	if ((start - bmaporgy) % (0x80)) {
		start += (0x80) - ((start - bmaporgy) % (0x80));
	}
    end = (screen_botleft_y )+ (screen_viewport_height);

    // draw horizontal gridlines
    ml.a.x = screen_botleft_x;
    ml.b.x = screen_botleft_x + screen_viewport_width;
    for (y=start; y<end; y+=(0x80)) {
		ml.a.y = y;
		ml.b.y = y;
		AM_drawMline(&ml, GRIDCOLORS);
    }

}

//
// Determines visible lines, draws them.
// This is LineDef based, not LineSeg based.
//
void __near AM_drawWalls()
{
	uint16_t i;
	int16_t linev1Offset;
	int16_t linev2Offset;
	int16_t lineflags;
	int16_t linefrontsecnum;
	int16_t linebacksecnum;
	int16_t linespecial;
	boolean floorheightnonequal;
	boolean ceilingheightnonequal;
	uint8_t mappedflag;

    for (i=0;i<numlines;i++) {
		linev1Offset = lines_physics[i].v1Offset;
		linev2Offset = lines_physics[i].v2Offset & VERTEX_OFFSET_MASK;
		mappedflag = seenlines[i / 8] & (0x01 << (i%8));  // todo this seems wasteful? just add up during the loop to avoid all these shifts?
		lineflags = lineflagslist[i];
		linebacksecnum = lines_physics[i].backsecnum;
		linefrontsecnum = lines_physics[i].frontsecnum;
		linespecial = lines_physics[i].special;

		l.a.x = vertexes[linev1Offset].x;
		l.a.y = vertexes[linev1Offset].y;
		l.b.x = vertexes[linev2Offset].x;
		l.b.y = vertexes[linev2Offset].y;

		if (cheating || mappedflag) {
			if ((lineflags & LINE_NEVERSEE) && !cheating) {
				continue;
			} if (linebacksecnum == SECNUM_NULL) {
				AM_drawMline(&l, WALLCOLORS);
			} else {
				floorheightnonequal = sectors[linebacksecnum].floorheight != sectors[linefrontsecnum].floorheight;
				ceilingheightnonequal = sectors[linebacksecnum].ceilingheight != sectors[linefrontsecnum].ceilingheight;
				if (linespecial == 39) { // teleporters
					AM_drawMline(&l, WALLCOLORS+WALLRANGE/2);
				} else if (lineflags & ML_SECRET){ // secret door
					if (cheating) { 
						AM_drawMline(&l, SECRETWALLCOLORS); 
					} else {
						AM_drawMline(&l, WALLCOLORS);
					}
				} else if (floorheightnonequal) {
					AM_drawMline(&l, FDWALLCOLORS); // floor level change
				}
				else if (ceilingheightnonequal) {
					AM_drawMline(&l, CDWALLCOLORS); // ceiling level change
				} else if (cheating) {
					AM_drawMline(&l, TSWALLCOLORS);
				}
			}
		} else if (player.powers[pw_allmap]) {
			if (!(lineflags & LINE_NEVERSEE)) {
				AM_drawMline(&l, GRAYS + 3);
			}
		}
    }
}


//
// Rotation in 2D.
// Used to rotate player arrow line character.
//
void
__near AM_rotate
( int16_t __near*	x,
	int16_t __near*	y,
  fineangle_t	a )
{
	fixed_t_union tmpx;
    tmpx.w = ((int32_t)(*x * finecosine[a]))
	- ((int32_t)(*y * finesine[a]));
    
	*y = ((int32_t)(*x*finesine[a])) + ((int32_t)(*y*finecosine[a])) >> 16;
	*x = tmpx.h.intbits;

}
static mline_t	lc;

void
__near AM_drawLineCharacter
( mline_t __near*	lineguy,
  int16_t		lineguylines,
  int16_t	scale,
  fineangle_t	angle,
  uint8_t		color,
  int16_t	x,
	int16_t	y )
{
    uint16_t		i;

    for (i=0;i<lineguylines;i++) {
		lc.a.x = lineguy[i].a.x;
		lc.a.y = lineguy[i].a.y;

		if (scale) {
			// scale is only ever 16 or 0
			lc.a.x <<= 4;
			lc.a.y <<= 4;
		}

		if (angle)
			AM_rotate(&lc.a.x, &lc.a.y, angle);

		lc.a.x >>= 4;
		lc.a.y >>= 4;

		lc.a.x += x;
		lc.a.y += y;

		lc.b.x = lineguy[i].b.x;
		lc.b.y = lineguy[i].b.y;

		if (scale) {
			// scale is only ever 16 or 0
			lc.b.x <<= 4;
			lc.b.y <<= 4;
		}

		if (angle)
			AM_rotate(&lc.b.x, &lc.b.y, angle);
	
		lc.b.x >>= 4;
		lc.b.y >>= 4;

		lc.b.x += x;
		lc.b.y += y;

		AM_drawMline(&lc, color);
    }
}

void __near AM_drawPlayers(void)
{
	
	if (cheating)
		AM_drawLineCharacter(cheat_player_arrow, NUMCHEATPLYRLINES, 0, playerMobj_pos->angle.hu.intbits>>SHORTTOFINESHIFT, WHITE, playerMobj_pos->x.h.intbits, playerMobj_pos->y.h.intbits);
	else
		AM_drawLineCharacter(player_arrow, NUMPLYRLINES, 0, playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT, WHITE, playerMobj_pos->x.h.intbits, playerMobj_pos->y.h.intbits);



}

void __near AM_drawThings()
{
    uint16_t		i;
    mobj_pos_t __far*	t;
	THINKERREF tRef;
	for (i=0;i<numsectors;i++) {
		tRef = sectors[i].thinglistRef;
		while (tRef) {
			t = (mobj_pos_t __far*)(&mobjposlist[tRef]);
			
			AM_drawLineCharacter (thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
			 0x10L, t->angle.hu.intbits >> SHORTTOFINESHIFT, THINGCOLORS, t->x.h.intbits, t->y.h.intbits);
			tRef = t->snextRef;
		}
    }
}

void __near AM_drawMarks(void)
{
	int8_t i;
	int16_t fx, fy;

    for (i=0;i<AM_NUMMARKPOINTS;i++) {
		if (markpoints[i].x != -1) {
			//      w = 5 = (marknums[i]->width);
			//      h = 6 = (marknums[i]->height);
	    
			fx = CXMTOF16(markpoints[i].x);
			fy = CYMTOF16(markpoints[i].y);
 
			if (fx >= 0 && fx <= automap_screenwidth - 5 && 
				fy >= 0 && fy <= automap_screenheight - 6) {
				V_DrawPatch(fx, fy, FB, ((patch_t __far*)&ammnumpatchbytes[ammnumpatchoffsets[i]]));

			
			

			}
		}
    }

}

void __near AM_drawCrosshair()
{
    screen0[(automap_screenwidth*(automap_screenheight+1))/2] = XHAIRCOLORS; // single point for now

}
//extern void G_ExitLevel();
void __far AM_Drawer (void)
{

	// sq - DEBUG: enable for easy/quick level change while debugging, i.e. to put pressure on memory
	//G_ExitLevel();



	// Clear automap frame buffer.
	FAR_memset(screen0, BACKGROUND, automap_screenwidth*automap_screenheight);

	if (grid)
		AM_drawGrid();
	AM_drawWalls();
	AM_drawPlayers();
	if (cheating==2)
		AM_drawThings();
	AM_drawCrosshair();

    AM_drawMarks();

    V_MarkRect(0, 0, automap_screenwidth, automap_screenheight);

}
#endif
