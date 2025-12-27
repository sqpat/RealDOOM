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
//   Duh.
//

#ifndef __G_GAME__
#define __G_GAME__

#include "doomdef.h"

#define SLOWTURNTICS    6 


//
// GAME
//

void __near G_InitNew (skill_t skill, int8_t episode, int8_t map);






// Called by M_Responder.
void __far G_SaveGame (int8_t slot, int8_t __far* description);

boolean __far G_CheckDemoStatus (void);

void __far G_ExitLevel (void);
void __far G_SecretExitLevel (void);


void __near G_Ticker (void);
uint16_t   __near  R_TextureNumForName(int8_t* __near name);
uint16_t  __near   R_CheckTextureNumForName(int8_t __near *  name);


#endif
