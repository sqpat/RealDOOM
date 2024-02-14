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
 
// max values in doom 1 and doom2 combined
#define MAX_SIDES				2587u
#define MAX_SECTORS				348u
#define MAX_VERTEXES			1626u
#define MAX_LINES				1764u
#define MAX_SUBSECTORS			875u
#define MAX_NODES				874u
#define MAX_SEGS				2815u
#define MAX_LINEBUFFER_COUNT	2542u

#define MAX_SIDES_SIZE				(MAX_SIDES *		sizeof(side_t))
#define MAX_SECTORS_SIZE			(MAX_SECTORS *		sizeof(sector_t))
#define MAX_VERTEXES_SIZE			(MAX_VERTEXES *		sizeof(vertex_t))
#define MAX_LINES_SIZE				(MAX_LINES *		sizeof(line_t))
#define MAX_SUBSECTORS_SIZE			(MAX_SUBSECTORS *	sizeof(subsector_t))
#define MAX_NODES_SIZE				(MAX_NODES *		sizeof(node_t))
#define MAX_SEGS_SIZE				(MAX_SEGS *			sizeof(seg_t))

#define MAX_SEGS_PHYSICS_SIZE		(MAX_SIDES *		sizeof(seg_physics_t))
#define MAX_SECTORS_PHYSICS_SIZE	(MAX_SECTORS *		sizeof(sector_physics_t))
#define MAX_LINES_PHYSICS_SIZE		(MAX_LINES *		sizeof(line_physics_t))

#define MAX_SIDES_RENDER_SIZE		(MAX_SIDES *		sizeof(side_render_t))
#define MAX_NODES_RENDER_SIZE		(MAX_NODES *		sizeof(node_render_t))
#define MAX_SEGS_RENDER_SIZE		(MAX_SEGS *			sizeof(seg_render_t))

#define MAX_LINEBUFFER_SIZE			(MAX_LINEBUFFER_COUNT * sizeof(int16_t))
#define MAX_BLOCKMAP_LUMPSIZE		26870u
#define MAX_BLOCKLINKS_SIZE			7866u
#define MAX_REJECT_SIZE				15138u
#define NIGHTMARE_SPAWN_SIZE		(MAX_THINKERS *  sizeof(mapthing_t))


#define MAX_LEVEL_THINKERS			509u

/*

MAX_SIDES_SIZE				10348
MAX_SECTORS_SIZE			5568
MAX_VERTEXES_SIZE			6504
MAX_LINES_SIZE				8820
MAX_SUBSECTORS_SIZE			4375
MAX_NODES_SIZE				10488
MAX_SEGS_SIZE				8445

12138


//65442
MAX_SEGS_PHYSICS_SIZE		10348
MAX_LINES_PHYSICS_SIZE		28224
MAX_BLOCKMAP_LUMPSIZE		26870u

//43448
MAX_SECTORS_PHYSICS_SIZE	6960
MAX_LINEBUFFER_SIZE			5084
MAX_BLOCKLINKS_SIZE			7866u
NIGHTMARE_SPAWN_SIZE		8400u
MAX_REJECT_SIZE				15138u
// 6960
// 10348
// 28224
// 5084
// 26870u
// 7866u



MAX_SIDES_RENDER_SIZE		7761
MAX_NODES_RENDER_SIZE		13984
MAX_SEGS_RENDER_SIZE		28150


*/

//
// Refresh internal data structures,
//  for rendering.
//



// needed for pre rendering (fracs)
//extern int16_t		*spritewidths;
extern int16_t		 __far*spriteoffsets;
extern int16_t		 __far*spritetopoffsets;

#define colormaps		((lighttable_t  __far*			) 0x80000000)


extern int16_t		viewwidth;
extern int16_t		scaledviewwidth;
extern int16_t		viewheight;

extern int16_t		firstflat;


//extern uint8_t __far* usedcompositetexturepagemem;
extern uint8_t __far* compositetextureoffset;
extern uint8_t __far* compositetexturepage;
//extern uint8_t __far* usedpatchpagemem;
extern uint8_t __far* patchpage;
extern uint8_t __far* patchoffset;
//extern uint8_t __far* usedspritepagemem;
extern uint8_t __far* spritepage;
extern uint8_t __far* spriteoffset;
extern uint8_t __far* flatindex;
 

extern uint8_t firstunusedflat;
extern int32_t totalpatchsize;
extern byte __far*	 spritedefs_bytes;

 
extern uint16_t	__near*texturecolumn_offset;
extern uint16_t	__near*texturedefs_offset;
extern uint8_t	__near*texturewidthmasks;
extern uint8_t	__near*textureheights;		    // uint8_t must be + 1 and then shifted to fracbits when used
extern uint16_t	__near*texturecompositesizes;	// uint16_t*
// for global animation
extern uint8_t	__near*flattranslation; // can almost certainly be smaller
extern uint8_t	__near*texturetranslation;





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
extern spritedef_t __far*	sprites;

extern int16_t		numvertexes;
extern vertex_t __far*	vertexes;

extern int16_t		numsegs;
extern seg_t __far*		segs;


extern int16_t		numsectors;
extern sector_t __far* sectors;

// PHYSICS 0x6000 - 0x7FFF DATA
// note: strings in 0x6000-6400 region

 
//0x7000
#define size_segs_physics		(MAX_SEGS_PHYSICS_SIZE)
#define size_lines_physics		(size_segs_physics		+ MAX_LINES_PHYSICS_SIZE)
#define size_blockmaplump		(size_lines_physics		+ MAX_BLOCKMAP_LUMPSIZE)

//0x6400
#define size_sectors_physics	MAX_SECTORS_PHYSICS_SIZE
#define size_linebuffer			(size_sectors_physics	+ MAX_LINEBUFFER_SIZE)
#define size_blocklinks			(size_linebuffer		+ MAX_BLOCKLINKS_SIZE)
#define size_nightmarespawns	(size_blocklinks		+ NIGHTMARE_SPAWN_SIZE)
#define size_rejectmatrix		(size_nightmarespawns	+ MAX_REJECT_SIZE)

#define segs_physics		((seg_physics_t __far*)		(0x70000000))
#define lines_physics		((line_physics_t __far*)	(0x70000000 + size_segs_physics))
#define blockmaplump		((int16_t __far*)			(0x70000000 + size_lines_physics))
#define blockmaplump_plus4	((int16_t __far*)			(0x70000008 + size_lines_physics))

#define sectors_physics		((sector_physics_t __far* ) (0x60004000))
#define linebuffer			((int16_t __far*)			(0x60004000 + size_sectors_physics))
#define blocklinks			((THINKERREF __far*)		(0x60004000 + size_linebuffer))
#define nightmarespawns		((mapthing_t __far *)		(0x60004000 + size_blocklinks))
#define rejectmatrix		((byte __far *)				(0x60004000 + size_nightmarespawns))


#define size_nodes_render		MAX_NODES_RENDER_SIZE
#define size_sides_render		(MAX_SIDES_RENDER_SIZE)
#define size_segs_render		(size_sides_render		+ MAX_SEGS_RENDER_SIZE)
//#define size_RENDER_SCRATCH		(size_segs_render		+ MAX_SEGS_RENDER_SIZE)

// RENDER 0x7000 - 0x7FFF DATA

#define nodes_render	((node_render_t __far*)		0x70000000)
//#define sides_render	((side_render_t __far*)		(nodes_render + MAX_NODES_RENDER_SIZE))
#define sides_render	((side_render_t __far*)		0x70008000)
#define segs_render		((seg_render_t	__far*)		(0x70008000 + size_sides_render))
#define RENDER_SCRATCH  ((int16_t		__far*)		(0x70008000 + size_segs_render))


/*
segs_physics		7000:0000
lines_physics		7000:286c
blockmaplump		7000:96ac
sectors_physics		6000:4000
linebuffer			6000:5b30
blocklinks			6000:6f0c
nightmarespawns		6000:8dc6
rejectmatrix		6000:ae96

nodes_render		7000:0000  // this is paged out for two flat cache pages after render_bspnode
sides_render		7000:8000
segs_render			7000:9e51
... remaining		7000:0c47


*/
extern int16_t		numsubsectors;
extern subsector_t __far*	subsectors;

extern int16_t		numnodes;
extern node_t __far*      nodes;

extern int16_t		numlines;
extern line_t __far*   lines;
extern uint8_t __far*		seenlines;



extern int16_t		numsides;
extern side_t __far*       sides;




#ifdef PRECALCULATE_OPENINGS
extern lineopening_t __far*	lineopenings;
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

 extern visplaneheader_t __far	*visplaneheaders;// [MAXEMSVISPLANES];

#define MAXCONVENTIONALVISPLANES	60
  



extern int16_t	floorplaneindex;
extern int16_t	ceilingplaneindex;


#endif
