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




PROC    T_VerticalDoor_ NEAR
PUBLIC  T_VerticalDoor_

;void __near T_VerticalDoor (vldoor_t __near* door, THINKERREF doorRef) {

; bp - 2 doorref



PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
push  dx ; bp - 2
xchg  ax, si
mov   ax, word ptr ds:[si + VLDOOR_T.vldoor_secnum]

mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]


mov   di, ax

SHIFT_MACRO shl   ax 4

xor   cx, cx
mov   bx, cx
mov   bl, byte ptr ds:[si + VLDOOR_T.vldoor_direction]
mov   dx, word ptr ds:[si + VLDOOR_T.vldoor_speed]

; dx is speed (sometimes used)
; ax is vldoor secnum offset
; di is vldoor secnum
; si is vldoor ptr
; cx is zero (used in two calls)

cmp   bl, 1
jg    switch_case_verticaldoor_dir_case_2  ; 2 > 1
jpo   switch_case_verticaldoor_dir_minus_1 ; 0xFE parity odd. 0xFF, 0x00 not.
jl    switch_case_verticaldoor_dir_case_0  ; 0 < 1
jmp   switch_case_verticaldoor_dir_case_1  

switch_case_verticaldoor_dir_case_2:
dec   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown]
jne   exit_t_verticaldoor

mov   al, byte ptr ds:[si + VLDOOR_T.vldoor_type]
cmp   al, DOOR_RAISEIN5MINS
jne   exit_t_verticaldoor

mov   dx, SFX_DOROPN
mov   byte ptr ds:[si + VLDOOR_T.vldoor_type], cl; 0, DOOR_NORMAL
jmp   set_dir_to_1_and_call_sound_and_exit

switch_case_verticaldoor_dir_minus_1:

mov   bx, ax
mov   bx, word ptr es:[bx + SECTOR_T.sec_floorheight]
push  ax  ; store sector offset
call  T_MovePlaneCeilingDown_
pop   bx  ; sector offset in bx in case necessary
cmp   al, FLOOR_CRUSHED
mov   al, byte ptr ds:[si + VLDOOR_T.vldoor_type]
ja    vert_door_floor_past_dest ; pastdest
jne   exit_t_verticaldoor
;crushed

cmp   al, DOOR_BLAZECLOSE
je    exit_t_verticaldoor
cmp   al, DOOR_CLOSE
je    exit_t_verticaldoor
mov   dx, SFX_DOROPN

set_dir_to_1_and_call_sound_and_exit:
mov   bx, 1
set_dir_to_bx_and_call_sound_and_exit:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], bx

call_sound_and_exit:
mov   ax, di
call  S_StartSoundWithParams_
switch_case_verticaldoor_2_default:
switch_case_verticaldoor_3_default:
exit_t_verticaldoor_2:   
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

vert_door_floor_past_dest:
cmp   al, DOOR_BLAZECLOSE
ja    exit_t_verticaldoor
je    switch_case_verticaldoor_2_blazeclose
cmp   al, DOOR_BLAZERAISE
je    switch_case_verticaldoor_2_blazeraise
cmp   al, DOOR_CLOSE30THENOPEN
je    switch_case_verticaldoor_2_doorclose30thenopen
cmp   al, DOOR_CLOSE
ja    exit_t_verticaldoor
; fall thru to 0 and 2 case

switch_case_verticaldoor_2_doornormal:
switch_case_verticaldoor_2_doorclose:
switch_case_verticaldoor_3_doorclose30thenopen:
switch_case_verticaldoor_3_dooropen:
switch_case_verticaldoor_3_doorblazeopen:
; bx pre-set to sec offset

xor   ax, ax


mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
pop   ax ; bp - 2

call  P_RemoveThinker_
exit_t_verticaldoor:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   
switch_case_verticaldoor_dir_case_0:

dec   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown]
jne   exit_t_verticaldoor_2
mov   al, byte ptr ds:[si + VLDOOR_T.vldoor_type]
cmp   al, DOOR_BLAZERAISE
je    play_blaze_close
cmp   al, DOOR_CLOSE30THENOPEN
je    play_open
test  al, al ; DOOR_NORMAL
jne   exit_t_verticaldoor_2
; DOOR_NORMAL
mov   dx, SFX_DORCLS
mov   bx, -1

jmp   set_dir_to_bx_and_call_sound_and_exit

play_blaze_close:
mov   dx, SFX_BDCLS
mov   bx, -1
jmp   set_dir_to_bx_and_call_sound_and_exit

play_open:
mov   dx, SFX_DOROPN
jmp   set_dir_to_1_and_call_sound_and_exit



switch_case_verticaldoor_2_blazeraise:
switch_case_verticaldoor_2_blazeclose:
mov   bx, word ptr ds:[si + VLDOOR_T.vldoor_secnum]
shl   bx, 4

xor   ax, ax

mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
pop   ax  ; bp - 2
mov   dx, SFX_BDCLS

call  P_RemoveThinker_
jmp   call_sound_and_exit

switch_case_verticaldoor_2_doorclose30thenopen:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 0
mov   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown], 35 * 30
jmp   exit_t_verticaldoor
switch_case_verticaldoor_dir_case_1:


mov   bx, word ptr ds:[si + VLDOOR_T.vldoor_topheight]
push  ax ; store sec offset in case needed
call  T_MovePlaneCeilingUp_
pop   bx  ; bx has sec offset

cmp   al, DOOR_CLOSE
jne   exit_t_verticaldoor
mov   al, byte ptr ds:[si + VLDOOR_T.vldoor_type]
cmp   al, DOOR_BLAZEOPEN
ja    exit_t_verticaldoor
je    switch_case_verticaldoor_3_doorblazeopen
cmp   al, DOOR_RAISEIN5MINS
je    exit_t_verticaldoor
ja    switch_case_verticaldoor_3_doorraisein5mins
cmp   al, DOOR_CLOSE
je    exit_t_verticaldoor
ja    switch_case_verticaldoor_3_dooropen
cmp   al, DOOR_CLOSE30THENOPEN
je    switch_case_verticaldoor_3_doorclose30thenopen
; fall thru 0

switch_case_verticaldoor_3_doornormal:
switch_case_verticaldoor_3_doorraisein5mins:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 0
mov   ax, word ptr ds:[si + VLDOOR_T.vldoor_topwait]
mov   word ptr ds:[si + VLDOOR_T.vldoor_topcountdown], ax
jmp   exit_t_verticaldoor



ENDP

_jump_table_do_door:
dw OFFSET switch_block_ev_dodoor_case_doornormal             - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER
dw OFFSET switch_block_ev_dodoor_case_doorclose30thenopen    - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER
dw OFFSET switch_block_ev_dodoor_case_doorclose              - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER
dw OFFSET switch_block_ev_dodoor_case_dooropen               - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER
dw OFFSET switch_block_ev_dodoor_case_doorraisein5mins       - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER
dw OFFSET switch_block_ev_dodoor_case_doorblazeraise         - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER
dw OFFSET switch_block_ev_dodoor_case_doorblazeopen          - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER
dw OFFSET switch_block_ev_dodoor_case_doorblazeclose         - OFFSET SELFMODIFY_evdoordoor_do_jmp_AFTER



;int16_t __near EV_DoLockedDoor ( uint8_t linetag, int16_t linespecial, vldoor_e	type, THINKERREF thingRef ) {


PROC    EV_DoLockedDoor_ NEAR
PUBLIC  EV_DoLockedDoor_

; bp - 2 linetag
cmp   cx, word ptr ds:[_playerMobjRef]
jne   exit_non_player_locked_door
xchg  ax, cx  ; cx gets linetag for now
xchg  ax, bx  ; ax holds bx. 
xor   bx, bx ; bx 0


cmp   dx, 133
ja    check_for_red_key
cmp   dx, 99
jne   switch_block_fall_thru
; case blue
case_blue:

do_key_stuff:

; bh is 0..

cmp   byte ptr ds:[_player + PLAYER_T.player_cards + bx], bh ; card
jne   switch_block_fall_thru
cmp   byte ptr ds:[_player + PLAYER_T.player_cards + bx + 3], bh  ; skull
jne   switch_block_fall_thru
xchg  ax, dx  ; ax gets dx
mov   dx, SFX_OOF
add   bl, PD_BLUEO
mov   word ptr ds:[_player + PLAYER_T.player_message], bx

play_sound_and_exit_lockedoor:

call  S_StartSound_
exit_non_player_locked_door:
xor   ax, ax
ret



check_for_red_key:
inc   bx
cmp   dx, 135
jna   do_key_stuff
check_for_yellow_key:
inc   bx
cmp   dx, 137
jna   do_key_stuff

switch_block_fall_thru:
; restore bx
xchg  ax, dx  ; type to dx
xchg  ax, cx  ; linetag restored

; fall thru
;call  EV_DoDoor_
;ret   



ENDP


PROC    EV_DoDoor_ FAR
PUBLIC  EV_DoDoor_

;int16_t __far EV_DoDoor ( uint8_t linetag, vldoor_e	type ) {

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 0200h
xor   dh, dh
mov   byte ptr cs:[SELFMODIFY_evdoordoor_settype+2], dl  ; + 2 because offset is 0

sal   dx, 1
mov   si, dx
push  word ptr cs:[_jump_table_do_door+si]
pop   word ptr cs:[SELFMODIFY_evdoordoor_do_jmp+1]

mov   byte ptr cs:[SELFMODIFY_evdoordoor_rtn+1], 0
lea   dx, [bp - 0200h]
mov   si, dx

xor   bx, bx ; false

call  P_FindSectorsFromLineTag_

lodsw  ;get first secnum
test  ax, ax
js    exit_evdoodoor_return_rtn

mov   byte ptr cs:[SELFMODIFY_evdoordoor_rtn+1], 1  ; only need to do once

loop_next_secnum_evdodoor:

xchg  ax, cx ; cx has secnum

mov   ax, TF_VERTICALDOOR_HIGHBITS
cwd   ; zero dx

call  P_CreateThinker_

mov   bx, ax   ; bx gets door ptr
mov   di, SIZEOF_THINKER_T

sub   ax, (_thinkerlist + THINKER_T.t_data)
div   di  ; get doorref in ax

mov   di, cx
SHIFT_MACRO shl   di 4  ; di has sector offset


mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topwait], VDOORWAIT
mov   word ptr ds:[bx + VLDOOR_T.vldoor_speed], VDOORSPEED
mov   ax, cx  ; ax gets secnum copy
cwd   ; dx 0. secnum should be < 08000h
mov   word ptr ds:[bx + VLDOOR_T.vldoor_secnum], ax

mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   di, word ptr es:[di + SECTOR_T.sec_ceilingheight]; last use of sector ptr

SELFMODIFY_evdoordoor_settype:
mov   byte ptr ds:[bx + VLDOOR_T.vldoor_type], 010h 


; ax is secnum
; dx is 0
; di is ceiling height
; cx is secnum
; bx is vldoor ptr
; di is ceiling height

SELFMODIFY_evdoordoor_do_jmp:
jmp   P_DOORS_ENDMARKER_  ; force a word-sized jump immediate
SELFMODIFY_evdoordoor_do_jmp_AFTER:

switch_block_ev_dodoor_case_doorblazeclose:

mov   word ptr ds:[bx + VLDOOR_T.vldoor_speed], VDOORSPEED*4
call  P_FindLowestOrHighestCeilingSurrounding_
mov   dx, SFX_BDCLS

do_rest_of_close_case:

sub   ax, (4 SHL SHORTFLOORBITS)
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topheight], ax

set_direction_secnum_and_play_sound_and_exit:
mov   word ptr ds:[bx + VLDOOR_T.vldoor_direction], -1
set_secnum_and_play_sound_and_exit:
xchg  ax, cx

call  S_StartSoundWithParams_
switch_block_ev_dodoor_case_doorraisein5mins:
done_with_evdodoor_switch_block:

lodsw ; get next secnum
test  ax, ax
jns   loop_next_secnum_evdodoor
exit_evdoodoor_return_rtn:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
SELFMODIFY_evdoordoor_rtn:
mov   al, 010h
retf  

switch_block_ev_dodoor_case_doorclose:
call  P_FindLowestOrHighestCeilingSurrounding_
mov   dx, SFX_DORCLS
jmp   do_rest_of_close_case

switch_block_ev_dodoor_case_doorclose30thenopen:
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topheight], di
mov   dx, SFX_DORCLS

jmp   set_direction_secnum_and_play_sound_and_exit
switch_block_ev_dodoor_case_doornormal:
switch_block_ev_dodoor_case_dooropen:


call  P_FindLowestOrHighestCeilingSurrounding_
mov   dx, SFX_DOROPN
do_ceilingheight_compare:
sub   ax, (4 SHL SHORTFLOORBITS)
mov   word ptr ds:[bx + VLDOOR_T.vldoor_topheight], ax
mov   word ptr ds:[bx + VLDOOR_T.vldoor_direction], 1
cmp   ax, di
je    done_with_evdodoor_switch_block

jmp   set_secnum_and_play_sound_and_exit
switch_block_ev_dodoor_case_doorblazeraise:
switch_block_ev_dodoor_case_doorblazeopen:
mov   word ptr ds:[bx + VLDOOR_T.vldoor_speed], VDOORSPEED*4
call  P_FindLowestOrHighestCeilingSurrounding_
mov   dx, SFX_BDOPN

jmp   do_ceilingheight_compare


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
