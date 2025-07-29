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



.DATA




.CODE

MAX_ADJOINING_SECTORS = 256



PROC    P_SPEC_STARTMARKER_ 
PUBLIC  P_SPEC_STARTMARKER_
ENDP


PROC    twoSided_ NEAR
PUBLIC  twoSided_

;int16_t __near twoSided( int16_t	sector,int16_t	line ){

;	line = sectors[sector].linesoffset + line;
;	line = linebuffer[line];
;   return lineflagslist[line] & ML_TWOSIDED;



push      bx
SHIFT_MACRO shl       ax 4
xchg      ax, bx
mov       ax, SECTORS_SEGMENT
mov       es, ax
mov       bx, word ptr es:[bx + SECTOR_T.sec_linesoffset]
add       bx, dx
sal       bx, 1
mov       bx, word ptr ds:[bx + _linebuffer]
mov       ax, LINEFLAGSLIST_SEGMENT
mov       es, ax
mov       al, byte ptr es:[bx]
and       ax, ML_TWOSIDED
pop       bx
ret       

ENDP



; todo make arg 5 this si argument.


;int16_t __near getNextSectorList(int16_t __near * linenums,int16_t	sec,int16_t __near* secnums,int16_t linecount,boolean onlybacksecnums){

PROC    getNextSectorList_  NEAR
PUBLIC  getNextSectorList_



push      si
push      di
push      bp
mov       bp, sp  ; need stack frame due to bp + 8 arg. can be removed later with selfmodify and si param.

mov       di, ax

mov       word ptr cs:[OFFSET SELFMODIFY_pspec_secnum+2], dx
mov       word ptr cs:[OFFSET SELFMODIFY_pspec_subtract_secnums_base+1], bx


mov       ax, LINEFLAGSLIST_SEGMENT
mov       es, ax
mov       ax, LINES_PHYSICS_SEGMENT
mov       ds, ax

xor       ax, ax   ; ax stores i

test      cx, cx
jle       done_iterating_over_linecount
loop_next_line:
mov       si, word ptr ss:[di]

test      byte ptr es:[si], ML_TWOSIDED
jne       found_sector_opening
dec       bx
dec       bx  
do_next_line:
inc       ax
inc       di
inc       di
inc       bx
inc       bx ; secnums
cmp       ax, cx
jl        loop_next_line
done_iterating_over_linecount:


;	return linecount - skipped. which is the bx index because i == linecount and loopend and bx is i - skipped

xchg      ax, bx   
SELFMODIFY_pspec_subtract_secnums_base:
sub       ax, 01000h  ; remove array base
sar       ax, 1       ; undo word ptr shift



mov       dx, ss
mov       ds, dx  ; restore ds
LEAVE_MACRO     
pop       di
pop       si
ret       2

found_sector_opening:

;		line_physics = &lines_physics[linenums[i]];

SHIFT_MACRO shl       si, 4
; bx already has ptr.

mov       dx, word ptr ds:[si + LINE_PHYSICS_T.lp_frontsecnum]
SELFMODIFY_pspec_secnum:
cmp       dx, 01000h
jne       not_frontsecnum
push      word ptr ds:[si + LINE_PHYSICS_T.lp_backsecnum]
pop       word ptr ss:[bx]
jmp       do_next_line

not_frontsecnum:
cmp       byte ptr [bp + 8], 0  ;only_backsecnums check
jne       do_next_line
mov       word ptr ss:[bx], dx
jmp       do_next_line

ENDP

;short_height_t __near P_FindHighestOrLowestFloorSurrounding(int16_t secnum, int8_t isHigh){

JGE_OPCODE = 07Dh
JLE_OPCODE = 07Eh

PROC    P_FindHighestOrLowestFloorSurrounding_  NEAR
PUBLIC  P_FindHighestOrLowestFloorSurrounding_

; bp - 0200h secnumlist
; bp - 0400h linebufferlines

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4 * MAX_ADJOINING_SECTORS  ; 400

mov       cx, ax
xchg      ax, bx
SHIFT_MACRO shl       bx 4
mov       ax, SECTORS_SEGMENT
mov       es, ax

lea       di, [bp - 0400h]
mov       si, word ptr es:[bx + SECTOR_T.sec_linesoffset]
mov       ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
mov       dh, JGE_OPCODE
cmp       dl, 0 ; ishigh check
je        done_with_floorheight
mov       ax, 0F060h  ;   (-500 SHL 3); -500 << SHORTFLOORBITS 0xf060
mov       dh, JLE_OPCODE
done_with_floorheight:
mov       byte ptr cs:[OFFSET SELFMODIFY_ishigh_jle_jge], dh

mov       dx, cx  ; dx gets secnum for func call.

mov       bx, word ptr es:[bx + SECTOR_T.sec_linecount]
sal       si, 1
mov       cx, bx
add       si, OFFSET _linebuffer


;	memcpy(linebufferlines, &linebuffer[offset], linecount << 1);
push      ds
pop       es
rep movsw 

xchg      ax, di   ; di stores floorheight


push      cx  ; should be 0. false parameter. todo move to si...?
; dx already has secnum...
mov       cx, bx
lea       bx, [bp - 0200h]
lea       ax, [bp - 0400h]

;	linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);

call      getNextSectorList_


mov       cx, ax
jcxz      skip_loop
lea       si, [bp - 0200h]

mov       dx, SECTORS_SEGMENT
mov       es, dx


loop_next_sector:
lodsw   ; inc si 2

xchg      ax, bx
SHIFT_MACRO shl       bx 4

mov       ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
cmp       ax, di
SELFMODIFY_ishigh_jle_jge:   ;    use jle if ishigh false. use jge if ishigh true
jle       dont_update_floorheight
mov       di, ax
dont_update_floorheight:

loop      loop_next_sector

skip_loop:
xchg      ax, di
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       


ENDP

COMMENT @


PROC    P_FindNextHighestFloor_  NEAR
PUBLIC  P_FindNextHighestFloor_

0x0000000000004728:  53                push      bx
0x0000000000004729:  51                push      cx
0x000000000000472a:  56                push      si
0x000000000000472b:  57                push      di
0x000000000000472c:  55                push      bp
0x000000000000472d:  89 E5             mov       bp, sp
0x000000000000472f:  81 EC 04 06       sub       sp, 0x604
0x0000000000004733:  50                push      ax
0x0000000000004734:  52                push      dx
0x0000000000004735:  BA 90 21          mov       dx, SECTORS_SEGMENT
0x0000000000004738:  8D BE FC FD       lea       di, [bp - 0204h]
0x000000000000473c:  C1 E0 04          shl       ax, 4
0x000000000000473f:  8E C2             mov       es, dx
0x0000000000004741:  89 C3             mov       bx, ax
0x0000000000004743:  8B 96 F8 F9       mov       dx, word ptr [bp - 0x608]
0x0000000000004747:  26 8B 77 0C       mov       si, word ptr es:[bx + 0xc]
0x000000000000474b:  83 C3 0C          add       bx, 0xc
0x000000000000474e:  89 56 FC          mov       word ptr [bp - 4], dx
0x0000000000004751:  89 C3             mov       bx, ax
0x0000000000004753:  01 F6             add       si, si
0x0000000000004755:  8B 96 FA F9       mov       dx, word ptr [bp - 0x606]
0x0000000000004759:  26 8B 47 0A       mov       ax, word ptr es:[bx + 0xa]
0x000000000000475d:  83 C3 0A          add       bx, 0xa
0x0000000000004760:  81 C6 50 CA       add       si, OFFSET _linebuffer
0x0000000000004764:  89 C1             mov       cx, ax
0x0000000000004766:  8D 9E FC F9       lea       bx, [bp - 0x604]
0x000000000000476a:  01 C1             add       cx, ax
0x000000000000476c:  89 46 FE          mov       word ptr [bp - 2], ax
0x000000000000476f:  57                push      di
0x0000000000004770:  8C D8             mov       ax, ds
0x0000000000004772:  8E C0             mov       es, ax
0x0000000000004774:  D1 E9             shr       cx, 1
0x0000000000004776:  F3 A5             rep movsw 
0x0000000000004778:  13 C9             adc       cx, cx
0x000000000000477a:  F3 A4             rep movsb 
0x000000000000477c:  5F                pop       di
0x000000000000477d:  6A 00             push      0
0x000000000000477f:  8B 4E FE          mov       cx, word ptr [bp - 2]
0x0000000000004782:  8D 86 FC FD       lea       ax, [bp - 0204h]
0x0000000000004786:  E8 83 FE          call      getNextSectorList_
0x0000000000004789:  31 F6             xor       si, si
0x000000000000478b:  89 46 FE          mov       word ptr [bp - 2], ax
0x000000000000478e:  30 C9             xor       cl, cl
0x0000000000004790:  31 D2             xor       dx, dx
0x0000000000004792:  88 C8             mov       al, cl
0x0000000000004794:  30 E4             xor       ah, ah
0x0000000000004796:  3B 46 FE          cmp       ax, word ptr [bp - 2]
0x0000000000004799:  7D 26             jge       0x47c1
0x000000000000479b:  89 C7             mov       di, ax
0x000000000000479d:  01 C7             add       di, ax
0x000000000000479f:  8B 9B FC F9       mov       bx, word ptr [bp + di - 0x604]
0x00000000000047a3:  B8 90 21          mov       ax, SECTORS_SEGMENT
0x00000000000047a6:  C1 E3 04          shl       bx, 4
0x00000000000047a9:  8E C0             mov       es, ax
0x00000000000047ab:  26 8B 07          mov       ax, word ptr es:[bx]
0x00000000000047ae:  3B 46 FC          cmp       ax, word ptr [bp - 4]
0x00000000000047b1:  7F 04             jg        0x47b7
0x00000000000047b3:  FE C1             inc       cl
0x00000000000047b5:  EB DB             jmp       0x4792
0x00000000000047b7:  83 C6 02          add       si, 2
0x00000000000047ba:  42                inc       dx
0x00000000000047bb:  89 82 FA FB       mov       word ptr [bp + si - 0x406], ax
0x00000000000047bf:  EB F2             jmp       0x47b3
0x00000000000047c1:  85 D2             test      dx, dx
0x00000000000047c3:  74 1E             je        0x47e3
0x00000000000047c5:  8B BE FC FB       mov       di, word ptr [bp - 0404h]
0x00000000000047c9:  B3 01             mov       bl, 1
0x00000000000047cb:  88 D8             mov       al, bl
0x00000000000047cd:  30 E4             xor       ah, ah
0x00000000000047cf:  39 D0             cmp       ax, dx
0x00000000000047d1:  7D 1E             jge       0x47f1
0x00000000000047d3:  89 C6             mov       si, ax
0x00000000000047d5:  01 C6             add       si, ax
0x00000000000047d7:  8B 82 FC FB       mov       ax, word ptr [bp + si - 0404h]
0x00000000000047db:  39 C7             cmp       di, ax
0x00000000000047dd:  7F 0E             jg        0x47ed
0x00000000000047df:  FE C3             inc       bl
0x00000000000047e1:  EB E8             jmp       0x47cb
0x00000000000047e3:  8B 86 F8 F9       mov       ax, word ptr [bp - 0x608]
0x00000000000047e7:  C9                LEAVE_MACRO     
0x00000000000047e8:  5F                pop       di
0x00000000000047e9:  5E                pop       si
0x00000000000047ea:  59                pop       cx
0x00000000000047eb:  5B                pop       bx
0x00000000000047ec:  C3                ret       
0x00000000000047ed:  89 C7             mov       di, ax
0x00000000000047ef:  EB EE             jmp       0x47df
0x00000000000047f1:  89 F8             mov       ax, di
0x00000000000047f3:  C9                LEAVE_MACRO     
0x00000000000047f4:  5F                pop       di
0x00000000000047f5:  5E                pop       si
0x00000000000047f6:  59                pop       cx
0x00000000000047f7:  5B                pop       bx
0x00000000000047f8:  C3                ret       
ENDP

PROC    P_FindLowestOrHighestCeilingSurrounding_  NEAR
PUBLIC  P_FindLowestOrHighestCeilingSurrounding_

0x00000000000047fa:  53                push      bx
0x00000000000047fb:  51                push      cx
0x00000000000047fc:  56                push      si
0x00000000000047fd:  57                push      di
0x00000000000047fe:  55                push      bp
0x00000000000047ff:  89 E5             mov       bp, sp
0x0000000000004801:  81 EC 06 04       sub       sp, 0x406
0x0000000000004805:  50                push      ax
0x0000000000004806:  88 56 FE          mov       byte ptr [bp - 2], dl
0x0000000000004809:  84 D2             test      dl, dl
0x000000000000480b:  75 03             jne       0x4810
0x000000000000480d:  E9 8C 00          jmp       0x489c
0x0000000000004810:  31 C0             xor       ax, ax
0x0000000000004812:  89 46 FC          mov       word ptr [bp - 4], ax
0x0000000000004815:  8B 86 F8 FB       mov       ax, word ptr [bp - 0x408]
0x0000000000004819:  BB 90 21          mov       bx, SECTORS_SEGMENT
0x000000000000481c:  C1 E0 04          shl       ax, 4
0x000000000000481f:  8E C3             mov       es, bx
0x0000000000004821:  89 C3             mov       bx, ax
0x0000000000004823:  8D BE FA FD       lea       di, [bp - 0x206]
0x0000000000004827:  83 C3 0C          add       bx, 0xc
0x000000000000482a:  8B 96 F8 FB       mov       dx, word ptr [bp - 0x408]
0x000000000000482e:  26 8B 37          mov       si, word ptr es:[bx]
0x0000000000004831:  89 C3             mov       bx, ax
0x0000000000004833:  01 F6             add       si, si
0x0000000000004835:  26 8B 47 0A       mov       ax, word ptr es:[bx + 0xa]
0x0000000000004839:  83 C3 0A          add       bx, 0xa
0x000000000000483c:  81 C6 50 CA       add       si, OFFSET _linebuffer
0x0000000000004840:  89 C1             mov       cx, ax
0x0000000000004842:  8D 9E FA FB       lea       bx, [bp - 0x406]
0x0000000000004846:  01 C1             add       cx, ax
0x0000000000004848:  89 46 FA          mov       word ptr [bp - 6], ax
0x000000000000484b:  57                push      di
0x000000000000484c:  8C D8             mov       ax, ds
0x000000000000484e:  8E C0             mov       es, ax
0x0000000000004850:  D1 E9             shr       cx, 1
0x0000000000004852:  F3 A5             rep movsw 
0x0000000000004854:  13 C9             adc       cx, cx
0x0000000000004856:  F3 A4             rep movsb 
0x0000000000004858:  5F                pop       di
0x0000000000004859:  6A 00             push      0
0x000000000000485b:  8B 4E FA          mov       cx, word ptr [bp - 6]
0x000000000000485e:  8D 86 FA FD       lea       ax, [bp - 0x206]
0x0000000000004862:  E8 A7 FD          call      getNextSectorList_
0x0000000000004865:  89 46 FA          mov       word ptr [bp - 6], ax
0x0000000000004868:  30 D2             xor       dl, dl
0x000000000000486a:  88 D0             mov       al, dl
0x000000000000486c:  30 E4             xor       ah, ah
0x000000000000486e:  3B 46 FA          cmp       ax, word ptr [bp - 6]
0x0000000000004871:  7C 03             jl        0x4876
0x0000000000004873:  E9 99 FE          jmp       0x470f
0x0000000000004876:  89 C6             mov       si, ax
0x0000000000004878:  01 C6             add       si, ax
0x000000000000487a:  8B 9A FA FB       mov       bx, word ptr [bp + si - 0x406]
0x000000000000487e:  C1 E3 04          shl       bx, 4
0x0000000000004881:  80 7E FE 00       cmp       byte ptr [bp - 2], 0
0x0000000000004885:  74 20             je        0x48a7
0x0000000000004887:  B8 90 21          mov       ax, SECTORS_SEGMENT
0x000000000000488a:  8E C0             mov       es, ax
0x000000000000488c:  26 8B 47 02       mov       ax, word ptr es:[bx + 2]
0x0000000000004890:  83 C3 02          add       bx, 2
0x0000000000004893:  3B 46 FC          cmp       ax, word ptr [bp - 4]
0x0000000000004896:  7F 0A             jg        0x48a2
0x0000000000004898:  FE C2             inc       dl
0x000000000000489a:  EB CE             jmp       0x486a
0x000000000000489c:  B8 FF 7F          mov       ax, 0x7fff
0x000000000000489f:  E9 70 FF          jmp       0x4812
0x00000000000048a2:  89 46 FC          mov       word ptr [bp - 4], ax
0x00000000000048a5:  EB F1             jmp       0x4898
0x00000000000048a7:  B8 90 21          mov       ax, SECTORS_SEGMENT
0x00000000000048aa:  8E C0             mov       es, ax
0x00000000000048ac:  26 8B 47 02       mov       ax, word ptr es:[bx + 2]
0x00000000000048b0:  83 C3 02          add       bx, 2
0x00000000000048b3:  3B 46 FC          cmp       ax, word ptr [bp - 4]
0x00000000000048b6:  7D E0             jge       0x4898
0x00000000000048b8:  89 46 FC          mov       word ptr [bp - 4], ax
0x00000000000048bb:  FE C2             inc       dl
0x00000000000048bd:  EB AB             jmp       0x486a
ENDP

PROC    P_FindSectorsFromLineTag_  NEAR
PUBLIC  P_FindSectorsFromLineTag_

0x00000000000048c0:  51                push      cx
0x00000000000048c1:  56                push      si
0x00000000000048c2:  57                push      di
0x00000000000048c3:  55                push      bp
0x00000000000048c4:  89 E5             mov       bp, sp
0x00000000000048c6:  83 EC 0A          sub       sp, 0xa
0x00000000000048c9:  88 46 FC          mov       byte ptr [bp - 4], al
0x00000000000048cc:  89 56 FA          mov       word ptr [bp - 6], dx
0x00000000000048cf:  88 5E FE          mov       byte ptr [bp - 2], bl
0x00000000000048d2:  8B 76 FA          mov       si, word ptr [bp - 6]
0x00000000000048d5:  31 FF             xor       di, di
0x00000000000048d7:  31 D2             xor       dx, dx
0x00000000000048d9:  31 C9             xor       cx, cx
0x00000000000048db:  BB CE 05          mov       bx, 0x5ce
0x00000000000048de:  3B 17             cmp       dx, word ptr ds:[bx]
0x00000000000048e0:  7D 3C             jge       0x491e
0x00000000000048e2:  89 CB             mov       bx, cx
0x00000000000048e4:  C7 46 F8 00 00    mov       word ptr [bp - 8], 0
0x00000000000048e9:  81 C3 3F DE       add       bx, 0xde3f
0x00000000000048ed:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x00000000000048f0:  8A 1F             mov       bl, byte ptr [bx]
0x00000000000048f2:  98                cwde      
0x00000000000048f3:  30 FF             xor       bh, bh
0x00000000000048f5:  89 4E F6          mov       word ptr [bp - 0xa], cx
0x00000000000048f8:  39 C3             cmp       bx, ax
0x00000000000048fa:  74 06             je        0x4902
0x00000000000048fc:  83 C1 10          add       cx, 0x10
0x00000000000048ff:  42                inc       dx
0x0000000000004900:  EB D9             jmp       0x48db
0x0000000000004902:  80 7E FE 00       cmp       byte ptr [bp - 2], 0
0x0000000000004906:  74 09             je        0x4911
0x0000000000004908:  83 C6 02          add       si, 2
0x000000000000490b:  47                inc       di
0x000000000000490c:  89 54 FE          mov       word ptr ds:[si - 2], dx
0x000000000000490f:  EB EB             jmp       0x48fc
0x0000000000004911:  89 CB             mov       bx, cx
0x0000000000004913:  81 C3 38 DE       add       bx, 0xde38
0x0000000000004917:  83 3F 00          cmp       word ptr ds:[bx], 0
0x000000000000491a:  74 EC             je        0x4908
0x000000000000491c:  EB DE             jmp       0x48fc
0x000000000000491e:  89 FB             mov       bx, di
0x0000000000004920:  01 FB             add       bx, di
0x0000000000004922:  03 5E FA          add       bx, word ptr [bp - 6]
0x0000000000004925:  C7 07 FF FF       mov       word ptr ds:[bx], 0xffff
0x0000000000004929:  C9                LEAVE_MACRO     
0x000000000000492a:  5F                pop       di
0x000000000000492b:  5E                pop       si
0x000000000000492c:  59                pop       cx
0x000000000000492d:  C3                ret       
ENDP

PROC    P_FindMinSurroundingLight_  NEAR
PUBLIC  P_FindMinSurroundingLight_

0x000000000000492e:  53                push      bx
0x000000000000492f:  51                push      cx
0x0000000000004930:  56                push      si
0x0000000000004931:  57                push      di
0x0000000000004932:  55                push      bp
0x0000000000004933:  89 E5             mov       bp, sp
0x0000000000004935:  81 EC 04 04       sub       sp, 0404h
0x0000000000004939:  50                push      ax
0x000000000000493a:  88 56 FE          mov       byte ptr [bp - 2], dl
0x000000000000493d:  BA 90 21          mov       dx, SECTORS_SEGMENT
0x0000000000004940:  C1 E0 04          shl       ax, 4
0x0000000000004943:  8D BE FC FD       lea       di, [bp - 0204h]
0x0000000000004947:  89 C3             mov       bx, ax
0x0000000000004949:  8E C2             mov       es, dx
0x000000000000494b:  83 C3 0C          add       bx, 0xc
0x000000000000494e:  8B 96 FA FB       mov       dx, word ptr [bp - 0x406]
0x0000000000004952:  26 8B 37          mov       si, word ptr es:[bx]
0x0000000000004955:  89 C3             mov       bx, ax
0x0000000000004957:  01 F6             add       si, si
0x0000000000004959:  26 8B 47 0A       mov       ax, word ptr es:[bx + 0xa]
0x000000000000495d:  83 C3 0A          add       bx, 0xa
0x0000000000004960:  81 C6 50 CA       add       si, OFFSET _linebuffer
0x0000000000004964:  89 C1             mov       cx, ax
0x0000000000004966:  8D 9E FC FB       lea       bx, [bp - 0404h]
0x000000000000496a:  01 C1             add       cx, ax
0x000000000000496c:  89 46 FC          mov       word ptr [bp - 4], ax
0x000000000000496f:  57                push      di
0x0000000000004970:  8C D8             mov       ax, ds
0x0000000000004972:  8E C0             mov       es, ax
0x0000000000004974:  D1 E9             shr       cx, 1
0x0000000000004976:  F3 A5             rep movsw 
0x0000000000004978:  13 C9             adc       cx, cx
0x000000000000497a:  F3 A4             rep movsb 
0x000000000000497c:  5F                pop       di
0x000000000000497d:  6A 00             push      0
0x000000000000497f:  8B 4E FC          mov       cx, word ptr [bp - 4]
0x0000000000004982:  8D 86 FC FD       lea       ax, [bp - 0204h]
0x0000000000004986:  E8 83 FC          call      getNextSectorList_
0x0000000000004989:  8A 76 FE          mov       dh, byte ptr [bp - 2]
0x000000000000498c:  89 46 FC          mov       word ptr [bp - 4], ax
0x000000000000498f:  30 D2             xor       dl, dl
0x0000000000004991:  88 D0             mov       al, dl
0x0000000000004993:  30 E4             xor       ah, ah
0x0000000000004995:  3B 46 FC          cmp       ax, word ptr [bp - 4]
0x0000000000004998:  7D 25             jge       0x49bf
0x000000000000499a:  89 C6             mov       si, ax
0x000000000000499c:  01 C6             add       si, ax
0x000000000000499e:  8B 82 FC FB       mov       ax, word ptr [bp + si - 0404h]
0x00000000000049a2:  BB 90 21          mov       bx, SECTORS_SEGMENT
0x00000000000049a5:  C1 E0 04          shl       ax, 4
0x00000000000049a8:  8E C3             mov       es, bx
0x00000000000049aa:  89 C3             mov       bx, ax
0x00000000000049ac:  26 8A 47 0E       mov       al, byte ptr es:[bx + 0xe]
0x00000000000049b0:  83 C3 0E          add       bx, 0xe
0x00000000000049b3:  38 C6             cmp       dh, al
0x00000000000049b5:  77 04             ja        0x49bb
0x00000000000049b7:  FE C2             inc       dl
0x00000000000049b9:  EB D6             jmp       0x4991
0x00000000000049bb:  88 C6             mov       dh, al
0x00000000000049bd:  EB F8             jmp       0x49b7
0x00000000000049bf:  88 F0             mov       al, dh
0x00000000000049c1:  C9                LEAVE_MACRO     
0x00000000000049c2:  5F                pop       di
0x00000000000049c3:  5E                pop       si
0x00000000000049c4:  59                pop       cx
0x00000000000049c5:  5B                pop       bx
0x00000000000049c6:  C3                ret       

ENDP

dw 04B46h, 04BABh, 04BB2h, 04BB8h, 04BD1h, 04D71h, 04BE3h, 04D71h, 04BF4h, 04D71h, 04C0Eh 
dw 04C26h, 04D71h, 04D71h, 04C3Fh, 04C47h, 04D71h, 04C56h, 04D71h, 04D71h, 04C6Fh, 04D71h 
dw 04D71h, 04C87h, 04D71h, 04D71h, 04D71h, 04D71h, 04C99h, 04D71h, 04D71h, 04D71h, 04D71h 
dw 04CB3h, 04CCCh, 04CE6h, 04D00h, 04D1Ah, 04D33h, 04D71h, 04D71h, 04D71h, 04D5Ah, 04D71h
dw 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D6Ch, 04D81h, 04D96h, 04D71h, 04DA8h
dw 04DC2h, 04DD1h, 04DEBh, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h
dw 04D71h, 04D71h, 04D71h, 04D71h, 04ECEh, 04EDBh, 04EE8h, 04EF2h, 04F01h, 04F10h, 04D71h
dw 04F1Dh, 04F2Fh, 04F40h, 04F52h, 04F67h, 04F7Bh, 04D71h, 04F90h, 04F9Fh, 04FB1h, 04FC6h
dw 04FD3h, 04FE1h, 04FF4h, 05007h, 0501Ah, 0502Dh, 05044h, 05057h, 0506Bh, 04D71h, 04E2Ch
dw 04D71h, 04D71h, 04D71h, 04E05h, 0507Eh, 0508Dh, 0509Ch, 04E18h, 04E22h, 04E3Eh, 04D71h
dw 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04E48h, 050ABh, 04E60h, 04D71h
dw 04D71h, 04E7Ch, 04E84h, 050C2h, 04D71h, 050DDh, 050F0h, 04EA4h, 04D71h, 04D71h, 04D71h
dw 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04D71h, 04EBCh

PROC    P_CrossSpecialLine_  NEAR
PUBLIC  P_CrossSpecialLine_

0x0000000000004ae0:  51                   push      cx
0x0000000000004ae1:  56                   push      si
0x0000000000004ae2:  57                   push      di
0x0000000000004ae3:  55                   push      bp
0x0000000000004ae4:  89 E5                mov       bp, sp
0x0000000000004ae6:  83 EC 08             sub       sp, 8
0x0000000000004ae9:  50                   push      ax
0x0000000000004aea:  89 D1                mov       cx, dx
0x0000000000004aec:  89 DE                mov       si, bx
0x0000000000004aee:  BF 0A 00             mov       di, 0xa
0x0000000000004af1:  C7 46 FC FF FF       mov       word ptr [bp - 4], 0xffff
0x0000000000004af6:  89 C2                mov       dx, ax
0x0000000000004af8:  B8 00 70             mov       ax, 0x7000
0x0000000000004afb:  C1 E2 04             shl       dx, 4
0x0000000000004afe:  89 46 FA             mov       word ptr [bp - 6], ax
0x0000000000004b01:  89 56 F8             mov       word ptr [bp - 8], dx
0x0000000000004b04:  8E C0                mov       es, ax
0x0000000000004b06:  89 D3                mov       bx, dx
0x0000000000004b08:  26 8B 05             mov       ax, word ptr es:[di]
0x0000000000004b0b:  89 D7                mov       di, dx
0x0000000000004b0d:  26 8A 5F 0E          mov       bl, byte ptr es:[bx + 0xe]
0x0000000000004b11:  26 8A 55 0F          mov       dl, byte ptr es:[di + 0xf]
0x0000000000004b15:  8A 7C 1A             mov       bh, byte ptr [si + 0x1a]
0x0000000000004b18:  30 F6                xor       dh, dh
0x0000000000004b1a:  84 FF                test      bh, bh
0x0000000000004b1c:  74 16                je        0x4b34
0x0000000000004b1e:  80 FF 1F             cmp       bh, 0x1f
0x0000000000004b21:  73 4E                jae       0x4b71
0x0000000000004b23:  80 FF 10             cmp       bh, 0x10
0x0000000000004b26:  74 42                je        0x4b6a
0x0000000000004b28:  31 FF                xor       di, di
0x0000000000004b2a:  83 FA 27             cmp       dx, 0x27
0x0000000000004b2d:  73 4E                jae       0x4b7d
0x0000000000004b2f:  83 FA 0A             cmp       dx, 0xa
0x0000000000004b32:  75 5B                jne       0x4b8f
0x0000000000004b34:  83 EA 02             sub       dx, 2
0x0000000000004b37:  81 FA 8B 00          cmp       dx, 0x8b
0x0000000000004b3b:  77 54                ja        0x4b91
0x0000000000004b3d:  89 D7                mov       di, dx
0x0000000000004b3f:  01 D7                add       di, dx
0x0000000000004b41:  2E FF A5 C8 49       jmp       word ptr cs:[di + 0x49c8]
0x0000000000004b46:  30 FF                xor       bh, bh
0x0000000000004b48:  BA 03 00             mov       dx, 3
0x0000000000004b4b:  89 D8                mov       ax, bx
0x0000000000004b4d:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004b52:  0E                   push      cs
0x0000000000004b53:  E8 48 D9             call      0x249e
0x0000000000004b56:  90                   nop       
0x0000000000004b57:  8B 5E F6             mov       bx, word ptr [bp - 0xa]
0x0000000000004b5a:  C1 E3 04             shl       bx, 4
0x0000000000004b5d:  8E 46 FA             mov       es, word ptr [bp - 6]
0x0000000000004b60:  03 5E F8             add       bx, word ptr [bp - 8]
0x0000000000004b63:  8A 46 FC             mov       al, byte ptr [bp - 4]
0x0000000000004b66:  26 88 47 0F          mov       byte ptr es:[bx + 0xf], al
0x0000000000004b6a:  C9                   LEAVE_MACRO     
0x0000000000004b6b:  5F                   pop       di
0x0000000000004b6c:  5E                   pop       si
0x0000000000004b6d:  59                   pop       cx
0x0000000000004b6e:  CA 04 00             retf      4
0x0000000000004b71:  80 FF 20             cmp       bh, 0x20
0x0000000000004b74:  76 F4                jbe       0x4b6a
0x0000000000004b76:  80 FF 23             cmp       bh, 0x23
0x0000000000004b79:  76 EF                jbe       0x4b6a
0x0000000000004b7b:  EB AB                jmp       0x4b28
0x0000000000004b7d:  76 B5                jbe       0x4b34
0x0000000000004b7f:  83 FA 61             cmp       dx, 0x61
0x0000000000004b82:  73 10                jae       0x4b94
0x0000000000004b84:  83 FA 58             cmp       dx, 0x58
0x0000000000004b87:  74 AB                je        0x4b34
0x0000000000004b89:  85 FF                test      di, di
0x0000000000004b8b:  74 DD                je        0x4b6a
0x0000000000004b8d:  EB A5                jmp       0x4b34
0x0000000000004b8f:  EB 15                jmp       0x4ba6
0x0000000000004b91:  E9 DD 01             jmp       0x4d71
0x0000000000004b94:  76 9E                jbe       0x4b34
0x0000000000004b96:  83 FA 7D             cmp       dx, 0x7d
0x0000000000004b99:  72 EE                jb        0x4b89
0x0000000000004b9b:  83 FA 7E             cmp       dx, 0x7e
0x0000000000004b9e:  76 94                jbe       0x4b34
0x0000000000004ba0:  85 FF                test      di, di
0x0000000000004ba2:  74 C6                je        0x4b6a
0x0000000000004ba4:  EB 8E                jmp       0x4b34
0x0000000000004ba6:  83 FA 04             cmp       dx, 4
0x0000000000004ba9:  EB DC                jmp       0x4b87
0x0000000000004bab:  30 FF                xor       bh, bh
0x0000000000004bad:  BA 02 00             mov       dx, 2
0x0000000000004bb0:  EB 99                jmp       0x4b4b
0x0000000000004bb2:  30 FF                xor       bh, bh
0x0000000000004bb4:  31 D2                xor       dx, dx
0x0000000000004bb6:  EB 93                jmp       0x4b4b
0x0000000000004bb8:  BA 03 00             mov       dx, 3
0x0000000000004bbb:  30 FF                xor       bh, bh
0x0000000000004bbd:  89 C1                mov       cx, ax
0x0000000000004bbf:  89 D8                mov       ax, bx
0x0000000000004bc1:  89 D3                mov       bx, dx
0x0000000000004bc3:  89 CA                mov       dx, cx
0x0000000000004bc5:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004bca:  0E                   push      cs
0x0000000000004bcb:  E8 D6 DF             call      0x2ba4
0x0000000000004bce:  90                   nop       
0x0000000000004bcf:  EB 86                jmp       0x4b57
0x0000000000004bd1:  30 FF                xor       bh, bh
0x0000000000004bd3:  BA 04 00             mov       dx, 4
0x0000000000004bd6:  89 D8                mov       ax, bx
0x0000000000004bd8:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004bdd:  E8 DC D3             call      0x1fbc
0x0000000000004be0:  E9 74 FF             jmp       0x4b57
0x0000000000004be3:  30 FF                xor       bh, bh
0x0000000000004be5:  31 D2                xor       dx, dx
0x0000000000004be7:  89 D8                mov       ax, bx
0x0000000000004be9:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004bee:  E8 43 E3             call      0x2f34
0x0000000000004bf1:  E9 63 FF             jmp       0x4b57
0x0000000000004bf4:  BA 01 00             mov       dx, 1
0x0000000000004bf7:  30 FF                xor       bh, bh
0x0000000000004bf9:  31 C9                xor       cx, cx
0x0000000000004bfb:  89 DE                mov       si, bx
0x0000000000004bfd:  89 D3                mov       bx, dx
0x0000000000004bff:  89 C2                mov       dx, ax
0x0000000000004c01:  89 F0                mov       ax, si
0x0000000000004c03:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004c08:  E8 E3 F6             call      0x42ee
0x0000000000004c0b:  E9 49 FF             jmp       0x4b57
0x0000000000004c0e:  BA 01 00             mov       dx, 1
0x0000000000004c11:  30 FF                xor       bh, bh
0x0000000000004c13:  31 C0                xor       ax, ax
0x0000000000004c15:  89 D9                mov       cx, bx
0x0000000000004c17:  89 C3                mov       bx, ax
0x0000000000004c19:  89 C8                mov       ax, cx
0x0000000000004c1b:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004c20:  E8 0D F4             call      0x4030
0x0000000000004c23:  E9 31 FF             jmp       0x4b57
0x0000000000004c26:  B8 FF 00             mov       ax, 0xff
0x0000000000004c29:  30 FF                xor       bh, bh
0x0000000000004c2b:  BA 01 00             mov       dx, 1
0x0000000000004c2e:  89 D9                mov       cx, bx
0x0000000000004c30:  89 C3                mov       bx, ax
0x0000000000004c32:  89 C8                mov       ax, cx
0x0000000000004c34:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004c39:  E8 F4 F3             call      0x4030
0x0000000000004c3c:  E9 18 FF             jmp       0x4b57
0x0000000000004c3f:  30 FF                xor       bh, bh
0x0000000000004c41:  BA 01 00             mov       dx, 1
0x0000000000004c44:  E9 04 FF             jmp       0x4b4b
0x0000000000004c47:  30 FF                xor       bh, bh
0x0000000000004c49:  89 D8                mov       ax, bx
0x0000000000004c4b:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004c50:  E8 A5 F3             call      0x3ff8
0x0000000000004c53:  E9 01 FF             jmp       0x4b57
0x0000000000004c56:  89 C1                mov       cx, ax
0x0000000000004c58:  30 FF                xor       bh, bh
0x0000000000004c5a:  31 D2                xor       dx, dx
0x0000000000004c5c:  89 D8                mov       ax, bx
0x0000000000004c5e:  89 D3                mov       bx, dx
0x0000000000004c60:  89 CA                mov       dx, cx
0x0000000000004c62:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004c67:  0E                   push      cs
0x0000000000004c68:  3E E8 38 DF          call      0x2ba4
0x0000000000004c6c:  E9 E8 FE             jmp       0x4b57
0x0000000000004c6f:  BE 03 00             mov       si, 3
0x0000000000004c72:  89 C2                mov       dx, ax
0x0000000000004c74:  30 FF                xor       bh, bh
0x0000000000004c76:  31 C9                xor       cx, cx
0x0000000000004c78:  89 D8                mov       ax, bx
0x0000000000004c7a:  89 F3                mov       bx, si
0x0000000000004c7c:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004c81:  E8 6A F6             call      0x42ee
0x0000000000004c84:  E9 D0 FE             jmp       0x4b57
0x0000000000004c87:  30 FF                xor       bh, bh
0x0000000000004c89:  BA 03 00             mov       dx, 3
0x0000000000004c8c:  89 D8                mov       ax, bx
0x0000000000004c8e:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004c93:  E8 26 D3             call      0x1fbc
0x0000000000004c96:  E9 BE FE             jmp       0x4b57
0x0000000000004c99:  BA 05 00             mov       dx, 5
0x0000000000004c9c:  30 FF                xor       bh, bh
0x0000000000004c9e:  89 C1                mov       cx, ax
0x0000000000004ca0:  89 D8                mov       ax, bx
0x0000000000004ca2:  89 D3                mov       bx, dx
0x0000000000004ca4:  89 CA                mov       dx, cx
0x0000000000004ca6:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004cab:  0E                   push      cs
0x0000000000004cac:  3E E8 F4 DE          call      0x2ba4
0x0000000000004cb0:  E9 A4 FE             jmp       0x4b57
0x0000000000004cb3:  B8 23 00             mov       ax, 0x23
0x0000000000004cb6:  30 FF                xor       bh, bh
0x0000000000004cb8:  BA 01 00             mov       dx, 1
0x0000000000004cbb:  89 D9                mov       cx, bx
0x0000000000004cbd:  89 C3                mov       bx, ax
0x0000000000004cbf:  89 C8                mov       ax, cx
0x0000000000004cc1:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004cc6:  E8 67 F3             call      0x4030
0x0000000000004cc9:  E9 8B FE             jmp       0x4b57
0x0000000000004ccc:  30 FF                xor       bh, bh
0x0000000000004cce:  BA 02 00             mov       dx, 2
0x0000000000004cd1:  89 D9                mov       cx, bx
0x0000000000004cd3:  89 D3                mov       bx, dx
0x0000000000004cd5:  89 C2                mov       dx, ax
0x0000000000004cd7:  89 C8                mov       ax, cx
0x0000000000004cd9:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004cde:  0E                   push      cs
0x0000000000004cdf:  E8 C2 DE             call      0x2ba4
0x0000000000004ce2:  90                   nop       
0x0000000000004ce3:  E9 71 FE             jmp       0x4b57
0x0000000000004ce6:  30 FF                xor       bh, bh
0x0000000000004ce8:  BA 06 00             mov       dx, 6
0x0000000000004ceb:  89 D9                mov       cx, bx
0x0000000000004ced:  89 D3                mov       bx, dx
0x0000000000004cef:  89 C2                mov       dx, ax
0x0000000000004cf1:  89 C8                mov       ax, cx
0x0000000000004cf3:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004cf8:  0E                   push      cs
0x0000000000004cf9:  E8 A8 DE             call      0x2ba4
0x0000000000004cfc:  90                   nop       
0x0000000000004cfd:  E9 57 FE             jmp       0x4b57
0x0000000000004d00:  30 FF                xor       bh, bh
0x0000000000004d02:  BA 01 00             mov       dx, 1
0x0000000000004d05:  89 D9                mov       cx, bx
0x0000000000004d07:  89 D3                mov       bx, dx
0x0000000000004d09:  89 C2                mov       dx, ax
0x0000000000004d0b:  89 C8                mov       ax, cx
0x0000000000004d0d:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004d12:  0E                   push      cs
0x0000000000004d13:  E8 8E DE             call      0x2ba4
0x0000000000004d16:  90                   nop       
0x0000000000004d17:  E9 3D FE             jmp       0x4b57
0x0000000000004d1a:  FF 76 0E             push      word ptr [bp + 0xe]
0x0000000000004d1d:  89 CA                mov       dx, cx
0x0000000000004d1f:  30 FF                xor       bh, bh
0x0000000000004d21:  FF 76 0C             push      word ptr [bp + 0xc]
0x0000000000004d24:  89 D8                mov       ax, bx
0x0000000000004d26:  89 F3                mov       bx, si
0x0000000000004d28:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004d2d:  E8 D0 15             call      0x6300
0x0000000000004d30:  E9 24 FE             jmp       0x4b57
0x0000000000004d33:  88 D8                mov       al, bl
0x0000000000004d35:  BA 01 00             mov       dx, 1
0x0000000000004d38:  30 E4                xor       ah, ah
0x0000000000004d3a:  E8 7F D2             call      0x1fbc
0x0000000000004d3d:  30 FF                xor       bh, bh
0x0000000000004d3f:  BA 01 00             mov       dx, 1
0x0000000000004d42:  8A 46 F6             mov       al, byte ptr [bp - 0xa]
0x0000000000004d45:  89 D9                mov       cx, bx
0x0000000000004d47:  89 D3                mov       bx, dx
0x0000000000004d49:  30 E4                xor       ah, ah
0x0000000000004d4b:  89 CA                mov       dx, cx
0x0000000000004d4d:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004d52:  0E                   push      cs
0x0000000000004d53:  E8 4E DE             call      0x2ba4
0x0000000000004d56:  90                   nop       
0x0000000000004d57:  E9 FD FD             jmp       0x4b57
0x0000000000004d5a:  30 FF                xor       bh, bh
0x0000000000004d5c:  BA 02 00             mov       dx, 2
0x0000000000004d5f:  89 D8                mov       ax, bx
0x0000000000004d61:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004d66:  E8 53 D2             call      0x1fbc
0x0000000000004d69:  E9 EB FD             jmp       0x4b57
0x0000000000004d6c:  9A 34 19 A7 0A       lcall     0xaa7:0x1934
0x0000000000004d71:  83 7E FC FF          cmp       word ptr [bp - 4], -1
0x0000000000004d75:  74 03                je        0x4d7a
0x0000000000004d77:  E9 DD FD             jmp       0x4b57
0x0000000000004d7a:  C9                   LEAVE_MACRO     
0x0000000000004d7b:  5F                   pop       di
0x0000000000004d7c:  5E                   pop       si
0x0000000000004d7d:  59                   pop       cx
0x0000000000004d7e:  CA 04 00             retf      4
0x0000000000004d81:  89 C2                mov       dx, ax
0x0000000000004d83:  30 FF                xor       bh, bh
0x0000000000004d85:  31 C9                xor       cx, cx
0x0000000000004d87:  89 D8                mov       ax, bx
0x0000000000004d89:  89 CB                mov       bx, cx
0x0000000000004d8b:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004d90:  E8 5B F5             call      0x42ee
0x0000000000004d93:  E9 C1 FD             jmp       0x4b57
0x0000000000004d96:  30 FF                xor       bh, bh
0x0000000000004d98:  BA 01 00             mov       dx, 1
0x0000000000004d9b:  89 D8                mov       ax, bx
0x0000000000004d9d:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004da2:  E8 4B F7             call      0x44f0
0x0000000000004da5:  E9 AF FD             jmp       0x4b57
0x0000000000004da8:  BA 09 00             mov       dx, 9
0x0000000000004dab:  30 FF                xor       bh, bh
0x0000000000004dad:  89 C1                mov       cx, ax
0x0000000000004daf:  89 D8                mov       ax, bx
0x0000000000004db1:  89 D3                mov       bx, dx
0x0000000000004db3:  89 CA                mov       dx, cx
0x0000000000004db5:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004dba:  0E                   push      cs
0x0000000000004dbb:  E8 E6 DD             call      0x2ba4
0x0000000000004dbe:  90                   nop       
0x0000000000004dbf:  E9 95 FD             jmp       0x4b57
0x0000000000004dc2:  30 FF                xor       bh, bh
0x0000000000004dc4:  89 D8                mov       ax, bx
0x0000000000004dc6:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004dcb:  E8 EA D3             call      0x21b8
0x0000000000004dce:  E9 86 FD             jmp       0x4b57
0x0000000000004dd1:  BA 07 00             mov       dx, 7
0x0000000000004dd4:  30 FF                xor       bh, bh
0x0000000000004dd6:  89 C1                mov       cx, ax
0x0000000000004dd8:  89 D8                mov       ax, bx
0x0000000000004dda:  89 D3                mov       bx, dx
0x0000000000004ddc:  89 CA                mov       dx, cx
0x0000000000004dde:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004de3:  0E                   push      cs
0x0000000000004de4:  3E E8 BC DD          call      0x2ba4
0x0000000000004de8:  E9 6C FD             jmp       0x4b57
0x0000000000004deb:  30 FF                xor       bh, bh
0x0000000000004ded:  BA 08 00             mov       dx, 8
0x0000000000004df0:  89 D9                mov       cx, bx
0x0000000000004df2:  89 D3                mov       bx, dx
0x0000000000004df4:  89 C2                mov       dx, ax
0x0000000000004df6:  89 C8                mov       ax, cx
0x0000000000004df8:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004dfd:  0E                   push      cs
0x0000000000004dfe:  3E E8 A2 DD          call      0x2ba4
0x0000000000004e02:  E9 52 FD             jmp       0x4b57
0x0000000000004e05:  88 D8                mov       al, bl
0x0000000000004e07:  31 D2                xor       dx, dx
0x0000000000004e09:  30 E4                xor       ah, ah
0x0000000000004e0b:  31 DB                xor       bx, bx
0x0000000000004e0d:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004e12:  E8 1B F2             call      0x4030
0x0000000000004e15:  E9 3F FD             jmp       0x4b57
0x0000000000004e18:  88 D8                mov       al, bl
0x0000000000004e1a:  BA 05 00             mov       dx, 5
0x0000000000004e1d:  30 E4                xor       ah, ah
0x0000000000004e1f:  E9 2B FD             jmp       0x4b4d
0x0000000000004e22:  88 D8                mov       al, bl
0x0000000000004e24:  BA 06 00             mov       dx, 6
0x0000000000004e27:  30 E4                xor       ah, ah
0x0000000000004e29:  E9 21 FD             jmp       0x4b4d
0x0000000000004e2c:  88 D8                mov       al, bl
0x0000000000004e2e:  BA 01 00             mov       dx, 1
0x0000000000004e31:  30 E4                xor       ah, ah
0x0000000000004e33:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004e38:  E8 F9 E0             call      0x2f34
0x0000000000004e3b:  E9 19 FD             jmp       0x4b57
0x0000000000004e3e:  88 D8                mov       al, bl
0x0000000000004e40:  BA 07 00             mov       dx, 7
0x0000000000004e43:  30 E4                xor       ah, ah
0x0000000000004e45:  E9 05 FD             jmp       0x4b4d
0x0000000000004e48:  88 D9                mov       cl, bl
0x0000000000004e4a:  89 C2                mov       dx, ax
0x0000000000004e4c:  30 ED                xor       ch, ch
0x0000000000004e4e:  BB 04 00             mov       bx, 4
0x0000000000004e51:  89 C8                mov       ax, cx
0x0000000000004e53:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004e58:  0E                   push      cs
0x0000000000004e59:  E8 48 DD             call      0x2ba4
0x0000000000004e5c:  90                   nop       
0x0000000000004e5d:  E9 F7 FC             jmp       0x4b57
0x0000000000004e60:  C6 46 FF 00          mov       byte ptr [bp - 1], 0
0x0000000000004e64:  88 5E FE             mov       byte ptr [bp - 2], bl
0x0000000000004e67:  89 C2                mov       dx, ax
0x0000000000004e69:  31 C9                xor       cx, cx
0x0000000000004e6b:  BB 04 00             mov       bx, 4
0x0000000000004e6e:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000004e71:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004e76:  E8 75 F4             call      0x42ee
0x0000000000004e79:  E9 DB FC             jmp       0x4b57
0x0000000000004e7c:  9A 42 19 A7 0A       lcall     0xaa7:0x1942
0x0000000000004e81:  E9 ED FE             jmp       0x4d71
0x0000000000004e84:  84 FF                test      bh, bh
0x0000000000004e86:  75 03                jne       0x4e8b
0x0000000000004e88:  E9 E6 FE             jmp       0x4d71
0x0000000000004e8b:  FF 76 0E             push      word ptr [bp + 0xe]
0x0000000000004e8e:  88 D8                mov       al, bl
0x0000000000004e90:  89 CA                mov       dx, cx
0x0000000000004e92:  FF 76 0C             push      word ptr [bp + 0xc]
0x0000000000004e95:  89 F3                mov       bx, si
0x0000000000004e97:  30 E4                xor       ah, ah
0x0000000000004e99:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004e9e:  E8 5F 14             call      0x6300
0x0000000000004ea1:  E9 B3 FC             jmp       0x4b57
0x0000000000004ea4:  88 D9                mov       cl, bl
0x0000000000004ea6:  89 C2                mov       dx, ax
0x0000000000004ea8:  30 ED                xor       ch, ch
0x0000000000004eaa:  BB 0A 00             mov       bx, 0xa
0x0000000000004ead:  89 C8                mov       ax, cx
0x0000000000004eaf:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004eb4:  0E                   push      cs
0x0000000000004eb5:  E8 EC DC             call      0x2ba4
0x0000000000004eb8:  90                   nop       
0x0000000000004eb9:  E9 9B FC             jmp       0x4b57
0x0000000000004ebc:  88 D8                mov       al, bl
0x0000000000004ebe:  BA 05 00             mov       dx, 5
0x0000000000004ec1:  30 E4                xor       ah, ah
0x0000000000004ec3:  C7 46 FC 00 00       mov       word ptr [bp - 4], 0
0x0000000000004ec8:  E8 F1 D0             call      0x1fbc
0x0000000000004ecb:  E9 89 FC             jmp       0x4b57
0x0000000000004ece:  30 FF                xor       bh, bh
0x0000000000004ed0:  BA 02 00             mov       dx, 2
0x0000000000004ed3:  89 D8                mov       ax, bx
0x0000000000004ed5:  E8 E4 D0             call      0x1fbc
0x0000000000004ed8:  E9 96 FE             jmp       0x4d71
0x0000000000004edb:  30 FF                xor       bh, bh
0x0000000000004edd:  BA 03 00             mov       dx, 3
0x0000000000004ee0:  89 D8                mov       ax, bx
0x0000000000004ee2:  E8 D7 D0             call      0x1fbc
0x0000000000004ee5:  E9 89 FE             jmp       0x4d71
0x0000000000004ee8:  30 FF                xor       bh, bh
0x0000000000004eea:  89 D8                mov       ax, bx
0x0000000000004eec:  E8 C9 D2             call      0x21b8
0x0000000000004eef:  E9 7F FE             jmp       0x4d71
0x0000000000004ef2:  30 FF                xor       bh, bh
0x0000000000004ef4:  BA 02 00             mov       dx, 2
0x0000000000004ef7:  89 D8                mov       ax, bx
0x0000000000004ef9:  0E                   push      cs
0x0000000000004efa:  3E E8 A0 D5          call      0x249e
0x0000000000004efe:  E9 70 FE             jmp       0x4d71
0x0000000000004f01:  30 FF                xor       bh, bh
0x0000000000004f03:  BA 01 00             mov       dx, 1
0x0000000000004f06:  89 D8                mov       ax, bx
0x0000000000004f08:  0E                   push      cs
0x0000000000004f09:  E8 92 D5             call      0x249e
0x0000000000004f0c:  90                   nop       
0x0000000000004f0d:  E9 61 FE             jmp       0x4d71
0x0000000000004f10:  30 FF                xor       bh, bh
0x0000000000004f12:  BA 04 00             mov       dx, 4
0x0000000000004f15:  89 D8                mov       ax, bx
0x0000000000004f17:  E8 A2 D0             call      0x1fbc
0x0000000000004f1a:  E9 54 FE             jmp       0x4d71
0x0000000000004f1d:  B9 23 00             mov       cx, 0x23
0x0000000000004f20:  30 FF                xor       bh, bh
0x0000000000004f22:  BA 01 00             mov       dx, 1
0x0000000000004f25:  89 D8                mov       ax, bx
0x0000000000004f27:  89 CB                mov       bx, cx
0x0000000000004f29:  E8 04 F1             call      0x4030
0x0000000000004f2c:  E9 42 FE             jmp       0x4d71
0x0000000000004f2f:  BA 01 00             mov       dx, 1
0x0000000000004f32:  30 FF                xor       bh, bh
0x0000000000004f34:  31 C9                xor       cx, cx
0x0000000000004f36:  89 D8                mov       ax, bx
0x0000000000004f38:  89 CB                mov       bx, cx
0x0000000000004f3a:  E8 F3 F0             call      0x4030
0x0000000000004f3d:  E9 31 FE             jmp       0x4d71
0x0000000000004f40:  B9 FF 00             mov       cx, 0xff
0x0000000000004f43:  30 FF                xor       bh, bh
0x0000000000004f45:  BA 01 00             mov       dx, 1
0x0000000000004f48:  89 D8                mov       ax, bx
0x0000000000004f4a:  89 CB                mov       bx, cx
0x0000000000004f4c:  E8 E1 F0             call      0x4030
0x0000000000004f4f:  E9 1F FE             jmp       0x4d71
0x0000000000004f52:  30 FF                xor       bh, bh
0x0000000000004f54:  BA 01 00             mov       dx, 1
0x0000000000004f57:  89 D9                mov       cx, bx
0x0000000000004f59:  89 D3                mov       bx, dx
0x0000000000004f5b:  89 C2                mov       dx, ax
0x0000000000004f5d:  89 C8                mov       ax, cx
0x0000000000004f5f:  0E                   push      cs
0x0000000000004f60:  3E E8 40 DC          call      0x2ba4
0x0000000000004f64:  E9 0A FE             jmp       0x4d71
0x0000000000004f67:  30 FF                xor       bh, bh
0x0000000000004f69:  31 D2                xor       dx, dx
0x0000000000004f6b:  89 D9                mov       cx, bx
0x0000000000004f6d:  89 D3                mov       bx, dx
0x0000000000004f6f:  89 C2                mov       dx, ax
0x0000000000004f71:  89 C8                mov       ax, cx
0x0000000000004f73:  0E                   push      cs
0x0000000000004f74:  3E E8 2C DC          call      0x2ba4
0x0000000000004f78:  E9 F6 FD             jmp       0x4d71
0x0000000000004f7b:  30 FF                xor       bh, bh
0x0000000000004f7d:  BA 06 00             mov       dx, 6
0x0000000000004f80:  89 D9                mov       cx, bx
0x0000000000004f82:  89 D3                mov       bx, dx
0x0000000000004f84:  89 C2                mov       dx, ax
0x0000000000004f86:  89 C8                mov       ax, cx
0x0000000000004f88:  0E                   push      cs
0x0000000000004f89:  E8 18 DC             call      0x2ba4
0x0000000000004f8c:  90                   nop       
0x0000000000004f8d:  E9 E1 FD             jmp       0x4d71
0x0000000000004f90:  30 FF                xor       bh, bh
0x0000000000004f92:  BA 03 00             mov       dx, 3
0x0000000000004f95:  89 D8                mov       ax, bx
0x0000000000004f97:  0E                   push      cs
0x0000000000004f98:  3E E8 02 D5          call      0x249e
0x0000000000004f9c:  E9 D2 FD             jmp       0x4d71
0x0000000000004f9f:  89 C2                mov       dx, ax
0x0000000000004fa1:  30 FF                xor       bh, bh
0x0000000000004fa3:  31 C9                xor       cx, cx
0x0000000000004fa5:  89 DE                mov       si, bx
0x0000000000004fa7:  89 CB                mov       bx, cx
0x0000000000004fa9:  89 F0                mov       ax, si
0x0000000000004fab:  E8 40 F3             call      0x42ee
0x0000000000004fae:  E9 C0 FD             jmp       0x4d71
0x0000000000004fb1:  BA 01 00             mov       dx, 1
0x0000000000004fb4:  30 FF                xor       bh, bh
0x0000000000004fb6:  31 C9                xor       cx, cx
0x0000000000004fb8:  89 DE                mov       si, bx
0x0000000000004fba:  89 D3                mov       bx, dx
0x0000000000004fbc:  89 C2                mov       dx, ax
0x0000000000004fbe:  89 F0                mov       ax, si
0x0000000000004fc0:  E8 2B F3             call      0x42ee
0x0000000000004fc3:  E9 AB FD             jmp       0x4d71
0x0000000000004fc6:  88 D8                mov       al, bl
0x0000000000004fc8:  BA 01 00             mov       dx, 1
0x0000000000004fcb:  30 E4                xor       ah, ah
0x0000000000004fcd:  E8 20 F5             call      0x44f0
0x0000000000004fd0:  E9 9E FD             jmp       0x4d71
0x0000000000004fd3:  88 D8                mov       al, bl
0x0000000000004fd5:  31 D2                xor       dx, dx
0x0000000000004fd7:  30 E4                xor       ah, ah
0x0000000000004fd9:  0E                   push      cs
0x0000000000004fda:  3E E8 C0 D4          call      0x249e
0x0000000000004fde:  E9 90 FD             jmp       0x4d71
0x0000000000004fe1:  88 D9                mov       cl, bl
0x0000000000004fe3:  89 C2                mov       dx, ax
0x0000000000004fe5:  30 ED                xor       ch, ch
0x0000000000004fe7:  BB 03 00             mov       bx, 3
0x0000000000004fea:  89 C8                mov       ax, cx
0x0000000000004fec:  0E                   push      cs
0x0000000000004fed:  E8 B4 DB             call      0x2ba4
0x0000000000004ff0:  90                   nop       
0x0000000000004ff1:  E9 7D FD             jmp       0x4d71
0x0000000000004ff4:  88 D9                mov       cl, bl
0x0000000000004ff6:  89 C2                mov       dx, ax
0x0000000000004ff8:  30 ED                xor       ch, ch
0x0000000000004ffa:  BB 07 00             mov       bx, 7
0x0000000000004ffd:  89 C8                mov       ax, cx
0x0000000000004fff:  0E                   push      cs
0x0000000000005000:  3E E8 A0 DB          call      0x2ba4
0x0000000000005004:  E9 6A FD             jmp       0x4d71
0x0000000000005007:  88 D9                mov       cl, bl
0x0000000000005009:  89 C2                mov       dx, ax
0x000000000000500b:  30 ED                xor       ch, ch
0x000000000000500d:  BB 08 00             mov       bx, 8
0x0000000000005010:  89 C8                mov       ax, cx
0x0000000000005012:  0E                   push      cs
0x0000000000005013:  E8 8E DB             call      0x2ba4
0x0000000000005016:  90                   nop       
0x0000000000005017:  E9 57 FD             jmp       0x4d71
0x000000000000501a:  88 D9                mov       cl, bl
0x000000000000501c:  89 C2                mov       dx, ax
0x000000000000501e:  30 ED                xor       ch, ch
0x0000000000005020:  BB 09 00             mov       bx, 9
0x0000000000005023:  89 C8                mov       ax, cx
0x0000000000005025:  0E                   push      cs
0x0000000000005026:  3E E8 7A DB          call      0x2ba4
0x000000000000502a:  E9 44 FD             jmp       0x4d71
0x000000000000502d:  C6 46 FF 00          mov       byte ptr [bp - 1], 0
0x0000000000005031:  88 5E FE             mov       byte ptr [bp - 2], bl
0x0000000000005034:  89 C2                mov       dx, ax
0x0000000000005036:  31 C9                xor       cx, cx
0x0000000000005038:  BB 03 00             mov       bx, 3
0x000000000000503b:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x000000000000503e:  E8 AD F2             call      0x42ee
0x0000000000005041:  E9 2D FD             jmp       0x4d71
0x0000000000005044:  88 D9                mov       cl, bl
0x0000000000005046:  89 C2                mov       dx, ax
0x0000000000005048:  30 ED                xor       ch, ch
0x000000000000504a:  BB 05 00             mov       bx, 5
0x000000000000504d:  89 C8                mov       ax, cx
0x000000000000504f:  0E                   push      cs
0x0000000000005050:  3E E8 50 DB          call      0x2ba4
0x0000000000005054:  E9 1A FD             jmp       0x4d71
0x0000000000005057:  FF 76 0E             push      word ptr [bp + 0xe]
0x000000000000505a:  88 D8                mov       al, bl
0x000000000000505c:  89 CA                mov       dx, cx
0x000000000000505e:  FF 76 0C             push      word ptr [bp + 0xc]
0x0000000000005061:  89 F3                mov       bx, si
0x0000000000005063:  30 E4                xor       ah, ah
0x0000000000005065:  E8 98 12             call      0x6300
0x0000000000005068:  E9 06 FD             jmp       0x4d71
0x000000000000506b:  88 D9                mov       cl, bl
0x000000000000506d:  89 C2                mov       dx, ax
0x000000000000506f:  30 ED                xor       ch, ch
0x0000000000005071:  BB 02 00             mov       bx, 2
0x0000000000005074:  89 C8                mov       ax, cx
0x0000000000005076:  0E                   push      cs
0x0000000000005077:  E8 2A DB             call      0x2ba4
0x000000000000507a:  90                   nop       
0x000000000000507b:  E9 F3 FC             jmp       0x4d71
0x000000000000507e:  88 D8                mov       al, bl
0x0000000000005080:  BA 05 00             mov       dx, 5
0x0000000000005083:  30 E4                xor       ah, ah
0x0000000000005085:  0E                   push      cs
0x0000000000005086:  3E E8 14 D4          call      0x249e
0x000000000000508a:  E9 E4 FC             jmp       0x4d71
0x000000000000508d:  88 D8                mov       al, bl
0x000000000000508f:  BA 06 00             mov       dx, 6
0x0000000000005092:  30 E4                xor       ah, ah
0x0000000000005094:  0E                   push      cs
0x0000000000005095:  E8 06 D4             call      0x249e
0x0000000000005098:  90                   nop       
0x0000000000005099:  E9 D5 FC             jmp       0x4d71
0x000000000000509c:  88 D8                mov       al, bl
0x000000000000509e:  BA 07 00             mov       dx, 7
0x00000000000050a1:  30 E4                xor       ah, ah
0x00000000000050a3:  0E                   push      cs
0x00000000000050a4:  3E E8 F6 D3          call      0x249e
0x00000000000050a8:  E9 C6 FC             jmp       0x4d71
0x00000000000050ab:  C6 46 FF 00          mov       byte ptr [bp - 1], 0
0x00000000000050af:  88 5E FE             mov       byte ptr [bp - 2], bl
0x00000000000050b2:  89 C2                mov       dx, ax
0x00000000000050b4:  31 C9                xor       cx, cx
0x00000000000050b6:  BB 04 00             mov       bx, 4
0x00000000000050b9:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x00000000000050bc:  E8 2F F2             call      0x42ee
0x00000000000050bf:  E9 AF FC             jmp       0x4d71
0x00000000000050c2:  84 FF                test      bh, bh
0x00000000000050c4:  75 03                jne       0x50c9
0x00000000000050c6:  E9 A8 FC             jmp       0x4d71
0x00000000000050c9:  FF 76 0E             push      word ptr [bp + 0xe]
0x00000000000050cc:  88 D8                mov       al, bl
0x00000000000050ce:  89 CA                mov       dx, cx
0x00000000000050d0:  FF 76 0C             push      word ptr [bp + 0xc]
0x00000000000050d3:  89 F3                mov       bx, si
0x00000000000050d5:  30 E4                xor       ah, ah
0x00000000000050d7:  E8 26 12             call      0x6300
0x00000000000050da:  E9 94 FC             jmp       0x4d71
0x00000000000050dd:  88 D9                mov       cl, bl
0x00000000000050df:  89 C2                mov       dx, ax
0x00000000000050e1:  30 ED                xor       ch, ch
0x00000000000050e3:  BB 04 00             mov       bx, 4
0x00000000000050e6:  89 C8                mov       ax, cx
0x00000000000050e8:  0E                   push      cs
0x00000000000050e9:  E8 B8 DA             call      0x2ba4
0x00000000000050ec:  90                   nop       
0x00000000000050ed:  E9 81 FC             jmp       0x4d71
0x00000000000050f0:  88 D9                mov       cl, bl
0x00000000000050f2:  89 C2                mov       dx, ax
0x00000000000050f4:  30 ED                xor       ch, ch
0x00000000000050f6:  BB 0A 00             mov       bx, 0xa
0x00000000000050f9:  89 C8                mov       ax, cx
0x00000000000050fb:  0E                   push      cs
0x00000000000050fc:  3E E8 A4 DA          call      0x2ba4
0x0000000000005100:  E9 6E FC             jmp       0x4d71

ENDP

PROC    P_ShootSpecialLine_  NEAR
PUBLIC  P_ShootSpecialLine_

0x0000000000005104:  53                   push      bx
0x0000000000005105:  51                   push      cx
0x0000000000005106:  56                   push      si
0x0000000000005107:  57                   push      di
0x0000000000005108:  55                   push      bp
0x0000000000005109:  89 E5                mov       bp, sp
0x000000000000510b:  83 EC 06             sub       sp, 6
0x000000000000510e:  50                   push      ax
0x000000000000510f:  89 D7                mov       di, dx
0x0000000000005111:  89 D0                mov       ax, dx
0x0000000000005113:  01 D0                add       ax, dx
0x0000000000005115:  C7 46 FA 91 29       mov       word ptr [bp - 6], 0x2991
0x000000000000511a:  89 C3                mov       bx, ax
0x000000000000511c:  BE 0A 00             mov       si, 0xa
0x000000000000511f:  81 C3 50 CA          add       bx, OFFSET _linebuffer
0x0000000000005123:  8B 1F                mov       bx, word ptr ds:[bx]
0x0000000000005125:  B8 00 70             mov       ax, 0x7000
0x0000000000005128:  89 D9                mov       cx, bx
0x000000000000512a:  8E C0                mov       es, ax
0x000000000000512c:  C1 E1 02             shl       cx, 2
0x000000000000512f:  C1 E3 04             shl       bx, 4
0x0000000000005132:  26 8B 34             mov       si, word ptr es:[si]
0x0000000000005135:  26 8A 47 0F          mov       al, byte ptr es:[bx + 0xf]
0x0000000000005139:  26 8A 57 0E          mov       dl, byte ptr es:[bx + 0xe]
0x000000000000513d:  8E 46 FA             mov       es, word ptr [bp - 6]
0x0000000000005140:  30 E4                xor       ah, ah
0x0000000000005142:  89 CB                mov       bx, cx
0x0000000000005144:  89 46 FC             mov       word ptr [bp - 4], ax
0x0000000000005147:  26 8B 0F             mov       cx, word ptr es:[bx]
0x000000000000514a:  8B 5E F8             mov       bx, word ptr [bp - 8]
0x000000000000514d:  89 4E FE             mov       word ptr [bp - 2], cx
0x0000000000005150:  80 7F 1A 00          cmp       byte ptr [bx + 0x1a], 0
0x0000000000005154:  74 05                je        0x515b
0x0000000000005156:  3D 2E 00             cmp       ax, 0x2e
0x0000000000005159:  75 12                jne       0x516d
0x000000000000515b:  8B 46 FC             mov       ax, word ptr [bp - 4]
0x000000000000515e:  3D 2F 00             cmp       ax, 0x2f
0x0000000000005161:  74 50                je        0x51b3
0x0000000000005163:  3D 2E 00             cmp       ax, 0x2e
0x0000000000005166:  74 2C                je        0x5194
0x0000000000005168:  3D 18 00             cmp       ax, 0x18
0x000000000000516b:  74 06                je        0x5173
0x000000000000516d:  C9                   LEAVE_MACRO     
0x000000000000516e:  5F                   pop       di
0x000000000000516f:  5E                   pop       si
0x0000000000005170:  59                   pop       cx
0x0000000000005171:  5B                   pop       bx
0x0000000000005172:  CB                   retf      
0x0000000000005173:  BB 03 00             mov       bx, 3
0x0000000000005176:  88 D0                mov       al, dl
0x0000000000005178:  89 F2                mov       dx, si
0x000000000000517a:  30 E4                xor       ah, ah
0x000000000000517c:  89 F1                mov       cx, si
0x000000000000517e:  0E                   push      cs
0x000000000000517f:  E8 22 DA             call      0x2ba4
0x0000000000005182:  90                   nop       
0x0000000000005183:  6A 00                push      0
0x0000000000005185:  8A 5E FC             mov       bl, byte ptr [bp - 4]
0x0000000000005188:  8B 56 FE             mov       dx, word ptr [bp - 2]
0x000000000000518b:  89 F8                mov       ax, di
0x000000000000518d:  30 FF                xor       bh, bh
0x000000000000518f:  E8 CE 06             call      0x5860
0x0000000000005192:  EB D9                jmp       0x516d
0x0000000000005194:  8A 5E FC             mov       bl, byte ptr [bp - 4]
0x0000000000005197:  88 D0                mov       al, dl
0x0000000000005199:  BA 03 00             mov       dx, 3
0x000000000000519c:  30 E4                xor       ah, ah
0x000000000000519e:  89 F1                mov       cx, si
0x00000000000051a0:  0E                   push      cs
0x00000000000051a1:  E8 FA D2             call      0x249e
0x00000000000051a4:  90                   nop       
0x00000000000051a5:  30 FF                xor       bh, bh
0x00000000000051a7:  6A 01                push      1
0x00000000000051a9:  8B 56 FE             mov       dx, word ptr [bp - 2]
0x00000000000051ac:  89 F8                mov       ax, di
0x00000000000051ae:  E8 AF 06             call      0x5860
0x00000000000051b1:  EB BA                jmp       0x516d
0x00000000000051b3:  BB 03 00             mov       bx, 3
0x00000000000051b6:  88 D0                mov       al, dl
0x00000000000051b8:  31 C9                xor       cx, cx
0x00000000000051ba:  89 F2                mov       dx, si
0x00000000000051bc:  30 E4                xor       ah, ah
0x00000000000051be:  E8 2D F1             call      0x42ee
0x00000000000051c1:  6A 00                push      0
0x00000000000051c3:  8A 5E FC             mov       bl, byte ptr [bp - 4]
0x00000000000051c6:  8B 56 FE             mov       dx, word ptr [bp - 2]
0x00000000000051c9:  89 F1                mov       cx, si
0x00000000000051cb:  89 F8                mov       ax, di
0x00000000000051cd:  30 FF                xor       bh, bh
0x00000000000051cf:  E8 8E 06             call      0x5860
0x00000000000051d2:  C9                   LEAVE_MACRO     
0x00000000000051d3:  5F                   pop       di
0x00000000000051d4:  5E                   pop       si
0x00000000000051d5:  59                   pop       cx
0x00000000000051d6:  5B                   pop       bx
0x00000000000051d7:  CB                   retf      



dw 05254h, 0526Ah, 05264h, 0528Dh, 05264h, 052D0h, 05264h, 052DDh, 05264h, 05264h, 05264h, 05264h, 05254h



ENDP

PROC    P_PlayerInSpecialSector_  NEAR
PUBLIC  P_PlayerInSpecialSector_


0x00000000000051f2:  53                   push      bx
0x00000000000051f3:  51                   push      cx
0x00000000000051f4:  52                   push      dx
0x00000000000051f5:  56                   push      si
0x00000000000051f6:  55                   push      bp
0x00000000000051f7:  89 E5                mov       bp, sp
0x00000000000051f9:  83 EC 04             sub       sp, 4
0x00000000000051fc:  BB EC 06             mov       bx, 0x6ec
0x00000000000051ff:  C7 46 FE 00 00       mov       word ptr [bp - 2], 0
0x0000000000005204:  8B 1F                mov       bx, word ptr ds:[bx]
0x0000000000005206:  B8 90 21             mov       ax, SECTORS_SEGMENT
0x0000000000005209:  8B 5F 04             mov       bx, word ptr ds:[bx + 4]
0x000000000000520c:  BE 30 07             mov       si, 0x730
0x000000000000520f:  C1 E3 04             shl       bx, 4
0x0000000000005212:  8E C0                mov       es, ax
0x0000000000005214:  89 5E FC             mov       word ptr [bp - 4], bx
0x0000000000005217:  26 8B 17             mov       dx, word ptr es:[bx]
0x000000000000521a:  26 8B 07             mov       ax, word ptr es:[bx]
0x000000000000521d:  C1 FA 03             sar       dx, 3
0x0000000000005220:  30 E4                xor       ah, ah
0x0000000000005222:  8B 1C                mov       bx, word ptr ds:[si]
0x0000000000005224:  24 07                and       al, 7
0x0000000000005226:  8E 44 02             mov       es, word ptr ds:[si + 2]
0x0000000000005229:  C1 E0 0D             shl       ax, 0xd
0x000000000000522c:  26 3B 57 0A          cmp       dx, word ptr es:[bx + 0xa]
0x0000000000005230:  75 32                jne       0x5264
0x0000000000005232:  26 3B 47 08          cmp       ax, word ptr es:[bx + 8]
0x0000000000005236:  75 2C                jne       0x5264
0x0000000000005238:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x000000000000523b:  8A 87 3E DE          mov       al, byte ptr [bx - 0x21c2]
0x000000000000523f:  2C 04                sub       al, 4
0x0000000000005241:  81 C3 3E DE          add       bx, 0xde3e
0x0000000000005245:  3C 0C                cmp       al, 0xc
0x0000000000005247:  77 1B                ja        0x5264
0x0000000000005249:  30 E4                xor       ah, ah
0x000000000000524b:  89 C6                mov       si, ax
0x000000000000524d:  01 C6                add       si, ax
0x000000000000524f:  2E FF A4 D8 51       jmp       word ptr cs:[si + 0x51d8]
0x0000000000005254:  BB F4 07             mov       bx, 0x7f4
0x0000000000005257:  83 3F 00             cmp       word ptr ds:[bx], 0
0x000000000000525a:  75 54                jne       0x52b0
0x000000000000525c:  BB 1C 07             mov       bx, 0x71c
0x000000000000525f:  F6 07 1F             test      byte ptr [bx], 0x1f
0x0000000000005262:  74 55                je        0x52b9
0x0000000000005264:  C9                   LEAVE_MACRO     
0x0000000000005265:  5E                   pop       si
0x0000000000005266:  5A                   pop       dx
0x0000000000005267:  59                   pop       cx
0x0000000000005268:  5B                   pop       bx
0x0000000000005269:  C3                   ret       
0x000000000000526a:  BB F4 07             mov       bx, 0x7f4
0x000000000000526d:  83 3F 00             cmp       word ptr ds:[bx], 0
0x0000000000005270:  75 F2                jne       0x5264
0x0000000000005272:  BB 1C 07             mov       bx, 0x71c
0x0000000000005275:  F6 07 1F             test      byte ptr [bx], 0x1f
0x0000000000005278:  75 EA                jne       0x5264
0x000000000000527a:  BB EC 06             mov       bx, 0x6ec
0x000000000000527d:  B9 0A 00             mov       cx, 0xa
0x0000000000005280:  31 D2                xor       dx, dx
0x0000000000005282:  8B 07                mov       ax, word ptr ds:[bx]
0x0000000000005284:  31 DB                xor       bx, bx
0x0000000000005286:  0E                   push      cs
0x0000000000005287:  E8 B8 E7             call      0x3a42
0x000000000000528a:  90                   nop       
0x000000000000528b:  EB D7                jmp       0x5264
0x000000000000528d:  BB F4 07             mov       bx, 0x7f4
0x0000000000005290:  83 3F 00             cmp       word ptr ds:[bx], 0
0x0000000000005293:  75 CF                jne       0x5264
0x0000000000005295:  BB 1C 07             mov       bx, 0x71c
0x0000000000005298:  F6 07 1F             test      byte ptr [bx], 0x1f
0x000000000000529b:  75 C7                jne       0x5264
0x000000000000529d:  BB EC 06             mov       bx, 0x6ec
0x00000000000052a0:  B9 05 00             mov       cx, 5
0x00000000000052a3:  31 D2                xor       dx, dx
0x00000000000052a5:  8B 07                mov       ax, word ptr ds:[bx]
0x00000000000052a7:  31 DB                xor       bx, bx
0x00000000000052a9:  0E                   push      cs
0x00000000000052aa:  3E E8 94 E7          call      0x3a42
0x00000000000052ae:  EB B4                jmp       0x5264
0x00000000000052b0:  E8 42 14             call      0x66f5
0x00000000000052b3:  3C 05                cmp       al, 5
0x00000000000052b5:  72 A5                jb        0x525c
0x00000000000052b7:  EB AB                jmp       0x5264
0x00000000000052b9:  BB EC 06             mov       bx, 0x6ec
0x00000000000052bc:  B9 14 00             mov       cx, 0x14
0x00000000000052bf:  31 D2                xor       dx, dx
0x00000000000052c1:  8B 07                mov       ax, word ptr ds:[bx]
0x00000000000052c3:  31 DB                xor       bx, bx
0x00000000000052c5:  0E                   push      cs
0x00000000000052c6:  3E E8 78 E7          call      0x3a42
0x00000000000052ca:  C9                   LEAVE_MACRO     
0x00000000000052cb:  5E                   pop       si
0x00000000000052cc:  5A                   pop       dx
0x00000000000052cd:  59                   pop       cx
0x00000000000052ce:  5B                   pop       bx
0x00000000000052cf:  C3                   ret       
0x00000000000052d0:  BE 22 08             mov       si, 0x822
0x00000000000052d3:  FF 04                inc       word ptr ds:[si]
0x00000000000052d5:  88 27                mov       byte ptr [bx], ah
0x00000000000052d7:  C9                   LEAVE_MACRO     
0x00000000000052d8:  5E                   pop       si
0x00000000000052d9:  5A                   pop       dx
0x00000000000052da:  59                   pop       cx
0x00000000000052db:  5B                   pop       bx
0x00000000000052dc:  C3                   ret       
0x00000000000052dd:  BB 0B 08             mov       bx, 0x80b
0x00000000000052e0:  80 27 FD             and       byte ptr [bx], 0xfd
0x00000000000052e3:  BB 1C 07             mov       bx, 0x71c
0x00000000000052e6:  F6 07 1F             test      byte ptr [bx], 0x1f
0x00000000000052e9:  74 16                je        0x5301
0x00000000000052eb:  BB E8 07             mov       bx, 0x7e8
0x00000000000052ee:  83 3F 0A             cmp       word ptr ds:[bx], 0xa
0x00000000000052f1:  7E 03                jle       0x52f6
0x00000000000052f3:  E9 6E FF             jmp       0x5264
0x00000000000052f6:  9A 34 19 A7 0A       lcall     0xaa7:0x1934
0x00000000000052fb:  C9                   LEAVE_MACRO     
0x00000000000052fc:  5E                   pop       si
0x00000000000052fd:  5A                   pop       dx
0x00000000000052fe:  59                   pop       cx
0x00000000000052ff:  5B                   pop       bx
0x0000000000005300:  C3                   ret       
0x0000000000005301:  BB EC 06             mov       bx, 0x6ec
0x0000000000005304:  B9 14 00             mov       cx, 0x14
0x0000000000005307:  31 D2                xor       dx, dx
0x0000000000005309:  8B 07                mov       ax, word ptr ds:[bx]
0x000000000000530b:  31 DB                xor       bx, bx
0x000000000000530d:  0E                   push      cs
0x000000000000530e:  3E E8 30 E7          call      0x3a42
0x0000000000005312:  EB D7                jmp       0x52eb

ENDP

PROC    P_UpdateSpecials_  NEAR
PUBLIC  P_UpdateSpecials_


0x0000000000005314:  53                   push      bx
0x0000000000005315:  51                   push      cx
0x0000000000005316:  52                   push      dx
0x0000000000005317:  56                   push      si
0x0000000000005318:  57                   push      di
0x0000000000005319:  55                   push      bp
0x000000000000531a:  89 E5                mov       bp, sp
0x000000000000531c:  83 EC 04             sub       sp, 4
0x000000000000531f:  80 3E 49 20 01       cmp       byte ptr [0x2049], 1
0x0000000000005324:  74 49                je        0x536f
0x0000000000005326:  BF 78 1A             mov       di, 0x1a78
0x0000000000005329:  3B 3E 4C 1F          cmp       di, word ptr [0x1f4c]
0x000000000000532d:  73 66                jae       0x5395
0x000000000000532f:  BE 1C 07             mov       si, 0x71c
0x0000000000005332:  8B 4D 03             mov       cx, word ptr ds:[di + 3]
0x0000000000005335:  89 C8                mov       ax, cx
0x0000000000005337:  01 C8                add       ax, cx
0x0000000000005339:  89 46 FE             mov       word ptr [bp - 2], ax
0x000000000000533c:  8A 5D 05             mov       bl, byte ptr [di + 5]
0x000000000000533f:  8B 45 03             mov       ax, word ptr ds:[di + 3]
0x0000000000005342:  30 FF                xor       bh, bh
0x0000000000005344:  01 D8                add       ax, bx
0x0000000000005346:  39 C1                cmp       cx, ax
0x0000000000005348:  73 4D                jae       0x5397
0x000000000000534a:  8B 04                mov       ax, word ptr ds:[si]
0x000000000000534c:  C1 E8 03             shr       ax, 3
0x000000000000534f:  31 D2                xor       dx, dx
0x0000000000005351:  01 C8                add       ax, cx
0x0000000000005353:  F7 F3                div       bx
0x0000000000005355:  03 55 03             add       dx, word ptr ds:[di + 3]
0x0000000000005358:  80 3D 00             cmp       byte ptr [di], 0
0x000000000000535b:  74 2C                je        0x5389
0x000000000000535d:  B8 14 3C             mov       ax, 0x3c14
0x0000000000005360:  8B 5E FE             mov       bx, word ptr [bp - 2]
0x0000000000005363:  8E C0                mov       es, ax
0x0000000000005365:  26 89 17             mov       word ptr es:[bx], dx
0x0000000000005368:  83 46 FE 02          add       word ptr [bp - 2], 2
0x000000000000536c:  41                   inc       cx
0x000000000000536d:  EB CD                jmp       0x533c
0x000000000000536f:  83 06 3C 1D FF       add       word ptr [0x1d3c], -1
0x0000000000005374:  83 16 3E 1D FF       adc       word ptr [0x1d3e], -1
0x0000000000005379:  A1 3E 1D             mov       ax, word ptr [0x1d3e]
0x000000000000537c:  0B 06 3C 1D          or        ax, word ptr [0x1d3c]
0x0000000000005380:  75 A4                jne       0x5326
0x0000000000005382:  9A 34 19 A7 0A       lcall     0xaa7:0x1934
0x0000000000005387:  EB 9D                jmp       0x5326
0x0000000000005389:  B8 0A 3C             mov       ax, 0x3c0a
0x000000000000538c:  89 CB                mov       bx, cx
0x000000000000538e:  8E C0                mov       es, ax
0x0000000000005390:  26 88 17             mov       byte ptr es:[bx], dl
0x0000000000005393:  EB D3                jmp       0x5368
0x0000000000005395:  EB 09                jmp       0x53a0
0x0000000000005397:  83 C7 06             add       di, 6
0x000000000000539a:  3B 3E 4C 1F          cmp       di, word ptr [0x1f4c]
0x000000000000539e:  72 92                jb        0x5332
0x00000000000053a0:  31 C9                xor       cx, cx
0x00000000000053a2:  83 3E 4A 1F 00       cmp       word ptr [0x1f4a], 0
0x00000000000053a7:  7E 47                jle       0x53f0
0x00000000000053a9:  BA D8 4C             mov       dx, 0x4cd8
0x00000000000053ac:  31 F6                xor       si, si
0x00000000000053ae:  89 F3                mov       bx, si
0x00000000000053b0:  8E C2                mov       es, dx
0x00000000000053b2:  26 8B 3F             mov       di, word ptr es:[bx]
0x00000000000053b5:  B8 00 70             mov       ax, 0x7000
0x00000000000053b8:  C1 E7 04             shl       di, 4
0x00000000000053bb:  8E C0                mov       es, ax
0x00000000000053bd:  26 8A 45 0F          mov       al, byte ptr es:[di + 0xf]
0x00000000000053c1:  83 C7 0F             add       di, 0xf
0x00000000000053c4:  3C 30                cmp       al, 0x30
0x00000000000053c6:  75 1E                jne       0x53e6
0x00000000000053c8:  8E C2                mov       es, dx
0x00000000000053ca:  26 8B 1F             mov       bx, word ptr es:[bx]
0x00000000000053cd:  B8 91 29             mov       ax, 0x2991
0x00000000000053d0:  C1 E3 02             shl       bx, 2
0x00000000000053d3:  8E C0                mov       es, ax
0x00000000000053d5:  26 8B 1F             mov       bx, word ptr es:[bx]
0x00000000000053d8:  B8 83 24             mov       ax, 0x2483
0x00000000000053db:  C1 E3 03             shl       bx, 3
0x00000000000053de:  8E C0                mov       es, ax
0x00000000000053e0:  83 C3 06             add       bx, 6
0x00000000000053e3:  26 FF 07             inc       word ptr es:[bx]
0x00000000000053e6:  41                   inc       cx
0x00000000000053e7:  83 C6 02             add       si, 2
0x00000000000053ea:  3B 0E 4A 1F          cmp       cx, word ptr [0x1f4a]
0x00000000000053ee:  7C BE                jl        0x53ae
0x00000000000053f0:  C7 46 FC 40 1D       mov       word ptr [bp - 4], 0x1d40
0x00000000000053f5:  31 F6                xor       si, si
0x00000000000053f7:  6B DE 09             imul      bx, si, 9
0x00000000000053fa:  83 BF 45 1D 00       cmp       word ptr ds:[bx + 0x1d45], 0
0x00000000000053ff:  74 57                je        0x5458
0x0000000000005401:  FF 8F 45 1D          dec       word ptr ds:[bx + 0x1d45]
0x0000000000005405:  75 51                jne       0x5458
0x0000000000005407:  8B BF 40 1D          mov       di, word ptr ds:[bx + 0x1d40]
0x000000000000540b:  B8 91 29             mov       ax, 0x2991
0x000000000000540e:  C1 E7 02             shl       di, 2
0x0000000000005411:  8E C0                mov       es, ax
0x0000000000005413:  26 8B 05             mov       ax, word ptr es:[di]
0x0000000000005416:  8A 97 42 1D          mov       dl, byte ptr [bx + 0x1d42]
0x000000000000541a:  C1 E0 03             shl       ax, 3
0x000000000000541d:  80 FA 02             cmp       dl, 2
0x0000000000005420:  75 47                jne       0x5469
0x0000000000005422:  BA 83 24             mov       dx, 0x2483
0x0000000000005425:  89 C7                mov       di, ax
0x0000000000005427:  8E C2                mov       es, dx
0x0000000000005429:  83 C7 02             add       di, 2
0x000000000000542c:  8B 87 43 1D          mov       ax, word ptr ds:[bx + 0x1d43]
0x0000000000005430:  26 89 05             mov       word ptr es:[di], ax
0x0000000000005433:  6B DE 09             imul      bx, si, 9
0x0000000000005436:  BA 17 00             mov       dx, 0x17
0x0000000000005439:  B9 09 00             mov       cx, 9
0x000000000000543c:  8B 87 47 1D          mov       ax, word ptr ds:[bx + 0x1d47]
0x0000000000005440:  8B 7E FC             mov       di, word ptr [bp - 4]
0x0000000000005443:  0E                   push      cs
0x0000000000005444:  3E E8 1A B1          call      0x562
0x0000000000005448:  30 C0                xor       al, al
0x000000000000544a:  57                   push      di
0x000000000000544b:  1E                   push      ds
0x000000000000544c:  07                   pop       es
0x000000000000544d:  8A E0                mov       ah, al
0x000000000000544f:  D1 E9                shr       cx, 1
0x0000000000005451:  F3 AB                rep stosw 
0x0000000000005453:  13 C9                adc       cx, cx
0x0000000000005455:  F3 AA                rep stosb 
0x0000000000005457:  5F                   pop       di
0x0000000000005458:  46                   inc       si
0x0000000000005459:  83 46 FC 09          add       word ptr [bp - 4], 9
0x000000000000545d:  83 FE 04             cmp       si, 4
0x0000000000005460:  7C 95                jl        0x53f7
0x0000000000005462:  C9                   LEAVE_MACRO     
0x0000000000005463:  5F                   pop       di
0x0000000000005464:  5E                   pop       si
0x0000000000005465:  5A                   pop       dx
0x0000000000005466:  59                   pop       cx
0x0000000000005467:  5B                   pop       bx
0x0000000000005468:  C3                   ret       
0x0000000000005469:  80 FA 01             cmp       dl, 1
0x000000000000546c:  75 0C                jne       0x547a
0x000000000000546e:  BA 83 24             mov       dx, 0x2483
0x0000000000005471:  89 C7                mov       di, ax
0x0000000000005473:  8E C2                mov       es, dx
0x0000000000005475:  83 C7 04             add       di, 4
0x0000000000005478:  EB B2                jmp       0x542c
0x000000000000547a:  84 D2                test      dl, dl
0x000000000000547c:  75 B5                jne       0x5433
0x000000000000547e:  BA 83 24             mov       dx, 0x2483
0x0000000000005481:  89 C7                mov       di, ax
0x0000000000005483:  8E C2                mov       es, dx
0x0000000000005485:  EB A5                jmp       0x542c

ENDP

PROC    EV_DoDonut_  NEAR
PUBLIC  EV_DoDonut_


0x0000000000005488:  53                   push      bx
0x0000000000005489:  51                   push      cx
0x000000000000548a:  52                   push      dx
0x000000000000548b:  56                   push      si
0x000000000000548c:  57                   push      di
0x000000000000548d:  55                   push      bp
0x000000000000548e:  89 E5                mov       bp, sp
0x0000000000005490:  81 EC 0A 08          sub       sp, 0x80a
0x0000000000005494:  8D 96 F6 FD          lea       dx, [bp - 0x20a]
0x0000000000005498:  98                   cwde      
0x0000000000005499:  31 DB                xor       bx, bx
0x000000000000549b:  C7 46 F8 FF FF       mov       word ptr [bp - 8], 0xffff
0x00000000000054a0:  E8 1D F4             call      0x48c0
0x00000000000054a3:  31 C9                xor       cx, cx
0x00000000000054a5:  83 BE F6 FD FF       cmp       word ptr [bp - 0x20a], -1
0x00000000000054aa:  74 27                je        0x54d3
0x00000000000054ac:  31 F6                xor       si, si
0x00000000000054ae:  8B 82 F6 FD          mov       ax, word ptr [bp + si - 0x20a]
0x00000000000054b2:  85 C0                test      ax, ax
0x00000000000054b4:  7C 26                jl        0x54dc
0x00000000000054b6:  89 46 FE             mov       word ptr [bp - 2], ax
0x00000000000054b9:  89 C3                mov       bx, ax
0x00000000000054bb:  B8 90 21             mov       ax, SECTORS_SEGMENT
0x00000000000054be:  C1 E3 04             shl       bx, 4
0x00000000000054c1:  8E C0                mov       es, ax
0x00000000000054c3:  83 C6 02             add       si, 2
0x00000000000054c6:  26 8B 47 0C          mov       ax, word ptr es:[bx + 0xc]
0x00000000000054ca:  83 C3 0C             add       bx, 0xc
0x00000000000054cd:  89 82 F4 F9          mov       word ptr [bp + si - 0x60c], ax
0x00000000000054d1:  EB DB                jmp       0x54ae
0x00000000000054d3:  31 C0                xor       ax, ax
0x00000000000054d5:  C9                   LEAVE_MACRO     
0x00000000000054d6:  5F                   pop       di
0x00000000000054d7:  5E                   pop       si
0x00000000000054d8:  5A                   pop       dx
0x00000000000054d9:  59                   pop       cx
0x00000000000054da:  5B                   pop       bx
0x00000000000054db:  C3                   ret       
0x00000000000054dc:  C7 82 F6 F9 FF FF    mov       word ptr [bp + si - 0x60a], 0xffff
0x00000000000054e2:  31 F6                xor       si, si
0x00000000000054e4:  83 BE F6 F9 00       cmp       word ptr [bp - 0x60a], 0
0x00000000000054e9:  7C 21                jl        0x550c
0x00000000000054eb:  8B 82 F6 F9          mov       ax, word ptr [bp + si - 0x60a]
0x00000000000054ef:  89 46 FE             mov       word ptr [bp - 2], ax
0x00000000000054f2:  01 C0                add       ax, ax
0x00000000000054f4:  83 C6 02             add       si, 2
0x00000000000054f7:  89 C3                mov       bx, ax
0x00000000000054f9:  8B 87 50 CA          mov       ax, word ptr ds:[bx - 0x35b0]
0x00000000000054fd:  89 82 F4 F9          mov       word ptr [bp + si - 0x60c], ax
0x0000000000005501:  81 C3 50 CA          add       bx, OFFSET _linebuffer
0x0000000000005505:  83 BA F6 F9 00       cmp       word ptr [bp + si - 0x60a], 0
0x000000000000550a:  7D DF                jge       0x54eb
0x000000000000550c:  BF 00 70             mov       di, 0x7000
0x000000000000550f:  31 C0                xor       ax, ax
0x0000000000005511:  89 C6                mov       si, ax
0x0000000000005513:  01 C6                add       si, ax
0x0000000000005515:  83 BA F6 F9 00       cmp       word ptr [bp + si - 0x60a], 0
0x000000000000551a:  7C 36                jl        0x5552
0x000000000000551c:  BA 4A 2B             mov       dx, 0x2b4a
0x000000000000551f:  8B 9A F6 F9          mov       bx, word ptr [bp + si - 0x60a]
0x0000000000005523:  8B B2 F6 F9          mov       si, word ptr [bp + si - 0x60a]
0x0000000000005527:  8E C2                mov       es, dx
0x0000000000005529:  C1 E3 04             shl       bx, 4
0x000000000000552c:  26 F6 04 04          test      byte ptr es:[si], 4
0x0000000000005530:  75 04                jne       0x5536
0x0000000000005532:  41                   inc       cx
0x0000000000005533:  40                   inc       ax
0x0000000000005534:  EB DB                jmp       0x5511
0x0000000000005536:  89 C6                mov       si, ax
0x0000000000005538:  8E C7                mov       es, di
0x000000000000553a:  29 CE                sub       si, cx
0x000000000000553c:  26 8B 57 0A          mov       dx, word ptr es:[bx + 0xa]
0x0000000000005540:  01 F6                add       si, si
0x0000000000005542:  3B 56 FE             cmp       dx, word ptr [bp - 2]
0x0000000000005545:  75 04                jne       0x554b
0x0000000000005547:  26 8B 57 0C          mov       dx, word ptr es:[bx + 0xc]
0x000000000000554b:  89 92 F6 FD          mov       word ptr [bp + si - 0x20a], dx
0x000000000000554f:  40                   inc       ax
0x0000000000005550:  EB BF                jmp       0x5511
0x0000000000005552:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000005555:  C1 E0 04             shl       ax, 4
0x0000000000005558:  89 76 FC             mov       word ptr [bp - 4], si
0x000000000000555b:  89 46 FA             mov       word ptr [bp - 6], ax
0x000000000000555e:  8B 76 FC             mov       si, word ptr [bp - 4]
0x0000000000005561:  8B 82 F6 FD          mov       ax, word ptr [bp + si - 0x20a]
0x0000000000005565:  85 C0                test      ax, ax
0x0000000000005567:  7D 03                jge       0x556c
0x0000000000005569:  E9 0B 01             jmp       0x5677
0x000000000000556c:  89 46 F6             mov       word ptr [bp - 0xa], ax
0x000000000000556f:  C1 E0 04             shl       ax, 4
0x0000000000005572:  BA 90 21             mov       dx, SECTORS_SEGMENT
0x0000000000005575:  89 C3                mov       bx, ax
0x0000000000005577:  8E C2                mov       es, dx
0x0000000000005579:  83 C3 0A             add       bx, 0xa
0x000000000000557c:  8D BE F6 F7          lea       di, [bp - 0x80a]
0x0000000000005580:  26 8B 17             mov       dx, word ptr es:[bx]
0x0000000000005583:  89 C3                mov       bx, ax
0x0000000000005585:  89 D1                mov       cx, dx
0x0000000000005587:  26 8B 77 0C          mov       si, word ptr es:[bx + 0xc]
0x000000000000558b:  83 C3 0C             add       bx, 0xc
0x000000000000558e:  01 F6                add       si, si
0x0000000000005590:  01 D1                add       cx, dx
0x0000000000005592:  81 C6 50 CA          add       si, OFFSET _linebuffer
0x0000000000005596:  8D 9E F6 FB          lea       bx, [bp - 0x40a]
0x000000000000559a:  57                   push      di
0x000000000000559b:  8C D8                mov       ax, ds
0x000000000000559d:  8E C0                mov       es, ax
0x000000000000559f:  D1 E9                shr       cx, 1
0x00000000000055a1:  F3 A5                rep movsw 
0x00000000000055a3:  13 C9                adc       cx, cx
0x00000000000055a5:  F3 A4                rep movsb 
0x00000000000055a7:  5F                   pop       di
0x00000000000055a8:  6A 01                push      1
0x00000000000055aa:  8D 86 F6 F7          lea       ax, [bp - 0x80a]
0x00000000000055ae:  89 D1                mov       cx, dx
0x00000000000055b0:  8B 56 F8             mov       dx, word ptr [bp - 8]
0x00000000000055b3:  E8 56 F0             call      getNextSectorList_
0x00000000000055b6:  89 C3                mov       bx, ax
0x00000000000055b8:  89 C2                mov       dx, ax
0x00000000000055ba:  31 C0                xor       ax, ax
0x00000000000055bc:  85 DB                test      bx, bx
0x00000000000055be:  7E 9E                jle       0x555e
0x00000000000055c0:  31 F6                xor       si, si
0x00000000000055c2:  8B 9A F6 FB          mov       bx, word ptr [bp + si - 0x40a]
0x00000000000055c6:  3B 5E FE             cmp       bx, word ptr [bp - 2]
0x00000000000055c9:  75 03                jne       0x55ce
0x00000000000055cb:  E9 9B 00             jmp       0x5669
0x00000000000055ce:  89 DA                mov       dx, bx
0x00000000000055d0:  B8 90 21             mov       ax, SECTORS_SEGMENT
0x00000000000055d3:  C1 E2 04             shl       dx, 4
0x00000000000055d6:  8E C0                mov       es, ax
0x00000000000055d8:  89 D3                mov       bx, dx
0x00000000000055da:  BF 2C 00             mov       di, 0x2c
0x00000000000055dd:  26 8A 47 04          mov       al, byte ptr es:[bx + 4]
0x00000000000055e1:  83 C3 04             add       bx, 4
0x00000000000055e4:  30 E4                xor       ah, ah
0x00000000000055e6:  89 D3                mov       bx, dx
0x00000000000055e8:  89 C1                mov       cx, ax
0x00000000000055ea:  26 8B 1F             mov       bx, word ptr es:[bx]
0x00000000000055ed:  B8 00 28             mov       ax, 0x2800
0x00000000000055f0:  31 D2                xor       dx, dx
0x00000000000055f2:  0E                   push      cs
0x00000000000055f3:  E8 34 0F             call      0x652a
0x00000000000055f6:  90                   nop       
0x00000000000055f7:  89 C6                mov       si, ax
0x00000000000055f9:  2D 04 34             sub       ax, 0x3404
0x00000000000055fc:  F7 F7                div       di
0x00000000000055fe:  8B 56 F6             mov       dx, word ptr [bp - 0xa]
0x0000000000005601:  C1 E2 04             shl       dx, 4
0x0000000000005604:  89 D7                mov       di, dx
0x0000000000005606:  89 85 38 DE          mov       word ptr ds:[di - 0x21c8], ax
0x000000000000560a:  C6 04 0B             mov       byte ptr [si], 0xb
0x000000000000560d:  C6 44 04 01          mov       byte ptr [si + 4], 1
0x0000000000005611:  C7 44 09 04 00       mov       word ptr ds:[si + 9], 4
0x0000000000005616:  88 6C 01             mov       byte ptr [si + 1], ch
0x0000000000005619:  88 4C 06             mov       byte ptr [si + 6], cl
0x000000000000561c:  88 6C 05             mov       byte ptr [si + 5], ch
0x000000000000561f:  8B 46 F6             mov       ax, word ptr [bp - 0xa]
0x0000000000005622:  89 5C 07             mov       word ptr ds:[si + 7], bx
0x0000000000005625:  31 D2                xor       dx, dx
0x0000000000005627:  89 44 02             mov       word ptr ds:[si + 2], ax
0x000000000000562a:  B8 00 28             mov       ax, 0x2800
0x000000000000562d:  B9 2C 00             mov       cx, 0x2c
0x0000000000005630:  0E                   push      cs
0x0000000000005631:  E8 F6 0E             call      0x652a
0x0000000000005634:  90                   nop       
0x0000000000005635:  89 C6                mov       si, ax
0x0000000000005637:  2D 04 34             sub       ax, 0x3404
0x000000000000563a:  F7 F1                div       cx
0x000000000000563c:  81 C7 38 DE          add       di, 0xde38
0x0000000000005640:  8B 56 FA             mov       dx, word ptr [bp - 6]
0x0000000000005643:  89 D7                mov       di, dx
0x0000000000005645:  89 85 38 DE          mov       word ptr ds:[di - 0x21c8], ax
0x0000000000005649:  C6 04 00             mov       byte ptr [si], 0
0x000000000000564c:  C6 44 01 00          mov       byte ptr [si + 1], 0
0x0000000000005650:  C6 44 04 FF          mov       byte ptr [si + 4], 0xff
0x0000000000005654:  C7 44 09 04 00       mov       word ptr ds:[si + 9], 4
0x0000000000005659:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x000000000000565c:  89 5C 07             mov       word ptr ds:[si + 7], bx
0x000000000000565f:  81 C7 38 DE          add       di, 0xde38
0x0000000000005663:  89 44 02             mov       word ptr ds:[si + 2], ax
0x0000000000005666:  E9 F5 FE             jmp       0x555e
0x0000000000005669:  40                   inc       ax
0x000000000000566a:  83 C6 02             add       si, 2
0x000000000000566d:  39 D0                cmp       ax, dx
0x000000000000566f:  7D 03                jge       0x5674
0x0000000000005671:  E9 4E FF             jmp       0x55c2
0x0000000000005674:  E9 E7 FE             jmp       0x555e
0x0000000000005677:  B8 01 00             mov       ax, 1
0x000000000000567a:  C9                   LEAVE_MACRO     
0x000000000000567b:  5F                   pop       di
0x000000000000567c:  5E                   pop       si
0x000000000000567d:  5A                   pop       dx
0x000000000000567e:  59                   pop       cx
0x000000000000567f:  5B                   pop       bx
0x0000000000005680:  C3                   ret    




ENDP

dw 05719h, 05720h, 0572Ch, 0573Bh, 05702h, 05702h, 05702h, 0574Ah, 05751h, 05770h, 05702h, 0577Ch, 0578Eh, 057A0h, 05702h, 05702h, 057ACh

PROC    P_SpawnSpecials_  NEAR
PUBLIC  P_SpawnSpecials_



0x00000000000056a4:  53                   push      bx
0x00000000000056a5:  51                   push      cx
0x00000000000056a6:  52                   push      dx
0x00000000000056a7:  56                   push      si
0x00000000000056a8:  57                   push      di
0x00000000000056a9:  55                   push      bp
0x00000000000056aa:  89 E5                mov       bp, sp
0x00000000000056ac:  83 EC 04             sub       sp, 4
0x00000000000056af:  B8 64 18             mov       ax, 0x1864
0x00000000000056b2:  0E                   push      cs
0x00000000000056b3:  E8 4E 1C             call      0x7304
0x00000000000056b6:  90                   nop       
0x00000000000056b7:  31 C9                xor       cx, cx
0x00000000000056b9:  31 FF                xor       di, di
0x00000000000056bb:  C6 06 49 20 00       mov       byte ptr [0x2049], 0
0x00000000000056c0:  BB CE 05             mov       bx, 0x5ce
0x00000000000056c3:  3B 0F                cmp       cx, word ptr ds:[bx]
0x00000000000056c5:  7C 29                jl        0x56f0
0x00000000000056c7:  31 C0                xor       ax, ax
0x00000000000056c9:  31 C9                xor       cx, cx
0x00000000000056cb:  31 D2                xor       dx, dx
0x00000000000056cd:  A3 4A 1F             mov       word ptr [0x1f4a], ax
0x00000000000056d0:  BB D0 05             mov       bx, 0x5d0
0x00000000000056d3:  3B 07                cmp       ax, word ptr ds:[bx]
0x00000000000056d5:  7D 61                jge       0x5738
0x00000000000056d7:  BB 00 70             mov       bx, 0x7000
0x00000000000056da:  89 CE                mov       si, cx
0x00000000000056dc:  8E C3                mov       es, bx
0x00000000000056de:  26 8A 5C 0F          mov       bl, byte ptr es:[si + 0xf]
0x00000000000056e2:  83 C6 0F             add       si, 0xf
0x00000000000056e5:  80 FB 30             cmp       bl, 0x30
0x00000000000056e8:  74 6E                je        0x5758
0x00000000000056ea:  83 C1 10             add       cx, 0x10
0x00000000000056ed:  40                   inc       ax
0x00000000000056ee:  EB E0                jmp       0x56d0
0x00000000000056f0:  89 7E FC             mov       word ptr [bp - 4], di
0x00000000000056f3:  8D B5 3E DE          lea       si, [di - 0x21c2]
0x00000000000056f7:  8A 04                mov       al, byte ptr [si]
0x00000000000056f9:  C7 46 FE 00 00       mov       word ptr [bp - 2], 0
0x00000000000056fe:  84 C0                test      al, al
0x0000000000005700:  75 06                jne       0x5708
0x0000000000005702:  83 C7 10             add       di, 0x10
0x0000000000005705:  41                   inc       cx
0x0000000000005706:  EB B8                jmp       0x56c0
0x0000000000005708:  FE C8                dec       al
0x000000000000570a:  3C 10                cmp       al, 0x10
0x000000000000570c:  77 F4                ja        0x5702
0x000000000000570e:  30 E4                xor       ah, ah
0x0000000000005710:  89 C3                mov       bx, ax
0x0000000000005712:  01 C3                add       bx, ax
0x0000000000005714:  2E FF A7 82 56       jmp       word ptr cs:[bx + 0x5682]
0x0000000000005719:  89 C8                mov       ax, cx
0x000000000000571b:  E8 A6 E7             call      0x3ec4
0x000000000000571e:  EB E2                jmp       0x5702
0x0000000000005720:  BA 0F 00             mov       dx, 0xf
0x0000000000005723:  89 C8                mov       ax, cx
0x0000000000005725:  31 DB                xor       bx, bx
0x0000000000005727:  E8 48 E8             call      0x3f72
0x000000000000572a:  EB D6                jmp       0x5702
0x000000000000572c:  BA 23 00             mov       dx, 0x23
0x000000000000572f:  89 C8                mov       ax, cx
0x0000000000005731:  31 DB                xor       bx, bx
0x0000000000005733:  E8 3C E8             call      0x3f72
0x0000000000005736:  EB CA                jmp       0x5702
0x0000000000005738:  E9 7D 00             jmp       0x57b8
0x000000000000573b:  BA 0F 00             mov       dx, 0xf
0x000000000000573e:  89 C8                mov       ax, cx
0x0000000000005740:  31 DB                xor       bx, bx
0x0000000000005742:  E8 2D E8             call      0x3f72
0x0000000000005745:  C6 04 04             mov       byte ptr [si], 4
0x0000000000005748:  EB B8                jmp       0x5702
0x000000000000574a:  89 C8                mov       ax, cx
0x000000000000574c:  E8 11 EA             call      0x4160
0x000000000000574f:  EB B1                jmp       0x5702
0x0000000000005751:  BB 20 01             mov       bx, 0x120
0x0000000000005754:  FF 07                inc       word ptr ds:[bx]
0x0000000000005756:  EB AA                jmp       0x5702
0x0000000000005758:  BB D8 4C             mov       bx, 0x4cd8
0x000000000000575b:  89 D6                mov       si, dx
0x000000000000575d:  8E C3                mov       es, bx
0x000000000000575f:  83 C2 02             add       dx, 2
0x0000000000005762:  FF 06 4A 1F          inc       word ptr [0x1f4a]
0x0000000000005766:  26 89 04             mov       word ptr es:[si], ax
0x0000000000005769:  83 C1 10             add       cx, 0x10
0x000000000000576c:  40                   inc       ax
0x000000000000576d:  E9 60 FF             jmp       0x56d0
0x0000000000005770:  89 C8                mov       ax, cx
0x0000000000005772:  E8 9D D0             call      0x2812
0x0000000000005775:  83 C7 10             add       di, 0x10
0x0000000000005778:  41                   inc       cx
0x0000000000005779:  E9 44 FF             jmp       0x56c0
0x000000000000577c:  BB 01 00             mov       bx, 1
0x000000000000577f:  BA 23 00             mov       dx, 0x23
0x0000000000005782:  89 C8                mov       ax, cx
0x0000000000005784:  E8 EB E7             call      0x3f72
0x0000000000005787:  83 C7 10             add       di, 0x10
0x000000000000578a:  41                   inc       cx
0x000000000000578b:  E9 32 FF             jmp       0x56c0
0x000000000000578e:  BB 01 00             mov       bx, 1
0x0000000000005791:  BA 0F 00             mov       dx, 0xf
0x0000000000005794:  89 C8                mov       ax, cx
0x0000000000005796:  E8 D9 E7             call      0x3f72
0x0000000000005799:  83 C7 10             add       di, 0x10
0x000000000000579c:  41                   inc       cx
0x000000000000579d:  E9 20 FF             jmp       0x56c0
0x00000000000057a0:  89 C8                mov       ax, cx
0x00000000000057a2:  E8 B5 D0             call      0x285a
0x00000000000057a5:  83 C7 10             add       di, 0x10
0x00000000000057a8:  41                   inc       cx
0x00000000000057a9:  E9 14 FF             jmp       0x56c0
0x00000000000057ac:  89 C8                mov       ax, cx
0x00000000000057ae:  E8 7F E6             call      0x3e30
0x00000000000057b1:  83 C7 10             add       di, 0x10
0x00000000000057b4:  41                   inc       cx
0x00000000000057b5:  E9 08 FF             jmp       0x56c0
0x00000000000057b8:  B9 3C 00             mov       cx, 0x3c
0x00000000000057bb:  BF 00 06             mov       di, 0x600
0x00000000000057be:  30 C0                xor       al, al
0x00000000000057c0:  57                   push      di
0x00000000000057c1:  1E                   push      ds
0x00000000000057c2:  07                   pop       es
0x00000000000057c3:  8A E0                mov       ah, al
0x00000000000057c5:  D1 E9                shr       cx, 1
0x00000000000057c7:  F3 AB                rep stosw 
0x00000000000057c9:  13 C9                adc       cx, cx
0x00000000000057cb:  F3 AA                rep stosb 
0x00000000000057cd:  5F                   pop       di
0x00000000000057ce:  B9 3C 00             mov       cx, 0x3c
0x00000000000057d1:  BF 6C 1D             mov       di, 0x1d6c
0x00000000000057d4:  57                   push      di
0x00000000000057d5:  1E                   push      ds
0x00000000000057d6:  07                   pop       es
0x00000000000057d7:  8A E0                mov       ah, al
0x00000000000057d9:  D1 E9                shr       cx, 1
0x00000000000057db:  F3 AB                rep stosw 
0x00000000000057dd:  13 C9                adc       cx, cx
0x00000000000057df:  F3 AA                rep stosb 
0x00000000000057e1:  5F                   pop       di
0x00000000000057e2:  B9 24 00             mov       cx, 0x24
0x00000000000057e5:  BF 40 1D             mov       di, 0x1d40
0x00000000000057e8:  57                   push      di
0x00000000000057e9:  1E                   push      ds
0x00000000000057ea:  07                   pop       es
0x00000000000057eb:  8A E0                mov       ah, al
0x00000000000057ed:  D1 E9                shr       cx, 1
0x00000000000057ef:  F3 AB                rep stosw 
0x00000000000057f1:  13 C9                adc       cx, cx
0x00000000000057f3:  F3 AA                rep stosb 
0x00000000000057f5:  5F                   pop       di
0x00000000000057f6:  C9                   LEAVE_MACRO     
0x00000000000057f7:  5F                   pop       di
0x00000000000057f8:  5E                   pop       si
0x00000000000057f9:  5A                   pop       dx
0x00000000000057fa:  59                   pop       cx
0x00000000000057fb:  5B                   pop       bx
0x00000000000057fc:  CB                   retf      

ENDP

@



PROC    P_SPEC_ENDMARKER_ 
PUBLIC  P_SPEC_ENDMARKER_
ENDP


END
