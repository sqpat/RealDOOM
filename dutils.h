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
//	Cheat code checking.
//

#ifndef __DUTILS__
#define __DUTILS__

#include "doomtype.h"
#include "doomdef.h"

 

//
// CHEAT SEQUENCE PACKAGE
//

#define SCRAMBLE(a) \
((((a)&1)<<7) + (((a)&2)<<5) + ((a)&4) + (((a)&8)<<1) \
 + (((a)&16)>>1) + ((a)&32) + (((a)&64)>>5) + (((a)&128)>>7))

typedef struct cheatseq_s {
    uint8_t __near*	sequence;
    uint8_t __near*	p;    
} cheatseq_t;

int8_t __near cht_CheckCheat ( cheatseq_t __near* cht, int8_t key );
void __near cht_GetParam ( cheatseq_t __near* cht, int8_t __near* buffer );

#endif
