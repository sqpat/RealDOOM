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

PROC  SM_LOAD_STARTMARKER_
PUBLIC  SM_LOAD_STARTMARKER_

ENDP



0x0000000000000000:  53                   push      bx
0x0000000000000001:  51                   push      cx
0x0000000000000002:  52                   push      dx
0x0000000000000003:  56                   push      si
0x0000000000000004:  57                   push      di
0x0000000000000005:  55                   push      bp
0x0000000000000006:  89 E5                mov       bp, sp
0x0000000000000008:  83 EC 10             sub       sp, 0x10
0x000000000000000b:  50                   push      ax
0x000000000000000c:  8B 3E 08 1B          mov       di, word ptr [0x1b08]
0x0000000000000010:  31 F6                xor       si, si
0x0000000000000012:  31 DB                xor       bx, bx
0x0000000000000014:  89 76 F6             mov       word ptr [bp - 0xa], si
0x0000000000000017:  89 7E F8             mov       word ptr [bp - 8], di
0x000000000000001a:  89 F9                mov       cx, di
0x000000000000001c:  89 76 F0             mov       word ptr [bp - 0x10], si
0x000000000000001f:  9A 1A 48 06 1F       lcall     0x1f06:0x481a
0x0000000000000024:  8E C7                mov       es, di
0x0000000000000026:  89 7E FC             mov       word ptr [bp - 4], di
0x0000000000000029:  26 81 3C 4D 55       cmp       word ptr es:[si], 0x554d
0x000000000000002e:  74 03                je        0x33
0x0000000000000030:  E9 2B 01             jmp       0x15e
0x0000000000000033:  26 81 7C 02 53 1A    cmp       word ptr es:[si + 2], 0x1a53
0x0000000000000039:  75 F5                jne       0x30
0x000000000000003b:  89 36 9E 1A          mov       word ptr [0x1a9e], si
0x000000000000003f:  89 36 2C 0D          mov       word ptr [0xd2c], si
0x0000000000000043:  26 8B 44 04          mov       ax, word ptr es:[si + 4]
0x0000000000000047:  26 8B 4C 08          mov       cx, word ptr es:[si + 8]
0x000000000000004b:  A3 94 1A             mov       word ptr [0x1a94], ax
0x000000000000004e:  89 0E 9A 1A          mov       word ptr [0x1a9a], cx
0x0000000000000052:  26 8B 44 06          mov       ax, word ptr es:[si + 6]
0x0000000000000056:  26 8B 4C 0A          mov       cx, word ptr es:[si + 0xa]
0x000000000000005a:  A3 96 1A             mov       word ptr [0x1a96], ax
0x000000000000005d:  89 0E 9C 1A          mov       word ptr [0x1a9c], cx
0x0000000000000061:  A3 A0 1A             mov       word ptr [0x1aa0], ax
0x0000000000000064:  A1 2A 0D             mov       ax, word ptr [0xd2a]
0x0000000000000067:  26 8B 4C 0C          mov       cx, word ptr es:[si + 0xc]
0x000000000000006b:  8B 36 28 0D          mov       si, word ptr [0xd28]
0x000000000000006f:  89 0E 98 1A          mov       word ptr [0x1a98], cx
0x0000000000000073:  85 C0                test      ax, ax
0x0000000000000075:  75 04                jne       0x7b
0x0000000000000077:  85 F6                test      si, si
0x0000000000000079:  74 6D                je        0xe8
0x000000000000007b:  8E C0                mov       es, ax
0x000000000000007d:  26 8A 44 34          mov       al, byte ptr es:[si + 0x34]
0x0000000000000081:  3C 01                cmp       al, 1
0x0000000000000083:  74 04                je        0x89
0x0000000000000085:  3C 02                cmp       al, 2
0x0000000000000087:  75 5F                jne       0xe8
0x0000000000000089:  A1 28 0D             mov       ax, word ptr [0xd28]
0x000000000000008c:  30 D2                xor       dl, dl
0x000000000000008e:  8E 06 2A 0D          mov       es, word ptr [0xd2a]
0x0000000000000092:  89 C1                mov       cx, ax
0x0000000000000094:  8C 46 FE             mov       word ptr [bp - 2], es
0x0000000000000097:  83 C1 36             add       cx, 0x36
0x000000000000009a:  05 26 04             add       ax, 0x426
0x000000000000009d:  89 4E F2             mov       word ptr [bp - 0xe], cx
0x00000000000000a0:  89 46 FA             mov       word ptr [bp - 6], ax
0x00000000000000a3:  B9 AF 00             mov       cx, 0xaf
0x00000000000000a6:  B0 FF                mov       al, 0xff
0x00000000000000a8:  8B 7E FA             mov       di, word ptr [bp - 6]
0x00000000000000ab:  8C 46 F4             mov       word ptr [bp - 0xc], es
0x00000000000000ae:  57                   push      di
0x00000000000000af:  8A E0                mov       ah, al
0x00000000000000b1:  D1 E9                shr       cx, 1
0x00000000000000b3:  F3 AB                rep stosw word ptr es:[di], ax
0x00000000000000b5:  13 C9                adc       cx, cx
0x00000000000000b7:  F3 AA                rep stosb byte ptr es:[di], al
0x00000000000000b9:  5F                   pop       di
0x00000000000000ba:  88 D0                mov       al, dl
0x00000000000000bc:  98                   cwde      
0x00000000000000bd:  3B 06 98 1A          cmp       ax, word ptr [0x1a98]
0x00000000000000c1:  73 2C                jae       0xef
0x00000000000000c3:  88 D0                mov       al, dl
0x00000000000000c5:  98                   cwde      
0x00000000000000c6:  8B 76 F0             mov       si, word ptr [bp - 0x10]
0x00000000000000c9:  01 C0                add       ax, ax
0x00000000000000cb:  8E 46 FC             mov       es, word ptr [bp - 4]
0x00000000000000ce:  01 C6                add       si, ax
0x00000000000000d0:  26 8B 44 10          mov       ax, word ptr es:[si + 0x10]
0x00000000000000d4:  3D 7F 00             cmp       ax, 0x7f
0x00000000000000d7:  77 11                ja        0xea
0x00000000000000d9:  8B 76 FA             mov       si, word ptr [bp - 6]
0x00000000000000dc:  8E 46 F4             mov       es, word ptr [bp - 0xc]
0x00000000000000df:  01 C6                add       si, ax
0x00000000000000e1:  26 88 14             mov       byte ptr es:[si], dl
0x00000000000000e4:  FE C2                inc       dl
0x00000000000000e6:  EB D2                jmp       0xba
0x00000000000000e8:  EB 6A                jmp       0x154
0x00000000000000ea:  2D 07 00             sub       ax, 7
0x00000000000000ed:  EB EA                jmp       0xd9
0x00000000000000ef:  8B 5E F6             mov       bx, word ptr [bp - 0xa]
0x00000000000000f2:  8B 4E F8             mov       cx, word ptr [bp - 8]
0x00000000000000f5:  B8 84 11             mov       ax, 0x1184
0x00000000000000f8:  9A 08 48 06 1F       lcall     0x1f06:0x4808
0x00000000000000fd:  80 FE AF             cmp       dh, 0xaf
0x0000000000000100:  73 44                jae       0x146
0x0000000000000102:  88 F0                mov       al, dh
0x0000000000000104:  8B 76 FA             mov       si, word ptr [bp - 6]
0x0000000000000107:  30 E4                xor       ah, ah
0x0000000000000109:  8E 46 F4             mov       es, word ptr [bp - 0xc]
0x000000000000010c:  01 C6                add       si, ax
0x000000000000010e:  26 8A 14             mov       dl, byte ptr es:[si]
0x0000000000000111:  80 FA FF             cmp       dl, 0xff
0x0000000000000114:  74 29                je        0x13f
0x0000000000000116:  6B F0 24             imul      si, ax, 0x24
0x0000000000000119:  88 D0                mov       al, dl
0x000000000000011b:  6B C0 24             imul      ax, ax, 0x24
0x000000000000011e:  8B 7E F2             mov       di, word ptr [bp - 0xe]
0x0000000000000121:  8B 0E 08 1B          mov       cx, word ptr [0x1b08]
0x0000000000000125:  8E 46 FE             mov       es, word ptr [bp - 2]
0x0000000000000128:  83 C6 08             add       si, 8
0x000000000000012b:  01 C7                add       di, ax
0x000000000000012d:  B8 24 00             mov       ax, 0x24
0x0000000000000130:  1E                   push      ds
0x0000000000000131:  57                   push      di
0x0000000000000132:  91                   xchg      ax, cx
0x0000000000000133:  8E D8                mov       ds, ax
0x0000000000000135:  D1 E9                shr       cx, 1
0x0000000000000137:  F3 A5                rep movsw word ptr es:[di], word ptr [si]
0x0000000000000139:  13 C9                adc       cx, cx
0x000000000000013b:  F3 A4                rep movsb byte ptr es:[di], byte ptr [si]
0x000000000000013d:  5F                   pop       di
0x000000000000013e:  1F                   pop       ds
0x000000000000013f:  FE C6                inc       dh
0x0000000000000141:  80 FE AF             cmp       dh, 0xaf
0x0000000000000144:  72 BC                jb        0x102
0x0000000000000146:  8B 5E F6             mov       bx, word ptr [bp - 0xa]
0x0000000000000149:  8B 4E F8             mov       cx, word ptr [bp - 8]
0x000000000000014c:  8B 46 EE             mov       ax, word ptr [bp - 0x12]
0x000000000000014f:  9A 1A 48 06 1F       lcall     0x1f06:0x481a
0x0000000000000154:  B8 01 00             mov       ax, 1
0x0000000000000157:  C9                   leave     
0x0000000000000158:  5F                   pop       di
0x0000000000000159:  5E                   pop       si
0x000000000000015a:  5A                   pop       dx
0x000000000000015b:  59                   pop       cx
0x000000000000015c:  5B                   pop       bx
0x000000000000015d:  CB                   retf      
0x000000000000015e:  B8 FF FF             mov       ax, 0xffff
0x0000000000000161:  C9                   leave     
0x0000000000000162:  5F                   pop       di
0x0000000000000163:  5E                   pop       si
0x0000000000000164:  5A                   pop       dx
0x0000000000000165:  59                   pop       cx
0x0000000000000166:  5B                   pop       bx
0x0000000000000167:  CB                   retf    



PROC  SM_LOAD_ENDMARKER_
PUBLIC  SM_LOAD_ENDMARKER_

ENDP


END