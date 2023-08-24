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


void    P_SpawnMapThing(mapthing_t *    mthing, int key);

//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
int             numvertexes;
MEMREF       vertexesRef;

int             numsegs;
//seg_t*          segs;
MEMREF          segsRef;

int             numsectors;
MEMREF          sectorsRef;
//sector_t*       sectors;

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
int				blockmapOffset;       // int for larger maps

								// offsets in blockmap are from here
MEMREF          blockmaplumpRef;

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
MEMREF           rejectmatrixRef;

 
//
// P_LoadVertexes
//
void P_LoadVertexes(int lump)
{
	MEMREF				dataRef;
	mapvertex_t*			data;
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
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);
	data = (mapvertex_t*)Z_LoadBytesFromEMS(dataRef);
	
	li = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

	// Copy and convert vertex coordinates,
	// internal representation as fixed.
	for (i = 0; i < numvertexes; i++, li++) {
		ml = &data[i];

		li->x = SHORT(ml->x) << FRACBITS;
		li->y = SHORT(ml->y) << FRACBITS;
		Z_RefIsActive(dataRef);
		Z_RefIsActive(vertexesRef);
	}

	// Free buffer memory.
	Z_FreeEMSNew(dataRef);
}



//
// P_LoadSegs
//
void P_LoadSegs(int lump)
{
	MEMREF				dataRef;
	mapseg_t *          data;
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
	short mlv1;
	short mlv2;
	angle_t mlangle;
	fixed_t mloffset;
	short mllinedef;
	numsegs = W_LumpLength(lump) / sizeof(mapseg_t);
	segsRef = Z_MallocEMSNew(numsegs * sizeof(seg_t), PU_LEVEL, 0, ALLOC_TYPE_SEGMENTS);
	
	segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	memset(segs, 0xff, numsegs * sizeof(seg_t));
	
	W_CacheLumpNumCheck(lump, 4);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);
	data = (mapseg_t *)Z_LoadBytesFromEMS(dataRef);

	ml = (mapseg_t *)data;
	
	for (i = 0; i < numsegs; i++) {
		data = (mapseg_t *)Z_LoadBytesFromEMS(dataRef);
		ml = &data[i];
		mlv1 = SHORT(ml->v1);
		mlv2 = SHORT(ml->v2);
		mlangle = (SHORT(ml->angle)) << 16;
		mloffset = (SHORT(ml->offset)) << 16;
		mllinedef = SHORT(ml->linedef);
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
		li->v1Offset = mlv1;
		li->v2Offset = mlv2;
	
		li->angle = mlangle;
		li->offset = mloffset;
		li->linedefOffset = mllinedef;
		li->sidedefOffset = ldefsidenum;



		li->frontsecnum = sidesecnum;
		if (ldefflags & ML_TWOSIDED)
			li->backsecnum = othersidesecnum;
		else
			li->backsecnum = SECNUM_NULL;

		//Z_RefIsActive(sidesRef);
		//Z_RefIsActive(vertexesRef);
		//Z_RefIsActive(segsRef);
		//Z_RefIsActive(dataRef);
	}

	Z_FreeEMSNew(dataRef);
	//Z_Free(data);
}



//
// P_LoadSubsectors
//
void P_LoadSubsectors(int lump)
{
	mapsubsector_t *               data;
	int                 i;
	mapsubsector_t*     ms;
	subsector_t*        ss;
	subsector_t*    subsectors;
	MEMREF			dataRef;
	numsubsectors = W_LumpLength(lump) / sizeof(mapsubsector_t);
	subsectorsRef = Z_MallocEMSNew (numsubsectors * sizeof(subsector_t), PU_LEVEL, 0, ALLOC_TYPE_SUBSECS);

	W_CacheLumpNumCheck(lump, 5);

	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);
	data = (mapsubsector_t *) Z_LoadBytesFromEMS(dataRef);

	subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);
	memset(subsectors, 0, numsubsectors * sizeof(subsector_t));

	for (i = 0; i < numsubsectors; i++)
	{
		ms = &data[i];
		ss = &subsectors[i];
		ss->numlines = SHORT(ms->numsegs);
		ss->firstline = SHORT(ms->firstseg);
		Z_RefIsActive(dataRef);
		Z_RefIsActive(subsectorsRef);

	}

	Z_FreeEMSNew(dataRef);
}



//
// P_LoadSectors
//
void P_LoadSectors(int lump)
{
	mapsector_t*        data;
	int                 i;
	mapsector_t        ms;
	sector_t*           ss;
	MEMREF				dataRef;
	sector_t* sectors;

	numsectors = W_LumpLength(lump) / sizeof(mapsector_t);
	//sectors = Z_Malloc (numsectors * sizeof(sector_t), PU_LEVEL, 0);
	sectorsRef = Z_MallocEMSNew (numsectors * sizeof(sector_t), PU_LEVEL, 0, ALLOC_TYPE_SECTORS);
	sectors = (sector_t*) Z_LoadBytesFromEMS(sectorsRef);


	memset(sectors, 0, numsectors * sizeof(sector_t));
	W_CacheLumpNumCheck(lump, 6);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);


	ss = sectors;
	for (i = 0; i < numsectors; i++, ss++) {
		data = (mapsector_t *)Z_LoadBytesFromEMS(dataRef);
		ms = data[i];
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		ss->floorheight = SHORT(ms.floorheight) << FRACBITS;
		ss->ceilingheight = SHORT(ms.ceilingheight) << FRACBITS;
		ss->floorpic = R_FlatNumForName(ms.floorpic);
		ss->ceilingpic = R_FlatNumForName(ms.ceilingpic);
		ss->lightlevel = SHORT(ms.lightlevel);
		ss->special = SHORT(ms.special);
		ss->tag = SHORT(ms.tag);
		ss->thinglistRef = NULL_MEMREF;
		Z_RefIsActive(dataRef);



	}

	Z_FreeEMSNew(dataRef);
}


//
// P_LoadNodes
//
void P_LoadNodes(int lump)
{
	mapnode_t *       data;
	int         i;
	int         j;
	int         k;
	node_t*     no;
	node_t*		nodes;
	MEMREF		dataRef;
	mapnode_t	currentdata;
 


		fixed_t	bbox[2][4];

	// If NF_SUBSECTOR its a subsector.
	unsigned short children[2];

	numnodes = W_LumpLength(lump) / sizeof(mapnode_t);
	nodesRef = Z_MallocEMSNew (numnodes * sizeof(node_t), PU_LEVEL, 0, ALLOC_TYPE_NODES);
	W_CacheLumpNumCheck(lump, 7);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);


	for (i = 0; i < numnodes; i++) {
		data = (mapnode_t *)Z_LoadBytesFromEMS(dataRef);
		currentdata = data[i];
		nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
		no = &nodes[i];

		no->x = SHORT(currentdata.x) << FRACBITS;
		no->y = SHORT(currentdata.y) << FRACBITS;
		no->dx = SHORT(currentdata.dx) << FRACBITS;
		no->dy = SHORT(currentdata.dy) << FRACBITS;
		for (j = 0; j < 2; j++) {
			no->children[j] = SHORT(currentdata.children[j]);
			for (k = 0; k < 4; k++)
				no->bbox[j][k] = SHORT(currentdata.bbox[j][k]) << FRACBITS;
		}
		//Z_RefIsActive(nodesRef);
		//Z_RefIsActive(dataRef);
	}

	Z_FreeEMSNew(dataRef);
}


//
// P_LoadThings
//
void P_LoadThings(int lump)
{
	mapthing_t *		data;
	int                 i;
	mapthing_t*         mt;
	int                 numthings;
	boolean             spawn;
	MEMREF				dataRef;
	node_t*				nodes;
	W_CacheLumpNumCheck(lump, 8);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);

	numthings = W_LumpLength(lump) / sizeof(mapthing_t);

	for (i = 0; i < numthings; i++) {
		nodes = (node_t*)Z_LoadBytesFromEMS(nodesRef);
		data = (mapthing_t *)Z_LoadBytesFromEMS(dataRef);
		mt = &data[i];
		spawn = true;

		// Do not spawn cool, new monsters if !commercial
		if (!commercial) {
			switch (mt->type) {
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
		mt->x = SHORT(mt->x);
		mt->y = SHORT(mt->y);
		mt->angle = SHORT(mt->angle);
		mt->type = SHORT(mt->type);
		mt->options = SHORT(mt->options);

		P_SpawnMapThing(mt, i);
	 

	}

	Z_FreeEMSNew(dataRef);
}


//
// P_LoadLineDefs
// Also counts secret lines for intermissions.
//
void P_LoadLineDefs(int lump)
{
	maplinedef_t *		data;
	int                 i;
	maplinedef_t*       mld;
	line_t*             ld;
	vertex_t*           v1;
	vertex_t*           v2;
	vertex_t*           vertexes;
	side_t* sides;
	line_t*         lines;
	short side0secnum;
	short side1secnum;
	fixed_t v1x;
	fixed_t v1y;
	fixed_t v2x;
	fixed_t v2y;
	MEMREF dataRef;
	short mldflags;
	short mldspecial;
	short mldtag;
	short mldv1;
	short mldv2 = SHORT(mld->v2);
	short mldsidenum0;
	short mldsidenum1;


	numlines = W_LumpLength(lump) / sizeof(maplinedef_t);
	linesRef = Z_MallocEMSNew (numlines * sizeof(line_t), PU_LEVEL, 0, ALLOC_TYPE_LINES);
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

	memset(lines, 0, numlines * sizeof(line_t));
	W_CacheLumpNumCheck(lump, 9);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);


	for (i = 0; i < numlines; i++) {
		data = (maplinedef_t *)  Z_LoadBytesFromEMS(dataRef);
		mld = &data[i];

		mldflags = SHORT(mld->flags);
		mldspecial = SHORT(mld->special);
		mldtag = SHORT(mld->tag);
		mldv1 = SHORT(mld->v1);
		mldv2 = SHORT(mld->v2);
		mldsidenum0 = SHORT(mld->sidenum[0]);
		mldsidenum1 = SHORT(mld->sidenum[1]);
		 

		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		side0secnum = sides[mldsidenum0].secnum;
		side1secnum = sides[mldsidenum1].secnum;
		vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
		v1 = &vertexes[mldv1];
		v2 = &vertexes[mldv2];
		v1x = v1->x;
		v1y = v1->y;
		v2x = v2->x;
		v2y = v2->y;

		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
		ld = &lines[i];

		ld->sidenum[0] = mldsidenum0;
		ld->sidenum[1] = mldsidenum1;



		ld->flags = mldflags;
		ld->special = mldspecial;
		ld->tag = mldtag;
		ld->v1Offset = mldv1;
		ld->v2Offset = mldv2;
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

		if (mldsidenum0 != -1) {
			ld->frontsecnum = side0secnum;
		} else {
			ld->frontsecnum = SECNUM_NULL;
		}
		if (mldsidenum1 != -1){
			ld->backsecnum = side1secnum;
		} else {
			ld->backsecnum = SECNUM_NULL;
		}
	}
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

	Z_FreeEMSNew(dataRef);
}


//
// P_LoadSideDefs
//
void P_LoadSideDefs(int lump)
{
	mapsidedef_t*               data;
	int                 i;
	mapsidedef_t*       msd;
	side_t*             sd;
	side_t* sides;
	short toptex;
	short bottex;
	short midtex;
	MEMREF dataRef;
	char texname[8];
	short msdtextureoffset;
	short msdrowoffset;
	short msdsecnum;

	numsides = W_LumpLength(lump) / sizeof(mapsidedef_t);
	sidesRef = Z_MallocEMSNew (numsides * sizeof(side_t), PU_LEVEL, 0, ALLOC_TYPE_SIDES);
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
	memset(sides, 0, numsides * sizeof(side_t));

	W_CacheLumpNumCheck(lump, 10);
	
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);

	
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);

	for (i = 0; i < numsides; i++) {
		data = (mapsidedef_t *)Z_LoadBytesFromEMS(dataRef);
		msd = &data[i];

		msdtextureoffset = SHORT(msd->textureoffset);
		msdrowoffset = SHORT(msd->rowoffset);
		msdsecnum = SHORT(msd->sector);
	
		memcpy(texname, msd->toptexture, 8);
		toptex = R_TextureNumForName(texname);

		data = (mapsidedef_t *)Z_LoadBytesFromEMS(dataRef);
		msd = &data[i];
		memcpy(texname, msd->bottomtexture, 8);
		bottex = R_TextureNumForName(texname);

		data = (mapsidedef_t *)Z_LoadBytesFromEMS(dataRef);
		msd = &data[i];
		memcpy(texname, msd->midtexture, 8);
		midtex = R_TextureNumForName(texname);



		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		sd = &sides[i];
		sd->toptexture = toptex;
		sd->bottomtexture = bottex;
		sd->midtexture = midtex;

		sd->textureoffset = msdtextureoffset << FRACBITS;
		sd->rowoffset = msdrowoffset << FRACBITS;
		sd->secnum = msdsecnum;

		Z_RefIsActive(sidesRef);


	}
	Z_FreeEMSNew(dataRef);
}


//
// P_LoadBlockMap
//
void P_LoadBlockMap(int lump)
{
	int         i;
	int         count;
	short*		blockmaplump;
	
	W_CacheLumpNumCheck(lump, 11);
	
	blockmaplumpRef = W_CacheLumpNumEMS(lump, PU_LEVEL);
	blockmaplump = (short*)Z_LoadBytesFromEMS(blockmaplumpRef);
	blockmapOffset = 4;
	count = W_LumpLength(lump) / 2;

	for (i = 0; i < count; i++)
		blockmaplump[i] = SHORT(blockmaplump[i]);

	bmaporgx = blockmaplump[0] << FRACBITS;
	bmaporgy = blockmaplump[1] << FRACBITS;
	bmapwidth = blockmaplump[2];
	bmapheight = blockmaplump[3];

	// clear out mobj chains
	count = sizeof(*blocklinks)* bmapwidth*bmapheight;

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
	seg_t*              seg;
	fixed_t             bbox[4];
	int                 block;
	seg_t*              segs;
	vertex_t*			vertexes;
	short				previouslinebufferindex;
	short*				linebuffer;
	subsector_t*		subsectors;
	short				firstlinenum;
	short				sidedefOffset;
	line_t*				lines;
	short				linev1Offset;
	short				linev2Offset;
	short				linebacksecnum;
	short				linefrontsecnum;
	short				linebufferindex;
	short				sidesecnum;
	sector_t*			sectors;
	int					sectorlinecount;

	side_t* sides;

	// look up sector number for each subsector
	for (i = 0; i < numsubsectors; i++) {
		subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef); 
		firstlinenum = subsectors[i].firstline;
		segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
		
		sidedefOffset = segs[firstlinenum].sidedefOffset;
		sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
		sidesecnum = sides[sidedefOffset].secnum;
		subsectors = (subsector_t*)Z_LoadBytesFromEMS(subsectorsRef);

		Z_RefIsActive(subsectorsRef);
		subsectors[i].secnum = sidesecnum;

	}

	// count number of lines in each sector
	total = 0;
	for (i = 0; i < numlines; i++) {
		lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
		li = &lines[i];
		linebacksecnum = li->backsecnum;
		linefrontsecnum = li->frontsecnum;
		total++;
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
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
		
		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		sectorlinecount = sectors[i].linecount;

		sectors[i].linesoffset = linebufferindex;
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
		if (linebufferindex - previouslinebufferindex != sectorlinecount) {
			linebuffer = (short*)Z_LoadBytesFromEMS(linebufferRef);
			I_Error("P_GroupLines: miscounted %i %i   iteration %i      %i != (%i - %i)", linebuffer, sectors[i].linesoffset,  i, sectors[i].linecount, linebufferindex , previouslinebufferindex);
		}

		// set the degenmobj_t to the middle of the bounding box
		

		sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
		
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

	byte* nodes;

	wminfo.partime = 180;
	players[0].killcount = players[0].secretcount = players[0].itemcount = 0;

	// Initial height of PointOfView
	// will be set by player think.
	players[consoleplayer].viewz = 1;

	S_Start();
	Z_FreeTagsEMS(PU_LEVEL, PU_PURGELEVEL - 1);


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
	nodes = Z_LoadBytesFromEMS(nodesRef);



	P_LoadSegs(lumpnum + ML_SEGS);


	W_CacheLumpNumCheck(lumpnum + ML_REJECT, 12);
	rejectmatrixRef = W_CacheLumpNumEMS(lumpnum + ML_REJECT, PU_LEVEL);

	P_GroupLines();



	bodyqueslot = 0;

	P_LoadThings(lumpnum + ML_THINGS);


 

	// clear special respawning que
	iquehead = iquetail = 0;
	
	// set up world state
	P_SpawnSpecials();


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


