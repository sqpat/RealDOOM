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
//	Movement/collision utility functions,
//	as used by function in p_map.c. 
//	BLOCKMAP Iterator functions,
//	and some PIT_* functions to use for iteration.
//


#include <stdlib.h>


#include "m_misc.h"

#include "doomdef.h"
#include "p_local.h"

#include "i_system.h"
#include "doomstat.h"
// State.
#include "r_state.h"
#include "p_setup.h"

//
// P_AproxDistance
// Gives an estimation of distance (not exact)
//

fixed_t
P_AproxDistance
( fixed_t	dx,
  fixed_t	dy )
{
    dx = abs(dx);
    dy = abs(dy);
    if (dx < dy)
	return dx+dy-(dx>>1);
    return dx+dy-(dy>>1);
}


//
// P_PointOnLineSide
// Returns 0 or 1
//
int
P_PointOnLineSide
( fixed_t	x,
  fixed_t	y,
	fixed_t linedx,
	fixed_t linedy,
	short linev1Offset)
{
    fixed_t	dx;
    fixed_t	dy;
    fixed_t	left;
    fixed_t	right;
	vertex_t* vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

    if (!linedx) {
		if (x <= vertexes[linev1Offset].x) {
			return linedy > 0;
		}
		return linedy < 0;
    }
    if (!linedy) {
		if (y <= vertexes[linev1Offset].y) {
			return linedx < 0;
		}
	
		return linedx > 0;
    }
	
    dx = (x - vertexes[linev1Offset].x);
    dy = (y - vertexes[linev1Offset].y);
	
    left = FixedMul ( linedy>>FRACBITS , dx );
    right = FixedMul ( dy , linedx>>FRACBITS );
	
	if (right < left) {
		return 0;		// front side
	}

    return 1;			// back side
}



//
// P_BoxOnLineSide
// Considers the line to be infinite
// Returns side 0 or 1, -1 if box crosses the line.
//
int
P_BoxOnLineSide
( fixed_t*	tmbox,
	slopetype_t	lineslopetype,
	fixed_t linedx,
	fixed_t linedy,
	short linev1Offset
	)
{
    int		p1;
    int		p2;
	vertex_t* vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

    switch (lineslopetype)
    {
      case ST_HORIZONTAL:
	p1 = tmbox[BOXTOP] > vertexes[linev1Offset].y;
	p2 = tmbox[BOXBOTTOM] > vertexes[linev1Offset].y;
	if (linedx < 0) {
	    p1 ^= 1;
	    p2 ^= 1;
	}
	break;
	
      case ST_VERTICAL:
	p1 = tmbox[BOXRIGHT] < vertexes[linev1Offset].x;
	p2 = tmbox[BOXLEFT] < vertexes[linev1Offset].x;
	if (linedy < 0)
	{
	    p1 ^= 1;
	    p2 ^= 1;
	}
	break;
	
      case ST_POSITIVE:
	p1 = P_PointOnLineSide (tmbox[BOXLEFT], tmbox[BOXTOP], linedx, linedy, linev1Offset);
	p2 = P_PointOnLineSide (tmbox[BOXRIGHT], tmbox[BOXBOTTOM], linedx, linedy, linev1Offset);
	break;
	
      case ST_NEGATIVE:
	p1 = P_PointOnLineSide (tmbox[BOXRIGHT], tmbox[BOXTOP], linedx, linedy, linev1Offset);
	p2 = P_PointOnLineSide (tmbox[BOXLEFT], tmbox[BOXBOTTOM], linedx, linedy, linev1Offset);
	break;
    }

    if (p1 == p2)
	return p1;
    return -1;
}


//
// P_PointOnDivlineSide
// Returns 0 or 1.
//
int
P_PointOnDivlineSide
( fixed_t	x,
  fixed_t	y,
  divline_t*	line )
{
    fixed_t	dx;
    fixed_t	dy;
    fixed_t	left;
    fixed_t	right;
	
    if (!line->dx)
    {
	if (x <= line->x)
	    return line->dy > 0;
	
	return line->dy < 0;
    }
    if (!line->dy)
    {
	if (y <= line->y)
	    return line->dx < 0;

	return line->dx > 0;
    }
	
    dx = (x - line->x);
    dy = (y - line->y);
	
    // try to quickly decide by looking at sign bits
    if ( (line->dy ^ line->dx ^ dx ^ dy)&0x80000000 )
    {
	if ( (line->dy ^ dx) & 0x80000000 )
	    return 1;		// (left is negative)
	return 0;
    }
	
    left = FixedMul ( line->dy>>8, dx>>8 );
    right = FixedMul ( dy>>8 , line->dx>>8 );
	
    if (right < left)
	return 0;		// front side
    return 1;			// back side
}



//
// P_MakeDivline
//
void
P_MakeDivline
(fixed_t linedx,
	fixed_t linedy,
	short linev1Offset,
  divline_t*	dl )
{
	vertex_t* vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
	dl->x = vertexes[linev1Offset].x;
    dl->y = vertexes[linev1Offset].y;
    dl->dx = linedx;
    dl->dy = linedy;
}



//
// P_InterceptVector
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings
// and addlines traversers.
//
fixed_t
P_InterceptVector
( divline_t*	v2,
  divline_t*	v1 )
{
    fixed_t	frac;
    fixed_t	num;
    fixed_t	den;
	
    den = FixedMul (v1->dy>>8,v2->dx) - FixedMul(v1->dx>>8,v2->dy);

    if (den == 0)
	return 0;
    //	I_Error ("P_InterceptVector: parallel");
    
    num = FixedMul ( (v1->x - v2->x)>>8 ,v1->dy ) + FixedMul ( (v2->y - v1->y)>>8, v1->dx );

    frac = FixedDiv (num , den);

    return frac;
 
}


//
// P_LineOpening
// Sets opentop and openbottom to the window
// through a two sided line.
// OPTIMIZE: keep this precalculated
//
fixed_t opentop;
fixed_t openbottom;
fixed_t openrange;
fixed_t	lowfloor;


void P_LineOpening (short lineside1, short linefrontsecnum, short linebacksecnum) {
    sector_t*	front;
    sector_t*	back;
	sector_t*   sectors;
    if (lineside1 == -1) {
		// single sided line
		openrange = 0;
		return;
	}

	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	
	front = &sectors[linefrontsecnum];
	back = &sectors[linebacksecnum];
	
	if (front->ceilingheight < back->ceilingheight) {
		opentop = front->ceilingheight;
	} else {
		opentop = back->ceilingheight;
	}
	if (front->floorheight > back->floorheight) {
		openbottom = front->floorheight;
		lowfloor = back->floorheight;
	} else {
		openbottom = back->floorheight;
		lowfloor = front->floorheight;
	}
	
    openrange = opentop - openbottom;

	if (setval == 3) {
		// 22, 23
		I_Error("blah %i %i %i %i", front->ceilingheight, front->floorheight, back->ceilingheight, back->floorheight >> FRACBITS);
	}


}


//
// THING POSITION SETTING
//


//
// P_UnsetThingPosition
// Unlinks a thing from block map and sectors.
// On each position change, BLOCKMAP and other
// lookups maintaining lists ot things inside
// these structures need to be updated.
//
void P_UnsetThingPosition (MEMREF thingRef)
{
    int		blockx;
    int		blocky;
	//MEMREF* blocklinksList;
	mobj_t* changeThing;
	mobj_t* thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);
	MEMREF thingsprevRef = thing->sprevRef;
	MEMREF thingsnextRef = thing->snextRef;
	MEMREF thingbprevRef = thing->bprevRef;
	MEMREF thingbnextRef = thing->bnextRef;
	fixed_t thingx = thing->x;
	fixed_t thingy = thing->y;
	int thingflags = thing->flags;
	//short thingsubsecnum = thing->subsecnum;
	short thingsecnum = thing->secnum;
	sector_t* sectors;

    if ( ! (thingflags & MF_NOSECTOR) ) {
	// inert things don't need to be in blockmap?
	// unlink from subsector
		if (thingsnextRef) {
			changeThing = (mobj_t*)Z_LoadBytesFromEMS(thingsnextRef);
			changeThing->sprevRef = thingsprevRef;
		}
		
		if (thingsprevRef) {
			changeThing = (mobj_t*)Z_LoadBytesFromEMS(thingsprevRef);
			changeThing->snextRef = thingsnextRef;
		}
		else {
			sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
			sectors[thingsecnum].thinglistRef = thingsnextRef;
			 

		}
    }

	


    if ( ! (thingflags & MF_NOBLOCKMAP) ) {
	// inert things don't need to be in blockmap
	// unlink from block map
		if (thingbnextRef) {
			changeThing = (mobj_t*)Z_LoadBytesFromEMS(thingbnextRef);
			changeThing->bprevRef = thingbprevRef;
		}
	
		if (thingbprevRef) {
			changeThing = (mobj_t*)Z_LoadBytesFromEMS(thingbprevRef);
			changeThing->bnextRef = thingbnextRef;
		} else {
			blockx = (thingx - bmaporgx)>>MAPBLOCKSHIFT;
			blocky = (thingy - bmaporgy)>>MAPBLOCKSHIFT;

			if (blockx>=0 && blockx < bmapwidth && blocky>=0 && blocky <bmapheight) {
				//blocklinksList = (MEMREF*) Z_LoadBytesFromEMS(blocklinksRef);
				blocklinks[blocky*bmapwidth+blockx] = thingbnextRef;
			}
		}
    }
}


//
// P_SetThingPosition
// Links a thing into both a block and a subsector
// based on it's x y.
// Sets thing->subsector properly
//
void
P_SetThingPosition (MEMREF thingRef)
{
	short	subsecnum;
    //sector_t*		sec;
    int			blockx;
    int			blocky;
    MEMREF		linkRef;
	mobj_t*		link;
	mobj_t* thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);
	mobj_t* thingList;
	short subsectorsecnum;
	subsector_t* subsectors;
	sector_t* sectors;
	MEMREF oldsectorthinglist;
//	MEMREF* blocklinksList;

    // link into subsector
    subsecnum = R_PointInSubsector (thing->x,thing->y);

	subsectors = (subsector_t*) Z_LoadBytesFromEMS(subsectorsRef);
	subsectorsecnum = subsectors[subsecnum].secnum;
	thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);
	thing->secnum = subsectorsecnum;

	if (thing->secnum < 0 || thing->secnum > numsectors) {
		I_Error("P_SetThingPosition: thing being set with bad secnum %i: numsectors:%i subsecnum %i num subsectors %i thingRef %i", subsectorsecnum, numsectors, subsecnum, numsubsectors, thingRef);
	}

    if ( ! (thing->flags & MF_NOSECTOR) ) {
		// invisible things don't go into the sector links

		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		oldsectorthinglist = sectors[subsectorsecnum].thinglistRef;
		sectors[subsectorsecnum].thinglistRef = thingRef;

		thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);


		thing->sprevRef = NULL_MEMREF;
		thing->snextRef = oldsectorthinglist;

		if (thing->snextRef) {
			thingList = (mobj_t*)Z_LoadBytesFromEMS(thing->snextRef);
			thingList->sprevRef = thingRef;
		}

    }


	thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);
    
    // link into blockmap
    if ( ! (thing->flags & MF_NOBLOCKMAP) ) {
		// inert things don't need to be in blockmap		
		blockx = (thing->x - bmaporgx)>>MAPBLOCKSHIFT;
		blocky = (thing->y - bmaporgy)>>MAPBLOCKSHIFT;

		if (blockx>=0 && blockx < bmapwidth && blocky>=0 && blocky < bmapheight) {
			//blocklinksList = (MEMREF*)Z_LoadBytesFromEMS(blocklinksRef);
			linkRef = blocklinks[blocky*bmapwidth+blockx];
			thing->bprevRef = NULL_MEMREF;
			thing->bnextRef = linkRef;
			if (linkRef) {
				link = (mobj_t*)Z_LoadBytesFromEMS(linkRef);
				link->bprevRef = thingRef;
			}
			
			//*link = thing;
			// todo is this right?
			blocklinks[blocky*bmapwidth + blockx] = thingRef;

		} else {
			// thing is off the map
			thing->bnextRef = thing->bprevRef = NULL_MEMREF;
		}
    }
}



//
// BLOCK MAP ITERATORS
// For each line/thing in the given mapblock,
// call the passed PIT_* function.
// If the function returns false,
// exit with false without checking anything else.
//


//
// P_BlockLinesIterator
// The validcount flags are used to avoid checking lines
// that are marked in multiple mapblocks,
// so increment validcount before the first call
// to P_BlockLinesIterator, then make one or more calls
// to it.
//
boolean
P_BlockLinesIterator
( int			x,
  int			y,
  boolean(*func)(short) )
{
    int			offset;
	int			index;
    short		list;
    line_t*		ld;
	line_t* lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
	short *blockmaplump;
    if (x<0
	|| y<0
	|| x>=bmapwidth
	|| y>=bmapheight)
    {
	return true;
    }
    
    offset = y*bmapwidth+x;
	blockmaplump = (short*)Z_LoadBytesFromEMS(blockmaplumpRef);
	offset = *(blockmaplump+blockmapOffset + offset);
	
    for ( index = offset ; blockmaplump[index] != -1 ; index++) {

		list = blockmaplump[index];
		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

		ld = &lines[list];

		if (ld->validcount == validcount) {
			blockmaplump = (short*)Z_LoadBytesFromEMS(blockmaplumpRef);
			continue; 	// line has already been checked
		}
		ld->validcount = validcount;
			
		if (!func(list)) {
			return false;
		}
		blockmaplump = (short*)Z_LoadBytesFromEMS(blockmaplumpRef);
    }


    return true;	// everything was checked
}


//
// P_BlockThingsIterator
//
boolean
P_BlockThingsIterator
( int			x,
  int			y,
  boolean(*func)(MEMREF) )
{
	MEMREF mobjRef;
    mobj_t*		mobj;
	int i = 0;
    if ( x<0 || y<0 || x>=bmapwidth || y>=bmapheight) {
		return true;
	}
	 

	for (mobjRef = blocklinks[y*bmapwidth + x]; mobjRef; mobjRef = mobj->bnextRef) {
		// will this cause stuff to lose scope...?
		i++;


		if (i > NUM_BLOCKLINKS) {
			I_Error("block things caught infinite? %i ", gametic);
		}


		if (!func(mobjRef)) {
			 
			return false;
		}

		mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef); // necessary for bnextref...
		 
	} 

	return true;
}



//
// INTERCEPT ROUTINES
//
intercept_t	intercepts[MAXINTERCEPTS];
intercept_t*	intercept_p;

divline_t 	trace;
boolean 	earlyout;
int		ptflags;

//
// PIT_AddLineIntercepts.
// Looks for lines in the given block
// that intercept the given trace
// to add to the intercepts list.
//
// A line is crossed if its endpoints
// are on opposite sides of the trace.
// Returns true if earlyout and a solid line hit.
//
boolean
PIT_AddLineIntercepts (short linenum)
{
    int			s1;
    int			s2;
    fixed_t		frac;
    divline_t		dl;
	line_t* lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
	line_t* ld = &lines[linenum];
	short linev1Offset = ld->v1Offset;
	short linev2Offset = ld->v2Offset;
	fixed_t linedx = ld->dx;
	fixed_t linedy = ld->dy;
	short linebacksecnum = ld->backsecnum;



	vertex_t* vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

    // avoid precision problems with two routines
    if ( trace.dx > FRACUNIT*16 || trace.dy > FRACUNIT*16 || trace.dx < -FRACUNIT*16 || trace.dy < -FRACUNIT*16) {
		s1 = P_PointOnDivlineSide (vertexes[linev1Offset].x, vertexes[linev1Offset].y, &trace);
		s2 = P_PointOnDivlineSide (vertexes[linev2Offset].x, vertexes[linev2Offset].y, &trace);
    } else {
		s1 = P_PointOnLineSide (trace.x, trace.y, linedx, linedy, linev1Offset);
		s2 = P_PointOnLineSide (trace.x+trace.dx, trace.y+trace.dy, linedx, linedy, linev1Offset);
    }
    
    if (s1 == s2)
		return true;	// line isn't crossed
    
    // hit the line
    P_MakeDivline(linedx, linedy, linev1Offset, &dl);
    frac = P_InterceptVector (&trace, &dl);

	if (frac < 0) {
		return true;	// behind source
	}

    // try to early out the check
    if (earlyout && frac < FRACUNIT && linebacksecnum == SECNUM_NULL) {
		return false;	// stop checking
    }
    
	
    intercept_p->frac = frac;
    intercept_p->isaline = true;
    intercept_p->d.linenum = linenum;
    intercept_p++;

    return true;	// continue
}



//
// PIT_AddThingIntercepts
//
boolean PIT_AddThingIntercepts (MEMREF thingRef)
{
    fixed_t		x1;
    fixed_t		y1;
    fixed_t		x2;
    fixed_t		y2;
    
    int			s1;
    int			s2;
    
    boolean		tracepositive;

    divline_t		dl;
    
    fixed_t		frac;
	mobj_t* thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);

	
    tracepositive = (trace.dx ^ trace.dy)>0;
		
    // check a corner to corner crossection for hit
    if (tracepositive)
    {
	x1 = thing->x - thing->radius;
	y1 = thing->y + thing->radius;
		
	x2 = thing->x + thing->radius;
	y2 = thing->y - thing->radius;			
    }
    else
    {
	x1 = thing->x - thing->radius;
	y1 = thing->y - thing->radius;
		
	x2 = thing->x + thing->radius;
	y2 = thing->y + thing->radius;			
    }
    
    s1 = P_PointOnDivlineSide (x1, y1, &trace);
    s2 = P_PointOnDivlineSide (x2, y2, &trace);

	if (s1 == s2) {
		return true;		// line isn't crossed
	}

    dl.x = x1;
    dl.y = y1;
    dl.dx = x2-x1;
    dl.dy = y2-y1;
    
    frac = P_InterceptVector (&trace, &dl);

	if (frac < 0) {
		return true;		// behind source
	}

    intercept_p->frac = frac;
    intercept_p->isaline = false;
    intercept_p->d.thingRef = thingRef;
    intercept_p++;

    return true;		// keep going
}


//
// P_TraverseIntercepts
// Returns true if the traverser function returns true
// for all lines.
// 
boolean
P_TraverseIntercepts
( traverser_t	func,
  fixed_t	maxfrac )
{
    int			count;
    fixed_t		dist;
    intercept_t*	scan;
    intercept_t*	in;
	
    count = intercept_p - intercepts;
    
    in = 0;			// shut up compiler warning
	
    while (count--)
    {
	dist = MAXINT;
	for (scan = intercepts ; scan<intercept_p ; scan++)
	{
	    if (scan->frac < dist)
	    {
		dist = scan->frac;
		in = scan;
	    }
	}
	
	if (dist > maxfrac)
	    return true;	// checked everything in range		
	 

     if ( !func (in) )
	    return false;	// don't bother going farther

	in->frac = MAXINT;
    }
	
    return true;		// everything was traversed
}




//
// P_PathTraverse
// Traces a line from x1,y1 to x2,y2,
// calling the traverser function for each.
// Returns true if the traverser function returns true
// for all lines.
//
boolean
P_PathTraverse
( fixed_t		x1,
  fixed_t		y1,
  fixed_t		x2,
  fixed_t		y2,
  int			flags,
  boolean (*trav) (intercept_t *))
{
    fixed_t	xt1;
    fixed_t	yt1;
    fixed_t	xt2;
    fixed_t	yt2;
    
    fixed_t	xstep;
    fixed_t	ystep;
    
    fixed_t	partial;
    
    fixed_t	xintercept;
    fixed_t	yintercept;
    
    int		mapx;
    int		mapy;
    
    int		mapxstep;
    int		mapystep;

    int		count;
		
    earlyout = flags & PT_EARLYOUT;
	
    validcount++;
    intercept_p = intercepts;
	
    if ( ((x1-bmaporgx)&(MAPBLOCKSIZE-1)) == 0)
	x1 += FRACUNIT;	// don't side exactly on a line
    
    if ( ((y1-bmaporgy)&(MAPBLOCKSIZE-1)) == 0)
	y1 += FRACUNIT;	// don't side exactly on a line

    trace.x = x1;
    trace.y = y1;
    trace.dx = x2 - x1;
    trace.dy = y2 - y1;

    x1 -= bmaporgx;
    y1 -= bmaporgy;
    xt1 = x1>>MAPBLOCKSHIFT;
    yt1 = y1>>MAPBLOCKSHIFT;

    x2 -= bmaporgx;
    y2 -= bmaporgy;
    xt2 = x2>>MAPBLOCKSHIFT;
    yt2 = y2>>MAPBLOCKSHIFT;

    if (xt2 > xt1)
    {
	mapxstep = 1;
	partial = FRACUNIT - ((x1>>MAPBTOFRAC)&(FRACUNIT-1));
	ystep = FixedDiv (y2-y1,abs(x2-x1));
    }
    else if (xt2 < xt1)
    {
	mapxstep = -1;
	partial = (x1>>MAPBTOFRAC)&(FRACUNIT-1);
	ystep = FixedDiv (y2-y1,abs(x2-x1));
    }
    else
    {
	mapxstep = 0;
	partial = FRACUNIT;
	ystep = 256*FRACUNIT;
    }	

    yintercept = (y1>>MAPBTOFRAC) + FixedMul (partial, ystep);

	
    if (yt2 > yt1)
    {
	mapystep = 1;
	partial = FRACUNIT - ((y1>>MAPBTOFRAC)&(FRACUNIT-1));
	xstep = FixedDiv (x2-x1,abs(y2-y1));
    }
    else if (yt2 < yt1)
    {
	mapystep = -1;
	partial = (y1>>MAPBTOFRAC)&(FRACUNIT-1);
	xstep = FixedDiv (x2-x1,abs(y2-y1));
    }
    else
    {
	mapystep = 0;
	partial = FRACUNIT;
	xstep = 256*FRACUNIT;
    }	
    xintercept = (x1>>MAPBTOFRAC) + FixedMul (partial, xstep);
    
    // Step through map blocks.
    // Count is present to prevent a round off error
    // from skipping the break.
    mapx = xt1;
    mapy = yt1;
    for (count = 0 ; count < 64 ; count++)
    {
	if (flags & PT_ADDLINES)
	{
	    if (!P_BlockLinesIterator (mapx, mapy,PIT_AddLineIntercepts))
			return false;	// early out
	}
	
	if (flags & PT_ADDTHINGS)
	{

		if (!P_BlockThingsIterator (mapx, mapy,PIT_AddThingIntercepts))
			return false;	// early out
	}
		
	if (mapx == xt2
	    && mapy == yt2)
	{
	    break;
	}
	
	if ( (yintercept >> FRACBITS) == mapy)
	{
	    yintercept += ystep;
	    mapx += mapxstep;
	}
	else if ( (xintercept >> FRACBITS) == mapx)
	{
	    xintercept += xstep;
	    mapy += mapystep;
	}
		
    }
    // go through the sorted list
    return P_TraverseIntercepts ( trav, FRACUNIT );
}



