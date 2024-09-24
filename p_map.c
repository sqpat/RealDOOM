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
#include "m_memory.h"
#include "m_near.h"



//
// TELEPORT MOVE
// 

//
// PIT_StompThing
//
/*
int16_t __near R_PointOnSide2 ( fixed_t_union x, fixed_t_union y, int16_t nodenum){
	node_t __far* node = &nodes[nodenum];

    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t_union	left;
    fixed_t_union	right;
    fixed_t_union temp;
    
	temp.h.fracbits = 0;
	
    if (!node->dx) {
        temp.h.intbits = node->x;
        if (x.w <= temp.w)
            return node->dy > 0;
        
        return node->dy < 0;
    }
    if (!node->dy) {
        temp.h.intbits = node->y;
        if (y.w <= temp.w)
            return node->dx < 0;
        
        return node->dx > 0;
    }
    temp.h.intbits = node->x;
    dx.w = (x.w - temp.w);
    temp.h.intbits = node->y;
    dy.w = (y.w - temp.w);
	
    // Try to quickly decide by looking at sign bits.
    if ( (node->dy ^ node->dx ^ dx.h.intbits ^ dy.h.intbits)&(int16_t)0x8000 ) {
        if  ( (node->dy ^ dx.h.intbits) &(int16_t) 0x8000 ) {
	        // (left is negative)
	        return 1;
	    }
	    return 0;
    }

    left.w = FixedMul1632 ( node->dy , dx.w );
    right.w = FixedMul1632 (node->dx, dy.w );
	
    if (right.w < left.w) {
	    // front side
	    return 0;
    }
    // back side
    return 1;			
}

int16_t __near R_PointOnSide3 ( fixed_t_union x, fixed_t_union y, int16_t nodenum);
int16_t __near R_PointOnSide2 ( fixed_t_union x, fixed_t_union y, int16_t nodenum);

int16_t __near R_PointOnSide ( fixed_t_union x, fixed_t_union y, int16_t nodenum){
	int16_t a = R_PointOnSide2(x, y, nodenum);
	int16_t b = R_PointOnSide3(x, y, nodenum);
	a = nodes[nodenum].children[a];
	if (a != b){
		I_Error("bad! %i %x %i %x %lx %lx %i %x %x %x %x %x %x", a, a, b, b, x, y, nodenum
		, nodes[nodenum].x
		, nodes[nodenum].y
		, nodes[nodenum].dx
		, nodes[nodenum].dy
		, nodes[nodenum].children[0]
		, nodes[nodenum].children[1]
		);
	}
	return a;
}
*/

fixed_t __near R_GetAttackRangeMult(int16_t range, fixed_t frac){

	switch (range){
		case MISSILERANGE:
			// todo byte swaps
			return frac << 11; 
		case HALFMISSILERANGE:
			// todo byte swaps
			return frac << 10; 
		case MELEERANGE:
			// todo byte swaps
			return frac << 6; 
		case CHAINSAWRANGE:
			// todo this can probably be a sum of two shifts.
			return FixedMulBig1632 (CHAINSAWRANGE, frac);
	}
	return 0;  // shouldnt ever happen?
}

//
// R_PointInSubsector
//
int16_t __near R_PointInSubsector ( fixed_t_union	x, fixed_t_union	y ) {
    int16_t		nodenum;
    // single subsector is a special case
	if (!numnodes) {
		return 0;
	}
		
	nodenum = numnodes - 1;
	while (! (nodenum & NF_SUBSECTOR) ) {
		// only used here... inline?
		nodenum = R_PointOnSide (x, y, nodenum);

    }

	return nodenum & ~NF_SUBSECTOR;
}



boolean __near  PIT_StompThing (THINKERREF thingRef, mobj_t __far*	thing, mobj_pos_t __far* thing_pos)
{
    fixed_t_union	blockdist;

    if (!(thing_pos->flags1 & MF_SHOOTABLE) )
		return true;
		
    blockdist.h.intbits = thing->radius + tmthing->radius;
	blockdist.h.fracbits = 0;
    
    if ( labs(thing_pos->x.w - tmx.w) >= blockdist.w
	 || labs(thing_pos->y.w - tmy.w) >= blockdist.w )
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


boolean DoBlockmapLoop(int16_t xl, int16_t yl, int16_t xh, int16_t yh, boolean __near(*   func )(THINKERREF, mobj_t __far*, mobj_pos_t __far*) , int8_t returnOnFalse){
	int16_t by;
	if (xl < 0) xl = 0;
	if (yl < 0) yl = 0;
	if (xh >= bmapwidth) xh = bmapwidth - 1;
	if (yh >= bmapheight) yh = bmapheight - 1;

	for (; xl <= xh; xl++) {
		for (by = yl; by <= yh; by++) {
			if (!P_BlockThingsIterator(xl, by, func)) {
				if (returnOnFalse)
					return false;
			}
		}
	}

    return true;
}

//
// P_TeleportMove
//
boolean __near P_TeleportMove (mobj_t __far* thing,mobj_pos_t __far* thing_pos,fixed_t_union	x,fixed_t_union	y, int16_t oldsecnum){
    int16_t			xl;
    int16_t			xh;
    int16_t			yl;
    int16_t			yh;
    
	 
	
	fixed_t_union temp;
	temp.h.fracbits = 0;
    // kill anything occupying the position
	tmthing = thing;
	tmthing_pos = thing_pos;
	tmflags1 = thing_pos->flags1;

    tmx = x;
    tmy = y;
	// todo imrpove how to do the minus cases? can underflow happen?
	tmbbox[BOXTOP] = y; 
	tmbbox[BOXTOP].h.intbits += tmthing->radius;
	temp.h.intbits = tmthing->radius;
	tmbbox[BOXBOTTOM].w = y.w - temp.w;
	tmbbox[BOXRIGHT] = x; 
	tmbbox[BOXRIGHT].h.intbits += tmthing->radius;
	tmbbox[BOXLEFT].w = x.w - temp.w;
//	newsubsecnum = R_PointInSubsector (x,y);
//	newsubsecsecnum = oldsecnum;  subsectors[newsubsecnum].secnum;
    ceilinglinenum = -1;
    
    // The base floor/ceiling is from the subsector
    // that contains the point.
    // Any contacted lines the step closer together
    // will adjust them.
	tmfloorz = tmdropoffz = sectors[oldsecnum].floorheight;
    tmceilingz = sectors[oldsecnum].ceilingheight;
			
    validcount++;
    numspechit = 0;
    
    // stomp on any things contacted
    xl = (tmbbox[BOXLEFT].h.intbits - bmaporgx - MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;
    xh = (tmbbox[BOXRIGHT].h.intbits - bmaporgx + MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;
    yl = (tmbbox[BOXBOTTOM].h.intbits - bmaporgy - MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;
    yh = (tmbbox[BOXTOP].h.intbits - bmaporgy + MAXRADIUSNONFRAC)>> MAPBLOCKSHIFT;

 
	if (!DoBlockmapLoop(xl, yl, xh, yh, PIT_StompThing, true)){
		return false;
	}	

    
    // the move is ok,
    // so link the thing into its new position
	P_UnsetThingPosition (thing, thing_pos);

    thing->floorz = tmfloorz;
    thing->ceilingz = tmceilingz;	
	thing_pos->x = x;
	thing_pos->y = y;

    P_SetThingPosition (thing, thing_pos, oldsecnum);
	
    return true;
}


//
// MOVEMENT ITERATOR FUNCTIONS
//


//
// PIT_CheckLine
// Adjusts tmfloorz and tmceilingz as lines are contacted
//
boolean __near PIT_CheckLine (line_physics_t __far* ld_physics, int16_t linenum) {
	line_t __far* ld = &lines[linenum];
	slopetype_t lineslopetype = ld_physics->v2Offset & LINE_VERTEX_SLOPETYPE;
	int16_t linedx = ld_physics->dx;
	int16_t linedy = ld_physics->dy;
	vertex_t v1 = vertexes[ld_physics->v1Offset];
	int16_t v1x = v1.x;
	int16_t v1y = v1.y;
	int16_t lineright = v1x;
	int16_t lineleft = v1x;
	int16_t linetop = v1y;
	int16_t linebot = v1y;
	uint8_t flags;

#ifndef	PRECALCULATE_OPENINGS
	int16_t linefrontsecnum = ld_physics->frontsecnum;
	int16_t linebacksecnum = ld_physics->backsecnum;
	
	int16_t lineside1 = ld->sidenum[1];
#endif
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


	if (P_BoxOnLineSide(lineslopetype, linedx, linedy, v1x, v1y) != -1) {
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

	if (ld_physics->backsecnum == SECNUM_NULL) {
		return false;		// one sided line
	}
	flags = lineflagslist[linenum];


    if (!(tmthing_pos->flags2 & MF_MISSILE) ) {
		if (flags & ML_BLOCKING) {
			return false;	// explicitly blocking everything
		}
		if (tmthing->type != MT_PLAYER && flags & ML_BLOCKMONSTERS) {
			return false;	// block monsters only
		}
    }

    // set openrange, opentop, openbottom
#ifdef	PRECALCULATE_OPENINGS
	P_LoadLineOpening(linenum);
#else
	P_LineOpening (lineside1, linefrontsecnum, linebacksecnum);
#endif
	
    // adjust floor / ceiling heights
    if (lineopening.opentop < tmceilingz) {
		tmceilingz = lineopening.opentop;
		ceilinglinenum = linenum;
    } 

	if (lineopening.openbottom > tmfloorz) {
		tmfloorz = lineopening.openbottom;
	}

	if (lineopening.lowfloor < tmdropoffz) {
		tmdropoffz = lineopening.lowfloor;
	}

    // if contacted a special line, add it to the list
    if (ld_physics->special) {
		spechit[numspechit] = linenum;
		numspechit++;
    }

    return true;
}

//
// PIT_CheckThing
//
boolean __near PIT_CheckThing (THINKERREF thingRef, mobj_t __far*	thing, mobj_pos_t __far* thing_pos)
{
    fixed_t_union blockdist;
    boolean		solid;
    int16_t			damage;
	mobj_t __far* tmthingTarget;
	mobjtype_t tmthingTargettype;
	mobjtype_t thingtype;
	THINKERREF tmthingtargetRef;
	int16_t thingflags1;
	fixed_t_union thingx;
	fixed_t_union thingy;
	fixed_t_union thingz;
	fixed_t_union tmthingz;
	fixed_t_union tmthingheight;
	fixed_t_union thingheight;
	fixed_t_union thingradius;
	// don't clip against self
	//todoaddr inline later
	uint8_t (__far  * getDamage)(uint8_t) = getDamageAddr;

	if (thing == tmthing) {
		return true;
	}

	thingflags1 = thing_pos->flags1;

	if (!(thingflags1 & (MF_SOLID | MF_SPECIAL | MF_SHOOTABLE))) {
			return true;
	}
	thingtype = thing->type;
	thingx = thing_pos->x;
	thingy = thing_pos->y;
	thingz = thing_pos->z;
	thingheight = thing->height;
	thingradius.h.intbits = thing->radius;
	thingradius.h.fracbits = 0;


	
	thingradius.h.intbits += tmthing->radius;
	blockdist = thingradius;

    if ( labs(thingx.w - tmx.w) >= blockdist.w || labs(thingy.w - tmy.w) >= blockdist.w ) {
		// didn't hit it
			return true;
    }
	tmthingheight = tmthing->height;
	tmthingz = tmthing_pos->z;
	tmthingtargetRef = tmthing->targetRef;


    // check for skulls slamming into things
    if (tmthing_pos->flags2 & MF_SKULLFLY) {
		damage = ((P_Random()%8)+1)*getDamage(tmthing->type);
		P_DamageMobj (thing, tmthing, tmthing, damage);
		tmthing_pos->flags2 &= ~MF_SKULLFLY;
		tmthing->momx.w = tmthing->momy.w = tmthing->momz.w = 0;
	
		P_SetMobjState (tmthing, mobjinfo[tmthing->type].spawnstate);

		return false;		// stop moving
    }
	
    // missiles can hit other things
    if (tmthing_pos->flags2 & MF_MISSILE) {
		// see if it went over / under
		if (tmthingz.w > thingz.w + thingheight.w) {
			return true;		// overhead
		}
		if (tmthingz.w + tmthingheight.w < thingz.w) {
			return true;		// underneath
		}
		tmthingTarget = (mobj_t __far*)&thinkerlist[tmthingtargetRef].data;
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
		if (! (thingflags1 & MF_SHOOTABLE) ) {
			// didn't do any damage
			return !(thingflags1 & MF_SOLID);
		}
	
		// damage / explode
		damage = ((P_Random()%8)+1)*getDamage(tmthing->type);
		

		P_DamageMobj (thing, tmthing, tmthingTarget, damage);

		// don't traverse any more
		return false;				
    }
    
    // check for special pickup
    if (thingflags1 & MF_SPECIAL) {
		solid = thingflags1 &MF_SOLID;
		if (tmflags1&MF_PICKUP) {
			//I_Error("%i %i %i", players.moRef, tmthingRef, thingRef);
			// can remove thing
			P_TouchSpecialThing (thing, tmthing, thing_pos, tmthing_pos);
		}
		return !solid;
    }

    return !(thingflags1 & MF_SOLID);
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

boolean __near P_CheckPosition (mobj_t __far* thing, fixed_t_union	x, fixed_t_union	y, int16_t oldsecnum )
{
    int16_t			xl;
    int16_t			xh;
    int16_t			yl;
    int16_t			yh;
	int16_t			by;
	fixed_t_union	temp;
	int16_t_union   blocktemp;
	int16_t xl2, xh2, yl2, yh2;
	temp.h.fracbits = 0;
    tmthing = thing;
	tmthing_pos = GET_MOBJPOS_FROM_MOBJ(tmthing);
	tmflags1 = tmthing_pos->flags1;
    tmx = x;
    tmy = y;
 

	
	// todo imrpove how to do the minus cases? can underflow happen?
	// todo can this move down
	tmbbox[BOXTOP] = y;
	tmbbox[BOXTOP].h.intbits += thing->radius;
	temp.h.intbits = thing->radius;
	tmbbox[BOXBOTTOM].w = y.w - temp.w;
	tmbbox[BOXRIGHT] = x;
	tmbbox[BOXRIGHT].h.intbits += thing->radius;
	tmbbox[BOXLEFT].w = x.w - temp.w;


	if (oldsecnum != -1) {
		lastcalculatedsector = oldsecnum;
	}
	else {
		int16_t newsubsecnum = R_PointInSubsector(x, y);
		lastcalculatedsector = subsectors[newsubsecnum].secnum;
	}


	ceilinglinenum = -1;
    
    // The base floor / ceiling is from the subsector
    // that contains the point.
    // Any contacted lines the step closer together
    // will adjust them.
	tmfloorz = tmdropoffz = sectors[lastcalculatedsector].floorheight;
    tmceilingz = sectors[lastcalculatedsector].ceilingheight;
	

    validcount++;
    numspechit = 0;

	if (tmflags1 & MF_NOCLIP) {
		return true;
	}

    // Check things first, possibly picking things up.
    // The bounding box is extended by MAXRADIUS
    // because mobj_ts are grouped into mapblocks
    // based on their origin point, and can overlap
    // into adjacent blocks by up to MAXRADIUS units.

	// very similar xl, xh, etc values are used in the two following loops.
	// the only difference is we add or subtract 32 (for radius) before we shift 7 to divide by 128.
	// we are doing quick checks to determine if the radius plus/minus makes this block different and storing the diff.


	blocktemp.h = (tmbbox[BOXLEFT].h.intbits - bmaporgx - MAXRADIUSNONFRAC);
	xl2 = (blocktemp.h & 0x0060) == 0x0060 ? 1 : 0; // if 64 and 32 bit are set then we subtracted from one 128 aligned block down. add 1 later
	//xl = ((int16_t)blocktemp.b.bytelow << 1) + (blocktemp.b.bytehigh & 0x80 ? 1 : 0); // messy math to avoid shift 7
	xl = blocktemp.h >> MAPBLOCKSHIFT;
	xl2 += xl;
	blocktemp.h = (tmbbox[BOXRIGHT].h.intbits - bmaporgx + MAXRADIUSNONFRAC);
	xh2 = blocktemp.h & 0x0060 ? 0 : -1; // if niether 64 nor 32 bit are set then we added from one 128 aligned block up. sub 1 later
//	xh = ((int16_t)blocktemp.b.bytelow << 1) + (blocktemp.b.bytehigh & 0x80 ? 1 : 0);
	xh = blocktemp.h >> MAPBLOCKSHIFT;
	xh2 += xh;
	blocktemp.h = (tmbbox[BOXBOTTOM].h.intbits - bmaporgy - MAXRADIUSNONFRAC);
	yl2 = (blocktemp.h & 0x0060) == 0x0060 ? 1 : 0;
	//yl = ((int16_t)blocktemp.b.bytelow << 1) + (blocktemp.b.bytehigh & 0x80 ? 1 : 0);
	yl = blocktemp.h >> MAPBLOCKSHIFT;
	yl2 += yl;
	blocktemp.h = (tmbbox[BOXTOP].h.intbits - bmaporgy + MAXRADIUSNONFRAC);
	yh2 = blocktemp.h & 0x0060 ? 0 : -1;
	//yh = ((int16_t)blocktemp.b.bytelow << 1) + (blocktemp.b.bytehigh & 0x80 ? 1 : 0);
	yh = blocktemp.h >> MAPBLOCKSHIFT;
	yh2 += yh;


 
	
	if (!DoBlockmapLoop(xl, yl, xh, yh, PIT_CheckThing, true)){
		return false;
	}	

	 

	if (xl2 < 0) xl2 = 0;
	if (yl2 < 0) yl2 = 0;
	if (xh2 >= bmapwidth) xh2 = bmapwidth - 1;
	if (yh2 >= bmapheight) yh2 = bmapheight - 1;
 
	for (; xl2 <= xh2; xl2++) {
		for (by = yl2; by <= yh2; by++) {


			if (!P_BlockLinesIterator(xl2, by, PIT_CheckLine)) {

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
boolean __near P_TryMove (mobj_t __far* thing, mobj_pos_t __far* thing_pos, fixed_t_union	x, fixed_t_union	y ) {
    fixed_t_union	oldx;
    fixed_t_union	oldy;
	fixed_t_union	newx;
	fixed_t_union	newy;


	fixed_t_union temp;
	int16_t temp2;
	temp.h.fracbits = 0;

	floatok = false;

	if (!P_CheckPosition(thing, x, y, -1)) {
		return false;		// solid wall or thing
	}
    if ( !(thing_pos->flags1 & MF_NOCLIP) ) {
		temp2 = (tmceilingz - tmfloorz);
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
//		if (temp.w < thing->height.w) { 
		if (temp.h.intbits < thing->height.h.intbits) { // 16 bit logic handles the fractional fine
			return false;	// doesn't fit
		}

		floatok = true;
		
		// temp.h.intbits = tmceilingz >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, tmceilingz);
		if (!(thing_pos->flags1&MF_TELEPORT) && temp.w - thing_pos->z.w < thing->height.w) {
			return false;	// mobj must lower itself to fit
		}
		// temp.h.intbits = tmfloorz >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, tmfloorz);
		if (!(thing_pos->flags1&MF_TELEPORT) && (temp.w - thing_pos->z.w) > 24 * FRACUNIT) {
			return false;	// too big a step up
		}

		if (!(thing_pos->flags1&(MF_DROPOFF | MF_FLOAT)) && (tmfloorz - tmdropoffz) > (24<<SHORTFLOORBITS) ) {
			return false;	// don't stand over a dropoff
		}
		

    }

    // the move is ok,
    // so link the thing into its new position
	P_UnsetThingPosition (thing, thing_pos);

    oldx = thing_pos->x;
    oldy = thing_pos->y;
    thing->floorz = tmfloorz;
    thing->ceilingz = tmceilingz;	
	thing_pos->x = x;
	thing_pos->y = y;


	// we calculated the sector above in checkposition, now it's cached.
	P_SetThingPosition (thing, thing_pos, lastcalculatedsector);


	newx = thing_pos->x;
	newy = thing_pos->y;
    
	// if any special lines were hit, do the effect
    if (! (thing_pos->flags1&(MF_TELEPORT|MF_NOCLIP)) ) {
		int16_t v1x;
		int16_t v1y;
		int16_t lddx;
		int16_t lddy;
		int16_t ldspecial;
		int16_t ldv1Offset;
		int16_t	side;
		int16_t	oldside;
		line_physics_t __far* ld_physics;
		while (numspechit--) {
			// see if the line was crossed
			ld_physics = &lines_physics[spechit[numspechit]];
			lddx = ld_physics->dx;
			lddy = ld_physics->dy;
			ldv1Offset = ld_physics->v1Offset;
			v1x = vertexes[ldv1Offset].x;
			v1y = vertexes[ldv1Offset].y;
			ldspecial = ld_physics->special;

			side = P_PointOnLineSide (newx.w, newy.w, lddx, lddy, v1x, v1y);
			oldside = P_PointOnLineSide (oldx.w, oldy.w, lddx, lddy, v1x, v1y);
			if (side != oldside) {
				if (ldspecial) {
					P_CrossSpecialLine(spechit[numspechit], oldside, thing, thing_pos);
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
boolean __near P_ThingHeightClip (mobj_t __far* thing, mobj_pos_t __far* thing_pos)
{
    boolean		onfloor;
	fixed_t_union temp;
	int16_t temp2;
	temp.h.fracbits = 0;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->floorz);
    onfloor = (thing_pos->z.w == temp.w);


    P_CheckPosition (thing, thing_pos->x, thing_pos->y, thing->secnum);
    // what about stranding a monster partially off an edge?

    thing->floorz = tmfloorz;
    thing->ceilingz = tmceilingz;
	
    if (onfloor) {
		// walking monsters rise and fall with the floor
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->floorz);
		thing_pos->z.w = temp.w;

    } else {
	// don't adjust a floating monster unless forced to
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->ceilingz);
		if (thing_pos->z.w+ thing->height.w > temp.w)
			thing_pos->z.w = temp.w - thing->height.w;
	}

	temp2 = (thing->ceilingz - thing->floorz);
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
	
	if (temp.h.intbits < thing->height.h.intbits) // 16 bit math should be ok
		return false;

    return true;
}




//
// P_HitSlideLine
// Adjusts the xmove / ymove
// so that the next move will slide along the wall.
//
void __near P_HitSlideLine (int16_t linenum)
{
    int16_t			side;

    angle_t		lineangle;
    angle_t		moveangle;
    angle_t		deltaangle;
    
    fixed_t		movelen;
    fixed_t		newlen;
	fixed_t_union zero;
	line_physics_t __far* ld_physics = &lines_physics[linenum];
	zero.w = 0;

    if ((ld_physics->v2Offset&LINE_VERTEX_SLOPETYPE) == ST_HORIZONTAL_HIGH) {
		tmymove.w = 0;
		return;
    }
    
    if ((ld_physics->v2Offset&LINE_VERTEX_SLOPETYPE) == ST_VERTICAL_HIGH) {
		tmxmove.w = 0;
		return;
    }
	
    side = P_PointOnLineSide (playerMobj_pos->x.w, playerMobj_pos->y.w, ld_physics->dx, ld_physics->dy, vertexes[ld_physics->v1Offset].x, vertexes[ld_physics->v1Offset].y);
    lineangle.wu = R_PointToAngle2_16 (ld_physics->dx, ld_physics->dy);

    if (side == 1)
		lineangle.hu.intbits += ANG180_HIGHBITS;

    moveangle.wu = R_PointToAngle2 (zero,zero, tmxmove, tmymove);
    deltaangle.wu = moveangle.wu-lineangle.wu;

    if (deltaangle.wu > ANG180)
		deltaangle.hu.intbits += ANG180_HIGHBITS;
    //	I_Error ("SlideLine: ang>ANG180");

    lineangle.hu.intbits = (lineangle.hu.intbits >> 1) & 0xFFFC;
    deltaangle.hu.intbits = (deltaangle.hu.intbits >> 1) & 0xFFFC;
	
    movelen = P_AproxDistance (tmxmove.w, tmymove.w);
    newlen = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, deltaangle.hu.intbits, movelen);

    tmxmove.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, lineangle.hu.intbits, newlen);
    tmymove.w = FixedMulTrigNoShift(FINE_SINE_ARGUMENT, lineangle.hu.intbits, newlen);
}


//
// PTR_SlideTraverse
//
boolean __near PTR_SlideTraverse (intercept_t __far* in) {
	uint8_t lineflags = lineflagslist[in->d.linenum];
	line_t __far* li = &lines[in->d.linenum];
	fixed_t_union temp;
	line_physics_t __far* li_physics = &lines_physics[in->d.linenum];


    
    if ( ! (lineflags & ML_TWOSIDED) ) {
 		if (P_PointOnLineSide (playerMobj_pos->x.w, playerMobj_pos->y.w, li_physics->dx, li_physics->dy, vertexes[li_physics->v1Offset].x, vertexes[li_physics->v1Offset].y)) {
	    // don't hit the back side
			return true;		
		}
	goto isblocking;
    }

    // set openrange, opentop, openbottom
	temp.h.fracbits = 0;
#ifdef	PRECALCULATE_OPENINGS
	P_LoadLineOpening(in ->d.linenum);
#else
	P_LineOpening (li->sidenum[1], li_physics->frontsecnum, li_physics->backsecnum);
#endif
	
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, (lineopening.opentop - lineopening.openbottom));

    if (temp.h.intbits < playerMobj->height.h.intbits) // 16 bit okay
		goto isblocking;		// doesn't fit
		
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.opentop);
    if (temp.w - playerMobj_pos->z.w < playerMobj->height.w)
		goto isblocking;		// mobj is too high

	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.openbottom);
    if (temp.w - playerMobj_pos->z.w > 24*FRACUNIT )
		goto isblocking;		// too big a step up

    // this line doesn't block movement
    return true;		
	
    // the line does block movement,
    // see if it is closer than best so far
  isblocking:		
    if (in->frac < bestslidefrac.w) {
		//secondslidefrac = bestslidefrac;
		//secondslidelinenum = bestslidelinenum;
		bestslidefrac.w = in->frac;
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
void __near P_SlideMove ()
{
    fixed_t_union		leadx;
	fixed_t_union		leady;
	fixed_t_union		trailx;
	fixed_t_union		traily;
	fixed_t_union		newx;
	fixed_t_union		newy;
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
	leadx = playerMobj_pos->x;
	trailx = playerMobj_pos->x;
	leady = playerMobj_pos->y;
	traily = playerMobj_pos->y;
	if (playerMobj->momx.w > 0) {
		leadx.h.intbits += temp.h.intbits;
		trailx.w -= temp.w;
    } else {
		leadx.w -= temp.w;
		trailx.h.intbits += temp.h.intbits;
    }
	
    if (playerMobj->momy.w > 0) {
		leady.h.intbits += temp.h.intbits;
		traily.w -= temp.w;
    } else {
		leady.w -= temp.w;
		traily.h.intbits += temp.h.intbits;

    } 
		
	bestslidefrac.w = FRACUNIT + 1;

	
 
	temp.w = leadx.w + playerMobj->momx.w;
	temp2.w = leady.w + playerMobj->momy.w;
	P_PathTraverse(leadx, leady, temp, temp2, PT_ADDLINES, PTR_SlideTraverse);
	
	//todo do these mo fields change? if not then pull out momx/momy into locals to avoid extra loads
	temp2.w = leady.w + playerMobj->momy.w;
	temp3.w = trailx.w + playerMobj->momx.w;
	P_PathTraverse(trailx, leady, temp3, temp2, PT_ADDLINES, PTR_SlideTraverse);

	temp.w = leadx.w + playerMobj->momx.w;
	temp4.w = traily.w + playerMobj->momy.w;

	P_PathTraverse(leadx, traily, temp, temp4, PT_ADDLINES, PTR_SlideTraverse);


 
    // move up to the wall

	if (bestslidefrac.w == FRACUNIT+1) {
	// the move most have hit the middle, so stairstep
      stairstep:
		newy = playerMobj_pos->y;
		newy.w += playerMobj->momy.w;
		if (!P_TryMove(playerMobj, playerMobj_pos, playerMobj_pos->x, newy)) {
			newx = playerMobj_pos->x;
			newx.w += playerMobj->momx.w;

			P_TryMove(playerMobj, playerMobj_pos, newx, playerMobj_pos->y);
		}

		return;
    }

    // fudge a bit to make sure it doesn't hit
    bestslidefrac.w -= 0x800;	
    if (bestslidefrac.w > 0) {
		newx.w = FixedMul (playerMobj->momx.w, bestslidefrac.w);
		newx.w += playerMobj_pos->x.w;
		newy.w = FixedMul (playerMobj->momy.w, bestslidefrac.w);
		newy.w += playerMobj_pos->y.w;
		if (!P_TryMove(playerMobj, playerMobj_pos,  newx, newy)) {
			goto stairstep;
		}
    }

 

    // Now continue along the wall.
    // First calculate remainder.

	if (bestslidefrac.hu.fracbits == 0xF800) {
		tmxmove = playerMobj->momx;
		tmymove = playerMobj->momy;
	} else {
		// same as 1 - (this+0x800) 
		bestslidefrac.hu.fracbits += 0x7FF; 
		bestslidefrac.hu.fracbits ^= 0xFFFF;

		tmxmove.w = FixedMul16u32(bestslidefrac.hu.fracbits, playerMobj->momx.w);
		tmymove.w = FixedMul16u32(bestslidefrac.hu.fracbits, playerMobj->momy.w);
	}

    P_HitSlideLine (bestslidelinenum);	// clip the moves

 
	playerMobj->momx = tmxmove;
	playerMobj->momy = tmymove;
	newx = playerMobj_pos->x;
	newx.w += tmxmove.w;
	newy = playerMobj_pos->y;
	newy.w += tmymove.w;

    if (!P_TryMove (playerMobj, playerMobj_pos, newx, newy)) {
		goto retry;
    }
}




//
// PTR_AimTraverse
// Sets linetaget and aimslope when a target is aimed at.
//
boolean __near PTR_AimTraverse (intercept_t __far* in) {
	line_t __far*		li;
	line_physics_t __far*		li_physics;
    mobj_t __far*		th;
	mobj_pos_t __far* th_pos;
    fixed_t		slope;
    fixed_t		thingtopslope;
    fixed_t		thingbottomslope;
    fixed_t		dist;
	fixed_t_union temp;

    if (in->isaline) {
		if (!(lineflagslist[in->d.linenum] & ML_TWOSIDED)) {
			return false;		// stop
		}
		li = &lines[in->d.linenum];
		// Crosses a two sided line.
		// A two sided line will restrict
		// the possible target ranges.
		li_physics = &lines_physics[in->d.linenum];
#ifdef	PRECALCULATE_OPENINGS
		P_LoadLineOpening(in->d.linenum);
#else
		P_LineOpening(li->sidenum[1], li_physics->frontsecnum, li_physics->backsecnum);
#endif


		if (lineopening.openbottom >= lineopening.opentop) {
			return false;		// stop
		}
	
		dist = R_GetAttackRangeMult(attackrange16, in->frac);

		temp.h.fracbits = 0;
		if (sectors[li_physics->frontsecnum].floorheight != sectors[li_physics->backsecnum].floorheight) {
 			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.openbottom);
			slope = FixedDiv (temp.w - shootz.w , dist);
			if (slope > bottomslope)
				bottomslope = slope;
		}
		
		if (sectors[li_physics->frontsecnum].ceilingheight != sectors[li_physics->backsecnum].ceilingheight) {
 			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.opentop);
			slope = FixedDiv (temp.w - shootz.w , dist);
			if (slope < topslope)
				topslope = slope;
		}
		
		if (topslope <= bottomslope) {
			return false;		// stop
		}

		return true;			// shot continues
    }
    
    // shoot a thing
	th = (mobj_t __far*)&thinkerlist[in->d.thingRef].data;
	if (th == shootthing) {
		return true;			// can't shoot self
	}
	th_pos = &mobjposlist[in->d.thingRef];

	if (!(th_pos->flags1&MF_SHOOTABLE)) {
		return true;			// corpse or something
	}
    // check angles to see if the thing can be aimed at
	dist = R_GetAttackRangeMult(attackrange16, in->frac);

    thingtopslope = FixedDiv (th_pos->z.w+th->height.w - shootz.w , dist);

	if (thingtopslope < bottomslope) {
		return true;			// shot over the thing
	}
    thingbottomslope = FixedDiv (th_pos->z.w - shootz.w, dist);

	if (thingbottomslope > topslope) {
		return true;			// shot under the thing
	}
    // this thing can be hit!
    if (thingtopslope > topslope)
		thingtopslope = topslope;
    
    if (thingbottomslope < bottomslope)
		thingbottomslope = bottomslope;
 
	aimslope = (thingtopslope+thingbottomslope)>>1;
	linetarget = th;
	linetarget_pos = th_pos;
    return false;			// don't go any farther
}


//
// PTR_ShootTraverse
//
boolean __near PTR_ShootTraverse (intercept_t __far* in)
{
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
    fixed_t		frac;
    
	line_t		 __far* li;
	line_physics_t __far*		li_physics;
    
	mobj_t __far*		th;
	mobj_pos_t __far*		th_pos;

    fixed_t		slope;
    fixed_t		dist;
    fixed_t		thingtopslope;
    fixed_t		thingbottomslope;
	THINKERREF		thRef;
	fixed_t_union temp;
	temp.h.fracbits = 0;

    if (in->isaline) {
		uint8_t lineflags = lineflagslist[in->d.linenum];
		li = &lines[in->d.linenum];
		li_physics = &lines_physics[in->d.linenum];
		if (li_physics->special)
			P_ShootSpecialLine (shootthing, in->d.linenum);

		if ( !(lineflags & ML_TWOSIDED) )
			goto hitline;
	
		// crosses a two sided line
#ifdef	PRECALCULATE_OPENINGS
		P_LoadLineOpening(in->d.linenum);
#else
		P_LineOpening(li->sidenum[1], li_physics->frontsecnum, li_physics->backsecnum);
#endif

		dist = R_GetAttackRangeMult(attackrange16, in->frac);

		if (sectors[li_physics->frontsecnum].floorheight != sectors[li_physics->backsecnum].floorheight) {
 			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.openbottom);
			slope = FixedDiv (temp.w - shootz.w , dist);
			if (slope > aimslope)
				goto hitline;
		}
		
		if (sectors[li_physics->frontsecnum].ceilingheight != sectors[li_physics->backsecnum].ceilingheight) {
 			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.opentop);
			slope = FixedDiv (temp.w - shootz.w , dist);
			if (slope < aimslope)
				goto hitline;
		}

		// shot continues
		return true;
	
	
		// hit line
		  hitline:
		// position a bit closer

			// 0x40000L / attackrange16 hardcoded

			//frac = in->frac - FixedDivWholeAB2 (4, attackrange16); 

			switch (attackrange16){
				case MISSILERANGE:
					frac = in->frac - 128;
					break;
					// todo are non missilerange cases possible?
				case HALFMISSILERANGE:
					frac = in->frac - 256;
					break;
				case MELEERANGE:
					frac = in->frac - 4096;
					break;
				case MELEERANGE + 1:
					frac = in->frac - 4095;
					break;
			}



		x = trace.x.w + FixedMul (trace.dx.w, frac);
		y = trace.y.w + FixedMul (trace.dy.w, frac);
		z = shootz.w  + FixedMul (aimslope, R_GetAttackRangeMult(attackrange16, frac));

			if (sectors[li_physics->frontsecnum].ceilingpic == skyflatnum) {
				// don't shoot the sky!
				SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  sectors[li_physics->frontsecnum].ceilingheight);
				if (z > temp.w) {
					return false;
				}
				// it's a sky hack wall
				if (li_physics->backsecnum != SECNUM_NULL && sectors[li_physics->backsecnum].ceilingpic == skyflatnum) {
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
	th = (mobj_t __far*)&thinkerlist[thRef].data;
	if (th == shootthing) {
		return true;		// can't shoot self
	}
	th_pos = &mobjposlist[thRef];


	if (!(th_pos->flags1&MF_SHOOTABLE)) {
		return true;		// corpse or something
	}

    // check angles to see if the thing can be aimed at
	dist = R_GetAttackRangeMult(attackrange16, in->frac);
    thingtopslope = FixedDiv (th_pos->z.w+th->height.w - shootz.w , dist);



    if (thingtopslope < aimslope)
		return true;		// shot over the thing

    thingbottomslope = FixedDiv (th_pos->z.w - shootz.w, dist);

    if (thingbottomslope > aimslope)
		return true;		// shot under the thing

    
    // hit thing
    // position a bit closer
    //frac = in->frac - FixedDivWholeAB2 (10, attackrange16);

	switch (attackrange16){
			case MISSILERANGE:
			frac = in->frac - 320;
			break;
			case HALFMISSILERANGE:
			frac = in->frac - 640;
			break;
			// todo are non missilerange cases possible?
		case MELEERANGE:
			frac = in->frac - 10240;
			break;
		case MELEERANGE + 1:
			frac = in->frac - 10239;
			break;
	}

    x = trace.x.w + FixedMul (trace.dx.w, frac);
    y = trace.y.w + FixedMul (trace.dy.w, frac);
    z = shootz.w + FixedMul (aimslope, R_GetAttackRangeMult(attackrange16, in->frac));


    // Spawn bullet puffs or blod spots,
    // depending on target type.
	if (th_pos->flags2 & MF_NOBLOOD) {
		P_SpawnPuff(x, y, z);
	}
	else {
		P_SpawnBlood(x, y, z, la_damage);
	}
	if (la_damage) {
		P_DamageMobj(th, shootthing, shootthing, la_damage);
	}
    // don't go any farther
    return false;
	
}

//
// P_AimLineAttack
//
fixed_t __near P_AimLineAttack ( mobj_t __far*	t1, fineangle_t	angle,int16_t	distance16 ) {
    fixed_t_union	x2;
	fixed_t_union	y2;
	fixed_t_union	x;
	fixed_t_union	y;
	mobj_pos_t __far* t1_pos = GET_MOBJPOS_FROM_MOBJ(t1);
	
    shootthing = t1;

	x = t1_pos->x;
	y = t1_pos->y;
    

	// todo: byte swaps for multiples of 8 and add
	switch (distance16) {
		case MISSILERANGE:			
			x2.w = x.w + (finecosine[angle] << 11);
			y2.w = y.w + (finesine[angle] << 11);
			break;
		case HALFMISSILERANGE:
			x2.w = x.w + (finecosine[angle] << 10);
			y2.w = y.w + (finesine[angle] << 10);
			break;
		case MELEERANGE:
			x2.w = x.w + (finecosine[angle] << 6);
			y2.w = y.w + (finesine[angle] << 6);
			break;
		case CHAINSAWRANGE:
			x2.w = x.w + ((finecosine[angle] << 6) + finecosine[angle]);
			y2.w = y.w + ((finesine[angle] << 6) + finesine[angle]);
			break;
    }





	shootz.w = t1_pos->z.w;
	shootz.h.intbits += ((t1->height.h.intbits >> 1) + 8);

    // can't shoot outside view angles
    topslope = 100*FRACUNIT/160;	
    bottomslope = -100*FRACUNIT/160;
    
	attackrange16 = distance16;
    linetarget = NULL;
	linetarget_pos = NULL;

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
void __near P_LineAttack (mobj_t __far* t1, fineangle_t	angle, int16_t	distance16, fixed_t	slope, int16_t	damage ) {
    fixed_t_union	x2;
	fixed_t_union	y2;
	
	fixed_t_union	x;
	fixed_t_union	y;
	mobj_pos_t __far* t1_pos = GET_MOBJPOS_FROM_MOBJ(t1);
	x = t1_pos->x;
	y = t1_pos->y;
	shootthing = t1;
    la_damage = damage;

	// todo: byte swaps for multiples of 8 and add
	switch (distance16) {
		case MISSILERANGE:			
			x2.w = x.w + (finecosine[angle] << 11);
			y2.w = y.w + (finesine[angle] << 11);
			break;
		case HALFMISSILERANGE:
			x2.w = x.w + (finecosine[angle] << 10);
			y2.w = y.w + (finesine[angle] << 10);
			break;
		case MELEERANGE:
			x2.w = x.w + (finecosine[angle] << 6);
			y2.w = y.w + (finesine[angle] << 6);
			break;
		case CHAINSAWRANGE:
			x2.w = x.w + ((finecosine[angle] << 6) + finecosine[angle]);
			y2.w = y.w + ((finesine[angle] << 6) + finesine[angle]);
			break;
    }


	shootz.w = t1_pos->z.w;
	shootz.h.intbits += ((t1->height.h.intbits >> 1) + 8);
	
	attackrange16  = distance16;
    
    aimslope = slope;
	

    P_PathTraverse ( x, y,
		     x2, y2,
		     PT_ADDLINES|PT_ADDTHINGS,
		     PTR_ShootTraverse );

}
 


//
// USE LINES
//

boolean	__near PTR_UseTraverse (intercept_t __far* in) {
    int16_t		side;

	line_physics_t __far* line_physics = &lines_physics[in->d.linenum];

	if (!line_physics->special) {
#ifdef	PRECALCULATE_OPENINGS
		P_LoadLineOpening(in->d.linenum);
#else
		line_t __far* line = &lines[in->d.linenum];
		P_LineOpening(line->sidenum[1], line_physics->frontsecnum, line_physics->backsecnum);
#endif

 		if (lineopening.opentop < lineopening.openbottom)
		{
			S_StartSoundFromRef (playerMobj, sfx_noway);

			// can't use through a wall
			return false;	
		}
		// not a special line, but keep checking
		return true ;		
    }
	
    side = 0;

	if (P_PointOnLineSide(playerMobj_pos->x.w, playerMobj_pos->y.w, line_physics->dx, line_physics->dy, vertexes[line_physics->v1Offset].x, vertexes[line_physics->v1Offset].y) == 1) {
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
void __near P_UseLines ()  {
    fineangle_t angle;
    fixed_t_union	x1;
	fixed_t_union	y1;
	fixed_t_union	x2;
	fixed_t_union	y2;
		
    angle = playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT;

    x1 = playerMobj_pos->x;
    y1 = playerMobj_pos->y;

//	x2.w = x1.w + (USERANGE)*finecosine[angle];
//	y2.w = y1.w + (USERANGE)*finesine[angle];
	x2.w = x1.w + (finecosine[angle] << 6);
	y2.w = y1.w + (finesine[angle] << 6);
    P_PathTraverse ( x1, y1, x2, y2, PT_ADDLINES, PTR_UseTraverse );
}





//
// PIT_RadiusAttack
// "bombsource" is the creature
// that caused the explosion at "bombspot".
//
boolean __near PIT_RadiusAttack (THINKERREF thingRef, mobj_t __far*	thing, mobj_pos_t __far* thing_pos)  {
    fixed_t	dx;
    fixed_t	dy;
    fixed_t_union	dist;
	//todoaddr inline later
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif

	
	if (!(thing_pos->flags1 & MF_SHOOTABLE)) {
		return true;
	}
    // Boss spider and cyborg
    // take no damage from concussion.
	if (thing->type == MT_CYBORG || thing->type == MT_SPIDER) {
		return true;
	}


    dx = labs(thing_pos->x.w - bombspot_pos->x.w);
    dy = labs(thing_pos->y.w - bombspot_pos->y.w);
    
    dist.w = dx>dy ? dx : dy;
    dist.h.intbits = (dist.h.intbits - thing->radius ) ;

	if (dist.h.intbits < 0) {
		dist.h.intbits = 0;
	}

	if (dist.h.intbits >= bombdamage) {
		return true;	// out of range
	}

    if ( P_CheckSight (thing, bombspot, thing_pos, bombspot_pos) ) {
		// must be in direct path
		P_DamageMobj (thing, bombspot, bombsource, bombdamage - dist.h.intbits);
    }
    
    return true;
}


//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//
void __near P_RadiusAttack (mobj_t __far* spot, mobj_pos_t __far* spot_pos, mobj_t __far* source, int16_t		damage) {
	int16_t		xl;
	int16_t		xh;
	int16_t		yl;
	int16_t		yh;
	fixed_t_union pos;
	
	pos = spot_pos->y;
	yh = (pos.h.intbits + damage - bmaporgy) >> MAPBLOCKSHIFT;
	yl = (pos.h.intbits - damage - bmaporgy) >> MAPBLOCKSHIFT;
	pos = spot_pos->x;
	xh = (pos.h.intbits + damage - bmaporgx) >> MAPBLOCKSHIFT;
	xl = (pos.h.intbits - damage - bmaporgx) >> MAPBLOCKSHIFT;
	bombspot = spot;
	bombspot_pos = spot_pos;
	bombsource = source;
	bombdamage = damage;


 

	DoBlockmapLoop(xl, yl, xh, yh, PIT_RadiusAttack, false);	


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


//
// PIT_ChangeSector
//
boolean __near PIT_ChangeSector (THINKERREF thingRef, mobj_t __far*	thing, mobj_pos_t __far* thing_pos) {


    if (P_ThingHeightClip (thing, thing_pos)) {
		// keep checking
		return true;
    }
    

    // crunch bodies to giblets
    if (thing->health <= 0) {
		P_SetMobjState (thing, S_GIBS);
		thing = setStateReturn;
		thing_pos->flags1 &= ~MF_SOLID;
		thing->height.w = 0;
		thing->radius = 0;

		// keep checking
		return true;		
    }

    // crunch dropped items
    if (thing_pos->flags2 & MF_DROPPED) {
		P_RemoveMobj (thing);
	
		// keep checking
		return true;		
    }

    if (! (thing_pos->flags1 & MF_SHOOTABLE) ) {
	// assume it is bloody gibs or something
		return true;			
    }
    
    nofit = true;
	
    if (crushchange && !(leveltime.w &3) ) {
		mobj_t __far*	mo;
		THINKERREF moRef;
		P_DamageMobj(thing,NULL_THINKERREF,NULL_THINKERREF,10);

		// spray blood in a random direction
		moRef = P_SpawnMobj (thing_pos->x.w, thing_pos->y.w, thing_pos->z.w + thing->height.w>>1, MT_BLOOD, thing->secnum);
		
		mo = setStateReturn;
		mo->momx.w = (P_Random() - P_Random ())<<12;
		mo->momy.w = (P_Random() - P_Random ())<<12;
    }

    // keep checking (crush other things)	
    return true;	
}



//
// P_ChangeSector
//
boolean __near P_ChangeSector ( sector_t __far*	sector, boolean	crunch ) {
	sector_physics_t __far* sector_physics = &sectors_physics[sector - sectors];

	int16_t xl = sector_physics->blockbox[BOXLEFT];
	int16_t xh = sector_physics->blockbox[BOXRIGHT];
	int16_t yh = sector_physics->blockbox[BOXTOP];
	int16_t yl = sector_physics->blockbox[BOXBOTTOM];

    nofit = false;
    crushchange = crunch;

	DoBlockmapLoop(xl, yl, xh, yh, PIT_ChangeSector, false);	
	
    return nofit;
}

