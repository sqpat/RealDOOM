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


// vanilla doom defs for comparison:


typedef struct
{
    int32_t		state;	// ptr instead of int16_t
    int32_t		tics;   // instead of int16_t
    fixed_t	sx;
    fixed_t	sy;

} pspdef_vanilla_t;


#define MAXPLAYERS_VANILLA 4

typedef struct 
{
    int32_t				mo;
    int32_t 			playerstate;
    ticcmd_t			cmd;				// same byte structure as vanilla
    fixed_t				viewzvalue;
    fixed_t				viewheightvalue;
    fixed_t         	deltaviewheight;
    fixed_t         	bob;	
    int32_t				health;	
    int32_t				armorpoints;
    int32_t				armortype;	
    int32_t				powers[NUMPOWERS];
    int32_t				cards[NUMCARDS];
    int32_t				backpack;
    int32_t				frags[MAXPLAYERS_VANILLA];
    int32_t				readyweapon;
    int32_t				pendingweapon;
    int32_t				weaponowned[NUMWEAPONS];
    int32_t				ammo[NUMAMMO];
    int32_t				maxammo[NUMAMMO];
    int32_t				attackdown;
    int32_t				usedown;
    int32_t				cheats;		
    int32_t				refire;		
    int32_t				killcount;
    int32_t				itemcount;
    int32_t				secretcount;
    int32_t				message;	
    int32_t				damagecount;
    int32_t				bonuscount;
    int32_t				attacker;
    int32_t				extralightvalue;
    int32_t				fixedcolormapvalue;
    int32_t				colormap;	
    pspdef_vanilla_t	psprites_field[NUMPSPRITES];
    int32_t				didsecret;	

} player_vanilla_t;


typedef struct thinker_vanilla_s
{
    int32_t	prev;
	int32_t	next;
    int32_t	function;
    
} thinker_vanilla_t;


// Map Object definition.
typedef struct  {

    thinker_vanilla_t	thinker;
    fixed_t				x;
    fixed_t				y;
    fixed_t				z;
    int32_t				snext;
    int32_t				sprev;
    angle_t				angle;	// orientation
    int32_t				sprite;	// used to find patch_t and flip value
    int32_t				frame;	// might be ORed with FF_FULLBRIGHT
    int32_t				bnext;
    int32_t				bprev;
    int32_t				subsector;
    fixed_t				floorz;
    fixed_t				ceilingz;
    fixed_t				radius;
    fixed_t				height;	
    fixed_t				momx;
    fixed_t				momy;
    fixed_t				momz;
    int32_t				validcount;
    int32_t				type;
    int32_t				info;	// &mobjinfo[mobj->type]
    int32_t				tics;	// state tic counter
    int32_t				state;
    int32_t				flags;
    int32_t				health;
    int32_t				movedir;	// 0-7
    int32_t				movecount;	// when 0, select a new dir
    int32_t				target;
    int32_t				reactiontime;   
    int32_t				threshold;
    int32_t				player;
    int32_t				lastlook;	
    mapthing_t			spawnpoint;	
    int32_t				tracer;	
    
} mobj_vanilla_t;



typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				type;
    int32_t				sector;
    fixed_t				bottomheight;
    fixed_t				topheight;
    fixed_t				speed;
    int32_t				crush;
    int32_t				direction;
    int32_t				tag;                   
    int32_t				olddirection;
    
} ceiling_vanilla_t;

typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				type;
    int32_t				sector;
    fixed_t				topheight;
    fixed_t				speed;
    int32_t             direction;
    int32_t             topwait;
    int32_t             topcountdown;
    
} vldoor_vanilla_t;

typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				type;
    int32_t				crush;
    int32_t				sector;
    int32_t				direction;
    int32_t				newspecial;
    int16_t				texture;
    fixed_t				floordestheight;
    fixed_t				speed;

} floormove_vanilla_t;

typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    fixed_t				speed;
    fixed_t				low;
    fixed_t				high;
    int32_t				wait;
    int32_t				count;
    int32_t				status;
    int32_t				oldstatus;
    int32_t				crush;
    int32_t				tag;
    int32_t				type;
    
} plat_vanilla_t;



typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    int32_t				count;
    int32_t				maxlight;
    int32_t				minlight;
    int32_t				maxtime;
    int32_t				mintime;
    
} lightflash_vanilla_t;



typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    int32_t				count;
    int32_t				minlight;
    int32_t				maxlight;
    int32_t				darktime;
    int32_t				brighttime;
    
} strobe_vanilla_t;




typedef struct
{
    thinker_vanilla_t	thinker;
    int32_t				sector;
    int32_t				minlight;
    int32_t				maxlight;
    int32_t				direction;

} glow_vanilla_t;


// Pads save_p to a 4-byte boundary
//  so that the load/save works on SGI&Gecko.
#define PADSAVEP()	save_p += (4 - ((int32_t) save_p & 3)) & 3



//
// P_ArchivePlayers
//
void __far P_ArchivePlayers (void) {
	player_vanilla_t __far * saveplayer;
	int16_t i;
	PADSAVEP();

	saveplayer = (player_vanilla_t __far *) save_p;
	FAR_memset (saveplayer,0,sizeof(player_vanilla_t));
	saveplayer->playerstate 		= player.playerstate;
	saveplayer->cmd			 		= player.cmd;
    saveplayer->viewzvalue			= player.viewzvalue.w;
    saveplayer->viewheightvalue		= player.viewheightvalue.w;
    saveplayer->deltaviewheight		= player.deltaviewheight.w;
    saveplayer->bob					= player.bob.w;
    saveplayer->health				= player.health;	
    saveplayer->armorpoints			= player.armorpoints;
    saveplayer->armortype			= player.armortype;
    saveplayer->backpack			= player.backpack;
    saveplayer->readyweapon			= player.readyweapon;
    saveplayer->pendingweapon		= player.pendingweapon;
    saveplayer->attackdown			= player.attackdown;
    saveplayer->usedown				= player.usedown;
    saveplayer->cheats				= player.cheats;
    saveplayer->refire				= player.refire;
    saveplayer->killcount			= player.killcount;
    saveplayer->itemcount			= player.itemcount;
    saveplayer->secretcount			= player.secretcount;
    //saveplayer->message				= player.message;
    saveplayer->damagecount			= player.damagecount;
    saveplayer->bonuscount			= player.bonuscount;
    //saveplayer->attacker			= player.viewzvalue;
    saveplayer->extralightvalue		= player.extralightvalue;
    saveplayer->fixedcolormapvalue  = player.fixedcolormapvalue;
    saveplayer->colormap			= player.colormap;
    saveplayer->didsecret			= player.didsecret;

	for (i = 0; i < NUMPOWERS; i++){
	    saveplayer->powers[i]			= player.powers[i];
	}

	for (i = 0; i < NUMCARDS; i++){
	    saveplayer->cards[i]			= player.cards[i];
	}

	for (i = 0; i < MAXPLAYERS_VANILLA; i++){
	    saveplayer->frags[i]			= 0; //player.frags[i];
	}

	for (i = 0; i < NUMAMMO; i++){
		saveplayer->ammo[i]				= player.ammo[i];
		saveplayer->maxammo[i]			= player.maxammo[i];
	}

	for (i = 0; i < NUMWEAPONS; i++){
	    saveplayer->weaponowned[i]		= player.weaponowned[i];
	}

	for (i = 0; i < NUMPSPRITES; i++){
	    if (psprites[i].statenum == STATENUM_NULL){
			saveplayer->psprites_field[i].state	= 0;
		} else {
			saveplayer->psprites_field[i].state	= psprites[i].statenum;
		}

	    saveplayer->psprites_field[i].tics	= psprites[i].tics;
	    saveplayer->psprites_field[i].sx	= psprites[i].sx;
	    saveplayer->psprites_field[i].sy	= psprites[i].sy;
	}


	save_p += sizeof(player_vanilla_t);

	
}



//
// P_UnArchivePlayers
//
/*
void __far P_UnArchivePlayers (void) {
	player_vanilla_t __far * saveplayer;
	int16_t i;

	
	PADSAVEP();
	saveplayer = (player_vanilla_t __far *) save_p;

	player.playerstate 				= saveplayer->playerstate;
	player.cmd			 			= saveplayer->cmd;
    player.viewzvalue.w				= saveplayer->viewzvalue;
    player.viewheightvalue.w		= saveplayer->viewheightvalue;
    player.deltaviewheight.w		= saveplayer->deltaviewheight;
    player.bob.w					= saveplayer->bob;
    player.health					= saveplayer->health;	
    player.armorpoints				= saveplayer->armorpoints;
    player.armortype				= saveplayer->armortype;
    player.backpack					= saveplayer->backpack;
    player.readyweapon				= saveplayer->readyweapon;
    player.pendingweapon			= saveplayer->pendingweapon; 
    player.attackdown				= saveplayer->attackdown;
    player.usedown					= saveplayer->usedown;
    player.cheats					= saveplayer->cheats;
    player.refire					= saveplayer->refire;
    player.killcount				= saveplayer->killcount;
    player.itemcount				= saveplayer->itemcount;
    player.secretcount				= saveplayer->secretcount;
    //player.message				= saveplayer->message;
    player.damagecount				= saveplayer->damagecount;
    player.bonuscount				= saveplayer->bonuscount;
    //player.viewzvalue				= saveplayer->attacker;
    player.extralightvalue			= saveplayer->extralightvalue;
    player.fixedcolormapvalue 		= saveplayer->fixedcolormapvalue;
    player.colormap					= saveplayer->colormap;
    player.didsecret				= saveplayer->didsecret;

	for (i = 0; i < NUMPOWERS; i++){
	    player.powers[i]			= saveplayer->powers[i];
	}

	for (i = 0; i < NUMCARDS; i++){
	    player.cards[i]				= saveplayer->cards[i];
	}

	// UNUSED
//	for (i = 0; i < MAXPLAYERS_VANILLA; i++){
//		player.frags[i]			= saveplayer->frags[i]; //player.frags[i];
//	}

	for (i = 0; i < NUMAMMO; i++){
		player.ammo[i]				= saveplayer->ammo[i];
		player.maxammo[i]			= saveplayer->maxammo[i];
	}

	for (i = 0; i < NUMWEAPONS; i++){
	    player.weaponowned[i]		= saveplayer->weaponowned[i];
	}

	for (i = 0; i < NUMPSPRITES; i++){
	    psprites[i].statenum		= saveplayer->psprites_field[i].state;
		if (psprites[i].statenum == 0){
			psprites[i].statenum = STATENUM_NULL;
		}
	    psprites[i].tics			= saveplayer->psprites_field[i].tics;
	    psprites[i].sx				= saveplayer->psprites_field[i].sx;
	    psprites[i].sy				= saveplayer->psprites_field[i].sy;
	}




	// will be set when unarchive thinkers
	playerMobjRef = NULL_THINKERREF;	
	player.message = -1;
	player.attackerRef = NULL_THINKERREF;

	
	save_p += sizeof(player_vanilla_t);

	
}
*/

//
// P_ArchiveWorld
//
void __far P_ArchiveWorld (void) {
	
    int16_t			i;
    int16_t			j;
    sector_t 		 __far*		sec;
    sector_physics_t __near*		sec_phys;

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
		
		// vanilla line flags:
		// #define ML_BLOCKING		1
		// #define ML_BLOCKMONSTERS	2
		// #define ML_TWOSIDED		4
		// #define ML_DONTPEGTOP		8
		// #define ML_DONTPEGBOTTOM	16	
		// #define ML_SECRET		32
		// #define ML_SOUNDBLOCK		64
		// #define ML_DONTDRAW		128
		// #define ML_MAPPED		256
		int16_t flags = lineflagslist[i];
		// make this bit 9
		if ((seenlines_6800[i/8] & (0x01 << (i % 8)))){
			flags |= 0x100;
		}
		*put++ = flags;
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
void __far P_UnArchiveWorld (void) {
	
    int16_t			i;
    int16_t			j;
    sector_t 			__far*		sec;
    sector_physics_t 	__near*		sec_phys;
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
		sec->thinglistRef   = NULL_THINKERREF;  // erase this. garbage value from p_setup, we will fix it later unarchivng mobj pos
		sec_phys->special 		= *get++;		// needed?
		sec_phys->tag 			= *get++;		// needed?
		sec_phys->specialdataRef = NULL_THINKERREF;
		//sec_phys->soundtargetRef = NULL_THINKERREF;
    }
    
    // do lines
	for (i=0 ; i<numlines ; i++,li++) {
		int16_t flags 			= *get++;
		uint8_t flags8bit       = (flags & 0xFF);
		uint8_t mapped 			= (flags & 0x0100) >> (8-(i % 8));

		li 						= &lines[i];
		li_phys 				= &lines_physics[i];
		lineflagslist[i] 	    = flags8bit;
		seenlines_6800[i/8] 	|= mapped;
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
    save_p = (byte __far *)get;	
	
}





//
// Thinkers
//
typedef enum {
    tc_end,
    tc_mobj

} thinkerclass_t;


 
//
// P_ArchiveThinkers
//
void __far P_ArchiveThinkers (void) {
	
    THINKERREF				th;
	mobj_t 		 __near*	mobj;
	mobj_pos_t   __far*		mobj_pos;
	mobj_vanilla_t __far *  savemobj;
	int16_t i;
	
    // save off the current thinkers
    
    for (th = thinkerlist[0].next ; th != 0; th=thinkerlist[th].next) {
		int16_t functype = thinkerlist[th].prevFunctype & TF_FUNCBITS;
		if (functype == TF_MOBJTHINKER_HIGHBITS) {
			fixed_t_union flags;
			int32_t scratch;
			mobj 	 = &thinkerlist[th].data;
			mobj_pos = &mobjposlist_6800[th];

			*save_p++ = tc_mobj;
			PADSAVEP();
			savemobj = (mobj_vanilla_t __far *) save_p;
			FAR_memset(savemobj, 0, sizeof(mobj_vanilla_t));

			//savemobj->thinker			= th;				// should recalculate in AddThinker/CreateThinker
			savemobj->x 				= mobj_pos->x.w;
			savemobj->y 				= mobj_pos->y.w;
			savemobj->z 				= mobj_pos->z.w;
			// savemobj->snext 			= mobj_pos-> //	? should recalculate in setposition
			// savemobj->sprev 			= mobj_pos-> //	? should recalculate in setposition
			savemobj->angle 			= mobj_pos->angle;
			savemobj->state 			= mobj_pos->stateNum;
			flags.h.intbits 			= mobj_pos->flags2;
			flags.h.fracbits 			= mobj_pos->flags1;
			savemobj->flags 			= flags.w;

			
			savemobj->sprite 			= states[mobj_pos->stateNum].sprite;
			savemobj->frame 			= states[mobj_pos->stateNum].frame;
			if (savemobj->frame & FF_FULLBRIGHT){
				savemobj->frame &= FF_FRAMEMASK; // get rid of fullbright
				savemobj->frame |= 0x8000;       // add vanilla FULLBRIGHT mask
			}
			// savemobj->bnext 			= mobj->	// dont store? should recalculate in setposition
			// savemobj->bprev 			= mobj->	// dont store? should recalculate in setposition
			// savemobj->subsector 		= mobj->	// dont store? should recalculate in setposition
			// scratch = mobj->floorz;
			// scratch <<= (16-SHORTFLOORBITS);
			// savemobj->floorz 			= scratch;	// dont store? recalc from sector on deserialize
			// scratch = mobj->ceilingz;
			// scratch <<= (16-SHORTFLOORBITS);
			// savemobj->ceilingz 			= scratch;	// dont store? recalc from sector on deserialize
			scratch = mobj->radius;
			scratch <<= FRACBITS;
			savemobj->radius 			= scratch;
			savemobj->height 			= mobj->height.w;
			savemobj->momx 				= mobj->momx.w;
			savemobj->momy 				= mobj->momy.w;
			savemobj->momz 				= mobj->momz.w;
			//savemobj->validcount 		= mobj->validcount;   TODO: seems unused in vanilla?
			savemobj->type 				= mobj->type;
			// savemobj->info 				= mobj->info;		recalculated from type during deserialize
			savemobj->tics				= mobj->tics;
			if (mobj->tics == 0xFF){
				savemobj->tics = -1;
			}
			savemobj->health 			= mobj->health;
			savemobj->movedir 			= mobj->movedir;
			savemobj->movecount 		= mobj->movecount;
			// savemobj->target 			= mobj->	unused/nulled
			savemobj->reactiontime 		= mobj->reactiontime;
			savemobj->threshold 		= mobj->threshold;
			savemobj->player 			= (mobj->type == MT_PLAYER) ? 1 : 0;
			//savemobj->lastlook 			= mobj->lastlook	//	elated to multiple players. unused.
			savemobj->spawnpoint 		= nightmarespawns[th];
			savemobj->tracer 			= mobj->tracerRef; 		// bug in vanilla i guess? trivial to make work right in realdoom

			
			save_p += sizeof(mobj_vanilla_t);

			
			
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


void  __far P_InitThinkers (void);

//
// P_UnArchiveThinkers
//
void __far P_UnArchiveThinkers (void) {
	
    byte					tclass;
    THINKERREF				currentthinker;
	THINKERREF				next;
	THINKERREF 				th;
	mobj_t __near* 			mobj;
	mobj_pos_t __far * 		mobj_pos;
	mobj_vanilla_t __far * 	savemobj;
	fixed_t_union flags;

	int16_t i;
    
    // remove all the current thinkers
    currentthinker = thinkerlist[0].next;
	while (currentthinker != 0) {
		int16_t functype = thinkerlist[th].prevFunctype & TF_FUNCBITS;
		next = thinkerlist[currentthinker].next;

		if (functype == TF_MOBJTHINKER_HIGHBITS) {
			P_RemoveMobj(&thinkerlist[currentthinker].data);
		} else {
			memset(&thinkerlist[currentthinker].data, 0, sizeof(mobj_t));
		}

		currentthinker = next;
    }
    P_InitThinkers ();
	
	FAR_memset(blocklinks, 0, MAX_BLOCKLINKS_SIZE);

    // read in saved thinkers
    while (1) {
		tclass = *save_p++;
		switch (tclass) {
			case tc_end:
				return; 	// end of list
					
			case tc_mobj:
				PADSAVEP();
				mobj = (mobj_t __near*)P_CreateThinker(TF_MOBJTHINKER_HIGHBITS);
				th = GETTHINKERREF(mobj);
				mobj_pos = &mobjposlist_6800[th];
				
				savemobj = (mobj_vanilla_t __far *) save_p;

				mobj_pos->x.w 				= savemobj->x;
				mobj_pos->y.w 				= savemobj->y;
				mobj_pos->z.w 				= savemobj->z;
				mobj_pos->angle 			= savemobj->angle;
				mobj_pos->stateNum 			= savemobj->state;
				flags.w 					= savemobj->flags;
				mobj_pos->flags1			= flags.h.fracbits;
				mobj_pos->flags2			= flags.h.intbits;
				mobj->radius 				= savemobj->radius >> FRACBITS;
				mobj->height.w 				= savemobj->height;
				mobj->momx.w 				= savemobj->momx;
				mobj->momy.w 				= savemobj->momy;
				mobj->momz.w 				= savemobj->momz;
				mobj->type 					= savemobj->type;
				mobj->tics					= savemobj->tics;
				mobj->health 				= savemobj->health;
				mobj->movedir 				= savemobj->movedir;
				mobj->movecount 			= savemobj->movecount;
				mobj->reactiontime 			= savemobj->reactiontime;
				mobj->threshold 			= savemobj->threshold;
				nightmarespawns[th] 		= savemobj->spawnpoint;
				//mobj->tracerRef 			= savemobj->tracer; 		// bug in vanilla i guess? no guarantee thinkers get the same thinkerref again so probbaly a bug here too,

				mobj->bnextRef = NULL_THINKERREF; // garbage value. P_SetThingPosition will fix
				mobj_pos->snextRef = NULL_THINKERREF; // garbage value. P_SetThingPosition will fix
				mobj->targetRef = NULL_THINKERREF;
				
				
				if (mobj->type == MT_PLAYER) {
					playerMobjRef = th;
				}

				P_SetThingPosition (mobj, mobj_pos, -1);	// generate secnum and various blocklink etc fields
				mobj->floorz = sectors[mobj->secnum].floorheight;
				mobj->ceilingz = sectors[mobj->secnum].ceilingheight;

				save_p += sizeof(mobj_vanilla_t);

				break;
				
					
			default:
				I_Error ("tclass a %i",tclass);
		}
	
    }
	
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
void __far P_ArchiveSpecials (void) {
	
    THINKERREF					th;
    int32_t 					scratch;

    int16_t			i;

    // save off the current thinkers
    for (th = thinkerlist[0].next ; th != 0 ; th=thinkerlist[th].next) {
		int16_t functype = thinkerlist[th].prevFunctype & TF_FUNCBITS;

		if (functype == TF_NULL_HIGHBITS) {
			for (i = 0; i < MAXCEILINGS;i++){
				if (activeceilings[i] == th) {
					break;
				}
			}
	    
			// copy nonactive ceilings
			if (i<MAXCEILINGS) {
				ceiling_vanilla_t __far*	saveceiling;
				ceiling_t __near*			sourceceiling = (ceiling_t __near*)&thinkerlist[th].data;
				*save_p++ 					= tc_ceiling;
				PADSAVEP();
				saveceiling 				= (ceiling_vanilla_t __far*)save_p;
				FAR_memset (saveceiling, 0, sizeof(ceiling_vanilla_t));
				saveceiling->type = 		sourceceiling->type;
				saveceiling->sector = 		sourceceiling->secnum;
				scratch 					= sourceceiling->bottomheight;
				saveceiling->bottomheight 	= scratch << (16-SHORTFLOORBITS); 
				scratch 					= sourceceiling->topheight;
				saveceiling->topheight	 	= scratch << (16-SHORTFLOORBITS); 
				scratch 					= sourceceiling->speed;
				saveceiling->speed		 	= scratch << (16-SHORTFLOORBITS); 
				saveceiling->crush			= sourceceiling->crush;
				saveceiling->direction		= sourceceiling->direction;
				saveceiling->tag			= sourceceiling->tag;
				saveceiling->olddirection	= sourceceiling->olddirection;

				save_p += sizeof(ceiling_vanilla_t);

			}
			continue;
		}
			
		if (functype == TF_MOVECEILING_HIGHBITS) {
			ceiling_vanilla_t __far*	saveceiling;
			ceiling_t __near*			sourceceiling = (ceiling_t __near*)&thinkerlist[th].data;
			*save_p++ 					= tc_ceiling;
			PADSAVEP();
			saveceiling 				= (ceiling_vanilla_t __far*)save_p;
			FAR_memset (saveceiling, 0, sizeof(ceiling_vanilla_t));
			saveceiling->type 			= sourceceiling->type;
			saveceiling->sector 		= sourceceiling->secnum;
			scratch 					= sourceceiling->bottomheight;
			saveceiling->bottomheight 	= scratch << (16-SHORTFLOORBITS); 
			scratch 					= sourceceiling->topheight;
			saveceiling->topheight	 	= scratch << (16-SHORTFLOORBITS); 
			scratch 					= sourceceiling->speed;
			saveceiling->speed		 	= scratch << (16-SHORTFLOORBITS); 
			saveceiling->crush			= sourceceiling->crush;
			saveceiling->direction		= sourceceiling->direction;
			saveceiling->tag			= sourceceiling->tag;
			saveceiling->olddirection	= sourceceiling->olddirection;

			save_p += sizeof(ceiling_vanilla_t);

			continue;
		}
			
		if (functype == TF_VERTICALDOOR_HIGHBITS) {
			vldoor_vanilla_t __far*		savedoor;
			vldoor_t __near*			sourcedoor = (vldoor_t __near*)&thinkerlist[th].data;
			*save_p++ 				= tc_door;
			PADSAVEP();
			savedoor 				= (vldoor_vanilla_t __far*)save_p;
			FAR_memset (savedoor, 0, sizeof(vldoor_vanilla_t));
			savedoor->type 			= sourcedoor->type;
			savedoor->sector 		= sourcedoor->secnum;
			scratch 				= sourcedoor->topheight;
			savedoor->topheight	 	= scratch << (16-SHORTFLOORBITS); 
			scratch 				= sourcedoor->speed;
			savedoor->speed		 	= scratch << (16-SHORTFLOORBITS); 
			savedoor->direction		= sourcedoor->direction;
			savedoor->topwait		= sourcedoor->topwait;
			savedoor->topcountdown	= sourcedoor->topcountdown;

			save_p += sizeof(vldoor_vanilla_t);

		}
			
		if (functype == TF_MOVEFLOOR_HIGHBITS) {
			floormove_vanilla_t __far*	savefloor;
			floormove_t __near*			sourcefloor = (floormove_t __near*)&thinkerlist[th].data;
			*save_p++ 					= tc_floor;
			PADSAVEP();
			savefloor 					= (floormove_vanilla_t __far*)save_p;
			FAR_memset (savefloor, 0, sizeof(floormove_vanilla_t));
			savefloor->type 			= sourcefloor->type;
			savefloor->crush 			= sourcefloor->crush;
			savefloor->sector 			= sourcefloor->secnum;
			savefloor->direction		= sourcefloor->direction;
			savefloor->newspecial		= sourcefloor->newspecial;
			savefloor->texture			= sourcefloor->texture;
			scratch 					= sourcefloor->floordestheight;
			savefloor->floordestheight	= scratch << (16-SHORTFLOORBITS); 
			scratch 					= sourcefloor->speed;
			savefloor->speed		 	= scratch << (16-SHORTFLOORBITS); 

			save_p += sizeof(floormove_vanilla_t);
		}
			



		if (functype == TF_PLATRAISE_HIGHBITS) {
			plat_vanilla_t __far*	saveplat;
			plat_t __near*			sourceplat = (plat_t __near*)&thinkerlist[th].data;
			*save_p++ 					= tc_plat;
			PADSAVEP();
			saveplat 					= (plat_vanilla_t __far*)save_p;
			FAR_memset (saveplat, 0, sizeof(plat_vanilla_t));
			saveplat->sector 			= sourceplat->secnum;
			scratch 					= sourceplat->speed;
			saveplat->speed		 		= scratch << (16-SHORTFLOORBITS); 
			scratch 					= sourceplat->low;
			saveplat->low		 		= scratch << (16-SHORTFLOORBITS); 
			scratch 					= sourceplat->high;
			saveplat->high		 		= scratch << (16-SHORTFLOORBITS); 
			saveplat->wait 				= sourceplat->wait;
			saveplat->count 			= sourceplat->count;
			saveplat->status 			= sourceplat->status;
			saveplat->oldstatus 		= sourceplat->oldstatus;
			saveplat->crush 			= sourceplat->crush;
			saveplat->tag 				= sourceplat->tag;
			saveplat->type 				= sourceplat->type;



			save_p += sizeof(plat_vanilla_t);
			continue;
		}

			
		if (functype == TF_LIGHTFLASH_HIGHBITS) {
			lightflash_vanilla_t __far*	saveflash;
			lightflash_t __near*			sourceflash = (lightflash_t __near*)&thinkerlist[th].data;
			*save_p++ 					= tc_flash;
			PADSAVEP();
			saveflash 					= (lightflash_vanilla_t __far*)save_p;
			FAR_memset (saveflash, 0, sizeof(lightflash_vanilla_t));
			saveflash->sector 			= sourceflash->secnum;
			saveflash->count			= sourceflash->count;
			saveflash->maxlight			= sourceflash->maxlight;
			saveflash->minlight			= sourceflash->minlight;
			saveflash->maxtime			= sourceflash->maxtime;
			saveflash->mintime			= sourceflash->mintime;

			save_p += sizeof(lightflash_vanilla_t);
			continue;
		}


			
		if (functype == TF_STROBEFLASH_HIGHBITS) {
			strobe_vanilla_t __far*	savestrobe;
			strobe_t __near*			sourcestrobe = (strobe_t __near*)&thinkerlist[th].data;
			*save_p++ 					= tc_strobe;
			PADSAVEP();
			savestrobe 					= (strobe_vanilla_t __far*)save_p;
			FAR_memset (savestrobe, 0, sizeof(strobe_vanilla_t));
			savestrobe->sector 			= sourcestrobe->secnum;
			savestrobe->count			= sourcestrobe->count;
			savestrobe->minlight		= sourcestrobe->minlight;
			savestrobe->maxlight		= sourcestrobe->maxlight;
			savestrobe->darktime		= sourcestrobe->darktime;
			savestrobe->brighttime		= sourcestrobe->brighttime;

			save_p += sizeof(strobe_vanilla_t);
			continue;
		}
			




		if (functype == TF_GLOW_HIGHBITS) {
			glow_vanilla_t __far*	saveglow;
			glow_t __near*			sourceglow = (glow_t __near*)&thinkerlist[th].data;
			*save_p++ 				= tc_glow;
			PADSAVEP();
			saveglow 				= (glow_vanilla_t __far*)save_p;
			FAR_memset (saveglow, 0, sizeof(glow_vanilla_t));
			saveglow->sector 		= sourceglow->secnum;
			saveglow->minlight		= sourceglow->minlight;
			saveglow->maxlight		= sourceglow->maxlight;
			saveglow->direction		= sourceglow->direction;

			save_p += sizeof(glow_vanilla_t);
			continue;
		}
		
    }
	


    // add a terminating marker
    *save_p++ = tc_endspecials;	
	
}


//
// P_UnArchiveSpecials
//
void __far P_UnArchiveSpecials (void) {
	
    byte					tclass;
    ceiling_t 				__near*	ceiling;
    vldoor_t 				__near*	door;
    floormove_t 			__near*	floor;
    plat_t 					__near*	plat;
    lightflash_t 			__near*	flash;
    strobe_t 				__near*	strobe;
    glow_t 					__near*	glow;
	ceiling_vanilla_t 		__far*	saveceiling;
	vldoor_vanilla_t 		__far*	savedoor;
	glow_vanilla_t 			__far*	saveglow;
	strobe_vanilla_t 		__far*	savestrobe;
	floormove_vanilla_t 	__far*	savefloor;
	plat_vanilla_t 			__far*	saveplat;
	lightflash_vanilla_t 	__far*	saveflash;

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

				saveceiling = (ceiling_vanilla_t __far *) save_p;

				ceiling->type 			= saveceiling->type;
				ceiling->secnum 		= saveceiling->sector;
				ceiling->bottomheight   = saveceiling->bottomheight >> (16-SHORTFLOORBITS);
				ceiling->topheight   	= saveceiling->topheight 	>> (16-SHORTFLOORBITS);
				ceiling->crush			= saveceiling->crush;
				ceiling->direction		= saveceiling->direction;
				ceiling->tag			= saveceiling->tag;
				ceiling->olddirection	= saveceiling->olddirection;


				save_p += sizeof(ceiling_vanilla_t);
				sectors_physics[ceiling->secnum].specialdataRef = thinkerRef;




				P_AddActiveCeiling(thinkerRef);
				break;
						
			case tc_door:
				PADSAVEP();

				door =  P_CreateThinker(TF_VERTICALDOOR_HIGHBITS);
				thinkerRef = GETTHINKERREF(door);
				
				savedoor = (vldoor_vanilla_t __far *) save_p;

				door->type 			= savedoor->type;
				door->secnum 		= savedoor->sector;
				door->topheight 	= savedoor->topheight 	>> (16-SHORTFLOORBITS);
				door->speed		 	= savedoor->speed 		>> (16-SHORTFLOORBITS);
				door->direction		= savedoor->direction;
				door->topwait		= savedoor->topwait;
				door->topcountdown	= savedoor->topcountdown;



				save_p += sizeof(vldoor_vanilla_t);
				sectors_physics[door->secnum].specialdataRef = thinkerRef;

				break;
						
			case tc_floor:
				PADSAVEP();

				floor =  P_CreateThinker(TF_MOVEFLOOR_HIGHBITS);
				thinkerRef = GETTHINKERREF(floor);

				savefloor = (floormove_vanilla_t __far *) save_p;

				floor->type 			= savefloor->type;
				floor->crush 			= savefloor->crush;
				floor->secnum 			= savefloor->sector;
				floor->direction		= savefloor->direction;
				floor->newspecial		= savefloor->newspecial;
				floor->texture			= savefloor->texture;
				floor->floordestheight	= savefloor->floordestheight >> (16-SHORTFLOORBITS);
				floor->speed			= savefloor->speed >> (16-SHORTFLOORBITS);
				floor->texture			= savefloor->texture;

				save_p += sizeof(floormove_vanilla_t);
				sectors_physics[floor->secnum].specialdataRef = thinkerRef;
				break;
						
			case tc_plat:
				PADSAVEP();

				plat =  P_CreateThinker(TF_PLATRAISE_HIGHBITS);
				thinkerRef = GETTHINKERREF(plat);
				saveplat = (plat_vanilla_t __far *) save_p;

				plat->secnum 			= saveplat->sector;
				plat->speed				= saveplat->speed >> (16-SHORTFLOORBITS);
				plat->low				= saveplat->low   >> (16-SHORTFLOORBITS);
				plat->high				= saveplat->high  >> (16-SHORTFLOORBITS);
				plat->wait 				= saveplat->wait;
				plat->count 			= saveplat->count;
				plat->status 			= saveplat->status;
				plat->oldstatus 		= saveplat->oldstatus;
				plat->crush 			= saveplat->crush;
				plat->tag 				= saveplat->tag;
				plat->type 				= saveplat->type;

				save_p += sizeof(plat_vanilla_t);
				sectors_physics[plat->secnum].specialdataRef = thinkerRef;

				P_AddActivePlat(thinkerRef);
				break;
						
			case tc_flash:
				PADSAVEP();

				flash =  P_CreateThinker(TF_LIGHTFLASH_HIGHBITS);
				thinkerRef = GETTHINKERREF(flash);

				saveflash = (lightflash_vanilla_t __far *) save_p;

				flash->secnum 			= saveflash->sector;
				flash->count			= saveflash->count;
				flash->maxlight			= saveflash->maxlight;
				flash->minlight			= saveflash->minlight;
				flash->maxtime			= saveflash->maxtime;
				flash->mintime			= saveflash->mintime;


				save_p += sizeof(lightflash_vanilla_t);
				break;
						
			case tc_strobe:
				PADSAVEP();
				
				strobe =  P_CreateThinker(TF_STROBEFLASH_HIGHBITS);
				thinkerRef = GETTHINKERREF(strobe);

				savestrobe = (strobe_vanilla_t __far *) save_p;
				strobe->secnum 			= savestrobe->sector;
				strobe->count			= savestrobe->count;
				strobe->minlight		= savestrobe->minlight;
				strobe->maxlight		= savestrobe->maxlight;
				strobe->darktime		= savestrobe->darktime;
				strobe->brighttime		= savestrobe->brighttime;

				save_p += sizeof(strobe_vanilla_t);
				break;
						
			case tc_glow:
				PADSAVEP();

				glow =  P_CreateThinker(TF_GLOW_HIGHBITS);
				thinkerRef = GETTHINKERREF(glow);

				saveglow = (glow_vanilla_t __far *) save_p;
				glow->secnum 		= saveglow->sector;
				glow->minlight		= saveglow->minlight;
				glow->maxlight		= saveglow->maxlight;
				glow->direction		= saveglow->direction;

				save_p += sizeof(glow_vanilla_t);
				break;
						
			default:
				I_Error ("tclass b %i",tclass);
		}
	
    }

}

