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

//
// Locally used constants, shortcuts.
//
#define HU_TITLE	(mapnames[(gameepisode-1)*9+gamemap-1])
#define HU_TITLE2	(mapnames2[gamemap-1])
#define HU_TITLEP	(mapnamesp[gamemap-1])
#define HU_TITLET	(mapnamest[gamemap-1])
#define HU_TITLEHEIGHT	1
#define HU_TITLEX	0

#define HU_INPUTTOGGLE	't'
#define HU_INPUTX	HU_MSGX
#define HU_INPUTWIDTH	64
#define HU_INPUTHEIGHT	1

 

MEMREF		hu_fontRef[HU_FONTSIZE];
static hu_textline_t	w_title;

static boolean		message_on;
boolean			message_dontfuckwithme;
static boolean		message_nottobefuckedwith;

static hu_stext_t	w_message;
static uint8_t		message_counter;

extern uint8_t		showMessages;
extern boolean		automapactive;


//
// Builtin map names.
// The actual names can be found in DStrings.h.
//

int16_t	mapnames[] =	// DOOM shareware/registered/retail (Ultimate) names.
{

    HUSTR_E1M1,
    HUSTR_E1M2,
    HUSTR_E1M3,
    HUSTR_E1M4,
    HUSTR_E1M5,
    HUSTR_E1M6,
    HUSTR_E1M7,
    HUSTR_E1M8,
    HUSTR_E1M9,

    HUSTR_E2M1,
    HUSTR_E2M2,
    HUSTR_E2M3,
    HUSTR_E2M4,
    HUSTR_E2M5,
    HUSTR_E2M6,
    HUSTR_E2M7,
    HUSTR_E2M8,
    HUSTR_E2M9,

    HUSTR_E3M1,
    HUSTR_E3M2,
    HUSTR_E3M3,
    HUSTR_E3M4,
    HUSTR_E3M5,
    HUSTR_E3M6,
    HUSTR_E3M7,
    HUSTR_E3M8,
    HUSTR_E3M9,

    HUSTR_E4M1,
    HUSTR_E4M2,
    HUSTR_E4M3,
    HUSTR_E4M4,
    HUSTR_E4M5,
    HUSTR_E4M6,
    HUSTR_E4M7,
    HUSTR_E4M8,
    HUSTR_E4M9,

	NEWLEVELMSG,
	NEWLEVELMSG,
	NEWLEVELMSG,
	NEWLEVELMSG,
	NEWLEVELMSG,
	NEWLEVELMSG,
	NEWLEVELMSG,
	NEWLEVELMSG,
	NEWLEVELMSG
};

int16_t	mapnames2[] =	// DOOM 2 map names.
{
    HUSTR_1,
    HUSTR_2,
    HUSTR_3,
    HUSTR_4,
    HUSTR_5,
    HUSTR_6,
    HUSTR_7,
    HUSTR_8,
    HUSTR_9,
    HUSTR_10,
    HUSTR_11,
	
    HUSTR_12,
    HUSTR_13,
    HUSTR_14,
    HUSTR_15,
    HUSTR_16,
    HUSTR_17,
    HUSTR_18,
    HUSTR_19,
    HUSTR_20,
	
    HUSTR_21,
    HUSTR_22,
    HUSTR_23,
    HUSTR_24,
    HUSTR_25,
    HUSTR_26,
    HUSTR_27,
    HUSTR_28,
    HUSTR_29,
    HUSTR_30,
    HUSTR_31,
    HUSTR_32
};

#if (EXE_VERSION >= EXE_VERSION_FINAL)
int16_t	mapnamesp[] =	// Plutonia WAD map names.
{
    PHUSTR_1,
    PHUSTR_2,
    PHUSTR_3,
    PHUSTR_4,
    PHUSTR_5,
    PHUSTR_6,
    PHUSTR_7,
    PHUSTR_8,
    PHUSTR_9,
    PHUSTR_10,
    PHUSTR_11,
	
    PHUSTR_12,
    PHUSTR_13,
    PHUSTR_14,
    PHUSTR_15,
    PHUSTR_16,
    PHUSTR_17,
    PHUSTR_18,
    PHUSTR_19,
    PHUSTR_20,
	
    PHUSTR_21,
    PHUSTR_22,
    PHUSTR_23,
    PHUSTR_24,
    PHUSTR_25,
    PHUSTR_26,
    PHUSTR_27,
    PHUSTR_28,
    PHUSTR_29,
    PHUSTR_30,
    PHUSTR_31,
    PHUSTR_32
};


int16_t mapnamest[] =	// TNT WAD map names.
{
    THUSTR_1,
    THUSTR_2,
    THUSTR_3,
    THUSTR_4,
    THUSTR_5,
    THUSTR_6,
    THUSTR_7,
    THUSTR_8,
    THUSTR_9,
    THUSTR_10,
    THUSTR_11,
	
    THUSTR_12,
    THUSTR_13,
    THUSTR_14,
    THUSTR_15,
    THUSTR_16,
    THUSTR_17,
    THUSTR_18,
    THUSTR_19,
    THUSTR_20,
	
    THUSTR_21,
    THUSTR_22,
    THUSTR_23,
    THUSTR_24,
    THUSTR_25,
    THUSTR_26,
    THUSTR_27,
    THUSTR_28,
    THUSTR_29,
    THUSTR_30,
    THUSTR_31,
    THUSTR_32
};
#endif
 
 

void HU_Init(void)
{

    int16_t		i;
    int16_t		j;
	int8_t	buffer[9];


    // load the heads-up font
    j = HU_FONTSTART;
    for (i=0;i<HU_FONTSIZE;i++) {
		sprintf(buffer, "STCFN%.3d", j++);
		hu_fontRef[i] = W_CacheLumpNameEMS(buffer, PU_STATIC);
    }




}
 

void HU_Start(void)
{

    // int32_t		i;
    int16_t	sindex;
	int8_t* s;
	patch_t* hu_font0; 
	int16_t HU_TITLEY;
	int16_t HU_INPUTY;
	int16_t i;
	patch_t* font0;
	hu_textline_t*	t;
	hu_font0 = (patch_t*) Z_LoadBytesFromEMS(hu_fontRef[0]);
	HU_TITLEY = (167 - (hu_font0->height));
	HU_INPUTY = (HU_MSGY + HU_MSGHEIGHT * ((hu_font0->height) + 1));

    message_on = false;
    message_dontfuckwithme = false;
    message_nottobefuckedwith = false;
    // create the message widget

	
 


	w_message.h = HU_MSGHEIGHT;
	w_message.on = &message_on;
	w_message.laston = true;
	w_message.cl = 0;
	font0 = (patch_t*)Z_LoadBytesFromEMS(hu_fontRef[0]);
	for (i = 0; i < HU_MSGHEIGHT; i++) {
		t = &w_message.l[i];
		t->x = HU_MSGX;
		t->y = HU_MSGY - i * ((font0->height) + 1);
		t->fRef = hu_fontRef;
		t->sc = HU_FONTSTART;

		t->len = 0;
		t->l[0] = 0;
		t->needsupdate = true;


	}



    // create the map title widget
 
	w_title.x = HU_TITLEX;
	w_title.y = HU_TITLEY;
	w_title.fRef = hu_fontRef;
	w_title.sc = HU_FONTSTART;
	w_title.len = 0;
	w_title.l[0] = 0;
	w_title.needsupdate = true;


    if (commercial)
    {
#if (EXE_VERSION < EXE_VERSION_FINAL)
        sindex = HU_TITLE2;
#else
        if (plutonia)
        {
			sindex = HU_TITLEP;
        }
        else if (tnt)
        {
			sindex = HU_TITLET;
        }
        else
        {
			sindex = HU_TITLE2;
        }
#endif
    }
    else
    {
		sindex = HU_TITLE;
    }
    
	s = alloca(256);

	getStringByIndex(sindex, s);

    while (*s)
		HUlib_addCharToTextLine(&w_title, *(s++));




}

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
