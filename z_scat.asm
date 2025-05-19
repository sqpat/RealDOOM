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

SCAT_PAGE_D000 = 018h
SCAT_PAGE_SELECT_REGISTER = 020Ah
SCAT_PAGE_SET_REGISTER = 0208h
EMS_MEMORY_PAGE_OFFSET = 080h
EMS_MEMORY_PAGE_OFFSET_PLUS_ENABLE_BIT = 08080h
EXTRN _currentpageframes:BYTE

.CODE

 



; no need for input registers because its always going to be ems page 0x4000
PROC Z_QuickMap24AIC_ NEAR
PUBLIC Z_QuickMap24AIC_
push si
push cx
push dx
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


PROC Z_QuickMap16AIC_ NEAR
PUBLIC Z_QuickMap16AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
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
PROC Z_QuickMap9AIC_ NEAR
PUBLIC Z_QuickMap9AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl

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
PROC Z_QuickMap8AIC_ NEAR
PUBLIC Z_QuickMap8AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
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

PROC Z_QuickMap6AIC_ NEAR
PUBLIC Z_QuickMap6AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
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

PROC Z_QuickMap5AIC_ NEAR
PUBLIC Z_QuickMap5AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
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
PROC Z_QuickMap4AIC_ NEAR
PUBLIC Z_QuickMap4AIC_
push si
push cx
push dx
mov  si, ax
mov  al, dl
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
PROC Z_QuickMap3AIC_ NEAR
PUBLIC Z_QuickMap3AIC_
push si
push dx
mov  si, ax
mov  al, dl
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
PROC Z_QuickMap2AIC_ NEAR
PUBLIC Z_QuickMap2AIC_
push si
push dx
mov  si, ax
mov  al, dl
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


PROC Z_QuickMap1AIC_ NEAR
PUBLIC Z_QuickMap1AIC_
push si
push dx
mov  si, ax
mov  al, dl
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al
mov  dx, SCAT_PAGE_SET_REGISTER
lodsw
out dx, ax
pop dx
pop si
ret

ENDP

; pageframeindex al
; pagenumber dl 

PROC Z_QuickMapMusicPageFrame_ FAR
PUBLIC Z_QuickMapMusicPageFrame_


;cmp  al, byte ptr ds:[_currentpageframes]
;je   exit_page_frame

push dx
mov  ds:[_currentpageframes], al

mov  ah, al
mov  al, SCAT_PAGE_D000	; page D000
mov  dx, SCAT_PAGE_SELECT_REGISTER
out  dx, al

mov  al, 0

mov  dx, SCAT_PAGE_SET_REGISTER
xchg al, ah	 ; ah becomes 0
add  ax, (EMS_MEMORY_PAGE_OFFSET_PLUS_ENABLE_BIT + MUS_DATA_PAGES)
out  dx, ax

pop dx

exit_page_frame:

retf

ENDP


PROC Z_QuickMapSFXPageFrame_ FAR
PUBLIC Z_QuickMapSFXPageFrame_

cmp  al, byte ptr ds:[_currentpageframes + 1]
je   exit_sfx_pageframe

push dx
mov  byte ptr ds:[_currentpageframes + 1], al

mov  dx, SCAT_PAGE_SELECT_REGISTER
mov  ah, al
mov  al, SCAT_PAGE_D000 + 1	; page D400
out  dx, al

mov  dx, SCAT_PAGE_SET_REGISTER
mov  al, 0
xchg al, ah

; adding EMS_MEMORY_PAGE_OFFSET_PLUS_ENABLE_BIT is a manual _EPR process normally handled by c preprocessor...
; adding MUS_DATA_PAGES because this is only called for music/sound stuff, and thats the base page index for that.
add  ax, (EMS_MEMORY_PAGE_OFFSET_PLUS_ENABLE_BIT + SFX_DATA_PAGES)
out  dx, ax

pop  dx

exit_sfx_pageframe:
retf
ENDP

LUMP_MASK = 0FCh  ; todo move to constants

PROC   Z_QuickMapWADPageFrame_ FAR
PUBLIC Z_QuickMapWADPageFrame_


and  ah, LUMP_MASK

cmp  ah, byte ptr ds:[_currentpageframes + 2]
je   exit_wad_pageframe

push dx

mov  byte ptr ds:[_currentpageframes + 2], ah

mov  dx, SCAT_PAGE_SELECT_REGISTER
mov  al, SCAT_PAGE_D000 + 2	; page D800
out  dx, al

mov  dx, SCAT_PAGE_SET_REGISTER
mov  al, ah
xor  ah, ah

SHIFT_MACRO SHR AX 2

add  ax, (EMS_MEMORY_PAGE_OFFSET_PLUS_ENABLE_BIT + FIRST_LUMPINFO_LOGICAL_PAGE)
out  dx, ax

pop  dx

exit_wad_pageframe:
;pop  ax
retf

ENDP



END