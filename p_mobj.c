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


void G_PlayerReborn (int player);
void P_SpawnMapThing (mapthing_t*	mthing);


//
// P_SetMobjState
// Returns true if the mobj is still present.
//
static int test = 0;

boolean
P_SetMobjState2
( MEMREF mobjRef,
  statenum_t	state , char*file, int line)
{
    state_t*	st;
	mobj_t*	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

	if (mobj->targetRef > 4096) {
		I_Error("bad mobjRef early %i %i %s %i %i", mobjRef, mobj->targetRef, file, line, state);  // should be 28270
	}
	if (mobjRef == 469) {
		test++;
		if (state == 2) {
			I_Error("catch 469 %i %i %s %i %i", mobjRef, mobj->targetRef, file, line, state);  // should be 28270

			//       1: 469 0 mobj.c 478 175 (S_POSS_STND2)     (correspondws with testa = 7)
			// on error 469 28013 p_enemy.c 650 176 (S_POSS_RUN1)

			/*
			 S_POSS_STND2,
		    S_POSS_RUN1,
	*/

		}
	}

    do
    {
	if (state == S_NULL)
	{
		//I_Error("precrash %i %i %s %i %i", mobjRef, mobj->targetRef, file, line, state);  // should be 28270

	    mobj->state = (state_t *) S_NULL;
	    P_RemoveMobj (mobjRef);
	    return false;
	}

	st = &states[state];
	mobj->state = st;
	mobj->tics = st->tics;
	mobj->sprite = st->sprite;
	mobj->frame = st->frame;

	// Modified handling.
	// Call action functions when the state is set
	if (st->action.acp1) {
		st->action.acp1(mobjRef);
	}
	
	state = st->nextstate;
    } while (!mobj->tics);
				
    return true;
}


//
// P_ExplodeMissile  
//
void P_ExplodeMissile(MEMREF moRef){


	mobj_t* mo = (mobj_t*) Z_LoadBytesFromEMS(moRef);
    mo->momx = mo->momy = mo->momz = 0;

    P_SetMobjState (moRef, mobjinfo[mo->type].deathstate);

    mo->tics -= P_Random()&3;

    if (mo->tics < 1)
	mo->tics = 1;

    mo->flags &= ~MF_MISSILE;

    if (mo->info->deathsound)
		S_StartSound (mo, mo->info->deathsound);
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
	mobj_t* mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
	mobj_t* playermo;
			
    if (!mo->momx && !mo->momy)
    {
	if (mo->flags & MF_SKULLFLY)
	{
	    // the skull slammed into something
	    mo->flags &= ~MF_SKULLFLY;
	    mo->momx = mo->momy = mo->momz = 0;

	    P_SetMobjState (moRef, mo->info->spawnstate);
	}
	return;
    }
	
    player = mo->player;
		
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
	
    do
    {
	if (xmove > MAXMOVE/2 || ymove > MAXMOVE/2)
	{
	    ptryx = mo->x + xmove/2;
	    ptryy = mo->y + ymove/2;
	    xmove >>= 1;
	    ymove >>= 1;
	}
	else
	{
	    ptryx = mo->x + xmove;
	    ptryy = mo->y + ymove;
	    xmove = ymove = 0;
	}

		
	if (!P_TryMove (moRef, ptryx, ptryy))
	{
	    // blocked move
	    if (mo->player)
	    {	// try to slide along it
		P_SlideMove (moRef);
	    }
	    else if (mo->flags & MF_MISSILE)
	    {
		// explode a missile
		if (ceilingline &&
		    ceilingline->backsector &&
		    ceilingline->backsector->ceilingpic == skyflatnum)
		{
		    // Hack to prevent missiles exploding
		    // against the sky.
		    // Does not handle sky floors.
		    P_RemoveMobj (moRef);
		    return;
		}
		P_ExplodeMissile (moRef);
	    }
	    else
		mo->momx = mo->momy = 0;
	}
    } while (xmove || ymove);
    
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);

    // slow down
    if (player && player->cheats & CF_NOMOMENTUM) {
		// debug option for no sliding at all
		mo->momx = mo->momy = 0;
		return;
    }

    if (mo->flags & (MF_MISSILE | MF_SKULLFLY) )
		return; 	// no friction for missiles ever
		
    if (mo->z > mo->floorz)
		return;		// no friction when airborne

    if (mo->flags & MF_CORPSE) {
		// do not stop sliding
		//  if halfway off a step with some momentum

		if (mo->momx > FRACUNIT/4
			|| mo->momx < -FRACUNIT/4
			|| mo->momy > FRACUNIT/4
			|| mo->momy < -FRACUNIT/4)
		{
			if (mo->floorz != mo->subsector->sector->floorheight)
			return;
		}
    }

	if (player) {
		playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);
	}


    if (mo->momx > -STOPSPEED && mo->momx < STOPSPEED && mo->momy > -STOPSPEED && mo->momy < STOPSPEED
		&& (!player->moRef || (player->cmd.forwardmove== 0 && player->cmd.sidemove == 0 ) ) ) {
	// if in a walking frame, stop moving

		if (player && player->moRef > 4096) {
			I_Error("2bad moref %i", player->moRef);
		}
		//I_Error("normal moref %i", player->moRef);

		if (player&&(unsigned)((playermo->state - states)- S_PLAY_RUN1) < 4)
			P_SetMobjState (player->moRef, S_PLAY);
	
		mo->momx = 0;
		mo->momy = 0;
    } else {
		mo->momx = FixedMul (mo->momx, FRICTION);
		mo->momy = FixedMul (mo->momy, FRICTION);
    }
}

//
// P_ZMovement
//
void P_ZMovement (MEMREF moRef)
{
    fixed_t	dist;
    fixed_t	delta;
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
			dist = P_AproxDistance (mo->x - moTarget->x,
						mo->y - moTarget->y);
	    
			delta =(moTarget->z + (mo->height>>1)) - mo->z;

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
		}
		else {
			mo->momz -= GRAVITY;
		}
	}
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    if (mo->z + mo->height > mo->ceilingz) {
		// hit the ceiling
		if (mo->momz > 0)
			mo->momz = 0;
			mo->z = mo->ceilingz - mo->height;

			if (mo->flags & MF_SKULLFLY) {	// the skull slammed into something
				mo->momz = -mo->momz;
			}
	
		if ( (mo->flags & MF_MISSILE) && !(mo->flags & MF_NOCLIP) ) {

			//I_Error("blah");
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
	subsector_t*	ss;
	mobj_t*		mo;
	mapthing_t*		mthing;
	MEMREF moRef;
	mobj_t* mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

	x = mobj->spawnpoint.x << FRACBITS;
	y = mobj->spawnpoint.y << FRACBITS;

	// somthing is occupying it's position?
	if (!P_CheckPosition(mobjRef, x, y)) {
		return;	// no respwan
	}
		// spawn a teleport fog at old spot
		// because of removal of the body?
	moRef = P_SpawnMobj(mobj->x, mobj->y, mobj->subsector->sector->floorheight, MT_TFOG);
	// initiate teleport sound
	S_StartSoundFromRef(moRef, sfx_telept);

	// spawn a teleport fog at the new spot
	ss = R_PointInSubsector(x, y);

	moRef = P_SpawnMobj(x, y, ss->sector->floorheight, MT_TFOG);

	S_StartSoundFromRef(moRef, sfx_telept);

	// spawn the new monster
	mthing = &mobj->spawnpoint;

	// spawn it
	if (mobj->info->flags & MF_SPAWNCEILING){
		z = ONCEILINGZ;
	} else {
		z = ONFLOORZ;
	}
    // inherit attributes from deceased one
    moRef = P_SpawnMobj (x,y,z, mobj->type);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    mo->spawnpoint = mobj->spawnpoint;	
    mo->angle = ANG45 * (mthing->angle/45);

	if (mthing->options & MTF_AMBUSH) {
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
			if (!P_SetMobjState(mobjRef, mobj->state->nextstate)) {
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
P_SpawnMobj
( fixed_t	x,
  fixed_t	y,
  fixed_t	z,
  mobjtype_t	type )
{
    mobj_t*	mobj;
    state_t*	st;
    mobjinfo_t*	info;
	MEMREF mobjRef;
	

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

    if (gameskill != sk_nightmare)
	mobj->reactiontime = info->reactiontime;
    
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
	
    mobj->floorz = mobj->subsector->sector->floorheight;
    mobj->ceilingz = mobj->subsector->sector->ceilingheight;

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
    
    // free block
    P_RemoveThinker (mobj->thinkerRef);
}




//
// P_RespawnSpecials
//
void P_RespawnSpecials (void)
{
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
    
    subsector_t*	ss; 
    mobj_t*		mo;
    mapthing_t*		mthing;
	MEMREF moRef;
    
    int			i;

    // only respawn items in deathmatch
    if (deathmatch != 2)
	return;	// 

    // nothing left to respawn?
    if (iquehead == iquetail)
	return;		

    // wait at least 30 seconds
    if (leveltime - itemrespawntime[iquetail] < 30*35)
	return;			

    mthing = &itemrespawnque[iquetail];
	
    x = mthing->x << FRACBITS; 
    y = mthing->y << FRACBITS; 
	  
    // spawn a teleport fog at the new spot
    ss = R_PointInSubsector (x,y); 
    moRef = P_SpawnMobj (x, y, ss->sector->floorheight , MT_IFOG); 
    S_StartSoundFromRef (moRef, sfx_itmbk);

    // find which type to spawn
    for (i=0 ; i< NUMMOBJTYPES ; i++) {
		if (mthing->type == mobjinfo[i].doomednum) {
			break;
		}
    }
    
    // spawn it
    if (mobjinfo[i].flags & MF_SPAWNCEILING)
		z = ONCEILINGZ;
    else
		z = ONFLOORZ;

    moRef = P_SpawnMobj (x,y,z, i);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    mo->spawnpoint = *mthing;	
    mo->angle = ANG45 * (mthing->angle/45);

    // pull it from the que
    iquetail = (iquetail+1)&(ITEMQUESIZE-1);
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
    int			i;

    // not playing?
    if (!playeringame[mthing->type-1])
	return;					
		
    p = &players[mthing->type-1];

    if (p->playerstate == PST_REBORN)
	G_PlayerReborn (mthing->type-1);

    x 		= mthing->x << FRACBITS;
    y 		= mthing->y << FRACBITS;
    z		= ONFLOORZ;
    mobjRef	= P_SpawnMobj (x,y,z, MT_PLAYER);
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);

    // set color translations for player sprites
    if (mthing->type > 1)		
	mobj->flags |= (mthing->type-1)<<MF_TRANSSHIFT;
		
    mobj->angle	= ANG45 * (mthing->angle/45);
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
    
    // give all cards in death match mode
    if (deathmatch)
	for (i=0 ; i<NUMCARDS ; i++)
	    p->cards[i] = true;
			
    if (mthing->type-1 == consoleplayer)
    {
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
void P_SpawnMapThing (mapthing_t* mthing)
{
    int			i;
    int			bit;
    mobj_t*		mobj;
    fixed_t		x;
    fixed_t		y;
    fixed_t		z;
	MEMREF mobjRef;
		
    // count deathmatch start positions
    if (mthing->type == 11)
    {
	if (deathmatch_p < &deathmatchstarts[10])
	{
	    memcpy (deathmatch_p, mthing, sizeof(*mthing));
	    deathmatch_p++;
	}
	return;
    }
	
    // check for players specially
    if (mthing->type <= 4)
    {
	// save spots for respawning in network games
	playerstarts[mthing->type-1] = *mthing;
	if (!deathmatch)
	    P_SpawnPlayer (mthing);

	return;
    }

    // check for apropriate skill level
    if (!netgame && (mthing->options & 16) )
	return;
		
    if (gameskill == sk_baby)
	bit = 1;
    else if (gameskill == sk_nightmare)
	bit = 4;
    else
	bit = 1<<(gameskill-1);

    if (!(mthing->options & bit) )
	return;
	
    // find which type to spawn
    for (i=0 ; i< NUMMOBJTYPES ; i++)
	if (mthing->type == mobjinfo[i].doomednum)
	    break;
	
    if (i==NUMMOBJTYPES)
	I_Error ("P_SpawnMapThing: Unknown type %i at (%i, %i)",
		 mthing->type,
		 mthing->x, mthing->y);
		
    // don't spawn keycards and players in deathmatch
    if (deathmatch && mobjinfo[i].flags & MF_NOTDMATCH)
	return;
		
    // don't spawn any monsters if -nomonsters
    if (nomonsters
	&& ( i == MT_SKULL
	     || (mobjinfo[i].flags & MF_COUNTKILL)) )
    {
	return;
    }
    
    // spawn it
    x = mthing->x << FRACBITS;
    y = mthing->y << FRACBITS;

    if (mobjinfo[i].flags & MF_SPAWNCEILING)
	z = ONCEILINGZ;
    else
	z = ONFLOORZ;
    
    mobjRef = P_SpawnMobj (x,y,z, i);
	mobj = (mobj_t*)Z_LoadBytesFromEMS(mobjRef);
    mobj->spawnpoint = *mthing;

    if (mobj->tics > 0)
	mobj->tics = 1 + (P_Random () % mobj->tics);
    if (mobj->flags & MF_COUNTKILL)
	totalkills++;
    if (mobj->flags & MF_COUNTITEM)
	totalitems++;
		
    mobj->angle = ANG45 * (mthing->angle/45);
    if (mthing->options & MTF_AMBUSH)
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
    if (th->tics < 1)
	th->tics = 1;
    
    // move a little forward so an angle can
    // be computed if it immediately explodes
    th->x += (th->momx>>1);
    th->y += (th->momy>>1);
    th->z += (th->momz>>1);

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
	MEMREF thRef;
    mobj_t*	th;
    angle_t	an;
    int		dist;
	mobj_t*	source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
	mobj_t*	dest = (mobj_t*)Z_LoadBytesFromEMS(destRef);



    thRef = P_SpawnMobj (source->x,
		      source->y,
		      source->z + 4*8*FRACUNIT, type);

	th = (mobj_t*)Z_LoadBytesFromEMS(thRef);
    
    if (th->info->seesound)
	S_StartSound (th, th->info->seesound);

    th->targetRef = sourceRef;	// where it came from
    an = R_PointToAngle2 (source->x, source->y, dest->x, dest->y);	

    // fuzzy player
    if (dest->flags & MF_SHADOW)
	an += (P_Random()-P_Random())<<20;	

    th->angle = an;
    an >>= ANGLETOFINESHIFT;
    th->momx = FixedMul (th->info->speed, finecosine[an]);
    th->momy = FixedMul (th->info->speed, finesine[an]);
	
    dist = P_AproxDistance (dest->x - source->x, dest->y - source->y);
    dist = dist / th->info->speed;

    if (dist < 1)
	dist = 1;

    th->momz = (dest->z - source->z) / dist;
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
    
    if (!linetargetRef)
    {
	an += 1<<26;
	slope = P_AimLineAttack (sourceRef, an, 16*64*FRACUNIT);

	if (!linetargetRef)
	{
	    an -= 2<<26;
	    slope = P_AimLineAttack (sourceRef, an, 16*64*FRACUNIT);
	}

	if (!linetargetRef)
	{
	    an = source->angle;
	    slope = 0;
	}
    }
		
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

