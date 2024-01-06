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
#include "d_net.h"

#include "m_misc.h"

#include "r_local.h"


#include "i_system.h"
#include "doomstat.h"


// Fineangles in the SCREENWIDTH wide window.
#define FIELDOFVIEW		2048	

// Cached fields to avoid thinker access after page swap
int16_t r_cachedplayerMobjsecnum;
state_t r_cachedstatecopy[2];



// increment every time a check is made
//uint8_t			validcount = 1;
int16_t			validcount = 1;


//uint16_t*		fixedcolormap;
lighttable_t*		fixedcolormap;
extern lighttable_t**	walllights;

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

// The viewangletox[viewangle + FINEANGLES/4] lookup
// maps the visible view angles to screen X coordinates,
// flattening the arc to a flat projection plane.
// There will be many angles mapped to the same X. 
int16_t			*viewangletox;// [FINEANGLES / 2];

// The xtoviewangleangle[] table maps a screen pixel
// to the lowest viewangle that maps back to x ranges
// from clipangle to -clipangle.
fineangle_t			*xtoviewangle;// [SCREENWIDTH + 1];

lighttable_t**		scalelight;// [LIGHTLEVELS][MAXLIGHTSCALE];
//uint16_t*			scalelight;// [LIGHTLEVELS][MAXLIGHTSCALE];
lighttable_t*		*scalelightfixed;// [MAXLIGHTSCALE];
//uint16_t*			zlight;// [LIGHTLEVELS][MAXLIGHTZ];
lighttable_t**		zlight;// [LIGHTLEVELS][MAXLIGHTZ];

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
( fixed_t	x,
  fixed_t	y,
  node_t*	node )
{
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
    fixed_t_union temp;

    
        temp.h.fracbits = 0;
	
    if (!node->dx) {
        temp.h.intbits = node->x;
        if (x <= temp.w)
            return node->dy > 0;
        
        return node->dy < 0;
    }
    if (!node->dy) {
        temp.h.intbits = node->y;
        if (y <= temp.w)
            return node->dx < 0;
        
        return node->dx > 0;
    }
    temp.h.intbits = node->x;
    dx.w = (x - temp.w);
    temp.h.intbits = node->y;
    dy.w = (y - temp.w);
	
    // Try to quickly decide by looking at sign bits.
    if ( (node->dy ^ node->dx ^ dx.h.intbits ^ dy.h.intbits)&(int16_t)0x8000 ) {
        if  ( (node->dy ^ dx.h.intbits) &(int16_t) 0x8000 ) {
	        // (left is negative)
	        return 1;
	    }
	    return 0;
    }

    left = FixedMul1632 ( node->dy , dx.w );
    right = FixedMul1632 (node->dx, dy.w );
	
    if (right < left) {
	    // front side
	    return 0;
    }
    // back side
    return 1;			
}



int16_t
R_PointOnSegSide
( fixed_t	x,
  fixed_t	y,
  vertex_t* v1,
	vertex_t* v2)
{
    int16_t	lx;
    int16_t	ly;
    int16_t	ldx;
    int16_t	ldy;
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
	
    fixed_t_union temp;

	lx = v1->x;
    ly = v1->y;
	
    ldx = v2->x - lx;
    ldy = v2->y - ly;
	temp.h.fracbits = 0;

    if (!ldx) {
	    temp.h.intbits = lx;
        if (x <= temp.w)
            return ldy > 0;
        
        return ldy < 0;
    }
    if (!ldy) {
	    temp.h.intbits = ly;
        if (y <= temp.w)
            return ldx < 0;
        
        return ldx > 0;
    }

	temp.h.intbits = lx;
    dx.w = (x - temp.w);
	temp.h.intbits = ly;
    dy.w = (y - temp.w);
	
    // Try to quickly decide by looking at sign bits.
    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )  // returns 1
		// (left is negative)
		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1
    

    left = FixedMul1632 ( ldy , dx.w );
    right = FixedMul1632 (ldx, dy.w );
	
	// front side if true, back side if false
	return right >= left;

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


uint32_t
R_PointToAngle16
(int16_t	x,
	int16_t	y) {

	fixed_t_union xfp, yfp;
	xfp.h.intbits = x;
	yfp.h.intbits = y;
	xfp.h.fracbits = 0;
	yfp.h.fracbits = 0;

	return R_PointToAngle(xfp.w, yfp.w);
}


uint32_t
R_PointToAngle
( fixed_t	x,
  fixed_t	y )
{	
	fixed_t tempDivision;

	x -= viewx.w;
	y -= viewy.w;

	if ((!x) && (!y))
		return 0;

	if (x >= 0)
	{
		// x >=0
		if (y >= 0)
		{
			// y>= 0
			if (x > y)
			{
				// octant 0
				if (x < 512)
					return 536870912L;
				else
				{
					tempDivision = (y << 3) / (x >> 8);
					if (tempDivision < SLOPERANGE)
						return tantoangle[tempDivision].wu;
					else
						return 536870912L;
				}
			}
			else
			{
				// octant 1
				if (y < 512)
					return ANG90 - 1 - 536870912L;
				else
				{
					tempDivision = (x << 3) / (y >> 8);
					if (tempDivision < SLOPERANGE)
						return ANG90 - 1 - tantoangle[tempDivision].wu;
					else
						return ANG90 - 1 - 536870912L;
				}
			}
		}
		else
		{
			// y<0
			y = -y;

			if (x > y)
			{
				// octant 8
				if (x < 512)
					return -536870912L;
				else
				{
					tempDivision = (y << 3) / (x >> 8);
					if (tempDivision < SLOPERANGE)
						return -(tantoangle[tempDivision].wu);
					else
						return -536870912L;
				}
			}
			else
			{
				// octant 7
				if (y < 512)
					return ANG270 + 536870912L;
				else
				{
					tempDivision = (x << 3) / (y >> 8);
					if (tempDivision < SLOPERANGE)
						return ANG270 + tantoangle[tempDivision].wu;
					else
						return ANG270 + 536870912L;
				}
			}
		}
	}
	else
	{
		// x<0
		x = -x;

		if (y >= 0)
		{
			// y>= 0
			if (x > y)
			{
				// octant 3
				if (x < 512)
					return ANG180 - 1 - 536870912L;
				else
				{
					tempDivision = (y << 3) / (x >> 8);
					if (tempDivision < SLOPERANGE)
						return ANG180 - 1 - tantoangle[tempDivision].wu;
					else
						return ANG180 - 1 - 536870912L;
				}
			}
			else
			{
				// octant 2
				if (y < 512)
					return ANG90 + 536870912L;
				else
				{
					tempDivision = (x << 3) / (y >> 8);
					if (tempDivision < SLOPERANGE)
						return ANG90 + tantoangle[tempDivision].wu;
					else
						return ANG90 + 536870912L;
				};
			}
		}
		else
		{
			// y<0
			y = -y;

			if (x > y)
			{
				// octant 4
				if (x < 512)
					return ANG180 + 536870912L;
				else
				{
					tempDivision = (y << 3) / (x >> 8);
					if (tempDivision < SLOPERANGE)
						return ANG180 + tantoangle[tempDivision].wu;
					else
						return ANG180 + 536870912L;
				}
			}
			else
			{
				// octant 5
				if (y < 512)
					return ANG270 - 1 - 536870912L;
				else
				{
					tempDivision = (x << 3) / (y >> 8);
					if (tempDivision < SLOPERANGE)
						return ANG270 - 1 - tantoangle[tempDivision].wu;
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
( fixed_t	x1,
  fixed_t	y1,
  fixed_t	x2,
  fixed_t	y2 )
{	
    viewx.w = x1;
    viewy.w = y1;
    
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

    return R_PointToAngle (x2fp.w, y2fp.w);
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

extern int8_t textureLRU[4];
extern int16_t activetexturepages[4];
extern int16_t pageswapargs_textcache[8];



//
// sky mapping
//
uint8_t			skyflatnum;
uint8_t			skytexture;




//
// R_PointInSubsector
//
int16_t
 R_PointInSubsector
( fixed_t	x,
  fixed_t	y )
{
    node_t*	node;
    int16_t		side;
    int16_t		nodenum;
    // single subsector is a special case
	if (!numnodes) {
		return 0;
	}
		
	nodenum = numnodes - 1;
	while (! (nodenum & NF_SUBSECTOR) ) {
		node = &nodes[nodenum];
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

    viewz.w = player.viewz;
	viewz_shortheight = viewz.w >> (16 - SHORTFLOORBITS);

    viewsin = finesine[viewangle_shiftright3];
    viewcos = finecosine[viewangle_shiftright3];
	
    if (player.fixedcolormap)
    {
	fixedcolormap =
	    colormaps
	    + player.fixedcolormap*256*sizeof(lighttable_t);
	
	walllights = scalelightfixed;

	for (i=0 ; i<MAXLIGHTSCALE ; i++)
	    scalelightfixed[i] = fixedcolormap;
    }
    else
	fixedcolormap = 0;
		
    validcount++;
	// i think this sets the view within the border for when screen size is increased/shrunk
    
	destview = (byte*)(destscreen.w + viewwindowoffset);

	for (i = 0; i < 4; i++) {
		activetexturepages[i] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		textureLRU[i] = i;
		pageswapargs_textcache[i * 2] = FIRST_TEXTURE_LOGICAL_PAGE + i;
	}
	Z_QuickmapRenderTexture();


}
#ifdef DETAILED_BENCH_STATS

extern uint16_t renderplayersetuptics;
extern uint16_t renderplayerbsptics;
extern uint16_t renderplayerplanetics;
extern uint16_t renderplayermaskedtics;
extern uint16_t cachedrenderplayertics;
#endif

//
// R_RenderView
//
void R_RenderPlayerView ()
{	

#ifdef DETAILED_BENCH_STATS
	cachedrenderplayertics = ticcount;
#endif

	r_cachedplayerMobjsecnum = playerMobj->secnum;
	viewx.w = playerMobj_pos->x;
	viewy.w = playerMobj_pos->y;
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

    R_DrawPlanes ();
#ifdef DETAILED_BENCH_STATS
	renderplayerplanetics += ticcount - cachedrenderplayertics;
	cachedrenderplayertics = ticcount;
#endif

    // Check for new console commands.
    NetUpdate ();

    R_DrawMasked ();
#ifdef DETAILED_BENCH_STATS
	renderplayermaskedtics += ticcount - cachedrenderplayertics;
#endif

	// Check for new console commands.
    NetUpdate ();	
	Z_QuickmapPhysics();

}
