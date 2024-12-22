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

    ; di contains shifted dc_x relative to details
    ; bx contains dc_yl

    cli 									; disable interrupts
    push bp

    ; todo just move this above to prevenet the need for the mov ax
    ;SELFMODIFY_COLFUNC_subtract_centery
    sub   ax, 01000h
    mov   es, ax              ; save low(M1)

	; shift already done earlier
    
	
    ; todo when self modifying get this register exchange for free..

    mov   bx, word ptr ds:[_dc_iscale + 0]   
    mov   ch, byte ptr ds:[_dc_iscale + 2]      ; 2nd byte of high word not used up ahead...
    mov   cl, bh                             ; construct dc_iscale + 1 word
    mov   bp, cx                             ; cache for later to avoid going to memory



;  DX:AX * CX:BX

; note this is 8 bit times 32 bit and we want the mid 16


	CWD
	AND DX, BX
	NEG DX



    mul     ch;             ; only the bottom 16 bits are necessary.
    add     dx,ax           ; - add to total
    mov     cx,dx           ; - hold total in cx
    mov     ax,es           ; restore low(M1)
    mul     bx              ; low(M2) * low(M1)
    add     dx,cx           ; add previously computed high part


; multiply completed. 
; dx:ax is the 32 bits of the mul. we want dx to have the mid 16.

;    finishing  dc_texturemid.w + (dc_yl-centery)*fracstep.w


    
    add   ax, word ptr ds:[_dc_texturemid+0]
    adc   dx, word ptr ds:[_dc_texturemid+2]   ; first add dx_texture mid

    mov   dh, dl
    mov   dl, ah                          ; mid 16 bits of the 32 bit dx:ax into dx
    
    mov   ch, al        ; ch gets the low 8 bits

    
    ; bx still has dc_iscale low word from above. prepare low bits of precision
    mov   cl, bl          ; cl has 8 bits of precision
    

    

    ; for fixing jaggies... need extra precision from time to time


   ;  prep our loop variables

;SELFMODIFY_COLFUNC_set_destview_segment:
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment
   xor     bx, bx       ; common bx offset of zero in the xlats ahead

   lds     si, dword ptr ds:[_dc_source_segment-2]  ; sets ds, and si to 004Fh (hardcoded)

   mov     ah,  7Fh   ; for ANDing to AX to mod al by 128 and preserve AH

COLFUNC_JUMP_OFFSET:
   jmp loop_done         ; relative jump to be modified before function is called


pixel_loop_fast:

   ;; 12 bytes loop iter

; 0xE size
DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didn't make anything faster.

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

    pop bp
    sti
    retf


ENDP






;
; R_DrawColumnPrep
;
	
PROC  R_DrawColumnPrep_
PUBLIC  R_DrawColumnPrep_ 

; argument AX is diff for various segment lookups

push  bx
push  cx
push  dx
push  si
push  di



; cant optimize as this is ADD not mov
add   ax, COLFUNC_JUMP_LOOKUP_SEGMENT        ; compute segment now, clear AX dependency
mov   es, ax                                 ; store this segment for now, with offset pre-added

; todo optimize this read
mov   ax, word ptr ds:[_dc_x]

; shift ax by (2 - detailshift.)
;SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift:
db 0EBh, 000h
shr   ax, 1
shr   ax, 1



; dest = destview + dc_yl*80 + (dc_x>>2); 
; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale


; todo optimize this read
mov   bx, word ptr ds:[_dc_yl]
mov   si, bx
add   ax, word ptr es:[bx+si+COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF]                  ; set up destview 
;SELFMODIFY_COLFUNC_add_destview_offset:
add   ax, 01000h

; todo optimize this read
mov   si, word ptr ds:[_dc_yh]                  ; grab dc_yh
sub   si, bx                                 ;


add   si, si                                 ; double diff (dc_yh - dc_yl) to get a word offset
xchg  ax, di
mov   ax, word ptr es:[si]                   ; get the jump value
mov   word ptr es:[((COLFUNC_JUMP_OFFSET+1)-R_DrawColumn_)+COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need
mov   al, byte ptr ds:[_dc_colormap_index]      ; lookup colormap index
; what follows is compution of desired CS segment and offset to function to allow for colormaps to be CS:BX and match DS:BX column
; or can we do this in an outer func without this instrction?
;SELFMODIFY_COLFUNC_set_colormaps_segment
mov   dx, 01000h
test  al, al
jne   skipcolormapzero

mov   word ptr ds:[_colfunc_farcall_addr_1+2], dx

xchg  ax, bx    ; dc_yl in ax

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _colfunc_farcall_addr_1


pop   di 
pop   si
pop   dx
pop   cx
pop   bx
retf  


; if colormap is not zero we must do some segment math
skipcolormapzero:
mov   cx, DRAWCOL_OFFSET

cbw           ; al is like 0-20 so this will zero out ah...
xchg   ah, al ; move it high with 0 al.
sub   cx, ax
 
 ; todo investigate shift 4 lookup table
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shr   ax, 4
ELSE
shr   ax, 1
shr   ax, 1
shr   ax, 1
shr   ax, 1
ENDIF
 
add  ax, dx

mov   word ptr ds:[_func_farcall_scratch_addr], cx				; setup dynamic call
mov   word ptr ds:[_func_farcall_scratch_addr+2], ax

xchg  ax, bx    ; dc_yl in ax

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _func_farcall_scratch_addr

pop   di ; unused but drawcol clobbers it.
pop   si
pop   dx
pop   cx
pop   bx
retf   

ENDP



END