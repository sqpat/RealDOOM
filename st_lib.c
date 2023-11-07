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
//	The status bar widget code.
//
#include <ctype.h>

#include "doomdef.h"

#include "z_zone.h"
#include "v_video.h"

#include "i_system.h"

#include "w_wad.h"

#include "st_stuff.h"
#include "st_lib.h"
#include "r_local.h"
 

// 
// A fairly efficient way to draw a number
//  based on differences from the old number.
// Note: worth the trouble?
//
void
STlib_drawNum
( st_number_t*	n,
  boolean	refresh,
	int16_t num)
{
    int16_t		numdigits = n->width;
	patch_t* p0 = (patch_t*) Z_LoadBytesFromEMS(n->pRef[0]);
	int16_t w = (p0->width);
	int16_t h = (p0->height);
	int16_t x = n->x;
    
    int16_t		neg;

	// [crispy] redraw only if necessary
	if (n->oldnum == num && !refresh) {
		return;
	}

    n->oldnum = num;

    neg = num < 0;

    if (neg)
    {
	if (numdigits == 2 && num < -9)
	    num = -9;
	else if (numdigits == 3 && num < -99)
	    num = -99;
	
	num = -num;
    }

    // clear the area
    x = n->x - numdigits*w;

    V_CopyRect(x, n->y - ST_Y, w*numdigits, h, x, n->y);

    // if non-number, do not draw it
    if (num == 1994)
		return;

    x = n->x;

    // in the special case of 0, you draw 0
	if (!num) {
		V_DrawPatch(x - w, n->y, FG, (patch_t*)Z_LoadBytesFromEMS(n->pRef[0]));
	}
    // draw the new number
    while (num && numdigits--) {
		x -= w;
		V_DrawPatch(x, n->y, FG, (patch_t*)Z_LoadBytesFromEMS( n->pRef[ num % 10 ]));
		num /= 10;
    }
 
}





void
STlib_updatePercent
( st_percent_t*		per,
  int16_t			refresh, 
	int16_t			value)
{
    if (refresh)
		V_DrawPatch(per->n.x, per->n.y, FG, (patch_t*)Z_LoadBytesFromEMS(per->pRef));
	
	STlib_drawNum(&per->n, refresh, value);
}





void
STlib_updateMultIcon
( st_multicon_t*	mi,
  boolean		refresh,
	int16_t		inum,
	boolean		is_binicon)
{
    int16_t			w;
    int16_t			h;
    int16_t			x;
    int16_t			y;
	patch_t*    old;
	if ((mi->oldinum != inum || refresh) && (inum != -1)) {
		if (!is_binicon && mi->oldinum != -1) {
			old = (patch_t*)Z_LoadBytesFromEMS(mi->pRef[mi->oldinum]);
			x = mi->x - (old->leftoffset);
			y = mi->y - (old->topoffset);
			w = (old->width);
			h = (old->height);

#ifdef CHECK_FOR_ERRORS
			if (y - ST_Y < 0) {
				I_Error("updateMultIcon: y - ST_Y < 0");
			}
#endif
			V_CopyRect(x, y - ST_Y,   w, h, x, y);
		} 
			
		// binicon only has an array length zero and inum is always 1; this inum-is_binicon
		// to work on the same line of code.
		V_DrawPatch(mi->x, mi->y, FG, (patch_t*)Z_LoadBytesFromEMS(mi->pRef[inum-is_binicon]));

		mi->oldinum = inum;
	}
}

