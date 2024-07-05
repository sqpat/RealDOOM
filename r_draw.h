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
extern int16_t dc_x;
extern int16_t dc_yl;
extern int16_t dc_yh;
extern fixed_t dc_iscale;
extern fixed_t_union dc_texturemid;
extern uint16_t dc_yl_lookup_val; 


// first pixel in a column
extern segment_t		dc_source_segment;

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

extern uint16_t ds_colormap_segment;
extern uint8_t ds_colormap_index;

extern fixed_t		ds_xfrac;
extern fixed_t		ds_yfrac;
extern fixed_t		ds_xstep;
extern fixed_t		ds_ystep;
extern int16_t      sp_bp_safe_space[2];
extern int16_t      ss_variable_space[10];
extern int8_t  	    spanfunc_main_loop_count;
extern uint8_t 	    spanfunc_inner_loop_count[4];
extern uint8_t      spanfunc_outp[4];
extern int16_t    	spanfunc_prt[4];
extern uint16_t    	spanfunc_destview_offset[4];

// start of a 64*64 tile image
 extern byte __far*		ds_source;
 extern uint16_t ds_source_segment;

// Span blitting for rows, floor/ceiling.
// No Sepctre effect needed.
void 	__far R_DrawSpan (void);
void __far R_DrawSpanPrep();
 

// Rendering function.
void __far R_FillBackScreen (void);

// If the view size is not full screen, draws a border around it.
void __far R_DrawViewBorder (void);

void __far R_DrawColumnPrep(uint16_t lookup_offset_difference);


#endif
