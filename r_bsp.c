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


int16_t		curlinenum;
//line_t*		linedef;
int16_t linedefOffset;
int16_t	frontsecnum;
int16_t	backsecnum;

drawseg_t	drawsegs[MAXDRAWSEGS];
drawseg_t*	ds_p;


void
R_StoreWallRange
( int16_t	start,
  int16_t	stop );




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
    int16_t	first;
	int16_t last;
    
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
( int16_t			first,
  int16_t			last )
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
	    
		// 1/11/98 killough: performance tuning using fast memmove
		memmove(start + 1, start, (++newend - start) * sizeof(*start));
		start->first = first;
		start->last = last;
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
( int16_t	first,
  int16_t	last )
{
    cliprange_t*	start;
	#ifdef LOOPCHECK 
	int16_t i = 0;
	#endif
    // Find the first range that touches the range
    //  (adjacent pixels are touching).
    start = solidsegs;
	while (start->last < first - 1) {
		start++;
		#ifdef LOOPCHECK 
			if (i > 1000) {
				I_Error("too big? q");
			}
		#endif	

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
	#ifdef LOOPCHECK 
		i = 0;
	#endif

    while (last >= (start+1)->first-1)
    {
		#ifdef LOOPCHECK 
			i++;
			if (i > 1000) {
					I_Error("too big?");
			}
		#endif	
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
    solidsegs[0].first = -0x7fff;
    solidsegs[0].last = -1;
    solidsegs[1].first = viewwidth;
    solidsegs[1].last = 0x7fff;
    newend = solidsegs+2;
}

//
// R_AddLine
// Clips the given segment
// and adds any visible pieces to the line list.
//
void R_AddLine (int16_t linenum)
{
    int16_t			x1;
    int16_t			x2;
    angle_t		angle1;
    angle_t		angle2;
    angle_t		span;
    angle_t		tspan;
	seg_t* segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	int16_t linebacksecnum = segs[linenum].backsecnum;
	int16_t curlinesidedefOffset = segs[linenum].sidedefOffset;
	int16_t linenumv1Offset = segs[linenum].v1Offset;
	int16_t linenumv2Offset = segs[linenum].v2Offset;
	side_t* sides;
	int16_t sidemidtex;
	sector_t* sectors;
	sector_t frontsector;
	sector_t backsector;
	vertex_t*   vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
	fixed_t_union tempx;
	fixed_t_union tempy;
    curlinenum = linenum;
	
	if (segs[curlinenum].linedefOffset > numlines) {
		I_Error("R_Addline Error! lines out of bounds! %i %i %i %i", gametic, numlines, segs[curlinenum].linedefOffset, curlinenum);
	}

	tempx.h.fracbits = 0;
	tempy.h.fracbits = 0;
	tempx.h.intbits = vertexes[linenumv1Offset].x;
	tempy.h.intbits = vertexes[linenumv1Offset].y;
    // OPTIMIZE: quickly reject orthogonal back sides.
    angle1 = R_PointToAngle (tempx.w, tempy.w);
	tempx.h.intbits = vertexes[linenumv2Offset].x;
	tempy.h.intbits = vertexes[linenumv2Offset].y;
    angle2 = R_PointToAngle (tempx.w, tempy.w);
    


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
	if (tspan > fieldofview)
	{
	tspan -= fieldofview;

	// Totally off the left edge?
	if (tspan >= span)
	    return;
	
	angle1 = clipangle;
    }
    tspan = clipangle - angle2;
	if (tspan > fieldofview)
	{
		tspan -= fieldofview;
	
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


	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	frontsector = sectors[frontsecnum];
	backsector = sectors[backsecnum];

 

    // Closed door.
    if (backsector.ceilingheight <= frontsector.floorheight
	|| backsector.floorheight >= frontsector.ceilingheight)
	goto clipsolid;		

    // Window.
    if (backsector.ceilingheight != frontsector.ceilingheight
	|| backsector.floorheight != frontsector.floorheight)
	goto clippass;	
		
    // Reject empty lines used for triggers
    //  and special events.
    // Identical floor and ceiling on both sides,
    // identical light levels on both sides,
    // and no middle texture.
    
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
	sidemidtex = sides[curlinesidedefOffset].midtexture;

	if (backsector.ceilingpic == sectors[frontsecnum].ceilingpic
	&& backsector.floorpic == sectors[frontsecnum].floorpic
	&& backsector.lightlevel == sectors[frontsecnum].lightlevel
	&& sidemidtex == 0)
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

boolean R_CheckBBox(int16_t *bspcoord)
{
	byte boxx;
	byte boxy;
	byte boxpos;

	int16_t x1;
	int16_t y1;
	int16_t x2;
	int16_t y2;

	angle_t angle1;
	angle_t angle2;
	angle_t span;
	angle_t tspan;

	cliprange_t *start;

	int16_t sx1;
	int16_t sx2;

	// Find the corners of the box
	// that define the edges from current viewpoint.

	boxx = (viewx.h.intbits < bspcoord[BOXLEFT] || (viewx.h.fracbits == 0 && viewx.h.intbits == bspcoord[BOXLEFT]))  ? 0 : viewx.h.intbits < bspcoord[BOXRIGHT] ? 1 : 2;
	boxy = viewy.h.intbits >= bspcoord[BOXTOP] ? 0 : (viewy.h.intbits > bspcoord[BOXBOTTOM] || (viewy.h.fracbits > 0 && viewy.h.intbits == bspcoord[BOXBOTTOM]  )) ? 1 : 2;

	boxpos = (boxy << 2) + boxx;
	if (boxpos == 5)
		return true;

	switch (boxpos)
	{
	case 0:
		x1 = bspcoord[BOXRIGHT];
		y1 = bspcoord[BOXTOP];
		x2 = bspcoord[BOXLEFT];
		y2 = bspcoord[BOXBOTTOM];
		break;
	case 1:
		x1 = bspcoord[BOXRIGHT];
		y1 = y2 = bspcoord[BOXTOP];
		x2 = bspcoord[BOXLEFT];
		break;
	case 2:
		x1 = bspcoord[BOXRIGHT];
		y1 = bspcoord[BOXBOTTOM];
		x2 = bspcoord[BOXLEFT];
		y2 = bspcoord[BOXTOP];
		break;
	case 3:
	case 7:
		x1 = x2 = y1 = y2 = bspcoord[BOXTOP];
		break;
	case 4:
		x1 = x2 = bspcoord[BOXLEFT];
		y1 = bspcoord[BOXTOP];
		y2 = bspcoord[BOXBOTTOM];
		break;
	case 6:
		x1 = x2 = bspcoord[BOXRIGHT];
		y1 = bspcoord[BOXBOTTOM];
		y2 = bspcoord[BOXTOP];
		break;
	case 8:
		x1 = bspcoord[BOXLEFT];
		y1 = bspcoord[BOXTOP];
		x2 = bspcoord[BOXRIGHT];
		y2 = bspcoord[BOXBOTTOM];
		break;
	case 9:
		x1 = bspcoord[BOXLEFT];
		y1 = y2 = bspcoord[BOXBOTTOM];
		x2 = bspcoord[BOXRIGHT];
		break;
	case 10:
		x1 = bspcoord[BOXLEFT];
		y1 = bspcoord[BOXBOTTOM];
		x2 = bspcoord[BOXRIGHT];
		y2 = bspcoord[BOXTOP];
		break;
	}

	// check clip list for an open space
	angle1 = R_PointToAngle16(x1, y1) - viewangle;
	angle2 = R_PointToAngle16(x2, y2) - viewangle;

	span = angle1 - angle2;

	// Sitting on a line?
	if (span >= ANG180)
		return true;

	tspan = angle1 + clipangle;

	if (tspan > fieldofview)
	{
		tspan -= fieldofview;

		// Totally off the left edge?
		if (tspan >= span)
			return false;

		angle1 = clipangle;
	}
	tspan = clipangle - angle2;
	if (tspan > fieldofview)
	{
		tspan -= fieldofview;

		// Totally off the left edge?
		if (tspan >= span)
			return false;

		angle2 = -clipangle;
	}

	// Find the first clippost
	//  that touches the source post
	//  (adjacent pixels are touching).
	angle1 = (angle1 + ANG90) >> ANGLETOFINESHIFT;
	angle2 = (angle2 + ANG90) >> ANGLETOFINESHIFT;
	sx1 = viewangletox[angle1];
	sx2 = viewangletox[angle2];

	// Does not cross a pixel.
	if (sx1 == sx2)
		return false;
	sx2--;

	start = solidsegs;
	while (start->last < sx2)
		start++;

	if (sx1 >= start->first && sx2 <= start->last)
	{
		// The clippost contains the new span.
		return false;
	}

	return true;
}



//
// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.
//
void R_Subsector(int16_t subsecnum)
{
	int16_t count;
	seg_t *line;
	subsector_t *sub;
	subsector_t* subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);
	//seg_t* segs;
	int16_t lineoffset = 0;
	int16_t firstline;
	sector_t* sectors;
	sector_t* frontsector;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	
    frontsecnum = subsectors[subsecnum].secnum;
    count = subsectors[subsecnum].numlines;
	firstline = subsectors[subsecnum].firstline;

	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	frontsector = &sectors[frontsecnum];

	// temp.h.intbits = frontsector->floorheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector->floorheight);

	if (temp.w < viewz.w) {
		floorplane = R_FindPlane(temp.w, frontsector->floorpic, frontsector->lightlevel);
	} else {
		floorplane = NULL;
	}
	// temp.h.intbits = frontsector->ceilingheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector->ceilingheight);
	// todo: see if frontsector->ceilingheight > viewz.h.intbits would work. same above -sq
	
	if (temp.w > viewz.w || frontsector->ceilingpic == skyflatnum) {
		ceilingplane = R_FindPlane(temp.w, frontsector->ceilingpic, frontsector->lightlevel);
	} else {
		ceilingplane = NULL;
	}

	R_AddSprites(frontsecnum);

	while (count--)	{
		R_AddLine(firstline + lineoffset);
		lineoffset++;
	}
}

//
// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.

#define MAX_BSP_DEPTH 64

void R_RenderBSPNode(int16_t bspnum) {
	node_t *bsp;
	fixed_t_union dx, dy;
	fixed_t left, right;
	int16_t stack_bsp[MAX_BSP_DEPTH];
	byte stack_side[MAX_BSP_DEPTH];
	int16_t sp = 0;
	byte side = 0;
	node_t* nodes;
	fixed_t_union temp;
	temp.h.fracbits = 0;

//	nodes = (node_t*)Z_LoadBytesFromEMSWithOptions(nodesRef, 3, true);

	while (true) {
		//Front sides.
		while ((bspnum & NF_SUBSECTOR) == 0) {
			if (sp == MAX_BSP_DEPTH)
				break;

			nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
			bsp = &nodes[bspnum];

			//decide which side the view point is on
			temp.h.intbits = bsp->x;
			dx.w = (viewx.w - temp.w);
			temp.h.intbits = bsp->y;
			dy.w = (viewy.w - temp.w);

			left = (bsp->dy) * (dx.h.intbits);
			right = (dy.h.intbits) * (bsp->dx);

			side = right >= left;

			stack_bsp[sp] = bspnum;
			stack_side[sp] = side;

			sp++;

			bspnum = bsp->children[side];
		}

		if (bspnum == -1)
			R_Subsector(0);
		else
			R_Subsector(bspnum & (~NF_SUBSECTOR));

		if (sp == 0)
		{
			//back at root node and not visible. All done!
			return;
		}

		//Back sides.

		sp--;

		bspnum = stack_bsp[sp];
		side = stack_side[sp];
		nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
		bsp = &nodes[bspnum];

		// Possibly divide back space.
		//Walk back up the tree until we find
		//a node that has a visible backspace.
		while (!R_CheckBBox(bsp->bbox[side ^ 1])) {
			if (sp == 0) {
				//back at root node and not visible. All done!
				return;
			}

			//Back side next.

			sp--;

			bspnum = stack_bsp[sp];
			side = stack_side[sp];

			nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
			bsp = &nodes[bspnum];
		}

		bspnum = bsp->children[side ^ 1];
	}

	//Z_SetLocked(nodesRef, PAGE_NOT_LOCKED, 11);
}
