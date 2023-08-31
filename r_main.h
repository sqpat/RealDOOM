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
//	System specific interface stuff.
//


#ifndef __R_MAIN__
#define __R_MAIN__

#include "d_player.h"
#include "r_data.h"


//
// POV related.
//
extern fixed_t		viewcos;
extern fixed_t		viewsin;

extern int16_t		viewwidth;
extern int16_t		viewheight;
extern int16_t		viewwindowx;
extern int16_t		viewwindowy;



extern int16_t		centerx;
extern int16_t		centery;

extern fixed_t		centerxfrac;
extern fixed_t		centeryfrac;
extern fixed_t		projection;

extern int16_t		validcount;

//
// Lighting LUT.
// Used for z-depth cuing per column/row,
//  and other lighting effects (sector ambient, flash).
//

// Lighting constants.
// Now why not 32 levels here?
#define LIGHTLEVELS	        16
#define LIGHTSEGSHIFT	         4

#define MAXLIGHTSCALE		48
#define LIGHTSCALESHIFT		12
#define MAXLIGHTZ	       128
#define LIGHTZSHIFT		20

extern lighttable_t*	scalelight[LIGHTLEVELS][MAXLIGHTSCALE];
extern lighttable_t*	scalelightfixed[MAXLIGHTSCALE];
extern lighttable_t*	zlight[LIGHTLEVELS][MAXLIGHTZ];

extern uint8_t		extralight;
extern lighttable_t*	fixedcolormap;


// Number of diminishing brightness levels.
// There a 0-31, i.e. 32 LUT in the COLORMAP lump.
#define NUMCOLORMAPS		32


// Blocky/low detail mode.
//B remove this?
//  0 = high, 1 = low
extern	int8_t		detailshift;	


//
// Function pointers to switch refresh/drawing functions.
// Used to select shadow mode etc.
//
extern void		(*colfunc) (void);
extern void		(*basecolfunc) (void);
extern void		(*fuzzcolfunc) (void);
// No shadow effects on floors.
extern void		(*spanfunc) (void);


//
// Utility functions.
int16_t
R_PointOnSide
( fixed_t	x,
  fixed_t	y,
  node_t*	node );

fixed_t
R_PointOnSegSide
( fixed_t	x,
  fixed_t	y,
	int16_t linev1Offset,
	int16_t linev2Offset);


angle_t
R_PointToAngle16
(int16_t	x,
	int16_t	y);

angle_t
R_PointToAngle
( fixed_t	x,
  fixed_t	y );

angle_t
R_PointToAngle2
( fixed_t	x1,
  fixed_t	y1,
  fixed_t	x2,
  fixed_t	y2 );

angle_t
R_PointToAngle2_16
( int16_t	x1,
  int16_t	y1,
  int16_t	x2,
  int16_t	y2 );

fixed_t
R_PointToDist
 ( int16_t	x,
   int16_t	y );


fixed_t R_ScaleFromGlobalAngle (angle_t visangle);

int16_t
R_PointInSubsector
( fixed_t	x,
  fixed_t	y );

 



//
// REFRESH - the actual rendering functions.
//

// Called by G_Drawer.
void R_RenderPlayerView ();

// Called by startup code.
void R_Init (void);

// Called by M_Responder.
void R_SetViewSize (uint8_t blocks, uint8_t detail);

#endif
