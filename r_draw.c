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


#include "doomdef.h"

#include "i_system.h"
#include "z_zone.h"
#include "w_wad.h"

#include "r_local.h"

// Needs access to LFB (guess what).
#include "v_video.h"

// State.
#include "doomstat.h"
#include <conio.h>
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"


// ?
#define MAXWIDTH			320
#define MAXHEIGHT			200

// status bar height at bottom of screen
#define SBARHEIGHT		32

//
// All drawing to the view buffer is accomplished in this file.
// The other refresh files only know about ccordinates,
//  not the architecture of the frame buffer.
// Conveniently, the frame buffer is a linear one,
//  and we need only the base address,
//  and the total size == width*height*depth/8.,
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


//
// A column is a vertical slice/span from a wall texture that,
//  given the DOOM style restrictions on the view orientation,
//  will always have constant z depth.
// Thus a special case loop for very fast rendering can
//  be used. It has also been used with Wolfenstein 3D.
// 

/*
void __far R_DrawSpanPrep(){

	// desired bx offset is 0x0FC0  
	// so subtracted segment would be 0xFC

	#define cs_source_offset  0x0FC0
	#define cs_source_segment_offset  0xFC
	int8_t   i = 0;
	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];
	int8_t   shiftamount = (2-detailshift);
	// dont need to change ds at all.
	
	void (__far* dynamic_callfunc)(void);

	for (i = 0; i < spanfunc_main_loop_count; i ++){

		// precalc these outside in a tighter loop so we dont do it in the core inner loop and juggle variables 
		int16_t dsp_x1 = (ds_x1 - i) >> shiftamount;
		int16_t dsp_x2 = (ds_x2 - i) >> shiftamount;
		int16_t countp;
		
		// this only works in asm todo re-optimize it later
		//if ((ds_x1 & 3) != i)
		//	dsp_x1++;
		if ((dsp_x1 << shiftamount) + i < ds_x1)
			dsp_x1++;
		countp = dsp_x2 - dsp_x1;
		spanfunc_inner_loop_count[i] = countp;
		if (countp < 0) {
			continue;
		}
		
		spanfunc_prt[i] = (dsp_x1 << shiftamount) - ds_x1 + i;
		spanfunc_destview_offset[i] = baseoffset + dsp_x1;

		//I_Error("blah!? %i %i %i %i %i %i %x", ds_x1, ds_x2, dsp_x1, dsp_x2, countp, spanfunc_prt[i], spanfunc_destview_offset[i]);

		// todo calculate the steps here especially if there are savings to be had related to 
		// sharing data across loops?

		// we are definitely duplicating xadder/yadder calulcation
		// prt is probably different per call
	 
	}

	
	if (ds_colormap_index){
		uint16_t ds_colormap_offset = ds_colormap_index << 8;
		uint16_t ds_colormap_shift4 = ds_colormap_index << 4;
	 	
		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset + ds_colormap_shift4;
		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset - ds_colormap_offset;
		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

	} else {
		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset;
		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset;
		// todo we can do the fast version with no add al, bh once we find space for it.
		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

	}

	

// 0 121 
	
	// func location
	dynamic_callfunc();
}
*/

/*

void __far R_DrawColumnPrep(uint16_t lookup_offset_difference){

	uint16_t dc_source_offset = FP_OFF(dc_source);
	uint8_t colofs_paragraph_offset = dc_source_offset & 0x0F;
	uint16_t bx_offset = colofs_paragraph_offset << 8;

	int16_t segment_difference =  bx_offset >> 4;
	int16_t ds_segment_difference = (dc_source_offset >> 4) - segment_difference;
	uint16_t calculated_ds = FP_SEG(dc_source) + ds_segment_difference;
	
	void (__far* dynamic_callfunc)(void);
	uint8_t count = dc_yh-dc_yl;	
	
	dc_source = 	MK_FP(calculated_ds, 	bx_offset);	
	dc_yl_lookup_val = dc_yl_lookup[dc_yl];   // precalculate dc_yl * 80

	// modify the jump instruction based on count
	((uint16_t __far *)MK_FP(colfunc_segment, draw_jump_inst_offset))[0] = colfunc_jump_lookup[count];

	// todo add in the actual colormap?
	// todo this is probably 100h 200h 300h etc. i bet we can do a lookup off the high byte

	if (dc_colormap_index){
		uint16_t dc_colormap_offset = dc_colormap_index << 8;  // hope the compiler is smart and just moves the low byte high
		uint16_t dc_colormap_shift4 = dc_colormap_index << 4;
	 	
		uint16_t cs_base = dc_colormap_segment - segment_difference + dc_colormap_shift4;
		uint16_t callfunc_offset = colormaps_colfunc_off_difference + bx_offset - dc_colormap_offset;
		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

	} else {
		uint16_t cs_base = dc_colormap_segment - segment_difference;
		uint16_t callfunc_offset = colormaps_colfunc_off_difference + bx_offset;
		// todo we can do the fast version with no add al, bh once we find space for it.
		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

	}
	
	// func location
	dynamic_callfunc();
}




void __far R_DrawColumnPrepHigh(){

	uint16_t dc_source_offset = FP_OFF(dc_source);
	uint8_t colofs_paragraph_offset = dc_source_offset & 0x0F;
	uint16_t bx_offset = colofs_paragraph_offset << 8;

	// we know bx, so what is DS such that DS:BX  ==  skytexture_segment:skyofs[texture_x]?
	// we know skyofs max value is 35080 or 0x8908
	int16_t segment_difference =  bx_offset >> 4;
	int16_t ds_segment_difference = (dc_source_offset >> 4) - segment_difference;
	uint16_t calculated_ds = FP_SEG(dc_source) + ds_segment_difference;
	
	void (__far* dynamic_callfunc)(void);
	uint8_t count = dc_yh-dc_yl;	

	dc_source = 	MK_FP(calculated_ds, 	bx_offset);
	dc_yl_lookup_val = dc_yl_lookup_high[dc_yl];   // precalculate dc_yl * 80
	//dc_yl_lookup_val = dc_yl_lookup[dc_yl];   // precalculate dc_yl * 80
	
	// modify the jump instruction based on count
	((uint16_t __far *)MK_FP(colfunc_segment_high, draw_jump_inst_offset))[0] = colfunc_jump_lookup_high[count];
	//((uint16_t __far *)MK_FP(colfunc_segment_high, draw_jump_inst_offset))[0] = colfunc_jump_lookup[count];

	// todo add in the actual colormap?
	// todo this is probably 100h 200h 300h etc. i bet we can do a lookup off the high byte

	if (dc_colormap_index){
		uint16_t dc_colormap_offset = dc_colormap_index << 8;  // hope the compiler is smart and just moves the low byte high
		uint16_t dc_colormap_shift4 = dc_colormap_index << 4;
	 	
		uint16_t cs_base = dc_colormap_segment - segment_difference + dc_colormap_shift4;
		uint16_t callfunc_offset = colormaps_colfunc_off_difference + bx_offset - dc_colormap_offset;
		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

	} else {
		uint16_t cs_base = dc_colormap_segment - segment_difference;
		uint16_t callfunc_offset = colormaps_colfunc_off_difference + bx_offset;
		// todo we can do the fast version with no add al, bh once we find space for it.
		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

	}
	
	// func location
	dynamic_callfunc();
}




*/


	// ASM NOTES
	// call diff function based off size of dc_iscale and significant bits/position. we can probably do 16 bit precision fracstep just fine, if it's sufficiently shifted.
	//   note - just use mid 8 bits. 8 bits int 8 bits frac precision should be sufficient? Then use high byte for lookup..
	// if its sufficienetly shifted then the & 127 may even be able to be dropped.
	// when this func is in EMS memory, use CS for xlat on dc_colormap

	// carry bit?
	// colormap in code segment
	// texture in DS
	// dest as ES


	/*
	within the loop:
	CX = mid 16 bits of fracstep
	DX = mid 16 bits of frac
	
	we know top 8 bits get ignored
	we are accepting that droping bits 9-16 of the fraction will be lost, which may cause some infrequent off-by-one texel coordinates.
		this shouldnt be noticeable?

	

	BX = precalculated offset to colormap and dc_source
	  - sort of.
	   - we now know they will not necessarily be offset the same within paragraph
	   - this means we need a 0-F offset
	   - we XOR bl bh between the xlats.
	   - for example colormaps will always be paragraph offset 0 but dc_source may be 0-F
	     - in this case lets assume 0xD
		 - so BX is 0x0D00
		 - we subtract 0x00D0 from the segments to account for this
		 - xor BL BH back and forth between xlats makes BX 0x0D00, 0x0D0D, etc
		 - i dont think its possible to 
	CS prefix pointing to colormap (easy, use EMS to put it in the right segment)
	DS is 'hacked' pre loop to point to where it needs to for segment + BX to be equal to dc_source[0]
	ES contains DEST (screen 0, 0xA000 or whatever)

	AH is empty but during low , potato quality we copy al back into ah.
	SI is contains 4F, 4E, or 4C (to add the remainder of pixel offset for the screenwidth/4 or 0x50 add

	unroll loop all the way. try and keep it 0x10 bytes is for a fast jump calculation.
	calculate base addr + count shifted 4 store in stack. jump to stack loc, etc.


	



	MOV AL DH
	AND AL 127
	; note DS/cs should be pre-"hacked" to the right amount to use same BX for both segments.
	
	; bus usage here - these instructions take up 4 bytes total
	xlat    ; DS segment prefix pointed at dc_source
	db 2Eh  ; CS segment prefix
	xlat
	stosb   ; MOV ES:[DI] AL, INC DI

	;; now we begin to refill the prefetch queue again...

	ADD DI, 79; SCREENWIDTH/4
	ADD DX CX
	
																	286		stall cycles 
																	cycles  cold  warm
	0:  88 f0                   mov    al,dh						2		2		0
	2:  24 7f                   and    al,0x7f						3		2		0
	4:  d7                      xlat   BYTE PTR ds:[bx]				5		1		1
	5:  2e d7                   xlat   BYTE PTR cs:[bx]				5		0		0
	7:  aa                      stos   BYTE PTR es:[di],al			3		0		0
	8:  66 83 c7 4f             add    di,0x4f						3		4		4
	c:  66 01 ca                add    dx,cx						2		1		1
	total:															23		10		6
																	  INSTRUCTION				 PRE-	BUS
																  EU  REMAINING	BYTES IN  BUS   FETCH? REMAINING
	CYCLE	EXECUTING INSTRUCTION								 BUSY	CYCLES	PREFETCH  BUSY			CYCLES
	1																0		0		0		1		1	2
	2																0		0		0		1		1	1
	3	88 f0                   mov    al,dh						1		2		0+2-2	1		1	2
	4																1		1		0		1		1	1
	5	24 7f                   and    al,0x7f						1		3		0+2-2	1		1	2
	6																1		2		0		1		1	1
	7																1		1		0+2		0		0	0	
	8	d7                      xlat   BYTE PTR ds:[bx]				1		5		2-1		1		0	1	;xlat read cycle
	9																1		4		1		1		0	2
	10																1		3		1		1		0	1
	11																1		2		1+2		1		1	2
	12																1		1		3		0		0	0	;xlat read cycle
	13	2e d7                   xlat   BYTE PTR cs:[bx]				1		5		3-2		1		0	2
	14																1		4		1		1		0	2
	15																1		3		1		1		0	1
	16																1		2		1+2		1		1	2
	17																1		1		3		0		0	0
	18  aa                      stos   BYTE PTR es:[di],al			1		3		3-1		1		1	2
	19																1		2		2		1		1	1
	20																1		1		2+2		0		0	0
	21	66 01 ca                add    di,si						1		2		4-3		1		0	2	; write bus cycle for stos
	22																1		1		1		1		0	1
	23																0		0		1		1		1	2	; prefetch queue stalled
	24																0		0		1		1		1	1
	25  66 01 ca                add    dx,cx						1		2		1+2-3	1		1	2
	26																1		1		0		1		1	1
	FIRST  LOOP
	27	88 f0                   mov    al,dh						1		2		0+2-2	1		1	2
	28																1		1		0		1		1	1
	29	24 7f                   and    al,0x7f						1		3		0+2-2	1		1	2
	30																1		2		0		1		1	1
	31																1		1		0+2		1		0	0
	32	d7                      xlat   BYTE PTR ds:[bx]				1		5		2-1		1		0	1	;xlat read cycle
	33																1		4		1		1		0	2
	34																1		3		1		1		0	1
	35																1		2		1+2		1		1	2
	36																1		1		3		0		0	0	;xlat read cycle
	37	2e d7                   xlat   BYTE PTR cs:[bx]				1		5		3-2		1		0	2
	38																1		4		1		1		0	2
	39																1		3		1		1		0	1
	40																1		2		1+2		1		1	2
	41																1		1		3		0		0	0
	42  aa                      stos   BYTE PTR es:[di],al			1		3		3-1		1		1	2
	43																1		2		2		1		1	1
	44																1		1		2+2		0		0	0
	45	66 01 ca                add    di,si						1		2		4-3		1		0	2	; write bus cycle for stos
	46																1		1		1		1		0	1
	47																0		0		1		1		1	2
	48  66 01 ca                add    dx,cx						1		2		1+2-3	1		1	2
	49																1		1		0		1		1	1
	SECOND LOOP

																	286		stall cycles
																	cycles  cold  warm
	0:  88 f0                   mov    al,dh						2		2		0		
	2:  24 7f                   and    al,0x7f						3		2		0	2
	4:  d7                      xlat   BYTE PTR ds:[bx]				5		1		1	4
	5:  2e d7                   xlat   BYTE PTR cs:[bx]				5		0		0
	7:  aa                      stos   BYTE PTR es:[di],al			3		0		0
	b:  66 01 f7                add    di,si						2		2
	c:  66 01 ca                add    dx,cx						2		1		1
	total:															22		10		6

				
				

	one idea 		xor   bl, bh:  
	   offset segments by bh amount..

																	286		stall cycles
																	cycles  cold  warm
	0:  88 f0                   mov    al,dh						2		2		0		
	2:  24 7f                   and    al,0x7f						3		2		0	2
	4:  d7                      xlat   BYTE PTR ds:[bx]				5		1		1	4
	5:  30 fb 					xor    bl, bh						2       0       0
	7:  2e d7                   xlat   BYTE PTR cs:[bx]				5		0		0
	9:  30 fb 					xor    bl, bh						2       0       0
	b:  aa                      stos   BYTE PTR es:[di],al			3		0		0
	c:  66 01 f7                add    di,si						2		2
	f:  66 01 ca                add    dx,cx						2		1		1
	total:															26		10		6

another idea
  bx is already offset by 0-f
  subtract that from the first xlat lookup (al) ?
  ah contains 0x7f

  texture has 128 entries... 

  8000:1000      6000:1007
  8100:0000      6100:0007

  so if bx is 7

    minus 8 to the segment, offset the offset
real address is
  80F8:0080		 6100:0007    (real address)

but bl offset is 0007 so lets store 0x80-0x07 and put that in bh
  bh contains 0x80 - bl = 0x79 in this case

  bx = 0x7907

 sub al bh?  (28 f8)
    segments must have this subtracted from them (bh << 4)
but we cant really subtract from cs. cs is cs.

BUT we can hack cs into a value BEFORE colfunc, with some limitations.
so for example, pre-add 128-bl into it

 so if colfunc is at 8000:0000 and colormaps is 8100:0000
 we can call 7800:8000 instead and use 7800:9000 colormaps..
    ( or whatever....)

so: pre colfunc we inspect the paragraph offset of colofs (cpo)
  determine 128 - cpo
  make this the offset to our call
  for the cpo 0x07 example...   inv_cpo = 0x79
  so instead of invoking colfunc at 8000:0000
  we invoke it at 7900:7000... knowing colormaps is 7900:8000

  8000:1000   original
  7870:1000   cs/bx offset - subtracted segment by 0x9000 equivalent
  7868:1000   minus 128 offset (will be added back later)

  bx value is 0x7907..
  mov al, dh, and 127 <--- our lookup, max 127.
  add al, bh (0x79)
  al has had 128 added to it, minus the offset of 7
  7868:1000 + 7907 + (0x80-7)
  7868:1000 + 7900 + 0x80 
  7868:8980
  8000:1000 equivalent  


  so segments finally become

  8000:1000    6000:1007
  8100:0000    6100:0007
  80FF:0010    60FF:0017
  806F:0010    606F:0017

  bx = 0x0907 so

   806F:0010  + 0x0907 
 = 806F:0917  - bl from al (0x07)
 = 806F:0910  
 = 0x81000

  



																	286		stall cycles
																	cycles  cold  warm
	0:  88 f0                   mov    al,dh						2		2		0		
	2:  20 e0					and    al,ah						2		2		0	
	4:  28 f8					add    al,bh						2       
	5:  d7                      xlat   BYTE PTR ds:[bx]				5		1		1	
	7:  2e d7                   xlat   BYTE PTR cs:[bx]				5		0		0
	9:  aa                      stos   BYTE PTR es:[di],al			3		0		0
	a:  66 01 f7                add    di,si						2		2
	d:  66 01 ca                add    dx,cx						2		1		1
	total:			



	0:  88 f0                   mov    al,dh						2		2		1
	2:  24 7f                   and    al,0x7f						3		2		0
	4:  d7                      xlat   BYTE PTR ds:[bx]				5		1		1
	5:  2e d7                   xlat   BYTE PTR cs:[bx]				5		0		0
	7:  aa                      stos   BYTE PTR es:[di],al			3		0		0
	8:  66 01 ca                add    dx,cx						2		4		2
	b:  66 83 c7 4f             add    di,0x4f						3		2		2
	b:  66 01 f7                add    di,si						2		

	total:															22		10		6


low quality:
	for draw col low we may do (rather than double stos)
	and then make sure add 0x4e not 0x4f.(?)


	0:  88 f0                   mov    al,dh						2		2		1
	2:  24 7f                   and    al,0x7f						3		2		0
	4:  d7                      xlat   BYTE PTR ds:[bx]				5		1		1
	5:  2e d7                   xlat   BYTE PTR cs:[bx]				5		0		0
	7:  88 c4  					mov AH, AL							2		
	9:  AB       				stosw word ptr es:[di], ax			3		
	a:  66 01 f7                add    di,si						2		2
	d:  66 01 ca                add    dx,cx						2		1

	total:															24		10		6
	
potato:
	and then for potato:
	
	0:  88 f0                   mov    al,dh						2		2		1
	2:  24 7f                   and    al,0x7f						3		2		0
	4:  d7                      xlat   BYTE PTR ds:[bx]				5		1		1
	5:  2e d7                   xlat   BYTE PTR cs:[bx]				5		0		0
	7:  88 c4  					mov AH, AL							2		
	9:  AB       				stosw word ptr es:[di], ax			3
	A:  AB       				stosw word ptr es:[di], ax			3
	B:  66 01 f7                add    di,si						2		2
	E:  66 01 ca                add    dx,cx						2		1

	total:															27		10		6

	*/






/*
void __far R_DrawColumn (void) { 
    int16_t			count; 
    byte __far*		dest;
    fixed_t_union		frac;
    fixed_t_union		fracstep;	 
	//int16_t_union		usefrac;
	//int16_t_union		usestep;
    count = dc_yh - dc_yl; 

    // Zero length, column does not exceed a pixel.
	if (count < 0) {
		return;
	}
 


	outp (SC_INDEX+1,1<<(dc_x&3));

    dest = destview + dc_yl*80 + (dc_x>>2); 

	// dest is always A000 something...

    // Determine scaling,
    //  which is the only mapping to be done.
    fracstep.w = dc_iscale; 
    frac.w = dc_texturemid.w + (dc_yl-centery)*fracstep.w; 
	// get the mid 16 bits of the 32 bit values
	
	
	//confirmed mid 16 bit precision looks right. however, compiled, this actually performs worse than the normal method.
	//usefrac.b.bytehigh = frac.b.intbytelow;
	//usefrac.b.bytelow = frac.b.fracbytehigh;
	//usestep.b.bytehigh = fracstep.b.intbytelow;
	//usestep.b.bytelow = fracstep.b.fracbytehigh;
	





    // Inner loop that does the actual texture mapping,
    //  e.g. a DDA-lile scaling.
    // This is as fast as it gets.
    do  {
        // Re-map color indices from wall texture column
        //  using a lighting/special effects LUT.

		//*dest = dc_colormap[dc_source[usefrac.b.bytehigh & 127]];
        //dest += SCREENWIDTH/4;
        //usefrac.hu += usestep.hu;

		*dest = dc_colormap[dc_source[frac.h.intbits & 127]];
        dest += SCREENWIDTH/4;
        frac.w += fracstep.w;
        

    } while (count--); 
} 

 */
/*
void __far R_DrawColumnLow (void) 
{ 

	int16_t                 count;
	byte __far*               dest;
	fixed_t_union             frac;
	fixed_t             fracstep;
	count = dc_yh - dc_yl;

	// Zero length.
	if (count < 0)
		return;

	if (detailshift){

		if (dc_x & 1)
			outp(SC_INDEX + 1, 12);
		else
			outp(SC_INDEX + 1, 3);
	} else {
		outp(SC_INDEX + 1, 1<<(dc_x&3));
	}
	dest = destview + dc_yl * 80 + (dc_x >> (2-detailshift));

	fracstep = dc_iscale;
	frac.w = dc_texturemid.w + (dc_yl - centery)*fracstep;

	do
	{
		*dest = ((byte __far*)MK_FP(dc_colormap_segment, 0))[dc_source[(frac.h.intbits) & 127]];


		dest += SCREENWIDTH / 4;
		frac.w += fracstep;

	} while (count--);
}
*/
 

//
// Spectre/Invisibility.
//
// the table is 65 in length in memory, with the first 15 continuing after index 50
// so that we can do 16 unrolled loop iters without checking every step.
//#define FUZZOFF	(SCREENWIDTH/4)





//
// Framebuffer postprocessing.
// Creates a fuzzy image by copying pixels
//  from adjacent ones to left and right.
// Used with an all black colormap, this
//  could create the SHADOW effect,
//  i.e. spectres and invisible players.
//

// augmented by 6*256 bytes in paragraphs 
/*
#define colormaps_high_fuzz    ((lighttable_t  __far*) (((int32_t)colormaps_high)   + 0x00600000))



void __far R_DrawFuzzColumn (int16_t count, byte __far * dest) { 




    // Looks like an attempt at dithering,
    //  using the colormap #6 (of 0-31, a bit
    //  brighter than average).

	while (count >= FUZZ_LOOP_LENGTH){

    
		// Lookup framebuffer, and retrieve
		//  a pixel that is either one column
		//  left or right of the current one.
		// Add index from colormap to index.

		// only used during sprite, during which colormaps is high
		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];
		// Clamp table lookup index.
		fuzzpos ++;
	
		dest += SCREENWIDTH/4;

		if (fuzzpos >= FUZZTABLE) 
			fuzzpos -= FUZZTABLE;
	
		count -= FUZZ_LOOP_LENGTH;
    } 

    while (count){
		// Lookup framebuffer, and retrieve
		//  a pixel that is either one column
		//  left or right of the current one.
		// Add index from colormap to index.

		// only used during sprite, during which colormaps is high
		*dest = colormaps_high_fuzz[dest[fuzzoffset[fuzzpos]]];

		// Clamp table lookup index.
		if (++fuzzpos == FUZZTABLE) 
			fuzzpos = 0;
	
		dest += SCREENWIDTH/4;

		count --;

    } 
} 
*/

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


//
// Draws the actual span.

/*
void __far R_DrawSpan(void)
{
	//fixed_t_union             src = 0x80000000;
	fixed_t_union             xfrac;
	fixed_t_union             yfrac;
	fixed_t basex, basey;
	byte __far*               dest;
	uint16_t                 spot;
	int16_t                     i;
	int16_t                     prt;
	int16_t                     dsp_x1;
	int16_t                     dsp_x2;
	int16_t                     countp;
	uint16_t xadder, yadder;
	int16_t_union             xfrac16;
	int16_t_union             yfrac16;
	fixed_t x32step = (ds_xstep << 6);
	fixed_t y32step = (ds_ystep << 6);

	for (i = 0; i < 4; i++)
	{
 
		outp(SC_INDEX + 1, 1 << i);
		dsp_x1 = (ds_x1 - i) / 4;
		if (dsp_x1 * 4 + i < ds_x1)
			dsp_x1++;
		dsp_x2 = (ds_x2 - i) / 4;
		countp = dsp_x2 - dsp_x1;
		if (countp < 0) {
			continue;
		}

		// TODO: ds_y lookup table in CS
		dest = destview + ds_y * 80 + dsp_x1;

		prt = dsp_x1 * 4 - ds_x1 + i;
		xfrac.w = basex = ds_xfrac + ds_xstep * prt;
		yfrac.w = basey = ds_yfrac + ds_ystep * prt;
		xfrac16.hu = xfrac.wu >> 8;
		yfrac16.hu = yfrac.wu >> 10;

		xadder = ds_xstep >> 6; // >> 8, *4... lop off top 8 bits, but multing by 4. bottom 6 bits lopped off.
		yadder = ds_ystep >> 8; // lopping off bottom 16 , but multing by 4.
		while (countp >= 16) {

			/*
			nnnn nnnn nnxx xxxx nnnn nnnn nnnn nnnn
			nnnn nnnn nnyy yyyy nnnn nnnn nnnn nnnn
							    0000 3333 3322 2222
			1111 1111 1111 1111 1111 1111 1111 1111
			*/
/*
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			//spot = ((yfrac.w >> (16 - 6))&(4032)) + ((xfrac.h.intbits) & 63);
			dest[0] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			
			//xfrac.w += (4 * ds_xstep);
			//yfrac.w += (4 * ds_ystep);
			//xfrac16.hu = xfrac.wu >> 8;
			//yfrac16.hu = yfrac.wu >> 8;

			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[1] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[2] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[3] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			

			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[4] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[5] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[6] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[7] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;

			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[8] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[9] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[10] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[11] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;

			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[12] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[13] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[14] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[15] = ds_colormap[ds_source[spot]];
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;

			countp -= 16;
			dest+=16;

			xfrac.w += x32step;
			yfrac.w += y32step;

			xfrac16.hu = xfrac.wu >> 8;
			yfrac16.hu = yfrac.wu >> 10;

		}
		*/
		// i have no idea why final unrolled loop does not work (artifacts). im going to blame compiler. in handwritten asm this is closer to what we will do.
		// without the unrolled final loop, we cant push this to its fastest version (16-32 pixel per loop) because the final loop ends up too slow
		/*

		if (countp == 0)
			continue;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[0] = ds_colormap[ds_source[spot]];
		
		if (countp == 1)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[1] = ds_colormap[ds_source[spot]];
		
		if (countp == 2)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[2] = ds_colormap[ds_source[spot]];
		
		if (countp == 3)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[3] = ds_colormap[ds_source[spot]];

		if (countp == 4)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[4] = ds_colormap[ds_source[spot]];
		
		if (countp == 5)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[5] = ds_colormap[ds_source[spot]];
		
		if (countp == 6)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[6] = ds_colormap[ds_source[spot]];
		
		if (countp == 7)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[7] = ds_colormap[ds_source[spot]];
		
		if (countp == 8)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[8] = ds_colormap[ds_source[spot]];
		
		if (countp == 9)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[9] = ds_colormap[ds_source[spot]];
		
		if (countp == 10)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[10] = ds_colormap[ds_source[spot]];
		
		if (countp == 11)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[11] = ds_colormap[ds_source[spot]];

		if (countp == 12)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[12] = ds_colormap[ds_source[spot]];

		if (countp == 13)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[13] = ds_colormap[ds_source[spot]];

		if (countp == 14)
			continue;
		xfrac16.hu += xadder;
		yfrac16.hu += yadder;
		spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
		dest[14] = ds_colormap[ds_source[spot]];
 	

		*/
	/*
		do
		{
			spot = ((yfrac16.h)&(4032)) + (xfrac16.b.bytehigh & 63);
			dest[0] = ds_colormap[ds_source[spot]];
			dest++;
			xfrac16.hu += xadder;
			yfrac16.hu += yadder;
 
		} while (countp--);
	}
}




88 F0    mov   al, dh
24 3F    and   al, 0x3f
89 CE    mov   si, cx
21 DE    and   si, bx
01 C6    add   si, ax
8A 04    mov   al, byte ptr ds:[si]
2E D7    xlatb byte ptr cs:[bx], al
AA       stosb byte ptr es:[di], al
01 E2    add   dx, sp
01 E9    add   cx, bp

19 bytes per loop
then every 16 loop iters

BC 50 2A    mov sp, 0x2a50
5C          pop sp
5D          pop bp


*/

  
//
// Again..
//
/*
void __far R_DrawSpanLow(void)
{
	fixed_t_union             xfrac;
	fixed_t             yfrac;
	byte __far*               dest;
	uint16_t                 spot;
	int16_t                     i;
	int16_t                     prt;
	int16_t                     dsp_x1;
	int16_t                     dsp_x2;
	int16_t                     countp;

 

	for (i = 0; i < 2; i++)
	{
		outp(SC_INDEX + 1, 3 << (i * 2));
		dsp_x1 = (ds_x1 - i) / 2;
		if (dsp_x1 * 2 + i < ds_x1)
			dsp_x1++;
		dest = destview + ds_y * 80 + dsp_x1;
		dsp_x2 = (ds_x2 - i) / 2;
		countp = dsp_x2 - dsp_x1;

		xfrac.w = ds_xfrac;
		yfrac = ds_yfrac;

		prt = dsp_x1 * 2 - ds_x1 + i;

		xfrac.w += ds_xstep * prt;
		yfrac += ds_ystep * prt;
		if (countp < 0) {
			continue;
		}
		do
		{
			// Current texture index in u,v.
			spot = ((yfrac >> (16 - 6))&(4032)) + ((xfrac.h.intbits) & 63);

			// Lookup pixel from flat texture tile,
			//  re-index using light/colormap.
			*dest = ((byte __far *)MK_FP(ds_colormap_segment, ds_colormap_index << 8))[ds_source[spot]];
			dest++;
			// Next step in u,v.
			xfrac.w += ds_xstep * 2;
			yfrac += ds_ystep * 2;
		} while (countp--);
	}
}
*/

//
// R_FillBackScreen
// Fills the back screen with a pattern
//  for variable screen sizes
// Also draws a beveled edge.
//
void __far R_FillBackScreen (void) 
{ 
 

    byte __far*	src; // could be src[104] if not for name1/name2 flat texture. then we could avoid scratch altogether.
    byte __far*	dest;
    int16_t		x;
    int16_t		y; 
	int16_t i;

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
	Z_QuickMapScratch_5000();

	src = MK_FP(SCRATCH_PAGE_SEGMENT, 0);
	W_CacheLumpNameDirect(name, src);
	dest = screen0; 
	 
    for (y=0 ; y<SCREENHEIGHT-SBARHEIGHT ; y++)  { 
		for (x=0 ; x<SCREENWIDTH/64 ; x++)  { 
			FAR_memcpy (dest, src+((y&63)<<6), 64); 
			dest += 64; 
		} 
		 

    } 
	W_CacheLumpNameDirect("brdr_t", src);

	for (x = 0; x < scaledviewwidth; x += 8) {
		V_DrawPatch(viewwindowx + x, viewwindowy - 8, 0, (patch_t __far*)src);
	}
	W_CacheLumpNameDirect("brdr_b", src);

	for (x = 0; x < scaledviewwidth; x += 8) {
		V_DrawPatch(viewwindowx + x, viewwindowy + viewheight, 0, (patch_t __far*)src);
	}

	W_CacheLumpNameDirect("brdr_l", src);
	for (y = 0; y < viewheight; y += 8) {
		V_DrawPatch(viewwindowx - 8, viewwindowy + y, 0, (patch_t __far*)src);
	}
	W_CacheLumpNameDirect("brdr_r", src);

	for (y = 0; y < viewheight; y += 8) {
		V_DrawPatch(viewwindowx + scaledviewwidth, viewwindowy + y, 0, (patch_t __far*)src);
	}

    // Draw beveled edge. 
	W_CacheLumpNameDirect("brdr_tl", src);
		V_DrawPatch (viewwindowx-8,
		 viewwindowy-8,
		 0,
		(patch_t __far*)src);

	W_CacheLumpNameDirect("brdr_tr", src);
    V_DrawPatch (viewwindowx+scaledviewwidth,
		 viewwindowy-8,
		 0,
		(patch_t __far*)src);

	W_CacheLumpNameDirect("brdr_bl", src);
    V_DrawPatch (viewwindowx-8,
		 viewwindowy+viewheight,
		 0,
		(patch_t __far*)src);
	
	W_CacheLumpNameDirect("brdr_br", src);
	V_DrawPatch (viewwindowx+scaledviewwidth,
		 viewwindowy+viewheight,
		 0,
		(patch_t __far*)src);

    for (i = 0; i < 4; i++)
    {
		outp(SC_INDEX, SC_MAPMASK);
        outp(SC_INDEX + 1, 1 << i);

		dest = (byte __far*)0xac000000;

        src = screen0 + i;
        do
        {
			*dest = *src;
			dest++;
            src += 4;
        } 

		// todo can we just check the lower 16 bits?
		while (dest != (byte __far*)(0xac003480));

    }


} 
 

//
// Copy a screen buffer.
//
void __far R_VideoErase (uint16_t ofs, int16_t count )  {
    byte __far* dest;
    byte __far* source;
	int16_t countp;
	outp(SC_INDEX, SC_MAPMASK);
    outp(SC_INDEX + 1, 15);
    outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);
    dest = (byte __far*)(destscreen.w + (ofs >> 2));
	source = (byte __far*)0xac000000 + (ofs >> 2);

    countp = count / 4;
    while (--countp >= 0) {
		dest[countp] = source[countp];
    }

	outp(GC_INDEX, GC_MODE);
    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
} 


//
// R_DrawViewBorder
// Draws the border around the view
//  for different size windows?
//

 
void __far R_DrawViewBorder (void) 
{ 
    uint16_t		top;
    uint16_t		side;
    uint16_t		ofs;
    uint16_t		i; 
 
    if (scaledviewwidth == SCREENWIDTH) 
		return; 
  
    top = ((SCREENHEIGHT-SBARHEIGHT)-viewheight)>>1; 
    side = (SCREENWIDTH-scaledviewwidth)>>1; 
 
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
 
 
