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
EXTRN SB_SetupDMABuffer_:NEAR
EXTRN locallib_dos_setvect_old_:NEAR

.DATA

PC_SPEAKER_SFX_DATA_TEMP_SEGMENT = 0D7E0h

EXTRN _sb_port:WORD
EXTRN _SB_MixerType:BYTE
EXTRN _sb_dma:BYTE
EXTRN _sb_irq:BYTE 
EXTRN _SB_IntController1Mask:BYTE 
EXTRN _SB_IntController2Mask:BYTE 
EXTRN _sb_dma_8:BYTE  ; todo clean up
EXTRN _SB_OriginalVoiceVolumeLeft:BYTE
EXTRN _SB_OriginalVoiceVolumeRight:BYTE
EXTRN _SB_DSP_Version:WORD
EXTRN _SB_CardActive:BYTE
EXTRN _SB_OldInt:DWORD
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

SB_DSP_SET_DA_RATE   = 041h
SB_DSP_SET_AD_RATE   = 042h


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

SB_MIXBUFFERSIZE      = 256
SB_TOTALBUFFERSIZE    = (SB_MIXBUFFERSIZE * 2)
SB_TRANSFERLENGTH     = SB_MIXBUFFERSIZE
SB_DOUBLEBUFFERLENGTH = SB_TRANSFERLENGTH * 2



; todo programattically determine?
RETRY_COUNT = 000FFh   

; page, address, length

_DMA_PORTINFO:
db 087h, 000h, 001h
db 083h, 002h, 003h
db 081h, 004h, 005h
db 082h, 006h, 007h
db 08Fh, 0C0h, 0C2h
db 08Bh, 0C4h, 0C6h
db 089h, 0C8h, 0CAh
db 08Ah, 0CCh, 0CEh

INVALID_IRQ = 0FFh

_IRQ_TO_INTERRUPT_MAP:
db    INVALID_IRQ, INVALID_IRQ, 00Ah, 	     00B
db    INVALID_IRQ, 00Dh, 	    INVALID_IRQ, 00Fh
db    INVALID_IRQ, INVALID_IRQ, 072h, 	     073h
db    074h, 	   INVALID_IRQ, INVALID_IRQ, 077h



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
ENDP


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

ENDP

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

ENDP

DMA_ERROR = 0
DMA_OK    = 1
DMA_MAXCHANNEL_16_BIT = 7

; todo optimize to carry flag once all uses in asm

PROC   SB_DMA_VerifyChannel_ NEAR
PUBLIC SB_DMA_VerifyChannel_

cmp    al, DMA_MAXCHANNEL_16_BIT
jg     return_dma_error
cmp    al, 2            ; invalid dma channel i guess
je     return_dma_error
cmp    al, 6            ; invalid dma channel i guess
je     return_dma_error
mov    al, DMA_OK
ret
return_dma_error:
mov    al, DMA_ERROR
ret

ENDP

; int16_t __near DMA_SetupTransfer(uint8_t channel, uint16_t length) {

PROC    DMA_SetupTransfer_ NEAR
PUBLIC  DMA_SetupTransfer_

push    bx
push    cx
mov     bx, ax  ; backup channel

;if (SB_DMA_VerifyChannel(channel) == DMA_OK) {
call    SB_DMA_VerifyChannel_   ; todo carry flag
test    al, al
jz      dma_return_error
mov     ax, bx  ; channel
shl     bx, 1
add     bx, ax  ; channel x3
add     bx, OFFSET _DMA_PORTINFO ; port = &DMA_PortInfo[channel];
mov     ah, al  ; store channel...


cmp     al, 3
mov     cx, 00A0Ch 
mov     al, 00Bh
jle     done_with_port_stuff
; greater than 3
do_16_bit_port_stuff:
mov     cx, 0D4D8h
mov     al, 0D6h
;       transfer_length = (length + 1) >> 1;
inc     dx
shr     dx, 1


done_with_port_stuff:

mov    byte ptr cs:[OFFSET SELFMODIFY_set_dma_channel_2 + 1], ch
mov    byte ptr cs:[OFFSET SELFMODIFY_set_dma_channel_1 + 1], ch
mov    byte ptr cs:[OFFSET SELFMODIFY_clear_flipflop_port + 1], cl
mov    byte ptr cs:[OFFSET SELFMODIFY_set_dma_mode_port + 1], al  ; TODO

mov    al, ah
and    al, 3  ; channel_select
push   ax   ; store channel select for later


dec    dx  ; 		transfer_length--;
mov    es, dx ; store transfer length
xor    dx, dx ; clear high bit. cwd maybe safe?

mov    cx, ((SB_DMABUFFER_SEGMENT SHL 4) AND 0FFFFh)
cmp    ah, 3
jle    skip_addr_shift
shr    cx, 1
skip_addr_shift:




SELFMODIFY_set_dma_channel_1:
mov    dl, 00h   
mov    ah, al ; backup channel_select
or     al, 4
out    dx, al  ; outp(channel < 4 ? 	0x0A: 0xD4, 4 | channel_select);
xor    al, al
SELFMODIFY_clear_flipflop_port:
mov    dl, 00h   
out    dx, al  ; outp(channel < 4 ? 	0x0C: 0xD8, 0);

mov    al, ah
SELFMODIFY_set_dma_mode_port:
mov    dl, 00h   
or     al, 058h
out    dx, al  ; outp(channel < 4 ? 	0x0B: 0xD6, 0x58 | channel_select);

; es stores transfer length
; bx has port arrray pointer
; cx has addr low bits

xchg   ax, cx


xor    dx, dx  ; clear high bits
mov    dl, byte ptr cs:[bx + 1]
out    dx, al    ; outp(port->address, addr.bu.fracbytelow);
mov    al, ah
out    dx, al    ; outp(port->address, addr.bu.fracbytehigh);

; Send page
mov    dl, byte ptr cs:[bx + 0]
mov    al, ((SB_DMABUFFER_SEGMENT SHR 12) AND 0FFh)
out    dx, al    ; outp(port->page, addr.bu.intbytehigh);

; Send length
mov    dl, byte ptr cs:[bx + 2]
mov    ax, es
out    dx, al    ; outp(port->length, transfer_length);		    // lo
mov    al, ah
out    dx, al    ; outp(port->length, transfer_length >> 8);	// hi

; enable DMA channel
SELFMODIFY_set_dma_channel_2:
mov    dl, 00h 
pop    ax     ; recover channel_sellect
out    dx, al       ;  outp(channel < 4 ? 	0x0A: 0xD4, channel_select);

        
mov    al, DMA_OK ; return DMA_OK        



dma_return_error:
pop     cx
pop     bx
ret
ENDP


PROC    SB_SetupDMABuffer2_ NEAR
PUBLIC  SB_SetupDMABuffer2_  ; todo carry

push    dx

xchg    ax, dx  ; dx gets buffer_size
mov     al, byte ptr ds:[_sb_dma_8]
call    DMA_SetupTransfer_
pop     dx
test    al, al
jz      dma_buffer_error
mov     al, byte ptr ds:[_sb_dma_8]
mov     byte ptr ds:[_sb_dma], al
; carry flag still on
xor     ax, ax  ; SB_OK
ret
dma_buffer_error:
mov     al, SB_ERROR
ret

ENDP




PROC    SB_EnableInterrupt_ NEAR
PUBLIC  SB_EnableInterrupt_ 

push    cx

mov     al, byte ptr ds:[_sb_irq]
mov     ah, 1
mov     cl, al
and     cl, 7
sal     ah, cl
not     ah     ; ah = ~ (1 << cl)
cmp     al, 8
jl      enable_irq_lt_8

in      al, 0A1h
and     al, ah
out     0A1h, al

mov     ah, (NOT 4)   ; & ~(1 << 2);


jmp     out_21_and_exit
enable_irq_lt_8:
;        mask = inp(0x21) & ~(1 << sb_irq);
;        outp(0x21, mask);



out_21_and_exit:
; mask in ah
;        outp(0x21, mask);

in      al, 021h
and     al, ah
out     021h, al

pop     cx
ret

ENDP



PROC    SB_DisableInterrupt_ NEAR
PUBLIC  SB_DisableInterrupt_ 

push    cx

mov     al, byte ptr ds:[_sb_irq]
mov     ch, byte ptr ds:[_SB_IntController1Mask]


mov     ah, 1
mov     cl, al
and     cl, 7
sal     ah, cl
not     ah     ; ah = 1 << cl
cmp     al, 8
in      al, 021h

jl      disable_irq_gte_8


and     al, ah
and     ch, ah
or      al, ch
out     021h, al
jmp     done_disabling

mov     ah, (NOT 4)   ; & ~(1 << 2);


jmp     out_21_and_exit

disable_irq_gte_8:

and     al, (NOT 4)
and     ch, (NOT 4)
or      al, ch   ; mask |= SB_IntController1Mask & (1 << sb_irq);
out     021h, al


in      al, 0A1h
and     al, ah
and     ah, byte ptr ds:[_SB_IntController2Mask]
or      al, ah
out     0A1h, al

done_disabling:

pop     cx
ret


ENDP

PROC    SB_DMA_EndTransfer_ NEAR
PUBLIC  SB_DMA_EndTransfer_  ; todo carry


push  dx
mov   dx, ax

call  SB_DMA_VerifyChannel_
cmp   al, DMA_OK
jne   return_dma_error_endtransfer

mov   al, dl
and   al, 3
cmp   al, dl
mov   dx, 0Ah
jne   use_high_channel_values; channel >= 4
jmp   do_end_transfer_write
use_high_channel_values:
inc   dx
inc   dx ; 0xA -> 0xC
do_end_transfer_write:
or    al, 4

; Mask off DMA channel
out   dx, al    ; outp(channel < 4 ? 	0x0A: 0xD4, 4 | (channel & 0x3));

; Clear flip-flop to lower byte with any data
shl   dl, 1
add   dl, 0C0h  ; 0A/0C have become D4/D8
xor   ax, ax
out   dx, al    ; outp(channel < 4 ? 	0x0C: 0xD8, 0);

mov   al, DMA_OK

return_dma_error_endtransfer:

pop   dx
ret

ENDP

PROC    SB_SetPlaybackRate_ NEAR
PUBLIC  SB_SetPlaybackRate_

push   dx

cmp    byte ptr ds:[_SB_DSP_Version+1], (SB_DSP_VERSION4XX SHR 8)
jl     do_lower_version_set_playback_rate
xchg   ax, dx

; set playback rate
mov    al, SB_DSP_SET_DA_RATE
call   SB_WriteDSP_
mov    al, dh
call   SB_WriteDSP_
mov    al, dl
call   SB_WriteDSP_

; set recording rate
mov    al, SB_DSP_SET_AD_RATE
call   SB_WriteDSP_
mov    al, dh
call   SB_WriteDSP_
mov    al, dl
call   SB_WriteDSP_

pop    dx
ret


do_lower_version_set_playback_rate:

cmp    ax, SAMPLE_RATE_22_KHZ_UINT
mov    dl, 0D2h
je     do_22_khz_setup
do_11_khz_setup:
mov    dl, 0A5h
do_22_khz_setup:
mov    al, 040h
call   SB_WriteDSP_
xchg   ax, dx
call   SB_WriteDSP_
pop    dx
ret

ENDP

PROC    SB_StopPlayback_ NEAR
PUBLIC  SB_StopPlayback_

call    SB_DisableInterrupt_
mov     al, SB_DSP_HALT8BITTRANSFER
call    SB_WriteDSP_  ; halt command
mov     al, byte ptr ds:[_sb_dma_8]
call    SB_DMA_EndTransfer_  ; Disable the DMA channel
mov     al, 0D3h
call    SB_WriteDSP_  ; speaker off
mov     byte ptr ds:[_SB_CardActive], 0
ret

ENDP

PROC   SB_SetupPlayback_ NEAR
PUBLIC SB_SetupPlayback_

call   SB_StopPlayback_
;call   SB_SetMixMode_
mov    ax, SB_TOTALBUFFERSIZE
call   SB_SetupDMABuffer_
cmp    al, SB_ERROR
je     failed_setup_playback

push   cx
push   di

; _fmemset(sb_dmabuffer, 0x80, SB_TotalBufferSize);
mov    ax, 08080h
mov    cx, SB_TOTALBUFFERSIZE / 2
mov    di, SB_DMABUFFER_SEGMENT
mov    es, di
xor    di, di
rep    stosw

pop    di
pop    cx

mov    ax, SAMPLE_RATE_11_KHZ_UINT
call   SB_SetPlaybackRate_
call   SB_EnableInterrupt_
mov    al, 0D1h
call   SB_WriteDSP_   ; turn on speaker

;  Program the sound card to start the transfer.
mov     al, byte ptr ds:[_SB_DSP_Version+1]
cmp     al, 2
jl      do_1xx_setup
cmp     al, 4
jl      do_2xx_setup

do_4xx_setup:
call    SB_DSP4xx_BeginPlayback_
jmp     done_with_setup
do_2xx_setup:
call    SB_DSP2xx_BeginPlayback_
jmp     done_with_setup
do_1xx_setup:
call    SB_DSP1xx_BeginPlayback_
done_with_setup:
mov     byte ptr ds:[_SB_CardActive], 1
mov     al, SB_OK

failed_setup_playback:
ret




ENDP


PROC    SB_GetDSPVersion_ NEAR
PUBLIC  SB_GetDSPVersion_

mov     al, 0E1h
call    SB_WriteDSP_  ; get version

call    SB_ReadDSP_
cmp     al, SB_ERROR
je      failed_getdspversion
mov     byte ptr ds:[_SB_DSP_Version+1], al
call    SB_ReadDSP_
cmp     al, SB_ERROR
je      failed_getdspversion
mov     byte ptr ds:[_SB_DSP_Version+0], al

mov     ah, byte ptr ds:[_SB_DSP_Version+1]
cmp     ah, 4
jge     set_ver_4
cmp     ah, 2
jg      set_ver_3

mov     byte ptr ds:[_SB_MixerType], SB_TYPE_NONE

failed_getdspversion:

ret
set_ver_4:
mov     byte ptr ds:[_SB_MixerType], SB_TYPE_SB16
ret
set_ver_3:
mov     byte ptr ds:[_SB_MixerType], SB_TYPE_SBPRO
ret

ENDP




PROC    SB_Shutdown_ NEAR
PUBLIC  SB_Shutdown_


call    SB_StopPlayback_
call    SB_RestoreVoiceVolume_
call    SB_ResetDSP_

push    bx
push    cx

xor     bx, bx
mov     bl, byte ptr ds:[_sb_irq]
mov     al, byte ptr cs:[_IRQ_TO_INTERRUPT_MAP + bx]
les     bx, dword ptr ds:[_SB_OldInt]
mov     cx, es
;locallib_dos_setvect_old(IRQ_TO_INTERRUPT_MAP[sb_irq], SB_OldInt);

call    locallib_dos_setvect_old_
pop     cx
pop     bx



ret

ENDP


PROC    S_SBINIT_ENDMARKER_
PUBLIC  S_SBINIT_ENDMARKER_
ENDP

END
