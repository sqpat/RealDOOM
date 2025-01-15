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
EXTRN S_ChangeMusic_:PROC

EXTRN _hu_font:WORD
EXTRN _finaleflat:DWORD
EXTRN _finaletext:WORD
EXTRN _finalestage:WORD
EXTRN _finalecount:WORD
EXTRN _gamestate:byte
EXTRN _gameaction:byte
EXTRN _viewactive:byte
EXTRN _automapactive:byte
EXTRN _commercial:byte
EXTRN _gamemap:byte
EXTRN _gameepisode:byte


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

; FINALE FLAT STRINGS

flat_slime16:
db 053h, 04Ch, 049h, 04Dh, 045h, 031h, 036h, 000h   ; SLIME16
flat_rrock14:
db 052h, 052h, 04Fh, 043h, 04Bh, 032h, 034h, 000h   ; RROCK14
flat_rrock07:
db 052h, 052h, 04Fh, 043h, 04Bh, 030h, 037h, 000h   ; RROCK07
flat_floor4_8:
db 046h, 04Ch, 04Fh, 04Fh, 052h, 034h, 05Fh, 038h, 000h   ; FLOOR4_8
flat_rrock13:
db 052h, 052h, 04Fh, 043h, 04Bh, 032h, 033h, 000h   ; RROCK13
flat_rrock19:
db 052h, 052h, 04Fh, 043h, 04Bh, 032h, 039h, 000h   ; RROCK19

flat_sflr6_1:
db 053h, 046h, 04Ch, 052h, 036h, 05Fh, 031h, 000h   ; SFLR6_1
flat_mflr8_4:
db 04Dh, 046h, 04Ch, 052h, 038h, 05Fh, 034h, 000h   ; MFLR8_4
flat_mflr8_3:
db 04Dh, 046h, 04Ch, 052h, 038h, 05Fh, 033h, 000h   ; MFLR8_3

; lookups for doom1 case

flat_noncommercial_lookup:
dw flat_floor4_8, flat_sflr6_1, flat_mflr8_4, flat_mflr8_3


PROC F_StartFinale_ NEAR
PUBLIC F_StartFinale_


push  bx
push  cx
push  dx
push  si
mov   bx, word ptr ds:[_finaleflat]
mov   cx, word ptr ds:[_finaletext]
mov   byte ptr ds:[_gameaction], 0
xor   al, al
mov   byte ptr ds:[_gamestate], 2
mov   byte ptr ds:[_viewactive], al
mov   byte ptr ds:[_automapactive], al
cmp   byte ptr ds:[_commercial], 0
je    jump_to_handle_doom1
mov   al, byte ptr ds:[_gamemap]
cmp   al, 15
jae   commercial_above_or_equal_to_15
cmp   al, 11
jne   commercial_below_15_not_11
; commercial case 11
mov   bx, OFFSET flat_rrock14
mov   cx, 242
got_flat_values:
mov   ax, 65 ; set finale_music
got_flat_values_and_music:
; ax is finale music
; cs is finaletext
; bx is text for the flat graphic
mov   dx, 1
mov   word ptr ds:[_finaleflat], bx
mov   word ptr ds:[_finaleflat+2], cs
xor   ah, ah
mov   word ptr ds:[_finaletext], cx
call  S_ChangeMusic_
xor   ax, ax
mov   bx, word ptr ds:[_finaleflat]
mov   word ptr ds:[_finalestage], ax
mov   word ptr ds:[_finalecount], ax
pop   si
pop   dx
pop   cx
pop   bx
retf  
commercial_above_or_equal_to_15:
ja    commercial_above_15
; commercial case 15 
mov   bx, OFFSET flat_rrock13
mov   cx, 245       ; todo put these in defines too?
jmp   got_flat_values
commercial_above_15:
cmp   al, 31
jne   commercial_above_15_not_31
; commercial case 31
mov   bx, OFFSET flat_rrock19
mov   cx, 246
jmp   got_flat_values
commercial_above_15_not_31:
cmp   al, 30
jne   commercial_above_15_not_31_30
; commercial case 30
mov   bx, OFFSET flat_floor4_8
mov   cx, 244
jmp   got_flat_values
commercial_above_15_not_31_30:
cmp   al, 20
jne   got_flat_values
;commercial case 20
mov   bx, OFFSET flat_floor4_8
mov   cx, 243
jmp   got_flat_values
jump_to_handle_doom1:
jmp   handle_doom1
commercial_below_15_not_11:
cmp   al, 6
jne   got_flat_values
; commercial case 6
mov   bx, OFFSET flat_slime16
mov   cx, 241
jmp   got_flat_values
handle_doom1:
mov   cl, byte ptr ds:[_gameepisode]
dec   cl
cmp   cl, 3 
ja    got_string
; 0 to 3
xor   ch, ch
mov   si, cx
sal   si, 1

mov   bx, word ptr cs:[si + flat_noncommercial_lookup]
got_string:
mov   al, byte ptr ds:[_gameepisode]
cbw
mov   cx, ax
mov   ax, 31   ; set finale_music
add   cx, 236
jmp   got_flat_values_and_music



ENDP

END