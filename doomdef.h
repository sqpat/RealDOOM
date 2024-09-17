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
#include "d_math.h" 




//
// Global parameters/defines.
//
// DOOM version
enum { VERSION =  109 };

#define VERSION_STRING "1.09"

#define EXE_VERSION_1_9         0
#define EXE_VERSION_ULTIMATE    1
#define EXE_VERSION_FINAL       2
#define EXE_VERSION_FINAL2      3

#define EXE_VERSION EXE_VERSION_1_9

// MAIN FEATURE FLAGS

// line opening caching. Doesn't measurably affect runtime performance. Uses extra memory and code so i guess lets keep it off.
//#define PRECALCULATE_OPENINGS

// Prints startup messages. Good for development, turn off to save a little bit of binary size (~2k)
#define DEBUG_PRINTING

#ifdef DEBUG_PRINTING
	#define DEBUG_PRINT(...) printf(__VA_ARGS__)
#else
	#define DEBUG_PRINT(...) 
#endif

// Print player fields by tic to file. useful for debugging 16 vs 32 bit demo playback
//#define DEBUGLOG_TO_FILE

// Error checking. recommended ON during development. however, turning this off makes the binary like 10-12k smaller
//#define CHECK_FOR_ERRORS

// Debug flag which checks integrity of the EMS allocations data structures. Recommended to stay off for performance, on for development
//#define CHECKREFS

// skips fwipe (screen wipe)
//#define SKIPWIPE

// more detailed timedemo numbers
//#define DETAILED_BENCH_STATS

// turn on FPS display
//#define FPS_DISPLAY

// Sets some viewpoitn calculations to 16 bit and less precision than 32 bit. not super obvious, but if you run against a wall up close the wall texture pixels will move less smoothly with the player bob for example
#define USE_SHORTHEIGHT_VIEWZ	

// Load P_SETUP and P_SIGHT source dynamically into upper regions . if you enable these, move p_setup/p_sight to newsegments at start of linker file
//#define MOVE_P_SETUP
//#define MOVE_P_SIGHT


//
// For resize of screen, at start of game.
// It will not work dynamically, see visplanes.
//
#define	BASE_WIDTH		320

// It is educational but futile to change this
//  scaling e.g. to 2. Drawing of status bar,
//  menues etc. is tied to the scale implied
//  by the graphics.
#define	INV_ASPECT_RATIO	0.625 // 0.75, ideally

// Defines suck. C sucks.
// C++ might sucks for OOP, but it sure is a better C.
// So there.
#define SCREENWIDTH  320
#define SCREENWIDTHOVER2  160
#define SCREENHEIGHT 200u

#define	FRACBITS		16
#define	FRACUNIT		0x10000L

#define TAG_1323		56
#define TAG_1044		57
#define TAG_86			58
#define TAG_77			59
#define TAG_99			60
#define TAG_666			61
#define TAG_667			62
#define TAG_999			63

// ?? tag 99? make them all 63 or under?

// The maximum number of players, multiplayer/networking.

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

// todo make this optimized version of fixedmul 
//#define FixedMul2424(a,b) FixedMul(a, b) 
//#define FixedMul2432(a,b) FixedMul(a, b)

// sine/cosine LUT values go in b. This is 16 or 17 bits max - can be like a 24 bit mult except we can 0 check the high 8 bits and maybe just do 2 bytes of mult

typedef uint16_t fineangle_t;

// NoShift variant takes in an offset (index shifted by 2 already for dword lookup). 
// We do this because shifts are a little slow and we would be shifting right then left again in many cases.
fixed_t32	FixedMulTrig(uint16_t trigtype, fineangle_t fineangle, fixed_t32 b);
fixed_t32	FixedMulTrigNoShift(uint16_t trigtype, uint16_t fineanglelookup, fixed_t32 b);


#pragma aux speedfuncparams \
                    __modify [ax bx cx dx];

#pragma aux (speedfuncparams)  FixedMulTrigSpeed;
#pragma aux (speedfuncparams)  FixedMulTrigSpeedNoShift;
fixed_t32	FixedMulTrigSpeed(uint16_t trigtype, fineangle_t fineangle, int8_t speed);
fixed_t32	FixedMulTrigSpeedNoShift(uint16_t trigtype, uint16_t fineanglelookup, int8_t speed);


#pragma aux trig16params \
                    __modify [bx] \
                    __parm [ax] [dx] [bx] \
                    __value [dx ax];
#pragma aux (trig16params)  FastMulTrig16;

fixed_t32	FastMulTrig16(uint16_t trigtype, fineangle_t fineangle, int16_t b);

//fixed_t32	FixedMulTrig16(uint16_t trigtype, fineangle_t fineangle, int16_t b);
//fixed_t32	FixedMulTrigOld(fixed_t32 a, fixed_t32 b);
fixed_t32	FixedMul1632(int16_t a, fixed_t32 b);
fixed_t32	FixedMulBig1632(int16_t a, fixed_t b);
fixed_t32	FixedMul (fixed_t32 a, fixed_t32 b);
fixed_t32	FixedMul2424(fixed_t32 a, fixed_t32 b);
fixed_t32	FixedMul2432(fixed_t32 a, fixed_t32 b);


fixed_t32	FixedMul16u32(uint16_t a, fixed_t32 b);
fixed_t32	FixedMul16u32u(uint16_t a, uint32_t b);
// 
fixed_t32   FastMul16u32u(uint16_t a, uint32_t b);
// i think its correct that the sign extends dont play a factor in this..
#define     FastMul16u32(a, b)  FastMul16u32u(a, b)
#define     FastMul8u32(a, b)   FastMul16u32(a, b)
//todo
#define     FastMul1632u(a, b)  FastMul16u32u(a, b)


//#define SET_FIXED_UNION_FROM_SHORT_HEIGHT(x, y) x.h.intbits = y >> SHORTFLOORBITS; x.h.fracbits = (y & SHORTFLOORBITMASK) << (16 - SHORTFLOORBITS)

/*

// the result of this is wrong for some reason (?)
// also generates huge code. perhaps because the compiled code must shift DX/CX/AX registers around to fit this.
// could there be a better way, where this can work with any registers? no reason it has to be dx/cx/ax

fixed_t_union SET_FIXED_UNION_FROM_SHORT_HEIGHT(fixed_t_union a, int16_t b);
#pragma aux SET_FIXED_UNION_FROM_SHORT_HEIGHT =   \
"MOV DX, CX" \
"XOR AX, AX" \
"SAR DX, 1"  \
"RCR AX, 1"  \
"SAR DX, 1"  \
"RCR AX, 1"  \
"SAR DX, 1"  \
"RCR AX, 1"  \
    parm [dx ax] [cx] \
    modify [dx ax]   \
    value [dx ax];
    */


// 1 if negative, 0 if positive.


inline int8_t ROLAND1(int16_t a);
#pragma aux ROLAND1 =   \
"ROL AX, 1"  \
"AND AX, 1"  \
    parm [ax] \
    modify [ax]   \
    value [al];

#define FastMul8u32u(a, b) FastMul16u32u(a, b)
//fixed_t32   FastMul16u32(uint16_t a, uint32_t b);

// puts int16 into the high bits of a 32 bit
// puts int16 into the low bits of a 32 bit
//fixed_t32	FixedMul1616(int16_t a, int16_t b);

// just standard 16 * 16 = 32 IMUL 
inline fixed_t32 FastMul1616(int16_t a, int16_t b);
#pragma aux FastMul1616 =   \
"IMUL DX"  \
    parm [ax] [dx]       \
    modify [ax dx]   \
    value [dx ax];

inline uint32_t FastMul16u16u(uint16_t a, uint16_t b);
#pragma aux FastMul16u16u =   \
"MUL DX"  \
    parm [ax] [dx]       \
    modify [ax dx]   \
    value [dx ax];

inline uint16_t DIV3216RESULT(uint32_t a, uint16_t b);
#pragma aux DIV3216RESULT =   \
"DIV BX"  \
    parm [dx ax] [bx]       \
    modify [ax bx dx]   \
    value [ax];

inline uint16_t DIV3216REMAINDER(uint32_t a, uint16_t b);
#pragma aux DIV3216REMAINDER =   \
"DIV BX"  \
    parm [dx ax] [bx]       \
    modify [ax bx dx]   \
    value [dx];



inline uint32_t DIV3216RESULTREMAINDER(uint32_t a, uint16_t b);
#pragma aux DIV3216RESULTREMAINDER =   \
"DIV BX"  \
    parm [dx ax] [bx]       \
    modify [ax dx]   \
    value [dx ax];

inline uint16_t FastMul8u8u(uint8_t a, uint8_t b);
#pragma aux FastMul8u8u =   \
"MUL ah"  \
    parm [al] [ah]       \
    modify [ah al]   \
    value [ax];



fixed_t32	FixedDiv(fixed_t32 a, fixed_t32 b);
fixed_t32	FastDiv3232(fixed_t32 a, fixed_t32 b);
uint16_t 	FastDiv3232_shift_3_8(fixed_t32 a, fixed_t32 b);
fixed_t32	FastDiv32u16u (fixed_t32 a, int16_t b);
fixed_t32	FastDiv3216u (fixed_t32 a, int16_t b);
//int16_t     R_CalculateScaleStep(fixed_t32 a, int16_t b);
fixed_t32   FixedDivWholeA(fixed_16_t a, fixed_t32 b);

void copystr8(int8_t __far* dst, int8_t __far* src);
void __far combine_strings(char __far *dest, char __far *src1, char __far *src2);
void __far makesavegamename(char __far *dest, int8_t number);
void __far locallib_strcpy(char __far *dest, char __far *src);
void __far locallib_strncpy(char __far *dest, char __far *src, int16_t n);
int16_t __far locallib_strlen(char __far *src);
void locallib_strupr(char __far *str);


// A or (and) B is a whole number (0 in the low 16 bits). should be optimizable?
//#define	FixedDivWholeA(a,b) FixedDiv(a, b)
#define	FixedDivWholeB(a,b) FixedDiv(a, b)
//#define	FixedDivWholeAB(a,b) FixedDiv(a, b)
fixed_t32   FixedDivWholeAB(fixed_16_t a, fixed_16_t b);
fixed_t32   FixedDivWholeAB2(fixed_16_t a, fixed_16_t b);

//fixed_t32	FixedDivinner (fixed_t32 a, fixed_t32 b, int8_t* file, int32_t line);
//fixed_t32	FixedDiv2 (fixed_t32 a, fixed_t32 b, int8_t* file, int32_t line);
//#define FixedDiv(a, b) FixedDivinner(a, b, __FILE__, __LINE__)


typedef uint16_t THINKERREF;
typedef uint8_t  THINKFUNCTION;

#define NULL_THINKERREF 0


#define intx86(a, b, c) int86(a, b, c)


#define DPMI_INT 0x31
#define EMS_INT 0x67
#define XMS_INT 0x2F
#define DOSMM_INT 0x21

#define PAGE_FRAME_SIZE 0x4000L


#define FAR_memset _fmemset
#define FAR_memcpy _fmemcpy
#define FAR_strncpy _fstrncpy
#define FAR_strcpy _fstrcpy
#define FAR_memmove _fmemmove

#define __COMPILER_WATCOM 1

#ifdef __COMPILER_WATCOM
// open watcom defines
#define __far_func __far
#else
// gccia16 defines

#define __far_func  
#define __DEMO_ONLY_BINARY
#ifndef __near
#define __near
#endif
#ifndef __interrupt
#define __interrupt 
#endif
#ifndef O_BINARY
#define O_BINARY 0 
#define SKIPWIPE
//#define PRECALCULATE_OPENINGS


#define _chain_intr(func) func()

// only used in practice for b = 3, then & 0x07...
#define _rotl(a, b) (a>>13)

#endif

void __far  _fstrncpy(char __far *dst, const char __far *src, size_t n);


#endif

void  _far_fread(void __far* dest, uint16_t elementsize, uint16_t elementcount, FILE * stream);
void _far_fwrite(void __far* dest, uint16_t elementsize, uint16_t elementcount, FILE * stream);
void  _far_read(int16_t filehandle, void __far* dest, uint16_t totalsize);

#define FAR_fwrite _far_fwrite
#define FAR_fread _far_fread
#define FAR_read _far_read


#define SAVEGAMESIZE    0x2c000
// lets keep this comfortably 16 bit. otherwise how do we fit in ems without big rewrite?
#define DEMO_MAX_SIZE 0xF800

//#define FAR_fread fread
//#define FAR_read read



#endif          // __DOOMDEF__
