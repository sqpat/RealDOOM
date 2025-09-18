
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




EXTRN S_StartSound_:NEAR
EXTRN S_StartSoundWithSecnum_:NEAR
EXTRN T_MovePlaneCeilingUp_:NEAR
EXTRN T_MovePlaneCeilingDown_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_CreateThinker_:NEAR
EXTRN P_RemoveThinker_:NEAR
EXTRN P_UpdateThinkerFunc_:NEAR

SHORTFLOORBITS = 3

.DATA




.CODE



PROC    P_CEILNG_STARTMARKER_ NEAR
PUBLIC  P_CEILNG_STARTMARKER_
ENDP




;void __near T_MoveCeiling(ceiling_t __near* ceiling, THINKERREF ceilingRef) {



PROC    T_MoveCeiling_ NEAR
PUBLIC  T_MoveCeiling_

push  si
xchg  ax, si ; si gets ceiling
mov   al, byte ptr ds:[si + CEILING_T.ceiling_direction]
cmp   al, 0
je    ceiling_in_stasis_return

push  bx
push  cx
push  di
push  bp
mov   bp, sp


mov   di, word ptr ds:[si + CEILING_T.ceiling_secnum]

push  di ; bp - 2
push  dx ; bp - 4

SHIFT_MACRO shl di 4

; do a few thing used in both T_MovePlane call cases

mov   dx, word ptr ds:[si + CEILING_T.ceiling_speed]
cbw
cmp   al, 0  ; pend to below

push  word ptr ds:[si + CEILING_T.ceiling_type]  ; put this on stack to easily retrieve later into ax in either case.



mov   ax, 0

jl    do_ceiling_down

do_ceiling_up:

mov   cx, ax ; false crush
mov   bx, word ptr ds:[si + CEILING_T.ceiling_topheight]
mov   ax, di


call  T_MovePlaneCeilingUp_
xchg  ax,  cx
pop   ax ; type
test  byte ptr ds:[_leveltime], 7
jne   dont_play_ceiling_sound
cmp   al, CEILING_SILENTCRUSHANDRAISE
je    dont_play_ceiling_sound
mov   dx, SFX_STNMOV
push  ax
mov   ax, word ptr [bp - 2]
call  S_StartSoundWithSecnum_

pop   ax

dont_play_ceiling_sound:
cmp   cl, FLOOR_PASTDEST
jne   done_with_moveceiling_switch_block
cmp   al, CEILING_RAISETOHIGHEST
je    do_remove_ceiling ; 1

cmp   al, CEILING_CRUSHANDRAISE ; 3
jb    done_with_moveceiling_switch_block ; 0, 2
cmp   al, CEILING_FASTCRUSHANDRAISE
jbe   just_set_dir_negative ; 3, 4

; 5 fall thru
mov   dx, SFX_PSTOP
mov   ax, word ptr [bp - 2]
call  S_StartSoundWithSecnum_

just_set_dir_negative:
mov   byte ptr ds:[si + CEILING_T.ceiling_direction], -1
jmp   done_with_moveceiling_switch_block

switch_moveceiling_type_1:
do_remove_ceiling:

pop   dx ; bp - 4
xchg  ax, di
add   ax, _sectors_physics
call  P_RemoveActiveCeiling_
done_with_moveceiling_switch_block:
switch_moveceiling_default_case:
exit_t_moveceiling:
LEAVE_MACRO 
pop   di
pop   cx
pop   bx
ceiling_in_stasis_return:
pop   si
ret   

do_ceiling_down:


mov   cl, byte ptr ds:[si + CEILING_T.ceiling_crush] 
mov   bx, word ptr ds:[si + CEILING_T.ceiling_bottomheight]
mov   ax, di

call  T_MovePlaneCeilingDown_

xchg  ax,  cx
pop   ax ; type
test  byte ptr ds:[_leveltime], 7
jne   dont_play_ceiling_sound_2
cmp   al, CEILING_SILENTCRUSHANDRAISE
je    dont_play_ceiling_sound_2

mov   dx, SFX_STNMOV
push  ax ; backup
mov   ax, word ptr [bp - 2]
call  S_StartSoundWithSecnum_

pop   ax ; restore

dont_play_ceiling_sound_2:

cmp   cl, FLOOR_PASTDEST
jne   other_moveplane_result_type
cmp   al, CEILING_RAISETOHIGHEST ; 1
je    exit_t_moveceiling ; 1
cmp   al, CEILING_CRUSHANDRAISE ; 3
jb    switch_moveceiling_type_1 ; 0, 2
je    switch_moveceiling_type_2 ; 1

cmp   al, CEILING_SILENTCRUSHANDRAISE ; 5
jb    switch_moveceiling_type_3 ; 4
;jne   exit_t_moveceiling ; oob check? necessary?

; 5 fall thru


switch_moveceiling_type_4:
mov   dx, SFX_PSTOP
mov   ax, word ptr [bp - 2]
call  S_StartSoundWithSecnum_

; fall thru
switch_moveceiling_type_2:
mov   word ptr ds:[si + CEILING_T.ceiling_speed], CEILSPEED
; fall thru

switch_moveceiling_type_3:
mov   byte ptr ds:[si + CEILING_T.ceiling_direction], 1
jmp   exit_t_moveceiling
other_moveplane_result_type:
cmp   cl, FLOOR_CRUSHED
jne   exit_t_moveceiling
; 2 3 or 5. so not 4 and lower than 2
cmp   al, CEILING_FASTCRUSHANDRAISE ; 4
je    exit_t_moveceiling
cmp   al, CEILING_LOWERANDCRUSH ; 2
jb    exit_t_moveceiling

mov   word ptr ds:[si + CEILING_T.ceiling_speed], 1
jmp   exit_t_moveceiling
ENDP


; return in carry
PROC    EV_DoCeiling_ NEAR
PUBLIC  EV_DoCeiling_

;int16_t __near EV_DoCeiling ( uint8_t linetag, ceiling_e	type ) {


; bp - 2 type
; bp - 0202h  ; secnumlist

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
push  dx  ; bp - 2
sub   sp, 0200h
xchg  ax, bx ; bx gets linetag
xor   ax, ax
mov   byte ptr cs:[OFFSET SELFMODIFY_doceiling_return], CLC_OPCODE


cmp   dl, CEILING_CRUSHANDRAISE
jb    not_stasis_ceiling
je    do_activate_stasis
cmp   dl, CEILING_SILENTCRUSHANDRAISE
ja    not_stasis_ceiling
do_activate_stasis:

mov   ax, bx
call  P_ActivateInStasisCeiling_
not_stasis_ceiling:

lea   dx, [bp - 0202h]

xchg  ax, bx    ; last use of linetag

xor   bx, bx    ; false
mov   si, dx    ; si is loop secnum ptr with bp offset included.

call  P_FindSectorsFromLineTag_

cmp   word ptr ds:[si], 0
jl    exit_doceiling

loop_next_secnum:

lodsw        ; secnum
xchg  ax, cx



;		ceiling = (ceiling_t __near*) P_CreateThinker (TF_MOVECEILING_HIGHBITS);
mov   ax, TF_MOVECEILING_HIGHBITS
cwd  ; zero dx.
call  P_CreateThinker_


mov   bx, ax ; bx gets thinker
sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   di, SIZEOF_THINKER_T
div   di    ; calculate ceilingref


mov   di, cx  ; set up di as secnum << 4 for sector/sector_physics lookups now
SHIFT_MACRO shl   di, 4


mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
xchg  ax, dx ; dx stores ceilingref
xor   ax, ax
mov   byte ptr ds:[bx + CEILING_T.ceiling_crush], al
inc   ax
mov   byte ptr cs:[OFFSET SELFMODIFY_doceiling_return], STC_OPCODE


mov   word ptr ds:[bx + CEILING_T.ceiling_secnum], cx

mov   ax, SECTORS_SEGMENT
mov   es, ax ; get es ready

mov   al, byte ptr [bp - 2] ; type

cmp   al, CEILING_SILENTCRUSHANDRAISE ; 5
ja    switch_doceiling_default ; oob default
je    switch_doceiling_type_3  ; 5

cmp   al, CEILING_RAISETOHIGHEST ; 1
je    switch_doceiling_type_2 ; 1
jb    switch_doceiling_type_1 ; 0
cmp   al, CEILING_CRUSHANDRAISE ; 3
je    switch_doceiling_type_3 ; 3
ja    switch_doceiling_type_4 ; 4
;jb   switch_doceiling_type_2 ; 2
;jmp   switch_doceiling_type_2 ; 2
; fall thru

switch_doceiling_type_2:
xchg  ax, dx
xchg  ax, cx  ; ax gets secnum. cx stores ceilingref

mov   dx, 1 ; true
call  P_FindLowestOrHighestCeilingSurrounding_
mov   dx, cx  ; restore ceilingref.
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

mov   al, byte ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_tag]
mov   byte ptr ds:[bx + CEILING_T.ceiling_tag], al
mov   al, byte ptr [bp - 2]
mov   byte ptr ds:[bx], al
xchg  ax, dx  ; recover ceilingref

call  P_AddActiveCeiling_
cmp   word ptr ds:[si], 0
jnl   loop_next_secnum

exit_doceiling:
SELFMODIFY_doceiling_return:
clc
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

switch_doceiling_type_4:
mov   byte ptr ds:[bx + CEILING_T.ceiling_crush], 1
mov   byte ptr ds:[bx + CEILING_T.ceiling_direction], -1
mov   word ptr ds:[bx + CEILING_T.ceiling_speed], CEILSPEED * 2

mov   ax, word ptr es:[di + SECTOR_T.sec_ceilingheight]
mov   word ptr ds:[bx + CEILING_T.ceiling_topheight], ax

mov   ax, word ptr es:[di + SECTOR_T.sec_floorheight]
add   ax, (8 SHL SHORTFLOORBITS)
mov   word ptr ds:[bx + CEILING_T.ceiling_bottomheight], ax
jmp   done_with_doceiling_switch_block


switch_doceiling_type_3:
mov   byte ptr ds:[di + CEILING_T.ceiling_crush], 1
mov   ax, word ptr es:[di + SECTOR_T.sec_ceilingheight]
mov   word ptr ds:[bx + CEILING_T.ceiling_topheight], ax
;jmp   switch_doceiling_type_1 ; fall thru

switch_doceiling_type_1:
mov   ax, word ptr es:[di + SECTOR_T.sec_floorheight]
mov   word ptr ds:[bx + CEILING_T.ceiling_bottomheight], ax

cmp   byte ptr [bp - 2], CEILING_LOWERTOFLOOR
je    dont_pick_up_off_floor
add   word ptr ds:[bx + CEILING_T.ceiling_bottomheight], (8 SHL SHORTFLOORBITS)
dont_pick_up_off_floor:
mov   byte ptr ds:[bx + CEILING_T.ceiling_direction], -1
mov   word ptr ds:[bx + CEILING_T.ceiling_speed], CEILSPEED
jmp   done_with_doceiling_switch_block

ENDP




PROC    P_AddActiveCeiling_ FAR
PUBLIC  P_AddActiveCeiling_ 

;void __near P_AddActivePlat(THINKERREF thinkerref) {

push        di
push        cx
push        ax  ; store value..
mov         di, _activeceilings
push        ds
pop         es
xor         ax, ax ; look for 0 or NULL_THINKERREF
mov         cx, MAXCEILINGS

repne scasw
pop         ax ; retrieve...
jcxz        didnt_find_slot
found_slot_for_platadd:
stosw
didnt_find_slot:
pop         cx
pop         di
retf
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
jne   continue_statis_ceiling_loop
mov   al, byte ptr ds:[bx + CEILING_T.ceiling_olddirection]
mov   byte ptr ds:[bx + CEILING_T.ceiling_direction], al

xchg  ax, dx  ; recover _activeceilings into ax
mov   dx, TF_MOVECEILING_HIGHBITS
call  P_UpdateThinkerFunc_

continue_statis_ceiling_loop:
inc   cx
inc   cx
cmp   cl, (MAXCEILINGS * 2)
jl    loop_next_stasis_ceiling
pop   dx
pop   cx
pop   bx
ret   

ENDP


; return in carry
PROC    EV_CeilingCrushStop_ NEAR
PUBLIC  EV_CeilingCrushStop_


PUSHA_NO_AX_OR_BP_MACRO

mov   ch, al ; ch gets tag
xor   cl, cl ; cl is loop counter
mov   byte ptr cs:[OFFSET SELFMODIFY_ceilingcrush_return], CLC_OPCODE



loop_next_ceiling_crush_stop:
xor   bx, bx
mov   bl, cl

mov   bx, word ptr ds:[bx + _activeceilings]
test  bx, bx
je    continue_ceiling_crush_stop_loop
mov   ax, SIZEOF_THINKER_T
mul   bx
xchg  ax, bx ; ax gets activeceiling. bx gets thinkerlist offset.
xchg  ax, dx ; now dx gets activeceiling. ax has nothing.

add   bx, _thinkerlist + THINKER_T.t_data
cmp   ch, byte ptr ds:[bx  + CEILING_T.ceiling_tag]
jne   continue_ceiling_crush_stop_loop
mov   al, byte ptr ds:[bx + CEILING_T.ceiling_direction]
test  al, al
je    continue_ceiling_crush_stop_loop
mov   byte ptr ds:[bx + CEILING_T.ceiling_olddirection], al
xchg  ax, dx  ; recover _activeceilings into ax
cwd   ; dx gets 0  (TF_NULL)
mov   byte ptr cs:[OFFSET SELFMODIFY_ceilingcrush_return], STC_OPCODE

call  P_UpdateThinkerFunc_
mov   byte ptr ds:[bx + CEILING_T.ceiling_direction], 0
continue_ceiling_crush_stop_loop:
inc   cx
inc   cx
cmp   cl, (MAXCEILINGS * 2)
jl    loop_next_ceiling_crush_stop

POPA_NO_AX_OR_BP_MACRO
SELFMODIFY_ceilingcrush_return:
clc

ret   

ENDP


PROC    P_CEILNG_ENDMARKER_ NEAR
PUBLIC  P_CEILNG_ENDMARKER_
ENDP

END
