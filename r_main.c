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




// increment every time a check is made
int16_t			validcount = 1;		


lighttable_t*		fixedcolormap;
extern lighttable_t**	walllights;

int16_t			centerx;
int16_t			centery;

fixed_t			centerxfrac;
fixed_t			centeryfrac;
fixed_t			projection;


fixed_t_union			viewx;
fixed_t_union			viewy;
fixed_t_union			viewz;

angle_t			viewangle;

fixed_t			viewcos;
fixed_t			viewsin;

// 0 = high, 1 = low
int8_t			detailshift;	

//
// precalculated math tables
//
angle_t			clipangle;
angle_t			fieldofview;

// The viewangletox[viewangle + FINEANGLES/4] lookup
// maps the visible view angles to screen X coordinates,
// flattening the arc to a flat projection plane.
// There will be many angles mapped to the same X. 
int16_t			viewangletox[FINEANGLES/2];

// The xtoviewangleangle[] table maps a screen pixel
// to the lowest viewangle that maps back to x ranges
// from clipangle to -clipangle.
fineangle_t			xtoviewangle[SCREENWIDTH+1];


// UNUSED.
// The finetangentgent[angle+FINEANGLES/4] table
// holds the fixed_t tangent values for view angles,
// ranging from MININT to 0 to MAXINT.
// fixed_t		finetangent[FINEANGLES/2];
// fixed_t		finesine(5*FINEANGLES/4);
//fixed_t*		finecosine = &finesine(FINEANGLES/4);


lighttable_t*		scalelight[LIGHTLEVELS][MAXLIGHTSCALE];
lighttable_t*		scalelightfixed[MAXLIGHTSCALE];
lighttable_t*		zlight[LIGHTLEVELS][MAXLIGHTZ];

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

    left = FixedMul ( node->dy , dx.w );
    right = FixedMul ( dy.w , node->dx );
	
    if (right < left) {
	    // front side
	    return 0;
    }
    // back side
    return 1;			
}



uint8_t
R_PointOnSegSide
( fixed_t	x,
  fixed_t	y,
  int16_t linev1Offset,
	int16_t linev2Offset)
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

	lx = vertexes[linev1Offset].x;
    ly = vertexes[linev1Offset].y;
	
    ldx = vertexes[linev2Offset].x - lx;
    ldy = vertexes[linev2Offset].y - ly;
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
    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 ) 
		// (left is negative)
		return  ((ldy ^ dx.h.intbits) & 0x8000);
    

    left = FixedMul ( ldy , dx.w );
    right = FixedMul ( dy.w , ldx );
	
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


angle_t
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


angle_t
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
						return tantoangle[tempDivision];
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
						return ANG90 - 1 - tantoangle[tempDivision];
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
						return -tantoangle[tempDivision];
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
						return ANG270 + tantoangle[tempDivision];
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
						return ANG180 - 1 - tantoangle[tempDivision];
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
						return ANG90 + tantoangle[tempDivision];
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
						return ANG180 + tantoangle[tempDivision];
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
						return ANG270 - 1 - tantoangle[tempDivision];
					else
						return ANG270 - 1 - 536870912L;
				}
			}
		}
	}
	return 0;
}


angle_t
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


angle_t
R_PointToAngle2_16
( int16_t	x1,
  int16_t	y1,
  int16_t	x2,
  int16_t	y2 )
{	
	fixed_t_union x2fp, y2fp;
    viewx.w = x1; // called with 0, this is fine
    viewy.w = y1;
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
    int16_t		angle;
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
	
	// todo use fixed_t_union to reduce shift
	angle = (tantoangle[ FixedDiv(dy,dx)>>DBITS ]+ANG90) >> ANGLETOFINESHIFT;

    // use as cosine
    dist = FixedDiv (dx, finesine(angle) );	
	
    return dist;
}


 

//
// R_ScaleFromGlobalAngle
// Returns the texture mapping scale
//  for the current line (horizontal span)
//  at the given angle.
// rw_distance must be calculated first.
//
fixed_t R_ScaleFromGlobalAngle (angle_t visangle)
{
    fixed_t_union		scale;
    fineangle_t			anglea;
    fineangle_t			angleb;
    fixed_t			sinea;
    fixed_t			sineb;
    fixed_t_union		    num;
    fixed_t			den;

	// todo use fixed_t_union to reduce shift
    anglea = (ANG90 + (visangle-viewangle))>> ANGLETOFINESHIFT;
    angleb = MOD_FINE_ANGLE(FINE_ANG90 + (visangle >> ANGLETOFINESHIFT) - rw_normalangle);

    // both sines are allways positive
    sinea = finesine(anglea);	
    sineb = finesine(angleb);
    num.w = FixedMul(projection,sineb)<<detailshift;
    den = FixedMul(rw_distance,sinea);

    // i somewhat wonder (on 16 bit compiler) if setting the union fields
    // individually produce better code than setting a 32 bit value..? -sq
    if (den > num.h.intbits) {
        scale.w = FixedDiv (num.w, den);

        if (scale.h.intbits > 64){
            scale.w = 0x400000L;
            //scale.h.fracbits = 0;
        } else if (scale.w < 256)
            scale.w = 256;
    } else{
        scale.w = 0x400000L;
    }
    
    return scale.w;
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
	node_t* nodes;
    // single subsector is a special case
	if (!numnodes) {
		return 0;
	}
		
	nodenum = numnodes - 1;
	nodes = (node_t*)Z_LoadBytesFromConventional(nodesRef);
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
	fixed_t tempan;

    viewx.w = playerMobj.x;
    viewy.w = playerMobj.y;
    viewangle = playerMobj.angle;
    extralight = player.extralight;

    viewz.w = player.viewz;
	// todo use fixed_t_union to reduce shift
	tempan = viewangle >> ANGLETOFINESHIFT;
    viewsin = finesine(tempan);
    viewcos = finecosine(tempan);
	
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
    destview = (byte*)(destscreen.w + (viewwindowy*SCREENWIDTH/4) + (viewwindowx >> 2));
}



//
// R_RenderView
//
void R_RenderPlayerView ()
{	

	R_SetupFrame ();

    // Clear buffers.
    R_ClearClipSegs ();
	R_ClearDrawSegs ();
    R_ClearPlanes ();
    R_ClearSprites ();

    // check for new console commands.
	NetUpdate ();


	// The head node is the last node output.
	//Z_LoadBytesFromConventionalWithOptions(nodesRef, PAGE_LOCKED);
	TEXT_MODE_DEBUG_PRINT("\n       R_RenderPlayerView: R_RenderBSPNode running...");
	R_RenderBSPNode ();
	TEXT_MODE_DEBUG_PRINT("\n       R_RenderPlayerView: R_RenderBSPNode done");
	//Z_SetUnlocked(nodesRef)

    // Check for new console commands.
    NetUpdate ();

    R_DrawPlanes ();
	TEXT_MODE_DEBUG_PRINT("\n       R_RenderPlayerView: R_DrawPlanes done");

    // Check for new console commands.
    NetUpdate ();

    R_DrawMasked ();
	TEXT_MODE_DEBUG_PRINT("\n       R_RenderPlayerView: R_DrawMasked done");

    // Check for new console commands.
    NetUpdate ();	

}
