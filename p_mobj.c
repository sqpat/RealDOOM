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



void G_PlayerReborn ();
void P_SpawnMapThing (mapthing_t*	mthing, int16_t key);


void A_Explode(mobj_t* mobjmoRef);
void A_Pain(mobj_t* mobj);
void A_PlayerScream();
void A_Fall(mobj_t* mobj);
void A_XScream(mobj_t* mobj);
void A_Look(mobj_t* mobj);
void A_Chase(mobj_t* mobj);
void A_FaceTarget(mobj_t* mobj);
void A_PosAttack(mobj_t* mobj);
void A_Scream(mobj_t* mobj);
void A_SPosAttack(mobj_t* mobj);
void A_VileChase(mobj_t* mobj);
void A_VileStart(mobj_t* mobj);
void A_VileTarget(mobj_t* mobj);
void A_VileAttack(mobj_t* mobj);
void A_StartFire(mobj_t* mobj);
void A_Fire(mobj_t* mobj);
void A_FireCrackle(mobj_t* mobj);
void A_Tracer(mobj_t* mobj);
void A_SkelWhoosh(mobj_t* mobj);
void A_SkelFist(mobj_t* mobj);
void A_SkelMissile(mobj_t* mobj);
void A_FatRaise(mobj_t* mobj);
void A_FatAttack1(mobj_t* mobj);
void A_FatAttack2(mobj_t* mobj);
void A_FatAttack3(mobj_t* mobj);
void A_BossDeath(mobj_t* mobj);
void A_CPosAttack(mobj_t* mobj);
void A_CPosRefire(mobj_t* mobj);
void A_TroopAttack(mobj_t* mobj);
void A_SargAttack(mobj_t* mobj);
void A_HeadAttack(mobj_t* mobj);
void A_BruisAttack(mobj_t* mobj);
void A_SkullAttack(mobj_t* mobj);
void A_Metal(mobj_t* mobj);
void A_SpidRefire(mobj_t* mobj);
void A_BabyMetal(mobj_t* mobj);
void A_BspiAttack(mobj_t* mobj);
void A_Hoof(mobj_t* mobj);
void A_CyberAttack(mobj_t* mobj);
void A_PainAttack(mobj_t* mobj);
void A_PainDie(mobj_t* mobj);
void A_KeenDie(mobj_t* mobj);
void A_BrainPain();
void A_BrainScream(mobj_t* mobj);
void A_BrainDie();
void A_BrainAwake();
void A_BrainSpit(mobj_t* mobj);
void A_SpawnSound(mobj_t* mobj);
void A_SpawnFly(mobj_t* mobj);
void A_BrainExplode(mobj_t* mobj);

mobj_t* SAVEDUNIT;
mobj_t* setStateReturn;

//
// P_SetMobjState
// Returns true if the mobj is still present.
//

//
// P_ExplodeMissile  
//
void P_ExplodeMissile(mobj_t* mo){

    mo->momx = mo->momy = mo->momz = 0;
    P_SetMobjState (mo,getDeathState(mo->type));
	//mo = setStateReturn;

    mo->tics -= P_Random()&3;

	if (mo->tics < 1 || mo->tics > 240) {
		mo->tics = 1;
	}

    mo->flags &= ~MF_MISSILE;
	
	if (mobjinfo[mo->type].deathsound) {
		S_StartSound(mo, mobjinfo[mo->type].deathsound);
	}
}


//
// P_XYMovement  
//
#define STOPSPEED		0x1000
#define FRICTION		0xe800

void P_XYMovement (mobj_t* mo)
{ 	
    fixed_t 	ptryx;
    fixed_t	ptryy;
	int16_t motype = mo->type;
    fixed_t	xmove;
    fixed_t	ymove;
	fixed_t momomx;
	fixed_t momomy;
	int16_t ceilinglinebacksecnum;
	int16_t mosecnum;
	short_height_t sectorfloorheight;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	
	

	if (!mo->momx && !mo->momy) {

		if (mo->flags & MF_SKULLFLY) {
			// the skull slammed into something
			mo->flags &= ~MF_SKULLFLY;
			mo->momx = mo->momy = mo->momz = 0;

			P_SetMobjState (mo,mobjinfo[mo->type].spawnstate);
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
		


		if (!P_TryMove (mo, ptryx, ptryy)) {

			// blocked move
			if (motype == MT_PLAYER) {	// try to slide along it
				P_SlideMove ();
			} else if (mo->flags & MF_MISSILE) {
				// explode a missile
				ceilinglinebacksecnum=lines[ceilinglinenum].backsecnum;

				if (ceilinglinenum != SECNUM_NULL && ceilinglinebacksecnum != SECNUM_NULL && sectors[ceilinglinebacksecnum].ceilingpic == skyflatnum) {
					// Hack to prevent missiles exploding
					// against the sky.
					// Does not handle sky floors.
 
					P_RemoveMobj (mo);
					return;
				}
			

				P_ExplodeMissile (mo);
			} else {
				mo->momx = mo->momy = 0;
			}
		}
	

	 
    } while (xmove || ymove);
	

    // slow down
    if (motype == MT_PLAYER && player.cheats & CF_NOMOMENTUM) {
		// debug option for no sliding at all
		mo->momx = mo->momy = 0;
 
		return;
    }

	if (mo->flags & (MF_MISSILE | MF_SKULLFLY)) {

	 
		return; 	// no friction for missiles ever
	}
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);
	if (mo->z > temp.w) {

		return;		// no friction when airborne
	}
    
	if (mo->flags & MF_CORPSE) {
		// do not stop sliding
		//  if halfway off a step with some momentum
		sectorfloorheight = sectors[mosecnum].floorheight;
		if (mo->momx > FRACUNIT/4 || mo->momx < -FRACUNIT/4 || mo->momy > FRACUNIT/4 || mo->momy < -FRACUNIT/4) {
			if (mo->floorz != sectorfloorheight) {
				
				return;
			}
		}
    }
	momomx = mo->momx;
	momomy = mo->momy;


    if ((momomx > -STOPSPEED && momomx < STOPSPEED && momomy > -STOPSPEED && momomy < STOPSPEED) && 
			(motype != MT_PLAYER || (player.cmd.forwardmove== 0 && player.cmd.sidemove == 0 ) )
		) {
	// if in a walking frame, stop moving
		if (motype == MT_PLAYER && (uint32_t)((playerMobj->stateNum) - S_PLAY_RUN1) < 4) {
			P_SetMobjState(playerMobj,S_PLAY);
			//mo = setStateReturn;
		}

		mo->momx = 0;
		mo->momy = 0;
    } else {

		mo->momx = FixedMul16u32 (FRICTION, momomx );
		mo->momy = FixedMul16u32 (FRICTION, momomy);
		 
	}

}

//
// P_ZMovement
//
void P_ZMovement (mobj_t* mo)
{
    fixed_t	dist;
	fixed_t	delta;
	mobj_t* moTarget;
	
	fixed_t_union temp;
	int16_t motype = mo->type;
	temp.h.fracbits = 0;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);
    // check for smooth step up
    if (motype == MT_PLAYER && mo->z < temp.w) {
		player.viewheight -= temp.w-mo->z;

		player.deltaviewheight = (VIEWHEIGHT - player.viewheight)>>3;
    }
    
    // adjust height
    mo->z += mo->momz;
	
    if ( mo->flags & MF_FLOAT && mo->targetRef) {
		// float down towards target if too close
		if ( !(mo->flags & MF_SKULLFLY) && !(mo->flags & MF_INFLOAT) ) {
			moTarget = (mobj_t*)&thinkerlist[mo->targetRef].data;
			dist = P_AproxDistance (mo->x - moTarget->x,
						mo->y - moTarget->y);
	    
			delta =(moTarget->z + (mo->height.w>>1)) - mo->z;

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
			if (motype == MT_PLAYER && mo->momz < -GRAVITY*8)	 {
				// Squat down.
				// Decrease viewheight for a moment
				// after hitting the ground (hard),
				// and utter appropriate sound.
				player.deltaviewheight = mo->momz>>3;
				S_StartSound (mo, sfx_oof);
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
			P_ExplodeMissile (mo);
			return;
		}
	} else if (! (mo->flags & MF_NOGRAVITY) ) {
		if (mo->momz == 0) {
			mo->momz = -GRAVITY * 2;
		} else {
			mo->momz -= GRAVITY;
		}
	}
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
			P_ExplodeMissile (mo);
			return;
		}
    }



} 



//
// P_NightmareRespawn
//
void
P_NightmareRespawn(mobj_t* mobj)
{

	
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;
	mobj_t*		mo;
	THINKERREF moRef;
	int16_t subsecnum;
	int16_t subsectorsecnum;
	mobjtype_t mobjtype;
	fineangle_t mobjspawnangle;
	int16_t mobjspawnoptions;
	int16_t mobjsecnum;
	fixed_t mobjx;
	fixed_t mobjy;
	fixed_t_union temp;
	mapthing_t mobjspawnpoint;
	THINKERREF mobjRef = GETTHINKERREF(mobjRef);

	temp.h.fracbits = 0;
	x.h.fracbits = 0;
	y.h.fracbits = 0;
	
	
	x.h.intbits = mobjspawnpoint.x;
	y.h.intbits = mobjspawnpoint.y;
	

	// somthing is occupying it's position?
	if (!P_CheckPosition(mobj, x.w, y.w, -1)) {
		return;	// no respwan
	}
	mobjsecnum = mobj->secnum;
	mobjx = mobj->x;
	mobjy = mobj->y;

	// spawn a teleport fog at old spot
	// because of removal of the body?
	// temp.h.intbits = sectors[mobjsecnum].floorheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  sectors[mobjsecnum].floorheight);
	moRef = P_SpawnMobj(mobjx, mobjy, temp.w, MT_TFOG, mobjsecnum);
	// initiate teleport sound
	S_StartSoundFromRef(setStateReturn, sfx_telept);

	// spawn a teleport fog at the new spot
	subsecnum = R_PointInSubsector(x.w, y.w);
	subsectorsecnum = subsectors[subsecnum].secnum;
	moRef = P_SpawnMobj(x.w, y.w, temp.w, MT_TFOG, subsectorsecnum);

	S_StartSoundFromRef(setStateReturn, sfx_telept);

	// spawn the new monster

	mobjtype = mobj->type;

	// spawn it
	if (mobjinfo[mobjtype].flags & MF_SPAWNCEILING){
		z.w = ONCEILINGZ;
	} else {
		z.w = ONFLOORZ;
	}

	mobjspawnpoint = ((mapthing_t*)(Z_LoadBytesFromEMS(nightmareSpawnPointsRef)))[mobjRef];
	mobjspawnangle = mobjspawnpoint.angle;
	mobjspawnoptions = mobjspawnpoint.options;

	// todo probably fix this, its fudging the indices, i think we want to force it to reuse the same one to maintain nightmare spawn point ref 

    // inherit attributes from deceased one
    moRef = P_SpawnMobj (x.w,y.w,z.w, mobjtype, -1);
	mo = setStateReturn;
	//mo->spawnpoint = mobjspawnpoint;
    //todo does this work? or need to be in fixed_mul? -sq
	mo->angle.w = ANG45 * (mobjspawnangle/45);

	if (mobjspawnoptions & MTF_AMBUSH) {
		mo->flags |= MF_AMBUSH;
	}

    mo->reactiontime = 18;
	
    // remove the old monster,
    P_RemoveMobj (mo);

}

//
// P_MobjThinker
//
void P_MobjThinker (mobj_t* mobj, THINKERREF mobjRef) {

	// momentum movement
    fixed_t_union temp;

	if (mobj->momx || mobj->momy || (mobj->flags&MF_SKULLFLY) ) {

		P_XYMovement (mobj);

		if ((thinkerlist[mobjRef].prevFunctype & TF_FUNCBITS) == TF_DELETEME_HIGHBITS) {
			return;		// mobj was removed
		}
    } 


	temp.h.fracbits = 0;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->floorz);
		if ( (mobj->z != temp.w) || mobj->momz ) {
		P_ZMovement (mobj);

 		// FIXME: decent NOP/NULL/Nil function pointer please.
		if ((thinkerlist[mobjRef].prevFunctype & TF_FUNCBITS) == TF_DELETEME_HIGHBITS) {
			return;		// mobj was removed
		}
    }
 

    // cycle through states,
    // calling action functions at transitions
    if (mobj->tics != 255) {
		mobj->tics--;
		
		// you can cycle through multiple states in a tic
		if (!mobj->tics) {

			if (!P_SetMobjState(mobj, states[mobj->stateNum].nextstate)) {

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
		P_NightmareRespawn (mobj);
    }



}


//
// P_SpawnMobj
//
THINKERREF
P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type, int16_t knownsecnum ) {
    mobj_t*	mobj;
    state_t*	st;
    mobjinfo_t*	info;
	THINKERREF mobjRef;
	int16_t mobjsecnum;
	fixed_t_union temp;
	temp.h.fracbits = 0;

	mobj = (mobj_t*)P_CreateThinker(TF_MOBJTHINKER_HIGHBITS);
	mobjRef = GETTHINKERREF(mobj);

	memset (mobj, 0, sizeof (*mobj));


	info = &mobjinfo[type];

    mobj->type = type;
    //mobj->info = info;
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
    
    //mobj->lastlook = P_Random () % 1;
	P_Random();

    // do not set the state with P_SetMobjState,
    // because action routines can not be called yet
    st = &states[info->spawnstate];
	mobj->stateNum = info->spawnstate;
    mobj->tics = st->tics;
    //mobj->sprite = st->sprite;
    //mobj->frame = st->frame;


    // set subsector and/or block links
    P_SetThingPosition (mobj, knownsecnum);
 

	mobjsecnum = mobj->secnum;
	mobj->floorz = sectors[mobjsecnum].floorheight;
	mobj->ceilingz = sectors[mobjsecnum].ceilingheight;

    if (z == ONFLOORZ){
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->floorz);
		mobj->z = temp.w;
	} else if (z == ONCEILINGZ){
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->ceilingz);
		mobj->z = temp.w - mobjinfo[mobj->type].height * FRACUNIT;
	}
    else 
		mobj->z = z;

	 

	setStateReturn = mobj;

    return mobjRef;
}


//
// P_RemoveMobj
//


void P_RemoveMobj (mobj_t* mobj)
{
    // unlink from sector and block lists
    P_UnsetThingPosition (mobj);
    
    // stop any playing sound
    S_StopSound (mobj);

	// free block
	P_RemoveThinker(GETTHINKERREF(mobj));
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
	THINKERREF thRef;
	
    z += ((P_Random()-P_Random())<<10);

    thRef = P_SpawnMobj (x,y,z, MT_PUFF, -1);
	th = setStateReturn;
    th->momz = FRACUNIT;
    th->tics -= P_Random()&3;

    if (th->tics < 1 || th->tics > 240)
		th->tics = 1;
	
    // don't make punches spark on the wall
    if (attackrange == MELEERANGE * FRACUNIT)
		P_SetMobjState (th, S_PUFF3);
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
	THINKERREF thRef;
	
    z += ((P_Random()-P_Random())<<10);
	thRef  = P_SpawnMobj (x,y,z, MT_BLOOD, -1);
	th = setStateReturn;
    th->momz = FRACUNIT*2;
    th->tics -= P_Random()&3;

    if (th->tics < 1 || th->tics > 240)
		th->tics = 1;
		
    if (damage <= 12 && damage >= 9)
		P_SetMobjState (th,S_BLOOD2);
    else if (damage < 9)
		P_SetMobjState (th,S_BLOOD3);
}



//
// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
//
void P_CheckMissileSpawn (mobj_t* th)
{

    th->tics -= P_Random()&3;
	if (th->tics < 1 || th->tics > 240) {
		th->tics = 1;
	}
    // move a little forward so an angle can
    // be computed if it immediately explodes
    th->x += (th->momx>>1);
    th->y += (th->momy>>1);
    th->z += (th->momz>>1);

	if (!P_TryMove(th, th->x, th->y)) {

		P_ExplodeMissile(th);
	}
}


//
// P_SpawnMissile
//
THINKERREF
P_SpawnMissile
(mobj_t* source,
  mobj_t*	dest,
  mobjtype_t	type
	)
{
    mobj_t*	th;
    angle_t	an;
    fixed_t	dist;
	fixed_t destz;
	fixed_t momz;
	int32_t thspeed;
	THINKERREF thRef = P_SpawnMobj (source->x, source->y, source->z + 4*8*FRACUNIT, type, source->secnum);
	uint16_t temp;

	th = setStateReturn;
	if (mobjinfo[type].seesound) {
		S_StartSound(th, mobjinfo[type].seesound);


	}

    th->targetRef = GETTHINKERREF(source);	// where it came from
	thspeed = MAKESPEED(mobjinfo[type].speed);

	destz = dest->z;
	an.w = R_PointToAngle2 (source->x, source->y, dest->x, dest->y);

    // fuzzy player
	if (dest->flags & MF_SHADOW) {
		temp = (P_Random() - P_Random());
		temp  <<= 4;
		an.h.intbits += temp;
	}

	dist = P_AproxDistance(dest->x - source->x, dest->y - source->y);
	dist = dist / thspeed;
	momz = (destz - source->z) / dist;

	if (dist < 1)
		dist = 1;


    th->angle = an;
    an.h.intbits >>= SHORTTOFINESHIFT;
    th->momx = FixedMulTrig (thspeed, finecosine(an.h.intbits));
    th->momy = FixedMulTrig(thspeed, finesine(an.h.intbits));
	th->momz = momz;


	P_CheckMissileSpawn (th);
	
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
	THINKERREF thRef;
    fineangle_t	an;
    
    fixed_t_union	z;
    fixed_t	slope;
	fixed_t speed;

    // see which target is to be aimed at
    // todo use fixed_t_union
	an = playerMobj->angle.h.intbits >> SHORTTOFINESHIFT;
	slope = P_AimLineAttack (playerMobj, an, 16*64);
    
    if (!linetarget) {
		// todo use fixed_t_union
		an = MOD_FINE_ANGLE(an +(1<<(26- ANGLETOFINESHIFT)));
		slope = P_AimLineAttack (playerMobj, an, 16*64);
		if (!linetarget) {
			// todo use fixed_t_union
			an = MOD_FINE_ANGLE(an - (2<<(26-ANGLETOFINESHIFT)));
			slope = P_AimLineAttack (playerMobj, an, 16*64);
		}
		if (!linetarget) {
			an = playerMobj->angle.h.intbits >> SHORTTOFINESHIFT;
			slope = 0;
		}
    }

	
	z.w = playerMobj->z;
	z.h.intbits += 4 * 8;
	
    thRef = P_SpawnMobj (playerMobj->x, playerMobj->y,z.w, type, playerMobj->secnum);
	th = setStateReturn;

    if (mobjinfo[type].seesound)
		S_StartSound (th, mobjinfo[type].seesound);

    th->targetRef = playerMobjRef;
	th->angle.h.intbits = an;
	th->angle.h.intbits <<= 3;
	th->angle.h.fracbits = 0;

	speed = MAKESPEED(mobjinfo[type].speed);

    th->momx = FixedMulTrig( speed, finecosine(an));
    th->momy = FixedMulTrig( speed, finesine(an));
    th->momz = FixedMul( speed, slope);

    P_CheckMissileSpawn (th);
}


boolean
P_SetMobjState2
(mobj_t* mobj, statenum_t state)
//(THINKERREF mobjRef, statenum_t state, int8_t* file, int32_t line)
{
	state_t*	st;
	
#ifdef CHECK_FOR_ERRORS
//	if (mobjRef > 10000 && mobjRef != playerMobjRef) {
//		I_Error("caught bad ref? %u %u %s %li", mobjRef, state, file, line);
//	}
#endif

	setStateReturn = mobj;
	do {
		if (state == S_NULL) {
			mobj->stateNum = S_NULL;
			P_RemoveMobj(mobj);
			setStateReturn = mobj;
			return false;
		}


		st = &states[state];
		mobj->stateNum = state;
		mobj->tics = st->tics;

		//mobj->sprite = st->sprite;
		//mobj->frame = st->frame;


		// Modified handling.
		// Call action functions when the state is set



		switch (st->action) {

			case ETF_A_Explode: A_Explode(mobj); break;
			case ETF_A_Pain: A_Pain(mobj); break;
			case ETF_A_PlayerScream: A_PlayerScream(); break;
			case ETF_A_Fall: A_Fall(mobj); break;
			case ETF_A_XScream: A_XScream(mobj); break;
			case ETF_A_Look: A_Look(mobj); break;
			case ETF_A_Chase: A_Chase(mobj); break;
			case ETF_A_FaceTarget: A_FaceTarget(mobj); break;
			case ETF_A_PosAttack: A_PosAttack(mobj); break;
			case ETF_A_Scream: A_Scream(mobj); break;
			case ETF_A_SPosAttack: A_SPosAttack(mobj); break;
			case ETF_A_VileChase: A_VileChase(mobj); break;
			case ETF_A_VileStart: A_VileStart(mobj); break;
			case ETF_A_VileTarget: A_VileTarget(mobj); break;
			case ETF_A_VileAttack: A_VileAttack(mobj); break;
			case ETF_A_StartFire: A_StartFire(mobj); break;
			case ETF_A_Fire: A_Fire(mobj); break;
			case ETF_A_FireCrackle: A_FireCrackle(mobj); break;
			case ETF_A_Tracer: A_Tracer(mobj); break;
			case ETF_A_SkelWhoosh: A_SkelWhoosh(mobj); break;
			case ETF_A_SkelFist: A_SkelFist(mobj); break;
			case ETF_A_SkelMissile: A_SkelMissile(mobj); break;
			case ETF_A_FatRaise: A_FatRaise(mobj); break;
			case ETF_A_FatAttack1: A_FatAttack1(mobj); break;
			case ETF_A_FatAttack2: A_FatAttack2(mobj); break;
			case ETF_A_FatAttack3: A_FatAttack3(mobj); break;
			case ETF_A_BossDeath: A_BossDeath(mobj); break;
			case ETF_A_CPosAttack: A_CPosAttack(mobj); break;
			case ETF_A_CPosRefire: A_CPosRefire(mobj); break;
			case ETF_A_TroopAttack: A_TroopAttack(mobj); break;
			case ETF_A_SargAttack: A_SargAttack(mobj); break;
			case ETF_A_HeadAttack: A_HeadAttack(mobj); break;
			case ETF_A_BruisAttack: A_BruisAttack(mobj); break;
			case ETF_A_SkullAttack: A_SkullAttack(mobj); break;
			case ETF_A_Metal: A_Metal(mobj); break;
			case ETF_A_SpidRefire: A_SpidRefire(mobj); break;
			case ETF_A_BabyMetal: A_BabyMetal(mobj); break;
			case ETF_A_BspiAttack: A_BspiAttack(mobj); break;
			case ETF_A_Hoof: A_Hoof(mobj); break;
			case ETF_A_CyberAttack: A_CyberAttack(mobj); break;
			case ETF_A_PainAttack: A_PainAttack(mobj); break;
			case ETF_A_PainDie: A_PainDie(mobj); break;
			case ETF_A_KeenDie: A_KeenDie(mobj); break;
			case ETF_A_BrainPain: A_BrainPain(); break;
			case ETF_A_BrainScream: A_BrainScream(mobj); break;
			case ETF_A_BrainDie: A_BrainDie(); break;
				// ugly hacks because these values didnt fit in the char datatype, so we do this to avoid making that field a int16_t in a 1000 element struct array. 
				// easily saving extra 1-2kb of binary size is worth this hack imo - sq
			case ETF_A_BrainAwake:
				mobj->tics = 181;
				A_BrainAwake(); break;
			case ETF_A_BrainSpit: 
				mobj->tics = 150;
				A_BrainSpit(mobj); break;
			case ETF_A_SpawnSound: A_SpawnSound(mobj); break;
			case ETF_A_SpawnFly: A_SpawnFly(mobj); break;
			case ETF_A_BrainExplode: A_BrainExplode(mobj); break;
			//default:
		}



		setStateReturn = mobj;


		state = st->nextstate;
	} while (!mobj->tics);


	return true;
}
