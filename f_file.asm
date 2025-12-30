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
EXTRN setvbuf_:FAR

EXTRN exit_:FAR
EXTRN __SetIOMode_nogrow_:FAR
EXTRN __GetIOMode_:FAR
EXTRN __get_errno_ptr_:FAR
EXTRN __set_errno_dos_:FAR
EXTRN __qwrite_:FAR
EXTRN __qread_:FAR
EXTRN __doserror_:FAR
EXTRN __ioalloc_:FAR
EXTRN getche_:FAR


.DATA

EXTRN _errno:WORD
EXTRN ___OpenStreams:WORD

COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

FILE_BUFFER_SIZE = 512


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

;todo what uses this
PROC    locallib_fclose_inner   NEAR

push  bx
mov   bx, ax
mov   ah, 03Eh
int   021h
call  __doserror_  ; check carry flag etc
pop   bx
ret

ENDP


PROC    locallib_fsync_   NEAR

;  bx already had file handle
mov   ah, 068h  ; INT 21,68 - Flush Buffer Using Handle (DOS 3.3+)
clc   
int   021h
call  __doserror_  ; check carry flag etc
ret

ENDP


; si holds fp


PROC    locallib_flush_   NEAR

push bx
push cx
push dx
push si
push di
push bp  ; bp is ret
mov  si, ax
xor  bp, bp  ; ret
mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_DIRTY SHR 8)
je   file_not_dirty
jmp  file_is_dirty
file_not_dirty:
cmp  word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
je   finish_handling_flush
and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 0], (NOT _EOF)
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_ISTTY SHR 8)
jne  finish_handling_flush
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cwd  
mov  bx, dx
or   bx, ax
je   skip_seek
xchg ax, dx  ; low word into dx
xchg ax, cx  ; hi word into cx
mov  al, 1
neg  cx
neg  dx
sbb  cx, 0
mov  bx, di

call locallib_inner_lseek_

skip_seek:
cmp  dx, 0FFFFh
jne  finish_handling_flush
cmp  ax, 0FFFFh
jne  finish_handling_flush
mov  bp, 0FFFFh
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR

finish_handling_flush:
mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]

mov  ax, word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base]
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], ax
test bp, bp
jne  exit_flush

test byte ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_extflags], _COMMIT
jne  do_file_sync
exit_flush:
xchg ax, bp
exit_flush_skip_bp:
pop  bp
pop  di
pop  si
pop  dx
pop  cx
pop  bx
ret

file_is_dirty:
and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], ((NOT _DIRTY) SHR 8)  ; mark not dirty?
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 0], _WRITE
je   finish_handling_flush

mov  ax, word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base]
test ax, ax
je   finish_handling_flush
mov  di, ax
mov  cx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]


test cx, cx
flush_more_to_file:
je   finish_handling_flush
test bp, bp
jne  finish_handling_flush
mov  bx, cx
mov  dx, di
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
call __qwrite_

mov  dx, ax
cmp  ax, 0FFFFh
je  handle_error_len_case
test ax, ax
je   zero_flushed_error
not_error_flush_more:
add  di, dx
sub  cx, dx
jmp  flush_more_to_file
zero_flushed_error:
call __get_errno_ptr_
mov  bx, ax
mov  word ptr ds:[bx], 0Ch
mov  bp, 0FFFFh
jmp  set_err_flag

handle_error_len_case:
mov  bp, ax
set_err_flag:
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR
jmp  not_error_flush_more


do_file_sync:
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
call locallib_fsync_
cmp  ax, 0FFFFh
jne  exit_flush
jmp  exit_flush_skip_bp


ENDP

PROC   locallib_flushall_  NEAR

mov  ax, 0FFFFh
; fallthru? flush any flags.
ENDP


; ax is flags to flush/
PROC   locallib_flushall_inner_ NEAR

push bx
push cx
push dx
push si

mov  cx, ax
mov  bx, word ptr ds:[___OpenStreams]
xor  dx, dx  ; return value, flushed count?
loop_flushall_more_bytes:
test bx, bx
je   exit_flushall_inner_return ; end of the list?
mov  si, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_stream]
test word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], cx
jne  flag_is_match
increment_and_check_next_stream_for_flush:
increment_and_check_next_stream_for_flush:
mov  bx, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_next]  ; check next stream
jmp  loop_flushall_more_bytes
flag_is_match:
inc  dx
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_DIRTY SHR 8)
je   increment_and_check_next_stream_for_flush ; not dirty, skip
mov  ax, si
call locallib_flush_
jmp  increment_and_check_next_stream_for_flush

exit_flushall_inner_return:
mov  ax, dx
pop  si
pop  dx
pop  cx
pop  bx
ret

ENDP




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

and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], (NOT (_EOF OR _UNGET))       ; turn off the flags.
; lseek( int handle, off_t offset, int origin );
do_call_lseek:
call locallib_lseek_

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

call locallib_flush_

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


call locallib_tell_
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



do_call_lseek2:
call locallib_lseek_
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

jmp  do_call_lseek2



ENDP

PROC    locallib_fseekfromfar_   FAR
PUBLIC  locallib_fseekfromfar_
call    locallib_fseek_
retf
ENDP


PROC    locallib_inner_lseek_   NEAR
PUBLIC  locallib_inner_lseek_

; al is passed in with the file type
; cx:dx the size
; bx the file handle... ready to go

;    AL = origin of move:
;	     00 = beginning of file plus offset  (SEEK_SET)
;	     01 = current location plus offset	(SEEK_CUR)
;	     02 = end of file plus offset  (SEEK_END)
;	BX = file handle
;	CX = high order word of number of bytes to move
;	DX = low order word of number of bytes to move

; pass in seek type in al instead of dx.
; pass in handle in bx 


mov  ah, 042h   ; Move file pointer using handle
int  021h 
jc   do_errno_inner_lseek
exit_inner_lseek:
ret
do_errno_inner_lseek:
call __set_errno_dos_
jmp  exit_inner_lseek

ENDP



PROC    locallib_lseek_ NEAR

; si is file, not file handle...
push si
push dx  ; seek type to retrieve later
mov  si, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]

call __GetIOMode_
test cx, cx
jg   positive_size
jne  do_inner_lseek
test bx, bx
jbe  do_inner_lseek
positive_size:
test al, 080h
jne  do_inner_lseek
or   ah, 080h
mov  dx, ax
mov  ax, si
call __SetIOMode_nogrow_

do_inner_lseek:
pop  ax ; retrieve seek type
mov  dx, bx  ; low size word
mov  bx, si  ; file
call locallib_inner_lseek_
pop  si ; retireve file
ret 

ENDP

PROC    locallib_tell_ NEAR

; si = file handle

push bx
push cx
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]  ; si is always file handle here
mov  al, 1
xor  dx, dx
xor  cx, cx
call locallib_inner_lseek_
pop  cx
pop  bx
ret 
ENDP

PROC    locallib_fflush_ NEAR

test ax, ax
jne  do_ref_flush
call locallib_flushall_
xor  ax, ax
ret 

do_ref_flush:
call  locallib_flush_
ret

ENDP

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
call locallib_fflush_
skip_flush:

call locallib_tell_
cmp  dx, 0FFFFh
jne  good_location
cmp  ax, 0FFFFh
je   exit_ftell
good_location:
cmp  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
je   exit_ftell
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
exit_ftell:
pop  si
pop  bx
pop  cx

ret


ret
ENDP


PROC    locallib_setbuf_   NEAR
PUBLIC  locallib_setbuf_

push bx
push cx
mov  bx, _IOFBF
test dx, dx
jne  label_1
mov  bx, _IONBF
label_1:
mov  cx, FILE_BUFFER_SIZE
call setvbuf_  ;     setvbuf( fp, buf, mode, BUFSIZ );
pop  cx
pop  bx
ret


ret
ENDP

PROC    locallib_fill_buffer_   NEAR

push bx
push dx
push si
mov  si, ax
mov  bx, word ptr [si + WATCOM_C_FILE.watcom_file_link]
cmp  word ptr [bx + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
jne  dont_ioalloc
call __ioalloc_
dont_ioalloc:
mov  al, byte ptr [si + WATCOM_C_FILE.watcom_file_flag+1]
test al, (_ISTTY SHR 8)
je   dont_flush
test al, 6
je   dont_flush
mov  ax, _ISTTY
call locallib_flushall_inner_
dont_flush:
mov  bx, word ptr [si + WATCOM_C_FILE.watcom_file_link]
and  byte ptr [si + WATCOM_C_FILE.watcom_file_flag], (NOT _UNGET)
mov  ax, word ptr [bx + WATCOM_STREAM_LINK.watcom_streamlink_base]
mov  word ptr [si + WATCOM_C_FILE.watcom_file_ptr], ax
mov  ax, word ptr [si + WATCOM_C_FILE.watcom_file_flag]
and  ax, (_ISTTY OR _IONBF)
cmp  ax, (_ISTTY OR _IONBF)
jne  label_8
mov  ax, word ptr [si + WATCOM_C_FILE.watcom_file_handle]
test ax, ax
jne  label_8
mov  word ptr [si + WATCOM_C_FILE.watcom_file_cnt], ax

call getche_

mov  dx, ax
cmp  ax, 0FFFFh
jne  label_9

label_3:
mov  ax, word ptr [si + WATCOM_C_FILE.watcom_file_cnt]
test ax, ax
jnle label_6
jne  label_5
or   byte ptr [si + WATCOM_C_FILE.watcom_file_flag], _EOF
jmp  label_6
label_5:
mov  word ptr [si + WATCOM_C_FILE.watcom_file_cnt], 0
or   byte ptr [si + WATCOM_C_FILE.watcom_file_flag], _SFERR
label_6:
mov  ax, word ptr [si + WATCOM_C_FILE.watcom_file_cnt]
pop  si
pop  dx
pop  bx
ret 
label_9:
mov  bx, word ptr [si + WATCOM_C_FILE.watcom_file_ptr]
mov  byte ptr [bx], al
mov  word ptr [si + WATCOM_C_FILE.watcom_file_cnt], 1
jmp  label_6

label_8:
test byte ptr [si + WATCOM_C_FILE.watcom_file_flag+1], (_IONBF SHR 8)
mov  bx, 1
jne  label_4
mov  bx, word ptr [si + WATCOM_C_FILE.watcom_file_bufsize]
label_4:
mov  dx, word ptr [si + WATCOM_C_FILE.watcom_file_ptr]
mov  ax, word ptr [si + WATCOM_C_FILE.watcom_file_handle]
call __qread_
mov  word ptr [si + WATCOM_C_FILE.watcom_file_cnt], ax
jmp  label_3

ENDP

PROC    locallib_filbuf_   NEAR

push si
mov  si, ax
call locallib_fill_buffer_
test ax, ax
jne  label_2
mov  ax, 0FFFFh
pop  si
ret  
label_2:
dec  word ptr [si + 2]
inc  word ptr [si]
mov  si, word ptr [si]
mov  al, byte ptr [si - 1]
xor  ah, ah
pop  si
ret  

ENDP

PROC    locallib_fgetc_   NEAR
PUBLIC  locallib_fgetc_

push bx
push si
mov  bx, ax
mov  si, word ptr [bx + 4]
mov  ax, word ptr [si + 6]
cmp  ax, 1
je   label_10
test ax, ax
jne  exit_fgetc_return_error
mov  word ptr [si + 6], 1
label_10:
test byte ptr [bx + 6], 1
jne  label_11
call __get_errno_ptr_
mov  si, ax
mov  word ptr [si], 4
mov  ax, 0FFFFh
or   byte ptr [bx + 6], _SFERR
label_13:
test byte ptr [bx + 6], _BINARY
jne  exit_fgetc
cmp  ax, 0Dh
jne  skip_newline_garbage_getc
dec  word ptr [bx + 2]
cmp  word ptr [bx + 2], 0
jl   label_12
mov  si, word ptr [bx]
mov  al, byte ptr [si]
inc  si
xor  ah, ah
mov  word ptr [bx], si
skip_newline_garbage_getc:
cmp  ax, 01Ah    ; todo?
jne  exit_fgetc
mov  ax, 0FFFFh
or   byte ptr [bx + 6], _EOF
exit_fgetc:
pop  si
pop  bx
ret 
exit_fgetc_return_error:
mov  ax, 0FFFFh
pop  si
pop  bx
ret 
label_11:
dec  word ptr [bx + 2]
cmp  word ptr [bx + 2], 0
jl   label_14
mov  si, word ptr [bx]
mov  al, byte ptr [si]
inc  si
xor  ah, ah
mov  word ptr [bx], si
jmp  label_13
label_14:
mov  ax, bx
call locallib_filbuf_
jmp  label_13
label_12:
mov  ax, bx
call locallib_filbuf_
jmp  skip_newline_garbage_getc

ret
ENDP


PROC    locallib_fputc_   NEAR
PUBLIC  locallib_fputc_

push bx
push cx
push si
push di

xchg ax, cx  ; char in cx
mov  si, dx
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]

; mov  ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_orientation]
; cmp  ax, 1
; je   use_byte_orientation    ; todo not necessary check?
; test ax, ax
; je   set_byte_orientation
; jmp  exit_fputc_return_error
; set_byte_orientation:
; mov  word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_orientation], 1
; use_byte_orientation:

test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _WRITE
je   handle_fputc_error   ; not open for writing!
cmp  word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
jne  have_buffer_location
mov  ax, si
call __ioalloc_

have_buffer_location:

mov  dx, _IONBF
cmp  cl, 0Ah   ; newline char check
je   handle_newline_crap

prepare_to_put_char:
mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag+1], (_DIRTY SHR 8)
mov  byte ptr ds:[di], cl   ; write the char.
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
test word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag+0], dx
jne  flush_character
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cmp  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
jne  record_written_char
flush_character:
mov  ax, si
call locallib_flush_
test ax, ax
jne  exit_fputc_return_error

record_written_char:
mov  al, cl
xor  ah, ah


exit_fputc:
pop  di
pop  si
pop  cx
pop  bx
ret

handle_newline_crap:
or   dh, (_IOLBF SHR 8)
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag+0], _BINARY
jne  prepare_to_put_char    ; handle like a regular char
; really do newline shenanigans.
mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag+1], (_DIRTY SHR 8)
mov  byte ptr ds:[di], 0Dh
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cmp  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
jne  prepare_to_put_char
mov  ax, si

call locallib_flush_
test ax, ax
je   prepare_to_put_char
jmp  exit_fputc_return_error

handle_fputc_error:
call __get_errno_ptr_
mov  di, ax
mov  word ptr ds:[di], 4
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR
exit_fputc_return_error:
mov  ax, 0FFFFh
jmp  exit_fputc


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