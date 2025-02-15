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

ADLIBINSTRUMENTLIST_SEGMENT = 0CC00h
ADLIBCHANNELS_SEGMENT       = 0CC3Fh
INSTRUMENTLOOKUP_SEGMENT    = 0CC51h

; donothing
;

	
PROC  donothing_ FAR
PUBLIC  donothing_

0x0000000000000000:  CB                retf  

ENDP


PROC  OPLwriteReg_ NEAR
PUBLIC  OPLwriteReg_

0x0000000000000002:  53                push  bx
0x0000000000000003:  51                push  cx
0x0000000000000004:  88 D3             mov   bl, dl
0x0000000000000006:  80 3E B1 0D 00    cmp   byte ptr ds:[_OPL3mode], 0
0x000000000000000b:  74 16             je    do_opl2_writereg
do_opl3_writereg:
0x000000000000000d:  BA 88 03          mov   dx, ADLIB_PORT
0x0000000000000010:  0A E4             or    ah, ah
0x0000000000000012:  74 02             je    dont_inc_port_2
0x0000000000000014:  42                inc   dx
0x0000000000000015:  42                inc   dx

dont_inc_port_2:
0x0000000000000016:  EE                out   dx, al
0x0000000000000017:  EC                in    al, dx
0x0000000000000018:  8A E0             mov   ah, al
0x000000000000001a:  42                inc   dx
0x000000000000001b:  8A C3             mov   al, bl
0x000000000000001d:  EE                out   dx, al
0x000000000000001e:  88 E0             mov   al, ah
0x0000000000000020:  59                pop   cx
0x0000000000000021:  5B                pop   bx
0x0000000000000022:  CB                ret  
do_opl2_writereg:
0x0000000000000023:  BA 88 03          mov   dx, ADLIB_PORT
0x0000000000000026:  EE                out   dx, al
0x0000000000000027:  B9 06 00          mov   cx, 6
loop_delay_1:
0x000000000000002a:  EC                in    al, dx
0x000000000000002b:  E2 FD             loop  loop_delay_1
0x000000000000002d:  42                inc   dx
0x000000000000002e:  8A C3             mov   al, bl
0x0000000000000030:  EE                out   dx, al
0x0000000000000031:  4A                dec   dx
0x0000000000000032:  B9 24 00          mov   cx, 36     ; delay amount
loop_delay_2
0x0000000000000035:  EC                in    al, dx
0x0000000000000036:  E2 FD             loop  loop_delay_2
0x0000000000000038:  59                pop   cx
0x0000000000000039:  5B                pop   bx
0x000000000000003a:  CB                ret  

ENDP

PROC  OPLwriteChannel_ NEAR
PUBLIC  OPLwriteChannel_


0x000000000000003c:  56                push  si
0x000000000000003d:  55                push  bp
0x000000000000003e:  89 E5             mov   bp, sp
0x0000000000000040:  83 EC 04          sub   sp, 4
0x0000000000000043:  88 46 FC          mov   byte ptr [bp - 4], al
0x0000000000000046:  88 5E FE          mov   byte ptr [bp - 2], bl
0x0000000000000049:  31 DB             xor   bx, bx
0x000000000000004b:  80 FA 09          cmp   dl, 9
0x000000000000004e:  72 06             jb    channel_below_9
0x0000000000000050:  BB 00 01          mov   bx, 0100h
0x0000000000000053:  80 EA 09          sub   dl, 9
channel_below_9:
0x0000000000000056:  30 F6             xor   dh, dh
0x0000000000000058:  89 D6             mov   si, dx
0x000000000000005a:  8A 84 B2 0D       mov   al, byte ptr ds:[si + _op_num]
0x000000000000005e:  30 E4             xor   ah, ah
0x0000000000000060:  89 C2             mov   dx, ax
0x0000000000000062:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x0000000000000065:  01 D0             add   ax, dx
0x0000000000000067:  01 C3             add   bx, ax
0x0000000000000069:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x000000000000006c:  30 E4             xor   ah, ah
0x000000000000006e:  89 C2             mov   dx, ax
0x0000000000000070:  89 D8             mov   ax, bx
0x0000000000000073:  E8 8C FF          call  OPLwriteReg_
0x0000000000000076:  88 C8             mov   al, cl
0x0000000000000078:  30 E4             xor   ah, ah
0x000000000000007a:  83 C3 03          add   bx, 3
0x000000000000007d:  89 C2             mov   dx, ax
0x000000000000007f:  89 D8             mov   ax, bx
0x0000000000000082:  E8 7D FF          call  OPLwriteReg_
0x0000000000000085:  C9                LEAVE_MACRO 
0x0000000000000086:  5E                pop   si
0x0000000000000087:  CB                ret



ENDP


PROC  OPLwriteFreq_ NEAR ; todo used only once, inline?
PUBLIC  OPLwriteFreq_


0x0000000000000088:  55                push  bp
0x0000000000000089:  89 E5             mov   bp, sp
0x000000000000008b:  83 EC 08          sub   sp, 8
0x000000000000008e:  88 46 FA          mov   byte ptr [bp - 6], al
0x0000000000000091:  89 56 F8          mov   word ptr [bp - 8], dx
0x0000000000000094:  88 5E FC          mov   byte ptr [bp - 4], bl
0x0000000000000097:  88 4E FE          mov   byte ptr [bp - 2], cl
0x000000000000009a:  8A 46 F8          mov   al, byte ptr [bp - 8]
0x000000000000009d:  8A 4E FA          mov   cl, byte ptr [bp - 6]
0x00000000000000a0:  30 E4             xor   ah, ah
0x00000000000000a2:  30 ED             xor   ch, ch
0x00000000000000a4:  89 C3             mov   bx, ax
0x00000000000000a6:  89 CA             mov   dx, cx
0x00000000000000a8:  B8 A0 00          mov   ax, 0A0h
0x00000000000000ac:  E8 EF 00          call  OPLwriteValue_
0x00000000000000af:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x00000000000000b2:  8B 56 F8          mov   dx, word ptr [bp - 8]
0x00000000000000b5:  30 E4             xor   ah, ah
0x00000000000000b7:  C1 EA 08          shr   dx, 8
0x00000000000000ba:  C1 E0 02          shl   ax, 2
0x00000000000000bd:  09 C2             or    dx, ax
0x00000000000000bf:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000000c2:  30 E4             xor   ah, ah
0x00000000000000c4:  C1 E0 05          shl   ax, 5
0x00000000000000c7:  09 D0             or    ax, dx
0x00000000000000c9:  30 E4             xor   ah, ah
0x00000000000000cb:  89 CA             mov   dx, cx
0x00000000000000cd:  89 C3             mov   bx, ax
0x00000000000000cf:  B8 B0 00          mov   ax, 0B0h
0x00000000000000d3:  E8 C8 00          call  OPLwriteValue_
0x00000000000000d6:  C9                LEAVE_MACRO 
0x00000000000000d7:  CB                ret  


ENDP


PROC  OPLconvertVolume_ NEAR
PUBLIC  OPLconvertVolume_

0x00000000000000d8:  53                push  bx
0x00000000000000d9:  88 D4             mov   ah, dl
0x00000000000000db:  B2 3F             mov   dl, 03Fh
0x00000000000000dd:  28 C2             sub   dl, al
0x00000000000000df:  88 E0             mov   al, ah
0x00000000000000e1:  24 7F             and   al, 07Fh
0x00000000000000e3:  98                cbw  
0x00000000000000e4:  89 C3             mov   bx, ax
0x00000000000000e6:  8A 87 BB 0D       mov   al, byte ptr ds:[bx + _noteVolumetable]
0x00000000000000ea:  88 D4             mov   ah, dl
0x00000000000000ec:  F6 E4             mul   ah
0x00000000000000ee:  89 C2             mov   dx, ax
0x00000000000000f0:  01 C2             add   dx, ax
0x00000000000000f2:  B0 3F             mov   al, 03Fh
0x00000000000000f4:  28 F0             sub   al, dh
0x00000000000000f6:  5B                pop   bx
0x00000000000000f7:  CB                ret  



ENDP


PROC  OPLpanVolume_ NEAR
PUBLIC  OPLpanVolume_


0x00000000000000f8:  53                push  bx
0x00000000000000f9:  88 C3             mov   bl, al
0x00000000000000fb:  88 D0             mov   al, dl
0x00000000000000fd:  84 D2             test  dl, dl
0x00000000000000ff:  7C 04             jl    pan_below_0
0x0000000000000101:  88 D8             mov   al, bl
0x0000000000000103:  5B                pop   bx
0x0000000000000104:  CB                ret
pan_below_0:
0x0000000000000105:  98                cbw  
0x0000000000000106:  89 C2             mov   dx, ax
0x0000000000000108:  88 D8             mov   al, bl
0x000000000000010a:  83 C2 40          add   dx, 64
0x000000000000010d:  98                cbw  
0x000000000000010e:  F7 EA             imul  dx
0x0000000000000110:  99                cwd
0x0000000000000111:  C1 E2 06          shl   dx, 6
0x0000000000000114:  1B C2             sbb   ax, dx
0x0000000000000116:  C1 F8 06          sar   ax, 6      ; / div 64
0x0000000000000119:  24 7F             and   al, 07Fh
0x000000000000011b:  5B                pop   bx
0x000000000000011c:  CB                ret  

ENDP


PROC  OPLwriteVolume_ NEAR
PUBLIC  OPLwriteVolume_


0x000000000000011e:  56                push  si
0x000000000000011f:  57                push  di
0x0000000000000120:  55                push  bp
0x0000000000000121:  89 E5             mov   bp, sp
0x0000000000000123:  83 EC 02          sub   sp, 2
0x0000000000000126:  88 46 FE          mov   byte ptr [bp - 2], al
0x0000000000000129:  89 CF             mov   di, cx
0x000000000000012b:  88 D0             mov   al, dl
0x000000000000012d:  98                cbw  
0x000000000000012e:  8E C7             mov   es, di
0x0000000000000130:  89 C1             mov   cx, ax
0x0000000000000132:  26 8A 47 0C       mov   al, byte ptr es:[bx + 0Ch] ; instr->level_2
0x0000000000000136:  89 CA             mov   dx, cx
0x0000000000000138:  30 E4             xor   ah, ah
0x000000000000013b:  E8 9A FF          call  OPLconvertVolume_
0x000000000000013e:  8E C7             mov   es, di
0x0000000000000140:  26 0A 47 0B       or    al, byte ptr es:[bx + 0Bh] ; instr->scale_2
0x0000000000000144:  30 E4             xor   ah, ah
0x0000000000000146:  89 C6             mov   si, ax
0x0000000000000148:  26 F6 47 06 01    test  byte ptr es:[bx + 6], 1     ; instr->feedback
0x000000000000014d:  75 22             jne   feedback_zero
0x000000000000014f:  26 8A 47 05       mov   al, byte ptr es:[bx + 5]    ; instr->level_1
do_writechannel_call:
0x0000000000000153:  8E C7             mov   es, di
0x0000000000000155:  26 8A 57 04       mov   dl, byte ptr es:[bx + 4]    ; instr->scale_1
0x0000000000000159:  30 F6             xor   dh, dh
0x000000000000015b:  89 F1             mov   cx, si
0x000000000000015d:  09 D0             or    ax, dx
0x000000000000015f:  8A 56 FE          mov   dl, byte ptr [bp - 2]
0x0000000000000162:  88 C3             mov   bl, al
0x0000000000000164:  B8 40 00          mov   ax, 040h
0x0000000000000167:  30 FF             xor   bh, bh
0x000000000000016a:  E8 CF FE          call  OPLwriteChannel_
0x000000000000016d:  C9                LEAVE_MACRO 
0x000000000000016e:  5F                pop   di
0x000000000000016f:  5E                pop   si
0x0000000000000170:  CB                ret  

feedback_zero:
0x0000000000000171:  89 CA             mov   dx, cx
0x0000000000000173:  26 8A 47 05       mov   al, byte ptr es:[bx + 5]   ;instr->level_1
0x0000000000000178:  E8 5D FF          call  OPLconvertVolume_
0x000000000000017b:  98                cbw  
0x000000000000017c:  EB D5             jmp   do_writechannel_call


ENDP


PROC  OPLwritePan_ FAR
PUBLIC  OPLwritePan_

0x000000000000017e:  88 C6             mov   dh, al
0x0000000000000180:  8E C1             mov   es, cx
0x0000000000000182:  80 FA DC          cmp   dl, -36
0x0000000000000185:  7C 38             jl    pan_less_than_minus_36
0x0000000000000187:  80 FA 24          cmp   dl, 36
0x000000000000018a:  7E 37             jle   pan_not_greater_than_36
0x000000000000018c:  B0 20             mov   al, PAN_RIGHT_CHANNEL
pan_capped:
0x000000000000018e:  26 8A 5F 06       mov   bl, byte ptr es:[bx + 6]
0x0000000000000192:  88 F2             mov   dl, dh
0x0000000000000194:  08 C3             or    bl, al
0x0000000000000196:  30 F6             xor   dh, dh
0x0000000000000198:  B8 C0 00          mov   ax, REGISTER_FEEDBACK
0x000000000000019b:  30 FF             xor   bh, bh

; fallthru
ENDP

PROC  OPLwriteValue_ FAR
PUBLIC  OPLwriteValue_


0x000000000000019e:  51                push  cx
0x000000000000019f:  88 C1             mov   cl, al
0x00000000000001a1:  88 D0             mov   al, dl
0x00000000000001a3:  30 E4             xor   ah, ah
0x00000000000001a5:  80 FA 09          cmp   dl, 9
0x00000000000001a8:  72 03             jb    dont_add_regnum_lookup_offset
0x00000000000001aa:  05 F7 00          add   ax, (0100h - 9)
dont_add_regnum_lookup_offset:
0x00000000000001ad:  88 DA             mov   dl, bl
0x00000000000001af:  30 F6             xor   dh, dh
0x00000000000001b1:  89 D3             mov   bx, dx
0x00000000000001b3:  88 CA             mov   dl, cl
0x00000000000001b5:  01 D0             add   ax, dx
0x00000000000001b7:  89 DA             mov   dx, bx
0x00000000000001ba:  E8 45 FE          call  OPLwriteReg_
0x00000000000001bd:  59                pop   cx
0x00000000000001be:  CB                retf  

; part of writepan
pan_less_than_minus_36:
0x00000000000001bf:  B0 10             mov   al, PAN_LEFT_CHANNEL
0x00000000000001c1:  EB CB             jmp   pan_capped
pan_not_greater_than_36:
0x00000000000001c3:  B0 30             mov   al, PAN_BOTH_CHANNELS
0x00000000000001c5:  EB C7             jmp   pan_capped
0x00000000000001c7:  FC                cld   

ENDP

PROC  OPLwriteInstrument_ FAR
PUBLIC  OPLwriteInstrument_


0x00000000000001c8:  52                push  dx
0x00000000000001c9:  56                push  si
0x00000000000001ca:  57                push  di
0x00000000000001cb:  55                push  bp
0x00000000000001cc:  89 E5             mov   bp, sp
0x00000000000001ce:  83 EC 02          sub   sp, 2
0x00000000000001d1:  89 DE             mov   si, bx
0x00000000000001d3:  89 CF             mov   di, cx
0x00000000000001d5:  C6 46 FF 00       mov   byte ptr [bp - 1], 0
0x00000000000001d9:  88 46 FE          mov   byte ptr [bp - 2], al
0x00000000000001dc:  B9 3F 00          mov   cx, 03Fh
0x00000000000001df:  8B 56 FE          mov   dx, word ptr [bp - 2]
0x00000000000001e2:  B8 40 00          mov   ax, REGISTER_VOLUME
0x00000000000001e5:  89 CB             mov   bx, cx
0x00000000000001e8:  E8 51 FE          call  OPLwriteChannel_
0x00000000000001eb:  8B 56 FE          mov   dx, word ptr [bp - 2]
0x00000000000001ee:  8E C7             mov   es, di
0x00000000000001f0:  B8 20 00          mov   ax, REGISTER_MODULATOR
0x00000000000001f3:  26 8A 4C 07       mov   cl, byte ptr es:[si + 7]   ; instr->trem_vibr_2
0x00000000000001f7:  26 8A 1C          mov   bl, byte ptr es:[si]       ; instr->trem_vibr_1
0x00000000000001fa:  30 ED             xor   ch, ch
0x00000000000001fc:  30 FF             xor   bh, bh
0x00000000000001ff:  E8 3A FE          call  OPLwriteChannel_
0x0000000000000202:  8B 56 FE          mov   dx, word ptr [bp - 2]
0x0000000000000205:  8E C7             mov   es, di
0x0000000000000207:  B8 60 00          mov   ax, REGISTER_ATTACK
0x000000000000020a:  26 8A 4C 08       mov   cl, byte ptr es:[si + 8]   ; instr->att_dec_2
0x000000000000020e:  26 8A 5C 01       mov   bl, byte ptr es:[si + 1]   ; instr->att_dec_1
0x0000000000000212:  30 ED             xor   ch, ch
0x0000000000000214:  30 FF             xor   bh, bh
0x0000000000000217:  E8 22 FE          call  OPLwriteChannel_
0x000000000000021a:  8B 56 FE          mov   dx, word ptr [bp - 2]
0x000000000000021d:  8E C7             mov   es, di
0x000000000000021f:  B8 80 00          mov   ax, REGISTER_SUSTAIN
0x0000000000000222:  26 8A 4C 09       mov   cl, byte ptr es:[si + 9]   ; instr->sust_rel_2
0x0000000000000226:  26 8A 5C 02       mov   bl, byte ptr es:[si + 2]   ; instr->sust_rel_1
0x000000000000022a:  30 ED             xor   ch, ch
0x000000000000022c:  30 FF             xor   bh, bh
0x000000000000022f:  E8 0A FE          call  OPLwriteChannel_
0x0000000000000232:  8B 56 FE          mov   dx, word ptr [bp - 2]
0x0000000000000235:  8E C7             mov   es, di
0x0000000000000237:  B8 E0 00          mov   ax, REGISTER_WAVEFORM
0x000000000000023a:  26 8A 4C 0A       mov   cl, byte ptr es:[si + 0Ah] ; instr->wave_2
0x000000000000023e:  26 8A 5C 03       mov   bl, byte ptr es:[si + 3]   ; instr->wave_1
0x0000000000000242:  30 ED             xor   ch, ch
0x0000000000000244:  30 FF             xor   bh, bh
0x0000000000000247:  E8 F2 FD          call  OPLwriteChannel_
0x000000000000024a:  8E C7             mov   es, di
0x000000000000024c:  26 8A 5C 06       mov   bl, byte ptr es:[si + 6]   ; instr->feedback
0x0000000000000250:  8B 56 FE          mov   dx, word ptr [bp - 2]
0x0000000000000253:  80 CB 30          or    bl, 030h
0x0000000000000256:  B8 C0 00          mov   ax, REGISTER_FEEDBACK
0x0000000000000259:  30 FF             xor   bh, bh
0x000000000000025c:  E8 3F FF          call  OPLwriteValue_
0x000000000000025f:  C9                LEAVE_MACRO 
0x0000000000000260:  5F                pop   di
0x0000000000000261:  5E                pop   si
0x0000000000000262:  5A                pop   dx
0x0000000000000263:  CB                retf  

ENDP

PROC  OPLinit_ FAR
PUBLIC  OPLinit_

0x0000000000000264:  88 16 B1 0D       mov   byte ptr ds:[_OPL3mode], dl
0x0000000000000268:  84 D2             test  dl, dl
0x000000000000026a:  74 03             je    oplinit_opl2      ; todo jne remove jmp
0x000000000000026c:  E9 8A 00          jmp   oplinit_opl3
oplinit_opl2:
0x000000000000026f:  C6 06 B0 0D 09    mov   byte ptr ds:[_OPLchannels], 9
finish_opl_init:
0x0000000000000274:  BA 20 00          mov   dx, REGISTER_MODULATOR
0x0000000000000277:  B8 01 00          mov   ax, 1
0x000000000000027b:  E8 84 FD          call  OPLwriteReg_
0x000000000000027e:  BA 40 00          mov   dx, REGISTER_VOLUME
0x0000000000000281:  B8 08 00          mov   ax, 8
0x0000000000000285:  E8 7A FD          call  OPLwriteReg_
0x0000000000000288:  B8 BD 00          mov   ax, 0BDh         ; set vibrato/tremolo depth to low, set melodic mode
0x000000000000028b:  31 D2             xor   dx, dx
0x000000000000028e:  E8 71 FD          call  OPLwriteReg_

; fallthru to oplshutup

ENDP

PROC  OPLshutup_ FAR
PUBLIC  OPLshutup_

0x0000000000000292:  53                push  bx
0x0000000000000293:  51                push  cx
0x0000000000000294:  52                push  dx
0x0000000000000295:  56                push  si
0x0000000000000296:  57                push  di
0x0000000000000297:  55                push  bp
0x0000000000000298:  89 E5             mov   bp, sp
0x000000000000029a:  83 EC 02          sub   sp, 2
0x000000000000029d:  C6 46 FE 00       mov   byte ptr [bp - 2], 0
0x00000000000002a1:  80 3E B0 0D 00    cmp   byte ptr ds:[_OPLchannels], 0
0x00000000000002a6:  76 4A             jbe   exit_opl_shutup
0x00000000000002a8:  BF 3F 00          mov   di, 03Fh               ; turn off volume
loop_shutup_next_channel:
0x00000000000002ab:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000002ae:  89 F9             mov   cx, di
0x00000000000002b0:  30 E4             xor   ah, ah
0x00000000000002b2:  89 FB             mov   bx, di
0x00000000000002b4:  89 C6             mov   si, ax
0x00000000000002b6:  89 C2             mov   dx, ax
0x00000000000002b8:  B8 40 00          mov   ax, REGISTER_VOLUME
0x00000000000002bc:  E8 7D FD          call  OPLwriteChannel_
0x00000000000002bf:  B9 FF 00          mov   cx, 0FFh               ; the fastest attack, decay
0x00000000000002c2:  B8 60 00          mov   ax, REGISTER_ATTACK
0x00000000000002c5:  89 F2             mov   dx, si
0x00000000000002c7:  89 CB             mov   bx, cx
0x00000000000002ca:  E8 6F FD          call  OPLwriteChannel_
0x00000000000002cd:  B9 0F 00          mov   cx, 03Fh               ; ... and release
0x00000000000002d0:  B8 80 00          mov   ax, REGISTER_SUSTAIN
0x00000000000002d3:  89 F2             mov   dx, si
0x00000000000002d5:  89 CB             mov   bx, cx
0x00000000000002d8:  E8 61 FD          call  OPLwriteChannel_
0x00000000000002db:  B8 B0 00          mov   ax, REGISTER_KEY_ON_OFF
0x00000000000002de:  89 F2             mov   dx, si
0x00000000000002e0:  31 DB             xor   bx, bx
0x00000000000002e2:  FE 46 FE          inc   byte ptr [bp - 2]
0x00000000000002e6:  E8 B5 FE          call  OPLwriteValue_
0x00000000000002e9:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000002ec:  3A 06 B0 0D       cmp   al, byte ptr ds:[_OPLchannels]
0x00000000000002f0:  72 B9             jb    loop_shutup_next_channel
exit_opl_shutup:
0x00000000000002f2:  C9                LEAVE_MACRO 
0x00000000000002f3:  5F                pop   di
0x00000000000002f4:  5E                pop   si
0x00000000000002f5:  5A                pop   dx
0x00000000000002f6:  59                pop   cx
0x00000000000002f7:  5B                pop   bx
0x00000000000002f8:  CB                retf  


ENDP

oplinit_opl3:
0x00000000000002f9:  BA 01 00          mov   dx, 1
0x00000000000002fc:  B8 05 01          mov   ax, 0105h      ; enable YMF262/OPL3 mode
0x00000000000002ff:  C6 06 B0 0D 12    mov   byte ptr ds:[_OPLchannels], 012h
0x0000000000000305:  E8 FA FC          call  OPLwriteReg_
0x0000000000000308:  B8 04 01          mov   ax, 0104h      ; disable 4-operator mode
0x000000000000030b:  31 D2             xor   dx, dx
0x000000000000030e:  E8 F1 FC          call  OPLwriteReg_
0x0000000000000311:  E9 60 FF          jmp   finish_opl_init


PROC  OPLdeinit_ FAR
PUBLIC  OPLdeinit_


0x0000000000000314:  52                push  dx
0x0000000000000316:  E8 79 FF          call  OPLshutup_
0x0000000000000319:  80 3E B1 0D 00    cmp   byte ptr ds:[_OPL3mode], 0
0x000000000000031e:  75 1E             jne   de_init_opl3
de_init_opl2:
0x0000000000000320:  BA 20 00          mov   dx, 020h       ; enable Waveform Select
0x0000000000000323:  B8 01 00          mov   ax, 1
0x0000000000000327:  E8 D8 FC          call  OPLwriteReg_
0x000000000000032a:  B8 08 00          mov   ax, 8          ; turn off CSW mode
0x000000000000032d:  31 D2             xor   dx, dx
0x0000000000000330:  E8 CF FC          call  OPLwriteReg_
0x0000000000000333:  B8 BD 00          mov   ax, 0BDh       ; set vibrato/tremolo depth to low, set melodic mode
0x0000000000000336:  31 D2             xor   dx, dx
0x0000000000000339:  E8 C6 FC          call  OPLwriteReg_
0x000000000000033c:  5A                pop   dx
0x000000000000033d:  CB                retf  
de_init_opl3:
0x000000000000033e:  B8 05 01          mov   ax, 0105h
0x0000000000000341:  31 D2             xor   dx, dx
0x0000000000000344:  E8 BB FC          call  OPLwriteReg_
0x0000000000000347:  B8 04 01          mov   ax, 0104h
0x000000000000034a:  31 D2             xor   dx, dx
0x000000000000034d:  E8 B2 FC          call  OPLwriteReg_
0x0000000000000350:  EB CE             jmp   de_init_opl2

ENDP

PROC  OPL2detect_ FAR
PUBLIC  OPL2detect_


0x0000000000000352:  53                push  bx
0x0000000000000353:  51                push  cx
0x0000000000000354:  52                push  dx
0x0000000000000355:  89 C1             mov   cx, ax
0x0000000000000357:  BA 60 00          mov   dx, 060h
0x000000000000035a:  B8 04 00          mov   ax, 4
0x000000000000035e:  E8 A1 FC          call  OPLwriteReg_
0x0000000000000361:  BA 80 00          mov   dx, 080h
0x0000000000000364:  B8 04 00          mov   ax, 4
0x0000000000000368:  E8 97 FC          call  OPLwriteReg_
0x000000000000036b:  89 CA             mov   dx, cx
0x000000000000036d:  EC                in    al, dx
0x000000000000036e:  2A E4             sub   ah, ah
0x0000000000000370:  BA FF 00          mov   dx, 0FFh
0x0000000000000373:  88 C7             mov   bh, al
0x0000000000000375:  B8 02 00          mov   ax, 2
0x0000000000000378:  80 E7 E0          and   bh, 0E0h
0x000000000000037c:  E8 83 FC          call  OPLwriteReg_
0x000000000000037f:  BA 21 00          mov   dx, 021h
0x0000000000000382:  B8 04 00          mov   ax, 4
0x0000000000000385:  B3 FF             mov   bl, 0FFh
0x0000000000000388:  E8 77 FC          call  OPLwriteReg_
0x000000000000038b:  89 CA             mov   dx, cx
0x000000000000038d:  FC                cld   
loop_delay_detect_opl2:
0x000000000000038e:  FE CB             dec   bl
0x0000000000000390:  74 05             je    done_with_loop_delay_detect_opl2
0x0000000000000392:  EC                in    al, dx
0x0000000000000393:  2A E4             sub   ah, ah
0x0000000000000395:  EB F7             jmp   loop_delay_detect_opl2
done_with_loop_delay_detect_opl2:
0x0000000000000397:  89 CA             mov   dx, cx
0x0000000000000399:  EC                in    al, dx
0x000000000000039a:  2A E4             sub   ah, ah
0x000000000000039c:  BA 60 00          mov   dx, 060h
0x000000000000039f:  88 C3             mov   bl, al
0x00000000000003a1:  B8 04 00          mov   ax, 4
0x00000000000003a5:  E8 5A FC          call  OPLwriteReg_
0x00000000000003a8:  BA 80 00          mov   dx, 080h
0x00000000000003ab:  B8 04 00          mov   ax, 4
0x00000000000003ae:  80 E3 E0          and   bl, 0E0h
0x00000000000003b2:  E8 4D FC          call  OPLwriteReg_
0x00000000000003b5:  84 FF             test  bh, bh
0x00000000000003b7:  75 0C             jne   return_opl2_not_detected
0x00000000000003b9:  80 FB C0          cmp   bl, 0C0h
0x00000000000003bc:  75 07             jne   return_opl2_not_detected
0x00000000000003be:  B8 01 00          mov   ax, 1
0x00000000000003c1:  5A                pop   dx
0x00000000000003c2:  59                pop   cx
0x00000000000003c3:  5B                pop   bx
0x00000000000003c4:  CB                retf  
return_opl2_not_detected:
0x00000000000003c5:  31 C0             xor   ax, ax
0x00000000000003c7:  5A                pop   dx
0x00000000000003c8:  59                pop   cx
0x00000000000003c9:  5B                pop   bx
0x00000000000003ca:  CB                retf  



ENDP

PROC  OPL3detect_ FAR
PUBLIC  OPL3detect_


0x00000000000003cc:  52                push  dx
0x00000000000003cd:  89 C2             mov   dx, ax
0x00000000000003d0:  E8 7F FF          call  OPL2detect_
0x00000000000003d3:  85 C0             test  ax, ax
0x00000000000003d5:  75 02             jne   continue_detecting_opl3
0x00000000000003d7:  5A                pop   dx
0x00000000000003d8:  CB                retf  
continue_detecting_opl3:
0x00000000000003d9:  EC                in    al, dx
0x00000000000003da:  2A E4             sub   ah, ah
0x00000000000003dc:  A8 04             test  al, 4

0x00000000000003de:  74 04             je    return_opl3_detected
0x00000000000003e0:  31 C0             xor   ax, ax
0x00000000000003e2:  5A                pop   dx
0x00000000000003e3:  CB                retf  
return_opl3_detected:
0x00000000000003e4:  B8 01 00          mov   ax, 1
0x00000000000003e7:  5A                pop   dx
0x00000000000003e8:  CB                retf  


ENDP

ENDP


PROC  writeFrequency_ FAR       ; two inlined writevalues? todo 
PUBLIC  writeFrequency_

;void writeFrequency(uint8_t slot, uint8_t note, uint8_t pitchwheel, uint8_t keyOn){
; al = slot
; dl = note
; bl = pitchwheel
; cl = keyon

0x00000000000003ea:  56                push  si
0x00000000000003eb:  57                push  di
0x00000000000003ec:  55                push  bp
0x00000000000003ed:  89 E5             mov   bp, sp
0x00000000000003ef:  83 EC 08          sub   sp, 8
0x00000000000003f2:  88 46 FE          mov   byte ptr [bp - 2], al
0x00000000000003f5:  88 DF             mov   bh, bl
0x00000000000003f7:  88 4E FC          mov   byte ptr [bp - 4], cl
0x00000000000003fa:  80 FA 07          cmp   dl, 7
0x00000000000003fd:  73 63             jae   note_greater_than_7
0x00000000000003ff:  30 F6             xor   dh, dh
0x0000000000000401:  89 D6             mov   si, dx
0x0000000000000403:  01 D6             add   si, dx
0x0000000000000405:  30 DB             xor   bl, bl
0x0000000000000407:  8B B4 3C 0E       mov   si, word ptr ds:[si + _freqtable]

freq_and_octave_ready:
0x000000000000040b:  80 FF 80          cmp   bh, DEFAULT_PITCH_BEND
0x000000000000040e:  74 35             je    skip_pitch_wheel_calculation
0x0000000000000410:  88 F8             mov   al, bh
0x0000000000000412:  30 E4             xor   ah, ah
0x0000000000000414:  89 C7             mov   di, ax
0x0000000000000416:  8A 85 62 0E       mov   al, byte ptr ds:[di + _pitchwheeltable]
0x000000000000041a:  BA 80 00          mov   dx, DEFAULT_PITCH_BEND
0x000000000000041d:  98                cbw  
0x000000000000041e:  29 C2             sub   dx, ax
0x0000000000000420:  89 F0             mov   ax, si
0x0000000000000422:  F7 E2             mul   dx
0x0000000000000424:  89 56 FA          mov   word ptr [bp - 6], dx
0x0000000000000427:  89 46 F8          mov   word ptr [bp - 8], ax
0x000000000000042a:  8A 46 FB          mov   al, byte ptr [bp - 5]
0x000000000000042d:  A8 80             test  al, 080h
0x000000000000042f:  74 4D             je    zero_last_bit
0x0000000000000431:  BE 01 00          mov   si, 1      ; si holds that one bit...
got_last_bit:
0x0000000000000434:  8B 46 F9          mov   ax, word ptr [bp - 7]
0x0000000000000437:  01 C0             add   ax, ax
0x0000000000000439:  01 C6             add   si, ax
0x000000000000043b:  81 FE 00 04       cmp   si, 1024
0x000000000000043f:  72 04             jb    skip_pitch_wheel_calculation
0x0000000000000441:  D1 EE             shr   si, 1
0x0000000000000443:  FE C3             inc   bl
skip_pitch_wheel_calculation:
0x0000000000000445:  80 FB 07          cmp   bl, 7
0x0000000000000448:  76 02             jbe   octave_lower_than_7
0x000000000000044a:  B3 07             mov   bl, 7
octave_lower_than_7:
0x000000000000044c:  8A 4E FC          mov   cl, byte ptr [bp - 4]
0x000000000000044f:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000000452:  89 F2             mov   dx, si
0x0000000000000454:  30 FF             xor   bh, bh
0x0000000000000456:  30 ED             xor   ch, ch
0x0000000000000458:  30 E4             xor   ah, ah
0x000000000000045b:  E8 2A FC          call  OPLwriteFreq_       ; todo only use, inline
0x000000000000045e:  C9                LEAVE_MACRO 
0x000000000000045f:  5F                pop   di
0x0000000000000460:  5E                pop   si
0x0000000000000461:  CB                retf  

note_greater_than_7:

0x0000000000000462:  30 F6             xor   dh, dh
0x0000000000000464:  89 D0             mov   ax, dx
0x0000000000000466:  B2 0C             mov   dl, 12
0x0000000000000468:  2D 07 00          sub   ax, 7
0x000000000000046b:  F6 F2             div   dl
0x000000000000046d:  89 C1             mov   cx, ax
0x000000000000046f:  88 E0             mov   al, ah
0x0000000000000471:  98                cbw  
0x0000000000000472:  89 C6             mov   si, ax
0x0000000000000474:  01 C6             add   si, ax
0x0000000000000476:  88 CB             mov   bl, cl
0x0000000000000478:  8B B4 4A 0E       mov   si, word ptr ds:[si + _freqtable2]
0x000000000000047c:  EB 8D             jmp   freq_and_octave_ready
zero_last_bit:
0x000000000000047e:  31 F6             xor   si, si
0x0000000000000480:  EB B2             jmp   got_last_bit

ENDP

PROC  writeModulation_ FAR
PUBLIC  writeModulation_

0x0000000000000482:  55                push  bp
0x0000000000000483:  89 E5             mov   bp, sp
0x0000000000000485:  83 EC 02          sub   sp, 2
0x0000000000000488:  88 46 FE          mov   byte ptr [bp - 2], al
0x000000000000048b:  8E C1             mov   es, cx
0x000000000000048d:  84 D2             test  dl, dl
0x000000000000048f:  74 02             je    dont_enable_vibrato
0x0000000000000491:  B2 40             mov   dl, 040h       ; frequency vibrato
dont_enable_vibrato:
0x0000000000000493:  26 8A 47 07       mov   al, byte ptr es:[bx + 7]   ; instr->trem_vibr_2
0x0000000000000497:  08 D0             or    al, dl
0x0000000000000499:  30 E4             xor   ah, ah
0x000000000000049b:  89 C1             mov   cx, ax
0x000000000000049d:  26 F6 47 06 01    test  byte ptr es:[bx + 6], 1    ; instr->feedback
0x00000000000004a2:  74 1B             je    feedback_one
0x00000000000004a4:  26 8A 1F          mov   bl, byte ptr es:[bx]
0x00000000000004a7:  30 FF             xor   bh, bh
0x00000000000004a9:  89 D8             mov   ax, bx
0x00000000000004ab:  08 D0             or    al, dl
feedback_checked:
0x00000000000004ad:  8A 56 FE          mov   dl, byte ptr [bp - 2]
0x00000000000004b0:  88 C3             mov   bl, al
0x00000000000004b2:  B8 20 00          mov   ax, 020h
0x00000000000004b5:  30 FF             xor   bh, bh
0x00000000000004b7:  30 F6             xor   dh, dh
0x00000000000004ba:  E8 7F FB          call  OPLwriteChannel_
0x00000000000004bd:  C9                LEAVE_MACRO 
0x00000000000004be:  CB                retf  
feedback_one:
0x00000000000004bf:  26 8A 07          mov   al, byte ptr es:[bx]   ; instr->trem_vibr_1
0x00000000000004c2:  EB E9             jmp   feedback_checked

ENDP



PROC  calcVolumeOPL_ FAR
PUBLIC  calcVolumeOPL_

; dx = system volume
; al = channel volume


0x00000000000004c4:  88 DC             mov   ah, bl
0x00000000000004c6:  C1 E2 02          shl   dx, 2
0x00000000000004c9:  F6 E4             mul   ah
0x00000000000004cb:  F7 E2             mul   dx
0x00000000000004cd:  88 E3             mov   bl, ah
0x00000000000004cf:  88 D7             mov   bh, dl
0x00000000000004d1:  B2 7F             mov   dl, 127
0x00000000000004d3:  89 D8             mov   ax, bx
0x00000000000004d5:  F6 F2             div   dl
0x00000000000004d7:  89 C3             mov   bx, ax
0x00000000000004d9:  3C 7F             cmp   al, 07Fh
0x00000000000004db:  76 02             jbe   already_below_127
0x00000000000004dd:  B0 7F             mov   al, 07Fh
already_below_127:
0x00000000000004df:  CB                retf  


ENDP

CH_SECONDARY = 1
MOD_MIN      = 40
CH_VIBRATO   = 4
PERCUSSION_CHANNEL = 15
FL_FIXED_PITCH = 1


PROC  occupyChannel_ FAR
PUBLIC  occupyChannel_

0x00000000000004e0:  56                push  si
0x00000000000004e1:  57                push  di
0x00000000000004e2:  55                push  bp
0x00000000000004e3:  89 E5             mov   bp, sp
0x00000000000004e5:  83 EC 0E          sub   sp, 0Eh
0x00000000000004e8:  8B 7E 0A          mov   di, word ptr [bp + 0Ah]
0x00000000000004eb:  88 46 FC          mov   byte ptr [bp - 4], al
0x00000000000004ee:  88 56 FE          mov   byte ptr [bp - 2], dl
0x00000000000004f1:  88 5E FA          mov   byte ptr [bp - 6], bl
0x00000000000004f4:  88 C8             mov   al, cl
0x00000000000004f6:  8A 5E FC          mov   bl, byte ptr [bp - 4]
0x00000000000004f9:  C7 46 F6 3F CC    mov   word ptr [bp - 0Ah], ADLIBCHANNELS_SEGMENT
0x00000000000004fe:  30 FF             xor   bh, bh
0x0000000000000500:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x0000000000000503:  C1 E3 04          shl   bx, 4
0x0000000000000506:  8A 66 FA          mov   ah, byte ptr [bp - 6]
0x0000000000000509:  26 88 17          mov   byte ptr es:[bx], dl
0x000000000000050c:  89 DE             mov   si, bx
0x000000000000050e:  26 88 67 01       mov   byte ptr es:[bx + 1], ah
0x0000000000000512:  80 7E 0E 00       cmp   byte ptr [bp + 0Eh], 0
0x0000000000000516:  75 03             jne   set_channel_secondary_flag_on
0x000000000000067a:  31 D2             xor   dx, dx
0x000000000000067c:  E9 9F FE          jmp   set_channel_secondary_flag
set_channel_secondary_flag_on:
0x000000000000051b:  BA 01 00          mov   dx, CH_SECONDARY
set_channel_secondary_flag:
0x000000000000051e:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000000521:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x0000000000000524:  30 FF             xor   bh, bh
0x0000000000000526:  26 88 54 02       mov   byte ptr es:[si + 2], dl   ; ch->flags
0x000000000000052a:  80 BF 30 17 28    cmp   byte ptr [bx _OPL2driverdata + 060h], MOD_MIN                ; channelModulation
0x000000000000052f:  72 05             jb    dont_set_vibrato
0x0000000000000531:  26 80 4C 02 04    or    byte ptr es:[si + 2], CH_VIBRATO
dont_set_vibrato:
0x0000000000000536:  8B 16 A4 0D       mov   dx, word ptr ds:[_playingtime]
0x000000000000053a:  8B 1E A6 0D       mov   bx, word ptr ds:[_playingtime + 2]
0x000000000000053e:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x0000000000000541:  26 89 54 0C       mov   word ptr es:[si + 0Ch], dx
0x0000000000000545:  26 89 5C 0E       mov   word ptr es:[si + 0Eh], bx

;   if (noteVolume == -1){
;		noteVolume = OPL2driverdata.channelLastVolume[channel];
;	} else{
;		OPL2driverdata.channelLastVolume[channel] = noteVolume;
;	}

0x0000000000000549:  3C FF             cmp   al, -1
0x000000000000054b:  74 03             je    use_last_volum
0x000000000000067f:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000000682:  30 FF             xor   bh, bh
0x0000000000000684:  88 87 F0 16       mov   byte ptr [bx + _OPL2driverdata + 020h], al     ; channelLastVolume
0x0000000000000688:  E9 CE FE          jmp   volume_is_set
use_last_volume:
0x0000000000000550:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000000553:  30 FF             xor   bh, bh
0x0000000000000555:  8A 87 F0 16       mov   al, byte ptr [bx + _OPL2driverdata + 020h]     ; channelLastVolume
volume_is_set:
0x0000000000000559:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x000000000000055c:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x000000000000055f:  8A 16 48 21       mov   dl, byte ptr ds:[_snd_MusicVolume]
0x0000000000000563:  30 FF             xor   bh, bh
0x0000000000000565:  26 88 44 06       mov   byte ptr es:[si + 6], al
0x0000000000000569:  98                cbw  
0x000000000000056a:  30 F6             xor   dh, dh
0x000000000000056c:  89 C1             mov   cx, ax
0x000000000000056e:  8A 87 E0 16       mov   al, byte ptr [bx + _OPL2driverdata + 010h]     ; channelVolume
0x0000000000000572:  89 CB             mov   bx, cx
0x0000000000000574:  30 E4             xor   ah, ah
0x0000000000000577:  E8 4A FF          call  calcVolumeOPL_
0x000000000000057a:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x000000000000057d:  26 88 44 07       mov   byte ptr es:[si + 7], al
0x0000000000000581:  8E 46 0C          mov   es, word ptr [bp + 0Ch]
0x0000000000000584:  26 F6 05 01       test  byte ptr es:[di], FL_FIXED_PITCH
0x0000000000000588:  75 03             jne   set_note_to_instrument_note
0x000000000000068b:  80 7E FE 0F       cmp   byte ptr [bp - 2], PERCUSSION_CHANNEL
0x000000000000068f:  74 03             jne   set_note
0x0000000000000694:  C6 46 FA 3C       mov   byte ptr [bp - 6], 60    ; C-5
0x0000000000000698:  E9 F9 FE          jmp   set_note
set_note_to_instrument_note:
0x000000000000058d:  26 8A 45 03       mov   al, byte ptr es:[di + 3]
0x0000000000000591:  88 46 FA          mov   byte ptr [bp - 6], al
set_note:
0x0000000000000594:  80 7E 0E 00       cmp   byte ptr [bp + 0Eh], 0
0x0000000000000598:  75 03             jne   lookup_instrument_finetune
use_fixed_pitch:
0x00000000000006ad:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x00000000000006b0:  26 C6 44 05 80    mov   byte ptr es:[si + 5], DEFAULT_PITCH_BEND
0x00000000000006b5:  E9 F9 FE          jmp   finetune_set
lookup_instrument_finetune:
0x000000000000059d:  8E 46 0C          mov   es, word ptr [bp + 0Ch]
0x00000000000005a0:  26 F6 05 04       test  byte ptr es:[di], 4
0x00000000000005a4:  74 F4             je    use_fixed_pitch
0x00000000000005a6:  26 8A 45 02       mov   al, byte ptr es:[di + 2]
0x00000000000005aa:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x00000000000005ad:  26 88 44 05       mov   byte ptr es:[si + 5], al
finetune_set:
0x00000000000005b1:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000005b4:  30 FF             xor   bh, bh
0x00000000000005b6:  8A 87 10 17       mov   al, byte ptr [bx + _OPL2driverdata + 030h]     ; channelpitch
0x00000000000005ba:  98                cbw  
0x00000000000005bb:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x00000000000005be:  89 C2             mov   dx, ax
0x00000000000005c0:  26 8A 44 05       mov   al, byte ptr es:[si + 5]
0x00000000000005c4:  98                cbw  
0x00000000000005c5:  01 D0             add   ax, dx
0x00000000000005c7:  26 88 44 04       mov   byte ptr es:[si + 4], al
0x00000000000005cb:  80 7E 0E 00       cmp   byte ptr [bp + 0Eh], 0
0x00000000000005cf:  75 03             jne   use_secondary
0x00000000000006b8:  8B 46 0C          mov   ax, word ptr [bp + 0Ch]    ; todo commonize this with below
0x00000000000006bb:  83 C7 04          add   di, 4
0x00000000000006be:  E9 19 FF          jmp   instr_set:
use_secondary:
0x00000000000005d4:  8B 46 0C          mov   ax, word ptr [bp + 0Ch]
0x00000000000005d7:  83 C7 14          add   di, 014h
instr_set:
0x00000000000005da:  89 46 F8          mov   word ptr [bp - 8], ax
0x00000000000005dd:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x00000000000005e0:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x00000000000005e3:  26 89 7C 08       mov   word ptr es:[si + 8], di
0x00000000000005e7:  26 89 44 0A       mov   word ptr es:[si + 0Ah], ax
0x00000000000005eb:  8E C0             mov   es, ax
0x00000000000005ed:  26 8A 45 0E       mov   al, byte ptr es:[di + 0Eh]
0x00000000000005f1:  00 46 FA          add   byte ptr [bp - 6], al
0x00000000000005f4:  80 66 FA 7F       and   byte ptr [bp - 6], 07Fh
0x00000000000005f8:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x00000000000005fb:  8A 46 FA          mov   al, byte ptr [bp - 6]
0x00000000000005fe:  C6 46 F3 00       mov   byte ptr [bp - 0Dh], 0
0x0000000000000602:  26 88 44 03       mov   byte ptr es:[si + 3], al
0x0000000000000606:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x0000000000000609:  8B 4E F8          mov   cx, word ptr [bp - 8]
0x000000000000060c:  88 46 F2          mov   byte ptr [bp - 0Eh], al
0x000000000000060f:  89 FB             mov   bx, di
0x0000000000000611:  8B 46 F2          mov   ax, word ptr [bp - 0Eh]
0x0000000000000615:  E8 B0 FB          call  OPLwriteInstrument_
0x0000000000000618:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x000000000000061b:  26 F6 44 02 04    test  byte ptr es:[si + 2], CH_VIBRATO
0x0000000000000620:  75 79             jne   writevibrato
done_with_vibrato:
0x0000000000000622:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000000625:  8A 56 FC          mov   dl, byte ptr [bp - 4]
0x0000000000000628:  8B 4E F8          mov   cx, word ptr [bp - 8]
0x000000000000062b:  30 FF             xor   bh, bh
0x000000000000062d:  88 56 F4          mov   byte ptr [bp - 0Ch], dl
0x0000000000000630:  8A 87 00 17       mov   al, byte ptr [bx + _OPL2driverdata + 020h]
0x0000000000000634:  88 7E F5          mov   byte ptr [bp - 0Bh], bh
0x0000000000000637:  98                cbw  
0x0000000000000638:  89 FB             mov   bx, di
0x000000000000063a:  89 C2             mov   dx, ax
0x000000000000063c:  8B 46 F4          mov   ax, word ptr [bp - 0Ch]
0x0000000000000640:  E8 3B FB          call  OPLwritePan_
0x0000000000000643:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x0000000000000646:  26 8A 44 07       mov   al, byte ptr es:[si + 7]
0x000000000000064a:  8B 4E F8          mov   cx, word ptr [bp - 8]
0x000000000000064d:  98                cbw  
0x000000000000064e:  89 FB             mov   bx, di
0x0000000000000650:  89 C2             mov   dx, ax
0x0000000000000652:  8B 46 F4          mov   ax, word ptr [bp - 0Ch]
0x0000000000000656:  E8 C5 FA          call  OPLwriteVolume_
0x0000000000000659:  8E 46 F6          mov   es, word ptr [bp - 0Ah]
0x000000000000065c:  8A 56 FA          mov   dl, byte ptr [bp - 6]
0x000000000000065f:  B9 01 00          mov   cx, 1
0x0000000000000662:  8B 46 F4          mov   ax, word ptr [bp - 0Ch]
0x0000000000000665:  26 8A 5C 04       mov   bl, byte ptr es:[si + 4]
0x0000000000000669:  30 F6             xor   dh, dh
0x000000000000066b:  30 FF             xor   bh, bh
0x000000000000066e:  E8 79 FD          call  writeFrequency_
0x0000000000000671:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x0000000000000674:  C9                LEAVE_MACRO 
0x0000000000000675:  5F                pop   di
0x0000000000000676:  5E                pop   si
0x0000000000000677:  CA 06 00          retf  6

writevibrato:
0x000000000000069b:  BA 01 00          mov   dx, 1
0x000000000000069e:  8B 4E F8          mov   cx, word ptr [bp - 8]
0x00000000000006a1:  8B 46 F2          mov   ax, word ptr [bp - 0Eh]
0x00000000000006a4:  89 FB             mov   bx, di
0x00000000000006a7:  E8 D8 FD          call  writeModulation_
0x00000000000006aa:  E9 75 FF          jmp   done_with_vibrato


ENDP

PROC  releaseChannel_ FAR
PUBLIC  releaseChannel_


0x00000000000006c2:  53                push  bx
0x00000000000006c3:  51                push  cx
0x00000000000006c4:  56                push  si
0x00000000000006c5:  57                push  di
0x00000000000006c6:  55                push  bp
0x00000000000006c7:  89 E5             mov   bp, sp
0x00000000000006c9:  83 EC 04          sub   sp, 4
0x00000000000006cc:  88 56 FE          mov   byte ptr [bp - 2], dl
0x00000000000006cf:  C6 46 FD 00       mov   byte ptr [bp - 3], 0
0x00000000000006d3:  BF 3F CC          mov   di, ADLIBCHANNELS_SEGMENT
0x00000000000006d6:  88 46 FC          mov   byte ptr [bp - 4], al
0x00000000000006d9:  31 C9             xor   cx, cx
0x00000000000006db:  8B 76 FC          mov   si, word ptr [bp - 4]
0x00000000000006de:  8E C7             mov   es, di
0x00000000000006e0:  C1 E6 04          shl   si, 4
0x00000000000006e3:  8B 46 FC          mov   ax, word ptr [bp - 4]
0x00000000000006e6:  26 8A 5C 04       mov   bl, byte ptr es:[si + 4]
0x00000000000006ea:  26 8A 54 03       mov   dl, byte ptr es:[si + 3]
0x00000000000006ee:  30 FF             xor   bh, bh
0x00000000000006f0:  30 F6             xor   dh, dh
0x00000000000006f3:  E8 F4 FC          call  writeFrequency_
0x00000000000006f6:  8E C7             mov   es, di
0x00000000000006f8:  26 C6 44 02 80    mov   byte ptr es:[si + 2], CH_FREE
0x00000000000006fd:  26 80 0C 80       or    byte ptr es:[si], CH_FREE
0x0000000000000701:  80 7E FE 00       cmp   byte ptr [bp - 2], 0
0x0000000000000705:  75 06             jne   kill_channel
0x0000000000000707:  C9                LEAVE_MACRO 
0x0000000000000708:  5F                pop   di
0x0000000000000709:  5E                pop   si
0x000000000000070a:  59                pop   cx
0x000000000000070b:  5B                pop   bx
0x000000000000070c:  CB                retf  
kill_channel:
0x000000000000070d:  B9 0F 00          mov   cx, 0Fh
0x0000000000000710:  8B 56 FC          mov   dx, word ptr [bp - 4]
0x0000000000000713:  B8 80 00          mov   ax, REGISTER_SUSTAIN
0x0000000000000716:  89 CB             mov   bx, cx
0x0000000000000719:  E8 20 F9          call  OPLwriteChannel_
0x000000000000071c:  B9 3F 00          mov   cx, 03Fh
0x000000000000071f:  8B 56 FC          mov   dx, word ptr [bp - 4]
0x0000000000000722:  B8 40 00          mov   ax, REGISTER_VOLUME
0x0000000000000725:  89 CB             mov   bx, cx
0x0000000000000728:  E8 11 F9          call  OPLwriteChannel_
0x000000000000072b:  C9                LEAVE_MACRO 
0x000000000000072c:  5F                pop   di
0x000000000000072d:  5E                pop   si
0x000000000000072e:  59                pop   cx
0x000000000000072f:  5B                pop   bx
0x0000000000000730:  CB                retf  


ENDP

PROC  releaseSustain_ FAR
PUBLIC  releaseSustain_

0x0000000000000732:  53                push  bx
0x0000000000000733:  52                push  dx
0x0000000000000734:  56                push  si
0x0000000000000735:  88 C7             mov   bh, al
0x0000000000000737:  30 DB             xor   bl, bl
0x0000000000000739:  80 3E B0 0D 00    cmp   byte ptr ds:[_OPLchannels], 0
0x000000000000073e:  76 2C             jbe   exit_release_sustain
loop_release_sustain:
0x0000000000000740:  88 D8             mov   al, bl
0x0000000000000742:  30 E4             xor   ah, ah
0x0000000000000744:  89 C2             mov   dx, ax
0x0000000000000746:  BE 3F CC          mov   si, ADLIBCHANNELS_SEGMENT
0x0000000000000749:  C1 E2 04          shl   dx, 4
0x000000000000074c:  8E C6             mov   es, si
0x000000000000074e:  89 D6             mov   si, dx
0x0000000000000750:  26 3A 3C          cmp   bh, byte ptr es:[si]
0x0000000000000753:  75 0F             jne   skip_release_channel
0x0000000000000755:  83 C6 02          add   si, 2
0x0000000000000758:  26 F6 04 02       test  byte ptr es:[si], 2
0x000000000000075c:  74 06             je    skip_release_channel
0x000000000000075e:  31 D2             xor   dx, dx
0x0000000000000761:  E8 5E FF          call  releaseChannel_
skip_release_channel:
0x0000000000000764:  FE C3             inc   bl
0x0000000000000766:  3A 1E B0 0D       cmp   bl, byte ptr ds:[_OPLchannels]
0x000000000000076a:  72 D4             jb    loop_release_sustain
exit_release_sustain:
0x000000000000076c:  5E                pop   si
0x000000000000076d:  5A                pop   dx
0x000000000000076e:  5B                pop   bx
0x000000000000076f:  CB                retf  

ENDP

PROC  findFreeChannel_ FAR
PUBLIC  findFreeChannel_

0x0000000000000770:  53                push  bx
0x0000000000000771:  51                push  cx
0x0000000000000772:  52                push  dx
0x0000000000000773:  56                push  si
0x0000000000000774:  57                push  di
0x0000000000000775:  55                push  bp
0x0000000000000776:  89 E5             mov   bp, sp
0x0000000000000778:  83 EC 04          sub   sp, 4
0x000000000000077b:  88 46 FC          mov   byte ptr [bp - 4], al
0x000000000000077e:  C6 46 FE FF       mov   byte ptr [bp - 2], 0xff
0x0000000000000782:  8B 3E A4 0D       mov   di, word ptr ds:[_playingtime]
0x0000000000000786:  8B 16 A6 0D       mov   dx, word ptr ds:[_playingtime + 2]
0x000000000000078a:  30 DB             xor   bl, bl
0x000000000000078c:  80 3E B0 0D 00    cmp   byte ptr ds:[_OPLchannels], 0
0x0000000000000791:  76 30             jbe   0x7c3
0x0000000000000793:  B9 3F CC          mov   cx, ADLIBCHANNELS_SEGMENT
0x0000000000000796:  FE 06 5A 10       inc   byte ptr ds:[_lastfreechannel]
0x000000000000079a:  A0 5A 10          mov   al, byte ptr ds:[_lastfreechannel]
0x000000000000079d:  3A 06 B0 0D       cmp   al, byte ptr ds:[_OPLchannels]
0x00000000000007a1:  75 03             jne   0x7a6
0x00000000000007a3:  E9 7B 00          jmp   0x821
0x00000000000007a6:  A0 5A 10          mov   al, byte ptr ds:[_lastfreechannel]
0x00000000000007a9:  30 E4             xor   ah, ah
0x00000000000007ab:  89 C6             mov   si, ax
0x00000000000007ad:  C1 E6 04          shl   si, 4
0x00000000000007b0:  8E C1             mov   es, cx
0x00000000000007b2:  83 C6 02          add   si, 2
0x00000000000007b5:  26 F6 04 80       test  byte ptr es:[si], 0x80
0x00000000000007b9:  75 5F             jne   0x81a
0x00000000000007bb:  FE C3             inc   bl
0x00000000000007bd:  3A 1E B0 0D       cmp   bl, byte ptr ds:[_OPLchannels]
0x00000000000007c1:  72 D3             jb    0x796
0x00000000000007c3:  F6 46 FC 01       test  byte ptr [bp - 4], 1
0x00000000000007c7:  75 4F             jne   0x818
0x00000000000007c9:  30 C9             xor   cl, cl
0x00000000000007cb:  80 3E B0 0D 00    cmp   byte ptr ds:[_OPLchannels], 0
0x00000000000007d0:  76 39             jbe   0x80b
0x00000000000007d2:  88 C8             mov   al, cl
0x00000000000007d4:  30 E4             xor   ah, ah
0x00000000000007d6:  89 C3             mov   bx, ax
0x00000000000007d8:  BE 3F CC          mov   si, ADLIBCHANNELS_SEGMENT
0x00000000000007db:  C1 E3 04          shl   bx, 4
0x00000000000007de:  8E C6             mov   es, si
0x00000000000007e0:  8D 77 02          lea   si, [bx + 2]
0x00000000000007e3:  26 F6 04 01       test  byte ptr es:[si], 1
0x00000000000007e7:  75 40             jne   0x829
0x00000000000007e9:  26 8B 47 0E       mov   ax, word ptr es:[bx + 0Eh]
0x00000000000007ed:  83 C3 0C          add   bx, 0Ch
0x00000000000007f0:  39 C2             cmp   dx, ax
0x00000000000007f2:  77 07             ja    0x7fb
0x00000000000007f4:  75 0D             jne   0x803
0x00000000000007f6:  26 3B 3F          cmp   di, word ptr es:[bx]
0x00000000000007f9:  76 08             jbe   0x803
0x00000000000007fb:  89 C2             mov   dx, ax
0x00000000000007fd:  88 4E FE          mov   byte ptr [bp - 2], cl
0x0000000000000800:  26 8B 3F          mov   di, word ptr es:[bx]
0x0000000000000803:  FE C1             inc   cl
0x0000000000000805:  3A 0E B0 0D       cmp   cl, byte ptr ds:[_OPLchannels]
0x0000000000000809:  72 C7             jb    0x7d2
0x000000000000080b:  F6 46 FC 02       test  byte ptr [bp - 4], 2
0x000000000000080f:  75 07             jne   0x818
0x0000000000000811:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000000814:  3C FF             cmp   al, 0xff
0x0000000000000816:  75 1C             jne   0x834
0x0000000000000818:  B0 FF             mov   al, 0xff
0x000000000000081a:  C9                LEAVE_MACRO 
0x000000000000081b:  5F                pop   di
0x000000000000081c:  5E                pop   si
0x000000000000081d:  5A                pop   dx
0x000000000000081e:  59                pop   cx
0x000000000000081f:  5B                pop   bx
0x0000000000000820:  CB                retf  


0x0000000000000821:  C6 06 5A 10 00    mov   byte ptr ds:[_lastfreechannel], 0
0x0000000000000826:  E9 7D FF          jmp   0x7a6
0x0000000000000829:  BA FF 00          mov   dx, 0xff
0x000000000000082d:  E8 92 FE          call  releaseChannel_
0x0000000000000830:  88 C8             mov   al, cl
0x0000000000000832:  EB E6             jmp   0x81a
0x0000000000000834:  BA FF 00          mov   dx, 0xff
0x0000000000000837:  30 E4             xor   ah, ah
0x000000000000083a:  E8 85 FE          call  releaseChannel_
0x000000000000083d:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000000840:  C9                LEAVE_MACRO 
0x0000000000000841:  5F                pop   di
0x0000000000000842:  5E                pop   si
0x0000000000000843:  5A                pop   dx
0x0000000000000844:  59                pop   cx
0x0000000000000845:  5B                pop   bx
0x0000000000000846:  CB                retf  

ENDP

PROC  getInstrument_ FAR
PUBLIC  getInstrument_

0x0000000000000848:  53                push  bx
0x0000000000000849:  51                push  cx
0x000000000000084a:  BB 01 00          mov   bx, 1
0x000000000000084d:  88 C1             mov   cl, al
0x000000000000084f:  D3 E3             shl   bx, cl
0x0000000000000851:  85 1E A0 0D       test  word ptr ds:[_playingpercussMask], bx
0x0000000000000855:  74 24             je    0x87b
0x0000000000000857:  80 FA 23          cmp   dl, 0x23
0x000000000000085a:  72 18             jb    0x874
0x000000000000085c:  80 FA 51          cmp   dl, 0x51
0x000000000000085f:  77 13             ja    0x874
0x0000000000000861:  88 D3             mov   bl, dl
0x0000000000000863:  80 C3 5D          add   bl, 0x5d
0x0000000000000866:  B8 51 CC          mov   ax, INSTRUMENTLOOKUP_SEGMENT
0x0000000000000869:  30 FF             xor   bh, bh
0x000000000000086b:  8E C0             mov   es, ax
0x000000000000086d:  26 8A 07          mov   al, byte ptr es:[bx]
0x0000000000000870:  3C FF             cmp   al, 0xff
0x0000000000000872:  75 11             jne   0x885
0x0000000000000874:  31 C0             xor   ax, ax
0x0000000000000876:  31 D2             xor   dx, dx
0x0000000000000878:  59                pop   cx
0x0000000000000879:  5B                pop   bx
0x000000000000087a:  CB                retf  
0x000000000000087b:  88 C3             mov   bl, al
0x000000000000087d:  30 FF             xor   bh, bh
0x000000000000087f:  8A 9F D0 16       mov   bl, byte ptr [bx + 0x16d0]
0x0000000000000883:  EB E1             jmp   0x866
0x0000000000000885:  30 E4             xor   ah, ah
0x0000000000000887:  BA 00 CC          mov   dx, ADLIBINSTRUMENTLIST_SEGMENT
0x000000000000088a:  6B C0 24          imul  ax, ax, 0x24
0x000000000000088d:  59                pop   cx
0x000000000000088e:  5B                pop   bx
0x000000000000088f:  CB                retf  

ENDP

PROC  OPLplayNote_ FAR
PUBLIC  OPLplayNote_

0x0000000000000890:  51                push  cx
0x0000000000000891:  56                push  si
0x0000000000000892:  57                push  di
0x0000000000000893:  55                push  bp
0x0000000000000894:  89 E5             mov   bp, sp
0x0000000000000896:  83 EC 0A          sub   sp, 0Ah
0x0000000000000899:  88 46 FE          mov   byte ptr [bp - 2], al
0x000000000000089c:  88 56 FC          mov   byte ptr [bp - 4], dl
0x000000000000089f:  88 5E FA          mov   byte ptr [bp - 6], bl
0x00000000000008a2:  30 F6             xor   dh, dh
0x00000000000008a4:  30 E4             xor   ah, ah
0x00000000000008a7:  E8 9E FF          call  getInstrument_
0x00000000000008aa:  89 C6             mov   si, ax
0x00000000000008ac:  89 D7             mov   di, dx
0x00000000000008ae:  85 D2             test  dx, dx
0x00000000000008b0:  75 04             jne   0x8b6
0x00000000000008b2:  85 C0             test  ax, ax
0x00000000000008b4:  74 16             je    0x8cc
0x00000000000008b6:  80 7E FE 0F       cmp   byte ptr [bp - 2], 0xf
0x00000000000008ba:  75 15             jne   0x8d1
0x00000000000008bc:  B8 02 00          mov   ax, 2
0x00000000000008bf:  30 E4             xor   ah, ah
0x00000000000008c2:  E8 AB FE          call  findFreeChannel_
0x00000000000008c5:  88 46 F6          mov   byte ptr [bp - 0Ah], al
0x00000000000008c8:  3C FF             cmp   al, 0xff
0x00000000000008ca:  75 09             jne   0x8d5
0x00000000000008cc:  C9                LEAVE_MACRO 
0x00000000000008cd:  5F                pop   di
0x00000000000008ce:  5E                pop   si
0x00000000000008cf:  59                pop   cx
0x00000000000008d0:  CB                retf  

0x00000000000008d1:  31 C0             xor   ax, ax
0x00000000000008d3:  EB EA             jmp   0x8bf
0x00000000000008d5:  6A 00             push  0
0x00000000000008d7:  8A 46 FA          mov   al, byte ptr [bp - 6]
0x00000000000008da:  8A 5E FC          mov   bl, byte ptr [bp - 4]
0x00000000000008dd:  8A 56 FE          mov   dl, byte ptr [bp - 2]
0x00000000000008e0:  57                push  di
0x00000000000008e1:  98                cbw  
0x00000000000008e2:  30 FF             xor   bh, bh
0x00000000000008e4:  30 F6             xor   dh, dh
0x00000000000008e6:  89 C1             mov   cx, ax
0x00000000000008e8:  8A 46 F6          mov   al, byte ptr [bp - 0Ah]
0x00000000000008eb:  56                push  si
0x00000000000008ec:  30 E4             xor   ah, ah
0x00000000000008ef:  E8 EE FB          call  occupyChannel_
0x00000000000008f2:  80 3E 99 0D 00    cmp   byte ptr ds:[_OPLsinglevoice], 0
0x00000000000008f7:  75 D3             jne   0x8cc
0x00000000000008f9:  8E C7             mov   es, di
0x00000000000008fb:  26 83 3C 04       cmp   word ptr es:[si], 4
0x00000000000008ff:  75 CB             jne   0x8cc
0x0000000000000901:  80 7E FE 0F       cmp   byte ptr [bp - 2], 0xf
0x0000000000000905:  75 32             jne   0x939
0x0000000000000907:  B8 03 00          mov   ax, 3
0x000000000000090a:  30 E4             xor   ah, ah
0x000000000000090d:  E8 60 FE          call  findFreeChannel_
0x0000000000000910:  88 46 F8          mov   byte ptr [bp - 8], al
0x0000000000000913:  3C FF             cmp   al, 0xff
0x0000000000000915:  74 B5             je    0x8cc
0x0000000000000917:  6A 01             push  1
0x0000000000000919:  8A 46 FA          mov   al, byte ptr [bp - 6]
0x000000000000091c:  8A 5E FC          mov   bl, byte ptr [bp - 4]
0x000000000000091f:  8A 56 FE          mov   dl, byte ptr [bp - 2]
0x0000000000000922:  57                push  di
0x0000000000000923:  98                cbw  
0x0000000000000924:  30 FF             xor   bh, bh
0x0000000000000926:  30 F6             xor   dh, dh
0x0000000000000928:  89 C1             mov   cx, ax
0x000000000000092a:  8A 46 F8          mov   al, byte ptr [bp - 8]
0x000000000000092d:  56                push  si
0x000000000000092e:  30 E4             xor   ah, ah
0x0000000000000931:  E8 AC FB          call  occupyChannel_
0x0000000000000934:  C9                LEAVE_MACRO 
0x0000000000000935:  5F                pop   di
0x0000000000000936:  5E                pop   si
0x0000000000000937:  59                pop   cx
0x0000000000000938:  CB                retf  
0x0000000000000939:  B8 01 00          mov   ax, 1
0x000000000000093c:  EB CC             jmp   0x90a


ENDP

PROC  OPLreleaseNote_ FAR
PUBLIC  OPLreleaseNote_

0x000000000000093e:  53                push  bx
0x000000000000093f:  51                push  cx
0x0000000000000940:  56                push  si
0x0000000000000941:  55                push  bp
0x0000000000000942:  89 E5             mov   bp, sp
0x0000000000000944:  83 EC 02          sub   sp, 2
0x0000000000000947:  88 D7             mov   bh, dl
0x0000000000000949:  88 C1             mov   cl, al
0x000000000000094b:  30 E4             xor   ah, ah
0x000000000000094d:  89 C6             mov   si, ax
0x000000000000094f:  8A 84 20 17       mov   al, byte ptr [si + 0x1720]
0x0000000000000953:  30 DB             xor   bl, bl
0x0000000000000955:  88 46 FE          mov   byte ptr [bp - 2], al
0x0000000000000958:  80 3E B0 0D 00    cmp   byte ptr ds:[_OPLchannels], 0
0x000000000000095d:  76 2F             jbe   0x98e
0x000000000000095f:  88 D8             mov   al, bl
0x0000000000000961:  30 E4             xor   ah, ah
0x0000000000000963:  89 C2             mov   dx, ax
0x0000000000000965:  BE 3F CC          mov   si, ADLIBCHANNELS_SEGMENT
0x0000000000000968:  C1 E2 04          shl   dx, 4
0x000000000000096b:  8E C6             mov   es, si
0x000000000000096d:  89 D6             mov   si, dx
0x000000000000096f:  26 3A 0C          cmp   cl, byte ptr es:[si]
0x0000000000000972:  75 12             jne   0x986
0x0000000000000974:  46                inc   si
0x0000000000000975:  26 3A 3C          cmp   bh, byte ptr es:[si]
0x0000000000000978:  75 0C             jne   0x986
0x000000000000097a:  80 7E FE 40       cmp   byte ptr [bp - 2], 0x40
0x000000000000097e:  73 13             jae   0x993
0x0000000000000980:  31 D2             xor   dx, dx
0x0000000000000983:  E8 3C FD          call  releaseChannel_
0x0000000000000986:  FE C3             inc   bl
0x0000000000000988:  3A 1E B0 0D       cmp   bl, byte ptr ds:[_OPLchannels]
0x000000000000098c:  72 D1             jb    0x95f
0x000000000000098e:  C9                LEAVE_MACRO 
0x000000000000098f:  5E                pop   si
0x0000000000000990:  59                pop   cx
0x0000000000000991:  5B                pop   bx
0x0000000000000992:  CB                retf  
0x0000000000000993:  89 D6             mov   si, dx
0x0000000000000995:  83 C6 02          add   si, 2
0x0000000000000998:  26 80 0C 02       or    byte ptr es:[si], 2
0x000000000000099c:  EB E8             jmp   0x986


ENDP

PROC  OPLpitchWheel_ FAR
PUBLIC  OPLpitchWheel_

0x000000000000099e:  53                push  bx
0x000000000000099f:  51                push  cx
0x00000000000009a0:  55                push  bp
0x00000000000009a1:  89 E5             mov   bp, sp
0x00000000000009a3:  83 EC 08          sub   sp, 8
0x00000000000009a6:  88 56 FE          mov   byte ptr [bp - 2], dl
0x00000000000009a9:  80 6E FE 80       sub   byte ptr [bp - 2], 0x80
0x00000000000009ad:  88 C3             mov   bl, al
0x00000000000009af:  88 46 FA          mov   byte ptr [bp - 6], al
0x00000000000009b2:  30 FF             xor   bh, bh
0x00000000000009b4:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000009b7:  88 7E FC          mov   byte ptr [bp - 4], bh
0x00000000000009ba:  88 87 10 17       mov   byte ptr [bx + 0x1710], al
0x00000000000009be:  80 3E B0 0D 00    cmp   byte ptr ds:[_OPLchannels], 0
0x00000000000009c3:  76 29             jbe   0x9ee
0x00000000000009c5:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x00000000000009c8:  C6 46 F9 00       mov   byte ptr [bp - 7], 0
0x00000000000009cc:  88 46 F8          mov   byte ptr [bp - 8], al
0x00000000000009cf:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x00000000000009d2:  B8 3F CC          mov   ax, ADLIBCHANNELS_SEGMENT
0x00000000000009d5:  C1 E3 04          shl   bx, 4
0x00000000000009d8:  8E C0             mov   es, ax
0x00000000000009da:  26 8A 07          mov   al, byte ptr es:[bx]
0x00000000000009dd:  3A 46 FA          cmp   al, byte ptr [bp - 6]
0x00000000000009e0:  74 10             je    0x9f2
0x00000000000009e2:  FE 46 FC          inc   byte ptr [bp - 4]
0x00000000000009e5:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x00000000000009e8:  3A 06 B0 0D       cmp   al, byte ptr ds:[_OPLchannels]
0x00000000000009ec:  72 D7             jb    0x9c5
0x00000000000009ee:  C9                LEAVE_MACRO 
0x00000000000009ef:  59                pop   cx
0x00000000000009f0:  5B                pop   bx
0x00000000000009f1:  CB                retf  


0x00000000000009f2:  8B 16 A4 0D       mov   dx, word ptr ds:[_playingtime]
0x00000000000009f6:  A1 A6 0D          mov   ax, word ptr ds:[_playingtime + 2]
0x00000000000009f9:  26 89 47 0E       mov   word ptr es:[bx + 0Eh], ax
0x00000000000009fd:  26 8A 47 05       mov   al, byte ptr es:[bx + 5]
0x0000000000000a01:  98                cbw  
0x0000000000000a02:  26 89 57 0C       mov   word ptr es:[bx + 0Ch], dx
0x0000000000000a06:  89 C2             mov   dx, ax
0x0000000000000a08:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000000a0b:  30 E4             xor   ah, ah
0x0000000000000a0d:  B9 01 00          mov   cx, 1
0x0000000000000a10:  01 D0             add   ax, dx
0x0000000000000a12:  26 8A 57 03       mov   dl, byte ptr es:[bx + 3]
0x0000000000000a16:  26 88 47 04       mov   byte ptr es:[bx + 4], al
0x0000000000000a1a:  30 E4             xor   ah, ah
0x0000000000000a1c:  30 F6             xor   dh, dh
0x0000000000000a1e:  89 C3             mov   bx, ax
0x0000000000000a20:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x0000000000000a24:  E8 C3 F9          call  writeFrequency_
0x0000000000000a27:  EB B9             jmp   0x9e2



ENDP

PROC  OPLchangeControl_ FAR
PUBLIC  OPLchangeControl_


0x0000000000000a3c:  51                push      cx
0x0000000000000a3d:  56                push      si
0x0000000000000a3e:  55                push      bp
0x0000000000000a3f:  89 E5             mov       bp, sp
0x0000000000000a41:  83 EC 0E          sub       sp, 0Eh
0x0000000000000a44:  88 5E F6          mov       byte ptr [bp - 0Ah], bl
0x0000000000000a47:  88 46 FE          mov       byte ptr [bp - 2], al
0x0000000000000a4a:  80 FA 08          cmp       dl, 8
0x0000000000000a4d:  77 16             ja        0xa65
0x0000000000000a4f:  30 F6             xor       dh, dh
0x0000000000000a51:  89 D3             mov       bx, dx
0x0000000000000a53:  01 D3             add       bx, dx
0x0000000000000a55:  2E FF A7 EA 0E    jmp       word ptr cs:[bx + 0xeea]
0x0000000000000a5a:  88 C3             mov       bl, al
0x0000000000000a5c:  30 FF             xor       bh, bh
0x0000000000000a5e:  8A 46 F6          mov       al, byte ptr [bp - 0Ah]
0x0000000000000a61:  88 87 D0 16       mov       byte ptr [bx + 0x16d0], al
0x0000000000000a65:  C9                LEAVE_MACRO     
0x0000000000000a66:  5E                pop       si
0x0000000000000a67:  59                pop       cx
0x0000000000000a68:  CB                retf      
0x0000000000000a69:  88 C3             mov       bl, al
0x0000000000000a6b:  8A 46 F6          mov       al, byte ptr [bp - 0Ah]
0x0000000000000a6e:  30 FF             xor       bh, bh
0x0000000000000a70:  88 76 FC          mov       byte ptr [bp - 4], dh
0x0000000000000a73:  88 87 30 17       mov       byte ptr [bx + 0x1730], al
0x0000000000000a77:  80 3E B0 0D 00    cmp       byte ptr ds:[_OPLchannels], 0
0x0000000000000a7c:  76 E7             jbe       0xa65
0x0000000000000a7e:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x0000000000000a81:  30 E4             xor       ah, ah
0x0000000000000a83:  BA 3F CC          mov       dx, ADLIBCHANNELS_SEGMENT
0x0000000000000a86:  89 C3             mov       bx, ax
0x0000000000000a88:  8E C2             mov       es, dx
0x0000000000000a8a:  C1 E3 04          shl       bx, 4
0x0000000000000a8d:  26 8A 17          mov       dl, byte ptr es:[bx]
0x0000000000000a90:  3A 56 FE          cmp       dl, byte ptr [bp - 2]
0x0000000000000a93:  74 0E             je        0xaa3
0x0000000000000a95:  FE 46 FC          inc       byte ptr [bp - 4]
0x0000000000000a98:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x0000000000000a9b:  3A 06 B0 0D       cmp       al, byte ptr ds:[_OPLchannels]
0x0000000000000a9f:  73 C4             jae       0xa65
0x0000000000000aa1:  EB DB             jmp       0xa7e
0x0000000000000aa3:  26 8A 57 02       mov       dl, byte ptr es:[bx + 2]
0x0000000000000aa7:  8B 0E A4 0D       mov       cx, word ptr ds:[_playingtime]
0x0000000000000aab:  8B 36 A6 0D       mov       si, word ptr ds:[_playingtime + 2]
0x0000000000000aaf:  26 89 4F 0C       mov       word ptr es:[bx + 0Ch], cx
0x0000000000000ab3:  26 89 77 0E       mov       word ptr es:[bx + 0Eh], si
0x0000000000000ab7:  80 7E F6 28       cmp       byte ptr [bp - 0Ah], 0x28
0x0000000000000abb:  72 1E             jb        0xadb
0x0000000000000abd:  26 80 4F 02 04    or        byte ptr es:[bx + 2], 4
0x0000000000000ac2:  26 3A 57 02       cmp       dl, byte ptr es:[bx + 2]
0x0000000000000ac6:  74 CD             je        0xa95
0x0000000000000ac8:  BA 01 00          mov       dx, 1
0x0000000000000acb:  26 8B 77 08       mov       si, word ptr es:[bx + 8]
0x0000000000000acf:  26 8B 4F 0A       mov       cx, word ptr es:[bx + 0Ah]
0x0000000000000ad3:  89 F3             mov       bx, si
0x0000000000000ad5:  0E                push      cs
0x0000000000000ad6:  E8 A9 F9          call      writeModulation_
0x0000000000000ad9:  EB BA             jmp       0xa95
0x0000000000000adb:  26 80 67 02 FB    and       byte ptr es:[bx + 2], 0xfb
0x0000000000000ae0:  26 3A 57 02       cmp       dl, byte ptr es:[bx + 2]
0x0000000000000ae4:  74 AF             je        0xa95
0x0000000000000ae6:  26 8B 4F 08       mov       cx, word ptr es:[bx + 8]
0x0000000000000aea:  26 8B 77 0A       mov       si, word ptr es:[bx + 0Ah]
0x0000000000000aee:  31 D2             xor       dx, dx
0x0000000000000af0:  89 CB             mov       bx, cx
0x0000000000000af2:  89 F1             mov       cx, si
0x0000000000000af4:  0E                push      cs
0x0000000000000af5:  E8 8A F9          call      writeModulation_
0x0000000000000af8:  EB 9B             jmp       0xa95
0x0000000000000afa:  88 C3             mov       bl, al
0x0000000000000afc:  8A 46 F6          mov       al, byte ptr [bp - 0Ah]
0x0000000000000aff:  30 FF             xor       bh, bh
0x0000000000000b01:  88 76 FA          mov       byte ptr [bp - 6], dh
0x0000000000000b04:  88 87 E0 16       mov       byte ptr [bx + 0x16e0], al
0x0000000000000b08:  80 3E B0 0D 00    cmp       byte ptr ds:[_OPLchannels], 0
0x0000000000000b0d:  77 03             ja        0xb12
0x0000000000000b0f:  E9 53 FF          jmp       0xa65
0x0000000000000b12:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000b15:  C6 46 F5 00       mov       byte ptr [bp - 0Bh], 0
0x0000000000000b19:  88 46 F4          mov       byte ptr [bp - 0Ch], al
0x0000000000000b1c:  B9 3F CC          mov       cx, ADLIBCHANNELS_SEGMENT
0x0000000000000b1f:  8B 76 F4          mov       si, word ptr [bp - 0Ch]
0x0000000000000b22:  8E C1             mov       es, cx
0x0000000000000b24:  C1 E6 04          shl       si, 4
0x0000000000000b27:  26 8A 04          mov       al, byte ptr es:[si]
0x0000000000000b2a:  3A 46 FE          cmp       al, byte ptr [bp - 2]
0x0000000000000b2d:  74 0F             je        0xb3e
0x0000000000000b2f:  FE 46 FA          inc       byte ptr [bp - 6]
0x0000000000000b32:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000b35:  3A 06 B0 0D       cmp       al, byte ptr ds:[_OPLchannels]
0x0000000000000b39:  72 D7             jb        0xb12
0x0000000000000b3b:  E9 27 FF          jmp       0xa65
0x0000000000000b3e:  A1 A4 0D          mov       ax, word ptr ds:[_playingtime]
0x0000000000000b41:  8B 16 A6 0D       mov       dx, word ptr ds:[_playingtime + 2]
0x0000000000000b45:  26 89 44 0C       mov       word ptr es:[si + 0Ch], ax
0x0000000000000b49:  26 8A 44 06       mov       al, byte ptr es:[si + 6]
0x0000000000000b4d:  26 89 54 0E       mov       word ptr es:[si + 0Eh], dx
0x0000000000000b51:  98                cbw      
0x0000000000000b52:  8A 16 48 21       mov       dl, byte ptr ds:[_snd_MusicVolume]
0x0000000000000b56:  89 C3             mov       bx, ax
0x0000000000000b58:  8A 46 F6          mov       al, byte ptr [bp - 0Ah]
0x0000000000000b5b:  30 F6             xor       dh, dh
0x0000000000000b5d:  30 E4             xor       ah, ah
0x0000000000000b5f:  0E                push      cs
0x0000000000000b60:  E8 61 F9          call      calcVolumeOPL_
0x0000000000000b63:  8E C1             mov       es, cx
0x0000000000000b65:  26 8B 5C 08       mov       bx, word ptr es:[si + 8]
0x0000000000000b69:  26 88 44 07       mov       byte ptr es:[si + 7], al
0x0000000000000b6d:  98                cbw      
0x0000000000000b6e:  26 8B 4C 0A       mov       cx, word ptr es:[si + 0Ah]
0x0000000000000b72:  89 C2             mov       dx, ax
0x0000000000000b74:  8B 46 F4          mov       ax, word ptr [bp - 0Ch]
0x0000000000000b77:  0E                push      cs
0x0000000000000b78:  E8 A3 F5          call      OPLwriteVolume_
0x0000000000000b7b:  EB B2             jmp       0xb2f
0x0000000000000b7d:  80 6E F6 40       sub       byte ptr [bp - 0Ah], 0x40
0x0000000000000b81:  88 C3             mov       bl, al
0x0000000000000b83:  8A 46 F6          mov       al, byte ptr [bp - 0Ah]
0x0000000000000b86:  30 FF             xor       bh, bh
0x0000000000000b88:  88 76 F8          mov       byte ptr [bp - 8], dh
0x0000000000000b8b:  88 87 00 17       mov       byte ptr [bx + 0x1700], al
0x0000000000000b8f:  80 3E B0 0D 00    cmp       byte ptr ds:[_OPLchannels], 0
0x0000000000000b94:  77 03             ja        0xb99
0x0000000000000b96:  E9 CC FE          jmp       0xa65
0x0000000000000b99:  8A 46 F8          mov       al, byte ptr [bp - 8]
0x0000000000000b9c:  C6 46 F3 00       mov       byte ptr [bp - 0Dh], 0
0x0000000000000ba0:  88 46 F2          mov       byte ptr [bp - 0Eh], al
0x0000000000000ba3:  8B 5E F2          mov       bx, word ptr [bp - 0Eh]
0x0000000000000ba6:  B8 3F CC          mov       ax, ADLIBCHANNELS_SEGMENT
0x0000000000000ba9:  C1 E3 04          shl       bx, 4
0x0000000000000bac:  8E C0             mov       es, ax
0x0000000000000bae:  26 8A 07          mov       al, byte ptr es:[bx]
0x0000000000000bb1:  3A 46 FE          cmp       al, byte ptr [bp - 2]
0x0000000000000bb4:  74 0F             je        0xbc5
0x0000000000000bb6:  FE 46 F8          inc       byte ptr [bp - 8]
0x0000000000000bb9:  8A 46 F8          mov       al, byte ptr [bp - 8]
0x0000000000000bbc:  3A 06 B0 0D       cmp       al, byte ptr ds:[_OPLchannels]
0x0000000000000bc0:  72 D7             jb        0xb99
0x0000000000000bc2:  E9 A0 FE          jmp       0xa65
0x0000000000000bc5:  A1 A4 0D          mov       ax, word ptr ds:[_playingtime]
0x0000000000000bc8:  8B 16 A6 0D       mov       dx, word ptr ds:[_playingtime + 2]
0x0000000000000bcc:  26 8B 77 08       mov       si, word ptr es:[bx + 8]
0x0000000000000bd0:  26 8B 4F 0A       mov       cx, word ptr es:[bx + 0Ah]
0x0000000000000bd4:  26 89 47 0C       mov       word ptr es:[bx + 0Ch], ax
0x0000000000000bd8:  8A 46 F6          mov       al, byte ptr [bp - 0Ah]
0x0000000000000bdb:  26 89 57 0E       mov       word ptr es:[bx + 0Eh], dx
0x0000000000000bdf:  98                cbw      
0x0000000000000be0:  89 F3             mov       bx, si
0x0000000000000be2:  89 C2             mov       dx, ax
0x0000000000000be4:  8B 46 F2          mov       ax, word ptr [bp - 0Eh]
0x0000000000000be7:  0E                push      cs
0x0000000000000be8:  E8 93 F5          call      OPLwritePan_
0x0000000000000beb:  EB C9             jmp       0xbb6
0x0000000000000bed:  88 C3             mov       bl, al
0x0000000000000bef:  30 FF             xor       bh, bh
0x0000000000000bf1:  8A 46 F6          mov       al, byte ptr [bp - 0Ah]
0x0000000000000bf4:  88 87 20 17       mov       byte ptr [bx + 0x1720], al
0x0000000000000bf8:  3C 40             cmp       al, 0x40
0x0000000000000bfa:  73 9A             jae       0xb96
0x0000000000000bfc:  89 D8             mov       ax, bx
0x0000000000000bfe:  0E                push      cs
0x0000000000000bff:  E8 30 FB          call      releaseSustain_
0x0000000000000c02:  C9                LEAVE_MACRO     
0x0000000000000c03:  5E                pop       si
0x0000000000000c04:  59                pop       cx
0x0000000000000c05:  CB                retf    


ENDP

PROC  OPLplayMusic_ FAR
PUBLIC  OPLplayMusic_


0x0000000000000c06:  53                push      bx
0x0000000000000c07:  30 C0             xor       al, al
0x0000000000000c09:  FC                cld       
0x0000000000000c0a:  88 C3             mov       bl, al
0x0000000000000c0c:  30 FF             xor       bh, bh
0x0000000000000c0e:  C6 87 E0 16 7F    mov       byte ptr [bx + 0x16e0], 0x7f
0x0000000000000c13:  88 BF F0 16       mov       byte ptr [bx + 0x16f0], bh
0x0000000000000c17:  FE C0             inc       al
0x0000000000000c19:  88 BF 20 17       mov       byte ptr [bx + 0x1720], bh
0x0000000000000c1d:  3C 10             cmp       al, 0x10
0x0000000000000c1f:  72 E9             jb        0xc0a
0x0000000000000c21:  5B                pop       bx
0x0000000000000c22:  CB                retf      


ENDP

PROC  OPLstopMusic_ FAR
PUBLIC  OPLstopMusic_

0x0000000000000c24:  53                push      bx
0x0000000000000c25:  52                push      dx
0x0000000000000c26:  56                push      si
0x0000000000000c27:  30 DB             xor       bl, bl
0x0000000000000c29:  80 3E B0 0D 00    cmp       byte ptr ds:[_OPLchannels], 0
0x0000000000000c2e:  76 1F             jbe       0xc4f
0x0000000000000c30:  88 D8             mov       al, bl
0x0000000000000c32:  30 E4             xor       ah, ah
0x0000000000000c34:  89 C6             mov       si, ax
0x0000000000000c36:  BA 3F CC          mov       dx, ADLIBCHANNELS_SEGMENT
0x0000000000000c39:  C1 E6 04          shl       si, 4
0x0000000000000c3c:  8E C2             mov       es, dx
0x0000000000000c3e:  83 C6 02          add       si, 2
0x0000000000000c41:  26 F6 04 80       test      byte ptr es:[si], 0x80
0x0000000000000c45:  74 0C             je        0xc53
0x0000000000000c47:  FE C3             inc       bl
0x0000000000000c49:  3A 1E B0 0D       cmp       bl, byte ptr ds:[_OPLchannels]
0x0000000000000c4d:  72 E1             jb        0xc30
0x0000000000000c4f:  5E                pop       si
0x0000000000000c50:  5A                pop       dx
0x0000000000000c51:  5B                pop       bx
0x0000000000000c52:  CB                retf      

0x0000000000000c53:  BA FF 00          mov       dx, 0xff
0x0000000000000c56:  0E                push      cs
0x0000000000000c57:  E8 68 FA          call      releaseChannel_
0x0000000000000c5a:  EB EB             jmp       0xc47


ENDP

PROC  OPLchangeSystemVolume_ FAR
PUBLIC  OPLchangeSystemVolume_

0x0000000000000c5c:  53                push      bx
0x0000000000000c5d:  51                push      cx
0x0000000000000c5e:  52                push      dx
0x0000000000000c5f:  56                push      si
0x0000000000000c60:  57                push      di
0x0000000000000c61:  55                push      bp
0x0000000000000c62:  89 E5             mov       bp, sp
0x0000000000000c64:  83 EC 06          sub       sp, 6
0x0000000000000c67:  88 46 FE          mov       byte ptr [bp - 2], al
0x0000000000000c6a:  C6 46 FC 00       mov       byte ptr [bp - 4], 0
0x0000000000000c6e:  80 3E B0 0D 00    cmp       byte ptr ds:[_OPLchannels], 0
0x0000000000000c73:  76 4C             jbe       0xcc1
0x0000000000000c75:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x0000000000000c78:  C6 46 FB 00       mov       byte ptr [bp - 5], 0
0x0000000000000c7c:  88 46 FA          mov       byte ptr [bp - 6], al
0x0000000000000c7f:  B9 3F CC          mov       cx, ADLIBCHANNELS_SEGMENT
0x0000000000000c82:  8B 76 FA          mov       si, word ptr [bp - 6]
0x0000000000000c85:  8E C1             mov       es, cx
0x0000000000000c87:  C1 E6 04          shl       si, 4
0x0000000000000c8a:  26 8A 44 06       mov       al, byte ptr es:[si + 6]
0x0000000000000c8e:  98                cbw      
0x0000000000000c8f:  89 C3             mov       bx, ax
0x0000000000000c91:  26 8A 04          mov       al, byte ptr es:[si]
0x0000000000000c94:  24 0F             and       al, 0xf
0x0000000000000c96:  BF E0 16          mov       di, 0x16e0
0x0000000000000c99:  30 E4             xor       ah, ah
0x0000000000000c9b:  8A 56 FE          mov       dl, byte ptr [bp - 2]
0x0000000000000c9e:  01 C7             add       di, ax
0x0000000000000ca0:  30 F6             xor       dh, dh
0x0000000000000ca2:  8A 05             mov       al, byte ptr [di]
0x0000000000000ca4:  0E                push      cs
0x0000000000000ca5:  E8 1C F8          call      calcVolumeOPL_
0x0000000000000ca8:  8E C1             mov       es, cx
0x0000000000000caa:  26 88 44 07       mov       byte ptr es:[si + 7], al
0x0000000000000cae:  80 3E 9E 0D 02    cmp       byte ptr ds:[_playingstate], 2
0x0000000000000cb3:  74 13             je        0xcc8
0x0000000000000cb5:  FE 46 FC          inc       byte ptr [bp - 4]
0x0000000000000cb8:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x0000000000000cbb:  3A 06 B0 0D       cmp       al, byte ptr ds:[_OPLchannels]
0x0000000000000cbf:  72 B4             jb        0xc75
0x0000000000000cc1:  C9                LEAVE_MACRO     
0x0000000000000cc2:  5F                pop       di
0x0000000000000cc3:  5E                pop       si
0x0000000000000cc4:  5A                pop       dx
0x0000000000000cc5:  59                pop       cx
0x0000000000000cc6:  5B                pop       bx
0x0000000000000cc7:  CB                retf      


0x0000000000000cc8:  98                cbw      
0x0000000000000cc9:  26 8B 5C 08       mov       bx, word ptr es:[si + 8]
0x0000000000000ccd:  26 8B 4C 0A       mov       cx, word ptr es:[si + 0Ah]
0x0000000000000cd1:  89 C2             mov       dx, ax
0x0000000000000cd3:  8B 46 FA          mov       ax, word ptr [bp - 6]
0x0000000000000cd6:  0E                push      cs
0x0000000000000cd7:  E8 44 F4          call      OPLwriteVolume_
0x0000000000000cda:  EB D9             jmp       0xcb5

ENDP

PROC  OPLinitDriver_ FAR
PUBLIC  OPLinitDriver_

0x0000000000000cdc:  53                push      bx
0x0000000000000cdd:  51                push      cx
0x0000000000000cde:  52                push      dx
0x0000000000000cdf:  57                push      di
0x0000000000000ce0:  B9 20 01          mov       cx, 0x120
0x0000000000000ce3:  B0 FF             mov       al, 0xff
0x0000000000000ce5:  BA 3F CC          mov       dx, ADLIBCHANNELS_SEGMENT
0x0000000000000ce8:  31 FF             xor       di, di
0x0000000000000cea:  8E C2             mov       es, dx
0x0000000000000cec:  57                push      di
0x0000000000000ced:  8A E0             mov       ah, al
0x0000000000000cef:  D1 E9             shr       cx, 1
0x0000000000000cf1:  F3 AB             rep stosw word ptr es:[di], ax
0x0000000000000cf3:  13 C9             adc       cx, cx
0x0000000000000cf5:  F3 AA             rep stosb byte ptr es:[di], al
0x0000000000000cf7:  5F                pop       di
0x0000000000000cf8:  30 D2             xor       dl, dl
0x0000000000000cfa:  88 D0             mov       al, dl
0x0000000000000cfc:  8A 1E B0 0D       mov       bl, byte ptr ds:[_OPLchannels]
0x0000000000000d00:  98                cbw      
0x0000000000000d01:  30 FF             xor       bh, bh
0x0000000000000d03:  39 D8             cmp       ax, bx
0x0000000000000d05:  7D 13             jge       0xd1a
0x0000000000000d07:  BB 3F CC          mov       bx, ADLIBCHANNELS_SEGMENT
0x0000000000000d0a:  C1 E0 04          shl       ax, 4
0x0000000000000d0d:  8E C3             mov       es, bx
0x0000000000000d0f:  89 C3             mov       bx, ax
0x0000000000000d11:  FE C2             inc       dl
0x0000000000000d13:  26 C6 47 04 80    mov       byte ptr es:[bx + 4], 0x80
0x0000000000000d18:  EB E0             jmp       0xcfa
0x0000000000000d1a:  30 C0             xor       al, al
0x0000000000000d1c:  5F                pop       di
0x0000000000000d1d:  5A                pop       dx
0x0000000000000d1e:  59                pop       cx
0x0000000000000d1f:  5B                pop       bx
0x0000000000000d20:  CB                retf      



ENDP

PROC  OPL2initHardware_ FAR
PUBLIC  OPL2initHardware_


0x0000000000000d22:  31 D2             xor       dx, dx
0x0000000000000d24:  0E                push      cs
0x0000000000000d25:  E8 3C F5          call      OPLinit_
0x0000000000000d28:  30 C0             xor       al, al
0x0000000000000d2a:  CB                retf    


ENDP

PROC  OPL3initHardware_ FAR
PUBLIC  OPL3initHardware_

0x0000000000000d2c:  BA 01 00          mov       dx, 1
0x0000000000000d2f:  0E                push      cs
0x0000000000000d30:  E8 31 F5          call      OPLinit_
0x0000000000000d33:  30 C0             xor       al, al
0x0000000000000d35:  CB                retf    


; same for opl2 or 3
PROC  OPLdeinitHardware_ FAR
PUBLIC  OPLdeinitHardware_


0x0000000000000d36:  0E                push      cs
0x0000000000000d37:  E8 DA F5          call      OPLdeinit_
ENDP

PROC  OPLsendMIDI_ FAR
PUBLIC  OPLsendMIDI_

0x0000000000000d3a:  30 C0             xor       al, al
0x0000000000000d3c:  CB                retf      

ENDP


