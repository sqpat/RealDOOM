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
#include <dos.h>	

void    P_SpawnMapThing(mapthing_t     mthing, int16_t key);

//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
int16_t             numvertexes;
vertex_t*		vertexes;

int16_t             numsegs;
seg_t*				segs;
seg_physics_t*		segs_physics;
seg_render_t*		segs_render;

int16_t             numsectors;
sector_t*		sectors;
sector_physics_t* sectors_physics;

int16_t             numsubsectors;
subsector_t*    subsectors;

int16_t             numnodes;
node_t*				nodes;
node_render_t*      nodes_render;



int16_t             numlines;
line_t*			lines;
uint8_t*		seenlines;
line_physics_t*	lines_physics;

int16_t             numsides;
side_t*				sides;
side_render_t*		sides_render;
int16_t*          linebuffer;

// for things nightmare respawn data
mapthing_t*			nightmarespawns;

#ifdef PRECALCULATE_OPENINGS
lineopening_t*	lineopenings;
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
int16_t*		blockmaplump;

// origin of block map
// todo can this be made 16 bit
int16_t         bmaporgx;
int16_t         bmaporgy;

// for thing chains
THINKERREF*		blocklinks;

// REJECT
// For fast sight rejection.
// Speeds up enemy AI by skipping detailed
//  LineOf Sight calculation.
// Without special effect, this could be
//  used as a PVS lookup as well.
//
byte* far           rejectmatrix;

uint16_t leveldataoffset_phys = 0u;
uint16_t leveldataoffset_rend = 0 - (MAX_THINKERS * sizeof(mobj_pos_t));
uint16_t leveldataoffset_6000_phys = 0u;

byte* far	SCRATCH_ADDRESS = (byte* far)0x40000000;

#define Z_GetNextPhysicsAddress(A) Z_GetNext0x7000Address(A, PAGE_TYPE_PHYSICS)
#define Z_GetNextRenderAddress(A) Z_GetNext0x7000Address(A, PAGE_TYPE_RENDER)
#define Z_SubtractRenderAddress(A) Z_Subtract0x7000Address(A, PAGE_TYPE_RENDER)

byte* far Z_GetNext0x6000Address(uint16_t size) {

	uint16_t oldoffset = leveldataoffset_6000_phys;
	byte* far returnvalue;
	

	leveldataoffset_6000_phys -= size;
	returnvalue = MK_FP(0x6000, leveldataoffset_6000_phys);

	if (leveldataoffset_6000_phys < 32768u) {
		// wraparound
		I_Error("Allocated too much space in Z_GetNext0x6000Address (size %u) ", size);
	}
	return returnvalue;

}

byte* far Z_GetNext0x7000Address(uint16_t size, int8_t pagetype) {

	uint16_t oldoffset;
	uint16_t *useoffset;
	byte* far returnvalue;
	switch (pagetype) {
	case PAGE_TYPE_PHYSICS:
		oldoffset = leveldataoffset_phys;
		useoffset = &leveldataoffset_phys;
		break;
	case PAGE_TYPE_RENDER:
		oldoffset = leveldataoffset_rend;
		useoffset = &leveldataoffset_rend;
		break;
	}

	*useoffset -= size;
	returnvalue = MK_FP(0x7000, *useoffset);

	if (oldoffset != 0 && (oldoffset < *useoffset)) {
		// wraparound
		if (pagetype == PAGE_TYPE_PHYSICS) {
			*useoffset += size;
			return Z_GetNext0x6000Address(size);
		}

		I_Error("Allocated too much space in Z_GetNext0x7000Address (size %u type %hhu) ", size, pagetype);
	}
	return returnvalue;

}

void Z_Subtract0x7000Address(uint16_t size, int8_t pagetype) {

	switch (pagetype) {
	case PAGE_TYPE_PHYSICS:
		leveldataoffset_phys += size;
		return;
	case PAGE_TYPE_RENDER:
		leveldataoffset_rend += size;
		return;
	}


}

 
//
// P_LoadVertexes
//
void P_LoadVertexes(int16_t lump)
{
	mapvertex_t*			data;
	uint16_t                 i;
	mapvertex_t			ml;
	MEMREF vertexesRef;
	// Determine number of lumps:
	//  total lump length / vertex record length.
	numvertexes = W_LumpLength(lump) / sizeof(mapvertex_t);

	// Allocate zone memory for buffer.
	vertexesRef = Z_MallocConventional(numvertexes * sizeof(vertex_t));
	vertexes = Z_LoadBytesFromConventional(vertexesRef);
	// Load data into cache.
	
	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (mapvertex_t*)SCRATCH_ADDRESS;

	// Copy and convert vertex coordinates,
	// internal representation as fixed.
	for (i = 0; i < numvertexes; i++) {
		ml = data[i];

		vertexes[i].x = (ml.x);
		vertexes[i].y = (ml.y);
	}

	// Free buffer memory.
 }



//
// P_LoadSegs
//
void P_LoadSegs(int16_t lump)
{
 	mapseg_t *          data;
	uint16_t                 i;
	mapseg_t*           ml;
	seg_t*              li;
	seg_render_t*              li_render;
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
	MEMREF segsRef;
	int16_t* tempsecnums;
	Z_QuickmapRender_NoTex();

	numsegs = W_LumpLength(lump) / sizeof(mapseg_t);
	segsRef = Z_MallocConventional(numsegs * sizeof(seg_t));
	segs = (seg_t*)Z_LoadBytesFromConventional(segsRef);

	segs_render = (seg_render_t* far)Z_GetNextRenderAddress(numsegs * sizeof(seg_render_t));
	segs_physics = (seg_physics_t* far)Z_GetNextPhysicsAddress(numsegs * sizeof(seg_physics_t));

	// ugly, gross, but this memory is free right now...
	tempsecnums = (int16_t* far)Z_GetNextRenderAddress(numsegs * 2 * sizeof(int16_t));

	memset(segs, 0xff, numsegs * sizeof(seg_t));
	
	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (mapseg_t*)SCRATCH_ADDRESS;

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


		sidesecnum = sides_render[ldefsidenum].secnum;
		othersidesecnum = sides_render[ldefothersidenum].secnum;


		li = &segs[i];
		li->side = side ? 1 : 0;
		li->linedefOffset = mllinedef;
	
		li_render = &segs_render[i];
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
	
	
	Z_QuickmapPhysics();
	Z_QuickmapRender7000to6000();
	

	tempsecnums = MK_FP(0x6000u, (uint16_t)((uint32_t)tempsecnums & 0xFFFFu));


	for (i = 0; i < numsegs; i++) {
		segs_physics[i].frontsecnum = tempsecnums[i * 2];
		segs_physics[i].backsecnum  = tempsecnums[i * 2 + 1];
	}
	
	// and now we put it back..

	Z_SubtractRenderAddress(numsegs * 2 * sizeof(int16_t));
	Z_QuickmapPhysics();

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
	MEMREF		subsectorsRef;
	numsubsectors = W_LumpLength(lump) / sizeof(mapsubsector_t);
	subsectorsRef = Z_MallocConventional (numsubsectors * sizeof(subsector_t));
	subsectors = (subsector_t*)Z_LoadBytesFromConventional(subsectorsRef);
	memset(subsectors, 0, numsubsectors * sizeof(subsector_t));

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (mapsubsector_t*)SCRATCH_ADDRESS;

	for (i = 0; i < numsubsectors; i++)
	{
		ms = &data[i];
		ss = &subsectors[i];
		ss->numlines = (ms->numsegs);
		ss->firstline = (ms->firstseg);

	}

}



//
// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
//
// note this function got duped across different overlays, but this ends up reducing overall conventional memory use
uint8_t R_FlatNumForNameC(int8_t* name)
{
	int16_t         i;

	i = W_CheckNumForName(name);


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
	sector_physics_t*   sp;
	MEMREF				sectorsRef;
	// most tags are under 100, a couple are like 666 or 667 or 999 or other such special numbers.
	// we will special case those and fit it in 8 bits so allocations are smaller
	int16_t convertedtag;
	numsectors = W_LumpLength(lump) / sizeof(mapsector_t);

	sectorsRef = Z_MallocConventional (numsectors * sizeof(sector_t));
	sectors = (sector_t*) Z_LoadBytesFromConventional(sectorsRef);

	sectors_physics  = (sector_physics_t*)Z_GetNextPhysicsAddress(numsectors * sizeof(sector_physics_t));

	memset(sectors, 0, numsectors * sizeof(sector_t));
	memset(sectors_physics, 0, numsectors * sizeof(sector_physics_t));

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (mapsector_t*)SCRATCH_ADDRESS;

	ss = sectors;
	sp = sectors_physics;
	for (i = 0; i < numsectors; i++, ss++, sp++) {
		ms = data[i];
		convertedtag = ms.tag;
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
		} else if (convertedtag >= 58) {
			I_Error("found (sector) line tag that was too high! %i %i", convertedtag, i);
		}
		ss->floorheight = (ms.floorheight) << SHORTFLOORBITS;
		ss->ceilingheight = (ms.ceilingheight) << SHORTFLOORBITS;
		ss->floorpic = R_FlatNumForNameC(ms.floorpic);
		ss->ceilingpic = R_FlatNumForNameC(ms.ceilingpic);
		ss->lightlevel = (ms.lightlevel);
		ss->thinglistRef = NULL_THINKERREF;
		
		sp->tag = (convertedtag);
		sp->special = (ms.special);

 

	}

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
	node_render_t* no_render;

	mapnode_t	currentdata;
	MEMREF	nodesRef;

	numnodes = W_LumpLength(lump) / sizeof(mapnode_t);
	nodesRef = Z_MallocConventional(numnodes * sizeof(node_t));
	nodes = (node_t*)Z_LoadBytesFromConventional(nodesRef);
	nodes_render = (node_render_t* far) Z_GetNextRenderAddress(numnodes * sizeof(node_render_t));


	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (mapnode_t*)SCRATCH_ADDRESS;
	Z_QuickmapRender_NoTex();


	for (i = 0; i < numnodes; i++) {
		currentdata = data[i];
		no = &nodes[i];
		no_render = &nodes_render[i];

		no->x = (currentdata.x);
		no->y = (currentdata.y);
		no->dx = (currentdata.dx);
		no->dy = (currentdata.dy);
		for (j = 0; j < 2; j++) {
			no->children[j] = (currentdata.children[j]);
			for (k = 0; k < 4; k++) {
				no_render->bbox[j][k] = (currentdata.bbox[j][k]);
			}
		}
 	}
	Z_QuickmapPhysics();

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
extern mobj_t* setStateReturn;
extern mobj_pos_t* setStateReturn_pos;

void ST_Start(void);
void G_PlayerReborn();
void HU_Start(void);

void P_SpawnPlayer(mapthing_t* mthing)
{
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;

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

	playerMobjRef = P_SpawnMobj(x.w, y.w, z.w, MT_PLAYER, -1);
	playerMobj = setStateReturn;
	playerMobj_pos = setStateReturn_pos;
	playerMobj->reactiontime = 0;

	playerMobj_pos->angle.wu = ANG45 * (mthingangle / 45);
	playerMobj->health = player.health;


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

	Z_QuickmapStatus();

	// wake up the status bar
	ST_Start();

	// wake up the heads up text
	HU_Start();

	Z_QuickmapPhysics();

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
void P_SpawnMapThing(mapthing_t mthing, int16_t key)
{



	int16_t			i;
	int16_t			bit;
	mobj_t*		mobj;
	mobj_pos_t* mobj_pos;
	fixed_t_union		x;
	fixed_t_union		y;
	fixed_t_union		z;
	THINKERREF mobjRef;
	int16_t mthingtype = mthing.type;
	int16_t mthingoptions = mthing.options;
	int16_t mthingx = mthing.x;
	int16_t mthingy = mthing.y;
	int16_t mthingangle = mthing.angle;




	if (mthing.type == 11 || mthing.type == 2 || mthing.type == 3 || mthing.type == 4) {
		return;
	}

	// check for players specially
	if (mthingtype == 1) {
		// save spots for respawning in network games
		P_SpawnPlayer(&mthing);
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

	mobjRef = P_SpawnMobj(x.w, y.w, z.w, i, -1);

	mobj = setStateReturn;
	mobj_pos = setStateReturn_pos;
	nightmarespawns[mobjRef] = mthing;

	if (mobj->tics > 0 && mobj->tics < 240)
		mobj->tics = 1 + (P_Random() % mobj->tics);
	if (mobj_pos->flags & MF_COUNTKILL)
		totalkills++;
	if (mobj_pos->flags & MF_COUNTITEM)
		totalitems++;

	//todo does this work? or need to be in fixed_mul? -sq
	mobj_pos->angle.wu = ANG45 * (mthingangle / 45);

	if (mthingoptions & MTF_AMBUSH)
		mobj_pos->flags |= MF_AMBUSH;

 

}
#ifdef PRECALCULATE_OPENINGS

void P_CacheLineOpenings() {
	int16_t linenum, linefrontsecnum, linebacksecnum;
	sector_t* front;
	sector_t* back;
	

	lineopenings = (lineopening_t* far)Z_GetNextPhysicsAddress(numlines * sizeof(lineopening_t));
	memset(lineopenings, 0, numlines * sizeof(lineopening_t));

	for (linenum = 0; linenum < numlines; linenum++) {
		int16_t lineside1 = lines[linenum].sidenum[1];
		if (lineside1 == -1) {
			// single sided line
			continue;
		}
		linefrontsecnum = lines_physics[linenum].frontsecnum;
		linebacksecnum = lines_physics[linenum].backsecnum;

		front = &sectors[linefrontsecnum];
		back = &sectors[linebacksecnum];

		if (front->ceilingheight < back->ceilingheight) {
			lineopenings[linenum].opentop = front->ceilingheight;
		}
		else {
			lineopenings[linenum].opentop = back->ceilingheight;
		}
		if (front->floorheight > back->floorheight) {
			lineopenings[linenum].openbottom = front->floorheight;
			lineopenings[linenum].lowfloor = back->floorheight;
		}
		else {
			lineopenings[linenum].openbottom = back->floorheight;
			lineopenings[linenum].lowfloor = front->floorheight;
		}

		//lineopenings[linenum].openrange = lineopenings[linenum].opentop - lineopenings[linenum].openbottom;
	}
	 
}

#endif
//
// P_LoadThings
//
void P_LoadThings(int16_t lump)
{
	mapthing_t *		data;
	uint16_t                 i;
	mapthing_t         mt;
	uint16_t                 numthings;
	boolean             spawn;
	
	memset(nightmarespawns, 0, sizeof(mapthing_t) * MAX_THINKERS);
 
	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (mapthing_t*)SCRATCH_ADDRESS;

	numthings = W_LumpLength(lump) / sizeof(mapthing_t);
	for (i = 0; i < numthings; i++) {
		mt = data[i];
		spawn = true;

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
void P_LoadLineDefs(int16_t lump)
{
	maplinedef_t *		data;
	uint16_t                 i;
	maplinedef_t*       mld;
	line_t*             ld;
	line_physics_t*             ld_physics;
	vertex_t*           v1;
	vertex_t*           v2;
	int16_t side0secnum;
	int16_t side1secnum;
	int16_t v1x;
	int16_t v1y;
	int16_t v2x;
	int16_t v2y;
	int16_t mldflags;
	uint8_t mldspecial;
	uint8_t mldtag;
	int16_t mldv1;
	int16_t mldv2;
	int16_t mldsidenum0;
	int16_t mldsidenum1;
	MEMREF linesRef;
	int16_t convertedtag;
	MEMREF seenlinesRef;
	side_render_t* tempsides_render;

	numlines = W_LumpLength(lump) / sizeof(maplinedef_t);
	linesRef = Z_MallocConventional(numlines * sizeof(line_t));
	lines = (line_t* far)Z_LoadBytesFromConventional(linesRef);

	lines_physics = (line_physics_t* far)Z_GetNextPhysicsAddress(numlines * sizeof(line_physics_t));

	seenlinesRef = Z_MallocConventional(numlines/8+1);
	seenlines = (uint8_t*)Z_LoadBytesFromConventional(seenlinesRef);
	memset(lines, 0, numlines * sizeof(line_t));
	memset(lines_physics, 0, numlines * sizeof(line_physics_t));
	memset(seenlines, 0, numlines / 8 + 1);

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (maplinedef_t*)SCRATCH_ADDRESS;

	Z_QuickmapRender7000to6000();
	tempsides_render = MK_FP(0x6000u, (uint16_t)((uint32_t)sides_render & 0xFFFFu));

	for (i = 0; i < numlines; i++) {
		mld = &data[i];

		mldflags = (mld->flags);
		mldspecial = (mld->special);
		mldtag = (mld->tag);
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

		convertedtag = mldtag;
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
		} else if (convertedtag >= 58) {
			I_Error("found (line) line tag that was too high! %i %i", convertedtag, i);
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

		side0secnum = tempsides_render[mldsidenum0].secnum;
		side1secnum = tempsides_render[mldsidenum1].secnum;

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

	 

	Z_QuickmapPhysics();
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
	side_render_t*             sd_render;
	uint8_t toptex;
	uint8_t bottex;
	uint8_t midtex;
	int8_t texnametop[8];
	int8_t texnamemid[8];
	int8_t texnamebot[8];
	texsize_t msdtextureoffset;
	texsize_t msdrowoffset;
	int16_t msdsecnum;
	MEMREF sidesRef;

	Z_QuickmapRender_NoTex();
	//Z_QuickmapTextureInfoPage();

	numsides = W_LumpLength(lump) / sizeof(mapsidedef_t);
	sidesRef = Z_MallocConventional (numsides * sizeof(side_t));
	sides = (side_t*)Z_LoadBytesFromConventional(sidesRef);
	sides_render = (side_render_t*) Z_GetNextRenderAddress(numsides * sizeof(side_render_t));


	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS);
	data = (mapsidedef_t*)SCRATCH_ADDRESS;

	for (i = 0; i < numsides; i++) {
		msd = &data[i];

		msdtextureoffset = (msd->textureoffset);
		msdrowoffset = (msd->rowoffset);
		msdsecnum = (msd->sector);

		memcpy(texnametop, msd->toptexture, 8);
		memcpy(texnamebot, msd->bottomtexture, 8);
		memcpy(texnamemid, msd->midtexture, 8);

  
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

		sd_render = &sides_render[i];
		sd_render->rowoffset = msdrowoffset;
		sd_render->secnum = msdsecnum;


	}


	Z_QuickmapPhysics();

}


//
// P_LoadBlockMap
//
void P_LoadBlockMap(int16_t lump)
{
	uint16_t         count;

	MEMREF			blocklinksRef;




	blockmaplump = (int16_t* far)Z_GetNextPhysicsAddress(W_LumpLength(lump));
	W_CacheLumpNumDirect(lump, (byte*)blockmaplump);


	
	bmaporgx = blockmaplump[0];
	bmaporgy = blockmaplump[1];
	bmapwidth = blockmaplump[2];
	bmapheight = blockmaplump[3];

	// 9700 52 56     2 * 52 * 56 too big?  5824 
	// 4423 32 27 


	// clear out mobj chains

	count = sizeof(THINKERREF) * bmapwidth*bmapheight;

	blocklinks = (THINKERREF*) Z_GetNextPhysicsAddress(count);

	memset(blocklinks, 0, count);
}


uint16_t                 total;

//
// P_GroupLines
// Builds sector line lists and subsector sector numbers.
// Finds block bounding boxes for sectors.
//
void P_GroupLines(void)
{
	uint16_t                 i;
	uint16_t                 j;
	line_physics_t*     li_physics;
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

	Z_QuickmapRender_NoTex();

	// look up sector number for each subsector
	for (i = 0; i < numsubsectors; i++) {
		firstlinenum = subsectors[i].firstline;
		
		sidedefOffset = segs_render[firstlinenum].sidedefOffset;
		sidesecnum = sides_render[sidedefOffset].secnum;
		subsectors[i].secnum = sidesecnum;

	}

	Z_QuickmapPhysics();

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

	linebuffer = (int16_t* far)Z_GetNextPhysicsAddress(total * sizeof(int16_t));
	linebufferindex = 0;

	tempv1.h.fracbits = 0;
	tempv2.h.fracbits = 0;


	for (i = 0; i < numsectors; i++) {
		M_ClearBox16(bbox);
		
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
void P_InitThinkers(void)
{
	int16_t i;
	thinkerlist[0].next = 1;
	thinkerlist[0].prevFunctype = 1;


	for (i = 0; i < MAX_THINKERS; i++) {
		thinkerlist[i].prevFunctype = MAX_THINKERS;
	}

	currentThinkerListHead = 0;

}


extern uint16_t remainingconventional1;
extern uint16_t leveldataoffset_phys;
extern uint16_t leveldataoffset_rend;

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



	wminfo.partime = 180;
	player.killcount = player.secretcount = player.itemcount = 0;

	// Initial height of PointOfView
	// will be set by player think.
	player.viewz = 1;
	
	W_EraseFullscreenCache();
	S_Start();
	Z_FreeConventionalAllocations();

	// TODO reset 32 bit counters to start values here..
	validcount = 1;

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

	Z_QuickmapScratch_4000();
	
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

	P_GroupLines(); // 49 tics (362 ics total  in 16 bit, 45 tics in 32 bit)

#ifdef PRECALCULATE_OPENINGS
	P_CacheLineOpenings();
#endif

	bodyqueslot = 0;





	//     sector    linedef      subsec      seg      linebuffer
	// side     vertex     seenlines   node     lineopenings   blocklinks

	// e1m1
	// 648    85  467   475	  475   237  236   732    475   642    828			num x
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	//  2592 1360 1868 4275    60  1185 2832  2196   3325  1284   1656	 	bytes used
	//	49040 42021 52496
	//   3    2     1     4    5     6     7     8		load order

	// e1m2
	// 1323 200  942   1033  1033   448  447   1463 1033  1322    1302
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	// 5292 3200 3768  9297  130  2240  5364  4389 7231  2644   2604
	// 31728 18939 39785


	// e1m3
	// 1326 177  946   1026  1026  461  460  1445	   1026 1318   850
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	// 5304 2832 3784 9234   129  2305 5520 4335   7182 2636  1700
	//  31965 23492 39748

		// e1m4
	// 1054 139  780   830    830    355  354   1172   830  1051   660
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	// 4216 2224 3120 7470   104   1775 4248 3516  5810  2102  1320
	// 38735 31658 44990 

	// e1m5
	// 1053 143  746   825   825    384  383   1141   825  1051    832
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	// 4212 2288 2984 7425  104   1920 4596    3423   5775 2102   1664
	//	38456 30639 44839
	//     sector    linedef      subsec      seg      linebuffer
	// side     vertex     seenlines   node     lineopenings   blocklinks


	// biggest shareware e1m6?
	// 1727  250  1207 1352  1352   606  605  1862     1352 1719  1748
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	// 6908 4000 4828 12168   170  3030  7260 5586     9464   3438 3496
	//	21458  4662 32055
	
	// e1m7 timedemo 3
	//     sector    linedef      subsec      seg      linebuffer
	// side     vertex     seenlines   node     lineopenings   blocklinks
	// 1223 170   896   958  958   467  466   1371   958	1220   864				count
	//   4   16     4    9  /8+1     5   12    3	   7	  2	     2		size of type
	// 4892 2720 3584  8622  120  2335 5592  4113  6707  2440	1728				bytes used
	// 33430 25436 40701
	
	//   3    2     1     4    5     6     7     8		load order
	
	// e1m8
	// 511   74   328   333  333    177  176    586   333   507   2912
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	// 2044 1184 1312  2997   42    885 2112   1758  2331  1014   5824
	// 53074 29147 55327

	// e1m9
	// 902  147  581    653  653    288  287    978   653   898    702
	//   4   16     4    9  /8+1     5   12    3	      7	  2	     2		size of type
	// 3608 2352 2324  5877   41   1440 3444  2934  4571  1796   1404
	// 43347 36297 48458

	// doom 2 map 14
	//  side sect vert line	 subsec node   seg
	//	2587 348  1429 1681   851  850	  2815  
	// 10344 5568 5716 15129 4255 10200   8445
	//                                     59657 up to here. Static UMB probably free but will probably go way over in physics task memory - but there should be free memory in the 4000 or 5000 region
	

	/*
	I_Error("\n\n%u %u %u %u %u %u %u %u %u %u \n%u %u %u %u %u %u %u %u %u %u\n%u %u %u %u %u %u %u %u %u %u\n%p %p %p %p %p %p %p %p\n\n %p \n%u %u %u",
		sizeof(side_t), sizeof(sector_t), sizeof(vertex_t), sizeof(line_t),
		sizeof(subsector_t), sizeof(node_t), sizeof(seg_t), sizeof(lineopening_t), 2, sizeof(THINKERREF),
		
		numsides , numsectors , numvertexes , numlines ,
		numsubsectors , numnodes , numsegs  , numlines , total,  bmapheight * bmapwidth,


		numsides * sizeof(side_t), numsectors * sizeof(sector_t), numvertexes * sizeof(vertex_t), numlines * sizeof(line_t),
		numsubsectors * sizeof(subsector_t), numnodes * sizeof(node_t), numsegs * sizeof(seg_t), numlines * sizeof(lineopening_t), total * 2, bmapheight * bmapwidth *sizeof(THINKERREF),
		
		sides, sectors, vertexes, lines,
		subsectors, nodes, vertexes, lineopenings,
		
		conventionalmemoryblock, 
		remainingconventional, leveldataoffset_phys, leveldataoffset_rend
	);
	*/
	
	P_LoadThings(lumpnum + ML_THINGS);// 15 tics 


	// set up world state
	P_SpawnSpecials();  // 3 tics

	// preload graphics
	if (precache)
		R_PrecacheLevel();



}

