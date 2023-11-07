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


 

void HU_Drawer(void)
{


	hu_stext_t* s = &w_message;
	int16_t i, idx;
	hu_textline_t *l;

	if (!*s->on)
		return; // if not on, don't draw

		// draw everything
	for (i = 0; i < s->h; i++)
	{
		idx = s->cl - i;
		if (idx < 0)
			idx += s->h; // handle queue of lines

		l = &s->l[idx];

		// need a decision made here on whether to skip the draw
		HUlib_drawTextLine(l, false); // no cursor, please
	}

    if (automapactive)
		HUlib_drawTextLine(&w_title, false);

}

void HU_Erase(void)
{
	int16_t i;

	for (i = 0; i < w_message.h; i++)
	{
		if (w_message.laston && !*w_message.on)
			w_message.l[i].needsupdate = 4;
		HUlib_eraseTextLine(&w_message.l[i]);
	}
	w_message.laston = *w_message.on;

    HUlib_eraseTextLine(&w_title);

}

void HU_Ticker(void)
{

	int8_t temp[256];
	// tick down message counter if message is up
	if (message_counter && !--message_counter)
	{
		message_on = false;
		message_nottobefuckedwith = false;
	}

	if (showMessages || message_dontfuckwithme)
	{

		// display message if necessary
		if (((player.messagestring || player.message != -1) && !message_nottobefuckedwith) || (player.message && message_dontfuckwithme))
		{
			if (player.message != -1) {
				 getStringByIndex(player.message, temp);
				HUlib_addMessageToSText(&w_message, 0, temp);
				player.message = -1;
			}
			else {
				HUlib_addMessageToSText(&w_message, 0, player.messagestring);
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

 
boolean HU_Responder(event_t *ev)
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
