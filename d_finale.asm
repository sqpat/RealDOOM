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
mov   si, ax
xor   cx, cx
test  ax, ax
je    char_is_string_end
check_next_character_width:
lodsb
cbw
test  ax, ax
jne   char_not_string_end
char_is_string_end:
mov   ax, cx        ; cx is width
sar   ax, 1
mov   cx, SCREENWIDTHOVER2
mov   si, di        ; di is original text ptr. restore si to base
sub   cx, ax        ; 160 - width/2
test  di, di
je    exit_castprint
print_next_char:
lodsb
cbw
test  ax, ax
jne   do_char_upper
exit_castprint:
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
char_not_string_end:
xor   ah, ah

call  locallib_toupper_
sub   al, HU_FONTSTART
jl    bad_glyph
cmp   al, HU_FONTSIZE
jle   lookup_glyph_width
bad_glyph:
add   cx, 4
check_next_character_for_zero:
test  si, si
jne   check_next_character_width
jmp   char_is_string_end
lookup_glyph_width:
mov   bx, FONT_WIDTHS_SEGMENT
mov   es, bx
cbw 
mov   bx, ax
mov   al, byte ptr es:[bx]
add   cx, ax        ; add glyph width
jmp   check_next_character_for_zero
do_char_upper:
xor   ah, ah

call  locallib_toupper_

sub   al, HU_FONTSTART
jl    bad_glyph2
cmp   al, HU_FONTSIZE
jle   lookup_glyph_width2
bad_glyph2:
add   cx, 4
draw_next_glyph:
test  si, si
jne   print_next_char
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
lookup_glyph_width2:
mov   bx, FONT_WIDTHS_SEGMENT
mov   es, bx
cbw
mov   bx, ax
mov   al, byte ptr es:[bx]
mov   di, ST_GRAPHICS_SEGMENT    
push  di        ; v_ drawpatch arg
sal   bx, 1
mov   di, ax
mov   ax, word ptr ds:[bx + _hu_font]
mov   dx, 180   ; y coord for draw patch.
push  ax           ; v_ drawpatch arg
xor   bx, bx
mov   ax, cx
call  V_DrawPatch_
add   cx, di
jmp   draw_next_glyph


ENDP

END