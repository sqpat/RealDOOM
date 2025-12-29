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
EXTRN fread_:FAR
EXTRN fwrite_:FAR
EXTRN fgetc_:FAR
EXTRN fputc_:FAR
EXTRN setbuf_:FAR
EXTRN exit_:FAR
EXTRN __flush_:FAR
EXTRN lseek_:FAR
EXTRN __get_errno_ptr_:FAR
EXTRN _tell_:FAR
EXTRN fflush_:FAR

.DATA


COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE



; todo: get rid of UNGET stuff. we dont use this.

_READ    = 00001h    ; file opened for reading 
_WRITE   = 00002h    ; file opened for writing 
_UNGET   = 00004h    ; ungetc has been done 
_BIGBUF  = 00008h    ; big buffer allocated 
_EOF     = 00010h    ; EOF has occurred 
_SFERR   = 00020h    ; error has occurred on this file 
_APPEND  = 00080h    ; file opened for append 
_BINARY  = 00040h    ; file is binary, skip CRLF processing 
_IOFBF   = 00100h    ; full buffering 
_IOLBF   = 00200h    ; line buffering 
_IONBF   = 00400h    ; no buffering 
_TMPFIL  = 00800h    ; this is a temporary file 
_DIRTY   = 01000h    ; buffer has been modified 
_ISTTY   = 02000h    ; is console device 
_DYNAMIC = 04000h   ; FILE is dynamically allocated   
_FILEEXT = 08000h   ; lseek with positive offset has been done 
_COMMIT  = 00001h    ; extended flag: commit OS buffers on flush 


PROC    F_FILE_STARTMARKER_ NEAR
PUBLIC  F_FILE_STARTMARKER_
ENDP

FREAD_BUFFER_SIZE = 512

;void  __far locallib_far_fread(void __far* dest, uint16_t size, FILE * fp) {


PROC    locallib_freadfromfar_   FAR
PUBLIC  locallib_freadfromfar_
call    fread_
retf
ENDP


PROC    locallib_fread_   NEAR
PUBLIC  locallib_fread_
call    fread_
ret
ENDP


PROC    locallib_fopenfromfar_   FAR
PUBLIC  locallib_fopenfromfar_
call    fopen_
retf
ENDP

PROC    locallib_fopen_   NEAR
PUBLIC  locallib_fopen_
call    fopen_
ret
ENDP

PROC    locallib_fclosefromfar_   FAR
PUBLIC  locallib_fclosefromfar_
call    fclose_
retf
ENDP

PROC    locallib_fclose_   NEAR
PUBLIC  locallib_fclose_
call    fclose_
ret
ENDP


PROC    localib_update_buffer_ NEAR
PUBLIC  localib_update_buffer_

; cx:bx = diff, si = file
; return in carry



mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cwd  
cmp  cx, dx
jl   size_check_ok
jne  outside_of_buffer
cmp  bx, ax
ja   outside_of_buffer
size_check_ok:
mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
mov  ax, word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base]
sub  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
cwd  
cmp  cx, dx
jg   update_file
jne  outside_of_buffer
cmp  bx, ax
jae  update_file
outside_of_buffer:
stc
return_update_buffer:

ret  

update_file:
and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], (NOT _EOF)
add  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], bx
sub  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], bx
clc
jmp  return_update_buffer

ENDP


PROC    localib_reset_buffer_ NEAR
PUBLIC  localib_reset_buffer_

; si is file
push bx
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], (NOT _EOF)
mov  bx, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base]
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], bx

pop  bx
ret  


ENDP



; ax = FILE*
; dx = seek type
; cx:bx = position

SEEK_SET = 0
SEEK_CUR = 1
SEEK_END = 2

; bp - 2 = seek type
; si holds fp



PROC    locallib_fseek_   NEAR
PUBLIC  locallib_fseek_

push si
push di
push bp
mov  bp, sp

mov  si, ax

push dx   ; bp - 2. store seek type.

test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 0], (_UNGET OR _WRITE)
je   check_for_seek_end
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_DIRTY SHR 8)
jne  do_flush
cmp  dx, SEEK_CUR
jne  dont_subtract_offset
subtract_offset:
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cwd  
sub  bx, ax
sbb  cx, dx
dont_subtract_offset:
mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link] ; get link
mov  ax, word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base]
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], ax
file_ready_for_seek:
mov  dx, word ptr [bp - 2] ; retrieve seek type
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], (NOT (_EOF OR _UNGET))       ; turn off the flags.
; lseek( int handle, off_t offset, int origin );
do_call_lseek:
call lseek_

cmp  dx, 0FFFFh
jne  status_ok_good_lseek_result

cmp  ax, 0FFFFh
jne  status_ok_good_lseek_result
exit_return_fseek_error:
mov  ax, 0FFFFh     ; a little silly, the fallthru is already 0FFFFh from above.
exit_return_fseek:
mov  sp, bp
pop  bp
pop  di
pop  si
ret 
do_flush:

call __flush_

test ax, ax
je   file_ready_for_seek
test dx, dx
jne  exit_return_fseek_error
test cx, cx
jge  exit_return_fseek_error

invalid_param:
call __get_errno_ptr_
mov  si, ax
mov  word ptr ds:[si], 9
jmp  exit_return_fseek_error

check_for_seek_end:
cmp  dx, SEEK_CUR
je   handle_seek_cur
ja   reset_buffer
; no invlaid param checking.
; SEEK_SET case

mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
call _tell_
mov  di, ax    ; low bytes temporarily
mov  es, dx
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cwd  

sub  di, ax
xchg ax, di  ; low result in ax
mov  di, es
sbb  di, dx
push cx
push bx
sub  bx, ax
sbb  cx, di

call localib_update_buffer_
pop  bx
pop  cx
jnc  status_ok_good_lseek_result

pop  dx  ; bp - 2. seek type

mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]

do_call_lseek2:
call lseek_
cmp  dx, 0FFFFh
jne  not_lseek_error_2
cmp  ax, 0FFFFh
je   exit_return_fseek_error
not_lseek_error_2:

call localib_reset_buffer_
status_ok_good_lseek_result:
xor  ax, ax
jmp  exit_return_fseek
reset_buffer:
call localib_reset_buffer_
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
jmp  do_call_lseek




handle_seek_cur:
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cwd  

push dx
push ax
call localib_update_buffer_
jnc  status_ok_good_lseek_result
pop  ax
sub  bx, ax
pop  ax
sbb  cx, ax
pop  dx  ; bp - 2. seek type
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
jmp  do_call_lseek2



ENDP

PROC    locallib_fseekfromfar_   FAR
PUBLIC  locallib_fseekfromfar_
call    locallib_fseek_
retf
ENDP

PROC    locallib_ftell_   NEAR
PUBLIC  locallib_ftell_

; si is file

push cx
push bx
push si

mov  si, ax

test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 0], _APPEND
je   skip_flush
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], _DIRTY SHR 8
je   skip_flush
mov  ax, si
call fflush_
skip_flush:
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
call _tell_
cmp  dx, 0FFFFh
jne  good_location
cmp  ax, 0FFFFh
je   exit_lseek
good_location:
cmp  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
je   exit_lseek
xchg ax, bx
mov  cx, dx
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cwd  
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_DIRTY SHR 8)
jne  do_add_and_exit
; dx:ax is file_cnt

; cx:bx - dx:ax is equal to -dx:ax + cx:bx
neg  dx
neg  ax
sbb  dx, 0   

do_add_and_exit:
add  ax, bx
adc  dx, cx
exit_lseek:
pop  si
pop  bx
pop  cx

ret


ret
ENDP


PROC    locallib_setbuf_   NEAR
PUBLIC  locallib_setbuf_
call    setbuf_
ret
ENDP

PROC    locallib_fgetc_   NEAR
PUBLIC  locallib_fgetc_
call    fgetc_
ret
ENDP


PROC    locallib_fputc_   NEAR
PUBLIC  locallib_fputc_
call    fputc_
ret
ENDP


PROC    locallib_exit_   NEAR
PUBLIC  locallib_exit_
jmp     exit_

ENDP




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
mov       dx, cx

mov       bx, ds
mov       es, bx

mov       ds, di
lea       di, [bp - FREAD_BUFFER_SIZE] ; todo mov sp?
mov       ax, di

shr       cx, 1         ;FAR_memcpy(destloc, stackbufferfar, copysize);
rep movsw 
adc       cx, cx
rep movsb 

mov       di, ds   ; restore backup segment...

mov       ds, bx   ; restore ds

mov       bx, 1
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

PROC    F_FILE_ENDMARKER_ NEAR
PUBLIC  F_FILE_ENDMARKER_
ENDP


END