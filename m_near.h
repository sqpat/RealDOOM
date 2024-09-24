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

#include "dutils.h"

#include "am_map.h"
#include "m_memory.h"
#include "m_misc.h"
#include "d_event.h"
#include "d_ticcmd.h"
#include "st_lib.h"
#include "st_stuff.h"
#include "hu_lib.h"
#include "dmx.h"
#include "m_menu.h"
#include "wi_stuff.h"
#include "p_spec.h"


#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
#define NUMEPISODES	3
#else
#define NUMEPISODES	4
#endif
#define NUMMAPS		9

#define NUM_QUITMESSAGES   8
 
//
// Globally visible constants.
//
#define HU_FONTSTART	'!'	// the first font characters
#define HU_FONTEND	'_'	// the last font characters

// Calculate # of glyphs in font.
#define HU_FONTSIZE	(HU_FONTEND - HU_FONTSTART + 1)	

#define ST_NUMPAINFACES         5
#define ST_NUMSTRAIGHTFACES     3
#define ST_NUMTURNFACES         2
#define ST_NUMSPECIALFACES              3
#define ST_NUMEXTRAFACES                2

#define ST_FACESTRIDE \
          (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)
#define ST_NUMFACES \
          (ST_FACESTRIDE*ST_NUMPAINFACES+ST_NUMEXTRAFACES)



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
extern uint16_t             viewangle_shiftright1;
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

extern int8_t               am_cheating;
extern int8_t 	            am_grid;
extern mpoint_t             m_paninc; 
extern int16_t 	            mtof_zoommul; 
extern int16_t 	            ftom_zoommul; 
extern int16_t 	            screen_botleft_x;
extern int16_t              screen_botleft_y;
extern int16_t 	            screen_topright_x;
extern int16_t              screen_topright_y;
extern int16_t	            screen_viewport_width;
extern int16_t	            screen_viewport_height;
extern int16_t              am_min_level_x;
extern int16_t	            am_min_level_y;
extern int16_t              am_max_level_x;
extern int16_t	            am_max_level_y;
extern uint16_t 	        am_min_scale_mtof;
extern fixed_t_union 	    am_max_scale_mtof;
extern int16_t              old_screen_viewport_width;
extern int16_t              old_screen_viewport_height;
extern int16_t              old_screen_botleft_x;
extern int16_t              old_screen_botleft_y;
extern mpoint_t             screen_oldloc;
extern fixed_t_union        am_scale_mtof;
extern fixed_t_union        am_scale_ftom;
extern mpoint_t             markpoints[AM_NUMMARKPOINTS];
extern int8_t               markpointnum;
extern int8_t               followplayer;
extern uint8_t              cheat_amap_seq[];
extern cheatseq_t           cheat_amap;
extern boolean              am_stopped;
extern boolean              am_bigstate;
extern int8_t               am_buffer[20];
extern boolean              automapactive;
extern fline_t              am_fl;
extern mline_t              am_ml;
extern mline_t              am_l;
extern int8_t               am_lastlevel; 
extern int8_t               am_lastepisode;
extern mline_t              am_lc;
extern mline_t              player_arrow[7];
extern mline_t              cheat_player_arrow[16]; 
extern mline_t              triangle_guy[3];
extern mline_t              thintriangle_guy[3];
extern uint8_t              jump_mult_table_3[8];
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



extern int16_t              currentlumpindex;
extern uint16_t             maskedcount;
extern uint16_t             currentpostoffset;
extern uint16_t             currentpostdataoffset;
extern uint16_t             currentpixeloffset;

extern segment_t            EMS_PAGE;

extern spriteframe_t __far* p_init_sprtemp;
extern int16_t              p_init_maxframe;

#define SC_UPARROW              0x48
#define SC_DOWNARROW            0x50
#define SC_LEFTARROW            0x4b
#define SC_RIGHTARROW           0x4d
#define SC_RCTRL                0x1d
#define SC_RALT                 0x38
#define SC_RSHIFT               0x36
#define SC_SPACE                0x39
#define SC_COMMA                0x33
#define SC_PERIOD               0x34
#define SC_PAGEUP               0x49
#define SC_INSERT               0x52
#define SC_HOME                 0x47
#define SC_PAGEDOWN             0x51
#define SC_DELETE               0x53
#define SC_END                  0x4f
#define SC_ENTER                0x1c

#define SC_KEY_A                0x1e
#define SC_KEY_B                0x30
#define SC_KEY_C                0x2e
#define SC_KEY_D                0x20
#define SC_KEY_E                0x12
#define SC_KEY_F                0x21
#define SC_KEY_G                0x22
#define SC_KEY_H                0x23
#define SC_KEY_I                0x17
#define SC_KEY_J                0x24
#define SC_KEY_K                0x25
#define SC_KEY_L                0x26
#define SC_KEY_M                0x32
#define SC_KEY_N                0x31
#define SC_KEY_O                0x18
#define SC_KEY_P                0x19
#define SC_KEY_Q                0x10
#define SC_KEY_R                0x13
#define SC_KEY_S                0x1f
#define SC_KEY_T                0x14
#define SC_KEY_U                0x16
#define SC_KEY_V                0x2f
#define SC_KEY_W                0x11
#define SC_KEY_X                0x2d
#define SC_KEY_Y                0x15
#define SC_KEY_Z                0x2c
#define SC_BACKSPACE            0x0e




extern boolean grmode;
extern boolean mousepresent;
extern volatile uint32_t ticcount;
// REGS stuff used for int calls
extern union REGS regs;
extern struct SREGS segregs;

extern boolean novideo; // if true, stay in text mode for debugging
#define KBDQUESIZE 32
extern byte keyboardque[KBDQUESIZE];
extern uint8_t kbdtail;
extern uint8_t kbdhead;
extern union REGS in;
extern union REGS out;
extern void (__interrupt __far_func *oldkeyboardisr) (void);
extern byte __far *currentscreen;
extern byte __far *destview;
extern fixed_t_union destscreen;

extern int16_t olddb[2][4];
extern boolean             viewactivestate;
extern boolean             menuactivestate;
extern boolean             inhelpscreensstate;
extern boolean             fullscreen;
extern gamestate_t         oldgamestate;
extern uint8_t                 borderdrawcount;
extern ticcount_t maketic;
extern ticcount_t gametime;

extern uint8_t			numChannels;	
extern uint8_t	usegamma;

#define BACKUPTICS		16
#define NUMKEYS         256 


//default_t	defaults[NUM_DEFAULTS];
 
extern gameaction_t    gameaction; 
extern gamestate_t     gamestate; 
extern skill_t         gameskill; 
extern boolean         respawnmonsters;
extern int8_t             gameepisode; 
extern int8_t             gamemap;
extern boolean         paused; 
extern boolean         sendpause;              // send a pause event next tic 
extern boolean         sendsave;               // send a save event next tic 
extern boolean         usergame;               // ok to save / end game 
extern boolean         timingdemo;             // if true, exit with report on completion 
extern boolean         noblit;                 // for comparative timing purposes 
extern ticcount_t             starttime;              // for comparative timing purposes       
extern boolean         viewactive; 
extern player_t        player;
extern ticcount_t          gametic;
extern int16_t             totalkills; 
extern int16_t             totalitems;
extern int16_t             totalsecret;    // for intermission 
extern int8_t            demoname[32];
extern boolean         demorecording; 
extern boolean         demoplayback; 
extern boolean         netdemo; 
extern uint16_t           demo_p;				// buffer
extern boolean         singledemo;             // quit after playing a demo from cmdline 
extern boolean         precache;        // if true, load all graphics at start 
extern wbstartstruct_t wminfo;                 // parms for world map / intermission 
 
  
 
// 
// controls (have defaults) 
// 
extern uint8_t             key_right;
extern uint8_t             key_left;
extern uint8_t             key_up;
extern uint8_t             key_down;
extern uint8_t             key_strafeleft;
extern uint8_t             key_straferight;
extern uint8_t             key_fire;
extern uint8_t             key_use;
extern uint8_t             key_strafe;
extern uint8_t             key_speed;
extern uint8_t             mousebfire;
extern uint8_t             mousebstrafe;
extern uint8_t             mousebforward;
extern int8_t         forwardmove[2];
extern int8_t         sidemove[2];
extern int16_t         angleturn[3];
extern boolean				gamekeydown[NUMKEYS];
extern int8_t             turnheld;
extern boolean         mousearray[4]; 
extern boolean*        mousebuttons;
extern int16_t             mousex;
extern int16_t             mousey;
extern int32_t             dclicktime;
extern int32_t             dclickstate;
extern int32_t             dclicks;
extern int32_t             dclicktime2;
extern int32_t             dclickstate2;
extern int32_t             dclicks2;
extern int8_t             savegameslot;
extern int8_t            savedescription[32];
extern ticcmd_t localcmds[BACKUPTICS];

extern skill_t d_skill; 
extern int8_t     d_episode;
extern int8_t     d_map;


extern int16_t		myargc;
extern int8_t**		myargv;
extern int16_t	rndindex;
extern int16_t	prndindex;
extern uint8_t		usemouse;
extern default_t	defaults[28];
extern int8_t*	defaultfile;


extern int8_t*   defdemoname; 
extern boolean         secretexit; 

extern boolean          st_firsttime;
extern boolean          updatedthisframe;
extern st_stateenum_t   st_gamestate;
extern boolean          st_statusbaron;
extern uint16_t         tallnum[10];
extern uint16_t         shortnum[10];

extern uint16_t         keys[NUMCARDS];
extern uint16_t         faces[ST_NUMFACES];
extern uint16_t arms[6][2];
extern st_number_t      w_ready;
extern st_percent_t     w_health;
extern st_multicon_t     w_armsbg;
extern st_multicon_t    w_arms[6];
extern st_multicon_t    w_faces; 
extern st_multicon_t    w_keyboxes[3];
extern st_percent_t     w_armor;
extern st_number_t      w_ammo[4];
extern st_number_t      w_maxammo[4]; 
extern int16_t      st_oldhealth;
extern boolean  oldweaponsowned[NUMWEAPONS]; 
extern int16_t      st_facecount;
extern int16_t      st_faceindex;
extern int16_t      keyboxes[3];
extern uint8_t      st_randomnumber;
extern uint8_t   cheat_mus_seq[9];

extern uint8_t   cheat_choppers_seq[11];

extern uint8_t   cheat_god_seq[6];
extern uint8_t   cheat_ammo_seq[6];

extern uint8_t   cheat_ammonokey_seq[5];
extern uint8_t   cheat_noclip_seq[11];
extern uint8_t   cheat_commercial_noclip_seq[7];
extern uint8_t   cheat_powerup_seq[7][10];
extern uint8_t   cheat_clev_seq[10];
// my position cheat
extern uint8_t   cheat_mypos_seq[8];

// Now what?
extern cheatseq_t      cheat_mus;
extern cheatseq_t      cheat_god;
extern cheatseq_t      cheat_ammo;
extern cheatseq_t      cheat_ammonokey;
extern cheatseq_t      cheat_noclip;
extern cheatseq_t      cheat_commercial_noclip;
extern cheatseq_t      cheat_powerup[7];
extern cheatseq_t      cheat_choppers;
extern cheatseq_t      cheat_clev;
extern cheatseq_t      cheat_mypos;
extern boolean do_st_refresh;

extern int8_t st_palette;

extern int16_t  st_calc_lastcalc;
extern int16_t  st_calc_oldhealth;
extern int8_t  st_face_lastattackdown;
extern int8_t  st_face_priority;
extern int8_t     st_stuff_buf[ST_MSGWIDTH];



extern hu_textline_t	w_title;
extern boolean		message_on;
extern boolean			message_dontfuckwithme;
extern boolean		message_nottobefuckedwith;
extern hu_stext_t	w_message;
extern uint8_t		message_counter;
extern int8_t hudneedsupdate;



// offsets within segment stored
extern uint16_t hu_font[HU_FONTSIZE];
extern uint8_t	mapnames[45];

extern uint8_t	mapnames2[32];

#if (EXE_VERSION >= EXE_VERSION_FINAL)
extern uint8_t	mapnamesp[32];
extern uint8_t mapnamest[32];

#endif




extern int16_t		finalestage;

extern int16_t		finalecount;

extern int16_t 	e1text;
extern int16_t	e2text;
extern int16_t	e3text;
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
extern int8_t*	e4text = E4TEXT;
#endif

extern int16_t	c1text;
extern int16_t	c2text;
extern int16_t	c3text;
extern int16_t	c4text;
extern int16_t	c5text;
extern int16_t	c6text;

#if (EXE_VERSION >= EXE_VERSION_FINAL)
extern int16_t	p1text;
extern int16_t	p2text;
extern int16_t	p3text;
extern int16_t	p4text;
extern int16_t	p5text;
extern int16_t	p6text;

extern int16_t	t1text;
extern int16_t	t2text;
extern int16_t	t3text;
extern int16_t	t4text;
extern int16_t	t5text;
extern int16_t	t6text;
#endif

extern int16_t	finaletext;
extern int8_t *	finaleflat;
extern int8_t	finale_laststage;

extern uint8_t  messageToPrint;
extern int8_t   menu_messageString[105];
extern int16_t  messageLastMenuActive;
extern boolean  messageNeedsInput;
extern void     (__near *messageRoutine)(int16_t response);
extern int8_t   gammamsg[5];
extern int16_t  endmsg[NUM_QUITMESSAGES];
extern int16_t  endmsg2[NUM_QUITMESSAGES];
extern int16_t  saveStringEnter;
extern int16_t  saveSlot;       // which slot to save in
extern int16_t  saveCharIndex;  // which char we're editing
extern int8_t   saveOldString[SAVESTRINGSIZE];
extern int16_t  itemOn;                 // menu item skull is on
extern int16_t  skullAnimCounter;       // skull animation counter
extern int16_t  whichSkull;             // which skull to draw
extern int16_t  skullName[2];
extern menu_t   __near* currentMenu;      

extern int16_t     menu_mousewait;
extern int16_t     menu_mousey;
extern int16_t     menu_lasty;
extern int16_t     menu_mousex;
extern int16_t     menu_lastx;
extern int16_t        menu_drawer_x;
extern int16_t        menu_drawer_y;





extern menuitem_t MainMenu[6];
extern menu_t  MainDef;



#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
extern menuitem_t EpisodeMenu[4];
#else
extern menuitem_t EpisodeMenu[3];
#endif

extern menu_t  EpiDef;
//
// NEW GAME
//

extern menuitem_t NewGameMenu[5];
extern menu_t  NewDef;


extern menuitem_t OptionsMenu[8];
extern menu_t  OptionsDef;

//
// Read This! MENU 1 & 2
//

extern menuitem_t ReadMenu1[1];
extern menu_t  ReadDef1;


extern menuitem_t ReadMenu2[1];
extern menu_t  ReadDef2;

//
// SOUND VOLUME MENU
//

extern menuitem_t SoundMenu[4];
extern menu_t  SoundDef;
extern menuitem_t LoadMenu[6];
extern menu_t  LoadDef;
extern menuitem_t SaveMenu[6];
extern menu_t  SaveDef;
extern int8_t     menu_epi;


extern int8_t    detailNames[2];
extern int8_t    msgNames[2];

extern int8_t     quitsounds[8];

extern int8_t     quitsounds2[8];

extern uint16_t  wipeduration;


extern task HeadTask;
extern void( __interrupt __far_func *OldInt8)(void);
extern volatile int32_t TaskServiceRate;;
extern volatile int32_t TaskServiceCount;

extern volatile int32_t TS_TimesInInterrupt;
extern int8_t TS_Installed;
extern volatile int32_t TS_InInterrupt;

extern int8_t NUMANIMS[NUMEPISODES];
extern wianim_t __far*wianims[NUMEPISODES];
extern int16_t		acceleratestage;
extern stateenum_t	state;
extern wbstartstruct_t __near*	wbs;
extern wbplayerstruct_t plrs;  // wbs->plyr[]
extern uint16_t 		cnt;
extern uint16_t 		bcnt;
extern int16_t		cnt_kills;
extern int16_t		cnt_items;
extern int16_t		cnt_secret;
extern int16_t		cnt_time;
extern int16_t		cnt_par;
extern int16_t		cnt_pause;
extern boolean unloaded;
extern uint8_t		yahRef[2];
extern uint8_t		splatRef;
extern uint8_t		numRef[10];
extern boolean		snl_pointeron;
extern int16_t	sp_state;


#define castorderoffset CC_ZOMBIE
//
// Final DOOM 2 animation
// Casting by id Software.
//   in order of appearance
//
typedef struct
{
	uint8_t		nameindex;
    mobjtype_t	type;
} castinfo_t;

#define MAX_CASTNUM 17
extern castinfo_t	castorder[MAX_CASTNUM];

extern int8_t		castnum;
extern int8_t		casttics;
extern state_t __far*	caststate;
extern boolean		castdeath;
extern int8_t		castframes;
extern int8_t		castonmelee;
extern boolean		castattacking;

extern boolean  st_stopped;
extern uint16_t armsbgarray[1];
extern byte*           save_p;


extern THINKERREF	activeceilings[MAXCEILINGS];
extern THINKERREF	activeplats[MAXPLATS];
extern weaponinfo_t	weaponinfo[NUMWEAPONS];
extern fixed_t		bulletslope;
extern uint16_t		switchlist[MAXSWITCHES * 2];
extern int16_t		numswitches;
extern button_t        buttonlist[MAXBUTTONS];
extern int16_t	maxammo[NUMAMMO];
extern int8_t	clipammo[NUMAMMO];
extern boolean		onground;


extern fixed_t_union	leveltime;
extern int16_t currentThinkerListHead;
extern mobj_t __far* setStateReturn;
extern mobj_pos_t __far* setStateReturn_pos;
extern angle_t __far* tantoangle;
