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

#include "doomstat.h"


void    P_SpawnMapThing(mapthing_t*    mthing);

//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
int             numvertexes;
MEMREF       vertexesRef;

int             numsegs;
//seg_t*          segs;
MEMREF                  segsRef;

int             numsectors;
sector_t*       sectors;

int             numsubsectors;
//subsector_t*    subsectors;
MEMREF    subsectorsRef;

int             numnodes;
MEMREF          nodesRef;

int             numlines;
MEMREF			linesRef;

int             numsides;
MEMREF          sidesRef;

//short*          linebuffer;
MEMREF          linebufferRef;

// BLOCKMAP
// Created from axis aligned bounding box
// of the map, a rectangular array of
// blocks of size ...
// Used to speed up collision detection
// by spatial subdivision in 2D.
//
// Blockmap size.
int             bmapwidth;
int             bmapheight;     // size in mapblocks
short*          blockmap;       // int for larger maps

								// offsets in blockmap are from here
short*          blockmaplump;

// origin of block map
fixed_t         bmaporgx;
fixed_t         bmaporgy;

// for thing chains
MEMREF        blocklinks[NUM_BLOCKLINKS];


// REJECT
// For fast sight rejection.
// Speeds up enemy AI by skipping detailed
//  LineOf Sight calculation.
// Without special effect, this could be
//  used as a PVS lookup as well.
//
byte*           rejectmatrix;


// Maintain single and multi player starting spots.
#define MAX_DEATHMATCH_STARTS   10

mapthing_t      deathmatchstarts[MAX_DEATHMATCH_STARTS];
mapthing_t*     deathmatch_p;
mapthing_t      playerstarts[MAXPLAYERS];





//
// P_LoadVertexes
//
void P_LoadVertexes(int lump)
{
	byte*               data;
	int                 i;
	mapvertex_t*        ml;
	vertex_t*           li;

	// Determine number of lumps:
	//  total lump length / vertex record length.
	numvertexes = W_LumpLength(lump) / sizeof(mapvertex_t);

	// Allocate zone memory for buffer.
	vertexesRef = Z_MallocEMSNew(numvertexes * sizeof(vertex_t), PU_LEVEL, 0, ALLOC_TYPE_VERTEXES);

	// Load data into cache.
	W_CacheLumpNumCheck(lump, 3);
	data = W_CacheLumpNum(lump, PU_STATIC);

	ml = (mapvertex_t *)data;
	li = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

	// Copy and convert vertex coordinates,
	// internal representation as fixed.
	for (i = 0; i < numvertexes; i++, li++, ml++)
	{
		li->x = SHORT(ml->x) << FRACBITS;
		li->y = SHORT(ml->y) << FRACBITS;
	}

	// Free buffer memory.
	Z_Free(data);
}



//
// P_LoadSegs
//
void P_LoadSegs(int lump)
{
	byte*               data;
	int                 i;
	mapseg_t*           ml;
	seg_t*              li;
	line_t*             ldef;
	int                 side;
	vertex_t*                       vertexes;
	seg_t*                          segs;
	short linedef;
	side_t*         sides;
	short ldefsidenum;
	short ldefothersidenum;
	short sidesecnum;
	short othersidesecnum;
	int ldefflags;
	line_t* lines;
	numsegs = W_LumpLength(lump) / sizeof(mapseg_t);
	segsRef = Z_MallocEMSNew(numsegs * sizeof(seg_t), PU_LEVEL, 0, ALLOC_TYPE_SEGMENTS);
	
	segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	memset(segs, 0xff, numsegs * sizeof(seg_t));
	W_CacheLumpNumCheck(lump, 4);
	data = W_CacheLumpNum(lump, PU_STATIC);

	ml = (mapseg_t *)data;
	
	for (i = 0; i < numsegs; i++, ml++) {
		side = SHORT(ml->side);
		linedef = SHORT(ml->linedef);

		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
		ldef = &lines[linedef];
		ldefsidenum = ldef->sidenum[side];
		ldefothersidenum = ldef->sidenum[side ^ 1];
		ldefflags = ldef->flags;


		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		sidesecnum = sides[ldefsidenum].secnum;
		othersidesecnum = sides[ldefothersidenum].secnum;


		segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);

		li = &segs[i];
		li->v1Offset = SHORT(ml->v1);
		li->v2Offset = SHORT(ml->v2);
	
		li->angle = (SHORT(ml->angle)) << 16;
		li->offset = (SHORT(ml->offset)) << 16;
		li->linedefOffset = SHORT(ml->linedef);
		li->sidedefOffset = ldefsidenum;

		li->frontsecnum = sidesecnum;
		if (ldefflags & ML_TWOSIDED)
			li->backsecnum = othersidesecnum;
		else
			li->backsecnum = SECNUM_NULL;

		//Z_RefIsActive(sidesRef);
		//Z_RefIsActive(vertexesRef);
		//Z_RefIsActive(segsRef);
	}

	Z_Free(data);
}



//
// P_LoadSubsectors
//
void P_LoadSubsectors(int lump)
{
	byte*               data;
	int                 i;
	mapsubsector_t*     ms;
	subsector_t*        ss;
	subsector_t*    subsectors;
	numsubsectors = W_LumpLength(lump) / sizeof(mapsubsector_t);
	subsectorsRef = Z_MallocEMSNew (numsubsectors * sizeof(subsector_t), PU_LEVEL, 0, ALLOC_TYPE_SUBSECS);

	W_CacheLumpNumCheck(lump, 5);
	data = W_CacheLumpNum(lump, PU_STATIC);

	ms = (mapsubsector_t *)data;
	subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);
	memset(subsectors, 0, numsubsectors * sizeof(subsector_t));
	ss = subsectors;

	for (i = 0; i < numsubsectors; i++, ss++, ms++)
	{
		ss->numlines = SHORT(ms->numsegs);
		ss->firstline = SHORT(ms->firstseg);
	}

	Z_Free(data);
}



//
// P_LoadSectors
//
void P_LoadSectors(int lump)
{
	byte*               data;
	int                 i;
	mapsector_t*        ms;
	sector_t*           ss;

	numsectors = W_LumpLength(lump) / sizeof(mapsector_t);
	sectors = Z_Malloc (numsectors * sizeof(sector_t), PU_LEVEL, 0);
	//I_Error("%i numsect", numsectors);
	// 143-177


	memset(sectors, 0, numsectors * sizeof(sector_t));
	W_CacheLumpNumCheck(lump, 6);
	data = W_CacheLumpNum(lump, PU_STATIC);

	ms = (mapsector_t *)data;
	ss = sectors;
	for (i = 0; i < numsectors; i++, ss++, ms++) {
		ss->floorheight = SHORT(ms->floorheight) << FRACBITS;
		ss->ceilingheight = SHORT(ms->ceilingheight) << FRACBITS;
		ss->floorpic = R_FlatNumForName(ms->floorpic);
		ss->ceilingpic = R_FlatNumForName(ms->ceilingpic);
		ss->lightlevel = SHORT(ms->lightlevel);
		ss->special = SHORT(ms->special);
		ss->tag = SHORT(ms->tag);
		ss->thinglistRef = NULL_MEMREF;
	}

	Z_Free(data);
}


//
// P_LoadNodes
//
void P_LoadNodes(int lump)
{
	byte*       data;
	int         i;
	int         j;
	int         k;
	mapnode_t*  mn;
	node_t*     no;
	node_t*		nodes;
	numnodes = W_LumpLength(lump) / sizeof(mapnode_t);
	nodesRef = Z_MallocEMSNew (numnodes * sizeof(node_t), PU_LEVEL, 0, ALLOC_TYPE_NODES);
	W_CacheLumpNumCheck(lump, 7);
	data = W_CacheLumpNum(lump, PU_STATIC);

	mn = (mapnode_t *)data;
	nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
	no = nodes;

	for (i = 0; i < numnodes; i++, no++, mn++)
	{
		no->x = SHORT(mn->x) << FRACBITS;
		no->y = SHORT(mn->y) << FRACBITS;
		no->dx = SHORT(mn->dx) << FRACBITS;
		no->dy = SHORT(mn->dy) << FRACBITS;
		for (j = 0; j < 2; j++)
		{
			no->children[j] = SHORT(mn->children[j]);
			for (k = 0; k < 4; k++)
				no->bbox[j][k] = SHORT(mn->bbox[j][k]) << FRACBITS;
		}
	}

	Z_Free(data);
}


//
// P_LoadThings
//
void P_LoadThings(int lump)
{
	byte*               data;
	int                 i;
	mapthing_t*         mt;
	int                 numthings;
	boolean             spawn;

	W_CacheLumpNumCheck(lump, 8);
	data = W_CacheLumpNum(lump, PU_STATIC);
	numthings = W_LumpLength(lump) / sizeof(mapthing_t);

	mt = (mapthing_t *)data;
	for (i = 0; i < numthings; i++, mt++)
	{
		spawn = true;

		// Do not spawn cool, new monsters if !commercial
		if (!commercial)
		{
			switch (mt->type)
			{
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
		if (spawn == false)
			break;

		// Do spawn all other stuff. 
		mt->x = SHORT(mt->x);
		mt->y = SHORT(mt->y);
		mt->angle = SHORT(mt->angle);
		mt->type = SHORT(mt->type);
		mt->options = SHORT(mt->options);

		P_SpawnMapThing(mt);
	}

	Z_Free(data);
}


//
// P_LoadLineDefs
// Also counts secret lines for intermissions.
//
void P_LoadLineDefs(int lump)
{
	byte*               data;
	int                 i;
	maplinedef_t*       mld;
	line_t*             ld;
	vertex_t*           v1;
	vertex_t*           v2;
	vertex_t*           vertexes;
	side_t* sides;
	line_t*         lines;
	short sidenum0;
	short sidenum1;
	short side0secnum;
	short side1secnum;
	fixed_t v1x;
	fixed_t v1y;
	fixed_t v2x;
	fixed_t v2y;

	numlines = W_LumpLength(lump) / sizeof(maplinedef_t);
	linesRef = Z_MallocEMSNew (numlines * sizeof(line_t), PU_LEVEL, 0, ALLOC_TYPE_LINES);
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

	memset(lines, 0, numlines * sizeof(line_t));
	W_CacheLumpNumCheck(lump, 9);
	data = W_CacheLumpNum(lump, PU_STATIC);

	mld = (maplinedef_t *)data;

	for (i = 0; i < numlines; i++, mld++, ld++) {


		sidenum0 = SHORT(mld->sidenum[0]);
		sidenum1 = SHORT(mld->sidenum[1]);
		
		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		side0secnum = sides[sidenum0].secnum;
		side1secnum = sides[sidenum1].secnum;
		vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
		v1 = &vertexes[SHORT(mld->v1)];
		v2 = &vertexes[SHORT(mld->v2)];
		v1x = v1->x;
		v1y = v1->y;
		v2x = v2->x;
		v2y = v2->y;

		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
		ld = &lines[i];

		ld->sidenum[0] = sidenum0;
		ld->sidenum[1] = sidenum1;

		ld->flags = SHORT(mld->flags);
		ld->special = SHORT(mld->special);
		ld->tag = SHORT(mld->tag);
		ld->v1Offset = SHORT(mld->v1);
		ld->v2Offset = SHORT(mld->v2);
		ld->dx = v2x - v1x;
		ld->dy = v2y - v1y;

		if (!ld->dx) {
			ld->slopetype = ST_VERTICAL;
		} else if (!ld->dy) {
			ld->slopetype = ST_HORIZONTAL;
		} else {
			if (FixedDiv(ld->dy, ld->dx) > 0) {
				ld->slopetype = ST_POSITIVE;
			} else {
				ld->slopetype = ST_NEGATIVE;
			}
		}

		if (v1x < v2x) {
			ld->bbox[BOXLEFT] = v1x;
			ld->bbox[BOXRIGHT] = v2x;
		} else {
			ld->bbox[BOXLEFT] = v2x;
			ld->bbox[BOXRIGHT] = v1x;
		}
		if (v1y < v2y) {
			ld->bbox[BOXBOTTOM] = v1y;
			ld->bbox[BOXTOP] = v2y;
		} else {
			ld->bbox[BOXBOTTOM] = v2y;
			ld->bbox[BOXTOP] = v1y;
		}

		if (sidenum0 != -1) {
			ld->frontsecnum = side0secnum;
		} else {
			ld->frontsecnum = SECNUM_NULL;
		}
		if (sidenum1 != -1){
			ld->backsecnum = side1secnum;
		} else {
			ld->backsecnum = SECNUM_NULL;
		}
	}

	Z_Free(data);
}


//
// P_LoadSideDefs
//
void P_LoadSideDefs(int lump)
{
	byte*               data;
	int                 i;
	mapsidedef_t*       msd;
	side_t*             sd;
	side_t* sides;
	short toptex;
	short bottex;
	short midtex;
	numsides = W_LumpLength(lump) / sizeof(mapsidedef_t);
	sidesRef = Z_MallocEMSNew (numsides * sizeof(side_t), PU_LEVEL, 0, ALLOC_TYPE_SIDES);
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
	memset(sides, 0, numsides * sizeof(side_t));

	W_CacheLumpNumCheck(lump, 10);
	data = W_CacheLumpNum(lump, PU_STATIC);
	msd = (mapsidedef_t *)data;
	
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);

	for (i = 0; i < numsides; i++, msd++) {
		sd = &sides[i];

		sd->textureoffset = SHORT(msd->textureoffset) << FRACBITS;
		sd->rowoffset = SHORT(msd->rowoffset) << FRACBITS;
		sd->secnum = SHORT(msd->sector);

		toptex = R_TextureNumForName(msd->toptexture);
		bottex = R_TextureNumForName(msd->bottomtexture);
		midtex = R_TextureNumForName(msd->midtexture);
		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		sd = &sides[i];
		sd->toptexture = toptex;
		sd->bottomtexture = bottex;
		sd->midtexture = midtex;

		Z_RefIsActive(sidesRef);


	}
	Z_Free(data);
}


//
// P_LoadBlockMap
//
void P_LoadBlockMap(int lump)
{
	int         i;
	int         count;

	W_CacheLumpNumCheck(lump, 11);
	blockmaplump = W_CacheLumpNum(lump, PU_LEVEL);
	blockmap = blockmaplump + 4;
	count = W_LumpLength(lump) / 2;

	for (i = 0; i < count; i++)
		blockmaplump[i] = SHORT(blockmaplump[i]);

	bmaporgx = blockmaplump[0] << FRACBITS;
	bmaporgy = blockmaplump[1] << FRACBITS;
	bmapwidth = blockmaplump[2];
	bmapheight = blockmaplump[3];

	// clear out mobj chains
	count = sizeof(*blocklinks)* bmapwidth*bmapheight;
//	I_Error("count %i", count);
//	blocklinksRef = Z_MallocEMSNew (count, PU_LEVEL, 0, ALLOC_TYPE_BLOCKLINKS);
//	blocklinks = (MEMREF*) Z_LoadBytesFromEMS(blocklinksRef);
	memset(blocklinks, 0, count);
}



//
// P_GroupLines
// Builds sector line lists and subsector sector numbers.
// Finds block bounding boxes for sectors.
//
void P_GroupLines(void)
{
	int                 i;
	int                 j;
	int                 total;
	line_t*             li;
	sector_t*           sector;
	seg_t*              seg;
	fixed_t             bbox[4];
	int                 block;
	seg_t*              segs;
	vertex_t*			vertexes;
	short  previouslinebufferindex;
	short* linebuffer;
	subsector_t* subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);
	short	firstlinenum;
	short	sidedefOffset;
	line_t*         lines;
	short linev1Offset;
	short linev2Offset;
	short linebacksecnum;
	short linefrontsecnum;
	short linebufferindex;
	short sidesecnum;

	side_t* sides;

	// look up sector number for each subsector
	for (i = 0; i < numsubsectors; i++) {
		firstlinenum = subsectors[i].firstline;
		segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);

		sidedefOffset = segs[firstlinenum].sidedefOffset;
		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		sidesecnum = sides[sidedefOffset].secnum;
		subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);
		if (sidesecnum == -64) {
			I_Error("caught it %i %i %i %i %i", i, numsubsectors, firstlinenum, sidedefOffset, sidesecnum);
		}
		subsectors[i].secnum = sidesecnum;
		Z_RefIsActive(subsectorsRef);
	}

	// count number of lines in each sector
	total = 0;
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
	for (i = 0; i < numlines; i++) {
		li = &lines[i];
		linebacksecnum = li->backsecnum;
		linefrontsecnum = li->frontsecnum;
		total++;
		sectors[linefrontsecnum].linecount++;

		if (linebacksecnum != -1 && linebacksecnum != linefrontsecnum) {
			sectors[linebacksecnum].linecount++;
			total++;
		}
	}

	// build line tables for each sector        

	linebufferRef = Z_MallocEMSNew (total * 2, PU_LEVEL, 0, ALLOC_TYPE_LINEBUFFER);
	linebufferindex = 0;

	for (i = 0; i < numsectors; i++) {
		M_ClearBox(bbox);
		
		sector = &sectors[i];


		sector->linesoffset = linebufferindex;
		previouslinebufferindex = linebufferindex;
	 
		for (j = 0; j < numlines; j++) {
			lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
			li = &lines[j];
			linev1Offset = li->v1Offset;
			linev2Offset = li->v2Offset;

			if (li->frontsecnum == i || li->backsecnum == i) {

				linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
				linebuffer[linebufferindex] = j;
				linebufferindex++;
				vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
				M_AddToBox(bbox, vertexes[linev1Offset].x, vertexes[linev1Offset].y);
				M_AddToBox(bbox, vertexes[linev2Offset].x, vertexes[linev2Offset].y);
			}
		}
		if (linebufferindex - previouslinebufferindex != sectors[i].linecount) {
			linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
			I_Error("P_GroupLines: miscounted %i %i   iteration %i      %i != (%i - %i)", linebuffer, sectors[i].linesoffset,  i, sectors[i].linecount, linebufferindex , previouslinebufferindex);
		}

		// set the degenmobj_t to the middle of the bounding box
		

		sectors[i].soundorgX = (bbox[BOXRIGHT] + bbox[BOXLEFT]) / 2;
		sectors[i].soundorgY = (bbox[BOXTOP] + bbox[BOXBOTTOM]) / 2;

		// adjust bounding box to map blocks
		block = (bbox[BOXTOP] - bmaporgy + MAXRADIUS) >> MAPBLOCKSHIFT;
		block = block >= bmapheight ? bmapheight - 1 : block;
		sectors[i].blockbox[BOXTOP] = block;

		block = (bbox[BOXBOTTOM] - bmaporgy - MAXRADIUS) >> MAPBLOCKSHIFT;
		block = block < 0 ? 0 : block;
		sectors[i].blockbox[BOXBOTTOM] = block;

		block = (bbox[BOXRIGHT] - bmaporgx + MAXRADIUS) >> MAPBLOCKSHIFT;
		block = block >= bmapwidth ? bmapwidth - 1 : block;
		sectors[i].blockbox[BOXRIGHT] = block;

		block = (bbox[BOXLEFT] - bmaporgx - MAXRADIUS) >> MAPBLOCKSHIFT;
		block = block < 0 ? 0 : block;
		sectors[i].blockbox[BOXLEFT] = block;
	}

	 

}


//
// P_SetupLevel
//
void
P_SetupLevel
(int           episode,
	int           map,
	int           playermask,
	skill_t       skill)
{
	int         i;
	char        lumpname[9];
	int         lumpnum;
	subsector_t* subsectors;


	totalkills = totalitems = totalsecret = wminfo.maxfrags = 0;
	wminfo.partime = 180;
	for (i = 0; i < MAXPLAYERS; i++)
	{
		players[i].killcount = players[i].secretcount
			= players[i].itemcount = 0;
	}

	// Initial height of PointOfView
	// will be set by player think.
	players[consoleplayer].viewz = 1;

	// Make sure all sounds are stopped before Z_FreeTags.
	S_Start();


#if 0 // UNUSED
	if (debugfile)
	{
		Z_FreeTags(PU_LEVEL, MAXINT);
		Z_FileDumpHeap(debugfile);
	}
	else
#endif
		Z_FreeTags(PU_LEVEL, PU_PURGELEVEL - 1);
		Z_FreeTagsEMS(PU_LEVEL, PU_PURGELEVEL - 1);


	// UNUSED W_Profile ();
	P_InitThinkers();

	// if working with a devlopment map, reload it
	W_Reload();

	// find map name
	if (commercial)
	{
		if (map < 10)
			sprintf(lumpname, "map0%i", map);
		else
			sprintf(lumpname, "map%i", map);
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

	leveltime = 0;


	// note: most of this ordering is important 
	P_LoadBlockMap(lumpnum + ML_BLOCKMAP);
	P_LoadVertexes(lumpnum + ML_VERTEXES);
	P_LoadSectors(lumpnum + ML_SECTORS);
	P_LoadSideDefs(lumpnum + ML_SIDEDEFS);

	P_LoadLineDefs(lumpnum + ML_LINEDEFS);
	P_LoadSubsectors(lumpnum + ML_SSECTORS);

	P_LoadNodes(lumpnum + ML_NODES);

	P_LoadSegs(lumpnum + ML_SEGS);



	W_CacheLumpNumCheck(lumpnum + ML_REJECT, 12);
	rejectmatrix = W_CacheLumpNum(lumpnum + ML_REJECT, PU_LEVEL);

	P_GroupLines();

	bodyqueslot = 0;
	deathmatch_p = deathmatchstarts;

	P_LoadThings(lumpnum + ML_THINGS);

	// if deathmatch, randomly spawn the active players
	if (deathmatch)
	{
		for (i = 0; i < MAXPLAYERS; i++)
			if (playeringame[i])
			{
				players[i].moRef = NULL_MEMREF;
				G_DeathMatchSpawnPlayer(i);
			}

	}

	// clear special respawning que
	iquehead = iquetail = 0;
	
	// set up world state
	P_SpawnSpecials();

	// build subsector connect matrix
	//  UNUSED P_ConnectSubsectors ();

	// preload graphics
	if (precache)
		R_PrecacheLevel();
	//printf ("free memory: 0x%x\n", Z_FreeMemory());

}



//
// P_Init
//
void P_Init(void)
{
	P_InitSwitchList();
	P_InitPicAnims();
	R_InitSprites(sprnames);
}


