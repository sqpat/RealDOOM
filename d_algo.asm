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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO


.CODE



; nice for debug... 
COMMENT @

PROC getSPBP_ NEAR
PUBLIC getSPBP_

mov dx, sp
mov ax, bp


ret


PROC getDSSS_ NEAR
PUBLIC getDSSS_

mov dx, ds
mov ax, ss


ret

@



ENDP

; end marker for this asm file
PROC D_ALGO_END_ NEAR
PUBLIC D_ALGO_END_ 
ENDP


END