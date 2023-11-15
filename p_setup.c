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


void    P_SpawnMapThing(mapthing_t *    mthing, int16_t key);

//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
int16_t             numvertexes;
//MEMREF       vertexesRef;
vertex_t*		vertexes;

int16_t             numsegs;
seg_t*				segs;

int16_t             numsectors;
sector_t*		sectors;
MEMREF			sectorBlockBoxesRef;

int16_t             numsubsectors;
subsector_t*    subsectors;

int16_t             numnodes;
node_t*          nodes;

int16_t             numlines;
line_t*			lines;
//MEMREF			linesRef;

int16_t             numsides;
side_t*          sides;

int16_t*          linebuffer;

int16_t firstnode;


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
MEMREF          blockmaplumpRef;

// origin of block map
// todo can this be made 16 bit
int16_t         bmaporgx;
int16_t         bmaporgy;

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
void P_LoadVertexes(int16_t lump)
{
	MEMREF				dataRef;
	mapvertex_t*			data;
	uint16_t                 i;
	mapvertex_t			ml;
	MEMREF vertexesRef;
	// Determine number of lumps:
	//  total lump length / vertex record length.
	numvertexes = W_LumpLength(lump) / sizeof(mapvertex_t);

	// Allocate zone memory for buffer.
	vertexesRef = Z_MallocConventional(numvertexes * sizeof(vertex_t), PU_LEVEL, CA_TYPE_LEVELDATA,0, ALLOC_TYPE_VERTEXES);
	vertexes = Z_LoadBytesFromConventional(vertexesRef);
	// Load data into cache.
	W_CacheLumpNumCheck(lump, 0);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);
	
	data = (mapvertex_t*)Z_LoadBytesFromEMS(dataRef);

	// Copy and convert vertex coordinates,
	// internal representation as fixed.
	for (i = 0; i < numvertexes; i++) {
		ml = data[i];

		vertexes[i].x = (ml.x);
		vertexes[i].y = (ml.y);
	}

	// Free buffer memory.
	Z_FreeEMS(dataRef);
}



//
// P_LoadSegs
//
void P_LoadSegs(int16_t lump)
{
	MEMREF				dataRef;
	mapseg_t *          data;
	uint16_t                 i;
	mapseg_t*           ml;
	seg_t*              li;
	line_t*             ldef;
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
	fixed_t_union temp;
	MEMREF segsRef; 

	temp.h.fracbits = 0;
	numsegs = W_LumpLength(lump) / sizeof(mapseg_t);
	segsRef = Z_MallocConventional(numsegs * sizeof(seg_t), PU_LEVEL, CA_TYPE_LEVELDATA,0, ALLOC_TYPE_SEGMENTS);
	
	segs = (seg_t*)Z_LoadBytesFromConventional(segsRef);
	memset(segs, 0xff, numsegs * sizeof(seg_t));
	
	W_CacheLumpNumCheck(lump, 1);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);
	data = (mapseg_t *)Z_LoadBytesFromEMS(dataRef);

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


		sidesecnum = sides[ldefsidenum].secnum;
		othersidesecnum = sides[ldefothersidenum].secnum;


		li = &segs[i];
		li->v1Offset = mlv1;
		li->v2Offset = mlv2 + (side ? SEG_V2_SIDE_1_HIGHBIT : 0);
	
		li->fineangle = mlangle >> SHORTTOFINESHIFT;
		li->offset = mloffset;
		li->linedefOffset = mllinedef;
		li->sidedefOffset = ldefsidenum;

	}

	//Z_SetUnlocked(dataRef);
	Z_FreeEMS(dataRef);
}



//
// P_LoadSubsectors
//
void P_LoadSubsectors(int16_t lump)
{
	mapsubsector_t *               data;
	uint16_t                 i;
	mapsubsector_t*     ms;
	subsector_t*        ss;
	MEMREF			dataRef;
	MEMREF		subsectorsRef;
	numsubsectors = W_LumpLength(lump) / sizeof(mapsubsector_t);
	subsectorsRef = Z_MallocConventional (numsubsectors * sizeof(subsector_t), PU_LEVEL, CA_TYPE_LEVELDATA, 0, ALLOC_TYPE_SUBSECS);
	subsectors = (subsector_t*)Z_LoadBytesFromConventional(subsectorsRef);
	memset(subsectors, 0, numsubsectors * sizeof(subsector_t));
	W_CacheLumpNumCheck(lump, 2);

	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);
	data = (mapsubsector_t *) Z_LoadBytesFromEMS(dataRef);



	for (i = 0; i < numsubsectors; i++)
	{
		ms = &data[i];
		ss = &subsectors[i];
		ss->numlines = (ms->numsegs);
		ss->firstline = (ms->firstseg);

	}

	Z_FreeEMS(dataRef);
}



//
// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
//
// note this function got duped across different overlays, but this ends up reducing overall conventional memory use
uint8_t R_FlatNumForNameC(int8_t* name)
{
	int16_t         i;
#ifdef CHECK_FOR_ERRORS
	int8_t        namet[9];
#endif

	i = W_CheckNumForName(name);

#ifdef CHECK_FOR_ERRORS
	if (i == -1)
	{
		namet[8] = 0;
		memcpy(namet, name, 8);
		I_Error("\nR_FlatNumForName: %s not found", namet);
	}

	if (i - firstflat > 255) {
		I_Error("Flat too big %i %i", i, firstflat);
	}
#endif

	return (uint8_t)(i - firstflat);
}



//
// P_LoadSectors
//
void P_LoadSectors(int16_t lump)
{
	mapsector_t*        data;
	uint16_t                 i;
	mapsector_t        ms;
	sector_t*           ss;
	MEMREF				dataRef;
	MEMREF				sectorsRef;
	// most tags are under 100, a couple are like 666 or 667 or 999 or other such special numbers.
	// we will special case those and fit it in 8 bits so allocations are smaller
	int16_t convertedtag;
	numsectors = W_LumpLength(lump) / sizeof(mapsector_t);
	//sectors = Z_Malloc (numsectors * sizeof(sector_t), PU_LEVEL, 0);
	sectorsRef = Z_MallocConventional (numsectors * sizeof(sector_t), PU_LEVEL, CA_TYPE_LEVELDATA,0, ALLOC_TYPE_SECTORS);
	sectors = (sector_t*) Z_LoadBytesFromConventional(sectorsRef);


	memset(sectors, 0, numsectors * sizeof(sector_t));
	W_CacheLumpNumCheck(lump, 3);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);


	ss = sectors;
	for (i = 0; i < numsectors; i++, ss++) {
		data = (mapsector_t *)Z_LoadBytesFromEMS(dataRef);
		ms = data[i];
		convertedtag = ms.tag;
		if (convertedtag == 666) {
			convertedtag = TAG_666;
		} else if (convertedtag == 667) {
			convertedtag = TAG_667;
		} else if (convertedtag == 999) {
			convertedtag = TAG_999;
		}
		//sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);
		ss->floorheight = (ms.floorheight) << SHORTFLOORBITS;
		ss->ceilingheight = (ms.ceilingheight) << SHORTFLOORBITS;
		ss->floorpic = R_FlatNumForNameC(ms.floorpic);
		ss->ceilingpic = R_FlatNumForNameC(ms.ceilingpic);
		ss->lightlevel = (ms.lightlevel);
		ss->special = (ms.special);
		ss->tag = (convertedtag);
		ss->thinglistRef = NULL_MEMREF;
		Z_RefIsActive(dataRef);



	}

	Z_FreeEMS(dataRef);
}


//
// P_LoadNodes
//
void P_LoadNodes(int16_t lump)
{
	mapnode_t *       data;
	uint16_t         i;
	uint16_t         j;
	uint16_t         k;
	node_t*     no;
	MEMREF		dataRef;
	mapnode_t	currentdata;
	MEMREF	nodesRef;

	numnodes = W_LumpLength(lump) / sizeof(mapnode_t);
	firstnode = numnodes - 1;
	nodesRef = Z_MallocConventional(numnodes * sizeof(node_t), PU_LEVEL, CA_TYPE_LEVELDATA,0, ALLOC_TYPE_NODES);
	nodes = (node_t*)Z_LoadBytesFromConventional(nodesRef);
	W_CacheLumpNumCheck(lump, 4);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);


	for (i = 0; i < numnodes; i++) {
		data = (mapnode_t *)Z_LoadBytesFromEMS(dataRef);
		currentdata = data[i];
		no = &nodes[i];

		no->x = (currentdata.x);
		no->y = (currentdata.y);
		no->dx = (currentdata.dx);
		no->dy = (currentdata.dy);
		for (j = 0; j < 2; j++) {
			no->children[j] = (currentdata.children[j]);
			for (k = 0; k < 4; k++) {
				no->bbox[j][k] = (currentdata.bbox[j][k]);
			}
		}
		//Z_RefIsActive(nodesRef);
		//Z_RefIsActive(dataRef);
	}

	Z_FreeEMS(dataRef);
}


void P_BringUpWeapon();

//
// P_SetupPsprites
// Called at start of level for each player.
//
void P_SetupPsprites()
{
	int8_t	i;

	// remove all psprites
	for (i = 0; i < NUMPSPRITES; i++)
		player.psprites[i].state = NULL;

	// spawn the gun
	player.pendingweapon = player.readyweapon;
	P_BringUpWeapon();
}


//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//

void ST_Start(void);
void G_PlayerReborn();
void HU_Start(void);

void P_SpawnPlayer(mapthing_t* mthing)
{
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;

	MEMREF mobjRef;
	mobj_t*		mobj;
	//int16_t mthingtype = mthing->type;
	int16_t mthingx = mthing->x;
	int16_t mthingy = mthing->y;
	int16_t mthingangle = mthing->angle;


	if (player.playerstate == PST_REBORN) {
		G_PlayerReborn();
	}
	x.h.fracbits = 0;
	y.h.fracbits = 0;
	x.h.intbits = mthingx;
	y.h.intbits = mthingy;
	z.w = ONFLOORZ;

	mobjRef = P_SpawnMobj(x.w, y.w, z.w, MT_PLAYER);
	mobj = &playerMobj;
	mobj->reactiontime = 0;

	mobj->angle = ANG45 * (mthingangle / 45);
	//mobj->player = &player;
	mobj->health = player.health;


	player.playerstate = PST_LIVE;
	player.refire = 0;
	player.message = -1;
	player.damagecount = 0;
	player.bonuscount = 0;
	player.extralight = 0;
	player.fixedcolormap = 0;
	player.viewheight = VIEWHEIGHT;

	// setup gun psprite
	P_SetupPsprites();

	// wake up the status bar
	ST_Start();

	// wake up the heads up text
	HU_Start();

}

int16_t getDoomEdNum(uint8_t id) {
	switch (id) {
	case 1:
		return 3004;
	case 2:
		return 9;
	case 3:
		return 64;
	case 5:
		return 66;
	case 8:
		return 67;
	case 10:
		return 65;
	case 11:
		return 3001;
	case 12:
		return 3002;
	case 13:
		return 58;
	case 14:
		return 3005;
	case 15:
		return 3003;
	case 17:
		return 69;
	case 18:
		return 3006;
	case 19:
		return 7;
	case 20:
		return 68;
	case 21:
		return 16;
	case 22:
		return 71;
	case 23:
		return 84;
	case 24:
		return 72;
	case 25:
		return 88;
	case 26:
		return 89;
	case 27:
		return 87;
	case 30:
		return 2035;
	case 41:
		return 14;
	case 43:
		return 2018;
	case 44:
		return 2019;
	case 45:
		return 2014;
	case 46:
		return 2015;
	case 47:
		return 5;
	case 48:
		return 13;
	case 49:
		return 6;
	case 50:
		return 39;
	case 51:
		return 38;
	case 52:
		return 40;
	case 53:
		return 2011;
	case 54:
		return 2012;
	case 55:
		return 2013;
	case 56:
		return 2022;
	case 57:
		return 2023;
	case 58:
		return 2024;
	case 59:
		return 2025;
	case 60:
		return 2026;
	case 61:
		return 2045;
	case 62:
		return 83;
	case 63:
		return 2007;
	case 64:
		return 2048;
	case 65:
		return 2010;
	case 66:
		return 2046;
	case 67:
		return 2047;
	case 68:
		return 17;
	case 69:
		return 2008;
	case 70:
		return 2049;
	case 71:
		return 8;
	case 72:
		return 2006;
	case 73:
		return 2002;
	case 74:
		return 2005;
	case 75:
		return 2003;
	case 76:
		return 2004;
	case 77:
		return 2001;
	case 78:
		return 82;
	case 79:
		return 85;
	case 80:
		return 86;
	case 81:
		return 2028;
	case 82:
		return 30;
	case 83:
		return 31;
	case 84:
		return 32;
	case 85:
		return 33;
	case 86:
		return 37;
	case 87:
		return 36;
	case 88:
		return 41;
	case 89:
		return 42;
	case 90:
		return 43;
	case 91:
		return 44;
	case 92:
		return 45;
	case 93:
		return 46;
	case 94:
		return 55;
	case 95:
		return 56;
	case 96:
		return 57;
	case 97:
		return 47;
	case 98:
		return 48;
	case 99:
		return 34;
	case 100:
		return 35;
	case 101:
		return 49;
	case 102:
		return 50;
	case 103:
		return 51;
	case 104:
		return 52;
	case 105:
		return 53;
	case 106:
		return 59;
	case 107:
		return 60;
	case 108:
		return 61;
	case 109:
		return 62;
	case 110:
		return 63;
	case 111:
		return 22;
	case 112:
		return 15;
	case 113:
		return 18;
	case 114:
		return 21;
	case 115:
		return 23;
	case 116:
		return 20;
	case 117:
		return 19;
	case 118:
		return 10;
	case 119:
		return 12;
	case 120:
		return 28;
	case 121:
		return 24;
	case 122:
		return 27;
	case 123:
		return 29;
	case 124:
		return 25;
	case 125:
		return 26;
	case 126:
		return 54;
	case 127:
		return 70;
	case 128:
		return 73;
	case 129:
		return 74;
	case 130:
		return 75;
	case 131:
		return 76;
	case 132:
		return 77;
	case 133:
		return 78;
	case 134:
		return 79;
	case 135:
		return 80;
	case 136:
		return 81;
	default:
		return -1;


	}

}


extern mobj_t* setStateReturn;

//
// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.
//
void P_SpawnMapThing(mapthing_t* mthing, int16_t key)
{



	int16_t			i;
	int16_t			bit;
	mobj_t*		mobj;
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;
	MEMREF mobjRef;
	int16_t mthingtype = mthing->type;
	int16_t mthingoptions = mthing->options;
	int16_t mthingx = mthing->x;
	int16_t mthingy = mthing->y;
	int16_t mthingangle = mthing->angle;
	mapthing_t copyofthing = *mthing;




	if (mthing->type == 11 || mthing->type == 2 || mthing->type == 3 || mthing->type == 4) {
		return;
	}

	// check for players specially
	if (mthingtype == 1) {
		// save spots for respawning in network games
		P_SpawnPlayer(mthing);
		return;
	}


	// check for apropriate skill level
	if ((mthingoptions & 16)) {
		return;
	}
	if (gameskill == sk_baby) {
		bit = 1;
	}
	else if (gameskill == sk_nightmare) {
		bit = 4;
	}
	else {
		bit = 1 << (gameskill - 1);
	}
	if (!(mthingoptions & bit)) {

		return;
	}


	// find which type to spawn
	for (i = 0; i < NUMMOBJTYPES; i++) {
		if (mthingtype == getDoomEdNum(i)) {
			break;
		}
	}


#ifdef CHECK_FOR_ERRORS
	if (i == NUMMOBJTYPES) {
		I_Error("P_SpawnMapThing: Unknown type %i at (%i, %i)",
			mthingtype,
			mthingx, mthingy);
	}
#endif


	// don't spawn any monsters if -nomonsters
	if (nomonsters && (i == MT_SKULL || (mobjinfo[i].flags & MF_COUNTKILL))) {
		return;
	}

	// spawn it
	x.h.fracbits = 0;
	y.h.fracbits = 0;
	x.h.intbits = mthingx;
	y.h.intbits = mthingy;

	if (mobjinfo[i].flags & MF_SPAWNCEILING) {
		z.w = ONCEILINGZ;
	}
	else {
		z.w = ONFLOORZ;
	}

	mobjRef = P_SpawnMobj(x.w, y.w, z.w, i);

	mobj = setStateReturn;
	//mobj->spawnpoint = copyofthing;

	if (mobj->tics > 0 && mobj->tics < 240)
		mobj->tics = 1 + (P_Random() % mobj->tics);
	if (mobj->flags & MF_COUNTKILL)
		totalkills++;
	if (mobj->flags & MF_COUNTITEM)
		totalitems++;

	//todo does this work? or need to be in fixed_mul? -sq
	mobj->angle = ANG45 * (mthingangle / 45);

	if (mthingoptions & MTF_AMBUSH)
		mobj->flags |= MF_AMBUSH;


}



//
// P_LoadThings
//
void P_LoadThings(int16_t lump)
{
	mapthing_t *		data;
	uint16_t                 i;
	mapthing_t*         mt;
	uint16_t                 numthings;
	boolean             spawn;
	MEMREF				dataRef;
	W_CacheLumpNumCheck(lump, 5);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);

	numthings = W_LumpLength(lump) / sizeof(mapthing_t);

	for (i = 0; i < numthings; i++) {
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
	
		P_SpawnMapThing(mt, i);
	


	}

	Z_FreeEMS(dataRef);
}


//
// P_LoadLineDefs
// Also counts secret lines for intermissions.
//
void P_LoadLineDefs(int16_t lump)
{
	maplinedef_t *		data;
	uint16_t                 i;
	maplinedef_t*       mld;
	line_t*             ld;
	vertex_t*           v1;
	vertex_t*           v2;
	int16_t side0secnum;
	int16_t side1secnum;
	int16_t v1x;
	int16_t v1y;
	int16_t v2x;
	int16_t v2y;
	MEMREF dataRef;
	int16_t mldflags;
	uint8_t mldspecial;
	uint8_t mldtag;
	int16_t mldv1;
	int16_t mldv2;
	int16_t mldsidenum0;
	int16_t mldsidenum1;
	MEMREF linesRef;

	numlines = W_LumpLength(lump) / sizeof(maplinedef_t);
	linesRef = Z_MallocConventional(numlines * sizeof(line_t), PU_LEVEL, CA_TYPE_LEVELDATA, 0, ALLOC_TYPE_LINES);
	lines = (line_t*)Z_LoadBytesFromConventional(linesRef);

	memset(lines, 0, numlines * sizeof(line_t));
	W_CacheLumpNumCheck(lump, 6);
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);


	for (i = 0; i < numlines; i++) {
		data = (maplinedef_t *)  Z_LoadBytesFromEMS(dataRef);
		mld = &data[i];

		mldflags = (mld->flags);
		mldspecial = (mld->special);
		mldtag = (mld->tag);
		mldv1 = (mld->v1);
		mldv2 = (mld->v2);
		mldsidenum0 = (mld->sidenum[0]);
		mldsidenum1 = (mld->sidenum[1]);
		 

		side0secnum = sides[mldsidenum0].secnum;
		side1secnum = sides[mldsidenum1].secnum;
		v1 = &vertexes[mldv1];
		v2 = &vertexes[mldv2];
		v1x = v1->x;
		v1y = v1->y;
		v2x = v2->x;
		v2y = v2->y;

		ld = &lines[i];

		ld->sidenum[0] = mldsidenum0;
		ld->sidenum[1] = mldsidenum1;

		ld->flags = mldflags&0xff;
		ld->special = mldspecial;
		ld->tag = mldtag;
		ld->v1Offset = mldv1;
		ld->v2Offset = mldv2;
		ld->dx = v2x - v1x;
		ld->dy = v2y - v1y;
		
		// setting the slopetype in the high bits of v2Offset
		if (!ld->dx) {
			ld->v2Offset |= (ST_VERTICAL_HIGH);
		} else if (!ld->dy) {
			ld->v2Offset |= (ST_HORIZONTAL_HIGH);
		} else {
			if (FixedDiv(ld->dy, ld->dx) > 0) {
				ld->v2Offset |= (ST_POSITIVE_HIGH);
			} else {
				ld->v2Offset |= (ST_NEGATIVE_HIGH);
			}
		}

  
		ld->baseX = v1x;
		ld->baseY = v1y;

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

	Z_FreeEMS(dataRef);
}

uint8_t     R_TextureNumForNameB(int8_t* name);


//
// P_LoadSideDefs
//
void P_LoadSideDefs(int16_t lump)
{
	mapsidedef_t*               data;
	uint16_t                 i;
	mapsidedef_t*       msd;
	side_t*             sd;
	uint8_t toptex;
	uint8_t bottex;
	uint8_t midtex;
	MEMREF dataRef;
	int8_t texnametop[8];
	int8_t texnamemid[8];
	int8_t texnamebot[8];
	texsize_t msdtextureoffset;
	texsize_t msdrowoffset;
	int16_t msdsecnum;
	MEMREF sidesRef;

	numsides = W_LumpLength(lump) / sizeof(mapsidedef_t);
	sidesRef = Z_MallocConventional (numsides * sizeof(side_t), PU_LEVEL, CA_TYPE_LEVELDATA, 0, ALLOC_TYPE_SIDES);
	sides = (side_t*)Z_LoadBytesFromConventional(sidesRef);


	W_CacheLumpNumCheck(lump, 7);
	
	dataRef = W_CacheLumpNumEMS(lump, PU_STATIC);
	data = (mapsidedef_t *)Z_LoadBytesFromEMSWithOptions(dataRef, PAGE_LOCKED);


	for (i = 0; i < numsides; i++) {
		//data = (mapsidedef_t *)Z_LoadBytesFromEMS(dataRef);
		msd = &data[i];

		msdtextureoffset = (msd->textureoffset);
		msdrowoffset = (msd->rowoffset);
		msdsecnum = (msd->sector);

		memcpy(texnametop, msd->toptexture, 8);
		memcpy(texnamebot, msd->bottomtexture, 8);
		memcpy(texnamemid, msd->midtexture, 8);

		// side i = 225 textop "bigdoor4-" not found??

		toptex = R_TextureNumForNameB(texnametop);
		bottex = R_TextureNumForNameB(texnamebot);
		midtex = R_TextureNumForNameB(texnamemid);
		
		// sides gets unloaded by the above calls, and theres not enough room in ems to 
		// hold it in memory in the worst case alongside data
		sd = &sides[i];
		sd->toptexture = toptex;
		sd->bottomtexture = bottex;
		sd->midtexture = midtex;

		sd->textureoffset = msdtextureoffset;
		sd->rowoffset = msdrowoffset;
		sd->secnum = msdsecnum;


	}

	Z_SetUnlocked(dataRef);
	Z_FreeEMS(dataRef);
}


//
// P_LoadBlockMap
//
void P_LoadBlockMap(int16_t lump)
{
	uint16_t         i;
	uint16_t         count;
	int16_t*		blockmaplump;
	fixed_t_union temp;
	temp.h.fracbits = 0;

	W_CacheLumpNumCheck(lump, 8);
	
	blockmaplumpRef = W_CacheLumpNumEMS(lump, PU_LEVEL);
	blockmaplump = (int16_t*)Z_LoadBytesFromEMS(blockmaplumpRef);
	//blockmapOffset = 4;  // only ever 4? deleted..
	count = W_LumpLength(lump) / 2;

	for (i = 0; i < count; i++)
		blockmaplump[i] = (blockmaplump[i]);
	
	bmaporgx = blockmaplump[0];
	bmaporgy = blockmaplump[1];
	bmapwidth = blockmaplump[2];
	bmapheight = blockmaplump[3];

	// clear out mobj chains
	count = sizeof(*blocklinks)* bmapwidth*bmapheight;

	//	blocklinksRef = Z_MallocEMS (count, PU_LEVEL, 0, ALLOC_TYPE_BLOCKLINKS);
	memset(blocklinks, 0, count);
}



//
// P_GroupLines
// Builds sector line lists and subsector sector numbers.
// Finds block bounding boxes for sectors.
//
void P_GroupLines(void)
{
	uint16_t                 i;
	uint16_t                 j;
	uint16_t                 total;
	line_t*             li;
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
	uint8_t				sectorlinecount;
	fixed_t_union		tempv1;
	fixed_t_union		tempv2;
	MEMREF linebufferRef;
	int16_t* sectorBlockBoxes;
	// look up sector number for each subsector
	for (i = 0; i < numsubsectors; i++) {
		firstlinenum = subsectors[i].firstline;
		
		sidedefOffset = segs[firstlinenum].sidedefOffset;
		sidesecnum = sides[sidedefOffset].secnum;

		subsectors[i].secnum = sidesecnum;

	}


	// count number of lines in each sector
	total = 0;
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

	linebufferRef = Z_MallocConventional (total * 2, PU_LEVEL, CA_TYPE_LEVELDATA,0, ALLOC_TYPE_LINEBUFFER);
	linebuffer = (int16_t*)Z_LoadBytesFromConventional(linebufferRef);
	linebufferindex = 0;

	tempv1.h.fracbits = 0;
	tempv2.h.fracbits = 0;
	sectorBlockBoxesRef = Z_MallocEMS(numsectors * 8, PU_LEVEL, 0, ALLOC_TYPE_SECTORS);
	sectorBlockBoxes = (int16_t*)Z_LoadBytesFromEMS(sectorBlockBoxesRef);
	for (i = 0; i < numsectors; i++) {
		M_ClearBox16(bbox);
		
		sectorlinecount = sectors[i].linecount;

		sectors[i].linesoffset = linebufferindex;
		previouslinebufferindex = linebufferindex;
	 
		for (j = 0; j < numlines; j++) {
			li = &lines[j];
			linev1Offset = li->v1Offset & VERTEX_OFFSET_MASK;
			linev2Offset = li->v2Offset & VERTEX_OFFSET_MASK;

			if (li->frontsecnum == i || li->backsecnum == i) {
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
		

		sectors[i].soundorgX = (bbox[BOXRIGHT] + bbox[BOXLEFT]) / 2;
		sectors[i].soundorgY = (bbox[BOXTOP] + bbox[BOXBOTTOM]) / 2;

		// adjust bounding box to map blocks
		block = (bbox[BOXTOP] - bmaporgy + MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block >= bmapheight ? bmapheight - 1 : block;
		sectorBlockBoxes[i*4+BOXTOP] = block;

		block = (bbox[BOXBOTTOM] - bmaporgy - MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block < 0 ? 0 : block;
		sectorBlockBoxes[i * 4 + BOXBOTTOM] = block;

		block = (bbox[BOXRIGHT] - bmaporgx + MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block >= bmapwidth ? bmapwidth - 1 : block;
		sectorBlockBoxes[i * 4 + BOXRIGHT] = block;

		block = (bbox[BOXLEFT] - bmaporgx - MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
		block = block < 0 ? 0 : block;
		sectorBlockBoxes[i * 4 + BOXLEFT] = block;
	}



}






//
// P_SetupLevel
//
void
P_SetupLevel
(int8_t           episode,
	int8_t           map,
	skill_t       skill)
{
	int8_t        lumpname[9];
	int16_t         lumpnum;

	uint32_t time;


	wminfo.partime = 180;
	player.killcount = player.secretcount = player.itemcount = 0;

	// Initial height of PointOfView
	// will be set by player think.
	player.viewz = 1;

	S_Start();
	Z_FreeTagsEMS(PU_LEVEL);
	Z_FreeConventionalAllocations();

	TEXT_MODE_DEBUG_PRINT("\n P_InitThinkers");
	P_InitThinkers();

	// if working with a devlopment map, reload it

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

	leveltime.w = 0;

	time = ticcount;


	TEXT_MODE_DEBUG_PRINT("\n P_LoadBlockMap");
	// note: most of this ordering is important 
	P_LoadBlockMap(lumpnum + ML_BLOCKMAP);
	TEXT_MODE_DEBUG_PRINT("\n P_LoadVertexes");
	P_LoadVertexes(lumpnum + ML_VERTEXES);
	TEXT_MODE_DEBUG_PRINT("\n P_LoadSectors");
	P_LoadSectors(lumpnum + ML_SECTORS);
	TEXT_MODE_DEBUG_PRINT("\n P_LoadSideDefs");
	P_LoadSideDefs(lumpnum + ML_SIDEDEFS);

	TEXT_MODE_DEBUG_PRINT("\n P_LoadLineDefs");
	P_LoadLineDefs(lumpnum + ML_LINEDEFS);
	TEXT_MODE_DEBUG_PRINT("\n P_LoadSubsectors");
	P_LoadSubsectors(lumpnum + ML_SSECTORS);
	TEXT_MODE_DEBUG_PRINT("\n P_LoadNodes");
	P_LoadNodes(lumpnum + ML_NODES);

	TEXT_MODE_DEBUG_PRINT("\n P_LoadSegs");
	P_LoadSegs(lumpnum + ML_SEGS);


	//     sector    linedef      node      linebuffer
	// side     vertex     subsec       seg
	// 1223 170   896   958  467  466   1371        num x
	//    7  23     4    27    5   28     12        sizeof type
	// 8561 3910 3584 25866 2335 13048 16452  2440  bytes used
	//								   21936
	//   3    2     1     4    5     6     7     8  load order
	//                           57304        18892
	//											24376

	/*
	I_Error("%i %i %i %i %i %i %i %i %i %i",
		sizeof(side_t), sizeof(sector_t), sizeof(vertex_t), sizeof(line_t), sizeof(subsector_t),
		sizeof(node_t), sizeof(seg_t), 0, 0, 0
	);;
	*/

	W_CacheLumpNumCheck(lumpnum + ML_REJECT, 9);
	rejectmatrixRef = W_CacheLumpNumEMS(lumpnum + ML_REJECT, PU_LEVEL);

	P_GroupLines(); // 49 tics (362 ics total  in 16 bit, 45 tics in 32 bit)

	bodyqueslot = 0;

	TEXT_MODE_DEBUG_PRINT("\n P_LoadThings");
	P_LoadThings(lumpnum + ML_THINGS);// 15 tics 


	// set up world state
	TEXT_MODE_DEBUG_PRINT("\n P_SpawnSpecials");
	P_SpawnSpecials();  // 3 tics

	// preload graphics
	if (precache)
		R_PrecacheLevel();



}

