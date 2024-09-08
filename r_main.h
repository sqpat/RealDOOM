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
extern int16_t		viewwidth;
extern int16_t		viewheight;
extern int16_t		viewwindowx;
extern int16_t		viewwindowy;
extern int16_t      viewwindowoffset;


extern int16_t		centerx;
extern int16_t		centery;

extern fixed_t_union		centeryfrac_shiftright4;
extern fixed_t_union		projection;

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



extern uint8_t		extralight;
extern uint8_t	fixedcolormap;

extern byte __far*			texturecache;

// Number of diminishing brightness levels.
// There a 0-31, i.e. 32 LUT in the COLORMAP lump.
#define NUMCOLORMAPS		32


// Blocky/low detail mode.
//B remove this?
//  0 = high, 1 = low
extern	int16_t_union		detailshift;	


//
// Function pointers to switch refresh/drawing functions.
// Used to select shadow mode etc.
//
// No shadow effects on floors.


//
// Utility functions.


/**/
#pragma aux fiveparam \
                    __parm [dx ax] [cx bx] [si] \
                    __modify [ax bx cx dx si];

#pragma aux (fiveparam)  R_PointOnSegSide;
int16_t __near R_PointOnSegSide ( fixed_t_union	x, fixed_t_union	y, int16_t segindex);

uint32_t __near R_PointToAngle16 (int16_t	x, int16_t	y);
uint32_t __far R_PointToAngle ( fixed_t_union	x, fixed_t_union	y );
uint32_t __far R_PointToAngle2 ( fixed_t_union	x1, fixed_t_union	y1, fixed_t_union	x2, fixed_t_union	y2 );
uint32_t __far R_PointToAngle2_16 (  int16_t	x2, int16_t	y2 );
fixed_t __near R_PointToDist ( int16_t	x,int16_t	y );


fixed_t __far R_ScaleFromGlobalAngle (fineangle_t visangle_shift3);

 



//
// REFRESH - the actual rendering functions.
//

// Called by G_Drawer.
void __far R_RenderPlayerView ();

// Called by startup code.
void __near R_Init (void);

// Called by M_Responder.
void __far R_SetViewSize (uint8_t blocks, uint8_t detail);

#endif
