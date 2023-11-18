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
//	Movement, collision handling.
//	Shooting and aiming.
//

#include <stdlib.h>

#include "m_misc.h"
#include "i_system.h"

#include "doomdef.h"
#include "p_local.h"

#include "s_sound.h"
#include "p_setup.h"

// State.
#include "doomstat.h"
#include "r_state.h"
// Data.
#include "sounds.h"


fixed_t_union		tmbbox[4];
mobj_t*		tmthing;
int32_t		tmflags;
fixed_t		tmx;
fixed_t		tmy;


// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".
boolean		floatok;

short_height_t		tmfloorz;
short_height_t		tmceilingz;
short_height_t		tmdropoffz;

// keep track of the line that lowers the ceiling,
// so missiles don't explode against sky hack walls
int16_t		ceilinglinenum;

// keep track of special lines as they are hit,
// but don't process them until the move is proven valid
#define MAXSPECIALCROSS		8

int16_t		spechit[MAXSPECIALCROSS];
int16_t		numspechit;



//
// TELEPORT MOVE
// 

//
// PIT_StompThing
//
boolean PIT_StompThing (THINKERREF thingRef, mobj_t*	thing)
{
    fixed_t_union	blockdist;

    if (!(thing->flags & MF_SHOOTABLE) )
		return true;
		
    blockdist.h.intbits = thing->radius + tmthing->radius;
	blockdist.h.fracbits = 0;
    
    if ( labs(thing->x - tmx) >= blockdist.w
	 || labs(thing->y - tmy) >= blockdist.w )
    {
	// didn't hit it
	return true;
    }
    
    // don't clip against self
    if (thing == tmthing)
	return true;
    
	
    // monsters don't stomp things except on boss level
    if ( !tmthing->type == MT_PLAYER && gamemap != 30)
	return false;	
		
    P_DamageMobj (thing, tmthing, tmthing, 10000);
	
    return true;
}


//
// P_TeleportMove
//
boolean
P_TeleportMove
(mobj_t* thing,
  fixed_t	x,
  fixed_t	y )
{
    int16_t			xl;
    int16_t			xh;
    int16_t			yl;
    int16_t			yh;
    int16_t			bx;
    int16_t			by;
    
	int16_t	newsubsecsecnum;
	int16_t	newsubsecnum;
	
	fixed_t_union temp;
	temp.h.fracbits = 0;
    // kill anything occupying the position
	tmthing = thing;
	tmflags = thing->flags;

    tmx = x;
    tmy = y;
	// todo imrpove how to do the minus cases? can underflow happen?
	tmbbox[BOXTOP].w = y; 
	tmbbox[BOXTOP].h.intbits += tmthing->radius;
	temp.h.intbits = tmthing->radius;
	tmbbox[BOXBOTTOM].w = y - temp.w;
	tmbbox[BOXRIGHT].w = x; 
	tmbbox[BOXRIGHT].h.intbits += tmthing->radius;
	tmbbox[BOXLEFT].w = x - temp.w;
	newsubsecnum = R_PointInSubsector (x,y);
	newsubsecsecnum = subsectors[newsubsecnum].secnum;
    ceilinglinenum = -1;
    
    // The base floor/ceiling is from the subsector
    // that contains the point.
    // Any contacted lines the step closer together
    // will adjust them.
	tmfloorz = tmdropoffz = sectors[newsubsecsecnum].floorheight;
    tmceilingz = sectors[newsubsecsecnum].ceilingheight;
			
    validcount++;
    numspechit = 0;
    
    // stomp on any things contacted
    xl = (tmbbox[BOXLEFT].h.intbits - bmaporgx - MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;
    xh = (tmbbox[BOXRIGHT].h.intbits - bmaporgx + MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;
    yl = (tmbbox[BOXBOTTOM].h.intbits - bmaporgy - MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;
    yh = (tmbbox[BOXTOP].h.intbits - bmaporgy + MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;


	if (xl < 0) xl = 0;
	if (yl < 0) yl = 0;
	if (xh >= bmapwidth) xh = bmapwidth - 1;
	if (yh >= bmapheight) yh = bmapheight - 1;

	for (bx = xl; bx <= xh; bx++) {
		for (by = yl; by <= yh; by++) {
			if (!P_BlockThingsIterator(bx, by, PIT_StompThing)) {
				return false;
			}
		}
	}
    
    // the move is ok,
    // so link the thing into its new position
	P_UnsetThingPosition (thing);

    thing->floorz = tmfloorz;
    thing->ceilingz = tmceilingz;	
    thing->x = x;
    thing->y = y;

    P_SetThingPosition (thing);
	
    return true;
}


//
// MOVEMENT ITERATOR FUNCTIONS
//


//
// PIT_CheckLine
// Adjusts tmfloorz and tmceilingz as lines are contacted
//
boolean PIT_CheckLine (line_t* ld, int16_t linenum)
{
	//int16_t linespecial;
	//fixed_t linedx; , fixed_t linedy, int16_t linev1Offset, int16_t linev2Offset, int16_t linefrontsecnum, int16_t linebacksecnum, int16_t lineside1, slopetype_t lineslopetype
	
	slopetype_t lineslopetype = ld->v2Offset & LINE_VERTEX_SLOPETYPE;
	int16_t linedx = ld->dx;
	int16_t linedy = ld->dy;
	int16_t linev1Offset = ld->v1Offset & VERTEX_OFFSET_MASK;
	vertex_t v1 = vertexes[linev1Offset];
	int16_t linefrontsecnum = ld->frontsecnum;
	int16_t linebacksecnum = ld->backsecnum;
	uint8_t lineflags = ld->flags;
	int16_t linespecial = ld->special;
	int16_t lineside1 = ld->sidenum[1];
	int16_t lineright = v1.x;
	int16_t lineleft = v1.x;
	int16_t linetop = v1.y;
	int16_t linebot = v1.y;

	if (linedx > 0) {
		lineright += linedx;
	} else if (linedx < 0){
		lineleft += linedx;
	}
	if (linedy > 0) {
		linetop += linedy;
	} else if (linedy < 0) {
		linebot += linedy;
	}


	
	if (tmbbox[BOXLEFT].h.intbits >= lineright || tmbbox[BOXBOTTOM].h.intbits >= linetop
		|| ((tmbbox[BOXRIGHT].h.intbits < lineleft) || ((tmbbox[BOXRIGHT].h.intbits == lineleft   && tmbbox[BOXRIGHT].h.fracbits == 0)))
		|| ((tmbbox[BOXTOP].h.intbits < linebot) || ((tmbbox[BOXTOP].h.intbits   == linebot) &&  tmbbox[BOXTOP].h.fracbits == 0))
		) {
		
 

		return true;
	}


	if (P_BoxOnLineSide(tmbbox, lineslopetype, linedx, linedy, linev1Offset) != -1) {
		return true;
	}

    // A line has been hit
    
    // The moving thing's destination position will cross
    // the given line.
    // If this should not be allowed, return false.
    // If the line is special, keep track of it
    // to process later if the move is proven ok.
    // NOTE: specials are NOT sorted by order,
    // so two special lines that are only 8 pixels apart
    // could be crossed in either order.
    
	if (linebacksecnum == SECNUM_NULL) {
		return false;		// one sided line
	}


    if (!(tmthing->flags & MF_MISSILE) ) {
		if (lineflags & ML_BLOCKING) {
			return false;	// explicitly blocking everything
		}
		if (tmthing->type != MT_PLAYER && lineflags & ML_BLOCKMONSTERS) {
			return false;	// block monsters only
		}
    }

    // set openrange, opentop, openbottom
    P_LineOpening (lineside1, linefrontsecnum, linebacksecnum);	
	
    // adjust floor / ceiling heights
    if (opentop < tmceilingz) {
		tmceilingz = opentop;
		ceilinglinenum = linenum;
    } 

	if (openbottom > tmfloorz) {
		tmfloorz = openbottom;
	}

	if (lowfloor < tmdropoffz) {
		tmdropoffz = lowfloor;
	}

    // if contacted a special line, add it to the list
    if (linespecial) {
		spechit[numspechit] = linenum;
		numspechit++;
    }

    return true;
}

//
// PIT_CheckThing
//
boolean PIT_CheckThing (THINKERREF thingRef, mobj_t*	thing)
{
    fixed_t		blockdist;
    boolean		solid;
    int16_t			damage;
	mobj_t* tmthingTarget;
	mobjtype_t tmthingTargettype;
	mobjtype_t thingtype;
	THINKERREF tmthingtargetRef;
	int32_t thingflags;
	fixed_t thingx;
	fixed_t thingy;
	fixed_t thingz;
	fixed_t tmthingz;
	fixed_t_union tmthingheight;
	fixed_t_union thingheight;
	fixed_t_union thingradius;
	// don't clip against self


	if (thing == tmthing) {
			return true;
	}

	thingflags = thing->flags;

	if (!(thingflags & (MF_SOLID | MF_SPECIAL | MF_SHOOTABLE))) {
			return true;
	}
	thingtype = thing->type;
	thingx = thing->x;
	thingy = thing->y;
	thingz = thing->z;
	thingheight = thing->height;
	thingradius.h.intbits = thing->radius;
	thingradius.h.fracbits = 0;


	
	thingradius.h.intbits += tmthing->radius;
	blockdist = thingradius.w;

    if ( labs(thingx - tmx) >= blockdist || labs(thingy - tmy) >= blockdist ) {
		// didn't hit it
			return true;
    }
	tmthingheight = tmthing->height;
	tmthingz = tmthing->z;
	tmthingtargetRef = tmthing->targetRef;


    // check for skulls slamming into things
    if (tmthing->flags & MF_SKULLFLY) {
		damage = ((P_Random()%8)+1)*getDamage(tmthing->type);
		P_DamageMobj (thing, tmthing, tmthing, damage);
		tmthing->flags &= ~MF_SKULLFLY;
		tmthing->momx = tmthing->momy = tmthing->momz = 0;
	
		P_SetMobjState (tmthing, mobjinfo[tmthing->type].spawnstate);

		return false;		// stop moving
    }
	
    // missiles can hit other things
    if (tmthing->flags & MF_MISSILE) {
		// see if it went over / under
		if (tmthingz > thingz + thingheight.w) {
			return true;		// overhead
		}
		if (tmthingz + tmthingheight.w < thingz) {
			return true;		// underneath
		}
		tmthingTarget = (mobj_t*)&thinkerlist[tmthingtargetRef].data;
		if (tmthingTarget) {
			tmthingTargettype = tmthingTarget->type;
			if (tmthingTargettype == thingtype || (tmthingTargettype == MT_KNIGHT && thingtype == MT_BRUISER)|| (tmthingTargettype == MT_BRUISER && thingtype == MT_KNIGHT) ) {
				// Don't hit same species as originator.
 			if (thing == tmthingTarget) {
					return true;
				}

				if (thingtype != MT_PLAYER) {
				// Explode, but do no damage.
				// Let players missile other players.

					return false;
				}
			}
		}
		if (! (thingflags & MF_SHOOTABLE) ) {
			// didn't do any damage
			return !(thingflags & MF_SOLID);
		}
	
		// damage / explode
		damage = ((P_Random()%8)+1)*getDamage(tmthing->type);
		

		P_DamageMobj (thing, tmthing, tmthingTarget, damage);

		// don't traverse any more
		return false;				
    }
    
    // check for special pickup
    if (thingflags & MF_SPECIAL)
    {
	solid = thingflags &MF_SOLID;
	if (tmflags&MF_PICKUP)
	{
		//I_Error("%i %i %i", players.moRef, tmthingRef, thingRef);
	    // can remove thing
	    P_TouchSpecialThing (thing, tmthing);
	}
	return !solid;
    }

    return !(thingflags & MF_SOLID);
}


//
// MOVEMENT CLIPPING
//

//
// P_CheckPosition
// This is purely informative, nothing is modified
// (except things picked up).
// 
// in:
//  a mobj_t (can be valid or invalid)
//  a position to be checked
//   (doesn't need to be related to the mobj_t->x,y)
//
// during:
//  special things are touched if MF_PICKUP
//  early out on solid lines?
//
// out:
//  newsubsec
//  floorz
//  ceilingz
//  tmdropoffz
//   the lowest point contacted
//   (monsters won't move to a dropoff)
//  speciallines[]
//  numspeciallines
//
boolean
P_CheckPosition
(mobj_t* thing,
  fixed_t	x,
  fixed_t	y
	)
{
    int16_t			xl;
    int16_t			xh;
    int16_t			yl;
    int16_t			yh;
    int16_t			bx;
    int16_t			by;
	int16_t newsubsecnum;
	int16_t newsubsecsecnum;
	fixed_t_union temp;
	temp.h.fracbits = 0;
    tmthing = thing;
    tmflags = thing->flags;
	
    tmx = x;
    tmy = y;
 

	
	// todo imrpove how to do the minus cases? can underflow happen?

	tmbbox[BOXTOP].w = y;
	tmbbox[BOXTOP].h.intbits += thing->radius;
	temp.h.intbits = thing->radius;
	tmbbox[BOXBOTTOM].w = y - temp.w;
	tmbbox[BOXRIGHT].w = x;
	tmbbox[BOXRIGHT].h.intbits += thing->radius;
	tmbbox[BOXLEFT].w = x - temp.w;

 


	newsubsecnum = R_PointInSubsector(x, y);
	newsubsecsecnum = subsectors[newsubsecnum].secnum;



	ceilinglinenum = -1;
    
    // The base floor / ceiling is from the subsector
    // that contains the point.
    // Any contacted lines the step closer together
    // will adjust them.
	tmfloorz = tmdropoffz = sectors[newsubsecsecnum].floorheight;
    tmceilingz = sectors[newsubsecsecnum].ceilingheight;
	

    validcount++;
    numspechit = 0;

	if (tmflags & MF_NOCLIP) {
		return true;
	}

    // Check things first, possibly picking things up.
    // The bounding box is extended by MAXRADIUS
    // because mobj_ts are grouped into mapblocks
    // based on their origin point, and can overlap
    // into adjacent blocks by up to MAXRADIUS units.
 	xl = (tmbbox[BOXLEFT].h.intbits - bmaporgx - MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
	xh = (tmbbox[BOXRIGHT].h.intbits - bmaporgx + MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
	yl = (tmbbox[BOXBOTTOM].h.intbits - bmaporgy - MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
	yh = (tmbbox[BOXTOP].h.intbits - bmaporgy + MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;

	if (xl < 0) xl = 0;
	if (yl < 0) yl = 0;
	if (xh >= bmapwidth) xh = bmapwidth - 1;
	if (yh >= bmapheight) yh = bmapheight - 1;

	for (bx = xl; bx <= xh; bx++) {
		for (by = yl; by <= yh; by++) {

	
			if (!P_BlockThingsIterator(bx, by, PIT_CheckThing)) {

				return false;
			}
		}
	}
	
	// check lines
	xl = (tmbbox[BOXLEFT].h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
	xh = (tmbbox[BOXRIGHT].h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
	yl = (tmbbox[BOXBOTTOM].h.intbits - bmaporgy) >> MAPBLOCKSHIFT;
	yh = (tmbbox[BOXTOP].h.intbits - bmaporgy) >> MAPBLOCKSHIFT;

	if (xl < 0) xl = 0;
	if (yl < 0) yl = 0;
	if (xh >= bmapwidth) xh = bmapwidth - 1;
	if (yh >= bmapheight) yh = bmapheight - 1;

	for (bx = xl; bx <= xh; bx++) {
		for (by = yl; by <= yh; by++) {


			if (!P_BlockLinesIterator(bx, by, PIT_CheckLine)) {

				return false;
			}

		}
	}

	return true;
}


//
// P_TryMove
// Attempt to move to a new position,
// crossing special lines unless MF_TELEPORT is set.
//
boolean
P_TryMove
(mobj_t* thing,
  fixed_t	x,
  fixed_t	y 
	)
{
    fixed_t	oldx;
    fixed_t	oldy;
	fixed_t	newx;
	fixed_t	newy;
    int16_t	side;
    int16_t	oldside;
    line_t*	ld;
 	int16_t lddx;
 	int16_t lddy;
	int16_t ldspecial;
	int16_t ldv1Offset;
	fixed_t_union temp;
	int16_t temp2;
	temp.h.fracbits = 0;

	floatok = false;

	if (!P_CheckPosition(thing, x, y)) {
		return false;		// solid wall or thing
	}

    if ( !(thing->flags & MF_NOCLIP) ) {
		temp2 = (tmceilingz - tmfloorz);
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
//		if (temp.w < thing->height.w) { 
		if (temp.h.intbits < thing->height.h.intbits) { // 16 bit logic handles the fractional fine
			return false;	// doesn't fit
		}

		floatok = true;
		
		// temp.h.intbits = tmceilingz >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, tmceilingz);
		if (!(thing->flags&MF_TELEPORT) && temp.w - thing->z < thing->height.w) {
			return false;	// mobj must lower itself to fit
		}
		// temp.h.intbits = tmfloorz >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, tmfloorz);
		if (!(thing->flags&MF_TELEPORT) && (temp.w - thing->z) > 24 * FRACUNIT) {
			return false;	// too big a step up
		}

		if (!(thing->flags&(MF_DROPOFF | MF_FLOAT)) && (tmfloorz - tmdropoffz) > (24<<SHORTFLOORBITS) ) {
			return false;	// don't stand over a dropoff
		}
		

    }

    // the move is ok,
    // so link the thing into its new position
	P_UnsetThingPosition (thing);

    oldx = thing->x;
    oldy = thing->y;
    thing->floorz = tmfloorz;
    thing->ceilingz = tmceilingz;	
    thing->x = x;
    thing->y = y;



	P_SetThingPosition (thing);


	newx = thing->x;
	newy = thing->y;
    
	// if any special lines were hit, do the effect
    if (! (thing->flags&(MF_TELEPORT|MF_NOCLIP)) ) {
		while (numspechit--) {
			// see if the line was crossed
			ld = &lines[spechit[numspechit]];
			lddx = ld->dx;
			lddy = ld->dy;
			ldv1Offset = ld->v1Offset & VERTEX_OFFSET_MASK;
			ldspecial = ld->special;

			side = P_PointOnLineSide (newx, newy, lddx, lddy, ldv1Offset);
			oldside = P_PointOnLineSide (oldx, oldy, lddx, lddy, ldv1Offset);
			if (side != oldside) {
				if (ldspecial) {
					P_CrossSpecialLine(spechit[numspechit], oldside, thing);
				}
			}
		}
    }
	
    return true;
}


//
// P_ThingHeightClip
// Takes a valid thing and adjusts the thing->floorz,
// thing->ceilingz, and possibly thing->z.
// This is called for all nearby monsters
// whenever a sector changes height.
// If the thing doesn't fit,
// the z will be set to the lowest value
// and false will be returned.
//
boolean P_ThingHeightClip (mobj_t* thing)
{
    boolean		onfloor;
	fixed_t_union temp;
	int16_t temp2;
	temp.h.fracbits = 0;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->floorz);
    onfloor = (thing->z == temp.w);


    P_CheckPosition (thing, thing->x, thing->y);	
    // what about stranding a monster partially off an edge?

    thing->floorz = tmfloorz;
    thing->ceilingz = tmceilingz;
	
    if (onfloor) {
		// walking monsters rise and fall with the floor
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->floorz);
		thing->z = temp.w;

    } else {
	// don't adjust a floating monster unless forced to
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->ceilingz);
		if (thing->z+ thing->height.w > temp.w)
			thing->z = temp.w - thing->height.w;
	}

	temp2 = (thing->ceilingz - thing->floorz);
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
	
	if (temp.h.intbits < thing->height.h.intbits) // 16 bit math should be ok
		return false;

    return true;
}



//
// SLIDE MOVE
// Allows the player to slide along any angled walls.
//
fixed_t		bestslidefrac;
fixed_t		secondslidefrac;

int16_t		bestslidelinenum;
int16_t		secondslidelinenum;

fixed_t		tmxmove;
fixed_t		tmymove;



//
// P_HitSlideLine
// Adjusts the xmove / ymove
// so that the next move will slide along the wall.
//
void P_HitSlideLine (int16_t linenum)
{
    int16_t			side;

    angle_t		lineangle;
    angle_t		moveangle;
    angle_t		deltaangle;
    
    fixed_t		movelen;
    fixed_t		newlen;

	line_t ld = lines[linenum];
	
    if ((ld.v2Offset&LINE_VERTEX_SLOPETYPE) == ST_HORIZONTAL_HIGH) {
		tmymove = 0;
		return;
    }
    
    if ((ld.v2Offset&LINE_VERTEX_SLOPETYPE) == ST_VERTICAL_HIGH) {
		tmxmove = 0;
		return;
    }
	
    side = P_PointOnLineSide (playerMobj->x, playerMobj->y, ld.dx, ld.dy, ld.v1Offset & VERTEX_OFFSET_MASK);
    lineangle = R_PointToAngle2_16 (0,0, ld.dx, ld.dy);

    if (side == 1)
		lineangle += ANG180;

    moveangle = R_PointToAngle2 (0,0, tmxmove, tmymove);
    deltaangle = moveangle-lineangle;

    if (deltaangle > ANG180)
	deltaangle += ANG180;
    //	I_Error ("SlideLine: ang>ANG180");

    lineangle >>= ANGLETOFINESHIFT;
    deltaangle >>= ANGLETOFINESHIFT;
	
    movelen = P_AproxDistance (tmxmove, tmymove);
    newlen = FixedMul (movelen, finecosine(deltaangle));

    tmxmove = FixedMul (newlen, finecosine(lineangle));	
    tmymove = FixedMul (newlen, finesine(lineangle));	
}


//
// PTR_SlideTraverse
//
boolean PTR_SlideTraverse (intercept_t* in)
{
	line_t li;
	fixed_t_union temp;

	li = lines[in->d.linenum];

    
    if ( ! (li.flags & ML_TWOSIDED) ) {
 		if (P_PointOnLineSide (playerMobj->x, playerMobj->y, li.dx, li.dy, li.v1Offset & VERTEX_OFFSET_MASK)) {
	    // don't hit the back side
			return true;		
		}
	goto isblocking;
    }

    // set openrange, opentop, openbottom
	temp.h.fracbits = 0;
    P_LineOpening (li.sidenum[1], li.frontsecnum, li.backsecnum);
 	// temp.h.intbits = openrange >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, openrange);

    if (temp.h.intbits < playerMobj->height.h.intbits) // 16 bit okay
		goto isblocking;		// doesn't fit
		
	// temp.h.intbits = opentop >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, opentop);
    if (temp.w - playerMobj->z < playerMobj->height.w)
		goto isblocking;		// mobj is too high

	// temp.h.intbits = openbottom >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, openbottom);
    if (temp.w - playerMobj->z > 24*FRACUNIT )
		goto isblocking;		// too big a step up

    // this line doesn't block movement
    return true;		
	
    // the line does block movement,
    // see if it is closer than best so far
  isblocking:		
    if (in->frac < bestslidefrac) {
		secondslidefrac = bestslidefrac;
		secondslidelinenum = bestslidelinenum;
		bestslidefrac = in->frac;
		bestslidelinenum = in->d.linenum;
    }
	
    return false;	// stop
}


//
// P_SlideMove
// The momx / momy move is bad, so try to slide
// along a wall.
// Find the first line hit, move flush to it,
// and slide along it
//
// This is a kludgy mess.
//
void P_SlideMove ()
{
    fixed_t_union		leadx;
	fixed_t_union		leady;
	fixed_t_union		trailx;
	fixed_t_union		traily;
	fixed_t		newx;
	fixed_t		newy;
    int16_t			hitcount;
	fixed_t_union   temp;
	fixed_t_union   temp2;
	fixed_t_union   temp3;
	fixed_t_union   temp4;
		
     hitcount = 0;
    
  retry:
    if (++hitcount == 3)
		goto stairstep;		// don't loop forever

    // trace along the three leading corners
	// todo improve the minus cases
	temp.h.fracbits = 0;
	temp.h.intbits = playerMobj->radius;
	leadx.w = playerMobj->x;
	trailx.w = playerMobj->x;
	leady.w = playerMobj->y;
	traily.w = playerMobj->y;
	if (playerMobj->momx > 0) {
		leadx.h.intbits += temp.h.intbits;
		trailx.w -= temp.w;
    } else {
		leadx.w -= temp.w;
		trailx.h.intbits += temp.h.intbits;
    }
	
    if (playerMobj->momy > 0) {
		leady.h.intbits += temp.h.intbits;
		traily.w -= temp.w;
    } else {
		leady.w -= temp.w;
		traily.h.intbits += temp.h.intbits;

    } 
		
    bestslidefrac = FRACUNIT+1;
	
 
	
	temp.w = leadx.w + playerMobj->momx;
	temp2.w = leady.w + playerMobj->momy;
	P_PathTraverse(leadx, leady, temp, temp2, PT_ADDLINES, PTR_SlideTraverse);
	
	//todo do these mo fields change? if not then pull out momx/momy into locals to avoid extra loads
	temp2.w = leady.w + playerMobj->momy;
	temp3.w = trailx.w + playerMobj->momx;
	P_PathTraverse(trailx, leady, temp3, temp2, PT_ADDLINES, PTR_SlideTraverse);

	temp.w = leadx.w + playerMobj->momx;
	temp4.w = traily.w + playerMobj->momy;

	P_PathTraverse(leadx, traily, temp, temp4, PT_ADDLINES, PTR_SlideTraverse);


 
    // move up to the wall

	if (bestslidefrac == FRACUNIT+1) {
	// the move most have hit the middle, so stairstep
      stairstep:
 
		if (!P_TryMove(playerMobj, playerMobj->x, playerMobj->y + playerMobj->momy)) {
			P_TryMove(playerMobj, playerMobj->x + playerMobj->momx, playerMobj->y);
		}

		return;
    }

    // fudge a bit to make sure it doesn't hit
    bestslidefrac -= 0x800;	
    if (bestslidefrac > 0) {
		newx = FixedMul (playerMobj->momx, bestslidefrac);
		newy = FixedMul (playerMobj->momy, bestslidefrac);
	
		if (!P_TryMove(playerMobj, playerMobj->x + newx, playerMobj->y + newy)) {
			goto stairstep;
		}
    }

 

    // Now continue along the wall.
    // First calculate remainder.
    bestslidefrac = FRACUNIT-(bestslidefrac+0x800);
    
    if (bestslidefrac > FRACUNIT)
		bestslidefrac = FRACUNIT;
    
	if (bestslidefrac <= 0) {
		return;
	}
 
    tmxmove = FixedMul (playerMobj->momx, bestslidefrac);
    tmymove = FixedMul (playerMobj->momy, bestslidefrac);

    P_HitSlideLine (bestslidelinenum);	// clip the moves

 
	playerMobj->momx = tmxmove;
	playerMobj->momy = tmymove;
		
    if (!P_TryMove (playerMobj, playerMobj->x+tmxmove, playerMobj->y+tmymove)) {
		goto retry;
    }
}


//
// P_LineAttack
//
mobj_t*		linetarget;	// who got hit (or NULL)
mobj_t*		shootthing;

// Height if not aiming up or down
// ???: use slope for monsters?
fixed_t		shootz;	

int16_t		la_damage;
fixed_t_union		attackrange;

fixed_t		aimslope;

// slopes to top and bottom of target
extern fixed_t	topslope;
extern fixed_t	bottomslope;	


//
// PTR_AimTraverse
// Sets linetaget and aimslope when a target is aimed at.
//
boolean
PTR_AimTraverse (intercept_t* in)
{
    line_t		li;
    mobj_t*		th;
    fixed_t		slope;
    fixed_t		thingtopslope;
    fixed_t		thingbottomslope;
    fixed_t		dist;
	fixed_t_union temp;

    if (in->isaline) {
		li = lines[in->d.linenum];
	
		if (!(li.flags & ML_TWOSIDED)) {
			//I_Error("caught a");
			return false;		// stop
		}
		// Crosses a two sided line.
		// A two sided line will restrict
		// the possible target ranges.
		P_LineOpening (li.sidenum[1], li.frontsecnum, li.backsecnum);
	
		if (openbottom >= opentop) {
			//I_Error("caught b");
			return false;		// stop
		}
	
		dist = FixedMul (attackrange.w, in->frac);

		temp.h.fracbits = 0;
		if (sectors[li.frontsecnum].floorheight != sectors[li.backsecnum].floorheight) {
			// temp.h.intbits = openbottom >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, openbottom);
			slope = FixedDiv (temp.w - shootz , dist);
			if (slope > bottomslope)
				bottomslope = slope;
		}
		
		if (sectors[li.frontsecnum].ceilingheight != sectors[li.backsecnum].ceilingheight) {
			// temp.h.intbits = opentop >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, opentop);
			slope = FixedDiv (temp.w - shootz , dist);
			if (slope < topslope)
				topslope = slope;
		}
		
		if (topslope <= bottomslope) {
			return false;		// stop
		}

		//I_Error("caught d");
		return true;			// shot continues
    }
    
    // shoot a thing
	th = (mobj_t*)&thinkerlist[in->d.thingRef].data;
	if (th == shootthing) {
		//I_Error("caught e");
		return true;			// can't shoot self
	}

	if (!(th->flags&MF_SHOOTABLE)) {
		//I_Error("caught f");
		return true;			// corpse or something
	}
    // check angles to see if the thing can be aimed at
    dist = FixedMul (attackrange.w, in->frac);
    thingtopslope = FixedDiv (th->z+th->height.w - shootz , dist);

	if (thingtopslope < bottomslope) {
		//I_Error("caught g");
		return true;			// shot over the thing
	}
    thingbottomslope = FixedDiv (th->z - shootz, dist);

	if (thingbottomslope > topslope) {
		//I_Error("caught h");
		return true;			// shot under the thing
	}
    // this thing can be hit!
    if (thingtopslope > topslope)
		thingtopslope = topslope;
    
    if (thingbottomslope < bottomslope)
		thingbottomslope = bottomslope;

    aimslope = (thingtopslope+thingbottomslope)/2;
    linetarget = th;
	
    return false;			// don't go any farther
}


//
// PTR_ShootTraverse
//
boolean PTR_ShootTraverse (intercept_t* in)
{
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
    fixed_t		frac;
    
    line_t		li;
    
    mobj_t*		th;

    fixed_t		slope;
    fixed_t		dist;
    fixed_t		thingtopslope;
    fixed_t		thingbottomslope;
	THINKERREF		thRef;
	fixed_t_union temp;
	temp.h.fracbits = 0;

    if (in->isaline) {
		li = lines[in->d.linenum];
		
		if (li.special)
			P_ShootSpecialLine (shootthing, in->d.linenum);

		if ( !(li.flags & ML_TWOSIDED) )
			goto hitline;
	
		// crosses a two sided line
		P_LineOpening(li.sidenum[1], li.frontsecnum, li.backsecnum);
		
		dist = FixedMul (attackrange.w, in->frac);

		if (sectors[li.frontsecnum].floorheight != sectors[li.backsecnum].floorheight) {
			// temp.h.intbits = openbottom >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, openbottom);
			slope = FixedDiv (temp.w - shootz , dist);
			if (slope > aimslope)
				goto hitline;
		}
		
		if (sectors[li.frontsecnum].ceilingheight != sectors[li.backsecnum].ceilingheight) {
			// temp.h.intbits = opentop >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, opentop);
			slope = FixedDiv (temp.w - shootz , dist);
			if (slope < aimslope)
				goto hitline;
		}

		// shot continues
		return true;
	
	
		// hit line
		  hitline:
		// position a bit closer
		frac = in->frac - FixedDiv (4*FRACUNIT, attackrange.w); // todo can we use intbits and remove fracunit?
		x = trace.x.w + FixedMul (trace.dx.w, frac);
		y = trace.y.w + FixedMul (trace.dy.w, frac);
		z = shootz + FixedMul (aimslope, FixedMul(frac, attackrange.w));



		if (sectors[li.frontsecnum].ceilingpic == skyflatnum) {
			// don't shoot the sky!
			// temp.h.intbits = sectors[li.frontsecnum].ceilingheight >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  sectors[li.frontsecnum].ceilingheight);
			if (z > temp.w) {
				return false;
			}
			// it's a sky hack wall
			if (li.backsecnum != SECNUM_NULL && sectors[li.backsecnum].ceilingpic == skyflatnum) {
				return false;
			}
		}

		// Spawn bullet puffs.
		P_SpawnPuff (x,y,z);
	
		// don't go any farther
		return false;	
    }
	 
    // shoot a thing
    thRef = in->d.thingRef;
	th = (mobj_t*)&thinkerlist[thRef].data;
	if (th == shootthing) {
		return true;		// can't shoot self
	}



	if (!(th->flags&MF_SHOOTABLE)) {
		return true;		// corpse or something
	}

    // check angles to see if the thing can be aimed at
    dist = FixedMul (attackrange.w, in->frac);
    thingtopslope = FixedDiv (th->z+th->height.w - shootz , dist);

	

    if (thingtopslope < aimslope)
		return true;		// shot over the thing

    thingbottomslope = FixedDiv (th->z - shootz, dist);

    if (thingbottomslope > aimslope)
		return true;		// shot under the thing

    
    // hit thing
    // position a bit closer
    frac = in->frac - FixedDiv (10*FRACUNIT, attackrange.w); // todo can we use intbits and remove fracunit?

    x = trace.x.w + FixedMul (trace.dx.w, frac);
    y = trace.y.w + FixedMul (trace.dy.w, frac);
    z = shootz + FixedMul (aimslope, FixedMul(frac, attackrange.w));

    // Spawn bullet puffs or blod spots,
    // depending on target type.
	if (th->flags & MF_NOBLOOD)
		P_SpawnPuff (x,y,z);
    else
		P_SpawnBlood (x,y,z, la_damage);

    if (la_damage)
		P_DamageMobj (th, shootthing, shootthing, la_damage);

    // don't go any farther
    return false;
	
}

extern int setval;
//
// P_AimLineAttack
//
fixed_t
P_AimLineAttack
( mobj_t*	t1,
  fineangle_t	angle,
  int16_t	distance16
	)
{
    fixed_t_union	x2;
	fixed_t_union	y2;
	fixed_t_union	x;
	fixed_t_union	y;
	fixed_t_union t1height;
	fixed_t_union distance;
	boolean ischainsaw = distance16 & CHAINSAW_FLAG;
	
    shootthing = t1;
	distance16 &= (CHAINSAW_FLAG-1);

	x.w = t1->x;
	y.w = t1->y;
    
	//todo re-enable?
    //x2.w = x.w + FixedMul1616(distance16,finecosine(angle));
    //y2.w = y.w + FixedMul1616(distance16,finesine(angle));

	x2.w = x.w + FixedMulBig1632(distance16,finecosine(angle));
	y2.w = y.w + FixedMulBig1632(distance16,finesine(angle));

	t1height.h.fracbits = 0;
	t1height.h.intbits = (t1->height.h.intbits >> 1) + 8;
    shootz = t1->z + t1height.w;

    // can't shoot outside view angles
    topslope = 100*FRACUNIT/160;	
    bottomslope = -100*FRACUNIT/160;
    
	distance.h.fracbits = ischainsaw ? 1 : 0;
	distance.h.intbits = distance16;
    attackrange = distance;
    linetarget = NULL;
	
	//setval = 1;

    P_PathTraverse ( x, y,
		     x2, y2,
		     PT_ADDLINES|PT_ADDTHINGS,
		     PTR_AimTraverse );
		


	if (linetarget) {

		return aimslope;
	}

    return 0;
}
 

//
// P_LineAttack
// If damage == 0, it is just a test trace
// that will leave linetarget set.
//
void
P_LineAttack
(mobj_t* t1,
  fineangle_t	angle,
	int16_t	distance16,
  fixed_t	slope,
  int16_t		damage )
{
    fixed_t_union	x2;
	fixed_t_union	y2;
	
	fixed_t_union	x;
	fixed_t_union	y;
	fixed_t_union	distance;
	boolean ischainsaw = distance16 & CHAINSAW_FLAG; //sigh... look into why this needs to be here, remove if at all possible - sq
	fixed_t_union t1height;
	x.w = t1->x;
	y.w = t1->y;
	distance16 &= (CHAINSAW_FLAG-1);
	shootthing = t1;
    la_damage = damage;
    //x2.w = x.w + FixedMul1616(distance16,finecosine(angle));
    //y2.w = y.w + FixedMul1616(distance16,finesine(angle));
	x2.w = x.w + FixedMulBig1632(distance16,finecosine(angle));
	y2.w = y.w + FixedMulBig1632(distance16,finesine(angle));

	t1height.h.fracbits = 0;
	t1height.h.intbits = (t1->height.h.intbits >> 1) + 8;
	shootz = t1->z + t1height.w;

	distance.h.intbits = distance16;
	distance.h.fracbits = ischainsaw ? 1 : 0;
	attackrange = distance;
    aimslope = slope;
	

    P_PathTraverse ( x, y,
		     x2, y2,
		     PT_ADDLINES|PT_ADDTHINGS,
		     PTR_ShootTraverse );

}
 


//
// USE LINES
//

boolean	PTR_UseTraverse (intercept_t* in)
{
    int16_t		side;

	line_t line = lines[in->d.linenum];
	if (!line.special) {
		P_LineOpening (line.sidenum[1], line.frontsecnum, line.backsecnum);
		if (openrange <= 0)
		{
			S_StartSoundFromRef (playerMobj, sfx_noway);
	    
			// can't use through a wall
			return false;	
		}
		// not a special line, but keep checking
		return true ;		
    }
	
    side = 0;

	if (P_PointOnLineSide(playerMobj->x, playerMobj->y, line.dx, line.dy, line.v1Offset & VERTEX_OFFSET_MASK) == 1) {
		side = 1;
	}
    
    //	return false;		// don't use back side
    P_UseSpecialLine (playerMobj, in->d.linenum, side, playerMobjRef);

    // can't use for than one special line in a row
    return false;
}


//
// P_UseLines
// Looks for special lines in front of the player to activate.
//
void P_UseLines () 
{
    fineangle_t angle;
    fixed_t_union	x1;
	fixed_t_union	y1;
	fixed_t_union	x2;
	fixed_t_union	y2;
		
    angle = playerMobj->angle >> ANGLETOFINESHIFT;

    x1.w = playerMobj->x;
    y1.w = playerMobj->y;
    // todo replace with bit shift? - sq
	x2.w = x1.w + (USERANGE)*finecosine(angle);
	y2.w = y1.w + (USERANGE)*finesine(angle);
    P_PathTraverse ( x1, y1, x2, y2, PT_ADDLINES, PTR_UseTraverse );
}


//
// RADIUS ATTACK
//
mobj_t*		bombsource;
mobj_t*		bombspot;
int16_t		bombdamage;


//
// PIT_RadiusAttack
// "bombsource" is the creature
// that caused the explosion at "bombspot".
//
boolean PIT_RadiusAttack (THINKERREF thingRef, mobj_t*	thing)
{
    fixed_t	dx;
    fixed_t	dy;
    fixed_t_union	dist;

	
	if (!(thing->flags & MF_SHOOTABLE)) {
		return true;
	}
    // Boss spider and cyborg
    // take no damage from concussion.
	if (thing->type == MT_CYBORG || thing->type == MT_SPIDER) {
		return true;
	}


    dx = labs(thing->x - bombspot->x);
    dy = labs(thing->y - bombspot->y);
    
    dist.w = dx>dy ? dx : dy;
    dist.h.intbits = (dist.h.intbits - thing->radius ) ;

	if (dist.h.intbits < 0) {
		dist.h.intbits = 0;
	}

	if (dist.h.intbits >= bombdamage) {
		return true;	// out of range
	}

    if ( P_CheckSight (thing, bombspot) ) {
		// must be in direct path

//		if (thing == 0) {
//			I_Error("bad thing caught d");
//		}

		P_DamageMobj (thing, bombspot, bombsource, bombdamage - dist.h.intbits);
    }
    
    return true;
}


//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//
void
P_RadiusAttack
(mobj_t* spot,
	mobj_t* source,
	int16_t		damage)
{
	int16_t		x;
	int16_t		y;

	int16_t		xl;
	int16_t		xh;
	int16_t		yl;
	int16_t		yh;
	fixed_t_union pos;
	
	pos.w = spot->y;
	yh = (pos.h.intbits + damage - bmaporgy) >> MAPBLOCKSHIFT;
	yl = (pos.h.intbits - damage - bmaporgy) >> MAPBLOCKSHIFT;
	pos.w = spot->x;
	xh = (pos.h.intbits + damage - bmaporgx) >> MAPBLOCKSHIFT;
	xl = (pos.h.intbits - damage - bmaporgx) >> MAPBLOCKSHIFT;
	bombspot = spot;
	bombsource = source;
	bombdamage = damage;


	if (xl < 0) xl = 0;
	if (yl < 0) yl = 0;
	if (xh >= bmapwidth) xh = bmapwidth - 1;
	if (yh >= bmapheight) yh = bmapheight - 1;
	for (y = yl; y <= yh; y++) {
		for (x = xl; x <= xh; x++) {
			P_BlockThingsIterator(x, y, PIT_RadiusAttack);
		}
	}



}



//
// SECTOR HEIGHT CHANGING
// After modifying a sectors floor or ceiling height,
// call this routine to adjust the positions
// of all things that touch the sector.
//
// If anything doesn't fit anymore, true will be returned.
// If crunch is true, they will take damage
//  as they are being crushed.
// If Crunch is false, you should set the sector height back
//  the way it was and call P_ChangeSector again
//  to undo the changes.
//
boolean		crushchange;
boolean		nofit;

extern mobj_t* setStateReturn;

//
// PIT_ChangeSector
//
boolean PIT_ChangeSector (THINKERREF thingRef, mobj_t*	thing)
{
    mobj_t*	mo;
	THINKERREF moRef;

    if (P_ThingHeightClip (thing)) {
		// keep checking
		return true;
    }
    

    // crunch bodies to giblets
    if (thing->health <= 0) {
		P_SetMobjState (thing, S_GIBS);
		thing = setStateReturn;
		thing->flags &= ~MF_SOLID;
		thing->height.w = 0;
		thing->radius = 0;

		// keep checking
		return true;		
    }

    // crunch dropped items
    if (thing->flags & MF_DROPPED) {
		P_RemoveMobj (thing);
	
		// keep checking
		return true;		
    }

    if (! (thing->flags & MF_SHOOTABLE) ) {
	// assume it is bloody gibs or something
		return true;			
    }
    
    nofit = true;
	
    if (crushchange && !(leveltime.w &3) ) {

		P_DamageMobj(thing,NULL_THINKERREF,NULL_THINKERREF,10);

		// spray blood in a random direction
		moRef = P_SpawnMobj (thing->x, thing->y, thing->z + thing->height.w/2, MT_BLOOD);
		
		mo = setStateReturn;
		mo->momx = (P_Random() - P_Random ())<<12;
		mo->momy = (P_Random() - P_Random ())<<12;
    }

    // keep checking (crush other things)	
    return true;	
}



//
// P_ChangeSector
//
boolean
P_ChangeSector
( sector_t*	sector,
  boolean	crunch )
{
    int16_t		x;
    int16_t		y;
	int16_t*	sectorBlockBoxes = Z_LoadBytesFromEMS(sectorBlockBoxesRef);
	uint16_t secnumx4 = 4*(sector - sectors);
	int16_t xl = sectorBlockBoxes[secnumx4 + BOXLEFT];
	int16_t xh = sectorBlockBoxes[secnumx4 + BOXRIGHT];
	int16_t yh = sectorBlockBoxes[secnumx4 + BOXTOP];
	int16_t yl = sectorBlockBoxes[secnumx4 + BOXBOTTOM];


    nofit = false;
    crushchange = crunch;


	if (xl < 0) xl = 0;
	if (yl < 0) yl = 0;
	if (xh >= bmapwidth) xh = bmapwidth - 1;
	if (yh >= bmapheight) yh = bmapheight - 1;
    // re-check heights for all things near the moving sector
	for (x = xl; x <= xh; x++) {
		for (y = yl; y <= yh; y++) {
				P_BlockThingsIterator(x, y, PIT_ChangeSector); {
			}
		}
	}
	
	
    return nofit;
}

