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

boolean  st_stopped = true;

// ST_Start() has just been called
extern boolean          st_firsttime;

// used to execute ST_Init() only once

// lump number for PLAYPAL
//int16_t              lu_palette;
extern MEMREF               palRef;

// used for timing


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

extern int8_t st_palette;



// ?
void
STlib_initNum
(st_number_t*		n,
	int16_t			x,
	int16_t			y,
	MEMREF*		plRef,
	int16_t			width)
{
	n->x = x;
	n->y = y;
	n->oldnum = 0;
	n->width = width;
	n->pRef = plRef;
}


//
void
STlib_initPercent
(st_percent_t*		p,
	int16_t			x,
	int16_t			y,
	MEMREF*		plRef,
	MEMREF		percentRef) {
	STlib_initNum(&p->n, x, y, plRef, 3);
	p->pRef = percentRef;
}



void
STlib_initMultIcon
(st_multicon_t*	i,
	int16_t			x,
	int16_t			y,
	MEMREF*		ilRef)
{
	i->x = x;
	i->y = y;
	i->oldinum = -1;
	i->pRef = ilRef;

}


void ST_createWidgets(void)
{

	int8_t i;

	// ready weapon ammo
	STlib_initNum(&w_ready,
		ST_AMMOX,
		ST_AMMOY,
		tallnumRef,
		ST_AMMOWIDTH);



	// health percentage
	STlib_initPercent(&w_health,
		ST_HEALTHX,
		ST_HEALTHY,
		tallnumRef,
		tallpercentRef);

	// arms background
	STlib_initMultIcon(&w_armsbg,
		ST_ARMSBGX,
		ST_ARMSBGY,
		armsbgRef);
	w_armsbg.oldinum = 0; // hack to make it work as multicon instead of binicon

	// weapons owned
	for (i = 0; i < 6; i++)
	{
		STlib_initMultIcon(&w_arms[i],
			ST_ARMSX + (i % 3)*ST_ARMSXSPACE,
			ST_ARMSY + (i / 3)*ST_ARMSYSPACE,
			armsRef[i]);




	}



	// faces
	STlib_initMultIcon(&w_faces,
		ST_FACESX,
		ST_FACESY,
		facesRef);

	// armor percentage - should be colored later
	STlib_initPercent(&w_armor,
		ST_ARMORX,
		ST_ARMORY,
		tallnumRef,
		tallpercentRef);

	// keyboxes 0-2
	STlib_initMultIcon(&w_keyboxes[0],
		ST_KEY0X,
		ST_KEY0Y,
		keysRef);

	STlib_initMultIcon(&w_keyboxes[1],
		ST_KEY1X,
		ST_KEY1Y,
		keysRef);

	STlib_initMultIcon(&w_keyboxes[2],
		ST_KEY2X,
		ST_KEY2Y,
		keysRef);

	// ammo count (all four kinds)
	STlib_initNum(&w_ammo[0],
		ST_AMMO0X,
		ST_AMMO0Y,
		shortnumRef,
		ST_AMMO0WIDTH);

	STlib_initNum(&w_ammo[1],
		ST_AMMO1X,
		ST_AMMO1Y,
		shortnumRef,
		ST_AMMO1WIDTH);

	STlib_initNum(&w_ammo[2],
		ST_AMMO2X,
		ST_AMMO2Y,
		shortnumRef,
		ST_AMMO2WIDTH);

	STlib_initNum(&w_ammo[3],
		ST_AMMO3X,
		ST_AMMO3Y,
		shortnumRef,
		ST_AMMO3WIDTH);

	// max ammo count (all four kinds)
	STlib_initNum(&w_maxammo[0],
		ST_MAXAMMO0X,
		ST_MAXAMMO0Y,
		shortnumRef,
		ST_MAXAMMO0WIDTH);

	STlib_initNum(&w_maxammo[1],
		ST_MAXAMMO1X,
		ST_MAXAMMO1Y,
		shortnumRef,
		ST_MAXAMMO1WIDTH);

	STlib_initNum(&w_maxammo[2],
		ST_MAXAMMO2X,
		ST_MAXAMMO2Y,
		shortnumRef,
		ST_MAXAMMO2WIDTH);

	STlib_initNum(&w_maxammo[3],
		ST_MAXAMMO3X,
		ST_MAXAMMO3Y,
		shortnumRef,
		ST_MAXAMMO3WIDTH);

}



void ST_Stop(void)
{
	//MEMREF palRef;
	byte*       pal;
	if (st_stopped)
		return;

	//palRef = W_CacheLumpNumEMS(lu_palette, PU_CACHE);
	pal = (byte*)Z_LoadBytesFromEMS(palRef);
	I_SetPalette(0);

	//	I_SetPalette(W_CacheLumpNum(lu_palette, PU_CACHE));

	st_stopped = true;
}


void ST_Start(void)
{
	int8_t         i;

	if (!st_stopped)
		ST_Stop();

	st_firsttime = true;
	st_gamestate = FirstPersonState;
	st_statusbaron = true;

	st_faceindex = 0;
	st_palette = -1;
	st_oldhealth = -1;

	for (i = 0; i < NUMWEAPONS; i++)
		oldweaponsowned[i] = player.weaponowned[i];

	for (i = 0; i < 3; i++)
		keyboxes[i] = -1;


	ST_createWidgets();
	st_stopped = false;

}