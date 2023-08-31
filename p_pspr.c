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
//	Weapon sprite animation, weapon objects.
//	Action functions for weapons.
//

#include "doomdef.h"
#include "d_event.h"


#include "m_misc.h"
#include "p_local.h"
#include "s_sound.h"

// State.
#include "doomstat.h"

// Data.
#include "sounds.h"

#include "p_pspr.h"
#include "i_system.h"

#define LOWERSPEED		FRACUNIT*6
#define RAISESPEED		FRACUNIT*6

#define WEAPONBOTTOM	128*FRACUNIT
#define WEAPONTOP		32*FRACUNIT


// plasma cells for a bfg attack
#define BFGCELLS		40		

void P_SetPsprite(int8_t		position, statenum_t	stnum);


//
// PSPRITE ACTIONS for waepons.
// This struct controls the weapon animations.
//
// Each entry is:
//   ammo/amunition type
//  upstate
//  downstate
// readystate
// atkstate, i.e. attack/fire/hit frame
// flashstate, muzzle flash
//
weaponinfo_t	weaponinfo[NUMWEAPONS] =
{
    {
	// fist
	am_noammo,
	S_PUNCHUP,
	S_PUNCHDOWN,
	S_PUNCH,
	S_PUNCH1,
	S_NULL
    },	
    {
	// pistol
	am_clip,
	S_PISTOLUP,
	S_PISTOLDOWN,
	S_PISTOL,
	S_PISTOL1,
	S_PISTOLFLASH
    },	
    {
	// shotgun
	am_shell,
	S_SGUNUP,
	S_SGUNDOWN,
	S_SGUN,
	S_SGUN1,
	S_SGUNFLASH1
    },
    {
	// chaingun
	am_clip,
	S_CHAINUP,
	S_CHAINDOWN,
	S_CHAIN,
	S_CHAIN1,
	S_CHAINFLASH1
    },
    {
	// missile launcher
	am_misl,
	S_MISSILEUP,
	S_MISSILEDOWN,
	S_MISSILE,
	S_MISSILE1,
	S_MISSILEFLASH1
    },
    {
	// plasma rifle
	am_cell,
	S_PLASMAUP,
	S_PLASMADOWN,
	S_PLASMA,
	S_PLASMA1,
	S_PLASMAFLASH1
    },
    {
	// bfg 9000
	am_cell,
	S_BFGUP,
	S_BFGDOWN,
	S_BFG,
	S_BFG1,
	S_BFGFLASH1
    },
    {
	// chainsaw
	am_noammo,
	S_SAWUP,
	S_SAWDOWN,
	S_SAW,
	S_SAW1,
	S_NULL
    },
    {
	// super shotgun
	am_shell,
	S_DSGUNUP,
	S_DSGUNDOWN,
	S_DSGUN,
	S_DSGUN1,
	S_DSGUNFLASH1
    },	
};


 


//
// P_BringUpWeapon
// Starts bringing the pending weapon up
// from the bottom of the screen.
// Uses player
//
void P_BringUpWeapon ()
{
    statenum_t	newstate;
	
    if (players.pendingweapon == wp_nochange)
	players.pendingweapon = players.readyweapon;
		
    if (players.pendingweapon == wp_chainsaw)
	S_StartSoundFromRef (players.moRef, sfx_sawup);
		
    newstate = weaponinfo[players.pendingweapon].upstate;

    players.pendingweapon = wp_nochange;
    players.psprites[ps_weapon].sy = WEAPONBOTTOM;

    P_SetPsprite ( ps_weapon, newstate);
}

//
// P_CheckAmmo
// Returns true if there is enough ammo to shoot.
// If not, selects the next weapon to use.
//
boolean P_CheckAmmo ()
{
    ammotype_t		ammo;
    int16_t			count;

    ammo = weaponinfo[players.readyweapon].ammo;

    // Minimal amount for one shot varies.
    if (players.readyweapon == wp_bfg)
	count = BFGCELLS;
    else if (players.readyweapon == wp_supershotgun)
	count = 2;	// Double barrel.
    else
	count = 1;	// Regular.

    // Some do not need ammunition anyway.
    // Return if current ammunition sufficient.
    if (ammo == am_noammo || players.ammo[ammo] >= count)
	return true;
		
    // Out of ammo, pick a weapon to change to.
    // Preferences are set here.
    do
    {
	if (players.weaponowned[wp_plasma]
	    && players.ammo[am_cell]
	    && (!shareware) )
	{
	    players.pendingweapon = wp_plasma;
	}
	else if (players.weaponowned[wp_supershotgun] 
		 && players.ammo[am_shell]>2
		 && (commercial) )
	{
	    players.pendingweapon = wp_supershotgun;
	}
	else if (players.weaponowned[wp_chaingun]
		 && players.ammo[am_clip])
	{
	    players.pendingweapon = wp_chaingun;
	}
	else if (players.weaponowned[wp_shotgun]
		 && players.ammo[am_shell])
	{
	    players.pendingweapon = wp_shotgun;
	}
	else if (players.ammo[am_clip])
	{
	    players.pendingweapon = wp_pistol;
	}
	else if (players.weaponowned[wp_chainsaw])
	{
	    players.pendingweapon = wp_chainsaw;
	}
	else if (players.weaponowned[wp_missile]
		 && players.ammo[am_misl])
	{
	    players.pendingweapon = wp_missile;
	}
	else if (players.weaponowned[wp_bfg]
		 && players.ammo[am_cell]>40
		 && (!shareware) )
	{
	    players.pendingweapon = wp_bfg;
	}
	else
	{
	    // If everything fails.
	    players.pendingweapon = wp_fist;
	}
	
    } while (players.pendingweapon == wp_nochange);

    // Now set appropriate weapon overlay.
    P_SetPsprite (
		  ps_weapon,
		  weaponinfo[players.readyweapon].downstate);

    return false;	
}


//
// P_FireWeapon.
//
void P_FireWeapon ()
{
    statenum_t	newstate;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);

    if (!P_CheckAmmo ())
		return;
	
	P_SetMobjState (players.moRef, S_PLAY_ATK1);
    newstate = weaponinfo[players.readyweapon].atkstate;

	P_SetPsprite (ps_weapon, newstate);
	P_NoiseAlert (players.moRef, players.moRef);
}



//
// P_DropWeapon
// Player died, so put the weapon away.
//
void P_DropWeapon ()
{
    P_SetPsprite (
		  ps_weapon,
		  weaponinfo[players.readyweapon].downstate);
}



//
// A_WeaponReady
// The player can fire the weapon
// or change to another weapon at this time.
// Follows after getting weapon up,
// or after previous attack/fire sequence.
//
void
A_WeaponReady
( 
  pspdef_t*	psp )
{	
    statenum_t	newstate;
    fixed_t		angle;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
    
    // get out of attack state
    if (playermo->state == &states[S_PLAY_ATK1]
	|| playermo->state == &states[S_PLAY_ATK2] )
    {
	P_SetMobjState (players.moRef, S_PLAY);
    }
    
    if (players.readyweapon == wp_chainsaw
	&& psp->state == &states[S_SAW])
    {
	S_StartSoundFromRef (players.moRef, sfx_sawidl);
    }
    
    // check for change
    //  if player is dead, put the weapon away
    if (players.pendingweapon != wp_nochange || !players.health)
    {
	// change weapon
	//  (pending weapon should allready be validated)
	newstate = weaponinfo[players.readyweapon].downstate;
	P_SetPsprite (ps_weapon, newstate);
	return;	
    }
    
    // check for fire
    //  the missile launcher and bfg do not auto fire
    if (players.cmd.buttons & BT_ATTACK)
    {
	if ( !players.attackdown
	     || (players.readyweapon != wp_missile
		 && players.readyweapon != wp_bfg) )
	{
	    players.attackdown = true;
	    P_FireWeapon ();		
	    return;
	}
    }
    else
	players.attackdown = false;
    
    // bob the weapon based on movement speed
    angle = (128*leveltime)&FINEMASK;
    psp->sx = FRACUNIT + FixedMul (players.bob, finecosine(angle));
    angle &= FINEANGLES/2-1;
    psp->sy = WEAPONTOP + FixedMul (players.bob, finesine(angle));

}



//
// A_ReFire
// The player can re-fire the weapon
// without lowering it entirely.
//
void A_ReFire
( 
  pspdef_t*	psp )
{
    
    // check for fire
    //  (if a weaponchange is pending, let it go through instead)
    if ( (players.cmd.buttons & BT_ATTACK) 
	 && players.pendingweapon == wp_nochange
	 && players.health)
    {
	players.refire++;
	P_FireWeapon ();
    }
    else
    {
	players.refire = 0;
	P_CheckAmmo ();
    }
}


void
A_CheckReload
(
  pspdef_t*	psp )
{
    P_CheckAmmo ();
 
}



//
// A_Lower
// Lowers current weapon,
//  and changes weapon at bottom.
//
void
A_Lower
( 
  pspdef_t*	psp )
{	
    psp->sy += LOWERSPEED;

    // Is already down.
    if (psp->sy < WEAPONBOTTOM )
	return;

    // Player is dead.
    if (players.playerstate == PST_DEAD)
    {
	psp->sy = WEAPONBOTTOM;

	// don't bring weapon back up
	return;		
    }
    
    // The old weapon has been lowered off the screen,
    // so change the weapon and start raising it
    if (!players.health)
    {
	// Player is dead, so keep the weapon off screen.
	P_SetPsprite (  ps_weapon, S_NULL);
	return;	
    }
	
    players.readyweapon = players.pendingweapon; 

    P_BringUpWeapon ();
}


//
// A_Raise
//
void
A_Raise
( 
  pspdef_t*	psp )
{
    statenum_t	newstate;
	
    psp->sy -= RAISESPEED;

    if (psp->sy > WEAPONTOP )
	return;
    
    psp->sy = WEAPONTOP;
    
    // The weapon has been raised all the way,
    //  so change to the ready state.
    newstate = weaponinfo[players.readyweapon].readystate;

    P_SetPsprite ( ps_weapon, newstate);
}



//
// A_GunFlash
//
void
A_GunFlash
( 
  pspdef_t*	psp ) 
{
    P_SetMobjState (players.moRef, S_PLAY_ATK2);
    P_SetPsprite (ps_flash,weaponinfo[players.readyweapon].flashstate);
}



//
// WEAPON ATTACKS
//


//
// A_Punch
//
void
A_Punch
( 
  pspdef_t*	psp ) 
{
    fineangle_t	angle;
    int16_t		damage;
    fixed_t		slope;
	mobj_t* playermo = (mobj_t*) Z_LoadBytesFromEMS(players.moRef);
	mobj_t* linetarget;

    damage = (P_Random ()%10+1)<<1;

	if (players.powers[pw_strength]) {
		damage *= 10;
	}

    angle = playermo->angle >> ANGLETOFINESHIFT;
    angle = MOD_FINE_ANGLE(angle + (P_Random()-P_Random())>>(1));
    slope = P_AimLineAttack (players.moRef, angle, MELEERANGE * FRACUNIT);
    P_LineAttack (players.moRef, angle, MELEERANGE * FRACUNIT, slope, damage);

    // turn to face target
    if (linetargetRef)
    {
		S_StartSoundFromRef(players.moRef, sfx_punch);
	linetarget = (mobj_t*) Z_LoadBytesFromEMS(linetargetRef);
	playermo->angle = R_PointToAngle2 (playermo->x, playermo->y, linetarget->x, linetarget->y);
    }


}


//
// A_Saw
//
void
A_Saw
( 
  pspdef_t*	psp ) 
{
	angle_t bigangle;
    fineangle_t	angle;
    int16_t		damage;
    fixed_t		slope;
	mobj_t* playermo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
	mobj_t* linetarget; 

    damage = 2*(P_Random ()%10+1);
    angle = playermo->angle >> ANGLETOFINESHIFT;
    angle = MOD_FINE_ANGLE( + (P_Random()-P_Random())>>(1));
    
    // use meleerange + 1 se the puff doesn't skip the flash
    slope = P_AimLineAttack (players.moRef, angle, (MELEERANGE * FRACUNIT) +1);
    P_LineAttack (players.moRef, angle, (MELEERANGE*FRACUNIT)+1, slope, damage);

    if (!linetargetRef)
    {
		S_StartSoundFromRef(players.moRef, sfx_sawful);
	return;
    }
	S_StartSoundFromRef(players.moRef, sfx_sawhit);
	
	linetarget = (mobj_t*)Z_LoadBytesFromEMS(linetargetRef);
    // turn to face target
    bigangle = R_PointToAngle2 (playermo->x, playermo->y, linetarget->x, linetarget->y);
    if (bigangle - playermo->angle > ANG180)
    {
	if (bigangle - playermo->angle < -ANG90/20)
		playermo->angle = bigangle + ANG90/21;
	else
		playermo->angle -= ANG90/20;
    }
    else
    {
	if (bigangle - playermo->angle > ANG90/20)
		playermo->angle = bigangle - ANG90/21;
	else
		playermo->angle += ANG90/20;
    }
	playermo->flags |= MF_JUSTATTACKED;
}



//
// A_FireMissile
//
void
A_FireMissile
( 
  pspdef_t*	psp ) 
{
    players.ammo[weaponinfo[players.readyweapon].ammo]--;
    P_SpawnPlayerMissile (players.moRef, MT_ROCKET);
}


//
// A_FireBFG
//
void
A_FireBFG
( 
  pspdef_t*	psp ) 
{
    players.ammo[weaponinfo[players.readyweapon].ammo] -= BFGCELLS;
    P_SpawnPlayerMissile (players.moRef, MT_BFG);
}



//
// A_FirePlasma
//
void
A_FirePlasma
( 
  pspdef_t*	psp ) 
{
    players.ammo[weaponinfo[players.readyweapon].ammo]--;

    P_SetPsprite (
		  ps_flash,
		  weaponinfo[players.readyweapon].flashstate+(P_Random ()&1) );

    P_SpawnPlayerMissile (players.moRef, MT_PLASMA);
}



//
// P_BulletSlope
// Sets a slope so a near miss is at aproximately
// the height of the intended target
//
fixed_t		bulletslope;


void P_BulletSlope (MEMREF moRef)
{
    fineangle_t	an;
	mobj_t*	mo = (mobj_t*) Z_LoadBytesFromEMS(moRef);
    // see which target is to be aimed at
    an = mo->angle >> ANGLETOFINESHIFT;
    bulletslope = P_AimLineAttack (moRef, an, 16*64*FRACUNIT);

    if (!linetargetRef) {
		an =  MOD_FINE_ANGLE(an +(1<<(26-ANGLETOFINESHIFT)));
		bulletslope = P_AimLineAttack (moRef, an, 16*64*FRACUNIT);
		if (!linetargetRef) {
			an = MOD_FINE_ANGLE(an- (2<<(26-ANGLETOFINESHIFT)));
			bulletslope = P_AimLineAttack (moRef, an, 16*64*FRACUNIT);
		}
    }
}


//
// P_GunShot
//
void
P_GunShot
( MEMREF moRef,
  boolean	accurate )
{
    fineangle_t	angle;
    int16_t		damage;

	mobj_t*	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
 
    damage = 5*(P_Random ()%3+1);
    angle = mo->angle >> ANGLETOFINESHIFT;

    if (!accurate)
		angle = MOD_FINE_ANGLE(angle + ((P_Random()-P_Random())>>(1)));
    P_LineAttack (moRef, angle, MISSILERANGE, bulletslope, damage);

}


//
// A_FirePistol
//
void
A_FirePistol
( 
  pspdef_t*	psp ) 
{
	
	S_StartSoundFromRef(players.moRef, sfx_pistol);

    P_SetMobjState (players.moRef, S_PLAY_ATK2);
    players.ammo[weaponinfo[players.readyweapon].ammo]--;

    P_SetPsprite (
		  ps_flash,
		  weaponinfo[players.readyweapon].flashstate);

    P_BulletSlope (players.moRef);
    P_GunShot (players.moRef, !players.refire);

}


//
// A_FireShotgun
//
void
A_FireShotgun
( 
  pspdef_t*	psp ) 
{
    int8_t		i;
	
	S_StartSoundFromRef(players.moRef, sfx_shotgn);
    P_SetMobjState (players.moRef, S_PLAY_ATK2);

    players.ammo[weaponinfo[players.readyweapon].ammo]--;

    P_SetPsprite (
		  ps_flash,
		  weaponinfo[players.readyweapon].flashstate);

    P_BulletSlope (players.moRef);

	for (i = 0; i < 7; i++) {
		P_GunShot(players.moRef, false);
	}
}



//
// A_FireShotgun2
//
void
A_FireShotgun2
( 
  pspdef_t*	psp ) 
{
    int8_t		i;
    fineangle_t	angle;
    int16_t		damage;
	mobj_t* playermo;
		
	
	S_StartSoundFromRef(players.moRef, sfx_dshtgn);
    P_SetMobjState (players.moRef, S_PLAY_ATK2);

    players.ammo[weaponinfo[players.readyweapon].ammo]-=2;

    P_SetPsprite (
		  ps_flash,
		  weaponinfo[players.readyweapon].flashstate);

    P_BulletSlope (players.moRef);
	
	playermo = (mobj_t*) Z_LoadBytesFromEMS(players.moRef);
    for (i=0 ; i<20 ; i++)
    {
	damage = 5*(P_Random ()%3+1);
	angle = playermo->angle >> ANGLETOFINESHIFT;
	angle = MOD_FINE_ANGLE( angle + ((P_Random()-P_Random())<<(19-ANGLETOFINESHIFT)));
	P_LineAttack (players.moRef,
		      angle,
		      MISSILERANGE,
		      bulletslope + ((P_Random()-P_Random())<<5), damage);
    }
}


//
// A_FireCGun
//
void
A_FireCGun
( 
  pspdef_t*	psp ) 
{
    S_StartSoundFromRef (players.moRef, sfx_pistol);

    if (!players.ammo[weaponinfo[players.readyweapon].ammo])
	return;
		
    P_SetMobjState (players.moRef, S_PLAY_ATK2);
    players.ammo[weaponinfo[players.readyweapon].ammo]--;

    P_SetPsprite (
		  ps_flash,
		  weaponinfo[players.readyweapon].flashstate
		  + psp->state
		  - &states[S_CHAIN1] );

    P_BulletSlope (players.moRef);
	
    P_GunShot (players.moRef, !players.refire);
}



//
// ?
//
void A_Light0 (pspdef_t *psp)
{
    players.extralight = 0;
}

void A_Light1 (pspdef_t *psp)
{
    players.extralight = 1;
}

void A_Light2 (pspdef_t *psp)
{
    players.extralight = 2;
}


//
// A_BFGSpray
// Spawn a BFG explosion on every monster in view
//
void A_BFGSpray (mobj_t* mo) 
{
    int8_t			i;
    int8_t			j;
    int16_t			damage;
    fineangle_t		an;
	mobj_t* linetarget;
	
    // offset angles from its attack angle
    for (i=0 ; i<40 ; i++) {
		an = MOD_FINE_ANGLE( (mo->angle >> ANGLETOFINESHIFT) - (FINE_ANG90/2) + (FINE_ANG90/40*i));

		// mo->target is the originator ()
		//  of the missile
		P_AimLineAttack (mo->targetRef, an, 16*64*FRACUNIT);

		if (!linetargetRef)
			continue;
		linetarget = (mobj_t*)Z_LoadBytesFromEMS(linetargetRef);

		P_SpawnMobj (linetarget->x,
				linetarget->y,
				linetarget->z + (linetarget->height.w>>2),
				MT_EXTRABFG);
		
		damage = 0;
		for (j=0;j<15;j++)
			damage += (P_Random()&7) + 1;

		if (linetargetRef == 0) {
			I_Error("bad thing caught e");
		}

		P_DamageMobj (linetargetRef, mo->targetRef,mo->targetRef, damage);
    }
}


//
// A_BFGsound
//
void
A_BFGsound
( 
  pspdef_t*	psp )
{
	S_StartSoundFromRef(players.moRef, sfx_bfg);
}



//
// P_SetupPsprites
// Called at start of level for each player.
//
void P_SetupPsprites () 
{
    int8_t	i;
	
    // remove all psprites
    for (i=0 ; i<NUMPSPRITES ; i++)
	players.psprites[i].state = NULL;
		
    // spawn the gun
    players.pendingweapon = players.readyweapon;
    P_BringUpWeapon ();
}




//
// P_MovePsprites
// Called every tic by player thinking routine.
//
void P_MovePsprites () 
{
    int8_t		i;
    pspdef_t*	psp;
    state_t*	state;
	
    psp = &players.psprites[0];
    for (i=0 ; i<NUMPSPRITES ; i++, psp++)
    {
	// a null state means not active
	if ( (state = psp->state) )	
	{
	    // drop tic count and possibly change state

	    // a -1 tic count never changes
	    if (psp->tics != -1)	
	    {
		psp->tics--;
		if (!psp->tics)
		    P_SetPsprite (i, psp->state->nextstate);
	    }				
	}
    }
    
    players.psprites[ps_flash].sx = players.psprites[ps_weapon].sx;
    players.psprites[ps_flash].sy = players.psprites[ps_weapon].sy;
}




//
// P_SetPsprite
//
void
P_SetPsprite
(
	int8_t		position,
	statenum_t	stnum)
{
	pspdef_t*	psp;
	state_t*	state;
	boolean found;

	psp = &players.psprites[position];

	do {
		if (!stnum)
		{
			// object removed itself
			psp->state = NULL;
			break;
		}

		state = &states[stnum];
		psp->state = state;
		psp->tics = state->tics;	// could be 0

		/*
		apparently nused feature in release DOOM, these misc longs are always 0 and add like 8kb to the final executable
		
		if (state->misc1)
		{
			// coordinate set
			psp->sx = state->misc1 << FRACBITS;
			psp->sy = state->misc2 << FRACBITS;
		}

		*/


		// Call action routine.
		// Modified handling.

		// instead of checking action.acp2, 2 variable ones explicitly handled by their switch block, the rest fall thru to default
		found = true;
		switch (state->action) {
			case ETF_A_Light0: A_Light0(psp); break;
			case ETF_A_WeaponReady: A_WeaponReady(psp); break;
			case ETF_A_Lower: A_Lower(psp); break;
			case ETF_A_Raise: A_Raise(psp); break;
			case ETF_A_Punch: A_Punch(psp); break;
			case ETF_A_ReFire: A_ReFire(psp); break;
			case ETF_A_FirePistol: A_FirePistol(psp); break;
			case ETF_A_Light1: A_Light1(psp); break;
			case ETF_A_FireShotgun: A_FireShotgun(psp); break;
			case ETF_A_Light2: A_Light2(psp); break;
			case ETF_A_FireShotgun2: A_FireShotgun2(psp); break;
			case ETF_A_CheckReload: A_CheckReload(psp); break;
			//case ETF_A_OpenShotgun2: A_OpenShotgun2(psp); break;
			//case ETF_A_LoadShotgun2: A_LoadShotgun2(psp); break;
			//case ETF_A_CloseShotgun2: A_CloseShotgun2(psp); break;
			case ETF_A_FireCGun: A_FireCGun(psp); break;
			case ETF_A_GunFlash: A_GunFlash(psp); break;
			case ETF_A_FireMissile: A_FireMissile(psp); break;
			case ETF_A_Saw: A_Saw(psp); break;
			case ETF_A_FirePlasma: A_FirePlasma(psp); break;
			case ETF_A_BFGsound: A_BFGsound(psp); break;
			case ETF_A_FireBFG: A_FireBFG(psp); break;
  
		default:
			found = false;
		}
		if (found)
			if (!psp->state)
				break;


		stnum = psp->state->nextstate;

	} while (!psp->tics);
	// an initial state of 0 could cycle through
}
