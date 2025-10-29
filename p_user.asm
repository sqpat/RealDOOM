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






EXTRN P_PlayerInSpecialSector_:NEAR
EXTRN P_SetMobjState_:NEAR
EXTRN P_MovePsprites_:NEAR
EXTRN P_UseLines_:NEAR

.DATA




.CODE

; kind of a local variable 
_onground:
db 0



PROC    P_USER_STARTMARKER_ NEAR
PUBLIC  P_USER_STARTMARKER_
ENDP




PROC    P_Thrust_ NEAR
PUBLIC  P_Thrust_

;void __near P_Thrust (fineangle_t angle, fixed_t move )  {

;	move <<= 11;
;	//move *= 2048L;
;	playerMobj->momx.w += FixedMulTrig(FINE_COSINE_ARGUMENT, angle, move);
;	playerMobj->momy.w += FixedMulTrig(FINE_SINE_ARGUMENT, angle, move);

push  dx

; note: move is actually a single byte.. we shift by 11, but implication is ch, cl, bl are 0 coming in.
; UPDATE: we pass vars in backwards. angle is in bx. move is in ah so we can cwd for sign.

cwd
mov   cx, dx
xchg  ax, bx  ; cx:bx is sign adjusted angle. pre shifted left 8

xchg  ax, dx  ; dx gets angle...
;mov   bh, bl ; shift 8
; pre-shifted by 8. we pass in the value in bh.
sal   bx, 1
rcl   cx, 1
sal   bx, 1
rcl   cx, 1
sal   bx, 1
rcl   cx, 1 ; shift 11
and   bx, 0F800h  ; shift mask bx

push  bx
push  cx  ; store for second call
push  dx  

mov   ax, FINECOSINE_SEGMENT
;call  FixedMulTrig_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrig_addr


mov   bx, word ptr ds:[_playerMobj]
add   word ptr ds:[bx + MOBJ_T.m_momx + 0], ax
adc   word ptr ds:[bx + MOBJ_T.m_momx + 2], dx
pop   dx
pop   cx
pop   bx
mov   ax, FINESINE_SEGMENT

;call  FixedMulTrig_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrig_addr


mov   bx, word ptr ds:[_playerMobj]
add   word ptr ds:[bx + MOBJ_T.m_momy + 0], ax
adc   word ptr ds:[bx + MOBJ_T.m_momy + 2], dx

pop   dx
ret  

ENDP


PROC    P_CalcHeight_ NEAR
PUBLIC  P_CalcHeight_

;void __near P_CalcHeight ()  {

PUSHA_NO_AX_OR_BP_MACRO

mov   si, word ptr ds:[_playerMobj]
mov   ax, word ptr ds:[si + MOBJ_T.m_ceilingz]
sub   ax, (4 SHL SHORTFLOORBITS)
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

push  ax
push  dx  ; store temp. hi then lo push order..

;player.bob.w =	FixedMul (playerMobj->momx.w, playerMobj->momx.w) + FixedMul (playerMobj->momy.w, playerMobj->momy.w);


les   ax, dword ptr ds:[si + MOBJ_T.m_momx + 0] 
mov   dx, es
mov   bx, ax
mov   cx, es
;call FixedMul_ ; todo make a near one?
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul_addr


xchg  ax, di
les   bx, dword ptr ds:[si + MOBJ_T.m_momy + 0]  ; last use of mobj. clobber si is fine..
mov   si, dx ; backip in si
mov   cx, es
mov   dx, es
mov   ax, bx
;call FixedMul_ ; todo make a near one?
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul_addr


add   ax, di
adc   dx, si

;	player.bob.w >>= 2;
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

;    if (player.bob.w>MAXBOB){
;		player.bob.w = MAXBOB;
;	}

cmp   dx, MAXBOB_HIGHBITS
jl    dont_cap_bob

mov   dx, MAXBOB_HIGHBITS
xor   ax, ax
dont_cap_bob:

mov   di, _player
mov   word ptr ds:[di + PLAYER_T.player_bob + 0], ax
mov   word ptr ds:[di + PLAYER_T.player_bob + 2], dx

mov   cx, CF_NOMOMENTUM ; get ch 0 too
cmp   byte ptr cs:[_onground], ch ; 0
je    dont_calc_bob_stuff
test  byte ptr ds:[di + PLAYER_T.player_cheats], cl
je    do_further_bob_stuff

dont_calc_bob_stuff:

        ; THIS CODE IS DUMMIED...  clobbered by further code in block
        ; les   di, dword ptr ds:[_playerMobjRef]
        ;les   di, dword ptr es:[di + MOBJ_POS_T.mp_z]
        ;mov   ax, es
        ;ax:di is z..
        ;add   ax, VIEWHEIGHT_HIGHBITS
        ;pop   cx
        ;pop   dx
        ;;dx:cx is temp
        ;cmp   ax, dx
        ;jl    dont_cap_z
        ;jg    do_cap_z
        ;cmp   di, cx
        ;jna   dont_cap_z
        ;do_cap_z:
        ;xchg  ax, dx
        ;mov   di, cx
        ;dont_cap_z:

;		player.viewzvalue.w = playerMobj_pos->z.w + player.viewheightvalue.w;


les   ax, dword ptr ds:[di + PLAYER_T.player_viewheightvalue + 0]
mov   dx, es

xor   si, si ; no temp check
jmp   finish_viewz_calc_and_exit_p_calcheight


do_further_bob_stuff:
;    angle = (FINEANGLES/20*leveltime.w)&FINEMASK;

xchg  ax, bx
mov   cx, dx  ; bob to cx:bx

mov   ax,   (FINEANGLES/20)
mul   word ptr ds:[_leveltime]
and   ah, (FINEMASK SHR 8)
xchg  ax, dx

sar   cx, 1
rcr   bx, 1
mov   ax, FINESINE_SEGMENT

;call  FixedMulTrig_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrig_addr


xchg  ax, bx
mov   cx, dx   ; cx:bx with bob


les   ax, dword ptr ds:[di + PLAYER_T.player_viewheightvalue] ; dx:ax will have player_viewheightvalue
mov   dx, es
cmp   byte ptr ds:[di + PLAYER_T.player_playerstate], PST_LIVE ; 0
jne   skip_live_height_checks
    lea   di, [di + PLAYER_T.player_deltaviewheight + 0]
    ; di is offset in this section.
    xor   si, si ; use si as 0 reg

    add   ax, word ptr ds:[di + 0]
    adc   dx, word ptr ds:[di + 2]

    cmp   dx, VIEWHEIGHT_HIGHBITS
    jl    dont_cap_viewheight_high
    jg    cap_viewheight_high
    test  ax, ax
    jz    dont_cap_viewheight_high
    cap_viewheight_high:
    xor   ax, ax
    mov   dx, VIEWHEIGHT_HIGHBITS
    mov   word ptr ds:[di + 0], ax ;zero
    mov   word ptr ds:[di + 2], ax
    jmp   done_with_viewheightcapping_all  ; the following checks would be guaranteed false...

    dont_cap_viewheight_high:
    cmp   dx, VIEWHEIGHT_HIGHBITS/2
    jg    done_with_viewheightcapping_low
    jl    cap_viewheight_low
    cmp   ax, 08000h  ; VIEWHEIGHT_HIGHBITS/2 lowbits
    jae   done_with_viewheightcapping_low
    cap_viewheight_low:
    mov   ax, 08000h
    mov   dx, VIEWHEIGHT_HIGHBITS
    cmp   word ptr ds:[di + 2], si 
    jg    done_with_viewheightcapping_low  ; positive
    jl    cap_delta
    ; zero...
    cmp   word ptr ds:[di + 0], si ; 0
    jne   done_with_viewheightcapping_low
    cap_delta:
    mov   word ptr ds:[di + 0], 04000h  ; it would have been added below. instead add now and skip that section
    inc   si
    mov   word ptr ds:[di + 2], si ; 1
    jmp   done_with_viewheightcapping_all

    done_with_viewheightcapping_low:
    cmp   word ptr ds:[di], si 
    jne   add_to_viewheight_again
    cmp   word ptr ds:[di + 2], si 
    je    done_with_viewheightcapping_all
    add_to_viewheight_again:
    add   word ptr ds:[di + 0], 04000h  
    adc   word ptr ds:[di + 2], si      ; 0
    jnz   done_with_viewheightcapping_all
    cmp   word ptr ds:[di], si   ; check zero again
    jne   done_with_viewheightcapping_all
    inc   word ptr ds:[di + 0] ; set to 1.

done_with_viewheightcapping_all:
; write these back

mov   word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 0], ax
mov   word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 2], dx  ; modified in this area, so write back player_viewheightvalue

skip_live_height_checks:
;	player.viewzvalue.w = playerMobj_pos->z.w + player.viewheightvalue.w + bob;
 ; finally...

add   ax, bx
adc   dx, cx  ; add bob. box was in cx:bx
mov   si, ds  ; nonzero flag


finish_viewz_calc_and_exit_p_calcheight:

les   di, dword ptr ds:[_playerMobj_pos]
add   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
adc   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2] ; add z

pop   bx ; get temp in cx:bx
pop   cx


test  si, si
je    skip_temp_check

;    if (player.viewzvalue.w > temp.w){
;		player.viewzvalue = temp;
;	}

cmp   dx, cx
jl    dont_cap_to_temp
jg    cap_to_temp
cmp   ax, bx
jna   dont_cap_to_temp
cap_to_temp:
xchg  ax, bx
mov   dx, cx

dont_cap_to_temp:
skip_temp_check:

mov   word ptr ds:[_player + PLAYER_T.player_viewzvalue + 0], ax  ; write player_viewzvalue back
mov   word ptr ds:[_player + PLAYER_T.player_viewzvalue + 2], dx
exit_p_calcheight:
POPA_NO_AX_OR_BP_MACRO
ret  


ENDP


PROC    P_MovePlayer_ NEAR
PUBLIC  P_MovePlayer_

PUSHA_NO_AX_OR_BP_MACRO

mov   ax, word ptr ds:[_player + PLAYER_T.player_cmd_angleturn]
les   di, dword ptr ds:[_playerMobj_pos]
add   word ptr es:[di + MOBJ_POS_T.mp_angle + 2], ax
mov   bx, word ptr ds:[_playerMobj]
mov   ax, word ptr ds:[bx + MOBJ_T.m_floorz]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

;    onground = (playerMobj_pos->z.w <= temp.w);

cmp   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
mov   al, 0
jl    not_on_floor
jg    on_floor
cmp   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
jb    not_on_floor
on_floor:
inc   ax ; al is 1
not_on_floor: ; al already 0
set_onground:
mov   byte ptr cs:[_onground], al
test  al, al
je    not_on_ground_cant_move

; onground known true.

mov   si, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
SHIFT_MACRO shr si SHORTTOFINESHIFT

mov   dx, word ptr ds:[_player + PLAYER_T.player_cmd_forwardmove] ; sidemove in dh

test  dl, dl
je    not_moving_forward
mov   ah, dl  ; ah gets forward move
mov   bx, si  ; bx gets ang intbits >> 3


call  P_Thrust_

not_moving_forward:

test  dh, dh
je    not_side_moving

xchg  ax, si ; get ang intbits
sub   ax, FINE_ANG90
and   ax, FINEMASK
mov   bh, dh
xchg  ax, bx ; bx gets ang


call  P_Thrust_

not_side_moving:

not_on_ground_cant_move:

test  dx, dx ; test move sidemove, forwardmove.
je    exit_p_moveplayer

les   di, dword ptr ds:[_playerMobj_pos]
cmp   word ptr es:[di + MOBJ_POS_T.mp_statenum], S_PLAY
jne   exit_p_moveplayer

mov   ax, word ptr ds:[_playerMobj]
mov   dx, S_PLAY_RUN1
call  P_SetMobjState_
exit_p_moveplayer:
POPA_NO_AX_OR_BP_MACRO
ret  



ENDP

; ANG5   ANG90/18

ANG5_HIGH = 038Eh
ANG5_LOW  = 038E3h

NEG_ANG5_HIGH = 0FC71h
NEG_ANG5_LOW  = 0C71Dh

use_dead_attackerref:
mov   si, _deadAttackerX
jmp   set_values_call_point_to_angle


PROC    P_DeathThink_ NEAR
PUBLIC  P_DeathThink_

PUSHA_NO_AX_OR_BP_MACRO
call  P_MovePsprites_

xor   ax, ax
cmp   word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 2], 6
jl    dont_dec_viewheight
jg    dec_viewheight
; equal. leave as 6, set fracbits to 0
mov   word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 0], ax ; 0
jmp   done_with_viewheight

dec_viewheight:
dec   word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 2]

dont_dec_viewheight:
done_with_viewheight:
mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight + 0], ax ; 0
mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight + 2], ax ; 0

les   di, dword ptr ds:[_playerMobj_pos]
mov   bx, word ptr ds:[_playerMobj]

mov   ax, word ptr ds:[bx + MOBJ_T.m_floorz]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

;    onground = (playerMobj_pos->z.w <= temp.w);

cmp   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
mov   al, 0
jl    not_on_floor_2
jg    on_floor_2
cmp   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
jb    not_on_floor_2
on_floor_2:
inc   ax ; al is 1
not_on_floor_2: ; al already 0

mov   byte ptr cs:[_onground], al

call  P_CalcHeight_


mov   ax, word ptr ds:[_player + PLAYER_T.player_attackerRef]
test  ax, ax
je    dec_damage_count

cmp   ax, word ptr ds:[_playerMobjRef]
je    dec_damage_count


cmp   byte ptr ds:[_useDeadAttackerRef], 0
jne   use_dead_attackerref

dont_use_dead_attackerref:

mov   bx, SIZEOF_MOBJ_POS_T
mul   bx  ; ax has attacker ref.
xchg  ax, si
mov   ds, word ptr ds:[_playerMobj_pos+2]


set_values_call_point_to_angle:

push  word ptr ds:[si + 6] ; MOBJ_POS_T.mp_y + 2 or _deadAttackerY + 2
push  word ptr ds:[si + 4] ; MOBJ_POS_T.mp_y + 0 or _deadAttackerY + 0
push  word ptr ds:[si + 2] ; MOBJ_POS_T.mp_x + 2 or _deadAttackerX + 2
push  word ptr ds:[si]     ; MOBJ_POS_T.mp_x + 0 or _deadAttackerX + 0

lds   di, dword ptr ss:[_playerMobj_pos]

les   bx, dword ptr ds:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, es
les   ax, dword ptr ds:[di + MOBJ_POS_T.mp_x + 0]
mov   dx, es

push  ss
pop   ds

call_point_to_angle:

;call  R_PointToAngle2_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_PointToAngle2_addr

;		delta.wu = angle.wu - playerMobj_pos->angle.wu;
les   di, dword ptr ds:[_playerMobj_pos]

mov   bx, ax
mov   cx, dx ; store angle in cx:bx back up in case setting later.
sub   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 0]
sbb   dx, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]


; if (delta.wu < ANG5 || delta.wu > (uint32_t)-ANG5) {
mov   si, ANG5_HIGH
mov   di, ANG5_LOW

cmp   dx, si
jb    face_killer
ja    check_neg_ang_5
cmp   ax, di
jb    face_killer
check_neg_ang_5:
cmp   dx, NEG_ANG5_HIGH
ja    face_killer
jb    check_ang_180
cmp   ax, NEG_ANG5_LOW
jbe   check_ang_180

face_killer:

les   si, dword ptr ds:[_playerMobj_pos]
; set stored cx:bx angle
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], bx
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], cx




dec_damage_count:

cmp   word ptr ds:[_player + PLAYER_T.player_damagecount], 0
je    dont_dec_damagecount
dec   word ptr ds:[_player + PLAYER_T.player_damagecount]
dont_dec_damagecount:

test  byte ptr ds:[_player + PLAYER_T.player_cmd_buttons], BT_USE
je    no_reborn

mov   byte ptr ds:[_player + PLAYER_T.player_playerstate], PST_REBORN
no_reborn:


POPA_NO_AX_OR_BP_MACRO
ret  





check_ang_180:
les   bx, dword ptr ds:[_playerMobj_pos]

test  dx, dx   ; cmp ANG180_HIGHBITS
jns   add_ang_5 ; < 0x8000
neg   si
neg   di
sbb   si, 0
add_ang_5:
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], di
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], si
jmp   dont_dec_damagecount



ENDP


PROC    P_PlayerThink_ NEAR
PUBLIC  P_PlayerThink_


PUSHA_NO_AX_OR_BP_MACRO

les   di, dword ptr ds:[_playerMobj_pos]
test  byte ptr ds:[_player + PLAYER_T.player_cheats], CF_NOCLIP
je    clip_off
or    byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_NOCLIP SHR 8)
jmp   done_with_clip
clip_off:

and   byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (NOT (MF_NOCLIP SHR 8))
done_with_clip:
mov   bx, _player
mov   ax, 100
cwd  ; dx 0 for the function
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
je    skip_chainsaw_run_forward
mov   word ptr ds:[bx + PLAYER_T.player_cmd_angleturn], dx  ; two two byte writes of 0... ok?
mov   word ptr ds:[bx + PLAYER_T.player_cmd_forwardmove], ax ; 100
and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTATTACKED)
skip_chainsaw_run_forward:

cmp   byte ptr ds:[bx + PLAYER_T.player_playerstate], PST_DEAD
jne   not_dead
call  P_DeathThink_
jmp   exit_player_think

not_dead:

mov   si, word ptr ds:[_playerMobj]
cmp   byte ptr ds:[si + MOBJ_T.m_reactiontime], dl ; 0
jne   dec_reactiontime


call  P_MovePlayer_
jmp   done_with_player_movement

dec_reactiontime:

dec   byte ptr ds:[si + MOBJ_T.m_reactiontime]
done_with_player_movement:


call  P_CalcHeight_

mov   si, word ptr ds:[si + MOBJ_T.m_secnum]
SHIFT_MACRO shl   si 4

cmp   byte ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_special], dl ; 0 
je    skip_player_sector_special
call  P_PlayerInSpecialSector_
skip_player_sector_special:

mov   al, byte ptr ds:[bx + PLAYER_T.player_cmd_buttons]
test  al, BT_SPECIAL
jne   zero_buttons

do_buttons_check:
test  al, BT_CHANGE
je   check_for_use

and   ax, BT_WEAPONMASK  ; 8 + 16 + 32
SHIFT_MACRO shr   ax, BT_WEAPONSHIFT
test  al, al 
jne   not_chainsaw
cmp   byte ptr ds:[bx + PLAYER_T.player_weaponowned + WP_CHAINSAW], dl
je    not_chainsaw
cmp   byte ptr ds:[bx + PLAYER_T.player_readyweapon], WP_CHAINSAW
jne   set_chainsaw
cmp   word ptr ds:[bx + PLAYER_T.player_powers + (PW_STRENGTH * 2)], dx
jne   not_chainsaw
set_chainsaw:
mov   al, WP_CHAINSAW

not_chainsaw:

cmp   byte ptr ds:[_commercial], dl
je    not_supershotgun
cmp   al, WP_SHOTGUN
jne   not_supershotgun
cmp   byte ptr ds:[bx + PLAYER_T.player_weaponowned + WP_SUPERSHOTGUN], dl
je    not_supershotgun
cmp   byte ptr ds:[bx + PLAYER_T.player_readyweapon], WP_SUPERSHOTGUN
je    not_supershotgun
mov   al, WP_SUPERSHOTGUN
not_supershotgun:

mov   si, ax
cmp   byte ptr ds:[si + bx + PLAYER_T.player_weaponowned], dl
je    dont_change_weapon

cmp   al, byte ptr ds:[bx + PLAYER_T.player_readyweapon]
je    dont_change_weapon
cmp   byte ptr ds:[_shareware], dl
je    do_equip_weapon

cmp   al, WP_PLASMA
je    dont_change_weapon
cmp   al, WP_BFG
je    dont_change_weapon
do_equip_weapon:

mov   byte ptr ds:[bx + PLAYER_T.player_pendingweapon], al
dont_change_weapon:

check_for_use:
test  byte ptr ds:[bx + PLAYER_T.player_cmd_buttons], BT_USE
je    zero_usedown
cmp   byte ptr ds:[bx +  PLAYER_T.player_usedown], dl
jne   done_with_buttons


call      P_UseLines_

mov   byte ptr ds:[bx +  PLAYER_T.player_usedown], 1
jmp   done_with_buttons


zero_buttons:
mov   byte ptr ds:[bx + PLAYER_T.player_cmd_buttons], dl ; 0
zero_usedown:

mov   byte ptr ds:[bx + PLAYER_T.player_usedown], dl ; 0
done_with_buttons:

call  P_MovePsprites_

push  ds
pop   es

lea   si, [bx + PLAYER_T.player_damagecount]
mov   di, si

; damage count
lodsw
dec   ax
jns   write_damagecount
inc   ax ; undo
write_damagecount:
stosw

; bonus count
lodsb
dec   al
jns   write_bonuscount
inc   al ; undo
write_bonuscount:
stosb

lea   si, [bx + PLAYER_T.player_powers + (PW_INVULNERABILITY * 2)]
mov   di, si


; invuln
lodsw
dec   ax
jns   write_invuln
inc   ax ; undo
write_invuln:
stosw

xchg  ax, cx ; cx store invuln

; berserk
lodsw
inc   ax
js    write_berserk
dec   ax ; undo
write_berserk:
stosw


; invis
lodsw
dec   ax
jns   write_invis
inc   ax ; undo
write_invis:
stosw


; radsuit
lodsw
dec   ax
jns   write_radsuit
inc   ax ; undo
write_radsuit:
stosw

movsw ; skip allmap


; infrared
lodsw
dec   ax
jns   write_infrared
inc   ax ; undo
write_infrared:
stosw

xchg  ax, si ; si has infrared




mov   byte ptr ds:[bx + PLAYER_T.player_fixedcolormapvalue], dl ; 0

xchg  ax, cx ; invuln
test  ax, ax
jne   invul_wearing_off_colormap
xchg  ax, si ; infra
test  ax, ax
je    exit_player_think
cmp   ax, (4 * 32)
jg    set_colormap_1
test  al, 8
je    exit_player_think

set_colormap_1:
mov   byte ptr ds:[bx + PLAYER_T.player_fixedcolormapvalue], 1
jmp   exit_player_think

invul_wearing_off_colormap:
cmp   ax, (4 * 32)
jg    set_inverse_colormap
test  al, 8
je    exit_player_think

set_inverse_colormap:
mov   byte ptr ds:[bx + PLAYER_T.player_fixedcolormapvalue], INVERSECOLORMAP

exit_player_think:
POPA_NO_AX_OR_BP_MACRO
ret   






ENDP


PROC    P_USER_ENDMARKER_ NEAR
PUBLIC  P_USER_ENDMARKER_
ENDP

END
