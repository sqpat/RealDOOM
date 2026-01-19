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

INSTRUCTION_SET_MACRO_NO_MEDIUM

SEGMENT P_MATH_TEXT  USE16 PARA PUBLIC 'CODE'
ASSUME cs:P_MATH_TEXT





PROC   P_MATH_STARTMARKER_ 
PUBLIC P_MATH_STARTMARKER_
ENDP

IF COMPISA LE COMPILE_286



PROC   FixedMul2432_MapLocal_ NEAR
PUBLIC FixedMul2432_MapLocal_

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

MOV AL, DH  ; 43 24
MOV DH, DL  ; 33 24
MOV DL, AH  ; 32 24
CBW         ; 32 S4
XCHG AX, DX ; S4 32

ENDP
; fall thru


PROC   FixedMul_MapLocal_ NEAR
PUBLIC FixedMul_MapLocal_

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
RET

ENDP

ELSE

PROC   FixedMul2432_MapLocal_ NEAR
PUBLIC FixedMul2432_MapLocal_

PROC   FixedMul2432_MapLocal_ NEAR
PUBLIC FixedMul2432_MapLocal_

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
; fall thru

PROC   FixedMul_MapLocal_ NEAR
PUBLIC FixedMul_MapLocal_

; DX:AX  *  CX:BX
;  0  1      2  3

; thanks zero318 for xchg improvement ideas
  
  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul ecx
  shr  eax, 16


ret
ENDP





ENDIF


PROC   FixedMulBig16u32_MapLocal_ NEAR
PUBLIC FixedMulBig16u32_MapLocal_

; AX:00  *  CX:BX
; 1          2  3

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
;                               00BXhi	 00BXlo
;                       AXBXhi  AXBXlo          
;
;                       00CXhi  00CXlo
;               AXCXhi  AXCXlo  
;                       
;                               
;                       
;       




; need to get the sign-extends for DX and CX



XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  AX, CX    ; add 

ret



ENDP








PROC   FixedMul1632_MapLocal_  NEAR
PUBLIC FixedMul1632_MapLocal_

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



; improved into imul version by zero318


  MOV ES, CX
  MOV CX, AX
  MUL BX
  XCHG AX, DX
  XCHG AX, CX
  CWD
  AND BX, DX
  MOV DX, ES
  IMUL DX
  SUB CX, BX
  SBB BX, BX
  ADD AX, CX
  ADC DX, BX
  RET



ENDP




IF COMPISA GE COMPILE_386

    PROC   FixedMulTrig_MapLocal_ NEAR
    PUBLIC FixedMulTrig_MapLocal_
    sal dx, 1
    sal dx, 1   ; DWORD lookup index
    ENDP

    PROC   FixedMulTrigNoShift_MapLocal_ NEAR
    PUBLIC FixedMulTrigNoShift_MapLocal_
    ; pass in the index already shifted to be a dword lookup..


    ; lookup the fine angle

    mov es, ax
    db  066h, 081h, 0E2h, 0FFh, 0FFh, 0, 0  ;  and edx, 0x0000FFFF   

    db  026h, 067h, 066h, 08bh, 002h     ; mov  eax, dword ptr es:[edx]


    db  066h, 0C1h, 0E3h, 010h           ; shl  ebx, 0x10
    db  066h, 00Fh, 0ACh, 0CBh, 010h     ; shrd ebx, ecx, 0x10
    db  066h, 0F7h, 0EBh                 ; imul ebx
    db  066h, 0C1h, 0E8h, 010h           ; shr  eax, 0x10


    ret



    ENDP


ELSE

    PROC   FixedMulTrig_MapLocal_ NEAR
    PUBLIC FixedMulTrig_MapLocal_

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

    sal dx, 1
    sal dx, 1   ; DWORD lookup index

    ENDP
    PROC   FixedMulTrigNoShift_MapLocal_ NEAR
    PUBLIC FixedMulTrigNoShift_MapLocal_
    ; pass in the index already shifted to be a dword lookup..

    push  si

    ; lookup the fine angle

; todo swap arg order so cx:bx is seg/lookup
; allowing for mov es, cx -> les es:[bx]


    mov  si, dx
    mov  es, ax  ; put segment in dS
    les  ax, dword ptr es:[si]

    mov  dx, es
    mov  es, ax
    mov  ax, dx  ; gross juggle... revisit. for consistency with old algo


    AND   AX, BX	; S0*BX
    NEG   AX
    XCHG  AX, SI	; SI stores hi word return

    MOV   AX, DX    ; restore sign bits from DX

    AND   AX, CX     ; DX*CX
    SUB   SI, AX     ; low word result into high word return

    ; DX already has sign bits..

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
    ADC  SI, 0    ; would be cool if we had a known zero reg

    xchg AX, CX   ; AX gets CX

    CWD           ; S1 in DX

    mov  CX, ES   ; AX from ES
    AND  DX, CX   ; S1*AX
    SUB  SI, DX   ; result into high word return

    MUL  CX       ; AX*CX

    ADD  AX, BX	  ; set up final return value
    ADC  DX, SI

    pop   si
    ret



    ENDP
ENDIF



IF COMPISA GE COMPILE_386

    PROC   FixedMulTrig16_MapLocal_ NEAR
    PUBLIC FixedMulTrig16_MapLocal_

    ; lookup the fine angle
    mov es, ax

    ; todo improve zeroing out of high 16 bits.
    db  066h, 081h, 0E2h, 0FFh, 0FFh, 0, 0  ;  and edx, 0x0000FFFF   

    ; no shift of dx needed..
    db  026h, 066h, 08bh, 06bh, 0, 0     ; mov  eax, dword ptr es:[4*edx]
    db  066h, 081h, 0E3h, 0FFh, 0FFh, 0, 0  ;  and ebx, 0x0000FFFF   
    db  066h, 0F7h, 0EBh                 ; imul ebx

    db  066h, 0C1h, 0E8h, 010h           ; shr  eax, 0x10

    ret



    ENDP
ELSE

    PROC   FixedMulTrig16_MapLocal_ NEAR
    PUBLIC FixedMulTrig16_MapLocal_

    ; DX:AX  *  CX:00
    ;  0  1   2  

    ; DX:AX * CX:00
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
    ; CX:00 is value 2

    ; DX:AX * CX

    ; BX is used by this function and not preserved! fine in our use case.


    ; lookup the fine angle

    SAL dx, 1
    SAL dx, 1   ; DWORD lookup index
    MOV BX, dx
    MOV es, ax  ; put segment in ES
    les ax, dword ptr es:[BX]
    mov dx, es



    AND  DX, CX    ; DX*CX
    NEG  DX
    MOV  BX, DX    ; store high result


    MUL  CX       ; AX*CX
    ADD  DX, BX   
    

    ret



    ENDP

ENDIF






; todo: hardcode 10, 15, 20, 25 versions on switch case
; takes in 8 bit speed param, which is always a missile 
; then does a multiply to get the expected result.
; avoids needless back and forth 16 bit shift

; bl holds speed
; allowed to modify ax bx cx dx

; equivalent to an unsigned mult even though it is signed.

PROC   FixedMulTrigSpeed_MapLocal_  NEAR
PUBLIC FixedMulTrigSpeed_MapLocal_

SHIFT_MACRO shl dx 2

ENDP
PROC   FixedMulTrigSpeedNoShift_MapLocal_ NEAR
PUBLIC FixedMulTrigSpeedNoShift_MapLocal_

; todo pass this in via ES

mov es, ax  ; put segment in ES
xchg dx, bx

les cx, dword ptr es:[BX]
mov ax, es

; speed is dx, mul by ax:Cx 
and dx, 07Fh  ; drop the 32 bit flag.   bit 7 stores that this is a * fracunit value.

mov  BX, DX    ; dupe DX

MUL  DX        ; high mul

XCHG BX, AX    ; store low product to be high result. Retrieve orig AX
MUL  CX        ; low mul
ADD  DX, BX    ; add 

; ax * cx:bx

ret

ENDP



; first param is unsigned so DX and sign can be skipped
PROC   FixedMul16u32_MapLocal_   NEAR
PUBLIC FixedMul16u32_MapLocal_

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




; both params unsigned. drop all sign extensions.. and dont shift by 16 like fixed algos!
PROC   FastMul16u32u_MapLocal_  NEAR
PUBLIC FastMul16u32u_MapLocal_

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


shift_word:
mov si, dx
xchg  ax, dx
xor ax, ax
mov cx, bx
mov bx, ax

jmp shift_bits

;   
; basically, shift numerator left 16 and divide
; DX:AX:00 / CX:BX

PROC   div48_32_MapLocal_    NEAR
PUBLIC div48_32_MapLocal_


; di:si get shifted cx:bx

push  di
push  bp



XOR SI, SI ; zero this out to get high bits of numhi


jcxz  shift_word
; default branch taken 314358 vs 126885


test ch, ch
jne shift_bits
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl


xchg dh, dl
mov  si, dx
and si, 00FFh  ; todo make this better

mov dl, ah
mov ah, al
xor al, al

shift_bits:



; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1






; store this
done_shifting:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1
RCR BX, 1


; SI:DX:AX holds divisor...
; CX:BX holds dividend...
; numhi = SI:DX
; numlo = AX:00...


; save numlo word in bp.
; avoid going to memory... lets do interrupt magic

mov bp, ax


; set up first div. 
; dx:ax becomes numhi
mov   ax, dx
mov   dx, si    

; store these two long term...
mov   di, cx
mov   si, bx

mov   ds, ax                    ; store copy of numhi.low?



;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   di

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   bx, dx					; bx stores rhat
mov   es, ax     ; store qhat

mul   si   						; DX:AX = c1

;  c2 = rhat:num1



;    if (c1 > c2.wu)
;         qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
; 


; c1 hi = dx, c2 lo = bx
cmp   dx, bx



ja    check_c1_c2_diff
jne   q1_ready
cmp   ax, bp
jbe   q1_ready
check_c1_c2_diff:

; (c1 - c2.wu > den.wu)

sub   ax, bp
sbb   dx, bx
cmp   dx, di
ja    qhat_subtract_2
je    compare_low_word
jmp   qhat_subtract_1

compare_low_word:
cmp   ax, si
jbe   qhat_subtract_1

; ugly but rare occurrence i think?
qhat_subtract_2:
mov ax, es
dec ax
mov es, ax
qhat_subtract_1:
mov ax, es
dec ax
mov es, ax



;    q1 = (uint16_t)qhat;

q1_ready:

mov  ax, es
;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);


mov   cx, ax

; multiplying by DI:SI basically. inline SI in as BX.

;inlined FastMul16u32u_

MUL  DI        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  SI        ; AX * BX
ADD  DX, CX    ; add 

; actual 2nd division...


sub   bp, ax
mov   cx, ds
sbb   cx, dx
mov   dx, cx
mov   ax, bp

cmp   dx, di

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow


; 441240 branch not taken vs 3 taken


div   di

mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx

ja    continue_c1_c2_test
je    continue_check

; default 440124 vs branch 105492 times
do_return_2:
mov   dx, es      ; retrieve q1
mov   ax, bx

mov   cx, ss      ; restore ds
mov   ds, cx      

pop   bp
pop   di
ret  

continue_check:
cmp   ax, 0
jbe   do_return_2
continue_c1_c2_test:
sbb   dx, cx
cmp   dx, di
ja    do_qhat_subtraction_by_2
jne   do_qhat_subtraction_by_1
cmp   si, ax

jae   do_qhat_subtraction_by_1
do_qhat_subtraction_by_2:
dec   bx
do_qhat_subtraction_by_1:
dec   bx

jmp do_return_2;




adjust_for_overflow:
xor   dx, dx
sub   ax, di
sbb   cx, dx

cmp   cx, di

; check for overflow param

jae   adjust_for_overflow_again

mov   dx, cx



div   di
mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx
ja    continue_c1_c2_test_2
jne   dont_decrement_qhat_and_return
cmp   ax, 0
jbe   dont_decrement_qhat_and_return
continue_c1_c2_test_2:

sub   dx, cx
cmp   dx, di
ja    decrement_qhat_and_return
jne   dont_decrement_qhat_and_return
cmp   si, ax
jae   dont_decrement_qhat_and_return
decrement_qhat_and_return:
dec   bx
dont_decrement_qhat_and_return:
mov   ax, bx
mov   dx, es   ;retrieve q1
mov   cx, ss
mov   ds, cx

pop   bp
pop   di
ret  

; the divide would have overflowed. subtract values
adjust_for_overflow_again:

sub   ax, di
sbb   cx, dx
mov   dx, cx
div   di


; ax has its result...

mov   dx, es
mov   cx, ss
mov   ds, cx

pop   bp
pop   di
ret 





endp







COMMENT @
; TODO: test this fpu version by zero318


  MOV ES, SI
  XCHG AX, SI
  XCHG AX, DX
  CWD
  PUSH DX
  PUSH AX
  PUSH SI
  XOR AX, AX
  PUSH AX
  MOV SI, SP
  FILD QWORD [SI]
  WAIT
  FNSTCW [SI]
  MOV [SI+2], BX
  MOV [SI+4], CX
  FIDIV DWORD [SI+2]
  MOV BH, 0xC
  OR BX, [SI]
  MOV [SI+6], BX
  XOR CH, DH
  WAIT
  FLDCW [SI+6]
  FISTP DWORD [SI+2]
  WAIT
  FLDCW [SI]
  ADD SP, 2
  POP AX
  FNSTSW [SI+6]
  MOV SI, ES
  POP DX
  POP BX
  SHR BL, 1
  JC divide_overflow
  RET
divide_overflow:
  SHL CH, 1
  CMC
  SBB CX, CX
  XOR AX, CX
  XOR DX, CX
  RET


@



IF COMPISA LE COMPILE_286

do_quick_return:
  MOV   AX, SI
  NEG   AX
  DEC   AX
  CWD
  RCR   DX, 1
  MOV   BP, ES
  POP   SI
  RET

PROC   FixedDiv_MapLocal_   NEAR
PUBLIC FixedDiv_MapLocal_

; big improvements to branchless fixeddiv 'preamble' by zero318


  PUSH  SI
  MOV   ES, BP
  MOV   SI, DX
  SHL   SI, 1
  SBB   SI, SI  ; sign of dx in si
  XOR   AX, SI
  XOR   DX, SI  
  SUB   AX, SI  
  SBB   DX, SI  ; dx:ax now labs. sign bits in si
  MOV   BP, CX
  SHL   BP, 1
  SBB   BP, BP
  XOR   BX, BP
  XOR   CX, BP
  SUB   BX, BP
  SBB   CX, BP ; cx:bx now labs. sign bits in bp
  XOR   SI, BP ; si has sign bits
  MOV   BP, DX ; 
  ROL   BP, 1
  ROL   BP, 1
  AND   BP, 3  ;   3 is FFFF shr 14
  CMP   BP, CX ;   if ( (abs(a)>>14) >= abs(b))
  JG do_quick_return
  JNE   do_full_divide
  MOV   BP, DX
  ROL   AX, 1
  RCL   BP, 1
  ROL   AX, 1
  RCL   BP, 1
  CMP   BP, BX
  JAE   do_quick_return
  ROR   AX, 1
  ROR   AX, 1
do_full_divide:

  MOV  BP, ES    ; restore bp
  mov  word ptr cs:[_SELFMODIFY_store_fixeddiv_sign_ahead+1], si



call div48_32_MapLocal_ ; internally does push pop of di/bp but not si

; set negative if need be...

_SELFMODIFY_store_fixeddiv_sign_ahead:
mov  si, 01000h

XOR  AX, SI
XOR  DX, SI  
SUB  AX, SI  
SBB  DX, SI  ; dx:ax now labs. sign bits in si


pop   si
ret


ENDP

ELSE

  
PROC   FixedDiv_MapLocal_ FAR
PUBLIC FixedDiv_MapLocal_

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



ENDIF

PROC   FastDiv32u16u_MapLocal_   NEAR
PUBLIC FastDiv32u16u_MapLocal_

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
ret




ENDP


PROC   FastDiv3216u_MapLocal_    NEAR
PUBLIC FastDiv3216u_MapLocal_

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
ret




ENDP



PROC   FixedDivWholeA_MapLocal_FAR_  FAR
PUBLIC FixedDivWholeA_MapLocal_FAR_
call   FixedDivWholeA_MapLocal_
retf
ENDP

PROC   FixedDivWholeA_MapLocal_  NEAR
PUBLIC FixedDivWholeA_MapLocal_


; AX:00 / CX:BX
; return in DX:AX

; this is fixeddiv so we must do the whole labs14 check and word shift adjustment


mov   dx, ax  ; dx will store sign bit 
xor   dx, cx  ; dx now stores signedness via test operator...



; here we abs the numbers before unsigned division algo

or    cx, cx
jge   b_is_positive_whole
neg   bx
adc   cx, 0
neg   cx


b_is_positive_whole:

or    ax, ax			; sign check
jge   a_is_positive_whole
neg   ax

a_is_positive_whole:

;  ax:00  is  labs(ax:00) now (unshifted)
;  cx:bx  is  labs(cx:bx) now
mov   es, dx   ; store sign bit for now
xor   dx, dx
sal   ax, 1
rcl   dx, 1
sal   ax, 1
rcl   dx, 1
cmp   dx ,cx   ; compare high bit
jg    do_quick_return_whole                 ; greater
jne   restore_reg_then_do_full_divide_whole ; smaller
cmp   ax ,bx
jb    restore_reg_then_do_full_divide_whole
do_quick_return_whole: 
; return (a^b) < 0 ? MINLONG : MAXLONG;


mov   dx, es   ; restore sign bit

test  dx, dx   ; just need to do the high word due to sign?
jl    return_MAXLONG_whole

return_MINLONG_whole:

mov   ax, 0ffffh
mov   dx, 07fffh


ret

restore_reg_then_do_full_divide_whole:


sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1   ; restore ax
mov   dx, es  ; restore sign bit

; main division algo

do_full_divide_whole:


; set negative if need be...

test  dx, dx
jl do_negative_whole



call div48_32_whole_MapLocal_



ret

do_negative_whole:



call div48_32_whole_MapLocal_



neg   ax
adc   dx, 0
neg   dx


ret

return_MAXLONG_whole:

mov   dx, 08000h
xor   ax, ax
ret



endp



shift_word_whole:
mov dx, ax
xor ax, ax
mov cx, bx
xor bx, bx

jmp shift_bits_whole

;div48_32_whole_
; basically, shift numerator left 16 and divide
; AX:00:00 / CX:BX

PROC   div48_32_whole_MapLocal_ NEAR
PUBLIC div48_32_whole_MapLocal_

; di:si get shifted cx:bx



xor dx, dx


push  si
push  di
push  bp
mov   bp, sp




test cx, cx
je  shift_word_whole
; default branch taken 314358 vs 126885


test ch, ch
jne shift_bits_whole
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl


mov  dh, dl
mov dl, ah
mov ah, al
xor al, al

shift_bits_whole:



; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1






; store this
done_shifting_whole:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1
RCR BX, 1





; DX:AX holds divisor...
; CX:BX holds dividend...
; numhi = DX:AX
; numlo = 00:00...





; store these two long term...
; todo i think cx can be filtered out...
mov   di, cx
mov   si, bx

mov   ds, ax                    ; store copy of numhi.low




;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   di

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   bx, dx					; bx stores rhat
mov   es, ax     ; store qhat

mul   si   						; DX:AX = c1

;  c2 = rhat:num1



;    if (c1 > c2.wu)
;         qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
; 


; c1 hi = dx, c2 lo = bx
cmp   dx, bx



ja    check_c1_c2_diff_whole
jne   q1_ready_whole
cmp   ax, 0
jbe   q1_ready_whole
check_c1_c2_diff_whole:

; (c1 - c2.wu > den.wu)

sub   dx, bx
cmp   dx, di
ja    qhat_subtract_2_whole
je    compare_low_word_whole
jmp   qhat_subtract_1_whole

compare_low_word_whole:
cmp   ax, si
jbe   qhat_subtract_1_whole

; ugly but rare occurrence i think?
qhat_subtract_2_whole:
mov ax, es
dec ax
mov es, ax
qhat_subtract_1_whole:
mov ax, es
dec ax
mov es, ax



;    q1 = (uint16_t)qhat;

q1_ready_whole:

mov  ax, es
;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);


mov   cx, ax

; multiplying by DI:SI basically. inline SI in as BX.

;inlined FastMul16u32u_

MUL  DI        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  SI        ; AX * BX
ADD  DX, CX    ; add 

; actual 2nd division...


neg   ax
mov   cx, ds
sbb   cx, dx
mov   dx, cx

cmp   dx, di

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow_whole




div   di

mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx

ja    continue_c1_c2_test_whole
je    continue_check_whole

do_return_2_whole:
mov   dx, es      ; retrieve q1
mov   ax, bx

mov   cx, ss      ; restore ds
mov   ds, cx      
LEAVE_MACRO
pop   di
pop   si
ret  

continue_check_whole:
cmp   ax, 0
jbe   do_return_2_whole
continue_c1_c2_test_whole:
sbb   dx, cx
cmp   dx, di
ja    do_qhat_subtraction_by_2_whole
jne   do_qhat_subtraction_by_1_whole
cmp   si, ax

jae   do_qhat_subtraction_by_1_whole
do_qhat_subtraction_by_2_whole:
dec   bx
do_qhat_subtraction_by_1_whole:
dec   bx

jmp do_return_2_whole




adjust_for_overflow_whole:
xor   dx, dx
sub   ax, di
sbb   cx, dx

cmp   cx, di

; check for overflow param

jae   adjust_for_overflow_again_whole

mov   dx, cx



div   di
mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx
ja    continue_c1_c2_test_2_whole
jne   dont_decrement_qhat_and_return_whole
cmp   ax, 0
jbe   dont_decrement_qhat_and_return_whole
continue_c1_c2_test_2_whole:

sub   dx, cx
cmp   dx, di
ja    decrement_qhat_and_return_whole
jne   dont_decrement_qhat_and_return_whole
cmp   si, ax
jae   dont_decrement_qhat_and_return_whole
decrement_qhat_and_return_whole:
dec   bx
dont_decrement_qhat_and_return_whole:
mov   ax, bx
mov   dx, es   ;retrieve q1
mov   cx, ss
mov   ds, cx
LEAVE_MACRO
pop   di
pop   si
ret  

; the divide would have overflowed. subtract values
adjust_for_overflow_again_whole:

sub   ax, di
sbb   cx, dx
mov   dx, cx
div   di

; ax has its result...

mov   dx, es
mov   cx, ss
mov   ds, cx
LEAVE_MACRO
pop   di
pop   si
ret 





endp



PROC   FixedMul2424_ NEAR
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



;R_PointToAngle2_16_

PROC R_PointToAngle2_16_MapLocal_ NEAR
PUBLIC R_PointToAngle2_16_MapLocal_

;uint32_t __far R_PointToAngle2_16 (  int16_t	x2, int16_t	y2 ) {	
;	fixed_t_union x2fp, y2fp;
;	x2fp.h.intbits = x2;
;	y2fp.h.intbits = y2;
;	x2fp.h.fracbits = 0;
;	y2fp.h.fracbits = 0;
;    return R_PointToAngle (x2fp, y2fp);

push      bx
push      cx
mov       cx, dx
xchg      ax, dx
xor       ax, ax
mov       bx, ax
call      R_PointToAngle_MapLocal_
pop       cx
pop       bx
ret      
ENDP





octant_6:
test  cx, cx

jne   octant_6_do_divide
cmp   bx, 0200h
jae   octant_6_do_divide
octant_6_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax

ret  
octant_6_do_divide:
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_6_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 0c000h

ret  

y_is_negative:
;			y.w = -y.w;

neg   cx
neg   bx
sbb   cx, 0

cmp   dx, cx
jg    octant_7
jne   octant_6
cmp   ax, bx
jbe   octant_6
octant_7:
test  dx, dx
jne   octant_7_do_divide
cmp   ax, 0200h
jae   octant_7_do_divide
octant_7_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax

ret  
; result 16f01520
; 7ffd1a dx:ax
; 3077f6 cx:bx
; 5400000 -> 0x2A000000
; d400000  > 0xD4000    32B 811

;mov dx, cx
;mov ax, bx


octant_7_do_divide:

; swap params. y over x not x over y
xchg dx, cx
xchg ax, bx

call FastDiv3232_shift_3_8_

; 16f0  1520 instead of 32b

cmp   ax, 0800h
jae   octant_7_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
neg   dx
neg   ax
sbb   dx, 0

ret  

;R_PointToAngle_

PROC   R_PointToAngle_MapLocal_ NEAR
PUBLIC R_PointToAngle_MapLocal_
; inputs:
; DX:AX = x  (32 bit fixed pt 16:16)
; CX:BX = y  (32 bit fixed pt 16:16)

; places to improve -
; 1.default branches taken. count branches taken and modify to optimize

;	x.w -= viewx.w;
;	y.w -= viewy.w;

; idea: self modify code, change this to constants per frame.



test  dx, dx
jne   inputs_not_zero   ; todo rearrange this. rare case
test  cx, cx
jne   inputs_not_zero   ; todo rearrange this. rare case
test  ax, ax
jne   inputs_not_zero   ; todo rearrange this. rare case
test  bx, bx
jne   inputs_not_zero   ; todo rearrange this. rare case


return_0:

xor   ax, ax
cwd

ret  


inputs_not_zero:

test  dx, dx
js   x_is_negative

x_is_positive:
test  cx, cx

js   y_is_negative
y_is_positive:

cmp   dx, cx
jg    octant_0

jne   octant_1
cmp   ax, bx
jbe   octant_1


octant_0:
test  dx, dx

;	if (x.w < 512)

jne   octant_0_do_divide
cmp   ax, 0200h
jae   octant_0_do_divide
octant_0_out_of_bounds:
mov   dx, 02000h
xor   ax, ax

ret  


octant_0_do_divide:
;x_is_negative
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_0_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
ret  


octant_1:
test  cx, cx

jne   octant_1_do_divide
cmp   bx, 0200h
jae   octant_1_do_divide
octant_1_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 01fffh

ret  
octant_1_do_divide:
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_1_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 03fffh
sbb   dx, word ptr es:[bx + 2]

ret  



x_is_negative:

;		x.w = -x.w;

neg   dx
neg   ax
sbb   dx, 0

test  cx, cx

jg    y_is_positive_x_neg
jne   y_is_negative_x_neg
y_is_positive_x_neg:
cmp   dx, cx
jg    octant_3
jne   octant_2
cmp   ax, bx
jbe   octant_2

octant_3:
test  dx, dx
jne   octant_3_do_divide
cmp   ax, 0200h
jae   octant_3_do_divide
octant_3_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 05fffh

ret  
octant_3_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_3_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 07fffh
sbb   dx, word ptr es:[bx + 2]

ret  
octant_2:
test  cx, cx

jne   octant_2_do_divide
cmp   ax, 0200h
jae   octant_2_do_divide
octant_2_out_of_bounds:
mov   dx, 06000h
xor   ax, ax
ret  
octant_2_do_divide:

call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_2_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 04000h

ret  
y_is_negative_x_neg:

;			y.w = -y.w;

neg   cx
neg   bx
sbb   cx, 0
cmp   dx, cx
jg    octant_4
jne   octant_5
cmp   ax, bx
jbe   octant_5
octant_4:
test  dx, dx
jne   octant_4_do_divide
cmp   ax, 0200h
jae   octant_4_do_divide
octant_4_out_of_bounds:
mov   dx, 0a000h
xor   ax, ax

ret  
octant_4_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_4_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 08000h

ret  
octant_5:
test  cx, cx

jne   octant_5_do_divide
cmp   ax, 0200h
jae   octant_5_do_divide
octant_5_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 09fffh

ret  
octant_5_do_divide:

call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_5_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 0bfffh
sbb   dx, word ptr es:[bx + 2]

ret  
ENDP




fast_div_32_16:

mov bl, bh
mov bh, cl

sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1


div bx        ; after this dx stores remainder, ax stores q1

ret          ; dx will be garbage, but who cares , return 16 bits.

return_2048:


mov ax, 0800h
ret


PROC FastDiv3232_shift_3_8_ NEAR

; used by R_PointToAngle.
; DX:AX << 3 / CX:BX >> 8
; signed, but comes in positive. so high bit is never on
; if result is > 2048, a branch is taken and result is not used, 
; so this is designed around quickly detecting results greater than that



test ch, ch
je fast_div_32_16


; we have not shifted yet...


;TODO: checks are done outside this function, may be okay to remove this. test?
; we want to know if  (DX:AX << 3)  / (CX:BX >> 8)  >= 2048 for a quick out
; but that is just "is dx:ax greater than cx:bx"


cmp dx, cx
ja  return_2048
jb full_32_32
cmp ax, bx
jae return_2048


full_32_32:




call FastDiv3232_RPTA_

ret

ENDP



; todo optimize around fact ch is always 0...
; we are moving a byte back and forth

fast_div_32_16_RPTA:

mov bl, bh
mov bh, cl
mov cl, ch
xor ch, ch
sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1


xchg dx, cx   ; cx was 0, dx is FFFF
div bx        ; after this dx stores remainder, ax stores q1
xchg cx, ax   ; q1 to cx, ffff to ax  so div remaidner:ffff 
div bx
mov dx, cx   ; q1:q0 is dx:ax
ret 


; NOTE: this is used for R_PointToAngle and has a fast out when the high byte is detected to be above the threshhold

;FastDiv3232_RPTA_
; DX:AX / CX:BX

PROC FastDiv3232_RPTA_ NEAR

; we shift dx:ax by 11 into si... 




; if top 16 bits missing just do a 32 / 16

test ch, ch
je fast_div_32_16_RPTA

main_3232RPTA_div:

push  si
push  di

; shift left 11 in si:dx:ax


;si: 
;00000111 11111111
;dx:
;11111222 22222222
;ax:
;22222000 00000000

mov si, dx
mov dx, ax
xor ax, ax

; creating si:dx:ax

shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1





; now lets shift CX:BX to max...




test ch, ch
jne shift_bits_3232RPTA
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl


xchg ax, si
mov  ah, al
mov  al, dh
mov  dh, dl
xchg ax, si
mov  dl, ah
xor  al, al


shift_bits_3232RPTA:

; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1



; store this
done_shifting_3232RPTA:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1
RCR BX, 1


; SI:DX:AX holds divisor...
; CX:BX holds dividend...
; numhi = SI:DX
; numlo = AX:00...


; save numlo word in sp.
; avoid going to memory... lets do interrupt magic
mov di, ax


; set up first div. 
; dx:ax becomes numhi
mov   ax, dx
mov   dx, si    

; store these two long term...
mov   si, bx



; numhi is 00:SI in this case?

;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   cx

; qhat is at most 2 greater than the real answer.
; we are capping results at 2048 or 0x800 so quick return in that case.

cmp  ax, 0802h
ja   return_2048_2


; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   bx, dx					; bx stores rhat
mov   es, ax     ; store qhat




mul   si   						; DX:AX = c1


; c1 hi = dx, c2 lo = bx
cmp   dx, bx

ja    check_c1_c2_diff_3232RPTA
jne   q1_ready_3232RPTA
cmp   ax, di
jbe   q1_ready_3232RPTA
check_c1_c2_diff_3232RPTA:

; (c1 - c2.wu > den.wu)

sub   ax, di
sbb   dx, bx
cmp   dx, cx
ja    qhat_subtract_2_3232RPTA
je    compare_low_word_3232RPTA
jmp   qhat_subtract_1_3232RPTA

compare_low_word_3232RPTA:
cmp   ax, si
jbe   qhat_subtract_1_3232RPTA

; ugly but rare occurrence i think?
qhat_subtract_2_3232RPTA:
mov ax, es
dec ax
dec ax

pop   di
pop   si
ret  

return_2048_2:
; bigger than 2048.. just return it
pop   di
pop   si
ret


qhat_subtract_1_3232RPTA:
mov ax, es
dec ax

pop   di
pop   si
ret  




q1_ready_3232RPTA:

mov  ax, es

pop   di
pop   si
ret  


ENDP

PROC   R_PointToAngle2_FAR_ FAR
PUBLIC R_PointToAngle2_FAR_

; a little gross. Ah well, rare call (once every many frames) compared to below (many every frame)

push   word ptr [bp + 08h]
push   word ptr [bp + 0Ah]
push   word ptr [bp + 0Ch]
push   word ptr [bp + 0Eh]

call   R_PointToAngle2_MapLocal_
retf   8
ENDP

;R_PointToAngle2_

PROC   R_PointToAngle2_MapLocal_ NEAR
PUBLIC R_PointToAngle2_MapLocal_ 


;uint32_t __far R_PointToAngle2 ( fixed_t_union	x1, fixed_t_union	y1, fixed_t_union	x2, fixed_t_union	y2 ) {	
;    return R_PointToAngle (x2, y2);
;	x2.w -= x1.w;
;	y2.w -= y1.w;

; todo swap param order?

push      si
push      bp
mov       bp, sp
les       si, dword ptr [bp + 6]
xchg      ax, si
sub       ax, si
mov       si, es
sbb       si, dx
mov       dx, si
les       si, dword ptr [bp + 0Ah]
sub       si, bx
mov       bx, si
mov       si, es
sbb       si, cx
mov       cx, si

call      R_PointToAngle_MapLocal_
pop       bp
pop       si
ret       8

ENDP

PROC   P_MATH_ENDMARKER_ 
PUBLIC P_MATH_ENDMARKER_
ENDP

ENDS

END