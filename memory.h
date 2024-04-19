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
//	Refresh/render internal state variables (global).
//

#include "r_data.h"

#ifndef __MEMORY_H__
#define __MEMORY_H__


#define colormaps		((lighttable_t  __far*			) 0x80000000)



/*

#define colormapbytes				8000:0000
#define openings					8000:2100
#define negonearray					8000:c100
#define screenheightarray			8000:c380
#define vissprites					8000:c600
#define scalelightfixed				8000:e100
#define scalelight					8000:e1c0
#define usedcompositetexturepagemem 8000:edc0
#define usedspritepagemem			8000:edd8
#define usedpatchpagemem			8000:edfc

#define compositetextureoffset		8000:ee24
#define compositetexturepage		8000:efd0
#define spritepage					8000:f17c
#define spriteoffset				8000:f6e1
#define patchpage					8000:fc46
#define patchoffset					8000:fe22
									8000:fffe
*/


/*
#define visplanes				9000:0000
#define visplaneheaders			9000:9948
#define yslope					9000:9d17
#define distscale				9000:a037
#define cachedheight			9000:a537
#define cacheddistance			9000:a857
#define cachedxstep				9000:ab77
#define cachedystep				9000:ae97
#define spanstart				9000:b1b7
#define viewangletox			9000:b4d7
#define xtoviewangle			9000:d4d7
#define drawsegs				9000:d759
#define floorclip				9000:fa59
#define ceilingclip				9000:fcd9
#define flatindex				9000:ff59
								9000:fff0
*/

// RENDER 0x9000

#define size_visplanes				(0						+ sizeof(visplane_t) * MAXCONVENTIONALVISPLANES)
#define size_visplaneheaders		size_visplanes			+ sizeof(visplaneheader_t) * MAXEMSVISPLANES
#define size_drawsegs				size_visplaneheaders	+ (sizeof(drawseg_t) * (MAXDRAWSEGS))
#define size_flatindex				size_drawsegs			+ (sizeof(uint8_t) * MAX_FLATS)
#define size_sides_render			size_flatindex			+ MAX_SIDES_RENDER_SIZE
#define size_player_vissprites		size_sides_render		+ (sizeof(vissprite_t) * 2)
#define size_texturedefs_offset		size_player_vissprites	+ MAX_TEXTURES * sizeof(uint16_t)
#define size_texturewidthmasks		size_texturedefs_offset	+ MAX_TEXTURES * sizeof(uint8_t)



#define visplanes				((visplane_t __far*)			(0x90000000 + 0))
#define visplaneheaders			((visplaneheader_t __far*)		(0x90000000 + size_visplanes))
#define drawsegs				((drawseg_t __far*)				(0x90000000 + size_visplaneheaders))
#define flatindex				((uint8_t __far*)				(0x90000000 + size_drawsegs))
#define sides_render			((side_render_t __far*)			(0x90000000 + size_flatindex))
#define player_vissprites		((vissprite_t __far*)			(0x90000000 + size_sides_render))
#define texturedefs_offset		((uint16_t	__far*)				(0x90000000 + size_player_vissprites))
#define texturewidthmasks		((uint8_t	__far*)				(0x90000000 + size_texturedefs_offset))

// deff

// RENDER 0x8000

#define size_leftover_openings	0x2000

#define size_colormapbytes					((33 * 256) + size_leftover_openings)
#define size_scalelightfixed				size_colormapbytes					+ sizeof(lighttable_t __far* ) * (MAXLIGHTSCALE)
#define size_scalelight						size_scalelightfixed				+ sizeof(lighttable_t __far*) * (LIGHTLEVELS * MAXLIGHTSCALE)
#define size_usedcompositetexturepagemem	size_scalelight						+ NUM_TEXTURE_PAGES * sizeof(uint8_t)
#define size_usedpatchpagemem				size_usedcompositetexturepagemem				+ NUM_PATCH_CACHE_PAGES * sizeof(uint8_t)
#define size_compositetextureoffset			size_usedpatchpagemem				+ MAX_TEXTURES * sizeof(uint8_t)
#define size_compositetexturepage			size_compositetextureoffset			+ MAX_TEXTURES * sizeof(uint8_t)
#define size_patchpage						size_compositetexturepage					+ MAX_PATCHES * sizeof(uint8_t)
#define size_patchoffset					size_patchpage						+ MAX_PATCHES * sizeof(uint8_t)
#define size_texturepatchlump_offset		size_patchoffset					+ MAX_TEXTURES * sizeof(uint16_t)
#define size_texturecolumn_offset			size_texturepatchlump_offset		+ MAX_TEXTURES * sizeof(uint16_t)
#define size_texturecompositesizes			size_texturecolumn_offset			+ MAX_TEXTURES * sizeof(uint16_t)
#define size_vissprites						size_texturecompositesizes				+ sizeof(vissprite_t) * (MAXVISSPRITES)
#define size_usedspritepagemem				size_vissprites			+ NUM_SPRITE_CACHE_PAGES * sizeof(uint8_t)
#define size_spritepage						size_usedspritepagemem	+ MAX_SPRITE_LUMPS * sizeof(uint8_t)
#define size_spriteoffset					size_spritepage			+ MAX_SPRITE_LUMPS * sizeof(uint8_t)
#define size_floorclip						size_spriteoffset		+ (sizeof(int16_t) * SCREENWIDTH)
#define size_ceilingclip					size_floorclip			+ (sizeof(int16_t) * SCREENWIDTH)
#define size_segs_render					size_ceilingclip		+ ( MAX_SEGS_RENDER_SIZE)
#define size_screenheightarray				size_segs_render		+ sizeof(int16_t) * (SCREENWIDTH)
#define size_negonearray					size_screenheightarray	+ sizeof(int16_t) * (SCREENWIDTH)
#define size_spritecache_nodes				size_negonearray		+ sizeof(cache_node_t) * (NUM_SPRITE_CACHE_PAGES)
#define size_flatcache_nodes				size_spritecache_nodes	+ sizeof(cache_node_t) * (NUM_FLAT_CACHE_PAGES)
#define size_patchcache_nodes				size_flatcache_nodes	+ sizeof(cache_node_t) * (NUM_PATCH_CACHE_PAGES)
#define size_texturecache_nodes				size_patchcache_nodes	+ sizeof(cache_node_t) * (NUM_TEXTURE_PAGES)



//fd4a





#define colormapbytes				((byte __far*)					(0x80000000 + size_leftover_openings))
#define scalelightfixed				((lighttable_t __far*__far*	)	(0x80000000 + size_colormapbytes))
#define scalelight					((lighttable_t __far*__far*	)	(0x80000000 + size_scalelightfixed))
#define usedcompositetexturepagemem ((uint8_t __far*)				(0x80000000 + size_scalelight))
#define usedpatchpagemem			((uint8_t __far*)				(0x80000000 + size_usedcompositetexturepagemem))
#define compositetextureoffset		((uint8_t __far*)				(0x80000000 + size_usedpatchpagemem))
#define compositetexturepage		((uint8_t __far*)				(0x80000000 + size_compositetextureoffset))
#define patchpage					((uint8_t __far*)				(0x80000000 + size_compositetexturepage))
#define patchoffset					((uint8_t __far*)				(0x80000000 + size_patchpage))
#define texturepatchlump_offset		((uint16_t __far*)				(0x80000000 + size_patchoffset))
#define texturecolumn_offset		((uint16_t __far*)				(0x80000000 + size_texturepatchlump_offset))
#define texturecompositesizes		((uint16_t __far*)				(0x80000000 + size_texturecolumn_offset))
#define vissprites					((vissprite_t __far*)			(0x80000000 + size_texturecompositesizes))
#define usedspritepagemem			((uint8_t __far*)				(0x80000000 + size_vissprites))
#define spritepage					((uint8_t __far*)				(0x80000000 + size_usedspritepagemem))
#define spriteoffset				((uint8_t __far*)				(0x80000000 + size_spritepage))
#define floorclip					((int16_t __far*)				(0x80000000 + size_spriteoffset))
#define ceilingclip					((int16_t __far*)				(0x80000000 + size_floorclip))
#define segs_render					((seg_render_t	__far*		)	(0x80000000 + size_ceilingclip))
#define screenheightarray			((int16_t __far*)				(0x80000000 + size_segs_render))
#define negonearray					((int16_t __far*)				(0x80000000 + size_screenheightarray))
#define spritecache_nodes			((cache_node_t __far*)			(0x80000000 + size_negonearray))
#define flatcache_nodes				((cache_node_t __far*)			(0x80000000 + size_spritecache_nodes))
#define patchcache_nodes			((cache_node_t __far*)			(0x80000000 + size_flatcache_nodes))
#define texturecache_nodes			((cache_node_t __far*)			(0x80000000 + size_patchcache_nodes))




// RENDER 0x7800 - 0x7FFF DATA NOT USED IN PLANES

//				bsp		plane		sprite
// 7800-7FFF	DATA	flatcache	DATA
// 7000-77FF	DATA	flatcache	sprcache
// 6800-6FFF	DATA	DATA		sprcache

// openings are A000 in size. 0x7800 can be just that.

#define size_openings			sizeof(int16_t) * MAXOPENINGS
#define openings				((int16_t __far*			) (0x78000000))


// RENDER 0x7000-0x77FF DATA - USED ONLY IN BSP ... 13k + 8k ... 10592 free
#define size_nodes_render			0						+ MAX_NODES_RENDER_SIZE
#define size_viewangletox			size_nodes_render		+ (sizeof(int16_t) * (FINEANGLES / 2))
#define size_spritewidths			size_viewangletox		+ (sizeof(int16_t) * MAX_SPRITE_LUMPS)
#define size_spriteoffsets			size_spritewidths		+ (sizeof(int16_t) * MAX_SPRITE_LUMPS)
#define size_spritetopoffsets		size_spriteoffsets		+ (sizeof(int16_t) * MAX_SPRITE_LUMPS)
//30462

#define nodes_render				((node_render_t __far*)			(0x70000000 + 0))
#define viewangletox				((int16_t __far*)				(0x70000000 + size_nodes_render))
#define spritewidths				((int16_t __far*)				(0x70000000 + size_viewangletox))
#define spriteoffsets				((int16_t __far*)				(0x70000000 + size_spritewidths))
#define spritetopoffsets			((int16_t __far*)				(0x70000000 + size_spriteoffsets))



// RENDER 0x6800-0x6FFF DATA - USED ONLY IN PLANE... PAGED OUT IN SPRITE REGION  8k... 24k free
// carried over from below - mostly visplanes


// RENDER 0x5000-0x67FF DATA			LEFTOVER: 52

// size_texturecolumnofs_bytes is technically 80480. Takes up whole 0x5000 region, 14944 left over in 0x6000...
#define size_texturecolumnofs_bytes		14944u
#define size_texturecolumnlumps_bytes	(size_texturecolumnofs_bytes + (1264u * sizeof(int16_t)))
#define size_texturedefs_bytes			(size_texturecolumnlumps_bytes + 8756u)
// size_texturedefs_bytes 0x6184... 0x6674

#define texturecolumnofs_bytes_1	((byte __far*)					(0x50000000 ))
#define texturecolumnofs_bytes_2	((byte __far*)					(0x58000000 ))
#define texturecolumnlumps_bytes	((int16_t __far*)				(0x60000000 + size_texturecolumnofs_bytes))
#define texturedefs_bytes			((byte __far*)					(0x60000000 + size_texturecolumnlumps_bytes))

#define size_mobjposlist			0						+ (MAX_THINKERS * sizeof(mobj_pos_t))
#define size_xtoviewangle			size_mobjposlist		+ (sizeof(fineangle_t) * (SCREENWIDTH + 1))
#define size_yslope					size_xtoviewangle		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_distscale				size_yslope				+ (sizeof(fixed_t) * SCREENWIDTH)
#define size_cachedheight			size_distscale			+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cacheddistance			size_cachedheight		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedxstep			size_cacheddistance		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedystep			size_cachedxstep		+ (sizeof(fixed_t) * SCREENHEIGHT)
#define size_spanstart				size_cachedystep		+ (sizeof(fixed_t) * SCREENHEIGHT)



// some empty space above...

// begin stuff that is paged out in sprite code
#define mobjposlist					((mobj_pos_t __far*)			(0x68000000))
#define xtoviewangle				((fineangle_t __far*)			(0x68000000 + size_mobjposlist))
#define yslope						((fixed_t __far*)				(0x68000000 + size_xtoviewangle))
#define distscale					((fixed_t __far*)				(0x68000000 + size_yslope))
#define cachedheight				((fixed_t __far*)				(0x68000000 + size_distscale))
#define cacheddistance				((fixed_t __far*)				(0x68000000 + size_cachedheight))
#define cachedxstep					((fixed_t __far*)				(0x68000000 + size_cacheddistance))
#define cachedystep					((fixed_t __far*)				(0x68000000 + size_cachedxstep))
#define spanstart					((int16_t __far*)				(0x68000000 + size_cachedystep))

// 0x56a0




//0xE000
/*
size_vertexes			E000:0000
size_sectors			E000:1968
size_sides				E000:2f28
size_lines				E000:75e5
size_seenlines			E000:9859
size_subsectors			E000:9936
size_nodes				E000:aa4d
size_segs				E000:d345
size_flattranslation	E000:f442
size_texturetranslation	E000:f5ee
size_texturedefs_offset	E000:f946
size_texturewidthmasks	E000:fc93
size_textureheights		E000:fe41
						E000:fff6  9 bytes free
//	
*/

// may swap with EMS/0xD000 ?
#define uppermemoryblock		0xE0000000

#define size_vertexes			(MAX_VERTEXES_SIZE)
#define size_sectors			(size_vertexes				+ MAX_SECTORS_SIZE)
#define size_sides				(size_sectors				+ MAX_SIDES_SIZE)
#define size_lines				(size_sides					+ MAX_LINES_SIZE)
#define size_seenlines			(size_lines					+ MAX_SEENLINES_SIZE)
#define size_subsectors			(size_seenlines				+ MAX_SUBSECTORS_SIZE)
#define size_nodes				(size_subsectors			+ MAX_NODES_SIZE)
#define size_segs				(size_nodes					+ MAX_SEGS_SIZE)
//65117


#define vertexes				((vertex_t __far*)		(uppermemoryblock))
#define sectors					((sector_t __far*)		(uppermemoryblock + size_vertexes))
#define sides					((side_t __far*)		(uppermemoryblock + size_sectors))
#define lines					((line_t __far*)		(uppermemoryblock + size_sides))
#define seenlines				((uint8_t __far*)		(uppermemoryblock + size_lines))
#define subsectors				((subsector_t __far*)	(uppermemoryblock + size_seenlines))
#define nodes					((node_t __far*)		(uppermemoryblock + size_subsectors))
#define segs					((seg_t __far*)			(uppermemoryblock + size_nodes))

#define B000BlockOffset 0x14B0
#define B000Block 0xB0000000

// a lot unused here...
#define size_zlight					0		+ sizeof(lighttable_t __far*) * (LIGHTLEVELS * MAXLIGHTZ)
#define zlight				((lighttable_t __far* __far*)	(B000Block + B000BlockOffset))

#define CC00Block 0xCC000000

// shareware: 6939u
// commercial doom2: 16114u 
#define size_spritedefs		16114u
#define spritedefs_bytes	((byte __far*)					(CC00Block + 0))




// going to leave c800 free for xt-ide, etc bios
// 0xcc00



#define NUMMOBJTYPES 137


#define MAXEVENTS				64
#define MAXINTERCEPTS			128
#define size_thinkerlist		(sizeof(thinker_t) * MAX_THINKERS)
#define size_mobjinfo			size_thinkerlist + sizeof(mobjinfo_t) * NUMMOBJTYPES
#define size_intercepts			size_mobjinfo + sizeof(intercept_t) * MAXINTERCEPTS
#define size_ammnumpatchbytes	size_intercepts + 524
#define size_ammnumpatchoffsets	size_ammnumpatchbytes 		+ (sizeof(uint16_t) * 10)
#define size_linebuffer			(size_ammnumpatchoffsets	+ MAX_LINEBUFFER_SIZE)
#define size_sectors_physics	(size_linebuffer			+ MAX_SECTORS_PHYSICS_SIZE)
#define size_doomednum			(size_sectors_physics 		+ (sizeof(int16_t) * NUMMOBJTYPES))
#define size_linespeciallist  	(size_doomednum 			+ (sizeof(int16_t) * MAXLINEANIMS))

#define thinkerlist			((thinker_t __far*)			0x90000000)
#define mobjinfo			((mobjinfo_t __far *)		(0x90000000 + size_thinkerlist))
#define intercepts			((intercept_t __far*)		(0x90000000 + size_mobjinfo ))
#define ammnumpatchbytes	((byte __far *)				(0x90000000 + size_intercepts ))
#define ammnumpatchoffsets	((uint16_t __far*)			(0x90000000 + size_ammnumpatchbytes ))
#define linebuffer			((int16_t __far*)			(0x90000000 + size_ammnumpatchoffsets))
#define sectors_physics		((sector_physics_t __far* ) (0x90000000 + size_linebuffer))
#define doomednum			((int16_t __far*)			(0x90000000 + size_sectors_physics))
#define linespeciallist     ((int16_t __far*)   		(0x90000000 + size_doomednum))



// 9000: ... 
// 9000:ce37  	doomednum
// 9000:cf49	linespeciallist
// 9000:D011	[empty]

// PHYSICS 0x6000 - 0x7FFF DATA
// note: strings in 0x6000-6400 region


//0x7000
#define size_segs_physics		(MAX_SEGS_PHYSICS_SIZE)
#define size_lines_physics		(size_segs_physics		+ MAX_LINES_PHYSICS_SIZE)
#define size_blockmaplump		(size_lines_physics		+ MAX_BLOCKMAP_LUMPSIZE)

//0x6400
#define size_blocklinks			(0 + MAX_BLOCKLINKS_SIZE)
#define size_nightmarespawns	(size_blocklinks		+ NIGHTMARE_SPAWN_SIZE)
//3f8a, runs up close to 6800 which has mobjposlist, etc


#define segs_physics		((seg_physics_t __far*)		(0x70000000))
#define lines_physics		((line_physics_t __far*)	(0x70000000 + size_segs_physics))
#define blockmaplump		((int16_t __far*)			(0x70000000 + size_lines_physics))
#define blockmaplump_plus4	((int16_t __far*)			(0x70000008 + size_lines_physics))


#define blocklinks			((THINKERREF __far*)		(0x60004000))
#define nightmarespawns		((mapthing_t __far *)		(0x60004000 + size_blocklinks))

//#define size_sectors_physics	(MAX_SECTORS_PHYSICS_SIZE)
//#define sectors_physics		((sector_physics_t __far* ) (0x5000C000))
#define CC00Block 0xCC000000

#define SAVESTRINGSIZE  24

#define size_rejectmatrix		(MAX_REJECT_SIZE)
#define size_savegamestrings	(10 * SAVESTRINGSIZE)
#define size_saveOldString		(SAVESTRINGSIZE)

#define rejectmatrix			((byte __far *)				(0x5000C000))
#define savegamestrings			((int8_t __far *) 			(0x5000C000) + size_rejectmatrix)
#define saveOldString			((int8_t __far *) 			(0x5000C000) + size_savegamestrings)
//int8_t                    savegamestrings[10*SAVESTRINGSIZE];

 








 

/*
segs_physics		7000:0000
lines_physics		7000:286c
blockmaplump		7000:96ac
sectors_physics		6000:4000
linebuffer			6000:5b30
blocklinks			6000:6f0c
nightmarespawns		6000:8dc6
rejectmatrix		6000:ae96
[empty]				6000:E9B8

nodes_render		7000:0000  // this is paged out for two flat cache pages after render_bspnode
sides_render		7000:8000
segs_render			7000:9e51
... remaining		7000:0c47  !!! overflow

nodes_render		7000:0000  // this is paged out for two flat cache pages after render_bspnode
segs_render			7000:8000
					7000:EDF6



 


 
#define RENDER_SCRATCH		7000:e345


#define zlight						6000:0000
#define texturecolumnlumps_bytes	6000:2000
#define texturecolumnofs_bytes		6000:7430
#define texturedefs_bytes			6000:c860
#define spritewidths				6000:d717
#define spriteoffsets				6000:e1e1
#define spritetopoffsets			6000:ecab
									6000:f775
*/

// size_texturecolumnlumps_bytes

// 1264u doom2
// 402 shareware

// size_texturecolumnofs_bytes
// 80480  doom2 
// 21552u shareware

// size_texturedefs_bytes
// 3767u shareware
// 8756u doom2

#define baselowermemoryaddressStartingOffset 0x2600

#define size_finesine			(10240u * sizeof(int32_t))
#define size_finetangent		(size_finesine				+  2048u * sizeof(int32_t))
#define size_states				(size_finetangent			+ sizeof(state_t) * NUMSTATES)
#define size_events				(size_states				+ sizeof(event_t) * MAXEVENTS)
#define size_flattranslation	(size_events				+ MAX_TEXTURES * sizeof(uint8_t))
#define size_texturetranslation	(size_flattranslation		+ MAX_TEXTURES * sizeof(uint16_t))
#define size_textureheights		(size_texturetranslation	+ MAX_TEXTURES * sizeof(uint8_t))



#define size_tantoangle		size_finetangent +  2049u * sizeof(int32_t)

#define baselowermemoryaddress (0x31F00000)


#define finesine			((int32_t __far*)	baselowermemoryaddress)	// 10240
#define finecosine			((int32_t __far*)	(baselowermemoryaddress+0x2000))	// 10240
#define finetangentinner	((int32_t __far*)	(baselowermemoryaddress + size_finesine ))
#define states				((state_t __far*)	(baselowermemoryaddress + size_finetangent))
#define events				((event_t __far*)	(baselowermemoryaddress + size_states ))

#define	flattranslation		((uint8_t __far*)	(baselowermemoryaddress + size_events))
#define	texturetranslation	((uint16_t __far*)	(baselowermemoryaddress + size_flattranslation))
#define textureheights		((uint8_t __far*)	(baselowermemoryaddress + size_texturetranslation))











// Screen 0 is the screen updated by I_Update screen.
// Screen 1 is an extra buffer.

#define screen0 ((byte __far*) 0x80000000)
#define screen1 ((byte __far*) 0x90000000)
#define screen2 ((byte __far*) 0x70000000)
#define screen3 ((byte __far*) 0x60000000)
#define screen4 ((byte __far*) (0x90000000 + (65536u - ST_WIDTH * ST_HEIGHT)))

// screen1 is used during wi_stuff/intermission code, we can stick this anim data there
#define size_screen1    	    (64000u)
#define size_lnodex				(size_screen1 		+ (sizeof(int16_t) * (9*3)))
#define size_lnodey				(size_lnodex 		+ (sizeof(int16_t) * (9*3)))
#define size_epsd0animinfo		(size_lnodey 		+ (16 * 10))
#define size_epsd1animinfo		(size_epsd0animinfo + (16 * 9))
#define size_epsd2animinfo		(size_epsd1animinfo + (16 * 6))

#define screen1 			((byte __far*) 		0x90000000)
#define lnodex				((int16_t __far*)	(0x90000000 + size_screen1))
#define lnodey				((int16_t __far*)	(0x90000000 + size_lnodex))
#define epsd0animinfo		((wianim_t __far*)	(0x90000000 + size_lnodey))
#define epsd1animinfo		((wianim_t __far*)	(0x90000000 + size_epsd0animinfo))
#define epsd2animinfo		((wianim_t __far*)	(0x90000000 + size_epsd1animinfo))



/*
9000:0000	screen1
9000:FA00	lnodex
9000:FA36	lnodey
9000:FB0C	epsd0animinfo
9000:FAA0	epsd1animinfo
9000:FB9C	epsd2animinfo
9000:FBFC	[empty]


*/

 
#define size_screen0        (64000u)
#define size_gammatable     (size_screen0     + 256 * 5)
#define size_menuoffsets    (size_gammatable  + (sizeof(uint16_t) * NUM_MENU_ITEMS))


#define gammatable          ((byte __far*)      (0x80000000 + size_screen0))
#define menuoffsets         ((uint16_t __far*)  (0x80000000 + size_gammatable))


/*
8000:0000	screen0
8000:FA00	gammatable
8000:FF00	lnodex
8000:FF36	lnodey
8000:FF6C	[empty]

*/

#define conventional_far_bytes ((byte __far*) 0xC8000000)

#define           demobuffer ((byte __far*) 0x50000000)

#define stringdata ((byte __far*)0x60000000)
#define stringoffsets ((uint16_t __far*)0x63C40000)

// ST_STUFF
#define ST_GRAPHICS_SEGMENT 0x7000u

// tall % sign
#define tallpercent  61304u
#define tallpercent_patch  ((byte __far *) 0x7000EF78)

//extern byte __far* palettebytes;
#define palettebytes ((byte __far*) 0x90000000)

// main bar left
#define sbar  44024u
#define sbar_patch   ((byte __far *) 0x7000ABF8)

#define  faceback  57152u
#define  faceback_patch  ((byte __far *) 0x7000DF40)

#define armsbg_patch ((byte __far *)0x7000E668u)

#define armsbg	58984u




#define menugraphicspage0		(byte __far* )0x70000000
#define menugraphicspage4		(byte __far* )0x64000000

#define	 wigraphicspage0		(byte __far* )0x70000000
#define  wigraphicslevelname	(byte __far* )0x78000000
#define  wigraphicsfullscreen	(byte __far* )0x7C000000
#define	 wianimspage			(byte __far* )0x60000000


#define NUM_WI_ITEMS 28
#define NUM_WI_ANIM_ITEMS 30

// maximum size for level complete graphic, times two
#define MAX_LEVEL_COMPLETE_GRAPHIC_SIZE 0x1240
#define size_level_finished_graphic		(MAX_LEVEL_COMPLETE_GRAPHIC_SIZE * 2)
#define size_wioffsets 					(size_level_finished_graphic + sizeof(uint16_t) * NUM_WI_ITEMS)
#define size_wianimoffsets 				(size_wioffsets + sizeof(uint16_t) * NUM_WI_ANIM_ITEMS)

#define wioffsets 						((uint16_t __far*) 	0x78000000 + size_level_finished_graphic)
#define wianimoffsets 					((uint16_t __far*) 	0x78000000 + size_wioffsets)


#define size_blocklinks			(0 + MAX_BLOCKLINKS_SIZE)
#define size_nightmarespawns	(size_blocklinks		+ NIGHTMARE_SPAWN_SIZE)
//3f8a, runs up close to 6800 which has mobjposlist, etc

 

#endif
