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
	.MODEL  medium

IF COMPILE_INSTRUCTIONSET LE COMPILE_286
GLOBAL FixedMul_:FAR
GLOBAL FixedDiv_:FAR
ENDIF



.CODE

IF COMPILE_INSTRUCTIONSET LE COMPILE_286



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



ENDIF


PROC FixedMulBig16u32_ FAR
PUBLIC FixedMulBig16u32_

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






PROC FixedMul1632_ FAR
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
retf



ENDP


; unused
COMMENT @


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

@ 


IF COMPILE_INSTRUCTIONSET GE COMPILE_386

    PROC FixedMulTrig_
    PUBLIC FixedMulTrig_
    sal dx, 1
    sal dx, 1   ; DWORD lookup index


    PROC FixedMulTrigNoShift_
    PUBLIC FixedMulTrigNoShift_
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

    sal dx, 1
    sal dx, 1   ; DWORD lookup index


    PROC FixedMulTrigNoShift_
    PUBLIC FixedMulTrigNoShift_
    ; pass in the index already shifted to be a dword lookup..

    push  si

    ; lookup the fine angle


    mov si, dx
    mov ds, ax  ; put segment in ES
    lodsw
    mov es, ax
    lodsw

    mov   DX, AX    ; store sign bits in DX
    AND   AX, BX	; S0*BX
    NEG   AX
    mov   SI, AX	; SI stores hi word return

    mov   AX, DX    ; restore sign bits from DX

    AND  AX, CX    ; DX*CX
    NEG  AX
    add  SI, AX    ; low word result into high word return

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
ENDIF



IF COMPILE_INSTRUCTIONSET GE COMPILE_386

    PROC FixedMulTrig16_
    PUBLIC FixedMulTrig16_

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

    PROC FixedMulTrig16_
    PUBLIC FixedMulTrig16_

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



IF COMPILE_INSTRUCTIONSET GE COMPILE_386

    PROC FastMulTrig16_
    PUBLIC FastMulTrig16_

    ; lookup the fine angle
    mov es, ax

    ; todo improve zeroing out of high 16 bits.
    db  066h, 081h, 0E2h, 0FFh, 0FFh, 0, 0  ;  and edx, 0x0000FFFF   

    ; no shift of dx needed..
    db  026h, 066h, 08bh, 06bh, 0, 0     ; mov  eax, dword ptr es:[4*edx]
    db  066h, 081h, 0E1h, 0FFh, 0FFh, 0, 0  ;  and ecx, 0x0000FFFF   
    db  066h, 0F7h, 0E9h                 ; imul ecx
    db  066h, 00Fh, 0A4h, 0C2h, 010h     ; shld edx, eax, 0x10

    ret



    ENDP

ELSE


    PROC FastMulTrig16_
    PUBLIC FastMulTrig16_

    ; DX:AX  *  BX
    ;  0  1      2  

    ; DX:AX * BX
    ; (dont shift answer 16)
    ;
    ; 
    ;BYTE
    ; RETURN VALUE
    ;                3       2       1		0
    ;                DONTUSE DONTUSE USE    USE


    ;                               AXBXhi	 AXBXlo
    ;                       DXBXhi  DXBXlo          
    ;               S0BXhi  S0BXlo                          
    ;
    ;               AXS1hi  AXS1lo
    ;                               
    ;                       
    ;       

    ; AX is param 1 (segment)
    ; DX is param 2 (fineangle or lookup)
    ; BX is value 2

    ; DX:AX * BX
    ; need to sign extend BX to CX...

    ; do lookup..

    SAL dx, 1
    SAL dx, 1   ; DWORD lookup index
    xchg BX, dx

    MOV es, ax  ; put segment in ES
    les ax, dword ptr es:[BX]
    mov bx, es



    ; begin multiply...

    AND   BX, DX
    NEG   BX        ; get sign mult for 16 bit param * high trig.

    MOV   ES, BX    ; store it in ES

    MOV   BX, AX  ; BX stores trig param lowbits
    MOV   AX, DX  ; AX stores 16 bit param 

    CWD   ; DX gets 16 bit arg's sign bits
    AND   DX, BX  ; still need to neg. move after mul for pipelining
    XCHG  DX, BX  ; swap params

    MUL   DX

    NEG   BX      ; finish the sign multiply from above, after the queue is full from mul
    ADD   DX, BX  ; add first sign bits back
    MOV   BX, ES  ; add second sign bits back
    ADD   DX, BX



    ret


    ENDP

ENDIF

COMMENT @

PROC FastMulFriction_
PUBLIC FastMulFriction_

; hardcoded multiply by E800:0000 
; this is equivalent to multiply by 13/16 so i tried to subtract 1/16th 3 times via shift
; however the rounding errors make this not work. could not deterministically
; figure out rounding errors either. but maybe its possible

; Param is DX:AX

push cx
push bx

mov cx, dx
mov bx, ax
sar cx, 1
rcr bx, 1
sar cx, 1
rcr bx, 1
sar cx, 1
rcr bx, 1
sar cx, 1
rcr bx, 1
 
; shift right to get cx:bx = dx:ax >> 5

; subtract three times (dx:ax >> 5)
sub ax, bx
sbb dx, cx

sar cx, 1
rcr bx, 1

sub ax, bx
sbb dx, cx


pop bx
pop cx
 
ret
ENDP

@


; todo: hardcode 10, 15, 20, 25 versions on switch case
; takes in 8 bit speed param, which is always a missile 
; then does a multiply to get the expected result.
; avoids needless back and forth 16 bit shift

; bl holds speed
; allowed to modify ax bx cx dx

; equivalent to an unsigned mult even though it is signed.

PROC FixedMulTrigSpeed_
PUBLIC FixedMulTrigSpeed_

SHIFT_MACRO shl dx 2


PROC FixedMulTrigSpeedNoShift_
PUBLIC FixedMulTrigSpeedNoShift_

mov es, ax  ; put segment in ES
xchg dx, bx

les cx, dword ptr es:[BX]
mov ax, es

; speed is dx, mul by ax:Cx 
and dx, 07Fh  ; drop the 32 bit flag


mov  BX, DX    ; dupe DX

MUL  DX        ; high mul

XCHG BX, AX    ; store low product to be high result. Retrieve orig AX
MUL  CX        ; low mul
ADD  DX, BX    ; add 

; ax * cx:bx

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


shift_word:
mov si, dx
mov dx, ax
xor ax, ax
mov cx, bx
xor bx, bx

jmp shift_bits

;   
; basically, shift numerator left 16 and divide
; DX:AX:00 / CX:BX

PROC div48_32_
PUBLIC div48_32_


; di:si get shifted cx:bx

push  si
push  bp
mov   bp, sp


XOR SI, SI ; zero this out to get high bits of numhi


test cx, cx
je  shift_word
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


; save numlo word in sp.
; avoid going to memory... lets do interrupt magic
cli
mov sp, ax


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
cmp   ax, sp
jbe   q1_ready
check_c1_c2_diff:

; (c1 - c2.wu > den.wu)

sub   ax, sp
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


sub   sp, ax
mov   cx, ds
sbb   cx, dx
mov   dx, cx
mov   ax, sp

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
LEAVE_MACRO
sti
pop   si
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
LEAVE_MACRO
sti
pop   si
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
LEAVE_MACRO
sti
pop   si
ret 





endp








IF COMPILE_INSTRUCTIONSET LE COMPILE_286

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

do_shift_and_full_compare:

; store backup dx:ax in ds:es

SHIFT_MACRO rol dx 2

mov di, dx
and di, 03h


; do comparison  di:bx vs dx:ax
; 	if ((labs(a) >> 14) >= labs(b))

cmp   di, cx
jg    do_quick_return
jne   restore_reg_then_do_full_divide ; below
mov   di, dx      ; recover this
mov   es, ax      ; back this up
SHIFT_MACRO rol ax 2
and   ax, 03h
and   di, 0FFFCh  ; cx, 0FFFCh
or    ax, di
cmp   ax, bx
jb    restore_reg_then_do_full_divide_2

do_quick_return: 
; return (a^b) < 0 ? MINLONG : MAXLONG;
test  si, si   ; just need to do the high word due to sign?
jl    return_MAXLONG

return_MINLONG:

mov   ax, 0ffffh
mov   dx, 07fffh

exit_and_return_early:

; restore ds...


pop   di
pop   si
ret

return_MAXLONG:

mov   dx, 08000h
xor   ax, ax
jmp   exit_and_return_early

; main division algo

restore_reg_then_do_full_divide_2:


; restore ax
mov ax, es
restore_reg_then_do_full_divide:

; restore dx
SHIFT_MACRO ror dx 2


do_full_divide:


call div48_32_

; set negative if need be...

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


ENDP

ENDIF

PROC FastDiv32u16u_ 
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
ret




ENDP

PROC FastDiv3216u_ 
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
ret




ENDP


; returns 16 bit div result of 32bit / 16bit inputs.
; return 32767 if answer would be larger than that. 
; param 1 is signed, param 2 is unsigned. return val is signed.

; UNUSED
 COMMENT @

PROC R_CalculateScaleStep_ 
PUBLIC R_CalculateScaleStep_

;DX:AX / BX 

; 1. abs the value
; 2. if DX > bx then return 32767 
; 3. otherwise divide
; 4. reapply sign if necessary
; 5. return

test dx, dx
js handle_negative  ; sign set if negative..

;  we have to check for result > 32767, not 65536. so we need the ax sign bit.
sal ax, 1
rcl dx, 1
cmp dx, bx
jge returnmax ;  result is > 65536

; restore bits
sar dx, 1
rcr ax, 1
div bx
ret

returnmax:
mov ax, 07FFFh
ret

handle_negative:

neg ax
adc dx, 0
neg dx

; we need to shift 1 before we compare. again are checking for > 32768 not > 65536. one bit does come from ax.
sal ax, 1
rcl dx, 1

cmp dx, bx

jge returnmax_neg
sar dx, 1
rcr ax, 1
div bx

neg ax

ret

returnmax_neg:
; todo make this 08000h ?
mov ax, 07FFFh
ret




ENDP

@

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

retf          ; dx will be garbage, but who cares , return 16 bits.

return_2048:


mov ax, 0800h
retf

PROC FastDiv3232_shift_3_8_
PUBLIC FastDiv3232_shift_3_8_

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

endp


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
retf 


; NOTE: this is used for R_PointToAngle and has a fast out when the high byte is detected to be above the threshhold

;FastDiv3232_RPTA_
; DX:AX / CX:BX

PROC FastDiv3232_RPTA_
PUBLIC FastDiv3232_RPTA_

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


endp






IF COMPILE_INSTRUCTIONSET GE COMPILE_386

    PROC FastDiv3232FFFF_ FAR
    PUBLIC FastDiv3232FFFF_

    ; EDX:EAX as 00000000 FFFFFFFF

    db 066h, 031h, 0C0h              ; xor eax, eax
    db 066h, 099h                    ; cdq
    db 066h, 048h                    ; dec eax


    ; set up ecx
    db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
    db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

    ; divide
    db 066h, 0F7h, 0F1h              ; div ecx

    ; set up return
    db 066h, 00Fh, 0A4h, 0C2h, 010h  ; shld edx, eax, 0x10
    ret

    ENDP

ELSE

    fast_div_32_16_FFFF:

    xchg dx, cx   ; cx was 0, dx is FFFF
    div bx        ; after this dx stores remainder, ax stores q1
    xchg cx, ax   ; q1 to cx, ffff to ax  so div remaidner:ffff 
    div bx
    mov dx, cx   ; q1:q0 is dx:ax
    retf 


    ; NOTE: this may not work right for negative params or DX:AX  besides 0xFFFFFFFF
    ; TODO: We only use the low 24 bits of output from this function. can we optimize..?
    ;FastDiv3232FFFF_
    ; DX:AX / CX:BX

    PROC FastDiv3232FFFF_ FAR
    PUBLIC FastDiv3232FFFF_



    ; if top 16 bits missing just do a 32 / 16
    mov  ax, -1
    cwd

    test cx, cx
    je fast_div_32_16_FFFF

    main_3232_div:

    push  si
    push  di



    XOR SI, SI ; zero this out to get high bits of numhi




    test ch, ch
    jne shift_bits_3232
    ; shift a whole byte immediately

    mov ch, cl
    mov cl, bh
    mov bh, bl
    xor bl, bl

    ; dont need a full shift 8 because we know everything is FF
    mov  si, 000FFh
    xor al, al

    shift_bits_3232:

    ; less than a byte to shift
    ; shift until MSB is 1
    ; DX gets 1s so we can skip it.

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232  
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1



    ; store this
    done_shifting_3232:

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

    ; rhat = dx
    ; qhat = ax
    ;    c1 = FastMul16u16u(qhat , den0);

    mov   bx, dx					; bx stores rhat
    mov   es, ax     ; store qhat

    mul   si   						; DX:AX = c1


    ; c1 hi = dx, c2 lo = bx
    cmp   dx, bx

    ja    check_c1_c2_diff_3232
    jne   q1_ready_3232
    cmp   ax, di
    jbe   q1_ready_3232
    check_c1_c2_diff_3232:

    ; (c1 - c2.wu > den.wu)

    sub   ax, di
    sbb   dx, bx
    cmp   dx, cx
    ja    qhat_subtract_2_3232
    je    compare_low_word_3232

    qhat_subtract_1_3232:
    mov ax, es
    dec ax
    xor dx, dx

    pop   di
    pop   si
    retf  

    compare_low_word_3232:
    cmp   ax, si
    jbe   qhat_subtract_1_3232

    ; ugly but rare occurrence i think?
    qhat_subtract_2_3232:
    mov ax, es
    dec ax
    dec ax

    pop   di
    pop   si
    retf  






    q1_ready_3232:

    mov  ax, es
    xor  dx, dx;

    pop   di
    pop   si
    retf


    endp

ENDIF





PROC FixedDivWholeA_
PUBLIC FixedDivWholeA_


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



call div48_32_whole_



ret

do_negative_whole:



call div48_32_whole_



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

PROC div48_32_whole_
PUBLIC div48_32_whole_

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

; UNUSED
COMMENT @

PROC FixedDivWholeAB3_
PUBLIC FixedDivWholeAB3_

; AX:00:00 / DX:00  OR AX:00 / DX
; return in DX:AX

; can we do dx:ax / ax and sub 1? avoids push/pop/moves to cx

push cx

mov  cx, dx
xchg  dx, ax
;xor  ax, ax 
div  ax     ; dx has remainder ax has result

xor dx, dx
dec ax

pop cx
retf

ENDP

PROC FixedDivWholeAB2_
PUBLIC FixedDivWholeAB2_

; AX:00:00 / DX:00  OR AX:00 / DX
; return in DX:AX
; works as long as AX > DX. NOT EQUAL because we cheat to avoid to push/pop..


xchg dx, ax
div  ax
dec  ax
xor dx, dx

retf

ENDP


; todo optimize. work around dx as the param,
; handle optims related to bx 0


PROC FixedDivWholeAB_
PUBLIC FixedDivWholeAB_


; AX:00 / DX:00
; return in DX:AX

; this is fixeddiv so we must do the whole labs14 check and word shift adjustment

push  cx
push  bx
push  bp
mov   bp, sp

mov   cx, dx
xor   bx, bx


; this is never called with params that trip labs 14 check. go directly to division


; todo inline
call div48_32_wholeAB_


LEAVE_MACRO
pop   bx
pop   cx

ret

endp






jmp shift_bits_wholeAB

;div48_32_wholeAB_
; basically, shift numerator left 16 and divide
; AX:00:00 / CX:00  (bx is 00)

PROC div48_32_wholeAB_
PUBLIC div48_32_wholeAB_

; di:si get shifted cx:bx



xor dx, dx


push  di



test ch, ch
jne shift_bits_wholeAB
; shift a wholeAB byte immediately

mov ch, cl
xor cl, cl

mov  dh, dl
mov dl, ah
mov ah, al
xor al, al

shift_bits_wholeAB:



; less than a byte to shift
; shift until MSB is 1

SAL CX, 1
JC done_shifting_wholeAB
SAL AX, 1
RCL DX, 1

SAL CX, 1
JC done_shifting_wholeAB  
SAL AX, 1
RCL DX, 1

SAL CX, 1
JC done_shifting_wholeAB  
SAL AX, 1
RCL DX, 1

SAL CX, 1
JC done_shifting_wholeAB  
SAL AX, 1
RCL DX, 1

SAL CX, 1
JC done_shifting_wholeAB  
SAL AX, 1
RCL DX, 1

SAL CX, 1
JC done_shifting_wholeAB  
SAL AX, 1
RCL DX, 1

SAL CX, 1
JC done_shifting_wholeAB  
SAL AX, 1
RCL DX, 1

SAL CX, 1






; store this
done_shifting_wholeAB:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1

 



; store these two long term...
; todo i think cx can be filtered out...
mov   di, cx
mov   ds, ax                    ; store copy of numhi.low




;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   di

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   bx, dx					; bx stores rhat
mov   es, ax     ; store qhat



q1_ready_wholeAB:

mov  ax, es
;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);


mov   cx, ax

; multiplying by DI:SI basically. inline SI in as BX.

;inlined FastMul16u32u_

MUL  DI        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX

; mul si
;xor  AX, AX
;CWD

MOV  DX, CX    ; add 

; actual 2nd division...


xor  ax, ax
mov   cx, ds
sbb   cx, dx
mov   dx, cx

cmp   dx, di

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow_wholeAB




div   di

mov   bx, ax
mov   cx, dx

; mul si
xor ax, ax
cwd

cmp   dx, cx

ja    continue_c1_c2_test_wholeAB
je    continue_check_wholeAB

do_return_2_wholeAB:
mov   dx, es      ; retrieve q1
mov   ax, bx

mov   cx, ss      ; restore ds
mov   ds, cx      
pop   di
ret  

continue_check_wholeAB:
cmp   ax, 0
jbe   do_return_2_wholeAB
continue_c1_c2_test_wholeAB:
sbb   dx, cx
cmp   dx, di
ja    do_qhat_subtraction_by_2_wholeAB
jne   do_qhat_subtraction_by_1_wholeAB
cmp   ax, 0

jbe   do_qhat_subtraction_by_1_wholeAB
do_qhat_subtraction_by_2_wholeAB:
dec   bx
do_qhat_subtraction_by_1_wholeAB:
dec   bx

jmp do_return_2_wholeAB




adjust_for_overflow_wholeAB:
xor   dx, dx
sub   ax, di
sbb   cx, dx

cmp   cx, di

; check for overflow param

jae   adjust_for_overflow_again_wholeAB

mov   dx, cx



div   di
mov   bx, ax
mov   cx, dx

; mul si
xor ax, ax
cwd

cmp   dx, cx
ja    continue_c1_c2_test_2_wholeAB
jne   dont_decrement_qhat_and_return_wholeAB
cmp   ax, 0
jbe   dont_decrement_qhat_and_return_wholeAB
continue_c1_c2_test_2_wholeAB:

sub   dx, cx
cmp   dx, di
ja    decrement_qhat_and_return_wholeAB
jne   dont_decrement_qhat_and_return_wholeAB
cmp   ax, 0
jbe   dont_decrement_qhat_and_return_wholeAB
decrement_qhat_and_return_wholeAB:
dec   bx
dont_decrement_qhat_and_return_wholeAB:
mov   ax, bx
mov   dx, es   ;retrieve q1
mov   cx, ss
mov   ds, cx
pop   di
ret  

; the divide would have overflowed. subtract values
adjust_for_overflow_again_wholeAB:

sub   ax, di
sbb   cx, dx
mov   dx, cx
div   di

; ax has its result...

mov   dx, es
mov   cx, ss
mov   ds, cx
pop   di
ret 





endp
@









END