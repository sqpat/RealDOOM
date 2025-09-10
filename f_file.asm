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

;void  __far locallib_far_fread(void __far* dest, uint16_t elementsize, uint16_t elementcount, FILE * fp) {

; todo combne dx/cx into one

PROC    locallib_far_fread_ FAR
PUBLIC  locallib_far_fread_


push      si
push      di
push      bp
mov       bp, sp
sub       sp, FREAD_BUFFER_SIZE
xchg      ax, di  ; di = dest offset
mov       si, dx  ; si = dest segment
mov       ax, bx
mul       cx
jz        skip_read_zero

xchg      ax, dx ; dx gets size to read

; si has dest segment
; di has dest offset
; dx has size to read...

loop_fread_next_chunk:

push      dx  ; [MATCH A]  size left to read

cmp       dx, FREAD_BUFFER_SIZE
jb        use_remaining_size     ; unsigned compare
mov       dx, FREAD_BUFFER_SIZE
use_remaining_size:


push      dx  ; [MATCH B]  size to read this time
lea       ax, [bp - FREAD_BUFFER_SIZE]
mov       bx, 1
mov       cx, word ptr [bp + 0Ah]   ; fp
push      ax  ; [MATCH C]  buffer pos

call      fread_   ;fread(stackbuffer, copysize, 1, fp);

mov       es, si ; dest segment in es
pop       si     ; [MATCH C]  buffer pos
		
pop       cx     ; [MATCH B]  size to read this time
mov       bx, cx ; len copy 
lea       si, [bp - FREAD_BUFFER_SIZE]

                ; ds = ss
                ; di updates as we go set

shr       cx, 1         ;FAR_memcpy(destloc, stackbufferfar, copysize);
rep movsw 
adc       cx, cx
rep movsb 

mov       si, es   ; restore segment...

pop       dx  ; [MATCH A]  size left to read
sub       dx, bx
jne       loop_fread_next_chunk
skip_read_zero:

LEAVE_MACRO
pop       di
pop       si
retf      2

ENDP



PROC    locallib_far_fwrite_ FAR
PUBLIC  locallib_far_fwrite_


push      si
push      di
push      bp
mov       bp, sp
sub       sp, 020Eh
mov       si, ax
mov       di, dx
mov       ax, bx
mul       cx
mov       word ptr [bp - 4], 0
mov       word ptr [bp - 0Ch], ds
mov       word ptr [bp - 6], si
mov       word ptr [bp - 0Eh], di
lea       cx, [bp - 020Eh]
mov       word ptr [bp - 8], ax
mov       word ptr [bp - 0Ah], cx
test      ax, ax
jbe       label_3
mov       di, word ptr [bp - 0Ah]
label_5:
mov       ax, word ptr [bp - 8]
sub       ax, word ptr [bp - 4]
cmp       ax, FREAD_BUFFER_SIZE
jae       label_4
mov       word ptr [bp - 2], ax
label_6:
mov       ax, word ptr [bp - 2]
mov       si, word ptr [bp - 6]
les       cx, dword ptr [bp - 0Eh]
mov       bx, 1
mov       dx, word ptr [bp - 2]
push      ds
push      di
xchg      ax, cx
mov       ds, ax
shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 
pop       di
pop       ds
mov       cx, word ptr [bp + 0Ah]
lea       ax, [bp - 020Eh]

call      fwrite_
mov       ax, word ptr [bp - 2]
add       word ptr [bp - 4], ax
add       word ptr [bp - 6], ax
mov       ax, word ptr [bp - 4]
cmp       ax, word ptr [bp - 8]
jb        label_5
label_3:
mov       ax, word ptr [bp - 4]
LEAVE_MACRO
pop       di
pop       si
retf      2
label_4:
mov       word ptr [bp - 2], FREAD_BUFFER_SIZE
jmp       label_6

ENDP

PROC    F_FILE_ENDMARKER_ NEAR
PUBLIC  F_FILE_ENDMARKER_
ENDP


END