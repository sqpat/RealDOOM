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

#include "doomdef.h"
#include <ctype.h>


#include "v_video.h"

#include "hu_lib.h"
#include "hu_stuff.h"
#include "r_local.h"
#include "r_draw.h"
#include "i_system.h"
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"


// boolean : whether the screen is always erased
#define noterased viewwindowx



void __near HUlib_addStringToTextLine(hu_textline_t  __near*textline, int8_t* __near str){	
	int16_t index = 0;
	while (str[index]){
		if (textline->len == HU_MAXLINELENGTH) {
			textline->characters[textline->len] = 0;
			return;
		} else {
			textline->characters[textline->len++] = locallib_toupper(str[index]);
			textline->needsupdate = 4;
		}
		index++;
	}
	textline->characters[textline->len] = 0;

}
  
void __near HUlib_drawTextLine ( hu_textline_t __near* textline) {

    int16_t			i;
    int16_t			width;
    int16_t			x;
    uint8_t	c;
	patch_t __far* currentpatch;

    // draw the new stuff
    x = textline->x;
    for (i=0;i<textline->len;i++) {
		c = textline->characters[i];
		if (c != ' ' && c >= textline->sc && c <= '_') {
			currentpatch = ((patch_t __far *) MK_FP(ST_GRAPHICS_SEGMENT, hu_font[c - textline->sc]));


			width = (currentpatch->width);
			if (x + width > SCREENWIDTH) {
				break;
			}
			V_DrawPatchDirect(x, textline->y,  currentpatch);
			x += width;
		} else {
			x += 4;
			if (x >= SCREENWIDTH) {
				break;
			}
		}
    }
 
}


// sorta called by HU_Erase and just better darn get things straight
void __near HUlib_eraseTextLine(hu_textline_t __near* textline) {
    uint16_t			lineheight = 8; // hacked to reduce page swaps so it might not work with custom wad?
    uint16_t			y;
    uint16_t			yoffset;
    
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

	if (textline->needsupdate) {
		textline->needsupdate--;
	}

}

void __near HUlib_addMessageToSText (int8_t* __near msg ) {
	hu_stext_t __near* 	stext = &w_message;
	int16_t i;
	hu_textline_t __near* textline;
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
	 
	HUlib_addStringToTextLine(&stext->textlines[stext->currentline], msg);
	hudneedsupdate = 4;
}

 
