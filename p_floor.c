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
#include "m_memory.h"
#include "m_near.h"


//
// FLOORS
//

//
// Move a plane (floor or ceiling) and check for crushing
//
result_e __near T_MovePlane ( sector_t __far*	sector, short_height_t	speed, short_height_t	dest, boolean	crush, int16_t		floorOrCeiling, int16_t		direction ) {
    boolean	somethingcrushed; // plane will possibly move less
    short_height_t	lastpos;
#ifdef		PRECALCULATE_OPENINGS
	int16_t secnum = sector - sectors;
#endif

		switch(floorOrCeiling) {
			case 0:
				// FLOOR
				switch(direction) {
					case -1:
						// DOWN


						if (sector->floorheight - speed < dest) {
							lastpos = sector->floorheight;
							sector->floorheight = dest;
#ifdef		PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, true);
#endif

							somethingcrushed = P_ChangeSector(sector,crush);


							if (somethingcrushed) {
								sector->floorheight = lastpos;
#ifdef		PRECALCULATE_OPENINGS
								P_UpdateLineOpening(secnum, true);
#endif

								P_ChangeSector(sector,crush);
								//return floor_crushed;
							}

							return floor_pastdest;
						} else {
							lastpos = sector->floorheight;
							sector->floorheight -= speed;
#ifdef		PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, true);
#endif

							somethingcrushed = P_ChangeSector(sector,crush);

							if (somethingcrushed) {
								sector->floorheight = lastpos;
#ifdef		PRECALCULATE_OPENINGS
								P_UpdateLineOpening(secnum, true);
#endif

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
#ifdef		PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, true);
#endif
							somethingcrushed = P_ChangeSector(sector,crush);
							if (somethingcrushed) {
								sector->floorheight = lastpos;
#ifdef		PRECALCULATE_OPENINGS
								P_UpdateLineOpening(secnum, true);
#endif

								P_ChangeSector(sector,crush);
								//return floor_crushed;
							}
							return floor_pastdest;
						} else {
							// COULD GET CRUSHED
							lastpos = sector->floorheight;
							sector->floorheight += speed;
#ifdef		PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, true);
#endif
							somethingcrushed = P_ChangeSector(sector,crush);
							if (somethingcrushed) {
								if (crush == true) {
									return floor_crushed;
								}
								sector->floorheight = lastpos;
#ifdef		PRECALCULATE_OPENINGS
								P_UpdateLineOpening(secnum, true);
#endif
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
#ifdef		PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, false);
#endif
							somethingcrushed = P_ChangeSector(sector,crush);

							if (somethingcrushed) {
								sector->ceilingheight = lastpos;
#ifdef		PRECALCULATE_OPENINGS
								P_UpdateLineOpening(secnum, false);
#endif
								P_ChangeSector(sector,crush);
								//return floor_crushed;
							}
							return floor_pastdest;
						} else {
							// COULD GET CRUSHED
							lastpos = sector->ceilingheight;
							sector->ceilingheight -= speed;
#ifdef		PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, false);
#endif
							somethingcrushed = P_ChangeSector(sector,crush);

							if (somethingcrushed) {
								if (crush == true) {
									return floor_crushed;
								}
								sector->ceilingheight = lastpos;
#ifdef		PRECALCULATE_OPENINGS
								P_UpdateLineOpening(secnum, false);
#endif
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
#ifdef		PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, false);
#endif
							somethingcrushed = P_ChangeSector(sector,crush);
							if (somethingcrushed) {
								sector->ceilingheight = lastpos;
#ifdef		PRECALCULATE_OPENINGS
								P_UpdateLineOpening(secnum, false);
#endif
								P_ChangeSector(sector,crush);
								//return crushed;
							}
							return floor_pastdest;
						} else {
							lastpos = sector->ceilingheight;
							sector->ceilingheight += speed;
#ifdef	PRECALCULATE_OPENINGS
							P_UpdateLineOpening(secnum, false);
#endif
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
void __near T_MoveFloor(floormove_t __near* floor, THINKERREF floorRef) {
    result_e	res;
	int16_t floorsecnum = floor->secnum;

	sector_t __far* floorsector = &sectors[floorsecnum];
	uint8_t floornewspecial;
	floor_e floortype;
	int16_t floordirection;
	uint8_t floortexture;
    res = T_MovePlane(floorsector, floor->speed, floor->floordestheight, floor->crush,0,floor->direction);
	if (!(leveltime.h.fracbits & 7)) {
		S_StartSoundWithParams(floorsecnum, sfx_stnmov);
	}

    if (res == floor_pastdest) {
		floornewspecial = floor->newspecial;
		floortype = floor->type;
		floordirection = floor->direction;
		floortexture = floor->texture;

		sectors_physics[floorsecnum].specialdataRef = NULL_THINKERREF;

		if (floordirection == 1) {
			switch(floortype) {
			  case donutRaise:
				  (&sectors_physics[floorsecnum])->special = floornewspecial;
				  (&sectors[floorsecnum])->floorpic = floortexture;
			  default:
			break;
			}
		} else if (floordirection == -1) {
			switch(floortype) {
			  case lowerAndChange:
				  (&sectors_physics[floorsecnum])->special = floornewspecial;
				  (&sectors[floorsecnum])->floorpic = floortexture;
			  default:
			break;
			}
		}
		P_RemoveThinker(floorRef);

		S_StartSoundWithParams(floorsecnum, sfx_pstop);
    }

}

//
// HANDLE FLOOR TYPES
//
int16_t __near EV_DoFloor ( uint8_t linetag,int16_t linefrontsecnum,floor_e	floortype ){
    int16_t			secnum = -1;
    int16_t			rtn = 0;
    int16_t			i;
	int16_t		j = 0;
    floormove_t __near*	floor;
	THINKERREF floorRef;
	int16_t specialheight;
	sector_t __far* sector;
	sector_physics_t __near* sector_physics;

	int16_t sectorceilingheight;
	int16_t sectorfloorheight;
	int16_t secnumlist[MAX_ADJOINING_SECTORS];
	int16_t seclinesoffset;

	P_FindSectorsFromLineTag(linetag, secnumlist, false);
	while (secnumlist[j] >= 0) {
		//sec = &sectors[secnum];

		secnum = secnumlist[j];
		sector = &sectors[secnum];
		sector_physics = &sectors_physics[secnum];
		seclinesoffset = sector->linesoffset;
		j++;

		// new floor thinker
		rtn = 1;
		sectorceilingheight = sector->ceilingheight;
		sectorfloorheight = sector->floorheight;


		floor = (floormove_t __near*)P_CreateThinker(TF_MOVEFLOOR_HIGHBITS);
		floorRef = GETTHINKERREF(floor);
		sector_physics->specialdataRef = floorRef;


		floor->type = floortype;
		floor->crush = false;

		switch(floortype) {
		  case lowerFloor:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight =  P_FindHighestOrLowestFloorSurrounding(secnum, true); 
			floor->floordestheight = specialheight;
			break;

		  case lowerFloorToLowest:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindHighestOrLowestFloorSurrounding(secnum, false);
			floor->floordestheight = specialheight;

			break;

		  case turboLower:
			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED * 4;
			specialheight = P_FindHighestOrLowestFloorSurrounding(secnum, true);
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
			specialheight = P_FindLowestOrHighestCeilingSurrounding(secnum, false);
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
			floor->floordestheight = specialheight;

			break;

		  case raiseFloorToNearest:
			floor->direction = 1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindNextHighestFloor(secnum, sectorfloorheight);
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
			sector_physics->special = sectors_physics[linefrontsecnum].special;
			break;

		  case raiseToTexture: {
			  short_height_t minsize = MAXSHORT;
			  int16_t sidenum0, sidenum1;
			  uint16_t sidebottomtexture;
			  line_t __far * line;

			  floor->direction = 1;
			  floor->secnum = secnum;
			  floor->speed = FLOORSPEED;
			  for (i = 0; i < sector->linecount; i++) {
				  if (twoSided (secnum, i) ) {
					  line = &lines[linebuffer[seclinesoffset + i]];
					  sidenum0 = line->sidenum[0];
					  sidenum1 = line->sidenum[1];

					  sidebottomtexture = sides[sidenum0].bottomtexture;
					  //if (sidebottomtexture >= 0) {
						  if ((textureheights[sidebottomtexture]+1) < minsize) {
							  minsize = textureheights[sidebottomtexture]+1;
						  }
					  //}

					  sidebottomtexture = sides[sidenum1].bottomtexture;

					  //if (sidebottomtexture >= 0) {
						  if ((textureheights[sidebottomtexture]+1) < minsize) {
							  minsize = textureheights[sidebottomtexture]+1;
						  }
					  //}
				  }
			  }
			  floor->floordestheight = sectors[floor->secnum].floorheight + (minsize << SHORTFLOORBITS);
		  }
		  break;
	  
		  case lowerAndChange:{

			  //int16_t sidenum;
			  line_t __far* sideline;
			  line_physics_t __far* sideline_physics;

			floor->direction = -1;
			floor->secnum = secnum;
			floor->speed = FLOORSPEED;
			specialheight = P_FindHighestOrLowestFloorSurrounding(secnum, false);
			floor->floordestheight = specialheight;
			floor->texture = sector->floorpic;

			for (i = 0; i < sector->linecount; i++) {
				if (twoSided(secnum, i)) {
					//sidenum = (secnum, i, 0);
					sideline = &lines[linebuffer[seclinesoffset + i]];
					sideline_physics = &lines_physics[linebuffer[seclinesoffset + i]];
					if (sideline_physics->frontsecnum == secnum) {
						secnum = sideline->sidenum[1];

						if (sector->floorheight == floor->floordestheight) {
							floor->texture = sector->floorpic;
							floor->newspecial = sector_physics->special;
							break;
						}
					}
					else {
						secnum = sideline->sidenum[0];

						if (sector->floorheight == floor->floordestheight) {
							floor->texture = sector->floorpic;
							floor->newspecial = sector_physics->special;
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
int16_t __near EV_BuildStairs ( uint8_t	linetag,stair_e	type ) {
    int16_t			secnum = -1;
    short_height_t	height;
    uint8_t			i;
    int16_t			ok;
	int16_t			rtn = 0;
    
    int16_t		tsecOffset;

    floormove_t __near*	floor;
    
    int16_t		stairsize;
    int16_t		speed;
	THINKERREF floorRef;
	int16_t linebufferOffset;
	int16_t linenum;
	short_height_t sectorfloorheight;
	uint8_t sectorfloorpic;
	int16_t sectorlinesoffset;
	int16_t sectorlinecount;
	int16_t secnumlist[MAX_ADJOINING_SECTORS];
	int16_t		j = 0;
	sector_t __far* sector;
	
	P_FindSectorsFromLineTag(linetag, secnumlist, false);
	while (secnumlist[j] >= 0) {
		//sec = &sectors[secnum];
		
	// ALREADY MOVING?  IF SO, KEEP GOING...

		secnum = secnumlist[j];
		j++;
		sector = &sectors[secnum];
		// new floor thinker
		rtn = 1;
		sectorfloorheight = sector->floorheight;
		sectorfloorpic = sector->floorpic;
		sectorlinecount = sector->linecount;
		sectorlinesoffset = sector->linesoffset;

		floor = (floormove_t __near*)P_CreateThinker(TF_MOVEFLOOR_HIGHBITS);
		floorRef = GETTHINKERREF(floor);		
		floor->direction = 1;
		floor->secnum = secnum;
		sectors_physics[secnum].specialdataRef = floorRef;

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
		
	
		// Find next sector to raise
		// 1.	Find 2-sided line with same sector side[0]
		// 2.	Other side is the next sector to raise
		do {
			ok = 0;
			sector = &sectors[secnum];
			sectorfloorpic = sector->floorpic;
			sectorlinecount = sector->linecount;
			sectorlinesoffset = sector->linesoffset;

			for (i = 0;i < sectorlinecount;i++) {
				linebufferOffset = sectorlinesoffset + i;
				linenum = linebuffer[linebufferOffset];
				if (!(lineflagslist[linenum] & ML_TWOSIDED)) {
					continue;
				}
				tsecOffset = lines_physics[linenum].frontsecnum;
		
				if (secnum != tsecOffset)
					continue;

				tsecOffset = lines_physics[linenum].backsecnum;

				if (sectors[tsecOffset].floorpic != sectorfloorpic)
					continue;
					
				height += stairsize;

				if (sectors_physics[tsecOffset].specialdataRef)
					continue;
					
				//sec = tsecOffset;
				secnum = tsecOffset;


				floor = (floormove_t __near*)P_CreateThinker(TF_MOVEFLOOR_HIGHBITS);
				floorRef = GETTHINKERREF(floor);		

				floor->floordestheight = height;
				floor->direction = 1;
				floor->secnum = tsecOffset;
				floor->speed = speed;
				floor->floordestheight = height;
				sectors_physics[tsecOffset].specialdataRef = floorRef;
				ok = 1;
				break;
			}
		} while(ok);
	    }
    return rtn;
}

