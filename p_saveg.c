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
//

#include "i_system.h"
#include "z_zone.h"
#include "p_local.h"

// State.
#include "doomstat.h"
#include "r_state.h"
#include "m_near.h"


// Pads save_p to a 4-byte boundary
//  so that the load/save works on SGI&Gecko.
#define PADSAVEP()	save_p += (4 - ((int32_t) save_p & 3)) & 3


 void __near dologbig(int32_t a);

//
// P_ArchivePlayers
//
void P_ArchivePlayers (void) {
		
	
	PADSAVEP();

	FAR_memcpy (save_p,&player,sizeof(player_t));
	save_p += sizeof(player_t);
	FAR_memcpy (save_p,psprites,NUMPSPRITES*sizeof(pspdef_t));
	save_p += NUMPSPRITES*sizeof(pspdef_t);
//	for (j=0 ; j<NUMPSPRITES ; j++) {
//		if (psprites[j].state) {
//			psprites[j].state  = (state_t *)(psprites[j].state-states);
//		}
//	}
	
}



//
// P_UnArchivePlayers
//
void P_UnArchivePlayers (void) {
	
	
	PADSAVEP();

	FAR_memcpy (&player,save_p, sizeof(player_t));
	save_p += sizeof(player_t);
	
	// will be set when unarc thinker
	playerMobjRef = NULL_THINKERREF;	
	player.message = -1;
	player.attackerRef = NULL_THINKERREF;

	FAR_memcpy (psprites,save_p, NUMPSPRITES*sizeof(pspdef_t));
	save_p += NUMPSPRITES*sizeof(pspdef_t);

	
}


//
// P_ArchiveWorld
//
void P_ArchiveWorld (void) {
	
    int16_t			i;
    int16_t			j;
    sector_t 		 __far*		sec;
    sector_physics_t __far*		sec_phys;

    line_t			 __far*		li;
    line_physics_t	 __far*		li_phys;


    side_t  		__far*		si;
    side_render_t  	__far*		si_rend;
    int16_t 		__far*      put = (int16_t __far*)save_p;
    
    // do sectors




    for (i=0, sec = sectors, sec_phys = sectors_physics ;  i<numsectors ; i++,sec++,sec_phys++) {
		*put++ = sec->floorheight >> SHORTFLOORBITS;
		*put++ = sec->ceilingheight >> SHORTFLOORBITS;
		*put++ = sec->floorpic;
		*put++ = sec->ceilingpic;
		*put++ = sec->lightlevel;
		*put++ = sec_phys->special;		
		*put++ = sec_phys->tag;		
    }

	

    // do lines
    for (i=0, li = lines, li_phys = lines_physics ; i<numlines ; i++,li++,li_phys++) {
		
		*put++ = lineflagslist[i]; // todo bit 9?
		*put++ = li_phys->special;
		*put++ = li_phys->tag;
		for (j=0 ; j<2 ; j++) {
			if (li->sidenum[j] == -1){
				continue;
			}
			
			si 		= &sides[li->sidenum[j]];
			si_rend = &sides_render_9000[li->sidenum[j]];
			*put++ 	= si->textureoffset;
			*put++ 	= si_rend->rowoffset;
			*put++ 	= si->toptexture;
			*put++ 	= si->bottomtexture;
			*put++ 	= si->midtexture;	
		}
    }
	
    save_p = (byte __far*)put;
	
}



//
// P_UnArchiveWorld
//
void P_UnArchiveWorld (void) {
	
    int16_t			i;
    int16_t			j;
    sector_t 			__far*		sec;
    sector_physics_t 	__far*		sec_phys;
    line_t  			__far*		li;
    line_physics_t  	__far*		li_phys;
    side_t  			__far*		si;
    side_render_t  		__far*		si_rend;
    int16_t 			__far*		get = (int16_t __far*)save_p;

    // do sectors
    for (i=0, sec = sectors, sec_phys = sectors_physics; i<numsectors ; i++,sec++,sec_phys++) {
		sec->floorheight   	= *get++ << SHORTFLOORBITS;
		sec->ceilingheight 	= *get++ << SHORTFLOORBITS;
		sec->floorpic      	= *get++;
		sec->ceilingpic    	= *get++;
		sec->lightlevel 	= *get++;
		sec_phys->special 		= *get++;		// needed?
		sec_phys->tag 			= *get++;		// needed?
		sec_phys->specialdataRef = NULL_THINKERREF;
		//sec_phys->soundtargetRef = NULL_THINKERREF;
    }
    
    // do lines
	for (i=0 ; i<numlines ; i++,li++) {
		li = &lines[i];
		li_phys = &lines_physics[i];
		lineflagslist[i] 	= *get++;  // todo bit 9?
		li_phys->special 		= *get++;
		li_phys->tag 			= *get++;
		for (j=0 ; j<2 ; j++) {
			if (li->sidenum[j] == -1){
				continue;
			}

			si 					= &sides[li->sidenum[j]];
			si_rend 			= &sides_render_9000[li->sidenum[j]];
			si->textureoffset 	= *get++;
			si_rend->rowoffset  = *get++;
			si->toptexture 		= *get++;
			si->bottomtexture 	= *get++;
			si->midtexture 		= *get++;
		}
    }
    save_p = (byte *)get;	
	
}





//
// Thinkers
//
typedef enum {
    tc_end,
    tc_mobj

} thinkerclass_t;


 void __near dolog(int16_t a);

//
// P_ArchiveThinkers
//
void P_ArchiveThinkers (void) {
	
    THINKERREF				th;
	mobj_t 		 __near*	mobj;
	mobj_pos_t   __far*		mobj_pos;
	int16_t i;
	
    // save off the current thinkers
    
    for (th = thinkerlist[0].next ; th != 0; th=thinkerlist[th].next) {
		int16_t functype = thinkerlist[th].prevFunctype & TF_FUNCBITS;
		if (functype == TF_MOBJTHINKER_HIGHBITS) {
			mobj 	 = &thinkerlist[th].data;
			mobj_pos = &mobjposlist_6800[th];

			*save_p++ = tc_mobj;
			PADSAVEP();
			FAR_memcpy (save_p, mobj, sizeof(mobj_t));
			save_p += sizeof(mobj_t);

			FAR_memcpy (save_p, mobj_pos, sizeof(mobj_pos_t));
			save_p += sizeof(mobj_pos_t);


			//mobj->state = (state_t *)(mobj->state - states);
			
			// todo what to do here
			//if (mobj->player)
				//mobj->player = mobj->player
			continue;
		}
		// todo reenable error?		
		//I_Error ("P_ArchiveThinkers: Unknown thinker function");
    }

    // add a terminating marker
    *save_p++ = tc_end;	
	
}


void  __near P_InitThinkers (void);

//
// P_UnArchiveThinkers
//
void P_UnArchiveThinkers (void) {
	
    byte				tclass;
    THINKERREF			currentthinker;
	THINKERREF			next;
	THINKERREF 			th;
	mobj_t __near* 		mobj;
	mobj_pos_t __far * 	mobj_pos;
	
    
    // remove all the current thinkers
    currentthinker = thinkerlist[0].next;
	while (currentthinker != 0) {
		next = thinkerlist[currentthinker].next;

		if (thinkerlist[currentthinker].prevFunctype & TF_FUNCBITS == TF_MOBJTHINKER_HIGHBITS) {
			P_RemoveMobj(&thinkerlist[currentthinker].data);
		} else {
			memset(&thinkerlist[currentthinker].data, 0, sizeof(mobj_t));
		}

		currentthinker = next;
    }
    P_InitThinkers ();
	

    // read in saved thinkers
    while (1) {
		tclass = *save_p++;
		switch (tclass) {
			case tc_end:
				return; 	// end of list
					
			case tc_mobj:
				PADSAVEP();
				mobj =  P_CreateThinker(TF_MOBJTHINKER_HIGHBITS);
				th = GETTHINKERREF(mobj);
				mobj_pos = &mobjposlist_6800[th];
				
				FAR_memcpy (mobj, save_p, sizeof(mobj_t));
				save_p += sizeof(mobj_t);
				FAR_memcpy (mobj_pos, save_p, sizeof(mobj_pos_t));
				save_p += sizeof(mobj_pos_t);
				
				//mobj->state = &states[(int16_t)mobj->state];
				mobj->targetRef = NULL_THINKERREF;
				
				// todo player detect
				/*
				if (mobj->player) {
					mobj->player = &players;
					mobj->player->moRef = thinkerRef;
				}
				*/
				P_SetThingPosition (mobj, mobj_pos, mobj->secnum);
				//mobj->info = &mobjinfo[mobj->type];
				mobj->floorz = sectors[mobj->secnum].floorheight;
				mobj->ceilingz = sectors[mobj->secnum].ceilingheight;

				//mobj->thinkerRef = P_AddThinker (thinkerRef, TF_MOBJTHINKER);
				break;
				
					
			default:
				I_Error ("Unknown tclass %i in savegame",tclass);
		}
	
    }
	//I_Error("here2");
	
}


//
// P_ArchiveSpecials
//


enum {
    tc_ceiling,
    tc_door,
    tc_floor,
    tc_plat,
    tc_flash,
    tc_strobe,
    tc_glow,
    tc_endspecials

} specials_e;	



//
// Things to handle:
//
// T_MoveCeiling, (ceiling_t: sector_t * swizzle), - active list
// T_VerticalDoor, (vldoor_t: sector_t * swizzle),
// T_MoveFloor, (floormove_t: sector_t * swizzle),
// T_LightFlash, (lightflash_t: sector_t * swizzle),
// T_StrobeFlash, (strobe_t: sector_t *),
// T_Glow, (glow_t: sector_t *),
// T_PlatRaise, (plat_t: sector_t *), - active list
//
void P_ArchiveSpecials (void) {
	
    THINKERREF			th;
    ceiling_t __far*	ceiling;
    vldoor_t __far*		door;
    floormove_t __far*	floor;
    plat_t __far*		plat;
    lightflash_t __far*	flash;
    strobe_t __far*		strobe;
    glow_t __far*		glow;
    int16_t			i;
	mobj_t __near*		thinkerobj;
	
    // save off the current thinkers
    for (th = thinkerlist[0].next ; th != 0 ; th=thinkerlist[th].next) {
		thinkerobj = &thinkerlist[th].data;

		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_NULL_HIGHBITS) {
			for (i = 0; i < MAXCEILINGS;i++){
				if (activeceilings[i] == th) {
					break;
				}
			}
	    
			if (i<MAXCEILINGS) {
				*save_p++ = tc_ceiling;
				PADSAVEP();
				ceiling = (ceiling_t __far*)save_p;
				FAR_memcpy (ceiling, thinkerobj, sizeof(ceiling_t));
				save_p += sizeof(ceiling_t);
				//ceiling->secnum = ceiling->secnum
			}
			continue;
		}
			
		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_MOVECEILING_HIGHBITS) {
			*save_p++ = tc_ceiling;
			PADSAVEP();
			ceiling = (ceiling_t __far*)save_p;
			FAR_memcpy (ceiling, thinkerobj, sizeof(ceiling_t));
			save_p += sizeof(ceiling_t);
			//ceiling->secnum = ceiling->secnum
			
			continue;
		}
			
		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_VERTICALDOOR_HIGHBITS) {
			*save_p++ = tc_door;
			PADSAVEP();
			door = (vldoor_t __far*)save_p;
			FAR_memcpy (door, thinkerobj, sizeof(vldoor_t));
			save_p += sizeof(vldoor_t);
			//door->secnum = door->secnum;
			continue;
		}
			
		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_MOVEFLOOR_HIGHBITS) {
			*save_p++ = tc_floor;
			PADSAVEP();
			floor = (floormove_t __far*)save_p;
			FAR_memcpy (floor, thinkerobj, sizeof(floormove_t));
			save_p += sizeof(floormove_t);
			//floor->secnum = floor->secnum;
			continue;
		}
			
		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_PLATRAISE_HIGHBITS) {
			*save_p++ = tc_plat;
			PADSAVEP();
			plat = (plat_t __far*)save_p;
			FAR_memcpy (plat, thinkerobj, sizeof(plat_t));
			save_p += sizeof(plat_t);
			//plat->secnum = plat->secnum;
			continue;
		}
			
		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_LIGHTFLASH_HIGHBITS) {
			*save_p++ = tc_flash;
			PADSAVEP();
			flash = (lightflash_t __far*)save_p;
			FAR_memcpy (flash, thinkerobj, sizeof(lightflash_t));
			save_p += sizeof(lightflash_t);
			//flash->secnum = flash->secnum;
			continue;
		}
			
		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_STROBEFLASH_HIGHBITS) {
			*save_p++ = tc_strobe;
			PADSAVEP();
			strobe = (strobe_t __far *)save_p;
			FAR_memcpy (strobe, thinkerobj, sizeof(strobe_t));
			save_p += sizeof(strobe_t);
			//strobe->secnum = strobe->secnum;
			continue;
		}
			
		if (thinkerlist[th].prevFunctype & TF_FUNCBITS == TF_GLOW_HIGHBITS) {
			*save_p++ = tc_glow;
			PADSAVEP();
			glow = (glow_t __far *)save_p;
			FAR_memcpy (glow, thinkerobj, sizeof(glow_t));
			save_p += sizeof(glow_t);
			//glow->secnum = glow->secnum;
			continue;
		}
    }
	


    // add a terminating marker
    *save_p++ = tc_endspecials;	
	
}


//
// P_UnArchiveSpecials
//
void P_UnArchiveSpecials (void) {
	
    byte					tclass;
    ceiling_t __near*		ceiling;
    vldoor_t __near*		door;
    floormove_t __near*		floor;
    plat_t __near*			plat;
    lightflash_t __near*	flash;
    strobe_t __near*		strobe;
    glow_t __near*			glow;
	THINKERREF 				thinkerRef;
	
    // read in saved thinkers
    
	while (1) {
		tclass = *save_p++;
		//function.acp1 = NULL;
		switch (tclass) {
			case tc_endspecials:
				return;	// end of list
					
			case tc_ceiling:
				PADSAVEP();

				ceiling =  P_CreateThinker(TF_MOVECEILING_HIGHBITS);
				thinkerRef = GETTHINKERREF(ceiling);

				FAR_memcpy (ceiling, save_p, sizeof(*ceiling));
				save_p += sizeof(*ceiling);
				//ceiling->sector = &sectors[(int16_t)ceiling->sector];
				//ceiling->sector->specialdataRef = thinkerRef;
				sectors_physics[ceiling->secnum].specialdataRef = thinkerRef;

				//if (ceiling->thinkerRef.function.acp1) {
				//	function.acp1 = (actionf_p1)T_MoveCeiling;
				//}
				//function.acp1 = (actionf_p1)T_MoveFloor;
				//ceiling->thinkerRef = P_AddThinker(thinkerRef, function);



				P_AddActiveCeiling(thinkerRef);
				break;
						
			case tc_door:
				PADSAVEP();

				door =  P_CreateThinker(TF_VERTICALDOOR_HIGHBITS);
				thinkerRef = GETTHINKERREF(door);


				FAR_memcpy (door, save_p, sizeof(*door));
				save_p += sizeof(*door);
				//door->sector = &sectors[(int16_t)door->sector];
				//door->sector->specialdataRef = thinkerRef;
				sectors_physics[door->secnum].specialdataRef = thinkerRef;

				//door->thinker.function.acp1 = (actionf_p1)T_VerticalDoor;
				//door->thinker.memref = thinkerRef;
				//P_AddThinker (&door->thinker);
				break;
						
			case tc_floor:
				PADSAVEP();

				floor =  P_CreateThinker(TF_MOVEFLOOR_HIGHBITS);
				thinkerRef = GETTHINKERREF(floor);


				FAR_memcpy (floor, save_p, sizeof(*floor));
				save_p += sizeof(*floor);
				//floor->sector = &sectors[(int16_t)floor->sector];
				sectors_physics[floor->secnum].specialdataRef = thinkerRef;
				//floor->thinker.function.acp1 = (actionf_p1)T_MoveFloor;
				//floor->thinker.memref = thinkerRef;
				//P_AddThinker (&floor->thinker);
				break;
						
			case tc_plat:
				PADSAVEP();

				plat =  P_CreateThinker(TF_PLATRAISE_HIGHBITS);
				thinkerRef = GETTHINKERREF(plat);


				FAR_memcpy (plat, save_p, sizeof(*plat));
				save_p += sizeof(*plat);
				//plat->sector = &sectors[(int16_t)plat->sector];
				sectors_physics[plat->secnum].specialdataRef = thinkerRef;

				//if (plat->thinker.function.acp1){
				//	plat->thinker.function.acp1 = (actionf_p1)T_PlatRaise;
				//}

				//plat->thinker.memref = thinkerRef;
				//P_AddThinker (&plat->thinker);
				P_AddActivePlat(thinkerRef);
				break;
						
			case tc_flash:
				PADSAVEP();

				flash =  P_CreateThinker(TF_LIGHTFLASH_HIGHBITS);
				thinkerRef = GETTHINKERREF(flash);


				FAR_memcpy (flash, save_p, sizeof(*flash));
				save_p += sizeof(*flash);
				//flash->sector = &sectors[(int16_t)flash->sector];
				//flash->thinker.function.acp1 = (actionf_p1)T_LightFlash;
				//flash->thinker.memref = thinkerRef;
				//P_AddThinker (&flash->thinker);
				break;
						
			case tc_strobe:
				PADSAVEP();
				
				strobe =  P_CreateThinker(TF_STROBEFLASH_HIGHBITS);
				thinkerRef = GETTHINKERREF(strobe);

				FAR_memcpy (strobe, save_p, sizeof(*strobe));
				save_p += sizeof(*strobe);
				//strobe->sector = &sectors[(int16_t)strobe->sector];
				//strobe->thinker.function.acp1 = (actionf_p1)T_StrobeFlash;
				//strobe->thinker.memref = thinkerRef;
				break;
						
			case tc_glow:
				PADSAVEP();

				glow =  P_CreateThinker(TF_GLOW);
				thinkerRef = GETTHINKERREF(glow);


				FAR_memcpy (glow, save_p, sizeof(*glow));
				save_p += sizeof(*glow);
				//glow->sector = &sectors[(int16_t)glow->sector];
				//glow->thinker.function.acp1 = (actionf_p1)T_Glow;
				//glow->thinker.memref = thinkerRef;
				//P_AddThinker (&glow->thinker);
				break;
						
			default:
				I_Error ("P_UnarchiveSpecials:Unknown tclass %i "
					"in savegame",tclass);
		}
	
    }

}

