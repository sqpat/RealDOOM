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
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR
EXTRN T_MovePlaneFloorUp_:NEAR
EXTRN T_MovePlaneFloorDown_:NEAR
EXTRN P_Random_:NEAR
EXTRN P_UpdateThinkerFunc_:NEAR


.DATA



.CODE



PROC    P_PLATS_STARTMARKER_ NEAR
PUBLIC  P_PLATS_STARTMARKER_
ENDP


PROC    T_PlatRaise_ NEAR
PUBLIC  T_PlatRaise_ 

;void __near T_PlatRaise(plat_t __near* plat, THINKERREF platRef) {


PUSHA_NO_AX_OR_BP_MACRO
push        bp
mov         bp, sp
xchg        ax, si
push        dx ; bp - 2
mov         di, word ptr ds:[si + PLAT_T.plat_secnum]
mov         bx, di
mov         es, word ptr ds:[_SECTORS_SEGMENT_PTR]
SHIFT_MACRO shl         bx 4
xor         cx, cx
mov         ax, cx
mov         dx, word ptr ds:[si + PLAT_T.plat_speed]
mov         al, byte ptr ds:[si + PLAT_T.plat_status]
cmp         al, PLAT_IN_STASIS ; 3
je          platraise_switch_case_default ; 3
dec         ax  ; -1 0 or 1... easy test
mov         ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
xchg        ax, bx ; bx gets floorheight. ax gets sector offset.
; ax sector offset (FP_OFF(platsector))
; bx floorheight
; dx plat speed
; cx 0
; di secnum
; si plat
jz          platraise_switch_case_1       ; 1
jns         platraise_switch_case_2       ; 2
; fall thru
platraise_switch_case_0: ; 0
mov         cl, byte ptr ds:[si + PLAT_T.plat_crush]
mov         bx, word ptr ds:[si + PLAT_T.plat_high]
call        T_MovePlaneFloorUp_
xchg        ax, cx ; cx gets that result for now
mov         al, byte ptr ds:[si + PLAT_T.plat_type]
cmp         al, PLATFORM_RAISEANDCHANGE
je          check_level_time
cmp         al, PLATFORM_RAISETONEARESTANDCHANGE
jne         done_checking_level_time

check_level_time:
test        byte ptr ds:[_leveltime], 7
jne         done_checking_level_time
mov         dx, SFX_STNMOV
mov         ax, di
call        S_StartSoundWithParams_
done_checking_level_time:
mov         dx, SFX_PSTART  ; in case we play this platform sound
xor         bx, bx ; clear bx flag. use bx flag to determine if its the branch that does a 2nd switch block later
xchg        ax, cx ; restore res field
cmp         al, FLOOR_CRUSHED
jne         floor_not_crush
cmp         byte ptr ds:[si + PLAT_T.plat_crush], 0
je          start_platform_sound
floor_not_crush:
mov         dx, SFX_PSTOP ; in case played
cmp         al, FLOOR_PASTDEST
jne         done_with_platraise_switch_block    

mov         bl, 1 ; set bx flag
start_platform_sound:

jmp         set_stuff_play_sound_and_exit_t_platraise


platraise_switch_case_1:
mov         bx, word ptr ds:[si + PLAT_T.plat_low]
call        T_MovePlaneFloorDown_
cmp         al, FLOOR_PASTDEST ; 2
jne         done_with_platraise_switch_block
mov         dx, SFX_PSTOP
xor         bx, bx ; clear bx flag
set_stuff_play_sound_and_exit_t_platraise:
mov         byte ptr ds:[si + PLAT_T.plat_status], al ; al is 2 in the  2 case (plat_waiting == floor_pastdest) or 1 in the 1 case (floor_crushed == plat_down)
mov         al, byte ptr ds:[si + PLAT_T.plat_wait]
mov         byte ptr ds:[si + PLAT_T.plat_count], al
test        bx, bx ; look for flag
jnz         do_second_switch_block
jmp         set_status_play_sound_and_exit_t_platraise
platraise_switch_case_2:
dec         byte ptr ds:[si + PLAT_T.plat_count]
jne         done_with_platraise_switch_block
cmp         bx, word ptr ds:[si + PLAT_T.plat_low]   ; bx has sec floorheight
je          write_plat_up
inc         cx  ; plat_down = 1. plat_up = 0. cx was 0 to start.
write_plat_up:
mov         dx, SFX_PSTART
mov         byte ptr ds:[si + PLAT_T.plat_status], cl
set_status_play_sound_and_exit_t_platraise:
xchg        ax, di
call        S_StartSoundWithParams_
platraise_switch_case_3:
platraise_switch_case_default:
done_with_platraise_switch_block:
LEAVE_MACRO       
POPA_NO_AX_OR_BP_MACRO
ret      
do_second_switch_block:

mov         al, byte ptr ds:[si + PLAT_T.plat_type]
cmp         al, PLATFORM_BLAZEDWUS
ja          done_with_platraise_switch_block
cmp         al, PLATFORM_DOWNWAITUPSTAY
jb          done_with_platraise_switch_block

remove_plat_and_exit:
pop         ax  ; bp - 2
call        P_RemoveActivePlat_  ; todo inline?
LEAVE_MACRO       
POPA_NO_AX_OR_BP_MACRO
ret      
ENDP


jump_to_exit:
jmp         return_rtn_and_exit
PROC    EV_DoPlat_ NEAR
PUBLIC  EV_DoPlat_ 

;int16_t __near EV_DoPlat (  uint8_t linetag, int16_t linefrontsecnum,plattype_e	type,int16_t		amount ){

; bp - 1    linetag
; bp - 2    type


push        si
push        di
push        bp
mov         bp, sp
mov         bh, al   ; linetag in bh
push        bx ; bp - 2
mov         si, dx
SHIFT_MACRO shl         si 4
add         si, SECTOR_T.sec_floorpic
mov         word ptr cs:[SELFMODIFY_read_floorpic_hardcoded_offset+2], si
sub         sp, 0200h
SHIFT_MACRO shl         cx SHORTFLOORBITS
mov         word ptr cs:[OFFSET SELFMODIFY_set_amount + 1], cx
xor         ax, ax

mov         byte ptr cs:[SELFMODIFY_ev_doplatset_rtn+1], al
test        bl, bl  ; perpetualRaise
jne         not_perpetualRaise
mov         al, bh  ; linetag
xor         dx, dx
xor         ah, ah
call        EV_PlatFunc_
not_perpetualRaise:

mov         al, bh  ; linetag
lea         dx, [bp - 0202h]
mov         si, dx
xor         bx, bx
call        P_FindSectorsFromLineTag_

cmp         word ptr [si], 0
jl          jump_to_exit

loop_next_secnum_doplat:
lodsw
mov         cx, ax 
push        si
SHIFT_MACRO shl         ax 4
xchg        ax, si  ; si is sectors[secnum]
mov         ax, TF_PLATRAISE_HIGHBITS
cwd

call        P_CreateThinker_

mov         bx, ax ; bx gets plat. todo swap bx/si used for consistency with other funcs like this?

sub         ax, (_thinkerlist + THINKER_T.t_data)
mov         di, SIZEOF_THINKER_T
div         di

mov         es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov         di, word ptr es:[si + SECTOR_T.sec_floorheight]

mov         byte ptr cs:[SELFMODIFY_ev_doplatset_rtn+1], 1


mov         word ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov         word ptr cs:[SELFMODIFY_setplatref+1], ax
xor         ax, ax
cwd
mov         byte ptr ds:[bx + PLAT_T.plat_crush], al
mov         ax, word ptr [bp - 2]
mov         byte ptr ds:[bx + PLAT_T.plat_tag], ah
mov         byte ptr ds:[bx + PLAT_T.plat_type], al
mov         word ptr ds:[bx + PLAT_T.plat_secnum], cx




; ax is type
; cx is secnum
; bx is plat.
; dx is 0
; si is sectors[secnum]
; di is floorheight



; cases 0-4.

cmp         al, PLATFORM_RAISETONEARESTANDCHANGE ; 3
ja          switch_block_ev_doplat_case_blazeDWUS ; 4
je          switch_block_ev_doplat_case_raiseToNearestAndChange ; 3
cmp         al, PLATFORM_DOWNWAITUPSTAY ; 1
ja          switch_block_ev_doplat_case_raiseAndChange ; 2
je          switch_block_ev_doplat_case_downWaitUpStay ; 1

jb          switch_block_ev_doplat_case_perpetualRaise ; 0
jmp         done_with_ev_doplat_switchblock


switch_block_ev_doplat_case_perpetualRaise:
mov         ax, cx
mov         word ptr ds:[bx + PLAT_T.plat_speed], PLATSPEED
call        P_FindHighestOrLowestFloorSurrounding_
cmp         ax, di
jl          dont_cap_specialheight_1
mov         ax, di
dont_cap_specialheight_1:
mov         word ptr ds:[bx + PLAT_T.plat_low], ax
mov         dx, 1
mov         ax, cx
call        P_FindHighestOrLowestFloorSurrounding_

cmp         ax, di
jg          dont_cap_specialheight_2
xchg        ax, di
dont_cap_specialheight_2:
mov         word ptr ds:[bx + PLAT_T.plat_high], ax
call        P_Random_
and         al, 1
mov         byte ptr ds:[bx + PLAT_T.plat_status], al
jmp         done_with_ev_doplat_switchblock_play_pstart
 
switch_block_ev_doplat_case_raiseToNearestAndChange:

mov         byte ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_special], dl
mov         dx, di
mov         ax, cx
call        P_FindNextHighestFloor_
mov         word ptr ds:[bx + PLAT_T.plat_high], ax

set_raise_and_change_stuff:

mov         es, word ptr ds:[_SECTORS_SEGMENT_PTR]
SELFMODIFY_read_floorpic_hardcoded_offset:
mov         al, byte ptr es:[01000h]  ; func local sector's floorpic 
;mov         al, byte ptr es:[di + SECTOR_T.sec_floorpic]

mov         byte ptr es:[si + SECTOR_T.sec_floorpic], al

mov         ax, (PLATSPEED / 2) ; 4
mov         word ptr ds:[bx + PLAT_T.plat_speed], ax

mov         byte ptr ds:[bx + PLAT_T.plat_status], ah ; PLAT_UP ; 0
mov         byte ptr ds:[bx + PLAT_T.plat_wait], ah ; 0

mov         dx, SFX_STNMOV
jmp         done_with_ev_doplat_switchblock_play_sound
switch_block_ev_doplat_case_raiseAndChange:

xchg        ax, di
SELFMODIFY_set_amount:
add         ax, 01000h
mov         word ptr ds:[bx + PLAT_T.plat_high], ax
jmp         set_raise_and_change_stuff


switch_block_ev_doplat_case_blazeDWUS:
mov         word ptr ds:[bx + PLAT_T.plat_speed], PLATSPEED * 8
jmp         do_plat_down
switch_block_ev_doplat_case_downWaitUpStay:
mov         word ptr ds:[bx + PLAT_T.plat_speed], PLATSPEED * 4
do_plat_down:
mov         ax, cx
call        P_FindHighestOrLowestFloorSurrounding_
mov         word ptr ds:[bx + PLAT_T.plat_high], di
cmp         ax, di
jl          dont_cap_specialheight_3
xchg        ax, di
dont_cap_specialheight_3:
mov         word ptr ds:[bx + PLAT_T.plat_low], ax
mov         byte ptr ds:[bx + PLAT_T.plat_status], PLAT_DOWN
done_with_ev_doplat_switchblock_play_pstart:
mov         byte ptr ds:[bx + PLAT_T.plat_wait], PLATWAIT * 35
mov         dx, SFX_PSTART
done_with_ev_doplat_switchblock_play_sound:
xchg        ax, cx
call        S_StartSoundWithParams_

done_with_ev_doplat_switchblock:
SELFMODIFY_setplatref:
mov         ax, 01000h

call        P_AddActivePlat_
pop         si
cmp         word ptr [si], 0
jl          return_rtn_and_exit
jmp         loop_next_secnum_doplat
return_rtn_and_exit:
SELFMODIFY_ev_doplatset_rtn:
mov         al, 010h
LEAVE_MACRO       
pop         di
pop         si
ret        
ENDP




PROC    EV_PlatFunc_ NEAR
PUBLIC  EV_PlatFunc_ 

;void __near EV_PlatFunc(uint8_t linetag, int8_t type) {

push        bx
push        cx
push        si
mov         byte ptr cs:[OFFSET SELFMODIFY_platfunc_linetag + 4], al

mov         cx, dx ; type in dl. dx gets clobbered by mul, func calls

mov         si, _activeplats

loop_next_active_plat:
lodsw
test        ax, ax
je          iter_next_active_plat
xchg        bx, ax ; store ref
mov         ax, SIZEOF_THINKER_T
mul         bx
xchg        ax, bx ; bx gets ptr, ax gets ref. dx is 0 
SELFMODIFY_platfunc_linetag:
cmp         byte ptr ds:[bx + _thinkerlist + t_data + PLAT_T.plat_tag], 010h
jne         iter_next_active_plat
mov         ch, byte ptr ds:[bx + PLAT_T.plat_status]
test        cl, cl
jne         check_stop_plat_status    ; 1 = PLAT_FUNC_STOP_PLAT
; check in stasis status
cmp         ch, PLAT_FUNC_IN_STASIS
jne         iter_next_active_plat
mov         dx, TF_PLATRAISE_HIGHBITS
jmp         do_update_thinker_call

check_stop_plat_status:
cmp         ch, PLAT_FUNC_IN_STASIS
je          iter_next_active_plat
mov         byte ptr ds:[bx + PLAT_T.plat_status], PLAT_FUNC_IN_STASIS
cwd         ; ax has ref which is < maxthinkers
;mov         dx, TF_NULL_HIGHBITS  ; 0
do_update_thinker_call:
mov         byte ptr ds:[bx + PLAT_T.plat_oldstatus], ch
; ax already this.
;mov         ax, word ptr ds:[bx + _activeplats]
call        P_UpdateThinkerFunc_
iter_next_active_plat:
cmp         si, _activeplats + (2 * MAXPLATS)
jl          loop_next_active_plat

pop         si
pop         cx
pop         bx
ret         

ENDP

PROC    P_AddActivePlat_ FAR
PUBLIC  P_AddActivePlat_ 

;void __near P_AddActivePlat(THINKERREF thinkerref) {

push        di
push        cx
push        ax  ; store value..
mov         di, _activeplats
push        ds
pop         es
xor         ax, ax ; look for 0 or NULL_THINKERREF
mov         cx, MAXPLATS

repne scasw
pop         ax ; retrieve...
jnz         didnt_find_slot

found_slot_for_platadd:
dec         di
dec         di
stosw
didnt_find_slot:
pop         cx
pop         di
retf         


ENDP

PROC    P_RemoveActivePlat_ NEAR
PUBLIC  P_RemoveActivePlat_ 
;void __near P_RemoveActivePlat(THINKERREF platRef) {


push        si
push        dx
mov         si, _activeplats
xchg        ax, dx
loop_look_for_empty_platslot_removeactiveplat:
lodsw
cmp         ax, dx
je          found_plat_to_remove
cmp         si, (_activeplats + MAXPLATS * 2)
jl          loop_look_for_empty_platslot_removeactiveplat
jmp         exit_removeactiveplat
found_plat_to_remove:

push        si  ; store activeplats[si] ptr
xchg        ax, si  ; si gets platref
mov         ax, SIZEOF_THINKER_T
mul         si ; dx zeroed.
xchg        ax, si  ; si gets ptr. ax gets platref back. dx is zeroed from mul

mov         si, word ptr [si + _thinkerlist + THINKER_T.t_data + PLAT_T.plat_secnum]
SHIFT_MACRO shl         si 4

call        P_RemoveThinker_

mov         word ptr [si + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], dx ; 0
pop         si
mov         word ptr [si], dx ; 0

exit_removeactiveplat:
pop         dx
pop         si
ret  

ENDP


PROC    P_PLATS_ENDMARKER_ NEAR
PUBLIC  P_PLATS_ENDMARKER_
ENDP


END