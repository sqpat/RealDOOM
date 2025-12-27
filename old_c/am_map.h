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
//  AutoMap module.
//

#ifndef __AMMAP_H__
#define __AMMAP_H__
#include "doomtype.h"


// Called by main loop.
// void __near AM_Ticker (void);

// Called by main loop,
// called instead of view drawer if automap active.
// void __near AM_Drawer (void);

// Called to force the automap to quit
// if the level is completed while it is up.
void __far AM_Stop (void);

#define AM_NUMMARKPOINTS 10

typedef struct {
	int16_t x, y;
} fpoint_t;

typedef struct {
    fpoint_t a, b;
} fline_t;

typedef struct {
    int16_t		x,y;
} mpoint_t;

typedef struct {
    mpoint_t a, b;
} mline_t;





#endif
