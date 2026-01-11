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


EXTRN I_Error_:FAR

.DATA




; not sure if word or what




COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

FILE_BUFFER_SIZE = 512

MAX_FILE_BUFFERS = 2

MAX_FILES = 6


.CODE



; todo: get rid of unused stuff

_READ    = 00001h    ; file opened for reading 
_WRITE   = 00002h    ; file opened for writing 
_BIGBUF  = 00008h    ; big buffer allocated 
_EOF     = 00010h    ; EOF has occurred 
_SFERR   = 00020h    ; error has occurred on this file 

_BINARY  = 00040h    ; file is binary, skip CRLF processing 
_IOFBF   = 00100h    ; full buffering 
_IOLBF   = 00200h    ; line buffering 
_IONBF   = 00400h    ; no buffering 







_O_RDONLY        = 00000h ;  open for read only 
_O_WRONLY        = 00001h ;  open for write only 
_O_RDWR          = 00002h ;  open for read and write 

_O_CREAT         = 00020h ;  create new file 
_O_TRUNC         = 00040h ;  truncate existing file 
_O_NOINHERIT     = 00080h ;  file is not inherited by child process




PROC    F_FILE_STARTMARKER_ NEAR
PUBLIC  F_FILE_STARTMARKER_
ENDP

FREAD_BUFFER_SIZE = 512



_buffercount:
db  0

_BAD_FCLOSE_STR:
db "!! Bad FClose!", 0Ah, 0
_BAD_FSEEK_STR:
db "!! Bad FSeek!", 0Ah, 0

_BAD_QWRITE_STR:
db "!! Bad QWrite!", 0Ah, 0

_BAD_QREAD_STR:
db "!! Bad QRead!", 0Ah, 0

_OUTOFFILES_STR:
db "!! Out of static files!", 0Ah, 0
_OVERALLOCATED_STR:
db "!! Overallocated file buffers!", 0Ah, 0

_UNDERALLOCATED_STR:
db "!! Underallocated file buffers!", 0Ah, 0



PROC    malloc_ NEAR
PUBLIC  malloc_

xor     ax, ax
mov     ah, byte ptr cs:[_buffercount]
cmp     ah, MAX_FILE_BUFFERS
jae     error_overallocated
shl     ah, 1  ; 512 times buffer count
add     ax, OFFSET _filebufferstart
inc     byte ptr cs:[_buffercount]

ret




; NOTE: realdoom fwrites do not use buffer. they dump the whole file at once


PROC    locallib_fwrite_ NEAR
PUBLIC  locallib_fwrite_

; dx:ax = far source, bx = num bytes, cx = fp

push      si
push      di
push      bp
mov       bp, sp


mov       si, cx   ; fp
mov       cx, bx   ; numbytes

; bx has size
; dx has segment

xchg      ax, dx   ; dx gets copy source ptr
push      ax       ; push target segment


mov       di, word ptr ds:[si + FILE_INFO_T.fileinto_flag]
and       di, (_SFERR OR _EOF)

and       byte ptr ds:[si + FILE_INFO_T.fileinto_flag], (NOT (_SFERR OR _EOF))

do_binary_fwrite:



;call      locallib_qwrite_
; inlined

; never do appends. always a whole write.

mov       bx, word ptr ds:[si + FILE_INFO_T.fileinto_handle]
pop       ds  ; get target segment
; DS:DX is now fwrite source
mov       ah, 040h  ; Write file or device using handle
int       021h

push      ss
pop       ds     ; restore ds


jc        do_qwrite_fwrite_error

cmp       ax, cx   ; did we write all the bytes?
je        fwrote_everything

do_qwrite_fwrite_error:

mov     ax, OFFSET _BAD_QWRITE_STR
jmp     got_error_str


fwrote_everything:
; cx has bytes written 

or        word ptr ds:[si + FILE_INFO_T.fileinto_flag], di


xchg      ax, cx ; cx had bytes copied.

exit_fwrite:
mov       sp, bp
pop       bp
pop       di
pop       si
ret      










ENDP



PROC    locallib_freadfromfar_   FAR
PUBLIC  locallib_freadfromfar_
call    locallib_fread_
retf
ENDP

SECTOR_SIZE = 512

error_overallocated:
mov     ax, OFFSET _OVERALLOCATED_STR
got_error_str:
push    cs
push    ax
jmp     I_Error_


PROC    locallib_fread_nearsegment_   NEAR
PUBLIC  locallib_fread_nearsegment_

mov       dx, ds  ; implied near.

PROC    locallib_fread_   NEAR
PUBLIC  locallib_fread_ 

push      si
push      di


xchg      ax, di  ; di gets dest
mov       es, dx  ; es stores target segment

mov       dx, bx    ; dx gets bytes to copy
mov       si, cx    ; si gets fp


cmp       word ptr ds:[si + FILE_INFO_T.fileinto_base], 0
jne       dont_allocate_buffer

; si already fp
call      locallib_ioalloc_

dont_allocate_buffer:


continue_fread_until_done:

mov       ax, dx ; get bytes_left
mov       cx, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
test      cx, cx
je        out_of_buffer

cmp       cx, ax
jbe       dont_cap_bytesleft
mov       cx, ax
dont_cap_bytesleft:

; di carries dest already.
mov       bx, si

sub       word ptr ds:[bx + FILE_INFO_T.fileinto_cnt], cx

sub       dx, cx
mov       si, word ptr ds:[si + FILE_INFO_T.fileinto_ptr]

; es already set...?

shr       cx, 1
rep       movsw
adc       cx, cx
rep       movsb

mov       word ptr ds:[bx + FILE_INFO_T.fileinto_ptr], si

mov       si, bx ;unbackup

out_of_buffer:
mov       ax, dx
test      ax, ax
je        finished_fread

test      byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _BIGBUF
je        skip_buffer
test      word ptr ds:[si + FILE_INFO_T.fileinto_flag+1], (_IONBF SHR 8)
jne       skip_buffer
cmp       ax, SECTOR_SIZE 
jb        just_fill_buffer_binary


skip_buffer_modify:


mov       ax, word ptr ds:[si + FILE_INFO_T.fileinto_base]
mov       word ptr ds:[si + FILE_INFO_T.fileinto_cnt], 0
mov       word ptr ds:[si + FILE_INFO_T.fileinto_ptr], ax

skip_buffer:
mov       cx, dx  

push      dx
mov       dx, di
mov       bx, word ptr ds:[si + FILE_INFO_T.fileinto_handle]
push      es
pop       ds ; set target segment for dos api call...

;inlined locallib_qread_

mov       ah, 03Fh  ; Read file or device using handle
int       021h
push      ss
pop       ds
pop       dx
jc        do_qread_fread_error

cmp       ax, 0FFFFh
je        bad_read_do_error
test      ax, ax
jne       exit_fread
hit_end_of_file:
or        byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _EOF
finished_fread:
exit_fread:

pop       di
pop       si
ret    


do_qread_fread_error:

bad_read_do_error:


mov     ax, OFFSET _BAD_QREAD_STR
jmp     got_error_str


just_fill_buffer_binary:
; buffer empty, so load bytes then recontinue loop and next time copy from buffer.
; todo inline
call      locallib_fill_buffer_

test      ax, ax

jne       continue_fread_until_done
jmp       exit_fread


ENDP




PROC    locallib_fopenfromfar_nobuffer_   FAR
PUBLIC  locallib_fopenfromfar_nobuffer_
call    locallib_fopen_nobuffering_
retf
ENDP


PROC    locallib_fopen_nobuffering_  NEAR
PUBLIC  locallib_fopen_nobuffering_

call    locallib_fopen_
test    ax, ax
je      dont_modify_values_bad_file  ; todo carry flag
xchg    ax, bx
or      byte ptr ds:[bx + FILE_INFO_T.fileinto_flag + 1], _IONBF SHR 8
and     byte ptr ds:[bx + FILE_INFO_T.fileinto_flag + 1], (NOT (_IOFBF OR _IOLBF)) SHR 8
xchg    ax, bx
dont_modify_values_bad_file:
ret

ENDP





; ax has flags
; si has fp
; bx has filename ptr


PERMISSION_READONLY = 1
PERMISSION_WRITABLE = 0
PMODE = 0180h ;  ?? ; (S_IREAD | S_IWRITE)






; dx = mode
; ax = filename

jump_to_exit_fopen:
jmp    exit_fopen

PROC    locallib_fopen_   NEAR
PUBLIC  locallib_fopen_


PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp


xchg ax, cx  ; cx holds onto filename



mov       di, OFFSET ___iob
loop_next_static_file:
test      byte ptr ds:[di + FILE_INFO_T.fileinto_flag], (_READ OR _WRITE)
je        create_streamlink      ; found an empty FP
add       di, SIZE FILE_INFO_T
cmp       di, (OFFSET ___iob + (MAX_FILES * SIZE FILE_INFO_T))
jb        loop_next_static_file
mov       ax, OFFSET _OUTOFFILES_STR
jmp       got_error_str



create_streamlink:

; si has streamlink ptr  todo reverse for consistency? si is usually FILE.
; ax has 0



push      ds
pop       es

; zero out the streamlink.
xor       ax, ax
stosw  ; 5 * 2 bytes = SIZE FILE_INFO_T = 0Ah
stosw
stosw  
stosw  
stosw

lea       si, [di - SIZE FILE_INFO_T]

; si has fp
xchg ax, dx  ; ax gets flags
xor  ah, ah  
; si has fp
; bx has filename ptr


cwd  ; dx = 0. ah known 0 ; equal to _O_RDONLY. default to read
mov  bx, PERMISSION_READONLY 

test al, FILEFLAG_WRITE
je   not_write_flag
dec  bx ; PERMISSION_WRITABLE = 0 
or   dl, (_O_WRONLY OR _O_CREAT)
not_write_flag:

; bx has permissions.



; flags set.

;    fp->_handle = __F_NAME(_sopen,_wsopen)( name, open_mode, shflag, p_mode );
; ?? why var args...


xchg ax, cx ; filename back in ax



; ax = filename
; dx = flags
; bx = file permissions

; todo get rid of this frame.
push      si
push      cx
push      bp
mov       bp, sp
xchg      ax, si        ; si gets filename ptr
push      dx            ; bp - 2 = flags
push      bx            ; bp - 4 is permissions
                        ; bp - 6 is temporarily filename later
mov       di, 0FFFFh    ; handle

; remove trailing spaces? todo remove? do i ever do this? maybe command line params will hit this.
loop_check_for_space:
lodsb
cmp       al, ' '
je        loop_check_for_space



found_space:
dec       si  ; roll back lodsb

mov       ax, word ptr [bp - 2]
and       ax, ( _O_RDONLY OR _O_WRONLY OR _O_RDWR OR _O_NOINHERIT ) ; 083h

push      si     ; [bp - 6] = filename.
mov       dx, si
mov       di, ax ;   si gets rwmode for later

;call      locallib_dosopen_  ; inlined

; di gets handle 

mov       ah, 03Dh  ; Open file using handle
int       021h
mov       di, 0FFFFh
jc        bad_open_dont_set_handle
xchg      ax, di   ; set file handle in di
bad_open_dont_set_handle:

sopen_handle_good:
test      byte ptr [bp - 2], (_O_WRONLY OR _O_RDWR) 
je        sopen_access_check_ok    ; readonly, access/write is ok
cmp       di, 0FFFFh               ; file does not exist, dont need to do access check, will try to create later
je        do_create_file

; open a file for writing is always delete file, not append
lea       dx, [bp - 2]            ; dummy ptr
mov       bx, di ; handle
xor       cx, cx                  ; len
mov       ah, 040h   ; Write file or device using handle
int       021h
mov       cx, ax
jc        handle_sopen_seterrno

sopen_access_check_ok:
cmp       di, 0FFFFh
jne       process_iomode_flags        ; file handle is valid so we dsont have to create it.

do_create_file:
test      byte ptr [bp - 2], _O_CREAT ; we didnt ask to create it....
je        exit_sopen_return_bad_handle
; al still has error
cmp       al, 2 ; E_NOFILE    ; i guess errno was set earlier and we check it to see we had the 'correct error' of no file exists.
jne       exit_sopen_return_bad_handle

; gotta create file..

pop       dx     ; [bp - 6], filename
pop       cx     ; [bp - 4], permissions vararg, 1 for readonly 0 for not

;call      locallib_doscreate_
; inlined


; di is handle ptr
; dx is filename
; cx is permissions

mov   ah, 03Ch  ; Create file using handle
int   021h
jb    exit_sopen_return_bad_handle
mov   di, ax   ; set file handle in di







process_iomode_flags:


; finished with flags

xchg      ax, di  ; last use of di


exit_sopen:
LEAVE_MACRO
pop       cx
pop       si




mov  word ptr ds:[si + FILE_INFO_T.fileinto_handle], ax
cmp  ax, 0FFFFh
je   bad_handle_dofree
xor  dx, dx
mov  word ptr ds:[si + FILE_INFO_T.fileinto_cnt], dx ; 0
mov  word ptr ds:[si + FILE_INFO_T.fileinto_base], dx ; 0
or   word ptr ds:[si + FILE_INFO_T.fileinto_flag], cx  ; flags

do_open_skip_fseek:

xchg  ax, si
exit_doopen:




exit_fopen:

mov   es, ax
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
mov   ax, es
ret 

exit_sopen_return_bad_handle:
mov       ax, 0FFFFh
jmp       exit_sopen


bad_handle_dofree:
xor  ax, ax
jmp  exit_doopen

handle_sopen_seterrno:
mov       bx, di
mov       ah, 03Eh   ; Close file using handle
int       021h
sbb       dx, dx
mov       ax, cx
jmp       exit_sopen

ENDP




PROC    locallib_fclosefromfar_   FAR
PUBLIC  locallib_fclosefromfar_
call    locallib_fclose_
retf
ENDP

; todo inline

PROC    locallib_close_  NEAR

push bx
push cx
push dx
push si
mov  cx, ax
mov  bx, ax
mov  ah, 03Eh  ; Close File Using Handle
int  021h
jc   close_is_error
xor  si, si ; 0/success return val

continue_close:


xchg ax, si  ; ax gets return val
pop  si
pop  dx
pop  cx
pop  bx
ret
close_is_error:
mov     ax, OFFSET _BAD_FCLOSE_STR
jmp     got_error_str


ENDP


error_underallocated:
mov     ax, OFFSET _UNDERALLOCATED_STR
jmp     got_error_str


PROC    locallib_fclose_   NEAR
PUBLIC  locallib_fclose_
ENDP
; fall thru
; todo pass in si?

; todo revisit the lseek stuff.
; todo inline


PROC    doclose_  NEAR
PUBLIC  doclose_  
push  bx
push  cx
push  dx
push  si
push  di

mov   si, ax

xor   di, di ; error code.
test  byte ptr ds:[si + FILE_INFO_T.fileinto_flag], (_READ OR _WRITE)
je    error_and_exit_doclose  ; not readable or writable? todo get rid of error check

; todo do we need this seek on close thing? is it for making sure files get saved?

mov   ax, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
test  ax, ax
je    skip_seek_on_close
neg   ax
cwd   
mov   bx, word ptr ds:[si + FILE_INFO_T.fileinto_handle]
xchg  ax, bx
mov   cx, dx
mov   dx, 1  ; SEEK_CUR
call  locallib_lseek_
skip_seek_on_close:

mov   ax, word ptr ds:[si + FILE_INFO_T.fileinto_handle]
call  locallib_close_  ; close ms-dos file
or    di, ax
skip_close_null_handle:
test  byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _BIGBUF
je    skip_bigbuf  ; todo do we get rid of this check?

mov   ax, word ptr ds:[si + FILE_INFO_T.fileinto_base]
;call  free_
dec     byte ptr cs:[_buffercount]
js      error_underallocated

mov   word ptr ds:[si + FILE_INFO_T.fileinto_base], 0
skip_bigbuf:
mov   word ptr ds:[si + FILE_INFO_T.fileinto_flag], 0  ; not open for read or write anymore.

exit_doclose:
xchg  ax, di

pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  
error_and_exit_doclose: 
dec   di  ; 0FFFFh    ; not open file?
jmp   exit_doclose

ENDP


ENDP



PROC    locallib_update_buffer_ NEAR
PUBLIC  locallib_update_buffer_

; cx:bx = diff, si = file
; return in carry



mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
cwd  
cmp  cx, dx
jl   size_check_ok
jne  outside_of_buffer
cmp  bx, ax
ja   outside_of_buffer
size_check_ok:

mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_base]
sub  ax, word ptr ds:[si + FILE_INFO_T.fileinto_ptr]
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
and  byte ptr ds:[si + FILE_INFO_T.fileinto_flag], (NOT _EOF)
add  word ptr ds:[si + FILE_INFO_T.fileinto_ptr], bx
sub  word ptr ds:[si + FILE_INFO_T.fileinto_cnt], bx
clc
jmp  return_update_buffer

ENDP


PROC    locallib_reset_buffer_ NEAR
PUBLIC  locallib_reset_buffer_

; si is file

and  byte ptr ds:[si + FILE_INFO_T.fileinto_flag], (NOT _EOF)
mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_base]
mov  word ptr ds:[si + FILE_INFO_T.fileinto_cnt], 0
mov  word ptr ds:[si + FILE_INFO_T.fileinto_ptr], ax

ret  


ENDP



SEEK_SET = 0
SEEK_CUR = 1
SEEK_END = 2





PROC    locallib_fseek_   NEAR
PUBLIC  locallib_fseek_

push si
push di
push bp
mov  bp, sp

mov  si, ax

push dx   ; bp - 2. store seek type.

test byte ptr ds:[si + FILE_INFO_T.fileinto_flag + 0], (_WRITE)
je   check_for_seek_end
cmp  dx, SEEK_CUR   
jne  dont_subtract_offset
subtract_offset:
mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
cwd  
sub  bx, ax
sbb  cx, dx
dont_subtract_offset:

mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_base]
mov  word ptr ds:[si + FILE_INFO_T.fileinto_cnt], 0
mov  word ptr ds:[si + FILE_INFO_T.fileinto_ptr], ax
file_ready_for_seek:
mov  dx, word ptr [bp - 2] ; retrieve seek type

and  byte ptr ds:[si + FILE_INFO_T.fileinto_flag], (NOT (_EOF))       ; turn off the flags.
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



check_for_seek_end:
cmp  dx, SEEK_CUR
je   handle_seek_cur
ja   reset_buffer
; no invlaid param checking.
; SEEK_SET case


call locallib_tell_
mov  di, ax    ; low bytes temporarily
mov  es, dx
mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
cwd  

sub  di, ax
xchg ax, di  ; low result in ax
mov  di, es
sbb  di, dx
push cx
push bx
sub  bx, ax
sbb  cx, di

call locallib_update_buffer_
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

call locallib_reset_buffer_
status_ok_good_lseek_result:
xor  ax, ax
jmp  exit_return_fseek
reset_buffer:
call locallib_reset_buffer_
mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_handle]
jmp  do_call_lseek




handle_seek_cur:
mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
cwd  

push dx
push ax
call locallib_update_buffer_
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


PROC    locallib_lseek_ NEAR

; si is file


xchg ax, bx  ; low size into ax
xchg ax, dx  ; size cx:dx, ax gets type

mov  bx, word ptr ds:[si + FILE_INFO_T.fileinto_handle]

; fall thru


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
jc   do_bad_inner_lseek
exit_inner_lseek:
ret

do_bad_inner_lseek:
mov     ax, OFFSET _BAD_FSEEK_STR
jmp     got_error_str

ENDP





ENDP

PROC    locallib_tell_ NEAR

; si = file handle

push bx
push cx
mov  bx, word ptr ds:[si + FILE_INFO_T.fileinto_handle]  ; si is always file handle here
mov  al, 1
xor  dx, dx
xor  cx, cx
call locallib_inner_lseek_
pop  cx
pop  bx
ret 
ENDP


ENDP

ENDP

PROC    locallib_ftell_   NEAR
PUBLIC  locallib_ftell_

; si is file

push cx
push bx
push si

mov  si, ax



call locallib_tell_
cmp  dx, 0FFFFh
jne  good_location
cmp  ax, 0FFFFh
je   exit_ftell
good_location:
cmp  word ptr ds:[si + FILE_INFO_T.fileinto_cnt], 0
je   exit_ftell
xchg ax, bx
mov  cx, dx
mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
cwd  

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


ENDP












; if base is nonzero then you have a buffer.

PROC    locallib_ioalloc_ NEAR

; si fas file already

call  malloc_  ; near malloc
; ax gets file buffer

mov   word ptr ds:[si + FILE_INFO_T.fileinto_base], ax ; ptr to the file buf...
or    byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _BIGBUF
mov   word ptr ds:[si + FILE_INFO_T.fileinto_cnt], 0
mov   word ptr ds:[si + FILE_INFO_T.fileinto_ptr], ax  ; current pointer.

ret  

ENDP







PROC    locallib_fill_buffer_   NEAR

push bx
push cx
push dx

; si has file
; todo does bx already have link?

; dont need ioalloc check. only call already did it

mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_base]
mov  word ptr ds:[si + FILE_INFO_T.fileinto_ptr], ax   ; point to start of buffer

test word ptr ds:[si + FILE_INFO_T.fileinto_flag+1], (_IONBF SHR 8)
mov  cx, 1              ; todo breakpoint this.
jne  dont_use_bufsize
mov  cx, FILE_BUFFER_SIZE
dont_use_bufsize:
mov  dx, word ptr ds:[si + FILE_INFO_T.fileinto_ptr]
mov  bx, word ptr ds:[si + FILE_INFO_T.fileinto_handle]

mov  ah, 03Fh  ; Read file or device using handle
int  021h

jc   do_qread_error

mov  word ptr ds:[si + FILE_INFO_T.fileinto_cnt], ax
test ax, ax
jg   done_with_eof_check
jne  handle_fill_buffer_error  ; negative
or   byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _EOF

done_with_eof_check:
mov  ax, word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
pop  dx
pop  cx
pop  bx
ret 


handle_fill_buffer_error:
mov  word ptr ds:[si + FILE_INFO_T.fileinto_cnt], 0
or   byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _SFERR
jmp  done_with_eof_check

do_qread_error:

mov     ax, OFFSET _BAD_QREAD_STR
jmp     got_error_str

ENDP





COMMENT @


PROC  locallib_qwrite_ NEAR

push cx
push si
push di
push bp
mov  si, ax
mov  bp, dx
mov  di, bx

mov  dx, bp
mov  cx, di
mov  bx, si
mov  ah, 040h  ; Write file or device using handle
int  021h
jc   do_qwrite_error
mov  dx, ax
cmp  ax, di
jne  get_qwrite_errno
skip_qwrite_errno:
mov  ax, dx
exit_qwrite:
pop  bp
pop  di
pop  si
pop  cx
ret
do_qwrite_error:
call locallib_set_errno_ptr_
jmp  exit_qwrite
get_qwrite_errno:
mov  word ptr ds:[_errno], 0Ch
jmp  skip_qwrite_errno


ENDP

PROC    locallib_fread_   FAR
PUBLIC  locallib_fread_


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
call      locallib_fread_translate_   ;fread(stackbuffer, copysize, 1, fp);

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

mov       dx, ds
mov       cx, word ptr [bp + 6]   ; fp


call      locallib_fwrite_   ;fwrite(stackbuffer, copysize, 1, fp);


		
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
@


COMMENT @

DOS_EOF_CHAR = 01Ah

PROC    locallib_fgetc_   NEAR
PUBLIC  locallib_fgetc_

push bx
push si
mov  si, ax
actually_get_char:
dec  word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
jl   increase_buffer
mov  bx, word ptr ds:[si + FILE_INFO_T.fileinto_ptr]
xor  ax, ax
mov  al, byte ptr ds:[bx]
inc  word ptr ds:[si + FILE_INFO_T.fileinto_ptr]

check_if_2nd_get_necessary:
cmp  al, DOS_EOF_CHAR    ; todo?
jne  exit_fgetc
mov  ax, 0FFFFh
or   byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _EOF

exit_fgetc:
pop  si
pop  bx
ret 

exit_fgetc_return_error:
mov  ax, 0FFFFh
pop  si
pop  bx
ret 
increase_buffer:

;call locallib_filbuf_
; inlined

call locallib_fill_buffer_
test ax, ax
je   return_eof
mov  bx, word ptr ds:[si + FILE_INFO_T.fileinto_ptr]
xor  ax, ax
mov  al, byte ptr ds:[bx] ; get this before incrementing file_ptr.
dec  word ptr ds:[si + FILE_INFO_T.fileinto_cnt]
inc  word ptr ds:[si + FILE_INFO_T.fileinto_ptr]
jmp  check_if_2nd_get_necessary

return_eof:
dec ax  ; since ax is 0 dec is -1 
jmp  exit_fgetc

fgetc_error_handler:
mov  word ptr ds:[_errno], 4
mov  ax, 0FFFFh
or   byte ptr ds:[si + FILE_INFO_T.fileinto_flag], _SFERR
jmp  exit_fgetc



ret
ENDP
@

PROC    F_FILE_ENDMARKER_ NEAR
PUBLIC  F_FILE_ENDMARKER_
ENDP


END