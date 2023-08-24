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

#ifndef __M_MISC__
#define __M_MISC__


#include "doomdef.h"
#include "doomtype.h"
#include "z_zone.h"
//
// MISC
//
extern  int32_t	myargc;
extern  int8_t**	myargv;
extern int32_t	prndindex;


// Returns the position of the given parameter
// in the arg list (0 if not found).
int32_t M_CheckParm (int8_t* check);

boolean
M_WriteFile
(int8_t const*	name,
  void*		source,
  int32_t		length );

int
M_ReadFile
(int8_t const*	name,
  MEMREF*	bufferRef );

// Returns a number from 0 to 255,
// from a lookup table.
int32_t M_Random(void);

// As M_Random, but used only by the play simulation.
int32_t P_Random(void);


// Fix randoms for demos.
void M_ClearRandom(void);

// Bounding box coordinate storage.
enum
{
    BOXTOP,
    BOXBOTTOM,
    BOXLEFT,
    BOXRIGHT
};	// bbox coordinates

// Bounding box functions.
void M_ClearBox (fixed_t*	box);

void
M_AddToBox
( fixed_t*	box,
  fixed_t	x,
  fixed_t	y );


void M_LoadDefaults (void);

void M_SaveDefaults (void);

 


#endif
