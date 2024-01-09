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
//   All the global variables that store the internal state.
//   Theoretically speaking, the internal state of the engine
//    should be found by looking at the variables collected
//    here, and every relevant module will have to include
//    this header file.
//   In practice, things are a bit messy.
//


#ifndef __D_STATE__
#define __D_STATE__

// We need globally shared data structures,
//  for defining the global state variables.
#include "doomdata.h"
#include "d_net.h"

// We need the playr data structure as well.
#include "d_player.h"



// ------------------------
// Command line parameters.
//
extern  boolean	nomonsters;	// checkparm of -nomonsters
extern  boolean	respawnparm;	// checkparm of -respawn
extern  boolean	fastparm;	// checkparm of -fast



// Set if homebrew PWAD stuff has been added.
extern  boolean	modifiedgame;

// -------------------------------------------
// Selected skill type, map etc.
//

// Defaults for menu, methinks.
extern  skill_t		startskill;
extern  int8_t             startepisode;
extern	int8_t		startmap;

extern  boolean		autostart;

// Selected by user. 
extern  skill_t         gameskill;
extern  int8_t		gameepisode;
extern  int8_t		gamemap;

extern  boolean         shareware;
extern  boolean         registered;
extern  boolean         commercial;
extern  boolean         plutonia;
extern  boolean         tnt;


// Nightmare mode flag, single player.
extern  boolean         respawnmonsters;


// -------------------------
// Internal parameters for sound rendering.
// These have been taken from the DOS version,
//  but are not (yet) supported with Linux
//  (e.g. no sound volume adjustment with menu.

// These are not used, but should be (menu).
// From m_menu.c:
//  Sound FX volume has default, 0 - 15
//  Music volume has default, 0 - 15
// These are multiplied by 8.
//extern int32_t snd_SfxVolume;      // maximum volume for sound
//extern int32_t snd_MusicVolume;    // maximum volume for music

// Current music/sfx card - index useless
//  w/o a reference LUT in a sound module.
// Ideally, this would use indices found
//  in: /usr/include/linux/soundcard.h
extern uint8_t snd_MusicDevice;
extern uint8_t snd_SfxDevice;
// Config file? Same disclaimer as above.
extern uint8_t snd_DesiredMusicDevice;
extern uint8_t snd_DesiredSfxDevice;


// -------------------------
// Status flags for refresh.
//

// Depending on view size - no status bar?
// Note that there is no way to disable the
//  status bar explicitely.
extern  boolean statusbaractive;

extern  boolean automapactive;	// In AutoMap mode?
extern  boolean	menuactive;	// Menu overlayed?
extern  boolean	paused;		// Game Pause?


extern  boolean		viewactive;

extern  boolean		nodrawers;
extern  boolean		noblit;

extern	int16_t		viewwindowx;
extern	int16_t		viewwindowy;
extern	int16_t		viewheight;
extern	int16_t		viewwidth;
extern	int16_t		scaledviewwidth;


// -------------------------------------
// Scores, rating.
// Statistics on a given map, for intermission.
//
extern  int16_t	totalkills;
extern	int16_t	totalitems;
extern	int16_t	totalsecret;

// Timer, for scores.
extern  fixed_t_union	leveltime;	// tics in game play for par



// --------------------------------------
// DEMO playback/recording related stuff.
// No demo, there is a human player in charge?
// Disable save/end game?
extern  boolean	usergame;

//?
extern  boolean	demoplayback;
extern  boolean	demorecording;

// Quit after playing a demo from cmdline.
extern  boolean		singledemo;	




//?
extern  gamestate_t     gamestate;






//-----------------------------
// Internal parameters, fixed.
// These are set by the engine, and not changed
//  according to user inputs. Partly load from
//  WAD, partly set at startup time.



extern	ticcount_t		gametic;


// Bookkeeping on players - state.
extern	player_t	player;
extern mobj_t*		playerMobj;
extern mobj_pos_t*			playerMobj_pos;
extern	THINKERREF  playerMobjRef;
 

// Intermission stats.
// Parameters for world map / intermission.
extern  wbstartstruct_t		wminfo;	


// LUT of ammunition limits for each kind.
// This doubles with BackPack powerup item.
extern  int16_t		maxammo[NUMAMMO];





//-----------------------------------------
// Internal parameters, used for engine.
//

// File handling stuff.
extern	int8_t*		basedefault;

// if true, load all graphics at level load
extern  boolean         precache;


// wipegamestate can be set to -1
//  to force a wipe on the next draw
extern  gamestate_t     wipegamestate;

extern  uint8_t             mouseSensitivity;
//?
// debug flag to cancel adaptiveness
extern  boolean         singletics;	

extern  int8_t             bodyqueslot;



// Needed to store the number of the dummy sky flat.
// Used for rendering,
//  as well as tracking projectiles etc.
extern uint8_t		skyflatnum;




// This is ???

extern	int16_t		rndindex;

extern	int32_t		maketic;
extern  int32_t             nettics;




#endif
