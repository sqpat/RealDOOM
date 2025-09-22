


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


EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapDemo_:FAR
EXTRN I_Error_:FAR
EXTRN M_WriteFile_:NEAR
EXTRN I_Quit_:FAR
EXTRN W_CacheLumpNameDirectFarString_:FAR
EXTRN G_InitNew_:NEAR


.DATA

EXTRN _demo_p:WORD
EXTRN _pagetic:WORD
EXTRN _pagename:WORD
EXTRN _defdemoname:DWORD
EXTRN _precache:BYTE
EXTRN _timingdemo:BYTE
EXTRN _singledemo:BYTE


.CODE

EXTRN _gamekeydown:BYTE


PROC    G_DEMO_STARTMARKER_ NEAR
PUBLIC  G_DEMO_STARTMARKER_
ENDP

str_demo1:
db "demo1", 0
str_demo2:
db "demo2", 0
str_demo3:
db "demo3", 0
str_demo4:
db "demo4", 0
str_TITLEPIC:
db "TITLEPIC", 0
str_CREDIT:
db "CREDIT", 0
str_HELP2:
db "HELP2", 0




PROC    G_DeferedPlayDemo_ NEAR
PUBLIC  G_DeferedPlayDemo_


mov     word ptr ds:[_defdemoname+0], ax
; todo remove
mov     word ptr ds:[_defdemoname+2], cs
mov     byte ptr ds:[_gameaction], ga_playdemo ; GA_NOTHING

ret
ENDP


demo_jump_table:
dw demo_sequence_0, demo_sequence_1, demo_sequence_2, demo_sequence_3, demo_sequence_4, demo_sequence_5, demo_sequence_6

PROC    D_DoAdvanceDemo_ NEAR
PUBLIC  D_DoAdvanceDemo_

push    dx
push    bx

xor     ax, ax
mov     byte ptr ds:[_player + PLAYER_T.player_playerstate], al ; PST_LIVE
mov     byte ptr ds:[_advancedemo], al
mov     byte ptr ds:[_usergame], al
mov     byte ptr ds:[_paused], al
mov     byte ptr ds:[_gameaction], al ; GA_NOTHING


;	if (is_ultimate){
;    	demosequence = (demosequence+1)%7;
;	} else{
;    	demosequence = (demosequence+1)%6;
;	}

mov     al, byte ptr ds:[_demosequence]
cwd    
mov     dh, byte ptr ds:[_is_ultimate]
cmp     dh, dl   ; is_ultimate compare to 0
mov     bl, 6
je      not_ultimate
inc     bx
not_ultimate:
inc     al
div     bl
mov     al, ah
cbw
mov     byte ptr ds:[_demosequence], al 
sal     ax, 1
xchg    ax, bx
mov     dl, byte ptr ds:[_commercial]

; bh known zero
; dh _is_ultimate
; dl _commerical
jmp     word ptr cs:[demo_jump_table + bx]
demo_sequence_0:
mov     ax, 170
cmp     dl, bh ; 0
mov     bl, MUS_INTRO
je      dont_adjust_pagetic_commercial
mov     ax, 35 * 11
mov     bl, MUS_DM2TTL
dont_adjust_pagetic_commercial:
mov     word ptr ds:[_pagetic], ax
mov     word ptr ds:[_pendingmusicenum], bx   ; set repeat to 0 in high byte
mov     byte ptr ds:[_gamestate], GS_DEMOSCREEN
mov     word ptr ds:[_pagename], OFFSET str_TITLEPIC
jmp     done_with_demo_sequence_switch_block
demo_sequence_1:
mov     ax, OFFSET str_demo1
call    G_DeferedPlayDemo_
jmp     done_with_demo_sequence_switch_block

demo_sequence_2:
mov     word ptr ds:[_pagetic], 200
mov     byte ptr ds:[_gamestate], GS_DEMOSCREEN
mov     word ptr ds:[_pagename], OFFSET str_CREDIT
jmp     done_with_demo_sequence_switch_block

demo_sequence_3:
mov     ax, OFFSET str_demo2
call    G_DeferedPlayDemo_
jmp     done_with_demo_sequence_switch_block

demo_sequence_4:
mov     byte ptr ds:[_gamestate], GS_DEMOSCREEN
cmp     dl, bh  ; commercial
je      not_commercial_seq_4
mov     ax, 35 * 11
mov     dx, OFFSET str_TITLEPIC
mov     word ptr ds:[_pendingmusicenum], MUS_DM2TTL ; set repeat to 0 in high byte
jmp     do_seq_4_stuff
not_commercial_seq_4:
mov    ax, 200
cmp    dh, bh   ; ultimate
mov    dx, OFFSET str_HELP2
je     do_seq_4_stuff
mov    dx, OFFSET str_CREDIT
do_seq_4_stuff:
mov    word ptr ds:[_pagetic], ax
mov    word ptr ds:[_pagename], dx
jmp    done_with_demo_sequence_switch_block

demo_sequence_5:
mov    ax, OFFSET str_demo3
call   G_DeferedPlayDemo_
jmp    done_with_demo_sequence_switch_block

demo_sequence_6:
; todo shouldnt happen if ultimate already? no need for check?
mov    ax, OFFSET str_demo4
call   G_DeferedPlayDemo_



done_with_demo_sequence_switch_block:


pop     bx
pop     dx
ret
ENDP



PROC   G_BeginRecording_ NEAR
PUBLIC G_BeginRecording_

push   di
call   Z_QuickMapDemo_
mov    ax, DEMO_SEGMENT
mov    es, ax
xor    di, di
mov    al, VERSION
stosb
mov    al, byte ptr ds:[_gameskill]
stosb
mov    ax, word ptr ds:[_gameepisode]
stosb
mov    al, ah ; gamemap
stosb
xor    ax, ax
stosb
mov    al, byte ptr ds:[_respawnparm]
stosb
mov    al, byte ptr ds:[_fastparm]
stosb
mov    al, byte ptr ds:[_nomonsters]
stosb
mov    al, ah ; 0
stosb
inc    ax     ; true
stosw   
dec    ax     ; true
stosw   
mov    word ptr ds:[_demo_p], di
call   Z_QuickMapPhysics_

pop    di

ret
ENDP

PROC   G_DoPlayDemo_ NEAR
PUBLIC G_DoPlayDemo_

call   Z_QuickMapDemo_
xor    bx, bx
mov    byte ptr ds:[_gameaction], bl ; 0 GA_NOTHING

les    ax, dword ptr ds:[_defdemoname]
mov    dx, es
mov    cx, DEMO_SEGMENT
mov    si, cx
call   W_CacheLumpNameDirectFarString_ ; (defdemoname, demobuffer);

mov    ds, si
xor    si, si
; ds:si is demo_addr
lodsb
cmp    al, VERSION
jne    do_version_error
do_version_error:  ; todo?

lodsw
xchg   ax, dx   ; dl = skill, dh = episode
lodsw
xchg   ax, bx   ; bl = map,   bh = deathmatch
lodsw
xchg   ax, cx   ; cl = respawn, ch = fastparm
lodsb


push   ss
pop    ds
mov    byte ptr ds:[_respawnparm], cl
mov    byte ptr ds:[_fastparm], ch
mov    byte ptr ds:[_nomonsters], al
lea    ax, [si+ 5]
mov    word ptr ds:[_demo_p], ax ; probably a constant actually

xchg   ax, dx ; al = skill, ah = episode
mov    dl, ah ; dl = episode
mov    byte ptr ds:[_precache], 0  ; false
call   G_InitNew_

mov    ax, 1
mov    byte ptr ds:[_precache], al      ; true
mov    byte ptr ds:[_usergame], ah      ; false
mov    byte ptr ds:[_demoplayback], al  ; true


call   Z_QuickMapPhysics_


ret
ENDP


DEMOMARKER = 080h



PROC   G_WriteDemoTiccmd_ NEAR
PUBLIC G_WriteDemoTiccmd_

push   di
push   si
xchg   ax, si

call   Z_QuickMapDemo_

mov  al, byte ptr cs:['q' + _gamekeydown]
je   dont_end_demo_q
call G_CheckDemoStatus_

dont_end_demo_q:

mov    di, word ptr ds:[_demo_p]
mov    ax, DEMO_SEGMENT
mov    es, ax
movsw ; forwardmove, sidemove
lodsw
add    ax, 128
mov    al, ah
stosb
inc    di
inc    di
inc    di
movsb

lea    ax, [di - SIZE TICCMD_T]

;call   G_ReadDemoTiccmd_   ; internally calls z_quickmap etc
jmp     do_readdemo_from_write

ENDP


PROC   G_ReadDemoTiccmd_ NEAR
PUBLIC G_ReadDemoTiccmd_

push   di
push   si
do_readdemo_from_write:
xchg   ax, di

call   Z_QuickMapDemo_

mov    si, word ptr ds:[_demo_p]
mov    ax, DEMO_SEGMENT
mov    ds, ax

lodsb
cmp   al, DEMOMARKER
jne   dont_end_demo
push  ss
pop   ds
call  G_CheckDemoStatus_
jmp   exit_playdemo


dont_end_demo:

stosb ; forwardmove ; 0
lodsw
stosb ; sidemove    ; 1
xor   al, al
stosw ; ;           ; 2-3 cmd->angleturn = ((uint8_t)*demo_addr++)<<8; 
inc   di ; 4
inc   di ; 5
inc   di ; 6
movsb  

push  ss
pop   ds
mov   word ptr ds:[_demo_p], si

exit_playdemo:
call   Z_QuickmapPhysics_

pop    si
pop    di
ret
ENDP


str_timed_tics:
db 0Ah, "timed %li gametics in %li realtics ", 0Ah, " prnd index %i ", 0
str_demo_recorded:
db "Demo %s recorded", 0

PROC   G_CheckDemoStatus_ NEAR
PUBLIC G_CheckDemoStatus_


xor    ax, ax
cmp    byte ptr ds:[_timingdemo], al ; 0
je     dont_end_playback
les    ax, dword ptr ds:[_ticcount]
mov    dx, es
sub    ax, word ptr ds:[_starttime + 0]
sbb    dx, word ptr ds:[_starttime + 2]
push   word ptr ds:[_prndindex]
push   dx
push   ax
push   word ptr ds:[_gametic+2]
push   word ptr ds:[_gametic+0]


push   cs
mov    ax, OFFSET str_timed_tics
push   ax
call   I_Error_

dont_end_playback:

cmp    byte ptr ds:[_demoplayback], al ; 0
je     skip_demo_playback_end_check
cmp    byte ptr ds:[_singledemo], al
je     dont_quit
call   I_Quit_
dont_quit:

mov     byte ptr ds:[_demoplayback], al ; false                      
mov     byte ptr ds:[_respawnparm], al ; false                      
mov     byte ptr ds:[_fastparm], al ; false                      
mov     byte ptr ds:[_nomonsters], al ; false                      
mov     byte ptr ds:[_advancedemo], al ; false                      

ret

skip_demo_playback_end_check:
cmp    byte ptr ds:[_demorecording], al ; 0
je     just_exit
call   Z_QuickMapDemo_

mov    di, word ptr ds:[_demo_p]
mov    ax, DEMO_SEGMENT
mov    es, ax
mov    al, DEMOMARKER
stosb
mov    word ptr ds:[_demo_p], di

mov    ax, word ptr ds:[_demoname]
xor    bx, bx
mov    cx, DEMO_SEGMENT
mov    dx, di
push   ax ; for I_Error call
call   M_WriteFile_

; is this necessary? i guess so in i_quit?
 mov    byte ptr ds:[_demorecording], 0

push   cs
mov    ax, OFFSET str_demo_recorded
push   ax
call   I_Error_

just_exit:
ret

ENDP

PROC    G_DEMO_ENDMARKER_ NEAR
PUBLIC  G_DEMO_ENDMARKER_
ENDP



END