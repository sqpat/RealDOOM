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
//	The actual span/column drawing functions.
//	Here find the main potential for optimization,
//	 e.g. inline assembly, different algorithms.
//


#include <conio.h>
#include "doomdef.h"

#include "i_system.h"
#include "z_zone.h"
#include "w_wad.h"

#include "r_local.h"

// Needs access to LFB (guess what).
#include "v_video.h"

// State.
#include "doomstat.h"


// ?
#define MAXWIDTH			320
#define MAXHEIGHT			200

// status bar height at bottom of screen
#define SBARHEIGHT		32

#define IGNORE_PLANAR_ASM 1

//
// All drawing to the view buffer is accomplished in this file.
// The other refresh files only know about ccordinates,
//  not the architecture of the frame buffer.
// Conveniently, the frame buffer is a linear one,
//  and we need only the base address,
//  and the total size == width*height*depth/8.,
//


byte*		viewimage; 
int16_t		viewwidth;
int16_t		scaledviewwidth;
int16_t		viewheight;
int16_t		viewwindowx;
int16_t		viewwindowy; 
int16_t		columnofs[MAXWIDTH]; 

// Color tables for different players,
//  translate a limited part to another
//  (color ramps used for  suit colors).
//
 
 
#define SC_INDEX                0x3C4
#define SC_RESET                0
#define SC_CLOCK                1
#define SC_MAPMASK              2
#define SC_CHARMAP              3
#define SC_MEMMODE              4

#define GC_INDEX                0x3CE
#define GC_SETRESET             0
#define GC_ENABLESETRESET 1
#define GC_COLORCOMPARE 2
#define GC_DATAROTATE   3
#define GC_READMAP              4
#define GC_MODE                 5
#define GC_MISCELLANEOUS 6
#define GC_COLORDONTCARE 7
#define GC_BITMASK              8

//
// R_DrawColumn
// Source is the top of the column to scale.
//
lighttable_t*		dc_colormap; 
int16_t			dc_x; 
int16_t			dc_yl; 
int16_t			dc_yh; 
fixed_t			dc_iscale; 
fixed_t			dc_texturemid;

// first pixel in a column (possibly virtual) 
byte*			dc_source;		


#if IGNORE_PLANAR_ASM
//
// A column is a vertical slice/span from a wall texture that,
//  given the DOOM style restrictions on the view orientation,
//  will always have constant z depth.
// Thus a special case loop for very fast rendering can
//  be used. It has also been used with Wolfenstein 3D.
// 

void R_DrawColumn (void) 
{ 
    int16_t			count; 
    byte*		dest; 
    fixed_t_union		frac;
    fixed_t		fracstep;	 

    count = dc_yh - dc_yl; 

    // Zero length, column does not exceed a pixel.
    if (count < 0) 
        return; 


#ifndef	SKIP_DRAW
	outp (SC_INDEX+1,1<<(dc_x&3));
#endif

    dest = destview + dc_yl*80 + (dc_x>>2); 

    // Determine scaling,
    //  which is the only mapping to be done.
    fracstep = dc_iscale; 
    frac.w = dc_texturemid + (dc_yl-centery)*fracstep; 

    // Inner loop that does the actual texture mapping,
    //  e.g. a DDA-lile scaling.
    // This is as fast as it gets.
    do  {
        // Re-map color indices from wall texture column
        //  using a lighting/special effects LUT.

#ifndef	SKIP_DRAW
		*dest = dc_colormap[dc_source[frac.h.intbits & 127]];
#endif
		/*
		I_Error("values... %li %i %i,    %li %li %i %i %i %i %li %li %i", 
			frac.w, frac.h.intbits, frac.h.fracbits,
			dc_iscale, dc_texturemid, dc_yh, dc_yl, dc_x, centery, fracstep, destview, count);
			*/
// -5406720 -83 -32768  0     -5406720 167 167 155 84 0     -1610612736 0
// 51293 0 -14243       63723 -2752519 129 128 162 84 63723 671744      1

/*
		I_Error("values... are they te same?\n %hhu %hhu %hhu %hhu %hhu %hhu %hhu %hhu\n %hhu %hhu %hhu %hhu %hhu %hhu %hhu %hhu",
			dc_colormap[dc_source[0]], dc_colormap[dc_source[1]], dc_colormap[dc_source[2]], dc_colormap[dc_source[3]],
			dc_colormap[dc_source[4]], dc_colormap[dc_source[5]], dc_colormap[dc_source[6]], dc_colormap[dc_source[7]],
		//);

		//I_Error("values... are they te same? %hhu %hhu %hhu %hhu %hhu %hhu %hhu %hhu",
			dc_source[0], dc_source[1], dc_source[2], dc_source[3],
			dc_source[4], dc_source[5], dc_source[6], dc_source[7]
		);
		*/
        dest += SCREENWIDTH/4;
        frac.w += fracstep;
        

    } while (count--); 
} 

 

void R_DrawColumnLow (void) 
{ 

	int16_t                 count;
	byte*               dest;
	fixed_t_union             frac;
	fixed_t             fracstep;

	count = dc_yh - dc_yl;

	// Zero length.
	if (count < 0)
		return;

#ifndef	SKIP_DRAW
	if (dc_x & 1)
		outp(SC_INDEX + 1, 12);
	else
		outp(SC_INDEX + 1, 3);
#endif
	dest = destview + dc_yl * 80 + (dc_x >> 1);

	fracstep = dc_iscale;
	frac.w = dc_texturemid + (dc_yl - centery)*fracstep;

	do
	{
#ifndef	SKIP_DRAW
		*dest = dc_colormap[dc_source[(frac.h.intbits) & 127]];
#endif


		dest += SCREENWIDTH / 4;
		frac.w += fracstep;

	} while (count--);
}

#endif


//
// Spectre/Invisibility.
//
#define FUZZTABLE		50 
#define FUZZOFF	(SCREENWIDTH/4)


int16_t	fuzzoffset[FUZZTABLE] =
{
    FUZZOFF,-FUZZOFF,FUZZOFF,-FUZZOFF,FUZZOFF,FUZZOFF,-FUZZOFF,
    FUZZOFF,FUZZOFF,-FUZZOFF,FUZZOFF,FUZZOFF,FUZZOFF,-FUZZOFF,
    FUZZOFF,FUZZOFF,FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF,
    FUZZOFF,-FUZZOFF,-FUZZOFF,FUZZOFF,FUZZOFF,FUZZOFF,FUZZOFF,-FUZZOFF,
    FUZZOFF,-FUZZOFF,FUZZOFF,FUZZOFF,-FUZZOFF,-FUZZOFF,FUZZOFF,
    FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF,-FUZZOFF,FUZZOFF,FUZZOFF,
    FUZZOFF,FUZZOFF,-FUZZOFF,FUZZOFF,FUZZOFF,-FUZZOFF,FUZZOFF 
}; 

int32_t	fuzzpos = 0; 


//
// Framebuffer postprocessing.
// Creates a fuzzy image by copying pixels
//  from adjacent ones to left and right.
// Used with an all black colormap, this
//  could create the SHADOW effect,
//  i.e. spectres and invisible players.
//
void R_DrawFuzzColumn (void) 
{ 
    int16_t			count; 
    byte*		dest; 
    fixed_t		frac;
    fixed_t		fracstep;	 

    // Adjust borders. Low... 
    if (!dc_yl) 
		dc_yl = 1;

    // .. and high.
    if (dc_yh == viewheight-1) 
		dc_yh = viewheight - 2; 
		 
    count = dc_yh - dc_yl; 

    // Zero length.
    if (count < 0) 
		return; 
 

    if (detailshift) {
		if (dc_x & 1) {
#ifndef	SKIP_DRAW
		outpw (GC_INDEX,GC_READMAP+(2<<8) );
	    outp (SC_INDEX+1,12); 
#endif
	} else {
#ifndef	SKIP_DRAW
		outpw (GC_INDEX,GC_READMAP);
	    outp (SC_INDEX+1,3); 
#endif
		}
		dest = destview + dc_yl*80 + (dc_x>>1); 
    }
    else {
#ifndef	SKIP_DRAW
		outpw (GC_INDEX,GC_READMAP+((dc_x&3)<<8) );
		outp (SC_INDEX+1,1<<(dc_x&3)); 
#endif
	dest = destview + dc_yl*80 + (dc_x>>2);
    }

    // Looks familiar.
    fracstep = dc_iscale; 
    frac = dc_texturemid + (dc_yl-centery)*fracstep; 

    // Looks like an attempt at dithering,
    //  using the colormap #6 (of 0-31, a bit
    //  brighter than average).
    do  {
		// Lookup framebuffer, and retrieve
		//  a pixel that is either one column
		//  left or right of the current one.
		// Add index from colormap to index.
#ifndef	SKIP_DRAW
		*dest = colormaps[6*256+dest[fuzzoffset[fuzzpos]]];
#endif

		// Clamp table lookup index.
		if (++fuzzpos == FUZZTABLE) 
			fuzzpos = 0;
	
		dest += SCREENWIDTH/4;

		frac += fracstep; 
    } while (count--); 
} 

//
// R_DrawSpan 
// With DOOM style restrictions on view orientation,
//  the floors and ceilings consist of horizontal slices
//  or spans with constant z depth.
// However, rotation around the world z axis is possible,
//  thus this mapping, while simpler and faster than
//  perspective correct texture mapping, has to traverse
//  the texture at an angle in all but a few cases.
// In consequence, flats are not stored by column (like walls),
//  and the inner loop has to step in texture space u and v.
//
int16_t                     ds_y;
int16_t                     ds_x1;
int16_t                     ds_x2;

lighttable_t*           ds_colormap;

fixed_t                 ds_xfrac;
fixed_t                 ds_yfrac;
fixed_t                 ds_xstep;
fixed_t                 ds_ystep;

// start of a 64*64 tile image 
MEMREF                   ds_sourceRef;
byte*                   ds_source;



//
// Draws the actual span.
void R_DrawSpan(void)
{
	fixed_t             xfrac;
	fixed_t             yfrac;
	byte*               dest;
	uint16_t                 spot;
	int16_t                     i;
	int16_t                     prt;
	int16_t                     dsp_x1;
	int16_t                     dsp_x2;
	int16_t                     countp;

 

	for (i = 0; i < 4; i++)
	{
#ifndef	SKIP_DRAW
		outp(SC_INDEX + 1, 1 << i);
#endif
		dsp_x1 = (ds_x1 - i) / 4;
		if (dsp_x1 * 4 + i < ds_x1)
			dsp_x1++;
		dest = destview + ds_y * 80 + dsp_x1;
		dsp_x2 = (ds_x2 - i) / 4;
		countp = dsp_x2 - dsp_x1;

		xfrac = ds_xfrac;
		yfrac = ds_yfrac;

		prt = dsp_x1 * 4 - ds_x1 + i;

		xfrac += ds_xstep * prt;
		yfrac += ds_ystep * prt;
		if (countp < 0) {
			continue;
		}

		do
		{
			// Current texture index in u,v.
			spot = ((yfrac >> (16 - 6))&(63 * 64)) + ((xfrac >> 16) & 63);

			// Lookup pixel from flat texture tile,
			//  re-index using light/colormap.

			Z_RefIsActive(ds_sourceRef);
#ifndef	SKIP_DRAW
			*dest = ds_colormap[ds_source[spot]];
			dest++;
#endif
			// Next step in u,v.
			xfrac += ds_xstep * 4;
			yfrac += ds_ystep * 4;
		} while (countp--);
	}
}



//
// Again..
//
void R_DrawSpanLow(void)
{
	fixed_t             xfrac;
	fixed_t             yfrac;
	byte*               dest;
	uint16_t                 spot;
	int16_t                     i;
	int16_t                     prt;
	int16_t                     dsp_x1;
	int16_t                     dsp_x2;
	int16_t                     countp;

 

	for (i = 0; i < 2; i++)
	{
#ifndef	SKIP_DRAW
		outp(SC_INDEX + 1, 3 << (i * 2));
#endif
		dsp_x1 = (ds_x1 - i) / 2;
		if (dsp_x1 * 2 + i < ds_x1)
			dsp_x1++;
		dest = destview + ds_y * 80 + dsp_x1;
		dsp_x2 = (ds_x2 - i) / 2;
		countp = dsp_x2 - dsp_x1;

		xfrac = ds_xfrac;
		yfrac = ds_yfrac;

		prt = dsp_x1 * 2 - ds_x1 + i;

		xfrac += ds_xstep * prt;
		yfrac += ds_ystep * prt;
		if (countp < 0) {
			continue;
		}
		do
		{
			// Current texture index in u,v.
			spot = ((yfrac >> (16 - 6))&(63 * 64)) + ((xfrac >> 16) & 63);

			// Lookup pixel from flat texture tile,
			Z_RefIsActive(ds_sourceRef);
			//  re-index using light/colormap.
#ifndef	SKIP_DRAW
			*dest = ds_colormap[ds_source[spot]];
			dest++;
#endif
			// Next step in u,v.
			xfrac += ds_xstep * 2;
			yfrac += ds_ystep * 2;
		} while (countp--);
	}
}

//
// R_InitBuffer 
// Creats lookup tables that avoid
//  multiplies and other hazzles
//  for getting the framebuffer address
//  of a pixel to draw.
//
void
R_InitBuffer
( int16_t		width,
  int16_t		height ) 
{ 
    int16_t		i; 

    // Handle resize,
    //  e.g. smaller view windows
    //  with border and/or status bar.
    viewwindowx = (SCREENWIDTH-width) >> 1; 

    // Column offset. For windows.
    for (i=0 ; i<width ; i++) 
	columnofs[i] = viewwindowx + i;

    // Samw with base row offset.
    if (width == SCREENWIDTH) 
	viewwindowy = 0; 
    else 
	viewwindowy = (SCREENHEIGHT-SBARHEIGHT-height) >> 1; 

} 
 
 


//
// R_FillBackScreen
// Fills the back screen with a pattern
//  for variable screen sizes
// Also draws a beveled edge.
//
void R_FillBackScreen (void) 
{ 
    byte*	src;
    byte*	dest; 
    int16_t		x;
    int16_t		y; 
    patch_t*	patch;
	int16_t i;
	MEMREF srcRef;

    // DOOM border patch.
	int8_t	name1[] = "FLOOR7_2";

    // DOOM II border patch.
	int8_t	name2[] = "GRNROCK";

    int8_t*	name;
	
    if (scaledviewwidth == 320)
	return;
	
    if (commercial)
	name = name2;
    else
	name = name1;
    
    srcRef = W_CacheLumpNameEMS (name, PU_CACHE); 
	src = Z_LoadBytesFromEMS(srcRef);
	dest = screen0; 
	 
    for (y=0 ; y<SCREENHEIGHT-SBARHEIGHT ; y++) 
    { 
	for (x=0 ; x<SCREENWIDTH/64 ; x++) 
	{ 
	    memcpy (dest, src+((y&63)<<6), 64); 
	    dest += 64; 
	} 
	/*
	if (SCREENWIDTH&63) 
	{ 
	    memcpy (dest, src+((y&63)<<6), SCREENWIDTH&63); 
	    dest += (SCREENWIDTH&63); 
	} 
	*/

    } 
	
    patch = W_CacheLumpNameEMSAsPatch ("brdr_t",PU_CACHE);

	for (x = 0; x < scaledviewwidth; x += 8) {
		V_DrawPatch(viewwindowx + x, viewwindowy - 8, 0, patch);
	}
	patch = W_CacheLumpNameEMSAsPatch("brdr_b",PU_CACHE);

	for (x = 0; x < scaledviewwidth; x += 8) {
		V_DrawPatch(viewwindowx + x, viewwindowy + viewheight, 0, patch);
	}
	patch = W_CacheLumpNameEMSAsPatch("brdr_l",PU_CACHE);
	for (y = 0; y < viewheight; y += 8) {
		V_DrawPatch(viewwindowx - 8, viewwindowy + y, 0, patch);
	}
    patch = W_CacheLumpNameEMSAsPatch("brdr_r",PU_CACHE);

	for (y = 0; y < viewheight; y += 8) {
		V_DrawPatch(viewwindowx + scaledviewwidth, viewwindowy + y, 0, patch);
	}


    // Draw beveled edge. 
    V_DrawPatch (viewwindowx-8,
		 viewwindowy-8,
		 0,
		W_CacheLumpNameEMSAsPatch("brdr_tl",PU_CACHE));
    
    V_DrawPatch (viewwindowx+scaledviewwidth,
		 viewwindowy-8,
		 0,
		W_CacheLumpNameEMSAsPatch("brdr_tr",PU_CACHE));
    
    V_DrawPatch (viewwindowx-8,
		 viewwindowy+viewheight,
		 0,
		W_CacheLumpNameEMSAsPatch("brdr_bl",PU_CACHE));
    
    V_DrawPatch (viewwindowx+scaledviewwidth,
		 viewwindowy+viewheight,
		 0,
		W_CacheLumpNameEMSAsPatch("brdr_br",PU_CACHE));

    for (i = 0; i < 4; i++)
    {
#ifndef	SKIP_DRAW
		outp(SC_INDEX, SC_MAPMASK);
        outp(SC_INDEX + 1, 1 << i);
#endif

#ifdef _M_I86
		dest = (byte*)0xac000000;
#else
		dest = (byte*)0xac000;
#endif

        src = screen0 + i;
        do
        {
#ifndef	SKIP_DRAW
			*dest = *src;
			dest++;
#endif
            src += 4;
        } 

#ifdef _M_I86
		while (dest != (byte*)(0xac000000
			+ (SCREENHEIGHT - SBARHEIGHT)*SCREENWIDTH / 4));

#else
		while (dest != (byte*)(0xac000
			+ (SCREENHEIGHT - SBARHEIGHT)*SCREENWIDTH / 4));

#endif

    }
} 
 

//
// Copy a screen buffer.
//
void
R_VideoErase
(uint16_t	ofs,
  int16_t		count ) 
{
    byte* dest;
    byte* source;
	int16_t countp;
#ifndef	SKIP_DRAW
	outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, 15);
    outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);
#endif
    dest = (byte*)(destscreen.w + (ofs >> 2));
#ifdef _M_I86
	source = (byte*)0xac000000 + (ofs >> 2);
#else
	source = (byte*)0xac000 + (ofs >> 2);
#endif

    countp = count / 4;
    while (--countp >= 0)
    {
#ifndef	SKIP_DRAW
		dest[countp] = source[countp];
#endif
    }

#ifndef	SKIP_DRAW
	outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
#endif
} 


//
// R_DrawViewBorder
// Draws the border around the view
//  for different size windows?
//

 
void R_DrawViewBorder (void) 
{ 
    uint16_t		top;
    uint16_t		side;
    uint16_t		ofs;
    uint16_t		i; 
 
    if (scaledviewwidth == SCREENWIDTH) 
		return; 
  
    top = ((SCREENHEIGHT-SBARHEIGHT)-viewheight)/2; 
    side = (SCREENWIDTH-scaledviewwidth)/2; 
 
    // copy top and one line of left side 
    R_VideoErase (0, top*SCREENWIDTH+side); 
 
    // copy one line of right side and bottom 
    ofs = (viewheight+top)*SCREENWIDTH-side; 
    R_VideoErase (ofs, top*SCREENWIDTH+side); 
 
    // copy sides using wraparound 
    ofs = top*SCREENWIDTH + SCREENWIDTH-side; 
    side <<= 1;
    
    for (i=1 ; i<viewheight ; i++)  { 
		R_VideoErase (ofs, side); 
		ofs += SCREENWIDTH; 
    } 

} 
 
 
