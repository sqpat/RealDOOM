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
EXTRN ST_updateFaceWidget_:NEAR

.DATA

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

COMMENT @


PROC    ST_updateFaceWidget_ NEAR
PUBLIC  ST_updateFaceWidget_


push  bx
push  cx
push  dx
push  si
cmp   byte ptr ds:[_st_face_priority], 10
jge   label_37
mov   bx, _player + PLAYER_T.player_health
cmp   word ptr ds:[bx], 0
jne   label_37
jmp   label_38
label_37:
cmp   byte ptr ds:[_st_face_priority], 9
jge   label_39
mov   bx, _player + PLAYER_T.player_bonuscount
cmp   byte ptr ds:[bx], 0
je    label_39
xor   dh, dh
xor   dl, dl
label_61:
mov   al, dl
cbw  
mov   bx, ax
mov   al, byte ptr ds:[bx + _oldweaponsowned]
cmp   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
je    label_40
mov   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
mov   dh, 1
mov   byte ptr ds:[bx + _oldweaponsowned], al
label_40:
inc   dl
cmp   dl, 9
jl    label_61
test  dh, dh
je    label_39
mov   byte ptr ds:[_st_face_priority], 8
mov   word ptr ds:[_st_facecount], ST_EVILGRINCOUNT
call  ST_calcPainOffset_
add   ax, 6
mov   word ptr ds:[_st_faceindex], ax
label_39:
cmp   byte ptr ds:[_st_face_priority], 8
jge   label_62
mov   bx, _player + PLAYER_T.player_damagecount
cmp   word ptr ds:[bx], 0
je    label_62
mov   bx, _player + PLAYER_T.player_attackerRef
mov   ax, word ptr ds:[bx]
test  ax, ax
je    label_62
mov   si, _playerMobjRef
cmp   ax, word ptr ds:[si]
je    label_62
mov   bx, _player + PLAYER_T.player_health
mov   ax, word ptr ds:[bx]
sub   ax, word ptr ds:[_st_oldhealth]
mov   byte ptr ds:[_st_face_priority], 7
cmp   ax, ST_MUCHPAIN
jg    label_87
jmp   label_88
label_87:
mov   word ptr ds:[_st_facecount], ST_TURNCOUNT
call  ST_calcPainOffset_
add   ax, 5
label_102:
mov   word ptr ds:[_st_faceindex], ax
label_62:
cmp   byte ptr ds:[_st_face_priority], 7
jge   label_89
mov   bx, _player + PLAYER_T.player_damagecount
cmp   word ptr ds:[bx], 0
je    label_89
mov   bx, _player + PLAYER_T.player_health
mov   ax, word ptr ds:[bx]
sub   ax, word ptr ds:[_st_oldhealth]
cmp   ax, ST_MUCHPAIN
jle   jump_to_label_90
mov   byte ptr ds:[_st_face_priority], 7
mov   word ptr ds:[_st_facecount], ST_TURNCOUNT
call  ST_calcPainOffset_
add   ax, 5
label_106:
mov   word ptr ds:[_st_faceindex], ax
label_89:
cmp   byte ptr ds:[_st_face_priority], 6
jge   label_91
mov   bx, _player + PLAYER_T.player_attackdown
cmp   byte ptr ds:[bx], 0
je    jump_to_label_92
cmp   byte ptr ds:[_st_face_lastattackdown], -1
jne   jump_to_label_93
mov   byte ptr ds:[_st_face_lastattackdown], ST_RAMPAGEDELAY
label_91:
cmp   byte ptr ds:[_st_face_priority], 5
jge   label_94
mov   bx, _player + PLAYER_T.player_cheats
test  byte ptr ds:[bx], 2
jne   jump_to_label_95
mov   bx, _player + PLAYER_T.player_powers
cmp   word ptr ds:[bx], 0
jne   jump_to_label_95
label_94:
cmp   word ptr ds:[_st_facecount], 0
je    label_96
label_108:
dec   word ptr ds:[_st_facecount]
pop   si
pop   dx
pop   cx
pop   bx
ret   
jump_to_label_90:
jmp   label_90
label_38:
mov   byte ptr ds:[_st_face_priority], 9
mov   word ptr ds:[_st_faceindex], ST_DEADFACE
mov   word ptr ds:[_st_facecount], 1
jmp   label_108
jump_to_label_92:
jmp   label_92
jump_to_label_93:
jmp   label_93
jump_to_label_95:
jmp   label_95
label_96:
mov   al, byte ptr ds:[_st_randomnumber]
xor   ah, ah
mov   bx, 3
cwd   
idiv  bx
call  ST_calcPainOffset_
mov   word ptr ds:[_st_facecount], ST_STRAIGHTFACECOUNT
add   ax, dx
mov   byte ptr ds:[_st_face_priority], 0
mov   word ptr ds:[_st_faceindex], ax
dec   word ptr ds:[_st_facecount]
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_88:
mov   bx, _player + PLAYER_T.player_attackerRef
imul  bx, word ptr ds:[bx], SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
push  word ptr es:[bx + 6]
push  word ptr es:[bx + 4]
push  word ptr es:[bx + 2]
mov   si, _playerMobj_pos
push  word ptr es:[bx]
les   bx, dword ptr ds:[si]
mov   ax, word ptr es:[bx + 4]
mov   cx, word ptr es:[bx + 6]
mov   dx, word ptr es:[bx]
mov   si, word ptr es:[bx + 2]
mov   bx, ax
mov   ax, dx
mov   dx, si
mov   si, _playerMobj_pos
call  R_PointToAngle2_
les   bx, dword ptr ds:[si]
cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
ja    label_97
jne   label_98
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
jbe   label_98
label_97:
mov   bx, si
mov   si, word ptr ds:[si + MOBJ_POS_T.mp_x + 0]
mov   es, word ptr ds:[bx + MOBJ_POS_T.mp_x + 2]
sub   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
sbb   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
cmp   dx, ANG180_HIGHBITS
ja    label_99
jne   label_100
test  ax, ax
jbe   label_100
label_99:
mov   bl, 1
label_104:
mov   word ptr ds:[_st_facecount], ST_OUCHCOUNT
call  ST_calcPainOffset_
cmp   dx, ANG45_HIGHBITS
jae   label_101
add   ax, 7
jmp   label_102
label_100:
xor   bl, bl
jmp   label_104
label_98:
mov   bx, si
mov   si, word ptr ds:[si]
mov   es, word ptr ds:[bx + 2]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
sub   bx, ax
mov   ax, bx
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
sbb   bx, dx
mov   dx, bx
cmp   bx, ANG180_HIGHBITS
jb    label_99
jne   label_103
test  ax, ax
jbe   label_99
label_103:
xor   bl, bl
jmp   label_104
label_101:
test  bl, bl
je    label_105
add   ax, 3
jmp   label_102
label_105:
add   ax, 4
jmp   label_102
label_90:
mov   byte ptr ds:[_st_face_priority], 6
mov   word ptr ds:[_st_facecount], ST_OUCHCOUNT
call  ST_calcPainOffset_
add   ax, 7
jmp   label_106
label_93:
dec   byte ptr ds:[_st_face_lastattackdown]
je    label_107
jmp   label_91
label_107:
mov   byte ptr ds:[_st_face_priority], 5
call  ST_calcPainOffset_
mov   word ptr ds:[_st_facecount], 1
add   ax, 7
mov   byte ptr ds:[_st_face_lastattackdown], 1
mov   word ptr ds:[_st_faceindex], ax
jmp   label_91
label_92:
mov   byte ptr ds:[_st_face_lastattackdown], -1
jmp   label_91
label_95:
mov   byte ptr ds:[_st_face_priority], 4
mov   word ptr ds:[_st_faceindex], ST_GODFACE
mov   word ptr ds:[_st_facecount], 1
dec   word ptr ds:[_st_facecount]
pop   si
pop   dx
pop   cx
pop   bx
ret   
ENDP

@

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


PROC    STlib_updateMultIcon_ NEAR
PUBLIC  STlib_updateMultIcon_

cmp   dx, -1
je    exit_updatemulticon_no_pop  ; test once.
PUSHA_NO_AX_OR_BP_MACRO
xchg  ax, si
cmp   byte ptr ds:[_do_st_refresh], 0
jne   do_draw
mov   cx, word ptr ds:[si + ST_MULTIICON_T.st_multicon_oldinum]
cmp   cx, dx
je    do_draw
exit_updatemulticon:
POPA_NO_AX_OR_BP_MACRO
exit_updatemulticon_no_pop:
ret   

do_draw:
call  STlib_updateflag_

mov   word ptr ds:[si + ST_MULTIICON_T.st_multicon_oldinum], dx ; update oldinum, dont need anymore
mov   ax, bx 
cbw
sub   dx, ax   ; calculate  "inum-is_binicon" lookup
sal   dx, 1
push  dx       ; store inum-is_binicon lookup

cmp   cx, -1                ; mi->oldinum != -1
je    skip_rect
test  bl, bl                ; !is_binicon
jne   skip_rect


mov   di, ST_GRAPHICS_SEGMENT   ; todo load from mem?
mov   es, di

mov   di, word ptr  ds:[si + ST_MULTIICON_T.st_multicon_patch_offset] ; mi->patch_offset
sal   cx, 1     ; word lookup
add   di, cx    ; mi->patch_offset[mi->oldinum]
mov   di, word ptr  ds:[di] ; es:di is patch



IF COMPISA GE COMPILE_186
    
    mov   ax, word ptr es:[di + PATCH_T.patch_leftoffset]
    mov   dx, word ptr es:[di + PATCH_T.patch_topoffset]
    mov   cx, dx
    add   cx, ax
    imul  cx, cx, SCREENWIDTH
    push  cx                    ; offset on stack
    sub   cx, ST_Y * SCREENWIDTH ; 0D200
    push  cx        ; offset - d200 on stack

ELSE

    mov   ax, word ptr es:[di + PATCH_T.patch_leftoffset]
    mov   dx, word ptr es:[di + PATCH_T.patch_topoffset]
    push  ax
    push  dx
    add   ax, dx
    mov   dx, SCREENWIDTH
    mul   dx
    pop   dx
    pop   cx
    push  ax        ; offset on stack
    sub   ax, ST_Y * SCREENWIDTH ; 0D200
    push  ax        ; offset - d200 on stack
    xchg  ax, cx


ENDIF

neg   ax
add   ax, word ptr ds:[si + ST_MULTIICON_T.st_multicon_x]
neg   dx
add   dx, word ptr ds:[si + ST_MULTIICON_T.st_multicon_y]

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

jmp   exit_updatemulticon


ENDP

COMMENT @


PROC    STlib_drawNum_ NEAR
PUBLIC  STlib_drawNum_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
mov   di, ax
mov   si, dx
mov   al, byte ptr ds:[di + 4]
mov   byte ptr [bp - 4], al
cmp   dx, word ptr ds:[di + 6]
jne   label_76
cmp   byte ptr ds:[_do_st_refresh], 0
jne   label_76
jmp   exit_stlib_drawnum
label_76:
call  STlib_updateflag_
mov   bx, word ptr ds:[di + 8]
mov   ax, ST_GRAPHICS_SEGMENT
mov   bx, word ptr ds:[bx]
mov   es, ax
mov   ax, word ptr es:[bx]
mov   word ptr [bp - 6], ax
mov   ax, word ptr es:[bx + 2]
mov   word ptr [bp - 8], ax
mov   word ptr ds:[di + 6], si
test  si, si
jge   label_77
cmp   byte ptr [bp - 4], 2
jne   label_78
cmp   si, -9
jge   label_78
mov   si, -9
neg_si:
neg   si
label_77:
mov   al, byte ptr [bp - 6]
mul   byte ptr [bp - 4]
mov   byte ptr [bp - 2], al
mov   bl, al
mov   ax, word ptr ds:[di]
xor   bh, bh
mov   cx, word ptr [bp - 8]
sub   ax, bx
mov   dx, word ptr ds:[di + 2]
mov   word ptr [bp - 0Ah], ax

call  V_MarkRect_
imul  dx, word ptr ds:[di + 2], SCREENWIDTH
mov   ax, word ptr ds:[di + 2]
sub   ax, ST_Y
imul  ax, ax, SCREENWIDTH
mov   bl, byte ptr [bp - 2]
mov   cx, word ptr [bp - 8]
xor   bh, bh
add   dx, word ptr [bp - 0Ah]
add   ax, word ptr [bp - 0Ah]
call  V_CopyRect_
cmp   si, 1994
je    exit_stlib_drawnum
mov   cx, word ptr ds:[di]
test  si, si
je    label_80
label_79:
test  si, si
je    exit_stlib_drawnum
dec   byte ptr [bp - 4]
cmp   byte ptr [bp - 4], -1
jne   label_81
exit_stlib_drawnum:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_78:
cmp   byte ptr [bp - 4], 3
jne   neg_si
cmp   si, -99
jge   neg_si
mov   si, -99
jmp   neg_si
label_80:
mov   bx, word ptr ds:[di + 8]
push  ST_GRAPHICS_SEGMENT
mov   ax, word ptr ds:[bx]
mov   dx, word ptr ds:[di + 2]
push  ax
mov   ax, cx
xor   bx, bx
sub   ax, word ptr [bp - 6]
call  V_DrawPatch_
jmp   label_79
label_81:
mov   ax, si
mov   bx, 10
cwd   
idiv  bx
mov   bx, word ptr ds:[di + 8]
add   dx, dx
push  ST_GRAPHICS_SEGMENT
add   bx, dx
sub   cx, word ptr [bp - 6]
mov   dx, word ptr ds:[bx]
mov   ax, cx
push  dx
xor   bx, bx
mov   dx, word ptr ds:[di + 2]
call  V_DrawPatch_
mov   ax, si
mov   bx, 10
cwd   
idiv  bx
mov   si, ax
jmp   label_79


ENDP


PROC    STlib_updatePercent_ NEAR
PUBLIC  STlib_updatePercent_


push  bx
push  cx
push  si
mov   si, ax
mov   cx, dx
cmp   byte ptr ds:[_do_st_refresh], 0
jne   label_82
mov   dx, cx
mov   ax, si
call  STlib_drawNum_
pop   si
pop   cx
pop   bx
ret   
label_82:
call  STlib_updateflag_
mov   bx, word ptr ds:[si + ST_PERCENT_T.st_percent_patch_offset]
push  ST_GRAPHICS_SEGMENT
mov   ax, word ptr ds:[bx]
mov   dx, word ptr ds:[si + 2]
push  ax
xor   bx, bx
mov   ax, word ptr ds:[si]

call  V_DrawPatch_

mov   dx, cx
mov   ax, si
call  STlib_drawNum_
pop   si
pop   cx
pop   bx
ret   

ENDP


PROC    ST_drawWidgets_ NEAR
PUBLIC  ST_drawWidgets_

push  bx
push  cx
push  dx
push  si
cmp   byte ptr ds:[_st_statusbaron], 0
jne   label_49
jmp   exit_st_drawwidgets
label_49:
mov   bx, _player + PLAYER_T.player_readyweapon
mov   al, byte ptr ds:[bx]
xor   ah, ah
imul  bx, ax, SIZEOF_WEAPONINFO_T
mov   ch, byte ptr ds:[bx + _weaponinfo]
xor   cl, cl
label_83:
mov   al, cl
cbw  
mov   bx, ax
add   bx, ax
imul  si, ax, SIZEOF_ST_NUMBER_T
mov   ax, _w_ammo
mov   dx, word ptr ds:[bx + _player + PLAYER_T.player_ammo]
add   ax, si
call  STlib_drawNum_
mov   ax, _w_maxammo
mov   dx, word ptr ds:[bx + _player + PLAYER_T.player_maxammo]
add   ax, si
inc   cl
call  STlib_drawNum_
cmp   cl, 4
jl    label_83
cmp   ch, 5
je    label_84
jmp   label_85
label_84:
mov   dx, 1994
mov   ax, _w_ready
label_86:
call  STlib_drawNum_
mov   bx, _player + PLAYER_T.player_health
mov   ax, OFFSET _w_health
mov   dx, word ptr ds:[bx]
call  STlib_updatePercent_
mov   bx, _player + PLAYER_T.player_armorpoints
mov   ax, OFFSET _w_armor
mov   dx, word ptr ds:[bx]
call  STlib_updatePercent_
mov   bx, 1
mov   ax, OFFSET _w_armsbg
mov   dx, bx
xor   cl, cl
call  STlib_updateMultIcon_
label_71:
mov   al, cl
cbw  
mov   bx, ax
mov   si, OFFSET _w_arms
mov   al, byte ptr ds:[bx + _player + PLAYER_T._player_weaponowned + 1]
shl   bx, 3
cbw  
add   si, bx
mov   dx, ax
mov   ax, si
xor   bx, bx
inc   cl
call  STlib_updateMultIcon_
cmp   cl, 6
jl    label_71
mov   ax, OFFSET _w_faces
mov   dx, word ptr ds:[_st_faceindex]
xor   bx, bx
call  STlib_updateMultIcon_
xor   cl, cl
label_50:
mov   al, cl
cbw  
mov   bx, ax
add   bx, ax
shl   ax, 3
mov   dx, word ptr ds:[bx + _keyboxes]
add   ax, OFFSET _w_keyboxes
xor   bx, bx
inc   cl
call  STlib_updateMultIcon_
cmp   cl, 3
jl    label_50
exit_st_drawwidgets:
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_85:
mov   al, ch
cbw  
mov   bx, ax
add   bx, ax
mov   ax, _w_ready
mov   dx, word ptr ds:[bx + _player + PLAYER_T.player_ammo]
jmp   label_86


ENDP


PROC    ST_Drawer_ NEAR
PUBLIC  ST_Drawer_

push  bx
test  al, al
jne   label_42
label_45:
mov   al, 1
label_46:
mov   byte ptr ds:[_st_statusbaron], al
mov   al, byte ptr ds:[_st_firsttime]
test  al, al
je    label_43
label_47:
mov   al, 1
label_48:
mov   byte ptr ds:[_updatedthisframe], 0
mov   byte ptr ds:[_st_firsttime], al
call  ST_doPaletteStuff_
mov   al, byte ptr ds:[_st_firsttime]
test  al, al
je    label_44
mov   byte ptr ds:[_st_firsttime], 0
mov   byte ptr ds:[_updatedthisframe], 1

call  Z_QuickMapStatus_
call  ST_refreshBackground_  ; todo inline?
mov   byte ptr ds:[_do_st_refresh], 1
label_41:
call  ST_drawWidgets_
cmp   byte ptr ds:[_updatedthisframe], 0
jne   do_quickmapphysics
pop   bx
ret   
label_42:
mov   bx, _automapactive
mov   al, byte ptr ds:[bx]
test  al, al
jne   label_45
jmp   label_46
label_43:
test  dl, dl
jne   label_47
jmp   label_48
label_44:
mov   byte ptr ds:[_do_st_refresh], al
jmp   label_41
do_quickmapphysics:
call  Z_QuickMapPhysics_
pop   bx
ret   

@

PROC    ST_STUFF_ENDMARKER_ NEAR
PUBLIC  ST_STUFF_ENDMARKER_
ENDP


ENDP

END