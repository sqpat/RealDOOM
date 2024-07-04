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


#include <math.h>

#include "z_zone.h"

#include "m_misc.h"

#include "g_game.h"

#include "i_system.h"
#include "w_wad.h"

#include "doomdef.h"
#include "p_local.h"
#include "p_setup.h"

#include "s_sound.h"

#include "v_video.h"

#include "doomstat.h"
#include <dos.h>
#include "memory.h"




//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
int16_t             numvertexes;
int16_t             numsegs;
int16_t             numsectors;
int16_t             numsubsectors;
int16_t             numnodes;
int16_t             numlines;
int16_t             numsides;


#ifdef PRECALCULATE_OPENINGS
lineopening_t __far*	lineopenings;
#endif

// BLOCKMAP
// Created from axis aligned bounding box
// of the map, a rectangular array of
// blocks of size ...
// Used to speed up collision detection
// by spatial subdivision in 2D.
//
// Blockmap size.
int16_t             bmapwidth;
int16_t             bmapheight;     // size in mapblocks

								// offsets in blockmap are from here

// origin of block map
int16_t         bmaporgx;
int16_t         bmaporgy;

 
 
 
uint16_t   __far  R_TextureNumForName(int8_t* name);
uint8_t    __far R_FlatNumForName(int8_t* name);

void __near P_LoadVertexes(int16_t lump);
void __near P_LoadSectors(int16_t lump);
void __near P_LoadSubsectors(int16_t lump);
void __near P_LoadNodes(int16_t lump);
void __near P_LoadSideDefs(int16_t lump);
void __near P_LoadLineDefs(int16_t lump);
void __near P_LoadBlockMap(int16_t lump);
void __near P_LoadThings(int16_t lump);
void __near P_LoadSegs(int16_t lump);	
void __near P_InitThinkers (void);
void __near Z_FreeConventionalAllocations();
void __near P_GroupLines();
void __far P_SpawnSpecials(void);

//
// P_SetupLevel
//
// stick this at top so entry point is always xxxx:0000
void __far P_SetupLevel (int8_t episode, int8_t map, skill_t skill) {
	int8_t        lumpname[9];
	int16_t         lumpnum;
	
	
	//I_Error("level is %i %i", episode, map);

	wminfo.partime = 180;
	player.killcount = player.secretcount = player.itemcount = 0;

	// Initial height of PointOfView
	// will be set by player think.
	player.viewz.w = 1;
	
	S_Start();
	Z_FreeConventionalAllocations();

	// TODO reset 32 bit counters to start values here..
	validcount = 1;

	P_InitThinkers();


	// find map name
	if (commercial) {
		sprintf(lumpname, "map%02d", map);
	}
	else
	{
		lumpname[0] = 'E';
		lumpname[1] = '0' + episode;
		lumpname[2] = 'M';
		lumpname[3] = '0' + map;
		lumpname[4] = 0;
	}

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
#ifdef PRECALCULATE_OPENINGS
	P_CacheLineOpenings();
#endif


	 
	P_LoadThings(lumpnum + ML_THINGS);
 

	// set up world state
	P_SpawnSpecials();
	
	Z_QuickMapRender();
	Z_QuickMapRenderPlanes();

	// prep sky texture
								// lump lookup
	R_LoadPatchColumns( ((int16_t __far *)&(texturecolumnlumps_bytes[texturepatchlump_offset[skytexture]]))[0], skytexture_texture_bytes, false);
	

	// precalculate the offsets table location...

	Z_QuickMapPhysics();
 


	// preload graphics
	
	/*
	if (precache)
		R_PrecacheLevel();
*/


}



//
// P_LoadVertexes
//
void __near P_LoadVertexes(int16_t lump) {
	//mapvertex_t __far*			data;
	uint16_t                 i;
	//mapvertex_t			ml;
	// Determine number of lumps:
	//  total lump length / vertex record length.
	uint16_t totalsize = W_LumpLength(lump);
	numvertexes = totalsize / sizeof(mapvertex_t);

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
	seg_t __far*              li;
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

	numsegs = W_LumpLength(lump) / sizeof(mapseg_t);

	FAR_memset(segs, 0xff, MAX_SEGS_SIZE);
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
		ldefflags = ldef->flags;


		sidesecnum = sides_render_9000[ldefsidenum].secnum;
		othersidesecnum = sides_render_9000[ldefothersidenum].secnum;


		li = &segs[i];
		li->side = side ? 1 : 0;
		li->linedefOffset = mllinedef;
	
		li_render = &segs_render_9000[i];
		li_render->v1Offset = mlv1;
		li_render->v2Offset = mlv2;
	
		li_render->fineangle = mlangle >> SHORTTOFINESHIFT;
		li_render->offset = mloffset;
		li_render->sidedefOffset = ldefsidenum;

		tempsecnums[i * 2] = sidesecnum;
		if (ldef->flags & ML_TWOSIDED)
			tempsecnums[i * 2 + 1] = othersidesecnum;
		else
			tempsecnums[i * 2 + 1] = SECNUM_NULL;

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
	subsector_t __far*        ss;
	numsubsectors = W_LumpLength(lump) / sizeof(mapsubsector_t);
	FAR_memset(subsectors, 0, MAX_SUBSECTORS_SIZE);

	Z_QuickMapScratch_5000();

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	data = (mapsubsector_t __far*)SCRATCH_ADDRESS_5000;

	for (i = 0; i < numsubsectors; i++)
	{
		ms = &data[i];
		ss = &subsectors[i];
		ss->numlines = (ms->numsegs);
		ss->firstline = (ms->firstseg);

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
	sector_physics_t __far*   sp;
	// most tags are under 100, a couple are like 666 or 667 or 999 or other such special numbers.
	// we will special case those and fit it in 8 bits so allocations are smaller
	int16_t convertedtag;
	numsectors = W_LumpLength(lump) / sizeof(mapsector_t);


	FAR_memset(sectors, 0, MAX_SECTORS_SIZE);
	FAR_memset(sectors_physics, 0, MAX_SECTORS_PHYSICS_SIZE);
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
	uint16_t         j;
	uint16_t         k;
	node_t __far*     no;

	mapnode_t	currentdata;
	
	numnodes = W_LumpLength(lump) / sizeof(mapnode_t);

	Z_QuickMapRender_4000To9000();
	Z_QuickMapScratch_5000();
	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);

	for (i = 0; i < numnodes; i++) {
		currentdata = data[i];
		no = &nodes[i];

		no->x = (currentdata.x);
		no->y = (currentdata.y);
		no->dx = (currentdata.dx);
		no->dy = (currentdata.dy);

		no->children[0] = (currentdata.children[0]);
		no->children[1] = (currentdata.children[1]);

		FAR_memcpy(&nodes_render[i], currentdata.bbox, 16);

 	}
	Z_QuickMapPhysics();

}





 

void __far G_PlayerReborn();
 


extern mobj_t __far* setStateReturn;




void __far P_SpawnMapThing(mapthing_t mthing, int16_t key);


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

	numthings = W_LumpLength(lump) / sizeof(mapthing_t);

	// first do a run to search for the player1 object as we want to force it to be thing 1 in memory.
	for (i = 0; i < numthings; i++) {
		mt = data[i];

		// do player1
		if (mt.type == 1) {
			P_SpawnMapThing(data[i], i);
			break;
		}

	}
	//return;
	for (i = 0; i < numthings; i++) {
		mt = data[i];
		spawn = true;

		// skip player1
		if (mt.type == 1) {
			continue;
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
	
		P_SpawnMapThing(mt, i);
	


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
	
	numlines = W_LumpLength(lump) / sizeof(maplinedef_t);

	FAR_memset(lines, 0, MAX_LINES_SIZE);
	FAR_memset(lines_physics, 0, MAX_LINES_PHYSICS_SIZE);
	FAR_memset(seenlines, 0, MAX_SEENLINES_SIZE);
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

		ld->flags = mldflags&0xff;

		 
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
 
	lumpsize = W_LumpLength(lump);
	numsides = lumpsize / sizeof(mapsidedef_t);

	Z_QuickMapScratch_5000();
	// this will be a little different. ths can be over 64k so lets load one page at a time (like with titlepics)
	W_CacheLumpNumDirectFragment(lump, SCRATCH_ADDRESS_5000, 0);
	
	data = (mapsidedef_t __far*)SCRATCH_ADDRESS_5000;

	for (i = 0; i < numsides; i++) {
		
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
/*
		if (toptex > 0){
			toptex = R_TextureNumForName("WOOD12");
		}
		if (bottex > 0){
			bottex = R_TextureNumForName("WOOD12");
		}
		if (midtex > 0){
			midtex = R_TextureNumForName("WOOD12");
		}
		*/

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

	count = sizeof(THINKERREF) * bmapwidth*bmapheight;
	

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
				M_AddToBox16(bbox, vertexes[linev1Offset].x, vertexes[linev1Offset].y);
				M_AddToBox16(bbox, vertexes[linev2Offset].x, vertexes[linev2Offset].y);
			}
		}
#ifdef CHECK_FOR_ERRORS
		if (linebufferindex - previouslinebufferindex != sectorlinecount) {
			I_Error("P_GroupLines: miscounted %i %i   iteration %i      %i != (%i - %i)", linebuffer, sectors[i].linesoffset,  i, sectors[i].linecount, linebufferindex , previouslinebufferindex);
		}
#endif

		// set the degenmobj_t to the middle of the bounding box
		

		sectors_physics[i].soundorgX = (bbox[BOXRIGHT] + bbox[BOXLEFT]) / 2;
		sectors_physics[i].soundorgY = (bbox[BOXTOP] + bbox[BOXBOTTOM]) / 2;

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

extern int16_t currentThinkerListHead;

//
// P_InitThinkers
//
void  __near P_InitThinkers (void) {
	int16_t i;
	thinkerlist[0].next = 1;
	thinkerlist[0].prevFunctype = 1;


	for (i = 0; i < MAX_THINKERS; i++) {
		thinkerlist[i].prevFunctype = MAX_THINKERS;
	}

	currentThinkerListHead = 0;

}
 
 


 
extern int16_t spriteLRU[4];
extern int16_t activespritepages[4];
 
extern int32_t totalpatchsize;


extern int16_t activetexturepages[4]; // always gets reset to defaults at start of frame
extern int16_t textureLRU[4];
extern uint8_t activenumpages[4]; // always gets reset to defaults at start of frame
extern int16_t currentflatpage[4];
extern uint8_t activespritenumpages[4];


extern int8_t spritecache_head;
extern int8_t spritecache_tail;

extern int8_t flatcache_head;
extern int8_t flatcache_tail;

extern int8_t allocatedflatsperpage[NUM_FLAT_CACHE_PAGES];

extern int8_t patchcache_head;
extern int8_t patchcache_tail;

extern int8_t texturecache_head;
extern int8_t texturecache_tail;

extern uint8_t usedcompositetexturepagemem[NUM_TEXTURE_PAGES];
extern uint8_t usedpatchpagemem[NUM_PATCH_CACHE_PAGES];
extern uint8_t usedspritepagemem[NUM_SPRITE_CACHE_PAGES];
extern int8_t skytextureloaded;

extern int32_t fps_rendered_frames_since_last_measure;
extern ticcount_t fps_last_measure_start_tic;


#define STATIC_CONVENTIONAL_BLOCK_SIZE DESIRED_UMB_SIZE << 4

 // called in between levels, frees level stuff like sectors, frees thinkers, etc.
void __near Z_FreeConventionalAllocations() {
	int16_t i;

	// we should be paged to physics now - should be ok
	FAR_memset(thinkerlist, 0, MAX_THINKERS * sizeof(thinker_t));

	//erase the level data region
	FAR_memset(((byte __far*) uppermemoryblock), 0, size_segs);

	// todo make this area less jank. We want to free all the ems 4.0 region level data...
	FAR_memset(MK_FP(0x7000, 0), 0, 65535);
	
	FAR_memset(nightmarespawns, 0, sizeof(mapthing_t) * MAX_THINKERS);

	Z_QuickMapRender();
	//FAR_memset(MK_FP(0x7000, 0), 0, 65535);

	//reset texturee cache
	FAR_memset(compositetexturepage, 0xFF, sizeof(uint8_t) * (MAX_TEXTURES));
	FAR_memset(compositetextureoffset,0xFF, sizeof(uint8_t) * (MAX_TEXTURES));
	memset(usedcompositetexturepagemem, 00, sizeof(uint8_t) * NUM_TEXTURE_PAGES);
	
	FAR_memset(patchpage, 0xFF, sizeof(uint8_t) * (MAX_PATCHES));
	FAR_memset(patchoffset, 0xFF, sizeof(uint8_t) * (MAX_PATCHES));
	memset(usedpatchpagemem, 00, sizeof(uint8_t) * NUM_PATCH_CACHE_PAGES);

	FAR_memset(spritepage, 0xFF, sizeof(uint8_t) * (MAX_SPRITE_LUMPS));
	FAR_memset(spriteoffset, 0xFF, sizeof(uint8_t) * (MAX_SPRITE_LUMPS));
	memset(usedspritepagemem, 00, sizeof(uint8_t) * NUM_SPRITE_CACHE_PAGES);

#ifdef FPS_DISPLAY
	fps_rendered_frames_since_last_measure = 0;
	fps_last_measure_start_tic = gametic;
#endif

	skytextureloaded = 0;

	spritecache_head = -1;
	spritecache_tail = -1;

	flatcache_head = -1;
	flatcache_tail = -1;


	patchcache_head = -1;
	patchcache_tail = -1;

	texturecache_head = -1;
	texturecache_tail = -1;

	// just run thru the whole bunch in one go instead of multiple 
	for ( i = 0; i < NUM_SPRITE_CACHE_PAGES+NUM_FLAT_CACHE_PAGES+NUM_PATCH_CACHE_PAGES+NUM_TEXTURE_PAGES; i++) {
		spritecache_nodes[i].prev = -1; // Mark unused entries
		spritecache_nodes[i].next = -1; // Mark unused entries
		spritecache_nodes[i].pagecount = 0;
	}  

	for ( i = 0; i < NUM_FLAT_CACHE_PAGES; i++) {
		allocatedflatsperpage[i] = 0;
	}  



	FAR_memset(flatindex, 0xFF, sizeof(uint8_t) * numflats);
	
	currentflatpage[0] = -1;
	currentflatpage[1] = -1;
	currentflatpage[2] = -1;
	currentflatpage[3] = -1;

	Z_QuickMapPhysics();

	totalpatchsize = 0;

	for (i = 0; i < 4; i++) {
		activetexturepages[i] = FIRST_TEXTURE_LOGICAL_PAGE + i;
		textureLRU[i] = i;
		activespritepages[i] = FIRST_SPRITE_CACHE_LOGICAL_PAGE + i;
		spriteLRU[i] = i;

		pageswapargs[pageswapargs_rend_offset + i * 2]	  = FIRST_TEXTURE_LOGICAL_PAGE + i;
		pageswapargs[pageswapargs_spritecache_offset + i * 2] = FIRST_SPRITE_CACHE_LOGICAL_PAGE + i;

		activenumpages[i] = 0;
		activespritenumpages[i] = 0;
	}

}


void __near PSetupEndFunc(){}


