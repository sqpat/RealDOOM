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







; for the 6th colormap (used in fuzz draws. offset by 600h bytes, or 60h segments)
COLORMAPS_6_HIGH_SEG_DIFF_SEGMENT = (08C00h + 060h)
 
; 5472 or 0x1560
COLORMAPS_HIGH_SEG_OFFSET_IN_CS = 16 * (COLORMAPS_6_HIGH_SEG_DIFF_SEGMENT - DRAWFUZZCOL_AREA_SEGMENT)




;=================================

.CODE




;
; R_DrawFuzzColumn
;
	
PROC  R_DrawFuzzColumn_ 
PUBLIC  R_DrawFuzzColumn_ 

; todo:
; could write sp somehwere and use it as 64h for si comps. 

push dx
push si
push di
mov  es, cx
mov  cl, byte ptr ds:[_fuzzpos]	; note this is always the byte offset - no shift conversion necessary
xor  ch, ch
mov  si, cx
mov  cx, ax
; todo dont need segment... use the variable offset and store in di
mov  ax, FUZZOFFSET_SEGMENT
mov  ds, ax
mov  di, bx
; constant space
mov  dx, 04Fh
mov  ch, 010h


cli
push bp
mov  bp, COLORMAPS_HIGH_SEG_OFFSET_IN_CS





cmp  cl, ch
jg   draw_16_fuzzpixels
jmp  done_drawing_16_fuzzpixels
draw_16_fuzzpixels:



DRAW_SINGLE_FUZZPIXEL MACRO 



lodsw     						; load fuzz offset...
mov  bx, ax	       				; move offset to bx.
mov  al, byte ptr es:[bx + di]  ; read screen
mov  bx, bp						; set colormaps 6 CS-based offset
xlat byte ptr cs:[bx]		    ; lookup colormaps + al byte
stosb							; write to screen
add  di, dx						; dx contains constant (0x4F) to add to di to get next screen dest.


ENDM

REPT 16
    DRAW_SINGLE_FUZZPIXEL
endm


cmp  si, 064h
jl   fuzzpos_ok
; subtract 50 from fuzzpos
sub  si, 064h
fuzzpos_ok:
sub  cl, ch
cmp  cl, ch
jle  done_drawing_16_fuzzpixels
jmp  draw_16_fuzzpixels
done_drawing_16_fuzzpixels:
test cl, cl
je   finished_drawing_fuzzpixels
xor ch, ch;
draw_one_fuzzpixel:

lodsw     						; load fuzz offset...
mov  bx, ax	       				; move offset to bx.
mov  al, byte ptr es:[bx + di]  ; read screen
mov  bx, bp						; set colormaps 6 CS-based offset
xlat byte ptr cs:[bx]		    ; lookup colormaps + al byte
stosb							; write to screen
add  di, dx						; dx contains constant (0x4F) to add to di to get next screen dest.

cmp  si, 064h
je   zero_out_fuzzpos
finish_one_fuzzpixel_iteration:
loop  draw_one_fuzzpixel
; write back fuzzpos
finished_drawing_fuzzpixels:

pop bp
sti

; restore ds
mov  di, ss
mov  ds, di

; write back fuzzpos
mov  ax, si

mov  byte ptr ds:[_fuzzpos], al

pop  di
pop  si
pop  dx
retf 

zero_out_fuzzpos:
xor  si, si
loop  draw_one_fuzzpixel
jmp finished_drawing_fuzzpixels

ENDP



;
; R_DrawSingleMaskedColumn
;
	
PROC  R_DrawSingleMaskedColumn_ 
PUBLIC  R_DrawSingleMaskedColumn_ 

push  bx
push  cx
push  si
push  di
push  bp

mov   word ptr ds:[_dc_source_segment], ax	; set this early. 

mov   cl, dl
xor   ch, ch		; count used once for mul and not again. todo is dh already zero?



;    topscreen.w = sprtopscreen;

mov   di, word ptr ds:[_sprtopscreen]
mov   si, word ptr ds:[_sprtopscreen+2]
mov   bx, word ptr ds:[_spryscale]
mov   ax, word ptr ds:[_spryscale+2]

;   topscreen = si:di 

; fastmul1632, ax/cx preswapped

; FastMul16u32u(length, spryscale.w)

MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

;    bottomscreen.w = topscreen.w + FastMul16u32u(length, spryscale.w);


add ax, di
adc dx, si

; dx:ax = bottomscreen
; si:di = topscreen (still)

;    dc_yh = bottomscreen.h.intbits;
;    if (!bottomscreen.h.fracbits)
;        dc_yh--;



neg  di
adc  si, 0
;mov  word ptr ds:[_dc_yl], si

; dc_yl written back


;		dc_yh = bottomscreen.h.intbits;
;		if (!bottomscreen.h.fracbits)
;			dc_yh--;

neg ax
sbb dx, 0FFFFh
mov  word ptr ds:[_dc_yh], dx
; dx is dc_yh
; si is dc_yl





skip_inc_dc_yl:

;        if (dc_yh >= mfloorclip[dc_x])
;            dc_yh = mfloorclip[dc_x]-1;



mov   bx, word ptr ds:[_dc_x]
sal   bx, 1
les   ax, dword ptr ds:[_mfloorclip]
add   bx, ax
mov   cx, word ptr es:[bx]

cmp   dx, cx
jl    skip_floor_clip_set_single	; todo consider making this jump out and back? whats the better default branch
mov   dx, cx
dec   dx
skip_floor_clip_set_single:



;        if (dc_yl <= mceilingclip[dc_x])
;            dc_yl = mceilingclip[dc_x]+1;


sub   bx, ax

les   ax, dword ptr ds:[_mceilingclip]   
add   bx, ax

mov   cx, word ptr es:[bx]
cmp   si, cx
jg    skip_ceil_clip_set_single   ; todo consider making this jump out and back? whats the better default branch
mov   si, cx
inc   si
skip_ceil_clip_set_single:

cmp   si, dx			
jnle   exit_function_single


mov   word ptr ds:[_dc_yh], dx ; todo eventually just pass this in as an arg instead of write it
mov   word ptr ds:[_dc_yl], si ;  dc_x could also be trivially recovered from bx

mov   ax, 02400h


db 09Ah
db R_DRAWCOLUMNPREPCALLOFFSET AND 0FFh
db (R_DRAWCOLUMNPREPCALLOFFSET SHR 8 )
db COLFUNC_HIGH_SEGMENT AND 0FFh
db (COLFUNC_HIGH_SEGMENT SHR 8 )


exit_function_single:

pop   bp
pop   di
pop   si
pop   cx
pop   bx
retf   

ENDP


; ax pixelsegment
; cx:bx column


;
; R_DrawMaskedColumn
;
	
PROC  R_DrawMaskedColumn_ 
PUBLIC  R_DrawMaskedColumn_ 

;  bp - 02 cx/column segment
;  bp - 04  ax/pixelsegment cache
;  bp - 06  cached dc_texturemid intbits to restore before function

push  dx
push  si
push  di
push  bp
mov   bp, sp
push  cx            ; bp - 2
mov   si, bx        ; si now holds column address.
mov   es, cx
push  ax            ; bp - 4

mov   cx, word ptr ds:[_dc_texturemid+2]
push  cx            ; bp - 6
xor   di, di        ; di used as currentoffset.

cmp   byte ptr es:[si], 0FFh
jne   draw_next_column_patch
jmp   exit_function
draw_next_column_patch:

;        topscreen.w = sprtopscreen + FastMul16u32u(column->topdelta, spryscale.w);

mov   bx, word ptr ds:[_spryscale]
mov   ax, word ptr ds:[_spryscale+2]

mov   cl, byte ptr es:[si]
xor   ch, ch

;inlined fastmul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

; bx was preserved im mul
; DX:AX = fastmult result. 


add   ax, word ptr ds:[_sprtopscreen]
adc   dx, word ptr ds:[_sprtopscreen+2]

; topscreen = DX:AX.

;		dc_yl = topscreen.h.intbits; 
;		if (topscreen.h.fracbits)
;			dc_yl++;


neg  ax
adc  dx, 0
mov  ds:[_dc_yl], dx
neg  ax
sbb  dx, 0

mov  ds, ax    ; store old topscreen
mov  ax, word ptr ss:[_spryscale+2]    ; use ss as ds as a hack...

mov  cl, byte ptr es:[si + 1] ; get length for mult
xor  ch, ch

mov  es, dx   ;  es:ds stores old topscreen result
 

;inlined fastmul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 


;        bottomscreen.w = topscreen.w + FastMul16u32u(column->length, spryscale.w);
; add cached topscreen
mov   cx, ds
add   ax, cx
mov   cx, es
adc   dx, cx
mov   cx, ss
mov   ds, cx


;		dc_yh = bottomscreen.h.intbits;
;		if (!bottomscreen.h.fracbits)
;			dc_yh--;

neg ax
sbb dx, 0FFFFh


; dx is dc_yh but needs to be written back 

; dc_yh, dc_yl are set



;        if (dc_yh >= mfloorclip[dc_x])
;            dc_yh = mfloorclip[dc_x]-1;


mov   bx, word ptr ds:[_dc_x]
sal   bx, 1
les   ax, dword ptr ds:[_mfloorclip]
add   bx, ax

mov   cx, word ptr es:[bx]
cmp   dx, cx
jl    skip_floor_clip_set
mov   dx, cx
dec   dx
skip_floor_clip_set:
mov   word ptr ds:[_dc_yh], dx


;        if (dc_yl <= mceilingclip[dc_x])
;            dc_yl = mceilingclip[dc_x]+1;

sub   bx, ax
les   ax, dword ptr ds:[_mceilingclip]   
add   bx, ax

mov   ax, word ptr ds:[_dc_yl]
mov   cx, word ptr es:[bx]
cmp   ax, cx
jg    skip_ceil_clip_set
mov   ax, cx
inc   ax
mov   word ptr ds:[_dc_yl], ax
skip_ceil_clip_set:

cmp   ax, word ptr ds:[_dc_yh]
jg    increment_column_and_continue_loop
mov   bx, di

shr   bx, 1
shr   bx, 1
shr   bx, 1
shr   bx, 1
mov   dx, word ptr [bp - 6]
les   ax, dword ptr [bp - 4]
add   ax, bx
mov   word ptr ds:[_dc_source_segment], ax
mov   al, byte ptr es:[si]
xor   ah, ah
sub   dx, ax
mov   word ptr ds:[_dc_texturemid+2], dx
mov   ax, 02400h


db 09Ah
db R_DRAWCOLUMNPREPCALLOFFSET AND 0FFh
db (R_DRAWCOLUMNPREPCALLOFFSET SHR 8 )
db COLFUNC_HIGH_SEGMENT AND 0FFh
db (COLFUNC_HIGH_SEGMENT SHR 8 )

increment_column_and_continue_loop:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[si + 1]
xor   ah, ah

add   di, ax

neg   ax
and   ax, 0Fh
add   si, 2
add   di, ax
cmp   byte ptr es:[si], 0FFh
je    exit_function
jmp   draw_next_column_patch ; todo inverse and skip jump
exit_function:

mov   ax, word ptr [bp - 6]             ; restore dc_texture_mid
mov   word ptr ds:[_dc_texturemid+2], ax
LEAVE_MACRO
pop   di
pop   si
pop   dx
retf


ENDP







END