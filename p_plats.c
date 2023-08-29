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
	int16_t platsecnum = plat->secnum;

	sector_t* sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	int32_t sectorsoundorgX = sectors[platsecnum].soundorgX;
	int32_t sectorsoundorgY = sectors[platsecnum].soundorgY;
	short_height_t sectorfloorheight = sectors[platsecnum].floorheight;

	plat = (plat_t*)Z_LoadBytesFromEMS(platRef);



	switch(plat->status) {
		  case plat_up:
				res = T_MovePlane(plat->secnum,  plat->speed, plat->high, plat->crush,0,1);
				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
				if (plat->type == raiseAndChange || plat->type == raiseToNearestAndChange) {
					if (!(leveltime & 7)) {
						S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_stnmov);
					}
				}
	
				
				if (res == floor_crushed && (!plat->crush)) {
					plat->count = plat->wait;
					plat->status = plat_down;
					S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_pstart);
				} else {
					if (res == floor_pastdest) {
						plat->count = plat->wait;
						plat->status = plat_waiting;
						S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_pstop);

						switch(plat->type) {
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
	
		  case	plat_down:
				res = T_MovePlane(platsecnum,plat->speed,plat->low,false,0,-1);
				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
				if (res == floor_pastdest) {
					plat->count = plat->wait;
					plat->status = plat_waiting;
					S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_pstop);
				}
				break;
	
		  case	plat_waiting:
			  if (!--plat->count) {
					if (sectorfloorheight == plat->low)
						plat->status = plat_up;
					else
						plat->status = plat_down;
					S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_pstart);
			  }
		  case	plat_in_stasis:
			  break;
    }
}


//
// Do Platforms
//  "amount" is only used for SOME platforms.
//
int16_t
EV_DoPlat
(  int16_t linetag,
	int16_t lineside0,
  plattype_e	type,
  int16_t		amount )
{
    plat_t*	plat;
    int16_t		secnum;
    int16_t		rtn;
	MEMREF platRef;
	side_t* sides;
	int16_t side0secnum;
	short_height_t specialheight;
	int32_t sectorsoundorgX;
	int32_t sectorsoundorgY;
	short_height_t sectorfloorheight;
	sector_t* sectors;

    secnum = -1;
    rtn = 0;

    //	Activate all <type> plats that are in_stasis
    switch(type) {
		  case perpetualRaise:
			P_ActivateInStasis(linetag);
			break;
	
		  default:
			break;
	}
	
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
	side0secnum = sides[lineside0].secnum;
	while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0) {
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
 


		if ((&sectors[secnum])->specialdataRef) {
			continue;
		}
		// Find lowest & highest floors around sector
		rtn = 1;


		sectorsoundorgX = sectors[secnum].soundorgX;
		sectorsoundorgY = sectors[secnum].soundorgY;
		sectorfloorheight = sectors[secnum].floorheight;
		platRef = Z_MallocEMSNew(sizeof(*plat), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
		(&sectors[secnum])->specialdataRef = platRef;
		plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
		plat->thinkerRef = P_AddThinker(platRef, TF_PLATRAISE);
	 

		plat->type = type;
		plat->secnum = secnum;
		plat->crush = false;
		plat->tag = linetag;

		 

		switch (type) {
			case raiseToNearestAndChange:
				plat->speed = PLATSPEED / 2;
				sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
				(&sectors[secnum])->floorpic = sectors[side0secnum].floorpic;
				specialheight = P_FindNextHighestFloor(secnum, sectorfloorheight);
				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
				plat->high = specialheight;
				plat->wait = 0;
				plat->status = plat_up;
				// NO MORE DAMAGE, IF APPLICABLE
				sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
				(&sectors[secnum])->special = 0;

				S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_stnmov);
				break;

			case raiseAndChange:
				sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
				(&sectors[secnum])->floorpic = sectors[side0secnum].floorpic;

				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
				plat->speed = PLATSPEED / 2;
				plat->high = sectorfloorheight + amount;
				plat->wait = 0;
				plat->status = plat_up;

				S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_stnmov);
				break;

			case downWaitUpStay:
				plat->speed = PLATSPEED * 4;
				specialheight = P_FindLowestFloorSurrounding(secnum);
				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
				plat->low = specialheight;

				if (plat->low > sectorfloorheight) {
					plat->low = sectorfloorheight;
				}
				plat->high = sectorfloorheight;
				plat->wait = 35 * PLATWAIT;
				plat->status = plat_down;

				S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_pstart);
				break;

			case blazeDWUS:
				plat->speed = PLATSPEED * 8;
				specialheight = P_FindLowestFloorSurrounding(secnum);
				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);

				plat->low = specialheight;

				if (plat->low > sectorfloorheight) {
					plat->low = sectorfloorheight;
				}
				plat->high = sectorfloorheight;
				plat->wait = 35 * PLATWAIT;
				plat->status = plat_down;
				S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_pstart);
				break;

			case perpetualRaise:
				plat->speed = PLATSPEED;
				specialheight = P_FindLowestFloorSurrounding(secnum);
				if (specialheight > sectorfloorheight) {
					specialheight = sectorfloorheight;
				}

				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
				plat->low = specialheight;

				specialheight = P_FindHighestFloorSurrounding(secnum);
				plat = (plat_t*)Z_LoadBytesFromEMS(platRef);
				plat->high = specialheight;

				if (plat->high < sectorfloorheight) {
					plat->high = sectorfloorheight;
				}

				plat->wait = 35*PLATWAIT;
				plat->status = P_Random()&1;

				S_StartSoundWithParams(sectorsoundorgX, sectorsoundorgY, sfx_pstart);
				break;
		}
		P_AddActivePlat(platRef);
    }
    return rtn;
}



void P_ActivateInStasis(int16_t tag) {
    int8_t		j;
	plat_t* plat;
	for (j = 0; j < MAXPLATS; j++)
		if (activeplats[j] != NULL_MEMREF) {
			plat = (plat_t*)Z_LoadBytesFromEMS(activeplats[j]);
			if ((plat->status == plat_in_stasis) && (plat->tag == tag)) {
				plat->oldstatus = plat->status;

				P_UpdateThinkerFunc(plat->thinkerRef, TF_PLATRAISE);
			}
		}

}

void EV_StopPlat(int16_t linetag) {
	int8_t		j;
	plat_t* plat;

	for (j = 0; j < MAXPLATS; j++) {
		if (activeplats[j] != NULL_MEMREF) {
			plat = (plat_t*)Z_LoadBytesFromEMS(activeplats[j]);
			if ((plat->status != plat_in_stasis) && (plat->tag == linetag)) {
				plat->oldstatus = plat->status;
				plat->status = plat_in_stasis;

				P_UpdateThinkerFunc(plat->thinkerRef, TF_NULL);
			}
		}
	}
}

static int16_t platraisecount = 0;
static int16_t addedplatraisecount = 0;
static int16_t platindex = 0;

void P_AddActivePlat(MEMREF memref) {
    int8_t		i;
	addedplatraisecount++;
    for (i = 0;i < MAXPLATS;i++)
	if (activeplats[i] == NULL_MEMREF) {
	    activeplats[i] = memref;
		platindex = memref;
	    return;
	}
}



void P_RemoveActivePlat(MEMREF platRef)
{
    int8_t		i;
	plat_t* plat;
	sector_t* sectors;
	int16_t platsecnum;
	THINKERREF platthinkerRef;
	platraisecount++;
	for (i = 0; i < MAXPLATS; i++) {
		if (platRef == activeplats[i]) {
			plat = (plat_t*)Z_LoadBytesFromEMS(activeplats[i]);
			platsecnum = plat->secnum;
			platthinkerRef = plat->thinkerRef;

			sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
			(&sectors[platsecnum])->specialdataRef = NULL_MEMREF;

			P_RemoveThinker(platthinkerRef);
			activeplats[i] = NULL_MEMREF;

			return;
		}
	}
    
}
