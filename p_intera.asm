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


EXTRN EV_DoFloor_:FAR


.DATA




.CODE


PROC    P_INTER_STARTMARKER_ 
PUBLIC  P_INTER_STARTMARKER_
ENDP


;int16_t	maxammo[NUMAMMO] = {200, 50, 300, 50};
;int8_t	clipammo[NUMAMMO] = {10, 4, 20, 1};
_clipammo:
dw 10, 4, 20, 1

_ammo_jump_table:

dw OFFSET give_ammo_case_0, OFFSET give_ammo_case_1, OFFSET give_ammo_case_2, OFFSET give_ammo_case_3


PROC    P_GiveAmmo_  NEAR
PUBLIC  P_GiveAmmo_

;boolean __near P_GiveAmmo (  ammotype_t	ammo, int16_t		num ) ;

push   bx
cbw
cmp    al, AM_NOAMMO
je     exit_giveammo_ret_0

xchg   ax, bx           ; bx holds ammo types
sal    bx, 1  ; hold ammo type * 2  for various lookups

mov    ax, word ptr ds:[bx + _player + PLAYER_T.player_ammo]
cmp    ax, word ptr ds:[bx + _player + PLAYER_T.player_maxammo]
je     exit_giveammo_ret_0 ; have max ammo
mov    ax, word ptr cs:[bx + OFFSET _clipammo]
test   dl, dl
jne    multiply_ammo_by_clipsize

mov    dx, ax
sar    dx, 1
jmp    got_ammo_size

multiply_ammo_by_clipsize:
mul    dl
xchg   ax, dx
got_ammo_size:
mov    al, byte ptr ds:[_gameskill]
test   al, al  ; SK_BABY
je     give_double_ammo

cmp    al, SK_NIGHTMARE
jne    give_normal_ammo

give_double_ammo:
sal    dx, 1
give_normal_ammo:

; ax is old ammo.

mov    ax, word ptr ds:[bx + _player + PLAYER_T.player_ammo]
add    dx, ax
mov    word ptr ds:[bx + _player + PLAYER_T.player_ammo], dx
cmp    dx, word ptr ds:[bx + _player + PLAYER_T.player_maxammo]
jle    dont_cap_ammo
mov    dx, word ptr ds:[bx + _player + PLAYER_T.player_maxammo]
mov    word ptr ds:[bx + _player + PLAYER_T.player_ammo], dx
dont_cap_ammo:

;    // If non zero ammo, 
;    // don't change up weapons,
;    // player was lower on purpose.

test   ax, ax
jne    exit_giveammo_ret_1
; check for adding weapons, changing weapons...
mov    al, byte ptr ds:[_player + PLAYER_T.player_readyweapon]
jmp    word ptr cs:[bx + OFFSET _ammo_jump_table]

exit_giveammo_ret_0:
xor    ax, ax
pop    bx
ret    


give_ammo_case_0:
cmp    al, 0
jne    exit_giveammo_ret_1
cmp    byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_CHAINGUN], 0
je     switch_to_pistol
mov    byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_CHAINGUN
exit_giveammo_ret_1:
mov    al, 1
exit_giveammo:
pop    bx
ret    


switch_to_pistol:

mov    al, WP_PISTOL ; 1
mov    byte ptr ds:[_player + PLAYER_T.player_readyweapon], al
pop    bx
ret    

give_ammo_case_1:

test   al, al
je     check_for_switch_to_shotgun

cmp    al, 1
jne    exit_giveammo_ret_1

check_for_switch_to_shotgun:

cmp    byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_SHOTGUN], 0
je     exit_giveammo_ret_1
mov    byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_SHOTGUN
mov    al, 1
pop    bx
ret    
give_ammo_case_2:

test   al, al
je    check_for_switch_to_plasma
cmp    al, 1
jne    exit_giveammo_ret_1
check_for_switch_to_plasma:
cmp    byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_PLASMA], 0
je     exit_giveammo_ret_1
mov    byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_PLASMA
mov    al, 1
pop    bx
ret    
give_ammo_case_3:
cmp    al, 0
jne    exit_giveammo_ret_1

cmp    byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_MISSILE], 0
je     exit_giveammo_ret_1

mov    byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_MISSILE
mov    al, 1
pop    bx
ret    

ENDP


PROC    P_GiveWeapon_ NEAR
PUBLIC  P_GiveWeapon_

;boolean __near P_GiveWeapon (  weapontype_t	weapon, boolean	dropped ) {


push   bx
cbw   ; clear ah for later.
xchg   ax, bx
mov    al, SIZEOF_WEAPONINFO_T
mul    bl
xchg   ax, bx
; al has weapontype again
mov    dh, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
cmp    dh, AM_NOAMMO
jne    do_give_ammo
xchg   ax, bx  ; bx has weapontype.
; fall thru with implied giveammo = false.
no_ammo_actually_given:
cmp    byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned], 0
je     add_weapon
xor    ax, ax
pop    bx
ret    


do_give_ammo:

xchg   ax, bx  ; bx has weapontype.
mov    al, dh
test   dl, dl   
jne    weapon_is_drop
mov    dl, 2

weapon_is_drop:   ; dl should have been 1.
call_giveammo:
call   P_GiveAmmo_
; al = given ammo

test   al, al
jz     no_ammo_actually_given

dont_give_ammo:
; bx has weapontype.
cmp    byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned], 0
jne    dont_add_weapon

add_weapon:
mov    byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned], 1
mov    byte ptr ds:[_player + PLAYER_T.player_pendingweapon], bl

dont_add_weapon:
mov    al, 1
pop    bx
ret    

ENDP



PROC    P_GiveBody_  NEAR
PUBLIC  P_GiveBody_

push   bx
mov    bx, _player + PLAYER_T.player_health
cmp    word ptr ds:[bx], 100
jge    exit_pgivebody_return_0
add    word ptr ds:[bx], ax
cmp    word ptr ds:[bx], 100
jle    dont_cap_health
mov    ax, 100
mov    word ptr ds:[bx], ax

dont_cap_health:
mov    bx, word ptr ds:[_playerMobj]
mov    word ptr ds:[bx + MOBJ_T.m_health], ax
mov    al, 1
pop    bx
ret    
exit_pgivebody_return_0:
xor    al, al
pop    bx
ret    
ENDP

COMMENT @


PROC    P_GiveArmor_  NEAR
PUBLIC  P_GiveArmor_

0x0000000000003276:  53                      push   bx
0x0000000000003277:  52                      push   dx
0x0000000000003278:  6B D0 64                imul   dx, ax, 0x64
0x000000000000327b:  BB EA 07                mov    bx, _player + PLAYER_T.player_armorpoints
0x000000000000327e:  3B 17                   cmp    dx, word ptr ds:[bx]
0x0000000000003280:  7F 05                   jg     0x3287
0x0000000000003282:  30 C0                   xor    al, al
0x0000000000003284:  5A                      pop    dx
0x0000000000003285:  5B                      pop    bx
0x0000000000003286:  C3                      ret    
0x0000000000003287:  BB EC 07                mov    bx, _player + PLAYER_T.player_armortype
0x000000000000328a:  88 07                   mov    byte ptr ds:[bx], al
0x000000000000328c:  BB EA 07                mov    bx, _player + PLAYER_T.player_armorpoints
0x000000000000328f:  B0 01                   mov    al, 1
0x0000000000003291:  89 17                   mov    word ptr ds:[bx], dx
0x0000000000003293:  5A                      pop    dx
0x0000000000003294:  5B                      pop    bx
0x0000000000003295:  C3                      ret    
ENDP



PROC    P_GiveCard_  NEAR
PUBLIC  P_GiveCard_

0x0000000000003296:  53                      push   bx
0x0000000000003297:  56                      push   si
0x0000000000003298:  88 C3                   mov    bl, al
0x000000000000329a:  30 FF                   xor    bh, bh
0x000000000000329c:  80 BF FA 07 00          cmp    byte ptr ds:[bx + 0x7fa], 0
0x00000000000032a1:  74 03                   je     0x32a6
0x00000000000032a3:  5E                      pop    si
0x00000000000032a4:  5B                      pop    bx
0x00000000000032a5:  C3                      ret    
0x00000000000032a6:  BE 2A 08                mov    si, 0x82a
0x00000000000032a9:  C6 04 06                mov    byte ptr ds:[si], 6
0x00000000000032ac:  C6 87 FA 07 01          mov    byte ptr ds:[bx + 0x7fa], 1
0x00000000000032b1:  5E                      pop    si
0x00000000000032b2:  5B                      pop    bx
0x00000000000032b3:  C3                      ret    
ENDP



PROC    P_GivePower_  NEAR
PUBLIC  P_GivePower_

0x00000000000032b4:  53                      push   bx
0x00000000000032b5:  56                      push   si
0x00000000000032b6:  89 C3                   mov    bx, ax
0x00000000000032b8:  01 C3                   add    bx, ax
0x00000000000032ba:  85 C0                   test   ax, ax
0x00000000000032bc:  74 20                   je     0x32de
0x00000000000032be:  3D 02 00                cmp    ax, 2
0x00000000000032c1:  74 26                   je     0x32e9
0x00000000000032c3:  3D 05 00                cmp    ax, 5
0x00000000000032c6:  74 36                   je     0x32fe
0x00000000000032c8:  3D 03 00                cmp    ax, 3
0x00000000000032cb:  74 3C                   je     0x3309
0x00000000000032cd:  3D 01 00                cmp    ax, 1
0x00000000000032d0:  74 42                   je     0x3314
0x00000000000032d2:  83 BF EE 07 00          cmp    word ptr ds:[bx + 0x7ee], 0
0x00000000000032d7:  74 41                   je     0x331a
0x00000000000032d9:  30 C0                   xor    al, al
0x00000000000032db:  5E                      pop    si
0x00000000000032dc:  5B                      pop    bx
0x00000000000032dd:  CB                      retf   
0x00000000000032de:  B0 01                   mov    al, 1
0x00000000000032e0:  C7 87 EE 07 1A 04       mov    word ptr ds:[bx + 0x7ee], 0x41a
0x00000000000032e6:  5E                      pop    si
0x00000000000032e7:  5B                      pop    bx
0x00000000000032e8:  CB                      retf   
0x00000000000032e9:  C7 87 EE 07 34 08       mov    word ptr ds:[bx + 0x7ee], 0x834
0x00000000000032ef:  BB 30 07                mov    bx, 0x730
0x00000000000032f2:  C4 37                   les    si, ptr ds:[bx]
0x00000000000032f4:  B0 01                   mov    al, 1
0x00000000000032f6:  26 80 4C 16 04          or     byte ptr es:[si + 0x16], 4
0x00000000000032fb:  5E                      pop    si
0x00000000000032fc:  5B                      pop    bx
0x00000000000032fd:  CB                      retf   
0x00000000000032fe:  B0 01                   mov    al, 1
0x0000000000003300:  C7 87 EE 07 68 10       mov    word ptr ds:[bx + 0x7ee], 0x1068
0x0000000000003306:  5E                      pop    si
0x0000000000003307:  5B                      pop    bx
0x0000000000003308:  CB                      retf   
0x0000000000003309:  B0 01                   mov    al, 1
0x000000000000330b:  C7 87 EE 07 34 08       mov    word ptr ds:[bx + 0x7ee], 0x834
0x0000000000003311:  5E                      pop    si
0x0000000000003312:  5B                      pop    bx
0x0000000000003313:  CB                      retf   
0x0000000000003314:  B8 64 00                mov    ax, 0x64
0x0000000000003317:  E8 30 FF                call   P_GiveBody_
0x000000000000331a:  B0 01                   mov    al, 1
0x000000000000331c:  C7 87 EE 07 01 00       mov    word ptr ds:[bx + 0x7ee], 1
0x0000000000003322:  5E                      pop    si
0x0000000000003323:  5B                      pop    bx
0x0000000000003324:  CB                      retf   
; table

0x0000000000003326:  08 34                   or     byte ptr ds:[si], dh
0x0000000000003328:  4C                      dec    sp
0x0000000000003329:  34 19                   xor    al, 0x19
0x000000000000332b:  34 19                   xor    al, 0x19
0x000000000000332d:  34 19                   xor    al, 0x19
0x000000000000332f:  34 5F                   xor    al, 0x5f
0x0000000000003331:  34 86                   xor    al, 0x86
0x0000000000003333:  34 07                   xor    al, 7
0x0000000000003335:  35 34 35                xor    ax, 0x3534
0x0000000000003338:  1E                      push   ds
0x0000000000003339:  35 4C 35                xor    ax, 0x354c
0x000000000000333c:  7C 35                   jl     0x3373
0x000000000000333e:  64 35 94 35             xor    ax, 0x3594
0x0000000000003342:  AB                      stosw  word ptr es:[di], ax
0x0000000000003343:  35 AC 34                xor    ax, 0x34ac
0x0000000000003346:  BF 35 D6                mov    di, 0xd635
0x0000000000003349:  35 01 36                xor    ax, 0x3601
0x000000000000334c:  D8 34                   fdiv   dword ptr ds:[si]
0x000000000000334e:  19 36 34 36             sbb    word ptr ds:[0x3634], si
0x0000000000003352:  4C                      dec    sp
0x0000000000003353:  36 64 36 84 36 9A 36    test   byte ptr ss:[0x369a], dh
0x000000000000335a:  B4 36                   mov    ah, 0x36
0x000000000000335c:  CB                      retf   
0x000000000000335d:  36 E2 36                loop   0x3396
0x0000000000003360:  F9                      stc    
0x0000000000003361:  36 0F 37                getsec 
0x0000000000003364:  26 37                   aaa    
0x0000000000003366:  65 37                   aaa    
0x0000000000003368:  81 37 9B 37             xor    word ptr ds:[bx], 0x379b
0x000000000000336c:  B4 37                   mov    ah, 0x37
0x000000000000336e:  CD 37                   int    0x37
0x0000000000003370:  E6 37                   out    0x37, al
0x0000000000003372:  03 38                   add    di, word ptr ds:[bx + si]
ENDP



PROC    P_TouchSpecialThing_  NEAR
PUBLIC  P_TouchSpecialThing_

0x0000000000003374:  56                      push   si
0x0000000000003375:  57                      push   di
0x0000000000003376:  55                      push   bp
0x0000000000003377:  89 E5                   mov    bp, sp
0x0000000000003379:  83 EC 06                sub    sp, 6
0x000000000000337c:  50                      push   ax
0x000000000000337d:  89 D7                   mov    di, dx
0x000000000000337f:  89 CA                   mov    dx, cx
0x0000000000003381:  8E C1                   mov    es, cx
0x0000000000003383:  26 8B 47 0A             mov    ax, word ptr es:[bx + 0xa]
0x0000000000003387:  89 46 FA                mov    word ptr [bp - 6], ax
0x000000000000338a:  26 8B 47 12             mov    ax, word ptr es:[bx + 0x12]
0x000000000000338e:  89 C6                   mov    si, ax
0x0000000000003390:  C1 E6 02                shl    si, 2
0x0000000000003393:  26 8B 4F 08             mov    cx, word ptr es:[bx + 8]
0x0000000000003397:  29 C6                   sub    si, ax
0x0000000000003399:  B8 74 7D                mov    ax, 0x7d74
0x000000000000339c:  01 F6                   add    si, si
0x000000000000339e:  8E C0                   mov    es, ax
0x00000000000033a0:  26 8A 04                mov    al, byte ptr es:[si]
0x00000000000033a3:  8E C2                   mov    es, dx
0x00000000000033a5:  88 46 FE                mov    byte ptr [bp - 2], al
0x00000000000033a8:  26 F6 47 16 02          test   byte ptr es:[bx + 0x16], 2
0x00000000000033ad:  74 55                   je     0x3404
0x00000000000033af:  B8 01 00                mov    ax, 1
0x00000000000033b2:  8E C2                   mov    es, dx
0x00000000000033b4:  26 F6 47 16 80          test   byte ptr es:[bx + 0x16], 0x80
0x00000000000033b9:  74 4B                   je     0x3406
0x00000000000033bb:  BA 01 00                mov    dx, 1
0x00000000000033be:  C4 5E 0A                les    bx, ptr [bp + 0xa]
0x00000000000033c1:  88 56 FC                mov    byte ptr [bp - 4], dl
0x00000000000033c4:  89 CA                   mov    dx, cx
0x00000000000033c6:  8B 76 0A                mov    si, word ptr [bp + 0xa]
0x00000000000033c9:  26 2B 57 08             sub    dx, word ptr es:[bx + 8]
0x00000000000033cd:  8B 5E FA                mov    bx, word ptr [bp - 6]
0x00000000000033d0:  26 1B 5C 0A             sbb    bx, word ptr es:[si + 0xa]
0x00000000000033d4:  3B 5D 0C                cmp    bx, word ptr ds:[di + 0xc]
0x00000000000033d7:  7F 63                   jg     0x343c
0x00000000000033d9:  75 05                   jne    0x33e0
0x00000000000033db:  3B 55 0A                cmp    dx, word ptr ds:[di + 0xa]
0x00000000000033de:  77 5C                   ja     0x343c
0x00000000000033e0:  83 FB F8                cmp    bx, -8
0x00000000000033e3:  7C 57                   jl     0x343c
0x00000000000033e5:  B9 20 00                mov    cx, 0x20
0x00000000000033e8:  83 7D 1C 00             cmp    word ptr ds:[di + MOBJ_T.m_health], 0
0x00000000000033ec:  7E 4E                   jle    0x343c
0x00000000000033ee:  8A 56 FE                mov    dl, byte ptr [bp - 2]
0x00000000000033f1:  80 EA 37                sub    dl, 0x37
0x00000000000033f4:  80 FA 26                cmp    dl, 0x26
0x00000000000033f7:  77 20                   ja     0x3419
0x00000000000033f9:  30 F6                   xor    dh, dh
0x00000000000033fb:  89 D3                   mov    bx, dx
0x00000000000033fd:  01 D3                   add    bx, dx
0x00000000000033ff:  2E FF A7 26 33          jmp    word ptr cs:[bx + 0x3326]
0x0000000000003404:  EB 3C                   jmp    0x3442
0x0000000000003406:  EB 3F                   jmp    0x3447
0x0000000000003408:  B8 01 00                mov    ax, 1
0x000000000000340b:  E8 68 FE                call   P_GiveArmor_
0x000000000000340e:  84 C0                   test   al, al
0x0000000000003410:  74 2A                   je     0x343c
0x0000000000003412:  BB 24 08                mov    bx, 0x824
0x0000000000003415:  C7 07 18 00             mov    word ptr ds:[bx], 0x18
0x0000000000003419:  80 7E FC 00             cmp    byte ptr [bp - 4], 0
0x000000000000341d:  74 05                   je     0x3424
0x000000000000341f:  BB 20 08                mov    bx, 0x820
0x0000000000003422:  FF 07                   inc    word ptr ds:[bx]
0x0000000000003424:  8B 46 F8                mov    ax, word ptr [bp - 8]
0x0000000000003427:  BB 2A 08                mov    bx, 0x82a
0x000000000000342a:  88 CA                   mov    dl, cl
0x000000000000342c:  FF 1E 6C 0F             lcall  [0xf6c]
0x0000000000003430:  30 F6                   xor    dh, dh
0x0000000000003432:  31 C0                   xor    ax, ax
0x0000000000003434:  80 07 06                add    byte ptr ds:[bx], 6
0x0000000000003437:  0E                      push   cs
0x0000000000003438:  3E E8 14 D1             call   0x550
0x000000000000343c:  C9                      LEAVE_MACRO  
0x000000000000343d:  5F                      pop    di
0x000000000000343e:  5E                      pop    si
0x000000000000343f:  CA 04 00                retf   4
0x0000000000003442:  31 C0                   xor    ax, ax
0x0000000000003444:  E9 6B FF                jmp    0x33b2
0x0000000000003447:  31 D2                   xor    dx, dx
0x0000000000003449:  E9 72 FF                jmp    0x33be
0x000000000000344c:  B8 02 00                mov    ax, 2
0x000000000000344f:  E8 24 FE                call   P_GiveArmor_
0x0000000000003452:  84 C0                   test   al, al
0x0000000000003454:  74 E6                   je     0x343c
0x0000000000003456:  BB 24 08                mov    bx, 0x824
0x0000000000003459:  C7 07 19 00             mov    word ptr ds:[bx], 0x19
0x000000000000345d:  EB BA                   jmp    0x3419
0x000000000000345f:  BB E8 07                mov    bx, _player + PLAYER_T.player_health
0x0000000000003462:  FF 07                   inc    word ptr ds:[bx]
0x0000000000003464:  81 3F C8 00             cmp    word ptr ds:[bx], 0xc8
0x0000000000003468:  7F 16                   jg     0x3480
0x000000000000346a:  BB EC 06                mov    bx, 0x6ec
0x000000000000346d:  BE E8 07                mov    si, _player + PLAYER_T.player_health
0x0000000000003470:  8B 1F                   mov    bx, word ptr ds:[bx]
0x0000000000003472:  8B 04                   mov    ax, word ptr ds:[si]
0x0000000000003474:  89 47 1C                mov    word ptr ds:[bx + MOBJ_T.m_health], ax
0x0000000000003477:  BB 24 08                mov    bx, 0x824
0x000000000000347a:  C7 07 1A 00             mov    word ptr ds:[bx], 0x1a
0x000000000000347e:  EB 99                   jmp    0x3419
0x0000000000003480:  C7 07 C8 00             mov    word ptr ds:[bx], 0xc8
0x0000000000003484:  EB E4                   jmp    0x346a
0x0000000000003486:  BB EA 07                mov    bx, _player + PLAYER_T.player_armorpoints
0x0000000000003489:  FF 07                   inc    word ptr ds:[bx]
0x000000000000348b:  81 3F C8 00             cmp    word ptr ds:[bx], 0xc8
0x000000000000348f:  7F 15                   jg     0x34a6
0x0000000000003491:  BB EC 07                mov    bx, _player + PLAYER_T.player_armortype
0x0000000000003494:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x0000000000003497:  75 03                   jne    0x349c
0x0000000000003499:  C6 07 01                mov    byte ptr ds:[bx], 1
0x000000000000349c:  BB 24 08                mov    bx, 0x824
0x000000000000349f:  C7 07 1B 00             mov    word ptr ds:[bx], 0x1b
0x00000000000034a3:  E9 73 FF                jmp    0x3419
0x00000000000034a6:  C7 07 C8 00             mov    word ptr ds:[bx], 0xc8
0x00000000000034aa:  EB E5                   jmp    0x3491
0x00000000000034ac:  BB E8 07                mov    bx, _player + PLAYER_T.player_health
0x00000000000034af:  83 07 64                add    word ptr ds:[bx], 0x64
0x00000000000034b2:  81 3F C8 00             cmp    word ptr ds:[bx], 0xc8
0x00000000000034b6:  7F 1A                   jg     0x34d2
0x00000000000034b8:  BB EC 06                mov    bx, 0x6ec
0x00000000000034bb:  BE E8 07                mov    si, _player + PLAYER_T.player_health
0x00000000000034be:  8B 1F                   mov    bx, word ptr ds:[bx]
0x00000000000034c0:  8B 04                   mov    ax, word ptr ds:[si]
0x00000000000034c2:  89 47 1C                mov    word ptr ds:[bx + MOBJ_T.m_health], ax
0x00000000000034c5:  BB 24 08                mov    bx, 0x824
0x00000000000034c8:  B9 5D 00                mov    cx, 0x5d
0x00000000000034cb:  C7 07 1E 00             mov    word ptr ds:[bx], 0x1e
0x00000000000034cf:  E9 47 FF                jmp    0x3419
0x00000000000034d2:  C7 07 C8 00             mov    word ptr ds:[bx], 0xc8
0x00000000000034d6:  EB E0                   jmp    0x34b8
0x00000000000034d8:  BB EB 02                mov    bx, 0x2eb
0x00000000000034db:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x00000000000034de:  75 03                   jne    0x34e3
0x00000000000034e0:  E9 59 FF                jmp    0x343c
0x00000000000034e3:  BB E8 07                mov    bx, _player + PLAYER_T.player_health
0x00000000000034e6:  BE EC 06                mov    si, 0x6ec
0x00000000000034e9:  C7 07 C8 00             mov    word ptr ds:[bx], 0xc8
0x00000000000034ed:  8B 34                   mov    si, word ptr ds:[si]
0x00000000000034ef:  8B 07                   mov    ax, word ptr ds:[bx]
0x00000000000034f1:  BB 24 08                mov    bx, 0x824
0x00000000000034f4:  89 44 1C                mov    word ptr ds:[si + MOBJ_T.m_health], ax
0x00000000000034f7:  B8 02 00                mov    ax, 2
0x00000000000034fa:  B9 5D 00                mov    cx, 0x5d
0x00000000000034fd:  E8 76 FD                call   P_GiveArmor_
0x0000000000003500:  C7 07 2B 00             mov    word ptr ds:[bx], 0x2b
0x0000000000003504:  E9 12 FF                jmp    0x3419
0x0000000000003507:  BB FA 07                mov    bx, 0x7fa
0x000000000000350a:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x000000000000350d:  75 07                   jne    0x3516
0x000000000000350f:  BB 24 08                mov    bx, 0x824
0x0000000000003512:  C7 07 1F 00             mov    word ptr ds:[bx], 0x1f
0x0000000000003516:  31 C0                   xor    ax, ax
0x0000000000003518:  E8 7B FD                call   P_GiveCard_
0x000000000000351b:  E9 FB FE                jmp    0x3419
0x000000000000351e:  BB FB 07                mov    bx, 0x7fb
0x0000000000003521:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x0000000000003524:  75 05                   jne    0x352b
0x0000000000003526:  BB 24 08                mov    bx, 0x824
0x0000000000003529:  89 0F                   mov    word ptr ds:[bx], cx
0x000000000000352b:  B8 01 00                mov    ax, 1
0x000000000000352e:  E8 65 FD                call   P_GiveCard_
0x0000000000003531:  E9 E5 FE                jmp    0x3419
0x0000000000003534:  BB FC 07                mov    bx, 0x7fc
0x0000000000003537:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x000000000000353a:  75 07                   jne    0x3543
0x000000000000353c:  BB 24 08                mov    bx, 0x824
0x000000000000353f:  C7 07 21 00             mov    word ptr ds:[bx], 0x21
0x0000000000003543:  B8 02 00                mov    ax, 2
0x0000000000003546:  E8 4D FD                call   P_GiveCard_
0x0000000000003549:  E9 CD FE                jmp    0x3419
0x000000000000354c:  BB FD 07                mov    bx, 0x7fd
0x000000000000354f:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x0000000000003552:  75 07                   jne    0x355b
0x0000000000003554:  BB 24 08                mov    bx, 0x824
0x0000000000003557:  C7 07 22 00             mov    word ptr ds:[bx], 0x22
0x000000000000355b:  B8 03 00                mov    ax, 3
0x000000000000355e:  E8 35 FD                call   P_GiveCard_
0x0000000000003561:  E9 B5 FE                jmp    0x3419
0x0000000000003564:  BB FE 07                mov    bx, 0x7fe
0x0000000000003567:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x000000000000356a:  75 07                   jne    0x3573
0x000000000000356c:  BB 24 08                mov    bx, 0x824
0x000000000000356f:  C7 07 23 00             mov    word ptr ds:[bx], 0x23
0x0000000000003573:  B8 04 00                mov    ax, 4
0x0000000000003576:  E8 1D FD                call   P_GiveCard_
0x0000000000003579:  E9 9D FE                jmp    0x3419
0x000000000000357c:  BB FF 07                mov    bx, 0x7ff
0x000000000000357f:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x0000000000003582:  75 07                   jne    0x358b
0x0000000000003584:  BB 24 08                mov    bx, 0x824
0x0000000000003587:  C7 07 24 00             mov    word ptr ds:[bx], 0x24
0x000000000000358b:  B8 05 00                mov    ax, 5
0x000000000000358e:  E8 05 FD                call   P_GiveCard_
0x0000000000003591:  E9 85 FE                jmp    0x3419
0x0000000000003594:  B8 0A 00                mov    ax, 0xa
0x0000000000003597:  E8 B0 FC                call   P_GiveBody_
0x000000000000359a:  84 C0                   test   al, al
0x000000000000359c:  75 03                   jne    0x35a1
0x000000000000359e:  E9 9B FE                jmp    0x343c
0x00000000000035a1:  BB 24 08                mov    bx, 0x824
0x00000000000035a4:  C7 07 1C 00             mov    word ptr ds:[bx], 0x1c
0x00000000000035a8:  E9 6E FE                jmp    0x3419
0x00000000000035ab:  B8 19 00                mov    ax, 0x19
0x00000000000035ae:  E8 99 FC                call   P_GiveBody_
0x00000000000035b1:  84 C0                   test   al, al
0x00000000000035b3:  74 E9                   je     0x359e
0x00000000000035b5:  BB 24 08                mov    bx, 0x824
0x00000000000035b8:  C7 07 1D 00             mov    word ptr ds:[bx], 0x1d
0x00000000000035bc:  E9 5A FE                jmp    0x3419
0x00000000000035bf:  31 C0                   xor    ax, ax
0x00000000000035c1:  0E                      push   cs
0x00000000000035c2:  E8 EF FC                call   P_GivePower_
0x00000000000035c5:  84 C0                   test   al, al
0x00000000000035c7:  74 D5                   je     0x359e
0x00000000000035c9:  BB 24 08                mov    bx, 0x824
0x00000000000035cc:  B9 5D 00                mov    cx, 0x5d
0x00000000000035cf:  C7 07 25 00             mov    word ptr ds:[bx], 0x25
0x00000000000035d3:  E9 43 FE                jmp    0x3419
0x00000000000035d6:  B8 01 00                mov    ax, 1
0x00000000000035d9:  0E                      push   cs
0x00000000000035da:  E8 D7 FC                call   P_GivePower_
0x00000000000035dd:  84 C0                   test   al, al
0x00000000000035df:  74 BD                   je     0x359e
0x00000000000035e1:  BB 24 08                mov    bx, 0x824
0x00000000000035e4:  C7 07 26 00             mov    word ptr ds:[bx], 0x26
0x00000000000035e8:  BB 00 08                mov    bx, _player + PLAYER_T.player_readyweapon
0x00000000000035eb:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x00000000000035ee:  75 06                   jne    0x35f6
0x00000000000035f0:  B9 5D 00                mov    cx, 0x5d
0x00000000000035f3:  E9 23 FE                jmp    0x3419
0x00000000000035f6:  BB 01 08                mov    bx, _player + PLAYER_T.player_pendingweapon
0x00000000000035f9:  88 37                   mov    byte ptr ds:[bx], dh
0x00000000000035fb:  B9 5D 00                mov    cx, 0x5d
0x00000000000035fe:  E9 18 FE                jmp    0x3419
0x0000000000003601:  B8 02 00                mov    ax, 2
0x0000000000003604:  0E                      push   cs
0x0000000000003605:  E8 AC FC                call   P_GivePower_
0x0000000000003608:  84 C0                   test   al, al
0x000000000000360a:  74 92                   je     0x359e
0x000000000000360c:  BB 24 08                mov    bx, 0x824
0x000000000000360f:  B9 5D 00                mov    cx, 0x5d
0x0000000000003612:  C7 07 27 00             mov    word ptr ds:[bx], 0x27
0x0000000000003616:  E9 00 FE                jmp    0x3419
0x0000000000003619:  B8 03 00                mov    ax, 3
0x000000000000361c:  0E                      push   cs
0x000000000000361d:  E8 94 FC                call   P_GivePower_
0x0000000000003620:  84 C0                   test   al, al
0x0000000000003622:  75 03                   jne    0x3627
0x0000000000003624:  E9 15 FE                jmp    0x343c
0x0000000000003627:  BB 24 08                mov    bx, 0x824
0x000000000000362a:  B9 5D 00                mov    cx, 0x5d
0x000000000000362d:  C7 07 28 00             mov    word ptr ds:[bx], 0x28
0x0000000000003631:  E9 E5 FD                jmp    0x3419
0x0000000000003634:  B8 04 00                mov    ax, 4
0x0000000000003637:  0E                      push   cs
0x0000000000003638:  E8 79 FC                call   P_GivePower_
0x000000000000363b:  84 C0                   test   al, al
0x000000000000363d:  74 E5                   je     0x3624
0x000000000000363f:  BB 24 08                mov    bx, 0x824
0x0000000000003642:  B9 5D 00                mov    cx, 0x5d
0x0000000000003645:  C7 07 29 00             mov    word ptr ds:[bx], 0x29
0x0000000000003649:  E9 CD FD                jmp    0x3419
0x000000000000364c:  B8 05 00                mov    ax, 5
0x000000000000364f:  0E                      push   cs
0x0000000000003650:  E8 61 FC                call   P_GivePower_
0x0000000000003653:  84 C0                   test   al, al
0x0000000000003655:  74 CD                   je     0x3624
0x0000000000003657:  BB 24 08                mov    bx, 0x824
0x000000000000365a:  B9 5D 00                mov    cx, 0x5d
0x000000000000365d:  C7 07 2A 00             mov    word ptr ds:[bx], 0x2a
0x0000000000003661:  E9 B5 FD                jmp    0x3419
0x0000000000003664:  84 C0                   test   al, al
0x0000000000003666:  74 15                   je     0x367d
0x0000000000003668:  30 D2                   xor    dl, dl
0x000000000000366a:  31 C0                   xor    ax, ax
0x000000000000366c:  E8 69 FA                call   P_GiveAmmo_
0x000000000000366f:  84 C0                   test   al, al
0x0000000000003671:  74 B1                   je     0x3624
0x0000000000003673:  BB 24 08                mov    bx, 0x824
0x0000000000003676:  C7 07 2C 00             mov    word ptr ds:[bx], 0x2c
0x000000000000367a:  E9 9C FD                jmp    0x3419
0x000000000000367d:  BA 01 00                mov    dx, 1
0x0000000000003680:  30 E4                   xor    ah, ah
0x0000000000003682:  EB E8                   jmp    0x366c
0x0000000000003684:  BA 05 00                mov    dx, 5
0x0000000000003687:  31 C0                   xor    ax, ax
0x0000000000003689:  E8 4C FA                call   P_GiveAmmo_
0x000000000000368c:  84 C0                   test   al, al
0x000000000000368e:  74 94                   je     0x3624
0x0000000000003690:  BB 24 08                mov    bx, 0x824
0x0000000000003693:  C7 07 2D 00             mov    word ptr ds:[bx], 0x2d
0x0000000000003697:  E9 7F FD                jmp    0x3419
0x000000000000369a:  BA 01 00                mov    dx, 1
0x000000000000369d:  B8 03 00                mov    ax, 3
0x00000000000036a0:  E8 35 FA                call   P_GiveAmmo_
0x00000000000036a3:  84 C0                   test   al, al
0x00000000000036a5:  75 03                   jne    0x36aa
0x00000000000036a7:  E9 92 FD                jmp    0x343c
0x00000000000036aa:  BB 24 08                mov    bx, 0x824
0x00000000000036ad:  C7 07 2E 00             mov    word ptr ds:[bx], 0x2e
0x00000000000036b1:  E9 65 FD                jmp    0x3419
0x00000000000036b4:  BA 05 00                mov    dx, 5
0x00000000000036b7:  B8 03 00                mov    ax, 3
0x00000000000036ba:  E8 1B FA                call   P_GiveAmmo_
0x00000000000036bd:  84 C0                   test   al, al
0x00000000000036bf:  74 E6                   je     0x36a7
0x00000000000036c1:  BB 24 08                mov    bx, 0x824
0x00000000000036c4:  C7 07 2F 00             mov    word ptr ds:[bx], 0x2f
0x00000000000036c8:  E9 4E FD                jmp    0x3419
0x00000000000036cb:  BA 01 00                mov    dx, 1
0x00000000000036ce:  B8 02 00                mov    ax, 2
0x00000000000036d1:  E8 04 FA                call   P_GiveAmmo_
0x00000000000036d4:  84 C0                   test   al, al
0x00000000000036d6:  74 CF                   je     0x36a7
0x00000000000036d8:  BB 24 08                mov    bx, 0x824
0x00000000000036db:  C7 07 30 00             mov    word ptr ds:[bx], 0x30
0x00000000000036df:  E9 37 FD                jmp    0x3419
0x00000000000036e2:  BA 05 00                mov    dx, 5
0x00000000000036e5:  B8 02 00                mov    ax, 2
0x00000000000036e8:  E8 ED F9                call   P_GiveAmmo_
0x00000000000036eb:  84 C0                   test   al, al
0x00000000000036ed:  74 B8                   je     0x36a7
0x00000000000036ef:  BB 24 08                mov    bx, 0x824
0x00000000000036f2:  C7 07 31 00             mov    word ptr ds:[bx], 0x31
0x00000000000036f6:  E9 20 FD                jmp    0x3419
0x00000000000036f9:  BA 01 00                mov    dx, 1
0x00000000000036fc:  89 D0                   mov    ax, dx
0x00000000000036fe:  E8 D7 F9                call   P_GiveAmmo_
0x0000000000003701:  84 C0                   test   al, al
0x0000000000003703:  74 A2                   je     0x36a7
0x0000000000003705:  BB 24 08                mov    bx, 0x824
0x0000000000003708:  C7 07 32 00             mov    word ptr ds:[bx], 0x32
0x000000000000370c:  E9 0A FD                jmp    0x3419
0x000000000000370f:  BA 05 00                mov    dx, 5
0x0000000000003712:  B8 01 00                mov    ax, 1
0x0000000000003715:  E8 C0 F9                call   P_GiveAmmo_
0x0000000000003718:  84 C0                   test   al, al
0x000000000000371a:  74 8B                   je     0x36a7
0x000000000000371c:  BB 24 08                mov    bx, 0x824
0x000000000000371f:  C7 07 33 00             mov    word ptr ds:[bx], 0x33
0x0000000000003723:  E9 F3 FC                jmp    0x3419
0x0000000000003726:  BB 32 08                mov    bx, 0x832
0x0000000000003729:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x000000000000372c:  75 1A                   jne    0x3748
0x000000000000372e:  30 D2                   xor    dl, dl
0x0000000000003730:  88 D0                   mov    al, dl
0x0000000000003732:  98                      cbw   
0x0000000000003733:  89 C3                   mov    bx, ax
0x0000000000003735:  01 C3                   add    bx, ax
0x0000000000003737:  FE C2                   inc    dl
0x0000000000003739:  D1 A7 14 08             shl    word ptr ds:[bx + _player + PLAYER_T.player_maxammo], 1
0x000000000000373d:  80 FA 04                cmp    dl, 4
0x0000000000003740:  7C EE                   jl     0x3730
0x0000000000003742:  BB 32 08                mov    bx, 0x832
0x0000000000003745:  C6 07 01                mov    byte ptr ds:[bx], 1
0x0000000000003748:  30 DB                   xor    bl, bl
0x000000000000374a:  88 D8                   mov    al, bl
0x000000000000374c:  BA 01 00                mov    dx, 1
0x000000000000374f:  30 E4                   xor    ah, ah
0x0000000000003751:  FE C3                   inc    bl
0x0000000000003753:  E8 82 F9                call   P_GiveAmmo_
0x0000000000003756:  80 FB 04                cmp    bl, 4
0x0000000000003759:  7C EF                   jl     0x374a
0x000000000000375b:  BB 24 08                mov    bx, 0x824
0x000000000000375e:  C7 07 34 00             mov    word ptr ds:[bx], 0x34
0x0000000000003762:  E9 B4 FC                jmp    0x3419
0x0000000000003765:  B8 06 00                mov    ax, 6
0x0000000000003768:  30 D2                   xor    dl, dl
0x000000000000376a:  E8 85 FA                call   P_GiveWeapon_
0x000000000000376d:  84 C0                   test   al, al
0x000000000000376f:  75 03                   jne    0x3774
0x0000000000003771:  E9 C8 FC                jmp    0x343c
0x0000000000003774:  BB 24 08                mov    bx, 0x824
0x0000000000003777:  B9 21 00                mov    cx, 0x21
0x000000000000377a:  C7 07 35 00             mov    word ptr ds:[bx], 0x35
0x000000000000377e:  E9 98 FC                jmp    0x3419
0x0000000000003781:  98                      cbw   
0x0000000000003782:  89 C2                   mov    dx, ax
0x0000000000003784:  B8 03 00                mov    ax, 3
0x0000000000003787:  E8 68 FA                call   P_GiveWeapon_
0x000000000000378a:  84 C0                   test   al, al
0x000000000000378c:  74 E3                   je     0x3771
0x000000000000378e:  BB 24 08                mov    bx, 0x824
0x0000000000003791:  B9 21 00                mov    cx, 0x21
0x0000000000003794:  C7 07 36 00             mov    word ptr ds:[bx], 0x36
0x0000000000003798:  E9 7E FC                jmp    0x3419
0x000000000000379b:  B8 07 00                mov    ax, 7
0x000000000000379e:  30 D2                   xor    dl, dl
0x00000000000037a0:  E8 4F FA                call   P_GiveWeapon_
0x00000000000037a3:  84 C0                   test   al, al
0x00000000000037a5:  74 CA                   je     0x3771
0x00000000000037a7:  BB 24 08                mov    bx, 0x824
0x00000000000037aa:  B9 21 00                mov    cx, 0x21
0x00000000000037ad:  C7 07 37 00             mov    word ptr ds:[bx], 0x37
0x00000000000037b1:  E9 65 FC                jmp    0x3419
0x00000000000037b4:  B8 04 00                mov    ax, 4
0x00000000000037b7:  30 D2                   xor    dl, dl
0x00000000000037b9:  E8 36 FA                call   P_GiveWeapon_
0x00000000000037bc:  84 C0                   test   al, al
0x00000000000037be:  74 B1                   je     0x3771
0x00000000000037c0:  BB 24 08                mov    bx, 0x824
0x00000000000037c3:  B9 21 00                mov    cx, 0x21
0x00000000000037c6:  C7 07 38 00             mov    word ptr ds:[bx], 0x38
0x00000000000037ca:  E9 4C FC                jmp    0x3419
0x00000000000037cd:  B8 05 00                mov    ax, 5
0x00000000000037d0:  30 D2                   xor    dl, dl
0x00000000000037d2:  E8 1D FA                call   P_GiveWeapon_
0x00000000000037d5:  84 C0                   test   al, al
0x00000000000037d7:  74 98                   je     0x3771
0x00000000000037d9:  BB 24 08                mov    bx, 0x824
0x00000000000037dc:  B9 21 00                mov    cx, 0x21
0x00000000000037df:  C7 07 39 00             mov    word ptr ds:[bx], 0x39
0x00000000000037e3:  E9 33 FC                jmp    0x3419
0x00000000000037e6:  98                      cbw   
0x00000000000037e7:  89 C2                   mov    dx, ax
0x00000000000037e9:  B8 02 00                mov    ax, 2
0x00000000000037ec:  E8 03 FA                call   P_GiveWeapon_
0x00000000000037ef:  84 C0                   test   al, al
0x00000000000037f1:  75 03                   jne    0x37f6
0x00000000000037f3:  E9 46 FC                jmp    0x343c
0x00000000000037f6:  BB 24 08                mov    bx, 0x824
0x00000000000037f9:  B9 21 00                mov    cx, 0x21
0x00000000000037fc:  C7 07 3A 00             mov    word ptr ds:[bx], 0x3a
0x0000000000003800:  E9 16 FC                jmp    0x3419
0x0000000000003803:  98                      cbw   
0x0000000000003804:  89 C2                   mov    dx, ax
0x0000000000003806:  B8 08 00                mov    ax, 8
0x0000000000003809:  E8 E6 F9                call   P_GiveWeapon_
0x000000000000380c:  84 C0                   test   al, al
0x000000000000380e:  74 E3                   je     0x37f3
0x0000000000003810:  BB 24 08                mov    bx, 0x824
0x0000000000003813:  B9 21 00                mov    cx, 0x21
0x0000000000003816:  C7 07 3B 00             mov    word ptr ds:[bx], 0x3b
0x000000000000381a:  E9 FC FB                jmp    0x3419

ENDP



PROC    P_KillMobj_  NEAR
PUBLIC  P_KillMobj_

0x000000000000381e:  56                      push   si
0x000000000000381f:  57                      push   di
0x0000000000003820:  55                      push   bp
0x0000000000003821:  89 E5                   mov    bp, sp
0x0000000000003823:  83 EC 0E                sub    sp, 0xe
0x0000000000003826:  89 C7                   mov    di, ax
0x0000000000003828:  89 D6                   mov    si, dx
0x000000000000382a:  89 4E FE                mov    word ptr [bp - 2], cx
0x000000000000382d:  C7 46 F6 3C 06          mov    word ptr [bp - 0xa], 0x63c
0x0000000000003832:  C7 46 F8 D9 92          mov    word ptr [bp - 8], 0x92d9
0x0000000000003837:  C7 46 FA 0A 01          mov    word ptr [bp - 6], 0x10a
0x000000000000383c:  8E C1                   mov    es, cx
0x000000000000383e:  C7 46 FC D9 92          mov    word ptr [bp - 4], 0x92d9
0x0000000000003843:  26 81 67 14 FB BF       and    word ptr es:[bx + 0x14], 0xbffb
0x0000000000003849:  C7 46 F2 A8 04          mov    word ptr [bp - 0xe], 0x4a8
0x000000000000384e:  26 80 67 17 FE          and    byte ptr es:[bx + 0x17], 0xfe
0x0000000000003853:  C7 46 F4 D9 92          mov    word ptr [bp - 0xc], 0x92d9
0x0000000000003858:  80 7C 1A 12             cmp    byte ptr ds:[si + 0x1a], 0x12
0x000000000000385c:  74 03                   je     0x3861
0x000000000000385e:  E9 1B 01                jmp    0x397c
0x0000000000003861:  8E 46 FE                mov    es, word ptr [bp - 2]
0x0000000000003864:  26 80 4F 15 04          or     byte ptr es:[bx + 0x15], 4
0x0000000000003869:  26 80 4F 16 10          or     byte ptr es:[bx + 0x16], 0x10
0x000000000000386e:  D1 7C 0C                sar    word ptr ds:[si + 0xc], 1
0x0000000000003871:  D1 5C 0A                rcr    word ptr ds:[si + 0xa], 1
0x0000000000003874:  D1 7C 0C                sar    word ptr ds:[si + 0xc], 1
0x0000000000003877:  D1 5C 0A                rcr    word ptr ds:[si + 0xa], 1
0x000000000000387a:  85 FF                   test   di, di
0x000000000000387c:  74 06                   je     0x3884
0x000000000000387e:  80 7D 1A 00             cmp    byte ptr ds:[di + 0x1a], 0
0x0000000000003882:  75 0C                   jne    0x3890
0x0000000000003884:  26 F6 47 16 40          test   byte ptr es:[bx + 0x16], 0x40
0x0000000000003889:  74 05                   je     0x3890
0x000000000000388b:  BF 1E 08                mov    di, 0x81e
0x000000000000388e:  FF 05                   inc    word ptr ds:[di]
0x0000000000003890:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003893:  3C 12                   cmp    al, 0x12
0x0000000000003895:  74 03                   je     0x389a
0x0000000000003897:  E9 EA 00                jmp    0x3984
0x000000000000389a:  B9 2C 00                mov    cx, 0x2c
0x000000000000389d:  8D 84 FC CB             lea    ax, [si - 0x3404]
0x00000000000038a1:  31 D2                   xor    dx, dx
0x00000000000038a3:  F7 F1                   div    cx
0x00000000000038a5:  BF 2C 08                mov    di, 0x82c
0x00000000000038a8:  3B 05                   cmp    ax, word ptr ds:[di]
0x00000000000038aa:  75 25                   jne    0x38d1
0x00000000000038ac:  C6 06 35 20 01          mov    byte ptr ds:[0x2035], 1
0x00000000000038b1:  8E 46 FE                mov    es, word ptr [bp - 2]
0x00000000000038b4:  26 8B 07                mov    ax, word ptr es:[bx]
0x00000000000038b7:  26 8B 57 02             mov    dx, word ptr es:[bx + 2]
0x00000000000038bb:  A3 C4 1D                mov    word ptr ds:[0x1dc4], ax
0x00000000000038be:  89 16 C6 1D             mov    word ptr ds:[0x1dc6], dx
0x00000000000038c2:  26 8B 57 04             mov    dx, word ptr es:[bx + 4]
0x00000000000038c6:  26 8B 47 06             mov    ax, word ptr es:[bx + 6]
0x00000000000038ca:  89 16 C0 1D             mov    word ptr ds:[0x1dc0], dx
0x00000000000038ce:  A3 C2 1D                mov    word ptr ds:[0x1dc2], ax
0x00000000000038d1:  80 7C 1A 00             cmp    byte ptr ds:[si + 0x1a], 0
0x00000000000038d5:  75 1F                   jne    0x38f6
0x00000000000038d7:  8E 46 FE                mov    es, word ptr [bp - 2]
0x00000000000038da:  BF ED 07                mov    di, 0x7ed
0x00000000000038dd:  26 80 67 14 FD          and    byte ptr es:[bx + 0x14], 0xfd
0x00000000000038e2:  C6 05 01                mov    byte ptr ds:[di], 1
0x00000000000038e5:  BF EA 02                mov    di, 0x2ea
0x00000000000038e8:  FF 1E 68 0F             lcall  [0xf68]
0x00000000000038ec:  80 3D 00                cmp    byte ptr ds:[di], 0
0x00000000000038ef:  74 05                   je     0x38f6
0x00000000000038f1:  9A 3A 25 A8 0A          lcall  0xaa8:0x253a
0x00000000000038f6:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x00000000000038f9:  30 E4                   xor    ah, ah
0x00000000000038fb:  FF 5E F6                lcall  [bp - 0xa]
0x00000000000038fe:  F7 D8                   neg    ax
0x0000000000003900:  3B 44 1C                cmp    ax, word ptr ds:[si + MOBJ_T.m_health]
0x0000000000003903:  7E 6D                   jle    0x3972
0x0000000000003905:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003908:  30 E4                   xor    ah, ah
0x000000000000390a:  FF 5E FA                lcall  [bp - 6]
0x000000000000390d:  85 C0                   test   ax, ax
0x000000000000390f:  74 61                   je     0x3972
0x0000000000003911:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003914:  30 E4                   xor    ah, ah
0x0000000000003916:  FF 5E FA                lcall  [bp - 6]
0x0000000000003919:  89 C2                   mov    dx, ax
0x000000000000391b:  89 F0                   mov    ax, si
0x000000000000391d:  FF 1E 7C 0F             lcall  [0xf7c]
0x0000000000003921:  E8 E1 25                call   0x5f05
0x0000000000003924:  24 03                   and    al, 3
0x0000000000003926:  28 44 1B                sub    byte ptr ds:[si + 0x1b], al
0x0000000000003929:  8A 44 1B                mov    al, byte ptr ds:[si + 0x1b]
0x000000000000392c:  3C 01                   cmp    al, 1
0x000000000000392e:  73 5E                   jae    0x398e
0x0000000000003930:  C6 44 1B 01             mov    byte ptr ds:[si + 0x1b], 1
0x0000000000003934:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003937:  3C 02                   cmp    al, 2
0x0000000000003939:  73 59                   jae    0x3994
0x000000000000393b:  3C 01                   cmp    al, 1
0x000000000000393d:  75 2F                   jne    0x396e
0x000000000000393f:  B0 3F                   mov    al, 0x3f
0x0000000000003941:  FF 74 04                push   word ptr ds:[si + 4]
0x0000000000003944:  30 E4                   xor    ah, ah
0x0000000000003946:  50                      push   ax
0x0000000000003947:  8E 46 FE                mov    es, word ptr [bp - 2]
0x000000000000394a:  68 00 80                push   0x8000
0x000000000000394d:  26 8B 77 04             mov    si, word ptr es:[bx + 4]
0x0000000000003951:  26 8B 4F 06             mov    cx, word ptr es:[bx + 6]
0x0000000000003955:  26 8B 07                mov    ax, word ptr es:[bx]
0x0000000000003958:  26 8B 57 02             mov    dx, word ptr es:[bx + 2]
0x000000000000395c:  6A 00                   push   0
0x000000000000395e:  89 F3                   mov    bx, si
0x0000000000003960:  BE 34 07                mov    si, 0x734
0x0000000000003963:  FF 1E 74 0F             lcall  [0xf74]
0x0000000000003967:  C4 1C                   les    bx, ptr ds:[si]
0x0000000000003969:  26 80 4F 16 02          or     byte ptr es:[bx + 0x16], 2
0x000000000000396e:  C9                      LEAVE_MACRO  
0x000000000000396f:  5F                      pop    di
0x0000000000003970:  5E                      pop    si
0x0000000000003971:  C3                      ret    
0x0000000000003972:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003975:  30 E4                   xor    ah, ah
0x0000000000003977:  FF 5E F2                lcall  [bp - 0xe]
0x000000000000397a:  EB 9D                   jmp    0x3919
0x000000000000397c:  26 80 67 15 FD          and    byte ptr es:[bx + 0x15], 0xfd
0x0000000000003981:  E9 DD FE                jmp    0x3861
0x0000000000003984:  3C 16                   cmp    al, 0x16
0x0000000000003986:  75 03                   jne    0x398b
0x0000000000003988:  E9 0F FF                jmp    0x389a
0x000000000000398b:  E9 43 FF                jmp    0x38d1
0x000000000000398e:  3C F0                   cmp    al, 0xf0
0x0000000000003990:  77 9E                   ja     0x3930
0x0000000000003992:  EB A0                   jmp    0x3934
0x0000000000003994:  77 04                   ja     0x399a
0x0000000000003996:  B0 4D                   mov    al, 0x4d
0x0000000000003998:  EB A7                   jmp    0x3941
0x000000000000399a:  3C 17                   cmp    al, 0x17
0x000000000000399c:  74 A1                   je     0x393f
0x000000000000399e:  3C 0A                   cmp    al, 0xa
0x00000000000039a0:  75 CC                   jne    0x396e
0x00000000000039a2:  B0 49                   mov    al, 0x49
0x00000000000039a4:  EB 9B                   jmp    0x3941
0x00000000000039a6:  E9 39 39                jmp    0x72e2
0x00000000000039a9:  3A E9                   cmp    ch, cl
0x00000000000039ab:  39 39                   cmp    word ptr ds:[bx + di], di
0x00000000000039ad:  3A 39                   cmp    bh, byte ptr ds:[bx + di]
0x00000000000039af:  3A 1F                   cmp    bl, byte ptr ds:[bx]
0x00000000000039b1:  3A 39                   cmp    bh, byte ptr ds:[bx + di]
0x00000000000039b3:  3A 39                   cmp    bh, byte ptr ds:[bx + di]
0x00000000000039b5:  3A 39                   cmp    bh, byte ptr ds:[bx + di]
0x00000000000039b7:  3A 07                   cmp    al, byte ptr ds:[bx]
0x00000000000039b9:  3A 07                   cmp    al, byte ptr ds:[bx]
0x00000000000039bb:  3A 07                   cmp    al, byte ptr ds:[bx]
0x00000000000039bd:  3A 1F                   cmp    bl, byte ptr ds:[bx]
0x00000000000039bf:  3A 39                   cmp    bh, byte ptr ds:[bx + di]
0x00000000000039c1:  3A 1F                   cmp    bl, byte ptr ds:[bx]
0x00000000000039c3:  3A FF                   cmp    bh, bh
0x00000000000039c5:  39 1F                   cmp    word ptr ds:[bx], bx
0x00000000000039c7:  3A 0F                   cmp    cl, byte ptr ds:[bx]
0x00000000000039c9:  3A 1F                   cmp    bl, byte ptr ds:[bx]
0x00000000000039cb:  3A 07                   cmp    al, byte ptr ds:[bx]
0x00000000000039cd:  3A 39                   cmp    bh, byte ptr ds:[bx + di]
0x00000000000039cf:  3A 2F                   cmp    ch, byte ptr ds:[bx]
0x00000000000039d1:  3A 2F                   cmp    ch, byte ptr ds:[bx]
0x00000000000039d3:  3A


PROC    getMassThrust_  NEAR
PUBLIC  getMassThrust_

0x00000000000039d4:  53                      push   bx
0x00000000000039d5:  51                      push   cx
0x00000000000039d6:  80 EA 03                sub    dl, 3
0x00000000000039d9:  80 FA 16                cmp    dl, 0x16
0x00000000000039dc:  77 5B                   ja     0x3a39
0x00000000000039de:  30 F6                   xor    dh, dh
0x00000000000039e0:  89 D3                   mov    bx, dx
0x00000000000039e2:  01 D3                   add    bx, dx
0x00000000000039e4:  2E FF A7 A6 39          jmp    word ptr cs:[bx + 0x39a6]
0x00000000000039e9:  BB 00 80                mov    bx, 0x8000
0x00000000000039ec:  B9 0C 00                mov    cx, 0xc
0x00000000000039ef:  9A DF 5C A8 0A          lcall  0xaa8:0x5cdf
0x00000000000039f4:  BB F4 01                mov    bx, 0x1f4
0x00000000000039f7:  9A AD 5E A8 0A          lcall  0xaa8:0x5ead
0x00000000000039fc:  59                      pop    cx
0x00000000000039fd:  5B                      pop    bx
0x00000000000039fe:  C3                      ret    
0x00000000000039ff:  BA 00 40                mov    dx, 0x4000
0x0000000000003a02:  F7 E2                   mul    dx
0x0000000000003a04:  59                      pop    cx
0x0000000000003a05:  5B                      pop    bx
0x0000000000003a06:  C3                      ret    
0x0000000000003a07:  BA 00 08                mov    dx, 0x800
0x0000000000003a0a:  F7 E2                   mul    dx
0x0000000000003a0c:  59                      pop    cx
0x0000000000003a0d:  5B                      pop    bx
0x0000000000003a0e:  C3                      ret    
0x0000000000003a0f:  BB 00 80                mov    bx, 0x8000
0x0000000000003a12:  B9 0C 00                mov    cx, 0xc
0x0000000000003a15:  9A DF 5C A8 0A          lcall  0xaa8:0x5cdf
0x0000000000003a1a:  BB 58 02                mov    bx, 0x258
0x0000000000003a1d:  EB D8                   jmp    0x39f7
0x0000000000003a1f:  BB 00 80                mov    bx, 0x8000
0x0000000000003a22:  B9 0C 00                mov    cx, 0xc
0x0000000000003a25:  9A DF 5C A8 0A          lcall  0xaa8:0x5cdf
0x0000000000003a2a:  BB E8 03                mov    bx, 0x3e8
0x0000000000003a2d:  EB C8                   jmp    0x39f7
0x0000000000003a2f:  BB 50 00                mov    bx, 0x50
0x0000000000003a32:  99                      cwd    
0x0000000000003a33:  F7 FB                   idiv   bx
0x0000000000003a35:  99                      cwd    
0x0000000000003a36:  59                      pop    cx
0x0000000000003a37:  5B                      pop    bx
0x0000000000003a38:  C3                      ret    
0x0000000000003a39:  BA 00 20                mov    dx, 0x2000
0x0000000000003a3c:  F7 E2                   mul    dx
0x0000000000003a3e:  59                      pop    cx
0x0000000000003a3f:  5B                      pop    bx
0x0000000000003a40:  C3                      ret    
ENDP



PROC    P_DamageMobj_  FAR
PUBLIC  P_DamageMobj_

0x0000000000003a42:  56                      push   si
0x0000000000003a43:  57                      push   di
0x0000000000003a44:  55                      push   bp
0x0000000000003a45:  89 E5                   mov    bp, sp
0x0000000000003a47:  83 EC 28                sub    sp, 0x28
0x0000000000003a4a:  89 C6                   mov    si, ax
0x0000000000003a4c:  89 56 F2                mov    word ptr [bp - 0xe], dx
0x0000000000003a4f:  89 5E FA                mov    word ptr [bp - 6], bx
0x0000000000003a52:  89 CF                   mov    di, cx
0x0000000000003a54:  BB 2C 00                mov    bx, 0x2c
0x0000000000003a57:  2D 04 34                sub    ax, 0x3404
0x0000000000003a5a:  31 D2                   xor    dx, dx
0x0000000000003a5c:  F7 F3                   div    bx
0x0000000000003a5e:  6B D8 18                imul   bx, ax, 0x18
0x0000000000003a61:  C7 46 FE F5 6A          mov    word ptr [bp - 2], 0x6af5
0x0000000000003a66:  C7 46 D8 34 00          mov    word ptr [bp - 0x28], 0x34
0x0000000000003a6b:  C7 46 DA D9 92          mov    word ptr [bp - 0x26], 0x92d9
0x0000000000003a70:  C7 46 E0 86 05          mov    word ptr [bp - 0x20], 0x586
0x0000000000003a75:  C7 46 E2 D9 92          mov    word ptr [bp - 0x1e], 0x92d9
0x0000000000003a7a:  C7 46 DC 50 03          mov    word ptr [bp - 0x24], 0x350
0x0000000000003a7f:  C7 46 DE D9 92          mov    word ptr [bp - 0x22], 0x92d9
0x0000000000003a84:  8E 46 FE                mov    es, word ptr [bp - 2]
0x0000000000003a87:  89 5E FC                mov    word ptr [bp - 4], bx
0x0000000000003a8a:  26 F6 47 14 04          test   byte ptr es:[bx + 0x14], 4
0x0000000000003a8f:  75 03                   jne    0x3a94
0x0000000000003a91:  E9 6E 02                jmp    0x3d02
0x0000000000003a94:  83 7C 1C 00             cmp    word ptr ds:[si + MOBJ_T.m_health], 0
0x0000000000003a98:  7E F7                   jle    0x3a91
0x0000000000003a9a:  26 F6 47 17 01          test   byte ptr es:[bx + 0x17], 1
0x0000000000003a9f:  74 03                   je     0x3aa4
0x0000000000003aa1:  E9 62 02                jmp    0x3d06
0x0000000000003aa4:  80 7C 1A 00             cmp    byte ptr ds:[si + 0x1a], 0
0x0000000000003aa8:  75 0A                   jne    0x3ab4
0x0000000000003aaa:  BB 31 01                mov    bx, 0x131
0x0000000000003aad:  80 3F 00                cmp    byte ptr ds:[bx], 0
0x0000000000003ab0:  75 02                   jne    0x3ab4
0x0000000000003ab2:  D1 FF                   sar    di, 1
0x0000000000003ab4:  83 7E F2 00             cmp    word ptr [bp - 0xe], 0
0x0000000000003ab8:  75 03                   jne    0x3abd
0x0000000000003aba:  E9 14 01                jmp    0x3bd1
0x0000000000003abd:  C4 5E FC                les    bx, ptr [bp - 4]
0x0000000000003ac0:  26 F6 47 15 10          test   byte ptr es:[bx + 0x15], 0x10
0x0000000000003ac5:  75 F3                   jne    0x3aba
0x0000000000003ac7:  8B 46 FA                mov    ax, word ptr [bp - 6]
0x0000000000003aca:  85 C0                   test   ax, ax
0x0000000000003acc:  74 03                   je     0x3ad1
0x0000000000003ace:  E9 5C 02                jmp    0x3d2d
0x0000000000003ad1:  8B 46 F2                mov    ax, word ptr [bp - 0xe]
0x0000000000003ad4:  BB 2C 00                mov    bx, 0x2c
0x0000000000003ad7:  31 D2                   xor    dx, dx
0x0000000000003ad9:  2D 04 34                sub    ax, 0x3404
0x0000000000003adc:  F7 F3                   div    bx
0x0000000000003ade:  6B D8 18                imul   bx, ax, 0x18
0x0000000000003ae1:  B8 F5 6A                mov    ax, 0x6af5
0x0000000000003ae4:  8E C0                   mov    es, ax
0x0000000000003ae6:  26 8B 17                mov    dx, word ptr es:[bx]
0x0000000000003ae9:  26 8B 47 02             mov    ax, word ptr es:[bx + 2]
0x0000000000003aed:  26 8B 4F 06             mov    cx, word ptr es:[bx + 6]
0x0000000000003af1:  89 46 E4                mov    word ptr [bp - 0x1c], ax
0x0000000000003af4:  89 4E E8                mov    word ptr [bp - 0x18], cx
0x0000000000003af7:  26 8B 47 04             mov    ax, word ptr es:[bx + 4]
0x0000000000003afb:  26 8B 4F 08             mov    cx, word ptr es:[bx + 8]
0x0000000000003aff:  26 8B 5F 0A             mov    bx, word ptr es:[bx + 0xa]
0x0000000000003b03:  8E 46 FE                mov    es, word ptr [bp - 2]
0x0000000000003b06:  89 5E EC                mov    word ptr [bp - 0x14], bx
0x0000000000003b09:  8B 5E FC                mov    bx, word ptr [bp - 4]
0x0000000000003b0c:  26 FF 77 06             push   word ptr es:[bx + 6]
0x0000000000003b10:  26 FF 77 04             push   word ptr es:[bx + 4]
0x0000000000003b14:  89 4E EA                mov    word ptr [bp - 0x16], cx
0x0000000000003b17:  26 FF 77 02             push   word ptr es:[bx + 2]
0x0000000000003b1b:  8B 4E E8                mov    cx, word ptr [bp - 0x18]
0x0000000000003b1e:  26 FF 37                push   word ptr es:[bx]
0x0000000000003b21:  89 C3                   mov    bx, ax
0x0000000000003b23:  89 D0                   mov    ax, dx
0x0000000000003b25:  8B 56 E4                mov    dx, word ptr [bp - 0x1c]
0x0000000000003b28:  0E                      push   cs
0x0000000000003b29:  E8 E9 2D                call   0x6915
0x0000000000003b2c:  90                      nop    
0x0000000000003b2d:  89 46 EE                mov    word ptr [bp - 0x12], ax
0x0000000000003b30:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003b33:  89 56 F0                mov    word ptr [bp - 0x10], dx
0x0000000000003b36:  98                      cbw   
0x0000000000003b37:  89 56 F8                mov    word ptr [bp - 8], dx
0x0000000000003b3a:  89 C2                   mov    dx, ax
0x0000000000003b3c:  89 F8                   mov    ax, di
0x0000000000003b3e:  E8 93 FE                call   0x39d4
0x0000000000003b41:  89 C1                   mov    cx, ax
0x0000000000003b43:  89 46 F4                mov    word ptr [bp - 0xc], ax
0x0000000000003b46:  89 56 F6                mov    word ptr [bp - 0xa], dx
0x0000000000003b49:  83 FF 28                cmp    di, 0x28
0x0000000000003b4c:  7D 4C                   jge    0x3b9a
0x0000000000003b4e:  3B 7C 1C                cmp    di, word ptr ds:[si + MOBJ_T.m_health]
0x0000000000003b51:  7E 47                   jle    0x3b9a
0x0000000000003b53:  C4 5E FC                les    bx, ptr [bp - 4]
0x0000000000003b56:  26 8B 47 08             mov    ax, word ptr es:[bx + 8]
0x0000000000003b5a:  2B 46 EA                sub    ax, word ptr [bp - 0x16]
0x0000000000003b5d:  89 46 E6                mov    word ptr [bp - 0x1a], ax
0x0000000000003b60:  26 8B 47 0A             mov    ax, word ptr es:[bx + 0xa]
0x0000000000003b64:  1B 46 EC                sbb    ax, word ptr [bp - 0x14]
0x0000000000003b67:  3D 40 00                cmp    ax, 0x40
0x0000000000003b6a:  7F 08                   jg     0x3b74
0x0000000000003b6c:  75 2C                   jne    0x3b9a
0x0000000000003b6e:  83 7E E6 00             cmp    word ptr [bp - 0x1a], 0
0x0000000000003b72:  76 26                   jbe    0x3b9a
0x0000000000003b74:  E8 8E 23                call   0x5f05
0x0000000000003b77:  A8 01                   test   al, 1
0x0000000000003b79:  74 1F                   je     0x3b9a
0x0000000000003b7b:  89 C8                   mov    ax, cx
0x0000000000003b7d:  01 C0                   add    ax, ax
0x0000000000003b7f:  11 D2                   adc    dx, dx
0x0000000000003b81:  01 C0                   add    ax, ax
0x0000000000003b83:  89 46 F4                mov    word ptr [bp - 0xc], ax
0x0000000000003b86:  8B 46 EE                mov    ax, word ptr [bp - 0x12]
0x0000000000003b89:  11 D2                   adc    dx, dx
0x0000000000003b8b:  05 00 00                add    ax, 0
0x0000000000003b8e:  8B 46 F0                mov    ax, word ptr [bp - 0x10]
0x0000000000003b91:  15 00 80                adc    ax, 0x8000
0x0000000000003b94:  89 56 F6                mov    word ptr [bp - 0xa], dx
0x0000000000003b97:  89 46 F8                mov    word ptr [bp - 8], ax
0x0000000000003b9a:  8B 46 F8                mov    ax, word ptr [bp - 8]
0x0000000000003b9d:  D1 E8                   shr    ax, 1
0x0000000000003b9f:  8B 5E F4                mov    bx, word ptr [bp - 0xc]
0x0000000000003ba2:  24 FC                   and    al, 0xfc
0x0000000000003ba4:  8B 4E F6                mov    cx, word ptr [bp - 0xa]
0x0000000000003ba7:  89 46 F8                mov    word ptr [bp - 8], ax
0x0000000000003baa:  89 C2                   mov    dx, ax
0x0000000000003bac:  B8 D6 33                mov    ax, 0x33d6
0x0000000000003baf:  9A 03 5C A8 0A          lcall  0xaa8:0x5c03
0x0000000000003bb4:  8B 5E F4                mov    bx, word ptr [bp - 0xc]
0x0000000000003bb7:  8B 4E F6                mov    cx, word ptr [bp - 0xa]
0x0000000000003bba:  01 44 0E                add    word ptr ds:[si + 0xe], ax
0x0000000000003bbd:  B8 D6 31                mov    ax, 0x31d6
0x0000000000003bc0:  11 54 10                adc    word ptr ds:[si + 0x10], dx
0x0000000000003bc3:  8B 56 F8                mov    dx, word ptr [bp - 8]
0x0000000000003bc6:  9A 03 5C A8 0A          lcall  0xaa8:0x5c03
0x0000000000003bcb:  01 44 12                add    word ptr ds:[si + 0x12], ax
0x0000000000003bce:  11 54 14                adc    word ptr ds:[si + 0x14], dx
0x0000000000003bd1:  80 7C 1A 00             cmp    byte ptr ds:[si + 0x1a], 0
0x0000000000003bd5:  74 03                   je     0x3bda
0x0000000000003bd7:  E9 A0 00                jmp    0x3c7a
0x0000000000003bda:  8B 44 04                mov    ax, word ptr ds:[si + 4]
0x0000000000003bdd:  C1 E0 04                shl    ax, 4
0x0000000000003be0:  89 C3                   mov    bx, ax
0x0000000000003be2:  81 C3 3E DE             add    bx, 0xde3e
0x0000000000003be6:  80 3F 0B                cmp    byte ptr ds:[bx], 0xb
0x0000000000003be9:  75 0A                   jne    0x3bf5
0x0000000000003beb:  8B 44 1C                mov    ax, word ptr ds:[si + MOBJ_T.m_health]
0x0000000000003bee:  39 C7                   cmp    di, ax
0x0000000000003bf0:  7C 03                   jl     0x3bf5
0x0000000000003bf2:  89 C7                   mov    di, ax
0x0000000000003bf4:  4F                      dec    di
0x0000000000003bf5:  81 FF E8 03             cmp    di, 0x3e8
0x0000000000003bf9:  7D 13                   jge    0x3c0e
0x0000000000003bfb:  BB 0B 08                mov    bx, 0x80b
0x0000000000003bfe:  F6 07 02                test   byte ptr ds:[bx], 2
0x0000000000003c01:  74 03                   je     0x3c06
0x0000000000003c03:  E9 FC 00                jmp    0x3d02
0x0000000000003c06:  BB EE 07                mov    bx, 0x7ee
0x0000000000003c09:  83 3F 00                cmp    word ptr ds:[bx], 0
0x0000000000003c0c:  75 F5                   jne    0x3c03
0x0000000000003c0e:  BB EC 07                mov    bx, _player + PLAYER_T.player_armortype
0x0000000000003c11:  8A 07                   mov    al, byte ptr ds:[bx]
0x0000000000003c13:  84 C0                   test   al, al
0x0000000000003c15:  74 25                   je     0x3c3c
0x0000000000003c17:  3C 01                   cmp    al, 1
0x0000000000003c19:  74 03                   je     0x3c1e
0x0000000000003c1b:  E9 25 01                jmp    0x3d43
0x0000000000003c1e:  89 F8                   mov    ax, di
0x0000000000003c20:  BB 03 00                mov    bx, 3
0x0000000000003c23:  99                      cwd    
0x0000000000003c24:  F7 FB                   idiv   bx
0x0000000000003c26:  BB EA 07                mov    bx, _player + PLAYER_T.player_armorpoints
0x0000000000003c29:  3B 07                   cmp    ax, word ptr ds:[bx]
0x0000000000003c2b:  7C 08                   jl     0x3c35
0x0000000000003c2d:  8B 07                   mov    ax, word ptr ds:[bx]
0x0000000000003c2f:  BB EC 07                mov    bx, _player + PLAYER_T.player_armortype
0x0000000000003c32:  C6 07 00                mov    byte ptr ds:[bx], 0
0x0000000000003c35:  BB EA 07                mov    bx, _player + PLAYER_T.player_armorpoints
0x0000000000003c38:  29 C7                   sub    di, ax
0x0000000000003c3a:  29 07                   sub    word ptr ds:[bx], ax
0x0000000000003c3c:  BB E8 07                mov    bx, _player + PLAYER_T.player_health
0x0000000000003c3f:  29 3F                   sub    word ptr ds:[bx], di
0x0000000000003c41:  83 3F 00                cmp    word ptr ds:[bx], 0
0x0000000000003c44:  7D 03                   jge    0x3c49
0x0000000000003c46:  E9 01 01                jmp    0x3d4a
0x0000000000003c49:  8B 46 FA                mov    ax, word ptr [bp - 6]
0x0000000000003c4c:  BB 2C 00                mov    bx, 0x2c
0x0000000000003c4f:  31 D2                   xor    dx, dx
0x0000000000003c51:  2D 04 34                sub    ax, 0x3404
0x0000000000003c54:  F7 F3                   div    bx
0x0000000000003c56:  BB 2C 08                mov    bx, 0x82c
0x0000000000003c59:  89 07                   mov    word ptr ds:[bx], ax
0x0000000000003c5b:  8B 5E FA                mov    bx, word ptr [bp - 6]
0x0000000000003c5e:  83 7F 1C 00             cmp    word ptr ds:[bx + MOBJ_T.m_health], 0
0x0000000000003c62:  7F 03                   jg     0x3c67
0x0000000000003c64:  E9 EC 00                jmp    0x3d53
0x0000000000003c67:  C6 06 35 20 00          mov    byte ptr ds:[0x2035], 0
0x0000000000003c6c:  BB 28 08                mov    bx, 0x828
0x0000000000003c6f:  01 3F                   add    word ptr ds:[bx], di
0x0000000000003c71:  83 3F 64                cmp    word ptr ds:[bx], 0x64
0x0000000000003c74:  7E 04                   jle    0x3c7a
0x0000000000003c76:  C7 07 64 00             mov    word ptr ds:[bx], 0x64
0x0000000000003c7a:  29 7C 1C                sub    word ptr ds:[si + MOBJ_T.m_health], di
0x0000000000003c7d:  83 7C 1C 00             cmp    word ptr ds:[si + MOBJ_T.m_health], 0
0x0000000000003c81:  7F 03                   jg     0x3c86
0x0000000000003c83:  E9 04 01                jmp    0x3d8a
0x0000000000003c86:  E8 7C 22                call   0x5f05
0x0000000000003c89:  88 C2                   mov    dl, al
0x0000000000003c8b:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003c8e:  30 E4                   xor    ah, ah
0x0000000000003c90:  30 F6                   xor    dh, dh
0x0000000000003c92:  FF 5E D8                lcall  [bp - 0x28]
0x0000000000003c95:  39 C2                   cmp    dx, ax
0x0000000000003c97:  7D 1F                   jge    0x3cb8
0x0000000000003c99:  C4 5E FC                les    bx, ptr [bp - 4]
0x0000000000003c9c:  26 F6 47 17 01          test   byte ptr es:[bx + 0x17], 1
0x0000000000003ca1:  75 15                   jne    0x3cb8
0x0000000000003ca3:  26 80 4F 14 40          or     byte ptr es:[bx + 0x14], 0x40
0x0000000000003ca8:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003cab:  30 E4                   xor    ah, ah
0x0000000000003cad:  FF 5E E0                lcall  [bp - 0x20]
0x0000000000003cb0:  89 C2                   mov    dx, ax
0x0000000000003cb2:  89 F0                   mov    ax, si
0x0000000000003cb4:  FF 1E 7C 0F             lcall  [0xf7c]
0x0000000000003cb8:  C6 44 24 00             mov    byte ptr ds:[si + 0x24], 0
0x0000000000003cbc:  80 7C 25 00             cmp    byte ptr ds:[si + 0x25], 0
0x0000000000003cc0:  75 69                   jne    0x3d2b
0x0000000000003cc2:  8B 46 FA                mov    ax, word ptr [bp - 6]
0x0000000000003cc5:  85 C0                   test   ax, ax
0x0000000000003cc7:  74 39                   je     0x3d02
0x0000000000003cc9:  39 C6                   cmp    si, ax
0x0000000000003ccb:  74 35                   je     0x3d02
0x0000000000003ccd:  89 C3                   mov    bx, ax
0x0000000000003ccf:  80 7F 1A 03             cmp    byte ptr ds:[bx + 0x1a], 3
0x0000000000003cd3:  74 2D                   je     0x3d02
0x0000000000003cd5:  BB 2C 00                mov    bx, 0x2c
0x0000000000003cd8:  2D 04 34                sub    ax, 0x3404
0x0000000000003cdb:  31 D2                   xor    dx, dx
0x0000000000003cdd:  F7 F3                   div    bx
0x0000000000003cdf:  89 44 22                mov    word ptr ds:[si + 0x22], ax
0x0000000000003ce2:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003ce5:  30 E4                   xor    ah, ah
0x0000000000003ce7:  6B D0 0B                imul   dx, ax, 0xb
0x0000000000003cea:  8B 7E FC                mov    di, word ptr [bp - 4]
0x0000000000003ced:  C6 44 25 64             mov    byte ptr ds:[si + 0x25], 0x64
0x0000000000003cf1:  8E 46 FE                mov    es, word ptr [bp - 2]
0x0000000000003cf4:  89 D3                   mov    bx, dx
0x0000000000003cf6:  81 C3 60 C4             add    bx, 0xc460
0x0000000000003cfa:  26 8B 55 12             mov    dx, word ptr es:[di + 0x12]
0x0000000000003cfe:  3B 17                   cmp    dx, word ptr ds:[bx]
0x0000000000003d00:  74 4F                   je     0x3d51
0x0000000000003d02:  C9                      LEAVE_MACRO  
0x0000000000003d03:  5F                      pop    di
0x0000000000003d04:  5E                      pop    si
0x0000000000003d05:  CB                      retf   
0x0000000000003d06:  C7 44 16 00 00          mov    word ptr ds:[si + 0x16], 0
0x0000000000003d0b:  C7 44 18 00 00          mov    word ptr ds:[si + 0x18], 0
0x0000000000003d10:  8B 44 16                mov    ax, word ptr ds:[si + 0x16]
0x0000000000003d13:  8B 54 18                mov    dx, word ptr ds:[si + 0x18]
0x0000000000003d16:  89 44 12                mov    word ptr ds:[si + 0x12], ax
0x0000000000003d19:  89 54 14                mov    word ptr ds:[si + 0x14], dx
0x0000000000003d1c:  8B 54 12                mov    dx, word ptr ds:[si + 0x12]
0x0000000000003d1f:  8B 44 14                mov    ax, word ptr ds:[si + 0x14]
0x0000000000003d22:  89 54 0E                mov    word ptr ds:[si + 0xe], dx
0x0000000000003d25:  89 44 10                mov    word ptr ds:[si + 0x10], ax
0x0000000000003d28:  E9 79 FD                jmp    0x3aa4
0x0000000000003d2b:  EB 6F                   jmp    0x3d9c
0x0000000000003d2d:  89 C3                   mov    bx, ax
0x0000000000003d2f:  80 7F 1A 00             cmp    byte ptr ds:[bx + 0x1a], 0
0x0000000000003d33:  75 03                   jne    0x3d38
0x0000000000003d35:  E9 99 FD                jmp    0x3ad1
0x0000000000003d38:  BB 00 08                mov    bx, _player + PLAYER_T.player_readyweapon
0x0000000000003d3b:  80 3F 07                cmp    byte ptr ds:[bx], 7
0x0000000000003d3e:  75 F5                   jne    0x3d35
0x0000000000003d40:  E9 8E FE                jmp    0x3bd1
0x0000000000003d43:  89 F8                   mov    ax, di
0x0000000000003d45:  D1 F8                   sar    ax, 1
0x0000000000003d47:  E9 DC FE                jmp    0x3c26
0x0000000000003d4a:  C7 07 00 00             mov    word ptr ds:[bx], 0
0x0000000000003d4e:  E9 F8 FE                jmp    0x3c49
0x0000000000003d51:  EB 56                   jmp    0x3da9
0x0000000000003d53:  80 3E 35 20 00          cmp    byte ptr ds:[0x2035], 0
0x0000000000003d58:  74 03                   je     0x3d5d
0x0000000000003d5a:  E9 0F FF                jmp    0x3c6c
0x0000000000003d5d:  6B D8 18                imul   bx, ax, 0x18
0x0000000000003d60:  B8 F5 6A                mov    ax, 0x6af5
0x0000000000003d63:  8E C0                   mov    es, ax
0x0000000000003d65:  C6 06 35 20 01          mov    byte ptr ds:[0x2035], 1
0x0000000000003d6a:  26 8B 17                mov    dx, word ptr es:[bx]
0x0000000000003d6d:  26 8B 47 02             mov    ax, word ptr es:[bx + 2]
0x0000000000003d71:  89 16 C4 1D             mov    word ptr ds:[0x1dc4], dx
0x0000000000003d75:  A3 C6 1D                mov    word ptr ds:[0x1dc6], ax
0x0000000000003d78:  26 8B 47 04             mov    ax, word ptr es:[bx + 4]
0x0000000000003d7c:  26 8B 57 06             mov    dx, word ptr es:[bx + 6]
0x0000000000003d80:  A3 C0 1D                mov    word ptr ds:[0x1dc0], ax
0x0000000000003d83:  89 16 C2 1D             mov    word ptr ds:[0x1dc2], dx
0x0000000000003d87:  E9 E2 FE                jmp    0x3c6c
0x0000000000003d8a:  8B 5E FC                mov    bx, word ptr [bp - 4]
0x0000000000003d8d:  8B 4E FE                mov    cx, word ptr [bp - 2]
0x0000000000003d90:  8B 46 FA                mov    ax, word ptr [bp - 6]
0x0000000000003d93:  89 F2                   mov    dx, si
0x0000000000003d95:  E8 86 FA                call   0x381e
0x0000000000003d98:  C9                      LEAVE_MACRO  
0x0000000000003d99:  5F                      pop    di
0x0000000000003d9a:  5E                      pop    si
0x0000000000003d9b:  CB                      retf   
0x0000000000003d9c:  80 7C 1A 03             cmp    byte ptr ds:[si + 0x1a], 3
0x0000000000003da0:  75 03                   jne    0x3da5
0x0000000000003da2:  E9 1D FF                jmp    0x3cc2
0x0000000000003da5:  C9                      LEAVE_MACRO  
0x0000000000003da6:  5F                      pop    di
0x0000000000003da7:  5E                      pop    si
0x0000000000003da8:  CB                      retf   
0x0000000000003da9:  FF 5E DC                lcall  [bp - 0x24]
0x0000000000003dac:  85 C0                   test   ax, ax
0x0000000000003dae:  75 03                   jne    0x3db3
0x0000000000003db0:  E9 4F FF                jmp    0x3d02
0x0000000000003db3:  8A 44 1A                mov    al, byte ptr ds:[si + 0x1a]
0x0000000000003db6:  30 E4                   xor    ah, ah
0x0000000000003db8:  FF 5E DC                lcall  [bp - 0x24]
0x0000000000003dbb:  89 C2                   mov    dx, ax
0x0000000000003dbd:  89 F0                   mov    ax, si
0x0000000000003dbf:  FF 1E 7C 0F             lcall  [0xf7c]
0x0000000000003dc3:  C9                      LEAVE_MACRO  
0x0000000000003dc4:  5F                      pop    di
0x0000000000003dc5:  5E                      pop    si
0x0000000000003dc6:  CB                      retf   

@

PROC    P_INTER_ENDMARKER_ 
PUBLIC  P_INTER_ENDMARKER_
ENDP


END