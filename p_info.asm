
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


cmp    al, MT_SHOTGUY
jae    xd_ae_2
cmp    al, MT_POSSESSED
je     xd_possessed
test   al, al
jne    xdeath_state_default
mov    ax, S_PLAY_XDIE1
ret   
xd_ae_2:
jbe    xd_shotguy
cmp    al, MT_WOLFSS
je     xd_wolfss
cmp    al, MT_TROOP
je     xd_chainguy
cmp    al, MT_CHAINGUY
jne    xdeath_state_default
mov    ax, S_CPOS_XDIE1
ret   
xd_possessed:
mov    ax, S_POSS_XDIE1
ret   
xd_shotguy:
mov    ax, S_SPOS_XDIE1
ret   
xd_chainguy:
mov    ax, S_TROO_XDIE1
ret   
xd_wolfss:
mov    ax, S_SSWV_XDIE1
ret   
xdeath_state_default:
xor    ax, ax
ret   

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


cmp    al, MT_BOSSBRAIN
ja     pain_sound_default
cbw
push   bx
mov    bx, ax
mov    al, byte ptr cs:[bx + _pain_sound_lookup]
pop    bx

pain_sound_default:
xor    ax, ax
ret 

EDNP

PROC    getAttackSound_ NEAR 
PUBLIC  getAttackSound_


cmp    al, MT_SERGEANT
jae    attackabove12
cmp    al, MT_POSSESSED
jne    attack_sound_default
ret   
attackabove12:
cmp    al, MT_SHADOWS
jbe    attack_sound_sgtatk
cmp    al, MT_SKULL
je     attack_sound_shotgun
cmp    al, MT_KNIGHT
jne    attack_sound_default
mov    al, SFX_SKLATK
ret   
attack_sound_sgtatk:
mov    al, SFX_SGTATK
ret   
attack_sound_shotgun:
mov    al, SFX_SHOTGN
ret   
attack_sound_default:
damage_default:
xor    al, al
ret   

ENDP

PROC    getDamage_ NEAR 
PUBLIC  getDamage_


cmp    al, MT_TROOPSHOT
jae    damage_type_above_30
cmp    al, MT_BRUISERSHOT
jae    damage_type_above_16
cmp    al, MT_FATSHOT
je     damage_is_8
cmp    al, MT_TRACER
jne    damage_default
mov    al, 10
ret   
damage_type_above_30:
jbe    damage_is_3
cmp    al, MT_PLASMA
jae    damage_type_above_34
cmp    al, MT_ROCKET
jne    damage_is_5
mov    al, MT_BABY
ret   
damage_type_above_34:
jbe    damage_is_5
cmp    al, MT_ARACHPLAZ
je     damage_is_5
cmp    al, MT_BFG
jne    damage_default
mov    al, 100
ret   
damage_type_above_16:
jbe    damage_is_8
cmp    al, MT_SPAWNSHOT
je     damage_is_3
cmp    al, MT_SKULL
jne    damage_default
damage_is_3:
mov    al, 3
ret   
damage_is_8:
mov    al, 8
ret   
damage_is_5:
mov    al, 5
ret   

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


cmp    al, MT_WOLFSS
ja     missile_state_default
push   bx
cbw
xchg   ax, bx
sal    bx, 1
mov    ax, word ptr cs:[bx + _missile_state_lookup]

missile_state_default:
xor    ax, ax
ret   

ENDP

_death_state_lookup:

dw S_PLAY_DIE1   ; MT_PLAYER = 00h
dw S_POSS_DIE1   ; MT_POSSESSED = 01h
dw S_SPOS_DIE1   ; MT_SHOTGUY = 02h
dw S_VILE_DIE1   ; MT_VILE = 03h
dw 0             ; MT_FIRE = 04h
dw S_SKEL_DIE1   ; MT_UNDEAD = 05h
dw S_TRACEEXP1   ; MT_TRACER = 06h
dw 0             ; MT_SMOKE = 07h
dw S_FATT_DIE1   ; MT_FATSO = 08h
dw S_FATSHOTX1   ; MT_FATSHOT = 09h
dw S_CPOS_DIE1   ; MT_CHAINGUY = 0Ah
dw S_TROO_DIE1   ; MT_TROOP = 0Bh
dw S_SARG_DIE1   ; MT_SERGEANT = 0Ch
dw S_SARG_DIE1   ; MT_SHADOWS = 0Dh
dw S_HEAD_DIE1   ; MT_HEAD = 0Eh
dw S_BOSS_DIE1   ; MT_BRUISER = 0Fh
dw S_BRBALLX1    ; MT_BRUISERSHOT = 010h
dw S_BOS2_DIE1   ; MT_KNIGHT = 011h
dw S_SKULL_DIE1  ; MT_SKULL = 012h
dw S_SPID_DIE1   ; MT_SPIDER = 013h
dw S_BSPI_DIE1   ; MT_BABY = 014h
dw S_CYBER_DIE1  ; MT_CYBORG = 015h
dw S_PAIN_DIE1   ; MT_PAIN = 016h
dw S_SSWV_DIE1   ; MT_WOLFSS = 017h
dw S_COMMKEEN    ; MT_KEEN = 018h
dw S_BRAIN_DIE1  ; MT_BOSSBRAIN = 019h
dw 0             ; MT_BOSSSPIT = 01Ah
dw 0             ; MT_BOSSTARGET = 01Bh
dw 0             ; MT_SPAWNSHOT = 01Ch
dw 0             ; MT_SPAWNFIRE = 01Dh
dw S_BEXP        ; MT_BARREL = 01Eh
dw S_TBALLX1     ; MT_TROOPSHOT = 01Fh
dw S_RBALLX1     ; MT_HEADSHOT = 020h
dw S_EXPLODE1    ; MT_ROCKET = 021h
dw S_PLASEXP     ; MT_PLASMA = 022h
dw S_BFGLAND     ; MT_BFG = 023h
dw S_ARACH_PLEX  ; MT_ARACHPLAZ = 024h

PROC    getDeathState_ NEAR 
PUBLIC  getDeathState_



cmp    al, MT_ARACHPLAZ
ja     death_state_default
push   bx
cbw
xchg   ax, bx
sal    bx, 1
mov    ax, word ptr cs:[bx + _death_state_lookup]
pop    bx
ret   
death_state_default:
xor    ax, ax
ret   


ENDP

_pain_state_lookup:

dw S_PLAY_PAIN   ; MT_PLAYER = 00h
dw S_POSS_PAIN   ; MT_POSSESSED = 01h
dw S_SPOS_PAIN   ; MT_SHOTGUY = 02h
dw S_VILE_PAIN   ; MT_VILE = 03h
dw 0             ; MT_FIRE = 04h
dw S_SKEL_PAIN   ; MT_UNDEAD = 05h
dw 0             ; MT_TRACER = 06h
dw 0             ; MT_SMOKE = 07h
dw S_FATT_PAIN   ; MT_FATSO = 08h
dw 0             ; MT_FATSHOT = 09h
dw S_CPOS_PAIN   ; MT_CHAINGUY = 0Ah
dw S_TROO_PAIN   ; MT_TROOP = 0Bh
dw S_SARG_PAIN   ; MT_SERGEANT = 0Ch
dw S_SARG_PAIN   ; MT_SHADOWS = 0Dh
dw S_HEAD_PAIN   ; MT_HEAD = 0Eh
dw S_BOSS_PAIN   ; MT_BRUISER = 0Fh
dw 0             ; MT_BRUISERSHOT = 010h
dw S_BOS2_PAIN   ; MT_KNIGHT = 011h
dw S_SKULL_PAIN  ; MT_SKULL = 012h
dw S_SPID_PAIN   ; MT_SPIDER = 013h
dw S_BSPI_PAIN   ; MT_BABY = 014h
dw S_CYBER_PAIN  ; MT_CYBORG = 015h
dw S_PAIN_PAIN   ; MT_PAIN = 016h
dw S_SSWV_PAIN   ; MT_WOLFSS = 017h
dw S_KEENPAIN    ; MT_KEEN = 018h
dw S_BRAIN_PAIN  ; MT_BOSSBRAIN = 019h

PROC    getPainState_ NEAR 
PUBLIC  getPainState_


cmp    al, MT_BOSSBRAIN
ja     pain_state_default
push   bx
cbw
xchg   ax, bx
sal    bx, 1
mov    ax, word ptr cs:[bx + _pain_state_lookup]
pop    bx
ret   
pain_state_default:
xor    ax, ax
ret   

ENDP

_spawn_health_lookup:

dw 100  ; MT_PLAYER = 00h
dw 20   ; MT_POSSESSED = 01h
dw 30   ; MT_SHOTGUY = 02h
dw 700  ; MT_VILE = 03h
dw 1000 ; MT_FIRE = 04h
dw 300  ; MT_UNDEAD = 05h
dw 1000 ; MT_TRACER = 06h
dw 1000 ; MT_SMOKE = 07h
dw 600  ; MT_FATSO = 08h
dw 1000 ; MT_FATSHOT = 09h
dw 70   ; MT_CHAINGUY = 0Ah
dw 60   ; MT_TROOP = 0Bh
dw 150  ; MT_SERGEANT = 0Ch
dw 150  ; MT_SHADOWS = 0Dh
dw 400  ; MT_HEAD = 0Eh
dw 1000 ; MT_BRUISER = 0Fh
dw 1000 ; MT_BRUISERSHOT = 010h
dw 500  ; MT_KNIGHT = 011h
dw 100  ; MT_SKULL = 012h
dw 3000 ; MT_SPIDER = 013h
dw 500  ; MT_BABY = 014h
dw 4000 ; MT_CYBORG = 015h
dw 400  ; MT_PAIN = 016h
dw 50   ; MT_WOLFSS = 017h
dw 100  ; MT_KEEN = 018h
dw 250  ; MT_BOSSBRAIN = 019h
dw 1000 ; MT_BOSSSPIT = 01Ah
dw 1000 ; MT_BOSSTARGET = 01Bh
dw 1000 ; MT_SPAWNSHOT = 01Ch
dw 1000 ; MT_SPAWNFIRE = 01Dh
dw 20   ; MT_BARREL = 01Eh


PROC    getSpawnHealth_ NEAR 
PUBLIC  getSpawnHealth_


push   bx
cmp    al, MT_BARREL
ja     spawn_health_default
cbw
xchg   ax, bx
sal    bx, 1
mov    ax, word ptr cs:[bx + _spawn_health_lookup]
pop    bx
ret   

spawn_health_default:
mov    ax, 1000
ret   

ENDP

PROC    P_INFO_ENDMARKER_ 
PUBLIC  P_INFO_ENDMARKER_
ENDP

END