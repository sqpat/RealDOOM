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
//	Implements special effects:
//	Texture animation, height or lighting changes
//	 according to adjacent sectors, respective
//	 utility functions, etc.
//	Line Tag handling. Line and Sector triggers.
//

#include <stdlib.h>

#include "doomdef.h"
#include "doomstat.h"

#include "i_system.h"
#include "z_zone.h"
#include "m_misc.h"
#include "w_wad.h"

#include "r_local.h"
#include "p_local.h"

#include "g_game.h"

#include "s_sound.h"

// State.
#include "r_state.h"

// Data.
#include "sounds.h"


//
// Animating textures and planes
// There is another anim_t used in wi_stuff, unrelated.
//
typedef struct
{
    boolean	istexture;
    int		picnum;
    int		basepic;
    int		numpics;
    int		speed;
    
} anim_t;

//
//      source animation definition
//
typedef struct
{
    boolean	istexture;	// if false, it is a flat
    char	endname[9];
    char	startname[9];
    int		speed;
} animdef_t;



#define MAXANIMS                32

extern anim_t	anims[MAXANIMS];
extern anim_t*	lastanim;

//
// P_InitPicAnims
//

// Floor/ceiling animation sequences,
//  defined by first and last frame,
//  i.e. the flat (64x64 tile) name to
//  be used.
// The full animation sequence is given
//  using all the flats between the start
//  and end entry, in the order found in
//  the WAD file.
//
animdef_t		animdefs[] =
{
    {false,	"NUKAGE3",	"NUKAGE1",	8},
    {false,	"FWATER4",	"FWATER1",	8},
    {false,	"SWATER4",	"SWATER1", 	8},
    {false,	"LAVA4",	"LAVA1",	8},
    {false,	"BLOOD3",	"BLOOD1",	8},

    // DOOM II flat animations.
    {false,	"RROCK08",	"RROCK05",	8},		
    {false,	"SLIME04",	"SLIME01",	8},
    {false,	"SLIME08",	"SLIME05",	8},
    {false,	"SLIME12",	"SLIME09",	8},

    {true,	"BLODGR4",	"BLODGR1",	8},
    {true,	"SLADRIP3",	"SLADRIP1",	8},

    {true,	"BLODRIP4",	"BLODRIP1",	8},
    {true,	"FIREWALL",	"FIREWALA",	8},
    {true,	"GSTFONT3",	"GSTFONT1",	8},
    {true,	"FIRELAVA",	"FIRELAV3",	8},
    {true,	"FIREMAG3",	"FIREMAG1",	8},
    {true,	"FIREBLU2",	"FIREBLU1",	8},
    {true,	"ROCKRED3",	"ROCKRED1",	8},

    {true,	"BFALL4",	"BFALL1",	8},
    {true,	"SFALL4",	"SFALL1",	8},
    {true,	"WFALL4",	"WFALL1",	8},
    {true,	"DBRAIN4",	"DBRAIN1",	8},
	
    {-1}
};

anim_t		anims[MAXANIMS];
anim_t*		lastanim;


//
//      Animating line specials
//
#define MAXLINEANIMS            64

extern  short	numlinespecials;
extern  short	linespeciallist[MAXLINEANIMS];



void P_InitPicAnims (void)
{
    int		i;

    
    //	Init animation
    lastanim = anims;
    for (i=0 ; animdefs[i].istexture != -1 ; i++)
    {
	if (animdefs[i].istexture)
	{
	    // different episode ?
	    if (R_CheckTextureNumForName(animdefs[i].startname) == -1)
		continue;	

	    lastanim->picnum = R_TextureNumForName (animdefs[i].endname);
	    lastanim->basepic = R_TextureNumForName (animdefs[i].startname);
	}
	else
	{
	    if (W_CheckNumForName(animdefs[i].startname) == -1)
		continue;

	    lastanim->picnum = R_FlatNumForName (animdefs[i].endname);
	    lastanim->basepic = R_FlatNumForName (animdefs[i].startname);
	}

	lastanim->istexture = animdefs[i].istexture;
	lastanim->numpics = lastanim->picnum - lastanim->basepic + 1;

	if (lastanim->numpics < 2)
	    I_Error ("P_InitPicAnims: bad cycle from %s to %s",
		     animdefs[i].startname,
		     animdefs[i].endname);
	
	lastanim->speed = animdefs[i].speed;
	lastanim++;
    }
	
}



//
// UTILITIES
//



//
// getSide()
// Will return a side_t*
//  given the number of the current sector,
//  the line number, and the side (0/1) that you want.
//
short
getSideNum
( short		currentSector,
  short		offset,
  short		side ) {
	short* linebuffer;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	offset = sectors[currentSector].linesoffset + offset;

	linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
	offset = linebuffer[offset];
	return ((line_t*)Z_LoadBytesFromEMS(linesRef))[offset].sidenum[side];
	
}


//
// getSector()
// Will return a sector_t*
//  given the number of the current sector,
//  the line number and the side (0/1) that you want.
//
short
getSector
( short		currentSector,
  short		offset,
  short		side )
{
	line_t* lines;
	short* linebuffer;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	offset = sectors[currentSector].linesoffset + offset;

	linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
	offset = linebuffer[offset];
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
	offset = lines[offset].sidenum[side];

    return ((side_t*)Z_LoadBytesFromEMS(sidesRef))[offset].secnum;
}


//
// twoSided()
// Given the sector number and the line number,
//  it will tell you whether the line is two-sided or not.
//
short
twoSided
( short	sector,
  short	line )
{
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	short* linebuffer;
	line = sectors[sector].linesoffset + line;
	linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
	line = linebuffer[line];
    return (((line_t*)Z_LoadBytesFromEMS(linesRef))[line]).flags & ML_TWOSIDED;
}




//
// getNextSector()
// Return sector_t * of sector next to current.
// SECNUM_NULL if not two-sided line
//
short
getNextSector
( short linenum,
  short	sec )
{
	line_t* lines = (line_t*) Z_LoadBytesFromEMS(linesRef);
	line_t* line = &lines[linenum];

	if (!(line->flags & ML_TWOSIDED))
		return SECNUM_NULL; 
		

    if (line->frontsecnum == sec)
		return line->backsecnum;
	else 
		return line->frontsecnum;
}



//
// P_FindLowestFloorSurrounding()
// FIND LOWEST FLOOR HEIGHT IN SURROUNDING SECTORS
//
fixed_t	P_FindLowestFloorSurrounding(short secnum)
{
    int			i;
    line_t*		check;
	short		otherSecOffset;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	fixed_t		floor = sectors[secnum].floorheight;
	int linecount = sectors[secnum].linecount;
	short* linebuffer;
	short linenumber;

    for (i=0 ;i < linecount ; i++) {
		otherSecOffset = sectors[secnum].linesoffset + i;
		linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
		linenumber = linebuffer[otherSecOffset];

		otherSecOffset = getNextSector(linenumber, secnum);

		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		if (otherSecOffset == SECNUM_NULL) {
			continue;
		}
		if (sectors[otherSecOffset].floorheight < floor) {
			floor = sectors[otherSecOffset].floorheight;
		}
    }
    return floor;
}



//
// P_FindHighestFloorSurrounding()
// FIND HIGHEST FLOOR HEIGHT IN SURROUNDING SECTORS
//
fixed_t	P_FindHighestFloorSurrounding(short secnum)
{
    int			i;
    short		offset;
    fixed_t		floor = -500*FRACUNIT;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	int linecount = sectors[secnum].linecount;
	short* linebuffer;
	
    for (i=0 ;i < linecount ; i++) {
		offset = sectors[secnum].linesoffset + i;
		linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);

		offset = getNextSector(linebuffer[offset], secnum);
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		if (offset == SECNUM_NULL) {
			continue;
		}
		if (sectors[offset].floorheight > floor) {
			floor = sectors[offset].floorheight;
		}
    }
    return floor;
}



//
// P_FindNextHighestFloor
// FIND NEXT HIGHEST FLOOR IN SURROUNDING SECTORS
// Note: this should be doable w/o a fixed array.

// 20 adjoining sectors max!
#define MAX_ADJOINING_SECTORS    	20

fixed_t
P_FindNextHighestFloor
( short	secnum,
  int		currentheight )
{
    int			i;
    int			h;
    int			min;
	short		offset;
	fixed_t		height = currentheight;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	int linecount = sectors[secnum].linecount;
	short* linebuffer;

    
    fixed_t		heightlist[MAX_ADJOINING_SECTORS];		

    for (i=0, h=0 ;i < linecount ; i++) {
		offset = sectors[secnum].linesoffset + i;
		linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
		offset = getNextSector(linebuffer[offset], secnum);
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		if (offset == SECNUM_NULL) {
			continue;
		}
	
		if (sectors[offset].floorheight > height) {
			heightlist[h++] = sectors[offset].floorheight;
		}

    }
    
    // Find lowest height in list
    if (!h)
		return currentheight;
		
    min = heightlist[0];
    
    // Range checking? 
    for (i = 1;i < h;i++)
		if (heightlist[i] < min)
			min = heightlist[i];
			
    return min;
}


//
// FIND LOWEST CEILING IN THE SURROUNDING SECTORS
//
fixed_t
P_FindLowestCeilingSurrounding(short	secnum)
{
    int			i;
	short		offset;
	fixed_t		height = MAXINT;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	int linecount = sectors[secnum].linecount;
	short* linebuffer;

    for (i=0 ;i < linecount ; i++) {
		offset = sectors[secnum].linesoffset + i;
		linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);

		offset = getNextSector(linebuffer[offset], secnum);
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		if (offset == SECNUM_NULL) {
			continue;
		}
		if (sectors[offset].ceilingheight < height) {
			height = sectors[offset].ceilingheight;
		}
	}
    return height;
}


//
// FIND HIGHEST CEILING IN THE SURROUNDING SECTORS
//
fixed_t	P_FindHighestCeilingSurrounding(short	secnum)
{
    int		i;
	short		offset;
	fixed_t	height = 0;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	int linecount = sectors[secnum].linecount;
	short* linebuffer;

    for (i=0 ;i < linecount ; i++) {
		offset = sectors[secnum].linesoffset + i;
		linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);

		offset = getNextSector(linebuffer[offset], secnum);
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		if (offset == SECNUM_NULL) {
			continue;
		}
		if (sectors[offset].ceilingheight > height) {
			height = sectors[offset].ceilingheight;
		}
	}
    return height;
}



//
// RETURN NEXT SECTOR # THAT LINE TAG REFERS TO
//
int
P_FindSectorFromLineTag
( short		linetag,
  int		start )
{
    int	i;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

	for (i = start + 1; i < numsectors; i++) {
		if (sectors[i].tag == linetag) {
			return i;
		}
	}
    return -1;
}




//
// Find minimum light from an adjacent sector
//
int
P_FindMinSurroundingLight
( short secnum,
  int		max )
{
    int		i;
    int		min;
    short	offset;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	int linecount = sectors[secnum].linecount;
	short* linebuffer;

    min = max;
    for (i=0 ; i < linecount ; i++) {
		offset = sectors[secnum].linesoffset + i;
		linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
		 
		offset = getNextSector(linebuffer[offset], secnum);

		
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		if (offset == SECNUM_NULL) {
			continue;
		}

		if (sectors[offset].lightlevel < min) {
			min = sectors[offset].lightlevel;
		}
    }


	return min;

}



//
// EVENTS
// Events are operations triggered by using, crossing,
// or shooting special lines, or by timed thinkers.
//

//
// P_CrossSpecialLine - TRIGGER
// Called every time a thing origin is about
//  to cross a line with a non 0 special.
//
void
P_CrossSpecialLine
( int		linenum,
  int		side,
  MEMREF thingRef )
{
    int		ok;
	line_t* lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
	line_t*	line = &lines[linenum];
	short linetag = line->tag;
	short linefrontsecnum = line->frontsecnum;
	short lineside0 = line->sidenum[0];
	short linespecial = line->special;
	short setlinespecial = -1;
	mobj_t*	thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);

	 
    //	Triggers that other things can activate
    if (!thing->player)
    {
	// Things that should NOT trigger specials...
	switch(thing->type)
	{
	  case MT_ROCKET:
	  case MT_PLASMA:
	  case MT_BFG:
	  case MT_TROOPSHOT:
	  case MT_HEADSHOT:
	  case MT_BRUISERSHOT:
	    return;
	    break;
	    
	  default: break;
	}
		
	ok = 0;
	switch(linespecial)
	{
	  case 39:	// TELEPORT TRIGGER
	  case 97:	// TELEPORT RETRIGGER
	  case 125:	// TELEPORT MONSTERONLY TRIGGER
	  case 126:	// TELEPORT MONSTERONLY RETRIGGER
	  case 4:	// RAISE DOOR
	  case 10:	// PLAT DOWN-WAIT-UP-STAY TRIGGER
	  case 88:	// PLAT DOWN-WAIT-UP-STAY RETRIGGER
	    ok = 1;
	    break;
	}
	if (!ok)
	    return;
    }

    
    // Note: could use some const's here.
    switch (linespecial)
    {
	// TRIGGERS.
	// All from here to RETRIGGERS.
      case 2:
		// Open Door
		EV_DoDoor(linetag,open);
		setlinespecial = 0;
		break;

      case 3:
		// Close Door
		EV_DoDoor(linetag,close);
		setlinespecial = 0;
		break;

      case 4:
		// Raise Door
		EV_DoDoor(linetag,normal);
		setlinespecial = 0;
		break;
	
      case 5:
		// Raise Floor
		EV_DoFloor(linetag, linefrontsecnum,raiseFloor);
		setlinespecial = 0;
		break;
	
      case 6:
		// Fast Ceiling Crush & Raise
		EV_DoCeiling(linetag,fastCrushAndRaise);
		setlinespecial = 0;
		break;
	
      case 8:
		// Build Stairs
		EV_BuildStairs(linetag,build8);
		setlinespecial = 0;
		break;
	
      case 10:
		// PlatDownWaitUp
		EV_DoPlat(linetag, lineside0,downWaitUpStay,0);
		setlinespecial = 0;
		break;
	
      case 12:
		// Light Turn On - brightest near
		EV_LightTurnOn(linetag,0);
		setlinespecial = 0;
		break;
	
      case 13:
		// Light Turn On 255
		EV_LightTurnOn(linetag,255);
		setlinespecial = 0;
		break;
	
      case 16:
		// Close Door 30
		EV_DoDoor(linetag,close30ThenOpen);
		setlinespecial = 0;
		break;
	
      case 17:
		// Start Light Strobing
		EV_StartLightStrobing(linetag);
		setlinespecial = 0;
		break;
	
      case 19:
		// Lower Floor
		EV_DoFloor(linetag, linefrontsecnum,lowerFloor);
		setlinespecial = 0;
		break;
	
      case 22:
		// Raise floor to nearest height and change texture
		EV_DoPlat(linetag, lineside0, raiseToNearestAndChange,0);
		setlinespecial = 0;
		break;
	
      case 25:
		// Ceiling Crush and Raise
		EV_DoCeiling(linetag,crushAndRaise);
		setlinespecial = 0;
		break;
	
      case 30:
		// Raise floor to shortest texture height
		//  on either side of lines.
		EV_DoFloor(linetag, linefrontsecnum, raiseToTexture);
		setlinespecial = 0;
		break;
	
      case 35:
		// Lights Very Dark
		EV_LightTurnOn(linetag,35);
		setlinespecial = 0;
		break;
	
      case 36:
		// Lower Floor (TURBO)
		EV_DoFloor(linetag, linefrontsecnum, turboLower);
		setlinespecial = 0;
		break;
	
      case 37:
		// LowerAndChange
		EV_DoFloor(linetag, linefrontsecnum, lowerAndChange);
		setlinespecial = 0;
		break;
	
      case 38:
		// Lower Floor To Lowest
		EV_DoFloor( linetag, linefrontsecnum, lowerFloorToLowest );
		setlinespecial = 0;
		break;
	
      case 39:
		// TELEPORT!
		EV_Teleport( linetag, side, thingRef );
		setlinespecial = 0;
		break;

      case 40:
		// RaiseCeilingLowerFloor
		EV_DoCeiling(linetag, raiseToHighest );
		EV_DoFloor( linenum, linetag, lowerFloorToLowest );
		setlinespecial = 0;
		break;
	
      case 44:
		// Ceiling Crush
		EV_DoCeiling(linetag, lowerAndCrush );
		setlinespecial = 0;
		break;
	
      case 52:
		// EXIT!
		G_ExitLevel ();
		break;
	
      case 53:
		// Perpetual Platform Raise
		EV_DoPlat(linetag, lineside0, perpetualRaise,0);
		setlinespecial = 0;
		break;
	
      case 54:
		// Platform Stop
		EV_StopPlat(linetag);
		setlinespecial = 0;
		break;

      case 56:
		// Raise Floor Crush
		EV_DoFloor(linetag, linefrontsecnum, raiseFloorCrush);
		setlinespecial = 0;
		break;

      case 57:
		// Ceiling Crush Stop
		EV_CeilingCrushStop(line->tag);
		setlinespecial = 0;
		break;
	
      case 58:
		// Raise Floor 24
		EV_DoFloor(linetag, linefrontsecnum, raiseFloor24);
		setlinespecial = 0;
		break;

      case 59:
		// Raise Floor 24 And Change
		EV_DoFloor(linetag, linefrontsecnum, raiseFloor24AndChange);
		setlinespecial = 0;
		break;
	
      case 104:
		// Turn lights off in sector(tag)
		EV_TurnTagLightsOff(linetag);
		setlinespecial = 0;
		break;
	
      case 108:
		// Blazing Door Raise (faster than TURBO!)
		EV_DoDoor(linetag, blazeRaise);
		setlinespecial = 0;
		break;
	
      case 109:
		// Blazing Door Open (faster than TURBO!)
		EV_DoDoor(linetag, blazeOpen);
		setlinespecial = 0;
		break;
	
      case 100:
		// Build Stairs Turbo 16
		EV_BuildStairs(linetag,turbo16);
		setlinespecial = 0;
		break;
	
      case 110:
		// Blazing Door Close (faster than TURBO!)
		EV_DoDoor(linetag, blazeClose);
		setlinespecial = 0;
		break;

      case 119:
		// Raise floor to nearest surr. floor
		EV_DoFloor(linetag, linefrontsecnum, raiseFloorToNearest);
		setlinespecial = 0;
		break;
	
      case 121:
		// Blazing PlatDownWaitUpStay
		EV_DoPlat(linetag, lineside0, blazeDWUS,0);
		setlinespecial = 0;
		break;
	
      case 124:
		// Secret EXIT
		G_SecretExitLevel ();
		break;
		
      case 125:
		// TELEPORT MonsterONLY
		if (!thing->player) {
			EV_Teleport( linetag, side, thingRef );
			setlinespecial = 0;
		}
		break;
	
      case 130:
		// Raise Floor Turbo
		EV_DoFloor(linetag, linefrontsecnum, raiseFloorTurbo);
		setlinespecial = 0;
		break;
	
      case 141:
		// Silent Ceiling Crush & Raise
		EV_DoCeiling(linetag,silentCrushAndRaise);
		setlinespecial = 0;
		break;
	
	// RETRIGGERS.  All from here till end.
      case 72:
		// Ceiling Crush
		EV_DoCeiling(linetag, lowerAndCrush );
		break;

      case 73:
		// Ceiling Crush and Raise
		EV_DoCeiling(linetag,crushAndRaise);
		break;

      case 74:
		// Ceiling Crush Stop
		EV_CeilingCrushStop(linetag);
		break;
	
      case 75:
		// Close Door
		EV_DoDoor(linetag,close);
		break;
	
      case 76:
		// Close Door 30
		EV_DoDoor(linetag,close30ThenOpen);
		break;
	
      case 77:
		// Fast Ceiling Crush & Raise
		EV_DoCeiling(linetag,fastCrushAndRaise);
		break;
	
      case 79:
		// Lights Very Dark
		EV_LightTurnOn(linetag, 35);
		break;
	
      case 80:
		// Light Turn On - brightest near
		EV_LightTurnOn(linetag, 0);
		break;
	
      case 81:
		// Light Turn On 255
		EV_LightTurnOn(linetag, 255);
		break;
	
      case 82:
		// Lower Floor To Lowest
		EV_DoFloor(linetag, linefrontsecnum, lowerFloorToLowest );
		break;
	
      case 83:
		// Lower Floor
		EV_DoFloor(linetag, linefrontsecnum, lowerFloor);
		break;

      case 84:
		// LowerAndChange
		EV_DoFloor(linetag, linefrontsecnum, lowerAndChange);
		break;

      case 86:
		// Open Door
		EV_DoDoor(linetag,open);
		break;
	
      case 87:
		// Perpetual Platform Raise
		EV_DoPlat(linetag, lineside0, perpetualRaise,0);
		break;
	
      case 88:
		// PlatDownWaitUp
		EV_DoPlat(linetag, lineside0, downWaitUpStay,0);
		break;
	
      case 89:
		// Platform Stop
		EV_StopPlat(linetag);
		break;
	
      case 90:
		// Raise Door
		EV_DoDoor(linetag,normal);
		break;
	
      case 91:
		// Raise Floor
		EV_DoFloor(linetag, linefrontsecnum, raiseFloor);
		break;
	
      case 92:
		// Raise Floor 24
		EV_DoFloor(linetag, linefrontsecnum, raiseFloor24);
		break;
	
      case 93:
		// Raise Floor 24 And Change
		EV_DoFloor(linetag, linefrontsecnum, raiseFloor24AndChange);
		break;
	
      case 94:
		// Raise Floor Crush
		EV_DoFloor(linetag, linefrontsecnum, raiseFloorCrush);
		break;
	
      case 95:
		// Raise floor to nearest height
		// and change texture.
		EV_DoPlat(linetag, lineside0, raiseToNearestAndChange,0);
		break;
	
      case 96:
		// Raise floor to shortest texture height
		// on either side of lines.
		EV_DoFloor(linetag, linefrontsecnum, raiseToTexture);
		break;
	
	  case 97:
		// TELEPORT!
		EV_Teleport( linetag, side, thingRef );
		break;
	
      case 98:
		// Lower Floor (TURBO)
		EV_DoFloor(linetag, linefrontsecnum, turboLower);
		break;

      case 105:
		// Blazing Door Raise (faster than TURBO!)
		EV_DoDoor (linetag,blazeRaise);
		break;
	
      case 106:
		// Blazing Door Open (faster than TURBO!)
		EV_DoDoor(linetag, blazeOpen);
		break;

      case 107:
		// Blazing Door Close (faster than TURBO!)
		EV_DoDoor(linetag, blazeClose);
		break;

      case 120:
		// Blazing PlatDownWaitUpStay.
		EV_DoPlat(linetag, lineside0, blazeDWUS,0);
		break;
	
      case 126:
	// TELEPORT MonsterONLY.
		if (!thing->player)
	    EV_Teleport( linetag, side, thingRef );
		break;
	
      case 128:
		// Raise To Nearest Floor
		EV_DoFloor(linetag, linefrontsecnum, raiseFloorToNearest);
		break;
	
      case 129:
		// Raise Floor Turbo
		EV_DoFloor(linetag, linefrontsecnum, raiseFloorTurbo);
		break;
    }

	if (setlinespecial != -1) {
		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
		lines[linenum].special = setlinespecial;
	}

}



//
// P_ShootSpecialLine - IMPACT SPECIALS
// Called when a thing shoots a special line.
//
void
P_ShootSpecialLine
( MEMREF thingRef,
  short linenum )
{
    int		ok;
	short* linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
	short innerlinenum = linebuffer[linenum];
	line_t* lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
	line_t* line = &lines[innerlinenum];
	short linespecial = line->special;
	short linetag = line->tag;
	short linefrontsecnum = line->frontsecnum;
	short lineside0 = line->sidenum[0];

	
	mobj_t*	thing = (mobj_t*)Z_LoadBytesFromEMS(thingRef);
    
    //	Impacts that other things can activate.
    if (!thing->player) {
		ok = 0;
		switch(linespecial) {
		  case 46:
			// OPEN DOOR IMPACT
			ok = 1;
			break;
		}
		if (!ok) {
			return;
		}
    }

    switch(linespecial) {
      case 24:
		// RAISE FLOOR
		EV_DoFloor(linetag, linefrontsecnum, raiseFloor);
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum,0);
		break;
	
      case 46:
		// OPEN DOOR
		EV_DoDoor(linetag,open);
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
		break;
	
      case 47:
		// RAISE FLOOR NEAR AND CHANGE
		EV_DoPlat(linetag, lineside0, raiseToNearestAndChange,0);
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
		break;
    }

}



//
// P_PlayerInSpecialSector
// Called every tic frame
//  that the player origin is in a special sector
//
void P_PlayerInSpecialSector (player_t* player) {
	mobj_t* playerMo = (mobj_t*)Z_LoadBytesFromEMS(player->moRef);
	fixed_t playerMoz = playerMo->z;
	short secnum = playerMo->secnum;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

    // Falling, not all the way down yet?
	if (playerMoz != sectors[secnum].floorheight) {
		return;
	}

    // Has hitten ground.
    switch (sectors[secnum].special) {
		case 5:
			// HELLSLIME DAMAGE
			if (!player->powers[pw_ironfeet])
				if (!(leveltime&0x1f))
					P_DamageMobj (player->moRef, NULL_MEMREF, NULL_MEMREF, 10);
			break;
	
		case 7:
			// NUKAGE DAMAGE
			if (!player->powers[pw_ironfeet])
				if (!(leveltime&0x1f))
					P_DamageMobj (player->moRef, NULL_MEMREF, NULL_MEMREF, 5);
			break;
	
		case 16:
			// SUPER HELLSLIME DAMAGE
			case 4:
				// STROBE HURT
				if (!player->powers[pw_ironfeet] || (P_Random()<5) ) {
					if (!(leveltime&0x1f))
						P_DamageMobj (player->moRef, NULL_MEMREF, NULL_MEMREF, 20);
				}
				break;
			
		case 9:
			// SECRET SECTOR
			player->secretcount++;
			sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
			sectors[secnum].special = 0;
			break;
			
		case 11:
			// EXIT SUPER DAMAGE! (for E1M8 finale)
			player->cheats &= ~CF_GODMODE;

			if (!(leveltime&0x1f))
				P_DamageMobj (player->moRef, NULL_MEMREF, NULL_MEMREF, 20);

			if (player->health <= 10)
				G_ExitLevel();
			break;
			
		default:
			I_Error ("P_PlayerInSpecialSector: unknown special %i", sectors[secnum].special);
			break;
    };

}




//
// P_UpdateSpecials
// Animate planes, scroll walls, etc.
//
boolean		levelTimer;
int		levelTimeCount;

void P_UpdateSpecials(void)
{
	anim_t*	anim;
	int		pic;
	int		i;
	line_t*	line;
	int * texturetranslation;
	int * flattranslation;
	side_t* sides;
	line_t* lines;
	short sidenum;

	//	LEVEL TIMER
	if (levelTimer == true) {
		levelTimeCount--;
		if (!levelTimeCount) {
			G_ExitLevel();
		}
	}

	//	ANIMATE FLATS AND TEXTURES GLOBALLY
	for (anim = anims; anim < lastanim; anim++) {
		for (i = anim->basepic; i < anim->basepic + anim->numpics; i++) {
			pic = anim->basepic + ((leveltime / anim->speed + i) % anim->numpics);
			if (anim->istexture) {
				texturetranslation = (int*)Z_LoadBytesFromEMS(texturetranslationRef);
				texturetranslation[i] = pic;
			}
			else {
				flattranslation = (int*)Z_LoadBytesFromEMS(flattranslationRef);
				flattranslation[i] = pic;
			}
		}
	}


	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

	//	ANIMATE LINE SPECIALS
	for (i = 0; i < numlinespecials; i++) {
		line = &lines[linespeciallist[i]];
		switch (line->special) {
		  case 48:
			// EFFECT FIRSTCOL SCROLL +
			sidenum = line->sidenum[0];
			sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
			sides[sidenum].textureoffset += FRACUNIT;
			lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
			break;
		}
	}


	//	DO BUTTONS
	for (i = 0; i < MAXBUTTONS; i++){
		if (buttonlist[i].btimer) {
			buttonlist[i].btimer--;
			if (!buttonlist[i].btimer) {
				lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
				sidenum = lines[buttonlist[i].linenum].sidenum[0];
				sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);

				switch (buttonlist[i].where) {
				case top:
					sides[sidenum].toptexture =
						buttonlist[i].btexture;
					break;

				case middle:
					sides[sidenum].midtexture =
						buttonlist[i].btexture;
					break;

				case bottom:
					sides[sidenum].bottomtexture =
						buttonlist[i].btexture;
					break;
				}
				S_StartSoundWithParams(buttonlist[i].soundorgX, buttonlist[i].soundorgY, sfx_swtchn);
				memset(&buttonlist[i], 0, sizeof(button_t));
			}
		}
	}
	
}



//
// Special Stuff that can not be categorized
//
int EV_DoDonut(short linetag)
{
    short		s1Offset;
    short		s2Offset;
    short		s3Offset;
    int			secnum;
    int			rtn;
    int			i;
    floormove_t*	floor;
	MEMREF floorRef;
	short* linebuffer;
	short offset;
	int lineflags;
	short linebacksecnum;
	short lineoffset;
	short sectors1lineoffset;
	line_t* lines;
	sector_t* sectors;
	short sectors3floorpic;
	fixed_t sectors3floorheight;

    secnum = -1;
    rtn = 0;
    while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0) {
		s1Offset = secnum;
		
		// ALREADY MOVING?  IF SO, KEEP GOING...
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		if (sectors[s1Offset].specialdataRef)
			continue;
		sectors1lineoffset = sectors[s1Offset].linesoffset;

		rtn = 1;
		linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
		lineoffset = linebuffer[sectors1lineoffset];
		s2Offset = getNextSector(lineoffset,s1Offset);
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		for (i = 0;i < sectors[s2Offset].linecount;i++) {
			offset = sectors[s2Offset].linesoffset + i;
			linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
			lineoffset = linebuffer[offset];
			lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

			lineflags = (lines[lineoffset]).flags;
			linebacksecnum = (lines[lineoffset]).backsecnum;
			if ((!lineflags & ML_TWOSIDED) || (linebacksecnum == s1Offset));
				continue;
			s3Offset = linebacksecnum;
	    
			//	Spawn rising slime

			floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
			sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
			sectors[s2Offset].specialdataRef = floorRef;
			sectors3floorpic = sectors[s3Offset].floorpic;
			sectors3floorheight = sectors[s3Offset].floorheight;

			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);


			floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);
			floor->type = donutRaise;
			floor->crush = false;
			floor->direction = 1;
			floor->secnum = s2Offset;
			floor->speed = FLOORSPEED / 2;
			floor->texture = sectors3floorpic;
			floor->newspecial = 0;
			floor->floordestheight = sectors3floorheight;
	    
			//	Spawn lowering donut-hole
			floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
			sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
			sectors[s1Offset].specialdataRef = floorRef;
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->thinkerRef = P_AddThinker (floorRef, TF_MOVEFLOOR);
			floor->type = lowerFloor;
			floor->crush = false;
			floor->direction = -1;
			floor->secnum = s1Offset;
			floor->speed = FLOORSPEED / 2;
			floor->floordestheight = sectors3floorheight;
			break;
		}
    }
    return rtn;
}



//
// SPECIAL SPAWNING
//

//
// P_SpawnSpecials
// After the map has been loaded, scan for specials
//  that spawn thinkers
//
short		numlinespecials;
short		linespeciallist[MAXLINEANIMS];


// Parses command line parameters.
void P_SpawnSpecials (void)
{
    int		i;
    int		episode;
	line_t* lines;
	sector_t* sectors;

    episode = 1;
    if (W_CheckNumForName("texture2") >= 0)
		episode = 2;

    
    // See if -TIMER needs to be used.
    levelTimer = false;
	
    //	Init special SECTORs.
    //sector = sectors;

	//I_Error("sector: %p %i", sectors, numsectors);

	for (i=0 ; i<numsectors ; i++) {
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		if (!sectors[i].special)
			continue;
		//I_Error("stopping");

		switch (sectors[i].special)
		{
		  case 1:
			// FLICKERING LIGHTS
			P_SpawnLightFlash (i);
			break;

		  case 2:
			// STROBE FAST
			P_SpawnStrobeFlash(i,FASTDARK,0);
			break;
	    
		  case 3:
			// STROBE SLOW
			P_SpawnStrobeFlash(i,SLOWDARK,0);
			break;
	    
		  case 4:
			// STROBE FAST/DEATH SLIME
			P_SpawnStrobeFlash(i,FASTDARK,0);
			sectors[i].special = 4;
			break;
	    
		  case 8:
			// GLOWING LIGHT
			P_SpawnGlowingLight(i);
			break;
		  case 9:
			// SECRET SECTOR
			totalsecret++;
			break;
	    
		  case 10:
			// DOOR CLOSE IN 30 SECONDS
			P_SpawnDoorCloseIn30 (i);
			break;
	    
		  case 12:
			// SYNC STROBE SLOW
			P_SpawnStrobeFlash (i, SLOWDARK, 1);
			break;

		  case 13:
			// SYNC STROBE FAST
			P_SpawnStrobeFlash (i, FASTDARK, 1);
			break;

		  case 14:
			// DOOR RAISE IN 5 MINUTES
			P_SpawnDoorRaiseIn5Mins (i);
			break;
	    
		  case 17:
			P_SpawnFireFlicker(i);
			break;
		}
    }
	
    
    //	Init line EFFECTs
    numlinespecials = 0;
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

	for (i = 0;i < numlines; i++) {
		switch(lines[i].special) {
		  case 48:
			// EFFECT FIRSTCOL SCROLL+
			linespeciallist[numlinespecials] = i;
			numlinespecials++;
			break;
		}
    }

    
    //	Init other misc stuff
    for (i = 0;i < MAXCEILINGS;i++)
	activeceilings[i] = NULL_MEMREF;

    for (i = 0;i < MAXPLATS;i++)
	activeplats[i] = NULL_MEMREF;
    
    for (i = 0;i < MAXBUTTONS;i++)
	memset(&buttonlist[i],0,sizeof(button_t));

	
}
