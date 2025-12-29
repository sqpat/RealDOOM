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


EXTRN locallib_fopen_:NEAR
EXTRN fclose_:FAR
EXTRN locallib_fseek_:NEAR
EXTRN locallib_ftell_:NEAR
EXTRN locallib_far_fwrite_:NEAR
EXTRN locallib_far_fread_:FAR
EXTRN locallib_strcmp_:NEAR
EXTRN locallib_strlwr_:NEAR


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

;boolean __near M_WriteFile (int8_t const* name, void __far* source,filelength_t length );
; ax name
; dx len
; cx/bx source
PROC    M_WriteFile_ NEAR
PUBLIC  M_WriteFile_

push  di

mov   di, dx ; backup dx
mov   dx, _fopen_wb_argument
call  locallib_fopen_

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
call  locallib_fopen_

push  bx
push  cx

xor   bx, bx
xor   cx, cx
mov   dx, 2     ; SEEK_END
mov   si, ax    ; store fp
call  locallib_fseek_

mov   ax, si    ; fp
call  locallib_ftell_

xchg  ax, di    ; store length

xor   bx, bx
xor   cx, cx
xor   dx, dx    ; SEEK_SET


mov   ax, si    ; fp
call  locallib_fseek_

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

; int16_t __near M_CheckParm (int8_t *__far check) {



PROC    M_CheckParm_CS_   NEAR
PUBLIC  M_CheckParm_CS_
mov     dx, cs
ENDP
PROC    M_CheckParm_   NEAR
PUBLIC  M_CheckParm_


PUSHA_NO_AX_MACRO


xchg ax, di   ; di stores arg offset
mov  bp, dx   ; bp stores arg segment

mov  si, 1
cmp  si, word ptr ds:[_myargc]
jge  exit_check_parm_return_0

loop_check_next_parm:
sal  si, 1
mov  bx, word ptr ds:[_myargv] ; myargv
mov  ax, word ptr ds:[bx + si] ; myargv[i]
mov  dx, ds
call locallib_strlwr_   ;  locallib_strlwr(myargv[i]);

mov  ax, di
mov  dx, bp
mov  bx, word ptr ds:[bx + si] ; myargv[i]
mov  cx, ds

call locallib_strcmp_ ; todo carry return?      ; if ( !locallib_strcmp(check, myargv[i]) )

shr  si, 1

test ax, ax
mov  ax, si
je   exit_check_parm_return

xchg ax, bx ; retrieve check


inc  si
cmp  si, word ptr ds:[_myargc]
jl   loop_check_next_parm


exit_check_parm_return_0:
xor  ax, ax
exit_check_parm_return:

mov  es, ax
POPA_NO_AX_MACRO
mov  ax, es

ret

ENDP

PROC    M_MISC_ENDMARKER_ NEAR
PUBLIC  M_MISC_ENDMARKER_
ENDP



END