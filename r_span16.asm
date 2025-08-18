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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO 

;=================================

.CODE

PROC R_SPAN16_STARTMARKER_
PUBLIC R_SPAN16_STARTMARKER_
ENDP 


R_DRAWSPANACTUAL_DIFF = (OFFSET R_DrawSpanActual16_ - OFFSET R_SPAN16_STARTMARKER_)
DRAWSPAN_BX_OFFSET             = 0FC0h
DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_JUMP_LOOKUP_SEGMENT - COLORMAPS_SEGMENT)) + DRAWSPAN_BX_OFFSET

; lcall cs:[00xx] here to call R_DrawSpan with the right CS:IP for colormaps to be at cs:3F00
_spanfunc_call_table:

dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00000h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0000h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00100h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0010h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00200h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0020h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00300h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0030h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00400h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0040h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00500h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0050h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00600h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0060h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00700h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0070h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00800h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0080h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00900h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0090h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00A00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 00A0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00B00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 00B0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00C00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 00C0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00D00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 00D0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00E00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 00E0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 00F00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 00F0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01000h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0100h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01100h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0110h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01200h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0120h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01300h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0130h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01400h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0140h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01500h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0150h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01600h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0160h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01700h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0170h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01800h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0180h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01900h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0190h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01A00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 01A0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01B00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 01B0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01C00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 01C0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01D00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 01D0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01E00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 01E0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 01F00h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 01F0h
dw (DRAWSPAN_CALL_OFFSET + R_DRAWSPANACTUAL_DIFF) - 02000h,  (COLORMAPS_SEGMENT - (DRAWSPAN_BX_OFFSET SHR 4)) + 0200h


_spanfunc_jump_target:
dw 0058Eh, 0057Ch, 0056Ah, 00558h, 00546h, 00534h, 00522h, 00510h, 004FEh, 004ECh
dw 004DAh, 004C8h, 004B6h, 004A4h, 00492h, 00480h, 0046Eh, 0045Ch, 0044Ah, 00438h
dw 00426h, 00414h, 00402h, 003F0h, 003DEh, 003CCh, 003BAh, 003A8h, 00396h, 00384h
dw 00372h, 00360h, 0034Eh, 0033Ch, 0032Ah, 00318h, 00306h, 002F4h, 002E2h, 002D0h
dw 002BEh, 002ACh, 0029Ah, 00288h, 00276h, 00264h, 00252h, 00240h, 0022Eh, 0021Ch
dw 0020Ah, 001F8h, 001E6h, 001D4h, 001C2h, 001B0h, 0019Eh, 0018Ch, 0017Ah, 00168h
dw 00156h, 00144h, 00132h, 00120h, 0010Eh, 000FCh, 000EAh, 000D8h, 000C6h, 000B4h
dw 000A2h, 00090h, 0007Eh, 0006Ch, 0005Ah, 00048h, 00036h, 00024h, 00012h, 00000h

MAXLIGHTZ                      = 0080h
MAXLIGHTZ_UNSHIFTED            = 0800h









FIRST_FLAT_CACHE_LOGICAL_PAGE = 026h


; NOTE: cs:offset stuff for self modifying code must be zero-normalized
;  (subtract offset of R_DrawSpan) because this code is being moved to
; segment:0000 at runtime and the cs offset stuff is absolute, not relative.



;
; R_DrawSpan
;
PROC  R_DrawSpan16_ 
PUBLIC  R_DrawSpan16_ 
	
; need to include these 2 instructions, and need a function label to include this...

no_pixels:
jmp   do_span_loop

ENDP ; shut up compiler warning

PROC  R_DrawSpanActual16_

; stack vars
 
; _ss_variable_space
;
; 00h i (outer loop counter)
; 04h ds_xfrac
; 08h ds_yfrac
; 0Ch ds_xstep
; 10h ds_ystep



cli 									; disable interrupts because we use bp/sp here. (sigh)


; fixed_t x32step = (ds_xstep << 6);

; todo move this logic out into prep function? could use cs instead of generating
; todo LES something useful?
MOV   es, ds:[_spanfunc_jump_segment_storage]


; store sp/bp
; todo push bp but store sp this way.

mov   word ptr es:[((SELFMODIFY_SPAN_sp_storage+1) - R_SPAN16_STARTMARKER_   )], sp
mov   word ptr es:[((SELFMODIFY_SPAN_bp_storage+1) - R_SPAN16_STARTMARKER_   )], bp


; setup x_adder/y_adder now
;	xadder = ds_xstep >> 6; 
;preshifted by 6
SELFMODIFY_SPAN_ds_xstep_lo_2:
mov   sp, 01000h	; store x_adder


;	yadder = ds_ystep >> 8; // lopping off bottom 16 , but multing by 4.


SELFMODIFY_SPAN_ds_ystep_mid:
mov   bp, 01000h	; y_adder
;preshifted outside.


mov   byte ptr es:[((SELFMODIFY_SPAN_set_span_counter+1) - OFFSET R_SPAN16_STARTMARKER_   )], 0      ; set loop increment value





; main loop start (i = 0, 1, 2, 3)

xor   bx, bx						; zero out cx as loopcount

span_i_loop_repeat:


mov   al, byte ptr ds:[_spanfunc_inner_loop_count + bx]
; es is already pre-set..
inc   byte ptr es:[((SELFMODIFY_SPAN_set_span_counter+1) -  OFFSET R_SPAN16_STARTMARKER_   )]					; increment loop counter


test  al, al

; is count < 0? if so skip this loop iter

jl   no_pixels			; todo this so it doesnt loop in both cases
cbw

;       modify the jump for this iteration (self-modifying code)
sal   AL, 1					; convert index to  a word lookup index
xchg  ax, SI

; outp to plane only if there was a pixel to draw
mov   al, byte ptr ds:[_spanfunc_outp + bx]
mov   dx, SC_DATA						; outp 1 << i
out   dx, al


mov   ax, word ptr es:[si + _spanfunc_jump_target - OFFSET R_SPAN16_STARTMARKER_ ]	    ; get unrolled jump count.
; write to the unrolled loop jump instruction.
mov   WORD PTR es:[((SPANFUNC_JUMP_OFFSET+1)- OFFSET R_SPAN16_STARTMARKER_   )], ax;

; 		dest = destview + ds_y * 80 + dsp_x1;
sal   bx, 1
;    todo use si instead of bx and lodsw.
mov   ax, word ptr ds:[_spanfunc_prt + bx]
; BX is preserved for a while here. this allows us to calculate DI (big instruction) after a mul
; finally load di using bx
mov   DI, word ptr ds:[_spanfunc_destview_offset + bx]  ; destview offset precalculated..

;		xfrac.w = basex = ds_xfrac + ds_xstep * prt;


;  DX:AX contains sign extended prt. 
;  probably dont really need this. can test ax and jge
; bx free here...
; es too... 
mov   si, ax						; temporarily store dx:ax into es:si
SELFMODIFY_SPAN_ds_xstep_hi_1:
mov   dx, 01000h

; inline i4m
; note these registers have all been shuffled around from the original version  which was wasteful but as a result it got hard to read.
; we dont seem to shuffle by the sign extend anymore but it also doesnt seem to matter.? todo revisit

        mul     dx              ; - low(M2) * high(M1)
        mov     cx, ax           ; save that in cx
SELFMODIFY_SPAN_ds_xstep_lo_1:
        mov     dx, 01000h        ; pre xchged bx ax

        mov     ax, si
        mul     dx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part

;	continuing	xfrac.w = basex = ds_xfrac + ds_xstep * prt;
;	DX:AX contains ds_xstep * prt


SELFMODIFY_SPAN_ds_xfrac_lo:
add   ax, 01000h	; load _ds_xfrac
; dh is choped off anyway so just add to dl.
SELFMODIFY_SPAN_ds_xfrac_hi:
adc   dl, 010h  ; ; ds_xfrac + ds_xstep * prt high bits

mov   dh, dl
mov   dl, ah
mov   es, dx  ; store mid 16 bits of x_frac.w
mov   ax, si

SELFMODIFY_SPAN_ds_ystep_hi:
mov   dx, 01000h


;		yfrac.w = basey = ds_yfrac + ds_ystep * prt;

; inline i4m
        mul     dx              ; - low(M2) * high(M1)
        mov     cx, ax           ; save that in cx
        SELFMODIFY_SPAN_ds_ystep_lo:
        mov     dx, 01000h

        mov     ax, si
        mul     dx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part

;	continuing:	yfrac.w = basey = ds_yfrac + ds_ystep * prt;
; dx:ax contains ds_ystep * prt



; add 32 bits of ds_yfrac
SELFMODIFY_SPAN_ds_yfrac_lo:
add   ax, 01000h
mov   cx, ax
SELFMODIFY_SPAN_ds_yfrac_hi:
adc   dl, 010h

; cant preshift cause its the sum

;	xfrac16.hu = xfrac.wu >> 8;


;	yfrac16.hu = yfrac.wu >> 10;

mov cl, ch
mov ch, dl   ; shift 8

sar dh, 1    ; shift two more
rcr cx, 1
sar dh, 1
rcr cx, 1    ; yfrac16 in cx


; shift 8, yadder in dh?

mov dx, es   ;  get back mid 16 bits of x_frac.w





; todo LES something here dunno?
mov   es, word ptr ds:[_destview + 2]	; retrieve destview segment



; yfrac16 already in cx

lds   bx, dword ptr ds:[_ds_source_segment] 		; ds:si is ds_source. BX is pulled in by lds as a constant (DRAWSPAN_BX_OFFSET)



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


 
 

; restore ds
mov   ax, ss					;   SS is DS in this watcom memory model so we use that to restore DS
mov   ds, ax


do_span_loop:

SELFMODIFY_SPAN_set_span_counter:
mov   bx, 0

; loop if i < loopcount. note we can overwrite this with self modifying coe
SELFMODIFY_SPAN_compare_span_counter:
cmp   bl, 4
jge    span_i_loop_done

MOV   ES, ds:[_spanfunc_jump_segment_storage]

jmp   span_i_loop_repeat
span_i_loop_done:

; restore sp, bp
SELFMODIFY_SPAN_sp_storage:
mov sp, 01000h
SELFMODIFY_SPAN_bp_storage:
mov bp, 01000h


sti								; reenable interrupts

retf  


ENDP




;
; R_DrawSpanPrep
;
	
PROC  R_DrawSpanPrep16_ NEAR

 
 ;  	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];

; predoubles _ds_y for lookup
 les   bx, dword ptr ds:[_ds_y]
 
 mov   ax, word ptr es:[bx]				; get dc_yl_lookup[ds_y]
SELFMODIFY_SPAN_destview_lo_1:
 add   ax, 01000h
 mov   es, word ptr [bp - 0Ah]			; es holds ds_x1
	
 xor   bl, bl							; zero out bl. use it as loop counter/ i
 ; todo carry this forward
 mov   word ptr cs:[SELFMODIFY_SPAN_destview_add+2 - OFFSET R_SPAN16_STARTMARKER_], ax			; store base view offset
 
; todo the following  feels like extraneous register juggling, reexamine

 spanfunc_arg_setup_loop_start:
 mov   al, bl							; al holds loop counter
 mov   dx, es							; get ds_x1
 CBW  									; zero out ah
 
;		int16_t dsp_x1 = (ds_x1 - i) >> shiftamount;
 sub   dx, ax							; subtract i 
 SELFMODIFY_SPAN_detailshift2minus_1:
 sar   dx, 1							; shift
 sar   dx, 1							; shift

; 		int16_t dsp_x2 = (ds_x2 - i) >> shiftamount;

SELFMODIFY_SPAN_ds_x2:
 mov   cx, word ptr [bp - 0Ch]		        ; cx holds ds_x2
 sub   cx, ax							; subtract i
 mov   si, ax							; put i in si
 
 mov   ax, dx							; copy dsp_x1 to ax
 
 SELFMODIFY_SPAN_detailshift2minus_2:
 shl   ax, 1							; shift dsp_x1 left
 shl   ax, 1							; shift dsp_x1 left
 SELFMODIFY_SPAN_detailshift2minus_3:
 sar   cx, 1							; shift ds_x2 right. di = dsp_x2
 sar   cx, 1							; shift ds_x2 right. di = dsp_x2
 
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

 mov   byte ptr ds:[si + _spanfunc_inner_loop_count], cl  ; store it
 test  cx, cx										   ; if negative then loop
 jl    spanfunc_arg_setup_iter_done
 
; 		spanfunc_prt[i] = (dsp_x1 << shiftamount) - ds_x1 + i;
;		spanfunc_destview_offset[i] = baseoffset + dsp_x1;

 
 mov   ax, dx										   ; move dsp_x1 to ax
 SELFMODIFY_SPAN_detailshift2minus_4:
 shl   ax, 1										   ; shift dsp_x1 left
 shl   ax, 1
 sub   ax, di										   ; subtract ds_x1
 add   ax, si										   ; add i, prt is calculated
 add   si, si										   ; double i for word lookup index
 SELFMODIFY_SPAN_destview_add:
 add   dx, 01000h						   ; dsp_x1 + base view offset
 mov   word ptr ds:[si + _spanfunc_prt], ax			   ; store prt
 mov   word ptr ds:[si + _spanfunc_destview_offset], dx   ; store view offset
 
 spanfunc_arg_setup_iter_done:
 
 inc   bl
 
 SELFMODIFY_SPAN_detailshift_mainloopcount_2:
 cmp   bl, 0
 jl    spanfunc_arg_setup_loop_start
 
 spanfunc_arg_setup_complete:

 ; use jump table with desired cs:ip for far jump


db 02Eh  ; cs segment override
db 0FFh  ; lcall[addr]
db 01Eh  ;
SELFMODIFY_SPAN_set_colormap_index_jump:
dw 0000h
; addr 0000 + first byte (4x colormap.)



ret  

ENDP







PROC R_FixedMulTrigLocal16_

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

; DWORD lookup index
SHIFT_MACRO sal dx 2

mov si, dx

mov ds, ax  ; cosine/sine segment in ds
lodsw
mov  es, ax
lodsw
mov  dx, ax ; store sign bits in DX

AND AX, BX  ; S0*BX
NEG AX
MOV SI, AX  ; SI stores hi word return

mov AX, DX  ; restore sign bits from dx

AND  AX, CX    ; DX*CX
NEG  AX
add  SI, AX    ; low word result into high word return
; use DX copy of sign bits later..

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

PROC R_FixedMulLocal16_

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

go_generate_values:
jmp   generate_distance_steps

;
; R_MapPlane16_
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



PROC  R_MapPlane16_ NEAR

push  cx
push  si
push  di
push  es
push  dx




mov  si, di
; si is x * 4
mov   es, ds:[_cachedheight_segment_storage]

mov   ax, word ptr [bp - 010h]
mov   dx, word ptr [bp - 0Eh]
; TODO: do this shl outside of the function. borrow from es:di lookup's di
shl   si, 1
; CACHEDHEIGHT LOOKUP

cmp   ax, word ptr es:[si] ; compare low word
jne   go_generate_values

cmp   dx, word ptr es:[si+2]
jne   go_generate_values	; comparing high word


; CACHED DISTANCE lookup
use_cached_values:

les   ax, dword ptr es:[si + 0 + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, es

push  ax
; CACHEDXSTEP lookup. move these into temporary variable space

mov   es, ds:[_cachedxstep_segment_storage]
lods  word ptr es:[si]
mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax
xchg  ax, cx
lods  word ptr es:[si]
mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep_hi_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax

; shift 6 and juggle. (take mid 16 into ax after shifting ax:cl left 6.)
shl   cx, 1
rcl   al, 1
shl   cx, 1
rcl   al, 1

mov   ah, al
mov   al, ch

; do loop setup here?

SELFMODIFY_SPAN_detailshift_3:
mov ax, ax
mov ax, ax

mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep_lo_2+1 - OFFSET R_SPAN16_STARTMARKER_], ax



sub   si, 4
; CACHEDYSTEP lookup
mov   es, ss:[_cachedystep_segment_storage]
lods  word ptr es:[si]
mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep_lo+1 - OFFSET R_SPAN16_STARTMARKER_], ax
mov   bl, ah
lods  word ptr es:[si]
mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep_hi+1 - OFFSET R_SPAN16_STARTMARKER_], ax
mov   bh, al
SELFMODIFY_SPAN_detailshift_4:
mov ax, ax
mov ax, ax
mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep_mid+1 - OFFSET R_SPAN16_STARTMARKER_], bx




pop ax ; restore distance low word


distance_steps_ready:
;dx:ax is already distance going in

; dx:ax is y_step
;     length = R_FixedMulLocal (distance,distscale[x1]);

mov   si, word ptr [bp - 0Ah]		; grab x2 (function input)

shl   si, 1						; word lookup
mov   bx, si          ; dword lookup if we add them
mov   es, ds:[_distscale_segment_storage]
;todo bench without bx + si + 2 - sar again later etc.
push  dx   ; store distance high word in case needed for colormap
les   bx, dword ptr es:[bx + si]		; distscale low word
mov   cx, es                                   	; distscale high word

call R_FixedMulLocal16_


;	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);
; ds_xfrac = viewx.w + R_FixedMulLocal(finecosine[angle], length );

xchg  bx, ax			; store low word of length (product result)in bx
mov   cx, dx			; store high word of length  (product result) in cx

les   ax, dword ptr ds:[_viewangle_shiftright3]
add   ax, word ptr es:[si]		; ax is unmodded fine angle.. si is a word lookup
and   ah, 01Fh			; MOD_FINE_ANGLE mod high bits
push  ax            ; store fineangle

xchg  dx, ax			; fineangle in DX
mov   ax, FINECOSINE_SEGMENT

mov   di, bx			; backup low word to DX
mov   si, cx			; backup high word

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal16_

;    ds_yfrac = -viewy.w - R_FixedMulLocal(finesine[angle], length );

SELFMODIFY_SPAN_viewx_lo_1:
add   ax, 01000h
SELFMODIFY_SPAN_viewx_hi_1:
adc   dx, 01000h
mov   word ptr cs:[SELFMODIFY_SPAN_ds_xfrac_lo+1 - OFFSET R_SPAN16_STARTMARKER_], ax
mov   byte ptr cs:[SELFMODIFY_SPAN_ds_xfrac_hi+2 - OFFSET R_SPAN16_STARTMARKER_], dl

mov   ax, FINESINE_SEGMENT
pop   dx              ; get fineangle
mov   cx, si					; prep length
mov   bx, di					; prep length

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal16_

;    ds_yfrac = -viewy.w - R_FixedMulLocalWrapper(finesine[angle], length );

; let's instead add then take the negative of the whole

; add viewy
SELFMODIFY_SPAN_viewy_lo_1:
add   ax, 01000h
SELFMODIFY_SPAN_viewy_hi_1:
adc   dx, 01000h

neg   dx
neg   ax
; - sqpat 12/30/24  read below, i used to be so dumb.

; i dont understand why this is here but the compiler did this. it works with or without, 
; probably too tiny an error to be visibly noticable?
sbb   dx, 0

mov   word ptr cs:[SELFMODIFY_SPAN_ds_yfrac_lo+1 - OFFSET R_SPAN16_STARTMARKER_], ax
mov   byte ptr cs:[SELFMODIFY_SPAN_ds_yfrac_hi+2 - OFFSET R_SPAN16_STARTMARKER_], dl

pop   ax  ; for stack consistency across branches, this pop is done here.

; 	if (fixedcolormap) {

SELFMODIFY_SPAN_fixedcolormap_1:
mov   ax, ax
SELFMODIFY_SPAN_fixedcolormap_1_AFTER:
; 		index = distance >> LIGHTZSHIFT;


SHIFT_MACRO sar ax 4


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
; mov  al, byte ptr cs:[bx + _cs_zlight_offset]
colormap_ready:

mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump - OFFSET R_SPAN16_STARTMARKER_], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep16_


pop   dx
pop   es
pop   di
pop   si
pop   cx
ret

SELFMODIFY_SPAN_fixedcolormap_1_TARGET:
SELFMODIFY_SPAN_fixedcolormap_2:
use_fixed_colormap:
mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump - OFFSET R_SPAN16_STARTMARKER_], 00

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep16_


pop   dx
pop   es
pop   di
pop   si
pop   cx
ret  

generate_distance_steps:

; es = 5000h  (CACHEDHEIGHT_SEGMENT)
; dx:ax = planeheight segment
; note: es wrecked by function calls to r_fixedmullocal...

mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx   ; cachedheight into dx
les   bx, dword ptr es:[si + 0 (( YSLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   cx, es


; not worth continuing to LEA because fixedmul destroys ES and then we have to store and restore from SI which is too much extra time
; distance = cacheddistance[y] = R_FixedMulLocal (planeheight, yslope[y]);

call R_FixedMulLocal16_

; result is distance
mov   es, ds:[_cacheddistance_segment_storage]
SELFMODIFY_SPAN_basexscale_lo_1:
mov   bx, 01000h
SELFMODIFY_SPAN_basexscale_hi_1:
mov   cx, 01000h
mov   word ptr es:[si], ax			; store distance
mov   word ptr es:[si + 2], dx		; store distance
mov   di, dx						; store distance high word in di
push  ax  ; distance low word

; 		ds_xstep = cachedxstep[y] = (R_FixedMulLocal (distance,basexscale));

call R_FixedMulLocal16_

mov   es, ds:[_cachedxstep_segment_storage]
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx

mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep_hi_1+1 - OFFSET R_SPAN16_STARTMARKER_], dx


; shift 6 and juggle
shl   ax, 1
rcl   dl, 1
shl   ax, 1
rcl   dl, 1

mov   al, ah
mov   ah, dl

; do loop setup here?

SELFMODIFY_SPAN_detailshift_1:
mov ax, ax			; shift x_step by pixel shift
mov ax, ax			; shift x_step by pixel shift

mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep_lo_2+1 - OFFSET R_SPAN16_STARTMARKER_], ax


mov   dx, di
SELFMODIFY_SPAN_baseyscale_lo_1:
mov   bx, 01000h
SELFMODIFY_SPAN_baseyscale_hi_1:
mov   cx, 01000h

pop ax  ; retrieve low distance word
push ax

;		ds_ystep = cachedystep[y] = (R_FixedMulLocal (distance,baseyscale));

call R_FixedMulLocal16_

mov   es, ds:[_cachedystep_segment_storage]
; todo turn into stosw here and above?
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx

mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep_lo+1 - OFFSET R_SPAN16_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep_hi+1 - OFFSET R_SPAN16_STARTMARKER_], dx
mov   al, ah
mov   ah, dl
SELFMODIFY_SPAN_detailshift_2:
mov ax, ax
mov ax, ax
mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep_mid+1 - OFFSET R_SPAN16_STARTMARKER_], ax


pop   ax
mov   dx, di  				    ; distance high word
jmp   distance_steps_ready

   

ENDP


;R_DrawPlanes_

PROC R_DrawPlanes16_
PUBLIC R_DrawPlanes16_ 


; ARGS none

; STACK
; bp - 10h planeheight lo
; bp - 0Eh planeheight hi
; bp - 0Ch ds_x2
; bp - 0Ah ds_x1
; bp - 8 visplaneoffset
; bp - 6 visplanesegment
; bp - 4 usedflatindex
; bp - 3 usedflatindex AND 3
; bp - 2 physindex

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 10h
xor   ax, ax
mov   word ptr [bp - 8], ax
mov   word ptr [bp - 6], FIRST_VISPLANE_PAGE_SEGMENT   ; todo make constant visplane segment
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 2], ax

; inline R_WriteBackSpanFrameConstants_
; get whole dword at the end here.

; lodsw, push pop si worth?
mov   si, _basexscale
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_basexscale_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_basexscale_hi_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax

lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_baseyscale_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_baseyscale_hi_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax

lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewx_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewx_hi_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax

lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewy_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewy_hi_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax

lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewz_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewz_hi_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax

mov   ax, word ptr ds:[_destview+0]
mov   word ptr cs:[SELFMODIFY_SPAN_destview_lo_1+1 - OFFSET R_SPAN16_STARTMARKER_], ax

mov   al, byte ptr ds:[_extralight]
mov   byte ptr cs:[SELFMODIFY_SPAN_extralight_1+1 - OFFSET R_SPAN16_STARTMARKER_], al


mov   al, byte ptr ds:[_fixedcolormap]
test  al, al 
jne   do_span_fixedcolormap_selfmodify
mov   ax, 0c089h  ; nop
jmp   done_with_span_fixedcolormap_selfmodify

do_next_drawplanes_loop:	

inc   byte ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPAN16_STARTMARKER_]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop
do_sky_flat_draw:
; todo revisit params. maybe these can be loaded in R_DrawSkyPlaneCallHigh
les   bx, dword ptr [bp - 8] ; get visplane offset
mov   cx, es ; and segment
les   ax, dword ptr ds:[si + 4]
mov   dx, es
;call  [_R_DrawSkyPlaneCallHigh]
SELFMODIFY_SPAN_draw_skyplane_call:
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_DrawSkyPlane_addr
inc   byte ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPAN16_STARTMARKER_]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop

exit_drawplanes:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
mov   byte ptr cs:[(SELFMODIFY_SPAN_drawplaneiter+1) - OFFSET R_SPAN16_STARTMARKER_], 0
retf   
do_span_fixedcolormap_selfmodify:
mov   byte ptr cs:[SELFMODIFY_SPAN_fixedcolormap_2 + 5 - OFFSET R_SPAN16_STARTMARKER_], al
mov   ax, ((SELFMODIFY_SPAN_fixedcolormap_1_TARGET - SELFMODIFY_SPAN_fixedcolormap_1_AFTER) SHL 8) + 0EBh
; fall thru
done_with_span_fixedcolormap_selfmodify:
; modify instruction
mov   word ptr cs:[SELFMODIFY_SPAN_fixedcolormap_1 - OFFSET R_SPAN16_STARTMARKER_], ax








mov       ax, OFFSET _R_DrawSkyPlane_addr
cmp       byte ptr ds:[_screenblocks], 10
jge       setup_dynamic_skyplane
mov       ax, OFFSET _R_DrawSkyPlaneDynamic_addr
setup_dynamic_skyplane:
mov       word ptr cs:[SELFMODIFY_SPAN_draw_skyplane_call + 2 - OFFSET R_SPAN16_STARTMARKER_], ax




drawplanes_loop:
SELFMODIFY_SPAN_drawplaneiter:
mov   ax, 0 ; get i value. this is at the start of the function so its hard to self modify. so we reset to 0 at the end of the function
cmp   ax, word ptr ds:[_lastvisplane]
jge   exit_drawplanes
SHIFT_MACRO shl ax 3


add   ax, offset _visplaneheaders
; todo lea si bx + _visplaneheaders
mov   si, ax
mov   ax, word ptr ds:[si + 4]			; fetch visplane minx
cmp   ax, word ptr ds:[si + 6]			; fetch visplane maxx
jnle   do_next_drawplanes_loop

loop_visplane_page_check:
cmp   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
jnb   check_next_visplane_page


; todo: DI is (mostly) unused here. Can probably be used to hold something usedful.

mov   bx, word ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPAN16_STARTMARKER_]

add   bx, bx
mov   cx, word ptr ds:[bx +  _visplanepiclights]
SELFMODIFY_SPAN_skyflatnum:
cmp   cl, 0
je    do_sky_flat_draw

do_nonsky_flat_draw:

mov   byte ptr cs:[SELFMODIFY_SPAN_lookuppicnum+2 - OFFSET R_SPAN16_STARTMARKER_], cl 
mov   al, ch
xor   ah, ah

SHIFT_MACRO sar ax LIGHTSEGSHIFT


SELFMODIFY_SPAN_extralight_1:
add   al, 0
cmp   al, LIGHTLEVELS
jb    lightlevel_in_range
mov   al, LIGHTLEVELS-1
lightlevel_in_range:
; ah is 0
; shift 7
xchg  al, ah
sar   ax, 1



mov   word ptr ds:[_planezlight], ax
;mov   word ptr ds:[_planezlight + 2], ZLIGHT_SEGMENT  ; this is static and set in memory.asm

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   ax, FLATINDEX_SEGMENT
mov   es, ax

mov   al, byte ptr es:[bx]
; going to use di to hold flatunloaded
xor   di, di
cmp   al, 0ffh
jne   flat_loaded
mov   bx, di
loop_find_flat:
cmp   byte ptr ds:[bx + _allocatedflatsperpage], 4   ; if (allocatedflatsperpage[j]<4){
jl    found_page_with_empty_space
inc   bl
cmp   bl, NUM_FLAT_CACHE_PAGES
jge   found_flat_page_to_evict
jmp   loop_find_flat

check_next_visplane_page:
; do next visplane page
sub   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
inc   byte ptr [bp - 2]
cmp   byte ptr [bp - 2], 3
je    do_visplane_pagination
lookup_visplane_segment:
mov   bx, word ptr [bp - 2]
add   bx, bx
mov   ax, word ptr ds:[bx + _visplanelookupsegments]
mov   word ptr [bp - 6], ax
jmp   loop_visplane_page_check
do_visplane_pagination:
mov   al, byte ptr ds:[_visplanedirty]
add   al, 3
mov   dx, 2
cbw  
mov   byte ptr [bp - 2], 2



call  Z_QuickMapVisplanePage_SpanLocal16_


jmp   lookup_visplane_segment




found_page_with_empty_space:

mov   al, bl ; bl is usedflatindex
SHIFT_MACRO shl al 2


mov   ah, byte ptr ds:[bx + _allocatedflatsperpage]
add   al, ah
inc   byte ptr ds:[bx + _allocatedflatsperpage]
found_flat:
; al is usedflatindex
mov   di, FLATTRANSLATION_SEGMENT
mov   es, di
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   di, FLATINDEX_SEGMENT
mov   es, di

; di already nonzero
;mov   di, 1 ; update flat unloaded

mov   byte ptr es:[bx], al	; flatindex[flattranslation[piclight.bytes.picnum]] = usedflatindex;

; check l2 cache next
flat_loaded:
; ah is already set above..
mov   ah, al
and   ah, 3
mov   word ptr [bp - 4], ax     ; store usedflatindex only once, along with AND 3 of it

; al is guaranteed usedflatindex...
; consider cwd mov dl, al
xor    ah, ah
mov    dx, ax

SHIFT_MACRO sar dl 2

; dl = flatcacheL2pagenumber
cmp   dl, byte ptr ds:[_currentflatpage+0]
je    in_flat_page_0

; check if L2 page is in L1 cache

cmp   dl, byte ptr ds:[_currentflatpage+1]
jne   not_in_flat_page_1
mov   cl, 1
jmp   SHORT update_l1_cache
found_flat_page_to_evict:


;call  R_EvictFlatCacheEMSPage_   ; al stores result..
jmp    do_evict_flatcache_ems_page
done_with_evict_flatcache_ems_page:
SHIFT_MACRO shl al 2

jmp   found_flat

not_in_flat_page_1:
cmp   dl, byte ptr ds:[_currentflatpage+2]
jne   not_in_flat_page_2
mov   cl, 2
jmp SHORT  update_l1_cache
not_in_flat_page_2:
cmp   dl, byte ptr ds:[_currentflatpage+3]
jne   not_in_flat_page_3
mov   cl, 3
jmp SHORT  update_l1_cache
not_in_flat_page_3:
; L2 page not in L1 cache. need to EMS remap

; doing word writes/reads instead of byte writes/reads when possible
mov   ch, byte ptr ds:[_lastflatcacheindicesused]
mov   ax, word ptr ds:[_lastflatcacheindicesused+1]
mov   cl, byte ptr ds:[_lastflatcacheindicesused+3]

mov   word ptr ds:[_lastflatcacheindicesused], cx
mov   word ptr ds:[_lastflatcacheindicesused+2], ax

mov   ax, dx

mov   bl, cl
xor   bh, bh   ; ugly... can i do cx above
mov   byte ptr ds:[bx + _currentflatpage], al
add   ax, FIRST_FLAT_CACHE_LOGICAL_PAGE

;call  Z_QuickMapFlatPage_
;	pageswapargs[pageswapargs_flatcache_offset + offset * PAGE_SWAP_ARG_MULT] = _EPR(page);
push  cx
push  si
shl   bx, 1
SHIFT_PAGESWAP_ARGS bx
; _EPR here
IFDEF COMP_CH
    add  ax, EMS_MEMORY_PAGE_OFFSET
ELSE
ENDIF
mov   word ptr ds:[_pageswapargs + (pageswapargs_flatcache_offset * 2) + bx], ax
Z_QUICKMAPAI4 pageswapargs_flatcache_offset_size INDEXED_PAGE_7000_OFFSET

pop   si
pop   cx


jmp  SHORT l1_cache_finished_updating
in_flat_page_0:
mov   cl, 0

update_l1_cache:
mov   ch, byte ptr ds:[_lastflatcacheindicesused]
cmp   ch, cl
je    l1_cache_finished_updating
mov   ah, byte ptr ds:[_lastflatcacheindicesused+1]
cmp   ah, cl
je    in_flat_page_1
mov   al, byte ptr ds:[_lastflatcacheindicesused+2]
cmp   al, cl
je    in_flat_page_2
mov   byte ptr ds:[_lastflatcacheindicesused+3], al
in_flat_page_2:
mov   byte ptr ds:[_lastflatcacheindicesused+2], ah
in_flat_page_1:
mov   word ptr ds:[_lastflatcacheindicesused], cx
l1_cache_finished_updating:
mov   al, byte ptr [bp - 4]
SHIFT_MACRO sar al 2

;cbw  


cmp       al, byte ptr ds:[_flatcache_l2_head]
jne       jump_to_flatcachemruL2
done_with_mruL2:


cmp   di, 0 ; di used to hold flatunlodaed
jnz   flat_is_unloaded
flat_not_unloaded:
; calculate ds_source_segment


;! todo use a single 16 element lookup instead of two four element ones.
; cl is flatcacheL1pagenumber 

; calculate flat page.
; 7000h + 400h * l1 pagenumber + 100h * (usedflatindex &3)
mov   al, cl
SHIFT_MACRO sal   al 2
add   al, byte ptr [bp - 3]
add   al, 070h

mov   byte ptr ds:[_ds_source_segment+3], al            ; low byte always zero!
les   ax, dword ptr ds:[si]
mov   dx, es
SELFMODIFY_SPAN_viewz_lo_1:
sub   ax, 01000h
SELFMODIFY_SPAN_viewz_hi_1:
sbb   dx, 01000h
or    dx, dx

; planeheight = labs(plheader->height - viewz.w);

jge   planeheight_already_positive	; labs check
neg   ax
adc   dx, 0
neg   dx
planeheight_already_positive:
mov   word ptr [bp - 010h], ax
mov   word ptr [bp - 0Eh], dx
mov   ax, word ptr ds:[si + 6]
mov   di, ax
les   bx, dword ptr [bp - 8]

mov   byte ptr es:[bx + di + 3], 0ffh
mov   si, word ptr ds:[si + 4]
mov   byte ptr es:[bx + si + 1], 0ffh
inc   ax

mov   word ptr cs:[SELFMODIFY_SPAN_comparestop+2 - OFFSET R_SPAN16_STARTMARKER_], ax ; set count value to be compared against in loop.

cmp   si, ax
jle   start_single_plane_draw_loop
jmp   do_next_drawplanes_loop

jump_to_flatcachemruL2:
jmp continue_flatcachemru

; flat is unloaded. load it in
flat_is_unloaded:

; flat cache page is 7000h + 400h * cl

push  cx
mov   ch, cl
xor   cl, cl
xor   bh, bh    ; for later

sal   cx, 1
sal   cx, 1   ; cx = 400h * cl 

add   cx, FLAT_CACHE_BASE_SEGMENT

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax

SELFMODIFY_SPAN_lookuppicnum:
mov   al, byte ptr es:[00]    ; uses picnum from way above.

xor   ah, ah
add   ax, word ptr ds:[_firstflat]
mov   bl, byte ptr [bp - 3]     ; usedflatindex AND 3

add   bx, bx
mov   bx, word ptr ds:[bx + _MULT_4096]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNumDirect_addr

;call  W_CacheLumpNumDirect_
pop   cx
jmp   flat_not_unloaded



start_single_plane_draw_loop:
; loop setup

single_plane_draw_loop:
; si is x, bx is plheader pointer. so adding si gets us plheader->top[x] etc.
les    bx, dword ptr [bp - 8]

;			t1 = pl->top[x - 1];
;			b1 = pl->bottom[x - 1];
;			t2 = pl->top[x];
;			b2 = pl->bottom[x];



mov   dx, word ptr es:[bx + si + 0143h]	; b1&b2
mov   cx, word ptr es:[bx + si + 1]		; t1&t2


mov   ax, SPANSTART_SEGMENT
mov   es, ax

; t1/t2 ch/cl
; b1/b2 dh/dl
dec   si	; x - 1  constant
mov   word ptr [bp - 0Ch], si
inc   si  ; add one back from the previous saved x-1 state

;    while (t1 < t2 && t1 <= b1)

cmp   cl, ch
jae   done_with_first_mapplane_loop
; set up the di parameter to be spanstart lookup index
mov   al, cl
xor   ah, ah
mov   di, ax
add   di, ax


loop_first_mapplane:
cmp   cl, dl
ja   done_with_first_mapplane_loop

mov   ax, word ptr es:[di]
mov   word ptr ds:[_ds_y], di   ; predoubled for lookup
mov   word ptr [bp - 0Ah], ax   ; store ds_x1
inc   cl

call  R_MapPlane16_

cmp   cl, ch
jae   done_with_first_mapplane_loop
inc   di
inc   di

jmp   loop_first_mapplane

end_single_plane_draw_loop_iteration:

;  todo: di not really in use at all in this loop. could be made to hold something useful
inc   si
SELFMODIFY_SPAN_comparestop:
cmp   si, 1000h
jle   single_plane_draw_loop

;jmp exit_drawplanes

jmp   do_next_drawplanes_loop

done_with_first_mapplane_loop:



cmp   dl, dh
jbe   done_with_second_mapplane_loop
; set up the di parameter to be spanstart lookup index
mov   al, dl
xor   ah, ah
mov   di, ax
add   di, ax

loop_second_mapplane:
cmp   cl, dl
ja   done_with_second_mapplane_loop

mov   ax, word ptr es:[di]
mov   word ptr ds:[_ds_y], di
mov   word ptr [bp - 0Ah], ax
dec   dl

call  R_MapPlane16_

cmp   dl, dh
jbe   done_with_second_mapplane_loop

dec   di
dec   di
jmp   loop_second_mapplane

done_with_second_mapplane_loop:

; update spanstarts



; b1 = dl
; b2 = dh
; t1 = cl
; t2 = ch

;			while (t2 < t1 && t2 <= b2) {
;				spanstart[t2] = x;

mov   ax, SPANSTART_SEGMENT
mov   es, ax

mov   bx, cx

sub   cl, ch     ; t2 < t1?
jbe   second_spanstart_update_loop
mov   ax, dx
sub   ah, ch     ; t2 <= b2?
jb    second_spanstart_update_loop

inc   ah		; add one for the >= 
cmp   ah, cl
ja    dont_swap_cx_params_1  ; todo jae and inc inside
mov   cl, ah
dont_swap_cx_params_1:


mov   al, ch  ; get t2 word lookup...
xor   ah, ah
add   ax, ax
mov   di, ax  ; di = offset

xor   ch, ch  ; cx loop count is set
mov   ax, bx
add   bh, cl  ; add the t2 increment

mov   ax, si  ;  ax = x
rep   stosw



second_spanstart_update_loop:


;			while (b2 > b1 && b2 >= t2) {
;				spanstart[b2] = x;
; b1 = dl
; b2 = dh
; t1 = bl
; t2 = bh

mov   ax, dx
sub   ah, al    ; b2 - b1
jbe   end_single_plane_draw_loop_iteration
mov   cl, dh	; store b2 copy for spanstart addr calculation
sub   dh, bh    ; b2 - t2
jb    end_single_plane_draw_loop_iteration

; add one for the >= case 
inc   dh
; ah and ch store the two values... take the smallest one to get loop count
cmp   ah, dh
ja    dont_swap_cx_params_2
mov   dh, ah
dont_swap_cx_params_2:


xor   ch, ch
mov   di, cx  ; cl held copied b2 from above
add   di, di  ; di = offset

mov   cl, dh  ; count


mov   ax, si  ;  ax = x
std   
rep   stosw
cld
jmp   end_single_plane_draw_loop_iteration



ENDP



;PROC R_MarkL2FlatCacheMRU16_ NEAR

;	if (index == flatcache_l2_head) {
;		return;
;	}

continue_flatcachemru:
push      si




;	cache_node_t far* nodelist  = flatcache_nodes;

mov       dl, al
mov       bx, OFFSET _flatcache_nodes


;	prev = nodelist[index].prev;
;	next = nodelist[index].next;


cbw      

add       ax, ax
mov       si, ax
mov       ax, word ptr ds:[si + bx]

mov       dh, al ; back up

;	if (index == flatcache_l2_tail) {
;		flatcache_l2_tail = next;	
;	} else {
;		nodelist[prev].next = next;
;	}

cmp       dl, byte ptr ds:[_flatcache_l2_tail]
jne       index_not_tail

mov       byte ptr ds:[_flatcache_l2_tail], ah
jmp       flat_tail_check_done

index_not_tail:

mov       si, ax
and       si, 000FFh      ; blegh
sal       si, 1
mov       byte ptr ds:[si + bx + 1], ah

flat_tail_check_done:

;	// guaranteed to have a next. if we didnt have one, it'd be head but we already returned from that case.
;	nodelist[next].prev = prev;

mov       al, ah
cbw      

mov       si, ax
sal       si, 1

mov       byte ptr ds:[si + bx], dh
mov       al, dl

mov       si, ax
sal       si, 1

;	nodelist[index].prev = flatcache_l2_head;
;	nodelist[index].next = -1;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx], al
mov       byte ptr ds:[si + bx + 1], 0FFh

mov       si, ax
sal       si, 1

;	nodelist[flatcache_l2_head].next = index;

mov       byte ptr ds:[si + bx + 1], dl

;	flatcache_l2_head = index;
mov       byte ptr ds:[_flatcache_l2_head], dl
exit_flatcachemru:
pop       si
jmp       done_with_mruL2

ENDP


;PROC R_EvictFlatCacheEMSPage16_ NEAR
do_evict_flatcache_ems_page:

push      bx
push      dx
push      si
mov       al, byte ptr ds:[_flatcache_l2_tail]
mov       dh, al
cbw      

;	evictedpage = flatcache_l2_tail;
mov       bx, OFFSET _flatcache_nodes
mov       si, ax        ; si gets evictedpage.

;	// all the other flats in this are cleared.
;	allocatedflatsperpage[evictedpage] = 1;
mov       byte ptr ds:[si + _allocatedflatsperpage], 1
sal       si, 1  ; now word lookup.

;	flatcache_l2_tail = flatcache_nodes[evictedpage].next;	// tail is nextmost

mov       dl, byte ptr ds:[si + bx + 1]         ; dl has flatcache_l2_tail
mov       byte ptr ds:[_flatcache_l2_tail], dl

;	flatcache_nodes[evictedpage].next = -1;
mov       byte ptr ds:[si + bx + 1], 0FFh

;	flatcache_nodes[evictedpage].prev = flatcache_l2_head;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx + 0], al

;	flatcache_nodes[flatcache_l2_head].next = evictedpage;
mov       si, ax
sal       si, 1
mov       byte ptr ds:[si + bx + 1], dh

;	flatcache_nodes[flatcache_l2_tail].prev = -1;

mov       al, dl
mov       si, ax
sal       si, 1
mov       byte ptr ds:[si + bx], 0FFh


;	flatcache_l2_head = evictedpage;


mov       byte ptr ds:[_flatcache_l2_head], dh


mov       bx, FLATINDEX_SEGMENT
mov       ds, bx
mov       ah, dh
xor       si, si
mov       bx, -1
mov       dx, MAX_FLATS


;   for (i = 0; i < MAX_FLATS; i++){
;	   if ((flatindex[i] >> 2) == evictedpage){
;         flatindex[i] = 0xFF;
;   	}
;  	}
check_next_flat:
lodsb       ; si is always one in front because of lodsb...

SHIFT_MACRO shr       al 2
cmp       al, ah
je        erase_flat
continue_erasing_flats:
cmp       si, dx
jb        check_next_flat
mov       al, ah
mov       bx, ss
mov       ds, bx
pop       si
pop       dx
pop       bx
jmp       done_with_evict_flatcache_ems_page
;ret   

erase_flat:
mov       byte ptr ds:[si+bx], bl   ; bx is -1. this both writes FF and subtracts the 1 from si
jmp       continue_erasing_flats

ENDP

PROC Z_QuickMapVisplanePage_SpanLocal16_ NEAR



;	int16_t usedpageindex = pagenum9000 + PAGE_8400_OFFSET + physicalpage;
;	int16_t usedpagevalue;
;	int8_t i;
;	if (virtualpage < 2){
;		usedpagevalue = FIRST_VISPLANE_PAGE + virtualpage;
;	} else {
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
;	}

push  bx
push  cx
push  si
mov   cl, al
mov   dh, dl
mov   al, dl
cbw  
IFDEF COMP_CH
mov   si, CHIPSET_PAGE_9000
ELSE
mov   si, word ptr ds:[_pagenum9000]
ENDIF
add   si, PAGE_8400_OFFSET ; sub 3
add   si, ax
mov   al, cl
cbw  
cmp   al, 2
jge   visplane_page_above_2
add   ax, FIRST_VISPLANE_PAGE
used_pagevalue_ready:

;		pageswapargs[pageswapargs_visplanepage_offset] = _EPR(usedpagevalue);

; _EPR here
IFDEF COMP_CH
    add  ax, EMS_MEMORY_PAGE_OFFSET
ELSE
ENDIF
mov   word ptr ds:[_pageswapargs + (pageswapargs_visplanepage_offset * 2)], ax


;pageswapargs[pageswapargs_visplanepage_offset+1] = usedpageindex;
IFDEF COMP_CH
ELSE
    mov   word ptr ds:[_pageswapargs + ((pageswapargs_visplanepage_offset+1) * 2)], si
ENDIF

;	physicalpage++;
inc   dh
mov   dl, 4

;	for (i = 4; i > 0; i --){
;		if (active_visplanes[i] == physicalpage){
;			active_visplanes[i] = 0;
;			break;
;		}
;	}

loop_next_visplane_page:
mov   al, dl
cbw  
mov   bx, ax
cmp   dh, byte ptr ds:[bx + _active_visplanes]
je    set_zero_and_break
dec   dl
test  dl, dl
jg    loop_next_visplane_page

done_with_visplane_loop:
mov   al, cl
cbw  
mov   bx, ax

mov   byte ptr ds:[bx + _active_visplanes], dh


IFDEF COMP_CH
    IF COMP_CH EQ CHIPSET_SCAT

        mov  	dx, SCAT_PAGE_SELECT_REGISTER
        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out  	dx, al
        mov     ax,  ds:[(pageswapargs_visplanepage_offset * 2) + _pageswapargs]
        mov  	dx, SCAT_PAGE_SET_REGISTER
        out 	dx, ax

    ELSEIF COMP_CH EQ CHIPSET_SCAMP

        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out     SCAMP_PAGE_SELECT_REGISTER, al
        mov     ax, ds:[_pageswapargs + (2 * pageswapargs_visplanepage_offset)]
        out 	SCAMP_PAGE_SET_REGISTER, ax

    ELSEIF COMP_CH EQ CHIPSET_HT18

        mov  	dx, HT18_PAGE_SELECT_REGISTER
        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out  	dx, al
        mov     ax,  ds:[(pageswapargs_visplanepage_offset * 2) + _pageswapargs]
        mov  	dx, HT18_PAGE_SET_REGISTER
        out 	dx, ax

    ENDIF

ELSE


    Z_QUICKMAPAI1 pageswapargs_visplanepage_offset_size unused_param



ENDIF


mov   byte ptr ds:[_visplanedirty], 1
pop   si
pop   cx
pop   bx
ret  
visplane_page_above_2:
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
add   ax, (EMS_VISPLANE_EXTRA_PAGE - 2)
jmp   used_pagevalue_ready

set_zero_and_break:
mov   byte ptr ds:[bx + _active_visplanes], 0
jmp   done_with_visplane_loop

ENDP



;
; The following functions are loaded into a different segment at runtime.
; However, at compile time they have access to the labels in this file.
;


;R_WriteBackViewConstantsSpan

PROC R_WriteBackViewConstantsSpan16_ FAR
PUBLIC R_WriteBackViewConstantsSpan16_ 



mov      ax, SPANFUNC_JUMP_LOOKUP_SEGMENT
mov      ds, ax


ASSUME DS:R_SPAN16_TEXT


mov      al, byte ptr ss:[_skyflatnum]

mov      byte ptr ds:[SELFMODIFY_SPAN_skyflatnum + 2 - OFFSET R_SPAN16_STARTMARKER_], al


mov      al, byte ptr ss:[_detailshift]
cmp      al, 1
je       do_detail_shift_one
jl       do_detail_shift_zero
jmp      do_detail_shift_two
do_detail_shift_zero:

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN16_STARTMARKER_], 4
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN16_STARTMARKER_], 4


mov      ax, 0c089h  ; nop
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN16_STARTMARKER_], ax

; 2 minus


mov ax, 0e0d1h ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPAN16_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPAN16_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPAN16_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPAN16_STARTMARKER_], ax  ; shl   ax, 1
mov ax, 0FAD1h  ; shr   dx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN16_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax  ; sar   dx, 1
mov ax, 0F9d1h  ; sar   cx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN16_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN16_STARTMARKER_], ax  ; sar   cx, 1



jmp     done_with_detailshift
do_detail_shift_one:

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN16_STARTMARKER_], 2
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN16_STARTMARKER_], 2

mov      ax, 0e8d1h  ; shr ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN16_STARTMARKER_], 0EBD1h ; shr bx, 1

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN16_STARTMARKER_], 0FAD1h  ; sar   dx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN16_STARTMARKER_], 0F9D1h  ; sar   cx, 1
mov      ax, 0E0D1h
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPAN16_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPAN16_STARTMARKER_], ax  ; shl   ax, 1

mov   ax, 0c089h  ; nop
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN16_STARTMARKER_], ax

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPAN16_STARTMARKER_], ax

jmp     done_with_detailshift

do_detail_shift_two:


mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN16_STARTMARKER_], 1
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN16_STARTMARKER_], 1

mov      ax, 0e8d1h  ; shr ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      ax, 0EBD1h   ; shr bx, 1

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN16_STARTMARKER_], ax

; two minus
mov   ax, 0c089h  ; nop

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPAN16_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPAN16_STARTMARKER_], ax

done_with_detailshift:




mov      ax, ss
mov      ds, ax





ASSUME DS:DGROUP

retf

endp




; end marker for this asm file
PROC R_SPAN16_ENDMARKER_ FAR
PUBLIC R_SPAN16_ENDMARKER_ 
ENDP



END
