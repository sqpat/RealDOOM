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


EXTRN S_StartSoundWithParams_:PROC
EXTRN P_RemoveThinker_:PROC
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR
EXTRN T_MovePlaneFloorUp_:NEAR
EXTRN T_MovePlaneFloorDown_:NEAR
EXTRN P_Random_:NEAR
EXTRN P_UpdateThinkerFunc_:NEAR


.DATA


.CODE



PROC    P_LIGHTS_STARTMARKER_ NEAR
PUBLIC  P_LIGHTS_STARTMARKER_
ENDP


PROC    T_FireFlicker_ NEAR
PUBLIC  T_FireFlicker_ 



0x0000000000003250:  53                push  bx
0x0000000000003251:  51                push  cx
0x0000000000003252:  55                push  bp
0x0000000000003253:  89 E5             mov   bp, sp
0x0000000000003255:  83 EC 02          sub   sp, 2
0x0000000000003258:  89 C3             mov   bx, ax
0x000000000000325a:  8B 17             mov   dx, word ptr [bx]
0x000000000000325c:  8A 47 04          mov   al, byte ptr [bx + 4]
0x000000000000325f:  8A 4F 05          mov   cl, byte ptr [bx + 5]
0x0000000000003262:  88 46 FE          mov   byte ptr [bp - 2], al
0x0000000000003265:  FF 4F 02          dec   word ptr [bx + 2]
0x0000000000003268:  74 04             je    0x326e
0x000000000000326a:  C9                LEAVE_MACRO 
0x000000000000326b:  59                pop   cx
0x000000000000326c:  5B                pop   bx
0x000000000000326d:  C3                ret   
0x000000000000326e:  E8 78 17          call  0x49e9
0x0000000000003271:  88 C5             mov   ch, al
0x0000000000003273:  C7 47 02 04 00    mov   word ptr [bx + 2], 4
0x0000000000003278:  B8 90 21          mov   ax, 0x2190
0x000000000000327b:  89 D3             mov   bx, dx
0x000000000000327d:  80 E5 03          and   ch, 3
0x0000000000003280:  C1 E3 04          shl   bx, 4
0x0000000000003283:  8E C0             mov   es, ax
0x0000000000003285:  C0 E5 04          shl   ch, 4
0x0000000000003288:  26 8A 57 0E       mov   dl, byte ptr es:[bx + 0xe]
0x000000000000328c:  88 E8             mov   al, ch
0x000000000000328e:  30 F6             xor   dh, dh
0x0000000000003290:  30 E4             xor   ah, ah
0x0000000000003292:  29 C2             sub   dx, ax
0x0000000000003294:  88 C8             mov   al, cl
0x0000000000003296:  83 C3 0E          add   bx, 0xe
0x0000000000003299:  39 C2             cmp   dx, ax
0x000000000000329b:  7D 07             jge   0x32a4
0x000000000000329d:  26 88 0F          mov   byte ptr es:[bx], cl
0x00000000000032a0:  C9                LEAVE_MACRO 
0x00000000000032a1:  59                pop   cx
0x00000000000032a2:  5B                pop   bx
0x00000000000032a3:  C3                ret   
ENDP


PROC    P_SpawnFireFlicker_ NEAR
PUBLIC  P_SpawnFireFlicker_


0x00000000000032b0:  53                push  bx
0x00000000000032b1:  51                push  cx
0x00000000000032b2:  52                push  dx
0x00000000000032b3:  55                push  bp
0x00000000000032b4:  89 E5             mov   bp, sp
0x00000000000032b6:  83 EC 04          sub   sp, 4
0x00000000000032b9:  89 C1             mov   cx, ax
0x00000000000032bb:  89 C2             mov   dx, ax
0x00000000000032bd:  BB 90 21          mov   bx, 0x2190
0x00000000000032c0:  C1 E2 04          shl   dx, 4
0x00000000000032c3:  8E C3             mov   es, bx
0x00000000000032c5:  89 D3             mov   bx, dx
0x00000000000032c7:  C7 46 FE 00 00    mov   word ptr [bp - 2], 0
0x00000000000032cc:  83 C3 0E          add   bx, 0xe
0x00000000000032cf:  89 56 FC          mov   word ptr [bp - 4], dx
0x00000000000032d2:  26 8A 17          mov   dl, byte ptr es:[bx]
0x00000000000032d5:  8B 5E FC          mov   bx, word ptr [bp - 4]
0x00000000000032d8:  81 C3 3E DE       add   bx, 0xde3e
0x00000000000032dc:  B8 00 30          mov   ax, 0x3000
0x00000000000032df:  C6 07 00          mov   byte ptr [bx], 0
0x00000000000032e2:  0E                push  cs
0x00000000000032e3:  E8 34 15          call  0x481a
0x00000000000032e6:  90                nop   
0x00000000000032e7:  89 C3             mov   bx, ax
0x00000000000032e9:  89 C8             mov   ax, cx
0x00000000000032eb:  88 57 04          mov   byte ptr [bx + 4], dl
0x00000000000032ee:  30 F6             xor   dh, dh
0x00000000000032f0:  89 0F             mov   word ptr [bx], cx
0x00000000000032f2:  E8 BD 07          call  0x3ab2
0x00000000000032f5:  04 10             add   al, 0x10
0x00000000000032f7:  C7 47 02 04 00    mov   word ptr [bx + 2], 4
0x00000000000032fc:  88 47 05          mov   byte ptr [bx + 5], al
0x00000000000032ff:  C9                LEAVE_MACRO 
0x0000000000003300:  5A                pop   dx
0x0000000000003301:  59                pop   cx
0x0000000000003302:  5B                pop   bx
0x0000000000003303:  C3                ret   


ENDP

PROC    T_LightFlash_ NEAR
PUBLIC  T_LightFlash_

0x0000000000003304:  53                push  bx
0x0000000000003305:  56                push  si
0x0000000000003306:  89 C3             mov   bx, ax
0x0000000000003308:  8A 67 05          mov   ah, byte ptr [bx + 5]
0x000000000000330b:  8B 37             mov   si, word ptr [bx]
0x000000000000330d:  8A 47 04          mov   al, byte ptr [bx + 4]
0x0000000000003310:  FF 4F 02          dec   word ptr [bx + 2]
0x0000000000003313:  75 24             jne   0x3339
0x0000000000003315:  BA 90 21          mov   dx, 0x2190
0x0000000000003318:  C1 E6 04          shl   si, 4
0x000000000000331b:  8E C2             mov   es, dx
0x000000000000331d:  83 C6 0E          add   si, 0xe
0x0000000000003320:  26 3A 04          cmp   al, byte ptr es:[si]
0x0000000000003323:  75 17             jne   0x333c
0x0000000000003325:  26 88 24          mov   byte ptr es:[si], ah
0x0000000000003328:  8A 47 07          mov   al, byte ptr [bx + 7]
0x000000000000332b:  98                cwde  
0x000000000000332c:  89 C6             mov   si, ax
0x000000000000332e:  E8 B8 16          call  0x49e9
0x0000000000003331:  30 E4             xor   ah, ah
0x0000000000003333:  21 F0             and   ax, si
0x0000000000003335:  40                inc   ax
0x0000000000003336:  89 47 02          mov   word ptr [bx + 2], ax
0x0000000000003339:  5E                pop   si
0x000000000000333a:  5B                pop   bx
0x000000000000333b:  C3                ret   
0x000000000000333c:  26 88 04          mov   byte ptr es:[si], al
0x000000000000333f:  8A 47 06          mov   al, byte ptr [bx + 6]
0x0000000000003342:  EB E7             jmp   0x332b

ENDP


PROC    P_SpawnLightFlash_ NEAR
PUBLIC  P_SpawnLightFlash_

0x0000000000003344:  53                push  bx
0x0000000000003345:  51                push  cx
0x0000000000003346:  52                push  dx
0x0000000000003347:  55                push  bp
0x0000000000003348:  89 E5             mov   bp, sp
0x000000000000334a:  83 EC 06          sub   sp, 6
0x000000000000334d:  89 C1             mov   cx, ax
0x000000000000334f:  C7 46 FC 00 00    mov   word ptr [bp - 4], 0
0x0000000000003354:  89 C2             mov   dx, ax
0x0000000000003356:  BB 90 21          mov   bx, 0x2190
0x0000000000003359:  C1 E2 04          shl   dx, 4
0x000000000000335c:  8E C3             mov   es, bx
0x000000000000335e:  89 D3             mov   bx, dx
0x0000000000003360:  89 56 FA          mov   word ptr [bp - 6], dx
0x0000000000003363:  26 8A 57 0E       mov   dl, byte ptr es:[bx + 0xe]
0x0000000000003367:  83 C3 0E          add   bx, 0xe
0x000000000000336a:  30 F6             xor   dh, dh
0x000000000000336c:  8B 5E FA          mov   bx, word ptr [bp - 6]
0x000000000000336f:  89 56 FE          mov   word ptr [bp - 2], dx
0x0000000000003372:  88 B7 3E DE       mov   byte ptr [bx - 0x21c2], dh
0x0000000000003376:  8A 56 FE          mov   dl, byte ptr [bp - 2]
0x0000000000003379:  E8 36 07          call  0x3ab2
0x000000000000337c:  88 C2             mov   dl, al
0x000000000000337e:  B8 00 38          mov   ax, 0x3800
0x0000000000003381:  81 C3 3E DE       add   bx, 0xde3e
0x0000000000003385:  0E                push  cs
0x0000000000003386:  3E E8 90 14       call  0x481a
0x000000000000338a:  89 C3             mov   bx, ax
0x000000000000338c:  C7 47 06 40 07    mov   word ptr [bx + 6], 0x740
0x0000000000003391:  89 0F             mov   word ptr [bx], cx
0x0000000000003393:  8A 76 FE          mov   dh, byte ptr [bp - 2]
0x0000000000003396:  8A 47 06          mov   al, byte ptr [bx + 6]
0x0000000000003399:  88 77 04          mov   byte ptr [bx + 4], dh
0x000000000000339c:  98                cwde  
0x000000000000339d:  88 57 05          mov   byte ptr [bx + 5], dl
0x00000000000033a0:  89 C1             mov   cx, ax
0x00000000000033a2:  E8 44 16          call  0x49e9
0x00000000000033a5:  88 C2             mov   dl, al
0x00000000000033a7:  30 F6             xor   dh, dh
0x00000000000033a9:  20 CA             and   dl, cl
0x00000000000033ab:  42                inc   dx
0x00000000000033ac:  89 57 02          mov   word ptr [bx + 2], dx
0x00000000000033af:  C9                LEAVE_MACRO 
0x00000000000033b0:  5A                pop   dx
0x00000000000033b1:  59                pop   cx
0x00000000000033b2:  5B                pop   bx
0x00000000000033b3:  C3                ret   

ENDP


PROC    T_StrobeFlash_ NEAR
PUBLIC  T_StrobeFlash_


0x00000000000033b4:  53                push  bx
0x00000000000033b5:  56                push  si
0x00000000000033b6:  89 C3             mov   bx, ax
0x00000000000033b8:  FF 4F 02          dec   word ptr [bx + 2]
0x00000000000033bb:  75 22             jne   0x33df
0x00000000000033bd:  8B 37             mov   si, word ptr [bx]
0x00000000000033bf:  B8 90 21          mov   ax, 0x2190
0x00000000000033c2:  C1 E6 04          shl   si, 4
0x00000000000033c5:  8E C0             mov   es, ax
0x00000000000033c7:  26 8A 44 0E       mov   al, byte ptr es:[si + 0xe]
0x00000000000033cb:  83 C6 0E          add   si, 0xe
0x00000000000033ce:  3A 47 04          cmp   al, byte ptr [bx + 4]
0x00000000000033d1:  75 0F             jne   0x33e2
0x00000000000033d3:  8A 47 05          mov   al, byte ptr [bx + 5]
0x00000000000033d6:  26 88 04          mov   byte ptr es:[si], al
0x00000000000033d9:  8B 77 08          mov   si, word ptr [bx + 8]
0x00000000000033dc:  89 77 02          mov   word ptr [bx + 2], si
0x00000000000033df:  5E                pop   si
0x00000000000033e0:  5B                pop   bx
0x00000000000033e1:  C3                ret   
0x00000000000033e2:  8A 47 04          mov   al, byte ptr [bx + 4]
0x00000000000033e5:  26 88 04          mov   byte ptr es:[si], al
0x00000000000033e8:  8B 77 06          mov   si, word ptr [bx + 6]
0x00000000000033eb:  89 77 02          mov   word ptr [bx + 2], si
0x00000000000033ee:  5E                pop   si
0x00000000000033ef:  5B                pop   bx
0x00000000000033f0:  C3                ret   

ENDP


PROC    P_SpawnStrobeFlash_ NEAR
PUBLIC  P_SpawnStrobeFlash_

0x00000000000033f2:  51                push  cx
0x00000000000033f3:  56                push  si
0x00000000000033f4:  57                push  di
0x00000000000033f5:  55                push  bp
0x00000000000033f6:  89 E5             mov   bp, sp
0x00000000000033f8:  83 EC 06          sub   sp, 6
0x00000000000033fb:  89 C1             mov   cx, ax
0x00000000000033fd:  89 56 FE          mov   word ptr [bp - 2], dx
0x0000000000003400:  89 DF             mov   di, bx
0x0000000000003402:  89 C2             mov   dx, ax
0x0000000000003404:  BB 90 21          mov   bx, 0x2190
0x0000000000003407:  C1 E2 04          shl   dx, 4
0x000000000000340a:  8E C3             mov   es, bx
0x000000000000340c:  89 D3             mov   bx, dx
0x000000000000340e:  C7 46 FC 00 00    mov   word ptr [bp - 4], 0
0x0000000000003413:  83 C3 0E          add   bx, 0xe
0x0000000000003416:  89 56 FA          mov   word ptr [bp - 6], dx
0x0000000000003419:  26 8A 17          mov   dl, byte ptr es:[bx]
0x000000000000341c:  8B 5E FA          mov   bx, word ptr [bp - 6]
0x000000000000341f:  81 C3 3E DE       add   bx, 0xde3e
0x0000000000003423:  B8 00 40          mov   ax, 0x4000
0x0000000000003426:  C6 07 00          mov   byte ptr [bx], 0
0x0000000000003429:  0E                push  cs
0x000000000000342a:  3E E8 EC 13       call  0x481a
0x000000000000342e:  89 C3             mov   bx, ax
0x0000000000003430:  89 C6             mov   si, ax
0x0000000000003432:  C7 47 08 05 00    mov   word ptr [bx + 8], 5
0x0000000000003437:  8B 46 FE          mov   ax, word ptr [bp - 2]
0x000000000000343a:  88 57 05          mov   byte ptr [bx + 5], dl
0x000000000000343d:  30 F6             xor   dh, dh
0x000000000000343f:  89 47 06          mov   word ptr [bx + 6], ax
0x0000000000003442:  89 C8             mov   ax, cx
0x0000000000003444:  89 0F             mov   word ptr [bx], cx
0x0000000000003446:  E8 69 06          call  0x3ab2
0x0000000000003449:  88 47 04          mov   byte ptr [bx + 4], al
0x000000000000344c:  3A 47 05          cmp   al, byte ptr [bx + 5]
0x000000000000344f:  74 0E             je    0x345f
0x0000000000003451:  85 FF             test  di, di
0x0000000000003453:  74 10             je    0x3465
0x0000000000003455:  C7 44 02 01 00    mov   word ptr [si + 2], 1
0x000000000000345a:  C9                LEAVE_MACRO 
0x000000000000345b:  5F                pop   di
0x000000000000345c:  5E                pop   si
0x000000000000345d:  59                pop   cx
0x000000000000345e:  C3                ret   
0x000000000000345f:  C6 47 04 00       mov   byte ptr [bx + 4], 0
0x0000000000003463:  EB EC             jmp   0x3451
0x0000000000003465:  E8 81 15          call  0x49e9
0x0000000000003468:  88 C2             mov   dl, al
0x000000000000346a:  80 E2 07          and   dl, 7
0x000000000000346d:  30 F6             xor   dh, dh
0x000000000000346f:  42                inc   dx
0x0000000000003470:  89 54 02          mov   word ptr [si + 2], dx
0x0000000000003473:  C9                LEAVE_MACRO 
0x0000000000003474:  5F                pop   di
0x0000000000003475:  5E                pop   si
0x0000000000003476:  59                pop   cx
0x0000000000003477:  C3                ret   

ENDP


PROC    EV_StartLightStrobing_ NEAR
PUBLIC  EV_StartLightStrobing_

0x0000000000003478:  53                push  bx
0x0000000000003479:  52                push  dx
0x000000000000347a:  56                push  si
0x000000000000347b:  55                push  bp
0x000000000000347c:  89 E5             mov   bp, sp
0x000000000000347e:  81 EC 00 02       sub   sp, 0x200
0x0000000000003482:  8D 96 00 FE       lea   dx, [bp - 0x200]
0x0000000000003486:  98                cwde  
0x0000000000003487:  31 DB             xor   bx, bx
0x0000000000003489:  E8 EF 05          call  0x3a7b
0x000000000000348c:  31 F6             xor   si, si
0x000000000000348e:  83 BE 00 FE 00    cmp   word ptr [bp - 0x200], 0
0x0000000000003493:  7C 16             jl    0x34ab
0x0000000000003495:  BA 23 00          mov   dx, 0x23
0x0000000000003498:  8B 82 00 FE       mov   ax, word ptr [bp + si - 0x200]
0x000000000000349c:  31 DB             xor   bx, bx
0x000000000000349e:  83 C6 02          add   si, 2
0x00000000000034a1:  E8 4E FF          call  0x33f2
0x00000000000034a4:  83 BA 00 FE 00    cmp   word ptr [bp + si - 0x200], 0
0x00000000000034a9:  7D EA             jge   0x3495
0x00000000000034ab:  C9                LEAVE_MACRO 
0x00000000000034ac:  5E                pop   si
0x00000000000034ad:  5A                pop   dx
0x00000000000034ae:  5B                pop   bx
0x00000000000034af:  C3                ret   

ENDP


PROC    EV_LightChange_ NEAR
PUBLIC  EV_LightChange_

0x00000000000034b0:  51                push  cx
0x00000000000034b1:  56                push  si
0x00000000000034b2:  57                push  di
0x00000000000034b3:  55                push  bp
0x00000000000034b4:  89 E5             mov   bp, sp
0x00000000000034b6:  81 EC 06 04       sub   sp, 0x406
0x00000000000034ba:  88 D5             mov   ch, dl
0x00000000000034bc:  88 D9             mov   cl, bl
0x00000000000034be:  BB 01 00          mov   bx, 1
0x00000000000034c1:  8D 96 FA FB       lea   dx, [bp - 0x406]
0x00000000000034c5:  98                cwde  
0x00000000000034c6:  C7 46 FC 00 00    mov   word ptr [bp - 4], 0
0x00000000000034cb:  E8 AD 05          call  0x3a7b
0x00000000000034ce:  83 BE FA FB 00    cmp   word ptr [bp - 0x406], 0
0x00000000000034d3:  7D 03             jge   0x34d8
0x00000000000034d5:  E9 7D 00          jmp   0x3555
0x00000000000034d8:  8B 76 FC          mov   si, word ptr [bp - 4]
0x00000000000034db:  8B 82 FA FB       mov   ax, word ptr [bp + si - 0x406]
0x00000000000034df:  89 46 FA          mov   word ptr [bp - 6], ax
0x00000000000034e2:  C1 E0 04          shl   ax, 4
0x00000000000034e5:  BA 90 21          mov   dx, 0x2190
0x00000000000034e8:  89 C3             mov   bx, ax
0x00000000000034ea:  8E C2             mov   es, dx
0x00000000000034ec:  83 C3 0A          add   bx, 0xa
0x00000000000034ef:  83 46 FC 02       add   word ptr [bp - 4], 2
0x00000000000034f3:  26 8B 17          mov   dx, word ptr es:[bx]
0x00000000000034f6:  89 C3             mov   bx, ax
0x00000000000034f8:  89 56 FE          mov   word ptr [bp - 2], dx
0x00000000000034fb:  26 8A 57 0E       mov   dl, byte ptr es:[bx + 0xe]
0x00000000000034ff:  83 C3 0E          add   bx, 0xe
0x0000000000003502:  84 ED             test  ch, ch
0x0000000000003504:  75 54             jne   0x355a
0x0000000000003506:  31 C0             xor   ax, ax
0x0000000000003508:  83 7E FE 00       cmp   word ptr [bp - 2], 0
0x000000000000350c:  7E 26             jle   0x3534
0x000000000000350e:  31 F6             xor   si, si
0x0000000000003510:  8B 9A FA FD       mov   bx, word ptr [bp + si - 0x206]
0x0000000000003514:  C1 E3 04          shl   bx, 4
0x0000000000003517:  84 ED             test  ch, ch
0x0000000000003519:  74 45             je    0x3560
0x000000000000351b:  BF 90 21          mov   di, 0x2190
0x000000000000351e:  83 C3 0E          add   bx, 0xe
0x0000000000003521:  8E C7             mov   es, di
0x0000000000003523:  26 3A 0F          cmp   cl, byte ptr es:[bx]
0x0000000000003526:  73 03             jae   0x352b
0x0000000000003528:  26 8A 0F          mov   cl, byte ptr es:[bx]
0x000000000000352b:  40                inc   ax
0x000000000000352c:  83 C6 02          add   si, 2
0x000000000000352f:  3B 46 FE          cmp   ax, word ptr [bp - 2]
0x0000000000003532:  7C DC             jl    0x3510
0x0000000000003534:  8B 46 FA          mov   ax, word ptr [bp - 6]
0x0000000000003537:  C1 E0 04          shl   ax, 4
0x000000000000353a:  84 ED             test  ch, ch
0x000000000000353c:  74 34             je    0x3572
0x000000000000353e:  BA 90 21          mov   dx, 0x2190
0x0000000000003541:  89 C3             mov   bx, ax
0x0000000000003543:  8E C2             mov   es, dx
0x0000000000003545:  83 C3 0E          add   bx, 0xe
0x0000000000003548:  26 88 0F          mov   byte ptr es:[bx], cl
0x000000000000354b:  8B 76 FC          mov   si, word ptr [bp - 4]
0x000000000000354e:  83 BA FA FB 00    cmp   word ptr [bp + si - 0x406], 0
0x0000000000003553:  7D 83             jge   0x34d8
0x0000000000003555:  C9                LEAVE_MACRO 
0x0000000000003556:  5F                pop   di
0x0000000000003557:  5E                pop   si
0x0000000000003558:  59                pop   cx
0x0000000000003559:  C3                ret   
0x000000000000355a:  84 C9             test  cl, cl
0x000000000000355c:  74 A8             je    0x3506
0x000000000000355e:  EB D4             jmp   0x3534
0x0000000000003560:  BF 90 21          mov   di, 0x2190
0x0000000000003563:  83 C3 0E          add   bx, 0xe
0x0000000000003566:  8E C7             mov   es, di
0x0000000000003568:  26 3A 17          cmp   dl, byte ptr es:[bx]
0x000000000000356b:  76 BE             jbe   0x352b
0x000000000000356d:  26 8A 17          mov   dl, byte ptr es:[bx]
0x0000000000003570:  EB B9             jmp   0x352b
0x0000000000003572:  BB 90 21          mov   bx, 0x2190
0x0000000000003575:  8E C3             mov   es, bx
0x0000000000003577:  89 C3             mov   bx, ax
0x0000000000003579:  26 88 57 0E       mov   byte ptr es:[bx + 0xe], dl
0x000000000000357d:  83 C3 0E          add   bx, 0xe
0x0000000000003580:  EB C9             jmp   0x354b

ENDP


PROC    T_Glow_ NEAR
PUBLIC  T_Glow_

0x0000000000003582:  53                push  bx
0x0000000000003583:  56                push  si
0x0000000000003584:  89 C3             mov   bx, ax
0x0000000000003586:  8B 07             mov   ax, word ptr [bx]
0x0000000000003588:  8A 57 02          mov   dl, byte ptr [bx + 2]
0x000000000000358b:  8B 77 04          mov   si, word ptr [bx + 4]
0x000000000000358e:  C1 E0 04          shl   ax, 4
0x0000000000003591:  8A 77 03          mov   dh, byte ptr [bx + 3]
0x0000000000003594:  83 FE FF          cmp   si, -1
0x0000000000003597:  74 1B             je    0x35b4
0x0000000000003599:  83 FE 01          cmp   si, 1
0x000000000000359c:  75 13             jne   0x35b1
0x000000000000359e:  BE 90 21          mov   si, 0x2190
0x00000000000035a1:  8E C6             mov   es, si
0x00000000000035a3:  89 C6             mov   si, ax
0x00000000000035a5:  83 C6 0E          add   si, 0xe
0x00000000000035a8:  26 80 04 08       add   byte ptr es:[si], 8
0x00000000000035ac:  26 3A 34          cmp   dh, byte ptr es:[si]
0x00000000000035af:  76 22             jbe   0x35d3
0x00000000000035b1:  5E                pop   si
0x00000000000035b2:  5B                pop   bx
0x00000000000035b3:  C3                ret   
0x00000000000035b4:  BE 90 21          mov   si, 0x2190
0x00000000000035b7:  8E C6             mov   es, si
0x00000000000035b9:  89 C6             mov   si, ax
0x00000000000035bb:  83 C6 0E          add   si, 0xe
0x00000000000035be:  26 80 2C 08       sub   byte ptr es:[si], 8
0x00000000000035c2:  26 3A 14          cmp   dl, byte ptr es:[si]
0x00000000000035c5:  72 EA             jb    0x35b1
0x00000000000035c7:  26 80 04 08       add   byte ptr es:[si], 8
0x00000000000035cb:  C7 47 04 01 00    mov   word ptr [bx + 4], 1
0x00000000000035d0:  5E                pop   si
0x00000000000035d1:  5B                pop   bx
0x00000000000035d2:  C3                ret   
0x00000000000035d3:  26 80 2C 08       sub   byte ptr es:[si], 8
0x00000000000035d7:  C7 47 04 FF FF    mov   word ptr [bx + 4], 0xffff
0x00000000000035dc:  5E                pop   si
0x00000000000035dd:  5B                pop   bx
0x00000000000035de:  C3                ret   


ENDP


PROC    P_SpawnGlowingLight_ NEAR
PUBLIC  P_SpawnGlowingLight_

0x00000000000035e0:  53                push  bx
0x00000000000035e1:  51                push  cx
0x00000000000035e2:  52                push  dx
0x00000000000035e3:  55                push  bp
0x00000000000035e4:  89 E5             mov   bp, sp
0x00000000000035e6:  83 EC 06          sub   sp, 6
0x00000000000035e9:  89 C1             mov   cx, ax
0x00000000000035eb:  C7 46 FC 00 00    mov   word ptr [bp - 4], 0
0x00000000000035f0:  BB 90 21          mov   bx, 0x2190
0x00000000000035f3:  89 C2             mov   dx, ax
0x00000000000035f5:  B8 00 48          mov   ax, 0x4800
0x00000000000035f8:  C1 E2 04          shl   dx, 4
0x00000000000035fb:  8E C3             mov   es, bx
0x00000000000035fd:  89 D3             mov   bx, dx
0x00000000000035ff:  89 56 FA          mov   word ptr [bp - 6], dx
0x0000000000003602:  26 8A 57 0E       mov   dl, byte ptr es:[bx + 0xe]
0x0000000000003606:  83 C3 0E          add   bx, 0xe
0x0000000000003609:  30 F6             xor   dh, dh
0x000000000000360b:  8B 5E FA          mov   bx, word ptr [bp - 6]
0x000000000000360e:  89 56 FE          mov   word ptr [bp - 2], dx
0x0000000000003611:  88 B7 3E DE       mov   byte ptr [bx - 0x21c2], dh
0x0000000000003615:  81 C3 3E DE       add   bx, 0xde3e
0x0000000000003619:  0E                push  cs
0x000000000000361a:  3E E8 FC 11       call  0x481a
0x000000000000361e:  8A 56 FE          mov   dl, byte ptr [bp - 2]
0x0000000000003621:  89 C3             mov   bx, ax
0x0000000000003623:  89 C8             mov   ax, cx
0x0000000000003625:  89 0F             mov   word ptr [bx], cx
0x0000000000003627:  E8 88 04          call  0x3ab2
0x000000000000362a:  C7 47 04 FF FF    mov   word ptr [bx + 4], 0xffff
0x000000000000362f:  88 47 02          mov   byte ptr [bx + 2], al
0x0000000000003632:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000003635:  88 47 03          mov   byte ptr [bx + 3], al
0x0000000000003638:  C9                LEAVE_MACRO 
0x0000000000003639:  5A                pop   dx
0x000000000000363a:  59                pop   cx
0x000000000000363b:  5B                pop   bx
0x000000000000363c:  C3                ret   

ENDP


PROC    P_LIGHTS_ENDMARKER_ NEAR
PUBLIC  P_LIGHTS_ENDMARKER_
ENDP

END
