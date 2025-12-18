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

PC_SPEAKER_SFX_DATA_TEMP_SEGMENT = 0D7E0h

EXTRN _sb_port:WORD


.CODE


PROC    S_SBINIT_STARTMARKER_
PUBLIC  S_SBINIT_STARTMARKER_
ENDP





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




PROC    S_SBINIT_ENDMARKER_
PUBLIC  S_SBINIT_ENDMARKER_
ENDP

END
