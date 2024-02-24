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
#define size_openings						size_colormapbytes					+ sizeof(int16_t) * MAXOPENINGS
#define size_negonearray					size_openings						+ sizeof(int16_t) * (SCREENWIDTH)
#define size_screenheightarray				size_negonearray					+ sizeof(int16_t) * (SCREENWIDTH)
#define size_vissprites						size_screenheightarray				+ sizeof(vissprite_t) * (MAXVISSPRITES)
#define size_scalelightfixed				size_vissprites						+ sizeof(lighttable_t __far* ) * (MAXLIGHTSCALE)
#define size_scalelight						size_scalelightfixed				+ sizeof(lighttable_t __far*) * (LIGHTLEVELS * MAXLIGHTSCALE)
#define size_usedcompositetexturepagemem	size_scalelight						+ NUM_TEXTURE_PAGES * sizeof(uint8_t)
#define size_usedspritepagemem				size_usedcompositetexturepagemem	+ NUM_SPRITE_CACHE_PAGES * sizeof(uint8_t)
#define size_usedpatchpagemem				size_usedspritepagemem				+ NUM_PATCH_CACHE_PAGES * sizeof(uint8_t)


#define size_compositetextureoffset			size_usedpatchpagemem				+ MAX_TEXTURES * sizeof(uint8_t)
#define size_compositetexturepage			size_compositetextureoffset			+ MAX_TEXTURES * sizeof(uint8_t)
#define size_spritepage						size_compositetexturepage			+ MAX_SPRITE_LUMPS * sizeof(uint8_t)
#define size_spriteoffset					size_spritepage						+ MAX_SPRITE_LUMPS * sizeof(uint8_t)
#define size_patchpage						size_spriteoffset					+ MAX_PATCHES * sizeof(uint8_t)
#define size_patchoffset					size_patchpage						+ MAX_PATCHES * sizeof(uint8_t)
 

/*

#define colormapbytes				8000:0000
#define openings					8000:2100
#define negonearray					8000:c100
#define screenheightarray			8000:c380
#define vissprites					8000:c600
#define scalelightfixed				8000:e100
#define scalelight					8000:e1c0
#define usedcompositetexturepagemem 8000:edc0
#define usedspritepagemem			8000:edd8
#define usedpatchpagemem			8000:edfc

#define compositetextureoffset		8000:ee24
#define compositetexturepage		8000:efd0
#define spritepage					8000:f17c
#define spriteoffset				8000:f6e1
#define patchpage					8000:fc46
#define patchoffset					8000:fe22
									8000:fffe
*/

#define colormapbytes		((byte __far*				) 0x80000000)										
#define openings			((int16_t __far*			) (0x80000000 + size_colormapbytes))
#define negonearray			((int16_t __far*			) (0x80000000 + size_openings))
#define screenheightarray	((int16_t __far*			) (0x80000000 + size_negonearray))
#define vissprites			((vissprite_t __far*		) (0x80000000 + size_screenheightarray))
#define scalelightfixed		((lighttable_t __far*__far*	) (0x80000000 + size_vissprites))
#define scalelight			((lighttable_t __far*__far*	) (0x80000000 + size_scalelightfixed))
#define usedcompositetexturepagemem ((uint8_t __far*  ) (0x80000000 + size_scalelight))
#define usedspritepagemem	((uint8_t __far*			) (0x80000000 + size_usedcompositetexturepagemem))
#define usedpatchpagemem	((uint8_t __far*			) (0x80000000 + size_usedspritepagemem))

#define compositetextureoffset	((uint8_t __far*			) (0x80000000 + size_usedpatchpagemem))
#define compositetexturepage	((uint8_t __far*			) (0x80000000 + size_compositetextureoffset))
#define spritepage				((uint8_t __far*			) (0x80000000 + size_compositetexturepage))
#define spriteoffset			((uint8_t __far*			) (0x80000000 + size_spritepage))
#define patchpage				((uint8_t __far*			) (0x80000000 + size_spriteoffset))
#define patchoffset				((uint8_t __far*			) (0x80000000 + size_patchpage))


 


#define size_visplanes										sizeof(visplane_t) * MAXCONVENTIONALVISPLANES
#define size_visplaneheaders		size_visplanes			+ sizeof(visplaneheader_t) * MAXEMSVISPLANES
#define size_yslope					size_visplaneheaders	+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_distscale				size_yslope				+ (sizeof(fixed_t) * SCREENWIDTH)
#define size_cachedheight			size_distscale			+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cacheddistance			size_cachedheight		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedxstep			size_cacheddistance		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedystep			size_cachedxstep		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_spanstart				size_cachedystep		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_viewangletox			size_spanstart			+ (sizeof(int16_t) * (FINEANGLES / 2))
#define size_xtoviewangle			size_viewangletox		+ (sizeof(fineangle_t) * (SCREENWIDTH + 1))
#define size_drawsegs				size_xtoviewangle		+ (sizeof(drawseg_t) * (MAXDRAWSEGS))
#define size_floorclip				size_drawsegs			+ (sizeof(int16_t) * SCREENWIDTH)
#define size_ceilingclip			size_floorclip			+ (sizeof(int16_t) * SCREENWIDTH)
#define size_flatindex				size_ceilingclip		+ (sizeof(uint8_t) * MAX_FLATS)

/*
#define visplanes				9000:0000
#define visplaneheaders			9000:9948
#define yslope					9000:9d17
#define distscale				9000:a037
#define cachedheight			9000:a537
#define cacheddistance			9000:a857
#define cachedxstep				9000:ab77
#define cachedystep				9000:ae97  
#define spanstart				9000:b1b7
#define viewangletox			9000:b4d7
#define xtoviewangle			9000:d4d7
#define drawsegs				9000:d759
#define floorclip				9000:fa59
#define ceilingclip				9000:fcd9
#define flatindex				9000:ff59
								9000:fff0
*/



#define visplanes				((visplane_t __far*)			0x90000000)
#define visplaneheaders			((visplaneheader_t __far*)		(0x90000000 + size_visplanes))
#define yslope					((fixed_t __far*)				(0x90000000 + size_visplaneheaders))
#define distscale				((fixed_t __far*)				(0x90000000 + size_yslope))
#define cachedheight			((fixed_t __far*)				(0x90000000 + size_distscale))
#define cacheddistance			((fixed_t __far*)				(0x90000000 + size_cachedheight))
#define cachedxstep				((fixed_t __far*)				(0x90000000 + size_cacheddistance))
#define cachedystep				((fixed_t __far*)				(0x90000000 + size_cachedxstep))
#define spanstart				((int16_t __far*)				(0x90000000 + size_cachedystep))
#define viewangletox			((int16_t __far*)				(0x90000000 + size_spanstart))
#define xtoviewangle			((fineangle_t __far*)			(0x90000000 + size_viewangletox))
#define drawsegs				((drawseg_t __far*)				(0x90000000 + size_xtoviewangle))
#define floorclip				((int16_t __far*)				(0x90000000 + size_drawsegs))
#define ceilingclip				((int16_t __far*)				(0x90000000 + size_floorclip))
#define flatindex				((uint8_t __far*)				(0x90000000 + size_ceilingclip))

// Visplane related.
extern  int16_t __far*		lastopening;
 

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
