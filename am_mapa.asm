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

SCREEN_PAN_INC = 4

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

EXTRN _screen_oldloc:MPOINT_T
EXTRN _screen_oldloc:MPOINT_T
EXTRN _old_screen_botleft_x:WORD
EXTRN _old_screen_botleft_y:WORD

EXTRN _followplayer:BYTE
EXTRN _am_cheating:BYTE
EXTRN _am_grid:BYTE
EXTRN _am_bigstate:BYTE


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




PROC    CXMTOF16_ NEAR
PUBLIC  CXMTOF16_

; we can clobber cx, bx
push      dx
les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
sub       ax, word ptr ds:[_screen_botleft_x]  ; todo dont suppose this can be self modified start of frame?
call      FixedMul1632_
pop       dx
ret       

ENDP


PROC    CYMTOF16_ NEAR
PUBLIC  CYMTOF16_

; we can clobber cx, bx
push      dx
les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
sub       ax, word ptr ds:[_screen_botleft_y]  ; todo dont suppose this can be self modified start of frame?
call      FixedMul1632_
neg       ax
add       ax, AUTOMAP_SCREENHEIGHT
pop       dx
ret       

ENDP


PROC    AM_activateNewScale_ NEAR
PUBLIC  AM_activateNewScale_

push      bx
push      cx
push      dx
les       ax, dword ptr ds:[_screen_viewport_width]  ; todo put side by side, LES and get both
sar       ax, 1
add       word ptr ds:[_screen_botleft_x], ax
mov       ax, es
sar       ax, 1
add       word ptr ds:[_screen_botleft_y], ax
les       bx, dword ptr ds:[_am_scale_ftom + 0]
mov       cx, es
mov       ax, AUTOMAP_SCREENWIDTH
call      FixedMul1632_
les       bx, dword ptr ds:[_am_scale_ftom + 0]
mov       cx, es
mov       word ptr ds:[_screen_viewport_width], ax
push      ax
sar       ax, 1
sub       word ptr ds:[_screen_botleft_x], ax
pop       ax
add       ax, word ptr ds:[_screen_botleft_x]
mov       word ptr ds:[_screen_topright_x], ax

mov       ax, AUTOMAP_SCREENHEIGHT
call      FixedMul1632_
mov       word ptr ds:[_screen_viewport_height], ax
push      ax
sar       ax, 1
sub       word ptr ds:[_screen_botleft_y], ax
pop       ax
add       ax, word ptr ds:[_screen_botleft_y]
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
les       ax, dword ptr ds:[_old_screen_viewport_width]
mov       word ptr ds:[_screen_viewport_width], ax
mov       word ptr ds:[_screen_viewport_height], es
cmp       byte ptr ds:[_followplayer], 0
jne       do_follow_player
mov       ax, word ptr ds:[_old_screen_botleft_x]
mov       word ptr ds:[_screen_botleft_x], ax
mov       ax, word ptr ds:[_old_screen_botleft_y]
jmp       got_screen_xy
do_follow_player:
mov       dx, es
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



PROC    AM_findMinMaxBoundaries_ NEAR
PUBLIC  AM_findMinMaxBoundaries_

PUSHA_NO_AX_MACRO
mov       dx, MAXSHORT
mov       di, MAXSHORT
mov       bx, -MAXSHORT
mov       bp, -MAXSHORT

mov       cx, word ptr ds:[_numvertexes]


mov       ds, word ptr ds:[_VERTEXES_SEGMENT_PTR]
xor       si, si
; dx = minx
; bx = maxx
; di = miny
; bp = maxy
; si = current ptr
; cx = loop end 


loop_next_vertex:

lodsw ; get x

cmp       ax, dx
jl        update_minx

cmp       ax, bx
jle       dont_update_x_minmax
xchg      ax, bx ; update_max_x
jmp       dont_update_x_minmax

update_minx:
xchg      ax, dx ; update_min_x
dont_update_x_minmax:


lodsw ; get y

cmp       ax, di
jl        update_miny
cmp       ax, bp
jle       dont_update_y_minmax
xchg      ax, bp ; update max_y
jmp       dont_update_y_minmax
update_miny:
xchg      ax, di ; update min_y
dont_update_y_minmax:

loop      loop_next_vertex


push      ss
pop       ds

mov       word ptr ds:[_am_min_level_x], dx
mov       word ptr ds:[_am_max_level_x], bx
mov       word ptr ds:[_am_min_level_y], di
mov       word ptr ds:[_am_max_level_y], bp

;todo this in theory can be better. but whoe cares, runs once
;    max_w = am_max_level_x - am_min_level_x;
;    max_h = am_max_level_y - am_min_level_y;

;	a = FixedDiv(automap_screenwidth, max_w);
;	b = FixedDiv(automap_screenheight, max_h);


sub       bx, dx
xor       cx, cx


mov       ax, AUTOMAP_SCREENWIDTH
cwd
call      FixedDiv_
xchg      ax, si ; store a
mov       di, dx ; store a
lea       bx, [bp - di] ; max y - min y
mov       ax, AUTOMAP_SCREENHEIGHT
cwd
call      FixedDiv_

;    am_min_scale_mtof = a < b ? a : b;
; dx:ax is b

cmp       dx, di
jg        use_b
jl        use_a
cmp       ax, si
jge       use_b
use_a:
xchg       ax, si
use_b:
;	am_max_scale_mtof.w = 0x54000;// FixedDiv(automap_screenheight, 2*16);

mov       word ptr ds:[_am_min_scale_mtof], ax
mov       word ptr ds:[_am_max_scale_mtof + 0], 04000h
mov       word ptr ds:[_am_max_scale_mtof + 2], 5

POPA_NO_AX_MACRO
ret       

ENDP



PROC    AM_changeWindowLoc_ NEAR
PUBLIC  AM_changeWindowLoc_

push      bx
push      cx
push      dx
les       ax, dword ptr ds:[_m_paninc]
mov       dx, es
or        dx, ax
je        dont_cancel_follow_player

mov       byte ptr ds:[_followplayer], 0
mov       word ptr ds:[_screen_oldloc + 0], MAXSHORT
dont_cancel_follow_player:
mov       dx, word ptr ds:[_screen_botleft_x]
mov       bx, word ptr ds:[_screen_botleft_y]
add       dx, ax
mov       ax, es
add       bx, ax

mov       ax, word ptr ds:[_screen_viewport_width]
mov       cx, dx
sar       ax, 1
add       cx, ax
neg       ax
cmp       cx, word ptr ds:[_am_max_level_x]
jg        use_maxlevelx
cmp       cx, word ptr ds:[_am_min_level_x]
jge       dont_subtract_x
add       ax, word ptr ds:[_am_min_level_x]
jmp       done_subtracting_x
use_maxlevelx:
add       ax, word ptr ds:[_am_max_level_x]
jmp       done_subtracting_x
dont_subtract_x:
xchg      ax, dx  ; just use this value
done_subtracting_x:
mov       word ptr ds:[_screen_botleft_x], ax
add       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_screen_topright_x], ax

mov       ax, word ptr ds:[_screen_viewport_height]
mov       cx, bx
sar       ax, 1
add       cx, ax
neg       ax
cmp       cx, word ptr ds:[_am_max_level_y]
jle       use_minlevel7
add       ax, word ptr ds:[_am_max_level_y]
jmp       done_subtracting_y
use_minlevel7:
cmp       cx, word ptr ds:[_am_min_level_y]
jge       dont_subtract_y
add       ax, word ptr ds:[_am_min_level_y]
jmp       done_subtracting_y
dont_subtract_y:
xchg      ax, bx
done_subtracting_y:

mov       word ptr ds:[_screen_botleft_y], ax
add       ax, word ptr ds:[_screen_viewport_height]
mov       word ptr ds:[_screen_topright_y], ax
pop       dx
pop       cx
pop       bx
ret       

ENDP



FRAC_SCALE_UNIT = 01000h



PROC    AM_initVariables_ NEAR
PUBLIC  AM_initVariables_

PUSHA_NO_AX_OR_BP_MACRO
xor       ax, ax
mov       word ptr ds:[_m_paninc + MPOINT_T.mpoint_y], ax
mov       word ptr ds:[_m_paninc + MPOINT_T.mpoint_x], ax
mov       word ptr ds:[_screen_oldloc + 0], MAXSHORT
mov       byte ptr ds:[_automapactive], 1
mov       ax, FRAC_SCALE_UNIT
mov       word ptr ds:[_ftom_zoommul], ax
mov       word ptr ds:[_mtof_zoommul], ax
les       bx, dword ptr ds:[_am_scale_ftom]
mov       cx, es
mov       ax, AUTOMAP_SCREENWIDTH

call      FixedMul1632_
les       bx, dword ptr ds:[_am_scale_ftom]
mov       cx, es
mov       word ptr ds:[_screen_viewport_width], ax
sar       ax, 1
xchg      ax, si
mov       ax, AUTOMAP_SCREENHEIGHT
call      FixedMul1632_

les       bx, dword ptr ds:[_playerMobj_pos]

mov       word ptr ds:[_screen_viewport_height], ax

sar       ax, 1
neg       ax
add       ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov       word ptr ds:[_screen_botleft_y], ax

mov       ax, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
sub       ax, si
mov       word ptr ds:[_screen_botleft_x], ax

call      AM_changeWindowLoc_

; todo movsw? once in right spot in memory

call      AM_recordOldViewport_
mov       byte ptr ds:[_st_gamestate], 0
mov       byte ptr ds:[_st_firsttime], 1
POPA_NO_AX_OR_BP_MACRO
ret       

ENDP

PROC    AM_recordOldViewport_

mov       ax, word ptr ds:[_screen_botleft_x]
mov       word ptr ds:[_old_screen_botleft_x], ax
mov       ax, word ptr ds:[_screen_botleft_y]
mov       word ptr ds:[_old_screen_botleft_y], ax
mov       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_old_screen_viewport_width], ax
mov       ax, word ptr ds:[_screen_viewport_height]
mov       word ptr ds:[_old_screen_viewport_height], ax

ret

ENDP

PROC    AM_clearMarks_ NEAR
PUBLIC  AM_clearMarks_

push      cx
push      di
mov       cx, (AM_NUMMARKPOINTS * SIZE MPOINT_T) / 2 
mov       ax, -1
mov       di, OFFSET _markpoints
push      ds
pop       es
rep stosw
mov       byte ptr ds:[_markpointnum], cl ; 0
pop       di
pop       cx
ret       

ENDP

PROC    AM_LevelInit_ NEAR
PUBLIC  AM_LevelInit_

push      bx
push      cx
push      dx
mov       word ptr ds:[_am_scale_mtof + 0], 03333h  ; 0x10000 / 5

call      AM_clearMarks_
mov       bx, 0B333h
xor       cx, cx
call      AM_findMinMaxBoundaries_
mov       dx, word ptr ds:[_am_min_scale_mtof]
xor       ax, ax
call      FastDiv3216u_
mov       word ptr ds:[_am_scale_mtof + 0], ax
mov       word ptr ds:[_am_scale_mtof + 2], dx

cmp       dx, word ptr ds:[_am_max_scale_mtof + 2]
jg        set_to_minscale
jne       dont_set_to_minscale
cmp       ax, word ptr ds:[_am_max_scale_mtof + 0]
jbe       dont_set_to_minscale
set_to_minscale:
mov       ax, word ptr ds:[_am_min_scale_mtof]
mov       word ptr ds:[_am_scale_mtof + 0], ax
xor       dx, dx
mov       word ptr ds:[_am_scale_mtof + 2], dx
dont_set_to_minscale:
xchg      ax, bx
mov       cx, dx
mov       ax, 1
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
pop       dx
pop       cx
pop       bx
ret       


ENDP


; todo inline
PROC    AM_Stop_ NEAR
PUBLIC  AM_Stop_

;mov       byte ptr ds:[_automapactive], 0
mov       word ptr ds:[_am_stopped], 00001h
mov       byte ptr ds:[_st_gamestate], 1
ret      


ENDP

PROC    AM_Start_ NEAR
PUBLIC  AM_Start_

mov       al, byte ptr ds:[_am_stopped]
test      al, al
jne       dont_call_am_stop
call      AM_Stop_
dont_call_am_stop:

mov       byte ptr ds:[_am_stopped], 0
mov       al, byte ptr ds:[_am_lastlevel] ; todo make these two adjacent
cmp       al, byte ptr ds:[_gamemap]
jne       do_level_init
mov       al, byte ptr ds:[_am_lastepisode]
cmp       al, byte ptr ds:[_gameepisode]
je        just_init_variables
do_level_init:
call      AM_LevelInit_
mov       al, byte ptr ds:[_gamemap]
mov       byte ptr ds:[_am_lastlevel], al   ; todo make these all adjacent.. one read one write?
mov       al, byte ptr ds:[_gameepisode]
mov       byte ptr ds:[_am_lastepisode], al

just_init_variables:
call      AM_initVariables_
ret      




ENDP

PROC    AM_minOutWindowScale_ NEAR
PUBLIC  AM_minOutWindowScale_

push      bx
push      cx
push      dx
mov       ax, word ptr ds:[_am_min_scale_mtof]
mov       word ptr ds:[_am_scale_mtof + 0], ax
xchg      ax, bx
xor       ax, ax
mov       word ptr ds:[_am_scale_mtof + 2], ax
mov       cx, ax
inc       ax ; 1
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
les       bx, dword ptr ds:[_am_max_scale_mtof + 0]
mov       cx, es
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




; todo return carry
PROC    AM_Responder_ NEAR
PUBLIC  AM_Responder_

;boolean __near AM_Responder ( event_t __far* ev ) {

PUSHA_NO_AX_OR_BP_MACRO

xchg      ax, si
mov       es, dx

xor       ax, ax
cwd

mov       bl, byte ptr es:[si + EVENT_T.event_evtype]
mov       al, byte ptr es:[si + EVENT_T.event_data1]


; al is evdata
; dx is 0reg here

cmp       byte ptr ds:[_automapactive], dl ; 0
jne       automap_is_active
cmp       bl, dl  ; EV_KEYDOWN
jne       exit_am_responder_return_0
cmp       al, AM_STARTKEY
jne       exit_am_responder_return_0

call      AM_Start_

mov       byte ptr ds:[_viewactive], dl ; 0 

exit_am_responder_return_1:
stc
jmp       do_return
; fall thru return 1?
exit_am_responder_return_0:
clc
do_return:


POPA_NO_AX_OR_BP_MACRO
ret       

automap_is_active:

; bl is evtype
; al is data1 lo ; i guess we are just ignoring the 3 other bytes (??)
; cx is 0, inverse of cx
xor       cx, cx
mov       si, ax  ; back up in case we need it when done with keypress..


cmp       bl, EV_KEYUP
jb        do_keydown
ja        exit_am_responder_return_0
cmp       al, AM_PANRIGHTKEY
je        release_x_pan
cmp       al, AM_PANLEFTKEY
jne       not_release_x_pan

release_x_pan:

mov       word ptr ds:[_m_paninc + MPOINT_T.mpoint_x], cx
jmp       exit_am_responder_return_0


not_release_x_pan:

cmp       al, AM_PANUPKEY
je        release_y_pan
cmp       al, AM_PANDOWNKEY
jne       not_release_y_pan

release_y_pan:

mov       word ptr ds:[_m_paninc + MPOINT_T.mpoint_y], cx
jmp       exit_am_responder_return_0

not_release_y_pan:
cmp       al, AM_ZOOMINKEY
je        release_zoom
cmp       al, AM_ZOOMOUTKEY
jne       exit_am_responder_return_0

release_zoom:
mov       ax, FRAC_SCALE_UNIT
mov       word ptr ds:[_mtof_zoommul], ax
mov       word ptr ds:[_ftom_zoommul], ax

jmp       exit_am_responder_return_0

do_keydown:
inc       cx  ; rc = true (mostly) for these cases
mov       di, OFFSET _m_paninc + MPOINT_T.mpoint_x
; dx was cwded to 0 earlier. inc to 1 for a negative result..
; inc di twice to write to y

cmp       al, AM_PANRIGHTKEY
je        do_panright

not_panright:
cmp       al, AM_PANLEFTKEY
je        do_panleft
not_panleft:
inc       di
inc       di ; di points to mpoint_y
cmp       al, AM_PANUPKEY
je        do_pan_up

not_panup:
cmp       al, AM_PANDOWNKEY
jne       not_pandown

do_panup:    
do_panleft:  
dec       dx ; set negative flag for up/left
do_panright:
do_pan_up:

; if follow player is 0, dont set pan

cmp       byte ptr ds:[_followplayer], ch; 0
jne       done_with_keypress_do_false

; fixed mul by 4, or shift right 14 essentially.
; instead of sar 14

les       ax, dword ptr ds:[_am_scale_ftom]  
mov       bx, es
sal       ax, 1
rcl       bx, 1
sal       ax, 1
rcl       bx, 1
xchg      ax, bx
xor       ax, dx ; dx is -1 if this is to be a negative result
sub       ax, dx ; works for positive or negative

mov       word ptr ds:[di], ax

jmp       done_with_keypress

not_pandown:
cmp       al, AM_ZOOMOUTKEY
jne       not_zoomout_key

mov       word ptr ds:[_mtof_zoommul], M_ZOOMOUT
mov       word ptr ds:[_ftom_zoommul], M_ZOOMIN
jmp       done_with_keypress

not_zoomout_key:
cmp       al, AM_ZOOMINKEY
jne       not_zoomin_key

mov       word ptr ds:[_mtof_zoommul], M_ZOOMIN
mov       word ptr ds:[_ftom_zoommul], M_ZOOMOUT
jmp       done_with_keypress


not_zoomin_key:
cmp       al, AM_ENDKEY
jne       not_end_key

mov       byte ptr ds:[_am_bigstate], ah ; 0
mov       byte ptr ds:[_viewactive], cl ; 1
call      AM_Stop_

jmp       done_with_keypress


not_end_key:
cmp       al, AM_GOBIGKEY
jne       not_gobig_key

xor       byte ptr ds:[_am_bigstate], cl ; 1
je        turn_off_bigstate
call      AM_restoreScaleAndLoc_

jmp       done_with_keypress

turn_off_bigstate:

call      AM_recordOldViewport_
call      AM_minOutWindowScale_
jmp       done_with_keypress		

done_with_keypress_do_false:
not_clearmark_key:
dec       cx ; rc = false, cx = 0 again for default case
done_with_keypress:

mov       dx, si ; ev1
mov       al, CHEATID_AUTOMAP ; todo al or ax?
call      cht_CheckCheat_

jnc       return_cx
mov       al, byte ptr ds:[_am_cheating]
inc       ax
cmp       al, 3
jne       dont_zero_cheating
xor       ax, ax
dont_zero_cheating:
mov       byte ptr ds:[_am_cheating], al

xor       cx, cx

return_cx:
sar       cx, 1  ; carry means false.. inverse
jmp       do_return

not_gobig_key:
cmp       al, AM_FOLLOWKEY
jne       not_follow_key

mov       ax, AMSTR_FOLLOWOFF
xor       byte ptr ds:[_followplayer], cl ; 1
je        toggle_follow_player_off
dec ax  ; mov       ax, AMSTR_FOLLOWON
toggle_follow_player_off:

mov       word ptr ds:[OFFSET _player + PLAYER_T.player_message], ax
jmp       done_with_keypress		



not_follow_key:
cmp       al, AM_GRIDKEY
jne       not_grid_key

mov       ax, AMSTR_GRIDOFF
xor       byte ptr ds:[_am_grid], cl ; 1
je        toggle_grid_off
dec ax  ; mov       ax, AMSTR_GRIDON
toggle_grid_off:

mov       word ptr ds:[OFFSET _player + PLAYER_T.player_message], ax
jmp       done_with_keypress		


not_grid_key:
cmp       al, AM_MARKKEY
jne       not_mark_key

mov       bx, OFFSET _player_message_string
mov       ax, AMSTR_MARKEDSPOT
mov       cx, ds
call      getStringByIndex_

mov       ax, 030h ; null terminated '0'
add       al, byte ptr ds:[_markpointnum] ; add digit
mov       word ptr ds:[_player_message_string + 12], ax

call      AM_addMark_
mov       cl, 1
jmp       done_with_keypress		

not_mark_key:
cmp       al, AM_CLEARMARKKEY
jne       not_clearmark_key

mov       word ptr ds:[OFFSET _player + PLAYER_T.player_message], AMSTR_MARKSCLEARED
call      AM_clearMarks_
jmp       done_with_keypress		







ENDP



PROC    AM_changeWindowScale_ NEAR
PUBLIC  AM_changeWindowScale_

push      bx
push      cx
push      dx

;    am_scale_mtof.w = FixedMul1632(mtof_zoommul, am_scale_mtof.w)<<4;
;    am_scale_ftom.w = FixedDivWholeA(1, am_scale_mtof.w);


les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
mov       ax, word ptr ds:[_mtof_zoommul]
;SHIFT_MACRO sal ax 4   ; didnt work
call      FixedMul1632_

sal       ax, 1
rcl       dx, 1
sal       ax, 1
rcl       dx, 1
sal       ax, 1
rcl       dx, 1
sal       ax, 1
rcl       dx, 1

mov       word ptr ds:[_am_scale_mtof + 0], ax
mov       word ptr ds:[_am_scale_mtof + 2], dx
push      ax
push      dx
xchg      ax, bx
mov       cx, dx
mov       ax, 1
call      FixedDivWholeA_
mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
pop       ax ; ax gets high
pop       dx

test      ax, ax
jne       not_minout
cmp       dx, word ptr ds:[_am_min_scale_mtof + 0]
jb        min_out_windowscale
not_minout:
cmp       ax, word ptr ds:[_am_max_scale_mtof + 2]
jg        max_out_windowscale
jne       activate_new_scale
cmp       dx, word ptr ds:[_am_max_scale_mtof + 0]
jbe       activate_new_scale
max_out_windowscale:
call      AM_maxOutWindowScale_
exit_am_changewindowscale:
pop       dx
pop       cx
pop       bx
ret       
min_out_windowscale:
call      AM_minOutWindowScale_
jmp       exit_am_changewindowscale
activate_new_scale:
call      AM_activateNewScale_
jmp       exit_am_changewindowscale


ENDP


PROC    AM_doFollowPlayer_ NEAR
PUBLIC  AM_doFollowPlayer_


push      bx
push      dx

; compare intbits
les       bx, dword ptr ds:[_playerMobj_pos]
mov       dx, word ptr word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov       bx, word ptr word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
; dx has x intbits
; bx has y intbits

cmp       dx, word ptr ds:[_screen_oldloc + MPOINT_T.mpoint_x]
jne       not_equal_do_update
cmp       bx, word ptr ds:[_screen_oldloc + MPOINT_T.mpoint_y]
je        exit_follow_player

not_equal_do_update:

;	screen_oldloc.x = playerMobj_pos->x.h.intbits;
;	screen_oldloc.y = playerMobj_pos->y.h.intbits;
mov       word ptr ds:[_screen_oldloc + MPOINT_T.mpoint_x], dx
mov       word ptr ds:[_screen_oldloc + MPOINT_T.mpoint_y], bx

;	screen_botleft_x = (playerMobj_pos->x.h.intbits) - (screen_viewport_width >>1);
;	screen_topright_x = screen_botleft_x + screen_viewport_width;

les       ax, dword ptr ds:[_screen_viewport_width] ; es gets height
push      ax
sar       ax, 1
sub       dx, ax
mov       word ptr ds:[_screen_botleft_x], dx
pop       ax
add       ax, dx
mov       word ptr ds:[_screen_topright_x], ax

;	screen_botleft_y = (playerMobj_pos->y.h.intbits) - (screen_viewport_height >>1);
;	screen_topright_y= screen_botleft_y + screen_viewport_height;

mov       ax, es ; get height
push      ax
sar       ax, 1
sub       bx, ax
mov       word ptr ds:[_screen_botleft_y], bx
pop       ax
add       ax, bx
mov       word ptr ds:[_screen_topright_y], ax


exit_follow_player:
pop       dx
pop       bx
ret       

ENDP

PROC    AM_Ticker_ NEAR
PUBLIC  AM_Ticker_

cmp       byte ptr ds:[_followplayer], 0
je        dont_follow
call      AM_doFollowPlayer_
dont_follow:
cmp       word ptr ds:[_ftom_zoommul], FRAC_SCALE_UNIT
je        dont_scale
call      AM_changeWindowScale_
dont_scale:
cmp       word ptr ds:[_m_paninc + 0], 0
jne       do_change_window_loc
cmp       word ptr ds:[_m_paninc + 2], 0
je        exit_am_ticker
do_change_window_loc:
call      AM_changeWindowLoc_
exit_am_ticker:
ret      

ENDP


;int16_t __near DOOUTCODE(int16_t oc, int16_t mx, int16_t my) {

;// Automap clipping of lines.
;//
;// Based on Cohen-Sutherland clipping algorithm but with a slightly
;// faster reject and precalculated slopes.  If the speed is needed,
;// use a hash algorithm to handle  the common cases.
;//

AM_OUT_LEFT = 	1
AM_OUT_RIGHT = 	2
AM_OUT_BOTTOM = 4
AM_OUT_TOP = 	8

PROC    DOOUTCODE_ NEAR
PUBLIC  DOOUTCODE_

xor       ax, ax
test      bx, bx
jge       not_top
mov       al, AM_OUT_TOP
jmp       done_with_y
not_top:
cmp       bx, AUTOMAP_SCREENHEIGHT
jl        done_with_y
mov       al, AM_OUT_BOTTOM
done_with_y:
test      dx, dx
jge       not_left
or        al, AM_OUT_LEFT
ret
not_left:
cmp       dx, AUTOMAP_SCREENWIDTH
jl        done_with_x
or        al, AM_OUT_RIGHT
done_with_x:
ret       


ENDP

OUTCODE2_FLAG = 16

; inline intot he other thing

PROC    AM_clipMline_ NEAR
PUBLIC  AM_clipMline_


PUSHA_NO_AX_MACRO
xchg      ax, si  ; todo pass in via si
xor       cx, cx ; cl = outcode1. ch = outcode2

;todo reverse order again a little less reg swapping

lodsw
; ax has a.x
mov       di, word ptr ds:[_screen_botleft_x]  ; todo les?
mov       bx, word ptr ds:[_screen_topright_x]
cmp       ax, di
jnl       dont_and_left_a
or        cl, AM_OUT_LEFT
dont_and_left_a:
cmp       ax, bx
jng       dont_and_right_a
or        cl, AM_OUT_RIGHT
dont_and_right_a:

xchg      ax, bp  ; bp has a.x
lodsw
xchg      ax, dx  ; dx has a.y. ax gets b.x after
lodsw

cmp       ax, di
jnl       dont_and_left_b
or        ch, AM_OUT_LEFT
dont_and_left_b:
cmp       ax, bx
jng       dont_and_right_b
or        ch, AM_OUT_RIGHT
dont_and_right_b:
test      cl, ch
jne       exit_am_clipline_return_false

xchg      ax, di    ; di gets b.x
lodsw     

mov       bx, word ptr ds:[_screen_botleft_y]  ; todo les?
mov       si, word ptr ds:[_screen_topright_y]

cmp       ax, bx
jnl       dont_and_bottom_b
or        ch, AM_OUT_BOTTOM
dont_and_bottom_b:
cmp       ax, si
jng       dont_and_top_b
or        ch, AM_OUT_TOP
dont_and_top_b:

xchg      ax, dx  ; ax gets a.y, dx gets b.y

cmp       ax, bx
jnl       dont_and_bottom_a
or        cl, AM_OUT_BOTTOM
dont_and_bottom_a:
cmp       ax, si
jng       dont_and_top_a
or        cl, AM_OUT_TOP
dont_and_top_a:
test      cl, ch
jne       exit_am_clipline_return_false





; bp has a.x
; ax has a.y
; dx has b.y
; di has b.x


; cl/ch is outcode1/2

; todo use di instead of dx,, dont push/pop in this func?
; todo inline these funcs?

call      CYMTOF16_   ;a.y

xchg      ax, bp      ; bp gets a.y
call      CXMTOF16_   ;a.x

xchg      ax, dx      ; dx gets a.x
call      CYMTOF16_   ;b.y 

xchg      ax, di      ; di gets b.y
call      CXMTOF16_   ;b.x




; dx has am_fl.a.x
; bp has am_fl.a.y
; ax has am_fl.b.x
; di has am_fl.b.y

xchg      ax, bp   ; si gets b.x
xchg      ax, bx

; dx has am_fl.a.x
; bx has am_fl.a.y
; bp has am_fl.b.x
; di has am_fl.b.y


call      DOOUTCODE_  ; a case
xchg      ax, cx  ; outcode 1 to cl
xchg      bx, di
xchg      dx, bp
call      DOOUTCODE_  ; b case

mov       si, dx

; bp has am_fl.a.x
; di has am_fl.a.y
; si has am_fl.b.x
; bx has am_fl.b.y

test      al, cl
je        dont_exit_and_return_false

exit_am_clipline_return_false:

POPA_NO_AX_MACRO
xor       ax, ax
ret
exit_am_clipline_return_true:
mov       word ptr ds:[_am_fl + FLINE_T.fline_a + FPOINT_T.fpoint_x], bp
mov       word ptr ds:[_am_fl + FLINE_T.fline_a + FPOINT_T.fpoint_y], di
mov       word ptr ds:[_am_fl + FLINE_T.fline_b + FPOINT_T.fpoint_x], si
mov       word ptr ds:[_am_fl + FLINE_T.fline_b + FPOINT_T.fpoint_y], bx
POPA_NO_AX_MACRO
mov       ax, 1
ret

dont_exit_and_return_false:

mov       ch, al ; outcode 2 in ch
; si has am_fl.b.x
; bx has am_fl.b.y
; bp has am_fl.a.x
; di has am_fl.a.y
;  ch has outcode 2
;  cl has outcode 1

loop_next_outcode_loop:
jcxz      exit_am_clipline_return_true
mov       al, cl
test      al, al 
jne       use_outcode_1_as_outside



use_outcode_2_as_outside:
mov      al, ch
or       ch, OUTCODE2_FLAG
use_outcode_1_as_outside:
; al is outside

mov      es, cx   ; backup outcode1/outcode2 in es

; dx = am_fl.b.x - am_fl.a.x;
; dy = am_fl.a.y - am_fl.b.y;


mov      dx, si
sub      dx, bp
mov      cx, di
sub      cx, bx

; dx is 'dx'
; cx is 'dy

test     al, AM_OUT_TOP
je       outside_not_top

; tmp.x = am_fl.a.x + (dx*(am_fl.a.y))/dy;
; tmp.y = 0;

xchg   ax, dx
imul   di
idiv   cx
add    ax, bp
xor    dx, dx

jmp      done_with_side_check
outside_not_top:
test     al, AM_OUT_BOTTOM
je       outside_not_bottom

; tmp.x = am_fl.a.x + (dx*(am_fl.a.y-automap_screenheight))/dy;
; tmp.y = automap_screenheight-1;

mov     ax, di
sub     ax, AUTOMAP_SCREENHEIGHT
imul    dx
idiv    cx
add     ax, bp
mov     dx, AUTOMAP_SCREENHEIGHT-1

jmp      done_with_side_check
outside_not_bottom:
neg     cx       ; dy reverse for these 2 cases
xchg    cx, dx   ; dx is dy. cx is dx
test     al, AM_OUT_RIGHT
je       outside_not_right

; tmp.y = am_fl.a.y + (dy*(automap_screenwidth-1 - am_fl.a.x))/dx;
; tmp.x = automap_screenwidth-1;

mov      ax, (AUTOMAP_SCREENWIDTH - 1)
sub      ax, bp
imul     dx
idiv     cx
xchg     ax, dx
mov      ax, AUTOMAP_SCREENWIDTH-1
jmp      add_bp_and_done_with_sidecheck
outside_not_right:

; must be left

; tmp.y = am_fl.a.y + (dy*(-am_fl.a.x))/dx;
; tmp.x = 0;

mov      ax, bp
neg      ax
imul     dx
idiv     cx
xchg     ax, dx
xor      ax, ax
add_bp_and_done_with_sidecheck:
add      dx, di

done_with_side_check:

; si has am_fl.b.x
; bx has am_fl.b.y
; bp has am_fl.a.x
; di has am_fl.a.y
mov      cx, es   ; recover outcode1/outcode2 from es

;ax = tmp.x
;dx = tmp.y

test     ch, OUTCODE2_FLAG
jne      outside_is_outcode2

outside_is_outcode1:

;	am_fl.a = tmp;
;	outcode1 = DOOUTCODE(outcode1, am_fl.a.x, am_fl.a.y);

xchg     ax, bp
mov      di, dx
mov      dx, bp
xchg     bx, di ; get this param...

call     DOOUTCODE_
xchg     bx, di ; recover
mov      cl, al 

checkoutcodes_again:
test     cl, ch
je       loop_next_outcode_loop
POPA_NO_AX_MACRO
xor      ax, ax
ret       

outside_is_outcode2:

;	am_fl.b = tmp;
;	outcode2 = DOOUTCODE(outcode2, am_fl.b.x, am_fl.b.y);
xor      ch, OUTCODE2_FLAG  ; turn that off
xchg     ax, si
mov      bx, dx
mov      dx, si
; bx is already correct...
call     DOOUTCODE_
mov      ch, al
jmp      checkoutcodes_again

ENDP

COMMENT @

PROC    AM_drawMline_ NEAR
PUBLIC  AM_drawMline_

PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp
sub       sp, 8
mov       byte ptr [bp - 2], dl
call      AM_clipMline_
test      al, al
jne       label_113
label_123:
jmp       do_return
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
jmp       do_return
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
mov       di, word ptr es:[si]
mov       si, word ptr [bp - 4]
mov       es, word ptr ds:[_SEENLINES_6800_SEGMENT_PTR]
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