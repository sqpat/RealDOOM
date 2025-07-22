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
//	Play functions, animation, global header.
//


#ifndef __P_LOCAL__
#define __P_LOCAL__

#ifndef __R_LOCAL__
#include "r_local.h"
#endif

#define FLOATSPEED		(FRACUNIT*4)
#define FLOATSPEED_HIGHBITS	4


#define MAXHEALTH		100
#define VIEWHEIGHT		(41*FRACUNIT)
#define VIEWHEIGHT_HIGHBITS	41

// mapblocks are used to check movement
// against lines and things
#define MAPBLOCKUNITS	128
#define MAPBLOCKSIZE MAPBLOCKUNITS
#define MAPBLOCKSHIFT	7


// player radius for movement checking
#define PLAYERRADIUS	16*FRACUNIT

// MAXRADIUS is for precalculated sector block boxes
// the spider demon is larger,
// but we do not have any moving sectors nearby
#define MAXRADIUS		32*FRACUNIT
#define MAXRADIUSNONFRAC		32

#define GRAVITY		FRACUNIT
#define GRAVITY_HIGHBITS		1
#define MAXMOVE		(30*FRACUNIT)

#define USERANGE         (64)
#define MELEERANGE       (64)
#define CHAINSAWRANGE	 (65)
#define MISSILERANGE     (32*64)
#define HALFMISSILERANGE (16*64)

// follow a player exlusively for 3 seconds
#define	BASETHRESHOLD	 	100



//
// P_TICK
//



#define TF_NULL				0
#define TF_MOBJTHINKER		1
#define TF_PLATRAISE        2
#define TF_MOVECEILING		3
#define TF_VERTICALDOOR		4
#define TF_MOVEFLOOR        5
#define TF_FIREFLICKER      6
#define TF_LIGHTFLASH       7
#define TF_STROBEFLASH      8
#define TF_GLOW             9

#define TF_DELETEME         10

#define TF_NULL_HIGHBITS			0
#define TF_MOBJTHINKER_HIGHBITS		2048u
#define TF_PLATRAISE_HIGHBITS       4096u
#define TF_MOVECEILING_HIGHBITS		6144u
#define TF_VERTICALDOOR_HIGHBITS	8192u
#define TF_MOVEFLOOR_HIGHBITS       10240u
#define TF_FIREFLICKER_HIGHBITS     12288u
#define TF_LIGHTFLASH_HIGHBITS      14336u
#define TF_STROBEFLASH_HIGHBITS     16384u
#define TF_GLOW_HIGHBITS            18432u
#define TF_DELETEME_HIGHBITS		20480u

#define TF_FUNCBITS					0xF800u
#define TF_PREVBITS					0x07FFu

// 44 in size
typedef struct thinker_s {

	// functiontype is the five high bits

	// contains previous reference mixed with functin type (in the high five bits)
	THINKERREF	prevFunctype;
	THINKERREF	next;

	mobj_t			data;

} thinker_t;






void __near* __far P_CreateThinker(uint16_t thinkfunc);

void __near P_UpdateThinkerFunc(THINKERREF thinker, uint16_t argfunc);
void __far  P_RemoveThinker(THINKERREF thinkerRef);

#define THINKER_SIZE sizeof(thinker_t)
#define GETTHINKERREF(a) ((((uint16_t)((byte __near*)a - (byte __near*)thinkerlist))-4)/THINKER_SIZE)
#define GET_MOBJPOS_FROM_MOBJ(a) &mobjposlist_6800[GETTHINKERREF(a)]






//
// P_USER
//
void	__near P_PlayerThink ();


//
// P_MOBJ
//
#define ONFLOORZ		MINLONG
#define ONCEILINGZ		MAXLONG

// Time interval for item respawning.

THINKERREF __far P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type,  int16_t knownsecnum );

void 	__far P_RemoveMobj (mobj_t __near* mobj);

boolean	__far P_SetMobjState(mobj_t __near* mobj, statenum_t state);
void __near P_MobjThinker(mobj_t __near* mobj, mobj_pos_t __far* mobj_pos, THINKERREF mobjRef);

// todo re-enable

#pragma aux P_SpawnPuffParams __parm [dx ax] [cx bx] [di si] __modify [ax bx cx dx si di];
#pragma aux (P_SpawnPuffParams) P_SpawnPuff;
void	__far P_SpawnPuff (fixed_t x, fixed_t y, fixed_t z);





//
// P_ENEMY
//
void __far P_NoiseAlert ();


//
// P_MAPUTL
//
typedef struct {

	fixed_t_union	x;
	fixed_t_union	y;
    fixed_t_union	dx;
	fixed_t_union	dy;
    
} divline_t;

typedef struct {

    fixed_t	frac;		// along trace line
    boolean	isaline;    // todo put this after...
    union {
		THINKERREF	thingRef;
	int16_t linenum;
    }			d;
} intercept_t;

 

#define playerMobj_posMakerExpression	((&mobjposlist_6800[playerMobjRef]))
#define playerMobjMakerExpression		((mobj_t __near *) (((byte __far*)thinkerlist) + (playerMobjRef*sizeof(thinker_t) + 2 * sizeof(THINKERREF))))

typedef boolean __near (*traverser_t ) (intercept_t __far*in);











#define PT_ADDLINES		1
#define PT_ADDTHINGS	2





//
// P_MAP
//

// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".





void __far P_TouchSpecialThing (mobj_t __near*	special,mobj_t __near*	toucher,mobj_pos_t  __far*special_pos,mobj_pos_t  __far*toucher_pos);
void __far P_DamageMobj(mobj_t __near*	target,mobj_t __near*	inflictor,mobj_t __near*	source,int16_t		damage );



//
// P_SPEC
//
#include "p_spec.h"



#endif	// __P_LOCAL__
