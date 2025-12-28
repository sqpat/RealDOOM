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
//      Do all the WAD I/O, get map description,
//      set up initial state and misc. LUTs.
//

#include "doomdef.h"
#include "doomdata.h"

#include <math.h>
#include "constant.h"

#include "z_zone.h"
#include "w_wad.h"
#include "r_defs.h"
#include "r_state.h"

#include "p_setup.h"




#include <dos.h>
#include "m_memory.h"
#include "m_near.h"




 


void __far P_InitThinkers (void);
void __far P_SpawnMapThingCallThrough(mapthing_t mthing, int16_t key);
// void __far I_Error (int8_t __far *error, ...);

void __near P_SpawnSpecialsCallThrough();
void __near S_StartCallThrough();
void __near M_AddToBox16 ( int16_t	x, int16_t	y, int16_t __near*	box  );

uint16_t   __near  R_TextureNumForName(int8_t* __near name);
uint8_t __near R_FlatNumForName(int8_t __far* name);

void __near P_LoadVertexes(int16_t lump);
void __near P_LoadSectors(int16_t lump);
void __near P_LoadSubsectors(int16_t lump);
void __near P_LoadNodes(int16_t lump);
void __near P_LoadSideDefs(int16_t lump);
void __near P_LoadLineDefs(int16_t lump);
void __near P_LoadBlockMap(int16_t lump);
void __near P_LoadThings(int16_t lump);
void __near P_LoadSegs(int16_t lump);	
void __near Z_FreeConventionalAllocations();
void __near P_GroupLines();

void __near R_LoadPatchColumnsColormap0(uint16_t lump, segment_t texlocation_segment, boolean ismasked);
// void GAMEKEYDOWNTHING();


//
// P_SetupLevel
//
// stick this at top so entry point is always xxxx:0000
void __near P_SetupLevel (int8_t episode, int8_t map, skill_t skill) {
	int8_t        lumpname[9];
	int16_t         lumpnum;
	
	//I_Error("level is %i %i", episode, map);

    totalkills = totalitems = totalsecret = 0;
	wminfo.partime = 180; // // todo once this function in asm, move wminfo to cs
	player.killcount = player.secretcount = player.itemcount = 0;

	// Initial height of PointOfView
	// will be set by player think.
	player.viewzvalue.w = 1;
	
	S_StartCallThrough();
	Z_FreeConventionalAllocations();

	// TODO reset 32 bit counters to start values here..
	validcount_global = 1;

	P_InitThinkers();


	// find map name
	if (commercial) {
		lumpname[0] = 'm';
		lumpname[1] = 'a';
		lumpname[2] = 'p';
		lumpname[3] = '0' + map / 10;
		lumpname[4] = '0' + map % 10;

	}
	else
	{
		lumpname[0] = 'E';
		lumpname[1] = '0' + episode;
		lumpname[2] = 'M';
		lumpname[3] = '0' + map;
		lumpname[4] = 0;
	}
	lumpname[5] = 0;
	lumpname[6] = 0;
	lumpname[7] = 0;
	lumpname[8] = 0;

	lumpnum = W_GetNumForName(lumpname);

	leveltime.w = 0;
	
	// note: most of this ordering is important 
	P_LoadVertexes(lumpnum + ML_VERTEXES);
	P_LoadSectors(lumpnum + ML_SECTORS);
	P_LoadSideDefs(lumpnum + ML_SIDEDEFS);


	P_LoadLineDefs(lumpnum + ML_LINEDEFS);
	P_LoadSubsectors(lumpnum + ML_SSECTORS);
	P_LoadNodes(lumpnum + ML_NODES);

	P_LoadSegs(lumpnum + ML_SEGS);

	P_LoadBlockMap(lumpnum + ML_BLOCKMAP);


	W_CacheLumpNumDirect(lumpnum + ML_REJECT, rejectmatrix);

	P_GroupLines();


	P_LoadThings(lumpnum + ML_THINGS);
 

	// set up world state
	P_SpawnSpecialsCallThrough();
	
	Z_QuickMapRender();
	Z_QuickMapRenderPlanes();

	// prep sky texture
								// lump lookup
	R_LoadPatchColumnsColormap0( ((int16_t __far *)&(texturecolumnlumps_bytes[texturepatchlump_offset[skytexture]]))[0], skytexture_texture_segment, false);
	

	// precalculate the offsets table location...

	Z_QuickMapPhysics();
 

 // reset last used segment cache
	lastvisspritepatch = -1;    
	lastvisspritepatch2 = -1;    
	cachedtex[0] = -1;
    cachedtex[1] = -1;
	{
		int16_t a;
		for (a = 0; a < NUM_CACHE_LUMPS; a++){
			cachedlumps[a] = -1;
		}
	}


	// preload graphics
	
	/*
	if (precache)
		R_PrecacheLevel();
*/


}
//void __far S_StopChannel(int8_t cnum);

//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//


/*
void __far S_Start(void) {


	int8_t cnum;
	int8_t mnum;
  	
  	// kill all playing sounds at start of level
  	//  (trust me - a good idea)
  	for (cnum=0 ; cnum<numChannels ; cnum++){
    	if (channels[cnum].sfx_id){
      		S_StopChannel(cnum);
		}
	}
  
  	// start new music for the level
  	mus_paused = 0;
  
	if (commercial){
		mnum = mus_runnin + gamemap - 1;
	} else {
		int8_t spmus[]= {
			// Song - Who? - Where?
			
			mus_e3m4,	// American	e4m1
			mus_e3m2,	// Romero	e4m2
			mus_e3m3,	// Shawn	e4m3
			mus_e1m5,	// American	e4m4
			mus_e2m7,	// Tim 	e4m5
			mus_e2m4,	// Romero	e4m6
			mus_e2m6,	// J.Anderson	e4m7 CHIRON.WAD
			mus_e2m5,	// Shawn	e4m8
			mus_e1m9	// Tim		e4m9
		};
		
		if (gameepisode < 4){
			mnum = mus_e1m1 + (gameepisode-1)*9 + gamemap-1;
		} else {
			mnum = spmus[gamemap-1];
		}
    }	
  
  // HACK FOR COMMERCIAL
  //  if (commercial && mnum > mus_e3m9)	
  //      mnum -= mus_e3m9;
  
  S_ChangeMusic(mnum, true);
  

}
*/


// bypass the colofs cache stuff, store just raw pixel data at texlocation. 
//void R_LoadPatchColumns(uint16_t lump, byte __far * texlocation, boolean ismasked){
//todo remove texlocation_segment param if its hardcoded?
void __near R_LoadPatchColumnsColormap0(uint16_t lump, segment_t texlocation_segment, boolean ismasked){
	patch_t __far *patch = (patch_t __far *)SCRATCH_ADDRESS_4000;
	int16_t col;
	uint16_t destoffset = 0;
	int16_t patchwidth;


	Z_QuickMapScratch_4000(); // render col info has been paged out..

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_4000);
	patchwidth = patch->width;

	for (col = 0; col < patchwidth; col++){

		column_t __far * column = (column_t __far *)(SCRATCH_ADDRESS_4000 + patch->columnofs[col]);
		while (column->topdelta != 0xFF){
			uint8_t length = column->length;
			byte __far * sourcetexaddr = SCRATCH_ADDRESS_4000 + (((int32_t)column) + 3);
			byte __far * destaddr = MK_FP(texlocation_segment,  destoffset);
			byte __far * colormapzero = MK_FP(colormaps_segment,  0);
			//FAR_memcpy(MK_FP(texlocation_segment,  destoffset), sourcetexaddr, length);
			uint8_t i;
			for (i = 0; i < length; i++){
				destaddr[i] = colormapzero[sourcetexaddr[i]];
			}

			destoffset += length;
			if (ismasked){

				// round up to the next paragraph for masked textures which do multiple renders
				// and thus the subrenders must also start paragraph aligned...
				// for non masked textures they are always overlapping - or really "should" be.. revisit for buggy gap pixels
				destoffset += (16 - ((length &0xF)) &0xF);
				
			}

	    	column = (column_t __far *)(  (byte  __far*)column + length + 4 );
		}
		if (!ismasked){
			destoffset += (16 - ((destoffset &0xF)) &0xF);
		}

	}

	Z_QuickMapRender4000(); // put render info back

}


//
// P_LoadVertexes
//
void __near P_LoadVertexes(int16_t lump) {
	//mapvertex_t __far*			data;
	//mapvertex_t			ml;
	// Determine number of lumps:
	//  total lump length / vertex record length.
	uint16_t totalsize = W_LumpLength(lump);
	numvertexes = FastDiv32u16u(totalsize, sizeof(mapvertex_t));

	// Load data into cache.
	Z_QuickMapScratch_5000();

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	//data = (mapvertex_t __far*)SCRATCH_ADDRESS_5000;

	// Copy and convert vertex coordinates,
	// internal representation as fixed.
	FAR_memcpy(vertexes, SCRATCH_ADDRESS_5000, totalsize);


	// Free buffer memory.
 }


//
// P_LoadSegs
//
void __near P_LoadSegs(int16_t lump) {
 	mapseg_t  __far*          data;
	uint16_t                 i;
	mapseg_t __far*           ml;
	seg_render_t __far*              li_render;
	line_t __far*             ldef;
	uint16_t                 side;
	int16_t ldefsidenum;
	int16_t ldefothersidenum;
	int16_t sidesecnum;
	int16_t othersidesecnum;
	uint8_t ldefflags;
	int16_t mlv1;
	int16_t mlv2;
	int16_t mlangle;
	int16_t mloffset;
	int16_t mllinedef;
	// max segs doom1/2 like 2800. need 5600ish bytes
	int16_t __far* tempsecnums = MK_FP(0x5000, 0xc000);
	Z_QuickMapRender_4000To9000();

	numsegs = FastDiv3216u(W_LumpLength(lump), sizeof(mapseg_t));

	FAR_memset(seg_linedefs, 0xff, size_seg_linedefs + size_seg_sides);
	Z_QuickMapScratch_5000();

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	data = (mapseg_t __far*)SCRATCH_ADDRESS_5000;

	for (i = 0; i < numsegs; i++) {
		ml = &data[i];
		mlv1 = (ml->v1);
		mlv2 = (ml->v2);
		mlangle = ((ml->angle));// << 16;
		mloffset = ((ml->offset));// << 16;
		mllinedef = (ml->linedef);
		side = (ml->side);


		ldef = &lines[mllinedef];
		ldefsidenum = ldef->sidenum[side];
		ldefothersidenum = ldef->sidenum[side ^ 1];
		ldefflags = lineflagslist[mllinedef];


		sidesecnum = sides_render_9000[ldefsidenum].secnum;
		othersidesecnum = sides_render_9000[ldefothersidenum].secnum;


		seg_linedefs[i] = mllinedef;
		seg_sides[i] = side ? 1 : 0;
	
		li_render = &segs_render_9000[i];
		li_render->v1Offset = mlv1;
		li_render->v2Offset = mlv2;
	
		seg_normalangles_9000[i] = MOD_FINE_ANGLE((mlangle >> SHORTTOFINESHIFT) + FINE_ANG90);
		
		// precalculate, too?
		//li_render->fineangle = li_render->fineangle << SHORTTOFINESHIFT;


		li_render->offset = mloffset;
		li_render->sidedefOffset = ldefsidenum;

		tempsecnums[i <<1] = sidesecnum;
		if (ldefflags & ML_TWOSIDED)
			tempsecnums[(i <<1) + 1] = othersidesecnum;
		else
			tempsecnums[(i <<1) + 1] = SECNUM_NULL;

	}
	
	
	Z_QuickMapPhysics();
	Z_QuickMapScratch_5000();


	
	FAR_memcpy(segs_physics, MK_FP(0x5000, 0xc000), numsegs*4);

	


}



//
// P_LoadSubsectors
//
void __near P_LoadSubsectors(int16_t lump) {
	mapsubsector_t  __far*               data;
	uint16_t                 i;
	mapsubsector_t __far*     ms;
	numsubsectors = FastDiv32u16u(W_LumpLength(lump), sizeof(mapsubsector_t));
	FAR_memset(subsectors, 0, MAX_SUBSECTORS_SIZE);

	Z_QuickMapScratch_5000();

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	data = (mapsubsector_t __far*)SCRATCH_ADDRESS_5000;

	for (i = 0; i < numsubsectors; i++)
	{
		ms = &data[i];
		subsector_lines[i]  = (ms->nummapsectorsegs);
		subsectors[i].firstline = (ms->firstseg);

	}

}

 


//
// P_LoadSectors
//
void __near P_LoadSectors(int16_t lump) {
	mapsector_t __far*        data;
	uint16_t                 i;
	mapsector_t        ms;
	sector_t __far*           ss;
	sector_physics_t __near*   sp;
	// most tags are under 100, a couple are like 666 or 667 or 999 or other such special numbers.
	// we will special case those and fit it in 8 bits so allocations are smaller
	int16_t convertedtag;
	numsectors = FastDiv32u16u(W_LumpLength(lump), sizeof(mapsector_t));


	FAR_memset(sectors, 0, MAX_SECTORS_SIZE);
	memset(sectors_physics, 0, MAX_SECTORS_PHYSICS_SIZE);
	FAR_memset(sectors_soundorgs, 0, MAX_SECTORS_SOUNDORGS_SIZE);
	FAR_memset(sector_soundtraversed, 0, MAX_SECTORS_SOUNDTRAVERSED_SIZE);
	Z_QuickMapScratch_8000();

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_8000);
	data = (mapsector_t __far*)SCRATCH_ADDRESS_8000;

	ss = sectors;
	sp = sectors_physics;
	for (i = 0; i < numsectors; i++, ss++, sp++) {
		ms = data[i];
		convertedtag = ms.tag;
		// switch case compiles into bigger code...else if (convertedtag == 667) {
		if (convertedtag == 666) {
			convertedtag = TAG_666;
		} else if (convertedtag == 667) {
			convertedtag = TAG_667;
		} else if (convertedtag == 999) {
			convertedtag = TAG_999;
		} else if (convertedtag == 99) {
			convertedtag = TAG_99;
		} else if (convertedtag == 77) {
			convertedtag = TAG_77;
		} else if (convertedtag == 1323) {
			convertedtag = TAG_1323;
		} else if (convertedtag == 1044) {
			convertedtag = TAG_1044;
		} else if (convertedtag == 86) {
			convertedtag = TAG_86;
		} else if (convertedtag >= 55) {
			#ifdef CHECK_FOR_ERRORS
				I_Error("94 %i %i", convertedtag, i); // found (sector) line tag that was too high! %i %i
			#endif
		}
		ss->floorheight = (ms.floorheight) << SHORTFLOORBITS;
		ss->ceilingheight = (ms.ceilingheight) << SHORTFLOORBITS;
		ss->floorpic = R_FlatNumForName(ms.floorpic);
		ss->ceilingpic = R_FlatNumForName(ms.ceilingpic);
		ss->lightlevel = (ms.lightlevel);
		//ss->thinglistRef = NULL_THINKERREF;
		
		sp->tag = (convertedtag);
		sp->special = (ms.special);

 

	}

}


//
// P_LoadNodes
//
void __near P_LoadNodes(int16_t lump) {
	mapnode_t  __far*       data = (mapnode_t __far*)SCRATCH_ADDRESS_5000;
	uint16_t         i;
	node_t __far*     no;
	node_children_t __far*     no_children;

	mapnode_t	currentdata;
	
	numnodes = FastDiv32u16u(W_LumpLength(lump), sizeof(mapnode_t));

	Z_QuickMapRender_4000To9000();
	Z_QuickMapScratch_5000();
	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);

	for (i = 0; i < numnodes; i++) {
		currentdata = data[i];
		no = &nodes[i];
		no_children = &node_children[i];

		no->x = (currentdata.x);
		no->y = (currentdata.y);
		no->dx = (currentdata.dx);
		no->dy = (currentdata.dy);

		no_children->children[0] = (currentdata.children[0]);
		no_children->children[1] = (currentdata.children[1]);

		FAR_memcpy(&nodes_render[i], currentdata.bbox, 16);

 	}
	Z_QuickMapPhysics();

}





 

 







//
// P_LoadThings
//
void __near P_LoadThings(int16_t lump) {
	mapthing_t  __far*		data;
	uint16_t                 i;
	mapthing_t         mt;
	uint16_t                 numthings;
	boolean             spawn;
	
	FAR_memset(nightmarespawns, 0, sizeof(mapthing_t) * MAX_THINKERS);
	Z_QuickMapScratch_8000();

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_8000);
	data = (mapthing_t __far*)SCRATCH_ADDRESS_8000;

	numthings = FastDiv32u16u(W_LumpLength(lump), sizeof(mapthing_t));


	for (i = 0; i < numthings; i++) {
		mt = data[i];
		spawn = true;

		// skip player1
		if (mt.type == 1) {
			playerMobjRef = i;
			playerMobj 		= playerMobjMakerExpression;
		    playerMobj_pos  = playerMobj_posMakerExpression;
		}

		// Do not spawn cool, new monsters if !commercial
		if (!commercial) {
			switch (mt.type) {
				case 68:  // Arachnotron
				case 64:  // Archvile
				case 88:  // Boss Brain
				case 89:  // Boss Shooter
				case 69:  // Hell Knight
				case 67:  // Mancubus
				case 71:  // Pain Elemental
				case 65:  // Former Human Commando
				case 66:  // Revenant
				case 84:  // Wolf SS
					spawn = false;
					break;
			}
		}
		if (spawn == false) {
			break;
		}
		// Do spawn all other stuff. 
	
		P_SpawnMapThingCallThrough(mt, i);
	


	}

}


//
// P_LoadLineDefs
// Also counts secret lines for intermissions.
//
void __near P_LoadLineDefs(int16_t lump) {
	maplinedef_t  __far*		data;
	uint16_t                 i;
	maplinedef_t __far*       mld;
	line_t __far*             ld;
	line_physics_t __far*             ld_physics;
	vertex_t __far*           v1;
	vertex_t __far*           v2;
	int16_t side0secnum;
	int16_t side1secnum;
	int16_t v1x;
	int16_t v1y;
	int16_t v2x;
	int16_t v2y;
	int16_t mldflags;
	uint8_t mldspecial;
	int16_t mldv1;
	int16_t mldv2;
	int16_t mldsidenum0;
	int16_t mldsidenum1;
	int16_t convertedtag;
	
	numlines = FastDiv32u16u(W_LumpLength(lump), sizeof(maplinedef_t));

	FAR_memset(lines, 0, MAX_LINES_SIZE);
	FAR_memset(lines_physics, 0, MAX_LINES_PHYSICS_SIZE);
	FAR_memset(seenlines_6800, 0, MAX_SEENLINES_SIZE);
	Z_QuickMapScratch_5000();

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	data = (maplinedef_t __far*)SCRATCH_ADDRESS_5000;

	// put side_render active
	Z_QuickMapRender4000();
	
	
	for (i = 0; i < numlines; i++) {
		mld = &data[i];

		mldflags = (mld->flags);
		mldspecial = (mld->special);
		convertedtag = (mld->tag);
		mldv1 = (mld->v1);
		mldv2 = (mld->v2);
		mldsidenum0 = (mld->sidenum[0]);
		mldsidenum1 = (mld->sidenum[1]);
		 

		v1 = &vertexes[mldv1];
		v2 = &vertexes[mldv2];
		v1x = v1->x;
		v1y = v1->y;
		v2x = v2->x;
		v2y = v2->y;

		ld = &lines[i];
		ld_physics = &lines_physics[i];

		ld->sidenum[0] = mldsidenum0;
		ld->sidenum[1] = mldsidenum1;

		lineflagslist[i] = mldflags&0xff;

		 
		if (convertedtag == 666) {
			convertedtag = TAG_666;
		} else if (convertedtag == 667) {
			convertedtag = TAG_667;
		} else if (convertedtag == 999) {
			convertedtag = TAG_999;
		} else if (convertedtag == 99) {
			convertedtag = TAG_99;
		} else if (convertedtag == 77) {
			convertedtag = TAG_77;
		} else if (convertedtag == 1323) {
			convertedtag = TAG_1323;
		} else if (convertedtag == 1044) {
			convertedtag = TAG_1044;
		} else if (convertedtag == 86) {
			convertedtag = TAG_86;
		} else if (convertedtag >= 55) {
			//I_Error("93 %i %i %i", convertedtag, i, numlines);// found (line) line tag that was too high! %i %i
		}

		ld_physics->tag = convertedtag;
		ld_physics->v1Offset = mldv1;
		ld_physics->v2Offset = mldv2;
		ld_physics->dx = v2x - v1x;
		ld_physics->dy = v2y - v1y;
		ld_physics->special = mldspecial;

		// setting the slopetype in the high bits of v2Offset
		if (!ld_physics->dx) {
			ld_physics->v2Offset |= (ST_VERTICAL_HIGH);
		} else if (!ld_physics->dy) {
			ld_physics->v2Offset |= (ST_HORIZONTAL_HIGH);
		} else {
			if (FixedDiv(ld_physics->dy, ld_physics->dx) > 0) {
				ld_physics->v2Offset |= (ST_POSITIVE_HIGH);
			} else {
				ld_physics->v2Offset |= (ST_NEGATIVE_HIGH);
			}
		}

		side0secnum = sides_render[mldsidenum0].secnum;
		side1secnum = sides_render[mldsidenum1].secnum;

		if (mldsidenum0 != -1) {
			ld_physics->frontsecnum = side0secnum;
		}
		else {
			ld_physics->frontsecnum = SECNUM_NULL;
		}
		if (mldsidenum1 != -1) {
			ld_physics->backsecnum = side1secnum;
		}
		else {
			ld_physics->backsecnum = SECNUM_NULL;
		}
	}

	 

	Z_QuickMapPhysics();
}


//
// P_LoadSideDefs
//
void __near P_LoadSideDefs(int16_t lump) {
	mapsidedef_t __far*               data;
	uint16_t                 i;
	mapsidedef_t __far*       msd;
	side_t __far*             sd;
	side_render_t __far*             sd_render;
	uint16_t toptex;
	uint16_t bottex;
	uint16_t midtex;
	int8_t texnametop[8];
	int8_t texnamemid[8];
	int8_t texnamebot[8];
	texsize_t msdtextureoffset;
	texsize_t msdrowoffset;
	int16_t msdsecnum;
	int32_t lumpsize;
	int32_t offset = 0;
	int16_t indexoffset = 0;
	Z_QuickMapRender_4000To9000();
	Z_QuickMapRender_9000To6000(); //for R_TextureNumForName
 
	lumpsize = W_LumpLength(lump);
	numsides = FastDiv32u16u(lumpsize, sizeof(mapsidedef_t));

	Z_QuickMapScratch_5000();
	// this will be a little different. ths can be over 64k so lets load one page at a time (like with titlepics)
	W_CacheLumpNumDirectFragment(lump, SCRATCH_ADDRESS_5000, 0);
	
	data = (mapsidedef_t __far*)SCRATCH_ADDRESS_5000;

	for (i = 0; i < numsides; i++) {
		
		// when sides is too big for one 64k block
		//  and needs to have a 2nd fragment paged in.
		if ((i-indexoffset) == 546){
			// reload...
			offset += 16380;
			indexoffset = i;
			W_CacheLumpNumDirectFragment(lump, SCRATCH_ADDRESS_5000, offset);
		}

		msd = &data[i-indexoffset];

		msdtextureoffset = (msd->textureoffset);
		msdrowoffset = (msd->rowoffset);
		msdsecnum = (msd->sector);
		
		FAR_memcpy(texnametop, msd->toptexture, 8);
		FAR_memcpy(texnamebot, msd->bottomtexture, 8);
		FAR_memcpy(texnamemid, msd->midtexture, 8);

  
		toptex = R_TextureNumForName(texnametop);
		bottex = R_TextureNumForName(texnamebot);
		midtex = R_TextureNumForName(texnamemid);

		sd = &sides[i];
		sd->toptexture = toptex;
		sd->bottomtexture = bottex;
		sd->midtexture = midtex;
		sd->textureoffset = msdtextureoffset;

		sd_render = &sides_render_9000[i];
		sd_render->rowoffset = msdrowoffset;
		sd_render->secnum = msdsecnum;


	}


	Z_QuickMapPhysics();

}


//
// P_LoadBlockMap
//
void __near P_LoadBlockMap(int16_t lump) {
	uint16_t         count;
	Z_QuickMapPhysics();

	W_CacheLumpNumDirect(lump, (byte __far*)blockmaplump);
	


	bmaporgx = blockmaplump[0];
	bmaporgy = blockmaplump[1];
	bmapwidth = blockmaplump[2];
	bmapheight = blockmaplump[3];


	// clear out mobj chains

	// count = sizeof(THINKERREF) * bmapwidth*bmapheight;
	

	FAR_memset(blocklinks, 0, MAX_BLOCKLINKS_SIZE);
}



//
// P_GroupLines
// Builds sector line lists and subsector sector numbers.
// Finds block bounding boxes for sectors.
//
void __near P_GroupLines(void) {
	uint16_t                 i;
	uint16_t                 j;
	line_physics_t __far*     li_physics;
	int16_t             bbox[4];
	int16_t             block;
	int16_t				previouslinebufferindex;
	int16_t				firstlinenum;
	int16_t				sidedefOffset;
	int16_t				linev1Offset;
	int16_t				linev2Offset;
	int16_t				linebacksecnum;
	int16_t				linefrontsecnum;
	int16_t				linebufferindex;
	int16_t				sidesecnum;
	int16_t				sectorlinecount;
	fixed_t_union		tempv1;
	fixed_t_union		tempv2;
	uint16_t                 total;
	
	Z_QuickMapRender_4000To9000();

	// look up sector number for each subsector
	for (i = 0; i < numsubsectors; i++) {
		firstlinenum = subsectors[i].firstline;
		
		sidedefOffset = segs_render_9000[firstlinenum].sidedefOffset;
		sidesecnum = sides_render_9000[sidedefOffset].secnum;
		subsectors[i].secnum = sidesecnum;

	}

	Z_QuickMapPhysics();
	// count number of lines in each sector
	total = 0;
	for (i = 0; i < numlines; i++) {
		li_physics = &lines_physics[i];
		linebacksecnum = li_physics->backsecnum;
		linefrontsecnum = li_physics->frontsecnum;
		total++;
		sectors[linefrontsecnum].linecount++;

		if (linebacksecnum != -1 && linebacksecnum != linefrontsecnum) {
			sectors[linebacksecnum].linecount++;
			total++;
		}
	}

	// build line tables for each sector        

	linebufferindex = 0;

	tempv1.h.fracbits = 0;
	tempv2.h.fracbits = 0;


	for (i = 0; i < numsectors; i++) {
		//M_ClearBox16
		bbox[BOXTOP] = bbox[BOXRIGHT] = MINSHORT;
		bbox[BOXBOTTOM] = bbox[BOXLEFT] = MAXSHORT;

		sectorlinecount = sectors[i].linecount;

		sectors[i].linesoffset = linebufferindex;
		previouslinebufferindex = linebufferindex;
	 
		for (j = 0; j < numlines; j++) {
			li_physics = &lines_physics[j];
			linev1Offset = li_physics->v1Offset;
			linev2Offset = li_physics->v2Offset & VERTEX_OFFSET_MASK;

			if (li_physics->frontsecnum == i || li_physics->backsecnum == i) {
				linebuffer[linebufferindex] = j;
				linebufferindex++;
				M_AddToBox16(vertexes[linev1Offset].x, vertexes[linev1Offset].y, bbox);
				M_AddToBox16(vertexes[linev2Offset].x, vertexes[linev2Offset].y, bbox);
			}
		}
#ifdef CHECK_FOR_ERRORS
		if (linebufferindex - previouslinebufferindex != sectorlinecount) {
			I_Error("P_GroupLines: miscounted %i %i   iteration %i      %i != (%i - %i)", linebuffer, sectors[i].linesoffset,  i, sectors[i].linecount, linebufferindex , previouslinebufferindex);
		}
#endif

		// set the degenmobj_t to the middle of the bounding box
		
		// todo does this have to be 32 bit? eventually investigate...
		sectors_soundorgs[i].soundorgX = (bbox[BOXRIGHT] + bbox[BOXLEFT]) >> 1;
		sectors_soundorgs[i].soundorgY = (bbox[BOXTOP] + bbox[BOXBOTTOM]) >> 1;

		// adjust bounding box to map blocks
		block = (bbox[BOXTOP] - bmaporgy + MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block >= bmapheight ? bmapheight - 1 : block;
		sectors_physics[i].blockbox[BOXTOP] = block;

		block = (bbox[BOXBOTTOM] - bmaporgy - MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block < 0 ? 0 : block;
		sectors_physics[i].blockbox[BOXBOTTOM] = block;

		block = (bbox[BOXRIGHT] - bmaporgx + MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block >= bmapwidth ? bmapwidth - 1 : block;
		sectors_physics[i].blockbox[BOXRIGHT] = block;

		block = (bbox[BOXLEFT] - bmaporgx - MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block < 0 ? 0 : block;
		sectors_physics[i].blockbox[BOXLEFT] = block;
	}



}


//
// P_InitThinkers
//
void __near P_InitThinkersCallThrough();

/*
void  __far P_InitThinkers (void) {
	int16_t i;
	thinkerlist[0].next = 1;
	thinkerlist[0].prevFunctype = 1;


	for (i = 0; i < MAX_THINKERS; i++) {
		thinkerlist[i].prevFunctype = MAX_THINKERS;
	}

	currentThinkerListHead = 0;

}
 */
 


 // called in between levels, frees level stuff like sectors, frees thinkers, etc.
void __near Z_FreeConventionalAllocations() {
	int16_t i;

	// we should be paged to physics now - should be ok
	memset(thinkerlist, 0, MAX_THINKERS * sizeof(thinker_t));

	//erase the level data region
	FAR_memset(((byte __far*) baselowermemoryaddress), 0, (sfx_data_segment - base_lower_memory_segment) << 4);

	// todo make this area less jank. We want to free all the ems 4.0 region level data...
	// handles blockmaps and lines_physics...
	// do we really have to do this anyway?
	FAR_memset(MK_FP(0x7000, 0), 0, (states_segment - lines_physics_segment) << 4);
	
	FAR_memset(nightmarespawns, 0, sizeof(mapthing_t) * MAX_THINKERS);

	Z_QuickMapRender();
	//FAR_memset(MK_FP(0x7000, 0), 0, 65535);

	//reset texturee cache
	// FAR_memset(mobjposlist_6800, 0x00, size_mobjposlist); // todo this fix better. this makes a martypc bug go away due to unitinitialized memory, but what wasnt written to?
	FAR_memset(compositetexturepage, 0xFF, sizeof(uint8_t) * (MAX_TEXTURES));
	FAR_memset(compositetextureoffset,0xFF, sizeof(uint8_t) * (MAX_TEXTURES));
	memset(usedtexturepagemem, 00, sizeof(uint8_t) * NUM_TEXTURE_PAGES);
	
	FAR_memset(patchpage, 0xFF, sizeof(uint8_t) * (MAX_PATCHES));
	FAR_memset(patchoffset, 0xFF, sizeof(uint8_t) * (MAX_PATCHES));

	FAR_memset(spritepage, 0xFF, sizeof(uint8_t) * (MAX_SPRITE_LUMPS));
	FAR_memset(spriteoffset, 0xFF, sizeof(uint8_t) * (MAX_SPRITE_LUMPS));
	memset(usedspritepagemem, 00, sizeof(uint8_t) * NUM_SPRITE_CACHE_PAGES);

#ifdef FPS_DISPLAY
	fps_rendered_frames_since_last_measure = 0;
	fps_last_measure_start_tic = gametic;
#endif


	// put these all next to each other for a single memset..

	// L2 cache stuff

	flatcache_l2_head = 0;
	flatcache_l2_tail = NUM_FLAT_CACHE_PAGES-1;
	

	spritecache_l2_head = 0;
	spritecache_l2_tail = NUM_SPRITE_CACHE_PAGES-1;


	texturecache_l2_head = 0;
	texturecache_l2_tail = NUM_TEXTURE_PAGES-1;


	for (i = 0; i < NUM_FLAT_CACHE_PAGES; i++){
		flatcache_nodes[i].prev = i+1;
		flatcache_nodes[i].next = i-1;
	}
	flatcache_nodes[flatcache_l2_head].next = -1;
	flatcache_nodes[flatcache_l2_tail].prev = -1;

	for (i = 0; i < NUM_TEXTURE_PAGES; i++){
		texturecache_nodes[i].prev = i+1;
		texturecache_nodes[i].next = i-1;
		texturecache_nodes[i].pagecount = 0;
		texturecache_nodes[i].numpages = 0;
	}

	texturecache_nodes[texturecache_l2_head].next = -1;
	texturecache_nodes[texturecache_l2_tail].prev = -1;


	// just run thru the whole bunch in one go instead of multiple 
	for ( i = 0; i < NUM_SPRITE_CACHE_PAGES; i++) {
		spritecache_nodes[i].prev = i+1; // Mark unused entries
		spritecache_nodes[i].next = i-1; // Mark unused entries
		spritecache_nodes[i].pagecount = 0;
		spritecache_nodes[i].numpages = 0;
	}  

	spritecache_nodes[spritecache_l2_head].next = -1;
	spritecache_nodes[spritecache_l2_tail].prev = -1;




	// todo memcpy this all in asm?

	for ( i = 0; i < NUM_FLAT_CACHE_PAGES; i++) {
		allocatedflatsperpage[i] = 0;
	}  

	//FAR_memset(visplanepiclights, 0x00, size_visplanepiclights);
	FAR_memset(flatindex, 0xFF, size_flatindex);

	for (i = 0; i < MAX_FLATS; i++){
		flattranslation[i] = i;
	}
	for (i = 0; i < MAX_TEXTURES; i++){
		texturetranslation[i] = i;
	}

	
	currentflatpage[0] = 0;
	currentflatpage[1] = 1;
	currentflatpage[2] = 2;
	currentflatpage[3] = 3;

	lastflatcacheindicesused[0]= 0;
	lastflatcacheindicesused[1]= 1;
	lastflatcacheindicesused[2]= 2;
	lastflatcacheindicesused[3]= 3;


	Z_QuickMapPhysics();

	// reset ems cache settings
	for (i = 0; i < NUM_FLAT_L1_CACHE_PAGES; i ++){
		pageswapargs[pageswapargs_flatcache_offset + i * PAGE_SWAP_ARG_MULT] = _EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE+i);
	}	
	// L1 cache stuff
	for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES; i++) {
		activetexturepages[i] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		textureL1LRU[i] = i;
		pageswapargs[pageswapargs_rend_texture_offset +  i*PAGE_SWAP_ARG_MULT]  = _EPR(FIRST_TEXTURE_LOGICAL_PAGE + i);
		activenumpages[i] = 0;

		if (i < NUM_SPRITE_L1_CACHE_PAGES){
			activespritepages[i] = FIRST_SPRITE_CACHE_LOGICAL_PAGE + i;
			spriteL1LRU[i] = i;
			pageswapargs[pageswapargs_spritecache_offset + i*PAGE_SWAP_ARG_MULT]  = _EPR(FIRST_SPRITE_CACHE_LOGICAL_PAGE + i);
			activespritenumpages[i] = 0;
		}
	}

}


void __near PSetupEndFunc(){}
void __near D_INIT_STARTMARKER();


// clears dead initialization code.
void __near Z_ClearDeadCode() {
	byte __far *startaddr =	(byte __far*)D_INIT_STARTMARKER;
	byte __far *endaddr =		(byte __far*)P_Init;
	
	// accurate enough

	//8830 bytes or so
	//8978 currently - 05/29/24
	//8342           - 06/01/24
	//9350           - 10/07/24
	//11222          - 01/18/25		at this point like 3000 bytes to save.
	//11284          - 06/30/25   
	//11470          - 08/26/25
	//9798           - 09/12/25	   ; note 8196 is "max". or "min". there are probably some funcs that can be moved into init like wad or file funcs only used in init though.
	//9398           - 09/13/25	
	//9602           - 09/20/25	   - added some extra code into that region. still need to do z_init, p_init
	//9570           - 09/25/25	   
	//9634           - 12/21/25    - sb_init not yet added. needs to go soon.
	//10706          - 12/21/25    - sb_init asm added
	//10370          - 12/21/25    - sb_init asm fixed
	//9528           - 12/25/25    - r_init asm, some p_init work
	//8723           - 12/27/25    - p_init done

	uint16_t size = endaddr - startaddr-16;
	FILE* fp;


	angle_t __far*  dest;
	
	tantoangle_segment = FP_SEG(startaddr) + 1;
	// I_Error("size: %i", size);
	dest =  (angle_t __far* )MK_FP(tantoangle_segment, 0);
	fp = fopen("DOOMDATA.BIN", "rb");
	fseek(fp, TANTOA_DOOMDATA_OFFSET, SEEK_SET);
	locallib_far_fread(dest, 4 * 2049, fp);
	fclose(fp);

}

// logging functions to assist in finding desyncs.

/*

int16_t lastgametic = -1;
int16_t thinkercount = 0;
void __near DoLog() {

	// mobj_t __near* mobj = (mobj_t __near*)(0x3CBC);
	// mobj_pos_t __far* mobj_pos = (mobj_pos_t __far*)(MK_FP(mobjposlist_6800_segment, 0x6f0));
    // FILE* fp = fopen("debuglog.txt", "ab");

	
	// fprintf(fp, "pos %li %i %i %lx %lx %lx %i %i %i\n", gametic, prndindex, thinkercount, playerMobj_pos->x, playerMobj_pos->y, playerMobj_pos->z, 
	// mobj->tics, mobj_pos->stateNum, mobj->type);
    
	
	
	// fclose(fp);


	// if (gametic == 200){
	// 	I_Error("done %i", gameskill);
	// }


}


int16_t counter = 0;
int16_t setval = 0;
boolean is_init = false;


void __far MainLogger (uint16_t ax, uint16_t dx, uint16_t bx, uint16_t cx){
    // if (lastgametic != gametic){
	// 	lastgametic = gametic;
	// 	thinkercount = 0;
	// }
	// thinkercount++;
	// if (gametic == 123){
	// 	mobj_t __near* mobj = (mobj_t __near*) ax;
	// 	mobj_pos_t __far* mobj_pos = (mobj_t __far*) (MK_FP(cx, bx));
	// 	FILE* fp;
	// 	if (is_init){
	// 		fp = fopen("tick.txt", "ab");
	// 	} else {
	// 		fp = fopen("tick.txt", "wb");
	// 		is_init = true;
	// 	}
	// 	fprintf(fp, "%li %i %i %x %x %x %i %i\n", gametic, prndindex, counter, ax, dx, bx,
	// 		mobj->type, mobj->tics
	// 	);
	// 	fclose(fp);

	// 	if (counter == 71){
	// 		// mobj_t* mobj = (mobj_t*) bx;
	// 		// I_Error("vals %i %i", mobj->secnum, mobj->type);
	// 		// 1 74
	// 		// mobj_pos_t __far* mobjpos = (mobj_pos_t __far*)MK_FP(mobjposlist_6800_segment, (bx / 44) * 24);
	// 		// I_Error("vals %lx %lx", mobjpos->x, mobjpos->y);
	// 		// I_Error("prnd %i", prndindex);
	// 		setval = 1;
	// 	}

	// 	counter++;

	// }

}

void __far MainLogger (uint16_t ax, uint16_t dx, uint16_t bx, uint16_t cx){
	// int16_t __far *loc = MK_FP(dx, bx);
	// int16_t i;
	// FILE* fp = fopen("sound.txt", "ab");
	// fprintf(fp, "%x %x:  ", ax, cx);
	// for (i = 0; i < 8; i ++){
	// 	fprintf(fp, "%x %x %x  ", loc[i*3], loc[i*3+1], loc[i*3+2]);
	// }
	// fprintf(fp, "\n"  );

	// for (i = 0; i < NUM_SFX_TO_MIX; i++){
	// 	fprintf(fp, "%x  ", sb_voicelist[i].sfx_id);
	// }
	// fprintf(fp, "\n");

	// fclose(fp);

	I_Error("%x %x %x %x", ax, bx, cx, dx);
}
*/
