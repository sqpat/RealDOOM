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

; todo change to near segments

REJECTMATRIX_SEGMENT = 05C00h

PROC    P_CheckSight_
PUBLIC  P_CheckSight_

push  si
push  di
push  bp
mov   bp, sp
push cx			; bp - 2	; todo unused
push ax			; bp - 4
push dx			; bp - 6
sub   sp, 08h
mov   si, cx

xchg  ax, cx
mov   di, dx
mov   ax, word ptr [di + 4]
cwd   
mov   di, cx  ; bp - 4 value
xchg  ax, cx  ; back up low
mov   ax, word ptr [di + 4]
mov   di, dx  ; back up high

mul   word ptr ds:[_numsectors]
add   ax, cx
adc   dx, di

mov   cx, ax	; cx is preshifted

shr   dx, 1
rcr   ax, 1
shr   dx, 1
rcr   ax, 1
shr   dx, 1
rcr   ax, 1

mov   dx, 1
xchg  di, ax ; di gets post-shifted.
mov   ax, REJECTMATRIX_SEGMENT
mov   es, ax
and   cl, 7
mov   al, byte ptr es:[di]
shl   dx, cl
xor   ah, ah
test  ax, dx
je    not_in_reject_table
xor   al, al
LEAVE_MACRO
pop   di
pop   si
retf  4

not_in_reject_table:
inc   word ptr ds:[_validcount]

; carry cx arg in si from above...
; note: ES as segment is same for either position. all far mobjpos ptrs will be the same segment...
mov   es, si

mov   si, word ptr [bp + 0Ah]

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

; todo: a lot of movsw below

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

mov   ax, word ptr es:[bx]
mov   word ptr ds:[_strace], ax
mov   ax, word ptr es:[bx + 2]
mov   word ptr ds:[_strace+2], ax

mov   ax, word ptr es:[bx + 4]
mov   word ptr ds:[_strace+4], ax
mov   ax, word ptr es:[bx + 6]
mov   word ptr ds:[_strace+6], ax

mov   ax, word ptr es:[si]
mov   word ptr ds:[_cachedt2x], ax
mov   ax, word ptr es:[si + 2]
mov   word ptr ds:[_cachedt2x+2], ax

mov   ax, word ptr es:[si + 4]
mov   word ptr ds:[_cachedt2y], ax
mov   ax, word ptr es:[si + 6]
mov   word ptr ds:[_cachedt2y+2], ax

mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
sub   ax, word ptr es:[bx]
sbb   dx, word ptr es:[bx + 2]
mov   word ptr ds:[_strace+8], ax
mov   word ptr ds:[_strace+0Ah], dx

mov   dx, word ptr es:[si + 4]
mov   ax, word ptr es:[si + 6]
sub   dx, word ptr es:[bx + 4]
sbb   ax, word ptr es:[bx + 6]
mov   word ptr ds:[_strace+0Eh], ax
mov   word ptr ds:[_strace+0Ch], dx

mov   ax, word ptr ds:[_numnodes]
dec   ax
call  P_CrossBSPNode_

LEAVE_MACRO
pop   di
pop   si
retf  4

ENDP
END