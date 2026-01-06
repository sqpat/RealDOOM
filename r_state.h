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
// #include "r_data.h"
// #include "z_zone.h"



#define SECNUM_NULL -1
#define LINENUM_NULL -1
#define SBARHEIGHT		32
 
// max values in doom 1 and doom2 combined
#define MAX_SIDES				2587u
#define MAX_SECTORS				348u
#define MAX_VERTEXES			1626u
#define MAX_LINES				1764u
#define MAX_SUBSECTORS			956u
#define MAX_NODES				955u
//#define MAX_SUBSECTORS		875u
//#define MAX_NODES				874u

#define MAX_SEGS				2815u
#define MAX_LINEBUFFER_COUNT	2542u

#define MAX_SIDES_SIZE		    		(MAX_SIDES *		sizeof(side_t))
#define MAX_SECTORS_SIZE			    (MAX_SECTORS *		sizeof(sector_t))
#define MAX_VERTEXES_SIZE			    (MAX_VERTEXES *		sizeof(vertex_t))
#define MAX_LINES_SIZE				    (MAX_LINES *		sizeof(line_t))
#define MAX_LINEFLAGS_SIZE			    (MAX_LINES *        sizeof(uint8_t))
#define MAX_SEENLINES_SIZE			    ((MAX_LINES / 8) + 1)
#define MAX_SUBSECTORS_SIZE	    		(MAX_SUBSECTORS *	sizeof(subsector_t))
#define MAX_SUBSECTOR_LINES_SIZE    	(MAX_SUBSECTORS *	sizeof(uint8_t))
#define MAX_NODES_SIZE		  		    (MAX_NODES *		sizeof(node_t))
#define MAX_NODE_CHILDREN_SIZE		    (MAX_NODES *		sizeof(node_children_t))
#define MAX_SEGS_SIZE				    (MAX_SEGS *			sizeof(seg_t))

#define MAX_SEGS_PHYSICS_SIZE   		(MAX_SEGS *		    sizeof(seg_physics_t))
#define MAX_SECTORS_PHYSICS_SIZE    	(MAX_SECTORS *		sizeof(sector_physics_t))
#define MAX_SECTORS_SOUNDORGS_SIZE      (MAX_SECTORS *      sizeof(sector_soundorg_t))
#define MAX_SECTORS_SOUNDTRAVERSED_SIZE (MAX_SECTORS *      sizeof(int8_t))
#define MAX_LINES_PHYSICS_SIZE  		(MAX_LINES *		sizeof(line_physics_t))

#define MAX_SIDES_RENDER_SIZE   		(MAX_SIDES *		sizeof(side_render_t))
#define MAX_NODES_RENDER_SIZE	    	(MAX_NODES *		sizeof(node_render_t))
#define MAX_SEGS_RENDER_SIZE		    (MAX_SEGS *			sizeof(seg_render_t))

#define MAX_LINEBUFFER_SIZE 			(MAX_LINEBUFFER_COUNT * sizeof(int16_t))
#define MAX_BLOCKMAP_LUMPSIZE	    	26870u
#define MAX_BLOCKLINKS_SIZE	    		7866u
#define MAX_REJECT_SIZE				    15138u
#define NIGHTMARE_SPAWN_SIZE		    (MAX_THINKERS *  sizeof(mapthing_t))


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
MAX_SEGS_PHYSICS_SIZE		11260
MAX_LINES_PHYSICS_SIZE		28224
MAX_BLOCKMAP_LUMPSIZE		26870u


818 over!!!

//43448
MAX_SECTORS_PHYSICS_SIZE	6960
MAX_LINEBUFFER_SIZE			5084
MAX_BLOCKLINKS_SIZE			7866u
NIGHTMARE_SPAWN_SIZE		8400u
MAX_REJECT_SIZE				15138u
 



MAX_SIDES_RENDER_SIZE		10348
MAX_NODES_RENDER_SIZE		13984
MAX_SEGS_RENDER_SIZE		28150


*/

//
// Refresh internal data structures,
//  for rendering.
//




#define MAXOPENINGS	SCREENWIDTH*64
#define MAXVISSPRITES  	128





// 646
// sizeof(visplane_t)
#define VISPLANE_BYTE_SIZE (6 + (2 * SCREENWIDTH))
// 25
#define VISPLANES_PER_EMS_PAGE (PAGE_FRAME_SIZE  / VISPLANE_BYTE_SIZE)
#define NUM_VISPLANE_PAGES 5
#define MAXEMSVISPLANES (NUM_VISPLANE_PAGES * VISPLANES_PER_EMS_PAGE)

// before swapping becomes required...
#define MAX_CONVENTIONAL_VISPLANES	75
  


 


#endif
