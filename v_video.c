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


#include "i_system.h"
#include "r_local.h"

#include "doomdef.h"
#include "doomdata.h"

#include "m_misc.h"

#include "v_video.h"
#include "w_wad.h"
#include <conio.h>
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"


 



// Now where did these came from?
 
 
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

extern boolean skipdirectdraws;
//
// V_MarkRect 
// 
void __far V_MarkRect ( int16_t x, int16_t y, int16_t width, int16_t height )  { 
    M_AddToBox16 (dirtybox, x, y); 
    M_AddToBox16 (dirtybox, x+width-1, y+height-1); 
} 
 

//
// V_CopyRect 
// 

#define SCREEN4_SEGMENT 0x9C00
#define SCREEN0_SEGMENT 0x8000

void  V_CopyRect ( uint16_t srcoffset, uint16_t destoffset, uint16_t width, uint16_t height) { 
    byte __far*	src;
    byte __far*	dest;
	if (skipdirectdraws) {
		return;
	}
     
	 
	src =  MK_FP(SCREEN4_SEGMENT, srcoffset);
	dest = MK_FP(SCREEN0_SEGMENT, destoffset);

    for ( ; height>0 ; height--) { 
        FAR_memcpy (dest, src, width); 
        src += SCREENWIDTH; 
        dest += SCREENWIDTH; 
    } 
} 
 
//
// V_DrawPatch
// Masks a column based masked pic to the screen. 
//


/*
void V_DrawPatch ( int16_t x, uint8_t y,int8_t scrn,patch_t __far* patch ) { 

    int16_t		col; 
    column_t __far*	column;
	uint16_t offset;
	byte  __far* desttop;
    int16_t		w; 
	 
	if (skipdirectdraws) {
		return;
	}

    y -= (patch->topoffset); 
    x -= (patch->leftoffset); 
	offset = y * SCREENWIDTH + x;

    if (!scrn)
		V_MarkRect (x, y, (patch->width), (patch->height)); 

	desttop = MK_FP(screen_segments[scrn], offset);

    col = 0; 
	 
    w = (patch->width); 

    for ( ; col<w ; x++, col++, desttop++) { 
		column = (column_t __far *)((byte __far*)patch + (patch->columnofs[col])); 
 
		// step through the posts in a column 
		while (column->topdelta != 0xff )  { 

			register const byte __far*source = (byte __far*)column + 3;
			register byte __far*dest = desttop + column->topdelta * SCREENWIDTH;
			register int16_t count = column->length;

			if ((count -= 4) >= 0){
				do {
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
			}

			if (count += 4) {
				do {
					*dest = *source;
					source++;
					dest += SCREENWIDTH;
				} while (--count);
			}
			column = (column_t __far*)(source + 1);
		} 
    }			 
} 
 */


//
// V_DrawPatchDirect
// Draws directly to the screen on the pc. 
//
/*
void
V_DrawPatchDirect
( int16_t		x,
  int16_t		y,
  patch_t __far*	patch )
{
    int16_t		count;
    int16_t		col; 
    column_t __far*	column;
    byte __far*	desttop;
    byte __far*	dest;
    byte __far*	source;
    int16_t		w; 
	 
    y -= (patch->topoffset); 
    x -= (patch->leftoffset); 
 
	desttop = (byte __far*)(destscreen.w + y * (SCREENWIDTH / 4) + (x>>2));
	 
    w = (patch->width); 
    for ( col = 0 ; col<w ; col++) 
    { 
#ifndef	SKIP_DRAW
		outp (SC_INDEX+1,1<<(x&3));
#endif
	column = (column_t  __far*)((byte  __far*)patch + (patch->columnofs[col]));
 
	// step through the posts in a column 
	 
	while (column->topdelta != 0xff ) 
	{ 
	    source = (byte  __far*)column + 3;
		dest = desttop + column->topdelta * (SCREENWIDTH / 4);
	    count = column->length; 
	    while (count--)  { 
			*dest = *source;
			source++;
			dest +=  (SCREENWIDTH / 4);
	    } 
	    column = (column_t __far *)(  (byte  __far*)column + column->length + 4 );
	} 
	if ( ((++x)&3) == 0 ) {
	    desttop++;	// go to next byte, not next plane 
	}
    }
} 
*/
 

 
// Specially handles titlepic and other ~68k textures that exceed the 64k 4x page frames limit.
// Requires loading data in one page frame at a time
// It's okay if this is kind of slow... its only used in menus.

void V_DrawFullscreenPatch ( int8_t __near* pagename, int8_t screen) {
	int16_t		count;
	int16_t		col;
	column_t __far*	column;
	byte __far* desttop;
	byte __far*	dest;
	byte __far*	source;
	int16_t		w;
	patch_t __far*	patch = (patch_t __far *) (0x50000000);
 
	int32_t    offset = 0;
	int16_t    pageoffset = 0;
	byte __far*       extradata = (byte __far *)patch;
	int8_t oldtask = currenttask;
	int16_t lump = W_GetNumForName(pagename);
	Z_QuickMapScratch_5000();

	W_CacheLumpNumDirectFragment(lump, extradata, 0);

	w = (patch->width);


	V_MarkRect(0, 0, w, (patch->height));
	if (screen == 1) {
		desttop = screen1;
	} else {
		desttop = screen0;
	}

	for (col = 0; col < w; col++, desttop++) {

		// todo dynamically calculate the offsets
		column = (column_t  __far*)((byte  __far*)extradata + ((patch->columnofs[col]) - offset));
		pageoffset = (byte  __far*)column - extradata;

		if (pageoffset > 16000) {
			byte __far*	patch2 = (byte __far *) (0x50008000);
			offset += pageoffset;
			W_CacheLumpNumDirectFragment(lump, patch2,  offset);
			extradata = patch2;
			column = (column_t  __far*)((byte  __far*)extradata + patch->columnofs[col] - offset);
		}


		// step through the posts in a column 
		while (column->topdelta != 0xff) {

			source = (byte  __far*)column + 3;
			dest = desttop + column->topdelta * SCREENWIDTH;
			count = column->length;

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
					column = (column_t  __far*)(source + 1);
		}
	}

	Z_QuickMapByTaskNum(oldtask);

}
