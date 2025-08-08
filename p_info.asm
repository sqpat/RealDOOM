
; Copyright (C) 1993-dw 01996h
Id Software, Inc.
; Copyright (C) 1993-dw 02008h
Raven Software
; Copyright (C) 2016-dw 02017h
Alexey Khokholov (Nuke.YKT)
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


; hack but oh well
P_SIGHT_STARTMARKER_ = 0 

EXTRN P_Random_MapLocal_:NEAR
EXTRN P_SpawnPuff_:NEAR
EXTRN P_SpawnMobj_:NEAR
EXTRN P_RemoveMobj_:NEAR
EXTRN P_CheckSight_:NEAR
EXTRN P_RadiusAttack_:NEAR
EXTRN A_BFGSpray_:NEAR
EXTRN P_AimLineAttack_:NEAR
EXTRN P_LineAttack_:NEAR
EXTRN P_AproxDistance_:NEAR
EXTRN P_LineOpening_:NEAR
EXTRN P_UnsetThingPosition_:NEAR
EXTRN P_SetThingPosition_:NEAR
EXTRN P_TryMove_:NEAR
EXTRN P_CheckPosition_:NEAR
EXTRN P_SpawnMissile_:NEAR
EXTRN P_TeleportMove_:NEAR
EXTRN P_BlockThingsIterator_:NEAR

.DATA



.CODE


PROC    P_INFO_STARTMARKER_ 
PUBLIC  P_INFO_STARTMARKER_
ENDP


dw 04400h
dw 04900h
dw 04E00h
dw 05300h
dw 08000h
dw 05800h
dw 08000h
dw 08000h
dw 05D00h
dw 08000h
dw 04E00h
dw 04900h
dw 06200h
dw 06200h
dw 06700h
dw 06C00h
dw 08000h
dw 06C00h
dw 07100h
dw 07600h
dw 06700h
dw 07B00h
dw 06700h
dw 04E00h
dw 07100h
dw 04400h 


PROC    getPainChance_  NEAR 
PUBLIC  getPainChance_



0x0000000000000034:  53                push   bx
0x0000000000000035:  3C 19             cmp    al, 0x19
0x0000000000000037:  77 47             ja     label_1
0x0000000000000039:  30 E4             xor    ah, ah
0x000000000000003b:  89 C3             mov    bx, ax
0x000000000000003d:  01 C3             add    bx, ax
0x000000000000003f:  2E FF A7 00 00    jmp    word ptr cs:[bx]
0x0000000000000044:  B8 FF 00          mov    ax, 0xff
0x0000000000000047:  5B                pop    bx
0x0000000000000048:  CB                ret   
0x0000000000000049:  B8 C8 00          mov    ax, 0xc8
0x000000000000004c:  5B                pop    bx
0x000000000000004d:  CB                ret   
0x000000000000004e:  B8 AA 00          mov    ax, 0xaa
0x0000000000000051:  5B                pop    bx
0x0000000000000052:  CB                ret   
0x0000000000000053:  B8 0A 00          mov    ax, 0xa
0x0000000000000056:  5B                pop    bx
0x0000000000000057:  CB                ret   
0x0000000000000058:  B8 64 00          mov    ax, 0x64
0x000000000000005b:  5B                pop    bx
0x000000000000005c:  CB                ret   
0x000000000000005d:  B8 50 00          mov    ax, 0x50
0x0000000000000060:  5B                pop    bx
0x0000000000000061:  CB                ret   
0x0000000000000062:  B8 B4 00          mov    ax, 0xb4
0x0000000000000065:  5B                pop    bx
0x0000000000000066:  CB                ret   
0x0000000000000067:  B8 80 00          mov    ax, 0x80
0x000000000000006a:  5B                pop    bx
0x000000000000006b:  CB                ret   
0x000000000000006c:  B8 32 00          mov    ax, 0x32
0x000000000000006f:  5B                pop    bx
0x0000000000000070:  CB                ret   
0x0000000000000071:  B8 00 01          mov    ax, 0x100
0x0000000000000074:  5B                pop    bx
0x0000000000000075:  CB                ret   
0x0000000000000076:  B8 28 00          mov    ax, 0x28
0x0000000000000079:  5B                pop    bx
0x000000000000007a:  CB                ret   
0x000000000000007b:  B8 14 00          mov    ax, 0x14
0x000000000000007e:  5B                pop    bx
0x000000000000007f:  CB                ret   
label_1:
0x0000000000000080:  31 C0             xor    ax, ax
0x0000000000000082:  5B                pop    bx
0x0000000000000083:  CB                ret  

ENDP



dw 0C400h
dw 0C900h
dw 00501h
dw 00501h
dw 0CE00h
dw 00501h
dw 00501h
dw 0D300h
dw 00501h
dw 0D800h
dw 0DD00h
dw 0E200h
dw 0E200h
dw 0E700h
dw 0EC00h
dw 00501h
dw 0F100h
dw 00501h
dw 00501h
dw 0F600h
dw 00501h
dw 0FB00h
dw 00001h


PROC    getRaiseState_  NEAR 
PUBLIC  getRaiseState_


0x00000000000000b2:  53                push   bx
0x00000000000000b3:  FE C8             dec    al
0x00000000000000b5:  3C 16             cmp    al, 0x16
0x00000000000000b7:  77 4C             ja     0x105
0x00000000000000b9:  30 E4             xor    ah, ah
0x00000000000000bb:  89 C3             mov    bx, ax
0x00000000000000bd:  01 C3             add    bx, ax
0x00000000000000bf:  2E FF A7 84 00    jmp    word ptr cs:[bx + 0x84]
0x00000000000000c4:  B8 CB 00          mov    ax, 0xcb
0x00000000000000c7:  5B                pop    bx
0x00000000000000c8:  CB                ret   
0x00000000000000c9:  B8 EC 00          mov    ax, 0xec
0x00000000000000cc:  5B                pop    bx
0x00000000000000cd:  CB                ret   
0x00000000000000ce:  B8 5F 01          mov    ax, 0x15f
0x00000000000000d1:  5B                pop    bx
0x00000000000000d2:  CB                ret   
0x00000000000000d3:  B8 8E 01          mov    ax, 0x18e
0x00000000000000d6:  5B                pop    bx
0x00000000000000d7:  CB                ret   
0x00000000000000d8:  B8 B3 01          mov    ax, 0x1b3
0x00000000000000db:  5B                pop    bx
0x00000000000000dc:  CB                ret   
0x00000000000000dd:  B8 D6 01          mov    ax, 0x1d6
0x00000000000000e0:  5B                pop    bx
0x00000000000000e1:  CB                ret   
0x00000000000000e2:  B8 F0 01          mov    ax, 0x1f0
0x00000000000000e5:  5B                pop    bx
0x00000000000000e6:  CB                ret   
0x00000000000000e7:  B8 04 02          mov    ax, 0x204
0x00000000000000ea:  5B                pop    bx
0x00000000000000eb:  CB                ret   
0x00000000000000ec:  B8 25 02          mov    ax, 0x225
0x00000000000000ef:  5B                pop    bx
0x00000000000000f0:  CB                ret   
0x00000000000000f1:  B8 42 02          mov    ax, 0x242
0x00000000000000f4:  5B                pop    bx
0x00000000000000f5:  CB                ret   
0x00000000000000f6:  B8 94 02          mov    ax, 0x294
0x00000000000000f9:  5B                pop    bx
0x00000000000000fa:  CB                ret   
0x00000000000000fb:  B8 D0 02          mov    ax, 0x2d0
0x00000000000000fe:  5B                pop    bx
0x00000000000000ff:  CB                ret   
0x0000000000000100:  B8 F6 02          mov    ax, 0x2f6
0x0000000000000103:  5B                pop    bx
0x0000000000000104:  CB                ret   
0x0000000000000105:  31 C0             xor    ax, ax
0x0000000000000107:  5B                pop    bx
0x0000000000000108:  CB                ret   

ENDP


PROC    getXDeathState_ NEAR 
PUBLIC  getXDeathState_


0x000000000000010a:  3C 02             cmp    al, 2
0x000000000000010c:  73 0C             jae    0x11a
0x000000000000010e:  3C 01             cmp    al, 1
0x0000000000000110:  74 1A             je     0x12c
0x0000000000000112:  84 C0             test   al, al
0x0000000000000114:  75 26             jne    0x13c
0x0000000000000116:  B8 A5 00          mov    ax, 0xa5
0x0000000000000119:  CB                ret   
0x000000000000011a:  76 14             jbe    0x130
0x000000000000011c:  3C 17             cmp    al, 0x17
0x000000000000011e:  74 18             je     0x138
0x0000000000000120:  3C 0B             cmp    al, 0xb
0x0000000000000122:  74 10             je     0x134
0x0000000000000124:  3C 0A             cmp    al, 0xa
0x0000000000000126:  75 14             jne    0x13c
0x0000000000000128:  B8 AD 01          mov    ax, 0x1ad
0x000000000000012b:  CB                ret   
0x000000000000012c:  B8 C2 00          mov    ax, 0xc2
0x000000000000012f:  CB                ret   
0x0000000000000130:  B8 E3 00          mov    ax, 0xe3
0x0000000000000133:  CB                ret   
0x0000000000000134:  B8 CE 01          mov    ax, 0x1ce
0x0000000000000137:  CB                ret   
0x0000000000000138:  B8 ED 02          mov    ax, 0x2ed
0x000000000000013b:  CB                ret   
0x000000000000013c:  31 C0             xor    ax, ax
0x000000000000013e:  CB                ret   

ENDP

dw 06C01h
dw 08501h
dw 08501h
dw 08501h
dw 08501h
dw 08501h
dw 07101h
dw 07601h
dw 07601h
dw 08501h
dw 07B01h
dw 08501h
dw 08001h


PROC    getMeleeState_ NEAR 
PUBLIC  getMeleeState_


0x000000000000015a:  53                push   bx
0x000000000000015b:  2C 05             sub    al, 5
0x000000000000015d:  3C 0C             cmp    al, 0xc
0x000000000000015f:  77 24             ja     0x185
0x0000000000000161:  30 E4             xor    ah, ah
0x0000000000000163:  89 C3             mov    bx, ax
0x0000000000000165:  01 C3             add    bx, ax
0x0000000000000167:  2E FF A7 40 01    jmp    word ptr cs:[bx + 0x140]
0x000000000000016c:  B8 4F 01          mov    ax, 0x14f
0x000000000000016f:  5B                pop    bx
0x0000000000000170:  CB                ret   
0x0000000000000171:  B8 C4 01          mov    ax, 0x1c4
0x0000000000000174:  5B                pop    bx
0x0000000000000175:  CB                ret   
0x0000000000000176:  B8 E5 01          mov    ax, 0x1e5
0x0000000000000179:  5B                pop    bx
0x000000000000017a:  CB                ret   
0x000000000000017b:  B8 19 02          mov    ax, 0x219
0x000000000000017e:  5B                pop    bx
0x000000000000017f:  CB                ret   
0x0000000000000180:  B8 36 02          mov    ax, 0x236
0x0000000000000183:  5B                pop    bx
0x0000000000000184:  CB                ret   
0x0000000000000185:  31 C0             xor    ax, ax
0x0000000000000187:  5B                pop    bx
0x0000000000000188:  CB                ret   

ENDP

dw 0CA01h
dw 0ED01h
dw 0CA01h
dw 0ED01h
dw 0ED01h
dw 0E001h
dw 0ED01h
dw 0ED01h
dw 0ED01h
dw 0D601h
dw 0D601h
dw 0D601h
dw 0E001h
dw 0ED01h
dw 0E001h
dw 0D101h
dw 0E001h
dw 0DB01h
dw 0E001h
dw 0D601h
dw 0ED01h
dw 0E501h
dw 0E501h

PROC    getMobjMass_ NEAR 
PUBLIC  getMobjMass_


0x00000000000001b8:  53                push   bx
0x00000000000001b9:  2C 03             sub    al, 3
0x00000000000001bb:  3C 16             cmp    al, 0x16
0x00000000000001bd:  77 2E             ja     0x1ed
0x00000000000001bf:  30 E4             xor    ah, ah
0x00000000000001c1:  89 C3             mov    bx, ax
0x00000000000001c3:  01 C3             add    bx, ax
0x00000000000001c5:  2E FF A7 8A 01    jmp    word ptr cs:[bx + 0x18a]
0x00000000000001ca:  B8 F4 01          mov    ax, 0x1f4
0x00000000000001cd:  31 D2             xor    dx, dx
0x00000000000001cf:  5B                pop    bx
0x00000000000001d0:  CB                ret   
0x00000000000001d1:  B8 32 00          mov    ax, 0x32
0x00000000000001d4:  EB F7             jmp    0x1cd
0x00000000000001d6:  B8 90 01          mov    ax, 0x190
0x00000000000001d9:  EB F2             jmp    0x1cd
0x00000000000001db:  B8 58 02          mov    ax, 0x258
0x00000000000001de:  EB ED             jmp    0x1cd
0x00000000000001e0:  B8 E8 03          mov    ax, 0x3e8
0x00000000000001e3:  EB E8             jmp    0x1cd
0x00000000000001e5:  B8 80 96          mov    ax, 0x9680
0x00000000000001e8:  BA 98 00          mov    dx, 0x98
0x00000000000001eb:  5B                pop    bx
0x00000000000001ec:  CB                ret   
0x00000000000001ed:  B8 64 00          mov    ax, 0x64
0x00000000000001f0:  31 D2             xor    dx, dx
0x00000000000001f2:  5B                pop    bx
0x00000000000001f3:  CB                ret   

ENDP

dw 03402h
dw 03402h
dw 03802h
dw 04C02h
dw 03C02h
dw 04C02h
dw 04C02h
dw 03402h
dw 04C02h
dw 03402h
dw 04002h
dw 04402h
dw 04402h
dw 04402h
dw 04402h
dw 04C02h
dw 04402h
dw 04402h
dw 04402h
dw 04802h
dw 04402h
dw 04402h
dw 03402h

PROC    getActiveSound_ NEAR 
PUBLIC  getActiveSound_


0x0000000000000222:  53                push   bx
0x0000000000000223:  FE C8             dec    al
0x0000000000000225:  3C 16             cmp    al, 0x16
0x0000000000000227:  77 23             ja     0x24c
0x0000000000000229:  30 E4             xor    ah, ah
0x000000000000022b:  89 C3             mov    bx, ax
0x000000000000022d:  01 C3             add    bx, ax
0x000000000000022f:  2E FF A7 F4 01    jmp    word ptr cs:[bx + 0x1f4]
0x0000000000000234:  B0 4B             mov    al, 0x4b
0x0000000000000236:  5B                pop    bx
0x0000000000000237:  CB                ret   
0x0000000000000238:  B0 50             mov    al, 0x50
0x000000000000023a:  5B                pop    bx
0x000000000000023b:  CB                ret   
0x000000000000023c:  B0 69             mov    al, 0x69
0x000000000000023e:  5B                pop    bx
0x000000000000023f:  CB                ret   
0x0000000000000240:  B0 4C             mov    al, 0x4c
0x0000000000000242:  5B                pop    bx
0x0000000000000243:  CB                ret   
0x0000000000000244:  B0 4D             mov    al, 0x4d
0x0000000000000246:  5B                pop    bx
0x0000000000000247:  CB                ret   
0x0000000000000248:  B0 4E             mov    al, 0x4e
0x000000000000024a:  5B                pop    bx
0x000000000000024b:  CB                ret   
0x000000000000024c:  30 C0             xor    al, al
0x000000000000024e:  5B                pop    bx
0x000000000000024f:  CB                ret   

ENDP

dw 09402h
dw 09802h
dw 09802h
dw 09C02h
dw 0B402h
dw 09802h
dw 0B402h
dw 0B402h
dw 0A002h
dw 0B402h
dw 09802h
dw 09802h
dw 0A402h
dw 0A402h
dw 0A402h
dw 0A402h
dw 0B402h
dw 0A402h
dw 0A402h
dw 0A402h
dw 0A402h
dw 0A402h
dw 0A802h
dw 09802h
dw 0AC02h
dw 0B002h


PROC    getPainSound_ NEAR 
PUBLIC  getPainSound_


0x0000000000000284:  53                push bx
0x0000000000000285:  3C 19             cmp    al, 0x19
0x0000000000000287:  77 2B             ja     0x2b4
0x0000000000000289:  30 E4             xor    ah, ah
0x000000000000028b:  89 C3             mov    bx, ax
0x000000000000028d:  01 C3             add    bx, ax
0x000000000000028f:  2E FF A7 50 02    jmp    word ptr cs:[bx + 0x250]
0x0000000000000294:  B0 19             mov    al, 0x19
0x0000000000000296:  5B                pop    bx
0x0000000000000297:  CB                ret   
0x0000000000000298:  B0 1B             mov    al, 0x1b
0x000000000000029a:  5B                pop    bx
0x000000000000029b:  CB                ret   
0x000000000000029c:  B0 1C             mov    al, 0x1c
0x000000000000029e:  5B                pop    bx
0x000000000000029f:  CB                ret   
0x00000000000002a0:  B0 1D             mov    al, 0x1d
0x00000000000002a2:  5B                pop    bx
0x00000000000002a3:  CB                ret   
0x00000000000002a4:  B0 1A             mov    al, 0x1a
0x00000000000002a6:  5B                pop    bx
0x00000000000002a7:  CB                ret   
0x00000000000002a8:  B0 1E             mov    al, 0x1e
0x00000000000002aa:  5B                pop    bx
0x00000000000002ab:  CB                ret   
0x00000000000002ac:  B0 67             mov    al, 0x67
0x00000000000002ae:  5B                pop    bx
0x00000000000002af:  CB                ret   
0x00000000000002b0:  B0 61             mov    al, 0x61
0x00000000000002b2:  5B                pop    bx
0x00000000000002b3:  CB                ret   
0x00000000000002b4:  30 C0             xor    al, al
0x00000000000002b6:  5B                pop    bx
0x00000000000002b7:  CB                ret 

EDNP

PROC    getAttackSound_ NEAR 
PUBLIC  getAttackSound_


0x00000000000002b8:  3C 0C             cmp    al, 0xc
0x00000000000002ba:  73 05             jae    0x2c1
0x00000000000002bc:  3C 01             cmp    al, 1
0x00000000000002be:  75 16             jne    0x2d6
0x00000000000002c0:  CB                ret   
0x00000000000002c1:  3C 0D             cmp    al, 0xd
0x00000000000002c3:  76 0B             jbe    0x2d0
0x00000000000002c5:  3C 12             cmp    al, 0x12
0x00000000000002c7:  74 0A             je     0x2d3
0x00000000000002c9:  3C 11             cmp    al, 0x11
0x00000000000002cb:  75 09             jne    0x2d6
0x00000000000002cd:  B0 33             mov    al, 0x33
0x00000000000002cf:  CB                ret   
0x00000000000002d0:  B0 34             mov    al, 0x34
0x00000000000002d2:  CB                ret   
0x00000000000002d3:  B0 02             mov    al, 2
0x00000000000002d5:  CB                ret   
0x00000000000002d6:  30 C0             xor    al, al
0x00000000000002d8:  CB                ret   

ENDP

PROC    getDamage_ NEAR 
PUBLIC  getDamage_


0x00000000000002da:  3C 1F             cmp    al, 0x1f
0x00000000000002dc:  73 0F             jae    0x2ed
0x00000000000002de:  3C 10             cmp    al, 0x10
0x00000000000002e0:  73 25             jae    0x307
0x00000000000002e2:  3C 09             cmp    al, 9
0x00000000000002e4:  74 2E             je     0x314
0x00000000000002e6:  3C 06             cmp    al, 6
0x00000000000002e8:  75 EC             jne    0x2d6
0x00000000000002ea:  B0 0A             mov    al, 0xa
0x00000000000002ec:  CB                ret   
0x00000000000002ed:  76 22             jbe    0x311
0x00000000000002ef:  3C 22             cmp    al, 0x22
0x00000000000002f1:  73 07             jae    0x2fa
0x00000000000002f3:  3C 21             cmp    al, 0x21
0x00000000000002f5:  75 20             jne    0x317
0x00000000000002f7:  B0 14             mov    al, 0x14
0x00000000000002f9:  CB                ret   
0x00000000000002fa:  76 1B             jbe    0x317
0x00000000000002fc:  3C 24             cmp    al, 0x24
0x00000000000002fe:  74 17             je     0x317
0x0000000000000300:  3C 23             cmp    al, 0x23
0x0000000000000302:  75 D2             jne    0x2d6
0x0000000000000304:  B0 64             mov    al, 0x64
0x0000000000000306:  CB                ret   
0x0000000000000307:  76 0B             jbe    0x314
0x0000000000000309:  3C 1C             cmp    al, 0x1c
0x000000000000030b:  74 04             je     0x311
0x000000000000030d:  3C 12             cmp    al, 0x12
0x000000000000030f:  75 C5             jne    0x2d6
0x0000000000000311:  B0 03             mov    al, 3
0x0000000000000313:  CB                ret   
0x0000000000000314:  B0 08             mov    al, 8
0x0000000000000316:  CB                ret   
0x0000000000000317:  B0 05             mov    al, 5
0x0000000000000319:  CB                ret   

ENDP

dw 06003h
dw 06503h
dw 06A03h
dw 06F03h
dw 0BF03h
dw 07403h
dw 0BF03h
dw 0BF03h
dw 07903h
dw 0BF03h
dw 07E03h
dw 08303h
dw 08803h
dw 08803h
dw 08D03h
dw 09203h
dw 0BF03h
dw 09703h
dw 09C03h
dw 0A103h
dw 0A603h
dw 0AB03h
dw 0B003h
dw 0B503h
dw 0BF03h
dw 0BF03h
dw 0BA03h

PROC    getSeeState_ NEAR 
PUBLIC  getSeeState_

0x0000000000000350:  53                push   bx
0x0000000000000351:  3C 1A             cmp    al, 0x1a
0x0000000000000353:  77 64             ja     0x3b9
0x0000000000000355:  30 E4             xor    ah, ah
0x0000000000000357:  89 C3             mov    bx, ax
0x0000000000000359:  01 C3             add    bx, ax
0x000000000000035b:  2E FF A7 1A 03    jmp    word ptr cs:[bx + 0x31a]
0x0000000000000360:  B8 96 00          mov    ax, 0x96
0x0000000000000363:  5B                pop    bx
0x0000000000000364:  CB                ret   
0x0000000000000365:  B8 B0 00          mov    ax, 0xb0
0x0000000000000368:  5B                pop    bx
0x0000000000000369:  CB                ret   
0x000000000000036a:  B8 D1 00          mov    ax, 0xd1
0x000000000000036d:  5B                pop    bx
0x000000000000036e:  CB                ret   
0x000000000000036f:  B8 F3 00          mov    ax, 0xf3
0x0000000000000372:  5B                pop    bx
0x0000000000000373:  CB                ret   
0x0000000000000374:  B8 43 01          mov    ax, 0x143
0x0000000000000377:  5B                pop    bx
0x0000000000000378:  CB                ret   
0x0000000000000379:  B8 6C 01          mov    ax, 0x16c
0x000000000000037c:  5B                pop    bx
0x000000000000037d:  CB                ret   
0x000000000000037e:  B8 98 01          mov    ax, 0x198
0x0000000000000381:  5B                pop    bx
0x0000000000000382:  CB                ret   
0x0000000000000383:  B8 BC 01          mov    ax, 0x1bc
0x0000000000000386:  5B                pop    bx
0x0000000000000387:  CB                ret   
0x0000000000000388:  B8 DD 01          mov    ax, 0x1dd
0x000000000000038b:  5B                pop    bx
0x000000000000038c:  CB                ret   
0x000000000000038d:  B8 F7 01          mov    ax, 0x1f7
0x0000000000000390:  5B                pop    bx
0x0000000000000391:  CB                ret   
0x0000000000000392:  B8 11 02          mov    ax, 0x211
0x0000000000000395:  5B                pop    bx
0x0000000000000396:  CB                ret   
0x0000000000000397:  B8 2E 02          mov    ax, 0x22e
0x000000000000039a:  5B                pop    bx
0x000000000000039b:  CB                ret   
0x000000000000039c:  B8 4B 02          mov    ax, 0x24b
0x000000000000039f:  5B                pop    bx
0x00000000000003a0:  CB                ret   
0x00000000000003a1:  B8 5B 02          mov    ax, 0x25b
0x00000000000003a4:  5B                pop    bx
0x00000000000003a5:  CB                ret   
0x00000000000003a6:  B8 7A 02          mov    ax, 0x27a
0x00000000000003a9:  5B                pop    bx
0x00000000000003aa:  CB                ret   
0x00000000000003ab:  B8 A4 02          mov    ax, 0x2a4
0x00000000000003ae:  5B                pop    bx
0x00000000000003af:  CB                ret   
0x00000000000003b0:  B8 BE 02          mov    ax, 0x2be
0x00000000000003b3:  5B                pop    bx
0x00000000000003b4:  CB                ret   
0x00000000000003b5:  B8 D8 02          mov    ax, 0x2d8
0x00000000000003b8:  5B                pop    bx
0x00000000000003b9:  CB                ret   
0x00000000000003ba:  B8 11 03          mov    ax, 0x311
0x00000000000003bd:  5B                pop    bx
0x00000000000003be:  CB                ret   
0x00000000000003bf:  31 C0             xor    ax, ax
0x00000000000003c1:  5B                pop    bx
0x00000000000003c2:  CB                ret   

ENDP

dw 00404h
dw 00904h
dw 00E04h
dw 01304h
dw 05904h
dw 01804h
dw 05904h
dw 05904h
dw 01D04h
dw 05904h
dw 02204h
dw 02704h
dw 05904h
dw 05904h
dw 02C04h
dw 03104h
dw 05904h
dw 03604h
dw 03B04h
dw 04004h
dw 04504h
dw 04A04h
dw 04F04h
dw 05404h


PROC    getMissileState_ NEAR 
PUBLIC  getMissileState_


0x00000000000003f4:  53                push   bx
0x00000000000003f5:  3C 17             cmp    al, 0x17
0x00000000000003f7:  77 60             ja     0x459
0x00000000000003f9:  30 E4             xor    ah, ah
0x00000000000003fb:  89 C3             mov    bx, ax
0x00000000000003fd:  01 C3             add    bx, ax
0x00000000000003ff:  2E FF A7 C4 03    jmp    word ptr cs:[bx + 0x3c4]
0x0000000000000404:  B8 9A 00          mov    ax, 0x9a
0x0000000000000407:  5B                pop    bx
0x0000000000000408:  CB                ret   
0x0000000000000409:  B8 B8 00          mov    ax, 0xb8
0x000000000000040c:  5B                pop    bx
0x000000000000040d:  CB                ret   
0x000000000000040e:  B8 D9 00          mov    ax, 0xd9
0x0000000000000411:  5B                pop    bx
0x0000000000000412:  CB                ret   
0x0000000000000413:  B8 FF 00          mov    ax, 0xff
0x0000000000000416:  5B                pop    bx
0x0000000000000417:  CB                ret   
0x0000000000000418:  B8 53 01          mov    ax, 0x153
0x000000000000041b:  5B                pop    bx
0x000000000000041c:  CB                ret   
0x000000000000041d:  B8 78 01          mov    ax, 0x178
0x0000000000000420:  5B                pop    bx
0x0000000000000421:  CB                ret   
0x0000000000000422:  B8 A0 01          mov    ax, 0x1a0
0x0000000000000425:  5B                pop    bx
0x0000000000000426:  CB                ret   
0x0000000000000427:  B8 C4 01          mov    ax, 0x1c4
0x000000000000042a:  5B                pop    bx
0x000000000000042b:  CB                ret   
0x000000000000042c:  B8 F8 01          mov    ax, 0x1f8
0x000000000000042f:  5B                pop    bx
0x0000000000000430:  CB                ret   
0x0000000000000431:  B8 19 02          mov    ax, 0x219
0x0000000000000434:  5B                pop    bx
0x0000000000000435:  CB                ret   
0x0000000000000436:  B8 36 02          mov    ax, 0x236
0x0000000000000439:  5B                pop    bx
0x000000000000043a:  CB                ret   
0x000000000000043b:  B8 4D 02          mov    ax, 0x24d
0x000000000000043e:  5B                pop    bx
0x000000000000043f:  CB                ret   
0x0000000000000440:  B8 67 02          mov    ax, 0x267
0x0000000000000443:  5B                pop    bx
0x0000000000000444:  CB                ret   
0x0000000000000445:  B8 87 02          mov    ax, 0x287
0x0000000000000448:  5B                pop    bx
0x0000000000000449:  CB                ret   
0x000000000000044a:  B8 AC 02          mov    ax, 0x2ac
0x000000000000044d:  5B                pop    bx
0x000000000000044e:  CB                ret   
0x000000000000044f:  B8 C4 02          mov    ax, 0x2c4
0x0000000000000452:  5B                pop    bx
0x0000000000000453:  CB                ret   
0x0000000000000454:  B8 E0 02          mov    ax, 0x2e0
0x0000000000000457:  5B                pop    bx
0x0000000000000458:  CB                ret   
0x0000000000000459:  31 C0             xor    ax, ax
0x000000000000045b:  5B                pop    bx
0x000000000000045c:  CB                ret   

ENDP

dw 0B804h
dw 0BD04h
dw 0C204h
dw 0C704h
dw 01705h
dw 0CC04h
dw 0D104h
dw 01705h
dw 0D604h
dw 0DB04h
dw 0E004h
dw 0E504h
dw 0EA04h
dw 0EA04h
dw 0EF04h
dw 0F404h
dw 0F904h
dw 0FE04h
dw 00305h
dw 00805h
dw 00D05h
dw 01205h
dw 01B05h
dw 02005h
dw 02505h
dw 02A05h
dw 01705h
dw 01705h
dw 01705h
dw 01705h
dw 02F05h
dw 03405h
dw 03905h
dw 03E05h
dw 04305h
dw 04805h
dw 04D05h

PROC    getDeathState_ NEAR 
PUBLIC  getDeathState_



0x00000000000004a8:  53                push   bx
0x00000000000004a9:  3C 24             cmp    al, 0x24
0x00000000000004ab:  77 6A             ja     0x517
0x00000000000004ad:  30 E4             xor    ah, ah
0x00000000000004af:  89 C3             mov    bx, ax
0x00000000000004b1:  01 C3             add    bx, ax
0x00000000000004b3:  2E FF A7 5E 04    jmp    word ptr cs:[bx + 0x45e]
0x00000000000004b8:  B8 9E 00          mov    ax, 0x9e
0x00000000000004bb:  5B                pop    bx
0x00000000000004bc:  CB                ret   
0x00000000000004bd:  B8 BD 00          mov    ax, 0xbd
0x00000000000004c0:  5B                pop    bx
0x00000000000004c1:  CB                ret   
0x00000000000004c2:  B8 DE 00          mov    ax, 0xde
0x00000000000004c5:  5B                pop    bx
0x00000000000004c6:  CB                ret   
0x00000000000004c7:  B8 0F 01          mov    ax, 0x10f
0x00000000000004ca:  5B                pop    bx
0x00000000000004cb:  CB                ret   
0x00000000000004cc:  B8 59 01          mov    ax, 0x159
0x00000000000004cf:  5B                pop    bx
0x00000000000004d0:  CB                ret   
0x00000000000004d1:  B8 3E 01          mov    ax, 0x13e
0x00000000000004d4:  5B                pop    bx
0x00000000000004d5:  CB                ret   
0x00000000000004d6:  B8 84 01          mov    ax, 0x184
0x00000000000004d9:  5B                pop    bx
0x00000000000004da:  CB                ret   
0x00000000000004db:  B8 67 01          mov    ax, 0x167
0x00000000000004de:  5B                pop    bx
0x00000000000004df:  CB                ret   
0x00000000000004e0:  B8 A6 01          mov    ax, 0x1a6
0x00000000000004e3:  5B                pop    bx
0x00000000000004e4:  CB                ret   
0x00000000000004e5:  B8 C9 01          mov    ax, 0x1c9
0x00000000000004e8:  5B                pop    bx
0x00000000000004e9:  CB                ret   
0x00000000000004ea:  B8 EA 01          mov    ax, 0x1ea
0x00000000000004ed:  5B                pop    bx
0x00000000000004ee:  CB                ret   
0x00000000000004ef:  B8 FE 01          mov    ax, 0x1fe
0x00000000000004f2:  5B                pop    bx
0x00000000000004f3:  CB                ret   
0x00000000000004f4:  B8 1E 02          mov    ax, 0x21e
0x00000000000004f7:  5B                pop    bx
0x00000000000004f8:  CB                ret   
0x00000000000004f9:  B8 0C 02          mov    ax, 0x20c
0x00000000000004fc:  5B                pop    bx
0x00000000000004fd:  CB                ret   
0x00000000000004fe:  B8 3B 02          mov    ax, 0x23b
0x0000000000000501:  5B                pop    bx
0x0000000000000502:  CB                ret   
0x0000000000000503:  B8 53 02          mov    ax, 0x253
0x0000000000000506:  5B                pop    bx
0x0000000000000507:  CB                ret   
0x0000000000000508:  B8 6D 02          mov    ax, 0x26d
0x000000000000050b:  5B                pop    bx
0x000000000000050c:  CB                ret   
0x000000000000050d:  B8 8D 02          mov    ax, 0x28d
0x0000000000000510:  5B                pop    bx
0x0000000000000511:  CB                ret   
0x0000000000000512:  B8 B3 02          mov    ax, 0x2b3
0x0000000000000515:  5B                pop    bx
0x0000000000000516:  CB                ret   
0x0000000000000517:  31 C0             xor    ax, ax
0x0000000000000519:  5B                pop    bx
0x000000000000051a:  CB                ret   
0x000000000000051b:  B8 CA 02          mov    ax, 0x2ca
0x000000000000051e:  5B                pop    bx
0x000000000000051f:  CB                ret   
0x0000000000000520:  B8 E8 02          mov    ax, 0x2e8
0x0000000000000523:  5B                pop    bx
0x0000000000000524:  CB                ret   
0x0000000000000525:  B8 FC 02          mov    ax, 0x2fc
0x0000000000000528:  5B                pop    bx
0x0000000000000529:  CB                ret   
0x000000000000052a:  B8 0C 03          mov    ax, 0x30c
0x000000000000052d:  5B                pop    bx
0x000000000000052e:  CB                ret   
0x000000000000052f:  B8 28 03          mov    ax, 0x328
0x0000000000000532:  5B                pop    bx
0x0000000000000533:  CB                ret   
0x0000000000000534:  B8 63 00          mov    ax, 0x63
0x0000000000000537:  5B                pop    bx
0x0000000000000538:  CB                ret   
0x0000000000000539:  B8 68 00          mov    ax, 0x68
0x000000000000053c:  5B                pop    bx
0x000000000000053d:  CB                ret   
0x000000000000053e:  B8 7F 00          mov    ax, 0x7f
0x0000000000000541:  5B                pop    bx
0x0000000000000542:  CB                ret   
0x0000000000000543:  B8 6D 00          mov    ax, 0x6d
0x0000000000000546:  5B                pop    bx
0x0000000000000547:  CB                ret   
0x0000000000000548:  B8 75 00          mov    ax, 0x75
0x000000000000054b:  5B                pop    bx
0x000000000000054c:  CB                ret   
0x000000000000054d:  B8 9D 02          mov    ax, 0x29d
0x0000000000000550:  5B                pop    bx
0x0000000000000551:  CB                ret   

ENDP

dw 09605h
dw 09B05h
dw 0A005h
dw 0A505h
dw 0F505h
dw 0AA05h
dw 0F505h
dw 0F505h
dw 0AF05h
dw 0F505h
dw 0B405h
dw 0B905h
dw 0BE05h
dw 0BE05h
dw 0C305h
dw 0C805h
dw 0F505h
dw 0CD05h
dw 0D205h
dw 0D705h
dw 0DC05h
dw 0E105h
dw 0E605h
dw 0EB05h
dw 0F005h
dw 0F905h

PROC    getPainState_ NEAR 
PUBLIC  getPainState_


0x0000000000000586:  53                push   bx
0x0000000000000587:  3C 19             cmp    al, 0x19
0x0000000000000589:  77 6A             ja     0x5f5
0x000000000000058b:  30 E4             xor    ah, ah
0x000000000000058d:  89 C3             mov    bx, ax
0x000000000000058f:  01 C3             add    bx, ax
0x0000000000000591:  2E FF A7 52 05    jmp    word ptr cs:[bx + 0x552]
0x0000000000000596:  B8 9C 00          mov    ax, 0x9c
0x0000000000000599:  5B                pop    bx
0x000000000000059a:  CB                ret   
0x000000000000059b:  B8 BB 00          mov    ax, 0xbb
0x000000000000059e:  5B                pop    bx
0x000000000000059f:  CB                ret   
0x00000000000005a0:  B8 DC 00          mov    ax, 0xdc
0x00000000000005a3:  5B                pop    bx
0x00000000000005a4:  CB                ret   
0x00000000000005a5:  B8 0D 01          mov    ax, 0x10d
0x00000000000005a8:  5B                pop    bx
0x00000000000005a9:  CB                ret   
0x00000000000005aa:  B8 57 01          mov    ax, 0x157
0x00000000000005ad:  5B                pop    bx
0x00000000000005ae:  CB                ret   
0x00000000000005af:  B8 82 01          mov    ax, 0x182
0x00000000000005b2:  5B                pop    bx
0x00000000000005b3:  CB                ret   
0x00000000000005b4:  B8 A4 01          mov    ax, 0x1a4
0x00000000000005b7:  5B                pop    bx
0x00000000000005b8:  CB                ret   
0x00000000000005b9:  B8 C7 01          mov    ax, 0x1c7
0x00000000000005bc:  5B                pop    bx
0x00000000000005bd:  CB                ret   
0x00000000000005be:  B8 E8 01          mov    ax, 0x1e8
0x00000000000005c1:  5B                pop    bx
0x00000000000005c2:  CB                ret   
0x00000000000005c3:  B8 FB 01          mov    ax, 0x1fb
0x00000000000005c6:  5B                pop    bx
0x00000000000005c7:  CB                ret   
0x00000000000005c8:  B8 1C 02          mov    ax, 0x21c
0x00000000000005cb:  5B                pop    bx
0x00000000000005cc:  CB                ret   
0x00000000000005cd:  B8 39 02          mov    ax, 0x239
0x00000000000005d0:  5B                pop    bx
0x00000000000005d1:  CB                ret   
0x00000000000005d2:  B8 51 02          mov    ax, 0x251
0x00000000000005d5:  5B                pop    bx
0x00000000000005d6:  CB                ret   
0x00000000000005d7:  B8 6B 02          mov    ax, 0x26b
0x00000000000005da:  5B                pop    bx
0x00000000000005db:  CB                ret   
0x00000000000005dc:  B8 8B 02          mov    ax, 0x28b
0x00000000000005df:  5B                pop    bx
0x00000000000005e0:  CB                ret   
0x00000000000005e1:  B8 B2 02          mov    ax, 0x2b2
0x00000000000005e4:  5B                pop    bx
0x00000000000005e5:  CB                ret   
0x00000000000005e6:  B8 C8 02          mov    ax, 0x2c8
0x00000000000005e9:  5B                pop    bx
0x00000000000005ea:  CB                ret   
0x00000000000005eb:  B8 E6 02          mov    ax, 0x2e6
0x00000000000005ee:  5B                pop    bx
0x00000000000005ef:  CB                ret   
0x00000000000005f0:  B8 08 03          mov    ax, 0x308
0x00000000000005f3:  5B                pop    bx
0x00000000000005f4:  CB                ret   
0x00000000000005f5:  31 C0             xor    ax, ax
0x00000000000005f7:  5B                pop    bx
0x00000000000005f8:  CB                ret   
0x00000000000005f9:  B8 0B 03          mov    ax, 0x30b
0x00000000000005fc:  5B                pop    bx
0x00000000000005fd:  CB                ret  

ENDP

dw 04C06h
dw 05106h
dw 05606h
dw 05B06h
dw 06006h
dw 06506h
dw 06006h
dw 06006h
dw 06A06h
dw 06006h
dw 06F06h
dw 07406h
dw 07906h
dw 07906h
dw 07E06h
dw 06006h
dw 06006h
dw 08306h
dw 04C06h
dw 08806h
dw 08306h
dw 08D06h
dw 07E06h
dw 09206h
dw 04C06h
dw 09706h
dw 06006h
dw 06006h
dw 06006h
dw 06006h
dw 05106h


PROC    getSpawnHealth_ NEAR 
PUBLIC  getSpawnHealth_


0x000000000000063c:  53                push   bx
0x000000000000063d:  3C 1E             cmp    al, 0x1e
0x000000000000063f:  77 1F             ja     0x660
0x0000000000000641:  30 E4             xor    ah, ah
0x0000000000000643:  89 C3             mov    bx, ax
0x0000000000000645:  01 C3             add    bx, ax
0x0000000000000647:  2E FF A7 FE 05    jmp    word ptr cs:[bx + 0x5fe]
0x000000000000064c:  B8 64 00          mov    ax, 0x64
0x000000000000064f:  5B                pop    bx
0x0000000000000650:  CB                ret   
0x0000000000000651:  B8 14 00          mov    ax, 0x14
0x0000000000000654:  5B                pop    bx
0x0000000000000655:  CB                ret   
0x0000000000000656:  B8 1E 00          mov    ax, 0x1e
0x0000000000000659:  5B                pop    bx
0x000000000000065a:  CB                ret   
0x000000000000065b:  B8 BC 02          mov    ax, 0x2bc
0x000000000000065e:  5B                pop    bx
0x000000000000065f:  CB                ret   
0x0000000000000660:  B8 E8 03          mov    ax, 0x3e8
0x0000000000000663:  5B                pop    bx
0x0000000000000664:  CB                ret   
0x0000000000000665:  B8 2C 01          mov    ax, 0x12c
0x0000000000000668:  5B                pop    bx
0x0000000000000669:  CB                ret   
0x000000000000066a:  B8 58 02          mov    ax, 0x258
0x000000000000066d:  5B                pop    bx
0x000000000000066e:  CB                ret   
0x000000000000066f:  B8 46 00          mov    ax, 0x46
0x0000000000000672:  5B                pop    bx
0x0000000000000673:  CB                ret   
0x0000000000000674:  B8 3C 00          mov    ax, 0x3c
0x0000000000000677:  5B                pop    bx
0x0000000000000678:  CB                ret   
0x0000000000000679:  B8 96 00          mov    ax, 0x96
0x000000000000067c:  5B                pop    bx
0x000000000000067d:  CB                ret   
0x000000000000067e:  B8 90 01          mov    ax, 0x190
0x0000000000000681:  5B                pop    bx
0x0000000000000682:  CB                ret   
0x0000000000000683:  B8 F4 01          mov    ax, 0x1f4
0x0000000000000686:  5B                pop    bx
0x0000000000000687:  CB                ret   
0x0000000000000688:  B8 B8 0B          mov    ax, 0xbb8
0x000000000000068b:  5B                pop    bx
0x000000000000068c:  CB                ret   
0x000000000000068d:  B8 A0 0F          mov    ax, 0xfa0
0x0000000000000690:  5B                pop    bx
0x0000000000000691:  CB                ret   
0x0000000000000692:  B8 32 00          mov    ax, 0x32
0x0000000000000695:  5B                pop    bx
0x0000000000000696:  CB                ret   
0x0000000000000697:  B8 FA 00          mov    ax, 0xfa
0x000000000000069a:  5B                pop    bx
0x000000000000069b:  CB                ret  

ENDP

PROC    P_INFO_ENDMARKER_ 
PUBLIC  P_INFO_ENDMARKER_
ENDP

END