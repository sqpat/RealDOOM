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


EXTRN _playingtime:DWORD
EXTRN _playingdriver:DWORD
EXTRN _snd_MusicVolume:BYTE
EXTRN _playingstate:BYTE
EXTRN _SBMIDIport:WORD
EXTRN _MUS2MIDIctrl:BYTE
EXTRN _runningStatus:BYTE

.CODE

ZERO_BYTE MACRO 
    db 0
ENDM


ADLIB_PORT = 0388h

PAN_RIGHT_CHANNEL = 020h
PAN_LEFT_CHANNEL  = 010h
PAN_BOTH_CHANNELS = 030h

REGISTER_VOLUME     = 040h
REGISTER_MODULATOR  = 020h
REGISTER_ATTACK     = 060h
REGISTER_SUSTAIN    = 080h
REGISTER_FEEDBACK   = 0C0h
REGISTER_WAVEFORM   = 0E0h
REGISTER_KEY_ON_OFF = 0B0h



MIDI_NOTE_OFF	 = 080h	; release key,   <note#>, <velocity>
MIDI_NOTE_ON	 = 090h	; press key,     <note#>, <velocity>
MIDI_NOTE_TOUCH	 = 0A0h	; key after-touch, <note#>, <velocity>
MIDI_CONTROL	 = 0B0h	; control change, <controller>, <value>
MIDI_PATCH	     = 0C0h	; patch change,  <patch#>
MIDI_CHAN_TOUCH	 = 0D0h	; channel after-touch (??), <channel#>
MIDI_PITCH_WHEEL = 0E0h	; pitch wheel,   <bottom>, <top 7 bits>
MIDI_EVENT_MASK	 = 0F0h	; value to mask out the event number, not a command!

CTRLPATCH 			= 0
CTRLBANK 			= 1
CTRLMODULATION 		= 2
CTRLVOLUME 			= 3
CTRLPAN 			= 4
CTRLEXPRESSION		= 5
CTRLREVERB			= 6
CTRLCHORUS			= 7
CTRLSUSTAINPEDAL	= 8
CTRLSOFTPEDAL		= 9
CTRLSOUNDSOFF		= 10
CTRLNOTESOFF		= 11
CTRLMONO			= 12
CTRLPOLY			= 13
CTRLRESETCTRLS		= 14

CONTROLLER_DATA_SIZE = 010h

NUM_CONTROLLERS     = 10

DEFAULT_PITCH_BEND   = 080h
CH_FREE              = 080h
CH_SUSTAIN           = 002h
SIZEOF_OP2INSTRENTRY = 024h
MAX_MUSIC_CHANNELS   = 16
OPL3CHANNELS         = 18

PLAYING_PERCUSSION_MASK     = 08000h

MAX_INSTRUMENTS = 175
MAX_INSTRUMENTS_PER_TRACK = 01Ch ; largest in doom1 or doom2


ADLIBINSTRUMENTLIST_SEGMENT = 0CC00h
;ADLIBCHANNELS_SEGMENT       = 0CC3Fh
INSTRUMENTLOOKUP_SEGMENT    = 0CC51h

SIZE_ADLIBCHANNELS          = 0120h

PLAYING_PERCUSSION_MASK     = 08000h

MIDIDRIVERDATA_SEGMENT      = 0CC00h
MIDI_CHANNELS_SEGMENT       = 0CC0Eh
MIDI_PERC                   = 9
MIDITIME_SEGMENT            = 0CC12h

SIZE_MIDICHANNELS           = 010h
SIZE_MIDITIME               = 040h


MIDIDATA_CONTROLLERS_OFFSET = 000h
MIDIDATA_LAST_VOLUME_OFFSET = 0A0h
MIDIDATA_PITCH_WHEEL_OFFSET = 0B0h
MIDIDATA_REALCHANNEL_OFFSET = 0C0h
MIDIDATA_PERCUSSIONS_OFFSET = 0D0h
	
MIDI_READ_POLL	    = 030h
MIDI_READ_IRQ	    = 031h
MIDI_WRITE_POLL     = 038h


PROC  SM_SBMID_STARTMARKER_
PUBLIC  SM_SBMID_STARTMARKER_

ENDP

PROC  calcVolume_   NEAR


shl       ax, 2
xor       dh, dh
mul       dx
mov       al, ah
mov       ah, dl
cmp       ax, 07Fh
jbe       return_vol_as_is
mov       al, 07Fh
return_vol_as_is:
ret  


ENDP

PROC  stopChannel_    NEAR


push      bx
push      cx
push      dx
push      si
mov       cl, al
mov       bx, 07Fh
or        cl, MIDI_CONTROL
mov       dx, 120
xor       ch, ch
mov       si, word ptr [_playingdriver]
mov       ax, cx
call      dword ptr [si + 034h]            ; todo sendmidi
mov       bx, 07Fh
mov       dx, 121
mov       si, word ptr [_playingdriver]   ; todo sendmidi
mov       ax, cx
call      dword ptr [si + 034h]
pop       si
pop       dx
pop       cx
pop       bx
ret      


ENDP

PROC  findFreeMIDIChannel_  NEAR

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 2
mov       byte ptr [bp - 2], al
mov       cl, al
mov       ax, 1
shl       ax, cl
test      ax, PLAYING_PERCUSSION_MASK
jne       return_perc
mov       dx, MIDI_CHANNELS_SEGMENT
xor       al, al
loop_music_channels:
mov       bl, al
mov       es, dx
xor       bh, bh
cmp       byte ptr es:[bx], 0FFh
je        set_found_channel
inc       al
cmp       al, MAX_MUSIC_CHANNELS
jb        loop_music_channels
mov       cx, word ptr [_playingtime]
mov       dx, word ptr [_playingtime + 2]
mov       ah, 0FFh
mov       si, MIDITIME_SEGMENT
xor       al, al
loop_channels_find_oldest:
mov       bl, al
xor       bh, bh
mov       es, si
shl       bx, 2
cmp       dx, word ptr es:[bx + 2]
ja        update_time_oldest
jne       inc_loop_channels_find_oldest
cmp       cx, word ptr es:[bx]
ja        update_time_oldest
inc_loop_channels_find_oldest:
inc       al
cmp       al, MAX_MUSIC_CHANNELS
jae       done_looping_channels_find_oldest
cmp       al, MIDI_PERC
jne       loop_channels_find_oldest
jmp       inc_loop_channels_find_oldest
return_perc:
mov       al, MIDI_PERC
return_found_channel:
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret      
set_found_channel:
mov       ah, byte ptr [bp - 2]
mov       byte ptr es:[bx], ah
jmp       return_found_channel
update_time_oldest:
mov       ah, al
mov       cx, word ptr es:[bx]
mov       dx, word ptr es:[bx + 2]
jmp       inc_loop_channels_find_oldest
done_looping_channels_find_oldest:
mov       dl, ah
cmp       ah, 0FFh
je        dont_stop_channel
mov       di, MIDI_CHANNELS_SEGMENT
mov       bl, ah
mov       es, di
xor       bh, bh
mov       al, byte ptr es:[bx]
xor       ah, ah
mov       cx, MIDIDRIVERDATA_SEGMENT
mov       si, ax
mov       es, cx
mov       ax, bx
mov       byte ptr es:[si + MIDIDATA_REALCHANNEL_OFFSET], 0FFh

call      stopChannel_
mov       es, di
mov       al, byte ptr [bp - 2]
mov       byte ptr es:[bx], al
dont_stop_channel:
mov       al, dl
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret



ENDP

PROC  updateControllers_    NEAR

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4
mov       byte ptr [bp - 2], al
mov       bl, al
mov       ax, MIDIDRIVERDATA_SEGMENT
xor       bh, bh
mov       es, ax
lea       si, [bx + MIDIDATA_REALCHANNEL_OFFSET]
mov       ch, byte ptr es:[si]
test      ch, ch
jge       controller_not_zero
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret      

controller_not_zero:
mov       si, word ptr [_playingdriver]
mov       al, ch
mov       dl, byte ptr es:[bx]
or        al, MIDI_PATCH
xor       dh, dh
xor       bl, bl
xor       ah, ah
mov       cl, 1
call      dword ptr [si + 034h]
mov       al, ch
or        al, MIDI_CONTROL           ; is this right?
mov       byte ptr [bp - 4], al
controller_loop:
mov       al, cl
xor       ah, ah
mov       dx, MIDIDRIVERDATA_SEGMENT
mov       bx, ax
mov       al, byte ptr [bp - 2]
shl       bx, 4
mov       es, dx
add       bx, ax
mov       al, byte ptr es:[bx]
cmp       cl, CTRLVOLUME
jne       not_volume_control
cmp       ch, MIDI_PERC
jne       go_calculate_volume

increment_controller_loop:
inc       cl
cmp       cl, NUM_CONTROLLERS
jb        controller_loop
mov       al, byte ptr [bp - 2]
mov       dx, MIDIDRIVERDATA_SEGMENT
xor       ah, ah
mov       es, dx
mov       bx, ax
mov       dl, byte ptr es:[bx + MIDIDATA_PITCH_WHEEL_OFFSET]       ; pitchWheel

; calculate pitch
mov       al, dl
sar       ax, 1
and       al, 07Fh
ror       dl, 1      ; 1s bit into 080h bit
and       dx, 080h

mov       si, word ptr [_playingdriver]

mov       bl, al
mov       al, ch
xor       dh, dh
or        al, MIDI_PITCH_WHEEL
xor       bh, bh
xor       ah, ah
call      dword ptr [si + 034h]
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret
go_calculate_volume:
mov       dl, al
mov       al, byte ptr [_snd_MusicVolume]
xor       dh, dh
call      calcVolume_
not_volume_control:
mov       bl, al
mov       al, cl
xor       ah, ah
mov       si, word ptr [_playingdriver]
mov       di, ax
xor       bh, bh
mov       dl, byte ptr [di + _MUS2MIDIctrl]
mov       al, byte ptr [bp - 4]

xor       dh, dh
call      dword ptr [si + 034h]
jmp       increment_controller_loop




ENDP

exit_playnote_2:
LEAVE_MACRO     
pop       si
pop       cx
retf      


PROC  MIDIplayNote_    FAR
PUBLIC  MIDIplayNote_

push      cx
push      si
push      bp
mov       bp, sp
sub       sp, 2
mov       ch, al
mov       byte ptr [bp - 2], dl
xor       ah, ah
mov       dx, MIDIDRIVERDATA_SEGMENT
mov       si, ax
mov       es, dx
mov       bh, byte ptr es:[si + MIDIDATA_REALCHANNEL_OFFSET]
cmp       bl, -1
je        use_last_volume
mov       byte ptr es:[si+MIDIDATA_LAST_VOLUME_OFFSET], bl
jmp       got_volume
go_find_channel:
mov       dl, ch
xor       dh, dh
mov       ax, dx
call      findFreeMIDIChannel_
mov       bh, al
test      al, al
jl        exit_playnote_2
mov       si, MIDIDRIVERDATA_SEGMENT
mov       es, si
mov       si, dx
mov       byte ptr es:[si + MIDIDATA_REALCHANNEL_OFFSET], al
mov       ax, dx
call      updateControllers_
jmp       channel_positive

use_last_volume:
mov       bl, byte ptr es:[si+MIDIDATA_LAST_VOLUME_OFFSET]
got_volume:
test      bh, bh
jnge      go_find_channel

channel_positive:
cmp       bh, MIDI_PERC
jne       play_not_percussion
mov       al, byte ptr [bp - 2]
mov       dx, MIDIDRIVERDATA_SEGMENT
xor       ah, ah
mov       es, dx
mov       si, ax
mov       cl, al
mov       al, 1
and       cl, 7
sar       si, 3
shl       al, cl
mov       cl, ch

xor       ch, ch
or        byte ptr es:[si+MIDIDATA_PERCUSSIONS_OFFSET], al
mov       si, cx
mov       dl, byte ptr es:[si + CTRLVOLUME * CONTROLLER_DATA_SIZE]
mov       al, byte ptr [_snd_MusicVolume]
xor       dh, dh


call      calcVolume_
mul       bl
mov       dl, 127
div       dl
mov       bl, al

play_not_percussion:
mov       al, bh
cbw      
mov       si, ax
mov       ax, MIDITIME_SEGMENT
shl       si, 2
mov       es, ax
mov       dx, word ptr [_playingtime]
mov       ax, word ptr [_playingtime + 2]
mov       word ptr es:[si], dx
mov       cl, bh
mov       word ptr es:[si + 2], ax
mov       dl, byte ptr [bp - 2]
mov       si, word ptr [_playingdriver]
mov       al, bl
or        cl, MIDI_NOTE_ON
xor       ah, ah
xor       dh, dh
xor       ch, ch
mov       bx, ax
mov       ax, cx
call      dword ptr [si + 034h]
exit_playnote:
LEAVE_MACRO     
pop       si
pop       cx
retf      


ENDP

PROC  MIDIreleaseNote_    FAR
PUBLIC  MIDIreleaseNote_

push      bx
push      cx
push      si
mov       dh, dl
mov       bx, MIDIDRIVERDATA_SEGMENT
xor       ah, ah
mov       es, bx
mov       bx, ax
mov       dl, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]
test      dl, dl
jl        exit_releasenote
cmp       dl, MIDI_PERC
jne       release_non_percussion
mov       al, dh
mov       cl, dh
mov       bx, ax
and       cl, 7
mov       al, 1
sar       bx, 3
shl       al, cl
not       al
and       byte ptr es:[bx+MIDIDATA_PERCUSSIONS_OFFSET], al
release_non_percussion:
mov       al, dl
cbw      
mov       bx, ax
mov       ax, MIDITIME_SEGMENT
shl       bx, 2
mov       es, ax
mov       ax, word ptr [_playingtime]
mov       cx, word ptr [_playingtime + 2]
mov       word ptr es:[bx], ax
mov       si, word ptr [_playingdriver]
mov       word ptr es:[bx + 2], cx
mov       bx, 127
mov       cl, dh
mov       al, dl
xor       ch, ch
or        al, MIDI_NOTE_OFF
mov       dx, cx
xor       ah, ah
call      dword ptr [si + 034h]
exit_releasenote:
pop       si
pop       cx
pop       bx
retf      


ENDP

PROC  MIDIpitchWheel_    FAR
PUBLIC  MIDIpitchWheel_

push      bx
push      cx
push      si
mov       bl, al
mov       al, dl
xor       bh, bh
mov       dx, MIDIDRIVERDATA_SEGMENT
mov       es, dx
mov       dl, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]
mov       byte ptr es:[bx + MIDIDATA_PITCH_WHEEL_OFFSET], al
test      dl, dl
jl        exit_pitchwheel
mov       bl, al
xor       bh, bh
sar       bx, 1
mov       dh, bl
and       dh, 07Fh
ror       al, 1
xchg      ax, cx
and       cx, 080h       ; cx gets al low bit ? 080h : 000h
mov       al, dl
cbw      
mov       bx, ax
mov       ax, MIDITIME_SEGMENT
shl       bx, 2
mov       es, ax
mov       ax, word ptr [_playingtime]
mov       si, word ptr [_playingtime + 2]
mov       word ptr es:[bx], ax
mov       word ptr es:[bx + 2], si
mov       si, word ptr [_playingdriver]
mov       bl, dh
mov       al, cl
mov       cl, dl
xor       bh, bh
or        cl, MIDI_PITCH_WHEEL
xor       ah, ah
xor       ch, ch
mov       dx, ax
mov       ax, cx
call      dword ptr [si + 034h]
exit_pitchwheel:
pop       si
pop       cx
pop       bx
retf      

ENDP

PROC  MIDIchangeControl_    FAR
PUBLIC  MIDIchangeControl_


push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 2
mov       dh, al
mov       bh, dl
mov       cx, MIDIDRIVERDATA_SEGMENT
xor       ah, ah
mov       es, cx
mov       si, ax
mov       cl, byte ptr es:[si + MIDIDATA_REALCHANNEL_OFFSET]
cmp       dl, NUM_CONTROLLERS
jnb       done_recording_controller_value
record_controller_value:
mov       byte ptr [bp - 2], dl
mov       byte ptr [bp - 1], ah
mov       si, word ptr [bp - 2]
shl       si, 4
add       si, ax
mov       byte ptr es:[si], bl

done_recording_controller_value:
test      cl, cl
jl        exit_changecontrol
mov       al, cl
cbw      
mov       si, ax
mov       ax, MIDITIME_SEGMENT
shl       si, 2
mov       es, ax
mov       di, word ptr [_playingtime]
mov       ax, word ptr [_playingtime + 2]
mov       word ptr es:[si], di
mov       word ptr es:[si + 2], ax
test      bh, bh
je        do_patch_instrument
cmp       bh, CTRLRESETCTRLS
ja        exit_changecontrol
je        do_reset_ctrls
cmp       bh, CTRLVOLUME
jne       do_generic_control
do_volume_control:
cmp       cl, MIDI_PERC
je        exit_changecontrol
mov       dl, bl
mov       al, byte ptr [_snd_MusicVolume]
xor       dh, dh
xor       ah, ah

call      calcVolume_
mov       bl, al
do_generic_control:
mov       si, word ptr [_playingdriver]
mov       al, bl
or        cl, MIDI_CONTROL
mov       bl, bh
xor       ah, ah
xor       bh, bh
xor       ch, ch
mov       dl, byte ptr [bx + _MUS2MIDIctrl]
mov       bx, ax
xor       dh, dh
mov       ax, cx
send_midi_and_exit:
call      dword ptr [si + 034h]
exit_changecontrol:
LEAVE_MACRO     
pop       di
pop       si
pop       cx
retf      

do_patch_instrument:
mov       si, word ptr [_playingdriver]
mov       al, cl
mov       dl, bl
or        al, MIDI_PATCH
xor       dh, dh
xor       bl, bl
xor       ah, ah
jmp       send_midi_and_exit
do_reset_ctrls:
xor       ax, ax
mov       al, dh
mov       si, ax
mov       ax, MIDIDRIVERDATA_SEGMENT
mov       es, ax
xor       ax, ax
mov       byte ptr es:[si + CTRLBANK * CONTROLLER_DATA_SIZE], al
mov       byte ptr es:[si + CTRLMODULATION * CONTROLLER_DATA_SIZE], al
mov       byte ptr es:[si + CTRLPAN * CONTROLLER_DATA_SIZE], 64
mov       byte ptr es:[si + CTRLEXPRESSION * CONTROLLER_DATA_SIZE], 127
mov       byte ptr es:[si + CTRLSUSTAINPEDAL * CONTROLLER_DATA_SIZE], al
mov       byte ptr es:[si + CTRLSOFTPEDAL * CONTROLLER_DATA_SIZE], al
mov       byte ptr es:[si + MIDIDATA_PITCH_WHEEL_OFFSET], DEFAULT_PITCH_BEND
jmp       do_generic_control

ENDP

DUMMY_BASE_CONTROLLER_VALUES:
db 0, 0, 0, 127, 64, 127, 0, 0, 0, 0, 0, DEFAULT_PITCH_BEND, 0FFh

PROC  MIDIplayMusic_    FAR
PUBLIC  MIDIplayMusic_

;    FAR_memset((void __far*) (mididriverData->percussions), 0, sizeof(uint8_t) * (128/8));


push      bx
push      cx
push      dx
push      si
push      di
mov       cx, 010h / 2
mov       di, 0D0h
mov       ax, MIDIDRIVERDATA_SEGMENT
mov       es, ax
xor       ax, ax
rep stosw 
mov       bx, ax  ; zero out
mov       di, ax  ; zero out


push      cs
pop       ds

mov       si, OFFSET DUMMY_BASE_CONTROLLER_VALUES
mov       ah, MAX_MUSIC_CHANNELS

loop_ready_controllers:
lodsb     
mov       cl, ah    ; 16 bytes words
rep       stosb
inc       bl
cmp       bl, NUM_CONTROLLERS + 3    ; 3 controllers, lastvolumes, pitchwheels, realchannels
jl        loop_ready_controllers

; todo make this a 16 byte string in cs and rep movsw over and over

push      ss
pop       ds ; restore ds

mov       bx, 127
mov       ax, MIDI_CONTROL OR MIDI_PERC
mov       dl, 7   ; volume control
mov       si, word ptr [_playingdriver]
xor       dh, dh
call      dword ptr [si + 034h]

mov       ax, MIDI_CONTROL OR MIDI_PERC
mov       si, word ptr [_playingdriver]
mov       dl, 121  ; byte ptr [_MUS2MIDIctrl + e]
xor       bx, bx
xor       dh, dh
call      dword ptr [si + 034h]

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      



ENDP



PROC  MIDIpauseMusic_    FAR
PUBLIC  MIDIpauseMusic_
ENDP
; just calls stop music, fall thru

PROC  MIDIstopMusic_    FAR
PUBLIC  MIDIstopMusic_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 2
mov       byte ptr [bp - 2], 0
mov       di, MIDI_NOTE_OFF OR MIDI_PERC
loop_stop_channels:
mov       al, byte ptr [bp - 2]
mov       dx, MIDIDRIVERDATA_SEGMENT
cbw      
mov       es, dx
mov       bx, ax
mov       al, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]
test      al, al
jl        inc_loop_stop_channels
cmp       al, MIDI_PERC
jne       stop_non_perc_channel
xor       ch, ch
loop_stop_channels_perc:
mov       dl, ch
xor       dh, dh
mov       ax, MIDIDRIVERDATA_SEGMENT
mov       bx, dx
mov       es, ax
sar       bx, 3
mov       cl, ch
add       bx, MIDIDATA_PERCUSSIONS_OFFSET
and       cl, 7
mov       al, byte ptr es:[bx]
mov       bx, 1
xor       ah, ah
shl       bx, cl
test      ax, bx
je        inc_loop_stop_channels_perc
mov       bx, 127
mov       si, word ptr [_playingdriver]
mov       ax, di
call      dword ptr [si + 034h]
inc_loop_stop_channels_perc:
inc       ch
cmp       ch, 128
jb        loop_stop_channels_perc

inc_loop_stop_channels:
inc       byte ptr [bp - 2]
cmp       byte ptr [bp - 2], MAX_MUSIC_CHANNELS
jl        loop_stop_channels
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
stop_non_perc_channel:
xor       ah, ah
call      stopChannel_
jmp       inc_loop_stop_channels


PROC MIDIchangeSystemVolume_  FAR
PUBLIC MIDIchangeSystemVolume_

cmp       byte ptr [_playingstate], 2
je        actually_change_system_volume
retf      

actually_change_system_volume:
xor       ah, ah
push      bx
push      cx
push      dx
push      si
push      bp
mov       bp, sp
sub       sp, 2
mov       byte ptr [bp - 2], al
xor       cl, cl

loop_change_system_volume:
mov       al, cl
mov       dx, MIDIDRIVERDATA_SEGMENT
cbw      
mov       es, dx
mov       bx, ax
mov       ch, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]

test      ch, ch
jl        inc_loop_change_system_volume
cmp       ch, MIDI_PERC
je        inc_loop_change_system_volume
; inlined sendSystemVolume
mov       bx, ax
mov       si, word ptr [_playingdriver]
mov       dl, byte ptr es:[bx + CTRLVOLUME * CONTROLLER_DATA_SIZE]
mov       al, byte ptr [bp - 2]
xor       dh, dh
xor       ah, ah

call      calcVolume_

mov       dl, 7          ; byte ptr [_MUS2MIDIctrl + CTRLVOLUME]
mov       bl, al
mov       al, ch
xor       bh, bh
or        al, MIDI_CONTROL
xor       dh, dh
xor       ah, ah
call      dword ptr [si + 034h]
inc_loop_change_system_volume:
inc       cl
cmp       cl, MAX_MUSIC_CHANNELS
jl        loop_change_system_volume

LEAVE_MACRO     
pop       si
pop       dx
pop       cx
pop       bx
ENDP



PROC  MIDIresumeMusic_    FAR
PUBLIC  MIDIresumeMusic_


retf    

ENDP



PROC  MIDIinitDriver_    FAR
PUBLIC  MIDIinitDriver_

push      cx
push      di
mov       cx, SIZE_MIDICHANNELS / 2
mov       ax, MIDI_CHANNELS_SEGMENT
mov       es, ax
mov       ax, 0FFFFh
xor       di, di
rep       stosw 
mov       di, MIDI_PERC
mov       byte ptr es:[di], 080h    ; mark perc channel occupied
mov       cx, SIZE_MIDITIME / 2
mov       ax, MIDITIME_SEGMENT
mov       es, ax
xor       ax, ax
mov       di, ax
rep       stosw 
pop       di
pop       cx
retf      

ENDP

;;;; END OF GENERIC MIDI STUFF. 
;;;; FOLLOWING IS SBMIDI


ENDP
DSP_READ_DATA     = 0Ah
DSP_WRITE_STATUS  = 0Ch
DSP_WRITE_DATA    = 0Ch
DSP_DATA_AVAIL    = 0Eh

PROC  SBMIDIsendByte_    NEAR
PUBLIC  SBMIDIsendByte_

push      bx
push      dx
mov       bh, al
mov       bl, 0FFh
mov       dx, word ptr [_SBMIDIport]
add       dx, DSP_WRITE_STATUS
xor       ax, ax
loop_wait_dac:
in        al, dx
test      al, 080h
je        sbmidi_ready
dec       bl
jne       loop_wait_dac
jmp       device_timed_out
sbmidi_ready:
; still using same port
mov       al, MIDI_WRITE_POLL
out       dx, al

mov       bl, 0FFh

; use same port still...
loop_wait_dac_2:
in        al, dx
test      al, 080h
je        sbmidi_ready_2
dec       bl
jne       loop_wait_dac_2
device_timed_out:
mov       al, -1
pop       dx
pop       bx
ret

sbmidi_ready_2:
; use same port again...

mov       al, bh ; restore desired write value
out       dx, al
xor       ax, ax
pop       dx
pop       bx
ret  

ENDP


PROC  SBMIDIsendBlock_    NEAR
PUBLIC  SBMIDIsendBlock_

push      bx
mov       bx, ax
mov       byte ptr [_runningStatus], 0
cli       
dec       dx
cmp       dx, -1
jne       finished_sending_bytes
loop_send_next_byte:
mov       al, byte ptr [bx]
inc       bx
call      SBMIDIsendByte_
dec       dx
cmp       dx, -1
je        loop_send_next_byte


finished_sending_bytes:
sti       
xor       ax, ax
pop       bx
ret


ENDP

PROC  SBMIDIsendMIDI_    FAR
PUBLIC  SBMIDIsendMIDI_

mov       dh, dl
mov       dl, al
and       dl, MIDI_EVENT_MASK
cmp       dl, MIDI_NOTE_OFF
jne       not_midi_note_off
and       al, 0Fh
xor       bl, bl
or        al, MIDI_NOTE_ON
not_midi_note_off:
cli       
cmp       al, byte ptr [_runningStatus]
je        runningstatus_is_command
mov       byte ptr [_runningStatus], al
xor       ah, ah
call      SBMIDIsendByte_
runningstatus_is_command:
mov       al, dh
xor       ah, ah
call      SBMIDIsendByte_
cmp       dl, MIDI_PATCH
je        skip_send_byte
cmp       dl, MIDI_CHAN_TOUCH
je        skip_send_byte
xor       bh, bh
mov       ax, bx
call      SBMIDIsendByte_
skip_send_byte:
sti       
xor       al, al
retf

ENDP

PROC  SBMIDIdetectHardware_    FAR
PUBLIC  SBMIDIdetectHardware_

mov       byte ptr [_runningStatus], 0
mov       al, 1
retf      

ENDP

PROC  SBMIDIinitHardware_    FAR
PUBLIC  SBMIDIinitHardware_

mov       word ptr [_SBMIDIport], ax
ENDP

PROC  SBMIDIdeinitHardware_    FAR
PUBLIC  SBMIDIdeinitHardware_

xor       al, al
mov       byte ptr [_runningStatus], al
retf      

ENDP




PROC  SM_SBMID_ENDMARKER_
PUBLIC  SM_SBMID_ENDMARKER_
ENDP



END

