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

segment_t pagesegments[4] = { 0x0000u, 0x0400u, 0x0800u, 0x0c00u };

uint16_t MULT_4096[4] = {0x0000u, 0x1000u, 0x2000u, 0x3000u};
uint16_t MULT_256[4] = {0x0000u, 0x0100u, 0x0200u, 0x0300u};

uint16_t FLAT_CACHE_PAGE[4] = { 0x7000, 0x7400, 0x7800, 0x7C00 };

 
uint8_t quality_port_lookup[12] = {

// lookup for what to write in the planar port of vga during draw column etc.
//. constructed from detailshift and dc_x & 0x3
	// bit 34  00
         1, 2, 4, 8,

	// bit 34  01 = low
	     3, 12, 3, 12,

	    
	// bit 34  10  = potato
		15, 15, 15, 15


};

