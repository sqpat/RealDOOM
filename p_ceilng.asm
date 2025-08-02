
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

EXTRN _P_TeleportMove:DWORD
EXTRN _P_SpawnMobj:DWORD

EXTRN FastMul16u32u_:NEAR
EXTRN T_MovePlane_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_CreateThinker_:PROC
EXTRN P_RemoveThinker_:PROC
EXTRN P_UpdateThinkerFunc_:NEAR

SHORTFLOORBITS = 3

.DATA




.CODE



PROC    P_CEILNG_STARTMARKER_ NEAR
PUBLIC  P_CEILNG_STARTMARKER_
ENDP




_move_ceiling_jump_table:
dw switch_moveceiling_type_1, switch_moveceiling_default_case, switch_moveceiling_type_1, switch_moveceiling_type_2, switch_moveceiling_type_3, switch_moveceiling_type_4

;void __near T_MoveCeiling(ceiling_t __near* ceiling, THINKERREF ceilingRef) {


PROC    T_MoveCeiling_ NEAR
PUBLIC  T_MoveCeiling_



push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
mov   word ptr [bp - 4], dx
mov   di, word ptr ds:[si + CEILING_T.ceiling_secnum]
mov   dx, di
shl   dx, 4
mov   ax, dx
add   ax, _sectors_physics
mov   word ptr [bp - 2], ax
mov   al, byte ptr ds:[si + CEILING_T.ceiling_direction]
cmp   al, -1
je    do_ceiling_down
cmp   al, 1
je    do_process_ceiling
switch_moveceiling_default_case:
exit_t_moveceiling:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
do_process_ceiling:
cbw  
mov   cx, word ptr ds:[si + CEILING_T.ceiling_topheight]
push  ax
mov   bx, word ptr ds:[si + CEILING_T.ceiling_speed]
push  1
mov   ax, dx
push  0
mov   dx, SECTORS_SEGMENT
call  T_MovePlane_
mov   bx, _leveltime
mov   cl, al
test  byte ptr ds:[bx], 7
jne   label_2
mov   al, byte ptr ds:[si]
cmp   al, 5
jne   label_3
label_2:
cmp   cl, 2
jne   switch_moveceiling_default_case
mov   al, byte ptr ds:[si]
cmp   al, 5
je    label_4
cmp   al, 1
jb    switch_moveceiling_default_case
jbe   do_remove_ceiling
cmp   al, 3
jb    switch_moveceiling_default_case
cmp   al, 4
ja    switch_moveceiling_default_case
mov   byte ptr ds:[si + CEILING_T.ceiling_direction], -1
jmp   switch_moveceiling_default_case
label_3:
mov   dx, SFX_STNMOV
mov   ax, di

call  S_StartSoundWithParams_
jmp   label_2
do_ceiling_down:
jmp   continue_do_ceiling_down
switch_moveceiling_type_1:
do_remove_ceiling:
mov   dx, word ptr [bp - 4]
mov   ax, word ptr [bp - 2]
call  P_RemoveActiveCeiling_
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_4:
mov   dx, SFX_PSTOP
mov   ax, di

call  S_StartSoundWithParams_

mov   byte ptr ds:[si + CEILING_T.ceiling_direction], -1
jmp   exit_t_moveceiling
continue_do_ceiling_down:
cbw  
mov   cx, word ptr ds:[si + CEILING_T.ceiling_bottomheight]
push  ax
mov   al, byte ptr ds:[si + CEILING_T.ceiling_crush]
push  1
cbw  
mov   bx, word ptr ds:[si + CEILING_T.ceiling_speed]
push  ax
mov   ax, dx
mov   dx, SECTORS_SEGMENT
call  T_MovePlane_
mov   bx, _leveltime
mov   cl, al
test  byte ptr ds:[bx], 7
jne   label_1
mov   al, byte ptr ds:[si]
cmp   al, 5
jne   label_5
label_1:
cmp   cl, 2
jne   label_6
mov   dl, byte ptr ds:[si]
cmp   dl, 5
jbe   label_7
jump_to_exit_t_moveceiling:
jmp   exit_t_moveceiling
label_7:
xor   dh, dh
mov   bx, dx
add   bx, dx
jmp   word ptr cs:[bx + OFFSET _move_ceiling_jump_table]
label_5:
mov   dx, SFX_STNMOV
mov   ax, di

call  S_StartSoundWithParams_

nop   
jmp   label_1
switch_moveceiling_type_4:
mov   dx, SFX_PSTOP
mov   ax, di

call  S_StartSoundWithParams_

nop   
switch_moveceiling_type_2:
mov   word ptr ds:[si + CEILING_T.ceiling_speed], CEILSPEED
switch_moveceiling_type_3:
mov   byte ptr ds:[si + CEILING_T.ceiling_direction], 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_6:
cmp   cl, 1
jne   jump_to_exit_t_moveceiling
mov   al, byte ptr ds:[si]
cmp   al, 5
je    label_8
cmp   al, 3
je    label_8
cmp   al, 2
jne   jump_to_exit_t_moveceiling
label_8:
mov   word ptr ds:[si + CEILING_T.ceiling_speed], 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
ENDP

_ev_doceiling_jump_table:
dw switch_doceiling_type_1, switch_doceiling_type_2, switch_doceiling_type_1, switch_doceiling_type_3, switch_doceiling_type_4, switch_doceiling_type_3

; todo change to carry return
PROC    EV_DoCeiling_ NEAR
PUBLIC  EV_DoCeiling_

;int16_t __near EV_DoCeiling ( uint8_t linetag, ceiling_e	type ) {


; bp - 2 type
; bp - 4 unused 
; bp - 6 sector/sector_physics_t ptr (secnum * 16)
; bp - 8 ceilingRef
; bp - 0Ah unused (j)
; bp - 0Ch unused (rtn)
; bp - 0Eh ; unused
; bp - 010h   ; ?? 0Ah * 2?  TODO store in si.
; bp - 012h   ; sector physics
; bp - 0212h  ; secnumlist

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0212h
xchg  ax, bx ; bx gets linetag
mov   byte ptr [bp - 2], dl
xor   ax, ax
mov   word ptr cs:[OFFSET SELFMODIFY_doceiling_return+1], ax

mov   word ptr [bp - 010h], ax
cmp   dl, CEILING_CRUSHANDRAISE
jb    not_stasis_ceiling
je    do_activate_stasis
cmp   dl, CEILING_SILENTCRUSHANDRAISE
ja    not_stasis_ceiling
do_activate_stasis:

mov   ax, bx
call  P_ActivateInStasisCeiling_
not_stasis_ceiling:

lea   dx, [bp - 0212h]

xchg  ax, bx    ; last use of linetag

xor   bx, bx    ; false
call  P_FindSectorsFromLineTag_

cmp   word ptr [bp + si - 0212h], 0
jl    exit_doceiling

loop_next_secnum:
mov   si, word ptr [bp - 010h]
mov   cx, word ptr [bp + si - 0212h]        ; secnum

mov   di, cx
xor   dx, dx
SHIFT_MACRO shl   di, 4
mov   word ptr [bp - 6], di

;		ceiling = (ceiling_t __near*) P_CreateThinker (TF_MOVECEILING_HIGHBITS);
mov   ax, TF_MOVECEILING_HIGHBITS
call  P_CreateThinker_



mov   si, ax  ; si gets thinker
sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   bx, SIZEOF_THINKER_T
div   bx
mov   bx, si ; bx gets si copy..


mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov   word ptr [bp - 8], ax
xor   ax, ax
mov   byte ptr ds:[bx + CEILING_T.ceiling_crush], al
inc   ax
mov   word ptr cs:[OFFSET SELFMODIFY_doceiling_return + 1], ax ; 1
inc   ax
add   word ptr [bp - 010h], ax ; 2
mov   word ptr ds:[bx + CEILING_T.ceiling_secnum], cx
mov   al, byte ptr [bp - 2]

cmp   al, 5
ja    switch_doceiling_default

mov   di, ax
add   di, ax
jmp   word ptr cs:[di + OFFSET _ev_doceiling_jump_table]

switch_doceiling_type_2:
mov   dx, 1
mov   ax, cx
call  P_FindLowestOrHighestCeilingSurrounding_
mov   byte ptr ds:[bx + CEILING_T.ceiling_direction], 1
mov   word ptr ds:[bx + CEILING_T.ceiling_speed], CEILSPEED
mov   word ptr ds:[bx + CEILING_T.ceiling_topheight], ax
;jmp   done_with_doceiling_switch_block
; fall thru

done_with_doceiling_switch_block:
switch_doceiling_default:

;		ceiling->tag = sector_physics->tag;
;		ceiling->type = type;
;		P_AddActiveCeiling(ceilingRef);

mov   bx, word ptr [bp - 6]
mov   al, byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_tag]
mov   byte ptr ds:[si + CEILING_T.ceiling_tag], al
mov   al, byte ptr [bp - 2]
;mov   byte ptr ds:[si], al
stosb
mov   ax, word ptr [bp - 8]
mov   si, word ptr [bp - 010h]
call  P_AddActiveCeiling_
cmp   word ptr [bp + si - 0212h], 0
jnl   loop_next_secnum

exit_doceiling:
SELFMODIFY_doceiling_return:
mov   ax, 01000h
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
switch_doceiling_type_4:
mov   di, word ptr [bp - 6]
mov   byte ptr ds:[bx + CEILING_T.ceiling_crush], 1
mov   es, word ptr [bp - 4]
mov   ax, word ptr es:[di + 2]
mov   word ptr ds:[bx + CEILING_T.ceiling_topheight], ax
mov   cx, word ptr es:[di]
mov   byte ptr ds:[bx + CEILING_T.ceiling_direction], -1
add   cx, (8 SHL SHORTFLOORBITS)
mov   word ptr ds:[bx + CEILING_T.ceiling_speed], CEILSPEED * 2
mov   word ptr ds:[bx + CEILING_T.ceiling_bottomheight], cx
jmp   done_with_doceiling_switch_block


switch_doceiling_type_3:
mov   bx, word ptr [bp - 6]
mov   byte ptr ds:[si + CEILING_T.ceiling_crush], 1
mov   es, word ptr [bp - 4]
mov   ax, word ptr es:[bx + 2]
mov   word ptr ds:[si + CEILING_T.ceiling_topheight], ax
;jmp   switch_doceiling_type_1 ; fall thru

switch_doceiling_type_1:
mov   bx, SECTORS_SEGMENT
mov   es, bx
mov   bx, word ptr [bp - 6]
mov   ax, word ptr es:[bx]
mov   word ptr ds:[si + CEILING_T.ceiling_bottomheight], ax
cmp   byte ptr [bp - 2], 0
je    label_17
add   word ptr ds:[si + CEILING_T.ceiling_bottomheight], (8 SHL SHORTFLOORBITS)
label_17:
mov   byte ptr ds:[si + CEILING_T.ceiling_direction], -1
mov   word ptr ds:[si + 7], CEILSPEED
jmp   done_with_doceiling_switch_block

ENDP


PROC    P_AddActiveCeiling_ NEAR
PUBLIC  P_AddActiveCeiling_

push  bx
mov   bx, _activeceilings
loop_next_add_active_ceiling:

cmp   word ptr ds:[bx], NULL_THINKERREF
je    found_ceiling_slot_to_add
inc   bx
inc   bx
cmp   bx, (MAXCEILINGS * 2) + _activeceilings
jl    loop_next_add_active_ceiling
pop   bx
ret   
found_ceiling_slot_to_add:
mov   ds:[bx], ax
pop   bx
ret   




ENDP


;void __near P_RemoveActiveCeiling(sector_physics_t __near* ceilingsector_physics, THINKERREF ceilingRef) {

PROC    P_RemoveActiveCeiling_ NEAR
PUBLIC  P_RemoveActiveCeiling_


push  bx
mov   bx, _activeceilings
loop_next_remove_active_ceiling:

cmp   dx, word ptr ds:[bx]
je    found_ceiling_to_remove
inc   bx
inc   bx
cmp   bx, (MAXCEILINGS * 2) + _activeceilings
jl    loop_next_remove_active_ceiling
pop   bx
ret   

found_ceiling_to_remove:
xchg  ax, bx  ; bx gets sectorphysics
mov   word ptr ds:[bx + SECTOR_PHYSICS_T.secp_specialdataRef], 0
xchg  ax, bx  ; bx gets acrtiveceiling ptr back again
xchg  ax, dx  ; param for P_RemoveThinker_

call  P_RemoveThinker_

mov   word ptr ds:[bx], NULL_THINKERREF

pop   bx
ret   

ENDP


PROC    P_ActivateInStasisCeiling_ NEAR
PUBLIC  P_ActivateInStasisCeiling_



push  bx
push  cx
push  dx


mov   ch, al ; ch gets tag
xor   cl, cl ; cl is loop counter

loop_next_stasis_ceiling:
xor   bx, bx
mov   bl, cl
sal   bx, 1
mov   bx, word ptr ds:[bx + _activeceilings]
test  bx, bx
je    continue_statis_ceiling_loop
mov   ax, SIZEOF_THINKER_T
mul   bx
xchg  ax, bx ; ax gets activeceiling
xchg  ax, dx ; now dx gets activeceiling.

add   bx, _thinkerlist + THINKER_T.t_data
cmp   ch, byte ptr ds:[bx  + CEILING_T.ceiling_tag]
jne   continue_statis_ceiling_loop
mov   al, byte ptr ds:[bx + CEILING_T.ceiling_direction]
test  al, al
je    continue_statis_ceiling_loop
mov   byte ptr ds:[bx + CEILING_T.ceiling_olddirection], al
xchg  ax, dx  ; recover _activeceilings into ax
mov   dx, TF_MOVECEILING_HIGHBITS


call  P_UpdateThinkerFunc_

continue_statis_ceiling_loop:
inc   cx
cmp   cl, MAXCEILINGS
jl    loop_next_stasis_ceiling
pop   dx
pop   cx
pop   bx
ret   

ENDP



PROC    EV_CeilingCrushStop_ NEAR
PUBLIC  EV_CeilingCrushStop_


push  bx
push  cx
push  dx
push  di

mov   ch, al ; ch gets tag
xor   di, di ; di is retn
xor   cl, cl ; cl is loop counter



loop_next_ceiling_crush_stop:
xor   bx, bx
mov   bl, cl
sal   bx, 1
mov   bx, word ptr ds:[bx + _activeceilings]
test  bx, bx
je    continue_ceiling_crush_stop_loop
mov   ax, SIZEOF_THINKER_T
mul   bx
xchg  ax, bx ; ax gets activeceiling
xchg  ax, dx ; now dx gets activeceiling.

add   bx, _thinkerlist + THINKER_T.t_data
cmp   ch, byte ptr ds:[bx  + CEILING_T.ceiling_tag]
jne   continue_ceiling_crush_stop_loop
mov   al, byte ptr ds:[bx + CEILING_T.ceiling_direction]
test  al, al
je    continue_ceiling_crush_stop_loop
mov   byte ptr ds:[bx + CEILING_T.ceiling_olddirection], al
xchg  ax, dx  ; recover _activeceilings into ax
cwd   ; dx gets 0
mov   di, 1
call  P_UpdateThinkerFunc_
mov   byte ptr ds:[bx + CEILING_T.ceiling_direction], 0
continue_ceiling_crush_stop_loop:
inc   cx
cmp   cl, MAXCEILINGS
jl    loop_next_ceiling_crush_stop
xchg  ax, di
pop   di
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    P_CEILNG_ENDMARKER_ NEAR
PUBLIC  P_CEILNG_ENDMARKER_
ENDP

END
