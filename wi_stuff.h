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
//  Intermission.
//

#ifndef __WI_STUFF__
#define __WI_STUFF__

//#include "v_video.h"

#include "doomdef.h"

// States for the intermission

#define NoState -1
#define StatCount 0
#define ShowNextLoc 1

typedef int8_t stateenum_t;

// Called by main loop, animate the intermission.
//void __far WI_Ticker (void);
// Called by main loop,
// draws the intermission directly into the screen buffer.
//void __far WI_Drawer (void);
// Setup for an intermission screen.
//void __far WI_Start(wbstartstruct_t __near*	 wbstartstruct, boolean playerdidsecret);


typedef uint8_t animenum_t;

// in practice the used values are all 8 bit, 0 - 224
typedef struct {
    uint8_t		x;
    uint8_t		y;
    
} point_t;

// 20 bytes each .. 10, 9, 6 of them so 25 * 20 = 500 bytes total.
//
// Animation.
//
typedef struct {
    animenum_t	type;

    // period in tics between animations
    uint8_t		period;

    // number of animation frames
    int8_t		nanims;

    // location of animation
    point_t	loc;

    // ALWAYS: n/a,
    // RANDOM: period deviation (<256),
    // LEVEL: level
	// in practice values up to 8 are used
    int8_t		data1;

    // ALWAYS: n/a,
    // RANDOM: random base period,
    // LEVEL: n/a

    // actual graphics for frames of animations
	int16_t	pRef[3];

    // following must be initialized to zero before use!

    // next value of bcnt (used in conjunction with period)
    uint16_t		nexttic;

    // last drawn animation frame

    // next frame number to animate
    int8_t		ctr;
    
    // used by RANDOM and LEVEL when animating
    uint8_t		state;  

} wianim_t;

#endif
