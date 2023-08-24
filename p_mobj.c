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
void P_SpawnMapThing (mapthing_t*	mthing, int key);


void A_Explode(MEMREF moRef);
void A_Pain(MEMREF moRef);
void A_PlayerScream(MEMREF moRef);
void A_Fall(MEMREF moRef);
void A_XScream(MEMREF moRef);
void A_Look(MEMREF moRef);
void A_Chase(MEMREF moRef);
void A_FaceTarget(MEMREF moRef);
void A_PosAttack(MEMREF moRef);
void A_Scream(MEMREF moRef);
void A_SPosAttack(MEMREF moRef);
void A_VileChase(MEMREF moRef);
void A_VileStart(MEMREF moRef);
void A_VileTarget(MEMREF moRef);
void A_VileAttack(MEMREF moRef);
void A_StartFire(MEMREF moRef);
void A_Fire(MEMREF moRef);
void A_FireCrackle(MEMREF moRef);
void A_Tracer(MEMREF moRef);
void A_SkelWhoosh(MEMREF moRef);
void A_SkelFist(MEMREF moRef);
void A_SkelMissile(MEMREF moRef);
void A_FatRaise(MEMREF moRef);
void A_FatAttack1(MEMREF moRef);
void A_FatAttack2(MEMREF moRef);
void A_FatAttack3(MEMREF moRef);
void A_BossDeath(MEMREF moRef);
void A_CPosAttack(MEMREF moRef);
void A_CPosRefire(MEMREF moRef);
void A_TroopAttack(MEMREF moRef);
void A_SargAttack(MEMREF moRef);
void A_HeadAttack(MEMREF moRef);
void A_BruisAttack(MEMREF moRef);
void A_SkullAttack(MEMREF moRef);
void A_Metal(MEMREF moRef);
void A_SpidRefire(MEMREF moRef);
void A_BabyMetal(MEMREF moRef);
void A_BspiAttack(MEMREF moRef);
void A_Hoof(MEMREF moRef);
void A_CyberAttack(MEMREF moRef);
void A_PainAttack(MEMREF moRef);
void A_PainDie(MEMREF moRef);
void A_KeenDie(MEMREF moRef);
void A_BrainPain(MEMREF moRef);
void A_BrainScream(MEMREF moRef);
void A_BrainDie(MEMREF moRef);
void A_BrainAwake(MEMREF moRef);
void A_BrainSpit(MEMREF moRef);
void A_SpawnSound(MEMREF moRef);
void A_SpawnFly(MEMREF moRef);
void A_BrainExplode(MEMREF moRef);

mobj_t* SAVEDUNIT;
//
// P_SetMobjState
// Returns true if the mobj is still present.
//
static int test = 0;



//
// P_ExplodeMissile  
//
void P_ExplodeMissile(MEMREF moRef){


	mobj_t* mo = (mobj_t*) Z_LoadBytesFromEMS(moRef);
    mo->momx = mo->momy = mo->momz = 0;
	
    P_SetMobjState (moRef, mobjinfo[mo->type].deathstate);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);

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

void P_XYMovement (MEMREF moRef) 
{ 	
    fixed_t 	ptryx;
    fixed_t	ptryy;
    player_t*	player;
    fixed_t	xmove;
    fixed_t	ymove;
	mobj_t* playermo;
	fixed_t momomx;
	fixed_t momomy;
	line_t* lines;
	short ceilinglinebacksecnum;
	sector_t* sectors;
	short mosecnum;
	fixed_t sectorfloorheight;

	int i = 0;
	mobj_t* mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	player = mo->player;
	
	

	if (!mo->momx && !mo->momy) {

		if (mo->flags & MF_SKULLFLY) {
			// the skull slammed into something
			mo->flags &= ~MF_SKULLFLY;
			mo->momx = mo->momy = mo->momz = 0;

			P_SetMobjState (moRef, mo->info->spawnstate);
		}
		return;
    }

	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
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
		i++;

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
		


		if (!P_TryMove (moRef, ptryx, ptryy)) {

			mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
			// blocked move
			if (player) {	// try to slide along it
				P_SlideMove (moRef);
			} else if (mo->flags & MF_MISSILE) {
				// explode a missile
				lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
				ceilinglinebacksecnum=lines[ceilinglinenum].backsecnum;
				sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

				if (ceilinglinenum != SECNUM_NULL && ceilinglinebacksecnum != SECNUM_NULL && sectors[ceilinglinebacksecnum].ceilingpic == skyflatnum) {
					// Hack to prevent missiles exploding
					// against the sky.
					// Does not handle sky floors.
 
					P_RemoveMobj (moRef);
					return;
				}
			

				P_ExplodeMissile (moRef);
			} else {
				mo->momx = mo->momy = 0;
			}
		}


		mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	 
    } while (xmove || ymove);

	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);


    // slow down
    if (player && player->cheats & CF_NOMOMENTUM) {
		// debug option for no sliding at all
		mo->momx = mo->momy = 0;
 
		return;
    }

	if (mo->flags & (MF_MISSILE | MF_SKULLFLY)) {

	 
		return; 	// no friction for missiles ever
	}

	if (mo->z > mo->floorz) {

		return;		// no friction when airborne
	}
    
	if (mo->flags & MF_CORPSE) {
		// do not stop sliding
		//  if halfway off a step with some momentum
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		sectorfloorheight = sectors[mosecnum].floorheight;
		mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
		if (mo->momx > FRACUNIT/4 || mo->momx < -FRACUNIT/4 || mo->momy > FRACUNIT/4 || mo->momy < -FRACUNIT/4) {
			if (mo->floorz != sectorfloorheight) {
				
				return;
			}
		}
    }
	momomx = mo->momx;
	momomy = mo->momy;
	// mo and player can dereference each other here... let's not create a situation where both pointers are needed in the same if block
	if (player) {
		playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);

	}


    if ((momomx > -STOPSPEED && momomx < STOPSPEED && momomy > -STOPSPEED && momomy < STOPSPEED) && 
			(!player || (player->cmd.forwardmove== 0 && player->cmd.sidemove == 0 ) ) 
		) {
	// if in a walking frame, stop moving
		if (player) {
			playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);
		}
		if (player && (unsigned)((playermo->state - states) - S_PLAY_RUN1) < 4) {
			P_SetMobjState(player->moRef, S_PLAY);
		}
		mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);

		mo->momx = 0;
		mo->momy = 0;
    } else {
		mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);


		mo->momx = FixedMul (momomx, FRICTION);
		mo->momy = FixedMul (momomy, FRICTION);

	}

}

//
// P_ZMovement
//
void P_ZMovement (MEMREF moRef)
{
    fixed_t	dist;
	fixed_t	delta;
	fixed_t	moTargetx;
	fixed_t	moTargety;
	fixed_t	moTargetz;
	mobj_t* moTarget;
	mobj_t* mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
 
    // check for smooth step up
    if (mo->player && mo->z < mo->floorz) {
		mo->player->viewheight -= mo->floorz-mo->z;

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
			mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
			dist = P_AproxDistance (mo->x - moTargetx,
						mo->y - moTargety);
	    
			delta =(moTargetz + (mo->height>>1)) - mo->z;

			if (delta<0 && dist < -(delta*3) )
			mo->z -= FLOATSPEED;
			else if (delta>0 && dist < (delta*3) )
			mo->z += FLOATSPEED;			
		}
	
    }
    
    // clip movement
    if (mo->z <= mo->floorz) {
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
			mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
			mo->momz = 0;
		}
		mo->z = mo->floorz;

	#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
		if (mo->flags & MF_SKULLFLY) {
			// the skull slammed into something
			mo->momz = -mo->momz;
		}
	#endif

		if ( (mo->flags & MF_MISSILE) && !(mo->flags & MF_NOCLIP) ) {
			P_ExplodeMissile (moRef);
			return;
		}
	} else if (! (mo->flags & MF_NOGRAVITY) ) {
		if (mo->momz == 0) {
			mo->momz = -GRAVITY * 2;
		} else {
			mo->momz -= GRAVITY;
		}
	}
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    if (mo->z + mo->height > mo->ceilingz) {
		// hit the ceiling
		if (mo->momz > 0) {
			mo->momz = 0;
		}
		mo->z = mo->ceilingz - mo->height;

		if (mo->flags & MF_SKULLFLY) {	// the skull slammed into something
			mo->momz = -mo->momz;
		}
	
		if ( (mo->flags & MF_MISSILE) && !(mo->flags & MF_NOCLIP) ) {
			P_ExplodeMissile (moRef);
			return;
		}
    }



} 



//
// P_NightmareRespawn
//
void
P_NightmareRespawn(MEMREF mobjRef)
{
	fixed_t		x;
	fixed_t		y;
	fixed_t		z;
	mobj_t*		mo;
	mapthing_t*		mthing;
	MEMREF moRef;
	mobj_t* mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	short subsecnum;
	subsector_t* subsectors;
	short subsectorsecnum;
	mobjtype_t mobjtype;
	angle_t mobjspawnangle;
	mapthing_t mobjspawnpoint;
	short mobjspawnoptions;
	fixed_t sectorfloorheight;
	short mobjsecnum;
	fixed_t mobjx;
	fixed_t mobjy;
	sector_t* sectors;

	x = mobj->spawnpoint.x << FRACBITS;
	y = mobj->spawnpoint.y << FRACBITS;

	// somthing is occupying it's position?
	if (!P_CheckPosition(mobjRef, x, y)) {
		return;	// no respwan
	}
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	mobjsecnum = mobj->secnum;
	mobjx = mobj->x;
	mobjy = mobj->y;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

	// spawn a teleport fog at old spot
	// because of removal of the body?
	moRef = P_SpawnMobj(mobjx, mobjy, sectors[mobjsecnum].floorheight, MT_TFOG);
	// initiate teleport sound
	S_StartSoundFromRef(moRef, sfx_telept);

	// spawn a teleport fog at the new spot
	subsecnum = R_PointInSubsector(x, y);
	subsectors = Z_LoadBytesFromEMS(subsectorsRef);
	subsectorsecnum = subsectors[subsecnum].secnum;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	moRef = P_SpawnMobj(x, y, sectors[subsectorsecnum].floorheight, MT_TFOG);

	S_StartSoundFromRef(moRef, sfx_telept);
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

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
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	mo->spawnpoint = mobjspawnpoint;
    mo->angle = ANG45 * (mobjspawnangle/45);

	if (mobjspawnoptions & MTF_AMBUSH) {
		mo->flags |= MF_AMBUSH;
	}

    mo->reactiontime = 18;
	
    // remove the old monster,
    P_RemoveMobj (mobjRef);
}


//
// P_MobjThinker
//
void P_MobjThinker (MEMREF mobjRef) {

	mobj_t* mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	int i;
	// momentum movement
    if (mobj->momx || mobj->momy || (mobj->flags&MF_SKULLFLY) ) {

		P_XYMovement (mobjRef);
		mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	 
		// FIXME: decent NOP/NULL/Nil function pointer please.
		if (thinkerlist[mobj->thinkerRef].functionType == TF_DELETEME) {
			return;		// mobj was removed
		}
    } 

    if ( (mobj->z != mobj->floorz) || mobj->momz ) {
		P_ZMovement (mobjRef);
	 
		mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
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
			mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

			if (!P_SetMobjState(mobjRef, mobj->state->nextstate)) {

				return;		// freed itself
			}
			mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
			

		}
	} else {
		mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

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
		P_NightmareRespawn (mobjRef);
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
	short mobjsecnum;
	sector_t* sectors;
	fixed_t sectorfloorheight;
	fixed_t sectorceilingheight;

	mobjRef = Z_MallocEMSNew(sizeof(*mobj), PU_LEVEL, 0, ALLOC_TYPE_LEVSPEC);
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

	memset (mobj, 0, sizeof (*mobj));


	info = &mobjinfo[type];
	
    mobj->type = type;
    mobj->info = info;
    mobj->x = x;
    mobj->y = y;
    mobj->radius = info->radius;
    mobj->height = info->height;
    mobj->flags = info->flags;
    mobj->health = info->spawnhealth;


	if (gameskill != sk_nightmare) {
		mobj->reactiontime = 8;
	}
    
    mobj->lastlook = P_Random () % MAXPLAYERS;
    // do not set the state with P_SetMobjState,
    // because action routines can not be called yet
    st = &states[info->spawnstate];
	mobj->state = st;
    mobj->tics = st->tics;
    mobj->sprite = st->sprite;
    mobj->frame = st->frame;


    // set subsector and/or block links
    P_SetThingPosition (mobjRef);
 

	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	mobjsecnum = mobj->secnum;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	sectorfloorheight = sectors[mobjsecnum].floorheight;
	sectorceilingheight = sectors[mobjsecnum].ceilingheight;
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	mobj->floorz = sectorfloorheight;
	mobj->ceilingz = sectorceilingheight;

    if (z == ONFLOORZ)
		mobj->z = mobj->floorz;
    else if (z == ONCEILINGZ)
		mobj->z = mobj->ceilingz - mobj->info->height;
    else 
		mobj->z = z;

	 

	mobj->thinkerRef = P_AddThinker(mobjRef, TF_MOBJTHINKER);
 

    return mobjRef;
}


//
// P_RemoveMobj
//
mapthing_t	itemrespawnque[ITEMQUESIZE];
int		itemrespawntime[ITEMQUESIZE];
int		iquehead;
int		iquetail;


void P_RemoveMobj (MEMREF mobjRef)
{
	mobj_t* mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
    if ((mobj->flags & MF_SPECIAL) && !(mobj->flags & MF_DROPPED) && (mobj->type != MT_INV) && (mobj->type != MT_INS)) {
		itemrespawnque[iquehead] = mobj->spawnpoint;
		itemrespawntime[iquehead] = leveltime;
		iquehead = (iquehead+1)&(ITEMQUESIZE-1);

		// lose one off the end?
		if (iquehead == iquetail) {
			iquetail = (iquetail + 1)&(ITEMQUESIZE - 1);
		}
    }
	
    // unlink from sector and block lists
    P_UnsetThingPosition (mobjRef);
    
    // stop any playing sound
    S_StopSound (mobjRef);
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
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
    player_t*		p;
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;

	MEMREF mobjRef;
	mobj_t*		mobj;
	short mthingtype = mthing->type;
	short mthingx = mthing->x;
	short mthingy = mthing->y;
	short mthingangle = mthing->angle;
	 
		
    p = &players[0];

	if (p->playerstate == PST_REBORN) {
		G_PlayerReborn();
	}

    x 		= mthingx << FRACBITS;
    y 		= mthingy << FRACBITS;
    z		= ONFLOORZ;
    mobjRef	= P_SpawnMobj (x,y,z, MT_PLAYER);
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	mobj->reactiontime = 0;

    // set color translations for player sprites
    if (mthingtype > 1)		
		mobj->flags |= (mthingtype-1)<<MF_TRANSSHIFT;
		
    mobj->angle	= ANG45 * (mthingangle/45);
    mobj->player = p;
    mobj->health = p->health;

    p->moRef = mobjRef;
    p->playerstate = PST_LIVE;	
    p->refire = 0;
    p->message = NULL;
    p->damagecount = 0;
    p->bonuscount = 0;
    p->extralight = 0;
    p->fixedcolormap = 0;
    p->viewheight = VIEWHEIGHT;
	 

    // setup gun psprite
    P_SetupPsprites (p);
    
 

    if (mthingtype-1 == consoleplayer) {
		// wake up the status bar
	 
		ST_Start ();
		 

		// wake up the heads up text
		HU_Start ();		
    }
 
}


//
// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.
//
void P_SpawnMapThing (mapthing_t* mthing, int key)
{
    int			i;
    int			bit;
    mobj_t*		mobj;
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
	MEMREF mobjRef;
	short mthingtype = mthing->type;
	short mthingoptions = mthing->options;
	short mthingx = mthing->x;
	short mthingy = mthing->y;
	short mthingangle = mthing->angle;
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

	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
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
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);
    th->momz = FRACUNIT;
    th->tics -= P_Random()&3;

    if (th->tics < 1)
		th->tics = 1;
	
    // don't make punches spark on the wall
    if (attackrange == MELEERANGE)
		P_SetMobjState (thRef, S_PUFF3);
}



//
// P_SpawnBlood
// 
void
P_SpawnBlood
( fixed_t	x,
  fixed_t	y,
  fixed_t	z,
  int		damage )
{
    mobj_t*	th;
	MEMREF thRef;
	
    z += ((P_Random()-P_Random())<<10);
	thRef  = P_SpawnMobj (x,y,z, MT_BLOOD);
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);
    th->momz = FRACUNIT*2;
    th->tics -= P_Random()&3;

    if (th->tics < 1)
		th->tics = 1;
		
    if (damage <= 12 && damage >= 9)
		P_SetMobjState (thRef,S_BLOOD2);
    else if (damage < 9)
		P_SetMobjState (thRef,S_BLOOD3);
}



//
// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
//
void P_CheckMissileSpawn (MEMREF thRef)
{
	mobj_t* th = (mobj_t*)Z_LoadBytesFromEMS(thRef);

    th->tics -= P_Random()&3;
	if (th->tics < 1) {
		th->tics = 1;
	}
    // move a little forward so an angle can
    // be computed if it immediately explodes
    th->x += (th->momx>>1);
    th->y += (th->momy>>1);
    th->z += (th->momz>>1);
	Z_RefIsActive(thRef);

	if (!P_TryMove(thRef, th->x, th->y)) {
		P_ExplodeMissile(thRef);
	}
}


//
// P_SpawnMissile
//
MEMREF
P_SpawnMissile
( MEMREF	sourceRef,
  MEMREF	destRef,
  mobjtype_t	type )
{
    mobj_t*	th;
    angle_t	an;
    int		dist;
	mobj_t*	source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
	mobj_t*	dest;
	fixed_t destz;
	fixed_t sourcex = source->x;
	fixed_t sourcey = source->y;
	fixed_t sourcez = source->z;
	fixed_t momz;
	int thspeed;
	MEMREF thRef = P_SpawnMobj (sourcex, sourcey, sourcez + 4*8*FRACUNIT, type);

	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);
	if (th->info->seesound) {
		S_StartSound(th, th->info->seesound);
		th = (mobj_t*)Z_LoadBytesFromEMS(thRef);

	}
	Z_RefIsActive(thRef);
    th->targetRef = sourceRef;	// where it came from
	thspeed = th->info->speed;

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


	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);
    th->angle = an;
    an >>= ANGLETOFINESHIFT;
    th->momx = FixedMul (th->info->speed, finecosine[an]);
    th->momy = FixedMul (th->info->speed, finesine[an]);
	th->momz = momz;
	Z_RefIsActive(thRef);


	P_CheckMissileSpawn (thRef);
	
    return thRef;
}


//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
void
P_SpawnPlayerMissile
( MEMREF	sourceRef,
  mobjtype_t	type )
{
    mobj_t*	th;
	MEMREF thRef;
    angle_t	an;
    
    fixed_t	x;
    fixed_t	y;
    fixed_t	z;
    fixed_t	slope;
	mobj_t* source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
    

    // see which target is to be aimed at
    an = source->angle;
    slope = P_AimLineAttack (sourceRef, an, 16*64*FRACUNIT);
    
    if (!linetargetRef) {
		an += 1<<26;
		slope = P_AimLineAttack (sourceRef, an, 16*64*FRACUNIT);

		if (!linetargetRef) {
			an -= 2<<26;
			slope = P_AimLineAttack (sourceRef, an, 16*64*FRACUNIT);
		}
		source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
		if (!linetargetRef) {
			an = source->angle;
			slope = 0;
		}
    }
	source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
    x = source->x;
    y = source->y;
    z = source->z + 4*8*FRACUNIT;
	
    thRef = P_SpawnMobj (x,y,z, type);
	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);

    if (th->info->seesound)
	S_StartSound (th, th->info->seesound);

    th->targetRef = sourceRef;
    th->angle = an;
    th->momx = FixedMul( th->info->speed,
			 finecosine[an>>ANGLETOFINESHIFT]);
    th->momy = FixedMul( th->info->speed,
			 finesine[an>>ANGLETOFINESHIFT]);
    th->momz = FixedMul( th->info->speed, slope);

    P_CheckMissileSpawn (thRef);
}



boolean
P_SetMobjState
(MEMREF mobjRef,
	statenum_t	state)
{
	state_t*	st;
	mobj_t*	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
	int i = 0;

	do {
		if (state == S_NULL) {
			mobj->state = (state_t *)S_NULL;
			P_RemoveMobj(mobjRef);
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

			case ETF_A_Explode: A_Explode(mobjRef); break;
			case ETF_A_Pain: A_Pain(mobjRef); break;
			case ETF_A_PlayerScream: A_PlayerScream(mobjRef); break;
			case ETF_A_Fall: A_Fall(mobjRef); break;
			case ETF_A_XScream: A_XScream(mobjRef); break;
			case ETF_A_Look: A_Look(mobjRef); break;
			case ETF_A_Chase: A_Chase(mobjRef); break;
			case ETF_A_FaceTarget: A_FaceTarget(mobjRef); break;
			case ETF_A_PosAttack: A_PosAttack(mobjRef); break;
			case ETF_A_Scream: A_Scream(mobjRef); break;
			case ETF_A_SPosAttack: A_SPosAttack(mobjRef); break;
			case ETF_A_VileChase: A_VileChase(mobjRef); break;
			case ETF_A_VileStart: A_VileStart(mobjRef); break;
			case ETF_A_VileTarget: A_VileTarget(mobjRef); break;
			case ETF_A_VileAttack: A_VileAttack(mobjRef); break;
			case ETF_A_StartFire: A_StartFire(mobjRef); break;
			case ETF_A_Fire: A_Fire(mobjRef); break;
			case ETF_A_FireCrackle: A_FireCrackle(mobjRef); break;
			case ETF_A_Tracer: A_Tracer(mobjRef); break;
			case ETF_A_SkelWhoosh: A_SkelWhoosh(mobjRef); break;
			case ETF_A_SkelFist: A_SkelFist(mobjRef); break;
			case ETF_A_SkelMissile: A_SkelMissile(mobjRef); break;
			case ETF_A_FatRaise: A_FatRaise(mobjRef); break;
			case ETF_A_FatAttack1: A_FatAttack1(mobjRef); break;
			case ETF_A_FatAttack2: A_FatAttack2(mobjRef); break;
			case ETF_A_FatAttack3: A_FatAttack3(mobjRef); break;
			case ETF_A_BossDeath: A_BossDeath(mobjRef); break;
			case ETF_A_CPosAttack: A_CPosAttack(mobjRef); break;
			case ETF_A_CPosRefire: A_CPosRefire(mobjRef); break;
			case ETF_A_TroopAttack: A_TroopAttack(mobjRef); break;
			case ETF_A_SargAttack: A_SargAttack(mobjRef); break;
			case ETF_A_HeadAttack: A_HeadAttack(mobjRef); break;
			case ETF_A_BruisAttack: A_BruisAttack(mobjRef); break;
			case ETF_A_SkullAttack: A_SkullAttack(mobjRef); break;
			case ETF_A_Metal: A_Metal(mobjRef); break;
			case ETF_A_SpidRefire: A_SpidRefire(mobjRef); break;
			case ETF_A_BabyMetal: A_BabyMetal(mobjRef); break;
			case ETF_A_BspiAttack: A_BspiAttack(mobjRef); break;
			case ETF_A_Hoof: A_Hoof(mobjRef); break;
			case ETF_A_CyberAttack: A_CyberAttack(mobjRef); break;
			case ETF_A_PainAttack: A_PainAttack(mobjRef); break;
			case ETF_A_PainDie: A_PainDie(mobjRef); break;
			case ETF_A_KeenDie: A_KeenDie(mobjRef); break;
			case ETF_A_BrainPain: A_BrainPain(mobjRef); break;
			case ETF_A_BrainScream: A_BrainScream(mobjRef); break;
			case ETF_A_BrainDie: A_BrainDie(mobjRef); break;
				// ugly hacks because these values didnt fit in the char datatype, so we do this to avoid making that field a short in a 1000 element struct array. 
				// easily saving extra 1-2kb of binary size is worth this hack imo
			case ETF_A_BrainAwake:
				mobj->tics = 181;
				A_BrainAwake(mobjRef); break;
			case ETF_A_BrainSpit: 
				mobj->tics = 150;
				A_BrainSpit(mobjRef); break;
			case ETF_A_SpawnSound: A_SpawnSound(mobjRef); break;
			case ETF_A_SpawnFly: A_SpawnFly(mobjRef); break;
			case ETF_A_BrainExplode: A_BrainExplode(mobjRef); break;
			//default:
		}



		mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);


		state = st->nextstate;
		i++;
	} while (!mobj->tics);


	return true;
}
