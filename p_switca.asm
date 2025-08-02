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

EXTRN _P_RemoveMobj:DWORD
EXTRN _P_DropWeaponFar:DWORD
EXTRN _P_SpawnMobj:DWORD
EXTRN _P_SetMobjState:DWORD

EXTRN EV_DoFloor_:PROC
EXTRN EV_DoDoor_:PROC
EXTRN G_ExitLevel_:PROC
EXTRN G_SecretExitLevel_:PROC
EXTRN EV_DoPlat_:NEAR
EXTRN EV_DoDonut_:NEAR
EXTRN EV_DoLockedDoor_:NEAR
EXTRN EV_VerticalDoor_:NEAR
EXTRN EV_BuildStairs_:NEAR
EXTRN EV_DoCeiling_:NEAR
EXTRN EV_LightChange_:NEAR

;EXTRN dofilelog_:NEAR


.DATA




.CODE




PROC    P_SWITCH_STARTMARKER_ NEAR
PUBLIC  P_SWITCH_STARTMARKER_
ENDP

;void __near P_StartButton ( int16_t linenum,int16_t linefrontsecnum,bwhere_e	w,int16_t		texture,int16_t		time ){


; no need to push/pop. outer frame calls before return.






PROC    P_ChangeSwitchTexture_ NEAR
PUBLIC  P_ChangeSwitchTexture_

;void __near P_ChangeSwitchTexture ( int16_t linenum, int16_t lineside0, uint8_t linespecial, int16_t linefrontsecnum,int16_t 		useAgain ){

; bp - 2    (UNUSED) midtexture
; bp - 4    sound
; bp - 6    lineside 0 shifted 3 for side_t lookup
; bp - 8    linenum
; bp - 0Ah  linefrontsecnum

; useagain in di


push  bp
mov   bp, sp
sub   sp, 6
push  ax
push  cx
xchg  bx, dx

mov   cx, SIDES_SEGMENT
mov   es, cx

mov   word ptr [bp - 4], SFX_SWTCHN

SHIFT_MACRO shl   bx 3
mov   word ptr [bp - 6], bx
cmp   dl, 11  ; exit switch
jne   not_exit_switch
mov   word ptr [bp - 4], SFX_SWTCHX
not_exit_switch:


test  di, di ; pending branch
mov   di, word ptr es:[bx + SIDE_T.s_toptexture]
mov   dx, word ptr es:[bx + SIDE_T.s_midtexture]
mov   si, word ptr es:[bx + SIDE_T.s_bottomtexture]

mov   ax, 0c089h  ; 2 byte nop
jne   dont_mark_unusable

mov   bx, LINES_PHYSICS_SEGMENT
mov   es, bx
mov   bx, word ptr [bp - 8]
SHIFT_MACRO shl   bx 4
mov   byte ptr es:[bx + LINE_PHYSICS_T.lp_special], 0
mov   ax, ((OFFSET exit_p_changeswitchtexture - OFFSET SELFMODIFY_changeswitchtexture_useagain_AFTER) SHL 8) + 0EBh ; jump
dont_mark_unusable:

mov   word ptr cs:[SELFMODIFY_changeswitchtexture_useagain], ax

xor   ax, ax
check_next_switch:

mov   bx, word ptr ds:[_numswitches]

sal   bx, 1
cmp   ax, bx
jnge  dont_exit_p_changeswitchtexture
LEAVE_MACRO 
ret
dont_exit_p_changeswitchtexture:
mov   bx, ax
sal   bx, 1
mov   cx, ax
mov   bx, word ptr ds:[bx + _switchlist]
xor   cl, 1

cmp   bx, di
je    is_top_texture

cmp   bx, dx
je    is_mid_texture
cmp   bx, si
je    is_bottom_texture
inc   ax
jmp   check_next_switch

is_top_texture:
mov   bx, BUTTONTOP
mov   di, SIDE_T.s_toptexture


do_button_texture_stuff:

xor   dx, dx
mov   dl, byte ptr [bp - 4]
mov   ax, word ptr ds:[_buttonlist + BUTTON_T.button_soundorg] ; jank. bug in original source?

call  S_StartSoundWithParams_


mov   si, cx
sal   si, 1
mov   ax, SIDES_SEGMENT
mov   es, ax

;			sides[lineside0].toptexture = switchlist[i^1];

mov   ax, word ptr ds:[si + _switchlist] ; ax is switchlist[i^1];
add   di, word ptr [bp - 6]  
stosw   ;mov   word ptr es:[di], ax

SELFMODIFY_changeswitchtexture_useagain:
jmp   exit_p_changeswitchtexture  ; jmp if 0. nop otherwise
SELFMODIFY_changeswitchtexture_useagain_AFTER:
do_startbutton_call:

pop   dx ;mov   dx, word ptr [bp - 0Ah]
pop   ax ;mov   ax, word ptr [bp - 8]
mov   cx, word ptr ds:[bx + _switchlist]


; todo inlined only use.
;PROC    P_StartButton_
;PUBLIC  P_StartButton_


xchg  ax, si ; si holds ax
mov   ax, bx ; al holds w

mov   bx, _buttonlist

do_next_button_check:
cmp   word ptr ds:[bx + BUTTON_T.button_btimer], 0
je    timer_0_skip
cmp   si, word ptr ds:[bx + BUTTON_T.button_linenum]
je    button_already_exists
timer_0_skip:
add   bx, SIZEOF_BUTTON_T
cmp   bx, (_buttonlist + MAXBUTTONS * SIZEOF_BUTTON_T)
jl    do_next_button_check

mov   bx, _buttonlist + BUTTON_T.button_btimer

loop_check_next_bitton:


cmp   word ptr ds:[bx], 0
jne   button_already_active

mov   word ptr ds:[bx + _buttonlist + BUTTON_T.button_linenum], si
mov   byte ptr ds:[bx + _buttonlist + BUTTON_T.button_where], al
mov   word ptr ds:[bx + _buttonlist + BUTTON_T.button_btexture], cx
mov   word ptr ds:[bx + _buttonlist + BUTTON_T.button_soundorg], dx
mov   ax, BUTTONTIME
mov   word ptr ds:[bx + _buttonlist + BUTTON_T.button_btimer], ax

;ret   
jmp   exit_p_changeswitchtexture

button_already_active:
add   bx, SIZEOF_BUTTON_T
cmp   bx, (_buttonlist + BUTTON_T.button_btimer + MAXBUTTONS * SIZEOF_BUTTON_T)
jl    loop_check_next_bitton

button_already_exists:


; ENDP

exit_p_changeswitchtexture:
LEAVE_MACRO 
ret



is_mid_texture:
mov   bx, BUTTONMIDDLE
mov   di, SIDE_T.s_midtexture

jmp    do_button_texture_stuff





is_bottom_texture:
mov   bx, BUTTONBOTTOM
mov   di, SIDE_T.s_bottomtexture

jmp   do_button_texture_stuff



ENDP

_special_line_switch_block:

dw special_line_type_0, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_2, special_line_case_default, special_line_type_3, special_line_case_default, special_line_type_4, special_line_case_default, special_line_case_default, special_line_type_5, special_line_type_6
dw special_line_case_default, special_line_case_default, special_line_type_7, special_line_case_default, special_line_type_8, special_line_type_9, special_line_case_default, special_line_type_10, special_line_case_default, special_line_case_default, special_line_type_0, special_line_type_0, special_line_type_0, special_line_type_11, special_line_case_default
dw special_line_type_0, special_line_type_0, special_line_type_0, special_line_type_0, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_12, special_line_type_13, special_line_type_14, special_line_case_default, special_line_type_15
dw special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_16, special_line_type_17, special_line_type_18, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_19, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_20
dw special_line_type_21, special_line_type_22, special_line_type_23, special_line_type_24, special_line_type_25, special_line_type_26, special_line_type_27, special_line_type_28, special_line_type_29, special_line_type_30, special_line_type_31, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default
dw special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default
dw special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_32, special_line_case_default, special_line_type_33, special_line_type_34, special_line_type_35, special_line_case_default, special_line_case_default
dw special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_36, special_line_type_37, special_line_type_38, special_line_type_39, special_line_type_40, special_line_type_41, special_line_type_0, special_line_type_0, special_line_case_default, special_line_case_default
dw special_line_case_default, special_line_type_42, special_line_type_43, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_44, special_line_case_default, special_line_case_default, special_line_case_default, special_line_type_45, special_line_type_46, special_line_type_47, special_line_type_32, special_line_type_47
dw special_line_type_32, special_line_type_47, special_line_type_48, special_line_type_49, special_line_type_50



PROC    P_UseSpecialLine_ FAR
PUBLIC  P_UseSpecialLine_

;boolean __far P_UseSpecialLine ( mobj_t __near*	thing, int16_t linenum,int16_t		side,THINKERREF thingRef){               
; args:
; ax thing
; dx linenum
; cx thingref

; ax/thing not used at all. 

; thingref not used much. can quick out with it. put in bp - 2 and otherwise clean hands of it?

cmp   bx, 0
jne   side_1_return_false
; bx free, side not used again. TODO move this check out of the function.

;call  logcase_


push  si
push  di
push  bp
mov   bp, sp


mov   di, dx

mov   bx, LINES_PHYSICS_SEGMENT
mov   es, bx
mov   bx, di  ; linenum
SHIFT_MACRO sal bx 4

mov   dx, word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum]
mov   al, byte ptr es:[bx + LINE_PHYSICS_T.lp_special]
mov   bl, byte ptr es:[bx + LINE_PHYSICS_T.lp_tag]     ; could get these both in one read...

cmp   cx, ds:[_playerMobjRef]
je    skip_player_check
mov   si, LINEFLAGSLIST_SEGMENT
mov   es, si
test  byte ptr es:[di], ML_SECRET
jne   monster_secret_return_false
cmp   al, 1
je    finished_with_player_check
cmp   al, 32
jb    bad_monster_special_return_false
cmp   al, 34
jbe   finished_with_player_check
monster_secret_return_false:
bad_monster_special_return_false:
xor   ax, ax
jmp   exit_usespecialline
side_1_return_false:
xor   ax, ax
retf

finished_with_player_check:
skip_player_check:

; need lineside0, put on stack

xor   ah, ah
xchg  ax, bx ; put linetag, special back where it needs to be
xor   ah, ah
mov   si, LINES_SEGMENT
mov   es, si
mov   si, di
SHIFT_MACRO sal   si 2
push  bx    ; bp - 2 linespecial 
push  word ptr es:[si + LINE_T.l_sidenum]  ; bp - 4 lineside0
mov   si, dx   ; linesecnum in si too
sal   bx, 1

; ax is linetag
; dx/si are linesecnum
; bx is linespecial shl 1 for jump. can be recovered with shr 1
; di is linenum
; cx is thingref
; bp - 2 (2nd pop)  is linespecial
; bp - 4 (next pop) is lineside0

jmp   word ptr cs:[bx + (OFFSET _special_line_switch_block) - 2] ; didnt dec bx. offset 2 extra.

special_line_type_0:
xchg  ax, di
mov   dx, cx
call  EV_VerticalDoor_


jmp   do_specialline_exit_1




special_line_type_44:
mov   dx, STAIRS_TURBO16
jmp   do_buildstairs



special_line_type_4:
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
xor   di, di
call  P_ChangeSwitchTexture_
call  G_ExitLevel_
jmp   do_specialline_exit_1

special_line_type_5:
mov   cx, 32
mov   bx, PLATFORM_RAISEANDCHANGE

jmp   do_plat



special_line_type_10:
mov   bx, FLOOR_LOWERFLOORTOLOWEST
do_floor:
mov   dx, si
call  EV_DoFloor_
test  ax, ax
je    do_specialline_exit_1
jmp   do_change_switch_texture_0

special_line_type_6:
mov   cx, 24
mov   bx, PLATFORM_RAISEANDCHANGE
jmp   do_plat


special_line_type_8:
mov   bx, PLATFORM_RAISETONEARESTANDCHANGE

jmp   do_plat_zero_cx

special_line_type_9:
mov   bx, PLATFORM_DOWNWAITUPSTAY
do_plat_zero_cx:
xor   cx, cx
do_plat:

mov   dx, si
call  EV_DoPlat_
test  ax, ax
jne   do_change_switch_texture_0
jmp   do_specialline_exit_1


special_line_type_42:
mov   bx, PLATFORM_BLAZEDWUS
jmp   do_plat_zero_cx



special_line_type_3:
call  EV_DoDonut_
test  ax, ax
je    do_specialline_exit_1

do_change_switch_texture_0:
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
xor   di, di
call  P_ChangeSwitchTexture_
jmp   do_specialline_exit_1
special_line_type_11:
xor   dx, dx

do_door:
call  EV_DoDoor_
test  ax, ax
je    do_specialline_exit_1

jmp   do_change_switch_texture_0

special_line_type_16:
mov   dx, 3
jmp   do_ceiling


special_line_type_12:
xor   dx, dx
do_ceiling:
call  EV_DoCeiling_
test  ax, ax
jne   do_change_switch_texture_0
exit_usespecialline_return_1_2:
jmp   do_specialline_exit_1

special_line_type_7:
mov   bx, FLOOR_RAISEFLOORTONEAREST
jmp   do_floor

special_line_type_45:
mov   bx, FLOOR_RAISEFLOORTURBO
jmp   do_floor
special_line_type_50:
mov   bx, 0Ch  ;todo
jmp   do_floor
special_line_type_31:
mov   bx, DOOR_CLOSE
jmp   do_floor

special_line_type_2:
xor   dx, dx  ; STAIRS_BUILD8
do_buildstairs:
call  EV_BuildStairs_
test  ax, ax
je    do_specialline_exit_1
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
xor   di, di
call  P_ChangeSwitchTexture_
special_line_case_default:

do_specialline_exit_1:
mov   al, 1
exit_usespecialline:
LEAVE_MACRO 
pop   di
pop   si
retf  

special_line_type_19:
mov   bx, FLOOR_RAISEFLOORCRUSH
jmp   do_floor
special_line_type_33:
mov   bx, 3
jmp   do_floor
special_line_type_34:
xor   bx, bx
jmp   do_floor

special_line_type_17:
mov   dx, 2
jmp   do_door

special_line_type_35:
mov   dx, 3
jmp   do_door
special_line_type_36:
mov   dx, 5
jmp   do_door
special_line_type_37:
mov   dx, 6
jmp   do_door
special_line_type_38:
mov   dx, 7
jmp   do_door



special_line_type_18:
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
xor   di, di
call  P_ChangeSwitchTexture_
call  G_SecretExitLevel_
jump_to_exit_usespecialline_return_1_2:
jmp   do_specialline_exit_1






special_line_type_47:
shr   bx, 1
mov   dx, bx ; linespecial
; cx already thingref
mov   bx, DOOR_BLAZEOPEN
call  EV_DoLockedDoor_

test  ax, ax
jne   do_specialline_exit_1
jmp   do_change_switch_texture_0

special_line_type_21:
mov   dx, 3
jmp   do_door_1
special_line_type_39:
mov   dx, 5
jmp   do_door_1
special_line_type_40:
mov   dx, 6
jmp   do_door_1
special_line_type_41:
mov   dx, 7
jmp   do_door_1
special_line_type_23:
xor   dx, dx
jmp   do_door_1

special_line_type_15:
xor   bx, bx
do_floor_1:
mov   dx, si
call  EV_DoFloor_
test  ax, ax
jne   do_change_switch_texture_1
jmp   do_specialline_exit_1







special_line_type_13:
mov   dx, 2
do_door_1:
call  EV_DoDoor_
test  ax, ax
je    jump_to_exit_usespecialline_return_1_2
do_change_switch_texture_1:
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
mov   di, 1
call  P_ChangeSwitchTexture_
jmp   do_specialline_exit_1




special_line_type_14:
xor   dx, dx
call  EV_DoCeiling_
test  ax, ax
jne   do_change_switch_texture_1
jmp   do_specialline_exit_1



special_line_type_20:
mov   bx, FLOOR_LOWERFLOORTOLOWEST
jmp   do_floor_1
special_line_type_24:
mov   bx, 3
jmp   do_floor_1
special_line_type_25:
mov   bx, FLOOR_RAISEFLOORCRUSH
jmp   do_floor_1
special_line_type_29:
mov   bx, FLOOR_RAISEFLOORTONEAREST
jmp   do_floor_1
special_line_type_30:
mov   bx, DOOR_CLOSE
jmp   do_floor_1
special_line_type_46:
mov   bx, FLOOR_RAISEFLOORTURBO
jmp   do_floor_1
special_line_type_27:
mov   cx, 32
mov   bx, PLATFORM_RAISEANDCHANGE
jmp   do_plat_1
special_line_type_43:
mov   bx, PLATFORM_BLAZEDWUS
do_plat_1_zero_cx:
xor   cx, cx
do_plat_1:
mov   dx, si
call  EV_DoPlat_
test  ax, ax
jne   do_change_switch_texture_1
jmp   do_specialline_exit_1

special_line_type_28:
mov   bx, PLATFORM_RAISETONEARESTANDCHANGE
jmp   do_plat_1_zero_cx

special_line_type_32:

shr   bx, 1
mov   dx, bx ; linespecial
; cx already thingref
mov   bx, DOOR_BLAZEOPEN
call  EV_DoLockedDoor_

test  ax, ax
jne   do_change_switch_texture_1
jmp   do_specialline_exit_1

special_line_type_22:

mov   bx, PLATFORM_DOWNWAITUPSTAY
mov   cx, bx ; 1
jmp   do_plat_1

special_line_type_26:
mov   cx, 24
mov   bx, PLATFORM_RAISEANDCHANGE
jmp   do_plat_1

special_line_type_48:
mov   bx, 255
do_lightchange_1:
mov   dx, 1
call  EV_LightChange_
mov   cx, si
jmp   do_change_switch_texture_1

special_line_type_49:
mov   bx, 35
mov   dx, 1
jmp   do_lightchange_1





ENDP
COMMENT @
PROC   logcase_
pusha

mov    ax, dx
call   dofilelog_
popa

ret
@


ENDP

PROC    P_SWITCH_ENDMARKER_ 
PUBLIC  P_SWITCH_ENDMARKER_
ENDP


END