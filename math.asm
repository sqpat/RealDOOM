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


ENDIF



.CODE

IF COMPISA LE COMPILE_286



PROC   FixedMul_ NEAR
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

; thanks zero318 from discord for improved algorithm  

MOV  ES, SI
MOV  SI, DX
PUSH AX
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
ADD  AX, 01000h
ADC  SI, DX
XCHG AX, CX
CWD
POP  BX
AND  DX, BX
SUB  SI, DX
MUL  BX
ADD  AX, CX
ADC  DX, SI
MOV  SI, ES

ret



ENDP

ELSE

PROC   FixedMul_ NEAR
PUBLIC FixedMul_

; DX:AX  *  CX:BX
;  0  1      2  3

; thanks zero318 for xchg improvement ideas
  
  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul  ecx
  shr  eax, 16


ret


ENDIF



PROC   FastDiv32u16u_   NEAR
PUBLIC FastDiv32u16u_

;DX:AX / BX (?)

cmp dx, bx
jge two_part_divide
one_part_divide:
div bx
xor dx, dx
ret

two_part_divide:
mov  es, ax
mov  ax, dx
xor  dx, dx
div  bx     ; div high
push ax
mov  ax, es
; DX:AX contains remainder + ax...
div  bx
pop  dx ; q0 already in ax
ret

ENDP

PROC   FastDiv3216u_    NEAR
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
mov   es, ax
mov   ax, dx
xor   dx, dx
div   bx     ; div high
push  ax
mov ax, es
; DX:AX contains remainder + ax...
div bx
pop   dx
            ; q0 already in ax
neg   ax
adc   dx, 0
neg   dx


ret




ENDP



END