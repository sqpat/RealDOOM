;
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

;=================================
.DATA




.CODE

; todo make struct mapping?

DRIVERBLOCK_PLAYMUSIC_OFFSET  = 020h
DRIVERBLOCK_STOPMUSIC_OFFSET  = 024h
DRIVERBLOCK_DRIVERID_OFFSET   = 034h
DRIVERBLOCK_DRIVERDATA_OFFSET = 036h

PROC  SM_LOAD_STARTMARKER_
PUBLIC  SM_LOAD_STARTMARKER_

ENDP

_str_genmidi:
db "genmidi", 0

_songnamelist:
db 0, 0, 0, 0, 0, 0, 0, 0, 0

db "d_e1m1", 0, 0, 0
db "d_e1m2", 0, 0, 0
db "d_e1m3", 0, 0, 0
db "d_e1m4", 0, 0, 0
db "d_e1m5", 0, 0, 0
db "d_e1m6", 0, 0, 0
db "d_e1m7", 0, 0, 0
db "d_e1m8", 0, 0, 0
db "d_e1m9", 0, 0, 0
db "d_e2m1", 0, 0, 0
db "d_e2m2", 0, 0, 0
db "d_e2m3", 0, 0, 0
db "d_e2m4", 0, 0, 0
db "d_e2m5", 0, 0, 0
db "d_e2m6", 0, 0, 0
db "d_e2m7", 0, 0, 0
db "d_e2m8", 0, 0, 0
db "d_e2m9", 0, 0, 0
db "d_e3m1", 0, 0, 0
db "d_e3m2", 0, 0, 0
db "d_e3m3", 0, 0, 0
db "d_e3m4", 0, 0, 0
db "d_e3m5", 0, 0, 0
db "d_e3m6", 0, 0, 0
db "d_e3m7", 0, 0, 0
db "d_e3m8", 0, 0, 0
db "d_e3m9", 0, 0, 0
db "d_inter", 0, 0
db "d_intro", 0, 0
db "d_bunny", 0, 0
db "d_victor", 0
db "d_introa", 0
db "d_runnin", 0
db "d_stalks", 0
db "d_countd", 0
db "d_betwee", 0
db "d_doom", 0, 0, 0
db "d_the_da", 0
db "d_shawn", 0, 0
db "d_ddtblu", 0
db "d_in_cit", 0
db "d_dead", 0, 0, 0
db "d_stlks2", 0
db "d_theda2", 0
db "d_doom2", 0, 0
db "d_ddtbl2", 0
db "d_runni2", 0
db "d_dead2", 0, 0
db "d_stlks3", 0
db "d_romero", 0
db "d_shawn2", 0
db "d_messag", 0
db "d_count2", 0
db "d_ddtbl3", 0
db "d_ampie", 0, 0
db "d_theda3", 0
db "d_adrian", 0
db "d_messg2", 0
db "d_romer2", 0
db "d_tense", 0, 0
db "d_shawn3", 0
db "d_openin", 0
db "d_evil", 0, 0, 0
db "d_ultima", 0
db "d_read_m", 0
db "d_dm2ttl", 0
db "d_dm2int", 0 



PROC F_CopyString9_ NEAR

push  si
push  di
push  cx
push  ax
mov   di, OFFSET _filename_argument

push  ds
pop   es    ; es = ds

push  cs
pop   ds    ; ds = cs

mov   si, ax

mov   ax, 0
stosw       ; zero out
stosw
stosw
stosw
stosb
mov  cx, 9
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

push  ss
pop   ds    ; restore ds

pop   ax
pop   cx
pop   di
pop   si

ret

ENDP

; todo put this somewhere real sigh
PLAYINGDRIVER_LOCATION = 0CC00h


PROC  I_LoadSong_

ENDP

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
push      ax
mov       di, word ptr ds:[_EMS_PAGE] ; music goes in ems page frame 1..
xor       si, si
xor       bx, bx
mov       cx, di
call      dword ptr ds:[_W_CacheLumpNumDirect_addr]
mov       es, di
cmp       word ptr es:[si], 0554Dh        ; MUS FILE HEADER WORD 1
je        good_header
jump_to_return_failure:
jmp       return_failure
good_header:
cmp       word ptr es:[si + 2], 01A53h    ; MUS FILE HEADER WORD 2
jne       jump_to_return_failure

mov       word ptr ds:[_currentsong_ticks_to_process], si
mov       ax, word ptr es:[si + 6]
mov       word ptr ds:[_currentsong_start_offset], ax
mov       word ptr ds:[_currentsong_playing_offset], ax
mov       ax, word ptr ds:[_playingdriver + 2]
mov       bx, word ptr es:[si + 0Ch] ; num instruments
mov       si, word ptr ds:[_playingdriver]
; bx holds onto num instruments
test      ax, ax
jne       valid_driver_do_load
test      si, si
je        jump_to_return_success  ; no driver
valid_driver_do_load:
mov       es, ax
mov       al, byte ptr es:[si + DRIVERBLOCK_DRIVERID_OFFSET] ; driver id offset
cmp       al, MUS_DRIVER_TYPE_OPL2    ; only load instruments from genmidi for opl
je        load_opl_instruments
cmp       al, MUS_DRIVER_TYPE_OPL3
jne       jump_to_return_success
load_opl_instruments:
mov       ax, word ptr ds:[_playingdriver] ; should be 0
xor       dl, dl
mov       es, word ptr ds:[_playingdriver+2] ; todo les


mov       cx, MAX_INSTRUMENTS
mov       al, 0FFh
mov       di, DRIVERBLOCK_DRIVERDATA_OFFSET + (MAX_INSTRUMENTS_PER_TRACK * SIZEOF_OP2INSTRENTRY)

rep       stosb 
loop_next_instrument_lookup:
mov       al, dl
cbw      
cmp       ax, bx
jae       done_loading_instrument_lookups
mov       al, dl
cbw      

add       ax, ax
mov       es, word ptr ds:[_EMS_PAGE]
mov       si, ax
mov       ax, word ptr es:[si + 010h]
cmp       ax, 127
ja        set_percussion_instrument_id
record_instrument_lookup:
mov       si, PLAYINGDRIVER_LOCATION
mov       es, si
mov       si, DRIVERBLOCK_DRIVERDATA_OFFSET + (MAX_INSTRUMENTS_PER_TRACK * SIZEOF_OP2INSTRENTRY)
add       si, ax
mov       byte ptr es:[si], dl
inc       dl
jmp       loop_next_instrument_lookup

jump_to_return_success:
jmp       return_success
set_percussion_instrument_id:
sub       ax, 7
jmp       record_instrument_lookup
done_loading_instrument_lookups:
xor       bx, bx
mov       cx, word ptr ds:[_EMS_PAGE]

mov       ax, OFFSET _str_genmidi - OFFSET SM_LOAD_STARTMARKER_
call      F_CopyString9_
mov       ax, OFFSET _filename_argument

call      dword ptr ds:[_W_CacheLumpNameDirect_addr]
cmp       dh, MAX_INSTRUMENTS
jae       done_with_loading_instruments

mov       ax, PLAYINGDRIVER_LOCATION
mov       es, ax
mov       bx, DRIVERBLOCK_DRIVERDATA_OFFSET + (MAX_INSTRUMENTS_PER_TRACK * SIZEOF_OP2INSTRENTRY)
mov       ds, word ptr ds:[_EMS_PAGE]
xor       dh, dh

loop_load_next_instrument:
mov       al, dh

xor       ah, ah
mov       si, bx    ; get instrument lookup base
add       si, ax
mov       dl, byte ptr es:[si]
cmp       dl, 0FFh
je        inc_loop_load_next_instrument

mov       ah, SIZEOF_OP2INSTRENTRY    
mul       ah
; ax has offset of this instrument (source)
add       ax, 8
xchg      ax, si

mov       al, SIZEOF_OP2INSTRENTRY    
mul       dl
add       ax, DRIVERBLOCK_DRIVERDATA_OFFSET
xchg      ax, di

mov       cx, SIZEOF_OP2INSTRENTRY / 2

rep       movsw 
inc_loop_load_next_instrument:
inc       dh
cmp       dh, MAX_INSTRUMENTS
jb        loop_load_next_instrument

done_with_loading_instruments:
push      ss
pop       ds

xor       bx, bx
mov       cx, word ptr ds:[_EMS_PAGE]
mov       ax, word ptr [bp - 2]
call      dword ptr ds:[_W_CacheLumpNumDirect_addr]
return_success:
mov       ax, 1
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
return_failure:
mov       ax, -1
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf    

PROC  S_ActuallyChangeMusic_
PUBLIC  S_ActuallyChangeMusic_

push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0Ch
mov   al, byte ptr ds:[_pendingmusicenum]
mov   byte ptr [bp - 2], al
mov   byte ptr ds:[_pendingmusicenum], 0
cmp   byte ptr ds:[_snd_MusicDevice], 2
je    check_for_that_one_song_adlib_version
jump_to_not_adlib:
jmp   not_adlib
check_for_that_one_song_adlib_version:
cmp   al, MUS_INTRO
jne   jump_to_not_adlib
mov   byte ptr [bp - 2], MUS_INTROA
continue_loading_song:
mov   al, byte ptr ds:[_mus_playing]
cmp   al, byte ptr [bp - 2]
jne   dont_exit_changesong
jmp   exit_changesong
dont_exit_changesong:
test  al, al
je    dont_stop_song
mov   ax, word ptr ds:[_playingdriver+2]
mov   byte ptr ds:[_playingstate], 1
mov   bx, word ptr ds:[_playingdriver]
test  ax, ax
jne   valid_playdriver
test  bx, bx
je    null_playdriver
valid_playdriver:
mov   es, ax
call  dword ptr es:[bx + DRIVERBLOCK_STOPMUSIC_OFFSET]
null_playdriver:
mov   byte ptr ds:[_mus_playing], 0
dont_stop_song:
mov   al, byte ptr [bp - 2]
mov   ah, 9
mul   ah
add   ax, OFFSET _songnamelist - OFFSET SM_LOAD_STARTMARKER_

call  F_CopyString9_
mov   ax, OFFSET _filename_argument
call  dword ptr ds:[_W_GetNumForName_addr]
call  I_LoadSong_
mov   ax, word ptr ds:[_playingdriver+2]
mov   bx, word ptr ds:[_playingdriver]
test  ax, ax
jne   do_call_playmusic
test  bx, bx
je    dont_call_playmusic    ; null driver
do_call_playmusic:
mov   es, ax
call  dword ptr es:[bx + DRIVERBLOCK_PLAYMUSIC_OFFSET]
dont_call_playmusic:
mov   al, byte ptr [bp - 2]
mov   byte ptr ds:[_loops_enabled], 1
mov   byte ptr ds:[_mus_playing], al
mov   byte ptr ds:[_playingstate], 2
mov   ax, word ptr ds:[_playingdriver+2]
mov   bx, word ptr ds:[_playingdriver]
test  ax, ax
jne   call_stop_music_and_exit
test  bx, bx
jne   call_stop_music_and_exit
exit_changesong:
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
retf  
not_adlib:
mov   al, byte ptr [bp - 2]
test  al, al
je    exit_changesong
cmp   al, NUMMUSIC
jae   exit_changesong
jmp   continue_loading_song
call_stop_music_and_exit:
mov   es, ax
call  dword ptr es:[bx + DRIVERBLOCK_STOPMUSIC_OFFSET]
LEAVE_MACRO
pop   dx
pop   cx
pop   bx
retf  

ENDP

PROC  SM_LOAD_ENDMARKER_
PUBLIC  SM_LOAD_ENDMARKER_

ENDP


END