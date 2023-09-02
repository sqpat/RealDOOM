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


void A_Explode(mobj_t* mo);
void A_Pain(mobj_t* mo);
void A_PlayerScream(mobj_t* mo);
void A_Fall(mobj_t* mo);
void A_XScream(mobj_t* mo);
void A_Look(mobj_t* mo);
void A_Chase(mobj_t* mo);
void A_FaceTarget(mobj_t* mo);
void A_PosAttack(mobj_t* mo);
void A_Scream(mobj_t* mo);
void A_SPosAttack(mobj_t* mo);
void A_VileChase(mobj_t* mo);
void A_VileStart(mobj_t* mo);
void A_VileTarget(mobj_t* mo);
void A_VileAttack(mobj_t* mo);
void A_StartFire(mobj_t* mo);
void A_Fire(mobj_t* mo);
void A_FireCrackle(mobj_t* mo);
void A_Tracer(mobj_t* mo);
void A_SkelWhoosh(mobj_t* mo);
void A_SkelFist(mobj_t* mo);
void A_SkelMissile(mobj_t* mo);
void A_FatRaise(mobj_t* mo);
void A_FatAttack1(mobj_t* mo);
void A_FatAttack2(mobj_t* mo);
void A_FatAttack3(mobj_t* mo);
void A_BossDeath(mobj_t* mo);
void A_CPosAttack(mobj_t* mo);
void A_CPosRefire(mobj_t* mo);
void A_TroopAttack(mobj_t* mo);
void A_SargAttack(mobj_t* mo);
void A_HeadAttack(mobj_t* mo);
void A_BruisAttack(mobj_t* mo);
void A_SkullAttack(mobj_t* mo);
void A_Metal(mobj_t* mo);
void A_SpidRefire(mobj_t* mo);
void A_BabyMetal(mobj_t* mo);
void A_BspiAttack(mobj_t* mo);
void A_Hoof(mobj_t* mo);
void A_CyberAttack(mobj_t* mo);
void A_PainAttack(mobj_t* mo);
void A_PainDie(mobj_t* mo);
void A_KeenDie(mobj_t* mo);
void A_BrainPain(mobj_t* mo);
void A_BrainScream(mobj_t* mo);
void A_BrainDie(mobj_t* mo);
void A_BrainAwake(mobj_t* mo);
void A_BrainSpit(mobj_t* mo);
void A_SpawnSound(mobj_t* mo);
void A_SpawnFly(mobj_t* mo);
void A_BrainExplode(mobj_t* mo);

mobj_t* SAVEDUNIT;
//
// P_SetMobjState
// Returns true if the mobj is still present.
//

//
// P_ExplodeMissile  
//
void P_ExplodeMissile(mobj_t* mo){


    mo->momx = mo->momy = mo->momz = 0;
	
    P_SetMobjState (mo, mobjinfo[mo->type].deathstate);

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

// mobj is LOCKED page 0 going in
void P_XYMovement (mobj_t* mo)
{ 	
    fixed_t 	ptryx;
    fixed_t	ptryy;
    player_t*	player;
    fixed_t	xmove;
    fixed_t	ymove;
	//mobj_t* playermo;
	fixed_t momomx;
	fixed_t momomy;
	line_t* lines;
	int16_t ceilinglinebacksecnum;
	sector_t* sectors;
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

			P_SetMobjState (mo, mo->info->spawnstate);
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
			if (player) {	// try to slide along it
				P_SlideMove (mo);
			} else if (mo->flags & MF_MISSILE) {
				// explode a missile
				lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
				ceilinglinebacksecnum=lines[ceilinglinenum].backsecnum;
				sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

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
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
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
			(!player || (player->cmd.forwardmove== 0 && player->cmd.sidemove == 0 ) ) 
		) {
	// if in a walking frame, stop moving
		
		if (player && (uint32_t)((mo->state - states) - S_PLAY_RUN1) < 4) {
			P_SetMobjState(mo, S_PLAY);
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
// mobj is LOCKED page 0 going in
void P_ZMovement (mobj_t* mo)
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
			moTarget = (mobj_t*)Z_LoadBytesFromEMS(mo->targetRef);
			moTargetx = moTarget->x;
			moTargety = moTarget->y;
			moTargetz = moTarget->z;
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
			}
			mo->momz = 0;
		}

	// if (gametic == 758 && moRef == players.moRef){
	// 	I_Error ("the z value being set %i %i ", temp.w >>  (16-SHORTFLOORBITS), mo->z >>  (16-SHORTFLOORBITS));
	// }


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
	fixed_t		x;
	fixed_t		y;
	fixed_t		z;
	mapthing_t*		mthing;
	MEMREF moRef;
	int16_t subsecnum;
	subsector_t* subsectors;
	int16_t subsectorsecnum;
	mobjtype_t mobjtype;
	fineangle_t mobjspawnangle;
	mapthing_t mobjspawnpoint;
	int16_t mobjspawnoptions;
	fixed_t sectorfloorheight;
	int16_t mobjsecnum;
	fixed_t mobjx;
	fixed_t mobjy;
	sector_t* sectors;
	fixed_t_union temp;
	mobj_t* newmo;
	mobj_t* mo;
	temp.h.fracbits = 0;
	x = mobj->spawnpoint.x << FRACBITS;
	y = mobj->spawnpoint.y << FRACBITS;

	// somthing is occupying it's position?
	if (!P_CheckPosition(mobj, x, y)) {
		return;	// no respwan
	}
	mobjsecnum = mobj->secnum;
	mobjx = mobj->x;
	mobjy = mobj->y;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

	// spawn a teleport fog at old spot
	// because of removal of the body?
	// temp.h.intbits = sectors[mobjsecnum].floorheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  sectors[mobjsecnum].floorheight);
	moRef = P_SpawnMobj(mobjx, mobjy, temp.w, MT_TFOG);
	// initiate teleport sound
	S_StartSoundFromRef(moRef, sfx_telept);

	// spawn a teleport fog at the new spot
	subsecnum = R_PointInSubsector(x, y);
	subsectors = Z_LoadBytesFromEMS(subsectorsRef);
	subsectorsecnum = subsectors[subsecnum].secnum;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	moRef = P_SpawnMobj(x, y, temp.w, MT_TFOG);
	mo = (mobj_t*)Z_LoadBytesFromEMSWithOptions(moRef, PAGE_LOCKED);

	S_StartSound(mo, sfx_telept);
	Z_SetLocked(moRef, PAGE_NOT_LOCKED, 119);

	// spawn the new monster

	// spawn it
	if (mobj->info->flags & MF_SPAWNCEILING){
		z = ONCEILINGZ;
	} else {
		z = ONFLOORZ;
	}

	mobjtype = mobj->type;
	mobjspawnpoint = mobj->spawnpoint;
	mobjspawnangle = mobj->spawnpoint.angle;
	mobjspawnoptions = mobj->spawnpoint.options;


    // inherit attributes from deceased one
    moRef = P_SpawnMobj (x,y,z, mobjtype);
	newmo = (mobj_t*)Z_LoadBytesFromEMSWithOptions(moRef, PAGE_LOCKED);
	newmo->spawnpoint = mobjspawnpoint;
	newmo->angle = ANG45 * (mobjspawnangle/45);

	if (mobjspawnoptions & MTF_AMBUSH) {
		newmo->flags |= MF_AMBUSH;
	}

	newmo->reactiontime = 18;
	Z_SetLocked(moRef, PAGE_NOT_LOCKED, 114);

    // remove the old monster,
    P_RemoveMobj (mobj);


}


//
// P_MobjThinker
//
void P_MobjThinker (mobj_t* mobj) {

	// momentum movement
    fixed_t_union temp;
	if (mobj->momx || mobj->momy || (mobj->flags&MF_SKULLFLY) ) {

		P_XYMovement (mobj);
		//mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	 
		// FIXME: decent NOP/NULL/Nil function pointer please.
		if (thinkerlist[mobj->thinkerRef].functionType == TF_DELETEME) {
 			return;		// mobj was removed
		}
    } 

	temp.h.fracbits = 0;
	// temp.h.intbits = mobj->floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->floorz);
    if ( (mobj->z != temp.w) || mobj->momz ) {
		P_ZMovement (mobj);
	 
		//mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
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
			//mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

			if (!P_SetMobjState(mobj, mobj->state->nextstate)) {
 
				return;		// freed itself
			}
			//mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
			

		}
	} else {
		//mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

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
		if (leveltime & 31) {
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
MEMREF
P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type ) {
    mobj_t*	mobj;
    state_t*	st;
    mobjinfo_t*	info;
	MEMREF mobjRef;
	int16_t mobjsecnum;
	sector_t* sectors;
	short_height_t sectorfloorheight;
	short_height_t sectorceilingheight;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	mobjRef = Z_MallocEMSNew(sizeof(*mobj), PU_LEVEL, 0, ALLOC_TYPE_MOBJ);



	mobj = (mobj_t*)Z_LoadBytesFromEMSWithOptions(mobjRef, PAGE_LOCKED );

	memset (mobj, 0, sizeof (*mobj));


	info = &mobjinfo[type];
	mobj->selfRef = mobjRef;
    mobj->type = type;
    mobj->info = info;
    mobj->x = x;
    mobj->y = y;
	mobj->radius = info->radius;// *FRACUNIT;
	mobj->height.h.intbits = info->height;// *FRACUNIT;
	mobj->height.h.fracbits = 0;
    mobj->flags = info->flags;
    mobj->health = info->spawnhealth;


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
    P_SetThingPosition (mobj);
 

	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	mobjsecnum = mobj->secnum;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	sectorfloorheight = sectors[mobjsecnum].floorheight;
	sectorceilingheight = sectors[mobjsecnum].ceilingheight;
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
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
 

	Z_SetLocked(mobj->selfRef, PAGE_NOT_LOCKED, 201);

    return mobjRef;
}


//
// P_RemoveMobj
//

// Should be called with locked mobj
void P_RemoveMobj (mobj_t* mobj)
{
	
    // unlink from sector and block lists
    P_UnsetThingPosition (mobj);
    
    // stop any playing sound
    S_StopSound (mobj->selfRef);
    // free block
    P_RemoveThinker (mobj->thinkerRef);
}



 


//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//
void P_SpawnPlayer (mapthing_t* mthing)
{
     fixed_t		x;
    fixed_t		y;
    fixed_t		z;

	MEMREF mobjRef;
	mobj_t*		mobj;
	int16_t mthingtype = mthing->type;
	int16_t mthingx = mthing->x;
	int16_t mthingy = mthing->y;
	int16_t mthingangle = mthing->angle;
	 
		
 
	if (players.playerstate == PST_REBORN) {
		G_PlayerReborn();
	}

    x 		= mthingx << FRACBITS;
    y 		= mthingy << FRACBITS;
    z		= ONFLOORZ;
	mobjRef	= P_SpawnMobj (x,y,z, MT_PLAYER);
	mobj = (mobj_t*)Z_LoadBytesFromEMSWithOptions(mobjRef, PAGE_LOCKED);
	mobj->reactiontime = 0;

    // set color translations for player sprites
    if (mthingtype > 1)		
		mobj->flags |= (mthingtype-1)<<MF_TRANSSHIFT;
		
    mobj->angle	= ANG45 * (mthingangle/45);
    mobj->player = &players;
    mobj->health = players.health;

	players.moRef = mobjRef;
	players.playerstate = PST_LIVE;
	players.refire = 0;
	players.message = NULL;
	players.damagecount = 0;
	players.bonuscount = 0;
	players.extralight = 0;
	players.fixedcolormap = 0;
	players.viewheight = VIEWHEIGHT;


    // setup gun psprite
    P_SetupPsprites (&players);
    
 

    if (mthingtype-1 == consoleplayer) {
		// wake up the status bar
	 
		ST_Start ();
		 

		// wake up the heads up text
		HU_Start ();		
    }
	Z_SetLocked(mobjRef, PAGE_NOT_LOCKED, 113);

}


//
// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.
//
void P_SpawnMapThing (mapthing_t* mthing, int16_t key)
{
    int16_t			i;
    int16_t			bit;
    mobj_t*		mobj;
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
	MEMREF mobjRef;
	int16_t mthingtype = mthing->type;
	int16_t mthingoptions = mthing->options;
	int16_t mthingx = mthing->x;
	int16_t mthingy = mthing->y;
	int16_t mthingangle = mthing->angle;
	mapthing_t copyofthing = *mthing;



	if (mthing->type == 11 || mthing->type == 2 || mthing->type == 3 || mthing->type == 4) {
		return;
	}

    // check for players specially
    if (mthingtype == 1) {
		// save spots for respawning in network games
		P_SpawnPlayer(mthing);


		return;
    }


    // check for apropriate skill level
	if ((mthingoptions & 16)) {
		return;
	}
	if (gameskill == sk_baby) {
		bit = 1;
	} else if (gameskill == sk_nightmare) {
		bit = 4;
	} else {
		bit = 1 << (gameskill - 1);
	}
	if (!(mthingoptions & bit)) {
	 
		return;
	}


    // find which type to spawn
	for (i = 0; i < NUMMOBJTYPES; i++) {
		if (mthingtype == mobjinfo[i].doomednum) {
			break;
		}
	}


	if (i == NUMMOBJTYPES) {
		I_Error("P_SpawnMapThing: Unknown type %i at (%i, %i)",
			mthingtype,
			mthingx, mthingy);
	}


    // don't spawn any monsters if -nomonsters
    if (nomonsters && ( i == MT_SKULL || (mobjinfo[i].flags & MF_COUNTKILL)) ) {
		return;
    }
    
    // spawn it
    x = mthingx << FRACBITS;
    y = mthingy << FRACBITS;

	if (mobjinfo[i].flags & MF_SPAWNCEILING) {
		z = ONCEILINGZ;
	} else {
		z = ONFLOORZ;
	}
 
	// 55
	mobjRef = P_SpawnMobj (x,y,z, i);

	mobj = (mobj_t*)Z_LoadBytesFromEMSWithOptions(mobjRef, PAGE_LOCKED);
    mobj->spawnpoint = copyofthing;
	
    if (mobj->tics > 0)
		mobj->tics = 1 + (P_Random () % mobj->tics);
    if (mobj->flags & MF_COUNTKILL)
		totalkills++;
    if (mobj->flags & MF_COUNTITEM)
		totalitems++;
		
    mobj->angle = ANG45 * (mthingangle/45);
    
	if (mthingoptions & MTF_AMBUSH)
		mobj->flags |= MF_AMBUSH;

	Z_SetLocked(mobjRef, PAGE_NOT_LOCKED, 112);

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
	th = (mobj_t*)Z_LoadBytesFromEMSWithOptions(thRef, PAGE_LOCKED);
	th->momz = FRACUNIT;
    th->tics -= P_Random()&3;

    if (th->tics < 1)
		th->tics = 1;
	
    // don't make punches spark on the wall
    if (attackrange == MELEERANGE * FRACUNIT)
		P_SetMobjState (th, S_PUFF3);
	Z_SetLocked(thRef, PAGE_NOT_LOCKED, 111);

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
	th = (mobj_t*)Z_LoadBytesFromEMSWithOptions(thRef, PAGE_LOCKED);
	th->momz = FRACUNIT*2;
    th->tics -= P_Random()&3;

    if (th->tics < 1)
		th->tics = 1;
		
    if (damage <= 12 && damage >= 9)
		P_SetMobjState (th,S_BLOOD2);
    else if (damage < 9)
		P_SetMobjState (th,S_BLOOD3);

	Z_SetLocked(thRef, PAGE_NOT_LOCKED, 108);
}



//
// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
//
void P_CheckMissileSpawn (mobj_t* th)
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

	if (!P_TryMove(th, th->x, th->y)) {
		P_ExplodeMissile(th);
	}
}


//
// P_SpawnMissile
//
MEMREF
P_SpawnMissile
(mobj_t*	source,
  MEMREF	destRef,
  mobjtype_t	type )
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

	th = (mobj_t*)Z_LoadBytesFromEMSWithOptions(thRef, PAGE_LOCKED);
	if (th->info->seesound) {
		S_StartSound(th, th->info->seesound);

	}
	Z_RefIsActive(thRef);
    th->targetRef = source->selfRef;	// where it came from
	thspeed = MAKESPEED(th->info->speed);

	dest = (mobj_t*)Z_LoadBytesFromEMS(destRef);
	destz = dest->z;
	an = R_PointToAngle2 (sourcex, sourcey, dest->x, dest->y);	

    // fuzzy player
	if (dest->flags & MF_SHADOW) {
		an += (P_Random() - P_Random()) << 20;
	}

	dist = P_AproxDistance(dest->x - sourcex, dest->y - sourcey);
	dist = dist / thspeed;
	momz = (destz - sourcez) / dist;

	if (dist < 1)
		dist = 1;


     th->angle = an;
    an >>= ANGLETOFINESHIFT;
    th->momx = FixedMul (thspeed, finecosine(an));
    th->momy = FixedMul (thspeed, finesine(an));
	th->momz = momz;


	P_CheckMissileSpawn (th);
	Z_SetLocked(thRef, PAGE_NOT_LOCKED, 75);
    return thRef;
}


//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
void
P_SpawnPlayerMissile
( mobj_t* source,
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
    

    // see which target is to be aimed at
    an = source->angle >> ANGLETOFINESHIFT;
    slope = P_AimLineAttack (source, an, 16*64*FRACUNIT);
    
    if (!linetargetRef) {
		an = MOD_FINE_ANGLE(an +(1<<(26- ANGLETOFINESHIFT)));
		slope = P_AimLineAttack (source, an, 16*64*FRACUNIT);

		if (!linetargetRef) {
			an = MOD_FINE_ANGLE(an - (2<<(26-ANGLETOFINESHIFT)));
			slope = P_AimLineAttack (source, an, 16*64*FRACUNIT);
		}
		if (!linetargetRef) {
			an = source->angle >> ANGLETOFINESHIFT;
			slope = 0;
		}
    }
    x = source->x;
    y = source->y;
    z = source->z + 4*8*FRACUNIT;
	
    thRef = P_SpawnMobj (x,y,z, type);
	th = (mobj_t*)Z_LoadBytesFromEMSWithOptions(thRef, PAGE_LOCKED);

    if (th->info->seesound)
	S_StartSound (th, th->info->seesound);

    th->targetRef = source->selfRef;
    th->angle = an << ANGLETOFINESHIFT;
	//an = an >> ANGLETOFINESHIFT;

	speed = MAKESPEED(th->info->speed);

    th->momx = FixedMul( speed, finecosine(an));
    th->momy = FixedMul( speed, finesine(an));
    th->momz = FixedMul( speed, slope);

    P_CheckMissileSpawn (th);

	Z_SetLocked(thRef, PAGE_NOT_LOCKED, 107);
}



boolean
P_SetMobjState
// mobj locked (?) to page 0 coming in

(mobj_t*	mobj,
	statenum_t	state)
{
	state_t*	st;
	int16_t i = 0;

	do {
		if (state == S_NULL) {
			mobj->state = (state_t *)S_NULL;
			P_RemoveMobj(mobj);
			//Z_SetLocked(mobj, PAGE_NOT_LOCKED, 41);
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

			case ETF_A_Explode: A_Explode(mobj); break;
			case ETF_A_Pain: A_Pain(mobj); break;
			case ETF_A_PlayerScream: A_PlayerScream(mobj); break;
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
			case ETF_A_BrainPain: A_BrainPain(mobj); break;
			case ETF_A_BrainScream: A_BrainScream(mobj); break;
			case ETF_A_BrainDie: A_BrainDie(mobj); break;
				// ugly hacks because these values didnt fit in the char datatype, so we do this to avoid making that field a int16_t in a 1000 element struct array. 
				// easily saving extra 1-2kb of binary size is worth this hack imo - sq
			case ETF_A_BrainAwake:
				mobj->tics = 181;
				A_BrainAwake(mobj); break;
			case ETF_A_BrainSpit: 
				mobj->tics = 150;
				A_BrainSpit(mobj); break;
			case ETF_A_SpawnSound: A_SpawnSound(mobj); break;
			case ETF_A_SpawnFly: A_SpawnFly(mobj); break;
			case ETF_A_BrainExplode: A_BrainExplode(mobj); break;
			//default:
		}





		state = st->nextstate;
		i++;
	} while (!mobj->tics);

	//Z_SetLocked(mobj->selfRef, PAGE_NOT_LOCKED, 42);

	return true;
}
