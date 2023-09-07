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
	mobj_t* playermo = (mobj_t* ) Z_LoadBytesFromEMS(players.moRef);
    
	playermo->momx += FixedMul(move,finecosine(angle));
	playermo->momy += FixedMul(move,finesine(angle));
}




//
// P_CalcHeight
// Calculate the walking / running height adjustment
//
void P_CalcHeight () 
{
    fineangle_t		angle;
    fixed_t	bob;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
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
	players.bob =
	FixedMul (playermo->momx, playermo->momx) + FixedMul (playermo->momy, playermo->momy);
    
	players.bob >>= 2;

    if (players.bob>MAXBOB)
		players.bob = MAXBOB;
    if ((players.cheats & CF_NOMOMENTUM) || !onground) {
		players.viewz = playermo->z + VIEWHEIGHT;
		// temp.h.intbits = (playermo->ceilingz >> SHORTFLOORBITS)-4;

		temp2 = (playermo->ceilingz - (4 << SHORTFLOORBITS));
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);

		if (players.viewz > temp.w)
			players.viewz = temp.w;

		players.viewz = playermo->z + players.viewheight;
		return;
    }
		
    angle = (FINEANGLES/20*leveltime.w)&FINEMASK;
    bob = FixedMul (players.bob/2, finesine(angle));

    
    // move viewheight
    if (players.playerstate == PST_LIVE) {
		players.viewheight += players.deltaviewheight;

		if (players.viewheight > VIEWHEIGHT) {
			players.viewheight = VIEWHEIGHT;
			players.deltaviewheight = 0;
		}

		if (players.viewheight < VIEWHEIGHT/2) {
			players.viewheight = VIEWHEIGHT/2;
			if (players.deltaviewheight <= 0)
				players.deltaviewheight = 1;
		}
		
		if (players.deltaviewheight)	 {
			players.deltaviewheight += FRACUNIT/4;
			if (!players.deltaviewheight)
				players.deltaviewheight = 1;
		}
    }
	players.viewz = playermo->z + players.viewheight + bob;

	// temp.h.intbits = (playermo->ceilingz >> SHORTFLOORBITS)-4;
	temp2 = (playermo->ceilingz - (4 << SHORTFLOORBITS));
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);

    if (players.viewz > temp.w)
		players.viewz = temp.w;
}



//
// P_MovePlayer
//
void P_MovePlayer ()
{
    ticcmd_t*		cmd;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
	fixed_t_union temp;
	temp.h.fracbits = 0;
	cmd = &players.cmd;
	temp.h.intbits = cmd->angleturn;
	playermo->angle += temp.w;
	//temp.h.intbits = playermo->floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, playermo->floorz);

    // Do not let the player control movement
    //  if not onground.
    onground = (playermo->z <= temp.w);

    if (cmd->forwardmove && onground)
		P_Thrust (playermo->angle>>ANGLETOFINESHIFT, cmd->forwardmove*2048);
    
    if (cmd->sidemove && onground)
		P_Thrust (MOD_FINE_ANGLE((playermo->angle>>ANGLETOFINESHIFT)-FINE_ANG90), cmd->sidemove*2048);

    if ( (cmd->forwardmove || cmd->sidemove)  && playermo->state == &states[S_PLAY] ) {
		P_SetMobjState (players.moRef, S_PLAY_RUN1);
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
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
	mobj_t* playerattacker;
	fixed_t_union temp;
	temp.h.fracbits = 0;

    P_MovePsprites();
	
    // fall to the ground
    if (players.viewheight > 6*FRACUNIT)
		players.viewheight -= FRACUNIT;

    if (players.viewheight < 6*FRACUNIT)
		players.viewheight = 6*FRACUNIT;

	players.deltaviewheight = 0;
	
	// temp.h.intbits = playermo->floorz >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, playermo->floorz);

    onground = (playermo->z <= temp.w);
    P_CalcHeight();
	
	if (players.attackerRef && players.attackerRef != players.moRef) {
		playerattacker = (mobj_t*)Z_LoadBytesFromEMS(players.attackerRef);
		angle = R_PointToAngle2(playermo->x, playermo->y, playerattacker->x, playerattacker->y);
	

		delta = angle - playermo->angle;
	
		if (delta < ANG5 || delta > (uint32_t)-ANG5) {
			// Looking at killer,
			//  so fade damage flash down.
			playermo->angle = angle;

			if (players.damagecount)
				players.damagecount--;
		}
		else if (delta < ANG180)
			playermo->angle += ANG5;
		else
			playermo->angle -= ANG5;
    }
    else if (players.damagecount)
		players.damagecount--;
	

}



//
// P_PlayerThink
//
void P_PlayerThink (void)
{
    ticcmd_t*		cmd;
    weapontype_t	newweapon;
	mobj_t* playermo;
	int16_t playermosecnum;
	sector_t* sectors;

	playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);

    // fixme: do this in the cheat code
    if (players.cheats & CF_NOCLIP)
		playermo->flags |= MF_NOCLIP;
    else
		playermo->flags &= ~MF_NOCLIP;
    
    // chain saw run forward
    cmd = &players.cmd;
    if (playermo->flags & MF_JUSTATTACKED)
    {
	cmd->angleturn = 0;
	cmd->forwardmove = 100; // 0xc800/512;
	cmd->sidemove = 0;
	playermo->flags &= ~MF_JUSTATTACKED;
    }
			
	
    if (players.playerstate == PST_DEAD)
    {
	P_DeathThink();
	return;
    }
    
    // Move around.
    // Reactiontime is used to prevent movement
    //  for a bit after a teleport.
    if (playermo->reactiontime)
		playermo->reactiontime--;
    else
	P_MovePlayer();
    
    P_CalcHeight();
	playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
	playermosecnum = playermo->secnum;

	sectors = (sector_t*) Z_LoadBytesFromConventional(sectorsRef);
	if (sectors[playermosecnum].special) {
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
	    && players.weaponowned[wp_chainsaw]
	    && !(players.readyweapon == wp_chainsaw
		 && players.powers[pw_strength]))
	{
	    newweapon = wp_chainsaw;
	}
	
	if (commercial
	    && newweapon == wp_shotgun 
	    && players.weaponowned[wp_supershotgun]
	    && players.readyweapon != wp_supershotgun)
	{
	    newweapon = wp_supershotgun;
	}
	

	if (players.weaponowned[newweapon]
	    && newweapon != players.readyweapon)
	{
	    // Do not go to plasma or BFG in shareware,
	    //  even if cheated.
	    if ((newweapon != wp_plasma
		 && newweapon != wp_bfg)
		|| !shareware )
	    {
			players.pendingweapon = newweapon;
	    }
	}
    }
    
    // check for use
    if (cmd->buttons & BT_USE)
    {
	if (!players.usedown)
	{
	    P_UseLines ();
		players.usedown = true;
	}
    }
    else
		players.usedown = false;
    
    // cycle psprites
    P_MovePsprites();
    
    // Counters, time dependend power ups.

    // Strength counts up to diminish fade.
    if (players.powers[pw_strength])
		players.powers[pw_strength]++;
		
    if (players.powers[pw_invulnerability])
		players.powers[pw_invulnerability]--;

	playermo = (mobj_t*) Z_LoadBytesFromEMS(players.moRef);

    if (players.powers[pw_invisibility])
		if (! --players.powers[pw_invisibility] )
			playermo->flags &= ~MF_SHADOW;
			
    if (players.powers[pw_infrared])
		players.powers[pw_infrared]--;
		
    if (players.powers[pw_ironfeet])
		players.powers[pw_ironfeet]--;
		
    if (players.damagecount)
		players.damagecount--;
		
    if (players.bonuscount)
		players.bonuscount--;

    
    // Handling colormaps.
    if (players.powers[pw_invulnerability]) {
		if (players.powers[pw_invulnerability] > 4*32 || (players.powers[pw_invulnerability]&8) )
			players.fixedcolormap = INVERSECOLORMAP;
		else
			players.fixedcolormap = 0;
    } else if (players.powers[pw_infrared])	 {
		if (players.powers[pw_infrared] > 4*32 || (players.powers[pw_infrared]&8) ) {
			// almost full bright
			players.fixedcolormap = 1;
		} else {
			players.fixedcolormap = 0;
		}
	} else {
		players.fixedcolormap = 0;
	}
}


