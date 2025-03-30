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

SCAMP_PAGE_FRAME_BASE_INDEX = 4    ; todo ??? d000?
SCAMP_PAGE_SELECT_REGISTER = 0E8h
SCAMP_PAGE_SET_REGISTER = 0EAh
EMS_MEMORY_PAGE_OFFSET = 050h


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

COMMENT @
void __far Z_QuickMapPageFrame(uint8_t pageframeindex, uint8_t pagenumber){
	// page frame index 0 to 3
	// count 
	regs.h.ah = 0x44;
	regs.h.al = pageframeindex;
	regs.w.bx = pagenumber + MUS_DATA_PAGES;
	regs.w.dx = emshandle; // handle
	intx86(EMS_INT, &regs, &regs);
}
@


; pageframeindex al
; pagenumber dl 

PROC Z_QuickMapPageFrame_ FAR
PUBLIC Z_QuickMapPageFrame_

add  al, SCAMP_PAGE_FRAME_BASE_INDEX	; add by 4 to get d000 (page frame) index. TODO unhardcode
out  SCAMP_PAGE_SELECT_REGISTER, al
mov  ax, dx
; todo need xor ah/dh??
xor  ah, ah
; adding EMS_MEMORY_PAGE_OFFSET is a manual _EPR process normally handled by c preprocessor...
; adding MUS_DATA_PAGES because this is only called for music/sound stuff, and thats the base page index for that.
add  ax, (EMS_MEMORY_PAGE_OFFSET + MUS_DATA_PAGES)
out  SCAMP_PAGE_SET_REGISTER, ax

ret
ENDP

END