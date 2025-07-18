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

#include <dos.h>
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

#include "m_memory.h"
#include "m_near.h"


void __far G_PlayerReborn ();


void __near A_Explode(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Pain(			mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_PlayerScream( mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Fall(			mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_XScream(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Look(			mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Chase(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_FaceTarget(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_PosAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Scream(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SPosAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_VileChase(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_VileStart(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_VileTarget(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_VileAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_StartFire(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Fire(			mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_FireCrackle(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Tracer(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SkelWhoosh(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SkelFist(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SkelMissile(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_FatRaise(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_FatAttack1(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_FatAttack2(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_FatAttack3(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BossDeath(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_CPosAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_CPosRefire(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_TroopAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SargAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_HeadAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BruisAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SkullAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Metal(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SpidRefire(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BabyMetal(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BspiAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_Hoof(			mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_CyberAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_PainAttack(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_PainDie(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_KeenDie(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BrainPain(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BrainScream(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BrainAwake(   mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BrainSpit(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SpawnSound(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_SpawnFly(		mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void __near A_BrainExplode(	mobj_t __near* mobj, mobj_pos_t __far* mobj_pos);
void G_ExitLevel();

#ifdef DEBUGLOG_TO_FILE
mobj_t __near* SAVEDUNIT;
#endif

//
// P_SetMobjState
// Returns true if the mobj is still present.
//


// Which one is deterministic?
/*
uint8_t __near P_Random(void) {
	 
    prndindex++;
    return rndtable[prndindex];
}
*/


//
// P_SetupPsprites
// Called at start of level for each player.
//
/*
void __near P_SetupPsprites() {
	int8_t	i;

	// remove all psprites
	psprites[0].statenum = STATENUM_NULL;
	psprites[1].statenum = STATENUM_NULL;

	// spawn the gun
	player.pendingweapon = player.readyweapon;
	P_BringUpWeaponFar();
}
*/
void __far ST_Start(void);

//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//

// todo move ot p_setup perhaps?
/*
void __near P_SpawnPlayer(mapthing_t __far* mthing) {
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;

	//int16_t mthingtype = mthing->type;
	int16_t mthingx = mthing->x;
	int16_t mthingy = mthing->y;
	int16_t mthingangle = mthing->angle;

	if (player.playerstate == PST_REBORN) {
		G_PlayerReborn();
	}
	x.h.fracbits = 0;
	y.h.fracbits = 0;
	x.h.intbits = mthingx;
	y.h.intbits = mthingy;
	z.w = ONFLOORZ;
	
	playerMobjRef = P_SpawnMobj(x.w, y.w, z.w, MT_PLAYER, -1);
	playerMobj     = playerMobjMakerExpression;
    playerMobj_pos = playerMobj_posMakerExpression;

	//playerMobj = setStateReturn;
	///playerMobj_pos = setStateReturn_pos;


	playerMobj->reactiontime = 0;

	playerMobj_pos->angle.wu = FastMul1632u((mthingangle / 45), ANG45);
	playerMobj->health = player.health;


	player.playerstate = PST_LIVE;
	player.refire = 0;
	player.message = -1;
	player.damagecount = 0;
	player.bonuscount = 0;
	player.extralightvalue = 0;
	player.fixedcolormapvalue = 0;
	player.viewheightvalue.w = VIEWHEIGHT;

	// setup gun psprite
	P_SetupPsprites();

	Z_QuickMapStatus();

	// wake up the status bar
	ST_Start();

	// wake up the heads up text
	HU_Start();

	Z_QuickMapPhysics();
	Z_QuickMapScratch_8000(); // gross, due to p_setup.... perhaps externalize.
	Z_QuickMapPhysicsCode();
} */

//
// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.
//

// todo move ot p_setup perhaps?

/*
void __far P_SpawnMapThing(mapthing_t mthing, int16_t key) {



	int16_t			i;
	int16_t			bit;
	mobj_t __near*		mobj;
	mobj_pos_t __far* mobj_pos;
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;
	THINKERREF mobjRef;
	int16_t mthingtype = mthing.type;
	int16_t mthingoptions = mthing.options;
	int16_t mthingx = mthing.x;
	int16_t mthingy = mthing.y;
	int16_t mthingangle = mthing.angle;

	if (mthing.type == 11 || mthing.type == 2 || mthing.type == 3 || mthing.type == 4) {
		return;
	}

	// check for players specially
	if (mthingtype == 1) {
		// save spots for respawning in network games
		P_SpawnPlayer(&mthing);
		return;
	}

	// check for apropriate skill level
	if ((mthingoptions & 16)) {
		return;
	}
	if (gameskill == sk_baby) {
		bit = 1;
	}
	else if (gameskill == sk_nightmare) {
		bit = 4;
	}
	else {
		bit = 1 << (gameskill - 1);
	}
	if (!(mthingoptions & bit)) {

		return;
	}


	// find which type to spawn
	for (i = 0; i < NUMMOBJTYPES; i++) {
		if (mthingtype == doomednum_far[i]) {
			break;
		}
	}


#ifdef CHECK_FOR_ERRORS
	if (i == NUMMOBJTYPES) {
		I_Error("P_SpawnMapThing: Unknown type %i at (%i, %i)",
			mthingtype,
			mthingx, mthingy);
	}
#endif


	// don't spawn any monsters if -nomonsters
	if (nomonsters && (i == MT_SKULL || (mobjinfo[i].flags2 & MF_COUNTKILL))) {
		return;
	}

	// spawn it
	x.h.fracbits = 0;
	y.h.fracbits = 0;
	x.h.intbits = mthingx;
	y.h.intbits = mthingy;

	if (mobjinfo[i].flags1 & MF_SPAWNCEILING) {
		z.w = ONCEILINGZ;
	}
	else {
		z.w = ONFLOORZ;
	}

	mobjRef = P_SpawnMobj(x.w, y.w, z.w, i, -1);

	mobj = setStateReturn;
	mobj_pos = setStateReturn_pos;
	nightmarespawns[mobjRef] = mthing;

	if (mobj->tics > 0 && mobj->tics < 240)
		mobj->tics = 1 + (P_Random() % mobj->tics);
	if (mobj_pos->flags2 & MF_COUNTKILL)
		totalkills++;
	if (mobj_pos->flags2 & MF_COUNTITEM)
		totalitems++;


	mobj_pos->angle.wu = FastMul1632u((mthingangle / 45), ANG45);

	if (mthingoptions & MTF_AMBUSH)
		mobj_pos->flags1 |= MF_AMBUSH;

 

}
 */

// 
// P_ExplodeMissile  
//
/*
void __near P_ExplodeMissile(mobj_t __near* mo, mobj_pos_t __far* mo_pos){
	//todoaddr inline later
	statenum_t (__far  * getDeathState)(uint8_t) = getDeathStateAddr;

    mo->momx.w = mo->momy.w = mo->momz.w = 0;
    P_SetMobjState (mo,getDeathState(mo->type));

    mo->tics -= P_Random()&3;

	if (mo->tics < 1 || mo->tics > 240) {
		mo->tics = 1;
	}

	mo_pos->flags2 &= ~MF_MISSILE;
	
	if (mobjinfo[mo->type].deathsound) {
		S_StartSound(mo, mobjinfo[mo->type].deathsound);
	}
}
*/

//
// P_XYMovement  
//


// todo make near?
fixed_t  FastMulFriction (fixed_t num);
// void __far P_XYMovement (mobj_t __near* mo, mobj_pos_t __far* mo_pos);

/*
void __near P_XYMovement (mobj_t __near* mo, mobj_pos_t __far* mo_pos) { 	
    fixed_t_union 	ptryx;
    fixed_t_union	ptryy;
	int16_t motype = mo->type;
	fixed_t_union	xmove;
	fixed_t_union	ymove;
	fixed_t_union momomx;
	fixed_t_union momomy;
	int16_t ceilinglinebacksecnum;
	int16_t mosecnum;
	short_height_t sectorfloorheight;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	
	

	if (!mo->momx.w && !mo->momy.w) {

		if (mo_pos->flags2 & MF_SKULLFLY) {
			// the skull slammed into something
			mo_pos->flags2 &= ~MF_SKULLFLY;
			mo->momx.w = mo->momy.w = mo->momz.w = 0;

			P_SetMobjState (mo,mobjinfo[mo->type].spawnstate);
		}
		return;
    }

	mosecnum = mo->secnum;


    if (mo->momx.w > MAXMOVE){
		mo->momx.w = MAXMOVE;
	} else if (mo->momx.w < -MAXMOVE){
		mo->momx.w = -MAXMOVE;
	}

    if (mo->momy.w > MAXMOVE){
		mo->momy.w = MAXMOVE;
	} else if (mo->momy.w < -MAXMOVE){
		mo->momy.w = -MAXMOVE;
	}
		
    xmove = mo->momx;
    ymove = mo->momy;

	
	do {

		if (xmove.w > MAXMOVE/2 || ymove.w > MAXMOVE/2) {
			ptryx.w = mo_pos->x.w + xmove.w/2;
			ptryy.w = mo_pos->y.w + ymove.w/2;
			xmove.w >>= 1;
			ymove.w >>= 1;
		} else {
			ptryx.w = mo_pos->x.w + xmove.w;
			ptryy.w = mo_pos->y.w + ymove.w;
			xmove.w = ymove.w = 0;
		}
		


		if (!P_TryMove (mo, mo_pos, ptryx, ptryy)) {

			// blocked move
			if (motype == MT_PLAYER) {	// try to slide along it
				P_SlideMove ();
			} else if (mo_pos->flags2 & MF_MISSILE) {
				// explode a missile
				ceilinglinebacksecnum= lines_physics[ceilinglinenum].backsecnum;

				if (ceilinglinenum != SECNUM_NULL && ceilinglinebacksecnum != SECNUM_NULL && sectors[ceilinglinebacksecnum].ceilingpic == skyflatnum) {
					// Hack to prevent missiles exploding
					// against the sky.
					// Does not handle sky floors.
 
					P_RemoveMobj (mo);
					return;
				}
			

				P_ExplodeMissile (mo, mo_pos);
			} else {
				mo->momx.w = mo->momy.w = 0;
			}
		}
	

	 
    } while (xmove.w || ymove.w);
	

    // slow down
    if (motype == MT_PLAYER && player.cheats & CF_NOMOMENTUM) {
		// debug option for no sliding at all
		mo->momx.w = mo->momy.w = 0;
 
		return;
    }

	if (mo_pos->flags2 & (MF_MISSILE | MF_SKULLFLY)) {

	 
		return; 	// no friction for missiles ever
	}
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);
	if (mo_pos->z.w > temp.w) {

		return;		// no friction when airborne
	}
    
	if (mo_pos->flags2 & MF_CORPSE) {
		// do not stop sliding
		//  if halfway off a step with some momentum
		if (mo->momx.w > FRACUNIT/4 || mo->momx.w < -FRACUNIT/4 || mo->momy.w > FRACUNIT/4 || mo->momy.w < -FRACUNIT/4) {
			sectorfloorheight = sectors[mosecnum].floorheight;
			if (mo->floorz != sectorfloorheight) {
				
				return;
			}
		}
    }
	momomx = mo->momx;
	momomy = mo->momy;


    if ((momomx.w > -STOPSPEED && momomx.w < STOPSPEED && momomy.w > -STOPSPEED && momomy.w < STOPSPEED) && 
			(motype != MT_PLAYER || (player.cmd.forwardmove== 0 && player.cmd.sidemove == 0 ) )
		) {
	// if in a walking frame, stop moving
		if (motype == MT_PLAYER && (uint32_t)((playerMobj_pos->stateNum) - S_PLAY_RUN1) < 4) {
			P_SetMobjState(playerMobj,S_PLAY);
			//mo = setStateReturn;
		}

		mo->momx.w = 0;
		mo->momy.w = 0;
    } else {

		mo->momx.w = FixedMul16u32 (FRICTION, momomx.w);
		mo->momy.w = FixedMul16u32 (FRICTION, momomy.w);

		// todo revisit. has rounding errors
		//mo->momx.w = FastMulFriction ( momomx.w);
		//mo->momy.w = FastMulFriction ( momomy.w);

	}

}
*/
//
// P_ZMovement
//
// void __far P_ZMovement (mobj_t __near* mo, mobj_pos_t __far* mo_pos);

/*
void __near P_ZMovement (mobj_t __near* mo, mobj_pos_t __far* mo_pos) {
    fixed_t	dist;
	fixed_t	delta;
	mobj_t __near* moTarget;
	mobj_pos_t __far* moTarget_pos;
	fixed_t_union temp;
	int16_t motype = mo->type;
	temp.h.fracbits = 0;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);
    // check for smooth step up
    if (motype == MT_PLAYER && mo_pos->z.w < temp.w) {
		player.viewheightvalue.w -= (temp.w-mo_pos->z.w);

		player.deltaviewheight.w = (VIEWHEIGHT - player.viewheightvalue.w)>>3;
    }
    
    // adjust height
	mo_pos->z.w += mo->momz.w;
	
    if (mo_pos->flags1 & MF_FLOAT && mo->targetRef) {
		// float down towards target if too close
		//todo can this be done with a single if?
		if ( !(mo_pos->flags2 & MF_SKULLFLY) && !(mo_pos->flags2 & MF_INFLOAT) ) {
			moTarget = (mobj_t __near*)&thinkerlist[mo->targetRef].data;
			moTarget_pos = &mobjposlist_6800[mo->targetRef];
			dist = P_AproxDistance (mo_pos->x.w - moTarget_pos->x.w,
				mo_pos->y.w - moTarget_pos->y.w);
	    
			delta =(moTarget_pos->z.w + (mo->height.w>>1)) - mo_pos->z.w;

			if (delta<0 && dist < -(FastMul8u32(3, delta)) )
				mo_pos->z.h.intbits -= FLOATSPEED_HIGHBITS;
			else if (delta>0 && dist < FastMul8u32(3, delta)  )
				mo_pos->z.h.intbits += FLOATSPEED_HIGHBITS;
		}
	
    }
    
    // clip movement
    if (mo_pos->z.w <= temp.w) {
		// hit the floor

		if (is_ultimate){
			// Note (id):
			//  somebody left this after the setting momz to 0,
			//  kinda useless there.
			if (mo_pos->flags2 & MF_SKULLFLY)
			{
				// the skull slammed into something
				mo->momz.w = -mo->momz.w;
			}
		}
	
		if (mo->momz.h.intbits < 0) {
			if (motype == MT_PLAYER && mo->momz.w < -GRAVITY*8)	 {
				// Squat down.
				// Decrease viewheight for a moment
				// after hitting the ground (hard),
				// and utter appropriate sound.
				player.deltaviewheight.w = mo->momz.w>>3;
				S_StartSound (mo, sfx_oof);
			}
			mo->momz.w = 0;
		}



		mo_pos->z.w = temp.w;

		if (!is_ultimate){
			if (mo_pos->flags2 & MF_SKULLFLY) {
				// the skull slammed into something
				mo->momz.w = -mo->momz.w;
			}
		}

		if ( (mo_pos->flags2 & MF_MISSILE) && !(mo_pos->flags1 & MF_NOCLIP) ) {
			P_ExplodeMissile (mo, mo_pos);
			return;
		}
	} else if (! (mo_pos->flags1 & MF_NOGRAVITY) ) {
		if (mo->momz.w == 0) {
			mo->momz.h.intbits = -GRAVITY_HIGHBITS << 1;
		} else {
			mo->momz.h.intbits -= GRAVITY_HIGHBITS;
		}
	}
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->ceilingz);
    if (mo_pos->z.w + mo->height.w > temp.w) {
		// hit the ceiling
		if (mo->momz.w > 0) {
			mo->momz.w = 0;
		}
		mo_pos->z.w = temp.w - mo->height.w;

		if (mo_pos->flags2 & MF_SKULLFLY) {	// the skull slammed into something
			mo->momz.w = -mo->momz.w;
		}
	
		if ( (mo_pos->flags2 & MF_MISSILE) && !(mo_pos->flags1 & MF_NOCLIP) ) {
			P_ExplodeMissile (mo, mo_pos);
			return;
		}
    }



} 
*/



//
// P_NightmareRespawn
//

/*
void __near P_NightmareRespawn(mobj_t __near* mobj, mobj_pos_t __far* mobj_pos) {

	
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;
	mobj_t __near*		mo;
	THINKERREF moRef;
	int16_t subsecnum;
	int16_t subsectorsecnum;
	mobjtype_t mobjtype;
	int16_t mobjsecnum;
	fixed_t_union mobjx;
	fixed_t_union mobjy;
	fixed_t_union temp;
	mapthing_t mobjspawnpoint;
	THINKERREF mobjRef = GETTHINKERREF(mobj);
	mobj_pos_t __far* mo_pos;

	temp.h.fracbits = 0;
	x.h.fracbits = 0;
	y.h.fracbits = 0;
	
	mobjspawnpoint = nightmarespawns[mobjRef];

	x.h.intbits = mobjspawnpoint.x;
	y.h.intbits = mobjspawnpoint.y;
	

	// somthing is occupying it's position?
	if (!P_CheckPosition(mobj, -1, x, y)) {
		return;	// no respwan
	}
	mobjsecnum = mobj->secnum;
	mobjx = mobj_pos->x;
	mobjy = mobj_pos->y;

	// spawn a teleport fog at old spot
	// because of removal of the body?
	// temp.h.intbits = sectors[mobjsecnum].floorheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  sectors[mobjsecnum].floorheight);
	moRef = P_SpawnMobj(mobjx.w, mobjy.w, temp.w, MT_TFOG, mobjsecnum);
	// initiate teleport sound
	S_StartSound(setStateReturn, sfx_telept);

	// spawn a teleport fog at the new spot
	subsecnum = R_PointInSubsector(x, y);
	subsectorsecnum = subsectors[subsecnum].secnum;
	moRef = P_SpawnMobj(x.w, y.w, temp.w, MT_TFOG, subsectorsecnum);

	S_StartSound(setStateReturn, sfx_telept);

	// spawn the new monster

	mobjtype = mobj->type;

	// spawn it
	if (mobjinfo[mobjtype].flags1 & MF_SPAWNCEILING){
		z.w = ONCEILINGZ;
	} else {
		z.w = ONFLOORZ;
	}


    // inherit attributes from deceased one
    moRef = P_SpawnMobj (x.w,y.w,z.w, mobjtype, -1);
	
	// update nightmare respawn data for this new moref..
	nightmarespawns[moRef] = mobjspawnpoint;
	

	mo = setStateReturn;
	mo_pos = setStateReturn_pos;
	//mo->spawnpoint = mobjspawnpoint;
    //todo  fixed_mul? fastdiv -sq
	mo_pos->angle.wu = FastMul1632u((mobjspawnpoint.angle / 45), ANG45);
	if (mobjspawnpoint.options & MTF_AMBUSH) {
		mo_pos->flags1 |= MF_AMBUSH;
	}

    mo->reactiontime = 18;
	
    // remove the old monster,
    P_RemoveMobj (mobj);

}
*/
//
// P_MobjThinker
//

/*
void __near P_MobjThinker (mobj_t __near* mobj, mobj_pos_t __far* mobj_pos, THINKERREF mobjRef) {

	// momentum movement
    fixed_t_union temp;
	void (__far* P_XYMovement)() =                ((void (__far *)(mobj_t __near* mo, mobj_pos_t __far* mo_pos))     	                                                       (MK_FP(physics_highcode_segment, 		 P_XYMovementOffset)));
	void (__far* P_ZMovement)() =                 ((void (__far *)(mobj_t __near* mo, mobj_pos_t __far* mo_pos))     	                                                       (MK_FP(physics_highcode_segment, 		 P_ZMovementOffset)));
	void (__far* P_NightmareRespawn)() =          ((void (__far *)(mobj_t __near* mo, mobj_pos_t __far* mo_pos))     	                                                       (MK_FP(physics_highcode_segment, 		 P_NightmareRespawnOffset)));

	if (mobj->momx.w || mobj->momy.w || (mobj_pos->flags2&MF_SKULLFLY) ) {
		P_XYMovement (mobj, mobj_pos);

		if ((thinkerlist[mobjRef].prevFunctype & TF_FUNCBITS) == TF_DELETEME_HIGHBITS) {
			return;		// mobj was removed
		}
    } 


	temp.h.fracbits = 0;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->floorz);
	if ( (mobj_pos->z.w != temp.w) || mobj->momz.w ) {
		P_ZMovement (mobj, mobj_pos);

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

			if (!P_SetMobjState(mobj, states[mobj_pos->stateNum].nextstate)) {

				return;		// freed itself
			}
 

			

		}
	} else {
		// check for nightmare respawn
		if (!(mobj_pos->flags2 & MF_COUNTKILL)) {
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
		P_NightmareRespawn (mobj, mobj_pos);
    }

}
*/

//
// P_SpawnMobj
//
/*
THINKERREF __far P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type, int16_t knownsecnum ) {
	mobj_t __near*	mobj;
	mobj_pos_t __far*	mobj_pos;
    mobjinfo_t __near*	info;
	THINKERREF mobjRef;
	int16_t mobjsecnum;
	fixed_t_union temp;
	//todoaddr inline later
	int16_t (__far  * getSpawnHealth)(uint8_t) = getSpawnHealthAddr;
	temp.h.fracbits = 0;

	mobj = (mobj_t __near*)P_CreateThinker(TF_MOBJTHINKER_HIGHBITS);
	mobjRef = GETTHINKERREF(mobj);
	mobj_pos = &mobjposlist_6800[mobjRef];



	memset(mobj, 0, sizeof(mobj_t));
	FAR_memset(mobj_pos, 0, sizeof (mobj_pos_t));


	info = &mobjinfo[type];

    mobj->type = type;
    //mobj->info = info;
	mobj_pos->x.w = x;
	mobj_pos->y.w = y;
	mobj->radius = info->radius;// *FRACUNIT;
	mobj->height.h.intbits = info->height;// *FRACUNIT;
	mobj->height.h.fracbits = 0;
	mobj_pos->flags1 = info->flags1;
	mobj_pos->flags2 = info->flags2;
    mobj->health = getSpawnHealth(type);


	if (gameskill != sk_nightmare) {
		mobj->reactiontime = 8;
	}
    
    //mobj->lastlook = P_Random () % 1;
	P_Random();

    // do not set the state with P_SetMobjState,
    // because action routines can not be called yet
	mobj_pos->stateNum = info->spawnstate;
    mobj->tics = states[info->spawnstate].tics;

    // set subsector and/or block links
    P_SetThingPosition (mobj, FP_OFF(mobj_pos), knownsecnum);
 

	mobjsecnum = mobj->secnum;
	mobj->floorz = sectors[mobjsecnum].floorheight;
	mobj->ceilingz = sectors[mobjsecnum].ceilingheight;

    if (z == ONFLOORZ){
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(mobj_pos->z,  mobj->floorz);
	} else if (z == ONCEILINGZ){
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->ceilingz);
		temp.h.intbits -= mobjinfo[mobj->type].height;
		mobj_pos->z.w = temp.w;
	} else {
		mobj_pos->z.w = z;
	}

	setStateReturn = mobj;
	setStateReturn_pos = mobj_pos;
    return mobjRef;
}
*/

//
// P_RemoveMobj
//

/*
void __far P_RemoveMobj (mobj_t __near* mobj) {
	THINKERREF mobjRef = GETTHINKERREF(mobj);
    // unlink from sector and block lists
    P_UnsetThingPosition (mobj, mobjRef * sizeof(mobj_pos_t));
    
    // stop any playing sound
    S_StopSoundMobjRef (mobj);

	// free block
	P_RemoveThinker(GETTHINKERREF(mobj));
}
*/


 



//
// GAME SPAWN FUNCTIONS
//


//
// P_SpawnPuff
//
/*

#pragma aux P_SpawnPuffParams __parm [dx ax] [cx bx] [di si]  __modify [ax bx cx dx si di];                    
#pragma aux (P_SpawnPuffParams) P_SpawnPuff;
void __far P_SpawnPuff ( fixed_t	x, fixed_t	y, fixed_t	z ){
	mobj_t __near*	th;
	THINKERREF thRef;
	
    z += ((int32_t) ( (P_Random()-P_Random()))<<10);


    thRef = P_SpawnMobj (x,y,z, MT_PUFF, -1);
	th = setStateReturn;
    th->momz.h.intbits = 1;
    th->tics -= P_Random()&3;

    if (th->tics < 1 || th->tics > 240){
		th->tics = 1;
	}
    // don't make punches spark on the wall
    if (attackrange16 == MELEERANGE){
		P_SetMobjState (th, S_PUFF3);
	}
}



//
// P_SpawnBlood
// 
void __near P_SpawnBlood ( fixed_t x, fixed_t y, fixed_t z, int16_t damage ) {
    mobj_t __near*	th;
	THINKERREF thRef;
	
    z += ((int32_t) ( (P_Random()-P_Random()))<<10);
	thRef  = P_SpawnMobj (x,y,z, MT_BLOOD, -1);
	th = setStateReturn;
    th->momz.h.intbits = 2;
    th->tics -= P_Random()&3;

    if (th->tics < 1 || th->tics > 240)
		th->tics = 1;
		
    if (damage <= 12 && damage >= 9)
		P_SetMobjState (th,S_BLOOD2);
    else if (damage < 9)
		P_SetMobjState (th,S_BLOOD3);
}
*/


//
// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
//
/*

void __near P_CheckMissileSpawn (mobj_t __near* th, mobj_pos_t __far* th_pos) {

    th->tics -= P_Random()&3;
	if (th->tics < 1 || th->tics > 240) {
		th->tics = 1;
	}
    // move a little forward so an angle can
    // be computed if it immediately explodes
	th_pos->x.w += (th->momx.w>>1);
	th_pos->y.w += (th->momy.w>>1);
	th_pos->z.w += (th->momz.w>>1);

	if (!P_TryMove(th, th_pos, th_pos->x, th_pos->y)) {

		P_ExplodeMissile(th, th_pos);
	}
}
*/


//
// P_SpawnMissile
//
// THINKERREF __far P_SpawnMissile (mobj_t __near* source, mobj_pos_t __far* source_pos, mobj_t __near*	dest, mobjtype_t	type ) ;

/*
THINKERREF __near P_SpawnMissile (mobj_t __near* source, mobj_pos_t __far* source_pos, mobj_t __near*	dest, mobjtype_t	type ) {
	mobj_t __near*	th;
	mobj_pos_t __far*	th_pos;
    angle_t	an;
    fixed_t_union dist;
    int16_t dist16;
	fixed_t destz;
	fixed_t momz;
	uint16_t temp;
	mobj_pos_t __far*	dest_pos = GET_MOBJPOS_FROM_MOBJ(dest);
	THINKERREF thRef = P_SpawnMobj (source_pos->x.w, source_pos->y.w, source_pos->z.w + 4*8*FRACUNIT, type, source->secnum);
	th = setStateReturn;
	th_pos = setStateReturn_pos;
	if (mobjinfo[type].seesound) {
		S_StartSound(th, mobjinfo[type].seesound);
	}


    th->targetRef = GETTHINKERREF(source);	// where it came from


	destz = dest_pos->z.w;
	an.wu = R_PointToAngle2 (source_pos->x, source_pos->y, dest_pos->x, dest_pos->y);

    // fuzzy player
	if (dest_pos->flags2 & MF_SHADOW) {
		temp = (P_Random() - P_Random());
		temp  <<= 4;
		an.hu.intbits += temp;
	}

	dist.w = P_AproxDistance(dest_pos->x.w - source_pos->x.w, dest_pos->y.w - source_pos->y.w);
	//dist16 = P_FastDivBySpeed(dist, mobjinfo[type].speed);
	dist16 = dist.h.intbits / (mobjinfo[type].speed - 0x80);
	momz = FastDiv3216u(destz - source_pos->z.w, dist16);
    //dist = FastDiv3232(dist, thspeed);
	//momz = FastDiv3232((destz - source_pos->z.w), dist);

	// was this a bug? not used beyond this point in the func.
	//if (dist16 < 1)
	//	dist16 = 1;


	th_pos->angle = an;
    temp = (an.hu.intbits >> 1) & 0xFFFC;
	
    th->momx.w = FixedMulTrigSpeedNoShift(FINE_COSINE_ARGUMENT, temp, mobjinfo[type].speed);
    th->momy.w = FixedMulTrigSpeedNoShift(FINE_SINE_ARGUMENT  , temp, mobjinfo[type].speed);
	th->momz.w = momz;


	P_CheckMissileSpawn (th, th_pos);
	
	setStateReturn = th;
	setStateReturn_pos = th_pos;

    return thRef;
}

*/

// void __near A_BFGSpray(mobj_t __near* mo, mobj_pos_t __far* mo_pos);

//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
// void __far P_SpawnPlayerMissile ( mobjtype_t type );

/*
void __near P_SpawnPlayerMissile ( mobjtype_t type ) {
	mobj_t __near*	th;
	mobj_pos_t __far*	th_pos;
	THINKERREF thRef;
    fineangle_t	an;
    
    fixed_t_union	z;
    fixed_t	slope;

    // see which target is to be aimed at
    // todo use fixed_t_union
	an = playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
	slope = P_AimLineAttack (playerMobj, an, HALFMISSILERANGE);
    
    if (!linetarget) {
		// todo use fixed_t_union
		an = MOD_FINE_ANGLE(an +(1<<(26- ANGLETOFINESHIFT)));
		slope = P_AimLineAttack (playerMobj, an, HALFMISSILERANGE);
		if (!linetarget) {
			// todo use fixed_t_union
			an = MOD_FINE_ANGLE(an - (2<<(26-ANGLETOFINESHIFT)));
			slope = P_AimLineAttack (playerMobj, an, HALFMISSILERANGE);
		}
		if (!linetarget) {
			an = playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
			slope = 0;
		}
    }

	
	z.w = playerMobj_pos->z.w;
	z.h.intbits += 32;
	
    thRef = P_SpawnMobj (playerMobj_pos->x.w, playerMobj_pos->y.w,z.w, type, playerMobj->secnum);
	th = setStateReturn;
	th_pos = setStateReturn_pos;
    if (mobjinfo[type].seesound)
		S_StartSound (th, mobjinfo[type].seesound);

    th->targetRef = playerMobjRef;
	th_pos->angle.hu.intbits = an;
	th_pos->angle.hu.intbits <<= 3;
	th_pos->angle.hu.fracbits = 0;


    th->momx.w = FixedMulTrigSpeed(FINE_COSINE_ARGUMENT, an,  mobjinfo[type].speed);
    th->momy.w = FixedMulTrigSpeed(FINE_SINE_ARGUMENT, an,  mobjinfo[type].speed);
    
	// todo check slope for 0
	// basically this is only ever called with projectile speed values (10, 15, 20, or 25 * FRACUNIT)
	// this is encoded as 10, 25, 20, or 25 + the 0x80 flag in the mobjinfo speed byte.
	// since the bottom word is 0 (since its shifted 16 bits left by the FRACUNIT)
	// the Fixedmul (16 bit shifted result) is equivalent to a normal multiply without shifting.
	// so we just multiply slope by speed - 0x80 

	th->momz.w = FastMul16u32( mobjinfo[type].speed-0x80, slope);

    P_CheckMissileSpawn (th, th_pos);
}
*/

/*
boolean __far P_SetMobjState (mobj_t __near* mobj, statenum_t state) {
	state_t __far*	st;
	mobj_pos_t __far* mobj_pos;

	setStateReturn = mobj;
	mobj_pos = setStateReturn_pos = GET_MOBJPOS_FROM_MOBJ(mobj);
	
	do {
		if (state == S_NULL) {
			mobj_pos->stateNum = S_NULL;
			P_RemoveMobj(mobj);
			setStateReturn = mobj;
			setStateReturn_pos = GET_MOBJPOS_FROM_MOBJ(mobj);
			return false;
		}


		st = &states[state];
		mobj_pos->stateNum = state;
		mobj->tics = st->tics;

		//mobj->sprite = st->sprite;
		//mobj->frame = st->frame;


		// Modified handling.
		// Call action functions when the state is set



		switch (st->action) {

			case ETF_A_BFGSpray: 		A_BFGSprayFar(		mobj, mobj_pos); break;
			case ETF_A_Explode: 		A_Explode(			mobj, mobj_pos); break;
			case ETF_A_Pain: 			A_Pain(				mobj, mobj_pos); break;
			case ETF_A_PlayerScream: 	A_PlayerScream(		mobj, mobj_pos); break;
			case ETF_A_Fall: 			A_Fall(				mobj, mobj_pos); break;
			case ETF_A_XScream: 		A_XScream(			mobj, mobj_pos); break;
			case ETF_A_Look: 			A_Look(				mobj, mobj_pos); break;
			case ETF_A_Chase: 			A_Chase(			mobj, mobj_pos); break;
			case ETF_A_FaceTarget: 		A_FaceTarget(		mobj, mobj_pos); break;
			case ETF_A_PosAttack: 		A_PosAttack(		mobj, mobj_pos); break;
			case ETF_A_Scream: 			A_Scream(			mobj, mobj_pos); break;
			case ETF_A_SPosAttack: 		A_SPosAttack(		mobj, mobj_pos); break;
			case ETF_A_VileChase: 		A_VileChase(		mobj, mobj_pos); break;
			case ETF_A_VileStart: 		A_VileStart(		mobj, mobj_pos); break;
			case ETF_A_VileTarget: 		A_VileTarget(		mobj, mobj_pos); break;
			case ETF_A_VileAttack: 		A_VileAttack(		mobj, mobj_pos); break;
			case ETF_A_StartFire: 		A_StartFire(		mobj, mobj_pos); break;
			case ETF_A_Fire: 			A_Fire(				mobj, mobj_pos); break;
			case ETF_A_FireCrackle: 	A_FireCrackle(		mobj, mobj_pos); break;
			case ETF_A_Tracer: 			A_Tracer(			mobj, mobj_pos); break;
			case ETF_A_SkelWhoosh: 		A_SkelWhoosh(		mobj, mobj_pos); break;
			case ETF_A_SkelFist: 		A_SkelFist(			mobj, mobj_pos); break;
			case ETF_A_SkelMissile: 	A_SkelMissile(		mobj, mobj_pos); break;
			case ETF_A_FatRaise: 		A_FatRaise(			mobj, mobj_pos); break;
			case ETF_A_FatAttack1: 		A_FatAttack1(		mobj, mobj_pos); break;
			case ETF_A_FatAttack2: 		A_FatAttack2(		mobj, mobj_pos); break;
			case ETF_A_FatAttack3: 		A_FatAttack3(		mobj, mobj_pos); break;
			case ETF_A_BossDeath: 		A_BossDeath(		mobj, mobj_pos); break;
			case ETF_A_CPosAttack: 		A_CPosAttack(		mobj, mobj_pos); break;
			case ETF_A_CPosRefire: 		A_CPosRefire(		mobj, mobj_pos); break;
			case ETF_A_TroopAttack: 	A_TroopAttack(		mobj, mobj_pos); break;
			case ETF_A_SargAttack: 		A_SargAttack(		mobj, mobj_pos); break;
			case ETF_A_HeadAttack: 		A_HeadAttack(		mobj, mobj_pos); break;
			case ETF_A_BruisAttack: 	A_BruisAttack(		mobj, mobj_pos); break;
			case ETF_A_SkullAttack: 	A_SkullAttack(		mobj, mobj_pos); break;
			case ETF_A_Metal: 			A_Metal(			mobj, mobj_pos); break;
			case ETF_A_SpidRefire: 		A_SpidRefire(		mobj, mobj_pos); break;
			case ETF_A_BabyMetal: 		A_BabyMetal(		mobj, mobj_pos); break;
			case ETF_A_BspiAttack: 		A_BspiAttack(		mobj, mobj_pos); break;
			case ETF_A_Hoof: 			A_Hoof(				mobj, mobj_pos); break;
			case ETF_A_CyberAttack: 	A_CyberAttack(		mobj, mobj_pos); break;
			case ETF_A_PainAttack: 		A_PainAttack(		mobj, mobj_pos); break;
			case ETF_A_PainDie: 		A_PainDie(			mobj, mobj_pos); break;
			case ETF_A_KeenDie: 		A_KeenDie(			mobj, mobj_pos); break;
			case ETF_A_BrainPain: 		A_BrainPain(		mobj, mobj_pos); break;
			case ETF_A_BrainScream: 	A_BrainScream(		mobj, mobj_pos); break;
			case ETF_A_SpawnSound: 		A_SpawnSound(		mobj, mobj_pos); break;
			case ETF_A_SpawnFly: 		A_SpawnFly(			mobj, mobj_pos); break;
			case ETF_A_BrainExplode: 	A_BrainExplode(		mobj, mobj_pos); break;
			case ETF_A_BrainDie: 		G_ExitLevel(); 	break;
				// ugly hacks because these values didnt fit in the char datatype, so we do this to avoid making that field a int16_t in a 1000 element struct array. 
				// easily saving extra 1-2kb of binary size is worth this hack imo - sq
			case ETF_A_BrainAwake:
				mobj->tics = 181;
				A_BrainAwake(mobj, mobj_pos); break;
			case ETF_A_BrainSpit: 
				mobj->tics = 150;
				A_BrainSpit(mobj, mobj_pos); break;
			//default:
		}



		setStateReturn = mobj;
		mobj_pos = setStateReturn_pos = GET_MOBJPOS_FROM_MOBJ(mobj);
		state = st->nextstate;
	} while (!mobj->tics);


	return true;
}
*/
void __near OutOfThinkers (){
	I_Error("Out of thinkers!");
}
