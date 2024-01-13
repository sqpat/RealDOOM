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
//  DOOM Network game communication and protocol,
//  all OS independend parts.
//

#include "m_menu.h"
#include "i_system.h"
#include "g_game.h"
#include "doomdef.h"
#include "doomstat.h"

//
// NETWORKING
//
// gametic is the tic about to (or currently being) run
// maketic is the tick that hasn't had control made for it yet
// nettics[] has the maketics for all players
//
// a gametic cannot be run until nettics[] > gametic for all players
//
#define PL_DRONE 0x80 // bit flag in doomdata->player


ticcount_t nettics;

ticcount_t maketic;
ticcount_t skiptics;

void D_ProcessEvents(void);
void G_BuildTiccmd(int8_t index);

void D_DoAdvanceDemo(void);

//
// NetUpdate
// Builds ticcmds for console player,
// sends out a packet
//
ticcount_t gametime;

void NetUpdate(void)
{
	uint32_t nowtime;
	int32_t newtics;
	int32_t i;

	// check time
	nowtime = ticcount;
	newtics = nowtime - gametime;
	gametime = nowtime;

	if (newtics <= 0) // nothing new to update
		return;

	if (skiptics <= newtics)
	{
		newtics -= skiptics;
		skiptics = 0;
	}
	else
	{
		skiptics -= newtics;
		newtics = 0;
	}

	// build new ticcmds for console player
	for (i = 0; i < newtics; i++)
	{
		I_StartTic();
		D_ProcessEvents();
		if (maketic - gametic >= BACKUPTICS / 2 - 1) {
			break; // can't hold any more
		}

		G_BuildTiccmd(maketic & (BACKUPTICS - 1));
		maketic++;
	}

}

extern byte advancedemo;

void TryRunTics(void)
{
	int32_t entertic;
	static int32_t oldentertics;
	int32_t realtics;
	int32_t availabletics;
	int32_t counts;

	// get real tics
	entertic = ticcount;
	realtics = entertic - oldentertics;
	oldentertics = entertic;

	// get available tics
	NetUpdate();

	availabletics = maketic - gametic;

	// decide how many tics to run
	if (realtics + 1 < availabletics)
		counts = realtics + 1;
	else if (realtics < availabletics)
		counts = realtics;
	else
		counts = availabletics;

	if (counts < 1)
		counts = 1;

	// wait for new tics if needed
	while (maketic < gametic + counts)
	{
		NetUpdate();

		// don't stay in here forever -- give the menu a chance to work
		if (ticcount - entertic >= 20)
		{
			M_Ticker();
			return;
		}
	}

	// run the count dics
	while (counts--)
	{
		if (advancedemo)
			D_DoAdvanceDemo();
		M_Ticker();
		G_Ticker();
		gametic++;
		NetUpdate(); // check for new console commands
	}
}
