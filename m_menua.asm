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


EXTRN P_RemoveThinker_:NEAR
EXTRN P_CreateThinker_:NEAR
EXTRN V_DrawPatchDirect_:FAR
EXTRN Z_QuickMapStatus_:FAR
EXTRN S_SetSfxVolume_:FAR
EXTRN getStringByIndex_:FAR
EXTRN locallib_far_fread_:FAR
EXTRN fclose_:PROC
EXTRN fopen_:PROC
EXTRN makesavegamename_:PROC
EXTRN G_LoadGame_:PROC

.DATA




.CODE





PROC    M_MENU_STARTMARKER_ NEAR
PUBLIC  M_MENU_STARTMARKER_
ENDP


MENUGRAPHICS_PAGE0_SEGMENT = 05000h
MENUGRAPHICS_PAGE4_SEGMENT = 06400h


PROC    M_GetMenuPatch_ NEAR
PUBLIC  M_GetMenuPatch_


0x0000000000004120:  53                   push  bx
0x0000000000004121:  89 C3                mov   bx, ax
0x0000000000004123:  01 C3                add   bx, ax
0x0000000000004125:  3D 1B 00             cmp   ax, 27   ; number of menu graphics in first menu page. Todo unhardcode?
0x0000000000004128:  7C 0D                jl    label_1
0x000000000000412a:  B8 C7 6E             mov   ax, MENUOFFSETS_SEGMENT ; todo use offset in cs?
0x000000000000412d:  8E C0                mov   es, ax
0x000000000000412f:  BA 00 64             mov   dx, MENUGRAPHICS_PAGE4_SEGMENT
0x0000000000004132:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000004135:  5B                   pop   bx
0x0000000000004136:  C3                   ret   
label_1:
0x0000000000004137:  B8 C7 6E             mov   ax, MENUOFFSETS_SEGMENT
0x000000000000413a:  8E C0                mov   es, ax
0x000000000000413c:  BA 00 50             mov   dx, MENUGRAPHICS_PAGE0_SEGMENT
0x000000000000413f:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000004142:  5B                   pop   bx
0x0000000000004143:  C3                   ret   

weird_label_out_here:
0x0000000000004144:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000004147:  98                   cbw  
0x0000000000004148:  6B D8 18             imul  bx, ax, SAVESTRINGSIZE
0x000000000000414b:  B9 B1 3C             mov   cx, SAVEGAMESTRINGS_SEGMENT
0x000000000000414e:  B8 17 00             mov   ax, EMPTYSTRING
0x0000000000004152:  3E E8 D0 C2          call  getStringByIndex_
0x0000000000004156:  C6 85 97 10 00       mov   byte ptr [di + _LoadMenu + MENUITEM_T.menuitem_status], 0
0x000000000000415b:  E9 63 01             jmp   weird_label_out_here_back

ENDP

LOAD_END = 6

PROC    M_DrawLoad_ NEAR
PUBLIC  M_DrawLoad_


0x000000000000415e:  53                   push  bx
0x000000000000415f:  51                   push  cx
0x0000000000004160:  52                   push  dx
0x0000000000004161:  55                   push  bp
0x0000000000004162:  89 E5                mov   bp, sp
0x0000000000004164:  83 EC 02             sub   sp, 2
0x0000000000004167:  9A 7D 2C 4F 13       call  Z_QuickMapStatus_
0x000000000000416c:  B8 1E 00             mov   ax, 30
0x000000000000416f:  E8 AE FF             call  M_GetMenuPatch_
0x0000000000004172:  89 C3                mov   bx, ax
0x0000000000004174:  89 D1                mov   cx, dx
0x0000000000004176:  BA 1C 00             mov   dx, 28
0x0000000000004179:  B8 48 00             mov   ax, 72
0x000000000000417c:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
0x0000000000004180:  9A CC 26 4F 13       call  V_DrawPatchDirect_
label_2:
0x0000000000004185:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000004188:  98                   cbw  
0x0000000000004189:  8A 16 BE 10          mov   dl, byte ptr [_LoadDef + MENU_T.menu_y]
0x000000000000418d:  89 C3                mov   bx, ax
0x000000000000418f:  30 F6                xor   dh, dh
0x0000000000004191:  C1 E3 04             shl   bx, 4
0x0000000000004194:  A1 BC 10             mov   ax, word ptr [_LoadDef + MENU_T.menu_x]
0x0000000000004197:  01 DA                add   dx, bx
0x0000000000004199:  E8 28 00             call  M_DrawSaveLoadBorder_
0x000000000000419c:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x000000000000419f:  98                   cbw  
0x00000000000041a0:  6B C8 18             imul  cx, ax, SAVESTRINGSIZE
0x00000000000041a3:  8A 16 BE 10          mov   dl, byte ptr [_LoadDef + MENU_T.menu_y]
0x00000000000041a7:  30 F6                xor   dh, dh
0x00000000000041a9:  01 DA                add   dx, bx
0x00000000000041ab:  A1 BC 10             mov   ax, word ptr [_LoadDef + MENU_T.menu_x]
0x00000000000041ae:  89 CB                mov   bx, cx
0x00000000000041b0:  B9 B1 3C             mov   cx, SAVEGAMESTRINGS_SEGMENT
0x00000000000041b3:  FE 46 FE             inc   byte ptr [bp - 2]
0x00000000000041b6:  E8 29 0B             call  M_WriteText_
0x00000000000041b9:  80 7E FE 06          cmp   byte ptr [bp - 2], LOAD_END
0x00000000000041bd:  7C C6                jl    label_2
0x00000000000041bf:  C9                   LEAVE_MACRO 
0x00000000000041c0:  5A                   pop   dx
0x00000000000041c1:  59                   pop   cx
0x00000000000041c2:  5B                   pop   bx
0x00000000000041c3:  C3                   ret   


ENDP

PROC    M_DrawSaveLoadBorder_ NEAR
PUBLIC  M_DrawSaveLoadBorder_


0x00000000000041c4:  53                   push  bx
0x00000000000041c5:  51                   push  cx
0x00000000000041c6:  56                   push  si
0x00000000000041c7:  57                   push  di
0x00000000000041c8:  55                   push  bp
0x00000000000041c9:  89 E5                mov   bp, sp
0x00000000000041cb:  83 EC 04             sub   sp, 4
0x00000000000041ce:  89 C6                mov   si, ax
0x00000000000041d0:  89 D7                mov   di, dx
0x00000000000041d2:  B8 2A 00             mov   ax, 0x2a
0x00000000000041d5:  E8 48 FF             call  M_GetMenuPatch_
0x00000000000041d8:  89 F3                mov   bx, si
0x00000000000041da:  83 C7 07             add   di, 7
0x00000000000041dd:  83 EB 08             sub   bx, 8
0x00000000000041e0:  89 D1                mov   cx, dx
0x00000000000041e2:  89 5E FC             mov   word ptr [bp - 4], bx
0x00000000000041e5:  89 FA                mov   dx, di
0x00000000000041e7:  89 C3                mov   bx, ax
0x00000000000041e9:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x00000000000041ec:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
0x00000000000041f0:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x00000000000041f5:  FC                   cld   
0x00000000000041f6:  B8 2B 00             mov   ax, 0x2b
0x00000000000041f9:  E8 24 FF             call  M_GetMenuPatch_
0x00000000000041fc:  89 C3                mov   bx, ax
0x00000000000041fe:  89 D1                mov   cx, dx
0x0000000000004200:  89 FA                mov   dx, di
0x0000000000004202:  89 F0                mov   ax, si
0x0000000000004204:  FE 46 FE             inc   byte ptr [bp - 2]
0x0000000000004207:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x000000000000420c:  83 C6 08             add   si, 8
0x000000000000420f:  80 7E FE 18          cmp   byte ptr [bp - 2], 0x18
0x0000000000004213:  7C E1                jl    0x41f6
0x0000000000004215:  B8 2C 00             mov   ax, 0x2c
0x0000000000004218:  E8 05 FF             call  M_GetMenuPatch_
0x000000000000421b:  89 C3                mov   bx, ax
0x000000000000421d:  89 D1                mov   cx, dx
0x000000000000421f:  89 FA                mov   dx, di
0x0000000000004221:  89 F0                mov   ax, si
0x0000000000004223:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004228:  C9                   LEAVE_MACRO 
0x0000000000004229:  5F                   pop   di
0x000000000000422a:  5E                   pop   si
0x000000000000422b:  59                   pop   cx
0x000000000000422c:  5B                   pop   bx
0x000000000000422d:  C3                   ret   


ENDP

PROC    M_LoadSelect_ NEAR
PUBLIC  M_LoadSelect_


0x000000000000422e:  53                   push  bx
0x000000000000422f:  52                   push  dx
0x0000000000004230:  55                   push  bp
0x0000000000004231:  89 E5                mov   bp, sp
0x0000000000004233:  81 EC 00 01          sub   sp, 0100h
0x0000000000004237:  98                   cbw  
0x0000000000004238:  8C DA                mov   dx, ds
0x000000000000423a:  89 C3                mov   bx, ax
0x000000000000423c:  8D 86 00 FF          lea   ax, [bp - 0100h]
0x0000000000004240:  0E                   push  cs
0x0000000000004241:  E8 B2 CA             call  makesavegamename_
0x0000000000004244:  90                   nop   
0x0000000000004245:  8D 86 00 FF          lea   ax, [bp - 0100h]
0x0000000000004249:  BB 6C 04             mov   bx, 0x46c
0x000000000000424c:  0E                   push  cs
0x000000000000424d:  E8 6E D6             call  G_LoadGame_
0x0000000000004250:  90                   nop   
0x0000000000004251:  C6 07 00             mov   byte ptr [bx], 0
0x0000000000004254:  C9                   LEAVE_MACRO 
0x0000000000004255:  5A                   pop   dx
0x0000000000004256:  5B                   pop   bx
0x0000000000004257:  C3                   ret   


ENDP

PROC    M_LoadGame_ NEAR
PUBLIC  M_LoadGame_

0x0000000000004258:  A1 BF 10             mov   ax, word ptr [0x10bf]
0x000000000000425b:  C7 06 0E 1F B5 10    mov   word ptr [0x1f0e], 0x10b5
0x0000000000004261:  A3 12 1F             mov   word ptr [0x1f12], ax



ENDP  ; fall thru?

PROC    M_ReadSaveStrings_ NEAR
PUBLIC  M_ReadSaveStrings_

0x0000000000004264:  53                   push  bx
0x0000000000004265:  51                   push  cx
0x0000000000004266:  52                   push  dx
0x0000000000004267:  56                   push  si
0x0000000000004268:  57                   push  di
0x0000000000004269:  55                   push  bp
0x000000000000426a:  89 E5                mov   bp, sp
0x000000000000426c:  81 EC 02 01          sub   sp, 0102h
0x0000000000004270:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
label_6:
0x0000000000004274:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000004277:  98                   cbw  
0x0000000000004278:  89 C1                mov   cx, ax
0x000000000000427a:  6B F9 05             imul  di, cx, 5
0x000000000000427d:  8C DA                mov   dx, ds
0x000000000000427f:  89 C3                mov   bx, ax
0x0000000000004281:  8D 86 FE FE          lea   ax, [bp - 0102h]
0x0000000000004285:  0E                   push  cs
0x0000000000004286:  3E E8 6C CA          call  makesavegamename_
0x000000000000428a:  BA D4 19             mov   dx, OFFSET _fopen_rb_argument
0x000000000000428d:  8D 86 FE FE          lea   ax, [bp - 0102h]
0x0000000000004291:  9A A3 31 4F 13       call  fopen_
0x0000000000004296:  89 C6                mov   si, ax
0x0000000000004298:  85 C0                test  ax, ax
0x000000000000429a:  75 03                jne   label_7
0x000000000000429c:  E9 A5 FE             jmp   weird_label_out_here
label_7:
0x000000000000429f:  50                   push  ax
0x00000000000042a0:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x00000000000042a3:  98                   cbw  
0x00000000000042a4:  6B C0 18             imul  ax, ax, SAVESTRINGSIZE
0x00000000000042a7:  B9 18 00             mov   cx, SAVESTRINGSIZE
0x00000000000042aa:  BB 01 00             mov   bx, 1
0x00000000000042ad:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x00000000000042b0:  9A 00 22 4F 13       call  locallib_far_fread_
0x00000000000042b5:  89 F0                mov   ax, si
0x00000000000042b7:  9A 37 34 4F 13       call  fclose_
0x00000000000042bc:  C6 85 97 10 01       mov   byte ptr [di + _LoadMenu + MENUITEM_T.menuitem_status], 1
weird_label_out_here_back:
0x00000000000042c1:  FE 46 FE             inc   byte ptr [bp - 2]
0x00000000000042c4:  80 7E FE 06          cmp   byte ptr [bp - 2], 6
0x00000000000042c8:  7C AA                jl    label_6
0x00000000000042ca:  C9                   LEAVE_MACRO 
0x00000000000042cb:  5F                   pop   di
0x00000000000042cc:  5E                   pop   si
0x00000000000042cd:  5A                   pop   dx
0x00000000000042ce:  59                   pop   cx
0x00000000000042cf:  5B                   pop   bx
0x00000000000042d0:  C3                   ret   
0x00000000000042d1:  FC                   cld   


ENDP

PROC    M_DrawSave_ NEAR
PUBLIC  M_DrawSave_

0x00000000000042d2:  53                   push  bx
0x00000000000042d3:  51                   push  cx
0x00000000000042d4:  52                   push  dx
0x00000000000042d5:  55                   push  bp
0x00000000000042d6:  89 E5                mov   bp, sp
0x00000000000042d8:  83 EC 02             sub   sp, 2
0x00000000000042db:  9A 7D 2C 4F 13       call  Z_QuickMapStatus_
0x00000000000042e0:  B8 1D 00             mov   ax, 0x1d
0x00000000000042e3:  E8 3A FE             call  M_GetMenuPatch_
0x00000000000042e6:  89 C3                mov   bx, ax
0x00000000000042e8:  89 D1                mov   cx, dx
0x00000000000042ea:  BA 1C 00             mov   dx, 0x1c
0x00000000000042ed:  B8 48 00             mov   ax, 0x48
0x00000000000042f0:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
0x00000000000042f4:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x00000000000042f9:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x00000000000042fc:  98                   cbw  
0x00000000000042fd:  8A 16 BE 10          mov   dl, byte ptr [_LoadDef + MENU_T.menu_y]
0x0000000000004301:  89 C3                mov   bx, ax
0x0000000000004303:  30 F6                xor   dh, dh
0x0000000000004305:  C1 E3 04             shl   bx, 4
0x0000000000004308:  A1 BC 10             mov   ax, word ptr [_LoadDef + MENU_T.menu_x]
0x000000000000430b:  01 DA                add   dx, bx
0x000000000000430d:  E8 B4 FE             call  M_DrawSaveLoadBorder_
0x0000000000004310:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000004313:  98                   cbw  
0x0000000000004314:  6B C8 18             imul  cx, ax, SAVESTRINGSIZE
0x0000000000004317:  A0 BE 10             mov   al, byte ptr [_LoadDef + MENU_T.menu_y]
0x000000000000431a:  30 E4                xor   ah, ah
0x000000000000431c:  89 C2                mov   dx, ax
0x000000000000431e:  A1 BC 10             mov   ax, word ptr [_LoadDef + MENU_T.menu_x]
0x0000000000004321:  01 DA                add   dx, bx
0x0000000000004323:  89 CB                mov   bx, cx
0x0000000000004325:  B9 B1 3C             mov   cx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004328:  FE 46 FE             inc   byte ptr [bp - 2]
0x000000000000432b:  E8 B4 09             call  M_WriteText_
0x000000000000432e:  80 7E FE 06          cmp   byte ptr [bp - 2], 6
0x0000000000004332:  7C C5                jl    0x42f9
0x0000000000004334:  83 3E 10 1F 00       cmp   word ptr [0x1f10], 0
0x0000000000004339:  75 05                jne   0x4340
0x000000000000433b:  C9                   LEAVE_MACRO 
0x000000000000433c:  5A                   pop   dx
0x000000000000433d:  59                   pop   cx
0x000000000000433e:  5B                   pop   bx
0x000000000000433f:  C3                   ret   
0x0000000000004340:  6B 06 18 1F 18       imul  ax, word ptr [0x1f18], SAVESTRINGSIZE
0x0000000000004345:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004348:  8C D9                mov   cx, ds
0x000000000000434a:  E8 F3 08             call  M_StringWidth_
0x000000000000434d:  8A 16 BE 10          mov   dl, byte ptr [_LoadDef + MENU_T.menu_y]
0x0000000000004351:  8B 1E 18 1F          mov   bx, word ptr [0x1f18]
0x0000000000004355:  98                   cbw  
0x0000000000004356:  C1 E3 04             shl   bx, 4
0x0000000000004359:  30 F6                xor   dh, dh
0x000000000000435b:  03 06 BC 10          add   ax, word ptr [_LoadDef + MENU_T.menu_x]
0x000000000000435f:  01 DA                add   dx, bx
0x0000000000004361:  BB D7 19             mov   bx, 0x19d7
0x0000000000004364:  E8 7B 09             call  M_WriteText_
0x0000000000004367:  C9                   LEAVE_MACRO 
0x0000000000004368:  5A                   pop   dx
0x0000000000004369:  59                   pop   cx
0x000000000000436a:  5B                   pop   bx
0x000000000000436b:  C3                   ret   


ENDP

PROC    M_DoSave_ NEAR
PUBLIC  M_DoSave_

0x000000000000436c:  53                   push  bx
0x000000000000436d:  51                   push  cx
0x000000000000436e:  52                   push  dx
0x000000000000436f:  89 C2                mov   dx, ax
0x0000000000004371:  6B D8 18             imul  bx, ax, SAVESTRINGSIZE
0x0000000000004374:  B9 B1 3C             mov   cx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004377:  98                   cbw  
0x0000000000004378:  0E                   push  cs
0x0000000000004379:  E8 B4 D6             call  0x1a30
0x000000000000437c:  90                   nop   
0x000000000000437d:  BB 6C 04             mov   bx, 0x46c
0x0000000000004380:  C6 07 00             mov   byte ptr [bx], 0
0x0000000000004383:  80 3E 21 20 FE       cmp   byte ptr [0x2021], 0xfe
0x0000000000004388:  74 04                je    0x438e
0x000000000000438a:  5A                   pop   dx
0x000000000000438b:  59                   pop   cx
0x000000000000438c:  5B                   pop   bx
0x000000000000438d:  C3                   ret   
0x000000000000438e:  88 16 21 20          mov   byte ptr [0x2021], dl
0x0000000000004392:  5A                   pop   dx
0x0000000000004393:  59                   pop   cx
0x0000000000004394:  5B                   pop   bx
0x0000000000004395:  C3                   ret   



ENDP

PROC    M_SaveSelect_ NEAR
PUBLIC  M_SaveSelect_


0x0000000000004396:  53                   push  bx
0x0000000000004397:  51                   push  cx
0x0000000000004398:  52                   push  dx
0x0000000000004399:  56                   push  si
0x000000000000439a:  57                   push  di
0x000000000000439b:  55                   push  bp
0x000000000000439c:  89 E5                mov   bp, sp
0x000000000000439e:  81 EC 00 01          sub   sp, 0x100
0x00000000000043a2:  89 C7                mov   di, ax
0x00000000000043a4:  6B C8 18             imul  cx, ax, SAVESTRINGSIZE
0x00000000000043a7:  C7 06 10 1F 01 00    mov   word ptr [0x1f10], 1
0x00000000000043ad:  30 D2                xor   dl, dl
0x00000000000043af:  A3 18 1F             mov   word ptr [0x1f18], ax
0x00000000000043b2:  88 D0                mov   al, dl
0x00000000000043b4:  98                   cbw  
0x00000000000043b5:  3D 18 00             cmp   ax, SAVESTRINGSIZE
0x00000000000043b8:  73 19                jae   0x43d3
0x00000000000043ba:  88 D0                mov   al, dl
0x00000000000043bc:  98                   cbw  
0x00000000000043bd:  89 CE                mov   si, cx
0x00000000000043bf:  89 C3                mov   bx, ax
0x00000000000043c1:  01 C6                add   si, ax
0x00000000000043c3:  B8 B1 3C             mov   ax, SAVEGAMESTRINGS_SEGMENT
0x00000000000043c6:  8E C0                mov   es, ax
0x00000000000043c8:  26 8A 04             mov   al, byte ptr es:[si]
0x00000000000043cb:  FE C2                inc   dl
0x00000000000043cd:  88 87 70 1C          mov   byte ptr [bx + 0x1c70], al
0x00000000000043d1:  EB DF                jmp   0x43b2
0x00000000000043d3:  6B F7 18             imul  si, di, SAVESTRINGSIZE
0x00000000000043d6:  8D 9E 00 FF          lea   bx, [bp - 0x100]
0x00000000000043da:  B8 17 00             mov   ax, 0x17
0x00000000000043dd:  8C D9                mov   cx, ds
0x00000000000043df:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x00000000000043e2:  0E                   push  cs
0x00000000000043e3:  E8 40 C0             call  0x426
0x00000000000043e6:  90                   nop   
0x00000000000043e7:  8D 9E 00 FF          lea   bx, [bp - 0x100]
0x00000000000043eb:  8C D9                mov   cx, ds
0x00000000000043ed:  89 F0                mov   ax, si
0x00000000000043ef:  0E                   push  cs
0x00000000000043f0:  3E E8 56 C8          call  0xc4a
0x00000000000043f4:  85 C0                test  ax, ax
0x00000000000043f6:  75 09                jne   0x4401
0x00000000000043f8:  B8 B1 3C             mov   ax, SAVEGAMESTRINGS_SEGMENT
0x00000000000043fb:  8E C0                mov   es, ax
0x00000000000043fd:  26 C6 04 00          mov   byte ptr es:[si], 0
0x0000000000004401:  6B C7 18             imul  ax, di, SAVESTRINGSIZE
0x0000000000004404:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004407:  0E                   push  cs
0x0000000000004408:  3E E8 9A C0          call  0x4a6
0x000000000000440c:  A3 14 1F             mov   word ptr [0x1f14], ax
0x000000000000440f:  C9                   LEAVE_MACRO 
0x0000000000004410:  5F                   pop   di
0x0000000000004411:  5E                   pop   si
0x0000000000004412:  5A                   pop   dx
0x0000000000004413:  59                   pop   cx
0x0000000000004414:  5B                   pop   bx
0x0000000000004415:  C3                   ret   


ENDP

PROC    M_SaveGame_ NEAR
PUBLIC  M_SaveGame_


0x0000000000004416:  53                   push  bx
0x0000000000004417:  51                   push  cx
0x0000000000004418:  52                   push  dx
0x0000000000004419:  55                   push  bp
0x000000000000441a:  89 E5                mov   bp, sp
0x000000000000441c:  81 EC 00 01          sub   sp, 0x100
0x0000000000004420:  80 3E 1D 20 00       cmp   byte ptr [0x201d], 0
0x0000000000004425:  74 0D                je    0x4434
0x0000000000004427:  BB 9F 01             mov   bx, 0x19f
0x000000000000442a:  80 3F 00             cmp   byte ptr [bx], 0
0x000000000000442d:  74 20                je    0x444f
0x000000000000442f:  C9                   LEAVE_MACRO 
0x0000000000004430:  5A                   pop   dx
0x0000000000004431:  59                   pop   cx
0x0000000000004432:  5B                   pop   bx
0x0000000000004433:  C3                   ret   
0x0000000000004434:  8D 9E 00 FF          lea   bx, [bp - 0x100]
0x0000000000004438:  B8 06 00             mov   ax, 6
0x000000000000443b:  8C D9                mov   cx, ds
0x000000000000443d:  0E                   push  cs
0x000000000000443e:  3E E8 E4 BF          call  0x426
0x0000000000004442:  31 D2                xor   dx, dx
0x0000000000004444:  8D 86 00 FF          lea   ax, [bp - 0x100]
0x0000000000004448:  31 DB                xor   bx, bx
0x000000000000444a:  E8 B3 07             call  0x4c00
0x000000000000444d:  EB E0                jmp   0x442f
0x000000000000444f:  A1 E9 10             mov   ax, word ptr [0x10e9]
0x0000000000004452:  C7 06 0E 1F DF 10    mov   word ptr [0x1f0e], 0x10df
0x0000000000004458:  A3 12 1F             mov   word ptr [0x1f12], ax
0x000000000000445b:  E8 06 FE             call  0x4264
0x000000000000445e:  C9                   LEAVE_MACRO 
0x000000000000445f:  5A                   pop   dx
0x0000000000004460:  59                   pop   cx
0x0000000000004461:  5B                   pop   bx
0x0000000000004462:  C3                   ret   
0x0000000000004463:  FC                   cld   

ENDP

PROC    M_QuickSaveResponse_ NEAR
PUBLIC  M_QuickSaveResponse_

0x0000000000004464:  52                   push  dx
0x0000000000004465:  3D 79 00             cmp   ax, 0x79
0x0000000000004468:  74 02                je    0x446c
0x000000000000446a:  5A                   pop   dx
0x000000000000446b:  C3                   ret   
0x000000000000446c:  A0 21 20             mov   al, byte ptr [0x2021]
0x000000000000446f:  98                   cbw  
0x0000000000004470:  BA 18 00             mov   dx, SAVESTRINGSIZE
0x0000000000004473:  E8 F6 FE             call  0x436c
0x0000000000004476:  31 C0                xor   ax, ax
0x0000000000004478:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000447d:  5A                   pop   dx
0x000000000000447e:  C3                   ret   
0x000000000000447f:  FC                   cld   


ENDP

PROC    M_QuickSave_ NEAR
PUBLIC  M_QuickSave_

0x0000000000004480:  53                   push  bx
0x0000000000004481:  51                   push  cx
0x0000000000004482:  52                   push  dx
0x0000000000004483:  55                   push  bp
0x0000000000004484:  89 E5                mov   bp, sp
0x0000000000004486:  81 EC E2 00          sub   sp, 0xe2
0x000000000000448a:  81 ED 98 00          sub   bp, 0x98
0x000000000000448e:  A0 1D 20             mov   al, byte ptr [0x201d]
0x0000000000004491:  84 C0                test  al, al
0x0000000000004493:  74 6C                je    0x4501
0x0000000000004495:  BB 9F 01             mov   bx, 0x19f
0x0000000000004498:  80 3F 00             cmp   byte ptr [bx], 0
0x000000000000449b:  75 5B                jne   0x44f8
0x000000000000449d:  80 3E 21 20 00       cmp   byte ptr [0x2021], 0
0x00000000000044a2:  7C 69                jl    0x450d
0x00000000000044a4:  8D 5E 4C             lea   bx, [bp + 0x4c]
0x00000000000044a7:  B8 07 00             mov   ax, 7
0x00000000000044aa:  8C D9                mov   cx, ds
0x00000000000044ac:  0E                   push  cs
0x00000000000044ad:  E8 76 BF             call  0x426
0x00000000000044b0:  90                   nop   
0x00000000000044b1:  8D 5E 7E             lea   bx, [bp + 0x7e]
0x00000000000044b4:  B8 31 01             mov   ax, 0x131
0x00000000000044b7:  8C D9                mov   cx, ds
0x00000000000044b9:  0E                   push  cs
0x00000000000044ba:  3E E8 68 BF          call  0x426
0x00000000000044be:  A0 21 20             mov   al, byte ptr [0x2021]
0x00000000000044c1:  98                   cbw  
0x00000000000044c2:  6B C0 18             imul  ax, ax, SAVESTRINGSIZE
0x00000000000044c5:  8C DA                mov   dx, ds
0x00000000000044c7:  68 B1 3C             push  SAVEGAMESTRINGS_SEGMENT
0x00000000000044ca:  8D 5E 4C             lea   bx, [bp + 0x4c]
0x00000000000044cd:  8C D9                mov   cx, ds
0x00000000000044cf:  50                   push  ax
0x00000000000044d0:  8D 46 B6             lea   ax, [bp - 0x4a]
0x00000000000044d3:  0E                   push  cs
0x00000000000044d4:  3E E8 B0 C6          call  0xb88
0x00000000000044d8:  8D 46 7E             lea   ax, [bp + 0x7e]
0x00000000000044db:  8D 5E B6             lea   bx, [bp - 0x4a]
0x00000000000044de:  8C DA                mov   dx, ds
0x00000000000044e0:  1E                   push  ds
0x00000000000044e1:  8C D9                mov   cx, ds
0x00000000000044e3:  50                   push  ax
0x00000000000044e4:  8D 46 B6             lea   ax, [bp - 0x4a]
0x00000000000044e7:  0E                   push  cs
0x00000000000044e8:  3E E8 9C C6          call  0xb88
0x00000000000044ec:  BB 01 00             mov   bx, 1
0x00000000000044ef:  BA 64 44             mov   dx, 0x4464
0x00000000000044f2:  8D 46 B6             lea   ax, [bp - 0x4a]
0x00000000000044f5:  E8 08 07             call  0x4c00
0x00000000000044f8:  8D A6 98 00          lea   sp, [bp + 0x98]
0x00000000000044fc:  5D                   pop   bp
0x00000000000044fd:  5A                   pop   dx
0x00000000000044fe:  59                   pop   cx
0x00000000000044ff:  5B                   pop   bx
0x0000000000004500:  C3                   ret   
0x0000000000004501:  BA 22 00             mov   dx, 0x22
0x0000000000004504:  30 E4                xor   ah, ah
0x0000000000004506:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000450b:  EB EB                jmp   0x44f8
0x000000000000450d:  E8 52 0E             call  M_StartControlPanel_
0x0000000000004510:  E8 51 FD             call  0x4264
0x0000000000004513:  C7 06 0E 1F DF 10    mov   word ptr [0x1f0e], 0x10df
0x0000000000004519:  A1 E9 10             mov   ax, word ptr [0x10e9]
0x000000000000451c:  C6 06 21 20 FE       mov   byte ptr [0x2021], 0xfe
0x0000000000004521:  A3 12 1F             mov   word ptr [0x1f12], ax
0x0000000000004524:  8D A6 98 00          lea   sp, [bp + 0x98]
0x0000000000004528:  5D                   pop   bp
0x0000000000004529:  5A                   pop   dx
0x000000000000452a:  59                   pop   cx
0x000000000000452b:  5B                   pop   bx
0x000000000000452c:  C3                   ret   
0x000000000000452d:  FC                   cld   


ENDP

PROC    M_QuickLoadResponse_ NEAR
PUBLIC  M_QuickLoadResponse_


0x000000000000452e:  52                   push  dx
0x000000000000452f:  3D 79 00             cmp   ax, 'y' ; 0x79
0x0000000000004532:  74 02                je    label_3
0x0000000000004534:  5A                   pop   dx
0x0000000000004535:  C3                   ret   
label_3:
0x0000000000004536:  A0 21 20             mov   al, byte ptr [0x2021]
0x0000000000004539:  98                   cbw  
0x000000000000453a:  BA 18 00             mov   dx, SFX_SWTCHX
0x000000000000453d:  E8 EE FC             call  S_StartSound_
0x0000000000004540:  31 C0                xor   ax, ax
0x0000000000004542:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000004547:  5A                   pop   dx
0x0000000000004548:  C3                   ret   
0x0000000000004549:  FC                   cld   



ENDP

PROC    M_QuickLoad_ NEAR
PUBLIC  M_QuickLoad_


0x000000000000454a:  53                   push  bx
0x000000000000454b:  51                   push  cx
0x000000000000454c:  52                   push  dx
0x000000000000454d:  55                   push  bp
0x000000000000454e:  89 E5                mov   bp, sp
0x0000000000004550:  81 EC E2 00          sub   sp, 0xe2
0x0000000000004554:  81 ED 98 00          sub   bp, 0x98
0x0000000000004558:  80 3E 21 20 00       cmp   byte ptr [0x2021], 0
0x000000000000455d:  7C 5D                jl    0x45bc
0x000000000000455f:  8D 5E 4C             lea   bx, [bp + 0x4c]
0x0000000000004562:  B8 08 00             mov   ax, 8
0x0000000000004565:  8C D9                mov   cx, ds
0x0000000000004567:  0E                   push  cs
0x0000000000004568:  3E E8 BA BE          call  0x426
0x000000000000456c:  8D 5E 7E             lea   bx, [bp + 0x7e]
0x000000000000456f:  B8 31 01             mov   ax, 0x131
0x0000000000004572:  8C D9                mov   cx, ds
0x0000000000004574:  0E                   push  cs
0x0000000000004575:  E8 AE BE             call  0x426
0x0000000000004578:  90                   nop   
0x0000000000004579:  A0 21 20             mov   al, byte ptr [0x2021]
0x000000000000457c:  98                   cbw  
0x000000000000457d:  6B C0 18             imul  ax, ax, SAVESTRINGSIZE
0x0000000000004580:  8C DA                mov   dx, ds
0x0000000000004582:  68 B1 3C             push  SAVEGAMESTRINGS_SEGMENT
0x0000000000004585:  8D 5E 4C             lea   bx, [bp + 0x4c]
0x0000000000004588:  8C D9                mov   cx, ds
0x000000000000458a:  50                   push  ax
0x000000000000458b:  8D 46 B6             lea   ax, [bp - 0x4a]
0x000000000000458e:  0E                   push  cs
0x000000000000458f:  E8 F6 C5             call  0xb88
0x0000000000004592:  90                   nop   
0x0000000000004593:  8D 56 7E             lea   dx, [bp + 0x7e]
0x0000000000004596:  8D 5E B6             lea   bx, [bp - 0x4a]
0x0000000000004599:  8D 46 B6             lea   ax, [bp - 0x4a]
0x000000000000459c:  1E                   push  ds
0x000000000000459d:  8C D9                mov   cx, ds
0x000000000000459f:  52                   push  dx
0x00000000000045a0:  8C DA                mov   dx, ds
0x00000000000045a2:  0E                   push  cs
0x00000000000045a3:  E8 E2 C5             call  0xb88
0x00000000000045a6:  90                   nop   
0x00000000000045a7:  BB 01 00             mov   bx, 1
0x00000000000045aa:  BA 2E 45             mov   dx, 0x452e
0x00000000000045ad:  8D 46 B6             lea   ax, [bp - 0x4a]
0x00000000000045b0:  E8 4D 06             call  0x4c00
0x00000000000045b3:  8D A6 98 00          lea   sp, [bp + 0x98]
0x00000000000045b7:  5D                   pop   bp
0x00000000000045b8:  5A                   pop   dx
0x00000000000045b9:  59                   pop   cx
0x00000000000045ba:  5B                   pop   bx
0x00000000000045bb:  C3                   ret   
0x00000000000045bc:  8D 5E B6             lea   bx, [bp - 0x4a]
0x00000000000045bf:  B8 05 00             mov   ax, 5
0x00000000000045c2:  8C D9                mov   cx, ds
0x00000000000045c4:  0E                   push  cs
0x00000000000045c5:  E8 5E BE             call  0x426
0x00000000000045c8:  90                   nop   
0x00000000000045c9:  31 D2                xor   dx, dx
0x00000000000045cb:  8D 46 B6             lea   ax, [bp - 0x4a]
0x00000000000045ce:  31 DB                xor   bx, bx
0x00000000000045d0:  E8 2D 06             call  0x4c00
0x00000000000045d3:  8D A6 98 00          lea   sp, [bp + 0x98]
0x00000000000045d7:  5D                   pop   bp
0x00000000000045d8:  5A                   pop   dx
0x00000000000045d9:  59                   pop   cx
0x00000000000045da:  5B                   pop   bx
0x00000000000045db:  C3                   ret   



ENDP

PROC    M_DrawReadThis1_ NEAR
PUBLIC  M_DrawReadThis1_

0x00000000000045dc:  52                   push  dx
0x00000000000045dd:  B8 D9 19             mov   ax, 0x19d9
0x00000000000045e0:  31 D2                xor   dx, dx
0x00000000000045e2:  C6 06 20 20 01       mov   byte ptr [0x2020], 1
0x00000000000045e7:  9A 4E 2A 4F 13       lcall 0x134f:0x2a4e
0x00000000000045ec:  5A                   pop   dx
0x00000000000045ed:  C3                   ret   


ENDP

PROC    M_DrawReadThis2_ NEAR
PUBLIC  M_DrawReadThis2_


0x00000000000045ee:  52                   push  dx
0x00000000000045ef:  B8 DF 19             mov   ax, 0x19df
0x00000000000045f2:  31 D2                xor   dx, dx
0x00000000000045f4:  C6 06 20 20 01       mov   byte ptr [0x2020], 1
0x00000000000045f9:  9A 4E 2A 4F 13       lcall 0x134f:0x2a4e
0x00000000000045fe:  5A                   pop   dx
0x00000000000045ff:  C3                   ret   


ENDP

PROC    M_DrawReadThisRetail_ NEAR
PUBLIC  M_DrawReadThisRetail_

0x0000000000004600:  52                   push  dx
0x0000000000004601:  B8 E5 19             mov   ax, 0x19e5
0x0000000000004604:  31 D2                xor   dx, dx
0x0000000000004606:  C6 06 20 20 01       mov   byte ptr [0x2020], 1
0x000000000000460b:  9A 4E 2A 4F 13       lcall 0x134f:0x2a4e
0x0000000000004610:  5A                   pop   dx
0x0000000000004611:  C3                   ret   


ENDP

PROC    M_DrawSound_ NEAR
PUBLIC  M_DrawSound_


0x0000000000004612:  53                   push  bx
0x0000000000004613:  51                   push  cx
0x0000000000004614:  52                   push  dx
0x0000000000004615:  B8 1B 00             mov   ax, 0x1b
0x0000000000004618:  E8 05 FB             call  M_GetMenuPatch_
0x000000000000461b:  89 D1                mov   cx, dx
0x000000000000461d:  89 C3                mov   bx, ax
0x000000000000461f:  BA 26 00             mov   dx, 0x26
0x0000000000004622:  B8 3C 00             mov   ax, 0x3c
0x0000000000004625:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x000000000000462a:  BB 10 00             mov   bx, 0x10
0x000000000000462d:  A0 94 10             mov   al, byte ptr [0x1094]
0x0000000000004630:  8A 0E 25 20          mov   cl, byte ptr [0x2025]
0x0000000000004634:  30 E4                xor   ah, ah
0x0000000000004636:  30 ED                xor   ch, ch
0x0000000000004638:  89 C2                mov   dx, ax
0x000000000000463a:  A1 92 10             mov   ax, word ptr [0x1092]
0x000000000000463d:  83 C2 10             add   dx, 0x10
0x0000000000004640:  E8 39 05             call  0x4b7c
0x0000000000004643:  BB 10 00             mov   bx, 0x10
0x0000000000004646:  A0 94 10             mov   al, byte ptr [0x1094]
0x0000000000004649:  8A 0E 2F 20          mov   cl, byte ptr [0x202f]
0x000000000000464d:  30 E4                xor   ah, ah
0x000000000000464f:  30 ED                xor   ch, ch
0x0000000000004651:  89 C2                mov   dx, ax
0x0000000000004653:  A1 92 10             mov   ax, word ptr [0x1092]
0x0000000000004656:  83 C2 30             add   dx, 0x30
0x0000000000004659:  E8 20 05             call  0x4b7c
0x000000000000465c:  5A                   pop   dx
0x000000000000465d:  59                   pop   cx
0x000000000000465e:  5B                   pop   bx
0x000000000000465f:  C3                   ret   



ENDP

PROC    M_Sound_ NEAR
PUBLIC  M_Sound_


0x0000000000004660:  A1 95 10             mov   ax, word ptr [0x1095]
0x0000000000004663:  C7 06 0E 1F 8B 10    mov   word ptr [0x1f0e], 0x108b
0x0000000000004669:  A3 12 1F             mov   word ptr [0x1f12], ax
0x000000000000466c:  C3                   ret   
0x000000000000466d:  FC                   cld   



ENDP

PROC    M_SfxVol_ NEAR
PUBLIC  M_SfxVol_


0x000000000000466e:  52                   push  dx
0x000000000000466f:  8A 16 25 20          mov   dl, byte ptr [0x2025]
0x0000000000004673:  3D 01 00             cmp   ax, 1
0x0000000000004676:  75 1A                jne   label_4
0x0000000000004678:  80 FA 0F             cmp   dl, 0xf
0x000000000000467b:  73 02                jae   label_5
0x000000000000467d:  FE C2                inc   dl
label_5:
0x000000000000467f:  88 D0                mov   al, dl
0x0000000000004681:  30 E4                xor   ah, ah
0x0000000000004683:  88 16 25 20          mov   byte ptr [0x2025], dl
0x0000000000004687:  9A 8E 01 4F 13       call  S_SetSfxVolume_
0x000000000000468c:  8A 16 25 20          mov   dl, byte ptr [0x2025]
0x0000000000004690:  5A                   pop   dx
0x0000000000004691:  C3                   ret   
label_4:
0x0000000000004692:  85 C0                test  ax, ax
0x0000000000004694:  75 E9                jne   label_5
0x0000000000004696:  84 D2                test  dl, dl
0x0000000000004698:  74 E5                je    label_5
0x000000000000469a:  FE CA                dec   dl
0x000000000000469c:  EB E1                jmp   label_5


ENDP

PROC    M_MusicVol_ NEAR
PUBLIC  M_MusicVol_


0x000000000000469e:  52                   push  dx
0x000000000000469f:  8A 16 2F 20          mov   dl, byte ptr [0x202f]
0x00000000000046a3:  3D 01 00             cmp   ax, 1
0x00000000000046a6:  75 1A                jne   0x46c2
0x00000000000046a8:  80 FA 0F             cmp   dl, 0xf
0x00000000000046ab:  73 02                jae   0x46af
0x00000000000046ad:  FE C2                inc   dl
0x00000000000046af:  88 D0                mov   al, dl
0x00000000000046b1:  30 E4                xor   ah, ah
0x00000000000046b3:  88 16 2F 20          mov   byte ptr [0x202f], dl
0x00000000000046b7:  9A 0E 00 4F 13       lcall 0x134f:0xe
0x00000000000046bc:  8A 16 2F 20          mov   dl, byte ptr [0x202f]
0x00000000000046c0:  5A                   pop   dx
0x00000000000046c1:  C3                   ret   
0x00000000000046c2:  85 C0                test  ax, ax
0x00000000000046c4:  75 E9                jne   0x46af
0x00000000000046c6:  84 D2                test  dl, dl
0x00000000000046c8:  74 E5                je    0x46af
0x00000000000046ca:  FE CA                dec   dl
0x00000000000046cc:  EB E1                jmp   0x46af


ENDP

PROC    M_DrawMainMenu_ NEAR
PUBLIC  M_DrawMainMenu_


0x00000000000046ce:  53                   push  bx
0x00000000000046cf:  51                   push  cx
0x00000000000046d0:  52                   push  dx
0x00000000000046d1:  31 C0                xor   ax, ax
0x00000000000046d3:  E8 4A FA             call  M_GetMenuPatch_
0x00000000000046d6:  89 C3                mov   bx, ax
0x00000000000046d8:  89 D1                mov   cx, dx
0x00000000000046da:  BA 02 00             mov   dx, 2
0x00000000000046dd:  B8 5E 00             mov   ax, 0x5e
0x00000000000046e0:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x00000000000046e5:  5A                   pop   dx
0x00000000000046e6:  59                   pop   cx
0x00000000000046e7:  5B                   pop   bx
0x00000000000046e8:  C3                   ret   
0x00000000000046e9:  FC                   cld   


ENDP

PROC    M_DrawNewGame_ NEAR
PUBLIC  M_DrawNewGame_


0x00000000000046ea:  53                   push  bx
0x00000000000046eb:  51                   push  cx
0x00000000000046ec:  52                   push  dx
0x00000000000046ed:  B8 18 00             mov   ax, 24
0x00000000000046f0:  E8 2D FA             call  M_GetMenuPatch_
0x00000000000046f3:  89 C3                mov   bx, ax
0x00000000000046f5:  89 D1                mov   cx, dx
0x00000000000046f7:  BA 0E 00             mov   dx, 0xe
0x00000000000046fa:  B8 60 00             mov   ax, 0x60
0x00000000000046fd:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004702:  B8 17 00             mov   ax, 0x17
0x0000000000004705:  E8 18 FA             call  M_GetMenuPatch_
0x0000000000004708:  89 C3                mov   bx, ax
0x000000000000470a:  89 D1                mov   cx, dx
0x000000000000470c:  BA 26 00             mov   dx, 0x26
0x000000000000470f:  B8 36 00             mov   ax, 0x36
0x0000000000004712:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004717:  5A                   pop   dx
0x0000000000004718:  59                   pop   cx
0x0000000000004719:  5B                   pop   bx
0x000000000000471a:  C3                   ret   
0x000000000000471b:  FC                   cld   


ENDP

PROC    M_NewGame_ NEAR
PUBLIC  M_NewGame_


0x000000000000471c:  53                   push  bx
0x000000000000471d:  BB EB 02             mov   bx, 0x2eb
0x0000000000004720:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004723:  74 10                je    0x4735
0x0000000000004725:  8B 1E 1F 10          mov   bx, word ptr [0x101f]
0x0000000000004729:  C7 06 0E 1F 15 10    mov   word ptr [0x1f0e], 0x1015
0x000000000000472f:  89 1E 12 1F          mov   word ptr [0x1f12], bx
0x0000000000004733:  5B                   pop   bx
0x0000000000004734:  C3                   ret   
0x0000000000004735:  8B 1E FA 0F          mov   bx, word ptr [0xffa]
0x0000000000004739:  C7 06 0E 1F F0 0F    mov   word ptr [0x1f0e], 0xff0
0x000000000000473f:  89 1E 12 1F          mov   word ptr [0x1f12], bx
0x0000000000004743:  5B                   pop   bx
0x0000000000004744:  C3                   ret   
0x0000000000004745:  FC                   cld   


ENDP

PROC    M_DrawEpisode_ NEAR
PUBLIC  M_DrawEpisode_


0x0000000000004746:  53                   push  bx
0x0000000000004747:  51                   push  cx
0x0000000000004748:  52                   push  dx
0x0000000000004749:  B8 10 00             mov   ax, 0x10
0x000000000000474c:  E8 D1 F9             call  M_GetMenuPatch_
0x000000000000474f:  89 C3                mov   bx, ax
0x0000000000004751:  89 D1                mov   cx, dx
0x0000000000004753:  BA 26 00             mov   dx, 0x26
0x0000000000004756:  B8 36 00             mov   ax, 0x36
0x0000000000004759:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x000000000000475e:  5A                   pop   dx
0x000000000000475f:  59                   pop   cx
0x0000000000004760:  5B                   pop   bx
0x0000000000004761:  C3                   ret   



ENDP

PROC    M_VerifyNightmare_ NEAR
PUBLIC  M_VerifyNightmare_


0x0000000000004762:  53                   push  bx
0x0000000000004763:  52                   push  dx
0x0000000000004764:  3D 79 00             cmp   ax, 0x79
0x0000000000004767:  74 03                je    0x476c
0x0000000000004769:  5A                   pop   dx
0x000000000000476a:  5B                   pop   bx
0x000000000000476b:  C3                   ret   
0x000000000000476c:  A0 F4 1F             mov   al, byte ptr [0x1ff4]
0x000000000000476f:  FE C0                inc   al
0x0000000000004771:  98                   cbw  
0x0000000000004772:  BB 01 00             mov   bx, 1
0x0000000000004775:  89 C2                mov   dx, ax
0x0000000000004777:  B8 04 00             mov   ax, 4
0x000000000000477a:  E8 83 D4             call  0x1c00
0x000000000000477d:  BB 6C 04             mov   bx, 0x46c
0x0000000000004780:  C6 07 00             mov   byte ptr [bx], 0
0x0000000000004783:  5A                   pop   dx
0x0000000000004784:  5B                   pop   bx
0x0000000000004785:  C3                   ret   



ENDP

PROC    M_ChooseSkill_ NEAR
PUBLIC  M_ChooseSkill_


0x0000000000004786:  53                   push  bx
0x0000000000004787:  51                   push  cx
0x0000000000004788:  52                   push  dx
0x0000000000004789:  55                   push  bp
0x000000000000478a:  89 E5                mov   bp, sp
0x000000000000478c:  81 EC 00 01          sub   sp, 0x100
0x0000000000004790:  89 C1                mov   cx, ax
0x0000000000004792:  3D 04 00             cmp   ax, 4
0x0000000000004795:  75 20                jne   0x47b7
0x0000000000004797:  8D 9E 00 FF          lea   bx, [bp - 0x100]
0x000000000000479b:  B8 09 00             mov   ax, 9
0x000000000000479e:  8C D9                mov   cx, ds
0x00000000000047a0:  BA 62 47             mov   dx, 0x4762
0x00000000000047a3:  0E                   push  cs
0x00000000000047a4:  3E E8 7E BC          call  0x426
0x00000000000047a8:  BB 01 00             mov   bx, 1
0x00000000000047ab:  8D 86 00 FF          lea   ax, [bp - 0x100]
0x00000000000047af:  E8 4E 04             call  0x4c00
0x00000000000047b2:  C9                   LEAVE_MACRO 
0x00000000000047b3:  5A                   pop   dx
0x00000000000047b4:  59                   pop   cx
0x00000000000047b5:  5B                   pop   bx
0x00000000000047b6:  C3                   ret   
0x00000000000047b7:  A0 F4 1F             mov   al, byte ptr [0x1ff4]
0x00000000000047ba:  FE C0                inc   al
0x00000000000047bc:  98                   cbw  
0x00000000000047bd:  89 C2                mov   dx, ax
0x00000000000047bf:  88 C8                mov   al, cl
0x00000000000047c1:  BB 01 00             mov   bx, 1
0x00000000000047c4:  30 E4                xor   ah, ah
0x00000000000047c6:  E8 37 D4             call  0x1c00
0x00000000000047c9:  BB 6C 04             mov   bx, 0x46c
0x00000000000047cc:  C6 07 00             mov   byte ptr [bx], 0
0x00000000000047cf:  C9                   LEAVE_MACRO 
0x00000000000047d0:  5A                   pop   dx
0x00000000000047d1:  59                   pop   cx
0x00000000000047d2:  5B                   pop   bx
0x00000000000047d3:  C3                   ret   



ENDP

PROC    M_Episode_ NEAR
PUBLIC  M_Episode_

0x00000000000047d4:  53                   push  bx
0x00000000000047d5:  51                   push  cx
0x00000000000047d6:  52                   push  dx
0x00000000000047d7:  55                   push  bp
0x00000000000047d8:  89 E5                mov   bp, sp
0x00000000000047da:  81 EC 00 01          sub   sp, 0x100
0x00000000000047de:  BB ED 02             mov   bx, 0x2ed
0x00000000000047e1:  80 3F 00             cmp   byte ptr [bx], 0
0x00000000000047e4:  74 04                je    0x47ea
0x00000000000047e6:  85 C0                test  ax, ax
0x00000000000047e8:  75 14                jne   0x47fe
0x00000000000047ea:  A2 F4 1F             mov   byte ptr [0x1ff4], al
0x00000000000047ed:  A1 1F 10             mov   ax, word ptr [0x101f]
0x00000000000047f0:  C7 06 0E 1F 15 10    mov   word ptr [0x1f0e], 0x1015
0x00000000000047f6:  A3 12 1F             mov   word ptr [0x1f12], ax
0x00000000000047f9:  C9                   LEAVE_MACRO 
0x00000000000047fa:  5A                   pop   dx
0x00000000000047fb:  59                   pop   cx
0x00000000000047fc:  5B                   pop   bx
0x00000000000047fd:  C3                   ret   
0x00000000000047fe:  8D 9E 00 FF          lea   bx, [bp - 0x100]
0x0000000000004802:  B8 0A 00             mov   ax, 0xa
0x0000000000004805:  8C D9                mov   cx, ds
0x0000000000004807:  0E                   push  cs
0x0000000000004808:  3E E8 1A BC          call  0x426
0x000000000000480c:  31 D2                xor   dx, dx
0x000000000000480e:  8D 86 00 FF          lea   ax, [bp - 0x100]
0x0000000000004812:  31 DB                xor   bx, bx
0x0000000000004814:  E8 E9 03             call  0x4c00
0x0000000000004817:  A1 64 10             mov   ax, word ptr [0x1064]
0x000000000000481a:  C7 06 0E 1F 5A 10    mov   word ptr [0x1f0e], 0x105a
0x0000000000004820:  A3 12 1F             mov   word ptr [0x1f12], ax
0x0000000000004823:  C9                   LEAVE_MACRO 
0x0000000000004824:  5A                   pop   dx
0x0000000000004825:  59                   pop   cx
0x0000000000004826:  5B                   pop   bx
0x0000000000004827:  C3                   ret   


ENDP

PROC    M_DrawOptions_ NEAR
PUBLIC  M_DrawOptions_

0x0000000000004828:  53                   push  bx
0x0000000000004829:  51                   push  cx
0x000000000000482a:  52                   push  dx
0x000000000000482b:  56                   push  si
0x000000000000482c:  B8 1C 00             mov   ax, 0x1c
0x000000000000482f:  E8 EE F8             call  M_GetMenuPatch_
0x0000000000004832:  89 D1                mov   cx, dx
0x0000000000004834:  89 C3                mov   bx, ax
0x0000000000004836:  BA 0F 00             mov   dx, 0xf
0x0000000000004839:  B8 6C 00             mov   ax, 0x6c
0x000000000000483c:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004841:  8A 1E 2D 20          mov   bl, byte ptr [0x202d]
0x0000000000004845:  30 FF                xor   bh, bh
0x0000000000004847:  8A 87 EB 10          mov   al, byte ptr [bx + 0x10eb]
0x000000000000484b:  98                   cbw  
0x000000000000484c:  E8 D1 F8             call  M_GetMenuPatch_
0x000000000000484f:  8A 1E 52 10          mov   bl, byte ptr [0x1052]
0x0000000000004853:  8B 36 50 10          mov   si, word ptr [0x1050]
0x0000000000004857:  89 D1                mov   cx, dx
0x0000000000004859:  8D 57 20             lea   dx, [bx + 0x20]
0x000000000000485c:  81 C6 AF 00          add   si, 0xaf
0x0000000000004860:  89 C3                mov   bx, ax
0x0000000000004862:  89 F0                mov   ax, si
0x0000000000004864:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004869:  8A 1E 27 20          mov   bl, byte ptr [0x2027]
0x000000000000486d:  30 FF                xor   bh, bh
0x000000000000486f:  8A 87 ED 10          mov   al, byte ptr [bx + 0x10ed]
0x0000000000004873:  98                   cbw  
0x0000000000004874:  E8 A9 F8             call  M_GetMenuPatch_
0x0000000000004877:  8A 1E 52 10          mov   bl, byte ptr [0x1052]
0x000000000000487b:  8B 36 50 10          mov   si, word ptr [0x1050]
0x000000000000487f:  89 D1                mov   cx, dx
0x0000000000004881:  8D 57 10             lea   dx, [bx + 0x10]
0x0000000000004884:  83 C6 78             add   si, 0x78
0x0000000000004887:  89 C3                mov   bx, ax
0x0000000000004889:  89 F0                mov   ax, si
0x000000000000488b:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004890:  BB 0A 00             mov   bx, 0xa
0x0000000000004893:  A0 52 10             mov   al, byte ptr [0x1052]
0x0000000000004896:  8A 0E 29 20          mov   cl, byte ptr [0x2029]
0x000000000000489a:  30 E4                xor   ah, ah
0x000000000000489c:  30 ED                xor   ch, ch
0x000000000000489e:  89 C2                mov   dx, ax
0x00000000000048a0:  A1 50 10             mov   ax, word ptr [0x1050]
0x00000000000048a3:  83 C2 60             add   dx, 0x60
0x00000000000048a6:  E8 D3 02             call  0x4b7c
0x00000000000048a9:  BB 0B 00             mov   bx, 0xb
0x00000000000048ac:  A0 52 10             mov   al, byte ptr [0x1052]
0x00000000000048af:  8A 0E 2B 20          mov   cl, byte ptr [0x202b]
0x00000000000048b3:  30 E4                xor   ah, ah
0x00000000000048b5:  30 ED                xor   ch, ch
0x00000000000048b7:  89 C2                mov   dx, ax
0x00000000000048b9:  A1 50 10             mov   ax, word ptr [0x1050]
0x00000000000048bc:  83 C2 40             add   dx, 0x40
0x00000000000048bf:  E8 BA 02             call  0x4b7c
0x00000000000048c2:  5E                   pop   si
0x00000000000048c3:  5A                   pop   dx
0x00000000000048c4:  59                   pop   cx
0x00000000000048c5:  5B                   pop   bx
0x00000000000048c6:  C3                   ret   
0x00000000000048c7:  FC                   cld   



ENDP

PROC    M_Options_ NEAR
PUBLIC  M_Options_


0x00000000000048c8:  A1 53 10             mov   ax, word ptr [0x1053]
0x00000000000048cb:  C7 06 0E 1F 49 10    mov   word ptr [0x1f0e], 0x1049
0x00000000000048d1:  A3 12 1F             mov   word ptr [0x1f12], ax
0x00000000000048d4:  C3                   ret   
0x00000000000048d5:  FC                   cld   


ENDP

PROC    M_ChangeMessages_ NEAR
PUBLIC  M_ChangeMessages_



0x00000000000048d6:  53                   push  bx
0x00000000000048d7:  B3 01                mov   bl, 1
0x00000000000048d9:  2A 1E 27 20          sub   bl, byte ptr [0x2027]
0x00000000000048dd:  88 1E 27 20          mov   byte ptr [0x2027], bl
0x00000000000048e1:  75 0E                jne   0x48f1
0x00000000000048e3:  BB 24 08             mov   bx, 0x824
0x00000000000048e6:  C7 07 0B 00          mov   word ptr [bx], 0xb
0x00000000000048ea:  C6 06 F6 1F 01       mov   byte ptr [0x1ff6], 1
0x00000000000048ef:  5B                   pop   bx
0x00000000000048f0:  C3                   ret   
0x00000000000048f1:  BB 24 08             mov   bx, 0x824
0x00000000000048f4:  C7 07 0C 00          mov   word ptr [bx], 0xc
0x00000000000048f8:  C6 06 F6 1F 01       mov   byte ptr [0x1ff6], 1
0x00000000000048fd:  5B                   pop   bx
0x00000000000048fe:  C3                   ret   
0x00000000000048ff:  FC                   cld   


ENDP

PROC    M_EndGameResponse_ NEAR
PUBLIC  M_EndGameResponse_



0x0000000000004900:  53                   push  bx
0x0000000000004901:  3D 79 00             cmp   ax, 0x79
0x0000000000004904:  74 02                je    0x4908
0x0000000000004906:  5B                   pop   bx
0x0000000000004907:  C3                   ret   
0x0000000000004908:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x000000000000490c:  A1 12 1F             mov   ax, word ptr [0x1f12]
0x000000000000490f:  89 47 0A             mov   word ptr [bx + 0xa], ax
0x0000000000004912:  BB 6C 04             mov   bx, 0x46c
0x0000000000004915:  C6 07 00             mov   byte ptr [bx], 0
0x0000000000004918:  0E                   push  cs
0x0000000000004919:  E8 16 C4             call  0xd32
0x000000000000491c:  90                   nop   
0x000000000000491d:  5B                   pop   bx
0x000000000000491e:  C3                   ret   
0x000000000000491f:  FC                   cld   


ENDP

PROC    M_EndGame_ NEAR
PUBLIC  M_EndGame_



0x0000000000004920:  53                   push  bx
0x0000000000004921:  51                   push  cx
0x0000000000004922:  52                   push  dx
0x0000000000004923:  55                   push  bp
0x0000000000004924:  89 E5                mov   bp, sp
0x0000000000004926:  81 EC 00 01          sub   sp, 0x100
0x000000000000492a:  A0 1D 20             mov   al, byte ptr [0x201d]
0x000000000000492d:  84 C0                test  al, al
0x000000000000492f:  75 0F                jne   0x4940
0x0000000000004931:  BA 22 00             mov   dx, 0x22
0x0000000000004934:  30 E4                xor   ah, ah
0x0000000000004936:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000493b:  C9                   LEAVE_MACRO 
0x000000000000493c:  5A                   pop   dx
0x000000000000493d:  59                   pop   cx
0x000000000000493e:  5B                   pop   bx
0x000000000000493f:  C3                   ret   
0x0000000000004940:  8D 9E 00 FF          lea   bx, [bp - 0x100]
0x0000000000004944:  B8 0E 00             mov   ax, 0xe
0x0000000000004947:  8C D9                mov   cx, ds
0x0000000000004949:  BA 00 49             mov   dx, 0x4900
0x000000000000494c:  0E                   push  cs
0x000000000000494d:  E8 D6 BA             call  0x426
0x0000000000004950:  90                   nop   
0x0000000000004951:  BB 01 00             mov   bx, 1
0x0000000000004954:  8D 86 00 FF          lea   ax, [bp - 0x100]
0x0000000000004958:  E8 A5 02             call  0x4c00
0x000000000000495b:  C9                   LEAVE_MACRO 
0x000000000000495c:  5A                   pop   dx
0x000000000000495d:  59                   pop   cx
0x000000000000495e:  5B                   pop   bx
0x000000000000495f:  C3                   ret   


ENDP

PROC    M_ReadThis_ NEAR
PUBLIC  M_ReadThis_



0x0000000000004960:  53                   push  bx
0x0000000000004961:  BB E1 00             mov   bx, 0xe1
0x0000000000004964:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004967:  74 10                je    0x4979
0x0000000000004969:  8B 1E 75 10          mov   bx, word ptr [0x1075]
0x000000000000496d:  C7 06 0E 1F 6B 10    mov   word ptr [0x1f0e], 0x106b
0x0000000000004973:  89 1E 12 1F          mov   word ptr [0x1f12], bx
0x0000000000004977:  5B                   pop   bx
0x0000000000004978:  C3                   ret   
0x0000000000004979:  8B 1E 64 10          mov   bx, word ptr [0x1064]
0x000000000000497d:  C7 06 0E 1F 5A 10    mov   word ptr [0x1f0e], 0x105a
0x0000000000004983:  89 1E 12 1F          mov   word ptr [0x1f12], bx
0x0000000000004987:  5B                   pop   bx
0x0000000000004988:  C3                   ret   
0x0000000000004989:  FC                   cld   


ENDP

PROC    M_ReadThis2_ NEAR
PUBLIC  M_ReadThis2_

0x000000000000498a:  A1 75 10             mov   ax, word ptr [0x1075]
0x000000000000498d:  C7 06 0E 1F 6B 10    mov   word ptr [0x1f0e], 0x106b
0x0000000000004993:  A3 12 1F             mov   word ptr [0x1f12], ax
0x0000000000004996:  C3                   ret   
0x0000000000004997:  FC                   cld   


ENDP

PROC    M_FinishReadThis_ NEAR
PUBLIC  M_FinishReadThis_

0x0000000000004998:  A1 DA 0F             mov   ax, word ptr [0xfda]
0x000000000000499b:  C7 06 0E 1F D0 0F    mov   word ptr [0x1f0e], 0xfd0
0x00000000000049a1:  A3 12 1F             mov   word ptr [0x1f12], ax
0x00000000000049a4:  C3                   ret   
0x00000000000049a5:  FC                   cld   

ENDP

PROC    M_QuitResponse_ NEAR
PUBLIC  M_QuitResponse_

0x00000000000049a6:  53                   push  bx
0x00000000000049a7:  52                   push  dx
0x00000000000049a8:  56                   push  si
0x00000000000049a9:  55                   push  bp
0x00000000000049aa:  89 E5                mov   bp, sp
0x00000000000049ac:  83 EC 08             sub   sp, 8
0x00000000000049af:  3D 79 00             cmp   ax, 0x79
0x00000000000049b2:  75 49                jne   0x49fd
0x00000000000049b4:  BB EB 02             mov   bx, 0x2eb
0x00000000000049b7:  80 3F 00             cmp   byte ptr [bx], 0
0x00000000000049ba:  75 46                jne   0x4a02
0x00000000000049bc:  C7 46 F8 39 1A       mov   word ptr [bp - 8], 0x1a39
0x00000000000049c1:  C7 46 FA 1B 1F       mov   word ptr [bp - 6], 0x1f1b
0x00000000000049c6:  C7 46 FC 23 24       mov   word ptr [bp - 4], 0x2423
0x00000000000049cb:  C6 46 FE 26          mov   byte ptr [bp - 2], 0x26
0x00000000000049cf:  BB 38 07             mov   bx, 0x738
0x00000000000049d2:  C6 46 FF 34          mov   byte ptr [bp - 1], 0x34
0x00000000000049d6:  8B 07                mov   ax, word ptr [bx]
0x00000000000049d8:  8B 57 02             mov   dx, word ptr [bx + 2]
0x00000000000049db:  D1 FA                sar   dx, 1
0x00000000000049dd:  D1 D8                rcr   ax, 1
0x00000000000049df:  D1 FA                sar   dx, 1
0x00000000000049e1:  D1 D8                rcr   ax, 1
0x00000000000049e3:  89 C6                mov   si, ax
0x00000000000049e5:  83 E6 07             and   si, 7
0x00000000000049e8:  8A 52 F8             mov   dl, byte ptr [bp + si - 8]
0x00000000000049eb:  31 C0                xor   ax, ax
0x00000000000049ed:  30 F6                xor   dh, dh
0x00000000000049ef:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x00000000000049f4:  B8 69 00             mov   ax, 0x69
0x00000000000049f7:  E8 26 B8             call  0x220
0x00000000000049fa:  E8 C5 B7             call  0x1c2
0x00000000000049fd:  C9                   LEAVE_MACRO 
0x00000000000049fe:  5E                   pop   si
0x00000000000049ff:  5A                   pop   dx
0x0000000000004a00:  5B                   pop   bx
0x0000000000004a01:  C3                   ret   
0x0000000000004a02:  BB 38 07             mov   bx, 0x738
0x0000000000004a05:  C6 46 F8 34          mov   byte ptr [bp - 8], 0x34
0x0000000000004a09:  EB CB                jmp   0x49d6
0x0000000000004a0b:  FC                   cld   

ENDP

PROC    M_QuitDOOM_ NEAR
PUBLIC  M_QuitDOOM_


0x0000000000004a0c:  53                   push  bx
0x0000000000004a0d:  51                   push  cx
0x0000000000004a0e:  52                   push  dx
0x0000000000004a0f:  55                   push  bp
0x0000000000004a10:  89 E5                mov   bp, sp
0x0000000000004a12:  81 EC 88 00          sub   sp, 0x88
0x0000000000004a16:  81 ED 9C 00          sub   bp, 0x9c
0x0000000000004a1a:  BB 38 07             mov   bx, 0x738
0x0000000000004a1d:  8B 07                mov   ax, word ptr [bx]
0x0000000000004a1f:  8B 57 02             mov   dx, word ptr [bx + 2]
0x0000000000004a22:  8B 4F 02             mov   cx, word ptr [bx + 2]
0x0000000000004a25:  D1 FA                sar   dx, 1
0x0000000000004a27:  D1 D8                rcr   ax, 1
0x0000000000004a29:  C1 F9 0F             sar   cx, 0xf
0x0000000000004a2c:  D1 FA                sar   dx, 1
0x0000000000004a2e:  D1 D8                rcr   ax, 1
0x0000000000004a30:  89 CA                mov   dx, cx
0x0000000000004a32:  31 C2                xor   dx, ax
0x0000000000004a34:  8B 47 02             mov   ax, word ptr [bx + 2]
0x0000000000004a37:  C1 F8 0F             sar   ax, 0xf
0x0000000000004a3a:  29 C2                sub   dx, ax
0x0000000000004a3c:  8B 47 02             mov   ax, word ptr [bx + 2]
0x0000000000004a3f:  C1 F8 0F             sar   ax, 0xf
0x0000000000004a42:  83 E2 07             and   dx, 7
0x0000000000004a45:  31 C2                xor   dx, ax
0x0000000000004a47:  8B 47 02             mov   ax, word ptr [bx + 2]
0x0000000000004a4a:  B9 C0 3C             mov   cx, 0x3cc0
0x0000000000004a4d:  C1 F8 0F             sar   ax, 0xf
0x0000000000004a50:  8D 5E 7E             lea   bx, [bp + 0x7e]
0x0000000000004a53:  29 C2                sub   dx, ax
0x0000000000004a55:  B8 0F 00             mov   ax, 0xf
0x0000000000004a58:  0E                   push  cs
0x0000000000004a59:  E8 CA B9             call  0x426
0x0000000000004a5c:  90                   nop   
0x0000000000004a5d:  85 D2                test  dx, dx
0x0000000000004a5f:  74 48                je    0x4aa9
0x0000000000004a61:  BB EB 02             mov   bx, 0x2eb
0x0000000000004a64:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004a67:  74 45                je    0x4aae
0x0000000000004a69:  89 D0                mov   ax, dx
0x0000000000004a6b:  05 1A 01             add   ax, 0x11a
0x0000000000004a6e:  8D 5E 14             lea   bx, [bp + 0x14]
0x0000000000004a71:  8C D9                mov   cx, ds
0x0000000000004a73:  8D 56 14             lea   dx, [bp + 0x14]
0x0000000000004a76:  0E                   push  cs
0x0000000000004a77:  E8 AC B9             call  0x426
0x0000000000004a7a:  90                   nop   
0x0000000000004a7b:  BB EA 19             mov   bx, 0x19ea
0x0000000000004a7e:  8D 46 14             lea   ax, [bp + 0x14]
0x0000000000004a81:  0E                   push  cs
0x0000000000004a82:  3E E8 78 C1          call  0xbfe
0x0000000000004a86:  8D 5E 7E             lea   bx, [bp + 0x7e]
0x0000000000004a89:  8D 56 14             lea   dx, [bp + 0x14]
0x0000000000004a8c:  8D 46 14             lea   ax, [bp + 0x14]
0x0000000000004a8f:  0E                   push  cs
0x0000000000004a90:  3E E8 6A C1          call  0xbfe
0x0000000000004a94:  BB 01 00             mov   bx, 1
0x0000000000004a97:  BA A6 49             mov   dx, 0x49a6
0x0000000000004a9a:  8D 46 14             lea   ax, [bp + 0x14]
0x0000000000004a9d:  E8 60 01             call  0x4c00
0x0000000000004aa0:  8D A6 9C 00          lea   sp, [bp + 0x9c]
0x0000000000004aa4:  5D                   pop   bp
0x0000000000004aa5:  5A                   pop   dx
0x0000000000004aa6:  59                   pop   cx
0x0000000000004aa7:  5B                   pop   bx
0x0000000000004aa8:  C3                   ret   
0x0000000000004aa9:  B8 02 00             mov   ax, 2
0x0000000000004aac:  EB C0                jmp   0x4a6e
0x0000000000004aae:  89 D0                mov   ax, dx
0x0000000000004ab0:  05 13 01             add   ax, 0x113
0x0000000000004ab3:  EB B9                jmp   0x4a6e
0x0000000000004ab5:  FC                   cld   

ENDP

PROC    M_ChangeSensitivity_ NEAR
PUBLIC  M_ChangeSensitivity_

0x0000000000004ab6:  52                   push  dx
0x0000000000004ab7:  8A 16 29 20          mov   dl, byte ptr [0x2029]
0x0000000000004abb:  3D 01 00             cmp   ax, 1
0x0000000000004abe:  75 0D                jne   0x4acd
0x0000000000004ac0:  80 FA 09             cmp   dl, 9
0x0000000000004ac3:  73 02                jae   0x4ac7
0x0000000000004ac5:  FE C2                inc   dl
0x0000000000004ac7:  88 16 29 20          mov   byte ptr [0x2029], dl
0x0000000000004acb:  5A                   pop   dx
0x0000000000004acc:  C3                   ret   
0x0000000000004acd:  85 C0                test  ax, ax
0x0000000000004acf:  75 F6                jne   0x4ac7
0x0000000000004ad1:  84 D2                test  dl, dl
0x0000000000004ad3:  74 F2                je    0x4ac7
0x0000000000004ad5:  FE CA                dec   dl
0x0000000000004ad7:  88 16 29 20          mov   byte ptr [0x2029], dl
0x0000000000004adb:  5A                   pop   dx
0x0000000000004adc:  C3                   ret   
0x0000000000004add:  FC                   cld   

ENDP

PROC    M_ChangeDetail_ NEAR
PUBLIC  M_ChangeDetail_

0x0000000000004ade:  53                   push  bx
0x0000000000004adf:  52                   push  dx
0x0000000000004ae0:  56                   push  si
0x0000000000004ae1:  8A 1E 2D 20          mov   bl, byte ptr [0x202d]
0x0000000000004ae5:  FE C3                inc   bl
0x0000000000004ae7:  80 FB 03             cmp   bl, 3
0x0000000000004aea:  75 02                jne   0x4aee
0x0000000000004aec:  30 DB                xor   bl, bl
0x0000000000004aee:  88 D8                mov   al, bl
0x0000000000004af0:  30 E4                xor   ah, ah
0x0000000000004af2:  BE 9B 01             mov   si, 0x19b
0x0000000000004af5:  89 C2                mov   dx, ax
0x0000000000004af7:  8A 04                mov   al, byte ptr [si]
0x0000000000004af9:  88 1E 2D 20          mov   byte ptr [0x202d], bl
0x0000000000004afd:  9A 55 21 4F 13       lcall 0x134f:0x2155
0x0000000000004b02:  8A 1E 2D 20          mov   bl, byte ptr [0x202d]
0x0000000000004b06:  84 DB                test  bl, bl
0x0000000000004b08:  74 14                je    0x4b1e
0x0000000000004b0a:  80 FB 01             cmp   bl, 1
0x0000000000004b0d:  75 18                jne   0x4b27
0x0000000000004b0f:  BE 24 08             mov   si, 0x824
0x0000000000004b12:  C7 04 11 00          mov   word ptr [si], 0x11
0x0000000000004b16:  88 1E 2D 20          mov   byte ptr [0x202d], bl
0x0000000000004b1a:  5E                   pop   si
0x0000000000004b1b:  5A                   pop   dx
0x0000000000004b1c:  5B                   pop   bx
0x0000000000004b1d:  C3                   ret   
0x0000000000004b1e:  BE 24 08             mov   si, 0x824
0x0000000000004b21:  C7 04 10 00          mov   word ptr [si], 0x10
0x0000000000004b25:  EB EF                jmp   0x4b16
0x0000000000004b27:  BE 24 08             mov   si, 0x824
0x0000000000004b2a:  C7 04 30 01          mov   word ptr [si], 0x130
0x0000000000004b2e:  88 1E 2D 20          mov   byte ptr [0x202d], bl
0x0000000000004b32:  5E                   pop   si
0x0000000000004b33:  5A                   pop   dx
0x0000000000004b34:  5B                   pop   bx
0x0000000000004b35:  C3                   ret   


ENDP

PROC    M_SizeDisplay_ NEAR
PUBLIC  M_SizeDisplay_

0x0000000000004b36:  53                   push  bx
0x0000000000004b37:  51                   push  cx
0x0000000000004b38:  52                   push  dx
0x0000000000004b39:  8A 0E 2B 20          mov   cl, byte ptr [0x202b]
0x0000000000004b3d:  3D 01 00             cmp   ax, 1
0x0000000000004b40:  75 29                jne   0x4b6b
0x0000000000004b42:  80 F9 0A             cmp   cl, 0xa
0x0000000000004b45:  73 07                jae   0x4b4e
0x0000000000004b47:  BB 9B 01             mov   bx, 0x19b
0x0000000000004b4a:  FE C1                inc   cl
0x0000000000004b4c:  FE 07                inc   byte ptr [bx]
0x0000000000004b4e:  A0 2D 20             mov   al, byte ptr [0x202d]
0x0000000000004b51:  30 E4                xor   ah, ah
0x0000000000004b53:  BB 9B 01             mov   bx, 0x19b
0x0000000000004b56:  89 C2                mov   dx, ax
0x0000000000004b58:  8A 07                mov   al, byte ptr [bx]
0x0000000000004b5a:  88 0E 2B 20          mov   byte ptr [0x202b], cl
0x0000000000004b5e:  9A 55 21 4F 13       lcall 0x134f:0x2155
0x0000000000004b63:  8A 0E 2B 20          mov   cl, byte ptr [0x202b]
0x0000000000004b67:  5A                   pop   dx
0x0000000000004b68:  59                   pop   cx
0x0000000000004b69:  5B                   pop   bx
0x0000000000004b6a:  C3                   ret   
0x0000000000004b6b:  85 C0                test  ax, ax
0x0000000000004b6d:  75 DF                jne   0x4b4e
0x0000000000004b6f:  84 C9                test  cl, cl
0x0000000000004b71:  76 DB                jbe   0x4b4e
0x0000000000004b73:  BB 9B 01             mov   bx, 0x19b
0x0000000000004b76:  FE C9                dec   cl
0x0000000000004b78:  FE 0F                dec   byte ptr [bx]
0x0000000000004b7a:  EB D2                jmp   0x4b4e

ENDP

PROC    M_DrawThermo_ NEAR
PUBLIC  M_DrawThermo_

0x0000000000004b7c:  56                   push  si
0x0000000000004b7d:  57                   push  di
0x0000000000004b7e:  55                   push  bp
0x0000000000004b7f:  89 E5                mov   bp, sp
0x0000000000004b81:  50                   push  ax
0x0000000000004b82:  52                   push  dx
0x0000000000004b83:  53                   push  bx
0x0000000000004b84:  51                   push  cx
0x0000000000004b85:  B8 0A 00             mov   ax, 0xa
0x0000000000004b88:  8B 76 FE             mov   si, word ptr [bp - 2]
0x0000000000004b8b:  E8 92 F5             call  M_GetMenuPatch_
0x0000000000004b8e:  31 FF                xor   di, di
0x0000000000004b90:  89 C3                mov   bx, ax
0x0000000000004b92:  89 D1                mov   cx, dx
0x0000000000004b94:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x0000000000004b97:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004b9a:  83 C6 08             add   si, 8
0x0000000000004b9d:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004ba2:  83 7E FA 00          cmp   word ptr [bp - 6], 0
0x0000000000004ba6:  7E 1D                jle   0x4bc5
0x0000000000004ba8:  B8 09 00             mov   ax, 9
0x0000000000004bab:  E8 72 F5             call  M_GetMenuPatch_
0x0000000000004bae:  89 C3                mov   bx, ax
0x0000000000004bb0:  89 D1                mov   cx, dx
0x0000000000004bb2:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x0000000000004bb5:  89 F0                mov   ax, si
0x0000000000004bb7:  47                   inc   di
0x0000000000004bb8:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004bbd:  83 C6 08             add   si, 8
0x0000000000004bc0:  3B 7E FA             cmp   di, word ptr [bp - 6]
0x0000000000004bc3:  7C E3                jl    0x4ba8
0x0000000000004bc5:  B8 08 00             mov   ax, 8
0x0000000000004bc8:  8B 7E FE             mov   di, word ptr [bp - 2]
0x0000000000004bcb:  E8 52 F5             call  M_GetMenuPatch_
0x0000000000004bce:  89 C3                mov   bx, ax
0x0000000000004bd0:  89 D1                mov   cx, dx
0x0000000000004bd2:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x0000000000004bd5:  89 F0                mov   ax, si
0x0000000000004bd7:  83 C7 08             add   di, 8
0x0000000000004bda:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004bdf:  B8 07 00             mov   ax, 7
0x0000000000004be2:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000004be5:  E8 38 F5             call  M_GetMenuPatch_
0x0000000000004be8:  C1 E6 03             shl   si, 3
0x0000000000004beb:  89 C3                mov   bx, ax
0x0000000000004bed:  89 D1                mov   cx, dx
0x0000000000004bef:  01 FE                add   si, di
0x0000000000004bf1:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x0000000000004bf4:  89 F0                mov   ax, si
0x0000000000004bf6:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004bfb:  C9                   LEAVE_MACRO 
0x0000000000004bfc:  5F                   pop   di
0x0000000000004bfd:  5E                   pop   si
0x0000000000004bfe:  C3                   ret   
0x0000000000004bff:  FC                   cld   


ENDP

PROC    M_StartMessage_ NEAR
PUBLIC  M_StartMessage_

0x0000000000004c00:  51                   push  cx
0x0000000000004c01:  56                   push  si
0x0000000000004c02:  55                   push  bp
0x0000000000004c03:  89 E5                mov   bp, sp
0x0000000000004c05:  83 EC 02             sub   sp, 2
0x0000000000004c08:  89 C1                mov   cx, ax
0x0000000000004c0a:  89 D6                mov   si, dx
0x0000000000004c0c:  88 5E FE             mov   byte ptr [bp - 2], bl
0x0000000000004c0f:  BB 6C 04             mov   bx, 0x46c
0x0000000000004c12:  8A 07                mov   al, byte ptr [bx]
0x0000000000004c14:  8C DA                mov   dx, ds
0x0000000000004c16:  98                   cbw  
0x0000000000004c17:  89 CB                mov   bx, cx
0x0000000000004c19:  A3 0C 1F             mov   word ptr [0x1f0c], ax
0x0000000000004c1c:  8C D9                mov   cx, ds
0x0000000000004c1e:  B8 6C 1F             mov   ax, 0x1f6c
0x0000000000004c21:  C6 06 F9 1F 01       mov   byte ptr [0x1ff9], 1
0x0000000000004c26:  0E                   push  cs
0x0000000000004c27:  E8 A6 B8             call  0x4d0
0x0000000000004c2a:  90                   nop   
0x0000000000004c2b:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000004c2e:  BB 6C 04             mov   bx, 0x46c
0x0000000000004c31:  89 36 16 1F          mov   word ptr [0x1f16], si
0x0000000000004c35:  A2 F5 1F             mov   byte ptr [0x1ff5], al
0x0000000000004c38:  C6 07 01             mov   byte ptr [bx], 1
0x0000000000004c3b:  C9                   LEAVE_MACRO 
0x0000000000004c3c:  5E                   pop   si
0x0000000000004c3d:  59                   pop   cx
0x0000000000004c3e:  C3                   ret   
0x0000000000004c3f:  FC                   cld   

ENDP

PROC    M_StringWidth_ NEAR
PUBLIC  M_StringWidth_

0x0000000000004c40:  53                   push  bx
0x0000000000004c41:  51                   push  cx
0x0000000000004c42:  56                   push  si
0x0000000000004c43:  57                   push  di
0x0000000000004c44:  55                   push  bp
0x0000000000004c45:  89 E5                mov   bp, sp
0x0000000000004c47:  83 EC 02             sub   sp, 2
0x0000000000004c4a:  89 C6                mov   si, ax
0x0000000000004c4c:  89 D7                mov   di, dx
0x0000000000004c4e:  0E                   push  cs
0x0000000000004c4f:  E8 54 B8             call  0x4a6
0x0000000000004c52:  90                   nop   
0x0000000000004c53:  89 C1                mov   cx, ax
0x0000000000004c55:  31 DB                xor   bx, bx
0x0000000000004c57:  31 D2                xor   dx, dx
0x0000000000004c59:  85 C0                test  ax, ax
0x0000000000004c5b:  7E 27                jle   0x4c84
0x0000000000004c5d:  89 7E FE             mov   word ptr [bp - 2], di
0x0000000000004c60:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004c63:  26 8A 04             mov   al, byte ptr es:[si]
0x0000000000004c66:  30 E4                xor   ah, ah
0x0000000000004c68:  0E                   push  cs
0x0000000000004c69:  E8 58 B8             call  0x4c4
0x0000000000004c6c:  90                   nop   
0x0000000000004c6d:  30 E4                xor   ah, ah
0x0000000000004c6f:  2D 21 00             sub   ax, 0x21
0x0000000000004c72:  85 C0                test  ax, ax
0x0000000000004c74:  7C 05                jl    0x4c7b
0x0000000000004c76:  3D 3F 00             cmp   ax, 0x3f
0x0000000000004c79:  7C 11                jl    0x4c8c
0x0000000000004c7b:  83 C3 04             add   bx, 4
0x0000000000004c7e:  42                   inc   dx
0x0000000000004c7f:  46                   inc   si
0x0000000000004c80:  39 CA                cmp   dx, cx
0x0000000000004c82:  7C DC                jl    0x4c60
0x0000000000004c84:  89 D8                mov   ax, bx
0x0000000000004c86:  C9                   LEAVE_MACRO 
0x0000000000004c87:  5F                   pop   di
0x0000000000004c88:  5E                   pop   si
0x0000000000004c89:  59                   pop   cx
0x0000000000004c8a:  5B                   pop   bx
0x0000000000004c8b:  C3                   ret   
0x0000000000004c8c:  BF 73 4C             mov   di, 0x4c73
0x0000000000004c8f:  8E C7                mov   es, di
0x0000000000004c91:  89 C7                mov   di, ax
0x0000000000004c93:  26 8A 05             mov   al, byte ptr es:[di]
0x0000000000004c96:  98                   cbw  
0x0000000000004c97:  01 C3                add   bx, ax
0x0000000000004c99:  EB E3                jmp   0x4c7e
0x0000000000004c9b:  FC                   cld   

ENDP

PROC    M_StringHeight_ NEAR
PUBLIC  M_StringHeight_

0x0000000000004c9c:  53                   push  bx
0x0000000000004c9d:  51                   push  cx
0x0000000000004c9e:  56                   push  si
0x0000000000004c9f:  57                   push  di
0x0000000000004ca0:  55                   push  bp
0x0000000000004ca1:  89 E5                mov   bp, sp
0x0000000000004ca3:  83 EC 02             sub   sp, 2
0x0000000000004ca6:  89 C1                mov   cx, ax
0x0000000000004ca8:  89 D6                mov   si, dx
0x0000000000004caa:  C7 46 FE 08 00       mov   word ptr [bp - 2], 8
0x0000000000004caf:  30 DB                xor   bl, bl
0x0000000000004cb1:  89 C8                mov   ax, cx
0x0000000000004cb3:  89 F2                mov   dx, si
0x0000000000004cb5:  0E                   push  cs
0x0000000000004cb6:  3E E8 EC B7          call  0x4a6
0x0000000000004cba:  89 C2                mov   dx, ax
0x0000000000004cbc:  88 D8                mov   al, bl
0x0000000000004cbe:  98                   cbw  
0x0000000000004cbf:  39 D0                cmp   ax, dx
0x0000000000004cc1:  7D 16                jge   0x4cd9
0x0000000000004cc3:  89 CF                mov   di, cx
0x0000000000004cc5:  8E C6                mov   es, si
0x0000000000004cc7:  01 C7                add   di, ax
0x0000000000004cc9:  26 80 3D 0A          cmp   byte ptr es:[di], 0xa
0x0000000000004ccd:  74 04                je    0x4cd3
0x0000000000004ccf:  FE C3                inc   bl
0x0000000000004cd1:  EB DE                jmp   0x4cb1
0x0000000000004cd3:  83 46 FE 08          add   word ptr [bp - 2], 8
0x0000000000004cd7:  EB F6                jmp   0x4ccf
0x0000000000004cd9:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004cdc:  C9                   LEAVE_MACRO 
0x0000000000004cdd:  5F                   pop   di
0x0000000000004cde:  5E                   pop   si
0x0000000000004cdf:  59                   pop   cx
0x0000000000004ce0:  5B                   pop   bx
0x0000000000004ce1:  C3                   ret   


ENDP

PROC    M_WriteText_ NEAR
PUBLIC  M_WriteText_

0x0000000000004ce2:  56                   push  si
0x0000000000004ce3:  57                   push  di
0x0000000000004ce4:  55                   push  bp
0x0000000000004ce5:  89 E5                mov   bp, sp
0x0000000000004ce7:  83 EC 06             sub   sp, 6
0x0000000000004cea:  50                   push  ax
0x0000000000004ceb:  89 5E FC             mov   word ptr [bp - 4], bx
0x0000000000004cee:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000004cf1:  89 C6                mov   si, ax
0x0000000000004cf3:  89 D7                mov   di, dx
0x0000000000004cf5:  C4 5E FC             les   bx, ptr [bp - 4]
0x0000000000004cf8:  26 8A 07             mov   al, byte ptr es:[bx]
0x0000000000004cfb:  98                   cbw  
0x0000000000004cfc:  FF 46 FC             inc   word ptr [bp - 4]
0x0000000000004cff:  89 C2                mov   dx, ax
0x0000000000004d01:  85 C0                test  ax, ax
0x0000000000004d03:  74 41                je    0x4d46
0x0000000000004d05:  3D 0A 00             cmp   ax, 0xa
0x0000000000004d08:  75 08                jne   0x4d12
0x0000000000004d0a:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000004d0d:  83 C7 0C             add   di, 0xc
0x0000000000004d10:  EB E3                jmp   0x4cf5
0x0000000000004d12:  30 E4                xor   ah, ah
0x0000000000004d14:  0E                   push  cs
0x0000000000004d15:  E8 AC B7             call  0x4c4
0x0000000000004d18:  90                   nop   
0x0000000000004d19:  88 C2                mov   dl, al
0x0000000000004d1b:  30 F6                xor   dh, dh
0x0000000000004d1d:  83 EA 21             sub   dx, 0x21
0x0000000000004d20:  85 D2                test  dx, dx
0x0000000000004d22:  7C 05                jl    0x4d29
0x0000000000004d24:  83 FA 3F             cmp   dx, 0x3f
0x0000000000004d27:  7C 05                jl    0x4d2e
0x0000000000004d29:  83 C6 04             add   si, 4
0x0000000000004d2c:  EB C7                jmp   0x4cf5
0x0000000000004d2e:  B8 73 4C             mov   ax, 0x4c73
0x0000000000004d31:  89 D3                mov   bx, dx
0x0000000000004d33:  8E C0                mov   es, ax
0x0000000000004d35:  26 8A 07             mov   al, byte ptr es:[bx]
0x0000000000004d38:  98                   cbw  
0x0000000000004d39:  89 F3                mov   bx, si
0x0000000000004d3b:  01 C3                add   bx, ax
0x0000000000004d3d:  89 5E FA             mov   word ptr [bp - 6], bx
0x0000000000004d40:  81 FB 40 01          cmp   bx, 0x140
0x0000000000004d44:  7E 04                jle   0x4d4a
0x0000000000004d46:  C9                   LEAVE_MACRO 
0x0000000000004d47:  5F                   pop   di
0x0000000000004d48:  5E                   pop   si
0x0000000000004d49:  C3                   ret   
0x0000000000004d4a:  B9 00 70             mov   cx, 0x7000
0x0000000000004d4d:  89 D3                mov   bx, dx
0x0000000000004d4f:  89 F0                mov   ax, si
0x0000000000004d51:  01 D3                add   bx, dx
0x0000000000004d53:  89 FA                mov   dx, di
0x0000000000004d55:  8B 9F 78 1E          mov   bx, word ptr [bx + 0x1e78]
0x0000000000004d59:  8B 76 FA             mov   si, word ptr [bp - 6]
0x0000000000004d5c:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x0000000000004d61:  EB 92                jmp   0x4cf5
0x0000000000004d63:  FC                   cld   

ENDP

PROC    M_Responder_ NEAR
PUBLIC  M_Responder_

0x0000000000004d64:  53                   push  bx
0x0000000000004d65:  51                   push  cx
0x0000000000004d66:  56                   push  si
0x0000000000004d67:  89 C6                mov   si, ax
0x0000000000004d69:  8E C2                mov   es, dx
0x0000000000004d6b:  BB FF FF             mov   bx, 0xffff
0x0000000000004d6e:  26 80 3C 00          cmp   byte ptr es:[si], 0
0x0000000000004d72:  75 04                jne   0x4d78
0x0000000000004d74:  26 8B 5C 01          mov   bx, word ptr es:[si + 1]
0x0000000000004d78:  83 FB FF             cmp   bx, -1
0x0000000000004d7b:  74 2F                je    0x4dac
0x0000000000004d7d:  83 3E 10 1F 00       cmp   word ptr [0x1f10], 0
0x0000000000004d82:  74 5E                je    0x4de2
0x0000000000004d84:  83 FB 7F             cmp   bx, 0x7f
0x0000000000004d87:  75 27                jne   0x4db0
0x0000000000004d89:  83 3E 14 1F 00       cmp   word ptr [0x1f14], 0
0x0000000000004d8e:  7E 16                jle   0x4da6
0x0000000000004d90:  6B 1E 18 1F 18       imul  bx, word ptr [0x1f18], SAVESTRINGSIZE
0x0000000000004d95:  FF 0E 14 1F          dec   word ptr [0x1f14]
0x0000000000004d99:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004d9c:  03 1E 14 1F          add   bx, word ptr [0x1f14]
0x0000000000004da0:  8E C2                mov   es, dx
0x0000000000004da2:  26 C6 07 00          mov   byte ptr es:[bx], 0
0x0000000000004da6:  B0 01                mov   al, 1
0x0000000000004da8:  5E                   pop   si
0x0000000000004da9:  59                   pop   cx
0x0000000000004daa:  5B                   pop   bx
0x0000000000004dab:  CB                   retf  
0x0000000000004dac:  30 C0                xor   al, al
0x0000000000004dae:  EB F8                jmp   0x4da8
0x0000000000004db0:  83 FB 1B             cmp   bx, 0x1b
0x0000000000004db3:  75 30                jne   0x4de5
0x0000000000004db5:  31 C0                xor   ax, ax
0x0000000000004db7:  30 D2                xor   dl, dl
0x0000000000004db9:  A3 10 1F             mov   word ptr [0x1f10], ax
0x0000000000004dbc:  6B 0E 18 1F 18       imul  cx, word ptr [0x1f18], SAVESTRINGSIZE
0x0000000000004dc1:  88 D0                mov   al, dl
0x0000000000004dc3:  98                   cbw  
0x0000000000004dc4:  3D 18 00             cmp   ax, 0x18
0x0000000000004dc7:  73 DD                jae   0x4da6
0x0000000000004dc9:  88 D0                mov   al, dl
0x0000000000004dcb:  98                   cbw  
0x0000000000004dcc:  89 CE                mov   si, cx
0x0000000000004dce:  89 C3                mov   bx, ax
0x0000000000004dd0:  01 C6                add   si, ax
0x0000000000004dd2:  B8 B1 3C             mov   ax, SAVEGAMESTRINGS_SEGMENT
0x0000000000004dd5:  8E C0                mov   es, ax
0x0000000000004dd7:  8A 87 70 1C          mov   al, byte ptr [bx + 0x1c70]
0x0000000000004ddb:  FE C2                inc   dl
0x0000000000004ddd:  26 88 04             mov   byte ptr es:[si], al
0x0000000000004de0:  EB DF                jmp   0x4dc1
0x0000000000004de2:  E9 90 00             jmp   0x4e75
0x0000000000004de5:  83 FB 0D             cmp   bx, 0xd
0x0000000000004de8:  75 21                jne   0x4e0b
0x0000000000004dea:  6B 1E 18 1F 18       imul  bx, word ptr [0x1f18], SAVESTRINGSIZE
0x0000000000004def:  31 C0                xor   ax, ax
0x0000000000004df1:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004df4:  A3 10 1F             mov   word ptr [0x1f10], ax
0x0000000000004df7:  8E C2                mov   es, dx
0x0000000000004df9:  26 80 3F 00          cmp   byte ptr es:[bx], 0
0x0000000000004dfd:  74 A7                je    0x4da6
0x0000000000004dff:  A1 18 1F             mov   ax, word ptr [0x1f18]
0x0000000000004e02:  E8 67 F5             call  0x436c
0x0000000000004e05:  B0 01                mov   al, 1
0x0000000000004e07:  5E                   pop   si
0x0000000000004e08:  59                   pop   cx
0x0000000000004e09:  5B                   pop   bx
0x0000000000004e0a:  CB                   retf  
0x0000000000004e0b:  30 FF                xor   bh, bh
0x0000000000004e0d:  89 D8                mov   ax, bx
0x0000000000004e0f:  0E                   push  cs
0x0000000000004e10:  3E E8 B0 B6          call  0x4c4
0x0000000000004e14:  88 C3                mov   bl, al
0x0000000000004e16:  83 FB 20             cmp   bx, 0x20
0x0000000000004e19:  74 12                je    0x4e2d
0x0000000000004e1b:  8D 47 DF             lea   ax, [bx - 0x21]
0x0000000000004e1e:  85 C0                test  ax, ax
0x0000000000004e20:  7C 84                jl    0x4da6
0x0000000000004e22:  8D 47 DF             lea   ax, [bx - 0x21]
0x0000000000004e25:  3D 3F 00             cmp   ax, 0x3f
0x0000000000004e28:  7C 03                jl    0x4e2d
0x0000000000004e2a:  E9 79 FF             jmp   0x4da6
0x0000000000004e2d:  83 FB 20             cmp   bx, 0x20
0x0000000000004e30:  7C F8                jl    0x4e2a
0x0000000000004e32:  83 FB 7F             cmp   bx, 0x7f
0x0000000000004e35:  7F F3                jg    0x4e2a
0x0000000000004e37:  83 3E 14 1F 17       cmp   word ptr [0x1f14], 0x17
0x0000000000004e3c:  73 EC                jae   0x4e2a
0x0000000000004e3e:  6B 06 18 1F 18       imul  ax, word ptr [0x1f18], SAVESTRINGSIZE
0x0000000000004e43:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004e46:  E8 F7 FD             call  M_StringWidth_
0x0000000000004e49:  3D B0 00             cmp   ax, 0xb0
0x0000000000004e4c:  73 DC                jae   0x4e2a
0x0000000000004e4e:  6B 06 18 1F 18       imul  ax, word ptr [0x1f18], SAVESTRINGSIZE
0x0000000000004e53:  BA B1 3C             mov   dx, SAVEGAMESTRINGS_SEGMENT
0x0000000000004e56:  8B 36 14 1F          mov   si, word ptr [0x1f14]
0x0000000000004e5a:  8E C2                mov   es, dx
0x0000000000004e5c:  01 C6                add   si, ax
0x0000000000004e5e:  FF 06 14 1F          inc   word ptr [0x1f14]
0x0000000000004e62:  26 88 1C             mov   byte ptr es:[si], bl
0x0000000000004e65:  8B 1E 14 1F          mov   bx, word ptr [0x1f14]
0x0000000000004e69:  01 C3                add   bx, ax
0x0000000000004e6b:  26 C6 07 00          mov   byte ptr es:[bx], 0
0x0000000000004e6f:  B0 01                mov   al, 1
0x0000000000004e71:  5E                   pop   si
0x0000000000004e72:  59                   pop   cx
0x0000000000004e73:  5B                   pop   bx
0x0000000000004e74:  CB                   retf  
0x0000000000004e75:  80 3E F9 1F 00       cmp   byte ptr [0x1ff9], 0
0x0000000000004e7a:  74 51                je    0x4ecd
0x0000000000004e7c:  80 3E F5 1F 01       cmp   byte ptr [0x1ff5], 1
0x0000000000004e81:  75 05                jne   0x4e88
0x0000000000004e83:  83 FB 20             cmp   bx, 0x20
0x0000000000004e86:  75 30                jne   0x4eb8
0x0000000000004e88:  BE 6C 04             mov   si, 0x46c
0x0000000000004e8b:  A0 0C 1F             mov   al, byte ptr [0x1f0c]
0x0000000000004e8e:  C6 06 F9 1F 00       mov   byte ptr [0x1ff9], 0
0x0000000000004e93:  88 04                mov   byte ptr [si], al
0x0000000000004e95:  83 3E 16 1F 00       cmp   word ptr [0x1f16], 0
0x0000000000004e9a:  74 06                je    0x4ea2
0x0000000000004e9c:  89 D8                mov   ax, bx
0x0000000000004e9e:  FF 16 16 1F          call  word ptr [0x1f16]
0x0000000000004ea2:  BB 6C 04             mov   bx, 0x46c
0x0000000000004ea5:  BA 18 00             mov   dx, SFX_SWTCHX
0x0000000000004ea8:  31 C0                xor   ax, ax
0x0000000000004eaa:  C6 07 00             mov   byte ptr [bx], 0
0x0000000000004ead:  9A BF 03 4F 13       call  S_StartSound_
0x0000000000004eb2:  B0 01                mov   al, 1
0x0000000000004eb4:  5E                   pop   si
0x0000000000004eb5:  59                   pop   cx
0x0000000000004eb6:  5B                   pop   bx
0x0000000000004eb7:  CB                   retf  
0x0000000000004eb8:  83 FB 6E             cmp   bx, 0x6e
0x0000000000004ebb:  74 CB                je    0x4e88
0x0000000000004ebd:  83 FB 79             cmp   bx, 0x79
0x0000000000004ec0:  74 C6                je    0x4e88
0x0000000000004ec2:  83 FB 1B             cmp   bx, 0x1b
0x0000000000004ec5:  74 C1                je    0x4e88
0x0000000000004ec7:  30 C0                xor   al, al
0x0000000000004ec9:  5E                   pop   si
0x0000000000004eca:  59                   pop   cx
0x0000000000004ecb:  5B                   pop   bx
0x0000000000004ecc:  CB                   retf  
0x0000000000004ecd:  BE 6C 04             mov   si, 0x46c
0x0000000000004ed0:  8A 04                mov   al, byte ptr [si]
0x0000000000004ed2:  84 C0                test  al, al
0x0000000000004ed4:  75 40                jne   0x4f16
0x0000000000004ed6:  81 FB BF 00          cmp   bx, 0xbf
0x0000000000004eda:  73 17                jae   0x4ef3
0x0000000000004edc:  81 FB BB 00          cmp   bx, 0xbb
0x0000000000004ee0:  73 64                jae   0x4f46
0x0000000000004ee2:  83 FB 3D             cmp   bx, 0x3d
0x0000000000004ee5:  75 61                jne   0x4f48
0x0000000000004ee7:  BB EA 02             mov   bx, 0x2ea
0x0000000000004eea:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004eed:  74 5B                je    0x4f4a
0x0000000000004eef:  5E                   pop   si
0x0000000000004ef0:  59                   pop   cx
0x0000000000004ef1:  5B                   pop   bx
0x0000000000004ef2:  CB                   retf  
0x0000000000004ef3:  76 58                jbe   0x4f4d
0x0000000000004ef5:  81 FB C2 00          cmp   bx, 0xc2
0x0000000000004ef9:  73 1D                jae   0x4f18
0x0000000000004efb:  81 FB C1 00          cmp   bx, 0xc1
0x0000000000004eff:  75 4F                jne   0x4f50
0x0000000000004f01:  BA 17 00             mov   dx, 0x17
0x0000000000004f04:  30 E4                xor   ah, ah
0x0000000000004f06:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000004f0b:  31 C0                xor   ax, ax
0x0000000000004f0d:  E8 10 FA             call  0x4920
0x0000000000004f10:  B0 01                mov   al, 1
0x0000000000004f12:  5E                   pop   si
0x0000000000004f13:  59                   pop   cx
0x0000000000004f14:  5B                   pop   bx
0x0000000000004f15:  CB                   retf  
0x0000000000004f16:  EB 47                jmp   0x4f5f
0x0000000000004f18:  76 57                jbe   0x4f71
0x0000000000004f1a:  81 FB D7 00          cmp   bx, 0xd7
0x0000000000004f1e:  75 33                jne   0x4f53
0x0000000000004f20:  FE 06 1C 20          inc   byte ptr [0x201c]
0x0000000000004f24:  80 3E 1C 20 04       cmp   byte ptr [0x201c], 4
0x0000000000004f29:  76 03                jbe   0x4f2e
0x0000000000004f2b:  A2 1C 20             mov   byte ptr [0x201c], al
0x0000000000004f2e:  A0 1C 20             mov   al, byte ptr [0x201c]
0x0000000000004f31:  30 E4                xor   ah, ah
0x0000000000004f33:  BB 24 08             mov   bx, 0x824
0x0000000000004f36:  05 12 00             add   ax, 0x12
0x0000000000004f39:  89 07                mov   word ptr [bx], ax
0x0000000000004f3b:  31 C0                xor   ax, ax
0x0000000000004f3d:  E8 A3 1D             call  0x6ce3
0x0000000000004f40:  B0 01                mov   al, 1
0x0000000000004f42:  5E                   pop   si
0x0000000000004f43:  59                   pop   cx
0x0000000000004f44:  5B                   pop   bx
0x0000000000004f45:  CB                   retf  
0x0000000000004f46:  EB 2C                jmp   0x4f74
0x0000000000004f48:  EB 5A                jmp   0x4fa4
0x0000000000004f4a:  E9 90 00             jmp   0x4fdd
0x0000000000004f4d:  E9 05 01             jmp   0x5055
0x0000000000004f50:  E9 17 01             jmp   0x506a
0x0000000000004f53:  81 FB C4 00          cmp   bx, 0xc4
0x0000000000004f57:  74 5F                je    0x4fb8
0x0000000000004f59:  81 FB C3 00          cmp   bx, 0xc3
0x0000000000004f5d:  74 5C                je    0x4fbb
0x0000000000004f5f:  BE 6C 04             mov   si, 0x46c
0x0000000000004f62:  8A 04                mov   al, byte ptr [si]
0x0000000000004f64:  84 C0                test  al, al
0x0000000000004f66:  75 6B                jne   0x4fd3
0x0000000000004f68:  83 FB 1B             cmp   bx, 0x1b
0x0000000000004f6b:  74 69                je    0x4fd6
0x0000000000004f6d:  5E                   pop   si
0x0000000000004f6e:  59                   pop   cx
0x0000000000004f6f:  5B                   pop   bx
0x0000000000004f70:  CB                   retf  
0x0000000000004f71:  E9 09 01             jmp   0x507d
0x0000000000004f74:  76 63                jbe   0x4fd9
0x0000000000004f76:  81 FB BE 00          cmp   bx, 0xbe
0x0000000000004f7a:  74 5F                je    0x4fdb
0x0000000000004f7c:  81 FB BD 00          cmp   bx, 0xbd
0x0000000000004f80:  75 71                jne   0x4ff3
0x0000000000004f82:  E8 DD 03             call  M_StartControlPanel_
0x0000000000004f85:  BA 17 00             mov   dx, 0x17
0x0000000000004f88:  31 C0                xor   ax, ax
0x0000000000004f8a:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000004f8f:  A1 BF 10             mov   ax, word ptr [0x10bf]
0x0000000000004f92:  C7 06 0E 1F B5 10    mov   word ptr [0x1f0e], 0x10b5
0x0000000000004f98:  A3 12 1F             mov   word ptr [0x1f12], ax
0x0000000000004f9b:  E8 C6 F2             call  0x4264
0x0000000000004f9e:  B0 01                mov   al, 1
0x0000000000004fa0:  5E                   pop   si
0x0000000000004fa1:  59                   pop   cx
0x0000000000004fa2:  5B                   pop   bx
0x0000000000004fa3:  CB                   retf  
0x0000000000004fa4:  83 FB 2D             cmp   bx, 0x2d
0x0000000000004fa7:  75 B6                jne   0x4f5f
0x0000000000004fa9:  BB EA 02             mov   bx, 0x2ea
0x0000000000004fac:  8A 07                mov   al, byte ptr [bx]
0x0000000000004fae:  84 C0                test  al, al
0x0000000000004fb0:  74 0C                je    0x4fbe
0x0000000000004fb2:  30 C0                xor   al, al
0x0000000000004fb4:  5E                   pop   si
0x0000000000004fb5:  59                   pop   cx
0x0000000000004fb6:  5B                   pop   bx
0x0000000000004fb7:  CB                   retf  
0x0000000000004fb8:  E9 EA 00             jmp   0x50a5
0x0000000000004fbb:  E9 D4 00             jmp   0x5092
0x0000000000004fbe:  30 E4                xor   ah, ah
0x0000000000004fc0:  BA 16 00             mov   dx, 0x16
0x0000000000004fc3:  E8 70 FB             call  0x4b36
0x0000000000004fc6:  31 C0                xor   ax, ax
0x0000000000004fc8:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000004fcd:  B0 01                mov   al, 1
0x0000000000004fcf:  5E                   pop   si
0x0000000000004fd0:  59                   pop   cx
0x0000000000004fd1:  5B                   pop   bx
0x0000000000004fd2:  CB                   retf  
0x0000000000004fd3:  E9 F7 00             jmp   0x50cd
0x0000000000004fd6:  E9 E1 00             jmp   0x50ba
0x0000000000004fd9:  EB 1A                jmp   0x4ff5
0x0000000000004fdb:  EB 5C                jmp   0x5039
0x0000000000004fdd:  B8 01 00             mov   ax, 1
0x0000000000004fe0:  BA 16 00             mov   dx, 0x16
0x0000000000004fe3:  E8 50 FB             call  0x4b36
0x0000000000004fe6:  31 C0                xor   ax, ax
0x0000000000004fe8:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000004fed:  B0 01                mov   al, 1
0x0000000000004fef:  5E                   pop   si
0x0000000000004ff0:  59                   pop   cx
0x0000000000004ff1:  5B                   pop   bx
0x0000000000004ff2:  CB                   retf  
0x0000000000004ff3:  EB 2C                jmp   0x5021
0x0000000000004ff5:  BB E1 00             mov   bx, 0xe1
0x0000000000004ff8:  E8 67 03             call  M_StartControlPanel_
0x0000000000004ffb:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004ffe:  74 19                je    0x5019
0x0000000000005000:  C7 06 0E 1F 6B 10    mov   word ptr [0x1f0e], 0x106b
0x0000000000005006:  31 C0                xor   ax, ax
0x0000000000005008:  BA 17 00             mov   dx, 0x17
0x000000000000500b:  A3 12 1F             mov   word ptr [0x1f12], ax
0x000000000000500e:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000005013:  B0 01                mov   al, 1
0x0000000000005015:  5E                   pop   si
0x0000000000005016:  59                   pop   cx
0x0000000000005017:  5B                   pop   bx
0x0000000000005018:  CB                   retf  
0x0000000000005019:  C7 06 0E 1F 5A 10    mov   word ptr [0x1f0e], 0x105a
0x000000000000501f:  EB E5                jmp   0x5006
0x0000000000005021:  E8 3E 03             call  M_StartControlPanel_
0x0000000000005024:  BA 17 00             mov   dx, 0x17
0x0000000000005027:  31 C0                xor   ax, ax
0x0000000000005029:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000502e:  31 C0                xor   ax, ax
0x0000000000005030:  E8 E3 F3             call  0x4416
0x0000000000005033:  B0 01                mov   al, 1
0x0000000000005035:  5E                   pop   si
0x0000000000005036:  59                   pop   cx
0x0000000000005037:  5B                   pop   bx
0x0000000000005038:  CB                   retf  
0x0000000000005039:  E8 26 03             call  M_StartControlPanel_
0x000000000000503c:  C7 06 0E 1F 8B 10    mov   word ptr [0x1f0e], 0x108b
0x0000000000005042:  31 C0                xor   ax, ax
0x0000000000005044:  BA 17 00             mov   dx, 0x17
0x0000000000005047:  A3 12 1F             mov   word ptr [0x1f12], ax
0x000000000000504a:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000504f:  B0 01                mov   al, 1
0x0000000000005051:  5E                   pop   si
0x0000000000005052:  59                   pop   cx
0x0000000000005053:  5B                   pop   bx
0x0000000000005054:  CB                   retf  
0x0000000000005055:  30 E4                xor   ah, ah
0x0000000000005057:  BA 17 00             mov   dx, 0x17
0x000000000000505a:  E8 81 FA             call  0x4ade
0x000000000000505d:  31 C0                xor   ax, ax
0x000000000000505f:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000005064:  B0 01                mov   al, 1
0x0000000000005066:  5E                   pop   si
0x0000000000005067:  59                   pop   cx
0x0000000000005068:  5B                   pop   bx
0x0000000000005069:  CB                   retf  
0x000000000000506a:  BA 17 00             mov   dx, 0x17
0x000000000000506d:  30 E4                xor   ah, ah
0x000000000000506f:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000005074:  E8 09 F4             call  0x4480
0x0000000000005077:  B0 01                mov   al, 1
0x0000000000005079:  5E                   pop   si
0x000000000000507a:  59                   pop   cx
0x000000000000507b:  5B                   pop   bx
0x000000000000507c:  CB                   retf  
0x000000000000507d:  30 E4                xor   ah, ah
0x000000000000507f:  BA 17 00             mov   dx, 0x17
0x0000000000005082:  E8 51 F8             call  0x48d6
0x0000000000005085:  31 C0                xor   ax, ax
0x0000000000005087:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000508c:  B0 01                mov   al, 1
0x000000000000508e:  5E                   pop   si
0x000000000000508f:  59                   pop   cx
0x0000000000005090:  5B                   pop   bx
0x0000000000005091:  CB                   retf  
0x0000000000005092:  BA 17 00             mov   dx, 0x17
0x0000000000005095:  30 E4                xor   ah, ah
0x0000000000005097:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000509c:  E8 AB F4             call  0x454a
0x000000000000509f:  B0 01                mov   al, 1
0x00000000000050a1:  5E                   pop   si
0x00000000000050a2:  59                   pop   cx
0x00000000000050a3:  5B                   pop   bx
0x00000000000050a4:  CB                   retf  
0x00000000000050a5:  BA 17 00             mov   dx, 0x17
0x00000000000050a8:  30 E4                xor   ah, ah
0x00000000000050aa:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x00000000000050af:  31 C0                xor   ax, ax
0x00000000000050b1:  E8 58 F9             call  0x4a0c
0x00000000000050b4:  B0 01                mov   al, 1
0x00000000000050b6:  5E                   pop   si
0x00000000000050b7:  59                   pop   cx
0x00000000000050b8:  5B                   pop   bx
0x00000000000050b9:  CB                   retf  
0x00000000000050ba:  E8 A5 02             call  M_StartControlPanel_
0x00000000000050bd:  BA 17 00             mov   dx, 0x17
0x00000000000050c0:  31 C0                xor   ax, ax
0x00000000000050c2:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x00000000000050c7:  B0 01                mov   al, 1
0x00000000000050c9:  5E                   pop   si
0x00000000000050ca:  59                   pop   cx
0x00000000000050cb:  5B                   pop   bx
0x00000000000050cc:  CB                   retf  
0x00000000000050cd:  8B 16 12 1F          mov   dx, word ptr [0x1f12]
0x00000000000050d1:  89 D0                mov   ax, dx
0x00000000000050d3:  C1 E0 02             shl   ax, 2
0x00000000000050d6:  01 D0                add   ax, dx
0x00000000000050d8:  81 FB AC 00          cmp   bx, 0xac
0x00000000000050dc:  73 34                jae   0x5112
0x00000000000050de:  83 FB 7F             cmp   bx, 0x7f
0x00000000000050e1:  75 2C                jne   0x510f
0x00000000000050e3:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x00000000000050e7:  8B 47 01             mov   ax, word ptr [bx + 1]
0x00000000000050ea:  89 57 0A             mov   word ptr [bx + 0xa], dx
0x00000000000050ed:  85 C0                test  ax, ax
0x00000000000050ef:  75 03                jne   0x50f4
0x00000000000050f1:  E9 B2 FC             jmp   0x4da6
0x00000000000050f4:  89 C3                mov   bx, ax
0x00000000000050f6:  A3 0E 1F             mov   word ptr [0x1f0e], ax
0x00000000000050f9:  8B 47 0A             mov   ax, word ptr [bx + 0xa]
0x00000000000050fc:  BA 17 00             mov   dx, 0x17
0x00000000000050ff:  A3 12 1F             mov   word ptr [0x1f12], ax
0x0000000000005102:  31 C0                xor   ax, ax
0x0000000000005104:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000005109:  B0 01                mov   al, 1
0x000000000000510b:  5E                   pop   si
0x000000000000510c:  59                   pop   cx
0x000000000000510d:  5B                   pop   bx
0x000000000000510e:  CB                   retf  
0x000000000000510f:  E9 2F 01             jmp   0x5241
0x0000000000005112:  77 4F                ja    0x5163
0x0000000000005114:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x0000000000005118:  8B 5F 03             mov   bx, word ptr [bx + 3]
0x000000000000511b:  01 C3                add   bx, ax
0x000000000000511d:  83 7F 02 00          cmp   word ptr [bx + 2], 0
0x0000000000005121:  74 CE                je    0x50f1
0x0000000000005123:  80 3F 02             cmp   byte ptr [bx], 2
0x0000000000005126:  75 C9                jne   0x50f1
0x0000000000005128:  BB 23 07             mov   bx, 0x723
0x000000000000512b:  BA 16 00             mov   dx, 0x16
0x000000000000512e:  8A 1F                mov   bl, byte ptr [bx]
0x0000000000005130:  9A B0 2D 4F 13       lcall 0x134f:0x2db0
0x0000000000005135:  31 C0                xor   ax, ax
0x0000000000005137:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000513c:  8B 16 12 1F          mov   dx, word ptr [0x1f12]
0x0000000000005140:  89 D0                mov   ax, dx
0x0000000000005142:  8B 36 0E 1F          mov   si, word ptr [0x1f0e]
0x0000000000005146:  C1 E0 02             shl   ax, 2
0x0000000000005149:  8B 74 03             mov   si, word ptr [si + 3]
0x000000000000514c:  01 D0                add   ax, dx
0x000000000000514e:  01 C6                add   si, ax
0x0000000000005150:  31 C0                xor   ax, ax
0x0000000000005152:  FF 54 02             call  word ptr [si + 2]
0x0000000000005155:  88 D8                mov   al, bl
0x0000000000005157:  98                   cbw  
0x0000000000005158:  9A 14 2E 4F 13       lcall 0x134f:0x2e14
0x000000000000515d:  B0 01                mov   al, 1
0x000000000000515f:  5E                   pop   si
0x0000000000005160:  59                   pop   cx
0x0000000000005161:  5B                   pop   bx
0x0000000000005162:  CB                   retf  
0x0000000000005163:  81 FB AF 00          cmp   bx, 0xaf
0x0000000000005167:  75 3E                jne   0x51a7
0x0000000000005169:  31 C9                xor   cx, cx
0x000000000000516b:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x000000000000516f:  8A 07                mov   al, byte ptr [bx]
0x0000000000005171:  98                   cbw  
0x0000000000005172:  89 C2                mov   dx, ax
0x0000000000005174:  A1 12 1F             mov   ax, word ptr [0x1f12]
0x0000000000005177:  4A                   dec   dx
0x0000000000005178:  40                   inc   ax
0x0000000000005179:  39 D0                cmp   ax, dx
0x000000000000517b:  7E 27                jle   0x51a4
0x000000000000517d:  89 0E 12 1F          mov   word ptr [0x1f12], cx
0x0000000000005181:  BA 13 00             mov   dx, 0x13
0x0000000000005184:  89 C8                mov   ax, cx
0x0000000000005186:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000518b:  6B 06 12 1F 05       imul  ax, word ptr [0x1f12], 5
0x0000000000005190:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x0000000000005194:  8B 5F 03             mov   bx, word ptr [bx + 3]
0x0000000000005197:  01 C3                add   bx, ax
0x0000000000005199:  80 3F FF             cmp   byte ptr [bx], 0xff
0x000000000000519c:  74 CD                je    0x516b
0x000000000000519e:  B0 01                mov   al, 1
0x00000000000051a0:  5E                   pop   si
0x00000000000051a1:  59                   pop   cx
0x00000000000051a2:  5B                   pop   bx
0x00000000000051a3:  CB                   retf  
0x00000000000051a4:  E9 07 01             jmp   0x52ae
0x00000000000051a7:  81 FB AE 00          cmp   bx, 0xae
0x00000000000051ab:  75 53                jne   0x5200
0x00000000000051ad:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x00000000000051b1:  8B 5F 03             mov   bx, word ptr [bx + 3]
0x00000000000051b4:  01 C3                add   bx, ax
0x00000000000051b6:  83 7F 02 00          cmp   word ptr [bx + 2], 0
0x00000000000051ba:  75 03                jne   0x51bf
0x00000000000051bc:  E9 E7 FB             jmp   0x4da6
0x00000000000051bf:  80 3F 02             cmp   byte ptr [bx], 2
0x00000000000051c2:  75 F8                jne   0x51bc
0x00000000000051c4:  BB 23 07             mov   bx, 0x723
0x00000000000051c7:  BA 16 00             mov   dx, 0x16
0x00000000000051ca:  8A 1F                mov   bl, byte ptr [bx]
0x00000000000051cc:  9A B0 2D 4F 13       lcall 0x134f:0x2db0
0x00000000000051d1:  31 C0                xor   ax, ax
0x00000000000051d3:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x00000000000051d8:  8B 16 12 1F          mov   dx, word ptr [0x1f12]
0x00000000000051dc:  89 D0                mov   ax, dx
0x00000000000051de:  8B 36 0E 1F          mov   si, word ptr [0x1f0e]
0x00000000000051e2:  C1 E0 02             shl   ax, 2
0x00000000000051e5:  8B 74 03             mov   si, word ptr [si + 3]
0x00000000000051e8:  01 D0                add   ax, dx
0x00000000000051ea:  01 C6                add   si, ax
0x00000000000051ec:  B8 01 00             mov   ax, 1
0x00000000000051ef:  FF 54 02             call  word ptr [si + 2]
0x00000000000051f2:  88 D8                mov   al, bl
0x00000000000051f4:  98                   cbw  
0x00000000000051f5:  9A 14 2E 4F 13       lcall 0x134f:0x2e14
0x00000000000051fa:  B0 01                mov   al, 1
0x00000000000051fc:  5E                   pop   si
0x00000000000051fd:  59                   pop   cx
0x00000000000051fe:  5B                   pop   bx
0x00000000000051ff:  CB                   retf  
0x0000000000005200:  81 FB AD 00          cmp   bx, 0xad
0x0000000000005204:  75 39                jne   0x523f
0x0000000000005206:  B9 FF FF             mov   cx, 0xffff
0x0000000000005209:  31 F6                xor   si, si
0x000000000000520b:  3B 36 12 1F          cmp   si, word ptr [0x1f12]
0x000000000000520f:  75 6C                jne   0x527d
0x0000000000005211:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x0000000000005215:  8A 07                mov   al, byte ptr [bx]
0x0000000000005217:  98                   cbw  
0x0000000000005218:  01 C8                add   ax, cx
0x000000000000521a:  A3 12 1F             mov   word ptr [0x1f12], ax
0x000000000000521d:  BA 13 00             mov   dx, 0x13
0x0000000000005220:  89 F0                mov   ax, si
0x0000000000005222:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000005227:  6B 06 12 1F 05       imul  ax, word ptr [0x1f12], 5
0x000000000000522c:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x0000000000005230:  8B 5F 03             mov   bx, word ptr [bx + 3]
0x0000000000005233:  01 C3                add   bx, ax
0x0000000000005235:  3A 0F                cmp   cl, byte ptr [bx]
0x0000000000005237:  74 D2                je    0x520b
0x0000000000005239:  B0 01                mov   al, 1
0x000000000000523b:  5E                   pop   si
0x000000000000523c:  59                   pop   cx
0x000000000000523d:  5B                   pop   bx
0x000000000000523e:  CB                   retf  
0x000000000000523f:  EB 43                jmp   0x5284
0x0000000000005241:  83 FB 1B             cmp   bx, 0x1b
0x0000000000005244:  75 39                jne   0x527f
0x0000000000005246:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x000000000000524a:  89 57 0A             mov   word ptr [bx + 0xa], dx
0x000000000000524d:  BB 9B 01             mov   bx, 0x19b
0x0000000000005250:  C6 04 00             mov   byte ptr [si], 0
0x0000000000005253:  C6 06 20 20 00       mov   byte ptr [0x2020], 0
0x0000000000005258:  80 3F 09             cmp   byte ptr [bx], 9
0x000000000000525b:  77 10                ja    0x526d
0x000000000000525d:  BB 9E 01             mov   bx, 0x19e
0x0000000000005260:  C6 06 15 20 03       mov   byte ptr [0x2015], 3
0x0000000000005265:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000005268:  74 03                je    0x526d
0x000000000000526a:  C6 07 06             mov   byte ptr [bx], 6
0x000000000000526d:  BA 18 00             mov   dx, SFX_SWTCHX
0x0000000000005270:  31 C0                xor   ax, ax
0x0000000000005272:  9A BF 03 4F 13       call  S_StartSound_
0x0000000000005277:  B0 01                mov   al, 1
0x0000000000005279:  5E                   pop   si
0x000000000000527a:  59                   pop   cx
0x000000000000527b:  5B                   pop   bx
0x000000000000527c:  CB                   retf  
0x000000000000527d:  EB 35                jmp   0x52b4
0x000000000000527f:  83 FB 0D             cmp   bx, 0xd
0x0000000000005282:  74 3A                je    0x52be
0x0000000000005284:  8B 16 12 1F          mov   dx, word ptr [0x1f12]
0x0000000000005288:  42                   inc   dx
0x0000000000005289:  89 D1                mov   cx, dx
0x000000000000528b:  C1 E1 02             shl   cx, 2
0x000000000000528e:  01 D1                add   cx, dx
0x0000000000005290:  8B 36 0E 1F          mov   si, word ptr [0x1f0e]
0x0000000000005294:  8A 04                mov   al, byte ptr [si]
0x0000000000005296:  98                   cbw  
0x0000000000005297:  39 C2                cmp   dx, ax
0x0000000000005299:  7D 20                jge   0x52bb
0x000000000000529b:  8B 74 03             mov   si, word ptr [si + 3]
0x000000000000529e:  01 CE                add   si, cx
0x00000000000052a0:  8A 44 04             mov   al, byte ptr [si + 4]
0x00000000000052a3:  98                   cbw  
0x00000000000052a4:  39 D8                cmp   ax, bx
0x00000000000052a6:  74 70                je    0x5318
0x00000000000052a8:  83 C1 05             add   cx, 5
0x00000000000052ab:  42                   inc   dx
0x00000000000052ac:  EB E2                jmp   0x5290
0x00000000000052ae:  A3 12 1F             mov   word ptr [0x1f12], ax
0x00000000000052b1:  E9 CD FE             jmp   0x5181
0x00000000000052b4:  01 0E 12 1F          add   word ptr [0x1f12], cx
0x00000000000052b8:  E9 62 FF             jmp   0x521d
0x00000000000052bb:  E9 78 00             jmp   0x5336
0x00000000000052be:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x00000000000052c2:  8B 5F 03             mov   bx, word ptr [bx + 3]
0x00000000000052c5:  01 C3                add   bx, ax
0x00000000000052c7:  83 7F 02 00          cmp   word ptr [bx + 2], 0
0x00000000000052cb:  75 03                jne   0x52d0
0x00000000000052cd:  E9 D6 FA             jmp   0x4da6
0x00000000000052d0:  80 3F 00             cmp   byte ptr [bx], 0
0x00000000000052d3:  74 F8                je    0x52cd
0x00000000000052d5:  BB 23 07             mov   bx, 0x723
0x00000000000052d8:  8A 0F                mov   cl, byte ptr [bx]
0x00000000000052da:  9A B0 2D 4F 13       lcall 0x134f:0x2db0
0x00000000000052df:  A1 12 1F             mov   ax, word ptr [0x1f12]
0x00000000000052e2:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x00000000000052e6:  89 C2                mov   dx, ax
0x00000000000052e8:  89 47 0A             mov   word ptr [bx + 0xa], ax
0x00000000000052eb:  C1 E2 02             shl   dx, 2
0x00000000000052ee:  8B 5F 03             mov   bx, word ptr [bx + 3]
0x00000000000052f1:  01 C2                add   dx, ax
0x00000000000052f3:  01 D3                add   bx, dx
0x00000000000052f5:  80 3F 02             cmp   byte ptr [bx], 2
0x00000000000052f8:  75 20                jne   0x531a
0x00000000000052fa:  B8 01 00             mov   ax, 1
0x00000000000052fd:  BA 16 00             mov   dx, 0x16
0x0000000000005300:  FF 57 02             call  word ptr [bx + 2]
0x0000000000005303:  31 C0                xor   ax, ax
0x0000000000005305:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x000000000000530a:  88 C8                mov   al, cl
0x000000000000530c:  98                   cbw  
0x000000000000530d:  9A 14 2E 4F 13       lcall 0x134f:0x2e14
0x0000000000005312:  B0 01                mov   al, 1
0x0000000000005314:  5E                   pop   si
0x0000000000005315:  59                   pop   cx
0x0000000000005316:  5B                   pop   bx
0x0000000000005317:  CB                   retf  
0x0000000000005318:  EB 08                jmp   0x5322
0x000000000000531a:  FF 57 02             call  word ptr [bx + 2]
0x000000000000531d:  BA 01 00             mov   dx, 1
0x0000000000005320:  EB E1                jmp   0x5303
0x0000000000005322:  89 16 12 1F          mov   word ptr [0x1f12], dx
0x0000000000005326:  31 D8                xor   ax, bx
0x0000000000005328:  BA 13 00             mov   dx, 0x13
0x000000000000532b:  9A BF 03 4F 13       lcall 0x134f:0x3bf
0x0000000000005330:  B0 01                mov   al, 1
0x0000000000005332:  5E                   pop   si
0x0000000000005333:  59                   pop   cx
0x0000000000005334:  5B                   pop   bx
0x0000000000005335:  CB                   retf  
0x0000000000005336:  31 D2                xor   dx, dx
0x0000000000005338:  83 3E 12 1F 00       cmp   word ptr [0x1f12], 0
0x000000000000533d:  7C 1D                jl    0x535c
0x000000000000533f:  31 C9                xor   cx, cx
0x0000000000005341:  8B 36 0E 1F          mov   si, word ptr [0x1f0e]
0x0000000000005345:  8B 74 03             mov   si, word ptr [si + 3]
0x0000000000005348:  01 CE                add   si, cx
0x000000000000534a:  8A 44 04             mov   al, byte ptr [si + 4]
0x000000000000534d:  98                   cbw  
0x000000000000534e:  39 D8                cmp   ax, bx
0x0000000000005350:  74 D0                je    0x5322
0x0000000000005352:  42                   inc   dx
0x0000000000005353:  83 C1 05             add   cx, 5
0x0000000000005356:  3B 16 12 1F          cmp   dx, word ptr [0x1f12]
0x000000000000535a:  7E E5                jle   0x5341
0x000000000000535c:  30 C0                xor   al, al
0x000000000000535e:  5E                   pop   si
0x000000000000535f:  59                   pop   cx
0x0000000000005360:  5B                   pop   bx
0x0000000000005361:  CB                   retf  

ENDP

PROC    M_StartControlPanel_ NEAR
PUBLIC  M_StartControlPanel_


0x0000000000005362:  53                   push  bx
0x0000000000005363:  BB 6C 04             mov   bx, 0x46c
0x0000000000005366:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000005369:  74 02                je    0x536d
0x000000000000536b:  5B                   pop   bx
0x000000000000536c:  C3                   ret   
0x000000000000536d:  C6 07 01             mov   byte ptr [bx], 1
0x0000000000005370:  8B 1E DA 0F          mov   bx, word ptr [0xfda]
0x0000000000005374:  C7 06 0E 1F D0 0F    mov   word ptr [0x1f0e], 0xfd0
0x000000000000537a:  89 1E 12 1F          mov   word ptr [0x1f12], bx
0x000000000000537e:  5B                   pop   bx
0x000000000000537f:  C3                   ret   

ENDP

PROC    M_Drawer_ NEAR
PUBLIC  M_Drawer_

0x0000000000005380:  53                   push  bx
0x0000000000005381:  51                   push  cx
0x0000000000005382:  52                   push  dx
0x0000000000005383:  56                   push  si
0x0000000000005384:  57                   push  di
0x0000000000005385:  55                   push  bp
0x0000000000005386:  89 E5                mov   bp, sp
0x0000000000005388:  83 EC 36             sub   sp, 0x36
0x000000000000538b:  88 46 FE             mov   byte ptr [bp - 2], al
0x000000000000538e:  C6 06 20 20 00       mov   byte ptr [0x2020], 0
0x0000000000005393:  80 3E F9 1F 00       cmp   byte ptr [0x1ff9], 0
0x0000000000005398:  75 0F                jne   0x53a9
0x000000000000539a:  BB 6C 04             mov   bx, 0x46c
0x000000000000539d:  80 3F 00             cmp   byte ptr [bx], 0
0x00000000000053a0:  75 57                jne   0x53f9
0x00000000000053a2:  C9                   LEAVE_MACRO 
0x00000000000053a3:  5F                   pop   di
0x00000000000053a4:  5E                   pop   si
0x00000000000053a5:  5A                   pop   dx
0x00000000000053a6:  59                   pop   cx
0x00000000000053a7:  5B                   pop   bx
0x00000000000053a8:  CB                   retf  
0x00000000000053a9:  9A 7D 2C 4F 13       call  Z_QuickMapStatus_
0x00000000000053ae:  B8 6C 1F             mov   ax, 0x1f6c
0x00000000000053b1:  8C DA                mov   dx, ds
0x00000000000053b3:  E8 E6 F8             call  0x4c9c
0x00000000000053b6:  BA 64 00             mov   dx, 0x64
0x00000000000053b9:  D1 F8                sar   ax, 1
0x00000000000053bb:  29 C2                sub   dx, ax
0x00000000000053bd:  C7 46 F2 00 00       mov   word ptr [bp - 0xe], 0
0x00000000000053c2:  89 56 F8             mov   word ptr [bp - 8], dx
0x00000000000053c5:  80 3E 6C 1F 00       cmp   byte ptr [0x1f6c], 0
0x00000000000053ca:  74 30                je    0x53fc
0x00000000000053cc:  B8 6C 1F             mov   ax, 0x1f6c
0x00000000000053cf:  8B 5E F2             mov   bx, word ptr [bp - 0xe]
0x00000000000053d2:  8C D9                mov   cx, ds
0x00000000000053d4:  03 46 F2             add   ax, word ptr [bp - 0xe]
0x00000000000053d7:  31 F6                xor   si, si
0x00000000000053d9:  89 46 FC             mov   word ptr [bp - 4], ax
0x00000000000053dc:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x00000000000053df:  8C DA                mov   dx, ds
0x00000000000053e1:  0E                   push  cs
0x00000000000053e2:  3E E8 C0 B0          call  0x4a6
0x00000000000053e6:  39 C6                cmp   si, ax
0x00000000000053e8:  7D 29                jge   0x5413
0x00000000000053ea:  8D 7C 01             lea   di, [si + 1]
0x00000000000053ed:  80 BF 6C 1F 0A       cmp   byte ptr [bx + 0x1f6c], 0xa
0x00000000000053f2:  74 0A                je    0x53fe
0x00000000000053f4:  43                   inc   bx
0x00000000000053f5:  89 FE                mov   si, di
0x00000000000053f7:  EB E3                jmp   0x53dc
0x00000000000053f9:  E9 84 00             jmp   0x5480
0x00000000000053fc:  EB 64                jmp   0x5462
0x00000000000053fe:  8B 5E FC             mov   bx, word ptr [bp - 4]
0x0000000000005401:  8D 46 CA             lea   ax, [bp - 0x36]
0x0000000000005404:  56                   push  si
0x0000000000005405:  8C DA                mov   dx, ds
0x0000000000005407:  0E                   push  cs
0x0000000000005408:  3E E8 F4 B0          call  0x500
0x000000000000540c:  01 7E F2             add   word ptr [bp - 0xe], di
0x000000000000540f:  C6 42 CA 00          mov   byte ptr [bp + si - 0x36], 0
0x0000000000005413:  BB 6C 1F             mov   bx, 0x1f6c
0x0000000000005416:  03 5E F2             add   bx, word ptr [bp - 0xe]
0x0000000000005419:  8C DA                mov   dx, ds
0x000000000000541b:  89 D8                mov   ax, bx
0x000000000000541d:  8C D9                mov   cx, ds
0x000000000000541f:  0E                   push  cs
0x0000000000005420:  3E E8 82 B0          call  0x4a6
0x0000000000005424:  39 C6                cmp   si, ax
0x0000000000005426:  75 0D                jne   0x5435
0x0000000000005428:  8D 46 CA             lea   ax, [bp - 0x36]
0x000000000000542b:  8C DA                mov   dx, ds
0x000000000000542d:  0E                   push  cs
0x000000000000542e:  3E E8 9E B0          call  0x4d0
0x0000000000005432:  01 76 F2             add   word ptr [bp - 0xe], si
0x0000000000005435:  8D 46 CA             lea   ax, [bp - 0x36]
0x0000000000005438:  8C DA                mov   dx, ds
0x000000000000543a:  E8 03 F8             call  M_StringWidth_
0x000000000000543d:  BA A0 00             mov   dx, 0xa0
0x0000000000005440:  D1 F8                sar   ax, 1
0x0000000000005442:  8D 5E CA             lea   bx, [bp - 0x36]
0x0000000000005445:  29 C2                sub   dx, ax
0x0000000000005447:  8C D9                mov   cx, ds
0x0000000000005449:  89 D0                mov   ax, dx
0x000000000000544b:  8B 56 F8             mov   dx, word ptr [bp - 8]
0x000000000000544e:  E8 91 F8             call  M_WriteText_
0x0000000000005451:  8B 5E F2             mov   bx, word ptr [bp - 0xe]
0x0000000000005454:  83 46 F8 08          add   word ptr [bp - 8], 8
0x0000000000005458:  80 BF 6C 1F 00       cmp   byte ptr [bx + 0x1f6c], 0
0x000000000000545d:  74 03                je    0x5462
0x000000000000545f:  E9 6A FF             jmp   0x53cc
0x0000000000005462:  80 7E FE 00          cmp   byte ptr [bp - 2], 0
0x0000000000005466:  74 0C                je    0x5474
0x0000000000005468:  9A EE 2D 4F 13       lcall 0x134f:0x2dee
0x000000000000546d:  C9                   LEAVE_MACRO 
0x000000000000546e:  5F                   pop   di
0x000000000000546f:  5E                   pop   si
0x0000000000005470:  5A                   pop   dx
0x0000000000005471:  59                   pop   cx
0x0000000000005472:  5B                   pop   bx
0x0000000000005473:  CB                   retf  
0x0000000000005474:  9A 9C 2B 4F 13       lcall 0x134f:0x2b9c
0x0000000000005479:  C9                   LEAVE_MACRO 
0x000000000000547a:  5F                   pop   di
0x000000000000547b:  5E                   pop   si
0x000000000000547c:  5A                   pop   dx
0x000000000000547d:  59                   pop   cx
0x000000000000547e:  5B                   pop   bx
0x000000000000547f:  CB                   retf  
0x0000000000005480:  9A B0 2D 4F 13       lcall 0x134f:0x2db0
0x0000000000005485:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x0000000000005489:  83 7F 05 00          cmp   word ptr [bx + 5], 0
0x000000000000548d:  74 03                je    0x5492
0x000000000000548f:  FF 57 05             call  word ptr [bx + 5]
0x0000000000005492:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x0000000000005496:  8B 47 07             mov   ax, word ptr [bx + 7]
0x0000000000005499:  89 46 F4             mov   word ptr [bp - 0xc], ax
0x000000000000549c:  8A 47 09             mov   al, byte ptr [bx + 9]
0x000000000000549f:  30 E4                xor   ah, ah
0x00000000000054a1:  89 C6                mov   si, ax
0x00000000000054a3:  8A 07                mov   al, byte ptr [bx]
0x00000000000054a5:  98                   cbw  
0x00000000000054a6:  C7 46 FA 00 00       mov   word ptr [bp - 6], 0
0x00000000000054ab:  89 46 F6             mov   word ptr [bp - 0xa], ax
0x00000000000054ae:  85 C0                test  ax, ax
0x00000000000054b0:  7E 35                jle   0x54e7
0x00000000000054b2:  31 FF                xor   di, di
0x00000000000054b4:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x00000000000054b8:  8B 5F 03             mov   bx, word ptr [bx + 3]
0x00000000000054bb:  01 FB                add   bx, di
0x00000000000054bd:  8A 47 01             mov   al, byte ptr [bx + 1]
0x00000000000054c0:  3C FF                cmp   al, 0xff
0x00000000000054c2:  74 12                je    0x54d6
0x00000000000054c4:  98                   cbw  
0x00000000000054c5:  E8 58 EC             call  M_GetMenuPatch_
0x00000000000054c8:  89 D1                mov   cx, dx
0x00000000000054ca:  89 C3                mov   bx, ax
0x00000000000054cc:  8B 46 F4             mov   ax, word ptr [bp - 0xc]
0x00000000000054cf:  89 F2                mov   dx, si
0x00000000000054d1:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x00000000000054d6:  FF 46 FA             inc   word ptr [bp - 6]
0x00000000000054d9:  83 C6 10             add   si, 0x10
0x00000000000054dc:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x00000000000054df:  83 C7 05             add   di, 5
0x00000000000054e2:  3B 5E F6             cmp   bx, word ptr [bp - 0xa]
0x00000000000054e5:  7C CD                jl    0x54b4
0x00000000000054e7:  BB 4A 0B             mov   bx, 0xb4a
0x00000000000054ea:  8B 1F                mov   bx, word ptr [bx]
0x00000000000054ec:  01 DB                add   bx, bx
0x00000000000054ee:  8B 87 4C 0B          mov   ax, word ptr [bx + 0xb4c]
0x00000000000054f2:  8B 7E F4             mov   di, word ptr [bp - 0xc]
0x00000000000054f5:  E8 28 EC             call  M_GetMenuPatch_
0x00000000000054f8:  8B 1E 0E 1F          mov   bx, word ptr [0x1f0e]
0x00000000000054fc:  83 EF 20             sub   di, 0x20
0x00000000000054ff:  8A 5F 09             mov   bl, byte ptr [bx + 9]
0x0000000000005502:  8B 36 12 1F          mov   si, word ptr [0x1f12]
0x0000000000005506:  30 FF                xor   bh, bh
0x0000000000005508:  C1 E6 04             shl   si, 4
0x000000000000550b:  83 EB 05             sub   bx, 5
0x000000000000550e:  89 D1                mov   cx, dx
0x0000000000005510:  01 DE                add   si, bx
0x0000000000005512:  89 C3                mov   bx, ax
0x0000000000005514:  89 F2                mov   dx, si
0x0000000000005516:  89 F8                mov   ax, di
0x0000000000005518:  9A CC 26 4F 13       call  V_DrawPatchDirect_
0x000000000000551d:  80 7E FE 00          cmp   byte ptr [bp - 2], 0
0x0000000000005521:  75 03                jne   0x5526
0x0000000000005523:  E9 4E FF             jmp   0x5474
0x0000000000005526:  9A EE 2D 4F 13       lcall 0x134f:0x2dee
0x000000000000552b:  C9                   LEAVE_MACRO 
0x000000000000552c:  5F                   pop   di
0x000000000000552d:  5E                   pop   si
0x000000000000552e:  5A                   pop   dx
0x000000000000552f:  59                   pop   cx
0x0000000000005530:  5B                   pop   bx
0x0000000000005531:  CB                   retf  


ENDP

PROC    M_SetupNextMenu_ NEAR
PUBLIC  M_SetupNextMenu_

0x0000000000005532:  53                   push  bx
0x0000000000005533:  89 C3                mov   bx, ax
0x0000000000005535:  8B 5F 0A             mov   bx, word ptr [bx + 0xa]
0x0000000000005538:  A3 0E 1F             mov   word ptr [0x1f0e], ax
0x000000000000553b:  89 1E 12 1F          mov   word ptr [0x1f12], bx
0x000000000000553f:  5B                   pop   bx
0x0000000000005540:  C3                   ret   
0x0000000000005541:  FC                   cld   


ENDP

PROC    M_Ticker_    NEAR
PUBLIC  M_Ticker_

0x0000000000005542:  53                   push  bx
0x0000000000005543:  BB 48 0B             mov   bx, 0xb48
0x0000000000005546:  FF 0F                dec   word ptr [bx]
0x0000000000005548:  83 3F 00             cmp   word ptr [bx], 0
0x000000000000554b:  7E 02                jle   0x554f
0x000000000000554d:  5B                   pop   bx
0x000000000000554e:  C3                   ret   
0x000000000000554f:  BB 4A 0B             mov   bx, 0xb4a
0x0000000000005552:  80 37 01             xor   byte ptr [bx], 1
0x0000000000005555:  BB 48 0B             mov   bx, 0xb48
0x0000000000005558:  C7 07 08 00          mov   word ptr [bx], 8
0x000000000000555c:  5B                   pop   bx
0x000000000000555d:  C3                   ret   
0x000000000000555e:  50                   push  ax
0x000000000000555f:  B8 C0 3C             mov   ax, 0x3cc0
0x0000000000005562:  8E D8                mov   ds, ax
0x0000000000005564:  58                   pop   ax
0x0000000000005565:  CB                   retf  


ENDP


PROC    M_MENU_ENDMARKER_ NEAR
PUBLIC  M_MENU_ENDMARKER_
ENDP


END