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
//	 finesine[10240]		- Sine lookup.
//	 Guess what, serves as cosine, too.
//	 Remarkable thing is, how to use BAMs with this? 
//
//	 tantoangle[2049]	- ArcTan LUT,
//	  maps tan(angle) to angle fast. Gotta search.	
//    
//-----------------------------------------------------------------------------


#ifndef __TABLES__
#define __TABLES__

#define PI				3.141592657

#include "doomdef.h"
	
#define FINEANGLES		8192
#define FINEMASK		(FINEANGLES-1)


 



// 0x100000000 to 0x2000
#define ANGLETOFINESHIFT	19		
#define SHORTTOFINESHIFT	3		



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

typedef fixed_t_union angle_t;
typedef uint16_t fineangle_t;

// Effective size is 10240.

#define size_finesine		10240u * sizeof(int32_t)
#define size_finetangent	size_finesine +  2048u * sizeof(int32_t)
#define size_tantoangle		size_finetangent +  2049u * sizeof(int32_t)

//todo eventually move these tables down here...
//#define finesine			((int32_t __far*) 0x31FF0000)	// 10240
//#define finecosine			((int32_t __far*) 0x31FF2000)	// 10240 should end at 3BFF + 4 bytes, leaving 12 till 3C00 for DS

#define finesine			((int32_t __far*) 0x50000000)	// 10240
#define finecosine			((int32_t __far*) 0x50002000)	// 10240
#define finetangentinner	((int32_t __far*) (0x50000000 + size_finesine ))
#define tantoangle			((angle_t __far*) (0x50000000 + size_finetangent))


// this one has no issues with mirroring 2nd half of values!

#define finetangent(x) (x < 2048 ? finetangentinner[x] : -(finetangentinner[(2047-(x-2048))]) )


#endif
