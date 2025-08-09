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


EXTRN I_SoundIsPlaying_:FAR
EXTRN I_StopSound_:FAR
EXTRN R_PointToAngle2_:FAR
EXTRN FastMul16u32u_:FAR
EXTRN FastDiv3216u_:FAR
EXTRN S_InitSFXCache_:FAR
EXTRN I_UpdateSoundParams_:FAR

.DATA

EXTRN _sfx_priority:BYTE
EXTRN _numChannels:BYTE
EXTRN _channels:WORD
EXTRN _snd_SfxVolume:BYTE
EXTRN _sb_voicelist:WORD
EXTRN _mus_paused:BYTE

.CODE

S_CLIPPING_DIST_HIGH = 1200
S_CLOSE_DIST_HIGH = 200


PROC    S_SOUND_STARTMARKER_ NEAR
PUBLIC  S_SOUND_STARTMARKER_
ENDP

PROC    S_SetMusicVolume_ NEAR
PUBLIC  S_SetMusicVolume_

0x0000000000000000:  53                push  bx
0x0000000000000001:  56                push  si
0x0000000000000002:  88 C4             mov   ah, al
0x0000000000000004:  BB A5 04          mov   bx, _snd_MusicVolume
0x0000000000000007:  C0 E4 03          shl   ah, 3
0x000000000000000a:  88 27             mov   byte ptr ds:[bx], ah
0x000000000000000c:  BB 44 06          mov   bx, _playingdriver
0x000000000000000f:  8B 37             mov   si, word ptr ds:[bx]
0x0000000000000011:  8B 5F 02          mov   bx, word ptr ds:[bx + 2]
0x0000000000000014:  85 DB             test  bx, bx
0x0000000000000016:  75 07             jne   also_change_system_volume
0x0000000000000018:  85 F6             test  si, si
0x000000000000001a:  75 03             jne   also_change_system_volume
0x000000000000001c:  5E                pop   si
0x000000000000001d:  5B                pop   bx
0x000000000000001e:  CB                retf  
also_change_system_volume:
0x000000000000001f:  BB 44 06          mov   bx, _playingdriver
0x0000000000000022:  C4 37             les   si, ptr ds:[bx]
0x0000000000000024:  30 E4             xor   ah, ah
0x0000000000000026:  26 FF 5C 30       lcall es:[si + 0x30]
0x000000000000002a:  5E                pop   si
0x000000000000002b:  5B                pop   bx
0x000000000000002c:  CB                retf  


ENDP

PROC    S_ChangeMusic_ NEAR
PUBLIC  S_ChangeMusic_


0x000000000000002e:  53                push  bx
0x000000000000002f:  BB DE 00          mov   bx, _pendingmusicenum
0x0000000000000032:  88 07             mov   byte ptr ds:[bx], al
0x0000000000000034:  BB DF 00          mov   bx, _pendingmusicenumlooping
0x0000000000000037:  88 17             mov   byte ptr ds:[bx], dl
0x0000000000000039:  5B                pop   bx
0x000000000000003a:  CB                retf  


ENDP

PROC    S_StartMusic_ NEAR
PUBLIC  S_StartMusic_


0x000000000000003c:  53                push  bx
0x000000000000003d:  BB DE 00          mov   bx, _pendingmusicenum
0x0000000000000040:  88 07             mov   byte ptr ds:[bx], al
0x0000000000000042:  BB DF 00          mov   bx, _pendingmusicenumlooping
0x0000000000000045:  C6 07 00          mov   byte ptr ds:[bx], 0
0x0000000000000048:  5B                pop   bx
0x0000000000000049:  CB                retf  

ENDP

PROC    S_StopChannel_ NEAR
PUBLIC  S_StopChannel_


0x000000000000004a:  53                push  bx
0x000000000000004b:  51                push  cx
0x000000000000004c:  52                push  dx
0x000000000000004d:  56                push  si
0x000000000000004e:  8A 0E 45 20       mov   cl, byte ptr ds:[_numChannels]
0x0000000000000052:  88 C6             mov   dh, al
0x0000000000000054:  98                cbw  
0x0000000000000055:  89 C3             mov   bx, ax
0x0000000000000057:  C1 E0 02          shl   ax, 2
0x000000000000005a:  29 D8             sub   ax, bx
0x000000000000005c:  BE 30 1C          mov   si, _channels
0x000000000000005f:  01 C0             add   ax, ax
0x0000000000000061:  01 C6             add   si, ax
0x0000000000000063:  80 7C 05 00       cmp   byte ptr ds:[si + 5], 0
0x0000000000000067:  75 09             jne   label_1
0x0000000000000069:  8A 0E 45 20       mov   cl, byte ptr ds:[_numChannels]
0x000000000000006d:  5E                pop   si
0x000000000000006e:  5A                pop   dx
0x000000000000006f:  59                pop   cx
0x0000000000000070:  5B                pop   bx
0x0000000000000071:  CB                retf  
label_1:
0x0000000000000072:  8A 44 04          mov   al, byte ptr ds:[si + 4]
0x0000000000000075:  98                cbw  
0x0000000000000076:  9A 9A 04 A2 0A    call  I_SoundIsPlaying_
0x000000000000007b:  84 C0             test  al, al
0x000000000000007d:  75 19             jne   label_2
label_10:
0x000000000000007f:  8A 0E 45 20       mov   cl, byte ptr ds:[_numChannels]
0x0000000000000083:  30 D2             xor   dl, dl
label_9:
0x0000000000000085:  88 D0             mov   al, dl
0x0000000000000087:  88 CB             mov   bl, cl
label_2:
0x0000000000000089:  98                cbw  
0x000000000000008a:  30 FF             xor   bh, bh
0x000000000000008c:  39 D8             cmp   ax, bx
0x000000000000008e:  7D 1F             jge   label_7
0x0000000000000090:  38 D6             cmp   dh, dl
0x0000000000000092:  75 0F             jne   label_8
label_11:
0x0000000000000094:  FE C2             inc   dl
0x0000000000000096:  EB ED             jmp   label_9
0x0000000000000098:  8A 44 04          mov   al, byte ptr ds:[si + 4]
0x000000000000009b:  98                cbw  
0x000000000000009c:  9A 7A 04 A2 0A    call  I_StopSound_
0x00000000000000a1:  EB DC             jmp   label_10
label_8:
0x00000000000000a3:  6B D8 06          imul  bx, ax, 6
0x00000000000000a6:  8A 44 05          mov   al, byte ptr ds:[si + 5]
0x00000000000000a9:  3A 87 35 1C       cmp   al, byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id]
0x00000000000000ad:  75 E5             jne   label_11
label_7:
0x00000000000000af:  88 0E 45 20       mov   byte ptr ds:[_numChannels], cl
0x00000000000000b3:  C6 44 05 00       mov   byte ptr ds:[si + 5], 0
0x00000000000000b7:  8A 0E 45 20       mov   cl, byte ptr ds:[_numChannels]
0x00000000000000bb:  5E                pop   si
0x00000000000000bc:  5A                pop   dx
0x00000000000000bd:  59                pop   cx
0x00000000000000be:  5B                pop   bx
0x00000000000000bf:  CB                retf  

ENDP

PROC    S_AdjustSoundParamsSep_ NEAR
PUBLIC  S_AdjustSoundParamsSep_

0x00000000000000c0:  56                push  si
0x00000000000000c1:  51                push  cx
0x00000000000000c2:  53                push  bx
0x00000000000000c3:  BB 30 07          mov   bx, _playerMobj_pos
0x00000000000000c6:  52                push  dx
0x00000000000000c7:  C4 37             les   si, ptr ds:[bx]
0x00000000000000c9:  50                push  ax
0x00000000000000ca:  26 8B 5C 04       mov   bx, word ptr es:[si + 4]
0x00000000000000ce:  26 8B 4C 06       mov   cx, word ptr es:[si + 6]
0x00000000000000d2:  26 8B 04          mov   ax, word ptr es:[si]
0x00000000000000d5:  26 8B 74 02       mov   si, word ptr es:[si + 2]
0x00000000000000d9:  89 F2             mov   dx, si
0x00000000000000db:  BE 30 07          mov   si, _playerMobj_pos

0x00000000000000df:  E8 8F 20          call  R_PointToAngle2_
0x00000000000000e3:  C4 1C             les   bx, ptr ds:[si]
0x00000000000000e5:  26 3B 57 10       cmp   dx, word ptr es:[bx + 0x10]
0x00000000000000e9:  7F 08             jg    label_12
0x00000000000000eb:  75 3B             jne   label_13
0x00000000000000ed:  26 3B 47 0E       cmp   ax, word ptr es:[bx + 0xe]
0x00000000000000f1:  76 35             jbe   label_13
label_12:
0x00000000000000f3:  89 F3             mov   bx, si
0x00000000000000f5:  8B 34             mov   si, word ptr ds:[si]
0x00000000000000f7:  8E 47 02          mov   es, word ptr ds:[bx + 2]
0x00000000000000fa:  26 2B 44 0E       sub   ax, word ptr es:[si + 0xe]
0x00000000000000fe:  26 1B 54 10       sbb   dx, word ptr es:[si + 0x10]
label_14:
0x0000000000000102:  89 D3             mov   bx, dx
0x0000000000000104:  B8 D6 31          mov   ax, FINESINE_SEGMENT
0x0000000000000107:  C1 FB 03          sar   bx, 3
0x000000000000010a:  8E C0             mov   es, ax
0x000000000000010c:  C1 E3 02          shl   bx, 2
0x000000000000010f:  26 8B 07          mov   ax, word ptr es:[bx]
0x0000000000000112:  26 8B 4F 02       mov   cx, word ptr es:[bx + 2]
0x0000000000000116:  89 C3             mov   bx, ax
0x0000000000000118:  B8 60 00          mov   ax, 0x60
0x000000000000011b:  9A 1F 5D A2 0A    call  FastMul16u32u_
0x0000000000000120:  B4 80             mov   ah, 0x80
0x0000000000000122:  28 C4             sub   ah, al
0x0000000000000124:  88 E0             mov   al, ah
0x0000000000000126:  5E                pop   si
0x0000000000000127:  CB                retf  
label_13:
0x0000000000000128:  B9 FF FF          mov   cx, -1
0x000000000000012b:  26 2B 4F 0E       sub   cx, word ptr es:[bx + 0xe]
0x000000000000012f:  BE FF FF          mov   si, -1
0x0000000000000132:  26 1B 77 10       sbb   si, word ptr es:[bx + 0x10]
0x0000000000000136:  01 C8             add   ax, cx
0x0000000000000138:  11 F2             adc   dx, si
0x000000000000013a:  EB C6             jmp   label_14

ENDP

PROC    S_AdjustSoundParamsVol_ NEAR
PUBLIC  S_AdjustSoundParamsVol_

0x000000000000013c:  56                push  si
0x000000000000013d:  57                push  di
0x000000000000013e:  55                push  bp
0x000000000000013f:  89 E5             mov   bp, sp
0x0000000000000141:  83 EC 04          sub   sp, 4
0x0000000000000144:  53                push  bx
0x0000000000000145:  51                push  cx
0x0000000000000146:  BB 30 07          mov   bx, _playerMobj_pos
0x0000000000000149:  C4 37             les   si, ptr ds:[bx]
0x000000000000014b:  26 8B 1C          mov   bx, word ptr es:[si]
0x000000000000014e:  29 C3             sub   bx, ax
0x0000000000000150:  89 D8             mov   ax, bx
0x0000000000000152:  26 8B 5C 02       mov   bx, word ptr es:[si + 2]
0x0000000000000156:  19 D3             sbb   bx, dx
0x0000000000000158:  89 DA             mov   dx, bx
0x000000000000015a:  BF 30 07          mov   di, _playerMobj_pos
0x000000000000015d:  0B D2             or    dx, dx
0x000000000000015f:  7D 07             jge   already_positive
0x0000000000000161:  F7 D8             neg   ax
0x0000000000000163:  83 D2 00          adc   dx, 0
0x0000000000000166:  F7 DA             neg   dx
already_positive:
0x0000000000000168:  89 C1             mov   cx, ax
0x000000000000016a:  89 D3             mov   bx, dx
0x000000000000016c:  C4 35             les   si, ptr ds:[di]
0x000000000000016e:  89 46 FC          mov   word ptr [bp - 4], ax
0x0000000000000171:  26 8B 44 04       mov   ax, word ptr es:[si + 4]
0x0000000000000175:  89 56 FE          mov   word ptr [bp - 2], dx
0x0000000000000178:  2B 46 FA          sub   ax, word ptr [bp - 6]
0x000000000000017b:  26 8B 54 06       mov   dx, word ptr es:[si + 6]
0x000000000000017f:  1B 56 F8          sbb   dx, word ptr [bp - 8]
0x0000000000000182:  0B D2             or    dx, dx
0x0000000000000184:  7D 07             jge   label_3
0x0000000000000186:  F7 D8             neg   ax
0x0000000000000188:  83 D2 00          adc   dx, 0
0x000000000000018b:  F7 DA             neg   dx
label_3:
0x000000000000018d:  89 C6             mov   si, ax
0x000000000000018f:  89 D7             mov   di, dx
0x0000000000000191:  39 D3             cmp   bx, dx
0x0000000000000193:  7C 06             jl    label_4
0x0000000000000195:  75 08             jne   label_5
0x0000000000000197:  39 C1             cmp   cx, ax
0x0000000000000199:  73 04             jae   label_5
label_4:
0x000000000000019b:  89 C8             mov   ax, cx
0x000000000000019d:  89 DA             mov   dx, bx
label_5:
0x000000000000019f:  D1 FA             sar   dx, 1
0x00000000000001a1:  D1 D8             rcr   ax, 1
0x00000000000001a3:  89 D1             mov   cx, dx
0x00000000000001a5:  8B 56 FC          mov   dx, word ptr [bp - 4]
0x00000000000001a8:  01 F2             add   dx, si
0x00000000000001aa:  8B 5E FE          mov   bx, word ptr [bp - 2]
0x00000000000001ad:  11 FB             adc   bx, di
0x00000000000001af:  29 C2             sub   dx, ax
0x00000000000001b1:  89 D8             mov   ax, bx
0x00000000000001b3:  BB A7 04          mov   bx, _gamemap
0x00000000000001b6:  19 C8             sbb   ax, cx
0x00000000000001b8:  80 3F 08          cmp   byte ptr ds:[bx], 8
0x00000000000001bb:  74 11             je    label_6
0x00000000000001bd:  3D B0 04          cmp   ax, S_CLIPPING_DIST_HIGH
0x00000000000001c0:  7F 06             jg    exit_s_adjustsoundparams_ret_0
0x00000000000001c2:  75 0A             jne   label_6
0x00000000000001c4:  85 D2             test  dx, dx
0x00000000000001c6:  76 06             jbe   label_6
exit_s_adjustsoundparams_ret_0:
0x00000000000001c8:  30 C0             xor   al, al
0x00000000000001ca:  C9                LEAVE_MACRO 
0x00000000000001cb:  5F                pop   di
0x00000000000001cc:  5E                pop   si
0x00000000000001cd:  C3                ret   
label_6:
0x00000000000001ce:  3D C8 00          cmp   ax, S_CLOSE_DIST_HIGH
0x00000000000001d1:  7C 1C             jl    label_15
0x00000000000001d3:  31 C9             xor   cx, cx
0x00000000000001d5:  BB A7 04          mov   bx, _gamemap
0x00000000000001d8:  29 D1             sub   cx, dx
0x00000000000001da:  BA B0 04          mov   dx, S_CLIPPING_DIST_HIGH
0x00000000000001dd:  19 C2             sbb   dx, ax
0x00000000000001df:  80 3F 08          cmp   byte ptr ds:[bx], 8
0x00000000000001e2:  75 11             jne   label_16
0x00000000000001e4:  3D B0 04          cmp   ax, S_CLIPPING_DIST_HIGH
0x00000000000001e7:  7C 1D             jl    label_17
0x00000000000001e9:  B0 0F             mov   al, 0xf
0x00000000000001eb:  C9                LEAVE_MACRO 
0x00000000000001ec:  5F                pop   di
0x00000000000001ed:  5E                pop   si
0x00000000000001ee:  C3                ret   
label_15:
0x00000000000001ef:  B0 7F             mov   al, 0x7f
0x00000000000001f1:  C9                LEAVE_MACRO 
0x00000000000001f2:  5F                pop   di
0x00000000000001f3:  5E                pop   si
0x00000000000001f4:  C3                ret   
label_16:
0x00000000000001f5:  B8 7F 00          mov   ax, 0x7f
0x00000000000001f8:  BB E8 03          mov   bx, 0x3e8
0x00000000000001fb:  F7 EA             imul  dx
0x00000000000001fd:  9A 0B 5F A2 0A    call  FastDiv3216u_
0x0000000000000202:  C9                LEAVE_MACRO 
0x0000000000000203:  5F                pop   di
0x0000000000000204:  5E                pop   si
0x0000000000000205:  C3                ret   
label_17:
0x0000000000000206:  B8 70 00          mov   ax, 0x70
0x0000000000000209:  BB E8 03          mov   bx, 0x3e8
0x000000000000020c:  F7 EA             imul  dx
0x000000000000020e:  9A 0B 5F A2 0A    call  FastDiv3216u_
0x0000000000000213:  04 0F             add   al, 0xf
0x0000000000000215:  C9                LEAVE_MACRO 
0x0000000000000216:  5F                pop   di
0x0000000000000217:  5E                pop   si
0x0000000000000218:  C3                ret   

ENDP

PROC    S_SetSfxVolume_ NEAR
PUBLIC  S_SetSfxVolume_

0x000000000000021a:  53                push  bx
0x000000000000021b:  52                push  dx
0x000000000000021c:  84 C0             test  al, al
0x000000000000021e:  75 24             jne   label_18
label_20:
0x0000000000000220:  A2 60 20          mov   byte ptr ds:[_snd_SfxVolume], al
0x0000000000000223:  FA                cli   
0x0000000000000224:  30 D2             xor   dl, dl
label_19:
0x0000000000000226:  88 D0             mov   al, dl
0x0000000000000228:  98                cbw  
0x0000000000000229:  89 C3             mov   bx, ax
0x000000000000022b:  C1 E3 03          shl   bx, 3
0x000000000000022e:  FE C2             inc   dl
0x0000000000000230:  C6 87 E0 1B 00    mov   byte ptr ds:[bx + _sb_voicelist], 0
0x0000000000000235:  80 FA 08          cmp   dl, 8
0x0000000000000238:  7C EC             jl    label_19

0x000000000000023b:  E8 42 17          call  S_InitSFXCache_

0x000000000000023f:  FB                sti   
0x0000000000000240:  FC                cld   
0x0000000000000241:  5A                pop   dx
0x0000000000000242:  5B                pop   bx
0x0000000000000243:  CB                retf  
label_18:
0x0000000000000244:  C0 E0 03          shl   al, 3
0x0000000000000247:  04 07             add   al, 7
0x0000000000000249:  EB D5             jmp   label_20

ENDP

PROC    S_PauseSound_ NEAR
PUBLIC  S_PauseSound_


0x000000000000024c:  53                push  bx
0x000000000000024d:  BB 4F 06          mov   bx, _mus_playing
0x0000000000000250:  80 3F 00          cmp   byte ptr ds:[bx], 0
0x0000000000000253:  74 07             je    label_21
0x0000000000000255:  80 3E 1B 20 00    cmp   byte ptr ds:[_mus_paused], 0
0x000000000000025a:  74 02             je    label_22
label_21:
0x000000000000025c:  5B                pop   bx
0x000000000000025d:  CB                retf  
label_22:
0x000000000000025e:  9A C6 03 A2 0A    call  I_PauseSong_
0x0000000000000263:  C6 06 1B 20 01    mov   byte ptr ds:[_mus_paused], 1
0x0000000000000268:  5B                pop   bx
0x0000000000000269:  CB                retf  

ENDP

PROC    S_ResumeSound_ NEAR
PUBLIC  S_ResumeSound_

0x000000000000026a:  53                push  bx
0x000000000000026b:  BB 4F 06          mov   bx, _mus_playing
0x000000000000026e:  80 3F 00          cmp   byte ptr ds:[bx], 0
0x0000000000000271:  74 07             je    label_23
0x0000000000000273:  80 3E 1B 20 00    cmp   byte ptr ds:[_mus_paused], 0
0x0000000000000278:  75 02             jne   label_24
label_23:
0x000000000000027a:  5B                pop   bx
0x000000000000027b:  CB                retf  
label_24:
0x000000000000027c:  9A EE 03 A2 0A    call  I_ResumeSong_
0x0000000000000281:  C6 06 1B 20 00    mov   byte ptr ds:[_mus_paused], 0
0x0000000000000286:  5B                pop   bx
0x0000000000000287:  CB                retf  

ENDP

PROC    S_StopSound_ NEAR
PUBLIC  S_StopSound_

0x0000000000000288:  53                push  bx
0x0000000000000289:  51                push  cx
0x000000000000028a:  89 D1             mov   cx, dx
0x000000000000028c:  83 FA FF          cmp   dx, -1
0x000000000000028f:  74 2A             je    label_25
0x0000000000000291:  30 D2             xor   dl, dl
label_28:
0x0000000000000293:  88 D0             mov   al, dl
0x0000000000000295:  8A 1E 45 20       mov   bl, byte ptr ds:[_numChannels]
0x0000000000000299:  98                cbw  
0x000000000000029a:  30 FF             xor   bh, bh
0x000000000000029c:  39 D8             cmp   ax, bx
0x000000000000029e:  7D 18             jge   label_26
0x00000000000002a0:  6B D8 06          imul  bx, ax, 6
0x00000000000002a3:  80 BF 35 1C 00    cmp   byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id], 0
0x00000000000002a8:  75 04             jne   label_27
label_29:
0x00000000000002aa:  FE C2             inc   dl
0x00000000000002ac:  EB E5             jmp   label_28
label_27:
0x00000000000002ae:  3B 8F 30 1C       cmp   cx, word ptr ds:[bx + _channels]
0x00000000000002b2:  75 F6             jne   label_29

0x00000000000002b5:  E8 92 FD          call  S_StopChannel_
label_26:
0x00000000000002b8:  59                pop   cx
0x00000000000002b9:  5B                pop   bx
0x00000000000002ba:  CB                retf  
label_25:
0x00000000000002bb:  85 C0             test  ax, ax
0x00000000000002bd:  74 F9             je    label_26
0x00000000000002bf:  BB 2C 00          mov   bx, MUL_SIZEOF_THINKER_T
0x00000000000002c2:  2D 04 34          sub   ax, (_thinkerlist + THINKER_T.t_data)
0x00000000000002c5:  31 D2             xor   dx, dx
0x00000000000002c7:  F7 F3             div   bx
0x00000000000002c9:  89 C1             mov   cx, ax
0x00000000000002cb:  30 D2             xor   dl, dl
label_39:
0x00000000000002cd:  88 D0             mov   al, dl
0x00000000000002cf:  8A 1E 45 20       mov   bl, byte ptr ds:[_numChannels]
0x00000000000002d3:  98                cbw  
0x00000000000002d4:  30 FF             xor   bh, bh
0x00000000000002d6:  39 D8             cmp   ax, bx
0x00000000000002d8:  7D DE             jge   label_26
0x00000000000002da:  6B D8 06          imul  bx, ax, 6
0x00000000000002dd:  80 BF 35 1C 00    cmp   byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id], 0
0x00000000000002e2:  75 04             jne   label_38
label_40:
0x00000000000002e4:  FE C2             inc   dl
0x00000000000002e6:  EB E5             jmp   label_39
label_38:
0x00000000000002e8:  3B 8F 32 1C       cmp   cx, word ptr ds:[bx + _channels + CHANNEL_T.channel_originRef]
0x00000000000002ec:  75 F6             jne   label_40

0x00000000000002ef:  E8 58 FD          call  S_StopChannel_
0x00000000000002f2:  59                pop   cx
0x00000000000002f3:  5B                pop   bx
0x00000000000002f4:  CB                retf  

ENDP

PROC    S_StopSoundMobjRef_ NEAR
PUBLIC  S_StopSoundMobjRef_

0x00000000000002f6:  53                push  bx
0x00000000000002f7:  51                push  cx
0x00000000000002f8:  52                push  dx
0x00000000000002f9:  85 C0             test  ax, ax
0x00000000000002fb:  74 33             je    exit_stopsoundmobjref
0x00000000000002fd:  BB 2C 00          mov   bx, MUL_SIZEOF_THINKER_T
0x0000000000000300:  2D 04 34          sub   ax, (_thinkerlist + THINKER_T.t_data)
0x0000000000000303:  31 D2             xor   dx, dx
0x0000000000000305:  F7 F3             div   bx
0x0000000000000307:  89 C1             mov   cx, ax
0x0000000000000309:  30 D2             xor   dl, dl
label_42:
0x000000000000030b:  88 D0             mov   al, dl
0x000000000000030d:  8A 1E 45 20       mov   bl, byte ptr ds:[_numChannels]
0x0000000000000311:  98                cbw  
0x0000000000000312:  30 FF             xor   bh, bh
0x0000000000000314:  39 D8             cmp   ax, bx
0x0000000000000316:  7D 18             jge   exit_stopsoundmobjref
0x0000000000000318:  6B D8 06          imul  bx, ax, 6
0x000000000000031b:  80 BF 35 1C 00    cmp   byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id], 0
0x0000000000000320:  75 04             jne   label_41
label_43:
0x0000000000000322:  FE C2             inc   dl
0x0000000000000324:  EB E5             jmp   label_42
label_41:
0x0000000000000326:  3B 8F 32 1C       cmp   cx, word ptr ds:[bx + _channels + CHANNEL_T.channel_originRef]
0x000000000000032a:  75 F6             jne   label_43

0x000000000000032d:  E8 1A FD          call  S_StopChannel_
exit_stopsoundmobjref:
0x0000000000000330:  5A                pop   dx
0x0000000000000331:  59                pop   cx
0x0000000000000332:  5B                pop   bx
0x0000000000000333:  CB                retf  

ENDP

PROC    S_getChannel_ NEAR
PUBLIC  S_getChannel_

0x0000000000000334:  51                push  cx
0x0000000000000335:  56                push  si
0x0000000000000336:  57                push  di
0x0000000000000337:  55                push  bp
0x0000000000000338:  89 E5             mov   bp, sp
0x000000000000033a:  83 EC 04          sub   sp, 4
0x000000000000033d:  89 C1             mov   cx, ax
0x000000000000033f:  89 56 FE          mov   word ptr [bp - 2], dx
0x0000000000000342:  88 DF             mov   bh, bl
0x0000000000000344:  BE 2C 00          mov   si, MUL_SIZEOF_THINKER_T
0x0000000000000347:  2D 04 34          sub   ax, (_thinkerlist + THINKER_T.t_data)
0x000000000000034a:  31 D2             xor   dx, dx
0x000000000000034c:  F7 F6             div   si
0x000000000000034e:  30 DB             xor   bl, bl
0x0000000000000350:  8A 16 45 20       mov   dl, byte ptr ds:[_numChannels]
0x0000000000000354:  89 C7             mov   di, ax
label_35:
0x0000000000000356:  88 D8             mov   al, bl
0x0000000000000358:  30 F6             xor   dh, dh
0x000000000000035a:  98                cbw  
0x000000000000035b:  39 D0             cmp   ax, dx
0x000000000000035d:  7D 0A             jge   label_30
0x000000000000035f:  6B F0 06          imul  si, ax, 6
0x0000000000000362:  80 BC 35 1C 00    cmp   byte ptr ds:[si + _channels + CHANNEL_T.channel_sfx_id], 0
0x0000000000000367:  75 3A             jne   label_33
label_30:
0x0000000000000369:  88 D8             mov   al, bl
0x000000000000036b:  98                cbw  
0x000000000000036c:  89 C2             mov   dx, ax
0x000000000000036e:  A0 45 20          mov   al, byte ptr ds:[_numChannels]
0x0000000000000371:  30 E4             xor   ah, ah
0x0000000000000373:  39 C2             cmp   dx, ax
0x0000000000000375:  75 57             jne   label_31
0x0000000000000377:  30 DB             xor   bl, bl
label_34:
0x0000000000000379:  88 D8             mov   al, bl
0x000000000000037b:  8A 16 45 20       mov   dl, byte ptr ds:[_numChannels]
0x000000000000037f:  98                cbw  
0x0000000000000380:  30 F6             xor   dh, dh
0x0000000000000382:  39 D0             cmp   ax, dx
0x0000000000000384:  7D 31             jge   label_32
0x0000000000000386:  6B F0 06          imul  si, ax, 6
0x0000000000000389:  8A 84 35 1C       mov   al, byte ptr ds:[si + _channels + CHANNEL_T.channel_sfx_id]
0x000000000000038d:  30 E4             xor   ah, ah
0x000000000000038f:  89 C6             mov   si, ax
0x0000000000000391:  88 FA             mov   dl, bh
0x0000000000000393:  8A 84 12 11       mov   al, byte ptr ds:[si + _sfx_priority]
0x0000000000000397:  89 D6             mov   si, dx
0x0000000000000399:  3A 84 12 11       cmp   al, byte ptr ds:[si + _sfx_priority]
0x000000000000039d:  73 18             jae   label_32
0x000000000000039f:  FE C3             inc   bl
0x00000000000003a1:  EB D6             jmp   label_34
label_33:
0x00000000000003a3:  85 C9             test  cx, cx
0x00000000000003a5:  75 04             jne   label_36
label_37:
0x00000000000003a7:  FE C3             inc   bl
0x00000000000003a9:  EB AB             jmp   label_35
label_36:
0x00000000000003ab:  3B BC 32 1C       cmp   di, word ptr ds:[si + _channels + CHANNEL_T.channel_originRef]
0x00000000000003af:  75 F6             jne   label_37

0x00000000000003b2:  E8 95 FC          call  S_StopChannel_
0x00000000000003b5:  EB B2             jmp   label_30
label_32:
0x00000000000003b7:  C6 46 FD 00       mov   byte ptr [bp - 3], 0
0x00000000000003bb:  88 D8             mov   al, bl
0x00000000000003bd:  8A 16 45 20       mov   dl, byte ptr ds:[_numChannels]
0x00000000000003c1:  98                cbw  
0x00000000000003c2:  88 56 FC          mov   byte ptr [bp - 4], dl
0x00000000000003c5:  3B 46 FC          cmp   ax, word ptr [bp - 4]
0x00000000000003c8:  74 37             je    label_44

0x00000000000003cb:  E8 7C FC          call  S_StopChannel_
label_31:
0x00000000000003ce:  88 D8             mov   al, bl
0x00000000000003d0:  98                cbw  
0x00000000000003d1:  89 C2             mov   dx, ax
0x00000000000003d3:  C1 E0 02          shl   ax, 2
0x00000000000003d6:  29 D0             sub   ax, dx
0x00000000000003d8:  BE 30 1C          mov   si, _channels
0x00000000000003db:  01 C0             add   ax, ax
0x00000000000003dd:  01 C6             add   si, ax
0x00000000000003df:  88 7C 05          mov   byte ptr ds:[si + 5], bh
0x00000000000003e2:  85 C9             test  cx, cx
0x00000000000003e4:  74 1F             je    0x405
0x00000000000003e6:  89 C8             mov   ax, cx
0x00000000000003e8:  31 D2             xor   dx, dx
0x00000000000003ea:  B9 2C 00          mov   cx, MUL_SIZEOF_THINKER_T
0x00000000000003ed:  2D 04 34          sub   ax, (_thinkerlist + THINKER_T.t_data)
0x00000000000003f0:  F7 F1             div   cx
label_45:
0x00000000000003f2:  89 44 02          mov   word ptr ds:[si + 2], ax
0x00000000000003f5:  8B 46 FE          mov   ax, word ptr [bp - 2]
0x00000000000003f8:  89 04             mov   word ptr ds:[si], ax
0x00000000000003fa:  88 D8             mov   al, bl
exit_s_getchannel:
0x00000000000003fc:  C9                LEAVE_MACRO 
0x00000000000003fd:  5F                pop   di
0x00000000000003fe:  5E                pop   si
0x00000000000003ff:  59                pop   cx
0x0000000000000400:  C3                ret   
label_44:
0x0000000000000401:  B0 FF             mov   al, -1
0x0000000000000403:  EB F7             jmp   exit_s_getchannel
0x0000000000000405:  B8 FF FF          mov   ax, -1
0x0000000000000408:  EB E8             jmp   label_45

ENDP

PROC    S_StartSoundWithPosition_ NEAR
PUBLIC  S_StartSoundWithPosition_

0x000000000000040a:  51                push  cx
0x000000000000040b:  56                push  si
0x000000000000040c:  57                push  di
0x000000000000040d:  55                push  bp
0x000000000000040e:  89 E5             mov   bp, sp
0x0000000000000410:  83 EC 10          sub   sp, 010h
0x0000000000000413:  89 C7             mov   di, ax
0x0000000000000415:  88 56 F8          mov   byte ptr [bp - 8], dl
0x0000000000000418:  89 DE             mov   si, bx
0x000000000000041a:  BB 2C 00          mov   bx, MUL_SIZEOF_THINKER_T
0x000000000000041d:  2D 04 34          sub   ax, (_thinkerlist + THINKER_T.t_data)
0x0000000000000420:  31 D2             xor   dx, dx
0x0000000000000422:  F7 F3             div   bx
0x0000000000000424:  BB 07 01          mov   bx, _snd_SfxDevice
0x0000000000000427:  C6 46 FC 7F       mov   byte ptr [bp - 4], 0x7f
0x000000000000042b:  80 3F 00          cmp   byte ptr ds:[bx], 0
0x000000000000042e:  75 03             jne   label_46
0x0000000000000430:  E9 A3 00          jmp   exit_startsoundwithposition
label_46:
0x0000000000000433:  85 FF             test  di, di
0x0000000000000435:  75 03             jne   label_47
0x0000000000000437:  E9 A1 00          jmp   label_48
label_47:
0x000000000000043a:  BB F6 06          mov   bx, _playerMobjRef
0x000000000000043d:  3B 07             cmp   ax, word ptr ds:[bx]
0x000000000000043f:  75 03             jne   label_49
0x0000000000000441:  E9 71 00          jmp   label_50
label_49:
0x0000000000000444:  83 FE FF          cmp   si, -1
0x0000000000000447:  75 03             jne   label_51
0x0000000000000449:  E9 AC 00          jmp   label_52
label_51:
0x000000000000044c:  89 F3             mov   bx, si
0x000000000000044e:  B8 DF 7E          mov   ax, SECTORS_SOUNDORGS_SEGMENT
0x0000000000000451:  C1 E3 02          shl   bx, 2
0x0000000000000454:  8E C0             mov   es, ax
0x0000000000000456:  26 8B 07          mov   ax, word ptr es:[bx]
0x0000000000000459:  89 46 F4          mov   word ptr [bp - 0xc], ax
0x000000000000045c:  26 8B 47 02       mov   ax, word ptr es:[bx + 2]
0x0000000000000460:  89 46 F2          mov   word ptr [bp - 0xe], ax
0x0000000000000463:  31 C0             xor   ax, ax
0x0000000000000465:  83 C3 02          add   bx, 2
0x0000000000000468:  89 46 F6          mov   word ptr [bp - 0xa], ax
0x000000000000046b:  89 46 F0          mov   word ptr [bp - 0x10], ax
label_56:
0x000000000000046e:  8B 5E F0          mov   bx, word ptr [bp - 0x10]
0x0000000000000471:  8B 4E F2          mov   cx, word ptr [bp - 0xe]
0x0000000000000474:  8B 46 F6          mov   ax, word ptr [bp - 0xa]
0x0000000000000477:  8B 56 F4          mov   dx, word ptr [bp - 0xc]
0x000000000000047a:  E8 BF FC          call  S_AdjustSoundParamsVol_
0x000000000000047d:  88 46 FC          mov   byte ptr [bp - 4], al
0x0000000000000480:  84 C0             test  al, al
0x0000000000000482:  74 52             je    exit_startsoundwithposition
0x0000000000000484:  BB 30 07          mov   bx, _playerMobj_pos
0x0000000000000487:  C4 17             les   dx, ptr ds:[bx]
0x0000000000000489:  89 D3             mov   bx, dx
0x000000000000048b:  8B 46 F4          mov   ax, word ptr [bp - 0xc]
0x000000000000048e:  26 3B 47 02       cmp   ax, word ptr es:[bx + 2]
0x0000000000000492:  75 4F             jne   label_53
0x0000000000000494:  8B 46 F6          mov   ax, word ptr [bp - 0xa]
0x0000000000000497:  26 3B 07          cmp   ax, word ptr es:[bx]
0x000000000000049a:  75 47             jne   label_53
0x000000000000049c:  BB 30 07          mov   bx, _playerMobj_pos
0x000000000000049f:  C4 17             les   dx, ptr ds:[bx]
0x00000000000004a1:  89 D3             mov   bx, dx
0x00000000000004a3:  8B 46 F2          mov   ax, word ptr [bp - 0xe]
0x00000000000004a6:  26 3B 47 06       cmp   ax, word ptr es:[bx + 6]
0x00000000000004aa:  75 37             jne   label_53
0x00000000000004ac:  8B 46 F0          mov   ax, word ptr [bp - 0x10]
0x00000000000004af:  26 3B 47 04       cmp   ax, word ptr es:[bx + 4]
0x00000000000004b3:  75 2E             jne   label_53
label_50:
0x00000000000004b5:  C6 46 FE 80       mov   byte ptr [bp - 2], 0x80
label_55:
0x00000000000004b9:  89 F2             mov   dx, si
0x00000000000004bb:  89 F8             mov   ax, di
0x00000000000004bd:  8A 4E F8          mov   cl, byte ptr [bp - 8]
0x00000000000004c0:  0E                push  cs
0x00000000000004c1:  E8 C4 FD          call  S_StopSound_
0x00000000000004c4:  89 F2             mov   dx, si
0x00000000000004c6:  30 ED             xor   ch, ch
0x00000000000004c8:  89 F8             mov   ax, di
0x00000000000004ca:  89 CB             mov   bx, cx
0x00000000000004cc:  E8 65 FE          call  S_getChannel_
0x00000000000004cf:  88 46 FA          mov   byte ptr [bp - 6], al
0x00000000000004d2:  84 C0             test  al, al
0x00000000000004d4:  7D 48             jge   label_54
exit_startsoundwithposition:
0x00000000000004d6:  C9                LEAVE_MACRO 
0x00000000000004d7:  5F                pop   di
0x00000000000004d8:  5E                pop   si
0x00000000000004d9:  59                pop   cx
0x00000000000004da:  CB                retf  
label_48:
0x00000000000004db:  83 FE FF          cmp   si, -1
0x00000000000004de:  74 D5             je    label_50
0x00000000000004e0:  E9 57 FF          jmp   label_47
label_53:
0x00000000000004e3:  8B 5E F0          mov   bx, word ptr [bp - 0x10]
0x00000000000004e6:  8B 4E F2          mov   cx, word ptr [bp - 0xe]
0x00000000000004e9:  8B 46 F6          mov   ax, word ptr [bp - 0xa]
0x00000000000004ec:  8B 56 F4          mov   dx, word ptr [bp - 0xc]

0x00000000000004f0:  E8 CD FB          call  S_AdjustSoundParamsSep_
0x00000000000004f3:  88 46 FE          mov   byte ptr [bp - 2], al
0x00000000000004f6:  EB C1             jmp   label_55
label_52:
0x00000000000004f8:  6B D8 18          imul  bx, ax, 0x18
0x00000000000004fe:  8E C0             mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]
0x0000000000000500:  26 8B 07          mov   ax, word ptr es:[bx]
0x0000000000000503:  89 46 F6          mov   word ptr [bp - 0xa], ax
0x0000000000000506:  26 8B 47 02       mov   ax, word ptr es:[bx + 2]
0x000000000000050a:  89 46 F4          mov   word ptr [bp - 0xc], ax
0x000000000000050d:  26 8B 47 04       mov   ax, word ptr es:[bx + 4]
0x0000000000000511:  89 46 F0          mov   word ptr [bp - 0x10], ax
0x0000000000000514:  26 8B 47 06       mov   ax, word ptr es:[bx + 6]
0x0000000000000518:  89 46 F2          mov   word ptr [bp - 0xe], ax
0x000000000000051b:  E9 50 FF          jmp   label_56:
label_54:
0x000000000000051e:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000000521:  8A 56 FC          mov   dl, byte ptr [bp - 4]
0x0000000000000524:  89 C8             mov   ax, cx
0x0000000000000526:  30 FF             xor   bh, bh
0x0000000000000528:  30 F6             xor   dh, dh
0x000000000000052a:  9A 16 04 A2 0A    call  I_StartSound_
0x000000000000052f:  98                cbw  
0x0000000000000530:  89 C2             mov   dx, ax
0x0000000000000532:  3D FF FF          cmp   ax, -1
0x0000000000000535:  74 9F             je    exit_startsoundwithposition
0x0000000000000537:  8A 46 FA          mov   al, byte ptr [bp - 6]
0x000000000000053a:  98                cbw  
0x000000000000053b:  89 C6             mov   si, ax
0x000000000000053d:  C1 E6 02          shl   si, 2
0x0000000000000540:  29 C6             sub   si, ax
0x0000000000000542:  01 F6             add   si, si
0x0000000000000544:  88 94 34 1C       mov   byte ptr ds:[si + _channels + CHANNEL_T.channel_handle], dl
0x0000000000000548:  C9                LEAVE_MACRO 
0x0000000000000549:  5F                pop   di
0x000000000000054a:  5E                pop   si
0x000000000000054b:  59                pop   cx
0x000000000000054c:  CB                retf  

ENDP

PROC    S_StartSound_ NEAR
PUBLIC  S_StartSound_

0x000000000000054e:  53                push  bx
0x000000000000054f:  84 D2             test  dl, dl
0x0000000000000551:  75 02             jne   label_57
0x0000000000000553:  5B                pop   bx
0x0000000000000554:  CB                retf  
label_57:
0x0000000000000555:  BB FF FF          mov   bx, -1
0x0000000000000558:  30 F6             xor   dh, dh
0x000000000000055a:  0E                push  cs
0x000000000000055b:  E8 AC FE          call  S_StartSoundWithPosition_
0x000000000000055e:  5B                pop   bx
0x000000000000055f:  CB                retf  

ENDP

PROC    S_StartSoundWithParams_ NEAR
PUBLIC  S_StartSoundWithParams_

0x0000000000000560:  53                push  bx
0x0000000000000561:  84 D2             test  dl, dl
0x0000000000000563:  75 02             jne   label_58
0x0000000000000565:  5B                pop   bx
0x0000000000000566:  CB                retf  
label_58:
0x0000000000000567:  89 C3             mov   bx, ax
0x0000000000000569:  30 F6             xor   dh, dh
0x000000000000056b:  31 C0             xor   ax, ax
0x000000000000056d:  0E                push  cs
0x000000000000056e:  E8 99 FE          call  S_StartSoundWithPosition_
0x0000000000000571:  5B                pop   bx
0x0000000000000572:  CB                retf  

ENDP

PROC    S_UpdateSounds_ NEAR
PUBLIC  S_UpdateSounds_

0x0000000000000574:  53                push  bx
0x0000000000000575:  51                push  cx
0x0000000000000576:  52                push  dx
0x0000000000000577:  56                push  si
0x0000000000000578:  57                push  di
0x0000000000000579:  55                push  bp
0x000000000000057a:  89 E5             mov   bp, sp
0x000000000000057c:  83 EC 0A          sub   sp, 0Ah
0x000000000000057f:  C6 46 FC 00       mov   byte ptr [bp - 4], 0
label_61:
0x0000000000000583:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x0000000000000586:  98                cbw  
0x0000000000000587:  89 C7             mov   di, ax
0x0000000000000589:  A0 45 20          mov   al, byte ptr ds:[_numChannels]
0x000000000000058c:  30 E4             xor   ah, ah
0x000000000000058e:  39 C7             cmp   di, ax
0x0000000000000590:  7D 13             jge   label_59
0x0000000000000592:  6B F7 06          imul  si, di, 6
0x0000000000000595:  81 C6 30 1C       add   si, _channels
0x0000000000000599:  8A 44 05          mov   al, byte ptr ds:[si + 5]
0x000000000000059c:  84 C0             test  al, al
0x000000000000059e:  75 08             jne   label_60
0x00000000000005a0:  FE 46 FC          inc   byte ptr [bp - 4]
0x00000000000005a3:  EB DE             jmp   label_61
label_59:
0x00000000000005a5:  E9 C8 00          jmp   exit_s_updatesounds
label_60:
0x00000000000005a8:  8A 44 04          mov   al, byte ptr ds:[si + 4]
0x00000000000005ab:  98                cbw  
0x00000000000005ac:  9A 9A 04 A2 0A    call  I_SoundIsPlaying_
0x00000000000005b1:  84 C0             test  al, al
0x00000000000005b3:  74 66             je    jump_to_label_64
0x00000000000005b5:  83 7C 02 FF       cmp   word ptr ds:[si + 2], -1
0x00000000000005b9:  74 55             je    label_65
0x00000000000005bb:  BB F6 06          mov   bx, _playerMobjRef
0x00000000000005be:  8B 07             mov   ax, word ptr ds:[bx]
0x00000000000005c0:  3B 44 02          cmp   ax, word ptr ds:[si + 2]
0x00000000000005c3:  74 4B             je    label_65
label_62:
0x00000000000005c5:  8B 04             mov   ax, word ptr ds:[si]
0x00000000000005c7:  3D FF FF          cmp   ax, 0xffff
0x00000000000005ca:  74 51             je    0x61d
0x00000000000005cc:  BA DF 7E          mov   dx, 0x7edf
0x00000000000005cf:  89 C3             mov   bx, ax
0x00000000000005d1:  C7 46 F8 00 00    mov   word ptr [bp - 8], 0
0x00000000000005d6:  C1 E3 02          shl   bx, 2
0x00000000000005d9:  8E C2             mov   es, dx
0x00000000000005db:  31 FF             xor   di, di
0x00000000000005dd:  26 8B 17          mov   dx, word ptr es:[bx]
0x00000000000005e0:  26 8B 47 02       mov   ax, word ptr es:[bx + 2]
0x00000000000005e4:  83 C3 02          add   bx, 2
0x00000000000005e7:  89 56 FA          mov   word ptr [bp - 6], dx
label_63:
0x00000000000005ea:  89 46 F6          mov   word ptr [bp - 0xa], ax
0x00000000000005ed:  8B 4E F6          mov   cx, word ptr [bp - 0xa]
0x00000000000005f0:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x00000000000005f3:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000005f6:  89 FB             mov   bx, di
0x00000000000005f8:  E8 41 FB          call  S_AdjustSoundParamsVol_
0x00000000000005fb:  88 46 FE          mov   byte ptr [bp - 2], al
0x00000000000005fe:  84 C0             test  al, al
0x0000000000000600:  75 3B             jne   label_66
0x0000000000000602:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x0000000000000605:  98                cbw  

0x0000000000000607:  E8 40 FA          call  S_StopChannel_
0x000000000000060a:  FE 46 FC          inc   byte ptr [bp - 4]
0x000000000000060d:  E9 73 FF          jmp   label_61
label_65:
0x0000000000000610:  83 3C FF          cmp   word ptr ds:[si], -1
0x0000000000000613:  75 B0             jne   label_62
0x0000000000000615:  FE 46 FC          inc   byte ptr [bp - 4]
0x0000000000000618:  E9 68 FF          jmp   label_61
jump_to_label_64:
0x000000000000061b:  EB 47             jmp   label_64
0x000000000000061d:  6B 5C 02 18       imul  bx, word ptr ds:[si + 2], 0x18

0x0000000000000624:  8E C0             mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]
0x0000000000000626:  26 8B 07          mov   ax, word ptr es:[bx]
0x0000000000000629:  89 46 F8          mov   word ptr [bp - 8], ax
0x000000000000062c:  26 8B 47 02       mov   ax, word ptr es:[bx + 2]
0x0000000000000630:  89 46 FA          mov   word ptr [bp - 6], ax
0x0000000000000633:  26 8B 47 06       mov   ax, word ptr es:[bx + 6]
0x0000000000000637:  26 8B 7F 04       mov   di, word ptr es:[bx + 4]
0x000000000000063b:  EB AD             jmp   label_63
label_66:
0x000000000000063d:  8B 4E F6          mov   cx, word ptr [bp - 0xa]
0x0000000000000640:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x0000000000000643:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000000646:  89 FB             mov   bx, di

0x0000000000000649:  E8 74 FA          call  S_AdjustSoundParamsSep_
0x000000000000064c:  8A 56 FE          mov   dl, byte ptr [bp - 2]
0x000000000000064f:  88 C3             mov   bl, al
0x0000000000000651:  8A 44 04          mov   al, byte ptr ds:[si + 4]
0x0000000000000654:  30 FF             xor   bh, bh
0x0000000000000656:  30 F6             xor   dh, dh
0x0000000000000658:  98                cbw  
0x0000000000000659:  9A A0 04 A2 0A    I_UpdateSoundParams_
0x000000000000065e:  FE 46 FC          inc   byte ptr [bp - 4]
0x0000000000000661:  E9 1F FF          jmp   label_61
label_64:
0x0000000000000664:  89 F8             mov   ax, di
0x0000000000000666:  0E                push  cs
0x0000000000000667:  E8 E0 F9          call  S_StopChannel_
0x000000000000066a:  FE 46 FC          inc   byte ptr [bp - 4]
0x000000000000066d:  E9 13 FF          jmp   label_61
exit_s_updatesounds:
0x0000000000000670:  C9                LEAVE_MACRO
0x0000000000000671:  5F                pop   di
0x0000000000000672:  5E                pop   si
0x0000000000000673:  5A                pop   dx
0x0000000000000674:  59                pop   cx
0x0000000000000675:  5B                pop   bx
0x0000000000000676:  CB                retf  

ENDP


PROC    S_SOUND_ENDMARKER_ NEAR
PUBLIC  S_SOUND_ENDMARKER_
ENDP



END