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
//	Header for math-related optimization functions
//




#ifndef __D_MATH__
#define __D_MATH__
#include "doomtype.h" 

extern int16_t lightmult48lookup[16];
extern int16_t lightshift7lookup[16];
extern segment_t pagesegments[4];
extern uint16_t MULT_4096[4];
extern uint16_t MULT_256[4];
extern uint16_t FLAT_CACHE_PAGE[4];
extern uint8_t quality_port_lookup[12];
#endif
