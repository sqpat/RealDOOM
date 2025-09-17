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
//  near memory allocations, hardcoded to specific addresses rather
//  than linker-dependent. This allows us to compile binaries of
//  groups of functions, export them to file (rather than in the
//  main binary) then load at runtime where the near variable
//  addresses won't have changed..



//
// Sound header & data
//

//
// Sound header & data
//

#include "doomdef.h"
#include "m_memory.h"
#include "m_near.h"
#include "d_englsh.h"
#include "sounds.h"
#include "s_sound.h"
#include "m_offset.h"
#include <dos.h>

#define title_string_offset HUSTR_E1M1

// DEFINE ALL LOCALS HERE. EXTERN IN m_near.h


boolean         singletics = false; // debug flag to cancel adaptiveness
skill_t         startskill;
int8_t          startepisode;
int8_t          startmap;
boolean         autostart;

//
//  DEMO LOOP
//
int16_t             pagetic;
int8_t                    *pagename;


#ifdef DETAILED_BENCH_STATS
uint16_t rendertics = 0;
uint16_t physicstics = 0;
uint16_t othertics = 0;
uint16_t cachedtics = 0;
uint16_t cachedrendertics = 0;
uint16_t rendersetuptics = 0;
uint16_t renderplayerviewtics = 0;
uint16_t renderpostplayerviewtics = 0;

uint16_t renderplayersetuptics = 0;
uint16_t renderplayerbsptics = 0;
uint16_t renderplayerplanetics = 0;
uint16_t renderplayermaskedtics = 0;
uint16_t cachedrenderplayertics = 0;
#endif

int8_t		eventhead;
int8_t		eventtail;

void (__far* P_SpawnMapThing)() =            ((void (__far *)(mapthing_t mthing, int16_t key))                                        	                                   (MK_FP(physics_highcode_segment, 		 P_SpawnMapThingOffset)));
void (__far* R_WriteBackViewConstantsSpanCall)()  =   				      	  ((void    (__far *)())  								(MK_FP(spanfunc_jump_lookup_segment, 	 R_WriteBackViewConstantsSpan24Offset)));

void (__far* R_WriteBackViewConstantsMaskedCall)() = 						  ((void    (__far *)())     							(MK_FP(maskedconstants_funcarea_segment, R_WriteBackViewConstantsMasked24Offset)));
void (__far* R_WriteBackViewConstants)() =    ((void (__far *)())     	                                                                                                   (MK_FP(bsp_code_segment,          		 R_WriteBackViewConstants24Offset)));
void (__far* R_RenderPlayerView)() =          ((void (__far *)())     	                                                                                                   (MK_FP(bsp_code_segment,          		 R_RenderPlayerView24Offset)));

void (__far* P_Ticker)() =                    ((void (__far *)())     	                                                                                                    (MK_FP(physics_highcode_segment,         P_TickerOffset)));
void (__far* P_SpawnSpecials)() =             ((void (__far *)())     	                                                                                                    (MK_FP(physics_highcode_segment,         P_SpawnSpecialsOffset)));

void (__far* AM_Ticker)() =                    ((void (__far *)())     	                                                                                                    (MK_FP(physics_highcode_segment,         AM_TickerOffset)));
void (__far* AM_Drawer)() =                    ((void (__far *)())     	                                                                                                    (MK_FP(physics_highcode_segment,         AM_DrawerOffset)));




void (__far* M_Init)() =                      ((void (__far *)())     	                                                                                                    (MK_FP(menu_code_area_segment,         M_InitOffset)));
boolean (__far* M_Responder)() =              ((boolean (__far *)(event_t __far* ev))     	                                                                                (MK_FP(menu_code_area_segment,         M_ResponderOffset)));
void (__far* M_LoadFromSaveGame)() =          ((void (__far *)(int8_t i))     	                                                                                            (MK_FP(menu_code_area_segment,         M_LoadFromSaveGameOffset)));





// todo p_map stuff goes here....





spriteframe_t __far* p_init_sprtemp;
int16_t             p_init_maxframe;

boolean grmode = 0;
boolean novideo; // if true, stay in text mode for debugging


void (__interrupt __far_func *oldkeyboardisr) (void) = NULL;
gamestate_t         oldgamestate = -1;
uint8_t				numChannels;	
 
 
boolean         	timingdemo;             // if true, exit with report on completion 
//boolean         	nodrawers;              // for comparative timing purposes 
boolean         	noblit;                 // for comparative timing purposes 

 


uint16_t           demo_p;				// buffer
//byte __far*           demoend; 
boolean         singledemo;             // quit after playing a demo from cmdline 
 
boolean         precache = true;        // if true, load all graphics at start 
 
wbstartstruct_t wminfo;                 // parms for world map / intermission 
 
  
 
// 
// controls (have defaults) 
// 
uint8_t             key_right;
uint8_t             key_left;
uint8_t             key_up;
uint8_t             key_down;
uint8_t             key_strafeleft;
uint8_t             key_straferight;
uint8_t             key_fire;
uint8_t             key_use;
uint8_t             key_strafe;
uint8_t             key_speed;
 
uint8_t             mousebfire;
uint8_t             mousebstrafe;
uint8_t             mousebforward;



int8_t             turnheld;                               // for accelerative turning 
 
boolean         mousearray[4]; 
// note: i think the -1 array thing  might be causing 16 bit binary to act up - not 100% sure - sq
// todo this is jank in asm just use an offset.
boolean*        mousebuttons = &mousearray[1];          // allow [-1]

// mouse values are used once 






int16_t		myargc;
int8_t**		myargv;

uint8_t		usemouse;




int8_t*   defdemoname; 
skill_t d_skill; 
int8_t     d_episode;
int8_t     d_map;
boolean         secretexit; 




























#define newg_end 5
#define hurtme 2
#define opt_end 8
#define ep1 0
#define read1_end 1
#define read2_end 1
#define sound_end 4




//
// LOAD GAME MENU
//
#define load_end 6








//
// M_QuitDOOM
//



task HeadTask = {0, false};
task MUSTask = {0, false};

void( __interrupt __far_func *OldInt8)(void);
volatile uint16_t TaskServiceCount;

volatile int8_t TS_TimesInInterrupt;
int8_t TS_Installed = false;
volatile int8_t TS_InInterrupt = false;






int16_t	maxammo[NUMAMMO] = {200, 50, 300, 50};



#ifdef DETAILED_BENCH_STATS
int32_t taskswitchcount = 0;
int32_t texturepageswitchcount = 0;
int32_t patchpageswitchcount = 0;
int32_t compositepageswitchcount = 0;
int32_t spritepageswitchcount = 0;
int16_t benchtexturetype = 0;
int32_t flatpageswitchcount = 0;
int32_t scratchpageswitchcount = 0;
int16_t spritecacheevictcount = 0;
int16_t flatcacheevictcount = 0;
int16_t patchcacheevictcount = 0;
int16_t compositecacheevictcount = 0;
int32_t visplaneswitchcount = 0;

#endif



/*
uint8_t blocksizelookup[256]={

// not sure this isa ctually faster..

	0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,

	1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,

	2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,

	3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
	4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
	4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
	4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4

};
*/


#if (EXE_VERSION >= EXE_VERSION_FINAL)
boolean    					plutonia = false;
boolean    					tnt = false;
#endif


int8_t versionstring[12] = "version 109";  // hardcoded from VERSION. todo dynamically generate?

int8_t  currentoverlay = OVERLAY_ID_UNMAPPED;
int32_t codestartposition[NUM_OVERLAYS];

 
//
// Information about all the sfx
//


//todo move these to cs section of asm once sfx driver in asm. Not needed for pc speaker?
uint8_t sfx_priority[] = {
  // S_sfx[0] needs to be a dummy for odd reasons.
  // todo: move this into asm 
  0 ,

  64,
  64,
  64,
  64,
  64,
  64,
  64,
  64,
  64,
  64,
  118,
  64,
  64,
  64,
  70,
  70,
  70,
  100,
  100,
  100,
  100,
  119,
  78,
  78,
  96,
  96,
  96,
  96,
  96,
  96,
  78,
  78,
  78,
  96,
  32,
  98,
  98,
  98,
  98,
  98,
  98,
  98,
  94,
  92,
  90,
  90,
  90,
  90,
  90,
  90,
  70,
  70,
  70,
  70,
  70,
  70,
  32,
  32,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  32,
  32,
  32,
  32,
  32,
  32,
  32,
  32,
  120,
  120,
  120,
  100,
  100,
  100,
  78,
  60,
  64,
  70,
  70,
  64,
  60,
  100,
  100,
  100,
  32,
  32,
  60,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  70,
  60
};


// the set of channels available
channel_t	channels[MAX_SFX_CHANNELS];

// These are not used, but should be (menu).
// Maximum volume of a sound effect.
// Internal default is max out of 0-15.






/*
uint16_t shift4lookup[256] = 

{ 0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 
272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512, 
528, 544, 560, 576, 592, 608, 624, 640, 656, 672, 688, 704, 720, 736, 752, 768, 
784, 800, 816, 832, 848, 864, 880, 896, 912, 928, 944, 960, 976, 992, 1008, 1024, 
1040, 1056, 1072, 1088, 1104, 1120, 1136, 1152, 1168, 1184, 1200, 1216, 1232, 1248, 1264, 1280, 
1296, 1312, 1328, 1344, 1360, 1376, 1392, 1408, 1424, 1440, 1456, 1472, 1488, 1504, 1520, 1536, 
1552, 1568, 1584, 1600, 1616, 1632, 1648, 1664, 1680, 1696, 1712, 1728, 1744, 1760, 1776, 1792, 
1808, 1824, 1840, 1856, 1872, 1888, 1904, 1920, 1936, 1952, 1968, 1984, 2000, 2016, 2032, 2048, 
2064, 2080, 2096, 2112, 2128, 2144, 2160, 2176, 2192, 2208, 2224, 2240, 2256, 2272, 2288, 2304, 
2320, 2336, 2352, 2368, 2384, 2400, 2416, 2432, 2448, 2464, 2480, 2496, 2512, 2528, 2544, 2560, 
2576, 2592, 2608, 2624, 2640, 2656, 2672, 2688, 2704, 2720, 2736, 2752, 2768, 2784, 2800, 2816, 
2832, 2848, 2864, 2880, 2896, 2912, 2928, 2944, 2960, 2976, 2992, 3008, 3024, 3040, 3056, 3072, 
3088, 3104, 3120, 3136, 3152, 3168, 3184, 3200, 3216, 3232, 3248, 3264, 3280, 3296, 3312, 3328, 
3344, 3360, 3376, 3392, 3408, 3424, 3440, 3456, 3472, 3488, 3504, 3520, 3536, 3552, 3568, 3584, 
3600, 3616, 3632, 3648, 3664, 3680, 3696, 3712, 3728, 3744, 3760, 3776, 3792, 3808, 3824, 3840, 
3856, 3872, 3888, 3904, 3920, 3936, 3952, 3968, 3984, 4000, 4016, 4032, 4048, 4064, 4080
};
*/

/* Driver descriptor */


/*
driverBlock OPL3driver = {
	OPLinitDriver,
	OPL3detectHardware,
	OPL3initHardware,
	OPL3deinitHardware,

	OPLplayNote,
	OPLreleaseNote,
	OPLpitchWheel,
	OPLchangeControl,
	OPLplayMusic,
	OPLstopMusic,
	OPLpauseMusic,
	OPLresumeMusic,
	OPLchangeSystemVolume,
	OPLsendMIDI,
	MUS_DRIVER_TYPE_OPL3

};*/






int32_t musdriverstartposition[MUS_DRIVER_COUNT-1];




uint16_t lastpcspeakernotevalue = 0;
