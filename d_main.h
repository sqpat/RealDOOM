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
//	System specific interface stuff.
//

#ifndef __D_MAIN__
#define __D_MAIN__

#include "d_event.h"

#define MAXWADFILES             3
extern int8_t*		wadfiles[MAXWADFILES];

void D_DoomMain (void);

// Called by IO functions when input is detected.
void D_PostEvent (event_t far* ev);

#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
	#define BGCOLOR         7
	#define FGCOLOR         8
#else
	#define BGCOLOR         7
	#define FGCOLOR         4
#endif


//
// BASE LEVEL
//
void D_PageTicker (void);
void D_PageDrawer (void);
void D_AdvanceDemo (void);
void D_StartTitle (void);




void D_DoomLoop(void);

#endif
