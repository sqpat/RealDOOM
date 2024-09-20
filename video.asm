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

; REMOVED bp - 2 is screen
; REMOVED bp - 4 stores dest segment
; REMOVED bp - 6 stores column segment   
; REMOVED bp - 8 stores desttop segment
; bp - 0A stores desttop offset (starts 0)
; bp - 0E stores w (width)
; bp - 0C column offset
; REMOVED bp - 10h column segment (is this same as patch segment?)
; bp - 12h x

; todo: modify stack amount
; todo: use dx for storing a loop var
; todo: use cx more effectively. ch and cl?
; todo: change input to not be bp based
; possible todo: interrupts, sp
; todo: make 8086

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
push  ax      ; bp - 12h
mov   cl, bl   ; do push?
sal   bl, 1
xor   bh, bh
mov   es, word ptr ds:[bx + _screen_segments]

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

lds   bx, dword ptr [bp + 0Ch]
sub   dl, byte ptr ds:[bx + 6]
xor   dh, dh

; si = y * screenwidth

;mov   ax, SCREENWIDTH
;mul   dx
; dx is 0 or garbage?
;mov   si, ax 
imul   si, dx, SCREENWIDTH


mov   ax, word ptr ds:[bx + 4]
sub   word ptr [bp - 012h], ax

; y is not used beyond this point
; offset = si += x



add   si, word ptr [bp - 012h]


cmp   cl, 0
jne   dontmarkrect
jmp   domarkrect
dontmarkrect:
donemarkingrect:

; 	desttop = MK_FP(screen_segments[scrn], offset); 


; bx = 2*ax for word lookup

mov   word ptr [bp - 0Ah], 0

; load patch addr again
mov   cx, si
mov   bx, word ptr [bp + 0Ch]

;    w = (patch->width); 
mov   ax, word ptr ds:[bx]
;lodsw

mov   word ptr [bp - 0Eh], ax  ; store width

test  ax, ax
jle   jumptoexit
push dx
mov  dx, SCREENWIDTH-1
; store patch segment (???) remove;
mov   word ptr [bp - 0Ch], bx
draw_next_column:

;		column = (column_t __far *)((byte __far*)patch + (patch->columnofs[col])); 

; ds:si is patch segment
mov   bx, word ptr [bp - 0Ch]
; grab patch offset into di
mov   si, word ptr [bp + 0Ch]
; si equals colofs lookup
add   si, word ptr ds:[bx + 8]

;		while (column->topdelta != 0xff )  
; check topdelta for 0xFFh
cmp   byte ptr ds:[si], 0FFh
jne   draw_next_column_patch
jmp   column_done


; here we render the next patch in the column.
draw_next_column_patch:



mov   al, byte ptr ds:[si]
xor   ah, ah
imul   ax, ax, SCREENWIDTH  ; column->topdelta * SCREENWIDTH

mov   bl, byte ptr ds:[si + 1]   ; grab column length
xor   bh, bh


xchg  bx, ax
add   bx, cx   ; retrieve offset

add   si, 3
sub   ax, 4

xchg  bx, di
test  ax, ax
jl    done_drawing_4_pixels

;  todo full unroll

draw_4_more_pixels:

movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx

sub   ax, 4
test  ax, ax
jge   draw_4_more_pixels

; todo: variable jmp here

done_drawing_4_pixels:
add   ax, 4
je    done_drawing_pixels

draw_one_more_pixel:
movsb
add di, dx
dec   ax
jne   draw_one_more_pixel

; restore stuff we changed above
done_drawing_pixels:
check_for_next_column:

inc si
cmp   byte ptr ds:[si], 0FFh

; restore flags for next iteration. does not modify above flag
xchg  di, bx


je    column_done
jmp   draw_next_column_patch
column_done:
inc   word ptr [bp - 012h]
inc   word ptr [bp - 0Ah]
add   word ptr [bp - 0Ch], 4
mov   ax, word ptr [bp - 0Ah]
inc   cx
cmp   ax, word ptr [bp - 0Eh]
jge   jumpexit_restore_dx
jmp   draw_next_column
jumpexit_restore_dx:
pop   dx
jumpexit:
mov   ax, ss
mov   ds, ax
mov   sp, bp
pop   bp
pop   di
pop   si
pop   cx
retf  4
domarkrect:
mov   cx, word ptr ds:[bx + 2]
mov   bx, word ptr ds:[bx]
push ds
mov  ax, ss
mov  ds, ax
mov   ax, word ptr [bp - 012h]
push es
call  V_MarkRect_
pop  es
pop  ds
jmp   donemarkingrect

ENDP

END