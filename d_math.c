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
//  DOOM main program (D_DoomMain) and game loop (D_DoomLoop),
//  plus functions to determine game mode (shareware, registered),
//  parse command line parameters, configure game parameters (turbo),
//  and call the startup functions.
//

#include "d_math.h"


int16_t lightmult48lookup[16] = { 0,  48,  96, 144,
								192, 240, 288, 336,
								384, 432, 480, 528,
								576, 624, 672, 720 };

int16_t lightshift7lookup[16] = { 0,  128,  256, 384,
								 512,  640,  768, 896,
								1024, 1152, 1280, 1408,
								1536, 1664, 1792, 1920 };

uint16_t pageoffsets[4] = { 0x0000u, 0x4000u, 0x8000u, 0xc000u };

uint16_t MULT_4096[4] = {0x0000u, 0x1000u, 0x2000u, 0x3000u};

uint16_t FLAT_CACHE_PAGE[3] = { 0x5C00, 0x7000, 0x7400 };
//uint16_t FLAT_CACHE_PAGE[3] = { 0x7000, 0x7400, 0x7800 };
