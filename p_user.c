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
#include "m_memory.h"
#include "m_near.h"



// Index of the special effects (INVUL inverse) map.
#define INVERSECOLORMAP		32


//
// Movement.
//

// 16 pixels of bob
#define MAXBOB	0x100000	



//
// P_Thrust
// Moves the given origin along a given angle.
//
void
P_Thrust
( 
  fineangle_t	angle,
  fixed_t	move )  {

	// todo
	move <<= 11;
	//move *= 2048L;
	playerMobj->momx.w += FixedMulTrig(FINE_COSINE_ARGUMENT, angle, move);
	playerMobj->momy.w += FixedMulTrig(FINE_SINE_ARGUMENT, angle, move);
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
	// Regular movement bobbing
    // (needs to be calculated for gun swing
    // even if not on ground)
    // OPTIMIZE: tablify angle
    // Note: a LUT allows for effects
    //  like a ramp with low health.
    // todo <- yea lets actually optimize with LUT? - sq
	temp2 = (playerMobj->ceilingz - (4 << SHORTFLOORBITS));
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);

	player.bob.w =
	FixedMul (playerMobj->momx.w, playerMobj->momx.w) + FixedMul (playerMobj->momy.w, playerMobj->momy.w);

	player.bob.w >>= 2;

    if (player.bob.w>MAXBOB)
		player.bob.w = MAXBOB;
    if ((player.cheats & CF_NOMOMENTUM) || !onground) {
		player.viewzvalue = playerMobj_pos->z;
		player.viewzvalue.h.intbits += VIEWHEIGHT_HIGHBITS;

		if (player.viewzvalue.w > temp.w)
			player.viewzvalue = temp;

		player.viewzvalue.w = playerMobj_pos->z.w + player.viewheight.w;
		return;
    }
		
    angle = (FINEANGLES/20*leveltime.w)&FINEMASK;
	// check for MAX_BOB case?
    bob = FixedMulTrig (FINE_SINE_ARGUMENT, angle, player.bob.w>>1);

    
    // move viewheight
    if (player.playerstate == PST_LIVE) {
		player.viewheight.w += player.deltaviewheight.w;

		if (player.viewheight.w > VIEWHEIGHT) {
			player.viewheight.w = VIEWHEIGHT;
			player.deltaviewheight.w = 0;
		}

		if (player.viewheight.w < VIEWHEIGHT/2) {
			player.viewheight.w = VIEWHEIGHT/2;
			if (player.deltaviewheight.w <= 0)
				player.deltaviewheight.w = 1;
		}
		
		if (player.deltaviewheight.w)	 {
			player.deltaviewheight.w += FRACUNIT/4;
			if (!player.deltaviewheight.w)
				player.deltaviewheight.w = 1;
		}
    }
	player.viewzvalue.w = playerMobj_pos->z.w + player.viewheight.w + bob;


    if (player.viewzvalue.w > temp.w)
		player.viewzvalue = temp;
}



//
// P_MovePlayer
//
void P_MovePlayer ()
{
    ticcmd_t __near*		cmd = &player.cmd;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	temp.h.intbits = cmd->angleturn;
	 
	playerMobj_pos->angle.wu += temp.w;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, playerMobj->floorz);

    // Do not let the player control movement
    //  if not onground.
    onground = (playerMobj_pos->z.w <= temp.w);

	if (cmd->forwardmove && onground) {
		P_Thrust(playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT, cmd->forwardmove);
	}
	
	if (cmd->sidemove && onground) {
		P_Thrust(MOD_FINE_ANGLE((playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT) - FINE_ANG90), cmd->sidemove);
	}

    if ( (cmd->forwardmove || cmd->sidemove)  && playerMobj_pos->stateNum == S_PLAY ) {
		P_SetMobjState (playerMobj, S_PLAY_RUN1);
    }
}	

void __near P_MovePsprites () ;


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
	mobj_pos_t __far* playerattacker_pos;
	fixed_t_union temp;
	temp.h.fracbits = 0;

    P_MovePsprites();
	
    // fall to the ground
    if (player.viewheight.w > 6*FRACUNIT)
		player.viewheight.h.intbits -= 1;

    if (player.viewheight.w < 6*FRACUNIT)
		player.viewheight.w = 6*FRACUNIT;

	player.deltaviewheight.w = 0;
	
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, playerMobj->floorz);

    onground = (playerMobj_pos->z.w <= temp.w);
    P_CalcHeight();
	
	if (player.attackerRef && player.attackerRef != playerMobjRef) {
		playerattacker_pos = &mobjposlist[player.attackerRef];
		angle.wu = R_PointToAngle2(playerMobj_pos->x, playerMobj_pos->y, playerattacker_pos->x, playerattacker_pos->y);
	

		delta.wu = angle.wu - playerMobj_pos->angle.wu;
	
		if (delta.wu < ANG5 || delta.wu > (uint32_t)-ANG5) {
			// Looking at killer,
			//  so fade damage flash down.
			playerMobj_pos->angle = angle;

			if (player.damagecount)
				player.damagecount--;
		}
		else if (delta.hu.intbits < ANG180_HIGHBITS)
			playerMobj_pos->angle.wu += ANG5;
		else
			playerMobj_pos->angle.wu -= ANG5;
    }
    else if (player.damagecount)
		player.damagecount--;
	


    if (player.cmd.buttons & BT_USE)
		player.playerstate = PST_REBORN;

}



//
// P_PlayerThink
//
void __near P_PlayerThink (void)
{
    ticcmd_t __near*		cmd;
    weapontype_t	newweapon;

    // fixme: do this in the cheat code
    if (player.cheats & CF_NOCLIP)
		playerMobj_pos->flags1 |= MF_NOCLIP;
    else
		playerMobj_pos->flags1 &= ~MF_NOCLIP;
    
    // chain saw run forward
    cmd = &player.cmd;
    if (playerMobj_pos->flags1 & MF_JUSTATTACKED) {
		cmd->angleturn = 0;
		cmd->forwardmove = 100; // 0xc800/512;
		cmd->sidemove = 0;
		playerMobj_pos->flags1 &= ~MF_JUSTATTACKED;
    }
			
	
    if (player.playerstate == PST_DEAD) {
		P_DeathThink();
		return;
    }
    
    // Move around.
    // Reactiontime is used to prevent movement
    //  for a bit after a teleport.
    if (playerMobj->reactiontime)
		playerMobj->reactiontime--;
    else
		P_MovePlayer();
    
    P_CalcHeight();

	if (sectors_physics[playerMobj->secnum].special) {
		P_PlayerInSpecialSector();
	}
    // Check for weapon change.

    // A special event has no other buttons.
    if (cmd->buttons & BT_SPECIAL)
		cmd->buttons = 0;			
		
    if (cmd->buttons & BT_CHANGE) {
		// The actual changing of the weapon is done
		//  when the weapon psprite can do it
		//  (read: not in the middle of an attack).
		newweapon = (cmd->buttons&BT_WEAPONMASK)>>BT_WEAPONSHIFT;
	
		if (newweapon == wp_fist
			&& player.weaponowned[wp_chainsaw]
			&& !(player.readyweapon == wp_chainsaw
			 && player.powers[pw_strength])) {
			newweapon = wp_chainsaw;
		}
	
		if (commercial
			&& newweapon == wp_shotgun 
			&& player.weaponowned[wp_supershotgun]
			&& player.readyweapon != wp_supershotgun) {
			newweapon = wp_supershotgun;
		}
	

		if (player.weaponowned[newweapon]
			&& newweapon != player.readyweapon) {
			// Do not go to plasma or BFG in shareware,
			//  even if cheated.
			if ((newweapon != wp_plasma
			 && newweapon != wp_bfg)
			|| !shareware ) {
				player.pendingweapon = newweapon;
			}
		}
    }
    
    // check for use
    if (cmd->buttons & BT_USE) {
		if (!player.usedown) {
			P_UseLines ();
			player.usedown = true;
		}
    } else {
		player.usedown = false;
	}
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
			playerMobj_pos->flags2 &= ~MF_SHADOW;
			
    if (player.powers[pw_infrared])
		player.powers[pw_infrared]--;
		
    if (player.powers[pw_ironfeet])
		player.powers[pw_ironfeet]--;
		
    if (player.damagecount)
		player.damagecount--;
		
    if (player.bonuscount)
		player.bonuscount--;

    player.fixedcolormapvalue = 0;
    // Handling colormaps.
    if (player.powers[pw_invulnerability]) {
		if (player.powers[pw_invulnerability] > 4*32 || (player.powers[pw_invulnerability]&8) )
			player.fixedcolormapvalue = INVERSECOLORMAP;
    } else if (player.powers[pw_infrared])	 {
		if (player.powers[pw_infrared] > 4*32 || (player.powers[pw_infrared]&8) ) {
			// almost full bright
			player.fixedcolormapvalue = 1;
		}
	} 
		
	
}


