
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
//	Gamma correction LUT stuff.
//	Functions to draw patches (by post) directly to screen.
//	Functions to blit a block to the screen.
//


#include "i_system.h"
#include "r_local.h"

#include "doomdef.h"
#include "doomdata.h"

#include "m_misc.h"

#include "v_video.h"
#include "w_wad.h"
#include <dos.h>
#include <conio.h>
#include "memory.h"


