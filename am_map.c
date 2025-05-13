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
#include "m_near.h"
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

#define FTOM16(x) FixedMul1632(x,am_scale_ftom.w)

#define NUMCHEATPLYRLINES (sizeof(cheat_player_arrow)/sizeof(mline_t))
#define NUMPLYRLINES (sizeof(player_arrow)/sizeof(mline_t))

 
// the following is crap
#define LINE_NEVERSEE ML_DONTDRAW

// #define __DEMO_ONLY_BINARY 1

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


 
#define NUMTHINTRIANGLEGUYLINES (sizeof(thintriangle_guy)/sizeof(mline_t))

#define automap_screenwidth SCREENWIDTH
// screenheight is 200u, not 200...
#define	automap_screenheight ((int16_t)(SCREENHEIGHT - 32))




fixed_16_t __near MTOF16(fixed_16_t x) {
	return FixedMul1632(x, am_scale_mtof.w);
}



fixed_16_t __near CXMTOF16(fixed_16_t x) {
	return MTOF16(x - screen_botleft_x);
}


fixed_16_t __near CYMTOF16(fixed_16_t y) {
	return automap_screenheight - MTOF16(y - screen_botleft_y);
}

 

void __far V_MarkRect ( int16_t x, int16_t y, int16_t width, int16_t height);

 

//
//
//
void __near AM_activateNewScale(void) {
 

    screen_botleft_x += screen_viewport_width>>1;
    screen_botleft_y += screen_viewport_height>>1;
    screen_viewport_width = FTOM16(automap_screenwidth);
    screen_viewport_height = FTOM16(automap_screenheight);
    screen_botleft_x -= screen_viewport_width >>1;
    screen_botleft_y -= screen_viewport_height >>1;
    screen_topright_x = screen_botleft_x + screen_viewport_width;
    screen_topright_y = screen_botleft_y + screen_viewport_height;

}


void __near AM_restoreScaleAndLoc(void) {
	fixed_t_union temp;
    screen_viewport_width = old_screen_viewport_width;
    screen_viewport_height = old_screen_viewport_height;
    if (!followplayer) {
		screen_botleft_x = old_screen_botleft_x;
		screen_botleft_y = old_screen_botleft_y;
    } else {
		screen_botleft_x = (playerMobj_pos->x.h.intbits) - (screen_viewport_width >>1);
		screen_botleft_y = (playerMobj_pos->y.h.intbits) - (screen_viewport_height >>1);
    }
    screen_topright_x = screen_botleft_x + screen_viewport_width;
    screen_topright_y = screen_botleft_y + screen_viewport_height;

    // Change the scaling multipliers
	temp.h.intbits = screen_viewport_width;
	temp.h.fracbits = 0;
    // todo FixedDivWholeAB
	am_scale_mtof.w = FixedDivWholeA(automap_screenwidth, temp.w);
    am_scale_ftom.w = FixedDivWholeA(1, am_scale_mtof.w);
}

//
// adds a marker at the current location
//
void __near AM_addMark(void) {
    markpoints[markpointnum].x = screen_botleft_x + (screen_viewport_width >>1);
    markpoints[markpointnum].y = screen_botleft_y + (screen_viewport_height >>1);
	 
	markpointnum = (markpointnum + 1) % AM_NUMMARKPOINTS;

}

//
// Determines bounding box of all vertices,
// sets global variables controlling zoom range.
//
void __near AM_findMinMaxBoundaries(void) {
	int16_t i;
    fixed_t a;
    fixed_t b;
	int16_t temp;
	int16_t max_w; // am_max_level_x-am_min_level_x,
	int16_t max_h; // am_max_level_y-am_min_level_y
	am_min_level_x = am_min_level_y =  MAXSHORT;
    am_max_level_x = am_max_level_y = -MAXSHORT;

    for (i=0;i<numvertexes;i++) {

		temp = vertexes[i].x;

		if ((temp) < am_min_level_x){
			am_min_level_x = temp;
		} else if ((temp) > am_max_level_x){
			am_max_level_x = temp;
		}

		temp = vertexes[i].y;

		if (temp < am_min_level_y){
			am_min_level_y = temp;
		} else if (temp > am_max_level_y){
			am_max_level_y = temp;
		}
    }
  
    max_w = am_max_level_x - am_min_level_x;
    max_h = am_max_level_y - am_min_level_y;
	
	//todo this in theory can be better. but whoe cares, runs once
	a = FixedDiv(automap_screenwidth, max_w);
	b = FixedDiv(automap_screenheight, max_h);
  
    am_min_scale_mtof = a < b ? a : b;

	am_max_scale_mtof.w = 0x54000;// FixedDiv(automap_screenheight, 2*16);


}


//
//
//
void __near AM_changeWindowLoc(void) {
    if (m_paninc.x || m_paninc.y) {
		followplayer = 0;
		screen_oldloc.x = MAXSHORT;
    }

    screen_botleft_x += m_paninc.x;
    screen_botleft_y += m_paninc.y;

    if (screen_botleft_x + (screen_viewport_width >>1) > am_max_level_x){
		screen_botleft_x = am_max_level_x - (screen_viewport_width >>1);
	} else if (screen_botleft_x + (screen_viewport_width >>1) < am_min_level_x){
		screen_botleft_x = am_min_level_x - (screen_viewport_width >>1);
	}
    if (screen_botleft_y + (screen_viewport_height >>1) > am_max_level_y){
		screen_botleft_y = am_max_level_y - (screen_viewport_height >>1);
	} else if (screen_botleft_y + (screen_viewport_height >>1) < am_min_level_y){
		screen_botleft_y = am_min_level_y - (screen_viewport_height >>1);
	}

    screen_topright_x = screen_botleft_x + screen_viewport_width;
    screen_topright_y = screen_botleft_y + screen_viewport_height;
}


//
//
//
void __near AM_initVariables(void) {

    automapactive = true;

    screen_oldloc.x = MAXSHORT;

    m_paninc.x = m_paninc.y = 0;
    ftom_zoommul = FRAC_SCALE_UNIT;
    mtof_zoommul = FRAC_SCALE_UNIT;

    screen_viewport_width = FTOM16(automap_screenwidth);
    screen_viewport_height = FTOM16(automap_screenheight);

  
	screen_botleft_x = (playerMobj_pos->x.h.intbits) - (screen_viewport_width >>1);
    screen_botleft_y = (playerMobj_pos->y.h.intbits) - (screen_viewport_height >>1);
    AM_changeWindowLoc();

    // for saving & restoring
    old_screen_botleft_x = screen_botleft_x;
    old_screen_botleft_y = screen_botleft_y;
    old_screen_viewport_width = screen_viewport_width;
    old_screen_viewport_height = screen_viewport_height;

    // inform the status bar of the change
	st_gamestate = AutomapState;
	st_firsttime = true;



}

//
// 
//
// ehh.. gross but it's not worth setting up its own EMS page for.
//byte ammnumpatchbytes[524];
//uint16_t ammnumpatchoffsets[10];



void __near AM_clearMarks(void) {

	// - 1 memset multiple times is still -1 as a word or dword...
	memset(markpoints, -1, AM_NUMMARKPOINTS*sizeof(mpoint_t));
    markpointnum = 0;
}

//
// should be called at the start of every level
// right now, i figure it out myself
//
void __near AM_LevelInit(void) {
	fixed_t_union temp;
	am_scale_mtof.w = INITSCALEMTOF;
    AM_clearMarks();

    AM_findMinMaxBoundaries();
    //todo should this be a fixedMul by 1/0.7 instead?
	//scale_mtof.w = FixedDiv(am_min_scale_mtof, (int32_t) (0.7*FRACUNIT));

	temp.h.intbits = am_min_scale_mtof;
	temp.h.fracbits = 0;
	am_scale_mtof.w = FastDiv3216u(temp.w, 0xB333);

	//I_Error("%lx %lx %lx %lx", scale_mtof.w, a.w, b.w, am_min_scale_mtof);

	if (am_scale_mtof.w > am_max_scale_mtof.w) {
		am_scale_mtof.w = am_min_scale_mtof;
	}
    am_scale_ftom.w = FixedDivWholeA(1, am_scale_mtof.w);
}




//
//
//
void __far AM_Stop (void) {

    automapactive = false;
	st_gamestate = FirstPersonState;

    am_stopped = true;
}

//
//
//
void __far AM_Start (void) {

    if (!am_stopped) {
		AM_Stop();
	}
	am_stopped = false;
	
	if ((am_lastlevel != gamemap) || (am_lastepisode != gameepisode)) {
		AM_LevelInit();
		am_lastlevel = gamemap;
		am_lastepisode = gameepisode;
    }

	AM_initVariables();
 }

//
// set the window scale to the maximum size
//
void __near AM_minOutWindowScale(void) {
    am_scale_mtof.w = am_min_scale_mtof;
    am_scale_ftom.w = FixedDivWholeA(1, am_scale_mtof.w);
    AM_activateNewScale();
}

//
// set the window scale to the minimum size
//
void __near AM_maxOutWindowScale(void) {
    am_scale_mtof.w = am_max_scale_mtof.w;
    am_scale_ftom.w = FixedDivWholeA(1, am_scale_mtof.w);
    AM_activateNewScale();
}

//
// Handle events (user inputs) in automap mode
//
boolean __far AM_Responder ( event_t __far* ev ) {

	boolean rc;
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
			if (!followplayer) {
				m_paninc.x = FTOM16(SCREEN_PAN_INC);
			} else {
				rc = false;
			}
			break;
		  case AM_PANLEFTKEY: // pan left
			if (!followplayer){
				m_paninc.x = -FTOM16(SCREEN_PAN_INC);
			} else {
				rc = false;
			}
			break;
		  case AM_PANUPKEY: // pan up
			if (!followplayer) {
				m_paninc.y = FTOM16(SCREEN_PAN_INC);
			} else {
				rc = false;
			}
			break;
		  case AM_PANDOWNKEY: // pan down
			if (!followplayer){
				 m_paninc.y = -FTOM16(SCREEN_PAN_INC);
			} else { 
				rc = false;
			}
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
			am_bigstate = 0;
			viewactive = true;
			AM_Stop ();

			break;
		  case AM_GOBIGKEY:
			am_bigstate = !am_bigstate;
			if (am_bigstate) {
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
			am_grid = !am_grid;
			player.message = am_grid ? AMSTR_GRIDON : AMSTR_GRIDOFF;
			break;
		  case AM_MARKKEY:
			getStringByIndex(AMSTR_MARKEDSPOT, text);
			{
				char markpointstr[2];
				markpointstr[0] = '0' + markpointnum; 
				markpointstr[0] = '\0';
				combine_strings(am_buffer, text, markpointstr);
				player.messagestring = am_buffer;

			}
			AM_addMark();
			break;
		  case AM_CLEARMARKKEY:
			AM_clearMarks();
			player.message = AMSTR_MARKSCLEARED;
			break;
		  default:
			rc = false;
		}
		if ( cht_CheckCheat(CHEATID_AUTOMAP, ev->data1)) {
			rc = false;
			am_cheating = (am_cheating+1) % 3;
		}
	} else if (ev->type == ev_keyup) {
		rc = false;
		switch (ev->data1) {
		  case AM_PANRIGHTKEY:
			if (!followplayer) {
				m_paninc.x = 0;
			}
			break;
		  case AM_PANLEFTKEY:
			if (!followplayer) {
				m_paninc.x = 0;
			}
			break;
		  case AM_PANUPKEY:
			if (!followplayer) {
				m_paninc.y = 0;
			}
			break;
		  case AM_PANDOWNKEY:
			if (!followplayer) {
				m_paninc.y = 0;
			}
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
void __near AM_changeWindowScale(void) {

    // Change the scaling multipliers
    am_scale_mtof.w = FixedMul1632(mtof_zoommul, am_scale_mtof.w)<<4;
    am_scale_ftom.w = FixedDivWholeA(1, am_scale_mtof.w);

    if (am_scale_mtof.w < am_min_scale_mtof){
		AM_minOutWindowScale();
	} else if (am_scale_mtof.w > am_max_scale_mtof.w){
		AM_maxOutWindowScale();
	} else{
		AM_activateNewScale();
	}
}


//
//
//
void __near AM_doFollowPlayer(void) {


    if (screen_oldloc.x != playerMobj_pos->x.h.intbits || screen_oldloc.y != playerMobj_pos->y.h.intbits) {
		screen_botleft_x = (playerMobj_pos->x.h.intbits) - (screen_viewport_width >>1);
		screen_botleft_y = (playerMobj_pos->y.h.intbits) - (screen_viewport_height >>1);
		screen_topright_x = screen_botleft_x + screen_viewport_width;
		screen_topright_y= screen_botleft_y + screen_viewport_height;
		screen_oldloc.x = playerMobj_pos->x.h.intbits;
		screen_oldloc.y = playerMobj_pos->y.h.intbits;

    }

}

 

//
// Updates on Game Tick
//
void __far AM_Ticker (void) {

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


boolean __near AM_clipMline ( mline_t __near*	ml) {
    
    int16_t outcode1 = 0;
    int16_t outcode2 = 0;
    int16_t outside;
    
    fpoint_t	tmp;
    int16_t		dx;
	int16_t		dy;

    

    // do trivial rejects and outcodes
    if (ml->a.y > screen_topright_y){
		outcode1 = TOP;
    } else if (ml->a.y < screen_botleft_y){
		outcode1 = BOTTOM;
	}

    if (ml->b.y > screen_topright_y){
		outcode2 = TOP;
    } else if (ml->b.y < screen_botleft_y){
		outcode2 = BOTTOM;
	}
    
    if (outcode1 & outcode2){
		return false; // trivially outside
	}

    if (ml->a.x < screen_botleft_x){
		outcode1 |= LEFT;
    } else if (ml->a.x > screen_topright_x){
		outcode1 |= RIGHT;
	}

    if (ml->b.x < screen_botleft_x){
		outcode2 |= LEFT;
    } else if (ml->b.x > screen_topright_x){
		outcode2 |= RIGHT;
	}
    if (outcode1 & outcode2){
		return false; // trivially outside
	}

    // transform to frame-buffer coordinates.
    am_fl.a.x = CXMTOF16(ml->a.x);
    am_fl.a.y = CYMTOF16(ml->a.y);
    am_fl.b.x = CXMTOF16(ml->b.x);
    am_fl.b.y = CYMTOF16(ml->b.y);

	outcode1 = DOOUTCODE(outcode1, am_fl.a.x, am_fl.a.y);
	outcode2 = DOOUTCODE(outcode2, am_fl.b.x, am_fl.b.y);

    if (outcode1 & outcode2){
		return false;
	}

    while (outcode1 | outcode2) {
		// may be partially inside box
		// find an outside point
		if (outcode1){
			outside = outcode1;
		} else {
			outside = outcode2;
		}

		// clip to each side
		if (outside & TOP) {
			dy = am_fl.a.y - am_fl.b.y;
			dx = am_fl.b.x - am_fl.a.x;
			tmp.x = am_fl.a.x + (dx*(am_fl.a.y))/dy;
			tmp.y = 0;
		} else if (outside & BOTTOM) {
			dy = am_fl.a.y - am_fl.b.y;
			dx = am_fl.b.x - am_fl.a.x;
			tmp.x = am_fl.a.x + (dx*(am_fl.a.y-automap_screenheight))/dy;
			tmp.y = automap_screenheight-1;
		} else if (outside & RIGHT) {
			dy = am_fl.b.y - am_fl.a.y;
			dx = am_fl.b.x - am_fl.a.x;
			tmp.y = am_fl.a.y + (dy*(automap_screenwidth-1 - am_fl.a.x))/dx;
			tmp.x = automap_screenwidth-1;
		} else if (outside & LEFT) {
			dy = am_fl.b.y - am_fl.a.y;
			dx = am_fl.b.x - am_fl.a.x;
			tmp.y = am_fl.a.y + (dy*(-am_fl.a.x))/dx;
			tmp.x = 0;
		}

		if (outside == outcode1) {
			am_fl.a = tmp;
			outcode1 = DOOUTCODE(outcode1, am_fl.a.x, am_fl.a.y);
		} else {
			am_fl.b = tmp;
			outcode2 = DOOUTCODE(outcode2, am_fl.b.x, am_fl.b.y);
		}
	
		if (outcode1 & outcode2)
			return false; // trivially outside
		}

	return true;
}




//
// Clip lines, draw visible part sof lines.
//
void __near AM_drawMline ( mline_t __near*	ml, uint8_t	color ) {
	if (AM_clipMline(ml)){
		register int16_t x;
		register int16_t y;
		register int16_t dx;
		register int16_t dy;
		register int16_t sx;
		register int16_t sy;
		register int16_t ax;
		register int16_t ay;
		register int16_t d;
		
		
		//todo mult320? worth it?
		#define PUTDOT(xx,yy,cc) screen0[(yy)*automap_screenwidth+(xx)]=(cc)

	
		dx = am_fl.b.x - am_fl.a.x;
		ax = (dx<0 ? -dx : dx) << 1;
		sx = dx<0 ? -1 : 1;

		dy = am_fl.b.y - am_fl.a.y;
		ay = (dy<0 ? -dy : dy) << 1;
		sy = dy<0 ? -1 : 1;

		x = am_fl.a.x;
		y = am_fl.a.y;

		if (ax > ay) {
			d = ay - (ax>>1);
			while (1) {
				PUTDOT(x,y,color);
				if (x == am_fl.b.x) {
					return;
				}
				if (d>=0) {
					y += sy;
					d -= ax;
				}
				x += sx;
				d += ay;
			}
		} else {
			d = ax - (ay>>1);
			while (1) {
				PUTDOT(x, y, color);
				if (y == am_fl.b.y) { 
					return;
				}
				if (d >= 0) {
					x += sx;
					d -= ay;
				}
				y += sy;
				d += ax;
			}



		}
	}
}


//
// Draws flat (floor/ceiling tile) aligned grid lines.
//
void __near AM_drawGrid() {
    int16_t x, y;
	int16_t start, end;

    // Figure out start of vertical gridlines
	start = screen_botleft_x;
	
	if ((start - bmaporgx) % (0x80)) {
		start += (0x80) - ((start - bmaporgx) % (0x80));
	}
    end = (screen_botleft_x) + (screen_viewport_width);

    // draw vertical gridlines
	am_ml.a.y = screen_botleft_y;
	am_ml.b.y = screen_botleft_y +screen_viewport_height;
    for (x=start; x<end; x+=(0x80)) {
		am_ml.a.x = x;
		am_ml.b.x = x;
		AM_drawMline(&am_ml, GRIDCOLORS);
    }

    // Figure out start of horizontal gridlines
	start = screen_botleft_y;
	if ((start - bmaporgy) % (0x80)) {
		start += (0x80) - ((start - bmaporgy) % (0x80));
	}
    end = (screen_botleft_y )+ (screen_viewport_height);

    // draw horizontal gridlines
    am_ml.a.x = screen_botleft_x;
    am_ml.b.x = screen_botleft_x + screen_viewport_width;
    for (y=start; y<end; y+=(0x80)) {
		am_ml.a.y = y;
		am_ml.b.y = y;
		AM_drawMline(&am_ml, GRIDCOLORS);
    }

}

//
// Determines visible lines, draws them.
// This is LineDef based, not LineSeg based.
//
void __near AM_drawWalls() {
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
		mappedflag = seenlines_6800[i / 8] & (0x01 << (i%8));  // todo this seems wasteful? just add up during the loop to avoid all these shifts?
		lineflags = lineflagslist[i];
		linebacksecnum = lines_physics[i].backsecnum;
		linefrontsecnum = lines_physics[i].frontsecnum;
		linespecial = lines_physics[i].special;

		am_l.a.x = vertexes[linev1Offset].x;
		am_l.a.y = vertexes[linev1Offset].y;
		am_l.b.x = vertexes[linev2Offset].x;
		am_l.b.y = vertexes[linev2Offset].y;

		if (am_cheating || mappedflag) {
			if ((lineflags & LINE_NEVERSEE) && !am_cheating) {
				continue;
			} 
			if (linebacksecnum == SECNUM_NULL) {
				AM_drawMline(&am_l, WALLCOLORS);
			} else {
				floorheightnonequal = sectors[linebacksecnum].floorheight != sectors[linefrontsecnum].floorheight;
				ceilingheightnonequal = sectors[linebacksecnum].ceilingheight != sectors[linefrontsecnum].ceilingheight;
				if (linespecial == 39) { // teleporters
					AM_drawMline(&am_l, WALLCOLORS+WALLRANGE/2);
				} else if (lineflags & ML_SECRET){ // secret door
					if (am_cheating) { 
						AM_drawMline(&am_l, SECRETWALLCOLORS); 
					} else {
						AM_drawMline(&am_l, WALLCOLORS);
					}
				} else if (floorheightnonequal) {
					AM_drawMline(&am_l, FDWALLCOLORS); // floor level change
				}
				else if (ceilingheightnonequal) {
					AM_drawMline(&am_l, CDWALLCOLORS); // ceiling level change
				} else if (am_cheating) {
					AM_drawMline(&am_l, TSWALLCOLORS);
				}
			}
		} else if (player.powers[pw_allmap]) {
			if (!(lineflags & LINE_NEVERSEE)) {
				AM_drawMline(&am_l, GRAYS + 3);
			}
		}
    }
}


//
// Rotation in 2D.
// Used to rotate player arrow line character.
//
void __near AM_rotate ( int16_t __near*	x, int16_t __near* y, fineangle_t a ) {
	fixed_t_union tmpx;
	fixed_t_union tmpy;

    tmpx.w = (FastMulTrig16(FINE_COSINE_ARGUMENT, a, *x)) - FastMulTrig16(FINE_SINE_ARGUMENT, a,  *y);
    tmpy.w = (FastMulTrig16(FINE_SINE_ARGUMENT, a, *x)) + FastMulTrig16(FINE_COSINE_ARGUMENT, a,  *y);

	*y = tmpy.h.intbits;
	*x = tmpx.h.intbits;

}

void __near AM_drawLineCharacter ( mline_t __near*	lineguy,int16_t		lineguylines,int16_t	scale,fineangle_t	angle,uint8_t		color,int16_t	x,int16_t	y ){
    uint16_t		i;

    for (i=0;i<lineguylines;i++) {
		am_lc.a.x = lineguy[i].a.x;
		am_lc.a.y = lineguy[i].a.y;

		if (scale) {
			// scale is only ever 16 or 0
			am_lc.a.x <<= 4;
			am_lc.a.y <<= 4;
		}

		if (angle) {
			AM_rotate(&(am_lc.a.x), &am_lc.a.y, angle);
		}

		am_lc.a.x >>= 4;
		am_lc.a.y >>= 4;

		am_lc.a.x += x;
		am_lc.a.y += y;

		am_lc.b.x = lineguy[i].b.x;
		am_lc.b.y = lineguy[i].b.y;

		if (scale) {
			// scale is only ever 16 or 0
			am_lc.b.x <<= 4;
			am_lc.b.y <<= 4;
		}

		if (angle) {
			AM_rotate(&am_lc.b.x, &am_lc.b.y, angle);
		}
	
		am_lc.b.x >>= 4;
		am_lc.b.y >>= 4;

		am_lc.b.x += x;
		am_lc.b.y += y;

		AM_drawMline(&am_lc, color);
    }
}

void __near AM_drawPlayers(void) {
	
	if (am_cheating){
		AM_drawLineCharacter(cheat_player_arrow, NUMCHEATPLYRLINES, 0, playerMobj_pos->angle.hu.intbits>>SHORTTOFINESHIFT, WHITE, playerMobj_pos->x.h.intbits, playerMobj_pos->y.h.intbits);
	} else {
		AM_drawLineCharacter(player_arrow, NUMPLYRLINES, 0, playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT, WHITE, playerMobj_pos->x.h.intbits, playerMobj_pos->y.h.intbits);
	}


}

void __near AM_drawThings() {
    uint16_t		i;
    mobj_pos_t __far*	t;
	THINKERREF tRef;
	for (i=0;i<numsectors;i++) {
		tRef = sectors[i].thinglistRef;
		while (tRef) {
			t = (mobj_pos_t __far*)(&mobjposlist_6800[tRef]);
			
			AM_drawLineCharacter (thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
			 0x10L, t->angle.hu.intbits >> SHORTTOFINESHIFT, THINGCOLORS, t->x.h.intbits, t->y.h.intbits);
			tRef = t->snextRef;
		}
    }
}

void __near AM_drawMarks(void) {
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

void __near AM_drawCrosshair() {
    screen0[(automap_screenwidth*(automap_screenheight+1))/2] = XHAIRCOLORS; // single point for now

}

//void __far G_ExitLevel (void) ;

void __far AM_Drawer (void) {

	// sq - DEBUG: enable for easy/quick level change while debugging, i.e. to put pressure on memory
	//G_ExitLevel();

/*
	FILE* fp = fopen ("indump.txt", "w");
	Z_QuickMapRender();
	FAR_fwrite((byte __far*) flatindex, size_flatindex, 1, fp);
	fclose(fp);
	I_Error("done");
	*/

/*
	I_Error("%lx %lx %lx %lx", 
		playerMobj_pos->x.w, 
		playerMobj_pos->y.w, 
		playerMobj_pos->z.w,
		playerMobj_pos->angle.w
	);*/


	// 0E280C9b
	// 01532DF7
	// 0
	// 34C00000


/*
	playerMobj_pos->x.w =     0x0E280C9b;
	playerMobj_pos->y.w =     0x01532DF7;
	playerMobj_pos->z.w =     0x00000000;
	playerMobj_pos->angle.w = 0x34C00000;
	 
*/
	//setval = 1;
	I_Error("out!");
	// Clear automap frame buffer.
	FAR_memset(screen0, BACKGROUND, automap_screenwidth*automap_screenheight);

	if (am_grid){
		AM_drawGrid();
	}
	AM_drawWalls();
	AM_drawPlayers();
	if (am_cheating==2){
		AM_drawThings();
	}
	AM_drawCrosshair();

    AM_drawMarks();

    V_MarkRect(0, 0, automap_screenwidth, automap_screenheight);

}
#endif
