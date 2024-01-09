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
//	Refresh, visplane stuff (floor, ceilings).
//


#ifndef __R_PLANE__
#define __R_PLANE__


#include "r_data.h"
#define MAXOPENINGS	SCREENWIDTH*64
#define MAXVISSPRITES  	128

#define size_colormapbytes					(33 * 256)
#define size_openings						size_colormapbytes + sizeof(int16_t) * MAXOPENINGS
#define size_negonearray					size_openings + sizeof(int16_t) * (SCREENWIDTH)
#define size_screenheightarray				size_negonearray + sizeof(int16_t) * (SCREENWIDTH)
#define size_vissprites						size_screenheightarray + sizeof(vissprite_t) * (MAXVISSPRITES)
#define size_scalelightfixed				size_vissprites + sizeof(lighttable_t far* ) * (MAXLIGHTSCALE)
#define size_scalelight						size_scalelightfixed + sizeof(lighttable_t far*) * (LIGHTLEVELS * MAXLIGHTSCALE)
#define size_usedcompositetexturepagemem	size_scalelight + NUM_TEXTURE_PAGES * sizeof(uint8_t)
#define size_usedspritepagemem				size_usedcompositetexturepagemem + NUM_SPRITE_CACHE_PAGES * sizeof(uint8_t)
#define size_usedpatchpagemem				size_usedspritepagemem + NUM_PATCH_CACHE_PAGES * sizeof(uint8_t)

//#define size_spritewidths	size_usedpatchpagemem + (sizeof(int16_t) * numspritelumps)
//#define spriteoffsets		spritewidths + (sizeof(int16_t) * numspritelumps)
//#define spritetopoffsets	spriteoffsets + (sizeof(int16_t) * numspritelumps)

#define colormapbytes		((byte *			far) 0x80000000)
#define openings			((int16_t *			far) (0x80000000 + size_colormapbytes))
#define negonearray			((int16_t *			far) (0x80000000 + size_openings))
#define screenheightarray	((int16_t *			far) (0x80000000 + size_negonearray))
#define vissprites			((vissprite_t *		far) (0x80000000 + size_screenheightarray))
#define scalelightfixed		((lighttable_t**	far) (0x80000000 + size_vissprites))
#define scalelight			((lighttable_t**    far) (0x80000000 + size_scalelightfixed))
#define usedcompositetexturepagemem ((uint8_t*  far) (0x80000000 + size_scalelight))
#define usedspritepagemem	((uint8_t*			far) (0x80000000 + size_usedcompositetexturepagemem))
#define usedpatchpagemem	((uint8_t*			far) (0x80000000 + size_usedspritepagemem))
#define spritewidths		((int16_t *			far) (0x80000000 + size_usedpatchpagemem))


// Visplane related.
extern  int16_t*		lastopening;
//extern int16_t*			openings;// [MAXOPENINGS];

extern int16_t		*floorclip;// [SCREENWIDTH];
extern int16_t		*ceilingclip;// [SCREENWIDTH];
extern int16_t		*spanstart;// [SCREENHEIGHT];

extern fixed_t		*yslope;// [SCREENHEIGHT];
extern fixed_t		*distscale;// [SCREENWIDTH];

extern fixed_t			*cachedheight;// [SCREENHEIGHT];
extern fixed_t			*cacheddistance;// [SCREENHEIGHT];
extern fixed_t			*cachedxstep;// [SCREENHEIGHT];
extern fixed_t			*cachedystep;// [SCREENHEIGHT];

void R_InitPlanes (void);
void R_ClearPlanes (void);

void R_DrawPlanes (void);


int16_t
R_FindPlane
( fixed_t	height,
  uint8_t		picnum,
  uint8_t		lightlevel );

int16_t
R_CheckPlane
(int16_t	index,
  int16_t		start,
  int16_t		stop );



#endif
