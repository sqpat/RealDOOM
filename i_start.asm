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




EXTRN hackDS_:NEAR
EXTRN D_DoomMain_:NEAR

EXTRN __GETDS:NEAR
EXTRN doclose_:NEAR
EXTRN freefp_:NEAR
EXTRN malloc_:NEAR
EXTRN free_:NEAR
EXTRN purgefp_:NEAR
EXTRN get_new_streamlink_:NEAR








; static c file struct array











COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

FILE_BUFFER_SIZE = 512

STACK_SIZE = 0A00h


DGROUP group _NULL,_DATA,DATA,_BSS,STACK



_NULL   segment para public 'BEGDATA'
        __nullarea label word
        dw      16 dup(00101h)
        public  __nullarea
_NULL   ends


_DATA   segment word public 'DATA'
_DATA   ends

DATA    segment word public 'DATA'
DATA    ends

_BSS    segment word public 'BSS'
        _edata label byte  ; end of DATA (start of BSS)
        db 0, 0
        _end   label byte  ; byte  ; end of BSS (start of STACK)
                     

_BSS    ends

STACK   segment para stack 'STACK'
        db      (STACK_SIZE) dup(?)
STACK   ends

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



PROC    I_START_STARTMARKER_ NEAR
PUBLIC  I_START_STARTMARKER_
ENDP

NUM_STD_STREAMS = 5
STD_IN_STREAM_INDEX  = 0
STD_OUT_STREAM_INDEX = 1
STD_ERR_STREAM_INDEX = 2
STD_AUX_STREAM_INDEX = 3
STD_PRN_STREAM_INDEX = 4

SIZE_STD_STREAMS = NUM_STD_STREAMS * (SIZE WATCOM_C_FILE)



PROC   docloseall_ NEAR
PUBLIC docloseall_

push bx
push cx
push dx
push si
push di
push bp
mov  bp, sp
sub  sp, 2
shl  ax, 1
mov  cl, 3
mov  dx, ax
shl  ax, cl
mov  bx, word ptr ds:[___OpenStreams]
sub  ax, dx
mov  dx, OFFSET ___iob
xor  si, si
add  dx, ax
xor  cx, cx
mov  word ptr [bp - 2], dx
label_134:
test bx, bx
je   label_130
mov  di, word ptr ds:[bx + WATCOM_C_FILE.watcom_file_ptr]
mov  bx, word ptr ds:[bx + WATCOM_C_FILE.watcom_file_cnt]
mov  al, byte ptr ds:[bx + WATCOM_C_FILE.watcom_file_flag + 1]
mov  dx, 1
test al, (_DYNAMIC SHR 8)
je   label_131
label_132:
mov  ax, bx



call  doclose_
xchg  ax, dx
mov   ax, bx
call  freefp_
mov   ax, dx


inc  cx
or   si, ax
label_133:
mov  bx, di
jmp  label_134
label_131:
test al, 8
jne  label_132
cmp  bx, word ptr [bp - 2]
jb   label_133
cmp  bx, (OFFSET ___iob + SIZE_STD_STREAMS)
jae  label_132
xor  dx, dx
jmp  label_132
label_130:
test si, si
je   label_135
mov  bx, 0FFFFh
label_136:
mov  ax, bx
mov  sp, bp
pop  bp
pop  di
pop  si
pop  dx
pop  cx
pop  bx
ret  
label_135:
mov  bx, cx
jmp  label_136

ENDP




PROC    fcloseall_ NEAR
PUBLIC  fcloseall_

   mov       ax, NUM_STD_STREAMS
   call      docloseall_
   ret

ENDP

PROC    __full_io_exit_ NEAR
PUBLIC  __full_io_exit_ 

   xor       ax, ax
   call      docloseall_
   jmp       purgefp_

ENDP



;int historical, CHAR_TYPE *p, CHAR_TYPE **argv, CHAR_TYPE **endptr )

PROC    splitparms_ NEAR
PUBLIC  splitparms_

; ax = unused
; dx gets return endptr. 
; bp - 2 = cx (endptr)
; bp = 4 = start


push      si
push      di


; ax parm unused

mov       si, dx

mov       dx, bx
xor       cx, cx
label_101:
mov       al, byte ptr ds:[si]
cmp       al, ' '  ; space 020h
jne       label_100
label_102:
inc       si
jmp       label_101
label_100:
cmp       al, 9
je        label_102
test      al, al
je        jump_to_label_103
xor       al, al
cmp       byte ptr ds:[si], 022h ; double-quoute "
je        label_104
label_109:
mov       es, si   ; store start in es
mov       bx, si
label_108:
cmp       byte ptr ds:[si], 022h ; double-quoute "
jne       label_105

inc       si
test      al, al
jne       label_107
mov       al, 2
jmp       label_108
label_104:
mov       al, 1
inc       si
jmp       label_109
label_107:
xor       al, al
jmp       label_108
label_120:
test      dx, dx
je        label_110
mov       di, cx
shl       di, 1
add       di, dx
mov       ax, es  ; retrieve start
mov       word ptr ds:[di], ax
mov       al, byte ptr ds:[si]
inc       cx
test      al, al
je        label_118
inc       si
mov       byte ptr ds:[bx], 0
jmp       label_101
jump_to_label_103:
jmp       label_103
label_105:
cmp       byte ptr ds:[si], ' '  ; space 020h
jne       label_119
label_114:
test      al, al
je        label_120
label_115:
cmp       byte ptr ds:[si], 0
je        label_120
cmp       byte ptr ds:[si], 05Ch; backslash '\' 
jne       label_113

cmp       byte ptr ds:[si + 1], 022h ; double-quoute "
jne       label_113
inc       si
cmp       byte ptr ds:[si - 2], 05Ch; backslash '\' 
je        label_108
label_113:
test      dx, dx
jne       label_122
label_123:
inc       si
jmp       label_108
label_119:
cmp       byte ptr ds:[si], 9
je        label_114
jmp       label_115

label_117:
inc       si
jmp       label_113
label_110:
jmp       label_111
label_118:
jmp       label_112
label_116:
cmp       byte ptr ds:[si + 1], 05Ch; backslash '\' 
jne       label_113
cmp       al, 1
je        label_117
jmp       label_113
label_122:
mov       ah, byte ptr ds:[si]
mov       byte ptr ds:[bx], ah
inc       bx
jmp       label_123
label_112:
mov       byte ptr ds:[bx], al

label_103:

xchg      ax, cx
mov       dx, si  ; this return endptr value goes in dx

pop       di
pop       si
ret       
label_111:
inc       cx
cmp       byte ptr ds:[si], 0
je        label_103
jmp       label_102

ENDP



__LpCmdLine:
dw 0, 0
__LpPgmName:
dw 0, 0

; creates a list of pointers to words/params

PROC   __Init_Argv_ NEAR
PUBLIC __Init_Argv_ 

mov       si, word ptr cs:[__LpCmdLine]

mov       dx, si
xor       bx, bx
call      splitparms_

;  dx has endptr already

; todo clean this up...
inc       ax
sub       dx, si
shl       ax, 1
mov       cx, dx
add       dx, 2
add       ax, 2
and       dl, 0FEh ; make it even?
add       ax, dx
xor       di, di
inc       ax
inc       cx
and       al, 0FEh ; max size of command line
mov       bx, dx

; todo check size
mov       ax, OFFSET ___commandline_copy


xchg      ax, dx
xor       ax, ax
test      dx, dx
je        done_parsing_argv

mov       di, dx

push      ds
pop       es
shr       cx, 1
rep       movsw
adc       cx, cx
rep       movsb
mov       di, dx
mov       ax, word ptr cs:[__LpPgmName]
add       di, bx
mov       bx, di
stosw
xchg      bx, di

;xor      ax, ax
call      splitparms_
inc       ax
mov       bx, ax
shl       bx, 1

mov       word ptr ds:[bx + di], 0

done_parsing_argv:
mov       word ptr ds:[__argc], ax
mov       word ptr ds:[___argc], ax
mov       word ptr ds:[____Argc], ax
mov       word ptr ds:[__argv], di

mov       word ptr ds:[___argv], di
mov       word ptr ds:[____Argv], di
ret      

ENDP





ENDP

PROC   __InitFiles_ NEAR
PUBLIC __InitFiles_ 


push      bx
push      dx
push      si
push      di
and       byte ptr ds:[___iob + (STD_ERR_STREAM_INDEX * (SIZE WATCOM_C_FILE) + WATCOM_C_FILE.watcom_file_flag + 1)], (NOT _TMPFIL) SHR 8 ; 0F8h
mov       si, OFFSET ___iob
or        byte ptr ds:[___iob + (STD_ERR_STREAM_INDEX * (SIZE WATCOM_C_FILE) + WATCOM_C_FILE.watcom_file_flag + 1)], 4

check_next_file_for_init:
mov       ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag]
test      ax, ax
je        exit_initfiles
stdin_has_flags:
call      get_new_streamlink_
test      ax, ax
je        malloc_streamlink_failed
mov       di, ax

mov       ax, word ptr ds:[___OpenStreams]
mov       word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_stream], si
mov       word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_next], ax
mov       word ptr ds:[si + WATCOM_C_FILE.watcom_file_link], di
mov       word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_base], 0
mov       word ptr ds:[___OpenStreams], di
add       si, SIZE WATCOM_C_FILE
mov       word ptr ds:[di + WATCOM_STREAM_LINK.watcom_streamlink_orientation], 0
jmp       check_next_file_for_init

exit_initfiles:
mov       word ptr ds:[___ClosedStreams], ax
pop       di
pop       si
pop       dx
pop       bx
ret


malloc_streamlink_failed:

mov       bx, 1
; __fatal_runtime_error( "Not enough memory to allocate file structures", 1 );
mov       ax, 01002h  ; todo put some string here? or ignore the error
mov       dx, ds
jmp       __fatal_runtime_error_


ENDP

; todo rename

PROC    exit_   NEAR
PUBLIC  exit_


mov   bx, ax
mov   dx, 0FFh
mov   ax, 010h
call  __FiniRtns

mov   ax, bx
jmp   __exit_


ENDP


PROC    __FiniRtns NEAR
PUBLIC  __FiniRtns

push  ds
call  __GETDS

call  __full_io_exit_


pop   ds
ret  

ENDP

_NO_MEMORY_STR:
db "!!", 020h, "Not Enough Memory", 0

_NULL_AREA_STR:
db "!!", 020h, "NULL area write detected"

_NEWLINE_STR:
db 0Dh, 0Ah , 0

_CON_STR:
db "con", 0

PROC    __exit_ NEAR
PUBLIC  __exit_

push       ax
mov        dx, DGROUP  ; worst case call getds
mov        ds, dx
cld        
xor        di, di   ; di = null area
mov        es, dx
mov        cx, 010h
mov        ax, 0101h
repe       scasw
je         null_check_ok


pop        bx
mov        ax, OFFSET _NULL_AREA_STR

mov        dx, cs

__do_exit_with_msg_:
__exit_with_msg_:
PUBLIC __do_exit_with_msg_
PUBLIC __exit_with_msg_
;mov        sp, offset DGROUP:_end+80h
push       bx
push       ax
push       dx
mov        di, cs
mov        ds, di
mov        dx, OFFSET _CON_STR
mov        ax, 03D01h        ; get console file handle into bx
int        021h
mov        bx, ax
pop        ds
pop        dx
mov        si, dx
cld        
loop_find_end_of_string:
lodsb      
test       al, al
jne        loop_find_end_of_string
mov        cx, si
sub        cx, dx
dec        cx
mov        ah, 040h  ; Write file or device using handle
int        021h
mov        ds, di   ; cs
mov        dx, OFFSET _NEWLINE_STR
mov        cx, 2
mov        ah, 040h  ; Write file or device using handle
int        021h

null_check_ok:
mov        dx, 0Fh   ; FINI_PRIORITY_EXIT-1
call       __FiniRtns
pop        ax
mov        ah, 04Ch  ; Terminate process with return code
int        021h

ENDP

__fatal_runtime_error_:
PUBLIC __fatal_runtime_error_
mov  ax, ax
mov  cx, ax
jmp  __do_exit_with_msg_

ENDP



PROC   _exit_ NEAR
PUBLIC _exit_

mov   dx, ax
mov   ax, dx
jmp   __exit_

ENDP

PROC   __null_ovl_rtn FAR
PUBLIC __null_ovl_rtn
ENDP
PROC   __null_FPE_rtn FAR
PUBLIC __null_FPE_rtn
ENDP
PROC   __null_int23_exit_ FAR
PUBLIC __null_int23_exit_
retf
ENDP


ENDP


; PSP offsets
MEMTOP    = 2
CMDLDATA  = 81h


PROC   _realdoomstart_ NEAR
PUBLIC _realdoomstart_


sti        
mov        cx, DGROUP
mov        es, cx
mov        bx, offset DGROUP:_end 
add        bx, 00Fh
and        bl, 0F0h ; round up a segment
mov        word ptr es:[__STACKLOW], bx
mov        word ptr es:[__psp], ds
add        bx, sp
add        bx, 00Fh
and        bl, 0F0h  ; round up a segment
mov        ss, cx
mov        sp, bx
mov        word ptr es:[__STACKTOP], bx

mov        dx, bx
shr        dx, 1 ; seg count
shr        dx, 1
shr        dx, 1
shr        dx, 1

; set up heap

mov        cx, ds:[MEMTOP] ; 2   ; 0A000h
mov        ax, es                
sub        cx, ax                ; ; 85EA
cmp        dx, cx                ; (f7d)
jb         enuf_mem
mov        bx, 1
mov        ax, OFFSET _NO_MEMORY_STR
mov        dx, cs
jmp        __fatal_runtime_error_

enuf_mem:
mov        ax, es               
mov        bx, dx
shl        bx, 1
shl        bx, 1
shl        bx, 1
shl        bx, 1            ; ; F7D0
jne        not64k
mov        bx, 0FFFEh
not64k:
mov        word ptr es:[__curbrk],bx  ; 2120
mov        bx, dx
add        bx, ax       ; 2993
mov        ax, word ptr es:[__psp]
mov        es, ax
sub        bx, ax
mov        ah, 4Ah      ;  Modify allocated memory blocks
int        21h


mov        di, ds
mov        es, di  ; es gets PSP
mov        di, CMDLDATA
mov        cl, byte ptr ds:[di - 1]
xor        ch, ch
cld        
mov        al, ' ' ; 020h
repe       scasb
lea        si, [di - 1]
mov        dx, DGROUP
mov        es, dx
mov        di, word ptr es:[__STACKLOW]
mov        word ptr cs:[__LpCmdLine+0], di
mov        word ptr cs:[__LpCmdLine+2], es
je         noparameters
inc        cx
rep        movsb
noparameters:

xor        ax, ax ; null terminate parameters
stosw
dec        di

mov        cx, di

done_with_program_name:
mov        ds, dx
mov        word ptr cs:[__LpPgmName+0], cx
mov        word ptr cs:[__LpPgmName+2], es
mov        bx, sp
mov        ax, bp
mov        word ptr ds:[__STACKLOW], di
mov        cx, offset DGROUP:_end
mov        di, offset DGROUP:_edata
sub        cx, di
xor        al, al
rep        stosb  ; zero  BSS segment
xor        bp, bp
push       bp
mov        bp, sp
mov        ax, 0FFh
;call       __InitRtns
call  __GETDS
call  __InitFiles_
call  __Init_Argv_

;jmp        __CMain

ENDP

PROC    __CMain NEAR
PUBLIC  __CMain


push bp
mov  bp, sp

main_:
PUBLIC main_
call  hackDS_


mov  ax, word ptr ds:[____Argc]

mov   word ptr ds:[_myargc], ax
mov   ax, word ptr ds:[____Argv]

; main functions
mov   word ptr ds:[_myargv+0], ax
mov   word ptr ds:[_myargv+2], ds

call  D_DoomMain_

ENDP


_big_code_:
PUBLIC _big_code_
CodeModelMismatch:
PUBLIC CodeModelMismatch
__DOSseg__:
PUBLIC __DOSseg__
ret


PROC    I_END_STARTMARKER_ NEAR
PUBLIC  I_END_STARTMARKER_
ENDP

END
