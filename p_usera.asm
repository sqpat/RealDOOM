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


EXTRN S_StartSoundWithParams_:PROC
EXTRN P_RemoveThinker_:PROC
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindMinSurroundingLight_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR
EXTRN T_MovePlaneFloorUp_:NEAR
EXTRN T_MovePlaneFloorDown_:NEAR
EXTRN P_Random_:NEAR
EXTRN P_UpdateThinkerFunc_:NEAR


.DATA

EXTRN _onground:BYTE

.CODE




PROC    P_USER_STARTMARKER_ NEAR
PUBLIC  P_USER_STARTMARKER_
ENDP




PROC    P_Thrust_ NEAR
PUBLIC  P_Thrust_


push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
push  ax
mov   si, bx
mov   di, cx
mov   bx, _playerMobj
mov   cl, 11
shl   di, cl
rol   si, cl
xor   di, si
and   si, 0F800  ; shift mask todo make suck less.
xor   di, si
mov   dx, ax
mov   ax, FINECOSINE_SEGMENT
mov   bx, word ptr ds:[bx]
mov   cx, di
mov   word ptr [bp - 2], bx
mov   bx, si
call  FixedMulTrig_
mov   bx, word ptr [bp - 2]
mov   cx, di
add   word ptr ds:[bx + MOBJ_T.m_momx + 0], ax
adc   word ptr ds:[bx + MOBJ_T.m_momx + 2], dx
mov   bx, _playerMobj
mov   ax, FINESINE_SEGMENT
mov   bx, word ptr ds:[bx]
mov   dx, word ptr [bp - 4]
mov   word ptr [bp - 2], bx
mov   bx, si
call  FixedMulTrig_
mov   bx, word ptr [bp - 2]
add   word ptr ds:[bx + MOBJ_T.m_momy + 0], ax
adc   word ptr ds:[bx + MOBJ_T.m_momy + 2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret  

ENDP


PROC    P_CalcHeight_ NEAR
PUBLIC  P_CalcHeight_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 8
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   ax, word ptr ds:[bx + MOBJ_T.m_ceilingz]
sub   ax, (4 SHL SHORTFLOORBITS)
mov   si, ax
xor   ah, ah
mov   bx, _playerMobj
and   al, 7
mov   bx, word ptr ds:[bx]
shl   ax, 13
mov   cx, word ptr ds:[bx + MOBJ_T.m_momx + 2]
mov   word ptr [bp - 2], ax
mov   ax, word ptr ds:[bx + MOBJ_T.m_momx + 0]
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   di, word ptr ds:[bx + MOBJ_T.m_momx + 0]
mov   dx, word ptr ds:[bx + MOBJ_T.m_momx + 2]
mov   bx, ax
mov   ax, di
call  FixedMul_
mov   bx, _playerMobj
mov   di, ax
mov   bx, word ptr ds:[bx]
mov   word ptr [bp - 8], dx
mov   ax, word ptr ds:[bx + MOBJ_T.m_momy + 0]
mov   dx, word ptr ds:[bx + MOBJ_T.m_momy + 2]
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   word ptr [bp - 6], dx
mov   dx, word ptr ds:[bx + MOBJ_T.m_momy + 0]
mov   bx, word ptr ds:[bx + MOBJ_T.m_momy + 2]
mov   cx, word ptr [bp - 6]
mov   word ptr [bp - 6], bx
mov   bx, ax
mov   ax, dx
mov   dx, word ptr [bp - 6]
sar   si, 3
call  FixedMul_
mov   bx, _player + PLAYER_T.player_bob + 0
add   ax, di
adc   dx, word ptr [bp - 8]
mov   word ptr ds:[bx], ax
mov   word ptr ds:[bx + 2], dx
sar   word ptr ds:[bx + 2], 1
rcr   word ptr ds:[bx], 1
sar   word ptr ds:[bx + 2], 1
rcr   word ptr ds:[bx], 1
mov   ax, word ptr ds:[bx + 2]
cmp   ax, MAXBOB_HIGHBITS
jg    label_1
jne   label_2
cmp   word ptr ds:[bx], 0
jbe   label_2
label_1:
mov   word ptr ds:[bx], 0
mov   word ptr ds:[bx + 2], MAXBOB_HIGHBITS
label_2:
mov   bx, _player + PLAYER_T.player_cheats
test  byte ptr ds:[bx], CF_NOMOMENTUM
jne   label_3
cmp   byte ptr ds:[_onground], 0
jne   label_4
label_3:
mov   bx, _playerMobj_pos
les   di, dword ptr ds:[bx]
mov   bx, _player + PLAYER_T.player_viewzvalue
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
mov   word ptr ds:[bx], dx
mov   di, _player + PLAYER_T.player_viewzvalue + 2
mov   word ptr ds:[bx + 2], ax
add   word ptr ds:[di], VIEWHEIGHT_HIGHBITS
mov   ax, word ptr ds:[bx + 2]
cmp   si, ax
jl    label_5
jne   label_6
mov   ax, word ptr ds:[bx]
cmp   ax, word ptr [bp - 2]
jbe   label_6
label_5:
mov   ax, word ptr [bp - 2]
mov   word ptr ds:[bx + 2], si
mov   word ptr ds:[bx], ax
label_6:
mov   bx, _playerMobj_pos
les   di, dword ptr ds:[bx]
mov   si, _player + PLAYER_T.player_viewheightvalue
mov   bx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
add   bx, word ptr ds:[si]
adc   ax, word ptr ds:[si + 2]
mov   si, _player + PLAYER_T.player_viewzvalue
mov   word ptr ds:[si], bx
mov   word ptr ds:[si + 2], ax
exit_p_calcheight:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  
label_4:
mov   bx, _leveltime
mov   ax,   (FINEANGLES/20)
mul   word ptr ds:[bx]
xchg  ax, dx
;imul  dx, word ptr ds:[bx], 409   ; 409 = (FINEANGLES/20)
mov   bx, _player + PLAYER_T.player_bob
mov   ax, word ptr ds:[bx]
mov   cx, word ptr ds:[bx + 2]
sar   cx, 1
rcr   ax, 1
and   dh, (FINEMASK SHR 8)
mov   bx, ax
mov   ax, FINESINE_SEGMENT
call  FixedMulTrig_
mov   bx, _player + PLAYER_T.player_playerstate
mov   cx, ax
mov   word ptr [bp - 4], dx
cmp   byte ptr ds:[bx], 0
je    label_7
jmp   label_8
label_7:
mov   di, _player + PLAYER_T.player_deltaviewheight
mov   bx, _player + PLAYER_T.player_viewheightvalue
mov   ax, word ptr ds:[di]
mov   dx, word ptr ds:[di + 2]
add   word ptr ds:[bx], ax
adc   word ptr ds:[bx + 2], dx
mov   ax, word ptr ds:[bx + 2]
cmp   ax, VIEWHEIGHT_HIGHBITS
jg    label_9
jne   label_10
cmp   word ptr ds:[bx], 0
jbe   label_10
label_9:
mov   word ptr ds:[bx], 0
mov   word ptr ds:[bx + 2], VIEWHEIGHT_HIGHBITS
mov   word ptr ds:[di], 0
mov   word ptr ds:[di + 2], 0
label_10:
mov   bx, _player + PLAYER_T.player_viewheightvalue
mov   ax, word ptr ds:[bx + 2]
cmp   ax, VIEWHEIGHT_HIGHBITS/2  ; 20
jl    label_11
jne   label_12
cmp   word ptr ds:[bx], 08000h   ;  VIEWHEIGHT_HIGHBITS / 2 fractional part
jae   label_12
label_11:
mov   word ptr ds:[bx], 08000h  ;  VIEWHEIGHT_HIGHBITS / 2 fractional part
mov   word ptr ds:[bx + 2], VIEWHEIGHT_HIGHBITS/2 ; 20
mov   bx, _player + PLAYER_T.player_deltaviewheight
mov   ax, word ptr ds:[bx + 2]
test  ax, ax
jge   label_13
jmp   label_14
label_13:
jne   label_12
cmp   word ptr ds:[bx], 0
jbe   label_14
label_12:
mov   bx, _player + PLAYER_T.player_deltaviewheight
mov   ax, word ptr ds:[bx + 2]
or    ax, word ptr ds:[bx]
je    label_8
add   word ptr ds:[bx], 04000h  ; FRACUNIT / 4
adc   word ptr ds:[bx + 2], 0
mov   ax, word ptr ds:[bx + 2]
or    ax, word ptr ds:[bx]
jne   label_8
mov   word ptr ds:[bx], 1
mov   word ptr ds:[bx + 2], ax
label_8:
mov   bx, _playerMobj_pos
les   di, dword ptr ds:[bx]
mov   dx, _player + PLAYER_T.player_viewheightvalue
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
mov   bx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
mov   di, dx
mov   dx, ax
add   dx, word ptr ds:[di]
adc   bx, word ptr ds:[di + 2]
add   dx, cx
mov   ax, word ptr [bp - 4]
adc   ax, bx
mov   bx, _player + PLAYER_T.player_viewzvalue
mov   word ptr ds:[bx], dx
mov   word ptr ds:[bx + 2], ax
cmp   si, ax
jl    label_15
je    label_16
jump_to_exit_p_calcheight:
jmp   exit_p_calcheight
label_16:
mov   ax, word ptr ds:[bx]
cmp   ax, word ptr [bp - 2]
jbe   jump_to_exit_p_calcheight
label_15:
mov   ax, word ptr [bp - 2]
mov   word ptr ds:[bx + 2], si
mov   word ptr ds:[bx], ax
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  
label_14:
mov   word ptr ds:[bx], 1
mov   word ptr ds:[bx + 2], 0
jmp   label_12


ENDP


PROC    P_MovePlayer_ NEAR
PUBLIC  P_MovePlayer_

push  bx
push  cx
push  dx
push  si
push  di
mov   si, _player
mov   di, _playerMobj_pos
mov   ax, word ptr ds:[si + PLAYER_T.player_cmd_angleturn]
les   bx, dword ptr ds:[di]
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], 0
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   ax, word ptr ds:[bx + 6]
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   dx, word ptr ds:[bx + 6]
sar   ax, 3
xor   dh, dh
mov   bx, word ptr ds:[di]
and   dl, 7
mov   es, word ptr ds:[di + 2]
shl   dx, 13
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
jg    label_17
je    label_18
jump_to_label_19:
jmp   label_19
label_18:
cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 8]
jb    jump_to_label_19
label_17:
mov   al, 1
label_22:
mov   byte ptr ds:[_onground], al
cmp   byte ptr ds:[si + PLAYER_T.player_cmd_forwardmove], 0
je    label_20
test  al, al
je    label_20
mov   al, byte ptr ds:[si + PLAYER_T.player_cmd_forwardmove]
mov   bx, _playerMobj_pos
cbw  
les   di, dword ptr ds:[bx]
cwd   
mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
mov   bx, ax
shr   di, 3
mov   cx, dx
mov   ax, di

call  P_Thrust_
label_20:
cmp   byte ptr ds:[si + PLAYER_T.player_cmd_sidemove], 0
je    label_21
cmp   byte ptr ds:[_onground], 0
je    label_21
mov   bx, _playerMobj_pos
mov   al, byte ptr ds:[si + PLAYER_T.player_cmd_sidemove]
les   di, dword ptr ds:[bx]
mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
cbw  
shr   di, SHORTTOFINESHIFT
cwd   
sub   di, FINE_ANG90
mov   bx, ax
and   di, FINEMASK
mov   cx, dx
mov   ax, di

call  P_Thrust_
label_21:
cmp   byte ptr ds:[si + PLAYER_T.player_cmd_forwardmove], 0
je    label_77
label_23:
mov   bx, _playerMobj_pos
les   si, dword ptr ds:[bx]
cmp   word ptr es:[si + MOBJ_POS_T.mp_statenum], S_PLAY
je    label_78
label_24:
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  
label_19:
xor   al, al
jmp   label_22
label_77:
cmp   byte ptr ds:[si + 1], 0
jne   label_23
jmp   label_24
label_78:
mov   bx, _playerMobj
mov   dx, S_PLAY_RUN1
mov   ax, word ptr ds:[bx]
call  word ptr ds:[_P_SetMobjState]
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  


ENDP

; ANG5   ANG90/18

ANG5_HIGH = 038Eh
ANG5_LOW  = 038E3h

NEG_ANG5_HIGH = 0FC71h
NEG_ANG5_LOW  = 0C71Dh



PROC    P_DeathThink_ NEAR
PUBLIC  P_DeathThink_

push  bx
push  cx
push  dx
push  si
push  di
mov   bx, _player + PLAYER_T.player_viewheightvalue
call  word ptr ds:[_P_MovePsprites]
mov   ax, word ptr ds:[bx + 2]
cmp   ax, 6
jg    label_25
jne   label_26
cmp   word ptr ds:[bx], 0
jbe   label_26
label_25:
mov   bx, _player + PLAYER_T.player_viewheightvalue + 2
dec   word ptr ds:[bx]
label_26:
mov   bx, _player + PLAYER_T.player_viewheightvalue + 0
mov   ax, word ptr ds:[bx + 2]
cmp   ax, 6
jge   label_27
jmp   label_28
label_27:
mov   bx, _player + PLAYER_T.player_deltaviewheight
mov   word ptr ds:[bx], 0
mov   word ptr ds:[bx + 2], 0
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   ax, word ptr ds:[bx + 6]
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   si, _playerMobj_pos
mov   dx, word ptr ds:[bx + 6]
sar   ax, 3
xor   dh, dh
mov   bx, word ptr ds:[si]
and   dl, 7
mov   es, word ptr ds:[si + 2]
shl   dx, 13
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
jg    label_29
je    label_30
jump_to_label_31:
jmp   label_31
label_30:
cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
jb    jump_to_label_31
label_29:
mov   al, 1
label_39:
mov   bx, _player + PLAYER_T.player_attackerRef
mov   byte ptr ds:[_onground], al

call  P_CalcHeight_
mov   ax, word ptr ds:[bx]
test  ax, ax
jne   label_32
jump_to_label_33:
jmp   label_33
label_32:
mov   si, _playerMobjRef
cmp   ax, word ptr ds:[si]
je    jump_to_label_33
mov   bx, _useDeadAttackerRef
cmp   byte ptr ds:[bx], 0
je    jump_to_label_34
mov   bx, _deadAttackerY
push  word ptr ds:[bx + 2]
push  word ptr ds:[bx]
mov   bx, _deadAttackerX
push  word ptr ds:[bx + 2]
push  word ptr ds:[bx]
mov   bx, _playerMobj_pos
les   si, dword ptr ds:[bx]
mov   bx, word ptr es:[si + 4]
mov   cx, word ptr es:[si + 6]
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
label_40:
call  R_PointToAngle2_
mov   bx, ax
mov   si, _playerMobj_pos
les   di, dword ptr ds:[si]
mov   cx, bx
sub   cx, word ptr es:[di + MOBJ_POS_T.mp_angle + 0]
mov   ax, dx
sbb   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
cmp   ax, ANG5_HIGH
jb    label_35
jne   jump_to_label_36
cmp   cx, ANG5_LOW
jae   jump_to_label_36
label_35:
mov   di, _playerMobj_pos
les   si, dword ptr ds:[di]
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], bx
mov   bx, _player + PLAYER_T.player_damagecount
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], dx
label_43:
cmp   word ptr ds:[bx], 0
je    label_37
dec   word ptr ds:[bx]
label_37:
mov   bx, _player + PLAYER_T.player_cmd_buttons
test  byte ptr ds:[bx], 2
jne   jump_to_label_38
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  
jump_to_label_34:
jmp   label_34
label_28:
mov   word ptr ds:[bx], 0
mov   word ptr ds:[bx + 2], 6
jmp   label_27
label_31:
xor   al, al
jmp   label_39
jump_to_label_36:
jmp   label_36
label_34:
mov   bx, _player + PLAYER_T.player_attackerRef
imul  bx, word ptr ds:[bx], SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
push  word ptr es:[bx + 6]
push  word ptr es:[bx + 4]
push  word ptr es:[bx + 2]
push  word ptr es:[bx]
mov   bx, _playerMobj_pos
les   si, dword ptr ds:[bx]
mov   ax, word ptr es:[si + 4]
mov   cx, word ptr es:[si + 6]
mov   si, bx
mov   bx, word ptr ds:[bx]
mov   es, word ptr ds:[si + 2]
mov   si, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
mov   bx, ax
mov   ax, si
jmp   label_40
jump_to_label_38:
jmp   label_38
label_36:
cmp   ax, NEG_ANG5_HIGH
ja    label_35
jne   label_41
cmp   cx, NEG_ANG5_LOW
jbe   label_41
jmp   label_35
label_41:
cmp   ax, ANG180_HIGHBITS
jae   label_42
mov   bx, di
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ANG5_LOW
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], ANG5_HIGH
jmp   label_37
label_42:
mov   bx, di
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], NEG_ANG5_LOW
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], NEG_ANG5_HIGH
jmp   label_37
label_33:
mov   bx, _player + PLAYER_T.player_damagecount
jmp   label_43
label_38:
mov   bx, _player + PLAYER_T.player_playerstate
mov   byte ptr ds:[bx], 2
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  


ENDP


PROC    P_PlayerThink_ NEAR
PUBLIC  P_PlayerThink_


push  bx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   word ptr [bp - 4], P_USELINES_OFFSET
mov   bx, _player + PLAYER_T.player_cheats
mov   word ptr [bp - 2], PHYSICS_HIGHCODE_SEGMENT
test  byte ptr ds:[bx], CF_NOCLIP
je    label_48
jmp   label_49
label_48:
mov   si, _playerMobj_pos
les   bx, dword ptr ds:[si]
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1 + 1], (NOT (MF_NOCLIP SHR 8))
label_44:
mov   si, _playerMobj_pos
les   di, dword ptr ds:[si]
mov   bx, _player
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
je    label_45
mov   word ptr ds:[bx + PLAYER_T.player_cmd_angleturn], 0  ; two two byte writes of 0... ok?
mov   word ptr ds:[bx], 100
mov   di, si
mov   si, word ptr ds:[si]
mov   es, word ptr ds:[di + 2]
and   byte ptr es:[si + MOBJ_POS_T.mp_flags1 + 1], (NOT MF_JUSTATTACKED)
label_45:
mov   si, _player + PLAYER_T.player_playerstate
cmp   byte ptr ds:[si], PST_DEAD
jne   label_46
jmp   label_47
label_46:
mov   si, _playerMobj
mov   si, word ptr ds:[si]
cmp   byte ptr ds:[si + MOBJ_T.m_reactiontime], 0
jne   label_50
jmp   label_51
label_50:
mov   si, _playerMobj
mov   si, word ptr ds:[si]
dec   byte ptr ds:[si + MOBJ_T.m_reactiontime]
label_52:
mov   si, _playerMobj

call  P_CalcHeight_
mov   si, word ptr ds:[si]
mov   ax, word ptr ds:[si + 4]
shl   ax, 4
mov   si, ax
add   si, _sectors_physics + SECTOR_PHYSICS_T.secp_special
cmp   byte ptr ds:[si], 0
je    label_53
call  P_PlayerInSpecialSector_
label_53:
mov   al, byte ptr ds:[bx + PLAYER_T.player_cmd_buttons]
test  al, BT_SPECIAL
jne   label_54
jmp   label_55
label_54:
mov   byte ptr ds:[bx + PLAYER_T.player_cmd_buttons], 0
label_67:
mov   bx, _player + PLAYER_T.player_usedown
mov   byte ptr ds:[bx], 0
label_63:
mov   bx, _player + PLAYER_T.player_powers + (PW_STRENGTH * 2)
call  word ptr ds:[_P_MovePsprites]
cmp   word ptr ds:[bx], 0
je    label_64
inc   word ptr ds:[bx]
label_64:
mov   bx, _player + PLAYER_T.player_powers + (PW_INVULNERABILITY * 2)
cmp   word ptr ds:[bx], 0
je    label_65
dec   word ptr ds:[bx]
label_65:
mov   bx, _player + PLAYER_T.player_powers + (PW_INVISIBILITY * 2)
cmp   word ptr ds:[bx], 0
je    label_75
dec   word ptr ds:[bx]
jne   label_75
mov   si, _playerMobj_pos
les   bx, dword ptr ds:[si]
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags2], (NOT MF_SHADOW)
label_75:
mov   bx, _player + PLAYER_T.player_powers + (PW_INFRARED * 2)
cmp   word ptr ds:[bx], 0
je    label_76
dec   word ptr ds:[bx]
label_76:
mov   bx, _player + PLAYER_T.player_powers + (PW_IRONFEET * 2)
cmp   word ptr ds:[bx], 0
je    label_74
dec   word ptr ds:[bx]
label_74:
mov   bx, _player + PLAYER_T.player_damagecount
cmp   word ptr ds:[bx], 0
je    label_79
dec   word ptr ds:[bx]
label_79:
mov   bx, _player + PLAYER_T.player_bonuscount
cmp   byte ptr ds:[bx], 0
je    label_80
dec   byte ptr ds:[bx]
label_80:
mov   bx, _player + PLAYER_T.player_fixedcolormapvalue
mov   byte ptr ds:[bx], 0
mov   bx, _player + PLAYER_T.player_powers + (PW_INVULNERABILITY * 2)
mov   ax, word ptr ds:[bx]
test  ax, ax
je    jump_to_label_73
cmp   ax, (4 * 32)
jg    label_74
test  byte ptr ds:[bx], 8
jne   label_74
exit_player_think:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   bx
ret   
label_49:
mov   si, _playerMobj_pos
les   bx, dword ptr ds:[si]
or    byte ptr es:[bx + MOBJ_POS_T.mp_flags1 + 1], (MF_NOCLIP SHR 8)
jmp   label_44
label_47:

call  P_DeathThink_
jmp   exit_player_think
label_51:

call  P_MovePlayer_
jmp   label_52
jump_to_label_73:
jmp   label_73
label_74:
mov   bx, _player + PLAYER_T.player_fixedcolormapvalue
mov   byte ptr ds:[bx], INVERSECOLORMAP
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   bx
ret   
label_55:
test  al, 4
jne   label_56
jmp   label_57
label_56:
and   al, BT_WEAPONMASK  ; 8 + 16 + 32
xor   ah, ah
mov   dx, ax
sar   dx, 3
mov   al, dl
test  dl, dl
jne   label_62
mov   si, _player + PLAYER_T.player_weaponowned + WP_CHAINSAW
cmp   byte ptr ds:[si], 0
je    label_62
mov   si, _player + PLAYER_T.player_readyweapon
cmp   byte ptr ds:[si], 7
je    label_70
jmp   label_71
label_70:
mov   si, _player + PLAYER_T.player_powers + (PW_STRENGTH * 2)
cmp   word ptr ds:[si], 0
je    label_71
label_62:
mov   si, _commercial
cmp   byte ptr ds:[si], 0
je    label_69
cmp   al, 2
jne   label_69
mov   si, _player + PLAYER_T.player_weaponowned + WP_SUPERSHOTGUN
cmp   byte ptr ds:[si], 0
je    label_69
mov   si, _player + PLAYER_T.player_readyweapon
cmp   byte ptr ds:[si], 8
je    label_69
mov   al, 8
label_69:
mov   dl, al
xor   dh, dh
mov   si, dx
cmp   byte ptr ds:[si + _player + PLAYER_T.player_weaponowned], 0
je    label_57
mov   si, _player + PLAYER_T.player_readyweapon
cmp   al, byte ptr ds:[si]
je    label_57
cmp   al, 5
je    label_68
cmp   al, 6
je    label_68
label_61:
mov   si, _player + PLAYER_T.player_pendingweapon
mov   byte ptr ds:[si], al
label_57:
test  byte ptr ds:[bx + 7], 2
jne   label_66
jmp   label_67
label_66:
mov   bx, _player PLAYER_T.player_usedown
cmp   byte ptr ds:[bx], 0
je    label_72
jmp   label_63
label_72:
lcall [bp - 4]
mov   byte ptr ds:[bx], 1
jmp   label_63
label_71:
mov   al, 7
jmp   label_62
label_68:
mov   si, _shareware
cmp   byte ptr ds:[si], 0
je    label_61
jmp   label_57
label_73:
mov   bx, _player + PLAYER_T.player_powers + (PW_INFRARED * 2)
mov   ax, word ptr ds:[bx]
test  ax, ax
jne   label_60
label_58:
jmp   exit_player_think
label_60:
cmp   ax, (4 * 32)
jg    label_59
test  byte ptr ds:[bx], 8
je    label_58
label_59:
mov   bx, _player + PLAYER_T.player_fixedcolormapvalue
mov   byte ptr ds:[bx], 1
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   bx
ret   

ENDP


PROC    P_USER_ENDMARKER_ NEAR
PUBLIC  P_USER_ENDMARKER_
ENDP

END
