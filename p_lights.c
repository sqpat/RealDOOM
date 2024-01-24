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
void T_FireFlicker (fireflicker_t __far* flick, THINKERREF flickRef)

{
    uint8_t	amount;
	int16_t flicksecnum = flick->secnum;
	uint8_t flickmaxlight = flick->maxlight;
	uint8_t flickminlight= flick->minlight;

    if (--flick->count)
		return;
	
	flick->count = 4;
	amount = (P_Random()&3)*16;
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
    fireflicker_t __far*	flick;
	uint8_t lightamount;
    // Note that we are resetting sector attributes.
    // Nothing special about it during gameplay.
	uint8_t seclightlevel = sectors[secnum].lightlevel;
	sectors_physics[secnum].special = 0;

	
	flick = (fireflicker_t __far*)P_CreateThinker(TF_FIREFLICKER_HIGHBITS);

    flick->secnum = secnum;
    flick->maxlight = seclightlevel;
	lightamount = P_FindMinSurroundingLight(secnum,seclightlevel)+16;
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
void T_LightFlash (lightflash_t __far* flash, THINKERREF flashRef)
{
	int16_t flashsecnum = flash->secnum;
	uint8_t flashminlight = flash->minlight;
	uint8_t flashmaxlight = flash->maxlight;
 

    if (--flash->count)
		return;

    if (sectors[flashsecnum].lightlevel == flashmaxlight) {
		sectors[flashsecnum].lightlevel = flashminlight;
		flash->count = (P_Random()&flash->mintime)+1;
    }
    else {
		sectors[flashsecnum].lightlevel = flashmaxlight;
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
    lightflash_t __far*	flash;
	uint8_t lightamount;
	// nothing special about it during gameplay
	int16_t seclightlevel = sectors[secnum].lightlevel;
	sectors_physics[secnum].special = 0;

	
	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);

	flash = (lightflash_t __far*)P_CreateThinker(TF_LIGHTFLASH_HIGHBITS);


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
void T_StrobeFlash (strobe_t __far* flash, THINKERREF flashRef)
{
	int16_t flashsecnum = flash->secnum;
	int16_t flashminlight = flash->minlight;
	int16_t flashmaxlight = flash->maxlight;

	if (--flash->count)
		return;


	
    if (sectors[flashsecnum].lightlevel == flashminlight) {
		sectors[flashsecnum].lightlevel = flashmaxlight;
		flash->count = flash->brighttime;
    } else {
		sectors[flashsecnum].lightlevel = flashminlight;
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
    strobe_t __far*	flash;
	uint8_t lightamount;
	int16_t seclightlevel = sectors[secnum].lightlevel;

	// nothing special about it during gameplay
	sectors_physics[secnum].special = 0;



	flash = (strobe_t __far*)P_CreateThinker(TF_STROBEFLASH_HIGHBITS);

    flash->secnum = secnum;
    flash->darktime = fastOrSlow;
    flash->brighttime = STROBEBRIGHT;
    flash->maxlight = seclightlevel;

	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
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
	uint8_t linecount;
	int16_t offset;
	int16_t linebufferlines[MAX_ADJOINING_SECTORS];
	int16_t tagsecnumlist[MAX_ADJOINING_SECTORS];
	int16_t secnumlist[MAX_ADJOINING_SECTORS];


	
	P_FindSectorsFromLineTag(linetag, tagsecnumlist, true);



	while (tagsecnumlist[j] >= 0) {
		secnum = tagsecnumlist[j];
		j++;
		linecount = sectors[secnum].linecount;
		offset = sectors[secnum].linesoffset;
		
		min = sectors[secnum].lightlevel;

		FAR_memcpy(linebufferlines, &linebuffer[offset], 2 * linecount);
		linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);


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
	int16_t offset;
	int16_t linebufferlines[MAX_ADJOINING_SECTORS];
	int16_t tagsecnumlist[MAX_ADJOINING_SECTORS];
	int16_t secnumlist[MAX_ADJOINING_SECTORS];

	P_FindSectorsFromLineTag(linetag, tagsecnumlist, true);

	while (tagsecnumlist[j] >= 0) {
		secnum = tagsecnumlist[j];
		j++;

		if (!bright) {
			linecount = sectors[secnum].linecount;
			offset = sectors[secnum].linesoffset;
			FAR_memcpy(linebufferlines, &linebuffer[offset], 2 * linecount);
			linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);


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

void T_Glow(glow_t __far* glow, THINKERREF glowRef)
{
	int16_t gsecnum = glow->secnum;
	uint8_t gminlight = glow->minlight;
	uint8_t gmaxlight = glow->maxlight;

    switch(glow->direction) {
      case -1:
		// DOWN
		sectors[gsecnum].lightlevel -= GLOWSPEED;
		if (sectors[gsecnum].lightlevel <= gminlight) {
			sectors[gsecnum].lightlevel += GLOWSPEED;
			glow->direction = 1;
		}
		break;
	
      case 1:
		// UP
		sectors[gsecnum].lightlevel += GLOWSPEED;
		if (sectors[gsecnum].lightlevel >= gmaxlight) {
			sectors[gsecnum].lightlevel -= GLOWSPEED;
			glow->direction = -1;
		}
		break;
	}
}


void P_SpawnGlowingLight(int16_t secnum)
{
    glow_t __far*	g;
	uint8_t lightamount;
	// Note that we are resetting sector attributes.
	// Nothing special about it during gameplay.
	
	int16_t seclightlevel = sectors[secnum].lightlevel;
	sectors_physics[secnum].special = 0;



	g = (glow_t __far*)P_CreateThinker(TF_GLOW_HIGHBITS);


    g->secnum = secnum;

	
	lightamount = P_FindMinSurroundingLight(secnum, seclightlevel);
	g->minlight = lightamount;
	g->minlight = 
    g->maxlight = seclightlevel;
    g->direction = -1;

}

