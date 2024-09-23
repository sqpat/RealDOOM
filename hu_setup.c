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
#include "m_near.h"



//
// Locally used constants, shortcuts.
//
#define HUD_FONTHEIGHT 7
#define HUD_LINEHEIGHT HUD_FONTHEIGHT + 1

#define HU_TITLE	(mapnames[(gameepisode-1)*9+gamemap-1])
#define HU_TITLE2	(mapnames2[gamemap-1])
#define HU_TITLEP	(mapnamesp[gamemap-1])
#define HU_TITLET	(mapnamest[gamemap-1])
#define HU_TITLEHEIGHT	1
#define HU_TITLEX	0
#define HU_TITLEY   167 - HUD_FONTHEIGHT


#define HU_INPUTTOGGLE	't'
#define HU_INPUTX	HU_MSGX
#define HU_INPUTWIDTH	64
#define HU_INPUTHEIGHT	1

#define title_string_offset HUSTR_E1M1




void __far HU_Start(void) {

	//
	// Builtin map names.
	// The actual names can be found in DStrings.h.
	//

	// int32_t		i;
	int16_t	sindex;
	int8_t str[256];
	hu_textline_t __near*	t;


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


	getStringByIndex(sindex, str);

	HUlib_addStringToTextLine(&w_title, str);



}
