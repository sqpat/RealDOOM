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
    
    // pointer to current value
    int16_t*	num;

    // pointer to boolean stating
    //  whether to update number
    boolean*	on;

    // list of patches for 0-9
    //patch_t**	p;
	MEMREF* pRef;

    // user data
	int8_t data;
    
} st_number_t;



// Percent widget ("child" of number widget,
//  or, more precisely, contains a number widget.)
typedef struct
{
    // number information
    st_number_t		n;

    // percent sign graphic
    //patch_t*		p;
	MEMREF pRef;
    
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
    int16_t*		inum;

    // pointer to boolean stating
    //  whether to update icon
    boolean*		on;

    // list of icons
    //patch_t**		p;
	MEMREF*		pRef;
    
    // user data
	int16_t 		data;
    
} st_multicon_t;




// Binary Icon widget

typedef struct
{
    // center-justified location of icon
	int16_t 		x;
	int16_t 		y;

    // last icon value
	int16_t 		oldval;

    // pointer to current icon status
    boolean*		val;

    // pointer to boolean
    //  stating whether to update icon
    boolean*		on;  


    //patch_t*		p;	// icon
	MEMREF		pRef;
    
} st_binicon_t;



//
// Widget creation, access, and update routines
//

// Initializes widget library.
// More precisely, initialize STMINUS,
//  everything else is done somewhere else.
//
void STlib_init(void);



// Number widget routines
void
STlib_initNum
( st_number_t*		n,
	int16_t 		x,
	int16_t 		y,
    MEMREF*		plRef,
    int16_t*			num,
    boolean*		on,
	int16_t 		width );

void
STlib_updateNum
( st_number_t*		n,
  boolean		refresh );


// Percent widget routines
void
STlib_initPercent
( st_percent_t*		p,
	int16_t 		x,
	int16_t 		y,
    MEMREF*		plRef,
    int16_t*			num,
    boolean*		on,
    MEMREF		percentRef 
);


void
STlib_updatePercent
( st_percent_t*		per,
	int16_t 		refresh );


// Multiple Icon widget routines
void
STlib_initMultIcon
( st_multicon_t*	mi,
	int16_t 		x,
	int16_t 		y,
  MEMREF*		ilRef,
  int16_t*			inum,
  boolean*		on );


void
STlib_updateMultIcon
( st_multicon_t*	mi,
  boolean		refresh );

// Binary Icon widget routines

void
STlib_initBinIcon
( st_binicon_t*		b,
	int16_t 		x,
	int16_t 		y,
  MEMREF		iRef,
  boolean*		val,
  boolean*		on );

void
STlib_updateBinIcon
( st_binicon_t*		bi,
  boolean		refresh );

#endif
