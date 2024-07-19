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


; bp - 2     copy of numhi.low?
; bp - 4      unused
; bp - 6      qhat of result 1. not always q1! depends on 
; bp - 8      unused
; bp - 0Ah    unused
; bp - 0Ch    unused
; bp - 0Eh    unused
; bp - 010h   unused
; bp - 012h   unused
; bp - 014h   unused. was dupe of 020h, which was numhi.hu.fracbits ?
; bp - 016h   unused
; bp - 018h   overflow bits from dx shift   (numhi.high)
; bp - 01ah   shifted dx  					(numhi.low)
; bp - 01ch	  ax shifted right
; bp - 01eh   ax shifted right overflow 
; bp - 020h   shifted ax  					(numlo)
; bp - 022h   overflow bits from ax shift   (numlo)

; di:si get shifted cx:bx

push  si
push  bp
mov   bp, sp
sub   sp, 022h
mov   es, bx
mov   di, cx
mov   word ptr [bp - 01ah], dx
mov   word ptr [bp - 020h], ax
mov   word ptr [bp - 01Ch], ax  ; initialize this now i guess...

; make copies of cx:bx


; COUNT LEADING ZEROES

mov  si, bx
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

; END COUNT LEADING ZEROES

mov  si, es



done_counting_leading_zeroes:

; have zeroes in ax
; begin doing all the shifts

; do shifts. ax holds shift count.

;    den.wu <<= shift;
; di:si holds den (which was cx:bx)


mov   cx, ax					; count in cx...
jcxz  done_with_shift_denominator
shift_denominator:
shl   si, 1
rcl   di, 1
loop  shift_denominator
done_with_shift_denominator:

;    numhi.wu <<= shift;


mov   word ptr [bp - 018h], 0
mov   cx, ax					; count in cx...
mov   word ptr [bp - 022h], 0
jcxz  done_with_shift_b
shift_param_b:
shl   word ptr [bp - 01ah], 1
rcl   word ptr [bp - 018h], 1
loop  shift_param_b
done_with_shift_b:


;    numhi.wu |= (numlo.wu >> (-shift & 31)) & (-(int32_t)shift >> 31);

mov   word ptr [bp - 01eh], 0
mov   cx, ax
mov   bx, ax
neg   cx
xor   ch, ch

and   cl, 01fh
mov   ax, bx
jcxz  done_with_shift_c
shift_param_c:					; shift RIGHT. i think for the ORed stuff.
shr   word ptr [bp - 01ch], 1
rcr   word ptr [bp - 01eh], 1
loop  shift_param_c
done_with_shift_c:

;    numlo.wu <<= shift;

CWD   

mov   cx, ax
mov   ax, dx
neg   ax
neg   cx
sbb   ax, 0

mov   cx, bx  ; move shift count back again
sar   ax, 0fh

CWD   



jcxz  done_with_shift_d
shift_param_d:
shl   word ptr [bp - 022h], 1
rcl   word ptr [bp - 020h], 1
loop  shift_param_d
done_with_shift_d:

; begin actual first division. create params from shifted ones

and   dx, word ptr [bp - 01ch]
and   ax, word ptr [bp - 01eh]
or    word ptr [bp - 01ah], ax

or    word ptr [bp - 018h], dx

mov   dx, word ptr [bp - 018h]

mov   ax, word ptr [bp - 01ah]


;    num1 = (uint16_t)(numlo.hu.intbits);
;    num0 = (uint16_t)(numlo.hu.fracbits);
;    den1 = (uint16_t)(den.hu.intbits);
;    den0 = (uint16_t)(den.hu.fracbits);

;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu
; bx =  den1

; bx now contains shifted high denominator for division.

div   di

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   bx, dx					; bx stores rhat

;mov   ds, ax
mov   word ptr [bp - 6], ax

mul   si   						; DX:AX = c1

;  c2 = rhat:num1



;    if (c1 > c2.wu)
;         qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
; 

mov   cx, ax					; CX has low bits of c1
mov   ax, bx					; ax has rhat

; c1 hi = dx, c2 lo = bx
cmp   dx, bx



ja    check_c1_c2_diff
jne   q1_ready
cmp   cx, word ptr [bp - 020h]
jbe   q1_ready
check_c1_c2_diff:

; (c1 - c2.wu > den.wu)

sub   cx, word ptr [bp - 020h]
sbb   dx, ax
cmp   dx, di
ja    qhat_subtract_2
je    compare_low_word
qhat_subtract_1:
mov   ax, 1
jmp   do_qhat_subtraction

compare_low_word:
cmp   cx, si
jbe   qhat_subtract_1
qhat_subtract_2:
mov   ax, 2

do_qhat_subtraction:

; qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;

;mov   dx, ds
;sub   dx, ax
;mov   ds, dx	; store q1. could this be better...?
sub   word ptr [bp - 6], ax

;    q1 = (uint16_t)qhat;

q1_ready:

mov   ax, word ptr [bp - 6]
mov   ds, ax	; store q1. could this be better...?

; q1 is in DS

;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);


mov   bx, word ptr [bp - 01ah]
mov   cx, ax
mov   word ptr [bp - 2], bx

; multiplying by DI:SI basically. inline SI in as BX.

;inlined FastMul16u32u_

MUL  DI        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  SI        ; AX * BX
ADD  DX, CX    ; add 

; actual 2nd division...

mov   bx, word ptr [bp - 020h]
sub   bx, ax
sbb   word ptr [bp - 2], dx
mov   dx, word ptr [bp - 2]
mov   ax, bx

cmp   dx, di

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow

; default case, most common by a ton


div   di

mov   bx, dx
mov   cx, ax

mul   si

;mov   es, ax
;mov   ax, bx

cmp   dx, bx
ja    continue_c1_c2_test
jne   do_return



cmp   ax, word ptr [bp - 022h]
jbe   do_return

continue_c1_c2_test:


sub   ax, word ptr [bp - 022h]
sbb   dx, bx

mov   bx, 1
cmp   dx, di
ja    do_qhat_subtraction_by_2
jne   do_qhat_subtraction_by_1
cmp   si, ax
jae   do_qhat_subtraction_by_1
do_qhat_subtraction_by_2:
inc   bx
do_qhat_subtraction_by_1:
sub   cx, bx
do_return:
mov   ax, cx
mov   dx, ds
mov   bx, ss
mov   ds, bx  ; restore ds
mov   sp, bp
pop   bp
pop   si
ret  


adjust_for_overflow:

; division result will be over 16 bits. need to subtract once or twice

xor   dx, dx
sub   ax, di
sbb   word ptr [bp - 2], dx

cmp   di, word ptr [bp - 2]

; check for overflow param

jb   adjust_for_overflow_again

mov   dx, word ptr [bp - 2]

; no subtraction needed (most common case)


div   di
mov   bx, dx	; cx holds rhat
mov   cx, ax


mul   si

;    c1 = FastMul16u16u(qhat , den0);
;    c2.hu.intbits = rhat;
;	c2.hu.fracbits = num1;
;    if (c1 > c2.wu)
;        qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;


cmp   dx, ax
ja    continue_c1_c2_test_2
jne   dont_decrement_qhat_and_return

cmp   ax, word ptr [bp - 022h]
jbe   dont_decrement_qhat_and_return
continue_c1_c2_test_2:

sub   ax, word ptr [bp - 022h]
sbb   dx, bx
cmp   dx, di
ja    decrement_qhat_and_return
jne   dont_decrement_qhat_and_return
cmp   si, ax
jae   dont_decrement_qhat_and_return
decrement_qhat_and_return:
dec   cx

dont_decrement_qhat_and_return:
mov   ax, cx
mov   dx, ds
mov   cx, ss
mov   ds, cx
mov   sp, bp
pop   bp
pop   si
ret  

; the divide would have overflowed. subtract a second time
adjust_for_overflow_again:
sub   ax, di
sbb   word ptr [bp - 2], dx
mov   dx, word ptr [bp - 2]
div   di

; ax has its result...

mov   dx, word ptr [bp - 6]
mov   cx, ss
mov   ds, cx
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