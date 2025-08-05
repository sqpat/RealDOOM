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
EXTRN S_StartSound_:PROC
EXTRN P_RemoveThinker_:PROC
EXTRN _P_ChangeSector:DWORD
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR
EXTRN T_MovePlaneCeilingUp_:NEAR
EXTRN T_MovePlaneCeilingDown_:NEAR

SHORTFLOORBITS = 3

.DATA




.CODE





PROC    P_DOORS_STARTMARKER_ NEAR
PUBLIC  P_DOORS_STARTMARKER_
ENDP

_jump_table_vertical_door:
dw switch_case_verticaldoor_1_case_0, switch_case_verticaldoor_1_case_1, switch_case_verticaldoor_1_case_2, switch_case_verticaldoor_1_case_3
_jump_table_vertical_door_2:


dw switch_case_verticaldoor_2_doornormal, switch_case_verticaldoor_2_doorclose30thenopen, switch_case_verticaldoor_2_doorclose, switch_case_verticaldoor_2_default
dw switch_case_verticaldoor_2_default, switch_case_verticaldoor_2_blazeraise, switch_case_verticaldoor_2_default, switch_case_verticaldoor_2_blazeclose

_jump_table_vertical_door_3:
dw switch_case_verticaldoor_3_doornormal, switch_case_verticaldoor_3_doorclose30thenopen, switch_case_verticaldoor_3_default, switch_case_verticaldoor_3_dooropen
dw switch_case_verticaldoor_3_default, switch_case_verticaldoor_3_doorraisein5mins, switch_case_verticaldoor_3_doorblazeopen

DOOR_NORMAL = 00h
DOOR_CLOSE30THENOPEN = 01h
DOOR_CLOSE = 02h
DOOR_OPEN = 03h
DOOR_RAISEIN5MINS = 04h
DOOR_BLAZERAISE = 05h
DOOR_BLAZEOPEN = 06h
DOOR_BLAZECLOSE = 07h


PROC    T_VerticalDoor_ NEAR
PUBLIC  T_VerticalDoor_

;void __near T_VerticalDoor (vldoor_t __near* door, THINKERREF doorRef) {

; bp - 2 doorref
; bp - 4 vldoor secnum shl 4



PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
push  dx
mov   si, ax
mov   di, word ptr ds:[si + VLDOOR_T.vldoor_secnum]
mov   ax, SECTORS_SEGMENT
mov   bx, di
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
SHIFT_MACRO shl   bx 4
push  bx
mov   bx, word ptr ds:[si + VLDOOR_T.vldoor_direction]
inc   bx
cmp   bx, 3
ja    exit_t_verticaldoor
sal   bx, 1



jmp   word ptr cs:[bx + _jump_table_vertical_door]

switch_case_verticaldoor_1_case_0:
mov   bx, word ptr [bp - 4]
mov   ax, word ptr [bp - 4]
mov   dx, word ptr ds:[si + VLDOOR_T.vldoor_speed]
xor   cx, cx
mov   bx, word ptr es:[bx]
call  T_MovePlaneCeilingDown_
cmp   al, 2
je    label_2
cmp   al, 1
jne   exit_t_verticaldoor

mov   al, byte ptr ds:[si]
cmp   al, 7
je    exit_t_verticaldoor
cmp   al, 2
je    exit_t_verticaldoor
mov   dx, SFX_DOROPN
mov   ax, di
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1

jmp   call_sound_and_exit
label_2:
mov   al, byte ptr ds:[si]
cmp   al, 7
ja    exit_t_verticaldoor
xor   ah, ah
mov   bx, ax
add   bx, ax
jmp   word ptr cs:[bx + _jump_table_vertical_door_2]
switch_case_verticaldoor_2_doornormal:
switch_case_verticaldoor_2_doorclose:
switch_case_verticaldoor_3_doorclose30thenopen:
switch_case_verticaldoor_3_dooropen:
switch_case_verticaldoor_3_doorblazeopen:
mov   bx, word ptr ds:[si + VLDOOR_T.vldoor_secnum]
shl   bx, 4
xor   ax, ax


mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov   ax, word ptr [bp - 2]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef

call  P_RemoveThinker_
exit_t_verticaldoor:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

switch_case_verticaldoor_1_case_1:

dec   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown]
jne   exit_t_verticaldoor_2
mov   al, byte ptr ds:[si]
cmp   al, 5
je    label_3
cmp   al, 1
je    label_4
test  al, al
jne   exit_t_verticaldoor_2
mov   dx, SFX_DORCLS
mov   ax, di
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1

jmp   call_sound_and_exit

label_3:
mov   dx, SFX_BDCLS
mov   ax, di
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1

jmp   call_sound_and_exit
ret   
label_4:
mov   dx, SFX_DOROPN
mov   ax, di
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1

jmp   call_sound_and_exit
switch_case_verticaldoor_1_case_3:
dec   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown]
jne   exit_t_verticaldoor_2
mov   al, byte ptr ds:[si]
cmp   al, 4
jne   exit_t_verticaldoor_2
mov   dx, SFX_DOROPN
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1
mov   ax, di
mov   byte ptr ds:[si], 0
jmp   call_sound_and_exit
ret   
switch_case_verticaldoor_2_blazeraise:
switch_case_verticaldoor_2_blazeclose:
mov   bx, word ptr ds:[si + VLDOOR_T.vldoor_secnum]
shl   bx, 4

xor   ax, ax

mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov   ax, word ptr [bp - 2]
mov   dx, SFX_BDCLS

call  P_RemoveThinker_
mov   ax, di
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef

call_sound_and_exit:
call  S_StartSoundWithParams_
switch_case_verticaldoor_2_default:
switch_case_verticaldoor_3_default:
exit_t_verticaldoor_2:   
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   
switch_case_verticaldoor_2_doorclose30thenopen:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 0
mov   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown], 35 * 30
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   

switch_case_verticaldoor_1_case_2:

mov   ax, word ptr [bp - 4]
mov   bx, word ptr ds:[si + VLDOOR_T.vldoor_topheight]
mov   dx, word ptr ds:[si + VLDOOR_T.vldoor_speed]
xor   cx, cx
call  T_MovePlaneCeilingUp_
cmp   al, 2
jne   exit_t_verticaldoor_2
mov   al, byte ptr ds:[si]
cmp   al, 6
ja    exit_t_verticaldoor_2
xor   ah, ah
mov   bx, ax
add   bx, ax
jmp   word ptr cs:[bx + _jump_table_vertical_door_3]
switch_case_verticaldoor_3_doornormal:
switch_case_verticaldoor_3_doorraisein5mins:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 0
mov   ax, word ptr ds:[si + VLDOOR_T.vldoor_topwait]
mov   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown], ax
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

ENDP

PROC    EV_DoLockedDoor_ NEAR
PUBLIC  EV_DoLockedDoor_

push  si
push  bp
mov   bp, sp
sub   sp, 2
mov   byte ptr [bp - 2], al
mov   ax, dx
mov   si, _playerMobjRef
cmp   cx, word ptr ds:[si]
jne   label_5
cmp   dx, 133
jae   label_6
cmp   dx, 99
jne   label_7
label_9:
mov   si, _player + PLAYER_T.player_cards + IT_BLUECARD
cmp   byte ptr ds:[si], 0
jne   label_7
mov   si, _player + PLAYER_T.player_cards + IT_BLUESKULL
mov   al, byte ptr ds:[si]
test  al, al
jne   label_7
mov   bx, _player + PLAYER_T.player_message
mov   dx, SFX_OOF
xor   ah, ah
mov   word ptr ds:[bx], PD_BLUEO
label_11:

call  S_StartSound_
xor   ax, ax
LEAVE_MACRO 
pop   si
ret   
label_5:
xor   ax, dx
LEAVE_MACRO 
pop   si
ret   
label_6:
jbe   label_9
cmp   dx, 135
ja    label_10
mov   si, _player + PLAYER_T.player_cards + IT_REDCARD
cmp   byte ptr ds:[si], 0
jne   label_8
mov   si, _player + PLAYER_T.player_cards + IT_REDSKULL
mov   al, byte ptr ds:[si]
test  al, al
jne   label_8
mov   bx, _player + PLAYER_T.player_message
mov   dx, SFX_OOF
xor   ah, ah
mov   word ptr ds:[bx], PD_REDO
jmp   label_11
label_7:
jmp   label_8
label_10:
cmp   dx, 137
ja    label_8
mov   si, _player + PLAYER_T.player_cards + IT_YELLOWCARD
cmp   byte ptr ds:[si], 0
jne   label_8
mov   si, _player + PLAYER_T.player_cards + IT_YELLOWSKULL
mov   al, byte ptr ds:[si]
test  al, al
jne   label_8
mov   bx, _player + PLAYER_T.player_message
mov   dx, SFX_OOF
xor   ah, ah
mov   word ptr ds:[bx], PD_YELLOWO

call  S_StartSound_
   
xor   ax, ax
LEAVE_MACRO 
pop   si
ret   
label_8:
mov   dl, byte ptr [bp - 2]
mov   al, bl
xor   dh, dh
cbw  
mov   bx, dx
mov   dx, ax
mov   ax, bx

call  EV_DoDoor_
LEAVE_MACRO 
pop   si
ret   


_jump_table_do_door:
dw switch_block_ev_dodoor_case_doornormal, switch_block_ev_dodoor_case_doorclose30thenopen, switch_block_ev_dodoor_case_doorclose, switch_block_ev_dodoor_case_dooropen
dw switch_block_ev_dodoor_case_doorraisein5mins, switch_block_ev_dodoor_case_doorblazeraise, switch_block_ev_dodoor_case_doorblazeopen, switch_block_ev_dodoor_case_doorblazeclose


ENDP


PROC    EV_DoDoor_ NEAR
PUBLIC  EV_DoDoor_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 020Ch
mov   byte ptr [bp - 2], dl
mov   word ptr [bp - 0Ch], 0
lea   dx, [bp - 020Ch]
cbw  
xor   bx, bx
mov   word ptr [bp - 6], 0
call  P_FindSectorsFromLineTag_
cmp   word ptr [bp - 020Ch], 0
jl    label_12
label_14:
mov   si, word ptr [bp - 6]
mov   ax, TF_VERTICALDOOR_HIGHBITS
mov   di, SIZEOF_THINKER_T
xor   dx, dx
mov   bx, word ptr [bp + si - 020Ch]

call  P_CreateThinker_
   
mov   si, ax
mov   word ptr [bp - 4], ax
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   di
mov   word ptr [bp - 0Ch], 1
mov   cx, bx
mov   word ptr [bp - 8], SECTORS_SEGMENT
shl   cx, 4
mov   di, cx
add   word ptr [bp - 6], 2
mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov   word ptr [bp - 0Ah], cx
mov   word ptr ds:[si + VLDOOR_T.vldoor_topwait], VDOORWAIT
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED
mov   al, byte ptr [bp - 2]
mov   word ptr ds:[si + VLDOOR_T.vldoor_secnum], bx
add   di, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
mov   byte ptr ds:[si], al
cmp   al, 7
ja    label_15
xor   ah, ah
mov   di, ax
add   di, ax
jmp   word ptr cs:[di + _jump_table_do_door]
label_12:
jmp   label_13
switch_block_ev_dodoor_case_doornormal:
switch_block_ev_dodoor_case_dooropen:
mov   si, word ptr [bp - 4]
mov   ax, bx
xor   dx, dx
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1
call  P_FindLowestOrHighestCeilingSurrounding_
sub   ax, (4 SHL SHORTFLOORBITS)
mov   word ptr ds:[si + VLDOOR_T.vldoor_topheight], ax
les   si, dword ptr [bp - 0Ah]
cmp   ax, word ptr es:[si + 2]
je    label_15
mov   dx, SFX_DOROPN
label_18:
mov   ax, bx
label_16:
call  S_StartSoundWithParams_
label_15:
switch_block_ev_dodoor_case_doorraisein5mins:
mov   si, word ptr [bp - 6]
cmp   word ptr [bp + si - 020Ch], 0
jl    label_13
jmp   label_14
label_13:
mov   ax, word ptr [bp - 0Ch]
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
retf  
switch_block_ev_dodoor_case_doorblazeclose:
mov   ax, bx
xor   dx, dx
call  P_FindLowestOrHighestCeilingSurrounding_
sub   ax, (4 SHL SHORTFLOORBITS)
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1
mov   dx, SFX_BDCLS
mov   word ptr ds:[si + VLDOOR_T.vldoor_topheight], ax
mov   ax, bx
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED*4
jmp   label_16
switch_block_ev_dodoor_case_doorclose:
mov   ax, bx
xor   dx, dx
call  P_FindLowestOrHighestCeilingSurrounding_
sub   ax, (4 SHL SHORTFLOORBITS)
mov   dx, SFX_DORCLS
mov   word ptr ds:[si + VLDOOR_T.vldoor_topheight], ax
mov   ax, bx
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1
jmp   label_16
switch_block_ev_dodoor_case_doorclose30thenopen:
mov   es, word ptr [bp - 8]
mov   di, cx
mov   ax, word ptr es:[di + 2]
mov   dx, SFX_DORCLS
mov   word ptr ds:[si + VLDOOR_T.vldoor_topheight], ax
mov   ax, bx
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1
jmp   label_16
switch_block_ev_dodoor_case_doorblazeraise:
switch_block_ev_dodoor_case_doorblazeopen:
mov   si, word ptr [bp - 4]
mov   ax, bx
xor   dx, dx
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1
call  P_FindLowestOrHighestCeilingSurrounding_
sub   ax, (4 SHL SHORTFLOORBITS)
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED*4
mov   word ptr ds:[si + VLDOOR_T.vldoor_topheight], ax
mov   ax, word ptr ds:[si + VLDOOR_T.vldoor_topheight]
les   si, dword ptr [bp - 0Ah]
cmp   ax, word ptr es:[si + 2]
jne   label_17
jmp   label_15
label_17:
mov   dx, SFX_BDOPN
jmp   label_18

_jump_table_locked_door:
dw switch_block_verticaldoor_case_26, switch_block_verticaldoor_case_27, switch_block_verticaldoor_case_28, switch_block_verticaldoor_case_default
dw switch_block_verticaldoor_case_default, switch_block_verticaldoor_case_default, switch_block_verticaldoor_case_32, switch_block_verticaldoor_case_33
dw switch_block_verticaldoor_case_34



ENDP

PROC    EV_VerticalDoor_ NEAR
PUBLIC  EV_VerticalDoor_

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
push  ax
mov   ax, dx
mov   bx, word ptr [bp - 4]
mov   cx, LINES_PHYSICS_SEGMENT
shl   bx, 4
mov   es, cx
mov   cl, byte ptr es:[bx + LINE_PHYSICS_T.lp_special]
add   bx, LINE_PHYSICS_T.lp_special
xor   ch, ch
mov   bx, cx
sub   cx, 26
cmp   cx, 8
ja    switch_block_verticaldoor_case_default
mov   si, cx
add   si, cx
jmp   word ptr cs:[si + _jump_table_locked_door]
switch_block_verticaldoor_case_26:
switch_block_verticaldoor_case_32:
mov   si, _playerMobjRef
cmp   ax, word ptr ds:[si]
jne   exit_ev_verticaldoor
mov   si, _player + PLAYER_T.player_cards + IT_BLUECARD
cmp   byte ptr ds:[si], 0
jne   done_with_verticaldoor_switch_block
mov   si, _player + PLAYER_T.player_cards + IT_BLUESKULL
cmp   byte ptr ds:[si], 0
je    label_40
done_with_verticaldoor_switch_block:
switch_block_verticaldoor_case_default:

mov   si, word ptr [bp - 4]
mov   cx, LINES_PHYSICS_SEGMENT
shl   si, 4
mov   es, cx
mov   cx, word ptr es:[si + LINE_PHYSICS_T.lp_backsecnum]
add   si, LINE_PHYSICS_T.lp_backsecnum
mov   si, cx
shl   si, 4
add   si, _sectors_physics
cmp   word ptr ds:[si + 8], 0
je    jump_to_label_25
mov   si, word ptr ds:[si + 8]
imul  si, si, SIZEOF_THINKER_T
add   si, (_thinkerlist + THINKER_T.t_data)
cmp   bx, 117
jne   jump_to_label_36
label_24:
cmp   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1
je    jump_to_label_37
mov   bx, _playerMobjRef
cmp   ax, word ptr ds:[bx]
je    jump_to_label_41
exit_ev_verticaldoor:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_40:
mov   bx, _player + PLAYER_T.player_message
mov   dx, SFX_OOF
xor   ax, ax
mov   word ptr ds:[bx], PD_BLUEK

call  S_StartSound_
   
jmp   exit_ev_verticaldoor
switch_block_verticaldoor_case_27:
switch_block_verticaldoor_case_34:
mov   si, _playerMobjRef
cmp   ax, word ptr ds:[si]
jne   exit_ev_verticaldoor
mov   si, _player + PLAYER_T.player_cards + IT_YELLOWCARD
cmp   byte ptr ds:[si], 0
jne   done_with_verticaldoor_switch_block
mov   si, _player + PLAYER_T.player_cards + IT_YELLOWSKULL
cmp   byte ptr ds:[si], 0
jne   done_with_verticaldoor_switch_block
mov   bx, _player + PLAYER_T.player_message
mov   dx, SFX_OOF
xor   ax, ax
mov   word ptr ds:[bx], PD_YELLOWK

call  S_StartSound_
   
jmp   exit_ev_verticaldoor
jump_to_label_25:
jmp   label_25
jump_to_label_36:
jmp   label_36
jump_to_label_37:
jmp   label_37
jump_to_label_41:
jmp   label_41
switch_block_verticaldoor_case_28:
switch_block_verticaldoor_case_33:
mov   si, _playerMobjRef
cmp   ax, word ptr ds:[si]
jne   exit_ev_verticaldoor
mov   si, _player + PLAYER_T.player_cards + IT_REDCARD
cmp   byte ptr ds:[si], 0
je    label_38
jump_to_done_with_verticaldoor_switch_block:
jmp   done_with_verticaldoor_switch_block
label_38:
mov   si, _player + PLAYER_T.player_cards + IT_REDSKULL
cmp   byte ptr ds:[si], 0
jne   jump_to_done_with_verticaldoor_switch_block
mov   bx, _player + PLAYER_T.player_message
mov   dx, SFX_OOF
xor   ax, ax
mov   word ptr ds:[bx], VDOORSPEED*4

call  S_StartSound_
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_36:
cmp   bx, 1
jae   label_26
label_25:
cmp   bx, 31
jae   label_21
cmp   bx, 1
label_20:
mov   dx, SFX_DOROPN
label_28:
mov   ax, cx

call  S_StartSoundWithParams_
   
mov   ax, TF_VERTICALDOOR_HIGHBITS
mov   di, SIZEOF_THINKER_T

call  P_CreateThinker_
xor   dx, dx
mov   si, ax
mov   word ptr [bp - 2], ax
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   di
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED
mov   di, cx
mov   word ptr ds:[si + VLDOOR_T.vldoor_topwait], VDOORWAIT
shl   di, 4
mov   word ptr ds:[si + VLDOOR_T.vldoor_secnum], cx
mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
add   di, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
cmp   bx, 31
jae   label_33
cmp   bx, 1
jb    label_31
ja    jump_to_label_29
label_32:
mov   bx, word ptr [bp - 2]
mov   byte ptr ds:[bx], 0
label_31:
mov   ax, cx
xor   dx, dx
mov   bx, word ptr [bp - 2]
call  P_FindLowestOrHighestCeilingSurrounding_
sub   ax, (4 SHL SHORTFLOORBITS)
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topheight], ax
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_21:
jmp   label_22
label_26:
ja    label_23
jump_to_label_24:
jmp   label_24
label_23:
cmp   bx, 26
jb    label_25
cmp   bx, 28
jbe   jump_to_label_24
jmp   label_25
label_37:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_41:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_22:
ja    label_19
label_27:
jmp   label_20
label_19:
cmp   bx, 117
jb    label_27
cmp   bx, 118
ja    label_27
mov   dx, SFX_BDOPN
jmp   label_28
jump_to_label_29:
jmp   label_29
label_33:
mov   ax, word ptr [bp - 4]
shl   ax, 4
cmp   bx, 34
ja    label_30
mov   bx, LINES_PHYSICS_SEGMENT
mov   byte ptr ds:[si], 3
mov   es, bx
mov   bx, ax
add   bx, LINE_PHYSICS_T.lp_special
mov   byte ptr es:[bx], 0
jmp   label_31
label_30:
cmp   bx, 118
jne   label_35
mov   byte ptr ds:[si], 6
mov   bx, LINES_PHYSICS_SEGMENT
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED*4
mov   es, bx
mov   bx, ax
add   bx, LINE_PHYSICS_T.lp_special
mov   byte ptr es:[bx], 0
jmp   label_31
label_35:
cmp   bx, 117
je    label_42
label_34:
jmp   label_31
label_42:
mov   byte ptr ds:[si], 5
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED*4
jmp   label_31
label_29:
cmp   bx, 26
jb    label_34
cmp   bx, 28
ja    jump_to_label_31
jmp   label_32
jump_to_label_31:
jmp   label_31


ENDP

PROC    P_SpawnDoorCloseIn30_ NEAR
PUBLIC  P_SpawnDoorCloseIn30_


push  bx
push  dx
push  si
xchg  si, ax
mov   ax, TF_VERTICALDOOR_HIGHBITS

call  P_CreateThinker_
   
xor   dx, dx
mov   bx, ax

mov   word ptr ds:[bx + VLDOOR_T.vldoor_secnum], si
mov   word ptr ds:[bx + VLDOOR_T.vldoor_direction], dx ; 0
mov   word ptr ds:[bx + VLDOOR_T.vldoor_type], dx ; DOOR_NORMAL
mov   word ptr ds:[bx + VLDOOR_T.vldoor_speed], VDOORSPEED
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topcountdown],  30 * 35


SHIFT_MACRO SHL si 4
mov   word ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_special], dx


sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   bx, SIZEOF_THINKER_T
div   bx
mov   word ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax


pop   si
pop   dx
pop   bx
ret   

ENDP

PROC    P_SpawnDoorRaiseIn5Mins_ NEAR
PUBLIC  P_SpawnDoorRaiseIn5Mins_



push  bx
push  dx
push  si
xchg  ax, si
mov   ax, TF_VERTICALDOOR_HIGHBITS

call  P_CreateThinker_

xchg  ax, bx    
mov   ax, si
xor   dx, dx

call  P_FindLowestOrHighestCeilingSurrounding_

sub   ax, (4 SHL SHORTFLOORBITS)
; ax has doortopheight
; si has secnum
; bx has door

mov   word ptr ds:[bx + VLDOOR_T.vldoor_secnum], si
mov   word ptr ds:[bx + VLDOOR_T.vldoor_direction], 2
mov   word ptr ds:[bx + VLDOOR_T.vldoor_type], DOOR_RAISEIN5MINS
mov   word ptr ds:[bx + VLDOOR_T.vldoor_speed], VDOORSPEED
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topwait], VDOORWAIT
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topcountdown],  5 * 60 * 35;
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topheight],  ax

SHIFT_MACRO SHL si 4

xor   dx, dx
mov   word ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_special], dx
sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   bx, SIZEOF_THINKER_T
div   bx
mov   word ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax



pop   si
pop   dx
pop   bx
ret  


ENDP


PROC    P_DOORS_ENDMARKER_ NEAR
PUBLIC  P_DOORS_ENDMARKER_
ENDP


END
