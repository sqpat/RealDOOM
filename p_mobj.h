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
//	Map Objects, MObj, definition and handling.
//


#ifndef __P_MOBJ__
#define __P_MOBJ__

// Basics.
#include "doomdef.h"
#include "tables.h"

// We need the thinker_t stuff.
#include "d_think.h"

// We need the WAD data structure for Map things,
// from the THINGS lump.
#include "doomdata.h"

// States are tied to finite states are
//  tied to animation frames.
// Needs precompiled tables/data structures.
#include "info.h"



//
// NOTES: mobj_t
//
// mobj_ts are used to tell the refresh where to draw an image,
// tell the world simulation when objects are contacted,
// and tell the sound driver how to position a sound.
//
// The refresh uses the next and prev links to follow
// lists of things in sectors as they are being drawn.
// The sprite, frame, and angle elements determine which patch_t
// is used to draw the sprite if it is visible.
// The sprite and frame values are allmost allways set
// from state_t structures.
// The statescr.exe utility generates the states.h and states.c
// files that contain the sprite/frame numbers from the
// statescr.txt source file.
// The xyz origin point represents a point at the bottom middle
// of the sprite (between the feet of a biped).
// This is the default origin position for patch_ts grabbed
// with lumpy.exe.
// A walking creature will have its z equal to the floor
// it is standing on.
//
// The sound code uses the x,y, and subsector fields
// to do stereo positioning of any sound effited by the mobj_t.
//
// The play simulation uses the blocklinks, x,y,z, radius, height
// to determine when mobj_ts are touching each other,
// touching lines in the map, or hit by trace lines (gunshots,
// lines of sight, etc).
// The mobj_t->flags element has various bit flags
// used by the simulation.
//
// Every mobj_t is linked into a single sector
// based on its origin coordinates.
// The subsector_t is found with R_PointInSubsector(x,y),
// and the sector_t can be found with subsector->sector.
// The sector links are only used by the rendering code,
// the play simulation does not care about them at all.
//
// Any mobj_t that needs to be acted upon by something else
// in the play world (block movement, be shot, etc) will also
// need to be linked into the blockmap.
// If the thing has the MF_NOBLOCK flag set, it will not use
// the block links. It can still interact with other things,
// but only as the instigator (missiles will run into other
// things, but nothing can run into a missile).
// Each block in the grid is 128*128 units, and knows about
// every line_t that it contains a piece of, and every
// interactable mobj_t that has its origin contained.  
//
// A valid mobj_t is a mobj_t that has the proper subsector_t
// filled in for its xy coordinates and is linked into the
// sector from which the subsector was made, or has the
// MF_NOSECTOR flag set (the subsector_t needs to be valid
// even if MF_NOSECTOR is set), and is linked into a blockmap
// block or has the MF_NOBLOCKMAP flag set.
// Links should only be modified by the P_[Un]SetThingPosition()
// functions.
// Do not change the MF_NO? flags while a thing is valid.
//
// Any questions?
//

//
// Misc. mobj flags
//
typedef enum {

    // Call P_SpecialThing when touched.
    MF_SPECIAL		= 1,
    // Blocks.
    MF_SOLID		= 2,
    // Can be hit.
    MF_SHOOTABLE	= 4,
    // Don't use the sector links (invisible but touchable).
    MF_NOSECTOR		= 8,
    // Don't use the blocklinks (inert but displayable)
    MF_NOBLOCKMAP	= 16,                    

    // Not to be activated by sound, deaf monster.
    MF_AMBUSH		= 32,
    // Will try to attack right back.
    MF_JUSTHIT		= 64,
    // Will take at least one step before attacking.
    MF_JUSTATTACKED	= 128,
    // On level spawning (initial position),
    //  hang from ceiling instead of stand on floor.
    MF_SPAWNCEILING	= 256,
    // Don't apply gravity (every tic),
    //  that is, object will float, keeping current height
    //  or changing it actively.
    MF_NOGRAVITY	= 512,

    // Movement flags.
    // This allows jumps from high places.
    MF_DROPOFF		= 0x400,
    // For players, will pick up items.
    MF_PICKUP		= 0x800,
    // Player cheat. ???
    MF_NOCLIP		= 0x1000,
    // Player: keep info about sliding along walls.
    MF_SLIDE		= 0x2000,
    // Allow moves to any height, no gravity.
    // For active floaters, e.g. cacodemons, pain elementals.
    MF_FLOAT		= 0x4000,
    // Don't cross lines
    //   ??? or look at heights on teleport.
    MF_TELEPORT		= 0x8000
    // Don't hit same species, explode on block.
    // Player missiles as well as fireballs of various kinds.


} mobjflag_1_t;

typedef enum {


    MF_MISSILE		= 0x1,	
    // Dropped by a demon, not level spawned.
    // E.g. ammo clips dropped by dying former humans.
    MF_DROPPED		= 0x2,
    // Use fuzzy draw (shadow demons or spectres),
    //  temporary player invisibility powerup.
    MF_SHADOW		= 0x4,
    // Flag: don't bleed when shot (use puff),
    //  barrels and shootable furniture shall not bleed.
    MF_NOBLOOD		= 0x8,
    // Don't stop moving halfway off a step,
    //  that is, have dead bodies slide down all the way.
    MF_CORPSE		= 0x10,
    // Floating to a height for a move, ???
    //  don't auto float to target's height.
    MF_INFLOAT		= 0x20,

    // On kill, count this enemy object
    //  towards intermission kill total.
    // Happy gathering.
    MF_COUNTKILL	= 0x40,
    
    // On picking up, count this item object
    //  towards intermission item total.
    MF_COUNTITEM	= 0x80,

    // Special handling: skull in flight.
    // Neither a cacodemon nor a missile.
    MF_SKULLFLY		= 0x100,

    // Don't spawn this object
    //  in death match mode (e.g. key cards).
    MF_NOTDMATCH    	= 0x200,


    // Hmm ???.
    MF_TRANSSHIFT	= 26
} mobjflag_2_t;


// Map Object definition.
// 40 bytes

typedef struct mobj_s {

    // More list: links in sector (if needed)
	THINKERREF	sprevRef;                                                   // 0x00

    //spritenum_t		sprite;	// used to find patch_t and flip value
	//spriteframenum_t frame;	// might be ORed with FF_FULLBRIGHT

    // Interaction info, by BLOCKMAP.
    // Links in blocks (if needed).
	THINKERREF	bnextRef;                                                   // 0x02
    
	// added secnum, because subsecnum is mostly used to look this up, so it seems like a worthwhile cache.
	int16_t secnum;                                                         // 0x04

    // The closest interval over all contacted Sectors.
    short_height_t		floorz;                                             // 0x06
    short_height_t		ceilingz;                                           // 0x08

    // For movement checking.
    fixed_t_union		height;	                                            // 0x0A

    // Momentums, used to update position.
	fixed_t_union		momx;                                               // 0x0E
	fixed_t_union		momy;                                               // 0x12
    fixed_t_union		momz;                                               // 0x16

    mobjtype_t		type;                                                   // 0x1A
    
    uint8_t			tics;	// state tic counter                            // 0x1B
    int16_t			health;                                                 // 0x1C

    // Also for movement checking.
    uint8_t		radius;                                                     // 0x1E

    // Movement direction, movement generation (zig-zagging).
    uint8_t			movedir;	// 0-7  // uses 4 bits                      // 0x1F
    int16_t			movecount;	// when 0, select a new dir                 // 0x20

    // Thing being chased/attacked (or NULL),
    // also the originator for missiles.
    THINKERREF	targetRef;                                                  // 0x22

    // Reaction time: if non 0, don't attack yet.
    // Used by player to freeze a bit after teleporting.
	
	// uses 5 bits, up to 18. 
	uint8_t			reactiontime;                                           // 0x24

    // If >0, the target will be chased
    // no matter what (even if shot)
    uint8_t			threshold;                                              // 0x25

    // For nightmare respawn.
    //mapthing_t		spawnpoint;	

    // Thing being chased/attacked for tracers.
	THINKERREF	tracerRef;                                                  // 0x26
                                                                            // 0x28
    
} mobj_t;

 

// Kind of gross. This is a minimal set of fields needed in render task code
// which allows us to not have to allocate the whole 9000 block to thinkers, 
// and reduces some task switching in the sprite code 

// 24 bytes.
typedef struct mobj_pos_s {

	// List: thinker links.

	// Info for drawing: position.
	fixed_t_union		x;      // 00h
	fixed_t_union		y;      // 04h
	fixed_t_union		z;      // 08h
    
	// todo one day move angle here. to not split the qword
    // More list: links in sector (if needed)
	THINKERREF	snextRef;       // 0Ch

	angle_t		angle;	// orientation  0Eh
	
 	statenum_t		stateNum;   // 12h
	int16_t			flags1;     // 14h
	int16_t			flags2;     // 16h


} mobj_pos_t;



// As M_Random, but used only by the play simulation.
uint8_t __near P_Random(void);


#endif
