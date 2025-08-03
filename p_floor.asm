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
EXTRN _P_ChangeSector:DWORD
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN twoSided_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR

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

ceil_down_not_past_dest:
sub   word ptr es:[si], dx

mov   dx, es
mov   bx, cx ; crush
mov   ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplaneceilingdown
test  cl, cl
jne   exit_moveplaneceilingdown_return_floorcrushed
mov   dx, SECTORS_SEGMENT
mov   es, dx
mov   bx, cx ; crush
mov   word ptr es:[si], di
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
exit_moveplaneceilingdown_return_floorcrushed:
mov   al, FLOOR_CRUSHED
exit_moveplaneceilingdown:
pop   di
pop   si
ret   

ENDP



PROC    T_MovePlaneCeilingUp_ NEAR
PUBLIC  T_MovePlaneCeilingUp_

push  si
push  di

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


ceil_up_not_past_dest:


add   word ptr es:[si], dx
mov   dx, es
mov   bx, cx
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
xor   al, al ; floorok

pop   di
pop   si
ret   

ENDP



PROC    T_MovePlaneFloorDown_ NEAR
PUBLIC  T_MovePlaneFloorDown_

push  si
push  di

add   al, SECTOR_T.sec_floorheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si
mov   ax, SECTORS_SEGMENT
mov   es, ax

;	if (sector->floorheight - speed < dest) {


mov   di, word ptr es:[si]
mov   ax, di
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
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloordown_return_floorpastdest
; something crushed

mov   dx, SECTORS_SEGMENT
mov   es, dx
mov   word ptr es:[si], di
mov   bx, cx
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
exit_moveplanefloordown_return_floorpastdest:
exit_moveplanefloorup_return_floorpastdest:
mov   al, FLOOR_PASTDEST
exit_moveplanefloordown:

pop   di
pop   si
ret   

floor_down_not_past_dest:
sub   word ptr es:[si], dx

mov   dx, es
mov   bx, cx ; crush
mov   ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloordown_return_floorok
do_second_floor_changesector_call:
mov   dx, SECTORS_SEGMENT
mov   es, dx
mov   word ptr es:[si], di
mov   bx, cx ; crush
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
exit_moveplanefloordown_return_floorcrushed:
exit_moveplanefloorup_return_floorcrushed:
mov   al, FLOOR_CRUSHED
exit_moveplanefloordown_return_floorok:
exit_moveplanefloorup_return_floorok:
pop   di
pop   si
ret   


ENDP

PROC    T_MovePlaneFloorUp_ NEAR
PUBLIC  T_MovePlaneFloorUp_


push  si
push  di

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
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloorup_return_floorok
test  cl, cl
jne   exit_moveplanefloorup_return_floorcrushed
jmp   do_second_floor_changesector_call



ENDP



PROC    T_MoveFloor_ NEAR
PUBLIC  T_MoveFloor_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 8
mov   si, ax
mov   word ptr [bp - 4], dx
mov   di, word ptr ds:[si + 2]
mov   ax, di
shl   ax, 4
mov   word ptr [bp - 2], ax
mov   al, byte ptr ds:[si + 4]
cmp   al, 1
jne   label_7
jmp   label_8
label_7:
cmp   al, -1
je    label_9
jmp   label_10
label_9:
mov   al, byte ptr ds:[si + 1]
mov   bx, word ptr ds:[si + 7]
cbw  
mov   dx, word ptr ds:[si + 9]
mov   cx, ax
mov   ax, word ptr [bp - 2]
call  T_MovePlaneFloorDown_
label_12:
mov   cl, al
label_13:
mov   bx, _leveltime
test  byte ptr ds:[bx], 7
jne   label_11
mov   dx, SFX_STNMOV
mov   ax, di

call  S_StartSoundWithParams_
   
label_11:
cmp   cl, 2
jne   exit_move_floor
mov   dh, byte ptr ds:[si + 5]
mov   al, byte ptr ds:[si + 4]
mov   cl, byte ptr ds:[si + 6]
mov   dl, byte ptr ds:[si]
mov   si, di
shl   si, 4
mov   word ptr [bp - 8], si
lea   bx, [si + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef]
mov   word ptr [bp - 6], 0
mov   word ptr ds:[bx], 0
mov   bx, SECTORS_SEGMENT
cbw  
mov   es, bx
mov   bx, word ptr [bp - 8]
add   si, 4
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_special
cmp   ax, 1
jne   label_16
cmp   dl, FLOOR_DONUTRAISE
label_15:
jne   label_14
mov   byte ptr ds:[bx], dh
mov   byte ptr es:[si], cl
label_14:
mov   ax, word ptr [bp - 4]
mov   dx, SFX_PSTOP

call  P_RemoveThinker_
mov   ax, di

call  S_StartSoundWithParams_
   
exit_move_floor:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_8:
mov   al, byte ptr ds:[si + 1]
mov   bx, word ptr ds:[si + 7]
cbw  
mov   dx, word ptr ds:[si + 9]
mov   cx, ax
mov   ax, word ptr [bp - 2]
call  T_MovePlaneFloorUp_
jmp   label_12
label_10:
xor   cl, cl
jmp   label_13
label_16:
cmp   ax, -1
jne   label_14
cmp   dl, 6
jmp   label_15
ENDP


_do_floor_jump_table:
dw do_floor_switch_case_type_1, do_floor_switch_case_type_2, do_floor_switch_case_type_3, do_floor_switch_case_type_4
dw do_floor_switch_case_type_5, do_floor_switch_case_type_6, do_floor_switch_case_type_7, do_floor_switch_case_type_8
dw do_floor_switch_case_type_9, do_floor_switch_case_type_10, do_floor_switch_case_type_11, do_floor_switch_case_type_12, do_floor_switch_case_type_13 






PROC    EV_DoFloor_ NEAR
PUBLIC  EV_DoFloor_


push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0220h
mov   cx, dx
mov   byte ptr [bp - 2], bl
mov   word ptr [bp - 01Ch], 0
lea   dx, [bp - 0220h]
mov   word ptr [bp - 0Ah], 0
cbw  
xor   bx, bx
shl   cx, 4
call  P_FindSectorsFromLineTag_
mov   word ptr [bp - 018h], cx
cmp   word ptr [bp - 0220h], 0
jl    label_21
label_22:
mov   si, word ptr [bp - 0Ah]
mov   cx, word ptr [bp + si - 0220h]
mov   ax, cx
mov   word ptr [bp - 4], SECTORS_SEGMENT
shl   ax, 4
mov   es, word ptr [bp - 4]
mov   word ptr [bp - 6], ax
add   ax, _sectors_physics
mov   bx, word ptr [bp - 6]
mov   word ptr [bp - 0Eh], ax
mov   ax, word ptr es:[bx + SECTOR_PHYSICS_T.secp_linesoffset]
mov   word ptr [bp - 01Ah], ax
mov   ax, word ptr es:[bx + 2]
mov   word ptr [bp - 016h], ax
mov   ax, word ptr es:[bx]
mov   di, SIZEOF_THINKER_T
mov   word ptr [bp - 0Ch], ax
mov   ax, TF_MOVEFLOOR_HIGHBITS
xor   dx, dx

call  P_CreateThinker_

mov   bx, ax
mov   si, ax
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   di
mov   di, word ptr [bp - 0Eh]
mov   word ptr [bp - 01Ch], 1
mov   word ptr ds:[di + 8], ax
mov   al, byte ptr [bp - 2]
mov   byte ptr ds:[bx + 1], 0
add   word ptr [bp - 0Ah], 2
mov   byte ptr ds:[bx], al
cmp   al, FLOOR_RAISEFLOOR512
ja    label_18
xor   ah, ah
mov   di, ax
add   di, ax
jmp   word ptr cs:[di + _do_floor_jump_table]
label_21:
jmp   label_17
do_floor_switch_case_type_1:
mov   byte ptr ds:[bx + 4], -1
mov   dx, 1
mov   word ptr ds:[bx + 9], 8
mov   ax, cx
label_19:
mov   word ptr ds:[bx + 2], cx
call  P_FindHighestOrLowestFloorSurrounding_
label_28:
mov   word ptr ds:[bx + 7], ax
label_18:
do_floor_switch_case_type_12:
mov   si, word ptr [bp - 0Ah]
cmp   word ptr [bp + si - 0220h], 0
jl    label_17
jmp   label_22
label_17:
mov   ax, word ptr [bp - 01Ch]
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf  
do_floor_switch_case_type_2:
mov   byte ptr ds:[bx + 4], -1
mov   ax, cx
mov   word ptr ds:[bx + 9], 8
xor   dx, dx
jmp   label_19
do_floor_switch_case_type_3:
mov   byte ptr ds:[bx + 4], -1
mov   dx, 1
mov   word ptr ds:[bx + 9], (FLOORSPEED*4)
mov   ax, cx
mov   word ptr ds:[bx + 2], cx
call  P_FindHighestOrLowestFloorSurrounding_
mov   word ptr ds:[bx + 7], ax
cmp   ax, word ptr [bp - 0Ch]
je    label_18
add   word ptr ds:[bx + 7], (8 SHL SHORTFLOORBITS)
jmp   label_18
do_floor_switch_case_type_10:
mov   byte ptr ds:[bx + 1], 1
do_floor_switch_case_type_4:
mov   byte ptr ds:[si + 4], 1
mov   ax, cx
mov   word ptr ds:[si + 9], 8
xor   dx, dx
mov   word ptr ds:[si + 2], cx
call  P_FindLowestOrHighestCeilingSurrounding_
mov   word ptr ds:[si + 7], ax
cmp   ax, word ptr [bp - 016h]
jle   label_20
mov   ax, word ptr [bp - 016h]
mov   word ptr ds:[si + 7], ax
label_20:
add   si, 7
cmp   byte ptr [bp - 2], 9
jne   label_27
mov   bx, 1
shl   bx, 6
sub   word ptr ds:[si], bx
jmp   label_18
label_27:
xor   bx, bx
shl   bx, 6
sub   word ptr ds:[si], bx
jmp   label_18
do_floor_switch_case_type_11:
mov   byte ptr ds:[bx + 4], 1
mov   dx, word ptr [bp - 0Ch]
mov   word ptr ds:[bx + 9], (FLOORSPEED*4)
mov   ax, cx
mov   word ptr ds:[bx + 2], cx
call  P_FindNextHighestFloor_
jmp   label_28
do_floor_switch_case_type_5:
mov   byte ptr ds:[bx + 4], 1
mov   dx, word ptr [bp - 0Ch]
mov   word ptr ds:[bx + 9], 8
mov   ax, cx
mov   word ptr ds:[bx + 2], cx
call  P_FindNextHighestFloor_
jmp   label_28
do_floor_switch_case_type_8:
mov   byte ptr ds:[bx + 4], 1
mov   word ptr ds:[bx + 2], cx
mov   ax, SECTORS_SEGMENT
mov   si, word ptr ds:[bx + 2]
mov   word ptr ds:[bx + 9], 8
shl   si, 4
mov   es, ax
mov   cx, word ptr es:[si]
add   cx,  (24 SHL SHORTFLOORBITS)
mov   word ptr ds:[bx + 7], cx
jmp   label_18
do_floor_switch_case_type_13:
mov   byte ptr ds:[bx + 4], 1
mov   word ptr ds:[bx + 2], cx
mov   ax, SECTORS_SEGMENT
mov   si, word ptr ds:[bx + 2]
mov   word ptr ds:[bx + 9], 8
shl   si, 4
mov   es, ax
mov   cx, word ptr es:[si]
add   cx, (512 SHL SHORTFLOORBITS)
mov   word ptr ds:[bx + 7], cx
jmp   label_18
do_floor_switch_case_type_9:
mov   byte ptr ds:[bx + 4], 1
mov   word ptr ds:[bx + 2], cx
mov   ax, SECTORS_SEGMENT
mov   si, word ptr ds:[bx + 2]
mov   word ptr ds:[bx + 9], 8
shl   si, 4
mov   es, ax
mov   cx, word ptr es:[si]
add   cx,  (24 SHL SHORTFLOORBITS)
mov   ax, word ptr [bp - 018h]
mov   word ptr ds:[bx + 7], cx
mov   bx, ax
mov   word ptr [bp - 020h], ax
mov   al, byte ptr es:[bx + 4]
add   bx, 4
les   bx, dword ptr [bp - 6]
mov   word ptr [bp - 01Eh], 0
mov   byte ptr es:[bx + 4], al
mov   bx, word ptr [bp - 020h]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_special
mov   al, byte ptr ds:[bx]
mov   bx, word ptr [bp - 0Eh]
mov   byte ptr ds:[bx + SECTOR_PHYSICS_T.secp_special], al
jmp   label_18
do_floor_switch_case_type_6:
mov   byte ptr ds:[bx + 4], 1
mov   word ptr [bp - 8], MAXSHORT
mov   word ptr ds:[bx + 9], 8
mov   di, word ptr [bp - 6]
mov   word ptr ds:[bx + 2], cx
mov   es, word ptr [bp - 4]
xor   bx, bx
cmp   word ptr es:[di + SECTOR_T.sec_linecount], 0
jg    label_23
jmp   label_24
label_23:
mov   ax, word ptr [bp - 01Ah]
add   ax, ax
mov   word ptr [bp - 012h], ax
label_29:
mov   dx, bx
mov   ax, cx
call  twoSided_
test  ax, ax
je    label_25
mov   ax, word ptr [bp - 012h]
mov   di, ax
add   di, _linebuffer
mov   di, word ptr ds:[di]
mov   ax, LINES_SEGMENT
shl   di, 2
mov   es, ax
mov   ax, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
mov   di, SIDES_SEGMENT
shl   ax, 3
mov   es, di
mov   di, ax
add   di, 2
mov   ax, TEXTUREHEIGHTS_SEGMENT
mov   di, word ptr es:[di]
mov   es, ax
mov   al, byte ptr es:[di]
xor   ah, ah
inc   ax
cmp   ax, word ptr [bp - 8]
jge   label_26
mov   word ptr [bp - 8], ax
label_26:
mov   di, dx
mov   ax, SIDES_SEGMENT
shl   di, 3
mov   es, ax
add   di, 2
mov   ax, TEXTUREHEIGHTS_SEGMENT
mov   di, word ptr es:[di]
mov   es, ax
mov   al, byte ptr es:[di]
xor   ah, ah
inc   ax
cmp   ax, word ptr [bp - 8]
jge   label_25
mov   word ptr [bp - 8], ax
label_25:
les   di, dword ptr [bp - 6]
inc   bx
add   word ptr [bp - 012h], 2
cmp   bx, word ptr es:[di + SECTOR_T.sec_linecount]
jl    label_29
label_24:
mov   ax, SECTORS_SEGMENT
mov   bx, word ptr ds:[si + 2]
mov   dx, word ptr [bp - 8]
shl   bx, 4
mov   es, ax
shl   dx, 3
mov   ax, word ptr es:[bx]
add   ax, dx
mov   word ptr ds:[si + 7], ax
jmp   label_18
do_floor_switch_case_type_7:
mov   di, word ptr [bp - 6]
mov   byte ptr ds:[bx + 4], -1
mov   ax, cx
mov   word ptr ds:[bx + 9], 8
xor   dx, dx
mov   word ptr ds:[bx + 2], cx
call  P_FindHighestOrLowestFloorSurrounding_
mov   word ptr ds:[bx + 7], ax
mov   es, word ptr [bp - 4]
mov   al, byte ptr es:[di + 4]
mov   byte ptr ds:[bx + 6], al
xor   bx, bx
cmp   word ptr es:[di + SECTOR_T.sec_linecount], 0
jg    label_50
jmp   label_18
label_50:
mov   ax, word ptr [bp - 01Ah]
add   ax, ax
mov   word ptr [bp - 010h], ax
label_34:
mov   dx, bx
mov   ax, cx
call  twoSided_
test  ax, ax
je    label_31
mov   ax, word ptr [bp - 010h]
mov   di, ax
mov   word ptr [bp - 014h], LINES_SEGMENT
add   di, _linebuffer
mov   ax, word ptr ds:[di]
mov   di, word ptr ds:[di]
mov   dx, LINES_PHYSICS_SEGMENT
shl   di, 4
mov   es, dx
shl   ax, 2
cmp   cx, word ptr es:[di + LINE_PHYSICS_T.lp_frontsecnum]
jne   label_32
mov   es, word ptr [bp - 014h]
mov   di, ax
mov   cx, word ptr es:[di + 2]
les   di, dword ptr [bp - 6]
mov   ax, word ptr es:[di]
cmp   ax, word ptr ds:[si + 7]
jne   label_31
mov   bx, di
mov   al, byte ptr es:[bx + 4]
mov   bx, word ptr [bp - 0Eh]
mov   byte ptr ds:[si + 6], al
mov   al, byte ptr ds:[bx + SECTOR_PHYSICS_T.secp_special]
mov   byte ptr ds:[si + 5], al
jmp   label_18
label_32:
mov   es, word ptr [bp - 014h]
mov   di, ax
mov   cx, word ptr es:[di]
les   di, dword ptr [bp - 6]
mov   ax, word ptr es:[di]
cmp   ax, word ptr ds:[si + 7]
jne   label_31
mov   bx, di
mov   al, byte ptr es:[bx + 4]
mov   bx, word ptr [bp - 0Eh]
mov   byte ptr ds:[si + 6], al
mov   al, byte ptr ds:[bx + SECTOR_PHYSICS_T.secp_special]
mov   byte ptr ds:[si + 5], al
jmp   label_18
label_31:
les   di, dword ptr [bp - 6]
inc   bx
add   word ptr [bp - 010h], 2
cmp   bx, word ptr es:[di + SECTOR_PHYSICS_T.secp_linecount]
jge   label_33
jmp   label_34
label_33:
jmp   label_18


ENDP



PROC    EV_BuildStairs_ NEAR
PUBLIC  EV_BuildStairs_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0218h
mov   byte ptr [bp - 2], dl
mov   word ptr [bp - 012h], 0
lea   dx, [bp - 0218h]
cbw  
xor   bx, bx
mov   word ptr [bp - 010h], 0
call  P_FindSectorsFromLineTag_
cmp   word ptr [bp - 0218h], 0
jge   label_30
jmp   label_51
label_30:
mov   si, word ptr [bp - 010h]
mov   word ptr [bp - 6], SIZEOF_THINKER_T
mov   ax, word ptr [bp + si - 0218h]
xor   dx, dx
mov   word ptr [bp - 8], ax
mov   cx, ax
mov   ax, SECTORS_SEGMENT
shl   cx, 4
mov   es, ax
mov   bx, cx
mov   ax, TF_MOVEFLOOR_HIGHBITS
mov   di, word ptr es:[bx]

call  P_CreateThinker_
mov   bx, ax
mov   si, ax
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   word ptr [bp - 6]
mov   word ptr [bp - 012h], 1
mov   byte ptr ds:[bx + 4], 1
mov   dx, word ptr [bp - 8]
add   word ptr [bp - 010h], 2
mov   word ptr ds:[bx + 2], dx
mov   bx, cx
mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov   al, byte ptr [bp - 2]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
cmp   al, 1
jne   label_42
mov   word ptr [bp - 0Eh], (FLOORSPEED*4)
mov   word ptr [bp - 0Ch], (16 SHL SHORTFLOORBITS)
label_39:
mov   cx, word ptr [bp - 0Ch]
mov   ax, word ptr [bp - 0Eh]
add   cx, di
mov   word ptr ds:[si + 9], ax
mov   word ptr ds:[si + 7], cx
label_52:
mov   bx, word ptr [bp - 8]
mov   ax, SECTORS_SEGMENT
shl   bx, 4
mov   es, ax
mov   al, byte ptr es:[bx + 4]
mov   byte ptr [bp - 4], al
mov   ax, word ptr es:[bx + SECTOR_T.sec_linecount]
xor   di, di
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[bx + SECTOR_T.sec_linesoffset]
xor   dl, dl
mov   word ptr [bp - 014h], ax
label_38:
mov   al, dl
xor   ah, ah
cmp   ax, word ptr [bp - 0Ah]
jge   label_41
add   ax, word ptr [bp - 014h]
add   ax, ax
mov   bx, ax
add   bx, _linebuffer
mov   ax, word ptr ds:[bx]
mov   bx, LINEFLAGSLIST_SEGMENT
mov   es, bx
mov   bx, ax
test  byte ptr es:[bx], 4
jne   label_36
label_35:
inc   dl
jmp   label_38
label_42:
test  al, al
jne   label_39
mov   word ptr [bp - 0Eh], (FLOORSPEED / 4)
mov   word ptr [bp - 0Ch], (8 SHL SHORTFLOORBITS)
jmp   label_39
label_41:
jmp   label_40
label_36:
mov   bx, LINES_PHYSICS_SEGMENT
shl   ax, 4
mov   es, bx
mov   bx, ax

mov   bx, word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum]
cmp   bx, word ptr [bp - 8]
jne   label_35
mov   bx, ax
mov   word ptr [bp - 016h], 0
mov   si, word ptr es:[bx + LINE_PHYSICS_T.lp_backsecnum]
add   bx, LINE_PHYSICS_T.lp_backsecnum
mov   ax, si
mov   bx, SECTORS_SEGMENT
shl   ax, 4
mov   es, bx
mov   bx, ax
mov   word ptr [bp - 018h], ax
mov   al, byte ptr es:[bx + 4]
add   bx, 4
cmp   al, byte ptr [bp - 4]
jne   label_35
mov   bx, word ptr [bp - 018h]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
add   cx, word ptr [bp - 0Ch]
cmp   word ptr ds:[bx], 0
jne   label_35
mov   ax, TF_MOVEFLOOR_HIGHBITS
mov   word ptr [bp - 6], SIZEOF_THINKER_T

call  P_CreateThinker_
xor   dx, dx
mov   di, ax
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   word ptr [bp - 6]
mov   byte ptr ds:[di + 4], 1
mov   word ptr ds:[di + 7], cx
mov   word ptr ds:[di + 2], si
mov   word ptr ds:[di + 7], cx
mov   dx, word ptr [bp - 0Eh]
mov   word ptr ds:[di + 9], dx
mov   word ptr [bp - 8], si
mov   word ptr ds:[bx], ax
jmp   label_52
label_40:
test  di, di
je    label_54
jmp   label_52
label_54:
mov   si, word ptr [bp - 010h]
cmp   word ptr [bp + si - 0218h], 0
jl    label_51
jmp   label_30
label_51:
mov   ax, word ptr [bp - 012h]
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   

ENDP



PROC    P_FLOOR_ENDMARKER_ NEAR
PUBLIC  P_FLOOR_ENDMARKER_
ENDP

END