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
#include "m_memory.h"
#include "m_near.h"

//
// THINKERS
// All thinkers should be allocated by Z_Malloc
// so they can be operated on uniformly.
// The actual structures will vary in size,
// but the first element must be thinker_t.
//






//todo merge this below as its only used there
THINKERREF __near P_GetNextThinkerRef(void) {
	
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

void __near* __near P_CreateThinker(uint16_t thinkfunc) {
	int16_t index = P_GetNextThinkerRef();
	THINKERREF temp = thinkerlist[0].prevFunctype;// &0x7FF;
	thinkerlist[index].next = 0;
	thinkerlist[index].prevFunctype = temp + thinkfunc;

	thinkerlist[temp].next = index;
	thinkerlist[0].prevFunctype = index;

	return &thinkerlist[index].data;

}

void __near P_UpdateThinkerFunc(THINKERREF thinker, uint16_t argfunc) {
	thinkerlist[thinker].prevFunctype = (thinkerlist[thinker].prevFunctype & TF_PREVBITS) + argfunc;
}

//
// P_RemoveThinker
// Deallocation is lazy -- it will not actually be freed
// until its thinking turn comes up.
// 
void __near P_RemoveThinker (THINKERREF thinkerRef) {
	thinkerlist[thinkerRef].prevFunctype = (thinkerlist[thinkerRef].prevFunctype & TF_PREVBITS) + TF_DELETEME_HIGHBITS;
}
//
// P_RunThinkers
//
void __near P_RunThinkers (void) {
	THINKERREF	currentthinker;
	uint16_t	currentthinkerFunc;
	int16_t i = 0;
	mobj_t __near* mobj;
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

			memset(&thinkerlist[currentthinker].data, 0, sizeof(mobj_t));
			FAR_memset(&mobjposlist_6800[currentthinker],	  0, sizeof(mobj_pos_t));
			thinkerlist[currentthinker].prevFunctype = MAX_THINKERS;
		} else {
			mobj = &thinkerlist[currentthinker].data;
 



			if (currentthinkerFunc) {
				switch (currentthinkerFunc) {
					case TF_MOBJTHINKER_HIGHBITS:
						P_MobjThinker(mobj, &mobjposlist_6800[currentthinker], currentthinker);
						break;
					case TF_PLATRAISE_HIGHBITS:
						T_PlatRaise((plat_t __near*)mobj, currentthinker);
						break;
					case TF_MOVECEILING_HIGHBITS:
						T_MoveCeiling((ceiling_t __near*)mobj, currentthinker);
						break;
					case TF_VERTICALDOOR_HIGHBITS:
						T_VerticalDoor((vldoor_t __near*)mobj, currentthinker);
						break;
					case TF_MOVEFLOOR_HIGHBITS:
						T_MoveFloor((floormove_t __near*)mobj, currentthinker);
						break;
					case TF_FIREFLICKER_HIGHBITS:
						T_FireFlicker((fireflicker_t __near*)mobj, currentthinker);
						break;
					case TF_LIGHTFLASH_HIGHBITS:
						T_LightFlash((lightflash_t __near*)mobj, currentthinker);
						break;
					case TF_STROBEFLASH_HIGHBITS:
						T_StrobeFlash((strobe_t __near*)mobj, currentthinker);
						break;
					case TF_GLOW_HIGHBITS:
						T_Glow((glow_t __near*)mobj, currentthinker);
						break;
 					

				}
#ifdef DEBUGLOG_TO_FILE

				if (gametic == stoptic) {
					
					if (i == 0) {
						fp = fopen("debgtick.txt", "w"); // clear old file
					} else {
						fp = fopen("debgtick.txt", "a");
					}

					fprintf(fp, "%li %i %i %i %li \n", gametic, prndindex, i, currentthinker, currentthinkerFunc);
					fclose(fp);


				}
#endif

// i will need this later to help me debug inevitible doom 2 content memleaks
/*
				if (gametic == 619 && i == 0) {
					//SAVEDUNIT = (mobj_t __near*)Z_LoadThinkerBytesFromEMS(players.moRef);
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
void __far P_Ticker (void) {
    // run the tic
	// pause if in menu and at least one tic has been run
	if (paused || (menuactive && !demoplayback && player.viewzvalue.w != 1)) {
		return;
    }
	P_PlayerThink();

	//filelog();

 	P_RunThinkers ();

	P_UpdateSpecials ();

/*
	if (gametic > 15 && !setonce){
		setonce = 1;

		playerMobj_pos->x.w = 		0xfcc37e8d;
		playerMobj_pos->y.w = 		0xf63a120b;
		playerMobj_pos->z.w = 		0x00000000;
		playerMobj_pos->angle.w = 	0x2f400000;

//		playerMobj_pos->x.w = 		0xfc40b6e6;
//		playerMobj_pos->y.w = 		0xf865f975;
//		playerMobj_pos->z.w = 		0x00000000;
//		playerMobj_pos->angle.w = 	0xee400000;

	}
/*

*/

	// for par times
    leveltime.w++;	
}
