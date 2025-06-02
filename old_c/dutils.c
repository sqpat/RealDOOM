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
//  Cheat sequence checking.
//

#include "dutils.h"
#include "i_system.h"
#include "z_zone.h"
#include "m_near.h"

//
// Called in st_stuff module, which handles the input.
// Returns a 1 if the cheat was successful, 0 if failed.
//
/*
int8_t __near cht_CheckCheat ( int8_t cheatId, int8_t key ) { 
	int8_t rc = 0;
    cheatseq_t __near* cht = all_cheats[cheatId];

    if (!cht->p){
	    cht->p = cht->sequence; // initialize if first time
    }
    if (*cht->p == 0){
	    *(cht->p++) = key;
    } else if ((uint8_t)key == *cht->p) { 
        cht->p++;
    } else {
	    cht->p = cht->sequence;
    }

    if (*cht->p == 1){
	    cht->p++;
    } else if (*cht->p == 0xff){ // end of sequence character
        cht->p = cht->sequence;
        rc = 1;
    }


    return rc;
}

void __near cht_GetParam ( int8_t cheatId, int8_t __near* buffer ) {

    uint8_t *p, c;
    cheatseq_t __near* cht = all_cheats[cheatId];

    p = cht->sequence;
    while (*(p++) != 1);
    
    do {
        c = *p;
        *(buffer++) = c;
        *(p++) = 0;
    } while (c && *p!=0xff );

    if (*p==0xff)
	    *buffer = 0;

}
*/


