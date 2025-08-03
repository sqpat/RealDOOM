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
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
mov   ax, bx
mov   word ptr [bp - 2], SECTORS_SEGMENT
mov   es, word ptr [bp - 2]
mov   di, word ptr es:[si + 2]
sub   di, dx
cmp   di, bx
jge   label_1
mov   dx, SECTORS_SEGMENT
mov   al, cl
mov   di, word ptr es:[si + 2]
cbw  
mov   word ptr es:[si + 2], bx
mov   cx, ax
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplaneceilingdown_return_floorpastdest
mov   es, word ptr [bp - 2]
mov   dx, SECTORS_SEGMENT
mov   bx, cx
mov   ax, si
mov   word ptr es:[si + 2], di
call  dword ptr ds:[_P_ChangeSector]
exit_moveplaneceilingdown_return_floorpastdest:
mov   al, FLOOR_PASTDEST
exit_moveplaneceilingdown:
LEAVE_MACRO 
pop   di
pop   si
ret   
label_1:
mov   ax, word ptr es:[si + 2]
mov   word ptr [bp - 4], ax
sub   ax, dx
mov   word ptr es:[si + 2], ax
mov   al, cl
cbw  
mov   dx, SECTORS_SEGMENT
mov   di, ax
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplaneceilingdown
cmp   cl, 1
jne   label_2
mov   al, cl
LEAVE_MACRO 
pop   di
pop   si
ret   
label_2:
les   ax, dword ptr [bp - 4]
mov   dx, SECTORS_SEGMENT
mov   bx, di
mov   word ptr es:[si + 2], ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
mov   al, FLOOR_CRUSHED
LEAVE_MACRO 
pop   di
pop   si
ret   

ENDP



PROC    T_MovePlaneCeilingUp_ NEAR
PUBLIC  T_MovePlaneCeilingUp_



push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
mov   al, cl
mov   word ptr [bp - 2], SECTORS_SEGMENT
mov   es, word ptr [bp - 2]
mov   cx, word ptr es:[si + 2]
add   cx, dx
cmp   cx, bx
jle   label_3
mov   dx, SECTORS_SEGMENT
cbw  
mov   di, word ptr es:[si + 2]
mov   cx, ax
mov   word ptr es:[si + 2], bx
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplaneceilingup_return_floorpastdest
mov   es, word ptr [bp - 2]
mov   dx, SECTORS_SEGMENT
mov   bx, cx
mov   ax, si
mov   word ptr es:[si + 2], di
call  dword ptr ds:[_P_ChangeSector]
exit_moveplaneceilingup_return_floorpastdest:
mov   al, FLOOR_PASTDEST
LEAVE_MACRO 
pop   di
pop   si
ret   
label_3:
mov   bx, word ptr es:[si + 2]
cbw  
add   bx, dx
mov   dx, SECTORS_SEGMENT
mov   word ptr es:[si + 2], bx
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
xor   al, al ; floorok
LEAVE_MACRO 
pop   di
pop   si
ret   

ENDP



PROC    T_MovePlaneFloorDown_ NEAR
PUBLIC  T_MovePlaneFloorDown_



push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
mov   al, cl
mov   word ptr [bp - 2], SECTORS_SEGMENT
mov   es, word ptr [bp - 2]
mov   cx, word ptr es:[si]
sub   cx, dx
cmp   cx, bx
jge   label_4
mov   dx, SECTORS_SEGMENT
cbw  
mov   di, word ptr es:[si]
mov   cx, ax
mov   word ptr es:[si], bx
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloordown_return_floorpastdest
mov   es, word ptr [bp - 2]
mov   dx, SECTORS_SEGMENT
mov   bx, cx
mov   ax, si
mov   word ptr es:[si], di
call  dword ptr ds:[_P_ChangeSector]
exit_moveplanefloordown_return_floorpastdest:
mov   al, FLOOR_PASTDEST
exit_moveplanefloordown:
LEAVE_MACRO 
pop   di
pop   si
ret   
label_4:
mov   di, word ptr es:[si]
cbw  
mov   bx, di
mov   cx, ax
sub   bx, dx
mov   dx, SECTORS_SEGMENT
mov   word ptr es:[si], bx
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloordown
mov   es, word ptr [bp - 2]
mov   dx, SECTORS_SEGMENT
mov   bx, cx
mov   ax, si
mov   word ptr es:[si], di
call  dword ptr ds:[_P_ChangeSector]
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
ret   


ENDP

PROC    T_MovePlaneFloorUp_ NEAR
PUBLIC  T_MovePlaneFloorUp_


push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
mov   ax, bx
mov   word ptr [bp - 2], SECTORS_SEGMENT
mov   es, word ptr [bp - 2]
mov   di, word ptr es:[si]
add   di, dx
cmp   di, bx
jle   label_5
mov   dx, SECTORS_SEGMENT
mov   al, cl
mov   di, word ptr es:[si]
cbw  
mov   word ptr es:[si], bx
mov   cx, ax
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloorup_return_floorpastdest
mov   es, word ptr [bp - 2]
mov   dx, SECTORS_SEGMENT
mov   bx, cx
mov   ax, si
mov   word ptr es:[si], di
call  dword ptr ds:[_P_ChangeSector]
exit_moveplanefloorup_return_floorpastdest:
mov   al, FLOOR_PASTDEST
exit_moveplanefloorup:

LEAVE_MACRO 
pop   di
pop   si
ret   
label_5:
mov   ax, word ptr es:[si]
mov   word ptr [bp - 4], ax
add   ax, dx
mov   word ptr es:[si], ax
mov   al, cl
cbw  
mov   dx, SECTORS_SEGMENT
mov   di, ax
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloorup
cmp   cl, 1
jne   label_6
mov   al, cl
LEAVE_MACRO 
pop   di
pop   si
ret   
label_6:
les   ax, dword ptr [bp - 4]
mov   dx, SECTORS_SEGMENT
mov   bx, di
mov   word ptr es:[si], ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
ret   



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
jg    label_30
jmp   label_18
label_30:
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

COMMENT @


PROC    EV_BuildStairs_ NEAR
PUBLIC  EV_BuildStairs_


0x0000000000002e3e:  53                push  bx
0x0000000000002e3f:  51                push  cx
0x0000000000002e40:  56                push  si
0x0000000000002e41:  57                push  di
0x0000000000002e42:  55                push  bp
0x0000000000002e43:  89 E5             mov   bp, sp
0x0000000000002e45:  81 EC 18 02       sub   sp, 0x218
0x0000000000002e49:  88 56 FE          mov   byte ptr [bp - 2], dl
0x0000000000002e4c:  C7 46 EE 00 00    mov   word ptr [bp - 012h], 0
0x0000000000002e51:  8D 96 E8 FD       lea   dx, [bp - 0x218]
0x0000000000002e55:  98                cbw  
0x0000000000002e56:  31 DB             xor   bx, bx
0x0000000000002e58:  C7 46 F0 00 00    mov   word ptr [bp - 010h], 0
0x0000000000002e5d:  E8 EC 13          call  0x424c
0x0000000000002e60:  83 BE E8 FD 00    cmp   word ptr [bp - 0x218], 0
0x0000000000002e65:  7D 03             jge   0x2e6a
0x0000000000002e67:  E9 5F 01          jmp   0x2fc9
0x0000000000002e6a:  8B 76 F0          mov   si, word ptr [bp - 010h]
0x0000000000002e6d:  C7 46 FA 2C 00    mov   word ptr [bp - 6], SIZEOF_THINKER_T
0x0000000000002e72:  8B 82 E8 FD       mov   ax, word ptr [bp + si - 0x218]
0x0000000000002e76:  31 D2             xor   dx, dx
0x0000000000002e78:  89 46 F8          mov   word ptr [bp - 8], ax
0x0000000000002e7b:  89 C1             mov   cx, ax
0x0000000000002e7d:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002e80:  C1 E1 04          shl   cx, 4
0x0000000000002e83:  8E C0             mov   es, ax
0x0000000000002e85:  89 CB             mov   bx, cx
0x0000000000002e87:  B8 00 28          mov   ax, TF_MOVEFLOOR_HIGHBITS
0x0000000000002e8a:  26 8B 3F          mov   di, word ptr es:[bx]
0x0000000000002e8d:  0E                
0x0000000000002e8e:  3E E8 5A 21       call  P_CreateThinker_
0x0000000000002e92:  89 C3             mov   bx, ax
0x0000000000002e94:  89 C6             mov   si, ax
0x0000000000002e96:  2D 04 34          sub   ax, (_thinkerlist + THINKER_T.t_data)
0x0000000000002e99:  F7 76 FA          div   word ptr [bp - 6]
0x0000000000002e9c:  C7 46 EE 01 00    mov   word ptr [bp - 012h], 1
0x0000000000002ea1:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002ea5:  8B 56 F8          mov   dx, word ptr [bp - 8]
0x0000000000002ea8:  83 46 F0 02       add   word ptr [bp - 010h], 2
0x0000000000002eac:  89 57 02          mov   word ptr ds:[bx + 2], dx
0x0000000000002eaf:  89 CB             mov   bx, cx
0x0000000000002eb1:  89 87 38 DE       mov   word ptr ds:[bx - 0x21c8], ax
0x0000000000002eb5:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000002eb8:  81 C3 38 DE       add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
0x0000000000002ebc:  3C 01             cmp   al, 1
0x0000000000002ebe:  75 63             jne   0x2f23
0x0000000000002ec0:  C7 46 F2 20 00    mov   word ptr [bp - 0Eh], 0x20
0x0000000000002ec5:  C7 46 F4 80 00    mov   word ptr [bp - 0Ch], 0x80
0x0000000000002eca:  8B 4E F4          mov   cx, word ptr [bp - 0Ch]
0x0000000000002ecd:  8B 46 F2          mov   ax, word ptr [bp - 0Eh]
0x0000000000002ed0:  01 F9             add   cx, di
0x0000000000002ed2:  89 44 09          mov   word ptr ds:[si + 9], ax
0x0000000000002ed5:  89 4C 07          mov   word ptr ds:[si + 7], cx
0x0000000000002ed8:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x0000000000002edb:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002ede:  C1 E3 04          shl   bx, 4
0x0000000000002ee1:  8E C0             mov   es, ax
0x0000000000002ee3:  26 8A 47 04       mov   al, byte ptr es:[bx + 4]
0x0000000000002ee7:  88 46 FC          mov   byte ptr [bp - 4], al
0x0000000000002eea:  26 8B 47 0A       mov   ax, word ptr es:[bx + 0xa]
0x0000000000002eee:  31 FF             xor   di, di
0x0000000000002ef0:  89 46 F6          mov   word ptr [bp - 0Ah], ax
0x0000000000002ef3:  26 8B 47 0C       mov   ax, word ptr es:[bx + 0xc]
0x0000000000002ef7:  30 D2             xor   dl, dl
0x0000000000002ef9:  89 46 EC          mov   word ptr [bp - 014h], ax
0x0000000000002efc:  88 D0             mov   al, dl
0x0000000000002efe:  30 E4             xor   ah, ah
0x0000000000002f00:  3B 46 F6          cmp   ax, word ptr [bp - 0Ah]
0x0000000000002f03:  7D 2E             jge   0x2f33
0x0000000000002f05:  03 46 EC          add   ax, word ptr [bp - 014h]
0x0000000000002f08:  01 C0             add   ax, ax
0x0000000000002f0a:  89 C3             mov   bx, ax
0x0000000000002f0c:  81 C3 50 CA       add   bx, _linebuffer
0x0000000000002f10:  8B 07             mov   ax, word ptr ds:[bx]
0x0000000000002f12:  BB 4A 2B          mov   bx, 0x2b4a
0x0000000000002f15:  8E C3             mov   es, bx
0x0000000000002f17:  89 C3             mov   bx, ax
0x0000000000002f19:  26 F6 07 04       test  byte ptr es:[bx], 4
0x0000000000002f1d:  75 17             jne   0x2f36
0x0000000000002f1f:  FE C2             inc   dl
0x0000000000002f21:  EB D9             jmp   0x2efc
0x0000000000002f23:  84 C0             test  al, al
0x0000000000002f25:  75 A3             jne   0x2eca
0x0000000000002f27:  C7 46 F2 02 00    mov   word ptr [bp - 0Eh], 2
0x0000000000002f2c:  C7 46 F4 40 00    mov   word ptr [bp - 0Ch], 0x40
0x0000000000002f31:  EB 97             jmp   0x2eca
0x0000000000002f33:  E9 7F 00          jmp   0x2fb5
0x0000000000002f36:  BB 00 70          mov   bx, LINES_PHYSICS_SEGMENT
0x0000000000002f39:  C1 E0 04          shl   ax, 4
0x0000000000002f3c:  8E C3             mov   es, bx
0x0000000000002f3e:  89 C3             mov   bx, ax
0x0000000000002f40:  83 C3 0A          add   bx, 0xa
0x0000000000002f43:  26 8B 1F          mov   bx, word ptr es:[bx]
0x0000000000002f46:  3B 5E F8          cmp   bx, word ptr [bp - 8]
0x0000000000002f49:  75 D4             jne   0x2f1f
0x0000000000002f4b:  89 C3             mov   bx, ax
0x0000000000002f4d:  C7 46 EA 00 00    mov   word ptr [bp - 016h], 0
0x0000000000002f52:  26 8B 77 0C       mov   si, word ptr es:[bx + 0xc]
0x0000000000002f56:  83 C3 0C          add   bx, 0xc
0x0000000000002f59:  89 F0             mov   ax, si
0x0000000000002f5b:  BB 90 21          mov   bx, SECTORS_SEGMENT
0x0000000000002f5e:  C1 E0 04          shl   ax, 4
0x0000000000002f61:  8E C3             mov   es, bx
0x0000000000002f63:  89 C3             mov   bx, ax
0x0000000000002f65:  89 46 E8          mov   word ptr [bp - 018h], ax
0x0000000000002f68:  26 8A 47 04       mov   al, byte ptr es:[bx + 4]
0x0000000000002f6c:  83 C3 04          add   bx, 4
0x0000000000002f6f:  3A 46 FC          cmp   al, byte ptr [bp - 4]
0x0000000000002f72:  75 AB             jne   0x2f1f
0x0000000000002f74:  8B 5E E8          mov   bx, word ptr [bp - 018h]
0x0000000000002f77:  81 C3 38 DE       add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
0x0000000000002f7b:  03 4E F4          add   cx, word ptr [bp - 0Ch]
0x0000000000002f7e:  83 3F 00          cmp   word ptr ds:[bx], 0
0x0000000000002f81:  75 9C             jne   0x2f1f
0x0000000000002f83:  B8 00 28          mov   ax, TF_MOVEFLOOR_HIGHBITS
0x0000000000002f86:  C7 46 FA 2C 00    mov   word ptr [bp - 6], SIZEOF_THINKER_T
0x0000000000002f8b:  0E                
0x0000000000002f8c:  3E E8 5C 20       call  P_CreateThinker_
0x0000000000002f90:  31 D2             xor   dx, dx
0x0000000000002f92:  89 C7             mov   di, ax
0x0000000000002f94:  2D 04 34          sub   ax, (_thinkerlist + THINKER_T.t_data)
0x0000000000002f97:  F7 76 FA          div   word ptr [bp - 6]
0x0000000000002f9a:  C6 45 04 01       mov   byte ptr ds:[di + 4], 1
0x0000000000002f9e:  89 4D 07          mov   word ptr ds:[di + 7], cx
0x0000000000002fa1:  89 75 02          mov   word ptr ds:[di + 2], si
0x0000000000002fa4:  89 4D 07          mov   word ptr ds:[di + 7], cx
0x0000000000002fa7:  8B 56 F2          mov   dx, word ptr [bp - 0Eh]
0x0000000000002faa:  89 55 09          mov   word ptr ds:[di + 9], dx
0x0000000000002fad:  89 76 F8          mov   word ptr [bp - 8], si
0x0000000000002fb0:  89 07             mov   word ptr ds:[bx], ax
0x0000000000002fb2:  E9 23 FF          jmp   0x2ed8
0x0000000000002fb5:  85 FF             test  di, di
0x0000000000002fb7:  74 03             je    0x2fbc
0x0000000000002fb9:  E9 1C FF          jmp   0x2ed8
0x0000000000002fbc:  8B 76 F0          mov   si, word ptr [bp - 010h]
0x0000000000002fbf:  83 BA E8 FD 00    cmp   word ptr [bp + si - 0x218], 0
0x0000000000002fc4:  7C 03             jl    0x2fc9
0x0000000000002fc6:  E9 A1 FE          jmp   0x2e6a
0x0000000000002fc9:  8B 46 EE          mov   ax, word ptr [bp - 012h]
0x0000000000002fcc:  C9                LEAVE_MACRO 
0x0000000000002fcd:  5F                pop   di
0x0000000000002fce:  5E                pop   si
0x0000000000002fcf:  59                pop   cx
0x0000000000002fd0:  5B                pop   bx
0x0000000000002fd1:  C3                ret   




0x0000000000002fd2:  0A 00             or    al, byte ptr ds:[bx + si]
0x0000000000002fd4:  04 00             add   al, 0
0x0000000000002fd6:  14 00             adc   al, 0
0x0000000000002fd8:  01 00             add   word ptr ds:[bx + si], ax
0x0000000000002fda:  3C 30             cmp   al, 0x30
0x0000000000002fdc:  57                push  di
0x0000000000002fdd:  30 6F 30          xor   byte ptr ds:[bx + 0x30], ch
0x0000000000002fe0:  87 30             xchg  word ptr ds:[bx + si], si
0x0000000000002fe2:  53                push  bx
0x0000000000002fe3:  98                cbw  
0x0000000000002fe4:  3C 05             cmp   al, 5
0x0000000000002fe6:  74 50             je    0x3038
0x0000000000002fe8:  93                xchg  ax, bx
0x0000000000002fe9:  D1 E3             shl   bx, 1
0x0000000000002feb:  8B 87 0C 08       mov   ax, word ptr ds:[bx + 0x80c]
0x0000000000002fef:  3B 87 14 08       cmp   ax, word ptr ds:[bx + 0x814]
0x0000000000002ff3:  74 43             je    0x3038
0x0000000000002ff5:  2E 8B 87 D2 2F    mov   ax, word ptr cs:[bx + 0x2fd2]
0x0000000000002ffa:  84 D2             test  dl, dl
0x0000000000002ffc:  75 06             jne   0x3004
0x0000000000002ffe:  8B D0             mov   dx, ax
0x0000000000003000:  D1 FA             sar   dx, 1
0x0000000000003002:  EB 03             jmp   0x3007
0x0000000000003004:  F6 E2             mul   dl
0x0000000000003006:  92                xchg  ax, dx
0x0000000000003007:  A0 31 01          mov   al, byte ptr ds:[_gameskill]
0x000000000000300a:  84 C0             test  al, al
0x000000000000300c:  74 04             je    0x3012
0x000000000000300e:  3C 04             cmp   al, 4
0x0000000000003010:  75 02             jne   0x3014
0x0000000000003012:  D1 E2             shl   dx, 1
0x0000000000003014:  8B 87 0C 08       mov   ax, word ptr ds:[bx + 0x80c]
0x0000000000003018:  03 D0             add   dx, ax
0x000000000000301a:  89 97 0C 08       mov   word ptr ds:[bx + 0x80c], dx
0x000000000000301e:  3B 97 14 08       cmp   dx, word ptr ds:[bx + 0x814]
0x0000000000003022:  7E 08             jle   0x302c
0x0000000000003024:  8B 97 14 08       mov   dx, word ptr ds:[bx + 0x814]
0x0000000000003028:  89 97 0C 08       mov   word ptr ds:[bx + 0x80c], dx
0x000000000000302c:  85 C0             test  ax, ax
0x000000000000302e:  75 1C             jne   0x304c
0x0000000000003030:  A0 00 08          mov   al, byte ptr ds:[0x800]
0x0000000000003033:  2E FF A7 DA 2F    jmp   word ptr cs:[bx + 0x2fda]
0x0000000000003038:  33 C0             xor   ax, ax
0x000000000000303a:  5B                pop   bx
0x000000000000303b:  C3                ret   
0x000000000000303c:  3C 00             cmp   al, 0
0x000000000000303e:  75 0C             jne   0x304c
0x0000000000003040:  80 3E 05 08 00    cmp   byte ptr ds:[0x805], 0
0x0000000000003045:  74 09             je    0x3050
0x0000000000003047:  C6 06 01 08 03    mov   byte ptr ds:[0x801], 3
0x000000000000304c:  B0 01             mov   al, 1
0x000000000000304e:  5B                pop   bx
0x000000000000304f:  C3                ret   
0x0000000000003050:  B0 01             mov   al, 1
0x0000000000003052:  A2 00 08          mov   byte ptr ds:[0x800], al
0x0000000000003055:  5B                pop   bx
0x0000000000003056:  C3                ret   
0x0000000000003057:  84 C0             test  al, al
0x0000000000003059:  74 04             je    0x305f
0x000000000000305b:  3C 01             cmp   al, 1
0x000000000000305d:  75 ED             jne   0x304c
0x000000000000305f:  80 3E 04 08 00    cmp   byte ptr ds:[0x804], 0
0x0000000000003064:  74 E6             je    0x304c
0x0000000000003066:  C6 06 01 08 02    mov   byte ptr ds:[0x801], 2
0x000000000000306b:  B0 01             mov   al, 1
0x000000000000306d:  5B                pop   bx
0x000000000000306e:  C3                ret   
0x000000000000306f:  84 C0             test  al, al
0x0000000000003071:  74 04             je    0x3077
0x0000000000003073:  3C 01             cmp   al, 1
0x0000000000003075:  75 D5             jne   0x304c
0x0000000000003077:  80 3E 07 08 00    cmp   byte ptr ds:[0x807], 0
0x000000000000307c:  74 CE             je    0x304c
0x000000000000307e:  C6 06 01 08 05    mov   byte ptr ds:[0x801], 5
0x0000000000003083:  B0 01             mov   al, 1
0x0000000000003085:  5B                pop   bx
0x0000000000003086:  C3                ret   
0x0000000000003087:  3C 00             cmp   al, 0
0x0000000000003089:  75 C1             jne   0x304c
0x000000000000308b:  80 3E 06 08 00    cmp   byte ptr ds:[0x806], 0
0x0000000000003090:  74 BA             je    0x304c
0x0000000000003092:  C6 06 01 08 04    mov   byte ptr ds:[0x801], 4
0x0000000000003097:  B0 01             mov   al, 1
0x0000000000003099:  5B                pop   bx
0x000000000000309a:  C3                ret   
0x000000000000309b:  53                push  bx
0x000000000000309c:  98                cbw  
0x000000000000309d:  93                xchg  ax, bx
0x000000000000309e:  B0 0B             mov   al, 0xb
0x00000000000030a0:  F6 E3             mul   bl
0x00000000000030a2:  93                xchg  ax, bx
0x00000000000030a3:  8A B7 58 08       mov   dh, byte ptr ds:[bx + 0x858]
0x00000000000030a7:  80 FE 05          cmp   dh, 5
0x00000000000030aa:  75 0C             jne   0x30b8
0x00000000000030ac:  93                xchg  ax, bx
0x00000000000030ad:  80 BF 02 08 00    cmp   byte ptr ds:[bx + 0x802], 0
0x00000000000030b2:  74 1B             je    0x30cf
0x00000000000030b4:  33 C0             xor   ax, ax
0x00000000000030b6:  5B                pop   bx
0x00000000000030b7:  C3                ret   
0x00000000000030b8:  93                xchg  ax, bx
0x00000000000030b9:  8A C6             mov   al, dh
0x00000000000030bb:  84 D2             test  dl, dl
0x00000000000030bd:  75 02             jne   0x30c1
0x00000000000030bf:  B2 02             mov   dl, 2
0x00000000000030c1:  E8 1E FF          call  0x2fe2
0x00000000000030c4:  84 C0             test  al, al
0x00000000000030c6:  74 E5             je    0x30ad
0x00000000000030c8:  80 BF 02 08 00    cmp   byte ptr ds:[bx + 0x802], 0
0x00000000000030cd:  75 09             jne   0x30d8
0x00000000000030cf:  C6 87 02 08 01    mov   byte ptr ds:[bx + 0x802], 1
0x00000000000030d4:  88 1E 01 08       mov   byte ptr ds:[0x801], bl
0x00000000000030d8:  B0 01             mov   al, 1
0x00000000000030da:  5B                pop   bx
0x00000000000030db:  C3                ret   
0x00000000000030dc:  53                push  bx
0x00000000000030dd:  BB E8 07          mov   bx, 0x7e8
0x00000000000030e0:  83 3F 64          cmp   word ptr ds:[bx], 0x64
0x00000000000030e3:  7D 17             jge   0x30fc
0x00000000000030e5:  03 07             add   ax, word ptr ds:[bx]
0x00000000000030e7:  3D 64 00          cmp   ax, 0x64
0x00000000000030ea:  7E 03             jle   0x30ef
0x00000000000030ec:  B8 64 00          mov   ax, 0x64
0x00000000000030ef:  89 07             mov   word ptr ds:[bx], ax
0x00000000000030f1:  8B 1E EC 06       mov   bx, word ptr ds:[0x6ec]
0x00000000000030f5:  89 47 1C          mov   word ptr ds:[bx + 0x1c], ax
0x00000000000030f8:  B0 01             mov   al, 1
0x00000000000030fa:  5B                pop   bx
0x00000000000030fb:  C3                ret   
0x00000000000030fc:  32 C0             xor   al, al
0x00000000000030fe:  5B                pop   bx
0x00000000000030ff:  C3                ret   
0x0000000000003100:  52                push  dx
0x0000000000003101:  BA 64 00          mov   dx, 0x64
0x0000000000003104:  3C 01             cmp   al, 1
0x0000000000003106:  74 02             je    0x310a
0x0000000000003108:  D1 E2             shl   dx, 1
0x000000000000310a:  3B 16 EA 07       cmp   dx, word ptr ds:[0x7ea]
0x000000000000310e:  7F 04             jg    0x3114
0x0000000000003110:  33 C0             xor   ax, ax
0x0000000000003112:  5A                pop   dx
0x0000000000003113:  C3                ret   
0x0000000000003114:  A2 EC 07          mov   byte ptr ds:[0x7ec], al
0x0000000000003117:  89 16 EA 07       mov   word ptr ds:[0x7ea], dx
0x000000000000311b:  B0 01             mov   al, 1
0x000000000000311d:  5A                pop   dx
0x000000000000311e:  C3                ret   
0x000000000000311f:  53                push  bx
0x0000000000003120:  98                cbw  
0x0000000000003121:  8B D8             mov   bx, ax
0x0000000000003123:  80 BF FA 07 00    cmp   byte ptr ds:[bx + 0x7fa], 0
0x0000000000003128:  74 03             je    0x312d
0x000000000000312a:  5E                pop   si
0x000000000000312b:  5B                pop   bx
0x000000000000312c:  C3                ret   
0x000000000000312d:  C6 06 2A 08 06    mov   byte ptr ds:[0x82a], 6
0x0000000000003132:  C6 87 FA 07 01    mov   byte ptr ds:[bx + 0x7fa], 1
0x0000000000003137:  5B                pop   bx
0x0000000000003138:  C3                ret   
0x0000000000003139:  53                push  bx
0x000000000000313a:  8B D8             mov   bx, ax
0x000000000000313c:  D1 E3             shl   bx, 1
0x000000000000313e:  85 C0             test  ax, ax
0x0000000000003140:  75 05             jne   0x3147
0x0000000000003142:  B8 1A 04          mov   ax, 0x41a
0x0000000000003145:  EB 25             jmp   0x316c
0x0000000000003147:  3C 02             cmp   al, 2
0x0000000000003149:  74 13             je    0x315e
0x000000000000314b:  72 2C             jb    0x3179
0x000000000000314d:  3C 04             cmp   al, 4
0x000000000000314f:  72 18             jb    0x3169
0x0000000000003151:  77 21             ja    0x3174
0x0000000000003153:  83 BF EE 07 00    cmp   word ptr ds:[bx + 0x7ee], 0
0x0000000000003158:  74 25             je    0x317f
0x000000000000315a:  33 C0             xor   ax, ax
0x000000000000315c:  5B                pop   bx
0x000000000000315d:  CB                retf  
0x000000000000315e:  93                xchg  ax, bx
0x000000000000315f:  C4 1E 30 07       les   bx, dword ptr ds:[0x730]
0x0000000000003163:  26 80 4F 16 04    or    byte ptr es:[bx + 0x16], 4
0x0000000000003168:  93                xchg  ax, bx
0x0000000000003169:  B8 34 08          mov   ax, 0x834
0x000000000000316c:  89 87 EE 07       mov   word ptr ds:[bx + 0x7ee], ax
0x0000000000003170:  B0 01             mov   al, 1
0x0000000000003172:  5B                pop   bx
0x0000000000003173:  CB                retf  
0x0000000000003174:  B8 68 10          mov   ax, 0x1068
0x0000000000003177:  EB F3             jmp   0x316c
0x0000000000003179:  B8 64 00          mov   ax, 0x64
0x000000000000317c:  E8 5D FF          call  0x30dc
0x000000000000317f:  B8 01 00          mov   ax, 1
0x0000000000003182:  89 87 EE 07       mov   word ptr ds:[bx + 0x7ee], ax
0x0000000000003186:  5B                pop   bx
0x0000000000003187:  CB                retf  

ENDP

@

PROC    P_FLOOR_ENDMARKER_ NEAR
PUBLIC  P_FLOOR_ENDMARKER_
ENDP

END