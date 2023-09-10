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
    filelength_t			infotableofs;
    
} wadinfo_t;


typedef struct
{
    filelength_t			filepos;
    filelength_t			size;
	int8_t		name[8];
    
} filelump_t;

//
// WADFILE I/O related stuff.
//
typedef struct
{
	int8_t	name[8];
    filehandle_t		handle;
    int32_t		position;
    filelength_t		size;
} lumpinfo_t;


extern	lumpinfo_t*	lumpinfo;
extern	uint16_t		numlumps;

void    W_InitMultipleFiles (int8_t** filenames);
void    W_Reload (void);

int16_t	W_CheckNumForName (int8_t* name);
int16_t	W_GetNumForName(int8_t* name);
//int16_t W_GetNumForName2(int8_t* name, int8_t*file, int line);
//#define W_GetNumForName(a) W_GetNumForName2(a, __FILE__, __LINE__)

filelength_t	W_LumpLength (int16_t lump);
void    W_ReadLumpStatic (int16_t lump, void *dest);

int16_t W_CacheLumpNumCheck(int16_t lump, int16_t error);
MEMREF  W_CacheLumpNumEMS(int16_t lump, int8_t tag);
MEMREF  W_CacheLumpNameEMSFragment(int8_t* name, int8_t tag, int16_t pagenum, int32_t offset);

MEMREF  W_CacheLumpNameEMS(int8_t* name, int8_t tag);
void	W_EraseLumpCache(int16_t index);
patch_t* W_CacheLumpNameEMSAsPatch (int8_t*         name, int8_t           tag);



#endif
