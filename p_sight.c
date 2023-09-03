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
//	LineOfSight/Visibility checks, uses REJECT Lookup Table.
//


#include "doomdef.h"

#include "i_system.h"
#include "p_local.h"

// State.
#include "r_state.h"
#include "m_misc.h"

//
// P_CheckSight
//
fixed_t		sightzstart;		// eye z of looker
fixed_t		topslope;
fixed_t		bottomslope;		// slopes to top and bottom of target

divline_t	strace;			// from t1 to t2
fixed_t		cachedt2x;
fixed_t		cachedt2y;


//
// P_DivlineSide
// Returns side 0 (front), 1 (back), or 2 (on).
//

P_DivlineSide
( fixed_t	x,
  fixed_t	y,
  divline_t*	node )
{
    fixed_t_union	dx;
	fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;

    if (!node->dx.w)
    {
	if (x==node->x.w)
	    return 2;
	
	if (x <= node->x.w)
	    return node->dy.w > 0;

	return node->dy.w < 0;
    }
    
    if (!node->dy.w)
    {
	if (x==node->y.w)
	    return 2;

	if (y <= node->y.w)
	    return node->dx.w < 0;

	return node->dx.w > 0;
    }
	
    dx.w = (x - node->x.w);
    dy.w = (y - node->y.w);
	
    left =  (node->dy.h.intbits) * (dx.h.intbits);
    right = (dy.h.intbits) * (node->dx.h.intbits);
	
    if (right < left)
	return 0;	// front side
    
    if (left == right)
	return 2;
    return 1;		// back side
}

P_DivlineSide16
( int16_t	x,
  int16_t	y,
  divline_t*	node )
{
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
    fixed_t_union	temp;

	// NOTE: these divlines have proper 32 bit fixed_t

    if (!node->dx.w) {
		temp.w = node->x.w;
		if (x==temp.h.intbits)
			return 2;
		
		if (x <= temp.h.intbits)
			return node->dy.w > 0;

		return node->dy.w < 0;
    }
    
    if (!node->dy.w) {
		temp.w = node->y.w;
		if (x==temp.h.intbits)
			return 2;

		if (y <= temp.h.intbits)
			return node->dx.w < 0;

		return node->dx.w > 0;
    }
	
	temp.h.intbits = x;
	temp.h.fracbits = 0;

    dx.w = (temp.w - node->x.w);
	temp.h.intbits = y;
    dy.w = (temp.w - node->y.w);
	temp.w = node->dy.w;
    left =  (temp.h.intbits) * (dx.h.intbits);
	temp.w = node->dx.w;
    right = (dy.h.intbits) * (temp.h.intbits);
	
    if (right < left)
	return 0;	// front side
    
    if (left == right)
	return 2;
    return 1;		// back side
}


P_DivlineSideNode
( fixed_t	x,
  fixed_t	y,
  node_t*	node )
{

	// NOTE: these nodes have proper 16 bit integer fields.

    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
    fixed_t_union	temp;


    if (!node->dx) {
		temp.h.intbits = node->x;
		temp.h.fracbits = 0;

		if (x==temp.w)
			return 2;
		
		if (x <= temp.w)
			return node->dy > 0;

		return node->dy < 0;
    }
    
    if (!node->dy) {
		temp.h.intbits = node->y;
		temp.h.fracbits = 0;

		if (x==temp.w)
			return 2;
		if (y <= temp.w)
			return node->dx < 0;

		return node->dx > 0;
    }

	temp.h.intbits = node->x;
	temp.h.fracbits = 0;

    dx.w = (x - temp.w);
	temp.h.intbits = node->y;
    dy.w = (y - temp.w);

    left =  (node->dy) * (dx.h.intbits);
    right = (dy.h.intbits) * (node->dx);
	
    if (right < left)
		return 0;	// front side
    
    if (left == right)
		return 2;
    return 1;		// back side
}



//
// P_InterceptVector2
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings and addlines traversers.
//
/*
fixed_t
P_InterceptVector2
( divline_t*	v2,
  node_t*	v1 )
{
    fixed_t	frac;
    fixed_t	num;
    fixed_t	den;
	fixed_t_union tempdy;
	fixed_t_union tempdx;
	fixed_t_union tempx;
	fixed_t_union tempy;

	tempdy.h.intbits = v1->dy;
	tempdx.h.intbits = v1->dx;
	tempdy.h.fracbits = 0;
	tempdx.h.fracbits = 0;

	
	//v1 has 16 bit fields..
	
    den = FixedMul (tempdy.w>>8,v2->dx) - FixedMul(tempdx.w>>8,v2->dy);

    if (den == 0)
		return 0;
    
	tempx.h.intbits = v1->x;
	tempy.h.intbits = v1->y;
	tempx.h.fracbits = 0;
	tempy.h.fracbits = 0;

    num = FixedMul ( (tempx.w - v2->x)>>8 ,tempdy.w) + 
	FixedMul ( (v2->y - tempy.w)>>8 , v1->dx);
    frac = FixedDiv (num , den);

    return frac;
}

*/
fixed_t
P_InterceptVector2
( divline_t*	v2,
  divline_t*	v1 )
{
    fixed_t	frac;
    fixed_t	num;
    fixed_t	den;
	
    den = FixedMul (v1->dy.w>>8,v2->dx.w) - FixedMul(v1->dx.w>>8,v2->dy.w);

    if (den == 0)
		return 0;
    
    num = FixedMul ( (v1->x.w - v2->x.w)>>8 ,v1->dy.w) + 
	FixedMul ( (v2->y.w - v1->y.w)>>8 , v1->dx.w);
    frac = FixedDiv (num , den);

    return frac;
}

//static int32_t  bspcounter = 0;

//
// P_CrossSubsector
// Returns true
//  if strace crosses the given subsector successfully.
//
boolean P_CrossSubsector (int16_t subsecnum)
{
    int16_t		segnum;
	int16_t linedefOffset;
    line_t*		line;
    int8_t			s1;
    int8_t			s2;
    int16_t			count;
    int16_t frontsecnum;
	int16_t backsecnum;
    short_height_t		opentop;
    short_height_t		openbottom;
    node_t		divlNode;
    divline_t		divl;
    vertex_t		v1;
    vertex_t		v2;
    fixed_t		frac;
    fixed_t		slope;
	seg_t* segs;
	vertex_t* vertexes;
	line_t* lines;
	int16_t linev1Offset;
	int16_t linev2Offset;
	int16_t lineflags;
	subsector_t* subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);
	sector_t* sectors;
	fixed_t_union temp;
 	temp.h.fracbits = 0;
    // check lines
    count = subsectors[subsecnum].numlines;
    segnum = subsectors[subsecnum].firstline;
	

    for ( ; count ; segnum++, count--) {
		segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
		linedefOffset = segs[segnum].linedefOffset;
		frontsecnum = segs[segnum].frontsecnum;
		backsecnum = segs[segnum].backsecnum;
		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
		line = &lines[linedefOffset];



		// allready checked other side?
		if (line->validcount == validcount) {
			continue;
		}
		line->validcount = validcount;
		linev1Offset = line->v1Offset;
		linev2Offset = line->v2Offset;
		lineflags = line->flags;

		vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

		v1 = vertexes[linev1Offset];
		v2 = vertexes[linev2Offset];
		s1 = P_DivlineSide16 (v1.x, v1.y, &strace);
		s2 = P_DivlineSide16 (v2.x, v2.y, &strace);

		// line isn't crossed?
		if (s1 == s2)
			continue;
		
		divl.x.h.fracbits = 0;
		divl.y.h.fracbits = 0;
		divl.dx.h.fracbits = 0;
		divl.dy.h.fracbits = 0;
		
		divl.x.h.intbits = v1.x;
		divl.y.h.intbits = v1.y;
		divl.dx.h.intbits = v2.x - v1.x;
		divl.dy.h.intbits = v2.y - v1.y;

		s1 = P_DivlineSide(strace.x.w, strace.y.w, &divl);
		s2 = P_DivlineSide(cachedt2x, cachedt2y, &divl);


		// divlNode.x = v1.x;
		// divlNode.y = v1.y;
		// divlNode.dx = v2.x - v1.x;
		// divlNode.dy = v2.y - v1.y;
		// s1 = P_DivlineSideNode (strace.x, strace.y, &divlNode);
		// s2 = P_DivlineSideNode (cachedt2x, cachedt2y, &divlNode);


		// line isn't crossed?
		if (s1 == s2)
			continue;	
		

		// stop because it is not two sided anyway
		// might do this after updating validcount?
		if (!(lineflags & ML_TWOSIDED)) {

			return false;
		}
	
		// crosses a two sided line

		// no wall to block sight with?

		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		if (sectors[frontsecnum].floorheight == sectors[backsecnum].floorheight && sectors[frontsecnum].ceilingheight == sectors[backsecnum].ceilingheight) {
			continue;
		}

		// possible occluder
		// because of ceiling height differences
		if (sectors[frontsecnum].ceilingheight < sectors[backsecnum].ceilingheight)
			opentop = sectors[frontsecnum].ceilingheight;
		else
			opentop = sectors[backsecnum].ceilingheight;

		// because of ceiling height differences
		if (sectors[frontsecnum].floorheight > sectors[backsecnum].floorheight)
			openbottom = sectors[frontsecnum].floorheight;
		else
			openbottom = sectors[backsecnum].floorheight;
		
		// quick test for totally closed doors
		if (openbottom >= opentop) {


			return false;		// stop
		}
	
		frac = P_InterceptVector2 (&strace, &divl);
		// frac = P_InterceptVector2 (&strace, &divlNode);
		
		if (sectors[frontsecnum].floorheight != sectors[backsecnum].floorheight) {
		 	// temp.h.intbits = openbottom >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  openbottom);
			slope = FixedDiv (temp.w - sightzstart , frac);
			if (slope > bottomslope)
				bottomslope = slope;
		}
		
		if (sectors[frontsecnum].ceilingheight != sectors[backsecnum].ceilingheight) {
		 	// temp.h.intbits = opentop >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  opentop);
			slope = FixedDiv (temp.w - sightzstart , frac);
			if (slope < topslope)
				topslope = slope;
		}
		
		if (topslope <= bottomslope) {

			return false;		// stop				
		}
    }
    // passed the subsector ok

	

    return true;		
}


//
// P_CrossBSPNode
// Returns true
//  if strace crosses the given node successfully.
//
boolean P_CrossBSPNode (int32_t bspnum)
{
    node_t*	bsp;
    int8_t		side;
	node_t* nodes;
	
	if (bspnum & NF_SUBSECTOR) {
		if (bspnum == -1) {
			return P_CrossSubsector(0);
		} else {
			return P_CrossSubsector(bspnum&(~NF_SUBSECTOR));
		}
    }
		

	nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
	bsp = &nodes[bspnum];
    
    // decide which side the start point is on
    side = P_DivlineSideNode (strace.x.w, strace.y.w, bsp);
	if (side == 2) {
		side = 0;	// an "on" should cross both sides
	}
	nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
	bsp = &nodes[bspnum];

	if (!P_CrossBSPNode(bsp->children[side])) {
		return false;
	}

	nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
	bsp = &nodes[bspnum];

    // the partition plane is crossed here
    if (side == P_DivlineSideNode (cachedt2x, cachedt2y,bsp)) {
		// the line doesn't touch the other side
		return true;
    }
	nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
	bsp = &nodes[bspnum];

    // cross the ending side		
    return P_CrossBSPNode (bsp->children[side^1]);
}


//
// P_CheckSight
// Returns true
//  if a straight line between t1 and t2 is unobstructed.
// Uses REJECT.
//
boolean
P_CheckSight
( MEMREF t1Ref,
  MEMREF t2Ref)
{

    int32_t		pnum;
    int16_t		bytenum;
    int16_t		bitnum;
	mobj_t*	t1 = (mobj_t*)Z_LoadBytesFromEMS(t1Ref);
	fixed_t t1z = t1->z;
	fixed_t t1x = t1->x;
	fixed_t t1y = t1->y;
	fixed_t t1height = t1->height.w;
	int16_t s1 = t1->secnum;

	mobj_t*	t2;
		fixed_t t2z;
		fixed_t t2x;
		fixed_t t2y;
		fixed_t t2height;
		int16_t s2;

	 

	t2 = (mobj_t*)Z_LoadBytesFromEMS(t2Ref);
	t2z = t2->z;
	t2x = t2->x;
	t2y = t2->y;
	t2height = t2->height.w;
	s2 = t2->secnum;


	
    // First check for trivial rejection.

    // Determine subsector entries in REJECT table.
    // todo we can do this faster for 16 bite... shifts are slow, we want to avoid the 32 bit int too.
	// can be 330ish sectors in a level so pnum can surpass 16 bit sizes
	pnum = s1*numsectors + s2;
    bytenum = pnum>>3;
    bitnum = 1 << (pnum&7);
	

	

    // Check in REJECT table.
    if (((byte*) Z_LoadBytesFromEMS(rejectmatrixRef)) [bytenum]&bitnum) {

		// can't possibly be connected
		return false;	
    }

    // An unobstructed LOS is possible.
    // Now look from eyes of t1 to any part of t2.
    validcount++;
	
    sightzstart = t1z + t1height - (t1height>>2);
    topslope = (t2z+t2height) - sightzstart;
    bottomslope = (t2z) - sightzstart;
	
    strace.x.w = t1x;
    strace.y.w = t1y;
    cachedt2x = t2x;
	cachedt2y = t2y;
    strace.dx.w = t2x - t1x;
    strace.dy.w = t2y - t1y;

    // the head node is the last node output
    return P_CrossBSPNode (numnodes-1);	
}


