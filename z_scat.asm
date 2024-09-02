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
EXTRN	_pageswapargs_single:WORD
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


PROC Z_QuickMap12_ NEAR
PUBLIC Z_QuickMap12_
push bx
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_12
ENDP
PROC Z_QuickMap9_ NEAR
PUBLIC Z_QuickMap9_
push bx
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_9

ENDP
PROC Z_QuickMap8_ NEAR
PUBLIC Z_QuickMap8_
push bx
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_8

ENDP
PROC Z_QuickMap6_ NEAR
PUBLIC Z_QuickMap6_
push bx
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_6

ENDP
PROC Z_QuickMap1_ NEAR
PUBLIC Z_QuickMap1_
push bx
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_1
unrolled_loop_12:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_11:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_10:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_9:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_8:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_7:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_6:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_5:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_4:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_3:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_2:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax
unrolled_loop_1:
lodsw
mov  bx, ax
lodsw
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  ax, bx
mov  dx, SCAT_PAGE_SET_REGISTER
out  dx, ax

pop  dx
pop  si
pop  bx
ret  
 
ENDP


; no need for input registers because its always going to be ems page 0x4000
PROC Z_QuickMap24AI_ NEAR
PUBLIC Z_QuickMap24AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
mov  cx, 24
rep  outsw
pop dx
pop cx
pop si
ret
ENDP


PROC Z_QuickMap16AI_ NEAR
PUBLIC Z_QuickMap16AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_16
ENDP
PROC Z_QuickMap9AI_ NEAR
PUBLIC Z_QuickMap9AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_9
ENDP
PROC Z_QuickMap8AI_ NEAR
PUBLIC Z_QuickMap8AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_8
ENDP
PROC Z_QuickMap6AI_ NEAR
PUBLIC Z_QuickMap6AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_6
ENDP
PROC Z_QuickMap5AI_ NEAR
PUBLIC Z_QuickMap5AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_4
ENDP
PROC Z_QuickMap4AI_ NEAR
PUBLIC Z_QuickMap4AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_4
ENDP
PROC Z_QuickMap3AI_ NEAR
PUBLIC Z_QuickMap3AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_3
ENDP
PROC Z_QuickMap2AI_ NEAR
PUBLIC Z_QuickMap2AI_
push si
push dx
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 080h                     ; enable autoincrement
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
jmp unrolled_loop_AI_2

unrolled_loop_AI_24:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_23:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_22:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_21:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_20:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_19:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_18:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_17:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_16:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_15:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_14:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_13:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_12:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_11:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_10:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_9:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_8:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_7:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_6:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_5:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_4:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_3:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_2:
lodsw
add  si, 2
out  dx, ax
unrolled_loop_AI_1:
lodsw
out  dx, ax
pop  dx
pop  si
ret  
 

ENDP


END