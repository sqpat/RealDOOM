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
//	Main loop menu stuff.
//	Default Config File.
//

#include <fcntl.h>
#include <stdlib.h>

#include <ctype.h>


#include "doomdef.h"

#include "z_zone.h"

#include "w_wad.h"

#include "i_system.h"
#include "v_video.h"

#include "hu_stuff.h"

// State.
#include "doomstat.h"

// Data.
#include "dstrings.h"

#include "m_misc.h"
#include "m_memory.h"
#include "m_near.h"


//
// M_Random
// Returns a 0-255 number
//




uint8_t __far M_Random (void){
    rndindex = (rndindex+1)&0xff;
    return rndtable[rndindex];
}


 

void M_AddToBox16 ( int16_t __near*	box, int16_t	x, int16_t	y ) {
    if (x<box[BOXLEFT])
		  box[BOXLEFT] = x;
    else if (x>box[BOXRIGHT])
		  box[BOXRIGHT] = x;
    if (y<box[BOXBOTTOM])
		  box[BOXBOTTOM] = y;
    else if (y>box[BOXTOP])
		  box[BOXTOP] = y;
}
 
 
//
// M_WriteFile
//
#ifndef O_BINARY
#define O_BINARY 0
#endif

boolean M_WriteFile (int8_t const*	name, void __far*		source, filelength_t		length ){
    filelength_t		count;
	
    FILE* fp = fopen ( name, "wb");

    if (!fp){
	    return false;
    }

    count = FAR_fwrite (source, 1, length, fp);
    fclose (fp);
	
    if (count < length){
	    return false;
    }
    return true;
}


//
// M_ReadFile
//


filelength_t M_ReadFile (int8_t const*	name, byte __far*	buffer ){ 
    int32_t length;
	

    FILE* fp = fopen(name, "rb");
    fseek(fp, 0L, SEEK_END);
    length = ftell(fp);

/*
	if (fp == NULL){
		I_Error ("Couldn't read file %s", name);
    }
    */
    fseek(fp, 0L, SEEK_SET);
    FAR_fread(buffer, 1, length, fp);

    fclose (fp);

    return length;
}


//
// DEFAULTS
//




