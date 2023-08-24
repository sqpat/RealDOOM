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
//  MapObj data. Map Objects or mobjs are actors, entities,
//  thinker, take-your-pick... anything that moves, acts, or
//  suffers state changes of more or less violent nature.
//

#ifndef __D_THINK__
#define __D_THINK__

#include "z_zone.h"

//
// Experimental stuff.
// To compile this as "ANSI C with classes"
//  we will need to handle the various
//  action functions cleanly.
//
typedef  void (*actionf_v)();
typedef  void (*actionf_p1)( void* );
typedef  void (*actionf_p2)( void*, void* );

typedef union
{
  actionf_p1	acp1;
  actionf_v	acv;
  actionf_p2	acp2;

} actionf_t;





// Historically, "think_t" is yet another
//  function pointer to a routine to handle
//  an actor.
//typedef actionf_t  think_t;

typedef unsigned short THINKERREF;
typedef unsigned char  THINKFUNCTION;

#define TF_NULL				0
#define TF_MOBJTHINKER		1
#define TF_PLATRAISE        2
#define TF_MOVECEILING		3
#define TF_VERTICALDOOR		4
#define TF_MOVEFLOOR        5
#define TF_FIREFLICKER      6
#define TF_LIGHTFLASH       7
#define TF_STROBEFLASH      8
#define TF_GLOW             9


#define TF_DELETEME         255

// Doubly linked list of actors.
typedef struct thinker_s
{
	THINKERREF	prev;
	THINKERREF	next;
	//MEMREF		prev;
	//MEMREF		next;
	THINKFUNCTION functionType;

	MEMREF		memref;		// needed to delete the 'owner' of the thinker. All thinkers are owned by a memref controlled allocations..
    
} thinker_t;




#endif
