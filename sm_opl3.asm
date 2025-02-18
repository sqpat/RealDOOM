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
MAX_MUSIC_CHANNELS   = 16
OPL3CHANNELS         = 18

MAX_INSTRUMENTS = 175
MAX_INSTRUMENTS_PER_TRACK = 01Ch ; largest in doom1 or doom2


SIZE_ADLIBCHANNELS          = 0120h

PLAYING_PERCUSSION_MASK     = 08000h

PROC  SM_OPL3_STARTMARKER_
PUBLIC  SM_OPL3_STARTMARKER_

ENDP
;; START DRIVERBLOCK

dw	OFFSET  OPLinitDriver_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPL3detectHardware_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPL3initHardware_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPL3deinitHardware_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLplayNote_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLreleaseNote_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLpitchWheel_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLchangeControl_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLplayMusic_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLstopMusic_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLpauseMusic_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLresumeMusic_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
dw  0
dw	OFFSET 	OPLchangeSystemVolume_OPL3_ - OFFSET SM_OPL3_STARTMARKER_
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

_OPLchannels:
db 9
_OPL3mode:
db 0
_lastfreechannel:
db 0FFh


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

;_instrumentlookup:
;REPT MAX_INSTRUMENTS
;    ZERO_BYTE
;ENDM

_AdLibChannels:
REPT MAX_MUSIC_CHANNELS * OPL3CHANNELS
    ZERO_BYTE
ENDM









COMMENT @    
PROC  logwrite_ NEAR
PUBLIC  logwrite_
pusha
call  printerfunc_
popa
ret
ENDP

@


PROC  OPLwriteReg_ NEAR

push  bx
push  cx
mov   bl, dl
cmp   byte ptr cs:[_OPL3mode - OFFSET SM_OPL3_STARTMARKER_], 0
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
mov   al, byte ptr cs:[si + _op_num - OFFSET SM_OPL3_STARTMARKER_]
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

push  bx
mov   ah, dl
mov   dl, 03Fh
sub   dl, al
mov   al, ah
and   al, 07Fh
cbw  
mov   bx, ax
mov   al, byte ptr cs:[bx + _noteVolumetable - OFFSET SM_OPL3_STARTMARKER_]
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


PROC  OPLwritePan_ NEAR

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

PROC  OPLwriteValue_ NEAR


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
ret

; part of writepan
pan_less_than_minus_36:
mov   al, PAN_LEFT_CHANNEL
jmp   pan_capped
pan_not_greater_than_36:
mov   al, PAN_BOTH_CHANNELS
jmp   pan_capped

ENDP

PROC  OPLwriteInstrument_ NEAR


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

mov   byte ptr cs:[_OPL3mode - OFFSET SM_OPL3_STARTMARKER_], al
test  al, al
je    oplinit_opl2

oplinit_opl3:
mov   dx, 1
mov   ax, 0105h      ; enable YMF262/OPL3 mode
mov   byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_], 18
call  OPLwriteReg_
mov   ax, 0104h      ; disable 4-operator mode
xor   dx, dx
call  OPLwriteReg_
jmp   finish_opl_init

oplinit_opl2:
mov   byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_], 9
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

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   byte ptr [bp - 2], 0
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
mov   cx, 0Fh               ; ... and release
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
cmp   al, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
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








PROC  OPL2detect_ NEAR


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
do_exit:
pop   dx
pop   cx
pop   bx
ret
return_opl2_not_detected:
xor   ax, ax
jmp   do_exit



ENDP

PROC  OPL3detectHardware_OPL3_ FAR
PUBLIC  OPL3detectHardware_OPL3_


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



PROC  OPL3deinitHardware_OPL3_ FAR
PUBLIC  OPL3deinitHardware_OPL3_

push  dx
call  OPLshutup_
cmp   byte ptr cs:[_OPL3mode - OFFSET SM_OPL3_STARTMARKER_], 0
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
xor   ax, ax
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


PROC  OPLpauseMusic_OPL3_ FAR
PUBLIC  OPLpauseMusic_OPL3_
call  OPLshutup_
ENDP

PROC  OPLresumeMusic_OPL3_ FAR
PUBLIC  OPLresumeMusic_OPL3_

retf

ENDP

PROC  writeFrequency_ NEAR       ; two inlined writevalues? todo 

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
mov   si, word ptr cs:[si + _freqtable - OFFSET SM_OPL3_STARTMARKER_]

freq_and_octave_ready:
cmp   bh, DEFAULT_PITCH_BEND
je    skip_pitch_wheel_calculation
mov   al, bh
xor   ah, ah
mov   di, ax
mov   al, byte ptr cs:[di + _pitchwheeltable - OFFSET SM_OPL3_STARTMARKER_]
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

ret

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
mov   si, word ptr cs:[si + _freqtable2 - OFFSET SM_OPL3_STARTMARKER_]
jmp   freq_and_octave_ready
zero_last_bit:
xor   si, si
jmp   got_last_bit

ENDP

PROC  writeModulation_ NEAR

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
ret
feedback_one:
mov   al, byte ptr es:[bx]   ; instr->trem_vibr_1
jmp   feedback_checked

ENDP



PROC  calcVolumeOPL_ NEAR

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
ret


ENDP

CH_SECONDARY = 1
MOD_MIN      = 40
CH_VIBRATO   = 4
PERCUSSION_CHANNEL = 15
FL_FIXED_PITCH = 1
FL_DOUBLE_VOICE = 4


PROC  occupyChannel_ NEAR

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Eh
mov   di, word ptr [bp + 08h]
mov   byte ptr [bp - 4], al
mov   byte ptr [bp - 2], dl
mov   byte ptr [bp - 6], bl
mov   al, cl
mov   bl, byte ptr [bp - 4]

xor   bh, bh

shl   bx, 4     ; 16 bytes per channel...
mov   ah, byte ptr [bp - 6]
mov   byte ptr cs:[bx + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], dl
mov   si, bx
mov   byte ptr cs:[bx + 1 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], ah
cmp   byte ptr [bp + 0Ch], 0
jne   set_channel_secondary_flag_on
xor   dx, dx
jmp   set_channel_secondary_flag
set_channel_secondary_flag_on:
mov   dx, CH_SECONDARY
set_channel_secondary_flag:
mov   bl, byte ptr [bp - 2]
xor   bh, bh
mov   byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], dl                              ; ch->flags
cmp   byte ptr cs:[bx + _OPL2driverdata + 060h - OFFSET SM_OPL3_STARTMARKER_], MOD_MIN      ; channelModulation
jb    dont_set_vibrato
or    byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_VIBRATO
dont_set_vibrato:
mov   dx, word ptr ds:[_playingtime]
mov   bx, word ptr ds:[_playingtime + 2]
mov   word ptr cs:[si + 0Ch + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], dx
mov   word ptr cs:[si + 0Eh + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], bx

;   if (noteVolume == -1){
;		noteVolume = OPL2driverdata.channelLastVolume[channel];
;	} else{
;		OPL2driverdata.channelLastVolume[channel] = noteVolume;
;	}
mov   bl, byte ptr [bp - 2]
xor   bh, bh

cmp   al, -1
je    use_last_volume
mov   byte ptr cs:[bx + _OPL2driverdata + 020h - OFFSET SM_OPL3_STARTMARKER_], al     ; channelLastVolume
jmp   volume_is_set
use_last_volume:
mov   al, byte ptr cs:[bx + _OPL2driverdata + 020h - OFFSET SM_OPL3_STARTMARKER_]     ; channelLastVolume
volume_is_set:

mov   dl, byte ptr ds:[_snd_MusicVolume]
mov   byte ptr cs:[si + 6 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
cbw  
xor   dh, dh
mov   cx, ax
mov   al, byte ptr cs:[bx + _OPL2driverdata + 010h - OFFSET SM_OPL3_STARTMARKER_]     ; channelVolume
mov   bx, cx
xor   ah, ah
call  calcVolumeOPL_
mov   byte ptr cs:[si + 7 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
mov   es, word ptr [bp + 0Ah]
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
cmp   byte ptr [bp + 0Ch], 0
jne   lookup_instrument_finetune
use_fixed_pitch:
mov   byte ptr cs:[si + 5 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], DEFAULT_PITCH_BEND
jmp   finetune_set
lookup_instrument_finetune:

test  byte ptr es:[di], FL_DOUBLE_VOICE
je    use_fixed_pitch
mov   al, byte ptr es:[di + 2]
mov   byte ptr cs:[si + 5 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
finetune_set:
mov   bl, byte ptr [bp - 2]
xor   bh, bh
mov   al, byte ptr cs:[bx + _OPL2driverdata + 040h - OFFSET SM_OPL3_STARTMARKER_]     ; channelpitch
cbw  
mov   dx, ax
mov   al, byte ptr cs:[si + 5 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
cbw  
add   ax, dx
mov   byte ptr cs:[si + 4 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
cmp   byte ptr [bp + 0Ch], 0
jne   use_secondary

add   di, 4
jmp   instr_set
use_secondary:

add   di, 014h
instr_set:
mov   word ptr [bp - 8], es

mov   word ptr cs:[si + 8 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], di
mov   word ptr cs:[si + 0Ah + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], es

mov   al, byte ptr es:[di + 0Eh]
add   byte ptr [bp - 6], al
and   byte ptr [bp - 6], 07Fh

mov   al, byte ptr [bp - 6]
mov   byte ptr [bp - 0Dh], 0
mov   byte ptr cs:[si + 3 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
mov   al, byte ptr [bp - 4]
mov   cx, word ptr [bp - 8]
mov   byte ptr [bp - 0Eh], al
mov   bx, di
mov   ax, word ptr [bp - 0Eh]
call  OPLwriteInstrument_

test  byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_VIBRATO
jne   writevibrato
done_with_vibrato:
mov   bl, byte ptr [bp - 2]
mov   dl, byte ptr [bp - 4]
mov   cx, word ptr [bp - 8]
xor   bh, bh
mov   byte ptr [bp - 0Ch], dl
mov   al, byte ptr cs:[bx + _OPL2driverdata + 030h - OFFSET SM_OPL3_STARTMARKER_]     ; channelPan
mov   byte ptr [bp - 0Bh], bh
cbw  
mov   bx, di
mov   dx, ax
mov   ax, word ptr [bp - 0Ch]
call  OPLwritePan_

mov   al, byte ptr cs:[si + 7 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov   cx, word ptr [bp - 8]
cbw  
mov   bx, di
mov   dx, ax
mov   ax, word ptr [bp - 0Ch]
call  OPLwriteVolume_
mov   dl, byte ptr [bp - 6]
mov   cx, 1
mov   ax, word ptr [bp - 0Ch]
mov   bl, byte ptr cs:[si + 4 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_] 
xor   dh, dh
xor   bh, bh
call  writeFrequency_
mov   al, byte ptr [bp - 4]
LEAVE_MACRO 
pop   di
pop   si
ret  6

writevibrato:
mov   dx, 1
mov   cx, word ptr [bp - 8]
mov   ax, word ptr [bp - 0Eh]
mov   bx, di
call  writeModulation_
jmp   done_with_vibrato


ENDP

PROC  releaseChannel_ NEAR


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   byte ptr [bp - 2], dl
mov   byte ptr [bp - 3], 0

mov   byte ptr [bp - 4], al
xor   cx, cx
mov   si, word ptr [bp - 4]

shl   si, 4
mov   ax, word ptr [bp - 4]
mov   bl, byte ptr cs:[si + 4 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov   dl, byte ptr cs:[si + 3 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
xor   bh, bh
xor   dh, dh
call  writeFrequency_
mov   byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_FREE
or    byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_FREE
cmp   byte ptr [bp - 2], 0
jne   kill_channel
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret  
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
ret


ENDP

PROC  releaseSustain_ NEAR

push  bx
push  dx
push  si
mov   bh, al
xor   bl, bl
loop_release_sustain:
mov   al, bl
xor   ah, ah
mov   dx, ax

shl   dx, 4

mov   si, dx
cmp   bh, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
jne   skip_release_channel
add   si, 2
test  byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], 2
je    skip_release_channel
xor   dx, dx
call  releaseChannel_
skip_release_channel:
inc   bl
cmp   bl, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb    loop_release_sustain
exit_release_sustain:
pop   si
pop   dx
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
push  bp
mov   bp, sp
sub   sp, 4
mov   byte ptr [bp - 4], al
mov   byte ptr [bp - 2], 0FFh
mov   di, word ptr ds:[_playingtime]
mov   dx, word ptr ds:[_playingtime + 2]
xor   bl, bl

loop_search_for_free_channel:
inc   byte ptr cs:[_lastfreechannel - OFFSET SM_OPL3_STARTMARKER_]
mov   al, byte ptr cs:[_lastfreechannel - OFFSET SM_OPL3_STARTMARKER_]
cmp   al, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jne   dont_zero_free_channel
set_free_channel_to_0:
mov   byte ptr cs:[_lastfreechannel - OFFSET SM_OPL3_STARTMARKER_], 0
dont_zero_free_channel:
mov   al, byte ptr cs:[_lastfreechannel - OFFSET SM_OPL3_STARTMARKER_]
xor   ah, ah
mov   si, ax
shl   si, 4

test  byte ptr cs:[si + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_FREE
jne   exit_free_channel
inc   bl
cmp   bl, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb    loop_search_for_free_channel
done_finding_free_channel_loop:
test  byte ptr [bp - 4], 1
jne   exit_free_channel_return_not_found
xor   cl, cl
loop_find_free_channel:
mov   al, cl
xor   ah, ah
mov   bx, ax

shl   bx, 4


test  byte ptr cs:[bx + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], 1
jne   force_release_secondary_channel
mov   ax, word ptr cs:[bx + 0Eh + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]

cmp   dx, ax
ja    exit_free_channel_loop
jne   do_next_free_channel_loop
cmp   di, word ptr cs:[bx + 0Ch + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
jbe   do_next_free_channel_loop
exit_free_channel_loop:
mov   dx, ax
mov   byte ptr [bp - 2], cl
mov   di, word ptr cs:[bx + 0Ch + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
do_next_free_channel_loop:
inc   cl
cmp   cl, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
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
ret  

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
ret  

ENDP

PROC  getInstrument_ NEAR

push  bx
push  cx
mov   bx, 1
mov   cl, al
shl   bx, cl
test  bh, (PLAYING_PERCUSSION_MASK SHR 8)
je    not_percussion
cmp   dl, 35
jb    return_null_instrument
cmp   dl, 81
ja    return_null_instrument
mov   bl, dl
add   bl, (128 - 35)
look_up_instrument:
xor   bh, bh

mov   al, byte ptr cs:[bx + _instrumentlookup - OFFSET SM_OPL3_STARTMARKER_]
cmp   al, 0FFh
jne   found_instrument

return_null_instrument:
xor   ax, ax
xor   dx, dx
pop   cx
pop   bx
ret  
not_percussion:
mov   bl, al
xor   bh, bh
mov   bl, byte ptr cs:[bx + _OPL2driverdata + 00h - OFFSET SM_OPL3_STARTMARKER_]  ; channelInstr
jmp   look_up_instrument
found_instrument:
xor   ah, ah
mov   dx, cs
mov   ah, SIZEOF_OP2INSTRENTRY
mul   ah
add   ax, OFFSET _adlibinstrumentlist - OFFSET SM_OPL3_STARTMARKER_
pop   cx
pop   bx
ret  

ENDP

PROC  OPLplayNote_OPL3_ FAR
PUBLIC  OPLplayNote_OPL3_

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
call  getInstrument_        ; todo inline. used once. 
mov   si, ax
mov   di, dx
test  dx, dx

; todo clean this null check up
jne   instr_not_null
test  ax, ax
je    instr_is_null_dont_play
instr_not_null:
cmp   byte ptr [bp - 2], PERCUSSION_CHANNEL
je    channel_is_percussion
channel_not_percussion:
xor   ax, ax
go_find_channel:
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
push  si
cbw  
xor   bh, bh
xor   dh, dh
mov   cx, ax
mov   al, byte ptr [bp - 0Ah]
xor   ah, ah
call  occupyChannel_
;cmp   byte ptr ds:[_OPLsinglevoice], 0
;jne   exit_play_note
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
push  si
cbw  
xor   bh, bh
xor   dh, dh
mov   cx, ax
mov   al, byte ptr [bp - 8]
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

PROC  OPLreleaseNote_OPL3_ FAR
PUBLIC  OPLreleaseNote_OPL3_

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
mov   al, byte ptr cs:[si + _OPL2driverdata + 050h - OFFSET SM_OPL3_STARTMARKER_] ; channelSustain
xor   bl, bl
mov   byte ptr [bp - 2], al
continue_looping_release_note:
mov   al, bl
xor   ah, ah
mov   dx, ax
shl   dx, 4
mov   si, dx
cmp   cl, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
jne   loop_check_next_channel_for_release

cmp   bh, byte ptr cs:[si + 1 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
jne   loop_check_next_channel_for_release
cmp   byte ptr [bp - 2], 040h        ; todo whats this mean
jae   add_sustain_flag
xor   dx, dx
call  releaseChannel_
loop_check_next_channel_for_release:
inc   bl
cmp   bl, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb    continue_looping_release_note
exit_release_note:
LEAVE_MACRO 
pop   si
pop   cx
pop   bx
retf  
add_sustain_flag:
or    byte ptr cs:[si + 3 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_SUSTAIN
jmp   loop_check_next_channel_for_release


ENDP

PROC  OPLpitchWheel_OPL3_ FAR
PUBLIC  OPLpitchWheel_OPL3_

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
mov   byte ptr cs:[bx + _OPL2driverdata + 040h - OFFSET SM_OPL3_STARTMARKER_], al ; channelPitch
loop_pitchwheel:
mov   al, byte ptr [bp - 4]
mov   byte ptr [bp - 7], 0
mov   byte ptr [bp - 8], al
mov   bx, word ptr [bp - 8]

shl   bx, 4
mov   al, byte ptr cs:[bx + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
cmp   al, byte ptr [bp - 6]
je    do_adjust_pitch
check_pitchwheel_loop_for_increment:
inc   byte ptr [bp - 4]
mov   al, byte ptr [bp - 4]
cmp   al, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb    loop_pitchwheel
exit_pitchwheel:
LEAVE_MACRO 
pop   cx
pop   bx
retf  

do_adjust_pitch:
mov   dx, word ptr ds:[_playingtime]
mov   ax, word ptr ds:[_playingtime + 2]
mov   word ptr cs:[bx + 0Eh + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], ax
mov   al, byte ptr cs:[bx + 5 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
cbw  
mov   word ptr cs:[bx + 0Ch + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], dx
mov   dx, ax
mov   al, byte ptr [bp - 2]
xor   ah, ah
mov   cx, 1
add   ax, dx
mov   dl, byte ptr cs:[bx + 3 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov   byte ptr cs:[bx + 4 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
xor   ah, ah
xor   dh, dh
mov   bx, ax
mov   ax, word ptr [bp - 8]
call  writeFrequency_
jmp   check_pitchwheel_loop_for_increment



ENDP


; switch block lookup
change_control_lookup:
dw OFFSET change_control_instrument - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET change_control_modulation - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET change_control_volume     - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET change_control_pan        - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET exit_oplchangecontrol     - OFFSET SM_OPL3_STARTMARKER_
dw OFFSET change_control_sustain    - OFFSET SM_OPL3_STARTMARKER_


PROC  OPLchangeControl_OPL3_ FAR
PUBLIC  OPLchangeControl_OPL3_

push      cx
push      si
push      bp
mov       bp, sp
sub       sp, 0Eh
; todo pre-prep bl, dont use 0ah 
mov       byte ptr [bp - 0Ah], bl
mov       byte ptr [bp - 2], al
cmp       dl, 8
ja        exit_oplchangecontrol     ; todo je change_control_sustain
xor       dh, dh
mov       bx, dx
add       bx, dx
jmp       word ptr cs:[bx + change_control_lookup - OFFSET SM_OPL3_STARTMARKER_]
change_control_instrument:
mov       bl, al
xor       bh, bh
mov       al, byte ptr [bp - 0Ah]
mov       byte ptr cs:[bx + _OPL2driverdata + 00h - OFFSET SM_OPL3_STARTMARKER_], al  ; channelInstr
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
mov       byte ptr cs:[bx + _OPL2driverdata + 060h - OFFSET SM_OPL3_STARTMARKER_], al  ; channelModulation
loop_modulate_next_channel:
mov       al, byte ptr [bp - 4]
xor       ah, ah
mov       bx, ax
shl       bx, 4
mov       dl, byte ptr cs:[bx + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
cmp       dl, byte ptr [bp - 2]
je        found_channel_id_match_modulate
increment_loop_modulate_next_channel:
inc       byte ptr [bp - 4]
mov       al, byte ptr [bp - 4]
cmp       al, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jae       exit_oplchangecontrol
jmp       loop_modulate_next_channel
found_channel_id_match_modulate:
mov       dl, byte ptr cs:[bx + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       cx, word ptr ds:[_playingtime]
mov       si, word ptr ds:[_playingtime + 2]
mov       word ptr cs:[bx + 0Ch + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], cx
mov       word ptr cs:[bx + 0Eh + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], si
cmp       byte ptr [bp - 0Ah], MOD_MIN
jb        modulate_vibrato_off
modulate_vibrato_on:
or        byte ptr cs:[bx + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_VIBRATO
cmp       dl, byte ptr cs:[bx + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
je        increment_loop_modulate_next_channel
mov       dx, 1
mov       si, word ptr cs:[bx + 8 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       cx, word ptr cs:[bx + 0Ah + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       bx, si
call      writeModulation_
jmp       increment_loop_modulate_next_channel
modulate_vibrato_off:
and       byte ptr cs:[bx + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], (0100h - CH_VIBRATO)   ; NOT CH_VIBRATO 0FBh
cmp       dl, byte ptr cs:[bx + 2 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
je        increment_loop_modulate_next_channel
mov       cx, word ptr cs:[bx + 8 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       si, word ptr cs:[bx + 0Ah + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
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
mov       byte ptr cs:[bx + _OPL2driverdata + 010h - OFFSET SM_OPL3_STARTMARKER_], al   ; channelVolume
loop_change_control_volume:
mov       al, byte ptr [bp - 6]
mov       byte ptr [bp - 0Bh], 0
mov       byte ptr [bp - 0Ch], al
mov       si, word ptr [bp - 0Ch]
shl       si, 4
mov       al, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
cmp       al, byte ptr [bp - 2]
je        do_change_control_volume
increment_change_control_volume:
inc       byte ptr [bp - 6]
mov       al, byte ptr [bp - 6]
cmp       al, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb        loop_change_control_volume
jmp       exit_oplchangecontrol
do_change_control_volume:
mov       ax, word ptr ds:[_playingtime]
mov       dx, word ptr ds:[_playingtime + 2]
mov       word ptr cs:[si + 0Ch + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], ax
mov       al, byte ptr cs:[si + 6 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       word ptr cs:[si + 0Eh + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], dx
cbw      
mov       dl, byte ptr ds:[_snd_MusicVolume]
mov       bx, ax
mov       al, byte ptr [bp - 0Ah]
xor       dh, dh
xor       ah, ah
call      calcVolumeOPL_

mov       bx, word ptr cs:[si + 8 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       byte ptr cs:[si + 7 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
cbw      
mov       cx, word ptr cs:[si + 0Ah + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
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
mov       byte ptr cs:[bx + _OPL2driverdata + 030h - OFFSET SM_OPL3_STARTMARKER_], al ; channelPan
dont_exit_change_control_pan:
loop_change_control_pan:
mov       al, byte ptr [bp - 8]
mov       byte ptr [bp - 0Dh], 0
mov       byte ptr [bp - 0Eh], al
mov       bx, word ptr [bp - 0Eh]
shl       bx, 4
mov       al, byte ptr cs:[bx + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
cmp       al, byte ptr [bp - 2]
je        do_change_control_pan
increment_change_control_pan_loop:
inc       byte ptr [bp - 8]
mov       al, byte ptr [bp - 8]
cmp       al, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb        loop_change_control_pan
jmp       exit_oplchangecontrol
do_change_control_pan:
mov       ax, word ptr ds:[_playingtime]
mov       dx, word ptr ds:[_playingtime + 2]
mov       si, word ptr cs:[bx + 8 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       cx, word ptr cs:[bx + 0Ah + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       word ptr cs:[bx + 0Ch + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], ax
mov       al, byte ptr [bp - 0Ah]
mov       word ptr cs:[bx + 0Eh + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], dx
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
mov       byte ptr cs:[bx + _OPL2driverdata + 050h - OFFSET SM_OPL3_STARTMARKER_], al   ; channelSustain
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

PROC  OPLplayMusic_OPL3_ FAR
PUBLIC  OPLplayMusic_OPL3_


push      bx
xor       al, al

loop_next_music_channel:
mov       bl, al
xor       bh, bh
mov       byte ptr cs:[bx + _OPL2driverdata + 010h - OFFSET SM_OPL3_STARTMARKER_], 07Fh   ; channelVolume
mov       byte ptr cs:[bx + _OPL2driverdata + 020h - OFFSET SM_OPL3_STARTMARKER_], bh     ; channelLastVolume
inc       al
mov       byte ptr cs:[bx + _OPL2driverdata + 050h - OFFSET SM_OPL3_STARTMARKER_], bh ; channelSustain
cmp       al, MAX_MUSIC_CHANNELS
jb        loop_next_music_channel
pop       bx
retf      


ENDP

PROC  OPLstopMusic_OPL3_ FAR
PUBLIC  OPLstopMusic_OPL3_

push      bx
push      dx
push      si
xor       bl, bl
loop_stop_music:
mov       al, bl
xor       ah, ah
mov       si, ax
shl       si, 4
add       si, 2
test      byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], CH_FREE
jne       increment_loop_stop_music
mov       dx, -1
call      releaseChannel_
increment_loop_stop_music:
inc       bl
cmp       bl, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb        loop_stop_music
exit_stop_music:
pop       si
pop       dx
pop       bx
retf      


ENDP

PROC  OPLchangeSystemVolume_OPL3_ FAR
PUBLIC  OPLchangeSystemVolume_OPL3_

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
loop_change_system_volume:
mov       al, byte ptr [bp - 4]
mov       byte ptr [bp - 5], 0
mov       byte ptr [bp - 6], al
mov       si, word ptr [bp - 6]
shl       si, 4
mov       al, byte ptr cs:[si + 6 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
cbw      
mov       bx, ax
mov       al, byte ptr cs:[si + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
and       al, 0Fh
mov       di, OFFSET _OPL2driverdata + 010h - OFFSET SM_OPL3_STARTMARKER_  ; channelVolume
xor       ah, ah
mov       dl, byte ptr [bp - 2]
add       di, ax
xor       dh, dh
mov       al, byte ptr cs:[di]
call      calcVolumeOPL_

mov       byte ptr cs:[si + 7 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], al
cmp       byte ptr ds:[_playingstate], 2
jne       increment_loop_change_system_volume

cbw      
mov       bx, word ptr cs:[si + 8 + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       cx, word ptr cs:[si + 0Ah + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_]
mov       dx, ax
mov       ax, word ptr [bp - 6]
call      OPLwriteVolume_
increment_loop_change_system_volume:
inc       byte ptr [bp - 4]
mov       al, byte ptr [bp - 4]
cmp       al, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]
jb        loop_change_system_volume

LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      




ENDP

PROC  OPLinitDriver_OPL3_ FAR
PUBLIC  OPLinitDriver_OPL3_

push      bx
push      cx
push      dx
push      di

push      cs
pop       es
mov       cx, (SIZE_ADLIBCHANNELS / 2)
mov       ax, 0FFFFh
mov       di, OFFSET _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_
rep       stosw 

xor       dx, dx
mov       cx, dx
mov       bx, 4     ; pitchbend field offset in channel

mov       cl, byte ptr cs:[_OPLchannels - OFFSET SM_OPL3_STARTMARKER_]

loop_init_channel:
cmp       dx, cx
jge       exit_init_opldriver
inc       dx
mov       byte ptr cs:[bx + _AdLibChannels - OFFSET SM_OPL3_STARTMARKER_], DEFAULT_PITCH_BEND
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


PROC  OPL3initHardware_OPL3_ FAR
PUBLIC  OPL3initHardware_OPL3_

mov       al, 1
call      OPLinit_
xor       al, al
retf

ENDP







PROC  SM_OPL3_ENDMARKER_
PUBLIC  SM_OPL3_ENDMARKER_
ENDP



END

