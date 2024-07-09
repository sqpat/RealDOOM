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

.DATA



EXTRN   _spryscale:DWORD
EXTRN   _sprtopscreen:WORD
EXTRN   _mfloorclip:WORD
EXTRN   _mceilingclip:WORD

EXTRN  _R_DrawColumnPrepCallHigh:WORD






DRAWCOL_PREP_SEGMENT           = 06A42h
;DRAWCOL_PREP_SEGMENT_HIGH      = DRAWCOL_PREP_SEGMENT  - 06800h + 08C00h
DRAWCOL_PREP_SEGMENT_HIGH     = 08E42h
DRAWCOL_PREP_OFFSET            = 09D0h








;=================================

.CODE


;
; R_DrawMaskedColumn
;
	
PROC  R_DrawMaskedColumn_ NEAR
PUBLIC  R_DrawMaskedColumn_ 

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
push  ax
mov   si, bx
mov   word ptr [bp - 2], cx
mov   ax, word ptr [_dc_texturemid]
xor   di, di
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr [_dc_texturemid+2]
mov   es, cx
mov   word ptr [bp - 6], ax
cmp   byte ptr es:[si], 0FFh
jne   label_0
jmp   label_3
label_0:
mov   bx, word ptr [_spryscale]
mov   cx, word ptr [_spryscale+2]
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[si]
xor   ah, ah

;inlined fastmul16u32u
XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

mov   bx, word ptr [_sprtopscreen]
mov   cx, word ptr [_spryscale+2]
add   bx, ax
mov   word ptr [bp - 4], bx
mov   bx, word ptr [_spryscale]
mov   ax, word ptr [_sprtopscreen+2]
adc   ax, dx
mov   es, word ptr [bp - 2]
mov   word ptr [bp - 8], ax
mov   al, byte ptr es:[si + 1]
xor   ah, ah

;inlined fastmul16u32u
XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

mov   bx, word ptr [bp - 4]
add   bx, ax
mov   ax, word ptr [bp - 8]
adc   ax, dx
mov   dx, word ptr [bp - 8]
mov   word ptr [_dc_yh], ax
mov   word ptr [_dc_yl], dx
test  bx, bx
jne   label_2
jmp   finished_drawing_masked_column
label_2:
cmp   word ptr [bp - 4], 0
je    label_6
inc   word ptr [_dc_yl]
label_6:
mov   bx, word ptr [_dc_x]
mov   ax, word ptr [_mfloorclip]
add   bx, bx
mov   es, word ptr [_mfloorclip+2]
add   bx, ax
mov   ax, word ptr [_dc_yh]
cmp   ax, word ptr es:[bx]
jl    label_5
mov   ax, word ptr es:[bx]
dec   ax
mov   word ptr [_dc_yh], ax
label_5:
mov   bx, word ptr [_dc_x]
mov   ax, word ptr [_mceilingclip]
add   bx, bx
mov   es, word ptr [_mceilingclip+2]
add   bx, ax
mov   ax, word ptr [_dc_yl]
cmp   ax, word ptr es:[bx]
jg    label_1
mov   ax, word ptr es:[bx]
inc   ax
mov   word ptr [_dc_yl], ax
label_1:
mov   ax, word ptr [_dc_yl]
cmp   ax, word ptr [_dc_yh]
jg    label_7
mov   ax, di
mov   dx, word ptr [bp - 0Ch]
shr   ax, 1
shr   ax, 1
shr   ax, 1
shr   ax, 1
add   dx, ax
mov   ax, word ptr [bp - 0Ah]
mov   word ptr [_dc_texturemid], ax
mov   ax, word ptr [bp - 6]
mov   word ptr [_dc_source_segment], dx
mov   word ptr [_dc_texturemid+2], ax
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[si]
xor   ah, ah
sub   word ptr [_dc_texturemid+2], ax
mov   ax, 02400h

; call R_DrawColumnPrep_
;push cs
;db 09Ah
;dw DRAWCOL_PREP_OFFSET
;dw DRAWCOL_PREP_SEGMENT_HIGH

;push cs
db 0FFh
db 01Eh
dw _R_DrawColumnPrepCallHigh

label_7:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[si + 1]
xor   ah, ah
mov   dx, 010h
add   di, ax
and   al, 0Fh
sub   dx, ax
mov   ax, dx
xor   ah, dh
and   al, 0Fh
add   si, 2
add   di, ax
cmp   byte ptr es:[si], 0FFh
je    label_3
jmp   label_0
label_3:
mov   ax, word ptr [bp - 0Ah]
mov   word ptr [_dc_texturemid], ax
mov   ax, word ptr [bp - 6]
mov   word ptr [_dc_texturemid+2], ax
mov   sp, bp
pop   bp
pop   di
pop   si
pop   dx
ret
finished_drawing_masked_column:
dec   ax
mov   word ptr [_dc_yh], ax
jmp   label_2
cld   

ENDP


END