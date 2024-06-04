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


uint16_t spanfunc_jump_lookup[80] = {
    //1440,
    1422,
    1404,
    1386,
    1368,
    1350,
    1332,
    1314,
    1296,
    1278,
    1260,
    1242,
    1224,
    1206,
    1188,
    1170,
    1152,
    1134,
    1116,
    1098,
    1080,
    1062,
    1044,
    1026,
    1008,
    990,
    972,
    954,
    936,
    918,
    900,
    882,
    864,
    846,
    828,
    810,
    792,
    774,
    756,
    738,
    720,
    702,
    684,
    666,
    648,
    630,
    612,
    594,
    576,
    558,
    540,
    522,
    504,
    486,
    468,
    450,
    432,
    414,
    396,
    378,
    360,
    342,
    324,
    306,
    288,
    270,
    252,
    234,
    216,
    198,
    180,
    162,
    144,
    126,
    108,
    90,
    72,
    54,
    36,
    18,
	0


};
