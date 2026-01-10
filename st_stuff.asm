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
INCLUDE sound.inc
INCLUDE strings.inc
INSTRUCTION_SET_MACRO



ASCII_0 = 030h
ASCII_1 = 031h

ST_HEIGHT =	32
ST_WIDTH =	SCREENWIDTH
ST_Y =		(SCREENHEIGHT - ST_HEIGHT)


EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapStatus_:FAR
EXTRN I_SetPalette_:FAR
EXTRN V_MarkRect_:FAR
EXTRN V_DrawPatch_:FAR
EXTRN cht_CheckCheat_:NEAR
EXTRN cht_GetParam_:NEAR

.DATA











.CODE



PROC    ST_STUFF_STARTMARKER_ NEAR
PUBLIC  ST_STUFF_STARTMARKER_
ENDP


; various st vars



_st_facecount:
dw 0
_st_calc_lastcalc:
dw 0
_st_calc_oldhealth:
dw 0
_st_oldhealth:
dw 0
_st_faceindex:
dw 0

_shortnum:
dw 10 DUP(0)
_tallnum:
dw 10 DUP(0)
_arms:
dw 12 DUP(0)
_tallpercent:
dw 0
_sbar:
dw 0
_faceback:
dw 0
_armsbg:
dw 0
_armsbgarray:
dw 0
_faces:
dw ST_NUMFACES DUP(0)
_keys:
dw NUMCARDS DUP(0)

; even number of bytes for word alignment. matches order of stosw in init..
_updatedthisframe:
db 0
_oldweaponsowned:
db NUMWEAPONS DUP(0)
_keyboxes:
dw 3 DUP(0)

_w_ready:
 ST_NUMBER_T ?
_w_health:
 ST_PERCENT_T ?
_w_armsbg:
 ST_MULTICON_T ?
_w_arms:
 ST_MULTICON_T 6 DUP (?)
_w_faces:
 ST_MULTICON_T ?
_w_armor:
 ST_PERCENT_T ?
_w_keyboxes:
 ST_MULTICON_T 3 DUP (?)
_w_ammo:
 ST_NUMBER_T 4 DUP (?)
_w_maxammo:
 ST_NUMBER_T 4 DUP (?)

_w_end:
dw (OFFSET _w_end - OFFSET _w_ready) / 2




_st_face_priority:
db 0
_st_face_lastattackdown:
db 0
_st_randomnumber:
db 0
_st_palette:
db 0
_do_st_refresh:
db 0
_st_statusbaron:
db 0
_st_stopped:
db 0





PUBLIC _st_palette
PUBLIC _st_oldhealth
PUBLIC _st_faceindex
PUBLIC _oldweaponsowned
PUBLIC _st_stopped
PUBLIC _tallpercent
PUBLIC _armsbgarray
PUBLIC _arms
PUBLIC _armsbg
PUBLIC _faces
PUBLIC _keys
PUBLIC _keyboxes
PUBLIC _shortnum
PUBLIC _tallnum
PUBLIC _faceback
PUBLIC _sbar
PUBLIC _st_statusbaron

PUBLIC _w_ready
PUBLIC _w_health
PUBLIC _w_armsbg
PUBLIC _w_arms
PUBLIC _w_faces
PUBLIC _w_armor
PUBLIC _w_keyboxes
PUBLIC _w_ammo
PUBLIC _w_maxammo
PUBLIC _w_end


PROC    ST_refreshBackground_ NEAR
PUBLIC  ST_refreshBackground_



push  bx
push  cx
push  dx
xor   ax, ax
cmp   byte ptr cs:[_st_statusbaron], al
je    exit_st_refresh_background


mov   dx, ST_GRAPHICS_SEGMENT
push  dx
mov   bx, 4
push  word ptr cs:[_sbar]
; ax already 0
cwd
mov   cx, ST_HEIGHT
call  V_DrawPatch_

mov   bx, SCREENWIDTH
mov   dx, ST_Y
xor   ax, ax
call  V_MarkRect_

mov   cx, ST_HEIGHT
mov   bx, SCREENWIDTH
mov   dx, ST_Y * SCREENWIDTH ;0D200h
xor   ax, ax

db    09Ah
dw    V_COPYRECT_OFFSET, PHYSICS_HIGHCODE_SEGMENT



exit_st_refresh_background:
pop   dx
pop   cx
pop   bx
ret   

ENDP





PROC    ST_calcPainOffset_ NEAR
PUBLIC  ST_calcPainOffset_

push  dx
mov   ax, word ptr ds:[_player + PLAYER_T.player_health]

;    health = player.health > 100 ? 100 : player.health;

cmp   ax, 100
jle   use_current_health
more_than_100_health:
mov   ax, 100
use_current_health:
cmp   ax, word ptr cs:[_st_calc_oldhealth]
je    old_health_100

;  st_calc_lastcalc = ST_FACESTRIDE * (((100 - health) * ST_NUMPAINFACES) / 101);
mov   word ptr cs:[_st_calc_oldhealth], ax

neg   ax
add   ax, 100  ; 100 - health

mov   ah, ST_NUMPAINFACES ; 5
mul   ah
mov   dl, 101
div   dl
cbw   ; clear remainder.
SHIFT_MACRO shl   ax 3 ; * 8   ; ST_FACESTRIDE 
mov   word ptr cs:[_st_calc_lastcalc], ax
old_health_100:

mov   ax, word ptr cs:[_st_calc_lastcalc]
pop   dx
ret   



ENDP




PROC    ST_updateFaceWidget_ NEAR
PUBLIC  ST_updateFaceWidget_


PUSHA_NO_AX_OR_BP_MACRO
xor   ax, ax
cwd
mov   bx, ax
mov   cx, ax
mov   cl, byte ptr cs:[_st_face_priority]
cmp   cl, 10
jge   not_face_10
cmp   word ptr ds:[_player + PLAYER_T.player_health], ax ; 0
jne   not_face_10
mov   cl, 9

mov   al, ST_DEADFACE
jmp   set_facecount_1_and_face_priority_dec_facecount_and_exit

not_face_10:
cmp   cl, 9
jge   not_face_9
cmp   byte ptr ds:[_player + PLAYER_T.player_bonuscount], al ; 0
je    not_face_9

; bx/dx known zero

loop_next_wepowned_face:


mov   al, byte ptr cs:[bx + _oldweaponsowned]
cmp   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
je    not_weapon_change
mov   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
inc   dx  ; do evil grin
mov   byte ptr cs:[bx + _oldweaponsowned], al
not_weapon_change:
inc   bx
cmp   bl, NUMWEAPONS
jl    loop_next_wepowned_face

test  dx, dx
je    not_face_9
mov   cl, 8

mov   word ptr cs:[_st_facecount], ST_EVILGRINCOUNT
call  ST_calcPainOffset_
add   al, ST_EVILGRINOFFSET
jmp   set_face_priority_dec_facecount_and_exit



not_face_9:
xor   ax, ax
cmp   cl, 8
jge   not_face_8

cmp   word ptr ds:[_player + PLAYER_T.player_damagecount], ax ; 0
je    not_face_8
mov   bx, word ptr ds:[_player + PLAYER_T.player_attackerRef]
test  bx, bx
je    not_face_8
cmp   bx, word ptr ds:[_playerMobjRef]
je    not_face_8

mov   ax, word ptr ds:[_player + PLAYER_T.player_health]
sub   ax, word ptr cs:[_st_oldhealth]
mov   cl, 7

cmp   ax, ST_MUCHPAIN
jg    dont_look_at_attacker
jmp   look_at_attacker
dont_look_at_attacker:
mov   word ptr cs:[_st_facecount], ST_TURNCOUNT
call  ST_calcPainOffset_
add   al, ST_OUCHOFFSET
jmp   set_face_priority_dec_facecount_and_exit



not_face_8:
cmp   cl, 7
jge   not_face_7
cmp   word ptr ds:[_player + PLAYER_T.player_damagecount], ax
je    not_face_7
mov   ax, word ptr ds:[_player + PLAYER_T.player_health]
sub   ax, word ptr cs:[_st_oldhealth]
mov   word ptr cs:[_st_facecount], ST_TURNCOUNT
cmp   ax, ST_MUCHPAIN
jg    more_pain
mov   cl, 6

call  ST_calcPainOffset_
add   al, ST_RAMPAGEOFFSET
jmp   set_face_priority_dec_facecount_and_exit

more_pain:

mov   cl, 7
call  ST_calcPainOffset_
add   al, ST_OUCHOFFSET
jmp   set_face_priority_dec_facecount_and_exit

not_face_7:

cmp   cl, 6
jge   not_face_6
cmp   byte ptr ds:[_player + PLAYER_T.player_attackdown], al ; 0
jne   attack_down
mov   byte ptr cs:[_st_face_lastattackdown], -1
jmp   not_face_6
attack_down:
cmp   byte ptr cs:[_st_face_lastattackdown], -1
je    add_rampage_delay
dec   byte ptr cs:[_st_face_lastattackdown]
jne   not_face_6
mov   cl, 5

call  ST_calcPainOffset_
add   al, ST_RAMPAGEOFFSET
mov   byte ptr cs:[_st_face_lastattackdown], 1
jmp   set_facecount_1_and_face_priority_dec_facecount_and_exit



add_rampage_delay:
mov   byte ptr cs:[_st_face_lastattackdown], ST_RAMPAGEDELAY
not_face_6:

cmp   cl, 5

jge   not_face_5
test  byte ptr ds:[_player + PLAYER_T.player_cheats], CF_GODMODE
jne   handle_invuln
cmp   word ptr ds:[_player + PLAYER_T.player_powers + 2 * PW_INVULNERABILITY], ax ; 0
jne   handle_invuln

not_face_5:
cmp   word ptr cs:[_st_facecount], ax ; 0
jne   dec_facecount_and_exit

mov   al, byte ptr cs:[_st_randomnumber]
mov   bl, 3
div   bl
mov   dl, ah ; store mod
call  ST_calcPainOffset_
mov   word ptr cs:[_st_facecount], ST_STRAIGHTFACECOUNT
add   al, dl ; rand mod 3
xor   cx, cx
jmp   set_face_priority_dec_facecount_and_exit


handle_invuln:
mov   cl, 4
mov   al, ST_GODFACE

set_facecount_1_and_face_priority_dec_facecount_and_exit:
mov   word ptr cs:[_st_facecount], 1

set_face_priority_dec_facecount_and_exit:
mov   byte ptr cs:[_st_face_priority], cl

write_face_index_and_finish_face_checks:
mov   byte ptr cs:[_st_faceindex], al

dec_facecount_and_exit:
dec   word ptr cs:[_st_facecount]
exit_updatefacewidget:
POPA_NO_AX_OR_BP_MACRO
ret   


look_at_attacker:
mov   byte ptr cs:[_st_face_priority], cl
mov   ax, (SIZE MOBJ_POS_T)
mul   word ptr ds:[_player + PLAYER_T.player_attackerRef]
xchg  ax, di
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax

;   badguyangle.wu = R_PointToAngle2(playerMobj_pos->x,
;       playerMobj_pos->y,
;       plyrattacker_pos->x,
;       plyrattacker_pos->y);
                
push  word ptr es:[di + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[di + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[di + MOBJ_POS_T.mp_x + 2]
push  word ptr es:[di + MOBJ_POS_T.mp_x + 0]

les   si, dword ptr ds:[_playerMobj_pos]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
les   ax, dword ptr es:[si + MOBJ_POS_T.mp_x + 0]
mov   dx, es


;call  R_PointToAngle2_
; TODO! call high
db    09Ah
dw    R_POINTTOANGLE2_OFFSET, PHYSICS_HIGHCODE_SEGMENT


xor   bx, bx ; zero bx...
les   si, dword ptr ds:[_playerMobj_pos]
cmp   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
ja    angle_larger
jne   angle_smaller
cmp   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
jbe   angle_smaller
angle_larger:
sub   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
sbb   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
cmp   dx, ANG180_HIGHBITS
ja    set_i_1
jne   set_i_0
test  ax, ax
jbe   set_i_0
set_i_1:
inc   bx
set_i_0:
angle_and_i_set:
mov   word ptr cs:[_st_facecount], ST_OUCHCOUNT
call  ST_calcPainOffset_
cmp   dx, ANG45_HIGHBITS
jae   do_side_look
; head on
add   al, ST_RAMPAGEOFFSET
jmp   write_face_index_and_finish_face_checks
angle_smaller:
neg   dx
neg   ax
sbb   dx, 0
add   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 0]
adc   dx, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
cmp   dx, ANG180_HIGHBITS
jb    set_i_1
jne   set_i_0
test  ax, ax
jbe   set_i_1
jmp   set_i_0

do_side_look:
add   al, bl ; 1 or 0 for left or right.
add   al, ST_TURNOFFSET ; 3, so 3 or 4..
jmp   write_face_index_and_finish_face_checks

ENDP


PROC    ST_updateWidgets_ NEAR
PUBLIC  ST_updateWidgets_

push  di
push  si

push  cs
pop   es
mov   si, OFFSET _player + PLAYER_T.player_cards
mov   di, OFFSET _keyboxes

do_next_cardcolor:
lodsb
;        keyboxes[i] = player.cards[i] ? i : -1;
test  al, al
lea   ax, [si - 1 - (_player + PLAYER_T.player_cards)]
jnz   dont_set_minus_one
mov   ax, -1
dont_set_minus_one:


;        if (player.cards[i + 3])
;            keyboxes[i] = i + 3;


cmp   byte ptr ds:[si+2],0 ;si has already been incremented.
je    dont_set_iplus3
lea   ax, [si + 2 - (_player + PLAYER_T.player_cards)]
dont_set_iplus3:
stosw
cmp   si, (OFFSET _player + PLAYER_T.player_cards + 3)
jl    do_next_cardcolor


call  ST_updateFaceWidget_
pop   si
pop   di
ret   

ENDP


ENDP

PROC    ST_Ticker_ NEAR
PUBLIC  ST_Ticker_

;call  M_Random_
; inline

mov      ax, RNDTABLE_SEGMENT
mov      es, ax
inc      byte ptr ds:[_rndindex]
mov      al, byte ptr ds:[_rndindex]
xor      ah, ah
xchg     ax, bx
mov      bl, byte ptr es:[bx]
xchg     ax, bx

mov   byte ptr cs:[_st_randomnumber], al
call  ST_updateWidgets_
mov   ax, word ptr ds:[_player + PLAYER_T.player_health]
mov   word ptr cs:[_st_oldhealth], ax
ret   

ENDP

NUMREDPALS = 8
NUMBONUSPALS = 3
STARTBONUSPALS = 9
RADIATIONPAL = 13

PROC    ST_doPaletteStuff_ NEAR
PUBLIC  ST_doPaletteStuff_

push  dx
mov   ax, word ptr ds:[_player + PLAYER_T.player_damagecount]
mov   dx, word ptr ds:[_player + PLAYER_T.player_powers + (2 * PW_STRENGTH)]
test  dx, dx
je    done_with_berz_check
; fade berserk out
SHIFT_MACRO shr   dx 6
neg   dx
add   dx, 12
cmp   dx, ax
jle   done_with_berz_check
xchg  ax, dx
done_with_berz_check:
test  ax, ax
je    no_red_fadeout
add   ax, 7
SHIFT_MACRO sar   ax 3
cmp   al, NUMREDPALS
jl    dont_cap_redpedals
mov   al, 7
dont_cap_redpedals:
inc   al
jmp   check_set_palette_and_exit

no_red_fadeout:

mov   al, byte ptr ds:[_player + PLAYER_T.player_bonuscount]
test  al, al
je    no_bonus
cbw  
add   ax, 7
SHIFT_MACRO sar   ax, 3
cmp   al, NUMBONUSPALS
jle   dont_cap_bonuspals
mov   al, NUMBONUSPALS
dont_cap_bonuspals:
add   al, STARTBONUSPALS
jmp   check_set_palette_and_exit

no_bonus:

cmp   word ptr ds:[_player + PLAYER_T.player_powers + (2 * PW_IRONFEET)], 128
jle   check_mod_8_tic
set_rad_pal:
mov   al, RADIATIONPAL
jmp   check_set_palette_and_exit
check_mod_8_tic:
test  byte ptr ds:[_player + PLAYER_T.player_powers + (2 * PW_IRONFEET)], 8
jne   set_rad_pal

check_set_palette_and_exit:
cmp   al, byte ptr cs:[_st_palette]
je    dont_set_palette_and_exit
set_palette_and_exit:
mov   byte ptr cs:[_st_palette], al
cbw  
call  I_SetPalette_
dont_set_palette_and_exit:
pop   dx
ret   

ENDP


PROC    STlib_updateflag_ NEAR
PUBLIC  STlib_updateflag_

cmp   byte ptr cs:[_updatedthisframe], 0
jne   exit_updateflag
call  Z_QuickMapStatus_
inc   byte ptr cs:[_updatedthisframe]
exit_updateflag:
ret   


ENDP
;void __near STlib_updateMultIcon ( st_multicon_t __near* mi, int16_t inum, boolean        is_binicon) {

; 


PROC    STlib_updateMultIcon_ NEAR
PUBLIC  STlib_updateMultIcon_

cmp   dx, -1
je    exit_updatemulticon_no_pop  ; test once.
PUSHA_NO_AX_OR_BP_MACRO
xchg  ax, si
mov   cx, word ptr cs:[si + ST_MULTICON_T.st_multicon_oldinum]
cmp   cx, dx
jne   do_draw
cmp   byte ptr cs:[_do_st_refresh], 0
jne   do_draw
exit_updatemulticon:
POPA_NO_AX_OR_BP_MACRO
exit_updatemulticon_no_pop:
exit_stlib_drawnum_no_pop:
ret   

do_draw:
call  STlib_updateflag_

mov   word ptr cs:[si + ST_MULTICON_T.st_multicon_oldinum], dx ; update oldinum, dont need dx anymore
sub   dx, bx   ; calculate  "inum-is_binicon" lookup
sal   dx, 1
push  dx       ; store inum-is_binicon lookup

cmp   cx, -1                ; mi->oldinum != -1
je    skip_rect
test  bl, bl                ; !is_binicon
jne   skip_rect

les   ax, dword ptr cs:[si + ST_MULTICON_T.st_multicon_x]
mov   dx, es  ; st_multicon_y

mov   di, ST_GRAPHICS_SEGMENT   ; todo load from mem?
mov   es, di

mov   di, word ptr  cs:[si + ST_MULTICON_T.st_multicon_patch_offset] ; mi->patch_offset

sal   cx, 1     ; word lookup
add   di, cx    ; mi->patch_offset[mi->oldinum]
mov   di, word ptr  cs:[di] ; es:di is patch


sub   ax, word ptr es:[di + PATCH_T.patch_leftoffset]
sub   dx, word ptr es:[di + PATCH_T.patch_topoffset]

;  offset = x+y*SCREENWIDTH;

IF COMPISA GE COMPILE_186
    
    imul  cx, dx, SCREENWIDTH
    add   cx, ax
    push  cx                    ; offset on stack
    sub   cx, ST_Y * SCREENWIDTH ; 0D200
    push  cx        ; offset - d200 on stack

ELSE

    push  ax
    push  dx
    
    mov   ax, SCREENWIDTH
    mul   dx
    pop   dx
    pop   cx
    add   ax, cx
    push  ax        ; offset on stack
    sub   ax, ST_Y * SCREENWIDTH ; 0D200
    push  ax        ; offset - d200 on stack
    xchg  ax, cx


ENDIF


les   bx, dword ptr es:[di + PATCH_T.patch_width]
mov   cx, es  ;  height

push  cx
push  bx  ; for the next call..

call  V_MarkRect_

pop   bx    ; width
pop   cx    ; height
pop   ax    ; offset minus stuff
pop   dx    ; offset

db    09Ah
dw    V_COPYRECT_OFFSET, PHYSICS_HIGHCODE_SEGMENT

skip_rect:

lods  word ptr cs:[si]           ; x
xchg  ax, bx                     ; bx holds x
lods  word ptr cs:[si]           ; y
xchg  ax, dx                     ; dx gets y
lods  word ptr cs:[si]           ; oldinum (dontuse)
lods  word ptr cs:[si]           ; patch_offset
pop   si                         ;   get inum-is_binicon lookup
add   si, ax                     ; patch_offset[0] + inum-is_binicon lookup


mov   ax, ST_GRAPHICS_SEGMENT
push  ax
push  word ptr cs:[si]

xor   ax, ax
xchg  ax, bx    ; ax gets x. bx gets FG == 0


call  V_DrawPatch_
jmp   exit_updatemulticon



ENDP



PROC    STlib_drawNum_ NEAR
PUBLIC  STlib_drawNum_


PUSHA_NO_AX_OR_BP_MACRO
xchg  ax, si
mov   cx, word ptr cs:[si + ST_NUMBER_T.st_number_oldnum]
cmp   cx, dx
jne   drawnum
cmp   byte ptr cs:[_do_st_refresh], 0
jne   drawnum
POPA_NO_AX_OR_BP_MACRO
ret

drawnum:

call  STlib_updateflag_

;	p0 = (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, number->patch_offset[0]));
mov   ax, ST_GRAPHICS_SEGMENT
mov   es, ax
mov   di, word ptr cs:[si + ST_NUMBER_T.st_number_patch_offset]
mov   di, word ptr cs:[di] ; offset 0
les   bx, dword ptr es:[di + PATCH_T.patch_width]

; bx has width, es has height for now

mov   word ptr cs:[si + ST_NUMBER_T.st_number_oldnum], dx
mov   ax,word ptr cs:[si + ST_NUMBER_T.st_number_width] ; numdigits



;    digitwidth = w * numdigits;
; bx has width, but its smaller than 256.
mul   bl
; digits * w in ax
;    x = number->x - digitwidth;
push  bx   ; push width (-2)
xchg  ax, bx  ; digitwidth in bx
mov   ax, word ptr cs:[si + ST_NUMBER_T.st_number_x]
sub   ax, bx

mov   di, dx ; back up num
mov   dx, word ptr cs:[si + ST_NUMBER_T.st_number_y]
mov   cx, es  ; h

push  bx    ; (use as is in bx later)
push  cx    ; (use as is in cx later)
push  ax    ; x
push  dx    ; number->y


call  V_MarkRect_

;    V_CopyRect (x + SCREENWIDTH*(number->y - ST_Y), x + SCREENWIDTH*number->y, digitwidth, h);

pop   cx    ; number->y
mov   bx, cx
sub   bx, ST_y
mov   ax, SCREENWIDTH
mul   bx
pop   bx        ; x
add   ax, bx ; + x
mov   es, ax ; backup
mov   ax, SCREENWIDTH
mul   cx
add   ax, bx ; + x
xchg  ax, dx
mov   ax, es
pop   cx ; restore these args
pop   bx ; restore these args
db    09Ah
dw    V_COPYRECT_OFFSET, PHYSICS_HIGHCODE_SEGMENT

pop   cx  ; get w

cmp   di, 1994
je    exit_stlib_drawnum

lods  word ptr cs:[si] ;  number->x
xchg  ax, bx
lods  word ptr cs:[si] ;  number->y
xchg  ax, dx
add   si, 4
lods  word ptr cs:[si] ;  number->patchoffset
xchg  ax, si
xchg  ax, bx ; get x back


; di has num
; cx has w
; ax has x
; dx has number-y
; si is patch offsets ptr 

test  di, di
je    draw_zero
; drawnonzero
; do draw loop
draw_nonzero:
sub   ax, cx
push  ax    ; store for postcall
push  dx    ; store for postcall

mov   bx, ST_GRAPHICS_SEGMENT
push  bx  ; func arc 1

xchg  ax, di
push  dx
cwd
mov   bx, 10  ; bh 0
div   bx
mov   bx, dx  ; bx gets digit.
xchg  ax, di  ; di gets result / 10. ax gets its value back
pop   dx  ; restore dx for call
sal   bx, 1   ; word lookup

push  word ptr cs:[si+bx]
xor   bx, bx ; FG

call  V_DrawPatch_

pop   dx
pop   ax
test  di, di
jnz   draw_nonzero

exit_stlib_drawnum:
POPA_NO_AX_OR_BP_MACRO
ret   


draw_zero:
; draw one zero
mov   bx, ST_GRAPHICS_SEGMENT
push  bx
xor   bx, bx
push  word ptr cs:[si] ; first offset is 0
sub   ax, cx
call  V_DrawPatch_
jmp   exit_stlib_drawnum
ENDP


PROC    STlib_updatePercent_ NEAR
PUBLIC  STlib_updatePercent_


cmp   byte ptr cs:[_do_st_refresh], 0
je    skip_percent

push  si
push  bx
push  dx ; store for 2nd call
push  ax

xchg  ax, si

call  STlib_updateflag_

;        V_DrawPatch(per->num.x, per->num.y, FG, (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, *(uint16_t __near*)(per->patch_offset))));


mov   ax, ST_GRAPHICS_SEGMENT
push  ax
les   ax, dword ptr cs:[si + ST_NUMBER_T.st_number_x]
mov   dx, es
mov   si, word ptr cs:[si + ST_PERCENT_T.st_percent_patch_offset]
push  word ptr cs:[si]
xor   bx, bx
call  V_DrawPatch_

pop   ax
pop   dx
pop   bx
pop   si

skip_percent:

call  STlib_drawNum_
exit_st_drawwidgets_no_pop:
ret   



ENDP


PROC    ST_drawWidgets_ NEAR
PUBLIC  ST_drawWidgets_

cmp   byte ptr cs:[_st_statusbaron], 0
je    exit_st_drawwidgets_no_pop
PUSHA_NO_AX_OR_BP_MACRO

xor   bx, bx
mov   cx, 4

mov   si, OFFSET _player + PLAYER_T.player_ammo


update_next_ammo:

;            STlib_drawNum(&w_ammo[i], player.ammo[i]);
;            STlib_drawNum(&w_maxammo[i], player.maxammo[i]);

lodsw
xchg  ax, dx
ASSUME DS:ST_STUFF_TEXT
lea   ax, [bx + OFFSET _w_ammo]
ASSUME DS:DGROUP
call  STlib_drawNum_

mov   dx, word ptr ds:[si - 2 + PLAYER_T.player_maxammo - PLAYER_T.player_ammo]
ASSUME DS:ST_STUFF_TEXT
lea   ax, [bx + OFFSET _w_maxammo]
ASSUME DS:DGROUP
call  STlib_drawNum_

add   bx, (SIZE ST_NUMBER_T)
loop  update_next_ammo

mov   al, (SIZE WEAPONINFO_T)
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx


mov   al, byte ptr ds:[bx + _weaponinfo]
cmp   al, AM_NOAMMO

mov   dx, 1994

je    do_noammo


cbw  
mov   bx, ax
sal   bx, 1
mov   dx, word ptr ds:[bx + _player + PLAYER_T.player_ammo]

do_noammo:

done_with_ammo:
mov   ax, OFFSET _w_ready
call  STlib_drawNum_

mov   ax, OFFSET _w_health
mov   dx, word ptr ds:[_player + PLAYER_T.player_health]
call  STlib_updatePercent_

mov   ax, OFFSET _w_armor
mov   dx, word ptr ds:[_player + PLAYER_T.player_armorpoints]
call  STlib_updatePercent_

mov   bx, 1  ; true
mov   dx, bx ; true
mov   ax, OFFSET _w_armsbg
call  STlib_updateMultIcon_

mov   cx, 6
mov   di, OFFSET _w_arms
mov   si, _player + PLAYER_T.player_weaponowned + 1

update_next_weapon:

;            STlib_updateMultIcon(&w_arms[i], player.weaponowned[i + 1], false);
lodsb
cbw
xchg  ax, dx
mov   ax, di
xor   bx, bx
call  STlib_updateMultIcon_
add   di, (SIZE ST_MULTICON_T)
loop  update_next_weapon

;        STlib_updateMultIcon(&w_faces, st_faceindex, false);

mov   ax, OFFSET _w_faces
mov   dx, word ptr cs:[_st_faceindex]
xor   bx, bx
call  STlib_updateMultIcon_

mov   di, OFFSET _w_keyboxes
mov   si, OFFSET _keyboxes
mov   cx, 3
;            STlib_updateMultIcon(&w_keyboxes[i], keyboxes[i], false);

update_next_keybox:
lods  word ptr cs:[si]
xchg  ax, dx
mov   ax, di
xor   bx, bx
call  STlib_updateMultIcon_
add   di, (SIZE ST_MULTICON_T)
loop  update_next_keybox

exit_st_drawwidgets:
exit_st_responder_early:
POPA_NO_AX_OR_BP_MACRO
ret   


ENDP


PROC    ST_Responder_ NEAR
PUBLIC  ST_Responder_


PUSHA_NO_AX_OR_BP_MACRO

xchg  ax, di
xor   ax, ax
mov   es, dx
mov   si, _player + PLAYER_T.player_cheats
cmp   byte ptr es:[di + EVENT_T.event_evtype], al ; EV_KEYDOWN
jne   exit_st_responder_early

push  bp
mov   bp, sp
sub   sp, 014h

cmp   byte ptr ds:[_gameskill], SK_NIGHTMARE
jne   not_nightmare
jmp   done_checking_main_cheats
not_nightmare:

mov   al, byte ptr es:[di + EVENT_T.event_data1]
cbw  
mov   cx, ax        ; cx holds event?
xchg  ax, dx
mov   al, CHEATID_GODMODE
call  cht_CheckCheat_
jnc   is_not_godmode

is_godmode:
xor   byte ptr ds:[si], CF_GODMODE
test  byte ptr ds:[si], CF_GODMODE
jne   turn_godmode_on

turn_godmode_off:
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_DQDOFF
jmp   check_behold_cheats

turn_godmode_on:
mov   bx, word ptr ds:[_playerMobj]
mov   word ptr ds:[bx + MOBJ_T.m_health], 100
mov   word ptr ds:[_player + PLAYER_T.player_health], 100
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_DQDON

jmp   check_behold_cheats

is_not_godmode:
mov   dx, cx ; data1
mov   al, CHEATID_AMMONOKEYS
call  cht_CheckCheat_
jc    do_ammo_no_keys

not_ammonokeys:
mov   dx, cx
mov   al, CHEATID_AMMOANDKEYS
call  cht_CheckCheat_
jnc   not_ammoandkeys

do_ammo_and_keys:

mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_KFAADDED
xor   bx, bx

loop_next_set_key:
mov   byte ptr ds:[bx + _player + PLAYER_T.player_cards], 1
inc   bx
cmp   bl, 6
jl    loop_next_set_key
jmp   do_ammo_part

do_ammo_no_keys:
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_FAADDED
do_ammo_part:
mov   word ptr ds:[_player + PLAYER_T.player_armorpoints], 200
mov   byte ptr ds:[_player + PLAYER_T.player_armortype], 2
xor   bx, bx
loop_next_set_weapon_owned:
mov   byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned], 1
inc   bx
cmp   bl, NUMWEAPONS
jl    loop_next_set_weapon_owned
xor   bx, bx

loop_next_set_max_ammo:
push  word ptr ds:[bx + _player + PLAYER_T.player_maxammo]
pop   word ptr ds:[bx + _player + PLAYER_T.player_ammo]
inc   bx
inc   bx
cmp   bl, (4 * 2)
jl    loop_next_set_max_ammo

jmp   check_behold_cheats


not_ammoandkeys:
mov   dx, cx
mov   al, CHEATID_MUSIC
call  cht_CheckCheat_
jnc    is_not_music

is_music:
lea   di, [bp - 0Ah]
mov   bx, (CHEATID_MUSIC)
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_MUS

call  cht_GetParam_
cmp   byte ptr ds:[_commercial], 0
mov   ax, word ptr [bp - 0Ah]
mov   bl, ah
je    noncommercial_music
sub   al, ASCII_0
mov   ah, 10
mul   ah
xchg  ax, bx
; al has bp - 9
sub   al, ASCII_0

add   al, bl  ; ax has digits added
mov   bx, ax
add   al, (MUS_RUNNIN - 1)
cmp   bl, 35
jle   music_id_ok

mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_NOMUS
jmp   check_behold_cheats
music_id_ok:
mov   ah, 1
;call  S_ChangeMusic_
mov   word ptr ds:[_pendingmusicenum], ax

jmp   check_behold_cheats

noncommercial_music:

sub   al, ASCII_1
mov   ah, 9
mul   ah
xchg  ax, bx
; al has bp - 9
sub   al, ASCII_1

add   al, bl
cmp   al, 31
jle   music_id_ok
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_NOMUS
jmp   check_behold_cheats


is_not_music:
cmp   byte ptr ds:[_commercial], 0
jne   notclip_doom1_commercial_set

mov   dx, cx
mov   al, CHEATID_NOCLIP
call  cht_CheckCheat_

jnc   check_behold_cheats
do_clip_doom1_or_doom2:
xor   byte ptr ds:[si], CF_NOCLIP
test  byte ptr ds:[si], CF_NOCLIP
mov   ax, STSTR_NCOFF
je    turn_clipping_off
mov   ax, STSTR_NCON
turn_clipping_off:
mov   word ptr ds:[_player + PLAYER_T.player_message], ax
jmp   check_behold_cheats

notclip_doom1_commercial_set:
mov   dx, cx
mov   al, CHEATID_NOCLIPDOOM2
call  cht_CheckCheat_
jc    do_clip_doom1_or_doom2

; fall thru..

check_behold_cheats:

xor   bx, bx
mov   si, _player + PLAYER_T.player_powers

loop_next_behold_cheat:

; bx is cheat index times 2...

mov   dx, cx
mov   ax, bx  ; cheat index times two...
sal   ax, 1   ; four

call  cht_CheckCheat_
jnc   skip_this_behold

cmp   word ptr ds:[si + bx], 0  ; check powers
je    give_power

dont_give_power:
xor   ax, ax
cmp   bl, (PW_STRENGTH * 2)
jne   toggle_off_power
; do strength
inc   ax  ; write 1 instead of 0
jmp   toggle_off_power 

give_power:
mov   ax, bx
sar   ax, 1  

or   byte ptr ds:[_dodelayedcheatthisframe], CHECK_FOR_DELAYED_CHEAT

db    09Ah
dw    P_GIVEPOWEROFFSET, PHYSICS_HIGHCODE_SEGMENT

and   byte ptr ds:[_dodelayedcheatthisframe], (NOT CHECK_FOR_DELAYED_CHEAT)

jmp   done_applying_behold

toggle_off_power:
mov   word ptr ds:[si + bx], ax
done_applying_behold:
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_BEHOLDX


skip_this_behold:
inc   bx
inc   bx
cmp   bl, (NUMPOWERS * 2)
jl    loop_next_behold_cheat

; done with behold loop

mov   dx, cx
mov   al, CHEATID_BEHOLD
call  cht_CheckCheat_
jnc   not_single_behold
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_BEHOLD
jmp   done_checking_main_cheats
not_single_behold:


mov   dx, cx
mov   al, CHEATID_CHOPPERS
call  cht_CheckCheat_

jnc   not_choppers
mov   byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_CHAINSAW], 1
mov   word ptr ds:[_player + PLAYER_T.player_powers + 2 * PW_INVULNERABILITY], 1
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_CHOPPERS
jmp   done_checking_main_cheats

not_choppers:
mov   dx, cx
mov   al, CHEATID_MAPPOS
call  cht_CheckCheat_
jnc   done_checking_main_cheats

do_mappos_cheat:
; set flag for deferred calculation

or   byte ptr ds:[_dodelayedcheatthisframe], DO_DELAYED_MAP_CHEAT





done_checking_main_cheats:
mov   dx, cx
mov   al, CHEATID_CHANGE_LEVEL
call  cht_CheckCheat_
jc    do_change_level_cheat
exit_st_responder_return:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

do_change_level_cheat:

lea   di, [bp - 4]
mov   bx, (CHEATID_CHANGE_LEVEL)
call  cht_GetParam_


mov   cl, 4  ; max epsd

mov   ax, word ptr [bp - 4]

sub   ax, ((ASCII_0 SHL 8) + ASCII_0)  ; subtract '0' from both 
mov   bl, ah
cmp   byte ptr ds:[_commercial], 0
je    map_epsd_set

;    epsd = 0;
;    map = (buf[0] - '0')*10 + buf[1] - '0';

mov   ah, 10
mul   ah
add   al, bl
mov   ah, al
xor   al, al


map_epsd_set:

; al is epsd ah is map


cmp   byte ptr ds:[_is_ultimate], 0
je    dont_inc_max_epsd
inc   cx
dont_inc_max_epsd:

;    if ((!commercial && epsd > 0 && epsd < max_epsd && map > 0 && map < 10)
;        || (commercial && map > 0 && map <= 40)) {
;        // So be it.
;        player.message = STSTR_CLEV;
;        G_DeferedInitNew(gameskill, epsd, map);
;    }

cmp   byte ptr ds:[_commercial], 0
jne   first_check_fail
test  al, al
jle   exit_st_responder_return
cmp   al, cl
jge   exit_st_responder_return
test  ah, ah
jle   exit_st_responder_return
cmp   ah, 10
jl    checks_passed

first_check_fail:
; implied commercial is the other result
cmp   ah, 40
jg    exit_st_responder_return
checks_passed:

;void __far G_DeferedInitNew ( skill_t skill, int8_t episode, int8_t map) { 
;call  G_DeferedInitNew_

mov   word ptr ds:[_d_episode], ax
;mov   byte ptr ds:[_d_map], ah
mov   word ptr ds:[_player + PLAYER_T.player_message], STSTR_CLEV
mov   al, byte ptr ds:[_gameskill]
mov   byte ptr ds:[_d_skill], al
mov   byte ptr ds:[_gameaction], GA_NEWGAME

jmp   exit_st_responder_return



ENDP


PROC    ST_Drawer_ NEAR
PUBLIC  ST_Drawer_

dec   ax
neg   ax ; ! fullscreen
or    al, byte ptr ds:[_automapactive]
mov   byte ptr cs:[_st_statusbaron], al
call  ST_doPaletteStuff_
mov   ax, 0100h  ; ah = 1 al = 0

mov   byte ptr cs:[_updatedthisframe], al ; 0
or    byte ptr ds:[_st_firsttime], dl
je    not_first_time
first_time:
mov   byte ptr ds:[_st_firsttime], al ; 0
mov   byte ptr cs:[_updatedthisframe], ah ; 1
mov   byte ptr cs:[_do_st_refresh], ah ; 1

call  Z_QuickMapStatus_
call  ST_refreshBackground_
call  ST_drawWidgets_
jmp   do_quickmapphysics_and_exit

not_first_time:

mov   byte ptr cs:[_do_st_refresh], al ; 0
call  ST_drawWidgets_

cmp   byte ptr cs:[_updatedthisframe], 0
je    just_exit

do_quickmapphysics_and_exit:

call  Z_QuickMapPhysics_
just_exit:
ret   
ENDP

PROC    ST_STUFF_ENDMARKER_ NEAR
PUBLIC  ST_STUFF_ENDMARKER_
ENDP


ENDP

END