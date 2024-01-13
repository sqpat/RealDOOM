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
#include "hu_stuff.h"
#include "r_local.h"
#include "r_draw.h"
#include "i_system.h"

// boolean : whether the screen is always erased
#define noterased viewwindowx

extern boolean	automapactive;	// in AM_map.c
extern patch_t far*		hu_font[HU_FONTSIZE];


boolean HUlib_addCharToTextLine ( hu_textline_t near* textline, int8_t ch ) {

	if (textline->len == HU_MAXLINELENGTH) {
		return false;
	} else {
		textline->characters[textline->len++] = ch;
		textline->characters[textline->len] = 0;
		textline->needsupdate = 4;
		return true;
    }

}
  
void HUlib_drawTextLine ( hu_textline_t near* textline) {

    int16_t			i;
    int16_t			w;
    int16_t			x;
    uint8_t	c;
	patch_t far* currentpatch;

    // draw the new stuff
    x = textline->x;
    for (i=0;i<textline->len;i++) {
		c = toupper(textline->characters[i]);
		if (c != ' ' && c >= textline->sc && c <= '_') {
			currentpatch = (hu_font[c - textline->sc]);
			w = (currentpatch->width);
			if (x + w > SCREENWIDTH) {
				break;
			}
			V_DrawPatchDirect(x, textline->y,  currentpatch);
			x += w;
		} else {
			x += 4;
			if (x >= SCREENWIDTH) {
				break;
			}
		}
    }
 
}


// sorta called by HU_Erase and just better darn get things straight
void HUlib_eraseTextLine(hu_textline_t near* textline) {
    uint16_t			lineheight = 8; // hacked to reduce page swaps so it might not work with custom wad?
    uint16_t			y;
    uint16_t			yoffset;
    static boolean	lastautomapactive = true;

    // Only erases when NOT in automap and the screen is reduced,
    // and the text must either need updating or refreshing
    // (because of a recent change back from the automap)

    if (!automapactive && viewwindowx && textline->needsupdate) {
		for (y=textline->y,yoffset=y*SCREENWIDTH ; y<textline->y+lineheight ; y++,yoffset+=SCREENWIDTH) {
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
	if (textline->needsupdate) {
		textline->needsupdate--;
	}

}
extern hu_stext_t	w_message;


void HUlib_addMessageToSText (int8_t* msg ) {
	hu_stext_t near* 	stext = &w_message;
	int16_t i;
	hu_textline_t near* textline;
	// add a clear line

	if (++stext->currentline == stext->height) {
		stext->currentline = 0;
	}

	textline = &stext->textlines[stext->currentline];
	textline->len = 0;
	textline->characters[0] = 0;
	textline->needsupdate = true;

	// everything needs updating
	for (i = 0; i < stext->height; i++) {
		stext->textlines[i].needsupdate = 4;
	}
	 
	while (*msg) {
		HUlib_addCharToTextLine(&stext->textlines[stext->currentline], *(msg++));
	}
}

 
