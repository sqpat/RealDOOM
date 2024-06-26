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
//	Gamma correction LUT.
//	Functions to draw patches (by post) directly to screen.
//	Functions to blit a block to the screen.
//


#ifndef __V_VIDEO__
#define __V_VIDEO__

#include "doomtype.h"

#include "doomdef.h"

// Needed because we are refering to patches.
#include "r_data.h"
#include "st_stuff.h"

//
// VIDEO
//

#define CENTERY			(SCREENHEIGHT/2)


 

//extern	byte*		screen4;

extern  int16_t	dirtybox[4];
#define NUM_MENU_ITEMS  45
#define MAXLINEANIMS    64

extern	uint8_t	usegamma;

/*


  8000:0000 screen0
  8000:FA00 gammatable
  8000:FF00 menuoffsets
  8000:FF5A linespeciallist
  8000:FFDA [empty]



*/


// Allocates buffer screens, call before R_Init.
//void V_Init (void);


void
V_CopyRect
( uint16_t		srcx,
  uint16_t		srcy,
  uint16_t		width,
  uint16_t		height,
  int16_t		destx,
  int16_t		desty);

void 
V_DrawFullscreenPatch
( 
  int8_t*       texname,
	int16_t		screen) ;

void
V_DrawPatch
( int16_t		x,
  int16_t		y,
  int16_t		scrn,
  patch_t __far*	patch);

void
V_DrawPatchDirect
( int16_t		x,
  int16_t		y,
  patch_t __far*	patch );

 

void
V_MarkRect
( int16_t		x,
  int16_t		y,
  int16_t		width,
  int16_t		height );

#endif
