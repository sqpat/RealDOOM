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
//	Player related stuff.
//	Bobbing POV/weapon, movement.
//	Pending weapon.
//


#include "doomdef.h"
#include "d_event.h"

#include "p_local.h"

#include "doomstat.h"



// Index of the special effects (INVUL inverse) map.
#define INVERSECOLORMAP		32


//
// Movement.
//

// 16 pixels of bob
#define MAXBOB	0x100000	

boolean		onground;


//
// P_Thrust
// Moves the given origin along a given angle.
//
void
P_Thrust
( player_t*	player,
  angle_t	angle,
  fixed_t	move )  {
	mobj_t* playermo = (mobj_t* ) Z_LoadBytesFromEMS(player->moRef);
    angle >>= ANGLETOFINESHIFT;
    
	playermo->momx += FixedMul(move,finecosine[angle]);
	playermo->momy += FixedMul(move,finesine[angle]);
}




//
// P_CalcHeight
// Calculate the walking / running height adjustment
//
void P_CalcHeight (player_t* player) 
{
    int		angle;
    fixed_t	bob;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);

    // Regular movement bobbing
    // (needs to be calculated for gun swing
    // even if not on ground)
    // OPTIMIZE: tablify angle
    // Note: a LUT allows for effects
    //  like a ramp with low health.
    player->bob =
	FixedMul (playermo->momx, playermo->momx)
	+ FixedMul (playermo->momy, playermo->momy);
    
    player->bob >>= 2;

    if (player->bob>MAXBOB)
	player->bob = MAXBOB;

    if ((player->cheats & CF_NOMOMENTUM) || !onground)
    {
	player->viewz = playermo->z + VIEWHEIGHT;

	if (player->viewz > playermo->ceilingz-4*FRACUNIT)
	    player->viewz = playermo->ceilingz-4*FRACUNIT;

	player->viewz = playermo->z + player->viewheight;
	return;
    }
		
    angle = (FINEANGLES/20*leveltime)&FINEMASK;
    bob = FixedMul ( player->bob/2, finesine[angle]);

    
    // move viewheight
    if (player->playerstate == PST_LIVE)
    {
	player->viewheight += player->deltaviewheight;

	if (player->viewheight > VIEWHEIGHT)
	{
	    player->viewheight = VIEWHEIGHT;
	    player->deltaviewheight = 0;
	}

	if (player->viewheight < VIEWHEIGHT/2)
	{
	    player->viewheight = VIEWHEIGHT/2;
	    if (player->deltaviewheight <= 0)
		player->deltaviewheight = 1;
	}
	
	if (player->deltaviewheight)	
	{
	    player->deltaviewheight += FRACUNIT/4;
	    if (!player->deltaviewheight)
		player->deltaviewheight = 1;
	}
    }
    player->viewz = playermo->z + player->viewheight + bob;

    if (player->viewz > playermo->ceilingz-4*FRACUNIT)
	player->viewz = playermo->ceilingz-4*FRACUNIT;
}



//
// P_MovePlayer
//
void P_MovePlayer (player_t* player)
{
    ticcmd_t*		cmd;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);

    cmd = &player->cmd;
	
	playermo->angle += (cmd->angleturn<<16);

    // Do not let the player control movement
    //  if not onground.
    onground = (playermo->z <= playermo->floorz);
	
    if (cmd->forwardmove && onground)
	P_Thrust (player, playermo->angle, cmd->forwardmove*2048);
    
    if (cmd->sidemove && onground)
	P_Thrust (player, playermo->angle-ANG90, cmd->sidemove*2048);

    if ( (cmd->forwardmove || cmd->sidemove) 
	 && playermo->state == &states[S_PLAY] )
    {
	P_SetMobjState (player->moRef, S_PLAY_RUN1);
    }
}	



//
// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
//
#define ANG5   	(ANG90/18)

void P_DeathThink (player_t* player)
{
    angle_t		angle;
    angle_t		delta;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);
	mobj_t* playerattacker;

    P_MovePsprites (player);
	
    // fall to the ground
    if (player->viewheight > 6*FRACUNIT)
	player->viewheight -= FRACUNIT;

    if (player->viewheight < 6*FRACUNIT)
	player->viewheight = 6*FRACUNIT;

    player->deltaviewheight = 0;
    onground = (playermo->z <= playermo->floorz);
    P_CalcHeight (player);
	
	if (player->attackerRef && player->attackerRef != player->moRef) {
		playerattacker = (mobj_t*)Z_LoadBytesFromEMS(player->attackerRef);
		angle = R_PointToAngle2(playermo->x, playermo->y, playerattacker->x, playerattacker->y);
	

		delta = angle - playermo->angle;
	
		if (delta < ANG5 || delta > (unsigned)-ANG5) {
			// Looking at killer,
			//  so fade damage flash down.
			playermo->angle = angle;

			if (player->damagecount)
			player->damagecount--;
		}
		else if (delta < ANG180)
			playermo->angle += ANG5;
		else
			playermo->angle -= ANG5;
    }
    else if (player->damagecount)
		player->damagecount--;
	

    if (player->cmd.buttons & BT_USE)
		player->playerstate = PST_REBORN;
}



//
// P_PlayerThink
//
void P_PlayerThink (player_t* player)
{
    ticcmd_t*		cmd;
    weapontype_t	newweapon;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);
	short playermosecnum;
	sector_t* sectors;

    // fixme: do this in the cheat code
    if (player->cheats & CF_NOCLIP)
		playermo->flags |= MF_NOCLIP;
    else
		playermo->flags &= ~MF_NOCLIP;
    
    // chain saw run forward
    cmd = &player->cmd;
    if (playermo->flags & MF_JUSTATTACKED)
    {
	cmd->angleturn = 0;
	cmd->forwardmove = 0xc800/512;
	cmd->sidemove = 0;
	playermo->flags &= ~MF_JUSTATTACKED;
    }
			
	
    if (player->playerstate == PST_DEAD)
    {
	P_DeathThink (player);
	return;
    }
    
    // Move around.
    // Reactiontime is used to prevent movement
    //  for a bit after a teleport.
    if (playermo->reactiontime)
		playermo->reactiontime--;
    else
	P_MovePlayer (player);
    
    P_CalcHeight (player);
	playermo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);
	playermosecnum = playermo->secnum;

	sectors = (sector_t*) Z_LoadBytesFromEMS(sectorsRef);
	if (sectors[playermosecnum].special) {
		P_PlayerInSpecialSector(player);
	}
    // Check for weapon change.

    // A special event has no other buttons.
    if (cmd->buttons & BT_SPECIAL)
	cmd->buttons = 0;			
		
    if (cmd->buttons & BT_CHANGE)
    {
	// The actual changing of the weapon is done
	//  when the weapon psprite can do it
	//  (read: not in the middle of an attack).
	newweapon = (cmd->buttons&BT_WEAPONMASK)>>BT_WEAPONSHIFT;
	
	if (newweapon == wp_fist
	    && player->weaponowned[wp_chainsaw]
	    && !(player->readyweapon == wp_chainsaw
		 && player->powers[pw_strength]))
	{
	    newweapon = wp_chainsaw;
	}
	
	if (commercial
	    && newweapon == wp_shotgun 
	    && player->weaponowned[wp_supershotgun]
	    && player->readyweapon != wp_supershotgun)
	{
	    newweapon = wp_supershotgun;
	}
	

	if (player->weaponowned[newweapon]
	    && newweapon != player->readyweapon)
	{
	    // Do not go to plasma or BFG in shareware,
	    //  even if cheated.
	    if ((newweapon != wp_plasma
		 && newweapon != wp_bfg)
		|| !shareware )
	    {
		player->pendingweapon = newweapon;
	    }
	}
    }
    
    // check for use
    if (cmd->buttons & BT_USE)
    {
	if (!player->usedown)
	{
	    P_UseLines (player);
	    player->usedown = true;
	}
    }
    else
	player->usedown = false;
    
    // cycle psprites
    P_MovePsprites (player);
    
    // Counters, time dependend power ups.

    // Strength counts up to diminish fade.
    if (player->powers[pw_strength])
		player->powers[pw_strength]++;	
		
    if (player->powers[pw_invulnerability])
		player->powers[pw_invulnerability]--;

	playermo = (mobj_t*) Z_LoadBytesFromEMS(player->moRef);

    if (player->powers[pw_invisibility])
		if (! --player->powers[pw_invisibility] )
			playermo->flags &= ~MF_SHADOW;
			
    if (player->powers[pw_infrared])
		player->powers[pw_infrared]--;
		
    if (player->powers[pw_ironfeet])
		player->powers[pw_ironfeet]--;
		
    if (player->damagecount)
		player->damagecount--;
		
    if (player->bonuscount)
		player->bonuscount--;

    
    // Handling colormaps.
    if (player->powers[pw_invulnerability]) {
		if (player->powers[pw_invulnerability] > 4*32 || (player->powers[pw_invulnerability]&8) )
			player->fixedcolormap = INVERSECOLORMAP;
		else
			player->fixedcolormap = 0;
    } else if (player->powers[pw_infrared])	 {
		if (player->powers[pw_infrared] > 4*32 || (player->powers[pw_infrared]&8) ) {
			// almost full bright
			player->fixedcolormap = 1;
		} else {
			player->fixedcolormap = 0;
		}
	} else {
		player->fixedcolormap = 0;
	}
}


