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
//	Lookup tables.
//	Do not try to look them up :-).
//	In the order of appearance: 
//
//	 finetangent[4096]	- Tangens LUT.
//	 Should work with BAM fairly well (12 of 16bit,
//      effectively, by shifting).
//
//	 finesine(10240)		- Sine lookup.
//	 Guess what, serves as cosine, too.
//	 Remarkable thing is, how to use BAMs with this? 
//
//	 tantoangle[2049]	- ArcTan LUT,
//	  maps tan(angle) to angle fast. Gotta search.	
//    
//-----------------------------------------------------------------------------


#ifndef __TABLES__
#define __TABLES__

// basically, to reduce memory footprint by 30-40 KB we want to cut finesine tables
// down to 2048 entires and then generate the rest of the values for that and cosine based 
// on that. It's slower than a bigger lookup table for sure, but the savings of conventional
// memory will impact performance much more positively in the long run. The problem is,
// for each 2048 values shifted every 90 degrees theres a handful of off=by-one values.
// This does not really make DOOM play noticeably different, but a typical timedemo will
// diverge after a few hundred frames when one of those few angles incorrect angles is
// used. So we can special case those incorrect angles in a switch block for accuacy,
// but its slower of course. But it's still much faster overall to use that 30-40kb of
// memory on something else. This gives us full backwards compatibility with original
// doom timedemos - sqpat

// slower (involves function call) but backward comaptible with original doom.
#define USE_FUNCTION_TRIG


#define PI				3.141592657


#include "doomdef.h"
	
#define FINEANGLES		8192
#define FINEMASK		(FINEANGLES-1)

//#define finesine(x) (int32_t) (x < 2048 ? finesineinner[x] : x < 4096 ? finesineinner[2047-(x-2048)] : x < 6144 ? -(finesineinner[x-4096]) : x < 8192 ? -(finesineinner[2047-(x-6144)]) : finesineinner[x-8192] )
//#define finecosine(x) (x < 2048 ? finesineinner[2047-x] : x < 4096 ? -(finesineinner[(x-2048)]) : x < 6144 ? -(finesineinner[2047-(x-4096)]) : x < 8192 ? (finesineinner[(x-6144)]) : finesineinner[2047-(x-8192)] )

// for 2048
#define finesineexpr(x) (int32_t) (x < 2048 ? (int32_t)finesineinner[x] : x < 4096 ? (int32_t)finesineinner[2047-(x-2048)] : x < 6144 ? -((int32_t)finesineinner[x-4096]) :  -((int32_t)finesineinner[2047-(x-6144)]) )
#define finecosineexpr(x) (int32_t) (x < 2048 ? (int32_t)finesineinner[2047-x] : x < 4096 ? -((int32_t)finesineinner[(x-2048)]) : x < 6144 ? -((int32_t)finesineinner[2047-(x-4096)]) :  ((int32_t)finesineinner[(x-6144)])   )

#ifdef USE_FUNCTION_TRIG

int32_t fixedsine(int16_t x);

#define finesine(x) fixedsine(x)
#define finecosine(x) fixedsine((x+2048) & FINEMASK)

#else

#define finesine(x) finesineexpr(x)
#define finecosine(x) finecosineexpr(x)

#endif

#define finetangent(x) (x < 2048 ? finetangentinner[x] : -(finetangentinner[(2047-(x-2048))]) )


/*
#define finesine(x)  (finesineinner[x] )
#define finecosine(x)  (finesineinner[x+2048])
*/


// for 4096
/*
#define finesine(x) (int32_t) (x < 4096 ? finesineinner[x] : -finesineinner[4095-(x-4096)] )
#define finecosine(x) x > 6144 ? finesine(x-6144) : finesine(x+2048)
*/



// 0x100000000 to 0x2000
#define ANGLETOFINESHIFT	19		
#define SHORTTOFINESHIFT	3		

// Effective size is 10240.

#ifdef USE_FUNCTION_TRIG
#else

extern  uint16_t		finesineinner[2048];

#endif

// this one has no issues with mirroring 2nd half of values!
extern fixed_t		finetangentinner[2048];

// Binary Angle Measument, BAM.
#define ANG45			0x20000000u
#define ANG90			0x40000000u
#define ANG180			0x80000000u
#define ANG270			0xc0000000u

#define ANG45_HIGHBITS			0x2000u
#define ANG90_HIGHBITS			0x4000u
#define ANG180_HIGHBITS		0x8000u
#define ANG270_HIGHBITS		0xc000u

#define FINE_ANG45		0x400
#define FINE_ANG90	    0x800		    
#define FINE_ANG180		0x1000
#define FINE_ANG270		0x1800
#define FINE_ANG360		0x2000

#define MOD_FINE_ANGLE(x)  ((x & 0x1FFF))

#define SLOPERANGE		2048
#define SLOPEBITS		11
#define DBITS			(FRACBITS-SLOPEBITS)

typedef fixed_t_union_unsigned angle_t;
typedef fixed_t_union signed_angle_t;
typedef uint16_t fineangle_t;


// Effective size is 2049;
// The +1 size is to handle the case when x==y
//  without additional checking.
extern angle_t		tantoangle[SLOPERANGE + 1];
//extern signed_angle_t		tantoangle[SLOPERANGE+1];


#endif
