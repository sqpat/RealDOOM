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


EXTRN locallib_fopen_nobuffering_:NEAR
EXTRN locallib_fclose_:NEAR
EXTRN locallib_fseek_:NEAR
EXTRN locallib_ftell_:NEAR
EXTRN locallib_fwrite_:NEAR
EXTRN locallib_fread_:NEAR
EXTRN locallib_strcmp_:NEAR


.DATA


.CODE



PROC    M_MISC_STARTMARKER_ NEAR
PUBLIC  M_MISC_STARTMARKER_
ENDP





;boolean __near M_WriteFile (int8_t const* name, void __far* source,filelength_t length );
; ax name
; dx len
; cx/bx source
PROC    M_WriteFile_ NEAR
PUBLIC  M_WriteFile_

push  di

mov   di, dx ; backup dx
mov   dl, (FILEFLAG_WRITE OR FILEFLAG_BINARY)
call  locallib_fopen_nobuffering_

test  ax, ax
je    exit_writefile_return_0

push  ax      ; fp 2nd to retrieve later

mov   dx, cx  ; dx gets segment
xchg  ax, cx  ; fp to cx
xchg  ax, bx  ; dest offset to ax

mov   bx, di  ; len to bx


call  locallib_fwrite_

xchg  ax, dx   ; store result

pop   ax       ; retrieve fp
call  locallib_fclose_

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

mov   dl, (FILEFLAG_READ OR FILEFLAG_BINARY)
call  locallib_fopen_nobuffering_

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

call  locallib_fread_

xchg  ax, si  ; fp

call  locallib_fclose_

POPA_NO_AX_OR_BP_MACRO

ret  


ENDP

; int16_t __near M_CheckParm (int8_t *__far check) {



PROC    M_MISC_ENDMARKER_ NEAR
PUBLIC  M_MISC_ENDMARKER_
ENDP



END