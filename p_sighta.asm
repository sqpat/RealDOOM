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


EXTRN FixedMul1632_:FAR
EXTRN P_CrossBSPNode_:NEAR

INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA

EXTRN _validcount:BYTE
EXTRN _sightzstart:DWORD
EXTRN _bottomslope:DWORD
EXTRN _topslope:DWORD
EXTRN _cachedt2x:DWORD
EXTRN _cachedt2y:DWORD
EXTRN _strace:DWORD

.CODE

; boolean __far P_CheckSight (  mobj_t __near* t1, mobj_t __near* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos ) {

REJECTMATRIX_SEGMENT = 05C00h

PROC    P_CheckSight_
PUBLIC  P_CheckSight_

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Eh
mov   si, word ptr [bp + 0Ah]
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 6], dx
mov   word ptr [bp - 2], cx
mov   di, dx
mov   ax, word ptr [di + 4]
cwd   
mov   word ptr [bp - 0Ah], dx
mov   dx, word ptr ds:[_numsectors]
mov   di, word ptr [bp - 4]
mov   cx, ax
mov   ax, word ptr [di + 4]
mul   dx
add   ax, cx
adc   dx, word ptr [bp - 0Ah]
mov   word ptr [bp - 0Eh], ax
mov   word ptr [bp - 0Ch], dx
mov   cx, 3
loop_shift:
shr   word ptr [bp - 0Ch], 1
rcr   word ptr [bp - 0Eh], 1
loop  loop_shift
mov   dx, 1
mov   cx, ax
mov   ax, REJECTMATRIX_SEGMENT
mov   di, word ptr [bp - 0Eh]
mov   es, ax
and   cl, 7
mov   al, byte ptr es:[di]
shl   dx, cl
xor   ah, ah
test  ax, dx
je    not_in_reject_table
xor   al, al
leave 
pop   di
pop   si
retf  4
not_in_reject_table:
inc   word ptr ds:[_validcount]
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[bx + 8]
mov   di, word ptr [bp - 4]
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr [di + 0Ah]
mov   dx, word ptr es:[bx + 0Ah]
add   word ptr [bp - 0Ah], ax
adc   dx, word ptr [di + 0Ch]
mov   word ptr [bp - 8], dx
mov   dx, word ptr [di + 0Ch]
sar   dx, 1
rcr   ax, 1
mov   cx, word ptr [bp - 0Ah]
sar   dx, 1
rcr   ax, 1
sub   cx, ax
mov   ax, word ptr [bp - 8]
sbb   ax, dx
mov   word ptr ds:[_sightzstart], cx
mov   word ptr ds:[_sightzstart + 2], ax
mov   es, word ptr [bp + 0Ch]
mov   di, word ptr [bp - 6]
mov   ax, word ptr es:[si + 8]
mov   dx, word ptr es:[si + 0Ah]
add   ax, word ptr [di + 0Ah]
adc   dx, word ptr [di + 0Ch]
mov   word ptr [bp - 0Ah], dx
mov   dx, cx
mov   cx, word ptr ds:[_sightzstart + 2]
sub   ax, dx
mov   word ptr ds:[_topslope], ax
mov   ax, word ptr [bp - 0Ah]
sbb   ax, cx
mov   word ptr ds:[_topslope+2], ax
mov   ax, word ptr es:[si + 8]
mov   cx, word ptr es:[si + 0Ah]
sub   ax, dx
sbb   cx, word ptr ds:[_sightzstart + 2]
mov   word ptr ds:[_bottomslope], ax
mov   word ptr ds:[_bottomslope+2], cx
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
mov   word ptr ds:[_strace], ax
mov   word ptr ds:[_strace+2], dx
mov   dx, word ptr es:[bx + 4]
mov   ax, word ptr es:[bx + 6]
mov   word ptr ds:[_strace+4], dx
mov   word ptr ds:[_strace+6], ax
mov   es, word ptr [bp + 0Ch]
mov   dx, word ptr es:[si]
mov   ax, word ptr es:[si + 2]
mov   word ptr ds:[_cachedt2x], dx
mov   word ptr ds:[_cachedt2x+2], ax
mov   dx, word ptr es:[si + 4]
mov   ax, word ptr es:[si + 6]
mov   word ptr ds:[_cachedt2y], dx
mov   word ptr ds:[_cachedt2y+2], ax
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
mov   es, word ptr [bp - 2]
sub   ax, word ptr es:[bx]
sbb   dx, word ptr es:[bx + 2]
mov   word ptr ds:[_strace+8], ax
mov   word ptr ds:[_strace+0Ah], dx
mov   es, word ptr [bp + 0Ch]
mov   dx, word ptr es:[si + 4]
mov   ax, word ptr es:[si + 6]
mov   es, word ptr [bp - 2]
sub   dx, word ptr es:[bx + 4]
sbb   ax, word ptr es:[bx + 6]

mov   word ptr ds:[_strace+0Eh], ax
mov   ax, word ptr ds:[_numnodes]
dec   ax
mov   word ptr ds:[_strace+0Ch], dx
call  P_CrossBSPNode_
LEAVE_MACRO
pop   di
pop   si
retf  4

ENDP
END