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
//	Archiving: SaveGame I/O.
//	Thinker, Ticker.
//

#include "z_zone.h"
#include "p_local.h"

#include "doomstat.h"
#include "i_system.h"

int	leveltime;
short currentThinkerListHead;
//
// THINKERS
// All thinkers should be allocated by Z_Malloc
// so they can be operated on uniformly.
// The actual structures will vary in size,
// but the first element must be thinker_t.
//



// Both the head and tail of the thinker list.
thinker_t	thinkerlist[MAX_THINKERS];



//
// P_InitThinkers
//
void P_InitThinkers (void)
{
	int i = 2;
	thinkerlist[0].next = 1;
	thinkerlist[0].prev = 1;

	
	for (i = 0; i < MAX_THINKERS; i++) {
		thinkerlist[i].prev = MAX_THINKERS;
	}

	currentThinkerListHead = 0;

}


THINKERREF P_GetNextThinkerRef(void) {

    short start = currentThinkerListHead;
    int i;
    
    for (i = currentThinkerListHead + 1; i != currentThinkerListHead; i++){
        if (i == MAX_THINKERS){
            i = 0;
        }
        
        if (thinkerlist[i].prev == MAX_THINKERS){
			currentThinkerListHead = i;
            return i;
        }

    }

    // error case
    printf("P_GetNextThinkerRef: Couldn't find a free index!");
    I_Error ("P_GetNextThinkerRef: Couldn't find a free index!");
    

    return -1;
    

}

//
// P_AddThinker
// Adds a new thinker at the end of the list.
//
THINKERREF P_AddThinker (MEMREF argref, THINKFUNCTION thinkfunc)
{
	// get next index
	// sets nexts, prevs
	short index = P_GetNextThinkerRef();
	
	thinkerlist[index].next = 0;
	thinkerlist[index].prev = thinkerlist[0].prev;

	thinkerlist[thinkerlist[0].prev].next = index;
	thinkerlist[0].prev = index;

    thinkerlist[index].memref = argref;
	thinkerlist[index].functionType = thinkfunc;
	
	return index;

}

void P_UpdateThinkerFunc(THINKERREF thinker, THINKFUNCTION argfunc) {
	thinkerlist[thinker].functionType = argfunc;
}


//
// P_RemoveThinker
// Deallocation is lazy -- it will not actually be freed
// until its thinking turn comes up.
//
void P_RemoveThinker (THINKERREF thinkerRef)
{
  // FIXME: NOP.
	thinkerlist[thinkerRef].functionType = TF_DELETEME;
}

 


//
// P_RunThinkers
//
void P_RunThinkers (void)
{
    THINKERREF	currentthinker;
	void* arg;
	int i = 0;
	currentthinker = thinkerlist[0].next;
    while (currentthinker != 0) {
		i++;
		if ( thinkerlist[currentthinker].functionType == TF_DELETEME ) {
			// time to remove it
			thinkerlist[thinkerlist[currentthinker].next].prev = thinkerlist[currentthinker].prev;
			thinkerlist[thinkerlist[currentthinker].prev].next = thinkerlist[currentthinker].next;
			Z_FreeEMSNew (thinkerlist[currentthinker].memref, 5);
			thinkerlist[currentthinker].prev = MAX_THINKERS;
		} else {
			if (thinkerlist[currentthinker].functionType) {
				//if (!Z_RefIsActive(blocklinksRef)) {

				//}

				switch (thinkerlist[currentthinker].functionType) {
					case TF_MOBJTHINKER:
						P_MobjThinker(thinkerlist[currentthinker].memref);
						break;
					case TF_PLATRAISE:
						T_PlatRaise(thinkerlist[currentthinker].memref);
						break;
					case TF_MOVECEILING:
						T_MoveCeiling(thinkerlist[currentthinker].memref);
						break;
					case TF_VERTICALDOOR:
						T_VerticalDoor(thinkerlist[currentthinker].memref);
						break;
					case TF_MOVEFLOOR:
						T_MoveFloor(thinkerlist[currentthinker].memref);
						break;
					case TF_FIREFLICKER:
						T_FireFlicker(thinkerlist[currentthinker].memref);
						break;
					case TF_LIGHTFLASH:
						T_LightFlash(thinkerlist[currentthinker].memref);
						break;
					case TF_STROBEFLASH:
						T_StrobeFlash(thinkerlist[currentthinker].memref);
						break;
					case TF_GLOW:
						T_Glow(thinkerlist[currentthinker].memref);
						break;
					default:
						I_Error("Bad thinker func! %i %i", currentthinker, thinkerlist[currentthinker].functionType);
						break;
				}
			}

		}
		currentthinker = thinkerlist[currentthinker].next;
    }



}



//
// P_Ticker
//

void P_Ticker (void)
{
    int		i;
    
    // run the tic
	if (paused) {
		return;
	}
    // pause if in menu and at least one tic has been run
    if ( !netgame 	 && menuactive && !demoplayback && players[consoleplayer].viewz != 1) {
		return;
    }
    

	for (i = 0; i < MAXPLAYERS; i++) {
		if (playeringame[i]) {
			P_PlayerThink(&players[i]);
		}
	}
	

	P_RunThinkers ();
	P_UpdateSpecials ();
    P_RespawnSpecials ();

	// for par times
    leveltime++;	
}
