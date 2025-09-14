

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


; todo support cs string?

PROC    R_CheckTextureNumForName_ NEAR
PUBLIC  R_CheckTextureNumForName_

mov     word ptr cs:[SELFMODIFY_set_arg_pointer+1], ax

PUSHA_NO_AX_OR_BP_MACRO


mov     cx, word ptr ds:[_numtextures] 


xor     si, si ; loop counter
mov     dx, si ; zero dh.
mov     ax, TEXTUREDEFS_OFFSET_6000_SEGMENT
mov     ds, ax
mov     ax, TEXTUREDEFS_BYTES_6000_SEGMENT
mov     es, ax

loop_next_tex:
lodsw   

xchg    ax, bx  ; bx gets es:bx ptr


SELFMODIFY_set_arg_pointer:
mov     di, 01000h			; di gets arg param ptr

; inline strncasecmp


mov   dl, 8   ; 8 chars

; ss:di vs es:bx.
; n = dx 

loop_next_char_strncasecmp:
mov    al, byte ptr ss:[di]
inc    di
call   locallib_toupper_
mov    ah, byte ptr es:[bx]
inc    bx
;call   locallib_toupper_  ; these are always caps already right

; ah is b
; al is a

sub    al, ah
jne    done_with_strncasecmp

test   ah, ah
; mov    al, 0    ; in case we branch, we must return 0... but al is known zero
je     done_with_strncasecmp

dec    dx
jnz    loop_next_char_strncasecmp
; fall thru, found tex. but zero flag is set so it will work out?
done_with_strncasecmp:

;test    al, al
je      found_tex ; zero flag still carried thru

tex_not_found:
loop    loop_next_tex

mov     si, 0FFFFh
jmp     didnt_find_tex

found_tex:
shr     si, 1
didnt_find_tex:
mov     es, si

push    ss
pop     ds

POPA_NO_AX_OR_BP_MACRO
mov     ax, es

ret
ENDP



 

PROC    G_SETUP_ENDMARKER_ NEAR
PUBLIC  G_SETUP_ENDMARKER_
ENDP


END
