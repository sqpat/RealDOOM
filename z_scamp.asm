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

; AX = offset
; dl = count

push  cx
push  bx
push  si

; set up lodsw
mov   si, ax
add   si, word ptr _pageswapargoff
mov   ax, ds
mov   es, ax
mov   cx, dx
xor   ch, ch


; lets assume never called with 0.
;test  dl, dl
;jle   exit

; todo optimization rather than loop lets jump into unrolled loop?

DO_NEXT_PAGE_5000:
; next page in ax....
lodsw
mov        bx, ax
lodsw
; read two words - bx and ax

cmp   ax, 12
; default, lets assume backfill
jb PAGEFRAME_REGISTER_5000

out SCAMP_PAGE_SELECT_REGISTER, al   ; select EMS page

cmp   bx, 0FFFFh   ; -1 check
je    handle_default_page_with_add
; default is not the -1 case
mov   ax, bx
add   ax, SCAMP_PAGE_OFFSET_AMT   ; offset by default starting page
out   SCAMP_PAGE_SET_REGISTER, ax   ; write 16 bit page num. 


loop       DO_NEXT_PAGE_5000
; exits if we fall thru loop with no error
pop si
pop bx
pop cx
ret


PAGEFRAME_REGISTER_5000:

add   ax, 4 ; need to add 4 for d000 case for scamp...  c000, e000  not supported
out   SCAMP_PAGE_SELECT_REGISTER, al   ; select EMS page
cmp   bx, 0FFFFh   ; -1 check
je    handle_default_page
mov   ax, bx
add   ax, SCAMP_PAGE_OFFSET_AMT   ; offset by default starting page
out   SCAMP_PAGE_SET_REGISTER, ax   ; write 16 bit page num. 

loop       DO_NEXT_PAGE_5000

; exits if we fall thru loop with no error
pop si
pop bx
pop cx
ret

handle_default_page_with_add:
add   ax, 4

handle_default_page:
; mapping to page -1
out  SCAMP_PAGE_SET_REGISTER, ax   ; write 16 bit page num. 
loop       DO_NEXT_PAGE_5000
; fall thru if done..

pop si
pop bx
pop cx
ret

ENDP




END