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





.CODE
 
PROC D_INTERRUPT_STARTMARKER_
PUBLIC D_INTERRUPT_STARTMARKER_
ENDP

dw 00078h
dw 000F5h
db 00137h
db 00158h
db 0017Dh
db 00096h
db 001ADh
db 00093h

PROC MUS_ServiceRoutine_
PUBLIC MUS_ServiceRoutine_


0x0000000000000000:  53                push  bx
0x0000000000000001:  51                push  cx
0x0000000000000002:  52                push  dx
0x0000000000000003:  56                push  si
0x0000000000000004:  57                push  di
0x0000000000000005:  55                push  bp
0x0000000000000006:  89 E5             mov   bp, sp
0x0000000000000008:  83 EC 0A          sub   sp, 0Ah
0x000000000000000b:  BB EF 00          mov   bx, _playingstate
0x000000000000000e:  80 3F 02          cmp   byte ptr [bx], ST_PLAYING
0x0000000000000011:  75 60             jne   jump_to_exit_MUS_serviceroutine
0x0000000000000013:  BB 44 06          mov   bx, _playingdriver
0x0000000000000016:  8B 57 02          mov   dx, word ptr [bx + 2]
0x0000000000000019:  8B 07             mov   ax, word ptr [bx]
0x000000000000001b:  85 D2             test  dx, dx
0x000000000000001d:  75 04             jne   label_4
0x000000000000001f:  85 C0             test  ax, ax
0x0000000000000021:  74 50             je    jump_to_exit_MUS_serviceroutine
label_4:
0x0000000000000023:  BB 4C 06          mov   bx, _currentsong_ticks_to_process
0x0000000000000026:  FF 07             inc   word ptr [bx]
label_7:
0x0000000000000028:  BB 4C 06          mov   bx, _currentsong_ticks_to_process
0x000000000000002b:  83 3F 00          cmp   word ptr [bx], 0
0x000000000000002e:  7C 46             jl    jump_to_label_5
0x0000000000000030:  BF 32 01          mov   di, _EMS_PAGE
0x0000000000000033:  BB 4A 06          mov   bx, currentsong_playing_offset
0x0000000000000036:  8B 05             mov   ax, word ptr [di]
0x0000000000000038:  8B 1F             mov   bx, word ptr [bx]
0x000000000000003a:  8E C0             mov   es, ax
0x000000000000003c:  26 8A 07          mov   al, byte ptr es:[bx]
0x000000000000003f:  BE 01 00          mov   si, 1
0x0000000000000042:  88 C1             mov   cl, al
0x0000000000000044:  C6 46 FE 00       mov   byte ptr [bp - 2], 0
0x0000000000000048:  80 E1 70          and   cl, 070h
0x000000000000004b:  88 C2             mov   dl, al
0x000000000000004d:  30 ED             xor   ch, ch
0x000000000000004f:  80 E2 0F          and   dl, 0Fh
0x0000000000000052:  C1 F9 04          sar   cx, 4
0x0000000000000055:  24 80             and   al, 080h
0x0000000000000057:  89 4E F6          mov   word ptr [bp - 0Ah], cx
0x000000000000005a:  88 46 FA          mov   byte ptr [bp - 6], al
0x000000000000005d:  8A 46 F6          mov   al, byte ptr [bp - 0Ah]
0x0000000000000060:  8B 0E 8C 0D       mov   cx, 0  ; delay_amt
0x0000000000000064:  3C 07             cmp   al, 7
0x0000000000000066:  77 2E             ja    label_1
0x0000000000000068:  30 E4             xor   ah, ah
0x000000000000006a:  89 C7             mov   di, ax
0x000000000000006c:  01 C7             add   di, ax
0x000000000000006e:  2E FF A5 AA 06    jmp   word ptr cs:[di + 0x6aa]  ; todo jmp table 010h before 
jump_to_exit_MUS_serviceroutine:
0x0000000000000073:  E9 78 00          jmp   exit_MUS_serviceroutine
jump_to_label_5:
0x0000000000000076:  EB 6C             jmp   label_5
0x0000000000000078:  BE 44 06          mov   si, _playingdriver
0x000000000000007b:  26 8A 47 01       mov   al, byte ptr es:[bx + 1]
0x000000000000007f:  BB 44 06          mov   bx, _playingdriver
0x0000000000000082:  8B 34             mov   si, word ptr [si]
0x0000000000000084:  8E 47 02          mov   es, word ptr [bx + 2]
0x0000000000000087:  88 D3             mov   bl, dl
0x0000000000000089:  30 FF             xor   bh, bh
0x000000000000008b:  89 C2             mov   dx, ax
0x000000000000008d:  89 D8             mov   ax, bx
0x000000000000008f:  26 FF 5C 14       lcall es:[si + 0x14]
label_2:
0x0000000000000093:  BE 02 00          mov   si, 2
label_1:
0x0000000000000096:  BB 4A 06          mov   bx, currentsong_playing_offset
0x0000000000000099:  01 37             add   word ptr [bx], si
0x000000000000009b:  80 7E FA 00       cmp   byte ptr [bp - 6], 0
0x000000000000009f:  74 23             je    label_8
label_6:
0x00000000000000a1:  BB 4A 06          mov   bx, currentsong_playing_offset
0x00000000000000a4:  BE 32 01          mov   si, _EMS_PAGE
0x00000000000000a7:  8B 1F             mov   bx, word ptr [bx]
0x00000000000000a9:  8E 04             mov   es, word ptr [si]
0x00000000000000ab:  26 8A 07          mov   al, byte ptr es:[bx]
0x00000000000000ae:  C1 E1 07          shl   cx, 7
0x00000000000000b1:  88 C4             mov   ah, al
0x00000000000000b3:  43                inc   bx
0x00000000000000b4:  80 E4 7F          and   ah, 07Fh
0x00000000000000b7:  BE 4A 06          mov   si, currentsong_playing_offset
0x00000000000000ba:  00 E1             add   cl, ah
0x00000000000000bc:  24 80             and   al, 080h
0x00000000000000be:  89 1C             mov   word ptr [si], bx
0x00000000000000c0:  84 C0             test  al, al
0x00000000000000c2:  75 DD             jne   label_6
label_8:
0x00000000000000c4:  BB 4C 06          mov   bx, _currentsong_ticks_to_process
0x00000000000000c7:  29 0F             sub   word ptr [bx], cx
0x00000000000000c9:  80 7E FE 00       cmp   byte ptr [bp - 2], 0
0x00000000000000cd:  74 0A             je    label_9
0x00000000000000cf:  BB 48 06          mov   bx, currentsong_start_offset
0x00000000000000d2:  8B 07             mov   ax, word ptr [bx]
0x00000000000000d4:  BB 4A 06          mov   bx, currentsong_playing_offset
0x00000000000000d7:  89 07             mov   word ptr [bx], ax
label_9:
0x00000000000000d9:  BB EF 00          mov   bx, _playingstate
0x00000000000000dc:  80 3F 01          cmp   byte ptr [bx], 1
0x00000000000000df:  74 03             je    label_5
0x00000000000000e1:  E9 44 FF          jmp   label_7
label_5:
0x00000000000000e4:  BB DC 01          mov   bx, _playingtime
0x00000000000000e7:  83 07 01          add   word ptr [bx], 1
0x00000000000000ea:  83 57 02 00       adc   word ptr [bx + 2], 0
exit_MUS_serviceroutine:
0x00000000000000ee:  C9                LEAVE_MACRO
0x00000000000000ef:  5F                pop   di
0x00000000000000f0:  5E                pop   si
0x00000000000000f1:  5A                pop   dx
0x00000000000000f2:  59                pop   cx
0x00000000000000f3:  5B                pop   bx
0x00000000000000f4:  CB                retf  
0x00000000000000f5:  26 8A 67 01       mov   ah, byte ptr es:[bx + 1]
0x00000000000000f9:  B0 FF             mov   al, 0FFh
0x00000000000000fb:  88 E6             mov   dh, ah
0x00000000000000fd:  80 E6 7F          and   dh, 07Fh
0x0000000000000100:  88 76 FC          mov   byte ptr [bp - 4], dh
0x0000000000000103:  F6 C4 80          test  ah, 080h
0x0000000000000106:  74 09             je    label_10
0x0000000000000108:  26 8A 47 02       mov   al, byte ptr es:[bx + 2]
0x000000000000010c:  BE 02 00          mov   si, 2
0x000000000000010f:  24 7F             and   al, 07Fh
label_10:
0x0000000000000111:  BF 44 06          mov   di, _playingdriver
0x0000000000000114:  BB 44 06          mov   bx, _playingdriver
0x0000000000000117:  98                cwde  
0x0000000000000118:  8B 3D             mov   di, word ptr [di]
0x000000000000011a:  8E 47 02          mov   es, word ptr [bx + 2]
0x000000000000011d:  89 C3             mov   bx, ax
0x000000000000011f:  8A 46 FC          mov   al, byte ptr [bp - 4]
0x0000000000000122:  30 E4             xor   ah, ah
0x0000000000000124:  88 56 F8          mov   byte ptr [bp - 8], dl
0x0000000000000127:  88 66 F9          mov   byte ptr [bp - 7], ah
0x000000000000012a:  89 C2             mov   dx, ax
0x000000000000012c:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x000000000000012f:  46                inc   si
0x0000000000000130:  26 FF 5D 10       lcall es:[di + 0x10]
0x0000000000000134:  E9 5F FF          jmp   label_1
0x0000000000000137:  BF 44 06          mov   di, _playingdriver
0x000000000000013a:  26 8A 47 01       mov   al, byte ptr es:[bx + 1]
0x000000000000013e:  BB 44 06          mov   bx, _playingdriver
0x0000000000000141:  8B 3D             mov   di, word ptr [di]
0x0000000000000143:  8E 47 02          mov   es, word ptr [bx + 2]
0x0000000000000146:  88 D3             mov   bl, dl
0x0000000000000148:  30 FF             xor   bh, bh
0x000000000000014a:  89 C2             mov   dx, ax
0x000000000000014c:  89 D8             mov   ax, bx
0x000000000000014e:  BE 02 00          mov   si, 2
0x0000000000000151:  26 FF 5D 18       lcall es:[di + 0x18]
0x0000000000000155:  E9 3E FF          jmp   label_1
0x0000000000000158:  BE 44 06          mov   si, _playingdriver
0x000000000000015b:  88 56 F8          mov   byte ptr [bp - 8], dl
0x000000000000015e:  26 8A 47 01       mov   al, byte ptr es:[bx + 1]
0x0000000000000162:  BB 44 06          mov   bx, _playingdriver
0x0000000000000165:  24 7F             and   al, 07Fh
0x0000000000000167:  8B 34             mov   si, word ptr [si]
0x0000000000000169:  88 66 F9          mov   byte ptr [bp - 7], ah
0x000000000000016c:  89 C2             mov   dx, ax
0x000000000000016e:  8E 47 02          mov   es, word ptr [bx + 2]
0x0000000000000171:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x0000000000000174:  31 DB             xor   bx, bx
0x0000000000000176:  26 FF 5C 1C       lcall es:[si + 0x1c]
0x000000000000017a:  E9 16 FF          jmp   label_2
0x000000000000017d:  BE 44 06          mov   si, _playingdriver
0x0000000000000180:  BF 44 06          mov   di, _playingdriver
0x0000000000000183:  26 8A 77 01       mov   dh, byte ptr es:[bx + 1]
0x0000000000000187:  88 66 F9          mov   byte ptr [bp - 7], ah
0x000000000000018a:  80 E6 7F          and   dh, 07Fh
0x000000000000018d:  26 8A 5F 02       mov   bl, byte ptr es:[bx + 2]
0x0000000000000191:  8B 34             mov   si, word ptr [si]
0x0000000000000193:  80 E3 7F          and   bl, 07Fh
0x0000000000000196:  88 76 F8          mov   byte ptr [bp - 8], dh
0x0000000000000199:  88 D0             mov   al, dl
0x000000000000019b:  8E 45 02          mov   es, word ptr [di + 2]
0x000000000000019e:  8B 56 F8          mov   dx, word ptr [bp - 8]
0x00000000000001a1:  30 FF             xor   bh, bh
0x00000000000001a3:  26 FF 5C 1C       lcall es:[si + 0x1c]
0x00000000000001a7:  BE 03 00          mov   si, 3
0x00000000000001aa:  E9 E9 FE          jmp   label_1
0x00000000000001ad:  BB 4E 06          mov   bx, _loops_enabled
0x00000000000001b0:  80 3F 00          cmp   byte ptr [bx], 0
0x00000000000001b3:  74 07             je    label_3
0x00000000000001b5:  C6 46 FE 01       mov   byte ptr [bp - 2], 1
0x00000000000001b9:  E9 DA FE          jmp   label_1
label_3:
0x00000000000001bc:  BB EF 00          mov   bx, _playingstate
0x00000000000001bf:  C6 07 01          mov   byte ptr [bx], ST_STOPPED
0x00000000000001c2:  E9 D1 FE          jmp   label_1



ENDP

PROC D_INTERRUPT_ENDMARKER_
PUBLIC D_INTERRUPT_ENDMARKER_
ENDP

END
