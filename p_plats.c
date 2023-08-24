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
//	Plats (i.e. elevator platforms) code, raising/lowering.
//


#include "i_system.h"
#include "z_zone.h"
#include "m_misc.h"

#include "doomdef.h"
#include "p_local.h"

#include "s_sound.h"

// State.
#include "doomstat.h"
#include "r_state.h"

// Data.
#include "sounds.h"


MEMREF		activeplats[MAXPLATS];



//
// Move a plat up and down
//
void T_PlatRaise(MEMREF platRef)
{

    result_e	res;
	plat_t* plat = (plat_t*)Z_LoadBytesFromEMS(platRef);

    switch(plat->status)
    {
      case up:
	res = T_MovePlane(plat->secnum,
			  plat->speed,
			  plat->high,
			  plat->crush,0,1);
					
	if (plat->type == raiseAndChange
	    || plat->type == raiseToNearestAndChange)
	{
	    if (!(leveltime&7))
			S_StartSoundWithParams(sectors[plat->secnum].soundorgX, sectors[plat->secnum].soundorgY, sfx_stnmov);
	}
	
				
	if (res == crushed && (!plat->crush))
	{
	    plat->count = plat->wait;
	    plat->status = down;
		S_StartSoundWithParams(sectors[plat->secnum].soundorgX, sectors[plat->secnum].soundorgY, sfx_pstart);
	}
	else
	{
	    if (res == pastdest)
	    {
		plat->count = plat->wait;
		plat->status = waiting;
		S_StartSoundWithParams(sectors[plat->secnum].soundorgX, sectors[plat->secnum].soundorgY, sfx_pstop);

		switch(plat->type)
		{
		  case blazeDWUS:
		  case downWaitUpStay:
		    P_RemoveActivePlat(platRef);
		    break;
		    
		  case raiseAndChange:
		  case raiseToNearestAndChange:
		    P_RemoveActivePlat(platRef);
		    break;
		    
		  default:
		    break;
		}
	    }
	}
	break;
	
      case	down:
	res = T_MovePlane(plat->secnum,plat->speed,plat->low,false,0,-1);

	if (res == pastdest)
	{
	    plat->count = plat->wait;
	    plat->status = waiting;
		S_StartSoundWithParams(sectors[plat->secnum].soundorgX, sectors[plat->secnum].soundorgY, sfx_pstop);
	}
	break;
	
      case	waiting:
	if (!--plat->count)
	{
	    if (sectors[plat->secnum].floorheight == plat->low)
		plat->status = up;
	    else
		plat->status = down;
		S_StartSoundWithParams(sectors[plat->secnum].soundorgX, sectors[plat->secnum].soundorgY, sfx_pstart);
	}
      case	in_stasis:
	break;
    }
}


//
// Do Platforms
//  "amount" is only used for SOME platforms.
//
int
EV_DoPlat
( line_t*	line,
  plattype_e	type,
  int		amount )
{
    plat_t*	plat;
    int		secnum;
    int		rtn;
	MEMREF platRef;
	
    secnum = -1;
    rtn = 0;

    
    //	Activate all <type> plats that are in_stasis
    switch(type)
    {
      case perpetualRaise:
	P_ActivateInStasis(line->tag);
	break;
	
      default:
	break;
    }
	
    while ((secnum = P_FindSectorFromLineTag(line,secnum)) >= 0)
    {

	if (sectors[secnum].specialdataRef)
	    continue;
	
	// Find lowest & highest floors around sector
	rtn = 1;

	platRef = Z_MallocEMSNew(sizeof(*plat), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	plat = (plat_t*)Z_LoadBytesFromEMS(platRef);

	
	plat->thinkerRef = P_AddThinker(platRef, TF_PLATRAISE);
	 
		
	plat->type = type;
	plat->secnum = secnum;
	sectors[plat->secnum].specialdataRef = platRef;
	plat->crush = false;
	plat->tag = line->tag;
	
	switch(type)
	{
	  case raiseToNearestAndChange:
	    plat->speed = PLATSPEED/2;
		sectors[secnum].floorpic = sectors[sides[line->sidenum[0]].secnum].floorpic;
	    plat->high = P_FindNextHighestFloor(secnum,sectors[secnum].floorheight);
	    plat->wait = 0;
	    plat->status = up;
	    // NO MORE DAMAGE, IF APPLICABLE
		sectors[secnum].special = 0;

		S_StartSoundWithParams(sectors[secnum].soundorgX, sectors[secnum].soundorgY, sfx_stnmov);
	    break;
	    
	  case raiseAndChange:
	    plat->speed = PLATSPEED/2;
		sectors[secnum].floorpic = sectors[sides[line->sidenum[0]].secnum].floorpic;
	    plat->high = sectors[secnum].floorheight + amount*FRACUNIT;
	    plat->wait = 0;
	    plat->status = up;

		S_StartSoundWithParams(sectors[secnum].soundorgX, sectors[secnum].soundorgY, sfx_stnmov);
	    break;
	    
	  case downWaitUpStay:
	    plat->speed = PLATSPEED * 4;
	    plat->low = P_FindLowestFloorSurrounding(secnum);

	    if (plat->low > sectors[secnum].floorheight)
		plat->low = sectors[secnum].floorheight;

	    plat->high = sectors[secnum].floorheight;
	    plat->wait = 35*PLATWAIT;
	    plat->status = down;
		S_StartSoundWithParams(sectors[secnum].soundorgX, sectors[secnum].soundorgY, sfx_pstart);
	    break;
	    
	  case blazeDWUS:
	    plat->speed = PLATSPEED * 8;
	    plat->low = P_FindLowestFloorSurrounding(secnum);

	    if (plat->low > sectors[secnum].floorheight)
		plat->low = sectors[secnum].floorheight;

	    plat->high = sectors[secnum].floorheight;
	    plat->wait = 35*PLATWAIT;
	    plat->status = down;
		S_StartSoundWithParams(sectors[secnum].soundorgX, sectors[secnum].soundorgY, sfx_pstart);
	    break;
	    
	  case perpetualRaise:
	    plat->speed = PLATSPEED;
	    plat->low = P_FindLowestFloorSurrounding(secnum);

	    if (plat->low > sectors[secnum].floorheight)
		plat->low = sectors[secnum].floorheight;

	    plat->high = P_FindHighestFloorSurrounding(secnum);

	    if (plat->high < sectors[secnum].floorheight)
		plat->high = sectors[secnum].floorheight;

	    plat->wait = 35*PLATWAIT;
	    plat->status = P_Random()&1;

		S_StartSoundWithParams(sectors[secnum].soundorgX, sectors[secnum].soundorgY, sfx_pstart);
	    break;
	}
	P_AddActivePlat(platRef);
    }
    return rtn;
}



void P_ActivateInStasis(int tag) {
    int		j;
	plat_t* plat;
	for (j = 0; j < MAXPLATS; j++)
		if (activeplats[j] != NULL_MEMREF) {
			plat = (plat_t*)Z_LoadBytesFromEMS(activeplats[j]);
			if ((plat->status == in_stasis) && (plat->tag == tag)) {
				plat->oldstatus = plat->status;

				P_UpdateThinkerFunc(plat->thinkerRef, TF_PLATRAISE);
			}
		}

}

void EV_StopPlat(line_t* line) {
	int		j;
	plat_t* plat;

	for (j = 0; j < MAXPLATS; j++) {
		if (activeplats[j] != NULL_MEMREF) {
			plat = (plat_t*)Z_LoadBytesFromEMS(activeplats[j]);
			if ((plat->status != in_stasis) && (plat->tag == line->tag)) {
				plat->oldstatus = plat->status;
				plat->status = in_stasis;

				P_UpdateThinkerFunc(plat->thinkerRef, TF_NULL);
			}
		}
	}
}

static int platraisecount = 0;
static int addedplatraisecount = 0;
static int platindex = 0;

void P_AddActivePlat(MEMREF memref) {
    int		i;
	addedplatraisecount++;
    for (i = 0;i < MAXPLATS;i++)
	if (activeplats[i] == NULL_MEMREF) {
	    activeplats[i] = memref;
		platindex = memref;
	    return;
	}
    I_Error ("P_AddActivePlat: no more plats!");
}



void P_RemoveActivePlat(MEMREF platRef)
{
    int		i;
	plat_t* plat;
	platraisecount++;
	for (i = 0; i < MAXPLATS; i++) {
		if (platRef == activeplats[i]) {
			plat = (plat_t*)Z_LoadBytesFromEMS(activeplats[i]);

			sectors[plat->secnum].specialdataRef = NULL_MEMREF;
			P_RemoveThinker(plat->thinkerRef);
			activeplats[i] = NULL_MEMREF;

			return;
		}
	}
    I_Error ("P_RemoveActivePlat: can't find plat! %i %i %i %i", platRef, platraisecount, addedplatraisecount, platindex);
}
