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
	.286


INCLUDE defs.inc


.DATA

EXTRN	_skipdirectdraws:BYTE
EXTRN   _screen_segments:WORD

.CODE
EXTRN	V_MarkRect_:PROC


PROC V_DrawPatch_ FAR
PUBLIC V_DrawPatch_

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
push  ax
mov   byte ptr [bp - 2], bl   ; do push?
cmp   byte ptr [_skipdirectdraws], 0
je    jump1
jump0:
jmp   jumpexit
jump1:
les   bx, dword ptr [bp + 0Ch]
sub   dl, byte ptr es:[bx + 6]
xor   dh, dh
imul   si, dx, SCREENWIDTH
mov   ax, word ptr es:[bx + 4]
sub   word ptr [bp - 012h], ax
add   si, word ptr [bp - 012h]
cmp   byte ptr [bp - 2], 0
jne   jump3
jmp   jump10
jump3:
mov   al, byte ptr [bp - 2]
cbw  
mov   bx, ax
add   bx, ax
mov   word ptr [bp - 0Ah], 0
mov   ax, word ptr [bx + _screen_segments]
les   bx, dword ptr [bp + 0Ch]
mov   word ptr [bp - 8], ax
mov   ax, word ptr es:[bx]
mov   cx, si
mov   word ptr [bp - 0Eh], ax
test  ax, ax
jle   jump0
mov   word ptr [bp - 0Ch], bx
mov   word ptr [bp - 010h], es
jump4:
mov   es, word ptr [bp - 010h]
mov   bx, word ptr [bp - 0Ch]
mov   di, word ptr [bp + 0Ch]
mov   dx, word ptr [bp + 0Eh]
add   di, word ptr es:[bx + 8]
mov   es, dx
cmp   byte ptr es:[di], 0FFh
jne   jump5
jmp   jump9
jump5:
mov   es, dx
mov   al, byte ptr es:[di]
xor   ah, ah
imul   ax, ax, SCREENWIDTH
mov   bx, word ptr [bp - 8]
mov   word ptr [bp - 4], bx
mov   bx, cx
add   bx, ax
mov   al, byte ptr es:[di + 1]
xor   ah, ah
mov   word ptr [bp - 6], dx
sub   ax, 4
lea   si, [di + 3]
test  ax, ax
jl    jump8
jump6:
mov   es, word ptr [bp - 6]
mov   dl, byte ptr es:[si]
mov   dh, byte ptr es:[si + 1]
mov   es, word ptr [bp - 4]
mov   byte ptr es:[bx], dl
mov   byte ptr es:[bx + SCREENWIDTH], dh
mov   es, word ptr [bp - 6]
add   bx, 2*SCREENWIDTH
mov   dl, byte ptr es:[si + 2]
add   bx, 2*SCREENWIDTH
mov   dh, byte ptr es:[si + 3]
mov   es, word ptr [bp - 4]
add   si, 4
mov   byte ptr es:[bx - (2*SCREENWIDTH)], dl
sub   ax, 4
mov   byte ptr es:[bx - SCREENWIDTH], dh
test  ax, ax
jge   jump6
jump8:
add   ax, 4
je    jump12
jump11:
mov   es, word ptr [bp - 6]
add   bx, SCREENWIDTH
mov   dl, byte ptr es:[si]
mov   es, word ptr [bp - 4]
inc   si
mov   byte ptr es:[bx - SCREENWIDTH], dl
dec   ax
jne   jump11
jump12:
mov   dx, word ptr [bp - 6]
lea   di, [si + 1]
mov   es, dx
cmp   byte ptr es:[di], 0FFh
je    jump9
jmp   jump5
jump9:
inc   word ptr [bp - 012h]
inc   word ptr [bp - 0Ah]
add   word ptr [bp - 0Ch], 4
mov   ax, word ptr [bp - 0Ah]
inc   cx
cmp   ax, word ptr [bp - 0Eh]
jge   jumpexit
jmp   jump4
jumpexit:
leave 
pop   di
pop   si
pop   cx
retf  4
jump10:
mov   ax, word ptr [bp - 012h]
mov   cx, word ptr es:[bx + 2]
mov   bx, word ptr es:[bx]
call  V_MarkRect_
jmp   jump3

ENDP

END