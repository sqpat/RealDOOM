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

EXTRN V_MarkRect_:PROC

.CODE

SCRATCH_SEGMENT_5000 = 05000h


PROC V_DrawPatchFlipped_ NEAR
PUBLIC V_DrawPatchFlipped_





push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
push  ax
mov   si, dx
mov   ax, SCRATCH_SEGMENT_5000
xor   bx, bx
mov   es, ax
sub   si, word ptr es:[bx + 6]
mov   dx, si
imul  si, si, SCREENWIDTH
mov   ax, word ptr es:[bx]
mov   word ptr [bp - 0Eh], 0
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[bx + 4]
mov   cx, word ptr es:[bx + 2]
sub   word ptr [bp - 012h], ax
mov   bx, word ptr [bp - 0Ah]
mov   ax, word ptr [bp - 012h]
mov   word ptr [bp - 8], SCREEN0_SEGMENT
call  V_MarkRect_
mov   cx, word ptr [bp - 012h]
mov   ax, word ptr [bp - 0Ah]
add   cx, si
test  ax, ax
jle   jump_to_exit_drawpatchflipped
mov   bx, ax
dec   bx
shl   bx, 1
shl   bx, 1
mov   ax, SCRATCH_SEGMENT_5000
mov   word ptr [bp - 6], ax
mov   word ptr [bp - 0Ch], ax
mov   word ptr [bp - 010h], bx

draw_next_column_flipped:
mov   es, word ptr [bp - 0Ch]
mov   bx, word ptr [bp - 010h]
mov   bx, word ptr es:[bx + 8]
cmp   byte ptr es:[bx], 0FFh
je    label_2
draw_next_post_flipped:
mov   ax, word ptr [bp - 6]
mov   es, ax
mov   word ptr [bp - 2], ax
mov   al, byte ptr es:[bx]
xor   ah, ah
imul  ax, ax, SCREENWIDTH
mov   di, word ptr [bp - 8]
mov   word ptr [bp - 4], di
mov   di, cx
add   di, ax
mov   al, byte ptr es:[bx + 1]
lea   si, [bx + 3]
xor   ah, ah
mov   ds, word ptr [bp - 2]
mov   es, word ptr [bp - 4]
loop_copy_pixel:
dec   ax
cmp   ax, 0FFFFh   ; todo js?
je    done_drawing_post_flipped

movsb
add   di, SCREENWIDTH-1
jmp   loop_copy_pixel
jump_to_exit_drawpatchflipped:
jmp   exit_drawpatchflipped
done_drawing_post_flipped:
mov   es, word ptr [bp - 6]
mov   al, byte ptr es:[bx + 1]
xor   ah, ah
add   bx, ax
add   bx, 4
cmp   byte ptr es:[bx], 0FFh
jne   draw_next_post_flipped
label_2:
inc   word ptr [bp - 012h]
inc   word ptr [bp - 0Eh]
add   word ptr [bp - 010h], -4
mov   ax, word ptr [bp - 0Eh]
inc   cx
cmp   ax, word ptr [bp - 0Ah]
jge   exit_drawpatchflipped
jmp   draw_next_column_flipped
exit_drawpatchflipped:
LEAVE_MACRO
mov   ax, ss
mov   ds, ax
pop   di
pop   si
pop   cx
pop   bx
ret   




ENDP


END