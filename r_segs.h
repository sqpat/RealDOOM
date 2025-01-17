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
//	Refresh module, drawing LineSegs from BSP.
//


#ifndef __R_SEGS__
#define __R_SEGS__


void __near R_RenderMaskedSegRange ( drawseg_t __far*	ds, int16_t		x1, int16_t		x2 );
void __near R_RenderMaskedSegRange2 ( drawseg_t __far*	ds, int16_t		x1, int16_t		x2 );

#endif
