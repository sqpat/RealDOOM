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


COMMENT @

PROC P_Random_ NEAR
PUBLIC P_Random_


0x0000000000007e20:  53                   push      bx
0x0000000000007e21:  56                   push      si
0x0000000000007e22:  BB B8 01             mov       bx, OFFSET _prndindex
0x0000000000007e25:  FE 07                inc       byte ptr ds:[bx]
0x0000000000007e27:  BE 65 3C             mov       si, RNDTABLE_SEGMENT
0x0000000000007e2a:  8A 1F                mov       bl, byte ptr ds:[bx]
0x0000000000007e2c:  8E C6                mov       es, si
0x0000000000007e2e:  30 FF                xor       bh, bh
0x0000000000007e30:  26 8A 07             mov       al, byte ptr es:[bx]
0x0000000000007e33:  5E                   pop       si
0x0000000000007e34:  5B                   pop       bx
0x0000000000007e35:  C3                   ret       

ENDP


PROC P_SetupPsprites_ NEAR
PUBLIC P_SetupPsprites_


0x0000000000007e36:  53                   push      bx
0x0000000000007e37:  56                   push      si
0x0000000000007e38:  BB 88 03             mov       bx, OFFSET _psprites + PSPDEF_T.pspdef_statenum
0x0000000000007e3b:  C7 07 FF FF          mov       word ptr ds:[bx], STATENUM_NULL
0x0000000000007e3f:  BB 94 03             mov       bx, OFFSET _psprites + (1 * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_statenum
0x0000000000007e42:  C7 07 FF FF          mov       word ptr ds:[bx], STATENUM_NULL
0x0000000000007e46:  BB 00 08             mov       bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000007e49:  BE 01 08             mov       si, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000007e4c:  8A 1F                mov       bl, byte ptr ds:[bx]
0x0000000000007e4e:  88 1C                mov       byte ptr ds:[si], bl
0x0000000000007e50:  FF 1E 04 0D          lcall     ds:[P_BringUpWeaponFar_]
0x0000000000007e54:  5E                   pop       si
0x0000000000007e55:  5B                   pop       bx
0x0000000000007e56:  C3                   ret       

ENDP


PROC P_SpawnPlayer NEAR
PUBLIC P_SpawnPlayer

0x0000000000007e58:  53                   push      bx
0x0000000000007e59:  51                   push      cx
0x0000000000007e5a:  56                   push      si
0x0000000000007e5b:  89 C3                mov       bx, ax
0x0000000000007e5d:  8E C2                mov       es, dx
0x0000000000007e5f:  26 8B 17             mov       dx, word ptr es:[bx]
0x0000000000007e62:  26 8B 4F 02          mov       cx, word ptr es:[bx + 2]
0x0000000000007e66:  26 8B 77 04          mov       si, word ptr es:[bx + 4]
0x0000000000007e6a:  BB ED 07             mov       bx, OFFSET _player PLAYER_T.player_playerstate
0x0000000000007e6d:  80 3F 02             cmp       byte ptr ds:[bx], 2
0x0000000000007e70:  75 03                jne       dont_player_reborn
0x0000000000007f38:  9A CA 18 88 0A       call      G_PlayerReborn_
dont_player_reborn:
0x0000000000007e75:  6A FF                push      -1
0x0000000000007e77:  6A 00                push      0
0x0000000000007e79:  68 00 80             push      ONFLOORZ_HIGHBITS
0x0000000000007e7e:  6A 00                push      ONFLOORZ_LOWBITS
0x0000000000007e7c:  31 DB                xor       bx, bx
0x0000000000007e80:  31 C0                xor       ax, ax
0x0000000000007e83:  E8 8E 03             call      P_SpawnMobj_
0x0000000000007e86:  BB F6 06             mov       bx, OFFSET _playerMobjRef
0x0000000000007e89:  89 07                mov       word ptr ds:[bx], ax
0x0000000000007e8b:  6B C0 2C             imul      ax, ax, SIZEOF_THINKER_T
0x0000000000007e8e:  BB EC 06             mov       bx, OFFSET _playerMobj
0x0000000000007e91:  05 04 34             add       ax, (_thinkerlist + THINKER_T.t_data)
0x0000000000007e94:  89 07                mov       word ptr ds:[bx], ax
0x0000000000007e96:  BB F6 06             mov       bx, OFFSET _playerMobjRef
0x0000000000007e99:  6B 07 18             imul      ax, word ptr ds:[bx], SIZEOF_MOBJ_POS_T
0x0000000000007e9c:  BB 30 07             mov       bx, OFFSET _playerMobj_pos
0x0000000000007e9f:  C7 47 02 F5 6A       mov       word ptr ds:[bx + 2], MOBJPOSLIST_6800_SEGMENT  
0x0000000000007ea4:  89 07                mov       word ptr ds:[bx], ax
0x0000000000007ea6:  BB EC 06             mov       bx, OFFSET _playerMobj
0x0000000000007ea9:  89 F0                mov       ax, si
0x0000000000007eab:  8B 1F                mov       bx, word ptr ds:[bx]
0x0000000000007ead:  99                   cwd       
0x0000000000007eae:  C6 47 24 00          mov       byte ptr ds:[bx + MOBJ_T.m_reactiontime], 0
0x0000000000007eb2:  BB 2D 00             mov       bx, 45
0x0000000000007eb5:  F7 FB                idiv      bx
0x0000000000007eb7:  B9 00 20             mov       cx, ANG45_HIGHBITS
0x0000000000007eba:  31 DB                xor       bx, bx
0x0000000000007ebc:  BE 30 07             mov       si, OFFSET _playerMobj_pos
0x0000000000007ebf:  9A DF 5C 88 0A       call      FastMul16u32u_
0x0000000000007ec4:  C4 1C                les       bx, ptr ds:[si]
0x0000000000007ec6:  26 89 47 0E          mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
0x0000000000007eca:  26 89 57 10          mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
0x0000000000007ece:  BB EC 06             mov       bx, OFFSET _playerMobj
0x0000000000007ed1:  BE E8 07             mov       si, OFFSET _player PLAYER_T.player_health
0x0000000000007ed4:  8B 1F                mov       bx, word ptr ds:[bx]
0x0000000000007ed6:  8B 04                mov       ax, word ptr ds:[si]
0x0000000000007ed8:  89 47 1C             mov       word ptr ds:[bx + MOBJ_T.m_health], ax
0x0000000000007edb:  BB ED 07             mov       bx, OFFSET _player PLAYER_T.player_playerstate
0x0000000000007ede:  C6 07 00             mov       byte ptr ds:[bx], 0
0x0000000000007ee1:  BB 2B 08             mov       bx, OFFSET _player PLAYER_T.player_refire
0x0000000000007ee4:  C6 07 00             mov       byte ptr ds:[bx], 0
0x0000000000007ee7:  BB 24 08             mov       bx, OFFSET _player PLAYER_T.player_message
0x0000000000007eea:  C7 07 FF FF          mov       word ptr ds:[bx], -1
0x0000000000007eee:  BB 28 08             mov       bx, OFFSET _player PLAYER_T.player_damagecount
0x0000000000007ef1:  C7 07 00 00          mov       word ptr ds:[bx], 0
0x0000000000007ef5:  BB 2A 08             mov       bx, OFFSET _player PLAYER_T.player_bonuscount
0x0000000000007ef8:  C6 07 00             mov       byte ptr ds:[bx], 0
0x0000000000007efb:  BB 2E 08             mov       bx, OFFSET _player PLAYER_T.player_extralightvalue
0x0000000000007efe:  C6 07 00             mov       byte ptr ds:[bx], 0
0x0000000000007f01:  BB 2F 08             mov       bx, OFFSET _player PLAYER_T.player_fixedcolormapvalue
0x0000000000007f04:  C6 07 00             mov       byte ptr ds:[bx], 0
0x0000000000007f07:  BB DC 07             mov       bx, OFFSET _player PLAYER_T.player_viewheightvalue
0x0000000000007f0a:  C7 07 00 00          mov       word ptr ds:[bx], VIEWHEIGHT_LOWBITS
0x0000000000007f0e:  C7 47 02 29 00       mov       word ptr ds:[bx + 2], VIEWHEIGHT_HIGHBITS
0x0000000000007f13:  E8 20 FF             call      P_SetupPsprites_

0x0000000000007f17:  E8 49 22             call      Z_QuickmapStatus_

0x0000000000007f1b:  9A 72 79 88 0A       call      ST_Start_
0x0000000000007f20:  9A E0 79 88 0A       call      HU_Start_

0x0000000000007f26:  3E E8 58 21          call      Z_QuickMapPhysics_
0x0000000000007f2b:  E8 7C 22             call      Z_QuickMapScratch_8000_   ; // gross, due to p_setup.... perhaps externalize.
0x0000000000007f30:  3E E8 38 21          call      Z_QuickMapPhysicsCode_
0x0000000000007f34:  5E                   pop       si
0x0000000000007f35:  59                   pop       cx
0x0000000000007f36:  5B                   pop       bx
0x0000000000007f37:  C3                   ret       

ENDP


PROC P_SpawnMapThing_ FAR
PUBLIC P_SpawnMapThing_

; bp - 2    
; bp - 4    
; bp - 6    mthingoptions
; bp - 8    mthingangle
; bp - 0Ah  mthingx
; bp - 0Ch  
; bp - 0Eh  mthingy

; bp + 010h:  mthing

;void __far P_SpawnMapThing(mapthing_t mthing, int16_t key) {
    
; ugh. big params. NOTE if moved near this will all shift 2.



0x0000000000007f40:  53                   push      bx
0x0000000000007f41:  51                   push      cx
0x0000000000007f42:  52                   push      dx
0x0000000000007f43:  56                   push      si
0x0000000000007f44:  57                   push      di
0x0000000000007f45:  55                   push      bp
0x0000000000007f46:  89 E5                mov       bp, sp
0x0000000000007f48:  83 EC 0E             sub       sp, 0Eh

0x0000000000007f4b:  8B 46 18             mov       ax, word ptr [bp + 010h + MAPTHING_T.mapthing_options]
0x0000000000007f4e:  89 46 FA             mov       word ptr [bp - 6], ax
0x0000000000007f51:  8B 46 10             mov       ax, word ptr [bp + 010h + MAPTHING_T.mapthing_x]
0x0000000000007f54:  89 46 F6             mov       word ptr [bp - 0Ah], ax
0x0000000000007f57:  8B 46 12             mov       ax, word ptr [bp + 010h + MAPTHING_T.mapthing_y]
0x0000000000007f5a:  89 46 F2             mov       word ptr [bp - 0Eh], ax
0x0000000000007f5d:  8B 46 14             mov       ax, word ptr [bp + 010h + MAPTHING_T.mapthing_angle]
0x0000000000007f60:  8B 76 16             mov       si, word ptr [bp + 010h + MAPTHING_T.mapthing_type]
0x0000000000007f63:  89 46 F8             mov       word ptr [bp - 8], ax
0x0000000000007f66:  83 FE 0B             cmp       si, 11
0x0000000000007f69:  75 03                jne       thing_type_not_11
exit_spawnmapthing:
POPA_NO_AX_OR_BP_MACRO
retf   0Ch
thing_type_not_11:
0x0000000000007f6e:  83 FE 02             cmp       si, 2
0x0000000000007f71:  74 F8                je        exit_spawnmapthing
0x0000000000007f73:  83 FE 03             cmp       si, 3
0x0000000000007f76:  74 F3                je        exit_spawnmapthing
0x0000000000007f78:  83 FE 04             cmp       si, 4
0x0000000000007f7b:  74 EE                je        exit_spawnmapthing
0x0000000000007f7d:  83 FE 01             cmp       si, 1
0x0000000000007f80:  75 03                jne       spawn_not_player
; spawn player..
0x00000000000080a0:  8D 46 10             lea       ax, [bp + 010h]
0x00000000000080a3:  8C DA                mov       dx, ds
0x00000000000080a5:  E8 B0 FD             call      P_SpawnPlayer_
0x00000000000080a8:  C9                   LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
0x00000000000080ae:  CA 0C 00             retf      0Ch

spawn_not_player:
0x0000000000007f85:  F6 46 FA 10          test      byte ptr [bp - 6], 010h
0x0000000000007f89:  75 E0                jne       exit_spawnmapthing
0x0000000000007f8b:  A0 14 22             mov       al, byte ptr ds:[_gameskill]
0x0000000000007f8e:  84 C0                test      al, al
0x0000000000007f90:  74 03                je        label_6

0x00000000000080b1:  3C 04                cmp       al, SK_NIGHTMARE
0x00000000000080b3:  75 06                jne       label_7
0x00000000000080b5:  B8 04 00             mov       ax, 4
0x00000000000080b8:  E9 DD FE             jmp       label_8
label_7:
0x00000000000080bb:  30 E4                xor       ah, ah
0x00000000000080bd:  48                   dec       ax
0x00000000000080be:  88 C1                mov       cl, al
0x00000000000080c0:  B8 01 00             mov       ax, 1
0x00000000000080c3:  D3 E0                shl       ax, cl
0x00000000000080c5:  E9 D0 FE             jmp       label_8

label_6:
0x0000000000007f95:  B8 01 00             mov       ax, 1
label_8:
0x0000000000007f98:  85 46 FA             test      word ptr [bp - 6], ax
0x0000000000007f9b:  74 CE                je        exit_spawnmapthing
0x0000000000007f9d:  31 C0                xor       ax, ax
0x0000000000007f9f:  31 D2                cwd
label_3:
0x0000000000007fa1:  BB C6 4C             mov       bx, DOOMEDNUM_SEGMENT   ; todo almost near?
0x0000000000007fa4:  8E C3                mov       es, bx
0x0000000000007fa6:  89 D3                mov       bx, dx
0x0000000000007fa8:  26 3B 37             cmp       si, word ptr es:[bx]
0x0000000000007fab:  74 03                je        label_2

label_1:
0x00000000000080c8:  40                   inc       ax
0x00000000000080c9:  83 C2 02             add       dx, 2
0x00000000000080cc:  3D 89 00             cmp       ax, NUMMOBJTYPES
0x00000000000080cf:  7D 03                jge       label_2
0x00000000000080d1:  E9 CD FE             jmp       label_3


label_2:
0x0000000000007fb0:  80 3E 2C 22 00       cmp       byte ptr ds:[_nomonsters], 0
0x0000000000007fb5:  74 13                je        label_5
0x0000000000007fb7:  3D 12 00             cmp       ax, MT_SKULL
0x0000000000007fba:  74 AF                je        exit_spawnmapthing

0x0000000000007fbc:  6B D0 0B             imul      dx, ax, SIZEOF_MOBJINFO_T ; todo 8 bit mul
0x0000000000007fbf:  89 D3                mov       bx, dx
0x0000000000007fc1:  81 C3 69 C4          add       bx, _mobjinfo + MOBJINFO_T.mobjinfo_flags2
0x0000000000007fc5:  F6 07 40             test      byte ptr ds:[bx], MF_COUNTKILL
0x0000000000007fc8:  75 A1                jne       exit_spawnmapthing
label_5:
0x0000000000007fca:  8B 56 F2             mov       dx, word ptr [bp - 0Eh]
0x0000000000007fcd:  89 56 F4             mov       word ptr [bp - 0Ch], dx
0x0000000000007fd0:  6B D0 0B             imul      dx, ax, SIZEOF_MOBJINFO_T  ; todo 8 bit mul
0x0000000000007fd3:  8B 76 F6             mov       si, word ptr [bp - 0Ah]
0x0000000000007fd6:  31 FF                xor       di, di
0x0000000000007fd8:  31 C9                xor       cx, cx
0x0000000000007fda:  89 D3                mov       bx, dx
0x0000000000007fdc:  81 C3 67 C4          add       bx, _mobjinfo +MOBJINFO_T.mobjinfo_flags1
0x0000000000007fe0:  F6 47 01 01          test      byte ptr ds:[bx + 1], 1
0x0000000000007fe4:  75 03                jne       label_4
0x00000000000080d7:  BA 00 80             mov       dx, ONFLOORZ_HIGHBITS
0x00000000000080da:  31 DB                xor       bx, bx
0x00000000000080dc:  E9 10 FF             jmp       label_4
set_ambush_and_exit:
0x00000000000080df:  26 80 4F 14 20       or        byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_AMBUSH
0x00000000000080e4:  C9                   LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
0x00000000000080ea:  CA 0C 00             retf      0Ch
label_4:
0x0000000000007fe9:  BB FF FF             mov       bx, ONCEILINGZ_LOWBITS
0x0000000000007fec:  BA FF 7F             mov       dx, ONCEILINGZ_HIGHBITS
0x0000000000007fef:  6A FF                push      -1
0x0000000000007ff1:  30 E4                xor       ah, ah
0x0000000000007ff3:  50                   push      ax
0x0000000000007ff4:  52                   push      dx
0x0000000000007ff5:  89 F8                mov       ax, di
0x0000000000007ff7:  53                   push      bx
0x0000000000007ff8:  89 F2                mov       dx, si
0x0000000000007ffa:  89 CB                mov       bx, cx
0x0000000000007ffc:  8B 4E F4             mov       cx, word ptr [bp - 0Ch]
0x0000000000007fff:  BE 34 07             mov       si, OFFSET setStateReturn_pos
0x0000000000008002:  0E                   push      cs
0x0000000000008003:  E8 0E 02             call      P_SpawnMobj_
0x0000000000008006:  BB BA 01             mov       bx, OFFSET _setStateReturn
0x0000000000008009:  8B 3C                mov       di, word ptr ds:[si]
0x000000000000800b:  8B 54 02             mov       dx, word ptr ds:[si + 2]
0x000000000000800e:  89 7E FC             mov       word ptr [bp - 4], di
0x0000000000008011:  89 C7                mov       di, ax
0x0000000000008013:  8D 76 10             lea       si, [bp + 010h]
0x0000000000008016:  C1 E7 02             shl       di, 2
0x0000000000008019:  8B 1F                mov       bx, word ptr ds:[bx]
0x000000000000801b:  01 C7                add       di, ax
0x000000000000801d:  B8 EC 65             mov       ax, NIGHTMARESPAWNS_SEGMENT
0x0000000000008020:  01 FF                add       di, di
0x0000000000008022:  8E C0                mov       es, ax
0x0000000000008024:  A5                   movsw     
0x0000000000008025:  A5                   movsw     
0x0000000000008026:  A5                   movsw     
0x0000000000008027:  A5                   movsw     
0x0000000000008028:  A5                   movsw     
0x0000000000008029:  8A 47 1B             mov       al, byte ptr ds:[bx + MOBJ_T.m_tics]
0x000000000000802c:  89 56 FE             mov       word ptr [bp - 2], dx
0x000000000000802f:  84 C0                test      al, al
0x0000000000008031:  76 24                jbe       dont_set_random_tics
0x0000000000008033:  3C F0                cmp       al, 240
0x0000000000008035:  73 20                jae       dont_set_random_tics
0x0000000000008037:  BE B8 01             mov       si, OFFSET _prndindex
0x000000000000803a:  FE 04                inc       byte ptr ds:[si]
0x000000000000803c:  88 C1                mov       cl, al
0x000000000000803e:  8A 14                mov       dl, byte ptr ds:[si]
0x0000000000008040:  B8 65 3C             mov       ax, RNDTABLE_SEGMENT
0x0000000000008043:  30 F6                xor       dh, dh
0x0000000000008045:  8E C0                mov       es, ax
0x0000000000008047:  89 D6                mov       si, dx
0x0000000000008049:  26 8A 04             mov       al, byte ptr es:[si]
0x000000000000804c:  30 E4                xor       ah, ah
0x000000000000804e:  30 ED                xor       ch, ch
0x0000000000008050:  99                   cwd       
0x0000000000008051:  F7 F9                idiv      cx
0x0000000000008053:  42                   inc       dx

0x0000000000008054:  88 57 1B             mov       byte ptr ds:[bx + MOBJ_T.m_tics], dl

dont_set_random_tics:
0x0000000000008057:  C4 5E FC             les       bx, ptr [bp - 4]
0x000000000000805a:  26 F6 47 16 40       test      byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_COUNTKILL
0x000000000000805f:  74 04                je        not_killable
0x0000000000008061:  FF 06 5E 1F          inc       word ptr ds:[_totalkills]
not_killable:
0x0000000000008065:  C4 5E FC             les       bx, ptr [bp - 4]
0x0000000000008068:  26 F6 47 16 80       test      byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_COUNTITEM
0x000000000000806d:  74 04                je        not_an_item
0x000000000000806f:  FF 06 60 1F          inc       word ptr ds:[_totalitems]
not_an_item:
0x0000000000008073:  8B 46 F8             mov       ax, word ptr [bp - 8]
0x0000000000008076:  BB 2D 00             mov       bx, 45
0x0000000000008079:  99                   cwd       
0x000000000000807a:  F7 FB                idiv      bx
0x000000000000807c:  B9 00 20             mov       cx, ANG45_HIGHBITS
0x000000000000807f:  31 DB                xor       bx, bx
0x0000000000008081:  9A DF 5C 88 0A       call      FastMul16u32u_
0x0000000000008086:  C4 5E FC             les       bx, ptr [bp - 4]
0x0000000000008089:  26 89 47 0E          mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
0x000000000000808d:  26 89 57 10          mov       word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
0x0000000000008091:  F6 46 FA 08          test      byte ptr [bp - 6], MTF_AMBUSH
0x0000000000008095:  75 48                jne       set_ambush_and_exit

0x0000000000008097:  C9                   LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
0x000000000000809d:  CA 0C 00             retf      0Ch


ENDP


PROC P_MobjThinker_ NEAR
PUBLIC P_MobjThinker_

0x00000000000080ee:  56                   push      si
0x00000000000080ef:  57                   push      di
0x00000000000080f0:  55                   push      bp
0x00000000000080f1:  89 E5                mov       bp, sp
0x00000000000080f6:  89 C6                mov       si, ax
0x00000000000080f8:  89 DF                mov       di, bx
push cx

0x0000000000008116:  8B 44 10             mov       ax, word ptr ds:[si + MOBJ_T.m_momx + 0]
0x000000000000811e:  0B 44 0E             or        ax, word ptr ds:[si + MOBJ_T.m_momx + 2]
0x0000000000008121:  75 48                jne       do_xy_movement
0x0000000000008123:  8B 44 14             mov       ax, word ptr ds:[si + MOBJ_T.m_momy + 2]
0x0000000000008126:  0B 44 12             or        ax, word ptr ds:[si + MOBJ_T.m_momy + 0]
0x0000000000008129:  75 40                jne       do_xy_movement
0x000000000000812b:  8E C1                mov       es, cx
0x000000000000812d:  26 F6 45 17 01       test      byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], (MF_SKULLFLY SHR 8)
0x0000000000008132:  75 37                jne       do_xy_movement
label_13:
0x0000000000008134:  8B 5C 06             mov       bx, word ptr ds:[si + 6]
0x0000000000008137:  8B 44 06             mov       ax, word ptr ds:[si + 6]
0x000000000000813a:  30 FF                xor       bh, bh
0x000000000000813c:  8E 46 FE             mov       es, word ptr [bp - 2]
0x000000000000813f:  80 E3 07             and       bl, 7
0x0000000000008142:  C1 F8 03             sar       ax, 3
0x0000000000008145:  C1 E3 0D             shl       bx, 0Dh ; todo no
0x0000000000008148:  26 3B 45 0A          cmp       ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
0x000000000000814c:  75 3A                jne       label_9
0x000000000000814e:  26 3B 5D 08          cmp       bx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
0x0000000000008152:  75 34                jne       label_9
0x0000000000008154:  8B 44 18             mov       ax, word ptr ds:[si + MOBJ_T.m_momz + 2]
0x0000000000008157:  0B 44 16             or        ax, word ptr ds:[si + MOBJ_T.m_momz + 0]
0x000000000000815a:  75 2C                jne       label_9
label_15:
0x000000000000815c:  80 7C 1B FF          cmp       byte ptr ds:[si + MOBJ_T.m_tics], 255
0x0000000000008160:  74 67                je        label_11
0x0000000000008162:  FE 4C 1B             dec       byte ptr ds:[si + MOBJ_T.m_tics]
0x0000000000008165:  74 3E                je        label_14
exit_p_mobjthinker:
0x0000000000008167:  C9                   LEAVE_MACRO     
0x0000000000008168:  5F                   pop       di
0x0000000000008169:  5E                   pop       si
0x000000000000816a:  C3                   ret       

do_xy_movement:
0x000000000000816b:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000816e:  89 FB                mov       bx, di
0x0000000000008170:  89 F0                mov       ax, si

db 09Ah
dw P_XYMOVEMENTOFFSET, PHYSICS_HIGHCODE_SEGMENT

0x0000000000008175:  6B DA 2C             imul      bx, dx, SIZEOF_THINKER_T
0x0000000000008178:  8B 87 00 34          mov       ax, word ptr ds:[bx + _thinkerlist]

0x000000000000817e:  80 E4 F8             and       ax, TF_FUNCBITS
0x0000000000008181:  3D 00 50             cmp       ax, TF_DELETEME_HIGHBITS
0x0000000000008184:  74 E1                je        exit_p_mobjthinker
0x0000000000008186:  EB AC                jmp       label_13
label_9:
0x0000000000008188:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000818b:  89 FB                mov       bx, di
0x000000000000818d:  89 F0                mov       ax, si

db 09Ah
dw P_ZMOVEMENTOFFSET, PHYSICS_HIGHCODE_SEGMENT



0x0000000000008192:  6B DA 2C             imul      bx, dx, SIZEOF_THINKER_T
0x0000000000008195:  8B 87 00 34          mov       ax, word ptr ds:[bx + _thinkerlist]
0x000000000000819b:  80 E4 F8             and       ax, TF_FUNCBITS
0x000000000000819e:  3D 00 50             cmp       ax, TF_DELETEME_HIGHBITS
0x00000000000081a1:  74 C4                je        exit_p_mobjthinker
0x00000000000081a3:  EB B7                jmp       label_15
label_14:
0x00000000000081a5:  8E 46 FE             mov       es, word ptr [bp - 2]
0x00000000000081a8:  26 8B 45 12          mov       ax, word ptr es:[di + MOBJ_POS_T.mp_statenum]
0x00000000000081ac:  89 C7                mov       di, ax
0x00000000000081ae:  C1 E7 02             shl       di, 2
0x00000000000081b1:  29 C7                sub       di, ax
0x00000000000081b3:  B8 74 7D             mov       ax, STATES_SEGMENT
0x00000000000081b6:  01 FF                add       di, di
0x00000000000081b8:  8E C0                mov       es, ax
0x00000000000081ba:  89 F0                mov       ax, si
0x00000000000081bc:  26 8B 55 04          mov       dx, word ptr es:[di + 4]
0x00000000000081c0:  83 C7 04             add       di, 4
0x00000000000081c3:  0E                   push      cs
0x00000000000081c4:  E8 97 02             call      P_SetMobjState_
0x00000000000081c7:  EB 9E                jmp       exit_p_mobjthinker
label_11:
0x00000000000081c9:  8E 46 FE             mov       es, word ptr [bp - 2]
0x00000000000081cc:  26 F6 45 16 40       test      byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_COUNTKILL
0x00000000000081d1:  74 94                je        exit_p_mobjthinker
0x00000000000081d3:  80 3E 15 22 00       cmp       byte ptr ds:[_respawnmonsters], 0
0x00000000000081d8:  74 8D                je        exit_p_mobjthinker
0x00000000000081da:  FF 44 20             inc       word ptr ds:[si + MOBJ_T.m_movecount]
0x00000000000081dd:  81 7C 20 A4 01       cmp       word ptr ds:[si + MOBJ_T.m_movecount], (12 * 35)
0x00000000000081e2:  7C 83                jl        exit_p_mobjthinker
0x00000000000081e4:  BB 1C 07             mov       bx, _leveltime
0x00000000000081e7:  F6 07 1F             test      byte ptr ds:[bx], 31
0x00000000000081ea:  74 03                je        label_12
jump_to_exit_mobjthinker:
0x00000000000081ec:  E9 78 FF             jmp       exit_p_mobjthinker
label_12:
0x00000000000081ef:  BB B8 01             mov       bx, OFFSET _prndindex
0x00000000000081f2:  FE 07                inc       byte ptr ds:[bx]
0x00000000000081f4:  8A 17                mov       dl, byte ptr ds:[bx]
0x00000000000081f6:  B8 65 3C             mov       ax, RNDTABLE_SEGMENT
0x00000000000081f9:  30 F6                xor       dh, dh
0x00000000000081fb:  8E C0                mov       es, ax
0x00000000000081fd:  89 D3                mov       bx, dx
0x00000000000081ff:  26 8A 07             mov       al, byte ptr es:[bx]
0x0000000000008202:  3C 04                cmp       al, 4
0x0000000000008204:  77 E6                ja        jump_to_exit_mobjthinker
0x0000000000008206:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008209:  89 FB                mov       bx, di
0x000000000000820b:  89 F0                mov       ax, si


db 09Ah
dw P_NIGHTMARERESPAWNOFFSET, PHYSICS_HIGHCODE_SEGMENT


0x0000000000008210:  C9                   LEAVE_MACRO     
0x0000000000008211:  5F                   pop       di
0x0000000000008212:  5E                   pop       si
0x0000000000008213:  C3                   ret       

ENDP


PROC P_SpawnMobj_ FAR
PUBLIC P_SpawnMobj_


;THINKERREF __far P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type, int16_t knownsecnum ) {

; ugh also modify this when made near...
; bp + 010h knownsecnum
; bp + 0E   type
; bp + 0C   z hi
; bp + 0A   z lo


; bp - 2    MOBJPOSLIST_6800_SEGMENT
; bp - 4    
; bp - 5    
; bp - 8    
; bp - 0Ah  unused
; bp - 0Ch  unused

; bp - 0Eh  x lo
; bp - 010h x hi
; bp - 012h y lo
; bp - 014h y hi



0x0000000000008214:  56                   push      si
0x0000000000008215:  57                   push      di
0x0000000000008216:  55                   push      bp
0x0000000000008217:  89 E5                mov       bp, sp
0x0000000000008219:  83 EC 0C             sub       sp, 0Ch
0x000000000000821c:  50                   push      ax
0x000000000000821d:  52                   push      dx
0x000000000000821e:  53                   push      bx
0x000000000000821f:  51                   push      cx
0x0000000000008220:  B8 00 08             mov       ax, TF_MOBJTHINKER_HIGHBITS
0x0000000000008223:  B9 2C 00             mov       cx, SIZEOF_THINKER_T
0x0000000000008226:  0E                   push      cs
0x0000000000008227:  E8 02 08             call      P_CreateThinker_
0x000000000000822a:  90                   nop       
0x000000000000822b:  31 D2                xor       dx, dx
0x000000000000822d:  89 C3                mov       bx, ax
0x000000000000822f:  89 C6                mov       si, ax
0x0000000000008231:  2D 04 34             sub       ax, (_thinkerlist + THINKER_T.t_data)
0x0000000000008234:  F7 F1                div       cx
0x0000000000008236:  89 46 FA             mov       word ptr [bp - 6], ax
0x0000000000008239:  6B F8 18             imul      di, ax, SIZEOF_MOBJ_POS_T
0x000000000000823c:  B9 28 00             mov       cx, SIZEOF_MOBJ_T
0x000000000000823f:  89 7E F8             mov       word ptr [bp - 8], di
0x0000000000008242:  89 7E FC             mov       word ptr [bp - 4], di
0x0000000000008245:  30 C0                xor       al, al
0x0000000000008247:  89 DF                mov       di, bx
0x0000000000008249:  BA F5 6A             mov       dx, MOBJPOSLIST_6800_SEGMENT
0x000000000000824c:  57                   push      di
0x000000000000824d:  1E                   push      ds
0x000000000000824e:  07                   pop       es
0x000000000000824f:  8A E0                mov       ah, al
0x0000000000008251:  D1 E9                shr       cx, 1
0x0000000000008253:  F3 AB                rep stosw 
0x0000000000008255:  13 C9                adc       cx, cx
0x0000000000008257:  F3 AA                rep stosb 
0x0000000000008259:  5F                   pop       di
0x000000000000825a:  B9 18 00             mov       cx, SIZEOF_MOBJ_POS_T
0x000000000000825d:  8B 7E F8             mov       di, word ptr [bp - 8]
0x0000000000008260:  8E C2                mov       es, dx
0x0000000000008262:  57                   push      di
0x0000000000008263:  8A E0                mov       ah, al
0x0000000000008265:  D1 E9                shr       cx, 1
0x0000000000008267:  F3 AB                rep stosw 
0x0000000000008269:  13 C9                adc       cx, cx
0x000000000000826b:  F3 AA                rep stosb 
0x000000000000826d:  5F                   pop       di
0x000000000000826e:  8A 46 0E             mov       cl, byte ptr [bp + 0Eh]
0x000000000000826e:  8A 46 0E             mov       al, SIZEOF_MOBJINFO_T
0x0000000000008271:  30 E4                mul       cl
0x0000000000008273:  6B C8 0B             xchg      ax, cx
0x0000000000008276:  C7 46 FE F5 6A       mov       word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT
0x000000000000827b:  88 47 1A             mov       byte ptr ds:[bx + MOBJ_T.m_mobjtype], al
0x000000000000827e:  8E 46 FE             mov       es, word ptr [bp - 2]
; todo do this all ax or something. 
0x0000000000008281:  8B 56 F2             mov       dx, word ptr [bp - 0Eh]
0x0000000000008284:  26 89 15             mov       word ptr es:[di + MOBJ_POS_T.mp_x + 0], dx
0x0000000000008287:  8B 56 F0             mov       dx, word ptr [bp - 010h]
0x000000000000828a:  26 89 55 02          mov       word ptr es:[di + MOBJ_POS_T.mp_x + 2], dx
0x000000000000828e:  8B 56 EE             mov       dx, word ptr [bp - 012h]
0x0000000000008291:  26 89 55 04          mov       word ptr es:[di + MOBJ_POS_T.mp_y + 0], dx
0x0000000000008295:  8B 56 EC             mov       dx, word ptr [bp - 014h]
0x000000000000829c:  26 89 55 06          mov       word ptr es:[di + MOBJ_POS_T.mp_y + 2], dx
0x0000000000008298:  81 C1 60 C4          add       cx, _mobjinfo + MOBJINFO_T.mobjinfo_spawnstate
0x00000000000082a0:  89 CF                mov       di, cx
0x00000000000082a2:  8A 55 05             mov       dl, byte ptr ds:[di + MOBJINFO_T.mobjinfo_radius]
0x00000000000082a5:  88 57 1E             mov       byte ptr ds:[bx + MOBJ_T.m_radius], dl
0x00000000000082a8:  8A 55 06             mov       dl, byte ptr ds:[di + MOBJINFO_T.mobjinfo_height]
0x00000000000082ab:  C7 47 0A 00 00       mov       word ptr ds:[bx + MOBJ_T.m_height + 0], 0
0x00000000000082b0:  30 F6                xor       dh, dh
0x00000000000082b2:  89 57 0C             mov       word ptr ds:[bx + MOBJ_T.m_height + 2], dx
0x00000000000082b5:  8B 55 07             mov       dx, word ptr ds:[di + MOBJINFO_T.mobjinfo_flags1]
0x00000000000082b8:  8B 7E F8             mov       di, word ptr [bp - 8]
0x00000000000082bb:  26 89 55 14          mov       word ptr es:[di + MOBJ_POS_T.mp_flags1], dx
0x00000000000082bf:  89 CF                mov       di, cx
0x00000000000082c6:  8B 55 09             mov       dx, word ptr ds:[di + MOBJINFO_T.mobjinfo_flags2]
0x00000000000082c9:  8B 7E F8             mov       di, word ptr [bp - 8]
0x00000000000082d1:  26 89 55 16          mov       word ptr es:[di + MOBJ_POS_T.mp_flags2], dx


db 09Ah
dw GETSPAWNHEALTHADDR, INFOFUNCLOADSEGMENT


0x00000000000082d8:  89 47 1C             mov       word ptr ds:[bx + MOBJ_T.m_health], ax
0x00000000000082db:  80 3E 14 22 04       cmp       byte ptr ds:[_gameskill], SK_NIGHTMARE
0x00000000000082e0:  74 04                je        skill_not_nightmare
0x00000000000082e2:  C6 47 24 08          mov       byte ptr ds:[bx + MOBJ_T.m_reactiontime], 8
skill_not_nightmare:
0x00000000000082e6:  BB B8 01             mov       bx, OFFSET _prndindex
0x00000000000082e9:  FE 07                inc       byte ptr ds:[bx]
0x00000000000082eb:  89 CB                mov       bx, cx
0x00000000000082ed:  8B 07                mov       ax, word ptr ds:[bx + MOBJINFO_T.mobjinfo_spawnstatex]
0x00000000000082ef:  C4 5E FC             les       bx, ptr [bp - 4]
0x00000000000082f2:  26 89 47 12          mov       word ptr es:[bx + MOBJ_POS_T.mp_statenum], ax
0x00000000000082f6:  89 CB                mov       bx, cx
0x00000000000082f8:  8B 07                mov       ax, word ptr ds:[bx + MOBJINFO_T.mobjinfo_spawnstate]
0x00000000000082fa:  89 C3                mov       bx, ax
0x00000000000082fc:  C1 E3 02             SHIFT_MACRO shl       bx 2
0x00000000000082ff:  29 C3                sub       bx, ax
0x0000000000008301:  B8 74 7D             mov       ax, STATES_SEGMENT
0x0000000000008304:  01 DB                add       bx, bx  ; 6 bytes per
0x0000000000008306:  8E C0                mov       es, ax
0x000000000000830b:  8B 56 FC             mov       dx, word ptr [bp - 4]
0x000000000000830e:  26 8A 07             mov       al, byte ptr es:[bx + STATE_T.state_tics]
0x0000000000008311:  8B 5E 10             mov       bx, word ptr [bp + 010h]
0x0000000000008314:  88 44 1B             mov       byte ptr ds:[si + MOBJ_T.m_tics], al
0x0000000000008317:  89 F0                mov       ax, si
0x0000000000008319:  FF 1E D8 0C          call      dword ptr ds:[_P_SetThingPosition]
0x000000000000831d:  8B 5C 04             mov       bx, word ptr ds:[si + MOBJ_T.m_secnum]
0x0000000000008320:  B8 90 21             mov       ax, SECTORS_SEGMENT
0x0000000000008323:  C1 E3 04             SHIFT_MACRO shl       bx 4
0x0000000000008326:  8E C0                mov       es, ax
0x0000000000008328:  26 8B 07             mov       ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
0x000000000000832b:  89 44 06             mov       word ptr ds:[si + MOBJ_T.m_floorz], ax
0x000000000000832e:  26 8B 47 02          mov       ax, word ptr es:[bx + SECTOR_T.sec_ceilingheight]
0x0000000000008335:  89 44 08             mov       word ptr ds:[si + MOBJ_T.m_ceilingz], ax
0x0000000000008338:  81 7E 0C 00 80       cmp       word ptr [bp + 0Ch], ONFLOORZ_HIGHBITS
0x000000000000833d:  75 06                jne       not_floor_spawn
0x000000000000833f:  83 7E 0A 00          cmp       word ptr [bp + 0Ah], 0
0x0000000000008343:  74 59                je        is_floor_spawn:
not_floor_spawn:
0x0000000000008345:  81 7E 0C FF 7F       cmp       word ptr [bp + 0Ch], ONCEILINGZ_HIGHBITS
0x000000000000834a:  75 71                jne       not_ceiling_spawn
0x000000000000834c:  83 7E 0A FF          cmp       word ptr [bp + 0Ah], ONCEILINGZ_LOWBITS
0x0000000000008350:  75 6B                jne       not_ceiling_spawn
0x0000000000008352:  8A 54 1A             mov       dl, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000008355:  30 F6                xor       dh, dh
0x0000000000008357:  6B D2 0B             imul      dx, dx, SIZEOF_MOBJINFO_T
0x000000000000835a:  8B 4C 08             mov       cx, word ptr ds:[si + 8]
0x000000000000835d:  83 E1 07             and       cx, 7
0x0000000000008360:  C1 F8 03             sar       ax, 3
0x0000000000008363:  C1 E1 0D             shl       cx, 0Dh   ; todo no
0x0000000000008366:  89 D3                mov       bx, dx
0x0000000000008368:  8A 97 66 C4          mov       dl, byte ptr ds:[bx + _mobjinfo + MOBJINFO_T.mobjinfo_height]

0x0000000000008370:  8E 46 FE             mov       es, word ptr [bp - 2]
0x0000000000008373:  30 F6                xor       dh, dh
0x0000000000008375:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x0000000000008378:  29 D0                sub       ax, dx
0x000000000000837a:  26 89 4F 08          mov       word ptr es:[bx + MOBJ_POS_T.mp_z + 0], cx
set_z_highbits:
0x000000000000837e:  26 89 47 0A          mov       word ptr es:[bx + MOBJ_POS_T.mp_z + 2], ax
done_setting_z:
0x0000000000008382:  BB BA 01             mov       bx, OFFSET _setStateReturn
0x0000000000008385:  89 37                mov       word ptr ds:[bx], si
0x0000000000008387:  BB 34 07             mov       bx, OFFSET setStateReturn_pos
0x000000000000838a:  8B 76 FC             mov       si, word ptr [bp - 4]
0x000000000000838d:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000008390:  89 37                mov       word ptr ds:[bx], si
0x0000000000008392:  89 47 02             mov       word ptr ds:[bx + 2], ax
0x0000000000008395:  8B 46 FA             mov       ax, word ptr [bp - 6]
0x0000000000008398:  C9                   LEAVE_MACRO     
0x0000000000008399:  5F                   pop       di
0x000000000000839a:  5E                   pop       si
0x000000000000839b:  CA 08 00             retf      8
is_floor_spawn:
0x000000000000839e:  8B 5E FC             mov       bx, word ptr [bp - 4]
0x00000000000083a1:  8B 44 06             mov       ax, word ptr ds:[si + 6]
0x00000000000083a4:  8E 46 FE             mov       es, word ptr [bp - 2]
0x00000000000083a7:  C1 F8 03             sar       ax, 3
0x00000000000083aa:  26 89 47 0A          mov       word ptr es:[bx + MOBJ_POS_T.mp_z + 2], ax
0x00000000000083ae:  8B 44 06             mov       ax, word ptr ds:[si + 6]
0x00000000000083b1:  25 07 00             and       ax, 7
0x00000000000083b4:  C1 E0 0D             shl       ax, 0Dh  ; todo no
0x00000000000083b7:  26 89 47 08          mov       word ptr es:[bx + MOBJ_POS_T.mp_z + 0], ax
0x00000000000083bb:  EB C5                jmp       done_setting_z ; todo cleanup. do two writes at once
not_ceiling_spawn:
0x00000000000083bd:  C4 5E FC             les       bx, ptr [bp - 4]
0x00000000000083c0:  8B 46 0A             mov       ax, word ptr [bp + 0Ah]
0x00000000000083c3:  26 89 47 08          mov       word ptr es:[bx + MOBJ_POS_T.mp_z + 0], ax
0x00000000000083c7:  8B 46 0C             mov       ax, word ptr [bp + 0Ch]
0x00000000000083ca:  EB B2                jmp       set_z_highbits

ENDP




PROC P_RemoveMobj_ FAR
PUBLIC P_RemoveMobj_


0x00000000000083cc:  53                   push      bx
0x00000000000083cd:  51                   push      cx
0x00000000000083ce:  52                   push      dx
0x00000000000083cf:  89 C3                mov       bx, ax
0x00000000000083d1:  B9 2C 00             mov       cx, SIZEOF_THINKER_T
0x00000000000083d4:  2D 04 34             sub       ax, (_thinkerlist + THINKER_T.t_data)
0x00000000000083d7:  31 D2                xor       dx, dx
0x00000000000083d9:  F7 F1                div       cx
0x00000000000083db:  89 C1                mov       cx, ax
0x00000000000083dd:  6B D0 18             imul      dx, ax, SIZEOF_MOBJ_POS_T
0x00000000000083e0:  89 D8                mov       ax, bx
0x00000000000083e2:  FF 1E D4 0C          call      dword ptr ds:[_P_UnsetThingPosition]
0x00000000000083e6:  89 D8                mov       ax, bx
0x00000000000083e8:  0E                   push      cs
0x00000000000083e9:  E8 0A 7F             call      S_StopSoundMobjRef_
0x00000000000083ec:  90                   nop       
0x00000000000083ed:  89 C8                mov       ax, cx
0x00000000000083ef:  E8 D0 06             call      P_RemoveThinker_
0x00000000000083f2:  5A                   pop       dx
0x00000000000083f3:  59                   pop       cx
0x00000000000083f4:  5B                   pop       bx
0x00000000000083f5:  CB                   retf      


setmobjstate_jump_table:
dw setmobjstate_switch_jump_0
dw setmobjstate_switch_jump_1
dw setmobjstate_switch_jump_2
dw setmobjstate_switch_jump_3
dw setmobjstate_switch_jump_4
dw setmobjstate_switch_jump_5
dw setmobjstate_switch_jump_6
dw setmobjstate_switch_jump_7
dw setmobjstate_switch_jump_8
dw setmobjstate_switch_jump_9
dw setmobjstate_switch_jump_10
dw setmobjstate_switch_jump_11
dw setmobjstate_switch_jump_12
dw setmobjstate_switch_jump_13
dw setmobjstate_switch_jump_14
dw setmobjstate_switch_jump_15
dw setmobjstate_switch_jump_16
dw setmobjstate_switch_jump_17
dw setmobjstate_switch_jump_18
dw setmobjstate_switch_jump_19
dw setmobjstate_switch_jump_20
dw setmobjstate_switch_jump_21
dw setmobjstate_switch_jump_22
dw setmobjstate_switch_jump_23
dw setmobjstate_switch_jump_24
dw setmobjstate_switch_jump_25
dw setmobjstate_switch_jump_26
dw setmobjstate_switch_jump_27
dw setmobjstate_switch_jump_28
dw setmobjstate_switch_jump_29
dw setmobjstate_switch_jump_30
dw setmobjstate_switch_jump_31
dw setmobjstate_switch_jump_32
dw setmobjstate_switch_jump_33
dw setmobjstate_switch_jump_34
dw setmobjstate_switch_jump_35
dw setmobjstate_switch_jump_36
dw setmobjstate_switch_jump_37
dw setmobjstate_switch_jump_38
dw setmobjstate_switch_jump_39
dw setmobjstate_switch_jump_40
dw setmobjstate_switch_jump_41
dw setmobjstate_switch_jump_42
dw setmobjstate_switch_jump_43
dw setmobjstate_switch_jump_44
dw setmobjstate_switch_jump_45
dw setmobjstate_switch_jump_46
dw setmobjstate_switch_jump_47
dw setmobjstate_switch_jump_48
dw setmobjstate_switch_jump_49
dw setmobjstate_switch_jump_50
dw setmobjstate_switch_jump_51

ENDP




PROC P_SetMobjState_ FAR
PUBLIC P_SetMobjState_


0x000000000000845e:  53                   push      bx
0x000000000000845f:  51                   push      cx
0x0000000000008460:  56                   push      si
0x0000000000008461:  57                   push      di
0x0000000000008462:  55                   push      bp
0x0000000000008463:  89 E5                mov       bp, sp
0x0000000000008465:  83 EC 08             sub       sp, 8
0x0000000000008468:  89 C6                mov       si, ax
0x000000000000846a:  89 D1                mov       cx, dx
0x000000000000846c:  BB BA 01             mov       bx, OFFSET _setStateReturn
0x000000000000846f:  31 D2                xor       dx, dx
0x0000000000008471:  89 07                mov       word ptr ds:[bx], ax
0x0000000000008473:  BB 2C 00             mov       bx, SIZEOF_THINKER_T
0x0000000000008476:  2D 04 34             sub       ax, (_thinkerlist + THINKER_T.t_data)
0x0000000000008479:  F7 F3                div       bx
0x000000000000847b:  6B C0 18             imul      ax, ax, SIZEOF_MOBJ_POS_T
0x000000000000847e:  BB 34 07             mov       bx, OFFSET setStateReturn_pos
0x0000000000008481:  C7 47 02 F5 6A       mov       word ptr ds:[bx + 2], MOBJPOSLIST_6800_SEGMENT
0x0000000000008486:  89 07                mov       word ptr ds:[bx], ax
0x0000000000008488:  8B 7F 02             mov       di, word ptr ds:[bx + 2]
0x000000000000848b:  8B 17                mov       dx, word ptr ds:[bx]
0x000000000000848d:  89 7E FE             mov       word ptr [bp - 2], di
0x0000000000008490:  89 D3                mov       bx, dx
0x0000000000008492:  85 C9                test      cx, cx
0x0000000000008494:  74 70                je        0x8506
0x0000000000008496:  BA F5 6A             mov       dx, MOBJPOSLIST_6800_SEGMENT
0x0000000000008499:  89 46 F8             mov       word ptr [bp - 8], ax
0x000000000000849c:  6B C1 06             imul      ax, cx, 6
0x000000000000849f:  C7 46 FC 74 7D       mov       word ptr [bp - 4], STATES_SEGMENT
0x00000000000084a4:  8E 46 FE             mov       es, word ptr [bp - 2]
0x00000000000084a7:  89 C7                mov       di, ax
0x00000000000084a9:  26 89 4F 12          mov       word ptr es:[bx + 0x12], cx
0x00000000000084ad:  8E 46 FC             mov       es, word ptr [bp - 4]
0x00000000000084b0:  89 46 FA             mov       word ptr [bp - 6], ax
0x00000000000084b3:  26 8A 45 02          mov       al, byte ptr es:[di + STATE_T.state_tics]
0x00000000000084b7:  88 44 1B             mov       byte ptr ds:[si + MOBJ_T.m_tics], al
0x00000000000084ba:  26 8A 4D 03          mov       cl, byte ptr es:[di + state_action]
0x00000000000084be:  80 E9 17             sub       cl, 0x17
0x00000000000084c1:  80 F9 33             cmp       cl, 0x33
0x00000000000084c4:  77 14                ja        0x84da
0x00000000000084c6:  30 ED                xor       ch, ch
0x00000000000084c8:  89 CF                mov       di, cx
0x00000000000084ca:  01 CF                add       di, cx
0x00000000000084cc:  2E FF A5 F6 83       jmp       word ptr cs:[di + setmobjstate_jump_table]
setmobjstate_switch_jump_0:
0x00000000000084d1:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000084d4:  89 F0                mov       ax, si
0x00000000000084d6:  FF 1E 08 0D          call      dword ptr ds:[_A_BFGSprayFar_]
0x00000000000084da:  BB BA 01             mov       bx, OFFSET _setStateReturn
0x00000000000084dd:  89 37                mov       word ptr ds:[bx], si
0x00000000000084df:  BB 34 07             mov       bx, OFFSET setStateReturn_pos
0x00000000000084e2:  8B 46 F8             mov       ax, word ptr [bp - 8]
0x00000000000084e5:  89 07                mov       word ptr ds:[bx], ax
0x00000000000084e7:  89 57 02             mov       word ptr ds:[bx + 2], dx
0x00000000000084ea:  BF 34 07             mov       di, OFFSET setStateReturn_pos
0x00000000000084ed:  8B 1F                mov       bx, word ptr ds:[bx]
0x00000000000084ef:  8B 45 02             mov       ax, word ptr ds:[di + 2]
0x00000000000084f2:  C4 7E FA             les       di, ptr [bp - 6]
0x00000000000084f5:  89 46 FE             mov       word ptr [bp - 2], ax
0x00000000000084f8:  26 8B 4D 04          mov       cx, word ptr es:[di + 4]
0x00000000000084fc:  80 7C 1B 00          cmp       byte ptr ds:[si + MOBJ_T.m_tics], 0
0x0000000000008500:  75 77                jne       0x8579
0x0000000000008502:  85 C9                test      cx, cx
0x0000000000008504:  75 96                jne       0x849c
0x0000000000008506:  8E 46 FE             mov       es, word ptr [bp - 2]
0x0000000000008509:  89 F0                mov       ax, si
0x000000000000850b:  26 C7 47 12 00 00    mov       word ptr es:[bx + 0x12], 0
0x0000000000008511:  BB BA 01             mov       bx, OFFSET _setStateReturn
0x0000000000008514:  31 D2                xor       dx, dx
0x0000000000008516:  0E                   push      cs
0x0000000000008517:  E8 B2 FE             call      0x83cc
0x000000000000851a:  89 37                mov       word ptr ds:[bx], si
0x000000000000851c:  BB 2C 00             mov       bx, SIZEOF_THINKER_T
0x000000000000851f:  8D 84 FC CB          lea       ax, [si - (_thinkerlist + THINKER_T.t_data)]
0x0000000000008523:  F7 F3                div       bx
0x0000000000008525:  6B C0 18             imul      ax, ax, SIZEOF_MOBJ_POS_T
0x0000000000008528:  BB 34 07             mov       bx, OFFSET setStateReturn_pos
0x000000000000852b:  C7 47 02 F5 6A       mov       word ptr ds:[bx + 2], MOBJPOSLIST_6800_SEGMENT
0x0000000000008530:  89 07                mov       word ptr ds:[bx], ax
0x0000000000008532:  30 C0                xor       al, al
0x0000000000008534:  C9                   LEAVE_MACRO     
0x0000000000008535:  5F                   pop       di
0x0000000000008536:  5E                   pop       si
0x0000000000008537:  59                   pop       cx
0x0000000000008538:  5B                   pop       bx
0x0000000000008539:  CB                   retf      
setmobjstate_switch_jump_1:
0x000000000000853a:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000853d:  89 F0                mov       ax, si
0x000000000000853f:  E8 27 BA             call      0x3f69
0x0000000000008542:  EB 96                jmp       0x84da
setmobjstate_switch_jump_2:
0x0000000000008544:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008547:  89 F0                mov       ax, si
0x0000000000008549:  E8 FC B9             call      0x3f48
0x000000000000854c:  EB 8C                jmp       0x84da
setmobjstate_switch_jump_3:
0x000000000000854e:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008551:  89 F0                mov       ax, si
0x0000000000008553:  E8 A4 BE             call      0x43fa
0x0000000000008556:  EB 82                jmp       0x84da
setmobjstate_switch_jump_4:
0x0000000000008558:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000855b:  89 F0                mov       ax, si
0x000000000000855d:  E8 01 BA             call      0x3f61
0x0000000000008560:  E9 77 FF             jmp       0x84da
setmobjstate_switch_jump_5:
0x0000000000008563:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008566:  89 F0                mov       ax, si
0x0000000000008568:  E8 D3 B9             call      0x3f3e
0x000000000000856b:  E9 6C FF             jmp       0x84da
setmobjstate_switch_jump_6:
0x000000000000856e:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008571:  89 F0                mov       ax, si
0x0000000000008573:  E8 4B A9             call      0x2ec1
0x0000000000008576:  E9 61 FF             jmp       0x84da
0x0000000000008579:  B0 01                mov       al, 1
0x000000000000857b:  C9                   LEAVE_MACRO     
0x000000000000857c:  5F                   pop       di
0x000000000000857d:  5E                   pop       si
0x000000000000857e:  59                   pop       cx
0x000000000000857f:  5B                   pop       bx
0x0000000000008580:  CB                   retf      
setmobjstate_switch_jump_7:
0x0000000000008581:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008584:  89 F0                mov       ax, si
0x0000000000008586:  E8 E2 A9             call      0x2f6b
0x0000000000008589:  E9 4E FF             jmp       0x84da
setmobjstate_switch_jump_8:
0x000000000000858c:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000858f:  89 F0                mov       ax, si
0x0000000000008591:  E8 57 AB             call      0x30eb
0x0000000000008594:  E9 43 FF             jmp       0x84da
setmobjstate_switch_jump_9:
0x0000000000008597:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000859a:  89 F0                mov       ax, si
0x000000000000859c:  E8 BF AB             call      0x315e
0x000000000000859f:  E9 38 FF             jmp       0x84da
setmobjstate_switch_jump_10:
0x00000000000085a2:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085a5:  89 F0                mov       ax, si
0x00000000000085a7:  E8 3D B9             call      0x3ee7
0x00000000000085aa:  E9 2D FF             jmp       0x84da
setmobjstate_switch_jump_11:
0x00000000000085ad:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085b0:  89 F0                mov       ax, si
0x00000000000085b2:  E8 22 AC             call      0x31d7
0x00000000000085b5:  E9 22 FF             jmp       0x84da
setmobjstate_switch_jump_12:
0x00000000000085b8:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085bb:  89 F0                mov       ax, si
0x00000000000085bd:  E8 57 B2             call      0x3817
0x00000000000085c0:  E9 17 FF             jmp       0x84da
setmobjstate_switch_jump_13:
0x00000000000085c3:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085c6:  89 F0                mov       ax, si
0x00000000000085c8:  E8 EE B3             call      0x39b9
0x00000000000085cb:  E9 0C FF             jmp       0x84da
setmobjstate_switch_jump_14:
0x00000000000085ce:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085d1:  89 F0                mov       ax, si
0x00000000000085d3:  E8 AD B4             call      0x3a83
0x00000000000085d6:  E9 01 FF             jmp       0x84da
setmobjstate_switch_jump_15:
0x00000000000085d9:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085dc:  89 F0                mov       ax, si
0x00000000000085de:  E8 60 B5             call      0x3b41
0x00000000000085e1:  E9 F6 FE             jmp       0x84da
setmobjstate_switch_jump_16:
0x00000000000085e4:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085e7:  89 F0                mov       ax, si
0x00000000000085e9:  E8 D7 B3             call      0x39c3
0x00000000000085ec:  E9 EB FE             jmp       0x84da
setmobjstate_switch_jump_17:
0x00000000000085ef:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085f2:  89 F0                mov       ax, si
0x00000000000085f4:  E8 EA B3             call      0x39e1
0x00000000000085f7:  E9 E0 FE             jmp       0x84da
setmobjstate_switch_jump_18:
0x00000000000085fa:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000085fd:  89 F0                mov       ax, si
0x00000000000085ff:  E8 D0 B3             call      0x39d2
0x0000000000008602:  E9 D5 FE             jmp       0x84da
setmobjstate_switch_jump_19:
0x0000000000008605:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008608:  89 F0                mov       ax, si
0x000000000000860a:  E8 44 AF             call      0x3551
0x000000000000860d:  E9 CA FE             jmp       0x84da
setmobjstate_switch_jump_20:
0x0000000000008610:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008613:  89 F0                mov       ax, si
0x0000000000008615:  E8 B5 B0             call      0x36cd
0x0000000000008618:  E9 BF FE             jmp       0x84da
setmobjstate_switch_jump_21:
0x000000000000861b:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000861e:  89 F0                mov       ax, si
0x0000000000008620:  E8 C3 B0             call      0x36e6
0x0000000000008623:  E9 B4 FE             jmp       0x84da
setmobjstate_switch_jump_22:
0x0000000000008626:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008629:  89 F0                mov       ax, si
0x000000000000862b:  E8 CD AE             call      0x34fb
0x000000000000862e:  E9 A9 FE             jmp       0x84da
setmobjstate_switch_jump_23:
0x0000000000008631:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008634:  89 F0                mov       ax, si
0x0000000000008636:  E8 DF B5             call      0x3c18
0x0000000000008639:  E9 9E FE             jmp       0x84da
setmobjstate_switch_jump_24:
0x000000000000863c:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000863f:  89 F0                mov       ax, si
0x0000000000008641:  E8 39 B6             call      0x3c7d
0x0000000000008644:  E9 93 FE             jmp       0x84da
setmobjstate_switch_jump_25:
0x0000000000008647:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000864a:  89 F0                mov       ax, si
0x000000000000864c:  E8 4F B6             call      0x3c9e
0x000000000000864f:  E9 88 FE             jmp       0x84da
setmobjstate_switch_jump_26:
0x0000000000008652:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008655:  89 F0                mov       ax, si
0x0000000000008657:  E8 65 B6             call      0x3cbf
0x000000000000865a:  E9 7D FE             jmp       0x84da
setmobjstate_switch_jump_27:
0x000000000000865d:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008660:  89 F0                mov       ax, si
0x0000000000008662:  E8 67 B9             call      0x3fcc
0x0000000000008665:  E9 72 FE             jmp       0x84da
setmobjstate_switch_jump_28:
0x0000000000008668:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000866b:  89 F0                mov       ax, si
0x000000000000866d:  E8 ED AB             call      0x325d
0x0000000000008670:  E9 67 FE             jmp       0x84da
setmobjstate_switch_jump_29:
0x0000000000008673:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008676:  89 F0                mov       ax, si
0x0000000000008678:  E8 5C AC             call      0x32d7
0x000000000000867b:  E9 5C FE             jmp       0x84da
setmobjstate_switch_jump_30:
0x000000000000867e:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008681:  89 F0                mov       ax, si
0x0000000000008683:  E8 22 AD             call      0x33a8
0x0000000000008686:  E9 51 FE             jmp       0x84da
setmobjstate_switch_jump_31:
0x0000000000008689:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000868c:  89 F0                mov       ax, si
0x000000000000868e:  E8 6D AD             call      0x33fe
0x0000000000008691:  E9 46 FE             jmp       0x84da
setmobjstate_switch_jump_32:
0x0000000000008694:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008697:  89 F0                mov       ax, si
0x0000000000008699:  E8 A0 AD             call      0x343c
0x000000000000869c:  E9 3B FE             jmp       0x84da
setmobjstate_switch_jump_33:
0x000000000000869f:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086a2:  89 F0                mov       ax, si
0x00000000000086a4:  E8 07 AE             call      0x34ae
0x00000000000086a7:  E9 30 FE             jmp       0x84da
setmobjstate_switch_jump_34:
0x00000000000086aa:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086ad:  89 F0                mov       ax, si
0x00000000000086af:  E8 27 B6             call      0x3cd9
0x00000000000086b2:  E9 25 FE             jmp       0x84da
setmobjstate_switch_jump_35:
0x00000000000086b5:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086b8:  89 F0                mov       ax, si
0x00000000000086ba:  E8 EE B9             call      0x40ab
0x00000000000086bd:  E9 1A FE             jmp       0x84da
setmobjstate_switch_jump_36:
0x00000000000086c0:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086c3:  89 F0                mov       ax, si
0x00000000000086c5:  E8 67 AC             call      0x332f
0x00000000000086c8:  E9 0F FE             jmp       0x84da
setmobjstate_switch_jump_37:
0x00000000000086cb:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086ce:  89 F0                mov       ax, si
0x00000000000086d0:  E8 E7 B9             call      0x40ba
0x00000000000086d3:  E9 04 FE             jmp       0x84da
setmobjstate_switch_jump_38:
0x00000000000086d6:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086d9:  89 F0                mov       ax, si
0x00000000000086db:  E8 A9 AC             call      0x3387
0x00000000000086de:  E9 F9 FD             jmp       0x84da
setmobjstate_switch_jump_39:
0x00000000000086e1:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086e4:  89 F0                mov       ax, si
0x00000000000086e6:  E8 B3 B9             call      0x409c
0x00000000000086e9:  E9 EE FD             jmp       0x84da
setmobjstate_switch_jump_40:
0x00000000000086ec:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086ef:  89 F0                mov       ax, si
0x00000000000086f1:  E8 99 AD             call      0x348d
0x00000000000086f4:  E9 E3 FD             jmp       0x84da
setmobjstate_switch_jump_41:
0x00000000000086f7:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x00000000000086fa:  89 F0                mov       ax, si
0x00000000000086fc:  E8 95 B7             call      0x3e94
0x00000000000086ff:  E9 D8 FD             jmp       0x84da
setmobjstate_switch_jump_42:
0x0000000000008702:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008705:  89 F0                mov       ax, si
0x0000000000008707:  E8 A5 B7             call      0x3eaf
0x000000000000870a:  E9 CD FD             jmp       0x84da
setmobjstate_switch_jump_43:
0x000000000000870d:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008710:  89 F0                mov       ax, si
0x0000000000008712:  E8 4F A7             call      0x2e64
0x0000000000008715:  E9 C2 FD             jmp       0x84da
setmobjstate_switch_jump_44:
0x0000000000008718:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000871b:  89 F0                mov       ax, si
0x000000000000871d:  E8 F7 B9             call      0x4117
0x0000000000008720:  E9 B7 FD             jmp       0x84da
setmobjstate_switch_jump_45:
0x0000000000008723:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008726:  89 F0                mov       ax, si
0x0000000000008728:  E8 F8 B9             call      0x4123
0x000000000000872b:  E9 AC FD             jmp       0x84da
setmobjstate_switch_jump_49:
0x000000000000872e:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008731:  89 F0                mov       ax, si
0x0000000000008733:  E8 B3 BB             call      0x42e9
0x0000000000008736:  E9 A1 FD             jmp       0x84da
setmobjstate_switch_jump_50:
0x0000000000008739:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000873c:  89 F0                mov       ax, si
0x000000000000873e:  E8 B7 BB             call      0x42f8
0x0000000000008741:  E9 96 FD             jmp       0x84da
setmobjstate_switch_jump_51:
0x0000000000008744:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008747:  89 F0                mov       ax, si
0x0000000000008749:  E8 6B BA             call      0x41b7
0x000000000000874c:  E9 8B FD             jmp       0x84da
setmobjstate_switch_jump_46:
0x000000000000874f:  9A 68 19 88 0A       call      G_ExitLevel_
0x0000000000008754:  E9 83 FD             jmp       0x84da
setmobjstate_switch_jump_47:
0x0000000000008757:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x000000000000875a:  89 F0                mov       ax, si
0x000000000000875c:  C6 44 1B B5          mov       byte ptr ds:[si + MOBJ_T.m_tics], 0xb5
0x0000000000008760:  E8 66 B9             call      0x40c9
0x0000000000008763:  E9 74 FD             jmp       0x84da
setmobjstate_switch_jump_48:
0x0000000000008766:  8B 4E FE             mov       cx, word ptr [bp - 2]
0x0000000000008769:  89 F0                mov       ax, si
0x000000000000876b:  C6 44 1B 96          mov       byte ptr ds:[si + MOBJ_T.m_tics], 0x96
0x000000000000876f:  E8 CD BA             call      0x423f
0x0000000000008772:  E9 65 FD             jmp       0x84da
0x0000000000008775:  FC                   cld       

ENDP


@

END
