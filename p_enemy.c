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
//	Enemy thinking, AI.
//	Action Pointer Functions
//	that are associated with states/frames. 
//

#include <stdlib.h>

#include "m_misc.h"
#include "i_system.h"

#include "doomdef.h"
#include "p_local.h"

#include "s_sound.h"

#include "g_game.h"

// State.
#include "doomstat.h"
#include "r_state.h"

// Data.
#include "sounds.h"
#include "m_memory.h"




#define    DI_EAST 0
#define    DI_NORTHEAST 1
#define    DI_NORTH 2
#define    DI_NORTHWEST 3
#define    DI_WEST 4
#define    DI_SOUTHWEST 5
#define    DI_SOUTH 6
#define    DI_SOUTHEAST 7
#define    DI_NODIR 8
#define    NUMDIRS 9
    
typedef int8_t dirtype_t;
extern mobj_t __far* setStateReturn;
extern mobj_pos_t __far* setStateReturn_pos;

//
// P_NewChaseDir related LUT.
//
dirtype_t opposite[] =
{
  DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST,
  DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR
};

dirtype_t diags[] =
{
    DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST
};





void __near A_Fall (mobj_t __far* mobj, mobj_pos_t __far* actor_pos);


//
// ENEMY THINKING
// Enemies are allways spawned
// with targetplayer = -1, threshold = 0
// Most monsters are spawned unaware of all players,
// but some can be made preaware
//

/*

int16_t __near P_FastDivBySpeed(fixed_t_union num, uint8_t speed){
//todo take out switch, sub 128

	switch (speed){
		// todo magic numbers or other fast algos?
		case 138: // 10 + 0x80
			return  num.h.intbits / 10;
		case 143: // 15 + 0x80
			return  num.h.intbits / 15;
		case 148: // 20 + 0x80
			return  num.h.intbits / 20;
		case 153: // 25 + 0x80
			return  num.h.intbits / 25;

	}
	return 0;

}
int16_t __near P_FixedMulBySpeed(fixed_t num, uint8_t speed){

//todo take out switch, sub 128

	switch (speed){
		// todo magic numbers or other fast algos?
		case 138: // 10 + 0x80
			return  FastMul16u32u(10, num);
		case 143: // 15 + 0x80
			return  FastMul16u32u(15, num);
		case 148: // 20 + 0x80
			return  FastMul16u32u(20, num);
		case 153: // 25 + 0x80
			return  FastMul16u32u(25, num);

	}
	return 0;

}
*/

//
// Called by P_NoiseAlert.
// Recursively traverse adjacent sectors,
// sound blocking lines cut off traversal.
//




void
__near P_RecursiveSound
( int16_t		secnum,
	int8_t		soundblocks)
{
    int16_t		i;
	line_t __far*	check;
	line_physics_t __far* check_physics;
    int16_t	othersecnum;
	int16_t linecount;
	sector_t __far* soundsector = &sectors[secnum];
	sector_physics_t __far* soundsector_physics = &sectors_physics[secnum];
	int16_t linenumber;
	uint8_t checkflags;
	int16_t checksidenum0;
	int16_t checksidenum1;
#ifndef		PRECALCULATE_OPENINGS
	int16_t checkfrontsecnum;
	int16_t checkbacksecnum;
#endif
	uint16_t lineoffset;

#ifdef CHECK_FOR_ERRORS
	if (soundblocks < 0) {
		I_Error("bad soundblock P_RecursiveSound %i %i", soundblocks);
	}

	if (secnum < 0 || secnum >= numsectors) {
		I_Error("bad sectors in P_RecursiveSound %i %i", secnum);
	}
#endif

	// wake up all monsters in this sector
    if (soundsector->validcount == validcount && sector_soundtraversed[secnum] <= soundblocks+1) {
		return;		// already flooded
    }

	soundsector->validcount = validcount;
	sector_soundtraversed[secnum] = soundblocks+1;
	//soundsector->soundtargetRef = 1;


	linecount = soundsector->linecount;
	soundsector = &sectors[secnum];

	for (i=0 ;i<linecount ; i++) {
		lineoffset = soundsector->linesoffset + i;
		linenumber = linebuffer[lineoffset];
		checkflags = lineflagslist[linenumber];
		check = &lines[linenumber];
		check_physics = &lines_physics[linenumber];
		checksidenum0 = check->sidenum[0];
		checksidenum1 = check->sidenum[1];

#ifndef		PRECALCULATE_OPENINGS
		checkfrontsecnum = check_physics->frontsecnum;
		checkbacksecnum = check_physics->backsecnum;
#endif



		if (!(checkflags & ML_TWOSIDED)) {
			continue;
		}
#ifdef	PRECALCULATE_OPENINGS
		P_LoadLineOpening(linenumber);
#else
		P_LineOpening(checksidenum1, checkfrontsecnum, checkbacksecnum);
#endif

		if (lineopening.opentop <= lineopening.openbottom) {
			continue;	// closed door
		}

		if (check_physics->frontsecnum == secnum) {
			othersecnum = check_physics->backsecnum;
		} else {
			othersecnum = check_physics->frontsecnum;
		}

		// 14 37 169 0
		if (checkflags & ML_SOUNDBLOCK) {
			if (!soundblocks) {
				P_RecursiveSound(othersecnum, 1);
			}
		} else {
			P_RecursiveSound(othersecnum, soundblocks);
		}
    }
}



//
// P_NoiseAlert
// If a monster yells at a player,
// it will alert other monsters to the player.
//
void
__near P_NoiseAlert
(  )
{


    validcount++;
	
    P_RecursiveSound (playerMobj->secnum, 0);

	
}




//
// P_CheckMeleeRange
//
boolean __near P_CheckMeleeRange (mobj_t __far* actor)
{
	mobj_t __far*	pl;
	mobj_pos_t __far*	pl_pos;
	mobj_pos_t __far*	actor_pos;
	THINKERREF plRef;
    fixed_t_union	dist;
	fixed_t plx;
	fixed_t ply;
	fixed_t actorX, actorY;
	int16_t plradius;
	
#ifdef MOVE_P_SIGHT
	//todoaddr inline later
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif
	
    if (!actor->targetRef)
		return false;
	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);
		
	actorX = actor_pos->x.w;
	actorY = actor_pos->y.w;

	plRef = actor->targetRef;
	pl = (mobj_t __far*)(&thinkerlist[plRef].data);
	pl_pos = &mobjposlist[plRef];
	plx = pl_pos->x.w;
	ply = pl_pos->y.w;
	plradius  = mobjinfo[pl->type].radius;
	
	dist.w = P_AproxDistance (plx-actorX, ply-actorY);
	plradius += (MELEERANGE - 20);
    if (dist.h.intbits >= plradius)
		return false;
    if (! P_CheckSight (actor, pl, actor_pos, pl_pos) )
		return false;
							
    return true;		
}

//
// P_CheckMissileRange
//
boolean __near P_CheckMissileRange (mobj_t __far* actor)
{
    fixed_t_union	disttemp;
	int16_t dist;
	mobj_t __far* actorTarget;
	mobj_pos_t __far* actorTarget_pos;
	fixed_t_union actorTargetx;
	fixed_t_union actorTargety;
	mobj_pos_t __far*	actor_pos;
	//todoaddr inline later
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif
	statenum_t (__far  * getMeleeState)(uint8_t) = getMeleeStateAddr;

	actorTarget = (mobj_t __far*)(&thinkerlist[actor->targetRef].data);
	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);
	actorTarget_pos = GET_MOBJPOS_FROM_MOBJ(actorTarget);

	if (!P_CheckSight(actor, actorTarget, actor_pos, actorTarget_pos)) {

		return false;
	}

    if (actor_pos->flags1 & MF_JUSTHIT ) {
		// the target just hit the enemy,
		// so fight back!
		actor_pos->flags1 &= ~MF_JUSTHIT;
		return true;
    }
	
	if (actor->reactiontime) {
		return false;	// do not attack yet
	}



	actorTargetx = actorTarget_pos->x;
	actorTargety = actorTarget_pos->y;    // OPTIMIZE: get this from a global checksight

	disttemp.w = P_AproxDistance(actor_pos->x.w - actorTargetx.w,
		actor_pos->y.w - actorTargety.w);
	
	dist = disttemp.h.intbits;
	dist -= 64;

    if (!getMeleeState(actor->type))
		dist -= 128;	// no melee attack, so fire more

    if (actor->type == MT_VILE) {
		if (dist > 14 * 64) {

			return false;	// too far away
		}
    }
	

    if (actor->type == MT_UNDEAD) {
		if (dist < 196) {

			return false;	// close for fist attack
		}
		dist >>= 1;
    }
	

    if (actor->type == MT_CYBORG || actor->type == MT_SPIDER || actor->type == MT_SKULL) {
		dist >>= 1;
    }
    
    if (dist > 200)
		dist = 200;
		
    if (actor->type == MT_CYBORG && dist > 160)
		dist = 160;
		
	if (P_Random() < dist) {

		return false;
	}

    return true;
}


//
// P_Move
// Move in the current direction,
// returns false if the move is blocked.
//
//fixed_t	xspeed[8] = {FRACUNIT,47000,0,-47000,-FRACUNIT,-47000,0,47000};
//fixed_t yspeed[8] = {0,47000,FRACUNIT,47000,0,-47000,-FRACUNIT,-47000};

#define MAXSPECIALCROSS	8

extern	int16_t	spechit[MAXSPECIALCROSS];
extern	int16_t	numspechit;

boolean __near P_Move (mobj_t __far* actor, mobj_pos_t __far*	actor_pos)
{
    fixed_t_union	tryx;
    fixed_t_union	tryy;
    
	int16_t linenum;
	int16_t usespeed;
    
    // warning: 'catch', 'throw', and 'try'
    // are all C++ reserved words
    boolean	try_ok;
    boolean	good;
	

	fixed_t_union temp;
	if (actor->movedir == DI_NODIR) {
		return false;
	}
	
#ifdef CHECK_FOR_ERRORS
	if (actor->movedir >= 8) {
		I_Error("Weird actor->movedir!");
	}
#endif
	tryx.w = actor_pos->x.w;
	tryy.w = actor_pos->y.w;
	temp.h.fracbits = 0;
	usespeed = mobjinfo[actor->type].speed;

	switch(actor->movedir){
		case 0:
			 tryx.h.intbits +=  usespeed;
			break;

		case 1:
			 temp.w = FastMul16u16u(usespeed, 47000);
			 tryx.w += temp.w;
			 tryy.w += temp.w;
			break;

		case 2:
			 tryy.h.intbits +=  usespeed;
			break;
		case 3:
			 temp.w = FastMul16u16u(usespeed, 47000);
			 tryx.w -= temp.w;
			 tryy.w += temp.w;
			break;
		case 4:
			 temp.h.intbits = usespeed;
			 tryx.w -= temp.w;
			break;
		case 5:
			 temp.w = FastMul16u16u(usespeed, 47000);
			 tryx.w -= temp.w;
			 tryy.w -= temp.w;

			break;
		case 6:
			 temp.h.intbits = usespeed;
			 tryy.w -= temp.w;
			break;
		case 7:
			 temp.w = FastMul16u16u(usespeed, 47000);
			 tryx.w += temp.w;
			 tryy.w -= temp.w;
			break;
	}

//	tryx.w = actor_pos->x.w + mobjinfo[actor->type].speed*xspeed[actor->movedir];
    //tryy.w = actor_pos->y.w + mobjinfo[actor->type].speed*yspeed[actor->movedir];

	try_ok = P_TryMove (actor, actor_pos, tryx, tryy);


    if (!try_ok) {
		// open any specials
		if (actor_pos->flags1 & MF_FLOAT && floatok) {
			// must adjust height
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, tmfloorz);

			if (actor_pos->z.w < temp.w)
				actor_pos->z.h.intbits += FLOATSPEED_HIGHBITS;
			else
				actor_pos->z.h.intbits -= FLOATSPEED_HIGHBITS;

			actor_pos->flags2 |= MF_INFLOAT;

			return true;
		}
		if (!numspechit) {
			return false;
		}
			
		actor->movedir = DI_NODIR;
		good = false;

		while (numspechit--) {
			linenum = spechit[numspechit];
			// if the special is not a door
			// that can be opened,
			// return false
			if (P_UseSpecialLine(actor, linenum, 0, GETTHINKERREF(actor))) {
				good = true;
			}
		}

		return good;
    } else {
		actor_pos->flags2 &= ~MF_INFLOAT;
 
	}

	
	if (!(actor_pos->flags1 & MF_FLOAT)) {
    	SET_FIXED_UNION_FROM_SHORT_HEIGHT(actor_pos->z, actor->floorz);
	}


	return true; 
}


//
// TryWalk
// Attempts to move actor on
// in its current (ob->moveangle) direction.
// If blocked by either a wall or an actor
// returns FALSE
// If move is either clear or blocked only by a door,
// returns TRUE and sets...
// If a door is in the way,
// an OpenDoor call is made to start it opening.
//
boolean __near P_TryWalk (mobj_t __far*	actor, mobj_pos_t __far* actor_pos)
{	
    if (!P_Move (actor, actor_pos)) {
		return false;
    }

    actor->movecount = P_Random()&15;
    return true;
}




void __near P_NewChaseDir (mobj_t __far*	actor, mobj_pos_t __far* actor_pos)
{
    fixed_t_union	deltax;
    fixed_t_union	deltay;
    
    dirtype_t	d[3];
    
    int8_t		tdir;
    dirtype_t	olddir;
    
    dirtype_t	turnaround;
	
	fixed_t_union actorx = actor_pos->x;
	fixed_t_union actory = actor_pos->y;

	mobj_t __far* actorTarget;
	mobj_pos_t __far* actorTarget_pos;

#ifdef CHECK_FOR_ERRORS
	if (!actor->targetRef)
		I_Error ("P_NewChaseDir: called with no target");
#endif
	olddir = actor->movedir;
	actorTarget = (mobj_t __far*)(&thinkerlist[actor->targetRef].data);
	actorTarget_pos = GET_MOBJPOS_FROM_MOBJ(actorTarget);
    turnaround=opposite[olddir];

    deltax.w = actorTarget_pos->x.w - actorx.w;
    deltay.w = actorTarget_pos->y.w - actory.w;

    if (deltax.w>10*FRACUNIT)
		d[1]= DI_EAST;
    else if (deltax.w<-10*FRACUNIT)
		d[1]= DI_WEST;
    else
		d[1]=DI_NODIR;

    if (deltay.w<-10*FRACUNIT)
		d[2]= DI_SOUTH;
    else if (deltay.w>10*FRACUNIT)
		d[2]= DI_NORTH;
    else
		d[2]=DI_NODIR;

	// try direct route
    if (d[1] != DI_NODIR && d[2] != DI_NODIR) {
		actor->movedir = diags[((deltay.h.intbits<0)<<1)+(deltax.w>0)];
		if (actor->movedir != turnaround && P_TryWalk(actor, actor_pos)) {
			return;
		}
    }

    // try other directions
    if (P_Random() > 200 ||  labs(deltay.w)>labs(deltax.w)) {
		tdir=d[1];
		d[1]=d[2];
		d[2]=tdir;
    }

    if (d[1]==turnaround)
		d[1]=DI_NODIR;
    if (d[2]==turnaround)
		d[2]=DI_NODIR;

	if (d[1]!=DI_NODIR) {
			actor->movedir = d[1];
		if (P_TryWalk(actor, actor_pos)) {
			// either moved forward or attacked
			return;
		}
    }



	if (d[2]!=DI_NODIR) {
		actor->movedir =d[2];

		if (P_TryWalk(actor, actor_pos)) {
			return;
		}
	}

	// there is no direct path to the player,
	// so pick another direction.
	if (olddir!=DI_NODIR) {
		actor->movedir =olddir;

		if (P_TryWalk(actor, actor_pos)) {
			return;
		}
	}
	// randomly determine direction of search
	if (P_Random()&1) {
		for ( tdir=DI_EAST; tdir<=DI_SOUTHEAST; tdir++ ) {
			if (tdir != turnaround) {
				actor->movedir = tdir;
			
				if (P_TryWalk(actor, actor_pos)) {

					return;
				}
			}
		}

	} else {
		for ( tdir=DI_SOUTHEAST; tdir != (DI_EAST-1); tdir-- ) {
			if (tdir!=turnaround) {
				actor->movedir =tdir;
		
				if (P_TryWalk(actor, actor_pos)) {
					return;
				}
			}
		}
	}
	if (turnaround !=  DI_NODIR) {
		actor->movedir =turnaround;
		if (P_TryWalk(actor, actor_pos)) {

			return;
		}
    }


    actor->movedir = DI_NODIR;	// can not move

}



//
// P_LookForPlayers
// If allaround is false, only look 180 degrees in front.
// Returns true if a player is targeted.
//
boolean __near P_LookForPlayers (mobj_t __far*	actor, boolean	allaround ) {
    angle_t	an;
    fixed_t_union	dist;
	mobj_pos_t __far* actor_pos;
	//todoaddr inline later
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif

 	if (player.health <= 0)
		return false;		// dead
	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);

	if (!P_CheckSight(actor, playerMobj, actor_pos, playerMobj_pos)) {

		return false;		// out of sight
	}

	if (!allaround) {
		an.wu = R_PointToAngle2(actor_pos->x, actor_pos->y, playerMobj_pos->x, playerMobj_pos->y) - actor_pos->angle.wu;
		if (an.wu > ANG90 && an.wu < ANG270) {
			dist.w = P_AproxDistance(playerMobj_pos->x.w - actor_pos->x.w, playerMobj_pos->y.w - actor_pos->y.w);
			// if real close, react anyway
			if (dist.w > MELEERANGE * FRACUNIT) {
				return false;	// behind back
			}
		}
	}

	actor->targetRef = playerMobjRef;
	return true;
}

//
// A_KeenDie
// DOOM II special, map 32.
// Uses special tag 666.
//
void __near A_KeenDie (mobj_t __far* mo, mobj_pos_t __far* mo_pos)
{
    THINKERREF	th;
    mobj_t __far*	mo2;
	mobjtype_t motype = mo->type;
	THINKERREF moRef = GETTHINKERREF(mo);
    A_Fall (mo, mo_pos);
    
    // scan the remaining thinkers
    // to see if all Keens are dead
    for (th = thinkerlist[0].next ; th != 0 ; th= thinkerlist[th].next) {
		if ((thinkerlist[th].prevFunctype & TF_FUNCBITS) != TF_MOBJTHINKER_HIGHBITS) {
			continue;
		}

		mo2 = (mobj_t  __far*)&thinkerlist[th].data;
		if (th != moRef && mo2->type == motype && mo2->health > 0) {
			// other Keen not dead
			return;		
		}
    }

    EV_DoDoor(TAG_666,open);
}


//
// ACTION ROUTINES
//

//
// A_Look
// Stay in state until a player is sighted.
//
void __near A_Look (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    mobj_t __far*	targ;
	THINKERREF targRef;
	int16_t actorsecnum = actor->secnum;
	//todoaddr inline later
	statenum_t (__far  * getSeeState)(uint8_t) = getSeeStateAddr;
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif
	actor->threshold = 0;	// any shot will wake up


	#ifdef RANGECHECK
		if (actorsecnum > numsectors) {
			actor = (mobj_t __far*)(&thinkerlist[actorRef].data);
		}
	#endif
    targRef = sector_soundtraversed[actorsecnum] ? playerMobjRef : 0;



	if (targRef) {

		mobj_pos_t __far* targ_pos = &mobjposlist[targRef];

		targ = (mobj_t __far*)(&thinkerlist[targRef].data);
		if (targ_pos->flags1 & MF_SHOOTABLE) {

			actor->targetRef = targRef;

			if (actor_pos->flags1 & MF_AMBUSH)
			{
				
				if (P_CheckSight(actor, targ, actor_pos, targ_pos)) {
					goto seeyou;
				}
			}
			else {
				goto seeyou;
			}
		}

	}


	if (!P_LookForPlayers(actor, false)) {

		return;
	}


	// reload actor here, tends to get paged out


    // go into chase state
  seeyou:



	if (mobjinfo[actor->type].seesound) {
		int16_t		sound;
		switch (mobjinfo[actor->type].seesound)
		{
		  case sfx_posit1:
		  case sfx_posit2:
		  case sfx_posit3:
			sound = sfx_posit1+P_Random()%3;
			break;

		  case sfx_bgsit1:
		  case sfx_bgsit2:
			sound = sfx_bgsit1+P_Random()%2;
			break;

		  default:
			  sound = mobjinfo[actor->type].seesound;
			  break;
		}
		if (actor->type==MT_SPIDER || actor->type == MT_CYBORG) {
			// full volume
			S_StartSoundFromRef(NULL, sound);
		} else {

			S_StartSoundFromRef(actor, sound);
		}
    }


	P_SetMobjState (actor, getSeeState(actor->type));
}


uint16_t movedirangles[8] = {
	0x0000,
	0x2000,
	0x4000,
	0x6000,
	0x8000,
	0xA000,
	0xC000,
	0xE000
};

//
// A_Chase
// Actor has a melee attack,
// so it tries to close as fast as possible
//
void __near A_Chase (mobj_t __far*	actor, mobj_pos_t __far* actor_pos)
{
	
	THINKERREF actortargetRef = actor->targetRef;
	int16_t delta;
	uint8_t sound;
	mobj_t __far*	actorTarget = (mobj_t __far*)(&thinkerlist[actortargetRef].data);
	mobj_pos_t __far*	actorTarget_pos = &mobjposlist[actortargetRef];
	//todoaddr inline later
	statenum_t (__far  * getMissileState)(uint8_t) = getMissileStateAddr;
	statenum_t (__far  * getMeleeState)(uint8_t) = getMeleeStateAddr;
	sfxenum_t (__far  * getActiveSound)(uint8_t) = getActiveSoundAddr;
	sfxenum_t (__far  * getAttackSound)(uint8_t) = getAttackSoundAddr;

    if (actor->reactiontime)
		actor->reactiontime--;
				

    // modify target threshold
    if  (actor->threshold) {
		if (actortargetRef) {
		}
		if (!actortargetRef || actorTarget->health <= 0) {

			actor->threshold = 0;
		} else {

			actor->threshold--;
		}
    }
    
	
    // turn towards movement direction if not there yet
    if (actor->movedir < 8) {
		
		actor_pos->angle.hu.intbits &= 0xE000;
		actor_pos->angle.hu.fracbits = 0;
		delta = actor_pos->angle.hu.intbits - movedirangles[actor->movedir];
		
		if (delta > 0)
			actor_pos->angle.hu.intbits -= ANG90_HIGHBITS / 2;
		else if (delta < 0)
			actor_pos->angle.hu.intbits += ANG90_HIGHBITS / 2;
		
 
    }


	
    if (!actorTarget || !(actorTarget_pos->flags1&MF_SHOOTABLE)) {
		// look for a new target
		if (P_LookForPlayers(actor, true)) {
			 
			return; 	// got a new target
		}

		P_SetMobjState (actor, mobjinfo[actor->type].spawnstate);



		return;
    }
	 


	// do not attack twice in a row
    if (actor_pos->flags1 & MF_JUSTATTACKED) {
		actor_pos->flags1 &= ~MF_JUSTATTACKED;
		if (gameskill != sk_nightmare && !fastparm) {
			P_NewChaseDir(actor, actor_pos);
		}


		return;
    }

    // check for melee attack
    if (getMeleeState(actor->type) && P_CheckMeleeRange (actor)) {
		S_StartSoundFromRef(actor, getAttackSound(actor->type));
	
		

		P_SetMobjState (actor, getMeleeState(actor->type));

		return;
    }


    // check for missile attack
    if (getMissileState(actor->type)) {
		
		if (gameskill < sk_nightmare
			&& !fastparm && actor->movecount) {
		 		goto nomissile;
		}
		

		if (!P_CheckMissileRange(actor)) {
 			goto nomissile;
		}


		P_SetMobjState (actor, getMissileState(actor->type));
		//actor = setStateReturn;
		actor_pos->flags1 |= MF_JUSTATTACKED;

		return;
    }


    // ?
  nomissile:
    // possibly choose another target





    // chase towards player


	if (--actor->movecount < 0 || !P_Move(actor, actor_pos)) {
		P_NewChaseDir(actor, actor_pos);

	}


	// make active sound
	sound = getActiveSound(actor->type);
	if (sound && P_Random() < 3) {
		S_StartSoundFromRef(actor, sound);
	}

}


//
// A_FaceTarget
//
void __near A_FaceTarget (mobj_t __far* actor)
{	
	mobj_pos_t __far* actorTarget_pos;
	mobj_pos_t __far* actor_pos;
	int8_t actorTargetShadow;
	uint16_t temp;
    if (!actor->targetRef)
		return;
	actorTarget_pos = &mobjposlist[actor->targetRef];
	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);

    actor_pos->flags1 &= ~MF_AMBUSH;
	actorTarget_pos = &mobjposlist[actor->targetRef];
	actorTargetShadow = actorTarget_pos->flags2 & MF_SHADOW ? 1 : 0;



	actor_pos->angle.wu = R_PointToAngle2 (
		actor_pos->x,
		actor_pos->y,
		actorTarget_pos->x,
		actorTarget_pos->y);
    
	if (actorTargetShadow) {

		temp = (P_Random() - P_Random());
		temp <<= 5;
		actor_pos->angle.hu.intbits += temp;
		
	}
}


//
// A_PosAttack
//
void __near A_PosAttack (mobj_t __far* actor)
{
    fineangle_t		angle;
    int16_t		damage;
    fixed_t		slope;
	mobj_pos_t __far* actor_pos;

    if (!actor->targetRef)
		return;
	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);

    A_FaceTarget (actor);

	angle = actor_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
    slope = P_AimLineAttack (actor, angle, MISSILERANGE);

	S_StartSoundFromRef(actor, sfx_pistol);
    angle = MOD_FINE_ANGLE(angle + (((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
    damage = ((P_Random()%5)+1)*3;
	P_LineAttack (actor, angle, MISSILERANGE, slope, damage);
}

void __near A_SPosAttack (mobj_t __far*	actor)
{
    int8_t		i;
    fineangle_t		angle;
    fineangle_t		bangle;
    int8_t		damage;
    fixed_t		slope;
	mobj_pos_t __far* actor_pos;

    if (!actor->targetRef)
		return;
	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);

	S_StartSoundFromRef(actor, sfx_shotgn);
    A_FaceTarget (actor);

	bangle = actor_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
    slope = P_AimLineAttack (actor, bangle, MISSILERANGE);

    for (i=0 ; i<3 ; i++) {
		angle = MOD_FINE_ANGLE((bangle + ((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
		damage = ((P_Random()%5)+1)*3;
		P_LineAttack (actor, angle, MISSILERANGE, slope, damage);
    }
}

void __near A_CPosAttack (mobj_t __far*	actor)
{
    fineangle_t		angle;
    fineangle_t		bangle;
    int8_t		damage;
    fixed_t		slope;
	mobj_pos_t __far* actor_pos;

    if (!actor->targetRef)
		return;
	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);

	S_StartSoundFromRef(actor, sfx_shotgn);
    A_FaceTarget (actor);

	bangle = actor_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
    slope = P_AimLineAttack (actor, bangle, MISSILERANGE);

    angle = MOD_FINE_ANGLE((bangle + ((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
    damage = ((P_Random()%5)+1)*3;
    P_LineAttack (actor, angle, MISSILERANGE, slope, damage);
}

void __near A_CPosRefire (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{	
    // keep firing unless target got out of sight
	mobj_t __far* actorTarget;
	THINKERREF actortargetRef;
	//todoaddr inline later
	statenum_t (__far  * getSeeState)(uint8_t) = getSeeStateAddr;
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif

	A_FaceTarget (actor);
	
	actortargetRef = actor->targetRef;
    if (P_Random () < 40)
		return;

	if (!actortargetRef)
		return;

	actorTarget = (mobj_t __far*)(&thinkerlist[actortargetRef].data);
    if (!actortargetRef || actorTarget->health <= 0 || !P_CheckSight(actor, actorTarget, actor_pos, GET_MOBJPOS_FROM_MOBJ(actorTarget))) {

		P_SetMobjState (actor, getSeeState(actor->type));
    }
}


void __near A_SpidRefire (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{	
    // keep firing unless target got out of sight
	mobj_t __far* actorTarget;
	THINKERREF 	actortargetRef;
	//todoaddr inline later
	statenum_t (__far  * getSeeState)(uint8_t) = getSeeStateAddr;
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif
	A_FaceTarget (actor);

	actortargetRef = actor->targetRef;

	if (P_Random() < 10) {
		return;
	}

	if (!actortargetRef) {
		return;
	}

	actorTarget = (mobj_t __far*)(&thinkerlist[actortargetRef].data);

    if (!actortargetRef || actorTarget->health <= 0 || !P_CheckSight(actor, actorTarget, actor_pos, GET_MOBJPOS_FROM_MOBJ(actorTarget))) {
		P_SetMobjState (actor, getSeeState(actor->type));
    }
}

void __near A_BspiAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{	
	if (!actor->targetRef) {
		return;
	}
		
    A_FaceTarget (actor);

    // launch a missile

	P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_ARACHPLAZ);
}


//
// A_TroopAttack
//
void __near A_TroopAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    int16_t		damage;

    if (!actor->targetRef)
		return;
		
    A_FaceTarget (actor);

	if (P_CheckMeleeRange (actor)) {

		S_StartSoundFromRef(actor, sfx_claw);
		damage = (P_Random()%8+1)*3;

		P_DamageMobj ((&thinkerlist[actor->targetRef].data), actor, actor, damage);
		return;
    }


	// launch a missile
    P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_TROOPSHOT);
}


void __near A_SargAttack (mobj_t __far* actor)
{
    int16_t		damage;
	

	if (!actor->targetRef) {
		return;
	}
		
    A_FaceTarget (actor);

	if (P_CheckMeleeRange (actor)) {
		damage = ((P_Random()%10)+1)*4;

		P_DamageMobj ((&thinkerlist[actor->targetRef].data), actor, actor, damage);
    }
}

void __near A_HeadAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    int16_t		damage;

	if (!actor->targetRef) {
		return;
	}

    A_FaceTarget (actor);

	if (P_CheckMeleeRange (actor)) {
		damage = (P_Random()%6+1)*10;

		P_DamageMobj ((&thinkerlist[actor->targetRef].data), actor, actor, damage);
		return;
    }

	// launch a missile
    P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_HEADSHOT);
}

void __near A_CyberAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{	

    if (!actor->targetRef)
		return;
		
    A_FaceTarget (actor);

	P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_ROCKET);
}


void __near A_BruisAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    int16_t		damage;

    if (!actor->targetRef)
		return;
		
    if (P_CheckMeleeRange (actor)){

		S_StartSoundFromRef(actor, sfx_claw);
		damage = (P_Random()%8+1)*10;

		P_DamageMobj ((&thinkerlist[actor->targetRef].data), actor, actor, damage);
		return;
    }

	// launch a missile
    P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_BRUISERSHOT);
}


//
// A_SkelMissile
//
void __near A_SkelMissile (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{	
	mobj_t __far*	mo;
	mobj_pos_t __far*	mo_pos;
	THINKERREF moRef;
	THINKERREF actortargetRef;
 
	if (!actor->targetRef) {
		return;
	}
		
    A_FaceTarget (actor);
 
	actor_pos->z.h.intbits += 16;	// so missile spawns higher
    moRef = P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_TRACER);
	mo = setStateReturn;
	mo_pos = setStateReturn_pos;
	actor_pos->z.h.intbits -= 16;	// back to normal
	actortargetRef = actor->targetRef;
	
	mo_pos->x.w += mo->momx.w;
	mo_pos->y.w += mo->momy.w;
    mo->tracerRef = actortargetRef;
}

#define	TRACEANGLE 0xc000000

void __near A_Tracer (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    angle_t	exact;
	fineangle_t fineexact;
	fixed_t_union dist;
	int16_t dist16;
    fixed_t	slope;
    mobj_t __far*	dest;
    mobj_t __far*	th;
	THINKERREF thRef;
	fixed_t destz;
	
	mobj_pos_t __far*	dest_pos;

	if (gametic & 3)
		return;
	
    
    // spawn a puff of smoke behind the rocket		
    P_SpawnPuff (actor_pos->x.w, actor_pos->y.w, actor_pos->z.w);


	thRef = P_SpawnMobj (actor_pos->x.w-actor->momx.w,
		actor_pos->y.w-actor->momy.w,
		actor_pos->z.w, MT_SMOKE, -1);
    
	th = setStateReturn;

    th->momz.h.intbits = 1;
    th->tics -= P_Random()&3;
    if (th->tics < 1 || th->tics > 240)
		th->tics = 1;
    


	if (!actor->tracerRef) {
		return;
	}

    // adjust direction
    dest = (mobj_t __far*)(&thinkerlist[actor->tracerRef].data);
 
    if (!dest || dest->health <= 0)
		return;
    
    // change angle	
    exact.wu = R_PointToAngle2 (actor_pos->x,
		actor_pos->y,
		dest_pos->x,
		dest_pos->y);
	
 
    if (exact.wu != actor_pos->angle.wu) {
		if (exact.wu - actor_pos->angle.wu > 0x80000000) {
			actor_pos->angle.wu -= TRACEANGLE;
			if (exact.wu - actor_pos->angle.wu < 0x80000000)
				actor_pos->angle = exact;
		} else {
			actor_pos->angle.wu += TRACEANGLE;
			if (exact.wu - actor_pos->angle.wu > 0x80000000)
				actor_pos->angle = exact;
		}
    }
    fineexact = (actor_pos->angle.hu.intbits >> 1) & 0xFFFC;
    
	
	actor->momx.w = FixedMulTrigSpeed(FINE_COSINE_ARGUMENT, fineexact, mobjinfo[actor->type].speed);
	actor->momy.w = FixedMulTrigSpeed(FINE_SINE_ARGUMENT, fineexact, mobjinfo[actor->type].speed);
	
	dest = (mobj_t __far*)(&thinkerlist[actor->tracerRef].data);
	dest_pos = &mobjposlist[actor->tracerRef];
	destz = dest_pos->z.w;

	// change slope
    dist.w = P_AproxDistance (dest_pos->x.w - actor_pos->x.w,
			    dest_pos->y.w - actor_pos->y.w);
    
	dist16 = dist.h.intbits / (mobjinfo[actor->type].speed - 0x80);
	
	if (dist16 < 1) {
		dist16 = 1;
	}
    slope = FastDiv3216u(destz+40*FRACUNIT - actor_pos->z.w, dist16);

    if (slope < actor->momz.w)
		actor->momz.w -= FRACUNIT/8;
    else
		actor->momz.w += FRACUNIT/8;
}


void __near A_SkelWhoosh (mobj_t __far* actor)
{
    if (!actor->targetRef)
		return;

    A_FaceTarget (actor);

	S_StartSoundFromRef(actor,sfx_skeswg);
}

void __near A_SkelFist (mobj_t __far* actor)
{
    int16_t		damage;
    if (!actor->targetRef)
		return;
		
    A_FaceTarget (actor);
	

	if (P_CheckMeleeRange (actor)) {
		damage = ((P_Random()%10)+1)*6;

		S_StartSoundFromRef(actor, sfx_skepch);

		P_DamageMobj ((&thinkerlist[actor->targetRef].data), actor, actor, damage);
    }
}



//
// PIT_VileCheck
// Detect a corpse that could be raised.
//
THINKERREF		corpsehitRef;
mobj_t __far*		vileobj;
fixed_t_union		viletryx;
fixed_t_union		viletryy;

boolean __near PIT_VileCheck (THINKERREF thingRef, mobj_t __far*	thing, mobj_pos_t __far* thing_pos)
{
	fixed_t_union				maxdist;
    boolean	check;
	//todoaddr inline later
	statenum_t (__far  * getRaiseState)(uint8_t) = getRaiseStateAddr;


	if (!(thing_pos->flags2 & MF_CORPSE)) {
		return true;	// not a monster
	}
    
	if (thing->tics != 255) {
		return true;	// not lying still yet
	}

	if (getRaiseState(thing->type) == S_NULL) {
		return true;	// monster doesn't have a raise state
	}

	maxdist.h.intbits = (mobjinfo[thing->type].radius + mobjinfo[MT_VILE].radius);
	maxdist.h.fracbits = 0;

	
	if (labs(thing_pos->x.w - viletryx.w) > maxdist.w || labs(thing_pos->y.w - viletryy.w) > maxdist.w) {
		return true;		// not actually touching
	}
		
	corpsehitRef = thingRef;
    thing->momx.w = thing->momy.w = 0;
	thing->height.w <<= 2;
    check = P_CheckPosition (thing, thing_pos->x, thing_pos->y, thing->secnum);
	thing->height.w >>= 2;

	if (!check) {
		return true;		// doesn't fit here
	}
    return false;		// got one, so stop checking
}



//
// A_VileChase
// Check for ressurecting a body
//
void __near A_VileChase (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    int16_t			xl;
    int16_t			xh;
    int16_t			yl;
    int16_t			yh;
    
    int16_t			bx;
    int16_t			by;

    mobjinfo_t __far*		info;
	fixed_t_union   coord;
	THINKERREF		tempRef;
	mobj_t __far*	corpsehit;
	//todoaddr inline later
	int16_t (__far  * getSpawnHealth)(uint8_t) = getSpawnHealthAddr;
	statenum_t (__far  * getRaiseState)(uint8_t) = getRaiseStateAddr;


	coord.h.fracbits = 0;
    if (actor->movedir != DI_NODIR) {
		mobj_pos_t __far* corpsehit_pos;
		int16_t usespeed = mobjinfo[actor->type].speed;
		fixed_t_union temp;
		temp.h.fracbits = 0;
		// check for corpses to raise
		viletryx.w = actor_pos->x.w;// + mobjinfo[actor->type].speed*xspeed[actor->movedir];
		viletryy.w = actor_pos->y.w;// + mobjinfo[actor->type].speed*yspeed[actor->movedir];
		

		switch(actor->movedir){
			case 0:
				viletryx.h.intbits +=  usespeed;
				break;

			case 1:
				temp.w = FastMul16u16u(usespeed, 47000);
				viletryx.w += temp.w;
				viletryy.w += temp.w;
				break;

			case 2:
				viletryy.h.intbits +=  usespeed;
				break;
			case 3:
				temp.w = FastMul16u16u(usespeed, 47000);
				viletryx.w -= temp.w;
				viletryy.w += temp.w;
				break;
			case 4:
				temp.h.intbits = usespeed;
				viletryx.w -= temp.w;
				break;
			case 5:
				temp.w = FastMul16u16u(usespeed, 47000);
				viletryx.w -= temp.w;
				viletryy.w -= temp.w;

				break;
			case 6:
				temp.h.intbits = usespeed;
				viletryy.w -= temp.w;
				break;
			case 7:
				temp.w = FastMul16u16u(usespeed, 47000);
				viletryx.w += temp.w;
				viletryy.w -= temp.w;
				break;
		}



		coord.h.intbits = bmaporgx;
		// todo optimize when doing doom2 stuff
		xl = (viletryx.w - coord.w - MAXRADIUS*2)>>MAPBLOCKSHIFT;
		xh = (viletryx.w - coord.w + MAXRADIUS*2)>>MAPBLOCKSHIFT;
		coord.h.intbits = bmaporgy;
		yl = (viletryy.w - coord.w - MAXRADIUS*2)>>MAPBLOCKSHIFT;
		yh = (viletryy.w - coord.w + MAXRADIUS*2)>>MAPBLOCKSHIFT;
	
		vileobj = actor;
		for (bx=xl ; bx<=xh ; bx++)
		{
			for (by=yl ; by<=yh ; by++)
			{
			// Call PIT_VileCheck to check
			// whether object is a corpse
			// that canbe raised.
			if (!P_BlockThingsIterator(bx,by,PIT_VileCheck))
			{
				// got one!

				tempRef = actor->targetRef;
				actor->targetRef = corpsehitRef;
				A_FaceTarget (actor);
				actor->targetRef = tempRef;
					
				P_SetMobjState (actor, S_VILE_HEAL1);
				//actor = setStateReturn;

				corpsehit = (mobj_t __far*)(&thinkerlist[corpsehitRef].data);
				corpsehit_pos = &mobjposlist[corpsehitRef];
				S_StartSoundFromRef(corpsehit, sfx_slop);
				info = &mobjinfo[corpsehit->type];
		    
				P_SetMobjState (corpsehit,getRaiseState(corpsehit->type));
				//corpsehit = setStateReturn;
				corpsehit->height.h.intbits <<= 2;
				corpsehit_pos->flags1 = info->flags1;
				corpsehit_pos->flags2 = info->flags2;
				corpsehit->health = getSpawnHealth(corpsehit->type);
				corpsehit->targetRef = NULL_THINKERREF;

				return;
			}
			}
		}
    }

    // Return to normal attack.
	A_Chase (actor, actor_pos);
}


//
// A_VileStart
//
void __near A_VileStart (mobj_t __far* actor)
{
	S_StartSoundFromRef(actor, sfx_vilatk);
}


//
// A_Fire
// Keep fire in front of player unless out of sight
//
void __near A_Fire (mobj_t __far* actor, mobj_pos_t __far* actor_pos);

void __near A_StartFire (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
	S_StartSoundFromRef(actor,sfx_flamst);
    A_Fire( actor, actor_pos);
}

void __near A_FireCrackle (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
	S_StartSoundFromRef(actor,sfx_flame);
    A_Fire( actor, actor_pos);
}

void __near A_Fire (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
	THINKERREF	destRef;
	fineangle_t	an;
	mobj_t __far* dest;
	mobj_pos_t __far* dest_pos;
	//todoaddr inline later
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif


    destRef = actor->tracerRef;
    if (!destRef)
		return;
		
    // don't move it if the vile lost sight
	dest = (mobj_t __far*)(&thinkerlist[destRef].data);
	dest_pos = &mobjposlist[destRef];
	if (!P_CheckSight ((&thinkerlist[actor->targetRef].data), dest, &mobjposlist[actor->targetRef], dest_pos) )
		return;

    an = (dest_pos->angle.hu.intbits >> 1) & 0xFFFC;


	P_UnsetThingPosition (actor, actor_pos);

	//todo isnt this just multiplied by 24?
	actor_pos->x.w = dest_pos->x.w + FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, an, 24*FRACUNIT);
	actor_pos->y.w = dest_pos->y.w + FixedMulTrigNoShift(FINE_SINE_ARGUMENT,   an, 24*FRACUNIT);

	actor_pos->z.w = dest_pos->z.w;
    P_SetThingPosition (actor, actor_pos, -1);
}



//
// A_VileTarget
// Spawn the hellfire
//
void __near A_VileTarget (mobj_t __far* actor)
{
	mobj_t __far* actorTarget;
	mobj_t __far* fog;
	mobj_pos_t __far* actorTarget_pos;
	THINKERREF fogRef;
	THINKERREF actortargetRef;
	if (!actor->targetRef)
		return;

    A_FaceTarget (actor);

	actortargetRef = actor->targetRef;
	actorTarget = (mobj_t __far*)(&thinkerlist[actor->targetRef].data);
	actorTarget_pos = &mobjposlist[actor->targetRef];
    fogRef = P_SpawnMobj (actorTarget_pos->x.w,
		actorTarget_pos->y.w,
		actorTarget_pos->z.w, MT_FIRE, actorTarget->secnum);
	fog = setStateReturn;
	fog->targetRef = GETTHINKERREF(actor);
	fog->tracerRef = actortargetRef;

    actor->tracerRef = fogRef;

    A_Fire (fog, setStateReturn_pos);
}


fixed_t __near GetVileMomz(int8_t id){
	
	// return 1000 * FRACUNIT / mass
	switch (id){

		case MT_SKULL:
			return 20 * FRACUNIT;
		case MT_SERGEANT:
		case MT_SHADOWS:
		case MT_HEAD:
		case MT_PAIN:
			return 163840L;

		case MT_VILE:
		case MT_UNDEAD:
			return 2 * FRACUNIT;
		case MT_BABY:
			return 109226L;
		case MT_FATSO:
		case MT_BRUISER:
		case MT_KNIGHT:
		case MT_SPIDER:
		case MT_CYBORG:
			return FRACUNIT;

		case MT_KEEN:
		case MT_BOSSBRAIN:
			return 1;


		default:

			return 10 * FRACUNIT;
	}
}

//
// A_VileAttack
//
void __near A_VileAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{	
	THINKERREF	fireRef;
    uint16_t		an;
	mobj_t __far* actorTarget;
	mobj_t __far* fire;
	fixed_t_union mass;
	mobj_pos_t __far* actorTarget_pos;
	mobj_pos_t __far* fire_pos;
	//todoaddr inline later
#ifdef MOVE_P_SIGHT
	boolean (__far  * P_CheckSight)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ) = P_CheckSightAddr;
#endif

	if (!actor->targetRef)
		return;
	actorTarget_pos = &mobjposlist[actor->targetRef];

    A_FaceTarget (actor);
	actorTarget = (mobj_t __far*)(&thinkerlist[actor->targetRef].data);
	if (!P_CheckSight(actor, actorTarget, actor_pos, actorTarget_pos))
		return;
	S_StartSoundFromRef (actor, sfx_barexp);
	P_DamageMobj ((&thinkerlist[actor->targetRef].data), actor, actor, 20);
    an = (actor_pos->angle.hu.intbits >> 1) & 0xFFFC;

	fireRef = actor->tracerRef;

	actorTarget->momz.w = GetVileMomz(actorTarget->type);


    if (!fireRef)
		return;
		

	fire = (mobj_t __far*)(&thinkerlist[fireRef].data);
	fire_pos = &mobjposlist[fireRef];
	// move the fire between the vile and the player
	//todo isnt this just multiplied by 24?
	fire_pos->x.w = actorTarget_pos->x.w - FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, an, 24*FRACUNIT);
	fire_pos->y.w = actorTarget_pos->y.w - FixedMulTrigNoShift(FINE_SINE_ARGUMENT, an, 24*FRACUNIT);
    P_RadiusAttack (fire, fire_pos, actor, 70 );
}




//
// Mancubus attack,
// firing three missiles (bruisers)
// in three different directions?
// Doesn't look like it. 
//
#define	FATSPREAD	(ANG90/8)

void __near A_FatRaise (mobj_t __far*	actor)
{
    A_FaceTarget (actor);
	S_StartSoundFromRef (actor, sfx_manatk);
}


void __near A_FatAttack1 (mobj_t __far*	actor, mobj_pos_t __far* actor_pos)
{
	mobj_t __far*	mo;
	mobj_pos_t __far*	mo_pos;
    uint16_t		an;
	THINKERREF moRef;

    A_FaceTarget (actor);
    // Change direction  to ...
    actor_pos->angle.wu += FATSPREAD;
    P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_FATSHOT);

    moRef = P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_FATSHOT);
	mo = (mobj_t __far*)(&thinkerlist[moRef].data);
	mo_pos = &mobjposlist[moRef];
	mo_pos->angle.wu += FATSPREAD;
    an = (mo_pos->angle.hu.intbits >> 1) & 0xFFFC;
    mo->momx.w = FixedMulTrigSpeedNoShift(FINE_COSINE_ARGUMENT, an, (mobjinfo[mo->type].speed));
    mo->momy.w = FixedMulTrigSpeedNoShift(FINE_SINE_ARGUMENT, an, (mobjinfo[mo->type].speed));
}

void __near A_FatAttack2 (mobj_t __far*	actor, mobj_pos_t __far* actor_pos)
{
    mobj_t __far*	mo;
    fineangle_t		an;
	THINKERREF moRef;
	THINKERREF actortargetRef;
	mobj_pos_t __far*	mo_pos;

	A_FaceTarget (actor);
	// Now here choose opposite deviation.
    actor_pos->angle.wu -= FATSPREAD;
	actortargetRef = actor->targetRef;
    P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_FATSHOT);

	moRef = P_SpawnMissile (actor, actor_pos, (&thinkerlist[actor->targetRef].data), MT_FATSHOT);
	mo = setStateReturn;
	mo_pos = setStateReturn_pos;
	mo_pos->angle.wu -= FATSPREAD*2;
    an = (mo_pos->angle.hu.intbits >> 1) & 0xFFFC;
    mo->momx.w = FixedMulTrigSpeedNoShift(FINE_COSINE_ARGUMENT, an, (mobjinfo[mo->type].speed));
    mo->momy.w = FixedMulTrigSpeedNoShift(FINE_SINE_ARGUMENT, an, (mobjinfo[mo->type].speed));
}

void __near A_FatAttack3 (mobj_t __far*	actor, mobj_pos_t __far* actor_pos)
{
    mobj_t __far*	mo;
    fineangle_t		an;
	THINKERREF moRef;
	THINKERREF actortargetRef;
	mobj_pos_t __far*	mo_pos;
	int8_t mospeed;
	A_FaceTarget(actor);
	actortargetRef = actor->targetRef;

    moRef = P_SpawnMissile (actor, actor_pos, (&thinkerlist[actortargetRef].data), MT_FATSHOT);
	mo = setStateReturn;
	mo_pos = setStateReturn_pos;

	// todo hardcode this value, it's static..
	mo_pos->angle.wu -= FATSPREAD/2;
    an = (mo_pos->angle.hu.intbits >> 1) & 0xFFFC;
	mospeed = mobjinfo[mo->type].speed;
    mo->momx.w = FixedMulTrigSpeedNoShift(FINE_COSINE_ARGUMENT, an, mospeed);
    mo->momy.w = FixedMulTrigSpeedNoShift(FINE_SINE_ARGUMENT, an, mospeed);

	moRef = P_SpawnMissile (actor, actor_pos, (&thinkerlist[actortargetRef].data), MT_FATSHOT);
	mo = setStateReturn;
	mo_pos = setStateReturn_pos;
	mo_pos->angle.wu += FATSPREAD/2;
    an = (mo_pos->angle.hu.intbits >> 1) & 0xFFFC;
    mo->momx.w = FixedMulTrigSpeedNoShift(FINE_COSINE_ARGUMENT, an, mospeed);
    mo->momy.w = FixedMulTrigSpeedNoShift(FINE_SINE_ARGUMENT, an, mospeed);
}


//
// SkullAttack
// Fly at the player like a missile.
//
#define	SKULLSPEED		(20*FRACUNIT)
#define	SKULLSPEED_SMALL		(20)

void __near A_SkullAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    mobj_t __far*		dest;
	THINKERREF		destRef;
    fineangle_t		an;
    fixed_t_union			dist;
	int16_t         dist16;
	mobj_pos_t __far* dest_pos;
	//todoaddr inline later
	sfxenum_t (__far  * getAttackSound)(uint8_t) = getAttackSoundAddr;


	if (!actor->targetRef) {
		return;
	}

	actor_pos->flags2 |= MF_SKULLFLY;

    destRef = actor->targetRef;	

	S_StartSoundFromRef(actor, getAttackSound(actor->type));
	A_FaceTarget(actor);
	dest = (mobj_t __far*)(&thinkerlist[destRef].data);
	dest_pos = &mobjposlist[destRef];
    //an = actor_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
    an = (actor_pos->angle.hu.intbits >> 1) & 0xFFFC;
    actor->momx.w = FixedMulTrigSpeedNoShift(FINE_COSINE_ARGUMENT, an, SKULLSPEED_SMALL);
    actor->momy.w = FixedMulTrigSpeedNoShift(FINE_SINE_ARGUMENT, an, SKULLSPEED_SMALL);
    dist.w = P_AproxDistance (dest_pos->x.w - actor_pos->x.w, dest_pos->y.w - actor_pos->y.w);
    dist16 = dist.h.intbits / SKULLSPEED_SMALL;
    
	if (dist16 < 1) {
		dist16 = 1;
	}
    actor->momz.w = (dest_pos->z.w+(dest->height.w>>1) - actor_pos->z.w) / dist16;
}


//
// A_PainShootSkull
// Spawn a lost soul and launch it at the target
//
void __near A_PainShootSkull (mobj_t __far* actor, angle_t	angle ) {
    fixed_t	x;
    fixed_t	y;
    fixed_t_union	z;
    
    mobj_t __far*	newmobj;
    fineangle_t	an;
    fixed_t_union	prestep;
    int16_t		count;
    THINKERREF	currentthinker;
	THINKERREF newmobjRef;
	THINKERREF actortargetRef;
	int16_t radii;
	mobj_pos_t __far* actor_pos;
	mobj_pos_t __far* newmobj_pos;

	
	// count total number of skull currently on the level
    count = 0;

    currentthinker = thinkerlist[0].next;
    while (currentthinker != 0) {
		if (((thinkerlist[currentthinker].prevFunctype & TF_FUNCBITS) == TF_MOBJTHINKER_HIGHBITS)
			&& ((mobj_t  __far*)&thinkerlist[currentthinker])->type == MT_SKULL) {
			count++;
		}
		if (count > 20) {
			break;
		}

		currentthinker = thinkerlist[currentthinker].next;
    }

    // if there are allready 20 skulls on the level,
    // don't spit another one
	if (count > 20) {
		return;
	}

    // okay, there's playe for another one
    an = (angle.hu.intbits >> 1) & 0xFFFC;
	
	actortargetRef = actor->targetRef;
	radii = mobjinfo[actor->type].radius + mobjinfo[MT_SKULL].radius;
	prestep.h.intbits = 4 + 3 * ((radii) >> 1);
	if (radii % 1)
		prestep.h.fracbits = -32768; // handle the radii / 2 case
	else
		prestep.h.fracbits = 0x0000;

	actor_pos = GET_MOBJPOS_FROM_MOBJ(actor);


    
    x = actor_pos->x.w + FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, an, prestep.w);
    y = actor_pos->y.w + FixedMulTrigNoShift(FINE_SINE_ARGUMENT, an, prestep.w);
	z.w = actor_pos->z.w;
	z.h.intbits += 8;
		
    newmobjRef = P_SpawnMobj (x , y, z.w, MT_SKULL, -1);
	newmobj = setStateReturn;
	newmobj_pos = setStateReturn_pos;
    // Check for movements.

	if (!P_TryMove (newmobj, newmobj_pos, newmobj_pos->x, newmobj_pos->y)) {
		// kill it immediately
		P_DamageMobj (newmobj,actor,actor,10000);	
		return;
    }

    newmobj->targetRef = actortargetRef;
    A_SkullAttack (newmobj, newmobj_pos);
}


//
// A_PainAttack
// Spawn a lost soul and launch it at the target
// 
void __near A_PainAttack (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
    if (!actor->targetRef)
		return;

	A_FaceTarget(actor);
	A_PainShootSkull (actor, actor_pos->angle);
}


void __near A_PainDie (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
	angle_t actorangle = actor_pos->angle;
    A_Fall (actor, actor_pos);
	actorangle.hu.intbits += ANG90_HIGHBITS;
    A_PainShootSkull (actor, actorangle);
	actorangle.hu.intbits += ANG90_HIGHBITS;
	A_PainShootSkull(actor, actorangle);
	actorangle.hu.intbits += ANG90_HIGHBITS;
	A_PainShootSkull(actor, actorangle);

}

void __near A_Scream (mobj_t __far* actor)
{
    uint8_t		sound;
	
    switch (mobjinfo[actor->type].deathsound)
    {
      case 0:
	return;
		
      case sfx_podth1:
      case sfx_podth2:
      case sfx_podth3:
		sound = sfx_podth1 + P_Random ()%3;
	break;
		
      case sfx_bgdth1:
      case sfx_bgdth2:
		sound = sfx_bgdth1 + P_Random ()%2;
	break;
	
      default:
		sound = mobjinfo[actor->type].deathsound;
	break;
    }

    // Check for bosses.
    if (actor->type==MT_SPIDER || actor->type == MT_CYBORG) {
		// full volume
		S_StartSoundFromRef(NULL, sound);
	} else {
		S_StartSoundFromRef(actor, sound);
	}
}


void __near A_XScream (mobj_t __far* actor)
{

	S_StartSoundFromRef(actor, sfx_slop);
}

void __near A_Pain (mobj_t __far* actor)
{
	//todoaddr inline later
	sfxenum_t (__far  * getPainSound)(uint8_t) = getPainSoundAddr;

	S_StartSoundFromRef(actor, getPainSound(actor->type));
}



void __near A_Fall (mobj_t __far* actor, mobj_pos_t __far* actor_pos)
{
	// actor is on ground, it can be walked over
    actor_pos->flags1 &= ~MF_SOLID;

    // So change this if corpse objects
    // are meant to be obstacles.
}


//
// A_Explode
//
void __near A_Explode (mobj_t __far* thingy, mobj_pos_t __far* thingy_pos)
{
	
    P_RadiusAttack ( thingy, thingy_pos, (mobj_t __far*)&thinkerlist[ thingy->targetRef].data, 128 );

}


//
// A_BossDeath
// Possibly trigger special effects
// if on first boss level
//
void __near A_BossDeath (mobj_t __far* mo)
{
    THINKERREF	th;
    mobj_t __far*	mo2;
	THINKERREF moRef;
	
	mobjtype_t motype = mo->type;
		
    if (commercial)
    {
	if (gamemap != 7)
	    return;
		
	if ((motype != MT_FATSO)
	    && (motype != MT_BABY))
	    return;
    }
    else
    {
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
	if (gamemap != 8)
	    return;

	if (motype == MT_BRUISER && gameepisode != 1)
	    return;
#else
	switch(gameepisode)
	{
	  case 1:
	    if (gamemap != 8)
		return;

	    if (motype != MT_BRUISER)
		return;
	    break;
	    
	  case 2:
	    if (gamemap != 8)
		return;

	    if (motype != MT_CYBORG)
		return;
	    break;
	    
	  case 3:
	    if (gamemap != 8)
		return;
	    
	    if (motype != MT_SPIDER)
		return;
	    
	    break;
	    
	  case 4:
	    switch(gamemap)
	    {
	      case 6:
		if (motype != MT_CYBORG)
		    return;
		break;
		
	      case 8: 
		if (motype != MT_SPIDER)
		    return;
		break;
		
	      default:
		return;
		break;
	    }
	    break;
	    
	  default:
	    if (gamemap != 8)
		return;
	    break;
	}
#endif
		
    }

    
	// make sure there is a player alive for victory
	if (player.health <= 0)
		return; // no one left alive, so do not end game

    // scan the remaining thinkers to see
    // if all bosses are dead
	moRef = GETTHINKERREF(mo);
	for (th = thinkerlist[0].next; th != 0; th = thinkerlist[th].next)
	{
	if ((thinkerlist[th].prevFunctype & TF_FUNCBITS) != TF_MOBJTHINKER_HIGHBITS)
	    continue;
	
	mo2 = (mobj_t  __far*)&thinkerlist[th].data;
	if (th != moRef
	    && mo2->type == motype
	    && mo2->health > 0)
	{
	    // other boss not dead
	    return;
	}
    }
	
    // victory!
    if (commercial)
    {
	if (gamemap == 7)
	{
	    if (motype == MT_FATSO)
	    {
		EV_DoFloor(TAG_666, -1,lowerFloorToLowest);
		return;
	    }
	    
	    if (motype == MT_BABY)
	    {
		EV_DoFloor(TAG_667, -1,raiseToTexture);
		return;
	    }
	}
    }
    else
    {
	switch(gameepisode)
	{
	  case 1:
	    EV_DoFloor (TAG_666, -1, lowerFloorToLowest);
	    return;
	    break;
	    
	  case 4:
	    switch(gamemap)
	    {
	      case 6:
		EV_DoDoor (TAG_666, blazeOpen);
		return;
		break;
		
	      case 8:
		EV_DoFloor (TAG_666, -1, lowerFloorToLowest);
		return;
		break;
	    }
	}
    }
	
    G_ExitLevel ();
}


void __near A_Hoof(mobj_t __far* mobj, mobj_pos_t __far* mobj_pos)
{
	S_StartSoundFromRef(mobj, sfx_hoof);
    A_Chase (mobj, mobj_pos);
}

void __near A_Metal (mobj_t __far* mobj, mobj_pos_t __far* mobj_pos)
{
	S_StartSoundFromRef(mobj, sfx_metal);
	A_Chase(mobj, mobj_pos);
}

void __near A_BabyMetal (mobj_t __far* mobj, mobj_pos_t __far* mobj_pos)
{
	S_StartSoundFromRef(mobj, sfx_bspwlk);
	A_Chase(mobj, mobj_pos);
}



THINKERREF		braintargets[32];
int16_t		numbraintargets;
int16_t		braintargeton;

void __near A_BrainAwake ()
{
    THINKERREF	thinkerRef;
	mobj_t __far* m;
    // find all the target spots
    numbraintargets = 0;
    braintargeton = 0;
	
    for (thinkerRef = thinkerlist[0].next ;
	 thinkerRef != 0 ;
	 thinkerRef = thinkerlist[thinkerRef].next)
    {


	if ((thinkerlist[thinkerRef].prevFunctype & TF_FUNCBITS) != TF_MOBJTHINKER_HIGHBITS)
	    continue;	// not a mobj

	m = (mobj_t __far*)&thinkerlist[thinkerRef].data;


	if (m->type == MT_BOSSTARGET )
	{
	    braintargets[numbraintargets] = thinkerRef;
	    numbraintargets++;
	}
    }
	
	S_StartSoundFromRef(NULL,sfx_bossit);
}


void __near A_BrainPain ()
{
	S_StartSoundFromRef(NULL,sfx_bospn);
}


void __near A_BrainScream (mobj_t __far* mo, mobj_pos_t __far* mo_pos)
{
    fixed_t_union		x = mo_pos->x;
	fixed_t_union		y;
	fixed_t_union		z;
    mobj_t __far*	th;
	THINKERREF thRef;
	z.h.fracbits = 0;
	x.h.intbits -= 196;
    for (; x.h.intbits < mo_pos->x.h.intbits + 320; x.h.intbits += 8)
    {
		y = mo_pos->y;
		y.h.intbits -= 320;
		z.h.intbits = 128 + P_Random()*2;
		thRef = P_SpawnMobj (x.w,y.w,z.w, MT_ROCKET, -1);
		th = setStateReturn;
		th->momz.w = P_Random()*512;

		P_SetMobjState (th, S_BRAINEXPLODE1);
		//th = setStateReturn;

		th->tics -= P_Random()&7;
		if (th->tics < 1 || th->tics > 240) {
			th->tics = 1;
		}
    }
	
	S_StartSoundFromRef(NULL,sfx_bosdth);

}



void __near A_BrainExplode (mobj_t __far*mo, mobj_pos_t __far* mo_pos)
{
    fixed_t		x;
    fixed_t		y;
    fixed_t_union		z;
    mobj_t __far*	th;
	THINKERREF thRef;
	


    x = mo_pos->x.w + (P_Random () - P_Random ())*2048;
    y = mo_pos->y.w;
    z.h.intbits = 128 + P_Random()*2;
	z.h.fracbits = 0;
    thRef = P_SpawnMobj (x, y, z.w, MT_ROCKET, -1);
	th = setStateReturn;
    th->momz.w = P_Random()*512;

    P_SetMobjState (th, S_BRAINEXPLODE1);
	//th = setStateReturn;

    th->tics -= P_Random()&7;
    if (th->tics < 1 || th->tics > 240)
		th->tics = 1;
}



void __near A_BrainSpit (mobj_t __far* mo, mobj_pos_t __far* mo_pos)
{
	THINKERREF targRef;
	THINKERREF newmobjRef;
    mobj_t __far*	newmobj;
	
	mobj_t __far* targ;
	fixed_t moy;
	fixed_t targy;
	mobj_pos_t __far* targ_pos;
	mobj_pos_t __far* newmobj_pos;

    static int16_t	easy = 0;
	
    easy ^= 1;
    if (gameskill <= sk_easy && (!easy))
		return;
		
    // shoot a cube at current target
    targRef = braintargets[braintargeton];
    braintargeton = (braintargeton+1)%numbraintargets;



	targ = (mobj_t __far*)&thinkerlist[targRef].data;
	targ_pos = &mobjposlist[targRef];
	targy = targ_pos->y.w;
	moy = mo_pos->y.w;

    // spawn brain missile
    newmobjRef = P_SpawnMissile (mo, mo_pos, targ, MT_SPAWNSHOT);
	newmobj = setStateReturn;
	newmobj_pos = setStateReturn_pos;
	newmobj->targetRef = targRef;
    newmobj->reactiontime = ((targy - moy)/newmobj->momy.w) / states[newmobj_pos->stateNum].tics;

	S_StartSoundFromRef(NULL, sfx_bospit);
}



void __near A_SpawnFly (mobj_t __far* mo, mobj_pos_t __far* mo_pos);

// travelling cube sound
void __near A_SpawnSound (mobj_t __far* mobj, mobj_pos_t __far* mo_pos)
{
	S_StartSoundFromRef(mobj,sfx_boscub);
    A_SpawnFly(mobj, mo_pos);
}

void __near A_SpawnFly (mobj_t __far* mo, mobj_pos_t __far* mo_pos)
{
    mobj_t __far*	newmobj;
    mobj_t __far*	targ;
    uint8_t		r;
    mobjtype_t	type;
	THINKERREF targRef;
	THINKERREF newmobjRef;
	THINKERREF fogRef;
	mobj_pos_t __far* newmobj_pos;
	mobj_pos_t __far* targ_pos;
	//todoaddr inline later
	statenum_t (__far  * getSeeState)(uint8_t) = getSeeStateAddr;

	
    if (--mo->reactiontime)
		return;	// still flying
	
    targRef = mo->targetRef;
	targ = (mobj_t __far*)&thinkerlist[targRef].data;
	targ_pos = &mobjposlist[targRef];
    // First spawn teleport fog.
    fogRef = P_SpawnMobj (targ_pos->x.w, targ_pos->y.w, targ_pos->z.w, MT_SPAWNFIRE, targ->secnum);
    S_StartSoundFromRef (setStateReturn, sfx_telept);

    // Randomly select monster to spawn.
    r = P_Random ();

    // Probability distribution (kind of :),
    // decreasing likelihood.
    if ( r<50 )
		type = MT_TROOP;
    else if (r<90)
		type = MT_SERGEANT;
    else if (r<120)
		type = MT_SHADOWS;
    else if (r<130)
		type = MT_PAIN;
    else if (r<160)
		type = MT_HEAD;
    else if (r<162)
		type = MT_VILE;
    else if (r<172)
		type = MT_UNDEAD;
    else if (r<192)
		type = MT_BABY;
    else if (r<222)
		type = MT_FATSO;
    else if (r<246)
		type = MT_KNIGHT;
    else
		type = MT_BRUISER;		


    newmobjRef	= P_SpawnMobj (targ_pos->x.w, targ_pos->y.w, targ_pos->z.w, type, targ->secnum);
	newmobj = (mobj_t __far*)&thinkerlist[newmobjRef].data;
	newmobj_pos = &mobjposlist[newmobjRef];
	if (P_LookForPlayers(newmobj, true)) {
		P_SetMobjState(newmobj, getSeeState(newmobj->type));
	}

    // telefrag anything in this spot
    P_TeleportMove (newmobj, newmobj_pos, newmobj_pos->x, newmobj_pos->y, newmobj->secnum);

    // remove self (i.e., cube).
    P_RemoveMobj (mo);
}



void __near A_PlayerScream () {
	// mobj_t __far* mo = (mobj_t __far*)(&thinkerlist[moRef].data);
    // Default death sound.
    uint8_t		sound = sfx_pldeth;
	
    if ( commercial && 	(playerMobj->health < -50)) {
		// IF THE PLAYER DIES
		// LESS THAN -50% WITHOUT GIBBING
		sound = sfx_pdiehi;
    }
    
	S_StartSoundFromRef(playerMobj, sound);
}
