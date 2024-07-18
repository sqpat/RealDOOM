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

EXTRN __I8LS:PROC
EXTRN __I8DQ:PROC
;EXTRN _divllu:PROC
	
INCLUDE defs.inc

GLOBAL FixedMul_:PROC

.CODE


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

push  si

mov   es, ax	; store ax in es
mov   ds, dx    ; store dx in ds
mov   ax, dx	; ax holds dx
CWD				; S0 in DX

AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

; AX still stores DX
MUL  CX         ; DX*CX
add  SI, AX    ; low word result into high word return

mov  AX, DS    ; restore DX from ds
MUL  BX         ; DX*BX
XCHG BX, AX    ; BX will hold low word return. store bx in ax
add  SI, DX    ; add high word to result

mov  DX, ES    ; restore AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI

mov  CX, SS   ; restore DS
mov  DS, CX

pop   si
ret



ENDP




PROC FixedMul2424_ FAR
PUBLIC FixedMul2424_

; we are being passed two numbers that should be shifted right 8 bits before multiplication
; this should lead to a couple fewer 16-bit multiplications if we do things right.
; CWD becomes a little complicated

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

push  si

; DX:AX  is   43 21
; we want:    S4 32  (s = sign bit)

MOV   al, dh ; 43 24
MOV   dh, ah ; 23 24
CBW          ; 23 S4
XCHG AX, DX  ; S4 23
XCHG AL, AH  ; S4 32

mov   es, ax	; store ax in es
mov   ds, dx    ; store dx in ds

mov  al, ch     
CBW
mov  bl, bh
mov  bh, cl
mov  cx, AX

; registers have been prepped. 20-25ish cycles. This is way faster than four 8 bit shifts...

; TODO: actually make the mult faster

mov   ax, ds	; ax holds dx now
CWD				; S0 in DX

AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

; AX still stores DX
MUL  CX         ; DX*CX
add  SI, AX    ; low word result into high word return

mov  AX, DS    ; restore DX from ds
MUL  BX         ; DX*BX
XCHG BX, AX    ; BX will hold low word return. store bx in ax
add  SI, DX    ; add high word to result

mov  DX, ES    ; restore AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI

mov  CX, SS   ; restore DS
mov  DS, CX

pop   si
ret



ENDP


PROC FixedMul2432_ FAR
PUBLIC FixedMul2432_

; we are being passed two numbers that should be shifted right 8 bits before multiplication
; this should lead to a couple fewer 16-bit multiplications if we do things right.
; CWD becomes a little complicated

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

push  si

; DX:AX  is   43 21
; we want:    S4 32  (s = sign bit)

MOV   al, dh ; 43 24
MOV   dh, ah ; 23 24
CBW          ; 23 S4
XCHG AX, DX  ; S4 23
XCHG AL, AH  ; S4 32

mov   es, ax	; store ax in es
mov   ds, dx    ; store dx in ds



; registers have been prepped. 20-25ish cycles. This is way faster than four 8 bit shifts...

; TODO: actually make the mult faster

mov   ax, dx	; ax holds dx now
CWD				; S0 in DX

AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

; AX still stores DX
MUL  CX         ; DX*CX
add  SI, AX    ; low word result into high word return

mov  AX, DS    ; restore DX from ds
MUL  BX         ; DX*BX
XCHG BX, AX    ; BX will hold low word return. store bx in ax
add  SI, DX    ; add high word to result

mov  DX, ES    ; restore AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI

mov  CX, SS   ; restore DS
mov  DS, CX

pop   si
ret



ENDP






PROC FixedMul1632_
PUBLIC FixedMul1632_

; AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX

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




push  si

CWD				; DX/S0

mov   es, ax    ; store ax in es
AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

CWD 

AND  DX, CX    ; DX*CX
NEG  DX
add  SI, DX    ; low word result into high word return

CWD

; NEED TO ALSO EXTEND SIGN MULTIPLY TO HIGH WORD. if sign is FFFF then result is BX - 1. Otherwise 0.
; UNLESS BX is 0. then its also 0!

; the algorithm for high sign bit mult:   IF FFFF result is (BX - 1). If 0000 then 0.
MOV  AX, BX    ; create BX copy
SUB  AX, 1     ; DEC DOES NOT AFFECT CARRY FLAG! BOO! 3 byte instruction, can we improve?
ADC  AX, 0     ; if bx is 0 then restore to 0 after the dex  

AND  AX, DX    ; 0 or BX - 1
ADD  SI, AX    ; add DX * BX high word. 


AND  DX, BX    ; DX * BX low bits
NEG  DX
XCHG BX, DX    ; BX will hold low word return. store BX in DX for last mul 

mov  AX, ES    ; grab AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI
 

pop   si
ret



ENDP





PROC FixedMulTrigOld_
PUBLIC FixedMulTrigOld_

; DX:AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX
; The difference between FixedMulTrig and FixedMul1632:
; fine sine/cosine lookup tables are -65535 to 65535, so 17 bits. 
; technically, this resembles 16 * 32 with sign extend, except we cannot use CWD to generate the high 16 bits.
; So those sign bits which contain bit 17, sign extended must be stored somewhere cannot be regenerated via CWD
; we basically take the above function and shove sign bits in DS for storage and regenerate DS from SS upon return
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



push  si


mov   es, ax    ; store ax in es
mov   DS, DX    ; store sign bits in DS
AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

mov   DX, DS    ; restore sign bits from DS

AND  DX, CX    ; DX*CX
NEG  DX
add  SI, DX    ; low word result into high word return

mov   DX, DS    ; restore sign bits from DS

; NEED TO ALSO EXTEND SIGN MULTIPLY TO HIGH WORD. if sign is FFFF then result is BX - 1. Otherwise 0.
; UNLESS BX is 0. then its also 0!

; the algorithm for high sign bit mult:   IF FFFF result is (BX - 1). If 0000 then 0.
MOV  AX, BX    ; create BX copy
SUB  AX, 1     ; DEC DOES NOT AFFECT CARRY FLAG! BOO! 3 byte instruction, can we improve?
ADC  AX, 0     ; if bx is 0 then restore to 0 after the dex  

AND  AX, DX    ; 0 or BX - 1
ADD  SI, AX    ; add DX * BX high word. 


AND  DX, BX    ; DX * BX low bits
NEG  DX
XCHG BX, DX    ; BX will hold low word return. store BX in DX for last mul 

mov  AX, ES    ; grab AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX

CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI
 
MOV CX, SS
MOV DS, CX    ; put DS back from SS

pop   si
ret



ENDP



PROC FixedMulTrig_
PUBLIC FixedMulTrig_

; DX:AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX
; The difference between FixedMulTrig and FixedMul1632:
; fine sine/cosine lookup tables are -65535 to 65535, so 17 bits. 
; technically, this resembles 16 * 32 with sign extend, except we cannot use CWD to generate the high 16 bits.
; So those sign bits which contain bit 17, sign extended must be stored somewhere cannot be regenerated via CWD
; we basically take the above function and shove sign bits in DS for storage and regenerate DS from SS upon return
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

; AX is param 1 (segment)
; DX is param 2 (fineangle or lookup)
; CX:BX is value 2




push  si

; lookup the fine angle

sal dx, 1
sal dx, 1   ; DWORD lookup index
mov si, dx
mov es, ax  ; put segment in ES
mov ax, es:[si]
mov dx, es:[si+2]


mov   es, ax    ; store ax in es
mov   DS, DX    ; store sign bits in DS
AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

mov   DX, DS    ; restore sign bits from DS

AND  DX, CX    ; DX*CX
NEG  DX
add  SI, DX    ; low word result into high word return

mov   DX, DS    ; restore sign bits from DS

; NEED TO ALSO EXTEND SIGN MULTIPLY TO HIGH WORD. if sign is FFFF then result is BX - 1. Otherwise 0.
; UNLESS BX is 0. then its also 0!

; the algorithm for high sign bit mult:   IF FFFF result is (BX - 1). If 0000 then 0.
MOV  AX, BX    ; create BX copy
SUB  AX, 1     ; DEC DOES NOT AFFECT CARRY FLAG! BOO! 3 byte instruction, can we improve?
ADC  AX, 0     ; if bx is 0 then restore to 0 after the dex  

AND  AX, DX    ; 0 or BX - 1
ADD  SI, AX    ; add DX * BX high word. 


AND  DX, BX    ; DX * BX low bits
NEG  DX
XCHG BX, DX    ; BX will hold low word return. store BX in DX for last mul 

mov  AX, ES    ; grab AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX

CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI
 
MOV CX, SS
MOV DS, CX    ; put DS back from SS

pop   si
ret



ENDP





PROC FixedMulBig1632_
PUBLIC FixedMulBig1632_

; AX  *  CX:BX
;  0  1   2  3

; AX:00 * CX:BX

; BUT we are going to "alias" AX to DX and 00 to AX for the function to keep things consistent with above

; DX:00 * CX:BX

;
; 
;BYTE
; RETURN VALUE
;                3       2       1		0
;                DONTUSE USE     USE    DONTUSE


;                               00BXhi	 00BXlo
;                       00CXhi  00CXlo
;               00S1hi  00S1lo

;               S0BXhi  S0BXlo                          
;                       DXBXhi  DXBXlo          
;               DXCXhi  DXCXlo  
;                       
;                               
;                       
;       



; need to get the sign-extends for DX and CX





CWD				; DX/S0
AND   DX, BX	; S0*BX
NEG   DX
XCHG  CX, DX	; CX into DX, CX stores hi result

MOV   ES, AX    ; store DX into ES

MUL   DX        ; CX * DX
ADD   CX, AX    ; low word result into high word return

MOV  AX, ES    ; grab DX again
MUL  BX        ; BX * DX
ADD  DX, CX    ; add high bits back
 

ret



ENDP

; first param is unsigned so DX and sign can be skipped
PROC FixedMul16u32_
PUBLIC FixedMul16u32_

; AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX

;
; 
;BYTE
; RETURN VALUE
;                3       2       1		0
;                DONTUSE USE     USE    DONTUSE


;                               AXBXhi	 AXBXlo
;                       AXCXhi  AXCXlo
;               AXS1hi  AXS1lo
;       



; need to get the sign-extends for DX and CX


XCHG BX, AX    ; AX stored in BX
MUL  BX        ; AX * BX
MOV  AX, CX    ; CX to AX
MOV  CX, DX    ; CX stores low word
CWD            ; S1 in DX
AND  DX, BX    ; S1 * AX
NEG  DX        ; 
XCHG DX, BX    ; AX into DX, high word into BX
MUL  DX        ; AX*CX
ADD AX, CX     ; add low word
ADC DX, BX     ; add high word



ret



ENDP



; unused??
; both params unsigned. drop all sign extensions..
PROC FixedMul16u32u_
PUBLIC FixedMul16u32u_

; AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX

;
; 
;BYTE
; RETURN VALUE
;                3       2       1		0
;                DONTUSE USE     USE    DONTUSE


;                               AXBXhi	 AXBXlo
;                       AXCXhi  AXCXlo
;       



; need to get the sign-extends for DX and CX


XCHG BX, AX    ; AX stored in BX
MUL  BX        ; AX * BX
MOV AX, BX     ; AX to AX again. DX has high product, low word result
MOV BX, DX     ; high word to bx (as low word result)
MUL  CX        ; AX * CX
ADD AX, BX     ; add low word
ADC DX, 0      ; add carry bit


ret

ENDP


; unused??
; both params unsigned. drop all sign extensions.. and dont shift by 16 like fixed algos!
PROC FastMul16u32u_
PUBLIC FastMul16u32u_

; AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX

;
; 
;BYTE
; RETURN VALUE
;                3       2       1		0
;                DONTUSE USE     USE    DONTUSE


;                               AXBXhi	 AXBXlo
;                       AXCXhi  AXCXlo
;       



; need to get the sign-extends for DX and CX


XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 


ret

ENDP



;FIXEDDIV
; DX:AX / CX:BX

PROC div48_32_
PUBLIC div48_32_


;
;
;
;
; bp - 1ah   dx copy
;
; 
; bp - 20h   ax copy
; bp - 22h   cx copy
; bp - 24h   bx copy

push  si
push  bp
mov   bp, sp
sub   sp, 022h
push  ax
mov   si, bx
mov   di, cx
mov   word ptr [bp - 01ah], dx
mov   word ptr [bp - 020h], ax

; make copies of cx:bx
push cx
push bx


; COUNT LEADING ZEROES

push si
mov  si, bx
;mov  cx, dx
mov  dx, 08000h
xor  ax, ax
xor  bx, bx
test ch, 080h
jne  finished_counting_zeroes
count_next_binary_digit:
cmp  bx, 01fh
jge  finished_counting_zeroes
shr  dx, 1
rcr  ax, 1
inc  bx
test cx, dx
jne  finished_counting_zeroes
test si, ax
je   count_next_binary_digit
finished_counting_zeroes:
mov  ax, bx
pop  si

; END COUNT LEADING ZEROES

pop  bx
pop  cx


; have zeroes in ax
; begin doing all the shifts

mov   cx, ax
jcxz  label_0
label1:
shl   si, 1
rcl   di, 1
loop  label1
label_0:
mov   word ptr [bp - 018h], 0
mov   cx, ax
mov   word ptr [bp - 022h], 0
jcxz  label_2
label_3:
shl   word ptr [bp - 01ah], 1
rcl   word ptr [bp - 018h], 1
loop  label_3
label_2:
mov   word ptr [bp - 01eh], 0
mov   cx, ax
mov   bx, ax
neg   cx
mov   ax, word ptr [bp - 024h]
xor   ch, ch
mov   word ptr [bp - 01ch], ax
and   cl, 01fh
mov   ax, bx
jcxz  label_4
label_5:
shr   word ptr [bp - 01ch], 1
rcr   word ptr [bp - 01eh], 1
loop  label_5
label_4:
CWD   
mov   word ptr [bp - 4], di
mov   cx, ax
mov   ax, dx
mov   word ptr [bp - 016h], cx
neg   ax
neg   word ptr [bp - 016h]
sbb   ax, 0
mov   cx, bx
sar   ax, 0fh
mov   bx, di
CWD   
jcxz  label7
label8:
shl   word ptr [bp - 022h], 1
rcl   word ptr [bp - 020h], 1
loop  label8
label7:
and   dx, word ptr [bp - 01ch]
and   ax, word ptr [bp - 01eh]
or    word ptr [bp - 01ah], ax
mov   ax, word ptr [bp - 020h]
or    word ptr [bp - 018h], dx
mov   word ptr [bp - 014h], ax
mov   ax, word ptr [bp - 022h]
mov   dx, word ptr [bp - 018h]
mov   word ptr [bp - 8], ax
mov   ax, word ptr [bp - 01ah]
mov   word ptr [bp - 0ah], si
div   bx
mov   bx, dx
mov   dx, si
mov   word ptr [bp - 6], ax
mul   dx
mov   cx, ax
mov   ax, bx
cmp   dx, bx
ja    label9
jne   label10
cmp   cx, word ptr [bp - 020h]
jbe   label10
label9:
sub   cx, word ptr [bp - 020h]
sbb   dx, ax
cmp   dx, di
ja    label25
je    label26
label11:
jmp   label12
label26:
cmp   cx, si
jbe   label11
label25:
mov   ax, 2
label16:
sub   word ptr [bp - 6], ax
label10:
mov   ax, word ptr [bp - 6]
mov   bx, si
mov   word ptr [bp - 0ch], ax
mov   ax, word ptr [bp - 01ah]
mov   cx, di
mov   word ptr [bp - 2], ax
mov   ax, word ptr [bp - 6]

;inlined FastMul16u32u_

XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

mov   bx, word ptr [bp - 014h]
sub   bx, ax
sbb   word ptr [bp - 2], dx
mov   dx, word ptr [bp - 2]
mov   ax, bx
cmp   dx, word ptr [bp - 4]
jb    label13
xor   dx, dx
sub   ax, word ptr [bp - 4]
sbb   word ptr [bp - 2], dx
mov   bx, word ptr [bp - 2]
cmp   bx, word ptr [bp - 4]
jae   label14
mov   bx, word ptr [bp - 4]
mov   dx, word ptr [bp - 2]
div   bx
mov   bx, ax
mov   cx, dx
mov   dx, word ptr [bp - 0ah]
mov   word ptr [bp - 0eh], ax
mul   dx
mov   word ptr [bp - 012h], ax
mov   ax, cx
cmp   dx, cx
ja    label17
jne   label18
mov   cx, word ptr [bp - 012h]
cmp   cx, word ptr [bp - 8]
jbe   label18
label17:
mov   cx, word ptr [bp - 012h]
sub   cx, word ptr [bp - 8]
sbb   dx, ax
cmp   dx, di
ja    label19
jne   label18
cmp   si, cx
jae   label18
label19:
dec   bx
mov   word ptr [bp - 0eh], bx
label18:
mov   ax, word ptr [bp - 0eh]
mov   dx, word ptr [bp - 0ch]
mov   sp, bp
pop   bp
pop   si
ret  
label12:
mov   ax, 1
jmp   label16
label14:
jmp   label15
label13:
mov   bx, word ptr [bp - 4]
div   bx
mov   bx, dx
mov   dx, word ptr [bp - 0ah]
mov   cx, ax
mul   dx
mov   word ptr [bp - 010h], ax
mov   ax, bx
cmp   dx, bx
ja    label20
jne   label21
mov   bx, word ptr [bp - 010h]
cmp   bx, word ptr [bp - 8]
jbe   label21
label20:
mov   bx, word ptr [bp - 010h]
sub   bx, word ptr [bp - 8]
sbb   dx, ax
cmp   dx, di
ja    label23
jne   label22
cmp   si, bx
jae   label22
label23:
mov   ax, 2
label24:
sub   cx, ax
label21:
mov   dx, word ptr [bp - 0ch]
mov   ax, cx
mov   sp, bp
pop   bp
pop   si
ret  
label22:
mov   ax, 1
jmp   label24
label15:
sub   ax, word ptr [bp - 4]
sbb   word ptr [bp - 2], dx
mov   bx, word ptr [bp - 4]
mov   dx, word ptr [bp - 2]
div   bx
mov   dx, word ptr [bp - 0ah]
mov   bx, ax
mul   dx
mov   dx, word ptr [bp - 6]
mov   ax, bx
mov   sp, bp
pop   bp
pop   si
ret 

endp









PROC FixedDiv_
PUBLIC FixedDiv_


;fixed_t32 FixedDivinner(fixed_t32	a, fixed_t32 b int8_t* file, int32_t line)
; fixed_t32 FixedDiv(fixed_t32	a, fixed_t32	b) {
; 	if ((labs(a) >> 14) >= labs(b))
; 		return (a^b) < 0 ? MINLONG : MAXLONG;
; 	return FixedDiv2(a, b);
; }

;    abs(x) = (x XOR y) - y
;      where y = x's sign bit extended.


; DX:AX   /   CX:BX
 
push  si
push  di
push  bp
mov   bp, sp


mov   si, dx ; 	si will store sign bit 
xor   si, cx  ; si now stores signedness via test operator...

; how to test for sign:
; test  si, si   ; 
; jl    positive_case


; here we abs the numbers before unsigned division algo

or    cx, cx
jge   b_is_positive
neg   bx
adc   cx, 0
neg   cx


b_is_positive:

or    dx, dx			; sign check
jge   a_is_positive
neg   ax
adc   dx, 0
neg   dx


a_is_positive:

;  dx:ax  is  labs(dx:ax) now (unshifted)
;  cx:bx  is  labs(cx:bx) now
test cx, 0FFFCh


je continue_bounds_test

; main division algo

do_full_divide:


call div48_32_

; set negative if need be...

test  si, si

jl do_negative

mov   sp, bp
pop   bp

pop   di
pop   si
ret

do_negative:

neg   ax
adc   dx, 0
neg   dx

mov   sp, bp
pop   bp

pop   di
pop   si
ret

continue_bounds_test:




; if high 2 bits of dh arent present at all, and any bits of cx are present
; then we can quit out quickly.


test dh, 0C0h     ; dx AND 0xC000
jne do_shift_and_full_compare
test cx, cx
jne do_full_divide  ; dx >> 14 is zero, cx is nonzero.


do_shift_and_full_compare:

; store backup dx:ax in ds:es
mov ds, dx
mov es, ax

rol dx, 1
rol ax, 1
rol dx, 1
rol ax, 1

mov di, dx
and ax, 03h
and di, 0FFFCh  ; cx, 0FFFCh
or  ax, di
and dx, 03h


; do comparison  di:bx vs dx:ax
; 	if ((labs(a) >> 14) >= labs(b))

cmp   dx, cx
jg    do_quick_return
jne   restore_reg_then_do_full_divide ; below
cmp   ax, bx
jb    restore_reg_then_do_full_divide

do_quick_return: 
; return (a^b) < 0 ? MINLONG : MAXLONG;
test  si, si   ; just need to do the high word due to sign?
jl    return_MAXLONG

return_MINLONG:
mov   ax, ss
mov   ds, ax

mov   ax, 0ffffh
mov   dx, 07fffh

exit_and_return_early:

; restore ds...

mov   sp, bp

pop   bp
pop   di
pop   si
ret

return_MAXLONG:
mov   ax, ss
mov   ds, ax

mov   dx, 08000h
xor   ax, ax
jmp   exit_and_return_early

restore_reg_then_do_full_divide:

; restore dx
mov dx, ds

; restore ds
mov ax, ss
mov ds, ax 

; restore ax
mov ax, es
jmp do_full_divide

ENDP



; general idea: (?)
; div the high numbers
; div and sum the mid numbers + remainder of high
; adc into high number
; div the low number + remainder of mid
; adc into the mid and high number
; return high:mid
; so: dx/cx -> high
;   rem dx/cx + dx/bx + ax/cx -> mid, adc into high
;     rem of above + ax/bx, adc into mid into high




END