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
#include "i_system.h"

#include "p_local.h"


// Data.
#include "sounds.h"

// State.
#include "r_state.h"

extern mobj_t __far* setStateReturn;

//
// TELEPORTATION
//
int16_t
EV_Teleport
(uint8_t linetag,
  int16_t		side,
	mobj_t __far*	thing,
	mobj_pos_t __far* thing_pos)
{
    int16_t		i;
    mobj_t __far*	m;
	mobj_pos_t __far* m_pos;
	uint16_t	an;
    THINKERREF	thinkerRef;
	int16_t secnum;
	fixed_t_union	oldx;
	fixed_t_union	oldy;
	fixed_t_union	oldz;
	int16_t		oldsecnum;
	THINKERREF fogRef;
    // don't teleport missiles
    if (thing_pos->flags & MF_MISSILE)
		return 0;		

    // Don't teleport if hit back of line,
    //  so you can get out of teleporter.
    if (side == 1)		
		return 0;	
    
    for (i = 0; i < numsectors; i++) {

		if (sectors_physics[ i ].tag == linetag ) {
			//I_Error("looking for thinker thinker %i %i %u", linetag, i, thinkerRef);
			thinkerRef = 0;
			while (true) {
				
				// dumb hack.. i think a compiler optimization bug is making something fuck up this loop
				// and teleporters never trigger. Some error catching code made the bug away. I wanted to
				// switch from for loop to while but the initial case and end case are the same (thinkerRef 0)
				// so i did this... whatever.

				thinkerRef = thinkerlist[thinkerRef].next;
				if (thinkerRef == 0){
					break;
				}
				// not a mobj
				if ((thinkerlist[thinkerRef].prevFunctype & TF_FUNCBITS) != TF_MOBJTHINKER_HIGHBITS) {
					continue;
				}

				m = (mobj_t  __far*)(&thinkerlist[thinkerRef].data);
		
				// not a teleportman
				if (m->type != MT_TELEPORTMAN )
					continue;		
				


				secnum = m->secnum;
				// wrong sector
				if (secnum != i )
					continue;	

				m_pos = &mobjposlist[thinkerRef];
				oldx = thing_pos->x;
				oldy = thing_pos->y;
				oldz = thing_pos->z;
				oldsecnum = thing->secnum;
				
				if (!P_TeleportMove (thing, thing_pos, m_pos->x, m_pos->y, m->secnum))
					return 0;
		#if (EXE_VERSION != EXE_VERSION_FINAL)
				thing_pos->z.w = thing->floorz;  //fixme: not needed?
		#endif
				if (thing->type == MT_PLAYER) {
					player.viewz.w = thing_pos->z.w + player.viewheight.w;
				}
				// spawn teleport fog at source and destination
				fogRef = P_SpawnMobj (oldx.w, oldy.w, oldz.w, MT_TFOG, oldsecnum);
				S_StartSoundFromRef (setStateReturn, sfx_telept);
				an = m_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
				fogRef = P_SpawnMobj (m_pos->x.w+20*finecosine[an], m_pos->y.w+20*finesine[an]
						   , thing_pos->z.w, MT_TFOG, -1);

				// emit sound, where?
				S_StartSoundFromRef(setStateReturn, sfx_telept);
		
				// don't move for a bit
				if (thing->type == MT_PLAYER){
					playerMobj->reactiontime = 18;
				}
				thing_pos->angle = m_pos->angle;
				thing->momx.w = thing->momy.w = thing->momz.w = 0;
				return 1;
			}	
		}
    }
    return 0;
}

