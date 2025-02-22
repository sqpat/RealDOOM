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

MUS_SIZE_PER_PAGE = 16256

EXTRN  Z_QuickMapPageFrame_:PROC


.CODE
 
PROC D_INTERRUPT_STARTMARKER_
PUBLIC D_INTERRUPT_STARTMARKER_
ENDP

;; todo do this locally...
COMMENT @
PROC Z_MapPageFrame_

;   bx is value

push dx
mov  ax, 04400h ; always page 0
mov  dx, _emshandle
mov  
pop  dx
ret

@



_mus_service_routine_jmp_table:
dw OFFSET release_note_routine
dw OFFSET play_note_routine
dw pitch_bend_routine
dw system_event_routine
dw controller_event_routine
dw end_of_measure_routine
dw finish_song_routine
dw unused_routine



PROC MUS_ServiceRoutine_
PUBLIC MUS_ServiceRoutine_


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
cmp   byte ptr ds:[_playingstate], ST_PLAYING
jne   jump_to_exit_MUS_serviceroutine
mov   dx, word ptr ds:[_playingdriver + 2]
mov   ax, word ptr ds:[_playingdriver]
test  dx, dx 
jne   playingdriver_not_null
test  ax, ax
je    jump_to_exit_MUS_serviceroutine
playingdriver_not_null:
inc   word ptr ds:[_currentsong_ticks_to_process]
service_routine_loop:

cmp   word ptr ds:[_currentsong_ticks_to_process], 0
jl    jump_to_label_5
mov   es, word ptr ds:[_EMS_PAGE]
mov   bx, word ptr ds:[_currentsong_playing_offset]
mov   al, byte ptr es:[bx]
mov   si, 1
mov   cl, al
mov   byte ptr [bp - 2], 0
and   cl, 070h
mov   dl, al
xor   ch, ch
and   dl, 0Fh
sar   cx, 4
and   al, 080h
mov   word ptr [bp - 0Ah], cx
mov   byte ptr [bp - 6], al
mov   al, byte ptr [bp - 0Ah]
mov   cx, 0  ; delay_amt
cmp   al, 7
ja    inc_service_routine_loop
xor   ah, ah
mov   di, ax
add   di, ax
jmp   word ptr cs:[di + _mus_service_routine_jmp_table]
jump_to_exit_MUS_serviceroutine:
jmp   exit_MUS_serviceroutine
jump_to_label_5:
jmp   label_5
page_in_new_mus_page:
inc       byte ptr ds:[_currentMusPage]
xor       ax, ax
mov       dl, byte ptr ds:[_currentMusPage]
; in theory bad things might happen if currentmuspage went beyond 4?
call      dword ptr ds:[_Z_QuickMapPageFrame_addr]
sub       bx, MUS_SIZE_PER_PAGE
jmp       done_paging_in_new_mus_page


release_note_routine:
mov   al, byte ptr es:[bx + 1]
les   si, dword ptr ds:[_playingdriver]
mov   bl, dl
xor   bh, bh
mov   dx, ax
mov   ax, bx
call  dword ptr es:[si + 014h]
label_2:
unused_routine:
mov   si, 2
end_of_measure_routine:

inc_service_routine_loop:
mov   bx, word ptr ds:[_currentsong_playing_offset]
add   bx, si

; if bx over MUS_SIZE_PER_PAGE page next page in, sub MUS_SIZE_PER_PAGE...
cmp   bx, MUS_SIZE_PER_PAGE
jge   page_in_new_mus_page

done_paging_in_new_mus_page:
mov       word ptr ds:[_currentsong_playing_offset], bx


cmp   byte ptr [bp - 6], 0
je    add_increment_to_currentsong_ticks_to_process
read_delay_loop:
mov   bx, word ptr ds:[_currentsong_playing_offset]
mov   es, word ptr ds:[_EMS_PAGE]
mov   al, byte ptr es:[bx]
shl   cx, 7
mov   ah, al
inc   bx
and   ah, 07Fh
add   cl, ah
and   al, 080h
mov   word ptr ds:[_currentsong_playing_offset], bx
test  al, al
jne   read_delay_loop
add_increment_to_currentsong_ticks_to_process:
sub   word ptr ds:[_currentsong_ticks_to_process], cx
cmp   byte ptr [bp - 2], 0
jne   loop_song
done_looping_song:
cmp   byte ptr ds:[_playingstate], 1
je    inc_playing_time_and_exit
jmp   service_routine_loop
loop_song:

; move back to page 0
mov   byte ptr ds:[_currentMusPage], 0
xor   ax, ax
cwd
call  dword ptr ds:[_Z_QuickMapPageFrame_addr]

mov   ax, word ptr ds:[_currentsong_start_offset]
mov   word ptr ds:[_currentsong_playing_offset], ax
jmp   done_looping_song

inc_playing_time_and_exit:
label_5:
add   word ptr ds:[_playingtime], 1
adc   word ptr ds:[_playingtime + 2], 0
exit_MUS_serviceroutine:
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
play_note_routine:
mov   ah, byte ptr es:[bx + 1]
mov   al, 0FFh
mov   dh, ah
and   dh, 07Fh
mov   byte ptr [bp - 4], dh
test  ah, 080h
je    use_last_volume
mov   al, byte ptr es:[bx + 2]
mov   si, 2
and   al, 07Fh
use_last_volume:
cbw  
les   di, dword ptr ds:[_playingdriver]
mov   bx, ax
mov   al, byte ptr [bp - 4]
xor   ah, ah
mov   byte ptr [bp - 8], dl
mov   byte ptr [bp - 7], ah
mov   dx, ax
mov   ax, word ptr [bp - 8]
inc   si
call  dword ptr es:[di + 010h]
jmp   inc_service_routine_loop
pitch_bend_routine:
mov   al, byte ptr es:[bx + 1]
les   di, dword ptr ds:[_playingdriver]
mov   bl, dl
xor   bh, bh
mov   dx, ax
mov   ax, bx
mov   si, 2
call  dword ptr es:[di + 018h]
jmp   inc_service_routine_loop
system_event_routine:
mov   byte ptr [bp - 8], dl
mov   al, byte ptr es:[bx + 1]
and   al, 07Fh
mov   byte ptr [bp - 7], ah
mov   dx, ax
les   si, dword ptr ds:[_playingdriver]
mov   ax, word ptr [bp - 8]
xor   bx, bx
call  dword ptr es:[si + 01ch]
mov   si, 2
jmp  inc_service_routine_loop
controller_event_routine:
mov   dh, byte ptr es:[bx + 1]
mov   byte ptr [bp - 7], ah
and   dh, 07Fh
mov   bl, byte ptr es:[bx + 2]
and   bl, 07Fh
mov   byte ptr [bp - 8], dh
mov   al, dl
les   si, dword ptr ds:[_playingdriver]
mov   dx, word ptr [bp - 8]
xor   bh, bh
call  dword ptr es:[si + 01Ch]
mov   si, 3
jmp   inc_service_routine_loop
finish_song_routine:
cmp   byte ptr ds:[_loops_enabled], 0
je    label_3
mov   byte ptr [bp - 2], 1
jmp   inc_service_routine_loop
label_3:
mov   byte ptr ds:[_playingstate], ST_STOPPED
jmp   inc_service_routine_loop



ENDP

PROC D_INTERRUPT_ENDMARKER_
PUBLIC D_INTERRUPT_ENDMARKER_
ENDP

END
