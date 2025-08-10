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
#include "m_memory.h"
#include "m_near.h"

#include <i86.h>




//
// Move a plat up and down
//
void __near T_PlatRaise(plat_t __near* plat, THINKERREF platRef) {

    result_e	res;
	int16_t platsecnum = plat->secnum;
	sector_t __far* platsector = &sectors[platsecnum];

	short_height_t sectorfloorheight = platsector->floorheight;




	switch(plat->status) {
		  case plat_up:
				res = T_MovePlaneFloorUp(FP_OFF(platsector),  plat->speed, plat->high, plat->crush);
				if (plat->type == raiseAndChange || plat->type == raiseToNearestAndChange) {
					if (!(leveltime.w & 7)) {
						S_StartSoundWithSecnum(platsecnum, sfx_stnmov);
					}
				}
	
				
				if (res == floor_crushed && (!plat->crush)) {
					plat->count = plat->wait;
					plat->status = plat_down;
					S_StartSoundWithSecnum(platsecnum, sfx_pstart);
				} else {
					if (res == floor_pastdest) {
						plat->count = plat->wait;
						plat->status = plat_waiting;
						S_StartSoundWithSecnum(platsecnum, sfx_pstop);

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
				res = T_MovePlaneFloorDown(FP_OFF(platsector),plat->speed,plat->low,false);
				if (res == floor_pastdest) {
					plat->count = plat->wait;
					plat->status = plat_waiting;
					S_StartSoundWithSecnum(platsecnum, sfx_pstop);
				}
				break;
	
		  case	plat_waiting:
			  if (!--plat->count) {
					if (sectorfloorheight == plat->low)
						plat->status = plat_up;
					else
						plat->status = plat_down;
					S_StartSoundWithSecnum(platsecnum, sfx_pstart);
			  }
		  case	plat_in_stasis:
			  break;
    }
}


//
// Do Platforms
//  "amount" is only used for SOME platforms.
//
int16_t __near EV_DoPlat (  uint8_t linetag, int16_t linefrontsecnum,plattype_e	type,int16_t		amount ){
    plat_t __near*	plat;
    int16_t		secnum;
    int16_t		rtn;
	int16_t		j = 0;
	THINKERREF platRef;
 	short_height_t specialheight;
	short_height_t sectorfloorheight;
	int16_t secnumlist[MAX_ADJOINING_SECTORS];

    secnum = -1;
    rtn = 0;

    //	Activate all <type> plats that are in_stasis
    switch(type) {
		  case perpetualRaise:
			EV_PlatFunc(linetag, PLAT_FUNC_IN_STASIS);
			break;
	
		  default:
			break;
	}
	
 	P_FindSectorsFromLineTag(linetag, secnumlist, false);
	while (secnumlist[j] >= 0) {
		secnum = secnumlist[j];
		j++;

		// Find lowest & highest floors around sector
		rtn = 1;


		sectorfloorheight = sectors[secnum].floorheight;


		plat = (plat_t __near*)P_CreateThinker(TF_PLATRAISE_HIGHBITS);
		platRef = GETTHINKERREF(plat);
		sectors_physics[secnum].specialdataRef = platRef;

		plat->type = type;
		plat->secnum = secnum;
		plat->crush = false;
		plat->tag = linetag;

		 

		switch (type) {
			case raiseToNearestAndChange:
				plat->speed = PLATSPEED / 2;
				(&sectors[secnum])->floorpic = sectors[linefrontsecnum].floorpic;

				specialheight = P_FindNextHighestFloor(secnum, sectorfloorheight);
				plat->high = specialheight;
				plat->wait = 0;
				plat->status = plat_up;
				// NO MORE DAMAGE, IF APPLICABLE
				(&sectors_physics[secnum])->special = 0;

				S_StartSoundWithSecnum(secnum, sfx_stnmov);
				break;

			case raiseAndChange:
				(&sectors[secnum])->floorpic = sectors[linefrontsecnum].floorpic;

				plat->speed = PLATSPEED / 2;
				plat->high = sectorfloorheight + amount << SHORTFLOORBITS; // todo test, this looks wrong
				plat->wait = 0;
				plat->status = plat_up;

				S_StartSoundWithSecnum(secnum, sfx_stnmov);
				break;

			case downWaitUpStay:
				plat->speed = PLATSPEED * 4;
				specialheight = P_FindHighestOrLowestFloorSurrounding(secnum, false);
				plat->low = specialheight;

				if (plat->low > sectorfloorheight) {
					plat->low = sectorfloorheight;
				}
				plat->high = sectorfloorheight;
				plat->wait = 35 * PLATWAIT;
				plat->status = plat_down;

				S_StartSoundWithSecnum(secnum, sfx_pstart);
				break;

			case blazeDWUS:
				plat->speed = PLATSPEED * 8;
				specialheight = P_FindHighestOrLowestFloorSurrounding(secnum, false);

				plat->low = specialheight;

				if (plat->low > sectorfloorheight) {
					plat->low = sectorfloorheight;
				}
				plat->high = sectorfloorheight;
				plat->wait = 35 * PLATWAIT;
				plat->status = plat_down;
				S_StartSoundWithSecnum(secnum, sfx_pstart);
				break;

			case perpetualRaise:
				plat->speed = PLATSPEED;
				specialheight = P_FindHighestOrLowestFloorSurrounding(secnum, false);
				if (specialheight > sectorfloorheight) {
					specialheight = sectorfloorheight;
				}

				plat->low = specialheight;

				specialheight = P_FindHighestOrLowestFloorSurrounding(secnum, true);
				plat->high = specialheight;

				if (plat->high < sectorfloorheight) {
					plat->high = sectorfloorheight;
				}

				plat->wait = 35*PLATWAIT;
				plat->status = P_Random()&1;

				S_StartSoundWithSecnum(secnum, sfx_pstart);
				break;
		}
		P_AddActivePlat(platRef);
    }
    return rtn;
}



void __near EV_PlatFunc(uint8_t linetag, int8_t type) {
	int8_t		j;
	plat_t __near* plat;
	for (j = 0; j < MAXPLATS; j++) {
		if (activeplats[j] != NULL_THINKERREF) {
			plat = (plat_t __near*)&thinkerlist[activeplats[j]].data;
			if (plat->tag == linetag){
				if (type == PLAT_FUNC_IN_STASIS && plat->status == plat_in_stasis){
						plat->oldstatus = plat->status;
						P_UpdateThinkerFunc(activeplats[j], TF_PLATRAISE_HIGHBITS);
					
				}

				if (type == PLAT_FUNC_STOP_PLAT && plat->status != plat_in_stasis)  {
						plat->oldstatus = plat->status;
						plat->status = plat_in_stasis;
						P_UpdateThinkerFunc(activeplats[j], TF_NULL);
				}
				
			}
		}
	}
}


void __near P_AddActivePlat(THINKERREF thinkerref) {
    int8_t		i;
    for (i = 0;i < MAXPLATS;i++)
	if (activeplats[i] == NULL_THINKERREF) {
	    activeplats[i] = thinkerref;
	    return;
	}
}



void __near P_RemoveActivePlat(THINKERREF platRef) {
    int8_t		i;
	plat_t __near* plat;
	int16_t platsecnum;
	for (i = 0; i < MAXPLATS; i++) {
		if (platRef == activeplats[i]) {
			plat = (plat_t __near*)&thinkerlist[platRef].data;
			platsecnum = plat->secnum;
			P_RemoveThinker(platRef);
			(&sectors_physics[platsecnum])->specialdataRef = NULL_THINKERREF;

			activeplats[i] = NULL_THINKERREF;

			return;
		}
	}
    
}
