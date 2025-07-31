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
#include "m_memory.h"
#include "m_near.h"


#define BONUSADD	6




// a weapon is found with two clip loads,
// a big item has five clip loads


//
// GET STUFF
//

//
// P_GiveAmmo
// Num is the number of clip loads,
// not the individual count (0= 1/2 clip).
// Returns false if the ammo can't be picked up at all
//
boolean __near P_GiveAmmo (  ammotype_t	ammo, int16_t		num ) ;
boolean __near P_GiveWeapon (  weapontype_t	weapon, boolean	dropped ) ;
boolean __near P_GiveBody (  int16_t num ) ;
boolean __near P_GiveArmor(  int16_t		armortype );
void __near P_GiveCard (  card_t	card );
boolean __far P_GivePower (  int16_t /*powertype_t*/	power );

/*

boolean __near P_GiveAmmo (  ammotype_t	ammo, int16_t		num ) {
    int16_t		oldammo;
	
    if (ammo == am_noammo){
		return false;
	}
		 
		
    if (player.ammo[ammo] == player.maxammo[ammo]  ){
		return false;
	}
		
    if (num){
		num *= clipammo[ammo];
	} else {
		num = clipammo[ammo]>>1;
	}
    
    if (gameskill == sk_baby || gameskill == sk_nightmare) {
	// give double ammo in trainer mode,
	// you'll need in nightmare
		num <<= 1;
    }
    
		
    oldammo = player.ammo[ammo];
	player.ammo[ammo] += num;

    if (player.ammo[ammo] > player.maxammo[ammo]){
		player.ammo[ammo] = player.maxammo[ammo];
	}

    // If non zero ammo, 
    // don't change up weapons,
    // player was lower on purpose.
    if (oldammo){
		return true;	
	}

    // We were down to zero,
    // so select a new weapon.
    // Preferences are not user selectable.
    switch (ammo) {
		case am_clip:
			if (player.readyweapon == wp_fist) {
				if (player.weaponowned[wp_chaingun]){
					player.pendingweapon = wp_chaingun;
				} else {
					player.pendingweapon = wp_pistol;
				}
			}
			break;

		case am_shell:
			if (player.readyweapon == wp_fist || player.readyweapon == wp_pistol) {
				if (player.weaponowned[wp_shotgun]){
					player.pendingweapon = wp_shotgun;
				}
			}
			break;

		case am_cell:
			if (player.readyweapon == wp_fist || player.readyweapon == wp_pistol) {
				if (player.weaponowned[wp_plasma]){
					player.pendingweapon = wp_plasma;
				}
			}
			break;

		case am_misl:
			if (player.readyweapon == wp_fist) {
				if (player.weaponowned[wp_missile]){
					player.pendingweapon = wp_missile;
				}
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
boolean __near P_GiveWeapon (  weapontype_t	weapon, boolean	dropped ) {
    boolean	gaveammo;
    boolean	gaveweapon;
	
	
    if (weaponinfo[weapon].ammo != am_noammo) {
	// give one clip with a dropped weapon,
	// two clips with a found weapon
		if (dropped) {
			gaveammo = P_GiveAmmo(weaponinfo[weapon].ammo, 1);
		} else {
			gaveammo = P_GiveAmmo(weaponinfo[weapon].ammo, 2);
		}
	} else {
		gaveammo = false;
	}
	if (player.weaponowned[weapon]) {
		gaveweapon = false;
	} else {
		gaveweapon = true;
		player.weaponowned[weapon] = true;
		player.pendingweapon = weapon;
    }
	
    return (gaveweapon || gaveammo);
}

 

//
// P_GiveBody
// Returns false if the body isn't needed at all
//
boolean __near P_GiveBody (  int16_t num ) {
    if (player.health >= MAXHEALTH){
		return false;
	}
		
	player.health += num;
    if (player.health > MAXHEALTH){
		player.health = MAXHEALTH;
	}

	
	playerMobj->health = player.health;
	
    return true;
}



//
// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.
//
boolean __near P_GiveArmor(  int16_t		armortype ) {
    int16_t		hits;
	
    hits = armortype*100;
    if (player.armorpoints >= hits){
		return false;	// don't pick up
	}
	player.armortype = armortype;
	player.armorpoints = hits;
	
    return true;
}



//
// P_GiveCard
//
void __near P_GiveCard (  card_t	card ) {
    if (player.cards[card]){
		return;
	}
    
	player.bonuscount = BONUSADD;
	player.cards[card] = 1;
}




//
// P_GivePower
//
boolean __far P_GivePower (  int16_t 	power ) {
    if (power == pw_invulnerability){
		player.powers[power] = INVULNTICS;
		return true;
    }
    
    if (power == pw_invisibility){
		player.powers[power] = INVISTICS;
		playerMobj_pos->flags2 |= MF_SHADOW;
		return true;
    }
    
    if (power == pw_infrared) {
		player.powers[power] = INFRATICS;
		return true;
    }
    
    if (power == pw_ironfeet){
		player.powers[power] = IRONTICS;
		return true;
    }
    
    if (power == pw_strength){
		P_GiveBody (100);
		player.powers[power] = 1;
		return true;
    }
	
    if (player.powers[power]){
		return false;	// already got it
	}

	player.powers[power] = 1;
	return true;
}

*/


//
// P_TouchSpecialThing
//
// todo make it four offsets
void __far P_TouchSpecialThing ( mobj_t __near*	special, mobj_t __near*	toucher, mobj_pos_t  __far*special_pos, mobj_pos_t  __far*toucher_pos ) {
    int8_t		i;
    fixed_t	delta;
    int16_t		sound;
	fixed_t specialz = special_pos->z.w;
	spritenum_t specialsprite = states[special_pos->stateNum].sprite;
	boolean specialflagsdropped =special_pos->flags2&MF_DROPPED ? 1 : 0;
	boolean specialflagscountitem =  special_pos->flags2&MF_COUNTITEM ? 1 : 0;
		
    delta = specialz - toucher_pos->z.w;

    if (delta > toucher->height.w || delta < -8*FRACUNIT) {
		// out of reach
		return;
    }
    
	
    sound = sfx_itemup;	

    // Dead thing touching.
    // Can happen with a sliding player corpse.
    if (toucher->health <= 0){
		return;
	}

    // Identify by sprite.
    switch (specialsprite) {
		// armor
		case SPR_ARM1:
			if (!P_GiveArmor (1)){
				return;
			}
			player.message = GOTARMOR;
			break;
			
		case SPR_ARM2:
			if (!P_GiveArmor (2)){
				return;
			}
			player.message = GOTMEGA;
			break;
		
		// bonus items
		case SPR_BON1:
			player.health++;		// can go over 100%
			if (player.health > 200){
				player.health = 200;
			}
			playerMobj->health = player.health;
			player.message = GOTHTHBONUS;
			break;
		
		case SPR_BON2:
			player.armorpoints++;		// can go over 100%
			if (player.armorpoints > 200){
				player.armorpoints = 200;
			}
			if (!player.armortype){
				player.armortype = 1;
			}
			player.message = GOTARMBONUS;
			break;
			
		case SPR_SOUL:
			player.health += 100;
			if (player.health > 200){
				player.health = 200;
			}
			playerMobj->health = player.health;
			player.message = GOTSUPER;
			sound = sfx_getpow;
			break;
		
		case SPR_MEGA:
			if (!commercial){
				return;
			}
			player.health = 200;
			playerMobj->health = player.health;
			P_GiveArmor (2);
			player.message = GOTMSPHERE;
			sound = sfx_getpow;
			break;
		
			// cards
			// leave cards for everyone
		case SPR_BKEY:
			if (!player.cards[it_bluecard]){
				player.message = GOTBLUECARD;
			}
			P_GiveCard (it_bluecard);
			break;
			return;
		
		case SPR_YKEY:
			if (!player.cards[it_yellowcard]){
				player.message = GOTYELWCARD;
			}
			P_GiveCard (it_yellowcard);
			break;
			return;
		
		case SPR_RKEY:
			if (!player.cards[it_redcard]){
				player.message = GOTREDCARD;
			}
			P_GiveCard (it_redcard);
			break;
			return;
		
		case SPR_BSKU:
			if (!player.cards[it_blueskull]){
				player.message = GOTBLUESKUL;
			}
			P_GiveCard (it_blueskull);
			break;
			return;
		
		case SPR_YSKU:
			if (!player.cards[it_yellowskull]){
				player.message = GOTYELWSKUL;
			}
			P_GiveCard (it_yellowskull);
			break;
			return;
		
		case SPR_RSKU:
			if (!player.cards[it_redskull]){
				player.message = GOTREDSKULL;
			}
			P_GiveCard (it_redskull);
			break;
			return;
		
		// medikits, heals
		case SPR_STIM:
			if (!P_GiveBody (10)){
				return;
			}
			player.message = GOTSTIM;
			break;
		
		case SPR_MEDI:
			if (!P_GiveBody (25)){
				return;
			}

			player.message = GOTMEDIKIT;
			break;

		
		// power ups
		case SPR_PINV:
			if (!P_GivePower (pw_invulnerability)){
				return;
			}
			player.message = GOTINVUL;
			sound = sfx_getpow;
			break;
		
		case SPR_PSTR:
			if (!P_GivePower (pw_strength)){
				return;
			}
			player.message = GOTBERSERK;
			if (player.readyweapon != wp_fist){
				player.pendingweapon = wp_fist;
			}
			sound = sfx_getpow;
			break;
		
		case SPR_PINS:
			if (!P_GivePower (pw_invisibility)){
				return;
			}
			player.message = GOTINVIS;
			sound = sfx_getpow;
			break;
		
		case SPR_SUIT:
			if (!P_GivePower (pw_ironfeet)){
				return;
			}
			player.message = GOTSUIT;
			sound = sfx_getpow;
			break;
		
		case SPR_PMAP:
			if (!P_GivePower (pw_allmap)){
				return;
			}
			player.message = GOTMAP;
			sound = sfx_getpow;
			break;
		
		case SPR_PVIS:
			if (!P_GivePower (pw_infrared)){
				return;
			}
			player.message = GOTVISOR;
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
			player.message = GOTCLIP;
			break;
		
		case SPR_AMMO:
			if (!P_GiveAmmo (am_clip,5)){
				return;
			}
			player.message = GOTCLIPBOX;
			break;
		
		case SPR_ROCK:
			if (!P_GiveAmmo (am_misl,1)){
				return;
			}
			player.message = GOTROCKET;
			break;
			
		case SPR_BROK:
			if (!P_GiveAmmo (am_misl,5)){
				return;
			}
			player.message = GOTROCKBOX;
			break;
		
		case SPR_CELL:
			if (!P_GiveAmmo (am_cell,1)){
				return;
			}
			player.message = GOTCELL;
			break;
		
		case SPR_CELP:
			if (!P_GiveAmmo (am_cell,5)){
				return;
			}
			player.message = GOTCELLBOX;
			break;
		
		case SPR_SHEL:
			if (!P_GiveAmmo (am_shell,1)){
				return;
			}
			player.message = GOTSHELLS;
			break;
		
		case SPR_SBOX:
			if (!P_GiveAmmo (am_shell,5)){
				return;
			}
			player.message = GOTSHELLBOX;
			break;
		
		case SPR_BPAK:
			if (!player.backpack) {
				for (i=0 ; i<NUMAMMO ; i++){
					player.maxammo[i] *= 2;
				}
				player.backpack = true;
			}
			for (i=0 ; i<NUMAMMO ; i++){
				P_GiveAmmo (i, 1);
			}
			player.message = GOTBACKPACK;
			break;
		
		// weapons
		case SPR_BFUG:
			if (!P_GiveWeapon (wp_bfg, false) ){
				return;
			}
			player.message = GOTBFG9000;
			sound = sfx_wpnup;	
			break;
		
		case SPR_MGUN:
			if (!P_GiveWeapon (wp_chaingun, specialflagsdropped) ){
				return;
			}
			player.message = GOTCHAINGUN;
			sound = sfx_wpnup;	
			break;
		
		case SPR_CSAW:
			if (!P_GiveWeapon (wp_chainsaw, false) ){
				return;
			}
			player.message = GOTCHAINSAW;
			sound = sfx_wpnup;	
			break;
		
		case SPR_LAUN:
			if (!P_GiveWeapon (wp_missile, false) ){
				return;
			}
			player.message = GOTLAUNCHER;
			sound = sfx_wpnup;	
			break;
		
		case SPR_PLAS:
			if (!P_GiveWeapon (wp_plasma, false) ){
				return;
			}
			player.message = GOTPLASMA;
			sound = sfx_wpnup;	
			break;
		
		case SPR_SHOT:
			if (!P_GiveWeapon (wp_shotgun, specialflagsdropped ) ){
				return;
			}
			player.message = GOTSHOTGUN;
			sound = sfx_wpnup;	
			break;
			
		case SPR_SGN2:
			if (!P_GiveWeapon (wp_supershotgun, specialflagsdropped ) ){
				return;
			}
			player.message = GOTSHOTGUN2;
			sound = sfx_wpnup;	
			break;
				
#ifdef CHECK_FOR_ERRORS
		default:
			I_Error ("P_SpecialThing: Unknown gettable thing");
#endif
    }
	
    if (specialflagscountitem){
		player.itemcount++;
	}
    P_RemoveMobj (special);
    player.bonuscount += BONUSADD;
	S_StartSound (NULL, sound);
}


//
// KillMobj
//
void __near P_KillMobj (	mobj_t __near* source, mobj_t __near*	target, mobj_pos_t __far*	target_pos) {
    mobjtype_t	item;
	//todoaddr inline later
	int16_t (__far  * getSpawnHealth)(uint8_t) = getSpawnHealthAddr;
	statenum_t (__far  * getXDeathState)(uint8_t) = getXDeathStateAddr;
	statenum_t (__far  * getDeathState)(uint8_t) = getDeathStateAddr;

	
	target_pos->flags1 &= ~(MF_SHOOTABLE|MF_FLOAT);
	target_pos->flags2 &= ~(MF_SKULLFLY);

    if (target->type != MT_SKULL){
		target_pos->flags1 &= ~MF_NOGRAVITY;
	}

	target_pos->flags1 |= MF_DROPOFF;
	target_pos->flags2 |= MF_CORPSE;
    target->height.w >>= 2;

    if (source) {
		if (source->type == MT_PLAYER) {
			// count for intermission
			if (target_pos->flags2 & MF_COUNTKILL){
				player.killcount++;
			}

			 
		}
    } else if (target_pos->flags2 & MF_COUNTKILL) {
		// count all monster deaths,
		// even those caused by other monsters
		player.killcount++;
    }

	// todo what else doesnt leave a corpse...?
    if (target->type == MT_SKULL || target->type == MT_PAIN) {
		THINKERREF targetref = GETTHINKERREF(target);
		if (targetref == player.attackerRef){
			useDeadAttackerRef = true;
			deadAttackerX = target_pos->x;
			deadAttackerY = target_pos->y;
		}
	}

    if (target->type == MT_PLAYER) {
			
		target_pos->flags1 &= ~MF_SOLID;
		player.playerstate = PST_DEAD;
		P_DropWeaponFar ();

		if (automapactive) {
			// don't die in auto map,
			// switch view prior to dying
			AM_Stop ();
		}
	
    }

    if (target->health < (-getSpawnHealth(target->type))  && getXDeathState(target->type)) {
		P_SetMobjState (target, getXDeathState(target->type)) ;
    } else {
		P_SetMobjState (target, getDeathState(target->type));
	}
	//target = setStateReturn;

    target->tics -= P_Random()&3;

    if (target->tics < 1 || target->tics > 240){
		target->tics = 1;
	}
		


    // Drop stuff.
    // This determines the kind of object spawned
    // during the death frame of a thing.
    switch (target->type) {
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

    P_SpawnMobj (target_pos->x.w, target_pos->y.w,ONFLOORZ, item, target->secnum);
	//mo = setStateReturn;
	setStateReturn_pos->flags2 |= MF_DROPPED;	// special versions of items
}


fixed_t __near getMassThrust(int16_t damage, int8_t id){
	
			//return (damage*(FRACUNIT >> 3) * 100L) / mass.h.fracbits;
			// or   damage * 0xC8000  / mass
	switch (id){
		case MT_SKULL:
				
				return FastMul16u16u(damage, 0x4000);
			case MT_SERGEANT:
			case MT_SHADOWS:
			case MT_HEAD:
			case MT_PAIN:
				return FastMul16u16u(damage, 0x800);

			case MT_VILE:
			case MT_UNDEAD:
				// these arent clean multiplies. dont think it is safe to round and do one operation..
				return FastDiv32u16u(FastMul16u32u(damage, 0xc8000), 500);
			case MT_BABY:
				return FastDiv32u16u(FastMul16u32u(damage, 0xc8000), 600);
			case MT_FATSO:
			case MT_BRUISER:
			case MT_KNIGHT:
			case MT_SPIDER:
			case MT_CYBORG:
				return FastDiv32u16u(FastMul16u32u(damage, 0xc8000), 1000);

			case MT_KEEN:
			case MT_BOSSBRAIN:

				return damage / 80;


			default:

				return FastMul16u16u(damage, 0x2000);
	}
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
void __far P_DamageMobj (mobj_t __near*	target, mobj_t __near*	inflictor, mobj_t __near*	source, int16_t 		damage ) {
	angle_t	ang;
    int16_t		saved;
    fixed_t	thrust;
 	fixed_t_union inflictorx;
	fixed_t_union inflictory;
	fixed_t_union inflictorz;
	mobj_pos_t __far* target_pos = GET_MOBJPOS_FROM_MOBJ(target);
 	
	//todoaddr inline later
	int16_t (__far  * getPainChance)(uint8_t) = getPainChanceAddr;
 	statenum_t (__far  * getPainState)(uint8_t) = getPainStateAddr;
	statenum_t (__far  * getSeeState)(uint8_t) = getSeeStateAddr;



	if (!(target_pos->flags1 & MF_SHOOTABLE)) {
		return;	// shouldn't happen...
	}
		
	if (target->health <= 0) {
		return;
	}
    if (target_pos->flags2 & MF_SKULLFLY ) {
		target->momx.w = target->momy.w = target->momz.w = 0;
    }
	
    
	if (target->type == MT_PLAYER && gameskill == sk_baby) {
		damage >>= 1; 	// take half damage in trainer mode
	}

    // Some close combat weapons should not
    // inflict thrust and push the victim out of reach,
    // thus kick away unless using the chainsaw.

	if ((inflictor && !(target_pos->flags1 & MF_NOCLIP))  && 
		((!source || source->type == MT_PLAYER || player.readyweapon != wp_chainsaw))) {
		mobj_pos_t __far* inflictor_pos = GET_MOBJPOS_FROM_MOBJ(inflictor);
		inflictorx = inflictor_pos->x;
		inflictory = inflictor_pos->y;
		inflictorz = inflictor_pos->z;

		ang.wu = R_PointToAngle2(inflictorx,
			inflictory,
			target_pos->x,
			target_pos->y);

		//thrust = FixedDiv(damage*(FRACUNIT >> 3) * 100, getMobjMass(target->type));
		
		// todo hard code this based on the finite mass values

		thrust = getMassThrust(damage, target->type);

		// make fall forwards sometimes
		if (damage < 40
			&& damage > target->health
			&& (target_pos->z.w - inflictorz.w) > 64 * FRACUNIT
			&& (P_Random() & 1)) {
				ang.wu += ANG180;
				thrust *= 4;
		}

		ang.hu.intbits = (ang.hu.intbits >> 1) & 0xFFFC;
		target->momx.w += FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, ang.hu.intbits, thrust);
		target->momy.w += FixedMulTrigNoShift(FINE_SINE_ARGUMENT, ang.hu.intbits, thrust);
		
	}
    // player specific
    if (target->type == MT_PLAYER) {

		// end of game hell hack
		if (sectors_physics[target->secnum].special == 11 && damage >= target->health) {
			damage = target->health - 1;
		}

		// Below certain threshold,
		// ignore damage in GOD mode, or with INVUL power.
		if ( damage < 1000 && ( (player.cheats & CF_GODMODE) || player.powers[pw_invulnerability] ) ) {
			return;
		}
	
		if (player.armortype) {
			if (player.armortype == 1) {
				saved = damage/3;
			} else {
				saved = damage>>1;
			}
			if (player.armorpoints <= saved) {
				// armor is used up
				saved = player.armorpoints;
				player.armortype = 0;
			}
			player.armorpoints -= saved;
			damage -= saved;
		}

 


		player.health -= damage; 	// mirror mobj health here for Dave
		if (player.health < 0) {
			player.health = 0;			
		}

	 
	
		player.attackerRef = GETTHINKERREF(source);
		if (source->health > 0){
			useDeadAttackerRef = false;
		} else {
			if (!useDeadAttackerRef){
				mobj_pos_t __far* source_pos = GET_MOBJPOS_FROM_MOBJ(source);
				useDeadAttackerRef = true;
				deadAttackerX = source_pos->x;
				deadAttackerY = source_pos->y;
			}
		}

		player.damagecount += damage;	// add damage after armor / invuln

		if (player.damagecount > 100) {
			player.damagecount = 100;	// teleport stomp does 10k points...
		}


 

	}
    


    // do the damage	
    target->health -= damage;	
    if (target->health <= 0) {
		P_KillMobj (source, target, target_pos);
		return;
    }

    if ( (P_Random () < getPainChance(target->type)) && !(target_pos->flags2&MF_SKULLFLY) ) {
		target_pos->flags1 |= MF_JUSTHIT;	// fight back!
		P_SetMobjState (target, getPainState(target->type));
		//target = setStateReturn;
	}
			

    target->reactiontime = 0;		// we're awake now...	

	if ( (!target->threshold || target->type == MT_VILE) && source && source != target && source->type != MT_VILE) {
		// if not intent on another player,
		// chase after this one
		target->targetRef = GETTHINKERREF(source);
		target->threshold = BASETHRESHOLD;
		if (target_pos->stateNum == mobjinfo[target->type].spawnstate && getSeeState(target->type) != S_NULL){
			P_SetMobjState (target, getSeeState(target->type));
		}
    }
	 


}

