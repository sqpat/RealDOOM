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



ASCII_0 = 030h
ASCII_1 = 031h

ST_HEIGHT =	32
ST_WIDTH =	SCREENWIDTH
ST_Y =		(SCREENHEIGHT - ST_HEIGHT)


EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapStatus_:FAR
EXTRN I_SetPalette_:FAR
EXTRN V_CopyRect_:FAR
EXTRN V_MarkRect_:FAR
EXTRN V_DrawPatch_:FAR
EXTRN cht_CheckCheat_:NEAR
EXTRN cht_GetParam_:NEAR
EXTRN S_ChangeMusic_:FAR
EXTRN locallib_printhex_:NEAR
EXTRN G_DeferedInitNew_:FAR
EXTRN R_PointToAngle2_:FAR
EXTRN combine_strings_:NEAR
EXTRN M_Random_:FAR

.DATA

EXTRN _st_face_priority:BYTE
EXTRN _st_face_lastattackdown:BYTE
EXTRN _st_randomnumber:BYTE
EXTRN _updatedthisframe:BYTE
EXTRN _do_st_refresh:BYTE
EXTRN _st_facecount:WORD
EXTRN _st_calc_lastcalc:WORD
EXTRN _st_calc_oldhealth:WORD
EXTRN _P_GivePower:DWORD
EXTRN _st_stopped:BYTE
EXTRN _st_palette:BYTE
EXTRN _st_oldhealth:WORD
EXTRN _st_firsttime:BYTE
EXTRN _st_gamestate:BYTE
EXTRN _st_statusbaron:BYTE
EXTRN _st_faceindex:BYTE

EXTRN _tallpercent:BYTE

EXTRN _armsbgarray:BYTE

;todo move to cs
EXTRN _st_stuff_buf:BYTE
EXTRN _arms:BYTE
EXTRN _faces:BYTE
EXTRN _keys:BYTE
EXTRN _keyboxes:BYTE
EXTRN _oldweaponsowned:BYTE

EXTRN _w_ammo:BYTE
EXTRN _w_arms:BYTE
EXTRN _w_armsbg:BYTE
EXTRN _w_armor:BYTE
EXTRN _w_health:BYTE
EXTRN _w_faces:BYTE
EXTRN _w_keyboxes:BYTE
EXTRN _w_maxammo:BYTE
EXTRN _w_ready:BYTE
EXTRN _sbar:WORD


.CODE



PROC    ST_STUFF_STARTMARKER_ NEAR
PUBLIC  ST_STUFF_STARTMARKER_
ENDP


_st_mapcheat_string1:
db "ang=0x", 0
_st_mapcheat_string2:
db ";x,y=(0x", 0
_st_mapcheat_string3:
db ",0x", 0
_st_mapcheat_string4:
db ")", 0

PROC    ST_refreshBackground_ NEAR
PUBLIC  ST_refreshBackground_



push  bx
push  cx
push  dx
xor   ax, ax
cmp   byte ptr ds:[_st_statusbaron], al
je    exit_st_refresh_background


mov   dx, ST_GRAPHICS_SEGMENT
push  dx
mov   bx, 4
push  word ptr ds:[_sbar]
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
call  V_CopyRect_

exit_st_refresh_background:
pop   dx
pop   cx
pop   bx
ret   

ENDP

COMMENT @

PROC    ST_Responder_ NEAR
PUBLIC  ST_Responder_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 014h
mov   di, ax
mov   word ptr [bp - 2], dx
mov   es, dx
cmp   byte ptr es:[di], 0
je    label_1
jmp   exit_st_responder_ret_0
label_1:
mov   bx, _gameskill
cmp   byte ptr ds:[bx], 4
jne   label_3
jmp   label_2
label_3:
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_GODMODE
call  cht_CheckCheat_
test  al, al
jne   label_4
jmp   label_5
label_4:
mov   bx, _player + PLAYER_T.player_cheats
xor   byte ptr ds:[bx], 2
test  byte ptr ds:[bx], 2
jne   label_7
jmp   label_6
label_7:
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   word ptr ds:[bx + MOBJ_T.m_health], 100
mov   bx, _player + PLAYER_T.player_health
mov   word ptr ds:[bx], 100
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_DQDON
label_12:
xor   bl, bl
label_10:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   al, bl
cbw  
mov   cx, ax
shl   ax, 2
call  cht_CheckCheat_
test  al, al
je    label_8
mov   si, cx
add   si, si
cmp   word ptr ds:[si + _player + PLAYER_T.player_powers], 0
jne   jump_to_label_9
mov   ax, cx
call  dword ptr [_P_GivePower]
label_34:
mov   si, _player + PLAYER_T.player_message
mov   word ptr ds:[si], STSTR_BEHOLDX
label_8:
inc   bl
cmp   bl, 6
jl    label_10
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_BEHOLD
call  cht_CheckCheat_
test  al, al
je    jump_to_label_11
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_BEHOLD
label_2:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_CHANGE_LEVEL
call  cht_CheckCheat_
test  al, al
jne   jump_to_label_17
exit_st_responder_ret_0:
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_6:
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_DQDOFF
jmp   label_12
jump_to_label_9:
jmp   label_9
jump_to_label_11:
jmp   label_11
label_5:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_AMMONOKEYS
call  cht_CheckCheat_
test  al, al
je    label_18
mov   bx, _player + PLAYER_T.player_armorpoints
mov   word ptr ds:[bx], 200
mov   bx, _player + PLAYER_T.player_armortype
mov   byte ptr ds:[bx], 2
xor   bl, bl
label_20:
mov   al, bl
cbw  
mov   si, ax
inc   bl
mov   byte ptr ds:[si + _player + PLAYER_T.player_weaponowned], 1
cmp   bl, 9
jl    label_20
xor   bl, bl
label_19:
mov   al, bl
cbw  
mov   si, ax
add   si, ax
mov   ax, word ptr ds:[si + _player + PLAYER_T.player_maxammo]
inc   bl
mov   word ptr ds:[si + _player + PLAYER_T.player_ammo], ax
cmp   bl, 4
jl    label_19
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_KFAADDED
jmp   label_12
jump_to_label_17:
jmp   label_17
label_18:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_AMMOANDKEYS
call  cht_CheckCheat_
test  al, al
je    label_21
mov   bx, _player + PLAYER_T.player_armorpoints
mov   word ptr ds:[bx], 200
mov   bx, _player + PLAYER_T.player_armortype
mov   byte ptr ds:[bx], 2
xor   bl, bl
label_22:
mov   al, bl
cbw  
mov   si, ax
inc   bl
mov   byte ptr ds:[si + _player + PLAYER_T.player_weaponowned], 1
cmp   bl, 9
jl    label_22
xor   bl, bl
label_23:
mov   al, bl
cbw  
mov   si, ax
add   si, ax
mov   ax, word ptr ds:[si + _player + PLAYER_T.player_maxammo]
inc   bl
mov   word ptr ds:[si + _player + PLAYER_T.player_ammo], ax
cmp   bl, 4
jl    label_23
xor   bl, bl
label_24:
mov   al, bl
cbw  
mov   si, ax
inc   bl
mov   byte ptr ds:[si + _player + PLAYER_T.player_cards], 1
cmp   bl, 6
jl    label_24
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_KFAADDED
jmp   label_12
label_21:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_MUSIC
call  cht_CheckCheat_
test  al, al
jne   label_25
mov   bx, _commercial
cmp   byte ptr ds:[bx], 0
je    jump_to_label_26
label_32:
mov   bx, _commercial
cmp   byte ptr ds:[bx], 0
jne   label_27
jump_to_label_12:
jmp   label_12
label_27:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_NOCLIPDOOM2
call  cht_CheckCheat_
test  al, al
je    jump_to_label_12
mov   bx, _player + PLAYER_T.player_cheats
xor   byte ptr ds:[bx], 1
test  byte ptr ds:[bx], 1
je    jump_to_label_28
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_NCON
jmp   label_12
jump_to_label_26:
jmp   label_26
label_25:
mov   bx, _player + PLAYER_T.player_message
lea   dx, [bp - 0Ah]
mov   ax, CHEATID_MUSIC
mov   word ptr ds:[bx], STSTR_MUS
mov   bx, _commercial
call  cht_GetParam_
cmp   byte ptr ds:[bx], 0
je    label_29
mov   al, byte ptr [bp - 0Ah]
cbw  
sub   ax, ASCII_0
mov   dx, ax
shl   dx, 2
add   dx, ax
add   dx, dx
mov   al, byte ptr [bp - 9]
mov   bx, dx
cbw  
add   bx, MUS_RUNNIN
add   bx, ax
add   ax, dx
sub   ax, ASCII_0
lea   cx, [bx - ASCII_1]
cmp   ax, 35
jle   label_30
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_NOMUS
jmp   label_12
label_30:
mov   al, cl
mov   dx, 1
xor   ah, ah

call  S_ChangeMusic_
jmp   label_12
jump_to_label_28:
jmp   label_28
label_29:
mov   al, byte ptr [bp - 0Ah]
cbw  
sub   ax, ASCII_1
mov   dx, ax
shl   dx, 3
add   dx, ax
mov   al, byte ptr [bp - 9]
mov   bx, dx
cbw  
inc   bx
mov   cx, ax
add   ax, dx
sub   cx, ASCII_1
sub   ax, ASCII_1
add   cx, bx
cmp   ax, 31
jle   label_30
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_NOMUS
jmp   label_12
label_26:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_NOCLIP
call  cht_CheckCheat_
test  al, al
jne   label_31
jmp   label_32
label_31:
mov   bx, _player + PLAYER_T.player_cheats
xor   byte ptr ds:[bx], 1
test  byte ptr ds:[bx], 1
je    label_28
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_NCON
jmp   label_12
label_28:
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_NCOFF
jmp   label_12
label_9:
cmp   bl, 1
je    label_33
mov   word ptr ds:[si + _player + PLAYER_T.player_powers], 1
jmp   label_34
label_33:
mov   word ptr ds:[si + _player + PLAYER_T.player_powers], 0
jmp   label_34
label_11:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_CHOPPERS
call  cht_CheckCheat_
test  al, al
je    label_35
mov   bx, _player + PLAYER_T.player_weaponowned + WP_CHAINSAW
mov   byte ptr ds:[bx], 1
mov   bx, _player + PLAYER_T.player_powers + 2 * PW_INVULNERABILITY
mov   word ptr ds:[bx], 1
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], STSTR_CHOPPERS
jmp   label_2
label_35:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[di + 1]
cbw  
mov   dx, ax
mov   ax, CHEATID_MAPPOS
call  cht_CheckCheat_
test  al, al
jne   label_36
jmp   label_2
label_36:
mov   bx, _playerMobj_pos
lea   cx, [bp - 014h]
les   si, dword ptr ds:[bx]
mov   bx, 1
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
call  locallib_printhex_
lea   dx, [bp - 014h]
mov   bx, OFFSET _st_mapcheat_string1
mov   ax, OFFSET _st_stuff_buf
push  ds
mov   cx, cs
push  dx
mov   dx, ds
call  combine_strings_
mov   bx, OFFSET _st_stuff_buf
push  cs
mov   cx, ds
mov   dx, ds
push  OFFSET _st_mapcheat_string2
mov   ax, bx
mov   si, _playerMobj_pos
call  combine_strings_
les   bx, dword ptr ds:[si]
lea   cx, [bp - 014h]
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
mov   bx, 1
call  locallib_printhex_
lea   dx, [bp - 014h]
mov   bx, OFFSET _st_stuff_buf
push  ds
mov   cx, ds
push  dx
mov   ax, bx
mov   dx, ds
call  combine_strings_
mov   bx, OFFSET _st_stuff_buf
push  cs
mov   cx, ds
mov   dx, ds
push  OFFSET _st_mapcheat_string3
mov   ax, bx
call  combine_strings_
lea   cx, [bp - 014h]
mov   bx, si
mov   si, word ptr ds:[si]
mov   es, word ptr ds:[bx + 2]
mov   bx, 1
mov   ax, word ptr es:[si + 4]
mov   dx, word ptr es:[si + 6]
call  locallib_printhex_
lea   dx, [bp - 014h]
mov   bx, OFFSET _st_stuff_buf
push  ds
mov   cx, ds
push  dx
mov   ax, bx
mov   dx, ds
call  combine_strings_
mov   bx, OFFSET _st_stuff_buf
push  cs
mov   cx, ds
mov   dx, ds
push  OFFSET _st_mapcheat_string4
mov   ax, bx
call  combine_strings_
mov   bx, _player + PLAYER_T.player_messagestring
mov   word ptr ds:[bx], OFFSET _st_stuff_buf
jmp   label_2
label_17:
lea   dx, [bp - 6]
mov   ax, CHEATID_CHANGE_LEVEL
mov   bl, 4
call  cht_GetParam_
mov   al, byte ptr [bp - 6]
mov   si, _commercial
sub   al, ASCII_0
cmp   byte ptr ds:[si], 0
je    label_58
mov   ah, 10
imul  ah
add   al, byte ptr [bp - 5]
xor   dl, dl

label_16:
sub   al, ASCII_0
mov   si, _is_ultimate
cmp   byte ptr ds:[si], 0
je    label_56
mov   bl, 5
label_56:
mov   si, _commercial
cmp   byte ptr ds:[si], 0
jne   label_57
test  dl, dl
jle   label_57
cmp   dl, bl
jge   label_57
test  al, al
jle   label_57
cmp   al, 10
jl    label_59
label_57:
mov   bx, _commercial
cmp   byte ptr ds:[bx], 0
jne   label_60
label_55:
jmp   exit_st_responder_ret_0
label_60:
test  al, al
jle   label_55
cmp   al, 40
jg    label_55
label_59:
mov   bx, _player + PLAYER_T.player_message
cbw  
mov   word ptr ds:[bx], STSTR_CLEV
mov   bx, ax
mov   al, dl
cbw  
mov   si, _gameskill
mov   dx, ax
mov   al, byte ptr ds:[si]
xor   ah, ah
call  G_DeferedInitNew_
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_58:
mov   dl, al
mov   al, byte ptr [bp - 5]
jmp   label_16

ENDP

@

PROC    ST_calcPainOffset_ NEAR
PUBLIC  ST_calcPainOffset_

push  bx
push  dx
mov   ax, word ptr ds:[_player + PLAYER_T.player_health]
cmp   ax, 100
jle   more_than_100_health

mov   bx, ax
jmp   use_current_health
more_than_100_health:
mov   bx, 100
use_current_health:
cmp   bx, word ptr ds:[_st_calc_oldhealth]
je    old_health_100

mov   ax, 100
sub   ax, bx
mov   ah, 5
mul   ah
mov   dl, 101
div   dl
SHIFT_MACRO shl   ax 3
mov   word ptr ds:[_st_calc_oldhealth], bx
mov   word ptr ds:[_st_calc_lastcalc], ax
old_health_100:

mov   ax, word ptr ds:[_st_calc_lastcalc]
pop   dx
pop   bx
ret   



ENDP




PROC    ST_updateFaceWidget_ NEAR
PUBLIC  ST_updateFaceWidget_


PUSHA_NO_AX_OR_BP_MACRO
xor   ax, ax
cwd
mov   bx, ax
mov   cx, ax
mov   cl, byte ptr ds:[_st_face_priority]
cmp   cl, 10
jge   not_face_10
cmp   word ptr ds:[_player + PLAYER_T.player_health], ax ; 0
jne   not_face_10
mov   cl, 9

mov   word ptr ds:[_st_faceindex], ST_DEADFACE
mov   word ptr ds:[_st_facecount], 1

jmp   set_face_priority_dec_facecount_and_exit

not_face_10:
cmp   cl, 9
jge   not_face_9
cmp   byte ptr ds:[_player + PLAYER_T.player_bonuscount], al ; 0
je    not_face_9

loop_next_wepowned_face:


mov   al, byte ptr ds:[bx + _oldweaponsowned]
cmp   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
je    not_weapon_change
mov   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
inc   dx  ; do evil grin
mov   byte ptr ds:[bx + _oldweaponsowned], al
not_weapon_change:
inc   bx
cmp   bl, NUMWEAPONS
jl    loop_next_wepowned_face

test  dx, dx
je    not_face_9
mov   cl, 8

mov   word ptr ds:[_st_facecount], ST_EVILGRINCOUNT
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
sub   ax, word ptr ds:[_st_oldhealth]
mov   cl, 7

cmp   ax, ST_MUCHPAIN
jg    dont_look_at_attacker
jmp   look_at_attacker
dont_look_at_attacker:
mov   word ptr ds:[_st_facecount], ST_TURNCOUNT
call  ST_calcPainOffset_
add   al, ST_OUCHOFFSET
jmp   set_face_priority_dec_facecount_and_exit



not_face_8:
cmp   cl, 7
jge   not_face_7
cmp   word ptr ds:[_player + PLAYER_T.player_damagecount], ax
je    not_face_7
mov   ax, word ptr ds:[_player + PLAYER_T.player_health]
sub   ax, word ptr ds:[_st_oldhealth]
mov   word ptr ds:[_st_facecount], ST_TURNCOUNT
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
mov   byte ptr ds:[_st_face_lastattackdown], -1
jmp   not_face_6
attack_down:
cmp   byte ptr ds:[_st_face_lastattackdown], -1
je    add_rampage_delay
dec   byte ptr ds:[_st_face_lastattackdown]
jne   not_face_6
mov   cl, 5

call  ST_calcPainOffset_
mov   word ptr ds:[_st_facecount], 1
add   al, ST_RAMPAGEOFFSET
mov   byte ptr ds:[_st_face_lastattackdown], 1
jmp   set_face_priority_dec_facecount_and_exit



add_rampage_delay:
mov   byte ptr ds:[_st_face_lastattackdown], ST_RAMPAGEDELAY
not_face_6:

cmp   cl, 5

jge   not_face_5
test  byte ptr ds:[_player + PLAYER_T.player_cheats], CF_GODMODE
jne   handle_invuln
cmp   word ptr ds:[_player + PLAYER_T.player_powers], ax ; 0
je    not_face_5

handle_invuln:
;mov   cl, 4
mov   byte ptr ds:[_st_face_priority], 4
mov   word ptr ds:[_st_faceindex], ST_GODFACE
mov   word ptr ds:[_st_facecount], ax ; 0

jmp   exit_updatefacewidget



not_face_5:
cmp   word ptr ds:[_st_facecount], ax ; 0
jne   dec_facecount_and_exit

mov   al, byte ptr ds:[_st_randomnumber]
cwd
mov   bl, 3
div   bl
mov   dl, ah
call  ST_calcPainOffset_
mov   word ptr ds:[_st_facecount], ST_STRAIGHTFACECOUNT
add   ax, dx ; rand mod 3
xor   cx, cx
set_face_priority_dec_facecount_and_exit:
mov   byte ptr ds:[_st_face_priority], cl

write_face_index_and_finish_face_checks:
mov   word ptr ds:[_st_faceindex], ax

dec_facecount_and_exit:
dec   word ptr ds:[_st_facecount]
exit_updatefacewidget:
POPA_NO_AX_OR_BP_MACRO
ret   


look_at_attacker:
mov   byte ptr ds:[_st_face_priority], cl
mov   ax, SIZEOF_MOBJ_POS_T
mul   word ptr ds:[_player + PLAYER_T.player_attackerRef]
xchg  ax, di
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
push  word ptr es:[di + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[di + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[di + MOBJ_POS_T.mp_x + 2]
push  word ptr es:[di + MOBJ_POS_T.mp_x + 0]

les   si, dword ptr ds:[_playerMobj_pos]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
les   ax, dword ptr es:[si + MOBJ_POS_T.mp_x + 0]
mov   dx, es

call  R_PointToAngle2_
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
mov   bl, 1
angle_and_i_set:
mov   word ptr ds:[_st_facecount], ST_OUCHCOUNT
call  ST_calcPainOffset_
cmp   dx, ANG45_HIGHBITS
jae   do_side_look
; head on
add   al, ST_RAMPAGEOFFSET
jmp   write_face_index_and_finish_face_checks
set_i_0:
xor   bl, bl
jmp   angle_and_i_set
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
add   al, bl ; 1 or 0.
add   al, ST_TURNOFFSET ; 3, so 3 or 4..
jmp   write_face_index_and_finish_face_checks

ENDP


PROC    ST_updateWidgets_ NEAR
PUBLIC  ST_updateWidgets_

push  di
push  si

push  ds
pop   es
mov   si, OFFSET _player + PLAYER_T.player_cards
mov   di, OFFSET _keyboxes

do_next_cardcolor:
xor   ax, ax
lodsb
;        keyboxes[i] = player.cards[i] ? i : -1;
test  ax, ax
jnz   dont_set_minus_one
mov   al, -1
dont_set_minus_one:
cbw
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


PROC    ST_Ticker_ NEAR
PUBLIC  ST_Ticker_

call  M_Random_
mov   byte ptr ds:[_st_randomnumber], al
call  ST_updateWidgets_
mov   ax, word ptr ds:[_player + PLAYER_T.player_health]
mov   word ptr ds:[_st_oldhealth], ax
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
SHIFT_MACRO sar   dx 6
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
cmp   al, byte ptr ds:[_st_palette]
je    dont_set_palette_and_exit
set_palette_and_exit:
mov   byte ptr ds:[_st_palette], al
cbw  
call  I_SetPalette_
dont_set_palette_and_exit:
pop   dx
ret   

ENDP


PROC    STlib_updateflag_ NEAR
PUBLIC  STlib_updateflag_

cmp   byte ptr ds:[_updatedthisframe], 0
jne   exit_updateflag
call  Z_QuickMapStatus_
mov   byte ptr ds:[_updatedthisframe], 1
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
mov   cx, word ptr ds:[si + ST_MULTIICON_T.st_multicon_oldinum]
cmp   cx, dx
jne   do_draw
cmp   byte ptr ds:[_do_st_refresh], 0
jne   do_draw
exit_updatemulticon:
POPA_NO_AX_OR_BP_MACRO
exit_updatemulticon_no_pop:
exit_stlib_drawnum_no_pop:
ret   

do_draw:
call  STlib_updateflag_

mov   word ptr ds:[si + ST_MULTIICON_T.st_multicon_oldinum], dx ; update oldinum, dont need dx anymore
sub   dx, bx   ; calculate  "inum-is_binicon" lookup
sal   dx, 1
push  dx       ; store inum-is_binicon lookup

cmp   cx, -1                ; mi->oldinum != -1
je    skip_rect
test  bl, bl                ; !is_binicon
jne   skip_rect

les   ax, dword ptr ds:[si + ST_MULTIICON_T.st_multicon_x]
mov   dx, es  ; st_multicon_y

mov   di, ST_GRAPHICS_SEGMENT   ; todo load from mem?
mov   es, di

mov   di, word ptr  ds:[si + ST_MULTIICON_T.st_multicon_patch_offset] ; mi->patch_offset

sal   cx, 1     ; word lookup
add   di, cx    ; mi->patch_offset[mi->oldinum]
mov   di, word ptr  ds:[di] ; es:di is patch


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

call  V_CopyRect_

skip_rect:

lodsw           ; x
xchg  ax, bx    ; bx holds x
lodsw           ; y
xchg  ax, dx    ; dx gets y
lodsw           ; oldinum
lodsw           ; patch_offset
pop   si        ;   get inum-is_binicon lookup
add   si, ax    ; patch_offset[0] + inum-is_binicon lookup


mov   ax, ST_GRAPHICS_SEGMENT
push  ax
push  word ptr ds:[si]

xor   ax, ax
xchg  ax, bx    ; ax gets x. bx gets FG == 0


call  V_DrawPatch_
exit_stlib_drawnum_other:

jmp   exit_updatemulticon


ENDP



PROC    STlib_drawNum_ NEAR
PUBLIC  STlib_drawNum_


PUSHA_NO_AX_OR_BP_MACRO
xchg  ax, si
mov   cx, word ptr ds:[si + ST_NUMBER_T.st_number_oldnum]
cmp   cx, dx
jne   drawnum
cmp   byte ptr ds:[_do_st_refresh], 0
je    exit_stlib_drawnum_other
drawnum:

call  STlib_updateflag_

;	p0 = (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, number->patch_offset[0]));
mov   ax, ST_GRAPHICS_SEGMENT
mov   es, ax
mov   di, word ptr ds:[si + ST_NUMBER_T.st_number_patch_offset]
mov   di, word ptr ds:[di] ; offset 0
les   bx, dword ptr es:[di + PATCH_T.patch_width]

; bx has width, es has height for now

mov   word ptr ds:[si + ST_NUMBER_T.st_number_oldnum], dx
mov   ax,word ptr ds:[si + ST_NUMBER_T.st_number_width] ; numdigits



;    digitwidth = w * numdigits;
; bx has width, but its smaller than 256.
mul   bl
; digits * w in ax
;    x = number->x - digitwidth;
push  bx   ; push width (-2)
xchg  ax, bx  ; digitwidth in bx
mov   ax, word ptr ds:[si + ST_NUMBER_T.st_number_x]
sub   ax, bx

mov   di, dx ; back up num
mov   dx, word ptr ds:[si + ST_NUMBER_T.st_number_y]
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
call  V_CopyRect_

pop   cx  ; get w

cmp   di, 1994
je    exit_stlib_drawnum

lodsw ;  number->x
xchg  ax, bx
lodsw ;  number->y
xchg  ax, dx
add   si, 4
lodsw ;  number->patchoffset
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

push  word ptr ds:[si+bx]
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
push  word ptr ds:[si]
sub   ax, cx
call  V_DrawPatch_
jmp   exit_stlib_drawnum
ENDP


PROC    STlib_updatePercent_ NEAR
PUBLIC  STlib_updatePercent_


cmp   byte ptr ds:[_do_st_refresh], 0
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
les   ax, dword ptr ds:[si + ST_NUMBER_T.st_number_x]
mov   dx, es
mov   si, word ptr ds:[si + ST_PERCENT_T.st_percent_patch_offset]
push  word ptr ds:[si]
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


cmp   byte ptr ds:[_st_statusbaron], 0
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
lea   ax, [bx + _w_ammo]
call  STlib_drawNum_

mov   dx, word ptr ds:[si - 2 + PLAYER_T.player_maxammo - PLAYER_T.player_ammo]
lea   ax, [bx + _w_maxammo]
call  STlib_drawNum_

add   bx, SIZEOF_ST_NUMBER_T
loop  update_next_ammo

mov   al, SIZEOF_WEAPONINFO_T
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
add   di, SIZEOF_ST_MULTICON_T
loop  update_next_weapon

;        STlib_updateMultIcon(&w_faces, st_faceindex, false);

mov   ax, OFFSET _w_faces
mov   dx, word ptr ds:[_st_faceindex]
xor   bx, bx
call  STlib_updateMultIcon_

mov   di, OFFSET _w_keyboxes
mov   si, OFFSET _keyboxes
mov   cx, 3
;            STlib_updateMultIcon(&w_keyboxes[i], keyboxes[i], false);

update_next_keybox:
lodsw
xchg  ax, dx
mov   ax, di
xor   bx, bx
call  STlib_updateMultIcon_
add   di, SIZEOF_ST_MULTICON_T
loop  update_next_keybox

exit_st_drawwidgets:
POPA_NO_AX_OR_BP_MACRO
ret   


ENDP



PROC    ST_Drawer_ NEAR
PUBLIC  ST_Drawer_

dec   ax
neg   ax ; ! fullscreen
or    al, byte ptr ds:[_automapactive]
mov   byte ptr ds:[_st_statusbaron], al
call  ST_doPaletteStuff_
mov   ax, 0100h  ; ah = 1 al = 0

mov   byte ptr ds:[_updatedthisframe], al ; 0
or    byte ptr ds:[_st_firsttime], dl
je    not_first_time
first_time:
mov   byte ptr ds:[_st_firsttime], al ; 0
mov   byte ptr ds:[_updatedthisframe], ah ; 1
mov   byte ptr ds:[_do_st_refresh], ah ; 1

call  Z_QuickMapStatus_
call  ST_refreshBackground_
call  ST_drawWidgets_
jmp   do_quickmapphysics_and_exit

not_first_time:

mov   byte ptr ds:[_do_st_refresh], al ; 0
call  ST_drawWidgets_

cmp   byte ptr ds:[_updatedthisframe], 0
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