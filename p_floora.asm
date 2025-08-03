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

COMMENT @


dw 2B51 2B7D 2B8C 2bB2 2C07 2CB3 2D73 2C1E 2C65 2BAE 2BF0 2B68 2C42 






push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0x220
mov   cx, dx
mov   byte ptr [bp - 2], bl
mov   word ptr [bp - 0x1c], 0
lea   dx, [bp - 0x220]
mov   word ptr [bp - 0xa], 0
cbw  
xor   bx, bx
shl   cx, 4
call  0x424c
mov   word ptr [bp - 0x18], cx
cmp   word ptr [bp - 0x220], 0
jl    0x2b4f
mov   si, word ptr [bp - 0xa]
mov   cx, word ptr [bp + si - 0x220]
mov   ax, cx
mov   word ptr [bp - 4], SECTORS_SEGMENT
shl   ax, 4
mov   es, word ptr [bp - 4]
mov   word ptr [bp - 6], ax
add   ax, 0xde30
mov   bx, word ptr [bp - 6]
mov   word ptr [bp - 0xe], ax
mov   ax, word ptr es:[bx + 0xc]
mov   word ptr [bp - 0x1a], ax
mov   ax, word ptr es:[bx + 2]
mov   word ptr [bp - 0x16], ax
mov   ax, word ptr es:[bx]
mov   di, 0x2c
mov   word ptr [bp - 0xc], ax
mov   ax, 0x2800
xor   dx, dx
push  cs
call  0x4fec
nop   
mov   bx, ax
mov   si, ax
sub   ax, 0x3404
div   di
mov   di, word ptr [bp - 0xe]
mov   word ptr [bp - 0x1c], 1
mov   word ptr ds:[di + 8], ax
mov   al, byte ptr [bp - 2]
mov   byte ptr ds:[bx + 1], 0
add   word ptr [bp - 0xa], 2
mov   byte ptr ds:[bx], al
cmp   al, 0xc
ja    0x2b68
xor   ah, ah
mov   di, ax
add   di, ax
jmp   word ptr cs:[di + 0x2a94]
jmp   0x2b75
mov   byte ptr ds:[bx + 4], 0xff
mov   dx, 1
mov   word ptr ds:[bx + 9], 8
mov   ax, cx
mov   word ptr ds:[bx + 2], cx
call  0x40ef
mov   word ptr ds:[bx + 7], ax
mov   si, word ptr [bp - 0xa]
cmp   word ptr [bp + si - 0x220], 0
jl    0x2b75
jmp   0x2ade
mov   ax, word ptr [bp - 0x1c]
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf  
mov   byte ptr ds:[bx + 4], 0xff
mov   ax, cx
mov   word ptr ds:[bx + 9], 8
xor   dx, dx
jmp   0x2b5f
mov   byte ptr ds:[bx + 4], 0xff
mov   dx, 1
mov   word ptr ds:[bx + 9], 0x20
mov   ax, cx
mov   word ptr ds:[bx + 2], cx
call  0x40ef
mov   word ptr ds:[bx + 7], ax
cmp   ax, word ptr [bp - 0xc]
je    0x2b68
add   word ptr ds:[bx + 7], 0x40
jmp   0x2b68
mov   byte ptr ds:[bx + 1], 1
mov   byte ptr ds:[si + 4], 1
mov   ax, cx
mov   word ptr ds:[si + 9], 8
xor   dx, dx
mov   word ptr ds:[si + 2], cx
call  0x41d6
mov   word ptr ds:[si + 7], ax
cmp   ax, word ptr [bp - 0x16]
jle   0x2bd3
mov   ax, word ptr [bp - 0x16]
mov   word ptr ds:[si + 7], ax
add   si, 7
cmp   byte ptr [bp - 2], 9
jne   0x2be6
mov   bx, 1
shl   bx, 6
sub   word ptr ds:[si], bx
jmp   0x2b68
xor   bx, bx
shl   bx, 6
sub   word ptr ds:[si], bx
jmp   0x2b68
mov   byte ptr ds:[bx + 4], 1
mov   dx, word ptr [bp - 0xc]
mov   word ptr ds:[bx + 9], 0x20
mov   ax, cx
mov   word ptr ds:[bx + 2], cx
call  0x4165
jmp   0x2b65
mov   byte ptr ds:[bx + 4], 1
mov   dx, word ptr [bp - 0xc]
mov   word ptr ds:[bx + 9], 8
mov   ax, cx
mov   word ptr ds:[bx + 2], cx
call  0x4165
jmp   0x2b65
mov   byte ptr ds:[bx + 4], 1
mov   word ptr ds:[bx + 2], cx
mov   ax, SECTORS_SEGMENT
mov   si, word ptr ds:[bx + 2]
mov   word ptr ds:[bx + 9], 8
shl   si, 4
mov   es, ax
mov   cx, word ptr es:[si]
add   cx, 0xc0
mov   word ptr ds:[bx + 7], cx
jmp   0x2b68
mov   byte ptr ds:[bx + 4], 1
mov   word ptr ds:[bx + 2], cx
mov   ax, SECTORS_SEGMENT
mov   si, word ptr ds:[bx + 2]
mov   word ptr ds:[bx + 9], 8
shl   si, 4
mov   es, ax
mov   cx, word ptr es:[si]
add   ch, 0x10
mov   word ptr ds:[bx + 7], cx
jmp   0x2b68
mov   byte ptr ds:[bx + 4], 1
mov   word ptr ds:[bx + 2], cx
mov   ax, SECTORS_SEGMENT
mov   si, word ptr ds:[bx + 2]
mov   word ptr ds:[bx + 9], 8
shl   si, 4
mov   es, ax
mov   cx, word ptr es:[si]
add   cx, 0xc0
mov   ax, word ptr [bp - 0x18]
mov   word ptr ds:[bx + 7], cx
mov   bx, ax
mov   word ptr [bp - 0x20], ax
mov   al, byte ptr es:[bx + 4]
add   bx, 4
les   bx, dword ptr [bp - 6]
mov   word ptr [bp - 0x1e], 0
mov   byte ptr es:[bx + 4], al
mov   bx, word ptr [bp - 0x20]
add   bx, 0xde3e
mov   al, byte ptr ds:[bx]
mov   bx, word ptr [bp - 0xe]
mov   byte ptr ds:[bx + 0xe], al
jmp   0x2b68
mov   byte ptr ds:[bx + 4], 1
mov   word ptr [bp - 8], 0x7fff
mov   word ptr ds:[bx + 9], 8
mov   di, word ptr [bp - 6]
mov   word ptr ds:[bx + 2], cx
mov   es, word ptr [bp - 4]
xor   bx, bx
cmp   word ptr es:[di + 0xa], 0
jg    0x2cd6
jmp   0x2d57
mov   ax, word ptr [bp - 0x1a]
add   ax, ax
mov   word ptr [bp - 0x12], ax
mov   dx, bx
mov   ax, cx
call  0x4076
test  ax, ax
je    0x2d49
mov   ax, word ptr [bp - 0x12]
mov   di, ax
add   di, 0xca50
mov   di, word ptr ds:[di]
mov   ax, 0x2991
shl   di, 2
mov   es, ax
mov   ax, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
mov   di, 0x2483
shl   ax, 3
mov   es, di
mov   di, ax
add   di, 2
mov   ax, 0x3c4a
mov   di, word ptr es:[di]
mov   es, ax
mov   al, byte ptr es:[di]
xor   ah, ah
inc   ax
cmp   ax, word ptr [bp - 8]
jge   0x2d26
mov   word ptr [bp - 8], ax
mov   di, dx
mov   ax, 0x2483
shl   di, 3
mov   es, ax
add   di, 2
mov   ax, 0x3c4a
mov   di, word ptr es:[di]
mov   es, ax
mov   al, byte ptr es:[di]
xor   ah, ah
inc   ax
cmp   ax, word ptr [bp - 8]
jge   0x2d49
mov   word ptr [bp - 8], ax
les   di, dword ptr [bp - 6]
inc   bx
add   word ptr [bp - 0x12], 2
cmp   bx, word ptr es:[di + 0xa]
jl    0x2cde
mov   ax, SECTORS_SEGMENT
mov   bx, word ptr ds:[si + 2]
mov   dx, word ptr [bp - 8]
shl   bx, 4
mov   es, ax
shl   dx, 3
mov   ax, word ptr es:[bx]
add   ax, dx
mov   word ptr ds:[si + 7], ax
jmp   0x2b68
mov   di, word ptr [bp - 6]
mov   byte ptr ds:[bx + 4], 0xff
mov   ax, cx
mov   word ptr ds:[bx + 9], 8
xor   dx, dx
mov   word ptr ds:[bx + 2], cx
call  0x40ef
mov   word ptr ds:[bx + 7], ax
mov   es, word ptr [bp - 4]
mov   al, byte ptr es:[di + 4]
mov   byte ptr ds:[bx + 6], al
xor   bx, bx
cmp   word ptr es:[di + 0xa], 0
jg    0x2da2
jmp   0x2b68
mov   ax, word ptr [bp - 0x1a]
add   ax, ax
mov   word ptr [bp - 0x10], ax
mov   dx, bx
mov   ax, cx
call  0x4076
test  ax, ax
je    0x2e29
mov   ax, word ptr [bp - 0x10]
mov   di, ax
mov   word ptr [bp - 0x14], 0x2991
add   di, 0xca50
mov   ax, word ptr ds:[di]
mov   di, word ptr ds:[di]
mov   dx, 0x7000
shl   di, 4
mov   es, dx
shl   ax, 2
cmp   cx, word ptr es:[di + 0xa]
jne   0x2e01
mov   es, word ptr [bp - 0x14]
mov   di, ax
mov   cx, word ptr es:[di + 2]
les   di, dword ptr [bp - 6]
mov   ax, word ptr es:[di]
cmp   ax, word ptr ds:[si + 7]
jne   0x2e29
mov   bx, di
mov   al, byte ptr es:[bx + 4]
mov   bx, word ptr [bp - 0xe]
mov   byte ptr ds:[si + 6], al
mov   al, byte ptr ds:[bx + 0xe]
mov   byte ptr ds:[si + 5], al
jmp   0x2b68
mov   es, word ptr [bp - 0x14]
mov   di, ax
mov   cx, word ptr es:[di]
les   di, dword ptr [bp - 6]
mov   ax, word ptr es:[di]
cmp   ax, word ptr ds:[si + 7]
jne   0x2e29
mov   bx, di
mov   al, byte ptr es:[bx + 4]
mov   bx, word ptr [bp - 0xe]
mov   byte ptr ds:[si + 6], al
mov   al, byte ptr ds:[bx + 0xe]
mov   byte ptr ds:[si + 5], al
jmp   0x2b68
les   di, dword ptr [bp - 6]
inc   bx
add   word ptr [bp - 0x10], 2
cmp   bx, word ptr es:[di + 0xa]
jge   0x2e3a
jmp   0x2daa
jmp   0x2b68


ENDP

PROC    EV_BuildStairs_ NEAR
PUBLIC  EV_BuildStairs_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0x218
mov   byte ptr [bp - 2], dl
mov   word ptr [bp - 0x12], 0
lea   dx, [bp - 0x218]
cbw  
xor   bx, bx
mov   word ptr [bp - 0x10], 0
call  0x424c
cmp   word ptr [bp - 0x218], 0
jge   0x2e6a
jmp   0x2fc9
mov   si, word ptr [bp - 0x10]
mov   word ptr [bp - 6], 0x2c
mov   ax, word ptr [bp + si - 0x218]
xor   dx, dx
mov   word ptr [bp - 8], ax
mov   cx, ax
mov   ax, SECTORS_SEGMENT
shl   cx, 4
mov   es, ax
mov   bx, cx
mov   ax, 0x2800
mov   di, word ptr es:[bx]
push  cs
call  0x4fec
mov   bx, ax
mov   si, ax
sub   ax, 0x3404
div   word ptr [bp - 6]
mov   word ptr [bp - 0x12], 1
mov   byte ptr ds:[bx + 4], 1
mov   dx, word ptr [bp - 8]
add   word ptr [bp - 0x10], 2
mov   word ptr ds:[bx + 2], dx
mov   bx, cx
mov   word ptr ds:[bx - 0x21c8], ax
mov   al, byte ptr [bp - 2]
add   bx, 0xde38
cmp   al, 1
jne   0x2f23
mov   word ptr [bp - 0xe], 0x20
mov   word ptr [bp - 0xc], 0x80
mov   cx, word ptr [bp - 0xc]
mov   ax, word ptr [bp - 0xe]
add   cx, di
mov   word ptr ds:[si + 9], ax
mov   word ptr ds:[si + 7], cx
mov   bx, word ptr [bp - 8]
mov   ax, SECTORS_SEGMENT
shl   bx, 4
mov   es, ax
mov   al, byte ptr es:[bx + 4]
mov   byte ptr [bp - 4], al
mov   ax, word ptr es:[bx + 0xa]
xor   di, di
mov   word ptr [bp - 0xa], ax
mov   ax, word ptr es:[bx + 0xc]
xor   dl, dl
mov   word ptr [bp - 0x14], ax
mov   al, dl
xor   ah, ah
cmp   ax, word ptr [bp - 0xa]
jge   0x2f33
add   ax, word ptr [bp - 0x14]
add   ax, ax
mov   bx, ax
add   bx, 0xca50
mov   ax, word ptr ds:[bx]
mov   bx, 0x2b4a
mov   es, bx
mov   bx, ax
test  byte ptr es:[bx], 4
jne   0x2f36
inc   dl
jmp   0x2efc
test  al, al
jne   0x2eca
mov   word ptr [bp - 0xe], 2
mov   word ptr [bp - 0xc], 0x40
jmp   0x2eca
jmp   0x2fb5
mov   bx, 0x7000
shl   ax, 4
mov   es, bx
mov   bx, ax
add   bx, 0xa
mov   bx, word ptr es:[bx]
cmp   bx, word ptr [bp - 8]
jne   0x2f1f
mov   bx, ax
mov   word ptr [bp - 0x16], 0
mov   si, word ptr es:[bx + 0xc]
add   bx, 0xc
mov   ax, si
mov   bx, SECTORS_SEGMENT
shl   ax, 4
mov   es, bx
mov   bx, ax
mov   word ptr [bp - 0x18], ax
mov   al, byte ptr es:[bx + 4]
add   bx, 4
cmp   al, byte ptr [bp - 4]
jne   0x2f1f
mov   bx, word ptr [bp - 0x18]
add   bx, 0xde38
add   cx, word ptr [bp - 0xc]
cmp   word ptr ds:[bx], 0
jne   0x2f1f
mov   ax, 0x2800
mov   word ptr [bp - 6], 0x2c
push  cs
call  0x4fec
xor   dx, dx
mov   di, ax
sub   ax, 0x3404
div   word ptr [bp - 6]
mov   byte ptr ds:[di + 4], 1
mov   word ptr ds:[di + 7], cx
mov   word ptr ds:[di + 2], si
mov   word ptr ds:[di + 7], cx
mov   dx, word ptr [bp - 0xe]
mov   word ptr ds:[di + 9], dx
mov   word ptr [bp - 8], si
mov   word ptr ds:[bx], ax
jmp   0x2ed8
test  di, di
je    0x2fbc
jmp   0x2ed8
mov   si, word ptr [bp - 0x10]
cmp   word ptr [bp + si - 0x218], 0
jl    0x2fc9
jmp   0x2e6a
mov   ax, word ptr [bp - 0x12]
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
or    al, byte ptr ds:[bx + si]
add   al, 0
adc   al, 0
add   word ptr ds:[bx + si], ax
cmp   al, 0x30
push  di
xor   byte ptr ds:[bx + 0x30], ch
xchg  word ptr ds:[bx + si], si
push  bx
cbw  
cmp   al, 5
je    0x3038
xchg  ax, bx
shl   bx, 1
mov   ax, word ptr ds:[bx + 0x80c]
cmp   ax, word ptr ds:[bx + 0x814]
je    0x3038
mov   ax, word ptr cs:[bx + 0x2fd2]
test  dl, dl
jne   0x3004
mov   dx, ax
sar   dx, 1
jmp   0x3007
mul   dl
xchg  ax, dx
mov   al, byte ptr ds:[_gameskill]
test  al, al
je    0x3012
cmp   al, 4
jne   0x3014
shl   dx, 1
mov   ax, word ptr ds:[bx + 0x80c]
add   dx, ax
mov   word ptr ds:[bx + 0x80c], dx
cmp   dx, word ptr ds:[bx + 0x814]
jle   0x302c
mov   dx, word ptr ds:[bx + 0x814]
mov   word ptr ds:[bx + 0x80c], dx
test  ax, ax
jne   0x304c
mov   al, byte ptr ds:[0x800]
jmp   word ptr cs:[bx + 0x2fda]
xor   ax, ax
pop   bx
ret   
cmp   al, 0
jne   0x304c
cmp   byte ptr ds:[0x805], 0
je    0x3050
mov   byte ptr ds:[0x801], 3
mov   al, 1
pop   bx
ret   
mov   al, 1
mov   byte ptr ds:[0x800], al
pop   bx
ret   
test  al, al
je    0x305f
cmp   al, 1
jne   0x304c
cmp   byte ptr ds:[0x804], 0
je    0x304c
mov   byte ptr ds:[0x801], 2
mov   al, 1
pop   bx
ret   
test  al, al
je    0x3077
cmp   al, 1
jne   0x304c
cmp   byte ptr ds:[0x807], 0
je    0x304c
mov   byte ptr ds:[0x801], 5
mov   al, 1
pop   bx
ret   
cmp   al, 0
jne   0x304c
cmp   byte ptr ds:[0x806], 0
je    0x304c
mov   byte ptr ds:[0x801], 4
mov   al, 1
pop   bx
ret   
push  bx
cbw  
xchg  ax, bx
mov   al, 0xb
mul   bl
xchg  ax, bx
mov   dh, byte ptr ds:[bx + 0x858]
cmp   dh, 5
jne   0x30b8
xchg  ax, bx
cmp   byte ptr ds:[bx + 0x802], 0
je    0x30cf
xor   ax, ax
pop   bx
ret   
xchg  ax, bx
mov   al, dh
test  dl, dl
jne   0x30c1
mov   dl, 2
call  0x2fe2
test  al, al
je    0x30ad
cmp   byte ptr ds:[bx + 0x802], 0
jne   0x30d8
mov   byte ptr ds:[bx + 0x802], 1
mov   byte ptr ds:[0x801], bl
mov   al, 1
pop   bx
ret   
push  bx
mov   bx, 0x7e8
cmp   word ptr ds:[bx], 0x64
jge   0x30fc
add   ax, word ptr ds:[bx]
cmp   ax, 0x64
jle   0x30ef
mov   ax, 0x64
mov   word ptr ds:[bx], ax
mov   bx, word ptr ds:[0x6ec]
mov   word ptr ds:[bx + 0x1c], ax
mov   al, 1
pop   bx
ret   
xor   al, al
pop   bx
ret   
push  dx
mov   dx, 0x64
cmp   al, 1
je    0x310a
shl   dx, 1
cmp   dx, word ptr ds:[0x7ea]
jg    0x3114
xor   ax, ax
pop   dx
ret   
mov   byte ptr ds:[0x7ec], al
mov   word ptr ds:[0x7ea], dx
mov   al, 1
pop   dx
ret   
push  bx
cbw  
mov   bx, ax
cmp   byte ptr ds:[bx + 0x7fa], 0
je    0x312d
pop   si
pop   bx
ret   
mov   byte ptr ds:[0x82a], 6
mov   byte ptr ds:[bx + 0x7fa], 1
pop   bx
ret   
push  bx
mov   bx, ax
shl   bx, 1
test  ax, ax
jne   0x3147
mov   ax, 0x41a
jmp   0x316c
cmp   al, 2
je    0x315e
jb    0x3179
cmp   al, 4
jb    0x3169
ja    0x3174
cmp   word ptr ds:[bx + 0x7ee], 0
je    0x317f
xor   ax, ax
pop   bx
retf  
xchg  ax, bx
les   bx, dword ptr ds:[0x730]
or    byte ptr es:[bx + 0x16], 4
xchg  ax, bx
mov   ax, 0x834
mov   word ptr ds:[bx + 0x7ee], ax
mov   al, 1
pop   bx
retf  
mov   ax, 0x1068
jmp   0x316c
mov   ax, 0x64
call  0x30dc
mov   ax, 1
mov   word ptr ds:[bx + 0x7ee], ax
pop   bx
retf  

ENDP

@

PROC    P_FLOOR_ENDMARKER_ NEAR
PUBLIC  P_FLOOR_ENDMARKER_
ENDP

END