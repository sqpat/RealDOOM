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
#ifdef _M_I86
typedef long					int32_t;
typedef unsigned long			uint32_t;
#else
typedef int						int32_t;
typedef unsigned int			uint32_t;
#endif
typedef long long				int64_t;
typedef unsigned long long		uint64_t;
#endif


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
#define MAXINT		((int32_t)0x7fffffff)	
#define MAXLONG		((int32_t)0x7fffffff)
#define MINCHAR		((int8_t)0x80)
#define MINSHORT	((int16_t)0x8000)

// Max negative 32-bit integer.
#define MININT		((int32_t)0x80000000)	
#define MINLONG		((int32_t)0x80000000)





#endif
