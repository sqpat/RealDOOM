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

.386
;.MODEL  medium 
;SEGMENT DATA  USE16 PARA PUBLIC
;DATA ENDS

GLOBAL FixedMul_:PROC

SEGMENT MATH_TEXT  USE16 PARA PUBLIC 'CODE'


PROC FixedMul_ FAR
PUBLIC FixedMul_

; DX:AX  *  CX:BX
;  0  1      2  3

; need to get this out of DX:AX  CX:BX and into
; EAX and EBX (or something)
; todo improve
  sal  ecx, 16
  and  ebx, 0000FFFFh
  or   ebx, ecx

  sal  edx, 16
  and  eax, 0000FFFFh
  or   eax, edx
  
  ; actual mult and shrd..
  imul ebx
  shrd eax, edx, 16
  
  ; put results in the expected spots
  mov  edx, eax
  shr  edx, 16

ret



ENDP


MATH_TEXT ENDS

END