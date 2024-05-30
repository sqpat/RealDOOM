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
#include "memory.h"

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

uint16_t FLAT_CACHE_PAGE[4] = { 0x7000, 0x7400, 0x7800, 0x7C00 };

 

uint16_t R_DRAW_BX_OFFSETS[16] = { 0x0000, 0x0100, 0x0200, 0x0300, 
								   0x0400, 0x0500, 0x0600, 0x0700, 
								   0x0800, 0x0900, 0x0A00, 0x0B00, 
								   0x0C00, 0x0D00, 0x0E00, 0x0F00 };


uint16_t R_DRAW_BX_OFFSETS_shift4[16] = { 0x0000, 0x0010, 0x0020, 0x0030, 
								 	  	0x0040, 0x0050, 0x0060, 0x0070, 
								   		0x0080, 0x0090, 0x00A0, 0x00B0, 
								   		0x00C0, 0x00D0, 0x00E0, 0x00F0 };

 