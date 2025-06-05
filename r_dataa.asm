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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

 
EXTRN P_MobjThinker_:NEAR
EXTRN OutOfThinkers_:NEAR
EXTRN P_PlayerThink_:NEAR
EXTRN P_UpdateSpecials_:NEAR


.DATA

EXTRN _prndindex:BYTE
EXTRN _setStateReturn:WORD
EXTRN _attackrange16:WORD
EXTRN _currentThinkerListHead:WORD
EXTRN _paused:BYTE
EXTRN _menuactive:BYTE
EXTRN _demoplayback:BYTE
EXTRN _player:WORD
EXTRN _leveltime:DWORD

.CODE




 

COMMENT @


PROC R_MarkL1SpriteCacheMRU_ NEAR
PUBLIC R_MarkL1SpriteCacheMRU_


0x0000000000000030:  52                   push dx
0x0000000000000031:  98                   cwde 
0x0000000000000032:  3B 06 28 1C          cmp  ax, word ptr ds:[_sprite1LRU+0]
0x0000000000000036:  74 12                je   0x4a
0x0000000000000038:  3B 06 2A 1C          cmp  ax, word ptr ds:[_sprite1LRU+2]
0x000000000000003c:  74 0E                je   0x4c
0x000000000000003e:  3B 06 2C 1C          cmp  ax, word ptr ds:[_sprite1LRU+4]
0x0000000000000042:  74 15                je   0x59
0x0000000000000044:  3B 06 2E 1C          cmp  ax, word ptr ds:[_sprite1LRU+6]
0x0000000000000048:  74 24                je   0x6e
0x000000000000004a:  5A                   pop  dx
0x000000000000004b:  C3                   ret  
0x000000000000004c:  8B 16 28 1C          mov  dx, word ptr ds:[_sprite1LRU+0]
0x0000000000000050:  89 16 2A 1C          mov  word ptr ds:[_sprite1LRU+2], dx
0x0000000000000054:  A3 28 1C             mov  word ptr ds:[_sprite1LRU+0], ax
0x0000000000000057:  5A                   pop  dx
0x0000000000000058:  C3                   ret  
0x0000000000000059:  8B 16 2A 1C          mov  dx, word ptr ds:[_sprite1LRU+2]
0x000000000000005d:  89 16 2C 1C          mov  word ptr ds:[_sprite1LRU+4], dx
0x0000000000000061:  8B 16 28 1C          mov  dx, word ptr ds:[_sprite1LRU+0]
0x0000000000000065:  89 16 2A 1C          mov  word ptr ds:[_sprite1LRU+2], dx
0x0000000000000069:  A3 28 1C             mov  word ptr ds:[_sprite1LRU+0], ax
0x000000000000006c:  5A                   pop  dx
0x000000000000006d:  C3                   ret  
0x000000000000006e:  8B 16 2C 1C          mov  dx, word ptr ds:[_sprite1LRU+4]
0x0000000000000072:  89 16 2E 1C          mov  word ptr ds:[_sprite1LRU+6], dx
0x0000000000000076:  8B 16 2A 1C          mov  dx, word ptr ds:[_sprite1LRU+2]
0x000000000000007a:  89 16 2C 1C          mov  word ptr ds:[_sprite1LRU+4], dx
0x000000000000007e:  8B 16 28 1C          mov  dx, word ptr ds:[_sprite1LRU+0]
0x0000000000000082:  89 16 2A 1C          mov  word ptr ds:[_sprite1LRU+2], dx
0x0000000000000086:  A3 28 1C             mov  word ptr ds:[_sprite1LRU+0], ax
0x0000000000000089:  5A                   pop  dx
0x000000000000008a:  C3                   ret  

ENDP

PROC R_MarkL1SpriteCacheMRU3_ NEAR
PUBLIC R_MarkL1SpriteCacheMRU3_

0x000000000000008c:  52                   push dx
0x000000000000008d:  8B 16 2C 1C          mov  dx, word ptr ds:[_sprite1LRU+4]
0x0000000000000091:  89 16 2E 1C          mov  word ptr ds:[_sprite1LRU+6], dx
0x0000000000000095:  8B 16 2A 1C          mov  dx, word ptr ds:[_sprite1LRU+2]
0x0000000000000099:  89 16 2C 1C          mov  word ptr ds:[_sprite1LRU+4], dx
0x000000000000009d:  8B 16 28 1C          mov  dx, word ptr ds:[_sprite1LRU+0]
0x00000000000000a1:  98                   cwde 
0x00000000000000a2:  89 16 2A 1C          mov  word ptr ds:[_sprite1LRU+2], dx
0x00000000000000a6:  A3 28 1C             mov  word ptr ds:[_sprite1LRU+0], ax
0x00000000000000a9:  5A                   pop  dx
0x00000000000000aa:  C3                   ret  

ENDP

PROC R_MarkL1TextureCacheMRU_ NEAR
PUBLIC R_MarkL1TextureCacheMRU_


0x00000000000000ac:  52                   push dx
0x00000000000000ad:  98                   cwde 
0x00000000000000ae:  3B 06 38 1C          cmp  ax, word ptr ds:[_textureL1LRU+0]
0x00000000000000b2:  74 2A                je   0xde
0x00000000000000b4:  3B 06 3A 1C          cmp  ax, word ptr ds:[_textureL1LRU+2]
0x00000000000000b8:  74 26                je   0xe0
0x00000000000000ba:  3B 06 3C 1C          cmp  ax, word ptr ds:[_textureL1LRU+4]
0x00000000000000be:  74 2D                je   0xed
0x00000000000000c0:  3B 06 3E 1C          cmp  ax, word ptr ds:[_textureL1LRU+6]
0x00000000000000c4:  74 3C                je   0x102
0x00000000000000c6:  3B 06 40 1C          cmp  ax, word ptr ds:[_textureL1LRU+8]
0x00000000000000ca:  74 53                je   0x11f
0x00000000000000cc:  3B 06 42 1C          cmp  ax, word ptr ds:[_textureL1LRU+0Ah]
0x00000000000000d0:  74 76                je   0x148
0x00000000000000d2:  3B 06 44 1C          cmp  ax, word ptr ds:[_textureL1LRU+0Ch]
0x00000000000000d6:  74 6C                je   0x144
0x00000000000000d8:  3B 06 46 1C          cmp  ax, word ptr ds:[_textureL1LRU+0Eh]
0x00000000000000dc:  74 68                je   0x146
0x00000000000000de:  5A                   pop  dx
0x00000000000000df:  C3                   ret  
0x00000000000000e0:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x00000000000000e4:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x00000000000000e8:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x00000000000000eb:  5A                   pop  dx
0x00000000000000ec:  C3                   ret  
0x00000000000000ed:  8B 16 3A 1C          mov  dx, word ptr ds:[_textureL1LRU+2]
0x00000000000000f1:  89 16 3C 1C          mov  word ptr ds:[_textureL1LRU+4], dx
0x00000000000000f5:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x00000000000000f9:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x00000000000000fd:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x0000000000000100:  5A                   pop  dx
0x0000000000000101:  C3                   ret  
0x0000000000000102:  8B 16 3C 1C          mov  dx, word ptr ds:[_textureL1LRU+4]
0x0000000000000106:  89 16 3E 1C          mov  word ptr ds:[_textureL1LRU+6], dx
0x000000000000010a:  8B 16 3A 1C          mov  dx, word ptr ds:[_textureL1LRU+2]
0x000000000000010e:  89 16 3C 1C          mov  word ptr ds:[_textureL1LRU+4], dx
0x0000000000000112:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x0000000000000116:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x000000000000011a:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x000000000000011d:  5A                   pop  dx
0x000000000000011e:  C3                   ret  
0x000000000000011f:  8B 16 3E 1C          mov  dx, word ptr ds:[_textureL1LRU+6]
0x0000000000000123:  89 16 40 1C          mov  word ptr ds:[_textureL1LRU+8], dx
0x0000000000000127:  8B 16 3C 1C          mov  dx, word ptr ds:[_textureL1LRU+4]
0x000000000000012b:  89 16 3E 1C          mov  word ptr ds:[_textureL1LRU+6], dx
0x000000000000012f:  8B 16 3A 1C          mov  dx, word ptr ds:[_textureL1LRU+2]
0x0000000000000133:  89 16 3C 1C          mov  word ptr ds:[_textureL1LRU+4], dx
0x0000000000000137:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x000000000000013b:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x000000000000013f:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x0000000000000142:  5A                   pop  dx
0x0000000000000143:  C3                   ret  
0x0000000000000144:  EB 2F                jmp  0x175
0x0000000000000146:  EB 62                jmp  0x1aa
0x0000000000000148:  8B 16 40 1C          mov  dx, word ptr ds:[_textureL1LRU+8]
0x000000000000014c:  89 16 42 1C          mov  word ptr ds:[_textureL1LRU+0Ah], dx
0x0000000000000150:  8B 16 3E 1C          mov  dx, word ptr ds:[_textureL1LRU+6]
0x0000000000000154:  89 16 40 1C          mov  word ptr ds:[_textureL1LRU+8], dx
0x0000000000000158:  8B 16 3C 1C          mov  dx, word ptr ds:[_textureL1LRU+4]
0x000000000000015c:  89 16 3E 1C          mov  word ptr ds:[_textureL1LRU+6], dx
0x0000000000000160:  8B 16 3A 1C          mov  dx, word ptr ds:[_textureL1LRU+2]
0x0000000000000164:  89 16 3C 1C          mov  word ptr ds:[_textureL1LRU+4], dx
0x0000000000000168:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x000000000000016c:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x0000000000000170:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x0000000000000173:  5A                   pop  dx
0x0000000000000174:  C3                   ret  
0x0000000000000175:  8B 16 42 1C          mov  dx, word ptr ds:[_textureL1LRU+0Ah]
0x0000000000000179:  89 16 44 1C          mov  word ptr ds:[_textureL1LRU+0Ch], dx
0x000000000000017d:  8B 16 40 1C          mov  dx, word ptr ds:[_textureL1LRU+8]
0x0000000000000181:  89 16 42 1C          mov  word ptr ds:[_textureL1LRU+0Ah], dx
0x0000000000000185:  8B 16 3E 1C          mov  dx, word ptr ds:[_textureL1LRU+6]
0x0000000000000189:  89 16 40 1C          mov  word ptr ds:[_textureL1LRU+8], dx
0x000000000000018d:  8B 16 3C 1C          mov  dx, word ptr ds:[_textureL1LRU+4]
0x0000000000000191:  89 16 3E 1C          mov  word ptr ds:[_textureL1LRU+6], dx
0x0000000000000195:  8B 16 3A 1C          mov  dx, word ptr ds:[_textureL1LRU+2]
0x0000000000000199:  89 16 3C 1C          mov  word ptr ds:[_textureL1LRU+4], dx
0x000000000000019d:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x00000000000001a1:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x00000000000001a5:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x00000000000001a8:  5A                   pop  dx
0x00000000000001a9:  C3                   ret  
0x00000000000001aa:  8B 16 44 1C          mov  dx, word ptr ds:[_textureL1LRU+0Ch]
0x00000000000001ae:  89 16 46 1C          mov  word ptr ds:[_textureL1LRU+0Eh], dx
0x00000000000001b2:  8B 16 42 1C          mov  dx, word ptr ds:[_textureL1LRU+0Ah]
0x00000000000001b6:  89 16 44 1C          mov  word ptr ds:[_textureL1LRU+0Ch], dx
0x00000000000001ba:  8B 16 40 1C          mov  dx, word ptr ds:[_textureL1LRU+8]
0x00000000000001be:  89 16 42 1C          mov  word ptr ds:[_textureL1LRU+0Ah], dx
0x00000000000001c2:  8B 16 3E 1C          mov  dx, word ptr ds:[_textureL1LRU+6]
0x00000000000001c6:  89 16 40 1C          mov  word ptr ds:[_textureL1LRU+8], dx
0x00000000000001ca:  8B 16 3C 1C          mov  dx, word ptr ds:[_textureL1LRU+4]
0x00000000000001ce:  89 16 3E 1C          mov  word ptr ds:[_textureL1LRU+6], dx
0x00000000000001d2:  8B 16 3A 1C          mov  dx, word ptr ds:[_textureL1LRU+2]
0x00000000000001d6:  89 16 3C 1C          mov  word ptr ds:[_textureL1LRU+4], dx
0x00000000000001da:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x00000000000001de:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x00000000000001e2:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x00000000000001e5:  5A                   pop  dx
0x00000000000001e6:  C3                   ret  

ENDP

PROC R_MarkL1TextureCacheMRU7_ NEAR
PUBLIC R_MarkL1TextureCacheMRU7_


0x00000000000001e8:  52                   push dx
0x00000000000001e9:  8B 16 44 1C          mov  dx, word ptr ds:[_textureL1LRU+0Ch]
0x00000000000001ed:  89 16 46 1C          mov  word ptr ds:[_textureL1LRU+0Eh], dx
0x00000000000001f1:  8B 16 42 1C          mov  dx, word ptr ds:[_textureL1LRU+0Ah]
0x00000000000001f5:  89 16 44 1C          mov  word ptr ds:[_textureL1LRU+0Ch], dx
0x00000000000001f9:  8B 16 40 1C          mov  dx, word ptr ds:[_textureL1LRU+8]
0x00000000000001fd:  89 16 42 1C          mov  word ptr ds:[_textureL1LRU+0Ah], dx
0x0000000000000201:  8B 16 3E 1C          mov  dx, word ptr ds:[_textureL1LRU+6]
0x0000000000000205:  89 16 40 1C          mov  word ptr ds:[_textureL1LRU+8], dx
0x0000000000000209:  8B 16 3C 1C          mov  dx, word ptr ds:[_textureL1LRU+4]
0x000000000000020d:  89 16 3E 1C          mov  word ptr ds:[_textureL1LRU+6], dx
0x0000000000000211:  8B 16 3A 1C          mov  dx, word ptr ds:[_textureL1LRU+2]
0x0000000000000215:  89 16 3C 1C          mov  word ptr ds:[_textureL1LRU+4], dx
0x0000000000000219:  8B 16 38 1C          mov  dx, word ptr ds:[_textureL1LRU+0]
0x000000000000021d:  98                   cwde 
0x000000000000021e:  89 16 3A 1C          mov  word ptr ds:[_textureL1LRU+2], dx
0x0000000000000222:  A3 38 1C             mov  word ptr ds:[_textureL1LRU+0], ax
0x0000000000000225:  5A                   pop  dx
0x0000000000000226:  C3                   ret  

ENDP

PROC R_MarkL2CompositeTextureCacheMRU_ NEAR
PUBLIC R_MarkL2CompositeTextureCacheMRU_

0x0000000000000228:  53                   push bx
0x0000000000000229:  51                   push cx
0x000000000000022a:  52                   push dx
0x000000000000022b:  56                   push si
0x000000000000022c:  8A 0E AA 06          mov  cl, byte ptr ds:[_texturecache_l2_head]
0x0000000000000230:  88 C2                mov  dl, al
0x0000000000000232:  38 C8                cmp  al, cl
0x0000000000000234:  74 50                je   0x286
0x0000000000000236:  98                   cwde 
0x0000000000000237:  89 C3                mov  bx, ax
0x0000000000000239:  C1 E3 02             shl  bx, 2
0x000000000000023c:  8A 87 0A 18          mov  al, byte ptr ds:[bx + _texturecache_nodes+2]
0x0000000000000240:  84 C0                test al, al
0x0000000000000242:  74 1C                je   0x260
0x0000000000000244:  88 D0                mov  al, dl
0x0000000000000246:  98                   cwde 
0x0000000000000247:  89 C3                mov  bx, ax
0x0000000000000249:  C1 E3 02             shl  bx, 2
0x000000000000024c:  8A 87 0B 18          mov  al, byte ptr ds:[bx + _texturecache_nodes+3]
0x0000000000000250:  3A 87 0A 18          cmp  al, byte ptr ds:[bx + _texturecache_nodes+2]
0x0000000000000254:  74 06                je   0x25c
0x0000000000000256:  8A 97 09 18          mov  dl, byte ptr ss[bx + _texturecache_nodes+1]
0x000000000000025a:  EB E8                jmp  0x244
0x000000000000025c:  38 CA                cmp  dl, cl
0x000000000000025e:  74 26                je   0x286
0x0000000000000260:  88 D0                mov  al, dl
0x0000000000000262:  98                   cwde 
0x0000000000000263:  89 C3                mov  bx, ax
0x0000000000000265:  C1 E3 02             shl  bx, 2
0x0000000000000268:  80 BF 0B 18 00       cmp  byte ptr ds:[bx + _texturecache_nodes+3], 0
0x000000000000026d:  74 70                je   0x2df
0x000000000000026f:  88 D6                mov  dh, dl
0x0000000000000271:  88 F0                mov  al, dh
0x0000000000000273:  98                   cwde 
0x0000000000000274:  89 C3                mov  bx, ax
0x0000000000000276:  C1 E3 02             shl  bx, 2
0x0000000000000279:  80 BF 0A 18 01       cmp  byte ptr ds:[bx + _texturecache_nodes+2], 1
0x000000000000027e:  74 08                je   0x288
0x0000000000000280:  8A B7 08 18          mov  dh, byte ptr ds:[bx + _texturecache_nodes+0]
0x0000000000000284:  EB EB                jmp  0x271
0x0000000000000286:  EB 4E                jmp  0x2d6
0x0000000000000288:  88 D0                mov  al, dl
0x000000000000028a:  98                   cwde 
0x000000000000028b:  89 C6                mov  si, ax
0x000000000000028d:  C1 E6 02             shl  si, 2
0x0000000000000290:  8A BF 08 18          mov  bh, byte ptr ds:[bx + _texturecache_nodes+0]
0x0000000000000294:  8A 9C 09 18          mov  bl, byte ptr ds:[si + _texturecache_nodes+1]
0x0000000000000298:  3A 36 AB 06          cmp  dh, byte ptr ds:[_texturecache_l2_tail]
0x000000000000029c:  75 43                jne  0x2e1
0x000000000000029e:  88 D8                mov  al, bl
0x00000000000002a0:  98                   cwde 
0x00000000000002a1:  88 1E AB 06          mov  byte ptr ds:[_texturecache_l2_tail], bl
0x00000000000002a5:  89 C3                mov  bx, ax
0x00000000000002a7:  C1 E3 02             shl  bx, 2
0x00000000000002aa:  C6 87 08 18 FF       mov  byte ptr ds:[bx + _texturecache_nodes+0], 0xff
0x00000000000002af:  88 F0                mov  al, dh
0x00000000000002b1:  98                   cwde 
0x00000000000002b2:  89 C3                mov  bx, ax
0x00000000000002b4:  88 C8                mov  al, cl
0x00000000000002b6:  C1 E3 02             shl  bx, 2
0x00000000000002b9:  98                   cwde 
0x00000000000002ba:  88 8F 08 18          mov  byte ptr ds:[bx + _texturecache_nodes+0], cl
0x00000000000002be:  89 C3                mov  bx, ax
0x00000000000002c0:  88 D0                mov  al, dl
0x00000000000002c2:  C1 E3 02             shl  bx, 2
0x00000000000002c5:  98                   cwde 
0x00000000000002c6:  88 B7 09 18          mov  byte ptr ds:[bx + _texturecache_nodes+1], dh
0x00000000000002ca:  89 C3                mov  bx, ax
0x00000000000002cc:  C1 E3 02             shl  bx, 2
0x00000000000002cf:  88 D1                mov  cl, dl
0x00000000000002d1:  C6 87 09 18 FF       mov  byte ptr ds:[bx + _texturecache_nodes+1], 0xff
0x00000000000002d6:  88 0E AA 06          mov  byte ptr ds:[_texturecache_l2_head], cl
0x00000000000002da:  5E                   pop  si
0x00000000000002db:  5A                   pop  dx
0x00000000000002dc:  59                   pop  cx
0x00000000000002dd:  5B                   pop  bx
0x00000000000002de:  C3                   ret  
0x00000000000002df:  EB 1A                jmp  0x2fb
0x00000000000002e1:  88 F8                mov  al, bh
0x00000000000002e3:  98                   cwde 
0x00000000000002e4:  89 C6                mov  si, ax
0x00000000000002e6:  88 D8                mov  al, bl
0x00000000000002e8:  C1 E6 02             shl  si, 2
0x00000000000002eb:  98                   cwde 
0x00000000000002ec:  88 9C 09 18          mov  byte ptr ds:[si + _texturecache_nodes+1], bl
0x00000000000002f0:  89 C6                mov  si, ax
0x00000000000002f2:  C1 E6 02             shl  si, 2
0x00000000000002f5:  88 BC 08 18          mov  byte ptr ds:[si + _texturecache_nodes+0], bh
0x00000000000002f9:  EB B4                jmp  0x2af
0x00000000000002fb:  8A B7 09 18          mov  dh, byte ptr ds:[bx + _texturecache_nodes+1]
0x00000000000002ff:  8A AF 08 18          mov  ch, byte ptr ds:[bx + _texturecache_nodes+0]
0x0000000000000303:  3A 16 AB 06          cmp  dl, byte ptr ds:[_texturecache_l2_tail]
0x0000000000000307:  75 38                jne  0x341
0x0000000000000309:  88 36 AB 06          mov  byte ptr ds:[_texturecache_l2_tail], dh
0x000000000000030d:  88 F0                mov  al, dh
0x000000000000030f:  98                   cwde 
0x0000000000000310:  89 C3                mov  bx, ax
0x0000000000000312:  88 D0                mov  al, dl
0x0000000000000314:  C1 E3 02             shl  bx, 2
0x0000000000000317:  98                   cwde 
0x0000000000000318:  88 AF 08 18          mov  byte ptr ds:[bx + _texturecache_nodes+0], ch
0x000000000000031c:  89 C3                mov  bx, ax
0x000000000000031e:  C1 E3 02             shl  bx, 2
0x0000000000000321:  88 C8                mov  al, cl
0x0000000000000323:  C6 87 09 18 FF       mov  byte ptr ds:[bx + _texturecache_nodes+1], 0xff
0x0000000000000328:  98                   cwde 
0x0000000000000329:  88 8F 08 18          mov  byte ptr ds:[bx + _texturecache_nodes+0], cl
0x000000000000032d:  89 C3                mov  bx, ax
0x000000000000032f:  C1 E3 02             shl  bx, 2
0x0000000000000332:  88 D1                mov  cl, dl
0x0000000000000334:  88 97 09 18          mov  byte ptr ds:[bx + _texturecache_nodes+1], dl
0x0000000000000338:  88 0E AA 06          mov  byte ptr ds:[_texturecache_l2_head], cl
0x000000000000033c:  5E                   pop  si
0x000000000000033d:  5A                   pop  dx
0x000000000000033e:  59                   pop  cx
0x000000000000033f:  5B                   pop  bx
0x0000000000000340:  C3                   ret  
0x0000000000000341:  88 E8                mov  al, ch
0x0000000000000343:  98                   cwde 
0x0000000000000344:  89 C3                mov  bx, ax
0x0000000000000346:  C1 E3 02             shl  bx, 2
0x0000000000000349:  88 B7 09 18          mov  byte ptr ds:[bx + _texturecache_nodes+1], dh
0x000000000000034d:  EB BE                jmp  0x30d


ENDP

PROC R_MarkL2SpriteCacheMRU_ NEAR
PUBLIC R_MarkL2SpriteCacheMRU_

0x0000000000000350:  53                   push bx
0x0000000000000351:  51                   push cx
0x0000000000000352:  52                   push dx
0x0000000000000353:  56                   push si
0x0000000000000354:  8A 0E A6 06          mov  cl, byte ptr ds:[_spritecache_l2_head]
0x0000000000000358:  88 C2                mov  dl, al
0x000000000000035a:  38 C8                cmp  al, cl
0x000000000000035c:  74 50                je   0x3ae
0x000000000000035e:  98                   cwde 
0x000000000000035f:  89 C3                mov  bx, ax
0x0000000000000361:  C1 E3 02             shl  bx, 2
0x0000000000000364:  8A 87 6A 18          mov  al, byte ptr ds:[bx + _spritecache_nodes+2]
0x0000000000000368:  84 C0                test al, al
0x000000000000036a:  74 1C                je   0x388
0x000000000000036c:  88 D0                mov  al, dl
0x000000000000036e:  98                   cwde 
0x000000000000036f:  89 C3                mov  bx, ax
0x0000000000000371:  C1 E3 02             shl  bx, 2
0x0000000000000374:  8A 87 6B 18          mov  al, byte ptr ds:[bx + _spritecache_nodes+2]
0x0000000000000378:  3A 87 6A 18          cmp  al, byte ptr ds:[bx + _spritecache_nodes+2]
0x000000000000037c:  74 06                je   0x384
0x000000000000037e:  8A 97 69 18          mov  dl, byte ptr ds:[bx + _spritecache_nodes+1]
0x0000000000000382:  EB E8                jmp  0x36c
0x0000000000000384:  38 CA                cmp  dl, cl
0x0000000000000386:  74 26                je   0x3ae
0x0000000000000388:  88 D0                mov  al, dl
0x000000000000038a:  98                   cwde 
0x000000000000038b:  89 C3                mov  bx, ax
0x000000000000038d:  C1 E3 02             shl  bx, 2
0x0000000000000390:  80 BF 6B 18 00       cmp  byte ptr ds:[bx + _spritecache_nodes+3], 0
0x0000000000000395:  74 70                je   0x407
0x0000000000000397:  88 D6                mov  dh, dl
0x0000000000000399:  88 F0                mov  al, dh
0x000000000000039b:  98                   cwde 
0x000000000000039c:  89 C3                mov  bx, ax
0x000000000000039e:  C1 E3 02             shl  bx, 2
0x00000000000003a1:  80 BF 6A 18 01       cmp  byte ptr ds:[bx + _spritecache_nodes+2], 1
0x00000000000003a6:  74 08                je   0x3b0
0x00000000000003a8:  8A B7 68 18          mov  dh, byte ptr ds:[bx + _spritecache_nodes+0]
0x00000000000003ac:  EB EB                jmp  0x399
0x00000000000003ae:  EB 4E                jmp  0x3fe
0x00000000000003b0:  88 D0                mov  al, dl
0x00000000000003b2:  98                   cwde 
0x00000000000003b3:  89 C6                mov  si, ax
0x00000000000003b5:  C1 E6 02             shl  si, 2
0x00000000000003b8:  8A BF 68 18          mov  bh, byte ptr ds[bx + _spritecache_nodes+0]
0x00000000000003bc:  8A 9C 69 18          mov  bl, byte ptr ds:[si + _spritecache_nodes+1]
0x00000000000003c0:  3A 36 A7 06          cmp  dh, byte ptr ds:[_spritecache_l2_tail]
0x00000000000003c4:  75 43                jne  0x409
0x00000000000003c6:  88 D8                mov  al, bl
0x00000000000003c8:  98                   cwde 
0x00000000000003c9:  88 1E A7 06          mov  byte ptr ds:[_spritecache_l2_tail], bl
0x00000000000003cd:  89 C3                mov  bx, ax
0x00000000000003cf:  C1 E3 02             shl  bx, 2
0x00000000000003d2:  C6 87 68 18 FF       mov  byte ptr ds:[bx + _spritecache_nodes+0], 0xff
0x00000000000003d7:  88 F0                mov  al, dh
0x00000000000003d9:  98                   cwde 
0x00000000000003da:  89 C3                mov  bx, ax
0x00000000000003dc:  88 C8                mov  al, cl
0x00000000000003de:  C1 E3 02             shl  bx, 2
0x00000000000003e1:  98                   cwde 
0x00000000000003e2:  88 8F 68 18          mov  byte ptr ds:[bx + _spritecache_nodes+0], cl
0x00000000000003e6:  89 C3                mov  bx, ax
0x00000000000003e8:  88 D0                mov  al, dl
0x00000000000003ea:  C1 E3 02             shl  bx, 2
0x00000000000003ed:  98                   cwde 
0x00000000000003ee:  88 B7 69 18          mov  byte ptr ds:[bx + _spritecache_nodes+1], dh
0x00000000000003f2:  89 C3                mov  bx, ax
0x00000000000003f4:  C1 E3 02             shl  bx, 2
0x00000000000003f7:  88 D1                mov  cl, dl
0x00000000000003f9:  C6 87 69 18 FF       mov  byte ptr ds:[bx + _spritecache_nodes+1], 0xff
0x00000000000003fe:  88 0E A6 06          mov  byte ptr ds:[_spritecache_l2_head], cl
0x0000000000000402:  5E                   pop  si
0x0000000000000403:  5A                   pop  dx
0x0000000000000404:  59                   pop  cx
0x0000000000000405:  5B                   pop  bx
0x0000000000000406:  C3                   ret  
0x0000000000000407:  EB 1A                jmp  0x423
0x0000000000000409:  88 F8                mov  al, bh
0x000000000000040b:  98                   cwde 
0x000000000000040c:  89 C6                mov  si, ax
0x000000000000040e:  88 D8                mov  al, bl
0x0000000000000410:  C1 E6 02             shl  si, 2
0x0000000000000413:  98                   cwde 
0x0000000000000414:  88 9C 69 18          mov  byte ptr ds:[si + _spritecache_nodes+1], bl
0x0000000000000418:  89 C6                mov  si, ax
0x000000000000041a:  C1 E6 02             shl  si, 2
0x000000000000041d:  88 BC 68 18          mov  byte ptr ds:[si + _spritecache_nodes+0], bh
0x0000000000000421:  EB B4                jmp  0x3d7
0x0000000000000423:  8A B7 69 18          mov  dh, byte ptr ds:[bx + _spritecache_nodes+1]
0x0000000000000427:  8A AF 68 18          mov  ch, byte ptr ds:[bx + _spritecache_nodes+0]
0x000000000000042b:  3A 16 A7 06          cmp  dl, byte ptr ds:[_spritecache_l2_tail]
0x000000000000042f:  75 38                jne  0x469
0x0000000000000431:  88 36 A7 06          mov  byte ptr ds:[_spritecache_l2_tail], dh
0x0000000000000435:  88 F0                mov  al, dh
0x0000000000000437:  98                   cwde 
0x0000000000000438:  89 C3                mov  bx, ax
0x000000000000043a:  88 D0                mov  al, dl
0x000000000000043c:  C1 E3 02             shl  bx, 2
0x000000000000043f:  98                   cwde 
0x0000000000000440:  88 AF 68 18          mov  byte ptr ds:[bx + _spritecache_nodes+0], ch
0x0000000000000444:  89 C3                mov  bx, ax
0x0000000000000446:  C1 E3 02             shl  bx, 2
0x0000000000000449:  88 C8                mov  al, cl
0x000000000000044b:  C6 87 69 18 FF       mov  byte ptr ds:[bx + _spritecache_nodes+1], 0xff
0x0000000000000450:  98                   cwde 
0x0000000000000451:  88 8F 68 18          mov  byte ptr ds:[bx + _spritecache_nodes+0], cl
0x0000000000000455:  89 C3                mov  bx, ax
0x0000000000000457:  C1 E3 02             shl  bx, 2
0x000000000000045a:  88 D1                mov  cl, dl
0x000000000000045c:  88 97 69 18          mov  byte ptr ds:[bx + _spritecache_nodes+1], dl
0x0000000000000460:  88 0E A6 06          mov  byte ptr ds:[_spritecache_l2_head], cl
0x0000000000000464:  5E                   pop  si
0x0000000000000465:  5A                   pop  dx
0x0000000000000466:  59                   pop  cx
0x0000000000000467:  5B                   pop  bx
0x0000000000000468:  C3                   ret  
0x0000000000000469:  88 E8                mov  al, ch
0x000000000000046b:  98                   cwde 
0x000000000000046c:  89 C3                mov  bx, ax
0x000000000000046e:  C1 E3 02             shl  bx, 2
0x0000000000000471:  88 B7 69 18          mov  byte ptr ds:[bx + _spritecache_nodes+1], dh
0x0000000000000475:  EB BE                jmp  0x435

ENDP




PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_


ENDP


@

END