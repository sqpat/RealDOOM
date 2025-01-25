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
//	Savegame I/O, archiving, persistence.
//


#ifndef __P_SAVEG__
#define __P_SAVEG__


// Persistent storage/archiving.
// These are the load / save game routines.
// void __far P_ArchivePlayers (void);
// void __far P_ArchiveWorld (void);
// void __far P_ArchiveThinkers (void);
// void __far P_ArchiveSpecials (void);

//void __far P_UnArchivePlayers (void);
//void __far P_UnArchiveWorld (void);
//void __far P_UnArchiveThinkers (void);
//void __far P_UnArchiveSpecials (void);




typedef struct
{
    int32_t		state;	// ptr instead of int16_t
    int32_t		tics;   // instead of int16_t
    fixed_t	sx;
    fixed_t	sy;

} pspdef_vanilla_t;


#define MAXPLAYERS_VANILLA 4

typedef struct 
{
    int32_t				mo;
    int32_t 			playerstate;
    ticcmd_t			cmd;				// same byte structure as vanilla
    fixed_t				viewzvalue;
    fixed_t				viewheightvalue;
    fixed_t         	deltaviewheight;
    fixed_t         	bob;	
    int32_t				health;	
    int32_t				armorpoints;
    int32_t				armortype;	
    int32_t				powers[NUMPOWERS];
    int32_t				cards[NUMCARDS];
    int32_t				backpack;
    int32_t				frags[MAXPLAYERS_VANILLA];
    int32_t				readyweapon;
    int32_t				pendingweapon;
    int32_t				weaponowned[NUMWEAPONS];
    int32_t				ammo[NUMAMMO];
    int32_t				maxammo[NUMAMMO];
    int32_t				attackdown;
    int32_t				usedown;
    int32_t				cheats;		
    int32_t				refire;		
    int32_t				killcount;
    int32_t				itemcount;
    int32_t				secretcount;
    int32_t				message;	
    int32_t				damagecount;
    int32_t				bonuscount;
    int32_t				attacker;
    int32_t				extralightvalue;
    int32_t				fixedcolormapvalue;
    int32_t				colormap;	
    pspdef_vanilla_t	psprites_field[NUMPSPRITES];
    int32_t				didsecret;	

} player_vanilla_t;


typedef struct thinker_vanilla_s
{
    int32_t	prev;
	int32_t	next;
    int32_t	function;
    
} thinker_vanilla_t;


// Map Object definition.
typedef struct  {

    thinker_vanilla_t	thinker;
    fixed_t				x;
    fixed_t				y;
    fixed_t				z;
    int32_t				snext;
    int32_t				sprev;
    angle_t				angle;	// orientation
    int32_t				sprite;	// used to find patch_t and flip value
    int32_t				frame;	// might be ORed with FF_FULLBRIGHT
    int32_t				bnext;
    int32_t				bprev;
    int32_t				subsector;
    fixed_t				floorz;
    fixed_t				ceilingz;
    fixed_t				radius;
    fixed_t				height;	
    fixed_t				momx;
    fixed_t				momy;
    fixed_t				momz;
    int32_t				validcount;
    int32_t				type;
    int32_t				info;	// &mobjinfo[mobj->type]
    int32_t				tics;	// state tic counter
    int32_t				state;
    int32_t				flags;
    int32_t				health;
    int32_t				movedir;	// 0-7
    int32_t				movecount;	// when 0, select a new dir
    int32_t				target;
    int32_t				reactiontime;   
    int32_t				threshold;
    int32_t				player;
    int32_t				lastlook;	
    mapthing_t			spawnpoint;	
    int32_t				tracer;	
    
} mobj_vanilla_t;



typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				type;
    int32_t				sector;
    fixed_t				bottomheight;
    fixed_t				topheight;
    fixed_t				speed;
    int32_t				crush;
    int32_t				direction;
    int32_t				tag;                   
    int32_t				olddirection;
    
} ceiling_vanilla_t;

typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				type;
    int32_t				sector;
    fixed_t				topheight;
    fixed_t				speed;
    int32_t             direction;
    int32_t             topwait;
    int32_t             topcountdown;
    
} vldoor_vanilla_t;

typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				type;
    int32_t				crush;
    int32_t				sector;
    int32_t				direction;
    int32_t				newspecial;
    int16_t				texture;
    fixed_t				floordestheight;
    fixed_t				speed;

} floormove_vanilla_t;

typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    fixed_t				speed;
    fixed_t				low;
    fixed_t				high;
    int32_t				wait;
    int32_t				count;
    int32_t				status;
    int32_t				oldstatus;
    int32_t				crush;
    int32_t				tag;
    int32_t				type;
    
} plat_vanilla_t;



typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    int32_t				count;
    int32_t				maxlight;
    int32_t				minlight;
    int32_t				maxtime;
    int32_t				mintime;
    
} lightflash_vanilla_t;



typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    int32_t				count;
    int32_t				minlight;
    int32_t				maxlight;
    int32_t				darktime;
    int32_t				brighttime;
    
} strobe_vanilla_t;




typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    int32_t				minlight;
    int32_t				maxlight;
    int32_t				direction;

} glow_vanilla_t;



#endif
