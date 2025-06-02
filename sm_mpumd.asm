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

INCLUDE defs.inc
INSTRUCTION_SET_MACRO

;=================================
.DATA


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


SIZE_ADLIBCHANNELS          = 0120h

PLAYING_PERCUSSION_MASK     = 08000h

MIDI_PERC                   = 9

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


PROC  SM_MPUMD_STARTMARKER_
PUBLIC  SM_MPUMD_STARTMARKER_

ENDP

;; START DRIVERBLOCK

dw	OFFSET 	MIDIinitDriver_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MPU401detectHardware_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MPU401initHardware_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MPU401deinitHardware_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIplayNote_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIreleaseNote_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIpitchWheel_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIchangeControl_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIplayMusic_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIstopMusic_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIpauseMusic_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIresumeMusic_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
dw	OFFSET 	MIDIchangeSystemVolume_MPU401_ - OFFSET SM_MPUMD_STARTMARKER_
dw  0
db	MUS_DRIVER_TYPE_MPU401

;; END DRIVERBLOCK


_mididriverdata:
_mididriverdata_controllers:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlbank:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlmodulation:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlvolume:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlpan:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlexpression:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlreverb:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlchorus:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlsustainpedal:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_controllers_ctrlsoftpedal:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_channelLastVolume:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_pitchWheel:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_realChannels:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
_mididriverdata_percussions:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0



_midichannels:
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

_miditime:
dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

_MUS2MIDIctrl:
db 0FFh, 0, 1, 7, 10, 11, 91, 93, 64, 67, 120, 123, 126, 127, 121

_runningStatus:
db 0

_MPU401port:
dw 0330h

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
mov       ax, cx
call      MPU401sendMIDI_
mov       bx, 07Fh
mov       dx, 121
mov       ax, cx
call      MPU401sendMIDI_
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

xor       al, al
loop_music_channels:
mov       bl, al

xor       bh, bh
cmp       byte ptr cs:[bx + _midichannels - OFFSET SM_MPUMD_STARTMARKER_], 0FFh
je        set_found_channel
inc       al
cmp       al, MAX_MUSIC_CHANNELS
jb        loop_music_channels
mov       cx, word ptr ds:[_playingtime]
mov       dx, word ptr ds:[_playingtime + 2]
mov       ah, 0FFh

xor       al, al
loop_channels_find_oldest:
mov       bl, al
xor       bh, bh

SHIFT_MACRO shl bx 2
cmp       dx, word ptr cs:[bx + 2 + _miditime - OFFSET SM_MPUMD_STARTMARKER_]
ja        update_time_oldest
jne       inc_loop_channels_find_oldest
cmp       cx, word ptr cs:[bx + _miditime - OFFSET SM_MPUMD_STARTMARKER_]
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
mov       byte ptr cs:[bx + _midichannels - OFFSET SM_MPUMD_STARTMARKER_], ah
jmp       return_found_channel
update_time_oldest:
mov       ah, al
mov       cx, word ptr cs:[bx + _miditime - OFFSET SM_MPUMD_STARTMARKER_]
mov       dx, word ptr cs:[bx + 2 + _miditime - OFFSET SM_MPUMD_STARTMARKER_]
jmp       inc_loop_channels_find_oldest
done_looping_channels_find_oldest:
mov       dl, ah
cmp       ah, 0FFh
je        dont_stop_channel
mov       bl, ah
xor       bh, bh
mov       al, byte ptr cs:[bx + _midichannels - OFFSET SM_MPUMD_STARTMARKER_]
xor       ah, ah

mov       si, ax
mov       ax, bx
mov       byte ptr cs:[si + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_], 0FFh

call      stopChannel_
mov       al, byte ptr [bp - 2]
mov       byte ptr cs:[bx + _midichannels - OFFSET SM_MPUMD_STARTMARKER_], al
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
xor       bh, bh

mov       ch, byte ptr cs:[bx + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_]
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
mov       al, ch
mov       dl, byte ptr cs:[bx + _mididriverdata - OFFSET SM_MPUMD_STARTMARKER_]
or        al, MIDI_PATCH
xor       dh, dh
xor       bl, bl
xor       ah, ah
mov       cl, 1
call      MPU401sendMIDI_
mov       al, ch
or        al, MIDI_CONTROL           ; is this right?
mov       byte ptr [bp - 4], al
controller_loop:
mov       al, cl
xor       ah, ah
mov       bx, ax
mov       al, byte ptr [bp - 2]
shl       bx, 4
add       bx, ax
mov       al, byte ptr cs:[bx + _mididriverdata - OFFSET SM_MPUMD_STARTMARKER_]
cmp       cl, CTRLVOLUME
jne       not_volume_control
cmp       ch, MIDI_PERC
jne       go_calculate_volume

increment_controller_loop:
inc       cl
cmp       cl, NUM_CONTROLLERS
jb        controller_loop
mov       al, byte ptr [bp - 2]
xor       ah, ah
mov       bx, ax
mov       dl, byte ptr cs:[bx + _mididriverdata_pitchWheel - OFFSET SM_MPUMD_STARTMARKER_]       ; pitchWheel

; calculate pitch
mov       al, dl
sar       ax, 1
and       al, 07Fh
ror       dl, 1      ; 1s bit into 080h bit
and       dx, 080h


mov       bl, al
mov       al, ch
xor       dh, dh
or        al, MIDI_PITCH_WHEEL
xor       bh, bh
xor       ah, ah
call      MPU401sendMIDI_
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret
go_calculate_volume:
mov       dl, al
mov       al, byte ptr ds:[_snd_MusicVolume]
xor       dh, dh
call      calcVolume_
not_volume_control:
mov       bl, al
mov       al, cl
xor       ah, ah
mov       di, ax
xor       bh, bh
mov       dl, byte ptr cs:[di + _MUS2MIDIctrl - OFFSET SM_MPUMD_STARTMARKER_]
mov       al, byte ptr [bp - 4]

xor       dh, dh
call      MPU401sendMIDI_
jmp       increment_controller_loop




ENDP

exit_playnote_2:
LEAVE_MACRO     
pop       si
pop       cx
retf      


PROC  MIDIplayNote_MPU401_    FAR

push      cx
push      si
push      bp
mov       bp, sp
sub       sp, 2
mov       ch, al
mov       byte ptr [bp - 2], dl
xor       ah, ah

mov       si, ax

mov       bh, byte ptr cs:[si + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_]
cmp       bl, -1
je        use_last_volume
mov       byte ptr cs:[si+_mididriverdata_channelLastVolume - OFFSET SM_MPUMD_STARTMARKER_], bl
jmp       got_volume
go_find_channel:
mov       dl, ch
xor       dh, dh
mov       ax, dx
call      findFreeMIDIChannel_
mov       bh, al
test      al, al
jl        exit_playnote_2
mov       si, dx
mov       byte ptr cs:[si + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_], al
mov       ax, dx
call      updateControllers_
jmp       channel_positive

use_last_volume:
mov       bl, byte ptr cs:[si+_mididriverdata_channelLastVolume - OFFSET SM_MPUMD_STARTMARKER_]
got_volume:
test      bh, bh
jnge      go_find_channel

channel_positive:
cmp       bh, MIDI_PERC
jne       play_not_percussion
mov       al, byte ptr [bp - 2]
xor       ah, ah
mov       si, ax
mov       cl, al
mov       al, 1
and       cl, 7
sar       si, 3
shl       al, cl
mov       cl, ch

xor       ch, ch
or        byte ptr cs:[si+_mididriverdata_percussions - OFFSET SM_MPUMD_STARTMARKER_], al
mov       si, cx
mov       dl, byte ptr cs:[si + _mididriverdata_controllers_ctrlvolume - OFFSET SM_MPUMD_STARTMARKER_]
mov       al, byte ptr ds:[_snd_MusicVolume]
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
shl       si, 2
mov       dx, word ptr ds:[_playingtime]
mov       ax, word ptr ds:[_playingtime + 2]
mov       word ptr cs:[si + _miditime - OFFSET SM_MPUMD_STARTMARKER_], dx
mov       cl, bh
mov       word ptr cs:[si + 2 + _miditime - OFFSET SM_MPUMD_STARTMARKER_], ax
mov       dl, byte ptr [bp - 2]
mov       al, bl
or        cl, MIDI_NOTE_ON
xor       ah, ah
xor       dh, dh
xor       ch, ch
mov       bx, ax
mov       ax, cx
call      MPU401sendMIDI_
exit_playnote:
LEAVE_MACRO     
pop       si
pop       cx
retf      


ENDP

PROC  MIDIreleaseNote_MPU401_    FAR

push      cx
push      si
mov       dh, dl

xor       ah, ah

mov       bx, ax
mov       dl, byte ptr cs:[bx + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_]
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
and       byte ptr cs:[bx+_mididriverdata_percussions - OFFSET SM_MPUMD_STARTMARKER_], al
release_non_percussion:
mov       al, dl
cbw      
mov       bx, ax
shl       bx, 2
mov       ax, word ptr ds:[_playingtime]
mov       cx, word ptr ds:[_playingtime + 2]
mov       word ptr cs:[bx + _miditime - OFFSET SM_MPUMD_STARTMARKER_], ax
mov       word ptr cs:[bx + 2 + _miditime - OFFSET SM_MPUMD_STARTMARKER_], cx
mov       bx, 127
mov       cl, dh
mov       al, dl
xor       ch, ch
or        al, MIDI_NOTE_OFF
mov       dx, cx
xor       ah, ah
call      MPU401sendMIDI_
exit_releasenote:
pop       si
pop       cx
retf      


ENDP

PROC  MIDIpitchWheel_MPU401_    FAR

push      cx
push      si
mov       bl, al
mov       al, dl
xor       bh, bh

mov       dl, byte ptr cs:[bx + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_]
mov       byte ptr cs:[bx + _mididriverdata_pitchWheel - OFFSET SM_MPUMD_STARTMARKER_], al
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
shl       bx, 2
mov       ax, word ptr ds:[_playingtime]
mov       si, word ptr ds:[_playingtime + 2]
mov       word ptr cs:[bx + _miditime - OFFSET SM_MPUMD_STARTMARKER_], ax
mov       word ptr cs:[bx + 2 + _miditime - OFFSET SM_MPUMD_STARTMARKER_], si
mov       bl, dh
mov       al, cl
mov       cl, dl
xor       bh, bh
or        cl, MIDI_PITCH_WHEEL
xor       ah, ah
xor       ch, ch
mov       dx, ax
mov       ax, cx
call      MPU401sendMIDI_
exit_pitchwheel:
pop       si
pop       cx
retf      

ENDP

PROC  MIDIchangeControl_MPU401_    FAR


push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 2
mov       dh, al
mov       bh, dl
xor       ah, ah
mov       si, ax
mov       cl, byte ptr cs:[si + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_]
cmp       dl, NUM_CONTROLLERS
jnb       done_recording_controller_value
record_controller_value:
mov       byte ptr [bp - 2], dl
mov       byte ptr [bp - 1], ah
mov       si, word ptr [bp - 2]
shl       si, 4
add       si, ax
mov       byte ptr cs:[si + _mididriverdata_controllers - OFFSET SM_MPUMD_STARTMARKER_], bl

done_recording_controller_value:
test      cl, cl
jl        exit_changecontrol
mov       al, cl
cbw      
mov       si, ax
shl       si, 2
mov       di, word ptr ds:[_playingtime]
mov       ax, word ptr ds:[_playingtime + 2]
mov       word ptr cs:[si + _miditime - OFFSET SM_MPUMD_STARTMARKER_], di
mov       word ptr cs:[si + 2 + _miditime - OFFSET SM_MPUMD_STARTMARKER_], ax
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
mov       al, byte ptr ds:[_snd_MusicVolume]
xor       dh, dh
xor       ah, ah

call      calcVolume_
mov       bl, al
do_generic_control:
mov       al, bl
or        cl, MIDI_CONTROL
mov       bl, bh
xor       ah, ah
xor       bh, bh
xor       ch, ch
mov       dl, byte ptr cs:[bx + _MUS2MIDIctrl - OFFSET SM_MPUMD_STARTMARKER_]
mov       bx, ax
xor       dh, dh
mov       ax, cx
send_midi_and_exit:
call      MPU401sendMIDI_
exit_changecontrol:
LEAVE_MACRO     
pop       di
pop       si
pop       cx
retf      

do_patch_instrument:
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
xor       ax, ax
mov       byte ptr cs:[si + _mididriverdata_controllers_ctrlbank - OFFSET SM_MPUMD_STARTMARKER_], al
mov       byte ptr cs:[si + _mididriverdata_controllers_ctrlmodulation - OFFSET SM_MPUMD_STARTMARKER_], al
mov       byte ptr cs:[si + _mididriverdata_controllers_ctrlpan - OFFSET SM_MPUMD_STARTMARKER_], 64
mov       byte ptr cs:[si + _mididriverdata_controllers_ctrlexpression - OFFSET SM_MPUMD_STARTMARKER_], 127
mov       byte ptr cs:[si + _mididriverdata_controllers_ctrlsustainpedal - OFFSET SM_MPUMD_STARTMARKER_], al
mov       byte ptr cs:[si + _mididriverdata_controllers_ctrlsoftpedal - OFFSET SM_MPUMD_STARTMARKER_], al
mov       byte ptr cs:[si + _mididriverdata_pitchWheel - OFFSET SM_MPUMD_STARTMARKER_], DEFAULT_PITCH_BEND
jmp       do_generic_control

ENDP

DUMMY_BASE_CONTROLLER_VALUES:
db 0, 0, 0, 127, 64, 127, 0, 0, 0, 0, 0, DEFAULT_PITCH_BEND, 0FFh

PROC  MIDIplayMusic_MPU401_    FAR

;    FAR_memset((void __far*) (mididriverData->percussions), 0, sizeof(uint8_t) * (128/8));


push      bx
push      cx
push      dx
push      si
push      di
mov       cx, 010h / 2
mov       di, OFFSET _mididriverdata_percussions - OFFSET SM_MPUMD_STARTMARKER_
push      cs
pop       es
xor       ax, ax
rep stosw 
mov       bx, ax  ; zero out
mov       di, OFFSET _mididriverdata - OFFSET SM_MPUMD_STARTMARKER_


push      cs
pop       ds

mov       si, OFFSET DUMMY_BASE_CONTROLLER_VALUES - OFFSET SM_MPUMD_STARTMARKER_
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
xor       dh, dh
call      MPU401sendMIDI_

mov       ax, MIDI_CONTROL OR MIDI_PERC
mov       dl, 121  ; byte ptr [_MUS2MIDIctrl + e]
xor       bx, bx
xor       dh, dh
call      MPU401sendMIDI_

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      



ENDP



PROC  MIDIpauseMusic_MPU401_    FAR
ENDP
; just calls stop music, fall thru

PROC  MIDIstopMusic_MPU401_    FAR


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

cbw      

mov       bx, ax
mov       al, byte ptr cs:[bx + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_]
test      al, al
jl        inc_loop_stop_channels
cmp       al, MIDI_PERC
jne       stop_non_perc_channel
xor       ch, ch
loop_stop_channels_perc:
mov       dl, ch
xor       dh, dh

mov       bx, dx

sar       bx, 3
mov       cl, ch
and       cl, 7
mov       al, byte ptr cs:[bx+_mididriverdata_percussions - OFFSET SM_MPUMD_STARTMARKER_]
mov       bx, 1
xor       ah, ah
shl       bx, cl
test      ax, bx
je        inc_loop_stop_channels_perc
mov       bx, 127
mov       ax, di
call      MPU401sendMIDI_
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
ENDP

PROC MIDIchangeSystemVolume_MPU401_  FAR

cmp       byte ptr ds:[_playingstate], 2
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

cbw      
mov       bx, ax
mov       ch, byte ptr cs:[bx + _mididriverdata_realChannels - OFFSET SM_MPUMD_STARTMARKER_]

test      ch, ch
jl        inc_loop_change_system_volume
cmp       ch, MIDI_PERC
je        inc_loop_change_system_volume
; inlined sendSystemVolume
mov       bx, ax
mov       dl, byte ptr cs:[bx + _mididriverdata_controllers_ctrlvolume - OFFSET SM_MPUMD_STARTMARKER_]
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
call      MPU401sendMIDI_
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



PROC  MIDIresumeMusic_MPU401_    FAR


retf    

ENDP



PROC  MIDIinitDriver_MPU401_    FAR

push      cx
push      di
mov       cx, SIZE_MIDICHANNELS / 2
push      cs
pop       es
mov       ax, 0FFFFh
mov       di, OFFSET _midichannels - OFFSET SM_MPUMD_STARTMARKER_
rep       stosw 
mov       byte ptr cs:[MIDI_PERC + _midichannels - OFFSET SM_MPUMD_STARTMARKER_], 080h    ; mark perc channel occupied
mov       cx, SIZE_MIDITIME / 2
xor       ax, ax
; di should already be at this offset!
;mov       di, OFFSET _miditime - OFFSET SM_MPUMD_STARTMARKER_
rep       stosw 
pop       di
pop       cx
retf      

ENDP

;;;; END OF GENERIC MIDI STUFF. 
;;;; FOLLOWING IS MPU MIDI

; MPU401 status codes: (in: port 331h)
MPU401_BUSY	 = 040h	; 1:busy, 0:ready to receive a command
MPU401_EMPTY = 080h	; 1:empty, 0:buffer is full
MPU401_ACK	 = 0FEh	; command acknowledged
MPU401_RESET = 0FFh
MPU401_SET_UART = 03Fh

PROC  MPU401sendByte_   NEAR


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 2
mov   byte ptr [bp - 2], al
mov   bx, word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_]
mov   cx, 10000      ; timeout
inc   bx
mpu_is_not_empty:
mov   dx, bx
in    al, dx
sub   ah, ah
test  al, MPU401_BUSY
je    mpu_is_busy
test  al, MPU401_EMPTY
jne   mpu_is_not_empty
sti   
mov   al, 100
loop_mpu_delay:
dec   al
jne   loop_mpu_delay
mov   dx, word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_]
in    al, dx
sub   ah, ah
dec   cx
jne   mpu_is_not_empty
mov   al, -1
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret
mpu_is_busy:
mov   al, byte ptr [bp - 2]
mov   dx, word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_]
out   dx, al
xor   al, al
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret

ENDP


; unused???
PROC  MPU401sendBlock_    FAR


push  bx
mov   bx, ax
mov   byte ptr cs:[_runningStatus - OFFSET SM_MPUMD_STARTMARKER_], 0
cli   
loop_send_next_mpu_byte:
dec   dx
cmp   dx, -1
jne   do_send_block
sti   
cld   
xor   al, al
pop   bx
retf  
do_send_block:
mov   al, byte ptr [bx]
xor   ah, ah
inc   bx
call  MPU401sendByte_
jmp   loop_send_next_mpu_byte


ENDP


PROC  MPU401reset_    NEAR


mov   ax, MPU401_RESET
mov   byte ptr cs:[_runningStatus - OFFSET SM_MPUMD_STARTMARKER_], 0

call  MPU401sendCommand_
test  al, al
jne   do_second_trial
ret  
do_second_trial:
mov   ax, MPU401_RESET
jmp   MPU401sendCommand_

ENDP


PROC  MPU401sendMIDI_    NEAR


mov   dh, dl
mov   dl, al
and   dl, MIDI_EVENT_MASK
cmp   dl, MIDI_NOTE_OFF
jne   not_midi_note_off_mpu
and   al, 0Fh
xor   bl, bl
or    al, MIDI_NOTE_ON
not_midi_note_off_mpu:
cli   
cmp   al, byte ptr cs:[_runningStatus - OFFSET SM_MPUMD_STARTMARKER_]
je    skip_send_byte_mpu
mov   byte ptr cs:[_runningStatus - OFFSET SM_MPUMD_STARTMARKER_], al
xor   ah, ah

call  MPU401sendByte_
skip_send_byte_mpu:
mov   al, dh
xor   ah, ah

call  MPU401sendByte_
cmp   dl, MIDI_PATCH
je    skip_send_byte_mpu_2
cmp   dl, MIDI_CHAN_TOUCH
je    skip_send_byte_mpu_2
xor   bh, bh
mov   ax, bx

call  MPU401sendByte_
skip_send_byte_mpu_2:
sti   
xor   al, al
ret  

ENDP

PROC  MPU401detectHardware_    FAR

mov   dx, word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_]
mov   word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_], ax

call  MPU401reset_
inc   al
mov   word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_], dx
retf  

ENDP

PROC  MPU401initHardware_    FAR


mov   word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_], ax

call  MPU401reset_
test  al, al
je    set_uart_mode
mov   al, -1
retf  
set_uart_mode:
mov   ax, MPU401_SET_UART
call  MPU401sendCommand_
retf  

ENDP


PROC  MPU401deinitHardware_    FAR
mov   ax, MPU401_RESET
call  MPU401sendCommand_
retf  
ENDP

PROC  MPU401sendCommand_    NEAR

push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 2
mov   byte ptr [bp - 2], al
mov   bx, word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_]
mov   byte ptr cs:[_runningStatus - OFFSET SM_MPUMD_STARTMARKER_], 0
inc   bx
mov   cx, 0FFFFh
mov   dx, bx
loop_sendcommand:
in    al, dx
sub   ah, ah
test  al, MPU401_BUSY
jne   inc_loop_send_command


mov   al, byte ptr [bp - 2]
mov   cx, 0FFFFh   ; timeout
out   dx, al
loop_wait_on_mpu:
mov   dx, bx
in    al, dx
sub   ah, ah
test  al, MPU401_BUSY
je    mpu_is_busy_sendcommand
inc_loop_wait_on_mpu:
dec   cx
jne   loop_wait_on_mpu
mov   al, 0FFh
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret

mpu_is_busy_sendcommand:
mov   dx, word ptr cs:[_MPU401port - OFFSET SM_MPUMD_STARTMARKER_]
in    al, dx
sub   ah, ah
cmp   ax, MPU401_ACK
jne   inc_loop_wait_on_mpu
xor   al, al
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret


inc_loop_send_command:
dec   cx
jne   loop_sendcommand

mov   al, 0FFh
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret

ENDP

PROC  SM_MPUMD_ENDMARKER_
PUBLIC  SM_MPUMD_ENDMARKER_

ENDP

END