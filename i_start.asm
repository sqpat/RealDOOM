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

STACK_SIZE = 0600h


DGROUP group _NULL,STACK



_NULL   segment para public 'BEGDATA'
        __nullarea label word
        dw      8 dup(00101h)
        public  __nullarea
_NULL   ends




STACK   segment para stack 'STACK'
        _stackstart     label byte  ; byte  (start of STACK)
        db      (STACK_SIZE) dup(?)
STACK   ends

.CODE
EXTRN _gamekeydown:BYTE
EXTRN BASE_CHEAT_ADDRESS



PROC    I_START_STARTMARKER_ NEAR
PUBLIC  I_START_STARTMARKER_
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
mov        bx, offset DGROUP:_stackstart 
;add        bx, 00Fh
;and        bl, 0F0h ; round up a segment
mov        word ptr es:[__STACKLOW], bx
;mov        word ptr es:[__psp], ds
add        bx, sp
add        bx, 00Fh
and        bl, 0F0h  ; round up a segment
mov        ss, cx
mov        sp, bx
mov        word ptr es:[__STACKTOP], bx



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
mov        word ptr ds:[_ORIGINAL_CS_SEGMENT_PTR], cs
mov        word ptr ds:[_BASE_CHEAT_ADDRESS_OFFSET_PTR], OFFSET BASE_CHEAT_ADDRESS
mov        word ptr ds:[_gamekeydownpointer], OFFSET _gamekeydown
push       bp
mov        bp, sp


; init argv
; creates a list of pointers to words/params (argv), unescaped


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




;call  hackDS_

; inlined hackDS_


cli

xor di, di
mov si, di
mov cx, FIXED_DS_SEGMENT

mov es, cx

mov cx, 1000h    ; 2000h bytes
rep movsw

mov cx, es
mov ds, cx
mov ss, cx


;extern uint16_t __near* _GETDS;
;	((uint16_t __near*)(&_GETDS))[1] = FIXED_DS_SEGMENT;


sti

jmp   D_DoomMain_


ENDP




PROC    I_START_ENDMARKER_ NEAR
PUBLIC  I_START_ENDMARKER_
ENDP

END
