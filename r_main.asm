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




.CODE








;void __far R_VideoErase (uint16_t ofs, int16_t count ) 
;R_VideoErase_

PROC R_VideoErase_ NEAR
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
ret  

ENDP


;R_DrawViewBorder_

; could probably be improved a small amount wrt screenwidth constants and viewheight
; but dont care much

PROC R_DrawViewBorder_ FAR
PUBLIC R_DrawViewBorder_ 


cmp   word ptr ds:[_scaledviewwidth], SCREENWIDTH
jne   view_border_exists
ret  
view_border_exists:
PUSHA_NO_AX_OR_BP_MACRO
mov   ax, word ptr ds:[_scaledviewwidth]

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
