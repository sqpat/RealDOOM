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

#ifndef __D_EVENT__
#define __D_EVENT__


#include "doomtype.h"


//
// Event handling.
//

// Input event types.
#define ev_keydown 0
#define ev_keyup 1
#define ev_mouse 2

typedef uint8_t evtype_t;

// Event structure.
typedef struct
{
    evtype_t	type;
    int32_t		data1;		// keys / mouse buttons
    int32_t		data2;		// mouse x move
    int32_t		data3;		// mouse y move
} event_t;

 
#define ga_nothing	  0
#define ga_loadlevel  1
#define ga_newgame    2
#define ga_loadgame   3
#define ga_savegame   4
#define ga_playdemo   5
#define ga_completed  6
#define ga_victory    7
#define ga_worlddone  8

typedef uint8_t gameaction_t;



//
// Button/action code definitions.
//
// Press "Fire".
#define BT_ATTACK		 1
// Use button, to open doors, activate switches.
#define BT_USE		 2

// Flag: game events, not really buttons.
#define BT_SPECIAL		 128
#define BT_SPECIALMASK	 3
    
// Flag, weapon change pending.
// If true, the next 3 bits hold weapon num.
#define BT_CHANGE		 4
// The 3bit weapon mask and shift, convenience.
#define BT_WEAPONMASK	 (8+16+32)
#define BT_WEAPONSHIFT	 3

// Pause the game.
#define BTS_PAUSE		 1
// Save the game at each console.
#define BTS_SAVEGAME	 2

// Savegame slot numbers
//  occupy the second byte of buttons.    
#define BTS_SAVEMASK	 (4+8+16)
#define BTS_SAVESHIFT 	 2
  
typedef uint8_t buttoncode_t;




//
// GLOBAL VARIABLES
//
#define MAXEVENTS		64

extern  event_t			events[MAXEVENTS];
extern  gameaction_t	gameaction;


#endif
