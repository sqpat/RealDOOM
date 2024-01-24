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
//   Setup a game, startup stuff.
//

#ifndef __P_SETUP__
#define __P_SETUP__

// NOT called by W_Ticker. Fixme.
void
P_SetupLevel
( int8_t		episode,
  int8_t		map,
  skill_t	skill);

// Called by startup code.
void P_Init (void);
extern THINKERREF __far*		blocklinks;	// for thing chains

#endif
