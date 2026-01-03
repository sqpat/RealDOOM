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


EXTRN __exit_:NEAR
EXTRN __GETDS:NEAR


.DATA




; not sure if word or what




COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

FILE_BUFFER_SIZE = 512



.CODE

; todo change?
MAX_FILES = 20


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


_O_RDONLY        = 00000h ;  open for read only 
_O_WRONLY        = 00001h ;  open for write only 
_O_RDWR          = 00002h ;  open for read and write 
_O_APPEND        = 00010h ;  writes done at end of file 
_O_CREAT         = 00020h ;  create new file 
_O_TRUNC         = 00040h ;  truncate existing file 
_O_TEXT          = 00100h ;  text file 
_O_BINARY        = 00200h ;  binary file 
; todo remove
_O_EXCL          = 00400h ;  exclusive open 
_O_NOINHERIT     = 00080h ;  file is not inherited by child process


DOS_EOF_CHAR = 01Ah
CARRIAGE_RETURN = 0Dh;

PROC    F_FILE_STARTMARKER_ NEAR
PUBLIC  F_FILE_STARTMARKER_
ENDP

FREAD_BUFFER_SIZE = 512


PROC    __MemAllocator NEAR
PUBLIC  __MemAllocator

push cx
push si
push di
push ds
push bp
mov  bp, sp
sub  sp, 2
mov  si, bx
mov  word ptr [bp - 2], 0
test ax, ax
jne  label_30
jmp  exit_memallocator
label_30:
mov  di, ax
add  di, 3
and  di, 0FFFEh
cmp  di, ax
jb   exit_memallocator
mov  ds, dx
mov  ax, word ptr ds:[si + 0Ah]
cmp  di, 6
jae  label_31
mov  di, 6
label_31:
cmp  di, ax
ja   exit_memallocator
mov  ds, dx
mov  cx, word ptr ds:[si + 8]
mov  bx, word ptr ds:[si + 6]
cmp  di, cx
jbe  label_32
label_36:
mov  ds, dx
mov  ax, word ptr ds:[bx]
cmp  di, ax
ja   label_33
mov  word ptr ds:[si + 8], cx
sub  ax, di
inc  word ptr ds:[si + 0Ch]
cmp  ax, 6
jb   label_34
mov  cx, bx
add  cx, di
mov  word ptr ds:[si + 6], cx
mov  si, cx
mov  word ptr ds:[si], ax
mov  word ptr ds:[bx], di
mov  di, cx
mov  si, word ptr ds:[bx + 2]
mov  word ptr ds:[di + 2], si
mov  ax, word ptr ds:[bx + 4]
mov  word ptr ds:[di + 4], ax
mov  word ptr ds:[si + 4], cx
mov  si, ax
mov  word ptr ds:[si + 2], cx
label_37:
mov  ds, dx
or   byte ptr ds:[bx], 1
add  bx, 2
mov  word ptr [bp - 2], bx
exit_memallocator:
mov  dx, word ptr [bp - 2]
exit_memallocator_return_as_is:
mov  ax, dx
mov  sp, bp
pop  bp
pop  ds
pop  di
pop  si
pop  cx
ret 
label_32:
mov  bx, word ptr ds:[si + 014h]
xor  cx, cx
jmp  label_36
label_33:
cmp  cx, ax
jae  label_35
mov  cx, ax
label_35:
mov  ax, si
mov  ds, dx
add  ax, 010h
mov  bx, word ptr ds:[bx + 4]
cmp  bx, ax
jne  label_36
mov  dx, word ptr [bp - 2]
mov  word ptr ds:[si + 0Ah], cx
jmp  exit_memallocator_return_as_is
label_34:
dec  word ptr ds:[si + 0Eh]
mov  di, word ptr ds:[bx + 2]
mov  word ptr ds:[si + 6], di
mov  si, word ptr ds:[bx + 4]
mov  word ptr ds:[di + 4], si
mov  word ptr ds:[si + 2], di
jmp  label_37


ENDP

PROC    __MemFree NEAR
PUBLIC  __MemFree



push cx
push si
push di
push ds
push bp
mov  bp, sp
sub  sp, 6
mov  cx, dx
mov  word ptr [bp - 2], bx
test ax, ax
jne  label_40
jump_to_exit_memfree:
jmp  exit_memfree
label_40:
mov  si, ax
mov  ds, dx
sub  si, 2
test byte ptr ds:[si], 1
je   jump_to_exit_memfree
mov  ax, word ptr ds:[si]
mov  bx, si
and  al, 0FEh
add  bx, ax
test byte ptr ds:[bx], 1
je   label_41
jmp  label_42
label_41:
add  ax, word ptr ds:[bx]
mov  di, word ptr [bp - 2]
mov  word ptr ds:[si], ax
cmp  bx, word ptr ds:[di + 6]
jne  label_43
mov  word ptr ds:[di + 6], si
label_43:
mov  ds, cx
mov  di, word ptr ds:[bx + 2]
mov  bx, word ptr ds:[bx + 4]
mov  word ptr ds:[di + 4], bx
mov  word ptr ds:[bx + 2], di
mov  di, word ptr [bp - 2]
dec  word ptr ds:[di + 0Eh]
label_49:
mov  ds, cx
mov  di, word ptr ds:[bx + 2]
mov  dx, di
mov  ax, word ptr ds:[si]
add  dx, word ptr ds:[di]
mov  word ptr [bp - 4], di
cmp  si, dx
jne  jump_to_label_44
mov  bx, di
add  ax, word ptr ds:[bx]
mov  word ptr ds:[bx], ax
mov  bx, word ptr [bp - 2]
cmp  dx, word ptr ds:[bx + 6]
jne  label_45
mov  word ptr ds:[bx + 6], di
label_45:
mov  si, word ptr [bp - 4]
label_59:
mov  bx, word ptr [bp - 2]
mov  ds, cx
dec  word ptr ds:[bx + 0Ch]
cmp  si, word ptr ds:[bx + 6]
jae  label_46
cmp  ax, word ptr ds:[bx + 8]
jbe  label_46
mov  word ptr ds:[bx + 8], ax
label_46:
mov  bx, word ptr [bp - 2]
mov  ds, cx
cmp  ax, word ptr ds:[bx + 0Ah]
ja   record_and_exit_memfree
exit_memfree:
mov  sp, bp
pop  bp
pop  ds
pop  di
pop  si
pop  cx
ret 
jump_to_label_44:
jmp  label_44
record_and_exit_memfree:
mov  word ptr ds:[bx + 0Ah], ax
mov  sp, bp
pop  bp
pop  ds
pop  di
pop  si
pop  cx
ret 
label_42:
mov  bx, word ptr [bp - 2]
mov  word ptr ds:[si], ax
mov  bx, word ptr ds:[bx + 6]
cmp  si, bx
jb   label_47
jmp  label_48
label_47:
cmp  si, word ptr ds:[bx + 2]
ja   label_49
mov  bx, word ptr [bp - 2]
mov  bx, word ptr ds:[bx + 014h]
cmp  si, bx
jb   label_49
label_54:
mov  bx, word ptr [bp - 2]
mov  ds, cx
mov  bx, word ptr ds:[bx + 0Eh]
mov  ax, bx
mov  di, word ptr [bp - 2]
inc  ax
xor  dx, dx
mov  word ptr [bp - 6], ax
mov  ax, word ptr ds:[di + 0Ch]
div  word ptr [bp - 6]
cmp  ax, bx
jae  label_50
mov  dx, word ptr ds:[di + 0Ch]
sub  dx, bx
shl  ax, 1
cmp  bx, dx
jae  label_52
label_58:
mov  ds, cx
mov  bx, word ptr ds:[si]
mov  ds, cx
add  bx, si
label_61:
cmp  word ptr ds:[bx], -1
jne  label_51
label_50:
mov  bx, word ptr [bp - 2]
mov  ds, cx
mov  bx, word ptr ds:[bx + 6]
cmp  si, bx
jb   label_55
label_56:
mov  ds, cx
label_60:
cmp  si, bx
jae  label_57
label_53:
jmp  label_49
label_57:
mov  bx, word ptr ds:[bx + 4]
cmp  si, bx
jb   label_53
mov  bx, word ptr ds:[bx + 4]
cmp  si, bx
jb   label_53
mov  bx, word ptr ds:[bx + 4]
jmp  label_60
label_48:
mov  bx, word ptr ds:[bx + 4]
cmp  si, bx
jb   label_53
mov  di, word ptr [bp - 2]
add  di, 010h
mov  ax, word ptr ds:[di + 2]
mov  bx, di
cmp  si, ax
jbe  label_54
jmp  label_49
label_52:
mov  ax, 0FFFFh
jmp  label_58
label_51:
test byte ptr ds:[bx], 1
je   label_53
mov  dx, word ptr ds:[bx]
and  dl, 0FEh
add  bx, dx
dec  ax
je   label_50
jmp  label_61
label_55:
mov  bx, word ptr [bp - 2]
mov  bx, word ptr ds:[bx + 014h]
jmp  label_56
label_44:
mov  di, word ptr [bp - 2]
inc  word ptr ds:[di + 0Eh]
mov  di, word ptr [bp - 4]
mov  word ptr ds:[si + 4], bx
mov  word ptr ds:[si + 2], di
mov  word ptr ds:[di + 4], si
mov  word ptr ds:[bx + 2], si
jmp  label_59

ENDP

PROC    __nmemneed_ NEAR
PUBLIC  __nmemneed_


xor  ax, ax
ret 

ENDP

PROC    locallib_linkupnewnearheap_ NEAR
PUBLIC  locallib_linkupnewnearheap_


push bx
push si
push di
mov  si, ax
mov  bx, word ptr ds:[___nheapbeg]
xor  di, di
label_64:
test bx, bx
je   label_62
cmp  si, bx
jb   label_63
mov  di, bx
mov  bx, word ptr ds:[bx + 4]
jmp  label_64
label_63:
mov  word ptr ds:[bx + 2], si
label_62:
mov  word ptr ds:[si + 2], di
mov  word ptr ds:[si + 4], bx
test di, di
je   label_65
mov  word ptr ds:[di + 4], si
label_66:
mov  word ptr ds:[si + 010h], 0
mov  word ptr ds:[si + 8], 0
mov  word ptr ds:[si + 0Ch], 0
lea  ax, [si + 010h]
mov  word ptr ds:[si + 0Eh], 0
mov  word ptr ds:[si + 012h], ax
mov  bx, word ptr ds:[si]
mov  word ptr ds:[si + 014h], ax
sub  bx, 016h
mov  word ptr ds:[si + 6], ax
mov  word ptr ds:[si + 016h], bx
add  bx, si
lea  ax, [si + 016h]
mov  word ptr ds:[bx + 016h], 0FFFFh
pop  di
pop  si
pop  bx
ret  
label_65:
mov  word ptr ds:[___nheapbeg], si
jmp  label_66


ENDP

PROC    __LastFree_ NEAR
PUBLIC  __LastFree_

push bx
mov  ax, word ptr ds:[___nheapbeg]
test ax, ax
je   label_67
mov  bx, ax
mov  bx, word ptr ds:[bx + 012h]
mov  ax, word ptr ds:[bx]
add  ax, bx
add  ax, 2
cmp  ax, word ptr ds:[__curbrk]
jne  label_68
mov  ax, word ptr ds:[bx]
label_67:
pop  bx
ret 
label_68:
xor  ax, ax
pop  bx
ret 

ENDP

PROC    locallib_adjustamount_ NEAR
PUBLIC  locallib_adjustamount_


push bx
push dx
mov  bx, ax
mov  ax, word ptr ds:[bx]
mov  dx, ax
add  dx, 3
and  dl, 0FEh  ; todo
cmp  dx, ax
jae  label_69
exit_adjustmaount_return_0:
xor  ax, ax
pop  dx
pop  bx
ret  
label_69:
call __LastFree_
cmp  ax, dx
jb   label_70
xor  dx, dx
label_72:
mov  ax, dx
add  dx, 01Eh
cmp  dx, ax
jb   exit_adjustmaount_return_0
mov  ax, 0700h  ; amblksiz
cmp  dx, ax
jae  already_larger_than_amblksiz
mov  dx, ax
and  dl, 0FEh
already_larger_than_amblksiz:
mov  word ptr ds:[bx], dx
test dx, dx
je   exit_adjustmaount_return_0
mov  ax, 1
pop  dx
pop  bx
ret  
label_70:
sub  dx, ax
jmp  label_72


ENDP

PROC    __brk_ NEAR
PUBLIC  __brk_ 

push bx
push cx
push dx
mov  dx, ax
cmp  ax, word ptr ds:[__STACKTOP]
jb   label_83
mov  bx, dx
mov  cl, 4
add  bx, 0Fh
shr  bx, cl
mov  ax, ds
test bx, bx
jne  request_not_0
mov  bx, 01000h
request_not_0:

mov  ax, ss
sub  ax, word ptr ds:[__psp]
add  bx, ax

mov  es, word ptr ds:[__psp]
mov  ah, 04Ah ; Modify Allocated Memory Block (SETBLOCK)
int  021h
jc   label_83
mov  ax, word ptr ds:[__curbrk]
mov  word ptr ds:[__curbrk], dx
exit_brk:
pop  dx
pop  cx
pop  bx
ret
label_83:
mov  ax, 0FFFFh
mov  word ptr ds:[_errno], 5
jmp  exit_brk

ENDP


PROC    __ExpandDGROUP_ NEAR
PUBLIC  __ExpandDGROUP_


push bx
push si
push di
push bp
mov  bp, sp
push ax    ; bp - 2 amount to allocate

cmp  word ptr ds:[__curbrk], -2
jne  label_73
exit_expanddgroup_return_0:
xor  ax, ax
exit_expanddgroup:
mov  sp, bp
pop  bp
pop  di
pop  si
pop  bx
ret
label_73:
lea  ax, [bp - 2]  ; 
call locallib_adjustamount_
test ax, ax
je   exit_expanddgroup
mov  bx, word ptr [bp - 2]          ; amount to allocate
add  bx, word ptr ds:[__curbrk]
cmp  bx, word ptr ds:[__curbrk]
jae  label_74
mov  bx, 0FFFEh
label_74:
mov  ax, bx
call __brk_
mov  si, ax
cmp  ax, 0FFFFh
je   exit_expanddgroup_return_0
cmp  ax, 0FFF8h
ja   exit_expanddgroup_return_0
cmp  bx, ax
jbe  exit_expanddgroup_return_0
sub  bx, ax
mov  word ptr [bp - 2], bx
lea  ax, [bx - 2]
cmp  ax, bx
ja   exit_expanddgroup_return_0
mov  bx, word ptr ds:[___nheapbeg]
mov  word ptr [bp - 2], ax
label_78:
test bx, bx
je   label_75
cmp  word ptr ds:[bx + 4], 0
jne  label_82
label_75:
test bx, bx
je   label_76
mov  ax, word ptr ds:[bx]
lea  di, [si - 2]
add  ax, bx
cmp  di, ax
jne  label_76
add  word ptr [bp - 2], 2
mov  ax, word ptr [bp - 2]
add  word ptr ds:[bx], ax
mov  ax, word ptr [bp - 2]
mov  si, ax
add  si, di
mov  word ptr ds:[di], ax
mov  word ptr ds:[si], 0FFFFh
label_81:
or   byte ptr ds:[di], 1
mov  word ptr ds:[bx + 0Ah], 0FFFFh
lea  ax, [di + 2]
inc  word ptr ds:[bx + 0Ch]
call free_  
mov  ax, 1
jmp  exit_expanddgroup
label_82:
cmp  bx, si
jbe  label_77
label_79:
mov  bx, word ptr ds:[bx + 4]
jmp  label_78
label_77:
mov  ax, word ptr ds:[bx]
add  ax, bx
add  ax, 2
cmp  ax, si
jae  label_75
jmp  label_79
label_76:
mov  ax, word ptr [bp - 2]
cmp  ax, 01Ch
jae  label_80
jmp  exit_expanddgroup_return_0
label_80:
mov  word ptr ds:[si], ax
mov  ax, si
mov  bx, si
call locallib_linkupnewnearheap_
mov  di, ax
jmp  label_81

ENDP



PROC    free_ NEAR
PUBLIC  free_


push  bx
push  dx
push  si
test  ax, ax
je    label_1
mov   si, word ptr ds:[___MiniHeapFreeRover]
test  si, si
je    label_2
cmp   si, ax
ja    label_3
mov   dx, word ptr ds:[si]
add   dx, si
cmp   ax, dx
jb    label_4
label_3:
mov   bx, si
mov   si, word ptr ds:[si + 2]
test  si, si
je    label_1
cmp   si, ax
ja    label_1
mov   dx, word ptr ds:[si]
add   dx, si
cmp   ax, dx
jb    label_4
label_1:
mov   si, word ptr ds:[bx + 4]
test  si, si
je    label_2
cmp   si, ax
ja    label_2
mov   dx, word ptr ds:[si]
add   dx, si
cmp   ax, dx
jb    label_5
label_2:
mov   si, word ptr ds:[___MiniHeapRover]
test  si, si
jne   label_6
label_12:
mov   si, word ptr ds:[___nheapbeg]
label_9:
test  si, si
je    jump_to_exit_free
cmp   si, ax
jbe   label_7
label_8:
mov   si, word ptr ds:[si + 4]
jmp   label_9
jump_to_exit_free:
jmp   exit_free
label_4:
jmp   label_5
label_6:
cmp   si, ax
ja    label_10
mov   dx, word ptr ds:[si]
add   dx, si
cmp   ax, dx
jb    label_5
label_10:
mov   bx, si
mov   si, word ptr ds:[si + 2]
test  si, si
je    label_11
cmp   si, ax
ja    label_11
mov   dx, word ptr ds:[si]
add   dx, si
cmp   ax, dx
jb    label_5
label_11:
mov   si, word ptr ds:[bx + 4]
test  si, si
je    label_12
cmp   si, ax
ja    label_12
mov   dx, word ptr ds:[si]
add   dx, si
cmp   ax, dx
jae   label_12
label_5:
mov   dx, ds
mov   bx, si
call  __MemFree
mov   word ptr ds:[___MiniHeapFreeRover], si
cmp   si, word ptr ds:[___MiniHeapRover]
jae   exit_free
mov   ax, word ptr ds:[___LargestSizeB4MiniHeapRover]
cmp   ax, word ptr ds:[si + 0Ah]
jb    label_13
exit_free:
pop   si
pop   dx
pop   bx
ret
label_7:
mov   dx, word ptr ds:[si]
add   dx, si
cmp   ax, dx
jb    label_5
jmp   label_8
label_13:
mov   ax, word ptr ds:[si + 0Ah]
mov   word ptr ds:[___LargestSizeB4MiniHeapRover], ax
jmp   exit_free

ENDP


PROC    malloc_ NEAR
PUBLIC  malloc_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   di, ax
add   ax, 3
and   al, 0FEh  ; todo
mov   word ptr [bp - 4], ax
cmp   ax, 6  ; min size 6 allocation
jb    label_14
label_22:
mov   byte ptr [bp - 2], 0
xor   dx, dx
label_20:
mov   ax, word ptr [bp - 4]
cmp   ax, word ptr ds:[___LargestSizeB4MiniHeapRover]
jbe   label_15
mov   si, word ptr ds:[___MiniHeapRover]
test  si, si
je    set_up_miniheaprover
label_24:
test  si, si
je    label_17
mov   cx, word ptr ds:[si + 0Ah]
mov   word ptr ds:[___MiniHeapRover], si
cmp   cx, di
jb    label_18
mov   dx, ds
mov   bx, si
mov   ax, di
call  __MemAllocator
mov   dx, ax
test  ax, ax
jne   label_19
label_18:
cmp   cx, word ptr ds:[___LargestSizeB4MiniHeapRover]
ja    label_23
label_28:
mov   si, word ptr ds:[si + 4]
jmp   label_24
exit_malloc_return_0:
xor   ax, ax
exit_malloc:
mov   sp, bp
pop   bp
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret
label_14:
mov   word ptr [bp - 4], 6
jmp   label_22
set_up_miniheaprover:
mov   word ptr ds:[___LargestSizeB4MiniHeapRover], si
mov   si, word ptr ds:[___nheapbeg]
jmp   label_24
label_15:
xor   ax, ax
mov   si, word ptr ds:[___nheapbeg]
mov   word ptr ds:[___LargestSizeB4MiniHeapRover], ax
jmp   label_24
label_23:
mov   word ptr ds:[___LargestSizeB4MiniHeapRover], cx
jmp   label_28
label_17:
cmp   byte ptr [bp - 2], 0
je    label_29
label_21:
mov   ax, di
call  __nmemneed_  ; todo always 0?
test  ax, ax
je    label_19
mov   byte ptr [bp - 2], 0
jmp   label_20
label_29:
mov   ax, di
call  __ExpandDGROUP_
test  ax, ax
je    label_21
mov   byte ptr [bp - 2], 1
jmp   label_20
label_19:
mov   ax, dx
jmp   exit_malloc




PROC    locallib_fwrite_ NEAR
PUBLIC  locallib_fwrite_

; dx:ax = far source, bx = num bytes, cx = fp

; bp - 2 = some sort of flag




push      si
push      di
push      bp
mov       bp, sp


mov       si, cx   ; fp

; bx has size
; dx has segment

mov       di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
cmp       word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base], 0

xchg      ax, di   ; di gets copy source

jne       skip_ioalloc_fwrite

; si already fp
call      locallib_ioalloc_

skip_ioalloc_fwrite:

mov       ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag]
and       ax, (_SFERR OR _EOF)
push      ax  ; bp - 2 restore error/eof flags upon exit.
push      dx  ; bp - 4 target segment

and       byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], (NOT (_SFERR OR _EOF))

do_binary_fwrite:
continue_fwrite_loop:

cmp       word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
jne       do_copy_from_buffer_fwrite ; stuff left in buffer, copy that out first.
; bx is bytes left
cmp       bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
jb        do_copy_from_buffer_fwrite


;call      locallib_qwrite_
; inlined

mov       ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
call      __GetIOMode_
test      al, _APPEND

je        skip_move_file_ptr_fwrite
push      bx
mov       bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
xor       dx, dx
xor       cx, cx
mov       ax, 04200h + SEEK_END ; 042h  ; Move file pointer using handle
int       021h
pop       bx
jc        do_qwrite_fwrite_error

skip_move_file_ptr_fwrite:
push      bx

mov       dx, di   ; ds:dx is pointer for writing.
mov       cx, bx   ; num bytes to write
mov       bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
mov       ds, word ptr [bp - 4]
mov       ah, 040h  ; Write file or device using handle
int       021h
push      ss
pop       ds
pop       bx

jc        do_qwrite_fwrite_error

cmp       ax, bx   ; did we write all the bytes?
jne       get_qwrite_errno_fwrite

skip_qwrite_errno_fwrite:

mov       dx, ax
cmp       ax, 0FFFFh
je        failed_qwrite_fwrite
test      ax, ax
jne       iterate_and_continue_next_fwrite_cycle_also_add_to_di
mov       word ptr ds:[_errno], 0Ch


failed_qwrite_fwrite:
or        byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR

iterate_and_continue_next_fwrite_cycle_also_add_to_di:
add       di, dx
iterate_and_continue_next_fwrite_cycle:
sub       bx, dx
je        fwrote_everything

test      byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR
je        continue_fwrite_loop

fwrote_everything:
; dx known nonzero
test      byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR
je        non_error_fwrite
xor       dx, dx
non_error_fwrite:
mov       ax, word ptr [bp - 2]
or        word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], ax


xchg      ax, dx ; dx had bytes copied.

exit_fwrite:
mov       sp, bp
pop       bp
pop       di
pop       si
ret      
; todo maybe remove?
do_qwrite_fwrite_error:
call locallib_set_errno_ptr_
jmp  exit_fwrite

get_qwrite_errno_fwrite:
mov  word ptr ds:[_errno], 0Ch
jmp  skip_qwrite_errno_fwrite

do_copy_from_buffer_fwrite:

mov       dx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
sub       dx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cmp       dx, bx
jbe       dont_cap_bytesleft_fwrite
mov       dx, bx

dont_cap_bytesleft_fwrite:

mov       ax, ds
mov       es, ax
xchg      ax, bx  ; ax holds bytes to copy.

mov       bx, si
mov       si, di

mov       di, word ptr ds:[bx + WATCOM_C_FILE.watcom_file_ptr]
mov       cx, dx

shr       cx, 1
rep       movsw
adc       cx, cx
rep       movsb

mov       word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], di
mov       di, si
mov       si, bx

xchg      ax, bx  ; bx holds bytes to copy.

or        byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_DIRTY SHR 8)
add       word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], dx
mov       ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cmp       ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
je        hit_end_of_buffer_do_flush
test      byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_IOFBF SHR 8)
je        iterate_and_continue_next_fwrite_cycle
hit_end_of_buffer_do_flush:

call      locallib_flush_
jmp       iterate_and_continue_next_fwrite_cycle



ENDP



PROC    locallib_freadfromfar_   FAR
PUBLIC  locallib_freadfromfar_
call    locallib_fread_
retf
ENDP

SECTOR_SIZE = 512



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


mov       bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
cmp       word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
jne       dont_allocate_buffer

; si already fp
call      locallib_ioalloc_

dont_allocate_buffer:

do_binary_fread:


continue_fread_until_done:

mov       ax, dx ; get bytes_left
mov       cx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
test      cx, cx
je        out_of_buffer

cmp       cx, ax
jbe       dont_cap_bytesleft
mov       cx, ax
dont_cap_bytesleft:

; di carries dest already.
mov       bx, si

sub       word ptr ds:[bx + WATCOM_C_FILE.watcom_file_cnt], cx

sub       dx, cx
mov       si, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]

; es already set...?

shr       cx, 1
rep       movsw
adc       cx, cx
rep       movsb

mov       word ptr ds:[bx + WATCOM_C_FILE.watcom_file_ptr], si

mov       si, bx ;unbackup

out_of_buffer:
mov       ax, dx
test      ax, ax
je        finished_fread


cmp       ax, SECTOR_SIZE  ;  always same? ;  word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
jb        just_fill_buffer_binary


skip_buffer_modify:

mov       bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
mov       ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base]

mov       word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
mov       word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], ax
mov       cx, dx  


push      dx
mov       dx, di
mov       bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
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
je        hit_end_of_file
exit_fread:

pop       di
pop       si
ret    


hit_end_of_file:
or        byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _EOF
pop       di
pop       si
ret    


do_qread_fread_error:
call      locallib_set_errno_ptr_
bad_read_do_error:
or        byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR

jmp       exit_fread

just_fill_buffer_binary:
; buffer empty, so load bytes then recontinue loop and next time copy from buffer.
call      locallib_fill_buffer_

test      ax, ax

jne       continue_fread_until_done

finished_fread:
mov       al, 1   ; i never actually use this return value do i?
pop       di
pop       si
ret    


ENDP


COMMENT @

; small version!

PROC    locallib_fread_nearsegment_   NEAR
PUBLIC  locallib_fread_nearsegment_

mov       dx, ds  ; implied near.

PROC    locallib_fread_   NEAR
PUBLIC  locallib_fread_ 

push      si
push      di
xchg      ax, dx  ; dx gets dest, ax gets segment..
mov       si, cx    ; si gets fp
mov       cx, bx    ; cx gets bytes to copy


mov       bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]


mov       es, ax  ; es stores target segment ; todo things crash without this es line???
mov       ds, ax  ; ds stores target segment

;inlined locallib_qread_

mov       ah, 03Fh  ; Read file or device using handle
int       021h
push      ss
pop       ds
jc        do_qread_fread_error

cmp       ax, 0FFFFh
je        bad_read_do_error
test      ax, ax
jne       exit_fread


hit_end_of_file:
or        byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _EOF

continue_fread_until_done:

mov       al, 1   ; i never actually use this return value do i?

exit_fread:

pop       di
pop       si
ret    



do_qread_fread_error:
call      locallib_set_errno_ptr_
bad_read_do_error:
or        byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR

jmp       exit_fread

ENDP

@

PROC    locallib_fopenfromfar_   FAR
PUBLIC  locallib_fopenfromfar_
call    locallib_fopen_
retf
ENDP


PROC    locallib_dosopen_  NEAR

; di is handle register
; dx has filename
; si has flags

mov   ax, si   ; si had flags
mov   ah, 03Dh  ; Open file using handle
int   021h
jc    bad_open_do_dos_error
mov   di, ax   ; set file handle in di
bad_open_do_dos_error:
call  locallib_doserror_  ; check carry flag etc
ret

ENDP

PROC   locallib_sopen_   NEAR
PUBLIC locallib_sopen_   


; ax = filename
; dx = flags
; bx = file permissions


push      bx
push      cx
push      dx
push      si
push      di
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
jne       found_space
jmp       loop_check_for_space

handle_sopen_seterrno:
mov       bx, di
mov       ah, 03Eh   ; Close file using handle
int       021h
sbb       dx, dx
mov       ax, cx
call      locallib_set_errno_dos_reterr_
jmp       exit_sopen

close_file_and_error:
mov       bx, di
mov       ah, 03Eh   ; Close file using handle
int       021h
sbb       dx, dx
mov       cx, 0Bh   ; EMFILE?

mov       word ptr ds:[_errno], cx

jmp       exit_sopen_return_bad_handle


found_space:
dec       si  ; roll back lodsb

mov       ax, word ptr [bp - 2]
and       ax, ( _O_RDONLY OR _O_WRONLY OR _O_RDWR OR _O_NOINHERIT ) ; 083h

push      si     ; [bp - 6] = filename.
xchg      ax, si ;   ax gets filename. si gets rwmode for later
xchg      ax, dx ;   dx gets filename
call      locallib_dosopen_ 
test      ax, ax
jne       sopen_handle_good
cmp       di, MAX_FILES
jae       close_file_and_error
sopen_handle_good:
test      byte ptr [bp - 2], (_O_WRONLY OR _O_RDWR) 
je        sopen_access_check_ok    ; readonly, access/write is ok
cmp       di, 0FFFFh               ; file does not exist, dont need to do access check, will try to create later
je        do_create_file
test      byte ptr [bp - 2], _O_TRUNC ; if not append then we are truncating the file
je        sopen_access_check_ok
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

cmp       word ptr ds:[_errno], 2 ; E_NOFILE    ; i guess errno was set earlier and we check it to see we had the 'correct error' of no file exists.
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
jb    bad_create_do_dos_error
mov   di, ax   ; set file handle in di
bad_create_do_dos_error:
call  locallib_doserror_  ; check carry flag etc



test      ax, ax
jne       exit_sopen_return_bad_handle

cmp       di, MAX_FILES
jnb       jump_to_close_file_and_error    ; out of files

process_iomode_flags:
mov       ax, di
call      __GetIOMode_
and       al, (NOT (_READ OR _WRITE OR _APPEND OR _BINARY))
; si has rwmode
and       si, (NOT _O_NOINHERIT)
cmp       si, _O_RDWR
jne       not_rw
or        al, (_READ OR _WRITE)
not_rw:
cmp       si, _O_RDONLY
jne       not_readonly
or        al, _READ
not_readonly:
cmp       si, _O_WRONLY
jne       not_writeonly
or        al, _WRITE
not_writeonly:
test      byte ptr [bp - 2], _O_APPEND
je        not_append
or        al, _APPEND
not_append:
or        al, _BINARY
xchg      ax, dx   ; dx get flags

; finished with flags

mov       ax, di
call      __SetIOMode_nogrow_  ; todo same as nogrow?

xchg      ax, di  ; last use of di
exit_sopen:
mov       sp, bp
pop       bp
pop       di
pop       si
pop       dx
pop       cx
pop       bx

ret       
jump_to_close_file_and_error:
jmp       close_file_and_error
exit_sopen_return_bad_handle:
mov       ax, 0FFFFh
jmp       exit_sopen



ENDP




COMMENT @

PROC locallib_something_ NEAR


push      bx
push      bp
mov       bp, sp
lea       bx, [bp + 0Ch]
mov       ax, word ptr ds:[bx]
push      ax
xor       ax, ax
push      ax
push      word ptr [bp + 0Ah]
push      word ptr [bp + 8]
add       bx, 2
call      locallib_sopen_
add       sp, 8
pop       bp
pop       bx
ret

ENDP

@

; ax has flags
; si has fp
; bx has filename ptr


PERMISSION_READONLY = 1
PERMISSION_WRITABLE = 0
PMODE = 0180h ;  ?? ; (S_IREAD | S_IWRITE)


PROC   locallib_doopen_ NEAR
PUBLIC locallib_doopen_ 
push cx
push di

; si is already fp.


xor  dx, dx ; equal to _O_RDONLY. default to read
mov  cx, PERMISSION_READONLY 

test al, FILEFLAG_WRITE
je   not_write_flag
dec  cx ; PERMISSION_READONLY 
or   dl, (_O_WRONLY OR _O_CREAT)
not_write_flag:

push cx  ; p_mode (permissions) param is 0 or P_MODE based on write flag.

mov  cl, (_O_TEXT SHR 8)
test al, FILEFLAG_BINARY
je   not_binary_flag
mov  cl, (_O_BINARY SHR 8)
not_binary_flag:
or   dh, cl

mov  cl, _O_TRUNC
test al, FILEFLAG_APPEND
je   not_append_flag
mov  cl, _O_APPEND
not_append_flag:
or   dl, cl

; flags set.

;    fp->_handle = __F_NAME(_sopen,_wsopen)( name, open_mode, shflag, p_mode );
; ?? why var args...

xchg ax, cx ; cx stores flags.

xchg ax, bx ; ax = filename
            ; dx = flags already
pop  bx     ; bx gets file permissions

call locallib_sopen_


mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle], ax
cmp  ax, 0FFFFh
je   bad_handle_dofree
xor  dx, dx
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], dx ; 0
mov  word ptr ds:[si + 0Ah], dx ; 0
or   word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], cx  ; flags

mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
mov  word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_orientation], dx ; 0
mov  word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_extflags], dx ; 0
mov  word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base], dx ; 0
test cl, _APPEND
je   do_open_skip_fseek
mov  dx, SEEK_END
mov  ax, si
xor  bx, bx
xor  cx, cx
call locallib_fseek_
do_open_skip_fseek:
call locallib_chktty_
mov  ax, si
exit_doopen:

pop  di
pop  cx
ret



bad_handle_dofree:
xchg ax, si
call freefp_
xor  ax, ax
jmp  exit_doopen

ENDP


; todo inline???
; outer frame push/pops si. so its safe to wreck here

PROC    locallib_allocfp_ NEAR

push      dx
push      di
mov       si, word ptr ds:[___ClosedStreams]
test      si, si
jne       found_file  ; recently closed ok?
mov       di, OFFSET ___iob
loop_next_static_file:
test      byte ptr ds:[di + WATCOM_C_FILE.watcom_file_flag], (_READ OR _WRITE)
je        create_streamlink
add       di, SIZE WATCOM_C_FILE
jmp       loop_next_static_file


found_file:

; di is its file
; si is streamlink
inc       word ptr ds:[si - 2] ; mark used

mov       ax, word ptr ds:[si + WATCOM_STREAM_LINK.watcom_streamlink_next]
mov       di, word ptr ds:[si + WATCOM_STREAM_LINK.watcom_streamlink_stream]
mov       word ptr ds:[___ClosedStreams], ax ; set last file in linekd list.
mov       dx, word ptr ds:[di + WATCOM_C_FILE.watcom_file_flag]

fp_allocated:

push      ds
pop       es

mov       word ptr ds:[si + WATCOM_STREAM_LINK.watcom_streamlink_stream], di

mov       ax, word ptr ds:[___OpenStreams]
mov       word ptr ds:[___OpenStreams], si
mov       word ptr ds:[si], ax

; zero out the streamlink.

stosw  ; 7 * 2 bytes = SIZE WATCOM_STREAM_LINK = 0Eh
stosw
xchg      ax, si
stosw  ;  + WATCOM_C_FILE.watcom_file_link
xchg      ax, dx
stosw  ;  + WATCOM_C_FILE.watcom_file_flag
xchg      ax, si ; retrieve 0
stosw


lea       ax, [di - SIZE WATCOM_STREAM_LINK]
do_allocfp_exit:
pop       di
pop       dx
ret

create_streamlink:
call      get_new_streamlink_
mov       si, ax
test      ax, ax
je        do_allocfp_out_of_memory_error
xor       dx, dx
jmp       fp_allocated

do_allocfp_out_of_memory_error:
mov       word ptr ds:[_errno], 5  ; ENOMEM
xor       di, di
jmp       do_allocfp_exit

ENDP


; dx = mode
; ax = filename

PROC    locallib_fopen_   NEAR
PUBLIC  locallib_fopen_


push bx
push si

xchg ax, bx  ; bx has filename ptr
call locallib_allocfp_  ; no args. returns file ptr

test ax, ax
je   exit_fopen

xchg ax, si  ; si gets fp
xchg ax, dx  ; ax gets flags
xor  ah, ah  
; si has fp
; bx has filename ptr
call locallib_doopen_   ; si has filename, bx has flags

null_fp:

exit_fopen:

pop  si
pop  bx
ret 


ENDP


PROC    locallib_fclosefromfar_   FAR
PUBLIC  locallib_fclosefromfar_
call    locallib_fclose_
retf
ENDP

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

mov  ax, cx
xor  dx, dx
call __SetIOMode_nogrow_
xchg ax, si  ; ax gets return val
pop  si
pop  dx
pop  cx
pop  bx
ret
close_is_error:
mov  word ptr ds:[_errno], 4
mov  si, 0FFFFh
jmp  continue_close


ENDP

PROC    freefp_  NEAR
PUBLIC  freefp_  

push bx
push si
mov  si, OFFSET ___OpenStreams   ; si keeps last stream link
loop_check_next_fp_for_free:
mov  bx, word ptr ds:[si + WATCOM_STREAM_LINK.watcom_streamlink_next]
test bx, bx
je   exit_freefp  ; end of list
cmp  ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_stream]
je   found_fp_to_free
mov  si, bx  ; iterate next.
jmp  loop_check_next_fp_for_free
found_fp_to_free:
mov  ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_next]
mov  word ptr ds:[si + WATCOM_STREAM_LINK.watcom_streamlink_next], ax  ; link the linked list gap
mov  ax, word ptr ds:[___ClosedStreams]
mov  word ptr ds:[___ClosedStreams], bx
mov  word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_next], ax
exit_freefp:
pop  si
pop  bx
ret

ENDP

PROC    purgefp_  NEAR
PUBLIC  purgefp_  
push bx
loop_check_next_fp_for_purge:
mov  bx, word ptr ds:[___ClosedStreams]
test bx, bx
je   exit_purge_fp
mov  ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_next]
mov  word ptr ds:[___ClosedStreams], ax
mov  ax, bx
call free_streamlink_
jmp  loop_check_next_fp_for_purge
exit_purge_fp:
pop  bx
ret 


ENDP


PROC    doclose_  NEAR
PUBLIC  doclose_  
push  bx
push  cx
push  si
push  di
push  bp

mov   si, ax
mov   bp, dx  ; handle
test  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], (_READ OR _WRITE)
je    error_and_exit_doclose
xor   di, di ; error code.
test  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_DIRTY SHR 8)
je    file_not_dirty_skip_flush
call  locallib_flush_
test  ax, ax
je    flush_no_error
mov   di, 0FFFFh
flush_no_error:
file_not_dirty_skip_flush:
mov   ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
test  ax, ax
je    skip_seek_on_close
neg   ax
cwd   
mov   bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
xchg  ax, bx
mov   cx, dx
mov   dx, 1  ; SEEK_CUR
call  locallib_lseek_
skip_seek_on_close:
test  bp, bp  ; handle
je    skip_close_null_handle
mov   ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
call  locallib_close_
or    di, ax
skip_close_null_handle:
test  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _BIGBUF
je    skip_bigbuf  ; todo do we get rid of this check?
mov   bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
mov   ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base]
call  free_

mov   word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
skip_bigbuf:
and   word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 0], _DYNAMIC
exit_doclose:
xchg  ax, di
pop   bp
pop   di
pop   si
pop   cx
pop   bx
ret  
error_and_exit_doclose:
mov   di, 0FFFFh
jmp   exit_doclose

ENDP


ENDP

PROC    locallib_fclose_   NEAR
PUBLIC  locallib_fclose_


push  bx
push  dx
mov   bx, word ptr ds:[___OpenStreams] ; todo right?
loop_check_next_stream:
test  bx, bx
je    fclose_return_failure
cmp   ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_stream]
je    found_stream_do_fclose
mov   bx, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_next]
jmp   loop_check_next_stream
found_stream_do_fclose:
mov   dx, 1
; call  locallib_shutdown_stream_   ; inlined

push  ax
call  doclose_
xchg  ax, dx
pop   ax
call  freefp_
mov   ax, dx


pop   dx
pop   bx
ret  
fclose_return_failure:
mov   ax, 0FFFFh
pop   dx
pop   bx
ret

ret
ENDP


PROC    locallib_update_buffer_ NEAR
PUBLIC  locallib_update_buffer_

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


PROC    locallib_reset_buffer_ NEAR
PUBLIC  locallib_reset_buffer_

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
call  locallib_doserror_  ; check carry flag etc
pop   bx
ret

ENDP


PROC    locallib_fsync_   NEAR

;  bx already had file handle
mov   ah, 068h  ; INT 21,68 - Flush Buffer Using Handle (DOS 3.3+)
clc   
int   021h
call  locallib_doserror_  ; check carry flag etc
ret

ENDP


; si holds fp
PROC    locallib_flush_   NEAR
PUBLIC  locallib_flush_   

push bx
push cx
push dx
push si
push di
push bp  ; bp is ret

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
call locallib_qwrite_

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
mov  word ptr ds:[_errno], 0Ch
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
mov  word ptr ds:[_errno], 9
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
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
jmp  do_call_lseek




handle_seek_cur:
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
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
call locallib_set_errno_ptr_
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


ENDP

PROC    locallib_isatty_ NEAR


push bx
push dx
; si is file
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
mov  ax, 04400h  ;  I/O Control for Devices (IOCTL):  IOCTL,0 - Get Device Information
int  021h

;- BIT 7 of register DX can be used to detect if STDIN/STDOUT is
;	  redirected to/from disk; if a call to this function has DX BIT 7
;	  set it's not redirected from/to disk; if it's clear then it is
;	  redirected to/from disk

test dl, 080h   ; if flag on then character device.
mov  ax, 0
je   exit_is_atty
inc  ax ; zero flag undone
exit_is_atty:
pop  dx
pop  bx
ret

ENDP

PROC    locallib_chktty_ NEAR

; si has file already

test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_ISTTY SHR 8)
jne  exit_chktty
continue_chktty_check:

call locallib_isatty_
je   exit_chktty
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_ISTTY SHR 8)
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], ((_IOFBF OR _IOLBF OR _IONBF) SHR 8)
jne  exit_chktty
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_IOLBF SHR 8)
exit_chktty:
ret

ENDP

PROC   locallib_doserror_ NEAR

jnc  exit_doserror_ret_0
push ax
call locallib_set_errno_ptr_
pop  ax
jmp  exit_doserror
exit_doserror_ret_0:
sub  ax, ax
exit_doserror:
ret

ENDP

SIZE_OF_STREAM_LOOKUP = 2 + SIZE WATCOM_STREAM_LINK
NUM_STATIC_STREAMS = 10

PROC    get_new_streamlink_ NEAR
PUBLIC  get_new_streamlink_

xchg    ax, bx                      ; instead of push
mov     bx, OFFSET ___streamlinks

loop_next_streamlink_check:
cmp     word ptr ds:[bx], 0
je      found_streamlink

add     bx, SIZE_OF_STREAM_LOOKUP
cmp     bx, (OFFSET ___streamlinks) + (NUM_STATIC_STREAMS * SIZE_OF_STREAM_LOOKUP)
jl      loop_next_streamlink_check

xchg    ax, bx
xor     ax, ax
ret

found_streamlink:
inc     word ptr ds:[bx]  ; mark dirty
xchg    ax, bx            ; instead of pop
inc     ax
inc     ax  ; plus two for the lookup
ret

ENDP


PROC    free_streamlink_ NEAR
PUBLIC  free_streamlink_

xchg    ax, bx
dec     word ptr ds:[bx-2] ; mark clean
xchg    ax, bx
ret

ENDP




PROC    locallib_ioalloc_ NEAR

; si fas file already
; todo revisit if bx is safely link?

push  bx
call  locallib_chktty_
mov   ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
test  ax, ax
jne   bufsize_set
mov   ax, FILE_BUFFER_SIZE  ; lets just use FILE_BUFFER_SIZE = 512 for everything for now
mov   word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize], ax  ; default buffer is 134 apparently! todo revisit
bufsize_set:
call  malloc_  ; near malloc
; ax gets file buffer
mov   bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
mov   word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base], ax ; ptr to the file buf...
test  ax, ax
jne   set_bigbuf
and   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], ((NOT (_IONBF OR _IOLBF OR _IOFBF)) SHR 8)  ; 0F8h
lea   ax, [si + WATCOM_C_FILE.watcom_file_ungotten]
or    byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], (_IONBF SHR 8)
mov   word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base], ax
mov   word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize], 1
finish_and_exit_ioalloc:
mov   ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base]
mov   word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
mov   word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], ax
pop   bx
ret  
set_bigbuf:
or    byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 0], _BIGBUF
jmp   finish_and_exit_ioalloc

ENDP




PROC    locallib_setvbuf_ NEAR

push si
push di
mov  si, ax


call locallib_chktty_

mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize], FILE_BUFFER_SIZE

mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
mov  word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base], dx
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], dx
and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 1], ((NOT (_IONBF OR _IOLBF OR _IOFBF)) SHR 8)  ; 0F8h
or   word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag + 0], bx  ; mode
test dx, dx
jne  exit_setvbuf_return_0

call locallib_ioalloc_
exit_setvbuf_return_0:
xor  ax, ax
pop  di
pop  si
ret

ENDP

PROC  locallib_qwrite_ NEAR

push cx
push si
push di
push bp
mov  si, ax
mov  bp, dx
mov  di, bx
call __GetIOMode_
test al, _APPEND
je   skip_move_file_ptr
mov  bx, si
xor  dx, dx
xor  cx, cx
mov  ax, 04200h + SEEK_END ; 042h  ; Move file pointer using handle
int  021h
jc   do_qwrite_error
skip_move_file_ptr:
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

PROC  locallib_qread_ NEAR


push cx
mov  cx, bx
mov  bx, ax
mov  ah, 03Fh  ; Read file or device using handle
int  021h
pop  cx
jc   do_qread_error
ret
do_qread_error:
call locallib_set_errno_ptr_
ret

ENDP

; only used for STDOUT? revisit...

PROC    locallib_setbuf_   NEAR
PUBLIC  locallib_setbuf_

push bx
push cx
mov  bx, _IOFBF
test dx, dx
jne  buff_not_null
mov  bx, _IONBF
buff_not_null:
call locallib_setvbuf_  ;     setvbuf( fp, buf, mode, FILE_BUFFER_SIZE );
pop  cx
pop  bx
ret


ret
ENDP


; 20 files
_io_mode:
;   stdin  stdout  stderr  stdaux         stdprn
dw _READ, _WRITE, _WRITE, _READ OR _WRITE, _WRITE
; room to grow
dw 0, 0, 0, 0, 0
dw 0, 0, 0, 0, 0
dw 0, 0, 0, 0, 0



PROC   __GetIOMode_ NEAR
PUBLIC __GetIOMode_

push  bx
cmp   ax, MAX_FILES
jb    good_handle
xor   ax, ax
pop   bx
ret
good_handle:
shl   ax, 1
xchg  ax, bx
mov   ax, word ptr cs:[bx + _io_mode]
pop   bx
ret
ENDP

PROC   __SetIOMode_nogrow_ NEAR
PUBLIC __SetIOMode_nogrow_ 

push  bx
cmp   ax, MAX_FILES
jnb   bad_handle_set
shl   ax, 1
xchg  ax, bx
mov   word ptr cs:[bx + _io_mode], dx
bad_handle_set:
pop   bx
ret  
ENDP



; lets just assume its a valid error passed in.

PROC locallib_set_errno_ptr_ NEAR

mov   word ptr ds:[_errno], ax
mov   ax, 0FFFFh

ret 

ENDP



PROC locallib_set_errno_dos_reterr_ NEAR

push  dx
mov   dx, ax
call  locallib_set_errno_ptr_
mov   ax, dx
pop   dx
ret

ENDP

PROC    locallib_fill_buffer_   NEAR

push bx
push dx

; si has file
; todo does bx already have link?

mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_link]
cmp  word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
jne  dont_ioalloc
call locallib_ioalloc_
dont_ioalloc:
mov  al, byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag+1]
test al, (_ISTTY SHR 8)
je   dont_flush
test al, ((_IOLBF OR _IONBF) SHR 8)
je   dont_flush
mov  ax, _ISTTY
call locallib_flushall_inner_
dont_flush:

and  byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], (NOT _UNGET)
mov  ax, word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base]
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr], ax




not_std_in:
test byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag+1], (_IONBF SHR 8)
mov  bx, 1
jne  dont_use_bufsize
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
dont_use_bufsize:
mov  dx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_handle]
call locallib_qread_
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], ax
test ax, ax
jg   done_with_eof_check
jne  handle_fill_buffer_error  ; negative
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _EOF

done_with_eof_check:
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
pop  dx
pop  bx
ret 


handle_fill_buffer_error:
mov  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt], 0
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR
jmp  done_with_eof_check

ENDP




PROC    locallib_fgetc_   NEAR
PUBLIC  locallib_fgetc_

push bx
push si
mov  si, ax
actually_get_char:
dec  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
jl   increase_buffer
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
xor  ax, ax
mov  al, byte ptr ds:[bx]
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]

check_if_2nd_get_necessary:
cmp  al, DOS_EOF_CHAR    ; todo?
jne  exit_fgetc
mov  ax, 0FFFFh
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _EOF

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
mov  bx, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
xor  ax, ax
mov  al, byte ptr ds:[bx] ; get this before incrementing file_ptr.
dec  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
jmp  check_if_2nd_get_necessary

return_eof:
dec ax  ; since ax is 0 dec is -1 
jmp  exit_fgetc

fgetc_error_handler:
mov  word ptr ds:[_errno], 4
mov  ax, 0FFFFh
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag], _SFERR
jmp  exit_fgetc



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

cmp  word ptr ds:[bx + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
jne  have_buffer_location

call locallib_ioalloc_

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

call locallib_flush_
test ax, ax
jne  exit_fputc_return_error

record_written_char:
xchg ax, cx
xor  ah, ah


exit_fputc:
pop  di
pop  si
pop  cx
pop  bx
ret

handle_newline_crap:
or   dh, (_IOLBF SHR 8)

; note we never call putc on on nonstdout so its always necessary...
; really do newline shenanigans.
mov  di, word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
or   byte ptr ds:[si + WATCOM_C_FILE.watcom_file_flag+1], (_DIRTY SHR 8)
mov  byte ptr ds:[di], CARRIAGE_RETURN
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_ptr]
inc  word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
mov  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_cnt]
cmp  ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_bufsize]
jne  prepare_to_put_char


call locallib_flush_
test ax, ax
je   prepare_to_put_char
exit_fputc_return_error:
mov  ax, 0FFFFh
jmp  exit_fputc


ret
ENDP




COMMENT @
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
PROC    F_FILE_ENDMARKER_ NEAR
PUBLIC  F_FILE_ENDMARKER_
ENDP


END