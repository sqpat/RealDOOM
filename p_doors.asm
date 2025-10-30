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


EXTRN P_RemoveThinker_:NEAR
EXTRN P_CreateThinker_:NEAR

EXTRN S_StartSound_:NEAR
EXTRN S_StartSoundWithSecnum_:NEAR
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
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
jne   exit_t_verticaldoor_2

mov   al, byte ptr ds:[si + VLDOOR_T.vldoor_type]
cmp   al, DOOR_RAISEIN5MINS
jne   exit_t_verticaldoor_2

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
jne   exit_t_verticaldoor_2
;crushed

cmp   al, DOOR_BLAZECLOSE
je    exit_t_verticaldoor_2
cmp   al, DOOR_CLOSE
je    exit_t_verticaldoor_2
mov   dx, SFX_DOROPN

set_dir_to_1_and_call_sound_and_exit:
mov   bx, 1
set_dir_to_bx_and_call_sound_and_exit:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], bx

call_sound_and_exit:
mov   ax, di
call  S_StartSoundWithSecnum_

switch_case_verticaldoor_2_default:
switch_case_verticaldoor_3_default:
exit_t_verticaldoor_2:   
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

vert_door_floor_past_dest:
cmp   al, DOOR_BLAZECLOSE
ja    exit_t_verticaldoor_2
je    switch_case_verticaldoor_2_blazeclose
cmp   al, DOOR_BLAZERAISE
je    switch_case_verticaldoor_2_blazeraise
cmp   al, DOOR_CLOSE30THENOPEN
je    switch_case_verticaldoor_2_doorclose30thenopen
cmp   al, DOOR_CLOSE
ja    exit_t_verticaldoor_2
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
jmp   exit_t_verticaldoor_2
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
SHIFT_MACRO shl   bx 4

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
exit_t_verticaldoor:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   




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

; return in carry
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
mov   dl, SFX_OOF
add   bl, PD_BLUEO
mov   word ptr ds:[_player + PLAYER_T.player_message], bx

play_sound_and_exit_lockedoor:

call  S_StartSound_


exit_non_player_locked_door:
clc
ret



check_for_red_key:
inc   bx ; red is index 2...
inc   bx
cmp   dx, 135
jna   do_key_stuff
check_for_yellow_key:
dec   bx ; and yellow index 1.
cmp   dx, 137
jna   do_key_stuff

switch_block_fall_thru:
; restore bx
xchg  ax, dx  ; type to dx
xchg  ax, cx  ; linetag restored

; fall thru and to ev_dodoor_ without call

;call  EV_DoDoor_
;ret   



ENDP

; return in carry

PROC    EV_DoDoor_ NEAR
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

mov   byte ptr cs:[SELFMODIFY_evdoordoor_rtn], CLC_OPCODE
lea   dx, [bp - 0200h]
mov   si, dx

xor   bx, bx ; false

call  P_FindSectorsFromLineTag_

lodsw  ;get first secnum
test  ax, ax
js    exit_evdoodoor_return_rtn

mov   byte ptr cs:[SELFMODIFY_evdoordoor_rtn], STC_OPCODE

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

call  S_StartSoundWithSecnum_

switch_block_ev_dodoor_case_doorraisein5mins:
done_with_evdodoor_switch_block:

lodsw ; get next secnum
test  ax, ax
jns   loop_next_secnum_evdodoor
exit_evdoodoor_return_rtn:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
SELFMODIFY_evdoordoor_rtn:
clc
ret  

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




ENDP

PROC    EV_VerticalDoor_ NEAR
PUBLIC  EV_VerticalDoor_

;void __near EV_VerticalDoor ( int16_t linenum, THINKERREF thingRef ) {

; bp - 2 door
; bp - 4 linenum

; si stays door for the whole function generally
; di stays linephysics for the whole function generally


PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp

xchg  ax, di  
SHIFT_MACRO shl   di 4


push  dx

mov   es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]
mov   al, byte ptr es:[di + LINE_PHYSICS_T.lp_special]
xor   ah, ah
mov   cx, ax ; backup..
sub   al, 26
js    switch_block_verticaldoor_case_default ; catch 0-25
cmp   al, 3
jb    switch_block_verticaldoor_case_key ; catch 26-28
sub   al, 6
js    switch_block_verticaldoor_case_default ; catch 29-31
cmp   al, 3
jnb   switch_block_verticaldoor_case_default ; catch35+

; catch 32-34, fall thru

switch_block_verticaldoor_case_key_skull:
; in the case of skull, the logic is swapped for 33/34 or al = 1/2

; al is 0, 1, 2.
; red key in powers lookup is 2, but its al = 1 in skull door logic
; yellow in powers lookup is  1, but its al = 2 in skull door logic
; 1/2 cases need to swap

test    al, al
jz      dont_adjust_key

dec     al  ; 2 becomes 1, 1 becomes 0
jnz     set_up_bx
inc     ax 
inc     ax  ; 1 becomes 2, after having been 0

set_up_bx:

dont_adjust_key:
switch_block_verticaldoor_case_key:




cmp   dx, word ptr ds:[_playerMobjRef]  ; only player can open locked doors
jne   exit_ev_verticaldoor

mov   bl, al  ; key index

cmp   byte ptr ds:[_player + PLAYER_T.player_cards + bx], bh  
jne   done_with_verticaldoor_switch_block
cmp   byte ptr ds:[_player + PLAYER_T.player_cards + 3 + bx], bh   ; check skull
jne   done_with_verticaldoor_switch_block

mov   dl, SFX_OOF
add   al, PD_BLUEK
cbw
mov   word ptr ds:[_player + PLAYER_T.player_message], ax


xor   ax, ax

call  S_StartSound_
   
jmp   exit_ev_verticaldoor

done_with_verticaldoor_switch_block:
switch_block_verticaldoor_case_default:



; already set above..
;mov   es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]

mov   bx, word ptr es:[di + LINE_PHYSICS_T.lp_backsecnum]

mov   si, bx
SHIFT_MACRO shl   si 4
push  si  ; store sector offset for later
mov   ax, word ptr ds:[si + _sectors_physics+ SECTOR_PHYSICS_T.secp_specialdataRef]
test  ax, ax

jz    door_special_data_ref_block_done


mov   dx, SIZEOF_THINKER_T
mul   dx
xchg  ax, si
add   si, (_thinkerlist + THINKER_T.t_data) ; si is door ptr.
mov   ax, cx
cmp   al, 117
je    handle_raise_door
cmp   al, 1
jb    door_special_data_ref_block_done
je    handle_raise_door
cmp   al, 26
jb    door_special_data_ref_block_done
cmp   al, 28
ja    door_special_data_ref_block_done

handle_raise_door:
cmp   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1
je    set_door_up_and_exit
pop   ax ; bp - 2, thingref
cmp   ax, word ptr ds:[_playerMobjRef]
jne   exit_ev_verticaldoor
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], -1
exit_ev_verticaldoor:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

set_door_up_and_exit:
mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1
jmp   exit_ev_verticaldoor



door_special_data_ref_block_done:
mov   ax, cx
mov   dx, SFX_DOROPN
cmp   al, 117
jb    do_play_door_sound
cmp   al, 118
ja    do_play_door_sound
mov   dx, SFX_BDOPN
do_play_door_sound:

mov   ax, bx
call  S_StartSoundWithSecnum_

   
mov   ax, TF_VERTICALDOOR_HIGHBITS

call  P_CreateThinker_
xor   dx, dx
mov   si, ax

sub   ax, (_thinkerlist + THINKER_T.t_data)
push  di
mov   di, SIZEOF_THINKER_T
div   di
pop   di ; no other registers free now..?

mov   word ptr ds:[si + VLDOOR_T.vldoor_direction], 1
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED
mov   word ptr ds:[si + VLDOOR_T.vldoor_secnum], bx
mov   word ptr ds:[si + VLDOOR_T.vldoor_topwait], VDOORWAIT
pop   dx  ; shl 4 from earlier
xchg  ax, dx
xchg  ax, bx  ; ptr into bx
mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], dx
xchg  ax, bx  ; restore bx

mov   es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]

xchg  ax, cx ; last one

cmp   al, 31
jae   check_for_linespecial_34_and_above
cmp   al, 1
jb    done_with_final_linespecial_block
jna   do_linespecial_1
cmp   al, 26
jb    done_with_final_linespecial_block
cmp   al, 28
ja    done_with_final_linespecial_block

; fall thru 26-28

do_linespecial_1:

mov   byte ptr ds:[si + VLDOOR_T.vldoor_type], ah ; 0 DOOR_NORMAL

done_with_final_linespecial_block:
xchg  ax, bx ; last use of bx.
cwd  ; secnum should be under 08000h

call  P_FindLowestOrHighestCeilingSurrounding_
sub   ax, (4 SHL SHORTFLOORBITS)
mov   word ptr ds:[si + VLDOOR_T.vldoor_topheight], ax
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

check_for_linespecial_34_and_above:
cmp   al, 34
ja    check_for_line_special_118

mov   byte ptr ds:[si + VLDOOR_T.vldoor_type], DOOR_OPEN

set_special_zero:
mov   byte ptr es:[di + LINE_PHYSICS_T.lp_special], ah ; 0
jmp   done_with_final_linespecial_block
check_for_line_special_118:
cmp   al, 118
ja    done_with_final_linespecial_block
cmp   al, 117
jb    done_with_final_linespecial_block
mov   word ptr ds:[si + VLDOOR_T.vldoor_speed], VDOORSPEED*4
; al is 118 or 117.
sub   al, (118 - DOOR_BLAZEOPEN) ; normalize to type: from 117 or 118 to 5 or 6.
mov   byte ptr ds:[si + VLDOOR_T.vldoor_type], al  ; 5 or 6.
sub   al, 5
jz    done_with_final_linespecial_block ; if 117 dont set special
jmp   set_special_zero


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
