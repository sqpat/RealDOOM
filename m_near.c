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



// todo most of these aren't used??

//int16_t dmxCodes[NUM_SCARDS]; // the dmx code for a given card





boolean         respawnparm;    // checkparm of -respawn


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







// store sp/bp when doing cli/sti shenanigans







 

int8_t skytextureloaded = false;






//
// precalculated math tables
//

 
 


uint16_t			skytexture;





//
// regular wall
//





//
// Sprite rotation 0 is facing the viewer,
//  rotation 1 is one angle turn CLOCKWISE around the axis.
// This is not the same as the angle,
//  which increases counter clockwise (protractor).
// There was a lot of stuff grabbed wrong, so I changed it...
//


// constant arrays
//  used for psprite clipping and initializing clipping
//int16_t           *negonearray;// [SCREENWIDTH];
//int16_t           *screenheightarray;// [SCREENWIDTH];


//
// INITIALIZATION FUNCTIONS
//

// variables used to look up
//  and range check thing_t sprites patches





 
int16_t             numflats;

int16_t             numpatches;

int16_t             numspritelumps;

int16_t             numtextures;

 



int8_t 	am_cheating = 0;
int8_t 	am_grid = 0;

// size of window on screen
mpoint_t 	m_paninc; // how far the window pans each tic (map coords)
int16_t 	mtof_zoommul; // how far the window zooms in each tic (map coords)
int16_t 	ftom_zoommul; // how far the window zooms in each tic (fb coords)

int16_t 	screen_botleft_x, screen_botleft_y;   // LL x,y where the window is on the map (map coords)
int16_t 	screen_topright_x, screen_topright_y; // UR x,y where the window is on the map (map coords)

//
// width/height of window on map (map coords)
//
int16_t	screen_viewport_width;
int16_t	screen_viewport_height;

// based on level size
int16_t am_min_level_x;
int16_t	am_min_level_y;
int16_t am_max_level_x;
int16_t	am_max_level_y;


// based on player size
//this is never a 32 bit level in any commercial levels..
uint16_t 	am_min_scale_mtof; // used to tell when to stop zooming out
fixed_t_union 	am_max_scale_mtof; // used to tell when to stop zooming in

// old stuff for recovery later
int16_t old_screen_viewport_width, old_screen_viewport_height;
int16_t old_screen_botleft_x, old_screen_botleft_y;

// old location used by the Follower routine
mpoint_t screen_oldloc;

// used by MTOF to scale from map-to-frame-buffer coords

fixed_t_union am_scale_mtof;

// used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof)
fixed_t_union am_scale_ftom;

mpoint_t markpoints[AM_NUMMARKPOINTS]; // where the points are
int8_t markpointnum = 0; // next point to be assigned

int8_t followplayer = 1; // specifies whether to follow the player around

boolean am_stopped = true;
boolean am_bigstate=0;

fline_t am_fl;
mline_t am_ml;
mline_t am_l;
int8_t am_lastlevel = -1;
int8_t am_lastepisode = -1;
mline_t	am_lc;


//#define LINE_PLAYERRADIUS 16<<4

//
// The vector graphics for the automap.
//  A line drawing of the player pointing right,
//   starting from the middle.
//
//#define R ((8*LINE_PLAYERRADIUS)/7)
#define R 292
mline_t player_arrow[] = {
    { { -R+R/8, 0 }, { R, 0 } }, // -----
    { { R, 0 }, { R-R/2, R/4 } },  // ----->
    { { R, 0 }, { R-R/2, -R/4 } },
    { { -R+R/8, 0 }, { -R-R/8, R/4 } }, // >---->
    { { -R+R/8, 0 }, { -R-R/8, -R/4 } },
    { { -R+3*R/8, 0 }, { -R+R/8, R/4 } }, // >>--->
    { { -R+3*R/8, 0 }, { -R+R/8, -R/4 } }
};
#undef R

//#define R ((8*LINE_PLAYERRADIUS)/7)
#define R 292
mline_t cheat_player_arrow[] = {
    { { -R+R/8, 0 }, { R, 0 } }, // -----
    { { R, 0 }, { R-R/2, R/6 } },  // ----->
    { { R, 0 }, { R-R/2, -R/6 } },
    { { -R+R/8, 0 }, { -R-R/8, R/6 } }, // >----->
    { { -R+R/8, 0 }, { -R-R/8, -R/6 } },
    { { -R+3*R/8, 0 }, { -R+R/8, R/6 } }, // >>----->
    { { -R+3*R/8, 0 }, { -R+R/8, -R/6 } },
    { { -R/2, 0 }, { -R/2, -R/6 } }, // >>-d--->
    { { -R/2, -R/6 }, { -R/2+R/6, -R/6 } },
    { { -R/2+R/6, -R/6 }, { -R/2+R/6, R/4 } },
    { { -R/6, 0 }, { -R/6, -R/6 } }, // >>-dd-->
    { { -R/6, -R/6 }, { 0, -R/6 } },
    { { 0, -R/6 }, { 0, R/4 } },
    { { R/6, R/4 }, { R/6, -R/7 } }, // >>-ddt->
    { { R/6, -R/7 }, { R/6+R/32, -R/7-R/32 } },
    { { R/6+R/32, -R/7-R/32 }, { R/6+R/10, -R/7 } }
};
#undef R
/*
#define R (1 << 4)
mline_t triangle_guy[] = {
    { { -.867*R, -.5*R }, { .867*R, -.5*R } },
    { { .867*R, -.5*R } , { 0, R } },
    { { 0, R }, { -.867*R, -.5*R } }
};
#undef R
*/

#define R (1 << 4)
mline_t thintriangle_guy[] = {
    { { -.5*R, -.7*R }, { R, 0 } },
    { { R, 0 }, { -.5*R, .7*R } },
    { { -.5*R, .7*R }, { -.5*R, -.7*R } }
};
#undef R






/* 
uint8_t quality_port_lookup[12] = {

// lookup for what to write in the planar port of vga during draw column etc.
//. constructed from detailshift and dc_x & 0x3
	// bit 34  00
         1, 2, 4, 8,

	// bit 34  01 = low
	     3, 12, 3, 12,

	    
	// bit 34  10  = potato
		15, 15, 15, 15


};
*/


// int16_t 					segloopprevlookup[2];
// int16_t 					segloopnextlookup[2] = {-1, -1}; // 0 would be fine too...
// uint8_t 					seglooptexrepeat[2] = {0, 0}; 
// segment_t 					segloopcachedsegment[2];
// int16_t 					segloopcachedbasecol[2];

//uint8_t 					segloopheightvalcache[2];










void (__far* P_SpawnMapThing)() =            ((void (__far *)(mapthing_t mthing, int16_t key))                                        	                                   (MK_FP(physics_highcode_segment, 		 P_SpawnMapThingOffset)));
void (__far* R_WriteBackViewConstantsSpanCall)()  =   				      	  ((void    (__far *)())  								(MK_FP(spanfunc_jump_lookup_segment, 	 R_WriteBackViewConstantsSpan24Offset)));

void (__far* R_WriteBackViewConstantsMaskedCall)() = 						  ((void    (__far *)())     							(MK_FP(maskedconstants_funcarea_segment, R_WriteBackViewConstantsMasked24Offset)));
void (__far* R_WriteBackViewConstants)() =    ((void (__far *)())     	                                                                                                   (MK_FP(bsp_code_segment,          		 R_WriteBackViewConstants24Offset)));
void (__far* R_RenderPlayerView)() =          ((void (__far *)())     	                                                                                                   (MK_FP(bsp_code_segment,          		 R_RenderPlayerView24Offset)));

void (__far* P_Ticker)() =                    ((void (__far *)())     	                                                                                                    (MK_FP(physics_highcode_segment,         P_TickerOffset)));
void (__far* P_SpawnSpecials)() =             ((void (__far *)())     	                                                                                                    (MK_FP(physics_highcode_segment,         P_SpawnSpecialsOffset)));
void (__far* P_GivePower)() =                 ((void (__far *)(int16_t power))     	                                                                                        (MK_FP(physics_highcode_segment,         P_GivePowerOffset)));






// todo p_map stuff goes here....



int16_t                 currentlumpindex = 0;
//
// R_GenerateLookup
//
//todo pull down below?
uint16_t maskedcount = 0;
// global post offset for masked texture posts
uint16_t currentpostoffset = 0;
uint16_t currentpostdataoffset = 0;
uint16_t currentpixeloffset = 0;
// global colof offset for masked texture colofs


spriteframe_t __far* p_init_sprtemp;
int16_t             p_init_maxframe;




boolean grmode = 0;
boolean mousepresent;


boolean novideo; // if true, stay in text mode for debugging




void (__interrupt __far_func *oldkeyboardisr) (void) = NULL;
boolean             inhelpscreensstate = false;
boolean             fullscreen = false;
gamestate_t         oldgamestate = -1;
ticcount_t maketic;
ticcount_t gametime;

uint8_t				numChannels;	


 
 
 
boolean         	timingdemo;             // if true, exit with report on completion 
//boolean         	nodrawers;              // for comparative timing purposes 
boolean         	noblit;                 // for comparative timing purposes 
ticcount_t      	starttime;              // for comparative timing purposes       
 
 



 

 
boolean         demorecording; 

boolean         netdemo; 

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

// todo i think these fit in 16 bits... 
fixed_t         	forwardmove[2] = {0x19, 0x32}; 
fixed_t         	sidemove[2]    = {0x18, 0x28};


int8_t             turnheld;                               // for accelerative turning 
 
boolean         mousearray[4]; 
// note: i think the -1 array thing  might be causing 16 bit binary to act up - not 100% sure - sq
boolean*        mousebuttons = &mousearray[1];          // allow [-1]

// mouse values are used once 
int16_t             mousex;

int16_t             dclicktime;
int16_t             dclickstate;
int16_t             dclicks;
int16_t             dclicktime2;
int16_t             dclickstate2;
int16_t             dclicks2;





int16_t		myargc;
int8_t**		myargv;

uint8_t		usemouse;




int8_t*   defdemoname; 
skill_t d_skill; 
int8_t     d_episode;
int8_t     d_map;
boolean         secretexit; 



            
// ST_Start() has just been called
boolean          st_firsttime;
boolean          updatedthisframe;

// used to execute ST_Init() only once

// lump number for PLAYPAL
//int16_t              lu_palette;
//byte __far*  palettebytes;

// used for timing


// whether in automap or first-person
st_stateenum_t   st_gamestate;

// whether left-side main status bar is active
boolean          st_statusbaron;

// main bar left
//uint16_t         sbar;

uint16_t 		tallpercent;
uint16_t		faceback;
uint16_t		sbar;
uint16_t		armsbg;

// 3 key-cards, 3 skulls
uint16_t         keys[NUMCARDS];// = { 61200u, 61096u, 60992u, 60872u, 60752u, 60632u };

// weapon ownership patches
uint16_t arms[6][2];// = { {58908u, 0}, {58836u, 0}, {58776u, 0}, {58704u, 0}, {58632u, 0}, {58560u, 0} };

// face status patch offsets
// long long time ago to get binary size down, constants like these were hardcoded.
uint16_t         faces[ST_NUMFACES];
/*
 = { 43216u,
        42408u, 41600u, 40720u, 39836u, 38992u,
        38176u, 37352u, 36544u, 35736u, 34936u,
        34048u, 33164u, 32320u, 31504u, 30680u,
        29856u, 29028u, 28204u, 27308u, 26412u,
        25568u, 24752u, 23928u, 23088u, 22252u,
        21420u, 20512u, 19568u, 18724u, 17908u,
        17084u, 16240u, 15404u, 14560u, 13652u,
        12668u, 11824u, 11008u, 10184u, 9376u,
        8540u

};*/



// ready-weapon widget
st_number_t      w_ready;


// health widget
st_percent_t     w_health;

// arms background
st_multicon_t     w_armsbg;
//st_binicon_t     w_armsbg;


// weapon ownership widgets
st_multicon_t    w_arms[6];

// face status widget
st_multicon_t    w_faces; 

// keycard widgets
st_multicon_t    w_keyboxes[3];

// armor widget
st_percent_t     w_armor;

// ammo widgets
st_number_t      w_ammo[4];

// max ammo widgets
st_number_t      w_maxammo[4]; 




// used to use appopriately pained face 
int16_t      st_oldhealth = -1;

// used for evil grin
boolean  oldweaponsowned[NUMWEAPONS]; 

 // count until face changes
int16_t      st_facecount = 0;

// current face index, used by w_faces
int16_t      st_faceindex = 0;

// holds key-type for each key box on bar
int16_t      keyboxes[3];

// a random number per tick
uint8_t      st_randomnumber;


 

boolean do_st_refresh;

int8_t st_palette = 0;

int16_t  st_calc_lastcalc;
int16_t  st_calc_oldhealth = -1;
int8_t  st_face_lastattackdown = -1;
int8_t  st_face_priority = 0;
int8_t     st_stuff_buf[ST_MSGWIDTH];



uint8_t		message_counter;













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
volatile fixed_t_union TaskServiceCount;

volatile int8_t TS_TimesInInterrupt;
int8_t TS_Installed = false;
volatile int8_t TS_InInterrupt = false;


// used for general timing

boolean  st_stopped = true;
uint16_t armsbgarray[1];



int16_t	maxammo[NUMAMMO] = {200, 50, 300, 50};

// cached 'last used' mobjs for functions that operate on a mobj and where the mobj is often used right after. 

uint16_t oldentertics;

   







//
// SLIDE MOVE
// Allows the player to slide along any angled walls.
//







//
//      source animation definition
//








// newend is one past the last valid seg

uint16_t                    numlumps;
FILE*                		wadfiles[MAX_WADFILES];
int16_t                		filetolumpindex[MAX_WADFILES-1] = {-1, -1, -1};
int32_t                		filetolumpsize[MAX_WADFILES-1];
int8_t                     	currentloadedfileindex = 0;





  






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








boolean FORCE_5000_LUMP_LOAD = false;

SB_VoiceInfo        sb_voicelist[NUM_SFX_TO_MIX];

uint16_t lastpcspeakernotevalue = 0;
