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
// DESCRIPTION:  none
//	Implements special effects:
//	Texture animation, height or lighting changes
//	 according to adjacent sectors, respective
//	 utility functions, etc.
//


#ifndef __P_SPEC__
#define __P_SPEC__


//
// End-level timer (-TIMER option)
//
extern	boolean levelTimer;
extern	int	levelTimeCount;


//      Define values for map objects
#define MO_TELEPORTMAN          14


// at game start
void    P_InitPicAnims (void);

// at map load
void    P_SpawnSpecials (void);

// every tic
void    P_UpdateSpecials (void);

// when needed
boolean
P_UseSpecialLine
( MEMREF thingRef,
	short linenum,
  int		side );

void
P_ShootSpecialLine
(MEMREF thingRef,
  short linenum);

void
P_CrossSpecialLine
( int		linenum,
  int		side,
	MEMREF thingRef);

void    P_PlayerInSpecialSector (player_t* player);

short
twoSided
(short		sector,
	short		line );

short
getSector
(short		currentSector,
	short		line,
	short		side );

short
getSideNum
(short		currentSector,
	short		line,
	short		side );

fixed_t P_FindLowestFloorSurrounding(short secnum);
fixed_t P_FindHighestFloorSurrounding(short secnum);

fixed_t
P_FindNextHighestFloor
(short secnum,
  int		currentheight );

fixed_t P_FindLowestCeilingSurrounding(short secnum);
fixed_t P_FindHighestCeilingSurrounding(short secnum);

int
P_FindSectorFromLineTag
( short		linetag,
  int		start );

int
P_FindMinSurroundingLight
( short secnum,
  int		max );

short
getNextSector
( short linenum,
  short	sec );


//
// SPECIAL
//
int EV_DoDonut(short linetag);



//
// P_LIGHTS
//
typedef struct
{
    THINKERREF	thinkerRef;
	short secnum;
    int		count;
    int		maxlight;
    int		minlight;
    
} fireflicker_t;



typedef struct
{
	THINKERREF	thinkerRef;
	short secnum;
    int		count;
    int		maxlight;
    int		minlight;
    int		maxtime;
    int		mintime;
    
} lightflash_t;



typedef struct
{
	THINKERREF	thinkerRef;
	short secnum;
    int		count;
    int		minlight;
    int		maxlight;
    int		darktime;
    int		brighttime;
    
} strobe_t;




typedef struct
{
	THINKERREF	thinkerRef;
	short secnum;
    int		minlight;
    int		maxlight;
    int		direction;

} glow_t;


#define GLOWSPEED			8
#define STROBEBRIGHT		5
#define FASTDARK			15
#define SLOWDARK			35

void    P_SpawnFireFlicker (short secnum);
void    T_LightFlash (MEMREF memref);
void    P_SpawnLightFlash (short secnum);
void    T_StrobeFlash (MEMREF memref);

void
P_SpawnStrobeFlash
(short secnum,
  int		fastOrSlow,
  int		inSync );

void    EV_StartLightStrobing(short linetag);
void    EV_TurnTagLightsOff(short linetag);

void
EV_LightTurnOn
( short linetag,
  int		bright );

void    T_Glow(MEMREF memref);
void    P_SpawnGlowingLight(short secnum);


void T_FireFlicker(MEMREF memref);


//
// P_SWITCH
//
typedef struct
{
    char	name1[9];
    char	name2[9];
    short	episode;
    
} switchlist_t;


typedef enum
{
    top,
    middle,
    bottom

} bwhere_e;


typedef struct
{
	short linenum;
    bwhere_e	where;
    int		btexture;
    int		btimer;
	int soundorgX;
	int soundorgY;

} button_t;




 // max # of wall switches in a level
#define MAXSWITCHES		50

 // 4 players, 4 buttons each at once, max.
#define MAXBUTTONS		16

 // 1 second, in ticks. 
#define BUTTONTIME      35             

extern button_t	buttonlist[MAXBUTTONS]; 

void
P_ChangeSwitchTexture
(short linenum, short lineside0, short linespecial, short linefrontsecnum, int useAgain);

void P_InitSwitchList(void);


//
// P_PLATS
//
#define plat_up 0
#define plat_down 1
#define plat_waiting 2
#define plat_in_stasis 3

typedef unsigned char plat_e;



#define perpetualRaise 0
#define downWaitUpStay 1
#define raiseAndChange 2
#define raiseToNearestAndChange 3
#define blazeDWUS 4

typedef unsigned char plattype_e;



typedef struct
{
	THINKERREF	thinkerRef;
	short secnum;
    fixed_t	speed;
    fixed_t	low;
    fixed_t	high;
    int		wait;
    int		count;
    plat_e	status;
    plat_e	oldstatus;
    boolean	crush;
    int		tag;
    plattype_e	type;
    
} plat_t;



#define PLATWAIT		3
#define PLATSPEED		FRACUNIT
#define MAXPLATS		30


extern MEMREF	activeplats[MAXPLATS];

void    T_PlatRaise(MEMREF platRef);

int
EV_DoPlat
( short linenum,
	short linetag,
  plattype_e	type,
  int		amount );

void    P_AddActivePlat(MEMREF memref);
void    P_RemoveActivePlat(MEMREF memref);
void    EV_StopPlat(short linetag);
void    P_ActivateInStasis(int tag);


//
// P_DOORS
//
typedef enum
{
    normal,
    close30ThenOpen,
    close,
    open,
    raiseIn5Mins,
    blazeRaise,
    blazeOpen,
    blazeClose

} vldoor_e;



typedef struct
{
    THINKERREF	thinkerRef;
    vldoor_e	type;
    short	secnum;
    fixed_t	topheight;
    fixed_t	speed;

    // 1 = up, 0 = waiting at top, -1 = down
    int             direction;
    
    // tics to wait at the top
    int             topwait;
    // (keep in case a door going down is reset)
    // when it reaches 0, start going down
    int             topcountdown;
    
} vldoor_t;



#define VDOORSPEED		FRACUNIT*2
#define VDOORWAIT		150

void
EV_VerticalDoor
( short linenum,
  MEMREF	thingRef );

int
EV_DoDoor
( short linetag,
  vldoor_e	type );

int
EV_DoLockedDoor
(short linetag, short linepsecial,
  vldoor_e	type,
	MEMREF thingRef);

void    T_VerticalDoor (MEMREF memref);
void    P_SpawnDoorCloseIn30 (short secnum);

void
P_SpawnDoorRaiseIn5Mins
( short		secnum );

 

//
// P_CEILNG
//
typedef enum
{
    lowerToFloor,
    raiseToHighest,
    lowerAndCrush,
    crushAndRaise,
    fastCrushAndRaise,
    silentCrushAndRaise

} ceiling_e;



typedef struct
{
    THINKERREF	thinkerRef;
    ceiling_e	type;
	short secnum;
    fixed_t	bottomheight;
    fixed_t	topheight;
    fixed_t	speed;
    boolean	crush;

    // 1 = up, 0 = waiting, -1 = down
    int		direction;

    // ID
    int		tag;                   
    int		olddirection;
    
} ceiling_t;





#define CEILSPEED		FRACUNIT
#define CEILWAIT		150
#define MAXCEILINGS		30

extern MEMREF	activeceilings[MAXCEILINGS];

int
EV_DoCeiling
( short linetag,
  ceiling_e	type );

void    T_MoveCeiling (MEMREF memref);
void    P_AddActiveCeiling(MEMREF memref);
void    P_RemoveActiveCeiling(MEMREF memref);
int	EV_CeilingCrushStop(short linetag);
void    P_ActivateInStasisCeiling(short linetag);


//
// P_FLOOR
//
    // lower floor to highest surrounding floor
#define lowerFloor 0
    
    // lower floor to lowest surrounding floor
#define lowerFloorToLowest 1
    
    // lower floor to highest surrounding floor VERY FAST
#define turboLower 2
    
    // raise floor to lowest surrounding CEILING
#define raiseFloor 3
    
    // raise floor to next highest surrounding floor
#define raiseFloorToNearest 4

    // raise floor to shortest height texture around it
#define raiseToTexture 5
    
    // lower floor to lowest surrounding floor
    //  and change floorpic
#define lowerAndChange 6
  
#define raiseFloor24 7
#define raiseFloor24AndChange 8
#define raiseFloorCrush 9

     // raise to next highest floor, turbo-speed
#define raiseFloorTurbo 10
#define donutRaise 11
#define raiseFloor512 12
    
typedef unsigned char  floor_e;




#define build8 0	// slowly build by 8
#define turbo16	1 // quickly build by 16

typedef unsigned char  stair_e;



typedef struct
{
    THINKERREF	thinkerRef;
    floor_e	type;
    boolean	crush;
    short   secnum;
    int		direction;
    int		newspecial;
    short	texture;
    fixed_t	floordestheight;
    fixed_t	speed;

} floormove_t;



#define FLOORSPEED		FRACUNIT

#define floor_ok 0
#define floor_crushed 1
#define floor_pastdest 2
    
typedef unsigned char result_e;



result_e
T_MovePlane
( short secnum,
  fixed_t	speed,
  fixed_t	dest,
  boolean	crush,
  int		floorOrCeiling,
  int		direction );

int
EV_BuildStairs
( short linetag,
  stair_e	type );

int
EV_DoFloor
( short linetag,   short linefrontsecnum, floor_e	floortype );

void T_MoveFloor(MEMREF memref);

//
// P_TELEPT
//
int
EV_Teleport
( short linetag,
  int		side,
	MEMREF thingRef);

#endif
