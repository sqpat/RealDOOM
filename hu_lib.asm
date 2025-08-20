

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


EXTRN V_DrawPatchDirect_:FAR
EXTRN locallib_toupper_:NEAR
EXTRN R_VideoErase_:NEAR


SHORTFLOORBITS = 3

.DATA




.CODE



PROC    HULIB_STARTMARKER NEAR
PUBLIC  HULIB_STARTMARKER
ENDP




PROC    HUlib_addStringToTextLine_ NEAR
PUBLIC  HUlib_addStringToTextLine_


;void __near HUlib_addStringToTextLine(hu_textline_t  __near*textline, int8_t* __near str){	


push  bx
push  si
push  di

xchg  ax, bx  ; bx is textline
mov   si, dx  ; ds:si is str

mov   di, word ptr ds:[bx + HU_TEXTLINE_T.hu_textline_len]  ; write back once at end of func

loop_do_next_char:
cmp   di, HU_MAXLINELENGTH
je    done_adding_string_to_textline
lodsb 
test  al, al
je    done_adding_string_to_textline
call  locallib_toupper_

mov   byte ptr ds:[bx + di + HU_TEXTLINE_T.hu_textline_characters], al
inc   di
mov   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_needsupdate], 4

jmp   loop_do_next_char
        
done_adding_string_to_textline:

;	textline->characters[textline->len] = 0;
mov   word ptr ds:[bx + HU_TEXTLINE_T.hu_textline_len], di  ; write back
mov   byte ptr ds:[bx + di + HU_TEXTLINE_T.hu_textline_characters], 0

pop   di
pop   si
pop   bx
ret   


ENDP




PROC    HUlib_drawTextLine_ NEAR
PUBLIC  HUlib_drawTextLine_




push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
mov   word ptr [bp - 2], 0
mov   ax, word ptr ds:[si]
cmp   word ptr ds:[si + HU_TEXTLINE_T.hu_textline_len], 0
jle   exit_hulib_drawtextline
mov   di, si
label_5:
mov   dl, byte ptr ds:[di + HU_TEXTLINE_T.hu_textline_characters]
cmp   dl, ' '
je    iter_next_drawtextline
cmp   dl, byte ptr ds:[si + 4]
jb    iter_next_drawtextline
cmp   dl, '_'
ja    iter_next_drawtextline
mov   bl, byte ptr ds:[si + 4]
xor   dh, dh
xor   bh, bh
sub   dx, bx
mov   bx, dx
add   bx, dx
mov   dx, ST_GRAPHICS_SEGMENT
mov   bx, word ptr ds:[bx + _hu_font]
mov   es, dx
mov   cx, ax
mov   dx, word ptr es:[bx]
add   cx, dx
mov   word ptr [bp - 4], cx
cmp   cx, SCREENWIDTH
jg    exit_hulib_drawtextline
mov   cx, es
mov   dx, word ptr ds:[si + 2]

call  V_DrawPatchDirect_
mov   ax, word ptr [bp - 4]
label_4:
inc   word ptr [bp - 2]
mov   dx, word ptr [bp - 2]
inc   di
cmp   dx, word ptr ds:[si + HU_TEXTLINE_T.hu_textline_len]
jl    label_5
exit_hulib_drawtextline:

LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
iter_next_drawtextline:
add   ax, 4
cmp   ax, SCREENWIDTH
jge   exit_hulib_drawtextline
jmp   label_4


ENDP




PROC    HUlib_eraseTextLine_ NEAR
PUBLIC  HUlib_eraseTextLine_

PUSHA_NO_AX_OR_BP_MACRO
cmp   byte ptr ds:[_automapactive], 0
jne   skip_erase
cmp   word ptr ds:[_viewwindowx], 0
je    skip_erase
xchg  ax, si
cmp   byte ptr ds:[si + HU_TEXTLINE_T.hu_textline_needsupdate], 0
je    skip_erase
mov   cx, word ptr ds:[si + HU_TEXTLINE_T.hu_textline_y]
mov   di, cx
add   di, 8 
mov   ax, SCREENWIDTH
mul   cx
xchg  ax, bx 

; bx =  yoffset
; cx =  y

loop_next_textline_erase:

;   for (y=textline->y, yoffset=y*SCREENWIDTH ; y<textline->y + lineheight ; y++,yoffset+=SCREENWIDTH) {
;   	if (y < viewwindowy || y >= viewwindowy + viewheight) {
;   		R_VideoErase(yoffset, SCREENWIDTH); // erase entire line
;   	}  else {
;   		R_VideoErase(yoffset, viewwindowx); // erase left border
;   		R_VideoErase(yoffset + viewwindowx + viewwidth, viewwindowx);
;   		// erase right border
;   	}
;   }

cmp   cx, di  ; textline->y + lineheight
jae   skip_erase
mov   ax, word ptr ds:[_viewwindowy]
cmp   cx, ax
jnae  skip_first_videoerase


add   ax, word ptr ds:[_viewheight]
cmp   cx, ax
jae   skip_first_videoerase

mov   ax, bx
mov   dx, word ptr ds:[_viewwindowx]

call  R_VideoErase_

mov   ax, word ptr ds:[_viewwindowx]
mov   dx, ax

add   ax, bx
add   ax, word ptr ds:[_viewwidth]
jmp   do_final_erase

skip_first_videoerase:
mov   dx, SCREENWIDTH
mov   ax, bx

do_final_erase:

call  R_VideoErase_
inc   cx
add   bx, SCREENWIDTH
jmp   loop_next_textline_erase




skip_erase:

cmp   byte ptr ds:[si + HU_TEXTLINE_T.hu_textline_needsupdate], 0
je    exit_HUlib_eraseTextLine_
dec   byte ptr ds:[si + HU_TEXTLINE_T.hu_textline_needsupdate]
exit_HUlib_eraseTextLine_:
POPA_NO_AX_OR_BP_MACRO
ret

ENDP




PROC    HUlib_addMessageToSText_ NEAR
PUBLIC  HUlib_addMessageToSText_
;void __near HUlib_addMessageToSText (int8_t* __near msg ) {



push  dx
push  si

xchg  ax, dx  ; dx holds ptr

mov   si, _w_message
inc   byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_height]
mov   byte ptr cs:[SELFMODIFY_check_stext_height+1], al

cmp   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
jne   dont_set_line_to_0
mov   byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline], 0
dont_set_line_to_0:
mov   al, SIZEOF_HUTEXTLINE_T
mul   byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
add   si, ax
push  si  ; store this one
xor   ax, ax
mov   word ptr ds:[si + HU_TEXTLINE_T.hu_textline_len], ax ; 0
mov   byte ptr ds:[si + HU_TEXTLINE_T.hu_textline_characters], al ; 0
mov   byte ptr ds:[si + HU_TEXTLINE_T.hu_textline_needsupdate], 1

mov   si, _w_message
; ax  loop counter

loop_update_next_line:
SELFMODIFY_check_stext_height:
cmp   al, 010h
jge   updated_all_lines
inc   ax
mov   byte ptr ds:[si + HU_TEXTLINE_T.hu_textline_needsupdate], 4
add   si, SIZEOF_HUTEXTLINE_T
jmp   loop_update_next_line

updated_all_lines:

pop   ax ; recover previously calculated currentline
; dx already set
call  HUlib_addStringToTextLine_
mov   byte ptr ds:[_hudneedsupdate], 4

pop   si
pop   dx
ret   

ENDP



PROC    HULIB_ENDMARKER NEAR
PUBLIC  HULIB_ENDMARKER
ENDP

END 