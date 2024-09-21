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
	.8086


INCLUDE defs.inc


.DATA

EXTRN	_skipdirectdraws:BYTE
EXTRN   _destscreen:DWORD
EXTRN   _screen_segments:WORD
EXTRN   _jump_mult_table_3:BYTE

.CODE
EXTRN	V_MarkRect_:PROC


PROC V_DrawPatch_ FAR
PUBLIC V_DrawPatch_

; ax is x
; dl is y
; bl is screen
; cx is unused?
; bp + 0c is ptr to patch

 

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
push  dx

mov   cl, bl   ; do push?
; bx = 2*ax for word lookup
sal   bl, 1
xor   bh, bh
mov   es, word ptr ds:[bx + _screen_segments]


cmp   byte ptr [_skipdirectdraws], 0
je    doing_draws
jumptoexit:
jmp   jumpexit
doing_draws:

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch

lds   bx, dword ptr [bp + 0Ch]
sub   dl, byte ptr ds:[bx + 6]
xor   dh, dh

; si = y * screenwidth

mov    si, dx
mov    di, ax
mov    ax, SCREENWIDTH
mul    dx
mov    dx, si
mov    si, ax

add   si, di
sub   si, word ptr ds:[bx + 4]


cmp   cl, 0
jne   dontmarkrect
jmp   domarkrect
dontmarkrect:
donemarkingrect:

; 	desttop = MK_FP(screen_segments[scrn], offset); 



; load patch addr again
mov   word ptr cs:[OFFSET SELFMODIFY_offset_add_di + 2], si
mov   bx, word ptr [bp + 0Ch]

;    w = (patch->width); 
mov   ax, word ptr ds:[bx]

add   bx, 8
mov   word ptr cs:[OFFSET SELFMODIFY_compare_instruction + 1], ax  ; store width
mov   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction + 1], bx  ; store column
test  ax, ax
jle   jumptoexit
; store patch segment (???) remove;

draw_next_column:

dec   word ptr cs:[OFFSET SELFMODIFY_compare_instruction + 1] ; decrement count ahead of time

;		column = (column_t __far *)((byte __far*)patch + (patch->columnofs[col])); 

; ds:si is patch segment
; es:di is screen pixel target

SELFMODIFY_setup_bx_instruction:
mov   bx, 0F030h               ; F030h is target for self modifying code     
; grab patch offset into di
mov   si, word ptr [bp + 0Ch]
; si equals colofs lookup
add   si, word ptr ds:[bx]

;		while (column->topdelta != 0xff )  
; check topdelta for 0xFFh
cmp   byte ptr ds:[si], 0FFh
jne   draw_next_column_patch
jmp   column_done


; here we render the next patch in the column.
draw_next_column_patch:


; grab both column fields at once. si + 0 is topdelta. si + 1 is column length
mov   ax, word ptr ds:[si]

mov   cl, ah
xor   ah, ah      ; al contains topdelta
mov   di, SCREENWIDTH
mul   di
mov   dx, di
mov   di, ax
dec   dx


SELFMODIFY_offset_add_di:
add   di, 0F030h   ; retrieve offset


add   si, 3
; figure out loop counts
mov   bl, cl
and   bx, 0007h
mov   al, byte ptr ss:[_jump_mult_table_3 + bx]
mov   byte ptr cs:[SELFMODIFY_offset_draw_remaining_pixels + 1], al
shr   cx, 1
shr   cx, 1
shr   cx, 1


je    done_drawing_8_pixels


; bx, cx unused...

;  todo full unroll

draw_8_more_pixels:

movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx

loop   draw_8_more_pixels

; todo: variable jmp here

done_drawing_8_pixels:

SELFMODIFY_offset_draw_remaining_pixels:
db 0EBh, 00h		; jump rel8


movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx


; restore stuff we changed above
done_drawing_pixels:
check_for_next_column:

inc si
cmp   byte ptr ds:[si], 0FFh


je    column_done
jmp   draw_next_column_patch
column_done:
add   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction + 1], 4
inc   word ptr cs:[OFFSET SELFMODIFY_offset_add_di + 2]
xor   ax, ax
SELFMODIFY_compare_instruction:
cmp   ax, 0F030h		; compare to width
jge   jumpexit
jmp   draw_next_column
jumpexit:
pop   dx
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
mov  ax, di
push es
call  V_MarkRect_
pop  es
pop  ds
jmp   donemarkingrect

ENDP


PROC V_DrawPatchDirect_ FAR
PUBLIC V_DrawPatchDirect_

; CX:BX is patch
; dx is y
; ax is x

;bp  - 2 is ax  (x)

push  si
push  di
push  bp
mov   bp, sp

mov   es, cx

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
 

; patch is es:bx
sub   ax, word ptr es:[bx + 4]
sub   dx, word ptr es:[bx + 6]
mov   si, ax  ; store x
mov   ax, (SCREENWIDTH / 4)
mul   dx

mov   word ptr cs:[SELFMODIFY_retrievepatchoffset+1], bx
; load destscreen into es:bx to calc desttop
mov   di, bx
les   bx, dword ptr [_destscreen]
mov   ds, cx

   
add   bx, ax
mov   ax, si

;	desttop = (byte __far*)(destscreen.w + y * (SCREENWIDTH / 4) + (x>>2));
;   es:bx is desttop

sar   ax, 1
sar   ax, 1

;    w = (patch->width); 
;    for ( col = 0 ; col<w ; col++) 


;	column = (column_t  __far*)((byte  __far*)patch + (patch->columnofs[col]));

mov   word ptr cs:[SELFMODIFY_col_increment+1], 0

add   ax, bx

mov   word ptr cs:[SELFMODIFY_offset_set_di+1], ax
mov   ax, word ptr ds:[di]  ; get width
mov   word ptr cs:[SELFMODIFY_compare_instruction_direct + 1], ax
test  ax, ax
jle   jumptoexitdirect
mov   word ptr cs:[SELFMODIFY_retrievenextcoloffset + 1], di

draw_next_column_direct:

;		outp (SC_INDEX+1,1<<(x&3));
inc   word ptr cs:[SELFMODIFY_col_increment+1]    ; col++

mov   cx, si ; retrieve x
mov   ax, 1


mov   dx, 03C5h
and   cl, 3
SELFMODIFY_retrievenextcoloffset:
mov   di, 0F030h
shl   ax, cl
SELFMODIFY_retrievepatchoffset:
mov   bx, 0F030h



out   dx, al
mov   dx, si  ; store x in dx
add   bx, word ptr ds:[di + 8]
cmp   byte ptr ds:[bx], 0FFh
je    check_desttop_increment
jump4:
mov   al, byte ptr ds:[bx]
mov   ah, (SCREENWIDTH / 4)
mul   ah
SELFMODIFY_offset_set_di:
mov   di, 0F030h
add   di, ax
mov   cl, byte ptr ds:[bx + 1]
lea   si, [bx + 3]
xor   ch, ch
mov   ax,  (SCREENWIDTH / 4) - 1
draw_next_pixel:

;	    while (count--)  { 
 
;			*dest = *source;
;			source++;
;			dest +=  (SCREENWIDTH / 4);

movsb
add   di, ax

loop   draw_next_pixel
jmp    done_drawing_column


jumptoexitdirect:
jmp   jumpexitdirect

done_drawing_column:
mov   al, byte ptr ds:[bx + 1]
xor   ah, ah
add   bx, ax
add   bx, 4
cmp   byte ptr ds:[bx], 0FFh
jne   jump4
check_desttop_increment:

;	if ( ((++x)&3) == 0 ) 
;	    desttop++;	// go to next byte, not next plane 
;    }


inc   dx
test  dx, 3
jne   dont_increment_desttop
inc   word ptr cs:[SELFMODIFY_offset_set_di+1]
dont_increment_desttop:
SELFMODIFY_col_increment:
mov   ax, 0F030h
add   word ptr cs:[SELFMODIFY_retrievenextcoloffset + 1], 4
SELFMODIFY_compare_instruction_direct:
cmp   ax, 0F030h
jge   jumpexitdirect

mov   si, dx
jmp   draw_next_column_direct
jumpexitdirect:
mov   ax, ss
mov   ds, ax
mov   sp, bp
pop   bp
pop   di
pop   si
retf  

ENDP


END
