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


EXTRN FixedMul16u32_:FAR
EXTRN FixedMul1632_:FAR
EXTRN FixedMul2424_:FAR
EXTRN FixedMul2432_:FAR
EXTRN FixedMul_:FAR
EXTRN FixedDiv_:FAR
EXTRN FixedMulBig1632_:FAR
EXTRN FixedMulTrigNoShift_:PROC
EXTRN S_StartSound_:FAR
EXTRN R_PointToAngle2_16_:PROC
EXTRN R_PointToAngle2_:PROC
EXTRN P_Random_:NEAR
EXTRN P_UseSpecialLine_:PROC
EXTRN P_DamageMobj_:NEAR
EXTRN P_SetMobjState_:NEAR
EXTRN P_TouchSpecialThing_:NEAR
EXTRN P_CrossSpecialLine_:NEAR
EXTRN P_ShootSpecialLine_:NEAR
EXTRN P_SpawnMobj_:NEAR
EXTRN P_RemoveMobj_:NEAR


.DATA

EXTRN _prndindex:BYTE
EXTRN _setStateReturn:WORD
EXTRN _attackrange16:WORD
EXTRN _currentThinkerListHead:WORD

.CODE



; THINKERREF __near P_GetNextThinkerRef(void) 

;P_GetNextThinkerRef_

PROC P_GetNextThinkerRef_ NEAR
PUBLIC P_GetNextThinkerRef_
; todo inline in only used spot?

push      bx
push      dx
mov       dx, word ptr ds:[_currentThinkerListHead]
mov       ax, dx
inc       ax
cmp       ax, dx
je        error_no_thinker_found

imul      bx, ax, SIZEOF_THINKER_T ; get initial thinker offset
add       bx, OFFSET _thinkerlist
loop_check_next_thinker:
cmp       ax, MAX_THINKERS
jne       use_current_thinker_index
xor       ax, ax
mov       bx, OFFSET _thinkerlist
use_current_thinker_index: 
cmp       word ptr ds:[bx], MAX_THINKERS
je        found_thinker
inc       ax
add       bx, SIZEOF_THINKER_T
cmp       ax, dx
jne       loop_check_next_thinker
error_no_thinker_found:
mov       ax, -1
mov       word ptr ds:[_currentThinkerListHead], dx
pop       dx
pop       bx
ret       
found_thinker:
mov       dx, ax
mov       word ptr ds:[_currentThinkerListHead], dx
pop       dx
pop       bx
ret       

ENDP

COMMENT @

PROC P_CreateThinker_ NEAR
PUBLIC P_CreateThinker_


push      bx
push      cx
push      dx
push      si
mov       dx, ax
mov       bx, OFFSET _thinkerlist
call      P_GetNextThinkerRef_
mov       cx, word ptr [bx]
imul      bx, ax, SIZEOF_THINKER_T
add       dx, cx
imul      si, cx, SIZEOF_THINKER_T
mov       word ptr ds:[bx + _thinkerlist + 2], 0
mov       word ptr ds:[bx + _thinkerlist], dx
mov       word ptr ds:[si + _thinkerlist + 2], ax
mov       si, OFFSET _thinkerlist
mov       word ptr [si], ax
lea       ax, [bx + _thinkerlist + 4]
pop       si
pop       dx
pop       cx
pop       bx
retf      

ENDP

PROC P_UpdateThinkerFunc_ NEAR
PUBLIC P_UpdateThinkerFunc_

push      bx
imul      bx, ax, SIZEOF_THINKER_T
mov       ax, word ptr ds:[bx + _thinkerlist]
and       ah, 7
add       dx, ax
mov       word ptr ds:[bx + _thinkerlist], dx
pop       bx
ret       

ENDP

PROC P_RemoveThinker_ NEAR
PUBLIC P_RemoveThinker_

;	thinkerlist[thinkerRef].prevFunctype = (thinkerlist[thinkerRef].prevFunctype & TF_PREVBITS) + TF_DELETEME_HIGHBITS;


push      bx
imul      bx, ax, SIZEOF_THINKER_T
mov       ax, word ptr ds:[bx + _thinkerlist]
and       ah, 7
add       ah, (TF_DELETEME_HIGHBITS SHR 8)
mov       word ptr ds:[bx + _thinkerlist], ax
pop       bx
ret       


ENDP

PROC P_RunThinkers_ NEAR
PUBLIC P_RunThinkers_

0x0000000000000092:  53                   push      bx
0x0000000000000093:  51                   push      cx
0x0000000000000094:  52                   push      dx
0x0000000000000095:  56                   push      si
0x0000000000000096:  57                   push      di
0x0000000000000097:  55                   push      bp
0x0000000000000098:  89 E5                mov       bp, sp
0x000000000000009a:  83 EC 04             sub       sp, 4
0x000000000000009d:  BE 02 40             mov       si, OFFSET _thinkerlist + 2
0x00000000000000a0:  8B 34                mov       si, word ptr [si]
0x00000000000000a2:  85 F6                test      si, si
0x00000000000000a4:  74 49                je        0xef
0x00000000000000a6:  6B DE 2C             imul      bx, si, SIZEOF_THINKER_T
0x00000000000000a9:  6B D6 18             imul      dx, si, 0x18
0x00000000000000ac:  8B 87 00 40          mov       ax, word ptr ds:[bx + _thinkerlist]
0x00000000000000b0:  89 5E FE             mov       word ptr [bp - 2], bx
0x00000000000000b3:  30 C0                xor       al, al
0x00000000000000b5:  8D BF 04 40          lea       di, ds:[bx + _thinkerlist + 4]
0x00000000000000b9:  80 E4 F8             and       ah, 0xf8
0x00000000000000bc:  89 56 FC             mov       word ptr [bp - 4], dx
0x00000000000000bf:  3D 00 50             cmp       ax, 0x5000
0x00000000000000c2:  74 37                je        0xfb
0x00000000000000c4:  85 C0                test      ax, ax
0x00000000000000c6:  74 1C                je        0xe4
0x00000000000000c8:  3D 00 28             cmp       ax, 0x2800
0x00000000000000cb:  73 29                jae       0xf6
0x00000000000000cd:  3D 00 10             cmp       ax, 0x1000
0x00000000000000d0:  73 26                jae       0xf8
0x00000000000000d2:  3D 00 08             cmp       ax, 0x800
0x00000000000000d5:  75 0D                jne       0xe4
0x00000000000000d7:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x00000000000000da:  B9 F5 6A             mov       cx, 0x6af5
0x00000000000000dd:  89 F2                mov       dx, si
0x00000000000000df:  89 F8                mov       ax, di
0x00000000000000e1:  E8 26 F2             call      0xf30a
0x00000000000000e4:  6B F6 2C             imul      si, si, SIZEOF_THINKER_T
0x00000000000000e7:  8B B4 02 40          mov       si, word ptr ds:[si + _thinkerlist + 2]
0x00000000000000eb:  85 F6                test      si, si
0x00000000000000ed:  75 B7                jne       0xa6
0x00000000000000ef:  C9                   leave     
0x00000000000000f0:  5F                   pop       di
0x00000000000000f1:  5E                   pop       si
0x00000000000000f2:  5A                   pop       dx
0x00000000000000f3:  59                   pop       cx
0x00000000000000f4:  5B                   pop       bx
0x00000000000000f5:  C3                   ret       
0x00000000000000f6:  EB 5B                jmp       0x153
0x00000000000000f8:  E9 87 00             jmp       0x182
0x00000000000000fb:  8B 97 02 40          mov       dx, word ptr ds:[bx + _thinkerlist + 2]
0x00000000000000ff:  8B 87 00 40          mov       ax, word ptr ds:[bx + _thinkerlist + 0]
0x0000000000000103:  6B DA 2C             imul      bx, dx, SIZEOF_THINKER_T
0x0000000000000106:  C6 87 00 40 00       mov       byte ptr ds:[bx + _thinkerlist], 0
0x000000000000010b:  80 E4 07             and       ah, 7
0x000000000000010e:  80 A7 01 40 F8       and       byte ptr ds:[bx + _thinkerlist+1], 0xf8
0x0000000000000113:  01 87 00 40          add       word ptr ds:[bx + _thinkerlist], ax
0x0000000000000117:  6B D8 2C             imul      bx, ax, SIZEOF_THINKER_T
0x000000000000011a:  B9 28 00             mov       cx, 0x28
0x000000000000011d:  30 C0                xor       al, al
0x000000000000011f:  89 97 02 40          mov       word ptr [bx + 0x4002], dx
0x0000000000000123:  57                   push      di
0x0000000000000124:  1E                   push      ds
0x0000000000000125:  07                   pop       es
0x0000000000000126:  8A E0                mov       ah, al
0x0000000000000128:  D1 E9                shr       cx, 1
0x000000000000012a:  F3 AB                rep stosw word ptr es:[di], ax
0x000000000000012c:  13 C9                adc       cx, cx
0x000000000000012e:  F3 AA                rep stosb byte ptr es:[di], al
0x0000000000000130:  5F                   pop       di
0x0000000000000131:  B9 18 00             mov       cx, 0x18
0x0000000000000134:  BA F5 6A             mov       dx, MOBJPOSLIST_6800_SEGMENT
0x0000000000000137:  8B 7E FC             mov       di, word ptr [bp - 4]
0x000000000000013a:  8E C2                mov       es, dx
0x000000000000013c:  8B 5E FE             mov       bx, word ptr [bp - 2]
0x000000000000013f:  57                   push      di
0x0000000000000140:  8A E0                mov       ah, al
0x0000000000000142:  D1 E9                shr       cx, 1
0x0000000000000144:  F3 AB                rep stosw word ptr es:[di], ax
0x0000000000000146:  13 C9                adc       cx, cx
0x0000000000000148:  F3 AA                rep stosb byte ptr es:[di], al
0x000000000000014a:  5F                   pop       di
0x000000000000014b:  C7 87 00 40 48 03    mov       word ptr ds:[bx + _thinkerlist], MAX_THINKERS
0x0000000000000151:  EB 91                jmp       0xe4
0x0000000000000153:  76 57                jbe       0x1ac
0x0000000000000155:  3D 00 38             cmp       ax, TF_LIGHTFLASH_HIGHBITS
0x0000000000000158:  73 0F                jae       0x169
0x000000000000015a:  3D 00 30             cmp       ax, 03000h
0x000000000000015d:  75 85                jne       0xe4
0x000000000000015f:  89 F2                mov       dx, si
0x0000000000000161:  89 F8                mov       ax, di
0x0000000000000163:  E8 9A 92             call      0x9400
0x0000000000000166:  E9 7B FF             jmp       0xe4
0x0000000000000169:  76 4B                jbe       0x1b6
0x000000000000016b:  3D 00 48             cmp       ax, TF_GLOW_HIGHBITS
0x000000000000016e:  74 50                je        0x1c0
0x0000000000000170:  3D 00 40             cmp       ax, TF_STROBEFLASH_HIGHBITS
0x0000000000000173:  74 03                je        0x178
0x0000000000000175:  E9 6C FF             jmp       0xe4
0x0000000000000178:  89 F2                mov       dx, si
0x000000000000017a:  89 F8                mov       ax, di
0x000000000000017c:  E8 E5 93             call      0x9564
0x000000000000017f:  E9 62 FF             jmp       0xe4
0x0000000000000182:  76 14                jbe       0x198
0x0000000000000184:  3D 00 20             cmp       ax, TF_VERTICALDOOR_HIGHBITS
0x0000000000000187:  74 19                je        0x1a2
0x0000000000000189:  3D 00 18             cmp       ax, TF_MOVECEILING_HIGHBITS
0x000000000000018c:  75 E7                jne       0x175
0x000000000000018e:  89 F2                mov       dx, si
0x0000000000000190:  89 F8                mov       ax, di
0x0000000000000192:  E8 97 4D             call      0x4f2c
0x0000000000000195:  E9 4C FF             jmp       0xe4
0x0000000000000198:  89 F2                mov       dx, si
0x000000000000019a:  89 F8                mov       ax, di
0x000000000000019c:  E8 D9 B9             call      0xbb78
0x000000000000019f:  E9 42 FF             jmp       0xe4
0x00000000000001a2:  89 F2                mov       dx, si
0x00000000000001a4:  89 F8                mov       ax, di
0x00000000000001a6:  E8 2D 51             call      0x52d6
0x00000000000001a9:  E9 38 FF             jmp       0xe4
0x00000000000001ac:  89 F2                mov       dx, si
0x00000000000001ae:  89 F8                mov       ax, di
0x00000000000001b0:  E8 DB 7F             call      0x818e
0x00000000000001b3:  E9 2E FF             jmp       0xe4
0x00000000000001b6:  89 F2                mov       dx, si
0x00000000000001b8:  89 F8                mov       ax, di
0x00000000000001ba:  E8 F7 92             call      0x94b4
0x00000000000001bd:  E9 24 FF             jmp       0xe4
0x00000000000001c0:  89 F2                mov       dx, si
0x00000000000001c2:  89 F8                mov       ax, di
0x00000000000001c4:  E8 6B 95             call      0x9732
0x00000000000001c7:  E9 1A FF             jmp       0xe4
0x00000000000001ca:  80 3E 6C 22 00       cmp       byte ptr ds:[_paused], 0
0x00000000000001cf:  75 1C                jne       0x1ed
0x00000000000001d1:  80 3E 81 22 00       cmp       byte ptr ds:[_menuactive], 0
0x00000000000001d6:  74 16                je        0x1ee
0x00000000000001d8:  80 3E 70 22 00       cmp       byte ptr ds:[_demoplayback], 0
0x00000000000001dd:  75 0F                jne       0x1ee
0x00000000000001df:  83 3E E9 21 00       cmp       word ptr ds:[_player + 8 + 2], 0
0x00000000000001e4:  75 07                jne       0x1ed
0x00000000000001e6:  83 3E E7 21 01       cmp       word ptr ds:[_player + 8 + 0], 1    ; player.viewzvalue
0x00000000000001eb:  74 01                je        0x1ee
0x00000000000001ed:  CB                   retf      
ENDP

PROC P_Ticker_ NEAR
PUBLIC P_Ticker_

0x00000000000001ee:  E8 81 04             call      0x672
0x00000000000001f1:  E8 9E FE             call      0x92
0x00000000000001f4:  E8 71 D5             call      0xd768
0x00000000000001f7:  83 06 28 1D 01       add       word ptr ds:[_leveltime], 1
0x00000000000001fc:  83 16 2A 1D 00       adc       word ptr ds:[_leveltime], 0
0x0000000000000201:  CB                   retf  

ENDP

@
END