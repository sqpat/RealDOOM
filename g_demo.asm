


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


EXTRN locallib_putchar_:NEAR


.DATA

EXTRN _demo_p:WORD
EXTRN _pagetic:WORD
EXTRN _pagename:WORD
EXTRN _defdemoname:DWORD



.CODE


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



PROC    G_DEMO_ENDMARKER_ NEAR
PUBLIC  G_DEMO_ENDMARKER_
ENDP



END