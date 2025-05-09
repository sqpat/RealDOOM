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
//  Sprite animation.
//

#ifndef __P_PSPR__
#define __P_PSPR__

// Basic data types.
// Needs fixed point, and BAM angles.
#include "doomdef.h"
#include "tables.h"


//
// Needs to include the precompiled
//  sprite animation tables.
// Header generated by multigen utility.
// This includes all the data for thing animation,
// i.e. the Thing Atrributes table
// and the Frame Sequence table.
#include "info.h"


//
// Frame flags:
// handles maximum brightness (torches, muzzle flare, light sources)
//
#define FF_FULLBRIGHT	0x80	// flag in thing->frame
#define FF_FRAMEMASK	0x7f



//
// Overlay psprites are scaled shapes
// drawn directly on the view screen,
// coordinates are given for a 320*200 view screen.
//
typedef enum {
    ps_weapon,
    ps_flash,
    NUMPSPRITES

} psprnum_t;

// 12 bytes each
typedef struct {
	statenum_t 	statenum;	// a NULL state means not active
	int16_t		tics;
    fixed_t	sx;
    fixed_t	sy;

} pspdef_t;

// Weapon info: sprite frames, ammunition use.
typedef struct {
    ammotype_t	ammo;
    int16_t		upstate;
    int16_t		downstate;
    int16_t		readystate;
    int16_t		atkstate;
    int16_t		flashstate;

} weaponinfo_t;


#endif
