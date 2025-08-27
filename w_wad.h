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
//	WAD I/O functions.
//


#ifndef __W_WAD__
#define __W_WAD__
#include "r_defs.h"


//
// TYPES
//
typedef struct {
    // Should be "IWAD" or "PWAD".
	int8_t		identification[4];
    int32_t			numlumps;
	int32_t			infotableofs;
    
} wadinfo_t;


typedef struct {
	int32_t			filepos;
	int32_t			size;
	int8_t		name[8];
    
} filelump_t;

//
// WADFILE I/O related stuff.
//



// (OLD) 13 bytes each. LUMP_PER_EMS_PAGE is 1260
// (NOW) 16 bytes each. LUMP_PER_EMS_PAGE is 1024
//#define LUMP_PER_EMS_PAGE 16384 / sizeof(lumpinfo_t)
#define LUMP_PER_EMS_PAGE 1024

typedef struct {
	int8_t	name[8];
    int32_t		position; 
	// int8_t	sizediff;  // calculate size from next position minus your own plus diff.
	int32_t		size;  
} lumpinfo_t;



//#define lumpinfo4000 ((lumpinfo_t __far*) 0x44000000)


int16_t	__near W_CheckNumForName (int8_t __far* name);
int16_t	__far W_GetNumForName(int8_t __far* name);

int32_t	__far W_LumpLength (int16_t lump);


void __far W_CacheLumpNumDirectFragment(int16_t lump, byte __far* dest, int32_t offset);

void __far W_CacheLumpNameDirect(int8_t __near* name, byte __far* dest);
void __far W_CacheLumpNameDirectFarString (int8_t __far* name, byte __far* dest );

void __far W_CacheLumpNumDirect(int16_t lump, byte __far* dest);
void __far W_CacheLumpNumDirectWithOffset (int16_t lump, byte __far* dest, uint16_t offset, uint16_t length);


// correct value for DOOM Sharware
#define LUMPINFO_SIZE 16432 
//#define LUMPCACHE_SIZE 2528 
 

#endif
