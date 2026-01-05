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


//      Define values for map objects
#define MO_TELEPORTMAN          14

#define MAX_LINE_COUNT			256

// 32 adjoining sectors max!
#define MAX_ADJOINING_SECTORS    32


// at game start


// every tic
void    __near P_UpdateSpecials (void);
// when needed
boolean __far P_UseSpecialLine( mobj_t __near* thing,int16_t linenum,int16_t		side, THINKERREF thingRef );
void __far P_ShootSpecialLine (mobj_t __near* thing, int16_t linenum);
void __far P_CrossSpecialLine ( int16_t		linenum,int16_t		side,mobj_t __near* thing,mobj_pos_t __far* thing_pos);
void __near P_PlayerInSpecialSector ();
int16_t __near twoSided (int16_t		sector, int16_t		line );
short_height_t __near P_FindHighestOrLowestFloorSurrounding(int16_t secnum, int8_t isHigh);
short_height_t __near P_FindNextHighestFloor(int16_t secnum,short_height_t		currentheight );
short_height_t __near P_FindLowestOrHighestCeilingSurrounding(int16_t secnum, int8_t ishigh);
int16_t __near getNextSectorList (int16_t __near* linenums,int16_t	sec,int16_t __near* secnums,int16_t linecount,boolean onlybacksecnum);
void __near P_FindSectorsFromLineTag ( int8_t		linetag,int16_t*		foundsectors, boolean includespecials);
uint8_t __near P_FindMinSurroundingLight( int16_t secnum,uint8_t		max );

 

//
// SPECIAL
//
int16_t __near EV_DoDonut(uint8_t linetag);



//
// P_LIGHTS
//
typedef struct {
	int16_t secnum;
    int16_t		count;
    uint8_t		maxlight;
    uint8_t		minlight;
    
} fireflicker_t;



typedef struct {
	int16_t secnum;
    int16_t		count;
    uint8_t		maxlight;
    uint8_t		minlight;
    int8_t		maxtime;
    int8_t		mintime;
    
} lightflash_t;



typedef struct {
	int16_t secnum;
    int16_t		count;
    uint8_t		minlight;
    uint8_t		maxlight;
    int16_t		darktime;
    int16_t		brighttime;
    
} strobe_t;




typedef struct {
	int16_t secnum;
    uint8_t		minlight;
    uint8_t		maxlight;
    int16_t		direction;

} glow_t;


#define GLOWSPEED			8
#define STROBEBRIGHT		5
#define FASTDARK			15
#define SLOWDARK			35

void __near P_SpawnFireFlicker (int16_t secnum);
void __near T_LightFlash(lightflash_t __near* flash, THINKERREF flashRef);
void __near P_SpawnLightFlash (int16_t secnum);
void __near T_StrobeFlash(strobe_t __near* flash, THINKERREF flashRef);

void __near P_SpawnStrobeFlash (int16_t secnum,int16_t		fastOrSlow,int16_t		inSync );
void __near EV_StartLightStrobing(uint8_t linetag);
void __near EV_LightChange (uint8_t linetag, int8_t on,uint8_t		bright );
void __near T_Glow(glow_t __near* glow, THINKERREF glowRef);
void __near P_SpawnGlowingLight(int16_t secnum);
void __near T_FireFlicker(fireflicker_t __near* flick, THINKERREF flickRef);


//
// P_SWITCH
//
typedef struct {
    int8_t	name1[9];
	int8_t	name2[9];
    int16_t	episode;
    
} switchlist_t;


#define BUTTONTOP 0
#define BUTTONMIDDLE 1
#define BUTTONBOTTOM 2


typedef uint8_t bwhere_e;


typedef struct {
	int16_t     linenum;
    bwhere_e	where;
    uint16_t	btexture;
    int16_t		btimer;
	int16_t     soundorg;  // sectorid

} button_t;




 // max # of wall switches in a level
#define MAXSWITCHES		50

 // 4 players, 4 buttons each at once, max.
#define MAXBUTTONS		4

 // 1 second, in ticks. 
#define BUTTONTIME      35             


void __near P_ChangeSwitchTexture (int16_t linenum, int16_t lineside0, uint8_t linespecial, int16_t linefrontsecnum, int16_t useAgain);

 

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



typedef struct {
	int16_t secnum;
    short_height_t	speed;
    short_height_t	low;
    short_height_t	high;
    int8_t		wait;
    int8_t		count;
    plat_e	status;
    plat_e	oldstatus;
    boolean	crush;
	int8_t		tag;
    plattype_e	type;
    
} plat_t;



#define PLATWAIT		3
// #define PLATSPEED		FRACUNIT
#define PLATSPEED		(1 << SHORTFLOORBITS)
#define MAXPLATS		30



void __near T_PlatRaise(plat_t __near* plat, THINKERREF platRef);

int16_t __near EV_DoPlat (  uint8_t linetag,int16_t linenum,plattype_e	type,int16_t		amount );
void    __near P_AddActivePlat(THINKERREF platref);
void    __near P_RemoveActivePlat(THINKERREF platref);
void    __near EV_PlatFunc(uint8_t linetag, int8_t platfunc);
#define PLAT_FUNC_IN_STASIS 0
#define PLAT_FUNC_STOP_PLAT 1

//
// P_DOORS
//
#define normal 0
#define close30ThenOpen 1
#define close 2
#define open 3
#define raiseIn5Mins 4
#define blazeRaise 5
#define blazeOpen 6
#define blazeClose 7
typedef int8_t vldoor_e;



typedef struct {
    vldoor_e	type;
    int16_t	secnum;
    short_height_t	topheight;
    short_height_t	speed;

    // 1 = up, 0 = waiting at top, -1 = down
	int16_t             direction;
    
    // tics to wait at the top
	int16_t             topwait;
    // (keep in case a door going down is reset)
    // when it reaches 0, start going down
	int16_t             topcountdown;
    
} vldoor_t;



#define VDOORSPEED		(2 << SHORTFLOORBITS)
// #define VDOORSPEED		FRACUNIT*2
#define VDOORWAIT		150

void __near EV_VerticalDoor (int16_t linenum, THINKERREF thingRef );

int16_t __far EV_DoDoor (uint8_t linetag, vldoor_e type );

int16_t __near EV_DoLockedDoor (uint8_t linetag, int16_t linepsecial, vldoor_e type, THINKERREF thingRef);

void __near T_VerticalDoor(vldoor_t __near* door, THINKERREF doorRef);
void __near P_SpawnDoorCloseIn30 (int16_t secnum);

void __near P_SpawnDoorRaiseIn5Mins ( int16_t secnum );

 

//
// P_CEILNG
//
	
#define lowerToFloor 0
#define raiseToHighest 1
#define lowerAndCrush 2
#define crushAndRaise 3
#define fastCrushAndRaise 4
#define silentCrushAndRaise 5
typedef int8_t ceiling_e;



typedef struct {
    ceiling_e	type;
	int16_t secnum;
    short_height_t	bottomheight;
    short_height_t	topheight;
    short_height_t	speed;
    boolean	crush;

    // 1 = up, 0 = waiting, -1 = down
    int8_t		direction;

    // ID
    int8_t		tag;                   
	int8_t		olddirection;
    
} ceiling_t;





// #define CEILSPEED		FRACUNIT
#define CEILSPEED		(1 << SHORTFLOORBITS)
#define CEILWAIT		150
#define MAXCEILINGS		30


int16_t __near EV_DoCeiling (uint8_t linetag, ceiling_e	type );

void __near T_MoveCeiling(ceiling_t __near* ceiling, THINKERREF ceilingRef);
void    __far P_AddActiveCeiling(THINKERREF ceilingRef);
void    __near P_RemoveActiveCeiling(sector_physics_t __near*, THINKERREF ceilingRef);
int16_t	__near EV_CeilingCrushStop(uint8_t linetag);
void    __near P_ActivateInStasisCeiling(uint8_t linetag);


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



typedef struct {
    floor_e	type;
    boolean	crush;
    int16_t   secnum;
    int8_t		direction;
	uint8_t		newspecial;
	uint8_t	texture;
    short_height_t	floordestheight;
    
	// todo could be stored smaller and multiplied to save space but theres only a couple of these in memory at a time. not worth?
	short_height_t	speed;

} floormove_t;



// #define FLOORSPEED		FRACUNIT
#define FLOORSPEED		(1 << SHORTFLOORBITS)

#define floor_ok 0
#define floor_crushed 1
#define floor_pastdest 2
    
typedef uint8_t result_e;



result_e __near T_MovePlaneFloorUp ( uint16_t sector_offset, short_height_t	speed,short_height_t	dest,boolean	crush);
result_e __near T_MovePlaneFloorDown ( uint16_t sector_offset, short_height_t	speed,short_height_t	dest,boolean	crush);
result_e __near T_MovePlaneCeilingUp ( uint16_t sector_offset, short_height_t	speed,short_height_t	dest,boolean	crush);
result_e __near T_MovePlaneCeilingDown ( uint16_t sector_offset, short_height_t	speed,short_height_t	dest,boolean	crush);
int16_t __near EV_BuildStairs (uint8_t linetag, stair_e	type );
int16_t __far EV_DoFloor (uint8_t linetag,   int16_t linefrontsecnum, floor_e	floortype );
void __near T_MoveFloor(floormove_t __near* floor, THINKERREF floorRef);

//
// P_TELEPT
//
int16_t __near EV_Teleport (uint8_t linetag,int16_t		side,mobj_t __near*	thing,mobj_pos_t __far* thing_pos);

#endif
