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

cmp   byte ptr ds:[_playingstate], ST_PLAYING
jne   exit_MUS_serviceroutine
; + 0 is always zero. dx is the only one that is not null if set..
cmp   word ptr ds:[_playingdriver + 2], 0
je    exit_MUS_serviceroutine

; playing driver not null

; some pre-loop setup. si and di will contain these two fields.
mov   si, word ptr ds:[_currentsong_playing_offset]
mov   di, word ptr ds:[_currentsong_ticks_to_process]
inc   di

cmp   di, 0
jl    inc_playing_time_and_exit

service_routine_loop:


mov   es, word ptr ds:[_EMS_PAGE]
lods  word ptr es:[si]
;     ax gets first two bytes...

; ah remains untouched with the 2nd byte.

mov   bx, ax
mov   ch, 0     ; doing_loop
and   bx, 070h ; bits 4, 5, 6 of al
sar   bx, 1
sar   bx, 1
sar   bx, 1    ; shift 4 minus 1 - word lookup
; bx stores event ptr

mov   dl, al
and   dl, 0Fh   ; dl stores channel

and   al, 080h  ; al has last
mov   cl, al    ; store last


jmp   word ptr cs:[bx + _mus_service_routine_jmp_table]
inc_playing_time_and_exit:
; finally write si/di back.
mov   word ptr ds:[_currentsong_playing_offset], si
mov   word ptr ds:[_currentsong_ticks_to_process], di

add   word ptr ds:[_playingtime], 1
adc   word ptr ds:[_playingtime + 2], 0
exit_MUS_serviceroutine:
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  


release_note_routine:
mov   al, ah    ; previously loaded
xchg  ax, dx
mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[014h]

unused_routine:

inc_service_routine_loop:

; if si over MUS_SIZE_PER_PAGE page next page in, sub MUS_SIZE_PER_PAGE...
cmp   si, MUS_SIZE_PER_PAGE
jge   page_in_new_mus_page

done_paging_in_new_mus_page:



cmp   cl, 0 ; cl was last flag
je    skip_delay
xor   dx, dx ; dx gets loop amt
mov   es, word ptr ds:[_EMS_PAGE]
read_delay_loop:
lods  byte ptr es:[si]
mov   cl, 7
shl   dx, cl
mov   ah, al
and   ah, 07Fh
add   dl, ah
and   al, 080h
jne   read_delay_loop

sub   di, dx
skip_delay:
cmp   ch, 0     ; ch is doing_loop var
jne   loop_song
done_looping_song:
cmp   byte ptr ds:[_playingstate], 1
je    inc_playing_time_and_exit
cmp   di, 0
jl    inc_playing_time_and_exit
jmp   service_routine_loop


loop_song:

; move back to page 0
mov   byte ptr ds:[_currentMusPage], 0
xor   ax, ax
cwd     ; dx is 0
call  dword ptr ds:[_Z_QuickMapPageFrame_addr]
; set si to this initial value
mov   si, word ptr ds:[_currentsong_start_offset]

jmp   done_looping_song


page_in_new_mus_page:
inc       byte ptr ds:[_currentMusPage]
xor       ax, ax
mov       dl, byte ptr ds:[_currentMusPage]
; in theory bad things might happen if currentmuspage went beyond 4?
call      dword ptr ds:[_Z_QuickMapPageFrame_addr]
sub       si, MUS_SIZE_PER_PAGE
jmp       done_paging_in_new_mus_page
play_note_routine:
mov   bl, -1  ; lastvolume
test  ah, 080h
je    use_last_volume
lods  byte ptr es:[si]   ; get volume in al
and   al, 07Fh
mov   bl, al

use_last_volume:
; bl has volume
mov   al, dl     ; get channel in al
mov   dl, ah     ; put key/note
and   dl, 07Fh   ; note anded to 127


; channel, key, volume
;  al       dl    bl

mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[010h]

jmp   inc_service_routine_loop
pitch_bend_routine:
mov   al, dl    ; set channel
mov   dl, ah    ; set pitch bend value
mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[018h]
jmp   inc_service_routine_loop

system_event_routine:

mov   al, dl    ; set channel
mov   dl, ah    ; set controller
and   dl, 07Fh
xor   bx, bx    ; zero arg 2

mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[01Ch]

jmp  inc_service_routine_loop

controller_event_routine:

lods  byte ptr es:[si] ; load arg 2
and   al, 07Fh
mov   bl, al    ; arg 2
mov   al, dl    ; get channel
mov   dl, ah    ; arg 1
and   dl, 07Fh


mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[01Ch]
jmp   inc_service_routine_loop

finish_song_routine:

cmp   byte ptr ds:[_loops_enabled], 0
je    no_loop
mov   ch, 1 ; force loop flag on
jmp   inc_service_routine_loop
no_loop:
mov   byte ptr ds:[_playingstate], ST_STOPPED
jmp   inc_service_routine_loop
end_of_measure_routine:
dec   si    ; offset for that lodsw...
jmp   inc_service_routine_loop


ENDP

PROC D_INTERRUPT_ENDMARKER_
PUBLIC D_INTERRUPT_ENDMARKER_
ENDP

END
