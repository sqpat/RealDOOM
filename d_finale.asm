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
EXTRN V_DrawFullscreenPatch_:PROC
EXTRN getStringByIndex_:PROC
EXTRN locallib_strlen_:PROC
EXTRN Z_QuickMapStatusNoScreen4_:PROC
EXTRN Z_QuickMapRender7000_:PROC
EXTRN Z_QuickMapScratch_5000_:PROC
EXTRN Z_QuickMapScreen0_:PROC
EXTRN Z_QuickMapPhysics_:PROC
EXTRN W_CacheLumpNumDirect_:PROC
EXTRN W_CacheLumpNameDirect_:PROC
EXTRN W_CacheLumpNumDirectFragment_:PROC
EXTRN W_GetNumForName_:PROC
EXTRN S_StartSound_:PROC
EXTRN S_StartMusic_:PROC
EXTRN combine_strings_:PROC

EXTRN _hu_font:WORD

EXTRN _player:WORD
EXTRN _gamestate:BYTE
EXTRN _gameaction:BYTE
EXTRN _viewactive:BYTE
EXTRN _automapactive:BYTE
EXTRN _commercial:BYTE
EXTRN _gamemap:BYTE
EXTRN _gameepisode:BYTE
EXTRN _filename_argument:BYTE
EXTRN _firstspritelump:WORD
EXTRN _is_ultimate:BYTE
EXTRN _wipegamestate:BYTE

.CODE

; vars and data..

_CSDATA_castattacking:
db    0
_CSDATA__castdeath:
db    0
_CSDATA_castonmelee:
db    0
_CSDATA_castframes:
db    0
_CSDATA_casttics:
db    0
_CSDATA_castnum:
db    0
_CSDATA_castdeath:
db    0
_CSDATA_caststate:
dw    0, STATES_SEGMENT  ; hardcoded segment..
_CSDATA_finaleflat:
dw    0
_CSDATA_finaletext:
dw    0
_CSDATA_finalecount:
dw    0
; Stage of animation:
;  0 = text, 1 = art screen, 2 = character cast
_CSDATA_finalestage:
dw    0
_CSDATA_finale_laststage:
db    0







_CSDATA_castorder:
db    CC_ZOMBIE-castorderoffset,    MT_POSSESSED
db    CC_SHOTGUN-castorderoffset,   MT_SHOTGUY
db    CC_HEAVY-castorderoffset,     MT_CHAINGUY
db    CC_IMP-castorderoffset,       MT_TROOP
db    CC_DEMON-castorderoffset,     MT_SERGEANT
db    CC_LOST-castorderoffset,      MT_SKULL
db    CC_CACO-castorderoffset,      MT_HEAD
db    CC_HELL-castorderoffset,      MT_KNIGHT
db    CC_BARON-castorderoffset,     MT_BRUISER
db    CC_ARACH-castorderoffset,     MT_BABY
db    CC_PAIN-castorderoffset,      MT_PAIN
db    CC_REVEN-castorderoffset,     MT_UNDEAD
db    CC_MANCU-castorderoffset,     MT_FATSO
db    CC_ARCH-castorderoffset,      MT_VILE
db    CC_SPIDER-castorderoffset,    MT_SPIDER
db    CC_CYBER-castorderoffset,     MT_CYBORG
db    CC_HERO-castorderoffset,      MT_PLAYER

MAX_CASTNUM = 017

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
db "SLIME16", 0
flat_rrock14:
db "RROCK14", 0
flat_rrock07:
db "RROCK07", 0
flat_floor4_8:
db "FLOOR4_8", 0
flat_rrock13:
db "RROCK13", 0
flat_rrock19:
db "RROCK19", 0

flat_sflr6_1:
db "SFLR6_1", 0
flat_mflr8_4:
db "MFLR8_4", 0
flat_mflr8_3:
db "MFLR8_3", 0

; lookups for doom1 case

flat_noncommercial_lookup:
dw flat_floor4_8, flat_sflr6_1, flat_mflr8_4, flat_mflr8_3

; BIG TODO: if other build versions are to be implemented then
;  the strings above must be added to and switch cases changed a bit. could make a big fat lookup table with all fields?
;  once this is overlaid it probably wont be a big problem.
PROC F_StartFinale_ NEAR
PUBLIC F_StartFinale_


push  bx
push  cx
push  dx
push  si
mov   bx, word ptr cs:[_CSDATA_finaleflat]
mov   cx, word ptr cs:[_CSDATA_finaletext]
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
mov   cx, C2TEXT
got_flat_values:
mov   ax, 65 ; set finale_music
got_flat_values_and_music:
; ax is finale music
; cs is finaletext
; bx is text for the flat graphic
mov   dx, 1
mov   word ptr cs:[_CSDATA_finaleflat], bx

xor   ah, ah
mov   word ptr cs:[_CSDATA_finaletext], cx
call  S_ChangeMusic_
xor   ax, ax
mov   bx, word ptr cs:[_CSDATA_finaleflat]
mov   word ptr cs:[_CSDATA_finalestage], ax
mov   word ptr cs:[_CSDATA_finalecount], ax
pop   si
pop   dx
pop   cx
pop   bx
retf  
commercial_above_or_equal_to_15:
ja    commercial_above_15
; commercial case 15 
mov   bx, OFFSET flat_rrock13
mov   cx, C5TEXT
jmp   got_flat_values
commercial_above_15:
cmp   al, 31
jne   commercial_above_15_not_31
; commercial case 31
mov   bx, OFFSET flat_rrock19
mov   cx, C6TEXT
jmp   got_flat_values
commercial_above_15_not_31:
cmp   al, 30
jne   commercial_above_15_not_31_30
; commercial case 30
mov   bx, OFFSET flat_floor4_8
mov   cx, C4TEXT
jmp   got_flat_values
commercial_above_15_not_31_30:
cmp   al, 20
jne   got_flat_values
;commercial case 20
mov   bx, OFFSET flat_floor4_8
mov   cx, C3TEXT
jmp   got_flat_values
jump_to_handle_doom1:
jmp   handle_doom1
commercial_below_15_not_11:
cmp   al, 6
jne   got_flat_values
; commercial case 6
mov   bx, OFFSET flat_slime16
mov   cx, C1TEXT
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
add   cx, (E1TEXT-1)
jmp   got_flat_values_and_music

ENDP

str_bossback:
db "BOSSBACK", 0


; copy string from cs:bx to ds:ax

PROC F_CopyString9_ NEAR
PUBLIC F_CopyString9_

push  si
push  di
push  cx
push  ax
mov   di, ax

push  ds
pop   es    ; es = ds

push  cs
pop   ds    ; ds = cs

mov   si, bx

mov   ax, 0
stosw       ; zero out
stosw
stosw
stosw
stosb
mov  cx, 9
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

push  ss
pop   ds    ; restore ds

pop   ax
pop   cx
pop   di
pop   si

ret

ENDP


PROC F_CastDrawer_ NEAR
PUBLIC F_CastDrawer_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 068h
les   bx, dword ptr cs:[_CSDATA_caststate]
mov   al, byte ptr es:[bx]
mov   byte ptr [bp - 4], al
mov   al, byte ptr es:[bx + 1]
xor   dx, dx
mov   byte ptr [bp - 2], al
mov   ax, OFFSET _filename_argument


; copy 9 bytes "BOSSBACK" to ds. gross...
push  bx
mov   bx, OFFSET str_bossback
call  F_CopyString9_
pop   bx

call  V_DrawFullscreenPatch_
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder]
mov   cx, ds
xor   ah, ah
lea   bx, [bp - 068h] ; text param (100 length)
add   ax, CASTORDEROFFSET

call  getStringByIndex_

call  Z_QuickMapStatusNoScreen4_
lea   ax, [bp - 068h]  ; ; text param (100 length)
call  F_CastPrint_
call  Z_QuickMapRender7000_
mov   al, byte ptr [bp - 4]
xor   ah, ah
mov   bx, ax
shl   bx, 1
shl   bx, 1
sub   bx, ax
mov   ax, SPRITES_SEGMENT
mov   es, ax
mov   al, byte ptr [bp - 2]
and   al, FF_FRAMEMASK
mov   ah, 019h           ; todo sizeof spriteframe_t
mul   ah
mov   bx, word ptr es:[bx]
add   bx, ax
mov   cx, word ptr es:[bx]
mov   dl, byte ptr es:[bx + 010h]
call  Z_QuickMapScratch_5000_
mov   ax, word ptr ds:[_firstspritelump]
xor   bx, bx
add   ax, cx
mov   cx, SCRATCH_SEGMENT_5000
call  W_CacheLumpNumDirect_
test  dl, dl
je    not_flipped
mov   dx, 170                ; y param
mov   ax, SCREENWIDTHOVER2
call  V_DrawPatchFlipped_
LEAVE_MACRO
pop   dx
pop   cx
pop   bx
ret   
not_flipped:
mov   ax, SCRATCH_SEGMENT_5000
push  ax
xor   ax, ax
push  ax
mov   dx, 170                ; y param
mov   ax, SCREENWIDTHOVER2
xor   bx, bx
call  V_DrawPatch_
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   


ENDP



PROC F_TextWrite_ NEAR
PUBLIC F_TextWrite_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 029Eh
lea       bx, [bp - 029Eh]
mov       word ptr [bp - 4], bx

call      Z_QuickMapScratch_5000_
call      Z_QuickMapScreen0_

mov       bx, word ptr cs:[_CSDATA_finaleflat]
mov       ax, OFFSET _filename_argument
call      F_CopyString9_
xor       bx, bx

mov       cx, SCRATCH_SEGMENT_5000
xor       di, di                    ; dest offset 0

xor       dx, dx
call      W_CacheLumpNameDirect_


;    for (y=0 ; y<SCREENHEIGHT ; y++) {
;		for (x=0 ; x<SCREENWIDTH/64 ; x++) {
;			FAR_memcpy (MK_FP(screen0_segment, dest), MK_FP(0x5000, ((y&63)<<6)), 64);
;			dest += 64;
;		}
 ;   }

mov       ax, SCRATCH_SEGMENT_5000
mov       ds, ax
mov       ax, SCREEN0_SEGMENT
mov       es, ax
mov       dx, di    ; zeroed
mov       cx, di
mov       bh, 32
mov       bl, 63

loop_draw_fullscreen_next_row:
mov       ax, dx
and       ax, bx    ; 63, technically 32 is set in bh but we shift left 6 and clobber that bit.
IF COMPILE_INSTRUCTIONSET GE COMPILE_186

    shl       ax, 6
ELSE
    shl       ax, 1
    shl       ax, 1
    shl       ax, 1
    shl       ax, 1
    shl       ax, 1
    shl       ax, 1
ENDIF

loop_draw_fullscreen_next_column:

; repeat flat five times
mov       si, ax
mov       cl, bh    ; 32
rep       movsw
mov       si, ax
mov       cl, bh
rep       movsw 
mov       si, ax
mov       cl, bh
rep       movsw 
mov       si, ax
mov       cl, bh
rep       movsw 
mov       si, ax
mov       cl, bh
rep       movsw 



inc       dx
cmp       dx, SCREENHEIGHT
jb        loop_draw_fullscreen_next_row

; restore ds
push      ss
pop       ds


call      Z_QuickMapStatusNoScreen4_
mov       cx, SCREENHEIGHT
mov       bx, SCREENWIDTH
xor       dx, dx
xor       ax, ax


call      V_MarkRect_
lea       bx, [bp - 029Eh]
mov       ax, word ptr cs:[_CSDATA_finaletext]
mov       cx, ds
mov       si, 10

call      getStringByIndex_
mov       ax, word ptr cs:[_CSDATA_finalecount]
sub       ax, si
mov       bx, 3
CWD       
idiv      bx
mov       di, si
mov       cx, ax
jl        exit_ftextwrite
loop_count:
test      cx, cx
je        exit_ftextwrite
mov       bx, word ptr [bp - 4]
mov       al, byte ptr [bx]
cbw      
inc       word ptr [bp - 4]
mov       dx, ax
test      ax, ax
je        exit_ftextwrite
cmp       ax, 10
jne       do_char_upper_ftextwrite
mov       si, ax
add       di, 11
do_next_glyph_ftextwrite:
dec       cx
jmp       loop_count
do_char_upper_ftextwrite:
xor       ah, ah

call      locallib_toupper_
mov       bl, al
sub       bl, HU_FONTSTART
jl        bad_glyph_ftextwrite
cmp       bl, HU_FONTSIZE
jle       lookup_glyph_width_ftextwrite
bad_glyph_ftextwrite:
add       si, 4
jmp       do_next_glyph_ftextwrite
lookup_glyph_width_ftextwrite:
mov       ax, FONT_WIDTHS_SEGMENT
mov       es, ax
xor       bh, bh                    ; zero high bits.
mov       al, byte ptr es:[bx]
cbw      
add       ax, si
mov       word ptr [bp - 0Ah], ax
cmp       ax, SCREENWIDTH
jle       do_draw_glyph_ftextwrite
exit_ftextwrite:
LEAVE_MACRO    
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
do_draw_glyph_ftextwrite:
sal       bx, 1
mov       ax, ST_GRAPHICS_SEGMENT
push      ax
mov       ax, word ptr ds:[bx + _hu_font]
push      ax
mov       dx, di
xor       bx, bx
mov       ax, si
call      V_DrawPatch_
mov       si, word ptr [bp - 0Ah]
dec       cx
jmp       loop_count


ENDP


PROC F_DrawPatchCol_ NEAR
PUBLIC F_DrawPatchCol_

; technically i think this is only called with single post columns...

push  dx
push  si
push  di

mov   ds, cx
mov   cx, SCREEN0_SEGMENT
mov   es, cx
mov   cx, ax    ; dest x 
cmp   byte ptr ds:[bx], 0FFh
je    exit_drawpatchcol
draw_next_post:
mov   al, byte ptr ds:[bx]  ; get topdelta..
xor   ah, ah
mov   dx, SCREENWIDTH
mul   dx
mov   di, cx    ; screen x
add   di, ax    ; plus column topdelta
mov   al, byte ptr ds:[bx + 1]  ; get count
lea   si, [bx + 3]              ; column pixels
xor   ah, ah
xchg  ax, cx     ; count in cx so we can loop.
draw_next_pixel:
movsb
add   di, (SCREENWIDTH - 1)
loop  draw_next_pixel

done_with_post:
xchg  ax, cx                ; restore cx.
mov   al, byte ptr ds:[bx + 1]
xor   ah, ah
add   bx, ax
add   bx, 4                     ; next post address
cmp   byte ptr ds:[bx], 0FFh
jne   draw_next_post
exit_drawpatchcol:
push  ss
pop   ds  ; restore ds
pop   di
pop   si
pop   dx
ret   

ENDP


str_pfub1:
db "PFUB1", 0
str_pfub2:
db "PFUB2", 0
str_end0:
db "END0", 0


FINALE_PHASE_1_CHANGE = 1130
FINALE_PHASE_2_CHANGE = 1180

; function can probably be optimized and made smaller, I haven't really tried - sq

PROC F_BunnyScroll_ NEAR
PUBLIC F_BunnyScroll_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 018h
xor   ax, ax
mov   cx, SCREENHEIGHT
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 6], ax
xor   al, al
mov   bx, SCREENWIDTH
mov   byte ptr [bp - 2], al ; bp - 2 is pic2 boolean
xor   ah, ah
xor   dx, dx
mov   word ptr [bp - 8], ax
call  Z_QuickMapScratch_5000_
xor   ax, ax
call  V_MarkRect_
;    scrolled = 320 - (finalecount-230)/2;
mov   ax, word ptr cs:[_CSDATA_finalecount]
sub   ax, 230            
cwd
sub   ax, dx     ; i dont know what this cwd sub does.
sar   ax, 1
mov   word ptr [bp - 0Eh], SCRATCH_SEGMENT_5000
mov   dx, SCREENWIDTH
mov   si, 05400h    ; lookup offset
sub   dx, ax
xor   di, di
mov   word ptr [bp - 0Ch], dx   ; bp - 0Ch is scrolled
cmp   dx, SCREENWIDTH
jg    cap_scrolled_to_320

test  dx, dx
jge   scrolled_ready

mov   word ptr [bp - 0Ch], di   ; zero out scrolled
jmp   scrolled_ready

cap_scrolled_to_320:
mov   word ptr [bp - 0Ch], SCREENWIDTH
scrolled_ready:


mov   bx, OFFSET str_pfub2
mov   ax, OFFSET _filename_argument
call  F_CopyString9_

xor   bx, bx
push  bx
push  bx
mov   cx, SCRATCH_SEGMENT_5000
mov   dx, bx
call  W_GetNumForName_
call  W_CacheLumpNumDirectFragment_
xor   bx, bx
push  bx

mov   bx, OFFSET str_pfub2
mov   ax, OFFSET _filename_argument
call  F_CopyString9_


mov   bx, di
xor   cx, cx
push  cx
mov   cx, si
call  W_GetNumForName_
call  W_CacheLumpNumDirectFragment_

draw_next_bunny_column:
mov   ax, word ptr [bp - 0Ch]   ; get scrolled
add   ax, dx
cmp   ax, SCREENWIDTH
jl    xcoord_ready
jmp   calculate_xcoord
xcoord_ready:
mov   bx, word ptr [bp - 8]
shl   ax, 1
shl   ax, 1
mov   es, word ptr [bp - 0Eh]
add   bx, ax
mov   ax, word ptr es:[bx + 8]
sub   ax, word ptr [bp - 4]
mov   bx, word ptr es:[bx + 0Ah]
sbb   bx, word ptr [bp - 6]
test  bx, bx
jg    load_next_fullscreenpatch_chunk
jne   go_draw_patchcol
cmp   ax, 15000          ; kinda arbitrary "almost 16384" number
jbe   go_draw_patchcol
load_next_fullscreenpatch_chunk:
add   word ptr [bp - 4], ax
adc   word ptr [bp - 6], bx
cmp   byte ptr [bp - 2], 0
jne   use_pfub1
jmp   use_pfub2
use_pfub1:
mov   bx, word ptr [bp - 6]
push  bx

mov   bx, OFFSET str_pfub1



draw_chosen_pfub:

mov   ax, OFFSET _filename_argument
call  F_CopyString9_


mov   bx, di
mov   cx, word ptr [bp - 4]
push  cx
mov   cx, si
call  W_GetNumForName_
call  W_CacheLumpNumDirectFragment_
xor   ax, ax
go_draw_patchcol:
mov   bx, di
mov   cx, si
add   bx, ax
mov   ax, dx
inc   dx
call  F_DrawPatchCol_
cmp   dx, SCREENWIDTH
jl    draw_next_bunny_column
mov   ax, word ptr cs:[_CSDATA_finalecount]
cmp   ax, FINALE_PHASE_1_CHANGE
jl    exit_bunnyscroll
cmp   ax, FINALE_PHASE_2_CHANGE
jl    draw_end_patch
sub   ax, FINALE_PHASE_2_CHANGE
mov   bx, 5
CWD   
div   bx
mov   bx, ax        
cmp   ax, 6
jle   finale_stage_calculated
mov   bx, 6     ; cap fianle to 6.
finale_stage_calculated:
mov   al, byte ptr cs:[_CSDATA_finale_laststage]
cbw  
cmp   bx, ax
jle   draw_end0_patch
mov   dx, 1
xor   ax, ax
call  S_StartSound_
mov   byte ptr cs:[_CSDATA_finale_laststage], bl
draw_end0_patch:
mov   cl, bl  ; get finale stage in cl
mov   bx, OFFSET str_end0
mov   ax, OFFSET _filename_argument
call  F_CopyString9_
add   byte ptr [_filename_argument+3], cl ; add to the '0'

mov   bx, word ptr [bp - 8]
mov   cx, word ptr [bp - 0Eh]
mov   dx, (SCREENHEIGHT-8*8)/2
call  W_CacheLumpNameDirect_
mov   ax, word ptr [bp - 0Eh]
push  ax
mov   ax, word ptr [bp - 8]
push  ax

mov   ax, (SCREENWIDTH-13*8)/2
xor   bx, bx
call  V_DrawPatch_
exit_bunnyscroll:
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
draw_end_patch:
mov   cx, word ptr [bp - 0Eh]
mov   bx, OFFSET str_end0
mov   ax, OFFSET _filename_argument
call  F_CopyString9_
mov   bx, word ptr [bp - 8]


mov   dx, (SCREENHEIGHT-8*8)/2
call W_CacheLumpNameDirect_
mov   ax, word ptr [bp - 0Eh]
push  ax
mov   ax, word ptr [bp - 8]
push  ax

mov   ax, (SCREENWIDTH-13*8)/2
xor   bx, bx
call  V_DrawPatch_
mov   byte ptr cs:[_CSDATA_finale_laststage], 0
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

calculate_xcoord:
mov   al, byte ptr [bp - 2]
test  al, al
jne   currently_pic2
; load pic2 into 0x5000 seg
mov   byte ptr [bp - 2], 1
xor   cx, cx
push  cx
push  cx
mov   cx, SCRATCH_SEGMENT_5000
xor   ah, ah
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 6], ax

mov   bx, OFFSET str_pfub1
mov   ax, OFFSET _filename_argument
call  F_CopyString9_
xor   bx, bx


call  W_GetNumForName_
call  W_CacheLumpNumDirectFragment_
xor   ax, ax
push  ax

mov   bx, OFFSET str_pfub1
mov   ax, OFFSET _filename_argument
call  F_CopyString9_

mov   bx, di
xor   cx, cx
push  cx
mov   cx, si
call  W_GetNumForName_
call  W_CacheLumpNumDirectFragment_
currently_pic2:
mov   ax, word ptr [bp - 0Ch] ; get scrolled
add   ax, dx
sub   ax, SCREENWIDTH
jmp   xcoord_ready
use_pfub2:
mov   bx,  word ptr [bp - 6]
push  bx
mov   bx, OFFSET str_pfub2         ; string addr...
jmp   draw_chosen_pfub


ENDP




PROC F_StartCast_ NEAR
PUBLIC F_StartCast_


push  bx
push  dx

cmp   word ptr cs:[_CSDATA_finalestage], 2
je    dont_force_screenwipe
mov   byte ptr [_wipegamestate], 0FFh  ; force screen wipe
dont_force_screenwipe:
mov   al, byte ptr cs:[_CSDATA_castorder+1]     ;  castorder[castnum].type). castnum is 0.
xor   ah, ah
mov   byte ptr cs:[_CSDATA_castnum], 0
; call getSeeState
db    09Ah
dw    GETSEESTATEADDR, INFOFUNCLOADSEGMENT
mov   bx, ax
shl   bx, 1
shl   bx, 1
sub   bx, ax
mov   ax, STATES_SEGMENT
add   bx, bx

mov   word ptr cs:[_CSDATA_caststate], bx
mov   es, ax
mov   al, byte ptr es:[bx + 2]
mov   dx, 1
mov   byte ptr cs:[_CSDATA_casttics], al
xor   al, al
mov   byte ptr cs:[_CSDATA_castdeath], 0
mov   byte ptr cs:[_CSDATA_castframes], al
mov   byte ptr cs:[_CSDATA_castonmelee], al
mov   byte ptr cs:[_CSDATA_castattacking], al
mov   ax, MUS_EVIL
mov   word ptr cs:[_CSDATA_finalestage], 2
call  S_ChangeMusic_
pop   dx
pop   bx
ret   

ENDP


PROC F_CastTicker_ NEAR
PUBLIC F_CastTicker_

; lots of switch block shenanigans going on. 

push  bx
push  dx

dec   byte ptr cs:[_CSDATA_casttics]
cmp   byte ptr cs:[_CSDATA_casttics], 0
jle   do_castticker
exit_castticker:

pop   dx
pop   bx
ret   
do_castticker:
call  Z_QuickMapPhysics_
les   bx, dword ptr cs:[_CSDATA_caststate]       
cmp   byte ptr es:[bx + 2], 0FFh
je    label_1
jmp   label_2
label_1:
inc   byte ptr cs:[_CSDATA_castnum]
mov   byte ptr cs:[_CSDATA_castdeath], 0
cmp   byte ptr cs:[_CSDATA_castnum], MAX_CASTNUM
jne   label_8
mov   byte ptr cs:[_CSDATA_castnum], 0
label_8:
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, INFOFUNCLOADSEGMENT
mov   dl, al
xor   dh, dh
xor   ax, ax
call  S_StartSound_
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, INFOFUNCLOADSEGMENT
mov   dx, ax
shl   ax, 1
shl   ax, 1
sub   ax, dx

add   ax, ax
mov   byte ptr cs:[_CSDATA_castframes], 0
label_40:
mov   word ptr cs:[_CSDATA_caststate], ax
label_28:
cmp   byte ptr cs:[_CSDATA_castattacking], 0
je    label_6
cmp   byte ptr cs:[_CSDATA_castframes], 24
jne   label_9
label_5:
xor   al, al
mov   byte ptr cs:[_CSDATA_castattacking], al
mov   byte ptr cs:[_CSDATA_castframes], al
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, INFOFUNCLOADSEGMENT
mov   dx, ax
shl   ax, 1
shl   ax, 1
sub   ax, dx
add   ax, ax
mov   word ptr cs:[_CSDATA_caststate], ax
label_6:
les   bx, dword ptr cs:[_CSDATA_caststate]
mov   al, byte ptr es:[bx + 2]
mov   byte ptr cs:[_CSDATA_casttics], al
cmp   al, 0FFh
je    label_7
jmp   exit_castticker
label_7:
mov   byte ptr cs:[_CSDATA_casttics], 15
 
pop   dx
pop   bx
ret   
label_9:
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, INFOFUNCLOADSEGMENT
mov   dx, ax
shl   ax, 1
shl   ax, 1
sub   ax, dx
mov   dx, word ptr cs:[_CSDATA_caststate]
add   ax, ax
cmp   dx, ax
je    label_5
jmp   label_6
label_2:
cmp   word ptr es:[bx + 4], 0
jne   label_3
jmp   label_1
label_3:
cmp   ax, STATES_SEGMENT
jne   label_4
cmp   bx, (S_PLAY_ATK1 * 6)   ; 6 is sizeof state
jne   label_4
jmp   label_5
label_4:
mov   ax, word ptr es:[bx + 4]
mov   dx, ax
shl   dx, 1
shl   dx, 1
sub   dx, ax
add   dx, dx
inc   byte ptr cs:[_CSDATA_castframes]
mov   word ptr cs:[_CSDATA_caststate], dx
cmp   ax, S_TROO_ATK3
jb    label_10
jmp   label_11
label_10:
cmp   ax, S_SKEL_FIST4
jb    label_35
jmp   label_34
label_35:
cmp   ax, S_SPOS_ATK2
jb    label_32
jmp   label_33
label_32:
cmp   ax, S_POSS_ATK2
je    label_31
jmp   label_30
label_31:
mov   ax, 1
label_13:
mov   dl, al
xor   dh, dh
xor   ax, ax
call  S_StartSound_
cmp   byte ptr cs:[_CSDATA_castframes], 0Ch
je    label_27
jump_to_label_28:
jmp   label_28
label_27:
mov   byte ptr cs:[_CSDATA_castattacking], 1
cmp   byte ptr cs:[_CSDATA_castonmelee], 0
jne   jump_to_label_29
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah

db    09Ah
dw    GETMISSILESTATEADDR, INFOFUNCLOADSEGMENT

label_26:
mov   dx, ax
shl   ax, 1
shl   ax, 1
sub   ax, dx
add   ax, ax
mov   word ptr cs:[_CSDATA_caststate], ax
xor   byte ptr cs:[_CSDATA_castonmelee], 1

mov   dx, word ptr cs:[_CSDATA_caststate]   ; check if state 0
test  dx, dx
jne   jump_to_label_28
cmp   byte ptr cs:[_CSDATA_castonmelee], 0
je    label_36
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETMELEESTATEADDR, INFOFUNCLOADSEGMENT
mov   dx, ax
shl   ax, 1
shl   ax, 1
sub   ax, dx
add   ax, ax

jmp   label_40
label_11:
ja    label_12
mov   ax, SFX_CLAW
jmp   label_13
jump_to_label_29:
jmp   label_29
label_12:
cmp   ax, S_SPID_ATK2
jae   label_44
cmp   ax, S_BOSS_ATK2
jae   label_43
cmp   ax, S_HEAD_ATK2
jne   label_42
label_21:
mov   ax, SFX_FIRSHT
jmp   label_13
label_44:
cmp   ax, S_SPID_ATK3
ja    label_22
mov   ax, SFX_SHOTGN
jmp   label_13
label_22:
cmp   ax, S_CYBER_ATK4
jae   label_23
cmp   ax, S_CYBER_ATK2
jne   label_24
label_37:
mov   ax, SFX_RLAUNC
jmp   label_13
label_36:
jmp   label_25
label_23:
jbe   label_37
cmp   ax, S_PAIN_ATK3
jne   label_38
mov   ax, SFX_SKLATK
jmp   label_13
label_38:
cmp   ax, S_CYBER_ATK6
je    label_37
label_14:
xor   ax, ax
jmp   label_13
label_24:
cmp   ax, S_BSPI_ATK2
jne   label_14
mov   ax, SFX_PLASMA
jmp   label_13
label_43:
jbe   label_21
cmp   ax, S_SKULL_ATK2
jne   label_39
mov   ax, SFX_SKLATK
jmp   label_13
label_39:
cmp   ax, S_BOS2_ATK2
je    label_21
jmp   label_14
label_42:
cmp   ax, S_SARG_ATK2
jne   label_14
mov   ax, SFX_SGTATK
jmp   label_13
label_34:
ja    label_20
mov   ax, SFX_SKEPCH
jmp   label_13
label_20:
cmp   ax, S_FATT_ATK5
jae   label_19
cmp   ax, S_FATT_ATK2
jne   label_18
label_15:
mov   ax, SFX_FIRSHT
jmp   label_13
label_19:
jbe   label_15
cmp   ax, S_FATT_ATK8
jb    label_14
jbe   label_15
cmp   ax, S_CPOS_ATK2
jb    label_14
cmp   ax, S_CPOS_ATK4
ja    label_14
mov   ax, SFX_SHOTGN
jmp   label_13
label_18:
cmp   ax, S_SKEL_MISS2
jne   label_14
mov   ax, SFX_SKEATK
jmp   label_13
label_33:
ja    label_16
mov   ax, SFX_SHOTGN
jmp   label_13
label_16:
cmp   ax, S_SKEL_FIST2
jne   label_17
mov   ax, SFX_SKESWG
jmp   label_13
label_17:
cmp   ax, S_VILE_ATK2
je    label_41
jump_to_label_14:
jmp   label_14
label_41:
mov   ax, SFX_VILATK
jmp   label_13
label_30:
cmp   ax, S_PLAY_ATK1
jne   jump_to_label_14
mov   ax, SFX_DSHTGN
jmp   label_13
label_29:
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETMELEESTATEADDR, INFOFUNCLOADSEGMENT
jmp   label_26
label_25:
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETMISSILESTATEADDR, INFOFUNCLOADSEGMENT

mov   dx, ax
shl   ax, 1
shl   ax, 1
sub   ax, dx
add   ax, ax

jmp   label_40


ENDP

PROC F_CastResponder_ NEAR
PUBLIC F_CastResponder_



push  bx
mov   bx, ax
mov   es, dx
cmp   byte ptr es:[bx], 0
jne   exit_fresponder_return0
cmp   byte ptr cs:[_CSDATA_castdeath], 0
je    do_castdeath
mov   al, 1
pop   bx
ret   
exit_fresponder_return0:
xor   al, al
pop   bx
ret   
do_castdeath:
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr [bx + _CSDATA_castorder+1]
xor   ah, ah
mov   byte ptr cs:[_CSDATA_castdeath], 1
db    09Ah
dw    GETDEATHSTATEADDR, INFOFUNCLOADSEGMENT

mov   bx, ax
shl   bx, 1
shl   bx, 1
sub   bx, ax
mov   ax, STATES_SEGMENT
add   bx, bx
mov   word ptr cs:[_CSDATA_caststate], bx
mov   es, ax
mov   al, byte ptr es:[bx + 2]
mov   byte ptr cs:[_CSDATA_casttics], al
xor   al, al
mov   byte ptr cs:[_CSDATA_castframes], al
mov   byte ptr cs:[_CSDATA_castattacking], al
mov   al, byte ptr cs:[_CSDATA_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr [bx + _CSDATA_castorder+1]
mov   ah, 0Bh  ; sizeof mobjinfo?
mul   ah
mov   bx, ax
xor   ax, ax
mov   dl, byte ptr [bx + _mobjinfo + 3]
xor   dh, dh
call  S_StartSound_
mov   al, 1
pop   bx
ret   


ENDP

TEXTWAIT = 250

PROC F_Ticker_ FAR
PUBLIC F_Ticker_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 029Ah
cmp   byte ptr [_commercial], 0
je    done_checking_skipping
cmp   word ptr cs:[_CSDATA_finalecount], 50
jle   done_checking_skipping
cmp   byte ptr [_player + 7], 0   ; player.cmd.buttons
je    done_checking_skipping
cmp   byte ptr [_gamemap], 30
jne   do_worlddone
call  F_StartCast_
done_checking_skipping:
inc   word ptr cs:[_CSDATA_finalecount]
cmp   word ptr cs:[_CSDATA_finalestage], 2
je    call_fcastticker
cmp   byte ptr [_commercial], 0
je    do_noncommerical
exit_fticker:
LEAVE_MACRO
pop   dx
pop   cx
pop   bx
retf  
do_worlddone:
mov   byte ptr [_gameaction], GA_WORLDDONE
jmp   done_checking_skipping
call_fcastticker:
call  F_CastTicker_
jmp   exit_fticker
do_noncommerical:
lea   bx, [bp - 029Ah]
mov   ax, word ptr cs:[_CSDATA_finaletext]
mov   cx, ds
call  getStringByIndex_
cmp   word ptr cs:[_CSDATA_finalestage], 0
jne   exit_fticker
lea   ax, [bp - 029Ah]
mov   dx, ds

call  locallib_strlen_
mov   dx, ax
shl   ax, 2
sub   ax, dx
add   ax, TEXTWAIT
cmp   ax, word ptr cs:[_CSDATA_finalecount]
jge   exit_fticker
mov   word ptr cs:[_CSDATA_finalestage], 1
xor   ax, ax
mov   byte ptr [_wipegamestate], 0FFh
mov   word ptr cs:[_CSDATA_finalecount], ax
cmp   byte ptr [_gameepisode], 3
jne   exit_fticker
mov   ax, MUS_BUNNY
call  S_StartMusic_
LEAVE_MACRO
pop   dx
pop   cx
pop   bx
retf  


ENDP



PROC F_Responder_ FAR
PUBLIC F_Responder_

cmp  word ptr cs:[_CSDATA_finalestage], 2
je   call_castresponder
xor  al, al
retf 
call_castresponder:
call F_CastResponder_
retf 

ENDP

str_help2:
db "HELP2", 0
str_credit:
db "CREDIT", 0
str_victory2:
db "VICTORY2", 0
str_endpic:
db "ENDPIC", 0

PROC F_Drawer_ FAR
PUBLIC F_Drawer_



push  bx
push  dx
mov   ax, word ptr cs:[_CSDATA_finalestage]
cmp   ax, 2
je    call_castdrawer
test  ax, ax
je    call_textwrite
mov   bl, byte ptr [_gameepisode]
xor   bh, bh
mov   ax, OFFSET _filename_argument
cmp   bl, 4
ja    exit_fdrawer
je    fdrawer_episode4
cmp   bl, 2
je    fdrawer_episode2
ja    fdrawer_episode3


fdrawer_episode1:



cmp   byte ptr [_is_ultimate], 0
jne   do_ultimate_fullscreenpatch
mov   bx, OFFSET str_help2
do_finaledraw:
call  F_CopyString9_

xor   dx, dx
call  V_DrawFullscreenPatch_
exit_fdrawer:
pop   dx
pop   bx
retf  

call_castdrawer:
call  F_CastDrawer_
pop   dx
pop   bx
retf  
call_textwrite:
call  F_TextWrite_
pop   dx
pop   bx
retf  

do_ultimate_fullscreenpatch:
mov   bx, OFFSET str_credit
jmp   do_finaledraw
fdrawer_episode2:
mov   bx, OFFSET str_victory2
jmp   do_finaledraw
fdrawer_episode3:
call  F_BunnyScroll_
pop   dx
pop   bx
retf  
fdrawer_episode4:
mov   bx, OFFSET str_endpic
jmp   do_finaledraw

ENDP

END