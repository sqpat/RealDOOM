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
//
// Refresh internal data structures,
//  for rendering.
//

// needed for texture pegging
extern MEMREF		textureheightRef;

// needed for pre rendering (fracs)
extern MEMREF		spritewidthRef;

extern MEMREF		spriteoffsetRef;
extern MEMREF		spritetopoffsetRef;

//extern MEMREF		colormapsRef;
extern lighttable_t* colormaps;

extern int16_t		viewwidth;
extern int16_t		scaledviewwidth;
extern int16_t		viewheight;

extern int16_t		firstflat;

// for global animation
extern MEMREF	flattranslationRef;	
extern MEMREF	texturetranslationRef;	


// Sprite....
extern int16_t		firstspritelump;
extern int16_t		lastspritelump;
extern int16_t		numspritelumps;



//
// Lookup tables for map data.
//
extern int16_t		numsprites;
extern MEMREF	spritesRef;

extern int16_t		numvertexes;
//extern vertex_t vertexes[946];
extern MEMREF	vertexesRef;

extern int16_t		numsegs;
extern MEMREF		segsRef;

extern int16_t		numsectors;
extern MEMREF	sectorsRef;

extern int16_t		numsubsectors;
extern MEMREF	subsectorsRef;

extern int16_t		numnodes;
extern MEMREF    nodesRef;


extern int16_t		numlines;
extern MEMREF   linesRef;

extern int16_t		numsides;
extern MEMREF       sidesRef;

//extern int16_t*	linebuffer;
extern MEMREF          linebufferRef;


//
// POV data.
//
extern fixed_t		viewx;
extern fixed_t		viewy;
extern fixed_t		viewz;

extern angle_t		viewangle;
extern player_t*	viewplayer;


// ?
extern angle_t		clipangle;
extern angle_t fieldofview;

extern int16_t		viewangletox[FINEANGLES/2];
extern fineangle_t		xtoviewangle[SCREENWIDTH+1];
//extern fixed_t		finetangent[FINEANGLES/2];

extern fixed_t		rw_distance;
extern fineangle_t	rw_normalangle;



// angle to line origin
extern angle_t		rw_angle1;


extern visplane_t*	floorplane;
extern visplane_t*	ceilingplane;


#endif
