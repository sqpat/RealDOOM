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
EXTRN _P_ChangeSector:DWORD
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR

SHORTFLOORBITS = 3

.DATA




.CODE



PROC    P_PLATS_STARTMARKER_ NEAR
PUBLIC  P_PLATS_STARTMARKER_
ENDP

COMMENT @

_plat_raise_jump_table:
dw platraise_switch_case_0
dw platraise_switch_case_1
dw platraise_switch_case_2
dw platraise_switch_case_default


PROC    T_PlatRaise_ NEAR
PUBLIC  T_PlatRaise_ 


0x0000000000003648:  53                push        bx
0x0000000000003649:  51                push        cx
0x000000000000364a:  56                push        si
0x000000000000364b:  57                push        di
0x000000000000364c:  55                push        bp
0x000000000000364d:  89 E5             mov         bp, sp
0x000000000000364f:  83 EC 04          sub         sp, 4
0x0000000000003652:  89 C6             mov         si, ax
0x0000000000003654:  89 56 FC          mov         word ptr [bp - 4], dx
0x0000000000003657:  8B 3C             mov         di, word ptr ds:[si]
0x0000000000003659:  B8 90 21          mov         ax, SECTORS_SEGMENT
0x000000000000365c:  89 FB             mov         bx, di
0x000000000000365e:  8E C0             mov         es, ax
0x0000000000003660:  C1 E3 04          shl         bx, 4
0x0000000000003663:  8A 44 0A          mov         al, byte ptr ds:[si + 0xa]
0x0000000000003666:  89 5E FE          mov         word ptr [bp - 2], bx
0x0000000000003669:  26 8B 17          mov         dx, word ptr es:[bx]
0x000000000000366c:  3C 03             cmp         al, 3
0x000000000000366e:  77 48             ja          platraise_switch_case_default
0x0000000000003670:  30 E4             xor         ah, ah
0x0000000000003672:  89 C3             mov         bx, ax
0x0000000000003674:  01 C3             add         bx, ax
0x0000000000003676:  2E FF A7 40 36    jmp         word ptr cs:[bx + _plat_raise_jump_table]
platraise_switch_case_0:
0x000000000000367b:  8A 44 0C          mov         al, byte ptr ds:[si + 0xc]
0x000000000000367e:  8B 5C 06          mov         bx, word ptr ds:[si + 6]
0x0000000000003681:  98                cbw        
0x0000000000003682:  8B 54 02          mov         dx, word ptr ds:[si + 2]
0x0000000000003685:  89 C1             mov         cx, ax
0x0000000000003687:  8B 46 FE          mov         ax, word ptr [bp - 2]
0x000000000000368a:  E8 02 EF          call        T_MovePlaneFloorUp_
0x000000000000368d:  88 C1             mov         cl, al
0x000000000000368f:  8A 44 0E          mov         al, byte ptr ds:[si + 0xe]
0x0000000000003692:  3C 02             cmp         al, 2
0x0000000000003694:  75 28             jne         label_1
label_10:
0x0000000000003696:  BB 1C 07          mov         bx, 0x71c
0x0000000000003699:  F6 07 07          test        byte ptr ds:[bx], 7
0x000000000000369c:  75 0A             jne         label_2
0x000000000000369e:  BA 16 00          mov         dx, 0x16
0x00000000000036a1:  89 F8             mov         ax, di

0x00000000000036a4:  3E E8 BA CE       call        S_StartSoundWithParams_
label_2:
0x00000000000036a8:  80 F9 01          cmp         cl, 1
0x00000000000036ab:  75 06             jne         label_3
0x00000000000036ad:  80 7C 0C 00       cmp         byte ptr ds:[si + 0xc], 0
0x00000000000036b1:  74 11             je          label_4
label_3:
0x00000000000036b3:  80 F9 02          cmp         cl, 2
0x00000000000036b6:  74 21             je          label_5
platraise_switch_case_default:
platraise_switch_case_3:
done_with_platraise_switch_block:
0x00000000000036b8:  C9                LEAVE_MACRO       
0x00000000000036b9:  5F                pop         di
0x00000000000036ba:  5E                pop         si
0x00000000000036bb:  59                pop         cx
0x00000000000036bc:  5B                pop         bx
0x00000000000036bd:  C3                ret         
label_1:
0x00000000000036be:  3C 03             cmp         al, 3
0x00000000000036c0:  74 D4             je          label_10
0x00000000000036c2:  EB E4             jmp         label_2
label_4:
0x00000000000036c4:  8A 44 08          mov         al, byte ptr ds:[si + 8]
0x00000000000036c7:  BA 12 00          mov         dx, 0x12
0x00000000000036ca:  88 44 09          mov         byte ptr ds:[si + 9], al
0x00000000000036cd:  89 F8             mov         ax, di
0x00000000000036cf:  88 4C 0A          mov         byte ptr ds:[si + 0xa], cl
0x00000000000036d2:  0E                
0x00000000000036d3:  E8 8C CE          call        S_StartSoundWithParams_
0x00000000000036d6:  90                         
0x00000000000036d7:  EB DF             jmp         done_with_platraise_switch_block
label_5:
0x00000000000036d9:  8A 44 08          mov         al, byte ptr ds:[si + 8]
0x00000000000036dc:  BA 13 00          mov         dx, 0x13
0x00000000000036df:  88 44 09          mov         byte ptr ds:[si + 9], al
0x00000000000036e2:  89 F8             mov         ax, di
0x00000000000036e4:  88 4C 0A          mov         byte ptr ds:[si + 0xa], cl
0x00000000000036e7:  0E                
0x00000000000036e8:  3E E8 76 CE       call        S_StartSoundWithParams_
0x00000000000036ec:  8A 44 0E          mov         al, byte ptr ds:[si + 0xe]
0x00000000000036ef:  3C 04             cmp         al, 4
0x00000000000036f1:  74 0A             je          label_9
0x00000000000036f3:  3C 01             cmp         al, 1
0x00000000000036f5:  72 C1             jb          done_with_platraise_switch_block
0x00000000000036f7:  76 04             jbe         label_9
0x00000000000036f9:  3C 03             cmp         al, 3
0x00000000000036fb:  77 BB             ja          done_with_platraise_switch_block
label_9:
0x00000000000036fd:  8B 46 FC          mov         ax, word ptr [bp - 4]
0x0000000000003700:  E8 0B 03          call        P_RemoveActivePlat_
0x0000000000003703:  C9                LEAVE_MACRO       
0x0000000000003704:  5F                pop         di
0x0000000000003705:  5E                pop         si
0x0000000000003706:  59                pop         cx
0x0000000000003707:  5B                pop         bx
0x0000000000003708:  C3                ret         
platraise_switch_case_1:
0x0000000000003709:  8B 46 FE          mov         ax, word ptr [bp - 2]
0x000000000000370c:  8B 5C 04          mov         bx, word ptr ds:[si + 4]
0x000000000000370f:  8B 54 02          mov         dx, word ptr ds:[si + 2]
0x0000000000003712:  31 C9             xor         cx, cx
0x0000000000003714:  E8 03 EE          call        T_MovePlaneFloorDown_
0x0000000000003717:  3C 02             cmp         al, 2
0x0000000000003719:  75 9D             jne         done_with_platraise_switch_block
0x000000000000371b:  8A 44 08          mov         al, byte ptr ds:[si + 8]
0x000000000000371e:  BA 13 00          mov         dx, 0x13
0x0000000000003721:  88 44 09          mov         byte ptr ds:[si + 9], al
0x0000000000003724:  89 F8             mov         ax, di
0x0000000000003726:  C6 44 0A 02       mov         byte ptr ds:[si + 0xa], 2
0x000000000000372a:  0E                
0x000000000000372b:  E8 34 CE          call        S_StartSoundWithParams_
0x000000000000372e:  90                         
0x000000000000372f:  C9                LEAVE_MACRO       
0x0000000000003730:  5F                pop         di
0x0000000000003731:  5E                pop         si
0x0000000000003732:  59                pop         cx
0x0000000000003733:  5B                pop         bx
0x0000000000003734:  C3                ret         
platraise_switch_case_2:
0x0000000000003735:  FE 4C 09          dec         byte ptr ds:[si + 9]
0x0000000000003738:  74 03             je          label_8
0x000000000000373a:  E9 7B FF          jmp         done_with_platraise_switch_block
label_8:
0x000000000000373d:  3B 54 04          cmp         dx, word ptr ds:[si + 4]
0x0000000000003740:  74 14             je          label_6
0x0000000000003742:  C6 44 0A 01       mov         byte ptr ds:[si + 0xa], 1
label_7:
0x0000000000003746:  BA 12 00          mov         dx, 0x12
0x0000000000003749:  89 F8             mov         ax, di
0x000000000000374b:  0E                
0x000000000000374c:  3E E8 12 CE       call        S_StartSoundWithParams_
0x0000000000003750:  C9                LEAVE_MACRO       
0x0000000000003751:  5F                pop         di
0x0000000000003752:  5E                pop         si
0x0000000000003753:  59                pop         cx
0x0000000000003754:  5B                pop         bx
0x0000000000003755:  C3                ret         
label_6:
0x0000000000003756:  88 64 0A          mov         byte ptr ds:[si + 0xa], ah
0x0000000000003759:  EB EB             jmp         label_7
ENDP

_doplat_jump_table:
dw switch_block_ev_doplat_case_0
dw switch_block_ev_doplat_case_1
dw switch_block_ev_doplat_case_2
dw switch_block_ev_doplat_case_3
dw switch_block_ev_doplat_case_4


PROC    EV_DoPlat_ NEAR
PUBLIC  EV_DoPlat_ 


0x0000000000003766:  56                push        si
0x0000000000003767:  57                push        di
0x0000000000003768:  55                push        bp
0x0000000000003769:  89 E5             mov         bp, sp
0x000000000000376b:  81 EC 18 02       sub         sp, 0218h
0x000000000000376f:  88 46 FC          mov         byte ptr [bp - 4], al
0x0000000000003772:  89 D6             mov         si, dx
0x0000000000003774:  88 5E FE          mov         byte ptr [bp - 2], bl
0x0000000000003777:  89 4E EC          mov         word ptr [bp - 0x14], cx
0x000000000000377a:  31 C0             xor         ax, ax
0x000000000000377c:  89 46 EE          mov         word ptr [bp - 0x12], ax
0x000000000000377f:  89 46 F2          mov         word ptr [bp - 0xe], ax
0x0000000000003782:  84 DB             test        bl, bl
0x0000000000003784:  75 0A             jne         label_11
0x0000000000003786:  8A 46 FC          mov         al, byte ptr [bp - 4]
0x0000000000003789:  31 D2             xor         dx, dx
0x000000000000378b:  30 E4             xor         ah, ah
0x000000000000378d:  E8 D8 01          call        EV_PlatFunc_
label_11:
0x0000000000003790:  8A 46 FC          mov         al, byte ptr [bp - 4]
0x0000000000003793:  8D 96 E8 FD       lea         dx, [bp - 0218h]
0x0000000000003797:  C1 E6 04          shl         si, 4
0x000000000000379a:  31 DB             xor         bx, bx
0x000000000000379c:  89 76 F4          mov         word ptr [bp - 0xc], si
0x000000000000379f:  8B 76 EE          mov         si, word ptr [bp - 0x12]
0x00000000000037a2:  98                cbw        
0x00000000000037a3:  01 F6             add         si, si
0x00000000000037a5:  E8 61 04          call        P_FindSectorsFromLineTag_
0x00000000000037a8:  89 76 F6          mov         word ptr [bp - 0xa], si
0x00000000000037ab:  83 BA E8 FD 00    cmp         word ptr [bp + si - 0218h], 0
0x00000000000037b0:  7C 79             jl          label_12
0x00000000000037b2:  8B 76 F6          mov         si, word ptr [bp - 0xa]
0x00000000000037b5:  8B 8A E8 FD       mov         cx, word ptr [bp + si - 0218h]
0x00000000000037b9:  89 C8             mov         ax, cx
0x00000000000037bb:  C1 E0 04          shl         ax, 4
0x00000000000037be:  89 46 F8          mov         word ptr [bp - 8], ax
0x00000000000037c1:  89 46 E8          mov         word ptr [bp - 0x18], ax
0x00000000000037c4:  B8 90 21          mov         ax, SECTORS_SEGMENT
0x00000000000037c7:  8B 5E F8          mov         bx, word ptr [bp - 8]
0x00000000000037ca:  8E C0             mov         es, ax
0x00000000000037cc:  26 8B 07          mov         ax, word ptr es:[bx]
0x00000000000037cf:  BF 2C 00          mov         di, SIZEOF_THINKER_T
0x00000000000037d2:  89 46 FA          mov         word ptr [bp - 6], ax
0x00000000000037d5:  B8 00 10          mov         ax, TF_PLATRAISE_HIGHBITS
0x00000000000037d8:  31 D2             xor         dx, dx
0x00000000000037da:  0E                
0x00000000000037db:  E8 CA 11          call        P_CreateThinker_
0x00000000000037de:  90                         
0x00000000000037df:  89 C3             mov         bx, ax
0x00000000000037e1:  89 C6             mov         si, ax
0x00000000000037e3:  2D 04 34          sub         ax, (_thinkerlist + THINKER_T.t_data)
0x00000000000037e6:  F7 F7             div         di
0x00000000000037e8:  C7 46 F2 01 00    mov         word ptr [bp - 0xe], 1
0x00000000000037ed:  C7 46 EA 00 00    mov         word ptr [bp - 0x16], 0
0x00000000000037f2:  FF 46 EE          inc         word ptr [bp - 0x12]
0x00000000000037f5:  8B 7E E8          mov         di, word ptr [bp - 0x18]
0x00000000000037f8:  89 46 F0          mov         word ptr [bp - 0x10], ax
0x00000000000037fb:  89 85 38 DE       mov         word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_special], ax
0x00000000000037ff:  8A 46 FE          mov         al, byte ptr [bp - 2]
0x0000000000003802:  C6 47 0C 00       mov         byte ptr ds:[bx + 0xc], 0
0x0000000000003806:  83 46 F6 02       add         word ptr [bp - 0xa], 2
0x000000000000380a:  88 47 0E          mov         byte ptr ds:[bx + 0xe], al
0x000000000000380d:  8A 46 FC          mov         al, byte ptr [bp - 4]
0x0000000000003810:  81 C7 38 DE       add         di, _sectors_physics + SECTOR_PHYSICS_T.secp_special
0x0000000000003814:  88 47 0D          mov         byte ptr ds:[bx + 0xd], al
0x0000000000003817:  8A 46 FE          mov         al, byte ptr [bp - 2]
0x000000000000381a:  89 0F             mov         word ptr ds:[bx], cx
0x000000000000381c:  3C 04             cmp         al, 4
0x000000000000381e:  77 52             ja          label_13
0x0000000000003820:  30 E4             xor         ah, ah
0x0000000000003822:  89 C7             mov         di, ax
0x0000000000003824:  01 C7             add         di, ax
0x0000000000003826:  2E FF A5 5C 37    jmp         word ptr cs:[di + _doplat_jump_table]
label_12:
0x000000000000382b:  EB 58             jmp         label_14
switch_block_ev_doplat_case_0:
0x000000000000382d:  89 C8             mov         ax, cx
0x000000000000382f:  31 D2             xor         dx, dx
0x0000000000003831:  C7 47 02 08 00    mov         word ptr ds:[bx + 2], 8
0x0000000000003836:  E8 73 02          call        P_FindHighestOrLowestFloorSurrounding_
0x0000000000003839:  89 C3             mov         bx, ax
0x000000000000383b:  3B 46 FA          cmp         ax, word ptr [bp - 6]
0x000000000000383e:  7E 03             jle         label_17
0x0000000000003840:  8B 5E FA          mov         bx, word ptr [bp - 6]
label_17:
0x0000000000003843:  BA 01 00          mov         dx, 1
0x0000000000003846:  89 C8             mov         ax, cx
0x0000000000003848:  89 5C 04          mov         word ptr ds:[si + 4], bx
0x000000000000384b:  E8 5E 02          call        P_FindHighestOrLowestFloorSurrounding_
0x000000000000384e:  89 44 06          mov         word ptr ds:[si + 6], ax
0x0000000000003851:  3B 46 FA          cmp         ax, word ptr [bp - 6]
0x0000000000003854:  7D 06             jge         label_18
0x0000000000003856:  8B 46 FA          mov         ax, word ptr [bp - 6]
0x0000000000003859:  89 44 06          mov         word ptr ds:[si + 6], ax
label_18:
0x000000000000385c:  C6 44 08 69       mov         byte ptr ds:[si + 8], 0x69
0x0000000000003860:  E8 14 13          call        P_Random_
0x0000000000003863:  24 01             and         al, 1
0x0000000000003865:  BA 12 00          mov         dx, 0x12
0x0000000000003868:  88 44 0A          mov         byte ptr ds:[si + 0xa], al
0x000000000000386b:  89 C8             mov         ax, cx
label_15:
0x000000000000386d:  0E                
0x000000000000386e:  3E E8 F0 CC       call        S_StartSoundWithParams_
label_13:
0x0000000000003872:  8B 46 F0          mov         ax, word ptr [bp - 0x10]
0x0000000000003875:  8B 76 F6          mov         si, word ptr [bp - 0xa]
0x0000000000003878:  E8 6B 01          call        0x39e6
0x000000000000387b:  83 BA E8 FD 00    cmp         word ptr [bp + si - 0218h], 0
0x0000000000003880:  7C 03             jl          label_14
0x0000000000003882:  E9 2D FF          jmp         0x37b2
label_14:
0x0000000000003885:  8B 46 F2          mov         ax, word ptr [bp - 0xe]
0x0000000000003888:  C9                LEAVE_MACRO       
0x0000000000003889:  5F                pop         di
0x000000000000388a:  5E                pop         si
0x000000000000388b:  C3                ret         
switch_block_ev_doplat_case_3:
0x000000000000388c:  B8 90 21          mov         ax, SECTORS_SEGMENT
0x000000000000388f:  8B 76 F4          mov         si, word ptr [bp - 0xc]
0x0000000000003892:  C7 47 02 04 00    mov         word ptr ds:[bx + 2], 4
0x0000000000003897:  8E C0             mov         es, ax
0x0000000000003899:  8B 7E F8          mov         di, word ptr [bp - 8]
0x000000000000389c:  26 8A 44 04       mov         al, byte ptr es:[si + 4]
0x00000000000038a0:  8B 56 FA          mov         dx, word ptr [bp - 6]
0x00000000000038a3:  26 88 45 04       mov         byte ptr es:[di + 4], al
0x00000000000038a7:  89 C8             mov         ax, cx
0x00000000000038a9:  E8 76 02          call        P_FindNextHighestFloor_
0x00000000000038ac:  C6 47 08 00       mov         byte ptr ds:[bx + 8], 0
0x00000000000038b0:  83 C6 04          add         si, 4
0x00000000000038b3:  C6 47 0A 00       mov         byte ptr ds:[bx + 0xa], 0
0x00000000000038b7:  83 C7 04          add         di, 4
0x00000000000038ba:  89 47 06          mov         word ptr ds:[bx + 6], ax
0x00000000000038bd:  8B 5E E8          mov         bx, word ptr [bp - 0x18]
0x00000000000038c0:  BA 16 00          mov         dx, 0x16
0x00000000000038c3:  81 C3 3E DE       add         bx, _sectors_physics + SECTOR_PHYSICS_T.secp_linecount
0x00000000000038c7:  89 C8             mov         ax, cx
0x00000000000038c9:  C6 07 00          mov         byte ptr ds:[bx], 0
0x00000000000038cc:  EB 9F             jmp         label_15
switch_block_ev_doplat_case_2:
0x00000000000038ce:  B8 90 21          mov         ax, SECTORS_SEGMENT
0x00000000000038d1:  8B 7E F4          mov         di, word ptr [bp - 0xc]
0x00000000000038d4:  8B 76 F8          mov         si, word ptr [bp - 8]
0x00000000000038d7:  8E C0             mov         es, ax
0x00000000000038d9:  BA 16 00          mov         dx, 0x16
0x00000000000038dc:  26 8A 45 04       mov         al, byte ptr es:[di + 4]
0x00000000000038e0:  83 C7 04          add         di, 4
0x00000000000038e3:  26 88 44 04       mov         byte ptr es:[si + 4], al
0x00000000000038e7:  8B 46 FA          mov         ax, word ptr [bp - 6]
0x00000000000038ea:  C7 47 02 04 00    mov         word ptr ds:[bx + 2], 4
0x00000000000038ef:  03 46 EC          add         ax, word ptr [bp - 0x14]
0x00000000000038f2:  C6 47 08 00       mov         byte ptr ds:[bx + 8], 0
0x00000000000038f6:  C1 E0 03          shl         ax, 3
0x00000000000038f9:  83 C6 04          add         si, 4
0x00000000000038fc:  89 47 06          mov         word ptr ds:[bx + 6], ax
0x00000000000038ff:  89 C8             mov         ax, cx
0x0000000000003901:  C6 47 0A 00       mov         byte ptr ds:[bx + 0xa], 0
0x0000000000003905:  E9 65 FF          jmp         label_15
switch_block_ev_doplat_case_1:
0x0000000000003908:  89 C8             mov         ax, cx
0x000000000000390a:  31 D2             xor         dx, dx
0x000000000000390c:  C7 47 02 20 00    mov         word ptr ds:[bx + 2], 0x20
0x0000000000003911:  E8 98 01          call        P_FindHighestOrLowestFloorSurrounding_
0x0000000000003914:  89 47 04          mov         word ptr ds:[bx + 4], ax
0x0000000000003917:  3B 46 FA          cmp         ax, word ptr [bp - 6]
0x000000000000391a:  7E 06             jle         label_16
0x000000000000391c:  8B 46 FA          mov         ax, word ptr [bp - 6]
0x000000000000391f:  89 47 04          mov         word ptr ds:[bx + 4], ax
label_16:
0x0000000000003922:  8B 46 FA          mov         ax, word ptr [bp - 6]
0x0000000000003925:  C6 44 08 69       mov         byte ptr ds:[si + 8], 0x69
0x0000000000003929:  BA 12 00          mov         dx, 0x12
0x000000000000392c:  89 44 06          mov         word ptr ds:[si + 6], ax
0x000000000000392f:  89 C8             mov         ax, cx
0x0000000000003931:  C6 44 0A 01       mov         byte ptr ds:[si + 0xa], 1
0x0000000000003935:  E9 35 FF          jmp         label_15
switch_block_ev_doplat_case_4:
0x0000000000003938:  89 C8             mov         ax, cx
0x000000000000393a:  31 D2             xor         dx, dx
0x000000000000393c:  C7 47 02 40 00    mov         word ptr ds:[bx + 2], 0x40
0x0000000000003941:  E8 68 01          call        P_FindHighestOrLowestFloorSurrounding_
0x0000000000003944:  89 47 04          mov         word ptr ds:[bx + 4], ax
0x0000000000003947:  3B 46 FA          cmp         ax, word ptr [bp - 6]
0x000000000000394a:  7E 06             jle         label_19
0x000000000000394c:  8B 46 FA          mov         ax, word ptr [bp - 6]
0x000000000000394f:  89 47 04          mov         word ptr ds:[bx + 4], ax
label_19:
0x0000000000003952:  8B 46 FA          mov         ax, word ptr [bp - 6]
0x0000000000003955:  C6 44 08 69       mov         byte ptr ds:[si + 8], 0x69
0x0000000000003959:  BA 12 00          mov         dx, 0x12
0x000000000000395c:  89 44 06          mov         word ptr ds:[si + 6], ax
0x000000000000395f:  89 C8             mov         ax, cx
0x0000000000003961:  C6 44 0A 01       mov         byte ptr ds:[si + 0xa], 1
0x0000000000003965:  E9 05 FF          jmp         label_15

ENDP

PROC    EV_PlatFunc_ NEAR
PUBLIC  EV_PlatFunc_ 

0x0000000000003968:  53                push        bx
0x0000000000003969:  51                push        cx
0x000000000000396a:  56                push        si
0x000000000000396b:  55                push        bp
0x000000000000396c:  89 E5             mov         bp, sp
0x000000000000396e:  83 EC 02          sub         sp, 2
0x0000000000003971:  88 46 FE          mov         byte ptr [bp - 2], al
0x0000000000003974:  88 D5             mov         ch, dl
0x0000000000003976:  30 C9             xor         cl, cl
label_22:
0x0000000000003978:  88 C8             mov         al, cl
0x000000000000397a:  98                cbw        
0x000000000000397b:  89 C6             mov         si, ax
0x000000000000397d:  01 C6             add         si, ax
0x000000000000397f:  8B 84 58 09       mov         ax, word ptr ds:[si + _activeplats]
0x0000000000003983:  85 C0             test        ax, ax
0x0000000000003985:  74 52             je          label_20
0x0000000000003987:  6B D8 2C          imul        bx, ax, SIZEOF_THINKER_T
0x000000000000398a:  8A 87 11 34       mov         al, byte ptr ds:[bx + 0x3411]
0x000000000000398e:  98                cbw        
0x000000000000398f:  89 C2             mov         dx, ax
0x0000000000003991:  8A 46 FE          mov         al, byte ptr [bp - 2]
0x0000000000003994:  30 E4             xor         ah, ah
0x0000000000003996:  81 C3 04 34       add         bx, (_thinkerlist + THINKER_T.t_data)
0x000000000000399a:  39 C2             cmp         dx, ax
0x000000000000399c:  75 3B             jne         label_20
0x000000000000399e:  84 ED             test        ch, ch
0x00000000000039a0:  75 14             jne         label_21
0x00000000000039a2:  8A 47 0A          mov         al, byte ptr ds:[bx + 0xa]
0x00000000000039a5:  3C 03             cmp         al, 3
0x00000000000039a7:  75 0D             jne         label_21
0x00000000000039a9:  88 47 0B          mov         byte ptr ds:[bx + 0xb], al
0x00000000000039ac:  BA 00 10          mov         dx, TF_PLATRAISE_HIGHBITS
0x00000000000039af:  8B 84 58 09       mov         ax, word ptr ds:[si + _activeplats]
0x00000000000039b3:  E8 66 10          call        P_UpdateThinkerFunc_
label_21:
0x00000000000039b6:  80 FD 01          cmp         ch, 1
0x00000000000039b9:  75 1E             jne         label_20
0x00000000000039bb:  8A 47 0A          mov         al, byte ptr ds:[bx + 0xa]
0x00000000000039be:  3C 03             cmp         al, 3
0x00000000000039c0:  74 17             je          label_20
0x00000000000039c2:  88 47 0B          mov         byte ptr ds:[bx + 0xb], al
0x00000000000039c5:  88 C8             mov         al, cl
0x00000000000039c7:  98                cbw        
0x00000000000039c8:  C6 47 0A 03       mov         byte ptr ds:[bx + 0xa], 3
0x00000000000039cc:  89 C3             mov         bx, ax
0x00000000000039ce:  01 C3             add         bx, ax
0x00000000000039d0:  31 D2             xor         dx, dx
0x00000000000039d2:  8B 87 58 09       mov         ax, word ptr ds:[bx + _activeplats]
0x00000000000039d6:  E8 43 10          call        P_UpdateThinkerFunc_
label_20:
0x00000000000039d9:  FE C1             inc         cl
0x00000000000039db:  80 F9 1E          cmp         cl, MAXPLATS
0x00000000000039de:  7C 98             jl          label_22
0x00000000000039e0:  C9                LEAVE_MACRO       
0x00000000000039e1:  5E                pop         si
0x00000000000039e2:  59                pop         cx
0x00000000000039e3:  5B                pop         bx
0x00000000000039e4:  C3                ret         

ENDP

PROC    P_AddActivePlat_ NEAR
PUBLIC  P_AddActivePlat_ 


0x00000000000039e6:  53                push        bx
0x00000000000039e7:  51                push        cx
0x00000000000039e8:  52                push        dx
0x00000000000039e9:  89 C1             mov         cx, ax
0x00000000000039eb:  30 D2             xor         dl, dl
label_24:
0x00000000000039ed:  88 D0             mov         al, dl
0x00000000000039ef:  98                cbw        
0x00000000000039f0:  89 C3             mov         bx, ax
0x00000000000039f2:  01 C3             add         bx, ax
0x00000000000039f4:  83 BF 58 09 00    cmp         word ptr ds:[bx + _activeplats], 0
0x00000000000039f9:  74 0B             je          label_23
0x00000000000039fb:  FE C2             inc         dl
0x00000000000039fd:  80 FA 1E          cmp         dl, MAXPLATS
0x0000000000003a00:  7C EB             jl          label_24
0x0000000000003a02:  5A                pop         dx
0x0000000000003a03:  59                pop         cx
0x0000000000003a04:  5B                pop         bx
0x0000000000003a05:  C3                ret         
label_23:
0x0000000000003a06:  89 8F 58 09       mov         word ptr ds:[bx + _activeplats], cx
0x0000000000003a0a:  5A                pop         dx
0x0000000000003a0b:  59                pop         cx
0x0000000000003a0c:  5B                pop         bx
0x0000000000003a0d:  C3                ret         


ENDP

PROC    P_RemoveActivePlat_ NEAR
PUBLIC  P_RemoveActivePlat_ 


0x0000000000003a0e:  53                push        bx
0x0000000000003a0f:  51                push        cx
0x0000000000003a10:  52                push        dx
0x0000000000003a11:  56                push        si
0x0000000000003a12:  89 C1             mov         cx, ax
0x0000000000003a14:  30 D2             xor         dl, dl
label_26:
0x0000000000003a16:  88 D0             mov         al, dl
0x0000000000003a18:  98                cbw        
0x0000000000003a19:  89 C3             mov         bx, ax
0x0000000000003a1b:  01 C3             add         bx, ax
0x0000000000003a1d:  8B 87 58 09       mov         ax, word ptr ds:[bx + _activeplats]
0x0000000000003a21:  39 C1             cmp         cx, ax
0x0000000000003a23:  74 0C             je          label_25
0x0000000000003a25:  FE C2             inc         dl
0x0000000000003a27:  80 FA 1E          cmp         dl, MAXPLATS
0x0000000000003a2a:  7C EA             jl          label_26
0x0000000000003a2c:  5E                pop         si
0x0000000000003a2d:  5A                pop         dx
0x0000000000003a2e:  59                pop         cx
0x0000000000003a2f:  5B                pop         bx
0x0000000000003a30:  C3                ret         
label_25:
0x0000000000003a31:  6B F0 2C          imul        si, ax, SIZEOF_THINKER_T
0x0000000000003a34:  81 C6 04 34       add         si, (_thinkerlist + THINKER_T.t_data)
0x0000000000003a38:  8B 34             mov         si, word ptr [si]
0x0000000000003a3b:  E8 00 10          call        P_RemoveThinker_
0x0000000000003a3f:  C1 E6 04          shl         si, 4
0x0000000000003a42:  31 C0             xor         ax, ax
0x0000000000003a44:  89 84 38 DE       mov         word ptr [si + _sectors_physics + SECTOR_PHYSICS_T.secp_special], ax
0x0000000000003a48:  81 C6 38 DE       add         si, _sectors_physics + SECTOR_PHYSICS_T.secp_special
0x0000000000003a4c:  89 87 58 09       mov         word ptr [bx + _activeplats], ax
0x0000000000003a50:  5E                pop         si
0x0000000000003a51:  5A                pop         dx
0x0000000000003a52:  59                pop         cx
0x0000000000003a53:  5B                pop         bx
0x0000000000003a54:  C3                ret  

ENDP


PROC    P_PLATS_ENDMARKER_ NEAR
PUBLIC  P_PLATS_ENDMARKER_
ENDP


END