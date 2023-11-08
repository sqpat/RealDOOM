
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


MEMREF  W_CacheLumpNameEMSFragment(int8_t* name, int8_t tag, int16_t pagenum, int32_t offset);

// Specially handles titlepic and other ~68k textures that exceed the 64k 4x page frames limit.
// Requires loading data in one page frame at a time
// It's okay if this is kind of slow... its only used in menus.

void
V_DrawFullscreenPatch
(
	int8_t*       pagename)
{
	int16_t		count;
	int16_t		col;
	column_t*	column;
	byte* desttop;
	byte*	dest;
	byte*	source;
	int16_t		w;
	patch_t*	patch;
	MEMREF patchref;
	MEMREF colref;
	int32_t    offset = 0;
	int16_t    pageoffset = 0;
	byte*       extradata;


	patchref = W_CacheLumpNameEMSFragment(pagename, PU_LEVSPEC, 0, 0);
	patch = (patch_t*)Z_LoadBytesFromEMSWithOptions(patchref, PAGE_LOCKED);
	extradata = (byte*)patch;

	V_MarkRect(0, 0, (patch->width), (patch->height));

	desttop = screen0;
	col = 0;

	w = (patch->width);

	for (; col < w; col++, desttop++) {

		// todo dynamically calculate the offsets

		column = (column_t *)((byte *)extradata + ((patch->columnofs[col]) - offset));
		pageoffset = (byte *)column - extradata;

		if (pageoffset > 16000) {
			offset += pageoffset;
			colref = W_CacheLumpNameEMSFragment(pagename, PU_LEVSPEC, 1, offset);
			extradata = Z_LoadBytesFromEMS(colref);
			column = (column_t *)((byte *)extradata + patch->columnofs[col] - offset);
		}


		// step through the posts in a column 
		while (column->topdelta != 0xff) {

			source = (byte *)column + 3;
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
					column = (column_t *)(source + 1);
		}
	}

	Z_SetUnlocked(patchref);

}
