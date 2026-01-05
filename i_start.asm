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





EXTRN D_DoomMain_:NEAR

EXTRN doclose_:NEAR
EXTRN freefp_:NEAR
EXTRN malloc_:NEAR
EXTRN free_:NEAR

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

; todo get rid of this once file buffers out of heap.

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




;int historical, CHAR_TYPE *p, CHAR_TYPE **argv, CHAR_TYPE **endptr )




ret

PROC    __GETDS   NEAR
PUBLIC  __GETDS

push      ax
mov       ax, DGROUP
mov       ds, ax
pop       ax
ret       

ENDP


PROC hackDS_ NEAR
PUBLIC hackDS_

;todo: make cli held for less time

cli
push cx
push si
push di

mov ds:[_stored_ds], ds
xor di, di
mov si, di
mov cx, FIXED_DS_SEGMENT

;mov cx, ds
;add cx, 400h
mov es, cx

mov CX, 2000h    ; 4000h bytes
rep movsw

mov cx, es
mov ds, cx
mov ss, cx

mov word ptr cs:[__GETDS+2], cx

;extern uint16_t __near* _GETDS;
;	((uint16_t __near*)(&_GETDS))[1] = FIXED_DS_SEGMENT;


pop di
pop si
pop cx
sti
ret

ENDP


; creates a list of pointers to words/params (argv), unescaped

PROC   __Init_Argv_ NEAR
PUBLIC __Init_Argv_ 

push      ds
pop       es
mov       di, OFFSET _myargv

; todo selfmodify?
SELFMODIFY_set_program_name_ptr:
mov       ax, 01000h  
stosw
; di is argv[1] now

SELFMODIFY_set_command_line_ptr:
mov       si, 01000h


; inlined  splitparams


; unescapes cmd line and creates argv array
; si has current command line ptr
; di has argv ptr


mov       cx, 1  ; argc plus one for pgm name

check_next_character_in_param_name:
lodsb     
cmp       al, ' '  ; space 020h
je        found_space_delimiter_in_param_name

cmp       al, 9   ; tab
je        found_space_delimiter_in_param_name
test      al, al
je        found_end_of_params
xor       ah, ah  ; ah 0 (quote state none)
dec       si
cmp       al, 022h ; double-quoute "
jne       first_letter_not_quote
mov       ah, 1 ; quote is open
inc       si
first_letter_not_quote:

; new word. store start offsets..

mov       dx, si   ; store start of word in dx
mov       bx, si   ; store start of word in bx for unescaping as we write
get_next_word_character:
lodsb
cmp       al, 022h ; double-quoute "
jne       this_character_not_quote


test      ah, ah
mov       ah, 0
jne       get_next_word_character
mov       ah, 2
jmp       get_next_word_character

found_end_of_word:



; 2nd call, we store argv values.


inc       cx
xchg      ax, dx
stosw                   ; write start (argv ptr)
xchg      ax, dx        ; restore ah

mov       byte ptr ds:[bx], 0   ; null terminate escaped word string
test      al, al
je        found_end_of_params

found_space_delimiter_in_param_name:

jmp       check_next_character_in_param_name

this_character_not_quote:
cmp       al, ' '  ; space 020h
je        this_character_is_space_delimiter
cmp       al, 9    ; tab
jne       this_character_not_space
this_character_is_space_delimiter:
test      ah, ah
je        found_end_of_word

this_character_not_space:
cmp       al, 0
je        found_end_of_word

cmp       al, 05Ch; backslash '\' 
jne       this_character_not_special
; si already incremented.
cmp       byte ptr ds:[si], 022h ; double-quoute "
jne       this_character_not_special

cmp       byte ptr ds:[si - 3], 05Ch; backslash '\' 
je        get_next_word_character

this_character_not_special:

mov       byte ptr ds:[bx], al   ; write character having removed quotes etc.
inc       bx
jmp       get_next_word_character


found_end_of_params:

xor       ax, ax
stosw     ; null term argv
mov       word ptr ds:[_myargc], cx ;

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
or        byte ptr ds:[___iob + (STD_ERR_STREAM_INDEX * (SIZE WATCOM_C_FILE) + WATCOM_C_FILE.watcom_file_flag + 1)], (_IONBF SHR 8)

check_next_file_for_init:
mov       ax, word ptr ds:[si + WATCOM_C_FILE.watcom_file_flag]
test      ax, ax
je        exit_initfiles
stdin_has_flags:
call      get_new_streamlink_
; i dont think we can run out of 10 streamlinks??
; test      ax, ax
; je        malloc_streamlink_failed
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




ENDP



ENDP



_NO_MEMORY_STR:
db "!!", 020h, "Not Enough Memory", 0

_NULL_AREA_STR:
db "!!", 020h, "NULL area write detected"

_NEWLINE_STR:
db 0Dh, 0Ah , 0

_CON_STR:
db "con", 0



PROC    __FiniRtns NEAR
PUBLIC  __FiniRtns

push      ds
call      __GETDS
xor       ax, ax
call      docloseall_
pop       ds
ret  

ENDP

; todo clean up triple exit function stuff..

PROC    exit_   NEAR
PUBLIC  exit_


push  ax                        ; al = return code.
call  __FiniRtns

; fall thru


mov        dx, DGROUP  ; worst case call getds
mov        ds, dx
cld        
xor        di, di   ; di = null area
mov        es, dx
mov        cx, 010h
mov        ax, 0101h
repe       scasw
jne        null_check_fail

null_check_ok:

call       __FiniRtns
pop        ax
mov        ah, 04Ch  ; Terminate process with return code
int        021h


null_check_fail:
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


ENDP



; PSP offsets
MEMTOP    = 2
CMDLDATA  = 81h

; PROGRAM ENTRY POINT FROM MS-DOS!!!

PROC   _realdoomstart_ NEAR
PUBLIC _realdoomstart_


sti        
mov        cx, DGROUP
mov        es, cx
mov        bx, offset DGROUP:_end 
add        bx, 00Fh
and        bl, 0F0h ; round up a segment
mov        word ptr es:[__STACKLOW], bx
;mov        word ptr es:[__psp], ds
add        bx, sp
add        bx, 00Fh
and        bl, 0F0h  ; round up a segment
mov        ss, cx
mov        sp, bx
;mov        word ptr es:[__STACKTOP], bx



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
mov        word ptr cs:[SELFMODIFY_set_command_line_ptr+1], di

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
mov        word ptr cs:[SELFMODIFY_set_program_name_ptr+1], cx

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
call  hackDS_
jmp   D_DoomMain_


ENDP


_big_code_:
PUBLIC _big_code_
ret


PROC    I_START_ENDMARKER_ NEAR
PUBLIC  I_START_ENDMARKER_
ENDP

END
