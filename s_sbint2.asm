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

EXTRN SB_WriteDSP_:NEAR

.DATA

PC_SPEAKER_SFX_DATA_TEMP_SEGMENT = 0D7E0h

EXTRN _sb_port:WORD
EXTRN _SB_MixerType:BYTE
EXTRN _SB_OriginalVoiceVolumeLeft:BYTE
EXTRN _SB_OriginalVoiceVolumeRight:BYTE

.CODE


PROC    S_SBINIT_STARTMARKER_
PUBLIC  S_SBINIT_STARTMARKER_
ENDP



SB_TYPE_NONE 	= 0
SB_TYPE_SB 		= 1
SB_TYPE_SBPRO 	= 2
SB_TYPE_SB20 	= 3
SB_TYPE_SBPRO2 	= 4
SB_TYPE_SB16 	= 6

SB_MIXBUFFERSIZE = 256

SB_DSP_SignedBit = 010h
SB_DSP_StereoBit = 020h

SB_DSP_UNSIGNEDMONODATA = 	    000h
SB_DSP_SIGNEDMONODATA = 		(SB_DSP_SIGNEDBIT)
SB_DSP_UNSIGNEDSTEREODATA = 	(SB_DSP_STEREOBIT)
SB_DSP_SIGNEDSTEREODATA = 	    (SB_DSP_SIGNEDBIT OR SB_DSP_STEREOBIT)

SB_DSP_HALT8BITTRANSFER = 		0D0h
SB_DSP_CONTINUE8BITTRANSFER = 	0D4h
SB_DSP_HALT16BITTRANSFER = 		0D5h
SB_DSP_CONTINUE16BITTRANSFER = 	0D6h
SB_DSP_RESET = 					0FFFFh

SB_MIXER_DSP4xxISR_Ack              = 082h
SB_MIXER_DSP4xxISR_Enable           = 083h
SB_MIXER_MPU401_INT                 = 04h
SB_MIXER_16BITDMA_INT               = 02h
SB_MIXER_8BITDMA_INT                = 01h
SB_MIXER_DisableMPU401Interrupts    = 0Bh
SB_MIXER_SBProOutputSetting         = 00Eh
SB_MIXER_SBProStereoFlag            = 002h
SB_MIXER_SBProVoice                 = 004h
SB_MIXER_SBProMidi                  = 026h
SB_MIXER_SB16VoiceLeft              = 032h
SB_SBProVoice                       = 004h
SB_MIXER_SB16VoiceRight             = 033h
SB_MIXER_SB16MidiLeft               = 034h
SB_MIXER_SB16MidiRight              = 035h


PLAYING_FLAG = 080h

MAX_VOLUME_SFX = 07Fh

SB_DSP_VERSION1XX = 00100h
SB_DSP_VERSION2XX = 00200h
SB_DSP_VERSION201 = 00201h
SB_DSP_VERSION3XX = 00300h
SB_DSP_VERSION4XX = 00400h

MIXER_8BITDMA_INT    = 01h
SB_MIXERADDRESSPORT  = 04h
SB_MIXERDATAPORT 	 = 05h
SB_RESETPORT 		 = 06h
SB_READPORT 		 = 0Ah
SB_WRITEPORT 		 = 0Ch
SB_DATAAVAILABLEPORT = 0Eh
SB_ERROR             = -1
SB_OK                = 0
SB_READY 			 = 0AAh
SB_CARDNOTREADY      = 5


; todo programattically determine?
RETRY_COUNT = 000FFh   


PROC   SB_ReadDSP_ NEAR
PUBLIC SB_ReadDSP_

push   dx
push   cx
mov    dx, word ptr ds:[_sb_port] ;    int16_t port = sb_port + SB_DataAvailablePort;
add    dx, SB_DATAAVAILABLEPORT
mov    cx, RETRY_COUNT            ;     uint8_t count = 0xFF;
loop_try_read_dsp_again:
in     al, dx
test   al, 080h

jne    got_read_dsp_result        ;     if (inp(port) & 0x80) {

loop   loop_try_read_dsp_again
mov    al, SB_ERROR               ; return SB_Error;
jmp    do_read_dsp_return


got_read_dsp_result:
; return inp(sb_port + SB_ReadPort);
add    dl, (SB_READPORT - SB_DATAAVAILABLEPORT)  ; dx was previously SB_DATAAVAILABLEPORT
in     al, dx

do_read_dsp_return:
pop    cx
pop    dx
ret

ENDP

PROC   SB_ResetDSP_ NEAR
PUBLIC SB_ResetDSP_

push   dx
push   cx
mov    dx, word ptr ds:[_sb_port] ;    int16_t port = sb_port + SB_ResetPort;
add    dx, SB_ResetPort
mov    cx, RETRY_COUNT            ;     uint8_t count = 0xFF;

mov    al, 1
out    dx, al                     ;     outp(port, 0);

loop_reset_pause_loop:
loop   loop_reset_pause_loop

dec    ax
out    dx, al                     ;     outp(port, 0);

mov    cl, RETRY_COUNT            ;     count = 0xFF;

loop_try_reset_dsp:
call   SB_ReadDSP_
cmp    al, SB_READY               ;     if (SB_ReadDSP() == SB_Ready) {
mov    al, SB_OK
je     return_reset_result

loop   loop_try_reset_dsp
mov    al, SB_CARDNOTREADY
return_reset_result:

pop    cx
pop    dx

ret
ENDP

PROC   SB_ReadMixer_ NEAR
PUBLIC SB_ReadMixer_
push   dx
mov    dx, word ptr ds:[_sb_port]                   ; outp(sb_port + SB_MixerAddressPort, reg);
add    dx, SB_MIXERADDRESSPORT
out    dx, al
add    dl, (SB_MIXERDATAPORT - SB_MIXERADDRESSPORT) ; return inp(sb_port + SB_MixerDataPort);
in     al, dx
pop    dx
ret
ENDP

PROC   SB_WriteMixer_ NEAR
PUBLIC SB_WriteMixer_
mov    ah, dl    ; data in ah
mov    dx, word ptr ds:[_sb_port]                   ; outp(sb_port + SB_MixerAddressPort, reg);
add    dx, SB_MIXERADDRESSPORT
out    dx, al
add    dl, (SB_MIXERDATAPORT - SB_MIXERADDRESSPORT) ; outp(sb_port + SB_MixerDataPort, data);
mov    al, ah
out    dx, al
ret
ENDP


PROC   SB_SaveVoiceVolume_ NEAR
PUBLIC SB_SaveVoiceVolume_

mov    al, byte ptr ds:[_SB_MixerType]
cmp    al, SB_TYPE_SB16
je     save_both_voice_volume
mov    ah, SB_MIXER_SBPROVOICE
cmp    al, SB_TYPE_SBPRO
je     save_one_voice_volumne
cmp    al, SB_TYPE_SBPRO2
je     save_one_voice_volumne
ret
save_both_voice_volume:
mov    al, SB_MIXER_SB16VOICELEFT
call   SB_ReadMixer_
mov    byte ptr ds:[_SB_OriginalVoiceVolumeRight], al

mov    ah, SB_MIXER_SB16VOICELEFT
save_one_voice_volumne:
mov    al, ah
call   SB_ReadMixer_
mov    byte ptr ds:[_SB_OriginalVoiceVolumeLeft], al
ret

ENDP

PROC   SB_RestoreVoiceVolume_ NEAR
PUBLIC SB_RestoreVoiceVolume_

push   dx
mov    al, byte ptr ds:[_SB_MixerType]
cmp    al, SB_TYPE_SB16
je     restore_both_voice_volume
mov    ah, SB_MIXER_SBPROVOICE
cmp    al, SB_TYPE_SBPRO
je     restore_one_voice_volumne
cmp    al, SB_TYPE_SBPRO2
je     restore_one_voice_volumne
pop    dx
ret
restore_both_voice_volume:
mov    dl, byte ptr ds:[_SB_OriginalVoiceVolumeRight]
call   SB_WriteMixer_

mov    ah, SB_MIXER_SB16VOICELEFT
restore_one_voice_volumne:
mov    al, ah
mov    dl, byte ptr ds:[_SB_OriginalVoiceVolumeLeft]
call   SB_WriteMixer_
pop    dx
ret

ENDP

PROC   SB_DSP1xx_BeginPlayback_ NEAR
PUBLIC SB_DSP1xx_BeginPlayback_

;Program DSP to play sound
mov    al, 014h                 ; SB DAC 8 bit init, no autoinit
call   SB_WriteDSP_
jmp    write_size_to_dsp


PROC   SB_DSP2xx_BeginPlayback_ NEAR
PUBLIC SB_DSP2xx_BeginPlayback_

;Program DSP to play sound
mov    al, 048h                 ; set block length
call   SB_WriteDSP_
mov    al, ((SB_MIXBUFFERSIZE - 1 ) AND 0FFh)  ; 0FFh
call   SB_WriteDSP_
mov    al, ((SB_MIXBUFFERSIZE - 1 ) SHR 8)     ; 0 
call   SB_WriteDSP_
mov    al, 01Ch                 ; SB DAC init, 8 bit auto init
call   SB_WriteDSP_
ret

PROC   SB_DSP4xx_BeginPlayback_ NEAR
PUBLIC SB_DSP4xx_BeginPlayback_

mov    al, 0C6h                 ; 8 bit dac
call   SB_WriteDSP_
mov    al, SB_DSP_UNSIGNEDMONODATA ; transfer mode
call   SB_WriteDSP_

write_size_to_dsp:
mov    al, ((SB_MIXBUFFERSIZE - 1 ) AND 0FFh)  ; 0FFh
call   SB_WriteDSP_
mov    al, ((SB_MIXBUFFERSIZE - 1 ) SHR 8)     ; 0 
call   SB_WriteDSP_
ret





PROC    S_SBINIT_ENDMARKER_
PUBLIC  S_SBINIT_ENDMARKER_
ENDP

END
