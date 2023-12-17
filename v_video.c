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
//	Gamma correction LUT stuff.
//	Functions to draw patches (by post) directly to screen.
//	Functions to blit a block to the screen.
//


#include <conio.h>
#include "i_system.h"
#include "r_local.h"

#include "doomdef.h"
#include "doomdata.h"

#include "m_misc.h"

#include "v_video.h"


// Each screen is [SCREENWIDTH*SCREENHEIGHT]; 


#ifdef STATIC_ALLOCATED_SCREENS
byte				*screen0;// [1L * SCREENWIDTH*SCREENHEIGHT];
//byte				screen1[1L*SCREENWIDTH*SCREENHEIGHT];

	#ifdef SKIPWIPE
	byte* screen2;
	byte* screen3;
	#else
	byte				screen2[SCREENWIDTH*SCREENHEIGHT];
	byte				screen3[SCREENWIDTH*SCREENHEIGHT];
	#endif


#else
byte*				screen0;
//byte*				screen1;
byte*				screen2;
byte*				screen3;

#endif

byte*				screen4;
int16_t				dirtybox[4]; 



// Now where did these came from?
byte *gammatable;

 
#define SC_INDEX                0x3C4
#define SC_RESET                0
#define SC_CLOCK                1
#define SC_MAPMASK              2
#define SC_CHARMAP              3
#define SC_MEMMODE              4

#define GC_INDEX                0x3CE
#define GC_SETRESET             0
#define GC_ENABLESETRESET 1
#define GC_COLORCOMPARE 2
#define GC_DATAROTATE   3
#define GC_READMAP              4
#define GC_MODE                 5
#define GC_MISCELLANEOUS 6
#define GC_COLORDONTCARE 7
#define GC_BITMASK              8

uint8_t	usegamma;
extern boolean skipdirectdraws;
//
// V_MarkRect 
// 
void
V_MarkRect
( int16_t		x,
  int16_t		y,
  int16_t		width,
  int16_t		height ) 
{ 
    M_AddToBox16 (dirtybox, x, y); 
    M_AddToBox16 (dirtybox, x+width-1, y+height-1); 
} 
 

//
// V_CopyRect 
// 
void 
V_CopyRect
( uint16_t		srcx,
  uint16_t		srcy,
  uint16_t		width,
  uint16_t		height,
  int16_t		destx,
  int16_t		desty ) 
{ 
    byte*	src;
    byte*	dest; 
	if (skipdirectdraws) {
		return;
	}
     
    V_MarkRect (destx, desty, width, height); 
	 

    src = screen4+((uint16_t)SCREENWIDTH*srcy+srcx); 
    dest = screen0 +((uint16_t)SCREENWIDTH*desty+destx);

    for ( ; height>0 ; height--) { 
        memcpy (dest, src, width); 
        src += SCREENWIDTH; 
        dest += SCREENWIDTH; 
    } 
} 
 
extern boolean skipdirectdraws;
//
// V_DrawPatch
// Masks a column based masked pic to the screen. 
//
void
V_DrawPatch
( int16_t		x,
  int16_t		y,
  int16_t		scrn,
  patch_t*	patch ) 
{ 

    int16_t		col; 
    column_t*	column; 
	uint16_t offset;
	byte* desttop;
    int16_t		w; 
	 
	if (skipdirectdraws) {
		return;
	}

    y -= (patch->topoffset); 
    x -= (patch->leftoffset); 
	offset = y * SCREENWIDTH + x;

    if (!scrn)
		V_MarkRect (x, y, (patch->width), (patch->height)); 

	switch (scrn) {
		case 0:
		case 1:
			desttop = screen0 + offset;
			break;

#ifndef SKIPWIPE
		case 2:
			desttop = screen2 + offset;
			break;
		case 3:
			desttop = screen3 + offset;
			break;
#endif
		case 4:
			desttop = screen4 + offset;
			if (currenttask != TASK_STATUS) {
				I_Error("drawpatch bad task"); // todo remove this check
			}
			break;
	}



    col = 0; 
    ///desttop = screens[scrn] + y * SCREENWIDTH + x;
	 
    w = (patch->width); 

    for ( ; col<w ; x++, col++, desttop++)
    { 
	column = (column_t *)((byte *)patch + (patch->columnofs[col])); 
 
	// step through the posts in a column 
	while (column->topdelta != 0xff ) 
	{ 

		register const byte *source = (byte *)column + 3;
		register byte *dest = desttop + column->topdelta * SCREENWIDTH;
		register int16_t count = column->length;

		if ((count -= 4) >= 0)
			do
			{
				register byte s0, s1;
				s0 = source[0];
				s1 = source[1];
				dest[0] = s0;
				dest[SCREENWIDTH] = s1;
				dest += SCREENWIDTH * 2;
				s0 = source[2];
				s1 = source[3];
				source += 4;
				dest[0] = s0;
				dest[SCREENWIDTH] = s1;
				dest += SCREENWIDTH * 2;
			} while ((count -= 4) >= 0);
			if (count += 4)
				do
				{
					*dest = *source;
					source++;
					dest += SCREENWIDTH;
				} while (--count);
				column = (column_t *)(source + 1);
	} 
    }			 
} 
 


//
// V_DrawPatchDirect
// Draws directly to the screen on the pc. 
//
void
V_DrawPatchDirect
( int16_t		x,
  int16_t		y,
  patch_t*	patch ) 
{
    int16_t		count;
    int16_t		col; 
    column_t*	column; 
    byte*	desttop;
    byte*	dest;
    byte*	source; 
    int16_t		w; 
	 
    y -= (patch->topoffset); 
    x -= (patch->leftoffset); 
 
	desttop = (byte*)(destscreen.w + y * (SCREENWIDTH / 4) + (x>>2));
	 
    w = (patch->width); 
    for ( col = 0 ; col<w ; col++) 
    { 
#ifndef	SKIP_DRAW
		outp (SC_INDEX+1,1<<(x&3));
#endif
	column = (column_t *)((byte *)patch + (patch->columnofs[col])); 
 
	// step through the posts in a column 
	 
	while (column->topdelta != 0xff ) 
	{ 
	    source = (byte *)column + 3; 
		dest = desttop + column->topdelta * (SCREENWIDTH / 4);
	    count = column->length; 
	    while (count--)  { 
#ifndef	SKIP_DRAW
			*dest = *source;
			source++;
#endif
			dest +=  (SCREENWIDTH / 4);
	    } 
	    column = (column_t *)(  (byte *)column + column->length + 4 ); 
	} 
	if ( ((++x)&3) == 0 ) 
	    desttop++;	// go to next byte, not next plane 
    }
} 
 
