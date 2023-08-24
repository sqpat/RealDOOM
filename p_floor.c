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
//	Floor animation: raising stairs.
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
#include "i_system.h"


//
// FLOORS
//

//
// Move a plane (floor or ceiling) and check for crushing
//
result_e
T_MovePlane
( short	secnum,
  fixed_t	speed,
  fixed_t	dest,
  boolean	crush,
  int		floorOrCeiling,
  int		direction )
{
    boolean	flag;
    fixed_t	lastpos;
	
    switch(floorOrCeiling)
    {
      case 0:
	// FLOOR
	switch(direction)
	{
	  case -1:
	    // DOWN
		 
		  if (sectors[secnum].floorheight - speed < dest)
	    {
		lastpos = sectors[secnum].floorheight;
		sectors[secnum].floorheight = dest;
		flag = P_ChangeSector(secnum,crush);
		if (flag == true)
		{
			sectors[secnum].floorheight =lastpos;

			P_ChangeSector(secnum,crush);
		    //return crushed;
		}
		return pastdest;
	    }
	    else
	    {
		lastpos = sectors[secnum].floorheight;
		sectors[secnum].floorheight -= speed;
		flag = P_ChangeSector(secnum,crush);
		if (flag == true)
		{
			sectors[secnum].floorheight = lastpos;
			P_ChangeSector(secnum,crush);
		    return crushed;
		}
	    }
	    break;
						
	  case 1:
	    // UP
		

		  if (sectors[secnum].floorheight + speed > dest)
	    {
		lastpos = sectors[secnum].floorheight;
		sectors[secnum].floorheight = dest;
		flag = P_ChangeSector(secnum,crush);
		if (flag == true)
		{
			sectors[secnum].floorheight = lastpos;
			
			P_ChangeSector(secnum,crush);
		    //return crushed;
		}
		return pastdest;
	    }
	    else
	    {
		// COULD GET CRUSHED
		lastpos = sectors[secnum].floorheight;
		sectors[secnum].floorheight += speed;
		flag = P_ChangeSector(secnum,crush);
		if (flag == true)
		{
		    if (crush == true)
			return crushed;
			sectors[secnum].floorheight = lastpos;
			P_ChangeSector(secnum,crush);
		    return crushed;
		}
		
	    }
	    break;
	}
	break;
									
      case 1:
	// CEILING
	switch(direction)
	{
	  case -1:
	    // DOWN
	    if (sectors[secnum].ceilingheight - speed < dest)
	    {
		lastpos = sectors[secnum].ceilingheight;
		sectors[secnum].ceilingheight = dest;
		flag = P_ChangeSector(secnum,crush);

		if (flag == true)
		{
			sectors[secnum].ceilingheight = lastpos;
			P_ChangeSector(secnum,crush);
		    //return crushed;
		}
		return pastdest;
	    }
	    else
	    {
		// COULD GET CRUSHED
		lastpos = sectors[secnum].ceilingheight;
		sectors[secnum].ceilingheight -= speed;
		flag = P_ChangeSector(secnum,crush);

		if (flag == true)
		{
		    if (crush == true)
			return crushed;
			sectors[secnum].ceilingheight = lastpos;
			P_ChangeSector(secnum,crush);
		    return crushed;
		}
	    }
	    break;
						
	  case 1:
	    // UP
	    if (sectors[secnum].ceilingheight + speed > dest)
	    {
		lastpos = sectors[secnum].ceilingheight;
		sectors[secnum].ceilingheight = dest;
		flag = P_ChangeSector(secnum,crush);
		if (flag == true)
		{
			sectors[secnum].ceilingheight = lastpos;
			P_ChangeSector(secnum,crush);
		    //return crushed;
		}
		return pastdest;
	    }
	    else
	    {
		lastpos = sectors[secnum].ceilingheight;
		sectors[secnum].ceilingheight += speed;
		flag = P_ChangeSector(secnum,crush);
// UNUSED
#if 0
		if (flag == true)
		{
			sectors[secnum].ceilingheight = lastpos;
			P_ChangeSector(secnum,crush);
		    return crushed;
		}
#endif
	    }
	    break;
	}
	break;
		
    }
    return ok;
}


//
// MOVE A FLOOR TO IT'S DESTINATION (UP OR DOWN)
//
void T_MoveFloor(MEMREF memref)
{
    result_e	res;
	floormove_t* floor = (floormove_t*)Z_LoadBytesFromEMS(memref);
	short floorsecnum;

    res = T_MovePlane(floor->secnum,
		      floor->speed,
		      floor->floordestheight,
		      floor->crush,0,floor->direction);
	floor = (floormove_t*)Z_LoadBytesFromEMS(memref);
    if (!(leveltime&7))
		S_StartSoundWithParams(sectors[floor->secnum].soundorgX, sectors[floor->secnum].soundorgY, sfx_stnmov);
	
	floor = (floormove_t*)Z_LoadBytesFromEMS(memref);
	floorsecnum = floor->secnum;

    if (res == pastdest)
    {
		sectors[floorsecnum].specialdataRef = NULL_MEMREF;

	if (floor->direction == 1)
	{
	    switch(floor->type)
	    {
	      case donutRaise:
			  sectors[floorsecnum].special = floor->newspecial;
			  sectors[floorsecnum].floorpic = floor->texture;
	      default:
		break;
	    }
	}
	else if (floor->direction == -1)
	{
	    switch(floor->type)
	    {
	      case lowerAndChange:
			  sectors[floorsecnum].special = floor->newspecial;
			  sectors[floorsecnum].floorpic = floor->texture;
	      default:
		break;
	    }
	}
	P_RemoveThinker(floor->thinkerRef);

	S_StartSoundWithParams(sectors[floorsecnum].soundorgX, sectors[floorsecnum].soundorgY, sfx_pstop);
    }

}

//
// HANDLE FLOOR TYPES
//
int
EV_DoFloor
( 
	short linetag,
	short linefrontsecnum,
  floor_e	floortype )
{
    int			secnum;
    int			rtn;
    int			i;
    //sector_t*		sec;
    floormove_t*	floor;
	MEMREF floorRef;
	fixed_t* textureheight;

    secnum = -1;
    rtn = 0;
    while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0)
    {
	//sec = &sectors[secnum];
		
	// ALREADY MOVING?  IF SO, KEEP GOING...
	if (sectors[secnum].specialdataRef)
	    continue;
	
	// new floor thinker
	rtn = 1;
	floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);

	floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);
	sectors[secnum].specialdataRef = floorRef;

	floor->type = floortype;
	floor->crush = false;

	switch(floortype)
	{
	  case lowerFloor:
	    floor->direction = -1;
	    floor->secnum = secnum;
	    floor->speed = FLOORSPEED;
	    floor->floordestheight = 
		P_FindHighestFloorSurrounding(secnum);
	    break;

	  case lowerFloorToLowest:
	    floor->direction = -1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED;
	    floor->floordestheight = 
		P_FindLowestFloorSurrounding(secnum);
	    break;

	  case turboLower:
	    floor->direction = -1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED * 4;
	    floor->floordestheight =  P_FindHighestFloorSurrounding(secnum);
	    if (floor->floordestheight != sectors[secnum].floorheight)
		floor->floordestheight += 8*FRACUNIT;
	    break;

	  case raiseFloorCrush:
	    floor->crush = true;
	  case raiseFloor:
	    floor->direction = 1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED;
	    floor->floordestheight = 
		P_FindLowestCeilingSurrounding(secnum);
	    if (floor->floordestheight > sectors[secnum].ceilingheight)
		floor->floordestheight = sectors[secnum].ceilingheight;
	    floor->floordestheight -= (8*FRACUNIT)*
		(floortype == raiseFloorCrush);
	    break;

	  case raiseFloorTurbo:
	    floor->direction = 1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED*4;
	    floor->floordestheight = 
		P_FindNextHighestFloor(secnum, sectors[secnum].floorheight);
	    break;

	  case raiseFloorToNearest:
	    floor->direction = 1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED;
	    floor->floordestheight = 
		P_FindNextHighestFloor(secnum, sectors[secnum].floorheight);
	    break;

	  case raiseFloor24:
	    floor->direction = 1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED;
	    floor->floordestheight = sectors[floor->secnum].floorheight +
		24 * FRACUNIT;
	    break;
	  case raiseFloor512:
	    floor->direction = 1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED;
	    floor->floordestheight = sectors[floor->secnum].floorheight +
		512 * FRACUNIT;
	    break;

	  case raiseFloor24AndChange:
	    floor->direction = 1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED;
	    floor->floordestheight = sectors[floor->secnum].floorheight +
		24 * FRACUNIT;
		sectors[secnum].floorpic = sectors[linefrontsecnum].floorpic;
		sectors[secnum].special = sectors[linefrontsecnum].special;
	    break;

	  case raiseToTexture:
	  {
	      int	minsize = MAXINT;
	      side_t*	side;
				
	      floor->direction = 1;
		  floor->secnum = secnum;
		  floor->speed = FLOORSPEED;
	      for (i = 0; i < sectors[secnum].linecount; i++)
	      {
		  if (twoSided (secnum, i) )
		  {
			  textureheight = Z_LoadBytesFromEMS(textureheightRef);
			  side = getSide(secnum,i,0);
		      if (side->bottomtexture >= 0)
			  if (textureheight[side->bottomtexture] < 
			      minsize)
			      minsize = 
				  textureheight[side->bottomtexture];
		      side = getSide(secnum,i,1);
		      if (side->bottomtexture >= 0)
			  if (textureheight[side->bottomtexture] < 
			      minsize)
			      minsize = 
				  textureheight[side->bottomtexture];
		  }
	      }
	      floor->floordestheight =
			  sectors[floor->secnum].floorheight + minsize;
	  }
	  break;
	  
	  case lowerAndChange:
	    floor->direction = -1;
		floor->secnum = secnum;
		floor->speed = FLOORSPEED;
	    floor->floordestheight = 
		P_FindLowestFloorSurrounding(secnum);
	    floor->texture = sectors[secnum].floorpic;

	    for (i = 0; i < sectors[secnum].linecount; i++)
	    {
		if ( twoSided(secnum, i) )
		{
		    if (getSide(secnum,i,0)->secnum == secnum)
		    {
			secnum = getSector(secnum,i,1);

			if (sectors[secnum].floorheight == floor->floordestheight)
			{
			    floor->texture = sectors[secnum].floorpic;
			    floor->newspecial = sectors[secnum].special;
			    break;
			}
		    }
		    else
		    {
				secnum = getSector(secnum,i,0);

			if (sectors[secnum].floorheight == floor->floordestheight)
			{
			    floor->texture = sectors[secnum].floorpic;
			    floor->newspecial = sectors[secnum].special;
			    break;
			}
		    }
		}
	    }
	  default:
	    break;
	}
    }
    return rtn;
}




//
// BUILD A STAIRCASE!
//
int
EV_BuildStairs
( short	linetag,
  stair_e	type )
{
    int			secnum;
    int			height;
    int			i;
    int			newsecnum;
    int			texture;
    int			ok;
    int			rtn;
    
    //sector_t*		sec;
    short		tsecOffset;

    floormove_t*	floor;
    
    fixed_t		stairsize;
    fixed_t		speed;
	MEMREF floorRef;
	short *linebuffer;
	short linebufferOffset;
	short linenum;

    secnum = -1;
    rtn = 0;
    while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0)
    {
	//sec = &sectors[secnum];
		
	// ALREADY MOVING?  IF SO, KEEP GOING...
	if (sectors[secnum].specialdataRef)
	    continue;
	
	// new floor thinker
	rtn = 1;
	floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
	floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);

	floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);
	sectors[secnum].specialdataRef = floorRef;
	floor->direction = 1;
	floor->secnum = secnum;

	switch(type)
	{
	  case build8:
	    speed = FLOORSPEED/4;
	    stairsize = 8*FRACUNIT;
	    break;
	  case turbo16:
	    speed = FLOORSPEED*4;
	    stairsize = 16*FRACUNIT;
	    break;
	}
	floor->speed = speed;
	height = sectors[secnum].floorheight + stairsize;
	floor->floordestheight = height;
		
	texture = sectors[secnum].floorpic;
	
	// Find next sector to raise
	// 1.	Find 2-sided line with same sector side[0]
	// 2.	Other side is the next sector to raise
	do {
	    ok = 0;
	    for (i = 0;i < sectors[secnum].linecount;i++) {
			linebufferOffset = sectors[secnum].linesoffset + i;
			linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
			linenum = linebuffer[linebufferOffset];
			if (!((&lines[linenum])->flags & ML_TWOSIDED)) {
				continue;
			}
			tsecOffset = (&lines[linenum])->frontsecnum;
			newsecnum = tsecOffset ;
		
			if (secnum != newsecnum)
				continue;

			tsecOffset = (&lines[linenum])->backsecnum;
			newsecnum = tsecOffset;

			if (sectors[tsecOffset].floorpic != texture)
				continue;
					
			height += stairsize;

			if (sectors[tsecOffset].specialdataRef)
				continue;
					
			//sec = tsecOffset;
			secnum = newsecnum;

			floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);

			floor->floordestheight = height;

			floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);

			sectors[tsecOffset].specialdataRef = floorRef;
			floor->direction = 1;
			floor->secnum = tsecOffset;
			floor->speed = speed;
			floor->floordestheight = height;
			ok = 1;
			break;
	    }
	} while(ok);
    }
    return rtn;
}

