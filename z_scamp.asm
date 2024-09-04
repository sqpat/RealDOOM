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

SCAMP_PAGE_SELECT_REGISTER = 0E8h
SCAMP_PAGE_SET_REGISTER = 0EAh

.CODE
 

 ; todo: pass in the argument precalced as compile time thing
   ; eventually change the data structure to not even use the 2nd params (?)
 ; todo: make the 24 case fall thru
 ; todo: skip jump and do the whole thing for 1s, 4s, etc?


; Z_QuickMapAI  (autoincrement)
;



; no need for input registers because its always going to be ems page 0x4000
PROC Z_QuickMap24AIC_ NEAR
PUBLIC Z_QuickMap24AIC_
push si
push cx
push dx
mov  si, ax
mov  al, 04Ch     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 24
rep  outsw
pop dx
pop cx
pop si
ret
ENDP


PROC Z_QuickMap16AIC_ NEAR
PUBLIC Z_QuickMap16AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 16
rep  outsw
pop dx
pop cx
pop si
ret
ENDP

PROC Z_QuickMap12AIC_ NEAR
PUBLIC Z_QuickMap12AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 12
rep  outsw
pop dx
pop cx
pop si
ret
ENDP

  

PROC Z_QuickMap8AIC_ NEAR
PUBLIC Z_QuickMap8AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 8
rep  outsw
pop dx
pop cx
pop si
ret
ENDP


PROC Z_QuickMap6AIC_ NEAR
PUBLIC Z_QuickMap6AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 6
rep  outsw
pop dx
pop cx
pop si
ret
ENDP

PROC Z_QuickMap5AIC_ NEAR
PUBLIC Z_QuickMap5AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 5
rep  outsw
pop dx
pop cx
pop si
ret
ENDP

PROC Z_QuickMap4AIC_ NEAR
PUBLIC Z_QuickMap4AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 4
rep  outsw
pop dx
pop cx
pop si
ret
ENDP

PROC Z_QuickMap3AIC_ NEAR
PUBLIC Z_QuickMap3AIC_
push si
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
lodsw
out SCAMP_PAGE_SET_REGISTER, ax
lodsw
out SCAMP_PAGE_SET_REGISTER, ax
lodsw
out SCAMP_PAGE_SET_REGISTER, ax
pop si
ret
ENDP

PROC Z_QuickMap2AIC_ NEAR
PUBLIC Z_QuickMap2AIC_
push si
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
lodsw
out SCAMP_PAGE_SET_REGISTER, ax
lodsw
out SCAMP_PAGE_SET_REGISTER, ax
pop si
ret
ENDP

PROC Z_QuickMap1AIC_ NEAR
PUBLIC Z_QuickMap1AIC_
push si
mov  si, ax
mov  al, dl
out  SCAMP_PAGE_SELECT_REGISTER, al
lodsw
out SCAMP_PAGE_SET_REGISTER, ax
pop si
ret
ENDP





END