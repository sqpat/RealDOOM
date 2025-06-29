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


EXTRN R_PointToAngle_:NEAR

.DATA




.CODE




;R_PointToAngle2_

PROC R_PointToAngle2_ FAR
PUBLIC R_PointToAngle2_ 


;uint32_t __far R_PointToAngle2 ( fixed_t_union	x1, fixed_t_union	y1, fixed_t_union	x2, fixed_t_union	y2 ) {	
;    return R_PointToAngle (x2, y2);
;	x2.w -= x1.w;
;	y2.w -= y1.w;

; todo swap param order?

push      si
push      bp
mov       bp, sp
les       si, dword ptr [bp + 8]
xchg      ax, si
sub       ax, si
mov       si, es
sbb       si, dx
mov       dx, si
les       si, dword ptr [bp + 0Ch]
sub       si, bx
mov       bx, si
mov       si, es
sbb       si, cx
mov       cx, si

call      R_PointToAngle_
pop       bp
pop       si
retf      8

ENDP



;R_PointToAngle2_16_

PROC R_PointToAngle2_16_ FAR
PUBLIC R_PointToAngle2_16_ 

;uint32_t __far R_PointToAngle2_16 (  int16_t	x2, int16_t	y2 ) {	
;	fixed_t_union x2fp, y2fp;
;	x2fp.h.intbits = x2;
;	y2fp.h.intbits = y2;
;	x2fp.h.fracbits = 0;
;	y2fp.h.fracbits = 0;
;    return R_PointToAngle (x2fp, y2fp);

push      bx
push      cx
mov       cx, dx
xchg      ax, dx
xor       ax, ax
mov       bx, ax
call      R_PointToAngle_
pop       cx
pop       bx
retf      
ENDP

;R_SetViewSize_

PROC R_SetViewSize_ FAR
PUBLIC R_SetViewSize_ 


;void __far R_SetViewSize ( uint8_t		blocks, uint8_t		detail ) {
;    setsizeneeded = true;
;    setblocks = blocks;
;    pendingdetail = detail;
;}

; todo inline and move vars to fixeddata

mov       byte ptr ds:[_setblocks], al
xor       dh, dh
mov       byte ptr ds:[_setsizeneeded], 1
mov       word ptr ds:[_pendingdetail], dx
retf      

ENDP



;void __far R_VideoErase (uint16_t ofs, int16_t count ) 
;R_VideoErase_

PROC R_VideoErase_ FAR
PUBLIC R_VideoErase_ 



PUSHA_NO_AX_OR_BP_MACRO
SHIFT_MACRO shr   ax 2 ; ofs >> 2
SHIFT_MACRO shr   dx 2 ; count = count / 4
;dec   dx          ; offset/di/si by one starting
;add   ax, dx      ; for backwards iteration starting from count
;inc   dx
xchg  ax, si
mov   cx, dx

;	outp(SC_INDEX, SC_MAPMASK);
mov   dx, SC_INDEX
mov   al, SC_MAPMASK
out   dx, al

;    outp(SC_INDEX + 1, 15);
inc   dx
mov   al, 00Fh
out   dx, al

;    outp(GC_INDEX, GC_MODE);
mov   dx, GC_INDEX
mov   al, GC_MODE
out   dx, al

;    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);
inc   dx
in    al, dx
or    al, 1
out   dx, al

;    dest = (byte __far*)(destscreen.w + (ofs >> 2));
;	source = (byte __far*)0xac000000 + (ofs >> 2);


les   di, dword ptr ds:[_destscreen]
add   di, si    ; es:di = destscreen + ofs>>2

;    while (--countp >= 0) {
;		dest[countp] = source[countp];
;    }


mov   ax, 0AC00h;
mov   ds, ax        ; ds:si is AC00:ofs>>2
; es set above

; movsw does not seem to work
;shr   cx, 1
;rep movsw 
;adc   cx, cx
rep movsb 

mov   ax, ss
mov   ds, ax

;	outp(GC_INDEX, GC_MODE);
mov   dx, GC_INDEX
mov   al, GC_MODE
out   dx, al

;    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
inc   dx
in    al, dx
and   al, 0FEh
out   dx, al

POPA_NO_AX_OR_BP_MACRO
retf  

ENDP


;R_DrawViewBorder_

; could probably be improved a small amount wrt screenwidth constants and viewheight
; but dont care much

PROC R_DrawViewBorder_ FAR
PUBLIC R_DrawViewBorder_ 


PUSHA_NO_AX_OR_BP_MACRO
mov   ax, word ptr ds:[_scaledviewwidth]
cmp   ax, SCREENWIDTH
jne   view_border_exists
exit_drawviewborder:

POPA_NO_AX_OR_BP_MACRO
retf  
view_border_exists:
mov   bx, SCREENHEIGHT - SBARHEIGHT
sub   bx, word ptr ds:[_viewheight]
shr   bx, 1


mov   di, SCREENWIDTH
sub   di, ax
mov   al, SCREENWIDTHOVER2
mul   bl
sal   ax, 1
mov   si, ax

sar   di, 1
mov   cx, si
add   cx, di
xor   ax, ax
mov   dx, cx
;    // copy top and one line of left side 

call  R_VideoErase_
mov   ax, word ptr ds:[_viewheight]
add   ax, bx

mov   ah, SCREENWIDTHOVER2
mul   ah
sal   ax, 1

mov   bx, SCREENWIDTH

mov   dx, cx
add   si, bx
mov   cx, word ptr ds:[_viewheight]

sub   ax, di
sub   si, di

;    // copy one line of right side and bottom 

call  R_VideoErase_


;    // copy sides using wraparound 

sal   di, 1

loop_erase_border:
mov   dx, di
mov   ax, si
call  R_VideoErase_
add   si, bx
loop  loop_erase_border
POPA_NO_AX_OR_BP_MACRO
retf  



ENDP


END
