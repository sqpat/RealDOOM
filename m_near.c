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
#include <dos.h>


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

 



int32_t totalpatchsize = 0;


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

