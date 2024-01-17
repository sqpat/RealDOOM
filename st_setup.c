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
#include "st_stuff.h"

boolean  st_stopped = true;
uint16_t armsbgarray[1] = { armsbg };
// ST_Start() has just been called
extern boolean          st_firsttime;

// used to execute ST_Init() only once

// lump number for PLAYPAL
//int16_t              lu_palette;
 
// used for timing

 



// ?
void
STlib_initNum
(st_number_t near*		n,
	int16_t			x,
	int16_t			y,
	uint16_t near*		pl,
	int16_t			width)
{
	n->x = x;
	n->y = y;
	n->oldnum = 0;
	n->width = width;
	n->patchoffset = pl;
}


//
void
STlib_initPercent
(st_percent_t near*		p,
	int16_t			x,
	int16_t			y,
	uint16_t near*		pl,
	uint16_t		percent) {
	STlib_initNum(&p->num, x, y, pl, 3);
	p->patchoffset = percent;
}



void
STlib_initMultIcon
(st_multicon_t near*	i,
	int16_t			x,
	int16_t			y,
	uint16_t near*		il)
{
	i->x = x;
	i->y = y;
	i->oldinum = -1;
	i->patchoffset = il;

}


void ST_createWidgets(void)
{

	int8_t i;

	// ready weapon ammo
	STlib_initNum(&w_ready,
		ST_AMMOX,
		ST_AMMOY,
		tallnum,
		ST_AMMOWIDTH);



	// health percentage
	STlib_initPercent(&w_health,
		ST_HEALTHX,
		ST_HEALTHY,
		tallnum,
		tallpercent);

	// arms background
	STlib_initMultIcon(&w_armsbg,
		ST_ARMSBGX,
		ST_ARMSBGY,
		armsbgarray);
	w_armsbg.oldinum = 0; // hack to make it work as multicon instead of binicon

	// weapons owned
	for (i = 0; i < 6; i++)
	{
		STlib_initMultIcon(&w_arms[i],
			ST_ARMSX + (i % 3)*ST_ARMSXSPACE,
			ST_ARMSY + (i / 3)*ST_ARMSYSPACE,
			arms[i]);




	}



	// faces
	STlib_initMultIcon(&w_faces,
		ST_FACESX,
		ST_FACESY,
		faces);

	// armor percentage - should be colored later
	STlib_initPercent(&w_armor,
		ST_ARMORX,
		ST_ARMORY,
		tallnum,
		tallpercent);

	// keyboxes 0-2
	STlib_initMultIcon(&w_keyboxes[0],
		ST_KEY0X,
		ST_KEY0Y,
		keys);

	STlib_initMultIcon(&w_keyboxes[1],
		ST_KEY1X,
		ST_KEY1Y,
		keys);

	STlib_initMultIcon(&w_keyboxes[2],
		ST_KEY2X,
		ST_KEY2Y,
		keys);

	// ammo count (all four kinds)
	STlib_initNum(&w_ammo[0],
		ST_AMMO0X,
		ST_AMMO0Y,
		shortnum,
		ST_AMMO0WIDTH);

	STlib_initNum(&w_ammo[1],
		ST_AMMO1X,
		ST_AMMO1Y,
		shortnum,
		ST_AMMO1WIDTH);

	STlib_initNum(&w_ammo[2],
		ST_AMMO2X,
		ST_AMMO2Y,
		shortnum,
		ST_AMMO2WIDTH);

	STlib_initNum(&w_ammo[3],
		ST_AMMO3X,
		ST_AMMO3Y,
		shortnum,
		ST_AMMO3WIDTH);

	// max ammo count (all four kinds)
	STlib_initNum(&w_maxammo[0],
		ST_MAXAMMO0X,
		ST_MAXAMMO0Y,
		shortnum,
		ST_MAXAMMO0WIDTH);

	STlib_initNum(&w_maxammo[1],
		ST_MAXAMMO1X,
		ST_MAXAMMO1Y,
		shortnum,
		ST_MAXAMMO1WIDTH);

	STlib_initNum(&w_maxammo[2],
		ST_MAXAMMO2X,
		ST_MAXAMMO2Y,
		shortnum,
		ST_MAXAMMO2WIDTH);

	STlib_initNum(&w_maxammo[3],
		ST_MAXAMMO3X,
		ST_MAXAMMO3Y,
		shortnum,
		ST_MAXAMMO3WIDTH);

}



void ST_Stop(void)
{
	if (st_stopped)
		return;

	I_SetPalette(0);

	st_stopped = true;
}

extern int8_t st_palette;

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
