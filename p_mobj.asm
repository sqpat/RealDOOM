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



EXTRN G_ExitLevel_:PROC
EXTRN P_RemoveThinker_:NEAR
EXTRN G_PlayerReborn_:PROC

EXTRN Z_QuickMapScratch_8000_:PROC
EXTRN Z_QuickMapPhysicsCode_:PROC
EXTRN Z_QuickMapPhysics_:PROC
EXTRN Z_QuickMapStatus_:PROC
EXTRN HU_Start_:PROC
EXTRN ST_Start_:PROC
EXTRN S_StopSoundMobjRef_:PROC


.DATA



.CODE

VIEWHEIGHT_HIGHBITS = 41
VIEWHEIGHT_LOWBITS = 0
ONFLOORZ_HIGHBITS = 08000h
ONFLOORZ_LOWBITS = 0
ONCEILINGZ_HIGHBITS = 07FFFh
ONCEILINGZ_LOWBITS = 0FFFFh
; todo move this to p_mobja when its not called anymore from doom.exe code
; openwatcom wont allow pragma to force z param into di/si when called as a variable instead of function


;void __near P_SpawnPuff ( fixed_t	x, fixed_t	y, fixed_t	z ){

;P_SpawnPuff_

PROC P_SpawnPuff_ NEAR
PUBLIC P_SpawnPuff_


push  ax
push  dx
push  bx

mov   ax, RNDTABLE_SEGMENT
mov   es, ax

mov   al, byte ptr ds:[_prndindex]
add   byte ptr ds:[_prndindex], 3  ; for 3 calls this func..
xor   ah, ah
mov   bx, ax
inc   bx
mov   al, byte ptr es:[bx]
sub   al, byte ptr es:[bx+1]

sbb   ah, 0
cwd

; shift ax left 10
mov   dl, ah ; shift 8
mov   ah, al ; shift 8
sal   ax, 1
rcl   dx, 1
sal   ax, 1
rcl   dx, 1
and   ax, 0FC00h  ; clean out bottom bits


add   si, ax
adc   di, dx

mov   al, byte ptr es:[bx+2]
mov   byte ptr cs:[SELFMODIFY_set_rnd_value_3+1], al  

pop   bx
pop   dx
pop   ax

IF COMPISA GE COMPILE_186

push  -1        ; complicated for 8088...
push  MT_PUFF
push  di
push  si


ELSE

mov   es, si
mov   si, -1
push  si
mov   si, MT_PUFF
push  si
push  di
push  es


ENDIF


;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr
;	 th = setStateReturn;
;    th->momz.h.intbits = 1;
;    th->tics -= P_Random()&3;

mov   bx, word ptr ds:[_setStateReturn];
mov   word ptr ds:[bx + 018h], 1
SELFMODIFY_set_rnd_value_3:
mov   al, 0FFh
and   al, 3
sub   byte ptr ds:[bx + 01Bh], al

;    if (th->tics < 1 || th->tics > 240){
;		th->tics = 1;
;	}


mov   al, byte ptr ds:[bx + 01Bh]
cmp   al, 1
jb    set_tics_to_1
cmp   al, 240
jbe   dont_set_tics_to_1
set_tics_to_1:
mov   byte ptr ds:[bx + 01Bh], 1
dont_set_tics_to_1:
cmp   word ptr ds:[_attackrange16], MELEERANGE
je    spark_punch_on_wall
retf  
spark_punch_on_wall:
mov   dx, S_PUFF3
mov   ax, bx
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
retf   



ENDP




PROC P_Random_ NEAR
PUBLIC P_Random_

; ah guaranteed 0 now!
push    bx
inc 	byte ptr ds:[_prndindex]
mov     ax, RNDTABLE_SEGMENT
mov     es, ax
xor     ax, ax
mov     bx, ax
mov     al, byte ptr ds:[_prndindex]
xlat    byte ptr es:[bx]
pop     bx
ret

ENDP


COMMENT @
; INLINED AT SINGLE USE
PROC P_SetupPsprites_ NEAR
PUBLIC P_SetupPsprites_

mov       word ptr ds:[_psprites + (0 * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_statenum], STATENUM_NULL
mov       word ptr ds:[_psprites + (1 * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_statenum], STATENUM_NULL
mov       al, byte ptr ds:[_player + PLAYER_T.player_readyweapon]
mov       byte ptr ds:[_player + PLAYER_T.player_pendingweapon], al
db        09Ah
dw        P_BRINGUPWEAPONFAROFFSET, PHYSICS_HIGHCODE_SEGMENT
ret       

ENDP

@


PROC P_SpawnPlayer_ NEAR
PUBLIC P_SpawnPlayer_

push      bx
push      cx

mov       bx, ax

mov       dx, word ptr ds:[bx + MAPTHING_T.mapthing_x]
mov       cx, word ptr ds:[bx + MAPTHING_T.mapthing_y]
push      word ptr ds:[bx + MAPTHING_T.mapthing_angle]  ; for later

cmp       byte ptr ds:[_player + PLAYER_T.player_playerstate], PST_REBORN
jne       dont_player_reborn
call      G_PlayerReborn_
dont_player_reborn:

xor       bx, bx

IF COMPISA GE COMPILE_186
    push      -1
    push      bx
    push      ONFLOORZ_HIGHBITS
    push      bx
ELSE
    mov       ax, -1
    push      ax
    push      bx
    mov       ax, ONFLOORZ_HIGHBITS
    push      ax
    push      bx
ENDIF

mov       ax, bx
call      P_SpawnMobj_

mov       word ptr ds:[_playerMobjRef], ax
mov       dx, SIZEOF_THINKER_T
mul       dx
add       ax, (_thinkerlist + THINKER_T.t_data)

mov       word ptr ds:[_playerMobj], ax

mov       ax, SIZEOF_MOBJ_POS_T
mul       word ptr ds:[_playerMobjRef]

mov       word ptr ds:[_playerMobj_pos], ax
mov       word ptr ds:[_playerMobj_pos + 2], MOBJPOSLIST_6800_SEGMENT  

pop       ax ; retrieve stored angle
cwd       

mov       cx, 45
idiv      cx
mov       cx, ANG45_HIGHBITS
xor       bx, bx
;call      FastMul16u32u_
; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr

les       bx, dword ptr ds:[_playerMobj_pos]
mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx

mov       bx, word ptr ds:[_playerMobj]
push      word ptr ds:[_player + PLAYER_T.player_health]
pop       word ptr ds:[bx + MOBJ_T.m_health]

xor       ax, ax
mov       byte ptr ds:[bx + MOBJ_T.m_reactiontime], al

mov       word ptr ds:[_player + PLAYER_T.player_damagecount], ax
mov       byte ptr ds:[_player + PLAYER_T.player_playerstate], al
mov       byte ptr ds:[_player + PLAYER_T.player_refire], al
mov       byte ptr ds:[_player + PLAYER_T.player_bonuscount], al
mov       byte ptr ds:[_player + PLAYER_T.player_extralightvalue], al
mov       byte ptr ds:[_player + PLAYER_T.player_fixedcolormapvalue], al




mov       word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 0], ax
mov       word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 2], VIEWHEIGHT_HIGHBITS
;call      P_SetupPsprites_

dec       ax
mov       word ptr ds:[_player + PLAYER_T.player_message], ax

; inlined
mov       word ptr ds:[_psprites + (0 * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_statenum], ax
mov       word ptr ds:[_psprites + (1 * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_statenum], ax
mov       al, byte ptr ds:[_player + PLAYER_T.player_readyweapon]
mov       byte ptr ds:[_player + PLAYER_T.player_pendingweapon], al
db        09Ah
dw        P_BRINGUPWEAPONFAROFFSET, PHYSICS_HIGHCODE_SEGMENT



call      Z_QuickmapStatus_

call      ST_Start_
call      HU_Start_

call      Z_QuickMapPhysics_
call      Z_QuickMapScratch_8000_   ; // gross, due to p_setup.... perhaps externalize.
call      Z_QuickMapPhysicsCode_

pop       cx
pop       bx
ret       

ENDP


PROC P_SpawnMapThing_ FAR
PUBLIC P_SpawnMapThing_



;void __far P_SpawnMapThing(mapthing_t mthing, int16_t key) {
    
; ugh. big params. NOTE if moved near this will all shift 2.



push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp

mov       si, word ptr [bp + 010h + MAPTHING_T.mapthing_type]

cmp       si, 11
jne       thing_type_not_11
jmp       exit_spawnmapthing_2
thing_type_not_11:
cmp       si, 2
je        exit_spawnmapthing_2
cmp       si, 3
je        exit_spawnmapthing_2
cmp       si, 4
je        exit_spawnmapthing_2
cmp       si, 1
jne       spawn_not_player
; spawn player..
lea       ax, [bp + 010h]
call      P_SpawnPlayer_
exit_spawnmapthing_2:
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      0Ch

spawn_not_player:



test      byte ptr [bp + 010h + MAPTHING_T.mapthing_options], 010h  ; todo what 'option' is this?
jne       exit_spawnmapthing_2

mov       al, byte ptr ds:[_gameskill]
xor       ah, ah
test      al, al
je        use_bit_1

cmp       al, SK_NIGHTMARE
jne       calculate_bit
mov       al, 4
jmp       bit_calculcated
calculate_bit:
dec       ax
mov       cx, ax
mov       al, 1
shl       ax, cl
jmp       bit_calculcated

use_bit_1:
mov       al, 1
bit_calculcated:

test      word ptr [bp + 010h + MAPTHING_T.mapthing_options], ax
je        exit_spawnmapthing_2
mov       ax, DOOMEDNUM_SEGMENT   ; todo almost near?
mov       es, ax

xor       bx, bx
loop_try_next_thingtype:

cmp       si, word ptr es:[bx]
je        break_thing_loop
inc       bx
inc       bx
cmp       bx, (NUMMOBJTYPES * 2)
jge       break_thing_loop   ; in theory should error, whatever, assume good data.
jmp       loop_try_next_thingtype


break_thing_loop:
xchg      ax, bx
sar       ax, 1
cmp       byte ptr ds:[_nomonsters], 0
je        do_spawn_monster
cmp       ax, MT_SKULL
je        exit_spawnmapthing_2
IF COMPISA GE COMPILE_186
    imul  bx, ax, SIZEOF_MOBJINFO_T ; todo 8 bit mul
ELSE
    xchg  ax, bx
    mov   ax, SIZEOF_MOBJINFO_T
    mul   bx
    xchg  ax, bx
ENDIF
test      byte ptr ds:[bx + _mobjinfo + MOBJINFO_T.mobjinfo_flags2], MF_COUNTKILL
jne       exit_spawnmapthing_2

do_spawn_monster:

xchg      ax, bx
mov       al, SIZEOF_MOBJINFO_T
mul       bl
xchg      ax, bx

; mobjRef = P_SpawnMobj(x.w, y.w, z.w, i, -1);

IF COMPISA GE COMPILE_186
    push      -1
ELSE
    mov       dx, -1
    push      dx
ENDIF

xor       ah, ah
push      ax

xor       ax, ax

test      byte ptr ds:[bx + _mobjinfo +MOBJINFO_T.mobjinfo_flags1 + 1], (MF_SPAWNCEILING SHR 8)
jne       do_spawn_ceiling

IF COMPISA GE COMPILE_186
    push      ONFLOORZ_HIGHBITS
    push      ax ; zero
ELSE
    mov       dx, ONFLOORZ_HIGHBITS
    push      dx
    push      ax ; zero
ENDIF

jmp       got_starting_z

do_spawn_ceiling:

IF COMPISA GE COMPILE_186
    push      ONCEILINGZ_HIGHBITS
    push      ONCEILINGZ_LOWBITS
ELSE
    mov       dx, ONCEILINGZ_HIGHBITS
    push      dx
    mov       dx, ONCEILINGZ_LOWBITS
    push      dx
ENDIF


got_starting_z:

mov       bx, ax ; zero
mov       dx, word ptr [bp + 010h + MAPTHING_T.mapthing_x]
mov       cx, word ptr [bp + 010h + MAPTHING_T.mapthing_y]


call      P_SpawnMobj_

mov       di, SIZEOF_MAPTHING_T
mul       di
xchg      ax, di 

lea       si, [bp + 010h]

mov       ax, NIGHTMARESPAWNS_SEGMENT
mov       es, ax
movsw     
movsw     
movsw     
movsw     
movsw     

mov       si, word ptr ds:[_setStateReturn]
mov       al, byte ptr ds:[si + MOBJ_T.m_tics]

test      al, al
jbe       dont_set_random_tics
cmp       al, 240
jae       dont_set_random_tics

;		mobj->tics = 1 + (P_Random() % mobj->tics);


inc       byte ptr ds:[_prndindex]
mov       bl, byte ptr ds:[_prndindex]
xor       bh, bh

mov       dl, al

mov       ax, RNDTABLE_SEGMENT
mov       es, ax

mov       al, byte ptr es:[bx]
xor       ah, ah
div       dl
inc       ah

mov       byte ptr ds:[si + MOBJ_T.m_tics], ah

dont_set_random_tics:
les       bx, dword ptr ds:[_setStateReturn_pos]
test      byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_COUNTKILL
je        not_killable
inc       word ptr ds:[_totalkills]
not_killable:

test      byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_COUNTITEM
je        not_an_item
inc       word ptr ds:[_totalitems]
not_an_item:
mov       ax, word ptr [bp + 010h + MAPTHING_T.mapthing_angle]
cwd       
mov       bx, dx ; zero
mov       cx, 45
idiv      cx
mov       cx, ANG45_HIGHBITS
;call      FastMul16u32u_
; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr
les       bx, dword ptr ds:[_setStateReturn_pos]
mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
test      byte ptr [bp + 010h + MAPTHING_T.mapthing_options], MTF_AMBUSH
jne       set_ambush_and_exit
jmp       exit_spawnmapthing_2

set_ambush_and_exit:
or        byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_AMBUSH
jmp       exit_spawnmapthing_2

ENDP


PROC P_MobjThinker_ NEAR
PUBLIC P_MobjThinker_

;void __near P_MobjThinker (mobj_t __near* mobj, mobj_pos_t __far* mobj_pos, THINKERREF mobjRef) {
; ax    mobj
; dx    ref
; cx:bx mobjpos

push      si
push      di
mov       si, ax
mov       di, bx
mov       es, cx

mov       ax, word ptr ds:[si + MOBJ_T.m_momx + 0]
or        ax, word ptr ds:[si + MOBJ_T.m_momx + 2]
jne       do_xy_movement
mov       ax, word ptr ds:[si + MOBJ_T.m_momy + 2]
or        ax, word ptr ds:[si + MOBJ_T.m_momy + 0]
jne       do_xy_movement
test      byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], (MF_SKULLFLY SHR 8)
je        done_with_xy_movement

do_xy_movement:
mov       bx, di
mov       ax, si

db 09Ah
dw P_XYMOVEMENTOFFSET, PHYSICS_HIGHCODE_SEGMENT



IF COMPISA GE COMPILE_186
    imul  bx, dx, SIZEOF_THINKER_T
ELSE
    push  dx
    mov   ax, SIZEOF_THINKER_T
    mul   dx
    xchg  ax, bx
    pop   dx
ENDIF


mov       ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]

and       ax, TF_FUNCBITS
cmp       ax, TF_DELETEME_HIGHBITS
je        exit_p_mobjthinker


done_with_xy_movement:
mov       cx, MOBJPOSLIST_6800_SEGMENT
mov       es, cx

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  mobj->floorz);

xor       ax, ax
mov       bx, word ptr ds:[si + 6]
sar       bx, 1
rcr       ax, 1
sar       bx, 1
rcr       ax, 1
sar       bx, 1
rcr       ax, 1


cmp       bx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
jne       do_z_movement
cmp       ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
jne       do_z_movement

mov       ax, word ptr ds:[si + MOBJ_T.m_momz + 2]
or        ax, word ptr ds:[si + MOBJ_T.m_momz + 0]
je        done_with_z_movement
do_z_movement:

mov       bx, di
mov       ax, si

db 09Ah
dw P_ZMOVEMENTOFFSET, PHYSICS_HIGHCODE_SEGMENT




IF COMPISA GE COMPILE_186
    imul  bx, dx, SIZEOF_THINKER_T
ELSE
    push  dx
    mov   ax, SIZEOF_THINKER_T
    mul   dx
    xchg  ax, bx
    pop   dx

ENDIF



mov       ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
and       ax, TF_FUNCBITS
cmp       ax, TF_DELETEME_HIGHBITS
jne       done_with_z_movement
exit_p_mobjthinker:
pop       di
pop       si
ret       


done_with_z_movement:
mov       cx, MOBJPOSLIST_6800_SEGMENT
mov       es, cx

cmp       byte ptr ds:[si + MOBJ_T.m_tics], 255
je        tics_255
dec       byte ptr ds:[si + MOBJ_T.m_tics]
jne       exit_p_mobjthinker

mov       di, word ptr es:[di + MOBJ_POS_T.mp_statenum]
mov       ax, SIZEOF_STATE_T
mul       di
xchg      ax, di
mov       ax, STATES_SEGMENT
mov       es, ax

mov       ax, si
mov       dx, word ptr es:[di + STATE_T.state_nextstate]

;call      P_SetMobjState_
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr

jmp       exit_p_mobjthinker
tics_255:

test      byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_COUNTKILL
je        exit_p_mobjthinker
cmp       byte ptr ds:[_respawnmonsters], 0
je        exit_p_mobjthinker
inc       word ptr ds:[si + MOBJ_T.m_movecount]
cmp       word ptr ds:[si + MOBJ_T.m_movecount], (12 * 35)
jl        exit_p_mobjthinker
test      byte ptr ds:[_leveltime], 31
jne       exit_p_mobjthinker


inc       byte ptr ds:[_prndindex]
mov       bl, byte ptr ds:[bx]
mov       ax, RNDTABLE_SEGMENT
mov       es, ax
xor       bh, bh
mov       al, byte ptr es:[bx]
cmp       al, 4
ja        exit_p_mobjthinker

mov       bx, di
mov       ax, si


db 09Ah
dw P_NIGHTMARERESPAWNOFFSET, PHYSICS_HIGHCODE_SEGMENT
pop       di
pop       si
ret       

ENDP


PROC P_SpawnMobj_ FAR
PUBLIC P_SpawnMobj_


;THINKERREF __far P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type, int16_t knownsecnum ) {

; ugh also modify this when made near...
; bp + 010h knownsecnum
; bp + 0E   type
; bp + 0C   z hi
; bp + 0A   z lo


; bp - 2    mobjRef





push      si
push      di
push      bp
mov       bp, sp
sub       sp, 2    ; need stack frame due to stack params. sad

push      ax
push      dx
push      bx
push      cx
mov       ax, TF_MOBJTHINKER_HIGHBITS

;call      P_CreateThinker_
 db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr

mov       si, ax
sub       ax, (_thinkerlist + THINKER_T.t_data)
xor       dx, dx
mov       cx, SIZEOF_THINKER_T
div       cx

mov       word ptr [bp - 2], ax

IF COMPISA GE COMPILE_186
    imul      di, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov       di, SIZEOF_MOBJ_POS_T
    mul       di
    xchg      ax, di
ENDIF

;	memset(mobj, 0, sizeof(mobj_t));
;	FAR_memset(mobj_pos, 0, sizeof (mobj_pos_t));



xchg      si, di
xor       ax, ax
push      ds
pop       es
mov       cx, SIZEOF_MOBJ_T / 2
rep stosw 

xchg      si, di

mov       cx, SIZEOF_MOBJ_POS_T / 2
mov       dx, MOBJPOSLIST_6800_SEGMENT
mov       es, dx

rep stosw 

sub       di, SIZEOF_MOBJ_POS_T
sub       si, SIZEOF_MOBJ_T


mov       cl, byte ptr [bp + 0Eh]  ; type
mov       al, SIZEOF_MOBJINFO_T
mul       cl

add       ax, OFFSET _mobjinfo
xchg      ax, cx                        ; al gets type!
mov       bx, cx

mov       byte ptr ds:[si + MOBJ_T.m_mobjtype], al



; ax thru dx original arguments.
pop       word ptr es:[di + MOBJ_POS_T.mp_y + 2]
pop       word ptr es:[di + MOBJ_POS_T.mp_y + 0]
pop       word ptr es:[di + MOBJ_POS_T.mp_x + 2]
pop       word ptr es:[di + MOBJ_POS_T.mp_x + 0]

push      ax

; ds:bx is mobjinfo
; ds:si is mobj
; es:di is mobjpos

mov       al, byte ptr ds:[bx + MOBJINFO_T.mobjinfo_radius]
mov       byte ptr ds:[si + MOBJ_T.m_radius], al
xor       ax, ax
mov       word ptr ds:[si + MOBJ_T.m_height + 0], 0
mov       al, byte ptr ds:[bx + MOBJINFO_T.mobjinfo_height]
mov       word ptr ds:[si + MOBJ_T.m_height + 2], ax

push      word ptr ds:[bx + MOBJINFO_T.mobjinfo_flags1]
pop       word ptr es:[di + MOBJ_POS_T.mp_flags1]
push      word ptr ds:[bx + MOBJINFO_T.mobjinfo_flags2]
pop       word ptr es:[di + MOBJ_POS_T.mp_flags2]

pop       ax

db 09Ah
dw GETSPAWNHEALTHADDR, INFOFUNCLOADSEGMENT


mov       word ptr ds:[si + MOBJ_T.m_health], ax
cmp       byte ptr ds:[_gameskill], SK_NIGHTMARE
je        skill_not_nightmare
mov       byte ptr ds:[si + MOBJ_T.m_reactiontime], 8
skill_not_nightmare:

inc       byte ptr ds:[_prndindex]

mov       ax, MOBJPOSLIST_6800_SEGMENT
mov       es, ax

mov       ax, word ptr ds:[bx + MOBJINFO_T.mobjinfo_spawnstate]
mov       word ptr es:[di + MOBJ_POS_T.mp_statenum], ax


mov       bx, 6
mul       bx
xchg      ax, bx

mov       ax, STATES_SEGMENT
mov       es, ax

mov       dx, di
mov       al, byte ptr es:[bx + STATE_T.state_tics]
mov       bx, word ptr [bp + 010h]
mov       byte ptr ds:[si + MOBJ_T.m_tics], al
mov       ax, si
;call      dword ptr ds:[_P_SetThingPosition]
db        09Ah
dw        P_SETTHINGPOSITIONOFFSET, PHYSICS_HIGHCODE_SEGMENT


mov       bx, word ptr ds:[si + MOBJ_T.m_secnum]
SHIFT_MACRO shl       bx 4
mov       ax, SECTORS_SEGMENT
mov       es, ax
mov       ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
mov       word ptr ds:[si + MOBJ_T.m_floorz], ax
mov       ax, word ptr es:[bx + SECTOR_T.sec_ceilingheight]
mov       word ptr ds:[si + MOBJ_T.m_ceilingz], ax

mov       ax, MOBJPOSLIST_6800_SEGMENT
mov       es, ax
xor       dx, dx

cmp       word ptr [bp + 0Ch], ONFLOORZ_HIGHBITS
jne       not_floor_spawn
cmp       word ptr [bp + 0Ah], 0
je        is_floor_spawn
not_floor_spawn:
cmp       word ptr [bp + 0Ch], ONCEILINGZ_HIGHBITS
jne       not_ceiling_spawn
cmp       word ptr [bp + 0Ah], ONCEILINGZ_LOWBITS
jne       not_ceiling_spawn

mov       bx, cx
mov       ax, word ptr ds:[si + MOBJ_T.m_ceilingz]


sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1

sub       al, byte ptr ds:[bx + MOBJINFO_T.mobjinfo_height]

sbb       ah, dl  ; guaranteed dl 0...

write_z:
mov       word ptr es:[di + MOBJ_POS_T.mp_z + 0], dx
mov       word ptr es:[di + MOBJ_POS_T.mp_z + 2], ax


mov       word ptr ds:[_setStateReturn], si

mov       word ptr ds:[_setStateReturn_pos + 0], di
mov       word ptr ds:[_setStateReturn_pos + 2], es
mov       ax, word ptr [bp - 2]
LEAVE_MACRO     
pop       di
pop       si
retf      8
is_floor_spawn:


mov       ax, word ptr ds:[si + MOBJ_T.m_floorz]

sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1

jmp       write_z ; todo cleanup. do two writes at once
not_ceiling_spawn:

mov       dx, word ptr [bp + 0Ah]
mov       ax, word ptr [bp + 0Ch]
jmp       write_z

ENDP




PROC P_RemoveMobj_ FAR
PUBLIC P_RemoveMobj_



push      cx
push      dx

push      ax  ; store mobj

mov       cx, SIZEOF_THINKER_T
sub       ax, (_thinkerlist + THINKER_T.t_data)
xor       dx, dx
div       cx  ; get mobjref

pop       cx  ;  store mobj in cx
push      ax  ; store mobjref for later

IF COMPISA GE COMPILE_186
    imul  dx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov   dx, SIZEOF_MOBJ_POS_T
    mul   dx
    xchg  ax, dx
ENDIF

mov       ax, cx

;call      dword ptr ds:[_P_UnsetThingPosition]
db        09Ah
dw        P_UNSETTHINGPOSITIONOFFSET, PHYSICS_HIGHCODE_SEGMENT

mov       ax, cx
call      S_StopSoundMobjRef_
       
pop       ax  ; restore div result (mobjref)
call      P_RemoveThinker_

pop       dx
pop       cx
retf      
ENDP





END
