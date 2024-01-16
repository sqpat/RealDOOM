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

#include <ctype.h>
#include <alloca.h>

#include "doomdef.h"

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


 

hu_textline_t	w_title;

boolean		message_on;
boolean			message_dontfuckwithme;
boolean		message_nottobefuckedwith;

hu_stext_t	w_message;
uint8_t		message_counter;

extern uint8_t		showMessages;
extern boolean		automapactive;


 

void HU_Drawer(void) {


	hu_stext_t near* stext = &w_message;
	int16_t i, index;
	hu_textline_t near*line;
	boolean	mapped = false;
	
	if (!*stext->on) {
		return; // if not on, don't draw
	}
	
	// draw everything
	for (i = 0; i < stext->height; i++) {
		if (!mapped) {
			Z_QuickmapStatus();
			mapped = true;
		}
		index = stext->currentline - i;
		if (index < 0) {
			index += stext->height; // handle queue of lines
		}

		line = &stext->textlines[index];

		// need a decision made here on whether to skip the draw
		HUlib_drawTextLine(line); // no cursor, please
	}

	if (automapactive) {
		Z_QuickmapStatus();
		mapped = true;
		HUlib_drawTextLine(&w_title);
	}
	
	if (mapped) {
		Z_QuickmapPhysics();
	}
}

void HU_Erase(void)
{
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

void HU_Ticker(void) {

	// tick down message counter if message is up
	if (message_counter && !--message_counter) {
		message_on = false;
		message_nottobefuckedwith = false;
	}

	if (showMessages || message_dontfuckwithme) {

		// display message if necessary
		if (((player.messagestring || player.message != -1) && !message_nottobefuckedwith) || (player.message && message_dontfuckwithme)) {

			if (player.message != -1) {
				int8_t tempstring[256];// = "TEST 123 TEST 456 TEST 789 TEST 000";
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

 
boolean HU_Responder(event_t far *ev)
{

	boolean eatkey = false;
	static boolean shiftdown = false;
	static boolean altdown = false;

	if (ev->data1 == KEY_RSHIFT)
	{
		shiftdown = ev->type == ev_keydown;
		return false;
	}
	else if (ev->data1 == KEY_RALT || ev->data1 == KEY_LALT)
	{
		altdown = ev->type == ev_keydown;
		return false;
	}

	if (ev->type != ev_keydown)
		return false;

	if (ev->data1 == HU_MSGREFRESH)
	{
		message_on = true;
		message_counter = HU_MSGTIMEOUT;
		eatkey = true;
	}

	return eatkey;

}
