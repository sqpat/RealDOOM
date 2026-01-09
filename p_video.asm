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


; NOTE i think a lot of this function is an optimization candidate
; todo move jump mult table to cs...

EXTRN M_AddToBox16_:NEAR
.DATA


.CODE


EXTRN W_CacheLumpNameDirect_:FAR
EXTRN Z_QuickMapScratch_5000_:FAR  
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN W_CacheLumpNumDirectFragment_:FAR
EXTRN Z_QuickMapByTaskNum_:FAR


PROC   P_VIDEO_STARTMARKER_ NEAR
PUBLIC P_VIDEO_STARTMARKER_
ENDP

_jump_mult_table_3:
db 19, 18, 15, 12,  9,  6,  3, 0


jumptoexitdirect:
jmp   jumpexitdirect


PROC V_DrawPatchDirect_ FAR
PUBLIC V_DrawPatchDirect_

; CX:BX is patch
; dx is y
; ax is x

;bp  - 2 is ax  (x)

push  si
push  di
push  bp
mov   bp, sp

mov   es, cx

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
 

; patch is es:bx
sub   ax, word ptr es:[bx + 4]	; leftoffset
sub   dx, word ptr es:[bx + 6]  ; topoffset
mov   si, ax  ; store x
mov   ax, (SCREENWIDTH / 4)
mul   dx

mov   word ptr cs:[SELFMODIFY_retrievepatchoffset+1], bx
; load destscreen into es:bx to calc desttop
mov   di, bx
mov   word ptr cs:[SELFMODIFY_retrievenextcoloffset + 1], di
les   bx, dword ptr ds:[_destscreen]
mov   ds, cx

   
add   bx, ax
mov   ax, si

;	desttop = (byte __far*)(destscreen->w + y * (SCREENWIDTH / 4) + (x>>2));
;   es:bx is desttop

SHIFT_MACRO SAR AX 2

;    w = (patch->width); 
;    for ( col = 0 ; col<w ; col++) 


;	column = (column_t  __far*)((byte  __far*)patch + (patch->columnofs[col]));

mov   word ptr cs:[SELFMODIFY_col_increment+1], 0

add   ax, bx

mov   word ptr cs:[SELFMODIFY_offset_set_di+1], ax
mov   ax, word ptr ds:[di]  ; get width
mov   word ptr cs:[SELFMODIFY_compare_instruction_direct + 1], ax
test  ax, ax
jle   jumptoexitdirect

draw_next_column_direct:

;		outp (SC_INDEX+1,1<<(x&3));
inc   word ptr cs:[SELFMODIFY_col_increment+1]    ; col++

mov   cx, si ; retrieve x
mov   ax, 1


mov   dx, SC_DATA
and   cl, 3
SELFMODIFY_retrievenextcoloffset:
mov   di, 0F030h
shl   ax, cl
SELFMODIFY_retrievepatchoffset:
mov   bx, 0F030h



out   dx, al
mov   dx, si  ; store x in dx
add   bx, word ptr ds:[di + 8]
cmp   byte ptr ds:[bx], 0FFh
je    check_desttop_increment
draw_next_column_patch_direct:
mov   al, byte ptr ds:[bx]
mov   ah, (SCREENWIDTH / 4)
mul   ah
SELFMODIFY_offset_set_di:
mov   di, 0F030h
add   di, ax
mov   cl, byte ptr ds:[bx + 1]  ; get col length
xor   ch, ch
mov   si, cx
and   si, 0007h
mov   al, byte ptr cs:[_jump_mult_table_3 + si]
mov   byte ptr cs:[SELFMODIFY_offset_draw_remaining_pixels_direct + 1], al
mov   ax,  ((SCREENWIDTH / 4) - 1)
lea   si, [bx + 3]
SHIFT_MACRO shr cx 3
je    done_drawing_8_pixels_direct


draw_8_more_pixels_direct:

movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
loop draw_8_more_pixels_direct

done_drawing_8_pixels_direct:

SELFMODIFY_offset_draw_remaining_pixels_direct:
db 0EBh, 00h		; jump rel8

movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb


done_drawing_column:
mov   al, byte ptr ds:[bx + 1]
; ah is 0
add   bx, ax
add   bx, 4
cmp   byte ptr ds:[bx], 0FFh
jne   draw_next_column_patch_direct
check_desttop_increment:

;	if ( ((++x)&3) == 0 ) 
;	    desttop++;	// go to next byte, not next plane 
;    }


inc   dx
test  dx, 3
jne   dont_increment_desttop						; todo change branch? 1/4 chance of fallthru?
inc   word ptr cs:[SELFMODIFY_offset_set_di+1]
dont_increment_desttop:
SELFMODIFY_col_increment:
mov   ax, 0F030h
add   word ptr cs:[SELFMODIFY_retrievenextcoloffset + 1], 4
SELFMODIFY_compare_instruction_direct:
cmp   ax, 0F030h
jge   jumpexitdirect

mov   si, dx
jmp   draw_next_column_direct
jumpexitdirect:
mov   ax, ss
mov   ds, ax
LEAVE_MACRO
pop   di
pop   si
retf  

ENDP

PROC   P_VIDEO_ENDMARKER_ NEAR
PUBLIC P_VIDEO_ENDMARKER_ 
ENDP



END