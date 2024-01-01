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
typedef struct
{
    // Should be "IWAD" or "PWAD".
	int8_t		identification[4];
    int32_t			numlumps;
	int32_t			infotableofs;
    
} wadinfo_t;


typedef struct
{
	int32_t			filepos;
	int32_t			size;
	int8_t		name[8];
    
} filelump_t;

//
// WADFILE I/O related stuff.
//
typedef struct
{
	int8_t	name[8];
#ifdef	SUPPORT_MULTIWAD
	int8_t	handleindex;
#endif
	// (probably could cap at 16 bit and use high bit as sizediff)
    int32_t		position; 
	// dont know if this might have to change to int16_t at some point, but basically this is the diff between declared lump size and diff of adjacent positions. I think the wad is (annoyingly) made with some overlapping items. saves us 3 bytes per lump still.
	int8_t	sizediff; 
	//int32_t		size;  // calculate size from next position minus your own plus diff.
} lumpinfo_t;


extern	lumpinfo_t*	lumpinfo;
extern	uint16_t		numlumps;

void    W_InitMultipleFiles (int8_t** filenames);

int16_t	W_CheckNumForName (int8_t* name);
int16_t	W_GetNumForName(int8_t* name);
//int16_t W_GetNumForName2(int8_t* name, int8_t*file, int line);
//#define W_GetNumForName(a) W_GetNumForName2(a, __FILE__, __LINE__)

int32_t	W_LumpLength (int16_t lump);

int16_t W_CacheLumpNumCheck(int16_t lump);
//MEMREF  W_CacheLumpNumEMS2(int16_t lump, int8_t tag, int8_t* file, int32_t line);
MEMREF  W_CacheLumpNumEMS(int16_t lump, int8_t tag);

//#define W_CacheLumpNumEMS(a, b) W_CacheLumpNumEMS2(a, b)
//#define W_CacheLumpNumEMS(a, b) W_CacheLumpNumEMS2(a, b, __FILE__, __LINE__)

MEMREF  W_CacheLumpNameEMSFragment(int8_t* name, int8_t tag, int16_t pagenum, int32_t offset);
void W_EraseFullscreenCache();

void W_CacheLumpNameDirect(int8_t* name, byte* dest);
void W_CacheLumpNumDirect(int16_t lump, byte* dest);
MEMREF  W_CacheLumpNameEMS(int8_t* name, int8_t tag);
//MEMREF  W_CacheLumpNameEMS2(int8_t* name, int8_t tag	, int8_t* file, int32_t line );
//#define W_CacheLumpNameEMS(a, b) W_CacheLumpNameEMS2(a, b, __FILE__, __LINE__)


void	W_EraseLumpCache(int16_t index);
patch_t* W_CacheLumpNameEMSAsPatch (int8_t*         name, int8_t           tag);

// correct value for DOOM Sharware
#define LUMPINFO_SIZE 16432 
#define LUMPCACHE_SIZE 2528 
//#define LUMPCACHE_SIZE sizeof(MEMREF) * 1036


#endif
