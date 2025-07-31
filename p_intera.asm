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


EXTRN AM_Stop_:PROC
EXTRN P_Random_:NEAR
EXTRN FastDiv32u16u_:PROC
EXTRN FastMul16u32u_:PROC
EXTRN R_PointToAngle2_:PROC
EXTRN FixedMulTrigNoShift_:PROC

EXTRN _P_RemoveMobj:DWORD
EXTRN _P_DropWeaponFar:DWORD
EXTRN _P_SpawnMobj:DWORD
EXTRN _P_SetMobjState:DWORD
EXTRN _useDeadAttackerRef:BYTE
EXTRN _deadAttackerX:DWORD
EXTRN _deadAttackerY:DWORD

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
cmp    word ptr ds:[bx], MAXHEALTH
jge    exit_pgivebody_return_0
add    ax, word ptr ds:[bx]
cmp    ax, MAXHEALTH
jle    dont_cap_health
mov    ax, MAXHEALTH
dont_cap_health:
mov    word ptr ds:[bx], ax

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



PROC    P_GiveArmor_  NEAR
PUBLIC  P_GiveArmor_

push   dx
mov    dx, 100
cmp    al, 1
je     dont_give_l2_armor
sal    dx, 1 ; dx is 200
dont_give_l2_armor:
cmp    dx, word ptr ds:[_player + PLAYER_T.player_armorpoints]
jg     do_give_armor
xor    ax, ax
pop    dx
ret    

do_give_armor:
mov    byte ptr ds:[_player + PLAYER_T.player_armortype], al
mov    word ptr ds:[_player + PLAYER_T.player_armorpoints], dx
mov    al, 1
pop    dx
ret    
ENDP


BONUSADD = 6
PROC    P_GiveCard_  NEAR
PUBLIC  P_GiveCard_

push   bx
cbw
mov    bx, ax
cmp    byte ptr ds:[bx + _player + PLAYER_T.player_cards], 0
je     add_card
pop    si
pop    bx
ret    
add_card:

mov    byte ptr ds:[_player + PLAYER_T.player_bonuscount], BONUSADD
mov    byte ptr ds:[bx + _player + PLAYER_T.player_cards], 1
pop    bx
ret    
ENDP




PROC    P_GivePower_  FAR
PUBLIC  P_GivePower_

push   bx
mov    bx, ax
sal    bx, 1
test   ax, ax
jne    not_invulnerability
mov    ax, INVULNTICS
jmp    finish_giving_power

not_invulnerability:
cmp    al, PW_INVISIBILITY
je     give_invisibility   ; 2
jb     give_berserk        ; 1
cmp    al, PW_ALLMAP
;je     give_generic_power   ;4
jb     give_radsuit        ; 3
ja     give_infrared       ; 5
give_generic_power:
cmp    word ptr ds:[bx + _player + PLAYER_T.player_powers], 0
je     set_power_on_and_return
xor    ax, ax
pop    bx
ret   

give_invisibility:
xchg   ax, bx
les    bx, dword ptr ds:[_playerMobj_pos]
or     byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_SHADOW
xchg   ax, bx
give_radsuit:   ; IRONTICS == INVISTICS
mov    ax, INVISTICS

finish_giving_power:
mov    word ptr ds:[bx + _player + PLAYER_T.player_powers], ax
mov    al, 1
pop    bx
ret


give_infrared:
mov    ax, INFRATICS
jmp    finish_giving_power
give_berserk:
mov    ax, MAXHEALTH
call   P_GiveBody_
set_power_on_and_return:
mov    ax, 1
mov    word ptr ds:[bx + _player + PLAYER_T.player_powers], ax
pop    bx
ret
ENDP


; table

_touchspecial_jump_table:

dw touchspecial_case_55, touchspecial_case_56, touchspecial_case_default, touchspecial_case_default, touchspecial_case_default 
dw touchspecial_case_60, touchspecial_case_61, touchspecial_case_62, touchspecial_case_63
dw touchspecial_case_64, touchspecial_case_65, touchspecial_case_66, touchspecial_case_67, touchspecial_case_68, touchspecial_case_69
dw touchspecial_case_70, touchspecial_case_71, touchspecial_case_72, touchspecial_case_73, touchspecial_case_74, touchspecial_case_75
dw touchspecial_case_76, touchspecial_case_77, touchspecial_case_78, touchspecial_case_79, touchspecial_case_80, touchspecial_case_81
dw touchspecial_case_82, touchspecial_case_83, touchspecial_case_84, touchspecial_case_85, touchspecial_case_86, touchspecial_case_87
dw touchspecial_case_88, touchspecial_case_89, touchspecial_case_90, touchspecial_case_91, touchspecial_case_92, touchspecial_case_93

;void __far P_TouchSpecialThing ( mobj_t __near*	special, mobj_t __near*	toucher, mobj_pos_t  __far*special_pos, mobj_pos_t  __far*toucher_pos ) {

; ax special
; dx toucher
; bx specialpos offset
; cx toucherpos offset

; bp - 2    state
; bp - 4    countitem
; bp - 6    z high
; bp - 8    ax/special backup
; bp - 0Ah  

out_of_range:
dead_toucher_cant_pickup:

pop    di
retf

PROC    P_TouchSpecialThing_  FAR
PUBLIC  P_TouchSpecialThing_

push   di
mov    di, dx

; check toucher health 
cmp    word ptr ds:[di + MOBJ_T.m_health], 0
jle    dead_toucher_cant_pickup

mov    word ptr cs:[OFFSET SELFMODIFY_touchspecial_removemobj_ptr+1], ax
; ax free

; todo this might be guaranteed ES already.
mov    dx, MOBJPOSLIST_6800_SEGMENT
mov    es, dx

;	fixed_t specialz = special_pos->z.w;
mov    ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov    dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]

; dx:ax is  is specialz

;dx:ax is delta 
;    delta = specialz - toucher_pos->z.w;

xchg   bx, cx
sub    ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
sbb    dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]

;    if (delta > toucher->height.w || delta < -8*FRACUNIT) {
;		// out of reach
;		return;
;    }

cmp    dx, -8
jl     out_of_range
cmp    dx, word ptr ds:[di + MOBJ_T.m_height + 2]
jg     out_of_range
jne    done_with_height_check
cmp    ax, word ptr ds:[di + MOBJ_T.m_height + 0]
ja     out_of_range

done_with_height_check:

mov    bx, cx  ; restore special_pos. cx free for use.

;ax, dx, cx, di free.

;	boolean specialflagscountitem =  special_pos->flags2&MF_COUNTITEM ? 1 : 0;
mov    al, byte ptr es:[bx + MOBJ_POS_T.mp_flags2]
mov    dx, 0C089h  ; two byte nop
test   al, MF_COUNTITEM
jne    do_set_nop_count_item
mov    dx, ((OFFSET dont_increment_itemcount - OFFSET SELFMODIFY_touchspecial_itemcount_AFTER) SHL 8) + 0EBh 
do_set_nop_count_item:
mov    word ptr cs:[OFFSET SELFMODIFY_touchspecial_itemcount], dx

and    al, MF_DROPPED
cbw
shr    ax, 1  ; todo this is to get 1 out of MF_DROPPED... gross?

; al equals dropped.

mov    bx, word ptr es:[bx + MOBJ_POS_T.mp_statenum]
mov    dx, bx
sal    bx, 1
add    bx, dx
sal    bx, 1  ; size 6..

;	spritenum_t specialsprite = states[special_pos->stateNum].sprite;
mov    dx, STATES_SEGMENT
mov    es, dx
xchg   ax, dx  ; dx gets dropped flag.
mov    al, byte ptr es:[bx + STATE_T.state_sprite]
sub    al, SPR_ARM1   ; minimum switch block case
cmp    al, (SPR_SGN2 - SPR_ARM1)  ; 0x26.. diff between low and high case

ja     touchspecial_case_default
cbw

mov    bx, ax
sal    bx, 1
mov    cx, SFX_ITEMUP 

mov    di, _player + PLAYER_T.player_message

jmp    word ptr cs:[bx + OFFSET _touchspecial_jump_table]



touchspecial_case_74:
cmp    byte ptr ds:[_commercial], 0
je     exit_ptouchspecialthing
mov    word ptr ds:[_player + PLAYER_T.player_health], 200
mov    word ptr ds:[di], GOTMSPHERE
mov    bx, word ptr ds:[_playerMobj]
mov    word ptr ds:[bx + MOBJ_T.m_health], 200
mov    ax, 2
mov    cx, SFX_GETPOW
call   P_GiveArmor_
jmp    done_with_touchspecial_switch_block


touchspecial_case_55:
mov    word ptr ds:[di], GOTARMOR
mov    ax, 1
do_givearmor_touchspecial:
call   P_GiveArmor_
test   al, al
je     exit_ptouchspecialthing


touchspecial_case_default:
done_with_touchspecial_switch_block:

SELFMODIFY_touchspecial_itemcount:
jmp    dont_increment_itemcount  ; may become a nop
SELFMODIFY_touchspecial_itemcount_AFTER:
inc    word ptr ds:[_player + PLAYER_T.player_itemcount]
dont_increment_itemcount:


SELFMODIFY_touchspecial_removemobj_ptr:
mov    ax, 01000h

call   dword ptr [_P_RemoveMobj]

mov    dx, cx
xor    ax, ax
add    byte ptr ds:[_player + PLAYER_T.player_bonuscount], BONUSADD

;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

exit_ptouchspecialthing:
pop    di
retf
touchspecial_case_56:
mov    ax, 2
mov    word ptr ds:[di], GOTMEGA
jmp    do_givearmor_touchspecial

touchspecial_case_60:
mov    bx, _player + PLAYER_T.player_health
mov    ax, word ptr ds:[bx]
inc    ax
cmp    ax, 200
jng    dont_cap_health_4
mov    ax, 200
dont_cap_health_4:
mov    word ptr ds:[bx], ax

mov    bx, word ptr ds:[_playerMobj]
mov    word ptr ds:[bx + MOBJ_T.m_health], ax

mov    word ptr ds:[di], GOTHTHBONUS
jmp    done_with_touchspecial_switch_block




touchspecial_case_87:
mov    word ptr ds:[di], GOTBFG9000
mov    ax, WP_BFG

do_giveweapon_touchspecial_with_cwd:
cwd
do_giveweapon_touchspecial:

shr    bx, 1
add    bx, (GOTCHAINGUN - SPR_MGUN + SPR_ARM1) ; renormalize 
mov    word ptr ds:[di], bx


call   P_GiveWeapon_
test   al, al
je     exit_ptouchspecialthing

mov    cx, SFX_WPNUP
jmp    done_with_touchspecial_switch_block


; bh is known zero..
touchspecial_case_62:
mov    bl, 0

handle_give_card:
mov    ax, bx
cmp    byte ptr ds:[_player + PLAYER_T.player_cards + bx], bh
jne    skip_key_message
add    bx, GOTBLUECARD
mov    word ptr ds:[di], bx
skip_key_message:
; use ax from above. 
call   P_GiveCard_
jmp    done_with_touchspecial_switch_block

touchspecial_case_68:
mov    ax, 10
mov    word ptr ds:[di], GOTSTIM
do_givebody:
call   P_GiveBody_
test   al, al
jne    done_with_touchspecial_switch_block
exitptouchspecialthing_2:
pop    di
retf


;71 025h 0
;72 026h 1
;73 027h 2
; 74 na
;75 028h 3
;76 029h 4
;77 02Ah 5

touchspecial_case_75:
touchspecial_case_76:
touchspecial_case_77:

do_givepower_subtract_1_extra:
dec    bx ; undo the extra one for the 74 offset being a nonpowerup... dec once enough for shr 


touchspecial_case_73:
touchspecial_case_71:
do_givepower:

add    ax, (GOTINVUL - SPR_PINV + SPR_ARM1) ; renormalize 
mov    word ptr ds:[di], ax
sub    ax, GOTINVUL    ; set ax parameter to correct powerup.



call   P_GivePower_
test   al, al
je     exit_ptouchspecialthing

mov    cx, SFX_GETPOW
jmp    done_with_touchspecial_switch_block

touchspecial_case_88:
; dx carries dropped flag
mov    ax, WP_CHAINGUN
jmp    do_giveweapon_touchspecial


touchspecial_case_89:
mov    ax, WP_CHAINSAW
jmp    do_giveweapon_touchspecial_with_cwd

touchspecial_case_90:
mov    ax, WP_MISSILE
jmp    do_giveweapon_touchspecial_with_cwd

touchspecial_case_91:
mov    ax, WP_PLASMA
jmp    do_giveweapon_touchspecial_with_cwd
touchspecial_case_92:
; dx carries dropped flag
mov    ax, WP_SHOTGUN
jmp    do_giveweapon_touchspecial

touchspecial_case_93:
mov    ax, WP_SUPERSHOTGUN
; dx carries dropped flag
jmp    do_giveweapon_touchspecial



touchspecial_case_64:
mov    bl, IT_YELLOWCARD
jmp    handle_give_card
touchspecial_case_63:
mov    bl, IT_REDCARD
jmp    handle_give_card
touchspecial_case_65:
mov    bl, IT_BLUESKULL
jmp    handle_give_card
touchspecial_case_67:
mov    bl, IT_YELLOWSKULL
jmp    handle_give_card
touchspecial_case_66:
mov    bl, IT_REDSKULL
jmp    handle_give_card

touchspecial_case_72:
; bh known zero
cmp    byte ptr ds:[_player + PLAYER_T.player_readyweapon], bh
je     do_givepower
mov    byte ptr ds:[_player + PLAYER_T.player_pendingweapon], bh
jmp    do_givepower



touchspecial_case_69:
mov    ax, 25
mov    word ptr ds:[di], GOTMEDIKIT
jmp    do_givebody



touchspecial_case_78:
; special flags?
test   dl, dl
mov    ax, 0   ; AM_CLIP
jne    do_giveammo_touchspecial ; dropped clip

inc    ah
jmp    do_giveammo_touchspecial ; nondropped clip






touchspecial_case_79:
mov    ax, AM_CLIP + (5 SHL 8)
do_giveammo_touchspecial:
sar    bx, 1
add    bx, (GOTCLIP - SPR_CLIP + SPR_ARM1)
mov    word ptr ds:[di], bx
mov    dl ,ah
call   P_GiveAmmo_
test   al, al
je     exitptouchspecialthing_2

jmp    done_with_touchspecial_switch_block

touchspecial_case_80:
mov    ax, AM_MISL + (1 SHL 8)
jmp    do_giveammo_touchspecial

touchspecial_case_81:
mov    ax, AM_MISL + (5 SHL 8)

jmp    do_giveammo_touchspecial


touchspecial_case_82:
mov    ax, AM_CELL + (1 SHL 8)
jmp    do_giveammo_touchspecial

touchspecial_case_83:
mov    ax, AM_CELL + (5 SHL 8)
jmp    do_giveammo_touchspecial

touchspecial_case_84:
mov    ax, AM_SHELL + (1 SHL 8)
jmp    do_giveammo_touchspecial
touchspecial_case_85:
mov    ax, AM_SHELL + (5 SHL 8)
jmp    do_giveammo_touchspecial




touchspecial_case_86:

cmp    byte ptr ds:[_player + PLAYER_T.player_backpack], 0
jne    already_have_backpack
xor    dl, dl
mov    bx, _player + PLAYER_T.player_maxammo
shl    word ptr ds:[bx], 1
shl    word ptr ds:[bx+2], 1
shl    word ptr ds:[bx+4], 1
shl    word ptr ds:[bx+6], 1

mov    byte ptr ds:[_player + PLAYER_T.player_backpack], 1
already_have_backpack:

xor    bx, bx

loop_backpack_giveammo:
mov    ax, bx
cwd
inc    dx
inc    bl
call   P_GiveAmmo_
cmp    bl, 4
jl     loop_backpack_giveammo

mov    word ptr ds:[di], GOTBACKPACK

jmp    done_with_touchspecial_switch_block


touchspecial_case_61:
mov    bx, _player + PLAYER_T.player_armorpoints
mov    ax, word ptr ds:[bx]
inc    ax
cmp    ax, 200
jng    dont_cap_armor_2
mov    ax, 200
dont_cap_armor_2:
mov    word ptr ds:[bx], ax
mov    byte ptr ds:[_player + PLAYER_T.player_armortype], 1


mov    word ptr ds:[di], GOTARMBONUS
jmp    done_with_touchspecial_switch_block

touchspecial_case_70:
mov    bx, _player + PLAYER_T.player_health
mov    ax, word ptr ds:[bx]
add    ax, 100
cmp    ax, 200
jng    dont_cap_health_3
mov    ax, 200
dont_cap_health_3:
mov    word ptr ds:[bx], ax
mov    bx, word ptr ds:[_playerMobj]
mov    word ptr ds:[bx + MOBJ_T.m_health], ax

mov    cx, SFX_GETPOW
mov    word ptr ds:[di], GOTSUPER
jmp    done_with_touchspecial_switch_block


ENDP

ONFLOORZ_HIGHBITS = 08000h
ONFLOORZ_LOWBITS = 0


PROC    P_KillMobj_  NEAR
PUBLIC  P_KillMobj_



push   si
push   di
push   bp
mov    bp, sp
mov    di, ax
mov    si, dx

mov    es, cx

and    word ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT (MF_SHOOTABLE OR MF_FLOAT))
and    byte ptr es:[bx + MOBJ_POS_T.mp_flags2 + 1],  ((NOT MF_SKULLFLY) SHR 8)
mov    al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
cmp    al, MT_SKULL
je     not_skull
and    byte ptr es:[bx + MOBJ_POS_T.mp_flags1 + 1],  ((NOT MF_NOGRAVITY) SHR 8)
not_skull:

or     byte ptr es:[bx + MOBJ_POS_T.mp_flags1 + 1], (MF_DROPOFF SHR 8)
or     byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_CORPSE

sar    word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr    word ptr ds:[si + MOBJ_T.m_height + 0], 1
sar    word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr    word ptr ds:[si + MOBJ_T.m_height + 0], 1

test   byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_COUNTKILL
je     dont_count_kill
mov    di, _player + PLAYER_T.player_killcount
inc    word ptr ds:[di]
dont_count_kill:



cmp    al, MT_SKULL
je     no_corpse
cmp    al, MT_PAIN
jne    skip_nocorpse
no_corpse:
; this hack has to do with fixing a timedemo bug by keeping track of the thing to kill the player if dies and it has no corpse
; not sure if i care about keeping long term.
xchg   ax, di
mov    cx, SIZEOF_THINKER_T
lea    ax, [si - (_thinkerlist + THINKER_T.t_data)]
xor    dx, dx
div    cx

cmp    ax, word ptr ds:[_player + PLAYER_T.player_attackerRef]
xchg   ax, di
jne    skip_nocorpse

;			useDeadAttackerRef = true;
;			deadAttackerX = target_pos->x;
;			deadAttackerY = target_pos->y;


mov    byte ptr ds:[_useDeadAttackerRef], 1
push   word ptr es:[bx]
push   word ptr es:[bx + 2]
push   word ptr es:[bx + 4]
push   word ptr es:[bx + 6]
pop    word ptr ds:[_deadAttackerY + 2]
pop    word ptr ds:[_deadAttackerY + 0]
pop    word ptr ds:[_deadAttackerX + 2]
pop    word ptr ds:[_deadAttackerX + 0]

skip_nocorpse:

mov    di, ax  ; store type
cmp    al, MT_PLAYER
jne    target_not_player


and    byte ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT MF_SOLID)
mov    byte ptr ds:[_player + PLAYER_T.player_playerstate], 1

call   dword ptr ds:[_P_DropWeaponFar]
cmp    byte ptr ds:[_automapactive], 0
je     target_not_player
call   AM_Stop_
target_not_player:


;    if (target->health < (-getSpawnHealth(target->type))  && getXDeathState(target->type)) {
;		P_SetMobjState (target, getXDeathState(target->type)) ;
;    } else {
;		P_SetMobjState (target, getDeathState(target->type));
;	 }
mov   ax, di  ; retrieve type
db     09Ah
dw     GETSPAWNHEALTHADDR, INFOFUNCLOADSEGMENT

neg    ax
cmp    ax, word ptr ds:[si + MOBJ_T.m_health]

jle    do_death_state
mov    ax, di

db     09Ah
dw     GETXDEATHSTATEADDR, INFOFUNCLOADSEGMENT

test   ax, ax
jne    got_death_or_xdeath_state_in_ax

do_death_state:
mov    al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor    ah, ah

db    09Ah
dw    GETDEATHSTATEADDR, INFOFUNCLOADSEGMENT


got_death_or_xdeath_state_in_ax:
xchg   ax, dx
mov    ax, si
call   dword ptr  ds:[_P_SetMobjState]
call   P_Random_
and    al, 3
sub    byte ptr ds:[si + MOBJ_T.m_tics], al
mov    al, byte ptr ds:[si + MOBJ_T.m_tics]
cmp    al, 1
jnae   cap_tics
cmp    al, 240
jna    dont_cap_tics

cap_tics:
mov    byte ptr ds:[si + MOBJ_T.m_tics], 1
dont_cap_tics:
mov    ax, di
cmp    al, MT_SHOTGUY
jnae   type_not_above_equal_2

ja     type_not_2
mov    al, MT_SHOTGUN
jmp    do_spawn_drop

type_not_2:
cmp    al, MT_WOLFSS
je     drop_clip
cmp    al, MT_CHAINGUY
jne    exit_p_killmobj
mov    al, MT_CHAINGUN
jmp    do_spawn_drop

type_not_above_equal_2:

cmp    al, MT_POSSESSED
jne    exit_p_killmobj
drop_clip:
mov    al, MT_CLIP
do_spawn_drop:

xor    ah, ah
push   word ptr ds:[si + MOBJ_T.m_secnum]
push   ax  ; type

mov    ax, ONFLOORZ_HIGHBITS
push   ax
xor    ax, ax
push   ax

mov    ax, MOBJPOSLIST_6800_SEGMENT
mov    es, ax
mov    ax, word ptr es:[bx]
mov    dx, word ptr es:[bx + 2]

les    bx, dword ptr es:[bx + 4]
mov    cx, es

call   dword ptr [_P_SpawnMobj]

les    bx, dword ptr ds:[_setStateReturn_pos]
or     byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_DROPPED
exit_p_killmobj:
LEAVE_MACRO  
pop    di
pop    si
ret    




ENDP 



mass_thrust_switch_block:
dw mass_thrust_type_1, mass_thrust_default, mass_thrust_type_1, mass_thrust_default, mass_thrust_default, mass_thrust_type_4, mass_thrust_default, mass_thrust_default, mass_thrust_default, mass_thrust_type_2
dw mass_thrust_type_2, mass_thrust_type_2, mass_thrust_type_4, mass_thrust_default, mass_thrust_type_4, mass_thrust_type_6, mass_thrust_type_4, mass_thrust_type_5, mass_thrust_type_4, mass_thrust_type_2
dw mass_thrust_default, mass_thrust_type_3, mass_thrust_type_3



PROC    getMassThrust_  NEAR
PUBLIC  getMassThrust_
;fixed_t __near getMassThrust(int16_t damage, int8_t id){

push   bx
push   cx
sub    dl, MT_VILE ; (lowest)
cmp    dl, (MT_BOSSBRAIN - MT_VILE)  ; highest
ja     mass_thrust_default
xor    dh, dh
mov    bx, dx
add    bx, dx
jmp    word ptr cs:[bx + OFFSET mass_thrust_switch_block]
mass_thrust_type_1:
mov    bx, 08000h
mov    cx, 0Ch
call   FastMul16u32u_
mov    bx, 500
do_mass_thrust_div:
call   FastDiv32u16u_
pop    cx
pop    bx
ret    
mass_thrust_type_5:
mov    bx, 08000h
mov    cx, 0Ch
call   FastMul16u32u_
mov    bx, 600
jmp    do_mass_thrust_div
mass_thrust_type_4:
mov    bx, 08000h
mov    cx, 0Ch
call   FastMul16u32u_
mov    bx, 1000
jmp    do_mass_thrust_div
mass_thrust_type_3:
mov    bx, 80
cwd    
idiv   bx
cwd    
pop    cx
pop    bx
ret    

mass_thrust_type_6:
mov    dx, 04000h
jmp    do_mass_thrust_mul
mass_thrust_type_2:
mov    dx, 0800h
jmp    do_mass_thrust_mul

mass_thrust_default:
mov    dx, 02000h
do_mass_thrust_mul:
mul    dx
pop    cx
pop    bx
ret    
ENDP



PROC    P_DamageMobj_  FAR
PUBLIC  P_DamageMobj_

push   si
push   di
push   bp
mov    bp, sp
sub    sp, 01Ch
mov    si, ax
mov    word ptr [bp - 0Eh], dx
mov    word ptr [bp - 6], bx
mov    di, cx
mov    bx, SIZEOF_THINKER_T
sub    ax, (_thinkerlist + THINKER_T.t_data)
xor    dx, dx
div    bx
imul   bx, ax, SIZEOF_MOBJ_POS_T
mov    word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT

mov    es, word ptr [bp - 2]
mov    word ptr [bp - 4], bx
test   byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_SHOOTABLE
jne    label_1
jump_to_exit_p_damagemobj:
jmp    exit_p_damagemobj
label_1:
cmp    word ptr ds:[si + MOBJ_T.m_health], 0
jle    jump_to_exit_p_damagemobj
test   byte ptr es:[bx + MOBJ_POS_T.mp_flags2 + 1], 1
je     label_2
jmp    label_3
label_2:
cmp    byte ptr ds:[si + MOBJ_T.m_mobjtype], 0
jne    label_4
mov    bx, OFFSET _gameskill
cmp    byte ptr ds:[bx], 0
jne    label_4
sar    di, 1
label_4:
cmp    word ptr [bp - 0Eh], 0
jne    label_5
jump_to_label_6:
jmp    label_6
label_5:
les    bx, dword ptr [bp - 4]
test   byte ptr es:[bx + MOBJ_POS_T.mp_flags1 + 1], (MF_NOCLIP SHR 8)
jne    jump_to_label_6
mov    ax, word ptr [bp - 6]
test   ax, ax
je     label_7
jmp    label_30
label_7:
mov    ax, word ptr [bp - 0Eh]
mov    bx, SIZEOF_THINKER_T
xor    dx, dx
sub    ax, (_thinkerlist + THINKER_T.t_data)
div    bx
imul   bx, ax, SIZEOF_MOBJ_POS_T
mov    ax, MOBJPOSLIST_6800_SEGMENT
mov    es, ax
mov    dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov    ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov    cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov    word ptr [bp - 01Ch], ax
mov    word ptr [bp - 018h], cx
mov    ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov    cx, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov    bx, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
mov    es, word ptr [bp - 2]
mov    word ptr [bp - 014h], bx
mov    bx, word ptr [bp - 4]
push   word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push   word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov    word ptr [bp - 016h], cx
push   word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov    cx, word ptr [bp - 018h]
push   word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov    bx, ax
mov    ax, dx
mov    dx, word ptr [bp - 01Ch]

call   R_PointToAngle2_

mov    word ptr [bp - 012h], ax
mov    al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
mov    word ptr [bp - 010h], dx
cbw   
mov    word ptr [bp - 8], dx
mov    dx, ax
mov    ax, di
call   getMassThrust_
mov    cx, ax
mov    word ptr [bp - 0Ch], ax
mov    word ptr [bp - 0Ah], dx
cmp    di, 40
jge    label_15
cmp    di, word ptr ds:[si + MOBJ_T.m_health]
jle    label_15
les    bx, dword ptr [bp - 4]
mov    ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
sub    ax, word ptr [bp - 016h]
mov    word ptr [bp - 01Ah], ax
mov    ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
sbb    ax, word ptr [bp - 014h]
cmp    ax, 64
jg     label_16
jne    label_15
cmp    word ptr [bp - 01Ah], 0
jbe    label_15
label_16:
call   P_Random_
test   al, 1
je     label_15
mov    ax, cx
add    ax, ax
adc    dx, dx
add    ax, ax
mov    word ptr [bp - 0Ch], ax
mov    ax, word ptr [bp - 012h]
adc    dx, dx
add    ax, 0
mov    ax, word ptr [bp - 010h]
adc    ax, ANG180_HIGHBITS
mov    word ptr [bp - 0Ah], dx
mov    word ptr [bp - 8], ax
label_15:
mov    ax, word ptr [bp - 8]
shr    ax, 1
mov    bx, word ptr [bp - 0Ch]
and    al, 0FCh
mov    cx, word ptr [bp - 0Ah]
mov    word ptr [bp - 8], ax
mov    dx, ax
mov    ax, FINECOSINE_SEGMENT
call   FixedMulTrigNoShift_
mov    bx, word ptr [bp - 0Ch]
mov    cx, word ptr [bp - 0Ah]
add    word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov    ax, FINESINE_SEGMENT
adc    word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov    dx, word ptr [bp - 8]
call   FixedMulTrigNoShift_
add    word ptr ds:[si + MOBJ_T.m_momy + 0], ax
adc    word ptr ds:[si + MOBJ_T.m_momy + 2], dx
label_6:
cmp    byte ptr ds:[si + MOBJ_T.m_mobjtype], 0
je     label_17
jmp    label_18
label_17:
mov    ax, word ptr ds:[si + 4]
shl    ax, 4
mov    bx, ax
add    bx, _sectors_physics + SECTOR_PHYSICS_T.secp_special
;		// end of game hell hack
 
cmp    byte ptr ds:[bx], 11
jne    label_19
mov    ax, word ptr ds:[si + MOBJ_T.m_health]
cmp    di, ax
jl     label_19
mov    di, ax
dec    di
label_19:
cmp    di, 1000
jge    label_20
mov    bx, _player + PLAYER_T.player_cheats
test   byte ptr ds:[bx], CF_GODMODE
je     label_21
jump_to_exit_p_damagemobj_2:
jmp    exit_p_damagemobj
label_21:
mov    bx, _player + PLAYER_T.player_powers
cmp    word ptr ds:[bx], 0
jne    jump_to_exit_p_damagemobj_2
label_20:
mov    bx, _player + PLAYER_T.player_armortype
mov    al, byte ptr ds:[bx]
test   al, al
je     label_22
cmp    al, 1
je     label_23
jmp    label_24
label_23:
mov    ax, di
mov    bx, 3
cwd    
idiv   bx
label_28:
mov    bx, _player + PLAYER_T.player_armorpoints
cmp    ax, word ptr ds:[bx]
jl     label_25
mov    ax, word ptr ds:[bx]
mov    bx, _player + PLAYER_T.player_armortype
mov    byte ptr ds:[bx], 0
label_25:
mov    bx, _player + PLAYER_T.player_armorpoints
sub    di, ax
sub    word ptr ds:[bx], ax
label_22:
mov    bx, _player + PLAYER_T.player_health
sub    word ptr ds:[bx], di
cmp    word ptr ds:[bx], 0
jge    label_26
jmp    label_27
label_26:
mov    ax, word ptr [bp - 6]
mov    bx, SIZEOF_THINKER_T
xor    dx, dx
sub    ax, (_thinkerlist + THINKER_T.t_data)
div    bx
mov    bx, _player + PLAYER_T.player_attackerRef
mov    word ptr ds:[bx], ax
mov    bx, word ptr [bp - 6]
cmp    word ptr ds:[bx + MOBJ_T.m_health], 0
jg     label_31
jmp    label_32
label_31:
mov    byte ptr ds:[_useDeadAttackerRef], 0
label_14:
mov    bx, _player + PLAYER_T.player_damagecount
add    word ptr ds:[bx], di
cmp    word ptr ds:[bx], 100
jle    label_18
mov    word ptr ds:[bx], 100
label_18:
sub    word ptr ds:[si + MOBJ_T.m_health], di
cmp    word ptr ds:[si + MOBJ_T.m_health], 0
jg     label_33
jmp    label_34
label_33:
call   P_Random_
mov    dl, al
mov    al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor    ah, ah
xor    dh, dh

db     09Ah
dw     GETPAINCHANCEADDR, INFOFUNCLOADSEGMENT

cmp    dx, ax
jge    label_35
les    bx, dword ptr [bp - 4]
test   byte ptr es:[bx + MOBJ_POS_T.mp_flags2 + 1], (MF_SKULLFLY SHR 8)
jne    label_35
or     byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_JUSTHIT
mov    al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor    ah, ah
db     09Ah
dw     GETPAINSTATEADDR, INFOFUNCLOADSEGMENT
mov    dx, ax
mov    ax, si
call   dword ptr [_P_SetMobjState]
label_35:
mov    byte ptr ds:[si + MOBJ_T.m_reactiontime], 0
cmp    byte ptr ds:[si + MOBJ_T.m_threshold], 0
jne    jump_to_label_8
label_10:
mov    ax, word ptr [bp - 6]
test   ax, ax
je     exit_p_damagemobj
cmp    si, ax
je     exit_p_damagemobj
mov    bx, ax
cmp    byte ptr ds:[bx + MOBJ_T.m_mobjtype], 3
je     exit_p_damagemobj
mov    bx, SIZEOF_THINKER_T
sub    ax, (_thinkerlist + THINKER_T.t_data)
xor    dx, dx
div    bx
mov    word ptr ds:[si + MOBJ_T.m_targetRef], ax
mov    al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor    ah, ah
imul   dx, ax, SIZEOF_MOBJINFO_T
mov    di, word ptr [bp - 4]
mov    byte ptr ds:[si + MOBJ_T.m_threshold], BASETHRESHOLD
mov    es, word ptr [bp - 2]
mov    bx, dx
add    bx, _mobjinfo
mov    dx, word ptr es:[di + MOBJ_POS_T.mp_statenum]
cmp    dx, word ptr ds:[bx]
je     jump_to_label_12
exit_p_damagemobj:
LEAVE_MACRO  
pop    di
pop    si
retf   
label_3:
; big todo cleanup
xor ax, ax
cwd
mov    word ptr ds:[si + MOBJ_T.m_momz+0], ax
mov    word ptr ds:[si + MOBJ_T.m_momz+2], ax
mov    word ptr ds:[si + MOBJ_T.m_momy+0], ax
mov    word ptr ds:[si + MOBJ_T.m_momy+2], ax
mov    word ptr ds:[si + MOBJ_T.m_momx+0], ax
mov    word ptr ds:[si + MOBJ_T.m_momx+2], ax
jmp    label_2
jump_to_label_8:
jmp    label_8
label_30:
mov    bx, ax
cmp    byte ptr ds:[bx + MOBJ_T.m_mobjtype], 0
jne    label_11
jump_to_label_7:
jmp    label_7
label_11:
mov    bx, _player + PLAYER_T.player_readyweapon
cmp    byte ptr ds:[bx], 7
jne    jump_to_label_7
jmp    label_6
label_24:
mov    ax, di
sar    ax, 1
jmp    label_28
label_27:
mov    word ptr ds:[bx], 0
jmp    label_26
jump_to_label_12:
jmp    label_12
label_32:
cmp    byte ptr ds:[_useDeadAttackerRef], 0
je     label_13
jmp    label_14
label_13:
imul   bx, ax, SIZEOF_MOBJ_POS_T
mov    ax, MOBJPOSLIST_6800_SEGMENT
mov    es, ax
mov    byte ptr ds:[_useDeadAttackerRef], 1
mov    dx, word ptr es:[bx]
mov    ax, word ptr es:[bx + 2]
mov    word ptr ds:[_deadAttackerX+0], dx
mov    word ptr ds:[_deadAttackerX+2], ax
mov    ax, word ptr es:[bx + 4]
mov    dx, word ptr es:[bx + 6]
mov    word ptr ds:[_deadAttackerY+0], ax
mov    word ptr ds:[_deadAttackerY+2], dx
jmp    label_14
label_34:
mov    bx, word ptr [bp - 4]
mov    cx, word ptr [bp - 2]
mov    ax, word ptr [bp - 6]
mov    dx, si
call   P_KillMobj_
LEAVE_MACRO  
pop    di
pop    si
retf   
label_8:
cmp    byte ptr ds:[si + MOBJ_T.m_mobjtype], MT_VILE
jne    label_9
jmp    label_10
label_9:
LEAVE_MACRO  
pop    di
pop    si
retf   

label_12:
db     09Ah
dw     GETSEESTATEADDR, INFOFUNCLOADSEGMENT

test   ax, ax
jne    label_29
jmp    exit_p_damagemobj
label_29:
mov    al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor    ah, ah
db     09Ah
dw     GETSEESTATEADDR, INFOFUNCLOADSEGMENT

mov    dx, ax
mov    ax, si
call   dword ptr [_P_SetMobjState]
LEAVE_MACRO  
pop    di
pop    si
retf   

ENDP

PROC    P_INTER_ENDMARKER_ 
PUBLIC  P_INTER_ENDMARKER_
ENDP


END