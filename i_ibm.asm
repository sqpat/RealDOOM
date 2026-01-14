


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



.DATA



; TODO ENABLE_DISK_FLASH

.CODE


PROC    I_IBM_STARTMARKER_ NEAR
PUBLIC  I_IBM_STARTMARKER_
ENDP



PROC    I_ReadMouse_ NEAR
PUBLIC  I_ReadMouse_

push    bx
push    cx
push    dx


mov     ax, 03h
int     033h

; 03h
;on return:
;	CX = horizontal (X) position  (0..639)
;	DX = vertical (Y) position  (0..199)
;	BX = button status:

mov     ax, 0Bh
int     033h
; 0Bh
;on return:
;	CX = horizontal mickey count (-32768 to 32767)
;	DX = vertical mickey count (-32768 to 32767)
;	- count values are 1/200 inch intervals (1/200 in. = 1 mickey)

xchg    ax, bx
mov     ah, EV_MOUSE  ; ax has data1: buttons in al and EV_MOUSE in ah
; cx has data2: horizontal count

;call    D_PostEvent_
push di
mov  dx, EVENTS_SEGMENT
mov  es, dx
cwd  ; 0 no matter what
mov  dl, byte ptr ds:[_eventhead];
mov  di, dx
SHIFT_MACRO sal  di 2
stosw
xchg ax, cx ; get data2/mouse
stosw
inc  dx
and  dl, (MAXEVENTS-1)

mov  byte ptr ds:[_eventhead], dl
pop     di

pop     dx
pop     cx
pop     bx
ret

ENDP




PROC    I_IBM_ENDMARKER_ NEAR
PUBLIC  I_IBM_ENDMARKER_
ENDP


END