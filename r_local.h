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
//	Refresh (R_*) module, global header.
//	All the rendering/drawing stuff is here.
//

#ifndef __R_LOCAL__
#define __R_LOCAL__

// Binary Angles, sine/cosine/atan lookups.
#include "tables.h"

// Screen size related parameters.
#include "doomdef.h"

// Include the refresh/render data structs.
#include "r_data.h"



//
// Separate header file for each module.
//
#include "r_main.h"
#include "r_bsp.h"
#include "r_segs.h"
#include "r_plane.h"
#include "r_data.h"
#include "r_things.h"
#include "r_draw.h"

#define PATCHMASK 0x7FFF
#define ORIGINX_SIGN_FLAG 0x8000

typedef struct
{
	// Block origin (allways UL),
	// which has allready accounted
	// for the internal origin of the patch.
	uint8_t         originx; // in practice values range from ~-120 to 240. we use high bit of patch as negative
	int8_t         originy;  // in practice values range from ~-120 to 120
	int16_t         patch; // lump num
} texpatch_t;

typedef struct
{
	// Keep name for switch changing, etc.
	int8_t        name[8];
	// width and height max out at 256 and are never 0. we store as real size -  1 and add 1 whenever we readd it
	uint8_t       width;
	uint8_t       height;

	// All the patches[patchcount]
	//  are drawn back to front into the cached texture.
	uint8_t       patchcount;
	texpatch_t  patches[1];

} texture_t;

extern byte *colormapbytes;

#endif		// __R_LOCAL__
