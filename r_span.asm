;
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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

;=================================
.DATA




MAXLIGHTZ                      = 0080h
MAXLIGHTZ_UNSHIFTED            = 0800h




EXTRN FixedMul_:PROC



DS_XFRAC    = bp - 004h
DS_YFRAC    = bp - 008h
DS_XSTEP    = bp - 00Ch
DS_YSTEP    = bp - 010h


DS_XFRAC_INNER    = bp - 004h
DS_YFRAC_INNER    = bp - 008h
DS_XSTEP_INNER    = bp - 00Ch
DS_YSTEP_INNER    = bp - 010h



.CODE


;
; R_DrawSpan
;
	
PROC  R_DrawSpan_
PUBLIC  R_DrawSpan_ 

; stack vars
 
; _ss_variable_space
;
; 00h i (outer loop counter)
; 04h ds_xfrac
; 08h ds_yfrac
; 0Ch ds_xstep
; 10h ds_ystep

jmp start_function

no_pixels:
jmp   do_span_loop

start_function:
cli 									; disable interrupts

; fixed_t x32step = (ds_xstep << 6);

; todo move this logic out into prep function? 
mov   ax, SPANFUNC_JUMP_LOOKUP_SEGMENT
MOV   ES, ax

mov   al, byte ptr ds:[_spanfunc_main_loop_count]             
;; todo is this smaller with DI/stosb stuff?
mov   byte ptr es:[((SELFMODIFY_compare_span_counter+2) -R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )], al     ; set loop end constraint
mov   byte ptr es:[((SELFMODIFY_set_span_counter+1)     -R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )], 0      ; set loop increment value





; main loop start (i = 0, 1, 2, 3)

xor   bx, bx						; zero out cx as loopcount

span_i_loop_repeat:

xor   ah, ah

mov   al, byte ptr ds:[_spanfunc_inner_loop_count + bx]
; es is already pre-set..
inc   byte ptr es:[((SELFMODIFY_set_span_counter+1)-R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )]					; increment loop counter


test  al, al

; is count < 0? if so skip this loop iter

jl   no_pixels			; todo this so it doesnt loop in both cases

;       modify the jump for this iteration (self-modifying code)
sal   AL, 1					; convert index to  a word lookup index
xchg  ax, SI

; outp to plane only if there was a pixel to draw
mov   al, byte ptr ds:[_spanfunc_outp + bx]
mov   dx, 3c5h						; outp 1 << i
out   dx, al


lods  WORD PTR ES:[SI]	

mov  WORD PTR es:[((SPANFUNC_JUMP_OFFSET+1)-R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )], ax;

; 		dest = destview + ds_y * 80 + dsp_x1;
sal   bx, 1
mov   ax, word ptr ds:[_spanfunc_prt + bx]
mov   DI, word ptr ds:[_spanfunc_destview_offset + bx]  ; destview offset precalculated..


;		xfrac.w = basex = ds_xfrac + ds_xstep * prt;

CWD   				; extend sign into DX

;  DX:AX contains sign extended prt. 
;  probably dont really need this. can test ax and jge

mov   si, ax						; temporarily store dx:ax into es:si
mov   es, dx						; store sign bits (dx) in es
mov   bx, ax
mov   cx, dx						; also copy sign bits to cx
mov   ax, word ptr [DS_XSTEP_INNER]
mov   dx, word ptr [DS_XSTEP_INNER + 2]

; inline i4m
; DX:AX * CX:BX,  CX is 0000 or FFFF
 		xchg    ax,bx           ; swap low(M1) and low(M2)
        ; todo get rid of this push/pop..
		push    ax              ; save low(M2)
        xchg    ax,dx           ; exchange low(M2) and high(M1)
        or      ax,ax           ; if high(M1) non-zero
        je skiphigh11
          mul   dx              ; - low(M2) * high(M1)
        skiphigh11:                  ; endif
        xchg        ax,cx           ; save that in cx, get high(M2)
        test 	    ax,ax           ; if high(M2) non-zero
        je  skiphigh12              ; then
          sub   ax,bx              ; - high(M2) * low(M1)

;        xchg    ax,cx           ; save that in cx, get high(M2)
;        or      ax,ax           ; if high(M2) non-zero
;        je skiphigh12              ; then
;          mul   bx              ; - high(M2) * low(M1)
;          add   cx,ax           ; - add to total
        skiphigh12:                  ; endif
        pop     ax              ; restore low(M2)
        mul     bx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part

;	continuing	xfrac.w = basex = ds_xfrac + ds_xstep * prt;
;	DX:AX contains ds_xstep * prt


add   ax, word ptr [DS_XFRAC_INNER]	; load _ds_xfrac
mov   cx, es					; retrieve prt sign bits

adc   dx, word ptr [DS_XFRAC_INNER + 2]  ; ; ds_xfrac + ds_xstep * prt high bits

mov   dh, dl
mov   dl, ah
mov   es, dx  ; store mid 16 bits of x_frac.w
mov   bx, si

mov   ax, word ptr ds:[DS_YSTEP_INNER]
mov   dx, word ptr ds:[DS_YSTEP_INNER + 2]


;		yfrac.w = basey = ds_yfrac + ds_ystep * prt;

; inline i4m
; DX:AX * CX:BX,  CX is 0000 or FFFF

 		xchg    ax,bx           ; swap low(M1) and low(M2)
        push    ax              ; save low(M2)
        xchg    ax,dx           ; exchange low(M2) and high(M1)
        or      ax,ax           ; if high(M1) non-zero
        je skiphigh21              ; then
          mul   dx              ; - low(M2) * high(M1)
        skiphigh21:                  ; endif
        xchg        ax,cx           ; save that in cx, get high(M2)
        test 	    ax,ax           ; if high(M2) non-zero
        je  skiphigh22              ; then
          sub   ax,bx              ; - high(M2) * low(M1)

        skiphigh22:                  ; endif
        pop     ax              ; restore low(M2)
        mul     bx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part

;	continuing:	yfrac.w = basey = ds_yfrac + ds_ystep * prt;
; dx:ax contains ds_ystep * prt

; add 32 bits of ds_yfrac
mov   bx, ax
add   bx, word ptr [DS_YFRAC_INNER]	; load ds_yfrac
adc   dx, word ptr [DS_YFRAC_INNER + 2]

;	xfrac16.hu = xfrac.wu >> 8;


;	yfrac16.hu = yfrac.wu >> 10;

mov bl, bh
mov bh, dl   ; shift 8

sar dh, 1    ; shift two more
rcr bx, 1
sar dh, 1
rcr bx, 1    ; yfrac16 in bx



; shift 8, yadder in dh?

mov dx, es   ;  load mid 16 bits of x_frac.w


;	xadder = ds_xstep >> 6; 

mov   ax, word ptr [DS_XSTEP_INNER]
mov   cx, word ptr [DS_XSTEP_INNER + 2]


; quick shift 6
rol   ax, 1
rcl   cl, 1
rol   ax, 1
rcl   cl, 1

mov   al, ah
mov   ah, cl

; do loop setup here?

mov cl, byte ptr ds:[_detailshift]
shr ax, cl			; shift x_step by pixel shift
 

mov   word ptr ds:[_ss_variable_space], ax	; store x_adder

;	yadder = ds_ystep >> 8; // lopping off bottom 16 , but multing by 4.

mov   ax, word ptr ds:[DS_YSTEP_INNER + 1]



shr   ax, cl			; shift y_step by pixel shift
mov   word ptr ds:[_ss_variable_space + 2], ax	; y_adder



mov   es, word ptr ds:[_destview + 2]	; retrieve destview segment

; stack shenanigans. swap adders and sp/bp
; todo - this has got to be able to be improved somehow?

xchg  ds:[_ss_variable_space], sp             ;  store SP and load x_adder
xchg  ds:[_ss_variable_space+2], bp			  ;   store BP and load y_adder

mov   cx, bx  ; yfrac16
lds   bx, dword ptr ds:[_ds_source_segment-2] 		; ds:si is ds_source. BX is pulled in by lds as a constant 
;mov   bx, DRAWSPAN_BX_OFFSET

; we have a safe memory space declared in near variable space to put sp/bp values
; they meanwhile hold x_adder/y_adder and we juggle the two
; due to openwatcom compilation, SS = DS so we can use SS as if it were DS to address the var safely



xor   ah, ah

 
SPANFUNC_JUMP_OFFSET:
jmp span_i_loop_done         ; relative jump to be modified before function is called




; 89 C8       mov   ax, cx
; 21 D8       and   ax, bx
; 80 E6 3F    and   dh, 0x3f
; 00 F0       add   al, dh
; 97          xchg  ax, di

; alternate idea. one cycle slower and same byte count.
; cant we somehow make use of xchg and al, 3fh at the same time?

DRAW_SINGLE_SPAN_PIXEL MACRO 
mov   al, dh
and   al, 3fh
mov   si, cx
and   si, bx
add   si, ax
lods  BYTE PTR ds:[si]
xlat  BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
stos  BYTE PTR es:[di]       ;
add   dx, sp
add   cx, bp

ENDM

REPT 79
    DRAW_SINGLE_SPAN_PIXEL
endm

; final pixel

mov   al, dh
and   al, 3fh
mov   si, cx
and   si, bx
add   si, ax
lods  BYTE PTR ds:[si]
xlat  BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
stos  BYTE PTR es:[di]       ;


 
 

; restore stack
mov   ax, ss					;   SS is DS in this watcom memory model so we use that to restore DS
mov   ds, ax
xchg  ds:[_ss_variable_space], sp             ;  store SP and load x_adder
xchg  ds:[_ss_variable_space+2], bp			  ;   store BP and load y_adder

do_span_loop:

SELFMODIFY_set_span_counter:
mov   bx, 0

; loop if i < loopcount. note we can overwrite this with self modifying coe
SELFMODIFY_compare_span_counter:
cmp   bl, 4
jge    span_i_loop_done

mov   ax, SPANFUNC_JUMP_LOOKUP_SEGMENT
MOV   ES, ax

jmp   span_i_loop_repeat
span_i_loop_done:


sti								; reenable interrupts

retf  


ENDP




;
; R_DrawSpanPrep
;
	
PROC  R_DrawSpanPrep_
PUBLIC  R_DrawSpanPrep_ 

 
 ;  	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];

 les   bx, dword ptr ds:[_ds_y]
 add   bx, bx
 mov   ax, word ptr ds:[_destview]			; get FP_OFF(destview)
 mov   dx, word ptr es:[bx]				; get dc_yl_lookup[ds_y]

 add   dx, ax							; dx is baseoffset
 mov   es, word ptr ds:[_ds_x1]			; es holds ds_x1
	
; int8_t   shiftamount = (2-detailshift);
 mov   bh, byte ptr ds:[_detailshift2minus]		; get shiftamount in bh
 xor   bl, bl							; zero out bl. use it as loop counter/ i
 
 mov   word ptr ds:[_ss_variable_space], dx			; store base view offset
 
; todo the following  feels like extraneous register juggling, reexamine

 spanfunc_arg_setup_loop_start:
 mov   al, bl							; al holds loop counter
 mov   dx, es							; get ds_x1
 CBW  									; zero out ah
 mov   cl, bh							; move shiftamount to cl

;		int16_t dsp_x1 = (ds_x1 - i) >> shiftamount;
 sub   dx, ax							; subtract i 
 sar   dx, cl							; shift

; 		int16_t dsp_x2 = (ds_x2 - i) >> shiftamount;


 mov   di, word ptr ds:[_ds_x2]			; cx holds ds_x2
 sub   di, ax							; subtract i
 mov   si, ax							; put i in si
 
 mov   ax, dx							; copy dsp_x1 to ax
 
 shl   ax, cl							; shift dsp_x1 left
 sar   di, cl							; shift ds_x2 right. di = dsp_x2
 mov   cx, di							; store dsp_x2 in cx
 mov   di, es							; get ds_x1 into di

;		if ((dsp_x1 << shiftamount) + i < ds_x1)

 add   ax, si							; ax = (dsp_x1 << shiftamount) + i
 cmp   ax, di			; if si <  (dsp_x1 << shiftamount) + i

 jge   dont_increment_ds_x1     ; signed so carry flag adc 0 doesnt work?
;		ds_x1 ++
 
 inc   dx
 dont_increment_ds_x1:
 mov   al, bl							; al holds loop counter
 CBW  
 mov   si, ax							; store loop counter in si

 ; 		countp = dsp_x2 - dsp_x1;
 
;     cx has dsp_x2
 sub   cx, dx							; cx is countp

 mov   byte ptr [si + _spanfunc_inner_loop_count], cl  ; store it
 test  cx, cx										   ; if negative then loop
 jl    spanfunc_arg_setup_iter_done
 mov   cl, bh										   ; move shiftamount to cl
 
; 		spanfunc_prt[i] = (dsp_x1 << shiftamount) - ds_x1 + i;
;		spanfunc_destview_offset[i] = baseoffset + dsp_x1;

 
 mov   ax, dx										   ; move dsp_x1 to ax
 shl   ax, cl										   ; shift dsp_x1 left
 sub   ax, di										   ; subtract ds_x1
 add   ax, si										   ; add i, prt is calculated
 add   si, si										   ; double i for word lookup index
 add   dx, word ptr ds:[_ss_variable_space]						   ; dsp_x1 + base view offset
 mov   word ptr [si + _spanfunc_prt], ax			   ; store prt
 mov   word ptr [si + _spanfunc_destview_offset], dx   ; store view offset
 
 spanfunc_arg_setup_iter_done:
 
 inc   bl
 cmp   bl, byte ptr ds:[_spanfunc_main_loop_count]
 jl    spanfunc_arg_setup_loop_start
 
 spanfunc_arg_setup_complete:

 ; calculate desired cs:ip for far jump

 mov   ax, word ptr ds:[_ds_colormap_segment]
 mov   dl, byte ptr ds:[_ds_colormap_index]
 sub   ax, 0FCh
 test  dl, dl									; check _ds_colormap_index
 jne    ds_colormap_nonzero


 ; easy address calculation
 
; 		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));




mov   word ptr ds:[_spanfunc_farcall_addr_1+2], ax				; setup dynamic call segment. offset is static.

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _spanfunc_farcall_addr_1


 retf  
 ds_colormap_nonzero:									; if ds_colormap_index is 0
 

 
 
 
 ; colormap not zero. need to offset cs etc by its address

 ;		uint16_t ds_colormap_offset = ds_colormap_index << 8;
;		uint16_t ds_colormap_shift4 = ds_colormap_index << 4;
	 	
;		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset + ds_colormap_shift4;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset - ds_colormap_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

 
 mov   dh, dl
 xor   dl, dl
 mov   bx, DRAWSPAN_CALL_OFFSET
 sub   bx, dx
 IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shr   dx, 4
 ELSE
 shr   dx, 1
 shr   dx, 1
 shr   dx, 1
 shr   dx, 1
 ENDIF
 add   ax, dx

 
mov   word ptr ds:[_func_farcall_scratch_addr+0], bx				; setup dynamic call offset
mov   word ptr ds:[_func_farcall_scratch_addr+2], ax				; setup dynamic call segment

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _func_farcall_scratch_addr


 retf  

ENDP







PROC R_FixedMulTrigLocal_
PUBLIC R_FixedMulTrigLocal_

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

PROC R_FixedMulLocal_
PUBLIC R_FixedMulLocal_

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


;
; R_MapPlane_
; void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 )
; bp - 02h   distance low
; bp - 04h   distance high

;cachedheight   9000:0000
;yslope         9032:0000
;distscale      9064:0000
;cacheddistance 90B4:0000
;cachedxstep    90E6:0000
;cachedystep    9118:0000
; 	rather than changing ES a ton we will just modify offsets by segment distance
;   confirmed to be faster even on 8088 with it's baby prefetch queue - i think on 16 bit busses it is only faster.

PROC  R_MapPlane_
PUBLIC  R_MapPlane_ 

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 14h

xor   ah, ah
; set these values for drawspan while they are still in registers
mov   word ptr ds:[_ds_y], ax
mov   word ptr ds:[_ds_x1], dx
mov   word ptr ds:[_ds_x2], bx


xor   ah, ah
xchg  si, ax
mov   ax, CACHEDHEIGHT_SEGMENT			; base segment
mov   es, ax
mov   ax, word ptr ds:[_planeheight]
mov   dx, word ptr ds:[_planeheight + 2]
shl   si, 1
shl   si, 1
; CACHEDHEIGHT LOOKUP

cmp   ax, word ptr es:[si] ; compare low word
je    use_cached_values
go_generate_values:
jmp   generate_distance_steps
use_cached_values:

cmp   dx, word ptr es:[si+2]
jne   go_generate_values	; comparing high word


; CACHED DISTANCE lookup

mov   ax, word ptr es:[si + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, word ptr es:[si + 2 + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   di, dx					; store distance high word
push   ax	; store distance low word

; CACHEDXSTEP lookup


mov   ax, word ptr es:[si + (( CACHEDXSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, word ptr es:[si + 2 + (( CACHEDXSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   word ptr [DS_XSTEP], ax
mov   word ptr [DS_XSTEP+2], dx

; CACHEDYSTEP lookup


mov   ax, word ptr es:[si + (( CACHEDYSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, word ptr es:[si + 2 + (( CACHEDYSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   word ptr ds:[DS_YSTEP], ax
mov   word ptr ds:[DS_YSTEP+2], dx
distance_steps_ready:

; dx:ax is y_step
;     length = R_FixedMulLocal (distance,distscale[x1]);

mov   si, word ptr ds:[_ds_x1]		; grab x2 (function input)
mov   ax, DISTSCALE_SEGMENT
shl   si, 1
shl   si, 1						; dword lookup
mov   es, ax
mov   dx, di  				    ; distance high word
pop   ax   ; distance low word
push  dx   ; store distance high word in case needed for colormap
mov   bx, word ptr es:[si]		; distscale low word
mov   cx, word ptr es:[si + 2]	; distscale high word

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_


;	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);
; ds_xfrac = viewx.w + R_FixedMulLocal(finecosine[angle], length );

mov   bx, si
; todo bx + si below, reorder
shr   bx, 1		
xchg  di, ax			; store low word of length (product result)in di
mov   si, dx			; store high word of length  (product result) in si

les   ax, dword ptr ds:[_viewangle_shiftright3]
add   ax, word ptr es:[bx]		; ax is unmodded fine angle..
and   ah, 01Fh			; MOD_FINE_ANGLE mod high bits
push  ax            ; store fineangle

xchg  dx, ax			; fineangle in DX
mov   ax, FINECOSINE_SEGMENT

mov   bx, di			; length low word to DX
mov   cx, si			; length low word to DX

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal_

;    ds_yfrac = -viewy.w - R_FixedMulLocal(finesine[angle], length );

add   ax, word ptr ds:[_viewx]
adc   dx, word ptr ds:[_viewx+2]
mov   word ptr [DS_XFRAC], ax
mov   word ptr [DS_XFRAC+2], dx

mov   ax, FINESINE_SEGMENT
pop   dx              ; get fineangle
mov   cx, si					; prep length
mov   bx, di					; prep length

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal_

;    ds_yfrac = -viewy.w - R_FixedMulLocalWrapper(finesine[angle], length );

; let's instead add then take the negative of the whole

; add viewy
add   ax, word ptr ds:[_viewy]
adc   dx, word ptr ds:[_viewy+2]
; take negative of the whole
; apparently this is how you neg a dword. 
neg   dx
neg   ax
; i dont understand why this is here but the compiler did this. it works with or without, 
; probably too tiny an error to be visibly noticable?
sbb   dx, 0

mov   word ptr [DS_YFRAC], ax
mov   word ptr [DS_YFRAC+2], dx
mov   word ptr ds:[_ds_colormap_segment], COLORMAPS_SEGMENT


; 	if (fixedcolormap) {

cmp   byte ptr ds:[_fixedcolormap], 0
jne   use_fixed_colormap
; 		index = distance >> LIGHTZSHIFT;
pop   ax
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
sar   ax, 4
ELSE
sar   ax, 1
sar   ax, 1
sar   ax, 1
sar   ax, 1
ENDIF
;		if (index >= MAXLIGHTZ) {
;			index = MAXLIGHTZ - 1;
;		}



cmp   al, MAXLIGHTZ
jb    index_set
mov   al, MAXLIGHTZ - 1
index_set:

;		ds_colormap_segment = colormaps_segment;
;		ds_colormap_index = planezlight[index];

les    bx, dword ptr ds:[_planezlight]
xlat  byte ptr es:[bx]
colormap_ready:
mov   byte ptr ds:[_ds_colormap_index], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

db 09Ah
dw (R_DrawSpanPrep_ - R_DrawSpan_)
;dw SPANFUNC_PREP_OFFSET
dw SPANFUNC_FUNCTION_AREA_SEGMENT


LEAVE_MACRO

pop   di
pop   si
pop   cx
retf  

use_fixed_colormap:
mov   al, byte ptr ds:[_fixedcolormap]
mov   byte ptr ds:[_ds_colormap_index], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

db 09Ah
dw (R_DrawSpanPrep_ - R_DrawSpan_)
;dw SPANFUNC_PREP_OFFSET
dw SPANFUNC_FUNCTION_AREA_SEGMENT


LEAVE_MACRO
pop   di
pop   si
pop   cx
retf  

generate_distance_steps:

; es = 9000h  (CACHEDHEIGHT_SEGMENT)
; dx:ax = planeheight segment
; note: es wrecked by function calls to r_fixedmullocal...



mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx   ; cachedheight into dx
mov   bx, word ptr es:[si + (( YSLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   cx, word ptr es:[si + 2 + (( YSLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]


; not worth continuing to LEA because fixedmul destroys ES and then we have to store and restore from SI which is too much extra time
; distance = cacheddistance[y] = R_FixedMulLocal (planeheight, yslope[y]);

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

; result is distance
mov   bx, CACHEDDISTANCE_SEGMENT
mov   es, bx
mov   bx, word ptr ds:[_basexscale]
mov   cx, word ptr ds:[_basexscale+2]
mov   word ptr es:[si], ax			; store distance
mov   word ptr es:[si + 2], dx		; store distance
mov   di, dx						; store distance high word in di
push  ax  ; distance low word

; 		ds_xstep = cachedxstep[y] = (R_FixedMulLocal (distance,basexscale));

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, CACHEDXSTEP_SEGMENT
mov   es, bx
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx
mov   word ptr [DS_XSTEP], ax
mov   word ptr [DS_XSTEP+2], dx
mov   dx, di
mov   bx, word ptr ds:[_baseyscale]
mov   cx, word ptr ds:[_baseyscale+2]
; cant pop - used once more later
mov   ax, word ptr [bp - 02h]	; retrieve distance low word

;		ds_ystep = cachedystep[y] = (R_FixedMulLocal (distance,baseyscale));

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, CACHEDYSTEP_SEGMENT
mov   es, bx
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx
mov   word ptr ds:[DS_YSTEP], ax
mov   word ptr ds:[DS_YSTEP+2], dx
jmp   distance_steps_ready

   

ENDP

END