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
//	System specific interface stuff.
//


#ifndef __R_DRAW__
#define __R_DRAW__


extern uint16_t dc_colormap_segment;
extern uint8_t dc_colormap_index;
extern int16_t		dc_x;
extern int16_t		dc_yl;
extern int16_t		dc_yh;
extern fixed_t		dc_iscale;
extern fixed_t_union		dc_texturemid;

// first pixel in a column
extern byte __far*		dc_source;

#define COLORMAP_SHADOW 0xFF
// The span blitting interface.
// Hook in assembler or system specific BLT
//  here.
void 	__far R_DrawColumn (void);
void 	__far R_DrawColumnLow (void);

// The Spectre/Invisibility effect.
void 	__far R_DrawFuzzColumn (void);
void 	__far R_DrawFuzzColumnLow (void);
 

void __far R_VideoErase (uint16_t	ofs, int16_t		count );

extern int16_t		ds_y;
extern int16_t		ds_x1;
extern int16_t		ds_x2;

extern lighttable_t __far*	ds_colormap;

extern fixed_t		ds_xfrac;
extern fixed_t		ds_yfrac;
extern fixed_t		ds_xstep;
extern fixed_t		ds_ystep;

// start of a 64*64 tile image
 extern byte __far*		ds_source;

// Span blitting for rows, floor/ceiling.
// No Sepctre effect needed.
void 	__far R_DrawSpan (void);

// Low resolution mode, 160x200?
void __far 	R_DrawSpanLow (void);

 

// Rendering function.
void __far R_FillBackScreen (void);

// If the view size is not full screen, draws a border around it.
void __far R_DrawViewBorder (void);

void __far R_DrawColumnPrep();
void __far R_DrawColumnPrepHigh();


#endif
