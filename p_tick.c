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
#include "m_misc.h"
#include "p_setup.h"

fixed_t_union	leveltime;
int16_t currentThinkerListHead;
//
// THINKERS
// All thinkers should be allocated by Z_Malloc
// so they can be operated on uniformly.
// The actual structures will vary in size,
// but the first element must be thinker_t.
//



// Both the head and tail of the thinker list.
//thinker_t far*	thinkerlist; // [MAX_THINKERS];
mobj_pos_t far*	mobjposlist; // [MAX_THINKERS];



//todo merge this below as its only used there
THINKERREF P_GetNextThinkerRef(void) {
	
	int16_t i;
    
    for (i = currentThinkerListHead + 1; i != currentThinkerListHead; i++){
        if (i == MAX_THINKERS){
            i = 0;
        }
        
        if (thinkerlist[i].prevFunctype == MAX_THINKERS){
			currentThinkerListHead = i;
            return i;
        }

    }

#ifdef CHECK_FOR_ERRORS
	// error case
    I_Error ("P_GetNextThinkerRef: Couldn't find a free index!");
#endif

    return -1;
    

}

int16_t addCount = 0;
void far* P_CreateThinker(uint16_t thinkfunc) {
	int16_t index = P_GetNextThinkerRef();
	THINKERREF temp = thinkerlist[0].prevFunctype;// &0x7FF;
	thinkerlist[index].next = 0;
	thinkerlist[index].prevFunctype = temp + thinkfunc;

	thinkerlist[temp].next = index;
	thinkerlist[0].prevFunctype = index;

	addCount++;
	return &thinkerlist[index].data;

}

void P_UpdateThinkerFunc(THINKERREF thinker, uint16_t argfunc) {
	thinkerlist[thinker].prevFunctype = (thinkerlist[thinker].prevFunctype & TF_PREVBITS) + argfunc;
}

//
// P_RemoveThinker
// Deallocation is lazy -- it will not actually be freed
// until its thinking turn comes up.
// 
void P_RemoveThinker (THINKERREF thinkerRef)
{
	thinkerlist[thinkerRef].prevFunctype = (thinkerlist[thinkerRef].prevFunctype & TF_PREVBITS) + TF_DELETEME_HIGHBITS;
}

int setval = 0;
//
// P_RunThinkers
//
void P_RunThinkers (void)
{
	THINKERREF	currentthinker;
	uint16_t	currentthinkerFunc;
	int16_t i = 0;
	mobj_t far* mobj;
#ifdef DEBUGLOG_TO_FILE

	int8_t result2[100];
	int32_t lasttick = 0;
	FILE* fp;
	ticcount_t stoptic = 19818;
#endif

	currentthinker = thinkerlist[0].next;


    while (currentthinker != 0) {
		currentthinkerFunc = thinkerlist[currentthinker].prevFunctype & TF_FUNCBITS;


		if (currentthinkerFunc == TF_DELETEME_HIGHBITS ) {
			// time to remove it
			THINKERREF prevRef = thinkerlist[currentthinker].prevFunctype & TF_PREVBITS;
			THINKERREF nextRef = thinkerlist[currentthinker].next;

			thinkerlist[nextRef].prevFunctype &= TF_FUNCBITS;
			thinkerlist[nextRef].prevFunctype += prevRef;

					//thinkerlist[thinkerlist[currentthinker].next].prevFunctype & TF_FUNCBITS + 
					//prevRef;
			
			thinkerlist[prevRef].next = nextRef;;

			FAR_memset(&thinkerlist[currentthinker].data, 0, sizeof(mobj_t));
			FAR_memset(&mobjposlist[currentthinker],	  0, sizeof(mobj_pos_t));
			thinkerlist[currentthinker].prevFunctype = MAX_THINKERS;
		} else {
			mobj = &thinkerlist[currentthinker].data;
 



			if (currentthinkerFunc) {
				switch (currentthinkerFunc) {
					case TF_MOBJTHINKER_HIGHBITS:
						P_MobjThinker(mobj, &mobjposlist[currentthinker], currentthinker);
						break;
					case TF_PLATRAISE_HIGHBITS:
						T_PlatRaise((plat_t far*)mobj, currentthinker);
						break;
					case TF_MOVECEILING_HIGHBITS:
						T_MoveCeiling((ceiling_t far*)mobj, currentthinker);
						break;
					case TF_VERTICALDOOR_HIGHBITS:
						T_VerticalDoor((vldoor_t far*)mobj, currentthinker);
						break;
					case TF_MOVEFLOOR_HIGHBITS:
						T_MoveFloor((floormove_t far*)mobj, currentthinker);
						break;
					case TF_FIREFLICKER_HIGHBITS:
						T_FireFlicker((fireflicker_t far*)mobj, currentthinker);
						break;
					case TF_LIGHTFLASH_HIGHBITS:
						T_LightFlash((lightflash_t far*)mobj, currentthinker);
						break;
					case TF_STROBEFLASH_HIGHBITS:
						T_StrobeFlash((strobe_t far*)mobj, currentthinker);
						break;
					case TF_GLOW_HIGHBITS:
						T_Glow((glow_t far*)mobj, currentthinker);
						break;
 					

				}
#ifdef DEBUGLOG_TO_FILE

				if (gametic == stoptic) {
					
					if (i == 0) {
						fp = fopen("debgtick.txt", "w"); // clear old file
					} else {
						fp = fopen("debgtick.txt", "a");
					}

					fprintf(fp, "%li %hhu %i %i %hhu \n", gametic, prndindex, i, currentthinker, currentthinkerFunc);
					fclose(fp);


				}
#endif

// i will need this later to help me debug inevitible doom 2 content memleaks
/*
				if (gametic == 619 && i == 0) {
					//SAVEDUNIT = (mobj_t far*)Z_LoadThinkerBytesFromEMS(players.moRef);
					//I_Error("error %i %i %i %i %i %i %i", gametic, i, prndindex, SAVEDUNIT->x, SAVEDUNIT->y, SAVEDUNIT->momx, SAVEDUNIT->momy);
					// 454 122 157


				}
				 

				*/
 

				i++;
			}

		}
		currentthinker = thinkerlist[currentthinker].next;
    }
#ifdef DEBUGLOG_TO_FILE
	if (gametic == stoptic) {
		I_Error("done");
	}
#endif
}



//
// P_Ticker
//

void P_Ticker (void)
{
    // run the tic
	// pause if in menu and at least one tic has been run
	if (paused || (menuactive && !demoplayback && player.viewz.w != 1)) {
		return;
    }
	P_PlayerThink();

 	P_RunThinkers ();

	P_UpdateSpecials ();

	// for par times
    leveltime.w++;	
}
