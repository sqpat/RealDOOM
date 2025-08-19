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
INSTRUCTION_SET_MACRO_NO_MEDIUM

;=================================



SEGMENT SM_OPL2_TEXT USE16 PARA PUBLIC 'CODE'    
ASSUME  CS:SM_OPL2_TEXT


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

DEFAULT_PITCH_BEND   = 080h
CH_FREE              = 080h
CH_SUSTAIN           = 002h
SIZEOF_OP2INSTRENTRY = 024h
OPL_DRIVER_CHANNELS  = 16
; 0Ah-0ABh unused
; technically 14 now but shifting means faster code...
SIZEOF_ADLIBCHANNEL  = 16
OPL2CHANNELS         = 9



; 120h 
SIZE_ADLIBCHANNELS          = OPL2CHANNELS * SIZEOF_ADLIBCHANNEL

PLAYING_PERCUSSION_MASK     = 08000h

PROC  SM_OPL2_STARTMARKER_
PUBLIC  SM_OPL2_STARTMARKER_

ENDP
;; START DRIVERBLOCK

dw	OFFSET  OPLinitDriver_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPL2detectHardware_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPL2initHardware_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPL2deinitHardware_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLplayNote_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLreleaseNote_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLpitchWheel_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLchangeControl_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLplayMusic_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLstopMusic_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLpauseMusic_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLresumeMusic_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
dw	OFFSET 	OPLchangeSystemVolume_OPL2_ - OFFSET SM_OPL2_STARTMARKER_
dw  0
db	MUS_DRIVER_TYPE_OPL2
db	0

; begin externally accessible driver data

; 1008 bytes sigh
_adlibinstrumentlist:
; 0x24 each, for 0x1C instances
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
dw  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0



_instrumentlookup:
REPT MAX_INSTRUMENTS
    ZERO_BYTE
ENDM

;; END DRIVERBLOCK

_lastfreechannel:
db OPL2CHANNELS - 1


_op_num:
db 000h, 001h, 002h, 008h, 009h, 00Ah, 010h, 011h, 012h


_noteVolumetable:
db	  0,   1,   3,   5,   6,   8,  10,  11
db	 13,  14,  16,  17,  19,  20,  22,  23
db	 25,  26,  27,  29,  30,  32,  33,  34
db	 36,  37,  39,  41,  43,  45,  47,  49
db	 50,  52,  54,  55,  57,  59,  60,  61
db	 63,  64,  66,  67,  68,  69,  71,  72
db	 73,  74,  75,  76,  77,  79,  80,  81
db	 82,  83,  84,  84,  85,  86,  87,  88
db	 89,  90,  91,  92,  92,  93,  94,  95
db	 96,  96,  97,  98,  99,  99, 100, 101
db	101, 102, 103, 103, 104, 105, 105, 106
db	107, 107, 108, 109, 109, 110, 110, 111
db	112, 112, 113, 113, 114, 114, 115, 115
db	116, 117, 117, 118, 118, 119, 119, 120
db	120, 121, 121, 122, 122, 123, 123, 123
db	124, 124, 125, 125, 126, 126, 127, 127

; for low 7 notes
_freqtable:
dw	345, 365, 387, 410, 435, 460, 488
; for the rest.
_freqtable2:
dw	517, 547, 580, 615, 651, 690, 731, 774, 820, 869, 921, 975

; todo compress more?
_pitchwheeltable:
db	14,14,14,14,14,14,14,14,14,14,13,13,13,13,13,13
db	13,13,13,12,12,12,12,12,12,12,12,12,12,11,11,11
db	11,11,11,11,11,11,10,10,10,10,10,10,10,10,10,10
db	9,9,9,9,9,9,9,9,9,8,8,8,8,8,8,8
db	8,8,7,7,7,7,7,7,7,7,7,6,6,6,6,6
db	6,6,6,6,5,5,5,5,5,5,5,5,5,4,4,4
db	4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,2
db	2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1
db	0,0,0,0,0,0,0,0,0,-1,-1,-1,-1,-1,-1,-1
db	-1,-1,-2,-2,-2,-2,-2,-2,-2,-2,-3,-3,-3,-3,-3,-3
db	-3,-3,-3,-4,-4,-4,-4,-4,-4,-4,-4,-5,-5,-5,-5,-5
db	-5,-5,-5,-6,-6,-6,-6,-6,-6,-6,-6,-7,-7,-7,-7,-7
db	-7,-7,-7,-7,-8,-8,-8,-8,-8,-8,-8,-8,-9,-9,-9,-9
db	-9,-9,-9,-9,-10,-10,-10,-10,-10,-10,-10,-10,-11,-11,-11,-11
db	-11,-11,-11,-11,-12,-12,-12,-12,-12,-12,-12,-12,-13,-13,-13,-13
db	-13,-13,-13,-14,-14,-14,-14,-14,-14,-14,-14,-15,-15,-15,-15,-15

_OPL2driverdata:
; channelinstr
db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; channelvolume
db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; channellastvolume
db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; channelpan
db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; channelpitch
db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; channelsustain
db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; channelmodulation
db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


_AdLibChannels:
REPT SIZE_ADLIBCHANNELS
    ZERO_BYTE
ENDM



COMMENT @

; for writing port stuff to file.

_ptr:
dw 0


PROC  logwrite_ NEAR
PUBLIC  logwrite_

push es
push di
push bx
push ax
mov  di, 0DC00h
mov  es, di
mov  di, word ptr cs:[_ptr - OFFSET SM_OPL2_STARTMARKER_]

mov  bx, ax ; backup

;char 4
mov  al, bh
sar  al, 4
and  al, 0Fh
cmp  al, 9
jng   dont_add_extra_4
add  al, 7 ; '0' and 'a' diff minus 10
dont_add_extra_4:
add  al, 030h  ; '0'
stosb

;char 3
mov  al, bh
and  al, 0Fh
cmp  al, 9
jng   dont_add_extra_3
add  al, 7 ; '0' and 'a' diff minus 10
dont_add_extra_3:
add  al, 030h  ; '0'
stosb


;char 2
mov  al, bl
sar  ax, 4
and  al, 0Fh
cmp  al, 9
jng   dont_add_extra_2
add  al, 7 ; '0' and 'a' diff minus 10
dont_add_extra_2:
add  al, 030h  ; '0'
stosb

;char 1
and  al, 0Fh
cmp  al, 9
jng   dont_add_extra_1
add  al, 7 ; '0' and 'a' diff minus 10
dont_add_extra_1:
add  al, 030h  ; '0'
stosb



mov  al, 020h ; space
stosb

;char 6
mov  al, dl
sar  al, 4
and  al, 0Fh
cmp  al, 9
jng   dont_add_extra_6
add  al, 7 ; '0' and 'a' diff minus 10
dont_add_extra_6:
add  al, 030h  ; '0'
stosb


;char 5
mov  al, dl
and  al, 0Fh
cmp  al, 9
jng   dont_add_extra_5
add  al, 7 ; '0' and 'a' diff minus 10
dont_add_extra_5:
add  al, 030h  ; '0'
stosb


mov  al, 0Ah ; newline
stosb

mov  word ptr cs:[_ptr - OFFSET SM_OPL2_STARTMARKER_], di


pop  ax
pop  bx
pop  di
pop  es

ret
ENDP
@


PROC  OPLwriteReg_ NEAR
push  bx
push  cx
mov   bl, dl
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
mov   cl, 36     ; delay amount
loop_delay_2:
in    al, dx
loop  loop_delay_2
pop   cx
pop   bx
ret  

ENDP

;void OPLwriteChannel(uint8_t regbase, uint8_t channel, uint8_t data1, uint8_t data2){


PROC  OPLwriteChannel_ NEAR

;   uint16_t reg = 0;
;    if (channel >= 9){
;        channel -= 9;
;        reg = 0x100;
;    }
;    reg += regbase+op_num[channel];
;    OPLwriteReg(reg, data1);
;    OPLwriteReg(reg+3, data2);

; al gets regbase
; bl gets channel
; dl gets data1
; dh gets data2

xor   ah, ah
mov   bh, ah    ; zero them all...

cmp   bl, 9
jb    channel_below_9
inc   ah    ; add 0x100
sub   bl, 9
channel_below_9:
add   al, byte ptr cs:[bx + _op_num - OFFSET SM_OPL2_STARTMARKER_]
; ax is now reg
; dx is data1/2 still
mov   bl, dh  ; store data2
push  ax
call  OPLwriteReg_
mov   dx, bx  ; retrieve data2
pop   ax
add   al, 3
call  OPLwriteReg_
ret



ENDP




PROC  OPLconvertVolume_ NEAR

push  bx
; al data, ah notevolume
mov   dl, 03Fh
sub   dl, al
mov   al, ah
and   ax, 07Fh
mov   bx, ax
mov   al, byte ptr cs:[bx + _noteVolumetable - OFFSET SM_OPL2_STARTMARKER_]
mul   dl
sal   ax, 1
mov   al, 03Fh
sub   al, ah
pop   bx
ret  



ENDP


;void OPLwriteVolume(uint8_t channel, OPL2instrument __far  *instr, int8_t noteVolume){

PROC  OPLwriteVolume_ NEAR

; al channel 
; dl volume
; bx near ptr
push  cx

mov   ch, al    ; store channel
mov   cl, dl    ; store volume

mov   ah, dl
mov   al, byte ptr cs:[bx + 0Ch] ; instr->level_2
call  OPLconvertVolume_

or    al, byte ptr cs:[bx + 0Bh] ; instr->scale_2
mov   dh, al  ; store data2 in dh


test  byte ptr cs:[bx + 6], 1     ; instr->feedback
jne   feedback_zero
mov   al, byte ptr cs:[bx + 5]    ; instr->level_1
do_writechannel_call:
; dh already set with data2
or    al, byte ptr cs:[bx + 4]    ; instr->scale_1
mov   dl, al    ; data 1 set
mov   bl, ch ; channel
mov   al, 040h
call  OPLwriteChannel_
pop   cx
ret  

feedback_zero:
mov   ah, cl    ; notevolume
mov   cl, dh    ; cache data2
mov   al, byte ptr cs:[bx + 5]   ;instr->level_1
call  OPLconvertVolume_
mov   dh, cl    ; restore data2

jmp   do_writechannel_call


ENDP


PROC  OPLwritePan_ NEAR

; al contains pan
; dl contains channel
; bx contains instr near ptr 

cmp   al, -36
jl    pan_less_than_minus_36
cmp   al, 36
jle   pan_not_greater_than_36
mov   dh, PAN_RIGHT_CHANNEL
pan_capped:
;dh has pan flag.

; dl already has old al
or    dh, byte ptr cs:[bx + 6]
mov   al, REGISTER_FEEDBACK


; fallthru
ENDP

PROC  OPLwriteValue_ NEAR

;    uint16_t regnum = channel;
;    if (channel >= 9){
;        regnum += (0x100 - 9);
;    }
;    OPLwriteReg(regnum + regbase, value);

; ax regbase (ah not necessarily zeroed?)
; dl channel dh value


xor   ah, ah
add   al, dl    ; regnum + regbase
cmp   dl, 9
jb    dont_add_regnum_lookup_offset
add   ax, (0100h - 9)   ; + 0x100 - 9
dont_add_regnum_lookup_offset:

mov   dl, dh
xor   dh, dh
call  OPLwriteReg_

ret

; part of writepan
pan_less_than_minus_36:
mov   dh, PAN_LEFT_CHANNEL
jmp   pan_capped
pan_not_greater_than_36:
mov   dh, PAN_BOTH_CHANNELS
jmp   pan_capped

ENDP

; idea: move init out of driver and into a separate dynamically loaded block so its not ever-present..

PROC  OPL2initHardware_OPL2_ FAR
PUBLIC  OPL2initHardware_OPL2_


mov   dx, REGISTER_MODULATOR
mov   al, 1
call  OPLwriteReg_
mov   dx, REGISTER_VOLUME
mov   al, 8
call  OPLwriteReg_
mov   ax, 0BDh         ; set vibrato/tremolo depth to low, set melodic mode
cwd
call  OPLwriteReg_

call  OPLshutup_
xor   ax, ax
retf

ENDP


PROC  OPLshutup_ NEAR

push  bx
push  dx
push  si
push  di

xor   si, si                   ; channel/loop ctr
mov   di, 03F3Fh               ; turn off volume
loop_shutup_next_channel:

mov   dx, di    ; data 1/2
mov   bx, si                 ; channel
mov   al, REGISTER_VOLUME
call  OPLwriteChannel_
mov   dx, 0FFFFh      ;data 1/2         ; the fastest attack, decay
mov   al, REGISTER_ATTACK
mov   bx, si
call  OPLwriteChannel_
mov   dx, 00F0Fh      ;data 1/2         ; ... and release
mov   al, REGISTER_SUSTAIN
mov   bx, si
call  OPLwriteChannel_
mov   al, REGISTER_KEY_ON_OFF
mov   dx, si
xor   dh, dh        
inc   si
call  OPLwriteValue_
cmp   si, OPL2CHANNELS
jb    loop_shutup_next_channel

exit_opl_shutup:
pop   di
pop   si
pop   dx
pop   bx
ret 


ENDP









PROC  OPL2detectHardware_OPL2_ FAR
PUBLIC  OPL2detectHardware_OPL2_

push  bx
push  cx
push  dx
mov   cx, ax
mov   dx, 060h
mov   al, 4
call  OPLwriteReg_
mov   dx, 080h
mov   al, 4
call  OPLwriteReg_
mov   dx, cx
in    al, dx
sub   ah, ah
mov   dx, 0FFh
mov   bh, al
mov   al, 2
and   bh, 0E0h
call  OPLwriteReg_
mov   dx, 021h
mov   al, 4
mov   bl, 0FFh
call  OPLwriteReg_
mov   dx, cx

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
mov   al, 4
call  OPLwriteReg_
mov   dx, 080h
mov   al, 4
and   bl, 0E0h
call  OPLwriteReg_
test  bh, bh
jne   return_opl2_not_detected
cmp   bl, 0C0h
jne   return_opl2_not_detected
mov   ax, 1
doexitinit:
pop   dx
pop   cx
pop   bx
retf
return_opl2_not_detected:
xor   ax, ax
jmp   doexitinit

ENDP


PROC  OPL2deinitHardware_OPL2_ FAR
PUBLIC  OPL2deinitHardware_OPL2_

push  dx
call  OPLshutup_

de_init_opl2:
mov   dx, 020h       ; enable Waveform Select
mov   ax, 1
call  OPLwriteReg_
mov   ax, 8          ; turn off CSW mode
cwd
call  OPLwriteReg_
mov   ax, 0BDh       ; set vibrato/tremolo depth to low, set melodic mode
cwd
call  OPLwriteReg_
pop   dx
xor   ax, ax
retf




ENDP


PROC  OPLpauseMusic_OPL2_ FAR
PUBLIC  OPLpauseMusic_OPL2_
call  OPLshutup_
ENDP

PROC  OPLresumeMusic_OPL2_ FAR
PUBLIC  OPLresumeMusic_OPL2_

retf

ENDP

PROC  writeFrequency_ NEAR       ; two inlined writevalues? todo 

;void writeFrequency(uint8_t slot, uint8_t note, uint8_t pitchwheel, uint8_t keyOn){
; al = slot
; dl = note
; bl = pitchwheel
; bh = keyon

push  cx
push  si

mov   cl, bh
mov   ch, al    ; ch gets slot

cmp   dl, 7
jae   note_greater_than_7
xor   dh, dh
mov   si, dx
sal   si, 1
xor   bh, bh    ; octave 0
mov   si, word ptr cs:[si + _freqtable - OFFSET SM_OPL2_STARTMARKER_]

freq_and_octave_ready:
; si has freq
; bh has octave.
cmp   bl, DEFAULT_PITCH_BEND
jne    do_pitch_wheel_calculation

done_with_pitch_wheel_calculation:


mov   dx, si


;call  OPLwriteFreq_       ; inlined

;void OPLwriteFreq(uint8_t channel, uint16_t freq, uint8_t octave, uint8_t keyon){
;    OPLwriteValue(0xA0, channel, freq & 0xFF);
;    OPLwriteValue(0xB0, channel, (freq >> 8) | (octave << 2) | (keyon << 5));
; cl has keyon
; ch has channel
; dx has freq 
; bh has octave

SHIFT_MACRO shl cl 5
SHIFT_MACRO shl bh 2
or    bh, cl
or    bh, dh
;  bl has (freq >> 8) | (octave << 2) | (keyon << 5)


mov   dh, dl
mov   dl, ch    ; channel/freq for 1st call
mov   al, 0A0h

call  OPLwriteValue_

mov   dh, bh    ; octave
mov   dl, ch    ; channel
mov   al, 0B0h
call  OPLwriteValue_


pop   si
pop   cx

ret

note_greater_than_7:


mov   al, dl
sub   al, 7
cbw
mov   dl, 12
div   dl

cmp   al, 7
jbe   octave_lower_than_7
mov   al, 7
octave_lower_than_7:
mov   bh, al    ; store octave

mov   al, ah    
cbw  
sal   ax, 1
mov   si, ax
mov   si, word ptr cs:[si + _freqtable2 - OFFSET SM_OPL2_STARTMARKER_]
; si gets freq
jmp   freq_and_octave_ready
do_pitch_wheel_calculation:
mov   al, bl
xor   ah, ah
mov   dx, DEFAULT_PITCH_BEND
xchg  ax, si    ; si gets lookup. ax gets freq.
sub   dl, byte ptr cs:[si + _pitchwheeltable - OFFSET SM_OPL2_STARTMARKER_]



mul   dx    ; product.wu

;		int16_t pitchshiftval = 128 - pitchwheeltable[pitchwheel];
;		product.wu = FastMul16u16u(freq, pitchshiftval);
;		freq = (product.productresult_mid.usemid << 1) + ((product.productresult_mid.throwawaylow & 0x80) ? 1 : 0);

; shift 9 so ..

rcl   ax, 1  ; get carry flag
rcl   dx, 1  ; get carry flag   ; shift 1
mov   al, ah
mov   ah, dl
xchg  ax, si
cmp   si, 1024
jb    done_with_pitch_wheel_calculation
shr   si, 1
inc   bh
jmp   done_with_pitch_wheel_calculation


ENDP

PROC  writeModulation_ NEAR

;void writeModulation(uint8_t slot, OPL2instrument __far  *instr, uint8_t state){
; al slot
; bx instr near ptr
; dl state

; bx is modified

; dl comes with 040h or 0.
dont_enable_vibrato:
mov   dh, byte ptr cs:[bx + 7]   ; instr->trem_vibr_2
or    dh, dl
; dh has data 2

test  byte ptr cs:[bx + 6], 1    ; instr->feedback
je    feedback_one
or    dl, byte ptr cs:[bx]
feedback_checked:
; dl has data 1
mov   bl, al    ; set channel
mov   al, 020h
call  OPLwriteChannel_
ret
feedback_one:
mov   dl, byte ptr cs:[bx]   ; instr->trem_vibr_1
jmp   feedback_checked

ENDP



PROC  calcVolumeOPL_ NEAR

; dx = system volume    ; todo store this preshifted
; al = channel volume
; bl = note volume

; note: bx unmodified

mul   bl
SHIFT_MACRO shl dx 2
mul   dx
mov   al, ah
mov   ah, dl    ; mid 16 bits of result.
mov   dl, 127
div   dl

cmp   al, dl
jnbe  cap_at_127
ret
cap_at_127:
mov   al, dl
ret



ENDP

; todo put in codegen
CH_SECONDARY = 1
MOD_MIN      = 40
CH_VIBRATO   = 4
PERCUSSION_CHANNEL = 15
FL_FIXED_PITCH = 1
FL_DOUBLE_VOICE = 4


PROC  occupyChannel_ NEAR

;uint8_t occupyChannel(uint8_t slot, uint8_t channel,
;	uint8_t note, int8_t noteVolume, OP2instrEntry __far *instrument, uint8_t secondary){

; al slot           
; dh secondary
; bl channel        
; ch note           
; cl notevolume

push  si



cbw   
mov   di, ax
SHIFT_MACRO shl di 4
xor   bh, bh

; dh secondary flag
; bx = channel index 
; di = AdLibChannel ptr
; ch = note
; cl = notevolume

;    ch->channel = channel;
;    ch->note = note;
;    ch->flags = secondary ? CH_SECONDARY : 0;
;   if (OPL2driverdata.channelModulation[channel] >= MOD_MIN){
;		ch->flags |= CH_VIBRATO;
;	}

; write channel
mov   byte ptr cs:[di + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], bl
; write note
mov   byte ptr cs:[di + 1 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], ch
cmp   dh, 0    ; check flag
jne   set_channel_secondary_flag_on
xor   ah, ah
jmp   set_channel_secondary_flag
set_channel_secondary_flag_on:
mov   ah, CH_SECONDARY
set_channel_secondary_flag:

cmp   byte ptr cs:[bx + _OPL2driverdata + 060h - OFFSET SM_OPL2_STARTMARKER_], MOD_MIN      ; channelModulation
jb    dont_set_vibrato
or    ah, CH_VIBRATO
dont_set_vibrato:
mov   byte ptr cs:[di + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], ah                           ; ch->flags

;    ch->time = playingtime;


push  ax    ; temp store slot for les.
les   ax, dword ptr ds:[_playingtime]
mov   word ptr cs:[di + 0Ch + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], ax
mov   word ptr cs:[di + 0Eh + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], es
pop   ax    ; restore

;   if (noteVolume == -1){
;		noteVolume = OPL2driverdata.channelLastVolume[channel];
;	} else{
;		OPL2driverdata.channelLastVolume[channel] = noteVolume;
;	}

; bx still has opldriverdata
; cl has notevolume
; ch has note
; dh has secondary flag
; dl is empty
; ah has channel flags copy
; al has slot

;   if (noteVolume == -1){
;		noteVolume = OPL2driverdata.channelLastVolume[channel];
;	} else{
;		OPL2driverdata.channelLastVolume[channel] = noteVolume;
;	}

cmp   cl, -1
je    use_last_volume
mov   byte ptr cs:[bx + _OPL2driverdata + 020h - OFFSET SM_OPL2_STARTMARKER_], cl     ; channelLastVolume
jmp   volume_is_set
use_last_volume:
mov   cl, byte ptr cs:[bx + _OPL2driverdata + 020h - OFFSET SM_OPL2_STARTMARKER_]     ; channelLastVolume
volume_is_set:

;	ch->noteVolume = noteVolume;
;   ch->realvolume = calcVolumeOPL(OPL2driverdata.channelVolume[channel], snd_MusicVolume, noteVolume);

mov   byte ptr cs:[di + 6 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], cl   ; notevolume

mov   es, ax   ; store slot
mov   al, byte ptr cs:[bx + _OPL2driverdata + 010h - OFFSET SM_OPL2_STARTMARKER_]     ; channelVolume

mov   bh, dh   ; bl has channel, bh gets secondary flag..
xchg  bx, cx   ; get notevolume in bl which will be unmodified

mov   dl, byte ptr ds:[_snd_MusicVolume]
xor   dh, dh

call  calcVolumeOPL_
; record realvolume
mov   byte ptr cs:[di + 7 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], al

; ax/dx free...


; bl has notevolume (no longer used)
; bh has note
; ch has secondary flag
; cl has channel
; es low has slot
; es high has channel flags copy
; si has instr


;	if (instrument->flags & FL_FIXED_PITCH){
;		note = instrument->note;
;	} else if (channel == PERCUSSION){
;		note = 60;			// C-5
;	}


test  byte ptr cs:[si], FL_FIXED_PITCH
jne   set_note_to_instrument_note
cmp   cl, PERCUSSION_CHANNEL
jne   set_note
mov   bh, 60    ; C-5
jmp   set_note
set_note_to_instrument_note:
mov   bh, byte ptr cs:[si + 3]  ; update note

set_note:

;	if (secondary && (instrument->flags & FL_DOUBLE_VOICE)){
;		ch->finetune = instrument->finetune;
;	} else {
;		ch->finetune = DEFAULT_PITCH_BEND;
;	}

cmp   ch, 0    ; check flag again..
jne   lookup_instrument_finetune
use_fixed_pitch:
mov   dh, DEFAULT_PITCH_BEND 
jmp   finetune_set
lookup_instrument_finetune:

test  byte ptr cs:[si], FL_DOUBLE_VOICE
je    use_fixed_pitch
mov   dh, byte ptr cs:[si + 2]
finetune_set:
mov   byte ptr cs:[di + 5 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], dh


mov   bl, cl    ; set channel lookup
mov   dl, bh
xor   bh, bh

; es high has channel flags copy
; es low has slot
; si has instr ptr
; bx channel lookup
; dh is channel finetune (becomes pitchwheel)
; dl has note
; ch has secondary flag 
; cl has channel

;    pitchadder = ch->finetune + OPL2driverdata.channelPitch[channel];
;	 ch->pitchwheel = pitchadder & 0xFF;


add   dh, byte ptr cs:[bx + _OPL2driverdata + 040h - OFFSET SM_OPL2_STARTMARKER_]     ; channelpitch
mov   byte ptr cs:[di + 4 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], dh

;    if (secondary) {
;		instr = &instrument->instr[1];
;	} else { 
;		instr = &instrument->instr[0];
;	}


cmp   ch, 0    ; check secondary
jne   use_secondary

add   si, 4
jmp   instr_set
use_secondary:

add   si, 014h
instr_set:

;    ch->instr = instr;
;	note += instr->basenote;
;	note &= 0x7F;
;    ch->realnote = note;



mov   word ptr cs:[di + 8 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], si
add   dl, byte ptr cs:[si + 0Eh]
and   dl, 07Fh

mov   byte ptr cs:[di + 3 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], dl




; es high has channel flags copy
; es low has slot
; si has instr ptr
; bx channel lookup
; dh is pitchwheel
; dl has note
; ch unused
; cl has channel
; si is instr


;call  OPLwriteInstrument_
; inlined


push  dx    ; cache note/pitchwheel

mov   bx, es
mov   dx, 03F3Fh
mov   al, REGISTER_VOLUME
call  OPLwriteChannel_

mov   bx, es
mov   dh, byte ptr cs:[si + 7]   ; instr->trem_vibr_2
mov   dl, byte ptr cs:[si]       ; instr->trem_vibr_1
mov   al, REGISTER_MODULATOR
call  OPLwriteChannel_

mov   bx, es
mov   dh, byte ptr cs:[si + 8]   ; instr->att_dec_2
mov   dl, byte ptr cs:[si + 1]   ; instr->att_dec_1
mov   al, REGISTER_ATTACK
call  OPLwriteChannel_

mov   bx, es
mov   dh, byte ptr cs:[si + 9]   ; instr->sust_rel_2
mov   dl, byte ptr cs:[si + 2]   ; instr->sust_rel_1
mov   al, REGISTER_SUSTAIN
call  OPLwriteChannel_

mov   bx, es
mov   dh, byte ptr cs:[si + 0Ah] ; instr->wave_2
mov   dl, byte ptr cs:[si + 3]   ; instr->wave_1
mov   al, REGISTER_WAVEFORM
call  OPLwriteChannel_

mov   dx, es
mov   dh, byte ptr cs:[si + 6]   ; instr->feedback
or    dh, 030h
mov   al, REGISTER_FEEDBACK
call  OPLwriteValue_



; es has channel flags copy
; es low  is slot
; stack high has pitchwheel
; stack low has note

; si has instr ptr
; dh is pitchwheel
; dl has note
; ch unused
; cl has channel
; si is instr

mov   ax, es
test  ah, CH_VIBRATO
jne   writevibrato
done_with_vibrato:

mov   bl, cl
xor   bh, bh
mov   al, byte ptr cs:[bx + _OPL2driverdata + 030h - OFFSET SM_OPL2_STARTMARKER_]     ; channelPan
; ^^ last use of bx/channels

; al has channel pan
; stack high has pitchwheel
; stack low has note
; es low  is slot
; bx channel lookup
; si is instr

mov   dx, es    ; get channel/slot
mov   bx, si    ; instr

call  OPLwritePan_

;realvolume
mov   dl, byte ptr cs:[di + 7 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
mov   bx, si    ; instr
mov   ax, es
call  OPLwriteVolume_

pop   dx   ; retrieve note/pitchwheel

mov   bh, 1   ; keyon
mov   bl, dh  ; pitchwheel
;     dl is note
mov   ax, es  ; channel al
call  writeFrequency_

mov   bl, cl  ; restore channel. dont need to push/pop it
pop   si
ret

writevibrato:

mov   dx, 040h  ; vibrato on
mov   bx, si  ; instr
; al already has slot
call  writeModulation_

jmp   done_with_vibrato


ENDP

PROC  releaseChannel_ NEAR
; void releaseChannel(uint8_t slot, uint8_t killed){

; al slot
; ah killed
; todo: si channel ptr?

push  bx
push  cx
push  dx
push  di

mov   di, ax  ; store slot and killed.


xor   bh, bh

mov   dx, word ptr cs:[si + 3 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
mov   bl, dh
call  writeFrequency_
mov   byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], CH_FREE
or    byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], CH_FREE
test  di, 0FF00h  ; test high byte
jne   kill_channel

pop   di
pop   dx
pop   cx
pop   bx
ret  

kill_channel:
mov   dx, (PERCUSSION_CHANNEL SHL 8) + PERCUSSION_CHANNEL
mov   bx, di   ; low bits was al
mov   al, REGISTER_SUSTAIN

call  OPLwriteChannel_
mov   dx, 03F3Fh
mov   bx, di    ; low bits was al
mov   al, REGISTER_VOLUME
call  OPLwriteChannel_

pop   di
pop   dx
pop   cx
pop   bx
ret


ENDP



PROC  findFreeChannel_ NEAR

; todo work si out of this. use bx and change bl loop increment to smth else
push  bx
push  cx
push  dx
push  si
push  di


mov   bh, al
mov   cx, OPL2CHANNELS

mov   dl, byte ptr cs:[_lastfreechannel - OFFSET SM_OPL2_STARTMARKER_]
mov   al, SIZEOF_ADLIBCHANNEL
mul   dl
xchg  ax, si
xchg  ax, dx

loop_search_for_free_channel:
inc   al
add   si, SIZEOF_ADLIBCHANNEL
cmp   al, OPL2CHANNELS
jne   dont_zero_free_channel
set_free_channel_to_0:
mov   al, 0
xor   si, si
dont_zero_free_channel:
; write back free channel
mov   byte ptr cs:[_lastfreechannel - OFFSET SM_OPL2_STARTMARKER_], al 



test  byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], CH_FREE
jne   exit_free_channel


loop  loop_search_for_free_channel
done_finding_free_channel_loop:
test  bh, 1
jne   exit_free_channel_return_not_found
xor   bl, bl
mov   cl, 0FFh
xor   si, si
les   di, dword ptr ds:[_playingtime]
mov   dx, es


loop_find_free_channel:



test  byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], CH_SECONDARY
jne   force_release_secondary_channel
cmp   dx, word ptr cs:[si + 0Eh + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]


ja    exit_free_channel_loop
jne   do_next_free_channel_loop
cmp   di, word ptr cs:[si + 0Ch + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
jbe   do_next_free_channel_loop
exit_free_channel_loop:
mov   cl, bl
les   di, dword ptr cs:[si + 0Ch + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
mov   dx, es
do_next_free_channel_loop:
add   si, SIZEOF_ADLIBCHANNEL
inc   bl
cmp   bl, OPL2CHANNELS
jb    loop_find_free_channel

test  bh, 2
jne   exit_free_channel_return_not_found
cmp   cl, 0FFh
jne   force_release_oldest_channel
exit_free_channel_return_not_found:
mov   al, -1

exit_free_channel:

pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  

force_release_secondary_channel:
mov   ah, -1
mov   al, bl
call  releaseChannel_
xchg  ax, bx
jmp   exit_free_channel

force_release_oldest_channel:
mov   al, SIZEOF_ADLIBCHANNEL
mul   cl
xchg  ax, si
mov   al, cl
mov   ah, -1
call  releaseChannel_
xchg  ax, cx
jmp   exit_free_channel

ENDP


PROC  OPLplayNote_OPL2_ FAR
PUBLIC  OPLplayNote_OPL2_

;void OPLplayNote(uint8_t channel, uint8_t note, int8_t noteVolume){
; al channel  -2
; dl note     -4
; bl volume   -6

push  cx
push  si
push  di



mov   ch, bl
mov   cl, al    

; ch has volume
; cl/al has channel
; dl has note

;call  getInstrument_        ; inlined. used once. 


cmp   al, PERCUSSION_CHANNEL
jne   not_percussion
cmp   dl, 35
jb    instr_is_null_dont_play
cmp   dl, 81
ja    instr_is_null_dont_play
mov   bl, dl
add   bl, (128 - 35)
look_up_instrument:
cmp   bl, 174
ja    instr_is_null_dont_play
xor   bh, bh

mov   al, byte ptr cs:[bx + _instrumentlookup - OFFSET SM_OPL2_STARTMARKER_]
cmp   al, 0FFh
jne   found_instrument
; todo better jmp maze...

jmp   instr_is_null_dont_play
not_percussion:
mov   bl, al
xor   bh, bh
mov   bl, byte ptr cs:[bx + _OPL2driverdata + 00h - OFFSET SM_OPL2_STARTMARKER_]  ; channelInstr
jmp   look_up_instrument
found_instrument:
mov   ah, SIZEOF_OP2INSTRENTRY
mul   ah
add   ax, OFFSET _adlibinstrumentlist - OFFSET SM_OPL2_STARTMARKER_
got_instrument:

xchg  ax, si


instr_not_null:
; ch stores volume
; cl stores channel
; si is instr
; dl is note

cmp   cl, PERCUSSION_CHANNEL
je    channel_is_percussion
channel_not_percussion:
xor   ax, ax
go_find_channel:
call  findFreeChannel_

cmp   al, -1
jne   occupy_found_channel

jmp exit_play_note

channel_is_percussion:
mov   ax, 2              ; slot for findfreechannel
jmp   go_find_channel
occupy_found_channel:

; cl stores channel
; ch stores volume
; si is instr
; dl is note
; al has slot


xor   dh, dh  ; secondary 0
mov   bl, cl  ; bl gets channel
mov   cl, ch  ; cl gets volume.
mov   ch, dl  ; ch gets note

push  cx      ; store note/volume

; bl SHOULD have channel
; dh should have flag (0)
; cl should have volume
; ch should have note

; al already has freechannel/i

;		occupyChannel(i, channel, note, noteVolume, instr, 0);


call  occupyChannel_

; bl returns with channel
; si is popped..
pop   cx  ; retrieve note/volume

; cl now has volume
; ch now has note
; bl now has channel

cmp   word ptr cs:[si], FL_DOUBLE_VOICE
jne   exit_play_note
cmp   bl, PERCUSSION_CHANNEL
je    channel_is_percussion_2
channel_not_percussion_2:
mov   ax, 1
go_find_channel_2:
xor   ah, ah
call  findFreeChannel_
; al has new i/channel
cmp   al, -1
je    exit_play_note
; play 2nd voice

; bl channel
; cl/ch have volume/note.
; si has instr...
; al has slot.

mov   dh, 1

call  occupyChannel_
instr_is_null_dont_play:
exit_play_note:
pop   di
pop   si
pop   cx
retf  
channel_is_percussion_2:
mov   ax, 3
jmp   go_find_channel_2


ENDP

PROC  OPLreleaseNote_OPL2_ FAR
PUBLIC  OPLreleaseNote_OPL2_

;void OPLreleaseNote(uint8_t channel, uint8_t note){

; al channel
; dl note

push  cx
push  si

mov   ch, dl
mov   cl, al
xor   ah, ah
mov   si, ax
mov   al, byte ptr cs:[si + _OPL2driverdata + 050h - OFFSET SM_OPL2_STARTMARKER_] ; channelSustain
xor   bl, bl
mov   bh, al
xor   si, si
continue_looping_release_note:

cmp   cx, word ptr cs:[si + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
jne   loop_check_next_channel_for_release
cmp   bh, 040h        ; todo whats this mean
jae   add_sustain_flag
;si good
mov   al, bl
xor   ah, ah
call  releaseChannel_
loop_check_next_channel_for_release:
inc   bl
add   si, SIZEOF_ADLIBCHANNEL
cmp   bl, OPL2CHANNELS
jb    continue_looping_release_note
exit_release_note:

pop   si
pop   cx
retf  
add_sustain_flag:
or    byte ptr cs:[si + 3 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], CH_SUSTAIN
jmp   loop_check_next_channel_for_release


ENDP

PROC  OPLpitchWheel_OPL2_ FAR
PUBLIC  OPLpitchWheel_OPL2_

;void OPLpitchWheel(uint8_t channel, uint8_t pitch){

; al channel
; dl pitch

push  cx
push  si

sub   dl, DEFAULT_PITCH_BEND

cbw
mov   bx, ax

mov   byte ptr cs:[bx + _OPL2driverdata + 040h - OFFSET SM_OPL2_STARTMARKER_], dl ; channelPitch

mov   ch, al
mov   cl, 0
xor   si, si
loop_pitchwheel:

cmp   ch, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
je    do_adjust_pitch
check_pitchwheel_loop_for_increment:
inc   cl
add   si, SIZEOF_ADLIBCHANNEL
cmp   cl, OPL2CHANNELS
jb    loop_pitchwheel
exit_pitchwheel:
pop   si
pop   cx
retf  

do_adjust_pitch:
;	ch->time = playingtime;
;	pitchadder = (int16_t)ch->finetune + pitch;
;	ch->pitchwheel = (pitchadder & 0xFF);
;	writeFrequency(i, ch->realnote, ch->pitchwheel, 1);

; set time
les   ax, dword ptr ds:[_playingtime]
mov   word ptr cs:[si + 0Ch + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], ax
mov   word ptr cs:[si + 0Eh + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], es

; set pitchwheel
mov   al, byte ptr cs:[si + 5 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
add   ax, di
mov   byte ptr cs:[si + 4 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], al

; call writeFrequency

;realnote
mov   dl, byte ptr cs:[si + 3 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]

; pitchwheel and keyon
mov   bh, 1
mov   bl, al
mov   al, cl  ; get loop iter

call  writeFrequency_


jmp   check_pitchwheel_loop_for_increment



ENDP


; switch block lookup
change_control_lookup:
dw OFFSET change_control_instrument - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET change_control_modulation - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET change_control_volume     - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET change_control_pan        - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL2_STARTMARKER_
dw OFFSET change_control_sustain    - OFFSET SM_OPL2_STARTMARKER_


PROC  OPLchangeControl_OPL2_ FAR
PUBLIC  OPLchangeControl_OPL2_

;void OPLchangeControl(uint8_t channel, uint8_t controller, uint8_t value){

; al channel
; dl controller
; bl value

push      cx
push      si
push      di

; todo pre-prep bl, dont use 0ah 

cmp       dl, 8
ja        exit_oplchangecontrol     ; todo je change_control_sustain
cbw
xchg      ax, bx    ; bx has channel field. al has value
xor       dh, dh
mov       si, dx
sal       si, 1
jmp       word ptr cs:[si + change_control_lookup - OFFSET SM_OPL2_STARTMARKER_]
change_control_instrument:
mov       byte ptr cs:[bx + _OPL2driverdata + 00h - OFFSET SM_OPL2_STARTMARKER_], al  ; channelInstr
; fall thru exit
exit_oplchangecontrol:
pop       di
pop       si
pop       cx
retf     

change_control_sustain:
mov       byte ptr cs:[bx + _OPL2driverdata + 050h - OFFSET SM_OPL2_STARTMARKER_], al   ; channelSustain
cmp       al, 040h       ; todo this value
jae       exit_oplchangecontrol

;call      releaseSustain_ ; inlined


; bl has channel


xor   si, si
mov   cx, si

loop_release_sustain:
cmp   bl, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
jne   skip_release_channel
test  byte ptr cs:[si + _AdLibChannels + 2 - OFFSET SM_OPL2_STARTMARKER_], CH_SUSTAIN
je    skip_release_channel
mov   ax, cx
; ch is 0, ah/killed becomes zero
call  releaseChannel_
skip_release_channel:
add   si, SIZEOF_ADLIBCHANNEL
inc   cl
cmp   cl, OPL2CHANNELS
jb    loop_release_sustain

jmp exit_oplchangecontrol

change_control_modulation:

xor       di, di    ; loop counter
mov       si, di    ; loop channel ptr
mov       ch, bl    ; ch gets channel
mov       cl, al    ; cl gets value

mov       byte ptr cs:[bx + _OPL2driverdata + 060h - OFFSET SM_OPL2_STARTMARKER_], al  ; channelModulation
loop_modulate_next_channel:
cmp       ch, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]

je        found_channel_id_match_modulate
increment_loop_modulate_next_channel:
inc       di
add       si, SIZEOF_ADLIBCHANNEL
cmp       di, OPL2CHANNELS
jae       exit_oplchangecontrol
jmp       loop_modulate_next_channel
found_channel_id_match_modulate:

mov       al, byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
les       dx, dword ptr ds:[_playingtime]
mov       word ptr cs:[si + 0Ch + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], dx
mov       word ptr cs:[si + 0Eh + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], es

cmp       cl, MOD_MIN   ; value
jb        modulate_vibrato_off
modulate_vibrato_on:

or        byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], CH_VIBRATO
cmp       al, byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
je        increment_loop_modulate_next_channel
mov       dx, 040h
mov       bx, word ptr cs:[si + 8 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
mov       ax, di 
; al slot
; bx instr near ptr
; dl state

call      writeModulation_
jmp       increment_loop_modulate_next_channel
modulate_vibrato_off:
and       byte ptr cs:[bx + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], (0100h - CH_VIBRATO)   ; NOT CH_VIBRATO 0FBh
cmp       al, byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
je        increment_loop_modulate_next_channel
mov       bx, word ptr cs:[si + 8 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]

xor       dx, dx
mov       ax, di
call      writeModulation_
jmp       increment_loop_modulate_next_channel

change_control_volume:

xor       di, di    ; loop counter
mov       si, di    ; loop channel ptr
mov       ch, bl    ; ch gets channel
mov       cl, al    ; cl gets value

mov       byte ptr cs:[bx + _OPL2driverdata + 010h - OFFSET SM_OPL2_STARTMARKER_], al   ; channelVolume
loop_change_control_volume:

; cmp channel
cmp       ch, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
je        do_change_control_volume
increment_change_control_volume:
inc       di
add       si, SIZEOF_ADLIBCHANNEL


cmp       di, OPL2CHANNELS
jb        loop_change_control_volume
jmp       exit_oplchangecontrol
do_change_control_volume:
les       ax, dword ptr ds:[_playingtime]
mov       word ptr cs:[si + 0Ch + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], ax
mov       word ptr cs:[si + 0Eh + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], es

mov       al, byte ptr cs:[si + 6 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
cbw      
xchg      ax, bx
mov       al, byte ptr ds:[_snd_MusicVolume]
cbw      
xchg      ax, dx
mov       al, cl    ; get value field..
cbw      
call      calcVolumeOPL_

mov       bx, word ptr cs:[si + 8 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
mov       byte ptr cs:[si + 7 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], al
cbw      

xchg      ax, dx
mov       ax, di
call      OPLwriteVolume_
jmp       increment_change_control_volume

change_control_pan:

sub       al, 64

xor       di, di    ; loop counter
mov       si, di    ; loop channel ptr
mov       ch, bl    ; ch gets channel
mov       cl, al    ; cl gets value

mov       byte ptr cs:[bx + _OPL2driverdata + 030h - OFFSET SM_OPL2_STARTMARKER_], al ; channelPan

dont_exit_change_control_pan:
loop_change_control_pan:

cmp       ch, byte ptr cs:[bx + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
je        do_change_control_pan
increment_change_control_pan_loop:
inc       di
add       si, SIZEOF_ADLIBCHANNEL
cmp       di, OPL2CHANNELS
jb        loop_change_control_pan
jmp       exit_oplchangecontrol
do_change_control_pan:
les       ax, dword ptr ds:[_playingtime]
mov       word ptr cs:[bx + 0Ch + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], ax
mov       word ptr cs:[bx + 0Eh + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], es
mov       bx, word ptr cs:[bx + 8 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]

mov       al, cl
cbw      
mov       dx, di
call      OPLwritePan_
jmp       increment_change_control_pan_loop



ENDP

PROC  OPLplayMusic_OPL2_ FAR
PUBLIC  OPLplayMusic_OPL2_


push      bx
xor       al, al

loop_next_music_channel:
mov       bl, al
xor       bh, bh
mov       byte ptr cs:[bx + _OPL2driverdata + 010h - OFFSET SM_OPL2_STARTMARKER_], 07Fh   ; channelVolume
mov       byte ptr cs:[bx + _OPL2driverdata + 020h - OFFSET SM_OPL2_STARTMARKER_], bh     ; channelLastVolume
inc       al
mov       byte ptr cs:[bx + _OPL2driverdata + 050h - OFFSET SM_OPL2_STARTMARKER_], bh ; channelSustain
cmp       al, OPL_DRIVER_CHANNELS
jb        loop_next_music_channel
pop       bx
retf      


ENDP

PROC  OPLstopMusic_OPL2_ FAR
PUBLIC  OPLstopMusic_OPL2_

push      si
push      cx
xor       si, si
mov       cx, 0FF00h ;   -1 ch  0 cl
loop_stop_music:

test      byte ptr cs:[si + _AdLibChannels + 2 - OFFSET SM_OPL2_STARTMARKER_], CH_FREE
jne       increment_loop_stop_music
mov       ax, cx    ; -1 in ch
call      releaseChannel_
increment_loop_stop_music:
inc       cl
add       si, SIZEOF_ADLIBCHANNEL
cmp       cl, OPL2CHANNELS
jb        loop_stop_music

pop      cx
pop      si



retf      
ENDP


ENDP

ST_PLAYING = 2

PROC  OPLchangeSystemVolume_OPL2_ FAR
PUBLIC  OPLchangeSystemVolume_OPL2_

push      bx
push      cx
push      dx
push      si

; al = systemvolume 0-16


xor       si, si
mov       cx, si
mov       ch, al    ; ch holds system volume
loop_change_system_volume:

mov       al, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
and       ax, 0Fh
mov       bx, ax
mov       al, byte ptr cs:[bx + OFFSET _OPL2driverdata + 010h - OFFSET SM_OPL2_STARTMARKER_]
xor       dx, dx
mov       dl, ch
mov       bl, byte ptr cs:[si + 6 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
; dx = system volume
; al = channel volume
; bl = note volume
call      calcVolumeOPL_

; al gets volume...

mov       byte ptr cs:[si + 7 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], al
cmp       byte ptr ds:[_playingstate], ST_PLAYING
jne       increment_loop_change_system_volume

xchg      ax, dx    ; put volume in dl
mov       bx, word ptr cs:[si + 8 + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_]
mov       al, cl

; al channel 
; dl volume
; bx near ptr

call      OPLwriteVolume_
increment_loop_change_system_volume:
inc       cl
add       si, SIZEOF_ADLIBCHANNEL
cmp       cl, OPL2CHANNELS
jb        loop_change_system_volume

pop       si
pop       dx
pop       cx
pop       bx
retf      




ENDP

PROC  OPLinitDriver_OPL2_ FAR
PUBLIC  OPLinitDriver_OPL2_

push      bx
push      cx
push      dx
push      di

push      cs
pop       es
mov       cx, (SIZE_ADLIBCHANNELS / 2)
mov       ax, 0FFFFh
mov       di, OFFSET _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_
rep       stosw 

xor       dx, dx
mov       cx, dx
mov       bx, 4     ; pitchbend field offset in channel

mov       cl, OPL2CHANNELS

loop_init_channel:
cmp       dx, cx
jge       exit_init_opldriver
inc       dx
mov       byte ptr cs:[bx + _AdLibChannels - OFFSET SM_OPL2_STARTMARKER_], DEFAULT_PITCH_BEND
add       bx, 16    ; size of channel
jmp       loop_init_channel
exit_init_opldriver:
xor       al, al
pop       di
pop       dx
pop       cx
pop       bx
retf      



ENDP








PROC  SM_OPL2_ENDMARKER_
PUBLIC  SM_OPL2_ENDMARKER_
ENDP

ENDS


END

