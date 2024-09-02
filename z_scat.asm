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

EXTRN	_pageswapargs_single:WORD

SCAT_PAGE_SELECT_REGISTER = 020Ah
SCAT_PAGE_SET_REGISTER = 0208h

.CODE

 



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
push cx
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or   al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
mov  cx, 16
rep  outsw
pop dx
pop cx
pop si
ret
ENDP
PROC Z_QuickMap9AI_ NEAR
PUBLIC Z_QuickMap9AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
mov  cx, 9
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
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
mov  cx, 8
rep  outsw
pop dx
pop cx
pop si
ret
ENDP

PROC Z_QuickMap6AI_ NEAR
PUBLIC Z_QuickMap6AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
mov  cx, 6
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
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
mov  cx, 5
rep  outsw
pop dx
pop cx
pop si
ret
ENDP
PROC Z_QuickMap4AI_ NEAR
PUBLIC Z_QuickMap4AI_
push si
push cx
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
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
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
lodsw
out dx, ax
lodsw
out dx, ax
lodsw
out dx, ax
pop dx
pop si
ret
ENDP
PROC Z_QuickMap2AI_ NEAR
PUBLIC Z_QuickMap2AI_
push si
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
lodsw
out dx, ax
lodsw
out dx, ax
pop dx
pop si
ret
ENDP


PROC Z_QuickMap1AI_ NEAR
PUBLIC Z_QuickMap1AI_
push si
push dx
add  ax, OFFSET _pageswapargs_single
mov  si, ax
mov  al, dl
or  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
lodsw
out dx, ax
pop dx
pop si
ret



ENDP


END