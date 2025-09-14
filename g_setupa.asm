

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


EXTRN locallib_toupper_:NEAR

.DATA


COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE


PROC    G_SETUP_STARTMARKER_ NEAR
PUBLIC  G_SETUP_STARTMARKER_
ENDP




PROC    R_CheckTextureNumForName_ NEAR
PUBLIC  R_CheckTextureNumForName_

mov     word ptr cs:[SELFMODIFY_set_arg_pointer+1], ax

PUSHA_NO_AX_OR_BP_MACRO
push     bp
mov      bp, sp
sub      sp, 8


mov     cx, word ptr ds:[_numtextures]


xor     si, si ; loop counter


loop_next_tex:
mov     ax, TEXTUREDEFS_OFFSET_6000_SEGMENT
mov     ds, ax

lodsw   
mov     di, sp
mov     bx, sp
push    si ; store this

xchg    ax, si

mov     ax, TEXTUREDEFS_BYTES_6000_SEGMENT
mov     ds, ax
push    ss
pop     es

movsw
movsw
movsw
movsw  ; name copy

push    ss
pop     ds


SELFMODIFY_set_arg_pointer:
mov     si, 01000h

; inline

;int16_t __near locallib_strncasecmp(char __near *str1, char __near *str2, int16_t n){

;ds:bx and ds:si already pass this in.
mov   dx, 8

; ds:si vs ds:bx.
; n = dx 

loop_next_char_strncasecmp:
lodsb
call   locallib_toupper_
mov    ah, al
xchg   bx, si
lodsb
xchg   bx, si
call   locallib_toupper_

; ah is a
; al is b

sub    al, ah
jne    done_with_strncasecmp

test   ah, ah
mov    al, 0    ; in case we branch, we must return 0...
je     done_with_strncasecmp

dec    dx
jnz    loop_next_char_strncasecmp

done_with_strncasecmp:

pop     si
test    al, al
je      found_tex ; zero flag still carried thru

loop    loop_next_tex

mov     si, 0FFFFh
jmp     didnt_find_tex

found_tex:
shr     si, 1
didnt_find_tex:
mov     es, si

LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
mov     ax, es

ret
ENDP



 

PROC    G_SETUP_ENDMARKER_ NEAR
PUBLIC  G_SETUP_ENDMARKER_
ENDP


END
