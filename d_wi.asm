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

; todo optimed out??
PROC WI_GetPatch_ NEAR
PUBLIC WI_GetPatch_

push      bx
mov       bx, ax
add       bx, ax
mov       ax, WIOFFSETS_SEGMENT
mov       es, ax
mov       dx, WIGRAPHICSPAGE0_SEGMENT
mov       ax, word ptr es:[bx]
pop       bx
ret

ENDP

PROC WI_GetAnimPatch_ NEAR
PUBLIC WI_GetAnimPatch_

push      bx
mov       bx, ax
add       bx, ax
mov       ax, WIANIMOFFSETS_SEGMENT
mov       es, ax
mov       dx, WIANIMSPAGE_SEGMENT
mov       ax, word ptr es:[bx]
pop       bx
ret

ENDP

PROC maketwocharint_ NEAR
PUBLIC maketwocharint_

push      dx
push      si
mov       si, ax
mov       es, cx
mov       cx, 10
cwd       
idiv      cx
add       ax, 030h   ; '0' char
mov       byte ptr es:[bx], al
mov       ax, si
cwd       
idiv      cx
mov       byte ptr es:[bx + 2], 0
add       dx, 030h   ; '0' char
mov       byte ptr es:[bx + 1], dl
pop       si
pop       dx
ret       

ENDP


PROC WI_slamBackground_ NEAR
PUBLIC WI_slamBackground_


push      bx
push      cx
push      dx
push      si
push      di
mov       ax, SCREENWIDTH * SCREENHEIGHT
mov       cx, SCREEN1_SEGMENT
mov       dx, SCREEN0_SEGMENT
xor       si, si
xor       di, di
mov       es, dx
mov       bx, SCREENWIDTH
push      ds
push      di
xchg      ax, cx
mov       ds, ax
shr       cx, 1
rep       movsw 
adc       cx, cx
rep       movsb 
pop       di
pop       ds
mov       cx, SCREENHEIGHT
xor       dx, dx
xor       ax, ax

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_MarkRect_addr

pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       

ENDP

PROC WI_drawLF_ NEAR
PUBLIC WI_drawLF_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 2
mov       di, 5 * 2
mov       ax, WIOFFSETS_SEGMENT
mov       cx, WIANIMSPAGE_SEGMENT
mov       dx, 2
xor       si, si
xor       bx, bx
mov       es, ax
mov       ax, SCREENWIDTH
mov       di, word ptr es:[di]
mov       es, cx
push      cx
sub       ax, word ptr es:[si]
push      si
sar       ax, 1
mov       word ptr [bp - 2], WIGRAPHICSPAGE0_SEGMENT

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

push      WIGRAPHICSPAGE0_SEGMENT
mov       es, cx
mov       ax, SCREENWIDTH
mov       si, word ptr es:[si + 2]
xor       bx, bx
mov       dx, si
push      di
shl       dx, 2
mov       es, word ptr [bp - 2]
add       dx, si
sub       ax, word ptr es:[di]
sar       dx, 2
sar       ax, 1
add       dx, 2

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret      

ENDP

PROC WI_drawEL_ NEAR
PUBLIC WI_drawEL_


push      bx
push      dx
mov       bx, 27 * 2
mov       ax, WIOFFSETS_SEGMENT
mov       dx, WIGRAPHICSPAGE0_SEGMENT
mov       es, ax
push      dx
mov       ax, SCREENWIDTH
mov       bx, word ptr es:[bx]
mov       es, dx
push      bx
sub       ax, word ptr es:[bx]
mov       dx, 2
sar       ax, 1
xor       bx, bx

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

mov       ax, WIGRAPHICSLEVELNAME_SEGMENT
mov       bx, MAX_LEVEL_COMPLETE_GRAPHIC_SIZE
mov       es, ax
mov       dx, word ptr es:[bx + 2]
mov       ax, dx
push      es
shl       ax, 2
push      bx
add       dx, ax
mov       ax, SCREENWIDTH
sar       dx, 2
sub       ax, word ptr es:[bx]
add       dx, 2
sar       ax, 1
xor       bx, bx

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

pop       dx
pop       bx
ret       


ENDP

END