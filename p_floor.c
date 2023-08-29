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
( int16_t	secnum,
  short_height_t	speed,
  short_height_t	dest,
  boolean	crush,
  int16_t		floorOrCeiling,
  int16_t		direction )
{
    boolean	flag;
    short_height_t	lastpos;
	sector_t*  sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		switch(floorOrCeiling) {
			case 0:
				// FLOOR
				switch(direction) {
					case -1:
						// DOWN


						if ((&sectors[secnum])->floorheight - speed < dest) {
							lastpos = (&sectors[secnum])->floorheight;
							(&sectors[secnum])->floorheight = dest;
							flag = P_ChangeSector(secnum,crush);
							if (flag == true) {
								sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
								(&sectors[secnum])->floorheight =lastpos;

								P_ChangeSector(secnum,crush);
								//return floor_crushed;
							}


							return floor_pastdest;
						} else {
							lastpos = (&sectors[secnum])->floorheight;
							(&sectors[secnum])->floorheight -= speed;
							flag = P_ChangeSector(secnum,crush);


					

							if (flag == true) {
								sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
								(&sectors[secnum])->floorheight = lastpos;
								P_ChangeSector(secnum,crush);
								return floor_crushed;
							}
						}
						break;
						
					case 1:
						// UP
		

						if ((&sectors[secnum])->floorheight + speed > dest) {
							lastpos = (&sectors[secnum])->floorheight;
							(&sectors[secnum])->floorheight = dest;
							flag = P_ChangeSector(secnum,crush);
							if (flag == true) {
								sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
								(&sectors[secnum])->floorheight = lastpos;
			
								P_ChangeSector(secnum,crush);
								//return floor_crushed;
							}
							return floor_pastdest;
						} else {
							// COULD GET CRUSHED
							lastpos = (&sectors[secnum])->floorheight;
							(&sectors[secnum])->floorheight += speed;
							flag = P_ChangeSector(secnum,crush);
							if (flag == true) {
								if (crush == true) {
									return floor_crushed;
								}
								sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
								(&sectors[secnum])->floorheight = lastpos;
								P_ChangeSector(secnum,crush);
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
						if ((&sectors[secnum])->ceilingheight - speed < dest) {
							lastpos = (&sectors[secnum])->ceilingheight;
							(&sectors[secnum])->ceilingheight = dest;
							flag = P_ChangeSector(secnum,crush);

							if (flag == true) {
								sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
								(&sectors[secnum])->ceilingheight = lastpos;
								P_ChangeSector(secnum,crush);
								//return floor_crushed;
							}
							return floor_pastdest;
						} else {
							// COULD GET CRUSHED
							lastpos = (&sectors[secnum])->ceilingheight;
							(&sectors[secnum])->ceilingheight -= speed;
							flag = P_ChangeSector(secnum,crush);

							if (flag == true) {
								if (crush == true) {
									return floor_crushed;
								}
								sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
								(&sectors[secnum])->ceilingheight = lastpos;
								P_ChangeSector(secnum,crush);
								return floor_crushed;
							}
						}
						break;
						
					  case 1:
						// UP
						if ((&sectors[secnum])->ceilingheight + speed > dest) {
							lastpos = (&sectors[secnum])->ceilingheight;
							(&sectors[secnum])->ceilingheight = dest;
							flag = P_ChangeSector(secnum,crush);
							if (flag == true) {
								sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
								(&sectors[secnum])->ceilingheight = lastpos;
								P_ChangeSector(secnum,crush);
								//return crushed;
							}
							return floor_pastdest;
						} else {
							lastpos = (&sectors[secnum])->ceilingheight;
							(&sectors[secnum])->ceilingheight += speed;
							flag = P_ChangeSector(secnum,crush);
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
	floormove_t* floor = (floormove_t*)Z_LoadBytesFromEMS(memref);
	int16_t floorsecnum;
	int16_t floornewspecial;
	floor_e floortype;
	int16_t floordirection;
	int16_t floortexture;
	THINKERREF floorthinkerRef;
	sector_t* sectors;
    res = T_MovePlane(floor->secnum, floor->speed, floor->floordestheight, floor->crush,0,floor->direction);
	floor = (floormove_t*)Z_LoadBytesFromEMS(memref);
	floorsecnum = floor->secnum;
	if (!(leveltime & 7)) {
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		S_StartSoundWithParams(sectors[floorsecnum].soundorgX, sectors[floorsecnum].soundorgY, sfx_stnmov);
	}

    if (res == floor_pastdest) {
		floor = (floormove_t*)Z_LoadBytesFromEMS(memref);
		floornewspecial = floor->newspecial;
		floortype = floor->type;
		floordirection = floor->direction;
		floortexture = floor->texture;
		floorthinkerRef = floor->thinkerRef;

		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
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
	int16_t linetag,
	int16_t linefrontsecnum,
  floor_e	floortype )
{
    int16_t			secnum;
    int16_t			rtn;
    int16_t			i;
    //sector_t*		sec;
    floormove_t*	floor;
	MEMREF floorRef;
	int16_t* textureheight;
	int16_t specialheight;
	sector_t* sectors;
	int16_t sectorceilingheight;
	int16_t sectorfloorheight;

    secnum = -1;
    rtn = 0;
    while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0) {
		//sec = &sectors[secnum];
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

		// ALREADY MOVING?  IF SO, KEEP GOING...
		if ((&sectors[secnum])->specialdataRef)
			continue;
	
		// new floor thinker
		rtn = 1;
		floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
		(&sectors[secnum])->specialdataRef = floorRef;
		sectorceilingheight = (&sectors[secnum])->ceilingheight;
		sectorfloorheight = (&sectors[secnum])->floorheight;
		floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);

		floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);

		floor->type = floortype;
		floor->crush = false;

		switch(floortype) {
		  case lowerFloor:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight =  P_FindHighestFloorSurrounding(secnum); 
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			break;

		  case lowerFloorToLowest:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindLowestFloorSurrounding(secnum);
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;

			break;

		  case turboLower:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED * 4;
			specialheight = P_FindHighestFloorSurrounding(secnum);
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;

			if (floor->floordestheight != sectorfloorheight) {
				floor->floordestheight += 8;
			}
			break;

		  case raiseFloorCrush:
			floor->crush = true;
		  case raiseFloor:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindLowestCeilingSurrounding(secnum);
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			if (floor->floordestheight > sectorceilingheight) {
				floor->floordestheight = sectorceilingheight;
			}
			floor->floordestheight -= (8)* (floortype == raiseFloorCrush);
			break;

		  case raiseFloorTurbo:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED*4;
			specialheight =  P_FindNextHighestFloor(secnum, sectorfloorheight);
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;

			break;

		  case raiseFloorToNearest:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindNextHighestFloor(secnum, sectorfloorheight);
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			break;

		  case raiseFloor24:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			floor->floordestheight = sectors[floor->secnum].floorheight + 24;
			break;
		  case raiseFloor512:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			floor->floordestheight = sectors[floor->secnum].floorheight + 512;
			
			break;

		  case raiseFloor24AndChange:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			floor->floordestheight = sectors[floor->secnum].floorheight + 24;
			
			(&sectors[secnum])->floorpic = sectors[linefrontsecnum].floorpic;
			(&sectors[secnum])->special = sectors[linefrontsecnum].special;
			break;

		  case raiseToTexture: {
			  short_height_t minsize = MAXSHORT;
			  side_t* sides;
			  int16_t sidenum;
			  int16_t sidebottomtexture;
				
			  floor->direction = 1;
			  floor->secnum = secnum;
			  floor->speed = FLOORSPEED;
			  for (i = 0; i < (&sectors[secnum])->linecount; i++) {
				  if (twoSided (secnum, i) ) {
					  sidenum = getSideNum(secnum,i,0);
					  sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
					  sidebottomtexture = sides[sidenum].bottomtexture;
					  if (sidebottomtexture >= 0) {
						  textureheight = Z_LoadBytesFromEMS(textureheightRef);  // todo is this comparison right? used to both be 32 bit but now i converted both to 16...? whoops
						  if (textureheight[sidebottomtexture] < minsize) {
							  minsize = textureheight[sidebottomtexture];
						  }
					  }
					  sidenum = getSideNum(secnum,i,1);
					  sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
					  sidebottomtexture = sides[sidenum].bottomtexture;

					  if (sidebottomtexture >= 0) {
						  textureheight = Z_LoadBytesFromEMS(textureheightRef); // todo see above?
						  if (textureheight[sidebottomtexture] < minsize) {
							  minsize = textureheight[sidebottomtexture];
						  }
					  }
				  }
			  }
			  floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			  floor->floordestheight = sectors[floor->secnum].floorheight + minsize;
		  }
		  break;
	  
		  case lowerAndChange:{

			int16_t sidenum;
			side_t* sides;

			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindLowestFloorSurrounding(secnum);
			floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);
			floor->floordestheight = specialheight;
			floor->texture = (&sectors[secnum])->floorpic;

			for (i = 0; i < (&sectors[secnum])->linecount; i++) {
				if (twoSided(secnum, i)) {
					sidenum = getSideNum(secnum, i, 0);
					sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
					if (sides[sidenum].secnum == secnum) {
						secnum = getSector(secnum, i, 1);

						if ((&sectors[secnum])->floorheight == floor->floordestheight) {
							floor->texture = (&sectors[secnum])->floorpic;
							floor->newspecial = (&sectors[secnum])->special;
							break;
						}
					}
					else {
						secnum = getSector(secnum, i, 0);

						if ((&sectors[secnum])->floorheight == floor->floordestheight) {
							floor->texture = (&sectors[secnum])->floorpic;
							floor->newspecial = (&sectors[secnum])->special;
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
( int16_t	linetag,
  stair_e	type )
{
    int16_t			secnum;
    int16_t			height;
    uint8_t			i;
    int16_t			newsecnum;
    int16_t			texture;
    int16_t			ok;
    int16_t			rtn;
    
    //sector_t*		sec;
    int16_t		tsecOffset;

    floormove_t*	floor;
    
    int16_t		stairsize;
    int16_t		speed;
	MEMREF floorRef;
	int16_t *linebuffer;
	int16_t linebufferOffset;
	int16_t linenum;
	line_t* lines;
	sector_t*  sectors;
	int16_t sectorceilingheight;
	int16_t sectorfloorheight;
	uint8_t sectorfloorpic;
	int16_t sectorlinesoffset;
	uint8_t sectorlinecount;
    secnum = -1;
    rtn = 0;
    while ((secnum = P_FindSectorFromLineTag(linetag,secnum)) >= 0) {
	//sec = &sectors[secnum];
		
	// ALREADY MOVING?  IF SO, KEEP GOING...

		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		if ((&sectors[secnum])->specialdataRef)
			continue;
	
		// new floor thinker
		rtn = 1;
		floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
		(&sectors[secnum])->specialdataRef = floorRef;
		sectorceilingheight = (&sectors[secnum])->ceilingheight;
		sectorfloorheight = (&sectors[secnum])->floorheight;
		sectorfloorpic = (&sectors[secnum])->floorpic;
		sectorlinecount = (&sectors[secnum])->linecount;
		sectorlinesoffset = (&sectors[secnum])->linesoffset;
		floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);

		floor->thinkerRef = P_AddThinker(floorRef, TF_MOVEFLOOR);
		floor->direction = 1;
		floor->secnum = secnum;

		switch(type) {
		  case build8:
			speed = FLOORSPEED/4;
			stairsize = 8;
			break;
		  case turbo16:
			speed = FLOORSPEED*4;
			stairsize = 16;
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
				linebuffer = (int16_t*)Z_LoadBytesFromEMS(linebufferRef);
				linenum = linebuffer[linebufferOffset];
				lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
				if (!((&lines[linenum])->flags & ML_TWOSIDED)) {
					continue;
				}
				tsecOffset = (&lines[linenum])->frontsecnum;
				newsecnum = tsecOffset ;
		
				if (secnum != newsecnum)
					continue;

				tsecOffset = (&lines[linenum])->backsecnum;
				newsecnum = tsecOffset;
				sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);

				if (sectors[tsecOffset].floorpic != texture)
					continue;
					
				height += stairsize;

				if (sectors[tsecOffset].specialdataRef)
					continue;
					
				//sec = tsecOffset;
				secnum = newsecnum;

				floorRef = Z_MallocEMSNew(sizeof(*floor), PU_LEVSPEC, 0, ALLOC_TYPE_LEVSPEC);
				sectors[tsecOffset].specialdataRef = floorRef;
				floor = (floormove_t*)Z_LoadBytesFromEMS(floorRef);

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

