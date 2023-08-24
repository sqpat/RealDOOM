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
	
    if (--flick->count)
	return;
	
    amount = (P_Random()&3)*16;
    
    if (sectors[flick->secnum].lightlevel - amount < flick->minlight)
		sectors[flick->secnum].lightlevel = flick->minlight;
    else
		sectors[flick->secnum].lightlevel = flick->maxlight - amount;

    flick->count = 4;
}



//
// P_SpawnFireFlicker
//
void P_SpawnFireFlicker (short secnum)
{
    fireflicker_t*	flick;
	MEMREF flickRef;
    // Note that we are resetting sector attributes.
    // Nothing special about it during gameplay.
    sectors[secnum].special = 0;
	
	flickRef = Z_MallocEMSNew(sizeof(*flick), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	flick = (fireflicker_t*) Z_LoadBytesFromEMS(flickRef);

	flick->thinkerRef = P_AddThinker(flickRef, TF_FIREFLICKER);

    flick->secnum = secnum;
    flick->maxlight = sectors[secnum].lightlevel;
    flick->minlight = P_FindMinSurroundingLight(secnum,sectors[secnum].lightlevel)+16;
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

    if (--flash->count)
		return;
	
    if (sectors[flash->secnum].lightlevel == flash->maxlight) {
		sectors[flash->secnum].lightlevel = flash->minlight;
		flash->count = (P_Random()&flash->mintime)+1;
    }
    else {
		sectors[flash->secnum].lightlevel = flash->maxlight;
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

	// nothing special about it during gameplay
	sectors[secnum].special = 0;
	
	flashRef = Z_MallocEMSNew(sizeof(*flash), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	flash = (lightflash_t*) Z_LoadBytesFromEMS(flashRef);
	flash->thinkerRef = P_AddThinker(flashRef, TF_LIGHTFLASH);

	flash->secnum = secnum;
    flash->maxlight = sectors[secnum].lightlevel;

    flash->minlight = P_FindMinSurroundingLight(secnum, sectors[secnum].lightlevel);

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
	
	if (--flash->count)
	return;
	
    if (sectors[flash->secnum].lightlevel == flash->minlight)
    {
		sectors[flash->secnum].lightlevel = flash->maxlight;
	flash->count = flash->brighttime;
    }
    else
    {
		sectors[flash->secnum].lightlevel = flash->minlight;
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

	// nothing special about it during gameplay
	sectors[secnum].special = 0;

	flashRef = Z_MallocEMSNew(sizeof(*flash), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	flash = (strobe_t*) Z_LoadBytesFromEMS(flashRef);


	flash->thinkerRef = P_AddThinker(flashRef, TF_STROBEFLASH);

    flash->secnum = secnum;
    flash->darktime = fastOrSlow;
    flash->brighttime = STROBEBRIGHT;
    flash->maxlight = sectors[secnum].lightlevel;
	flash->minlight = P_FindMinSurroundingLight(secnum, sectors[secnum].lightlevel);
	

    if (flash->minlight == flash->maxlight)
	flash->minlight = 0;

    // nothing special about it during gameplay
	sectors[secnum].special = 0;

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
	
    secnum = -1;
    while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0)
    {
	if (sectors[secnum].specialdataRef)
	    continue;
	
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
    
    for (secnum = 0; secnum < numsectors; secnum++) {
		if (sectors[secnum].tag == linetag) {
			min = sectors[secnum].lightlevel;
			for (i = 0; i < sectors[secnum].linecount; i++) {
				offset = sectors[secnum].linesoffset + i;
				linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
				templine = &lines[linebuffer[offset]];

				offset = getNextSector(templine, secnum);
				if (offset == SECNUM_NULL){
					continue;
				}
				if (sectors[offset].lightlevel < min) {
					min = sectors[offset].lightlevel;
				}
			}
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
	
    for (secnum=0;secnum<numsectors;secnum++)
    {
	if (sectors[secnum].tag == linetag)
	{
	    // bright = 0 means to search
	    // for highest light level
	    // surrounding sector
	    if (!bright)
	    {
			linecount = sectors[secnum].linecount;
		for (j = 0;j < linecount; j++)
		{
			linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
			tempsecnum = sectors[secnum].linesoffset + j;

			templine = &lines[linebuffer[tempsecnum]];
			tempsecnum = getNextSector(templine,secnum);

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

    switch(g->direction)
    {
      case -1:
	// DOWN
	sectors[g->secnum].lightlevel -= GLOWSPEED;
	if (sectors[g->secnum].lightlevel <= g->minlight)
	{
		sectors[g->secnum].lightlevel += GLOWSPEED;
	    g->direction = 1;
	}
	break;
	
      case 1:
	// UP
		  sectors[g->secnum].lightlevel += GLOWSPEED;
	if (sectors[g->secnum].lightlevel >= g->maxlight)
	{
		sectors[g->secnum].lightlevel -= GLOWSPEED;
	    g->direction = -1;
	}
	break;
    }
}


void P_SpawnGlowingLight(short secnum)
{
    glow_t*	g;

	MEMREF glowRef;
	// Note that we are resetting sector attributes.
	// Nothing special about it during gameplay.
	sectors[secnum].special = 0;

	glowRef = Z_MallocEMSNew(sizeof(*g), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	g = (glow_t*)Z_LoadBytesFromEMS(glowRef);

	g->thinkerRef = P_AddThinker(glowRef, TF_GLOW);


    g->secnum = secnum;
    g->minlight = P_FindMinSurroundingLight(secnum, sectors[secnum].lightlevel);
    g->maxlight = sectors[secnum].lightlevel;
    g->direction = -1;

	sectors[secnum].special = 0;
}

