; Copyright (C) 1993-1996 Id Software, Inc.
; Copyright (C) 1993-2008 Raven Software
; Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
; Copyright (C) 2023-2026 Patrick Goncalves (sqpat17)
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


PROC    M_InitFileForWrite_ NEAR
PUBLIC  M_InitFileForWrite_
mov   ax, OFFSET _doomsav0_string
mov   dl, (FILEFLAG_WRITE OR FILEFLAG_BINARY)
call  locallib_fopen_nobuffering_
call  locallib_fclose_              ; delete file

ret

;boolean __near M_WriteFile (int8_t const* name, void __far* source,filelength_t length );
; ax name
; dx len
; cx/bx source
ALIGN_MACRO
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

_currentloadptr:
dw 0, 0

FILE_MAX_BUFFER_CHECK = 16384

PROC    M_InitAndReadFile_ NEAR
PUBLIC  M_InitAndReadFile_

mov   word ptr cs:[_currentloadptr+0], 0
mov   word ptr cs:[_currentloadptr+2], 0  
; fall thru

ENDP    

ALIGN_MACRO
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

sub   ax, word ptr cs:[_currentloadptr+0] ; subtract size by start point
sbb   dx, word ptr cs:[_currentloadptr+2]

test  dx, dx
je    done_capping_size
mov   ax, 65534 ; fill the seg seg
done_capping_size:
xchg  ax, di    ; store length

les   bx, dword ptr cs:[_currentloadptr+0] ; start at start point
mov   cx, es
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



ALIGN_MACRO
; advance the file forward x bytes.
PROC    M_AppendFle_ NEAR


; dx is len
; ax is ptr to filename

push  dx  ; ; backup size
mov   dl, (FILEFLAG_WRITE OR FILEFLAG_BINARY OR FILEFLAG_APPEND)
call  locallib_fopen_nobuffering_

pop   dx ; retrieve size/len

xchg  ax, cx ; cx gets fp, ax gets segment
xchg  ax, dx ; dx gets segment, ax gets len
xchg  ax, bx ; bx gets len, ax gets offset


push  cx      ; back up fp once more


call  locallib_fwrite_

pop   ax       ; retrieve fp
call  locallib_fclose_

ret  

ENDP


ALIGN_MACRO
; advance the file forward x bytes.
PROC    M_AdvanceWriteFile_ FAR
PUBLIC  M_AdvanceWriteFile_
;
push    cx
mov     cx, SCRATCH_SEGMENT_5000
xor     bx, bx
; dx has size
mov     ax, OFFSET _doomsav0_string


call    M_AppendFle_
pop     cx

retf

ENDP
ALIGN_MACRO
; advance the file forward 16384 
PROC    M_AdvanceLoadFile_ FAR
PUBLIC  M_AdvanceLoadFile_

add     word ptr cs:[_currentloadptr+0], FILE_MAX_BUFFER_CHECK
adc     word ptr cs:[_currentloadptr+2], 0  

push    cx
push    bx
mov     cx, SCRATCH_SEGMENT_5000
xor     bx, bx
mov     ax, OFFSET _savename


call    M_ReadFile_



pop     bx
pop     cx

retf


ENDP

; int16_t __near M_CheckParm (int8_t *__far check) {



PROC    M_MISC_ENDMARKER_ NEAR
PUBLIC  M_MISC_ENDMARKER_
ENDP



END