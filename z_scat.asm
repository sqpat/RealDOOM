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

SCAT_PAGE_SELECT_REGISTER = 020Ah
SCAT_PAGE_SET_REGISTER = 0208h

.CODE


;
; Z_QuickMap
;

;int16_t offset, int8_t count


PROC Z_QuickMap2_ NEAR
PUBLIC Z_QuickMap2_

; AX = offset
; dl (? or dx)= count

push  cx
push  bx
push  si
push  dx

; set up lodsw
mov   si, ax
add   si, word ptr _pageswapargoff
mov   cx, dx
xor   ch, ch

; todo optimization rather than loop lets jump into unrolled loop?

DO_NEXT_PAGE_5000:
lodsw      ; next page in ax....
mov   bx, ax
lodsw             						; read two words - bx and ax
mov   dx, SCAT_PAGE_SELECT_REGISTER
out   dx, al   	; select EMS page
mov   ax, bx
mov   dx, SCAT_PAGE_SET_REGISTER
out   dx, ax   	; write 16 bit page num. 
loop  DO_NEXT_PAGE_5000

; exits if we fall thru loop with no error
pop dx
pop si
pop bx
pop cx
ret
 

 

ENDP




END