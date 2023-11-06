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
    uint8_t	amount;
	fireflicker_t* flick = (fireflicker_t*)Z_LoadThinkerBytesFromEMS(memref);
	int16_t flicksecnum = flick->secnum;
	uint8_t flickmaxlight = flick->maxlight;
	uint8_t flickminlight= flick->minlight;
	sector_t* sectors;

    if (--flick->count)
		return;
	
	flick->count = 4;
	amount = (P_Random()&3)*16;
	sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
    if (sectors[flicksecnum].lightlevel - amount < flickminlight)
		sectors[flicksecnum].lightlevel = flickminlight;
    else
		sectors[flicksecnum].lightlevel = flickmaxlight - amount;

}



//
// P_SpawnFireFlicker
//
void P_SpawnFireFlicker (int16_t secnum)
{
    fireflicker_t*	flick;
	MEMREF flickRef;
	uint8_t lightamount;
    // Note that we are resetting sector attributes.
    // Nothing special about it during gameplay.
	sector_t* sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
	uint8_t seclightlevel = sectors[secnum].lightlevel;
	sectors[secnum].special = 0;

	
	flickRef = Z_MallocThinkerEMS(sizeof(*flick));
	flick = (fireflicker_t*) Z_LoadThinkerBytesFromEMS(flickRef);

	flick->thinkerRef = P_AddThinker(flickRef, TF_FIREFLICKER);

    flick->secnum = secnum;
    flick->maxlight = seclightlevel;
	lightamount = P_FindMinSurroundingLight(secnum,seclightlevel)+16;
	flick = (fireflicker_t*)Z_LoadThinkerBytesFromEMS(flickRef);
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
	lightflash_t* flash = (lightflash_t*)Z_LoadThinkerBytesFromEMS(memref);
	int16_t flashsecnum = flash->secnum;
	uint8_t flashminlight = flash->minlight;
	uint8_t flashmaxlight = flash->maxlight;
	sector_t* sectors;
 

    if (--flash->count)
		return;
	sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

    if (sectors[flashsecnum].lightlevel == flashmaxlight) {
		sectors[flashsecnum].lightlevel = flashminlight;
		flash = (lightflash_t*)Z_LoadThinkerBytesFromEMS(memref);
		flash->count = (P_Random()&flash->mintime)+1;
    }
    else {
		sectors[flashsecnum].lightlevel = flashmaxlight;
		flash = (lightflash_t*)Z_LoadThinkerBytesFromEMS(memref);
		flash->count = (P_Random()&flash->maxtime)+1;
    }
	

}




//
// P_SpawnLightFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
//
void P_SpawnLightFlash (int16_t secnum)
{
    lightflash_t*	flash;
	MEMREF flashRef;
	uint8_t lightamount;
	// nothing special about it during gameplay
	sector_t* sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
	int16_t seclightlevel = sectors[secnum].lightlevel;
	sectors[secnum].special = 0;

	
	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
	flashRef = Z_MallocThinkerEMS(sizeof(*flash));
	flash = (lightflash_t*) Z_LoadThinkerBytesFromEMS(flashRef);
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
	strobe_t* flash = (strobe_t*)Z_LoadThinkerBytesFromEMS(memref);
	int16_t flashsecnum = flash->secnum;
	int16_t flashminlight = flash->minlight;
	int16_t flashmaxlight = flash->maxlight;
	sector_t* sectors;

	if (--flash->count)
		return;

	sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

	
    if (sectors[flashsecnum].lightlevel == flashminlight) {
		sectors[flashsecnum].lightlevel = flashmaxlight;
		flash = (strobe_t*)Z_LoadThinkerBytesFromEMS(memref);
		flash->count = flash->brighttime;
    } else {
		sectors[flashsecnum].lightlevel = flashminlight;
		flash = (strobe_t*)Z_LoadThinkerBytesFromEMS(memref);
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
( int16_t secnum,
  int16_t		fastOrSlow,
  int16_t		inSync )
{
    strobe_t*	flash;
	MEMREF flashRef;
	uint8_t lightamount;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
	int16_t seclightlevel = sectors[secnum].lightlevel;

	// nothing special about it during gameplay
	sectors[secnum].special = 0;

	flashRef = Z_MallocThinkerEMS(sizeof(*flash));
	flash = (strobe_t*) Z_LoadThinkerBytesFromEMS(flashRef);


	flash->thinkerRef = P_AddThinker(flashRef, TF_STROBEFLASH);

    flash->secnum = secnum;
    flash->darktime = fastOrSlow;
    flash->brighttime = STROBEBRIGHT;
    flash->maxlight = seclightlevel;

	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
	flash = (strobe_t*)Z_LoadThinkerBytesFromEMS(flashRef);
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
void EV_StartLightStrobing(uint8_t linetag)
{
    int16_t		secnum;
	int16_t secnumlist[MAX_ADJOINING_SECTORS];
	int16_t		j = 0;

    secnum = -1;
	P_FindSectorsFromLineTag(linetag, secnumlist, false);
	while (secnumlist[j] >= 0) {
 		secnum = secnumlist[j];
		j++;

		P_SpawnStrobeFlash (secnum,SLOWDARK, 0);
    }
}



//
// TURN LINE'S TAG LIGHTS OFF
//
void EV_TurnTagLightsOff(uint8_t linetag)
{
	int16_t			i;
	int16_t			j = 0;
    int16_t			secnum;
    uint8_t			min;
	int16_t *		linebuffer;
	sector_t*   sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
	uint8_t linecount;
	int16_t offset;
	int16_t linebufferlines[MAX_ADJOINING_SECTORS];
	int16_t tagsecnumlist[MAX_ADJOINING_SECTORS];
	int16_t secnumlist[MAX_ADJOINING_SECTORS];


	
	P_FindSectorsFromLineTag(linetag, tagsecnumlist, true);


	sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

	while (tagsecnumlist[j] >= 0) {
		secnum = tagsecnumlist[j];
		j++;
		linecount = sectors[secnum].linecount;
		offset = sectors[secnum].linesoffset;
		
		min = sectors[secnum].lightlevel;

		linebuffer = (int16_t*)Z_LoadBytesFromConventional(linebufferRef);
		memcpy(linebufferlines, &linebuffer[offset], 2 * linecount);
		linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);

		sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

		for (i = 0; i < linecount; i++) {
 			 offset = secnumlist[i];

			if (sectors[offset].lightlevel < min) {
				min = sectors[offset].lightlevel;
			}
		}
		sectors[secnum].lightlevel = min;
	}
}


//
// TURN LINE'S TAG LIGHTS ON
//
void
EV_LightTurnOn
(uint8_t linetag,
  uint8_t		bright )
{
    int16_t secnum;
	uint8_t		j = 0;
	uint8_t		i;
	uint8_t linecount;
	int16_t* linebuffer;
	sector_t*   sectors;
	int16_t offset;
	int16_t linebufferlines[MAX_ADJOINING_SECTORS];
	int16_t tagsecnumlist[MAX_ADJOINING_SECTORS];
	int16_t secnumlist[MAX_ADJOINING_SECTORS];

	P_FindSectorsFromLineTag(linetag, tagsecnumlist, true);
	sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

	while (tagsecnumlist[j] >= 0) {
		secnum = tagsecnumlist[j];
		j++;

		if (!bright) {
			linecount = sectors[secnum].linecount;
			offset = sectors[secnum].linesoffset;
			linebuffer = (int16_t*)Z_LoadBytesFromConventional(linebufferRef);
			memcpy(linebufferlines, &linebuffer[offset], 2 * linecount);
			linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);

			sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

			for (i = 0; i < linecount; i++) {
				offset = secnumlist[i];

				if (sectors[offset].lightlevel > bright)
					bright = sectors[offset].lightlevel;
			}

		}
		sectors[secnum].lightlevel = bright;

	}
}

    
//
// Spawn glowing light
//

void T_Glow(MEMREF memref)
{
	glow_t* g = (glow_t*)Z_LoadThinkerBytesFromEMS(memref);
	int16_t gsecnum = g->secnum;
	uint8_t gminlight = g->minlight;
	uint8_t gmaxlight = g->maxlight;
	sector_t* sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

    switch(g->direction) {
      case -1:
		// DOWN
		sectors[gsecnum].lightlevel -= GLOWSPEED;
		if (sectors[gsecnum].lightlevel <= gminlight) {
			sectors[gsecnum].lightlevel += GLOWSPEED;
			g = (glow_t*)Z_LoadThinkerBytesFromEMS(memref);
			g->direction = 1;
		}
		break;
	
      case 1:
		// UP
		sectors[gsecnum].lightlevel += GLOWSPEED;
		if (sectors[gsecnum].lightlevel >= gmaxlight) {
			sectors[gsecnum].lightlevel -= GLOWSPEED;
			g = (glow_t*)Z_LoadThinkerBytesFromEMS(memref);
			g->direction = -1;
		}
		break;
	}
}


void P_SpawnGlowingLight(int16_t secnum)
{
    glow_t*	g;
	uint8_t lightamount;
	MEMREF glowRef;
	// Note that we are resetting sector attributes.
	// Nothing special about it during gameplay.
	
	sector_t* sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
	int16_t seclightlevel = sectors[secnum].lightlevel;
	sectors[secnum].special = 0;


	glowRef = Z_MallocThinkerEMS(sizeof(*g));
	g = (glow_t*)Z_LoadThinkerBytesFromEMS(glowRef);

	g->thinkerRef = P_AddThinker(glowRef, TF_GLOW);


    g->secnum = secnum;

	
	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
	g = (glow_t*)Z_LoadThinkerBytesFromEMS(glowRef);
	g->minlight = lightamount;
	g->minlight = 
    g->maxlight = seclightlevel;
    g->direction = -1;

}

