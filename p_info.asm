
; Copyright (C) 1993-dw 09619h
Id Software, Inc.
; Copyright (C) 1993-dw 00820h
Raven Software
; Copyright (C) 2016-dw 01720h
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

_pain_chance_lookup:


db 255  ; MT_PLAYER = 00h
db 200  ; MT_POSSESSED = 01h
db 170  ; MT_SHOTGUY = 02h
db 10   ; MT_VILE = 03h
db 0    ; MT_FIRE = 04h
db 100  ; MT_UNDEAD = 05h
db 0    ; MT_TRACER = 06h
db 0    ; MT_SMOKE = 07h
db 80   ; MT_FATSO = 08h
db 0    ; MT_FATSHOT = 09h
db 170  ; MT_CHAINGUY = 0Ah
db 200  ; MT_TROOP = 0Bh
db 180  ; MT_SERGEANT = 0Ch
db 180  ; MT_SHADOWS = 0Dh
db 128  ; MT_HEAD = 0Eh
db 50   ; MT_BRUISER = 0Fh
db 0    ; MT_BRUISERSHOT = 010h
db 50   ; MT_KNIGHT = 011h
db 0    ; MT_SKULL = 012h
db 40   ; MT_SPIDER = 013h
db 128  ; MT_BABY = 014h
db 20   ; MT_CYBORG = 015h
db 128  ; MT_PAIN = 016h
db 170  ; MT_WOLFSS = 017h
db 0    ; MT_KEEN = 018h
db 255  ; MT_BOSSBRAIN = 019h


PROC    getPainChance_  NEAR 
PUBLIC  getPainChance_



cmp    al, MT_BOSSBRAIN
ja     pain_chance_default
cmp    al, MT_KEEN
je     ret_pain_256
cmp    al, MT_SKULL
je     ret_pain_256
push   bx
cbw
mov    bx, ax
mov    al, byte ptr cs:[bx + _pain_chance_lookup]
pop    bx
ret  
ret_pain_256:
mov    ax, 0100h
ret

ENDP


_raise_state_lookup:

dw S_POSS_RAISE1 ; MT_POSSESSED = 01h
dw S_SPOS_RAISE1 ; MT_SHOTGUY = 02h
dw 0             ; MT_VILE = 03h
dw 0             ; MT_FIRE = 04h
dw S_SKEL_RAISE1 ; MT_UNDEAD = 05h
dw 0             ; MT_TRACER = 06h
dw 0             ; MT_SMOKE = 07h
dw S_FATT_RAISE1 ; MT_FATSO = 08h
dw 0             ; MT_FATSHOT = 09h
dw S_CPOS_RAISE1 ; MT_CHAINGUY = 0Ah
dw S_TROO_RAISE1 ; MT_TROOP = 0Bh
dw S_SARG_RAISE1 ; MT_SERGEANT = 0Ch
dw S_SARG_RAISE1 ; MT_SHADOWS = 0Dh
dw S_HEAD_RAISE1 ; MT_HEAD = 0Eh
dw S_BOSS_RAISE1 ; MT_BRUISER = 0Fh
dw 0             ; MT_BRUISERSHOT = 010h
dw S_BOS2_RAISE1 ; MT_KNIGHT = 011h
dw 0             ; MT_SKULL = 012h
dw 0             ; MT_SPIDER = 013h
dw S_BSPI_RAISE1 ; MT_BABY = 014h
dw 0             ; MT_CYBORG = 015h
dw S_PAIN_RAISE1 ; MT_PAIN = 016h
dw S_SSWV_RAISE1 ; MT_WOLFSS = 017h


PROC    getRaiseState_  NEAR 
PUBLIC  getRaiseState_


dec    ax
cmp    al, (MT_WOLFSS - 1)
ja     raise_state_default
push   bx
cbw
xchg   ax, bx
sal    bx, 1
mov    ax word ptr cs:[bx + _raise_state_lookup] ; 0 not counted..
raise_state_default:
xor    ax, ax
ret   



ENDP


PROC    getXDeathState_ NEAR 
PUBLIC  getXDeathState_


0x000000000000010a:  3C 02             cmp    al, MT_SHOTGUY
0x000000000000010c:  73 0C             jae    xd_ae_2
0x000000000000010e:  3C 01             cmp    al, MT_POSSESSED
0x0000000000000110:  74 1A             je     xd_possessed
0x0000000000000112:  84 C0             test   al, al
0x0000000000000114:  75 26             jne    xdeath_state_default
0x0000000000000116:  B8 A5 00          mov    ax, S_PLAY_XDIE1
0x0000000000000119:  CB                ret   
xd_ae_2:
0x000000000000011a:  76 14             jbe    xd_shotguy
0x000000000000011c:  3C 17             cmp    al, MT_WOLFSS
0x000000000000011e:  74 18             je     xd_wolfss
0x0000000000000120:  3C 0B             cmp    al, MT_TROOP
0x0000000000000122:  74 10             je     xd_chainguy
0x0000000000000124:  3C 0A             cmp    al, MT_CHAINGUY
0x0000000000000126:  75 14             jne    xdeath_state_default
0x0000000000000128:  B8 AD 01          mov    ax, S_CPOS_XDIE1
0x000000000000012b:  CB                ret   
xd_possessed:
0x000000000000012c:  B8 C2 00          mov    ax, S_POSS_XDIE1
0x000000000000012f:  CB                ret   
xd_shotguy:
0x0000000000000130:  B8 E3 00          mov    ax, S_SPOS_XDIE1
0x0000000000000133:  CB                ret   
xd_chainguy:
0x0000000000000134:  B8 CE 01          mov    ax, S_TROO_XDIE1
0x0000000000000137:  CB                ret   
xd_wolfss:
0x0000000000000138:  B8 ED 02          mov    ax, S_SSWV_XDIE1
0x000000000000013b:  CB                ret   
xdeath_state_default:
0x000000000000013c:  31 C0             xor    ax, ax
0x000000000000013e:  CB                ret   

ENDP



PROC    getMeleeState_ NEAR 
PUBLIC  getMeleeState_


cmp    al, MT_KNIGHT
;ja    melee_state_default
je    melee_state_hellknight
cmp   al, MT_BRUISER
je    melee_state_baron
cmp   al, MT_UNDEAD
je    melee_state_revenant
cmp   al, MT_TROOP
jb    melee_state_default
je    melee_state_imp
cmp   al, MT_SHADOWS
jbe   melee_state_pinky
melee_state_default:
xor    ax, ax
ret   
melee_state_revenant:
mov    ax, S_SKEL_FIST1
ret   
melee_state_imp:
mov    ax, S_TROO_ATK1
ret   
melee_state_pinky:
mov    ax, S_SARG_ATK1
ret   
melee_state_baron:
mov    ax, S_BOSS_ATK1
ret   
melee_state_hellknight:
mov    ax, S_BOS2_ATK1
ret   

ENDP

_mobj_mass_lookup:

dw 500      ; MT_VILE = 03h
dw 100      ; MT_FIRE = 04h
dw 500      ; MT_UNDEAD = 05h
dw 100      ; MT_TRACER = 06h
dw 100      ; MT_SMOKE = 07h
dw 1000     ; MT_FATSO = 08h
dw 100      ; MT_FATSHOT = 09h
dw 100      ; MT_CHAINGUY = 0Ah
dw 100      ; MT_TROOP = 0Bh
dw 400      ; MT_SERGEANT = 0Ch
dw 400      ; MT_SHADOWS = 0Dh
dw 400      ; MT_HEAD = 0Eh
dw 1000     ; MT_BRUISER = 0Fh
dw 100      ; MT_BRUISERSHOT = 010h
dw 1000     ; MT_KNIGHT = 011h
dw 50       ; MT_SKULL = 012h
dw 1000     ; MT_SPIDER = 013h
dw 600      ; MT_BABY = 014h
dw 1000     ; MT_CYBORG = 015h
dw 400      ; MT_PAIN = 016h
dw 100      ; MT_WOLFSS = 017h

PROC    getMobjMass_ NEAR 
PUBLIC  getMobjMass_

push   bx
sub    al, 3
cmp    al, (MT_BOSSBRAIN - 3)
ja     mobj_mass_default
cmp    al, (MT_WOLFSS - 3)
ja     mobj_mass_10million
cbw    ; already filtered out anything 0x80
xchg   ax, bx
sal    bx, 1
mov    ax, word ptr cs:[bx + _mobj_mass_lookup]
mobj_mass_cwd_and_return:
cwd
pop    bx
ret   
; ton of mass
mobj_mass_10million:
mov    ax, 09680h  ; 10000000
mov    dx, 098h
pop    bx
ret   
mobj_mass_default:
mov    ax, 100
jmp    mobj_mass_cwd_and_return


ENDP

_active_sound_lookup:

db SFX_POSACT   ; MT_POSSESSED = 01h
db SFX_POSACT   ; MT_SHOTGUY = 02h
db SFX_VILACT   ; MT_VILE = 03h
db 0            ; MT_FIRE = 04h
db SFX_SKEACT   ; MT_UNDEAD = 05h
db 0            ; MT_TRACER = 06h
db 0            ; MT_SMOKE = 07h
db SFX_POSACT   ; MT_FATSO = 08h
db 0            ; MT_FATSHOT = 09h
db SFX_POSACT   ; MT_CHAINGUY = 0Ah
db SFX_BGACT    ; MT_TROOP = 0Bh
db SFX_DMACT    ; MT_SERGEANT = 0Ch
db SFX_DMACT    ; MT_SHADOWS = 0Dh
db SFX_DMACT    ; MT_HEAD = 0Eh
db SFX_DMACT    ; MT_BRUISER = 0Fh
db 0            ; MT_BRUISERSHOT = 010h
db SFX_DMACT    ; MT_KNIGHT = 011h
db SFX_DMACT    ; MT_SKULL = 012h
db SFX_DMACT    ; MT_SPIDER = 013h
db SFX_BSPACT   ; MT_BABY = 014h
db SFX_DMACT    ; MT_CYBORG = 015h
db SFX_DMACT    ; MT_PAIN = 016h
db SFX_POSACT   ; MT_WOLFSS = 017h

PROC    getActiveSound_ NEAR 
PUBLIC  getActiveSound_


dec    al
cmp    al, (MT_WOLFSS - 1)
ja     active_sound_default
cbw
push   bx
mov    bx, ax
mov    al, byte ptr cs:[bx + _active_sound_lookup]
pop    bx
ret   

active_sound_default:
xor    ax, ax
ret   

ENDP

_pain_sound_lookup:

db SFX_PLPAIN ; MT_PLAYER = 00h
db SFX_POPAIN ; MT_POSSESSED = 01h
db SFX_POPAIN ; MT_SHOTGUY = 02h
db SFX_VIPAIN ; MT_VILE = 03h
db 0          ; MT_FIRE = 04h
db SFX_POPAIN ; MT_UNDEAD = 05h
db 0          ; MT_TRACER = 06h
db 0          ; MT_SMOKE = 07h
db SFX_MNPAIN ; MT_FATSO = 08h
db 0          ; MT_FATSHOT = 09h
db SFX_POPAIN ; MT_CHAINGUY = 0Ah
db SFX_POPAIN ; MT_TROOP = 0Bh
db SFX_DMPAIN ; MT_SERGEANT = 0Ch
db SFX_DMPAIN ; MT_SHADOWS = 0Dh
db SFX_DMPAIN ; MT_HEAD = 0Eh
db SFX_DMPAIN ; MT_BRUISER = 0Fh
db 0          ; MT_BRUISERSHOT = 010h
db SFX_DMPAIN ; MT_KNIGHT = 011h
db SFX_DMPAIN ; MT_SKULL = 012h
db SFX_DMPAIN ; MT_SPIDER = 013h
db SFX_DMPAIN ; MT_BABY = 014h
db SFX_DMPAIN ; MT_CYBORG = 015h
db SFX_PEPAIN ; MT_PAIN = 016h
db SFX_POPAIN ; MT_WOLFSS = 017h
db SFX_KEENPN ; MT_KEEN = 018h
db SFX_BOSPN  ; MT_BOSSBRAIN = 019h


PROC    getPainSound_ NEAR 
PUBLIC  getPainSound_


0x0000000000000285:  3C 19             cmp    al, MT_BOSSBRAIN
0x0000000000000287:  77 2B             ja     pain_sound_default
0x0000000000000289:  30 E4             cbw
0x0000000000000284:  53                push   bx
0x000000000000028b:  89 C3             mov    bx, ax
0x000000000000028f:  2E FF A7 50 02    mov    al, byte ptr cs:[bx + _pain_sound_lookup]
0x0000000000000296:  5B                pop    bx

pain_sound_default:
0x00000000000002b4:  30 C0             xor    ax, ax
0x00000000000002b7:  CB                ret 

EDNP

PROC    getAttackSound_ NEAR 
PUBLIC  getAttackSound_


0x00000000000002b8:  3C 0C             cmp    al, MT_SERGEANT
0x00000000000002ba:  73 05             jae    attackabove12
0x00000000000002bc:  3C 01             cmp    al, MT_POSSESSED
0x00000000000002be:  75 16             jne    attack_sound_default
0x00000000000002c0:  CB                ret   
attackabove12:
0x00000000000002c1:  3C 0D             cmp    al, MT_SHADOWS
0x00000000000002c3:  76 0B             jbe    attack_sound_sgtatk
0x00000000000002c5:  3C 12             cmp    al, MT_SKULL
0x00000000000002c7:  74 0A             je     attack_sound_shotgun
0x00000000000002c9:  3C 11             cmp    al, MT_KNIGHT
0x00000000000002cb:  75 09             jne    attack_sound_default
0x00000000000002cd:  B0 33             mov    al, SFX_SKLATK
0x00000000000002cf:  CB                ret   
attack_sound_sgtatk:
0x00000000000002d0:  B0 34             mov    al, SFX_SGTATK
0x00000000000002d2:  CB                ret   
attack_sound_shotgun:
0x00000000000002d3:  B0 02             mov    al, SFX_SHOTGN
0x00000000000002d5:  CB                ret   
attack_sound_default:
damage_default:
0x00000000000002d6:  30 C0             xor    al, al
0x00000000000002d8:  CB                ret   

ENDP

PROC    getDamage_ NEAR 
PUBLIC  getDamage_


0x00000000000002da:  3C 1F             cmp    al, MT_TROOPSHOT
0x00000000000002dc:  73 0F             jae    damage_type_above_30
0x00000000000002de:  3C 10             cmp    al, MT_BRUISERSHOT
0x00000000000002e0:  73 25             jae    damage_type_above_16
0x00000000000002e2:  3C 09             cmp    al, MT_FATSHOT
0x00000000000002e4:  74 2E             je     damage_is_8
0x00000000000002e6:  3C 06             cmp    al, MT_TRACER
0x00000000000002e8:  75 EC             jne    damage_default
0x00000000000002ea:  B0 0A             mov    al, 10
0x00000000000002ec:  CB                ret   
damage_type_above_30:
0x00000000000002ed:  76 22             jbe    damage_is_3
0x00000000000002ef:  3C 22             cmp    al, MT_PLASMA
0x00000000000002f1:  73 07             jae    damage_type_above_34
0x00000000000002f3:  3C 21             cmp    al, MT_ROCKET
0x00000000000002f5:  75 20             jne    damage_is_5
0x00000000000002f7:  B0 14             mov    al, MT_BABY
0x00000000000002f9:  CB                ret   
damage_type_above_34:
0x00000000000002fa:  76 1B             jbe    damage_is_5
0x00000000000002fc:  3C 24             cmp    al, MT_ARACHPLAZ
0x00000000000002fe:  74 17             je     damage_is_5
0x0000000000000300:  3C 23             cmp    al, MT_BFG
0x0000000000000302:  75 D2             jne    damage_default
0x0000000000000304:  B0 64             mov    al, 100
0x0000000000000306:  CB                ret   
damage_type_above_16:
0x0000000000000307:  76 0B             jbe    damage_is_8
0x0000000000000309:  3C 1C             cmp    al, MT_SPAWNSHOT
0x000000000000030b:  74 04             je     damage_is_3
0x000000000000030d:  3C 12             cmp    al, MT_SKULL
0x000000000000030f:  75 C5             jne    damage_default
damage_is_3:
0x0000000000000311:  B0 03             mov    al, 3
0x0000000000000313:  CB                ret   
damage_is_8:
0x0000000000000314:  B0 08             mov    al, 8
0x0000000000000316:  CB                ret   
damage_is_5:
0x0000000000000317:  B0 05             mov    al, 5
0x0000000000000319:  CB                ret   

ENDP

_see_state_lookup:
dw S_PLAY_RUN    ; MT_PLAYER = 00h
dw S_POSS_RUN1   ; MT_POSSESSED = 01h
dw S_SPOS_RUN1   ; MT_SHOTGUY = 02h
dw S_VILE_RUN1   ; MT_VILE = 03h
dw 0             ; MT_FIRE = 04h
dw S_SKEL_RUN1   ; MT_UNDEAD = 05h
dw 0             ; MT_TRACER = 06h
dw 0             ; MT_SMOKE = 07h
dw S_FATT_RUN1   ; MT_FATSO = 08h
dw 0             ; MT_FATSHOT = 09h
dw S_CPOS_RUN1   ; MT_CHAINGUY = 0Ah
dw S_TROO_RUN1   ; MT_TROOP = 0Bh
dw S_SARG_RUN1   ; MT_SERGEANT = 0Ch
dw S_SARG_RUN1   ; MT_SHADOWS = 0Dh
dw S_HEAD_RUN1   ; MT_HEAD = 0Eh
dw S_BOSS_RUN1   ; MT_BRUISER = 0Fh
dw 0             ; MT_BRUISERSHOT = 010h
dw S_BOS2_RUN1   ; MT_KNIGHT = 011h
dw S_SKULL_RUN1  ; MT_SKULL = 012h
dw S_SPID_RUN1   ; MT_SPIDER = 013h
dw S_BSPI_SIGHT  ; MT_BABY = 014h
dw S_CYBER_RUN1  ; MT_CYBORG = 015h
dw S_PAIN_RUN1   ; MT_PAIN = 016h
dw S_SSWV_RUN1   ; MT_WOLFSS = 017h
dw 0             ; MT_KEEN = 018h
dw 0             ; MT_BOSSBRAIN = 019h
dw S_BRAINEYESEE ; MT_BOSSSPIT = 01Ah

PROC    getSeeState_ NEAR 
PUBLIC  getSeeState_

cmp    al, MT_BOSSSPIT
ja     see_state_default
cbw
push   bx
mov    bx, ax
sal    bx, 1
mov    ax, word ptr cs:[bx + _see_state_lookup]
pop    bx
ret   


see_state_default:
xor    ax, ax
ret   

ENDP

_missile_state_lookup:

dw S_PLAY_ATK1  ; MT_PLAYER = 00h
dw S_POSS_ATK1  ; MT_POSSESSED = 0
dw S_SPOS_ATK1  ; MT_SHOTGUY = 02h
dw S_VILE_ATK1  ; MT_VILE = 03h
dw 0            ; MT_FIRE = 04h
dw S_SKEL_MISS1 ; MT_UNDEAD = 05h
dw 0            ; MT_TRACER = 06h
dw 0            ; MT_SMOKE = 07h
dw S_FATT_ATK1  ; MT_FATSO = 08h
dw 0            ; MT_FATSHOT = 09h
dw S_CPOS_ATK1  ; MT_CHAINGUY = 0A
dw S_TROO_ATK1  ; MT_TROOP = 0Bh
dw 0            ; MT_SERGEANT = 0C
dw 0            ; MT_SHADOWS = 0Dh
dw S_HEAD_ATK1  ; MT_HEAD = 0Eh
dw S_BOSS_ATK1  ; MT_BRUISER = 0Fh
dw 0            ; MT_BRUISERSHOT =
dw S_BOS2_ATK1  ; MT_KNIGHT = 011h
dw S_SKULL_ATK1 ; MT_SKULL = 012h
dw S_SPID_ATK1  ; MT_SPIDER = 013h
dw S_BSPI_ATK1  ; MT_BABY = 014h
dw S_CYBER_ATK1 ; MT_CYBORG = 015h
dw S_PAIN_ATK1  ; MT_PAIN = 016h
dw S_SSWV_ATK1  ; MT_WOLFSS = 017h


PROC    getMissileState_ NEAR 
PUBLIC  getMissileState_


0x00000000000003f5:  3C 17             cmp    al, MT_WOLFSS
0x00000000000003f7:  77 60             ja     missile_state_default
0x00000000000003f4:  53                push   bx
0x00000000000003f9:  30 E4             cbw
0x00000000000003fb:  89 C3             xchg   ax, bx
0x00000000000003fd:  01 C3             sal    bx, 1
0x00000000000003ff:  2E FF A7 C4 03    mov    ax, word ptr cs:[bx + _missile_state_lookup]


missile_state_default:
0x0000000000000459:  31 C0             xor    ax, ax
0x000000000000045c:  CB                ret   

ENDP

_death_state_lookup:

dw 004B8h
dw 004BDh
dw 004C2h
dw 004C7h
dw 00517h
dw 004CCh
dw 004D1h
dw 00517h
dw 004D6h
dw 004DBh
dw 004E0h
dw 004E5h
dw 004EAh
dw 004EAh
dw 004EFh
dw 004F4h
dw 004F9h
dw 004FEh
dw 00503h
dw 00508h
dw 0050Dh
dw 00512h
dw 0051Bh
dw 00520h
dw 00525h
dw 0052Ah
dw 00517h
dw 00517h
dw 00517h
dw 00517h
dw 0052Fh
dw 00534h
dw 00539h
dw 0053Eh
dw 00543h
dw 00548h
dw 0054Dh

PROC    getDeathState_ NEAR 
PUBLIC  getDeathState_



0x00000000000004a8:  53                push   bx
0x00000000000004a9:  3C 24             cmp    al, 36
0x00000000000004ab:  77 6A             ja     death_state_default
0x00000000000004ad:  30 E4             cbw
0x00000000000004af:  89 C3             mov    bx, ax
0x00000000000004b1:  01 C3             sal    bx, 1
0x00000000000004b3:  2E FF A7 5E 04    jmp    word ptr cs:[bx + _death_state_lookup]
0x00000000000004b8:  B8 9E 00          mov    ax, S_PLAY_DIE1
0x00000000000004bb:  5B                pop    bx
0x00000000000004bc:  CB                ret   
0x00000000000004bd:  B8 BD 00          mov    ax, S_POSS_DIE1
0x00000000000004c0:  5B                pop    bx
0x00000000000004c1:  CB                ret   
0x00000000000004c2:  B8 DE 00          mov    ax, S_SPOS_DIE1
0x00000000000004c5:  5B                pop    bx
0x00000000000004c6:  CB                ret   
0x00000000000004c7:  B8 0F 01          mov    ax, S_VILE_DIE1
0x00000000000004ca:  5B                pop    bx
0x00000000000004cb:  CB                ret   
0x00000000000004cc:  B8 59 01          mov    ax, S_SKEL_DIE1
0x00000000000004cf:  5B                pop    bx
0x00000000000004d0:  CB                ret   
0x00000000000004d1:  B8 3E 01          mov    ax, S_TRACEEXP1
0x00000000000004d4:  5B                pop    bx
0x00000000000004d5:  CB                ret   
0x00000000000004d6:  B8 84 01          mov    ax, S_FATT_DIE1
0x00000000000004d9:  5B                pop    bx
0x00000000000004da:  CB                ret   
0x00000000000004db:  B8 67 01          mov    ax, S_FATSHOTX1
0x00000000000004de:  5B                pop    bx
0x00000000000004df:  CB                ret   
0x00000000000004e0:  B8 A6 01          mov    ax, S_CPOS_DIE1
0x00000000000004e3:  5B                pop    bx
0x00000000000004e4:  CB                ret   
0x00000000000004e5:  B8 C9 01          mov    ax, S_TROO_DIE1
0x00000000000004e8:  5B                pop    bx
0x00000000000004e9:  CB                ret   
0x00000000000004ea:  B8 EA 01          mov    ax, S_SARG_DIE1
0x00000000000004ed:  5B                pop    bx
0x00000000000004ee:  CB                ret   
0x00000000000004ef:  B8 FE 01          mov    ax, S_HEAD_DIE1
0x00000000000004f2:  5B                pop    bx
0x00000000000004f3:  CB                ret   
0x00000000000004f4:  B8 1E 02          mov    ax, S_BOSS_DIE1
0x00000000000004f7:  5B                pop    bx
0x00000000000004f8:  CB                ret   
0x00000000000004f9:  B8 0C 02          mov    ax, S_BRBALLX1
0x00000000000004fc:  5B                pop    bx
0x00000000000004fd:  CB                ret   
0x00000000000004fe:  B8 3B 02          mov    ax, S_BOS2_DIE1
0x0000000000000501:  5B                pop    bx
0x0000000000000502:  CB                ret   
0x0000000000000503:  B8 53 02          mov    ax, S_SKULL_DIE1
0x0000000000000506:  5B                pop    bx
0x0000000000000507:  CB                ret   
0x0000000000000508:  B8 6D 02          mov    ax, S_SPID_DIE1
0x000000000000050b:  5B                pop    bx
0x000000000000050c:  CB                ret   
0x000000000000050d:  B8 8D 02          mov    ax, S_BSPI_DIE1
0x0000000000000510:  5B                pop    bx
0x0000000000000511:  CB                ret   
0x0000000000000512:  B8 B3 02          mov    ax, S_CYBER_DIE1
0x0000000000000515:  5B                pop    bx
0x0000000000000516:  CB                ret   
death_state_default:
0x0000000000000517:  31 C0             xor    ax, ax
0x0000000000000519:  5B                pop    bx
0x000000000000051a:  CB                ret   
0x000000000000051b:  B8 CA 02          mov    ax, S_PAIN_DIE1
0x000000000000051e:  5B                pop    bx
0x000000000000051f:  CB                ret   
0x0000000000000520:  B8 E8 02          mov    ax, S_SSWV_DIE1
0x0000000000000523:  5B                pop    bx
0x0000000000000524:  CB                ret   
0x0000000000000525:  B8 FC 02          mov    ax, S_COMMKEEN
0x0000000000000528:  5B                pop    bx
0x0000000000000529:  CB                ret   
0x000000000000052a:  B8 0C 03          mov    ax, S_BRAIN_DIE1
0x000000000000052d:  5B                pop    bx
0x000000000000052e:  CB                ret   
0x000000000000052f:  B8 28 03          mov    ax, S_BEXP
0x0000000000000532:  5B                pop    bx
0x0000000000000533:  CB                ret   
0x0000000000000534:  B8 63 00          mov    ax, S_TBALLX1
0x0000000000000537:  5B                pop    bx
0x0000000000000538:  CB                ret   
0x0000000000000539:  B8 68 00          mov    ax, S_RBALLX1
0x000000000000053c:  5B                pop    bx
0x000000000000053d:  CB                ret   
0x000000000000053e:  B8 7F 00          mov    ax, S_EXPLODE1
0x0000000000000541:  5B                pop    bx
0x0000000000000542:  CB                ret   
0x0000000000000543:  B8 6D 00          mov    ax, S_PLASEXP
0x0000000000000546:  5B                pop    bx
0x0000000000000547:  CB                ret   
0x0000000000000548:  B8 75 00          mov    ax, S_BFGLAND
0x000000000000054b:  5B                pop    bx
0x000000000000054c:  CB                ret   
0x000000000000054d:  B8 9D 02          mov    ax, S_ARACH_PLEX
0x0000000000000550:  5B                pop    bx
0x0000000000000551:  CB                ret   

ENDP

_pain_state_lookup:

dw 00596h
dw 0059Bh
dw 005A0h
dw 005A5h
dw 005F5h
dw 005AAh
dw 005F5h
dw 005F5h
dw 005AFh
dw 005F5h
dw 005B4h
dw 005B9h
dw 005BEh
dw 005BEh
dw 005C3h
dw 005C8h
dw 005F5h
dw 005CDh
dw 005D2h
dw 005D7h
dw 005DCh
dw 005E1h
dw 005E6h
dw 005EBh
dw 005F0h
dw 005F9h

PROC    getPainState_ NEAR 
PUBLIC  getPainState_


0x0000000000000586:  53                push   bx
0x0000000000000587:  3C 19             cmp    al, 25
0x0000000000000589:  77 6A             ja     pain_state_default
0x000000000000058b:  30 E4             cbw
0x000000000000058d:  89 C3             mov    bx, ax
0x000000000000058f:  01 C3             sal    bx, 1
0x0000000000000591:  2E FF A7 52 05    jmp    word ptr cs:[bx + _pain_state_lookup]
0x0000000000000596:  B8 9C 00          mov    ax, S_PLAY_PAIN
0x0000000000000599:  5B                pop    bx
0x000000000000059a:  CB                ret   
0x000000000000059b:  B8 BB 00          mov    ax, S_POSS_PAIN
0x000000000000059e:  5B                pop    bx
0x000000000000059f:  CB                ret   
0x00000000000005a0:  B8 DC 00          mov    ax, S_SPOS_PAIN
0x00000000000005a3:  5B                pop    bx
0x00000000000005a4:  CB                ret   
0x00000000000005a5:  B8 0D 01          mov    ax, S_VILE_PAIN
0x00000000000005a8:  5B                pop    bx
0x00000000000005a9:  CB                ret   
0x00000000000005aa:  B8 57 01          mov    ax, S_SKEL_PAIN
0x00000000000005ad:  5B                pop    bx
0x00000000000005ae:  CB                ret   
0x00000000000005af:  B8 82 01          mov    ax, S_FATT_PAIN
0x00000000000005b2:  5B                pop    bx
0x00000000000005b3:  CB                ret   
0x00000000000005b4:  B8 A4 01          mov    ax, S_CPOS_PAIN
0x00000000000005b7:  5B                pop    bx
0x00000000000005b8:  CB                ret   
0x00000000000005b9:  B8 C7 01          mov    ax, S_TROO_PAIN
0x00000000000005bc:  5B                pop    bx
0x00000000000005bd:  CB                ret   
0x00000000000005be:  B8 E8 01          mov    ax, S_SARG_PAIN
0x00000000000005c1:  5B                pop    bx
0x00000000000005c2:  CB                ret   
0x00000000000005c3:  B8 FB 01          mov    ax, S_HEAD_PAIN
0x00000000000005c6:  5B                pop    bx
0x00000000000005c7:  CB                ret   
0x00000000000005c8:  B8 1C 02          mov    ax, S_BOSS_PAIN
0x00000000000005cb:  5B                pop    bx
0x00000000000005cc:  CB                ret   
0x00000000000005cd:  B8 39 02          mov    ax, S_BOS2_PAIN
0x00000000000005d0:  5B                pop    bx
0x00000000000005d1:  CB                ret   
0x00000000000005d2:  B8 51 02          mov    ax, S_SKULL_PAIN
0x00000000000005d5:  5B                pop    bx
0x00000000000005d6:  CB                ret   
0x00000000000005d7:  B8 6B 02          mov    ax, S_SPID_PAIN
0x00000000000005da:  5B                pop    bx
0x00000000000005db:  CB                ret   
0x00000000000005dc:  B8 8B 02          mov    ax, S_BSPI_PAIN
0x00000000000005df:  5B                pop    bx
0x00000000000005e0:  CB                ret   
0x00000000000005e1:  B8 B2 02          mov    ax, S_CYBER_PAIN
0x00000000000005e4:  5B                pop    bx
0x00000000000005e5:  CB                ret   
0x00000000000005e6:  B8 C8 02          mov    ax, S_PAIN_PAIN
0x00000000000005e9:  5B                pop    bx
0x00000000000005ea:  CB                ret   
0x00000000000005eb:  B8 E6 02          mov    ax, S_SSWV_PAIN
0x00000000000005ee:  5B                pop    bx
0x00000000000005ef:  CB                ret   
0x00000000000005f0:  B8 08 03          mov    ax, S_KEENPAIN
0x00000000000005f3:  5B                pop    bx
0x00000000000005f4:  CB                ret   
pain_state_default:
0x00000000000005f5:  31 C0             xor    ax, ax
0x00000000000005f7:  5B                pop    bx
0x00000000000005f8:  CB                ret   
0x00000000000005f9:  B8 0B 03          mov    ax, S_BRAIN_PAIN
0x00000000000005fc:  5B                pop    bx
0x00000000000005fd:  CB                ret  

ENDP

_spawn_health_lookup:

dw 0064Ch
dw 00651h
dw 00656h
dw 0065Bh
dw 00660h
dw 00665h
dw 00660h
dw 00660h
dw 0066Ah
dw 00660h
dw 0066Fh
dw 00674h
dw 00679h
dw 00679h
dw 0067Eh
dw 00660h
dw 00660h
dw 00683h
dw 0064Ch
dw 00688h
dw 00683h
dw 0068Dh
dw 0067Eh
dw 00692h
dw 0064Ch
dw 00697h
dw 00660h
dw 00660h
dw 00660h
dw 00660h
dw 00651h


PROC    getSpawnHealth_ NEAR 
PUBLIC  getSpawnHealth_


0x000000000000063c:  53                push   bx
0x000000000000063d:  3C 1E             cmp    al, 30
0x000000000000063f:  77 1F             ja     spawn_health_default
0x0000000000000641:  30 E4             cbw
0x0000000000000643:  89 C3             mov    bx, ax
0x0000000000000645:  01 C3             sal    bx, 1
0x0000000000000647:  2E FF A7 FE 05    jmp    word ptr cs:[bx + _spawn_health_lookup]
0x000000000000064c:  B8 64 00          mov    ax, 100
0x000000000000064f:  5B                pop    bx
0x0000000000000650:  CB                ret   
0x0000000000000651:  B8 14 00          mov    ax, 20
0x0000000000000654:  5B                pop    bx
0x0000000000000655:  CB                ret   
0x0000000000000656:  B8 1E 00          mov    ax, 30
0x0000000000000659:  5B                pop    bx
0x000000000000065a:  CB                ret   
0x000000000000065b:  B8 BC 02          mov    ax, 700
0x000000000000065e:  5B                pop    bx
0x000000000000065f:  CB                ret   
spawn_health_default:
0x0000000000000660:  B8 E8 03          mov    ax, 1000
0x0000000000000663:  5B                pop    bx
0x0000000000000664:  CB                ret   
0x0000000000000665:  B8 2C 01          mov    ax, 300
0x0000000000000668:  5B                pop    bx
0x0000000000000669:  CB                ret   
0x000000000000066a:  B8 58 02          mov    ax, 600
0x000000000000066d:  5B                pop    bx
0x000000000000066e:  CB                ret   
0x000000000000066f:  B8 46 00          mov    ax, 70
0x0000000000000672:  5B                pop    bx
0x0000000000000673:  CB                ret   
0x0000000000000674:  B8 3C 00          mov    ax, 60
0x0000000000000677:  5B                pop    bx
0x0000000000000678:  CB                ret   
0x0000000000000679:  B8 96 00          mov    ax, 150
0x000000000000067c:  5B                pop    bx
0x000000000000067d:  CB                ret   
0x000000000000067e:  B8 90 01          mov    ax, 400
0x0000000000000681:  5B                pop    bx
0x0000000000000682:  CB                ret   
0x0000000000000683:  B8 F4 01          mov    ax, 500
0x0000000000000686:  5B                pop    bx
0x0000000000000687:  CB                ret   
0x0000000000000688:  B8 B8 0B          mov    ax, 3000
0x000000000000068b:  5B                pop    bx
0x000000000000068c:  CB                ret   
0x000000000000068d:  B8 A0 0F          mov    ax, 4000
0x0000000000000690:  5B                pop    bx
0x0000000000000691:  CB                ret   
0x0000000000000692:  B8 32 00          mov    ax, 50
0x0000000000000695:  5B                pop    bx
0x0000000000000696:  CB                ret   
0x0000000000000697:  B8 FA 00          mov    ax, 250
0x000000000000069a:  5B                pop    bx
0x000000000000069b:  CB                ret  

ENDP

PROC    P_INFO_ENDMARKER_ 
PUBLIC  P_INFO_ENDMARKER_
ENDP

END