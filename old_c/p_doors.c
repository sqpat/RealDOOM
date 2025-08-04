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
// DESCRIPTION: Door animation code (opening/closing)
//

#include "doomdef.h"
#include "z_zone.h"
#include "p_local.h"

#include "s_sound.h"


// State.
#include "doomstat.h"
#include "r_state.h"

// Data.
#include "dstrings.h"
#include "sounds.h"
#include "i_system.h"
#include "m_memory.h"
#include "m_near.h"
#include <i86.h>

//
// VERTICAL DOORS
//

//
// T_VerticalDoor
//
/*
void __near T_VerticalDoor (vldoor_t __near* door, THINKERREF doorRef) {
    result_e	res;
	int16_t secnum = door->secnum;
	sector_t __far* doorsector = &sectors[secnum];

	switch(door->direction) {
		  case 0:
		// WAITING
		if (!--door->topcountdown) {
			switch(door->type) {
				case blazeRaise:
					door->direction = -1; // time to go back down
					S_StartSoundWithParams(secnum, sfx_bdcls);
					break;
		
				case normal:
					door->direction = -1; // time to go back down
					S_StartSoundWithParams(secnum, sfx_dorcls);
					break;
		
				case close30ThenOpen:
					door->direction = 1;
					S_StartSoundWithParams(secnum, sfx_doropn);
					break;
		
				default:
					break;
			}
		}
		break;
	
		  case 2:
		//  INITIAL WAIT
		if (!--door->topcountdown) {
			switch(door->type) {
				case raiseIn5Mins:
					door->direction = 1;
					door->type = normal;
					S_StartSoundWithParams(secnum, sfx_doropn);
					break;
		
				default:
					break;
			}
		}
		break;
	
		  case -1:
		// DOWN

			res = T_MovePlaneCeilingDown(FP_OFF(doorsector), door->speed, doorsector->floorheight, false);
			if (res == floor_pastdest) {
				switch(door->type) {
					case blazeRaise:
					case blazeClose:
						sectors_physics[door->secnum].specialdataRef = NULL_THINKERREF;
						P_RemoveThinker (doorRef);  // unlink and free
						S_StartSoundWithParams(secnum, sfx_bdcls);
						break;
		
					case normal:
					case close:
						sectors_physics[door->secnum].specialdataRef = NULL_THINKERREF;
						P_RemoveThinker(doorRef);  // unlink and free
						break;
		
					case close30ThenOpen:
						door->direction = 0;
						door->topcountdown = 35*30;
						break;
		
					default:
						break;
				}
			} else if (res == floor_crushed) {
				switch(door->type) {
					case blazeClose:
					case close:		// DO NOT GO BACK UP!
						break;
		
					default:
						door->direction = 1;
						S_StartSoundWithParams(secnum, sfx_doropn);
						break;
				}
			}
			break;
	
			case 1:
				// UP
				res = T_MovePlaneCeilingUp(FP_OFF(doorsector),   door->speed, door->topheight, false);




				if (res == floor_pastdest) {
					switch(door->type) {
						case blazeRaise:
						case normal:
							door->direction = 0; // wait at top
							door->topcountdown = door->topwait;
							break;
		
						case close30ThenOpen:
						case blazeOpen:
						case open:
							sectors_physics[door->secnum].specialdataRef = NULL_THINKERREF;
							P_RemoveThinker(doorRef);  // unlink and free
							break;
		
						default:
							break;
			}
		}
		break;
    }
 
}


//
// EV_DoLockedDoor
// Move a locked door up/down
//

int16_t __near EV_DoLockedDoor ( uint8_t linetag, int16_t linespecial, vldoor_e	type, THINKERREF thingRef ) {
	
    if (thingRef != playerMobjRef)
		return 0;
		
    switch(linespecial)
    {
      case 99:	// Blue Lock
      case 133:

		  if (!player.cards[it_bluecard] && !player.cards[it_blueskull])
	{
			  player.message = PD_BLUEO;
	    S_StartSound(NULL,sfx_oof);
	    return 0;
	}
	break;
	
      case 134: // Red Lock
      case 135:

		  if (!player.cards[it_redcard] && !player.cards[it_redskull])
	{
			  player.message = PD_REDO;
	    S_StartSound(NULL,sfx_oof);
	    return 0;
	}
	break;
	
      case 136:	// Yellow Lock
      case 137:

		  if (!player.cards[it_yellowcard] &&
	    !player.cards[it_yellowskull])
	{
		player.message = PD_YELLOWO;
	    S_StartSound(NULL,sfx_oof);
	    return 0;
	}
	break;	
    }

    return EV_DoDoor(linetag,type);
}


int16_t __far EV_DoDoor ( uint8_t linetag, vldoor_e	type ) {
    int16_t		secnum,rtn;
    vldoor_t __near*	door;
	THINKERREF doorRef;
	int16_t doortopheight;
	sector_t  __far*doorsector;
	int16_t secnumlist[MAX_ADJOINING_SECTORS];
	int16_t		j = 0;
	int16_t soundorgx;
	int16_t soundorgy;


    secnum = -1;
    rtn = 0;
	P_FindSectorsFromLineTag(linetag, secnumlist, false);

	while (secnumlist[j] >= 0) {
		secnum = secnumlist[j];
		j++;
		
	
		// new door thinker
		rtn = 1;



		doorsector = &sectors[secnum];

		door  = (vldoor_t __near*)P_CreateThinker (TF_VERTICALDOOR_HIGHBITS);
		doorRef = GETTHINKERREF(door);
		sectors_physics[secnum].specialdataRef = doorRef;

	
		door->secnum = secnum;
		door->type = type;
		door->topwait = VDOORWAIT;
		door->speed = VDOORSPEED;
		
		switch(type)
		{
		  case blazeClose:
			doortopheight = P_FindLowestOrHighestCeilingSurrounding(secnum, false);
			door->topheight = doortopheight - (4 << SHORTFLOORBITS);
			door->direction = -1;
			door->speed = VDOORSPEED * 4;
			S_StartSoundWithParams(secnum, sfx_bdcls);
			break;
	    
		  case close:
			doortopheight = P_FindLowestOrHighestCeilingSurrounding(secnum, false);
			door->topheight = doortopheight - (4 << SHORTFLOORBITS);
			door->direction = -1;
			S_StartSoundWithParams(secnum, sfx_dorcls);
			break;
	    
		  case close30ThenOpen:
			door->topheight = doorsector->ceilingheight;
			door->direction = -1;
			S_StartSoundWithParams(secnum, sfx_dorcls);
			break;
	    
		  case blazeRaise:
		  case blazeOpen:
			door->direction = 1;
			doortopheight = P_FindLowestOrHighestCeilingSurrounding(secnum, false);
			door->topheight = doortopheight - (4 << SHORTFLOORBITS);
			door->speed = VDOORSPEED * 4;
			if (door->topheight != (doorsector->ceilingheight))
				S_StartSoundWithParams(secnum, sfx_bdopn);
			break;
	    
		  case normal:
		  case open:
			door->direction = 1;
			doortopheight = P_FindLowestOrHighestCeilingSurrounding(secnum, false);
			door->topheight = doortopheight - (4 << SHORTFLOORBITS);
			if (door->topheight != doorsector->ceilingheight)
				S_StartSoundWithParams(secnum, sfx_doropn);
			break;
	    
		  default:
			break;
		}
		
    }
    return rtn;
}


//
// EV_VerticalDoor : open a door manually, no tag value
//
void __near EV_VerticalDoor ( int16_t linenum, THINKERREF thingRef ) {
    int16_t		secnum;
    //sector_t __far*	sec;
    vldoor_t __near*	door;
    //int16_t		side = 0;
	THINKERREF doorRef;
	int16_t linespecial = lines_physics[linenum].special;
	int16_t doortopheight;
	sector_t  __far*doorsector;
	sector_physics_t  __near*doorsector_physics;


		
    switch(linespecial)
    {
      case 26: // Blue Lock
      case 32:
		if ( thingRef != playerMobjRef)
			return;
	
		if (!player.cards[it_bluecard] && !player.cards[it_blueskull])
		{
			player.message = PD_BLUEK;
			S_StartSound(NULL,sfx_oof);
			return;
		}
	break;
	
      case 27: // Yellow Lock
      case 34:
		  if (thingRef != playerMobjRef)
			  return;
	
	if (!player.cards[it_yellowcard] &&
	    !player.cards[it_yellowskull])
	{
	    player.message = PD_YELLOWK;
	    S_StartSound(NULL,sfx_oof);
	    return;
	}
	break;
	
      case 28: // Red Lock
      case 33:
		  if (thingRef != playerMobjRef)
			  return;

	if (!player.cards[it_redcard] && !player.cards[it_redskull])
	{
	    player.message = PD_REDK;
	    S_StartSound(NULL,sfx_oof);
	    return;
	}
	break;
    }
 

    // if the sector has an active thinker, use it
	
	// side always 0 so...
	//secnum = side ? lines[linenum].backsecnum : lines[linenum].frontsecnum;
	secnum = lines_physics[linenum].backsecnum;


	doorsector = &sectors[secnum];
	doorsector_physics = &sectors_physics[secnum];

    if (doorsector_physics->specialdataRef) {
		
		doorRef = doorsector_physics->specialdataRef;
		door = (vldoor_t __near*)&thinkerlist[doorRef].data;


		switch(linespecial) {
			case	1: // ONLY FOR "RAISE" DOORS, NOT "OPEN"s
			case	26:
			case	27:
			case	28:
			case	117:


				if (door->direction == -1) {
					door->direction = 1;	// go back up
				} else {
					if (thingRef != playerMobjRef)
						return;
					door->direction = -1;	// start going down immediately
				}

				return;
		}
    }
	 
    // for proper sound
    switch(linespecial)
    {
      case 117:	// BLAZING DOOR RAISE
      case 118:	// BLAZING DOOR OPEN
		  S_StartSoundWithParams(secnum, sfx_bdopn);
	break;
	
      case 1:	// NORMAL DOOR SOUND
      case 31:
		  S_StartSoundWithParams(secnum, sfx_doropn);
	break;
	
      default:	// LOCKED DOOR SOUND
		  S_StartSoundWithParams(secnum, sfx_doropn);
	break;
    }
	
    
    // new door thinker

	
	door = (vldoor_t __near*)P_CreateThinker(TF_VERTICALDOOR_HIGHBITS);
	doorRef = GETTHINKERREF(door);
	door->secnum = secnum;
	door->direction = 1;
	door->speed = VDOORSPEED;
	door->topwait = VDOORWAIT;
	sectors_physics[secnum].specialdataRef = doorRef;


    switch(linespecial) {
		case 1:
		case 26:
		case 27:
		case 28:
			door->type = normal;
			break;
	
		case 31:
		case 32:
		case 33:
		case 34:
			door->type = open;
			lines_physics[linenum].special = 0;
			break;
	
		case 117:	// blazing door raise
			door->type = blazeRaise;
			door->speed = VDOORSPEED*4;
			break;
		case 118:	// blazing door open
			door->type = blazeOpen;
			door->speed = VDOORSPEED*4;
			lines_physics[linenum].special = 0;
			break;
    }
    
    // find the top and bottom of the movement range
	doortopheight = P_FindLowestOrHighestCeilingSurrounding(secnum, false);
	door->topheight = doortopheight - (4 << SHORTFLOORBITS);
}


//
// Spawn a door that closes after 30 seconds
//
void __near P_SpawnDoorCloseIn30 (int16_t secnum) {
    vldoor_t __near*	door;
	THINKERREF doorRef;

	door = (vldoor_t __near*)P_CreateThinker(TF_VERTICALDOOR_HIGHBITS);
	doorRef = GETTHINKERREF(door);
	door->secnum = secnum;
	door->direction = 0;
	door->type = normal;
	door->speed = VDOORSPEED;
	door->topcountdown = 30 * 35;

	sectors_physics[secnum].specialdataRef = doorRef;
	sectors_physics[secnum].special = 0;

   
}

//
// Spawn a door that opens after 5 minutes
//
void __near P_SpawnDoorRaiseIn5Mins ( int16_t secnum) {
	vldoor_t __near*	door;
	THINKERREF doorRef;
	int16_t doortopheight;

	door = (vldoor_t __near*)P_CreateThinker(TF_VERTICALDOOR_HIGHBITS);
	doorRef = GETTHINKERREF(door);

	
    door->secnum = secnum;
    door->direction = 2;
    door->type = raiseIn5Mins;
    door->speed = VDOORSPEED;

	doortopheight = P_FindLowestOrHighestCeilingSurrounding(secnum, false);
	door->topheight = doortopheight - (4 << SHORTFLOORBITS);
	door->topwait = VDOORWAIT;
    door->topcountdown = 5 * 60 * 35;

	sectors_physics[secnum].specialdataRef = doorRef;
	sectors_physics[secnum].special = 0;


}

*/