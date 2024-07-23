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
    .286
	.MODEL  medium

EXTRN _tantoangle:DWORD
EXTRN _viewx:DWORD
EXTRN _viewy:DWORD
EXTRN FastDiv3232_shift_3_8_:PROC

INCLUDE defs.inc

.CODE

;R_PointToAngle_

PROC R_PointToAngle_
PUBLIC R_PointToAngle_

push  si
push  di
mov   di, ax
mov   si, dx
mov   ax, bx
mov   dx, cx
sub   di, word ptr [_viewx]
sbb   si, word ptr [_viewx+2]
mov   bx, si
sub   ax, word ptr [_viewy]
sbb   dx, word ptr [_viewy+2]
or    bx, di
jne   label_1
mov   bx, dx
or    bx, ax
je    label_2
label_1:
test  si, si
jg    label_1_1
jne   label_3
label_1_1:
test  dx, dx
jg    label_1_2
jne   label_4
label_1_2:
cmp   si, dx
jg    label_1_3
jne   label_5
cmp   di, ax
jbe   label_5
label_1_3:
test  si, si
jl    label_1_4
jne   label_2_1
cmp   di, 0200h
jae   label_2_1
label_1_4:
mov   dx, 02000h
xor   ax, ax
pop   di
pop   si
retf  
label_2:
xor   ax, ax
xor   dx, dx
pop   di
pop   si
retf  
label_2_1:
mov   bx, di
mov   cx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_1_4
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  
label_3:
jmp   label_6
label_4:
jmp   label_7
label_5:
test  dx, dx
jl    label_5_2
jne   label_5_1
cmp   ax, 0200h
jae   label_5_1
label_5_2:
mov   ax, 0ffffh
mov   dx, 01fffh
pop   di
pop   si
retf  
label_5_1:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_5_2
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[si]
mov   dx, 03fffh
sbb   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  
label_7:
neg   dx
neg   ax
sbb   dx, 0
cmp   si, dx
jg    label_7_1
jne   label_8
cmp   di, ax
jbe   label_8
label_7_1:
test  si, si
jl    label_7_2
jne   label_7_3
cmp   di, 0200h
jae   label_7_3
label_7_2:
mov   dx, 0e000h
xor   ax, ax
pop   di
pop   si
retf  
label_7_3:
mov   cx, si
mov   bx, di
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_7_2
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   dx, word ptr es:[si + 2]
mov   ax, word ptr es:[si]
neg   dx
neg   ax
sbb   dx, 0
pop   di
pop   si
retf  
label_8:
test  dx, dx
jl    label_8_1
jne   label_8_2
cmp   ax, 0200h
jae   label_8_2
label_8_1:
mov   dx, 0e000h
xor   ax, ax
pop   di
pop   si
retf  
label_8_2:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_8_1
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
add   ax, 0
mov   dx, word ptr es:[si + 2]
adc   dx, 0c000h
pop   di
pop   si
retf  
label_6:
neg   si
neg   di
sbb   si, 0
test  dx, dx
jg    label_6_1
jne   label_6_12
label_6_1:
cmp   si, dx
jg    label_6_2
jne   label_6_4
cmp   di, ax
jbe   label_6_4
label_6_2:
test  si, si
jl    label_6_3
jne   label_6_5
cmp   di, 0200h
jae   label_6_5
label_6_3:
mov   ax, 0ffffh
mov   dx, 05fffh
pop   di
pop   si
retf  
label_6_5:
mov   bx, di
mov   cx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_6_3
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[si]
mov   dx, 07fffh
sbb   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  
label_6_4:
test  dx, dx
jl    label_6_6
jne   label_6_51
cmp   ax, 0200h
jae   label_6_51
label_6_6:
mov   dx, 06000h
xor   ax, ax
pop   di
pop   si
retf  
label_6_12:
jmp   label_6_7
label_6_51:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_6_6
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
add   ax, 0
mov   dx, word ptr es:[si + 2]
adc   dx, 04000h
pop   di
pop   si
retf  
label_6_7:
neg   dx
neg   ax
sbb   dx, 0
cmp   si, dx
jg    label_6_8
jne   label_7_0
cmp   di, ax
jbe   label_7_0
label_6_8:
test  si, si
jl    label_6_10
jne   label_6_9
cmp   di, 0200h
jae   label_6_9
label_6_10:
mov   dx, 0a000h
xor   ax, ax
pop   di
pop   si
retf  
label_6_9:
mov   bx, di
mov   cx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_6_10
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
add   ax, 0
mov   dx, word ptr es:[si + 2]
adc   dx, 08000h
pop   di
pop   si
retf  
label_7_0:
test  dx, dx
jl    label_18_1
jne   label_18_2
cmp   ax, 0200h
jae   label_18_2
label_18_1:
mov   ax, 0ffffh
mov   dx, 09fffh
pop   di
pop   si
retf  
label_18_2:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   label_18_1
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[si]
mov   dx, 0bfffh
sbb   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  
endp

END
