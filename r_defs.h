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
//      Refresh/rendering module, shared data struct definitions.
//

#ifndef __R_DEFS__
#define __R_DEFS__


// Screenwidth.
#include "doomdef.h"

// Some more or less basic data types
// we depend on.
//#include "m_fixed.h"

// We rely on the thinker data struct
// to handle sound origins in sectors.
// #include "d_think.h"
// SECTORS do store MObjs anyway.
#include "p_mobj.h"



// Silhouette, needed for clipping Segs (mainly)
// and sprites representing things.
#define SIL_NONE		0
#define SIL_BOTTOM		1
#define SIL_TOP			2
#define SIL_BOTH		3

#define MAXDRAWSEGS		256





//
// INTERNAL MAP TYPES
//  used by play and refresh
//

//
// Your plain vanilla vertex.
// Note: transformed values not buffered locally,
//  like some DOOM-alikes ("wt", "WebView") did.
//
// 4 bytes, great
typedef struct {
    int16_t	x;
    int16_t	y;
    
} vertex_t;


// Forward of LineDefs, for Sectors.
struct line_s;
 
//
// The SECTORS record, at runtime.
// Stores things/mobjs.
//

// 16 bytes
typedef	struct {

    short_height_t	floorheight;
    short_height_t	ceilingheight;
	uint8_t	floorpic;
	uint8_t	ceilingpic;
    



    // if == validcount, already checked
	int16_t		validcount;

    // list of mobjs in sector
    THINKERREF	thinglistRef;

    int16_t		linecount;  // 374 line count for fricken doom 1 e2m2 sector 157

	int16_t linesoffset;	// [linecount] size
    uint8_t	lightlevel; // seems to max at 255

    uint8_t	unused_padding; // pad to 16 bytes per struct; could this be used for something helpful?


} sector_t;


// 16 bytes...
typedef	struct {

	int16_t	blockbox[4];
	// origin for any sounds played by the sector
	// corresponds to fixed_t, not easy to change
	// thinker_t for reversable actions
	THINKERREF	specialdataRef;
	int16_t		linecount;  // is int8 ok? seems more than 2-3 is rare..

	int16_t linesoffset;	// [linecount] size

	uint8_t	special;	// only a few small numbers
	uint8_t	tag;


} sector_physics_t;

typedef struct {
	int16_t soundorgX;
	int16_t soundorgY;
} sector_soundorg_t;


 



//
// The SideDef.
//

// 8 bytes, great
typedef struct {
  
	// todo remove above

    // Texture indices.
    // We do not maintain names here. 

	// idea - store unique texturetrios, and then single (or dual byte) references here to save space. im sure it might save a couple thousand bytes per level.
	uint16_t	toptexture;
	uint16_t	bottomtexture;
	uint16_t	midtexture;

	texsize_t	textureoffset;

} side_t; 


typedef struct side_render_s {
	// add this to the calculated texture column

	// add this to the calculated texture top
	texsize_t	rowoffset;

	// Sector the SideDef is facing.
	int16_t	secnum;
} side_render_t; 


//
// Move clipping aid for LineDefs.
//
#define     ST_HORIZONTAL_HIGH	0x0000
#define     ST_VERTICAL_HIGH	0x4000
#define     ST_POSITIVE_HIGH	0x8000
#define     ST_NEGATIVE_HIGH	0xC000
 
typedef int16_t slopetype_t;


#define		LINE_VERTEX_SLOPETYPE	0xC000
#define		VERTEX_OFFSET_MASK		0x3FFF
#define		SLOPETYPE_SHIFT			14
//#define		LINETAG_MASK		0x3F
//#define		LINETAG_VALIDCOUNT_MASK		0xC0

// 4 bytes, lineflags was moved out
typedef struct line_s {
    // Animation related.
    // theres normally 9 flags here, one is runtime created and not pulled from the wad (?) we put that flag in seenlines bit array

    // Visual appearance: SideDefs.
    //  sidenum[1] will be -1 if one sided
    int16_t	sidenum[2];	  // needed to figure out the other side of a line to get its sector...


    // if == validcount, already checked
	// todo make this work 8 bit



} line_t;





typedef struct  {
	// Vertices, from v1 to v2.
	int16_t	v1Offset;										
	int16_t	v2Offset;	//high two bits are the slopetype	

	// Precalculated v2 - v1 for side checking.
	int16_t	dx;
	int16_t	dy;


	// tricky, collisions do seem to happen with 8 bit. I think 10 or 11 would work. would need to fit those 3 high bits elsewhere.
	int16_t		validcount;

		// Front and back sector.
	int16_t	frontsecnum;
	int16_t	backsecnum; 

	uint8_t	tag;
	uint8_t	special;	// both for texture animation but can be fixed to physics only



} line_physics_t;


#define	LO_FLOOR_DIRTY_BIT 0x01
#define	LO_CEILING_DIRTY_BIT  0x02


// 6 bytes. not in an array, who cares..
typedef struct lineopening_s {
	short_height_t		opentop;
	short_height_t 		openbottom;
	short_height_t		lowfloor;
	//short_height_t		openrange; // not worth storing thousands of bytes of a subtraction result

} lineopening_t;


//
// A SubSector.
// References a Sector.
// Basically, this is a list of LineSegs,
//  indicating the visible walls that define
//  (all or some) sides of a convex BSP leaf.
//

// 4 bytes now, lines mvoed out..
typedef struct subsector_s {
    int16_t	secnum;   
    int16_t	firstline;
    
} subsector_t; // used in sight and bsp


 //
// The LineSeg.
//

// original seg_t replaced with other arrays
typedef struct seg_s {
 
    int16_t	linedefOffset;
	uint8_t side;

    
} seg_t;


// 4, great
typedef struct seg_physics_s {

	// Sector references.
	// Could be retrieved from linedef, too.
	// backsector is NULL for one sided lines
	int16_t	frontsecnum;
	int16_t	backsecnum;
} seg_physics_t;


// 8 bytes
typedef struct seg_render_s {

	uint16_t	v1Offset;
	uint16_t	v2Offset; // high bit contains side, necessary to determine frontsecnum/backsecnum dynamically

	int16_t	offset;


	int16_t	sidedefOffset;
} seg_render_t;

//
// BSP node.
//
// 8 bytes. ok
typedef struct node_s {
    // Partition line.
    int16_t	x;
    int16_t	y;
    int16_t	dx;
    int16_t	dy;

    // Bounding box for each child.

    
} node_t; // used in sight and bsp, but bbox is render only?


// 4 bytes
typedef struct node_children_s {
 
    // If NF_SUBSECTOR its a subsector.
    uint16_t children[2];
    
} node_children_t; // used in sight and bsp, but bbox is render only?


// 16 bytes, nice
typedef struct node_render_s {
	// Bounding box for each child.
	int16_t	bbox[2][4];


} node_render_t; // used in sight and bsp, but bbox is render only?





// posts are runs of non masked source pixels
typedef struct {
    byte		topdelta;	// -1 is the last post in a column
    byte		length; 	// length data bytes follows
} post_t;

// column_t is a list of 0 or more post_t, 0xFF terminated
typedef post_t	column_t;


typedef struct  {
    uint16_t    pixelofsoffset;
    uint16_t    postofsoffset;
    uint16_t    texturesize;
    uint16_t    reserved;

} masked_header_t;







//
// OTHER TYPES
//

// This could be wider for >8 bit display.
// Indeed, true color support is posibble
//  precalculating 24bpp lightmap/colormap LUT.
//  from darkening PLAYPAL to all black.
// Could even us emore than 32 levels.
typedef byte	lighttable_t;	




//
// ?
// padded to 32 bytes each..
typedef struct drawseg_s {
	uint16_t		cursegvalue;

	// start pixel x range
    int16_t			x1;
	// end pixel x range
    int16_t			x2;

    // scale at left (based on player distance)
	fixed_t		scale1;
    // scale at right (based on player distance)
	fixed_t		scale2;
	// scale step per pixel
    fixed_t		scalestep;


    // do not clip sprites above this
    short_height_t		bsilheight;

    // do not clip sprites below this
	short_height_t		tsilheight;
    
    // Pointers to lists for sprite clipping,
    //  all three adjusted so [x1] is first value.
    uint16_t		sprtopclip_offset;
    uint16_t		sprbottomclip_offset;
    
    // offset within openings
    uint16_t		maskedtexturecol_val;

    // 0=none, 1=bottom, 2=top, 3=both
    int8_t			silhouette;
    
    // pad to 32 bytes for faster lookups! todo: can we use this space to cache any values? tsilheight and bsilheight need 2 extra bytes each...
    int8_t          unused_padding_a;
    int8_t          unused_padding_b;
    int8_t          unused_padding_c;

    
} drawseg_t;

// underflows of up to screenwidth are possible (looking thru masked textures)
#define NULL_TEX_COL (65535u - SCREENWIDTH)
 

// Patches.
// A patch holds one or more columns.
// Patches are used for sprites and all masked pictures,
// and we compose textures from the TEXTURE1/2 lists
// of patches.
typedef struct  { 
    int16_t		width;		// bounding box size 
    int16_t		height; 
    int16_t		leftoffset;	// pixels to the left of origin 
    int16_t		topoffset;	// pixels below the origin 
	// not 100% sure what it is but changing to 16 bit is a crash. might be pointers.
    int32_t		columnofs[8];	// only [width] used
    // the [0] is &columnofs[width] 
} patch_t;





 

// A vissprite_t is a thing
//  that will be drawn during a refresh.
// I.e. a sprite object that is partly visible.

// 42 bytes.
typedef struct vissprite_s {
    // Doubly linked list.
    //0x0
    uint16_t	next;
    

    //0x2
	int16_t x1;
	int16_t x2;

    // for line side calculation
    //0x6
    fixed_t_union		gx;
    fixed_t_union		gy;

    // global bottom / top for silhouette clipping
    //0xE
    fixed_t_union		gz;
    fixed_t_union		gzt;

    // horizontal position of x1
    //0x16
    fixed_t		startfrac;    
    fixed_t		scale;
    
    // negative if flipped
    //0x1E
    fixed_t		xiscale;	

    //0x22
    fixed_t		texturemid;
    //0x26
	int16_t     patch;
    uint16_t	colormap; // actualy 8 bit

    // flags removed -were only used for player color translations?
   
    
} vissprite_t;


//	
// Sprites are patches with a special naming convention
//  so they can be recognized by R_InitSprites.
// The base name is NNNNFx or NNNNFxFx, with
//  x indicating the rotation, x = 0, 1-7.
// The sprite and frame specified by a thing_t
//  is range checked at run time.
// A sprite is a patch_t that is assumed to represent
//  a three dimensional object and may have multiple
//  rotations pre drawn.
// Horizontal flipping is used to save space,
//  thus NNNNF2F5 defines a mirrored patch.
// Some sprites will only have one picture used
// for all views: NNNNF0
//

//25 bytes, kinda sucks
typedef struct {
    // If false use 0 for any position.
    // Note: as eight entries are available,
    //  we might as well insert the same name eight times.

    // Lump to use for view angles 0-7.
    int16_t	lump[8];

    // Flip bit (1 = flip) to use for view angles 0-7.
    byte	flip[8];

    boolean	rotate;
    
} spriteframe_t;



//
// A sprite definition:
//  a number of animation frames.
//
typedef struct {
    uint16_t		spriteframesOffset;
    int8_t			numframes;

} spritedef_t;



// 2 bytes
typedef union visplanepiclight_s {
    int16_t pic_and_light;

    struct visplanepiclightbytes {
        uint8_t picnum;
        uint8_t lightlevel;
	} bytes;

} visplanepiclight_t;

// 8 bytes... picnum and lightlevel pulled out to their own fields
typedef struct {
  visplanepiclight_t piclight;
  int16_t height;
  int16_t minx;
  int16_t maxx;
   

} visplaneheader_t;


//
// Now what is a visplane, anyway?
// 
typedef struct {
    
  // leave pads for [minx-1]/[maxx+1]
// we want the top and bottom arrays to be at multiples of two bytes. 
// so add an extra pad byte to start and end. doesnt change planes per
// ems page
  byte		pad0;
  byte		pad1;
  // Here lies the rub for all
  //  dynamic resize/change of resolution.
  byte		top[SCREENWIDTH];
  byte		pad2;
  byte		pad3;
  // See above.
  byte		bottom[SCREENWIDTH];
  byte		pad4;
  byte		pad5;


} visplane_t;



#endif
