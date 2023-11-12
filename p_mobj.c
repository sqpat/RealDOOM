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
//	Moving object handling. Spawn functions.
//

#include "i_system.h"
#include "z_zone.h"
#include "m_misc.h"

#include "doomdef.h"
#include "p_local.h"
#include "sounds.h"

#include "st_stuff.h"
#include "hu_stuff.h"

#include "s_sound.h"

#include "doomstat.h"
#include "p_setup.h"


extern boolean playerSpawned;

void G_PlayerReborn ();
void P_SpawnMapThing (mapthing_t*	mthing, int16_t key);


void A_Explode(MEMREF, mobj_t* mobjmoRef);
void A_Pain(MEMREF moRef, mobj_t* mobj);
void A_PlayerScream();
void A_Fall(MEMREF moRef, mobj_t* mobj);
void A_XScream(MEMREF moRef, mobj_t* mobj);
void A_Look(MEMREF moRef, mobj_t* mobj);
void A_Chase(MEMREF moRef, mobj_t* mobj);
void A_FaceTarget(MEMREF moRef, mobj_t* mobj);
void A_PosAttack(MEMREF moRef, mobj_t* mobj);
void A_Scream(MEMREF moRef, mobj_t* mobj);
void A_SPosAttack(MEMREF moRef, mobj_t* mobj);
void A_VileChase(MEMREF moRef, mobj_t* mobj);
void A_VileStart(MEMREF moRef, mobj_t* mobj);
void A_VileTarget(MEMREF moRef, mobj_t* mobj);
void A_VileAttack(MEMREF moRef, mobj_t* mobj);
void A_StartFire(MEMREF moRef, mobj_t* mobj);
void A_Fire(MEMREF moRef, mobj_t* mobj);
void A_FireCrackle(MEMREF moRef, mobj_t* mobj);
void A_Tracer(MEMREF moRef, mobj_t* mobj);
void A_SkelWhoosh(MEMREF moRef, mobj_t* mobj);
void A_SkelFist(MEMREF moRef, mobj_t* mobj);
void A_SkelMissile(MEMREF moRef, mobj_t* mobj);
void A_FatRaise(MEMREF moRef, mobj_t* mobj);
void A_FatAttack1(MEMREF moRef, mobj_t* mobj);
void A_FatAttack2(MEMREF moRef, mobj_t* mobj);
void A_FatAttack3(MEMREF moRef, mobj_t* mobj);
void A_BossDeath(MEMREF moRef, mobj_t* mobj);
void A_CPosAttack(MEMREF moRef, mobj_t* mobj);
void A_CPosRefire(MEMREF moRef, mobj_t* mobj);
void A_TroopAttack(MEMREF moRef, mobj_t* mobj);
void A_SargAttack(MEMREF moRef, mobj_t* mobj);
void A_HeadAttack(MEMREF moRef, mobj_t* mobj);
void A_BruisAttack(MEMREF moRef, mobj_t* mobj);
void A_SkullAttack(MEMREF moRef, mobj_t* mobj);
void A_Metal(MEMREF moRef, mobj_t* mobj);
void A_SpidRefire(MEMREF moRef, mobj_t* mobj);
void A_BabyMetal(MEMREF moRef, mobj_t* mobj);
void A_BspiAttack(MEMREF moRef, mobj_t* mobj);
void A_Hoof(MEMREF moRef, mobj_t* mobj);
void A_CyberAttack(MEMREF moRef, mobj_t* mobj);
void A_PainAttack(MEMREF moRef, mobj_t* mobj);
void A_PainDie(MEMREF moRef, mobj_t* mobj);
void A_KeenDie(MEMREF moRef, mobj_t* mobj);
void A_BrainPain();
void A_BrainScream(MEMREF moRef, mobj_t* mobj);
void A_BrainDie();
void A_BrainAwake();
void A_BrainSpit(MEMREF moRef, mobj_t* mobj);
void A_SpawnSound(MEMREF moRef, mobj_t* mobj);
void A_SpawnFly(MEMREF moRef, mobj_t* mobj);
void A_BrainExplode(MEMREF moRef, mobj_t* mobj);

mobj_t* SAVEDUNIT;
mobj_t* setStateReturn;

//
// P_SetMobjState
// Returns true if the mobj is still present.
//

//
// P_ExplodeMissile  
//
void P_ExplodeMissile(MEMREF moRef, mobj_t* mo){

    mo->momx = mo->momy = mo->momz = 0;
    P_SetMobjState (moRef, getDeathState(mo->type), mo);
	mo = setStateReturn;

    mo->tics -= P_Random()&3;

	if (mo->tics < 1) {
		mo->tics = 1;
	}

    mo->flags &= ~MF_MISSILE;
	
	if (mo->info->deathsound) {
		S_StartSound(mo, mo->info->deathsound);
	}
}


//
// P_XYMovement  
//
#define STOPSPEED		0x1000
#define FRICTION		0xe800

void P_XYMovement (MEMREF moRef, mobj_t* mo)
{ 	
    fixed_t 	ptryx;
    fixed_t	ptryy;
    player_t*	player;
    fixed_t	xmove;
    fixed_t	ymove;
	fixed_t momomx;
	fixed_t momomy;
	int16_t ceilinglinebacksecnum;
	int16_t mosecnum;
	short_height_t sectorfloorheight;
	fixed_t_union temp;
	player = mo->player;
	temp.h.fracbits = 0;
	
	

	if (!mo->momx && !mo->momy) {

		if (mo->flags & MF_SKULLFLY) {
			// the skull slammed into something
			mo->flags &= ~MF_SKULLFLY;
			mo->momx = mo->momy = mo->momz = 0;

			P_SetMobjState (moRef, mo->info->spawnstate, mo);
		}
		return;
    }

	mosecnum = mo->secnum;


    if (mo->momx > MAXMOVE)
		mo->momx = MAXMOVE;
    else if (mo->momx < -MAXMOVE)
		mo->momx = -MAXMOVE;

    if (mo->momy > MAXMOVE)
		mo->momy = MAXMOVE;
    else if (mo->momy < -MAXMOVE)
		mo->momy = -MAXMOVE;
		
    xmove = mo->momx;
    ymove = mo->momy;

	
	do {

		if (xmove > MAXMOVE/2 || ymove > MAXMOVE/2) {
			ptryx = mo->x + xmove/2;
			ptryy = mo->y + ymove/2;
			xmove >>= 1;
			ymove >>= 1;
		} else {
			ptryx = mo->x + xmove;
			ptryy = mo->y + ymove;
			xmove = ymove = 0;
		}
		


		if (!P_TryMove (moRef, ptryx, ptryy, mo)) {

			mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);
			// blocked move
			if (player) {	// try to slide along it
				P_SlideMove ();
			} else if (mo->flags & MF_MISSILE) {
				// explode a missile
				ceilinglinebacksecnum=lines[ceilinglinenum].backsecnum;

				if (ceilinglinenum != SECNUM_NULL && ceilinglinebacksecnum != SECNUM_NULL && sectors[ceilinglinebacksecnum].ceilingpic == skyflatnum) {
					// Hack to prevent missiles exploding
					// against the sky.
					// Does not handle sky floors.
 
					P_RemoveMobj (moRef, (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef));
					return;
				}
			

				mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);
				P_ExplodeMissile (moRef, mo);
			} else {
				mo->momx = mo->momy = 0;
			}
		}
	

		mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);
	 
    } while (xmove || ymove);
	
	//mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);


    // slow down
    if (player && player->cheats & CF_NOMOMENTUM) {
		// debug option for no sliding at all
		mo->momx = mo->momy = 0;
 
		return;
    }

	if (mo->flags & (MF_MISSILE | MF_SKULLFLY)) {

	 
		return; 	// no friction for missiles ever
	}
	//temp.h.intbits = mo->floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);
	if (mo->z > temp.w) {

		return;		// no friction when airborne
	}
    
	if (mo->flags & MF_CORPSE) {
		// do not stop sliding
		//  if halfway off a step with some momentum
		sectorfloorheight = sectors[mosecnum].floorheight;
		mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);
		if (mo->momx > FRACUNIT/4 || mo->momx < -FRACUNIT/4 || mo->momy > FRACUNIT/4 || mo->momy < -FRACUNIT/4) {
			if (mo->floorz != sectorfloorheight) {
				
				return;
			}
		}
    }
	momomx = mo->momx;
	momomy = mo->momy;
	// mo and player can dereference each other here... let's not create a situation where both pointers are needed in the same if block
	

    if ((momomx > -STOPSPEED && momomx < STOPSPEED && momomy > -STOPSPEED && momomy < STOPSPEED) && 
			(!player || (player->cmd.forwardmove== 0 && player->cmd.sidemove == 0 ) ) 
		) {
	// if in a walking frame, stop moving
		if (player && (uint32_t)((playerMobj.state - states) - S_PLAY_RUN1) < 4) {
			P_SetMobjState(PLAYER_MOBJ_REF, S_PLAY, &playerMobj);
			mo = setStateReturn;
		}

		mo->momx = 0;
		mo->momy = 0;
    } else {

		mo->momx = FixedMul (momomx, FRICTION);
		mo->momy = FixedMul (momomy, FRICTION);
		 
	}

}

//
// P_ZMovement
//
void P_ZMovement (MEMREF moRef, mobj_t* mo)
{
    fixed_t	dist;
	fixed_t	delta;
	fixed_t	moTargetx;
	fixed_t	moTargety;
	fixed_t	moTargetz;
	mobj_t* moTarget;
	
	fixed_t_union temp;
	temp.h.fracbits = 0;
	// temp.h.intbits = mo->floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);
    // check for smooth step up
    if (mo->player && mo->z < temp.w) {
		mo->player->viewheight -= temp.w-mo->z;

		mo->player->deltaviewheight = (VIEWHEIGHT - mo->player->viewheight)>>3;
    }
    
    // adjust height
    mo->z += mo->momz;
	
    if ( mo->flags & MF_FLOAT && mo->targetRef) {
		// float down towards target if too close
		if ( !(mo->flags & MF_SKULLFLY) && !(mo->flags & MF_INFLOAT) ) {
			moTarget = (mobj_t*)Z_LoadThinkerBytesFromEMS(mo->targetRef);
			moTargetx = moTarget->x;
			moTargety = moTarget->y;
			moTargetz = moTarget->z;
			mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);
			dist = P_AproxDistance (mo->x - moTargetx,
						mo->y - moTargety);
	    
			delta =(moTargetz + (mo->height.w>>1)) - mo->z;

			if (delta<0 && dist < -(delta*3) )
				mo->z -= FLOATSPEED;
			else if (delta>0 && dist < (delta*3) )
				mo->z += FLOATSPEED;			
		}
	
    }
    
    // clip movement
    if (mo->z <= temp.w) {
		// hit the floor

	#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
		// Note (id):
		//  somebody left this after the setting momz to 0,
		//  kinda useless there.
		if (mo->flags & MF_SKULLFLY)
		{
			// the skull slammed into something
			mo->momz = -mo->momz;
		}
	#endif
	
		if (mo->momz < 0) {
			if (mo->player && mo->momz < -GRAVITY*8)	 {
				// Squat down.
				// Decrease viewheight for a moment
				// after hitting the ground (hard),
				// and utter appropriate sound.
				mo->player->deltaviewheight = mo->momz>>3;
				S_StartSound (mo, sfx_oof);
				mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);
			}
			mo->momz = 0;
		}



		mo->z = temp.w;

	#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
		if (mo->flags & MF_SKULLFLY) {
			// the skull slammed into something
			mo->momz = -mo->momz;
		}
	#endif

		if ( (mo->flags & MF_MISSILE) && !(mo->flags & MF_NOCLIP) ) {
			P_ExplodeMissile (moRef, mo);
			return;
		}
	} else if (! (mo->flags & MF_NOGRAVITY) ) {
		if (mo->momz == 0) {
			mo->momz = -GRAVITY * 2;
		} else {
			mo->momz -= GRAVITY;
		}
	}
	//mo = (mobj_t*)Z_LoadThinkerBytesFromEMS(moRef);
	//temp.h.intbits = mo->ceilingz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->ceilingz);
    if (mo->z + mo->height.w > temp.w) {
		// hit the ceiling
		if (mo->momz > 0) {
			mo->momz = 0;
		}
		mo->z = temp.w - mo->height.w;

		if (mo->flags & MF_SKULLFLY) {	// the skull slammed into something
			mo->momz = -mo->momz;
		}
	
		if ( (mo->flags & MF_MISSILE) && !(mo->flags & MF_NOCLIP) ) {
			P_ExplodeMissile (moRef, mo);
			return;
		}
    }



} 



//
// P_NightmareRespawn
//
void
P_NightmareRespawn(MEMREF mobjRef, mobj_t* mobj)
{
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;
	mobj_t*		mo;
	MEMREF moRef;
	int16_t subsecnum;
	int16_t subsectorsecnum;
	mobjtype_t mobjtype;
	fineangle_t mobjspawnangle;
	mapthing_t mobjspawnpoint;
	int16_t mobjspawnoptions;
	int16_t mobjsecnum;
	fixed_t mobjx;
	fixed_t mobjy;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	x.h.fracbits = 0;
	y.h.fracbits = 0;
	x.h.intbits = mobj->spawnpoint.x;
	y.h.intbits = mobj->spawnpoint.y;

	// somthing is occupying it's position?
	if (!P_CheckPosition(mobjRef, x.w, y.w, mobj)) {
		return;	// no respwan
	}
	mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
	mobjsecnum = mobj->secnum;
	mobjx = mobj->x;
	mobjy = mobj->y;

	// spawn a teleport fog at old spot
	// because of removal of the body?
	// temp.h.intbits = sectors[mobjsecnum].floorheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  sectors[mobjsecnum].floorheight);
	moRef = P_SpawnMobj(mobjx, mobjy, temp.w, MT_TFOG);
	// initiate teleport sound
	S_StartSoundFromRef(moRef, sfx_telept, setStateReturn);

	// spawn a teleport fog at the new spot
	subsecnum = R_PointInSubsector(x.w, y.w);
	subsectorsecnum = subsectors[subsecnum].secnum;
	moRef = P_SpawnMobj(x.w, y.w, temp.w, MT_TFOG);

	S_StartSoundFromRef(moRef, sfx_telept, setStateReturn);
	mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);

	// spawn the new monster

	// spawn it
	if (mobj->info->flags & MF_SPAWNCEILING){
		z.w = ONCEILINGZ;
	} else {
		z.w = ONFLOORZ;
	}

	mobjtype = mobj->type;
	mobjspawnpoint = mobj->spawnpoint;
	mobjspawnangle = mobj->spawnpoint.angle;
	mobjspawnoptions = mobj->spawnpoint.options;


    // inherit attributes from deceased one
    moRef = P_SpawnMobj (x.w,y.w,z.w, mobjtype);
	mo = setStateReturn;
	mo->spawnpoint = mobjspawnpoint;
    //todo does this work? or need to be in fixed_mul? -sq
	mo->angle = ANG45 * (mobjspawnangle/45);

	if (mobjspawnoptions & MTF_AMBUSH) {
		mo->flags |= MF_AMBUSH;
	}

    mo->reactiontime = 18;
	
    // remove the old monster,
    P_RemoveMobj (mobjRef, mo);
}

//
// P_MobjThinker
//
void P_MobjThinker (MEMREF mobjRef) {

	mobj_t* mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
	// momentum movement
    fixed_t_union temp;

	if (mobj->momx || mobj->momy || (mobj->flags&MF_SKULLFLY) ) {

		P_XYMovement (mobjRef, mobj);
		mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);

		if (thinkerlist[mobj->thinkerRef].functionType == TF_DELETEME) {
			return;		// mobj was removed
		}
    } 


	temp.h.fracbits = 0;
	// temp.h.intbits = mobj->floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->floorz);
    if ( (mobj->z != temp.w) || mobj->momz ) {
		P_ZMovement (mobjRef, mobj);
	 
		mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
		// FIXME: decent NOP/NULL/Nil function pointer please.
		if (thinkerlist[mobj->thinkerRef].functionType == TF_DELETEME) {
			return;		// mobj was removed
		}
    }


    // cycle through states,
    // calling action functions at transitions
    if (mobj->tics != -1) {
		mobj->tics--;
		
		// you can cycle through multiple states in a tic
		if (!mobj->tics) {

			if (!P_SetMobjState(mobjRef, mobj->state->nextstate, mobj)) {

				return;		// freed itself
			}

			

		}
	} else {

		// check for nightmare respawn
		if (!(mobj->flags & MF_COUNTKILL)) {
			return;
		}
		if (!respawnmonsters) {
			return;
		}
		mobj->movecount++;

		if (mobj->movecount < 12 * 35) {
			return;
		}
		if (leveltime.w & 31) {
			return;
		}

		if (P_Random() > 4) {
			return;
		}
		P_NightmareRespawn (mobjRef, mobj);
    }



}


//
// P_SpawnMobj
//
MEMREF
P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type ) {
    mobj_t*	mobj;
    state_t*	st;
    mobjinfo_t*	info;
	MEMREF mobjRef;
	int16_t mobjsecnum;
	short_height_t sectorfloorheight;
	short_height_t sectorceilingheight;
	fixed_t_union temp;
	temp.h.fracbits = 0;

	if (type == MT_PLAYER) {
		mobjRef = PLAYER_MOBJ_REF;
		playerSpawned = true;
	} else {
		mobjRef = Z_MallocThinkerEMS(sizeof(*mobj));
	}

	mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);

	memset (mobj, 0, sizeof (*mobj));


	info = &mobjinfo[type];

    mobj->type = type;
    mobj->info = info;
    mobj->x = x;
    mobj->y = y;
	mobj->radius = info->radius;// *FRACUNIT;
	mobj->height.h.intbits = info->height;// *FRACUNIT;
	mobj->height.h.fracbits = 0;
    mobj->flags = info->flags;
    mobj->health = getSpawnHealth(type);


	if (gameskill != sk_nightmare) {
		mobj->reactiontime = 8;
	}
    
    mobj->lastlook = P_Random () % 1;
	
    // do not set the state with P_SetMobjState,
    // because action routines can not be called yet
    st = &states[info->spawnstate];
	mobj->state = st;
    mobj->tics = st->tics;
    mobj->sprite = st->sprite;
    mobj->frame = st->frame;


    // set subsector and/or block links
    P_SetThingPosition (mobjRef, mobj);
 

	mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
	mobjsecnum = mobj->secnum;
	sectorfloorheight = sectors[mobjsecnum].floorheight;
	sectorceilingheight = sectors[mobjsecnum].ceilingheight;
	mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
	mobj->floorz = sectorfloorheight;
	mobj->ceilingz = sectorceilingheight;

    if (z == ONFLOORZ){
		// temp.h.intbits = mobj->floorz >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->floorz);
		mobj->z = temp.w;
	} else if (z == ONCEILINGZ){
		// temp.h.intbits = mobj->ceilingz >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->ceilingz);
		mobj->z = temp.w - mobj->info->height * FRACUNIT;
	}
    else 
		mobj->z = z;

	 

	mobj->thinkerRef = P_AddThinker(mobjRef, TF_MOBJTHINKER);
	setStateReturn = mobj;

    return mobjRef;
}


//
// P_RemoveMobj
//


void P_RemoveMobj (MEMREF mobjRef, mobj_t* mobj)
{
    // unlink from sector and block lists
    P_UnsetThingPosition (mobjRef, mobj);
    
    // stop any playing sound
    S_StopSound (mobjRef);
	mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
    // free block
    P_RemoveThinker (mobj->thinkerRef);
}



 



//
// GAME SPAWN FUNCTIONS
//


//
// P_SpawnPuff
//
extern fixed_t attackrange;

void
P_SpawnPuff
( fixed_t	x,
  fixed_t	y,
  fixed_t	z )
{
    mobj_t*	th;
	MEMREF thRef;
	
    z += ((P_Random()-P_Random())<<10);

    thRef = P_SpawnMobj (x,y,z, MT_PUFF);
	th = setStateReturn;
    th->momz = FRACUNIT;
    th->tics -= P_Random()&3;

    if (th->tics < 1)
		th->tics = 1;
	
    // don't make punches spark on the wall
    if (attackrange == MELEERANGE * FRACUNIT)
		P_SetMobjState (thRef, S_PUFF3, th);
}



//
// P_SpawnBlood
// 
void
P_SpawnBlood
( fixed_t	x,
  fixed_t	y,
  fixed_t	z,
  int16_t		damage )
{
    mobj_t*	th;
	MEMREF thRef;
	
    z += ((P_Random()-P_Random())<<10);
	thRef  = P_SpawnMobj (x,y,z, MT_BLOOD);
	th = setStateReturn;
    th->momz = FRACUNIT*2;
    th->tics -= P_Random()&3;

    if (th->tics < 1)
		th->tics = 1;
		
    if (damage <= 12 && damage >= 9)
		P_SetMobjState (thRef,S_BLOOD2, th);
    else if (damage < 9)
		P_SetMobjState (thRef,S_BLOOD3, th);
}



//
// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
//
void P_CheckMissileSpawn (MEMREF thRef, mobj_t* th)
{

    th->tics -= P_Random()&3;
	if (th->tics < 1) {
		th->tics = 1;
	}
    // move a little forward so an angle can
    // be computed if it immediately explodes
    th->x += (th->momx>>1);
    th->y += (th->momy>>1);
    th->z += (th->momz>>1);

	if (!P_TryMove(thRef, th->x, th->y, th)) {
		th = Z_LoadThinkerBytesFromEMS(thRef);
		P_ExplodeMissile(thRef, th);
	}
}


//
// P_SpawnMissile
//
MEMREF
P_SpawnMissile
( MEMREF	sourceRef,
  MEMREF	destRef,
  mobjtype_t	type,
	mobj_t* source)
{
    mobj_t*	th;
    angle_t	an;
    fixed_t	dist;
	mobj_t*	dest;
	fixed_t destz;
	fixed_t sourcex = source->x;
	fixed_t sourcey = source->y;
	fixed_t sourcez = source->z;
	fixed_t momz;
	int32_t thspeed;
	MEMREF thRef = P_SpawnMobj (sourcex, sourcey, sourcez + 4*8*FRACUNIT, type);
	fixed_t_union temp;

	th = setStateReturn;
	if (th->info->seesound) {
		S_StartSound(th, th->info->seesound);
		th = (mobj_t*)Z_LoadThinkerBytesFromEMS(thRef);

	}

    th->targetRef = sourceRef;	// where it came from
	thspeed = MAKESPEED(th->info->speed);

	dest = (mobj_t*)Z_LoadThinkerBytesFromEMS(destRef);
	destz = dest->z;
	an = R_PointToAngle2 (sourcex, sourcey, dest->x, dest->y);	

    // fuzzy player
	if (dest->flags & MF_SHADOW) {
		temp.h.fracbits = 0;
		temp.h.intbits = (P_Random() - P_Random());
		temp.h.intbits <<= 4;
		an += temp.w;
	}

	dist = P_AproxDistance(dest->x - sourcex, dest->y - sourcey);
	dist = dist / thspeed;
	momz = (destz - sourcez) / dist;

	if (dist < 1)
		dist = 1;


	th = (mobj_t*)Z_LoadThinkerBytesFromEMS(thRef);
    th->angle = an;
    an >>= ANGLETOFINESHIFT;
    th->momx = FixedMul (thspeed, finecosine(an));
    th->momy = FixedMul (thspeed, finesine(an));
	th->momz = momz;


	P_CheckMissileSpawn (thRef, th);
	
    return thRef;
}


//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
void
P_SpawnPlayerMissile
( 
  mobjtype_t	type )
{
    mobj_t*	th;
	MEMREF thRef;
    fineangle_t	an;
    
	fixed_t	x;
    fixed_t	y;
    fixed_t	z;
    fixed_t	slope;
	fixed_t speed;
	fixed_t_union temp;

    // see which target is to be aimed at
    // todo use fixed_t_union
	an = playerMobj.angle >> ANGLETOFINESHIFT;
	slope = P_AimLineAttack (PLAYER_MOBJ_REF, an, 16*64);
    
    if (!linetargetRef) {
		// todo use fixed_t_union
		an = MOD_FINE_ANGLE(an +(1<<(26- ANGLETOFINESHIFT)));
		slope = P_AimLineAttack (PLAYER_MOBJ_REF, an, 16*64);
		if (!linetargetRef) {
			// todo use fixed_t_union
			an = MOD_FINE_ANGLE(an - (2<<(26-ANGLETOFINESHIFT)));
			slope = P_AimLineAttack (PLAYER_MOBJ_REF, an, 16*64);
		}
		if (!linetargetRef) {
			// todo use fixed_t_union
			an = playerMobj.angle >> ANGLETOFINESHIFT;
			slope = 0;
		}
    }

	
    x = playerMobj.x;
    y = playerMobj.y;
    z = playerMobj.z + 4*8*FRACUNIT;
	
    thRef = P_SpawnMobj (x,y,z, type);
	th = setStateReturn;

    if (th->info->seesound)
	S_StartSound (th, th->info->seesound);

    th->targetRef = PLAYER_MOBJ_REF;
	temp.h.fracbits = 0;
	temp.h.intbits = an;
	temp.h.intbits <<= 3;
	th->angle = temp.w;

	speed = MAKESPEED(th->info->speed);

    th->momx = FixedMul( speed, finecosine(an));
    th->momy = FixedMul( speed, finesine(an));
    th->momz = FixedMul( speed, slope);

    P_CheckMissileSpawn (thRef, th);
}


boolean
P_SetMobjState2
(MEMREF mobjRef, statenum_t state, mobj_t* mobj)
//(MEMREF mobjRef, statenum_t state, int8_t* file, int32_t line)
{
	state_t*	st;
	
#if CHECK_FOR_ERRORS
	if (mobjRef > 10000 && mobjRef != PLAYER_MOBJ_REF) {
		I_Error("caught bad ref? %u %u %s %li", mobjRef, state, file, line);
	}
#endif

	setStateReturn = mobj;
	do {
		if (state == S_NULL) {
			mobj->state = (state_t *)S_NULL;
			P_RemoveMobj(mobjRef, mobj);
			mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
			setStateReturn = mobj;
			return false;
		}


		st = &states[state];
		mobj->state = st;
		mobj->tics = st->tics;
		mobj->sprite = st->sprite;
		mobj->frame = st->frame;


		// Modified handling.
		// Call action functions when the state is set



		switch (st->action) {

			case ETF_A_Explode: A_Explode(mobjRef, mobj); break;
			case ETF_A_Pain: A_Pain(mobjRef, mobj); break;
			case ETF_A_PlayerScream: A_PlayerScream(); break;
			case ETF_A_Fall: A_Fall(mobjRef, mobj); break;
			case ETF_A_XScream: A_XScream(mobjRef, mobj); break;
			case ETF_A_Look: A_Look(mobjRef, mobj); break;
			case ETF_A_Chase: A_Chase(mobjRef, mobj); break;
			case ETF_A_FaceTarget: A_FaceTarget(mobjRef, mobj); break;
			case ETF_A_PosAttack: A_PosAttack(mobjRef, mobj); break;
			case ETF_A_Scream: A_Scream(mobjRef, mobj); break;
			case ETF_A_SPosAttack: A_SPosAttack(mobjRef, mobj); break;
			case ETF_A_VileChase: A_VileChase(mobjRef, mobj); break;
			case ETF_A_VileStart: A_VileStart(mobjRef, mobj); break;
			case ETF_A_VileTarget: A_VileTarget(mobjRef, mobj); break;
			case ETF_A_VileAttack: A_VileAttack(mobjRef, mobj); break;
			case ETF_A_StartFire: A_StartFire(mobjRef, mobj); break;
			case ETF_A_Fire: A_Fire(mobjRef, mobj); break;
			case ETF_A_FireCrackle: A_FireCrackle(mobjRef, mobj); break;
			case ETF_A_Tracer: A_Tracer(mobjRef, mobj); break;
			case ETF_A_SkelWhoosh: A_SkelWhoosh(mobjRef, mobj); break;
			case ETF_A_SkelFist: A_SkelFist(mobjRef, mobj); break;
			case ETF_A_SkelMissile: A_SkelMissile(mobjRef, mobj); break;
			case ETF_A_FatRaise: A_FatRaise(mobjRef, mobj); break;
			case ETF_A_FatAttack1: A_FatAttack1(mobjRef, mobj); break;
			case ETF_A_FatAttack2: A_FatAttack2(mobjRef, mobj); break;
			case ETF_A_FatAttack3: A_FatAttack3(mobjRef, mobj); break;
			case ETF_A_BossDeath: A_BossDeath(mobjRef, mobj); break;
			case ETF_A_CPosAttack: A_CPosAttack(mobjRef, mobj); break;
			case ETF_A_CPosRefire: A_CPosRefire(mobjRef, mobj); break;
			case ETF_A_TroopAttack: A_TroopAttack(mobjRef, mobj); break;
			case ETF_A_SargAttack: A_SargAttack(mobjRef, mobj); break;
			case ETF_A_HeadAttack: A_HeadAttack(mobjRef, mobj); break;
			case ETF_A_BruisAttack: A_BruisAttack(mobjRef, mobj); break;
			case ETF_A_SkullAttack: A_SkullAttack(mobjRef, mobj); break;
			case ETF_A_Metal: A_Metal(mobjRef, mobj); break;
			case ETF_A_SpidRefire: A_SpidRefire(mobjRef, mobj); break;
			case ETF_A_BabyMetal: A_BabyMetal(mobjRef, mobj); break;
			case ETF_A_BspiAttack: A_BspiAttack(mobjRef, mobj); break;
			case ETF_A_Hoof: A_Hoof(mobjRef, mobj); break;
			case ETF_A_CyberAttack: A_CyberAttack(mobjRef, mobj); break;
			case ETF_A_PainAttack: A_PainAttack(mobjRef, mobj); break;
			case ETF_A_PainDie: A_PainDie(mobjRef, mobj); break;
			case ETF_A_KeenDie: A_KeenDie(mobjRef, mobj); break;
			case ETF_A_BrainPain: A_BrainPain(); break;
			case ETF_A_BrainScream: A_BrainScream(mobjRef, mobj); break;
			case ETF_A_BrainDie: A_BrainDie(); break;
				// ugly hacks because these values didnt fit in the char datatype, so we do this to avoid making that field a int16_t in a 1000 element struct array. 
				// easily saving extra 1-2kb of binary size is worth this hack imo - sq
			case ETF_A_BrainAwake:
				mobj->tics = 181;
				A_BrainAwake(); break;
			case ETF_A_BrainSpit: 
				mobj->tics = 150;
				A_BrainSpit(mobjRef, mobj); break;
			case ETF_A_SpawnSound: A_SpawnSound(mobjRef, mobj); break;
			case ETF_A_SpawnFly: A_SpawnFly(mobjRef, mobj); break;
			case ETF_A_BrainExplode: A_BrainExplode(mobjRef, mobj); break;
			//default:
		}



		mobj = (mobj_t*)Z_LoadThinkerBytesFromEMS(mobjRef);
		setStateReturn = mobj;


		state = st->nextstate;
	} while (!mobj->tics);


	return true;
}
