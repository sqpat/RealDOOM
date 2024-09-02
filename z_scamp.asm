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
PROC Z_QuickMap24AI_ NEAR
PUBLIC Z_QuickMap24AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
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


PROC Z_QuickMap16AI_ NEAR
PUBLIC Z_QuickMap16AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 16
rep  outsw
pop dx
pop cx
pop si
ret

ENDP

PROC Z_QuickMap12AI_ NEAR
PUBLIC Z_QuickMap12AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 12
rep  outsw
pop dx
pop cx
pop si
ret

ENDP

  

PROC Z_QuickMap8AI_ NEAR
PUBLIC Z_QuickMap8AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 8
rep  outsw
pop dx
pop cx
pop si
ret

ENDP


PROC Z_QuickMap5AI_ NEAR
PUBLIC Z_QuickMap5AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 5
rep  outsw
pop dx
pop cx
pop si
ret

PROC Z_QuickMap4AI_ NEAR
PUBLIC Z_QuickMap4AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 4
rep  outsw
pop dx
pop cx
pop si
ret

ENDP
PROC Z_QuickMap3AI_ NEAR
PUBLIC Z_QuickMap3AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 3
rep  outsw
pop dx
pop cx
pop si
ret

ENDP
PROC Z_QuickMap2AI_ NEAR
PUBLIC Z_QuickMap2AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 2
rep  outsw
pop dx
pop cx
pop si
ret

ENDP
PROC Z_QuickMap1AI_ NEAR
PUBLIC Z_QuickMap1AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs  ; put this here to put some space between the out commands...
mov  si, ax
mov  al, dl
or   al, 040h     ; 040h for autoincrement enable. 0Ch for page 4000 index
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  dx, SCAMP_PAGE_SET_REGISTER
mov  cx, 1
rep  outsw
pop dx
pop cx
pop si
ret

ENDP

ENDP 

ENDP





END