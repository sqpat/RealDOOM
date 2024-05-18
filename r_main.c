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
//	Rendering main loop and setup functions,
//	 utility functions (BSP, geometry, trigonometry).
//	See tables.c, too.
//



#include <stdlib.h>
#include <math.h>


#include "doomdef.h"
#include "p_local.h"
#include "d_net.h"

#include "m_misc.h"

#include "r_local.h"


#include "i_system.h"
#include "doomstat.h"
#include "memory.h"
#include <dos.h>


// Fineangles in the SCREENWIDTH wide window.
#define FIELDOFVIEW		2048	

// Cached fields to avoid thinker access after page swap
int16_t r_cachedplayerMobjsecnum;
state_t r_cachedstatecopy[2];



// increment every time a check is made
//uint8_t			validcount = 1;
int16_t			validcount = 1;


uint16_t		fixedcolormap;
extern uint16_t __far*	walllights;

int16_t			centerx;
int16_t			centery;

// these basically equal: (16 low bits are 0, 16 high bits are view size / 2)
fixed_t_union			centerxfrac;
fixed_t_union			centeryfrac;
fixed_t_union			centeryfrac_shiftright4;
fixed_t_union			projection;


fixed_t_union			viewx;
fixed_t_union			viewy;
fixed_t_union			viewz;
short_height_t			viewz_shortheight;
angle_t			viewangle;
fineangle_t			viewangle_shiftright3;

fixed_t			viewcos;
fixed_t			viewsin;

// 0 = high, 1 = low
int8_t			detailshift;	

//
// precalculated math tables
//
angle_t			clipangle = { 0 };		// note: fracbits always 0
angle_t			fieldofview = { 0 };	// note: fracbits always 0

 
 

// bumped light from gun blasts
uint8_t			extralight;			



void (*colfunc) (void);
void (*basecolfunc) (void);
void (*fuzzcolfunc) (void);
void (*spanfunc) (void);

 

//
// R_PointOnSide
// Traverse BSP (sub) tree,
//  check point against partition plane.
// Returns side 0 (front) or 1 (back).
//
int16_t
R_PointOnSide
( fixed_t_union	x,
  fixed_t_union	y,
  node_t __far*	node )
{
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t_union	left;
    fixed_t_union	right;
    fixed_t_union temp;

    
        temp.h.fracbits = 0;
	
    if (!node->dx) {
        temp.h.intbits = node->x;
        if (x.w <= temp.w)
            return node->dy > 0;
        
        return node->dy < 0;
    }
    if (!node->dy) {
        temp.h.intbits = node->y;
        if (y.w <= temp.w)
            return node->dx < 0;
        
        return node->dx > 0;
    }
    temp.h.intbits = node->x;
    dx.w = (x.w - temp.w);
    temp.h.intbits = node->y;
    dy.w = (y.w - temp.w);
	
    // Try to quickly decide by looking at sign bits.
    if ( (node->dy ^ node->dx ^ dx.h.intbits ^ dy.h.intbits)&(int16_t)0x8000 ) {
        if  ( (node->dy ^ dx.h.intbits) &(int16_t) 0x8000 ) {
	        // (left is negative)
	        return 1;
	    }
	    return 0;
    }

    left.w = FixedMul1632 ( node->dy , dx.w );
    right.w = FixedMul1632 (node->dx, dy.w );
	
    if (right.w < left.w) {
	    // front side
	    return 0;
    }
    // back side
    return 1;			
}



int16_t
R_PointOnSegSide
( fixed_t_union	x,
  fixed_t_union	y,
  vertex_t __far* v1,
	vertex_t __far* v2)
{
    int16_t	lx;
    int16_t	ly;
    int16_t	ldx;
    int16_t	ldy;
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t_union	left;
    fixed_t_union	right;
	
    fixed_t_union temp;

	lx = v1->x;
    ly = v1->y;
	
    ldx = v2->x - lx;
    ldy = v2->y - ly;
	temp.h.fracbits = 0;

    if (!ldx) {
	    temp.h.intbits = lx;
        if (x.w <= temp.w)
            return ldy > 0;
        
        return ldy < 0;
    }
    if (!ldy) {
	    temp.h.intbits = ly;
        if (y.w <= temp.w)
            return ldx < 0;
        
        return ldx > 0;
    }

	temp.h.intbits = lx;
    dx.w = (x.w - temp.w);
	temp.h.intbits = ly;
    dy.w = (y.w - temp.w);
	
    // Try to quickly decide by looking at sign bits.
    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )  // returns 1
		// (left is negative)
		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1
    

    left.w = FixedMul1632 ( ldy , dx.w );
    right.w = FixedMul1632 (ldx, dy.w );
	
	// front side if true, back side if false
	return right.w >= left.w;

} 


//
// R_PointToAngle
// To get a global angle from cartesian coordinates,
//  the coordinates are flipped until they are in
//  the first octant of the coordinate system, then
//  the y (<=x) is scaled and divided by x to get a
//  tangent (slope) value which is looked up in the
//  tantoangle[] table.

//
angle_t __far* tantoangle;

uint32_t
R_PointToAngle16
(int16_t	x,
	int16_t	y) {

	fixed_t_union xfp, yfp;
	xfp.h.intbits = x;
	yfp.h.intbits = y;
	xfp.h.fracbits = 0;
	yfp.h.fracbits = 0;

	return R_PointToAngle(xfp, yfp);
}


uint32_t
R_PointToAngle
( fixed_t_union	x,
  fixed_t_union	y )
{	
	fixed_t_union tempDivision;

	x.w -= viewx.w;
	y.w -= viewy.w;

	if ((!x.w) && (!y.w))
		return 0;

	if (x.w >= 0)
	{
		// x >=0
		if (y.w >= 0)
		{
			// y>= 0
			if (x.w > y.w)
			{
				// octant 0
				if (x.w < 512)
					return 536870912L;
				else
				{
					tempDivision.w = (y.w << 3) / (x.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return tantoangle[tempDivision.h.fracbits].wu;
					else
						return 536870912L;
				}
			}
			else
			{
				// octant 1
				if (y.w < 512)
					return ANG90 - 1 - 536870912L;
				else
				{
					tempDivision.w = (x.w << 3) / (y.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return ANG90 - 1 - tantoangle[tempDivision.h.fracbits].wu;
					else
						return ANG90 - 1 - 536870912L;
				}
			}
		}
		else
		{
			// y<0
			y.w = -y.w;

			if (x.w > y.w)
			{
				// octant 8
				if (x.w < 512)
					return -536870912L;
				else
				{
					tempDivision.w = (y.w << 3) / (x.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return -(tantoangle[tempDivision.h.fracbits].wu);
					else
						return -536870912L;
				}
			}
			else
			{
				// octant 7
				if (y.w < 512)
					return ANG270 + 536870912L;
				else
				{
					tempDivision.w = (x.w << 3) / (y.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return ANG270 + tantoangle[tempDivision.h.fracbits].wu;
					else
						return ANG270 + 536870912L;
				}
			}
		}
	}
	else
	{
		// x<0
		x.w = -x.w;

		if (y.w >= 0)
		{
			// y>= 0
			if (x.w > y.w)
			{
				// octant 3
				if (x.w < 512)
					return ANG180 - 1 - 536870912L;
				else
				{
					tempDivision.w = (y.w << 3) / (x.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return ANG180 - 1 - tantoangle[tempDivision.h.fracbits].wu;
					else
						return ANG180 - 1 - 536870912L;
				}
			}
			else
			{
				// octant 2
				if (y.w < 512)
					return ANG90 + 536870912L;
				else
				{
					tempDivision.w = (x.w << 3) / (y.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return ANG90 + tantoangle[tempDivision.h.fracbits].wu;
					else
						return ANG90 + 536870912L;
				};
			}
		}
		else
		{
			// y<0
			y.w = -y.w;

			if (x.w > y.w)
			{
				// octant 4
				if (x.w < 512)
					return ANG180 + 536870912L;
				else
				{
					tempDivision.w = (y.w << 3) / (x.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return ANG180 + tantoangle[tempDivision.h.fracbits].wu;
					else
						return ANG180 + 536870912L;
				}
			}
			else
			{
				// octant 5
				if (y.w < 512)
					return ANG270 - 1 - 536870912L;
				else
				{
					tempDivision.w = (x.w << 3) / (y.w >> 8);
					if (tempDivision.w < SLOPERANGE)
						return ANG270 - 1 - tantoangle[tempDivision.h.fracbits].wu;
					else
						return ANG270 - 1 - 536870912L;
				}
			}
		}
	}
	return 0;
}


uint32_t
R_PointToAngle2
( fixed_t_union	x1,
  fixed_t_union	y1,
  fixed_t_union	x2,
  fixed_t_union	y2 )
{	
    viewx.w = x1.w;
    viewy.w = y1.w;
    
    return R_PointToAngle (x2, y2);
}


uint32_t
R_PointToAngle2_16
( 
	//int16_t	x1,
  //int16_t	y1,
  int16_t	x2,
  int16_t	y2 )
{	
	fixed_t_union x2fp, y2fp;
    viewx.w = 0; // called with 0, this is fine
    viewy.w = 0;
	x2fp.h.intbits = x2;
	y2fp.h.intbits = y2;
	x2fp.h.fracbits = 0;
	y2fp.h.fracbits = 0;

    return R_PointToAngle (x2fp, y2fp);
}


fixed_t
R_PointToDist
( int16_t	xarg,
  int16_t	yarg )

{
    fineangle_t		angle;
    fixed_t	dx;
    fixed_t	dy;
    fixed_t	temp;
    fixed_t	dist;
	fixed_t_union x;
	fixed_t_union y;
    x.h.fracbits = 0;
    y.h.fracbits = 0;
    x.h.intbits = xarg;
    y.h.intbits = yarg;


    dx = labs(x.w - viewx.w);
    dy = labs(y.w - viewy.w);

    if (dy>dx) {
        temp = dx;
        dx = dy;
        dy = temp;
    }
	
	angle = (tantoangle[ FixedDiv(dy,dx)>>DBITS ].hu.intbits+ANG90_HIGHBITS) >> SHORTTOFINESHIFT;

    // use as cosine
    dist = FixedDiv (dx, finesine[angle] );	
	
    return dist;
}


 

//
// R_ScaleFromGlobalAngle
// Returns the texture mapping scale
//  for the current line (horizontal span)
//  at the given angle.
// rw_distance must be calculated first.
//
fixed_t R_ScaleFromGlobalAngle (fineangle_t visangle_shift3)
{
    fixed_t_union		scale;
    fineangle_t			anglea;
    fineangle_t			angleb;
    fixed_t			sinea;
    fixed_t			sineb;
    fixed_t_union		    num;
    fixed_t			den;

    anglea = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3 - viewangle_shiftright3));
    angleb = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3) - rw_normalangle);



    // both sines are allways positive
    sinea = finesine[anglea];	
    sineb = finesine[angleb];
    num.w = FixedMulTrig(projection.w,sineb)<<detailshift;
    den = FixedMulTrig(rw_distance,sinea);

    if (den > num.h.intbits) {
        scale.w = FixedDiv (num.w, den);

        if (scale.h.intbits > 64){
            return 0x400000L;
            //scale.h.fracbits = 0;
		} else if (scale.w < 256) {
			return 256;
		}
		return scale.w;
    } else{
        return 0x400000L;
    }
    
}



 


//
// R_SetViewSize
// Do not really change anything here,
//  because it might be in the middle of a refresh.
// The change will take effect next refresh.
//
boolean		setsizeneeded;
uint8_t		setblocks;
uint8_t		setdetail;


void
R_SetViewSize
( uint8_t		blocks,
  uint8_t		detail )
{
    setsizeneeded = true;
    setblocks = blocks;
    setdetail = detail;
}

#define DISTMAP		2



//
// R_Init
//
extern uint8_t	detailLevel;
extern uint8_t	screenblocks;




//
// sky mapping
//
uint8_t			skyflatnum;
uint16_t			skytexture;




//
// R_PointInSubsector
//
int16_t
 R_PointInSubsector
( fixed_t_union	x,
  fixed_t_union	y )
{
    node_t __far*	node;
    int16_t		side;
    int16_t		nodenum;
    // single subsector is a special case
	if (!numnodes) {
		return 0;
	}
		
	nodenum = numnodes - 1;
	while (! (nodenum & NF_SUBSECTOR) ) {
		node = &nodes[nodenum];
		
		// only used here... inline?
		side = R_PointOnSide (x, y, node);
		nodenum = node->children[side];

    }

	return nodenum & ~NF_SUBSECTOR;
}


//
// R_SetupFrame
//
void R_SetupFrame ()
{		
    int8_t		i;

    extralight = player.extralight;

    viewz = player.viewz;
	viewz_shortheight = viewz.w >> (16 - SHORTFLOORBITS);

    viewsin = finesine[viewangle_shiftright3];
    viewcos = finecosine[viewangle_shiftright3];
	
    if (player.fixedcolormap) {
		//todo what was this again? why 0x2000
		fixedcolormap =
			0x2000
			+ player.fixedcolormap*256*sizeof(lighttable_t);
		
		walllights = scalelightfixed;

		for (i=0 ; i<MAXLIGHTSCALE ; i++){
			scalelightfixed[i] = fixedcolormap;
		}
    }
    else
	fixedcolormap = 0;
		
    validcount++;
	// i think this sets the view within the border for when screen size is increased/shrunk
    
	destview = (byte __far*)(destscreen.w + viewwindowoffset);

	/*
	for (i = 0; i < 4; i++) {
		//todo dont reset this per frame? keep last frame's cache?
		activetexturepages[i] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		textureLRU[i] = i;
		pageswapargs_rend[40 + i * 2] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		
		
		//#define pageswapargs_textcache ((int16_t*)&pageswapargs_rend[40])
	}	 
	*/


}
#ifdef DETAILED_BENCH_STATS

extern uint16_t renderplayersetuptics;
extern uint16_t renderplayerbsptics;
extern uint16_t renderplayerplanetics;
extern uint16_t renderplayermaskedtics;
extern uint16_t cachedrenderplayertics;
#endif
void M_StartMessage(int8_t __near * string,void __far_func (* routine)(int16_t), boolean input);

extern int8_t visplanedirty;
extern int16_t lastvisplane;

//
// R_RenderView
//
//void filelog2(int16_t a, int16_t b, int16_t c, int16_t d, int16_t e, int16_t f);
int8_t tempbuf[5];

void R_RenderPlayerView ()
{	

#ifdef DETAILED_BENCH_STATS
	cachedrenderplayertics = ticcount;
#endif

	r_cachedplayerMobjsecnum = playerMobj->secnum;
	viewx = playerMobj_pos->x;
	viewy = playerMobj_pos->y;
	viewangle = playerMobj_pos->angle;
	viewangle_shiftright3 = viewangle.hu.intbits >> 3;

	if (player.psprites[0].state) {
		r_cachedstatecopy[0] = *(player.psprites[0].state);
	}
	if (player.psprites[1].state) {
		r_cachedstatecopy[1] = *(player.psprites[1].state);
	}

	Z_QuickmapRender();
	R_SetupFrame ();


    // Clear buffers.
    R_ClearClipSegs ();
	R_ClearDrawSegs ();
    R_ClearPlanes ();
    R_ClearSprites ();

    // check for new console commands.
	NetUpdate ();

#ifdef DETAILED_BENCH_STATS
	renderplayersetuptics += ticcount - cachedrenderplayertics;
	cachedrenderplayertics = ticcount;
#endif

	// The head node is the last node output.
	R_RenderBSPNode ();

#ifdef DETAILED_BENCH_STATS
	renderplayerbsptics += ticcount - cachedrenderplayertics;
	cachedrenderplayertics = ticcount;
#endif

    // Check for new console commands.
    NetUpdate ();

	// We add this here to prepare the vissprites for psprites while certain variables are in memory and not paged-out yet
	R_PrepareMaskedPSprites();

	// replace render level data with flat cache
	Z_QuickMapFlatPage(0, 4);
	// put visplanes 0-75 back in memory (if necessary)
	if (visplanedirty){
		Z_QuickMapVisplaneRevert();
	}
    
	R_DrawPlanes ();
	// put away flat cache, put back level data

	Z_QuickMapUndoFlatCache();
	//Z_QuickMapSpritePage(); //todo combine somehow with above?


#ifdef DETAILED_BENCH_STATS
	renderplayerplanetics += ticcount - cachedrenderplayertics;
	cachedrenderplayertics = ticcount;
#endif

    // Check for new console commands.
    // 0x5c00 currently used in R_DrawPlanes as flat cache, but also needed in netupdate for events
	// either one extra page swap per frame or comment this out
	
	//NetUpdate ();

	R_DrawMasked ();
#ifdef DETAILED_BENCH_STATS
	renderplayermaskedtics += ticcount - cachedrenderplayertics;
#endif
	//filelog2(4, 0, 0, 0, 0, 0);

	// Check for new console commands.
	Z_QuickmapPhysics();

	sprintf(tempbuf, "%i", lastvisplane);
	player.messagestring=tempbuf;

	NetUpdate ();

	/*
	if (lastvisplane > visplanemax){
		visplanemax = lastvisplane;
	}
	*/



}
