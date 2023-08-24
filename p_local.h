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
#define MELEERANGE		(64*FRACUNIT)
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
void P_SetupPsprites (player_t* curplayer);
void P_MovePsprites (player_t* curplayer);
void P_DropWeapon (player_t* player);


//
// P_USER
//
void	P_PlayerThink (player_t* player);


//
// P_MOBJ
//
#define ONFLOORZ		MININT
#define ONCEILINGZ		MAXINT

// Time interval for item respawning.
#define ITEMQUESIZE		128


extern mapthing_t	itemrespawnque[ITEMQUESIZE];
extern int		itemrespawntime[ITEMQUESIZE];
extern int		iquehead;
extern int		iquetail;


void P_RespawnSpecials (void);

MEMREF
P_SpawnMobj
( fixed_t	x,
  fixed_t	y,
  fixed_t	z,
  mobjtype_t	type );

void 	P_RemoveMobj (MEMREF th);
boolean	P_SetMobjState2 (MEMREF mobj, statenum_t state, char*file, int line);
void 	P_MobjThinker (MEMREF memref);

void	P_SpawnPuff (fixed_t x, fixed_t y, fixed_t z);
void 	P_SpawnBlood (fixed_t x, fixed_t y, fixed_t z, int damage);
MEMREF P_SpawnMissile (MEMREF source, MEMREF dest, mobjtype_t type);
void	P_SpawnPlayerMissile (MEMREF source, mobjtype_t type);




//
// P_ENEMY
//
void P_NoiseAlert (MEMREF target, MEMREF emmiter);


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
	short linenum;
    }			d;
} intercept_t;

#define MAXINTERCEPTS	128

extern intercept_t	intercepts[MAXINTERCEPTS];
extern intercept_t*	intercept_p;

typedef boolean (*traverser_t) (intercept_t *in);

fixed_t P_AproxDistance (fixed_t dx, fixed_t dy);
int 	P_PointOnLineSide (fixed_t	x, fixed_t	y, fixed_t linedx, fixed_t linedy, short linev1Offset);
int 	P_PointOnDivlineSide (fixed_t x, fixed_t y, divline_t* line);
void 	P_MakeDivline (fixed_t linedx, fixed_t linedy, short linenum, divline_t* dl);
fixed_t P_InterceptVector (divline_t* v2, divline_t* v1);
int 	P_BoxOnLineSide (fixed_t* tmbox, slopetype_t	lineslopetype, fixed_t linedx, fixed_t linedy, short linev1Offset);


extern fixed_t		opentop;
extern fixed_t 		openbottom;
extern fixed_t		openrange;
extern fixed_t		lowfloor;

void 	P_LineOpening (short lineside1, short linefrontsecnum, short linebacksecnum);

boolean P_BlockLinesIterator (int x, int y, boolean(*func)(line_t*, short ) );
boolean P_BlockThingsIterator (int x, int y, boolean(*func)(MEMREF));

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
  int		flags,
  boolean	(*trav) (intercept_t *));

void P_UnsetThingPosition (MEMREF thing);
void P_SetThingPosition (MEMREF thing);


//
// P_MAP
//

// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".
extern boolean		floatok;
extern fixed_t		tmfloorz;
extern fixed_t		tmceilingz;


extern	line_t*		ceilingline;

boolean P_CheckPosition (MEMREF thing, fixed_t x, fixed_t y);
boolean P_TryMove (MEMREF thing, fixed_t x, fixed_t y);
boolean P_TeleportMove (MEMREF thing, fixed_t x, fixed_t y);
void	P_SlideMove (MEMREF mo);
boolean P_CheckSight (MEMREF t1, MEMREF t2);
void 	P_UseLines (player_t* player);

boolean P_ChangeSector (short secnum, boolean crunch);

extern MEMREF	linetargetRef;	// who got hit (or NULL)

fixed_t
P_AimLineAttack
(MEMREF	t1,
  angle_t	angle,
  fixed_t	distance );

void
P_LineAttack
(MEMREF	t1,
  angle_t	angle,
  fixed_t	distance,
  fixed_t	slope,
  int		damage );

void
P_RadiusAttack
(MEMREF	spot,
	MEMREF	source,
  int		damage );



//
// P_SETUP
//
extern byte*		rejectmatrix;	// for fast sight rejection
extern short*		blockmaplump;	// offsets in blockmap are from here
extern short*		blockmap;
extern int		bmapwidth;
extern int		bmapheight;	// in mapblocks
extern fixed_t		bmaporgx;
extern fixed_t		bmaporgy;	// origin of block map



//
// P_INTER
//
extern int		maxammo[NUMAMMO];
extern int		clipammo[NUMAMMO];

void
P_TouchSpecialThing
(MEMREF	special,
	MEMREF	toucher );

void
P_DamageMobj
(MEMREF	target,
	MEMREF	inflictor,
	MEMREF	source,
  int		damage );


//
// P_SPEC
//
#include "p_spec.h"

#define P_SetMobjState(a,b) P_SetMobjState2(a,b, __FILE__, __LINE__)


#endif	// __P_LOCAL__
