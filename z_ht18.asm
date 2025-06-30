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
	.MODEL medium
	.286


INCLUDE defs.inc


.DATA

HT18_PAGE_D000 = 01Ch

HT18_PAGE_SELECT_REGISTER = 01EEh
HT18_PAGE_SET_REGISTER = 01ECh

.CODE

 

COMMENT @

; no need for input registers because its always going to be ems page 0x4000
PROC Z_QuickMap24AIC_ NEAR
PUBLIC Z_QuickMap24AIC_
push si
push cx
push dx
mov  si, ax
mov  al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
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
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
mov  cx, 16
rep  outsw
pop dx
pop cx
pop si
ret
ENDP
PROC Z_QuickMap9AIC_ NEAR
PUBLIC Z_QuickMap9AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl

mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
mov  cx, 9
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
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
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
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
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
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
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
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
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
push dx
mov  si, ax
mov  al, dl
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
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
PROC Z_QuickMap2AIC_ NEAR
PUBLIC Z_QuickMap2AIC_
push si
push dx
mov  si, ax
mov  al, dl
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
lodsw
out dx, ax
lodsw
out dx, ax
pop dx
pop si
ret
ENDP


PROC Z_QuickMap1AIC_ NEAR
PUBLIC Z_QuickMap1AIC_
push si
push dx
mov  si, ax
mov  al, dl
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
lodsw
out dx, ax
pop dx
pop si
ret

 

ENDP

@

;todo test

PROC Z_QuickMapPageFrame_ FAR
PUBLIC Z_QuickMapPageFrame_

push dx
push bx

mov  bx, ax
xor  bh, bh
mov  ds:[_currentpageframes+bx], dl

mov  bx, dx
mov  dx, HT18_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, HT18_PAGE_SET_REGISTER
xchg ax, bx
add  ax, MUS_DATA_PAGES
out dx, ax

pop bx
pop dx

ret

ENDP

; todo inline its one use
PROC Z_QuickMapMusicPageFrame_ FAR
PUBLIC Z_QuickMapMusicPageFrame_

	push dx
	mov  ds:[_currentpageframes], al

	mov  ah, al
	mov  al, HT18_PAGE_D000
	mov  dx, HT18_PAGE_SELECT_REGISTER
	out  dx, al

	
	
	mov  dx, HT18_PAGE_SET_REGISTER
	xchg al, ah	 ; ah becomes 0
	mov  ax, MUS_DATA_PAGES
	out  dx, ax
	pop  dx
	retf
ENDP

LUMP_MASK = 0FCh 

PROC Z_QuickMapWADPageFrame_ FAR
PUBLIC Z_QuickMapWADPageFrame_

and  ah, LUMP_MASK

cmp  ah, byte ptr ds:[_currentpageframes + WAD_PAGE_FRAME_INDEX]
je   exit_wad_pageframe

mov  byte ptr ds:[_currentpageframes + WAD_PAGE_FRAME_INDEX], ah

mov  al, SCAMP_PAGE_FRAME_BASE_INDEX + WAD_PAGE_FRAME_INDEX	; page D400
out  SCAMP_PAGE_SELECT_REGISTER, al

mov  al, ah
xor  ah, ah

SHIFT_MACRO SHR AX 2

; adding EMS_MEMORY_PAGE_OFFSET is a manual _EPR process normally handled by c preprocessor...
; adding MUS_DATA_PAGES because this is only called for music/sound stuff, and thats the base page index for that.
add  ax, (EMS_MEMORY_PAGE_OFFSET + FIRST_LUMPINFO_LOGICAL_PAGE)
out  SCAMP_PAGE_SET_REGISTER, ax
exit_wad_pageframe:

retf


END