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

#include "m_memory.h"
#include "m_near.h"
#include "doomdef.h"
#include "d_englsh.h"
#include "sounds.h"
#include <dos.h>

#define title_string_offset HUSTR_E1M1

// DEFINE ALL LOCALS HERE. EXTERN IN m_near.h


const int8_t snd_prefixen[] = { 'P', 'P', 'A', 'S', 'S', 'S', 'M', 'M', 'M', 'S', 'S', 'S' };

//int16_t dmxCodes[NUM_SCARDS]; // the dmx code for a given card

int16_t snd_SBport;
uint8_t snd_SBirq, snd_SBdma; // sound blaster variables
int16_t snd_Mport; // midi variables

uint8_t snd_MusicVolume; // maximum volume for music
uint8_t snd_SfxVolume; // maximum volume for sound

uint8_t snd_SfxDevice; // current sfx card # (index to dmxCodes)
uint8_t snd_MusicDevice; // current music card # (index to dmxCodes)
uint8_t snd_DesiredSfxDevice;
uint8_t snd_DesiredMusicDevice;
uint8_t snd_SBport8bit;
uint8_t snd_Mport8bit;


boolean skipdirectdraws;
// wipegamestate can be set to -1 to force a wipe on the next draw
gamestate_t     wipegamestate = GS_DEMOSCREEN;





boolean         nomonsters;     // checkparm of -nomonsters
boolean         respawnparm;    // checkparm of -respawn
boolean         fastparm;       // checkparm of -fast


boolean         singletics = false; // debug flag to cancel adaptiveness





skill_t         startskill;
int8_t             startepisode;
int8_t             startmap;
boolean         autostart;


boolean         advancedemo;

boolean         modifiedgame;

boolean         shareware;
boolean         registered;
boolean         commercial;



//
//  DEMO LOOP
//
int8_t             demosequence;
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



 

//
// defaulted values
//
uint8_t                     mouseSensitivity;       // has default

// Show messages has default, 0 = off, 1 = on
uint8_t                     showMessages;

uint8_t         sfxVolume;
uint8_t         musicVolume;

// Blocky mode, has default, 0 = high, 1 = normal
uint8_t                     detailLevel;
uint8_t                     screenblocks;           // has default

// temp for screenblocks (0-9)
uint8_t                     screenSize;

// -1/255 = no quicksave slot picked!
int8_t                     quickSaveSlot;

boolean                 inhelpscreens;
boolean                 menuactive;



// draw stuff

segment_t 		dc_colormap_segment;  // dc_colormap segment. the colormap will be byte 0 at this segment.
uint8_t 		dc_colormap_index;  // dc_colormap offset. this generally is an index
int16_t			dc_x; 
int16_t			dc_yl; 
int16_t			dc_yh; 
fixed_t			dc_iscale; 
fixed_t_union	dc_texturemid;


// first pixel in a column (possibly virtual) 
segment_t			dc_source_segment;


int16_t		viewwidth;
int16_t		scaledviewwidth;
int16_t		viewheight;
int16_t		viewwindowx;
int16_t		viewwindowy; 
int16_t		viewwindowoffset;

// store sp/bp when doing cli/sti shenanigans
int16_t		sp_bp_safe_space[2];

// used to index things via SS when bp and sp are in use (since ss == ds)
// actually we use this as a general variable work space in self-contained asm calls so that we don't have to
// declare so many one-off variables. 
int16_t		ss_variable_space[18];

int8_t  	spanfunc_main_loop_count;
uint8_t 	spanfunc_inner_loop_count[4];
uint8_t     spanfunc_outp[4];
int16_t    	spanfunc_prt[4];
uint16_t    spanfunc_destview_offset[4];

int8_t	fuzzpos = 0; 


int16_t                     ds_y;
int16_t                     ds_x1;
int16_t                     ds_x2;

uint16_t				ds_colormap_segment;
uint8_t					ds_colormap_index;

//fixed_t                 ds_xfrac;
//fixed_t                 ds_yfrac;
//fixed_t                 ds_xstep;
//fixed_t                 ds_ystep;

// start of a 64*64 tile image 
segment_t ds_source_segment;


int16_t				lastvisplane;
int16_t				floorplaneindex;
int16_t				ceilingplaneindex;
uint16_t 		lastopening;


uint8_t __far*	planezlight;
fixed_t			planeheight;

fixed_t			basexscale;
fixed_t			baseyscale;

segment_t visplanelookupsegments[3] = {0x8400, 0x8800, 0x8C00};
int8_t ceilphyspage = 0;
int8_t floorphyspage = 0;

int16_t currentflatpage[4] = { -1, -1, -1, -1 };
// there can be 4 flats (4k each) per ems page (16k each). Keep track of how many are allocated here.
int8_t allocatedflatsperpage[NUM_FLAT_CACHE_PAGES];

int8_t visplanedirty = false;
int8_t skytextureloaded = false;

// Cached fields to avoid thinker access after page swap
int16_t r_cachedplayerMobjsecnum;
state_t r_cachedstatecopy[2];



// increment every time a check is made
int16_t			validcount = 1;


uint8_t		fixedcolormap;

int16_t			centerx;
int16_t			centery;

fixed_t_union			centeryfrac_shiftright4;


fixed_t_union			viewx;
fixed_t_union			viewy;
fixed_t_union			viewz;
short_height_t			viewz_shortheight;
angle_t			viewangle;
fineangle_t			viewangle_shiftright3;
uint16_t			viewangle_shiftright1;

// 0 = high, 1 = low, = 2 potato
int16_t_union		detailshift;	
uint8_t				detailshiftitercount;
uint8_t				detailshift2minus;
uint16_t			detailshiftandval;
int16_t 			setdetail;
//
// precalculated math tables
//
uint16_t			clipangle = 0;		// note: fracbits always 0
uint16_t			fieldofview =  0;	// note: fracbits always 0

 
 

// bumped light from gun blasts
uint8_t			extralight;			

boolean		setsizeneeded;
uint8_t		setblocks;
uint8_t			skyflatnum;
uint16_t			skytexture;


// True if any of the segs textures might be visible.
boolean		segtextured;	

// False if the back side is the same plane.
boolean		markfloor;	
boolean		markceiling;

boolean		maskedtexture;
uint16_t		toptexture;
uint16_t		bottomtexture;
uint16_t		midtexture;


fineangle_t	rw_normalangle;
// angle to line origin
//fineangle_t		rw_angle1_fine;  // every attempt to do this has led to rendering bugs
angle_t			rw_angle1;

//
// regular wall
//
int16_t		rw_x;
int16_t		rw_stopx;
fineangle_t		rw_centerangle;
fixed_t_union		rw_offset;
fixed_t		rw_distance;
fixed_t_union		rw_scale;
fixed_t_union		rw_midtexturemid;
fixed_t_union		rw_toptexturemid;
fixed_t_union		rw_bottomtexturemid;


fixed_t		pixhigh;
fixed_t		pixlow;
fixed_t		pixhighstep;
fixed_t		pixlowstep;

fixed_t		topfrac;
fixed_t		topstep;

fixed_t		bottomfrac;
fixed_t		bottomstep;
uint8_t __far*	walllights;

uint16_t __far*		maskedtexturecol;

byte __far * ceiltop;
byte __far * floortop;


//
// Sprite rotation 0 is facing the viewer,
//  rotation 1 is one angle turn CLOCKWISE around the axis.
// This is not the same as the angle,
//  which increases counter clockwise (protractor).
// There was a lot of stuff grabbed wrong, so I changed it...
//
uint16_t         pspritescale;
fixed_t         pspriteiscale;

uint8_t __far*  spritelights;

// constant arrays
//  used for psprite clipping and initializing clipping
//int16_t           *negonearray;// [SCREENWIDTH];
//int16_t           *screenheightarray;// [SCREENWIDTH];


//
// INITIALIZATION FUNCTIONS
//

// variables used to look up
//  and range check thing_t sprites patches
spritedef_t __far*	sprites;
int16_t             numsprites;

vissprite_t __far*    vissprite_p;

uint8_t     vsprsortedheadfirst;
segment_t lastvisspritesegment = 0xFFFF;
int16_t   lastvisspritepatch = -1;




 
int16_t             firstflat;
int16_t             numflats;

int16_t             firstpatch;
int16_t             numpatches;

int16_t             firstspritelump;
int16_t             numspritelumps;

int16_t             numtextures;



int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
uint8_t activenumpages[4]; // always gets reset to defaults at start of frame
int16_t textureLRU[4];


int16_t activespritepages[4]; // always gets reset to defaults at start of frame
uint8_t activespritenumpages[4]; // always gets reset to defaults at start of frame
int16_t spriteLRU[4];

 





int8_t spritecache_head = -1;
int8_t spritecache_tail = -1;

int8_t flatcache_head = -1;
int8_t flatcache_tail = -1;

int8_t patchcache_head = -1;
int8_t patchcache_tail = -1;

int8_t texturecache_head = -1;
int8_t texturecache_tail = -1;

segment_t cachedsegmentlump = 0xFFFF;
segment_t cachedsegmenttex = 0xFFFF;
int16_t   cachedlump = -1;
int16_t   cachedtex = -1;

segment_t cachedsegmentlump2 = 0xFFFF;
segment_t cachedsegmenttex2 = 0xFFFF;
int16_t   cachedlump2 = -1;
int16_t   cachedtex2 = -1;
uint8_t   cachedcollength = 0;
uint8_t   cachedcollength2 = 0;
int8_t active_visplanes[5] = {1, 2, 3, 0, 0};

byte cachedbyteheight;
uint8_t cachedcol;
//int16_t setval = 0;


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

uint8_t cheat_amap_seq[] = {'i', 'd', 'd', 't', 0xff};
cheatseq_t cheat_amap = { cheat_amap_seq, 0 };
boolean am_stopped = true;
boolean am_bigstate=0;
int8_t  am_buffer[20];
boolean    	automapactive = false;
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

//uint8_t jump_mult_table_3[32] = {
uint8_t jump_mult_table_3[8] = {
	//93, 90, 87, 84, 81, 78, 75, 72, 69, 66, 63, 60, 57, 54, 51, 48,
	//45, 42, 39, 36, 33, 30, 27, 24, 
	21, 18, 15, 12, 9,  6,  3,  0
}; 
int16_t lightmult48lookup[16] = { 0,  48,  96, 144,
								192, 240, 288, 336,
								384, 432, 480, 528,
								576, 624, 672, 720 };

int16_t lightshift7lookup[16] = { 0,  128,  256, 384,
								 512,  640,  768, 896,
								1024, 1152, 1280, 1408,
								1536, 1664, 1792, 1920 };

segment_t pagesegments[4] = { 0x0000u, 0x0400u, 0x0800u, 0x0c00u };

uint16_t MULT_4096[4] = {0x0000u, 0x1000u, 0x2000u, 0x3000u};
uint16_t MULT_256[4] = {0x0000u, 0x0100u, 0x0200u, 0x0300u};

uint16_t FLAT_CACHE_PAGE[4] = { 0x7000, 0x7400, 0x7800, 0x7C00 };

 
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

uint16_t visplane_offset[25] = {
	0,
	646 ,1292, 1938, 2584, 3230, 
	3876, 4522, 5168, 5814, 6460, 
	7106, 7752, 8398, 9044, 9690, 
	10336, 10982, 11628, 12274, 12920, 
	13566, 14212, 14858, 15504
};

uint16_t vga_read_port_lookup[12] = {

// lookup for what to write to the vga port for read  for fuzzcolumn
         4, 260, 516, 772,

	// bit 34  01 = low
	     4, 516, 4, 516,

	    
	// bit 34  10  = potato
		4, 4, 4, 4


};



void (__far* R_DrawColumnPrepCallHigh)(uint16_t)  =  ((void    (__far *)(uint16_t))  (MK_FP(colfunc_segment_high, R_DrawColumnPrepOffset)));
void (__far* R_DrawColumnPrepCall)(uint16_t)  =   ((void    (__far *)(uint16_t))  (MK_FP(colfunc_segment, R_DrawColumnPrepOffset)));
int16_t __far*          mfloorclip;
int16_t __far*          mceilingclip;

fixed_t_union         spryscale;
fixed_t_union         sprtopscreen;

void (__far* R_DrawFuzzColumnCallHigh)(uint16_t, byte __far *)  =  ((void    (__far *)(uint16_t, byte __far *))  (MK_FP(drawfuzzcol_area_segment, 0)));



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
segment_t EMS_PAGE;


spriteframe_t __far* p_init_sprtemp;
int16_t             p_init_maxframe;




boolean grmode = 0;
boolean mousepresent;
volatile uint32_t ticcount;
// REGS stuff used for int calls
union REGS regs;
struct SREGS segregs;

boolean novideo; // if true, stay in text mode for debugging
#define KBDQUESIZE 32
byte keyboardque[KBDQUESIZE];
uint8_t kbdtail, kbdhead;
union REGS in, out;



void (__interrupt __far_func *oldkeyboardisr) (void) = NULL;
byte __far *currentscreen;
byte __far *destview;
fixed_t_union destscreen;

int16_t olddb[2][4];
boolean             viewactivestate = false;
boolean             menuactivestate = false;
boolean             inhelpscreensstate = false;
boolean             fullscreen = false;
gamestate_t         oldgamestate = -1;
uint8_t                 borderdrawcount;
ticcount_t maketic;
ticcount_t gametime;

uint8_t			numChannels;	
uint8_t	usegamma;


//default_t	defaults[NUM_DEFAULTS];
 
gameaction_t    gameaction; 
gamestate_t     gamestate; 
skill_t         gameskill; 
boolean         respawnmonsters;
int8_t             gameepisode; 
int8_t             gamemap;
 
boolean         paused; 
boolean         sendpause;              // send a pause event next tic 
boolean         sendsave;               // send a save event next tic 
boolean         usergame;               // ok to save / end game 
 
boolean         timingdemo;             // if true, exit with report on completion 
//boolean         nodrawers;              // for comparative timing purposes 
boolean         noblit;                 // for comparative timing purposes 
ticcount_t             starttime;              // for comparative timing purposes       
 
boolean         viewactive; 
 
player_t        player;
 
ticcount_t          gametic;
int16_t             totalkills, totalitems, totalsecret;    // for intermission 
 
int8_t            demoname[32];
boolean         demorecording; 
boolean         demoplayback; 
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
 
 int8_t         forwardmove[2] = {0x19, 0x32}; 
int8_t         sidemove[2] = {0x18, 0x28};
int16_t         angleturn[3] = {640, 1280, 320};        // + slow turn 


boolean				gamekeydown[NUMKEYS];
int8_t             turnheld;                               // for accelerative turning 
 
boolean         mousearray[4]; 
// note: i think the -1 array thing  might be causing 16 bit binary to act up - not 100% sure - sq
boolean*        mousebuttons = &mousearray[1];          // allow [-1]

// mouse values are used once 
int16_t             mousex;
int16_t             mousey;

int32_t             dclicktime;
int32_t             dclickstate;
int32_t             dclicks;
int32_t             dclicktime2;
int32_t             dclickstate2;
int32_t             dclicks2;

 
int8_t             savegameslot;
int8_t            savedescription[32];
ticcmd_t localcmds[BACKUPTICS];




int16_t		myargc;
int8_t**		myargv;
int16_t	rndindex = 0;
int16_t	prndindex = 0;
uint8_t		usemouse;

 
default_t	defaults[28] ={
    {"mouse_sensitivity",&mouseSensitivity, 5},
    {"sfx_volume",&sfxVolume, 8},
    {"music_volume",&musicVolume, 8},
    {"show_messages",&showMessages, 1},
    
    {"key_right",&key_right, SC_RIGHTARROW, 1},
    {"key_left",&key_left, SC_LEFTARROW, 1},
    {"key_up",&key_up, SC_UPARROW, 1},
    {"key_down",&key_down, SC_DOWNARROW, 1},
    {"key_strafeleft",&key_strafeleft, SC_COMMA, 1},
    {"key_straferight",&key_straferight, SC_PERIOD, 1},

    {"key_fire",&key_fire, SC_RCTRL, 1},
    {"key_use",&key_use, SC_SPACE, 1},
    {"key_strafe",&key_strafe, SC_RALT, 1},
    {"key_speed",&key_speed, SC_RSHIFT, 1},

    {"use_mouse",&usemouse, 0},
    {"mouseb_fire",&mousebfire,0},
    {"mouseb_strafe",&mousebstrafe,1},
    {"mouseb_forward",&mousebforward,2},

    {"screenblocks",&screenblocks, 9},
    {"detaillevel",&detailLevel, 0},

    {"snd_channels",&numChannels, 3},
    {"snd_musicdevice",&snd_DesiredMusicDevice, 0},
    {"snd_sfxdevice",&snd_DesiredSfxDevice, 0},
    {"snd_sbport",&snd_SBport8bit, 0x22}, // must be shifted one...
    {"snd_sbirq",&snd_SBirq, 5},
    {"snd_sbdma",&snd_SBdma, 1},
    {"snd_mport",&snd_Mport8bit, 0x33},  // must be shifted one..

    {"usegamma",&usegamma, 0}
	 

};

int8_t*	defaultfile;

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

// 0-9, tall numbers
uint16_t         tallnum[10] = { 65216u, 64972u, 64636u, 64300u, 63984u, 63636u, 63296u, 63020u, 62672u, 62336u };


// 0-9, short, yellow (,different!) numbers
uint16_t         shortnum[10] = { 62268u, 62204u, 62128u, 62056u, 61996u, 61924u, 61852u, 61780u, 61704u, 61632u};


// 3 key-cards, 3 skulls
uint16_t         keys[NUMCARDS] = { 61200u, 61096u, 60992u, 60872u, 60752u, 60632u };


// face status patches
uint16_t         faces[ST_NUMFACES] = { 43216u,
        42408u, 41600u, 40720u, 39836u, 38992u,
        38176u, 37352u, 36544u, 35736u, 34936u,
        34048u, 33164u, 32320u, 31504u, 30680u,
        29856u, 29028u, 28204u, 27308u, 26412u,
        25568u, 24752u, 23928u, 23088u, 22252u,
        21420u, 20512u, 19568u, 18724u, 17908u,
        17084u, 16240u, 15404u, 14560u, 13652u,
        12668u, 11824u, 11008u, 10184u, 9376u,
        8540u

};

// weapon ownership patches
uint16_t arms[6][2] = { {58908u, 0}, {58836u, 0}, {58776u, 0}, {58704u, 0}, {58632u, 0}, {58560u, 0} };


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



// Massive bunches of cheat shit
//  to keep it from being easy to figure them out.
// Yeah, right...
uint8_t   cheat_mus_seq[] = {
    'i', 'd', 'm', 'u', 's', 1, 0, 0, 0xff
};

uint8_t   cheat_choppers_seq[] = {
    'i', 'd', 'c', 'h', 'o', 'p', 'p', 'e', 'r', 's', 0xff // idchoppers
};

uint8_t   cheat_god_seq[] = {
    'i', 'd', 'd', 'q', 'd', 0xff // iddqd
};

uint8_t   cheat_ammo_seq[] = {
    'i', 'd', 'k', 'f', 'a', 0xff // idkfa
};

uint8_t   cheat_ammonokey_seq[] = {
    'i', 'd', 'f', 'a', 0xff // idfa
};


// Smashing Pumpkins Into Samml Piles Of Putried Debris. 
uint8_t   cheat_noclip_seq[] = {
    'i', 'd', 's', 'p', 'i', // idspispopd
    's', 'p', 'o', 'p', 'd', 0xff
};

//
uint8_t   cheat_commercial_noclip_seq[] = {
    'i', 'd', 'c', 'l', 'i', 'p', 0xff // idclip
}; 



uint8_t   cheat_powerup_seq[7][10] = {
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'v', 0xff}, // beholdv
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 's', 0xff}, // beholds
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'i', 0xff}, // beholdi
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'r', 0xff}, // beholdr
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'a', 0xff}, // beholda
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'l', 0xff}, // beholdl
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 0xff}     // behold
};


uint8_t   cheat_clev_seq[] = {
    'i', 'd', 'c', 'l', 'e', 'v', 1, 0, 0, 0xff // idclev
};


// my position cheat
uint8_t   cheat_mypos_seq[] = {
    'i', 'd', 'm', 'y', 'p', 'o', 's', 0xff // idmypos   
}; 


// Now what?
cheatseq_t      cheat_mus = { cheat_mus_seq, 0 };
cheatseq_t      cheat_god = { cheat_god_seq, 0 };
cheatseq_t      cheat_ammo = { cheat_ammo_seq, 0 };
cheatseq_t      cheat_ammonokey = { cheat_ammonokey_seq, 0 };
cheatseq_t      cheat_noclip = { cheat_noclip_seq, 0 };
cheatseq_t      cheat_commercial_noclip = { cheat_commercial_noclip_seq, 0 };

cheatseq_t      cheat_powerup[7] = {
    { cheat_powerup_seq[0], 0 },
    { cheat_powerup_seq[1], 0 },
    { cheat_powerup_seq[2], 0 },
    { cheat_powerup_seq[3], 0 },
    { cheat_powerup_seq[4], 0 },
    { cheat_powerup_seq[5], 0 },
    { cheat_powerup_seq[6], 0 }
};

cheatseq_t      cheat_choppers = { cheat_choppers_seq, 0 };
cheatseq_t      cheat_clev = { cheat_clev_seq, 0 };
cheatseq_t      cheat_mypos = { cheat_mypos_seq, 0 };
boolean do_st_refresh;

int8_t st_palette = 0;

int16_t  st_calc_lastcalc;
int16_t  st_calc_oldhealth = -1;
int8_t  st_face_lastattackdown = -1;
int8_t  st_face_priority = 0;
int8_t     st_stuff_buf[ST_MSGWIDTH];



hu_textline_t	w_title;

boolean		message_on;
boolean			message_dontfuckwithme;
boolean		message_nottobefuckedwith;

hu_stext_t	w_message;
uint8_t		message_counter;
int8_t hudneedsupdate = 0;



// offsets within segment stored
uint16_t hu_font[HU_FONTSIZE]  ={ 8468,
	8368, 8252, 8124, 7980, 7848,
	7788, 7668, 7548, 7452, 7376,
	7316, 7236, 7180, 7080, 6948,
	6864, 6724, 6592, 6476, 6352,
	6220, 6100, 5960, 5828, 5744,
	5672, 5592, 5512, 5432, 5304,
	5148, 5016, 4876, 4736, 4604,
	4472, 4344, 4212, 4076, 4004,
	3884, 3744, 3624, 3476, 3340,
	3216, 3088, 2952, 2812, 2692,
	2572, 2440, 2332, 2184, 2024,
	1900, 1772, 1680, 1580, 1488,
	1392, 1288
};


uint8_t	mapnames[] =	// DOOM shareware/registered/retail (Ultimate) names.
{

	HUSTR_E1M1 - title_string_offset,
	HUSTR_E1M2 - title_string_offset,
	HUSTR_E1M3 - title_string_offset,
	HUSTR_E1M4 - title_string_offset,
	HUSTR_E1M5 - title_string_offset,
	HUSTR_E1M6 - title_string_offset,
	HUSTR_E1M7 - title_string_offset,
	HUSTR_E1M8 - title_string_offset,
	HUSTR_E1M9 - title_string_offset,

	HUSTR_E2M1 - title_string_offset,
	HUSTR_E2M2 - title_string_offset,
	HUSTR_E2M3 - title_string_offset,
	HUSTR_E2M4 - title_string_offset,
	HUSTR_E2M5 - title_string_offset,
	HUSTR_E2M6 - title_string_offset,
	HUSTR_E2M7 - title_string_offset,
	HUSTR_E2M8 - title_string_offset,
	HUSTR_E2M9 - title_string_offset,

	HUSTR_E3M1 - title_string_offset,
	HUSTR_E3M2 - title_string_offset,
	HUSTR_E3M3 - title_string_offset,
	HUSTR_E3M4 - title_string_offset,
	HUSTR_E3M5 - title_string_offset,
	HUSTR_E3M6 - title_string_offset,
	HUSTR_E3M7 - title_string_offset,
	HUSTR_E3M8 - title_string_offset,
	HUSTR_E3M9 - title_string_offset,

	HUSTR_E4M1 - title_string_offset,
	HUSTR_E4M2 - title_string_offset,
	HUSTR_E4M3 - title_string_offset,
	HUSTR_E4M4 - title_string_offset,
	HUSTR_E4M5 - title_string_offset,
	HUSTR_E4M6 - title_string_offset,
	HUSTR_E4M7 - title_string_offset,
	HUSTR_E4M8 - title_string_offset,
	HUSTR_E4M9 - title_string_offset,

	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset,
	NEWLEVELMSG - title_string_offset
};

uint8_t	mapnames2[] =	// DOOM 2 map names.
{
	HUSTR_1 - title_string_offset,
	HUSTR_2 - title_string_offset,
	HUSTR_3 - title_string_offset,
	HUSTR_4 - title_string_offset,
	HUSTR_5 - title_string_offset,
	HUSTR_6 - title_string_offset,
	HUSTR_7 - title_string_offset,
	HUSTR_8 - title_string_offset,
	HUSTR_9 - title_string_offset,
	HUSTR_10 - title_string_offset,
	HUSTR_11 - title_string_offset,

	HUSTR_12 - title_string_offset,
	HUSTR_13 - title_string_offset,
	HUSTR_14 - title_string_offset,
	HUSTR_15 - title_string_offset,
	HUSTR_16 - title_string_offset,
	HUSTR_17 - title_string_offset,
	HUSTR_18 - title_string_offset,
	HUSTR_19 - title_string_offset,
	HUSTR_20 - title_string_offset,

	HUSTR_21 - title_string_offset,
	HUSTR_22 - title_string_offset,
	HUSTR_23 - title_string_offset,
	HUSTR_24 - title_string_offset,
	HUSTR_25 - title_string_offset,
	HUSTR_26 - title_string_offset,
	HUSTR_27 - title_string_offset,
	HUSTR_28 - title_string_offset,
	HUSTR_29 - title_string_offset,
	HUSTR_30 - title_string_offset,
	HUSTR_31 - title_string_offset,
	HUSTR_32 - title_string_offset
};

#if (EXE_VERSION >= EXE_VERSION_FINAL)
uint8_t	mapnamesp[] =	// Plutonia WAD map names.
{
	PHUSTR_1 - title_string_offset,
	PHUSTR_2 - title_string_offset,
	PHUSTR_3 - title_string_offset,
	PHUSTR_4 - title_string_offset,
	PHUSTR_5 - title_string_offset,
	PHUSTR_6 - title_string_offset,
	PHUSTR_7 - title_string_offset,
	PHUSTR_8 - title_string_offset,
	PHUSTR_9 - title_string_offset,
	PHUSTR_10 - title_string_offset,
	PHUSTR_11 - title_string_offset,

	PHUSTR_12 - title_string_offset,
	PHUSTR_13 - title_string_offset,
	PHUSTR_14 - title_string_offset,
	PHUSTR_15 - title_string_offset,
	PHUSTR_16 - title_string_offset,
	PHUSTR_17 - title_string_offset,
	PHUSTR_18 - title_string_offset,
	PHUSTR_19 - title_string_offset,
	PHUSTR_20 - title_string_offset,

	PHUSTR_21 - title_string_offset,
	PHUSTR_22 - title_string_offset,
	PHUSTR_23 - title_string_offset,
	PHUSTR_24 - title_string_offset,
	PHUSTR_25 - title_string_offset,
	PHUSTR_26 - title_string_offset,
	PHUSTR_27 - title_string_offset,
	PHUSTR_28 - title_string_offset,
	PHUSTR_29 - title_string_offset,
	PHUSTR_30 - title_string_offset,
	PHUSTR_31 - title_string_offset,
	PHUSTR_32 - title_string_offset
};


uint8_t mapnamest[] =	// TNT WAD map names.
{
	THUSTR_1 - title_string_offset,
	THUSTR_2 - title_string_offset,
	THUSTR_3 - title_string_offset,
	THUSTR_4 - title_string_offset,
	THUSTR_5 - title_string_offset,
	THUSTR_6 - title_string_offset,
	THUSTR_7 - title_string_offset,
	THUSTR_8 - title_string_offset,
	THUSTR_9 - title_string_offset,
	THUSTR_10 - title_string_offset,
	THUSTR_11 - title_string_offset,

	THUSTR_12 - title_string_offset,
	THUSTR_13 - title_string_offset,
	THUSTR_14 - title_string_offset,
	THUSTR_15 - title_string_offset,
	THUSTR_16 - title_string_offset,
	THUSTR_17 - title_string_offset,
	THUSTR_18 - title_string_offset,
	THUSTR_19 - title_string_offset,
	THUSTR_20 - title_string_offset,

	THUSTR_21 - title_string_offset,
	THUSTR_22 - title_string_offset,
	THUSTR_23 - title_string_offset,
	THUSTR_24 - title_string_offset,
	THUSTR_25 - title_string_offset,
	THUSTR_26 - title_string_offset,
	THUSTR_27 - title_string_offset,
	THUSTR_28 - title_string_offset,
	THUSTR_29 - title_string_offset,
	THUSTR_30 - title_string_offset,
	THUSTR_31 - title_string_offset,
	THUSTR_32 - title_string_offset
};
#endif


// Stage of animation:
//  0 = text, 1 = art screen, 2 = character cast
int16_t		finalestage;

int16_t		finalecount;



int16_t	e1text = E1TEXT;
int16_t	e2text = E2TEXT;
int16_t	e3text = E3TEXT;
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
int8_t*	e4text = E4TEXT;
#endif

int16_t	c1text = C1TEXT;
int16_t	c2text = C2TEXT;
int16_t	c3text = C3TEXT;
int16_t	c4text = C4TEXT;
int16_t	c5text = C5TEXT;
int16_t	c6text = C6TEXT;

#if (EXE_VERSION >= EXE_VERSION_FINAL)
int16_t	p1text = P1TEXT;
int16_t	p2text = P2TEXT;
int16_t	p3text = P3TEXT;
int16_t	p4text = P4TEXT;
int16_t	p5text = P5TEXT;
int16_t	p6text = P6TEXT;

int16_t	t1text = T1TEXT;
int16_t	t2text = T2TEXT;
int16_t	t3text = T3TEXT;
int16_t	t4text = T4TEXT;
int16_t	t5text = T5TEXT;
int16_t	t6text = T6TEXT;
#endif

int16_t	finaletext;
int8_t *	finaleflat;
int8_t	finale_laststage;



// 1 = message to be printed
uint8_t                     messageToPrint;
// ...and here is the message string!
int8_t                   menu_messageString[105];

// message x & y
int16_t                     messageLastMenuActive;

// timed message = no input from user
boolean                 messageNeedsInput;

void    (__near *messageRoutine)(int16_t response);


int8_t gammamsg[5] ={
    GAMMALVL0,
    GAMMALVL1,
    GAMMALVL2,
    GAMMALVL3,
    GAMMALVL4
};

int16_t endmsg[NUM_QUITMESSAGES] ={
    // DOOM1
    QUITMSG,
    QUITMSGD11,
    QUITMSGD12,
    QUITMSGD13,
    QUITMSGD14,
    QUITMSGD15,
    QUITMSGD16,
    QUITMSGD17
};

int16_t endmsg2[NUM_QUITMESSAGES] ={
    // QuitDOOM II messages
    QUITMSG,
    QUITMSGD21,
    QUITMSGD22,
    QUITMSGD23,
    QUITMSGD24,
    QUITMSGD25,
    QUITMSGD26,
    QUITMSGD27

};

// we are going to be entering a savegame string
int16_t                     saveStringEnter;
int16_t                     saveSlot;       // which slot to save in
int16_t                     saveCharIndex;  // which char we're editing
// old save description before edit
int8_t                    saveOldString[SAVESTRINGSIZE];



//int8_t                    savegamestrings[10*SAVESTRINGSIZE];


int16_t           itemOn;                 // menu item skull is on

// 
int16_t           skullAnimCounter;       // skull animation counter
int16_t           whichSkull;             // which skull to draw

// graphic name of skulls
int16_t    skullName[2] = {5, 6};

// current menudef
menu_t __near* currentMenu;      

int16_t     menu_mousewait = 0;
int16_t     menu_mousey = 0;
int16_t     menu_lasty = 0;
int16_t     menu_mousex = 0;
int16_t     menu_lastx = 0;
int16_t        menu_drawer_x;
int16_t        menu_drawer_y;



void __near M_ChooseSkill(int16_t choice);
void __near M_NewGame(int16_t choice);
void __near M_Options(int16_t choice);
void __near M_LoadGame(int16_t choice);
void __near M_SaveGame(int16_t choice);
void __near M_QuitDOOM(int16_t choice);
void __near M_Episode(int16_t choice);
void __near M_EndGame(int16_t choice);
void __near M_ChangeMessages(int16_t choice);
void __near M_ChangeDetail(int16_t choice);
void __near M_SizeDisplay(int16_t choice);
void __near M_Sound(int16_t choice);
void __near M_ChangeSensitivity(int16_t choice);
void __near M_ReadThis(int16_t choice);
void __near M_ReadThis2(int16_t choice);
void __near M_FinishReadThis(int16_t choice);
void __near M_LoadSelect(int16_t choice);
void __near M_SaveSelect(int16_t choice);
void __near M_SfxVol(int16_t choice);
void __near M_MusicVol(int16_t choice);



#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
void __near M_ReadThis(int16_t choice);
#else
void __near M_ReadThis2(int16_t choice);
#endif

void __near M_DrawMainMenu(void);
void __near M_DrawEpisode(void);
void __near M_DrawMainMenu(void);
void __near M_DrawNewGame(void);
void __near M_DrawOptions(void);
void __near M_DrawLoad(void);
void __near M_DrawSave(void);
void __near M_DrawSound(void);
void __near M_DrawReadThis1(void);
void __near M_DrawReadThis2(void);




menuitem_t MainMenu[]={
    {1,4,M_NewGame,'n'},
    {1,2,M_Options,'o'},
    {1,30,M_LoadGame,'l'},
    {1,29,M_SaveGame,'s'},
    // Another hickup with Special edition.
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
    {1,1,M_ReadThis,'r'},
#else
    {1,1,M_ReadThis2,'r'},
#endif
    {1,3,M_QuitDOOM,'q'}
};

menu_t  MainDef ={
    main_end,
    NULL,
    MainMenu,
    M_DrawMainMenu,
    97,64,
    0
};


#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    #define ep_end 4
#else 
    #define ep_end 3

#endif
#define newg_end 5
#define hurtme 2
#define opt_end 8
#define ep1 0
#define read1_end 1
#define read2_end 1
#define sound_end 4


menuitem_t EpisodeMenu[]={
    {1,17, M_Episode,'k'},
    {1,18, M_Episode,'t'},
    {1,19, M_Episode,'i'},
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    {1,46, M_Episode,'t'}
#endif
};

menu_t  EpiDef ={
    ep_end,             // # of menu items
    &MainDef,           // previous menu
    EpisodeMenu,        // menuitem_t ->
    M_DrawEpisode,      // drawing routine ->
    48,63,              // x,y
    ep1                 // lastOn
};



menuitem_t NewGameMenu[]={
    {1,21,       M_ChooseSkill, 'i'},
    {1,22,       M_ChooseSkill, 'h'},
    {1,20,        M_ChooseSkill, 'h'},
    {1,25,       M_ChooseSkill, 'u'},
    {1,26,       M_ChooseSkill, 'n'}
};

menu_t  NewDef ={
    newg_end,           // # of menu items
    &EpiDef,            // previous menu
    NewGameMenu,        // menuitem_t ->
    M_DrawNewGame,      // drawing routine ->
    48,63,              // x,y
    hurtme              // lastOn
};




menuitem_t OptionsMenu[]={
    {1,11,      M_EndGame,'e'},
    {1,13,       M_ChangeMessages,'m'},
    {1,35,      M_ChangeDetail,'g'},
    {2,37,      M_SizeDisplay,'s'},
    {-1,-1,0},
    {2,32,       M_ChangeSensitivity,'m'},
    {-1,-1,0},
    {1,27,        M_Sound,'s'}
};

menu_t  OptionsDef ={
    opt_end,
    &MainDef,
    OptionsMenu,
    M_DrawOptions,
    60,37,
    0
};

//
// Read This! MENU 1 & 2
//


menuitem_t ReadMenu1[] ={
    {1,-1,M_ReadThis2,0}
};

menu_t  ReadDef1 ={
    read1_end,
    &MainDef,
    ReadMenu1,
    M_DrawReadThis1,
    280,185,
    0
};


menuitem_t ReadMenu2[]={
    {1,-1,M_FinishReadThis,0}
};

menu_t  ReadDef2 ={
    read2_end,
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
    &ReadDef1,
#else
    NULL,
#endif
    ReadMenu2,
#if (EXE_VERSION < EXE_VERSION_FINAL)
    M_DrawReadThis2,
#else
    M_DrawReadThisRetail,
#endif
    330,175,
    0
};

//
// SOUND VOLUME MENU
//

menuitem_t SoundMenu[]={
    {2,40,M_SfxVol,'s'},
    {-1,-1,0},
    {2,41,M_MusicVol,'m'},
    {-1,-1,0}
};

menu_t  SoundDef ={
    sound_end,
    &OptionsDef,
    SoundMenu,
    M_DrawSound,
    80,64,
    0
};

//
// LOAD GAME MENU
//
#define load_end 6

menuitem_t LoadMenu[]={
    {1,-1, M_LoadSelect,'1'},
    {1,-1, M_LoadSelect,'2'},
    {1,-1, M_LoadSelect,'3'},
    {1,-1, M_LoadSelect,'4'},
    {1,-1, M_LoadSelect,'5'},
    {1,-1, M_LoadSelect,'6'}
};

menu_t  LoadDef ={
    load_end,
    &MainDef,
    LoadMenu,
    M_DrawLoad,
    80,54,
    0
};

//
// SAVE GAME MENU
//
menuitem_t SaveMenu[]={
    {1,-1, M_SaveSelect,'1'},
    {1,-1, M_SaveSelect,'2'},
    {1,-1, M_SaveSelect,'3'},
    {1,-1, M_SaveSelect,'4'},
    {1,-1, M_SaveSelect,'5'},
    {1,-1, M_SaveSelect,'6'}
};

menu_t  SaveDef ={
    load_end,
    &MainDef,
    SaveMenu,
    M_DrawSave,
    80,54,
    0
};

int8_t     menu_epi;
int8_t    detailNames[2]       = {33, 34};
int8_t    msgNames[2]          = {15, 14};



//
// M_QuitDOOM
//
int8_t     quitsounds[8] ={
    sfx_pldeth,
    sfx_dmpain,
    sfx_popain,
    sfx_slop,
    sfx_telept,
    sfx_posit1,
    sfx_posit3,
    sfx_sgtatk
};

int8_t     quitsounds2[8] ={
    sfx_vilact,
    sfx_getpow,
    sfx_boscub,
    sfx_slop,
    sfx_skeswg,
    sfx_kntdth,
    sfx_bspact,
    sfx_sgtatk
};
uint16_t  wipeduration = 0;

task HeadTask;
void( __interrupt __far_func *OldInt8)(void);
volatile int32_t TaskServiceRate = 0x10000L;
volatile int32_t TaskServiceCount = 0;

volatile int32_t TS_TimesInInterrupt;
int8_t TS_Installed = false;
volatile int32_t TS_InInterrupt = false;

int8_t NUMANIMS[NUMEPISODES] =
{
    10,
    9,
    6
};

wianim_t __far*wianims[NUMEPISODES] =
{
    epsd0animinfo,
    epsd1animinfo,
    epsd2animinfo
};


// used to accelerate or skip a stage
int16_t		acceleratestage;


 // specifies current state
stateenum_t	state;

// contains information passed into intermission
wbstartstruct_t __near*	wbs;

wbplayerstruct_t plrs;  // wbs->plyr[]

// used for general timing
uint16_t 		cnt;

// used for timing of background animation
uint16_t 		bcnt;

// signals to refresh everything for one frame

int16_t		cnt_kills;
int16_t		cnt_items;
int16_t		cnt_secret;
int16_t		cnt_time;
int16_t		cnt_par;
int16_t		cnt_pause;


boolean unloaded = false;

//
//	GRAPHICS
//


// You Are Here graphic
uint8_t		yahRef[2];

// splat
uint8_t		splatRef;


// 0-9 graphic
uint8_t		numRef[10];
boolean		snl_pointeron = false;
int16_t	sp_state;



castinfo_t	castorder[] = {
    {CC_ZOMBIE-castorderoffset, MT_POSSESSED},
    {CC_SHOTGUN-castorderoffset, MT_SHOTGUY},
    {CC_HEAVY-castorderoffset, MT_CHAINGUY},
    {CC_IMP-castorderoffset, MT_TROOP},
    {CC_DEMON-castorderoffset, MT_SERGEANT},
    {CC_LOST-castorderoffset, MT_SKULL},
    {CC_CACO-castorderoffset, MT_HEAD},
    {CC_HELL-castorderoffset, MT_KNIGHT},
    {CC_BARON-castorderoffset, MT_BRUISER},
    {CC_ARACH-castorderoffset, MT_BABY},
    {CC_PAIN-castorderoffset, MT_PAIN},
    {CC_REVEN-castorderoffset, MT_UNDEAD},
    {CC_MANCU-castorderoffset, MT_FATSO},
    {CC_ARCH-castorderoffset, MT_VILE},
    {CC_SPIDER-castorderoffset, MT_SPIDER},
    {CC_CYBER-castorderoffset, MT_CYBORG},
    {CC_HERO-castorderoffset, MT_PLAYER},

};

int8_t		castnum;
int8_t		casttics;
state_t __far*	caststate;
boolean		castdeath;
int8_t		castframes;
int8_t		castonmelee;
boolean		castattacking;

boolean  st_stopped = true;
uint16_t armsbgarray[1] = { armsbg };

byte*           save_p;

THINKERREF	activeceilings[MAXCEILINGS];
THINKERREF		activeplats[MAXPLATS];


weaponinfo_t	weaponinfo[NUMWEAPONS] =
{
    {
	// fist
	am_noammo,
	S_PUNCHUP,
	S_PUNCHDOWN,
	S_PUNCH,
	S_PUNCH1,
	S_NULL
    },	
    {
	// pistol
	am_clip,
	S_PISTOLUP,
	S_PISTOLDOWN,
	S_PISTOL,
	S_PISTOL1,
	S_PISTOLFLASH
    },	
    {
	// shotgun
	am_shell,
	S_SGUNUP,
	S_SGUNDOWN,
	S_SGUN,
	S_SGUN1,
	S_SGUNFLASH1
    },
    {
	// chaingun
	am_clip,
	S_CHAINUP,
	S_CHAINDOWN,
	S_CHAIN,
	S_CHAIN1,
	S_CHAINFLASH1
    },
    {
	// missile launcher
	am_misl,
	S_MISSILEUP,
	S_MISSILEDOWN,
	S_MISSILE,
	S_MISSILE1,
	S_MISSILEFLASH1
    },
    {
	// plasma rifle
	am_cell,
	S_PLASMAUP,
	S_PLASMADOWN,
	S_PLASMA,
	S_PLASMA1,
	S_PLASMAFLASH1
    },
    {
	// bfg 9000
	am_cell,
	S_BFGUP,
	S_BFGDOWN,
	S_BFG,
	S_BFG1,
	S_BFGFLASH1
    },
    {
	// chainsaw
	am_noammo,
	S_SAWUP,
	S_SAWDOWN,
	S_SAW,
	S_SAW1,
	S_NULL
    },
    {
	// super shotgun
	am_shell,
	S_DSGUNUP,
	S_DSGUNDOWN,
	S_DSGUN,
	S_DSGUN1,
	S_DSGUNFLASH1
    },	
};


fixed_t		bulletslope;
uint16_t		switchlist[MAXSWITCHES * 2];
int16_t		numswitches;
button_t        buttonlist[MAXBUTTONS];
int16_t	maxammo[NUMAMMO] = {200, 50, 300, 50};
int8_t	clipammo[NUMAMMO] = {10, 4, 20, 1};
boolean		onground;
fixed_t_union	leveltime;
int16_t currentThinkerListHead;
// cached 'last used' mobjs for functions that operate on a mobj and where the mobj is often used right after. 
mobj_t __far* setStateReturn;
mobj_pos_t __far* setStateReturn_pos;
angle_t __far* tantoangle;
uint16_t oldentertics;

boolean brainspit_easy = 0;
   

//
// P_NewChaseDir related LUT.
//
dirtype_t opposite[] =
{
  DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST,
  DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR
};

dirtype_t diags[] =
{
    DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST
};

uint16_t movedirangles[8] = {
	0x0000,
	0x2000,
	0x4000,
	0x6000,
	0x8000,
	0xA000,
	0xC000,
	0xE000
};


THINKERREF		braintargets[32];
int16_t		numbraintargets;
int16_t		braintargeton;

THINKERREF		corpsehitRef;
mobj_t __far*		vileobj;
fixed_t_union		viletryx;
fixed_t_union		viletryy;


fixed_t_union		tmbbox[4];
mobj_t __far*		tmthing;
mobj_pos_t __far*		tmthing_pos;
int16_t		tmflags1;
fixed_t_union		tmx;
fixed_t_union		tmy;


// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".
boolean		floatok;

short_height_t		tmfloorz;
short_height_t		tmceilingz;
short_height_t		tmdropoffz;

// keep track of the line that lowers the ceiling,
// so missiles don't explode against sky hack walls
int16_t		ceilinglinenum;

// keep track of special lines as they are hit,
// but don't process them until the move is proven valid

int16_t		spechit[MAXSPECIALCROSS];
int16_t		numspechit;

int16_t lastcalculatedsector;
//
// RADIUS ATTACK
//
mobj_t __far*		bombsource;
mobj_t __far*		bombspot;
mobj_pos_t __far*		bombspot_pos;
int16_t		bombdamage;



//
// SLIDE MOVE
// Allows the player to slide along any angled walls.
//
fixed_t_union		bestslidefrac;
//fixed_t_union		secondslidefrac;

int16_t		bestslidelinenum;
//int16_t		secondslidelinenum;

fixed_t_union		tmxmove;
fixed_t_union		tmymove;

//
// P_LineAttack
//
mobj_t __far*		linetarget;	// who got hit (or NULL)
mobj_pos_t __far*		linetarget_pos;	// who got hit (or NULL)
mobj_t __far*		shootthing;

// Height if not aiming up or down
// ???: use slope for monsters?
fixed_t_union		shootz;	

int16_t		la_damage;
int16_t		attackrange16;

fixed_t		aimslope;

//
// P_CheckSight
//
fixed_t		sightzstart;		// eye z of looker
fixed_t		topslope;
fixed_t		bottomslope;		// slopes to top and bottom of target

divline_t	strace;			// from t1 to t2
fixed_t_union		cachedt2x;
fixed_t_union		cachedt2y;

boolean		crushchange;
boolean		nofit;
 intercept_t __far*	intercept_p;

divline_t 	trace;
boolean 	earlyout;
lineopening_t lineopening;
divline_t		dl;



//
//      source animation definition
//


p_spec_anim_t	anims[MAXANIMS];
p_spec_anim_t __near*		lastanim;
boolean		levelTimer;
ticcount_t		levelTimeCount;
int16_t		numlinespecials;



int16_t		curseg;
seg_render_t __far* curseg_render;
sector_t __far*	frontsector;
sector_t __far*	backsector;

drawseg_t __far*	ds_p;


// newend is one past the last valid seg
cliprange_t __near*	newend;
cliprange_t	solidsegs[MAXSEGS];
uint8_t usedcompositetexturepagemem[NUM_TEXTURE_PAGES];
uint8_t usedpatchpagemem[NUM_PATCH_CACHE_PAGES];
uint8_t usedspritepagemem[NUM_SPRITE_CACHE_PAGES];
uint16_t                     numlumps;
FILE* wadfilefp;
FILE* wadfilefp2;
  
int16_t				dirtybox[4]; 
segment_t screen_segments[5] = {0x8000,0x8000,0x7000,0x6000,0x9C00};


//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
int16_t             numvertexes;
int16_t             numsegs;
int16_t             numsectors;
int16_t             numsubsectors;
int16_t             numnodes;
int16_t             numlines;
int16_t             numsides;


#ifdef PRECALCULATE_OPENINGS
lineopening_t __far*	lineopenings;
#endif

// BLOCKMAP
// Created from axis aligned bounding box
// of the map, a rectangular array of
// blocks of size ...
// Used to speed up collision detection
// by spatial subdivision in 2D.
//
// Blockmap size.
int16_t             bmapwidth;
int16_t             bmapheight;     // size in mapblocks

								// offsets in blockmap are from here

// origin of block map
int16_t         bmaporgx;
int16_t         bmaporgy;





#if defined(__CHIPSET_BUILD)

// these are prepared for calls to outsw with autoincrementing ems register on

uint16_t pageswapargs[total_pages] = {

	_NPR(PAGE_4000_OFFSET),	 _NPR(PAGE_4400_OFFSET),	 _NPR(PAGE_4800_OFFSET),	 _NPR(PAGE_4C00_OFFSET),	
	_NPR(PAGE_5000_OFFSET),  _NPR(PAGE_5400_OFFSET),	 _NPR(PAGE_5800_OFFSET),	 _NPR(PAGE_5C00_OFFSET),	 
	_NPR(PAGE_6000_OFFSET),  _NPR(PAGE_6400_OFFSET),	 _EPR(13),	                 _NPR(PAGE_6C00_OFFSET),	
	_NPR(PAGE_7000_OFFSET),	 _NPR(PAGE_7400_OFFSET),	 _NPR(PAGE_7800_OFFSET),	 _NPR(PAGE_7C00_OFFSET),	
	_NPR(PAGE_8000_OFFSET),	 _NPR(PAGE_8400_OFFSET),	 _NPR(PAGE_8800_OFFSET),	 _NPR(PAGE_8C00_OFFSET),	
	_EPR(15), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE)    , 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), 

	// render
	_EPR(0),				 _EPR(1),					 _EPR(2),					 _EPR(3),						
	_NPR(PAGE_5000_OFFSET),  _NPR(PAGE_5400_OFFSET),	 _NPR(PAGE_5800_OFFSET),	 _EPR(14),						  // same as physics as its unused for physics..
	_EPR(11), 				 _EPR(12),					 _EPR(13),					 _NPR(PAGE_6C00_OFFSET),		  // shared 6400 6800 with physics
	_EPR(7),				 _EPR(8),					 _EPR(9),					 _EPR(10),						
	_EPR(4),				 _EPR(5),					 _EPR(6),					 _EPR(EMS_VISPLANE_EXTRA_PAGE),
	_EPR(FIRST_TEXTURE_LOGICAL_PAGE + 0),	 _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 1),	 _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 2),	 _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 3),	  // texture cache area
	_EPR(0),				 _EPR(1),					 _EPR(2),					 _EPR(3),						

	
	// status/hud
	_NPR(PAGE_9C00_OFFSET), 		  //SCREEN4_LOGICAL_PAGE
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 0), 
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 1), 
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 2), 
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 3), 
	_NPR(PAGE_6000_OFFSET), 		  // STRINGS_LOGICAL_PAGE
	// demo
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 0), 
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 1), 
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 2), 
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 3), 

 
// we use 0x5000 as a  'scratch' page frame for certain things
// scratch 5000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), 

// but sometimes we need that in the 0x8000 segment..
// scratch 8000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), 
		// and sometimes we need that in the 0x7000 segment..
	// scratch 7000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), 

	// puts sky_texture in the right place, adjacent to flat cache for planes
	//  RenderPlane
	_NPR(PAGE_9000_OFFSET), 	
	_NPR(PAGE_9400_OFFSET), 	
	_NPR(PAGE_9800_OFFSET), 	
	
	_EPR(PALETTE_LOGICAL_PAGE),       // SPAN CODE SHOVED IN HERE. used to be mobjposlist but thats unused during planes
														
	//PHYSICS_RENDER_6800_PAGE,           // remap colormaps to be before drawspan code
														


	// flat cache
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 0), 
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 1), 
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 2), 
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 3), 

	// sprite cache
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 0), 
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 1), 
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 2), 
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 3), 

	// flat cache undo   NOTE: we just call it with seven params to set everything up for sprites
	_EPR(RENDER_7800_PAGE), 
	_EPR(RENDER_7C00_PAGE), 
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE), 
	//masked
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE+1), 
	_EPR(PHYSICS_RENDER_6800_PAGE),  // put colormaps where vissprites used to be?


	// palette
	_NPR(PAGE_8000_OFFSET), 
	_NPR(PAGE_8400_OFFSET), 
	_NPR(PAGE_8800_OFFSET), 
	_NPR(PAGE_8C00_OFFSET),  // SCREEN0_LOGICAL_PAGE
	_EPR(PALETTE_LOGICAL_PAGE), 

 
// menu 
	_NPR(PAGE_6000_OFFSET) 				  	  ,  // STRINGS_LOGICAL_PAGE
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 4), 
	_NPR(PAGE_6800_OFFSET)  				  , 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 5), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 0), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 1), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 2), 
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 3), 

// intermission 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 4), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 5), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 6), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 7), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 0), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 1), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 2), 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 3), 
// wipe/intermission, shared pages
	_NPR(PAGE_8000_OFFSET),  // SCREEN0_LOGICAL_PAGE
	_NPR(PAGE_8400_OFFSET), 
	_NPR(PAGE_8800_OFFSET), 
	_NPR(PAGE_8C00_OFFSET), 
	_EPR(SCREEN1_LOGICAL_PAGE + 0), 
	_EPR(SCREEN1_LOGICAL_PAGE + 1), 
	_EPR(SCREEN1_LOGICAL_PAGE + 2), 
	_EPR(SCREEN1_LOGICAL_PAGE + 3), 

	_EPR(SCREEN3_LOGICAL_PAGE + 0), 
	_EPR(SCREEN3_LOGICAL_PAGE + 1),  // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 2),  // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 3),  // shared with visplanes
	_EPR(SCREEN2_LOGICAL_PAGE + 0), 
	_EPR(SCREEN2_LOGICAL_PAGE + 1), 
	_EPR(SCREEN2_LOGICAL_PAGE + 2), 
	_EPR(SCREEN2_LOGICAL_PAGE + 3), 

	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE	), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), 
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), 

	_EPR(EMS_VISPLANE_EXTRA_PAGE)

};
#else

int16_t emshandle;
int16_t pagenum9000;

uint16_t pageswapargs[total_pages] = {
	_NPR(PAGE_4000_OFFSET),	PAGE_4000_OFFSET, _NPR(PAGE_4400_OFFSET),	PAGE_4400_OFFSET, _NPR(PAGE_4800_OFFSET),	PAGE_4800_OFFSET, _NPR(PAGE_4C00_OFFSET),	PAGE_4C00_OFFSET,
	_NPR(PAGE_5000_OFFSET), PAGE_5000_OFFSET, _NPR(PAGE_5400_OFFSET),	PAGE_5400_OFFSET, _NPR(PAGE_5800_OFFSET),	PAGE_5800_OFFSET, _NPR(PAGE_5C00_OFFSET),	PAGE_5C00_OFFSET, 
	_NPR(PAGE_6000_OFFSET), PAGE_6000_OFFSET, _NPR(PAGE_6400_OFFSET),	PAGE_6400_OFFSET, _EPR(13),	                PAGE_6800_OFFSET, _NPR(PAGE_6C00_OFFSET),	PAGE_6C00_OFFSET,
	_NPR(PAGE_7000_OFFSET),	PAGE_7000_OFFSET, _NPR(PAGE_7400_OFFSET),	PAGE_7400_OFFSET, _NPR(PAGE_7800_OFFSET),	PAGE_7800_OFFSET, _NPR(PAGE_7C00_OFFSET),	PAGE_7C00_OFFSET,
	_NPR(PAGE_8000_OFFSET),	PAGE_8000_OFFSET, _NPR(PAGE_8400_OFFSET),	PAGE_8400_OFFSET, _NPR(PAGE_8800_OFFSET),	PAGE_8800_OFFSET, _NPR(PAGE_8C00_OFFSET),	PAGE_8C00_OFFSET,
	_EPR(15), PAGE_9000_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE)    , PAGE_9400_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), PAGE_9800_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), PAGE_9C00_OFFSET,

 

	// render
	_EPR(0),				PAGE_4000_OFFSET, _EPR(1),					PAGE_4400_OFFSET, _EPR(2),					PAGE_4800_OFFSET, _EPR(3),						PAGE_4C00_OFFSET,
	_NPR(PAGE_5000_OFFSET), PAGE_5000_OFFSET, _NPR(PAGE_5400_OFFSET),	PAGE_5400_OFFSET, _NPR(PAGE_5800_OFFSET),	PAGE_5800_OFFSET, _EPR(14),						PAGE_5C00_OFFSET,  // same as physics as its unused for physics..
	_EPR(11), 				PAGE_6000_OFFSET, _EPR(12),					PAGE_6400_OFFSET, _EPR(13),					PAGE_6800_OFFSET, _NPR(PAGE_6C00_OFFSET),		PAGE_6C00_OFFSET,  // shared 6400 6800 with physics
	_EPR(7),				PAGE_7000_OFFSET, _EPR(8),					PAGE_7400_OFFSET, _EPR(9),					PAGE_7800_OFFSET, _EPR(10),						PAGE_7C00_OFFSET,
	_EPR(4),				PAGE_8000_OFFSET, _EPR(5),					PAGE_8400_OFFSET, _EPR(6),					PAGE_8800_OFFSET, _EPR(EMS_VISPLANE_EXTRA_PAGE),PAGE_8C00_OFFSET,
	_EPR(FIRST_TEXTURE_LOGICAL_PAGE + 0),	PAGE_9000_OFFSET, _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 1),	PAGE_9400_OFFSET, _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 2),	PAGE_9800_OFFSET, _EPR(FIRST_TEXTURE_LOGICAL_PAGE + 3),	PAGE_9C00_OFFSET,  // texture cache area

	_EPR(0),				PAGE_9000_OFFSET, _EPR(1),					PAGE_9400_OFFSET, _EPR(2),					PAGE_9800_OFFSET, _EPR(3),						PAGE_9C00_OFFSET,

	
	// status/hud
	_NPR(PAGE_9C00_OFFSET), 		 PAGE_9C00_OFFSET, //SCREEN4_LOGICAL_PAGE
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_STATUS_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,
	_NPR(PAGE_6000_OFFSET), 		 PAGE_6000_OFFSET, // STRINGS_LOGICAL_PAGE
	// demo
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 0), PAGE_5000_OFFSET,
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 1), PAGE_5400_OFFSET,
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 2), PAGE_5800_OFFSET,
	_EPR(FIRST_DEMO_LOGICAL_PAGE + 3), PAGE_5C00_OFFSET,

 
// we use 0x5000 as a  'scratch' page frame for certain things
// scratch 5000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), PAGE_5000_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), PAGE_5400_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), PAGE_5800_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), PAGE_5C00_OFFSET,

// but sometimes we need that in the 0x8000 segment..
// scratch 8000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), PAGE_8000_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), PAGE_8400_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), PAGE_8800_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), PAGE_8C00_OFFSET,
		// and sometimes we need that in the 0x7000 segment..
	// scratch 7000
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_SCRATCH_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,

	// puts sky_texture in the right place, adjacent to flat cache for planes
	//  RenderPlane
	_NPR(PAGE_9000_OFFSET), 	PAGE_9000_OFFSET,
	_NPR(PAGE_9400_OFFSET), 	PAGE_9400_OFFSET,
	_NPR(PAGE_9800_OFFSET), 	PAGE_9800_OFFSET,
	
	_EPR(PALETTE_LOGICAL_PAGE), PAGE_6C00_OFFSET,      // SPAN CODE SHOVED IN HERE. used to be mobjposlist but thats unused during planes
														
	//PHYSICS_RENDER_6800_PAGE,     PAGE_6800_OFFSET,      // remap colormaps to be before drawspan code

	// flat cache
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,

	// flat cache undo   NOTE: we just call it with seven params to set everything up for sprites
	// sprite cache
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 0), PAGE_6800_OFFSET,
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 1), PAGE_6C00_OFFSET,
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 2), PAGE_7000_OFFSET,
	_EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + 3), PAGE_7400_OFFSET,

	_EPR(RENDER_7800_PAGE), PAGE_7800_OFFSET,
	_EPR(RENDER_7C00_PAGE), PAGE_7C00_OFFSET,
	//masked
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE), PAGE_8400_OFFSET,
	_EPR(FIRST_EXTRA_MASKED_DATA_PAGE+1), PAGE_8800_OFFSET,
	_EPR(PHYSICS_RENDER_6800_PAGE), PAGE_8C00_OFFSET, // put colormaps where vissprites used to be?


	// palette
	_NPR(PAGE_8000_OFFSET), PAGE_8000_OFFSET,
	_NPR(PAGE_8400_OFFSET), PAGE_8400_OFFSET,
	_NPR(PAGE_8800_OFFSET), PAGE_8800_OFFSET,
	_NPR(PAGE_8C00_OFFSET), PAGE_8C00_OFFSET, // SCREEN0_LOGICAL_PAGE
	_EPR(PALETTE_LOGICAL_PAGE), PAGE_9000_OFFSET,

 
// menu 
	_NPR(PAGE_6000_OFFSET) 				  	  , PAGE_6000_OFFSET, // STRINGS_LOGICAL_PAGE
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 4), PAGE_6400_OFFSET,
	_NPR(PAGE_6800_OFFSET)  				  , PAGE_6800_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 5), PAGE_6C00_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,

// intermission 
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 4), PAGE_6000_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 5), PAGE_6400_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 6), PAGE_6800_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 7), PAGE_6C00_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,
// wipe/intermission, shared pages
	_NPR(PAGE_8000_OFFSET), PAGE_8000_OFFSET, // SCREEN0_LOGICAL_PAGE
	_NPR(PAGE_8400_OFFSET), PAGE_8400_OFFSET,
	_NPR(PAGE_8800_OFFSET), PAGE_8800_OFFSET,
	_NPR(PAGE_8C00_OFFSET), PAGE_8C00_OFFSET,
	// wipe start
	_EPR(SCREEN1_LOGICAL_PAGE + 0), PAGE_9000_OFFSET,
	_EPR(SCREEN1_LOGICAL_PAGE + 1), PAGE_9400_OFFSET,
	_EPR(SCREEN1_LOGICAL_PAGE + 2), PAGE_9800_OFFSET,
	_EPR(SCREEN1_LOGICAL_PAGE + 3), PAGE_9C00_OFFSET,

	_EPR(SCREEN3_LOGICAL_PAGE + 0), PAGE_6000_OFFSET,
	_EPR(SCREEN3_LOGICAL_PAGE + 1), PAGE_6400_OFFSET, // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 2), PAGE_6800_OFFSET, // shared with visplanes
	_EPR(SCREEN3_LOGICAL_PAGE + 3), PAGE_6C00_OFFSET, // shared with visplanes
	_EPR(SCREEN2_LOGICAL_PAGE + 0), PAGE_7000_OFFSET,
	_EPR(SCREEN2_LOGICAL_PAGE + 1), PAGE_7400_OFFSET,
	_EPR(SCREEN2_LOGICAL_PAGE + 2), PAGE_7800_OFFSET,
	_EPR(SCREEN2_LOGICAL_PAGE + 3), PAGE_7C00_OFFSET,
	//FIRST_WIPE_LOGICAL_PAGE, PAGE_9000_OFFSET,
	

	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE	), PAGE_5400_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 1), PAGE_5800_OFFSET,
	_EPR(FIRST_LUMPINFO_LOGICAL_PAGE + 2), PAGE_5C00_OFFSET,

	_EPR(EMS_VISPLANE_EXTRA_PAGE), 		   PAGE_8400_OFFSET,



};

#endif

  



int8_t current5000State = PAGE_5000_UNMAPPED;
int8_t last5000State = PAGE_5000_UNMAPPED;
int8_t current9000State = PAGE_9000_UNMAPPED;
int8_t last9000State = PAGE_9000_UNMAPPED;


#ifdef DETAILED_BENCH_STATS
int32_t taskswitchcount = 0;
int32_t texturepageswitchcount = 0;
int32_t patchpageswitchcount = 0;
int32_t compositepageswitchcount = 0;
int32_t spritepageswitchcount = 0;
int16_t benchtexturetype = 0;
int32_t flatpageswitchcount = 0;
int32_t scratchpageswitchcount = 0;
int32_t lumpinfo5000switchcount = 0;
int32_t lumpinfo9000switchcount = 0;
int16_t spritecacheevictcount = 0;
int16_t flatcacheevictcount = 0;
int16_t patchcacheevictcount = 0;
int16_t compositecacheevictcount = 0;
int32_t visplaneswitchcount = 0;

#endif

int8_t currenttask = -1;

int8_t ems_backfill_page_order[24] = { 0, 1, 2, 3, -4, -3, -2, -1, -8, -7, -6, -5, -12, -11, -10, -9, -16, -15, -14, -13, -20, -19, -18, -17 };
