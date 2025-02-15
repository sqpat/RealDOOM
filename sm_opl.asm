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


EXTRN _OPL3mode:BYTE
EXTRN _OPLchannels:BYTE
EXTRN _playingtime:DWORD
EXTRN _snd_MusicVolume:BYTE
EXTRN _lastfreechannel:BYTE
EXTRN _playingstate:BYTE
EXTRN _OPL2driverdata:WORD
EXTRN _playingpercussMask:WORD
EXTRN _op_num:WORD
EXTRN _freqtable:WORD
EXTRN _freqtable2:WORD
EXTRN _noteVolumetable:WORD
EXTRN _pitchwheeltable:WORD
EXTRN _OPLsinglevoice:WORD

.CODE

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

DEFAULT_PITCH_BEND  = 080h
CH_FREE             = 080h
CH_SUSTAIN          = 002h
SIZEOF_OP2INSTRENTRY = 024h
MAX_MUSIC_CHANNELS  = 16

ADLIBINSTRUMENTLIST_SEGMENT = 0CC00h
ADLIBCHANNELS_SEGMENT       = 0CC3Fh
INSTRUMENTLOOKUP_SEGMENT    = 0CC51h

SIZE_ADLIBCHANNELS          = 0120h

; donothing
;

PROC  SM_OPL_STARTMARKER_
PUBLIC  SM_OPL_STARTMARKER_

ENDP


	
PROC  donothing_ FAR
PUBLIC  donothing_

retf  

ENDP


PROC  OPLwriteReg_ NEAR
PUBLIC  OPLwriteReg_

push  bx
push  cx
mov   bl, dl
cmp   byte ptr ds:[_OPL3mode], 0
je    do_opl2_writereg
do_opl3_writereg:
mov   dx, ADLIB_PORT
or    ah, ah
je    dont_inc_port_2
inc   dx
inc   dx

dont_inc_port_2:
out   dx, al
in    al, dx
mov   ah, al
inc   dx
mov   al, bl
out   dx, al
mov   al, ah
pop   cx
pop   bx
ret  
do_opl2_writereg:
mov   dx, ADLIB_PORT
out   dx, al
mov   cx, 6
loop_delay_1:
in    al, dx
loop  loop_delay_1
inc   dx
mov   al, bl
out   dx, al
dec   dx
mov   cx, 36     ; delay amount
loop_delay_2:
in    al, dx
loop  loop_delay_2
pop   cx
pop   bx
ret  

ENDP

PROC  OPLwriteChannel_ NEAR
PUBLIC  OPLwriteChannel_


push  si
push  bp
mov   bp, sp
sub   sp, 4
mov   byte ptr [bp - 4], al
mov   byte ptr [bp - 2], bl
xor   bx, bx
cmp   dl, 9
jb    channel_below_9
mov   bx, 0100h
sub   dl, 9
channel_below_9:
xor   dh, dh
mov   si, dx
mov   al, byte ptr ds:[si + _op_num]
xor   ah, ah
mov   dx, ax
mov   al, byte ptr [bp - 4]
add   ax, dx
add   bx, ax
mov   al, byte ptr [bp - 2]
xor   ah, ah
mov   dx, ax
mov   ax, bx
call  OPLwriteReg_
mov   al, cl
xor   ah, ah
add   bx, 3
mov   dx, ax
mov   ax, bx
call  OPLwriteReg_
LEAVE_MACRO 
pop   si
ret



ENDP


PROC  OPLwriteFreq_ NEAR ; todo used only once, inline?
PUBLIC  OPLwriteFreq_


push  bp
mov   bp, sp
sub   sp, 8
mov   byte ptr [bp - 6], al
mov   word ptr [bp - 8], dx
mov   byte ptr [bp - 4], bl
mov   byte ptr [bp - 2], cl
mov   al, byte ptr [bp - 8]
mov   cl, byte ptr [bp - 6]
xor   ah, ah
xor   ch, ch
mov   bx, ax
mov   dx, cx
mov   ax, 0A0h
call  OPLwriteValue_
mov   al, byte ptr [bp - 4]
mov   dx, word ptr [bp - 8]
xor   ah, ah
shr   dx, 8
shl   ax, 2
or    dx, ax
mov   al, byte ptr [bp - 2]
xor   ah, ah
shl   ax, 5
or    ax, dx
xor   ah, ah
mov   dx, cx
mov   bx, ax
mov   ax, 0B0h
call  OPLwriteValue_
LEAVE_MACRO 
ret  


ENDP


PROC  OPLconvertVolume_ NEAR
PUBLIC  OPLconvertVolume_

push  bx
mov   ah, dl
mov   dl, 03Fh
sub   dl, al
mov   al, ah
and   al, 07Fh
cbw  
mov   bx, ax
mov   al, byte ptr ds:[bx + _noteVolumetable]
mov   ah, dl
mul   ah
mov   dx, ax
add   dx, ax
mov   al, 03Fh
sub   al, dh
pop   bx
ret  



ENDP


PROC  OPLpanVolume_ NEAR
PUBLIC  OPLpanVolume_


push  bx
mov   bl, al
mov   al, dl
test  dl, dl
jl    pan_below_0
mov   al, bl
pop   bx
ret
pan_below_0:
cbw  
mov   dx, ax
mov   al, bl
add   dx, 64
cbw  
imul  dx
cwd
shl   dx, 6
sbb   ax, dx
sar   ax, 6      ; / div 64
and   al, 07Fh
pop   bx
ret  

ENDP


PROC  OPLwriteVolume_ NEAR
PUBLIC  OPLwriteVolume_

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   byte ptr [bp - 2], al
mov   di, cx
mov   al, dl
cbw  
mov   es, di
mov   cx, ax
mov   al, byte ptr es:[bx + 0Ch] ; instr->level_2
mov   dx, cx
xor   ah, ah
call  OPLconvertVolume_
mov   es, di
or    al, byte ptr es:[bx + 0Bh] ; instr->scale_2
xor   ah, ah
mov   si, ax
test  byte ptr es:[bx + 6], 1     ; instr->feedback
jne   feedback_zero
mov   al, byte ptr es:[bx + 5]    ; instr->level_1
do_writechannel_call:
mov   es, di
mov   dl, byte ptr es:[bx + 4]    ; instr->scale_1
xor   dh, dh
mov   cx, si
or    ax, dx
mov   dl, byte ptr [bp - 2]
mov   bl, al
mov   ax, 040h
xor   bh, bh
call  OPLwriteChannel_
LEAVE_MACRO 
pop   di
pop   si
ret  

feedback_zero:
mov   dx, cx
mov   al, byte ptr es:[bx + 5]   ;instr->level_1
call  OPLconvertVolume_
cbw  
jmp   do_writechannel_call


ENDP


PROC  OPLwritePan_ FAR
PUBLIC  OPLwritePan_

mov   dh, al
mov   es, cx
cmp   dl, -36
jl    pan_less_than_minus_36
cmp   dl, 36
jle   pan_not_greater_than_36
mov   al, PAN_RIGHT_CHANNEL
pan_capped:
mov   bl, byte ptr es:[bx + 6]
mov   dl, dh
or    bl, al
xor   dh, dh
mov   ax, REGISTER_FEEDBACK
xor   bh, bh

; fallthru
ENDP

PROC  OPLwriteValue_ FAR
PUBLIC  OPLwriteValue_


push  cx
mov   cl, al
mov   al, dl
xor   ah, ah
cmp   dl, 9
jb    dont_add_regnum_lookup_offset
add   ax, (0100h - 9)
dont_add_regnum_lookup_offset:
mov   dl, bl
xor   dh, dh
mov   bx, dx
mov   dl, cl
add   ax, dx
mov   dx, bx
call  OPLwriteReg_
pop   cx
retf  

; part of writepan
pan_less_than_minus_36:
mov   al, PAN_LEFT_CHANNEL
jmp   pan_capped
pan_not_greater_than_36:
mov   al, PAN_BOTH_CHANNELS
jmp   pan_capped
cld   

ENDP

PROC  OPLwriteInstrument_ NEAR
PUBLIC  OPLwriteInstrument_


push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, bx
mov   di, cx
mov   byte ptr [bp - 1], 0
mov   byte ptr [bp - 2], al
mov   cx, 03Fh
mov   dx, word ptr [bp - 2]
mov   ax, REGISTER_VOLUME
mov   bx, cx
call  OPLwriteChannel_
mov   dx, word ptr [bp - 2]
mov   es, di
mov   ax, REGISTER_MODULATOR
mov   cl, byte ptr es:[si + 7]   ; instr->trem_vibr_2
mov   bl, byte ptr es:[si]       ; instr->trem_vibr_1
xor   ch, ch
xor   bh, bh
call  OPLwriteChannel_
mov   dx, word ptr [bp - 2]
mov   es, di
mov   ax, REGISTER_ATTACK
mov   cl, byte ptr es:[si + 8]   ; instr->att_dec_2
mov   bl, byte ptr es:[si + 1]   ; instr->att_dec_1
xor   ch, ch
xor   bh, bh
call  OPLwriteChannel_
mov   dx, word ptr [bp - 2]
mov   es, di
mov   ax, REGISTER_SUSTAIN
mov   cl, byte ptr es:[si + 9]   ; instr->sust_rel_2
mov   bl, byte ptr es:[si + 2]   ; instr->sust_rel_1
xor   ch, ch
xor   bh, bh
call  OPLwriteChannel_
mov   dx, word ptr [bp - 2]
mov   es, di
mov   ax, REGISTER_WAVEFORM
mov   cl, byte ptr es:[si + 0Ah] ; instr->wave_2
mov   bl, byte ptr es:[si + 3]   ; instr->wave_1
xor   ch, ch
xor   bh, bh
call  OPLwriteChannel_
mov   es, di
mov   bl, byte ptr es:[si + 6]   ; instr->feedback
mov   dx, word ptr [bp - 2]
or    bl, 030h
mov   ax, REGISTER_FEEDBACK
xor   bh, bh
call  OPLwriteValue_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret

ENDP

PROC  OPLinit_ NEAR
PUBLIC  OPLinit_

mov   byte ptr ds:[_OPL3mode], dl
test  dl, dl
je    oplinit_opl2      ; todo jne remove jmp
jmp   oplinit_opl3
oplinit_opl2:
mov   byte ptr ds:[_OPLchannels], 9
finish_opl_init:
mov   dx, REGISTER_MODULATOR
mov   ax, 1
call  OPLwriteReg_
mov   dx, REGISTER_VOLUME
mov   ax, 8
call  OPLwriteReg_
mov   ax, 0BDh         ; set vibrato/tremolo depth to low, set melodic mode
xor   dx, dx
call  OPLwriteReg_

; fallthru to oplshutup

ENDP

PROC  OPLshutup_ NEAR
PUBLIC  OPLshutup_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   byte ptr [bp - 2], 0
cmp   byte ptr ds:[_OPLchannels], 0
jbe   exit_opl_shutup
mov   di, 03Fh               ; turn off volume
loop_shutup_next_channel:
mov   al, byte ptr [bp - 2]
mov   cx, di
xor   ah, ah
mov   bx, di
mov   si, ax
mov   dx, ax
mov   ax, REGISTER_VOLUME
call  OPLwriteChannel_
mov   cx, 0FFh               ; the fastest attack, decay
mov   ax, REGISTER_ATTACK
mov   dx, si
mov   bx, cx
call  OPLwriteChannel_
mov   cx, 03Fh               ; ... and release
mov   ax, REGISTER_SUSTAIN
mov   dx, si
mov   bx, cx
call  OPLwriteChannel_
mov   ax, REGISTER_KEY_ON_OFF
mov   dx, si
xor   bx, bx
inc   byte ptr [bp - 2]
call  OPLwriteValue_
mov   al, byte ptr [bp - 2]
cmp   al, byte ptr ds:[_OPLchannels]
jb    loop_shutup_next_channel
exit_opl_shutup:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret 


ENDP

oplinit_opl3:
mov   dx, 1
mov   ax, 0105h      ; enable YMF262/OPL3 mode
mov   byte ptr ds:[_OPLchannels], 012h
call  OPLwriteReg_
mov   ax, 0104h      ; disable 4-operator mode
xor   dx, dx
call  OPLwriteReg_
jmp   finish_opl_init


PROC  OPLdeinit_ FAR
PUBLIC  OPLdeinit_


push  dx
call  OPLshutup_
cmp   byte ptr ds:[_OPL3mode], 0
jne   de_init_opl3
de_init_opl2:
mov   dx, 020h       ; enable Waveform Select
mov   ax, 1
call  OPLwriteReg_
mov   ax, 8          ; turn off CSW mode
xor   dx, dx
call  OPLwriteReg_
mov   ax, 0BDh       ; set vibrato/tremolo depth to low, set melodic mode
xor   dx, dx
call  OPLwriteReg_
pop   dx
retf  
de_init_opl3:
mov   ax, 0105h
xor   dx, dx
call  OPLwriteReg_
mov   ax, 0104h
xor   dx, dx
call  OPLwriteReg_
jmp   de_init_opl2

ENDP

PROC  OPL2detect_ FAR
PUBLIC  OPL2detect_


push  bx
push  cx
push  dx
mov   cx, ax
mov   dx, 060h
mov   ax, 4
call  OPLwriteReg_
mov   dx, 080h
mov   ax, 4
call  OPLwriteReg_
mov   dx, cx
in    al, dx
sub   ah, ah
mov   dx, 0FFh
mov   bh, al
mov   ax, 2
and   bh, 0E0h
call  OPLwriteReg_
mov   dx, 021h
mov   ax, 4
mov   bl, 0FFh
call  OPLwriteReg_
mov   dx, cx
cld   
loop_delay_detect_opl2:
dec   bl
je    done_with_loop_delay_detect_opl2
in    al, dx
sub   ah, ah
jmp   loop_delay_detect_opl2
done_with_loop_delay_detect_opl2:
mov   dx, cx
in    al, dx
sub   ah, ah
mov   dx, 060h
mov   bl, al
mov   ax, 4
call  OPLwriteReg_
mov   dx, 080h
mov   ax, 4
and   bl, 0E0h
call  OPLwriteReg_
test  bh, bh
jne   return_opl2_not_detected
cmp   bl, 0C0h
jne   return_opl2_not_detected
mov   ax, 1
pop   dx
pop   cx
pop   bx
retf  
return_opl2_not_detected:
xor   ax, ax
pop   dx
pop   cx
pop   bx
retf  



ENDP

PROC  OPL3detect_ FAR
PUBLIC  OPL3detect_


push  dx
mov   dx, ax
call  OPL2detect_
test  ax, ax
jne   continue_detecting_opl3
pop   dx
retf  
continue_detecting_opl3:
in    al, dx
sub   ah, ah
test  al, 4

je    return_opl3_detected
xor   ax, ax
pop   dx
retf  
return_opl3_detected:
mov   ax, 1
pop   dx
retf  


ENDP

PROC  OPL2detectHardware_ FAR
PUBLIC  OPL2detectHardware_
call  OPL2detect_
retf
ENDP


PROC  OPL3detectHardware_ FAR
PUBLIC  OPL3detectHardware_
call  OPL3detect_
retf
ENDP

PROC  OPL2deinitHardware_ FAR
PUBLIC  OPL2deinitHardware_
ENDP
PROC  OPL3deinitHardware_ FAR
PUBLIC  OPL3deinitHardware_

call  OPLdeinit_
xor   ax, ax
retf
ENDP


PROC  OPLpauseMusic_ FAR
PUBLIC  OPLpauseMusic_
call  OPLshutup_
ENDP

PROC  OPLresumeMusic_ FAR
PUBLIC  OPLresumeMusic_

retf

ENDP

PROC  writeFrequency_ FAR       ; two inlined writevalues? todo 
PUBLIC  writeFrequency_

;void writeFrequency(uint8_t slot, uint8_t note, uint8_t pitchwheel, uint8_t keyOn){
; al = slot
; dl = note
; bl = pitchwheel
; cl = keyon

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 8
mov   byte ptr [bp - 2], al
mov   bh, bl
mov   byte ptr [bp - 4], cl
cmp   dl, 7
jae   note_greater_than_7
xor   dh, dh
mov   si, dx
add   si, dx
xor   bl, bl
mov   si, word ptr ds:[si + _freqtable]

freq_and_octave_ready:
cmp   bh, DEFAULT_PITCH_BEND
je    skip_pitch_wheel_calculation
mov   al, bh
xor   ah, ah
mov   di, ax
mov   al, byte ptr ds:[di + _pitchwheeltable]
mov   dx, DEFAULT_PITCH_BEND
cbw  
sub   dx, ax
mov   ax, si
mul   dx
mov   word ptr [bp - 6], dx
mov   word ptr [bp - 8], ax
mov   al, byte ptr [bp - 5]
test  al, 080h
je    zero_last_bit
mov   si, 1      ; si holds that one bit...
got_last_bit:
mov   ax, word ptr [bp - 7]
add   ax, ax
add   si, ax
cmp   si, 1024
jb    skip_pitch_wheel_calculation
shr   si, 1
inc   bl
skip_pitch_wheel_calculation:
cmp   bl, 7
jbe   octave_lower_than_7
mov   bl, 7
octave_lower_than_7:
mov   cl, byte ptr [bp - 4]
mov   al, byte ptr [bp - 2]
mov   dx, si
xor   bh, bh
xor   ch, ch
xor   ah, ah
call  OPLwriteFreq_       ; todo only use, inline
LEAVE_MACRO 
pop   di
pop   si
retf  

note_greater_than_7:

xor   dh, dh
mov   ax, dx
mov   dl, 12
sub   ax, 7
div   dl
mov   cx, ax
mov   al, ah
cbw  
mov   si, ax
add   si, ax
mov   bl, cl
mov   si, word ptr ds:[si + _freqtable2]
jmp   freq_and_octave_ready
zero_last_bit:
xor   si, si
jmp   got_last_bit

ENDP

PROC  writeModulation_ FAR
PUBLIC  writeModulation_

push  bp
mov   bp, sp
sub   sp, 2
mov   byte ptr [bp - 2], al
mov   es, cx
test  dl, dl
je    dont_enable_vibrato
mov   dl, 040h       ; frequency vibrato
dont_enable_vibrato:
mov   al, byte ptr es:[bx + 7]   ; instr->trem_vibr_2
or    al, dl
xor   ah, ah
mov   cx, ax
test  byte ptr es:[bx + 6], 1    ; instr->feedback
je    feedback_one
mov   bl, byte ptr es:[bx]
xor   bh, bh
mov   ax, bx
or    al, dl
feedback_checked:
mov   dl, byte ptr [bp - 2]
mov   bl, al
mov   ax, 020h
xor   bh, bh
xor   dh, dh
call  OPLwriteChannel_
LEAVE_MACRO 
retf  
feedback_one:
mov   al, byte ptr es:[bx]   ; instr->trem_vibr_1
jmp   feedback_checked

ENDP



PROC  calcVolumeOPL_ FAR
PUBLIC  calcVolumeOPL_

; dx = system volume
; al = channel volume


mov   ah, bl
shl   dx, 2
mul   ah
mul   dx
mov   bl, ah
mov   bh, dl
mov   dl, 127
mov   ax, bx
div   dl
mov   bx, ax
cmp   al, 07Fh
jbe   already_below_127
mov   al, 07Fh
already_below_127:
retf  


ENDP

CH_SECONDARY = 1
MOD_MIN      = 40
CH_VIBRATO   = 4
PERCUSSION_CHANNEL = 15
FL_FIXED_PITCH = 1


PROC  occupyChannel_ FAR
PUBLIC  occupyChannel_

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Eh
mov   di, word ptr [bp + 0Ah]
mov   byte ptr [bp - 4], al
mov   byte ptr [bp - 2], dl
mov   byte ptr [bp - 6], bl
mov   al, cl
mov   bl, byte ptr [bp - 4]
mov   word ptr [bp - 0Ah], ADLIBCHANNELS_SEGMENT
xor   bh, bh
mov   es, word ptr [bp - 0Ah]
shl   bx, 4
mov   ah, byte ptr [bp - 6]
mov   byte ptr es:[bx], dl
mov   si, bx
mov   byte ptr es:[bx + 1], ah
cmp   byte ptr [bp + 0Eh], 0
jne   set_channel_secondary_flag_on
xor   dx, dx
jmp   set_channel_secondary_flag
set_channel_secondary_flag_on:
mov   dx, CH_SECONDARY
set_channel_secondary_flag:
mov   bl, byte ptr [bp - 2]
mov   es, word ptr [bp - 0Ah]
xor   bh, bh
mov   byte ptr es:[si + 2], dl                              ; ch->flags
cmp   byte ptr ds:[bx + _OPL2driverdata + 060h], MOD_MIN      ; channelModulation
jb    dont_set_vibrato
or    byte ptr es:[si + 2], CH_VIBRATO
dont_set_vibrato:
mov   dx, word ptr ds:[_playingtime]
mov   bx, word ptr ds:[_playingtime + 2]
mov   es, word ptr [bp - 0Ah]
mov   word ptr es:[si + 0Ch], dx
mov   word ptr es:[si + 0Eh], bx

;   if (noteVolume == -1){
;		noteVolume = OPL2driverdata.channelLastVolume[channel];
;	} else{
;		OPL2driverdata.channelLastVolume[channel] = noteVolume;
;	}

cmp   al, -1
je    use_last_volume
mov   bl, byte ptr [bp - 2]
xor   bh, bh
mov   byte ptr ds:[bx + _OPL2driverdata + 020h], al     ; channelLastVolume
jmp   volume_is_set
use_last_volume:
mov   bl, byte ptr [bp - 2]
xor   bh, bh
mov   al, byte ptr ds:[bx + _OPL2driverdata + 020h]     ; channelLastVolume
volume_is_set:
mov   es, word ptr [bp - 0Ah]
mov   bl, byte ptr [bp - 2]
mov   dl, byte ptr ds:[_snd_MusicVolume]
xor   bh, bh
mov   byte ptr es:[si + 6], al
cbw  
xor   dh, dh
mov   cx, ax
mov   al, byte ptr ds:[bx + _OPL2driverdata + 010h]     ; channelVolume
mov   bx, cx
xor   ah, ah
call  calcVolumeOPL_
mov   es, word ptr [bp - 0Ah]
mov   byte ptr es:[si + 7], al
mov   es, word ptr [bp + 0Ch]
test  byte ptr es:[di], FL_FIXED_PITCH
jne   set_note_to_instrument_note
cmp   byte ptr [bp - 2], PERCUSSION_CHANNEL
jne   set_note
mov   byte ptr [bp - 6], 60    ; C-5
jmp   set_note
set_note_to_instrument_note:
mov   al, byte ptr es:[di + 3]
mov   byte ptr [bp - 6], al
set_note:
cmp   byte ptr [bp + 0Eh], 0
jne   lookup_instrument_finetune
use_fixed_pitch:
mov   es, word ptr [bp - 0Ah]
mov   byte ptr es:[si + 5], DEFAULT_PITCH_BEND
jmp   finetune_set
lookup_instrument_finetune:
mov   es, word ptr [bp + 0Ch]
test  byte ptr es:[di], 4
je    use_fixed_pitch
mov   al, byte ptr es:[di + 2]
mov   es, word ptr [bp - 0Ah]
mov   byte ptr es:[si + 5], al
finetune_set:
mov   bl, byte ptr [bp - 2]
xor   bh, bh
mov   al, byte ptr ds:[bx + _OPL2driverdata + 040h]     ; channelpitch
cbw  
mov   es, word ptr [bp - 0Ah]
mov   dx, ax
mov   al, byte ptr es:[si + 5]
cbw  
add   ax, dx
mov   byte ptr es:[si + 4], al
cmp   byte ptr [bp + 0Eh], 0
jne   use_secondary
mov   ax, word ptr [bp + 0Ch]    ; todo commonize this with below
add   di, 4
jmp   instr_set
use_secondary:
mov   ax, word ptr [bp + 0Ch]
add   di, 014h
instr_set:
mov   word ptr [bp - 8], ax
mov   es, word ptr [bp - 0Ah]
mov   ax, word ptr [bp - 8]
mov   word ptr es:[si + 8], di
mov   word ptr es:[si + 0Ah], ax
mov   es, ax
mov   al, byte ptr es:[di + 0Eh]
add   byte ptr [bp - 6], al
and   byte ptr [bp - 6], 07Fh
mov   es, word ptr [bp - 0Ah]
mov   al, byte ptr [bp - 6]
mov   byte ptr [bp - 0Dh], 0
mov   byte ptr es:[si + 3], al
mov   al, byte ptr [bp - 4]
mov   cx, word ptr [bp - 8]
mov   byte ptr [bp - 0Eh], al
mov   bx, di
mov   ax, word ptr [bp - 0Eh]
call  OPLwriteInstrument_
mov   es, word ptr [bp - 0Ah]
test  byte ptr es:[si + 2], CH_VIBRATO
jne   writevibrato
done_with_vibrato:
mov   bl, byte ptr [bp - 2]
mov   dl, byte ptr [bp - 4]
mov   cx, word ptr [bp - 8]
xor   bh, bh
mov   byte ptr [bp - 0Ch], dl
mov   al, byte ptr ds:[bx + _OPL2driverdata + 030h]     ; channelPan
mov   byte ptr [bp - 0Bh], bh
cbw  
mov   bx, di
mov   dx, ax
mov   ax, word ptr [bp - 0Ch]
call  OPLwritePan_
mov   es, word ptr [bp - 0Ah]
mov   al, byte ptr es:[si + 7]
mov   cx, word ptr [bp - 8]
cbw  
mov   bx, di
mov   dx, ax
mov   ax, word ptr [bp - 0Ch]
call  OPLwriteVolume_
mov   es, word ptr [bp - 0Ah]
mov   dl, byte ptr [bp - 6]
mov   cx, 1
mov   ax, word ptr [bp - 0Ch]
mov   bl, byte ptr es:[si + 4]
xor   dh, dh
xor   bh, bh
call  writeFrequency_
mov   al, byte ptr [bp - 4]
LEAVE_MACRO 
pop   di
pop   si
retf  6

writevibrato:
mov   dx, 1
mov   cx, word ptr [bp - 8]
mov   ax, word ptr [bp - 0Eh]
mov   bx, di
call  writeModulation_
jmp   done_with_vibrato


ENDP

PROC  releaseChannel_ FAR
PUBLIC  releaseChannel_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   byte ptr [bp - 2], dl
mov   byte ptr [bp - 3], 0
mov   di, ADLIBCHANNELS_SEGMENT
mov   byte ptr [bp - 4], al
xor   cx, cx
mov   si, word ptr [bp - 4]
mov   es, di
shl   si, 4
mov   ax, word ptr [bp - 4]
mov   bl, byte ptr es:[si + 4]
mov   dl, byte ptr es:[si + 3]
xor   bh, bh
xor   dh, dh
call  writeFrequency_
mov   es, di
mov   byte ptr es:[si + 2], CH_FREE
or    byte ptr es:[si], CH_FREE
cmp   byte ptr [bp - 2], 0
jne   kill_channel
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
retf  
kill_channel:
mov   cx, PERCUSSION_CHANNEL
mov   dx, word ptr [bp - 4]
mov   ax, REGISTER_SUSTAIN
mov   bx, cx
call  OPLwriteChannel_
mov   cx, 03Fh
mov   dx, word ptr [bp - 4]
mov   ax, REGISTER_VOLUME
mov   bx, cx
call  OPLwriteChannel_
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
retf  


ENDP

PROC  releaseSustain_ FAR
PUBLIC  releaseSustain_

push  bx
push  dx
push  si
mov   bh, al
xor   bl, bl
cmp   byte ptr ds:[_OPLchannels], 0
jbe   exit_release_sustain
loop_release_sustain:
mov   al, bl
xor   ah, ah
mov   dx, ax
mov   si, ADLIBCHANNELS_SEGMENT
shl   dx, 4
mov   es, si
mov   si, dx
cmp   bh, byte ptr es:[si]
jne   skip_release_channel
add   si, 2
test  byte ptr es:[si], 2
je    skip_release_channel
xor   dx, dx
call  releaseChannel_
skip_release_channel:
inc   bl
cmp   bl, byte ptr ds:[_OPLchannels]
jb    loop_release_sustain
exit_release_sustain:
pop   si
pop   dx
pop   bx
retf  

ENDP

PROC  findFreeChannel_ FAR
PUBLIC  findFreeChannel_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   byte ptr [bp - 4], al
mov   byte ptr [bp - 2], 0FFh
mov   di, word ptr ds:[_playingtime]
mov   dx, word ptr ds:[_playingtime + 2]
xor   bl, bl
cmp   byte ptr ds:[_OPLchannels], 0
jbe   done_finding_free_channel_loop
mov   cx, ADLIBCHANNELS_SEGMENT
loop_search_for_free_channel:
inc   byte ptr ds:[_lastfreechannel]
mov   al, byte ptr ds:[_lastfreechannel]
cmp   al, byte ptr ds:[_OPLchannels]
jne   dont_zero_free_channel
set_free_channel_to_0:
mov   byte ptr ds:[_lastfreechannel], 0
dont_zero_free_channel:
mov   al, byte ptr ds:[_lastfreechannel]
xor   ah, ah
mov   si, ax
shl   si, 4
mov   es, cx
add   si, 2
test  byte ptr es:[si], CH_FREE
jne   exit_free_channel
inc   bl
cmp   bl, byte ptr ds:[_OPLchannels]
jb    loop_search_for_free_channel
done_finding_free_channel_loop:
test  byte ptr [bp - 4], 1
jne   exit_free_channel_return_not_found
xor   cl, cl
loop_find_free_channel:
mov   al, cl
xor   ah, ah
mov   bx, ax
mov   si, ADLIBCHANNELS_SEGMENT
shl   bx, 4
mov   es, si
lea   si, [bx + 2]
test  byte ptr es:[si], 1
jne   force_release_secondary_channel
mov   ax, word ptr es:[bx + 0Eh]
add   bx, 0Ch
cmp   dx, ax
ja    exit_free_channel_loop
jne   do_next_free_channel_loop
cmp   di, word ptr es:[bx]
jbe   do_next_free_channel_loop
exit_free_channel_loop:
mov   dx, ax
mov   byte ptr [bp - 2], cl
mov   di, word ptr es:[bx]
do_next_free_channel_loop:
inc   cl
cmp   cl, byte ptr ds:[_OPLchannels]
jb    loop_find_free_channel

test  byte ptr [bp - 4], 2
jne   exit_free_channel_return_not_found
mov   al, byte ptr [bp - 2]
cmp   al, 0FFh
jne   force_release_oldest_channel
exit_free_channel_return_not_found:
mov   al, -1

exit_free_channel:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  

force_release_secondary_channel:
mov   dx, -1
call  releaseChannel_
mov   al, cl
jmp   exit_free_channel

force_release_oldest_channel:
mov   dx, -1
xor   ah, ah
call  releaseChannel_
mov   al, byte ptr [bp - 2]  ; todo jmp above
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  

ENDP

PROC  getInstrument_ FAR
PUBLIC  getInstrument_

push  bx
push  cx
mov   bx, 1
mov   cl, al
shl   bx, cl
test  word ptr ds:[_playingpercussMask], bx
je    not_percussion
cmp   dl, 35
jb    return_null_instrument
cmp   dl, 81
ja    return_null_instrument
mov   bl, dl
add   bl, (128 - 35)
look_up_instrument:
mov   ax, INSTRUMENTLOOKUP_SEGMENT
xor   bh, bh
mov   es, ax
mov   al, byte ptr es:[bx]
cmp   al, 0FFh
jne   found_instrument

return_null_instrument:
xor   ax, ax
xor   dx, dx
pop   cx
pop   bx
retf  
not_percussion:
mov   bl, al
xor   bh, bh
mov   bl, byte ptr ds:[bx + _OPL2driverdata + 00h]  ; channelInstr
jmp   look_up_instrument
found_instrument:
xor   ah, ah
mov   dx, ADLIBINSTRUMENTLIST_SEGMENT
imul  ax, ax, SIZEOF_OP2INSTRENTRY
pop   cx
pop   bx
retf  

ENDP

PROC  OPLplayNote_ FAR
PUBLIC  OPLplayNote_

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
mov   byte ptr [bp - 2], al
mov   byte ptr [bp - 4], dl
mov   byte ptr [bp - 6], bl
xor   dh, dh
xor   ah, ah
call  getInstrument_
mov   si, ax
mov   di, dx
test  dx, dx
jne   instr_not_null
test  ax, ax
je    instr_is_null_dont_play
instr_not_null:
cmp   byte ptr [bp - 2], PERCUSSION_CHANNEL
je    channel_is_percussion
channel_not_percussion:
xor   ax, ax
go_find_channel:
xor   ah, ah
call  findFreeChannel_
mov   byte ptr [bp - 0Ah], al
cmp   al, -1
jne   occupy_found_channel
instr_is_null_dont_play:
exit_play_note:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf  
channel_is_percussion:
mov   ax, 2              ; slot for findfreechannel
jmp   go_find_channel
occupy_found_channel:
push  0                      ; todo change..
mov   al, byte ptr [bp - 6]
mov   bl, byte ptr [bp - 4]
mov   dl, byte ptr [bp - 2]
push  di
cbw  
xor   bh, bh
xor   dh, dh
mov   cx, ax
mov   al, byte ptr [bp - 0Ah]
push  si
xor   ah, ah
call  occupyChannel_
cmp   byte ptr ds:[_OPLsinglevoice], 0
jne   exit_play_note
mov   es, di
cmp   word ptr es:[si], 4
jne   exit_play_note
cmp   byte ptr [bp - 2], PERCUSSION_CHANNEL
je    channel_is_percussion_2
channel_not_percussion_2:
mov   ax, 1
go_find_channel_2:
xor   ah, ah
call  findFreeChannel_
mov   byte ptr [bp - 8], al
cmp   al, -1
je    exit_play_note
push  1
mov   al, byte ptr [bp - 6]
mov   bl, byte ptr [bp - 4]
mov   dl, byte ptr [bp - 2]
push  di
cbw  
xor   bh, bh
xor   dh, dh
mov   cx, ax
mov   al, byte ptr [bp - 8]
push  si
xor   ah, ah
call  occupyChannel_
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf  
channel_is_percussion_2:
mov   ax, 3
jmp   go_find_channel_2


ENDP

PROC  OPLreleaseNote_ FAR
PUBLIC  OPLreleaseNote_

push  bx
push  cx
push  si
push  bp
mov   bp, sp
sub   sp, 2
mov   bh, dl
mov   cl, al
xor   ah, ah
mov   si, ax
mov   al, byte ptr [si + _OPL2driverdata + 050h] ; channelSustain
xor   bl, bl
mov   byte ptr [bp - 2], al
cmp   byte ptr ds:[_OPLchannels], 0
jbe   exit_release_note
continue_looping_release_note:
mov   al, bl
xor   ah, ah
mov   dx, ax
mov   si, ADLIBCHANNELS_SEGMENT
shl   dx, 4
mov   es, si
mov   si, dx
cmp   cl, byte ptr es:[si]
jne   loop_check_next_channel_for_release
inc   si
cmp   bh, byte ptr es:[si]
jne   loop_check_next_channel_for_release
cmp   byte ptr [bp - 2], 040h        ; todo whats this mean
jae   add_sustain_flag
xor   dx, dx
call  releaseChannel_
loop_check_next_channel_for_release:
inc   bl
cmp   bl, byte ptr ds:[_OPLchannels]
jb    continue_looping_release_note
exit_release_note:
LEAVE_MACRO 
pop   si
pop   cx
pop   bx
retf  
add_sustain_flag:
mov   si, dx
add   si, 2
or    byte ptr es:[si], CH_SUSTAIN
jmp   loop_check_next_channel_for_release


ENDP

PROC  OPLpitchWheel_ FAR
PUBLIC  OPLpitchWheel_

push  bx
push  cx
push  bp
mov   bp, sp
sub   sp, 8
mov   byte ptr [bp - 2], dl
sub   byte ptr [bp - 2], DEFAULT_PITCH_BEND
mov   bl, al
mov   byte ptr [bp - 6], al
xor   bh, bh
mov   al, byte ptr [bp - 2]
mov   byte ptr [bp - 4], bh
mov   byte ptr [bx + _OPL2driverdata + 040h], al ; channelPitch
cmp   byte ptr ds:[_OPLchannels], 0
jbe   exit_pitchwheel
loop_pitchwheel:
mov   al, byte ptr [bp - 4]
mov   byte ptr [bp - 7], 0
mov   byte ptr [bp - 8], al
mov   bx, word ptr [bp - 8]
mov   ax, ADLIBCHANNELS_SEGMENT
shl   bx, 4
mov   es, ax
mov   al, byte ptr es:[bx]
cmp   al, byte ptr [bp - 6]
je    do_adjust_pitch
check_pitchwheel_loop_for_increment:
inc   byte ptr [bp - 4]
mov   al, byte ptr [bp - 4]
cmp   al, byte ptr ds:[_OPLchannels]
jb    loop_pitchwheel
exit_pitchwheel:
LEAVE_MACRO 
pop   cx
pop   bx
retf  

do_adjust_pitch:
mov   dx, word ptr ds:[_playingtime]
mov   ax, word ptr ds:[_playingtime + 2]
mov   word ptr es:[bx + 0Eh], ax
mov   al, byte ptr es:[bx + 5]
cbw  
mov   word ptr es:[bx + 0Ch], dx
mov   dx, ax
mov   al, byte ptr [bp - 2]
xor   ah, ah
mov   cx, 1
add   ax, dx
mov   dl, byte ptr es:[bx + 3]
mov   byte ptr es:[bx + 4], al
xor   ah, ah
xor   dh, dh
mov   bx, ax
mov   ax, word ptr [bp - 8]
call  writeFrequency_
jmp   check_pitchwheel_loop_for_increment



ENDP


; switch block lookup
change_control_lookup:
dw OFFSET change_control_instrument - OFFSET SM_OPL_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL_STARTMARKER_
dw OFFSET change_control_modulation - OFFSET SM_OPL_STARTMARKER_
dw OFFSET change_control_volume     - OFFSET SM_OPL_STARTMARKER_
dw OFFSET change_control_pan        - OFFSET SM_OPL_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL_STARTMARKER_
dw OFFSET change_control_sustain    - OFFSET SM_OPL_STARTMARKER_


PROC  OPLchangeControl_ FAR
PUBLIC  OPLchangeControl_

push      cx
push      si
push      bp
mov       bp, sp
sub       sp, 0Eh
mov       byte ptr [bp - 0Ah], bl
mov       byte ptr [bp - 2], al
cmp       dl, 8
ja        exit_oplchangecontrol
xor       dh, dh
mov       bx, dx
add       bx, dx
jmp       word ptr cs:[bx + change_control_lookup]
change_control_instrument:
mov       bl, al
xor       bh, bh
mov       al, byte ptr [bp - 0Ah]
mov       byte ptr ds:[bx + _OPL2driverdata + 00h], al  ; channelInstr
; fall thru exit
exit_oplchangecontrol:
LEAVE_MACRO     
pop       si
pop       cx
retf      
change_control_modulation:
mov       bl, al
mov       al, byte ptr [bp - 0Ah]
xor       bh, bh
mov       byte ptr [bp - 4], dh
mov       byte ptr ds:[bx + _OPL2driverdata + 060h], al  ; channelModulation
loop_modulate_next_channel:
mov       al, byte ptr [bp - 4]
xor       ah, ah
mov       dx, ADLIBCHANNELS_SEGMENT
mov       bx, ax
mov       es, dx
shl       bx, 4
mov       dl, byte ptr es:[bx]
cmp       dl, byte ptr [bp - 2]
je        found_channel_id_match_modulate
increment_loop_modulate_next_channel:
inc       byte ptr [bp - 4]
mov       al, byte ptr [bp - 4]
cmp       al, byte ptr ds:[_OPLchannels]
jae       exit_oplchangecontrol
jmp       loop_modulate_next_channel
found_channel_id_match_modulate:
mov       dl, byte ptr es:[bx + 2]
mov       cx, word ptr ds:[_playingtime]
mov       si, word ptr ds:[_playingtime + 2]
mov       word ptr es:[bx + 0Ch], cx
mov       word ptr es:[bx + 0Eh], si
cmp       byte ptr [bp - 0Ah], MOD_MIN
jb        modulate_vibrato_off
modulate_vibrato_on:
or        byte ptr es:[bx + 2], CH_VIBRATO
cmp       dl, byte ptr es:[bx + 2]
je        increment_loop_modulate_next_channel
mov       dx, 1
mov       si, word ptr es:[bx + 8]
mov       cx, word ptr es:[bx + 0Ah]
mov       bx, si
call      writeModulation_
jmp       increment_loop_modulate_next_channel
modulate_vibrato_off:
and       byte ptr es:[bx + 2], (0100h - CH_VIBRATO)   ; NOT CH_VIBRATO 0FBh
cmp       dl, byte ptr es:[bx + 2]
je        increment_loop_modulate_next_channel
mov       cx, word ptr es:[bx + 8]
mov       si, word ptr es:[bx + 0Ah]
xor       dx, dx
mov       bx, cx
mov       cx, si
call      writeModulation_
jmp       increment_loop_modulate_next_channel

change_control_volume:
mov       bl, al
mov       al, byte ptr [bp - 0Ah]
xor       bh, bh
mov       byte ptr [bp - 6], dh
mov       byte ptr [bx + _OPL2driverdata + 010h], al   ; channelVolume
cmp       byte ptr ds:[_OPLchannels], 0
ja        dont_exit
jmp       exit_oplchangecontrol      ; todo make jna
dont_exit:
loop_change_control_volume:
mov       al, byte ptr [bp - 6]
mov       byte ptr [bp - 0Bh], 0
mov       byte ptr [bp - 0Ch], al
mov       cx, ADLIBCHANNELS_SEGMENT
mov       si, word ptr [bp - 0Ch]
mov       es, cx
shl       si, 4
mov       al, byte ptr es:[si]
cmp       al, byte ptr [bp - 2]
je        do_change_control_volume
increment_change_control_volume:
inc       byte ptr [bp - 6]
mov       al, byte ptr [bp - 6]
cmp       al, byte ptr ds:[_OPLchannels]
jb        loop_change_control_volume
jmp       exit_oplchangecontrol
do_change_control_volume:
mov       ax, word ptr ds:[_playingtime]
mov       dx, word ptr ds:[_playingtime + 2]
mov       word ptr es:[si + 0Ch], ax
mov       al, byte ptr es:[si + 6]
mov       word ptr es:[si + 0Eh], dx
cbw      
mov       dl, byte ptr ds:[_snd_MusicVolume]
mov       bx, ax
mov       al, byte ptr [bp - 0Ah]
xor       dh, dh
xor       ah, ah
call      calcVolumeOPL_
mov       es, cx
mov       bx, word ptr es:[si + 8]
mov       byte ptr es:[si + 7], al
cbw      
mov       cx, word ptr es:[si + 0Ah]
mov       dx, ax
mov       ax, word ptr [bp - 0Ch]
call      OPLwriteVolume_
jmp       increment_change_control_volume
change_control_pan:
sub       byte ptr [bp - 0Ah], 64
mov       bl, al
mov       al, byte ptr [bp - 0Ah]
xor       bh, bh
mov       byte ptr [bp - 8], dh
mov       byte ptr [bx + _OPL2driverdata + 030h], al ; channelPan
cmp       byte ptr ds:[_OPLchannels], 0
ja        dont_exit_change_control_pan
jmp       exit_oplchangecontrol
dont_exit_change_control_pan:
loop_change_control_pan:
mov       al, byte ptr [bp - 8]
mov       byte ptr [bp - 0Dh], 0
mov       byte ptr [bp - 0Eh], al
mov       bx, word ptr [bp - 0Eh]
mov       ax, ADLIBCHANNELS_SEGMENT
shl       bx, 4
mov       es, ax
mov       al, byte ptr es:[bx]
cmp       al, byte ptr [bp - 2]
je        do_change_control_pan
increment_change_control_pan_loop:
inc       byte ptr [bp - 8]
mov       al, byte ptr [bp - 8]
cmp       al, byte ptr ds:[_OPLchannels]
jb        loop_change_control_pan
jmp       exit_oplchangecontrol
do_change_control_pan:
mov       ax, word ptr ds:[_playingtime]
mov       dx, word ptr ds:[_playingtime + 2]
mov       si, word ptr es:[bx + 8]
mov       cx, word ptr es:[bx + 0Ah]
mov       word ptr es:[bx + 0Ch], ax
mov       al, byte ptr [bp - 0Ah]
mov       word ptr es:[bx + 0Eh], dx
cbw      
mov       bx, si
mov       dx, ax
mov       ax, word ptr [bp - 0Eh]
call      OPLwritePan_
jmp       increment_change_control_pan_loop
change_control_sustain:
mov       bl, al
xor       bh, bh
mov       al, byte ptr [bp - 0Ah]
mov       byte ptr [bx + _OPL2driverdata + 050h], al   ; channelSustain
cmp       al, 040h       ; todo this value
jae       exit_oplchangecontrol2
mov       ax, bx
call      releaseSustain_
exit_oplchangecontrol2:
LEAVE_MACRO     
pop       si
pop       cx
retf    


ENDP

PROC  OPLplayMusic_ FAR
PUBLIC  OPLplayMusic_


push      bx
xor       al, al
cld       
loop_next_music_channel:
mov       bl, al
xor       bh, bh
mov       byte ptr [bx + _OPL2driverdata + 010h], 07Fh   ; channelVolume
mov       byte ptr [bx + _OPL2driverdata + 020h], bh     ; channelLastVolume
inc       al
mov       byte ptr [bx + _OPL2driverdata + 050h], bh ; channelSustain
cmp       al, MAX_MUSIC_CHANNELS
jb        loop_next_music_channel
pop       bx
retf      


ENDP

PROC  OPLstopMusic_ FAR
PUBLIC  OPLstopMusic_

push      bx
push      dx
push      si
xor       bl, bl
cmp       byte ptr ds:[_OPLchannels], 0
jbe       exit_stop_music
loop_stop_music:
mov       al, bl
xor       ah, ah
mov       si, ax
mov       dx, ADLIBCHANNELS_SEGMENT
shl       si, 4
mov       es, dx
add       si, 2
test      byte ptr es:[si], CH_FREE
jne       increment_loop_stop_music
mov       dx, -1
call      releaseChannel_
increment_loop_stop_music:
inc       bl
cmp       bl, byte ptr ds:[_OPLchannels]
jb        loop_stop_music
exit_stop_music:
pop       si
pop       dx
pop       bx
retf      


ENDP

PROC  OPLchangeSystemVolume_ FAR
PUBLIC  OPLchangeSystemVolume_

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 6
mov       byte ptr [bp - 2], al
mov       byte ptr [bp - 4], 0
cmp       byte ptr ds:[_OPLchannels], 0
jbe       exit_change_system_volume
loop_change_system_volume:
mov       al, byte ptr [bp - 4]
mov       byte ptr [bp - 5], 0
mov       byte ptr [bp - 6], al
mov       cx, ADLIBCHANNELS_SEGMENT
mov       si, word ptr [bp - 6]
mov       es, cx
shl       si, 4
mov       al, byte ptr es:[si + 6]
cbw      
mov       bx, ax
mov       al, byte ptr es:[si]
and       al, 0Fh
mov       di, OFFSET _OPL2driverdata + 010h   ; channelVolume
xor       ah, ah
mov       dl, byte ptr [bp - 2]
add       di, ax
xor       dh, dh
mov       al, byte ptr [di]
call      calcVolumeOPL_
mov       es, cx
mov       byte ptr es:[si + 7], al
cmp       byte ptr ds:[_playingstate], 2
jne       increment_loop_change_system_volume

cbw      
mov       bx, word ptr es:[si + 8]
mov       cx, word ptr es:[si + 0Ah]
mov       dx, ax
mov       ax, word ptr [bp - 6]
call      OPLwriteVolume_
increment_loop_change_system_volume:
inc       byte ptr [bp - 4]
mov       al, byte ptr [bp - 4]
cmp       al, byte ptr ds:[_OPLchannels]
jb        loop_change_system_volume
exit_change_system_volume:
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      




ENDP

PROC  OPLinitDriver_ FAR
PUBLIC  OPLinitDriver_

push      bx
push      cx
push      dx
push      di
mov       cx, SIZE_ADLIBCHANNELS
mov       al, 0FFh
mov       dx, ADLIBCHANNELS_SEGMENT
xor       di, di
mov       es, dx
push      di
mov       ah, al
shr       cx, 1
rep stosw 

pop       di
xor       dl, dl
loop_init_channel:
mov       al, dl
mov       bl, byte ptr ds:[_OPLchannels]
cbw      
xor       bh, bh
cmp       ax, bx
jge       exit_init_opldriver
mov       bx, ADLIBCHANNELS_SEGMENT
shl       ax, 4
mov       es, bx
mov       bx, ax
inc       dl
mov       byte ptr es:[bx + 4], DEFAULT_PITCH_BEND
jmp       loop_init_channel
exit_init_opldriver:
xor       al, al
pop       di
pop       dx
pop       cx
pop       bx
retf      



ENDP

PROC  OPL2initHardware_ FAR
PUBLIC  OPL2initHardware_


xor       dx, dx
call      OPLinit_
xor       al, al
retf    


ENDP

PROC  OPL3initHardware_ FAR
PUBLIC  OPL3initHardware_

mov       dx, 1
call      OPLinit_
xor       al, al
retf    

ENDP

; same for opl2 or 3
PROC  OPLdeinitHardware_ FAR
PUBLIC  OPLdeinitHardware_


call      OPLdeinit_
ENDP

PROC  OPLsendMIDI_ FAR
PUBLIC  OPLsendMIDI_

xor       al, al
retf      

ENDP


PROC  SM_OPL_ENDMARKER_
PUBLIC  SM_OPL_ENDMARKER_

ENDP


END

