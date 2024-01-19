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

// offsets within segment stored
uint16_t hu_font[HU_FONTSIZE]  ={ 8468,
	8368, 8252, 8124, 7980, 7848,
	7788, 7668, 7548, 7452, 7376,
	7316, 7236, 7180, 7080, 6948,
	6864, 6724, 6592, 6476, 6352,
	6220, 6100, 5960, 5828, 5744,
	5672, 5592, 5512, 5432, 5304,
	5148, 5016, 4876, 4736, 4604,
	4472, 4344, 4212, 4076, 4004,
	3884, 3744, 3624, 3476, 3340,
	3216, 3088, 2952, 2812, 2692,
	2572, 2440, 2332, 2184, 2024,
	1900, 1772, 1680, 1580, 1488,
	1392, 1288
};



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

// todo change to 8 bit + offset

#define title_string_offset HUSTR_E1M1

uint8_t	mapnames[] =	// DOOM shareware/registered/retail (Ultimate) names.
{

	HUSTR_E1M1 - title_string_offset,
	HUSTR_E1M2 - title_string_offset,
	HUSTR_E1M3 - title_string_offset,
	HUSTR_E1M4 - title_string_offset,
	HUSTR_E1M5 - title_string_offset,
	HUSTR_E1M6 - title_string_offset,
	HUSTR_E1M7 - title_string_offset,
	HUSTR_E1M8 - title_string_offset,
	HUSTR_E1M9 - title_string_offset,

	HUSTR_E2M1 - title_string_offset,
	HUSTR_E2M2 - title_string_offset,
	HUSTR_E2M3 - title_string_offset,
	HUSTR_E2M4 - title_string_offset,
	HUSTR_E2M5 - title_string_offset,
	HUSTR_E2M6 - title_string_offset,
	HUSTR_E2M7 - title_string_offset,
	HUSTR_E2M8 - title_string_offset,
	HUSTR_E2M9 - title_string_offset,

	HUSTR_E3M1 - title_string_offset,
	HUSTR_E3M2 - title_string_offset,
	HUSTR_E3M3 - title_string_offset,
	HUSTR_E3M4 - title_string_offset,
	HUSTR_E3M5 - title_string_offset,
	HUSTR_E3M6 - title_string_offset,
	HUSTR_E3M7 - title_string_offset,
	HUSTR_E3M8 - title_string_offset,
	HUSTR_E3M9 - title_string_offset,

	HUSTR_E4M1 - title_string_offset,
	HUSTR_E4M2 - title_string_offset,
	HUSTR_E4M3 - title_string_offset,
	HUSTR_E4M4 - title_string_offset,
	HUSTR_E4M5 - title_string_offset,
	HUSTR_E4M6 - title_string_offset,
	HUSTR_E4M7 - title_string_offset,
	HUSTR_E4M8 - title_string_offset,
	HUSTR_E4M9 - title_string_offset,

	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset
};

int16_t	mapnames2[] =	// DOOM 2 map names.
{
	HUSTR_1 - title_string_offset,
	HUSTR_2 - title_string_offset,
	HUSTR_3 - title_string_offset,
	HUSTR_4 - title_string_offset,
	HUSTR_5 - title_string_offset,
	HUSTR_6 - title_string_offset,
	HUSTR_7 - title_string_offset,
	HUSTR_8 - title_string_offset,
	HUSTR_9 - title_string_offset,
	HUSTR_10 - title_string_offset,
	HUSTR_11 - title_string_offset,

	HUSTR_12 - title_string_offset,
	HUSTR_13 - title_string_offset,
	HUSTR_14 - title_string_offset,
	HUSTR_15 - title_string_offset,
	HUSTR_16 - title_string_offset,
	HUSTR_17 - title_string_offset,
	HUSTR_18 - title_string_offset,
	HUSTR_19 - title_string_offset,
	HUSTR_20 - title_string_offset,

	HUSTR_21 - title_string_offset,
	HUSTR_22 - title_string_offset,
	HUSTR_23 - title_string_offset,
	HUSTR_24 - title_string_offset,
	HUSTR_25 - title_string_offset,
	HUSTR_26 - title_string_offset,
	HUSTR_27 - title_string_offset,
	HUSTR_28 - title_string_offset,
	HUSTR_29 - title_string_offset,
	HUSTR_30 - title_string_offset,
	HUSTR_31 - title_string_offset,
	HUSTR_32 - title_string_offset
};

#if (EXE_VERSION >= EXE_VERSION_FINAL)
int16_t	mapnamesp[] =	// Plutonia WAD map names.
{
	PHUSTR_1 - title_string_offset,
	PHUSTR_2 - title_string_offset,
	PHUSTR_3 - title_string_offset,
	PHUSTR_4 - title_string_offset,
	PHUSTR_5 - title_string_offset,
	PHUSTR_6 - title_string_offset,
	PHUSTR_7 - title_string_offset,
	PHUSTR_8 - title_string_offset,
	PHUSTR_9 - title_string_offset,
	PHUSTR_10 - title_string_offset,
	PHUSTR_11 - title_string_offset,

	PHUSTR_12 - title_string_offset,
	PHUSTR_13 - title_string_offset,
	PHUSTR_14 - title_string_offset,
	PHUSTR_15 - title_string_offset,
	PHUSTR_16 - title_string_offset,
	PHUSTR_17 - title_string_offset,
	PHUSTR_18 - title_string_offset,
	PHUSTR_19 - title_string_offset,
	PHUSTR_20 - title_string_offset,

	PHUSTR_21 - title_string_offset,
	PHUSTR_22 - title_string_offset,
	PHUSTR_23 - title_string_offset,
	PHUSTR_24 - title_string_offset,
	PHUSTR_25 - title_string_offset,
	PHUSTR_26 - title_string_offset,
	PHUSTR_27 - title_string_offset,
	PHUSTR_28 - title_string_offset,
	PHUSTR_29 - title_string_offset,
	PHUSTR_30 - title_string_offset,
	PHUSTR_31 - title_string_offset,
	PHUSTR_32 - title_string_offset
};


int16_t mapnamest[] =	// TNT WAD map names.
{
	THUSTR_1 - title_string_offset,
	THUSTR_2 - title_string_offset,
	THUSTR_3 - title_string_offset,
	THUSTR_4 - title_string_offset,
	THUSTR_5 - title_string_offset,
	THUSTR_6 - title_string_offset,
	THUSTR_7 - title_string_offset,
	THUSTR_8 - title_string_offset,
	THUSTR_9 - title_string_offset,
	THUSTR_10 - title_string_offset,
	THUSTR_11 - title_string_offset,

	THUSTR_12 - title_string_offset,
	THUSTR_13 - title_string_offset,
	THUSTR_14 - title_string_offset,
	THUSTR_15 - title_string_offset,
	THUSTR_16 - title_string_offset,
	THUSTR_17 - title_string_offset,
	THUSTR_18 - title_string_offset,
	THUSTR_19 - title_string_offset,
	THUSTR_20 - title_string_offset,

	THUSTR_21 - title_string_offset,
	THUSTR_22 - title_string_offset,
	THUSTR_23 - title_string_offset,
	THUSTR_24 - title_string_offset,
	THUSTR_25 - title_string_offset,
	THUSTR_26 - title_string_offset,
	THUSTR_27 - title_string_offset,
	THUSTR_28v
	THUSTR_29 - title_string_offset,
	THUSTR_30 - title_string_offset,
	THUSTR_31 - title_string_offset,
	THUSTR_32 - title_string_offset
};
#endif



extern boolean		message_on;
extern boolean			message_dontfuckwithme;
extern boolean		message_nottobefuckedwith;
extern hu_stext_t	w_message;
extern uint8_t		message_counter;

extern hu_textline_t	w_title;

void HU_Start(void)
{



	//
	// Builtin map names.
	// The actual names can be found in DStrings.h.
	//

 

	// int32_t		i;
	int16_t	sindex;
	int8_t s[256];
	int16_t s_index = 0;
	int16_t HU_TITLEY;
	int16_t HU_INPUTY;
	int16_t i;
	hu_textline_t near*	t;
	uint16_t			fontheight = 7;// might not work with custom wad?
	uint16_t			lineheight = 8;//might not work with custom wad?


	HU_TITLEY = (167 - fontheight);
	HU_INPUTY = (HU_MSGY + lineheight);

	message_on = false;
	message_dontfuckwithme = false;
	message_nottobefuckedwith = false;
	// create the message widget





	w_message.height = 1;
	w_message.on = &message_on;
	w_message.laston = true;
	w_message.currentline = 0;
	
	t = &w_message.textlines[0];
	t->x = HU_MSGX;
	t->y = HU_MSGY;
	t->sc = HU_FONTSTART;

	t->len = 0;
	t->characters[0] = 0;
	t->needsupdate = true;


	



	// create the map title widget

	w_title.x = HU_TITLEX;
	w_title.y = HU_TITLEY;
	w_title.sc = HU_FONTSTART;
	w_title.len = 0;
	w_title.characters[0] = 0;
	w_title.needsupdate = true;


	if (commercial) {
#if (EXE_VERSION < EXE_VERSION_FINAL)
		sindex = HU_TITLE2;
#else
		if (plutonia) {
			sindex = HU_TITLEP;
		} else if (tnt) {
			sindex = HU_TITLET;
		} else {
			sindex = HU_TITLE2;
		}
#endif
	} else {
		sindex = HU_TITLE;
	}
	sindex += title_string_offset;


	getStringByIndex(sindex, s);

	while (s[s_index]) {
		HUlib_addCharToTextLine(&w_title, (s[s_index++]));
	}



}
