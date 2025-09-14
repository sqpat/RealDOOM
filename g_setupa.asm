

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
EXTRN I_Error_:FAR

.DATA


COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE


PROC    G_SETUP_STARTMARKER_ NEAR
PUBLIC  G_SETUP_STARTMARKER_
ENDP

str_texturenum_error:
db 0Ah, "R_TextureNumForName: %s not found", 0


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
jne    tex_not_found ; chars different.

test   ah, ah
je     found_tex  ; both were zero, or null terminated.

dec    dx
jnz    loop_next_char_strncasecmp
; fall thru, found tex.
done_with_strncasecmp:

found_tex:
shr     si, 1
didnt_find_tex:
dec     si ; si overshot by 1 due to lods
mov     es, si

push    ss
pop     ds

POPA_NO_AX_OR_BP_MACRO
mov     ax, es

ret

tex_not_found:
loop    loop_next_tex

xor     si, si		; to return -1
jmp     didnt_find_tex

ENDP


PROC    R_TextureNumForName_ NEAR
PUBLIC  R_TextureNumForName_

push    si
xchg    ax, si
xor     ax, ax ; return 0 case
cmp     byte ptr ds:[si], '-'
je      return_false

xchg    ax, si
push    ax  ; in case needed for error case below
call    R_CheckTextureNumForName_
js      do_error  ; signed from dec si in the function above

pop     si  ; undo push above..
return_false:

pop     si


ret

do_error:

; ax with ptr already passed in
push    cs
mov     ax, OFFSET str_texturenum_error
push    ax
call    I_Error_

ENDP


 

PROC    G_SETUP_ENDMARKER_ NEAR
PUBLIC  G_SETUP_ENDMARKER_
ENDP


END
