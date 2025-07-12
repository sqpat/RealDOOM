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


; hack but oh well
P_SIGHT_STARTMARKER_ = 0 

EXTRN S_StartSound_:PROC
EXTRN P_DamageMobj_:PROC
EXTRN P_SetMobjState_:PROC
EXTRN P_SpawnMobj_:PROC
EXTRN P_Random_:NEAR
EXTRN R_PointToAngle2_:PROC
EXTRN FixedMulTrig_:PROC
EXTRN P_NoiseAlert_:NEAR

.DATA

EXTRN _weaponinfo:WORD
EXTRN _bulletslope:DWORD
EXTRN _P_AimLineAttack:DWORD
EXTRN _P_SpawnPlayerMissile:DWORD
EXTRN _P_LineAttack:DWORD

.CODE



PROC    P_PSPR_STARTMARKER_ 
PUBLIC  P_PSPR_STARTMARKER_
ENDP


PS_WEAPON = 0
PS_FLASH = 1
WEAPONBOTTOM_HIGH = 128
WEAPONBOTTOM_LOW = 0
WEAPONTOP_HIGH = 32
WEAPONTOP_LOW = 0

LOWERSPEED_HIGH = 6
LOWERSPEED_LOW  = 0

RAISESPEED_HIGH = 6
RAISESPEED_LOW  = 0

FINE_ANG90 = 0800h
ANG90_FULL = 040000000h
MINUS_ANG90_FULL = 0C0000000h

PST_LIVE = 0    ; Playing or camping.
PST_DEAD = 1    ; Dead on the ground, view follows killer.
PST_REBORN = 2  ; Ready to restart/respawn???

ANGLETOFINESHIFT = 19

; todo constants
WP_FIST = 0
WP_PISTOL = 1
WP_SHOTGUN = 2
WP_CHAINGUN = 3
WP_MISSILE = 4
WP_PLASMA = 5
WP_BFG = 6
WP_CHAINSAW = 7
WP_SUPERSHOTGUN = 8
WP_NOCHANGE = 0Ah

BFGCELLS = 40


FINEMASK = 01FFFh


AM_CLIP = 0	 ; Pistol / chaingun ammo.
AM_SHELL = 1 ; Shotgun / double barreled shotgun.
AM_CELL = 2  ; Plasma rifle, BFG.
AM_MISL = 3	 ; Missile launcher.
NUMAMMO = 4
AM_NOAMMO = 5	 ; Unlimited for chainsaw / fist.	

PROC P_BringUpWeapon_ NEAR
PUBLIC P_BringUpWeapon_
 
push  bx
push  dx
cmp   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_NOCHANGE
je    set_pending_weapon_ready_weapon
check_for_chainsaw_pending:
cmp   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_CHAINSAW
je    rev_chainsaw_noise
pending_weapon_checks_done:
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_pendingweapon]
xchg  ax, bx

mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_upstate]
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_NOCHANGE
xor   ax, ax
mov   word ptr ds:[_psprites + (PS_WEAPON * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy + 0], ax   ; WEAPONBOTTOM_LOW
mov   word ptr ds:[_psprites + (PS_WEAPON * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy + 2], WEAPONBOTTOM_HIGH
call  P_SetPsprite_
pop   dx
pop   bx
ret   
set_pending_weapon_ready_weapon:
mov   al, byte ptr ds:[_player + PLAYER_T.player_readyweapon]
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], al
jmp   check_for_chainsaw_pending
rev_chainsaw_noise:
mov   dx, SFX_SAWUP
mov   ax, word ptr ds:[_playerMobj]
call  S_StartSound_
jmp   pending_weapon_checks_done
ENDP


PROC P_CheckAmmo_ NEAR
PUBLIC P_CheckAmmo_
ENDP
; same func apparently
PROC A_CheckReload_ NEAR 
PUBLIC A_CheckReload_

push  bx
push  dx
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
mov   al, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
cmp   byte ptr ds:[_player + PLAYER_T.player_readyweapon], WP_BFG
jne   readyweapon_not_bfg
mov   dx, BFGCELLS ; use 40 ammo per shot
jmp   count_determined
readyweapon_not_bfg:
cmp   byte ptr ds:[bx], WP_SUPERSHOTGUN
jne   not_super_shotgun
mov   dx, 2 ; use two ammo per shot
jmp   count_determined
not_super_shotgun:
mov   dx, 1  ; use one ammo per shot
count_determined:
; dx has number of ammo to use per shot.
cmp   al, AM_NOAMMO ; this weapon doesn't use ammo
je    passed_ammo_check
xor   ah, ah
sal   ax, 1
xchg  ax, bx
cmp   dx, word ptr ds:[bx + _player + PLAYER_T.player_ammo] ; do we have enough ammo?
jle   passed_ammo_check
; not enough ammo..



xor   ax, ax

; dumb math flow to decide next weapon to change to! 
; NOTE: AL/AX known zero here. used for various checks.
 ; generally checking weapon ownership and then enough ammo to fire a shot, 
 ; and commercial/shareware



cmp   al, byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_PLASMA]       ; plasma owned?
je    cant_use_plasma_rifle
cmp   ax, word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_CELL)]          ; any cells?
je    cant_use_plasma_rifle
cmp   al, byte ptr ds:[_shareware]                                              ; no plasma in shareware
jne   cant_use_plasma_rifle
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_PLASMA          ; pending weapon plasma
jmp   fallback_weapon_attempt_selected
passed_ammo_check:
mov   al, 1  ; true
jmp   exit_check_reload

cant_use_plasma_rifle:
cmp   al, byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_SUPERSHOTGUN] ; ss owned?
je    cant_use_supershotgun
cmp   word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_SHELL)], 2          ; 2 shots per ss
jle   cant_use_supershotgun
cmp   al, byte ptr ds:[_commercial]                                             ; ss only commercial
je    cant_use_supershotgun
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_SUPERSHOTGUN    ; pending weapon ss
jmp   fallback_weapon_attempt_selected

cant_use_supershotgun:
cmp   al, byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_CHAINGUN]     ; chaingun owned?
je    cant_use_chaingun
cmp   ax, word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_CLIP)]          ; any ammo?
je    cant_use_chaingun
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_CHAINGUN        ; pending chaingun
jmp   fallback_weapon_attempt_selected
cant_use_chaingun:
cmp   al, byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_SHOTGUN]      ; shotgun owned?
je    cant_use_shotgun
cmp   ax, word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_SHELL)]         ; any clips?
je    cant_use_shotgun
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_SHOTGUN         ; pending shotgun
jmp   fallback_weapon_attempt_selected

cant_use_shotgun:
cmp   ax, word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_CLIP)]          ; any ammo?
je    cant_use_pistol
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_PISTOL          ; pending pistol
jmp   fallback_weapon_attempt_selected
cant_use_pistol:
cmp   al, byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_CHAINSAW]     ; chainsaw owned?
je    cant_use_chainsaw
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_CHAINSAW        ; pending chaisnaw
jmp   fallback_weapon_attempt_selected

cant_use_chainsaw:
cmp   al, byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_MISSILE]      ; rocket launcher owned?
je    cant_use_rocket
cmp   ax, word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_MISL)]          ; any rockets
je    cant_use_rocket
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_MISSILE         ; pending rocket launcher
jmp   fallback_weapon_attempt_selected
cant_use_rocket:
cmp   al, byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_BFG]          ; bfg owned?
je    cant_use_bfg
cmp   word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_CELL)], BFGCELLS    ; enough cells?
jle   cant_use_bfg
cmp   al, byte ptr ds:[_shareware]                                              ; no bfg in shareware..
jne   cant_use_bfg
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_BFG             ; pending bfg
jmp   fallback_weapon_attempt_selected
cant_use_bfg:
mov   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], al                 ; pending fist... AL is 0
;jmp   fallback_weapon_attempt_selected

fallback_weapon_attempt_selected:


mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx

; pending weapon has been set.
; set state to current weapon's down state.
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_downstate]

xor   ax, ax
call  P_SetPsprite_  ; change weapon anim

xor   ax, ax ; failed ammo check
exit_check_reload:
pop   dx
pop   bx
ret   





ENDP

PROC P_FireWeapon_ NEAR 
PUBLIC P_FireWeapon_


call  A_CheckReload_
test  al, al
jne   do_fire_weapon
ret   
do_fire_weapon:
push  bx
push  dx
mov   dx, S_PLAY_ATK1
mov   ax, word ptr ds:[_playerMobj]
call  P_SetMobjState_
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_atkstate]
xor   ax, ax
call  P_SetPsprite_
call  P_NoiseAlert_
pop   dx
pop   bx
ret   

ENDP

PROC P_DropWeapon_ NEAR
PUBLIC P_DropWeapon_

push  bx
push  dx
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_downstate]
xor   ax, ax
call  P_SetPsprite_
pop   dx
pop   bx
ret   

ENDP

PROC A_WeaponReady_ NEAR
PUBLIC A_WeaponReady_

PUSHA_NO_AX_OR_BP_MACRO
mov   si, ax
; si is pspdef...

les   di, dword ptr ds:[_playerMobj_pos]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_statenum]
cmp   ax, S_PLAY_ATK1
je    use_atk1_or_atk2_state
cmp   ax, S_PLAY_ATK2
jne   dont_use_atk1_or_atk2_state
use_atk1_or_atk2_state:
mov   dx, S_PLAY
mov   ax, word ptr ds:[_playerMobj]
call  P_SetMobjState_
dont_use_atk1_or_atk2_state:

cmp   byte ptr ds:[_player + PLAYER_T.player_readyweapon], WP_CHAINSAW
jne   dont_do_chainsaw_sound
cmp   word ptr ds:[si], S_SAW
jne   dont_do_chainsaw_sound
mov   dx, SFX_SAWIDL
mov   ax, word ptr ds:[_playerMobj]
call  S_StartSound_
dont_do_chainsaw_sound:


cmp   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_NOCHANGE
jne   put_weapon_away
cmp   word ptr ds:[_player + PLAYER_T.player_health], 0
je    put_weapon_away
test  byte ptr ds:[_player + PLAYER_T.player_cmd_buttons], BT_ATTACK
je    not_firing
cmp   byte ptr ds:[_player + PLAYER_T.player_attackdown], 0
je    fire_weapon
mov   al, byte ptr ds:[_player + PLAYER_T.player_readyweapon]
cmp   al, WP_MISSILE
je    dont_fire_weapon
cmp   al, WP_BFG
je    dont_fire_weapon

fire_weapon:
mov   byte ptr ds:[_player + PLAYER_T.player_attackdown], 1
call  P_FireWeapon_
exit_a_weaponready:

POPA_NO_AX_OR_BP_MACRO
ret   

put_weapon_away:
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
xor   ax, ax
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_downstate]
call  P_SetPsprite_
jmp   exit_a_weaponready

not_firing:
mov   byte ptr ds:[_player + PLAYER_T.player_attackdown], PS_WEAPON

dont_fire_weapon:
mov   ax, word ptr ds:[_leveltime]
shr   ax, 1
mov   ah, al ; shift 7 left by shift 1 right and word move. technically high bit of ah is wrong but it gets ANDed out below.
rcr   al, 1  ; restore bit 0 in bit 7
and   ax, 01F80h  ; bottom 7 bits 0 (shifted out), the rest is FINEMASK

mov   di, ax  ; store angle
xchg  ax, dx

les   bx, dword ptr ds:[_player + PLAYER_T.player_bob + 0]
mov   cx, es
mov   ax, FINECOSINE_SEGMENT

call  FixedMulTrig_

inc   dx
mov   word ptr ds:[si + 4], ax
mov   word ptr ds:[si + 6], dx

mov   dx, di
and   dh, 0Fh

les   bx, dword ptr ds:[_player + PLAYER_T.player_bob + 0]
mov   cx, es
mov   ax, FINESINE_SEGMENT
call  FixedMulTrig_

add   dx, WEAPONTOP_HIGH
mov   word ptr ds:[si + 8], ax
mov   word ptr ds:[si + 0Ah], dx

POPA_NO_AX_OR_BP_MACRO
ret   

ENDP

PROC A_ReFire_ NEAR
PUBLIC A_ReFire_


test  byte ptr ds:[_player + PLAYER_T.player_cmd_buttons], BT_ATTACK
je    dont_refire
cmp   byte ptr ds:[_player + PLAYER_T.player_pendingweapon], WP_NOCHANGE
jne   dont_refire

cmp   word ptr ds:[_player + PLAYER_T.player_health], 0
je    dont_refire

inc   byte ptr ds:[_player + PLAYER_T.player_refire]
call  P_FireWeapon_

ret   
dont_refire:
mov   byte ptr ds:[_player + PLAYER_T.player_refire], 0
call  A_CheckReload_
ret   

ENDP

PROC A_Lower_ NEAR
PUBLIC A_Lower_

push  bx
push  dx
xchg  ax, bx
; bx gets pspdef

add   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], LOWERSPEED_HIGH
cmp   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], WEAPONBOTTOM_HIGH
jl    exit_a_lower

cmp   byte ptr ds:[_player + PLAYER_T.player_playerstate], PST_DEAD
je    player_dead

cmp   word ptr ds:[_player + PLAYER_T.player_health], 0
jne   player_alive
xor   ax, ax
cwd
call  P_SetPsprite_
exit_a_lower:
pop   dx
pop   bx
ret   

player_dead:
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+0], WEAPONBOTTOM_LOW
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], WEAPONBOTTOM_HIGH
jmp   exit_a_lower
player_alive:
mov   al, byte ptr ds:[_player + PLAYER_T.player_pendingweapon]
mov   byte ptr ds:[_player + PLAYER_T.player_readyweapon], al
call  P_BringUpWeapon_
pop   dx
pop   bx
ret   

ENDP

PROC A_Raise_ NEAR
PUBLIC A_Raise_

push  bx
push  dx
mov   bx, ax
add   word ptr ds:[bx + PSPDEF_T.pspdef_sy+0], 0
adc   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], -6
cmp   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], WEAPONTOP_HIGH
jg    exit_a_raise
jne   set_weapon_top
cmp   word ptr ds:[bx + 8], 0
jbe   set_weapon_top
exit_a_raise:
pop   dx
pop   bx
ret   
set_weapon_top:
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+0], WEAPONTOP_LOW
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], WEAPONTOP_HIGH
mov   al, SIZEOF_MOBJINFO_T 
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
xor   ax, ax
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_readystate]
call  P_SetPsprite_
pop   dx
pop   bx
ret   
cld  ;todo remove

ENDP

PROC A_GunFlash_ NEAR
PUBLIC A_GunFlash_

push  bx
push  dx
mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[_playerMobj]
call  P_SetMobjState_
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
mov   ax, 1
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
call  P_SetPsprite_
pop   dx
pop   bx
ret   

ENDP

PROC A_Punch_ NEAR
PUBLIC A_Punch_


PUSHA_NO_AX_OR_BP_MACRO

call  P_Random_

;    damage = (P_Random ()%10+1)<<1;

xor   ah, ah
cwd   ; zero dx
mov   bx, 10  ; zero bh
div   bl
mov   dl, ah  ; modulo in dl.
inc   dx
sal   dx, 1

cmp   word ptr ds:[_player + PLAYER_T.player_powers + (PW_STRENGTH * 2)], 0
je    no_berserk
; multiply berserk dmg by 10
shl   dx, 1  ; x2 na
mov   ax, dx ; x2 x2
shl   dx, 1  ; x4 x2
shl   dx, 1  ; x8 x2
add   dx, ax ; x10 x2
no_berserk:

push  dx ; damage parameter down the road 

les   di, dword ptr ds:[_playerMobj_pos]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
call  P_Random_
mov   bl, al
call  P_Random_
; bh still zero
xor   ah, ah
xchg  ax, bx
sub   ax, bx

SHIFT_MACRO shr   cx 3
sar   ax, 1
add   cx, ax

; cx has angle.

;    slope = P_AimLineAttack (playerMobj, angle, MELEERANGE);

mov   dx, cx
mov   ax, word ptr ds:[_playerMobj]
mov   bx, MELEERANGE
call  dword ptr ds:[_P_AimLineAttack]

;    P_LineAttack (playerMobj, angle, MELEERANGE , slope, damage);

; already pushed damage above

push  dx
push  ax

mov   dx, cx
mov   ax, word ptr ds:[_playerMobj]
mov   bx, MELEERANGE
call  dword ptr ds:[_P_LineAttack]


cmp   word ptr ds:[_linetarget], 0
jne   have_linetarget
POPA_NO_AX_OR_BP_MACRO
ret   
have_linetarget:
mov   dx, SFX_PUNCH
mov   ax, word ptr ds:[_playerMobj]
call  S_StartSound_

les   di, dword ptr ds:[_linetarget_pos]
push  word ptr es:[di + 6]
push  word ptr es:[di + 4]
push  word ptr es:[di + 2]
push  word ptr es:[di]
les   di, dword ptr ds:[_playerMobj_pos]
mov   bx, word ptr es:[di + 4]
mov   cx, word ptr es:[di + 6]
les   ax, dword ptr es:[bx]
mov   dx, es

call  R_PointToAngle2_
les   di, dword ptr ds:[_playerMobj_pos]
mov   word ptr es:[di + MOBJ_POS_T.mp_angle+0], ax
mov   word ptr es:[di + MOBJ_POS_T.mp_angle+2], dx
POPA_NO_AX_OR_BP_MACRO
ret   


ENDP

PROC A_Saw_ NEAR
PUBLIC A_Saw_

PUSHA_NO_AX_OR_BP_MACRO
call  P_Random_

;    damage = 2*(P_Random ()%10+1);

xor   ah, ah
cwd   ; zero dx
mov   bx, 10  ; zero bh
div   bl
mov   dl, ah  ; modulo in dl.
inc   dx
sal   dx, 1

push  dx   ; push damage for later

les   si, dword ptr ds:[_playerMobj_pos]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]

call  P_Random_
mov   bl, al
call  P_Random_

xor   ah, ah
xchg  ax, bx
sub   ax, bx


SHIFT_MACRO shr   cx 3
sar   ax, 1
add   cx, ax
and   ch, (FINEMASK SHR 8)


;    slope = P_AimLineAttack (playerMobj, angle, CHAINSAWRANGE);
mov   ax, word ptr ds:[_playerMobj]
mov   bx, CHAINSAWRANGE
mov   dx, cx
call  dword ptr ds:[_P_AimLineAttack]


push  dx
push  ax

mov   dx, cx
mov   ax, word ptr ds:[_playerMobj]
mov   bx, CHAINSAWRANGE
call  dword ptr ds:[_P_LineAttack]

cmp   word ptr ds:[_linetarget], 0

jne   have_linetarget_chainsaw


mov   dx, SFX_SAWFUL
mov   ax, word ptr ds:[_playerMobj]
call  S_StartSound_
POPA_NO_AX_OR_BP_MACRO
ret   



have_linetarget_chainsaw:
mov   dx, SFX_SAWHIT
mov   ax, word ptr ds:[_playerMobj]
call  S_StartSound_

les   si, dword ptr ds:[_linetarget_pos]
push  word ptr es:[si + 6]
push  word ptr es:[si + 4]
push  word ptr es:[si + 2]
push  word ptr es:[si + 0]

les   si, dword ptr ds:[_playerMobj_pos]
mov   bx, word ptr es:[si + 4]
mov   cx, word ptr es:[si + 6]
les   ax, dword ptr es:[si]
mov   dx, es

call  R_PointToAngle2_

les   si, dword ptr ds:[_playerMobj_pos]
mov   bx, ax
mov   cx, dx
sub   bx, word ptr es:[si + MOBJ_POS_T.mp_angle+0]
sbb   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
cmp   cx, ANG180_HIGHBITS

ja    above_180
jne   not_above_180
test  bx, bx
jbe   not_above_180
above_180:

cmp   cx, 0999h;  ((MINUS_ANG90_FULL / 20) SHR 16)      ; 0x999
jb    less_than_negative_4point5
jne   not_less_than_negative_4point5
cmp   bx, 09999h;  ((MINUS_ANG90_FULL / 20) AND 0FFFFh)  ; 0x9999
jae   not_less_than_negative_4point5
less_than_negative_4point5:

add   ax, 030C3h ; ((ANG90_FULL / 21) AND 0FFFFh)  ; 0x30c3
adc   dx, 0030Ch ; ((ANG90_FULL / 21) SHR 16)      ; 0x30c
mov   word ptr es:[si + MOBJ_POS_T.mp_angle+0], ax
mov   word ptr es:[si + MOBJ_POS_T.mp_angle+2], dx
done_with_angle_comparisons_saw:

or    byte ptr es:[si + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
exit_a_saw:
POPA_NO_AX_OR_BP_MACRO
ret   
not_less_than_negative_4point5:

add   word ptr es:[si + MOBJ_POS_T.mp_angle+0], 0CCCDh
adc   word ptr es:[si + MOBJ_POS_T.mp_angle+2], 0FCCCh
jmp   done_with_angle_comparisons_saw
not_above_180:

cmp   cx, 00333h ; ((ANG90_FULL / 20) SHR 16)      ; 0x333
ja    greater_than_positive_4point5
jne   not_greater_than_positive_4point5
cmp   bx, 03333h ; ((ANG90_FULL / 20) AND 0FFFFh)  ; 0x3333
jbe   not_greater_than_positive_4point5
greater_than_positive_4point5:

add   ax, 0CF3Dh ; - ((ANG90_FULL / 21) AND 0FFFFh) ; 0xcf3d
adc   dx, 0FCF3h ; - ((ANG90_FULL / 21) SHR 16)     ; 0xfcf3



mov   word ptr es:[si + MOBJ_POS_T.mp_angle+0], ax
mov   word ptr es:[si + MOBJ_POS_T.mp_angle+2], dx
jmp   done_with_angle_comparisons_saw

not_greater_than_positive_4point5:
add   word ptr es:[si + MOBJ_POS_T.mp_angle+0], 03333h
adc   word ptr es:[si + MOBJ_POS_T.mp_angle+2], 00333h
jmp   done_with_angle_comparisons_saw



ENDP



PROC A_FireMissile_ NEAR
PUBLIC A_FireMissile_


push  bx
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
mov   bl, byte ptr ds:[bx]
xor   bh, bh
imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   bl, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
xor   bh, bh
add   bx, bx
mov   ax, MT_ROCKET
dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
call  dword ptr ds:[_P_SpawnPlayerMissile]
pop   bx
ret   

ENDP

PROC A_FireBFG_ NEAR
PUBLIC A_FireBFG_

push  bx
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
mov   bl, byte ptr ds:[bx]
xor   bh, bh
imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   bl, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
xor   bh, bh
add   bx, bx
mov   ax, MT_BFG
sub   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo], BFGCELLS
call  dword ptr ds:[_P_SpawnPlayerMissile]
pop   bx
ret   
cld  ;todo remove


ENDP

PROC A_FirePlasma_ NEAR
PUBLIC A_FirePlasma_

push  bx
push  dx
push  si
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
mov   bl, byte ptr ds:[bx]
xor   bh, bh
imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   bl, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
xor   bh, bh
add   bx, bx
mov   si, OFFSET _player + PLAYER_T.player_readyweapon
dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
mov   bl, byte ptr ds:[si]
xor   bh, bh
imul  si, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
call  P_Random_
mov   bl, al
mov   dx, word ptr ds:[si + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
and   bl, 1
mov   ax, 1
add   dx, bx
call  P_SetPsprite_
mov   ax, MT_PLASMA
call  dword ptr ds:[_P_SpawnPlayerMissile]
pop   si
pop   dx
pop   bx
ret   

ENDP

PROC P_BulletSlope_ NEAR
PUBLIC P_BulletSlope_

push  bx
push  cx
push  dx
push  si
mov   bx, OFFSET _playerMobj_pos
les   si, dword ptr ds:[bx]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
mov   bx, OFFSET _playerMobj
shr   cx, 3
mov   ax, word ptr ds:[bx]
mov   bx, HALFMISSILERANGE
mov   dx, cx
call  dword ptr ds:[_P_AimLineAttack]
mov   bx, OFFSET _linetarget
mov   word ptr ds:[_bulletslope+0], ax
mov   word ptr ds:[_bulletslope+2], dx
cmp   word ptr ds:[bx], 0
je    label_54
label_55:
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_54:
add   cx, (1 SHL (26-ANGLETOFINESHIFT)) ; 0x80
mov   bx, OFFSET _playerMobj
and   ch, (FINEMASK SHR 8)
mov   ax, word ptr ds:[bx]
mov   bx, HALFMISSILERANGE
mov   dx, cx
call  dword ptr ds:[_P_AimLineAttack]
mov   bx, OFFSET _linetarget
mov   word ptr ds:[_bulletslope+0], ax
mov   word ptr ds:[_bulletslope+2], dx
cmp   word ptr ds:[bx], 0
jne   label_55
sub   cx, (2 SHL (26-ANGLETOFINESHIFT))  ; 0x100
mov   bx, OFFSET _playerMobj
and   ch, (FINEMASK SHR 8)
mov   ax, word ptr ds:[bx]
mov   bx, HALFMISSILERANGE
mov   dx, cx
call  dword ptr ds:[_P_AimLineAttack]
mov   word ptr ds:[_bulletslope+0], ax
mov   word ptr ds:[_bulletslope+2], dx
pop   si
pop   dx
pop   cx
pop   bx
ret   
cld  ;todo remove

ENDP

PROC P_GunShot_ NEAR
PUBLIC P_GunShot_

push  bx
push  cx
push  dx
push  si
push  di
mov   cl, al
call  P_Random_
xor   ah, ah
mov   bx, 3
cwd   
idiv  bx
inc   dx
mov   bx, OFFSET _playerMobj_pos
mov   di, dx
mov   si, word ptr ds:[bx]
shl   di, 2
mov   es, word ptr ds:[bx + 2]
add   di, dx
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
shr   dx, 3
test  cl, cl
je    label_56
label_57:
push  di
mov   bx, OFFSET _playerMobj
push  word ptr ds:[_bulletslope+2]
mov   ax, word ptr ds:[bx]
push  word ptr ds:[_bulletslope+0]
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
call  dword ptr ds:[_P_LineAttack]
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_56:
call  P_Random_
mov   bl, al
call  P_Random_
xor   bh, bh
xor   ah, ah
sub   bx, ax
sar   bx, 1
add   dx, bx
and   dh, (FINEMASK SHR 8)
jmp   label_57
cld  ;todo remove

ENDP

PROC A_FirePistol_ NEAR
PUBLIC A_FirePistol_

push  bx
push  dx
push  si
mov   bx, OFFSET _playerMobj
mov   dx, SFX_PISTOL
mov   ax, word ptr ds:[bx]
call  S_StartSound_
mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[bx]
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
call  P_SetMobjState_
mov   al, byte ptr ds:[bx]
xor   ah, ah
imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   al, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
mov   bx, ax
add   bx, ax
mov   si, OFFSET _player + PLAYER_T.player_readyweapon
dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
mov   al, byte ptr ds:[si]
imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   ax, 1
mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
mov   bx, OFFSET _player + PLAYER_T.player_refire
call  P_SetPsprite_
call  P_BulletSlope_
cmp   byte ptr ds:[bx], 0
jne   label_58
mov   al, 1
cbw  
call  P_GunShot_
pop   si
pop   dx
pop   bx
ret   
label_58:
xor   al, al
cbw  
call  P_GunShot_
pop   si
pop   dx
pop   bx
ret   
cld  ;todo remove

ENDP

PROC A_FireShotgun_ NEAR
PUBLIC A_FireShotgun_

push  bx
push  dx
push  si
mov   bx, OFFSET _playerMobj
mov   dx, SFX_SHOTGN
mov   ax, word ptr ds:[bx]
call  S_StartSound_
mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[bx]
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
call  P_SetMobjState_
mov   bl, byte ptr ds:[bx]
xor   bh, bh
imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   bl, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
xor   bh, bh
add   bx, bx
mov   si, OFFSET _player + PLAYER_T.player_readyweapon
dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
mov   bl, byte ptr ds:[si]
xor   bh, bh
imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   ax, 1
mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
call  P_SetPsprite_
call  P_BulletSlope_
xor   dl, dl
label_59:
xor   ax, ax
inc   dl
call  P_GunShot_
cmp   dl, 7
jl    label_59
pop   si
pop   dx
pop   bx
ret   
cld  ;todo remove

ENDP

PROC A_FireShotgun2_ NEAR
PUBLIC A_FireShotgun2_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   bx, OFFSET _playerMobj
mov   dx, SFX_DSHTGN
mov   ax, word ptr ds:[bx]
call  S_StartSound_
mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[bx]
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
call  P_SetMobjState_
mov   al, byte ptr ds:[bx]
xor   ah, ah
imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   bl, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
xor   bh, bh
add   bx, bx
mov   si, OFFSET _player + PLAYER_T.player_readyweapon
sub   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo], 2
mov   al, byte ptr ds:[si]
imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   byte ptr [bp - 2], 0
mov   ax, 1
mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
mov   di, OFFSET _playerMobj_pos
call  P_SetPsprite_
call  P_BulletSlope_
cld   
label_60:
call  P_Random_
xor   ah, ah
mov   bx, 3
cwd   
idiv  bx
inc   dx
imul  si, dx, 5
mov   bx, OFFSET _playerMobj_pos
mov   bx, word ptr ds:[bx]
mov   es, word ptr ds:[di + 2]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]
call  P_Random_
shr   cx, 3
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
push  si
sub   dx, ax
call  P_Random_
add   cx, dx
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
sub   dx, ax
mov   ax, dx
shl   ax, 5
cwd   
and   ch, (FINEMASK SHR 8)
add   ax, word ptr ds:[_bulletslope+0]
adc   dx, word ptr ds:[_bulletslope+2]
push  dx
mov   bx, OFFSET _playerMobj
push  ax
mov   dx, cx
mov   ax, word ptr ds:[bx]
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
inc   byte ptr [bp - 2]
call  dword ptr ds:[_P_LineAttack]
cmp   byte ptr [bp - 2], 20
jl    label_60
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP

PROC A_FireCGun_ NEAR
PUBLIC A_FireCGun_

push  bx
push  dx
push  si
push  di
mov   si, ax
mov   bx, OFFSET _playerMobj
mov   dx, SFX_PISTOL
mov   ax, word ptr ds:[bx]
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
call  S_StartSound_
mov   al, byte ptr ds:[bx]
xor   ah, ah
imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   al, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
mov   bx, ax
add   bx, ax
cmp   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo], 0
jne   label_21
pop   di
pop   si
pop   dx
pop   bx
ret   
label_21:
mov   bx, OFFSET _playerMobj
mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[bx]
mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
call  P_SetMobjState_
mov   al, byte ptr ds:[bx]
xor   ah, ah
imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   al, byte ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_ammo]
mov   bx, ax
add   bx, ax
mov   di, OFFSET _player + PLAYER_T.player_readyweapon
dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
mov   al, byte ptr ds:[di]
imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
add   dx, word ptr ds:[si]
mov   ax, 1
sub   dx, S_CHAIN1
mov   bx, OFFSET _player + PLAYER_T.player_refire
call  P_SetPsprite_
call  P_BulletSlope_
cmp   byte ptr ds:[bx], 0
jne   label_61
mov   al, 1
cbw  
call  P_GunShot_
pop   di
pop   si
pop   dx
pop   bx
ret   
label_61:
xor   al, al
cbw  
call  P_GunShot_
pop   di
pop   si
pop   dx
pop   bx
ret   


ENDP

PROC A_Light0_ NEAR
PUBLIC A_Light0_

push  bx
mov   bx, OFFSET _player + PLAYER_T.player_extralightvalue
mov   byte ptr ds:[bx], 0
pop   bx
ret   
cld  ;todo remove

ENDP

PROC A_Light1_ NEAR
PUBLIC A_Light1_

push  bx
mov   bx, OFFSET _player + PLAYER_T.player_extralightvalue
mov   byte ptr ds:[bx], 1
pop   bx
ret   
cld  ;todo remove

ENDP

PROC A_Light2_ NEAR
PUBLIC A_Light2_

push  bx
mov   bx, OFFSET _player + PLAYER_T.player_extralightvalue
mov   byte ptr ds:[bx], 2
pop   bx
ret   
cld  ;todo remove

ENDP

PROC A_OpenShotgun2_ NEAR
PUBLIC A_OpenShotgun2_

push  bx
push  dx
mov   bx, OFFSET _playerMobj
mov   dx, SFX_DBOPN
mov   ax, word ptr ds:[bx]
call  S_StartSound_
pop   dx
pop   bx
ret

ENDP

PROC A_LoadShotgun2_ NEAR
PUBLIC A_LoadShotgun2_

push  bx
push  dx
mov   bx, OFFSET _playerMobj
mov   dx, SFX_DBLOAD
mov   ax, word ptr ds:[bx]
call  S_StartSound_
pop   dx
pop   bx
ret   

ENDP

PROC A_CloseShotgun2_ NEAR
PUBLIC A_CloseShotgun2_

push  bx
push  dx
push  si
mov   bx, ax
mov   si, OFFSET _playerMobj
mov   dx, SFX_DBCLS
mov   ax, word ptr ds:[si]
call  S_StartSound_
mov   ax, bx
call  A_Refire_
pop   si
pop   dx
pop   bx
ret   
cld  ;todo remove

ENDP

PROC A_BFGSpray_ NEAR
PUBLIC A_BFGSpray_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
push  ax
push  bx
push  cx
mov   byte ptr [bp - 2], 0
label_46:
mov   al, byte ptr [bp - 2]
cbw  
imul  ax, ax, (FINE_ANG90/40)  ; 0x33
mov   es, word ptr [bp - 8]
mov   bx, word ptr [bp - 6]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]
mov   bx, word ptr [bp - 4]
imul  si, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
shr   dx, 3
sub   dx, (FINE_ANG90/2)
add   dx, ax
mov   bx, HALFMISSILERANGE
add   si, (_thinkerlist + 4)
and   dh, (FINEMASK SHR 8)
mov   ax, si
call  dword ptr ds:[_P_AimLineAttack]
mov   bx, OFFSET _linetarget
mov   ax, word ptr ds:[bx]
test  ax, ax
jne   label_45
label_47:
inc   byte ptr [bp - 2]
cmp   byte ptr [bp - 2], 40
jl    label_46
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_45:
mov   bx, ax
mov   di, OFFSET _linetarget_pos
mov   ax, word ptr ds:[bx + MOBJ_T.m_height+0]
mov   cx, word ptr ds:[bx + MOBJ_T.m_height+2]
push  word ptr ds:[bx + MOBJ_T.m_secnum]
sar   cx, 1
rcr   ax, 1
mov   bx, OFFSET _linetarget_pos
sar   cx, 1
rcr   ax, 1
mov   bx, word ptr ds:[bx]
mov   es, word ptr ds:[di + 2]
push  MT_EXTRABFG        ; todo 186
add   ax, word ptr es:[bx + MOBJ_POS_T.mp_z+0]
adc   cx, word ptr es:[bx + MOBJ_POS_T.mp_z+2]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x+0]
push  cx
mov   di, word ptr es:[bx + MOBJ_POS_T.mp_x+2]
push  ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y+0]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y+2]
mov   bx, ax
mov   ax, dx
mov   dx, di
call  P_SpawnMobj_
xor   cx, cx
xor   dl, dl
label_48:
call  P_Random_
and   al, 7
xor   ah, ah
inc   ax
inc   dl
add   cx, ax
cmp   dl, 15
jl    label_48
mov   bx, OFFSET _linetarget
mov   dx, si
mov   ax, word ptr ds:[bx]
mov   bx, si
call  P_DamageMobj_
jmp   label_47
cld   

ENDP

PROC A_BFGsound_ NEAR
PUBLIC A_BFGsound_


push  bx
push  dx
mov   bx, OFFSET _playerMobj
mov   dx, SFX_BFG
mov   ax, word ptr ds:[bx]
call  S_StartSound_
pop   dx
pop   bx
ret   


ENDP

PROC P_MovePsprites_ NEAR
PUBLIC P_MovePsprites_

push  bx
push  cx
push  dx
push  si
mov   bx, OFFSET _psprites
xor   cl, cl
label_50:
cmp   word ptr ds:[bx], STATENUM_NULL
je    label_49
cmp   word ptr ds:[bx + 2], -1
je    label_49
dec   word ptr ds:[bx + 2]
jne   label_49
imul  si, word ptr ds:[bx], 6
mov   ax, STATES_SEGMENT
mov   es, ax
mov   al, cl
mov   dx, word ptr es:[si + 4]
cbw  
add   si, 4
call  P_SetPsprite_
label_49:
inc   cl
add   bx, SIZEOF_PSPDEF_T
cmp   cl, NUMPSPRITES
jl    label_50
mov   bx, OFFSET _psprites + (PS_WEAPON * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sx
mov   si, OFFSET _psprites + (PS_FLASH  * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sx
mov   ax, word ptr ds:[bx]
mov   dx, word ptr ds:[bx + 2]
mov   word ptr ds:[si], ax
mov   word ptr ds:[si + 2], dx
mov   si, OFFSET _psprites + (PS_WEAPON * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy
mov   bx, OFFSET _psprites + (PS_FLASH  * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy
mov   ax, word ptr ds:[si]
mov   dx, word ptr ds:[si + 2]
mov   word ptr ds:[bx], ax
mov   word ptr ds:[bx + 2], dx
pop   si
pop   dx
pop   cx
pop   bx
ret   
cld  ;todo remove

; todo probably switch jump table

p_setpsprite_jump_table:
dw switch_label_1
dw switch_label_2
dw switch_label_3
dw switch_label_4
dw switch_label_5
dw switch_label_6
dw switch_label_7
dw switch_label_8
dw switch_label_9
dw switch_label_10
dw switch_label_11
dw switch_label_12
dw switch_label_13
dw switch_label_14
dw switch_label_15
dw switch_label_16
dw switch_label_17
dw switch_label_18
dw switch_label_19
dw switch_label_20
dw switch_label_21
dw switch_label_22






ENDP

PROC P_SetPsprite_ NEAR
PUBLIC P_SetPsprite_


push  bx
push  cx
push  si
cbw  
imul  bx, ax, SIZEOF_PSPDEF_T   ; todo 0 or 1. mul not necessary.
add   bx, OFFSET _psprites
test  dx, dx
je    label_51
mov   cl, 1
label_53:
cmp   dx, STATENUM_NULL
je    label_51
imul  si, dx, 6
mov   ax, STATES_SEGMENT
mov   es, ax
mov   word ptr ds:[bx], dx
mov   al, byte ptr es:[si + 2]
cbw  
mov   word ptr ds:[bx + 2], ax
mov   dl, byte ptr es:[si + 3]
sub   dl, cl
cmp   dl, 21   ; max state
ja    label_52
xor   dh, dh
mov   si, dx
add   si, dx
jmp   word ptr cs:[si + OFFSET p_setpsprite_jump_table]
switch_label_1:
mov   si, OFFSET _player + PLAYER_T.player_extralightvalue
mov   byte ptr ds:[si], dh
label_29:
test  cl, cl
je    label_52
cmp   word ptr ds:[bx], -1
je    exit_p_setpsprite
label_52:
imul  si, word ptr ds:[bx], 6
mov   ax, STATES_SEGMENT
mov   es, ax
add   si, 4
mov   dx, word ptr es:[si]
cmp   word ptr ds:[bx + 2], 0
jne   exit_p_setpsprite
test  dx, dx
jne   label_53
label_51:
mov   word ptr ds:[bx], STATENUM_NULL
exit_p_setpsprite:
pop   si
pop   cx
pop   bx
ret   
switch_label_2:
mov   ax, bx
call  A_WeaponReady_
jmp   label_29
switch_label_3:
mov   ax, bx
call  A_Lower_
jmp   label_29
switch_label_4:
mov   ax, bx
call  A_Raise_
jmp   label_29
switch_label_5:
mov   ax, bx
call  A_Punch_
jmp   label_29
switch_label_6:
mov   ax, bx
call  A_Refire_
jmp   label_29
switch_label_7:
mov   ax, bx
call  A_FirePistol_
jmp   label_29
switch_label_8:
mov   si, OFFSET _player + PLAYER_T.player_extralightvalue
mov   byte ptr ds:[si], cl
jmp   label_29
switch_label_9:
mov   ax, bx
call  A_FireShotgun_
jmp   label_29
switch_label_10:
mov   si, OFFSET _player + PLAYER_T.player_extralightvalue
mov   byte ptr ds:[si], 2
jmp   label_29
switch_label_11:
mov   ax, bx
call  A_FireShotgun2_
jmp   label_29
switch_label_12:
call  A_CheckReload_
jmp   label_29
switch_label_13:
mov   si, OFFSET _playerMobj
mov   dx, SFX_DBOPN
mov   ax, word ptr ds:[si]
call  S_StartSound_
jmp   label_29
switch_label_14:
mov   si, OFFSET _playerMobj
mov   dx, SFX_DBLOAD
mov   ax, word ptr ds:[si]
call  S_StartSound_
jmp   label_29
switch_label_15:
mov   si, OFFSET _playerMobj
mov   dx, SFX_DBCLS
mov   ax, word ptr ds:[si]
call  S_StartSound_
mov   ax, bx
call  A_Refire_
jmp   label_29
switch_label_16:
mov   ax, bx
call  A_FireCGun_
jmp   label_29
switch_label_17:
mov   ax, bx
call  A_GunFlash_
jmp   label_29
switch_label_18:
mov   ax, bx
call  A_FireMissile_
jmp   label_29
switch_label_19:
mov   ax, bx
call  A_Saw_
jmp   label_29
switch_label_20:
mov   ax, bx
call  A_FirePlasma_
jmp   label_29
switch_label_21:
mov   si, OFFSET _playerMobj
mov   dx, SFX_BFG
mov   ax, word ptr ds:[si]
call  S_StartSound_
jmp   label_29
switch_label_22:
mov   ax, bx
call  A_FireBFG_
jmp   label_29

ENDP

PROC    P_PSPR_ENDMARKER_ 
PUBLIC  P_PSPR_ENDMARKER_
ENDP


END