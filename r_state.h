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
// DOOM 1 SHAREWARE VALUE


//
// Refresh internal data structures,
//  for rendering.
//



// needed for pre rendering (fracs)
extern int16_t		*spritewidths;
extern int16_t		*spriteoffsets;
extern int16_t		*spritetopoffsets;

//extern MEMREF		colormapsRef;
extern lighttable_t* colormaps;

extern int16_t		viewwidth;
extern int16_t		scaledviewwidth;
extern int16_t		viewheight;

extern int16_t		firstflat;


extern uint8_t* usedcompositetexturepagemem;
extern uint8_t* compositetextureoffset;
extern uint8_t* compositetexturepage;
extern uint8_t* usedpatchpagemem;
extern uint8_t* patchpage;
extern uint8_t* patchoffset;
extern uint8_t* usedspritepagemem;
extern uint8_t* spritepage;
extern uint8_t* spriteoffset;
extern uint8_t* flatindex;
 

extern uint8_t firstunusedflat;
extern int32_t totalpatchsize;
extern byte*	 spritedefs_bytes;

 
extern uint16_t *texturecolumn_offset;
extern uint16_t *texturedefs_offset;
extern uint8_t  *texturewidthmasks;
extern uint8_t  *textureheights;		    // uint8_t must be + 1 and then shifted to fracbits when used
extern uint16_t *texturecompositesizes;	// uint16_t*
// for global animation
extern uint8_t	*flattranslation; // can almost certainly be smaller
extern uint8_t	*texturetranslation;





// Sprite....


extern int16_t		firstspritelump;
extern int16_t		lastspritelump;
extern int16_t		numspritelumps;

extern int16_t             firstflat;
extern int16_t             lastflat;
extern int16_t             numflats;

extern int16_t             firstpatch;
extern int16_t             lastpatch;
extern int16_t             numpatches;
extern int16_t             numtextures;


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
extern seg_physics_t*		segs_physics;
extern seg_render_t*		segs_render;


extern int16_t		numsectors;
extern sector_t* sectors;
extern sector_physics_t* sectors_physics;

extern int16_t		numsubsectors;
extern subsector_t*	subsectors;

extern int16_t		numnodes;
extern node_t*      nodes;
extern node_render_t*      nodes_render;


extern int16_t		numlines;
extern line_t*   lines;
extern uint8_t*		seenlines;
extern line_physics_t*	lines_physics;



extern int16_t		numsides;
extern side_t*       sides;
extern side_render_t*		sides_render;

extern int16_t*          linebuffer;

extern mapthing_t*			nightmarespawns;

#ifdef PRECALCULATE_OPENINGS
extern lineopening_t*	lineopenings;
#endif

//
// POV data.
//
extern fixed_t_union		viewx;
extern fixed_t_union		viewy;
extern fixed_t_union		viewz;
extern short_height_t		viewz_shortheight;
extern angle_t		viewangle;
extern fineangle_t		viewangle_shiftright3;


// ?
extern angle_t		clipangle;	// note: fracbits always 0
extern angle_t fieldofview;		// note: fracbits always 0

extern int16_t		*viewangletox; //[FINEANGLES / 2];
extern fineangle_t		*xtoviewangle;// [SCREENWIDTH + 1];
//extern fixed_t		finetangent[FINEANGLES/2];

extern fixed_t		rw_distance;
extern fineangle_t	rw_normalangle;



// angle to line origin
 extern angle_t			rw_angle1;


// 644
#define VISPLANE_BYTE_SIZE (4 + 2 * SCREENWIDTH)
// 25
#define VISPLANES_PER_EMS_PAGE (PAGE_FRAME_SIZE  / VISPLANE_BYTE_SIZE)
#define NUM_VISPLANE_PAGES 3
#define MAXEMSVISPLANES (NUM_VISPLANE_PAGES * VISPLANES_PER_EMS_PAGE)

extern MEMREF visplanebytesRef[NUM_VISPLANE_PAGES]; 
extern visplaneheader_t	*visplaneheaders;// [MAXEMSVISPLANES];

#define MAXCONVENTIONALVISPLANES	60

// size for 60 is 39240, or 654 each... hasnt caused trouble yet?
// 70 is 45780
// 80 is 52320
// 90 is 58860
// 100 is 65400 (fits)
// start with this then add the view angles as well..
extern	visplane_t		*visplanes;// [MAXCONVENTIONALVISPLANES];
extern int16_t	floorplaneindex;
extern int16_t	ceilingplaneindex;


#endif
