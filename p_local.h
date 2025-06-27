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
void __near P_RemoveThinker(THINKERREF thinkerRef);

#define THINKER_SIZE sizeof(thinker_t)
#define GETTHINKERREF(a) ((((uint16_t)((byte __near*)a - (byte __near*)thinkerlist))-4)/THINKER_SIZE)
#define GET_MOBJPOS_FROM_MOBJ(a) &mobjposlist_6800[GETTHINKERREF(a)]



//
// P_PSPR
//
void __near P_DropWeapon ();


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

THINKERREF __near P_SpawnMissile (mobj_t __near* source, mobj_pos_t __far* source_pos, mobj_t __near* dest,  mobjtype_t type);
void	__near P_SpawnPlayerMissile (mobjtype_t type);




//
// P_ENEMY
//
void __near P_NoiseAlert ();


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



#pragma aux P_AproxDistanceParams \
			__modify [ax bx cx dx] \
			__parm [dx ax] [cx bx] \
                    __value [dx ax];

#pragma aux (P_AproxDistanceParams) P_AproxDistance;
fixed_t __far P_AproxDistance (fixed_t dx, fixed_t dy);







void 	__far P_LineOpening(int16_t lineside1, int16_t linefrontsecnum, int16_t linebacksecnum);


boolean __far P_BlockThingsIterator (int16_t x, int16_t y, boolean __near ( *  func )(THINKERREF, mobj_t __near*, mobj_pos_t __far*));

#define PT_ADDLINES		1
#define PT_ADDTHINGS	2



void __far P_UnsetThingPosition (mobj_t __near* thing, uint16_t mobj_pos_offset);
void __far P_SetThingPosition (mobj_t __near* thing, uint16_t mobj_pos_offset, int16_t knownsecnum);


//
// P_MAP
//

// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".

boolean __far P_CheckPosition (mobj_t __near* thing, int16_t oldsecnum, fixed_t_union x, fixed_t_union y);
boolean __far P_TryMove (mobj_t __near* thing, mobj_pos_t __far* thing_pos, fixed_t_union x, fixed_t_union y);
boolean __far P_TeleportMove (mobj_t __near* thing, mobj_pos_t __far* thing_pos, fixed_t_union x, fixed_t_union y, int16_t oldsecnum);
void	__far P_SlideMove ();


void 	__far P_UseLines ();
boolean __far P_ChangeSector (sector_t __far* sector, boolean crunch);



fixed_t __far P_AimLineAttack(mobj_t __near*	t1,fineangle_t	angle,int16_t	distance);
void __far P_LineAttack(mobj_t __near*	t1,fineangle_t	angle,int16_t	distance,fixed_t	slope,int16_t		damage );
void __far P_RadiusAttack (mobj_t __near* spot, uint16_t spot_pos, mobj_t __near* source, int16_t		damage) ;



void __far P_TouchSpecialThing (mobj_t __near*	special,mobj_t __near*	toucher,mobj_pos_t  __far*special_pos,mobj_pos_t  __far*toucher_pos);
void __far P_DamageMobj(mobj_t __near*	target,mobj_t __near*	inflictor,mobj_t __near*	source,int16_t		damage );

int16_t __far R_PointInSubsector ( fixed_t_union	x, fixed_t_union	y );


//
// P_SPEC
//
#include "p_spec.h"



#endif	// __P_LOCAL__
