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

INSTRUCTION_SET_MACRO

IF COMPISA LE COMPILE_286
GLOBAL FixedMul_:FAR
GLOBAL FixedDiv_:FAR
ENDIF



.CODE

IF COMPISA LE COMPILE_286



PROC FixedMul_ FAR
PUBLIC FixedMul_

; DX:AX  *  CX:BX
;  0  1      2  3

; with sign extend for byte 3:
; S0:DX:AX    *   S1:CX:BX
; S0 = DX sign extend
; S1 = CX sign extend

;
; 
;BYTE
; RETURN VALUE
;                3       2       1		0
;                DONTUSE USE     USE    DONTUSE


;                               AXBXhi	 AXBXlo
;                       DXBXhi  DXBXlo          
;               S0BXhi  S0BXlo                          
;
;                       AXCXhi  AXCXlo
;               DXCXhi  DXCXlo  
;                       
;               AXS1hi  AXS1lo
;                               
;                       
;       




; need to get the sign-extends for DX and CX

; thanks zero318 from discord for improved algorithm  

MOV  ES, SI
MOV  SI, DX
MOV  word ptr cs:[_selfmodify_restore_original_ax+1], AX
MUL  BX
MOV  word ptr cs:[_selfmodify_restore_dx+1], DX
MOV  AX, SI
MUL  CX
XCHG AX, SI
CWD
AND  DX, BX
SUB  SI, DX
MUL  BX
_selfmodify_restore_dx:
mov  BX, 01000h
ADD  BX, AX
ADC  SI, DX
mov  AX, CX
CWD
_selfmodify_restore_original_ax:
mov CX, 01000h
AND DX, CX
SUB SI, DX
MUL CX
ADD AX, BX
ADC DX, SI
MOV SI, ES


ret



ENDP



ENDIF



PROC FastDiv32u16u_   FAR
PUBLIC FastDiv32u16u_

;DX:AX / BX (?)

cmp dx, bx
jge two_part_divide
one_part_divide:
div bx
xor dx, dx
ret

two_part_divide:
mov es, ax
mov ax, dx
xor dx, dx
div bx     ; div high
mov ds, ax ; store q1
mov ax, es
; DX:AX contains remainder + ax...
div bx
mov dx, ds  ; retrieve q1
            ; q0 already in ax
mov bx, ss
mov ds, bx  ; restored ds
retf




ENDP

PROC FastDiv3216u_    FAR
PUBLIC FastDiv3216u_

;DX:AX / BX (?)

test dx, dx
js   handle_negative_3216

cmp dx, bx
jge two_part_divide
div bx
xor dx, dx
ret

handle_negative_3216:

neg ax
adc dx, 0
neg dx


cmp dx, bx
jge two_part_divide_3216
one_part_divide_3216:
div bx
xor dx, dx

neg ax
adc dx, 0
neg dx

ret
two_part_divide_3216:
mov es, ax
mov ax, dx
xor dx, dx
div bx     ; div high
mov ds, ax ; store q1
mov ax, es
; DX:AX contains remainder + ax...
div bx
mov dx, ds  ; retrieve q1
            ; q0 already in ax
neg ax
adc dx, 0
neg dx


mov bx, ss
mov ds, bx  ; restored ds
retf




ENDP



END