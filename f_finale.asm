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
INCLUDE defs.inc
INCLUDE states.inc
INCLUDE sound.inc
INCLUDE strings.inc
INSTRUCTION_SET_MACRO_NO_MEDIUM




SEGMENT F_FINALE_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:F_FINALE_TEXT


PROC   F_FINALE_STARTMARKER_ NEAR
PUBLIC F_FINALE_STARTMARKER_
ENDP

; vars and data..



_CSDATA_castorder:
db    CC_ZOMBIE-CASTORDEROFFSET,    MT_POSSESSED
db    CC_SHOTGUN-CASTORDEROFFSET,   MT_SHOTGUY
db    CC_HEAVY-CASTORDEROFFSET,     MT_CHAINGUY
db    CC_IMP-CASTORDEROFFSET,       MT_TROOP
db    CC_DEMON-CASTORDEROFFSET,     MT_SERGEANT
db    CC_LOST-CASTORDEROFFSET,      MT_SKULL
db    CC_CACO-CASTORDEROFFSET,      MT_HEAD
db    CC_HELL-CASTORDEROFFSET,      MT_KNIGHT
db    CC_BARON-CASTORDEROFFSET,     MT_BRUISER
db    CC_ARACH-CASTORDEROFFSET,     MT_BABY
db    CC_PAIN-CASTORDEROFFSET,      MT_PAIN
db    CC_REVEN-CASTORDEROFFSET,     MT_UNDEAD
db    CC_MANCU-CASTORDEROFFSET,     MT_FATSO
db    CC_ARCH-CASTORDEROFFSET,      MT_VILE
db    CC_SPIDER-CASTORDEROFFSET,    MT_SPIDER
db    CC_CYBER-CASTORDEROFFSET,     MT_CYBORG
db    CC_HERO-CASTORDEROFFSET,      MT_PLAYER



MAX_CASTNUM = 017

FINALE_STAGE_TEXT = 0
FINALE_STAGE_BUNNY = 1
FINALE_STAGE_CAST = 2

PROC   V_DrawPatchFlipped_ NEAR
PUBLIC V_DrawPatchFlipped_


push  bp
mov   bp, sp


mov   bx, SCRATCH_SEGMENT_5000
mov   ds, bx
xor   bx, bx
sub   dx, word ptr ds:[bx + PATCH_T.patch_topoffset]
mov   es, dx   ; store
mov   si, ax
mov   ax, SCREENWIDTH
mul   dx
xchg  si, ax


sub   ax, word ptr ds:[bx + PATCH_T.patch_leftoffset] 
mov   cx, word ptr ds:[bx + PATCH_T.patch_height]
mov   dx, es   ; get dx back
mov   di, word ptr ds:[bx + PATCH_T.patch_width]

push  ds    ; store ds 0x5000
push  ss
pop   ds    ; restore ds for this func call
mov   bx, di
add   si, ax
call  F_MarkRect_


pop   ds    ; restore ds 0x5000
mov   word ptr cs:[_SELFMODIFY_set_desttop+1], si

; dx is end condition i guess
mov   dx, di

test  dx, dx
jle   exit_drawpatchflipped
dec   di
SHIFT_MACRO shl di 2
lea   bx, [di + PATCH_T.patch_columnofs]
mov   ax, SCREEN0_SEGMENT
mov   es, ax    ; for movsw
xor   cx, cx    ; zero ch

draw_next_column_flipped:
; ds:bx is patch 

mov   si, word ptr ds:[bx]   ; get column
lodsb
cmp   al, 0FFh
je    iterate_to_next_column_flipped

draw_next_post_flipped:
; al has ds:[si]  ; top delta



mov   ah, SCREENWIDTHOVER2
mul   ah        ; 8 bit mul faster than 16, doesnt kill dx
sal   ax, 1     ; times 2

    ; dest = es:di.    dest = desttop + column->topdelta*SCREENWIDTH;
_SELFMODIFY_set_desttop:
mov   di, 01000h
add   di, ax
lodsb     ; get column length
inc   si  ; to column data

mov   cl, al
loop_copy_pixel:
movsb
add   di, SCREENWIDTH-1
loop   loop_copy_pixel

inc    si
lodsb

cmp   al, 0FFh
jne   draw_next_post_flipped
iterate_to_next_column_flipped:
sub   bx, 4         ; iterate backwards a column..
inc   word ptr cs:[_SELFMODIFY_set_desttop+1]      ; increment desttop x.
dec   dx
jne   draw_next_column_flipped
exit_drawpatchflipped:

LEAVE_MACRO
push  ss
pop   ds
ret   




ENDP

PROC   F_CastPrint_ NEAR
PUBLIC F_CastPrint_


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
ret   
char_not_string_end:
xor   ah, ah

call  F_locallib_toupper_

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

call  F_locallib_toupper_

sub   al, HU_FONTSTART
jl    bad_glyph2
cmp   al, HU_FONTSIZE
jle   lookup_glyph_width2
bad_glyph2:
add   cx, 4
draw_next_glyph:
test  si, si
jne   print_next_char
ret   
lookup_glyph_width2:
mov   bx, FONT_WIDTHS_SEGMENT
mov   es, bx
cbw
mov   bx, ax
mov   al, byte ptr es:[bx]
xchg  ax, di

push  cx    ; kinda gross
xchg  ax, cx

mov   cx, ST_GRAPHICS_SEGMENT    
mov   es, cx        ; v_ drawpatch arg

sal   bx, 1
mov   cx, word ptr ds:[bx + _hu_font]

mov   dx, 180   ; y coord for draw patch.

call  F_DrawPatch_


pop   cx 
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
flat_rrock17:
db "RROCK17", 0
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

; lookups for doom1 (noncommercial) case

flat_nondoom2_lookup:
dw flat_floor4_8, flat_sflr6_1, flat_mflr8_4, flat_mflr8_3

; BIG TODO: if other build versions are to be implemented then
;  the strings above must be added to and switch cases changed a bit. could make a big fat lookup table with all fields?
;  once this is overlaid it probably wont be a big problem.
PROC   F_StartFinale_ FAR
PUBLIC F_StartFinale_


PUSHA_NO_AX_OR_BP_OR_DI_MACRO
mov   byte ptr ds:[_gameaction], 0
xor   al, al
mov   byte ptr ds:[_gamestate], 2
mov   byte ptr ds:[_viewactive], al
mov   byte ptr ds:[_automapactive], al
cmp   byte ptr ds:[_commercial], 0
je    jump_to_handle_doom1
mov   al, byte ptr ds:[_gamemap]
cmp   al, 15
jae   doom2_above_or_equal_to_15
cmp   al, 11
jne   doom2_below_15_not_11
; doom2 case 11
mov   bx, OFFSET flat_rrock14
mov   cx, C2TEXT
got_flat_values:
mov   ax, 65 ; set finale_music
got_flat_values_and_music:
; ax is finale music
; cx is finaletext
; bx is text for the flat graphic
mov   ah, 1
mov   word ptr ds:[_finaleflat], bx
mov   word ptr ds:[_finaletext], cx
;call  S_ChangeMusic_
mov   word ptr ds:[_pendingmusicenum], ax

xor   ax, ax
mov   byte ptr ds:[_finalestage], al
mov   word ptr ds:[_finalecount], ax
POPA_NO_AX_OR_BP_OR_DI_MACRO
retf  

doom2_above_or_equal_to_15:
ja    doom2_above_15
; doom2 case 15 
mov   bx, OFFSET flat_rrock13
mov   cx, C5TEXT
jmp   got_flat_values
doom2_above_15:
cmp   al, 31
jne   doom2_above_15_not_31
; doom2 case 31
mov   bx, OFFSET flat_rrock19
mov   cx, C6TEXT
jmp   got_flat_values
doom2_above_15_not_31:
cmp   al, 30
jne   doom2_above_15_not_31_30
; doom2 case 30
mov   bx, OFFSET flat_rrock17
mov   cx, C4TEXT
jmp   got_flat_values
doom2_above_15_not_31_30:
cmp   al, 20
jne   got_flat_values
;doom2 case 20
mov   bx, OFFSET flat_floor4_8
mov   cx, C3TEXT
jmp   got_flat_values
jump_to_handle_doom1:
jmp   handle_doom1
doom2_below_15_not_11:
cmp   al, 6
jne   got_flat_values
; doom2 case 6
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

mov   bx, word ptr cs:[si + flat_nondoom2_lookup]
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


PROC   F_CastDrawer_ NEAR
PUBLIC F_CastDrawer_

; bp - 4 is unused
; bp - 2 is spritenum
; bp - 1 is spriteframenum

push  bp
mov   bp, sp
sub   sp, 068h
les   bx, dword ptr ds:[_caststate]     ; state pointer
mov   ax, word ptr es:[bx]              ; spritenum_t	sprite, spriteframenum_t	frame
mov   word ptr [bp - 2], ax

mov   ax, OFFSET str_bossback
mov   dx, cs

call  dword ptr ds:[_V_DrawFullscreenPatch_addr]




mov   al, byte ptr ds:[_castnum]

sal    ax, 1
mov    bx, OFFSET _CSDATA_castorder
xlat   byte ptr cs:[bx]
mov   cx, ds
;xor   ah, ah   ; between 0-17, cbw is fine
cbw
mov   bx, sp ; text param (100 length)
add   ax, CASTORDEROFFSET

call  dword ptr ds:[_getStringByIndex_addr]

;call _Z_QuickMapStatusNoScreen4_
; inlined
Z_QUICKMAPAI4 (pageswapargs_stat_offset_size+1) INDEXED_PAGE_7000_OFFSET
Z_QUICKMAPAI1_NO_DX (pageswapargs_stat_offset_size+5) INDEXED_PAGE_6000_OFFSET



mov   ax, sp  ; ; text param (100 length)
call  F_CastPrint_

;call  Z_QuickMapRender7000_
Z_QUICKMAPAI4 (pageswapargs_rend_offset_size+12) INDEXED_PAGE_7000_OFFSET


mov   al, byte ptr [bp - 2]
xor   ah, ah
mov   bx, ax
SHIFT_MACRO shl bx 2
sub   bx, ax                    ; mul 3...
mov   ax, SPRITES_SEGMENT
mov   es, ax
mov   al, byte ptr [bp - 1]
and   al, FF_FRAMEMASK
mov   ah, 019h           ; todo sizeof spriteframe_t
mul   ah
mov   bx, word ptr es:[bx]
add   bx, ax

call  Z_QuickMapScratch_5000_FinaleLocal_

mov   cx, word ptr es:[bx]
mov   dl, byte ptr es:[bx + 010h]

mov   ax, word ptr ds:[_firstspritelump]
xor   bx, bx
add   ax, cx
mov   cx, SCRATCH_SEGMENT_5000

call  dword ptr ds:[_W_CacheLumpNumDirect_addr]   ; get graphic in memory

test  dl, dl
je    not_flipped
mov   dx, 170                ; y param
mov   ax, SCREENWIDTHOVER2
call  V_DrawPatchFlipped_
jmp   exit_castdrawer
not_flipped:
mov   cx, SCRATCH_SEGMENT_5000
mov   es, cx
xor   cx, cx
mov   dx, 170                ; y param
mov   ax, SCREENWIDTHOVER2

call  F_DrawPatch_

exit_castdrawer:
LEAVE_MACRO 
ret   


ENDP

SEGMENT_4000_OFFSET = (04000h - FIXED_DS_SEGMENT) SHL 4


PROC   F_TextWrite_ NEAR
PUBLIC F_TextWrite_


push      bp
mov       bp, sp

mov       bx, SEGMENT_4000_OFFSET
push      bx

call  Z_QuickMapScratch_5000_FinaleLocal_

;call    Z_QuickMapScreen0_
Z_QUICKMAPAI4 pageswapargs_screen0_offset_size INDEXED_PAGE_8000_OFFSET


mov       bx, word ptr ds:[_finaleflat]
mov       ax, OFFSET _filename_argument
call      F_CopyString9_
xor       bx, bx

mov       cx, SCRATCH_SEGMENT_5000
xor       di, di                    ; dest offset 0

xor       dx, dx

call  dword ptr ds:[_W_CacheLumpNameDirect_addr]


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
xor       ax, ax
loop_draw_fullscreen_next_row:





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

add       ax, 64	  ; add 64 (next texel row)
and       ax, 00FFFh  ; mod by flat size


inc       dx
cmp       dx, SCREENHEIGHT
jb        loop_draw_fullscreen_next_row

; restore ds
push      ss
pop       ds


;call _Z_QuickMapStatusNoScreen4_
; inlined
Z_QUICKMAPAI4 (pageswapargs_stat_offset_size+1) INDEXED_PAGE_7000_OFFSET

xor       ax, ax
cwd
; inlined markrect, clear whole screen
xor   ax, ax
mov   di, OFFSET _dirtybox
xor   ax, ax
mov   word ptr ds:[di + 2 * BOXBOTTOM], ax
mov   word ptr ds:[di + 2 * BOXLEFT],   ax
mov   word ptr ds:[di + 2 * BOXTOP],    SCREENHEIGHT - 1
mov   word ptr ds:[di + 2 * BOXRIGHT],  SCREENWIDTH - 1

mov       bx, SEGMENT_4000_OFFSET
mov       ax, word ptr ds:[_finaletext]
mov       cx, ds
mov       si, 10

call      dword ptr ds:[_getStringByIndex_addr]
mov       ax, word ptr ds:[_finalecount]
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
mov       bx, word ptr [bp - 2]
mov       al, byte ptr ds:[bx]
cbw      
inc       word ptr [bp - 2]
mov       dx, ax
test      ax, ax
je        exit_ftextwrite
cmp       ax, 10
jne       do_char_upper_ftextwrite
mov       si, ax
add       di, 11
do_next_glyph_ftextwrite:
dec       cx
jmp       loop_count        ; todo should this be a loop?
do_char_upper_ftextwrite:
xor       ah, ah

call      F_locallib_toupper_

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

cmp       ax, SCREENWIDTH
jle       do_draw_glyph_ftextwrite
exit_ftextwrite:
LEAVE_MACRO    
ret       
do_draw_glyph_ftextwrite:
xchg      ax, si 
sal       bx, 1
push      cx
mov       cx, ST_GRAPHICS_SEGMENT
mov       es, cx
mov       cx, word ptr ds:[bx + _hu_font]

mov       dx, di

call      F_DrawPatch_

pop       cx
dec       cx
jmp       loop_count   ; dude why is this not a loop instruction


ENDP


PROC   F_DrawPatchCol_ NEAR
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
xor   ax, ax
xlat  
;mov   al, byte ptr ds:[bx]  ; get topdelta..
;xor   ah, ah
mov   dx, SCREENWIDTH
mul   dx
mov   di, cx    ; screen x
add   di, ax    ; plus column topdelta
;mov   al, byte ptr ds:[bx + 1]  ; get count
;xor   ah, ah
mov   ax, 1
xlat
lea   si, ds:[bx + 3]              ; column pixels
xchg  ax, cx     ; count in cx so we can loop.
draw_next_pixel:
movsb
add   di, (SCREENWIDTH - 1)
loop  draw_next_pixel

done_with_post:
xchg  ax, cx                ; restore cx.
;mov   al, byte ptr ds:[bx + 1]
;xor   ah, ah
mov   ax, 1
xlat

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

PROC   F_BunnyScroll_ NEAR
PUBLIC F_BunnyScroll_

push  bp
mov   bp, sp
sub   sp, 018h
xor   ax, ax
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 6], ax
xor   al, al
mov   byte ptr [bp - 2], al ; bp - 2 is pic2 boolean
xor   ah, ah
mov   word ptr [bp - 8], ax

call  Z_QuickMapScratch_5000_FinaleLocal_

; inlined markrect, clear whole screen
xor   ax, ax
mov   di, OFFSET _dirtybox
xor   ax, ax
mov   word ptr ds:[di + 2 * BOXBOTTOM], ax
mov   word ptr ds:[di + 2 * BOXLEFT],   ax
mov   word ptr ds:[di + 2 * BOXTOP],    SCREENHEIGHT - 1
mov   word ptr ds:[di + 2 * BOXRIGHT],  SCREENWIDTH - 1

;    scrolled = 320 - (finalecount-230)/2;
mov   ax, word ptr ds:[_finalecount]
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

call  dword ptr ds:[_W_GetNumForName_addr]


call  dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]

xor   bx, bx
push  bx

mov   bx, OFFSET str_pfub2
mov   ax, OFFSET _filename_argument
call  F_CopyString9_


mov   bx, di
xor   cx, cx
push  cx
mov   cx, si
call  dword ptr ds:[_W_GetNumForName_addr]

call  dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]

draw_next_bunny_column:
mov   ax, word ptr [bp - 0Ch]   ; get scrolled
add   ax, dx
cmp   ax, SCREENWIDTH
jl    xcoord_ready
jmp   calculate_xcoord
xcoord_ready:
mov   bx, word ptr [bp - 8]
SHIFT_MACRO shl ax 2
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
call  dword ptr ds:[_W_GetNumForName_addr]

call  dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]
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
mov   ax, word ptr ds:[_finalecount]
cmp   ax, FINALE_PHASE_1_CHANGE
jl    exit_bunnyscroll
cmp   ax, FINALE_PHASE_2_CHANGE
jl    draw_end_patch
sub   ax, FINALE_PHASE_2_CHANGE
mov   bx, 5
cwd   
div   bx
mov   bx, ax        
cmp   ax, 6
jle   finale_stage_calculated
mov   bx, 6     ; cap fianle to 6.
finale_stage_calculated:
mov   al, byte ptr ds:[_finale_laststage]
cbw  
cmp   bx, ax
jle   draw_end0_patch
mov   dl, SFX_PISTOL


;call  S_StartSound_
db    09Ah
dw    S_STARTSOUNDAX0FAROFFSET, PHYSICS_HIGHCODE_SEGMENT


mov   byte ptr ds:[_finale_laststage], bl
draw_end0_patch:
mov   cl, bl  ; get finale stage in cl
mov   bx, OFFSET str_end0
mov   ax, OFFSET _filename_argument
call  F_CopyString9_
add   byte ptr ds:[_filename_argument+3], cl ; add to the '0'

mov   bx, word ptr [bp - 8]
mov   cx, word ptr [bp - 0Eh]
mov   dx, (SCREENHEIGHT-8*8)/2
call  dword ptr ds:[_W_CacheLumpNameDirect_addr]
mov   es, word ptr [bp - 0Eh]  ; boy les would be great
mov   cx, word ptr [bp - 8]

mov   ax, (SCREENWIDTH-13*8)/2
call  F_DrawPatch_

exit_bunnyscroll:
LEAVE_MACRO
ret   
draw_end_patch:
mov   cx, word ptr [bp - 0Eh]
mov   bx, OFFSET str_end0
mov   ax, OFFSET _filename_argument
call  F_CopyString9_
mov   bx, word ptr [bp - 8]


mov   dx, (SCREENHEIGHT-8*8)/2
call  dword ptr ds:[_W_CacheLumpNameDirect_addr]
mov   es, word ptr [bp - 0Eh]  ; boy les would be great
mov   cx, word ptr [bp - 8]

mov   ax, (SCREENWIDTH-13*8)/2
call  F_DrawPatch_

mov   byte ptr ds:[_finale_laststage], 0
LEAVE_MACRO
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


call  dword ptr ds:[_W_GetNumForName_addr]

call  dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]
xor   ax, ax
push  ax

mov   bx, OFFSET str_pfub1
mov   ax, OFFSET _filename_argument
call  F_CopyString9_

mov   bx, di
xor   cx, cx
push  cx
mov   cx, si
call  dword ptr ds:[_W_GetNumForName_addr]

call  dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]
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




PROC   F_StartCast_ NEAR
PUBLIC F_StartCast_



xor   ax, ax 
mov   word ptr ds:[_castattacking], ax  ; 0     ; 140
;mov   byte ptr ds:[_castdeath], al     ; 0     ; 141
mov   word ptr ds:[_castonmelee], ax    ; 0    ; 142
;mov   byte ptr ds:[_castframes], al    ; 0     ; 143
mov   byte ptr ds:[_castnum], al        ; 0     ; 145
dec   ax
mov   byte ptr ds:[_wipegamestate], al  ; 0FFh force screen wipe
mov   byte ptr ds:[_finalestage], FINALE_STAGE_CAST
inc   ax ; zero ah

mov   al, byte ptr cs:[_CSDATA_castorder+1]     ;  castorder[castnum].type). castnum is 0.
; call getSeeState
db    09Ah
dw    GETSEESTATEADDR, PHYSICS_HIGHCODE_SEGMENT
mov   bx, ax
shl   bx, 1
add   bx, ax
shl   bx, 1

mov   word ptr ds:[_caststate], bx
mov   ax, STATES_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx + STATE_T.state_tics]
mov   byte ptr ds:[_casttics], al


mov   ax, MUS_EVIL + 0100h
;call  S_ChangeMusic_
mov   word ptr ds:[_pendingmusicenum], ax

exit_castticker_early:
ret   

ENDP

check_nextstate_for_null:
cmp   word ptr es:[bx + STATE_T.state_nextstate], S_NULL
je    select_next_monster
jmp   select_next_anim

PROC   F_CastTicker_ NEAR
PUBLIC F_CastTicker_

; lots of switch block shenanigans going on. 

dec   byte ptr ds:[_casttics]
jnz   exit_castticker_early

do_castticker:

;call  Z_QuickMapPhysics_ 
Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET


les   bx, dword ptr ds:[_caststate]    
; check caststate->tcis   
cmp   byte ptr es:[bx + STATE_T.state_tics], 0FFh
je    select_next_monster
jmp   check_nextstate_for_null
select_next_monster:
inc   byte ptr ds:[_castnum]
mov   byte ptr ds:[_castdeath], 0
cmp   byte ptr ds:[_castnum], MAX_CASTNUM
jne   got_castnum
; reset to first monster
mov   byte ptr ds:[_castnum], 0
got_castnum:
mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, PHYSICS_HIGHCODE_SEGMENT
mov   dl, al


;call  S_StartSound_
db    09Ah
dw    S_STARTSOUNDAX0FAROFFSET, PHYSICS_HIGHCODE_SEGMENT

mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, PHYSICS_HIGHCODE_SEGMENT
mov   dx, ax
SHIFT_MACRO shl ax 2
sub   ax, dx

add   ax, ax
mov   byte ptr ds:[_castframes], 0
done_with_attack_frame_switch:
mov   word ptr ds:[_caststate], ax
finished_attack_frame_switch_check:
cmp   byte ptr ds:[_castattacking], 0
je    cast_not_attacking
cmp   byte ptr ds:[_castframes], 24
jne   check_see_state
stopattack:
xor   al, al
mov   byte ptr ds:[_castattacking], al
mov   byte ptr ds:[_castframes], al
mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, PHYSICS_HIGHCODE_SEGMENT
mov   dx, ax
SHIFT_MACRO shl ax 2
sub   ax, dx
add   ax, ax
mov   word ptr ds:[_caststate], ax
cast_not_attacking:
les   bx, dword ptr ds:[_caststate]
mov   al, byte ptr es:[bx + STATE_T.state_tics]
mov   byte ptr ds:[_casttics], al
cmp   al, 0FFh
je    set_casttics_to_15
exit_castticker:

ret   
set_casttics_to_15:
mov   byte ptr ds:[_casttics], 15
ret   
check_see_state:
mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, PHYSICS_HIGHCODE_SEGMENT
mov   dx, ax
SHIFT_MACRO shl ax 2
sub   ax, dx
mov   dx, word ptr ds:[_caststate]
add   ax, ax
cmp   dx, ax
je    stopattack
jmp   cast_not_attacking

select_next_anim:
;		if (caststate == &states[S_PLAY_ATK1]){

cmp   bx, (S_PLAY_ATK1 * (SIZE STATE_T)) 
jne   do_next_state
jmp   stopattack


do_next_state:
mov   ax, word ptr es:[bx + STATE_T.state_nextstate]  ; nextstate
mov   dx, ax
SHIFT_MACRO shl dx 2
sub   dx, ax
add   dx, dx
inc   byte ptr ds:[_castframes]
mov   word ptr ds:[_caststate], dx
; switch block nastiness
cmp   ax, S_TROO_ATK3
jb    b_strooatk3
jmp   ae_strooatk3
b_strooatk3:
cmp   ax, S_SKEL_FIST4
jb    b_sskelfist4
ja    a_sskelfist4
mov   al, SFX_SKEPCH
jmp   selected_sfx

b_sskelfist4:
cmp   ax, S_SPOS_ATK2
jb    b_ssposatk2
ja    a_ssposatk2
mov   al, SFX_SHOTGN
jmp   selected_sfx


e_spossatk2:
mov   al, SFX_PISTOL
jmp   selected_sfx
a_ssposatk2:
cmp   ax, S_SKEL_FIST2
jne   ne_sskelfist2
mov   al, SFX_SKESWG
jmp   selected_sfx
b_ssposatk2:
cmp   ax, S_POSS_ATK2
je    e_spossatk2

cmp   ax, S_PLAY_ATK1
jne   default_no_sfx
mov   al, SFX_DSHTGN
jmp   selected_sfx

ne_sskelfist2:
cmp   ax, S_VILE_ATK2
je    e_svileatk2
jmp   default_no_sfx
e_svileatk2:
mov   al, SFX_VILATK
jmp   selected_sfx




ae_strooatk3:
ja    a_strooatk3
mov   al, SFX_CLAW
jmp   selected_sfx

a_sskelfist4:
cmp   ax, S_FATT_ATK5
jae   ae_sfattatk5
cmp   ax, S_FATT_ATK2
jne   ne_sfattatk2

e_sfattatk8:
mov   al, SFX_FIRSHT
jmp   selected_sfx

a_strooatk3:
cmp   ax, S_SPID_ATK2
jae   ae_sspidatk2
cmp   ax, S_BOSS_ATK2
jae   ae_sbossatk2
cmp   ax, S_HEAD_ATK2
jne   ne_sheadatk2
e_sbossatk2:
mov   al, SFX_FIRSHT
jmp   SHORT selected_sfx
ae_sspidatk2:
cmp   ax, S_SPID_ATK3
ja    a_sspidatk3
mov   al, SFX_SHOTGN
jmp   selected_sfx
a_sspidatk3:
cmp   ax, S_CYBER_ATK4
jae   ae_scyberatk4
cmp   ax, S_CYBER_ATK2
jne   ne_scyberatk2
e_scyberatk6:
mov   al, SFX_RLAUNC
jmp   selected_sfx

ae_scyberatk4:
jbe   e_scyberatk6
cmp   ax, S_PAIN_ATK3
jne   ne_spainatk3
mov   al, SFX_SKLATK
jmp   selected_sfx
ne_sfattatk2:
cmp   ax, S_SKEL_MISS2
jne   default_no_sfx
mov   al, SFX_SKEATK
jmp   selected_sfx

ne_spainatk3:
cmp   ax, S_CYBER_ATK6
je    e_scyberatk6
default_no_sfx:
xor   ax, ax
jmp   selected_sfx
ne_scyberatk2:
cmp   ax, S_BSPI_ATK2
jne   default_no_sfx
mov   al, SFX_PLASMA
jmp   selected_sfx
ae_sbossatk2:
jbe   e_sbossatk2
cmp   ax, S_SKULL_ATK2
jne   ne_sskullatk2
mov   al, SFX_SKLATK
jmp   selected_sfx
ne_sskullatk2:
cmp   ax, S_BOS2_ATK2
je    e_sbossatk2
jmp   default_no_sfx
ae_sfattatk5:
jbe   e_sfattatk8
cmp   ax, S_FATT_ATK8
jb    default_no_sfx
jbe   e_sfattatk8
cmp   ax, S_CPOS_ATK2
jb    default_no_sfx
cmp   ax, S_CPOS_ATK4
ja    default_no_sfx
mov   al, SFX_SHOTGN
jmp   selected_sfx
ne_sheadatk2:
cmp   ax, S_SARG_ATK2
jne   default_no_sfx
mov   al, SFX_SGTATK
jmp   selected_sfx



selected_sfx:
mov   dl, al


;call  S_StartSound_
db    09Ah
dw    S_STARTSOUNDAX0FAROFFSET, PHYSICS_HIGHCODE_SEGMENT

cmp   byte ptr ds:[_castframes], 0Ch
je    do_attack_frame
jump_to_finished_attack_frame_switch_check:
jmp   finished_attack_frame_switch_check
do_attack_frame:
mov   byte ptr ds:[_castattacking], 1
cmp   byte ptr ds:[_castonmelee], 0
jne   get_melee_state
mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah

db    09Ah
dw    GETMISSILESTATEADDR, PHYSICS_HIGHCODE_SEGMENT

got_state:
mov   dx, ax
SHIFT_MACRO shl ax 2
sub   ax, dx
add   ax, ax
mov   word ptr ds:[_caststate], ax
xor   byte ptr ds:[_castonmelee], 1

mov   dx, word ptr ds:[_caststate]   ; check if state 0
test  dx, dx
jne   jump_to_finished_attack_frame_switch_check
cmp   byte ptr ds:[_castonmelee], 0
je    non_melee_second_state
mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETMELEESTATEADDR, PHYSICS_HIGHCODE_SEGMENT
mov   dx, ax
SHIFT_MACRO shl ax 2
sub   ax, dx
add   ax, ax

jmp   done_with_attack_frame_switch
get_melee_state:
mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETMELEESTATEADDR, PHYSICS_HIGHCODE_SEGMENT
jmp   got_state
non_melee_second_state:
mov   al, byte ptr ds:[_castnum]
cbw  
mov   bx, ax
add   bx, ax
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
xor   ah, ah
db    09Ah
dw    GETMISSILESTATEADDR, PHYSICS_HIGHCODE_SEGMENT

mov   dx, ax
SHIFT_MACRO shl ax 2
sub   ax, dx
add   ax, ax

jmp   done_with_attack_frame_switch

ENDP

PROC   F_CastResponder_ NEAR
PUBLIC F_CastResponder_



push  bx
xchg  ax, bx
mov   es, dx
xor   ax, ax
cmp   byte ptr es:[bx + EVENT_T.event_evtype], al
jne   exit_fresponder_return0
cmp   byte ptr ds:[_castdeath], al
je    do_castdeath
exit_fresponder_return1:
stc
pop   bx
ret   
exit_fresponder_return0:
clc
pop   bx
ret   
do_castdeath:
mov   al, byte ptr ds:[_castnum]  ; ah already 0 from sor
mov   bx, ax
shl   bx, 1
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
mov   byte ptr ds:[_castdeath], 1
db    09Ah
dw    GETDEATHSTATEADDR, PHYSICS_HIGHCODE_SEGMENT

mov   bx, ax
SHIFT_MACRO shl bx 2
sub   bx, ax
shl   bx, 1 
mov   word ptr ds:[_caststate], bx
mov   ax, STATES_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx + STATE_T.state_tics]
mov   byte ptr ds:[_casttics], al
xor   ax, ax
mov   byte ptr ds:[_castframes], al
mov   byte ptr ds:[_castattacking], al
mov   al, byte ptr ds:[_castnum]
mov   bx, ax
shl   bx, 1
mov   al, byte ptr cs:[bx + OFFSET _CSDATA_castorder+1]
mov   ah, 0Bh  ; sizeof mobjinfo? todo constant
mul   ah
xchg  ax, bx

mov   dl, byte ptr ds:[bx + _mobjinfo + MOBJINFO_T.mobjinfo_deathsound]

;call  S_StartSound_
db    09Ah
dw    S_STARTSOUNDAX0FAROFFSET, PHYSICS_HIGHCODE_SEGMENT
jmp   exit_fresponder_return1





ENDP

TEXTWAIT = 250


PROC   F_Ticker_ FAR
PUBLIC F_Ticker_


PUSHA_NO_AX_OR_BP_MACRO
mov   ax, 50  ; 50 low 0 hi


cmp   byte ptr ds:[_commercial], ah ; 0
je    done_checking_skipping
cmp   word ptr ds:[_finalecount], ax ; 50
jle   done_checking_skipping
cmp   byte ptr ds:[_player + PLAYER_T.player_cmd_buttons], ah ; 0
je    done_checking_skipping
cmp   byte ptr ds:[_gamemap], 30
jne   do_worlddone
cmp   byte ptr ds:[_finalestage], FINALE_STAGE_CAST
je    done_checking_skipping
call  F_StartCast_
done_checking_skipping:
inc   word ptr ds:[_finalecount]
cmp   byte ptr ds:[_finalestage], FINALE_STAGE_CAST
je    call_fcastticker
cmp   byte ptr ds:[_commercial], 0
je    do_noncommerical
exit_fticker:

POPA_NO_AX_OR_BP_MACRO
retf  
do_worlddone:
mov   byte ptr ds:[_gameaction], GA_WORLDDONE
jmp   done_checking_skipping
call_fcastticker:
call  F_CastTicker_
jmp   exit_fticker
do_noncommerical:
mov   bx, SEGMENT_4000_OFFSET
mov   ax, word ptr ds:[_finaletext]
mov   cx, ds
call  dword ptr ds:[_getStringByIndex_addr]
cmp   byte ptr ds:[_finalestage], FINALE_STAGE_TEXT
jne   exit_fticker
mov   ax, SEGMENT_4000_OFFSET
mov   dx, ds

call  F_locallib_strlen_

mov   dx, ax
SHIFT_MACRO shl ax 2
sub   ax, dx
add   ax, TEXTWAIT
cmp   ax, word ptr ds:[_finalecount]
jge   exit_fticker
mov   byte ptr ds:[_finalestage], FINALE_STAGE_BUNNY
xor   ax, ax
mov   byte ptr ds:[_wipegamestate], 0FFh
mov   word ptr ds:[_finalecount], ax ; 0
cmp   byte ptr ds:[_gameepisode], 3
jne   exit_fticker
mov   al, MUS_BUNNY  ; ah already 0
;call  S_StartMusic_
mov   word ptr ds:[_pendingmusicenum], ax
;mov   byte ptr ds:[_pendingmusicenumlooping], 0



POPA_NO_AX_OR_BP_MACRO
retf  


ENDP



PROC   F_Responder_ FAR
PUBLIC F_Responder_
; return al = 1 as carry on

cmp  byte ptr ds:[_finalestage], FINALE_STAGE_CAST
je   call_castresponder
clc
retf 
call_castresponder:
call F_CastResponder_   ; todo might as well inline
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

PROC   F_Drawer_ FAR
PUBLIC F_Drawer_


PUSHA_NO_AX_OR_BP_MACRO
mov   al, byte ptr ds:[_finalestage]
cmp   al, FINALE_STAGE_BUNNY ; 1
ja    call_castdrawer ; 2
jb    call_textwrite  ; 0
; 0
mov   bl, byte ptr ds:[_gameepisode]
xor   bh, bh
mov   ax, OFFSET _filename_argument
cmp   bl, 4
ja    exit_fdrawer
je    fdrawer_episode4
cmp   bl, 2
je    fdrawer_episode2
ja    fdrawer_episode3


fdrawer_episode1:



cmp   byte ptr ds:[_is_ultimate], 0
jne   do_ultimate_fullscreenpatch

mov   ax, OFFSET str_help2
do_finaledraw:
mov   dx, cs

call  dword ptr ds:[_V_DrawFullscreenPatch_addr]
exit_fdrawer:
POPA_NO_AX_OR_BP_MACRO
retf  

call_castdrawer:
call  F_CastDrawer_
jmp   exit_fdrawer
call_textwrite:
call  F_TextWrite_
jmp   exit_fdrawer

do_ultimate_fullscreenpatch:
mov   ax, OFFSET str_credit
jmp   do_finaledraw
fdrawer_episode2:
mov   ax, OFFSET str_victory2
jmp   do_finaledraw
fdrawer_episode3:
call  F_BunnyScroll_
jmp   exit_fdrawer
fdrawer_episode4:
mov   ax, OFFSET str_endpic
jmp   do_finaledraw

ENDP

PROC   F_locallib_strlen_ NEAR
PUBLIC F_locallib_strlen_

push   di
push   cx

mov    es, dx
xchg   ax, di
xor    ax, ax
mov    cx, 0FFFFh
repne  scasb
; ax is 0
dec    ax ; 0FFFh
sub    ax, cx

pop    cx
pop    di
ret

ENDP

PROC   F_locallib_toupper_ NEAR
PUBLIC F_locallib_toupper_

cmp   al, 061h
jb    exit_m_to_upper
cmp   al, 07Ah
ja    exit_m_to_upper
sub   al, 020h
exit_m_to_upper:
ret

ENDP




PROC   Z_QuickMapScratch_5000_FinaleLocal_ NEAR
PUBLIC Z_QuickMapScratch_5000_FinaleLocal_

push  dx
push  cx
push  si

Z_QUICKMAPAI4 pageswapargs_scratch5000_offset_size INDEXED_PAGE_5000_OFFSET

pop   si
pop   cx
pop   dx
ret  

ENDP


PROC   F_MarkRect_ NEAR
PUBLIC F_MarkRect_


;    M_AddToBox16 (dirtybox, x, y); 
;    M_AddToBox16 (dirtybox, x+width-1, y+height-1); 

push      di

mov       di, OFFSET _dirtybox

add       cx, dx   
dec       cx      ; y + height - 1
add       bx, ax
dec       bx      ; x + width - 1

push      bx
call      F_AddToBox16_
pop       ax  ; restore bx
mov       dx, cx
call      F_AddToBox16_


pop       di
ret      


ENDP

;void __near M_AddToBox16 ( int16_t	x, int16_t	y, int16_t __near*	box  );

PROC    F_AddToBox16_ NEAR
PUBLIC  F_AddToBox16_

mov   bx, (2 * BOXLEFT)
cmp   ax, word ptr ds:[di + bx]
jl    write_x_to_left
mov   bl, (2 * BOXRIGHT)
cmp   ax, word ptr ds:[di + bx]
jle   do_y_compare
write_x_to_left:
mov   word ptr ds:[di + bx], ax
do_y_compare:
xchg  ax, dx
mov   bl, 2 * BOXBOTTOM
cmp   ax, word ptr ds:[di + bx]
jl    write_y_to_bottom
mov   bl, 2 * BOXTOP
cmp   ax, word ptr ds:[di + bx]
jng   exit_m_addtobox16
write_y_to_bottom:
mov   word ptr ds:[di + bx], ax
exit_m_addtobox16:
ret   


ENDP


PROC   F_DrawPatch_ NEAR
PUBLIC F_DrawPatch_

; ax is x
; dl is y
; bl is screen (always 0)
; cx is patch offset
; es is patch segment

 cmp   byte ptr ds:[_skipdirectdraws], 0
 jne   exit_early

push  si 
push  di 

; bx = 2*ax for word lookup
mov   di, cx
mov   cx, es   
mov   es, word ptr ds:[_screen_segments]   ;todo move to cs.
mov   ds, cx    ; ds:di is seg

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch

; ds:di is patch
mov   word ptr cs:[_SELFMODIFY_add_patch_offset+2], di
sub   dx, word ptr ds:[di + PATCH_T.patch_topoffset]


; calculate x + (y * screenwidth)


IF COMPISA GE COMPILE_186

    imul  si, dx , SCREENWIDTH
    add   si, ax

ELSE
    xchg  ax, si  ; si gets x
    mov   al, SCREENWIDTH / 2
    mul   dl
    sal   ax, 1
    xchg  ax, si  ; si gets x
    add   si, ax


ENDIF

; ax, dx maintained for markrect

sub   si, word ptr ds:[di + PATCH_T.patch_leftoffset]
mov   word ptr cs:[_SELFMODIFY_offset_add_di + 2], si

; always screen 0, always mark rect


push  ds
push  es 	; restore previously looked up segment.


les   bx, dword ptr ds:[di + PATCH_T.patch_width] 
mov   cx, es    ; height


push  ss
pop   ds
call  F_MarkRect_
pop   es
pop   ds




;    w = (patch->width); 
mov   cx, word ptr ds:[di + PATCH_T.patch_width]  ; count
lea   bx, [di + PATCH_T.patch_columnofs]          ; set up columnofs ptr
mov   dx, SCREENWIDTH - 1                         ; loop constant

draw_next_column:
push  cx            ; store patch width for outer loop iter
xor   cx, cx        ; clear ch specifically


; es:di is screen pixel target

mov   si, word ptr ds:[bx]           ; ds:bx is current patch col offset to draw

_SELFMODIFY_add_patch_offset:
add   si, 01000h

lodsw
;		while (column->topdelta != 0xff )  

cmp  al, 0FFh               ; al topdelta, ah length
je   column_done

draw_next_patch_column:

; here we render the next patch in the column.

xchg  cl, ah          ; cx is now col length, ah is now 0
inc   si      


IF COMPISA GE COMPILE_186
imul   di, ax, SCREENWIDTH   ; ax has topdelta.

ELSE
; cant fit screenwidth in 1 byte but we can do this...
mov   ah, SCREENWIDTH / 2
mul   ah
sal   ax, 1
xchg  ax, di
ENDIF



_SELFMODIFY_offset_add_di:
add   di, 01000h   ; retrieve offset

; todo lazy len 8 or 16 unrolle dloop


draw_next_patch_pixel:

movsb
add   di, dx
loop  draw_next_patch_pixel 

check_for_next_column:

inc   si
lodsw
cmp   al, 0FFh
jne   draw_next_patch_column

column_done:
add   bx, 4
inc   word ptr cs:[_SELFMODIFY_offset_add_di + 2]   ; pixel offset increments each column
pop   cx
loop  draw_next_column

done_drawing:
push  ss
pop   ds
pop   di
pop   si
exit_early:
ret


ENDP



PROC F_FINALE_ENDMARKER_ NEAR
PUBLIC F_FINALE_ENDMARKER_
ENDP

ENDS

END
