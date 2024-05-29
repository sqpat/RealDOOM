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
#include "memory.h"


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


byte __far*		viewimage;
int16_t		viewwidth;
int16_t		scaledviewwidth;
int16_t		viewheight;
int16_t		viewwindowx;
int16_t		viewwindowy; 
int16_t		viewwindowoffset;

// Color tables for different players,
//  translate a limited part to another
//  (color ramps used for  suit colors).
//
 

/*
EXISTING R_DRAW


0x188b:1a20:  53                push  bx
0x188b:1a21:  51                push  cx
0x188b:1a22:  52                push  dx
0x188b:1a23:  56                push  si
0x188b:1a24:  57                push  di
0x188b:1a25:  55                push  bp
0x188b:1a26:  89 E5             mov   bp, sp
0x188b:1a28:  83 EC 06          sub   sp, 6						; 6 bytes on stack..
0x188b:1a2b:  A1 64 27          mov   ax, word ptr [0x2764]     ; dc_yh
0x188b:1a2e:  2B 06 66 27       sub   ax, word ptr [0x2766]     ; subtract dc_yl
0x188b:1a32:  89 C7             mov   di, ax					; di is count
0x188b:1a34:  85 C0             test  ax, ax                    ; return if count is 0
0x188b:1a36:  7D 07             jge   0x1a3f
0x188b:1a38:  C9                leave 
0x188b:1a39:  5F                pop   di
0x188b:1a3a:  5E                pop   si
0x188b:1a3b:  5A                pop   dx
0x188b:1a3c:  59                pop   cx
0x188b:1a3d:  5B                pop   bx
0x188b:1a3e:  C3                ret   							
0x188b:1a3f:  8B 0E 62 27       mov   cx, word ptr [0x2762]		; count is not 0 so...    dc_x into cx
0x188b:1a43:  B8 01 00          mov   ax, 1						
0x188b:1a46:  80 E1 03          and   cl, 3						; get dc_x & 03
0x188b:1a49:  BA C5 03          mov   dx, 0x3c5
0x188b:1a4c:  D3 E0             shl   ax, cl					; shift 1 left by the dc_x & 03 
0x188b:1a4e:  EE                out   dx, al					; output that value to port 0x3c5


	dest = destview + dc_yl*80 + (dc_x>>2); 
	fracstep.w = dc_iscale; 
    frac.w = dc_texturemid.w + (dc_yl-centery)*fracstep.w

0x188b:1a4f:  6B 1E 66 27 50    imul  bx, word ptr [0x2766], 0x50		bx = dc_yl * 80
0x188b:1a54:  A1 46 1A          mov   ax, word ptr [0x1a46]				ax = high 16 bits of destview (segment)
0x188b:1a57:  8B 16 44 1A       mov   dx, word ptr [0x1a44]				dx = low 16 bits of destview  (offset)
0x188b:1a5b:  89 46 FE          mov   word ptr [bp - 2], ax				store ax (view segment) in stack - 2
0x188b:1a5e:  A1 54 27          mov   ax, word ptr [0x2754]				ax = dc_iscale high 16 bits
0x188b:1a61:  8B 36 62 27       mov   si, word ptr [0x2762]				si = dc_x
0x188b:1a65:  89 46 FA          mov   word ptr [bp - 6], ax				store ax (dc_iscale high 16 bits) in stack - 6
0x188b:1a68:  A1 56 27          mov   ax, word ptr [0x2756]				ax = dc_iscale low 16 bits
0x188b:1a6b:  C1 FE 02          sar   si, 2								shift dc_x right 2
0x188b:1a6e:  89 46 FC          mov   word ptr [bp - 4], ax				store ax (dc_iscale low 16 bits) in stack - 4
0x188b:1a71:  01 DA             add   dx, bx							add bx (dc_yl * 80) into dx (destview offset)
0x188b:1a73:  8B 4E FC          mov   cx, word ptr [bp - 4]				move stack -4 ((dc_iscale low 16 bits) in stack - 4) into cx
0x188b:1a76:  A1 66 27          mov   ax, word ptr [0x2766]				move dc_yl into ax
0x188b:1a79:  8B 5E FA          mov   bx, word ptr [bp - 6]				put stack - 6 (dc_iscale high 16 bits) into bx
0x188b:1a7c:  2B 06 C8 27       sub   ax, word ptr [0x27c8]				subtract centery from ax (dc_yl)
0x188b:1a80:  01 D6             add   si, dx							add dx (destview offset + dc_yl * 80) into si (dc_x >> 2)
0x188b:1a82:  99                cdq   									32 bit sign copy ax into dx?
0x188b:1a83:  9A A8 28 7C 27    lcall 0x277c:0x28a8						call into clib I4M (integer four byte multiply

;========================================================================
;==     Name:           I4M,U4M                                        ==     ^^^^^^ details
;==     Operation:      integer four byte multiply                     ==
;==     Inputs:         DX;AX   integer M1                             ==	 so we are preparing dx:ax with cdq
;==                     CX;BX   integer M2                             ==    CX:BX has already been prepared. stored in stack as they get destroyed.
;==     Outputs:        DX;AX   product                                ==
;==     Volatile:       CX, BX destroyed                               ==    this is the (dc_yl-centery)*fracstep.w multiply.
;========================================================================    note this far compile time address linker dependency is bad so lets inline it.
)

0x188b:1a88:  8B 0E 50 27       mov   cx, word ptr [0x2750]				move dc_texturemid into cx
0x188b:1a8c:  01 C1             add   cx, ax							add ax (dc_iscale low 16 bits) into cx
0x188b:1a8e:  13 16 52 27       adc   dx, word ptr [0x2752]				add dc_texturemid next 16 bits into dx


 do  {
        // Re-map color indices from wall texture column
        //  using a lighting/special effects LUT.

		*dest = dc_colormap[dc_source[frac.h.intbits & 127]];
        dest += SCREENWIDTH/4;
        frac.w += fracstep.w;
        

    } while (count--); 


0x188b:1a92:  89 D0             mov   ax, dx							move frac.h.intbits into ax.
0x188b:1a94:  30 F4             xor   ah, dh							set ah to 0 (i guess)
0x188b:1a96:  8B 1E 44 27       mov   bx, word ptr [0x2744]				set dc_source offset into bx
0x188b:1a9a:  24 7F             and   al, 0x7f							and ah (frac.h.intbits) by 127
0x188b:1a9c:  8E 06 46 27       mov   es, word ptr [0x2746]				move dc_source segment into es
0x188b:1aa0:  01 C3             add   bx, ax							increment bx by ax
0x188b:1aa2:  26 8A 07          mov   al, byte ptr es:[bx]				store dc_source[frac.h.intbits & 127] into al
0x188b:1aa5:  8B 1E 58 27       mov   bx, word ptr [0x2758]				move colormap offset into bx
0x188b:1aa9:  30 E4             xor   ah, ah							zero out ah
0x188b:1aab:  8E 06 5A 27       mov   es, word ptr [0x275a]				store dc-colormap segment into es
0x188b:1aaf:  01 C3             add   bx, ax							add ax to bx (colormap segment)
0x188b:1ab1:  83 C6 50          add   si, 0x50							add 80 (0x50) to si
0x188b:1ab4:  26 8A 07          mov   al, byte ptr es:[bx]				move dc_colormap[lookup] into al
0x188b:1ab7:  8E 46 FE          mov   es, word ptr [bp - 2]				set destview segment into es
0x188b:1aba:  03 4E FA          add   cx, word ptr [bp - 6]				put dc_iscale high 16 bits into cx
0x188b:1abd:  13 56 FC          adc   dx, word ptr [bp - 4]				add destview 
0x188b:1ac0:  4F                dec   di								decrement count
0x188b:1ac1:  26 88 44 B0       mov   byte ptr es:[si - 0x50], al		store al in destview[etc]
0x188b:1ac5:  83 FF FF          cmp   di, -1
0x188b:1ac8:  75 C8             jne   0x1a92

0x188b:1aca:  C9                leave 
0x188b:1acb:  5F                pop   di
0x188b:1acc:  5E                pop   si
0x188b:1acd:  5A                pop   dx
0x188b:1ace:  59                pop   cx
0x188b:1acf:  5B                pop   bx
0x188b:1ad0:  C3                ret   
0x188b:1ad1:  FC                cld   

*/

 
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
lighttable_t __far*		dc_colormap;
int16_t			dc_x; 
int16_t			dc_yl; 
int16_t			dc_yh; 
fixed_t			dc_iscale; 
fixed_t_union	dc_texturemid;

// first pixel in a column (possibly virtual) 
byte __far*			dc_source;


//
// A column is a vertical slice/span from a wall texture that,
//  given the DOOM style restrictions on the view orientation,
//  will always have constant z depth.
// Thus a special case loop for very fast rendering can
//  be used. It has also been used with Wolfenstein 3D.
// 
extern int setval;
void __near R_DrawColumn (void) { 
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
	
	/*
	confirmed mid 16 bit precision looks right. however, compiled, this actually performs worse than the normal method.
	usefrac.b.bytehigh = frac.b.intbytelow;
	usefrac.b.bytelow = frac.b.fracbytehigh;
	usestep.b.bytehigh = fracstep.b.intbytelow;
	usestep.b.bytelow = fracstep.b.fracbytehigh;
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

cs (8000) cant be changed!

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

 

void __near R_DrawColumnLow (void) 
{ 

	int16_t                 count;
	byte __far*               dest;
	fixed_t_union             frac;
	fixed_t             fracstep;
	count = dc_yh - dc_yl;

	// Zero length.
	if (count < 0)
		return;

	if (dc_x & 1)
		outp(SC_INDEX + 1, 12);
	else
		outp(SC_INDEX + 1, 3);
	dest = destview + dc_yl * 80 + (dc_x >> 1);

	fracstep = dc_iscale;
	frac.w = dc_texturemid.w + (dc_yl - centery)*fracstep;

	do
	{
		*dest = dc_colormap[dc_source[(frac.h.intbits) & 127]];


		dest += SCREENWIDTH / 4;
		frac.w += fracstep;

	} while (count--);
}

 

//
// Spectre/Invisibility.
//
#define FUZZTABLE		50 
//#define FUZZOFF	(SCREENWIDTH/4)



int16_t	fuzzpos = 0; 


//
// Framebuffer postprocessing.
// Creates a fuzzy image by copying pixels
//  from adjacent ones to left and right.
// Used with an all black colormap, this
//  could create the SHADOW effect,
//  i.e. spectres and invisible players.
//
void __near R_DrawFuzzColumn (void) 
{ 
    int16_t			count; 
    byte __far*		dest;
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
		outpw (GC_INDEX,GC_READMAP+(2<<8) );
	    outp (SC_INDEX+1,12); 
	} else {
		outpw (GC_INDEX,GC_READMAP);
	    outp (SC_INDEX+1,3); 
		}
		dest = destview + dc_yl*80 + (dc_x>>1); 
    }
    else {
		outpw (GC_INDEX,GC_READMAP+((dc_x&3)<<8) );
		outp (SC_INDEX+1,1<<(dc_x&3)); 
		dest = destview + dc_yl*80 + (dc_x>>2);
    }

    // Looks familiar.
    fracstep = dc_iscale; 
    frac = dc_texturemid.w + (dc_yl-centery)*fracstep; 

    // Looks like an attempt at dithering,
    //  using the colormap #6 (of 0-31, a bit
    //  brighter than average).
    do  {
		// Lookup framebuffer, and retrieve
		//  a pixel that is either one column
		//  left or right of the current one.
		// Add index from colormap to index.

		// only used during sprite, during which colormaps is high
		*dest = colormaps_high[6*256+dest[fuzzoffset[fuzzpos]]];

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

lighttable_t __far*           ds_colormap;
//uint16_t*           ds_colormap;

fixed_t                 ds_xfrac;
fixed_t                 ds_yfrac;
fixed_t                 ds_xstep;
fixed_t                 ds_ystep;

// start of a 64*64 tile image 
 byte __far*                   ds_source;


//
// Draws the actual span.
void __near R_DrawSpan(void)
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
	//fixed_t x32step = ds_xstep << 6;// (32L * ds_xstep);
	//fixed_t y32step = ds_ystep << 6;// (32L * ds_ystep);
	fixed_t x32step = (ds_xstep << 6);
	fixed_t y32step = (ds_ystep << 6);
	//fixed_t x32step = (ds_xstep << 5);
	//fixed_t y32step = (ds_ystep << 5);

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


  
//
// Again..
//
void __near R_DrawSpanLow(void)
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
			*dest = ds_colormap[ds_source[spot]];
			dest++;
			// Next step in u,v.
			xfrac.w += ds_xstep * 2;
			yfrac += ds_ystep * 2;
		} while (countp--);
	}
}


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
void
__far R_VideoErase
(uint16_t	ofs,
  int16_t		count ) 
{
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
 
 
