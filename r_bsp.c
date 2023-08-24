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
//	BSP traversal, handling of LineSegs for rendering.
//


#include "doomdef.h"

#include "m_misc.h"

#include "i_system.h"

#include "r_main.h"
#include "r_plane.h"
#include "r_things.h"

// State.
#include "doomstat.h"
#include "r_state.h"

//#include "r_local.h"

int setval = 0;

short		curlinenum;
line_t*		linedef;
short	frontsecnum;
short	backsecnum;

drawseg_t	drawsegs[MAXDRAWSEGS];
drawseg_t*	ds_p;


void
R_StoreWallRange
( int	start,
  int	stop );




//
// R_ClearDrawSegs
//
void R_ClearDrawSegs (void)
{
    ds_p = drawsegs;
}



//
// ClipWallSegment
// Clips the given range of columns
// and includes it in the new clip list.
//
typedef	struct
{
    int	first;
    int last;
    
} cliprange_t;


#define MAXSEGS		32

// newend is one past the last valid seg
cliprange_t*	newend;
cliprange_t	solidsegs[MAXSEGS];




//
// R_ClipSolidWallSegment
// Does handle solid walls,
//  e.g. single sided LineDefs (middle texture)
//  that entirely block the view.
// 
void
R_ClipSolidWallSegment
( int			first,
  int			last )
{
    cliprange_t*	next;
    cliprange_t*	start;

    // Find the first range that touches the range
    //  (adjacent pixels are touching).
    start = solidsegs;
    while (start->last < first-1)
	start++;

    if (first < start->first)
    {
	if (last < start->first-1)
	{
	    // Post is entirely visible (above start),
	    //  so insert a new clippost.
	    R_StoreWallRange (first, last);
	    next = newend;
	    newend++;
	    
	    while (next != start)
	    {
		*next = *(next-1);
		next--;
	    }
	    next->first = first;
	    next->last = last;
	    return;
	}
		
	// There is a fragment above *start.
	R_StoreWallRange (first, start->first - 1);
	// Now adjust the clip size.
	start->first = first;	
    }

    // Bottom contained in start?
    if (last <= start->last)
	return;			
		
    next = start;
    while (last >= (next+1)->first-1)
    {
	// There is a fragment between two posts.
	R_StoreWallRange (next->last + 1, (next+1)->first - 1);
	next++;
	
	if (last <= next->last)
	{
	    // Bottom is contained in next.
	    // Adjust the clip size.
	    start->last = next->last;	
	    goto crunch;
	}
    }
	
    // There is a fragment after *next.
    R_StoreWallRange (next->last + 1, last);
    // Adjust the clip size.
    start->last = last;
	
    // Remove start+1 to next from the clip list,
    // because start now covers their area.
  crunch:
    if (next == start)
    {
	// Post just extended past the bottom of one post.
	return;
    }
    

    while (next++ != newend)
    {
	// Remove a post.
	*++start = *next;
    }

    newend = start+1;
}



//
// R_ClipPassWallSegment
// Clips the given range of columns,
//  but does not includes it in the clip list.
// Does handle windows,
//  e.g. LineDefs with upper and lower texture.
//
void
R_ClipPassWallSegment
( int	first,
  int	last )
{
    cliprange_t*	start;
	int i = 0;
    // Find the first range that touches the range
    //  (adjacent pixels are touching).
    start = solidsegs;
	while (start->last < first - 1) {
		start++;
		if (i > 1000) {
			I_Error("too big? q");
		}

	}
    if (first < start->first)
    {
	if (last < start->first-1)
	{
	    // Post is entirely visible (above start).
	    R_StoreWallRange (first, last);
	    return;
	}
		
	// There is a fragment above *start.
	R_StoreWallRange (first, start->first - 1);
    }

    // Bottom contained in start?
    if (last <= start->last)
	return;			
	i = 0;

    while (last >= (start+1)->first-1)
    {
		i++;
		if (i > 1000) {
				I_Error("too big?");
		}
	// There is a fragment between two posts.
	R_StoreWallRange (start->last + 1, (start+1)->first - 1);
	start++;
	
	if (last <= start->last)
	    return;
    }
	
    // There is a fragment after *next.
    R_StoreWallRange (start->last + 1, last);
}



//
// R_ClearClipSegs
//
void R_ClearClipSegs (void)
{
    solidsegs[0].first = -0x7fffffff;
    solidsegs[0].last = -1;
    solidsegs[1].first = viewwidth;
    solidsegs[1].last = 0x7fffffff;
    newend = solidsegs+2;
}

//
// R_AddLine
// Clips the given segment
// and adds any visible pieces to the line list.
//
void R_AddLine (short linenum)
{
    int			x1;
    int			x2;
    angle_t		angle1;
    angle_t		angle2;
    angle_t		span;
    angle_t		tspan;
	seg_t* segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	short linebacksecnum = segs[linenum].backsecnum;
	short curlinesidedefOffset = segs[curlinenum].sidedefOffset;
	short linenumv1Offset = segs[linenum].v1Offset;
	short linenumv2Offset = segs[linenum].v2Offset;

	vertex_t*   vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

    curlinenum = linenum;
	
	if (segs[curlinenum].linedefOffset > numlines) {
		I_Error("R_Addline Error! lines out of bounds! %i %i %i %i", gametic, numlines, segs[curlinenum].linedefOffset, curlinenum);
	}

    // OPTIMIZE: quickly reject orthogonal back sides.
    angle1 = R_PointToAngle (vertexes[linenumv1Offset].x, vertexes[linenumv1Offset].y);
    angle2 = R_PointToAngle (vertexes[linenumv2Offset].x, vertexes[linenumv2Offset].y);
    
    // Clip to view edges.
    // OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
    span = angle1 - angle2;
    
    // Back side? I.e. backface culling?
    if (span >= ANG180)
	return;		

    // Global angle needed by segcalc.
    rw_angle1 = angle1;
    angle1 -= viewangle;
    angle2 -= viewangle;
	
    tspan = angle1 + clipangle;
    if (tspan > 2*clipangle)
    {
	tspan -= 2*clipangle;

	// Totally off the left edge?
	if (tspan >= span)
	    return;
	
	angle1 = clipangle;
    }
    tspan = clipangle - angle2;
    if (tspan > 2*clipangle)
    {
	tspan -= 2*clipangle;

	// Totally off the left edge?
	if (tspan >= span)
	    return;	
	angle2 = -clipangle;
    }
    
    // The seg is in the view range,
    // but not necessarily visible.
    angle1 = (angle1+ANG90)>>ANGLETOFINESHIFT;
    angle2 = (angle2+ANG90)>>ANGLETOFINESHIFT;
    x1 = viewangletox[angle1];
    x2 = viewangletox[angle2];

    // Does not cross a pixel?
    if (x1 == x2)
	return;				

	backsecnum = linebacksecnum;

    // Single sided line?
    if (backsecnum == SECNUM_NULL)
		goto clipsolid;		

    // Closed door.
    if (sectors[backsecnum].ceilingheight <= sectors[frontsecnum].floorheight
	|| sectors[backsecnum].floorheight >= sectors[frontsecnum].ceilingheight)
	goto clipsolid;		

    // Window.
    if (sectors[backsecnum].ceilingheight != sectors[frontsecnum].ceilingheight
	|| sectors[backsecnum].floorheight != sectors[frontsecnum].floorheight)
	goto clippass;	
		
    // Reject empty lines used for triggers
    //  and special events.
    // Identical floor and ceiling on both sides,
    // identical light levels on both sides,
    // and no middle texture.
    if (sectors[backsecnum].ceilingpic == sectors[frontsecnum].ceilingpic
	&& sectors[backsecnum].floorpic == sectors[frontsecnum].floorpic
	&& sectors[backsecnum].lightlevel == sectors[frontsecnum].lightlevel
	&& sides[curlinesidedefOffset].midtexture == 0)
    {
	return;
    }
    
				
  clippass:
    R_ClipPassWallSegment (x1, x2-1);	
	return;
		
  clipsolid:
    R_ClipSolidWallSegment (x1, x2-1);

}


//
// R_CheckBBox
// Checks BSP node/subtree bounding box.
// Returns true
//  if some part of the bbox might be visible.
//
int	checkcoord[12][4] =
{
    {3,0,2,1},
    {3,0,2,0},
    {3,1,2,0},
    {0},
    {2,0,2,1},
    {0,0,0,0},
    {3,1,3,0},
    {0},
    {2,0,3,1},
    {2,1,3,1},
    {2,1,3,0}
};


boolean R_CheckBBox (fixed_t*	bspcoord)
{
    int			boxx;
    int			boxy;
    int			boxpos;

    fixed_t		x1;
    fixed_t		y1;
    fixed_t		x2;
    fixed_t		y2;
    
    angle_t		angle1;
    angle_t		angle2;
    angle_t		span;
    angle_t		tspan;
    
    cliprange_t*	start;

    int			sx1;
    int			sx2;
    
    // Find the corners of the box
    // that define the edges from current viewpoint.
    if (viewx <= bspcoord[BOXLEFT])
	boxx = 0;
    else if (viewx < bspcoord[BOXRIGHT])
	boxx = 1;
    else
	boxx = 2;
		
    if (viewy >= bspcoord[BOXTOP])
	boxy = 0;
    else if (viewy > bspcoord[BOXBOTTOM])
	boxy = 1;
    else
	boxy = 2;
		
    boxpos = (boxy<<2)+boxx;
    if (boxpos == 5)
	return true;
	
    x1 = bspcoord[checkcoord[boxpos][0]];
    y1 = bspcoord[checkcoord[boxpos][1]];
    x2 = bspcoord[checkcoord[boxpos][2]];
    y2 = bspcoord[checkcoord[boxpos][3]];
    
    // check clip list for an open space
    angle1 = R_PointToAngle (x1, y1) - viewangle;
    angle2 = R_PointToAngle (x2, y2) - viewangle;
	
    span = angle1 - angle2;

    // Sitting on a line?
    if (span >= ANG180)
	return true;
    
    tspan = angle1 + clipangle;

    if (tspan > 2*clipangle)
    {
	tspan -= 2*clipangle;

	// Totally off the left edge?
	if (tspan >= span)
	    return false;	

	angle1 = clipangle;
    }
    tspan = clipangle - angle2;
    if (tspan > 2*clipangle)
    {
	tspan -= 2*clipangle;

	// Totally off the left edge?
	if (tspan >= span)
	    return false;
	
	angle2 = -clipangle;
    }


    // Find the first clippost
    //  that touches the source post
    //  (adjacent pixels are touching).
    angle1 = (angle1+ANG90)>>ANGLETOFINESHIFT;
    angle2 = (angle2+ANG90)>>ANGLETOFINESHIFT;
    sx1 = viewangletox[angle1];
    sx2 = viewangletox[angle2];

    // Does not cross a pixel.
    if (sx1 == sx2)
	return false;			
    sx2--;
	
    start = solidsegs;
    while (start->last < sx2)
	start++;
    
    if (sx1 >= start->first
	&& sx2 <= start->last)
    {
	// The clippost contains the new span.
	return false;
    }

    return true;
}


int upcount = 0;

//
// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.
//
void R_Subsector (int num) {
    int			count;
    seg_t*		line;
    subsector_t*	sub;
	seg_t* segs;
	int lineoffset = 0;

	#ifdef RANGECHECK
		if (num >= numsubsectors) {
			I_Error("R_Subsector: ss %i with numss = %i", num, numsubsectors);
		}
	#endif
	Z_RefIsActive(nodesRef);



    sscount++;
    sub = &subsectors[num];
    frontsecnum = sub->secnum;
    count = sub->numlines;

    if (sectors[frontsecnum].floorheight < viewz) {
		floorplane = R_FindPlane (sectors[frontsecnum].floorheight,
			sectors[frontsecnum].floorpic,
			sectors[frontsecnum].lightlevel);
	}
	else {
		floorplane = NULL;
	}

    if (sectors[frontsecnum].ceilingheight > viewz  || sectors[frontsecnum].ceilingpic == skyflatnum) {
		ceilingplane = R_FindPlane (sectors[frontsecnum].ceilingheight,
			sectors[frontsecnum].ceilingpic,
			sectors[frontsecnum].lightlevel);
	} else {
		ceilingplane = NULL;
	}

	
    R_AddSprites (frontsecnum);
	 
	segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	line = &segs[sub->firstline];

    while (count--) {
		R_AddLine (sub->firstline + lineoffset);
		lineoffset++;
		if (count > 2000) {
			I_Error("too many lines???");
		}
		// note: segs definitely gets paged out inside of addline, so we need to re-set the line pointer based off its start point, not just
		// mindlessly add to the old paged-out address.
		//segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
		//line = &segs[sub->firstline + lineoffset];

		//if (line->linedefOffset > numlines) {
			//I_Error("R_subsector Error! lines out of bounds! %i %i %i %i", gametic, numlines, segs[curlinenum].linedefOffset, curlinenum);
		//}
	}
}



//
// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.
void R_RenderBSPNode (int bspnum) {
    node_t*	bsp;
    int		side;
	node_t* nodes;
    // Found a subsector?


	if (bspnum & NF_SUBSECTOR) {
		if (bspnum == -1) {
			R_Subsector(0);
		}
		else {
			R_Subsector(bspnum&(~NF_SUBSECTOR));
		}
		return;
    }

	nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
	bsp = &nodes[bspnum];
    
    // Decide which side the view point is on.
    side = R_PointOnSide (viewx, viewy, bsp);

    // Recursively divide front space.
    R_RenderBSPNode (bsp->children[side]); 
	nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
	bsp = &nodes[bspnum];

    // Possibly divide back space.
	if (R_CheckBBox(bsp->bbox[side ^ 1])) {
		R_RenderBSPNode(bsp->children[side ^ 1]);
	}


}


