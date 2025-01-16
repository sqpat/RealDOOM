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
//	Game completion, final screen animation.
//

#include <ctype.h>

// Functions.
#include "i_system.h"
#include "z_zone.h"
#include "v_video.h"
#include "w_wad.h"
#include "s_sound.h"

// Data.
#include "dstrings.h"
#include "sounds.h"

#include "doomstat.h"
#include "r_state.h"
#include <dos.h>


#include "p_local.h"
#include "m_memory.h"
#include "m_near.h"


#ifdef __DEMO_ONLY_BINARY

void __far F_Drawer(void) {
}
void __far F_Ticker(void) {
}
boolean __far F_Responder(event_t  __far*event) {

}
void __far F_StartFinale(void) {

}


#else


#define	TEXTSPEED	3
#define	TEXTWAIT	250

void	__near F_StartCast (void);
void	__near F_CastTicker (void);
boolean __near F_CastResponder (event_t __far *ev);
void	__near F_CastDrawer (void);

 



//
// V_DrawPatchFlipped 
// Masks a column based masked pic to the screen.
// Flips horizontally, e.g. to mirror face.
//
// patch always 0x50000000
void __near V_DrawPatchFlipped (int16_t	x, int16_t y) ;

/*
void __near V_DrawPatchFlipped2 (int16_t	x, int16_t y) {

	int16_t		    count;
	int16_t		    col = 0;
	column_t __far*	column;
	patch_t __far*	patch = (patch_t __far*) 0x50000000;
	byte __far*	    desttop;
	byte __far*		dest;
	byte __far*		source;
	int16_t			w = patch->width;
	y -= (patch->topoffset);
	x -= (patch->leftoffset);

	//if (!0)
	V_MarkRect(x, y, w, (patch->height));

	desttop = MK_FP(screen0_segment,  (y * SCREENWIDTH_UNSIGNED) + x);

	for (; col < w; x++, col++, desttop++) {
		//column = (column_t  __far*)MK_FP(0x5000 + (patch->columnofs[w - 1 - col]) << 4, 0);
		column = (column_t  __far*)MK_FP(0x5000, (patch->columnofs[w - 1 - col]));
		// step through the posts in a column 
		while (column->topdelta != 0xff) {
			source = (byte  __far*)column + 3;
			dest = desttop + column->topdelta*SCREENWIDTH;
			count = column->length;

			while (count--) {
				*dest = *source;
				source++;
				dest += SCREENWIDTH;
			}
			column = (column_t __far *)(  ((byte  __far*)column) + column->length + 4 );
		}
	}
}

*/
//
// F_StartFinale
//
/*
void __far F_StartFinale (void) {
	int16_t finalemusic;

    gameaction = ga_nothing;
    gamestate = GS_FINALE;
    viewactive = false;
    automapactive = false;

    if(commercial) {
		#if (EXE_VERSION < EXE_VERSION_FINAL)
        // DOOM II and missions packs with E1, M34
			switch (gamemap) {
				case 6:
					finaleflat = "SLIME16";
					finaletext = C1TEXT;
					break;
				case 11:
					finaleflat = "RROCK14";
					finaletext = C2TEXT;
					break;
				case 20:
					finaleflat = "RROCK07";
					finaletext = C3TEXT;
					break;
				case 30:
					finaleflat = "FLOOR4_8";
					finaletext = C4TEXT;
					break;
				case 15:
					finaleflat = "RROCK13";
					finaletext = C5TEXT;
					break;
				case 31:
					finaleflat = "RROCK19";
					finaletext = C6TEXT;
					break;
				default:
					// Ouch.
					break;
			}
		#else
			if (plutonia) {
				switch (gamemap) {
					case 6:
					finaleflat = "SLIME16";
					finaletext = p1text;
					break;
					case 11:
					finaleflat = "RROCK14";
					finaletext = p2text;
					break;
					case 20:
					finaleflat = "RROCK07";
					finaletext = p3text;
					break;
					case 30:
					finaleflat = "RROCK17";
					finaletext = p4text;
					break;
					case 15:
					finaleflat = "RROCK13";
					finaletext = p5text;
					break;
					case 31:
					finaleflat = "RROCK19";
					finaletext = p6text;
					break;
					default:
					// Ouch.
					break;
				}
			} else if (tnt) {
				switch (gamemap) {
					case 6:
					finaleflat = "SLIME16";
					finaletext = t1text;
					break;
					case 11:
					finaleflat = "RROCK14";
					finaletext = t2text;
					break;
					case 20:
					finaleflat = "RROCK07";
					finaletext = t3text;
					break;
					case 30:
					finaleflat = "RROCK17";
					finaletext = t4text;
					break;
					case 15:
					finaleflat = "RROCK13";
					finaletext = t5text;
					break;
					case 31:
					finaleflat = "RROCK19";
					finaletext = t6text;
					break;
					default:
					// Ouch.
					break;
				}
			} else {
				// DOOM II and missions packs with E1, M34
				switch (gamemap) {
					case 6:
					finaleflat = "SLIME16";
					finaletext = c1text;
					break;
					case 11:
					finaleflat = "RROCK14";
					finaletext = c2text;
					break;
					case 20:
					finaleflat = "RROCK07";
					finaletext = c3text;
					break;
					case 30:
					finaleflat = "RROCK17";
					finaletext = c4text;
					break;
					case 15:
					finaleflat = "RROCK13";
					finaletext = c5text;
					break;
					case 31:
					finaleflat = "RROCK19";
					finaletext = c6text;
					break;
					default:
					// Ouch.
					break;
				}
			}
		#endif
		finalemusic = mus_read_m;
    } else {
		// DOOM 1 - E1, E3 or E4, but each nine missions
		switch (gameepisode) {
			case 1:
				finaleflat = "FLOOR4_8";
				//finaletext = E1TEXT;
				break;
			case 2:
				finaleflat = "SFLR6_1";
				//finaletext = E2TEXT;
				break;
			case 3:
				finaleflat = "MFLR8_4";
				//finaletext = E3TEXT;
				break;
			case 4:
				finaleflat = "MFLR8_3";
				//finaletext = E4TEXT;
				break;
			default:
				// Ouch.
				break;
		}
		finaletext = (E1TEXT-1) + gameepisode;
		finalemusic = mus_victor;
    }
    
    S_ChangeMusic(finalemusic, true);
    finalestage = 0;
    finalecount = 0;
}

*/

boolean __far F_Responder (event_t  __far*event) {
    if (finalestage == 2){
		return F_CastResponder (event);
	}
    return false;
}


//
// F_Ticker
//
void __far F_Ticker (void) {
	// big enough for any string here
	int8_t text[666];
	
    // check for skipping
    if ( (commercial) && ( finalecount > 50) ) {
      // go on to the next level
		if (player.cmd.buttons) {
			if (gamemap == 30) {
				F_StartCast();
			} else {
				gameaction = ga_worlddone;
			}
		}
    }
    
    // advance animation
    finalecount++;
	
    if (finalestage == 2) {
		F_CastTicker ();
		return;
    }
	
	if (commercial) {
		return;
	}
	getStringByIndex(finaletext, text);
    if (!finalestage && finalecount>locallib_strlen (text)*TEXTSPEED + TEXTWAIT) {
		finalecount = 0;
		finalestage = 1;
		wipegamestate = -1;		// force a wipe
		if (gameepisode == 3) {
			S_StartMusic(mus_bunny);
		}
    }

}



//
// F_TextWrite
//

#include "hu_stuff.h"
void __near F_TextWrite (void);

/*
void __near F_TextWrite (void) {
	uint16_t dest = 0;
    
    int16_t		x,y,w;
    int16_t		count;
    int8_t		chstring[650];
	int8_t*		ch = &chstring;
    int16_t		c;
    int16_t		cx;
    int16_t		cy;
	int8_t      finaleflat_near[9];
	// todo improve in asm.
	finaleflat_near[0] = finaleflat[0];
	finaleflat_near[1] = finaleflat[1];
	finaleflat_near[2] = finaleflat[2];
	finaleflat_near[3] = finaleflat[3];
	finaleflat_near[4] = finaleflat[4];
	finaleflat_near[5] = finaleflat[5];
	finaleflat_near[6] = finaleflat[6];
	finaleflat_near[7] = finaleflat[7];
	finaleflat_near[8] = finaleflat[8];

     // erase the entire screen to a tiled background
	//byte __far* src = (byte __far*)0x50000000;

	Z_QuickMapScratch_5000(); // 5000
	Z_QuickMapScreen0();      // 8000
	// 9400-9c00 carries wad stuff
	W_CacheLumpNameDirect(finaleflat_near, MK_FP(0x5000, 0x0000));
	//I_Error("finale flat %s", finaleflat);

    for (y=0 ; y<SCREENHEIGHT ; y++) {
		for (x=0 ; x<SCREENWIDTH/64 ; x++) {
			FAR_memcpy (MK_FP(screen0_segment, dest), MK_FP(0x5000, ((y&63)<<6)), 64);
			dest += 64;
		}
	 
    }
	//6000, 7000-8000
	Z_QuickMapStatusNoScreen4();	

    V_MarkRect (0, 0, SCREENWIDTH, SCREENHEIGHT);	
    // draw some of the text onto the screen
    cx = 10;
    cy = 10;
   
    getStringByIndex(finaletext, chstring);
	
    count = (finalecount - 10)/TEXTSPEED;
    if (count < 0){
		count = 0;
	}
    for ( ; count ; count-- ) {
		c = *ch++;
		if (!c) {
			break;
		}
		if (c == '\n') {
			cx = 10;
			cy += 11;
			continue;
		}
			
		c = locallib_toupper(c) - HU_FONTSTART;
		if (c < 0 || c> HU_FONTSIZE) {
			cx += 4;
			continue;
		}
			
		w = font_widths[c];
		if (cx+w > SCREENWIDTH) {
			break;
		}
		V_DrawPatch(cx, cy, 0, (patch_t __far *) MK_FP(ST_GRAPHICS_SEGMENT, hu_font[c]));
		cx+=w;
    }
}
*/

//
// F_StartCast
//

void __near F_StartCast (void) {
	//todoaddr inline later
	statenum_t (__far  * getSeeState)(uint8_t) = getSeeStateAddr;

	if (finalestage != 2) {
    	wipegamestate = -1;		// force a screen wipe
	}
    castnum = 0;
    caststate = &states[getSeeState(castorder[castnum].type)];
    casttics = caststate->tics;
    castdeath = false;
    finalestage = 2;	
    castframes = 0;
    castonmelee = 0;
    castattacking = false;
    S_ChangeMusic(mus_evil, true);
}


//
// F_CastTicker
//
void __near F_CastTicker (void) {
    int16_t		st;
    int16_t		sfx;
	//todoaddr inline later
	statenum_t (__far  * getMissileState)(uint8_t) = getMissileStateAddr;
	statenum_t (__far  * getSeeState)(uint8_t) = getSeeStateAddr;
	statenum_t (__far  * getMeleeState)(uint8_t) = getMeleeStateAddr;

    if (--casttics > 0){
		return;			// not time to change state yet
	}
	Z_QuickMapPhysics();
    if (caststate->tics == -1 || caststate->nextstate == S_NULL) {
		// switch from deathstate to next monster
		castnum++;
		castdeath = false;
		if (castnum == MAX_CASTNUM){
			castnum = 0;
		}

		S_StartSound (NULL, getSeeState(castorder[castnum].type));
		caststate = &states[getSeeState(castorder[castnum].type)];
		castframes = 0;
	} else {
		// just advance to next state in animation
		if (caststate == &states[S_PLAY_ATK1]){
			goto stopattack;	// Oh, gross hack!
		}
		st = caststate->nextstate;
		caststate = &states[st];
		castframes++;

		// sound hacks....
		switch (st) {
			case S_PLAY_ATK1:	sfx = sfx_dshtgn; break;
			case S_POSS_ATK2:	sfx = sfx_pistol; break;
			case S_SPOS_ATK2:	sfx = sfx_shotgn; break;
			case S_VILE_ATK2:	sfx = sfx_vilatk; break;
			case S_SKEL_FIST2:	sfx = sfx_skeswg; break;
			case S_SKEL_FIST4:	sfx = sfx_skepch; break;
			case S_SKEL_MISS2:	sfx = sfx_skeatk; break;
			case S_FATT_ATK8:
			case S_FATT_ATK5:
			case S_FATT_ATK2:	sfx = sfx_firsht; break;
			case S_CPOS_ATK2:
			case S_CPOS_ATK3:
			case S_CPOS_ATK4:	sfx = sfx_shotgn; break;
			case S_TROO_ATK3:	sfx = sfx_claw; break;
			case S_SARG_ATK2:	sfx = sfx_sgtatk; break;
			case S_BOSS_ATK2:
			case S_BOS2_ATK2:
			case S_HEAD_ATK2:	sfx = sfx_firsht; break;
			case S_SKULL_ATK2:	sfx = sfx_sklatk; break;
			case S_SPID_ATK2:
			case S_SPID_ATK3:	sfx = sfx_shotgn; break;
			case S_BSPI_ATK2:	sfx = sfx_plasma; break;
			case S_CYBER_ATK2:
			case S_CYBER_ATK4:
			case S_CYBER_ATK6:	sfx = sfx_rlaunc; break;
			case S_PAIN_ATK3:	sfx = sfx_sklatk; break;
			default: sfx = 0; break;
		}

		S_StartSound(NULL, sfx);
	}
    if (castframes == 12) {
		// go into attack frame
		castattacking = true;
		if (castonmelee){
			caststate=&states[getMeleeState(castorder[castnum].type)];
		} else{
			caststate=&states[getMissileState(castorder[castnum].type)];
		}
		castonmelee ^= 1;
		if (caststate == &states[S_NULL]) {
			if (castonmelee){
				caststate= &states[getMeleeState(castorder[castnum].type)];
			} else {
				caststate= &states[getMissileState(castorder[castnum].type)];
			}
		}
    }
	
    if (castattacking) {
		if (castframes == 24 ||	caststate == &states[getSeeState(castorder[castnum].type)] ) {
			stopattack:
				castattacking = false;
				castframes = 0;
				caststate = &states[getSeeState(castorder[castnum].type)];
		}
    }
	
    casttics = caststate->tics;
    if (casttics == -1){
		casttics = 15;
	}
}


//
// F_CastResponder
//

boolean __near F_CastResponder (event_t __far* ev) {
 	//todoaddr inline later
	statenum_t (__far  * getDeathState)(uint8_t) = getDeathStateAddr;
   	if (ev->type != ev_keydown){
		return false;
	}
		
    if (castdeath){
		return true;			// already in dying frames
	}

    // go into death frame
    castdeath = true;
    caststate = &states[getDeathState(castorder[castnum].type)];
    casttics = caststate->tics;
    castframes = 0;
    castattacking = false;
	S_StartSound (NULL, mobjinfo[castorder[castnum].type].deathsound);
	
    return true;
}


void __near F_CastPrint (int8_t* text) ;
/*
void __near F_CastPrint (int8_t* text) {
    int8_t*	ch;
    int16_t		c;
    int16_t		cx;
    int16_t		w;
    int16_t		width;
    
	// find width
    ch = text;
    width = 0;
	
    while (ch) {
		c = *ch++;
		if (!c){
			break;
		}
		c = locallib_toupper(c) - HU_FONTSTART;
		if (c < 0 || c> HU_FONTSIZE) {
			width += 4;
			continue;
		}
			
	
		w = font_widths[c];
		width += w;
    }
    
    // draw it
    cx = 160-width/2;
    ch = text;
    while (ch) {
		c = *ch++;
		if (!c){
			break;
		}
		c = locallib_toupper(c) - HU_FONTSTART;
		if (c < 0 || c> HU_FONTSIZE) {
			cx += 4;
			continue;
		}
			
		w = font_widths[c];
		V_DrawPatch(cx, 180, 0, (patch_t __far *) MK_FP(ST_GRAPHICS_SEGMENT, hu_font[c]));
		cx+=w;
    }
	
}
*/

//
// F_CastDrawer
//

/*
void __near F_CastDrawer (void) {
    spritedef_t __far*	  sprite;
    spriteframe_t __far*  sprframe;
    int16_t			      lump;
    boolean				  flip;
	spriteframe_t __far*  spriteframes;
	int8_t				  text[100];
	patch_t __far*		  patch = (patch_t __far*)0x50000000;

	// these get paged out by render7000
	spritenum_t           castspritenum = caststate->sprite;
	spritenum_t           castframenum = caststate->frame;


    // erase the entire screen to a background
    V_DrawFullscreenPatch("BOSSBACK", 0);
	getStringByIndex(castorder[castnum].nameindex+castorderoffset, text);
    Z_QuickMapStatusNoScreen4();
    F_CastPrint (text); //this needs status for the letter graphics
	
	Z_QuickMapRender7000(); // need render 7000 for spriteframes. (but this overwrites status page)

    // draw the current frame in the middle of the screen
	sprite = &sprites[castspritenum];
	spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprite->spriteframesOffset]);

	sprframe = &spriteframes[castframenum & FF_FRAMEMASK];

	
	lump = sprframe->lump[0];
    flip = (boolean)sprframe->flip[0];
	
	Z_QuickMapScratch_5000();

	W_CacheLumpNumDirect(lump + firstspritelump, (byte __far*)0x50000000);

	if (flip) {
		V_DrawPatchFlipped(160, 170);
	} else {
		V_DrawPatch(160, 170, 0, patch);
	}

}
*/

//
// F_DrawPatchCol
//

void __near F_DrawPatchCol ( int16_t		x, column_t __far*	column);

/*
void __near F_DrawPatchCol ( int16_t		x, column_t __far*	column) {
    
    byte __far*	source;
    byte __far*	dest;
    byte __far*	desttop;
    int16_t		count;
	
    desttop = screen0+x;

    // step through the posts in a column
    while (column->topdelta != 0xff ) {
		source = (byte  __far*)column + 3;
		dest = desttop + column->topdelta*SCREENWIDTH;
		count = column->length;
			
		while (count--) {
			*dest = *source++;
			dest += SCREENWIDTH;
		}
		column = (column_t  __far*)(  (byte  __far*)column + column->length + 4 );
    }
}
*/

//
// F_BunnyScroll
//
void __near F_BunnyScroll (void) {
    int16_t		scrolled;
	int8_t	name[10];
    int16_t		stage;
	int8_t  stagestring[2];
	int32_t		totaloffset = 0;
	boolean	pic2 = false;
	int32_t columnoffset = 0;
	int16_t x;
	int16_t col;
	column_t __far* column;
	patch_t __far* patch 	  = (patch_t __far*)0x50000000;
	byte __far* lookupoffset = (byte __far*)0x54000000;
	Z_QuickMapScratch_5000();

    V_MarkRect (0, 0, SCREENWIDTH, SCREENHEIGHT);
	
    scrolled = 320 - (finalecount-230)/2;
    if (scrolled > 320){
		scrolled = 320;
	}
    if (scrolled < 0){
		scrolled = 0;
	}

	
	//V_DrawFullscreenPatch("PFUB2", PU_LEVEL)

	// get lump for patch 1	
	// load patch 1. 

	// offsets will always be page 1
	W_CacheLumpNumDirectFragment(W_GetNumForName("PFUB2"), (byte __far *)(0x50000000), 0);
	// we will page this 2nd page forward to get the column addr
	W_CacheLumpNumDirectFragment(W_GetNumForName("PFUB2"), lookupoffset, 0);

	for ( x=0 ; x<SCREENWIDTH ; x++) {

		if (x+scrolled < 320){
			col = x+scrolled;
		} else {
			if (!pic2){
				totaloffset = 0;
				columnoffset = 0;
				pic2 = true;
				// load patch 2
				W_CacheLumpNumDirectFragment(W_GetNumForName("PFUB1"), (byte __far *)(0x50000000), 0);
				W_CacheLumpNumDirectFragment(W_GetNumForName("PFUB1"), lookupoffset, 0);
			}
			col = x+scrolled - 320;
			
		}

		columnoffset = (patch->columnofs[col]) - totaloffset;
		if (columnoffset > 15000){
			totaloffset += columnoffset;
			if (pic2){
				W_CacheLumpNumDirectFragment(W_GetNumForName("PFUB1"), lookupoffset, totaloffset);
			} else {
				W_CacheLumpNumDirectFragment(W_GetNumForName("PFUB2"), lookupoffset, totaloffset);
			}

			columnoffset = 0;

		}
		column = (column_t  __far*)(lookupoffset + columnoffset);
		F_DrawPatchCol (x, column);			
		//I_Error("first %i %i %i %i", x, col, scrolled, finalecount);

    }
	
    if (finalecount < 1130){
		return;
	}
    
	if (finalecount < 1180) {
		W_CacheLumpNameDirect("END0", (byte __far*)patch);
		V_DrawPatch ((SCREENWIDTH-13*8)/2, (SCREENHEIGHT-8*8)/2,0, patch);
		finale_laststage = 0;

		return;
    }
	
    stage = (finalecount-1180) / 5;
    if (stage > 6){
		stage = 6;
	}
	if (stage > finale_laststage) {
		S_StartSound (NULL, sfx_pistol);
		finale_laststage = stage;
    }

	// max at 6.
	stagestring[0] = '0' + stage;
	stagestring[1] = '\0';
    combine_strings(name,"END", stagestring);
	W_CacheLumpNameDirect(name, (byte __far*)patch);
	V_DrawPatch ((SCREENWIDTH-13*8)/2, (SCREENHEIGHT-8*8)/2,0, patch);


}


//
// F_Drawer
//
void __far F_Drawer (void) {
    if (finalestage == 2) {
		F_CastDrawer ();  // F_CastDrawer calls F_CastPrint which restores physics quickmap
		return;
    }
	
	if (!finalestage) {
		F_TextWrite();
	} else {
		switch (gameepisode) {
		  case 1:
			if (!is_ultimate){
				V_DrawFullscreenPatch("HELP2", 0);
				break;
			} else {
			    V_DrawFullscreenPatch("CREDIT", 0);
				break;
			}
		  case 2:
				V_DrawFullscreenPatch("VICTORY2", 0);
				break;
		  case 3:
				F_BunnyScroll ();
				break;
		  case 4:
				V_DrawFullscreenPatch("ENDPIC", 0);
				break;
		}
    }
			
	
}


#endif
