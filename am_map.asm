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
INCLUDE strings.inc
INSTRUCTION_SET_MACRO



EXTRN FixedDivWholeA_MapLocal_:NEAR
EXTRN FixedDiv_MapLocal_:NEAR
EXTRN FixedMul1632_MapLocal_:NEAR
EXTRN FastDiv3216u_MapLocal_:NEAR







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








.CODE



PROC    AM_MAP_STARTMARKER_ NEAR
PUBLIC  AM_MAP_STARTMARKER_
ENDP

; 16 bit versions below...

_player_arrow:
 dw 0FF00h
 dw 00000h
 dw 00124h
 dw 00000h
 dw 00124h
 dw 00000h
 dw 00092h
 dw 00049h
 dw 00124h
 dw 00000h
 dw 00092h
 dw 0FFB7h
 dw 0FF00h
 dw 00000h
 dw 0FEB8h
 dw 00049h
 dw 0FF00h
 dw 00000h
 dw 0FEB8h
 dw 0FFB7h
 dw 0FF49h
 dw 00000h
 dw 0FF00h
 dw 00049h
 dw 0FF49h
 dw 00000h
 dw 0FF00h
 dw 0FFB7h


_cheat_player_arrow:

dw 0FF00h
 dw 00000h
 dw 00124h
 dw 00000h
 dw 00124h
 dw 00000h
 dw 00092h
 dw 00030h
 dw 00124h
 dw 00000h
 dw 00092h
 dw 0FFD0h
 dw 0FF00h
 dw 00000h
 dw 0FEB8h
 dw 00030h
 dw 0FF00h
 dw 00000h
 dw 0FEB8h
 dw 0FFD0h
 dw 0FF49h
 dw 00000h
 dw 0FF00h
 dw 00030h
 dw 0FF49h
 dw 00000h
 dw 0FF00h
 dw 0FFD0h
 dw 0FF6Eh
 dw 00000h
 dw 0FF6Eh
 dw 0FFD0h
 dw 0FF6Eh
 dw 0FFD0h
 dw 0FF9Eh
 dw 0FFD0h
 dw 0FF9Eh
 dw 0FFD0h
 dw 0FF9Eh
 dw 00049h
 dw 0FFD0h
 dw 00000h
 dw 0FFD0h
 dw 0FFD0h
 dw 0FFD0h
 dw 0FFD0h
 dw 00000h
 dw 0FFD0h
 dw 00000h
 dw 0FFD0h
 dw 00000h
 dw 00049h
 dw 00030h
 dw 00049h
 dw 00030h
 dw 0FFD7h
 dw 00030h
 dw 0FFD7h
 dw 00039h
 dw 0FFCEh
 dw 00039h
 dw 0FFCEh
 dw 0004Dh
 dw 0FFD7h



_thintriangle_guy:

 dw 0FF80h
 dw 0FF50h
 dw 00100h
 dw 00000h
 dw 00100h
 dw 00000h
 dw 0FF80h
 dw 000B0h
 dw 0FF80h
 dw 000B0h
 dw 0FF80h
 dw 0FF50h

_markpoints:
dw AM_NUMMARKPOINTS * 2 DUP(-1)

_am_min_level_x:
dw 0
_am_min_level_y:
dw 0
_am_max_level_x:
dw 0
_am_max_level_y:
dw 0


_am_lastlevel:
db 0
_am_lastepisode:
db 0
_markpointnum:
dw 0



;#pragma aux trig16params \
;                    __modify [bx] \
;                    __parm [ax] [dx] [bx] \
;                    __value [dx ax];



IF COMPISA GE COMPILE_386

    PROC FastMulTrig16_    NEAR
    PUBLIC FastMulTrig16_

    
    ;db  066h, 025h, 0FFh, 0FFh, 0, 0        ;  and eax, 0x0000FFFF  
    ;db 066h, 08eh, 0c0h                   ; mov es, eax
    
    ; seems to work instead of the above
    mov es, ax

    db  066h, 081h, 0E3h, 0FFh, 0FFh, 0, 0  ;  and ebx, 0x0000FFFF   
    ;sal   dx, 2

    xchg  dx, ax                            ; get dx in ax for sign extend
    db 066h, 098h                           ; cwde  (sign extend ax to eax for imul)

    db 026h, 067h, 066h, 0F7h, 02Bh         ; imul dword ptr es:[ebx]

    db  066h, 00Fh, 0A4h, 0C2h, 010h        ; shld edx, eax, 0x10

    ret



    ENDP

ELSE


    PROC FastMulTrig16_    NEAR
    PUBLIC FastMulTrig16_
    ; ax:[dx * 4] * BX
    ; (dont shift answer 16)
    ;
    ; 
    ;BYTE
    ; RETURN VALUE
    ;                3       2       1		0
    ;                DONTUSE DONTUSE USE    USE


    ;                               AXBXhi	 AXBXlo
    ;                       DXBXhi  DXBXlo          
    ;               S0BXhi  S0BXlo                          
    ;
    ;               AXS1hi  AXS1lo
    ;                               
    ;                       
    ;       

    ; AX is param 1 (segment)
    ; DX is param 2 (fineangle or lookup)
    ; BX is value 2

    ; DX:AX * BX
    ; need to sign extend BX to CX...

    ; do lookup..

    ; bx already passed in as lookup index...  value in dx etc

    mov es, ax  ; put segment in ES
    les ax, dword ptr es:[BX]
    mov bx, es

    ;BX:AX * DX

    ; begin multiply...

    AND   BX, DX
    NEG   BX        ; get sign mult for 16 bit param * high trig.

    MOV   ES, BX    ; store it in ES

    MOV   BX, AX  ; BX stores trig param lowbits
    MOV   AX, DX  ; AX stores 16 bit param 

    CWD   ; DX gets 16 bit arg's sign bits
    AND   DX, BX  ; still need to neg. move after mul for pipelining
    XCHG  DX, BX  ; swap params

    MUL   DX

    NEG   BX      ; finish the sign multiply from above, after the queue is full from mul
    ADD   DX, BX  ; add first sign bits back
    MOV   BX, ES  ; add second sign bits back
    ADD   DX, BX



    ret


    ENDP

ENDIF

PROC    CXMTOF16_ NEAR
PUBLIC  CXMTOF16_

; we can clobber cx, bx
push      dx
les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
sub       ax, word ptr ds:[_screen_botleft_x]  ; todo dont suppose this can be self modified start of frame?
call      FixedMul1632_MapLocal_
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
call      FixedMul1632_MapLocal_
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
les       ax, dword ptr ds:[_screen_viewport_width] 
sar       ax, 1
add       word ptr ds:[_screen_botleft_x], ax
mov       ax, es
sar       ax, 1
add       word ptr ds:[_screen_botleft_y], ax
les       bx, dword ptr ds:[_am_scale_ftom + 0]
mov       cx, es
mov       ax, AUTOMAP_SCREENWIDTH
call      FixedMul1632_MapLocal_
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
call      FixedMul1632_MapLocal_
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



PROC    AM_restoreScaleAndLoc_ NEAR
PUBLIC  AM_restoreScaleAndLoc_

; bx/dx are safe to clobber in outer scope
;push      bx
push      cx
;push      dx
les       ax, dword ptr ds:[_old_screen_viewport_width]
mov       word ptr ds:[_screen_viewport_width], ax
mov       word ptr ds:[_screen_viewport_height], es
cmp       byte ptr ds:[_followplayer], ch ; 0 known from outer func scope..
jne       do_follow_player
les       ax, dword ptr ds:[_old_screen_botleft_x]
mov       dx, es
jmp       got_screen_xy
do_follow_player:
mov       dx, es
les       bx, dword ptr ds:[_playerMobj_pos]
sar       ax, 1
sar       dx, 1
neg       ax
neg       dx
add       ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
add       dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
got_screen_xy:
; ax/dx have botleft x/y ready 
mov       word ptr ds:[_screen_botleft_x], ax
mov       word ptr ds:[_screen_botleft_y], dx
mov       cx, word ptr ds:[_screen_viewport_width]
add       ax, cx
mov       word ptr ds:[_screen_topright_x], ax
add       dx, word ptr ds:[_screen_viewport_height]
mov       word ptr ds:[_screen_topright_y], dx
xor       bx, bx
mov       ax, AUTOMAP_SCREENWIDTH
call      FixedDivWholeA_MapLocal_

mov       word ptr ds:[_am_scale_mtof + 0], ax
xchg      ax, bx
mov       ax, 1
mov       word ptr ds:[_am_scale_mtof + 2], dx
mov       cx, dx
call      FixedDivWholeA_MapLocal_


mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
;pop       dx
pop       cx
;pop       bx
ret       


ENDP



PROC    AM_addMark_ NEAR
PUBLIC  AM_addMark_

;	markpointnum = (markpointnum + 1) % AM_NUMMARKPOINTS;
;    markpoints[markpointnum].x = screen_botleft_x + (screen_viewport_width >>1);
;    markpoints[markpointnum].y = screen_botleft_y + (screen_viewport_height >>1);


push      bx
mov       ax, word ptr cs:[_markpointnum]

mov       bx, ax
inc       ax ; for division
mov       bh, AM_NUMMARKPOINTS
div       bh
mov       byte ptr cs:[_markpointnum], ah
xor       bh, bh

les       ax, dword ptr ds:[_screen_viewport_width]
sar       ax, 1
SHIFT_MACRO shl       bx 2
add       ax, word ptr ds:[_screen_botleft_x]
mov       word ptr cs:[bx + _markpoints + MPOINT_T.mpoint_x], ax
mov       ax, es
sar       ax, 1
add       ax, word ptr ds:[_screen_botleft_y]
mov       word ptr cs:[bx + _markpoints + MPOINT_T.mpoint_y], ax
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
mov       word ptr cs:[_am_min_level_x], dx
mov       word ptr cs:[_am_max_level_x], bx
mov       word ptr cs:[_am_min_level_y], di
mov       word ptr cs:[_am_max_level_y], bp
sub       bp, di ; bp = max y - min y

;todo this in theory can be better. but whoe cares, runs once
;    max_w = am_max_level_x - am_min_level_x;
;    max_h = am_max_level_y - am_min_level_y;

;	a = FixedDiv(automap_screenwidth, max_w);
;	b = FixedDiv(automap_screenheight, max_h);

; todo maybe just regular div since its 32 bit over 16 bit? or do overflows happen
; ax to dx, ax is 0. then div over bx. 
sub       bx, dx
xor       cx, cx


mov       ax, AUTOMAP_SCREENWIDTH
cwd
call  FixedDiv_MapLocal_


xchg      ax, si ; store a
mov       di, dx ; store a
mov       bx, bp
xor       cx, cx
mov       ax, AUTOMAP_SCREENHEIGHT
cwd
call  FixedDiv_MapLocal_



;    am_min_scale_mtof = a < b ? a : b;
; dx:ax is b

cmp       dx, di
jg        use_a
jl        use_b
cmp       ax, si
jl        use_b
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
add       dx, ax ;    screen_botleft_x += m_paninc.x;
mov       ax, es
add       bx, ax ;    screen_botleft_y += m_paninc.y;

; bounds check 
; dx = botleftx
; bx = botlefty
;    if (screen_botleft_x + (screen_viewport_width >>1) > am_max_level_x){
;		screen_botleft_x = am_max_level_x - (screen_viewport_width >>1);
;	} else if (screen_botleft_x + (screen_viewport_width >>1) < am_min_level_x){
;		screen_botleft_x = am_min_level_x - (screen_viewport_width >>1);

mov       ax, word ptr ds:[_screen_viewport_width]
mov       cx, dx
sar       ax, 1
add       cx, ax
neg       ax
cmp       cx, word ptr cs:[_am_max_level_x]
jg        use_maxlevelx
cmp       cx, word ptr cs:[_am_min_level_x]
jge       dont_subtract_x
add       ax, word ptr cs:[_am_min_level_x]
jmp       done_subtracting_x
use_maxlevelx:
add       ax, word ptr cs:[_am_max_level_x]
jmp       done_subtracting_x
dont_subtract_x:
xchg      ax, dx  ; just use this value
done_subtracting_x:
; ax is screen_botleft_x
mov       word ptr ds:[_screen_botleft_x], ax
add       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_screen_topright_x], ax    ; screen_topright_x = screen_botleft_x + screen_viewport_width;

mov       ax, word ptr ds:[_screen_viewport_height]
mov       cx, bx
sar       ax, 1
add       cx, ax
neg       ax
cmp       cx, word ptr cs:[_am_max_level_y]
jge       use_maxlevely
cmp       cx, word ptr cs:[_am_min_level_y]
jge       dont_subtract_y
add       ax, word ptr cs:[_am_min_level_y]
jmp       done_subtracting_y
use_maxlevely:
add       ax, word ptr cs:[_am_max_level_y]
jmp       done_subtracting_y
dont_subtract_y:
xchg      ax, bx
done_subtracting_y:

mov       word ptr ds:[_screen_botleft_y], ax
add       ax, word ptr ds:[_screen_viewport_height]
mov       word ptr ds:[_screen_topright_y], ax   ; screen_topright_y = screen_botleft_y + screen_viewport_height;
pop       dx
pop       cx
pop       bx
ret       

ENDP



FRAC_SCALE_UNIT = 01000h




PROC    AM_recordOldViewport_

les       ax, dword ptr ds:[_screen_botleft_x]
mov       word ptr ds:[_old_screen_botleft_x], ax
mov       word ptr ds:[_old_screen_botleft_y], es
les       ax, dword ptr ds:[_screen_viewport_width]
mov       word ptr ds:[_old_screen_viewport_width], ax
mov       word ptr ds:[_old_screen_viewport_height], es

ret

ENDP

PROC    AM_clearMarks_ NEAR
PUBLIC  AM_clearMarks_

push      cx
push      di
mov       cx, (AM_NUMMARKPOINTS * SIZE MPOINT_T) / 2 
mov       ax, -1
mov       di, OFFSET _markpoints
push      cs
pop       es
rep stosw
mov       byte ptr cs:[_markpointnum], cl ; 0
pop       di
pop       cx
ret       

ENDP


COMMENT @
; inlined

PROC    AM_Stop_ NEAR
PUBLIC  AM_Stop_

mov       word ptr ds:[_am_stopped], 00001h
mov       byte ptr ds:[_st_gamestate], 1
ret      

@

ENDP

PROC    AM_Start_ NEAR
PUBLIC  AM_Start_
PUSHA_NO_AX_OR_BP_MACRO

mov       al, byte ptr ds:[_am_stopped]
test      al, al
mov       ax, 1
jne       dont_call_am_stop
mov       word ptr ds:[_am_stopped], ax   ; 1
mov       byte ptr ds:[_st_gamestate], al ; 1

dont_call_am_stop:

mov       byte ptr ds:[_am_stopped], ah ; 0
mov       ax, word ptr cs:[_am_lastlevel] 
cmp       al, byte ptr ds:[_gamemap]
jne       do_level_init
cmp       ah, byte ptr ds:[_gameepisode]
je        just_init_variables
do_level_init:
;call      AM_LevelInit_
; inlined

mov       word ptr ds:[_am_scale_mtof + 0], 03333h  ; 0x10000 / 5

; 11e60000 / B333
call      AM_clearMarks_
call      AM_findMinMaxBoundaries_
mov       bx, 0B333h    ; 0.7*FRACUNIT
xor       cx, cx
mov       dx, word ptr ds:[_am_min_scale_mtof]
xor       ax, ax
call      FastDiv3216u_MapLocal_

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
call      FixedDivWholeA_MapLocal_

mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx

mov       al, byte ptr ds:[_gamemap]
mov       ah, byte ptr ds:[_gameepisode]  ; todo make these all adjacent.. one read one write?
mov       word ptr cs:[_am_lastlevel], ax  

just_init_variables:
;call      AM_initVariables_

; inlined
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

call      FixedMul1632_MapLocal_
les       bx, dword ptr ds:[_am_scale_ftom]
mov       cx, es
mov       word ptr ds:[_screen_viewport_width], ax
sar       ax, 1
xchg      ax, si
mov       ax, AUTOMAP_SCREENHEIGHT
call      FixedMul1632_MapLocal_

mov       word ptr ds:[_screen_viewport_height], ax

sar       ax, 1
neg       ax
add       ax, word ptr ds:[_cached_playerMobj_y_highbits]
mov       word ptr ds:[_screen_botleft_y], ax

mov       ax, word ptr ds:[_cached_playerMobj_x_highbits]
sub       ax, si
mov       word ptr ds:[_screen_botleft_x], ax

call      AM_changeWindowLoc_



call      AM_recordOldViewport_
mov       byte ptr ds:[_st_gamestate], 0
mov       byte ptr ds:[_st_firsttime], 1
POPA_NO_AX_OR_BP_MACRO
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
call      FixedDivWholeA_MapLocal_


mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
call      AM_activateNewScale_
pop       dx
pop       cx
pop       bx
ret       

ENDP







PROC    AM_Responder_ FAR
PUBLIC  AM_Responder_

;boolean __near AM_Responder ( event_t __far* ev ) {

PUSHA_NO_AX_OR_BP_MACRO

xchg      ax, si
mov       es, dx

xor       dx, dx


mov       ax, word ptr es:[si + EVENT_T.event_data1]

; al is evdata
; ah is type
; dx is 0reg here

cmp       byte ptr ds:[_automapactive], dl ; 0
jne       automap_is_active
cmp       ah, dl  ; EV_KEYDOWN, 0
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
retf       

automap_is_active:

; ah is evtype
; al is data1
; cx is 0, inverse of cx
xor       cx, cx
mov       si, ax  ; back up in case we need it when done with keypress..


cmp       ah, EV_KEYUP
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
;call      AM_Stop_
mov       word ptr ds:[_am_stopped], cx   ; 1
mov       byte ptr ds:[_st_gamestate], cl ; 1


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
mov       al, CHEATID_AUTOMAP 
call      dword ptr ds:[_cht_CheckCheat_Far_addr]

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
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _getStringByIndex_addr


mov       ax, 030h ; null terminated '0'
add       al, byte ptr cs:[_markpointnum] ; add digit
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






PROC    AM_Ticker_ FAR
PUBLIC  AM_Ticker_

push      bx
push      cx
push      dx

cmp       byte ptr ds:[_followplayer], 0
je        dont_follow
;call      AM_doFollowPlayer_
; inlined

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
dont_follow:
cmp       word ptr ds:[_ftom_zoommul], FRAC_SCALE_UNIT
je        dont_scale
;call      AM_changeWindowScale_
; inlined

;    am_scale_mtof.w = FixedMul1632(mtof_zoommul, am_scale_mtof.w)<<4;
;    am_scale_ftom.w = FixedDivWholeA(1, am_scale_mtof.w);

les       bx, dword ptr ds:[_am_scale_mtof + 0]
mov       cx, es
mov       ax, word ptr ds:[_mtof_zoommul]
;SHIFT_MACRO sal ax 4   ; didnt work
call      FixedMul1632_MapLocal_

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

call      FixedDivWholeA_MapLocal_

mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
pop       ax ; ax gets high
pop       dx

test      ax, ax
jne       not_minout
cmp       dx, word ptr ds:[_am_min_scale_mtof]
jb        min_out_windowscale
not_minout:
cmp       ax, word ptr ds:[_am_max_scale_mtof + 2]
jg        max_out_windowscale
jne       activate_new_scale
cmp       dx, word ptr ds:[_am_max_scale_mtof + 0]
jbe       activate_new_scale
max_out_windowscale:
;call      AM_maxOutWindowScale_
; inlined

mov       ax, 1
les       bx, dword ptr ds:[_am_max_scale_mtof + 0]
mov       cx, es
mov       word ptr ds:[_am_scale_mtof + 0], bx
mov       word ptr ds:[_am_scale_mtof + 2], cx
call      FixedDivWholeA_MapLocal_


mov       word ptr ds:[_am_scale_ftom + 0], ax
mov       word ptr ds:[_am_scale_ftom + 2], dx
activate_new_scale:
call      AM_activateNewScale_
exit_am_changewindowscale:

dont_scale:
cmp       word ptr ds:[_m_paninc + 0], 0
jne       do_change_window_loc
cmp       word ptr ds:[_m_paninc + 2], 0
je        exit_am_ticker
do_change_window_loc:
call      AM_changeWindowLoc_
exit_am_ticker:

pop       dx
pop       cx
pop       bx

retf      
min_out_windowscale:
call      AM_minOutWindowScale_
jmp       exit_am_changewindowscale

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

PROC    AM_drawMline_ NEAR
PUBLIC  AM_drawMline_

PUSHA_NO_AX_MACRO
push      dx    ; color

xchg      ax, si  
xor       cx, cx ; cl = outcode1. ch = outcode2



lodsw
; ax has a.x
les       di, dword ptr ds:[_screen_botleft_x]  
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

mov       bx, es ; got it earlier
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
pop       ax ; color
POPA_NO_AX_MACRO
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
jcxz      do_mlinedraw
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
pop       ax ; color
POPA_NO_AX_MACRO
ret       


; continue draw
do_mlinedraw:

; a.x bp
; a.y di
; b.x si
; b.y bx



; dx = am_fl.b.x - am_fl.a.x;
; ax = (dx<0 ? -dx : dx) << 1;
; sx = dx<0 ? -1 : 1;

mov       dx, 1              ; "sx"
sub       si, bp             ; 
jns       dont_negative_dx
neg       si
neg       dx
dont_negative_dx:
mov       cx, si             ; abs("dx")
sal       si, 1              ; "ax"

IF COMPISA GE COMPILE_186
    imul      ax, di, AUTOMAP_SCREENWIDTH
    add       ax, bp  

ELSE
    push      dx
    mov       ax, AUTOMAP_SCREENWIDTH  
    mul       di 
    pop       dx  ;   dx has sx
    add       ax, bp  
ENDIF




; dy = am_fl.b.y - am_fl.a.y;
; ay = (dy<0 ? -dy : dy) << 1;
; sy = dy<0 ? -1 : 1;

mov       bp, SCREENWIDTH  ; "sy"
sub       bx, di  ; dy
xchg      ax, di  ; di holds dest
jns       dont_negative_dy
neg       bx
neg       bp      ; "sy" negative
dont_negative_dy:
mov       es, bx  ; store positive dy
sal       bx, 1   ; "ay"


; di: dest pixel
; si: "ax"
; bx: "ay"  
; dx: "sx"  (1 or -1)
; bp: "sy"  (320 or -320)
; cx: abs (dx) (x loop length)
; es: abs (dy) (y loop length)

cmp       si, bx ; 		if (ax > ay) {
jg        dont_do_xy_swaps

xchg      dx, bp  ; "sx" "sy" swap
xchg      si, bx  ; "ax" "ay" swap
mov       cx, es ; use dy for loop length
dont_do_xy_swaps:

dec       dx  ; minus 1 to account for the stosb every step

;  d = ay - (ax>>1);
mov        ax, SCREEN0_SEGMENT
mov        es, ax
pop        ax ; get color into al

inc        cx
cli
mov        ds, sp ; backup
mov        sp, si
sar        sp, 1    ; ax >> 1
neg        sp
add        sp, bx  ; flags carry to js below



; dx is dominant coord  we add to di/screenpos every step. either sx or sy
; bp is the nondominant coord we only add when d >= 0
; sp is "d"
; bx is the nondominant coord we add to d every step
; si is the dominant coord we subtract when d >= 0
; cx is loop length (longest of positive dx and positive dy)

loop_next_pixel:

stosb      ; write pixel to screen

js         dont_do_d_stuff
; crossed over least dominant coord
add        di, bp  ; add nondominant screen step
sub        sp, si  ; subtract slope 

dont_do_d_stuff:
add        di, dx  ; add dominant screen step. dx was decced by 1 to account for stosb
add        sp, bx  ; add to slope 
loop       loop_next_pixel

mov        sp, ds
push       ss
pop        ds
sti
POPA_NO_AX_MACRO
ret

outside_is_outcode2:

;	am_fl.b = tmp;
;	outcode2 = DOOUTCODE(outcode2, am_fl.b.x, am_fl.b.y);

xchg     ax, si
mov      bx, dx
mov      dx, si
; bx is already correct...
call     DOOUTCODE_
mov      ch, al
jmp      checkoutcodes_again

ENDP 






LINE_NEVERSEE = ML_DONTDRAW

PROC    AM_drawWalls_ NEAR
PUBLIC  AM_drawWalls_
; okay to use registers.
push      bp
mov       bp, sp
sub       sp, 8

xor       bx, bx ; LINE_PHYSICS_T offset (16 bytes)
xor       di, di ; i/loop counter and 1 byte offset

loop_draw_next_wall:

mov       es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]
mov       dx, word ptr es:[bx + LINE_PHYSICS_T.lp_backsecnum]

les       si, dword ptr es:[bx]  ; v1/v2
mov       ax, es
;and       ax, VERTEX_OFFSET_MASK  ; dont need to, shift left two kills the 2 hi bits
mov       ds, word ptr ds:[_VERTEXES_SEGMENT_PTR]
push      ss
pop       es
SHIFT_MACRO sal si 2
SHIFT_MACRO sal ax 2

;	am_l.a.x = vertexes[linev1Offset].x;
;	am_l.a.y = vertexes[linev1Offset].y;
;	am_l.b.x = vertexes[linev2Offset].x;
;	am_l.b.y = vertexes[linev2Offset].y;
push      di
lea       di, [bp - 8]
movsw   ;a.x
movsw   ;a.y
xchg      ax, si
movsw   ;b.x
movsw   ;b.y
pop       di 

push      ss
pop       ds  ; recover ds



; dx holds backsecnum
; bx holds LINE_PHYSICS offset still
; di holds i...

cmp       byte ptr ds:[_am_cheating], 0
jne       do_draw_wall
mov       es, word ptr ds:[_SEENLINES_6800_SEGMENT_PTR]
; figure out mappedflag
;	mappedflag = seenlines_6800[i / 8] & (0x01 << (i%8));
mov       si, di
SHIFT_MACRO  sar si 3
mov       cx, di
and       cl, 7
mov       al, 1
sal       ax, cl

test      byte ptr es:[si], al
jz        wall_not_mapped
; can see wall

mov       es, word ptr ds:[_LINEFLAGSLIST_SEGMENT_PTR]
test      byte ptr es:[di], LINE_NEVERSEE
jne       iter_draw_wall_loop

; wall is visible, or cheating
do_draw_wall:
mov       cx, dx  ; now cx holds backsecnum

mov       dl, WALLCOLORS
cmp       cx, SECNUM_NULL
je        draw_wall_and_iter


do_other_wallchecks:
mov       es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]
mov       si, word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum]
; cx is backsecnum
; si is frontsecnum..
mov       dl, WALLCOLORS+(WALLRANGE/2)
cmp       word ptr es:[bx + LINE_PHYSICS_T.lp_special], 39  ; teleporters
je        draw_wall_and_iter

mov       es, word ptr ds:[_LINEFLAGSLIST_SEGMENT_PTR]
test      byte ptr es:[di], ML_SECRET ; secret_door
jne       draw_secret_door


SHIFT_MACRO  sal si 4
mov       es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov       ax, word ptr es:[si + SECTOR_T.sec_floorheight]
mov       si, word ptr es:[si + SECTOR_T.sec_ceilingheight]
xchg      cx, si
SHIFT_MACRO  sal si 4
; check floor level change
mov       dl, FDWALLCOLORS
cmp       ax, word ptr es:[si + SECTOR_T.sec_floorheight]
jne       draw_wall_and_iter
mov       dl, CDWALLCOLORS
cmp       cx, word ptr es:[si + SECTOR_T.sec_ceilingheight]
jne       draw_wall_and_iter
mov       dl, TSWALLCOLORS
cmp       byte ptr ds:[_am_cheating], 0
je        iter_draw_wall_loop  ; fall thru


draw_wall_and_iter:
lea       ax, [bp - 8]
call      AM_drawMline_

iter_draw_wall_loop:
add       bx, SIZE LINE_PHYSICS_T
inc       di
cmp       di, word ptr ds:[_numlines]
jge       exit_drawwalls
jmp       loop_draw_next_wall
exit_drawwalls:
LEAVE_MACRO
ret

wall_not_mapped:
cmp       word ptr ds:[_player + PLAYER_T.player_powers + (PW_ALLMAP * 2)], 0
je        iter_draw_wall_loop
mov       es, word ptr ds:[_LINEFLAGSLIST_SEGMENT_PTR]
test      byte ptr es:[di], LINE_NEVERSEE
jne       iter_draw_wall_loop
mov       dl, COLOR_GREYS + 3
jmp       draw_wall_and_iter



draw_secret_door:
mov       dl, WALLCOLORS
cmp       byte ptr ds:[_am_cheating], 0
je        draw_wall_and_iter
mov       dl, SECRETWALLCOLORS
jmp       draw_wall_and_iter


ENDP

PROC    AM_rotate_ NEAR
PUBLIC  AM_rotate_

push      bx
push      cx
push      si
push      di
push      bp

mov       cx, word ptr [bp - 0Ch] ; angle from outer scope.

xchg      ax, si  ; x backup
mov       di, dx  ; y backup
mov       ax, FINESINE_SEGMENT
mov       bx, cx
;mov       dx, di ; already set
call      FastMulTrig16_
xchg      ax, bp
push      dx

mov       ax, FINECOSINE_SEGMENT
mov       bx, cx
mov       dx, si
call      FastMulTrig16_
sub       ax, bp
pop       ax
sbb       dx, ax



xchg      dx, si   ; dx gets old x value once more and si stores x result

mov       bx, cx
mov       ax, FINESINE_SEGMENT
call      FastMulTrig16_
xchg      ax, bp  ; low result
xchg      dx, di  ; high result, get last y value into dx

mov       bx, cx
mov       ax, FINECOSINE_SEGMENT
call      FastMulTrig16_
add       ax, bp
adc       dx, di ; y result right into dx.
xchg      ax, si ; recover x result

pop       bp
pop       di
pop       si
pop       cx
pop       bx
ret       

ENDP

;void __near AM_drawLineCharacter
   ; ax     mline_t __near*	lineguy,
   ; dx     int16_t		lineguylines,
   ; bx     uint8_t		color,
   ; dx     fineangle_t	angle,
   ; bp+8   int16_t	x,
   ; bp+A   int16_t	y 




PROC    AM_drawLineCharacter_ NEAR
PUBLIC  AM_drawLineCharacter_

push      si ; bp + 4
push      di ; bp + 2
push      bp ; bp + 0
mov       bp, sp
sub       sp, 8
push      bx ; bp - 0Ah color
push      dx ; bp - 0Ch angle


xchg      ax, si ; si gets lineguy...
loop_next_lineguy_line:

lods      word ptr cs:[si]
xchg      ax, di ; a.x
lods      word ptr cs:[si]
xchg      ax, dx ; a.y
lods      word ptr cs:[si]
xchg      ax, bx ; b.x
lods      word ptr cs:[si]
xchg      ax, di ; a.x in ax

call      AM_rotate_

SHIFT_MACRO sar ax 4
SHIFT_MACRO sar dx 4
add       ax, word ptr [bp + 8] ; x
add       dx, word ptr [bp + 0Ah] ; y

mov       word ptr [bp - 8], ax
mov       word ptr [bp - 6], dx

xchg      ax, bx
xchg      dx, di
call      AM_rotate_

SHIFT_MACRO sar ax 4
SHIFT_MACRO sar dx 4
add       ax, word ptr [bp + 8] ; x
add       dx, word ptr [bp + 0Ah] ; y


mov       word ptr [bp - 4], ax
mov       word ptr [bp - 2], dx

lea       ax, [bp - 8]
mov       dx, word ptr [bp - 0Ah] ; color

call      AM_drawMline_

loop      loop_next_lineguy_line

exit_am_drawlinecharacter:
LEAVE_MACRO     
pop       di
pop       si
ret       4


ENDP


PROC    AM_drawPlayers_ NEAR
PUBLIC  AM_drawPlayers_

; unused in outer scope
;push      bx
;push      cx
;push      dx
cmp       byte ptr ds:[_am_cheating], 0
les       bx, dword ptr ds:[_playerMobj_pos]
jne       do_cheat_player_draw

mov       cx, 7 ; NUMPLYRLINES
mov       ax, OFFSET _player_arrow
jmp       do_player_draw

do_cheat_player_draw:
mov       cx, 16 ; NUMCHEATPLYRLINES
mov       ax, OFFSET _cheat_player_arrow

do_player_draw:
push      word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push      word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov       dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
shr       dx, 1
and       dl, 0FCh ; fineangle
mov       bx, COLOR_WHITE

call      AM_drawLineCharacter_
;pop       dx
;pop       cx
;pop       bx
ret       


ENDP



do_draw_things:
;call      AM_drawThings_

mov       cx, word ptr ds:[_numsectors]
mov       di, SECTOR_T.sec_thinglistRef

loop_next_sector:
push      cx

mov       es, word ptr ds:[_SECTORS_SEGMENT_PTR]
; si is thingref
mov       si, word ptr es:[di] ;  + SECTOR_T.sec_thinglistRef

loop_next_thingref:
test      si, si
je        done_with_sector

IF COMPISA GE COMPILE_186
    imul      si, si, (SIZE MOBJ_POS_T)
ELSE
    mov       ax, (SIZE MOBJ_POS_T)
    mul       si
    xchg      ax, si
ENDIF

mov       es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]

mov       ax, OFFSET _thintriangle_guy
mov       cx, 3

push      word ptr es:[si + MOBJ_POS_T.mp_y + 2]
push      word ptr es:[si + MOBJ_POS_T.mp_x + 2]
mov       dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
shr       dx, 1
and       dl, 0FCh ; fineangle
mov       bx, THINGCOLORS

mov       si, word ptr es:[si + MOBJ_POS_T.mp_snextRef] ; get next ref...

call      AM_drawLineCharacter_

jmp       loop_next_thingref

done_with_sector:

add       di, SIZE SECTOR_T
pop       cx
loop      loop_next_sector

jmp       done_drawing_things



PROC    AM_Drawer_ FAR
PUBLIC  AM_Drawer_

PUSHA_NO_AX_MACRO


mov       cx, AUTOMAP_SCREENWIDTH*AUTOMAP_SCREENHEIGHT / 2; 0D200h
mov       dx, SCREEN0_SEGMENT
mov       es, dx
xor       ax, ax
mov       di, ax
rep stosw 

cmp       byte ptr ds:[_am_grid], al ; 0
jne       do_draw_grid
done_drawing_grid:
call      AM_drawWalls_
call      AM_drawPlayers_
cmp       byte ptr ds:[_am_cheating], 2
je        do_draw_things
done_drawing_things:
; draw crosshair

;    screen0[(automap_screenwidth*(automap_screenheight+1))/2] = XHAIRCOLORS; // single point for now
mov       dx, SCREEN0_SEGMENT
mov       es, dx
mov       byte ptr es:[(AUTOMAP_SCREENWIDTH*(AUTOMAP_SCREENHEIGHT+1))/2 ], XHAIRCOLORS
;call      AM_drawMarks_  ; inlined

mov       si, OFFSET _markpoints
mov       di, AMMNUMPATCHOFFSETS_FAR_OFFSET
mov       bp, AMMNUMPATCHBYTES_SEGMENT
loop_next_mark:

lods      word ptr cs:[si]
xchg      ax, dx
lods      word ptr cs:[si]
cmp       dx, -1
je        skip_draw_mark

call      CYMTOF16_ 

test      ax, ax
js        skip_draw_mark
cmp       ax, (AUTOMAP_SCREENHEIGHT - 6)
jg        skip_draw_mark
xchg      ax, dx
call      CXMTOF16_ 
test      ax, ax
js        skip_draw_mark
cmp       ax, (AUTOMAP_SCREENWIDTH - 5)
jg        skip_draw_mark
mov       es, bp
push      es
push      word ptr es:[di]  ;  + AMMNUMPATCHOFFSETS_FAR_OFFSET
xor       bx, bx ; FB = 0
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
skip_draw_mark:
inc       di
inc       di
cmp       si, OFFSET _markpoints + (AM_NUMMARKPOINTS * (SIZE MPOINT_T))
jl        loop_next_mark


mov       cx, AUTOMAP_SCREENHEIGHT

mov       bx, AUTOMAP_SCREENWIDTH
xor       ax, ax
cwd
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_MarkRect_addr

POPA_NO_AX_MACRO
retf      

do_draw_grid:

;call      AM_drawGrid_
; inlined


push      bp
mov       bp, sp
sub       sp, 8 ; size of mline


mov       ax, word ptr ds:[_screen_botleft_x]
mov       cx, ax  ; cx = start
mov       bx, ax  ; bx = end
add       bx, word ptr ds:[_screen_viewport_width]
sub       ax, word ptr ds:[_bmaporgx]
jns       dont_do_abs_x
neg       ax
dont_do_abs_x:
and       ax, 07Fh
jz        dont_mod_start_x
skip_sign_adjust:
add       cx, 080h
sub       cx, ax
dont_mod_start_x:

mov       ax, word ptr ds:[_screen_botleft_y]
mov       word ptr ss:[bp - 6], ax  ; am_ml_a.y
add       ax, word ptr ds:[_screen_viewport_height]
mov       word ptr ss:[bp - 2], ax  ; am_ml_b.y

loop_do_next_vertical_line:
cmp       cx, bx
jge       done_with_vertical_grid
mov       word ptr ss:[bp - 4], cx  ; am_ml_b.x
mov       word ptr ss:[bp - 8], cx  ; am_ml_a.x
lea       ax, [bp - 8]
mov       dl, GRIDCOLORS
call      AM_drawMline_
add       cx, 080h
jmp       loop_do_next_vertical_line
done_with_vertical_grid:


mov       ax, word ptr ds:[_screen_botleft_y]
mov       cx, ax  ; cx = start
mov       bx, ax  ; bx = end
add       bx, word ptr ds:[_screen_viewport_height]
sub       ax, word ptr ds:[_bmaporgy]
jns       dont_do_abs_y
neg       ax
dont_do_abs_y:

and       ax, 07Fh
jz        dont_mod_start_y
add       cx, 080h
sub       cx, ax
dont_mod_start_y:


mov       ax, word ptr ds:[_screen_botleft_x]
mov       word ptr ss:[bp - 8], ax  ; am_ml_a.x
add       ax, word ptr ds:[_screen_viewport_width]
mov       word ptr ss:[bp - 4], ax  ; am_ml_b.x

loop_do_next_horizontal_line:
cmp       cx, bx
jge       done_with_horizontal_grid
mov       word ptr ss:[bp - 2], cx  ; am_ml_a.y
mov       word ptr ss:[bp - 6], cx  ; am_ml_b.y
lea       ax, [bp - 8]
mov       dl, GRIDCOLORS
call      AM_drawMline_
add       cx, 080h
jmp       loop_do_next_horizontal_line
done_with_horizontal_grid:

LEAVE_MACRO


jmp       done_drawing_grid

ENDP

PROC    AM_MAP_ENDMARKER_ NEAR
PUBLIC  AM_MAP_ENDMARKER_
ENDP


END