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





void A_Fall (MEMREF actorRef);


//
// ENEMY THINKING
// Enemies are allways spawned
// with targetplayer = -1, threshold = 0
// Most monsters are spawned unaware of all players,
// but some can be made preaware
//


//
// Called by P_NoiseAlert.
// Recursively traverse adjacent sectors,
// sound blocking lines cut off traversal.
//

MEMREF		soundtargetRef;

void
P_RecursiveSound
( int16_t		secnum,
  int32_t		soundblocks)
{
    int16_t		i;
	line_t* lines;
	line_t*	check;
    int16_t	othersecnum;
	int16_t linecount;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	sector_t* soundsector = &sectors[secnum];
	int16_t *linebuffer;
	side_t* sides;
	int16_t linenumber;
	int16_t checkflags;
	int16_t checksidenum0;
	int16_t checksidenum1;
	int16_t checkfrontsecnum;
	int16_t checkbacksecnum;
	uint16_t lineoffset;

	if (soundblocks < 0) {
		I_Error("bad soundblock P_RecursiveSound %i %i", soundblocks);
	}

	if (secnum < 0 || secnum >= numsectors) {
		// TODO remove
		I_Error("bad sectors in P_RecursiveSound %i %i", secnum);
	}
    // wake up all monsters in this sector
    if (soundsector->validcount == validcount && soundsector->soundtraversed <= soundblocks+1) {
		return;		// already flooded
    }
    
	soundsector->validcount = validcount;
	soundsector->soundtraversed = soundblocks+1;
	soundsector->soundtargetRef = soundtargetRef;


	linecount = soundsector->linecount;
	
	// todo load the whole sector's lines into te mp buffer to prevent trashing? Recursive function tho. would be lots of stack memory
	for (i=0 ;i<linecount ; i++) {
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		soundsector = &sectors[secnum];
		lineoffset = soundsector->linesoffset + i;
		linebuffer = (int16_t*)Z_LoadBytesFromEMS(linebufferRef);
		linenumber = linebuffer[lineoffset];

		

		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
		check = &lines[linenumber];
		checkflags = check->flags;
		checksidenum0 = check->sidenum[0];
		checksidenum1 = check->sidenum[1];
		checkfrontsecnum = check->frontsecnum;
		checkbacksecnum = check->backsecnum;

	 

		if (!(checkflags & ML_TWOSIDED)) {
			continue;
		}
		P_LineOpening (checksidenum1, checkfrontsecnum, checkbacksecnum );

		if (openrange <= 0) {
			continue;	// closed door
		}
	
		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		if (sides[checksidenum0].secnum == secnum) {
			othersecnum = sides[checksidenum1].secnum;
		} else {
			othersecnum = sides[checksidenum0].secnum;
		}
 
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
P_NoiseAlert
( MEMREF	targetRef,
  MEMREF	emmiterRef )
{
	mobj_t* emmiter = (mobj_t*)Z_LoadBytesFromEMS(emmiterRef);
	soundtargetRef = targetRef;
    validcount++;
    P_RecursiveSound (emmiter->secnum, 0);
}




//
// P_CheckMeleeRange
//
boolean P_CheckMeleeRange (MEMREF actorRef)
{
    mobj_t*	pl;
	MEMREF plRef;
    fixed_t	dist;
	fixed_t plx;
	fixed_t ply;
	fixed_t plradius;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (!actor->targetRef)
		return false;
		
	plRef = actor->targetRef;
	pl = (mobj_t*)Z_LoadBytesFromEMS(plRef);
	plx = pl->x;
	ply = pl->y;
	plradius = pl->info->radius*FRACUNIT;
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	dist = P_AproxDistance (plx-actor->x, ply-actor->y);

    if (dist >= MELEERANGE-20*FRACUNIT+plradius)
		return false;
    if (! P_CheckSight (actorRef, actor->targetRef) )
		return false;
							
    return true;		
}

//
// P_CheckMissileRange
//
boolean P_CheckMissileRange (MEMREF actorRef)
{
    fixed_t	dist;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	mobj_t* actorTarget;
	fixed_t actorTargetx;
	fixed_t actorTargety;

	if (!P_CheckSight(actorRef, actor->targetRef)) {

		return false;
	}
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if ( actor->flags & MF_JUSTHIT ) {
		// the target just hit the enemy,
		// so fight back!
		actor->flags &= ~MF_JUSTHIT;
		return true;
    }
	
	if (actor->reactiontime) {

		return false;	// do not attack yet
	}



	actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actor->targetRef);
	actorTargetx = actorTarget->x;
	actorTargety = actorTarget->y;    // OPTIMIZE: get this from a global checksight
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	dist = P_AproxDistance ( actor->x- actorTargetx,
			     actor->y- actorTargety) - 64*FRACUNIT;

    if (!getMeleeState(actor->type))
		dist -= 128*FRACUNIT;	// no melee attack, so fire more

    dist >>= 16;

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
fixed_t	xspeed[8] = {FRACUNIT,47000,0,-47000,-FRACUNIT,-47000,0,47000};
fixed_t yspeed[8] = {0,47000,FRACUNIT,47000,0,-47000,-FRACUNIT,-47000};

#define MAXSPECIALCROSS	8

extern	int16_t	spechit[MAXSPECIALCROSS];
extern	int16_t	numspechit;

boolean P_Move (MEMREF actorRef)
{
    fixed_t	tryx;
    fixed_t	tryy;
    
	int16_t linenum;
    
    // warning: 'catch', 'throw', and 'try'
    // are all C++ reserved words
    boolean	try_ok;
    boolean	good;

	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	
		
	if (actor->movedir == DI_NODIR) {
		return false;
	}
		
	if (actor->movedir >= 8) {
		I_Error("Weird actor->movedir!");
	}
		
    tryx = actor->x + actor->info->speed*xspeed[actor->movedir];
    tryy = actor->y + actor->info->speed*yspeed[actor->movedir];

	

	try_ok = P_TryMove (actorRef, tryx, tryy);


	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);




    if (!try_ok) {
		// open any specials
		if (actor->flags & MF_FLOAT && floatok) {
			// must adjust height
			if (actor->z < tmfloorz)
			actor->z += FLOATSPEED;
			else
			actor->z -= FLOATSPEED;

			actor->flags |= MF_INFLOAT;

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
			if (P_UseSpecialLine(actorRef, linenum, 0)) {
				good = true;
			}
		}

		return good;
    } else {
		actor->flags &= ~MF_INFLOAT;
 
	}

	
	if (!(actor->flags & MF_FLOAT)) {
		actor->z = actor->floorz;
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
boolean P_TryWalk (MEMREF actorRef)
{	
	mobj_t* actor; 
    if (!P_Move (actorRef)) {
		return false;
    }

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    actor->movecount = P_Random()&15;
    return true;
}




void P_NewChaseDir (MEMREF actorRef)
{
    fixed_t	deltax;
    fixed_t	deltay;
    
    dirtype_t	d[3];
    
    int8_t		tdir;
    dirtype_t	olddir;
    
    dirtype_t	turnaround;
	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef); 
	fixed_t actorx = actor->x;
	fixed_t actory = actor->y;

	mobj_t* actorTarget;
	
    if (!actor->targetRef)
		I_Error ("P_NewChaseDir: called with no target");
	olddir = actor->movedir;
	actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actor->targetRef);
		
    turnaround=opposite[olddir];

    deltax = actorTarget->x - actorx;
    deltay = actorTarget->y - actory;

    if (deltax>10*FRACUNIT)
		d[1]= DI_EAST;
    else if (deltax<-10*FRACUNIT)
		d[1]= DI_WEST;
    else
		d[1]=DI_NODIR;

    if (deltay<-10*FRACUNIT)
		d[2]= DI_SOUTH;
    else if (deltay>10*FRACUNIT)
		d[2]= DI_NORTH;
    else
		d[2]=DI_NODIR;
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    // try direct route
    if (d[1] != DI_NODIR && d[2] != DI_NODIR) {
		actor->movedir = diags[((deltay<0)<<1)+(deltax>0)];
		if (actor->movedir != turnaround && P_TryWalk(actorRef)) {
			return;
		}
    }

    // try other directions
    if (P_Random() > 200 ||  abs(deltay)>abs(deltax)) {
		tdir=d[1];
		d[1]=d[2];
		d[2]=tdir;
    }

    if (d[1]==turnaround)
		d[1]=DI_NODIR;
    if (d[2]==turnaround)
		d[2]=DI_NODIR;
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (d[1]!=DI_NODIR) {
			actor->movedir = d[1];
		if (P_TryWalk(actorRef)) {
			// either moved forward or attacked
			return;
		}
    }
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	

	if (d[2]!=DI_NODIR) {
		actor->movedir =d[2];

		if (P_TryWalk(actorRef)) {
			return;
		}
	}
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	// there is no direct path to the player,
	// so pick another direction.
	if (olddir!=DI_NODIR) {
		actor->movedir =olddir;

		if (P_TryWalk(actorRef)) {
			return;
		}
	}
	// randomly determine direction of search
	if (P_Random()&1) {
		for ( tdir=DI_EAST; tdir<=DI_SOUTHEAST; tdir++ ) {
			if (tdir != turnaround) {
				actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
				actor->movedir = tdir;
			
				if (P_TryWalk(actorRef)) {
					actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
					return;
				}
			}
		}

	} else {
		for ( tdir=DI_SOUTHEAST; tdir != (DI_EAST-1); tdir-- ) {
			if (tdir!=turnaround) {
				actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
				actor->movedir =tdir;
		
				if (P_TryWalk(actorRef)) {
					return;
				}
			}
		}
	}
	if (turnaround !=  DI_NODIR) {
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		actor->movedir =turnaround;
		if (P_TryWalk(actorRef)) {

			return;
		}
    }
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    actor->movedir = DI_NODIR;	// can not move

}



//
// P_LookForPlayers
// If allaround is false, only look 180 degrees in front.
// Returns true if a player is targeted.
//
boolean
P_LookForPlayers
( MEMREF	actorRef,
  boolean	allaround )
{
    int16_t		c;
    int8_t		stop;
    player_t*	player;
	//int16_t secnum;
    angle_t	an;
    fixed_t	dist;
	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	mobj_t* playerMo;
	fixed_t playerMoy;
	fixed_t playerMox;

	//secnum = actor->subsectorsecnum;

    c = 0;
    stop = (actor->lastlook-1)&3;


    for ( ; ; actor->lastlook = (actor->lastlook+1)&3 ) {
		Z_RefIsActive(actorRef);
		if (!playeringame[actor->lastlook])
			continue;
			
		if (c++ == 2
			|| actor->lastlook == stop)
		{
			// done looking
			return false;	
		}
	
		player = &players[actor->lastlook];
		if (player->health <= 0)
			continue;		// dead
	
		if (!P_CheckSight(actorRef, player->moRef)) {
			actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
			continue;		// out of sight
		}
		playerMo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);
		playerMox = playerMo->x;
		playerMoy = playerMo->y;
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

		if (!allaround) {
			an = R_PointToAngle2 (actor->x, actor->y,  playerMox, playerMoy) - actor->angle;
			if (an > ANG90 && an < ANG270) {
				dist = P_AproxDistance (playerMox - actor->x, playerMoy - actor->y);
				// if real close, react anyway
				if (dist > MELEERANGE) {
					continue;	// behind back
				}
			}
		}

		actor->targetRef = player->moRef;


		return true;
    }

    return false;
}


//
// A_KeenDie
// DOOM II special, map 32.
// Uses special tag 666.
//
void A_KeenDie (MEMREF moRef)
{
    THINKERREF	th;
    mobj_t*	mo2;
	mobj_t* mo;
	mobjtype_t motype;

    A_Fall (moRef);
    
    // scan the remaining thinkers
    // to see if all Keens are dead
    for (th = thinkerlist[0].next ; th != 0 ; th= thinkerlist[th].next) {
		if (thinkerlist[th].functionType != TF_MOBJTHINKER) {
			continue;
		}

		mo = (mobj_t *)Z_LoadBytesFromEMS(moRef);
		motype = mo->type;
		mo2 = (mobj_t *)Z_LoadBytesFromEMS(thinkerlist[th].memref);
		if (thinkerlist[th].memref != moRef && mo2->type == motype && mo2->health > 0) {
			// other Keen not dead
			return;		
		}
    }

    EV_DoDoor(666,open);
}


//
// ACTION ROUTINES
//

//
// A_Look
// Stay in state until a player is sighted.
//
void A_Look (MEMREF actorRef)
{
    mobj_t*	targ;
	MEMREF targRef;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	int16_t actorsecnum = actor->secnum;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);


	actor->threshold = 0;	// any shot will wake up

	#ifdef RANGECHECK
		if (actorsecnum > numsectors) {
			actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		}
	#endif
    targRef = sectors[actorsecnum].soundtargetRef;
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);


	if (targRef) {


		targ = (mobj_t*)Z_LoadBytesFromEMS(targRef);
		if (targ->flags & MF_SHOOTABLE) {
			actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
			actor->targetRef = targRef;

			if (actor->flags & MF_AMBUSH)
			{

				if (P_CheckSight(actorRef, actor->targetRef)) {

					goto seeyou;
				}
			}
			else {
				goto seeyou;
			}
		}

	}
 

	if (!P_LookForPlayers(actorRef, false)) {
		return;
	}

	// reload actor here, tends to get paged out


    // go into chase state
  seeyou:
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);


	if (actor->info->seesound) {
		int16_t		sound;
		switch (actor->info->seesound)
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
			  sound = actor->info->seesound;
			  break;
		}
		if (actor->type==MT_SPIDER || actor->type == MT_CYBORG) {
			// full volume
			S_StartSoundFromRef(NULL_MEMREF, sound);
		} else {

			S_StartSoundFromRef(actorRef, sound);
		}
    }

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    P_SetMobjState (actorRef, actor->info->seestate);
}


//
// A_Chase
// Actor has a melee attack,
// so it tries to close as fast as possible
//
void A_Chase (MEMREF actorRef)
{
    int32_t		delta; // cant set to angle_t due to it being uint

	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	MEMREF actortargetRef = actor->targetRef;
	mobj_t*	actorTarget;

    if (actor->reactiontime)
		actor->reactiontime--;
				

    // modify target threshold
    if  (actor->threshold) {
		if (actortargetRef) {
			//I_Error("actorRef %i", actor->targetRef);
			actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actortargetRef);
		}
		if (!actortargetRef || actorTarget->health <= 0) {
			actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
			actor->threshold = 0;
		} else {
			actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
			actor->threshold--;
		}
    }
    
	
    // turn towards movement direction if not there yet
    if (actor->movedir < 8) {
		actor->angle &= (7<<29);
		delta = actor->angle - (actor->movedir << 29);
	
		if (delta > 0)
			actor->angle -= ANG90/2;
		else if (delta < 0)
			actor->angle += ANG90/2;
    }
	if (actortargetRef) {
		actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actortargetRef);
	}


	
    if (!actortargetRef || !(actorTarget->flags&MF_SHOOTABLE)) {
		// look for a new target
		if (P_LookForPlayers(actorRef, true)) {
			 
	

			return; 	// got a new target
		}
	 
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_SetMobjState (actorRef, actor->info->spawnstate);
	 

		return;
    }

	

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    // do not attack twice in a row
    if (actor->flags & MF_JUSTATTACKED) {
		actor->flags &= ~MF_JUSTATTACKED;
		if (gameskill != sk_nightmare && !fastparm) {
			P_NewChaseDir(actorRef);
		}
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

		return;
    }

    // check for melee attack
    if (getMeleeState(actor->type) && P_CheckMeleeRange (actorRef)) {
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		if (actor->info->attacksound) {
			S_StartSoundFromRef(actorRef, actor->info->attacksound);
		}
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
 		P_SetMobjState (actorRef, getMeleeState(actor->type));

		return;
    }

    // check for missile attack
    if (actor->info->missilestate) {
		
		if (gameskill < sk_nightmare
			&& !fastparm && actor->movecount) {
		 		goto nomissile;
		}
	
		if (!P_CheckMissileRange(actorRef)) {
 			goto nomissile;
		}
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
 
		P_SetMobjState (actorRef, actor->info->missilestate);
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		actor->flags |= MF_JUSTATTACKED;

		return;
    }


    // ?
  nomissile:
    // possibly choose another target

	
	
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	
    // chase towards player

 
	if (--actor->movecount < 0 || !P_Move(actorRef)) {
		P_NewChaseDir(actorRef);

		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);


	}

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (actor->info->activesound && P_Random () < 3) {
		S_StartSoundFromRef(actorRef, actor->info->activesound);
    }

}


//
// A_FaceTarget
//
void A_FaceTarget (MEMREF actorRef)
{	
	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	mobj_t* actorTarget;
	fixed_t actorTargetx;
	fixed_t actorTargety;
	int8_t actorTargetShadow;

    if (!actor->targetRef)
		return;
    
    actor->flags &= ~MF_AMBUSH;
	actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actor->targetRef);
	actorTargetx = actorTarget->x;
	actorTargety = actorTarget->y;
	actorTargetShadow = actorTarget->flags & MF_SHADOW ? 1 : 0;


	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    actor->angle = R_PointToAngle2 (actor->x,
				    actor->y,
		actorTargetx,
		actorTargety);
    
    if (actorTargetShadow)
		actor->angle += (P_Random()-P_Random())<<21;
}


//
// A_PosAttack
//
void A_PosAttack (MEMREF actorRef)
{
    fineangle_t		angle;
    int16_t		damage;
    fixed_t		slope;
	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (!actor->targetRef)
		return;
		
    A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	angle = actor->angle >> ANGLETOFINESHIFT;
    slope = P_AimLineAttack (actorRef, angle, MISSILERANGE);

	S_StartSoundFromRef(actorRef, sfx_pistol);
    angle = MOD_FINE_ANGLE(angle + (((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
    damage = ((P_Random()%5)+1)*3;
    P_LineAttack (actorRef, angle, MISSILERANGE, slope, damage);
}

void A_SPosAttack (MEMREF actorRef)
{
    int8_t		i;
    fineangle_t		angle;
    fineangle_t		bangle;
    int8_t		damage;
    fixed_t		slope;
	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (!actor->targetRef)
		return;

	S_StartSoundFromRef(actorRef, sfx_shotgn);
    A_FaceTarget (actorRef);

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef); 
	bangle = actor->angle >> ANGLETOFINESHIFT;
    slope = P_AimLineAttack (actorRef, bangle, MISSILERANGE);

    for (i=0 ; i<3 ; i++) {
		angle = MOD_FINE_ANGLE((bangle + ((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
		damage = ((P_Random()%5)+1)*3;
		P_LineAttack (actorRef, angle, MISSILERANGE, slope, damage);
    }
}

void A_CPosAttack (MEMREF actorRef)
{
    fineangle_t		angle;
    fineangle_t		bangle;
    int8_t		damage;
    fixed_t		slope;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (!actor->targetRef)
		return;

	S_StartSoundFromRef(actorRef, sfx_shotgn);
    A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    bangle = (actor->angle) >> ANGLETOFINESHIFT;
    slope = P_AimLineAttack (actorRef, bangle, MISSILERANGE);

    angle = MOD_FINE_ANGLE((bangle + ((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
    damage = ((P_Random()%5)+1)*3;
    P_LineAttack (actorRef, angle, MISSILERANGE, slope, damage);
}

void A_CPosRefire (MEMREF actorRef)
{	
    // keep firing unless target got out of sight
	mobj_t* actor;
	mobj_t* actorTarget;
	MEMREF actortargetRef;
	A_FaceTarget (actorRef);
	
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	actortargetRef = actor->targetRef;
    if (P_Random () < 40)
		return;

	if (!actortargetRef)
		return;

	actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actortargetRef);
    if (!actortargetRef || actorTarget->health <= 0 || !P_CheckSight(actorRef, actortargetRef)) {
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_SetMobjState (actorRef, actor->info->seestate);
    }
}


void A_SpidRefire (MEMREF actorRef)
{	
    // keep firing unless target got out of sight
	mobj_t* actor;
	mobj_t* actorTarget;
	MEMREF 	actortargetRef;
	A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	actortargetRef = actor->targetRef;

	if (P_Random() < 10) {
		return;
	}

	if (!actortargetRef) {
		return;
	}

	actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actortargetRef);

    if (!actortargetRef || actorTarget->health <= 0 || !P_CheckSight(actorRef, actortargetRef)) {
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_SetMobjState (actorRef, actor->info->seestate);
    }
}

void A_BspiAttack (MEMREF actorRef)
{	
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	if (!actor->targetRef) {
		return;
	}
		
    A_FaceTarget (actorRef);

    // launch a missile
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	P_SpawnMissile (actorRef, actor->targetRef, MT_ARACHPLAZ);
}


//
// A_TroopAttack
//
void A_TroopAttack (MEMREF actorRef)
{
    int16_t		damage;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (!actor->targetRef)
		return;
		
    A_FaceTarget (actorRef);
    if (P_CheckMeleeRange (actorRef)) {
		S_StartSoundFromRef(actorRef, sfx_claw);
		damage = (P_Random()%8+1)*3;
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_DamageMobj (actor->targetRef, actorRef, actorRef, damage);
		return;
    }

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    // launch a missile
    P_SpawnMissile (actorRef, actor->targetRef, MT_TROOPSHOT);
}


void A_SargAttack (MEMREF actorRef)
{
    int16_t		damage;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

	if (!actor->targetRef) {
		return;
	}
		
    A_FaceTarget (actorRef);
    if (P_CheckMeleeRange (actorRef)) {
		damage = ((P_Random()%10)+1)*4;
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_DamageMobj (actor->targetRef, actorRef, actorRef, damage);
    }
}

void A_HeadAttack (MEMREF actorRef)
{
    int16_t		damage;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

	if (!actor->targetRef) {
		return;
	}

    A_FaceTarget (actorRef);
    if (P_CheckMeleeRange (actorRef)) {
		damage = (P_Random()%6+1)*10;
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_DamageMobj (actor->targetRef, actorRef, actorRef, damage);
		return;
    }
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    // launch a missile
    P_SpawnMissile (actorRef, actor->targetRef, MT_HEADSHOT);
}

void A_CyberAttack (MEMREF actorRef)
{	
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (!actor->targetRef)
		return;
		
    A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	P_SpawnMissile (actorRef, actor->targetRef, MT_ROCKET);
}


void A_BruisAttack (MEMREF actorRef)
{
    int16_t		damage;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (!actor->targetRef)
		return;
		
    if (P_CheckMeleeRange (actorRef)){
		S_StartSoundFromRef(actorRef, sfx_claw);
		damage = (P_Random()%8+1)*10;
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_DamageMobj (actor->targetRef, actorRef, actorRef, damage);
		return;
    }
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    // launch a missile
    P_SpawnMissile (actorRef, actor->targetRef, MT_BRUISERSHOT);
}


//
// A_SkelMissile
//
void A_SkelMissile (MEMREF actorRef)
{	
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	mobj_t*	mo;
	MEMREF moRef;
	MEMREF actortargetRef;

	if (!actor->targetRef) {
		return;
	}
		
    A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    actor->z += 16*FRACUNIT;	// so missile spawns higher
    moRef = P_SpawnMissile (actorRef, actor->targetRef, MT_TRACER);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	actor->z -= 16*FRACUNIT;	// back to normal
	actortargetRef = actor->targetRef;
	
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	mo->x += mo->momx;
    mo->y += mo->momy;
    mo->tracerRef = actortargetRef;
}

angle_t	TRACEANGLE = 0xc000000;

void A_Tracer (MEMREF actorRef)
{
    angle_t	exact;
    fixed_t	dist;
    fixed_t	slope;
    mobj_t*	dest;
    mobj_t*	th;
	mobj_t* actor;
	MEMREF thRef;
	fixed_t actorx;
	fixed_t actory;
	fixed_t destz;
	fixed_t actorspeed;

    if (gametic & 3)
		return;
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    
    // spawn a puff of smoke behind the rocket		
    P_SpawnPuff (actor->x, actor->y, actor->z);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

	thRef = P_SpawnMobj (actor->x-actor->momx,
		      actor->y-actor->momy,
		      actor->z, MT_SMOKE);
    
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);

    th->momz = FRACUNIT;
    th->tics -= P_Random()&3;
    if (th->tics < 1)
	th->tics = 1;
    
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

	if (!actor->tracerRef) {
		return;
	}
	actorx = actor->x;
	actory = actor->y;

    // adjust direction
    dest = (mobj_t*)Z_LoadBytesFromEMS(actor->tracerRef);
	
    if (!dest || dest->health <= 0)
		return;
    
    // change angle	
    exact = R_PointToAngle2 (actorx,
			     actory,
			     dest->x,
			     dest->y);
	
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    if (exact != actor->angle) {
		if (exact - actor->angle > 0x80000000) {
			actor->angle -= TRACEANGLE;
			if (exact - actor->angle < 0x80000000)
			actor->angle = exact;
		} else {
			actor->angle += TRACEANGLE;
			if (exact - actor->angle > 0x80000000)
			actor->angle = exact;
		}
    }
	actorspeed = MAKESPEED(actor->info->speed);
    exact = actor->angle>>ANGLETOFINESHIFT;
    actor->momx = FixedMul (actorspeed, finecosine(exact));
    actor->momy = FixedMul (actorspeed, finesine(exact));
	actorx = actor->x;
	actory = actor->y;
	
	dest = (mobj_t*)Z_LoadBytesFromEMS(actor->tracerRef);
	destz = dest->z;
    
	// change slope
    dist = P_AproxDistance (dest->x - actorx,
			    dest->y - actory);
    
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);

    dist = dist / actorspeed;

	if (dist < 1) {
		dist = 1;
	}
    slope = (destz+40*FRACUNIT - actor->z) / dist;

    if (slope < actor->momz)
		actor->momz -= FRACUNIT/8;
    else
		actor->momz += FRACUNIT/8;
}


void A_SkelWhoosh (MEMREF actorRef)
{
	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (!actor->targetRef)
		return;

    A_FaceTarget (actorRef);
	S_StartSoundFromRef(actorRef,sfx_skeswg);
}

void A_SkelFist (MEMREF actorRef)
{
    int16_t		damage;
	mobj_t*	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (!actor->targetRef)
		return;
		
    A_FaceTarget (actorRef);
	
    if (P_CheckMeleeRange (actorRef)) {
		damage = ((P_Random()%10)+1)*6;
		S_StartSoundFromRef(actorRef, sfx_skepch);
		actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
		P_DamageMobj (actor->targetRef, actorRef, actorRef, damage);
    }
}



//
// PIT_VileCheck
// Detect a corpse that could be raised.
//
MEMREF		corpsehitRef;
mobj_t*		vileobj;
fixed_t		viletryx;
fixed_t		viletryy;

boolean PIT_VileCheck (MEMREF thingRef)
{
    fixed_t		maxdist;
    boolean	check;
	mobj_t*	thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);
	
	if (!(thing->flags & MF_CORPSE)) {
		return true;	// not a monster
	}
    
	if (thing->tics != -1) {
		return true;	// not lying still yet
	}

	if (getRaiseState(thing->type) == S_NULL) {
		return true;	// monster doesn't have a raise state
	}

    maxdist = (thing->info->radius + mobjinfo[MT_VILE].radius)*FRACUNIT;
	
	if (abs(thing->x - viletryx) > maxdist || abs(thing->y - viletryy) > maxdist) {
		return true;		// not actually touching
	}
		
	corpsehitRef = thingRef;
    thing->momx = thing->momy = 0;
	thing->height <<= 2;
    check = P_CheckPosition (corpsehitRef, thing->x, thing->y);
	thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);
	thing->height >>= 2;

	if (!check) {
		return true;		// doesn't fit here
	}
    return false;		// got one, so stop checking
}



//
// A_VileChase
// Check for ressurecting a body
//
void A_VileChase (MEMREF actorRef)
{
    int16_t			xl;
    int16_t			xh;
    int16_t			yl;
    int16_t			yh;
    
    int16_t			bx;
    int16_t			by;

    mobjinfo_t*		info;
    MEMREF		temp;
	mobj_t*	corpsehit;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (actor->movedir != DI_NODIR) {
		// check for corpses to raise
		viletryx = actor->x + actor->info->speed*xspeed[actor->movedir];
		viletryy = actor->y + actor->info->speed*yspeed[actor->movedir];

		xl = (viletryx - bmaporgx - MAXRADIUS*2)>>MAPBLOCKSHIFT;
		xh = (viletryx - bmaporgx + MAXRADIUS*2)>>MAPBLOCKSHIFT;
		yl = (viletryy - bmaporgy - MAXRADIUS*2)>>MAPBLOCKSHIFT;
		yh = (viletryy - bmaporgy + MAXRADIUS*2)>>MAPBLOCKSHIFT;
	
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
				actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
				temp = actor->targetRef;
				actor->targetRef = corpsehitRef;
				A_FaceTarget (actorRef);
				actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
				actor->targetRef = temp;
					
				P_SetMobjState (actorRef, S_VILE_HEAL1);
				S_StartSoundFromRef(corpsehitRef, sfx_slop);
				corpsehit = (mobj_t*)Z_LoadBytesFromEMS(corpsehitRef);
				info = corpsehit->info;
		    
				P_SetMobjState (corpsehitRef,getRaiseState(corpsehit->type));
				corpsehit = (mobj_t*)Z_LoadBytesFromEMS(corpsehitRef);
				corpsehit->height <<= 2;
				corpsehit->flags = info->flags;
				corpsehit->health = info->spawnhealth;
				corpsehit->targetRef = NULL_MEMREF;

				return;
			}
			}
		}
    }

    // Return to normal attack.
    A_Chase (actorRef);
}


//
// A_VileStart
//
void A_VileStart (MEMREF actorRef)
{
	S_StartSoundFromRef(actorRef, sfx_vilatk);
}


//
// A_Fire
// Keep fire in front of player unless out of sight
//
void A_Fire (MEMREF actorRef);

void A_StartFire (MEMREF actorRef)
{
	S_StartSoundFromRef(actorRef,sfx_flamst);
    A_Fire(actorRef);
}

void A_FireCrackle (MEMREF actorRef)
{
	S_StartSoundFromRef(actorRef,sfx_flame);
    A_Fire(actorRef);
}

void A_Fire (MEMREF actorRef)
{
    MEMREF	destRef;
	uint16_t	an;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	mobj_t* dest;
	fixed_t destx;
	fixed_t desty;
	fixed_t destz;

    destRef = actor->tracerRef;
    if (!destRef)
		return;
		
    // don't move it if the vile lost sight
    if (!P_CheckSight (actor->targetRef, destRef) )
		return;
	dest = (mobj_t*)Z_LoadBytesFromEMS(destRef);
	destx = dest->x;
	desty = dest->y;
	destz = dest->z;

    an = dest->angle >> ANGLETOFINESHIFT;

    P_UnsetThingPosition (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	actor->x = destx + FixedMul (24*FRACUNIT, finecosine(an));
    actor->y = desty + FixedMul (24*FRACUNIT, finesine(an));
    actor->z = destz;
    P_SetThingPosition (actorRef);
}



//
// A_VileTarget
// Spawn the hellfire
//
void A_VileTarget (MEMREF actorRef)
{
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	mobj_t* actorTarget;
	mobj_t* fog;
	MEMREF fogRef;
	MEMREF actortargetRef;
	if (!actor->targetRef)
		return;

    A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actor->targetRef);
    fogRef = P_SpawnMobj (actorTarget->x,
		actorTarget->x,
		actorTarget->z, MT_FIRE);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    actor->tracerRef = fogRef;
	actortargetRef = actor->targetRef;
	fog = (mobj_t*)Z_LoadBytesFromEMS(fogRef);

	fog->targetRef = actorRef;
    fog->tracerRef = actortargetRef;
    A_Fire (fogRef);
}




//
// A_VileAttack
//
void A_VileAttack (MEMREF actorRef)
{	
    MEMREF	fireRef;
    uint16_t		an;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	mobj_t* actorTarget;
	mobj_t* fire;
	fixed_t actorTargetx;
	fixed_t actorTargety;
	if (!actor->targetRef)
		return;
    
    A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (!P_CheckSight(actorRef, actor->targetRef))
		return;

	S_StartSoundFromRef (actorRef, sfx_barexp);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	P_DamageMobj (actor->targetRef, actorRef, actorRef, 20);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	an = actor->angle >> ANGLETOFINESHIFT;
	fireRef = actor->tracerRef;


	actorTarget = (mobj_t*)Z_LoadBytesFromEMS(actor->targetRef);
	actorTarget->momz = 1000*FRACUNIT/ getMobjMass(actorTarget->type);
	actorTargetx = actorTarget->x;
	actorTargety = actorTarget->y;


    if (!fireRef)
		return;
		
	fire = (mobj_t*)Z_LoadBytesFromEMS(fireRef);
	// move the fire between the vile and the player
    fire->x = actorTargetx - FixedMul (24*FRACUNIT, finecosine(an));
    fire->y = actorTargety - FixedMul (24*FRACUNIT, finesine(an));
    P_RadiusAttack (fireRef, actorRef, 70 );
}




//
// Mancubus attack,
// firing three missiles (bruisers)
// in three different directions?
// Doesn't look like it. 
//
#define	FATSPREAD	(ANG90/8)

void A_FatRaise (MEMREF actorRef)
{
    A_FaceTarget (actorRef);
    S_StartSoundFromRef (actorRef, sfx_manatk);
}


void A_FatAttack1 (MEMREF actorRef)
{
    mobj_t*	mo;
    uint16_t		an;
	mobj_t* actor;
	MEMREF moRef;

    A_FaceTarget (actorRef);
    // Change direction  to ...
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    actor->angle += FATSPREAD;
    P_SpawnMissile (actorRef, actor->targetRef, MT_FATSHOT);

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    moRef = P_SpawnMissile (actorRef, actor->targetRef, MT_FATSHOT);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    mo->angle += FATSPREAD;
    an = mo->angle >> ANGLETOFINESHIFT;
    mo->momx = FixedMul (MAKESPEED(mo->info->speed), finecosine(an));
    mo->momy = FixedMul (MAKESPEED(mo->info->speed), finesine(an));
}

void A_FatAttack2 (MEMREF actorRef)
{
    mobj_t*	mo;
    uint16_t		an;
	mobj_t*	actor;
	MEMREF moRef;
	MEMREF actortargetRef;
	
	A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	// Now here choose opposite deviation.
    actor->angle -= FATSPREAD;
	actortargetRef = actor->targetRef;
    P_SpawnMissile (actorRef, actortargetRef, MT_FATSHOT);

    moRef = P_SpawnMissile (actorRef, actortargetRef, MT_FATSHOT);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    mo->angle -= FATSPREAD*2;
    an = mo->angle >> ANGLETOFINESHIFT;
    mo->momx = FixedMul (MAKESPEED(mo->info->speed), finecosine(an));
    mo->momy = FixedMul (MAKESPEED(mo->info->speed), finesine(an));
}

void A_FatAttack3 (MEMREF actorRef)
{
    mobj_t*	mo;
    uint16_t		an;
	mobj_t* actor;
	MEMREF moRef;
	MEMREF actortargetRef;
	fixed_t mospeed;
	A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	actortargetRef = actor->targetRef;

    moRef = P_SpawnMissile (actorRef, actortargetRef, MT_FATSHOT);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	
	// todo hardcode this value, it's static..
	mospeed = MAKESPEED(mo->info->speed);
    mo->angle -= FATSPREAD/2;
    an = mo->angle >> ANGLETOFINESHIFT;
    mo->momx = FixedMul (mospeed, finecosine(an));
    mo->momy = FixedMul (mospeed, finesine(an));

    moRef = P_SpawnMissile (actorRef, actortargetRef, MT_FATSHOT);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	mo->angle += FATSPREAD/2;
    an = mo->angle >> ANGLETOFINESHIFT;
    mo->momx = FixedMul (mospeed, finecosine(an));
    mo->momy = FixedMul (mospeed, finesine(an));
}


//
// SkullAttack
// Fly at the player like a missile.
//
#define	SKULLSPEED		(20*FRACUNIT)

void A_SkullAttack (MEMREF actorRef)
{
    mobj_t*		dest;
	MEMREF		destRef;
    angle_t		an;
    fixed_t			dist;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	fixed_t destx;
	fixed_t desty;
	fixed_t destz;
	fixed_t destheight;

	if (!actor->targetRef) {
		return;
	}

	actor->flags |= MF_SKULLFLY;

    destRef = actor->targetRef;	

	S_StartSoundFromRef(actorRef, actor->info->attacksound);
    A_FaceTarget (actorRef);
	dest = (mobj_t*)Z_LoadBytesFromEMS(destRef);
	destx = dest->x;
	desty = dest->y;
	destz = dest->z;
	destheight = dest->height;

	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    an = actor->angle >> ANGLETOFINESHIFT;
    actor->momx = FixedMul (SKULLSPEED, finecosine(an));
    actor->momy = FixedMul (SKULLSPEED, finesine(an));
    dist = P_AproxDistance (destx - actor->x, desty - actor->y);
    dist = dist / SKULLSPEED;
    
	if (dist < 1) {
		dist = 1;
	}
    actor->momz = (destz+(destheight>>1) - actor->z) / dist;
}


//
// A_PainShootSkull
// Spawn a lost soul and launch it at the target
//
void
A_PainShootSkull
(MEMREF actorRef,
  angle_t	angle )
{
    fixed_t	x;
    fixed_t	y;
    fixed_t	z;
    
    mobj_t*	newmobj;
    angle_t	an;
    fixed_t		prestep;
    int16_t		count;
    THINKERREF	currentthinker;
	MEMREF newmobjRef;
	MEMREF actortargetRef;
	mobj_t* actor;
	
	// count total number of skull currently on the level
    count = 0;

    currentthinker = thinkerlist[0].next;
    while (currentthinker != 0) {
		if ((thinkerlist[currentthinker].functionType == TF_MOBJTHINKER)
			&& ((mobj_t *)Z_LoadBytesFromEMS(thinkerlist[currentthinker].memref))->type == MT_SKULL) {
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
    an = angle >> ANGLETOFINESHIFT;
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	actortargetRef = actor->targetRef;
	prestep = 4*FRACUNIT + 3*FRACUNIT*(actor->info->radius + mobjinfo[MT_SKULL].radius)/2;
    
    x = actor->x + FixedMul (prestep, finecosine(an));
    y = actor->y + FixedMul (prestep, finesine(an));
    z = actor->z + 8*FRACUNIT;
		
    newmobjRef = P_SpawnMobj (x , y, z, MT_SKULL);
	newmobj = (mobj_t*)Z_LoadBytesFromEMS(newmobjRef);
    // Check for movements.

	if (!P_TryMove (newmobjRef, newmobj->x, newmobj->y)) {
		// kill it immediately
		P_DamageMobj (newmobjRef,actorRef,actorRef,10000);	
		return;
    }
	newmobj = (mobj_t*)Z_LoadBytesFromEMS(newmobjRef);

    newmobj->targetRef = actortargetRef;
    A_SkullAttack (newmobjRef);
}


//
// A_PainAttack
// Spawn a lost soul and launch it at the target
// 
void A_PainAttack (MEMREF actorRef)
{
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (!actor->targetRef)
		return;

    A_FaceTarget (actorRef);
	actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    A_PainShootSkull (actorRef, actor->angle);
}


void A_PainDie (MEMREF actorRef)
{
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	angle_t actorangle = actor->angle;
    A_Fall (actorRef);
    A_PainShootSkull (actorRef, actorangle+ANG90);
    A_PainShootSkull (actorRef, actorangle+ANG180);
    A_PainShootSkull (actorRef, actorangle+ANG270);
}






void A_Scream (MEMREF actorRef)
{
    uint8_t		sound;
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	
    switch (actor->info->deathsound)
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
	sound = actor->info->deathsound;
	break;
    }

    // Check for bosses.
    if (actor->type==MT_SPIDER || actor->type == MT_CYBORG) {
		// full volume
		S_StartSoundFromRef(NULL_MEMREF, sound);
	} else {
		S_StartSoundFromRef(actorRef, sound);
	}
}


void A_XScream (MEMREF actorRef)
{

	S_StartSoundFromRef(actorRef, sfx_slop);
}

void A_Pain (MEMREF actorRef)
{
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
    if (actor->info->painsound)
		S_StartSoundFromRef(actorRef, actor->info->painsound);
}



void A_Fall (MEMREF actorRef)
{
	mobj_t* actor = (mobj_t*)Z_LoadBytesFromEMS(actorRef);
	// actor is on ground, it can be walked over
    actor->flags &= ~MF_SOLID;

    // So change this if corpse objects
    // are meant to be obstacles.
}


//
// A_Explode
//
void A_Explode (MEMREF thingyRef)
{
	mobj_t* thingy = (mobj_t*)Z_LoadBytesFromEMS(thingyRef);
    P_RadiusAttack ( thingyRef, thingy->targetRef, 128 );

}


//
// A_BossDeath
// Possibly trigger special effects
// if on first boss level
//
void A_BossDeath (MEMREF moRef)
{
    THINKERREF	th;
    mobj_t*	mo2;
    line_t	junk;
	mobj_t* mo = (mobj_t *)Z_LoadBytesFromEMS(moRef);
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
	if (players[0].health <= 0)
		return; // no one left alive, so do not end game

    // scan the remaining thinkers to see
    // if all bosses are dead
	for (th = thinkerlist[0].next; th != 0; th = thinkerlist[th].next)
	{
	if (thinkerlist[th].functionType != TF_MOBJTHINKER)
	    continue;
	
	mo2 = (mobj_t *)Z_LoadBytesFromEMS(thinkerlist[th].memref);
	if (thinkerlist[th].memref != moRef
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
		EV_DoFloor(666, -1,lowerFloorToLowest);
		return;
	    }
	    
	    if (motype == MT_BABY)
	    {
		EV_DoFloor(667, -1,raiseToTexture);
		return;
	    }
	}
    }
    else
    {
	switch(gameepisode)
	{
	  case 1:
	    EV_DoFloor (666, -1, lowerFloorToLowest);
	    return;
	    break;
	    
	  case 4:
	    switch(gamemap)
	    {
	      case 6:
		EV_DoDoor (666, blazeOpen);
		return;
		break;
		
	      case 8:
		EV_DoFloor (666, -1, lowerFloorToLowest);
		return;
		break;
	    }
	}
    }
	
    G_ExitLevel ();
}


void A_Hoof (MEMREF moRef)
{
	S_StartSoundFromRef(moRef, sfx_hoof);
    A_Chase (moRef);
}

void A_Metal (MEMREF moRef)
{
	S_StartSoundFromRef(moRef, sfx_metal);
    A_Chase (moRef);
}

void A_BabyMetal (MEMREF moRef)
{
	S_StartSoundFromRef(moRef, sfx_bspwlk);
    A_Chase (moRef);
}

void
A_OpenShotgun2
( player_t*	player,
  pspdef_t*	psp )
{
	S_StartSoundFromRef(player->moRef, sfx_dbopn);
}

void
A_LoadShotgun2
( player_t*	player,
  pspdef_t*	psp )
{
	S_StartSoundFromRef(player->moRef, sfx_dbload);
}

void
A_ReFire
( player_t*	player,
  pspdef_t*	psp );

void
A_CloseShotgun2
( player_t*	player,
  pspdef_t*	psp )
{
    S_StartSoundFromRef (player->moRef, sfx_dbcls);
    A_ReFire(player,psp);
}



MEMREF		braintargets[32];
int16_t		numbraintargets;
int16_t		braintargeton;

void A_BrainAwake (MEMREF moRef)
{
    THINKERREF	thinkerRef;
    mobj_t*	m;
	
    // find all the target spots
    numbraintargets = 0;
    braintargeton = 0;
	
    for (thinkerRef = thinkerlist[0].next ;
	 thinkerRef != 0 ;
	 thinkerRef = thinkerlist[thinkerRef].next)
    {
	if (thinkerlist[thinkerRef].functionType != TF_MOBJTHINKER)
	    continue;	// not a mobj

	m = (mobj_t *)Z_LoadBytesFromEMS(thinkerlist[thinkerRef].memref);


	if (m->type == MT_BOSSTARGET )
	{
	    braintargets[numbraintargets] = thinkerlist[thinkerRef].memref;
	    numbraintargets++;
	}
    }
	
	S_StartSoundFromRef(NULL_MEMREF,sfx_bossit);
}


void A_BrainPain (MEMREF moRef)
{
	S_StartSoundFromRef(NULL_MEMREF,sfx_bospn);
}


void A_BrainScream (MEMREF moRef)
{
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
    mobj_t*	th;
	MEMREF thRef;
	mobj_t*mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	
    for (x=mo->x - 196*FRACUNIT ; x< mo->x + 320*FRACUNIT ; x+= FRACUNIT*8)
    {
	y = mo->y - 320*FRACUNIT;
	z = 128 + P_Random()*2*FRACUNIT;
	thRef = P_SpawnMobj (x,y,z, MT_ROCKET);
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);
	th->momz = P_Random()*512;

	P_SetMobjState (thRef, S_BRAINEXPLODE1);
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);

	th->tics -= P_Random()&7;
	if (th->tics < 1)
	    th->tics = 1;
    }
	
	S_StartSoundFromRef(NULL_MEMREF,sfx_bosdth);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
}



void A_BrainExplode (MEMREF moRef)
{
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
    mobj_t*	th;
	MEMREF thRef;
	mobj_t*mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);


    x = mo->x + (P_Random () - P_Random ())*2048;
    y = mo->y;
    z = 128 + P_Random()*2*FRACUNIT;
    thRef = P_SpawnMobj (x,y,z, MT_ROCKET);
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);
    th->momz = P_Random()*512;

    P_SetMobjState (thRef, S_BRAINEXPLODE1);
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);

    th->tics -= P_Random()&7;
    if (th->tics < 1)
	th->tics = 1;
}


void A_BrainDie (MEMREF moRef)
{
    G_ExitLevel ();
}

void A_BrainSpit (MEMREF moRef)
{
	MEMREF targRef;
	MEMREF newmobjRef;
    mobj_t*	newmobj;
	mobj_t* mo;
	mobj_t* targ;
	fixed_t moy;
	fixed_t targy;
    
    static int16_t	easy = 0;
	
    easy ^= 1;
    if (gameskill <= sk_easy && (!easy))
	return;
		
    // shoot a cube at current target
    targRef = braintargets[braintargeton];
    braintargeton = (braintargeton+1)%numbraintargets;

	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	moy = mo->y;

	targ = (mobj_t*)Z_LoadBytesFromEMS(targRef);
	targy = targ->y;


    // spawn brain missile
    newmobjRef = P_SpawnMissile (moRef, targRef, MT_SPAWNSHOT);
	newmobj = (mobj_t*)Z_LoadBytesFromEMS(newmobjRef);
	newmobj->targetRef = targRef;
    newmobj->reactiontime = ((targy - moy)/newmobj->momy) / newmobj->state->tics;

	S_StartSoundFromRef(NULL_MEMREF, sfx_bospit);
}



void A_SpawnFly (MEMREF moRef);

// travelling cube sound
void A_SpawnSound (MEMREF moRef)
{
	S_StartSoundFromRef(moRef,sfx_boscub);
    A_SpawnFly(moRef);
}

void A_SpawnFly (MEMREF moRef)
{
    mobj_t*	newmobj;
    mobj_t*	fog;
    mobj_t*	targ;
    uint8_t		r;
    mobjtype_t	type;
	MEMREF targRef;
	MEMREF newmobjRef;
	MEMREF fogRef;
	mobj_t* mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	

	
    if (--mo->reactiontime)
		return;	// still flying
	
    targRef = mo->targetRef;
	targ = (mobj_t*)Z_LoadBytesFromEMS(targRef);

    // First spawn teleport fog.
    fogRef = P_SpawnMobj (targ->x, targ->y, targ->z, MT_SPAWNFIRE);
    S_StartSoundFromRef (fogRef, sfx_telept);

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

	targ = (mobj_t*)Z_LoadBytesFromEMS(targRef);

    newmobjRef	= P_SpawnMobj (targ->x, targ->y, targ->z, type);
	newmobj = (mobj_t*)Z_LoadBytesFromEMS(newmobjRef);
	if (P_LookForPlayers(newmobjRef, true)) {
		P_SetMobjState(newmobjRef, newmobj->info->seestate);
	}
	newmobj = (mobj_t*)Z_LoadBytesFromEMS(newmobjRef);

    // telefrag anything in this spot
    P_TeleportMove (newmobjRef, newmobj->x, newmobj->y);

    // remove self (i.e., cube).
    P_RemoveMobj (moRef);
}



void A_PlayerScream (MEMREF moRef) {
	mobj_t* mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    // Default death sound.
    uint8_t		sound = sfx_pldeth;
	
    if ( commercial
	&& 	(mo->health < -50))
    {
	// IF THE PLAYER DIES
	// LESS THAN -50% WITHOUT GIBBING
	sound = sfx_pdiehi;
    }
    
	S_StartSoundFromRef(moRef, sound);
}
