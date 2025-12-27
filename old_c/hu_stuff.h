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
// DESCRIPTION:  Head up display
//

#ifndef __HU_STUFF_H__
#define __HU_STUFF_H__

#include "r_defs.h"




#define HU_BROADCAST	5

#define HU_MSGREFRESH	KEY_ENTER
#define HU_MSGX		0
#define HU_MSGY		0
#define HU_MSGWIDTH	64	// in characters
#define HU_MSGHEIGHT	1	// in lines
#define HU_INPUTY HU_MSGY + HUD_FONTHEIGHT
#define HU_MSGTIMEOUT	(4*TICRATE)

//
// HEADS UP TEXT
//

void __near HU_Init(void);
void __far HU_Start(void);

boolean __near HU_Responder(event_t __far* ev);

void __near HU_Ticker(void);
void __near HU_Drawer(void);
void __near HU_Erase(void);
 


#endif
