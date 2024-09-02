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

SCAMP_PAGE_SELECT_REGISTER = 0E8h
SCAMP_PAGE_SET_REGISTER = 0EAh

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
out   SCAMP_PAGE_SELECT_REGISTER, al   	; select EMS page
mov   ax, bx
out   SCAMP_PAGE_SET_REGISTER, ax   	; write 16 bit page num. 
loop  DO_NEXT_PAGE_5000

; exits if we fall thru loop with no error
pop si
pop bx
pop cx
ret
 

 

ENDP






PROC Z_QuickMap_ NEAR
PUBLIC Z_QuickMap_

; AX = offset
; dl (? or dx)= count

push bx
push si
mov  si, ax
mov  ax, 00A18h   ; 10 in ah for mul. 24 in al to sub for 24 - count
sub  al, dl
mul  ah  ; 10 bytes per loop
add  si, OFFSET _pageswapargs


mov  bx, OFFSET unrolled_loop_start
add  bx, ax
jmp  bx

unrolled_loop_start:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_23:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_22:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_21:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_20:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_19:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_18:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_17:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_16:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_15:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_14:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_13:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_12:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_11:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_10:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_9:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_8:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_7:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_6:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_5:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_4:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_3:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_2:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_1:
lodsw
mov  bx, ax
lodsw
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, bx
out  SCAMP_PAGE_SET_REGISTER, ax


pop  si
pop  bx
ret  
 

 

ENDP





END