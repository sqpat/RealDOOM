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
EXTRN M_Random_:NEAR
EXTRN FixedMul1632_:NEAR
EXTRN FixedDivWholeA_:FAR
EXTRN FixedDiv_:FAR
EXTRN FastDiv3216u_:FAR
EXTRN cht_CheckCheat_:NEAR
EXTRN combine_strings_:NEAR
EXTRN FastMulTrig16_:NEAR
EXTRN V_DrawPatch_:FAR
EXTRN V_MarkRect_:FAR
EXTRN getStringByIndex_:FAR

; todo ghetto
AMMNUMPATCHOFFSETS_FAR_OFFSET = 20Ch 

AUTOMAP_SCREENWIDTH = SCREENWIDTH
AUTOMAP_SCREENHEIGHT = SCREENHEIGHT - 32
AM_NUMMARKPOINTS = 10

; FRAC_SCALE_UNIT * 1.02
M_ZOOMIN =        4177
; how much zoom-out per tic
; pulls out to 0.5x in 1 second
; FRAC_SCALE_UNIT / 1.02
M_ZOOMOUT =      4015

COLOR_REDS	=	(256-5*16)
REDRANGE = 16
COLOR_BLUES	=	(256-4*16+8)
COLOR_GREYS = 6 * 16
COLOR_BROWNS = 4 * 16
COLOR_GREENS = 7 * 16
GRIDCOLORS = 104
COLOR_WHITE = 256-47
COLOR_YELLOWS	= (256-32+7) ; E7h


WALLCOLORS =       COLOR_REDS
SECRETWALLCOLORS = WALLCOLORS
WALLRANGE =        REDRANGE
TSWALLCOLORS =     COLOR_GREYS
CDWALLCOLORS =     COLOR_YELLOWS
XHAIRCOLORS =      COLOR_GREYS
FDWALLCOLORS =     COLOR_BROWNS
FDWALLCOLORS =     COLOR_BROWNS
THINGCOLORS =      COLOR_GREENS

KEY_RIGHTARROW =    0AEh
KEY_LEFTARROW =     0ACh
KEY_UPARROW =       0ADh
KEY_DOWNARROW =     0AFh
KEY_ESCAPE =        27
KEY_ENTER =     	13
KEY_TAB =       	9

AM_PANDOWNKEY =     KEY_DOWNARROW
AM_PANUPKEY =      	KEY_UPARROW
AM_PANRIGHTKEY =    KEY_RIGHTARROW
AM_PANLEFTKEY =     KEY_LEFTARROW
AM_ZOOMINKEY =     	'='
AM_ZOOMOUTKEY =     '-'
AM_STARTKEY =      	KEY_TAB
AM_ENDKEY =        	KEY_TAB
AM_GOBIGKEY =      	'0'
AM_FOLLOWKEY =     	'f'
AM_GRIDKEY =       	'g'
AM_MARKKEY =       	'm'
AM_CLEARMARKKEY =   'c'


.DATA

EXTRN _m_paninc:MPOINT_T
EXTRN _am_scale_ftom:DWORD
EXTRN _am_scale_mtof:DWORD
EXTRN _mtof_zoommul:WORD
EXTRN _ftom_zoommul:WORD

EXTRN _am_min_level_x:WORD
EXTRN _am_min_level_y:WORD
EXTRN _am_min_scale_mtof:WORD
EXTRN _am_max_scale_mtof:WORD
EXTRN _am_max_level_x:WORD
EXTRN _am_max_level_y:WORD

EXTRN _screen_botleft_x:WORD
EXTRN _screen_botleft_y:WORD
EXTRN _screen_topright_x:WORD
EXTRN _screen_topright_y:WORD
EXTRN _screen_viewport_width:WORD
EXTRN _screen_viewport_height:WORD

EXTRN _screen_oldloc:MPOINT_T
EXTRN _screen_oldloc:MPOINT_T
EXTRN _old_screen_botleft_x:WORD
EXTRN _old_screen_botleft_y:WORD
EXTRN _old_screen_viewport_width:WORD
EXTRN _old_screen_viewport_height:WORD

EXTRN _followplayer:BYTE
EXTRN _am_cheating:BYTE
EXTRN _am_grid:BYTE
EXTRN _am_bigstate:BYTE
EXTRN _am_stopped:BYTE

EXTRN _markpointnum:BYTE
EXTRN _am_lastlevel:BYTE
EXTRN _am_lastepisode:BYTE


EXTRN _am_fl:FLINE_T
EXTRN _am_l:MLINE_T
EXTRN _am_ml:MLINE_T
EXTRN _am_lc:FLINE_T

EXTRN _cheat_player_arrow:MLINE_T
EXTRN _player_arrow:MLINE_T
EXTRN _thintriangle_guy:MLINE_T
EXTRN _markpoints:MLINE_T



.CODE



PROC    AM_MAP_STARTMARKER_ NEAR
PUBLIC  AM_MAP_STARTMARKER_
ENDP





PROC    MTOF16_ NEAR
PUBLIC  MTOF16_


push      bx
push      cx
push      dx
les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
call      FixedMul1632_
pop       dx
pop       cx
pop       bx
ret       

ENDP

PROC    CXMTOF16_ NEAR
PUBLIC  CXMTOF16_


push      bx
push      cx
push      dx
les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
sub       ax, word ptr ds:[_screen_botleft_x]  ; todo dont suppose this can be self modified start of frame?
call      FixedMul1632_
pop       dx
pop       cx
pop       bx
ret       

ENDP


PROC    CYMTOF16_ NEAR
PUBLIC  CYMTOF16_

push      bx
push      cx
push      dx
les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
sub       ax, word ptr ds:[_screen_botleft_y]  ; todo dont suppose this can be self modified start of frame?
call      FixedMul1632_
neg       ax
add       ax, AUTOMAP_SCREENHEIGHT
pop       dx
pop       cx
pop       bx
ret       

ENDP

; todo optim
PROC    AM_activateNewScale_ NEAR
PUBLIC  AM_activateNewScale_

push      bx
push      cx
push      dx
mov       ax, word ptr ds:[_screen_viewport_width]  ; todo put side by side, LES and get both
sar       ax, 1
add       word ptr ds:[_screen_botleft_x], ax
mov       ax, word ptr ds:[_screen_viewport_height]
mov       bx, word ptr ds:[_am_scale_ftom + 0]
sar       ax, 1
mov       cx, word ptr ds:[_am_scale_ftom + 2]
add       word ptr ds:[_screen_botleft_y], ax
mov       ax, AUTOMAP_SCREENWIDTH
call      FixedMul1632_
mov       bx, word ptr ds:[_am_scale_ftom + 0]
mov       cx, word ptr ds:[_am_scale_ftom + 2]
mov       word ptr ds:[_screen_viewport_width], ax
mov       ax, AUTOMAP_SCREENHEIGHT
call      FixedMul1632_
mov       bx, word ptr ds:[_screen_viewport_width]
sar       bx, 1
sub       word ptr ds:[_screen_botleft_x], bx
mov       bx, ax
sar       bx, 1
sub       word ptr ds:[_screen_botleft_y], bx
mov       bx, word ptr ds:[_screen_botleft_x]
add       bx, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_screen_topright_x], bx
mov       bx, word ptr ds:[_screen_botleft_y]
mov       word ptr ds:[_screen_viewport_height], ax
add       ax, bx
mov       word ptr ds:[_screen_topright_y], ax
pop       dx
pop       cx
pop       bx
ret  

ENDP

; todo inline its single usage
; todo optim
PROC    AM_restoreScaleAndLoc_ NEAR
PUBLIC  AM_restoreScaleAndLoc_


push      bx
push      cx
push      dx
mov       ax, word ptr ds:[_old_screen_viewport_width]
mov       dx, word ptr ds:[_old_screen_viewport_height]
mov       word ptr ds:[_screen_viewport_width], ax
mov       word ptr ds:[_screen_viewport_height], dx
cmp       byte ptr ds:[_followplayer], 0
jne       do_follow_player
mov       ax, word ptr ds:[_old_screen_botleft_x]
mov       word ptr ds:[_screen_botleft_x], ax
mov       ax, word ptr ds:[_old_screen_botleft_y]
jmp       got_screen_xy
do_follow_player:
les       bx, dword ptr ds:[_playerMobj_pos]
sar       ax, 1
mov       cx, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
sub       cx, ax
mov       word ptr ds:[_screen_botleft_x], cx
sar       dx, 1
mov       ax, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
sub       ax, dx

got_screen_xy:
mov       word ptr ds:[_screen_botleft_y], ax
mov       ax, word ptr ds:[_screen_botleft_x]
add       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_screen_topright_x], ax
mov       ax, word ptr ds:[_screen_botleft_y]
mov       cx, word ptr ds:[_screen_viewport_width]
add       ax, word ptr ds:[_screen_viewport_height]
xor       bx, bx
mov       word ptr ds:[_screen_topright_y], ax
mov       ax, AUTOMAP_SCREENWIDTH
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_mtof + 0], ax
mov       bx, ax
mov       cx, dx
mov       ax, 1
mov       word ptr ds:[_am_scale_mtof + 2], dx
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
pop       dx
pop       cx
pop       bx
ret       


ENDP



PROC    AM_addMark_ NEAR
PUBLIC  AM_addMark_

;	markpointnum = (markpointnum + 1) % AM_NUMMARKPOINTS;
;    markpoints[markpointnum].x = screen_botleft_x + (screen_viewport_width >>1);
;    markpoints[markpointnum].y = screen_botleft_y + (screen_viewport_height >>1);


push      bx
mov       al, byte ptr ds:[_markpointnum]
cbw      

mov       bx, ax
inc       ax
mov       bh, AM_NUMMARKPOINTS
div       bh
mov       byte ptr ds:[_markpointnum], ah
xor       bh, bh

mov       ax, word ptr ds:[_screen_viewport_width] ; todo les
sar       ax, 1
SHIFT_MACRO shl       bx 2
add       ax, word ptr ds:[_screen_botleft_x]
mov       word ptr ds:[bx + _markpoints + MPOINT_T.mpoint_x], ax
mov       ax, word ptr ds:[_screen_viewport_height]
sar       ax, 1
add       ax, word ptr ds:[_screen_botleft_y]
mov       word ptr ds:[bx + _markpoints + MPOINT_T.mpoint_y], ax
pop       bx
ret       

ENDP

COMMENT @


PROC    AM_findMinMaxBoundaries_ NEAR
PUBLIC  AM_findMinMaxBoundaries_

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4
mov       ax, MAXSHORT
mov       di, -MAXSHORT ;08001 h
xor       bx, bx
xor       dx, dx
mov       word ptr ds:[_am_min_level_y], ax
mov       word ptr ds:[_am_min_level_x], ax
mov       word ptr ds:[_am_max_level_x], di
label_6:
mov       si, OFFSET _numvertexes
cmp       bx, word ptr ds:[si]
jge       label_3
mov       ax, VERTEXES_SEGMENT
mov       si, dx
mov       es, ax
mov       ax, word ptr es:[si]
cmp       ax, word ptr ds:[_am_min_level_x]
jge       label_4
mov       word ptr ds:[_am_min_level_x], ax
label_7:
mov       ax, VERTEXES_SEGMENT
mov       si, dx
mov       es, ax
mov       ax, word ptr es:[si + 2]
add       si, 2
cmp       ax, word ptr ds:[_am_min_level_y]
jge       label_5
mov       word ptr ds:[_am_min_level_y], ax
label_8:
add       dx, 4
inc       bx
jmp       label_6
label_4:
cmp       ax, word ptr ds:[_am_max_level_x]
jle       label_7
mov       word ptr ds:[_am_max_level_x], ax
jmp       label_7
label_5:
cmp       ax, di
jle       label_8
mov       di, ax
jmp       label_8
label_3:
mov       ax, word ptr ds:[_am_max_level_x]
sub       ax, word ptr ds:[_am_min_level_x]
mov       si, di
cwd       
mov       word ptr ds:[_am_max_level_y], di
mov       bx, ax
mov       cx, dx
mov       ax, AUTOMAP_SCREENWIDTH
xor       dx, dx
sub       si, word ptr ds:[_am_min_level_y]
call      FixedDiv_
mov       word ptr [bp - 4], ax
mov       ax, si
mov       word ptr [bp - 2], dx
cwd       
mov       bx, ax
mov       cx, dx
mov       ax, AUTOMAP_SCREENHEIGHT
xor       dx, dx
call      FixedDiv_
mov       di, word ptr ds:[_am_max_level_y]
cmp       dx, word ptr [bp - 2]
jg        label_9
jne       label_10
cmp       ax, word ptr [bp - 4]
jbe       label_10
label_9:
mov       ax, word ptr [bp - 4]
label_10:
;	am_max_scale_mtof.w = 0x54000;// FixedDiv(automap_screenheight, 2*16);

mov       word ptr ds:[_am_max_scale_mtof + 0], 04000h
mov       word ptr ds:[_am_max_scale_mtof + 2], 5
mov       word ptr ds:[_am_min_scale_mtof], ax
mov       word ptr ds:[_am_max_level_y], di
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       

ENDP

PROC    AM_changeWindowLoc_ NEAR
PUBLIC  AM_changeWindowLoc_

push      bx
push      cx
push      dx
mov       dx, word ptr ds:[_screen_botleft_x]
mov       bx, word ptr ds:[_screen_botleft_y]
cmp       word ptr ds:[_m_paninc + 0], 0
jne       label_11
cmp       word ptr ds:[_m_paninc + 2], 0
je        label_12
label_11:
mov       byte ptr ds:[_followplayer], 0
mov       word ptr ds:[_screen_oldloc + 0], MAXSHORT
label_12:
mov       ax, word ptr ds:[_m_paninc + 0]
add       dx, ax
mov       ax, word ptr ds:[_m_paninc + 2]
add       bx, ax
mov       ax, word ptr ds:[_screen_viewport_width]
mov       cx, dx
sar       ax, 1
add       cx, ax
cmp       cx, word ptr ds:[_am_max_level_x]
jle       label_13
mov       dx, word ptr ds:[_am_max_level_x]
label_17:
sub       dx, ax
label_16:
mov       ax, word ptr ds:[_screen_viewport_height]
mov       cx, bx
sar       ax, 1
add       cx, ax
cmp       cx, word ptr ds:[_am_max_level_y]
jg        label_14
cmp       cx, word ptr ds:[_am_min_level_y]
jge       label_15
mov       bx, word ptr ds:[_am_min_level_y]
label_18:
sub       bx, ax
label_15:
mov       ax, dx
add       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_screen_topright_x], ax
mov       ax, bx
add       ax, word ptr ds:[_screen_viewport_height]
mov       word ptr ds:[_screen_topright_y], ax
mov       word ptr ds:[_screen_botleft_y], bx
mov       word ptr ds:[_screen_botleft_x], dx
pop       dx
pop       cx
pop       bx
ret       
label_13:
cmp       cx, word ptr ds:[_am_min_level_x]
jge       label_16
mov       dx, word ptr ds:[_am_min_level_x]
jmp       label_17
label_14:
mov       bx, word ptr ds:[_am_max_level_y]
jmp       label_18

ENDP

FRAC_SCALE_UNIT = 01000h

PROC    AM_initVariables_ NEAR
PUBLIC  AM_initVariables_

push      bx
push      cx
push      dx
push      si
mov       bx, OFFSET _automapactive
xor       ax, ax
mov       cx, word ptr ds:[_am_scale_ftom + 2]
mov       word ptr ds:[_m_paninc + 2], ax
mov       word ptr ds:[_m_paninc + 0], ax
mov       byte ptr ds:[bx], 1
mov       ax, FRAC_SCALE_UNIT
mov       bx, word ptr ds:[_am_scale_ftom + 0]
mov       word ptr ds:[_ftom_zoommul], ax
mov       word ptr ds:[_mtof_zoommul], ax
mov       ax, AUTOMAP_SCREENWIDTH
mov       word ptr ds:[_screen_oldloc + 0], MAXSHORT
call      FixedMul1632_
mov       bx, word ptr ds:[_am_scale_ftom + 0]
mov       cx, word ptr ds:[_am_scale_ftom + 2]
mov       word ptr ds:[_screen_viewport_width], ax
mov       ax, AUTOMAP_SCREENHEIGHT
call      FixedMul1632_
mov       bx, OFFSET _playerMobj_pos
mov       word ptr ds:[_screen_viewport_height], ax
les       si, dword ptr ds:[bx]
mov       bx, word ptr ds:[_screen_viewport_width]
mov       cx, word ptr es:[si + 2]
sar       bx, 1
sub       cx, bx
mov       bx, OFFSET _playerMobj_pos
mov       word ptr ds:[_screen_botleft_x], cx
les       si, dword ptr ds:[bx]
sar       ax, 1
mov       bx, word ptr es:[si + 6]
sub       bx, ax
mov       word ptr ds:[_screen_botleft_y], bx
call      AM_changeWindowLoc_
mov       ax, word ptr ds:[_screen_botleft_x]
mov       bx, OFFSET _st_gamestate
mov       word ptr ds:[_old_screen_botleft_x], ax
mov       ax, word ptr ds:[_screen_botleft_y]
mov       byte ptr ds:[bx], 0
mov       word ptr ds:[_old_screen_botleft_y], ax
mov       ax, word ptr ds:[_screen_viewport_width]
mov       bx, OFFSET _st_firsttime
mov       word ptr ds:[_old_screen_viewport_width], ax
mov       ax, word ptr ds:[_screen_viewport_height]
mov       byte ptr ds:[bx], 1
mov       word ptr ds:[_old_screen_viewport_height], ax
pop       si
pop       dx
pop       cx
pop       bx
ret       

ENDP

PROC    AM_clearMarks_ NEAR
PUBLIC  AM_clearMarks_

push      cx
push      di
mov       cx, AM_NUMMARKPOINTS * SIZE MPOINT_T  ; todo div 2 etc
mov       al, -1
mov       di, OFFSET _markpoints
push      di
push      ds
pop       es
mov       ah, al
shr       cx, 1
rep stosw
adc       cx, cx
rep stosb
pop       di
mov       byte ptr ds:[_markpointnum], 0
pop       di
pop       cx
ret       

ENDP

PROC    AM_LevelInit_ NEAR
PUBLIC  AM_LevelInit_

push      bx
push      cx
push      dx
push      di
mov       word ptr ds:[_am_scale_mtof + 0], 03333h  ; 0x10000 / 5
mov       cx, 028h 
xor       ax, ax
mov       di, OFFSET _markpoints
mov       word ptr ds:[_am_scale_mtof + 2], ax
mov       al, -1
mov       bx, 0B333h
push      di
push      ds
pop       es
mov       ah, al
shr       cx, 1
rep stosw   ; todo just call the func above.
adc       cx, cx
rep stosb 
pop       di
mov       byte ptr ds:[_markpointnum], 0
call      AM_findMinMaxBoundaries_
mov       dx, word ptr ds:[_am_min_scale_mtof]
xor       ax, ax
call      FastDiv3216u_
mov       word ptr ds:[_am_scale_mtof + 0], ax
mov       word ptr ds:[_am_scale_mtof + 2], dx
cmp       dx, word ptr ds:[_am_max_scale_mtof + 2]
jg        label_19
jne       label_20
cmp       ax, word ptr ds:[_am_max_scale_mtof + 0]
jbe       label_20
label_19:
mov       ax, word ptr ds:[_am_min_scale_mtof]
mov       word ptr ds:[_am_scale_mtof + 0], ax
xor       ax, ax
mov       word ptr ds:[_am_scale_mtof + 2], ax
label_20:
mov       ax, 1
mov       bx, word ptr ds:[_am_scale_mtof + 0]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
pop       di
pop       dx
pop       cx
pop       bx
ret       


ENDP

PROC    AM_Stop_ FAR
PUBLIC  AM_Stop_

push      bx
mov       bx, OFFSET _automapactive
mov       byte ptr ds:[bx], 0
mov       bx, OFFSET _st_gamestate
mov       byte ptr ds:[_am_stopped], 1
mov       byte ptr ds:[bx], 1
pop       bx
retf      


ENDP

PROC    AM_Start_ NEAR
PUBLIC  AM_Start_


push      bx
mov       al, byte ptr ds:[_am_stopped]
test      al, al
je        label_21
label_23:
mov       bx, OFFSET _gamemap
mov       al, byte ptr ds:[_am_lastlevel]
mov       byte ptr ds:[_am_stopped], 0
cmp       al, byte ptr ds:[bx]
jne       label_22
mov       bx, OFFSET _gameepisode
mov       al, byte ptr ds:[_am_lastepisode]
cmp       al, byte ptr ds:[bx]
jne       label_22
call      AM_initVariables_
pop       bx
retf      
label_21:
mov       bx, OFFSET _automapactive
mov       byte ptr ds:[bx], al
mov       bx, OFFSET _st_gamestate
mov       byte ptr ds:[bx], 1
jmp       label_23
label_22:
mov       bx, OFFSET _gamemap
call      AM_LevelInit_
mov       bl, byte ptr ds:[bx]
mov       byte ptr ds:[_am_lastlevel], bl
mov       bx, OFFSET _gameepisode
mov       bl, byte ptr ds:[bx]
mov       byte ptr ds:[_am_lastepisode], bl
call      AM_initVariables_
pop       bx
retf      

ENDP

PROC    AM_minOutWindowScale_ NEAR
PUBLIC  AM_minOutWindowScale_

push      bx
push      cx
push      dx
mov       ax, word ptr ds:[_am_min_scale_mtof]
mov       word ptr ds:[_am_scale_mtof + 0], ax
xor       ax, ax
mov       bx, word ptr ds:[_am_scale_mtof + 0]
mov       word ptr ds:[_am_scale_mtof + 2], ax
mov       cx, ax
mov       ax, 1
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
call      AM_activateNewScale_
pop       dx
pop       cx
pop       bx
ret       

ENDP

PROC    AM_maxOutWindowScale_ NEAR
PUBLIC  AM_maxOutWindowScale_

push      bx
push      cx
push      dx
mov       ax, 1
mov       bx, word ptr ds:[_am_max_scale_mtof + 0]
mov       cx, word ptr ds:[_am_max_scale_mtof + 2]
mov       word ptr ds:[_am_scale_mtof + 0], bx
mov       word ptr ds:[_am_scale_mtof + 2], cx
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
call      AM_activateNewScale_
pop       dx
pop       cx
pop       bx
ret       

ENDP

PROC    AM_Responder_ NEAR
PUBLIC  AM_Responder_

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 06Ah
mov       si, ax
mov       word ptr [bp - 4], dx
mov       bx, OFFSET _automapactive
mov       byte ptr [bp - 2], 0
cmp       byte ptr ds:[bx], 0
jne       label_24
mov       es, dx
cmp       byte ptr es:[si], 0
jne       label_25
cmp       word ptr es:[si + 3], 0
jne       label_25
cmp       word ptr es:[si + 1], 9
je        label_26
label_25:
mov       al, byte ptr [bp - 2]
label_114:
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
label_26:
call      AM_Start_
mov       bx, OFFSET _viewactive
mov       byte ptr [bp - 2], 1
mov       byte ptr ds:[bx], 0
jmp       label_25
label_24:
mov       es, dx
mov       al, byte ptr es:[si]
test      al, al
jne       label_27
mov       byte ptr [bp - 2], 1
mov       cx, word ptr es:[si + 3]
mov       ax, word ptr es:[si + 1]
test      cx, cx
jne       label_28
cmp       ax, AM_FOLLOWKEY
jae       label_28
test      cx, cx
jne       label_29
cmp       ax, AM_GOBIGKEY
jae       label_29
test      cx, cx
jne       label_30
cmp       ax, AM_ZOOMOUTKEY
jne       label_30
mov       word ptr ds:[_mtof_zoommul], M_ZOOMOUT
mov       word ptr ds:[_ftom_zoommul], M_ZOOMIN
label_37:
mov       es, word ptr [bp - 4]
mov       al, byte ptr es:[si + 1]
cbw      
mov       dx, ax
mov       ax, CHEATID_AUTOMAP
call      cht_CheckCheat_

jnc       label_25
mov       al, byte ptr ds:[_am_cheating]
cbw      
inc       ax
mov       bx, 3
cwd       
idiv      bx
mov       byte ptr [bp - 2], 0
mov       byte ptr ds:[_am_cheating], dl
mov       al, byte ptr [bp - 2]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
label_27:
jmp       label_31
label_29:
jmp       label_32
label_30:
jmp       label_33
label_28:
test      cx, cx
jne       label_34
cmp       ax, AM_FOLLOWKEY
ja        label_34
cmp       byte ptr ds:[_followplayer], 0
jne       label_35
mov       al, 1
label_60:
mov       word ptr ds:[_screen_oldloc + 0], MAXSHORT
mov       byte ptr ds:[_followplayer], al
test      al, al
je        label_36
mov       ax, AMSTR_FOLLOWON
mov       bx, OFFSET _player + PLAYER_T.player_message
mov       word ptr ds:[bx], ax
jmp       label_37
label_34:
test      cx, cx
jne       label_38
cmp       ax, AM_PANLEFTKEY
jae       label_38
test      cx, cx
jne       label_39
cmp       ax, AM_MARKKEY
je        label_40
label_39:
test      cx, cx
jne       label_41
cmp       ax, AM_GRIDKEY
jne       label_41
cmp       byte ptr ds:[_am_grid], 0
jne       label_170
mov       al, 1
label_61:
mov       byte ptr ds:[_am_grid], al
test      al, al
je        label_171
mov       ax, AMSTR_GRIDON
mov       bx, OFFSET _player + PLAYER_T.player_message
mov       word ptr ds:[bx], ax
jmp       label_37
label_35:
jmp       label_172
label_38:
test      cx, cx
jne       label_62
cmp       ax, AM_PANLEFTKEY
ja        label_62
cmp       byte ptr ds:[_followplayer], 0
je        label_63
mov       byte ptr [bp - 2], 0
jmp       label_37
label_36:
jmp       label_64
label_62:
test      cx, cx
jne       label_65
cmp       ax, AM_PANDOWNKEY
jne       label_65
cmp       byte ptr ds:[_followplayer], 0
je        label_66
mov       byte ptr [bp - 2], 0
jmp       label_37
label_40:
jmp       label_67
label_41:
jmp       label_42
label_170:
jmp       label_43
label_65:
test      cx, cx
jne       label_44
cmp       ax, AM_PANRIGHTKEY
jne       label_44
cmp       byte ptr ds:[_followplayer], 0
je        label_45
mov       byte ptr [bp - 2], 0
jmp       label_37
label_171:
jmp       label_46
label_44:
test      cx, cx
jne       label_42
cmp       ax, AM_PANUPKEY
jne       label_42
cmp       byte ptr ds:[_followplayer], 0
je        label_47
label_42:
mov       byte ptr [bp - 2], 0
jmp       label_37
label_63:
jmp       label_48
label_66:
jmp       label_49
label_32:
test      cx, cx
jne       label_50
cmp       ax, AM_GOBIGKEY
ja        label_50
cmp       byte ptr ds:[_am_bigstate], 0
jne       label_51
mov       al, 1
label_59:
mov       byte ptr ds:[_am_bigstate], al
test      al, al
je        label_52
mov       ax, word ptr ds:[_screen_botleft_x]
mov       word ptr ds:[_old_screen_botleft_x], ax
mov       ax, word ptr ds:[_screen_botleft_y]
mov       word ptr ds:[_old_screen_botleft_y], ax
mov       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_old_screen_viewport_width], ax
mov       ax, word ptr ds:[_screen_viewport_height]
mov       word ptr ds:[_old_screen_viewport_height], ax
call      AM_minOutWindowScale_
jmp       label_37
label_45:
jmp       label_53
label_47:
jmp       label_54
label_50:
test      cx, cx
jne       label_55
cmp       ax, AM_CLEARMARKKEY
je        label_56
label_55:
test      cx, cx
jne       label_42
cmp       ax, AM_ZOOMINKEY
jne       label_42
mov       word ptr ds:[_mtof_zoommul], M_ZOOMIN
mov       word ptr ds:[_ftom_zoommul], M_ZOOMOUT
jmp       label_37
label_51:
jmp       label_57
label_52:
jmp       label_58
label_33:
test      cx, cx
jne       label_42
cmp       ax, 9
jne       label_42
mov       bx, OFFSET _viewactive
xor       al, al
mov       byte ptr ds:[bx], 1
mov       bx, OFFSET _automapactive
mov       byte ptr ds:[_am_stopped], 1
mov       byte ptr ds:[bx], al
mov       bx, OFFSET _st_gamestate
mov       byte ptr ds:[_am_bigstate], al
mov       byte ptr ds:[bx], 1
jmp       label_37
label_53:
mov       ax, 4
mov       bx, word ptr ds:[_am_scale_ftom + 0]
mov       cx, word ptr ds:[_am_scale_ftom + 2]
call      FixedMul1632_
mov       word ptr ds:[_m_paninc + 0], ax
jmp       label_37
label_56:
mov       cx, AM_NUMMARKPOINTS * SIZE MPOINT_T ; todo div 2 etc
mov       ax, -1
mov       di, OFFSET _markpoints
mov       bx, OFFSET _player + PLAYER_T.player_message
push      di
push      ds
pop       es
mov       ah, al
shr       cx, 1
rep stosw
adc       cx, cx
rep stosb
pop       di
mov       byte ptr ds:[_markpointnum], 0
mov       word ptr ds:[bx], AMSTR_MARKSCLEARED
jmp       label_37
label_48:
mov       ax, 4
mov       bx, word ptr ds:[_am_scale_ftom + 0]
mov       cx, word ptr ds:[_am_scale_ftom + 2]
call      FixedMul1632_
mov       word ptr ds:[_m_paninc + 0], ax
neg       word ptr ds:[_m_paninc + 0]
jmp       label_37
label_54:
mov       ax, 4
mov       bx, word ptr ds:[_am_scale_ftom + 0]
mov       cx, word ptr ds:[_am_scale_ftom + 2]
call      FixedMul1632_
mov       word ptr ds:[_m_paninc + 2], ax
jmp       label_37
label_49:
mov       ax, 4
mov       bx, word ptr ds:[_am_scale_ftom + 0]
mov       cx, word ptr ds:[_am_scale_ftom + 2]
call      FixedMul1632_
mov       word ptr ds:[_m_paninc + 2], ax
neg       word ptr ds:[_m_paninc + 2]
jmp       label_37
label_57:
xor       al, al
jmp       label_59
label_58:
call      AM_restoreScaleAndLoc_
jmp       label_37
label_172:
xor       al, al
jmp       label_60
label_64:
mov       ax, AMSTR_FOLLOWOFF
mov       bx, OFFSET _player + PLAYER_T.player_message
mov       word ptr ds:[bx], ax
jmp       label_37
label_43:
xor       al, al
jmp       label_61
label_46:
mov       ax, AMSTR_GRIDOFF
mov       bx, OFFSET _player + PLAYER_T.player_message
mov       word ptr ds:[bx], ax
jmp       label_37
label_67:
lea       bx, [bp - 06Ah]
mov       ax, AMSTR_MARKEDSPOT
mov       cx, ds
lea       dx, [bp - 6]
call      getStringByIndex_
lea       bx, [bp - 06Ah]
mov       ax, OFFSET _player_message_string
push      ds
mov       cx, ds
push      dx
xor       dx, dx
mov       byte ptr [bp - 6], 0
call      combine_strings_
call      AM_addMark_
jmp       label_37
label_31:
cmp       al, 1
je        label_68
label_72:
jmp       label_25
label_68:
mov       byte ptr [bp - 2], 0
mov       ax, word ptr es:[si + 3]
mov       cx, word ptr es:[si + 1]
test      ax, ax
jne       label_69
cmp       cx, AM_PANLEFTKEY
jae       label_69
test      ax, ax
jne       label_70
cmp       cx, AM_ZOOMINKEY
je        label_71
label_70:
test      ax, ax
jne       label_72
cmp       cx, AM_ZOOMOUTKEY
jne       label_72
label_71:
mov       ax, FRAC_SCALE_UNIT
mov       word ptr ds:[_mtof_zoommul], ax
mov       word ptr ds:[_ftom_zoommul], ax
mov       al, byte ptr [bp - 2]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
label_69:
test      ax, ax
jne       label_73
cmp       cx, AM_PANLEFTKEY
ja        label_73
mov       al, byte ptr ds:[_followplayer]
test      al, al
jne       label_72
xor       ah, ah
mov       word ptr ds:[_m_paninc + 0], ax
mov       al, byte ptr [bp - 2]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
label_73:
test      ax, ax
jne       label_74
cmp       cx, AM_PANDOWNKEY
jne       label_74
mov       al, byte ptr ds:[_followplayer]
test      al, al
jne       label_72
xor       ah, ah
mov       word ptr ds:[_m_paninc + 2], ax
mov       al, byte ptr [bp - 2]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
label_74:
test      ax, ax
jne       label_75
cmp       cx, AM_PANRIGHTKEY
jne       label_75
mov       al, byte ptr ds:[_followplayer]
test      al, al
je        label_76
label_77:
jmp       label_25
label_76:
xor       ah, ah
mov       word ptr ds:[_m_paninc + 0], ax
mov       al, byte ptr [bp - 2]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
label_75:
test      ax, ax
jne       label_77
cmp       cx, AM_PANUPKEY
jne       label_77
mov       al, byte ptr ds:[_followplayer]
test      al, al
jne       label_77
xor       ah, ah
mov       word ptr ds:[_m_paninc + 2], ax
mov       al, byte ptr [bp - 2]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       


ENDP

PROC    AM_changeWindowScale_ NEAR
PUBLIC  AM_changeWindowScale_

push      bx
push      cx
push      dx
mov       bx, word ptr ds:[_am_scale_mtof + 0]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
mov       ax, word ptr ds:[_mtof_zoommul]
call      FixedMul1632_
mov       cl, 4
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0FFF0h  ; todo clean up shift...
xor       dx, ax
mov       word ptr ds:[_am_scale_mtof + 0], ax
mov       bx, ax
mov       cx, dx
mov       ax, 1
mov       word ptr ds:[_am_scale_mtof + 2], dx
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
mov       ax, word ptr ds:[_am_min_scale_mtof]
cmp       word ptr ds:[_am_scale_mtof + 2], 0
jl        label_78
jne       label_79
cmp       ax, word ptr ds:[_am_scale_mtof + 0]
ja        label_78
label_79:
mov       ax, word ptr ds:[_am_scale_mtof + 2]
mov       dx, word ptr ds:[_am_scale_mtof + 0]
cmp       ax, word ptr ds:[_am_max_scale_mtof + 2]
jg        label_80
jne       label_81
cmp       dx, word ptr ds:[_am_max_scale_mtof + 0]
jbe       label_81
label_80:
call      AM_maxOutWindowScale_
exit_am_changewindowscale:
pop       dx
pop       cx
pop       bx
ret       
label_78:
call      AM_minOutWindowScale_
jmp       exit_am_changewindowscale
label_81:
call      AM_activateNewScale_
pop       dx
pop       cx
pop       bx
ret       


ENDP

PROC    AM_doFollowPlayer_ NEAR
PUBLIC  AM_doFollowPlayer_


push      bx
push      dx
push      si
mov       bx, OFFSET _playerMobj_pos
les       si, dword ptr ds:[bx]
mov       ax, word ptr ds:[_screen_oldloc + 0]
cmp       ax, word ptr es:[si + 2]
jne       label_82
mov       ax, word ptr ds:[_screen_oldloc + 2]
cmp       ax, word ptr es:[si + 6]
jne       label_82
pop       si
pop       dx
pop       bx
ret       
label_82:
mov       bx, OFFSET _playerMobj_pos
les       si, dword ptr ds:[bx]
mov       ax, word ptr ds:[_screen_viewport_width]
mov       bx, word ptr es:[si + 2]
sar       ax, 1
sub       bx, ax
mov       ax, bx
mov       word ptr ds:[_screen_botleft_x], bx
mov       bx, OFFSET _playerMobj_pos
les       si, dword ptr ds:[bx]
mov       dx, word ptr ds:[_screen_viewport_height]
mov       bx, word ptr es:[si + 6]
sar       dx, 1
sub       bx, dx
mov       word ptr ds:[_screen_botleft_y], bx
add       bx, word ptr ds:[_screen_viewport_height]
add       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_screen_topright_y], bx
mov       bx, OFFSET _playerMobj_pos
mov       word ptr ds:[_screen_topright_x], ax
les       si, dword ptr ds:[bx]
mov       ax, word ptr es:[si + 2]
mov       word ptr ds:[_screen_oldloc + 0], ax
mov       ax, word ptr es:[si + 6]
mov       word ptr ds:[_screen_oldloc + 2], ax
pop       si
pop       dx
pop       bx
ret       

ENDP

PROC    AM_Ticker_ NEAR
PUBLIC  AM_Ticker_

cmp       byte ptr ds:[_followplayer], 0
jne       label_83
label_86:
cmp       word ptr ds:[_ftom_zoommul], FRAC_SCALE_UNIT
je        label_84
call      AM_changeWindowScale_
label_84:
cmp       word ptr ds:[_m_paninc + 0], 0
jne       label_85
cmp       word ptr ds:[_m_paninc + 2], 0
jne       label_85
ret      
label_83:
call      AM_doFollowPlayer_
jmp       label_86
label_85:
call      AM_changeWindowLoc_
ret      

ENDP

PROC    DOOUTCODE_ NEAR
PUBLIC  DOOUTCODE_

xor       ax, ax
test      bx, bx
jl        label_87
cmp       bx, AUTOMAP_SCREENHEIGHT
jl        label_88
mov       ax, 4
label_88:
test      dx, dx
jl        label_89
cmp       dx, AUTOMAP_SCREENWIDTH
jl        label_92
or        al, 2
label_92:
ret       
label_87:
mov       ax, 8
jmp       label_88
label_89:
or        al, 1
ret       


ENDP

PROC    AM_clipMline_ NEAR
PUBLIC  AM_clipMline_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 6
push      ax
xor       ax, ax
mov       bx, word ptr [bp - 8]
mov       word ptr [bp - 2], ax
mov       word ptr [bp - 4], ax
mov       ax, word ptr ds:[bx + 2]
cmp       ax, word ptr ds:[_screen_topright_y]
jle       label_90
mov       word ptr [bp - 2], 8
label_97:
mov       bx, word ptr [bp - 8]
mov       ax, word ptr ds:[bx + 6]
cmp       ax, word ptr ds:[_screen_topright_y]
jle       label_91
mov       word ptr [bp - 4], 8
label_98:
mov       ax, word ptr [bp - 2]
test      word ptr [bp - 4], ax
jne       label_93
mov       bx, word ptr [bp - 8]
mov       ax, word ptr ds:[bx]
cmp       ax, word ptr ds:[_screen_botleft_x]
jge       label_94
or        byte ptr [bp - 2], 1
label_99:
mov       bx, word ptr [bp - 8]
mov       ax, word ptr ds:[bx + 4]
cmp       ax, word ptr ds:[_screen_botleft_x]
jge       label_95
or        byte ptr [bp - 4], 1
label_100:
mov       ax, word ptr [bp - 2]
test      word ptr [bp - 4], ax
je        label_96
label_93:
xor       al, al
exit_am_clipline:
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
label_90:
cmp       ax, word ptr ds:[_screen_botleft_y]
jge       label_97
mov       word ptr [bp - 2], 4
jmp       label_97
label_91:
cmp       ax, word ptr ds:[_screen_botleft_y]
jge       label_98
mov       word ptr [bp - 4], 4
jmp       label_98
label_94:
cmp       ax, word ptr ds:[_screen_topright_x]
jle       label_99
or        byte ptr [bp - 2], 2
jmp       label_99
label_95:
cmp       ax, word ptr ds:[_screen_topright_x]
jle       label_100
or        byte ptr [bp - 4], 2
jmp       label_100
label_96:
mov       bx, word ptr [bp - 8]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
mov       ax, word ptr ds:[bx]
mov       bx, word ptr ds:[_am_scale_mtof + 0]
sub       ax, word ptr ds:[_screen_botleft_x]
call      FixedMul1632_
mov       bx, word ptr [bp - 8]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
mov       word ptr ds:[_am_fl + 0], ax
mov       ax, word ptr ds:[bx + 2]
mov       bx, word ptr ds:[_am_scale_mtof + 0]
sub       ax, word ptr ds:[_screen_botleft_y]
call      FixedMul1632_
mov       dx, AUTOMAP_SCREENHEIGHT
mov       bx, word ptr [bp - 8]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
sub       dx, ax
mov       ax, word ptr ds:[bx + 4]
mov       bx, word ptr ds:[_am_scale_mtof + 0]
sub       ax, word ptr ds:[_screen_botleft_x]
mov       word ptr ds:[_am_fl + 2], dx
call      FixedMul1632_
mov       bx, word ptr [bp - 8]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
mov       word ptr ds:[_am_fl + 4], ax
mov       ax, word ptr ds:[bx + 6]
mov       bx, word ptr ds:[_am_scale_mtof + 0]
sub       ax, word ptr ds:[_screen_botleft_y]
call      FixedMul1632_
mov       dx, AUTOMAP_SCREENHEIGHT
mov       bx, word ptr ds:[_am_fl + 2]
sub       dx, ax
mov       ax, word ptr [bp - 2]
mov       word ptr ds:[_am_fl + 6], dx
mov       dx, word ptr ds:[_am_fl + 0]
call      DOOUTCODE_
mov       bx, word ptr ds:[_am_fl + 6]
mov       dx, word ptr ds:[_am_fl + 4]
mov       cx, ax
mov       word ptr [bp - 2], ax
mov       ax, word ptr [bp - 4]
call      DOOUTCODE_
mov       word ptr [bp - 4], ax
test      cx, ax
je        label_101
jmp       label_93
label_101:
mov       ax, word ptr [bp - 2]
or        ax, word ptr [bp - 4]
je        label_102
mov       ax, word ptr [bp - 2]
test      ax, ax
je        label_103
mov       cx, ax
label_106:
mov       ax, word ptr ds:[_am_fl + 2]
mov       bx, word ptr ds:[_am_fl + 4]
mov       word ptr [bp - 6], ax
mov       ax, word ptr ds:[_am_fl + 6]
sub       bx, word ptr ds:[_am_fl + 0]
sub       word ptr [bp - 6], ax
test      cl, 8
je        label_104
mov       ax, bx
imul      word ptr ds:[_am_fl + 2]
cwd       
idiv      word ptr [bp - 6]
mov       di, word ptr ds:[_am_fl + 0]
xor       si, si
label_109:
add       di, ax
label_111:
mov       ax, word ptr [bp - 2]
cmp       cx, ax
jne       label_105
mov       word ptr ds:[_am_fl + 0], di
mov       bx, si
mov       dx, di
mov       word ptr ds:[_am_fl + 2], si
call      DOOUTCODE_
mov       word ptr [bp - 2], ax
label_173:
mov       ax, word ptr [bp - 2]
test      word ptr [bp - 4], ax
je        label_101
xor       al, al
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
label_103:
mov       cx, word ptr [bp - 4]
jmp       label_106
label_102:
jmp       label_107
label_104:
test      cl, 4
je        label_108
mov       dx, word ptr ds:[_am_fl + 2]
mov       ax, bx
sub       dx, AUTOMAP_SCREENHEIGHT
imul      dx
cwd       
idiv      word ptr [bp - 6]
mov       di, word ptr ds:[_am_fl + 0]
mov       si, AUTOMAP_SCREENHEIGHT - 1
jmp       label_109
label_108:
sub       ax, word ptr ds:[_am_fl + 2]
test      cl, 2
je        label_110
mov       dx, AUTOMAP_SCREENWIDTH - 1
sub       dx, word ptr ds:[_am_fl + 0]
imul      dx
cwd       
idiv      bx
mov       si, word ptr ds:[_am_fl + 2]
mov       di, AUTOMAP_SCREENWIDTH - 1
add       si, ax
jmp       label_111
label_105:
jmp       label_112
label_110:
test      cl, 1
je        label_111
mov       dx, word ptr ds:[_am_fl + 0]
neg       dx
imul      dx
cwd       
idiv      bx
mov       si, word ptr ds:[_am_fl + 2]
xor       di, di
add       si, ax
jmp       label_111
label_112:
mov       ax, word ptr [bp - 4]
mov       word ptr ds:[_am_fl + 4], di
mov       bx, si
mov       dx, di
mov       word ptr ds:[_am_fl + 6], si
call      DOOUTCODE_
mov       word ptr [bp - 4], ax
jmp       label_173
label_107:
mov       al, 1
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       


ENDP

PROC    AM_drawMline_ NEAR
PUBLIC  AM_drawMline_

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 8
mov       byte ptr [bp - 2], dl
call      AM_clipMline_
test      al, al
jne       label_113
label_123:
jmp       label_114
label_113:
mov       ax, word ptr ds:[_am_fl + 4]
sub       ax, word ptr ds:[_am_fl + 0]
mov       dx, ax
test      ax, ax
jl        label_118
label_126:
mov       di, ax
add       di, ax
test      dx, dx
jl        label_119
mov       ax, 1
label_127:
mov       word ptr [bp - 8], ax
mov       ax, word ptr ds:[_am_fl + 6]
sub       ax, word ptr ds:[_am_fl + 2]
mov       dx, ax
test      ax, ax
jl        label_120
label_128:
add       ax, ax
mov       word ptr [bp - 4], ax
test      dx, dx
jl        label_121
mov       ax, 1
label_129:
mov       dx, word ptr ds:[_am_fl + 0]
mov       word ptr [bp - 6], ax
mov       ax, word ptr ds:[_am_fl + 2]
cmp       di, word ptr [bp - 4]
jle       label_122
mov       bx, di
mov       si, word ptr [bp - 4]
sar       bx, 1
sub       si, bx
mov       bx, si
label_125:
imul      si, ax, AUTOMAP_SCREENWIDTH
mov       cx, SCREEN0_SEGMENT
mov       es, cx
add       si, dx
mov       cl, byte ptr [bp - 2]
mov       byte ptr es:[si], cl
cmp       dx, word ptr ds:[_am_fl + 4]
je        label_123
test      bx, bx
jl        label_124
add       ax, word ptr [bp - 6]
sub       bx, di
label_124:
add       dx, word ptr [bp - 8]
add       bx, word ptr [bp - 4]
jmp       label_125
label_118:
neg       ax
jmp       label_126
label_119:
mov       ax, -1
jmp       label_127
label_120:
neg       ax
jmp       label_128
label_121:
mov       ax, -1
jmp       label_129
label_122:
mov       bx, word ptr [bp - 4]
mov       si, di
sar       bx, 1
sub       si, bx
mov       bx, si
label_117:
imul      si, ax, AUTOMAP_SCREENWIDTH
mov       cx, SCREEN0_SEGMENT
mov       es, cx
add       si, dx
mov       cl, byte ptr [bp - 2]
mov       byte ptr es:[si], cl
cmp       ax, word ptr ds:[_am_fl + 6]
jne       label_115
jmp       label_114
label_115:
test      bx, bx
jl        label_116
add       dx, word ptr [bp - 8]
sub       bx, word ptr [bp - 4]
label_116:
add       ax, word ptr [bp - 6]
add       bx, di
jmp       label_117


ENDP

PROC    AM_drawGrid_ NEAR
PUBLIC  AM_drawGrid_

push      bx
push      cx
push      dx
mov       ax, word ptr ds:[_screen_botleft_x]
mov       bx, OFFSET _bmaporgx
mov       cx, ax
mov       dx, ax
sub       cx, word ptr ds:[bx]
sub       dx, word ptr ds:[bx]
sar       cx, 15 ; todo no
xor       cx, dx
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
sub       cx, bx
mov       bx, OFFSET _bmaporgx
mov       dx, ax
sub       dx, word ptr ds:[bx]
xor       ch, ch
mov       bx, dx
and       cl, 07Fh
sar       bx, 15 ; todo no
xor       cx, bx
mov       bx, OFFSET _bmaporgx
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
sub       cx, bx
je        label_132
mov       bx, OFFSET _bmaporgx
mov       cx, ax
mov       dx, ax
sub       cx, word ptr ds:[bx]
sub       dx, word ptr ds:[bx]
sar       cx, 15 ; todo no
xor       cx, dx
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
sub       cx, bx
mov       bx, OFFSET _bmaporgx
mov       dx, ax
sub       dx, word ptr ds:[bx]
xor       ch, ch
mov       bx, dx
and       cl, 07Fh
sar       bx, 15 ; todo no
xor       cx, bx
mov       bx, OFFSET _bmaporgx
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
sub       cx, bx
mov       bx, 080h
sub       bx, cx
add       ax, bx
label_132:
mov       bx, word ptr ds:[_screen_botleft_y]
mov       cx, word ptr ds:[_screen_botleft_x]
mov       word ptr ds:[_am_ml + 2], bx
add       bx, word ptr ds:[_screen_viewport_height]
add       cx, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_am_ml + 6], bx
mov       bx, ax
cmp       ax, cx
jge       label_131
label_130:
mov       dx, GRIDCOLORS
mov       ax, OFFSET _am_ml + 0
mov       word ptr ds:[_am_ml + 0], bx
mov       word ptr ds:[_am_ml + 4], bx
add       bx, 080h
call      AM_drawMline_
cmp       bx, cx
jl        label_130
label_131:
mov       ax, word ptr ds:[_screen_botleft_y]
mov       bx, OFFSET _bmaporgy
mov       cx, ax
mov       dx, ax
sub       cx, word ptr ds:[bx]
sub       dx, word ptr ds:[bx]
sar       cx, 15 ; todo no
xor       cx, dx
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
sub       cx, bx
mov       bx, OFFSET _bmaporgy
mov       dx, ax
sub       dx, word ptr ds:[bx]
xor       ch, ch
mov       bx, dx
and       cl, 07Fh
sar       bx, 15 ; todo no
xor       cx, bx
mov       bx, OFFSET _bmaporgy
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
sub       cx, bx
je        label_133
mov       bx, OFFSET _bmaporgy
mov       cx, ax
mov       dx, ax
sub       cx, word ptr ds:[bx]
sub       dx, word ptr ds:[bx]
sar       cx, 15 ; todo no
xor       cx, dx
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
sub       cx, bx
mov       bx, OFFSET _bmaporgy
mov       dx, ax
sub       dx, word ptr ds:[bx]
xor       ch, ch
mov       bx, dx
and       cl, 07Fh
sar       bx, 15 ; todo no
xor       cx, bx
mov       bx, OFFSET _bmaporgy
mov       dx, ax
sub       dx, word ptr ds:[bx]
mov       bx, dx
sar       bx, 15 ; todo no
mov       dx, 080h
sub       cx, bx
sub       dx, cx
add       ax, dx
label_133:
mov       bx, word ptr ds:[_screen_botleft_x]
mov       cx, word ptr ds:[_screen_botleft_y]
mov       word ptr ds:[_am_ml + 0], bx
add       bx, word ptr ds:[_screen_viewport_width]
add       cx, word ptr ds:[_screen_viewport_height]
mov       word ptr ds:[_am_ml + 4], bx
mov       bx, ax
cmp       ax, cx
jge       label_134
label_135:
mov       dx, GRIDCOLORS
mov       ax, OFFSET _am_ml + 0
mov       word ptr ds:[_am_ml + 2], bx
mov       word ptr ds:[_am_ml + 6], bx
add       bx, 080h
call      AM_drawMline_
cmp       bx, cx
jl        label_135
label_134:
pop       dx
pop       cx
pop       bx
ret       


ENDP

PROC    AM_drawWalls_ NEAR
PUBLIC  AM_drawWalls_

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 0Eh
mov       word ptr [bp - 4], 0
xor       bx, bx
label_139:
mov       si, OFFSET _numlines
mov       ax, word ptr [bp - 4]
cmp       ax, word ptr ds:[si]
jb        label_136
jmp       exit_am_clipline   ;shared exit. 
label_136:
mov       ax, LINES_PHYSICS_SEGMENT; _LINES_PHYSICS_SEGMENT_PTR
mov       si, bx
mov       es, ax
mov       cl, byte ptr [bp - 4]
mov       ax, word ptr es:[si]
and       cl, 7
mov       word ptr [bp - 0Eh], ax
lea       si, [bx + 2]
mov       ax, SEENLINES_6800_SEGMENT
mov       di, word ptr es:[si]
mov       si, word ptr [bp - 4]
mov       es, ax
mov       al, 1
shr       si, 3
shl       al, cl
mov       ah, byte ptr es:[si]
and       ah, al
mov       byte ptr [bp - 2], ah
mov       ax, LINEFLAGSLIST_SEGMENT ; todo _LINEFLAGSLIST_SEGMENT_PTR
mov       si, word ptr [bp - 4]
mov       es, ax
mov       dx, LINES_PHYSICS_SEGMENT
mov       al, byte ptr es:[si]
mov       es, dx
lea       si, [bx + 0Ch]
mov       dx, word ptr es:[si]
lea       si, [bx + 0Ah]
xor       ah, ah
mov       cx, word ptr es:[si]
lea       si, [bx + 0Fh]
mov       word ptr [bp - 8], cx
mov       cl, byte ptr es:[si]
mov       byte ptr [bp - 0Bh], ah
mov       byte ptr [bp - 0Ch], cl
mov       cx, word ptr [bp - 0Ch]
mov       word ptr [bp - 0Ah], cx
mov       cx, word ptr [bp - 0Eh]
mov       si, VERTEXES_SEGMENT
shl       cx, 2
mov       es, si
mov       si, cx
mov       si, word ptr es:[si]
mov       word ptr ds:[_am_l + 0], si
mov       si, cx
mov       cx, word ptr es:[si + 2]
and       di, VERTEX_OFFSET_MASK
mov       word ptr ds:[_am_l + 2], cx
mov       cx, di
add       si, 2
shl       cx, 2
mov       si, cx
mov       si, word ptr es:[si]
mov       word ptr ds:[_am_l + 4], si
mov       si, cx
mov       word ptr [bp - 6], ax
mov       cx, word ptr es:[si + 2]
add       si, 2
mov       word ptr ds:[_am_l + 6], cx
cmp       byte ptr ds:[_am_cheating], 0
je        label_137
label_140:
test      byte ptr [bp - 6], 080h
je        label_138
cmp       byte ptr ds:[_am_cheating], 0
jne       label_138
label_141:
inc       word ptr [bp - 4]
add       bx, 010h
jmp       label_139
label_137:
cmp       byte ptr [bp - 2], 0
jne       label_140
mov       si, OFFSET _player + PLAYER_T.player_messagestring ; 6f6? todo dummied? whats this
cmp       word ptr ds:[si], 0
je        label_141
test      al, 080h
jne       label_141
mov       dx, AM_CLEARMARKKEY
mov       ax, OFFSET _am_l + 0
call      AM_drawMline_
jmp       label_141
label_138:
cmp       dx, -1
je        label_142
mov       ax, SECTORS_SEGMENT
mov       di, dx
mov       si, word ptr [bp - 8]
shl       di, 4
mov       es, ax
shl       si, 4
mov       ax, word ptr es:[di]
cmp       ax, word ptr es:[si]
je        label_143
mov       al, 1
label_151:
mov       di, word ptr [bp - 8]
mov       cl, al
mov       si, dx
mov       ax, SECTORS_SEGMENT
shl       si, 4
shl       di, 4
mov       es, ax
add       di, 2
mov       ax, word ptr es:[si + 2]
add       si, 2
cmp       ax, word ptr es:[di]
je        label_144
mov       al, 1
label_145:
cmp       word ptr [bp - 0Ah], 39  ; teleporters
je        label_149
test      byte ptr [bp - 6], ML_SECRET
je        label_150
cmp       byte ptr ds:[_am_cheating], 0
label_142:
mov       dx, WALLCOLORS
mov       ax, OFFSET _am_l + 0
call      AM_drawMline_
inc       word ptr [bp - 4]
add       bx, 010h
jmp       label_139
label_143:
xor       al, al
jmp       label_151
label_144:
xor       al, al
jmp       label_145
label_149:
mov       dx, WALLCOLORS + WALLRANGE / 2
mov       ax, OFFSET _am_l + 0
call      AM_drawMline_
inc       word ptr [bp - 4]
add       bx, 010h
jmp       label_139
label_150:
test      cl, cl
jne       label_146
test      al, al
jne       label_147
cmp       byte ptr ds:[_am_cheating], 0
jne       label_148
jmp       label_141
label_148:
mov       dx, TSWALLCOLORS
mov       ax, OFFSET _am_l + 0
call      AM_drawMline_
inc       word ptr [bp - 4]
add       bx, 010h
jmp       label_139
label_146:
mov       dx, FDWALLCOLORS
mov       ax, OFFSET _am_l + 0
call      AM_drawMline_
inc       word ptr [bp - 4]
add       bx, 010h
jmp       label_139
label_147:
mov       dx, CDWALLCOLORS
mov       ax, OFFSET _am_l + 0
call      AM_drawMline_
inc       word ptr [bp - 4]
add       bx, 010h
jmp       label_139


ENDP

PROC    AM_rotate_ NEAR
PUBLIC  AM_rotate_

push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 6
mov       si, ax
mov       di, dx
mov       cx, bx
mov       ax, FINECOSINE_SEGMENT
mov       dx, cx
mov       bx, word ptr ds:[si]
call      FastMulTrig16_
mov       word ptr [bp - 4], ax
mov       word ptr [bp - 2], dx
mov       bx, word ptr ds:[di]
mov       ax, FINESINE_SEGMENT
mov       dx, cx
call      FastMulTrig16_
mov       bx, word ptr [bp - 4]
sub       bx, ax
mov       ax, word ptr [bp - 2]
sbb       ax, dx
mov       bx, word ptr ds:[si]
mov       word ptr [bp - 6], ax
mov       dx, cx
mov       ax, FINESINE_SEGMENT
call      FastMulTrig16_
mov       word ptr [bp - 4], ax
mov       word ptr [bp - 2], dx
mov       bx, word ptr ds:[di]
mov       ax, FINECOSINE_SEGMENT
mov       dx, cx
call      FastMulTrig16_
mov       bx, word ptr [bp - 4]
add       bx, ax
adc       dx, word ptr [bp - 2]
mov       ax, word ptr [bp - 6]
mov       word ptr ds:[di], dx
mov       word ptr ds:[si], ax
LEAVE_MACRO     
pop       di
pop       si
pop       cx
ret       

ENDP

PROC    AM_drawLineCharacter_ NEAR
PUBLIC  AM_drawLineCharacter_

push      si
push      di
push      bp
mov       bp, sp
push      dx
push      bx
xor       di, di
test      dx, dx
ja        label_152
jmp       exit_am_drawlinecharacter
label_152:
mov       si, ax
label_153:
mov       ax, word ptr ds:[si]
mov       word ptr ds:[_am_lc + 0], ax
mov       ax, word ptr ds:[si + 2]
mov       word ptr ds:[_am_lc + 2], ax
cmp       word ptr [bp - 4], 0
je        label_158
jmp       label_157
label_158:
test      cx, cx
je        label_156
mov       dx, OFFSET _am_lc + 2
mov       ax, OFFSET _am_lc + 0
mov       bx, cx
call      AM_rotate_
label_156:
mov       ax, word ptr [bp + 0Ah]
sar       word ptr ds:[_am_lc + 0], 4
sar       word ptr ds:[_am_lc + 2], 4
add       word ptr ds:[_am_lc + 0], ax
mov       ax, word ptr [bp + 0Ch]
add       word ptr ds:[_am_lc + 2], ax
mov       ax, word ptr ds:[si + 4]
mov       word ptr ds:[_am_lc + 4], ax
mov       ax, word ptr ds:[si + 6]
mov       word ptr ds:[_am_lc + 6], ax
cmp       word ptr [bp - 4], 0
je        label_155
shl       word ptr ds:[_am_lc + 4], 4
shl       word ptr ds:[_am_lc + 6], 4
label_155:
test      cx, cx
je        label_154
mov       dx, OFFSET _am_lc + 6
mov       ax, OFFSET _am_lc + 4
mov       bx, cx
call      AM_rotate_
label_154:
mov       ax, word ptr [bp + 0Ah]
sar       word ptr ds:[_am_lc + 4], 4
sar       word ptr ds:[_am_lc + 6], 4
add       word ptr ds:[_am_lc + 4], ax
mov       ax, word ptr [bp + 0Ch]
add       word ptr ds:[_am_lc + 6], ax
mov       al, byte ptr [bp + 8]
xor       ah, ah
add       si, 8
mov       dx, ax
mov       ax, OFFSET _am_lc + 0
inc       di
call      AM_drawMline_
cmp       di, word ptr [bp - 2]
jae       exit_am_drawlinecharacter
jmp       label_153
exit_am_drawlinecharacter:
LEAVE_MACRO     
pop       di
pop       si
ret       6
label_157:
shl       word ptr ds:[_am_lc + 0], 4
shl       word ptr ds:[_am_lc + 2], 4
jmp       label_158


ENDP

PROC    AM_drawPlayers_ NEAR
PUBLIC  AM_drawPlayers_

push      bx
push      cx
push      dx
push      si
cmp       byte ptr ds:[_am_cheating], 0
je        label_159
mov       bx, OFFSET _playerMobj_pos
mov       dx, 010h
les       si, dword ptr ds:[bx]
mov       ax, OFFSET _cheat_player_arrow
label_174:
push      word ptr es:[si + 6]
mov       cx, word ptr es:[si + 010h]
push      word ptr es:[si + 2]
xor       bx, bx
push      COLOR_WHITE
shr       cx, 3
call      AM_drawLineCharacter_
pop       si
pop       dx
pop       cx
pop       bx
ret       
label_159:
mov       bx, OFFSET _playerMobj_pos
mov       dx, 7
les       si, dword ptr ds:[bx]
mov       ax, OFFSET _player_arrow
jmp       label_174


ENDP

PROC    AM_drawThings_ NEAR
PUBLIC  AM_drawThings_

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4
mov       word ptr [bp - 2], 0
xor       di, di
label_162:
mov       si, OFFSET _numsectors
mov       ax, word ptr [bp - 2]
cmp       ax, word ptr ds:[si]
jb        label_160
jmp       exit_am_clipline ; shared exit
label_160:
mov       ax, SECTORS_SEGMENT
lea       si, [di + 8]
mov       es, ax
mov       ax, word ptr es:[si]
test      ax, ax
je        label_161
label_163:
imul      si, ax, SIZEOF_MOBJ_POS_T
mov       word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
mov       bx, 010h
mov       es, word ptr [bp - 4]
mov       dx, 3
push      word ptr es:[si + 6]
mov       ax, OFFSET _thintriangle_guy
push      word ptr es:[si + 2]
mov       cx, word ptr es:[si + 010h]
push      THINGCOLORS
shr       cx, 3
call      AM_drawLineCharacter_
mov       es, word ptr [bp - 4]
mov       ax, word ptr es:[si + 0Ch]
test      ax, ax
jne       label_163
label_161:
inc       word ptr [bp - 2]
add       di, 010h
jmp       label_162


ENDP

PROC    AM_drawMarks_ NEAR
PUBLIC  AM_drawMarks_

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4
mov       byte ptr [bp - 2], 0
cld       
label_165:
mov       al, byte ptr [bp - 2]
cbw      
mov       di, ax
shl       di, 2
mov       word ptr [bp - 4], ax
mov       ax, word ptr ds:[di + _markpoints]
cmp       ax, -1
jne       label_164
label_166:
inc       byte ptr [bp - 2]
cmp       byte ptr [bp - 2], AM_NUMMARKPOINTS
jl        label_165
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
label_164:
mov       bx, word ptr ds:[_am_scale_mtof + 0]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
sub       ax, word ptr ds:[_screen_botleft_x]
call      FixedMul1632_
mov       bx, word ptr ds:[_am_scale_mtof + 0]
mov       si, ax
mov       ax, word ptr ds:[di + _markpoints + 2]
mov       cx, word ptr ds:[_am_scale_mtof + 2]
sub       ax, word ptr ds:[_screen_botleft_y]
call      FixedMul1632_
mov       dx, AUTOMAP_SCREENHEIGHT
sub       dx, ax
test      si, si
jl        label_166
cmp       si, (AUTOMAP_SCREENWIDTH - 5)
jg        label_166
test      dx, dx
jl        label_166
cmp       dx, (AUTOMAP_SCREENHEIGHT - 6)
jg        label_166
mov       ax, AMMNUMPATCHBYTES_SEGMENT
mov       bx, word ptr [bp - 4]
mov       es, ax
add       bx, bx
push      es
mov       ax, word ptr es:[bx + AMMNUMPATCHOFFSETS_FAR_OFFSET]        ; todo near
add       bx, AMMNUMPATCHOFFSETS_FAR_OFFSET
push      ax
xor       bx, bx
mov       ax, si
call      V_DrawPatch_
jmp       label_166


ENDP


PROC    AM_drawCrosshair_ NEAR
PUBLIC  AM_drawCrosshair_

;    screen0[(automap_screenwidth*(automap_screenheight+1))/2] = XHAIRCOLORS; // single point for now
; todo should be 8000:69A0 ?

push      bx
mov       ax, SCREEN0_SEGMENT
mov       bx, (AUTOMAP_SCREENWIDTH*(AUTOMAP_SCREENHEIGHT+1))/2 ; 69A0h
mov       es, ax
mov       byte ptr es:[bx], XHAIRCOLORS
pop       bx
ret       


ENDP

PROC    AM_Drawer_ NEAR
PUBLIC  AM_Drawer_

push      bx
push      cx
push      dx
push      di
mov       cx, AUTOMAP_SCREENWIDTH*AUTOMAP_SCREENHEIGHT; 0D200h
mov       dx, SCREEN0_SEGMENT
xor       al, al
xor       di, di
mov       es, dx
push      di
mov       ah, al
shr       cx, 1
rep stosw 
adc       cx, cx
rep stosb 
pop       di
cmp       byte ptr ds:[_am_grid], 0
je        label_167
call      AM_drawGrid_
label_167:
call      AM_drawWalls_
call      AM_drawPlayers_
cmp       byte ptr ds:[_am_cheating], 2
je        label_168
label_169:
; todo inlined funcs 
mov       dx, 07FFFh
mov       bx, 0E9A0h
mov       es, dx
mov       cx, AUTOMAP_SCREENHEIGHT
mov       byte ptr es:[bx], XHAIRCOLORS
call      AM_drawMarks_
xor       dx, dx
mov       bx, AUTOMAP_SCREENWIDTH
xor       ax, ax
call      V_MarkRect_
pop       di
pop       dx
pop       cx
pop       bx
ret      
label_168:
call      AM_drawThings_
jmp       label_169


ENDP

@

PROC    AM_MAP_ENDMARKER_ NEAR
PUBLIC  AM_MAP_ENDMARKER_
ENDP


END