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
//	Refresh/render internal state variables (global).
//


#ifndef __R_STATE__
#define __R_STATE__

// Need data structure definitions.
#include "d_player.h"
#include "r_data.h"
#include "z_zone.h"


#define SECNUM_NULL -1
#define LINENUM_NULL -1

// DOOM 1 SHAREWARE VALUE
#define NUM_TEXTURE_CACHE 125
// todo i think this might have to increase outside of shareware version?
#define NUM_SPRITE_LUMPS_CACHE 500

//
// Refresh internal data structures,
//  for rendering.
//

// needed for texture pegging
extern uint8_t		textureheights[NUM_TEXTURE_CACHE];

// needed for pre rendering (fracs)
extern int16_t		spritewidths[NUM_SPRITE_LUMPS_CACHE];
extern int16_t		spriteoffsets[NUM_SPRITE_LUMPS_CACHE];
extern int16_t		spritetopoffsets[NUM_SPRITE_LUMPS_CACHE];

//extern MEMREF		colormapsRef;
extern lighttable_t* colormaps;

extern int16_t		viewwidth;
extern int16_t		scaledviewwidth;
extern int16_t		viewheight;

extern int16_t		firstflat;

// for global animation
extern uint8_t			flattranslation[NUM_TEXTURE_CACHE];
extern uint8_t			texturetranslation[NUM_TEXTURE_CACHE];



// Sprite....
extern int16_t		firstspritelump;
extern int16_t		lastspritelump;
extern int16_t		numspritelumps;

extern int16_t firstnode;


//
// Lookup tables for map data.
//
extern int16_t		numsprites;
//extern MEMREF	spritesRef;
extern spritedef_t*	sprites;

extern int16_t		numvertexes;
extern vertex_t*	vertexes;

extern int16_t		numsegs;
extern seg_t*		segs;

extern int16_t		numsectors;
extern sector_t* sectors;
extern MEMREF    sectorBlockBoxesRef;

extern int16_t		numsubsectors;
extern subsector_t*	subsectors;

extern int16_t		numnodes;
extern node_t*      nodes;


extern int16_t		numlines;
extern line_t*   lines;

extern int16_t		numsides;
extern side_t*       sides;

extern int16_t*          linebuffer;


//
// POV data.
//
extern fixed_t_union		viewx;
extern fixed_t_union		viewy;
extern fixed_t_union		viewz;

extern angle_t		viewangle;


// ?
extern angle_t		clipangle;
extern angle_t fieldofview;

extern int16_t		viewangletox[FINEANGLES/2];
extern fineangle_t		xtoviewangle[SCREENWIDTH+1];
//extern fixed_t		finetangent[FINEANGLES/2];

extern fixed_t		rw_distance;
extern fineangle_t	rw_normalangle;



// angle to line origin
 // i have tried to remove this but the extra precision seems necessary to prevent drawing artifcts - sq
extern angle_t		rw_angle1;



// 644
#define VISPLANE_BYTE_SIZE (4 + 2 * SCREENWIDTH)
// 25
#define VISPLANES_PER_EMS_PAGE (PAGE_FRAME_SIZE  / VISPLANE_BYTE_SIZE)
#define NUM_VISPLANE_PAGES 3
#define MAXEMSVISPLANES (NUM_VISPLANE_PAGES * VISPLANES_PER_EMS_PAGE)

extern MEMREF visplanebytesRef[NUM_VISPLANE_PAGES]; 
extern visplaneheader_t	visplaneheaders[MAXEMSVISPLANES];

#define MAXCONVENTIONALVISPLANES	60

extern	visplane_t		visplanes[MAXCONVENTIONALVISPLANES];
extern int16_t	floorplaneindex;
extern int16_t	ceilingplaneindex;


#endif
