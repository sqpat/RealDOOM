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

// eventually, DS will be fixed to 0x3C00 or so. Then, these will all 
// become casted #define variable locations rather than linked variables.
// this will make it easier to build collections of function binaries, 
// export them to file and load them at runtime into EMS memory locations





extern const int8_t         snd_prefixen[];
extern int16_t              snd_SBport;
extern uint8_t              snd_SBirq, snd_SBdma; // sound blaster variables
extern int16_t              snd_Mport; // midi variables

extern uint8_t              snd_MusicVolume; // maximum volume for music
extern uint8_t              snd_SfxVolume; // maximum volume for sound

extern uint8_t              snd_SfxDevice; // current sfx card # (index to dmxCodes)
extern uint8_t              snd_MusicDevice; // current music card # (index to dmxCodes)
extern uint8_t              snd_DesiredSfxDevice;
extern uint8_t              snd_DesiredMusicDevice;
extern uint8_t              snd_SBport8bit;
extern uint8_t              snd_Mport8bit;


extern boolean              skipdirectdraws;
// wipegamestate can be set to -1 to force a wipe on the next draw
extern gamestate_t          wipegamestate;


#define MAXWADFILES             3

extern int8_t*              wadfiles[MAXWADFILES];


extern boolean              nomonsters;     // checkparm of -nomonsters
extern boolean              respawnparm;    // checkparm of -respawn
extern boolean              fastparm;       // checkparm of -fast

extern boolean              singletics;


extern skill_t              startskill;
extern int8_t               startepisode;
extern int8_t               startmap;
extern boolean              autostart;


extern boolean              advancedemo;

extern boolean              modifiedgame;

extern boolean              shareware;
extern boolean              registered;
extern boolean              commercial;

extern int8_t               demosequence;

extern int16_t              pagetic;
extern int8_t               *pagename;


#ifdef DETAILED_BENCH_STATS
extern uint16_t             rendertics;
extern uint16_t             physicstics;
extern uint16_t             othertics;
extern uint16_t             cachedtics;
extern uint16_t             cachedrendertics;
extern uint16_t             rendersetuptics;
extern uint16_t             renderplayerviewtics;
extern uint16_t             renderpostplayerviewtics;

extern uint16_t             renderplayersetuptics;
extern uint16_t             renderplayerbsptics;
extern uint16_t             renderplayerplanetics;
extern uint16_t             renderplayermaskedtics;
extern uint16_t             cachedrenderplayertics;
#endif

extern int8_t		        eventhead;
extern int8_t		        eventtail;

extern uint8_t              mouseSensitivity;       
extern uint8_t              showMessages;
extern uint8_t              sfxVolume;
extern uint8_t              musicVolume;
extern uint8_t              detailLevel;
extern uint8_t              screenblocks;           
extern uint8_t              screenSize;
extern int8_t               quickSaveSlot;
extern boolean              inhelpscreens;
extern boolean              menuactive;
extern segment_t 		    dc_colormap_segment;  
extern uint8_t 		        dc_colormap_index; 
extern int16_t			    dc_x; 
extern int16_t			    dc_yl; 
extern int16_t		    	dc_yh; 
extern fixed_t			    dc_iscale; 
extern fixed_t_union	    dc_texturemid;
extern segment_t		    dc_source_segment;
extern byte __far*		    viewimage;
extern int16_t		        viewwidth;
extern int16_t		        scaledviewwidth;
extern int16_t		        viewheight;
extern int16_t		        viewwindowx;
extern int16_t		        viewwindowy; 
extern int16_t		        viewwindowoffset;
extern int16_t		        sp_bp_safe_space[2];
extern int16_t		        ss_variable_space[18];
extern int8_t  	            spanfunc_main_loop_count;
extern uint8_t 	            spanfunc_inner_loop_count[4];
extern uint8_t              spanfunc_outp[4];
extern int16_t    	        spanfunc_prt[4];
extern uint16_t             spanfunc_destview_offset[4];
extern int8_t	            fuzzpos; 
extern int16_t              ds_y;
extern int16_t              ds_x1;
extern int16_t              ds_x2;
extern segment_t		    ds_colormap_segment;
extern uint8_t		        ds_colormap_index;
extern segment_t            ds_source_segment;
extern int16_t				lastvisplane;
extern int16_t				floorplaneindex;
extern int16_t				ceilingplaneindex;
extern uint16_t 		    lastopening;
extern uint8_t __far*	    planezlight;
extern fixed_t			    planeheight;
extern fixed_t			    basexscale;
extern fixed_t			    baseyscale;
extern int8_t               currentemsvisplanepage; 
extern segment_t            visplanelookupsegments[3];
extern int8_t               ceilphyspage;
extern int8_t               floorphyspage;
extern int16_t              currentflatpage[4];
extern int8_t               allocatedflatsperpage[NUM_FLAT_CACHE_PAGES];
extern int8_t               visplanedirty;
extern int8_t               skytextureloaded;
extern int16_t              r_cachedplayerMobjsecnum;
extern state_t              r_cachedstatecopy[2];
extern int16_t			    validcount;
extern uint8_t		        fixedcolormap;
extern int16_t			    centerx;
extern int16_t			    centery;
extern fixed_t_union		centeryfrac_shiftright4;
extern fixed_t_union		viewx;
extern fixed_t_union		viewy;
extern fixed_t_union		viewz;
extern short_height_t		viewz_shortheight;
extern angle_t			    viewangle;
extern fineangle_t			viewangle_shiftright3;
extern int16_t_union		detailshift;	
extern uint8_t				detailshiftitercount;
extern uint8_t				detailshift2minus;
extern uint16_t             detailshiftandval;
extern int16_t 			    setdetail;
extern uint16_t			    clipangle;
extern uint16_t			    fieldofview;
extern uint8_t			    extralight;			
extern boolean		        setsizeneeded;
extern uint8_t		        setblocks;
extern uint8_t			    skyflatnum;
extern uint16_t			    skytexture;
extern boolean		        segtextured;	
extern boolean		        markfloor;	
extern boolean		        markceiling;
extern boolean		        maskedtexture;
extern uint16_t		        toptexture;
extern uint16_t		        bottomtexture;
extern uint16_t		        midtexture;
extern fineangle_t	        rw_normalangle;
extern angle_t			    rw_angle1;
extern int16_t		        rw_x;
extern int16_t		        rw_stopx;
extern fineangle_t		    rw_centerangle;
extern fixed_t_union		rw_offset;
extern fixed_t		        rw_distance;
extern fixed_t_union		rw_scale;
extern fixed_t_union		rw_midtexturemid;
extern fixed_t_union		rw_toptexturemid;
extern fixed_t_union		rw_bottomtexturemid;
extern fixed_t_union		worldtop;
extern fixed_t_union		worldbottom;
extern fixed_t_union		worldhigh;
extern fixed_t_union		worldlow;
extern fixed_t		        pixhigh;
extern fixed_t		        pixlow;
extern fixed_t		        pixhighstep;
extern fixed_t		        pixlowstep;
extern fixed_t		        topfrac;
extern fixed_t		        topstep;
extern fixed_t		        bottomfrac;
extern fixed_t		        bottomstep;
extern uint8_t __far*	    walllights;
extern uint16_t __far*		maskedtexturecol;
extern byte __far *         ceiltop;
extern byte __far *         floortop;
extern uint16_t             pspritescale;
extern fixed_t              pspriteiscale;
extern uint8_t __far*       spritelights;
extern spritedef_t __far*	sprites;
extern int16_t              numsprites;
extern vissprite_t __far*   vissprite_p;
extern uint8_t              vsprsortedheadfirst;
extern segment_t            lastvisspritesegment;
extern int16_t              lastvisspritepatch;
extern int16_t              firstflat;
extern int16_t              numflats;
extern int16_t              firstpatch;
extern int16_t              numpatches;
extern int16_t              firstspritelump;
extern int16_t              numspritelumps;
extern int16_t              numtextures;
extern int16_t              activetexturepages[4];
extern uint8_t              activenumpages[4];
extern int16_t              textureLRU[4];
extern int16_t              activespritepages[4];
extern uint8_t              activespritenumpages[4];
extern int16_t              spriteLRU[4];
extern int32_t              totalpatchsize;
extern int8_t               spritecache_head;
extern int8_t               spritecache_tail;
extern int8_t               flatcache_head;
extern int8_t               flatcache_tail;
extern int8_t               patchcache_head;
extern int8_t               patchcache_tail;
extern int8_t               texturecache_head;
extern int8_t               texturecache_tail;
extern segment_t            cachedsegmentlump;
extern segment_t            cachedsegmenttex;
extern int16_t              cachedlump;
extern int16_t              cachedtex;
extern segment_t            cachedsegmentlump2;
extern segment_t            cachedsegmenttex2;
extern int16_t              cachedlump2;
extern int16_t              cachedtex2;
extern uint8_t              cachedcollength;
extern uint8_t              cachedcollength2;

extern int8_t               active_visplanes[5];
extern byte                 cachedbyteheight;
extern uint8_t              cachedcol;
extern int16_t              setval;
extern int16_t              lightmult48lookup[16];
extern int16_t              lightshift7lookup[16];
extern segment_t            pagesegments[4];
extern uint16_t             MULT_4096[4];
extern uint16_t             MULT_256[4];
extern uint16_t             FLAT_CACHE_PAGE[4];
extern uint8_t              quality_port_lookup[12]; 
extern uint16_t             vga_read_port_lookup[12];
extern uint16_t             visplane_offset[25];


extern void                 (__far* R_DrawColumnPrepCallHigh)(uint16_t);
extern void                 (__far* R_DrawColumnPrepCall)(uint16_t);
extern int16_t __far*       mfloorclip;
extern int16_t __far*       mceilingclip;

extern fixed_t_union        spryscale;
extern fixed_t_union        sprtopscreen;
extern void                 (__far* R_DrawFuzzColumnCallHigh)(uint16_t, byte __far *);
