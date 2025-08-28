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
//

#ifndef __D_PLAYER__
#define __D_PLAYER__


// The player data structure depends on a number
// of other structs: items (internal inventory),
// animation states (closely tied to the sprites
// used to represent them, unfortunately).
#include "p_pspr.h"

// In addition, the player is just a special
// case of the generic moving object/actor.
#include "p_mobj.h"

// Finally, for odd reasons, the player input
// is buffered within the player data struct,
// as commands per game tick.
#include "d_ticcmd.h"




//
// Player states.
//
    // Playing or camping.
	#define PST_LIVE 0
    // Dead on the ground, view follows killer.
	#define PST_DEAD 1
    // Ready to restart/respawn???
	#define PST_REBORN	2

typedef uint8_t playerstate_t;


//
// Player internal flags, for cheats and debug.
//


// No clipping, walk through barriers.
#define CF_NOCLIP		 1
// No damage, no health loss.
#define CF_GODMODE		 2
// Not really a cheat, just a debug aid.
#define CF_NOMOMENTUM	 4
typedef int8_t cheat_t;

//
// Extended player object info: player_t
//


typedef struct player_s{

    ticcmd_t		cmd;  // 8 bytes

    // Determine POV,
    //  including viewpoint bobbing during movement.
    // Focal origin above r.z
    fixed_t_union		viewzvalue;             // 08
    // Base height above floor for viewz.
	fixed_t_union		viewheightvalue;        // 0C
    // Bob/squat speed.
	fixed_t_union     deltaviewheight;          // 10
    // bounded/scaled total momentum.
	fixed_t_union     bob;                      // 14
    // This is only used between levels,
    // mo->health is used during levels.
    int16_t		health;	                        // 18

    int16_t		armorpoints;                    // 1A
    // Armor type is 0-2.
    int8_t			armortype;	                // 1C
    playerstate_t	playerstate;                // 1D

    // Power ups. invinc and invis are tic counters.
    int16_t		powers[NUMPOWERS];              // 1E
    boolean		cards[NUMCARDS];
    
    weapontype_t	readyweapon;
    
    // Is wp_nochange if not changing.
    weapontype_t	pendingweapon;

    boolean			weaponowned[NUMWEAPONS];
    // Bit flags, for cheats and debug.
    // See cheat_t, above.
    int8_t			cheats;		



    int16_t			ammo[NUMAMMO];
    int16_t			maxammo[NUMAMMO];


    // True if button down last tic.
    int8_t			attackdown;
    int8_t			usedown;

    

     // For intermission stats.
    int16_t			killcount;
    int16_t			itemcount;
    int16_t			secretcount;

    // Hint messages.
    int16_t		message;
	//int8_t		messagestring[40];
	int8_t*		messagestring;  // note unused now. 

    // For screen flashing (red or bright).
    int16_t			damagecount;
    int8_t			bonuscount;
    // Refired shots are less accurate.
    int8_t			refire;		


    // Who did damage (NULL for floors/ceilings).
    THINKERREF		attackerRef;
    
    // So gun flashes light up areas.
    int8_t			extralightvalue;

    // Current PLAYPAL, ???
    //  can be set to REDCOLORMAP for pain, etc.
    uint8_t			fixedcolormapvalue;

    // Player skin colorshift,
    //  0-3 for which color to draw player.
    int8_t			colormap;	
    // True if secret level has been done.
    boolean		didsecret;	

    // Overlay view sprites (gun, etc).
    boolean		backpack;


} player_t;


//
// INTERMISSION
// Structure passed e.g. to WI_Start(wb)
//
typedef struct{

    boolean	in;	// whether the player is in game
    
    // Player stats, kills, collected items etc.
    int16_t		skills;
    int16_t		sitems;
    int16_t		ssecret;
    int16_t		stime; 
  
} wbplayerstruct_t;

typedef struct{

    int8_t		epsd;	// episode # (0-2)

    // if true, splash the secret level
    boolean	didsecret;
    
    // previous and next levels, origin 0
    int8_t		last;
    int8_t		next;	
    
    int16_t		maxkills;
    int16_t		maxitems;
    int16_t		maxsecret;

    // the par time
    int16_t		partime;
    
    // index of this player in game
    //int16_t		pnum;	

	wbplayerstruct_t	plyr;

} wbstartstruct_t;


#endif
