

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


EXTRN I_Error_:FAR
EXTRN Z_QuickMapPhysics_:FAR

EXTRN locallib_toupper_:NEAR
EXTRN G_ResetGameKeys_:NEAR
EXTRN P_SetupLevel_:NEAR
EXTRN S_ResumeSound_:FAR
EXTRN Z_QuickMapRender_:FAR
EXTRN Z_QuickMapRender_9000To6000_:NEAR

.DATA

EXTRN _mousebuttons:BYTE

COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE


PROC    G_SETUP_STARTMARKER_ NEAR
PUBLIC  G_SETUP_STARTMARKER_
ENDP

str_texturenum_error:
db 0Ah, "R_TextureNumForName: %s not found", 0


PROC    R_CheckTextureNumForName_ NEAR
PUBLIC  R_CheckTextureNumForName_

mov     word ptr cs:[SELFMODIFY_set_arg_pointer+1], ax

PUSHA_NO_AX_OR_BP_MACRO


mov     cx, word ptr ds:[_numtextures] 


xor     si, si ; loop counter
mov     dx, si ; zero dh.
mov     ax, TEXTUREDEFS_OFFSET_6000_SEGMENT
mov     ds, ax
mov     ax, TEXTUREDEFS_BYTES_6000_SEGMENT
mov     es, ax

loop_next_tex:
lodsw   

xchg    ax, bx  ; bx gets es:bx ptr


SELFMODIFY_set_arg_pointer:
mov     di, 01000h			; di gets arg param ptr

; inline strncasecmp


mov   dl, 8   ; 8 chars

; ss:di vs es:bx.
; n = dx 

loop_next_char_strncasecmp:
mov    al, byte ptr ss:[di]
inc    di
call   locallib_toupper_
mov    ah, byte ptr es:[bx]
inc    bx
;call   locallib_toupper_  ; these are always caps already right

; ah is b
; al is a

sub    al, ah
jne    tex_not_found ; chars different.

test   ah, ah
je     found_tex  ; both were zero, or null terminated.

dec    dx
jnz    loop_next_char_strncasecmp
; fall thru, found tex.
done_with_strncasecmp:

found_tex:
shr     si, 1
didnt_find_tex:
dec     si ; si overshot by 1 due to lods
mov     es, si

push    ss
pop     ds

POPA_NO_AX_OR_BP_MACRO
mov     ax, es

ret

tex_not_found:
loop    loop_next_tex

xor     si, si		; to return -1
jmp     didnt_find_tex

ENDP


PROC    R_TextureNumForName_ NEAR
PUBLIC  R_TextureNumForName_

push    si
xchg    ax, si
xor     ax, ax ; return 0 case
cmp     byte ptr ds:[si], '-'
je      return_false

xchg    ax, si
push    ax  ; in case needed for error case below
call    R_CheckTextureNumForName_
js      do_error  ; signed from dec si in the function above

pop     si  ; undo push above..
return_false:

pop     si


ret

do_error:

; ax with ptr already passed in
push    cs
mov     ax, OFFSET str_texturenum_error
push    ax
call    I_Error_
; ret not needed
ENDP


PROC    G_DoLoadLevel_ NEAR
PUBLIC  G_DoLoadLevel_

push    bx
push    dx

call	Z_QuickMapPhysics_

cmp     byte ptr ds:[_wipegamestate], GS_LEVEL
jne     dont_force_wipe
mov     byte ptr ds:[_wipegamestate], -1
dont_force_wipe:
mov     byte ptr ds:[_gamestate], GS_LEVEL

cmp     byte ptr ds:[_player + PLAYER_T.player_playerstate], PST_DEAD
jne     dont_do_reborn_player
mov     byte ptr ds:[_player + PLAYER_T.player_playerstate], PST_REBORN

dont_do_reborn_player:

xor     ax, ax
cwd
mov     bx, ax

mov     al, byte ptr ds:[_gameepisode]
mov     dl, byte ptr ds:[_gamemap]
mov     bl, byte ptr ds:[_gameskill]
call    P_SetupLevel_

les     ax, dword ptr ds:[_ticcount]
mov     word ptr ds:[_starttime+0], ax
mov     word ptr ds:[_starttime+2], es

mov     byte ptr ds:[_gameaction], GA_NOTHING

call    G_ResetGameKeys_

xor     ax, ax
mov     byte ptr ds:[_paused], al ; 0
mov     byte ptr ds:[_sendsave], al ; 0
mov     byte ptr ds:[_sendpause], al ; 0
mov     bx, word ptr ds:[_mousebuttons]
mov     word ptr ds:[bx], ax
mov     byte ptr ds:[bx+2], al ; i guess 3 bytes...?


pop    dx
pop    bx



ret
ENDP

HIGHBIT = 080h

;void __near G_InitNew (skill_t skill, int8_t episode, int8_t map) {

PROC    G_InitNew_ NEAR
PUBLIC  G_InitNew_

xor   ah, ah

cmp   byte ptr ds:[_paused], ah ; 0
je    dont_unpause
mov   byte ptr ds:[_paused], ah ; 0
push  ax
call  S_ResumeSound_
pop   ax

dont_unpause:

cmp   al, SK_NIGHTMARE
jbe   dont_cap_skill
mov   al, SK_NIGHTMARE
dont_cap_skill:

cmp   byte ptr ds:[_is_ultimate], ah
xchg  ax, dx

jne   us_ultimate
cmp   al, 3
jb    dont_cap_ultimate_ep_high
mov   al, 3
dont_cap_ultimate_ep_high:
test  al, al
jne   ultimate_ep_not_zero
inc   ax  ; change 0 to 1
ultimate_ep_not_zero:
jmp   done_with_episode_check
us_ultimate:
test  al, al
jne   done_with_episode_check
mov   al, 4


done_with_episode_check:
xchg  ax, dx


cmp   byte ptr ds:[_shareware], ah
je    skip_shareware_checks
mov   dl, 1 ; forced episode 1
skip_shareware_checks:

cmp   bl, 1
jnb   map_not_too_low
mov   bl, 1
map_not_too_low:

cmp   byte ptr ds:[_commercial], ah
jne   skip_commercial_mapcheck
cmp   bl, 9
jna   skip_commercial_mapcheck
mov   bl, 9
skip_commercial_mapcheck:

mov   byte ptr ds:[_prndindex], ah ; 0
mov   byte ptr ds:[_rndindex], ah ; 0

mov   byte ptr ds:[_gamemap], bl ; free up bx
mov   byte ptr ds:[_gameepisode], dl ; free up dx


mov   dl, byte ptr ds:[_gameskill]

mov   byte ptr ds:[_respawnmonsters], ah
cmp   byte ptr ds:[_respawnparm], ah
mov   byte ptr ds:[_gameskill], al ; finally write this
jne   do_respawn_on
cmp   al, SK_NIGHTMARE
jne   keep_respawn_off
do_respawn_on:
inc   byte ptr ds:[_respawnparm]
keep_respawn_off:

mov   dx, STATES_SEGMENT
mov   es, dx
mov   bx, (S_SARG_RUN1 * SIZE STATE_T) + STATE_T.state_tics ; 6 bytes per

cmp   byte ptr ds:[_fastparm], ah
jne   do_fastmonsters_on

; (skill == sk_nightmare && gameskill != sk_nightmare)
cmp   al, SK_NIGHTMARE
jne   check_fastmonsters_off
cmp   dl, SK_NIGHTMARE    ; check old setting
je    check_fastmonsters_off
do_fastmonsters_on:

speedup_next_state:
shr   byte ptr es:[bx ], 1  ; already offset to  STATE_T.state_tics
add   bx, SIZE STATE_T
cmp   bx, (S_SARG_PAIN2 * SIZE STATE_T)
jl    speedup_next_state

mov   al, 20 + HIGHBIT
mov   byte ptr ds:[_mobjinfo + (MT_BRUISERSHOT * (SIZE MOBJINFO_T )) + MOBJINFO_T.mobjinfo_speed], al
mov   byte ptr ds:[_mobjinfo + (MT_HEADSHOT * (SIZE MOBJINFO_T)) + MOBJINFO_T.mobjinfo_speed], al
mov   byte ptr ds:[_mobjinfo + (MT_TROOPSHOT * (SIZE MOBJINFO_T)) + MOBJINFO_T.mobjinfo_speed], al


jmp     done_with_fastmonsters
check_fastmonsters_off:
cmp   al, SK_NIGHTMARE
je    done_with_fastmonsters
cmp   dl, SK_NIGHTMARE    ; check old setting
jne   done_with_fastmonsters

do_fastmonsters_off:



speeddown_next_state:
shl   byte ptr es:[bx ], 1  ; already offset to  STATE_T.state_tics
add   bx, SIZE STATE_T
cmp   bx, (S_SARG_PAIN2 * SIZE STATE_T)
jl    speeddown_next_state

mov   al, 10 + HIGHBIT
mov   byte ptr ds:[_mobjinfo + (MT_BRUISERSHOT * (SIZE MOBJINFO_T)) + MOBJINFO_T.mobjinfo_speed], 15 + HIGHBIT
mov   byte ptr ds:[_mobjinfo + (MT_HEADSHOT * (SIZE MOBJINFO_T)) + MOBJINFO_T.mobjinfo_speed], al
mov   byte ptr ds:[_mobjinfo + (MT_TROOPSHOT * (SIZE MOBJINFO_T)) + MOBJINFO_T.mobjinfo_speed], al


done_with_fastmonsters:

mov   byte ptr ds:[_player + PLAYER_T.player_playerstate], PST_REBORN
mov   al, 1 ; ah still 0

mov   byte ptr ds:[_usergame], al		; true
mov   byte ptr ds:[_paused], ah			; false
mov   byte ptr ds:[_demoplayback], ah	; false
mov   byte ptr ds:[_automapactive], ah	; false

mov   byte ptr ds:[_viewactive], al		; true


xchg  ax, dx ; dx gets 0001

call	Z_QuickMapRender_
call    Z_QuickMapRender_9000To6000_  ; //for R_TextureNumForName

; todo this stuff

mov   bl, '1'
xchg  ax, dx  ; ah zero again.
cmp   byte ptr ds:[_commercial], al
je    commercial_on_sky



jmp   done_with_sky
commercial_on_sky:
mov   al, byte ptr ds:[_gamemap]

cmp  al, 12
jl   do_sky_load
cmp  al, 21
jl   add_one_do_sky_load
jmp  add_two_do_sky_load

done_with_sky:
mov   al, byte ptr ds:[_gameepisode]
dec   ax
jz    do_sky_load
dec   ax
jz    add_one_do_sky_load
dec   ax
jz    add_two_do_sky_load

add_three_do_sky_load:
inc   bx
add_two_do_sky_load:
inc   bx
add_one_do_sky_load:
inc   bx
do_sky_load:
mov     byte ptr ds:[_SKY_String + 3], bl
mov     ax, OFFSET _SKY_String
call    R_TextureNumForName_
mov     word ptr ds:[_skytexture], ax


call	Z_QuickMapPhysics_
call	G_DoLoadLevel_  ; todo do a fall thru 

ret


ENDP

 

PROC    G_SETUP_ENDMARKER_ NEAR
PUBLIC  G_SETUP_ENDMARKER_
ENDP


END
