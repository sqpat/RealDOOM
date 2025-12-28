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
INCLUDE sound.inc
INSTRUCTION_SET_MACRO


EXTRN S_StartSound_:NEAR
EXTRN S_StartSoundWithSecnum_:NEAR
EXTRN P_RemoveThinker_:NEAR
EXTRN P_CreateThinker_:NEAR
EXTRN P_ChangeSector_:NEAR
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR



SHORTFLOORBITS = 3

.DATA




.CODE



PROC    P_FLOOR_STARTMARKER_ NEAR
PUBLIC  P_FLOOR_STARTMARKER_
ENDP

PROC    T_MovePlaneCeilingDown_ NEAR
PUBLIC  T_MovePlaneCeilingDown_

;result_e __near T_MovePlaneCeilingDown ( uint16_t sector_offset, short_height_t	speed, short_height_t	dest, boolean	crush ) {

push  si
push  di
push  bp
xor   bp, bp
add   al, SECTOR_T.sec_ceilingheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si

mov   ax, SECTORS_SEGMENT
mov   es, ax

;	if (sector->ceilingheight - speed < dest) {


mov   di, word ptr es:[si]
mov   ax, di
sub   ax, dx 

cmp   ax, bx
jl    ceiling_down_past_dest
jmp   ceil_down_not_past_dest


ENDP



PROC    T_MovePlaneCeilingUp_ NEAR
PUBLIC  T_MovePlaneCeilingUp_

push  si
push  di
push  bp
mov   bp, 1 ; do check 
add   al, SECTOR_T.sec_ceilingheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si

;	if (sector->ceilingheight + speed > dest) {

mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   di, word ptr es:[si]
mov   ax, di
add   ax, dx
cmp   ax, bx
jg    ceiling_up_past_dest


jmp   floor_up_not_past_dest


ENDP



PROC    T_MovePlaneFloorDown_ NEAR
PUBLIC  T_MovePlaneFloorDown_

push  si
push  di
push  bp
mov   bp, 1
;NOTE: this is 0 anyway dont add
; add   al, SECTOR_T.sec_floorheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]

;	if (sector->floorheight - speed < dest) {


mov   ax, word ptr es:[si]
mov   di, ax
sub   ax, dx 

cmp   ax, bx
jge   floor_down_not_past_dest
floor_down_past_dest:
ceiling_down_past_dest:
ceiling_up_past_dest:
floor_up_past_dest:
mov   word ptr es:[si], bx

mov   dx, es
mov   bx, cx
mov   ax, si
and   al, 0F0h ; undo the ptr
call  P_ChangeSector_

jnc   exit_moveplanefloordown_return_floorpastdest
; something crushed

mov   dx, SECTORS_SEGMENT
mov   es, dx
mov   word ptr es:[si], di
mov   bx, cx
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  P_ChangeSector_

exit_moveplanefloordown_return_floorpastdest:
exit_moveplanefloorup_return_floorpastdest:
mov   al, FLOOR_PASTDEST
exit_moveplanefloordown:

pop   bp
pop   di
pop   si
ret   

ceil_down_not_past_dest:
floor_down_not_past_dest:
sub   word ptr es:[si], dx

mov   dx, es
mov   bx, cx ; crush
mov   ax, si
and   al, 0F0h ; undo the ptr
call  P_ChangeSector_

jnc   exit_moveplanefloordown_return_floorok

test  bp, bp
jne   do_second_floor_changesector_call   ; skip second check...
test  cl, cl
jne   exit_moveplaneceilingdown_return_floorcrushed


do_second_floor_changesector_call:
mov   dx, SECTORS_SEGMENT
mov   es, dx
mov   word ptr es:[si], di
mov   bx, cx ; crush
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  P_ChangeSector_

exit_moveplanefloordown_return_floorcrushed:
exit_moveplanefloorup_return_floorcrushed:
exit_moveplaneceilingdown_return_floorcrushed:
mov   al, FLOOR_CRUSHED
jmp   exit_moveplanefloordown_return
exit_moveplanefloordown_return_floorok:
exit_moveplanefloorup_return_floorok:
mov   al, 0
exit_moveplanefloordown_return:
exit_moveplanefloorup_return:
pop   bp
pop   di
pop   si
ret   


ENDP

PROC    T_MovePlaneFloorUp_ NEAR
PUBLIC  T_MovePlaneFloorUp_

push  si
push  di
push  bp
xor   bp, bp
add   al, SECTOR_T.sec_floorheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si

;	if (sector->floorheight + speed > dest) {


mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   di, word ptr es:[si]
mov   ax, di
add   ax, dx
cmp   ax, bx
jg    floor_up_past_dest

floor_up_not_past_dest:


add   word ptr es:[si], dx
mov   dx, es
mov   bx, cx
mov   ax, si
and   al, 0F0h ; undo the ptr
call  P_ChangeSector_

jnc   exit_moveplanefloorup_return_floorok
mov   al, 0 ; to force a ret 0 below...
test  bp, bp  ; skip 2nd call if 1
jne   exit_moveplanefloorup_return_floorok
test  cl, cl
jne   exit_moveplanefloorup_return_floorcrushed
jmp   do_second_floor_changesector_call



ENDP



PROC    T_MoveFloor_ NEAR
PUBLIC  T_MoveFloor_

;void __near T_MoveFloor(floormove_t __near* floor, THINKERREF floorRef) {


PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp

xchg  ax, si
push  dx  ; bp - 2
mov   di, word ptr ds:[si + FLOORMOVE_T.floormove_secnum]


test  byte ptr ds:[_leveltime], 7
jne   dont_play_floor_sound
mov   dx, SFX_STNMOV
mov   ax, di
call  S_StartSoundWithSecnum_

dont_play_floor_sound:

mov   ax, di
SHIFT_MACRO shl   ax 4
push  ax  ; bp - 4
cmp   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], 0
je    exit_move_floor

mov   bx, word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight]  ; fe00
mov   dx, word ptr ds:[si + FLOORMOVE_T.floormove_speed]            ; 8
mov   cl, byte ptr ds:[si + FLOORMOVE_T.floormove_crush]            ; 0
; ax already offset
jl    floor_direction_down

floor_direction_up:
call  T_MovePlaneFloorUp_
jmp   done_with_TMovePlanecall

floor_direction_down:
call  T_MovePlaneFloorDown_
done_with_TMovePlanecall:



cmp   al, FLOOR_PASTDEST
jne   exit_move_floor

xor   ax, ax
pop   bx ; bp - 4
mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax ; NULL_THINKERREF


cmp  byte ptr ds:[si + FLOORMOVE_T.floormove_direction], al
mov  al, byte ptr ds:[si + FLOORMOVE_T.floormove_type]
je   dont_change_specials    ; dir was 0
jg   check_for_raising_donut ; dir was 1

;     dir is -1

cmp   al, FLOOR_LOWERANDCHANGE
jmp   do_type_compare


check_for_raising_donut:
cmp   al, FLOOR_DONUTRAISE
do_type_compare:
jne   dont_change_specials

mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   ax, word ptr ds:[si + FLOORMOVE_T.floormove_newspecial] 
;mov   al, byte ptr ds:[si + FLOORMOVE_T.floormove_texture] 
mov   byte ptr es:[bx + SECTOR_T.sec_floorpic], ah
mov   byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], al

dont_change_specials:
pop   ax  ; bp - 2 retrieve floorRef
mov   dx, SFX_PSTOP

call  P_RemoveThinker_
xchg  ax, di

call  S_StartSoundWithSecnum_

   
exit_move_floor:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

ENDP


_do_floor_jump_table:
dw do_floor_switch_case_type_lowerfloor
dw do_floor_switch_case_type_lowerFloorToLowest
dw do_floor_switch_case_type_turboLower
dw do_floor_switch_case_type_raiseFloor
dw do_floor_switch_case_type_raiseFloorToNearest
dw do_floor_switch_case_type_raiseToTexture
dw do_floor_switch_case_type_lowerAndChange
dw do_floor_switch_case_type_raiseFloor24
dw do_floor_switch_case_type_raiseFloor24AndChange
dw do_floor_switch_case_type_raiseFloorCrush
dw do_floor_switch_case_type_raiseFloorTurbo
dw do_floor_switch_case_type_default
dw do_floor_switch_case_type_raiseFloor512 






PROC    EV_DoFloor_ NEAR
PUBLIC  EV_DoFloor_
; return in carry

;int16_t __far EV_DoFloor ( uint8_t linetag,int16_t linefrontsecnum,floor_e	floortype ){

; bp - 2    floortype
; bp - 0202h secnumlist
; bp - 0204h secnumlist iter


push  cx
push  si
push  di
push  bp
mov   bp, sp

mov   word ptr cs:[SELFMODIFY_set_frontsector+1], dx


mov   byte ptr cs:[SELFMODIFY_set_dofloor_return], CLC_OPCODE
mov   byte ptr cs:[SELFMODIFY_set_dofloor_type + 1], bl
lea   dx, [bp - 0202h]
sub   sp, 0200h
push  dx

mov   si, dx


;	P_FindSectorsFromLineTag(linetag, secnumlist, false);


xor   bx, bx
call  P_FindSectorsFromLineTag_
cmp   word ptr ds:[si], 0

jl    no_sectors_in_list_exit

loop_next_secnum_dofloor:

lodsw 
xchg  ax, cx

push  si ; bp - 0202h. pop at end of loop...

mov   ax, TF_MOVEFLOOR_HIGHBITS
cwd   ; zero dx
call  P_CreateThinker_

mov   si, ax  ;  si is floor

sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   di, (SIZE THINKER_T)
div   di

mov   di, SECTORS_SEGMENT
mov   es, di

mov   di, cx
mov   byte ptr cs:[SELFMODIFY_set_dofloor_return], STC_OPCODE
; ax is floor ref
SHIFT_MACRO shl  di 4  
mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax ;floor ref

; di is sectors offset
; si is floor
; cx is secnum


mov  ax, cx  ; ax gets secnum too
; set type 
SELFMODIFY_set_dofloor_type:
db 0BBh, 0FFh, 000h   ; mov bx, 000FFh

mov   byte ptr ds:[si + FLOORMOVE_T.floormove_type], bl
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_crush], bh ; known 0


; ds:si is floor
; ds:di + _sectors_physics is sector_physics
; es:di  is sector
; ax/cx is secnum
; bx is floor type (soon to be shifted for jmp)
; dl is 1 

cmp   bl, FLOOR_RAISEFLOOR512
ja    do_floor_switch_case_type_default
sal   bx, 1
mov   dl, 1 ; "true" used for many calls.
jmp   word ptr cs:[bx + _do_floor_jump_table]

; BEGIN SWITCH BLOCK
; BEGIN SWITCH BLOCK

do_floor_switch_case_type_lowerFloorToLowest:
cwd   ; secnum should be below 0x8000...
do_floor_switch_case_type_lowerfloor:

mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
find_highestlowest:
call  P_FindHighestOrLowestFloorSurrounding_
mov   dl, -1 ; dir negative.

cmp   bx, (FLOOR_TURBOLOWER * 2)
jne   write_floordestheight_secnum_dir
;turbo case
mov   bx, SECTORS_SEGMENT
mov   es, bx
cmp   ax, word ptr es:[di + SECTOR_T.sec_floorheight]
je    write_floordestheight_secnum_dir

add   ax, (8 SHL SHORTFLOORBITS)

write_floordestheight_secnum_dir:
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], dl
mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], ax
mov   word ptr ds:[si + FLOORMOVE_T.floormove_secnum], cx


done_with_dofloor_switch_block:

do_floor_switch_case_type_default:

pop   si ; pop and inc word ptr

cmp   word ptr ds:[si], 0
jnl   loop_next_secnum_dofloor
exit_ev_dofloor_and_return_rtn:
no_sectors_in_list_exit:
SELFMODIFY_set_dofloor_return:
clc
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret  


do_floor_switch_case_type_turboLower:

mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED * 4
jmp   find_highestlowest

do_floor_switch_case_type_raiseFloorCrush:
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_crush], dl ; 1

do_floor_switch_case_type_raiseFloor:
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED

cwd   ; secnum should be below 0x8000...
call  P_FindLowestOrHighestCeilingSurrounding_

mov   dx, word ptr es:[di + SECTOR_T.sec_floorheight]
cmp   ax, dx
jge   dont_adjust_to_ceil_height
mov   ax, dx
dont_adjust_to_ceil_height:

cmp  bx, (FLOOR_RAISEFLOORCRUSH * 2)
jne   finally_set_destheight
sub   ax, (8 SHL SHORTFLOORBITS)

finally_set_destheight:
mov   dl, 1

jmp   write_floordestheight_secnum_dir



do_floor_switch_case_type_raiseFloorTurbo:
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], (FLOORSPEED * 4)

do_raisefloor:
mov   dx, word ptr es:[di + SECTOR_T.sec_floorheight]
call  P_FindNextHighestFloor_
mov   dl, 1
jmp   write_floordestheight_secnum_dir

do_floor_switch_case_type_raiseFloorToNearest:
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED

jmp   do_raisefloor

do_floor_switch_case_type_raiseFloor24AndChange:
SELFMODIFY_set_frontsector:
mov   ax, 01000h
SHIFT_MACRO shl   ax 4
xchg  ax, di
mov   dh, byte ptr es:[di + SECTOR_T.sec_floorpic]
mov   di, word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_special] ; high byte garbage.
xchg  ax, di
mov   byte ptr es:[di + SECTOR_T.sec_floorpic], dh
mov   byte ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_special], al

; fall thru

do_floor_switch_case_type_raiseFloor24:
mov   ax, (24 SHL SHORTFLOORBITS)
do_raisefloor_fixed:
add   ax, word ptr es:[di+ SECTOR_T.sec_floorheight] 
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
;mov   dl, 1 ; dl already 1.
jmp   write_floordestheight_secnum_dir
do_floor_switch_case_type_raiseFloor512:
mov   ax, (512 SHL SHORTFLOORBITS)
jmp   do_raisefloor_fixed



do_floor_switch_case_type_raiseToTexture:

mov   word ptr ds:[si + FLOORMOVE_T.floormove_secnum], ax
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], dl ; 1



push  word ptr es:[di + SECTOR_T.sec_floorheight]
pop   word ptr cs:[SELFMODIFY_add_floorheight+1]

mov   bx, word ptr es:[di + SECTOR_T.sec_linesoffset]
mov   ax, word ptr es:[di + SECTOR_T.sec_linecount]

sal   bx, 1
add   bx, _linebuffer

sal   ax, 1
add   ax, bx

mov   word ptr cs:[SELFMODIFY_set_raisetotexture_linecount + 2], ax ; set end case.

mov   ax, MAXSHORT ; 07FFFh

; loop from bx to dx
loop_next_secnum_raisetotexture:

; if twosided?
mov   cx, word ptr ds:[bx]
xchg  cx, bx  ; cx gets old loop iter
mov   dx, LINEFLAGSLIST_SEGMENT
mov   es, dx
test  byte ptr es:[bx], ML_TWOSIDED
je    continue_secnum_raisetotextureloop


mov   dx, LINES_SEGMENT
mov   es, dx


SHIFT_MACRO shl       bx 2


; cx has old loop iter
; bx has lines ptr.

les   bx, dword ptr es:[bx + LINE_T.l_sidenum + (0 * 2)] ; side 0
mov   di, es ; side 1
mov   dx, SIDES_SEGMENT
mov   es, dx

SHIFT_MACRO sal bx 3
mov   bx, word ptr es:[bx + SIDE_T.s_bottomtexture] ; side0bottomtexture

SHIFT_MACRO sal di 3
mov   di, word ptr es:[di + SIDE_T.s_bottomtexture] ; side1bottomtexture

; bx has side 0 bottom tex
; di has side 1 bottom tex

mov   dx, TEXTUREHEIGHTS_SEGMENT
mov   es, dx

;    if ((textureheights[sidebottomtexture]+1) < minsize) {
;        minsize = textureheights[sidebottomtexture]+1;
;    }

cwd   ; maxshort was 7fff... high bit always off, zero dx.
mov   dl, byte ptr es:[bx]
cmp   dx, ax
jg    dont_set_new_min_a
xchg  ax, dx
dont_set_new_min_a:

cwd   ; maxshort was 7fff... high bit always off, zero dx.
mov   dl, byte ptr es:[di]
cmp   dx, ax
jg    dont_set_new_min_b
xchg  ax, dx
dont_set_new_min_b:




continue_secnum_raisetotextureloop:
mov   bx, cx ; restore bx loop counter
inc   bx
inc   bx
SELFMODIFY_set_raisetotexture_linecount:
cmp   bx, 01000h
jl    loop_next_secnum_raisetotexture

;	floor->floordestheight = sectors[floor->secnum].floorheight + (minsize << SHORTFLOORBITS);

; al was a byte, minsize - 1

inc   ax
SHIFT_MACRO shl ax SHORTFLOORBITS
SELFMODIFY_add_floorheight:
add   ax, 01000h ;   word ptr es:[di+ SECTOR_T.sec_floorheight] 
mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], ax
jmp   done_with_dofloor_switch_block


do_floor_switch_case_type_lowerAndChange:

mov   word ptr ds:[si + FLOORMOVE_T.floormove_secnum], ax
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], -1 ; dir negative


mov   word ptr cs:[selfmodify_check_secnum+2], ax
cwd   ; secnum should be below 0x8000... dx to 0
call  P_FindHighestOrLowestFloorSurrounding_

mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], ax  ; STORE FLOORDESTHEIGHT FOR LATER
mov   dl, byte ptr es:[di + SECTOR_T.sec_floorpic]
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_texture], dl  


; ax is floordestheight for loop

; cx and di and bx are free
; bx will be loop counter.

mov   bx, word ptr es:[di + SECTOR_T.sec_linesoffset]
mov   cx, word ptr es:[di + SECTOR_T.sec_linecount]

sal   bx, 1
add   bx, _linebuffer

sal   cx, 1
add   cx, bx

mov   word ptr cs:[SELFMODIFY_set_lowerandchange_linecount + 2], cx ; set end case.

loop_next_secnum_lowerandchange:


; if twosided?
mov   cx, word ptr ds:[bx]
xchg  cx, bx
mov   es, ds:[_LINEFLAGSLIST_SEGMENT_PTR]
test  byte ptr es:[bx], ML_TWOSIDED
je    continue_secnum_lowerandchangeloop

; found a sector to sue
; get the line side secnum that isnt the same as the original sector 


mov   es, ds:[_LINES_PHYSICS_SEGMENT_PTR]


SHIFT_MACRO shl       bx 4


mov   di, word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum]

selfmodify_check_secnum:
cmp   di, 01000h 
jne   set_sector_values_and_break_loop
mov   di, word ptr es:[bx + LINE_PHYSICS_T.lp_backsecnum]
set_sector_values_and_break_loop:


SHIFT_MACRO shl di 4
mov   es, ds:[_SECTORS_SEGMENT_PTR]
; !! check the floor heights. 
;			if (sec->floorheight == floor->floordestheight)
mov   ax, word ptr es:[di + SECTOR_T.sec_floorheight]
cmp   ax, word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight]
jne   continue_secnum_lowerandchangeloop

mov   ah, byte ptr es:[di + SECTOR_T.sec_floorpic]
mov   al, byte ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_special]
mov   word ptr ds:[si + FLOORMOVE_T.floormove_newspecial], ax
;mov   byte ptr ds:[si + FLOORMOVE_T.floormove_texture], al


jmp   done_with_dofloor_switch_block




continue_secnum_lowerandchangeloop:
mov   bx, cx ; restore bx loop countr

inc   bx
inc   bx
SELFMODIFY_set_lowerandchange_linecount:
cmp   bx, 01000h
jb    loop_next_secnum_lowerandchange



jmp   done_with_dofloor_switch_block



ENDP


; i think space could be saved in this func with less selfmodify and more stack frames
; return in carry

PROC    EV_BuildStairs_ NEAR
PUBLIC  EV_BuildStairs_

;int16_t __near EV_BuildStairs ( uint8_t	linetag,stair_e	type ) {


PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 0210h

; bp - 2  current secnum in innermost loop
; bp - 4  stairheight in innermost loop

cmp   dl, STAIRS_TURBO16
mov   dx, 0C089h ; two byte nop  ; nop if turbo16
je    do_type_selfmodify
mov   dx, ((SELFMODIFY_check_stairtype_TARGET - SELFMODIFY_check_stairtype_AFTER) SHL 8) + 0EBh
do_type_selfmodify:

mov   word ptr cs:[SELFMODIFY_check_stairtype], dx

mov   byte ptr cs:[SELFMODIFY_set_buildstairs_return], CLC_OPCODE


lea   dx, [bp - 0200h]
cbw  
xor   bx, bx
mov   si, dx
call  P_FindSectorsFromLineTag_
cmp   word ptr ds:[si], 0
jge   loop_next_secnum_buildstairs
jmp   exit_ev_buildstairs

loop_next_secnum_buildstairs:

lodsw
xchg  ax, cx
push  si

mov   ax, TF_MOVEFLOOR_HIGHBITS
cwd   

call  P_CreateThinker_


mov   si, ax  ; si is floor..
sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   di, (SIZE THINKER_T)
div   di

mov   es, ds:[_SECTORS_SEGMENT_PTR]


mov   word ptr [bp - 2], cx

mov   di, cx  
SHIFT_MACRO shl   di 4    ; di is sector offset

mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax

;mov   bx, word ptr es:[di]

; es:di is sector
; ds:di + _sectors_physics is sector_physics
; ds:si is floor
; cx is secnum
; ax is floorref
mov   ax, 1 ; zero ah
cwd   ; zero dx
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], al ; 1
mov   byte ptr cs:[SELFMODIFY_set_buildstairs_return], STC_OPCODE
mov   word ptr ds:[si + FLOORMOVE_T.floormove_secnum], cx


mov   dl, FLOORSPEED / 4
mov   al, (8 SHL SHORTFLOORBITS)

SELFMODIFY_check_stairtype:
jmp   done_setting_values      ; either a jmp or a nop
SELFMODIFY_check_stairtype_AFTER:
; turbo16 values
mov   dl, FLOORSPEED * 4
shl   ax, 1

SELFMODIFY_check_stairtype_TARGET:
done_setting_values:

; ax is stairsize
mov   word ptr [bp - 4], ax
add   ax, word ptr es:[di + SECTOR_T.sec_floorheight]

mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], dx

mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], ax
xchg  ax, dx ; dx gets height.
mov   word ptr cs:[SELFMODIFY_set_buildstairs_speed+3], ax  ; write speed




;; BEGIN 2ND LOOP
;; BEGIN 2ND LOOP
;; BEGIN 2ND LOOP

loop_next_buildstair_middleloop:

; loop constants
; secnum self modified ahead
; si free...
;  di is sector
;  dx is height
;  speed, stairstep selfmodify set ahead

; we are in the middle (2nd) loop of three. secnum is set either by precondition (pre-2nd loop) or last iteration + break of 3rd loop in DI.




mov   word ptr cs:[SELFMODIFY_set_buildstairs_middleloop_ok], ((SELFMODIFY_set_buildstairs_middleloop_TARGET - SELFMODIFY_set_buildstairs_middleloop_AFTER) SHL 8) + 0EBh



mov   es, ds:[_SECTORS_SEGMENT_PTR]


;	sectorfloorpic = sector->floorpic;
mov   cl, byte ptr es:[di + SECTOR_T.sec_floorpic]

; find next sector to raise. iterate over linecount
mov   bx, word ptr es:[di + SECTOR_T.sec_linesoffset]
mov   ax, word ptr es:[di + SECTOR_T.sec_linecount]

sal   bx, 1
add   bx, _linebuffer

sal   ax, 1
add   ax, bx

mov   word ptr [bp - 6], ax ; set end case.



;; BEGIN 3RD LOOP
;; BEGIN 3RD LOOP
;; BEGIN 3RD LOOP
loop_next_inner_secnum_buildstairs:

; 3rd loop values:
; es:di is sector
; si is unused until end
; cl is floorpic
; ds:di + _sectors_physics is sector_physics
; bx is current line ptr. gets pushed  and restored during iter step.
; dx continues to be height 
; some selfmodified constants (floorpic)
push  bx
mov   bx, word ptr ds:[bx]

mov   es, ds:[_LINEFLAGSLIST_SEGMENT_PTR]
test  byte ptr es:[bx], ML_TWOSIDED
je    continue_inner_secnum_buildstairs_loop
mov   es, ds:[_LINES_PHYSICS_SEGMENT_PTR]

SHIFT_MACRO  sal bx 4

mov   ax, word ptr [bp - 2]


cmp   ax, es:[bx + LINE_PHYSICS_T.lp_frontsecnum]
jne   continue_inner_secnum_buildstairs_loop

mov   ax, es:[bx + LINE_PHYSICS_T.lp_backsecnum]
; dont need this bx anymore

mov   es, ds:[_SECTORS_SEGMENT_PTR]


mov   bx, ax ; ax hold onto unshifted secnum for a bit...
SHIFT_MACRO shl bx 4  ;bx is new sec


;    if (sectors[tsecOffset].floorpic != sectorfloorpic)
;        continue;



cmp   cl, byte ptr es:[bx + SECTOR_T.sec_floorpic]
jne   continue_inner_secnum_buildstairs_loop

add   dx, word ptr [bp - 4] ; stair size

;    if (sectors_physics[tsecOffset].specialdataRef)
;        continue;

cmp   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], 0
jnz   continue_inner_secnum_buildstairs_loop

; in the clear. record next secnum.

mov   word ptr [bp - 2], ax
mov   word ptr cs:[SELFMODIFY_set_buildstairs_middleloop_ok], 0C089h ; two byte nop
mov   di, bx  ; update sector variable.

push  ax       ; secnum on stack...

mov   ax, TF_MOVEFLOOR_HIGHBITS
call  P_CreateThinker_

;    floor->floordestheight = height;
;    floor->direction = 1;
;    floor->secnum = tsecOffset;
;    floor->speed = speed;
;    floorRef = GETTHINKERREF(floor);		
;    sectors_physics[tsecOffset].specialdataRef = floorRef;

; si free. bx holds secnum. dx still has height 
mov   si, ax  ; si gets floor

SELFMODIFY_set_buildstairs_speed:
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], 01000h
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], 1
pop   word ptr ds:[si + FLOORMOVE_T.floormove_secnum]   ; earlier pushed secnum here

mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], dx

; done with si...

push  dx ; store height...
xor   dx, dx
sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   bx, (SIZE THINKER_T)
div   bx  ; wrecks dx of course...
pop   dx ; recover height

mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax


continue_inner_secnum_buildstairs_loop:
pop   bx  ; restore ptr

inc   bx
inc   bx
cmp   bx, word ptr [bp - 6]
jl    loop_next_inner_secnum_buildstairs

;; END 3RD LOOP
;; END 3RD LOOP
;; END 3RD LOOP

SELFMODIFY_set_buildstairs_middleloop_ok:
jmp   end_middle_loop  ; or NOP if ok = 1
SELFMODIFY_set_buildstairs_middleloop_AFTER:

jmp   loop_next_buildstair_middleloop
;; END 2ND LOOP
;; END 2ND LOOP
;; END 2ND LOOP
SELFMODIFY_set_buildstairs_middleloop_TARGET:
end_middle_loop:


continue_buildstairs_middle_loop:
pop   si

cmp   word ptr ds:[si], 0
jl    exit_ev_buildstairs
jmp   loop_next_secnum_buildstairs
exit_ev_buildstairs:

SELFMODIFY_set_buildstairs_return:
clc

LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

ENDP



PROC    P_FLOOR_ENDMARKER_ NEAR
PUBLIC  P_FLOOR_ENDMARKER_
ENDP

END