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
//  The status bar widget code.
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

typedef struct {
    // upper right-hand corner
    //  of the number (right-justified)
 int16_t  x;
 int16_t  y;

    // max # of digits in number
 int16_t width;

    // last number value
 int16_t  oldnum;

    // list of patches for 0-9
 uint16_t __near* patch_offset;

} st_number_t;



// Percent widget ("child" of number widget,
//  or, more precisely, contains a number widget.)
typedef struct {
    // number information
    st_number_t  num;

    // percent sign graphic
    //patch_t*  p;
 uint16_t  patch_offset;
    
} st_percent_t;



// Multiple Icon widget
typedef struct {
     // center-justified location of icons
 int16_t   x;
 int16_t   y;

    // last icon number
 int16_t   oldinum;

    // pointer to current icon

 // pointer to boolean stating
    //  whether to update icon

    // list of icons
  uint16_t __near*  patch_offset;
    
} st_multicon_t;



 

  

#endif
