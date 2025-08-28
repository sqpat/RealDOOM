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


EXTRN Z_QuickMapPhysics_:FAR
EXTRN M_Random_:NEAR

.DATA











.CODE



PROC    AM_MAP_STARTMARKER_ NEAR
PUBLIC  AM_MAP_STARTMARKER_
ENDP





PROC    MTOF16_ NEAR
PUBLIC  MTOF16_


0x0000000000003684:  53                   push      bx
0x0000000000003685:  51                   push      cx
0x0000000000003672:  52                   push      dx
0x0000000000003673:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x0000000000003677:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x000000000000367b:  0E                   push      cs
0x000000000000367c:  3E E8 09 23          call      0x5989
0x0000000000003680:  5A                   pop       dx
0x0000000000003681:  59                   pop       cx
0x0000000000003682:  5B                   pop       bx
0x0000000000003683:  C3                   ret       

ENDP

PROC    CXMTOF16_ NEAR
PUBLIC  CXMTOF16_


0x0000000000003684:  53                   push      bx
0x0000000000003685:  51                   push      cx
0x0000000000003686:  52                   push      dx
0x0000000000003687:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x000000000000368b:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x000000000000368f:  2B 06 4E 1A          sub       ax, word ptr [0x1a4e]
0x0000000000003693:  0E                   push      cs
0x0000000000003694:  3E E8 F1 22          call      0x5989
0x0000000000003698:  5A                   pop       dx
0x0000000000003699:  59                   pop       cx
0x000000000000369a:  5B                   pop       bx
0x000000000000369b:  C3                   ret       

ENDP

PROC    CYMTOF16_ NEAR
PUBLIC  CYMTOF16_

0x000000000000369c:  53                   push      bx
0x000000000000369d:  51                   push      cx
0x000000000000369e:  52                   push      dx
0x000000000000369f:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x00000000000036a3:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x00000000000036a7:  2B 06 50 1A          sub       ax, word ptr [0x1a50]
0x00000000000036ab:  0E                   push      cs
0x00000000000036ac:  3E E8 D9 22          call      0x5989
0x00000000000036b0:  BB A8 00             mov       bx, 0xa8
0x00000000000036b3:  29 C3                sub       bx, ax
0x00000000000036b5:  89 D8                mov       ax, bx
0x00000000000036b7:  5A                   pop       dx
0x00000000000036b8:  59                   pop       cx
0x00000000000036b9:  5B                   pop       bx
0x00000000000036ba:  C3                   ret       

ENDP

PROC    AM_activateNewScale_ NEAR
PUBLIC  AM_activateNewScale_

0x00000000000036bc:  53                   push      bx
0x00000000000036bd:  51                   push      cx
0x00000000000036be:  52                   push      dx
0x00000000000036bf:  A1 4C 1A             mov       ax, word ptr [0x1a4c]
0x00000000000036c2:  D1 F8                sar       ax, 1
0x00000000000036c4:  01 06 4E 1A          add       word ptr [0x1a4e], ax
0x00000000000036c8:  A1 34 1A             mov       ax, word ptr [0x1a34]
0x00000000000036cb:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x00000000000036cf:  D1 F8                sar       ax, 1
0x00000000000036d1:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x00000000000036d5:  01 06 50 1A          add       word ptr [0x1a50], ax
0x00000000000036d9:  B8 40 01             mov       ax, 0x140
0x00000000000036dc:  0E                   push      cs
0x00000000000036dd:  E8 A9 22             call      0x5989
0x00000000000036e0:  90                   nop       
0x00000000000036e1:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x00000000000036e5:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x00000000000036e9:  A3 4C 1A             mov       word ptr [0x1a4c], ax
0x00000000000036ec:  B8 A8 00             mov       ax, 0xa8
0x00000000000036ef:  0E                   push      cs
0x00000000000036f0:  3E E8 95 22          call      0x5989
0x00000000000036f4:  8B 1E 4C 1A          mov       bx, word ptr [0x1a4c]
0x00000000000036f8:  D1 FB                sar       bx, 1
0x00000000000036fa:  29 1E 4E 1A          sub       word ptr [0x1a4e], bx
0x00000000000036fe:  89 C3                mov       bx, ax
0x0000000000003700:  D1 FB                sar       bx, 1
0x0000000000003702:  29 1E 50 1A          sub       word ptr [0x1a50], bx
0x0000000000003706:  8B 1E 4E 1A          mov       bx, word ptr [0x1a4e]
0x000000000000370a:  03 1E 4C 1A          add       bx, word ptr [0x1a4c]
0x000000000000370e:  89 1E 4A 1A          mov       word ptr [0x1a4a], bx
0x0000000000003712:  8B 1E 50 1A          mov       bx, word ptr [0x1a50]
0x0000000000003716:  A3 34 1A             mov       word ptr [0x1a34], ax
0x0000000000003719:  01 D8                add       ax, bx
0x000000000000371b:  A3 46 1A             mov       word ptr [0x1a46], ax
0x000000000000371e:  5A                   pop       dx
0x000000000000371f:  59                   pop       cx
0x0000000000003720:  5B                   pop       bx
0x0000000000003721:  C3                   ret  

ENDP

PROC    AM_restoreScaleAndLoc_ NEAR
PUBLIC  AM_restoreScaleAndLoc_


0x0000000000003722:  53                   push      bx
0x0000000000003723:  51                   push      cx
0x0000000000003724:  52                   push      dx
0x0000000000003725:  56                   push      si
0x0000000000003726:  A1 38 1A             mov       ax, word ptr [0x1a38]
0x0000000000003729:  8B 16 42 1A          mov       dx, word ptr [0x1a42]
0x000000000000372d:  A3 4C 1A             mov       word ptr [0x1a4c], ax
0x0000000000003730:  89 16 34 1A          mov       word ptr [0x1a34], dx
0x0000000000003734:  80 3E 34 0E 00       cmp       byte ptr [0xe34], 0
0x0000000000003739:  75 4D                jne       0x3788
0x000000000000373b:  A1 3A 1A             mov       ax, word ptr [0x1a3a]
0x000000000000373e:  A3 4E 1A             mov       word ptr [0x1a4e], ax
0x0000000000003741:  A1 3C 1A             mov       ax, word ptr [0x1a3c]
0x0000000000003744:  A3 50 1A             mov       word ptr [0x1a50], ax
0x0000000000003747:  A1 4E 1A             mov       ax, word ptr [0x1a4e]
0x000000000000374a:  03 06 4C 1A          add       ax, word ptr [0x1a4c]
0x000000000000374e:  A3 4A 1A             mov       word ptr [0x1a4a], ax
0x0000000000003751:  A1 50 1A             mov       ax, word ptr [0x1a50]
0x0000000000003754:  8B 0E 4C 1A          mov       cx, word ptr [0x1a4c]
0x0000000000003758:  03 06 34 1A          add       ax, word ptr [0x1a34]
0x000000000000375c:  31 DB                xor       bx, bx
0x000000000000375e:  A3 46 1A             mov       word ptr [0x1a46], ax
0x0000000000003761:  B8 40 01             mov       ax, 0x140
0x0000000000003764:  0E                   push      cs
0x0000000000003765:  E8 4A 25             call      0x5cb2
0x0000000000003768:  90                   nop       
0x0000000000003769:  A3 04 1A             mov       word ptr [0x1a04], ax
0x000000000000376c:  89 C3                mov       bx, ax
0x000000000000376e:  89 D1                mov       cx, dx
0x0000000000003770:  B8 01 00             mov       ax, 1
0x0000000000003773:  89 16 06 1A          mov       word ptr [0x1a06], dx
0x0000000000003777:  0E                   push      cs
0x0000000000003778:  3E E8 36 25          call      0x5cb2
0x000000000000377c:  A3 08 1A             mov       word ptr [0x1a08], ax
0x000000000000377f:  89 16 0A 1A          mov       word ptr [0x1a0a], dx
0x0000000000003783:  5E                   pop       si
0x0000000000003784:  5A                   pop       dx
0x0000000000003785:  59                   pop       cx
0x0000000000003786:  5B                   pop       bx
0x0000000000003787:  C3                   ret       
0x0000000000003788:  BB 30 06             mov       bx, 0x630
0x000000000000378b:  C4 37                les       si, ptr [bx]
0x000000000000378d:  D1 F8                sar       ax, 1
0x000000000000378f:  26 8B 5C 02          mov       bx, word ptr es:[si + 2]
0x0000000000003793:  29 C3                sub       bx, ax
0x0000000000003795:  89 1E 4E 1A          mov       word ptr [0x1a4e], bx
0x0000000000003799:  BB 30 06             mov       bx, 0x630
0x000000000000379c:  C4 37                les       si, ptr [bx]
0x000000000000379e:  D1 FA                sar       dx, 1
0x00000000000037a0:  26 8B 44 06          mov       ax, word ptr es:[si + 6]
0x00000000000037a4:  29 D0                sub       ax, dx
0x00000000000037a6:  EB 9C                jmp       0x3744

ENDP

PROC    AM_addMark_ NEAR
PUBLIC  AM_addMark_

0x00000000000037a8:  53                   push      bx
0x00000000000037a9:  52                   push      dx
0x00000000000037aa:  A0 33 0E             mov       al, byte ptr [0xe33]
0x00000000000037ad:  98                   cwde      
0x00000000000037ae:  8B 16 4C 1A          mov       dx, word ptr [0x1a4c]
0x00000000000037b2:  89 C3                mov       bx, ax
0x00000000000037b4:  D1 FA                sar       dx, 1
0x00000000000037b6:  C1 E3 02             shl       bx, 2
0x00000000000037b9:  03 16 4E 1A          add       dx, word ptr [0x1a4e]
0x00000000000037bd:  89 97 C0 19          mov       word ptr [bx + 0x19c0], dx
0x00000000000037c1:  8B 16 34 1A          mov       dx, word ptr [0x1a34]
0x00000000000037c5:  D1 FA                sar       dx, 1
0x00000000000037c7:  03 16 50 1A          add       dx, word ptr [0x1a50]
0x00000000000037cb:  40                   inc       ax
0x00000000000037cc:  89 97 C2 19          mov       word ptr [bx + 0x19c2], dx
0x00000000000037d0:  BB 0A 00             mov       bx, 0xa
0x00000000000037d3:  99                   cdq       
0x00000000000037d4:  F7 FB                idiv      bx
0x00000000000037d6:  88 16 33 0E          mov       byte ptr [0xe33], dl
0x00000000000037da:  5A                   pop       dx
0x00000000000037db:  5B                   pop       bx
0x00000000000037dc:  C3                   ret       

ENDP

PROC    AM_findMinMaxBoundaries_ NEAR
PUBLIC  AM_findMinMaxBoundaries_

0x00000000000037de:  53                   push      bx
0x00000000000037df:  51                   push      cx
0x00000000000037e0:  52                   push      dx
0x00000000000037e1:  56                   push      si
0x00000000000037e2:  57                   push      di
0x00000000000037e3:  55                   push      bp
0x00000000000037e4:  89 E5                mov       bp, sp
0x00000000000037e6:  83 EC 04             sub       sp, 4
0x00000000000037e9:  B8 FF 7F             mov       ax, 0x7fff
0x00000000000037ec:  BF 01 80             mov       di, 0x8001
0x00000000000037ef:  31 DB                xor       bx, bx
0x00000000000037f1:  31 D2                xor       dx, dx
0x00000000000037f3:  A3 32 1A             mov       word ptr [0x1a32], ax
0x00000000000037f6:  A3 30 1A             mov       word ptr [0x1a30], ax
0x00000000000037f9:  89 3E 40 1A          mov       word ptr [0x1a40], di
0x00000000000037fd:  BE D2 04             mov       si, 0x4d2
0x0000000000003800:  3B 1C                cmp       bx, word ptr [si]
0x0000000000003802:  7D 43                jge       0x3847
0x0000000000003804:  B8 3B 23             mov       ax, 0x233b
0x0000000000003807:  89 D6                mov       si, dx
0x0000000000003809:  8E C0                mov       es, ax
0x000000000000380b:  26 8B 04             mov       ax, word ptr es:[si]
0x000000000000380e:  3B 06 30 1A          cmp       ax, word ptr [0x1a30]
0x0000000000003812:  7D 20                jge       0x3834
0x0000000000003814:  A3 30 1A             mov       word ptr [0x1a30], ax
0x0000000000003817:  B8 3B 23             mov       ax, 0x233b
0x000000000000381a:  89 D6                mov       si, dx
0x000000000000381c:  8E C0                mov       es, ax
0x000000000000381e:  26 8B 44 02          mov       ax, word ptr es:[si + 2]
0x0000000000003822:  83 C6 02             add       si, 2
0x0000000000003825:  3B 06 32 1A          cmp       ax, word ptr [0x1a32]
0x0000000000003829:  7D 14                jge       0x383f
0x000000000000382b:  A3 32 1A             mov       word ptr [0x1a32], ax
0x000000000000382e:  83 C2 04             add       dx, 4
0x0000000000003831:  43                   inc       bx
0x0000000000003832:  EB C9                jmp       0x37fd
0x0000000000003834:  3B 06 40 1A          cmp       ax, word ptr [0x1a40]
0x0000000000003838:  7E DD                jle       0x3817
0x000000000000383a:  A3 40 1A             mov       word ptr [0x1a40], ax
0x000000000000383d:  EB D8                jmp       0x3817
0x000000000000383f:  39 F8                cmp       ax, di
0x0000000000003841:  7E EB                jle       0x382e
0x0000000000003843:  89 C7                mov       di, ax
0x0000000000003845:  EB E7                jmp       0x382e
0x0000000000003847:  A1 40 1A             mov       ax, word ptr [0x1a40]
0x000000000000384a:  2B 06 30 1A          sub       ax, word ptr [0x1a30]
0x000000000000384e:  89 FE                mov       si, di
0x0000000000003850:  99                   cdq       
0x0000000000003851:  89 3E 3E 1A          mov       word ptr [0x1a3e], di
0x0000000000003855:  89 C3                mov       bx, ax
0x0000000000003857:  89 D1                mov       cx, dx
0x0000000000003859:  B8 40 01             mov       ax, 0x140
0x000000000000385c:  31 D2                xor       dx, dx
0x000000000000385e:  2B 36 32 1A          sub       si, word ptr [0x1a32]
0x0000000000003862:  0E                   push      cs
0x0000000000003863:  E8 80 23             call      0x5be6
0x0000000000003866:  90                   nop       
0x0000000000003867:  89 46 FC             mov       word ptr [bp - 4], ax
0x000000000000386a:  89 F0                mov       ax, si
0x000000000000386c:  89 56 FE             mov       word ptr [bp - 2], dx
0x000000000000386f:  99                   cdq       
0x0000000000003870:  89 C3                mov       bx, ax
0x0000000000003872:  89 D1                mov       cx, dx
0x0000000000003874:  B8 A8 00             mov       ax, 0xa8
0x0000000000003877:  31 D2                xor       dx, dx
0x0000000000003879:  0E                   push      cs
0x000000000000387a:  3E E8 68 23          call      0x5be6
0x000000000000387e:  8B 3E 3E 1A          mov       di, word ptr [0x1a3e]
0x0000000000003882:  3B 56 FE             cmp       dx, word ptr [bp - 2]
0x0000000000003885:  7F 07                jg        0x388e
0x0000000000003887:  75 08                jne       0x3891
0x0000000000003889:  3B 46 FC             cmp       ax, word ptr [bp - 4]
0x000000000000388c:  76 03                jbe       0x3891
0x000000000000388e:  8B 46 FC             mov       ax, word ptr [bp - 4]
0x0000000000003891:  C7 06 00 1A 00 40    mov       word ptr [0x1a00], 0x4000
0x0000000000003897:  C7 06 02 1A 05 00    mov       word ptr [0x1a02], 5
0x000000000000389d:  A3 36 1A             mov       word ptr [0x1a36], ax
0x00000000000038a0:  89 3E 3E 1A          mov       word ptr [0x1a3e], di
0x00000000000038a4:  C9                   leave     
0x00000000000038a5:  5F                   pop       di
0x00000000000038a6:  5E                   pop       si
0x00000000000038a7:  5A                   pop       dx
0x00000000000038a8:  59                   pop       cx
0x00000000000038a9:  5B                   pop       bx
0x00000000000038aa:  C3                   ret       

ENDP

PROC    AM_changeWindowLoc_ NEAR
PUBLIC  AM_changeWindowLoc_

0x00000000000038ac:  53                   push      bx
0x00000000000038ad:  51                   push      cx
0x00000000000038ae:  52                   push      dx
0x00000000000038af:  8B 16 4E 1A          mov       dx, word ptr [0x1a4e]
0x00000000000038b3:  8B 1E 50 1A          mov       bx, word ptr [0x1a50]
0x00000000000038b7:  83 3E 10 1A 00       cmp       word ptr [0x1a10], 0
0x00000000000038bc:  75 07                jne       0x38c5
0x00000000000038be:  83 3E 12 1A 00       cmp       word ptr [0x1a12], 0
0x00000000000038c3:  74 0B                je        0x38d0
0x00000000000038c5:  C6 06 34 0E 00       mov       byte ptr [0xe34], 0
0x00000000000038ca:  C7 06 0C 1A FF 7F    mov       word ptr [0x1a0c], 0x7fff
0x00000000000038d0:  A1 10 1A             mov       ax, word ptr [0x1a10]
0x00000000000038d3:  01 C2                add       dx, ax
0x00000000000038d5:  A1 12 1A             mov       ax, word ptr [0x1a12]
0x00000000000038d8:  01 C3                add       bx, ax
0x00000000000038da:  A1 4C 1A             mov       ax, word ptr [0x1a4c]
0x00000000000038dd:  89 D1                mov       cx, dx
0x00000000000038df:  D1 F8                sar       ax, 1
0x00000000000038e1:  01 C1                add       cx, ax
0x00000000000038e3:  3B 0E 40 1A          cmp       cx, word ptr [0x1a40]
0x00000000000038e7:  7E 3F                jle       0x3928
0x00000000000038e9:  8B 16 40 1A          mov       dx, word ptr [0x1a40]
0x00000000000038ed:  29 C2                sub       dx, ax
0x00000000000038ef:  A1 34 1A             mov       ax, word ptr [0x1a34]
0x00000000000038f2:  89 D9                mov       cx, bx
0x00000000000038f4:  D1 F8                sar       ax, 1
0x00000000000038f6:  01 C1                add       cx, ax
0x00000000000038f8:  3B 0E 3E 1A          cmp       cx, word ptr [0x1a3e]
0x00000000000038fc:  7F 36                jg        0x3934
0x00000000000038fe:  3B 0E 32 1A          cmp       cx, word ptr [0x1a32]
0x0000000000003902:  7D 06                jge       0x390a
0x0000000000003904:  8B 1E 32 1A          mov       bx, word ptr [0x1a32]
0x0000000000003908:  29 C3                sub       bx, ax
0x000000000000390a:  89 D0                mov       ax, dx
0x000000000000390c:  03 06 4C 1A          add       ax, word ptr [0x1a4c]
0x0000000000003910:  A3 4A 1A             mov       word ptr [0x1a4a], ax
0x0000000000003913:  89 D8                mov       ax, bx
0x0000000000003915:  03 06 34 1A          add       ax, word ptr [0x1a34]
0x0000000000003919:  A3 46 1A             mov       word ptr [0x1a46], ax
0x000000000000391c:  89 1E 50 1A          mov       word ptr [0x1a50], bx
0x0000000000003920:  89 16 4E 1A          mov       word ptr [0x1a4e], dx
0x0000000000003924:  5A                   pop       dx
0x0000000000003925:  59                   pop       cx
0x0000000000003926:  5B                   pop       bx
0x0000000000003927:  C3                   ret       
0x0000000000003928:  3B 0E 30 1A          cmp       cx, word ptr [0x1a30]
0x000000000000392c:  7D C1                jge       0x38ef
0x000000000000392e:  8B 16 30 1A          mov       dx, word ptr [0x1a30]
0x0000000000003932:  EB B9                jmp       0x38ed
0x0000000000003934:  8B 1E 3E 1A          mov       bx, word ptr [0x1a3e]
0x0000000000003938:  EB CE                jmp       0x3908

ENDP

PROC    AM_initVariables_ NEAR
PUBLIC  AM_initVariables_

0x000000000000393a:  53                   push      bx
0x000000000000393b:  51                   push      cx
0x000000000000393c:  52                   push      dx
0x000000000000393d:  56                   push      si
0x000000000000393e:  BB EA 02             mov       bx, 0x2ea
0x0000000000003941:  31 C0                xor       ax, ax
0x0000000000003943:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x0000000000003947:  A3 12 1A             mov       word ptr [0x1a12], ax
0x000000000000394a:  A3 10 1A             mov       word ptr [0x1a10], ax
0x000000000000394d:  C6 07 01             mov       byte ptr [bx], 1
0x0000000000003950:  B8 00 10             mov       ax, 0x1000
0x0000000000003953:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x0000000000003957:  A3 54 1A             mov       word ptr [0x1a54], ax
0x000000000000395a:  A3 58 1A             mov       word ptr [0x1a58], ax
0x000000000000395d:  B8 40 01             mov       ax, 0x140
0x0000000000003960:  C7 06 0C 1A FF 7F    mov       word ptr [0x1a0c], 0x7fff
0x0000000000003966:  0E                   push      cs
0x0000000000003967:  E8 1F 20             call      0x5989
0x000000000000396a:  90                   nop       
0x000000000000396b:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x000000000000396f:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x0000000000003973:  A3 4C 1A             mov       word ptr [0x1a4c], ax
0x0000000000003976:  B8 A8 00             mov       ax, 0xa8
0x0000000000003979:  0E                   push      cs
0x000000000000397a:  3E E8 0B 20          call      0x5989
0x000000000000397e:  BB 30 06             mov       bx, 0x630
0x0000000000003981:  A3 34 1A             mov       word ptr [0x1a34], ax
0x0000000000003984:  C4 37                les       si, ptr [bx]
0x0000000000003986:  8B 1E 4C 1A          mov       bx, word ptr [0x1a4c]
0x000000000000398a:  26 8B 4C 02          mov       cx, word ptr es:[si + 2]
0x000000000000398e:  D1 FB                sar       bx, 1
0x0000000000003990:  29 D9                sub       cx, bx
0x0000000000003992:  BB 30 06             mov       bx, 0x630
0x0000000000003995:  89 0E 4E 1A          mov       word ptr [0x1a4e], cx
0x0000000000003999:  C4 37                les       si, ptr [bx]
0x000000000000399b:  D1 F8                sar       ax, 1
0x000000000000399d:  26 8B 5C 06          mov       bx, word ptr es:[si + 6]
0x00000000000039a1:  29 C3                sub       bx, ax
0x00000000000039a3:  89 1E 50 1A          mov       word ptr [0x1a50], bx
0x00000000000039a7:  E8 02 FF             call      0x38ac
0x00000000000039aa:  A1 4E 1A             mov       ax, word ptr [0x1a4e]
0x00000000000039ad:  BB F4 0A             mov       bx, 0xaf4
0x00000000000039b0:  A3 3A 1A             mov       word ptr [0x1a3a], ax
0x00000000000039b3:  A1 50 1A             mov       ax, word ptr [0x1a50]
0x00000000000039b6:  C6 07 00             mov       byte ptr [bx], 0
0x00000000000039b9:  A3 3C 1A             mov       word ptr [0x1a3c], ax
0x00000000000039bc:  A1 4C 1A             mov       ax, word ptr [0x1a4c]
0x00000000000039bf:  BB F5 0A             mov       bx, 0xaf5
0x00000000000039c2:  A3 38 1A             mov       word ptr [0x1a38], ax
0x00000000000039c5:  A1 34 1A             mov       ax, word ptr [0x1a34]
0x00000000000039c8:  C6 07 01             mov       byte ptr [bx], 1
0x00000000000039cb:  A3 42 1A             mov       word ptr [0x1a42], ax
0x00000000000039ce:  5E                   pop       si
0x00000000000039cf:  5A                   pop       dx
0x00000000000039d0:  59                   pop       cx
0x00000000000039d1:  5B                   pop       bx
0x00000000000039d2:  C3                   ret       

ENDP

PROC    AM_clearMarks_ NEAR
PUBLIC  AM_clearMarks_

0x00000000000039d4:  51                   push      cx
0x00000000000039d5:  57                   push      di
0x00000000000039d6:  B9 28 00             mov       cx, 0x28
0x00000000000039d9:  B0 FF                mov       al, 0xff
0x00000000000039db:  BF C0 19             mov       di, 0x19c0
0x00000000000039de:  57                   push      di
0x00000000000039df:  1E                   push      ds
0x00000000000039e0:  07                   pop       es
0x00000000000039e1:  8A E0                mov       ah, al
0x00000000000039e3:  D1 E9                shr       cx, 1
0x00000000000039e5:  F3 AB                rep stosw word ptr es:[di], ax
0x00000000000039e7:  13 C9                adc       cx, cx
0x00000000000039e9:  F3 AA                rep stosb byte ptr es:[di], al
0x00000000000039eb:  5F                   pop       di
0x00000000000039ec:  C6 06 33 0E 00       mov       byte ptr [0xe33], 0
0x00000000000039f1:  5F                   pop       di
0x00000000000039f2:  59                   pop       cx
0x00000000000039f3:  C3                   ret       

ENDP

PROC    AM_LevelInit_ NEAR
PUBLIC  AM_LevelInit_

0x00000000000039f4:  53                   push      bx
0x00000000000039f5:  51                   push      cx
0x00000000000039f6:  52                   push      dx
0x00000000000039f7:  57                   push      di
0x00000000000039f8:  C7 06 04 1A 33 33    mov       word ptr [0x1a04], 0x3333
0x00000000000039fe:  B9 28 00             mov       cx, 0x28
0x0000000000003a01:  31 C0                xor       ax, ax
0x0000000000003a03:  BF C0 19             mov       di, 0x19c0
0x0000000000003a06:  A3 06 1A             mov       word ptr [0x1a06], ax
0x0000000000003a09:  B0 FF                mov       al, 0xff
0x0000000000003a0b:  BB 33 B3             mov       bx, 0xb333
0x0000000000003a0e:  57                   push      di
0x0000000000003a0f:  1E                   push      ds
0x0000000000003a10:  07                   pop       es
0x0000000000003a11:  8A E0                mov       ah, al
0x0000000000003a13:  D1 E9                shr       cx, 1
0x0000000000003a15:  F3 AB                rep stosw word ptr es:[di], ax
0x0000000000003a17:  13 C9                adc       cx, cx
0x0000000000003a19:  F3 AA                rep stosb byte ptr es:[di], al
0x0000000000003a1b:  5F                   pop       di
0x0000000000003a1c:  C6 06 33 0E 00       mov       byte ptr [0xe33], 0
0x0000000000003a21:  E8 BA FD             call      0x37de
0x0000000000003a24:  8B 16 36 1A          mov       dx, word ptr [0x1a36]
0x0000000000003a28:  31 C0                xor       ax, ax
0x0000000000003a2a:  0E                   push      cs
0x0000000000003a2b:  E8 44 22             call      0x5c72
0x0000000000003a2e:  90                   nop       
0x0000000000003a2f:  A3 04 1A             mov       word ptr [0x1a04], ax
0x0000000000003a32:  89 16 06 1A          mov       word ptr [0x1a06], dx
0x0000000000003a36:  3B 16 02 1A          cmp       dx, word ptr [0x1a02]
0x0000000000003a3a:  7F 08                jg        0x3a44
0x0000000000003a3c:  75 11                jne       0x3a4f
0x0000000000003a3e:  3B 06 00 1A          cmp       ax, word ptr [0x1a00]
0x0000000000003a42:  76 0B                jbe       0x3a4f
0x0000000000003a44:  A1 36 1A             mov       ax, word ptr [0x1a36]
0x0000000000003a47:  A3 04 1A             mov       word ptr [0x1a04], ax
0x0000000000003a4a:  31 C0                xor       ax, ax
0x0000000000003a4c:  A3 06 1A             mov       word ptr [0x1a06], ax
0x0000000000003a4f:  B8 01 00             mov       ax, 1
0x0000000000003a52:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x0000000000003a56:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x0000000000003a5a:  0E                   push      cs
0x0000000000003a5b:  E8 54 22             call      0x5cb2
0x0000000000003a5e:  90                   nop       
0x0000000000003a5f:  A3 08 1A             mov       word ptr [0x1a08], ax
0x0000000000003a62:  89 16 0A 1A          mov       word ptr [0x1a0a], dx
0x0000000000003a66:  5F                   pop       di
0x0000000000003a67:  5A                   pop       dx
0x0000000000003a68:  59                   pop       cx
0x0000000000003a69:  5B                   pop       bx
0x0000000000003a6a:  C3                   ret       


ENDP

PROC    AM_Stop_ FAR
PUBLIC  AM_Stop_

0x0000000000003a6c:  53                   push      bx
0x0000000000003a6d:  BB EA 02             mov       bx, 0x2ea
0x0000000000003a70:  C6 07 00             mov       byte ptr [bx], 0
0x0000000000003a73:  BB F4 0A             mov       bx, 0xaf4
0x0000000000003a76:  C6 06 35 0E 01       mov       byte ptr [0xe35], 1
0x0000000000003a7b:  C6 07 01             mov       byte ptr [bx], 1
0x0000000000003a7e:  5B                   pop       bx
0x0000000000003a7f:  CB                   retf      


ENDP

PROC    AM_Start_ NEAR
PUBLIC  AM_Start_


0x0000000000003a80:  53                   push      bx
0x0000000000003a81:  A0 35 0E             mov       al, byte ptr [0xe35]
0x0000000000003a84:  84 C0                test      al, al
0x0000000000003a86:  74 1E                je        0x3aa6
0x0000000000003a88:  BB A7 03             mov       bx, 0x3a7
0x0000000000003a8b:  A0 37 0E             mov       al, byte ptr [0xe37]
0x0000000000003a8e:  C6 06 35 0E 00       mov       byte ptr [0xe35], 0
0x0000000000003a93:  3A 07                cmp       al, byte ptr [bx]
0x0000000000003a95:  75 1C                jne       0x3ab3
0x0000000000003a97:  BB A6 03             mov       bx, 0x3a6
0x0000000000003a9a:  A0 38 0E             mov       al, byte ptr [0xe38]
0x0000000000003a9d:  3A 07                cmp       al, byte ptr [bx]
0x0000000000003a9f:  75 12                jne       0x3ab3
0x0000000000003aa1:  E8 96 FE             call      0x393a
0x0000000000003aa4:  5B                   pop       bx
0x0000000000003aa5:  CB                   retf      
0x0000000000003aa6:  BB EA 02             mov       bx, 0x2ea
0x0000000000003aa9:  88 07                mov       byte ptr [bx], al
0x0000000000003aab:  BB F4 0A             mov       bx, 0xaf4
0x0000000000003aae:  C6 07 01             mov       byte ptr [bx], 1
0x0000000000003ab1:  EB D5                jmp       0x3a88
0x0000000000003ab3:  BB A7 03             mov       bx, 0x3a7
0x0000000000003ab6:  E8 3B FF             call      0x39f4
0x0000000000003ab9:  8A 1F                mov       bl, byte ptr [bx]
0x0000000000003abb:  88 1E 37 0E          mov       byte ptr [0xe37], bl
0x0000000000003abf:  BB A6 03             mov       bx, 0x3a6
0x0000000000003ac2:  8A 1F                mov       bl, byte ptr [bx]
0x0000000000003ac4:  88 1E 38 0E          mov       byte ptr [0xe38], bl
0x0000000000003ac8:  E8 6F FE             call      0x393a
0x0000000000003acb:  5B                   pop       bx
0x0000000000003acc:  CB                   retf      

ENDP

PROC    AM_minOutWindowScale_ NEAR
PUBLIC  AM_minOutWindowScale_

0x0000000000003ace:  53                   push      bx
0x0000000000003acf:  51                   push      cx
0x0000000000003ad0:  52                   push      dx
0x0000000000003ad1:  A1 36 1A             mov       ax, word ptr [0x1a36]
0x0000000000003ad4:  A3 04 1A             mov       word ptr [0x1a04], ax
0x0000000000003ad7:  31 C0                xor       ax, ax
0x0000000000003ad9:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x0000000000003add:  A3 06 1A             mov       word ptr [0x1a06], ax
0x0000000000003ae0:  89 C1                mov       cx, ax
0x0000000000003ae2:  B8 01 00             mov       ax, 1
0x0000000000003ae5:  0E                   push      cs
0x0000000000003ae6:  3E E8 C8 21          call      0x5cb2
0x0000000000003aea:  A3 08 1A             mov       word ptr [0x1a08], ax
0x0000000000003aed:  89 16 0A 1A          mov       word ptr [0x1a0a], dx
0x0000000000003af1:  E8 C8 FB             call      0x36bc
0x0000000000003af4:  5A                   pop       dx
0x0000000000003af5:  59                   pop       cx
0x0000000000003af6:  5B                   pop       bx
0x0000000000003af7:  C3                   ret       

ENDP

PROC    AM_maxOutWindowScale_ NEAR
PUBLIC  AM_maxOutWindowScale_

0x0000000000003af8:  53                   push      bx
0x0000000000003af9:  51                   push      cx
0x0000000000003afa:  52                   push      dx
0x0000000000003afb:  B8 01 00             mov       ax, 1
0x0000000000003afe:  8B 1E 00 1A          mov       bx, word ptr [0x1a00]
0x0000000000003b02:  8B 0E 02 1A          mov       cx, word ptr [0x1a02]
0x0000000000003b06:  89 1E 04 1A          mov       word ptr [0x1a04], bx
0x0000000000003b0a:  89 0E 06 1A          mov       word ptr [0x1a06], cx
0x0000000000003b0e:  0E                   push      cs
0x0000000000003b0f:  E8 A0 21             call      0x5cb2
0x0000000000003b12:  90                   nop       
0x0000000000003b13:  A3 08 1A             mov       word ptr [0x1a08], ax
0x0000000000003b16:  89 16 0A 1A          mov       word ptr [0x1a0a], dx
0x0000000000003b1a:  E8 9F FB             call      0x36bc
0x0000000000003b1d:  5A                   pop       dx
0x0000000000003b1e:  59                   pop       cx
0x0000000000003b1f:  5B                   pop       bx
0x0000000000003b20:  C3                   ret       

ENDP

PROC    AM_Responder_ NEAR
PUBLIC  AM_Responder_

0x0000000000003b22:  53                   push      bx
0x0000000000003b23:  51                   push      cx
0x0000000000003b24:  56                   push      si
0x0000000000003b25:  57                   push      di
0x0000000000003b26:  55                   push      bp
0x0000000000003b27:  89 E5                mov       bp, sp
0x0000000000003b29:  83 EC 6A             sub       sp, 0x6a
0x0000000000003b2c:  89 C6                mov       si, ax
0x0000000000003b2e:  89 56 FC             mov       word ptr [bp - 4], dx
0x0000000000003b31:  BB EA 02             mov       bx, 0x2ea
0x0000000000003b34:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x0000000000003b38:  80 3F 00             cmp       byte ptr [bx], 0
0x0000000000003b3b:  75 2F                jne       0x3b6c
0x0000000000003b3d:  8E C2                mov       es, dx
0x0000000000003b3f:  26 80 3C 00          cmp       byte ptr es:[si], 0
0x0000000000003b43:  75 0E                jne       0x3b53
0x0000000000003b45:  26 83 7C 03 00       cmp       word ptr es:[si + 3], 0
0x0000000000003b4a:  75 07                jne       0x3b53
0x0000000000003b4c:  26 83 7C 01 09       cmp       word ptr es:[si + 1], 9
0x0000000000003b51:  74 09                je        0x3b5c
0x0000000000003b53:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000003b56:  C9                   leave     
0x0000000000003b57:  5F                   pop       di
0x0000000000003b58:  5E                   pop       si
0x0000000000003b59:  59                   pop       cx
0x0000000000003b5a:  5B                   pop       bx
0x0000000000003b5b:  C3                   ret       
0x0000000000003b5c:  0E                   push      cs
0x0000000000003b5d:  E8 20 FF             call      0x3a80
0x0000000000003b60:  BB E9 02             mov       bx, 0x2e9
0x0000000000003b63:  C6 46 FE 01          mov       byte ptr [bp - 2], 1
0x0000000000003b67:  C6 07 00             mov       byte ptr [bx], 0
0x0000000000003b6a:  EB E7                jmp       0x3b53
0x0000000000003b6c:  8E C2                mov       es, dx
0x0000000000003b6e:  26 8A 04             mov       al, byte ptr es:[si]
0x0000000000003b71:  84 C0                test      al, al
0x0000000000003b73:  75 63                jne       0x3bd8
0x0000000000003b75:  C6 46 FE 01          mov       byte ptr [bp - 2], 1
0x0000000000003b79:  26 8B 4C 03          mov       cx, word ptr es:[si + 3]
0x0000000000003b7d:  26 8B 44 01          mov       ax, word ptr es:[si + 1]
0x0000000000003b81:  85 C9                test      cx, cx
0x0000000000003b83:  75 5C                jne       0x3be1
0x0000000000003b85:  3D 66 00             cmp       ax, 0x66
0x0000000000003b88:  73 57                jae       0x3be1
0x0000000000003b8a:  85 C9                test      cx, cx
0x0000000000003b8c:  75 4D                jne       0x3bdb
0x0000000000003b8e:  3D 30 00             cmp       ax, 0x30
0x0000000000003b91:  73 48                jae       0x3bdb
0x0000000000003b93:  85 C9                test      cx, cx
0x0000000000003b95:  75 47                jne       0x3bde
0x0000000000003b97:  3D 2D 00             cmp       ax, 0x2d
0x0000000000003b9a:  75 42                jne       0x3bde
0x0000000000003b9c:  C7 06 58 1A AF 0F    mov       word ptr [0x1a58], 0xfaf
0x0000000000003ba2:  C7 06 54 1A 51 10    mov       word ptr [0x1a54], 0x1051
0x0000000000003ba8:  8E 46 FC             mov       es, word ptr [bp - 4]
0x0000000000003bab:  26 8A 44 01          mov       al, byte ptr es:[si + 1]
0x0000000000003baf:  98                   cwde      
0x0000000000003bb0:  89 C2                mov       dx, ax
0x0000000000003bb2:  B8 1C 00             mov       ax, 0x1c
0x0000000000003bb5:  E8 67 23             call      0x5f1f
0x0000000000003bb8:  84 C0                test      al, al
0x0000000000003bba:  74 97                je        0x3b53
0x0000000000003bbc:  A0 31 0E             mov       al, byte ptr [0xe31]
0x0000000000003bbf:  98                   cwde      
0x0000000000003bc0:  40                   inc       ax
0x0000000000003bc1:  BB 03 00             mov       bx, 3
0x0000000000003bc4:  99                   cdq       
0x0000000000003bc5:  F7 FB                idiv      bx
0x0000000000003bc7:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x0000000000003bcb:  88 16 31 0E          mov       byte ptr [0xe31], dl
0x0000000000003bcf:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000003bd2:  C9                   leave     
0x0000000000003bd3:  5F                   pop       di
0x0000000000003bd4:  5E                   pop       si
0x0000000000003bd5:  59                   pop       cx
0x0000000000003bd6:  5B                   pop       bx
0x0000000000003bd7:  C3                   ret       
0x0000000000003bd8:  E9 3C 02             jmp       0x3e17
0x0000000000003bdb:  E9 D5 00             jmp       0x3cb3
0x0000000000003bde:  E9 35 01             jmp       0x3d16
0x0000000000003be1:  85 C9                test      cx, cx
0x0000000000003be3:  75 25                jne       0x3c0a
0x0000000000003be5:  3D 66 00             cmp       ax, 0x66
0x0000000000003be8:  77 20                ja        0x3c0a
0x0000000000003bea:  80 3E 34 0E 00       cmp       byte ptr [0xe34], 0
0x0000000000003bef:  75 4F                jne       0x3c40
0x0000000000003bf1:  B0 01                mov       al, 1
0x0000000000003bf3:  C7 06 0C 1A FF 7F    mov       word ptr [0x1a0c], 0x7fff
0x0000000000003bf9:  A2 34 0E             mov       byte ptr [0xe34], al
0x0000000000003bfc:  84 C0                test      al, al
0x0000000000003bfe:  74 5A                je        0x3c5a
0x0000000000003c00:  B8 DB 00             mov       ax, 0xdb
0x0000000000003c03:  BB 24 07             mov       bx, 0x724
0x0000000000003c06:  89 07                mov       word ptr [bx], ax
0x0000000000003c08:  EB 9E                jmp       0x3ba8
0x0000000000003c0a:  85 C9                test      cx, cx
0x0000000000003c0c:  75 35                jne       0x3c43
0x0000000000003c0e:  3D AC 00             cmp       ax, 0xac
0x0000000000003c11:  73 30                jae       0x3c43
0x0000000000003c13:  85 C9                test      cx, cx
0x0000000000003c15:  75 05                jne       0x3c1c
0x0000000000003c17:  3D 6D 00             cmp       ax, 0x6d
0x0000000000003c1a:  74 58                je        0x3c74
0x0000000000003c1c:  85 C9                test      cx, cx
0x0000000000003c1e:  75 57                jne       0x3c77
0x0000000000003c20:  3D 67 00             cmp       ax, 0x67
0x0000000000003c23:  75 52                jne       0x3c77
0x0000000000003c25:  80 3E 32 0E 00       cmp       byte ptr [0xe32], 0
0x0000000000003c2a:  75 4D                jne       0x3c79
0x0000000000003c2c:  B0 01                mov       al, 1
0x0000000000003c2e:  A2 32 0E             mov       byte ptr [0xe32], al
0x0000000000003c31:  84 C0                test      al, al
0x0000000000003c33:  74 5E                je        0x3c93
0x0000000000003c35:  B8 DD 00             mov       ax, 0xdd
0x0000000000003c38:  BB 24 07             mov       bx, 0x724
0x0000000000003c3b:  89 07                mov       word ptr [bx], ax
0x0000000000003c3d:  E9 68 FF             jmp       0x3ba8
0x0000000000003c40:  E9 8B 01             jmp       0x3dce
0x0000000000003c43:  85 C9                test      cx, cx
0x0000000000003c45:  75 16                jne       0x3c5d
0x0000000000003c47:  3D AC 00             cmp       ax, 0xac
0x0000000000003c4a:  77 11                ja        0x3c5d
0x0000000000003c4c:  80 3E 34 0E 00       cmp       byte ptr [0xe34], 0
0x0000000000003c51:  74 5A                je        0x3cad
0x0000000000003c53:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x0000000000003c57:  E9 4E FF             jmp       0x3ba8
0x0000000000003c5a:  E9 76 01             jmp       0x3dd3
0x0000000000003c5d:  85 C9                test      cx, cx
0x0000000000003c5f:  75 1B                jne       0x3c7c
0x0000000000003c61:  3D AF 00             cmp       ax, 0xaf
0x0000000000003c64:  75 16                jne       0x3c7c
0x0000000000003c66:  80 3E 34 0E 00       cmp       byte ptr [0xe34], 0
0x0000000000003c6b:  74 43                je        0x3cb0
0x0000000000003c6d:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x0000000000003c71:  E9 34 FF             jmp       0x3ba8
0x0000000000003c74:  E9 77 01             jmp       0x3dee
0x0000000000003c77:  EB 2D                jmp       0x3ca6
0x0000000000003c79:  E9 62 01             jmp       0x3dde
0x0000000000003c7c:  85 C9                test      cx, cx
0x0000000000003c7e:  75 16                jne       0x3c96
0x0000000000003c80:  3D AE 00             cmp       ax, 0xae
0x0000000000003c83:  75 11                jne       0x3c96
0x0000000000003c85:  80 3E 34 0E 00       cmp       byte ptr [0xe34], 0
0x0000000000003c8a:  74 5E                je        0x3cea
0x0000000000003c8c:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x0000000000003c90:  E9 15 FF             jmp       0x3ba8
0x0000000000003c93:  E9 4D 01             jmp       0x3de3
0x0000000000003c96:  85 C9                test      cx, cx
0x0000000000003c98:  75 0C                jne       0x3ca6
0x0000000000003c9a:  3D AD 00             cmp       ax, 0xad
0x0000000000003c9d:  75 07                jne       0x3ca6
0x0000000000003c9f:  80 3E 34 0E 00       cmp       byte ptr [0xe34], 0
0x0000000000003ca4:  74 46                je        0x3cec
0x0000000000003ca6:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x0000000000003caa:  E9 FB FE             jmp       0x3ba8
0x0000000000003cad:  E9 C9 00             jmp       0x3d79
0x0000000000003cb0:  E9 F6 00             jmp       0x3da9
0x0000000000003cb3:  85 C9                test      cx, cx
0x0000000000003cb5:  75 38                jne       0x3cef
0x0000000000003cb7:  3D 30 00             cmp       ax, 0x30
0x0000000000003cba:  77 33                ja        0x3cef
0x0000000000003cbc:  80 3E 36 0E 00       cmp       byte ptr [0xe36], 0
0x0000000000003cc1:  75 4D                jne       0x3d10
0x0000000000003cc3:  B0 01                mov       al, 1
0x0000000000003cc5:  A2 36 0E             mov       byte ptr [0xe36], al
0x0000000000003cc8:  84 C0                test      al, al
0x0000000000003cca:  74 47                je        0x3d13
0x0000000000003ccc:  A1 4E 1A             mov       ax, word ptr [0x1a4e]
0x0000000000003ccf:  A3 3A 1A             mov       word ptr [0x1a3a], ax
0x0000000000003cd2:  A1 50 1A             mov       ax, word ptr [0x1a50]
0x0000000000003cd5:  A3 3C 1A             mov       word ptr [0x1a3c], ax
0x0000000000003cd8:  A1 4C 1A             mov       ax, word ptr [0x1a4c]
0x0000000000003cdb:  A3 38 1A             mov       word ptr [0x1a38], ax
0x0000000000003cde:  A1 34 1A             mov       ax, word ptr [0x1a34]
0x0000000000003ce1:  A3 42 1A             mov       word ptr [0x1a42], ax
0x0000000000003ce4:  E8 E7 FD             call      0x3ace
0x0000000000003ce7:  E9 BE FE             jmp       0x3ba8
0x0000000000003cea:  EB 51                jmp       0x3d3d
0x0000000000003cec:  E9 A4 00             jmp       0x3d93
0x0000000000003cef:  85 C9                test      cx, cx
0x0000000000003cf1:  75 05                jne       0x3cf8
0x0000000000003cf3:  3D 63 00             cmp       ax, 0x63
0x0000000000003cf6:  74 5B                je        0x3d53
0x0000000000003cf8:  85 C9                test      cx, cx
0x0000000000003cfa:  75 AA                jne       0x3ca6
0x0000000000003cfc:  3D 3D 00             cmp       ax, 0x3d
0x0000000000003cff:  75 A5                jne       0x3ca6
0x0000000000003d01:  C7 06 58 1A 51 10    mov       word ptr [0x1a58], 0x1051
0x0000000000003d07:  C7 06 54 1A AF 0F    mov       word ptr [0x1a54], 0xfaf
0x0000000000003d0d:  E9 98 FE             jmp       0x3ba8
0x0000000000003d10:  E9 B0 00             jmp       0x3dc3
0x0000000000003d13:  E9 B2 00             jmp       0x3dc8
0x0000000000003d16:  85 C9                test      cx, cx
0x0000000000003d18:  75 8C                jne       0x3ca6
0x0000000000003d1a:  3D 09 00             cmp       ax, 9
0x0000000000003d1d:  75 87                jne       0x3ca6
0x0000000000003d1f:  BB E9 02             mov       bx, 0x2e9
0x0000000000003d22:  30 C0                xor       al, al
0x0000000000003d24:  C6 07 01             mov       byte ptr [bx], 1
0x0000000000003d27:  BB EA 02             mov       bx, 0x2ea
0x0000000000003d2a:  C6 06 35 0E 01       mov       byte ptr [0xe35], 1
0x0000000000003d2f:  88 07                mov       byte ptr [bx], al
0x0000000000003d31:  BB F4 0A             mov       bx, 0xaf4
0x0000000000003d34:  A2 36 0E             mov       byte ptr [0xe36], al
0x0000000000003d37:  C6 07 01             mov       byte ptr [bx], 1
0x0000000000003d3a:  E9 6B FE             jmp       0x3ba8
0x0000000000003d3d:  B8 04 00             mov       ax, 4
0x0000000000003d40:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x0000000000003d44:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x0000000000003d48:  0E                   push      cs
0x0000000000003d49:  E8 3D 1C             call      0x5989
0x0000000000003d4c:  90                   nop       
0x0000000000003d4d:  A3 10 1A             mov       word ptr [0x1a10], ax
0x0000000000003d50:  E9 55 FE             jmp       0x3ba8
0x0000000000003d53:  B9 28 00             mov       cx, 0x28
0x0000000000003d56:  B8 FF FF             mov       ax, 0xffff
0x0000000000003d59:  BF C0 19             mov       di, 0x19c0
0x0000000000003d5c:  BB 24 07             mov       bx, 0x724
0x0000000000003d5f:  57                   push      di
0x0000000000003d60:  1E                   push      ds
0x0000000000003d61:  07                   pop       es
0x0000000000003d62:  8A E0                mov       ah, al
0x0000000000003d64:  D1 E9                shr       cx, 1
0x0000000000003d66:  F3 AB                rep stosw word ptr es:[di], ax
0x0000000000003d68:  13 C9                adc       cx, cx
0x0000000000003d6a:  F3 AA                rep stosb byte ptr es:[di], al
0x0000000000003d6c:  5F                   pop       di
0x0000000000003d6d:  C6 06 33 0E 00       mov       byte ptr [0xe33], 0
0x0000000000003d72:  C7 07 E0 00          mov       word ptr [bx], 0xe0
0x0000000000003d76:  E9 2F FE             jmp       0x3ba8
0x0000000000003d79:  B8 04 00             mov       ax, 4
0x0000000000003d7c:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x0000000000003d80:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x0000000000003d84:  0E                   push      cs
0x0000000000003d85:  E8 01 1C             call      0x5989
0x0000000000003d88:  90                   nop       
0x0000000000003d89:  A3 10 1A             mov       word ptr [0x1a10], ax
0x0000000000003d8c:  F7 1E 10 1A          neg       word ptr [0x1a10]
0x0000000000003d90:  E9 15 FE             jmp       0x3ba8
0x0000000000003d93:  B8 04 00             mov       ax, 4
0x0000000000003d96:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x0000000000003d9a:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x0000000000003d9e:  0E                   push      cs
0x0000000000003d9f:  E8 E7 1B             call      0x5989
0x0000000000003da2:  90                   nop       
0x0000000000003da3:  A3 12 1A             mov       word ptr [0x1a12], ax
0x0000000000003da6:  E9 FF FD             jmp       0x3ba8
0x0000000000003da9:  B8 04 00             mov       ax, 4
0x0000000000003dac:  8B 1E 08 1A          mov       bx, word ptr [0x1a08]
0x0000000000003db0:  8B 0E 0A 1A          mov       cx, word ptr [0x1a0a]
0x0000000000003db4:  0E                   push      cs
0x0000000000003db5:  E8 D1 1B             call      0x5989
0x0000000000003db8:  90                   nop       
0x0000000000003db9:  A3 12 1A             mov       word ptr [0x1a12], ax
0x0000000000003dbc:  F7 1E 12 1A          neg       word ptr [0x1a12]
0x0000000000003dc0:  E9 E5 FD             jmp       0x3ba8
0x0000000000003dc3:  30 C0                xor       al, al
0x0000000000003dc5:  E9 FD FE             jmp       0x3cc5
0x0000000000003dc8:  E8 57 F9             call      0x3722
0x0000000000003dcb:  E9 DA FD             jmp       0x3ba8
0x0000000000003dce:  30 C0                xor       al, al
0x0000000000003dd0:  E9 20 FE             jmp       0x3bf3
0x0000000000003dd3:  B8 DC 00             mov       ax, 0xdc
0x0000000000003dd6:  BB 24 07             mov       bx, 0x724
0x0000000000003dd9:  89 07                mov       word ptr [bx], ax
0x0000000000003ddb:  E9 CA FD             jmp       0x3ba8
0x0000000000003dde:  30 C0                xor       al, al
0x0000000000003de0:  E9 4B FE             jmp       0x3c2e
0x0000000000003de3:  B8 DE 00             mov       ax, 0xde
0x0000000000003de6:  BB 24 07             mov       bx, 0x724
0x0000000000003de9:  89 07                mov       word ptr [bx], ax
0x0000000000003deb:  E9 BA FD             jmp       0x3ba8
0x0000000000003dee:  8D 5E 96             lea       bx, [bp - 0x6a]
0x0000000000003df1:  B8 DF 00             mov       ax, 0xdf
0x0000000000003df4:  8C D9                mov       cx, ds
0x0000000000003df6:  8D 56 FA             lea       dx, [bp - 6]
0x0000000000003df9:  0E                   push      cs
0x0000000000003dfa:  3E E8 D8 E9          call      0x27d6
0x0000000000003dfe:  8D 5E 96             lea       bx, [bp - 0x6a]
0x0000000000003e01:  B8 00 05             mov       ax, 0x500
0x0000000000003e04:  1E                   push      ds
0x0000000000003e05:  8C D9                mov       cx, ds
0x0000000000003e07:  52                   push      dx
0x0000000000003e08:  31 D2                xor       dx, dx
0x0000000000003e0a:  C6 46 FA 00          mov       byte ptr [bp - 6], 0
0x0000000000003e0e:  E8 2A 30             call      0x6e3b
0x0000000000003e11:  E8 94 F9             call      0x37a8
0x0000000000003e14:  E9 91 FD             jmp       0x3ba8
0x0000000000003e17:  3C 01                cmp       al, 1
0x0000000000003e19:  74 03                je        0x3e1e
0x0000000000003e1b:  E9 35 FD             jmp       0x3b53
0x0000000000003e1e:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x0000000000003e22:  26 8B 44 03          mov       ax, word ptr es:[si + 3]
0x0000000000003e26:  26 8B 4C 01          mov       cx, word ptr es:[si + 1]
0x0000000000003e2a:  85 C0                test      ax, ax
0x0000000000003e2c:  75 2A                jne       0x3e58
0x0000000000003e2e:  81 F9 AC 00          cmp       cx, 0xac
0x0000000000003e32:  73 24                jae       0x3e58
0x0000000000003e34:  85 C0                test      ax, ax
0x0000000000003e36:  75 05                jne       0x3e3d
0x0000000000003e38:  83 F9 3D             cmp       cx, 0x3d
0x0000000000003e3b:  74 09                je        0x3e46
0x0000000000003e3d:  85 C0                test      ax, ax
0x0000000000003e3f:  75 DA                jne       0x3e1b
0x0000000000003e41:  83 F9 2D             cmp       cx, 0x2d
0x0000000000003e44:  75 D5                jne       0x3e1b
0x0000000000003e46:  B8 00 10             mov       ax, 0x1000
0x0000000000003e49:  A3 58 1A             mov       word ptr [0x1a58], ax
0x0000000000003e4c:  A3 54 1A             mov       word ptr [0x1a54], ax
0x0000000000003e4f:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000003e52:  C9                   leave     
0x0000000000003e53:  5F                   pop       di
0x0000000000003e54:  5E                   pop       si
0x0000000000003e55:  59                   pop       cx
0x0000000000003e56:  5B                   pop       bx
0x0000000000003e57:  C3                   ret       
0x0000000000003e58:  85 C0                test      ax, ax
0x0000000000003e5a:  75 1B                jne       0x3e77
0x0000000000003e5c:  81 F9 AC 00          cmp       cx, 0xac
0x0000000000003e60:  77 15                ja        0x3e77
0x0000000000003e62:  A0 34 0E             mov       al, byte ptr [0xe34]
0x0000000000003e65:  84 C0                test      al, al
0x0000000000003e67:  75 B2                jne       0x3e1b
0x0000000000003e69:  30 E4                xor       ah, ah
0x0000000000003e6b:  A3 10 1A             mov       word ptr [0x1a10], ax
0x0000000000003e6e:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000003e71:  C9                   leave     
0x0000000000003e72:  5F                   pop       di
0x0000000000003e73:  5E                   pop       si
0x0000000000003e74:  59                   pop       cx
0x0000000000003e75:  5B                   pop       bx
0x0000000000003e76:  C3                   ret       
0x0000000000003e77:  85 C0                test      ax, ax
0x0000000000003e79:  75 1B                jne       0x3e96
0x0000000000003e7b:  81 F9 AF 00          cmp       cx, 0xaf
0x0000000000003e7f:  75 15                jne       0x3e96
0x0000000000003e81:  A0 34 0E             mov       al, byte ptr [0xe34]
0x0000000000003e84:  84 C0                test      al, al
0x0000000000003e86:  75 93                jne       0x3e1b
0x0000000000003e88:  30 E4                xor       ah, ah
0x0000000000003e8a:  A3 12 1A             mov       word ptr [0x1a12], ax
0x0000000000003e8d:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000003e90:  C9                   leave     
0x0000000000003e91:  5F                   pop       di
0x0000000000003e92:  5E                   pop       si
0x0000000000003e93:  59                   pop       cx
0x0000000000003e94:  5B                   pop       bx
0x0000000000003e95:  C3                   ret       
0x0000000000003e96:  85 C0                test      ax, ax
0x0000000000003e98:  75 1E                jne       0x3eb8
0x0000000000003e9a:  81 F9 AE 00          cmp       cx, 0xae
0x0000000000003e9e:  75 18                jne       0x3eb8
0x0000000000003ea0:  A0 34 0E             mov       al, byte ptr [0xe34]
0x0000000000003ea3:  84 C0                test      al, al
0x0000000000003ea5:  74 03                je        0x3eaa
0x0000000000003ea7:  E9 A9 FC             jmp       0x3b53
0x0000000000003eaa:  30 E4                xor       ah, ah
0x0000000000003eac:  A3 10 1A             mov       word ptr [0x1a10], ax
0x0000000000003eaf:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000003eb2:  C9                   leave     
0x0000000000003eb3:  5F                   pop       di
0x0000000000003eb4:  5E                   pop       si
0x0000000000003eb5:  59                   pop       cx
0x0000000000003eb6:  5B                   pop       bx
0x0000000000003eb7:  C3                   ret       
0x0000000000003eb8:  85 C0                test      ax, ax
0x0000000000003eba:  75 EB                jne       0x3ea7
0x0000000000003ebc:  81 F9 AD 00          cmp       cx, 0xad
0x0000000000003ec0:  75 E5                jne       0x3ea7
0x0000000000003ec2:  A0 34 0E             mov       al, byte ptr [0xe34]
0x0000000000003ec5:  84 C0                test      al, al
0x0000000000003ec7:  75 DE                jne       0x3ea7
0x0000000000003ec9:  30 E4                xor       ah, ah
0x0000000000003ecb:  A3 12 1A             mov       word ptr [0x1a12], ax
0x0000000000003ece:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000003ed1:  C9                   leave     
0x0000000000003ed2:  5F                   pop       di
0x0000000000003ed3:  5E                   pop       si
0x0000000000003ed4:  59                   pop       cx
0x0000000000003ed5:  5B                   pop       bx
0x0000000000003ed6:  C3                   ret       
0x0000000000003ed7:  FC                   cld       

ENDP

PROC    AM_changeWindowScale_ NEAR
PUBLIC  AM_changeWindowScale_

0x0000000000003ed8:  53                   push      bx
0x0000000000003ed9:  51                   push      cx
0x0000000000003eda:  52                   push      dx
0x0000000000003edb:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x0000000000003edf:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x0000000000003ee3:  A1 58 1A             mov       ax, word ptr [0x1a58]
0x0000000000003ee6:  0E                   push      cs
0x0000000000003ee7:  E8 9F 1A             call      0x5989
0x0000000000003eea:  90                   nop       
0x0000000000003eeb:  B1 04                mov       cl, 4
0x0000000000003eed:  D3 E2                shl       dx, cl
0x0000000000003eef:  D3 C0                rol       ax, cl
0x0000000000003ef1:  31 C2                xor       dx, ax
0x0000000000003ef3:  81 E0 F0 FF          and       ax, 0xfff0
0x0000000000003ef7:  31 C2                xor       dx, ax
0x0000000000003ef9:  A3 04 1A             mov       word ptr [0x1a04], ax
0x0000000000003efc:  89 C3                mov       bx, ax
0x0000000000003efe:  89 D1                mov       cx, dx
0x0000000000003f00:  B8 01 00             mov       ax, 1
0x0000000000003f03:  89 16 06 1A          mov       word ptr [0x1a06], dx
0x0000000000003f07:  0E                   push      cs
0x0000000000003f08:  3E E8 A6 1D          call      0x5cb2
0x0000000000003f0c:  A3 08 1A             mov       word ptr [0x1a08], ax
0x0000000000003f0f:  89 16 0A 1A          mov       word ptr [0x1a0a], dx
0x0000000000003f13:  A1 36 1A             mov       ax, word ptr [0x1a36]
0x0000000000003f16:  83 3E 06 1A 00       cmp       word ptr [0x1a06], 0
0x0000000000003f1b:  7C 24                jl        0x3f41
0x0000000000003f1d:  75 06                jne       0x3f25
0x0000000000003f1f:  3B 06 04 1A          cmp       ax, word ptr [0x1a04]
0x0000000000003f23:  77 1C                ja        0x3f41
0x0000000000003f25:  A1 06 1A             mov       ax, word ptr [0x1a06]
0x0000000000003f28:  8B 16 04 1A          mov       dx, word ptr [0x1a04]
0x0000000000003f2c:  3B 06 02 1A          cmp       ax, word ptr [0x1a02]
0x0000000000003f30:  7F 08                jg        0x3f3a
0x0000000000003f32:  75 12                jne       0x3f46
0x0000000000003f34:  3B 16 00 1A          cmp       dx, word ptr [0x1a00]
0x0000000000003f38:  76 0C                jbe       0x3f46
0x0000000000003f3a:  E8 BB FB             call      0x3af8
0x0000000000003f3d:  5A                   pop       dx
0x0000000000003f3e:  59                   pop       cx
0x0000000000003f3f:  5B                   pop       bx
0x0000000000003f40:  C3                   ret       
0x0000000000003f41:  E8 8A FB             call      0x3ace
0x0000000000003f44:  EB F7                jmp       0x3f3d
0x0000000000003f46:  E8 73 F7             call      0x36bc
0x0000000000003f49:  5A                   pop       dx
0x0000000000003f4a:  59                   pop       cx
0x0000000000003f4b:  5B                   pop       bx
0x0000000000003f4c:  C3                   ret       


ENDP

PROC    AM_doFollowPlayer_ NEAR
PUBLIC  AM_doFollowPlayer_


0x0000000000003f4e:  53                   push      bx
0x0000000000003f4f:  52                   push      dx
0x0000000000003f50:  56                   push      si
0x0000000000003f51:  BB 30 06             mov       bx, 0x630
0x0000000000003f54:  C4 37                les       si, ptr [bx]
0x0000000000003f56:  A1 0C 1A             mov       ax, word ptr [0x1a0c]
0x0000000000003f59:  26 3B 44 02          cmp       ax, word ptr es:[si + 2]
0x0000000000003f5d:  75 0D                jne       0x3f6c
0x0000000000003f5f:  A1 0E 1A             mov       ax, word ptr [0x1a0e]
0x0000000000003f62:  26 3B 44 06          cmp       ax, word ptr es:[si + 6]
0x0000000000003f66:  75 04                jne       0x3f6c
0x0000000000003f68:  5E                   pop       si
0x0000000000003f69:  5A                   pop       dx
0x0000000000003f6a:  5B                   pop       bx
0x0000000000003f6b:  C3                   ret       
0x0000000000003f6c:  BB 30 06             mov       bx, 0x630
0x0000000000003f6f:  C4 37                les       si, ptr [bx]
0x0000000000003f71:  A1 4C 1A             mov       ax, word ptr [0x1a4c]
0x0000000000003f74:  26 8B 5C 02          mov       bx, word ptr es:[si + 2]
0x0000000000003f78:  D1 F8                sar       ax, 1
0x0000000000003f7a:  29 C3                sub       bx, ax
0x0000000000003f7c:  89 D8                mov       ax, bx
0x0000000000003f7e:  89 1E 4E 1A          mov       word ptr [0x1a4e], bx
0x0000000000003f82:  BB 30 06             mov       bx, 0x630
0x0000000000003f85:  C4 37                les       si, ptr [bx]
0x0000000000003f87:  8B 16 34 1A          mov       dx, word ptr [0x1a34]
0x0000000000003f8b:  26 8B 5C 06          mov       bx, word ptr es:[si + 6]
0x0000000000003f8f:  D1 FA                sar       dx, 1
0x0000000000003f91:  29 D3                sub       bx, dx
0x0000000000003f93:  89 1E 50 1A          mov       word ptr [0x1a50], bx
0x0000000000003f97:  03 1E 34 1A          add       bx, word ptr [0x1a34]
0x0000000000003f9b:  03 06 4C 1A          add       ax, word ptr [0x1a4c]
0x0000000000003f9f:  89 1E 46 1A          mov       word ptr [0x1a46], bx
0x0000000000003fa3:  BB 30 06             mov       bx, 0x630
0x0000000000003fa6:  A3 4A 1A             mov       word ptr [0x1a4a], ax
0x0000000000003fa9:  C4 37                les       si, ptr [bx]
0x0000000000003fab:  26 8B 44 02          mov       ax, word ptr es:[si + 2]
0x0000000000003faf:  A3 0C 1A             mov       word ptr [0x1a0c], ax
0x0000000000003fb2:  26 8B 44 06          mov       ax, word ptr es:[si + 6]
0x0000000000003fb6:  A3 0E 1A             mov       word ptr [0x1a0e], ax
0x0000000000003fb9:  5E                   pop       si
0x0000000000003fba:  5A                   pop       dx
0x0000000000003fbb:  5B                   pop       bx
0x0000000000003fbc:  C3                   ret       

ENDP

PROC    AM_Ticker_ NEAR
PUBLIC  AM_Ticker_

0x0000000000003fbe:  80 3E 34 0E 00       cmp       byte ptr [0xe34], 0
0x0000000000003fc3:  75 1A                jne       0x3fdf
0x0000000000003fc5:  81 3E 54 1A 00 10    cmp       word ptr [0x1a54], 0x1000
0x0000000000003fcb:  74 03                je        0x3fd0
0x0000000000003fcd:  E8 08 FF             call      0x3ed8
0x0000000000003fd0:  83 3E 10 1A 00       cmp       word ptr [0x1a10], 0
0x0000000000003fd5:  75 0D                jne       0x3fe4
0x0000000000003fd7:  83 3E 12 1A 00       cmp       word ptr [0x1a12], 0
0x0000000000003fdc:  75 06                jne       0x3fe4
0x0000000000003fde:  CB                   retf      
0x0000000000003fdf:  E8 6C FF             call      0x3f4e
0x0000000000003fe2:  EB E1                jmp       0x3fc5
0x0000000000003fe4:  E8 C5 F8             call      0x38ac
0x0000000000003fe7:  CB                   retf      

ENDP

PROC    DOOUTCODE_ NEAR
PUBLIC  DOOUTCODE_

0x0000000000003fe8:  31 C0                xor       ax, ax
0x0000000000003fea:  85 DB                test      bx, bx
0x0000000000003fec:  7C 16                jl        0x4004
0x0000000000003fee:  81 FB A8 00          cmp       bx, 0xa8
0x0000000000003ff2:  7C 03                jl        0x3ff7
0x0000000000003ff4:  B8 04 00             mov       ax, 4
0x0000000000003ff7:  85 D2                test      dx, dx
0x0000000000003ff9:  7C 0E                jl        0x4009
0x0000000000003ffb:  81 FA 40 01          cmp       dx, 0x140
0x0000000000003fff:  7C 02                jl        0x4003
0x0000000000004001:  0C 02                or        al, 2
0x0000000000004003:  C3                   ret       
0x0000000000004004:  B8 08 00             mov       ax, 8
0x0000000000004007:  EB EE                jmp       0x3ff7
0x0000000000004009:  0C 01                or        al, 1
0x000000000000400b:  C3                   ret       


ENDP

PROC    AM_clipMline_ NEAR
PUBLIC  AM_clipMline_


0x000000000000400c:  53                   push      bx
0x000000000000400d:  51                   push      cx
0x000000000000400e:  52                   push      dx
0x000000000000400f:  56                   push      si
0x0000000000004010:  57                   push      di
0x0000000000004011:  55                   push      bp
0x0000000000004012:  89 E5                mov       bp, sp
0x0000000000004014:  83 EC 06             sub       sp, 6
0x0000000000004017:  50                   push      ax
0x0000000000004018:  31 C0                xor       ax, ax
0x000000000000401a:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x000000000000401d:  89 46 FE             mov       word ptr [bp - 2], ax
0x0000000000004020:  89 46 FC             mov       word ptr [bp - 4], ax
0x0000000000004023:  8B 47 02             mov       ax, word ptr [bx + 2]
0x0000000000004026:  3B 06 46 1A          cmp       ax, word ptr [0x1a46]
0x000000000000402a:  7E 4E                jle       0x407a
0x000000000000402c:  C7 46 FE 08 00       mov       word ptr [bp - 2], 8
0x0000000000004031:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x0000000000004034:  8B 47 06             mov       ax, word ptr [bx + 6]
0x0000000000004037:  3B 06 46 1A          cmp       ax, word ptr [0x1a46]
0x000000000000403b:  7E 4A                jle       0x4087
0x000000000000403d:  C7 46 FC 08 00       mov       word ptr [bp - 4], 8
0x0000000000004042:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000004045:  85 46 FC             test      word ptr [bp - 4], ax
0x0000000000004048:  75 27                jne       0x4071
0x000000000000404a:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x000000000000404d:  8B 07                mov       ax, word ptr [bx]
0x000000000000404f:  3B 06 4E 1A          cmp       ax, word ptr [0x1a4e]
0x0000000000004053:  7D 3F                jge       0x4094
0x0000000000004055:  80 4E FE 01          or        byte ptr [bp - 2], 1
0x0000000000004059:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x000000000000405c:  8B 47 04             mov       ax, word ptr [bx + 4]
0x000000000000405f:  3B 06 4E 1A          cmp       ax, word ptr [0x1a4e]
0x0000000000004063:  7D 3B                jge       0x40a0
0x0000000000004065:  80 4E FC 01          or        byte ptr [bp - 4], 1
0x0000000000004069:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x000000000000406c:  85 46 FC             test      word ptr [bp - 4], ax
0x000000000000406f:  74 3B                je        0x40ac
0x0000000000004071:  30 C0                xor       al, al
0x0000000000004073:  C9                   leave     
0x0000000000004074:  5F                   pop       di
0x0000000000004075:  5E                   pop       si
0x0000000000004076:  5A                   pop       dx
0x0000000000004077:  59                   pop       cx
0x0000000000004078:  5B                   pop       bx
0x0000000000004079:  C3                   ret       
0x000000000000407a:  3B 06 50 1A          cmp       ax, word ptr [0x1a50]
0x000000000000407e:  7D B1                jge       0x4031
0x0000000000004080:  C7 46 FE 04 00       mov       word ptr [bp - 2], 4
0x0000000000004085:  EB AA                jmp       0x4031
0x0000000000004087:  3B 06 50 1A          cmp       ax, word ptr [0x1a50]
0x000000000000408b:  7D B5                jge       0x4042
0x000000000000408d:  C7 46 FC 04 00       mov       word ptr [bp - 4], 4
0x0000000000004092:  EB AE                jmp       0x4042
0x0000000000004094:  3B 06 4A 1A          cmp       ax, word ptr [0x1a4a]
0x0000000000004098:  7E BF                jle       0x4059
0x000000000000409a:  80 4E FE 02          or        byte ptr [bp - 2], 2
0x000000000000409e:  EB B9                jmp       0x4059
0x00000000000040a0:  3B 06 4A 1A          cmp       ax, word ptr [0x1a4a]
0x00000000000040a4:  7E C3                jle       0x4069
0x00000000000040a6:  80 4E FC 02          or        byte ptr [bp - 4], 2
0x00000000000040aa:  EB BD                jmp       0x4069
0x00000000000040ac:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x00000000000040af:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x00000000000040b3:  8B 07                mov       ax, word ptr [bx]
0x00000000000040b5:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x00000000000040b9:  2B 06 4E 1A          sub       ax, word ptr [0x1a4e]
0x00000000000040bd:  0E                   push      cs
0x00000000000040be:  3E E8 C7 18          call      0x5989
0x00000000000040c2:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x00000000000040c5:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x00000000000040c9:  A3 A8 19             mov       word ptr [0x19a8], ax
0x00000000000040cc:  8B 47 02             mov       ax, word ptr [bx + 2]
0x00000000000040cf:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x00000000000040d3:  2B 06 50 1A          sub       ax, word ptr [0x1a50]
0x00000000000040d7:  0E                   push      cs
0x00000000000040d8:  3E E8 AD 18          call      0x5989
0x00000000000040dc:  BA A8 00             mov       dx, 0xa8
0x00000000000040df:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x00000000000040e2:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x00000000000040e6:  29 C2                sub       dx, ax
0x00000000000040e8:  8B 47 04             mov       ax, word ptr [bx + 4]
0x00000000000040eb:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x00000000000040ef:  2B 06 4E 1A          sub       ax, word ptr [0x1a4e]
0x00000000000040f3:  89 16 AA 19          mov       word ptr [0x19aa], dx
0x00000000000040f7:  0E                   push      cs
0x00000000000040f8:  3E E8 8D 18          call      0x5989
0x00000000000040fc:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x00000000000040ff:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x0000000000004103:  A3 AC 19             mov       word ptr [0x19ac], ax
0x0000000000004106:  8B 47 06             mov       ax, word ptr [bx + 6]
0x0000000000004109:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x000000000000410d:  2B 06 50 1A          sub       ax, word ptr [0x1a50]
0x0000000000004111:  0E                   push      cs
0x0000000000004112:  3E E8 73 18          call      0x5989
0x0000000000004116:  BA A8 00             mov       dx, 0xa8
0x0000000000004119:  8B 1E AA 19          mov       bx, word ptr [0x19aa]
0x000000000000411d:  29 C2                sub       dx, ax
0x000000000000411f:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000004122:  89 16 AE 19          mov       word ptr [0x19ae], dx
0x0000000000004126:  8B 16 A8 19          mov       dx, word ptr [0x19a8]
0x000000000000412a:  E8 BB FE             call      0x3fe8
0x000000000000412d:  8B 1E AE 19          mov       bx, word ptr [0x19ae]
0x0000000000004131:  8B 16 AC 19          mov       dx, word ptr [0x19ac]
0x0000000000004135:  89 C1                mov       cx, ax
0x0000000000004137:  89 46 FE             mov       word ptr [bp - 2], ax
0x000000000000413a:  8B 46 FC             mov       ax, word ptr [bp - 4]
0x000000000000413d:  E8 A8 FE             call      0x3fe8
0x0000000000004140:  89 46 FC             mov       word ptr [bp - 4], ax
0x0000000000004143:  85 C1                test      cx, ax
0x0000000000004145:  74 03                je        0x414a
0x0000000000004147:  E9 27 FF             jmp       0x4071
0x000000000000414a:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x000000000000414d:  0B 46 FC             or        ax, word ptr [bp - 4]
0x0000000000004150:  74 63                je        0x41b5
0x0000000000004152:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000004155:  85 C0                test      ax, ax
0x0000000000004157:  74 57                je        0x41b0
0x0000000000004159:  89 C1                mov       cx, ax
0x000000000000415b:  A1 AA 19             mov       ax, word ptr [0x19aa]
0x000000000000415e:  8B 1E AC 19          mov       bx, word ptr [0x19ac]
0x0000000000004162:  89 46 FA             mov       word ptr [bp - 6], ax
0x0000000000004165:  A1 AE 19             mov       ax, word ptr [0x19ae]
0x0000000000004168:  2B 1E A8 19          sub       bx, word ptr [0x19a8]
0x000000000000416c:  29 46 FA             sub       word ptr [bp - 6], ax
0x000000000000416f:  F6 C1 08             test      cl, 8
0x0000000000004172:  74 44                je        0x41b8
0x0000000000004174:  89 D8                mov       ax, bx
0x0000000000004176:  F7 2E AA 19          imul      word ptr [0x19aa]
0x000000000000417a:  99                   cdq       
0x000000000000417b:  F7 7E FA             idiv      word ptr [bp - 6]
0x000000000000417e:  8B 3E A8 19          mov       di, word ptr [0x19a8]
0x0000000000004182:  31 F6                xor       si, si
0x0000000000004184:  01 C7                add       di, ax
0x0000000000004186:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000004189:  39 C1                cmp       cx, ax
0x000000000000418b:  75 69                jne       0x41f6
0x000000000000418d:  89 3E A8 19          mov       word ptr [0x19a8], di
0x0000000000004191:  89 F3                mov       bx, si
0x0000000000004193:  89 FA                mov       dx, di
0x0000000000004195:  89 36 AA 19          mov       word ptr [0x19aa], si
0x0000000000004199:  E8 4C FE             call      0x3fe8
0x000000000000419c:  89 46 FE             mov       word ptr [bp - 2], ax
0x000000000000419f:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x00000000000041a2:  85 46 FC             test      word ptr [bp - 4], ax
0x00000000000041a5:  74 A3                je        0x414a
0x00000000000041a7:  30 C0                xor       al, al
0x00000000000041a9:  C9                   leave     
0x00000000000041aa:  5F                   pop       di
0x00000000000041ab:  5E                   pop       si
0x00000000000041ac:  5A                   pop       dx
0x00000000000041ad:  59                   pop       cx
0x00000000000041ae:  5B                   pop       bx
0x00000000000041af:  C3                   ret       
0x00000000000041b0:  8B 4E FC             mov       cx, word ptr [bp - 4]
0x00000000000041b3:  EB A6                jmp       0x415b
0x00000000000041b5:  E9 73 00             jmp       0x422b
0x00000000000041b8:  F6 C1 04             test      cl, 4
0x00000000000041bb:  74 19                je        0x41d6
0x00000000000041bd:  8B 16 AA 19          mov       dx, word ptr [0x19aa]
0x00000000000041c1:  89 D8                mov       ax, bx
0x00000000000041c3:  81 EA A8 00          sub       dx, 0xa8
0x00000000000041c7:  F7 EA                imul      dx
0x00000000000041c9:  99                   cdq       
0x00000000000041ca:  F7 7E FA             idiv      word ptr [bp - 6]
0x00000000000041cd:  8B 3E A8 19          mov       di, word ptr [0x19a8]
0x00000000000041d1:  BE A7 00             mov       si, 0xa7
0x00000000000041d4:  EB AE                jmp       0x4184
0x00000000000041d6:  2B 06 AA 19          sub       ax, word ptr [0x19aa]
0x00000000000041da:  F6 C1 02             test      cl, 2
0x00000000000041dd:  74 19                je        0x41f8
0x00000000000041df:  BA 3F 01             mov       dx, 0x13f
0x00000000000041e2:  2B 16 A8 19          sub       dx, word ptr [0x19a8]
0x00000000000041e6:  F7 EA                imul      dx
0x00000000000041e8:  99                   cdq       
0x00000000000041e9:  F7 FB                idiv      bx
0x00000000000041eb:  8B 36 AA 19          mov       si, word ptr [0x19aa]
0x00000000000041ef:  BF 3F 01             mov       di, 0x13f
0x00000000000041f2:  01 C6                add       si, ax
0x00000000000041f4:  EB 90                jmp       0x4186
0x00000000000041f6:  EB 1B                jmp       0x4213
0x00000000000041f8:  F6 C1 01             test      cl, 1
0x00000000000041fb:  74 89                je        0x4186
0x00000000000041fd:  8B 16 A8 19          mov       dx, word ptr [0x19a8]
0x0000000000004201:  F7 DA                neg       dx
0x0000000000004203:  F7 EA                imul      dx
0x0000000000004205:  99                   cdq       
0x0000000000004206:  F7 FB                idiv      bx
0x0000000000004208:  8B 36 AA 19          mov       si, word ptr [0x19aa]
0x000000000000420c:  31 FF                xor       di, di
0x000000000000420e:  01 C6                add       si, ax
0x0000000000004210:  E9 73 FF             jmp       0x4186
0x0000000000004213:  8B 46 FC             mov       ax, word ptr [bp - 4]
0x0000000000004216:  89 3E AC 19          mov       word ptr [0x19ac], di
0x000000000000421a:  89 F3                mov       bx, si
0x000000000000421c:  89 FA                mov       dx, di
0x000000000000421e:  89 36 AE 19          mov       word ptr [0x19ae], si
0x0000000000004222:  E8 C3 FD             call      0x3fe8
0x0000000000004225:  89 46 FC             mov       word ptr [bp - 4], ax
0x0000000000004228:  E9 74 FF             jmp       0x419f
0x000000000000422b:  B0 01                mov       al, 1
0x000000000000422d:  C9                   leave     
0x000000000000422e:  5F                   pop       di
0x000000000000422f:  5E                   pop       si
0x0000000000004230:  5A                   pop       dx
0x0000000000004231:  59                   pop       cx
0x0000000000004232:  5B                   pop       bx
0x0000000000004233:  C3                   ret       


ENDP

PROC    AM_drawMline_ NEAR
PUBLIC  AM_drawMline_

0x0000000000004234:  53                   push      bx
0x0000000000004235:  51                   push      cx
0x0000000000004236:  56                   push      si
0x0000000000004237:  57                   push      di
0x0000000000004238:  55                   push      bp
0x0000000000004239:  89 E5                mov       bp, sp
0x000000000000423b:  83 EC 08             sub       sp, 8
0x000000000000423e:  88 56 FE             mov       byte ptr [bp - 2], dl
0x0000000000004241:  E8 C8 FD             call      0x400c
0x0000000000004244:  84 C0                test      al, al
0x0000000000004246:  75 03                jne       0x424b
0x0000000000004248:  E9 0B F9             jmp       0x3b56
0x000000000000424b:  A1 AC 19             mov       ax, word ptr [0x19ac]
0x000000000000424e:  2B 06 A8 19          sub       ax, word ptr [0x19a8]
0x0000000000004252:  89 C2                mov       dx, ax
0x0000000000004254:  85 C0                test      ax, ax
0x0000000000004256:  7C 69                jl        0x42c1
0x0000000000004258:  89 C7                mov       di, ax
0x000000000000425a:  01 C7                add       di, ax
0x000000000000425c:  85 D2                test      dx, dx
0x000000000000425e:  7C 65                jl        0x42c5
0x0000000000004260:  B8 01 00             mov       ax, 1
0x0000000000004263:  89 46 F8             mov       word ptr [bp - 8], ax
0x0000000000004266:  A1 AE 19             mov       ax, word ptr [0x19ae]
0x0000000000004269:  2B 06 AA 19          sub       ax, word ptr [0x19aa]
0x000000000000426d:  89 C2                mov       dx, ax
0x000000000000426f:  85 C0                test      ax, ax
0x0000000000004271:  7C 57                jl        0x42ca
0x0000000000004273:  01 C0                add       ax, ax
0x0000000000004275:  89 46 FC             mov       word ptr [bp - 4], ax
0x0000000000004278:  85 D2                test      dx, dx
0x000000000000427a:  7C 52                jl        0x42ce
0x000000000000427c:  B8 01 00             mov       ax, 1
0x000000000000427f:  8B 16 A8 19          mov       dx, word ptr [0x19a8]
0x0000000000004283:  89 46 FA             mov       word ptr [bp - 6], ax
0x0000000000004286:  A1 AA 19             mov       ax, word ptr [0x19aa]
0x0000000000004289:  3B 7E FC             cmp       di, word ptr [bp - 4]
0x000000000000428c:  7E 45                jle       0x42d3
0x000000000000428e:  89 FB                mov       bx, di
0x0000000000004290:  8B 76 FC             mov       si, word ptr [bp - 4]
0x0000000000004293:  D1 FB                sar       bx, 1
0x0000000000004295:  29 DE                sub       si, bx
0x0000000000004297:  89 F3                mov       bx, si
0x0000000000004299:  69 F0 40 01          imul      si, ax, 0x140
0x000000000000429d:  B9 00 80             mov       cx, 0x8000
0x00000000000042a0:  8E C1                mov       es, cx
0x00000000000042a2:  01 D6                add       si, dx
0x00000000000042a4:  8A 4E FE             mov       cl, byte ptr [bp - 2]
0x00000000000042a7:  26 88 0C             mov       byte ptr es:[si], cl
0x00000000000042aa:  3B 16 AC 19          cmp       dx, word ptr [0x19ac]
0x00000000000042ae:  74 98                je        0x4248
0x00000000000042b0:  85 DB                test      bx, bx
0x00000000000042b2:  7C 05                jl        0x42b9
0x00000000000042b4:  03 46 FA             add       ax, word ptr [bp - 6]
0x00000000000042b7:  29 FB                sub       bx, di
0x00000000000042b9:  03 56 F8             add       dx, word ptr [bp - 8]
0x00000000000042bc:  03 5E FC             add       bx, word ptr [bp - 4]
0x00000000000042bf:  EB D8                jmp       0x4299
0x00000000000042c1:  F7 D8                neg       ax
0x00000000000042c3:  EB 93                jmp       0x4258
0x00000000000042c5:  B8 FF FF             mov       ax, 0xffff
0x00000000000042c8:  EB 99                jmp       0x4263
0x00000000000042ca:  F7 D8                neg       ax
0x00000000000042cc:  EB A5                jmp       0x4273
0x00000000000042ce:  B8 FF FF             mov       ax, 0xffff
0x00000000000042d1:  EB AC                jmp       0x427f
0x00000000000042d3:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x00000000000042d6:  89 FE                mov       si, di
0x00000000000042d8:  D1 FB                sar       bx, 1
0x00000000000042da:  29 DE                sub       si, bx
0x00000000000042dc:  89 F3                mov       bx, si
0x00000000000042de:  69 F0 40 01          imul      si, ax, 0x140
0x00000000000042e2:  B9 00 80             mov       cx, 0x8000
0x00000000000042e5:  8E C1                mov       es, cx
0x00000000000042e7:  01 D6                add       si, dx
0x00000000000042e9:  8A 4E FE             mov       cl, byte ptr [bp - 2]
0x00000000000042ec:  26 88 0C             mov       byte ptr es:[si], cl
0x00000000000042ef:  3B 06 AE 19          cmp       ax, word ptr [0x19ae]
0x00000000000042f3:  75 03                jne       0x42f8
0x00000000000042f5:  E9 5E F8             jmp       0x3b56
0x00000000000042f8:  85 DB                test      bx, bx
0x00000000000042fa:  7C 06                jl        0x4302
0x00000000000042fc:  03 56 F8             add       dx, word ptr [bp - 8]
0x00000000000042ff:  2B 5E FC             sub       bx, word ptr [bp - 4]
0x0000000000004302:  03 46 FA             add       ax, word ptr [bp - 6]
0x0000000000004305:  01 FB                add       bx, di
0x0000000000004307:  EB D5                jmp       0x42de


ENDP

PROC    AM_drawGrid_ NEAR
PUBLIC  AM_drawGrid_

0x000000000000430a:  53                   push      bx
0x000000000000430b:  51                   push      cx
0x000000000000430c:  52                   push      dx
0x000000000000430d:  A1 4E 1A             mov       ax, word ptr [0x1a4e]
0x0000000000004310:  BB E0 04             mov       bx, 0x4e0
0x0000000000004313:  89 C1                mov       cx, ax
0x0000000000004315:  89 C2                mov       dx, ax
0x0000000000004317:  2B 0F                sub       cx, word ptr [bx]
0x0000000000004319:  2B 17                sub       dx, word ptr [bx]
0x000000000000431b:  C1 F9 0F             sar       cx, 0xf
0x000000000000431e:  31 D1                xor       cx, dx
0x0000000000004320:  89 C2                mov       dx, ax
0x0000000000004322:  2B 17                sub       dx, word ptr [bx]
0x0000000000004324:  89 D3                mov       bx, dx
0x0000000000004326:  C1 FB 0F             sar       bx, 0xf
0x0000000000004329:  29 D9                sub       cx, bx
0x000000000000432b:  BB E0 04             mov       bx, 0x4e0
0x000000000000432e:  89 C2                mov       dx, ax
0x0000000000004330:  2B 17                sub       dx, word ptr [bx]
0x0000000000004332:  30 ED                xor       ch, ch
0x0000000000004334:  89 D3                mov       bx, dx
0x0000000000004336:  80 E1 7F             and       cl, 0x7f
0x0000000000004339:  C1 FB 0F             sar       bx, 0xf
0x000000000000433c:  31 D9                xor       cx, bx
0x000000000000433e:  BB E0 04             mov       bx, 0x4e0
0x0000000000004341:  89 C2                mov       dx, ax
0x0000000000004343:  2B 17                sub       dx, word ptr [bx]
0x0000000000004345:  89 D3                mov       bx, dx
0x0000000000004347:  C1 FB 0F             sar       bx, 0xf
0x000000000000434a:  29 D9                sub       cx, bx
0x000000000000434c:  74 43                je        0x4391
0x000000000000434e:  BB E0 04             mov       bx, 0x4e0
0x0000000000004351:  89 C1                mov       cx, ax
0x0000000000004353:  89 C2                mov       dx, ax
0x0000000000004355:  2B 0F                sub       cx, word ptr [bx]
0x0000000000004357:  2B 17                sub       dx, word ptr [bx]
0x0000000000004359:  C1 F9 0F             sar       cx, 0xf
0x000000000000435c:  31 D1                xor       cx, dx
0x000000000000435e:  89 C2                mov       dx, ax
0x0000000000004360:  2B 17                sub       dx, word ptr [bx]
0x0000000000004362:  89 D3                mov       bx, dx
0x0000000000004364:  C1 FB 0F             sar       bx, 0xf
0x0000000000004367:  29 D9                sub       cx, bx
0x0000000000004369:  BB E0 04             mov       bx, 0x4e0
0x000000000000436c:  89 C2                mov       dx, ax
0x000000000000436e:  2B 17                sub       dx, word ptr [bx]
0x0000000000004370:  30 ED                xor       ch, ch
0x0000000000004372:  89 D3                mov       bx, dx
0x0000000000004374:  80 E1 7F             and       cl, 0x7f
0x0000000000004377:  C1 FB 0F             sar       bx, 0xf
0x000000000000437a:  31 D9                xor       cx, bx
0x000000000000437c:  BB E0 04             mov       bx, 0x4e0
0x000000000000437f:  89 C2                mov       dx, ax
0x0000000000004381:  2B 17                sub       dx, word ptr [bx]
0x0000000000004383:  89 D3                mov       bx, dx
0x0000000000004385:  C1 FB 0F             sar       bx, 0xf
0x0000000000004388:  29 D9                sub       cx, bx
0x000000000000438a:  BB 80 00             mov       bx, 0x80
0x000000000000438d:  29 CB                sub       bx, cx
0x000000000000438f:  01 D8                add       ax, bx
0x0000000000004391:  8B 1E 50 1A          mov       bx, word ptr [0x1a50]
0x0000000000004395:  8B 0E 4E 1A          mov       cx, word ptr [0x1a4e]
0x0000000000004399:  89 1E BA 19          mov       word ptr [0x19ba], bx
0x000000000000439d:  03 1E 34 1A          add       bx, word ptr [0x1a34]
0x00000000000043a1:  03 0E 4C 1A          add       cx, word ptr [0x1a4c]
0x00000000000043a5:  89 1E BE 19          mov       word ptr [0x19be], bx
0x00000000000043a9:  89 C3                mov       bx, ax
0x00000000000043ab:  39 C8                cmp       ax, cx
0x00000000000043ad:  7D 19                jge       0x43c8
0x00000000000043af:  BA 68 00             mov       dx, 0x68
0x00000000000043b2:  B8 B8 19             mov       ax, 0x19b8
0x00000000000043b5:  89 1E B8 19          mov       word ptr [0x19b8], bx
0x00000000000043b9:  89 1E BC 19          mov       word ptr [0x19bc], bx
0x00000000000043bd:  81 C3 80 00          add       bx, 0x80
0x00000000000043c1:  E8 70 FE             call      0x4234
0x00000000000043c4:  39 CB                cmp       bx, cx
0x00000000000043c6:  7C E7                jl        0x43af
0x00000000000043c8:  A1 50 1A             mov       ax, word ptr [0x1a50]
0x00000000000043cb:  BB E2 04             mov       bx, 0x4e2
0x00000000000043ce:  89 C1                mov       cx, ax
0x00000000000043d0:  89 C2                mov       dx, ax
0x00000000000043d2:  2B 0F                sub       cx, word ptr [bx]
0x00000000000043d4:  2B 17                sub       dx, word ptr [bx]
0x00000000000043d6:  C1 F9 0F             sar       cx, 0xf
0x00000000000043d9:  31 D1                xor       cx, dx
0x00000000000043db:  89 C2                mov       dx, ax
0x00000000000043dd:  2B 17                sub       dx, word ptr [bx]
0x00000000000043df:  89 D3                mov       bx, dx
0x00000000000043e1:  C1 FB 0F             sar       bx, 0xf
0x00000000000043e4:  29 D9                sub       cx, bx
0x00000000000043e6:  BB E2 04             mov       bx, 0x4e2
0x00000000000043e9:  89 C2                mov       dx, ax
0x00000000000043eb:  2B 17                sub       dx, word ptr [bx]
0x00000000000043ed:  30 ED                xor       ch, ch
0x00000000000043ef:  89 D3                mov       bx, dx
0x00000000000043f1:  80 E1 7F             and       cl, 0x7f
0x00000000000043f4:  C1 FB 0F             sar       bx, 0xf
0x00000000000043f7:  31 D9                xor       cx, bx
0x00000000000043f9:  BB E2 04             mov       bx, 0x4e2
0x00000000000043fc:  89 C2                mov       dx, ax
0x00000000000043fe:  2B 17                sub       dx, word ptr [bx]
0x0000000000004400:  89 D3                mov       bx, dx
0x0000000000004402:  C1 FB 0F             sar       bx, 0xf
0x0000000000004405:  29 D9                sub       cx, bx
0x0000000000004407:  74 43                je        0x444c
0x0000000000004409:  BB E2 04             mov       bx, 0x4e2
0x000000000000440c:  89 C1                mov       cx, ax
0x000000000000440e:  89 C2                mov       dx, ax
0x0000000000004410:  2B 0F                sub       cx, word ptr [bx]
0x0000000000004412:  2B 17                sub       dx, word ptr [bx]
0x0000000000004414:  C1 F9 0F             sar       cx, 0xf
0x0000000000004417:  31 D1                xor       cx, dx
0x0000000000004419:  89 C2                mov       dx, ax
0x000000000000441b:  2B 17                sub       dx, word ptr [bx]
0x000000000000441d:  89 D3                mov       bx, dx
0x000000000000441f:  C1 FB 0F             sar       bx, 0xf
0x0000000000004422:  29 D9                sub       cx, bx
0x0000000000004424:  BB E2 04             mov       bx, 0x4e2
0x0000000000004427:  89 C2                mov       dx, ax
0x0000000000004429:  2B 17                sub       dx, word ptr [bx]
0x000000000000442b:  30 ED                xor       ch, ch
0x000000000000442d:  89 D3                mov       bx, dx
0x000000000000442f:  80 E1 7F             and       cl, 0x7f
0x0000000000004432:  C1 FB 0F             sar       bx, 0xf
0x0000000000004435:  31 D9                xor       cx, bx
0x0000000000004437:  BB E2 04             mov       bx, 0x4e2
0x000000000000443a:  89 C2                mov       dx, ax
0x000000000000443c:  2B 17                sub       dx, word ptr [bx]
0x000000000000443e:  89 D3                mov       bx, dx
0x0000000000004440:  C1 FB 0F             sar       bx, 0xf
0x0000000000004443:  BA 80 00             mov       dx, 0x80
0x0000000000004446:  29 D9                sub       cx, bx
0x0000000000004448:  29 CA                sub       dx, cx
0x000000000000444a:  01 D0                add       ax, dx
0x000000000000444c:  8B 1E 4E 1A          mov       bx, word ptr [0x1a4e]
0x0000000000004450:  8B 0E 50 1A          mov       cx, word ptr [0x1a50]
0x0000000000004454:  89 1E B8 19          mov       word ptr [0x19b8], bx
0x0000000000004458:  03 1E 4C 1A          add       bx, word ptr [0x1a4c]
0x000000000000445c:  03 0E 34 1A          add       cx, word ptr [0x1a34]
0x0000000000004460:  89 1E BC 19          mov       word ptr [0x19bc], bx
0x0000000000004464:  89 C3                mov       bx, ax
0x0000000000004466:  39 C8                cmp       ax, cx
0x0000000000004468:  7D 19                jge       0x4483
0x000000000000446a:  BA 68 00             mov       dx, 0x68
0x000000000000446d:  B8 B8 19             mov       ax, 0x19b8
0x0000000000004470:  89 1E BA 19          mov       word ptr [0x19ba], bx
0x0000000000004474:  89 1E BE 19          mov       word ptr [0x19be], bx
0x0000000000004478:  81 C3 80 00          add       bx, 0x80
0x000000000000447c:  E8 B5 FD             call      0x4234
0x000000000000447f:  39 CB                cmp       bx, cx
0x0000000000004481:  7C E7                jl        0x446a
0x0000000000004483:  5A                   pop       dx
0x0000000000004484:  59                   pop       cx
0x0000000000004485:  5B                   pop       bx
0x0000000000004486:  C3                   ret       


ENDP

PROC    AM_drawWalls_ NEAR
PUBLIC  AM_drawWalls_

0x0000000000004488:  53                   push      bx
0x0000000000004489:  51                   push      cx
0x000000000000448a:  52                   push      dx
0x000000000000448b:  56                   push      si
0x000000000000448c:  57                   push      di
0x000000000000448d:  55                   push      bp
0x000000000000448e:  89 E5                mov       bp, sp
0x0000000000004490:  83 EC 0E             sub       sp, 0xe
0x0000000000004493:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004498:  31 DB                xor       bx, bx
0x000000000000449a:  BE D0 04             mov       si, 0x4d0
0x000000000000449d:  8B 46 FC             mov       ax, word ptr [bp - 4]
0x00000000000044a0:  3B 04                cmp       ax, word ptr [si]
0x00000000000044a2:  72 03                jb        0x44a7
0x00000000000044a4:  E9 CC FB             jmp       0x4073
0x00000000000044a7:  B8 00 70             mov       ax, 0x7000
0x00000000000044aa:  89 DE                mov       si, bx
0x00000000000044ac:  8E C0                mov       es, ax
0x00000000000044ae:  8A 4E FC             mov       cl, byte ptr [bp - 4]
0x00000000000044b1:  26 8B 04             mov       ax, word ptr es:[si]
0x00000000000044b4:  80 E1 07             and       cl, 7
0x00000000000044b7:  89 46 F2             mov       word ptr [bp - 0xe], ax
0x00000000000044ba:  8D 77 02             lea       si, [bx + 2]
0x00000000000044bd:  B8 E1 6F             mov       ax, 0x6fe1
0x00000000000044c0:  26 8B 3C             mov       di, word ptr es:[si]
0x00000000000044c3:  8B 76 FC             mov       si, word ptr [bp - 4]
0x00000000000044c6:  8E C0                mov       es, ax
0x00000000000044c8:  B0 01                mov       al, 1
0x00000000000044ca:  C1 EE 03             shr       si, 3
0x00000000000044cd:  D2 E0                shl       al, cl
0x00000000000044cf:  26 8A 24             mov       ah, byte ptr es:[si]
0x00000000000044d2:  20 C4                and       ah, al
0x00000000000044d4:  88 66 FE             mov       byte ptr [bp - 2], ah
0x00000000000044d7:  B8 99 2B             mov       ax, 0x2b99
0x00000000000044da:  8B 76 FC             mov       si, word ptr [bp - 4]
0x00000000000044dd:  8E C0                mov       es, ax
0x00000000000044df:  BA 00 70             mov       dx, 0x7000
0x00000000000044e2:  26 8A 04             mov       al, byte ptr es:[si]
0x00000000000044e5:  8E C2                mov       es, dx
0x00000000000044e7:  8D 77 0C             lea       si, [bx + 0xc]
0x00000000000044ea:  26 8B 14             mov       dx, word ptr es:[si]
0x00000000000044ed:  8D 77 0A             lea       si, [bx + 0xa]
0x00000000000044f0:  30 E4                xor       ah, ah
0x00000000000044f2:  26 8B 0C             mov       cx, word ptr es:[si]
0x00000000000044f5:  8D 77 0F             lea       si, [bx + 0xf]
0x00000000000044f8:  89 4E F8             mov       word ptr [bp - 8], cx
0x00000000000044fb:  26 8A 0C             mov       cl, byte ptr es:[si]
0x00000000000044fe:  88 66 F5             mov       byte ptr [bp - 0xb], ah
0x0000000000004501:  88 4E F4             mov       byte ptr [bp - 0xc], cl
0x0000000000004504:  8B 4E F4             mov       cx, word ptr [bp - 0xc]
0x0000000000004507:  89 4E F6             mov       word ptr [bp - 0xa], cx
0x000000000000450a:  8B 4E F2             mov       cx, word ptr [bp - 0xe]
0x000000000000450d:  BE 3B 23             mov       si, 0x233b
0x0000000000004510:  C1 E1 02             shl       cx, 2
0x0000000000004513:  8E C6                mov       es, si
0x0000000000004515:  89 CE                mov       si, cx
0x0000000000004517:  26 8B 34             mov       si, word ptr es:[si]
0x000000000000451a:  89 36 A0 19          mov       word ptr [0x19a0], si
0x000000000000451e:  89 CE                mov       si, cx
0x0000000000004520:  26 8B 4C 02          mov       cx, word ptr es:[si + 2]
0x0000000000004524:  81 E7 FF 3F          and       di, 0x3fff
0x0000000000004528:  89 0E A2 19          mov       word ptr [0x19a2], cx
0x000000000000452c:  89 F9                mov       cx, di
0x000000000000452e:  83 C6 02             add       si, 2
0x0000000000004531:  C1 E1 02             shl       cx, 2
0x0000000000004534:  89 CE                mov       si, cx
0x0000000000004536:  26 8B 34             mov       si, word ptr es:[si]
0x0000000000004539:  89 36 A4 19          mov       word ptr [0x19a4], si
0x000000000000453d:  89 CE                mov       si, cx
0x000000000000453f:  89 46 FA             mov       word ptr [bp - 6], ax
0x0000000000004542:  26 8B 4C 02          mov       cx, word ptr es:[si + 2]
0x0000000000004546:  83 C6 02             add       si, 2
0x0000000000004549:  89 0E A6 19          mov       word ptr [0x19a6], cx
0x000000000000454d:  80 3E 31 0E 00       cmp       byte ptr [0xe31], 0
0x0000000000004552:  74 16                je        0x456a
0x0000000000004554:  F6 46 FA 80          test      byte ptr [bp - 6], 0x80
0x0000000000004558:  74 2D                je        0x4587
0x000000000000455a:  80 3E 31 0E 00       cmp       byte ptr [0xe31], 0
0x000000000000455f:  75 26                jne       0x4587
0x0000000000004561:  FF 46 FC             inc       word ptr [bp - 4]
0x0000000000004564:  83 C3 10             add       bx, 0x10
0x0000000000004567:  E9 30 FF             jmp       0x449a
0x000000000000456a:  80 7E FE 00          cmp       byte ptr [bp - 2], 0
0x000000000000456e:  75 E4                jne       0x4554
0x0000000000004570:  BE F6 06             mov       si, 0x6f6
0x0000000000004573:  83 3C 00             cmp       word ptr [si], 0
0x0000000000004576:  74 E9                je        0x4561
0x0000000000004578:  A8 80                test      al, 0x80
0x000000000000457a:  75 E5                jne       0x4561
0x000000000000457c:  BA 63 00             mov       dx, 0x63
0x000000000000457f:  B8 A0 19             mov       ax, 0x19a0
0x0000000000004582:  E8 AF FC             call      0x4234
0x0000000000004585:  EB DA                jmp       0x4561
0x0000000000004587:  83 FA FF             cmp       dx, -1
0x000000000000458a:  74 4E                je        0x45da
0x000000000000458c:  B8 DF 21             mov       ax, 0x21df
0x000000000000458f:  89 D7                mov       di, dx
0x0000000000004591:  8B 76 F8             mov       si, word ptr [bp - 8]
0x0000000000004594:  C1 E7 04             shl       di, 4
0x0000000000004597:  8E C0                mov       es, ax
0x0000000000004599:  C1 E6 04             shl       si, 4
0x000000000000459c:  26 8B 05             mov       ax, word ptr es:[di]
0x000000000000459f:  26 3B 04             cmp       ax, word ptr es:[si]
0x00000000000045a2:  74 48                je        0x45ec
0x00000000000045a4:  B0 01                mov       al, 1
0x00000000000045a6:  8B 7E F8             mov       di, word ptr [bp - 8]
0x00000000000045a9:  88 C1                mov       cl, al
0x00000000000045ab:  89 D6                mov       si, dx
0x00000000000045ad:  B8 DF 21             mov       ax, 0x21df
0x00000000000045b0:  C1 E6 04             shl       si, 4
0x00000000000045b3:  C1 E7 04             shl       di, 4
0x00000000000045b6:  8E C0                mov       es, ax
0x00000000000045b8:  83 C7 02             add       di, 2
0x00000000000045bb:  26 8B 44 02          mov       ax, word ptr es:[si + 2]
0x00000000000045bf:  83 C6 02             add       si, 2
0x00000000000045c2:  26 3B 05             cmp       ax, word ptr es:[di]
0x00000000000045c5:  74 29                je        0x45f0
0x00000000000045c7:  B0 01                mov       al, 1
0x00000000000045c9:  83 7E F6 27          cmp       word ptr [bp - 0xa], 0x27
0x00000000000045cd:  74 25                je        0x45f4
0x00000000000045cf:  F6 46 FA 20          test      byte ptr [bp - 6], 0x20
0x00000000000045d3:  74 31                je        0x4606
0x00000000000045d5:  80 3E 31 0E 00       cmp       byte ptr [0xe31], 0
0x00000000000045da:  BA B0 00             mov       dx, 0xb0
0x00000000000045dd:  B8 A0 19             mov       ax, 0x19a0
0x00000000000045e0:  E8 51 FC             call      0x4234
0x00000000000045e3:  FF 46 FC             inc       word ptr [bp - 4]
0x00000000000045e6:  83 C3 10             add       bx, 0x10
0x00000000000045e9:  E9 AE FE             jmp       0x449a
0x00000000000045ec:  30 C0                xor       al, al
0x00000000000045ee:  EB B6                jmp       0x45a6
0x00000000000045f0:  30 C0                xor       al, al
0x00000000000045f2:  EB D5                jmp       0x45c9
0x00000000000045f4:  BA B8 00             mov       dx, 0xb8
0x00000000000045f7:  B8 A0 19             mov       ax, 0x19a0
0x00000000000045fa:  E8 37 FC             call      0x4234
0x00000000000045fd:  FF 46 FC             inc       word ptr [bp - 4]
0x0000000000004600:  83 C3 10             add       bx, 0x10
0x0000000000004603:  E9 94 FE             jmp       0x449a
0x0000000000004606:  84 C9                test      cl, cl
0x0000000000004608:  75 20                jne       0x462a
0x000000000000460a:  84 C0                test      al, al
0x000000000000460c:  75 2E                jne       0x463c
0x000000000000460e:  80 3E 31 0E 00       cmp       byte ptr [0xe31], 0
0x0000000000004613:  75 03                jne       0x4618
0x0000000000004615:  E9 49 FF             jmp       0x4561
0x0000000000004618:  BA 60 00             mov       dx, 0x60
0x000000000000461b:  B8 A0 19             mov       ax, 0x19a0
0x000000000000461e:  E8 13 FC             call      0x4234
0x0000000000004621:  FF 46 FC             inc       word ptr [bp - 4]
0x0000000000004624:  83 C3 10             add       bx, 0x10
0x0000000000004627:  E9 70 FE             jmp       0x449a
0x000000000000462a:  BA 40 00             mov       dx, 0x40
0x000000000000462d:  B8 A0 19             mov       ax, 0x19a0
0x0000000000004630:  E8 01 FC             call      0x4234
0x0000000000004633:  FF 46 FC             inc       word ptr [bp - 4]
0x0000000000004636:  83 C3 10             add       bx, 0x10
0x0000000000004639:  E9 5E FE             jmp       0x449a
0x000000000000463c:  BA E7 00             mov       dx, 0xe7
0x000000000000463f:  B8 A0 19             mov       ax, 0x19a0
0x0000000000004642:  E8 EF FB             call      0x4234
0x0000000000004645:  FF 46 FC             inc       word ptr [bp - 4]
0x0000000000004648:  83 C3 10             add       bx, 0x10
0x000000000000464b:  E9 4C FE             jmp       0x449a


ENDP

PROC    AM_rotate_ NEAR
PUBLIC  AM_rotate_

0x000000000000464e:  51                   push      cx
0x000000000000464f:  56                   push      si
0x0000000000004650:  57                   push      di
0x0000000000004651:  55                   push      bp
0x0000000000004652:  89 E5                mov       bp, sp
0x0000000000004654:  83 EC 06             sub       sp, 6
0x0000000000004657:  89 C6                mov       si, ax
0x0000000000004659:  89 D7                mov       di, dx
0x000000000000465b:  89 D9                mov       cx, bx
0x000000000000465d:  B8 25 34             mov       ax, 0x3425
0x0000000000004660:  89 CA                mov       dx, cx
0x0000000000004662:  8B 1C                mov       bx, word ptr [si]
0x0000000000004664:  0E                   push      cs
0x0000000000004665:  E8 C8 13             call      0x5a30
0x0000000000004668:  90                   nop       
0x0000000000004669:  89 46 FC             mov       word ptr [bp - 4], ax
0x000000000000466c:  89 56 FE             mov       word ptr [bp - 2], dx
0x000000000000466f:  8B 1D                mov       bx, word ptr [di]
0x0000000000004671:  B8 25 32             mov       ax, 0x3225
0x0000000000004674:  89 CA                mov       dx, cx
0x0000000000004676:  0E                   push      cs
0x0000000000004677:  E8 B6 13             call      0x5a30
0x000000000000467a:  90                   nop       
0x000000000000467b:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x000000000000467e:  29 C3                sub       bx, ax
0x0000000000004680:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000004683:  19 D0                sbb       ax, dx
0x0000000000004685:  8B 1C                mov       bx, word ptr [si]
0x0000000000004687:  89 46 FA             mov       word ptr [bp - 6], ax
0x000000000000468a:  89 CA                mov       dx, cx
0x000000000000468c:  B8 25 32             mov       ax, 0x3225
0x000000000000468f:  0E                   push      cs
0x0000000000004690:  3E E8 9C 13          call      0x5a30
0x0000000000004694:  89 46 FC             mov       word ptr [bp - 4], ax
0x0000000000004697:  89 56 FE             mov       word ptr [bp - 2], dx
0x000000000000469a:  8B 1D                mov       bx, word ptr [di]
0x000000000000469c:  B8 25 34             mov       ax, 0x3425
0x000000000000469f:  89 CA                mov       dx, cx
0x00000000000046a1:  0E                   push      cs
0x00000000000046a2:  3E E8 8A 13          call      0x5a30
0x00000000000046a6:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x00000000000046a9:  01 C3                add       bx, ax
0x00000000000046ab:  13 56 FE             adc       dx, word ptr [bp - 2]
0x00000000000046ae:  8B 46 FA             mov       ax, word ptr [bp - 6]
0x00000000000046b1:  89 15                mov       word ptr [di], dx
0x00000000000046b3:  89 04                mov       word ptr [si], ax
0x00000000000046b5:  C9                   leave     
0x00000000000046b6:  5F                   pop       di
0x00000000000046b7:  5E                   pop       si
0x00000000000046b8:  59                   pop       cx
0x00000000000046b9:  C3                   ret       

ENDP

PROC    AM_drawLineCharacter_ NEAR
PUBLIC  AM_drawLineCharacter_

0x00000000000046ba:  56                   push      si
0x00000000000046bb:  57                   push      di
0x00000000000046bc:  55                   push      bp
0x00000000000046bd:  89 E5                mov       bp, sp
0x00000000000046bf:  52                   push      dx
0x00000000000046c0:  53                   push      bx
0x00000000000046c1:  31 FF                xor       di, di
0x00000000000046c3:  85 D2                test      dx, dx
0x00000000000046c5:  77 03                ja        0x46ca
0x00000000000046c7:  E9 99 00             jmp       0x4763
0x00000000000046ca:  89 C6                mov       si, ax
0x00000000000046cc:  8B 04                mov       ax, word ptr [si]
0x00000000000046ce:  A3 B0 19             mov       word ptr [0x19b0], ax
0x00000000000046d1:  8B 44 02             mov       ax, word ptr [si + 2]
0x00000000000046d4:  A3 B2 19             mov       word ptr [0x19b2], ax
0x00000000000046d7:  83 7E FC 00          cmp       word ptr [bp - 4], 0
0x00000000000046db:  74 03                je        0x46e0
0x00000000000046dd:  E9 89 00             jmp       0x4769
0x00000000000046e0:  85 C9                test      cx, cx
0x00000000000046e2:  74 0B                je        0x46ef
0x00000000000046e4:  BA B2 19             mov       dx, 0x19b2
0x00000000000046e7:  B8 B0 19             mov       ax, 0x19b0
0x00000000000046ea:  89 CB                mov       bx, cx
0x00000000000046ec:  E8 5F FF             call      0x464e
0x00000000000046ef:  8B 46 0A             mov       ax, word ptr [bp + 0xa]
0x00000000000046f2:  C1 3E B0 19 04       sar       word ptr [0x19b0], 4
0x00000000000046f7:  C1 3E B2 19 04       sar       word ptr [0x19b2], 4
0x00000000000046fc:  01 06 B0 19          add       word ptr [0x19b0], ax
0x0000000000004700:  8B 46 0C             mov       ax, word ptr [bp + 0xc]
0x0000000000004703:  01 06 B2 19          add       word ptr [0x19b2], ax
0x0000000000004707:  8B 44 04             mov       ax, word ptr [si + 4]
0x000000000000470a:  A3 B4 19             mov       word ptr [0x19b4], ax
0x000000000000470d:  8B 44 06             mov       ax, word ptr [si + 6]
0x0000000000004710:  A3 B6 19             mov       word ptr [0x19b6], ax
0x0000000000004713:  83 7E FC 00          cmp       word ptr [bp - 4], 0
0x0000000000004717:  74 0A                je        0x4723
0x0000000000004719:  C1 26 B4 19 04       shl       word ptr [0x19b4], 4
0x000000000000471e:  C1 26 B6 19 04       shl       word ptr [0x19b6], 4
0x0000000000004723:  85 C9                test      cx, cx
0x0000000000004725:  74 0B                je        0x4732
0x0000000000004727:  BA B6 19             mov       dx, 0x19b6
0x000000000000472a:  B8 B4 19             mov       ax, 0x19b4
0x000000000000472d:  89 CB                mov       bx, cx
0x000000000000472f:  E8 1C FF             call      0x464e
0x0000000000004732:  8B 46 0A             mov       ax, word ptr [bp + 0xa]
0x0000000000004735:  C1 3E B4 19 04       sar       word ptr [0x19b4], 4
0x000000000000473a:  C1 3E B6 19 04       sar       word ptr [0x19b6], 4
0x000000000000473f:  01 06 B4 19          add       word ptr [0x19b4], ax
0x0000000000004743:  8B 46 0C             mov       ax, word ptr [bp + 0xc]
0x0000000000004746:  01 06 B6 19          add       word ptr [0x19b6], ax
0x000000000000474a:  8A 46 08             mov       al, byte ptr [bp + 8]
0x000000000000474d:  30 E4                xor       ah, ah
0x000000000000474f:  83 C6 08             add       si, 8
0x0000000000004752:  89 C2                mov       dx, ax
0x0000000000004754:  B8 B0 19             mov       ax, 0x19b0
0x0000000000004757:  47                   inc       di
0x0000000000004758:  E8 D9 FA             call      0x4234
0x000000000000475b:  3B 7E FE             cmp       di, word ptr [bp - 2]
0x000000000000475e:  73 03                jae       0x4763
0x0000000000004760:  E9 69 FF             jmp       0x46cc
0x0000000000004763:  C9                   leave     
0x0000000000004764:  5F                   pop       di
0x0000000000004765:  5E                   pop       si
0x0000000000004766:  C2 06 00             ret       6
0x0000000000004769:  C1 26 B0 19 04       shl       word ptr [0x19b0], 4
0x000000000000476e:  C1 26 B2 19 04       shl       word ptr [0x19b2], 4
0x0000000000004773:  E9 6A FF             jmp       0x46e0


ENDP

PROC    AM_drawPlayers_ NEAR
PUBLIC  AM_drawPlayers_

0x0000000000004776:  53                   push      bx
0x0000000000004777:  51                   push      cx
0x0000000000004778:  52                   push      dx
0x0000000000004779:  56                   push      si
0x000000000000477a:  80 3E 31 0E 00       cmp       byte ptr [0xe31], 0
0x000000000000477f:  74 27                je        0x47a8
0x0000000000004781:  BB 30 06             mov       bx, 0x630
0x0000000000004784:  BA 10 00             mov       dx, 0x10
0x0000000000004787:  C4 37                les       si, ptr [bx]
0x0000000000004789:  B8 71 0E             mov       ax, 0xe71
0x000000000000478c:  26 FF 74 06          push      word ptr es:[si + 6]
0x0000000000004790:  26 8B 4C 10          mov       cx, word ptr es:[si + 0x10]
0x0000000000004794:  26 FF 74 02          push      word ptr es:[si + 2]
0x0000000000004798:  31 DB                xor       bx, bx
0x000000000000479a:  68 D1 00             push      0xd1
0x000000000000479d:  C1 E9 03             shr       cx, 3
0x00000000000047a0:  E8 17 FF             call      0x46ba
0x00000000000047a3:  5E                   pop       si
0x00000000000047a4:  5A                   pop       dx
0x00000000000047a5:  59                   pop       cx
0x00000000000047a6:  5B                   pop       bx
0x00000000000047a7:  C3                   ret       
0x00000000000047a8:  BB 30 06             mov       bx, 0x630
0x00000000000047ab:  BA 07 00             mov       dx, 7
0x00000000000047ae:  C4 37                les       si, ptr [bx]
0x00000000000047b0:  B8 39 0E             mov       ax, 0xe39
0x00000000000047b3:  EB D7                jmp       0x478c


ENDP

PROC    AM_drawThings_ NEAR
PUBLIC  AM_drawThings_

0x00000000000047b6:  53                   push      bx
0x00000000000047b7:  51                   push      cx
0x00000000000047b8:  52                   push      dx
0x00000000000047b9:  56                   push      si
0x00000000000047ba:  57                   push      di
0x00000000000047bb:  55                   push      bp
0x00000000000047bc:  89 E5                mov       bp, sp
0x00000000000047be:  83 EC 04             sub       sp, 4
0x00000000000047c1:  C7 46 FE 00 00       mov       word ptr [bp - 2], 0
0x00000000000047c6:  31 FF                xor       di, di
0x00000000000047c8:  BE CE 04             mov       si, 0x4ce
0x00000000000047cb:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x00000000000047ce:  3B 04                cmp       ax, word ptr [si]
0x00000000000047d0:  72 03                jb        0x47d5
0x00000000000047d2:  E9 9E F8             jmp       0x4073
0x00000000000047d5:  B8 DF 21             mov       ax, 0x21df
0x00000000000047d8:  8D 75 08             lea       si, [di + 8]
0x00000000000047db:  8E C0                mov       es, ax
0x00000000000047dd:  26 8B 04             mov       ax, word ptr es:[si]
0x00000000000047e0:  85 C0                test      ax, ax
0x00000000000047e2:  74 33                je        0x4817
0x00000000000047e4:  6B F0 18             imul      si, ax, 0x18
0x00000000000047e7:  C7 46 FC F5 6A       mov       word ptr [bp - 4], 0x6af5
0x00000000000047ec:  BB 10 00             mov       bx, 0x10
0x00000000000047ef:  8E 46 FC             mov       es, word ptr [bp - 4]
0x00000000000047f2:  BA 03 00             mov       dx, 3
0x00000000000047f5:  26 FF 74 06          push      word ptr es:[si + 6]
0x00000000000047f9:  B8 F1 0E             mov       ax, 0xef1
0x00000000000047fc:  26 FF 74 02          push      word ptr es:[si + 2]
0x0000000000004800:  26 8B 4C 10          mov       cx, word ptr es:[si + 0x10]
0x0000000000004804:  6A 70                push      0x70
0x0000000000004806:  C1 E9 03             shr       cx, 3
0x0000000000004809:  E8 AE FE             call      0x46ba
0x000000000000480c:  8E 46 FC             mov       es, word ptr [bp - 4]
0x000000000000480f:  26 8B 44 0C          mov       ax, word ptr es:[si + 0xc]
0x0000000000004813:  85 C0                test      ax, ax
0x0000000000004815:  75 CD                jne       0x47e4
0x0000000000004817:  FF 46 FE             inc       word ptr [bp - 2]
0x000000000000481a:  83 C7 10             add       di, 0x10
0x000000000000481d:  EB A9                jmp       0x47c8


ENDP

PROC    AM_drawMarks_ NEAR
PUBLIC  AM_drawMarks_

0x0000000000004820:  53                   push      bx
0x0000000000004821:  51                   push      cx
0x0000000000004822:  52                   push      dx
0x0000000000004823:  56                   push      si
0x0000000000004824:  57                   push      di
0x0000000000004825:  55                   push      bp
0x0000000000004826:  89 E5                mov       bp, sp
0x0000000000004828:  83 EC 04             sub       sp, 4
0x000000000000482b:  C6 46 FE 00          mov       byte ptr [bp - 2], 0
0x000000000000482f:  FC                   cld       
0x0000000000004830:  8A 46 FE             mov       al, byte ptr [bp - 2]
0x0000000000004833:  98                   cwde      
0x0000000000004834:  89 C7                mov       di, ax
0x0000000000004836:  C1 E7 02             shl       di, 2
0x0000000000004839:  89 46 FC             mov       word ptr [bp - 4], ax
0x000000000000483c:  8B 85 C0 19          mov       ax, word ptr [di + 0x19c0]
0x0000000000004840:  3D FF FF             cmp       ax, 0xffff
0x0000000000004843:  75 10                jne       0x4855
0x0000000000004845:  FE 46 FE             inc       byte ptr [bp - 2]
0x0000000000004848:  80 7E FE 0A          cmp       byte ptr [bp - 2], 0xa
0x000000000000484c:  7C E2                jl        0x4830
0x000000000000484e:  C9                   leave     
0x000000000000484f:  5F                   pop       di
0x0000000000004850:  5E                   pop       si
0x0000000000004851:  5A                   pop       dx
0x0000000000004852:  59                   pop       cx
0x0000000000004853:  5B                   pop       bx
0x0000000000004854:  C3                   ret       
0x0000000000004855:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x0000000000004859:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x000000000000485d:  2B 06 4E 1A          sub       ax, word ptr [0x1a4e]
0x0000000000004861:  0E                   push      cs
0x0000000000004862:  3E E8 23 11          call      0x5989
0x0000000000004866:  8B 1E 04 1A          mov       bx, word ptr [0x1a04]
0x000000000000486a:  89 C6                mov       si, ax
0x000000000000486c:  8B 85 C2 19          mov       ax, word ptr [di + 0x19c2]
0x0000000000004870:  8B 0E 06 1A          mov       cx, word ptr [0x1a06]
0x0000000000004874:  2B 06 50 1A          sub       ax, word ptr [0x1a50]
0x0000000000004878:  0E                   push      cs
0x0000000000004879:  E8 0D 11             call      0x5989
0x000000000000487c:  90                   nop       
0x000000000000487d:  BA A8 00             mov       dx, 0xa8
0x0000000000004880:  29 C2                sub       dx, ax
0x0000000000004882:  85 F6                test      si, si
0x0000000000004884:  7C BF                jl        0x4845
0x0000000000004886:  81 FE 3B 01          cmp       si, 0x13b
0x000000000000488a:  7F B9                jg        0x4845
0x000000000000488c:  85 D2                test      dx, dx
0x000000000000488e:  7C B5                jl        0x4845
0x0000000000004890:  81 FA A2 00          cmp       dx, 0xa2
0x0000000000004894:  7F AF                jg        0x4845
0x0000000000004896:  B8 37 4C             mov       ax, 0x4c37
0x0000000000004899:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x000000000000489c:  8E C0                mov       es, ax
0x000000000000489e:  01 DB                add       bx, bx
0x00000000000048a0:  06                   push      es
0x00000000000048a1:  26 8B 87 0C 02       mov       ax, word ptr es:[bx + 0x20c]
0x00000000000048a6:  81 C3 0C 02          add       bx, 0x20c
0x00000000000048aa:  50                   push      ax
0x00000000000048ab:  31 DB                xor       bx, bx
0x00000000000048ad:  89 F0                mov       ax, si
0x00000000000048af:  0E                   push      cs
0x00000000000048b0:  3E E8 10 6C          call      0xb4c4
0x00000000000048b4:  EB 8F                jmp       0x4845


ENDP

PROC    AM_drawCrosshair_ NEAR
PUBLIC  AM_drawCrosshair_


0x00000000000048b6:  53                   push      bx
0x00000000000048b7:  B8 FF 7F             mov       ax, 0x7fff
0x00000000000048ba:  BB A0 E9             mov       bx, 0xe9a0
0x00000000000048bd:  8E C0                mov       es, ax
0x00000000000048bf:  26 C6 07 60          mov       byte ptr es:[bx], 0x60
0x00000000000048c3:  5B                   pop       bx
0x00000000000048c4:  C3                   ret       


ENDP

PROC    AM_Drawer_ NEAR
PUBLIC  AM_Drawer_

0x00000000000048c6:  53                   push      bx
0x00000000000048c7:  51                   push      cx
0x00000000000048c8:  52                   push      dx
0x00000000000048c9:  57                   push      di
0x00000000000048ca:  B9 00 D2             mov       cx, 0xd200
0x00000000000048cd:  BA 00 80             mov       dx, 0x8000
0x00000000000048d0:  30 C0                xor       al, al
0x00000000000048d2:  31 FF                xor       di, di
0x00000000000048d4:  8E C2                mov       es, dx
0x00000000000048d6:  57                   push      di
0x00000000000048d7:  8A E0                mov       ah, al
0x00000000000048d9:  D1 E9                shr       cx, 1
0x00000000000048db:  F3 AB                rep stosw word ptr es:[di], ax
0x00000000000048dd:  13 C9                adc       cx, cx
0x00000000000048df:  F3 AA                rep stosb byte ptr es:[di], al
0x00000000000048e1:  5F                   pop       di
0x00000000000048e2:  80 3E 32 0E 00       cmp       byte ptr [0xe32], 0
0x00000000000048e7:  74 03                je        0x48ec
0x00000000000048e9:  E8 1E FA             call      0x430a
0x00000000000048ec:  E8 99 FB             call      0x4488
0x00000000000048ef:  E8 84 FE             call      0x4776
0x00000000000048f2:  80 3E 31 0E 02       cmp       byte ptr [0xe31], 2
0x00000000000048f7:  74 23                je        0x491c
0x00000000000048f9:  BA FF 7F             mov       dx, 0x7fff
0x00000000000048fc:  BB A0 E9             mov       bx, 0xe9a0
0x00000000000048ff:  8E C2                mov       es, dx
0x0000000000004901:  B9 A8 00             mov       cx, 0xa8
0x0000000000004904:  26 C6 07 60          mov       byte ptr es:[bx], 0x60
0x0000000000004908:  E8 15 FF             call      0x4820
0x000000000000490b:  31 D2                xor       dx, dx
0x000000000000490d:  BB 40 01             mov       bx, 0x140
0x0000000000004910:  31 C0                xor       ax, ax
0x0000000000004912:  0E                   push      cs
0x0000000000004913:  E8 8B 70             call      0xb9a1
0x0000000000004916:  90                   nop       
0x0000000000004917:  5F                   pop       di
0x0000000000004918:  5A                   pop       dx
0x0000000000004919:  59                   pop       cx
0x000000000000491a:  5B                   pop       bx
0x000000000000491b:  CB                   retf      
0x000000000000491c:  E8 97 FE             call      0x47b6
0x000000000000491f:  EB D8                jmp       0x48f9


ENDP

PROC    AM_MAP_ENDMARKER_ NEAR
PUBLIC  AM_MAP_ENDMARKER_
ENDP


END