
; note - do we want to do any quick-outs? (00 detection) or in cases where 00s are common, maybe call a different version...

PROC R_FixedMulLocal2_
PUBLIC R_FixedMulLocal2_


;AX:BX:CX:DX
;   times
;SS:SI (00 01 02 03)
;
; 
;BYTE
; RETURN VALUE
;       7       6       5       4       3       2       1		0
;       DONTUSE DONTUSE DONTUSE DONTUSE USE     USE     DONTUSE DONTUSE


; still need to ADC 1 into 2							
;                                                       DX00hi	DX00lo
;                                               CX00hi  CX00lo          
;                                       BX00hi  BX00lo                          
;                               AX00hi  AX00lo
;                                               DX02hi  DX02lo
;                                       CX02hi  CX02lo  
;                               BX02hi  BX02lo  
;                       
;                                       DX04hi  DX04lo
;                               CX04hi  CX04lo  
;                               DX06hi  DX06lo  
;                               
;                       
;       

 
                

;ax:bx:cx:dx
;SS:SI (00 01 02 03)
;      (06 04 02 00)
 
cli
push bp
push di

mov es, dx              ;       store  dx in es
mov dx, word ptr  ss:[si+00]    ;       retrieve 00
mov ds, dx              ;       store 00 in DS, will use it a lot. DS can be retrieved from SS later, DS = SS in this compilation model
mul dx                  ; AX00 - do this first because AX only used once, lets trash it here
mov di, ax              ;  di will accumulate high word result

mov ax, es              ;       restore DX from es
mul word ptr ss:[si+06] ; DX06 - do this next, 06 only used once...
add di, ax              ;  low word result into high word

mov ax, word ptr ss:[si+04]     ;       retrieve 04
mov bp, ax              ;       store 04 in bp, will use this once more...
mul cx                  ; CX04
add di, ax              ;  low word result into high word

; DI contains high word result
; SI points to the values
; BP is holding 04 (used once more)
; DS is holding 00 (used thrice more)
; ES is holding DX (used thrice more)
; BX holds BX
; CX holds CX
; lets use bp/04 and clear it out next

mov ax, es              
mul bp                  ; DX04
mov bp, ax              ;  bp now holds low word result
add di, dx              ;  high word result into high word (no carry needed yet as its the first low byte result)


mov dx, es				; get dx
mov ax, ds				; get 00
mul dx                  ; DX00

mov ax, word ptr ss:[si+02]     ;       retrieve 02
; si no longer used...
mov si, dx				;  put dx00 high word in si , now used as unreturned low word for adc carry into low word result
mov dx, es              ;       dx = dx, es no longer used
mov es, ax              ;       store 02 in es


mul dx                  ; DX02
add si, ax				;  add lower word to si
adc bp, dx              ;  high word result into low word
adc di, 0               ;  remember to add carry bit..




; DI contains high word result
; BP contains low word result
; SI points to the (unreturned) lower word result for adc into low word result
; DS is holding 00 (used twice more)
; ES is holding 02 (used twice more)
; BX holds BX (used twice more)
; CX holds CX (used twice more)

; remaining: CX02, CX00, BX02, BX00

mov ax, ds				; get 00
mul bx                  ; BX00
add bp, ax              ;  low word result into low word
adc di, dx              ;  high word result into high word

mov ax, es				; get 02
mul bx                  ; BX02
add di, ax              ;  low word result into high word

mov ax, ds				; get 00
mul cx                  ; CX00
add si, ax
adc bp, dx              ;  high word result into low word
adc di, 0               ;  remember to add carry bit..

mov ax, es				; get 02
mul cx                  ; CX02

; result into DX:AX
add ax, bp              ;  low word result into low word
adc dx, di              ;  high word result into high word


; end

pop di     ; restore di
pop bp     ; restore bp
mov cx, ss
mov ds, cx ; restore ds 
sti
retf


ENDP
 