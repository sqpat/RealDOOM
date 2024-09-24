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




#define COLORMAP_SHADOW 0xFF
// The span blitting interface.
// Hook in assembler or system specific BLT
//  here.
void 	__far R_DrawColumn (void);
void 	__far R_DrawColumnLow (void);

// The Spectre/Invisibility effect.
void 	__far R_DrawFuzzColumn (int16_t count, byte __far * dest);
 

void __far R_VideoErase (uint16_t	ofs, int16_t		count );



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
