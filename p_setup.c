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
line_t*         lines;

int             numsides;
side_t*         sides;

line_t**            linebuffer;

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
	short                 linedef;
	int                 side;
	vertex_t*                       vertexes;
	seg_t*                          segs;

	numsegs = W_LumpLength(lump) / sizeof(mapseg_t);
	segsRef = Z_MallocEMSNew(numsegs * sizeof(seg_t), PU_LEVEL, 0, ALLOC_TYPE_SEGMENTS);
	
	segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	memset(segs, 0xff, numsegs * sizeof(seg_t));
	W_CacheLumpNumCheck(lump, 4);
	data = W_CacheLumpNum(lump, PU_STATIC);

	ml = (mapseg_t *)data;
	li = segs;
	

	vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

	for (i = 0; i < numsegs; i++, li++, ml++) {
		li->v1Offset = SHORT(ml->v1);
		li->v2Offset = SHORT(ml->v2);

		li->angle = (SHORT(ml->angle)) << 16;
		li->offset = (SHORT(ml->offset)) << 16;
		linedef = SHORT(ml->linedef);
		ldef = &lines[linedef];
		li->linedefOffset = linedef;
		side = SHORT(ml->side);
		li->sidedefOffset = ldef->sidenum[side];
		li->frontsecnum = sides[ldef->sidenum[side]].secnum;
		if (ldef->flags & ML_TWOSIDED)
			li->backsecnum = sides[ldef->sidenum[side ^ 1]].secnum;
		else
			li->backsecnum = SECNUM_NULL;
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
	subsectors = (subsector_t*) Z_LoadBytesFromEMS(subsectorsRef);

	W_CacheLumpNumCheck(lump, 5);
	data = W_CacheLumpNum(lump, PU_STATIC);

	ms = (mapsubsector_t *)data;
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

	numlines = W_LumpLength(lump) / sizeof(maplinedef_t);
	lines = Z_Malloc (numlines * sizeof(line_t), PU_LEVEL, 0);
	memset(lines, 0, numlines * sizeof(line_t));
	W_CacheLumpNumCheck(lump, 9);
	data = W_CacheLumpNum(lump, PU_STATIC);

	mld = (maplinedef_t *)data;
	ld = lines;
	
	vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
	for (i = 0; i < numlines; i++, mld++, ld++) {
		ld->flags = SHORT(mld->flags);
		ld->special = SHORT(mld->special);
		ld->tag = SHORT(mld->tag);
		v1 = &vertexes[SHORT(mld->v1)];
		v2 = &vertexes[SHORT(mld->v2)];
		ld->v1Offset = SHORT(mld->v1);
		ld->v2Offset = SHORT(mld->v2);
		ld->dx = v2->x - v1->x;
		ld->dy = v2->y - v1->y;

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

		if (v1->x < v2->x) {
			ld->bbox[BOXLEFT] = v1->x;
			ld->bbox[BOXRIGHT] = v2->x;
		} else {
			ld->bbox[BOXLEFT] = v2->x;
			ld->bbox[BOXRIGHT] = v1->x;
		}
		if (v1->y < v2->y) {
			ld->bbox[BOXBOTTOM] = v1->y;
			ld->bbox[BOXTOP] = v2->y;
		} else {
			ld->bbox[BOXBOTTOM] = v2->y;
			ld->bbox[BOXTOP] = v1->y;
		}

		ld->sidenum[0] = SHORT(mld->sidenum[0]);
		ld->sidenum[1] = SHORT(mld->sidenum[1]);

		if (ld->sidenum[0] != -1) {
			ld->frontsecnum = sides[ld->sidenum[0]].secnum;
		} else {
			ld->frontsecnum = SECNUM_NULL;
		}
		if (ld->sidenum[1] != -1){
			ld->backsecnum = sides[ld->sidenum[1]].secnum;
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

	numsides = W_LumpLength(lump) / sizeof(mapsidedef_t);
	sides = Z_Malloc (numsides * sizeof(side_t), PU_LEVEL, 0);
	memset(sides, 0, numsides * sizeof(side_t));
	W_CacheLumpNumCheck(lump, 10);
	data = W_CacheLumpNum(lump, PU_STATIC);
	msd = (mapsidedef_t *)data;
	sd = sides;
	for (i = 0; i < numsides; i++, msd++, sd++)
	{
		sd->textureoffset = SHORT(msd->textureoffset) << FRACBITS;
		sd->rowoffset = SHORT(msd->rowoffset) << FRACBITS;
		sd->toptexture = R_TextureNumForName(msd->toptexture);
		sd->bottomtexture = R_TextureNumForName(msd->bottomtexture);
		sd->midtexture = R_TextureNumForName(msd->midtexture);
		sd->secnum = SHORT(msd->sector);
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
	short        subsecnum = 0;
	seg_t*              seg;
	fixed_t             bbox[4];
	int                 block;
	seg_t*              segs;
	MEMREF				linebufferRef;
	vertex_t*			vertexes;
	line_t**				baselinebuffer;
	line_t**  previouslinebuffer;
	subsector_t* subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);
	short	firstlinenum;
	short	sidedefOffset;
	

	// look up sector number for each subsector
	for (i = 0; i < numsubsectors; i++, subsecnum++) {
		firstlinenum = subsectors[subsecnum].firstline;
		segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);

		sidedefOffset = segs[firstlinenum].sidedefOffset;
		subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);

		subsectors[subsecnum].secnum = sides[sidedefOffset].secnum;
	}

	// count number of lines in each sector
	li = lines;
	total = 0;
	for (i = 0; i < numlines; i++, li++) {
		total++;
		sectors[li->frontsecnum].linecount++;

		if (li->backsecnum != -1 && li->backsecnum != li->frontsecnum)
		{
			sectors[li->backsecnum].linecount++;
			total++;
		}
	}

	// build line tables for each sector        
//	linebufferRef = Z_MallocEMSNew (total * 4, PU_LEVEL, 0, ALLOC_TYPE_LINEBUFFER);
//	linebuffer = (line_t**)Z_LoadBytesFromEMS(linebufferRef);
	linebuffer = (line_t**)Z_Malloc (total * 4, PU_LEVEL, 0);
	baselinebuffer = linebuffer;
	//I_Error("%s", outputter);
	//sector = sectors;
	vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
	sector = sectors;
	for (i = 0; i < numsectors; i++, sector++) {
		M_ClearBox(bbox);
		//sectors[i].lines = linebuffer;
		sector->linesoffset = linebuffer - baselinebuffer;
		previouslinebuffer = linebuffer;
		li = lines;
		if (i == 0) {
			//I_Error("%p %p %p %i %i %p %p", baselinebuffer[sector->linesoffset], linebuffer[0], baselinebuffer, sector->linesoffset, linebuffer - baselinebuffer, &lines[sector->linesoffset + 1], linebuffer[1]);
		}

		for (j = 0; j < numlines; j++, li++) {
			if (li->frontsecnum == i || li->backsecnum == i) {
				*linebuffer++ = li;
				M_AddToBox(bbox, vertexes[li->v1Offset].x, vertexes[li->v1Offset].y);
				M_AddToBox(bbox, vertexes[li->v2Offset].x, vertexes[li->v2Offset].y);
			}
		}
		if (linebuffer - previouslinebuffer != sectors[i].linecount)
			I_Error("P_GroupLines: miscounted %i %i %i %i %i, %i",linebuffer, sectors[i].linesoffset, sectors[i].linecount, i, linebuffer , sizeof(line_t));

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

	linebuffer = baselinebuffer;

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


