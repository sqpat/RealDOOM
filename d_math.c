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


uint16_t R_DRAW_BX_OFFSETS[16] = { 0x8000, 0x7F01, 0x7E02, 0x7D03, 
								   0x7C04, 0x7B05, 0x7A06, 0x7907, 
								   0x7808, 0x7709, 0x760A, 0x750B, 
								   0x740C, 0x730D, 0x720E, 0x710F };

uint16_t R_DRAW_BX_OFFSETS_shift4[16] = { 0x0800, 0x07F0, 0x07E0, 0x07D0, 
								 	  	0x07C0, 0x07B0, 0x07A0, 0x0790, 
								   		0x0780, 0x0770, 0x0760, 0x0750, 
								   		0x0740, 0x0730, 0x0720, 0x0710 };


uint16_t R_DRAW_COLORMAPS_SEGMENT[16] = 
{ 
	colormapssegment - 0x0808, colormapssegment - 0x07F8, colormapssegment - 0x07E8, colormapssegment - 0x07D8,
	colormapssegment - 0x07C8, colormapssegment - 0x07B8, colormapssegment - 0x07A8, colormapssegment - 0x0798,
	colormapssegment - 0x0788, colormapssegment - 0x0778, colormapssegment - 0x0768, colormapssegment - 0x0758,
	colormapssegment - 0x0748, colormapssegment - 0x0738, colormapssegment - 0x0728, colormapssegment - 0x0718

 };

uint16_t R_DRAW_COLORMAPS_HIGH_SEGMENT[16] = 
{ 
	colormapssegment_high - 0x0808, colormapssegment_high - 0x07F8, colormapssegment_high - 0x07E8, colormapssegment_high - 0x07D8,
	colormapssegment_high - 0x07C8, colormapssegment_high - 0x07B8, colormapssegment_high - 0x07A8, colormapssegment_high - 0x0798,
	colormapssegment_high - 0x0788, colormapssegment_high - 0x0778, colormapssegment_high - 0x0768, colormapssegment_high - 0x0758,
	colormapssegment_high - 0x0748, colormapssegment_high - 0x0738, colormapssegment_high - 0x0728, colormapssegment_high - 0x0718

 };
