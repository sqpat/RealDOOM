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
//	Status bar code.
//	Does the face/direction indicator animatin.
//	Does palette indicators as well (red pain/berserk, bright pickup)
//

#ifndef __STSTUFF_H__
#define __STSTUFF_H__

#include "doomtype.h"
#include "d_event.h"

// Size of statusbar.
// Now sensitive for scaling.
#define ST_HEIGHT	32
#define ST_WIDTH	SCREENWIDTH
#define ST_Y		(SCREENHEIGHT - ST_HEIGHT)


//
// STATUS BAR
//

// Called by main loop.
boolean __near ST_Responder (event_t __far* ev);

// Called by main loop.
void ST_Ticker (void);

// Called by main loop.
void ST_Drawer (boolean fullscreen, boolean refresh);


// Called by startup code.
void ST_Init (void);



// States for status bar code.
typedef enum
{
    AutomapState,
    FirstPersonState
    
} st_stateenum_t;


 


//
// STATUS BAR DATA
//


// Palette indices.
// For damage/bonus red-/gold-shifts
#define STARTREDPALS            1
#define STARTBONUSPALS          9
#define NUMREDPALS                      8
#define NUMBONUSPALS            4
// Radiation suit, green shift.
#define RADIATIONPAL            13

// N/256*100% probability
//  that the normal face state will change
#define ST_FACEPROBABILITY              96


// Location of status bar
#define ST_X                            0
#define ST_X2                           104

#define ST_FX                   143
#define ST_FY                   169

// Should be set to patch width
//  for tall numbers later on

// Number of status faces.
#define ST_NUMPAINFACES         5
#define ST_NUMSTRAIGHTFACES     3
#define ST_NUMTURNFACES         2
#define ST_NUMSPECIALFACES              3

#define ST_FACESTRIDE \
          (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)

#define ST_NUMEXTRAFACES                2

#define ST_NUMFACES \
          (ST_FACESTRIDE*ST_NUMPAINFACES+ST_NUMEXTRAFACES)

#define ST_TURNOFFSET           (ST_NUMSTRAIGHTFACES)
#define ST_OUCHOFFSET           (ST_TURNOFFSET + ST_NUMTURNFACES)
#define ST_EVILGRINOFFSET               (ST_OUCHOFFSET + 1)
#define ST_RAMPAGEOFFSET                (ST_EVILGRINOFFSET + 1)
#define ST_GODFACE                      (ST_NUMPAINFACES*ST_FACESTRIDE)
#define ST_DEADFACE                     (ST_GODFACE+1)

#define ST_FACESX                       143
#define ST_FACESY                       168

#define ST_EVILGRINCOUNT                (2*TICRATE)
#define ST_STRAIGHTFACECOUNT    (TICRATE/2)
#define ST_TURNCOUNT            (1*TICRATE)
#define ST_OUCHCOUNT            (1*TICRATE)
#define ST_RAMPAGEDELAY         (2*TICRATE)

#define ST_MUCHPAIN                     20


// Location and size of statistics,
//  justified according to widget type.
// Problem is, within which space? STbar? Screen?
// Note: this could be read in by a lump.
//       Problem is, is the stuff rendered
//       into a buffer,
//       or into the frame buffer?

// AMMO number pos.
#define ST_AMMOWIDTH            3       
#define ST_AMMOX                        44
#define ST_AMMOY                        171

// HEALTH number pos.
#define ST_HEALTHWIDTH          3       
#define ST_HEALTHX                      90
#define ST_HEALTHY                      171

// Weapon pos.
#define ST_ARMSX                        111
#define ST_ARMSY                        172
#define ST_ARMSBGX                      104
#define ST_ARMSBGY                      168
#define ST_ARMSXSPACE           12
#define ST_ARMSYSPACE           10


// ARMOR number pos.
#define ST_ARMORWIDTH           3
#define ST_ARMORX                       221
#define ST_ARMORY                       171

// Key icon positions.
#define ST_KEY0WIDTH            8
#define ST_KEY0HEIGHT           5
#define ST_KEY0X                        239
#define ST_KEY0Y                        171
#define ST_KEY1WIDTH            ST_KEY0WIDTH
#define ST_KEY1X                        239
#define ST_KEY1Y                        181
#define ST_KEY2WIDTH            ST_KEY0WIDTH
#define ST_KEY2X                        239
#define ST_KEY2Y                        191

// Ammunition counter.
#define ST_AMMO0WIDTH           3
#define ST_AMMO0HEIGHT          6
#define ST_AMMO0X                       288
#define ST_AMMO0Y                       173
#define ST_AMMO1WIDTH           ST_AMMO0WIDTH
#define ST_AMMO1X                       288
#define ST_AMMO1Y                       179
#define ST_AMMO2WIDTH           ST_AMMO0WIDTH
#define ST_AMMO2X                       288
#define ST_AMMO2Y                       191
#define ST_AMMO3WIDTH           ST_AMMO0WIDTH
#define ST_AMMO3X                       288
#define ST_AMMO3Y                       185

// Indicate maximum ammunition.
// Only needed because backpack exists.
#define ST_MAXAMMO0WIDTH                3
#define ST_MAXAMMO0HEIGHT               5
#define ST_MAXAMMO0X            314
#define ST_MAXAMMO0Y            173
#define ST_MAXAMMO1WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO1X            314
#define ST_MAXAMMO1Y            179
#define ST_MAXAMMO2WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO2X            314
#define ST_MAXAMMO2Y            191
#define ST_MAXAMMO3WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO3X            314
#define ST_MAXAMMO3Y            185

// pistol
#define ST_WEAPON0X                     110 
#define ST_WEAPON0Y                     172

// shotgun
#define ST_WEAPON1X                     122 
#define ST_WEAPON1Y                     172

// chain gun
#define ST_WEAPON2X                     134 
#define ST_WEAPON2Y                     172

// missile launcher
#define ST_WEAPON3X                     110 
#define ST_WEAPON3Y                     181

// plasma gun
#define ST_WEAPON4X                     122 
#define ST_WEAPON4Y                     181

 // bfg
#define ST_WEAPON5X                     134
#define ST_WEAPON5Y                     181

// WPNS title
#define ST_WPNSX                        109 
#define ST_WPNSY                        191

 // DETH title
#define ST_DETHX                        109
#define ST_DETHY                        191

//Incoming messages window location
#define ST_MSGTEXTX                     0
#define ST_MSGTEXTY                     0
// Dimensions given in characters.
#define ST_MSGWIDTH                     52
// Or shall I say, in lines?
#define ST_MSGHEIGHT            1

#define ST_OUTTEXTX                     0
#define ST_OUTTEXTY                     6

// Width, in characters again.
#define ST_OUTWIDTH                     52 
 // Height, in lines. 
#define ST_OUTHEIGHT            1

#define ST_MAPWIDTH     \
    (strlen(mapnames[(gameepisode-1)*9+(gamemap-1)]))

#define ST_MAPTITLEX \
    (SCREENWIDTH - ST_MAPWIDTH * ST_CHATFONTWIDTH)

#define ST_MAPTITLEY            0
#define ST_MAPHEIGHT            1



// whether in automap or first-person
extern st_stateenum_t   st_gamestate;

// whether left-side main status bar is active
extern boolean          st_statusbaron;


// 0-9, tall numbers
extern uint16_t         tallnum[10];


// 0-9, short, yellow (,different!) numbers
extern uint16_t         shortnum[10];

// 3 key-cards, 3 skulls
extern uint16_t         keys[NUMCARDS];

// face status patches
extern uint16_t         faces[ST_NUMFACES];

// face background
extern uint16_t         faceback;



// main bar right
//extern uint16_t         armsbg[1];

// weapon ownership patches
extern uint16_t	arms[6][2];




#endif
