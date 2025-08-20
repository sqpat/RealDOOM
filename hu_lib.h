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
//

#ifndef __HULIB__
#define __HULIB__

// We are referring to patches.
#include "r_defs.h"


// font stuff
#define HU_CHARERASE	KEY_BACKSPACE

#define HU_MAXLINES		4
#define HU_MAXLINELENGTH	80

//
// Typedefs of widgets
//

// Text Line widget
//  (parent of Scrolling Text and Input Text widgets)
typedef struct {

    // left-justified position of scrolling text window
    int16_t		x;
    int16_t		y;
    
    uint8_t		sc;			// start character
	int8_t		characters[HU_MAXLINELENGTH+1];	// line of text
    int16_t		len;		      	// current line length

    // whether this line needs to be udpated
    int8_t		needsupdate;	      

} hu_textline_t;



// Scrolling Text window widget
//  (child of Text Line widget)
typedef struct {

    hu_textline_t	textlines[HU_MAXLINES];	// text lines to draw
    int8_t			height;		// height in lines
    int8_t			currentline;		// current line number

    // pointer to boolean stating whether to update window
    boolean*		on;
    boolean		laston;		// last value of *->on.

} hu_stext_t;



// Input Text Line widget
//  (child of Text Line widget)
typedef struct {

    hu_textline_t	l;		// text line to input on

     // left margin past which I am not to delete characters
    int16_t			lm;

    // pointer to boolean stating whether to update window
    boolean*		on; 
    boolean		laston; // last value of *->on;

} hu_itext_t;


//
// Widget creation, access, and update routines
//

// initializes heads-up widget library

 


// returns success
void __near HUlib_addStringToTextLine(hu_textline_t  __near*t, int8_t* __near ch);

// draws tline
void __near HUlib_drawTextLine(hu_textline_t __near *l);

// erases text line
void __near HUlib_eraseTextLine(hu_textline_t __near *l);


//
// Scrolling Text window widget routines
//

 

void __near HUlib_addMessageToSText( int8_t* __near msg );
 

// Input Text Line widget routines
 

#endif
