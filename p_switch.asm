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

EXTRN EV_DoFloor_:NEAR
EXTRN EV_DoDoor_:NEAR

EXTRN S_StartSoundWithSecnum_:NEAR
EXTRN EV_DoPlat_:NEAR
EXTRN EV_DoDonut_:NEAR
EXTRN EV_DoLockedDoor_:NEAR
EXTRN EV_VerticalDoor_:NEAR
EXTRN EV_BuildStairs_:NEAR
EXTRN EV_DoCeiling_:NEAR
EXTRN EV_LightChange_:NEAR




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

; bp - 2    sound
; bp - 4    lineside 0 shifted 3 for side_t lookup
; bp - 6    linenum
; bp - 8    linefrontsecnum

; useagain in di


push  bp
mov   bp, sp
xchg  bx, dx

mov   si, SIDES_SEGMENT
mov   es, si

mov   si, SFX_SWTCHN
SHIFT_MACRO shl   bx 3

; i think people dont like change... lets not fix this bug, and lets use the 'original' switch sfx. uncomment to fix the bug in vanilla
COMMENT  @
cmp   dl, 11  ; exit switch
jne   not_exit_switch
inc    si      ;mov   si, SFX_SWTCHX
not_exit_switch:

@


push  si  ; bp - 2 sfx
push  bx  ; bp - 4 lineside 0 shifted 3
push  ax  ; bp - 6 linenum
push  cx  ; bp - 8 linefrontsecnum


test  di, di ; pending branch
mov   di, word ptr es:[bx + SIDE_T.s_toptexture]
mov   dx, word ptr es:[bx + SIDE_T.s_midtexture]
mov   si, word ptr es:[bx + SIDE_T.s_bottomtexture]

mov   ax, 0c089h  ; 2 byte nop
jne   dont_mark_unusable

mov   bx, LINES_PHYSICS_SEGMENT
mov   es, bx
mov   bx, word ptr [bp - 6]
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

mov   dx, word ptr [bp - 2]  ; get sfx
pop   ax ; word ptr [bp - 8]  ; get linefrontsecnum
push  ax ; word ptr [bp - 8]  ; put back for later


call  S_StartSoundWithSecnum_


mov   si, cx
sal   si, 1
mov   ax, SIDES_SEGMENT
mov   es, ax

;			sides[lineside0].toptexture = switchlist[i^1];

mov   ax, word ptr ds:[si + _switchlist] ; ax is switchlist[i^1];
add   di, word ptr [bp - 4]  
stosw   ;mov   word ptr es:[di], ax

SELFMODIFY_changeswitchtexture_useagain:
jmp   exit_p_changeswitchtexture  ; jmp if 0. nop otherwise
SELFMODIFY_changeswitchtexture_useagain_AFTER:
do_startbutton_call:

pop   dx ;mov   dx, word ptr [bp - 8]
pop   ax ;mov   ax, word ptr [bp - 6]
mov   cx, word ptr ds:[bx + _switchlist]


; todo inlined only use.
;PROC    P_StartButton_
;PUBLIC  P_StartButton_


xchg  ax, si ; si holds ax
mov   ax, bx ; al holds w

mov   bx, _buttonlist

;	if (buttonlist[i].btimer && buttonlist[i].linenum == linenum)
;	    return;


do_next_button_check:
cmp   word ptr ds:[bx + BUTTON_T.button_btimer], 0
je    timer_0_skip
cmp   si, word ptr ds:[bx + BUTTON_T.button_linenum]
je    button_already_exists
timer_0_skip:
add   bx, SIZEOF_BUTTON_T
cmp   bx, (_buttonlist + MAXBUTTONS * SIZEOF_BUTTON_T)
jl    do_next_button_check

mov   bx, _buttonlist

loop_check_next_button:


cmp   word ptr ds:[bx + BUTTON_T.button_btimer], 0
jne   button_already_active

mov   word ptr ds:[bx + BUTTON_T.button_linenum], si
mov   byte ptr ds:[bx + BUTTON_T.button_where], al
mov   word ptr ds:[bx + BUTTON_T.button_btexture], cx
mov   word ptr ds:[bx + BUTTON_T.button_soundorg], dx
mov   word ptr ds:[bx + BUTTON_T.button_btimer], BUTTONTIME


jmp   exit_p_changeswitchtexture

button_already_active:
add   bx, (SIZE BUTTON_T)
cmp   bx, (_buttonlist + (MAXBUTTONS * (SIZE BUTTON_T)))
jl    loop_check_next_button

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



; return in carry 

PROC    P_UseSpecialLine_ NEAR
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
clc
jmp   exit_usespecialline
side_1_return_false:
clc
ret

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







special_line_type_4:
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
xor   di, di
call  P_ChangeSwitchTexture_
;call  G_ExitLevel_ ; inlined
mov   byte ptr ds:[_secretexit], 0
mov   byte ptr ds:[_gameaction], GA_COMPLETED

jmp   do_specialline_exit_1

special_line_type_5:
mov   cl, 32
mov   bl, PLATFORM_RAISEANDCHANGE

jmp   do_plat

special_line_type_44:
mov   dl, STAIRS_TURBO16
jmp   do_buildstairs


special_line_type_10:
mov   bl, FLOOR_LOWERFLOORTOLOWEST
do_floor:
mov   dx, si
call  EV_DoFloor_
jmp   check_change_switch_texture_0

special_line_type_6:
mov   cl, 24
mov   bl, PLATFORM_RAISEANDCHANGE
jmp   do_plat


special_line_type_8:
mov   bl, PLATFORM_RAISETONEARESTANDCHANGE

jmp   do_plat_zero_cx

special_line_type_9:
mov   bl, PLATFORM_DOWNWAITUPSTAY
do_plat_zero_cx:
xor   cx, cx
do_plat:

mov   dx, si
call  EV_DoPlat_
jmp   check_change_switch_texture_0


special_line_type_42:
mov   bl, PLATFORM_BLAZEDWUS
jmp   do_plat_zero_cx



special_line_type_3:
call  EV_DoDonut_

check_change_switch_texture_0:
;test  ax, ax
jnc    do_specialline_exit_1
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
jmp   check_change_switch_texture_0

special_line_type_16:
mov   dl, CEILING_CRUSHANDRAISE
jmp   do_ceiling


special_line_type_12:
xor   dx, dx ; CEILING_LOWERTOFLOOR
do_ceiling:
call  EV_DoCeiling_
jmp   check_change_switch_texture_0

special_line_type_7:
mov   bl, FLOOR_RAISEFLOORTONEAREST
jmp   do_floor

special_line_type_45:
mov   bl, FLOOR_RAISEFLOORTURBO
jmp   do_floor
special_line_type_50:
mov   bl, FLOOR_RAISEFLOOR512
jmp   do_floor
special_line_type_31:
mov   bl, DOOR_CLOSE
jmp   do_floor

special_line_type_2:
xor   dx, dx  ; STAIRS_BUILD8
do_buildstairs:
call  EV_BuildStairs_

jmp   check_change_switch_texture_0

special_line_case_default:
do_specialline_exit_1:
stc
exit_usespecialline:
LEAVE_MACRO 
pop   di
pop   si
ret


special_line_type_19:
mov   bl, FLOOR_RAISEFLOORCRUSH
jmp   do_floor
special_line_type_33:
mov   bl, FLOOR_RAISEFLOOR
jmp   do_floor
special_line_type_34:
xor   bx, bx
jmp   do_floor

special_line_type_17:
mov   dl, DOOR_CLOSE
jmp   do_door

special_line_type_35:
mov   dl, DOOR_OPEN
jmp   do_door
special_line_type_36:
mov   dl, DOOR_BLAZERAISE
jmp   do_door
special_line_type_37:
mov   dl, DOOR_BLAZEOPEN
jmp   do_door
special_line_type_38:
mov   dl, DOOR_BLAZECLOSE
jmp   do_door



special_line_type_18:
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
xor   di, di
call  P_ChangeSwitchTexture_

;call  G_SecretExitLevel_ ; inlined

mov    al, 1
cmp    byte ptr ds:[_commercial], al
jne    just_do_secret_exit
;    // IF NO WOLF3D LEVELS, NO SECRET EXIT!
mov    al, byte ptr ds:[_map31_exists]  ; secret exit only if map 31 exists in commecial game.
just_do_secret_exit:
mov    byte ptr ds:[_secretexit], al
mov    byte ptr ds:[_gameaction], GA_COMPLETED

jmp   do_specialline_exit_1






special_line_type_47:
shr   bx, 1
mov   dx, bx ; linespecial
; cx already thingref
mov   bl, DOOR_BLAZEOPEN
call  EV_DoLockedDoor_
jmp   check_change_switch_texture_0

special_line_type_21:
mov   dl, DOOR_OPEN
jmp   do_door_1
special_line_type_39:
mov   dl, DOOR_BLAZERAISE
jmp   do_door_1
special_line_type_40:
mov   dl, DOOR_BLAZEOPEN
jmp   do_door_1
special_line_type_41:
mov   dl, DOOR_BLAZECLOSE
jmp   do_door_1
special_line_type_23:
xor   dx, dx  ; DOOR_NORMAL
jmp   do_door_1
special_line_type_13:
mov   dl, DOOR_CLOSE
do_door_1:
call  EV_DoDoor_
check_change_switch_texture_1:
;test  ax, ax
jnc   do_specialline_exit_1
do_change_switch_texture_1:
pop   dx   ; bp - 4
xchg  ax, di
mov   cx, si
pop   bx   ; bp - 2
mov   di, 1
call  P_ChangeSwitchTexture_
jmp   do_specialline_exit_1

special_line_type_15:
xor   bx, bx ; FLOOR_LOWERFLOOR
do_floor_1:
mov   dx, si
call  EV_DoFloor_
jmp   check_change_switch_texture_1











special_line_type_14:
xor   dx, dx
call  EV_DoCeiling_
jmp   check_change_switch_texture_1



special_line_type_20:
mov   bl, FLOOR_LOWERFLOORTOLOWEST
jmp   do_floor_1
special_line_type_24:
mov   bl, FLOOR_RAISEFLOOR
jmp   do_floor_1
special_line_type_25:
mov   bl, FLOOR_RAISEFLOORCRUSH
jmp   do_floor_1
special_line_type_29:
mov   bl, FLOOR_RAISEFLOORTONEAREST
jmp   do_floor_1
special_line_type_30:
mov   bl, DOOR_CLOSE
jmp   do_floor_1
special_line_type_46:
mov   bl, FLOOR_RAISEFLOORTURBO
jmp   do_floor_1
special_line_type_27:
mov   cl, 32
mov   bl, PLATFORM_RAISEANDCHANGE
jmp   do_plat_1
special_line_type_43:
mov   bl, PLATFORM_BLAZEDWUS
do_plat_1_zero_cx:
xor   cx, cx
do_plat_1:
mov   dx, si
call  EV_DoPlat_
jmp   check_change_switch_texture_1

special_line_type_28:
mov   bl, PLATFORM_RAISETONEARESTANDCHANGE
jmp   do_plat_1_zero_cx

special_line_type_32:

shr   bx, 1
mov   dx, bx ; linespecial
; cx already thingref
mov   bl, DOOR_BLAZEOPEN
call  EV_DoLockedDoor_
jmp   check_change_switch_texture_1

special_line_type_22:

mov   bl, PLATFORM_DOWNWAITUPSTAY
mov   cx, bx ; 1
jmp   do_plat_1

special_line_type_26:
mov   cl, 24
mov   bl, PLATFORM_RAISEANDCHANGE
jmp   do_plat_1

special_line_type_48:
mov   bl, 255
do_lightchange_1:
mov   dl, 1
call  EV_LightChange_
mov   cx, si
jmp   do_change_switch_texture_1

special_line_type_49:
mov   bl, 35
jmp   do_lightchange_1





ENDP


ENDP

PROC    P_SWITCH_ENDMARKER_ 
PUBLIC  P_SWITCH_ENDMARKER_
ENDP


END