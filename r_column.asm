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
.DATA





COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF   = ((DC_YL_LOOKUP_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)
COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)






;=================================

.CODE

;
; R_DrawColumn
;
	
PROC  R_DrawColumn_
PUBLIC  R_DrawColumn_

; no need to push anything. outer function just returns and pops

    ; di contains shifted dc_x relative to detailshift
    ; ax contains dc_yl
    ; bp:si is dc_texturemid
    ; bx contains dc_iscale+0
    ; cx contains dc_iscale+1 (we never use byte 4)

    ; todo just move this above to prevenet the need for the mov ax
    ;SELFMODIFY_COLFUNC_subtract_centery
    sub   ax, 01000h
    mov   ds, ax              ; save low(M1)

;    this is now done outside the call, including the register swap    
;    mov   bx, word ptr ds:[_dc_iscale + 0]   
;    mov   ch, byte ptr ds:[_dc_iscale + 2]      ; 2nd byte of high word not used up ahead...
;    mov   cl, bh                             ; construct dc_iscale + 1 word
     mov   es, cx                             ; cache for later to avoid going to memory



;  DX:AX * CX:BX

; note this is 8 bit times 32 bit and we want the mid 16

; begin multiply
	CWD
	AND DX, BX
	NEG DX

    mul     ch;             ; only the bottom 16 bits are necessary.
    add     dx,ax           ; - add to total
    mov     cx,dx           ; - hold total in cx
    mov     ax,ds           ; restore low(M1)
    mul     bx              ; low(M2) * low(M1)
    add     dx,cx           ; add previously computed high part
; end multiply    

; multiply completed. 
; dx:ax is the 32 bits of the mul. we want dx to have the mid 16.

;    finishing  dc_texturemid.w + (dc_yl-centery)*fracstep.w


    
    add   ax, bp
    adc   dx, si ; si was holding onto _dc_texturemid+2

    mov   bp, es        ; bp gets dc_iscale + 1

    ; note: top 8 bits cut off! can we restructure? make it faster?
    ; adc dl, [8 bit reg] instead of si?

    mov   dh, dl
    mov   dl, ah        ; mid 16 bits of the 32 bit dx:ax into dx
    

    ; bx still has dc_iscale low word from above. prepare low bits of precision
    mov   cl, bl        ; cl has 8 bits of precision (dc_iscale+0)
    mov   ch, al        ; ch gets the low 8 bits     (starting texel)

    
    

    

    ; for fixing jaggies... need extra precision from time to time


   ;  prep our loop variables

;SELFMODIFY_COLFUNC_set_destview_segment:
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment
   xor     bx, bx       ; common bx offset of zero in the xlats ahead

   lds     si, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and si to 004Fh (hardcoded)

   mov     ah,  7Fh   ; for ANDing to AX to mod al by 128 and preserve AH

COLFUNC_JUMP_OFFSET:
   jmp loop_done         ; relative jump to be modified before function is called


pixel_loop_fast:

   ;; 14 bytes loop iter

; 0xE size
DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didn't make anything faster.
   ; todo retry on real 286

    mov    al,dh
	and    al,ah                  ; ah is 7F
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    ch,cl                  ; add 8 low bits of precision
    adc    dx,bp                  ; carry result into this add
	add    di,si                  ; si has 79 (0x4F) and stos added one
ENDM


REPT 199
    DRAW_SINGLE_PIXEL
ENDM

; draw last pixel, cut off the add

    mov    al,dh
	and    al,ah                  ; ah is 7F
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	; dont need these in last loop
    ;add    di,si                  ; si has 79 (0x4F) and stos added one
	;add    dx,cx

loop_done:
; clean up

; restore ds without going to memory.

    mov ax, ss
    mov ds, ax

    retf


ENDP










END