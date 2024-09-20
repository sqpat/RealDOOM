; Copyright (C) 1993-1996 Id Software, Inc.
; Copyright (C) 1993-2008 Raven Software
; Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; DESCRIPTION:
;
	.MODEL  medium
	.286


INCLUDE defs.inc


.DATA

EXTRN	_skipdirectdraws:BYTE
EXTRN   _screen_segments:WORD

.CODE
EXTRN	V_MarkRect_:PROC


PROC V_DrawPatch_ FAR
PUBLIC V_DrawPatch_

; ax is x
; dl is y
; bl is screen
; cx is unused?
; bp + 0c is ptr to patch

; bp - 2 is screen

; bp - 04 stores dest segment
; bp - 06 stores column segment
; bp - 08 stores desttop segment
; bp - 0A stores desttop offset (starts 0)
; bp - 0E stores w  (width)
; bp - 0C column offset
; bp - 10h column segment (is this same as patch segment?)

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
push  ax
mov   byte ptr [bp - 2], bl   ; do push?

	;if (skipdirectdraws) {
	;	return;
	;}

cmp   byte ptr [_skipdirectdraws], 0
je    doing_draws
jumptoexit:
jmp   jumpexit
doing_draws:

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

;bp +0ch = patch dword..

les   bx, dword ptr [bp + 0Ch]
sub   dl, byte ptr es:[bx + 6]
xor   dh, dh

; si = y * screenwidth

imul   si, dx, SCREENWIDTH
mov   ax, word ptr es:[bx + 4]
sub   word ptr [bp - 012h], ax

; offset = si += x



add   si, word ptr [bp - 012h]

;    if (!scrn)
;		V_MarkRect (x, y, (patch->width), (patch->height)); 

cmp   byte ptr [bp - 2], 0
jne   dontmarkrect
jmp   domarkrect
dontmarkrect:
donemarkingrect:

; 	desttop = MK_FP(screen_segments[scrn], offset); 

mov   al, byte ptr [bp - 2]
cbw  

; bx = 2*ax for word lookup

mov   bx, ax
add   bx, ax
mov   word ptr [bp - 0Ah], 0
mov   ax, word ptr [bx + _screen_segments]

; load patch addr again
les   bx, dword ptr [bp + 0Ch]
mov   word ptr [bp - 8], ax

;    w = (patch->width); 
mov   ax, word ptr es:[bx]
mov   cx, si

mov   word ptr [bp - 0Eh], ax  ; store width

;    for ( ; col<w ; x++, col++, desttop++) { 

; 
test  ax, ax
jle   jumptoexit
; store patch segment (???) remove;
mov   word ptr [bp - 0Ch], bx
mov   word ptr [bp - 010h], es
draw_next_column:

;		column = (column_t __far *)((byte __far*)patch + (patch->columnofs[col])); 

; es:bx is patch segment
mov   es, word ptr [bp - 010h]
mov   bx, word ptr [bp - 0Ch]
; grab patch into dx:di 
mov   di, word ptr [bp + 0Ch]
mov   dx, word ptr [bp + 0Eh]
; di equals colofs lookup
add   di, word ptr es:[bx + 8]
mov   es, dx

;		while (column->topdelta != 0xff )  
; check topdelta for 0xFFh
cmp   byte ptr es:[di], 0FFh
jne   continue_column_patches
jmp   column_done


; here we render the next patch in the column.
continue_column_patches:

; es:di is column pointer

;register const byte __far*source = (byte __far*)column + 3;
;register byte __far*dest = desttop + column->topdelta * SCREENWIDTH;
;register int16_t count = column->length;

;ax = count


mov   es, dx                ; patch segment again
mov   al, byte ptr es:[di]
xor   ah, ah
imul   ax, ax, SCREENWIDTH  ; column->topdelta * SCREENWIDTH
mov   bx, word ptr [bp - 8] ; bx = dest segment
mov   word ptr [bp - 4], bx
mov   bx, cx   ; retrieve offset
add   bx, ax
mov   al, byte ptr es:[di + 1]   ; grab column length
xor   ah, ah
mov   word ptr [bp - 6], dx
sub   ax, 4
lea   si, [di + 3]
test  ax, ax
jl    done_drawing_4_pixels

;  todo unroll more?

;				do {
;					register byte s0, s1;
;					s0 = source[0];
;					s1 = source[1];
;					dest[0] = s0;
;					dest[SCREENWIDTH] = s1;
;					dest += SCREENWIDTH * 2;
;					s0 = source[2];
;					s1 = source[3];
;					source += 4;
;					dest[0] = s0;
;					dest[SCREENWIDTH] = s1;
;					dest += SCREENWIDTH * 2;
;				} while ((count -= 4) >= 0);


draw_4_more_pixels:
;s0 = dl
;s1 = dh

mov   es, word ptr [bp - 6]     ; restore column segment
mov   dl, byte ptr es:[si]
mov   dh, byte ptr es:[si + 1]
mov   es, word ptr [bp - 4]     ; dest segment
mov   byte ptr es:[bx], dl
mov   byte ptr es:[bx + SCREENWIDTH], dh
mov   es, word ptr [bp - 6]
add   bx, 2*SCREENWIDTH         ; todo just do this once per loop * 4. or do movsb

;s2 = dl
;s3 = dh

mov   dl, byte ptr es:[si + 2]
add   bx, 2*SCREENWIDTH
mov   dh, byte ptr es:[si + 3]
mov   es, word ptr [bp - 4]
add   si, 4
mov   byte ptr es:[bx - (2*SCREENWIDTH)], dl
sub   ax, 4
mov   byte ptr es:[bx - SCREENWIDTH], dh
test  ax, ax
jge   draw_4_more_pixels
done_drawing_4_pixels:
add   ax, 4
je    done_drawing_pixels
draw_one_more_pixel:
mov   es, word ptr [bp - 6]
add   bx, SCREENWIDTH
mov   dl, byte ptr es:[si]
mov   es, word ptr [bp - 4]
inc   si
mov   byte ptr es:[bx - SCREENWIDTH], dl
dec   ax
jne   draw_one_more_pixel
done_drawing_pixels:
check_for_next_column:
mov   dx, word ptr [bp - 6]
lea   di, [si + 1]
mov   es, dx
cmp   byte ptr es:[di], 0FFh
je    column_done
jmp   continue_column_patches
column_done:
inc   word ptr [bp - 012h]
inc   word ptr [bp - 0Ah]
add   word ptr [bp - 0Ch], 4
mov   ax, word ptr [bp - 0Ah]
inc   cx
cmp   ax, word ptr [bp - 0Eh]
jge   jumpexit
jmp   draw_next_column
jumpexit:
leave 
pop   di
pop   si
pop   cx
retf  4
domarkrect:
mov   ax, word ptr [bp - 012h]
mov   cx, word ptr es:[bx + 2]
mov   bx, word ptr es:[bx]
call  V_MarkRect_
jmp   donemarkingrect

ENDP

END