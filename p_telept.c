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
//	Teleportation.
//



#include "doomdef.h"
#include "doomstat.h"

#include "s_sound.h"

#include "p_local.h"


// Data.
#include "sounds.h"

// State.
#include "r_state.h"

extern mobj_t* setStateReturn;

//
// TELEPORTATION
//
int16_t
EV_Teleport
(uint8_t linetag,
  int16_t		side,
	mobj_t*	thing)
{
    int16_t		i;
    mobj_t*	m;
	uint16_t	an;
    THINKERREF	thinkerRef;
	int16_t secnum;
    fixed_t	oldx;
    fixed_t	oldy;
    fixed_t	oldz;
	
	MEMREF fogRef;
    // don't teleport missiles
    if (thing->flags & MF_MISSILE)
		return 0;		

    // Don't teleport if hit back of line,
    //  so you can get out of teleporter.
    if (side == 1)		
		return 0;	

    
    
    for (i = 0; i < numsectors; i++) {

		if (sectors[ i ].tag == linetag ) {
			thinkerRef = thinkerlist[0].next;
			for (thinkerRef = thinkerlist[0].next; thinkerRef != 0; thinkerRef = thinkerlist[thinkerRef].next) {
				// not a mobj
				if ((thinkerlist[thinkerRef].prevFunctype & TF_FUNCBITS) != TF_MOBJTHINKER_HIGHBITS) {
					continue;
				}
				m = (mobj_t *)Z_LoadThinkerBytesFromEMS(thinkerlist[thinkerRef].memref);
		
				// not a teleportman
				if (m->type != MT_TELEPORTMAN )
					continue;		

				secnum = m->secnum;
				// wrong sector
				if (secnum != i )
					continue;	

				oldx = thing->x;
				oldy = thing->y;
				oldz = thing->z;
				
				if (!P_TeleportMove (thing, m->x, m->y))
					return 0;
		#if (EXE_VERSION != EXE_VERSION_FINAL)
				thing->z = thing->floorz;  //fixme: not needed?
		#endif
				if (thing->type == MT_PLAYER) {
					player.viewz = thing->z + player.viewheight;
				}
				// spawn teleport fog at source and destination
				fogRef = P_SpawnMobj (oldx, oldy, oldz, MT_TFOG);
				S_StartSoundFromRef (fogRef, sfx_telept, setStateReturn);
				an = m->angle >> ANGLETOFINESHIFT;
				fogRef = P_SpawnMobj (m->x+20*finecosine(an), m->y+20*finesine(an)
						   , thing->z, MT_TFOG);

				// emit sound, where?
				S_StartSoundFromRef(fogRef, sfx_telept, setStateReturn);
		
				// don't move for a bit
				if (thing->type == MT_PLAYER){
					playerMobj.reactiontime = 18;
				}
				thing->angle = m->angle;
				thing->momx = thing->momy = thing->momz = 0;
				return 1;
			}	
		}
    }
    return 0;
}

