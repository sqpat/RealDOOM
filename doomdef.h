//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 1993-2008 Raven Software
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
//  Internally used data structures for virtually everything,
//   key definitions, lots of other stuff.
//

#ifndef __DOOMDEF__
#define __DOOMDEF__

#include <stdio.h>
#include <string.h>
#include "doomtype.h" 




//
// Global parameters/defines.
//
// DOOM version
enum { VERSION =  109 };

#define EXE_VERSION_1_9         0
#define EXE_VERSION_ULTIMATE    1
#define EXE_VERSION_FINAL       2
#define EXE_VERSION_FINAL2      3

#define EXE_VERSION EXE_VERSION_1_9


//#define LOOPCHECK


//
// For resize of screen, at start of game.
// It will not work dynamically, see visplanes.
//
#define	BASE_WIDTH		320

// It is educational but futile to change this
//  scaling e.g. to 2. Drawing of status bar,
//  menues etc. is tied to the scale implied
//  by the graphics.
#define	SCREEN_MUL		1
#define	INV_ASPECT_RATIO	0.625 // 0.75, ideally

// Defines suck. C sucks.
// C++ might sucks for OOP, but it sure is a better C.
// So there.
#define SCREENWIDTH  320
//SCREEN_MUL*BASE_WIDTH //320
#define SCREENHEIGHT 200
//(int32_t)(SCREEN_MUL*BASE_WIDTH*INV_ASPECT_RATIO) //200

#define	FRACBITS		16
#define	FRACUNIT		((int32_t)1<<FRACBITS)

//#define UNION_FIXED_POINT

typedef int32_t fixed_t32;

/* Basically, there are a number of things (sector floor and ceiling heights mainly) that
 in practice never end up with greater than 1/8th FRACUNIT precision. That happens with
  certain kinds of moving floors and ceilings. aside from that, they never really end up greater
 than ~ 500 height in practice. realistically, 10 bits integer + 3 of precision is already more
 than we need, we are keeping it at 13 and 3 for minimal shifting. Even though its a bit ugly,
 it's way less shifting (remember bigger shifts means more cpu cycles on 16 bit x86 processors )
 and way denser memory storage on many structs. short_height_t exists as a reminder as to when
 these fields are shifted and not just a standard int_16_t
 

 */
typedef int16_t short_height_t;



#define SHORTFLOORBITS 3

#ifdef UNION_FIXED_POINT


typedef union _fixed_t {
	struct dual_int16_t {
		int16_t fracbits;
		int16_t intbits;
	} h;
	
	int32_t w;
} fixed_t;


#define DECLARE_FIXED_POINT_HIGH(x, y) x = {0, y}
#define DECLARE_FIXED_POINT_LOW(x, y) x = {y, 0}
#define FIXED_T_PLUS_EQUALS(x, y) x.w += y
#define FIXED_T_MINUS_EQUALS(x, y) x.w -= y
#define FIXED_T_PLUS(x, y) x.w + y
#define FIXED_T_PLUS_FIXED_T(x, y) x.w + y.w
#define FIXED_T_MINUS(x, y) x.w - y
#define FIXED_T_MINUS_FIXED_T(x, y) x.w - y.w
#define FIXED_T_SHIFT_RIGHT(x, y) x.w >> y
#define FIXED_T_SET_FRACBITS(x, y) x.h.fracbits = y
#define FIXED_T_SET_WHOLE(x, y) x.w = y

#else

typedef int32_t fixed_t;

typedef union _longlong_union {
	int16_t h[4];	
	int64_t l;
} longlong_union;

typedef union _fixed_t_union {
	struct dual_int16_t {
		int16_t fracbits;
		int16_t intbits;
	} h;
	
	int32_t w;
} fixed_t_union;

#define DECLARE_FIXED_POINT_HIGH(x, y) x = y
#define DECLARE_FIXED_POINT_LOW(x, y) x = y

#define FIXED_T_PLUS_EQUALS(x, y) x += y
#define FIXED_T_MINUS_EQUALS(x, y) x -= y
#define FIXED_T_PLUS(x, y) (x + y)
#define FIXED_T_PLUS_FIXED_T(x, y) (x + y)
#define FIXED_T_MINUS(x, y) (x - y)
#define FIXED_T_MINUS_FIXED_T(x, y) (x - y)
#define FIXED_T_SHIFT_RIGHT(x, y) (x >> y)
#define FIXED_T_SET_FRACBITS(x, y) x = y
#define FIXED_T_SET_WHOLE(x, y) x = y
#endif


// The maximum number of players, multiplayer/networking.
#define MAXPLAYERS		4

// State updates, number of tics / second.
#define TICRATE		35

// The current state of the game: whether we are
// playing, gazing at the intermission screen,
// the game final animation, or a demo. 
#define    GS_LEVEL 0
#define    GS_INTERMISSION 1
#define    GS_FINALE 2
#define     GS_DEMOSCREEN 3
typedef uint8_t  gamestate_t;

//
// Difficulty/skill settings/filters.
//

// Skill flags.
#define	MTF_EASY		1
#define	MTF_NORMAL		2
#define	MTF_HARD		4

// Deaf monsters/do not react to sound.
#define	MTF_AMBUSH		8

#define sk_baby 0
#define sk_easy 1
#define sk_medium 2
#define sk_hard 3
#define sk_nightmare 4
typedef uint8_t skill_t;




//
// Key cards.
//
#define it_bluecard 0
#define it_yellowcard 1
#define it_redcard 2
#define it_blueskull 3
#define it_yellowskull 4
#define it_redskull 5
    
#define  NUMCARDS 6
    
typedef uint8_t card_t;



// The defined weapons,
//  including a marker indicating
//  user has not changed weapon.
#define wp_fist 0
#define wp_pistol 1
#define wp_shotgun 2
#define wp_chaingun 3
#define wp_missile 4
#define wp_plasma 5
#define wp_bfg 6
#define wp_chainsaw 7
#define wp_supershotgun 8

#define NUMWEAPONS 9
	// No pending weapon change.

#define wp_nochange 10

typedef uint8_t weapontype_t;

// Ammunition types defined.
#define am_clip 0	// Pistol / chaingun ammo.
#define am_shell 1	// Shotgun / double barreled shotgun.
#define am_cell 2	// Plasma rifle, BFG.
#define am_misl 3	// Missile launcher.
#define NUMAMMO 4
#define am_noammo 5	// Unlimited for chainsaw / fist.	

typedef uint8_t ammotype_t;

// Power up artifacts.
#define pw_invulnerability 0
#define pw_strength 1
#define pw_invisibility 2
#define pw_ironfeet 3
#define pw_allmap 4
#define pw_infrared 5
#define NUMPOWERS 6
    
typedef uint8_t powertype_t;



//
// Power up durations,
//  how many seconds till expiration,
//  assuming TICRATE is 35 ticks/second.
//
#define INVULNTICS	 (30*TICRATE)
#define INVISTICS	 (60*TICRATE)
#define INFRATICS	 (120*TICRATE)
#define IRONTICS	 (60*TICRATE)
    




//
// DOOM keyboard definition.
// This is the stuff configured by Setup.Exe.
// Most key data are simple ascii (uppercased).
//
#define KEY_RIGHTARROW	0xae
#define KEY_LEFTARROW	0xac
#define KEY_UPARROW	0xad
#define KEY_DOWNARROW	0xaf
#define KEY_ESCAPE	27
#define KEY_ENTER	13
#define KEY_TAB		9
#define KEY_F1		(0x80+0x3b)
#define KEY_F2		(0x80+0x3c)
#define KEY_F3		(0x80+0x3d)
#define KEY_F4		(0x80+0x3e)
#define KEY_F5		(0x80+0x3f)
#define KEY_F6		(0x80+0x40)
#define KEY_F7		(0x80+0x41)
#define KEY_F8		(0x80+0x42)
#define KEY_F9		(0x80+0x43)
#define KEY_F10		(0x80+0x44)
#define KEY_F11		(0x80+0x57)
#define KEY_F12		(0x80+0x58)

#define KEY_BACKSPACE	127
#define KEY_PAUSE	0xff

#define KEY_EQUALS	0x3d
#define KEY_MINUS	0x2d

#define KEY_RSHIFT	(0x80+0x36)
#define KEY_RCTRL	(0x80+0x1d)
#define KEY_RALT	(0x80+0x38)

#define KEY_LALT	KEY_RALT

fixed_t32	FixedMul (fixed_t32 a, fixed_t32 b);
int16_t	FixedMul1632 (int16_t a, fixed_t b);
fixed_t32	FixedDiv (fixed_t32 a, fixed_t32 b);
fixed_t32	FixedDiv2 (fixed_t32 a, fixed_t32 b);



#ifdef _M_I86
#define intx86(a, b, c) int86(a, b, c)
#define intx86x(a, b, c, d) int86x(a, b, c, d)
#else
#define intx86(a, b, c) int386(a, b, c)
#define intx86x(a, b, c, d) int386x(a, b, c, d)
#endif



// DOOM basic types (boolean),
//  and max/min values.
//#include "doomtype.h"

// Fixed point.
//#include "m_fixed.h"

// Endianess handling.
//#include "m_swap.h"


// Binary Angles, sine/cosine/atan lookups.
//#include "tables.h"

// Event type.
//#include "d_event.h"

// Game function, skills.
//#include "g_game.h"

// All external data is defined here.
//#include "doomdata.h"

// All important printed strings.
// Language selection (message strings).
//#include "dstrings.h"

// Player is a special actor.
//struct player_s;


//#include "d_items.h"
//#include "d_player.h"
//#include "p_mobj.h"
//#include "d_net.h"

// PLAY
//#include "p_tick.h"




// Header, generated by sound utility.
// The utility was written by Dave Taylor.
//#include "sounds.h"






#endif          // __DOOMDEF__
