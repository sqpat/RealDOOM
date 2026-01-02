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


EXTRN fwrite_:FAR


.DATA


.CODE
FREAD_BUFFER_SIZE = 512


; this is just for bingen.

PROC    locallib_fopen_ NEAR
PUBLIC  locallib_fopen_
ENDP
PROC    locallib_fseek_ NEAR
PUBLIC  locallib_fseek_
ENDP
PROC    locallib_fread_ NEAR
PUBLIC  locallib_fread_
ENDP
PROC    locallib_ftell_ NEAR
PUBLIC  locallib_ftell_
ENDP
PROC    locallib_fclose_ NEAR
PUBLIC  locallib_fclose_
ENDP
PROC    locallib_fread_nearsegment_ NEAR
PUBLIC  locallib_fread_nearsegment_
ENDP
PROC    locallib_fopenfromfar_ NEAR
PUBLIC  locallib_fopenfromfar_
ENDP
PROC    locallib_fseekfromfar_ NEAR
PUBLIC  locallib_fseekfromfar_
ENDP
PROC    locallib_freadfromfar_ NEAR
PUBLIC  locallib_freadfromfar_
ENDP
PROC    locallib_fclosefromfar_ NEAR
PUBLIC  locallib_fclosefromfar_
ENDP
PROC    locallib_fgetc_ NEAR
PUBLIC  locallib_fgetc_
ENDP
PROC    locallib_fputc_ NEAR
PUBLIC  locallib_fputc_
ENDP
PROC    locallib_fwrite_ NEAR
PUBLIC  locallib_fwrite_
ENDP
PROC    locallib_setbuf_ NEAR
PUBLIC  locallib_setbuf_
ENDP

ret


PROC    locallib_far_fwrite_ NEAR
PUBLIC  locallib_far_fwrite_
;filelength_t  __far locallib_far_fwrite(void __far* src, uint16_t elementsize, uint16_t elementcount, FILE * fp) {

push      cx      ; fp = bp + 6
push      si      ; bp + 4
push      di      ; bp + 2
push      bp      ; bp + 0
mov       bp, sp
sub       sp, FREAD_BUFFER_SIZE
xchg      ax, si  ; si = src offset
mov       di, dx  ; di = src segment
mov       cx, bx

; cx has size 
; si has dest segment
; di has dest offset
; dx has size to write...

loop_fwrite_next_chunk:

push      cx  ; [MATCH A]  size left to write
mov       dx, cx
cmp       cx, FREAD_BUFFER_SIZE
jb        use_remaining_read_size     ; unsigned compare
mov       cx, FREAD_BUFFER_SIZE
use_remaining_read_size:

push      cx  ; [MATCH B]  size to write this time

mov       dx, ds
mov       es, dx
mov       bx, cx

mov       ds, di
lea       di, [bp - FREAD_BUFFER_SIZE] ; todo mov sp?
mov       ax, di

shr       cx, 1         ;FAR_memcpy(destloc, stackbufferfar, copysize);
rep movsw 
adc       cx, cx
rep movsb 

mov       di, ds   ; restore backup segment...

mov       ds, dx   ; restore ds

mov       dx, 1
mov       cx, word ptr [bp + 6]   ; fp


call      fwrite_   ;fwrite(stackbuffer, copysize, 1, fp);


		
pop       bx     ; [MATCH B]  size to write this time
pop       cx     ; [MATCH A]  size left to write
sub       cx, bx
jne       loop_fwrite_next_chunk

skip_write_zero:

LEAVE_MACRO
pop       di
pop       si
pop       cx
ret

ENDP

END