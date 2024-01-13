
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
#include "w_wad.h"
#include <dos.h>


 
// Specially handles titlepic and other ~68k textures that exceed the 64k 4x page frames limit.
// Requires loading data in one page frame at a time
// It's okay if this is kind of slow... its only used in menus.

void
V_DrawFullscreenPatch
(
	int8_t*       pagename,
	int16_t screen)
{
	int16_t		count;
	int16_t		col;
	column_t far*	column;
	byte far* desttop;
	byte far*	dest;
	byte far*	source;
	int16_t		w;
	patch_t far*	patch;
	byte far*	patch2;
 
	int32_t    offset = 0;
	int16_t    pageoffset = 0;
	byte far*       extradata;
	int16_t	pagenum = 0;
	int16_t oldtask = currenttask;
	int16_t lump = W_GetNumForName(pagename);
	Z_QuickmapScratch_5000();

	patch = (patch_t far*)MK_FP(0x5000, 0x0000);
	patch2 =  MK_FP(0x5000, 0x8000);
	W_CacheLumpNumDirectFragment(lump, (byte far*)patch, pagenum, 0);


	extradata = (byte far*)patch;
	w = (patch->width);


	V_MarkRect(0, 0, w, (patch->height));
	if (screen == 1) {
		desttop = screen1;
	}
	else {
		desttop = screen0;
	}

	for (col = 0; col < w; col++, desttop++) {

		// todo dynamically calculate the offsets
		column = (column_t  far*)((byte  far*)extradata + ((patch->columnofs[col]) - offset));
		pageoffset = (byte  far*)column - extradata;

		if (pageoffset > 16000) {
			offset += pageoffset;
			pagenum++;
			W_CacheLumpNumDirectFragment(lump, patch2, pagenum, offset);
			extradata = patch2;
			column = (column_t  far*)((byte  far*)extradata + patch->columnofs[col] - offset);
		}


		// step through the posts in a column 
		while (column->topdelta != 0xff) {

			source = (byte  far*)column + 3;
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
					column = (column_t  far*)(source + 1);
		}
	}


	Z_QuickmapByTaskNum(oldtask);

}
