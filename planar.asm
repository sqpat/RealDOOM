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
	.286
	.MODEL  medium
	INCLUDE defs.inc

.DATA

EXTRN	_destview:DWORD
EXTRN	_centery:WORD

pixelcount dd 0
loopcount dd 0


;=================================


.CODE

;
; R_DrawColumn
;
	
PROC  R_DrawColumn_
PUBLIC  R_DrawColumn_
    push  bx
    push  cx
    push  dx
    push  si
    push  di
    push  bp
    mov   bp, sp
    sub   sp, 6
    mov   ax, word ptr [_dc_yh]
    sub   ax, word ptr [_dc_yl]
    mov   di, ax
    test  ax, ax
    jge   do_draw
    leave 
    pop   di
    pop   si
    pop   dx
    pop   cx
    pop   bx
    retf   
do_draw:
    mov   cx, word ptr [_dc_x]
    mov   ax, 1
    and   cl, 3
    mov   dx, 3c5h
    shl   ax, cl
    out   dx, al
    imul  bx, word ptr [_dc_yl], 50h
    mov   ax, word ptr [_destview + 2] ; todo
    mov   dx, word ptr [_destview + 0] ; todo
    mov   word ptr [bp - 2], ax
    mov   ax, word ptr [_dc_iscale + 0]   ; todo
    mov   si, word ptr [_dc_x]
    mov   word ptr [bp - 6], ax
    mov   ax, word ptr [_dc_iscale + 2]   ; todo
    sar   si, 2
    mov   word ptr [bp - 4], ax
    add   dx, bx
    mov   cx, word ptr [bp - 4]
    mov   ax, word ptr [_dc_yl]
    mov   bx, word ptr [bp - 6]
    sub   ax, word ptr [_centery]
    add   si, dx
    cwd   

; TODO optimize/remove

i4m:
    xchg    ax,bx           ; swap low(M1) and low(M2)
    push    ax              ; save low(M2)
    xchg    ax,dx           ; exchange low(M2) and high(M1)
    or      ax,ax           ; if high(M1) non-zero
    je skiplowmul
    mul   dx              ; - low(M2) * high(M1)
skiplowmul:
    xchg    ax,cx           ; save that in cx, get high(M2)
    or      ax,ax           ; if high(M2) non-zero
    je skiphighmul
    mul   bx              ; - high(M2) * low(M1)
    add   cx,ax           ; - add to total
skiphighmul:
    pop     ax              ; restore low(M2)
    mul     bx              ; low(M2) * low(M1)
    add     dx,cx           ; add previously computed high part
    


    mov   cx, word ptr [_dc_texturemid+0]
    add   cx, ax
    adc   dx, word ptr [_dc_texturemid+2]

; TODO we need the jump table, or to calculate the jump offset and jump to a relative offset with self modifying code.

pixel_loop:    
    mov   ax, dx
    xor   ah, dh
    mov   bx, word ptr [_dc_source+0]
    and   al, 7fh
    mov   es, word ptr [_dc_source+2]
    add   bx, ax
    mov   al, byte ptr es:[bx]
    mov   bx, word ptr [_dc_colormap+0]
    xor   ah, ah
    mov   es, word ptr [_dc_colormap+2]
    add   bx, ax
    add   si, 50h
    mov   al, byte ptr es:[bx]
    mov   es, word ptr [bp - 2]
    add   cx, word ptr [bp - 6]
    adc   dx, word ptr [bp - 4]
    dec   di
    mov   byte ptr es:[si - 50h], al
    cmp   di, -1
    jne   pixel_loop
    leave 
    pop   di
    pop   si
    pop   dx
    pop   cx
    pop   bx
    retf


ENDP


END