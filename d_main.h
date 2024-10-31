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


void __near D_DoomMain (void);

// Called by IO functions when input is detected.
void __near D_PostEvent (event_t __far* ev);


//
// BASE LEVEL
//
void __near D_PageTicker (void);
void __near D_PageDrawer (void);
void __far D_StartTitle (void);




void __near D_DoomLoop(void);

#endif
