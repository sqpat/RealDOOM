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
INCLUDE defs.inc

.386

;GLOBAL FixedMul_:FAR

SEGMENT MATH_TEXT  USE16 PARA PUBLIC 'CODE'

ASSUME cs:MATH_TEXT


PROC FixedMul_ FAR
PUBLIC FixedMul_

; DX:AX  *  CX:BX
;  0  1      2  3

; need to get this out of DX:AX  CX:BX and into
; EAX and EBX (or something)
; todo improve
  sal  ebx, 16
  shrd ebx, ecx, 16

  sal  eax, 16
  shrd eax, edx, 16

  ; actual mult and shrd..
  imul ebx
  ; put results in the expected spots
  ; edx low 16 bits already contains bits 32-48 of result
  ; need to move eax's high 16 bits low.
  shr  eax, 16

ret



ENDP

PROC FixedDiv_ FAR
PUBLIC FixedDiv_

;DX:AX / CX:BX...


push  si
push  di

mov   si, dx ; 	si will store sign bit 
xor   si, cx  ; si now stores signedness via test operator...

; here we abs the numbers before unsigned division algo

or    cx, cx
jge   b_is_positive
neg   cx
neg   bx
sbb   cx, 0


b_is_positive:

or    dx, dx			; sign check
jge   a_is_positive
neg   dx
neg   ax
sbb   dx, 0


a_is_positive:

;  dx:ax  is  labs(dx:ax) now (unshifted)
;  cx:bx  is  labs(cx:bx) now

; labs check


; set up eax
shl  eax, 16
shrd eax, edx, 16

; set up ecx
shl  ebx, 16
shld ecx, ebx, 16

; back up eax
mov edx, eax        

; do labs compare
shr EAX, 14

cmp eax, ecx
jge do_quick_return
mov eax, edx

; do divide. prepare edx:eax properly.
cdq             
shld edx,eax,16
shl  eax,16


div ecx             ; todo optimize this function in general to be idiv with a lot less juggling.

shld edx, eax, 010h


test  si, si

jl do_negative


pop   di
pop   si
ret

do_negative:

neg   dx
neg   ax
sbb   dx, 0


pop   di
pop   si
ret







do_quick_return: 
; return (a^b) < 0 ? MINLONG : MAXLONG;
test  si, si   ; just need to do the high word due to sign?
jl    return_MAXLONG

return_MINLONG:

mov   ax, 0ffffh
mov   dx, 07fffh

exit_and_return_early:



pop   di
pop   si
ret

return_MAXLONG:

mov   dx, 08000h
xor   ax, ax
jmp   exit_and_return_early




ENDP


MATH_TEXT ENDS

END