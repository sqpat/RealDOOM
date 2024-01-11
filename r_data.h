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
//  Refresh module, data I/O, caching, retrieval of graphics
//  by name.
//

#ifndef __R_DATA__
#define __R_DATA__

#include "r_defs.h"
#include "r_state.h"

// Retrieve column data for span blitting.

extern uint8_t		skytexture;

 
byte*
R_GetColumn
( int16_t		tex,
  int16_t		col );

byte* getspritetexture(int16_t spritelump);

#define BAD_TEXTURE 255

// I/O, setting up the stuff.
void R_InitData (void);
void R_PrecacheLevel (void);

 
//byte* R_GetFlat (int16_t flatlump);

#define TEXTURE_TYPE_PATCH 1
#define TEXTURE_TYPE_COMPOSITE 2
#define TEXTURE_TYPE_SPRITE 3

 

#endif
