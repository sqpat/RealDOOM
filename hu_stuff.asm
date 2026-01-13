

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


EXTRN HUlib_drawTextLine_:NEAR
EXTRN HUlib_eraseTextLine_:NEAR
EXTRN HUlib_addMessageToSText_:NEAR
EXTRN Z_QuickMapStatus_Physics_:NEAR



EXTRN _w_message:NEAR
EXTRN _w_title:NEAR
.DATA




.CODE



HU_MSGTIMEOUT = 4 * TICRATE
HU_MSGREFRESH = KEY_ENTER

PROC    HU_STUFF_STARTMARKER_ NEAR
PUBLIC  HU_STUFF_STARTMARKER_
ENDP

exit_hu_drawer_early:
pop   si
pop   dx
pop   cx
pop   bx
retf   

PROC    HU_Drawer_ FAR
PUBLIC  HU_Drawer_

push  bx
push  cx
push  dx
push  si

xor   cx, cx
xor   ax, ax
cwd
mov   si, OFFSET _w_message
mov   bx, word ptr cs:[si + HU_STEXT_T.hu_stext_onptr]
cmp   byte ptr ds:[bx], al ; 0
je    exit_hu_drawer_early

cmp   byte ptr ds:[_hudneedsupdate],al ; 0
jne   draw_everything
cmp   byte ptr ds:[_automapactive], al  ; 0
jne   draw_everything
cmp   byte ptr ds:[_screenblocks], 10
jb    done_drawing_everything

draw_everything:



draw_next_line:
mov   bl, byte ptr cs:[si + HU_STEXT_T.hu_stext_height]
cmp   dl, bl
jge   finish_loop
mov   al, byte ptr cs:[si + HU_STEXT_T.hu_stext_currentline]

sub   al, dl
jge   dont_add_height
add   al, bl
dont_add_height:
mov   ah, (SIZE HU_TEXTLINE_T)
mul   ah
xchg  ax, bx

jcxz  do_quickmap
done_mapping:

lea   ax, [bx + si]
call  HUlib_drawTextLine_
inc   dx
jmp   draw_next_line


finish_loop:
dec   byte ptr ds:[_hudneedsupdate]
done_drawing_everything:

cmp   byte ptr ds:[_automapactive], ch ; 0
je    check_if_mapped
inc   cx
call  Z_QuickMapStatus_Physics_

mov   ax, OFFSET _w_title
call  HUlib_drawTextLine_

check_if_mapped:
jcxz  exit_hu_drawer

Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET

exit_hu_drawer:
pop   si
pop   dx
pop   cx
pop   bx
retf   

do_quickmap:
inc   cx    ; mark mapped
call  Z_QuickMapStatus_Physics_

jmp   done_mapping





ENDP



PROC    HU_Erase_ FAR
PUBLIC  HU_Erase_


push  bx
push  cx
push  dx
push  si


push  cs
pop   ds

mov   bx, OFFSET _w_message
mov   dx, bx

xor   cx, cx
mov   si, word ptr ds:[bx + HU_STEXT_T.hu_stext_onptr]

loop_hu_erase_next_line:
cmp   cl, byte ptr ds:[bx + HU_STEXT_T.hu_stext_height]
jge   end_erase_loop_erase_last_line
cmp   byte ptr ds:[bx + HU_STEXT_T.hu_stext_laston], ch   ; known 0
je    dont_mark_line_for_update


cmp   byte ptr ds:[si], ch ; known 0
jne   dont_mark_line_for_update

mov   byte ptr ds:[si + bx + HU_TEXTLINE_T.hu_textline_needsupdate], 4


dont_mark_line_for_update:
mov   ax, dx


call  HUlib_eraseTextLine_


inc   cx
add   dx, (SIZE HU_TEXTLINE_T)
jmp   loop_hu_erase_next_line


end_erase_loop_erase_last_line:
lodsb ; word ptr ds:[OFFSET _w_message + HU_STEXT_T.hu_stext_onptr]
mov   byte ptr ds:[bx + HU_STEXT_T.hu_stext_laston], al
mov   ax, OFFSET _w_title

call  HUlib_eraseTextLine_

push  ss
pop   ds


pop   si
pop   dx
pop   cx
pop   bx
retf


ENDP



PROC    HU_Ticker_ FAR
PUBLIC  HU_Ticker_


push  bx
push  cx
push  bp
mov   bp, sp
sub   sp, 0100h

xor   ax, ax

cmp   byte ptr ds:[_message_counter], al
je    dont_reset_count
dec   byte ptr ds:[_message_counter]
jnz   dont_reset_count

; already zero
;mov   byte ptr ds:[_message_counter], al ; 0
mov   word ptr ds:[_message_on], ax      ; 0   ; gets both
; redraw hud ?
mov   byte ptr ds:[_borderdrawcount], 3
mov   byte ptr ds:[_hudneedsupdate], 6

; mov   byte ptr ds:[_message_nottobefuckedwith], al ; 0

dont_reset_count:

cmp   byte ptr ds:[_showMessages], al ; 0
jne   skip_early_exit_check
cmp   byte ptr ds:[_message_dontfuckwithme], al
je    exit_hu_ticker

skip_early_exit_check:

cmp   byte ptr ds:[_player_message_string], al ; 0
jne   has_message
cmp   word ptr ds:[_player + PLAYER_T.player_message], -1
je    check_player_message

has_message:

cmp   byte ptr ds:[_message_nottobefuckedwith], al ;0
je    continue_checks


check_player_message:

cmp   word ptr ds:[_player + PLAYER_T.player_message], ax ; 0
je    exit_hu_ticker

cmp   byte ptr ds:[_message_dontfuckwithme], al ; 0
je    exit_hu_ticker

continue_checks:

mov   ax, word ptr ds:[_player + PLAYER_T.player_message]
cmp   ax, -1
jne   go_get_string


mov   ax, OFFSET _player_message_string
call  HUlib_addMessageToSText_
mov   word ptr ds:[_player_message_string], 0
jmp   skip_getting_string

go_get_string:
lea   bx, [bp - 0100h]
mov   cx, ss
push  bx

call  dword ptr ds:[_getStringByIndex_addr]

pop   ax  ;bp - 0100h
call  HUlib_addMessageToSText_

mov   word ptr ds:[_player + PLAYER_T.player_message], -1
skip_getting_string:

mov   byte ptr ds:[_message_on], 1
mov   byte ptr ds:[_message_counter], HU_MSGTIMEOUT
mov   al, byte ptr ds:[_message_dontfuckwithme]
mov   byte ptr ds:[_message_nottobefuckedwith], al
mov   byte ptr ds:[_message_dontfuckwithme], 0

exit_hu_ticker:
LEAVE_MACRO 
pop   cx
pop   bx
retf   





ENDP

PROC    HU_Responder_ FAR
PUBLIC  HU_Responder_

push  bx
xchg  ax, bx
mov   es, dx
mov   ax, word ptr es:[bx + EVENT_T.event_data1]
cmp   al, KEY_RSHIFT
je    exit_hu_responder
not_rshift:
cmp   al, KEY_RALT
je    exit_hu_responder
not_alt:
cmp   ah,  EV_KEYDOWN
jne   exit_hu_responder
cmp   al, HU_MSGREFRESH
jne   exit_hu_responder
mov   byte ptr ds:[_message_on], 1
mov   byte ptr ds:[_message_counter], HU_MSGTIMEOUT
exit_hu_responder:
pop   bx
retf   




ENDP



PROC    HU_STUFF_ENDMARKER_ NEAR
PUBLIC  HU_STUFF_ENDMARKER_
ENDP

END 