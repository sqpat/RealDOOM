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
#include "m_memory.h"

//
// P_AproxDistance
// Gives an estimation of distance (not exact)
//

fixed_t
__near P_AproxDistance
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
boolean __near P_PointOnLineSide ( fixed_t	x, fixed_t	y, int16_t linedx, int16_t linedy,int16_t v1x,int16_t v1y){
    fixed_t	dx;
    fixed_t	dy;
    fixed_t	left;
    fixed_t	right;
	fixed_t_union temp;
	temp.h.fracbits = 0;
    if (!linedx) {
		temp.h.intbits = v1x;
		if (x <= temp.w) {
			return linedy > 0;
		}
		return linedy < 0;
    }
    if (!linedy) {
		temp.h.intbits = v1y;
		if (y <= temp.w) {
			return linedx < 0;
		}
	
		return linedx > 0;
    }
	
	temp.h.intbits = v1x;
    dx = (x - temp.w);
	temp.h.intbits = v1y;
    dy = (y - temp.w);
	
    left = FixedMul1632 ( linedy , dx );
    right = FixedMul1632 ( linedx , dy);
	
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

extern fixed_t_union		tmbbox[4];

int8_t __near P_BoxOnLineSide (  slopetype_t	lineslopetype, int16_t linedx, int16_t linedy, int16_t v1x, int16_t v1y ) {


    boolean		p1;
    boolean		p2;
	fixed_t_union temp;
	temp.h.fracbits = 0;
    switch (lineslopetype) {
      case ST_HORIZONTAL_HIGH:
	  	temp.h.intbits = v1y;
		p1 = tmbbox[BOXTOP].w > temp.w;
		p2 = tmbbox[BOXBOTTOM].w > temp.w;
		if (linedx < 0) {
			p1 ^= 1;
			p2 ^= 1;
		}
		break;
	
      case ST_VERTICAL_HIGH:
	  	temp.h.intbits = v1x;
		p1 = tmbbox[BOXRIGHT].w < temp.w;
		p2 = tmbbox[BOXLEFT].w < temp.w;
		if (linedy < 0)
		{
			p1 ^= 1;
			p2 ^= 1;
		}
		break;
	
      case ST_POSITIVE_HIGH:
		p1 = P_PointOnLineSide (tmbbox[BOXLEFT].w, tmbbox[BOXTOP].w, linedx, linedy, v1x, v1y);
		p2 = P_PointOnLineSide (tmbbox[BOXRIGHT].w, tmbbox[BOXBOTTOM].w, linedx, linedy, v1x, v1y);
		break;
	
      case ST_NEGATIVE_HIGH:
		p1 = P_PointOnLineSide (tmbbox[BOXRIGHT].w, tmbbox[BOXTOP].w, linedx, linedy, v1x, v1y);
		p2 = P_PointOnLineSide (tmbbox[BOXLEFT].w, tmbbox[BOXBOTTOM].w, linedx, linedy, v1x, v1y);
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
boolean __near P_PointOnDivlineSide ( fixed_t	x, fixed_t	y ) {
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
	divline_t __near*	line = &trace;
	
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
    // note these are internally being shifted by fixedmul2424
	left = FixedMul2424 ( line->dy.w, dx.w );
    right = FixedMul2424 ( dy.w , line->dx.w );
	
	return (right >= left);

	
}

// we know x/y low 16 bits is 0, small number of optimizaitons possible
// edit: decided not worth it, one comparison is slightly faster but it requires a new dupe function
#define P_PointOnDivlineSide16(a, b) P_PointOnDivlineSide(a, b)
/*
boolean
P_PointOnDivlineSide16
(fixed_t_union	x,
	fixed_t_union	y )
{
	fixed_t_union	dx;
	fixed_t_union	dy;
    fixed_t	left;
    fixed_t	right;
	divline_t __near*	line = &trace;
	fixed_t_union temp;
	
    if (!line->dx.w) {
		if (x.h.intbits <= line->x.h.intbits)
			return line->dy.w > 0;
		
		return line->dy.w < 0;
	}
    if (!line->dy.w) {
		if (y.h.intbits <= line->y.h.intbits)
			return line->dx.w < 0;

		return line->dx.w > 0;
    }
	
	dx.w = (x.w - line->x.w);
	dy.w = (y.w - line->y.w);
	
    // try to quickly decide by looking at sign bits
	if ((line->dy.h.intbits ^ line->dx.h.intbits ^ dx.h.intbits ^ dy.h.intbits) & 0x8000)
	{
		if ((line->dy.h.intbits ^ dx.h.intbits) & 0x8000)
			return 1;		// (left is negative)
		return 0;
	}
	
	left = FixedMul2424(line->dy.w , dx.w  );
	right = FixedMul2424(dy.w  , line->dx.w  );

	
	return (right >= left);

}

*/
 



//
// P_InterceptVector
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings
// and addlines traversers.
//
fixed_t __near P_InterceptVector ( divline_t __near*	v1 ) {
    fixed_t	frac;
    fixed_t	num;
    fixed_t	den;
	divline_t __near*	v2 = &trace;
	
    den = FixedMul2432 (v1->dy.w,v2->dx.w) - 
		FixedMul2432(v1->dx.w ,v2->dy.w);

    if (den == 0)
		return 0;
    
    num = FixedMul2432 ( (v1->x.w - v2->x.w) ,v1->dy.w) + 
		FixedMul2432 ( (v2->y.w - v1->y.w), v1->dx.w);

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
		int16_t linefrontsecnum = lines_physics[linenum].frontsecnum;
		int16_t linebacksecnum = lines_physics[linenum].backsecnum;

		sector_t __far* front = &sectors[linefrontsecnum];
		sector_t __far* back = &sectors[linebacksecnum];
	 


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

#ifdef CHECK_FOR_ERRORS
	if (secnum > numsectors || secnum < 0) {
		I_Error("bad secnum %i", secnum);
	}
#endif
 
	
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

void __near P_LineOpening (int16_t lineside1, int16_t linefrontsecnum, int16_t linebacksecnum) {
	sector_t __far*	front;
    sector_t __far*	back;
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
void __near P_UnsetThingPosition (mobj_t __far* thing, mobj_pos_t __far* thing_pos)
{
    int16_t		blockx;
    int16_t		blocky;
	mobj_t __far* changeThing;
	mobj_pos_t __far* changeThing_pos;

	THINKERREF nextRef;
	THINKERREF thingsprevRef = thing->sprevRef;

	THINKERREF thingsnextRef = thing_pos->snextRef;
	THINKERREF thingbnextRef = thing->bnextRef;
	int16_t thingflags1 = thing_pos->flags1;
	//int16_t thingsubsecnum = thing->subsecnum;
	int16_t thingsecnum = thing->secnum;
	THINKERREF thisRef = GETTHINKERREF(thing);

	if (!(thingflags1 & MF_NOSECTOR)) {
		// inert things don't need to be in blockmap?
		// unlink from subsector
		if (thingsnextRef) {
			changeThing = (mobj_t __far*)&thinkerlist[thingsnextRef].data;
			changeThing->sprevRef = thingsprevRef;
		}

		if (thingsprevRef) {
			changeThing_pos = &mobjposlist[thingsprevRef];
			changeThing_pos->snextRef = thingsnextRef;
		}
		else {
			sectors[thingsecnum].thinglistRef = thingsnextRef;
		}
	}

	/*
	if ( ! (thingflags1 & MF_NOSECTOR) ) {
	// inert things don't need to be in blockmap?
	// unlink from subsector

		nextRef = sectors[thingsecnum].thinglistRef;
		// if nextref check here?
		while (nextRef) {
			mobj_t __far* innerthing = &thinkerlist[nextRef].data;
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
	


    if (! (thingflags1 & MF_NOBLOCKMAP) ) {
	// insert things don't need to be in blockmap
	// unlink from block map
		fixed_t_union thingx = thing_pos->x;
		fixed_t_union thingy = thing_pos->y;


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
				mobj_t __far* innerthing = &thinkerlist[nextRef].data;
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
void __near P_SetThingPosition (mobj_t __far* thing, mobj_pos_t __far* thing_pos, int16_t knownsecnum) {



	//sector_t*		sec;
    int16_t			blockx;
    int16_t			blocky;
	THINKERREF		linkRef;
	
	mobj_t __far* thingList;
	THINKERREF oldsectorthinglist;
	fixed_t_union temp;
	THINKERREF thingRef = GETTHINKERREF(thing);
	// link into subsector

	if (knownsecnum != -1) {
		thing->secnum = knownsecnum;

	}
	else {
		int16_t	subsecnum = R_PointInSubsector(thing_pos->x, thing_pos->y);;
		int16_t subsectorsecnum = subsectors[subsecnum].secnum;
		thing->secnum = subsectorsecnum;
	}


	if (!(thing_pos->flags1 & MF_NOSECTOR)) {
		// invisible things don't go into the sector links

		oldsectorthinglist = sectors[thing->secnum].thinglistRef;
		sectors[thing->secnum].thinglistRef = thingRef;


		thing = (mobj_t __far*)&thinkerlist[thingRef].data;
		thing_pos = &mobjposlist[thingRef];

		thing->sprevRef = NULL_THINKERREF;
		thing_pos->snextRef = oldsectorthinglist;

		if (thing_pos->snextRef) {
			thingList = (mobj_t __far*)&thinkerlist[thing_pos->snextRef].data;
			thingList->sprevRef = thingRef;
		}

	}


	/*
    if ( ! (thing->flags1 & MF_NOSECTOR) ) {
		// invisible things don't go into the sector links

		thing->snextRef = sectors[subsectorsecnum].thinglistRef;
		sectors[subsectorsecnum].thinglistRef = thingRef;
		 

    }*/



    // link into blockmap
    if ( ! (thing_pos->flags1 & MF_NOBLOCKMAP) ) {
		// inert things don't need to be in blockmap		
		temp = thing_pos->x;
		blockx = (temp.h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
		temp = thing_pos->y;
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
boolean __near P_BlockLinesIterator ( int16_t x, int16_t y, boolean __near(*   func )(line_physics_t __far*, int16_t) ){
    int16_t			offset;
	int16_t			index;
    int16_t		list;
	line_physics_t __far*		ld_physics;
    if (x<0
	|| y<0
	|| x>=bmapwidth
	|| y>=bmapheight)
    {
	return true;
    }
    
    offset = y*bmapwidth+x;
	offset = *(blockmaplump_plus4 + offset);
	
    for ( index = offset ; blockmaplump[index] != -1 ; index++) {

		list = blockmaplump[index];

		ld_physics = &lines_physics[list];

		if (ld_physics->validcount == validcount) {
			continue; 	// line has already been checked
		}
		ld_physics->validcount = validcount;
			
		if (!func(ld_physics, list)) {
			return false;
		}
    }


    return true;	// everything was checked
}


//
// P_BlockThingsIterator
//
boolean __near P_BlockThingsIterator ( int16_t x, int16_t y, 
boolean __near(*   func )(THINKERREF, mobj_t __far*, mobj_pos_t __far*) ){
	THINKERREF mobjRef;
    mobj_t __far*		mobj;

    if ( x<0 || y<0 || x>=bmapwidth || y>=bmapheight) {
		return true;
	}
	 

	for (mobjRef = blocklinks[y*bmapwidth + x]; mobjRef; mobjRef = mobj->bnextRef) {
		// will this cause stuff to lose scope...?


		mobj = (mobj_t __far*)&thinkerlist[mobjRef].data;
		
		if (!func(mobjRef, mobj, &mobjposlist[mobjRef])) {

			return false;
		}

		 
	} 

	return true;
}



//
// INTERCEPT ROUTINES
//
 intercept_t __far*	intercept_p;

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
divline_t		dl;
boolean __near  PIT_AddLineIntercepts (line_physics_t __far* ld_physics, int16_t linenum) {
     int16_t			s1;
    int16_t			s2;
    fixed_t		frac;
	int16_t linedx = ld_physics->dx;
	int16_t linedy = ld_physics->dy;
	int16_t linev1Offset = ld_physics->v1Offset;
	int16_t v1x = vertexes[linev1Offset].x;
	int16_t v1y = vertexes[linev1Offset].y;
	fixed_t_union tempx;
	fixed_t_union tempy;
	fixed_t_union temp;

	tempx.h.fracbits = 0;
	tempy.h.fracbits = 0;

    // avoid precision problems with two routines
	if ( trace.dx.h.intbits > 16 || trace.dy.h.intbits > 16 || trace.dx.h.intbits < -16 || trace.dy.h.intbits < -16) {
		// we actually know the vertex fields to be 16 bit, but trace has 32 bit fields
		int16_t linev2Offset = ld_physics->v2Offset & VERTEX_OFFSET_MASK;
		tempx.h.intbits = v1x;
		tempy.h.intbits = v1y;
		s1 = P_PointOnDivlineSide16(tempx.w, tempy.w);
		tempx.h.intbits = vertexes[linev2Offset].x;
		tempy.h.intbits = vertexes[linev2Offset].y;
		s2 = P_PointOnDivlineSide16(tempx.w, tempy.w);
	} else {
		s1 = P_PointOnLineSide (trace.x.w, trace.y.w, linedx, linedy, v1x, v1y);
		s2 = P_PointOnLineSide (trace.x.w+trace.dx.w, trace.y.w+trace.dy.w, linedx, linedy, v1x, v1y);
    }
    
	if (s1 == s2) {
		return true;	// line isn't crossed
	}
    
    // hit the line

	temp.h.fracbits = 0;
	temp.h.intbits = v1x;
	dl.x = temp;
	temp.h.intbits = v1y;
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
    if (earlyout && frac < FRACUNIT && ld_physics->backsecnum == SECNUM_NULL) {
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
boolean __near  PIT_AddThingIntercepts (THINKERREF thingRef, mobj_t __far* thing, mobj_pos_t __far* thing_pos)
{
    fixed_t_union		x1;
	fixed_t_union		y1;
	fixed_t_union		x2;
	fixed_t_union		y2;
    
    int16_t			s1;
    int16_t			s2;
    
    boolean		tracepositive;

    
    fixed_t		frac;
	
 
	tracepositive = (trace.dx.h.intbits ^ trace.dy.h.intbits) > 0;

	x1 = x2 = thing_pos->x;
	y1 = y2 = thing_pos->y;
	x1.h.intbits -= thing->radius;
	x2.h.intbits += thing->radius;
	
	if (tracepositive) {
		y1.h.intbits += thing->radius;
		y2.h.intbits -= thing->radius;
	} else {
		y1.h.intbits -= thing->radius;
		y2.h.intbits += thing->radius;
	}
	s1 = P_PointOnDivlineSide (x1.w, y1.w);
    s2 = P_PointOnDivlineSide (x2.w, y2.w);

	if (s1 == s2) {
		return true;		// line isn't crossed
	}

    dl.x = x1;
    dl.y = y1;
    dl.dx.w = x2.w-x1.w;
    dl.dy.w = y2.w-y1.w;
    
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
void __near P_TraverseIntercepts( traverser_t	func) {
    int16_t			count;
    fixed_t_union		dist;
    intercept_t __far*	scan;
    intercept_t __far*	in = NULL;
	int16_t i = 0;
	count = intercept_p - intercepts;
 
	 


    while (count--) {
		i++;
		dist.w = MAXLONG;
		for (scan = intercepts ; scan<intercept_p ; scan++) {
			if (scan->frac < dist.w) {
				dist.w = scan->frac;
				in = scan;
			}
		}

		   
		//if (dist.h.intbits) {
		if (dist.w > FRACUNIT) {
			return;	// checked everything in range		
		}

		if (!func(in)) {
			return;	// don't bother going farther
		}

		in->frac = MAXLONG;
    }


}


#define MAPBLOCK1000_BITMASK (MAPBLOCKSIZE * 1000L) -1)
#define MAPBLOCK1000_LOWBITMASK 0xF3FF
#define MAPBLOCK1000_HIGHBITMASK 0x0001


//
// P_PathTraverse
// Traces a line from x1,y1 to x2,y2,
// calling the traverser function for each.
// Returns true if the traverser function returns true
// for all lines.
//
void __near P_PathTraverse
( fixed_t_union		x1,
  fixed_t_union		y1,
	fixed_t_union		x2,
	fixed_t_union		y2,
  uint8_t			flags,
  boolean __near(*   trav) (intercept_t  __far*))
{
    int16_t	xt1;
    int16_t	yt1;
    int16_t	xt2;
    int16_t	yt2;
    
    fixed_t	xstep;
    fixed_t	ystep;
    
	uint16_t	partial;
    
	fixed_t_union	xintercept;
    fixed_t_union	yintercept;
    
    int16_t		mapx;
    int16_t		mapy;
    
    int8_t		mapxstep;
    int8_t		mapystep;

    int8_t		count;
	fixed_t_union		x1mapblockshifted;
	fixed_t_union		y1mapblockshifted;

    earlyout = flags & PT_EARLYOUT;
	
    validcount++;
    intercept_p = intercepts;
 
	if (x1.h.fracbits & MAPBLOCK1000_LOWBITMASK == 0) {
		// only low bit matters, so xor is faster than subtract and just as accurate..
		// maybe during ASM optim do shift and check carry

		if ((x1.h.intbits ^ bmaporgx) & MAPBLOCK1000_LOWBITMASK == 0) {
			x1.h.intbits += 1;	// don't side exactly on a line
		}
	}
    

	if (y1.h.fracbits & MAPBLOCK1000_LOWBITMASK == 0) {
		// only low bit matters, so xor is faster than subtract and just as accurate..
		// maybe during ASM optim do shift and check carry
		if ((y1.h.intbits ^ bmaporgy) & MAPBLOCK1000_LOWBITMASK == 0) {
			y1.h.intbits += 1;	// don't side exactly on a line
		}
	}


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
    yt2 = y2.h.intbits >> MAPBLOCKSHIFT;
 

	x1mapblockshifted.w = (x1.w >> MAPBLOCKSHIFT);
	y1mapblockshifted.w = (y1.w >> MAPBLOCKSHIFT);
	
	yintercept = y1mapblockshifted;

	if (xt2 == xt1) {
		mapxstep = 0;
		yintercept.h.intbits += 256;
	} else {
		ystep = FixedDiv(y2.w - y1.w, labs(x2.w - x1.w));
		partial = x1mapblockshifted.h.fracbits;

		if (xt2 > xt1) {
			mapxstep = 1;
			partial ^= 0xFFFF;
			partial ++;
		} else {
			mapxstep = -1;
		}
		yintercept.w += FixedMul16u32(partial, ystep);
	}


	xintercept = x1mapblockshifted;
	if (yt2 == yt1) {
		xintercept.h.intbits += 256;
		mapystep = 0;

	} else {
		xstep = FixedDiv(x2.w - x1.w, labs(y2.w - y1.w));
		partial = y1mapblockshifted.h.fracbits;
		if (yt2 > yt1) {
			mapystep = 1;
			partial ^= 0xFFFF;
			partial++;

		} else {
			mapystep = -1;
		}

		xintercept.w += FixedMul16u32(partial, xstep);
	}

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



