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
#define FLOATSPEED_NONFRAC		(FRACUNIT)


#define MAXHEALTH		100
#define VIEWHEIGHT		(41*FRACUNIT)

// mapblocks are used to check movement
// against lines and things
#define MAPBLOCKUNITS	128
#define MAPBLOCKSIZE	(MAPBLOCKUNITS*FRACUNIT)
#define MAPBLOCKSHIFT	(FRACBITS+7)
#define MAPBMASK		(MAPBLOCKSIZE-1)
#define MAPBTOFRAC		(MAPBLOCKSHIFT-FRACBITS)


// player radius for movement checking
#define PLAYERRADIUS	16*FRACUNIT

// MAXRADIUS is for precalculated sector block boxes
// the spider demon is larger,
// but we do not have any moving sectors nearby
#define MAXRADIUS		32*FRACUNIT

#define GRAVITY		FRACUNIT
#define MAXMOVE		(30*FRACUNIT)

#define USERANGE		(64*FRACUNIT)
#define MELEERANGE		(64)
#define MISSILERANGE	(32*64*FRACUNIT)

// follow a player exlusively for 3 seconds
#define	BASETHRESHOLD	 	100


#define MAX_THINKERS 1000

//
// P_TICK
//

// both the head and tail of the thinker list
extern	thinker_t	thinkerlist[MAX_THINKERS];	


void P_InitThinkers (void);
THINKERREF P_AddThinker (MEMREF argref, THINKFUNCTION thinkfunc);
void P_UpdateThinkerFunc(THINKERREF thinker, THINKFUNCTION argfunc);
void P_RemoveThinker (THINKERREF thinkerRef);


//
// P_PSPR
//
void P_SetupPsprites ();
void P_MovePsprites ();
void P_DropWeapon ();


//
// P_USER
//
void	P_PlayerThink (mobj_t* playermo);


//
// P_MOBJ
//
#define ONFLOORZ		MINLONG
#define ONCEILINGZ		MAXLONG

// Time interval for item respawning.

MEMREF
P_SpawnMobj
( fixed_t	x,
  fixed_t	y,
  fixed_t	z,
  mobjtype_t	type );

void 	P_RemoveMobj (mobj_t* mobj);
boolean	P_SetMobjState (mobj_t* mobj, statenum_t state);
void 	P_MobjThinker (mobj_t* mobj);

void	P_SpawnPuff (fixed_t x, fixed_t y, fixed_t z);
void 	P_SpawnBlood (fixed_t x, fixed_t y, fixed_t z, int16_t damage);
MEMREF P_SpawnMissile (mobj_t* source, MEMREF dest, mobjtype_t type);
void	P_SpawnPlayerMissile (mobj_t* source, mobjtype_t type);




//
// P_ENEMY
//
void P_NoiseAlert (mobj_t* target, mobj_t* emmiter);


//
// P_MAPUTL
//
typedef struct
{
    fixed_t	x;
    fixed_t	y;
    fixed_t	dx;
    fixed_t	dy;
    
} divline_t;

typedef struct
{
    fixed_t	frac;		// along trace line
    boolean	isaline;
    union {
	MEMREF	thingRef;
	int16_t linenum;
    }			d;
} intercept_t;

#define MAXINTERCEPTS	128

extern intercept_t	intercepts[MAXINTERCEPTS];
extern intercept_t*	intercept_p;

typedef boolean (*traverser_t) (intercept_t *in);

fixed_t P_AproxDistance (fixed_t dx, fixed_t dy);
boolean 	P_PointOnLineSide (fixed_t	x, fixed_t	y, int16_t linedx, int16_t linedy, int16_t linev1Offset);
boolean 	P_PointOnDivlineSide (fixed_t x, fixed_t y, divline_t* line);
void 	P_MakeDivline (int16_t linedx, int16_t linedy, int16_t linenum, divline_t* dl);
fixed_t P_InterceptVector (divline_t* v2, divline_t* v1);
boolean 	P_BoxOnLineSide (fixed_t_union* tmbox, slopetype_t	lineslopetype, int16_t linedx, int16_t linedy, int16_t linev1Offset);


extern short_height_t		opentop;
extern short_height_t 		openbottom;
extern short_height_t		openrange;
extern short_height_t		lowfloor;

void 	P_LineOpening (int16_t lineside1, int16_t linefrontsecnum, int16_t linebacksecnum);

boolean P_BlockLinesIterator (int16_t x, int16_t y, boolean(*func)(int16_t ) );
boolean P_BlockThingsIterator (int16_t x, int16_t y, boolean(*func)(mobj_t*));

#define PT_ADDLINES		1
#define PT_ADDTHINGS	2
#define PT_EARLYOUT		4

extern divline_t	trace;

boolean
P_PathTraverse
( fixed_t	x1,
  fixed_t	y1,
  fixed_t	x2,
  fixed_t	y2,
  uint8_t		flags,
  boolean	(*trav) (intercept_t *));

void P_UnsetThingPosition (mobj_t* thing);
void P_SetThingPosition (mobj_t* thing);


//
// P_MAP
//

// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".
extern boolean		floatok;
extern short_height_t		tmfloorz;
extern short_height_t		tmceilingz;


extern	int16_t		ceilinglinenum;

boolean P_CheckPosition (mobj_t* thing, fixed_t x, fixed_t y);
boolean P_TryMove (mobj_t* thing, fixed_t x, fixed_t y);
boolean P_TeleportMove (mobj_t* thing, fixed_t x, fixed_t y);
void	P_SlideMove (mobj_t* mo);
boolean P_CheckSight (mobj_t* t1, MEMREF t2);


void 	P_UseLines (mobj_t* playermo);

boolean P_ChangeSector (int16_t secnum, boolean crunch);

extern MEMREF	linetargetRef;	// who got hit (or NULL)

fixed_t
P_AimLineAttack
(mobj_t*	t1,
  fineangle_t	angle,
  fixed_t	distance );

void
P_LineAttack
(mobj_t*	t1,
  fineangle_t	angle,
  fixed_t	distance,
  fixed_t	slope,
  int16_t		damage );

void
P_RadiusAttack
(mobj_t*	spot,
	mobj_t*	source,
  int16_t		damage );



//
// P_SETUP
//
extern MEMREF		rejectmatrixRef;	// for fast sight rejection
extern MEMREF          blockmaplumpRef;
extern int16_t		bmapwidth;
extern int16_t		bmapheight;	// in mapblocks
extern fixed_t		bmaporgx;
extern fixed_t		bmaporgy;	// origin of block map



//
// P_INTER
//
extern int16_t		maxammo[NUMAMMO];
extern int8_t		clipammo[NUMAMMO];

void
P_TouchSpecialThing
(mobj_t*	special,
	mobj_t*	toucher );

void
P_DamageMobj
(mobj_t*	target,
	mobj_t*	inflictor,
	MEMREF	source,
  int16_t		damage );


//
// P_SPEC
//
#include "p_spec.h"



#endif	// __P_LOCAL__
