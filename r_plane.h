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
// Refresh, visplane stuff (floor, ceilings).
//


#ifndef __R_PLANE__
#define __R_PLANE__


#include "r_data.h"

// Visplane related.
 

void __near R_ClearPlanes (void);
void __near R_DrawPlanes (void);

#define IS_CEILING_PLANE    1
#define IS_FLOOR_PLANE      0
int16_t __near R_FindPlane ( fixed_t height, uint8_t  picnum, uint8_t  lightlevel, int8_t isceil );
int16_t __near R_CheckPlane (int16_t index, int16_t  start, int16_t  stop,int8_t  isceil);



#endif
