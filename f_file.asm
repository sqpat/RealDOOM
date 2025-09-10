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


EXTRN fread_:FAR
EXTRN fwrite_:FAR

.DATA


COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE


PROC    F_FILE_STARTMARKER_ NEAR
PUBLIC  F_FILE_STARTMARKER_
ENDP

FREAD_BUFFER_SIZE = 512

;void  __far locallib_far_fread(void __far* dest, uint16_t size, FILE * fp) {



PROC    locallib_far_fread_   FAR
PUBLIC  locallib_far_fread_


push      si
push      di
push      bp
mov       bp, sp
sub       sp, FREAD_BUFFER_SIZE
xchg      ax, di  ; di = dest offset
mov       si, dx  ; si = dest segment
mov       dx, bx ; dx gets size to read

; si has dest segment
; di has dest offset
; dx has size to read...
; cx has fp

loop_fread_next_chunk:

push      dx  ; [MATCH A]  size left to read

cmp       dx, FREAD_BUFFER_SIZE
jb        use_remaining_write_size     ; unsigned compare
mov       dx, FREAD_BUFFER_SIZE
use_remaining_write_size:


push      cx  ; [MATCH B]  fp
push      dx  ; [MATCH C]  size to read this time
lea       ax, [bp - FREAD_BUFFER_SIZE]
mov       bx, 1
push      ax  ; [MATCH D]  buffer pos
call      fread_   ;fread(stackbuffer, copysize, 1, fp);

mov       es, si ; dest segment in es
pop       si     ; [MATCH D]  buffer pos
		
pop       cx     ; [MATCH C]  size to read this time
mov       bx, cx ; len copy 


                ; ds = ss
                ; di updates as we go set

shr       cx, 1         ;FAR_memcpy(destloc, stackbufferfar, copysize);
rep movsw 
adc       cx, cx
rep movsb 

mov       si, es   ; restore segment...
pop       cx     ; [MATCH B]  fp
pop       dx     ; [MATCH A]  size left to read
sub       dx, bx
jne       loop_fread_next_chunk
skip_read_zero:

LEAVE_MACRO
pop       di
pop       si
retf

ENDP



PROC    locallib_far_fwrite_ FAR
PUBLIC  locallib_far_fwrite_
;filelength_t  __far locallib_far_fwrite(void __far* src, uint16_t elementsize, uint16_t elementcount, FILE * fp) {


push      si
push      di
push      bp
mov       bp, sp
sub       sp, FREAD_BUFFER_SIZE
xchg      ax, si  ; si = src offset
mov       di, dx  ; di = src segment
mov       ax, bx
mul       cx
jz        skip_write_zero

xchg      ax, cx ; cx gets size to write

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
mov       dx, cx

mov       bx, ds
mov       es, bx

mov       ds, di
lea       di, [bp - FREAD_BUFFER_SIZE]
mov       ax, di

shr       cx, 1         ;FAR_memcpy(destloc, stackbufferfar, copysize);
rep movsw 
adc       cx, cx
rep movsb 

mov       di, ds   ; restore backup segment...

mov       ds, bx   ; restore ds

mov       bx, 1
mov       cx, word ptr [bp + 0Ah]   ; fp


call      fwrite_   ;fwrite(stackbuffer, copysize, 1, fp);


		
pop       bx     ; [MATCH B]  size to write this time
pop       cx     ; [MATCH A]  size left to write
sub       cx, bx
jne       loop_fwrite_next_chunk

skip_write_zero:

LEAVE_MACRO
pop       di
pop       si
retf      2

ENDP

PROC    F_FILE_ENDMARKER_ NEAR
PUBLIC  F_FILE_ENDMARKER_
ENDP


END