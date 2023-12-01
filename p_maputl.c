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
    dx = labs(dx);
    dy = labs(dy);
    if (dx < dy)
	return dx+dy-(dx>>1);
    return dx+dy-(dy>>1);
}


//
// P_PointOnLineSide
// Returns 0 or 1
//
boolean
P_PointOnLineSide
( fixed_t	x,
  fixed_t	y,
	int16_t linedx,
	int16_t linedy,
	int16_t linev1Offset)
{
    fixed_t	dx;
    fixed_t	dy;
    fixed_t	left;
    fixed_t	right;
	fixed_t_union temp;
	temp.h.fracbits = 0;
    if (!linedx) {
		temp.h.intbits = vertexes[linev1Offset].x;
		if (x <= temp.w) {
			return linedy > 0;
		}
		return linedy < 0;
    }
    if (!linedy) {
		temp.h.intbits = vertexes[linev1Offset].y;
		if (y <= temp.w) {
			return linedx < 0;
		}
	
		return linedx > 0;
    }
	
	temp.h.intbits = vertexes[linev1Offset].x;
    dx = (x - temp.w);
	temp.h.intbits = vertexes[linev1Offset].y;
    dy = (y - temp.w);
	
    left = FixedMul ( linedy , dx );
    right = FixedMul ( dy , linedx );
	
	if (right < left) {
		return 0;		// front side
	}

    return 1;	
}

/*
boolean
P_PointOnLineSide16
( 	int16_t	x,
  	int16_t	y,
	int16_t linedx,
	int16_t linedy,
	int16_t linev1Offset)
{
    int16_t	dx;
    int16_t	dy;
    fixed_t	left;
    fixed_t	right;

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

    dx = (x -  vertexes[linev1Offset].x);
    dy = (y -  vertexes[linev1Offset].x);
	
	// todo is a 16 bit mult ok...? test
    left = FixedMul ( linedy , dx );
    right = FixedMul ( dy , linedx );
	
	if (right < left) {
		return 0;		// front side
	}

    return 1;			// back side
}
*/

//
// P_BoxOnLineSide
// Considers the line to be infinite
// Returns side 0 or 1, -1 if box crosses the line.
//
boolean
P_BoxOnLineSide
( fixed_t_union*	tmbox,
	slopetype_t	lineslopetype,
	int16_t linedx,
	int16_t linedy,
	int16_t linev1Offset
	)
{


    boolean		p1;
    boolean		p2;
	fixed_t_union temp;
	temp.h.fracbits = 0;
    switch (lineslopetype) {
      case ST_HORIZONTAL_HIGH:
	  	temp.h.intbits = vertexes[linev1Offset].y;
		p1 = tmbox[BOXTOP].w > temp.w;
		p2 = tmbox[BOXBOTTOM].w > temp.w;
		if (linedx < 0) {
			p1 ^= 1;
			p2 ^= 1;
		}
		break;
	
      case ST_VERTICAL_HIGH:
	  	temp.h.intbits = vertexes[linev1Offset].x;
		p1 = tmbox[BOXRIGHT].w < temp.w;
		p2 = tmbox[BOXLEFT].w < temp.w;
		if (linedy < 0)
		{
			p1 ^= 1;
			p2 ^= 1;
		}
		break;
	
      case ST_POSITIVE_HIGH:
		p1 = P_PointOnLineSide (tmbox[BOXLEFT].w, tmbox[BOXTOP].w, linedx, linedy, linev1Offset);
		p2 = P_PointOnLineSide (tmbox[BOXRIGHT].w, tmbox[BOXBOTTOM].w, linedx, linedy, linev1Offset);
		break;
	
      case ST_NEGATIVE_HIGH:
		p1 = P_PointOnLineSide (tmbox[BOXRIGHT].w, tmbox[BOXTOP].w, linedx, linedy, linev1Offset);
		p2 = P_PointOnLineSide (tmbox[BOXLEFT].w, tmbox[BOXBOTTOM].w, linedx, linedy, linev1Offset);
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
boolean
P_PointOnDivlineSide
( fixed_t	x,
  fixed_t	y
   )
{
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
	divline_t*	line = &trace;
	
    if (!line->dx.w)
    {
	if (x <= line->x.w)
	    return line->dy.w > 0;
	
	return line->dy.w < 0;
    }
    if (!line->dy.w)
    {
	if (y <= line->y.w)
	    return line->dx.w < 0;

	return line->dx.w > 0;
    }
	
    dx.w = (x - line->x.w);
    dy.w = (y - line->y.w);
	
    // try to quickly decide by looking at sign bits
	
    if ( (line->dy.h.intbits ^ line->dx.h.intbits ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )
    {
	if ( (line->dy.h.intbits ^ dx.h.intbits) & 0x8000 )
	    return 1;		// (left is negative)
	return 0;
    }
	
	//todo is there a faster way to use just the 3 bytes?
    left = FixedMul ( line->dy.w >>8, dx.w>>8 );
    right = FixedMul ( dy.w>>8 , line->dx.w >>8 );
	
	return (right >= left);

	
}

/*
// TODO: FIX - sq
boolean
P_PointOnDivlineSide16
( int16_t	x,
  int16_t	y,
  divline_t*	line )
{
    fixed_t	dx;
    fixed_t	dy;
    fixed_t	left;
    fixed_t	right;
	fixed_t_union temp;
	
    if (!line->dx) {
		if (x <= line->x)
			return line->dy > 0;
		
		return line->dy < 0;
    }
    if (!line->dy) {
		if (y <= line->y)
			return line->dx < 0;

		return line->dx > 0;
    }
	
    dx = (x - line->x);
    dy = (y - line->y);
	
    // try to quickly decide by looking at sign bits
    if ( (line->dy ^ line->dx ^ dx ^ dy)&0x8000 ) {
	if ( (line->dy ^ dx) & 0x8000 )
	    return 1;		// (left is negative)
	return 0;
    }
	
    left = FixedMul ( line->dy, dx );
    right = FixedMul ( dy , line->dx );
	
    if (right < left)
		return 0;		// front side
    return 1;			// back side
}

*/

 



//
// P_InterceptVector
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings
// and addlines traversers.
//
fixed_t
P_InterceptVector
( 
  divline_t*	v1 )
{
    fixed_t	frac;
    fixed_t	num;
    fixed_t	den;
	divline_t*	v2 = &trace;
	
    den = FixedMul (v1->dy.w>>8,v2->dx.w) - FixedMul(v1->dx.w >>8,v2->dy.w);

    if (den == 0)
		return 0;
    
    num = FixedMul ( (v1->x.w - v2->x.w)>>8 ,v1->dy.w) + FixedMul ( (v2->y.w - v1->y.w)>>8, v1->dx.w);

    frac = FixedDiv (num , den);

    return frac;
 
}


//
// P_LineOpening
// Sets opentop and openbottom to the window
// through a two sided line.
// OPTIMIZE: keep this precalculated
//
lineopening_t lineopening;

#ifdef	PRECALCULATE_OPENINGS


void P_LoadLineOpening(int16_t linenum) {
	
	//recalc if cache dirty if necessary
	if (lineopenings[linenum].cachebits) {

		// we do the backsecnum check when setting bit dirty, so backsecnum always good
		int16_t linefrontsecnum = lines[linenum].frontsecnum;
		int16_t linebacksecnum = lines[linenum].backsecnum;

		sector_t* front = &sectors[linefrontsecnum];
		sector_t* back = &sectors[linebacksecnum];
	 


		if (lineopenings[linenum].cachebits & LO_CEILING_DIRTY_BIT) {
			if (front->ceilingheight < back->ceilingheight) {
				lineopenings[linenum].opentop = front->ceilingheight;
			}
			else {
				lineopenings[linenum].opentop = back->ceilingheight;
			}
		}
		if (lineopenings[linenum].cachebits & LO_FLOOR_DIRTY_BIT) {
			if (front->floorheight > back->floorheight) {
				lineopenings[linenum].openbottom = front->floorheight;
				lineopenings[linenum].lowfloor = back->floorheight;
			}
			else {
				lineopenings[linenum].openbottom = back->floorheight;
				lineopenings[linenum].lowfloor = front->floorheight;
			}
		}

		// this is used in two spots, we'll just calc ont he fly.
		//lineopenings[linenum].openrange = lineopenings[linenum].opentop - lineopenings[linenum].openbottom;

		lineopenings[linenum].cachebits = 0;
	}
	lineopening = lineopenings[linenum];
}

void P_UpdateLineOpening(int16_t secnum, boolean changedFloor) {
	int16_t max = sectors[secnum].linecount;
	int16_t i;
	sector_t* front;
	sector_t* back;

//	if (secnum > numsectors || secnum < 0) {
//		I_Error("bad secnum %i", secnum);
//	}
	//lineopening_t* lineopenings = Z_LoadBytesFromEMS(lineopeningsRef);
	
	for (i = 0; i < max; i++) {
		int16_t linenum = linebuffer[sectors[secnum].linesoffset + i];
		int16_t lineside1 = lines[linenum].sidenum[1];
		if (lineside1 == -1) {
			// single sided line
			continue;
		}

		lineopenings[linenum].cachebits |= 
				(changedFloor ? LO_FLOOR_DIRTY_BIT : LO_CEILING_DIRTY_BIT);



	}
}
#else

void P_LineOpening (int16_t lineside1, int16_t linefrontsecnum, int16_t linebacksecnum) {
	sector_t*	front;
    sector_t*	back;
    if (lineside1 == -1) {
		// single sided line
 		return;
	}

	
	front = &sectors[linefrontsecnum];
	back = &sectors[linebacksecnum];
	
	if (front->ceilingheight < back->ceilingheight) {
		lineopening.opentop = front->ceilingheight;
	} else {
		lineopening.opentop = back->ceilingheight;
	}
	if (front->floorheight > back->floorheight) {
		lineopening.openbottom = front->floorheight;
		lineopening.lowfloor = back->floorheight;
	} else {
		lineopening.openbottom = back->floorheight;
		lineopening.lowfloor = front->floorheight;
	}
	
 

}
#endif

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
void P_UnsetThingPosition (mobj_t* thing)
{
    int16_t		blockx;
    int16_t		blocky;
	mobj_t* changeThing;

	THINKERREF nextRef;
	THINKERREF thingsprevRef = thing->sprevRef;

	THINKERREF thingsnextRef = thing->snextRef;
	THINKERREF thingbnextRef = thing->bnextRef;
	fixed_t_union thingx;
	fixed_t_union thingy;
	int32_t thingflags = thing->flags;
	//int16_t thingsubsecnum = thing->subsecnum;
	int16_t thingsecnum = thing->secnum;
	THINKERREF thisRef = GETTHINKERREF(thing);
	thingx.w = thing->x;
	thingy.w = thing->y;
    
	if (!(thingflags & MF_NOSECTOR)) {
		// inert things don't need to be in blockmap?
		// unlink from subsector
		if (thingsnextRef) {
			changeThing = (mobj_t*)&thinkerlist[thingsnextRef].data;
			changeThing->sprevRef = thingsprevRef;
		}

		if (thingsprevRef) {
			changeThing = (mobj_t*)&thinkerlist[thingsprevRef].data;
			changeThing->snextRef = thingsnextRef;
		}
		else {
			sectors[thingsecnum].thinglistRef = thingsnextRef;
		}
	}

	/*
	if ( ! (thingflags & MF_NOSECTOR) ) {
	// inert things don't need to be in blockmap?
	// unlink from subsector

		nextRef = sectors[thingsecnum].thinglistRef;
		// if nextref check here?
		while (nextRef) {
			mobj_t* innerthing = &thinkerlist[nextRef].data;
			if (innerthing->snextRef == thisRef) {
				innerthing->snextRef = thingsnextRef;
				break;
			}
			nextRef = innerthing->snextRef;
		}

		// if it was not found in the block previously then...
		if (nextRef == NULL_THINKERREF) {
			sectors[thingsecnum].thinglistRef = thingsnextRef;
		}
    }
	*/
	


    if (! (thingflags & MF_NOBLOCKMAP) ) {
	// inert things don't need to be in blockmap
	// unlink from block map


		//todo how can this trip the < 0 check anyway?

		// should be faster for 16 bit than a shift right by 7?
		blockx = (thingx.h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
		blocky = (thingy.h.intbits - bmaporgy) >> MAPBLOCKSHIFT;
		/*		temp.h = (thingx.h.intbits - bmaporgx);
		blockx = temp.b.bytehigh << 1;
		blockx += temp.h & 0x0080 ? 1 : 0;*/
		/*			temp.h = (thingy.h.intbits - bmaporgy);
		blocky = temp.b.bytehigh << 1;
		blocky += temp.b.bytelow & 0x80 ? 1 : 0;*/

		if (blockx >= 0 && blockx < bmapwidth && blocky >= 0 && blocky < bmapheight){

			int16_t bindex = blocky * bmapwidth + blockx;
			nextRef = blocklinks[bindex];
			// if nextref check here?
			while (nextRef) {
				mobj_t* innerthing = &thinkerlist[nextRef].data;
				if (innerthing->bnextRef == thisRef) {
					innerthing->bnextRef = thingbnextRef;
					break;
				}
				nextRef = innerthing->bnextRef;
			}
			
			// if it was not found in the block previously then...
			if (nextRef == NULL_THINKERREF) {
				blocklinks[bindex] = thingbnextRef;
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
P_SetThingPosition (mobj_t* thing, int16_t knownsecnum)
{



	//sector_t*		sec;
    int16_t			blockx;
    int16_t			blocky;
	THINKERREF		linkRef;
	
	mobj_t* thingList;
	THINKERREF oldsectorthinglist;
	fixed_t_union temp;
	THINKERREF thingRef = GETTHINKERREF(thing);
	// link into subsector

	if (knownsecnum != -1) {
		thing->secnum = knownsecnum;

	}
	else {
		int16_t	subsecnum = R_PointInSubsector(thing->x, thing->y);;
		int16_t subsectorsecnum = subsectors[subsecnum].secnum;
		thing->secnum = subsectorsecnum;
	}


#ifdef CHECK_FOR_ERRORS
	if (thing->secnum < 0 || thing->secnum > numsectors) {
		I_Error("P_SetThingPosition: thing being set with bad secnum %i: numsectors:%i subsecnum %i num subsectors %i thingRef %i", subsectorsecnum, numsectors, subsecnum, numsubsectors, thingRef);
	}
#endif

	if (!(thing->flags & MF_NOSECTOR)) {
		// invisible things don't go into the sector links

		oldsectorthinglist = sectors[thing->secnum].thinglistRef;
		sectors[thing->secnum].thinglistRef = thingRef;


		thing = (mobj_t*)&thinkerlist[thingRef].data;


		thing->sprevRef = NULL_THINKERREF;
		thing->snextRef = oldsectorthinglist;

		if (thing->snextRef) {
			thingList = (mobj_t*)&thinkerlist[thing->snextRef].data; ;
			thingList->sprevRef = thingRef;
		}

	}


	/*
    if ( ! (thing->flags & MF_NOSECTOR) ) {
		// invisible things don't go into the sector links

		thing->snextRef = sectors[subsectorsecnum].thinglistRef;
		sectors[subsectorsecnum].thinglistRef = thingRef;
		 

    }*/



    // link into blockmap
    if ( ! (thing->flags & MF_NOBLOCKMAP) ) {
		// inert things don't need to be in blockmap		
		temp.w = thing->x;
		blockx = (temp.h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
		temp.w = thing->y;
		blocky = (temp.h.intbits - bmaporgy) >> MAPBLOCKSHIFT;
		
		if (blockx>=0 && blockx < bmapwidth && blocky>=0 && blocky < bmapheight) {
			int16_t bindex = blocky * bmapwidth + blockx;
			linkRef = blocklinks[bindex];
			thing->bnextRef = linkRef;
		 
			blocklinks[bindex] = thingRef;

		} else {
			// thing is off the map
			thing->bnextRef = NULL_THINKERREF;
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
( int16_t			x,
  int16_t			y,
  boolean(*func)(line_t*, int16_t) )
{
    int16_t			offset;
	int16_t			index;
    int16_t		list;
    line_t*		ld;
	int16_t *blockmaplump;
    if (x<0
	|| y<0
	|| x>=bmapwidth
	|| y>=bmapheight)
    {
	return true;
    }
    
    offset = y*bmapwidth+x;
	blockmaplump = (int16_t*)Z_LoadBytesFromEMS(blockmaplumpRef);
	offset = *(blockmaplump+4 + offset);
	
    for ( index = offset ; blockmaplump[index] != -1 ; index++) {

		list = blockmaplump[index];

		ld = &lines[list];

		//if (ld->validcount == (validcount & 0xFF)) {
		if (ld->validcount == validcount) {
			continue; 	// line has already been checked
		}
		ld->validcount = validcount;
		//ld->validcount = (validcount & 0xFF);
			
		if (!func(ld, list)) {
			return false;
		}
		blockmaplump = (int16_t*)Z_LoadBytesFromEMS(blockmaplumpRef);
    }


    return true;	// everything was checked
}


//
// P_BlockThingsIterator
//
boolean
P_BlockThingsIterator
( int16_t			x,
  int16_t			y,
  boolean(*func)(THINKERREF, mobj_t*) )
{
	THINKERREF mobjRef;
    mobj_t*		mobj;

    if ( x<0 || y<0 || x>=bmapwidth || y>=bmapheight) {
		return true;
	}
	 

	for (mobjRef = blocklinks[y*bmapwidth + x]; mobjRef; mobjRef = mobj->bnextRef) {
		// will this cause stuff to lose scope...?


		mobj = (mobj_t*)&thinkerlist[mobjRef].data;  

		if (!func(mobjRef, mobj)) {

			return false;
		}

		 
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
int32_t		ptflags;

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
PIT_AddLineIntercepts (line_t* ld, int16_t linenum)
{
    int16_t			s1;
    int16_t			s2;
    fixed_t		frac;
    divline_t		dl;
	
	int16_t linev1Offset = ld->v1Offset;
	int16_t linev2Offset = ld->v2Offset & VERTEX_OFFSET_MASK;
	int16_t linedx = ld->dx;
	int16_t linedy = ld->dy;
	int16_t linebacksecnum = ld->backsecnum;
	fixed_t_union tempx;
	fixed_t_union tempy;
	fixed_t_union temp;

	tempx.h.fracbits = 0;
	tempy.h.fracbits = 0;

    // avoid precision problems with two routines
	if ( trace.dx.h.intbits > 16 || trace.dy.h.intbits > 16 || trace.dx.h.intbits < -16 || trace.dy.h.intbits < -16) {
		// we actually know the vertex fields to be 16 bit, but trace has 32 bit fields
		tempx.h.intbits = vertexes[linev1Offset].x;
		tempy.h.intbits = vertexes[linev1Offset].y;
		s1 = P_PointOnDivlineSide (tempx.w, tempy.w);
		tempx.h.intbits = vertexes[linev2Offset].x;
		tempy.h.intbits = vertexes[linev2Offset].y;
		s2 = P_PointOnDivlineSide(tempx.w, tempy.w);
	} else {
		s1 = P_PointOnLineSide (trace.x.w, trace.y.w, linedx, linedy, linev1Offset);
		s2 = P_PointOnLineSide (trace.x.w+trace.dx.w, trace.y.w+trace.dy.w, linedx, linedy, linev1Offset);
    }
    
	if (s1 == s2) {
		return true;	// line isn't crossed
	}
    
    // hit the line
    //P_MakeDivline(linedx, linedy, linev1Offset, &dl);

	temp.h.fracbits = 0;
	temp.h.intbits = vertexes[linev1Offset].x;
	dl.x = temp;
	temp.h.intbits = vertexes[linev1Offset].y;
	dl.y = temp;

	temp.h.intbits = linedx;
	dl.dx.w = temp.w;
	temp.h.intbits = linedy;
	dl.dy.w = temp.w;


    frac = P_InterceptVector (&dl);

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
boolean PIT_AddThingIntercepts (THINKERREF thingRef, mobj_t* thing)
{
    fixed_t		x1;
    fixed_t		y1;
    fixed_t		x2;
    fixed_t		y2;
    
    int16_t			s1;
    int16_t			s2;
    
    boolean		tracepositive;

    divline_t		dl;
    
    fixed_t		frac;
	
	fixed_t_union temp;
 
	tracepositive = (trace.dx.w ^ trace.dy.w) > 0;

	temp.h.fracbits = 0;
	temp.h.intbits = thing->radius;
	if (tracepositive)
	{
		x1 = thing->x - temp.w;
		y1 = thing->y + temp.w;

		x2 = thing->x + temp.w;
		y2 = thing->y - temp.w;
	}
	else
	{
		x1 = thing->x - temp.w;
		y1 = thing->y - temp.w;

		x2 = thing->x + temp.w;
		y2 = thing->y + temp.w;
	}
	s1 = P_PointOnDivlineSide (x1, y1);
    s2 = P_PointOnDivlineSide (x2, y2);

	if (s1 == s2) {
		return true;		// line isn't crossed
	}

    dl.x.w = x1;
    dl.y.w = y1;
    dl.dx.w = x2-x1;
    dl.dy.w = y2-y1;
    
    frac = P_InterceptVector (&dl);

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

// todo: only called once, pull out the func argument or inline?
void
P_TraverseIntercepts
( traverser_t	func
   )
{
    int16_t			count;
    fixed_t		dist;
    intercept_t*	scan;
    intercept_t*	in = NULL;
	fixed_t maxfrac = FRACUNIT;
	int16_t i = 0;
	count = intercept_p - intercepts;
 
	 


    while (count--) {
		i++;
		dist = MAXLONG;
		for (scan = intercepts ; scan<intercept_p ; scan++) {
			if (scan->frac < dist) {
				dist = scan->frac;
				in = scan;
			}
		}

		   
		if (dist > maxfrac) {
			return;	// checked everything in range		
		}

		if (!func(in)) {
			return;	// don't bother going farther
		}

		in->frac = MAXLONG;
    }


}




//
// P_PathTraverse
// Traces a line from x1,y1 to x2,y2,
// calling the traverser function for each.
// Returns true if the traverser function returns true
// for all lines.
//
void
P_PathTraverse
( fixed_t_union		x1,
  fixed_t_union		y1,
	fixed_t_union		x2,
	fixed_t_union		y2,
  uint8_t			flags,
  boolean (*trav) (intercept_t *))
{
    int16_t	xt1;
    int16_t	yt1;
    int16_t	xt2;
    int16_t	yt2;
    
    fixed_t	xstep;
    fixed_t	ystep;
    
    fixed_t	partial;
    
	fixed_t_union	xintercept;
    fixed_t_union	yintercept;
    
    int16_t		mapx;
    int16_t		mapy;
    
    int8_t		mapxstep;
    int8_t		mapystep;

    int8_t		count;
	fixed_t_union temp;

    earlyout = flags & PT_EARLYOUT;
	
    validcount++;
    intercept_p = intercepts;
 
	temp.h.intbits = bmaporgx;
	temp.h.fracbits = 0;


    if ( ((x1.w - temp.w)&((MAPBLOCKSIZE*1000L) -1)) == 0)
		x1.h.intbits += 1;	// don't side exactly on a line
    
	temp.h.intbits = bmaporgy;
	if ( ((y1.w -temp.w)&((MAPBLOCKSIZE * 1000L) -1)) == 0)
		y1.h.intbits += 1;	// don't side exactly on a line

    trace.x = x1;
    trace.y = y1;
    trace.dx.w = x2.w - x1.w;
    trace.dy.w = y2.w - y1.w;
	
    x1.h.intbits -= bmaporgx;
    y1.h.intbits -= bmaporgy;
    xt1 = x1.h.intbits>> MAPBLOCKSHIFT;
    yt1 = y1.h.intbits >> MAPBLOCKSHIFT;

    x2.h.intbits -= bmaporgx;
    y2.h.intbits -= bmaporgy;
    xt2 = x2.h.intbits >> MAPBLOCKSHIFT;
    yt2 = y2.h.intbits >>MAPBLOCKSHIFT;
 
    if (xt2 > xt1) {
		mapxstep = 1;
		partial = FRACUNIT - ((x1.w>> MAPBLOCKSHIFT)&(0xFFFF));
		ystep = FixedDiv (y2.w-y1.w,labs(x2.w-x1.w));
    } else if (xt2 < xt1) {
		mapxstep = -1;
		partial = (x1.w>> MAPBLOCKSHIFT)&(0xFFFF);
		ystep = FixedDiv (y2.w-y1.w,labs(x2.w-x1.w));
    } else {
		mapxstep = 0;
		partial = FRACUNIT;
		ystep = 256*FRACUNIT;
    }	

    yintercept.w = (y1.w>> MAPBLOCKSHIFT) + FixedMul (partial, ystep);

	
    if (yt2 > yt1) {
		mapystep = 1;
		partial = FRACUNIT - ((y1.w>> MAPBLOCKSHIFT)&(0xFFFF));
		xstep = FixedDiv (x2.w -x1.w,labs(y2.w -y1.w));
    } else if (yt2 < yt1) {
		mapystep = -1;
		partial = (y1.w >> MAPBLOCKSHIFT)&(0xFFFF);
		xstep = FixedDiv (x2.w -x1.w,labs(y2.w -y1.w));
    } else {
		mapystep = 0;
		partial = FRACUNIT;
		xstep = 256*FRACUNIT;
    }	
    xintercept.w = (x1.w >> MAPBLOCKSHIFT) + FixedMul (partial, xstep);

    // Step through map blocks.
    // Count is present to prevent a round off error
    // from skipping the break.
    mapx = xt1;
    mapy = yt1;

	for (count = 0 ; count < 64 ; count++) {
		if (flags & PT_ADDLINES) {
			if (!P_BlockLinesIterator (mapx, mapy,PIT_AddLineIntercepts))
				return;	// early out
		}

		if (flags & PT_ADDTHINGS) {
			if (!P_BlockThingsIterator (mapx, mapy,PIT_AddThingIntercepts))
				return;	// early out
		}
			
		if (mapx == xt2 && mapy == yt2) {
			break;
		}
		
		if ( (yintercept.h.intbits) == mapy) {
			yintercept.w += ystep;
			mapx += mapxstep;
		} else if ( (xintercept.h.intbits) == mapx) {
			xintercept.w += xstep;
			mapy += mapystep;
		}
			
	}

	// go through the sorted list
	// todo inline this only used in one spot
	 P_TraverseIntercepts ( trav);



}



