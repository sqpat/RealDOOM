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

#include "doomdef.h"
#include "doomtype.h"


// Needed because we are refering to patches.
#include "r_data.h"
#include "st_stuff.h"

//
// VIDEO
//

#define CENTERY			(SCREENHEIGHT/2)


 


 


// Allocates buffer screens, call before R_Init.
//void V_Init (void);


void  V_CopyRect ( uint16_t srcoffset, uint16_t destoffset, uint16_t width, uint16_t height);
void  __far V_DrawFullscreenPatch ( int8_t __far* texname, int8_t screen) ;

/*
#pragma aux drawpatchparams \
                    __modify [ax] [dx] \
                    __parm [ax] [dh] [dl] [cx bx] ;
#pragma aux (drawpatchparams)  V_DrawPatch;
*/
void __far V_DrawPatch ( int16_t x, int16_t y, int8_t scrn, patch_t __far* patch);

void __far V_DrawPatchDirect( int16_t x,int16_t y, patch_t __far* patch );
void __far V_MarkRect( int16_t x, int16_t y, int16_t width, int16_t height );

#endif
