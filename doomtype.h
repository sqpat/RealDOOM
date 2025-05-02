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
//	Simple basic typedefs, isolated here to make it easier
//	 separating modules.
//


#ifndef __DOOMTYPE__
#define __DOOMTYPE__



#ifndef __FIXEDTYPES__
#define __FIXEDTYPES__
typedef signed char				int8_t;
typedef unsigned char			uint8_t;
typedef short					int16_t;
typedef unsigned short			uint16_t;
typedef long					int32_t;
typedef unsigned long			uint32_t;
typedef long long				int64_t;
typedef unsigned long long		uint64_t;
#endif

typedef uint16_t filelength_t;
typedef int32_t ticcount_t;
typedef uint16_t texsize_t;

typedef uint16_t segment_t;


#ifndef __BYTEBOOL__
#define __BYTEBOOL__
// Fixed to use builtin bool type with C++.
#ifdef __cplusplus
typedef bool boolean;
#else
typedef enum { false, true } boolean;
#endif
typedef uint8_t byte;
#endif


#define MAXCHAR		((int8_t)0x7f)
#define MAXSHORT	((int16_t)0x7fff)

// Max pos 32-bit int.
#define MAXLONG		((int32_t)0x7fffffffL)
#define MINCHAR		((int8_t)0x80)

// Max negative 32-bit integer.
#define MINLONG		((int32_t)0x80000000L)
#define MINSHORT	((int16_t)0x8000)


// let's avoid 'int' due to it being unclear between 16 and 32 bit
//#define MAXINT		((int32_t)0x7fffffff)	
//#define MININT		((int32_t)0x80000000)	





//#define UNION_FIXED_POINT

typedef int32_t fixed_t32;

/* Basically, there are a number of things (sector floor and ceiling heights mainly) that
 in practice never end up with greater than 1/8th FRACUNIT precision. That happens with
  certain kinds of moving floors and ceilings. aside from that, they never really end up greater
 than ~ 900 height in practice. realistically, 10 bits integer + 3 of precision is already more
 than we need, we are keeping it at 13 and 3 for minimal shifting. Even though its a bit ugly,
 it's way less shifting (remember bigger shifts means more cpu cycles on 16 bit x86 processors )
 and way denser memory storage on many structs. short_height_t exists as a reminder as to when
 these fields are shifted and not just a standard int_16_t


 */
typedef int16_t short_height_t;



#define SHORTFLOORBITS 3
#define SHORTFLOORBITMASK 0x0007
//#define SHORTFLOORBITS 4
//#define SHORTFLOORBITMASK 0x0F

//#define SET_FIXED_UNION_FROM_SHORT_HEIGHT(x, y) x.h.intbits = y >> SHORTFLOORBITS; x.h.fracbits = (y & SHORTFLOORBITMASK) << (8 - SHORTFLOORBITS)
#define SET_FIXED_UNION_FROM_SHORT_HEIGHT(x, y) x.h.intbits = y >> SHORTFLOORBITS; x.h.fracbits = (y & SHORTFLOORBITMASK) << (16 - SHORTFLOORBITS)

//#define SET_FIXED_UNION_FROM_SHORT_HEIGHT(x, y) x.h.intbits = y; x.h.fracbits = 0; x.w >>= SHORTFLOORBITS;

// old version bugged   6144
// old version bugfixed 6146

//new version 6187
 

typedef int32_t fixed_t;
typedef int16_t fixed_16_t;
#define FIXED_16_T_FRAC_BITS 4
#define	FRAC_16_UNIT		1 << (16 - FIXED_16_T_FRAC_BITS)

typedef union _longlong_union {
	int16_t h[4];

	struct productresult_t {
		int16_t throwawayhigh;
		int32_t usemid;
		int16_t throwawaylow;
	} productresult;


	struct productresult_small_t {
		int16_t throwawayhigh;
		int16_t usemid_high;
		int32_t usemid_low;
		int8_t throwawaylow;
	} productresult_small;

	int64_t l;
} longlong_union;

typedef union _fixed_t_union {
	uint32_t wu;
	int32_t w;

	struct dual_int16_t {
		int16_t fracbits;
		int16_t intbits;
	} h;

	struct dual_uuint16_t {
		uint16_t fracbits;
		uint16_t intbits;
	} hu;

	struct quad_int8_t {
		int8_t fracbytelow;
		int8_t fracbytehigh;
		int8_t intbytelow;
		int8_t intbytehigh;
	} b;

	struct quad_uint8_t {
		uint8_t fracbytelow;
		uint8_t fracbytehigh;
		uint8_t intbytelow;
		uint8_t intbytehigh;
	} bu;

	struct productresult_mid_t {
		int8_t throwawayhigh;		// errr these are reversed.
		int16_t usemid;
		int8_t throwawaylow;
	} productresult_mid;

} fixed_t_union;

 
 


typedef union _int16_t_union {
	uint16_t hu;
	int16_t h;

	struct dual_int8_t {
		int8_t bytelow;
		int8_t bytehigh;
	} b;

	struct dual_uint8_t {
		uint8_t bytelow;
		uint8_t bytehigh;
	} bu;

} int16_t_union;








typedef union _reg_return_4word {

	uint64_t qword;

	struct int16_t_values_ {
		int16_t dx;
		int16_t cx;
		int16_t bx;
		int16_t ax;
	} w;

	struct int8_t_values_ {
		int8_t dl;
		int8_t dh;
		int8_t cl;
		int8_t ch;
		int8_t bl;
		int8_t bh;
		int8_t al;
		int8_t ah;
	
	} h;

} 
reg_return_4word;


#endif

