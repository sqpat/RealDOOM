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
//	Handling interactions (i.e., collisions).
//


// Data.
#include "doomdef.h"
#include "dstrings.h"
#include "sounds.h"

#include "doomstat.h"

#include "m_misc.h"
#include "i_system.h"

#include "am_map.h"

#include "p_local.h"

#include "s_sound.h"

#include "p_inter.h"


#define BONUSADD	6




// a weapon is found with two clip loads,
// a big item has five clip loads
int16_t	maxammo[NUMAMMO] = {200, 50, 300, 50};
int8_t	clipammo[NUMAMMO] = {10, 4, 20, 1};


//
// GET STUFF
//

//
// P_GiveAmmo
// Num is the number of clip loads,
// not the individual count (0= 1/2 clip).
// Returns false if the ammo can't be picked up at all
//

boolean
P_GiveAmmo
( 
  ammotype_t	ammo,
  int16_t		num )
{
    int16_t		oldammo;
	
    if (ammo == am_noammo)
	return false;
		 
		
    if (players.ammo[ammo] == players.maxammo[ammo]  )
	return false;
		
    if (num)
	num *= clipammo[ammo];
    else
	num = clipammo[ammo]/2;
    
    if (gameskill == sk_baby
	|| gameskill == sk_nightmare)
    {
	// give double ammo in trainer mode,
	// you'll need in nightmare
	num <<= 1;
    }
    
		
    oldammo = players.ammo[ammo];
	players.ammo[ammo] += num;

    if (players.ammo[ammo] > players.maxammo[ammo])
		players.ammo[ammo] = players.maxammo[ammo];

    // If non zero ammo, 
    // don't change up weapons,
    // player was lower on purpose.
    if (oldammo)
	return true;	

    // We were down to zero,
    // so select a new weapon.
    // Preferences are not user selectable.
    switch (ammo)
    {
      case am_clip:
	if (players.readyweapon == wp_fist)
	{
	    if (players.weaponowned[wp_chaingun])
			players.pendingweapon = wp_chaingun;
	    else
			players.pendingweapon = wp_pistol;
	}
	break;
	
      case am_shell:
	if (players.readyweapon == wp_fist
	    || players.readyweapon == wp_pistol)
	{
	    if (players.weaponowned[wp_shotgun])
			players.pendingweapon = wp_shotgun;
	}
	break;
	
      case am_cell:
	if (players.readyweapon == wp_fist
	    || players.readyweapon == wp_pistol)
	{
	    if (players.weaponowned[wp_plasma])
			players.pendingweapon = wp_plasma;
	}
	break;
	
      case am_misl:
	if (players.readyweapon == wp_fist)
	{
	    if (players.weaponowned[wp_missile])
			players.pendingweapon = wp_missile;
	}
      default:
	break;
    }
	
    return true;
}


//
// P_GiveWeapon
// The weapon name may have a MF_DROPPED flag ored in.
//
boolean
P_GiveWeapon
( 
  weapontype_t	weapon,
  boolean	dropped )
{
    boolean	gaveammo;
    boolean	gaveweapon;
	
	
    if (weaponinfo[weapon].ammo != am_noammo)
    {
	// give one clip with a dropped weapon,
	// two clips with a found weapon
	if (dropped)
	    gaveammo = P_GiveAmmo (weaponinfo[weapon].ammo, 1);
	else
	    gaveammo = P_GiveAmmo (weaponinfo[weapon].ammo, 2);
    }
    else
	gaveammo = false;
	
    if (players.weaponowned[weapon])
	gaveweapon = false;
    else
    {
	gaveweapon = true;
	players.weaponowned[weapon] = true;
	players.pendingweapon = weapon;
    }
	
    return (gaveweapon || gaveammo);
}

 

//
// P_GiveBody
// Returns false if the body isn't needed at all
//
boolean
P_GiveBody
( 
  int16_t		num )
{
	mobj_t* playerMo;
    if (players.health >= MAXHEALTH)
	return false;
		
	players.health += num;
    if (players.health > MAXHEALTH)
		players.health = MAXHEALTH;

	playerMo = (mobj_t*) Z_LoadBytesFromEMS(players.moRef);
	playerMo->health = players.health;
	
    return true;
}



//
// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.
//
boolean
P_GiveArmor
( 
  int16_t		armortype )
{
    int16_t		hits;
	
    hits = armortype*100;
    if (players.armorpoints >= hits)
	return false;	// don't pick up
		
	players.armortype = armortype;
	players.armorpoints = hits;
	
    return true;
}



//
// P_GiveCard
//
void
P_GiveCard
( 
  card_t	card )
{
    if (players.cards[card])
	return;
    
	players.bonuscount = BONUSADD;
	players.cards[card] = 1;
}


//
// P_GivePower
//
boolean
P_GivePower
( 
	int16_t /*powertype_t*/	power )
{
	mobj_t* playerMo;
    if (power == pw_invulnerability)
    {
		players.powers[power] = INVULNTICS;
	return true;
    }
    
    if (power == pw_invisibility)
    {
	playerMo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);

	players.powers[power] = INVISTICS;
	playerMo->flags |= MF_SHADOW;
	return true;
    }
    
    if (power == pw_infrared)
    {
		players.powers[power] = INFRATICS;
	return true;
    }
    
    if (power == pw_ironfeet)
    {
		players.powers[power] = IRONTICS;
	return true;
    }
    
    if (power == pw_strength)
    {
	P_GiveBody (100);
	players.powers[power] = 1;
	return true;
    }
	
    if (players.powers[power])
	return false;	// already got it
		
	players.powers[power] = 1;
    return true;
}



//
// P_TouchSpecialThing
//
void
P_TouchSpecialThing
( MEMREF	specialRef,
  MEMREF	toucherRef )
{
     int8_t		i;
    fixed_t	delta;
    int16_t		sound;
	mobj_t* playerMo;
	mobj_t* special = (mobj_t*)Z_LoadBytesFromEMS(specialRef);
	fixed_t specialz = special->z;
	spritenum_t specialsprite = special->sprite;
	boolean specialflagsdropped =  special->flags&MF_DROPPED ? 1 : 0;
	boolean specialflagscountitem =  special->flags&MF_COUNTITEM ? 1 : 0;
	mobj_t* toucher = (mobj_t*)Z_LoadBytesFromEMS(toucherRef);
		
    delta = specialz - toucher->z;

    if (delta > toucher->height.w
	|| delta < -8*FRACUNIT)
    {
	// out of reach
	return;
    }
    
	
    sound = sfx_itemup;	

    // Dead thing touching.
    // Can happen with a sliding player corpse.
    if (toucher->health <= 0)
	return;

    // Identify by sprite.
    switch (specialsprite) {
		// armor
		case SPR_ARM1:
			if (!P_GiveArmor (1))
				return;
			players.message = GOTARMOR;
			break;
			
		case SPR_ARM2:
			if (!P_GiveArmor (2))
				return;
			players.message = GOTMEGA;
			break;
		
		// bonus items
		case SPR_BON1:
			players.health++;		// can go over 100%
			if (players.health > 200)
				players.health = 200;
			playerMo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
			playerMo->health = players.health;
			players.message = GOTHTHBONUS;
			break;
		
		case SPR_BON2:
			players.armorpoints++;		// can go over 100%
			if (players.armorpoints > 200)
				players.armorpoints = 200;
			if (!players.armortype)
				players.armortype = 1;
			players.message = GOTARMBONUS;
			break;
			
		case SPR_SOUL:
			players.health += 100;
			if (players.health > 200)
				players.health = 200;
			playerMo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
			playerMo->health = players.health;
			players.message = GOTSUPER;
			sound = sfx_getpow;
			break;
		
		case SPR_MEGA:
			if (!commercial)
				return;
			players.health = 200;
			playerMo = (mobj_t*)Z_LoadBytesFromEMS(players.moRef);
			playerMo->health = players.health;
			P_GiveArmor (2);
			players.message = GOTMSPHERE;
			sound = sfx_getpow;
			break;
		
			// cards
			// leave cards for everyone
		case SPR_BKEY:
			if (!players.cards[it_bluecard])
				players.message = GOTBLUECARD;
			P_GiveCard (it_bluecard);
				break;
			return;
		
		case SPR_YKEY:
			if (!players.cards[it_yellowcard])
				players.message = GOTYELWCARD;
			P_GiveCard (it_yellowcard);
				break;
			return;
		
		case SPR_RKEY:
			if (!players.cards[it_redcard])
				players.message = GOTREDCARD;
			P_GiveCard (it_redcard);
				break;
			return;
		
		case SPR_BSKU:
			if (!players.cards[it_blueskull])
				players.message = GOTBLUESKUL;
			P_GiveCard (it_blueskull);
				break;
			return;
		
		case SPR_YSKU:
			if (!players.cards[it_yellowskull])
				players.message = GOTYELWSKUL;
			P_GiveCard (it_yellowskull);
				break;
			return;
		
		case SPR_RSKU:
			if (!players.cards[it_redskull])
				players.message = GOTREDSKULL;
			P_GiveCard (it_redskull);
				break;
			return;
		
		// medikits, heals
		case SPR_STIM:
			if (!P_GiveBody (10))
				return;
			players.message = GOTSTIM;
			break;
		
		case SPR_MEDI:
			if (!P_GiveBody (25))
				return;

			players.message = GOTMEDIKIT;
			break;

		
		// power ups
		case SPR_PINV:
			if (!P_GivePower (pw_invulnerability))
				return;
			players.message = GOTINVUL;
			sound = sfx_getpow;
			break;
		
		case SPR_PSTR:
			if (!P_GivePower (pw_strength))
				return;
			players.message = GOTBERSERK;
			if (players.readyweapon != wp_fist)
				players.pendingweapon = wp_fist;
			sound = sfx_getpow;
			break;
		
		case SPR_PINS:
			if (!P_GivePower (pw_invisibility))
				return;
			players.message = GOTINVIS;
			sound = sfx_getpow;
			break;
		
		case SPR_SUIT:
			if (!P_GivePower (pw_ironfeet))
				return;
			players.message = GOTSUIT;
			sound = sfx_getpow;
			break;
		
		case SPR_PMAP:
			if (!P_GivePower (pw_allmap))
				return;
			players.message = GOTMAP;
			sound = sfx_getpow;
			break;
		
		case SPR_PVIS:
			if (!P_GivePower (pw_infrared))
				return;
			players.message = GOTVISOR;
			sound = sfx_getpow;
			break;
		
		// ammo
		case SPR_CLIP:
			if (specialflagsdropped) {
				if (!P_GiveAmmo (am_clip,0))
				return;
			} else {
				if (!P_GiveAmmo (am_clip,1))
				return;
			}
			players.message = GOTCLIP;
			break;
		
		case SPR_AMMO:
			if (!P_GiveAmmo (am_clip,5))
				return;
			players.message = GOTCLIPBOX;
			break;
		
		case SPR_ROCK:
			if (!P_GiveAmmo (am_misl,1))
				return;
			players.message = GOTROCKET;
			break;
			
		case SPR_BROK:
			if (!P_GiveAmmo (am_misl,5))
				return;
			players.message = GOTROCKBOX;
			break;
		
		case SPR_CELL:
			if (!P_GiveAmmo (am_cell,1))
				return;
			players.message = GOTCELL;
			break;
		
		case SPR_CELP:
			if (!P_GiveAmmo (am_cell,5))
				return;
			players.message = GOTCELLBOX;
			break;
		
		case SPR_SHEL:
			if (!P_GiveAmmo (am_shell,1))
				return;
			players.message = GOTSHELLS;
			break;
		
		case SPR_SBOX:
			if (!P_GiveAmmo (am_shell,5))
				return;
			players.message = GOTSHELLBOX;
			break;
		
		case SPR_BPAK:
			if (!players.backpack) {
				for (i=0 ; i<NUMAMMO ; i++)
					players.maxammo[i] *= 2;
				players.backpack = true;
			}
			for (i=0 ; i<NUMAMMO ; i++)
				P_GiveAmmo (i, 1);
			players.message = GOTBACKPACK;
			break;
		
		// weapons
		case SPR_BFUG:
			if (!P_GiveWeapon (wp_bfg, false) )
				return;
			players.message = GOTBFG9000;
			sound = sfx_wpnup;	
			break;
		
		case SPR_MGUN:
			if (!P_GiveWeapon (wp_chaingun, specialflagsdropped) )
				return;
			players.message = GOTCHAINGUN;
			sound = sfx_wpnup;	
			break;
		
		case SPR_CSAW:
			if (!P_GiveWeapon (wp_chainsaw, false) )
				return;
			players.message = GOTCHAINSAW;
			sound = sfx_wpnup;	
			break;
		
		case SPR_LAUN:
			if (!P_GiveWeapon (wp_missile, false) )
				return;
			players.message = GOTLAUNCHER;
			sound = sfx_wpnup;	
			break;
		
		case SPR_PLAS:
			if (!P_GiveWeapon (wp_plasma, false) )
				return;
			players.message = GOTPLASMA;
			sound = sfx_wpnup;	
			break;
		
		case SPR_SHOT:
			if (!P_GiveWeapon (wp_shotgun, specialflagsdropped ) )
				return;
			players.message = GOTSHOTGUN;
			sound = sfx_wpnup;	
			break;
			
		case SPR_SGN2:
			if (!P_GiveWeapon (wp_supershotgun, specialflagsdropped ) )
				return;
			players.message = GOTSHOTGUN2;
			sound = sfx_wpnup;	
			break;
				
#ifdef CHECK_FOR_ERRORS
		default:
			I_Error ("P_SpecialThing: Unknown gettable thing");
#endif
    }
	
    if (specialflagscountitem)
		players.itemcount++;
    P_RemoveMobj (specialRef);
    players.bonuscount += BONUSADD;
    //  always true? 
	//if (player == &players)
	S_StartSound (NULL, sound);
}


//
// KillMobj
//
void
P_KillMobj
( MEMREF	sourceRef,
	MEMREF	targetRef )
{
    mobjtype_t	item;
    mobj_t*	mo;
	mobj_t* source;
	mobj_t*	target = (mobj_t*)Z_LoadBytesFromEMS(targetRef);
	MEMREF moRef;

	
    target->flags &= ~(MF_SHOOTABLE|MF_FLOAT|MF_SKULLFLY);

    if (target->type != MT_SKULL)
	target->flags &= ~MF_NOGRAVITY;

    target->flags |= MF_CORPSE|MF_DROPOFF;
    target->height.w >>= 2;

    if (sourceRef) {
		source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
		if (source->player) {
			// count for intermission
			if (target->flags & MF_COUNTKILL)
				source->player->killcount++;

			 
		}
			
    }
	else if (target->flags & MF_COUNTKILL)
	{
	// count all monster deaths,
	// even those caused by other monsters
	players.killcount++;
    }
    
    if (target->player)
    {
			
	target->flags &= ~MF_SOLID;
	target->player->playerstate = PST_DEAD;
	P_DropWeapon (target->player);

	if (target->player == &players
	    && automapactive)
	{
	    // don't die in auto map,
	    // switch view prior to dying
	    AM_Stop ();
	}
	
    }

    if (target->health < -target->info->spawnhealth  && getXDeathState(target->type)) {
		P_SetMobjState (targetRef, getXDeathState(target->type)) ;
    } else {
		P_SetMobjState (targetRef, target->info->deathstate);
	}
    target->tics -= P_Random()&3;

    if (target->tics < 1)
	target->tics = 1;
		
    //	I_StartSound (&actor->r, actor->info->deathsound);


    // Drop stuff.
    // This determines the kind of object spawned
    // during the death frame of a thing.
    switch (target->type)
    {
      case MT_WOLFSS:
      case MT_POSSESSED:
	item = MT_CLIP;
	break;
	
      case MT_SHOTGUY:
	item = MT_SHOTGUN;
	break;
	
      case MT_CHAINGUY:
	item = MT_CHAINGUN;
	break;
	
      default:
	return;
    }

    moRef = P_SpawnMobj (target->x,target->y,ONFLOORZ, item);
	mo = (mobj_t*)Z_LoadBytesFromEMS(moRef);
    mo->flags |= MF_DROPPED;	// special versions of items
}




//
// P_DamageMobj
// Damages both enemies and players
// "inflictor" is the thing that caused the damage
//  creature or missile, can be NULL (slime, etc)
// "source" is the thing to target after taking damage
//  creature or NULL
// Source and inflictor are the same for melee attacks.
// Source can be NULL for slime, barrel explosions
// and other environmental stuff.
//
void
P_DamageMobj
( MEMREF	targetRef,
	MEMREF	inflictorRef,
	MEMREF	sourceRef,
	int16_t 		damage )
{
	angle_t	ang;
    int16_t		saved;
    player_t*	player;
    fixed_t	thrust;
	mobj_t* source;
	mobj_t* inflictor;
	mobj_t* target;
	fixed_t inflictorx;
	fixed_t inflictory;
	fixed_t inflictorz;
	sector_t* sectors;
	int16_t targetsecnum;
	int16_t targethealth;

	target = (mobj_t*)Z_LoadBytesFromEMS(targetRef);
 
	if (!(target->flags & MF_SHOOTABLE)) {
		return;	// shouldn't happen...
	}
		
	if (target->health <= 0) {
		return;
	}
    if ( target->flags & MF_SKULLFLY ) {
		target->momx = target->momy = target->momz = 0;
    }
	
    player = target->player;
    
	if (player && gameskill == sk_baby) {
		damage >>= 1; 	// take half damage in trainer mode
	}

    // Some close combat weapons should not
    // inflict thrust and push the victim out of reach,
    // thus kick away unless using the chainsaw.

	if (sourceRef) {
		source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
	}

    if (inflictorRef && !(target->flags & MF_NOCLIP) && (!sourceRef || !source->player || source->player->readyweapon != wp_chainsaw)) {

		inflictor = (mobj_t*)Z_LoadBytesFromEMS(inflictorRef);
		inflictorx = inflictor->x;
		inflictory = inflictor->y;
		inflictorz = inflictor->z;
		target = (mobj_t*)Z_LoadBytesFromEMS(targetRef);

		ang = R_PointToAngle2 ( inflictorx,
				inflictory,
				target->x,
				target->y);
		
		thrust = damage*(FRACUNIT>>3)*100/getMobjMass(target->type);

		// make fall forwards sometimes
		if ( damage < 40
			 && damage > target->health
			 && target->z - inflictorz > 64*FRACUNIT
			 && (P_Random ()&1) )
		{
			ang += ANG180;
			thrust *= 4;
		}

		ang >>= ANGLETOFINESHIFT;
		target->momx += FixedMul (thrust, finecosine(ang));
		target->momy += FixedMul (thrust, finesine(ang));
    }
	targetsecnum = target->secnum;
	targethealth = target->health;
    // player specific
    if (player) {

		// end of game hell hack
		sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
		if (sectors[targetsecnum].special == 11 && damage >= targethealth) {
			damage = target->health - 1;
		}

		// Below certain threshold,
		// ignore damage in GOD mode, or with INVUL power.
		if ( damage < 1000
			 && ( (players.cheats & CF_GODMODE)
			  || players.powers[pw_invulnerability] ) )
		{
			return;
		}
	
		if (players.armortype)
		{
			if (players.armortype == 1)
			saved = damage/3;
			else
			saved = damage/2;
	    
			if (players.armorpoints <= saved)
			{
			// armor is used up
			saved = players.armorpoints;
			players.armortype = 0;
			}
			players.armorpoints -= saved;
			damage -= saved;
		}

 


		players.health -= damage; 	// mirror mobj health here for Dave
		if (players.health < 0)
			players.health = 0;
	
		players.attackerRef = sourceRef;
		players.damagecount += damage;	// add damage after armor / invuln

		if (players.damagecount > 100)
			players.damagecount = 100;	// teleport stomp does 10k points...
	


 

	}
    


	target = (mobj_t*)Z_LoadBytesFromEMS(targetRef);
    // do the damage	
    target->health -= damage;	
    if (target->health <= 0) {
		P_KillMobj (sourceRef, targetRef);
		return;
    }

    if ( (P_Random () < getPainChance(target->type)) && !(target->flags&MF_SKULLFLY) ) {
		target->flags |= MF_JUSTHIT;	// fight back!
		P_SetMobjState (targetRef, target->info->painstate);
    }
			

    target->reactiontime = 0;		// we're awake now...	
	if (sourceRef) {
		source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);
	}
    if ( (!target->threshold || target->type == MT_VILE)
	 && sourceRef && sourceRef != targetRef
	 && source->type != MT_VILE)
    {
	// if not intent on another player,
	// chase after this one
	target->targetRef = sourceRef;
	target->threshold = BASETHRESHOLD;
	if (target->state == &states[target->info->spawnstate]
	    && target->info->seestate != S_NULL)
	    P_SetMobjState (targetRef, target->info->seestate);
    }
	 


}

