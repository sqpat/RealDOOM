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
#include "m_memory.h"
#include "m_near.h"

boolean __near P_CrossBSPNode (uint16_t bspnum);


//
// P_CheckSight
// Returns true
//  if a straight line between t1 and t2 is unobstructed.
// Uses REJECT.
//
boolean __far P_CheckSight (  mobj_t __near* t1, mobj_t __near* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos ) {

    fixed_t_union		pnum;
    uint16_t		bytenum;
    int16_t		bitnum;
	// this forces 32 bit operations down below 

	
    // First check for trivial rejection.

    // Determine subsector entries in REJECT table.
    // todo we can do this faster for 16 bite... shifts are slow, we want to avoid the 32 bit int too.
	// can be 330ish sectors in a level so pnum can surpass 16 bit sizes
	//pnum.wu = t1->secnum*result + t2->secnum;
    pnum.wu =  FastMul16u16u(t1->secnum,numsectors)+ t2->secnum;
    bytenum = pnum.wu>>3;
    bitnum = 1 << (pnum.h.fracbits&7);

	
    // Check in REJECT table.
	if (rejectmatrix[bytenum] & bitnum) {
		// can't possibly be connected
		return false;	
    }

    // An unobstructed LOS is possible.
    // Now look from eyes of t1 to any part of t2.
    validcount++;
	
    sightzstart = t1_pos->z.w + t1->height.w - (t1->height.w>>2);
    topslope = (t2_pos->z.w+t2->height.w) - sightzstart;
    bottomslope = (t2_pos->z.w) - sightzstart;
	
    strace.x = t1_pos->x;
    strace.y = t1_pos->y;
    cachedt2x = t2_pos->x;
	cachedt2y = t2_pos->y;
    strace.dx.w = t2_pos->x.w - t1_pos->x.w;
    strace.dy.w = t2_pos->y.w - t1_pos->y.w;

    // the head node is the last node output
	return P_CrossBSPNode (numnodes-1);
}



//
// P_DivlineSide
// Returns side 0 (front), 1 (back), or 2 (on).
//






int16_t __near P_DivlineSide ( fixed_t_union	x, fixed_t_union	y, divline_t __near*	node ) {
    fixed_t_union	dx;
	fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;

    if (!node->dx.w) {
		if (x.w==node->x.w){
			return 2;
		}
		
		if (x.w <= node->x.w){
			return node->dy.w > 0;
		}

		return node->dy.w < 0;
    }
    
    if (!node->dy.w) {
		if (x.w==node->y.w){
			return 2;
		}

		if (y.w <= node->y.w){
			return node->dx.w < 0;
		}

		return node->dx.w > 0;
    }
	
    dx.w = (x.w - node->x.w);
    dy.w = (y.w - node->y.w);
	
    left = FastMul1616(node->dy.h.intbits,dx.h.intbits);
    right = FastMul1616(dy.h.intbits,node->dx.h.intbits);
	
    if (right < left){
		return 0;	// front side
	}
    
    if (left == right){
		return 2;
	}

    return 1;		// back side
}

int16_t  __near P_DivlineSide16 ( int16_t	x, int16_t	y, divline_t __near*	node ) {
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
    fixed_t_union	temp;

	// NOTE: these divlines have proper 32 bit fixed_t

    if (!node->dx.w) {
		temp.w = node->x.w;
		if (x==temp.h.intbits){
			return 2;
		}
		
		if (x <= temp.h.intbits){
			return node->dy.w > 0;
		}

		return node->dy.w < 0;
    }
    
    if (!node->dy.w) {
		temp.w = node->y.w;
		if (x==temp.h.intbits){
			return 2;
		}

		if (y <= temp.h.intbits){
			return node->dx.w < 0;
		}

		return node->dx.w > 0;
    }
	
	temp.h.intbits = x;
	temp.h.fracbits = 0;

    dx.w = (temp.w - node->x.w);
	temp.h.intbits = y;
    dy.w = (temp.w - node->y.w);
	temp.w = node->dy.w;
    left =  FastMul1616(temp.h.intbits,dx.h.intbits);
	temp.w = node->dx.w;
    right = FastMul1616(dy.h.intbits,temp.h.intbits);
	
    if (right < left){
		return 0;	// front side
	}
    if (left == right){
		return 2;
	}
    return 1;		// back side
}

int16_t __near P_DivlineSideNode ( fixed_t_union	x, fixed_t_union	y, uint16_t nodenum ) {

	// NOTE: these nodes have proper 16 bit integer fields.

    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
    fixed_t_union	temp;
	node_t __far*	node = &nodes[nodenum];

    if (!node->dx) {
		temp.h.intbits = node->x;
		temp.h.fracbits = 0;

		if (x.w==temp.w){
			return 2;
		}
		
		if (x.w <= temp.w){
			return node->dy > 0;
		}

		return node->dy < 0;
    }
    
    if (!node->dy) {
		temp.h.intbits = node->y;
		temp.h.fracbits = 0;

		if (x.w==temp.w){
			return 2;
		}
		if (y.w <= temp.w){
			return node->dx < 0;
		}

		return node->dx > 0;
    }

	temp.h.intbits = node->x;
	temp.h.fracbits = 0;

    dx.w = (x.w - temp.w);
	temp.h.intbits = node->y;
    dy.w = (y.w - temp.w);

    left =  FastMul1616(node->dy, dx.h.intbits);
    right = FastMul1616(dy.h.intbits, node->dx);

	if (right < left){
		return 0;	// front side
	}
    
    if (left == right){
		return 2;
	}
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
( divline_t __near*	v2,
  node_t*	v1 ) {
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
	
    den = FixedMul2432 (tempdy.w,v2->dx) - FixedMul(tempdx.w,v2->dy);

    if (den == 0)
		return 0;
    
	tempx.h.intbits = v1->x;
	tempy.h.intbits = v1->y;
	tempx.h.fracbits = 0;
	tempy.h.fracbits = 0;

    num = FixedMul2432 ( (tempx.w - v2->x) ,tempdy.w) + 
	FixedMul2432 ( (v2->y - tempy.w) , v1->dx);
    frac = FixedDiv (num , den);

    return frac;
}

*/
fixed_t __near P_InterceptVector2 (divline_t __near* v2, divline_t __near*	v1 ) {
    fixed_t	frac;
    fixed_t	num;
    fixed_t	den;
	
    den = FixedMul2432 (v1->dy.w,v2->dx.w) - FixedMul2432(v1->dx.w,v2->dy.w);

    if (den == 0){
		return 0;
	}
    
    num = FixedMul2432 ( (v1->x.w - v2->x.w) ,v1->dy.w) + 
		  FixedMul2432 ( (v2->y.w - v1->y.w) , v1->dx.w);
    frac = FixedDiv (num , den);

    return frac;
}

// int32_t  bspcounter = 0;

//
// P_CrossSubsector
// Returns true
//  if strace crosses the given subsector successfully.
//
boolean __near P_CrossSubsector (uint16_t subsecnum) {
    int16_t		segnum;
	int16_t linedefOffset;
	line_t __far*		line;
	line_physics_t __far*		line_physics;
	int16_t			s1;
	int16_t			s2;
    int16_t			count;
    int16_t frontsecnum;
	int16_t backsecnum;
    short_height_t		opentop;
    short_height_t		openbottom;
    divline_t		divl;
    vertex_t		v1;
    vertex_t		v2;
    fixed_t		frac;
    fixed_t		slope;
	int16_t linev1Offset;
	int16_t linev2Offset;
	uint8_t lineflags;
	fixed_t_union temp;
	sector_t __far* frontsector_local;
	sector_t __far* backsector_local;
	int16_t curlineside;
 	temp.h.fracbits = 0;
    // check lines
    count = subsector_lines[subsecnum];
    segnum = subsectors[subsecnum].firstline;


    for ( ; count ; segnum++, count--) {
		linedefOffset = seg_linedefs[segnum];
		line_physics = &lines_physics[linedefOffset];


		// allready checked other side?
		// if (line->validcount == (validcount & 0xFF)) {
		

		if (line_physics->validcount == validcount ) {
			continue;
		}
		line = &lines[linedefOffset];
		lineflags = lineflagslist[linedefOffset];

		//line->validcount = (validcount & 0xFF);
		line_physics->validcount = validcount;
		linev1Offset = line_physics->v1Offset;
		linev2Offset = line_physics->v2Offset & VERTEX_OFFSET_MASK;

		v1 = vertexes[linev1Offset];
		v2 = vertexes[linev2Offset];
		s1 = P_DivlineSide16 (v1.x, v1.y, &strace);
		s2 = P_DivlineSide16 (v2.x, v2.y, &strace);

		// line isn't crossed?
		if (s1 == s2){
			continue;
		}
		
		divl.x.h.fracbits = 0;
		divl.y.h.fracbits = 0;
		divl.dx.h.fracbits = 0;
		divl.dy.h.fracbits = 0;
		
		divl.x.h.intbits = v1.x;
		divl.y.h.intbits = v1.y;
		divl.dx.h.intbits = v2.x - v1.x;
		divl.dy.h.intbits = v2.y - v1.y;

		s1 = P_DivlineSide(strace.x, strace.y, &divl);
		s2 = P_DivlineSide(cachedt2x, cachedt2y, &divl);

		 


		// line isn't crossed?
		if (s1 == s2){
			continue;
		}	
		

		// stop because it is not two sided anyway
		// might do this after updating validcount?
		if (!(lineflags & ML_TWOSIDED)) {

			return false;
		}
	
		// crosses a two sided line

		// no wall to block sight with?

		curlineside = seg_sides[segnum];
		frontsecnum = segs_physics[segnum].frontsecnum;
		backsecnum = segs_physics[segnum].backsecnum;

		/*
		curlineside = seg_sides[segnum];
		frontsecnum = sides[line->sidenum[curlineside]].secnum;
		backsecnum =
			line->flags & ML_TWOSIDED ?
			sides[line->sidenum[curlineside ^ 1]].secnum
			: SECNUM_NULL;
			*/
		frontsector_local = &sectors[frontsecnum];
		backsector_local = &sectors[backsecnum];

		if (frontsector_local->floorheight == backsector_local->floorheight && frontsector_local->ceilingheight == backsector_local->ceilingheight) {
			continue;
		}

		// possible occluder
		// because of ceiling height differences
		if (frontsector_local->ceilingheight < backsector_local->ceilingheight){
			opentop = frontsector_local->ceilingheight;
		} else {
			opentop = backsector_local->ceilingheight;
		}

		// because of ceiling height differences
		if (frontsector_local->floorheight > backsector_local->floorheight){
			openbottom = frontsector_local->floorheight;
		} else {
			openbottom = backsector_local->floorheight;
		}
		
		// quick test for totally closed doors
		if (openbottom >= opentop) {
			return false;		// stop
		}
	
		// todo pull this out? only use
		frac = P_InterceptVector2 (&strace, &divl);
		
		if (frontsector_local->floorheight != backsector_local->floorheight) {
		 	// temp.h.intbits = openbottom >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  openbottom);
			slope = FixedDiv (temp.w - sightzstart , frac);
			if (slope > bottomslope){
				bottomslope = slope;
			}
		}
		
		if (frontsector_local->ceilingheight != backsector_local->ceilingheight) {
		 	// temp.h.intbits = opentop >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  opentop);
			slope = FixedDiv (temp.w - sightzstart , frac);
			if (slope < topslope){
				topslope = slope;
			}
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
boolean __near P_CrossBSPNode (uint16_t bspnum) {
    int8_t		side;

	if (bspnum & NF_SUBSECTOR) {
		if (bspnum == 65535) { // -1 case. was thing for single sector maps?
			return P_CrossSubsector(0);
		} else {
			return P_CrossSubsector(bspnum&(~NF_SUBSECTOR));
		}
    }
		


	 
	side = P_DivlineSideNode (strace.x, strace.y, bspnum);
	side &= 0x01; // turn 0x02 case to 0x01
	if (!P_CrossBSPNode(node_children[bspnum].children[side])) {
		return false;
	}

    // the partition plane is crossed here
    if (side == P_DivlineSideNode (cachedt2x, cachedt2y,bspnum)) {
		// the line doesn't touch the other side
		return true;
    }
	//bsp = &nodes[bspnum];

    // cross the ending side		
    return P_CrossBSPNode (node_children[bspnum].children[side^1]);
}


