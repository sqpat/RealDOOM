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
//   Setup a game, startup stuff.
//

#ifndef __P_SETUP__
#define __P_SETUP__

// NOT called by W_Ticker. Fixme.


void __near P_SetupLevel ( int8_t episode, int8_t map, skill_t skill);


// Called by startup code.
void __near P_Init (void);

typedef uint8_t evtype_t;

// Event structure.
// todo 13 bytes gross. maybe re-align at least.
typedef struct {
    int16_t		data1;		// type high byte, keys / mouse buttons low byte
    int16_t		data2;		// mouse x move
} event_t;







#define    BOXTOP 0
#define    BOXBOTTOM 1
#define    BOXLEFT 2
#define    BOXRIGHT 3

typedef struct {

	fixed_t_union	x;
	fixed_t_union	y;
    fixed_t_union	dx;
	fixed_t_union	dy;
    
} divline_t;

typedef struct {

    fixed_t	frac;		// along trace line
    boolean	isaline;    // todo put this after...
    union {
		THINKERREF	thingRef;
	int16_t linenum;
    }			d;
} intercept_t;

typedef struct thinker_s {

	// functiontype is the five high bits

	// contains previous reference mixed with functin type (in the high five bits)
	THINKERREF	prevFunctype;
	THINKERREF	next;

	mobj_t			data;

} thinker_t;

#define MAPBLOCKUNITS	128
#define MAPBLOCKSIZE MAPBLOCKUNITS
#define MAPBLOCKSHIFT	7
#define playerMobj_posMakerExpression	((&mobjposlist_6800[playerMobjRef]))
#define playerMobjMakerExpression		((mobj_t __near *) (((byte __far*)thinkerlist) + (playerMobjRef*sizeof(thinker_t) + 2 * sizeof(THINKERREF))))


typedef struct {
  int8_t prev;
  int8_t next;
  
  // 0 for single page allocations. for multipage, 1 is the the last page of multipage
  // allocation and count up prev from there. allows us to idenitify connected pages in the cache
  int8_t pagecount; 

  int8_t numpages; // number of the pages in a multi page allocation

} cache_node_page_count_t;

typedef struct {
  int8_t prev;
  int8_t next;
  
  // flats are never anything but single page..
} cache_node_t;

#define MAXRADIUS		32*FRACUNIT
#define MAXRADIUSNONFRAC		32


#endif
