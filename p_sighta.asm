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

; ax = t1 (near ptr)
; dx = t2 (near ptr)
; bx = t1_pos (far offset)
; cx = t2_pos (far offset)

PROC    P_CheckSight_
PUBLIC  P_CheckSight_

push  si
push  di

push dx			; bp - 2

mov   si, cx    ; si gets t2_pos

; todo clean up this di shuffling
mov   es, ax    ; es holds t1
mov   di, dx    ; di gets t2
mov   ax, word ptr [di + 4]
cwd   

xchg  ax, cx  ; back up low
mov   di, es    ; di gets t1 
mov   ax, word ptr [di + 4]
mov   di, dx  ; back up high	di:cx holds first result

mul   word ptr ds:[_numsectors]
add   ax, cx
adc   dx, di

; generate reject bitmap lookup
mov   cx, ax	; cx is preshifted	
and   cl, 7		; will shift by this amount for bit count

; divide by 8 for 8 bits per byte..
shr   dx, 1
rcr   ax, 1
shr   dx, 1
rcr   ax, 1
shr   dx, 1
rcr   ax, 1

xchg  di, ax 			; di gets post-shifted.

mov   al, 1
shl   al, cl			; dl stores bit for bit test

mov   cx, es			; store t1 again

mov   dx, REJECTMATRIX_SEGMENT
mov   es, dx

test  al, byte ptr es:[di]	; bit test the byte

je    not_in_reject_table
xor   ax, ax				; return 0

pop   dx	; clean out the push earlier...
pop   di
pop   si
retf 

not_in_reject_table:
inc   word ptr ds:[_validcount]


mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
push  si  					; store for now

; todo is lds worth it for these dword reads..
mov   di, cx				; grab t1 again

;    sightzstart = t1_pos->z.w + t1->height.w - (t1->height.w>>2);

mov   cx, word ptr es:[bx + 8]
mov   si, word ptr es:[bx + 0Ah]
mov   ax, word ptr [di + 0Ah]
mov   dx, word ptr [di + 0Ch]
add   cx, ax
adc   si, dx			; si:cx result

sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sub   cx, ax

sbb   si, dx
mov   word ptr ds:[_sightzstart], cx
mov   word ptr ds:[_sightzstart + 2], si

; todo: a lot of movsw below

xchg  ax, si				; ax gets sightzstart+2
pop   si					; recover si
pop   di 					; grab t2 again
push  bx					; store this...
xchg  ax, bx				; bx gets sightzstart+2

;    topslope = (t2_pos->z.w+t2->height.w) - sightzstart;

mov   ax, word ptr es:[si + 8]
mov   dx, word ptr es:[si + 0Ah]
add   ax, word ptr [di + 0Ah]
adc   dx, word ptr [di + 0Ch]	; last di use...


mov   di, bx			; di gets sightzstart+2
mov   bx, dx			
mov   dx, cx			; cx had sightz_start

sub   ax, dx			; subtract sightzstart	
sbb   bx, di			
mov   word ptr ds:[_topslope], ax
mov   word ptr ds:[_topslope+2], bx


mov   ax, word ptr es:[si + 8]
mov   cx, word ptr es:[si + 0Ah]
sub   ax, dx			; subtract sightzstart
sbb   cx, di			
mov   word ptr ds:[_bottomslope], ax
mov   word ptr ds:[_bottomslope+2], cx

pop   bx				; restore bx (t1 pos?)
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


pop   di
pop   si
retf 

ENDP



END