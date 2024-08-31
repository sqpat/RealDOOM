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
	.286


INCLUDE defs.inc


.DATA

EXTRN	_pageswapargs:WORD
EXTRN	_pageswapargoff:WORD


SCAMP_PAGE_OFFSET_AMT = 80h
SCAMP_PAGE_SELECT_REGISTER = 0E8h
SCAMP_PAGE_SET_REGISTER = 0EAh


.CODE


;
; Z_QuickMap
;

;int16_t offset, int8_t count


PROC Z_QuickMap_ NEAR
PUBLIC Z_QuickMap_

; bp - 2 = count copy
; AX = offset
; dl = count

push  bx
push  cx
push  si
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
mov   byte ptr [bp - 2], dl
add   si, word ptr _pageswapargoff
test  dl, dl
jle   exit
loop_start:
mov   cx, word ptr [si + 2]
mov   bx, word ptr [si]
cmp   cx, 00Ch
jae   label_3
add   cx, 4
mov   dx, SCAMP_PAGE_SELECT_REGISTER
mov   al, cl
out   dx, al
cmp   bx, -1
jne   label_4
mov   dx, SCAMP_PAGE_SET_REGISTER
mov   ax, cx
out   dx, ax
label_1:
dec   byte ptr [bp - 2]
add   si, 4
cmp   byte ptr [bp - 2], 0
jg    loop_start
exit:
leave 
pop   si
pop   cx
pop   bx
ret   
label_3:
mov   dx, SCAMP_PAGE_SELECT_REGISTER
mov   al, cl
out   dx, al
cmp   bx, -1
jne   label_2
mov   ax, cx
mov   dx, SCAMP_PAGE_SET_REGISTER
add   ax, 4
out   dx, ax
jmp   label_1
label_2:
mov   dx, SCAMP_PAGE_SET_REGISTER
lea   ax, [bx + SCAMP_PAGE_OFFSET_AMT]
out   dx, ax
jmp   label_1
label_4:
mov   dx, SCAMP_PAGE_SET_REGISTER
lea   ax, [bx + SCAMP_PAGE_OFFSET_AMT]
out   dx, ax
jmp   label_1

ENDP



PROC  Z_QuickMapNo_ NEAR
PUBLIC  Z_QuickMapNo_ 

; ax = offset
; cx = count

;push bx
;push si

mov  si, OFFSET _pageswapargs
add  si, ax

mov ax, ds
mov es, ax  ; load ds into es.

; es:si is now set up for lodsw:

DO_NEXT_PAGE:
lodsw
mov        bx, ax
lodsw
; read two words - bx and ax

cmp ax, 12
jae NOT_CONVENTIONAL_REGISTER_5000
add ax, 4 ; need to add 4 for d000 case for scamp...  c000, e000  not supported
out        0E8h, al   ; select EMS page
sub ax, 4
xchg  ax, bx
cmp   ax, 0FFFFh   ; -1 check
je    handle_default_page
add   ax, SCAMP_PAGE_OFFSET_AMT   ; offset by default starting page
out   0EAh, ax   ; write 16 bit page num. 

loop       DO_NEXT_PAGE

; exits if we fall thru loop with no error
;pop si
;pop bx
ret

NOT_CONVENTIONAL_REGISTER_5000:
 
out        0E8h, al   ; select EMS page

xchg  ax, bx
cmp   ax, 0FFFFh   ; -1 check
je    handle_default_page

add   ax, SCAMP_PAGE_OFFSET_AMT   ; offset by default starting page
out   0EAh, ax   ; write 16 bit page num. 


loop       DO_NEXT_PAGE

; exits if we fall thru loop with no error
;pop si
;pop bx
ret

handle_default_page:
; mapping to page -1
mov  ax,   bx   ; retrieve page number
add  ax,   4
out  0EAh, ax   ; write 16 bit page num. 
loop       DO_NEXT_PAGE
; fall thru if done..

;pop si
;pop bx
ret





ENDP

END