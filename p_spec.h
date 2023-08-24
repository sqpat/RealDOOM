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
extern	int32_t	levelTimeCount;


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
	int16_t linenum,
  int32_t		side );

void
P_ShootSpecialLine
(MEMREF thingRef,
  int16_t linenum);

void
P_CrossSpecialLine
( int32_t		linenum,
  int32_t		side,
	MEMREF thingRef);

void    P_PlayerInSpecialSector (player_t* player);

int16_t
twoSided
(int16_t		sector,
	int16_t		line );

int16_t
getSector
(int16_t		currentSector,
	int16_t		line,
	int16_t		side );

int16_t
getSideNum
(int16_t		currentSector,
	int16_t		line,
	int16_t		side );

fixed_t P_FindLowestFloorSurrounding(int16_t secnum);
fixed_t P_FindHighestFloorSurrounding(int16_t secnum);

fixed_t
P_FindNextHighestFloor
(int16_t secnum,
  int32_t		currentheight );

fixed_t P_FindLowestCeilingSurrounding(int16_t secnum);
fixed_t P_FindHighestCeilingSurrounding(int16_t secnum);

int32_t
P_FindSectorFromLineTag
( int16_t		linetag,
  int32_t		start );

int32_t
P_FindMinSurroundingLight
( int16_t secnum,
  int32_t		max );

int16_t
getNextSector
( int16_t linenum,
  int16_t	sec );


//
// SPECIAL
//
int32_t EV_DoDonut(int16_t linetag);



//
// P_LIGHTS
//
typedef struct
{
    THINKERREF	thinkerRef;
	int16_t secnum;
    int32_t		count;
    int32_t		maxlight;
    int32_t		minlight;
    
} fireflicker_t;



typedef struct
{
	THINKERREF	thinkerRef;
	int16_t secnum;
    int32_t		count;
    int32_t		maxlight;
    int32_t		minlight;
    int32_t		maxtime;
    int32_t		mintime;
    
} lightflash_t;



typedef struct
{
	THINKERREF	thinkerRef;
	int16_t secnum;
    int32_t		count;
    int32_t		minlight;
    int32_t		maxlight;
    int32_t		darktime;
    int32_t		brighttime;
    
} strobe_t;




typedef struct
{
	THINKERREF	thinkerRef;
	int16_t secnum;
    int32_t		minlight;
    int32_t		maxlight;
    int32_t		direction;

} glow_t;


#define GLOWSPEED			8
#define STROBEBRIGHT		5
#define FASTDARK			15
#define SLOWDARK			35

void    P_SpawnFireFlicker (int16_t secnum);
void    T_LightFlash (MEMREF memref);
void    P_SpawnLightFlash (int16_t secnum);
void    T_StrobeFlash (MEMREF memref);

void
P_SpawnStrobeFlash
(int16_t secnum,
  int32_t		fastOrSlow,
  int32_t		inSync );

void    EV_StartLightStrobing(int16_t linetag);
void    EV_TurnTagLightsOff(int16_t linetag);

void
EV_LightTurnOn
( int16_t linetag,
  int32_t		bright );

void    T_Glow(MEMREF memref);
void    P_SpawnGlowingLight(int16_t secnum);


void T_FireFlicker(MEMREF memref);


//
// P_SWITCH
//
typedef struct
{
    int8_t	name1[9];
	int8_t	name2[9];
    int16_t	episode;
    
} switchlist_t;


typedef enum
{
    top,
    middle,
    bottom

} bwhere_e;


typedef struct
{
	int16_t linenum;
    bwhere_e	where;
    int32_t		btexture;
    int32_t		btimer;
	int32_t soundorgX;
	int32_t soundorgY;

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
(int16_t linenum, int16_t lineside0, int16_t linespecial, int16_t linefrontsecnum, int32_t useAgain);

void P_InitSwitchList(void);


//
// P_PLATS
//
#define plat_up 0
#define plat_down 1
#define plat_waiting 2
#define plat_in_stasis 3

typedef uint8_t plat_e;



#define perpetualRaise 0
#define downWaitUpStay 1
#define raiseAndChange 2
#define raiseToNearestAndChange 3
#define blazeDWUS 4

typedef uint8_t plattype_e;



typedef struct
{
	THINKERREF	thinkerRef;
	int16_t secnum;
    fixed_t	speed;
    fixed_t	low;
    fixed_t	high;
    int32_t		wait;
    int32_t		count;
    plat_e	status;
    plat_e	oldstatus;
    boolean	crush;
    int32_t		tag;
    plattype_e	type;
    
} plat_t;



#define PLATWAIT		3
#define PLATSPEED		FRACUNIT
#define MAXPLATS		30


extern MEMREF	activeplats[MAXPLATS];

void    T_PlatRaise(MEMREF platRef);

int32_t
EV_DoPlat
( int16_t linenum,
	int16_t linetag,
  plattype_e	type,
  int32_t		amount );

void    P_AddActivePlat(MEMREF memref);
void    P_RemoveActivePlat(MEMREF memref);
void    EV_StopPlat(int16_t linetag);
void    P_ActivateInStasis(int32_t tag);


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
    int16_t	secnum;
    fixed_t	topheight;
    fixed_t	speed;

    // 1 = up, 0 = waiting at top, -1 = down
	int32_t             direction;
    
    // tics to wait at the top
	int32_t             topwait;
    // (keep in case a door going down is reset)
    // when it reaches 0, start going down
	int32_t             topcountdown;
    
} vldoor_t;



#define VDOORSPEED		FRACUNIT*2
#define VDOORWAIT		150

void
EV_VerticalDoor
( int16_t linenum,
  MEMREF	thingRef );

int32_t
EV_DoDoor
( int16_t linetag,
  vldoor_e	type );

int32_t
EV_DoLockedDoor
(int16_t linetag, int16_t linepsecial,
  vldoor_e	type,
	MEMREF thingRef);

void    T_VerticalDoor (MEMREF memref);
void    P_SpawnDoorCloseIn30 (int16_t secnum);

void
P_SpawnDoorRaiseIn5Mins
( int16_t		secnum );

 

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
	int16_t secnum;
    fixed_t	bottomheight;
    fixed_t	topheight;
    fixed_t	speed;
    boolean	crush;

    // 1 = up, 0 = waiting, -1 = down
    int32_t		direction;

    // ID
    int32_t		tag;                   
    int32_t		olddirection;
    
} ceiling_t;





#define CEILSPEED		FRACUNIT
#define CEILWAIT		150
#define MAXCEILINGS		30

extern MEMREF	activeceilings[MAXCEILINGS];

int32_t
EV_DoCeiling
( int16_t linetag,
  ceiling_e	type );

void    T_MoveCeiling (MEMREF memref);
void    P_AddActiveCeiling(MEMREF memref);
void    P_RemoveActiveCeiling(MEMREF memref);
int32_t	EV_CeilingCrushStop(int16_t linetag);
void    P_ActivateInStasisCeiling(int16_t linetag);


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
    
typedef uint8_t  floor_e;




#define build8 0	// slowly build by 8
#define turbo16	1 // quickly build by 16

typedef uint8_t  stair_e;



typedef struct
{
    THINKERREF	thinkerRef;
    floor_e	type;
    boolean	crush;
    int16_t   secnum;
    int32_t		direction;
    int32_t		newspecial;
    int16_t	texture;
    fixed_t	floordestheight;
    fixed_t	speed;

} floormove_t;



#define FLOORSPEED		FRACUNIT

#define floor_ok 0
#define floor_crushed 1
#define floor_pastdest 2
    
typedef uint8_t result_e;



result_e
T_MovePlane
( int16_t secnum,
  fixed_t	speed,
  fixed_t	dest,
  boolean	crush,
  int32_t		floorOrCeiling,
  int32_t		direction );

int32_t
EV_BuildStairs
( int16_t linetag,
  stair_e	type );

int32_t
EV_DoFloor
( int16_t linetag,   int16_t linefrontsecnum, floor_e	floortype );

void T_MoveFloor(MEMREF memref);

//
// P_TELEPT
//
int32_t
EV_Teleport
( int16_t linetag,
  int32_t		side,
	MEMREF thingRef);

#endif
