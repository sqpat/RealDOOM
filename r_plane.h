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
//	Refresh, visplane stuff (floor, ceilings).
//


#ifndef __R_PLANE__
#define __R_PLANE__


#include "r_data.h"


// Visplane related.
extern  int16_t*		lastopening;

extern int16_t		*floorclip;// [SCREENWIDTH];
extern int16_t		*ceilingclip;// [SCREENWIDTH];
extern int16_t		*spanstart;// [SCREENHEIGHT];

extern fixed_t		*yslope;// [SCREENHEIGHT];
extern fixed_t		*distscale;// [SCREENWIDTH];

extern fixed_t			*cachedheight;// [SCREENHEIGHT];
extern fixed_t			*cacheddistance;// [SCREENHEIGHT];
extern fixed_t			*cachedxstep;// [SCREENHEIGHT];
extern fixed_t			*cachedystep;// [SCREENHEIGHT];

void R_InitPlanes (void);
void R_ClearPlanes (void);

void R_DrawPlanes (void);


int16_t
R_FindPlane
( fixed_t	height,
  uint8_t		picnum,
  uint8_t		lightlevel );

int16_t
R_CheckPlane
(int16_t	index,
  int16_t		start,
  int16_t		stop );



#endif
