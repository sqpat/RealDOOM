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

;GLOBAL FixedMul_:FAR

SEGMENT MATH_TEXT  USE16 PARA PUBLIC 'CODE'

;ASSUME cs:MATH_TEXT


PROC FixedMul_ FAR
PUBLIC FixedMul_

; DX:AX  *  CX:BX
;  0  1      2  3

; need to get this out of DX:AX  CX:BX and into
; EAX and EBX (or something)
; todo improve
  sal  ebx, 16
  shrd ebx, ecx, 16

  sal  eax, 16
  shrd eax, edx, 16

  ; actual mult and shrd..
  imul ebx
  ; put results in the expected spots
  ; edx low 16 bits already contains bits 32-48 of result
  ; need to move eax's high 16 bits low.
  shr  eax, 16

ret



ENDP


MATH_TEXT ENDS

END