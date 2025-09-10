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


EXTRN fopen_:FAR
EXTRN fclose_:FAR
EXTRN fseek_:FAR
EXTRN ftell_:FAR
EXTRN locallib_far_fwrite_:FAR
EXTRN locallib_far_fread_:FAR


.DATA


.CODE



PROC    M_MISC_STARTMARKER_ NEAR
PUBLIC  M_MISC_STARTMARKER_
ENDP

; M_Random preserving es:bx
PROC M_Random_ NEAR
PUBLIC M_Random_

;    rndindex = (rndindex+1)&0xff;
;    return rndtable[rndindex];

push     bx
mov      ax, RNDTABLE_SEGMENT
mov      es, ax
xor      ax, ax
mov      bx, ax
inc      byte ptr ds:[_rndindex]
mov      bl, byte ptr ds:[_rndindex]
mov      al, byte ptr es:[bx]
pop      bx
ret

ENDP

;void __near M_AddToBox16 ( int16_t	x, int16_t	y, int16_t __near*	box  );

PROC    M_AddToBox16_ NEAR
PUBLIC  M_AddToBox16_

cmp   ax, word ptr [bx + (2 * BOXLEFT)]
jl    write_x_to_left
cmp   ax, word ptr [bx + (2 * BOXRIGHT)]
jle   do_y_compare
mov   word ptr [bx + (2 * BOXRIGHT)], ax
do_y_compare:
cmp   dx, word ptr [bx + (2 * BOXBOTTOM)]
jl    write_y_to_bottom
cmp   dx, word ptr [bx + (2 * BOXTOP)]
jng   exit_m_addtobox16
mov   word ptr [bx + (2 * BOXTOP)], dx
exit_m_addtobox16:
ret   
write_x_to_left:
mov   word ptr [bx + (2 * BOXLEFT)], ax
jmp   do_y_compare
write_y_to_bottom:
mov   word ptr [bx + (2 * BOXBOTTOM)], dx
ret   

ENDP


PROC    M_WriteFile_ NEAR
PUBLIC  M_WriteFile_

push  di

mov   di, dx ; backup dx
mov   dx, _fopen_w_argument
call  fopen_

test  ax, ax
je    exit_writefile_return_0

push  ax      ; fp 2nd to retrieve later

mov   dx, cx  ; dx gets segment
xchg  ax, cx  ; fp to cx
xchg  ax, bx  ; dest offset to ax

mov   bx, di  ; len to bx


call  locallib_far_fwrite_

xchg  ax, dx   ; store result

pop   ax       ; retrieve fp
call  fclose_

cmp   dx, di
jb    exit_writefile_return_0
mov   al, 1
pop   di
ret  

exit_writefile_return_0:
xor   ax, ax
exit_writefile:

pop   di
ret  


ENDP

PROC    M_ReadFile_ NEAR
PUBLIC  M_ReadFile_


PUSHA_NO_AX_OR_BP_MACRO

mov   dx, _fopen_rb_argument
call  fopen_

push  bx
push  cx

xor   bx, bx
xor   cx, cx
mov   dx, 2     ; SEEK_END
mov   si, ax    ; store fp
call  fseek_

mov   ax, si    ; fp
call  ftell_

xchg  ax, di    ; store length

xor   bx, bx
xor   cx, cx
xor   dx, dx    ; SEEK_SET


mov   ax, si    ; fp
call  fseek_

mov   bx, di  ; bx gets len

pop   dx  ; seg
pop   ax  ; off



mov   cx, si    ; fp

call  locallib_far_fread_

xchg  ax, si  ; fp

call  fclose_

POPA_NO_AX_OR_BP_MACRO

ret  


ENDP

PROC    M_MISC_ENDMARKER_ NEAR
PUBLIC  M_MISC_ENDMARKER_
ENDP



END