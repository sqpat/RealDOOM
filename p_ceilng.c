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
// DESCRIPTION:  Ceiling aninmation (lowering, crushing, raising)
//


#include "z_zone.h"
#include "doomdef.h"
#include "p_local.h"

#include "s_sound.h"

// State.
#include "doomstat.h"
#include "r_state.h"

// Data.
#include "sounds.h"

//
// CEILINGS
//


MEMREF	activeceilings[MAXCEILINGS];


//
// T_MoveCeiling
//

void T_MoveCeiling (MEMREF memref)
{
    result_e	res;
	ceiling_t* ceiling = (ceiling_t*)Z_LoadBytesFromEMS(memref);
	
    switch(ceiling->direction)
    {
      case 0:
	// IN STASIS
	break;
      case 1:
	// UP
	res = T_MovePlane(ceiling->sector,
			  ceiling->speed,
			  ceiling->topheight,
			  false,1,ceiling->direction);
	
	if (!(leveltime&7))
	{
	    switch(ceiling->type)
	    {
	      case silentCrushAndRaise:
		break;
	      default:
		S_StartSound((mobj_t *)&ceiling->sector->soundorg,
			     sfx_stnmov);
		// ? 
		break;
	    }
	}
	
	if (res == pastdest)
	{
	    switch(ceiling->type)
	    {
	      case raiseToHighest:
		P_RemoveActiveCeiling(memref);
		break;
		
	      case silentCrushAndRaise:
		S_StartSound((mobj_t *)&ceiling->sector->soundorg,
			     sfx_pstop);
	      case fastCrushAndRaise:
	      case crushAndRaise:
		ceiling->direction = -1;
		break;
		
	      default:
		break;
	    }
	    
	}
	break;
	
      case -1:
	// DOWN
	res = T_MovePlane(ceiling->sector,
			  ceiling->speed,
			  ceiling->bottomheight,
			  ceiling->crush,1,ceiling->direction);
	
	if (!(leveltime&7))
	{
	    switch(ceiling->type)
	    {
	      case silentCrushAndRaise: break;
	      default:
		S_StartSound((mobj_t *)&ceiling->sector->soundorg,
			     sfx_stnmov);
	    }
	}
	
	if (res == pastdest)
	{
	    switch(ceiling->type)
	    {
	      case silentCrushAndRaise:
		S_StartSound((mobj_t *)&ceiling->sector->soundorg,
			     sfx_pstop);
	      case crushAndRaise:
		ceiling->speed = CEILSPEED;
	      case fastCrushAndRaise:
		ceiling->direction = 1;
		break;

	      case lowerAndCrush:
	      case lowerToFloor:
		P_RemoveActiveCeiling(memref);
		break;

	      default:
		break;
	    }
	}
	else // ( res != pastdest )
	{
	    if (res == crushed)
	    {
		switch(ceiling->type)
		{
		  case silentCrushAndRaise:
		  case crushAndRaise:
		  case lowerAndCrush:
		    ceiling->speed = CEILSPEED / 8;
		    break;

		  default:
		    break;
		}
	    }
	}
	break;
    }
}


//
// EV_DoCeiling
// Move a ceiling up/down and all around!
//
int
EV_DoCeiling
( line_t*	line,
  ceiling_e	type )
{
    int		secnum;
    int		rtn;
    sector_t*	sec;
    ceiling_t*	ceiling;
	MEMREF ceilingRef;
	
    secnum = -1;
    rtn = 0;
    
    //	Reactivate in-stasis ceilings...for certain types.
    switch(type)
    {
      case fastCrushAndRaise:
      case silentCrushAndRaise:
      case crushAndRaise:
	P_ActivateInStasisCeiling(line);
      default:
	break;
    }
	
    while ((secnum = P_FindSectorFromLineTag(line,secnum)) >= 0)
    {
	sec = &sectors[secnum];
	if (sec->specialdataRef != NULL_MEMREF)
	    continue;
	
	// new door thinker
	rtn = 1;
	ceilingRef = Z_MallocEMSNew(sizeof(*ceiling), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	ceiling = (ceiling_t*)Z_LoadBytesFromEMS(ceilingRef);

	ceiling->thinkerRef = P_AddThinker (ceilingRef, TF_MOVECEILING);
	sec->specialdataRef = ceilingRef;
	
	ceiling->sector = sec;
	ceiling->crush = false;
	
	switch(type)
	{
	  case fastCrushAndRaise:
	    ceiling->crush = true;
	    ceiling->topheight = sec->ceilingheight;
	    ceiling->bottomheight = sec->floorheight + (8*FRACUNIT);
	    ceiling->direction = -1;
	    ceiling->speed = CEILSPEED * 2;
	    break;

	  case silentCrushAndRaise:
	  case crushAndRaise:
	    ceiling->crush = true;
	    ceiling->topheight = sec->ceilingheight;
	  case lowerAndCrush:
	  case lowerToFloor:
	    ceiling->bottomheight = sec->floorheight;
	    if (type != lowerToFloor)
		ceiling->bottomheight += 8*FRACUNIT;
	    ceiling->direction = -1;
	    ceiling->speed = CEILSPEED;
	    break;

	  case raiseToHighest:
	    ceiling->topheight = P_FindHighestCeilingSurrounding(sec);
	    ceiling->direction = 1;
	    ceiling->speed = CEILSPEED;
	    break;
	}
		
	ceiling->tag = sec->tag;
	ceiling->type = type;
	P_AddActiveCeiling(ceilingRef);
    }
    return rtn;
}


//
// Add an active ceiling
//
void P_AddActiveCeiling(MEMREF memref) {
    int		i;
    
    for (i = 0; i < MAXCEILINGS;i++) {
		if (activeceilings[i] == NULL_MEMREF) {
			activeceilings[i] = memref;
			return;
		}
    }
}



//
// Remove a ceiling's thinker
//
void P_RemoveActiveCeiling(MEMREF memref)
{
    int		i;
	ceiling_t* c;

    for (i = 0;i < MAXCEILINGS;i++)
    {
	if (activeceilings[i] == memref)
	{
		c = (ceiling_t*)Z_LoadBytesFromEMS(memref);
		c->sector->specialdataRef = NULL_MEMREF;
	    P_RemoveThinker (c->thinkerRef);
	    activeceilings[i] = NULL_MEMREF;
	    break;
	}
    }
}



//
// Restart a ceiling that's in-stasis
//
void P_ActivateInStasisCeiling(line_t* line)
{
    int		i;
	ceiling_t* c;

	for (i = 0; i < MAXCEILINGS; i++) {
		if (activeceilings[i] != NULL_MEMREF) {
			c = (ceiling_t*)Z_LoadBytesFromEMS(activeceilings[i]);
			if ((c->tag == line->tag) && (c->direction == 0)) {
				c->direction = c->olddirection;

				P_UpdateThinkerFunc(c->thinkerRef, TF_MOVECEILING);
			}
		}
	}
}



//
// EV_CeilingCrushStop
// Stop a ceiling from crushing!
//
int	EV_CeilingCrushStop(line_t	*line)
{
    int		i;
    int		rtn;
	ceiling_t* c;
	rtn = 0;
	for (i = 0; i < MAXCEILINGS; i++) {
		if (activeceilings[i] != NULL_MEMREF) {
			c = (ceiling_t*)Z_LoadBytesFromEMS(activeceilings[i]);
			if ((c->tag == line->tag) && (c->direction != 0)) {
				c->olddirection = c->direction;
				P_UpdateThinkerFunc(c->thinkerRef, TF_NULL);
				c->direction = 0;		// in-stasis
				rtn = 1;
			}
		}
	}

    return rtn;
}
