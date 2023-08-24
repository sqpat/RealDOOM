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
//	Handle Sector base lighting effects.
//	Muzzle flash?
//


#include "z_zone.h"
#include "m_misc.h"

#include "doomdef.h"
#include "p_local.h"
#include "doomstat.h"
#include "i_system.h"


// State.
#include "r_state.h"

//
// FIRELIGHT FLICKER
//

//
// T_FireFlicker
//
void T_FireFlicker (MEMREF memref)

{
    int	amount;
	fireflicker_t* flick = (fireflicker_t*)Z_LoadBytesFromEMS(memref);
	short flicksecnum = flick->secnum;
	int flickmaxlight = flick->maxlight;
	int flickminlight= flick->minlight;
	sector_t* sectors;

    if (--flick->count)
		return;
	
	flick->count = 4;
	amount = (P_Random()&3)*16;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
    if (sectors[flicksecnum].lightlevel - amount < flickminlight)
		sectors[flicksecnum].lightlevel = flickminlight;
    else
		sectors[flicksecnum].lightlevel = flickmaxlight - amount;

}



//
// P_SpawnFireFlicker
//
void P_SpawnFireFlicker (short secnum)
{
    fireflicker_t*	flick;
	MEMREF flickRef;
	int lightamount;
    // Note that we are resetting sector attributes.
    // Nothing special about it during gameplay.
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	short seclightlevel = sectors[secnum].lightlevel;
	sectors[secnum].special = 0;

	
	flickRef = Z_MallocEMSNew(sizeof(*flick), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	flick = (fireflicker_t*) Z_LoadBytesFromEMS(flickRef);

	flick->thinkerRef = P_AddThinker(flickRef, TF_FIREFLICKER);

    flick->secnum = secnum;
    flick->maxlight = seclightlevel;
	lightamount = P_FindMinSurroundingLight(secnum,seclightlevel)+16;
	flick = (fireflicker_t*)Z_LoadBytesFromEMS(flickRef);
	flick->minlight = lightamount;
    flick->count = 4;
}



//
// BROKEN LIGHT FLASHING
//


//
// T_LightFlash
// Do flashing lights.
//
void T_LightFlash (MEMREF memref)
{
	lightflash_t* flash = (lightflash_t*)Z_LoadBytesFromEMS(memref);
	short flashsecnum = flash->secnum;
	int flashminlight = flash->minlight;
	int flashmaxlight = flash->maxlight;
	sector_t* sectors;
 

    if (--flash->count)
		return;
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

    if (sectors[flashsecnum].lightlevel == flashmaxlight) {
		sectors[flashsecnum].lightlevel = flashminlight;
		flash = (lightflash_t*)Z_LoadBytesFromEMS(memref);
		flash->count = (P_Random()&flash->mintime)+1;
    }
    else {
		sectors[flashsecnum].lightlevel = flashmaxlight;
		flash = (lightflash_t*)Z_LoadBytesFromEMS(memref);
		flash->count = (P_Random()&flash->maxtime)+1;
    }
	

}




//
// P_SpawnLightFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
//
void P_SpawnLightFlash (short secnum)
{
    lightflash_t*	flash;
	MEMREF flashRef;
	int lightamount;
	// nothing special about it during gameplay
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	short seclightlevel = sectors[secnum].lightlevel;
	sectors[secnum].special = 0;

	
	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
	flashRef = Z_MallocEMSNew(sizeof(*flash), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	flash = (lightflash_t*) Z_LoadBytesFromEMS(flashRef);
	flash->thinkerRef = P_AddThinker(flashRef, TF_LIGHTFLASH);

	flash->secnum = secnum;
    flash->maxlight = seclightlevel;
	flash->minlight = lightamount;
	flash->maxtime = 64;
    flash->mintime = 7;
    flash->count = (P_Random()&flash->maxtime)+1;


}



//
// STROBE LIGHT FLASHING
//


//
// T_StrobeFlash
//
void T_StrobeFlash (MEMREF memref)
{
	strobe_t* flash = (strobe_t*)Z_LoadBytesFromEMS(memref);
	short flashsecnum = flash->secnum;
	short flashminlight = flash->minlight;
	short flashmaxlight = flash->maxlight;
	sector_t* sectors;
	short seclightlevel;

	if (--flash->count)
		return;

	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

	
    if (sectors[flashsecnum].lightlevel == flashminlight) {
		sectors[flashsecnum].lightlevel = flashmaxlight;
		flash = (strobe_t*)Z_LoadBytesFromEMS(memref);
		flash->count = flash->brighttime;
    } else {
		sectors[flashsecnum].lightlevel = flashminlight;
		flash = (strobe_t*)Z_LoadBytesFromEMS(memref);
		flash->count =flash->darktime;
    }

}



//
// P_SpawnStrobeFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
//
void
P_SpawnStrobeFlash
( short secnum,
  int		fastOrSlow,
  int		inSync )
{
    strobe_t*	flash;
	MEMREF flashRef;
	int lightamount;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	short seclightlevel = sectors[secnum].lightlevel;

	// nothing special about it during gameplay
	sectors[secnum].special = 0;

	flashRef = Z_MallocEMSNew(sizeof(*flash), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	flash = (strobe_t*) Z_LoadBytesFromEMS(flashRef);


	flash->thinkerRef = P_AddThinker(flashRef, TF_STROBEFLASH);

    flash->secnum = secnum;
    flash->darktime = fastOrSlow;
    flash->brighttime = STROBEBRIGHT;
    flash->maxlight = seclightlevel;

	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
	flash = (strobe_t*)Z_LoadBytesFromEMS(flashRef);
	flash->minlight = lightamount;

	

    if (flash->minlight == flash->maxlight)
		flash->minlight = 0;

 

    if (!inSync)
		flash->count = (P_Random()&7)+1;
    else
		flash->count = 1;
}


//
// Start strobing lights (usually from a trigger)
//
void EV_StartLightStrobing(short linetag)
{
    int		secnum;
	sector_t* sectors;

    secnum = -1;
    while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0) {
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		if (sectors[secnum].specialdataRef) {
			continue;
		}
		P_SpawnStrobeFlash (secnum,SLOWDARK, 0);
    }
}



//
// TURN LINE'S TAG LIGHTS OFF
//
void EV_TurnTagLightsOff(short linetag)
{
    int			i;
    int			secnum;
    int			min;
    short		offset;
    line_t*		templine;
	short *		linebuffer;
	short		linenumber;
	sector_t*   sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

    for (secnum = 0; secnum < numsectors; secnum++) {
		if (sectors[secnum].tag == linetag) {
			min = sectors[secnum].lightlevel;
			for (i = 0; i < sectors[secnum].linecount; i++) {
				offset = sectors[secnum].linesoffset + i;
				linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
				linenumber = linebuffer[offset];

				offset = getNextSector(linenumber, secnum);
				sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
				if (offset == SECNUM_NULL){
					continue;
				}
				if (sectors[offset].lightlevel < min) {
					min = sectors[offset].lightlevel;
				}
			}
			sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
			sectors[secnum].lightlevel = min;
		}
    }
}


//
// TURN LINE'S TAG LIGHTS ON
//
void
EV_LightTurnOn
( short linetag,
  int		bright )
{
    short secnum;
    int		j;
    short	tempsecnum;
    line_t*	templine;
	int linecount;
	short* linebuffer;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

    for (secnum=0;secnum<numsectors;secnum++) {
		if (sectors[secnum].tag == linetag){
			// bright = 0 means to search
			// for highest light level
			// surrounding sector
			if (!bright) {
				linecount = sectors[secnum].linecount;
				for (j = 0;j < linecount; j++) {
					tempsecnum = sectors[secnum].linesoffset + j;
					linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);

					tempsecnum = getNextSector(linebuffer[tempsecnum],secnum);
					sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

					if (tempsecnum == SECNUM_NULL)
						continue;

					if (sectors[tempsecnum].lightlevel > bright)
						bright = sectors[tempsecnum].lightlevel;
				}
			}
			sectors[secnum].lightlevel = bright;
		}
    }
}

    
//
// Spawn glowing light
//

void T_Glow(MEMREF memref)
{
	glow_t* g = (glow_t*)Z_LoadBytesFromEMS(memref);
	short gsecnum = g->secnum;
	int gminlight = g->minlight;
	int gmaxlight = g->maxlight;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

    switch(g->direction) {
      case -1:
		// DOWN
		sectors[gsecnum].lightlevel -= GLOWSPEED;
		if (sectors[gsecnum].lightlevel <= gminlight) {
			sectors[gsecnum].lightlevel += GLOWSPEED;
			g = (glow_t*)Z_LoadBytesFromEMS(memref);
			g->direction = 1;
		}
		break;
	
      case 1:
		// UP
		sectors[gsecnum].lightlevel += GLOWSPEED;
		if (sectors[gsecnum].lightlevel >= gmaxlight) {
			sectors[gsecnum].lightlevel -= GLOWSPEED;
			g = (glow_t*)Z_LoadBytesFromEMS(memref);
			g->direction = -1;
		}
		break;
	}
}


void P_SpawnGlowingLight(short secnum)
{
    glow_t*	g;
	int lightamount;
	MEMREF glowRef;
	// Note that we are resetting sector attributes.
	// Nothing special about it during gameplay.
	
	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	short seclightlevel = sectors[secnum].lightlevel;
	sectors[secnum].special = 0;


	glowRef = Z_MallocEMSNew(sizeof(*g), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	g = (glow_t*)Z_LoadBytesFromEMS(glowRef);

	g->thinkerRef = P_AddThinker(glowRef, TF_GLOW);


    g->secnum = secnum;

	
	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
	g = (glow_t*)Z_LoadBytesFromEMS(glowRef);
	g->minlight = lightamount;
	g->minlight = 
    g->maxlight = seclightlevel;
    g->direction = -1;

}

