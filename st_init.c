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
//      Status bar code.
//      Does the face/direction indicator animatin.
//      Does palette indicators as well (red pain/berserk, bright pickup)
//


#include <stdio.h>

#include "i_system.h"
#include "z_zone.h"
#include "m_misc.h"
#include "w_wad.h"

#include "doomdef.h"

#include "g_game.h"

#include "st_stuff.h"
#include "st_lib.h"
#include "r_local.h"

#include "p_local.h"
#include "p_inter.h"

#include "am_map.h"
#include "dutils.h"

#include "s_sound.h"

// Needs access to LFB.
#include "v_video.h"

// State.
#include "doomstat.h"

// Data.
#include "dstrings.h"
#include "sounds.h"

//
// STATUS BAR DATA
//



#define ST_NUMPAINFACES         5
#define ST_NUMSTRAIGHTFACES     3
#define ST_NUMTURNFACES         2
#define ST_NUMSPECIALFACES              3
#define ST_NUMEXTRAFACES                2

#define ST_FACESTRIDE \
          (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)
#define ST_NUMFACES \
          (ST_FACESTRIDE*ST_NUMPAINFACES+ST_NUMEXTRAFACES)

extern MEMREF               palRef;

// whether in automap or first-person
extern st_stateenum_t   st_gamestate;

// whether left-side main status bar is active
extern boolean          st_statusbaron;

// main bar left
extern MEMREF         sbarRef;

// 0-9, tall numbers
extern MEMREF         tallnumRef[10];

// tall % sign
extern MEMREF         tallpercentRef;

// 0-9, short, yellow (,different!) numbers
extern MEMREF         shortnumRef[10];

// 3 key-cards, 3 skulls
extern MEMREF         keysRef[NUMCARDS];

// face status patches
extern MEMREF         facesRef[ST_NUMFACES];

// face background
extern MEMREF         facebackRef;

// main bar right
extern MEMREF         armsbgRef[1];

// weapon ownership patches
extern MEMREF	armsRef[6][2];

// ready-weapon widget
extern st_number_t      w_ready;


// health widget
extern st_percent_t     w_health;

// arms background
extern st_multicon_t     w_armsbg;
//extern st_binicon_t     w_armsbg;


// weapon ownership widgets
extern st_multicon_t    w_arms[6];

// face status widget
extern st_multicon_t    w_faces;

// keycard widgets
extern st_multicon_t    w_keyboxes[3];

// armor widget
extern st_percent_t     w_armor;

// ammo widgets
extern st_number_t      w_ammo[4];

// max ammo widgets
extern st_number_t      w_maxammo[4];




// used to use appopriately pained face
extern int16_t      st_oldhealth;

// used for evil grin
extern boolean  oldweaponsowned[NUMWEAPONS];

// count until face changes
extern int16_t      st_facecount;

// current face index, used by w_faces
extern int16_t      st_faceindex;

// holds key-type for each key box on bar
extern int16_t      keyboxes[3];

// a random number per tick
extern uint8_t      st_randomnumber;




void ST_loadGraphics(void)
{

	int8_t         i;
	int8_t         j;
	int16_t         facenum;

	int8_t        namebuf[9];

	// Load the numbers, tall and short
	for (i = 0; i < 10; i++)
	{
		sprintf(namebuf, "STTNUM%d", i);
		tallnumRef[i] = W_CacheLumpNameEMS(namebuf, PU_STATIC);

		sprintf(namebuf, "STYSNUM%d", i);
		shortnumRef[i] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
	}

	// Load percent key.
	//Note: why not load STMINUS here, too?
	tallpercentRef = W_CacheLumpNameEMS("STTPRCNT", PU_STATIC);

	// key cards
	for (i = 0; i < NUMCARDS; i++)
	{
		sprintf(namebuf, "STKEYS%d", i);
		keysRef[i] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
	}

	// arms background
	armsbgRef[0] = W_CacheLumpNameEMS("STARMS", PU_STATIC);

	// arms ownership widgets
	for (i = 0; i < 6; i++)
	{
		sprintf(namebuf, "STGNUM%d", i + 2);

		// gray #
		armsRef[i][0] = W_CacheLumpNameEMS(namebuf, PU_STATIC);

		// yellow #
		armsRef[i][1] = shortnumRef[i + 2];
	}

	// face backgrounds for different color players
	sprintf(namebuf, "STFB0");
	facebackRef = W_CacheLumpNameEMS(namebuf, PU_STATIC);

	// status bar background bits
	sbarRef = W_CacheLumpNameEMS("STBAR", PU_STATIC);

	// face states
	facenum = 0;
	for (i = 0; i < ST_NUMPAINFACES; i++)
	{
		for (j = 0; j < ST_NUMSTRAIGHTFACES; j++)
		{
			sprintf(namebuf, "STFST%d%d", i, j);
			facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
		}
		sprintf(namebuf, "STFTR%d0", i);        // turn right
		facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
		sprintf(namebuf, "STFTL%d0", i);        // turn left
		facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
		sprintf(namebuf, "STFOUCH%d", i);       // ouch!
		facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
		sprintf(namebuf, "STFEVL%d", i);        // evil grin ;)
		facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
		sprintf(namebuf, "STFKILL%d", i);       // pissed off
		facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
	}
	facesRef[facenum++] = W_CacheLumpNameEMS("STFGOD0", PU_STATIC);
	facesRef[facenum++] = W_CacheLumpNameEMS("STFDEAD0", PU_STATIC);

}

void ST_loadData(void)
{
	int16_t lu_palette = W_GetNumForName("PLAYPAL");
	palRef = W_CacheLumpNumEMS(lu_palette, PU_CACHE);

	ST_loadGraphics();
}

void ST_Init(void)
{
	ST_loadData();
	screen4Ref = Z_MallocEMS(ST_WIDTH*ST_HEIGHT, PU_STATIC, 0, ALLOC_TYPE_SCREEN);

}
