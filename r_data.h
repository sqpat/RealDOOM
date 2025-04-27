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
//  Refresh module, data I/O, caching, retrieval of graphics
//  by name.
//

#ifndef __R_DATA__
#define __R_DATA__

#include "r_defs.h"
#include "r_state.h"

// Retrieve column data for span blitting.


#define CACHETYPE_SPRITE	0
#define CACHETYPE_FLAT		1
#define CACHETYPE_PATCH		2
#define CACHETYPE_COMPOSITE	3


typedef struct {
  int8_t prev;
  int8_t next;
  
  // 0 for single page allocations. for multipage, 1 is the the last page of multipage
  // allocation and count up prev from there. allows us to idenitify connected pages in the cache
  int8_t pagecount; 
  int8_t numpages; // number of the pages in a multi page allocation
  //uint8_t value; // lump, value, etc
} cache_node_page_count_t;

typedef struct {
  int8_t prev;
  int8_t next;
  
  // flats are never anything but single page..
} cache_node_t;


int8_t __far R_EvictFlatCacheEMSPage();
int8_t __near R_EvictCacheEMSPage(int8_t numpages, int8_t cachetype);
void __near R_MarkL2CacheLRU(int8_t index, int8_t numpages, int8_t cachetype);
void __far R_MarkL2FlatCacheLRU(int8_t index);

//segment_t __near R_GetColumnSegment ( int16_t tex, int16_t col, int8_t segloopcachetype );
segment_t __far R_GetMaskedColumnSegment ( int16_t tex, int16_t col );
segment_t __far getspritetexture(int16_t index);

#define BAD_TEXTURE 65535

// I/O, setting up the stuff.
void __near R_InitData (void);
void R_PrecacheLevel (void);


void R_LoadPatchColumns(uint16_t lump, segment_t texlocationsegment, boolean ismasked);
void R_LoadSpriteColumns(uint16_t lump, segment_t destpatchsegment);
 
#define TEXTURE_TYPE_PATCH 1
#define TEXTURE_TYPE_COMPOSITE 2
#define TEXTURE_TYPE_SPRITE 3

 

#endif
