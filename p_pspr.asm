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


; these can be called near but must have push cs prefix
EXTRN P_Random_MapLocal_:NEAR   ; except this is really near
EXTRN P_LineAttack_:NEAR
EXTRN P_SpawnPlayerMissile_:NEAR
EXTRN P_AimLineAttack_:NEAR   ; except this is really near


.DATA


.CODE



PROC    P_PSPR_STARTMARKER_ 
PUBLIC  P_PSPR_STARTMARKER_
ENDP


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
mov   al, SIZEOF_WEAPONINFO_T
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
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
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
mov   al, SIZEOF_WEAPONINFO_T
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


mov   al, SIZEOF_WEAPONINFO_T
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
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
mov   al, SIZEOF_WEAPONINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_atkstate]
xor   ax, ax
call  P_SetPsprite_
;call  P_NoiseAlert_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_NoiseAlert_Addr


pop   dx
pop   bx
ret   

ENDP

PROC P_DropWeapon_ NEAR
PUBLIC P_DropWeapon_

push  bx
push  dx
mov   al, SIZEOF_WEAPONINFO_T
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
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
dont_use_atk1_or_atk2_state:

cmp   byte ptr ds:[_player + PLAYER_T.player_readyweapon], WP_CHAINSAW
jne   dont_do_chainsaw_sound
cmp   word ptr ds:[si], S_SAW
jne   dont_do_chainsaw_sound
mov   dx, SFX_SAWIDL
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
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

ret

put_weapon_away:
mov   al, SIZEOF_WEAPONINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
xor   ax, ax
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_downstate]
call  P_SetPsprite_
ret   

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

;call  FixedMulTrig_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrig_addr


inc   dx
mov   word ptr ds:[si + 4], ax
mov   word ptr ds:[si + 6], dx

mov   dx, di
and   dh, 0Fh

les   bx, dword ptr ds:[_player + PLAYER_T.player_bob + 0]
mov   cx, es
mov   ax, FINESINE_SEGMENT
;call  FixedMulTrig_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrig_addr

add   dx, WEAPONTOP_HIGH
mov   word ptr ds:[si + 8], ax
mov   word ptr ds:[si + 0Ah], dx

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
ret   

player_dead:
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+0], WEAPONBOTTOM_LOW
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], WEAPONBOTTOM_HIGH
ret   
player_alive:
mov   al, byte ptr ds:[_player + PLAYER_T.player_pendingweapon]
mov   byte ptr ds:[_player + PLAYER_T.player_readyweapon], al
call  P_BringUpWeapon_
ret   

ENDP

PROC A_Raise_ NEAR
PUBLIC A_Raise_

mov   bx, ax
add   word ptr ds:[bx + PSPDEF_T.pspdef_sy+0], 0
adc   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], -6
cmp   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], WEAPONTOP_HIGH
jg    exit_a_raise
jne   set_weapon_top
cmp   word ptr ds:[bx + 8], 0
jbe   set_weapon_top
exit_a_raise:
ret   
set_weapon_top:
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+0], WEAPONTOP_LOW
mov   word ptr ds:[bx + PSPDEF_T.pspdef_sy+2], WEAPONTOP_HIGH
mov   al, SIZEOF_WEAPONINFO_T 
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
xor   ax, ax
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_readystate]
call  P_SetPsprite_
ret   

ENDP

PROC A_GunFlash_ NEAR
PUBLIC A_GunFlash_

mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[_playerMobj]
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
mov   al, SIZEOF_WEAPONINFO_T
mul   byte ptr ds:[_player + PLAYER_T.player_readyweapon]
xchg  ax, bx
mov   ax, 1
mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
call  P_SetPsprite_
ret   

ENDP

PROC A_Punch_ NEAR
PUBLIC A_Punch_



call  P_Random_MapLocal_

;    damage = (P_Random ()%10+1)<<1;

cwd   ; zero dx
mov   bx, 10  ; zero bh
div   bl
mov   dl, ah  ; modulo in dl.
inc   dx
sal   dx, 1

cmp   word ptr ds:[_player + PLAYER_T.player_powers + (PW_STRENGTH * 2)], 0
je    no_berserk
; multiply berserk dmg by 10
mov   al, 10
mul   dl
xchg  ax, dx
no_berserk:


;	angle = playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT;
;	angle += ((P_Random()-P_Random())>> 1);

;    slope = P_AimLineAttack (playerMobj, angle, MELEERANGE);
;    P_LineAttack (playerMobj, angle, MELEERANGE , slope, damage);



push  dx ; damage parameter down the road 

les   di, dword ptr ds:[_playerMobj_pos]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_angle+2]

call  P_Random_MapLocal_
mov   bx, ax
call  P_Random_MapLocal_
; bh still zero
sub   bx, ax

SHIFT_MACRO shr   cx 3
sar   bx, 1
add   cx, bx
and   ch, (FINEMASK SHR 8)

; cx has angle.

;    slope = P_AimLineAttack (playerMobj, angle, MELEERANGE);

mov   dx, cx
mov   ax, word ptr ds:[_playerMobj]
mov   bx, MELEERANGE
push  cs
call  P_AimLineAttack_

;    P_LineAttack (playerMobj, angle, MELEERANGE , slope, damage);

; already pushed damage above

push  dx ; push slope hi
push  ax ; push slope lo

mov   dx, cx
mov   ax, word ptr ds:[_playerMobj]
mov   bx, MELEERANGE
push  cs
call  P_LineAttack_

cmp   word ptr ds:[_linetarget], 0
je    exit_a_punch

have_linetarget:

;		playerMobj_pos->angle.wu = R_PointToAngle2 (playerMobj_pos->x, playerMobj_pos->y, linetarget_pos->x, linetarget_pos->y);


mov   dx, SFX_PUNCH
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

mov   si, word ptr ds:[_playerMobj_pos]
lds   di, dword ptr ds:[_linetarget_pos]
push  word ptr ds:[di + MOBJ_POS_T.mp_y + 2]
push  word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[di + MOBJ_POS_T.mp_x + 0]

les   bx, dword ptr ds:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, es
les   ax, dword ptr ds:[si + MOBJ_POS_T.mp_x + 0]
mov   dx, es

push  ss
pop   ds

;call  R_PointToAngle2_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_PointToAngle2_addr

les   di, dword ptr ds:[_playerMobj_pos]
mov   word ptr es:[di + MOBJ_POS_T.mp_angle+0], ax
mov   word ptr es:[di + MOBJ_POS_T.mp_angle+2], dx
exit_a_punch:
ret   


ENDP

PROC A_Saw_ NEAR
PUBLIC A_Saw_

call  P_Random_MapLocal_

;    damage = 2*(P_Random ()%10+1);

cwd   ; zero dx
mov   bx, 10  ; zero bh
div   bl
mov   dl, ah  ; modulo in dl.
inc   dx
sal   dx, 1

push  dx   ; push damage for later

les   si, dword ptr ds:[_playerMobj_pos]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]

call  P_Random_MapLocal_
mov   bx, ax
call  P_Random_MapLocal_

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
push  cs
call  P_AimLineAttack_

; already pushed damage above

push  dx
push  ax

mov   dx, cx
mov   ax, word ptr ds:[_playerMobj]
mov   bx, CHAINSAWRANGE
push  cs
call  P_LineAttack_

cmp   word ptr ds:[_linetarget], 0

jne   have_linetarget_chainsaw


mov   dx, SFX_SAWFUL
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
ret   



have_linetarget_chainsaw:
mov   dx, SFX_SAWHIT
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

mov   si, word ptr ds:[_playerMobj_pos]
lds   di, dword ptr ds:[_linetarget_pos]
push  word ptr ds:[di + MOBJ_POS_T.mp_y + 2]
push  word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[di + MOBJ_POS_T.mp_x + 0]

les   bx, dword ptr ds:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, es
les   ax, dword ptr ds:[si + MOBJ_POS_T.mp_x + 0]
mov   dx, es

push  ss
pop   ds

;call  R_PointToAngle2_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_PointToAngle2_addr

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


mov   ax, MT_ROCKET
dec   ds:[_player + PLAYER_T.player_ammo + (2 * AM_MISL)]
call  P_SpawnPlayerMissile_
ret   

ENDP

PROC A_FireBFG_ NEAR
PUBLIC A_FireBFG_

mov   ax, MT_BFG
sub   ds:[_player + PLAYER_T.player_ammo + (2 * AM_CELL)], BFGCELLS
call  P_SpawnPlayerMissile_
ret   


ENDP

PROC A_FirePlasma_ NEAR
PUBLIC A_FirePlasma_


dec   ds:[_player + PLAYER_T.player_ammo + (2 * AM_CELL)]
call  P_Random_MapLocal_
and   al, 1
mov   dx, word ptr ds:[_weaponinfo + (WP_PLASMA * SIZEOF_WEAPONINFO_T) + WEAPONINFO_T.weaponinfo_flashstate]
add   dx, ax
mov   al, PS_FLASH
call  P_SetPsprite_
mov   ax, MT_PLASMA
call  P_SpawnPlayerMissile_

ret   

ENDP

PROC P_BulletSlope_ NEAR
PUBLIC P_BulletSlope_

push  bx
push  cx
push  dx

les   bx, dword ptr ds:[_playerMobj_pos]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]

SHIFT_MACRO shr   cx 3
mov   ax, word ptr ds:[_playerMobj]

mov   bx, HALFMISSILERANGE
mov   dx, cx
push  cs
call  P_AimLineAttack_

mov   word ptr ds:[_bulletslope+0], ax
mov   word ptr ds:[_bulletslope+2], dx

cmp   word ptr ds:[_linetarget], 0
je    has_linetarget_bulletslope
exit_bulletslope:
pop   dx
pop   cx
pop   bx
ret   
has_linetarget_bulletslope:
add   cx, (1 SHL (26-ANGLETOFINESHIFT)) ; 0x80
and   ch, (FINEMASK SHR 8)
mov   ax, word ptr ds:[_playerMobj]
mov   bx, HALFMISSILERANGE
mov   dx, cx

push  cs
call  P_AimLineAttack_

mov   word ptr ds:[_bulletslope+0], ax
mov   word ptr ds:[_bulletslope+2], dx
cmp   word ptr ds:[_linetarget], 0
jne   exit_bulletslope

sub   cx, (2 SHL (26-ANGLETOFINESHIFT))  ; 0x100
and   ch, (FINEMASK SHR 8)
mov   ax, word ptr ds:[_playerMobj]
mov   bx, HALFMISSILERANGE
mov   dx, cx

push  cs
call  P_AimLineAttack_
mov   word ptr ds:[_bulletslope+0], ax
mov   word ptr ds:[_bulletslope+2], dx
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC P_GunShot_ NEAR
PUBLIC P_GunShot_
;void __near P_GunShot (  boolean	accurate ) {

push  bx
push  dx
mov   bl, al ; bl stores accuracy
call  P_Random_MapLocal_
mov   dx, 3 ; zero dh

div   dl
mov   dl, ah
inc   dx

mov   ax, dx
SHIFT_MACRO shl   dx 2
add   dx, ax
push  dx  ; push damage argument for later

xchg  ax, bx  ; ax gets accuracy back

les   bx, dword ptr ds:[_playerMobj_pos]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle+2] ; angle hibits..

SHIFT_MACRO shr   dx 3
test  al, al

jne   do_shot
; add shot inaccuracy


call  P_Random_MapLocal_
mov   bx, ax
call  P_Random_MapLocal_

sub   bx, ax
sar   bx, 1
add   dx, bx
and   dh, (FINEMASK SHR 8)


do_shot:
; dx has hangle..
push  word ptr ds:[_bulletslope+2]
push  word ptr ds:[_bulletslope+0]
mov   ax, word ptr ds:[_playerMobj]
mov   bx, MISSILERANGE
push  cs
call  P_LineAttack_
pop   dx
pop   bx
ret   


ENDP

PROC A_FirePistol_ NEAR
PUBLIC A_FirePistol_

mov   dx, SFX_PISTOL
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[_playerMobj]

;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr


dec   ds:[_player + PLAYER_T.player_ammo + (2 * AM_CLIP)]
mov   ax, PS_FLASH
mov   dx, word ptr ds:[_weaponinfo + (WP_PISTOL * SIZEOF_WEAPONINFO_T) + WEAPONINFO_T.weaponinfo_flashstate]


call  P_SetPsprite_
call  P_BulletSlope_
xor   ax, ax
cmp   byte ptr ds:[_player + PLAYER_T.player_refire], al
jne   inaccurate_pistol_shot     ; ax 0
inc   ax                         ; ax 1
inaccurate_pistol_shot:
call  P_GunShot_
ret   

ENDP

PROC A_FireShotgun_ NEAR
PUBLIC A_FireShotgun_


mov   dx, SFX_SHOTGN
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[_playerMobj]

;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr


dec   ds:[_player + PLAYER_T.player_ammo + (2 * AM_SHELL)]
mov   ax, PS_FLASH
mov   dx, word ptr ds:[_weaponinfo + (WP_SHOTGUN * SIZEOF_WEAPONINFO_T) + WEAPONINFO_T.weaponinfo_flashstate]
call  P_SetPsprite_
call  P_BulletSlope_
xor   dl, dl
do_next_shotgun_pellet:
xor   ax, ax
inc   dl
call  P_GunShot_
cmp   dl, 7
jl    do_next_shotgun_pellet


ret   

ENDP

PROC A_FireShotgun2_ NEAR
PUBLIC A_FireShotgun2_


;	S_StartSound(playerMobj, sfx_dshtgn);


mov   dx, SFX_DSHTGN
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

;    P_SetMobjState (playerMobj, S_PLAY_ATK2);

mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[_playerMobj]
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr

;    player.ammo[weaponinfo[player.readyweapon].ammo]-=2;

sub   word ptr ds:[_player + PLAYER_T.player_ammo + (2 * AM_SHELL)], 2

;    P_SetPsprite (
;		  ps_flash,;
;		  weaponinfo[player.readyweapon].flashstate);


mov   ax, PS_FLASH
mov   dx, word ptr ds:[_weaponinfo + (WP_SUPERSHOTGUN * SIZEOF_WEAPONINFO_T) + WEAPONINFO_T.weaponinfo_flashstate]
call  P_SetPsprite_

;    P_BulletSlope ();

call  P_BulletSlope_

mov   cx, 20  ; 20 pellets... crazy!

loop_next_super_pellet:

;	damage = 5*(P_Random ()%3+1);

call  P_Random_MapLocal_


mov   dx, 3  ; dh made 0 here
div   dl
mov   al, 5
inc   ah
mul   ah
push  ax  ; store stack argument.

;	angle = playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT;

les   bx, dword ptr ds:[_playerMobj_pos]
mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]

;	angle = MOD_FINE_ANGLE( angle + ( ( P_Random()-P_Random() )<<(19-ANGLETOFINESHIFT)) );

call  P_Random_MapLocal_
SHIFT_MACRO shr   bx 3
add   bx, ax   ; add rand1
call  P_Random_MapLocal_
sub   bx, ax   ; sub rand2
and   bh, (FINEMASK SHR 8)

;	P_LineAttack (playerMobj,
;		      angle,
;		MISSILERANGE,
;		      bulletslope + ((P_Random()-P_Random())<<5), damage);

call  P_Random_MapLocal_
mov   dx, ax
call  P_Random_MapLocal_

sub   dx, ax
xchg  ax, dx
SHIFT_MACRO shl   ax 5
cwd   
add   ax, word ptr ds:[_bulletslope+0]
adc   dx, word ptr ds:[_bulletslope+2]
push  dx
push  ax
mov   dx, bx

mov   ax, word ptr ds:[_playerMobj]
mov   bx, MISSILERANGE

push  cs
call  P_LineAttack_

loop  loop_next_super_pellet

ret   

ENDP

PROC A_FireCGun_ NEAR
PUBLIC A_FireCGun_

mov   bx, ax
mov   dx, SFX_PISTOL
mov   ax, word ptr ds:[_playerMobj]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr


cmp   ds:[_player + PLAYER_T.player_ammo + (2 * AM_CLIP)], 0
je    exit_fire_cgun

mov   dx, S_PLAY_ATK2
mov   ax, word ptr ds:[_playerMobj]
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr

dec   ds:[_player + PLAYER_T.player_ammo + (2 * AM_CLIP)]
mov   dx, word ptr ds:[_weaponinfo + (WP_CHAINGUN * SIZEOF_WEAPONINFO_T) + WEAPONINFO_T.weaponinfo_flashstate]
add   dx, word ptr ds:[bx + PSPDEF_T.pspdef_statenum]
sub   dx, S_CHAIN1
mov   ax, PS_FLASH

call  P_SetPsprite_
call  P_BulletSlope_
xor   ax, ax
cmp   byte ptr ds:[_player + PLAYER_T.player_refire], al
jne   do_inaccurate_chaingunshot
inc   ax
do_inaccurate_chaingunshot:
call  P_GunShot_
exit_fire_cgun:
ret   


ENDP

PROC A_Light0_ NEAR
PUBLIC A_Light0_

mov   byte ptr ds:[_player + PLAYER_T.player_extralightvalue], 0
ret   

ENDP

PROC A_Light1_ NEAR
PUBLIC A_Light1_

mov   byte ptr ds:[_player + PLAYER_T.player_extralightvalue], 1
ret   

ENDP

PROC A_Light2_ NEAR
PUBLIC A_Light2_

mov   byte ptr ds:[_player + PLAYER_T.player_extralightvalue], 2
ret   

ENDP

PROC A_OpenShotgun2_ NEAR
PUBLIC A_OpenShotgun2_

mov   dx, SFX_DBOPN
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
ret

ENDP

PROC A_LoadShotgun2_ NEAR
PUBLIC A_LoadShotgun2_

mov   dx, SFX_DBLOAD
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
ret   

ENDP

PROC A_CloseShotgun2_ NEAR
PUBLIC A_CloseShotgun2_

push  ax
mov   dx, SFX_DBCLS
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
pop   ax
call  A_Refire_
ret   

ENDP

PROC A_BFGSpray_ NEAR
PUBLIC A_BFGSpray_

;void __near A_BFGSpray (mobj_t __near* mo, mobj_pos_t __far* mo_pos) {

push  dx
push  si
push  di

mov   di, bx   ; di has mobjpos
mov   si, ax   ; si has mobj
mov   ax, SIZEOF_THINKER_T
mul   word ptr ds:[si + MOBJ_T.m_targetRef]  ; targetRef  ; clobbers dx... gr
add   ax, (_thinkerlist + THINKER_T.t_data)
xchg  ax, si  ; si has target...

; apparently target is supposed to be the originator of missile (player) so should be static for the loop.

mov   cx, 40

loop_bfg_spray:

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax


; not sure if we can pull this out and store it outside the loop. can targetref change?
xchg  ax, bx ; bx stores

;mov   al, (FINE_ANG90/40)
;mov   ah, 40
mov   ax, 02833h  ; set hi and low in one go
sub   ah, cl
mul   ah



mov   dx, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
SHIFT_MACRO shr   dx 3
sub   dx, (FINE_ANG90/2)
add   dx, ax; angle ready
and   dh, (FINEMASK SHR 8)

;	P_AimLineAttack (motarget, an, HALFMISSILERANGE);

mov   ax, si
mov   bx, HALFMISSILERANGE
push  cs
call  P_AimLineAttack_

mov   bx, word ptr ds:[_linetarget]
test  bx, bx
jne   bfg_spray_hit_something
finish_this_bfg_spray_iter:

loop  loop_bfg_spray
pop   di
pop   si
pop   dx
ret   

bfg_spray_hit_something:
; bx is linetarget mobh

push  cx ; store outer loop var...


les   ax, dword ptr ds:[bx + MOBJ_T.m_height+0]
mov   dx, es
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1


;		P_SpawnMobj(linetarget_pos->x.w,
;			linetarget_pos->y.w,
;			linetarget_pos->z.w + (linetarget->height.w >> 2),
;			MT_EXTRABFG, linetarget->secnum);

push  word ptr ds:[bx + MOBJ_T.m_secnum]

IF COMPISA GE COMPILE_186
    push  MT_EXTRABFG        ; todo 186
ELSE
    mov   bx, MT_EXTRABFG
    push  bx
ENDIF

lds   bx, dword ptr ds:[_linetarget_pos]
add   ax, word ptr ds:[bx + MOBJ_POS_T.mp_z + 0]
adc   dx, word ptr ds:[bx + MOBJ_POS_T.mp_z + 2]
push  dx
push  ax

les   ax, dword ptr ds:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, es
les   bx, dword ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, es

push  ss
pop   ds

;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr


mov   cx, 15
mov   dx, cx  ; add 1 15 times up front here (instead of inc in loop)

;    for (j=0;j<15;j++)
;        damage += (P_Random()&7) + 1;

do_next_rand_damage_add:
call  P_Random_MapLocal_
and   al, 7
add   dx, ax
loop  do_next_rand_damage_add


;	P_DamageMobj (linetarget, motarget, motarget, damage);

mov   cx, dx
mov   dx, si
mov   bx, si
mov   ax, word ptr ds:[_linetarget]


db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr

pop   cx  ; get outer loop var..
jmp   finish_this_bfg_spray_iter


ENDP

PROC A_BFGsound_ NEAR
PUBLIC A_BFGsound_


mov   dx, SFX_BFG
mov   ax, word ptr ds:[_playerMobj]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
ret   


ENDP

PROC P_MovePsprites_ FAR
PUBLIC P_MovePsprites_

push  bx
push  cx
push  dx

xor   cx, cx
; loop 0 
mov   bx, OFFSET _psprites + (PS_WEAPON * SIZEOF_PSPDEF_T)

do_second_loop:
mov   ax, word ptr ds:[bx + PSPDEF_T.pspdef_statenum] ; get statenum and tics
cmp   ax, STATENUM_NULL
je    dont_set_this_psprite
cmp   word ptr ds:[bx + PSPDEF_T.pspdef_tics], -1
je    dont_set_this_psprite
dec   word ptr ds:[bx + PSPDEF_T.pspdef_tics]
jne   dont_set_this_psprite
; mul 6
sal   ax, 1     ; x2, na
mov   bx, ax    ; x2, x2
sal   bx, 1     ; x2, x4
add   bx, ax    ; x2, x6
mov   ax, STATES_SEGMENT
mov   es, ax
mov   ax, cx
mov   dx, word ptr es:[bx + 4]
call  P_SetPsprite_

dont_set_this_psprite:
inc   cx
cmp   cl, NUMPSPRITES
je    done_looping_psprites
; 2nd loop case: 
mov   bx, OFFSET _psprites + (PS_FLASH * SIZEOF_PSPDEF_T)

jmp   do_second_loop

done_looping_psprites:

;    psprites[ps_flash].sx = psprites[ps_weapon].sx;
;    psprites[ps_flash].sy = psprites[ps_weapon].sy;

les   ax, dword ptr ds:[_psprites + (PS_WEAPON * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sx]
mov   word ptr ds:[_psprites + (PS_FLASH  * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sx + 0], ax
mov   word ptr ds:[_psprites + (PS_FLASH  * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sx + 2], es

les   ax, dword ptr ds:[_psprites + (PS_WEAPON * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy]
mov   word ptr ds:[_psprites + (PS_FLASH  * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy + 0], ax
mov   word ptr ds:[_psprites + (PS_FLASH  * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy + 2], es

pop   dx
pop   cx
pop   bx
retf


p_setpsprite_jump_table:
dw OFFSET A_Light0_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_WeaponReady_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_Lower_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_Raise_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_Punch_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_Refire_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_FirePistol_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_Light1_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_FireShotgun_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_Light2_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_FireShotgun2_ - OFFSET P_SIGHT_STARTMARKER_
; this one is used a bit
dw OFFSET A_CheckReload_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_OpenShotgun2_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_LoadShotgun2_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_CloseShotgun2_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_FireCGun_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_GunFlash_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_FireMissile_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_Saw_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_FirePlasma_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_BFGsound_ - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET A_FireBFG_ - OFFSET P_SIGHT_STARTMARKER_






ENDP

PROC P_SetPsprite_ NEAR
PUBLIC P_SetPsprite_


push  bx
push  si
cmp   al, 0
je    psprite_0
mov   al, SIZEOF_PSPDEF_T
psprite_0:
cbw
xchg  ax, bx
add   bx, OFFSET _psprites
test  dx, dx

je    null_statenum_break_and_exit
loop_next_state:
cmp   dx, STATENUM_NULL
je    null_statenum_break_and_exit

mov   word ptr ds:[bx + PSPDEF_T.pspdef_statenum], dx

sal   dx, 1
mov   si, dx
sal   si, 1
add   si, dx  ; si has dx * 6..

mov   ax, STATES_SEGMENT
mov   es, ax


mov   al, byte ptr es:[si + STATE_T.state_tics]

cbw  
mov   word ptr ds:[bx + PSPDEF_T.pspdef_tics], ax

mov   al, byte ptr es:[si + STATE_T.state_action]
cbw
dec   ax

mov   dx, word ptr es:[si + STATE_T.state_nextstate] ; grab state now.... remove SI dependency

cmp   al, 21   ; max state
ja    bad_state


mov   si, ax
sal   si, 1
mov   ax, bx ; ax gets psp

; todo: push pop here, not in all the functions.

PUSHA_NO_AX_MACRO

call   word ptr cs:[si + OFFSET p_setpsprite_jump_table - OFFSET P_SIGHT_STARTMARKER_]

POPA_NO_AX_MACRO

finished_p_setpsprite_switchblock:
cmp   word ptr ds:[bx + PSPDEF_T.pspdef_statenum], STATENUM_NULL
je    exit_p_setpsprite

bad_state:


cmp   word ptr ds:[bx + PSPDEF_T.pspdef_tics], 0
jne   exit_p_setpsprite
test  dx, dx
jne   loop_next_state

null_statenum_break_and_exit:
mov   word ptr ds:[bx + PSPDEF_T.pspdef_statenum], STATENUM_NULL
exit_p_setpsprite:
pop   si
pop   bx
ret   


ENDP

; far accessors... remove eventually

PROC P_DropWeaponFar_ FAR
PUBLIC P_DropWeaponFar_

call   P_DropWeapon_
retf

ENDP


PROC P_BringUpWeaponFar_ FAR
PUBLIC P_BringUpWeaponFar_

call   P_BringUpWeapon_
retf

ENDP

PROC A_BFGSprayFar_ FAR
PUBLIC A_BFGSprayFar_

call   A_BFGSpray_
retf

ENDP


PROC    P_PSPR_ENDMARKER_ 
PUBLIC  P_PSPR_ENDMARKER_
ENDP


END