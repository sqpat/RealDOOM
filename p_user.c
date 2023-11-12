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
#include "i_system.h"



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
( 
  fineangle_t	angle,
  fixed_t	move )  {

	playerMobj.momx += FixedMul(move,finecosine(angle));
	playerMobj.momy += FixedMul(move,finesine(angle));
}




//
// P_CalcHeight
// Calculate the walking / running height adjustment
//
void P_CalcHeight () 
{
    fineangle_t		angle;
    fixed_t	bob;
	fixed_t_union temp;
	int16_t temp2;
    temp.h.fracbits = 0;
	// Regular movement bobbing
    // (needs to be calculated for gun swing
    // even if not on ground)
    // OPTIMIZE: tablify angle
    // Note: a LUT allows for effects
    //  like a ramp with low health.
    // todo <- yea lets actually optimize with LUT? - sq
	player.bob =
	FixedMul (playerMobj.momx, playerMobj.momx) + FixedMul (playerMobj.momy, playerMobj.momy);
    
	player.bob >>= 2;

    if (player.bob>MAXBOB)
		player.bob = MAXBOB;
    if ((player.cheats & CF_NOMOMENTUM) || !onground) {
		player.viewz = playerMobj.z + VIEWHEIGHT;
		// temp.h.intbits = (playerMobj.ceilingz >> SHORTFLOORBITS)-4;

		temp2 = (playerMobj.ceilingz - (4 << SHORTFLOORBITS));
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);

		if (player.viewz > temp.w)
			player.viewz = temp.w;

		player.viewz = playerMobj.z + player.viewheight;
		return;
    }
		
    angle = (FINEANGLES/20*leveltime.w)&FINEMASK;
    bob = FixedMul (player.bob/2, finesine(angle));

    
    // move viewheight
    if (player.playerstate == PST_LIVE) {
		player.viewheight += player.deltaviewheight;

		if (player.viewheight > VIEWHEIGHT) {
			player.viewheight = VIEWHEIGHT;
			player.deltaviewheight = 0;
		}

		if (player.viewheight < VIEWHEIGHT/2) {
			player.viewheight = VIEWHEIGHT/2;
			if (player.deltaviewheight <= 0)
				player.deltaviewheight = 1;
		}
		
		if (player.deltaviewheight)	 {
			player.deltaviewheight += FRACUNIT/4;
			if (!player.deltaviewheight)
				player.deltaviewheight = 1;
		}
    }
	player.viewz = playerMobj.z + player.viewheight + bob;

	// temp.h.intbits = (playerMobj.ceilingz >> SHORTFLOORBITS)-4;
	temp2 = (playerMobj.ceilingz - (4 << SHORTFLOORBITS));
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);

    if (player.viewz > temp.w)
		player.viewz = temp.w;
}



//
// P_MovePlayer
//
void P_MovePlayer ()
{
    ticcmd_t*		cmd;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	cmd = &player.cmd;
	temp.h.intbits = cmd->angleturn;
	playerMobj.angle += temp.w;
	//temp.h.intbits = playerMobj.floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, playerMobj.floorz);

    // Do not let the player control movement
    //  if not onground.
    onground = (playerMobj.z <= temp.w);

	if (cmd->forwardmove && onground) {
		P_Thrust(playerMobj.angle >> ANGLETOFINESHIFT, cmd->forwardmove * 2048L);
	}
	
	if (cmd->sidemove && onground) {
		P_Thrust(MOD_FINE_ANGLE((playerMobj.angle >> ANGLETOFINESHIFT) - FINE_ANG90), cmd->sidemove * 2048L);
	}

    if ( (cmd->forwardmove || cmd->sidemove)  && playerMobj.stateNum == S_PLAY ) {
		P_SetMobjState (PLAYER_MOBJ_REF, S_PLAY_RUN1, &playerMobj);
    }
}	



//
// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
//
#define ANG5   	(ANG90/18)

void P_DeathThink ()
{
    angle_t		angle;
    angle_t		delta;
	mobj_t* playerattacker;
	fixed_t_union temp;
	temp.h.fracbits = 0;

    P_MovePsprites();
	
    // fall to the ground
    if (player.viewheight > 6*FRACUNIT)
		player.viewheight -= FRACUNIT;

    if (player.viewheight < 6*FRACUNIT)
		player.viewheight = 6*FRACUNIT;

	player.deltaviewheight = 0;
	
	// temp.h.intbits = playerMobj.floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, playerMobj.floorz);

    onground = (playerMobj.z <= temp.w);
    P_CalcHeight();
	
	if (player.attackerRef && player.attackerRef != PLAYER_MOBJ_REF) {
		playerattacker = (mobj_t*)Z_LoadThinkerBytesFromEMS(player.attackerRef);
		angle = R_PointToAngle2(playerMobj.x, playerMobj.y, playerattacker->x, playerattacker->y);
	

		delta = angle - playerMobj.angle;
	
		if (delta < ANG5 || delta > (uint32_t)-ANG5) {
			// Looking at killer,
			//  so fade damage flash down.
			playerMobj.angle = angle;

			if (player.damagecount)
				player.damagecount--;
		}
		else if (delta < ANG180)
			playerMobj.angle += ANG5;
		else
			playerMobj.angle -= ANG5;
    }
    else if (player.damagecount)
		player.damagecount--;
	

}



//
// P_PlayerThink
//
void P_PlayerThink (void)
{
    ticcmd_t*		cmd;
    weapontype_t	newweapon;

    // fixme: do this in the cheat code
    if (player.cheats & CF_NOCLIP)
		playerMobj.flags |= MF_NOCLIP;
    else
		playerMobj.flags &= ~MF_NOCLIP;
    
    // chain saw run forward
    cmd = &player.cmd;
    if (playerMobj.flags & MF_JUSTATTACKED)
    {
	cmd->angleturn = 0;
	cmd->forwardmove = 100; // 0xc800/512;
	cmd->sidemove = 0;
	playerMobj.flags &= ~MF_JUSTATTACKED;
    }
			
	
    if (player.playerstate == PST_DEAD)
    {
	P_DeathThink();
	return;
    }
    
    // Move around.
    // Reactiontime is used to prevent movement
    //  for a bit after a teleport.
    if (playerMobj.reactiontime)
		playerMobj.reactiontime--;
    else
	P_MovePlayer();
    
    P_CalcHeight();

	if (sectors[playerMobj.secnum].special) {
		P_PlayerInSpecialSector();
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
	    && player.weaponowned[wp_chainsaw]
	    && !(player.readyweapon == wp_chainsaw
		 && player.powers[pw_strength]))
	{
	    newweapon = wp_chainsaw;
	}
	
	if (commercial
	    && newweapon == wp_shotgun 
	    && player.weaponowned[wp_supershotgun]
	    && player.readyweapon != wp_supershotgun)
	{
	    newweapon = wp_supershotgun;
	}
	

	if (player.weaponowned[newweapon]
	    && newweapon != player.readyweapon)
	{
	    // Do not go to plasma or BFG in shareware,
	    //  even if cheated.
	    if ((newweapon != wp_plasma
		 && newweapon != wp_bfg)
		|| !shareware )
	    {
			player.pendingweapon = newweapon;
	    }
	}
    }
    
    // check for use
    if (cmd->buttons & BT_USE)
    {
	if (!player.usedown)
	{
	    P_UseLines ();
		player.usedown = true;
	}
    }
    else
		player.usedown = false;
    
    // cycle psprites
    P_MovePsprites();
    
    // Counters, time dependend power ups.

    // Strength counts up to diminish fade.
    if (player.powers[pw_strength])
		player.powers[pw_strength]++;
		
    if (player.powers[pw_invulnerability])
		player.powers[pw_invulnerability]--;


    if (player.powers[pw_invisibility])
		if (! --player.powers[pw_invisibility] )
			playerMobj.flags &= ~MF_SHADOW;
			
    if (player.powers[pw_infrared])
		player.powers[pw_infrared]--;
		
    if (player.powers[pw_ironfeet])
		player.powers[pw_ironfeet]--;
		
    if (player.damagecount)
		player.damagecount--;
		
    if (player.bonuscount)
		player.bonuscount--;

    
    // Handling colormaps.
    if (player.powers[pw_invulnerability]) {
		if (player.powers[pw_invulnerability] > 4*32 || (player.powers[pw_invulnerability]&8) )
			player.fixedcolormap = INVERSECOLORMAP;
		else
			player.fixedcolormap = 0;
    } else if (player.powers[pw_infrared])	 {
		if (player.powers[pw_infrared] > 4*32 || (player.powers[pw_infrared]&8) ) {
			// almost full bright
			player.fixedcolormap = 1;
		} else {
			player.fixedcolormap = 0;
		}
	} else {
		player.fixedcolormap = 0;
	}
}


