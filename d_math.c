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


uint16_t jump_lookup[201] = {
2800, 2786, 2772, 2758, 2744, 2730, 2716, 2702, 2688, 2674, 
2660, 2646, 2632, 2618, 2604, 2590, 2576, 2562, 2548, 2534, 
2520, 2506, 2492, 2478, 2464, 2450, 2436, 2422, 2408, 2394, 
2380, 2366, 2352, 2338, 2324, 2310, 2296, 2282, 2268, 2254, 
2240, 2226, 2212, 2198, 2184, 2170, 2156, 2142, 2128, 2114, 
2100, 2086, 2072, 2058, 2044, 2030, 2016, 2002, 1988, 1974, 
1960, 1946, 1932, 1918, 1904, 1890, 1876, 1862, 1848, 1834, 
1820, 1806, 1792, 1778, 1764, 1750, 1736, 1722, 1708, 1694, 
1680, 1666, 1652, 1638, 1624, 1610, 1596, 1582, 1568, 1554, 
1540, 1526, 1512, 1498, 1484, 1470, 1456, 1442, 1428, 1414, 
1400, 1386, 1372, 1358, 1344, 1330, 1316, 1302, 1288, 1274, 
1260, 1246, 1232, 1218, 1204, 1190, 1176, 1162, 1148, 1134, 
1120, 1106, 1092, 1078, 1064, 1050, 1036, 1022, 1008, 994, 
980, 966, 952, 938, 924, 910, 896, 882, 868, 854,
840, 826, 812, 798, 784, 770, 756, 742, 728, 714, 
700, 686, 672, 658, 644, 630, 616, 602, 588, 574, 
560, 546, 532, 518, 504, 490, 476, 462, 448, 434, 
420, 406, 392, 378, 364, 350, 336, 322, 308, 294, 
280, 266, 252, 238, 224, 210, 196, 182, 168, 154, 
140, 126, 112, 98, 84, 70, 56, 42, 28, 14, 0
} ;

