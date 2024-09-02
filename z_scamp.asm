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

PROC Z_QuickMap24_ NEAR
PUBLIC Z_QuickMap24_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_24
ENDP
PROC Z_QuickMap16_ NEAR
PUBLIC Z_QuickMap16_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_16
ENDP
PROC Z_QuickMap12_ NEAR
PUBLIC Z_QuickMap12_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_12
ENDP
PROC Z_QuickMap9_ NEAR
PUBLIC Z_QuickMap9_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_9
ENDP
PROC Z_QuickMap8_ NEAR
PUBLIC Z_QuickMap8_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_8
ENDP
PROC Z_QuickMap7_ NEAR
PUBLIC Z_QuickMap7_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_7
ENDP
PROC Z_QuickMap6_ NEAR
PUBLIC Z_QuickMap6_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_6
ENDP
PROC Z_QuickMap5_ NEAR
PUBLIC Z_QuickMap5_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_5
ENDP
PROC Z_QuickMap4_ NEAR
PUBLIC Z_QuickMap4_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_4
ENDP
PROC Z_QuickMap3_ NEAR
PUBLIC Z_QuickMap3_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_3
ENDP
PROC Z_QuickMap2_ NEAR
PUBLIC Z_QuickMap2_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_2
ENDP
PROC Z_QuickMap1_ NEAR
PUBLIC Z_QuickMap1_
push bx
push si
mov  si, ax
add  si, OFFSET _pageswapargs
jmp unrolled_loop_1

unrolled_loop_24:
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

 ; todo: pass in the argument precalced as compile time thing


; Z_QuickMapAI  (autoincrement)
;

PROC Z_QuickMap24AI_ NEAR
PUBLIC Z_QuickMap24AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_24
ENDP
PROC Z_QuickMap16AI_ NEAR
PUBLIC Z_QuickMap16AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_16
ENDP
PROC Z_QuickMap12AI_ NEAR
PUBLIC Z_QuickMap12AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_12
ENDP
PROC Z_QuickMap9AI_ NEAR
PUBLIC Z_QuickMap9AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_9
ENDP
PROC Z_QuickMap8AI_ NEAR
PUBLIC Z_QuickMap8AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_8
ENDP
PROC Z_QuickMap7AI_ NEAR
PUBLIC Z_QuickMap7AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_7
ENDP
PROC Z_QuickMap6AI_ NEAR
PUBLIC Z_QuickMap6AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_6
ENDP
PROC Z_QuickMap5AI_ NEAR
PUBLIC Z_QuickMap5AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_5
ENDP
PROC Z_QuickMap4AI_ NEAR
PUBLIC Z_QuickMap4AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_4
ENDP
PROC Z_QuickMap3AI_ NEAR
PUBLIC Z_QuickMap3AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_3
ENDP
PROC Z_QuickMap2AI_ NEAR
PUBLIC Z_QuickMap2AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_2
ENDP
PROC Z_QuickMap1AI_ NEAR
PUBLIC Z_QuickMap1AI_
push si
mov  si, ax
add  si, OFFSET _pageswapargs
mov  ax, word ptr ds:[si+2]        ; first word param
or   al, 040h                     ; enable autoincrement
out  SCAMP_PAGE_SELECT_REGISTER, al
jmp unrolled_loop_AI_1

unrolled_loop_AI_24:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_23:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_22:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_21:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_20:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_19:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_18:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_17:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_16:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_15:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_14:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_13:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_12:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_11:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_10:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_9:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_8:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_7:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_6:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_5:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_4:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_3:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_2:
lodsw
add  si, 2
out  SCAMP_PAGE_SET_REGISTER, ax
unrolled_loop_AI_1:
lodsw
out  SCAMP_PAGE_SET_REGISTER, ax

pop  si
ret  
 

ENDP





END