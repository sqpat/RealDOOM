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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

EXTRN V_DrawPatch_:PROC
EXTRN V_MarkRect_:PROC
EXTRN locallib_toupper_:PROC
EXTRN _hu_font:WORD
.CODE

SCRATCH_SEGMENT_5000 = 05000h


PROC V_DrawPatchFlipped_ NEAR
PUBLIC V_DrawPatchFlipped_


push  bx
push  cx
push  si
push  di
push  ds
push  bp
mov   bp, sp
sub   sp, 2
mov   bx, SCRATCH_SEGMENT_5000
mov   ds, bx
xor   bx, bx
sub   dx, word ptr ds:[bx + 6]
mov   es, dx   ; store
mov   si, ax
mov   ax, SCREENWIDTH
mul   dx
xchg  si, ax
mov   di, word ptr ds:[bx]
mov   word ptr [bp - 2], 0    ; loop counter?
mov   word ptr cs:[SELFMODIFY_cmp_col_to_patch_width+3], di
sub   ax, word ptr ds:[bx + 4]
mov   cx, word ptr ds:[bx + 2]
mov   dx, es   ; get dx back

push  ds    ; store ds 0x5000
push  ss
pop   ds    ; restore ds for this func call
mov   bx, di
add   si, ax
call  V_MarkRect_

pop   ds    ; restore ds 0x5000
mov   cx, si

test  di, di
jle   exit_drawpatchflipped
dec   di
shl   di, 1
shl   di, 1
mov   dx, di
mov   ax, SCREEN0_SEGMENT
mov   es, ax    ; for movsw
draw_next_column_flipped:
; ds:dx is patch 
mov   bx, dx        
mov   bx, word ptr ds:[bx + 8]   ; get columnofs
mov   al, byte ptr ds:[bx]      ; get column topdelta
cmp   al, 0FFh
je    iterate_to_next_column_flipped
draw_next_post_flipped:
; al has ds:[bx]
mov   ah, SCREENWIDTHOVER2
mul   ah        ; 8 bit mul faster than 16, doesnt kill dx
sal   ax, 1     ; times 2

    ; desttop is cx
    ; dest = es:di.    dest = desttop + column->topdelta*SCREENWIDTH;
mov   di, cx
add   di, ax
mov   al, byte ptr ds:[bx + 1] ; get column length
lea   si, [bx + 3]
loop_copy_pixel:
dec   al
js    done_drawing_post_flipped  ; jump if -1

movsb
add   di, SCREENWIDTH-1
jmp   loop_copy_pixel
done_drawing_post_flipped:
mov   al, byte ptr ds:[bx + 1]  ; grab length again.
xor   ah, ah
; bx is column offset
; column = (column_t __far *)(  ((byte  __far*)column) + column->length + 4 );

add   bx, ax
add   bx, 4
mov   al, byte ptr ds:[bx]      ; get column topdelta
cmp   al, 0FFh
jne   draw_next_post_flipped
iterate_to_next_column_flipped:
inc   word ptr [bp - 2]
sub   dx, 4         ; iterate backwards a column..
inc   cx            ; increment desttop x.
SELFMODIFY_cmp_col_to_patch_width:
cmp   word ptr [bp - 2], 01000h
jnge   draw_next_column_flipped
exit_drawpatchflipped:
LEAVE_MACRO
pop   ds
pop   di
pop   si
pop   cx
pop   bx
ret   




ENDP

PROC F_CastPrint_ NEAR
PUBLIC F_CastPrint_


push  bx
push  cx
push  dx
push  si
push  di
mov   di, ax
mov   bx, ax
xor   cx, cx
test  ax, ax
je    label_1
label_11:
mov   al, byte ptr [bx]
cbw
inc   bx
mov   dx, ax
test  ax, ax
jne   label_2
label_1:
mov   ax, cx
CWD
sub   ax, dx
sar   ax, 1
mov   cx, SCREENWIDTHOVER2
mov   si, di
sub   cx, ax
test  di, di
je    exit_castprint
label_9:
mov   al, byte ptr [si]
cbw
inc   si
mov   dx, ax
test  ax, ax
jne   label_4
exit_castprint:
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_2:
xor   ah, ah

call  locallib_toupper_
mov   dl, al
xor   dh, dh
sub   dx, HU_FONTSTART
test  dx, dx
jl    label_5
cmp   dx, HU_FONTSIZE
jle   label_6
label_5:
add   cx, 4
label_3:
test  bx, bx
jne   label_11
jmp   label_1
label_6:
mov   ax, FONT_WIDTHS_SEGMENT
mov   si, dx
mov   es, ax
mov   al, byte ptr es:[si]
cbw
add   cx, ax
jmp   label_3
label_4:
xor   ah, ah

call  locallib_toupper_

mov   dl, al
xor   dh, dh
sub   dx, HU_FONTSTART
test  dx, dx
jl    label_7
cmp   dx, HU_FONTSIZE
jle   label_8
label_7:
add   cx, 4
label_10:
test  si, si
jne   label_9
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_8:
mov   ax, FONT_WIDTHS_SEGMENT
mov   bx, dx
mov   es, ax
mov   al, byte ptr es:[bx]
push  ST_GRAPHICS_SEGMENT
cbw
add   bx, dx
mov   di, ax
mov   ax, word ptr ds:[bx + _hu_font]
mov   dx, 180   ; y coord for draw patch.
push  ax
xor   bx, bx
mov   ax, cx
call  V_DrawPatch_
add   cx, di
jmp   label_10


ENDP

END