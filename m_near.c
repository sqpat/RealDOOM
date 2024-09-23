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
#include "d_englsh.h"
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



int8_t*           wadfiles[MAXWADFILES];


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


byte __far*		viewimage;
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

int8_t currentemsvisplanepage = 0; 
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
int16_t setval = 0;


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

#define R (1 << 4)
mline_t triangle_guy[] = {
    { { -.867*R, -.5*R }, { .867*R, -.5*R } },
    { { .867*R, -.5*R } , { 0, R } },
    { { 0, R }, { -.867*R, -.5*R } }
};
#undef R

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

