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
// 	The status bar widget code.
//

#ifndef __STLIB__
#define __STLIB__


// We are referring to patches.
#include "r_defs.h"


//
// Background and foreground screen numbers
//
#define BG 4
#define FG 0



//
// Typedefs of widgets
//

// Number widget

typedef struct
{
    // upper right-hand corner
    //  of the number (right-justified)
	int16_t 	x;
	int16_t 	y;

    // max # of digits in number
	int16_t width;

    // last number value
	int16_t 	oldnum;

    // list of patches for 0-9
	uint16_t near* patchoffset;

} st_number_t;



// Percent widget ("child" of number widget,
//  or, more precisely, contains a number widget.)
typedef struct
{
    // number information
    st_number_t		num;

    // percent sign graphic
    //patch_t*		p;
	uint16_t  patchoffset;
    
} st_percent_t;



// Multiple Icon widget
typedef struct
{
     // center-justified location of icons
	int16_t 		x;
	int16_t 		y;

    // last icon number
	int16_t 		oldinum;

    // pointer to current icon

	// pointer to boolean stating
    //  whether to update icon

    // list of icons
    //patch_t**		p;
	uint16_t near*		patchoffset;
    
} st_multicon_t;



 


//
// Widget creation, access, and update routines
//

// Initializes widget library.
// More precisely, initialize STMINUS,
//  everything else is done somewhere else.
//


// Number widget routines
void
STlib_initNum
( st_number_t near*		num,
	int16_t 		x,
	int16_t 		y,
	uint16_t near*		pl,
	int16_t 		width );

void
STlib_drawNum
(st_number_t near*	n,
	boolean	refresh,
	int16_t num);

// Percent widget routines
void
STlib_initPercent
( st_percent_t near*		per,
	int16_t 		x,
	int16_t 		y,
	uint16_t near*		pl,
	uint16_t 		percent
);


void
STlib_updatePercent
( st_percent_t near*		per,
	int16_t 		refresh,
	int16_t			num);


// Multiple Icon widget routines
void
STlib_initMultIcon
( st_multicon_t near*	mi,
	int16_t 		x,
	int16_t 		y,
	uint16_t near*		il);


void
STlib_updateMultIcon
( st_multicon_t near*	mi,
  boolean		refresh,
	int16_t			inum,
	boolean is_binicon);
 


// ready-weapon widget
extern st_number_t      w_ready;


// health widget
extern st_percent_t     w_health;

// arms background
extern st_multicon_t     w_armsbg;


// weapon ownership widgets
extern st_multicon_t    w_arms[6];

// face status widget
extern st_multicon_t    w_faces;

// keycard widgets
extern st_multicon_t    w_keyboxes[3];

// armor widget
extern st_percent_t     w_armor;

// ammo widgets
extern st_number_t      w_ammo[4];

// max ammo widgets
extern st_number_t      w_maxammo[4];




// used to use appopriately pained face
extern int16_t      st_oldhealth;

// used for evil grin
extern boolean  oldweaponsowned[NUMWEAPONS];

// count until face changes
extern int16_t      st_facecount;

// current face index, used by w_faces
extern int16_t      st_faceindex;

// holds key-type for each key box on bar
extern int16_t      keyboxes[3];

// a random number per tick
extern uint8_t      st_randomnumber;

#endif
