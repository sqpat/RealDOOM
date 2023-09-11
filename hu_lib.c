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
// DESCRIPTION:  heads-up text and input code
//

#include <ctype.h>

#include "doomdef.h"

#include "v_video.h"

#include "hu_lib.h"
#include "r_local.h"
#include "r_draw.h"

// boolean : whether the screen is always erased
#define noterased viewwindowx

extern boolean	automapactive;	// in AM_map.c

 

boolean
HUlib_addCharToTextLine
( hu_textline_t*	t,
	int8_t			ch )
{

    if (t->len == HU_MAXLINELENGTH)
	return false;
    else
    {
	t->l[t->len++] = ch;
	t->l[t->len] = 0;
	t->needsupdate = 4;
	return true;
    }

}
  
void
HUlib_drawTextLine
( hu_textline_t*	l,
  boolean		drawcursor )
{

    int16_t			i;
    int16_t			w;
    int16_t			x;
    uint8_t	c;
	patch_t* currentpatch;

    // draw the new stuff
    x = l->x;
    for (i=0;i<l->len;i++) {
		c = toupper(l->l[i]);
		if (c != ' ' && c >= l->sc && c <= '_') {
			currentpatch = (patch_t*)Z_LoadBytesFromEMS(l->fRef[c - l->sc]);
			w = (currentpatch->width);
			if (x + w > SCREENWIDTH) {
				break;
			}
			V_DrawPatchDirect(x, l->y,  currentpatch);
			x += w;
		} else {
			x += 4;
			if (x >= SCREENWIDTH) {
				break;
			}
		}
    }

	currentpatch = (patch_t*)Z_LoadBytesFromEMS(l->fRef['_' - l->sc]);
    // draw the cursor if requested
    if (drawcursor && x + (currentpatch->width) <= SCREENWIDTH) {
		V_DrawPatchDirect(x, l->y, currentpatch);
    }
}


// sorta called by HU_Erase and just better darn get things straight
void HUlib_eraseTextLine(hu_textline_t* l)
{
    uint16_t			lh;
    uint16_t			y;
    uint16_t			yoffset;
    static boolean	lastautomapactive = true;
	patch_t* currentpatch = Z_LoadBytesFromEMS(l->fRef[0]);   // todo can probably cache this


    // Only erases when NOT in automap and the screen is reduced,
    // and the text must either need updating or refreshing
    // (because of a recent change back from the automap)

    if (!automapactive && viewwindowx && l->needsupdate) {
		lh = (currentpatch->height) + 1;
		for (y=l->y,yoffset=y*SCREENWIDTH ; y<l->y+lh ; y++,yoffset+=SCREENWIDTH) {
			if (y < viewwindowy || y >= viewwindowy + viewheight) {
				R_VideoErase(yoffset, SCREENWIDTH); // erase entire line
			}  else {
				R_VideoErase(yoffset, viewwindowx); // erase left border
				R_VideoErase(yoffset + viewwindowx + viewwidth, viewwindowx);
				// erase right border
			}
		}
    }

    lastautomapactive = automapactive;
    if (l->needsupdate) l->needsupdate--;

}
 

void
HUlib_addMessageToSText
( hu_stext_t*	s,
  int8_t*		prefix,
  int8_t*		msg )
{

	int16_t i;
	hu_textline_t* t;
	// add a clear line
	if (++s->cl == s->h)
		s->cl = 0;

	t = &s->l[s->cl];
	t->len = 0;
	t->l[0] = 0;
	t->needsupdate = true;

	// everything needs updating
	for (i = 0; i < s->h; i++)
		s->l[i].needsupdate = 4;
	
	if (prefix)
	while (*prefix)
	    HUlib_addCharToTextLine(&s->l[s->cl], *(prefix++));

    while (*msg)
	HUlib_addCharToTextLine(&s->l[s->cl], *(msg++));
}

 
