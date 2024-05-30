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
	.MODEL  small
	INCLUDE defs.inc

.DATA

EXTRN	_destview:DWORD
EXTRN	_centery:DWORD

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
    mov   dx, 0x3c5
    shl   ax, cl
    out   dx, al
    imul  bx, word ptr [_dc_yl], 0x50
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
    cdq   
    lcall 0x277c:0x28a8                     ; big todo
    mov   cx, word ptr [_dc_texturemid+0]
    add   cx, ax
    adc   dx, word ptr [_dc_texturemid+2]
pixel_loop:    
    mov   ax, dx
    xor   ah, dh
    mov   bx, word ptr [_dc_source+0]
    and   al, 0x7f
    mov   es, word ptr [_dc_source+2]
    add   bx, ax
    mov   al, byte ptr es:[bx]
    mov   bx, word ptr [_dc_colormap+0]
    xor   ah, ah
    mov   es, word ptr [_dc_colormap+2]
    add   bx, ax
    add   si, 0x50
    mov   al, byte ptr es:[bx]
    mov   es, word ptr [bp - 2]
    add   cx, word ptr [bp - 6]
    adc   dx, word ptr [bp - 4]
    dec   di
    mov   byte ptr es:[si - 0x50], al
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