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

EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapRender_:FAR
EXTRN Z_QuickMapRenderPlanes_:FAR
EXTRN Z_QuickMapUndoFlatCache_:FAR
EXTRN Z_QuickMapWADPageFrame_:FAR
EXTRN copystr8_:NEAR

 
.DATA


.CODE

EXTRN  _doomdata_bin_string:NEAR

PROC    P_SETUP_STARTMARKER_ NEAR
PUBLIC  P_SETUP_STARTMARKER_
ENDP


PROC    P_SpawnMapThingCallThrough_ FAR
PUBLIC  P_SpawnMapThingCallThrough_

; ugly for now. so this is passed in a struct, not a pointer to a struct. 
; so theres a billion (or so) bytes on stack
; for now this is just a trampoline/placeholder func until p_setup is in asm
; we far jump to our func instead of calling. so it returns to the other place

;db    09Ah  ; call
db    0EAh   ; jump
dw    P_SPAWNMAPTHINGOFFSET, PHYSICS_HIGHCODE_SEGMENT
; ret   ; ret unused..
ENDP


PROC    P_SpawnSpecialsCallThrough_ NEAR
PUBLIC  P_SpawnSpecialsCallThrough_
db    09Ah  ; call
dw    P_SPAWNSPECIALSOFFSET, PHYSICS_HIGHCODE_SEGMENT
ret
ENDP

PROC    S_StartCallThrough_ NEAR
PUBLIC  S_StartCallThrough_
db    09Ah  ; call
dw    S_STARTOFFSET, PHYSICS_HIGHCODE_SEGMENT
ret
ENDP

PROC    P_InitThinkersCallThrough_ NEAR
PUBLIC  P_InitThinkersCallThrough_
call    P_InitThinkers_
ret
ENDP


PROC    P_InitThinkers_ FAR
PUBLIC  P_InitThinkers_

push    di
push    cx
push    dx

mov     di, OFFSET _thinkerlist
mov     dx, 1
mov     word ptr ds:[di + THINKER_T.t_next], dx
mov     word ptr ds:[di + THINKER_T.t_prevFunctype], dx
mov     ax, MAX_THINKERS  ; technically MAX_THINKERS | TF_NULL_HIGHBITS
mov     cx, ax
; dh already 0
mov     dl, (SIZE THINKER_T) - 2  ; account for stosw

push    ds
pop     es

;add    di, THINKER_T.t_prevFunctype    ; unncessary, equals 0.

loop_init_next_thinker:
stosw
add     di, dx
loop    loop_init_next_thinker

mov     word ptr ds:[_currentThinkerListHead], cx   ; cx is 0 after loop

pop     dx
pop     cx
pop     di

retf
ENDP




PROC    P_SETUP_ENDMARKER_ NEAR
PUBLIC  P_SETUP_ENDMARKER_
ENDP


END