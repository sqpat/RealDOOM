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





.CODE
 
PROC D_INTERRUPT_STARTMARKER_
PUBLIC D_INTERRUPT_STARTMARKER_
ENDP

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
mov   bx, _playingstate
cmp   byte ptr [bx], ST_PLAYING
jne   jump_to_exit_MUS_serviceroutine
mov   bx, _playingdriver
mov   dx, word ptr [bx + 2]
mov   ax, word ptr [bx]
test  dx, dx 
jne   playingdriver_not_null
test  ax, ax
je    jump_to_exit_MUS_serviceroutine
playingdriver_not_null:
mov   bx, _currentsong_ticks_to_process
inc   word ptr [bx]
service_routine_loop:
mov   bx, _currentsong_ticks_to_process
cmp   word ptr [bx], 0
jl    jump_to_label_5
mov   di, _EMS_PAGE
mov   bx, _currentsong_playing_offset
mov   ax, word ptr [di]
mov   bx, word ptr [bx]
mov   es, ax
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

release_note_routine:
mov   si, _playingdriver
mov   al, byte ptr es:[bx + 1]
mov   bx, _playingdriver
mov   si, word ptr [si]
mov   es, word ptr [bx + 2]
mov   bl, dl
xor   bh, bh
mov   dx, ax
mov   ax, bx
call  dword ptr es:[si + 014h]
label_2:
unused_routine:
mov   si, 2
inc_service_routine_loop:
end_of_measure_routine:
mov   bx, _currentsong_playing_offset
add   word ptr [bx], si
cmp   byte ptr [bp - 6], 0
je    add_increment_to_currentsong_ticks_to_process
read_delay_loop:
mov   bx, _currentsong_playing_offset
mov   si, _EMS_PAGE
mov   bx, word ptr [bx]
mov   es, word ptr [si]
mov   al, byte ptr es:[bx]
shl   cx, 7
mov   ah, al
inc   bx
and   ah, 07Fh
mov   si, _currentsong_playing_offset
add   cl, ah
and   al, 080h
mov   word ptr [si], bx
test  al, al
jne   read_delay_loop
add_increment_to_currentsong_ticks_to_process:
mov   bx, _currentsong_ticks_to_process
sub   word ptr [bx], cx
cmp   byte ptr [bp - 2], 0
jne   loop_song
done_looping_song:
mov   bx, _playingstate
cmp   byte ptr [bx], 1
je    inc_playing_time_and_exit
jmp   service_routine_loop
loop_song:
mov   bx, _currentsong_start_offset
mov   ax, word ptr [bx]
mov   bx, _currentsong_playing_offset
mov   word ptr [bx], ax
jmp   done_looping_song

inc_playing_time_and_exit:
label_5:
mov   bx, _playingtime
add   word ptr [bx], 1
adc   word ptr [bx + 2], 0
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
mov   di, _playingdriver
mov   bx, _playingdriver
cbw  
mov   di, word ptr [di]
mov   es, word ptr [bx + 2]
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
mov   di, _playingdriver
mov   al, byte ptr es:[bx + 1]
mov   bx, _playingdriver
mov   di, word ptr [di]
mov   es, word ptr [bx + 2]
mov   bl, dl
xor   bh, bh
mov   dx, ax
mov   ax, bx
mov   si, 2
call  dword ptr es:[di + 018h]
jmp   inc_service_routine_loop
system_event_routine:
mov   si, _playingdriver
mov   byte ptr [bp - 8], dl
mov   al, byte ptr es:[bx + 1]
mov   bx, _playingdriver
and   al, 07Fh
mov   si, word ptr [si]
mov   byte ptr [bp - 7], ah
mov   dx, ax
mov   es, word ptr [bx + 2]
mov   ax, word ptr [bp - 8]
xor   bx, bx
call  dword ptr es:[si + 01ch]
mov   si, 2
jmp  inc_service_routine_loop
controller_event_routine:
mov   si, _playingdriver
mov   di, _playingdriver
mov   dh, byte ptr es:[bx + 1]
mov   byte ptr [bp - 7], ah
and   dh, 07Fh
mov   bl, byte ptr es:[bx + 2]
mov   si, word ptr [si]
and   bl, 07Fh
mov   byte ptr [bp - 8], dh
mov   al, dl
mov   es, word ptr [di + 2]
mov   dx, word ptr [bp - 8]
xor   bh, bh
call  dword ptr es:[si + 01Ch]
mov   si, 3
jmp   inc_service_routine_loop
finish_song_routine:
mov   bx, _loops_enabled
cmp   byte ptr [bx], 0
je    label_3
mov   byte ptr [bp - 2], 1
jmp   inc_service_routine_loop
label_3:
mov   bx, _playingstate
mov   byte ptr [bx], ST_STOPPED
jmp   inc_service_routine_loop



ENDP

PROC D_INTERRUPT_ENDMARKER_
PUBLIC D_INTERRUPT_ENDMARKER_
ENDP

END
