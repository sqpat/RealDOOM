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
// DESCRIPTION:  Heads-up displays
//

#include "doomdef.h"
#include <ctype.h>


#include "z_zone.h"

#include "hu_stuff.h"
#include "hu_lib.h"
#include "w_wad.h"

#include "s_sound.h"

#include "doomstat.h"
#include "r_state.h"
#include "i_system.h"
#include "r_bsp.h"

// Data.
#include "dstrings.h"
#include "sounds.h"
#include "m_near.h"




//todo: on automap toggles and such, set needsupdate back to 4

void __near HU_Drawer(void) {

	hu_stext_t __near* stext = &w_message;
	int16_t i, index;
	hu_textline_t __near*line;
	boolean	mapped = false;  // keep track of if we mapped out
	
	if (!*stext->on) {
		return; // if not on, don't draw
	}
	
	
	if (hudneedsupdate || automapactive || screenblocks >= 10){
	
		// draw everything
		for (i = 0; i < stext->height; i++) {

			index = stext->currentline - i;
			if (index < 0) {
				index += stext->height; // handle queue of lines
			}

			line = &stext->textlines[index];

			// need a decision made here on whether to skip the draw

			if (!mapped) {
				Z_QuickMapStatus();
				mapped = true;
			}

			HUlib_drawTextLine(line); // no cursor, please
		}

		hudneedsupdate--;
	}

	if (automapactive) {
		Z_QuickMapStatus();
		mapped = true;
		HUlib_drawTextLine(&w_title);
	}
	
	if (mapped) {
		// remap physics memory if mapped out
		Z_QuickMapPhysics();
	}
}

void __near HU_Erase(void) {
	int16_t i;
	for (i = 0; i < w_message.height; i++) {
		if (w_message.laston && !*w_message.on) {
			w_message.textlines[i].needsupdate = 4;
		}
		HUlib_eraseTextLine(&(w_message.textlines[i]));
	}
	w_message.laston = *w_message.on;

    HUlib_eraseTextLine(&w_title);

}

void __near HU_Ticker(void) {

	// tick down message counter if message is up
	if (message_counter && !--message_counter) {
		message_on = false;
		message_nottobefuckedwith = false;
	}

	if (showMessages || message_dontfuckwithme) {

		// display message if necessary
		if (((player.messagestring || player.message != -1) && !message_nottobefuckedwith) || (player.message && message_dontfuckwithme)) {

			if (player.message != -1) {
				int8_t tempstring[256];
				getStringByIndex(player.message, tempstring);
				HUlib_addMessageToSText(tempstring);
				player.message = -1;
			} else {
				HUlib_addMessageToSText(player.messagestring);
				player.messagestring = NULL;
			}
			message_on = true;
			message_counter = HU_MSGTIMEOUT;
			message_nottobefuckedwith = message_dontfuckwithme;
			message_dontfuckwithme = 0;
		}

	} // else message_on = false;

}

#define QUEUESIZE		128

 
boolean __near HU_Responder(event_t __far *ev) {

	boolean eatkey = false;

	if (ev->data1 == KEY_RSHIFT || ev->data1 == KEY_RALT || ev->data1 == KEY_LALT) {
		return false;
	}

	if (ev->type != ev_keydown){
		return false;
	}

	if (ev->data1 == HU_MSGREFRESH) {
		message_on = true;
		message_counter = HU_MSGTIMEOUT;
		eatkey = true;
	}

	return eatkey;

}
