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
( sector_t*	sector,
  short_height_t	speed,
  short_height_t	dest,
  boolean	crush,
  int16_t		floorOrCeiling,
  int16_t		direction )
{
    boolean	somethingcrushed; // plane will possibly move less
    short_height_t	lastpos;

		switch(floorOrCeiling) {
			case 0:
				// FLOOR
				switch(direction) {
					case -1:
						// DOWN


						if (sector->floorheight - speed < dest) {
							lastpos = sector->floorheight;
							sector->floorheight = dest;
							somethingcrushed = P_ChangeSector(sector,crush);
							if (somethingcrushed) {
								sector->floorheight =lastpos;

								P_ChangeSector(sector,crush);
								//return floor_crushed;
							}


							return floor_pastdest;
						} else {
							lastpos = sector->floorheight;
							sector->floorheight -= speed;
							somethingcrushed = P_ChangeSector(sector,crush);

							if (somethingcrushed) {
								sector->floorheight = lastpos;
								P_ChangeSector(sector,crush);
								return floor_crushed;
							}
						}
						break;
						
					case 1:
						// UP
		

						if (sector->floorheight + speed > dest) {
							lastpos = sector->floorheight;
							sector->floorheight = dest;
							somethingcrushed = P_ChangeSector(sector,crush);
							if (somethingcrushed) {
								sector->floorheight = lastpos;
			
								P_ChangeSector(sector,crush);
								//return floor_crushed;
							}
							return floor_pastdest;
						} else {
							// COULD GET CRUSHED
							lastpos = sector->floorheight;
							sector->floorheight += speed;
							somethingcrushed = P_ChangeSector(sector,crush);
							if (somethingcrushed) {
								if (crush == true) {
									return floor_crushed;
								}
								sector->floorheight = lastpos;
								P_ChangeSector(sector,crush);
								return floor_crushed;
							}
		
						}
						break;
				}
				break;
									
			case 1:
			// CEILING
				switch(direction) {
					case -1:
						// DOWN
						if (sector->ceilingheight - speed < dest) {
							lastpos = sector->ceilingheight;
							sector->ceilingheight = dest;
							somethingcrushed = P_ChangeSector(sector,crush);

							if (somethingcrushed) {
								sector->ceilingheight = lastpos;
								P_ChangeSector(sector,crush);
								//return floor_crushed;
							}
							return floor_pastdest;
						} else {
							// COULD GET CRUSHED
							lastpos = sector->ceilingheight;
							sector->ceilingheight -= speed;
							somethingcrushed = P_ChangeSector(sector,crush);

							if (somethingcrushed) {
								if (crush == true) {
									return floor_crushed;
								}
								sector->ceilingheight = lastpos;
								P_ChangeSector(sector,crush);
								return floor_crushed;
							}
						}
						break;
						
					  case 1:
						// UP
						if (sector->ceilingheight + speed > dest) {
							lastpos = sector->ceilingheight;
							sector->ceilingheight = dest;
							somethingcrushed = P_ChangeSector(sector,crush);
							if (somethingcrushed) {
								sector->ceilingheight = lastpos;
								P_ChangeSector(sector,crush);
								//return crushed;
							}
							return floor_pastdest;
						} else {
							lastpos = sector->ceilingheight;
							sector->ceilingheight += speed;
							somethingcrushed = P_ChangeSector(sector,crush);
						}
						break;
					}
				break;
		
    }
    return floor_ok;
}


//
// MOVE A FLOOR TO IT'S DESTINATION (UP OR DOWN)
//
void T_MoveFloor(MEMREF memref)
{
    result_e	res;
	floormove_t* floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(memref);
	sector_t* floorsector = &sectors[floor->secnum];
	int16_t floorsecnum;
	uint8_t floornewspecial;
	floor_e floortype;
	int16_t floordirection;
	uint8_t floortexture;
	THINKERREF floorthinkerRef;
    res = T_MovePlane(floorsector, floor->speed, floor->floordestheight, floor->crush,0,floor->direction);
	floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(memref);
	floorsecnum = floor->secnum;
	if (!(leveltime.h.fracbits & 7)) {
		S_StartSoundWithParams(sectors[floorsecnum].soundorgX, sectors[floorsecnum].soundorgY, sfx_stnmov);
	}

    if (res == floor_pastdest) {
		floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(memref);
		floornewspecial = floor->newspecial;
		floortype = floor->type;
		floordirection = floor->direction;
		floortexture = floor->texture;
		floorthinkerRef = floor->thinkerRef;

		sectors[floorsecnum].specialdataRef = NULL_MEMREF;

		if (floordirection == 1) {
			switch(floortype) {
			  case donutRaise:
				  (&sectors[floorsecnum])->special = floornewspecial;
				  (&sectors[floorsecnum])->floorpic = floortexture;
			  default:
			break;
			}
		} else if (floordirection == -1) {
			switch(floortype) {
			  case lowerAndChange:
				  (&sectors[floorsecnum])->special = floornewspecial;
				  (&sectors[floorsecnum])->floorpic = floortexture;
			  default:
			break;
			}
		}
		P_RemoveThinker(floorthinkerRef);

		S_StartSoundWithParams(sectors[floorsecnum].soundorgX, sectors[floorsecnum].soundorgY, sfx_pstop);
    }

}

//
// HANDLE FLOOR TYPES
//
int16_t
EV_DoFloor
( 
	uint8_t linetag,
	int16_t linefrontsecnum,
  floor_e	floortype )
{
    int16_t			secnum;
    int16_t			rtn;
    int16_t			i;
	int16_t		j = 0;
    floormove_t*	floor;
	MEMREF floorRef;
	int16_t specialheight;
	sector_t* sector;

	int16_t sectorceilingheight;
	int16_t sectorfloorheight;
	int16_t secnumlist[MAX_ADJOINING_SECTORS];

    secnum = -1;
    rtn = 0;
	P_FindSectorsFromLineTag(linetag, secnumlist, false);
	while (secnumlist[j] >= 0) {
		//sec = &sectors[secnum];

		secnum = secnumlist[j];
		sector = &sectors[secnum];
		j++;

		// new floor thinker
		rtn = 1;
		floorRef = Z_MallocThinkerEMS(sizeof(*floor));
		sector->specialdataRef = floorRef;
		sectorceilingheight = sector->ceilingheight;
		sectorfloorheight = sector->floorheight;
		floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);

		floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);

		floor->type = floortype;
		floor->crush = false;

		switch(floortype) {
		  case lowerFloor:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight =  P_FindHighestFloorSurrounding(secnum); 
			floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			break;

		  case lowerFloorToLowest:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindLowestFloorSurrounding(secnum);
			floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;

			break;

		  case turboLower:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED * 4;
			specialheight = P_FindHighestFloorSurrounding(secnum);
			floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;

			if (floor->floordestheight != sectorfloorheight) {
				floor->floordestheight += (8 << SHORTFLOORBITS);
			}
			break;

		  case raiseFloorCrush:
			floor->crush = true;
		  case raiseFloor:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindLowestCeilingSurrounding(secnum);
			floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			if (floor->floordestheight > sectorceilingheight) {
				floor->floordestheight = sectorceilingheight;
			}
			floor->floordestheight -= (8 << SHORTFLOORBITS)* (floortype == raiseFloorCrush);
			break;

		  case raiseFloorTurbo:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED*4;
			specialheight =  P_FindNextHighestFloor(secnum, sectorfloorheight);
			floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;

			break;

		  case raiseFloorToNearest:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindNextHighestFloor(secnum, sectorfloorheight);
			floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			break;

		  case raiseFloor24:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			floor->floordestheight = sectors[floor->secnum].floorheight + (24 << SHORTFLOORBITS);
			break;
		  case raiseFloor512:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			floor->floordestheight = sectors[floor->secnum].floorheight + (512 << SHORTFLOORBITS);
			
			break;

		  case raiseFloor24AndChange:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			floor->floordestheight = sectors[floor->secnum].floorheight + (24 << SHORTFLOORBITS);
			
			sector->floorpic = sectors[linefrontsecnum].floorpic;
			sector->special = sectors[linefrontsecnum].special;
			break;

		  case raiseToTexture: {
			  short_height_t minsize = MAXSHORT;
			  int16_t sidenum;
			  uint8_t sidebottomtexture;
				
			  floor->direction = 1;
			  floor->secnum = secnum;
			  floor->speed = FLOORSPEED;
			  for (i = 0; i < sector->linecount; i++) {
				  if (twoSided (secnum, i) ) {
					  sidenum = getSideNum(secnum,i,0);
					  sidebottomtexture = sides[sidenum].bottomtexture;
					  //if (sidebottomtexture >= 0) {
						  if (textureheights[sidebottomtexture] < minsize) {
							  minsize = textureheights[sidebottomtexture];
						  }
					  //}
					  sidenum = getSideNum(secnum,i,1);
					  sidebottomtexture = sides[sidenum].bottomtexture;

					  //if (sidebottomtexture >= 0) {
						  if (textureheights[sidebottomtexture] < minsize) {
							  minsize = textureheights[sidebottomtexture];
						  }
					  //}
				  }
			  }
			  floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			  floor->floordestheight = sectors[floor->secnum].floorheight + (minsize << SHORTFLOORBITS);
		  }
		  break;
	  
		  case lowerAndChange:{

			int16_t sidenum;

			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindLowestFloorSurrounding(secnum);
			floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			floor->texture = sector->floorpic;

			for (i = 0; i < sector->linecount; i++) {
				if (twoSided(secnum, i)) {
					sidenum = getSideNum(secnum, i, 0);
					if (sides[sidenum].secnum == secnum) {
						secnum = getSector(secnum, i, 1);

						if (sector->floorheight == floor->floordestheight) {
							floor->texture = sector->floorpic;
							floor->newspecial = sector->special;
							break;
						}
					}
					else {
						secnum = getSector(secnum, i, 0);

						if (sector->floorheight == floor->floordestheight) {
							floor->texture = sector->floorpic;
							floor->newspecial = sector->special;
							break;
						}
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
int16_t
EV_BuildStairs
( uint8_t	linetag,
  stair_e	type )
{
    int16_t			secnum;
    short_height_t	height;
    uint8_t			i;
    int16_t			newsecnum;
	uint8_t			texture;
    int16_t			ok;
    int16_t			rtn;
    
    int16_t		tsecOffset;

    floormove_t*	floor;
    
    int16_t		stairsize;
    int16_t		speed;
	MEMREF floorRef;
	int16_t *linebuffer;
	int16_t linebufferOffset;
	int16_t linenum;
	short_height_t sectorceilingheight;
	short_height_t sectorfloorheight;
	uint8_t sectorfloorpic;
	int16_t sectorlinesoffset;
	uint8_t sectorlinecount;
	int16_t secnumlist[MAX_ADJOINING_SECTORS];
	int16_t		j = 0;
	sector_t* sector;
	secnum = -1;
    rtn = 0;
	P_FindSectorsFromLineTag(linetag, secnumlist, false);
	while (secnumlist[j] >= 0) {
		//sec = &sectors[secnum];
		
	// ALREADY MOVING?  IF SO, KEEP GOING...

		secnum = secnumlist[j];
		j++;
		sector = &sectors[secnum];
		// new floor thinker
		rtn = 1;
		floorRef = Z_MallocThinkerEMS(sizeof(*floor));
		sector->specialdataRef = floorRef;
		sectorceilingheight = sector->ceilingheight;
		sectorfloorheight = sector->floorheight;
		sectorfloorpic = sector->floorpic;
		sectorlinecount = sector->linecount;
		sectorlinesoffset = sector->linesoffset;
		floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);

		floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);
		floor->direction = 1;
		floor->secnum = secnum;

		switch(type) {
		  case build8:
			speed = (FLOORSPEED/4);
			stairsize = (8 << SHORTFLOORBITS);
			break;
		  case turbo16:
			speed = (FLOORSPEED*4);
			stairsize = (16 << SHORTFLOORBITS);
			break;
		}
		floor->speed = speed;
		height = sectorfloorheight + stairsize;
		floor->floordestheight = height;
		
		texture = sectorfloorpic;
	
		// Find next sector to raise
		// 1.	Find 2-sided line with same sector side[0]
		// 2.	Other side is the next sector to raise
		do {
			ok = 0;
			for (i = 0;i < sectorlinecount;i++) {
				linebufferOffset = sectorlinesoffset + i;
				linebuffer = (int16_t*)Z_LoadBytesFromConventional(linebufferRef);
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

				floorRef = Z_MallocThinkerEMS(sizeof(*floor));
				sectors[tsecOffset].specialdataRef = floorRef;
				floor = (floormove_t*)Z_LoadThinkerBytesFromEMS(floorRef);

				floor->floordestheight = height;

				floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);

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

