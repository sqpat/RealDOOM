

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
EXTRN Z_QuickMapStatus_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN getStringByIndex_:FAR

.DATA




.CODE



HU_MSGTIMEOUT = 4 * TICRATE
HU_MSGREFRESH = KEY_ENTER

PROC    HU_STUFF_STARTMARKER_ NEAR
PUBLIC  HU_STUFF_STARTMARKER_
ENDP



PROC    HU_Drawer_ NEAR
PUBLIC  HU_Drawer_

push  bx
push  cx
push  dx
push  si

xor   cx, cx
xor   ax, ax
cwd
mov   si, _w_message
mov   bx, word ptr ds:[si + HU_STEXT_T.hu_stext_onptr]
cmp   byte ptr ds:[bx], al ; 0
je    exit_hu_drawer

cmp   byte ptr ds:[_hudneedsupdate],al ; 0
jne   draw_everything
cmp   byte ptr ds:[_automapactive], al  ; 0
jne   draw_everything
cmp   byte ptr ds:[_screenblocks], 10
jb    done_drawing_everything

draw_everything:



draw_next_line:
mov   bl, byte ptr ds:[si + HU_STEXT_T.hu_stext_height]
cmp   dl, bl
jge   finish_loop
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]

sub   al, dl
jge   dont_add_height
add   al, bl
dont_add_height:
mov   ah, SIZEOF_HUTEXTLINE_T
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
call  Z_QuickMapStatus_
mov   ax, _w_title
call  HUlib_drawTextLine_

check_if_mapped:
jcxz  exit_hu_drawer

call  Z_QuickmapPhysics_
exit_hu_drawer:
pop   si
pop   dx
pop   cx
pop   bx
ret   

do_quickmap:
inc   cx    ; mark mapped
call  Z_QuickMapStatus_
jmp   done_mapping





ENDP



PROC    HU_Erase_ NEAR
PUBLIC  HU_Erase_


push  bx
push  dx
push  si
mov   dx, _w_message
xor   bx, bx
mov   si, word ptr ds:[_w_message + HU_STEXT_T.hu_stext_onptr]

loop_hu_erase_next_line:
cmp   bl, byte ptr ds:[_w_message + HU_STEXT_T.hu_stext_height]
jge   end_erase_loop_erase_last_line
cmp   byte ptr ds:[_w_message + HU_STEXT_T.hu_stext_laston], bh   ; known 0
je    dont_mark_line_for_update


cmp   byte ptr ds:[si], bh ; known 0
jne   dont_mark_line_for_update
xchg  dx, si
mov   byte ptr ds:[si + OFFSET _w_message + HU_TEXTLINE_T.hu_textline_needsupdate], 4
xchg  dx, si


dont_mark_line_for_update:
mov   ax, dx
call  HUlib_eraseTextLine_
inc   bx
add   dx, SIZEOF_HUTEXTLINE_T
jmp   loop_hu_erase_next_line


end_erase_loop_erase_last_line:
lodsb ; word ptr ds:[_w_message + HU_STEXT_T.hu_stext_onptr]
mov   byte ptr ds:[_w_message + HU_STEXT_T.hu_stext_laston], al
mov   ax, _w_title
call  HUlib_eraseTextLine_
pop   si
pop   dx
pop   bx
ret   


ENDP



PROC    HU_Ticker_ NEAR
PUBLIC  HU_Ticker_


push  bx
push  cx
push  bp
mov   bp, sp
sub   sp, 0100h

xor   ax, ax

cmp   byte ptr ds:[_message_counter], al
jne   dont_reset_count
dec   byte ptr ds:[_message_counter]
jnz   dont_reset_count

mov   byte ptr ds:[_message_counter], al ; 0
mov   word ptr ds:[_message_on], ax      ; 0
; mov   byte ptr ds:[_message_nottobefuckedwith], al ; 0

dont_reset_count:

cmp   byte ptr ds:[_showMessages], al ; 0
jne   skip_early_exit_check
cmp   byte ptr ds:[_message_dontfuckwithme], al
je    exit_hu_ticker

skip_early_exit_check:

cmp   word ptr ds:[_player + PLAYER_T.player_messagestring], ax ; 0
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


mov   ax, word ptr ds:[_player + PLAYER_T.player_messagestring]
call  HUlib_addMessageToSText_
mov   word ptr ds:[_player + PLAYER_T.player_messagestring], 0
jmp   skip_getting_string

go_get_string:
lea   bx, [bp - 0100h]
mov   cx, ss
push  bx
call  getStringByIndex_

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
ret   





ENDP

PROC    HU_Responder_ NEAR
PUBLIC  HU_Responder_

push  bx
xchg  ax, bx
mov   es, dx
xor   ax, ax
cmp   word ptr es:[bx + EVENT_T.event_data1 + 2], ax
jne   not_rshift
cmp   word ptr es:[bx + EVENT_T.event_data1], KEY_RSHIFT
je    exit_hu_responder
not_rshift:
cmp   word ptr es:[bx + EVENT_T.event_data1 + 2], ax
jne   not_alt
cmp   word ptr es:[bx + EVENT_T.event_data1], KEY_RALT
je    exit_hu_responder
not_alt:
cmp   byte ptr es:[bx + EVENT_T.event_evtype], al   ; EV_KEYDOWN
jne   exit_hu_responder
cmp   word ptr es:[bx + EVENT_T.event_data1 + 2], ax
jne   exit_hu_responder
cmp   word ptr es:[bx + EVENT_T.event_data1], HU_MSGREFRESH
jne   exit_hu_responder
inc   ax
mov   byte ptr ds:[_message_on], al
mov   byte ptr ds:[_message_counter], HU_MSGTIMEOUT
exit_hu_responder:
pop   bx
ret   




ENDP



PROC    HU_STUFF_ENDMARKER_ NEAR
PUBLIC  HU_STUFF_ENDMARKER_
ENDP

END 