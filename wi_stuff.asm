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

INCLUDE defs.inc
INCLUDE sound.inc
INSTRUCTION_SET_MACRO_NO_MEDIUM


; TODO refactor this file, it sucks.
; TODO: could encode a lot of the wi stuff data in here instead of loaded via doomcode and thus reduce management code in the main binary

;WI_STARTMARKER_ = 0



WIPATCH_YOU_ARE_HERE_L = 0
WIPATCH_YOU_ARE_HERE_R = 1
WIPATCH_SPLAT = 2
WIPATCH_KILLS = 3
WIPATCH_ITEMS = 4
WIPATCH_FINISHED = 5
WIPATCH_TOTAL = 6
WIPATCH_SCRT = 7
WIPATCH_F = 8
WIPATCH_TIME = 9
WIPATCH_PAR = 10
WIPATCH_YOU = 11
WIPATCH_MINUS = 12
WIPATCH_PERCENT = 13
WIPATCH_NUM_0 = 14
WIPATCH_NUM_1 = 15
WIPATCH_NUM_2 = 16
WIPATCH_NUM_3 = 17
WIPATCH_NUM_4 = 18
WIPATCH_NUM_5 = 19
WIPATCH_NUM_6 = 20
WIPATCH_NUM_7 = 21
WIPATCH_NUM_8 = 22
WIPATCH_NUM_9 = 23
WIPATCH_COLON = 24
WIPATCH_SUCKS = 25
WIPATCH_SECRET = 26
WIPATCH_ENTERING = 27

NOSTATE = -1
STATCOUNT = 0
SHOWNEXTLOC = 1



SEGMENT WI_STUFF_TEXT PARA PUBLIC 'CODE'
ASSUME  CS:WI_STUFF_TEXT





PROC   WI_STARTMARKER_ NEAR
PUBLIC WI_STARTMARKER_
ENDP


_NUMANIMS:
db    10, 9, 6
_unloaded:
db 0


_bcnt:
dw 0
_cnt:
dw 0

_cnt_secret:
dw 0
_cnt_items:
dw 0
_cnt_kills:
dw 0
_cnt_par:
dw 0
_cnt_pause:
dw 0
_cnt_time:
dw 0

_sp_state:
dw 0
_acceleratestage:
dw 0
_snl_pointeron:
dw 0

_wbs_ptr:
dw 0


_plrs:
dw 0,0,0,0,0

_state:
db 0

; variety hardcoded indices to look up patch asset locations via WI_GetPatch_
_numRef:
db 14, 15, 16, 17, 18, 19, 20, 21, 22, 23

_yahRef:
db 0, 1
_splatRef:
db 2

_wi_secretexit:
db 0


; lnodex
_lnodex:
dw 000B9h, 00094h, 00045h, 000D1h, 00074h, 000A6h, 00047h, 00087h, 00047h
dw 000FEh, 00061h, 000BCh, 00080h, 000D6h, 00085h, 000D0h, 00094h, 000EBh
dw 0009Ch, 00030h, 001AEh, 00009h, 00182h, 00017h, 000C6h, 0018Ch, 00019h

_lnodey:

dw 000A4h, 0008Fh, 0007Ah, 00066h, 00059h, 00037h, 00038h, 0001Dh, 00018h
dw 00019h, 00032h, 00040h, 0004Eh, 0005Ch, 00082h, 00088h, 0008Ch, 0009Eh
dw 000A8h, 0009Ah, 0005Fh, 0004Bh, 00030h, 00017h, 00030h, 00019h, 00088h

; wbs struct data dumps. maybe reorganize nicely one day?

_epsd0animinfo:
dw 00B00h, 0E003h, 00068h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 0B803h, 000A0h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 07003h, 00088h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 04803h, 00070h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 05803h, 00060h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 04003h, 00030h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 0C003h, 00028h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 08803h, 00010h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 05003h, 00010h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 04003h, 00018h, 00000h, 00000h, 00000h, 00000h, 00000h

_epsd1animinfo:
dw 00B02h, 08001h, 00188h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 08001h, 00288h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 08001h, 00388h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 08001h, 00488h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 08001h, 00588h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 08001h, 00688h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 08001h, 00788h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 0C003h, 00890h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B02h, 08001h, 00888h, 00000h, 00000h, 00000h, 00000h, 00000h

_epsd2animinfo:
dw 00B00h, 06803h, 000A8h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 02803h, 00088h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 0A003h, 00060h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 06803h, 00050h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00B00h, 07803h, 00020h, 00000h, 00000h, 00000h, 00000h, 00000h
dw 00800h, 02803h, 00000h, 00000h, 00000h, 00000h, 00000h, 00000h




_wigraphics:
db "WIURH0"      , 0, 0, 0
db "WIURH1"      , 0, 0, 0
db "WISPLAT"        , 0, 0
_wigraphics_commercial:
db "WIOSTK"      , 0, 0, 0
db "WIOSTI"      , 0, 0, 0
db "WIF", 0, 0, 0, 0, 0, 0
db "WIMSTT"      , 0, 0, 0
db "WIOSTS"      , 0, 0, 0
db "WIOSTF"      , 0, 0, 0
db "WITIME"      , 0, 0, 0
db "WIPAR"    , 0, 0, 0, 0
db "WIMSTAR"        , 0, 0
db "WIMINUS"        , 0, 0
db "WIPCNT"      , 0, 0, 0
db "WINUM0"      , 0, 0, 0
db "WINUM1"      , 0, 0, 0
db "WINUM2"      , 0, 0, 0
db "WINUM3"      , 0, 0, 0
db "WINUM4"      , 0, 0, 0
db "WINUM5"      , 0, 0, 0
db "WINUM6"      , 0, 0, 0
db "WINUM7"      , 0, 0, 0
db "WINUM8"      , 0, 0, 0
db "WINUM9"      , 0, 0, 0
db "WICOLON"        , 0, 0
db "WISUCKS"        , 0, 0
db "WISCRT2"        , 0, 0
db "WIENTER"        , 0, 0

;doom times
_pars:
dw 0041Ah, 00A41h, 01068h, 00C4Eh, 0168Fh, 0189Ch, 0189Ch, 0041Ah, 0168Fh
dw 00C4Eh, 00C4Eh, 00C4Eh, 01068h, 00C4Eh, 03138h, 020D0h, 0041Ah, 0173Eh
dw 00C4Eh, 00627h, 00C4Eh, 01482h, 00C4Eh, 00C4Eh, 0168Fh, 0041Ah, 01275h 

;doom2 times
_cpars:
dw 0041Ah, 00C4Eh, 01068h, 01068h, 00C4Eh, 01482h, 01068h, 01068h
dw 024EAh, 00C4Eh, 01CB6h, 01482h, 01482h, 01482h, 01CB6h, 01482h
dw 0396Ch, 01482h, 01CB6h, 01482h, 020D0h, 01482h, 0189Ch, 01482h
dw 01482h, 02904h, 02D1Eh, 0396Ch, 02904h, 0189Ch, 01068h, 0041Ah


_wianims:
dw OFFSET _epsd0animinfo, OFFSET _epsd1animinfo, OFFSET _epsd2animinfo

; todo return in bx?

PROC WI_GetPatch_ NEAR
PUBLIC WI_GetPatch_

push      bx
xor       ah, ah
xchg      ax, bx
sal       bx, 1
mov       ax, WIOFFSETS_SEGMENT
mov       es, ax
mov       ax, word ptr es:[bx]
mov       dx, WIGRAPHICSPAGE0_SEGMENT
mov       es, dx
pop       bx
ret

ENDP

PROC WI_GetPatchESBX_ NEAR
PUBLIC WI_GetPatchESBX_

xchg      ax, bx
shl       bx, 1		; word lookup
mov       ax, WIOFFSETS_SEGMENT
mov       es, ax
mov       bx, word ptr es:[bx]
mov       ax, WIGRAPHICSPAGE0_SEGMENT
mov       es, ax
ret

ENDP

; M_Random preserving es:bx
PROC WI_MRandomLocal_ NEAR
PUBLIC WI_MRandomLocal_
;    rndindex = (rndindex+1)&0xff;
;    return rndtable[rndindex];

push      es
push      bx

mov       es, word ptr ds:[_RNDTABLE_SEGMENT_PTR]
xor       ax, ax
mov       bx, ax
inc       byte ptr ds:[_rndindex]
mov       bl, byte ptr ds:[_rndindex]
mov       al, byte ptr es:[bx]

pop       bx
pop       es

ret

ENDP


PROC   WI_slamBackground_ NEAR
PUBLIC WI_slamBackground_


push      cx
push      di
push      si

mov       ax, SCREEN0_SEGMENT
mov       es, ax
mov       ah, (SCREEN1_SEGMENT SHR 8)
mov       ds, ax

xor       si, si
xor       di, di
mov       cx, (SCREENWIDTH * SCREENHEIGHT) / 2
rep       movsw 

push      ss
pop       ds


mov       di, OFFSET _dirtybox
xor       ax, ax
mov       word ptr ds:[di + 2 * BOXBOTTOM], ax
mov       word ptr ds:[di + 2 * BOXLEFT],   ax
mov       word ptr ds:[di + 2 * BOXTOP],    SCREENHEIGHT - 1
mov       word ptr ds:[di + 2 * BOXRIGHT],  SCREENWIDTH - 1


pop       si
pop       di
pop       cx

ret       

ENDP

PROC   WI_drawLF_ NEAR
PUBLIC WI_drawLF_



PUSHA_NO_AX_OR_BP_MACRO
push      bp
mov       bp, sp

mov       cx, WIGRAPHICSLEVELNAME_SEGMENT
mov       es, cx

xor       si, si

; patch



; x
mov       ax, SCREENWIDTH
sub       ax, word ptr es:[si + PATCH_T.patch_width]
sar       ax, 1

; y
mov       dx, 2				; y = 2

mov       si, word ptr es:[si + PATCH_T.patch_height]			; grab height of lname
;screen
xor       bx, bx
call      WI_DrawPatch_


mov       cx, WIOFFSETS_SEGMENT
mov       es, cx

mov       di, word ptr es:[WIPATCH_FINISHED * 2] ; todo constants

mov       cx, WIGRAPHICSPAGE0_SEGMENT
mov       es, cx
mov       bx, di

;	y += (5 * (lname->height)) >>2;
mov       dx, si
SHIFT_MACRO shl dx 2
add       dx, si		; 5 * height
SHIFT_MACRO sar dx 2
inc       dx			; += original 2
inc       dx			; += original 2

; x
mov       ax, SCREENWIDTH
sub       ax, word ptr es:[di]
sar       ax, 1


call  WI_DrawPatch_

LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
ret      

ENDP

PROC   WI_drawEL_ NEAR
PUBLIC WI_drawEL_


push      bx
push      cx
push      dx
mov       bx, WIPATCH_ENTERING * 2
mov       ax, WIOFFSETS_SEGMENT
mov       dx, WIGRAPHICSPAGE0_SEGMENT
mov       es, ax
mov       ax, SCREENWIDTH
mov       bx, word ptr es:[bx]
mov       es, dx

sub       ax, word ptr es:[bx + PATCH_T.patch_width]
mov       dx, 2
sar       ax, 1

call  WI_DrawPatch_
mov       ax, WIGRAPHICSLEVELNAME_SEGMENT
mov       bx, MAX_LEVEL_COMPLETE_GRAPHIC_SIZE
mov       es, ax
mov       dx, word ptr es:[bx + PATCH_T.patch_height]
mov       ax, dx

SHIFT_MACRO shl ax 2

add       dx, ax
mov       ax, SCREENWIDTH
SHIFT_MACRO sar dx 2
sub       ax, word ptr es:[bx + PATCH_T.patch_width]
add       dx, 2
sar       ax, 1

call      WI_DrawPatch_
pop       dx
pop       cx
pop       bx
ret       


ENDP



PROC   WI_drawOnLnode_ NEAR
PUBLIC WI_drawOnLnode_

push  bx
push  cx
push  si
push  di

;int16_t index = wbs->epsd*10 + n;

mov   si, dx					; store cref in si.

mov   di, word ptr cs:[_wbs_ptr ]    ; 
xor   bx, bx
xchg  ax, bx					; store n in bx
mov   ah, byte ptr ds:[di + WBSTARTSTRUCT_T.wbss_epsd]	; wbs->epsd

db    0D5h, 00Ah					; AAD to mul by 10

add   bx, ax						; plus n
shl   bx, 1   ; word lookup

mov   di, word ptr cs:[bx + _lnodex - OFFSET WI_STARTMARKER_]		; di = lnodex

mov   dx, word ptr cs:[bx + _lnodey - OFFSET WI_STARTMARKER_]		; dx = lnodey

mov   cx, 2

loop_drawonlnode:
mov   ax, cx
;     xor ah ah for free since cx is 0 or 1..
lods  byte ptr cs:[si]							    ;  WI_GetPatch(cRef[i]);
call  WI_GetPatchESBX_

;		left = lnodeX - (ci->leftoffset);
;		if (left >= 0
mov   ax, di						; copy lonodex
sub   ax, word ptr es:[bx + 4]
cmp   ax, 0
jnge  failed_inc_i				

; 		right = left + (ci->width)
;		&& right < SCREENWIDTH

add   ax, word ptr es:[bx + 0]
cmp   ax, SCREENWIDTH
jge   failed_inc_i

;       top = lnodeY - (ci->topoffset);
;			&& top >= 0

mov   ax, dx						; copy lnodey
sub   ax, word ptr es:[bx + 6]
cmp   ax, 0
jnge  failed_inc_i	

;		bottom = top + (ci->height);
;			&& bottom < SCREENHEIGHT

add   ax, word ptr es:[bx + 2]
cmp   ax, SCREENHEIGHT
jge   failed_inc_i

; draw patch


;		V_DrawPatch(lnodeX, lnodeY, FB, (WI_GetPatch(cRef[i])));

mov   ax, di		; lnodex
; dx is already lnodey
; es already set


call  WI_DrawPatch_

jmp   exit_wi_drawonlnode

failed_inc_i:
loop  loop_drawonlnode

exit_wi_drawonlnode:
pop   di
pop   si
pop   cx
pop   bx
ret   


ENDP



PROC   WI_updateAnimatedBack_ NEAR
PUBLIC WI_updateAnimatedBack_

push  bx
push  cx
push  dx

cmp   byte ptr ds:[_commercial], 0
jne   exit_update_animated_back   ; not for doom2 
mov   bx, word ptr cs:[_wbs_ptr ]    ; 

mov   al, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd]         ; get epsd
cmp   al, 2                     ; > epsd 2?
jg    exit_update_animated_back
cbw

mov   dl, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_next]     ; cache wbs->next for loop

xor   cx, cx                    ; zero out ch..
xchg  ax, bx                    ; bx gets epsd

mov   cl, byte ptr cs:[bx + _NUMANIMS - OFFSET WI_STARTMARKER_] ; cl gets num anims (loop amount)
sal   bx, 1                             ; word lookup 
mov   bx, word ptr cs:[bx + _wianims - OFFSET WI_STARTMARKER_]  ; cs:bx is wianims

loop_update_animated_back:

mov   ax, word ptr cs:[_bcnt ]
cmp   ax, word ptr cs:[bx + 0Ch]
jne   finish_update_anim_loop_iter


mov   al, byte ptr cs:[bx]      ; get anim type
cmp   al, ANIM_RANDOM
je    update_anim_random
cmp   al, ANIM_ALWAYS
je    update_anim_always
cmp   al, ANIM_LEVEL
je    update_anim_level

; fall thru
finish_update_anim_loop_iter:
add   bx, (SIZE WIANIM_T)
loop  loop_update_animated_back

exit_update_animated_back:

pop   dx
pop   cx
pop   bx
ret   


update_anim_level:
cmp   byte ptr cs:[_state - WI_STARTMARKER_], 0
jne   continue_level_check
cmp   cx, 7
je    finish_update_anim_loop_iter
continue_level_check:
mov   al, dl                        ; dh is cached wbs next

cmp   al, byte ptr cs:[bx + 5]
jne   finish_update_anim_loop_iter
inc   byte ptr cs:[bx + 0Eh]        ; increment ctr
mov   al, byte ptr cs:[bx + 0Eh]
cmp   al, byte ptr cs:[bx + 2]
jne   dont_dec_ctr
dec   byte ptr cs:[bx + 0Eh]
dont_dec_ctr:

update_anim_set_nexttic_to_bcnt_plus_period:
xor   ax, ax
mov   al, byte ptr cs:[bx + 1]
add   ax, word ptr cs:[_bcnt]
mov   word ptr cs:[bx + 0Ch], ax

jmp   finish_update_anim_loop_iter

update_anim_random:
inc   byte ptr cs:[bx + 0Eh]
mov   al, byte ptr cs:[bx + 0Eh]
cmp   al, byte ptr cs:[bx + 2]
jne   update_anim_set_nexttic_to_bcnt_plus_period


call  WI_MRandomLocal_
div   byte ptr cs:[bx + 5]
mov   al, ah
xor   ah, ah

add   ax, word ptr cs:[_bcnt]
mov   word ptr cs:[bx + 0Ch], ax
jmp   finish_update_anim_loop_iter

update_anim_always:
inc   byte ptr cs:[bx + 0Eh]
mov   al, byte ptr cs:[bx + 0Eh]
cmp   al, byte ptr cs:[bx + 2]
jnge  update_anim_set_nexttic_to_bcnt_plus_period
mov   byte ptr cs:[bx + 0Eh], 0

jmp   update_anim_set_nexttic_to_bcnt_plus_period





ENDP





PROC   WI_drawAnimatedBack_ NEAR
PUBLIC WI_drawAnimatedBack_

push  bx
push  cx
push  dx
push  di
cmp   byte ptr ds:[_commercial], 0
jne   exit_draw_animated_back   ; not for doom2 
mov   bx, word ptr cs:[_wbs_ptr]    ; 

mov   al, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd]         ; get epsd
cmp   al, 2                     ; > epsd 2?
jg    exit_draw_animated_back
cbw

xor   cx, cx                    ; zero out ch..
xchg  ax, bx                    ; bx gets epsd

mov   cl, byte ptr cs:[bx + _NUMANIMS - OFFSET WI_STARTMARKER_] ; cl gets num anims (loop amount)
sal   bx, 1                             ; word lookup 
mov   di, word ptr cs:[bx + _wianims - OFFSET WI_STARTMARKER_]  ; cs:bx is wianims


loop_draw_animated_back:
mov   al, byte ptr cs:[di + 0Eh]        ; get ctr
test  al, al
jnge  finish_draw_anim_loop_iter
cbw  

; draw patch

mov   dx, word ptr cs:[di + 3]  ; get loc.x and loc.y here

sal   ax, 1
mov   bx, di
add   bx, ax

mov   bx, word ptr cs:[bx + 6] ; pref lookup
sal   bx, 1
mov   ax, WIANIMOFFSETS_SEGMENT
mov   es, ax


mov   bx, word ptr es:[bx]  ; anim patch offset

mov   ax, WIANIMSPAGE_SEGMENT
mov   es, ax  ; segment arg to drawpatch



xor   ax, ax                ; set loc args
mov   al, dl
mov   dl, dh
xor   dh, dh

call  WI_DrawPatch_



finish_draw_anim_loop_iter:
add   di, (SIZE WIANIM_T)
loop  loop_draw_animated_back


exit_draw_animated_back:
pop   di
pop   dx
pop   cx
pop   bx
ret   




ENDP


PROC   WI_initShowNextLoc_ NEAR
PUBLIC WI_initShowNextLoc_


mov   byte ptr cs:[_state], 1
mov   word ptr cs:[_cnt], SHOWNEXTLOCDELAY * TICRATE
mov   word ptr cs:[_acceleratestage], 0

; fall thru

ENDP

PROC   WI_initAnimatedBack_ NEAR
PUBLIC WI_initAnimatedBack_

push  bx
push  cx
push  dx
cmp   byte ptr ds:[_commercial], 0
jne   exit_init_animated_back   ; not for doom2 
mov   bx, word ptr cs:[_wbs_ptr]    ; 

mov   al, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd]         ; get epsd
cmp   al, 2                     ; > epsd 2?
jg    exit_init_animated_back
cbw
xor   cx, cx                    ; zero out ch..

xchg  ax, bx                    ; bx gets epsd

mov   cl, byte ptr cs:[bx + _NUMANIMS - OFFSET WI_STARTMARKER_] ; cl gets num anims (loop amount)

sal   bx, 1                             ; word lookup 
mov   bx, word ptr cs:[bx + _wianims - OFFSET WI_STARTMARKER_]  ; cs:bx is wianims
loop_init_animated_back:

mov   al, byte ptr cs:[bx]              ; get anim type
mov   byte ptr cs:[bx + 0Eh], -1        ; ctr -1
cmp   al, ANIM_ALWAYS
je    init_anim_always
cmp   al, ANIM_RANDOM
je    init_anim_random
cmp   al, ANIM_LEVEL
je    init_anim_level
finish_init_anim_loop_iter:
add   bx, (SIZE WIANIM_T)               ; bx is next wi_anim


loop  loop_init_animated_back


exit_init_animated_back:

pop   dx
pop   cx
pop   bx
ret   

init_anim_always:
mov   dl, byte ptr cs:[bx + 1]
call  WI_MRandomLocal_
jmp   do_modulostep

init_anim_random:
mov   dl, byte ptr cs:[bx + 5]
call  WI_MRandomLocal_

do_modulostep:

div   dl
mov   al, ah            ; take modulo result.
xor   ah, ah

add_bcnt_plus_1_etc:
; plus bcnt plus 1
add   ax, word ptr cs:[_bcnt]
inc   ax
mov   word ptr cs:[bx + 0Ch], ax    ; write nexttic

jmp   finish_init_anim_loop_iter

init_anim_level:
xor   ax, ax
jmp   add_bcnt_plus_1_etc



ENDP


;int16_t __near WI_drawNum ( int16_t x, int16_t y, int16_t n, int16_t digits ){


PROC   WI_drawNum_ NEAR
PUBLIC WI_drawNum_

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   di, ax                    ; di stores x
mov   word ptr [bp - 2], dx     ; y
mov   si, bx                    ; si holds n
mov   al, byte ptr cs:[_numRef]
call  WI_GetPatch_
mov   bx, ax

mov   ax, word ptr es:[bx]      ; fontwidth
mov   word ptr [bp - 4], ax
test  cx, cx
jl    digits_negative
check_neg:
test  si, si
jl    set_neg_on
xor   ax, ax
neg_set:
mov   word ptr [bp - 6], ax
test  ax, ax
je    dont_neg_n
neg   si
dont_neg_n:
cmp   si, 1994				; if non-number dont draw it
je    exit_drawnum
loop_digits:
dec   cx
js    exit_digits_loop      ; catch -1 with js
mov   ax, si                ; ax gets n
mov   bx, 10
cwd   
idiv  bx
mov   bx, dx                ; bx gets modulo..
mov   si, ax                ; si updated

; todo just add by 14?
mov   al, byte ptr cs:[bx + _numRef - OFFSET WI_STARTMARKER_]
sub   di, word ptr [bp - 4]     ; x -= fontwidth

call  WI_GetPatch_
xchg  ax, bx
mov   dx, word ptr [bp - 2]     ; set y
mov   ax, di                    ; set x

call  WI_DrawPatch_

jmp   loop_digits
digits_negative:

; calculate digits
test  si, si
jne   not_zero
mov   cx, 1
jmp   check_neg
not_zero:
mov   ax, si
xor   cx, cx
test  si, si
je    check_neg
mov   bx, 10
loop_div_10:
cwd   
idiv  bx
inc   cx
test  ax, ax
jne   loop_div_10
jmp   check_neg
set_neg_on:
mov   ax, 1
jmp   neg_set
exit_drawnum:
xor   ax, ax
LEAVE_MACRO 
pop   di
pop   si
ret   
exit_digits_loop:
cmp   word ptr [bp - 6], 0
je    return_x_and_exit
mov   al, WIPATCH_MINUS
call  WI_GetPatch_
sub   di, 8

mov   dx, word ptr [bp - 2]
xchg  ax, bx
mov   ax, di
call  WI_DrawPatch_
return_x_and_exit:
mov   ax, di
LEAVE_MACRO 
pop   di
pop   si
ret   

ENDP


PROC   WI_drawPercent_ NEAR
PUBLIC WI_drawPercent_


push  cx
push  si
push  di
mov   si, ax
mov   di, dx
mov   cx, bx
test  bx, bx
jnge  exit_draw_percent

mov   al, WIPATCH_PERCENT
call  WI_GetPatch_
xchg  ax, bx

mov   dx, di
mov   ax, si
call  WI_DrawPatch_
mov   bx, cx
mov   cx, -1
mov   dx, di
mov   ax, si
call  WI_drawNum_
exit_draw_percent:
pop   di
pop   si
pop   cx
ret   

ENDP

PROC   WI_drawTime_ NEAR
PUBLIC WI_drawTime_


push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
push  ax
push  dx
mov   di, bx
test  bx, bx
jl    exit_wi_drawtime
cmp   bx, (61*59)
jg    draw_sucks
mov   al, WIPATCH_COLON
mov   si, 1
call  WI_GetPatch_
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 2], dx
loop_divide_60:
mov   ax, di
cwd   
idiv  si
mov   bx, 60
cwd   
idiv  bx
mov   bx, dx
mov   ax, 60
mul   si
xchg  ax, si
mov   cx, 2
les   dx, dword ptr [bp - 8]
mov   ax, es
call  WI_drawNum_
les   bx, dword ptr [bp - 4]
sub   ax, word ptr es:[bx]
mov   word ptr [bp - 6], ax
cmp   si, 60
jne   check_tdiv
do_draw_patch:

les   dx, dword ptr [bp - 8]
mov   ax, es

les   bx, dword ptr [bp - 4]
call  WI_DrawPatch_
do_next_drawtime_iter:
mov   ax, di
cwd   
idiv  si
test  ax, ax
jne   loop_divide_60
exit_wi_drawtime:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   

check_tdiv:
mov   ax, di
cwd   
idiv  si
test  ax, ax
jne   do_draw_patch
jmp   do_next_drawtime_iter
draw_sucks:
mov   al, WIPATCH_SUCKS
call  WI_GetPatch_
xchg  ax, bx
mov   si, ax

mov   dx, word ptr [bp - 8]
mov   ax, word ptr [bp - 6]
sub   ax, word ptr es:[si]
call  WI_DrawPatch_
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   

ENDP




PROC   WI_initNoState_ NEAR
PUBLIC WI_initNoState_

mov   byte ptr cs:[_state], -1
mov   word ptr cs:[_cnt], 10
mov   word ptr cs:[_acceleratestage], 0
ret   

ENDP



PROC   WI_updateShowNextLoc_ NEAR
PUBLIC WI_updateShowNextLoc_

call  WI_updateAnimatedBack_
dec   word ptr cs:[_cnt]
je    WI_initNoState_
cmp   word ptr cs:[_acceleratestage], 0
jne   WI_initNoState_
mov   ax, word ptr cs:[_cnt]
and   ax, 31
cmp   ax, 20
jae   set_ptr_off
mov   byte ptr cs:[_snl_pointeron], 1
ret   
set_ptr_off:
mov   byte ptr cs:[_snl_pointeron], 0
ret   




ENDP

PROC   WI_drawNoState_ NEAR
PUBLIC WI_drawNoState_

mov   byte ptr cs:[_snl_pointeron], 1

    ; fall thru
ENDP

PROC   WI_drawShowNextLoc_ NEAR
PUBLIC WI_drawShowNextLoc_

push  bx
push  cx
push  dx
call  WI_slamBackground_
call  WI_drawAnimatedBack_
cmp   byte ptr ds:[_commercial], 0
jne   skip_drawing_pointer
mov   bx, word ptr cs:[_wbs_ptr]
cmp   byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd], 2
jg    drawel_and_exit

;		last = (wbs->last == 8) ? wbs->next - 1 : wbs->last;

xor   ax, ax                ; zero out ah
mov   al, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_last]
cmp   al, 8
jne   set_last
mov   al, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_next]
dec   ax
set_last:
mov   cx, ax
xor   bx, bx
test  ax, ax

jl    done_with_splat
loop_splat:
mov   dx, OFFSET _splatRef
mov   ax, bx
inc   bx
call  WI_drawOnLnode_
cmp   bx, cx
jle   loop_splat
done_with_splat:

; check secret
mov   bx, word ptr cs:[_wbs_ptr]
cmp   byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_didsecret], 0
je    skip_drawing_secret_splat
mov   dx, OFFSET _splatRef
mov   ax, 8
call  WI_drawOnLnode_

skip_drawing_secret_splat:
cmp   byte ptr cs:[_snl_pointeron], 0
je    skip_drawing_pointer
mov   al, byte ptr ds:[bx + 3]
mov   dx, OFFSET _yahRef
cbw  
call  WI_drawOnLnode_

skip_drawing_pointer:
cmp   byte ptr ds:[_commercial], 0
je    drawel_and_exit
mov   bx, word ptr cs:[_wbs_ptr]
cmp   byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_next], 30 ; dont show for wolf level
jne   drawel_and_exit

exit_this_func_todo:
pop   dx
pop   cx
pop   bx
ret   

drawel_and_exit:
call  WI_drawEL_
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC   WI_initStats_ NEAR
PUBLIC WI_initStats_

xor   ax, ax
mov   byte ptr cs:[_state], al
mov   word ptr cs:[_acceleratestage], ax
mov   word ptr cs:[_sp_state], 1
mov   word ptr cs:[_cnt_pause], TICRATE
dec   ax    ; ax -1
mov   word ptr cs:[_cnt_secret], ax
mov   word ptr cs:[_cnt_items], ax
mov   word ptr cs:[_cnt_kills], ax
mov   word ptr cs:[_cnt_par], ax
mov   word ptr cs:[_cnt_time], ax
jmp   WI_initAnimatedBack_

ENDP




PROC   WI_updateStats_ NEAR
PUBLIC WI_updateStats_

push  bx
push  cx
push  dx

call  WI_updateAnimatedBack_
mov   bx, word ptr cs:[_wbs_ptr]

cmp   word ptr cs:[_acceleratestage], 0
je    skip_accelerate
cmp   word ptr cs:[_sp_state], 10
je    skip_accelerate
xor   ax, ax
mov   word ptr cs:[_acceleratestage], ax

mov   ax, 100
mul   word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_skills]
idiv  word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxkills]
mov   word ptr cs:[_cnt_kills], ax

mov   ax, 100
mul   word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_sitems]
idiv  word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxitems]
mov   word ptr cs:[_cnt_items], ax

mov   ax, 100
mul   word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_ssecret]
idiv  word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxsecret]
mov   word ptr cs:[_cnt_secret], ax

mov   ax, word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_stime]
mov   word ptr cs:[_cnt_time], ax
mov   ax, word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_partime]
mov   cx, TICRATE
cwd   
idiv  cx
mov   dl, SFX_BAREXP
mov   word ptr cs:[_cnt_par], ax

call  WI_StartSound_

mov   word ptr cs:[_sp_state], 10

done_checking_sp_state:
cmp   word ptr cs:[_acceleratestage], 0
jne   play_sgcock_sfx

exit_wi_updatestats:
pop   dx
pop   cx
pop   bx
ret   


skip_accelerate:

mov   ax, word ptr cs:[_sp_state]
cmp   ax, 2
jne   sp_state_not_2
add   word ptr cs:[_cnt_kills], ax
test  byte ptr cs:[_bcnt], 3
jne   do_update_kills
mov   dl, SFX_PISTOL

call  WI_StartSound_

do_update_kills:

mov   ax, 100
mul   word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_skills]
idiv  word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxkills]
cmp   ax, word ptr cs:[_cnt_kills]
jg    exit_wi_updatestats
mov   word ptr cs:[_cnt_kills], ax

jmp   play_barexp_sfx_inc_state_exit


play_sgcock_sfx:
mov   dl, SFX_SGCOCK
call  WI_StartSound_

cmp   byte ptr ds:[_commercial], 0
je    do_initshownextloc
call  WI_initNoState_
pop   dx
pop   cx
pop   bx
ret   
do_initshownextloc:
call  WI_initShowNextLoc_
pop   dx
pop   cx
pop   bx
ret   





sp_state_not_2:
cmp   ax, 4
jne   sp_state_not_4
add   word ptr cs:[_cnt_items], 2
test  byte ptr cs:[_bcnt], 3
jne   do_update_items
mov   dl, sfx_pistol
call  WI_StartSound_

do_update_items:
mov   ax, 100
mul   word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_sitems]
idiv  word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxitems]
cmp   ax, word ptr cs:[_cnt_items]
jg    exit_wi_updatestats_2

mov   word ptr cs:[_cnt_items], ax
play_barexp_sfx_inc_state_exit:

mov   dl, SFX_BAREXP
call  WI_StartSound_

inc   word ptr cs:[_sp_state]
exit_wi_updatestats_2:
pop   dx
pop   cx
pop   bx
ret   




sp_state_not_4:
cmp   ax, 6
jne   sp_state_not_6
add   word ptr cs:[_cnt_secret], 2
test  byte ptr cs:[_bcnt], 3
jne   do_update_secrets
mov   dl, SFX_PISTOL
call  WI_StartSound_

do_update_secrets:
mov   ax, 100
mul   word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_ssecret]
idiv  word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxsecret]
cmp   ax, word ptr cs:[_cnt_secret]
jg    exit_wi_updatestats_2
mov   word ptr cs:[_cnt_secret], ax
jmp   play_barexp_sfx_inc_state_exit





sp_state_not_6:
cmp   ax, 8
jne   sp_state_not_8
test  byte ptr cs:[_bcnt], 3
jne   dont_play_pistol_sfx_4
mov   dl, SFX_PISTOL
call  WI_StartSound_

dont_play_pistol_sfx_4:
add   word ptr cs:[_cnt_time], 3
mov   ax, word ptr cs:[_cnt_time]
cmp   ax, word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_stime]
jl    dont_set_time
mov   ax, word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_stime]
mov   word ptr cs:[_cnt_time], ax
dont_set_time:

mov   ax, word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_partime]
cwd   
mov   cx, TICRATE
idiv  cx
add   word ptr cs:[_cnt_par], 3
cmp   ax, word ptr cs:[_cnt_par]
jg    jump_to_exit_wi_updatestats_3
mov   word ptr cs:[_cnt_par], ax
mov   ax, word ptr cs:[_cnt_time]
cmp   ax, word ptr cs:[_plrs + WBPLAYERSTRUCT_T.wbos_stime]
jl    jump_to_exit_wi_updatestats_3
mov   dl, SFX_BAREXP

call  WI_StartSound_

inc   word ptr cs:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
jump_to_exit_wi_updatestats_3:
jmp   exit_wi_updatestats

sp_state_not_8:
cmp   ax, 10
jne   sp_state_not_10
jmp   done_checking_sp_state
sp_state_not_10:
test  byte ptr cs:[_sp_state], 1
jne   sp_state_is_odd
jump_to_exit_wi_updatestats:
jmp   exit_wi_updatestats
sp_state_is_odd:
dec   word ptr cs:[_cnt_pause]
jne   jump_to_exit_wi_updatestats
mov   word ptr cs:[_cnt_pause], TICRATE
inc   word ptr cs:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC   WI_drawStats_ NEAR
PUBLIC WI_drawStats_

push  bx
push  cx
push  dx
push  si
mov   al, byte ptr cs:[_numRef]	; patch numref 0

call  WI_GetPatch_
mov   si, ax

mov   dx, word ptr es:[si + PATCH_T.patch_height]  
mov   ax, dx
SHIFT_MACRO shl ax 2
sub   ax, dx
cwd   
sub   ax, dx
sar   ax, 1
mov   si, ax
call  WI_slamBackground_
call  WI_drawAnimatedBack_
call  WI_drawLF_
mov   al, WIPATCH_KILLS
call  WI_GetPatch_
xchg  ax, bx
mov   dx, SP_STATSY
mov   ax, dx ; SP_STATSX
call  WI_DrawPatch_
mov   dx, SP_STATSY
mov   ax, SCREENWIDTH - SP_STATSX
mov   bx, word ptr cs:[_cnt_kills]
call  WI_drawPercent_
mov   al, WIPATCH_ITEMS
call  WI_GetPatch_

xchg  ax, bx

lea   dx, [si + SP_STATSY]
mov   ax, SP_STATSX

call  WI_DrawPatch_
mov   ax, SCREENWIDTH - SP_STATSX
mov   bx, word ptr cs:[_cnt_items]
lea   dx, [si + SP_STATSY]

call  WI_drawPercent_
mov   al, WIPATCH_SECRET
call  WI_GetPatch_
xchg  ax, bx
shl   si, 1

lea   dx, [si + SP_STATSY]
mov   ax, SP_STATSX
call  WI_DrawPatch_

mov   ax, SCREENWIDTH - SP_STATSX
mov   bx, word ptr cs:[_cnt_secret]
lea   dx, [si + SP_STATSY]

call  WI_drawPercent_
mov   al, WIPATCH_TIME
call  WI_GetPatch_
xchg  ax, bx
mov   dx, SP_TIMEY
mov   ax, 16
call  WI_DrawPatch_

mov   dx, SP_TIMEY
mov   ax, SCREENWIDTH/2 - SP_TIMEX
mov   bx, word ptr cs:[_cnt_time]
call  WI_drawTime_
mov   bx, word ptr cs:[_wbs_ptr]
cmp   byte ptr ds:[bx], 3
jl    done_exit_draw_stats
pop   si
pop   dx
pop   cx
pop   bx
ret   
done_exit_draw_stats:
mov   al, WIPATCH_PAR
call  WI_GetPatch_
xchg  ax, bx
mov   dx, SP_TIMEY
mov   ax, SCREENWIDTH/2 + SP_TIMEX
call  WI_DrawPatch_

mov   dx, SP_TIMEY
mov   ax, SCREENWIDTH - SP_TIMEX
mov   bx, word ptr cs:[_cnt_par]
call  WI_drawTime_
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP



str_wi_name1:
db "INTERPIC", 0
str_wi_name2:
db "WIMAP0", 0

; this function is a mess and the loop could be cleaned up but it works.
PROC   WI_loadData_ NEAR
PUBLIC WI_loadData_

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 036h
mov   ax, ds
lea   di, [bp - 036h]
mov   es, ax
mov   si, OFFSET str_wi_name1
push    cs
pop     ds
movsw 
movsw 
movsw 
movsw 
;movsb 
lea   di, [bp - 02Ch]
mov   si, OFFSET str_wi_name2
movsw 
movsw 
movsw 
;movsw 
movsb 
push    ss
pop     ds

lea   di, [bp - 02Ch]
cmp   byte ptr ds:[_commercial], 0
je    add_episode_to_name
lea   di, [bp - 036h]
name_set:
mov   bx, word ptr cs:[_wbs_ptr]
cmp   byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd], 3
jne   dont_set_name1
lea   di, [bp - 036h]
dont_set_name1:
mov   ax, di
mov   dx, ds
call  dword ptr ds:[_V_DrawFullscreenPatch_FromIntermission_addr]

mov   al, byte ptr ds:[_commercial]
test  al, al
je    load_assets
done_loading_assets:



LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret   


add_episode_to_name:
mov   bx, word ptr cs:[_wbs_ptr]
mov   al, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd]
add   byte ptr [bp - 027h], al
jmp   name_set
load_assets:

mov   bx, word ptr cs:[_wbs_ptr]
cmp   byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd], 3
jge   done_loading_assets
xor   ah, ah
mov   word ptr [bp - 8], WIANIMSPAGE_SEGMENT
mov   word ptr [bp - 016h], ax
mov   word ptr [bp - 6], ax
mov   word ptr [bp - 012h], ax
mov   word ptr [bp - 0Ah], ax
mov   word ptr [bp - 014h], ax

loop_load_anim:
mov   bx, word ptr cs:[_wbs_ptr]
mov   al, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd]
cbw  
mov   bx, ax
mov   al, byte ptr cs:[bx + _NUMANIMS - OFFSET WI_STARTMARKER_]
cbw  
cmp   ax, word ptr [bp - 0Ah]
jle   done_loading_assets
shl   bx, 1
mov   word ptr [bp - 2], 0
mov   dx, word ptr cs:[bx + _wianims - OFFSET WI_STARTMARKER_]
mov   ax, cs
mov   bx, word ptr [bp - 014h]
mov   word ptr [bp - 0Eh], ax
mov   word ptr [bp - 0Ch], ax
add   bx, dx
mov   ax, word ptr [bp - 016h]
mov   word ptr [bp - 010h], bx
add   ax, ax
mov   word ptr [bp - 4], bx
mov   word ptr [bp - 018h], ax
continue_finish_load_loop_iter:
les   bx, dword ptr [bp - 010h]
mov   al, byte ptr es:[bx + 2]
cbw  
cmp   ax, word ptr [bp - 2] ; check count
jg    check_for_load_hack
add   word ptr [bp - 014h], (SIZE WIANIM_T)
inc   word ptr [bp - 0Ah]
jmp   loop_load_anim
check_for_load_hack:
mov   bx, word ptr cs:[_wbs_ptr]
cmp   byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd], 1
jne   dont_do_load_hack
jmp   continue_check_for_load_hack
dont_do_load_hack:
mov   bx, word ptr cs:[_wbs_ptr]



; "WIA" 57 49 41

mov   al, 041h					
mov   ah, byte ptr ds:[bx + WBSTARTSTRUCT_T.wbss_epsd]			; wbs->epsd
add   ah, 030h					; '0' char

mov   word ptr [bp - 022h], 04957h  ; "WI"
mov   word ptr [bp - 020h], ax      ; "A#"

mov   ax, word ptr [bp - 0Ah]
db    0D4h, 00Ah	    ; divide by 10 using AAM
xchg  al, ah
add   ax, 03030h				; add '0' to each character
mov   word ptr [bp - 01Eh], ax      ; "##"

mov   ax, word ptr [bp - 2]
db    0D4h, 00Ah	    ; divide by 10 using AAM
xchg  al, ah
add   ax, 03030h				; add '0' to each character
mov   word ptr [bp - 01Ch], ax       ; "##"
mov   byte ptr [bp - 01Ah], 0        ; null term






mov   bx, word ptr [bp - 012h]
lea   ax, [bp - 022h]
mov   cx, word ptr [bp - 8]


call  dword ptr ds:[_W_GetNumForName_addr]

mov   si, ax


call  dword ptr ds:[_W_LumpLength_addr]


mov   dx, ax
mov   ax, si

call  dword ptr ds:[_W_CacheLumpNumDirect_addr]

add   word ptr [bp - 012h], dx
mov   ax, WIANIMOFFSETS_SEGMENT
mov   bx, word ptr [bp - 018h]
add   word ptr [bp - 018h], 2
mov   es, ax
mov   ax, word ptr [bp - 6]
add   word ptr [bp - 6], dx
mov   word ptr es:[bx], ax
mov   ax, word ptr [bp - 016h]
mov   es, word ptr [bp - 0Ch]
mov   bx, word ptr [bp - 4]
inc   word ptr [bp - 016h]
done_with_load_hack:
finish_load_loop_iter:

mov   word ptr es:[bx + 6], ax
add   word ptr [bp - 4], 2
inc   word ptr [bp - 2]
jmp   continue_finish_load_loop_iter
continue_check_for_load_hack:
cmp   word ptr [bp - 0Ah], 8
je    do_load_hack
jmp   dont_do_load_hack
do_load_hack:

;						// HACK ALERT!
;						anim->pRef[i] = epsd1animinfo[4].pRef[i];



mov   bx, word ptr [bp - 2]

sal   bx, 1
mov   ax, word ptr cs:[bx + _epsd1animinfo + 046h - OFFSET WI_STARTMARKER_] ; 046h is the offset for this field..
mov   es, word ptr [bp - 0Ch]
mov   bx, word ptr [bp - 4]
jmp   done_with_load_hack

ENDP






PROC   WI_updateNoState_ NEAR
PUBLIC WI_updateNoState_

call  WI_updateAnimatedBack_

dec   word ptr cs:[_cnt]
je    WI_End_
ret   

ENDP

WI_End_:
WI_unloadData_:


mov   byte ptr cs:[_unloaded - OFFSET WI_STARTMARKER_], 1

; fall thru to G_WorldDone_.... but dont like that.



PROC   G_WorldDone_ NEAR
PUBLIC G_WorldDone_

mov   byte ptr ds:[_gameaction], 8
cmp   byte ptr cs:[_wi_secretexit], 0
je    continue_world_done

did_secret_stuff:
mov   byte ptr ds:[_player + 061h], 1 	; player didsecret


continue_world_done:

cmp   byte ptr ds:[_commercial], 0
je    exit_worlddone

mov   al, byte ptr ds:[_gamemap]
cmp   al, 15
jae   gamemap_ae_15
cmp   al, 11
je    gamemap_finalesetup
cmp   al, 6
je    gamemap_finalesetup
exit_worlddone:
ret   


gamemap_a_15:
cmp   al, 31
je    gamemap_31
cmp   al, 30
je    gamemap_finalesetup
cmp   al, 20
je    gamemap_finalesetup

ret   


gamemap_ae_15:
ja    gamemap_a_15



gamemap_31:
cmp   byte ptr cs:[_wi_secretexit], 0
je    exit_worlddone
gamemap_finalesetup:
mov   ax, 2


call  dword ptr ds:[_Z_SetOverlay_addr]



db    09Ah
dw    F_STARTFINALEOFFSET, CODE_OVERLAY_SEGMENT


ret   

ENDP




PROC   WI_Ticker_ FAR
PUBLIC WI_Ticker_

push  bx
push  dx

inc   word ptr cs:[_bcnt]
cmp   word ptr cs:[_bcnt], 1
jne   music_already_init
cmp   byte ptr ds:[_commercial], 0
je    set_doom1_music
;set doom2 music
mov   ax, MUS_DM2INT + 0100h
call_music:

; S_ChangeMusic_ inlined
mov   word ptr ds:[_pendingmusicenum], ax
;mov   byte ptr ds:[_pendingmusicenumlooping], dl


music_already_init:


; inlined WI_checkForAccelerate_

mov   bx, OFFSET _player
test  byte ptr ds:[bx + 07h], BT_ATTACK			; player.cmd.buttons & BT_ATTACK
je    not_attack_pressed
cmp   byte ptr ds:[bx + 04Ch], 0					; if (!player.attackdown){
jne   attack_not_already_down
mov   word ptr cs:[_acceleratestage], 1					; accel
attack_not_already_down:
mov   byte ptr ds:[bx + 04Ch], 1					; player attackdown.
check_use:
test  byte ptr ds:[bx + 07h], BT_USE				; player.cmd.buttons & BT_USE
je    not_use_pressed
cmp   byte ptr ds:[bx + 04Dh], 0					; if (!player.usedown){
jne   use_not_already_down
mov   word ptr cs:[_acceleratestage], 1					; accel
use_not_already_down:
mov   byte ptr ds:[bx + 04Dh], 1

jmp   done_with_checking_for_accel   

not_attack_pressed:
mov   byte ptr ds:[bx + 04Ch], 0
jmp   check_use
not_use_pressed:
mov   byte ptr ds:[bx + 04Dh], 0

done_with_checking_for_accel:

mov   al, byte ptr cs:[_state]
cmp   al, NOSTATE
je    branch_NoState
cmp   al, SHOWNEXTLOC
je    branch_ShowNextLoc
cmp   al, STATCOUNT
je    branch_StatCount
done_with_state_branch:


pop   dx
pop   bx
retf  
set_doom1_music:
mov   ax, MUS_INTER + 0100h
jmp   call_music

branch_StatCount:
call  WI_updateStats_
jmp   done_with_state_branch

branch_ShowNextLoc:
call  WI_updateShowNextLoc_
jmp   done_with_state_branch
branch_NoState:
call  WI_updateNoState_
jmp   done_with_state_branch

ENDP




PROC   WI_Drawer_ FAR
PUBLIC WI_Drawer_

cmp   byte ptr cs:[_unloaded], 0
jne   unloaded_exit_early
not_unloaded_do_draw:


mov   al, byte ptr cs:[_state]
cmp   al, NOSTATE
jne   not_nostate
call  WI_drawNoState_

invalid_state:
exit_wi_drawer:
unloaded_exit_early:

retf

not_nostate:
cmp   al, SHOWNEXTLOC
je    do_ShowNextLoc
cmp   al, STATCOUNT
jne   invalid_state
call  WI_drawStats_
jmp   exit_wi_drawer

do_ShowNextLoc:
call  WI_drawShowNextLoc_
jmp   exit_wi_drawer


ENDP




PROC   WI_initVariables_ NEAR
PUBLIC WI_initVariables_


push  bx
push  si
push  di
mov   word ptr cs:[_wbs_ptr], ax
xchg  ax, bx
xor   ax, ax
mov   word ptr cs:[_acceleratestage], ax
mov   word ptr cs:[_bcnt], ax
mov   word ptr cs:[_cnt], ax
push  cs
pop   es
mov   di, OFFSET _plrs
lea   si, [bx + WBSTARTSTRUCT_T.wbss_plyr]

movsb  ; wbos_in      
movsw  ; wbos_skills  
movsw  ; wbos_sitems  
movsw  ; wbos_ssecret 
movsw  ; wbos_stime   

; 	if ( commercial ){
;        wminfo.partime = cpars[gamemap-1]; 
;    } else {
;        wminfo.partime = pars[10*gameepisode+gamemap]; 
;    }


mov   al, byte ptr ds:[_gamemap]
; ah is known 0...
cmp   byte ptr ds:[_commercial], ah ; 0
je    use_pars

use_cpars:
dec   ax
sal   ax, 1
xchg  ax, si
mov   ax, word ptr cs:[_cpars + si]

jmp done_getting_pars

use_pars:
xchg  ax, si  ; si gets gamemap
mov   al, 9
mul   byte ptr ds:[_gameepisode]
sub   al, 10   ; normalize episode to 0 not 1, then sub one extra for game_map normalization
add   si, ax
sal   si, 1    ; word lookup
mov   ax, word ptr cs:[_pars + si]

done_getting_pars:

set_par:
mov   word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_partime], ax        ; set partime

xor   si, si
mov   ax, 1

cmp   word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxkills], si ; 0
jne   dont_set_maxkills
mov   word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxkills], ax ; 1
dont_set_maxkills:
cmp   word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxitems], si ; 0
jne   dont_set_maxitems
mov   word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxitems], ax ; 1
dont_set_maxitems:
cmp   word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxsecret], si ; 0
jne   dont_set_maxsecret
mov   word ptr ds:[bx + WBSTARTSTRUCT_T.wbss_maxsecret], ax ; 1
dont_set_maxsecret:
pop   di
pop   si
pop   bx
ret   





ENDP



PROC   WI_Init_ NEAR
PUBLIC WI_Init_


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Eh					   ; room for lump name string

xor   dx, dx                       ; loop ctr
mov   bx, dx 					   ; size/dst offset

mov   si, OFFSET _wigraphics

cmp   byte ptr ds:[_commercial], bl ; 0
je    skip_doom2_settings

mov   dl, 6
mov   bl, 6
mov   si, OFFSET _wigraphics_commercial

skip_doom2_settings:

loop_wi_items:

mov   word ptr [bp - 0Ch], dx
mov   word ptr [bp - 0Eh], bx

push  cs
pop   ds
push  ss
pop   es

lea   di, [bp - 0Ah]
mov   ax, di	; store this address as arg for getnumforname

movsw
movsw
movsw
movsw
movsb ; copy nine bytes

push  ss
pop   ds ; restore ds



call  dword ptr ds:[_W_GetNumForName_addr]


mov   di, ax				; ax has lump num, cache in di
call  dword ptr ds:[_W_LumpLength_addr]

xchg  ax, di				; di gets size. ax gets lumpnum

mov   cx, WIGRAPHICSPAGE0_SEGMENT  ; dest segment for W_CacheLumpNameDirect_ for loop
mov   bx, word ptr [bp - 0Eh]

call  dword ptr ds:[_W_CacheLumpNumDirect_addr]

les   bx, dword ptr [bp - 0Eh]
mov   dx, es

mov   ax, WIOFFSETS_SEGMENT
mov   es, ax


xchg  ax, di        ; size in ax

mov   di, dx
mov   word ptr es:[di], bx		; write old size

add   bx, ax				; add lump size to offset 

inc   dx
inc   dx

cmp   dx, (NUM_WI_ITEMS * 2)

jl    loop_wi_items



; done with setup loop


mov   cx, WIGRAPHICSLEVELNAME_SEGMENT
xor   bx, bx
mov   si, word ptr cs:[_wbs_ptr]
lea   di, [bp - 0Ah]



cmp   byte ptr ds:[_commercial], bl ; 0
je    do_nondoom2_wi_init
; doom2 case


; 
; CWILV00  = 43 57 49 4C 56 30 30 0

mov   word ptr ds:[di + 0], 05743h ; "CW"
mov   word ptr ds:[di + 2], 04C49h ; "IL"
mov   byte ptr ds:[di + 4], 056h ; "V"


mov   al, byte ptr ds:[si + WBSTARTSTRUCT_T.wbss_last]		; wbs ->last
db    0D4h, 00Ah	    ; divide by 10 using AAM
xchg  al, ah
add   ax, 03030h				; add '0' to each character
mov   word ptr ds:[di + 5], ax  ; numbers for string

mov   byte ptr ds:[di + 7], 00h ; null terminator

mov   ax, di

call  dword ptr ds:[_W_CacheLumpNameDirect_addr]


mov   al, byte ptr ds:[si + WBSTARTSTRUCT_T.wbss_next]		; wbs ->next
db    0D4h, 00Ah	    ; divide by 10 using AAM
xchg  al, ah
add   ax, 03030h				; add '0' to each character
mov   word ptr ds:[di + 5], ax  ; numbers for string

jmp   do_final_init_call_and_exit

do_nondoom2_wi_init:
 
; WILV00  = 57 49 4C 56 30 30 0

mov   word ptr ds:[di + 0], 04957h ; "WI"
mov   word ptr ds:[di + 2], 0564Ch ; "LV"

mov   al, byte ptr ds:[si + WBSTARTSTRUCT_T.wbss_epsd]			; wbs ->epsd
mov   ah, byte ptr ds:[si + WBSTARTSTRUCT_T.wbss_last]		; wbs ->last
add   ax, 03030h				; add '0' to each character
mov   word ptr ds:[di + 4], ax  ; numbers for string
mov   byte ptr ds:[di + 6], 00h ; null terminator



mov   ax, di
call  dword ptr ds:[_W_CacheLumpNameDirect_addr]


mov   al, byte ptr ds:[si + WBSTARTSTRUCT_T.wbss_next]		; wbs ->next
add   al, 030h	 				; add '0' to character
mov   byte ptr ds:[di + 5], al   ; update number for string


do_final_init_call_and_exit:


mov   bx, NEXT_OFFSET
mov   cx, WIGRAPHICSLEVELNAME_SEGMENT
;xchg  ax, di
lea   ax, [bp - 0Ah]

call  dword ptr ds:[_W_CacheLumpNameDirect_addr]


do_exit:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP





ENDP

PROC   WI_StartSound_ NEAR
PUBLIC WI_StartSound_


push   si
push   cx
push   dx

Z_QUICKMAPAI3 pageswapargs_physics_code_offset_size INDEXED_PAGE_9000_OFFSET

pop    dx


db    09Ah
dw    S_STARTSOUNDAX0FAROFFSET, PHYSICS_HIGHCODE_SEGMENT

Z_QUICKMAPAI3 (pageswapargs_intermission_offset_size+12) INDEXED_PAGE_9000_OFFSET

pop    cx
pop    si

ret
ENDP



PROC    G_DoCompleted_ FAR
PUBLIC  G_DoCompleted_

push    bx
push    cx
push    dx
push    di

xor     ax, ax
mov     byte ptr ds:[_gameaction], al ; GA_NOTHING
;call    G_PlayerFinishLevel_

; inlned



xor     ax, ax
mov     word ptr ds:[_player + PLAYER_T.player_extralightvalue], ax ; 0        cancel invisibility 
;mov     byte ptr ds:[_player + PLAYER_T.player_fixedcolormapvalue], al ; 0    cancel ir gogles 
mov     word ptr ds:[_player + PLAYER_T.player_damagecount], ax ; 0            no palette changes 
mov     byte ptr ds:[_player + PLAYER_T.player_bonuscount], al ; 0            
les     di, dword ptr ds:[_playerMobj_pos]
and     byte ptr es:[di + MOBJ_POS_T.mp_flags2], (NOT MF_SHADOW)
mov     cx, (2 * NUMPOWERS + 1 * NUMCARDS) / 2  ; 18 or 012h / 2 = 9
mov     di, OFFSET _player + PLAYER_T.player_powers
push    ds
pop     es
rep     stosw
    ;memset (player.powers, 0, sizeof (player.powers));
    ;memset (player.cards, 0, sizeof (player.cards));


mov     ax, 1
cmp     byte ptr ds:[_automapactive], ah ; 0
je      skip_am_stop
; AM_Stop() inlined
mov     byte ptr ds:[_am_stopped], al ; 1
mov     byte ptr ds:[_st_gamestate], al ; 1
skip_am_stop:
cmp     byte ptr ds:[_commercial], ah ; 0
jne     skip_non_commercial_stuff
cmp     byte ptr ds:[_gamemap], 8
ja      do_level_9
jne     skip_non_commercial_stuff
do_level_8:
mov     byte ptr ds:[_gameaction], GA_VICTORY
jmp     done_with_non_commercial_stuff
do_level_9:
mov     byte ptr ds:[_player + PLAYER_T.player_didsecret], al ; true
done_with_non_commercial_stuff:
skip_non_commercial_stuff:

mov     al, byte ptr ds:[_player + PLAYER_T.player_didsecret]
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_didsecret], al
mov     ax, word ptr ds:[_gameepisode]
sub     ax, 00101h ; sub 1 from each
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_epsd], al
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_last], ah

xor     ax, ax
mov     al, byte ptr ds:[_gamemap]

cmp     byte ptr ds:[_commercial], ah
je      do_non_commercial_wminfo
cmp     byte ptr ds:[_secretexit], ah
je      not_commercial_secret
mov     ah, 30
cmp     al, 15
je      do_map_30
inc     ah
cmp     al, 31;    // wminfo.next is 0 biased, unlike gamemap
je      do_map_31
jmp     done_with_wbss_next_calc
not_commercial_secret:
mov     ah, 15
cmp     al, 31
jae      do_map_15
;cmp     al, 32;    // wminfo.next is 0 biased, unlike gamemap
;je      do_map_31
jmp    do_default_map

do_non_commercial_wminfo:
cmp     byte ptr ds:[_secretexit], ah
mov     ah, 8
jne     do_map_8   ; secret
cmp     al, 9  ; returning from secret level
jne     not_map_9
mov     al, byte ptr ds:[_gameepisode]
mov     ah, 3
cmp     al, 2
jb      do_map_3  ; episode 1
mov     ah, 5
je      do_map_5  ; episode 2
mov     ah, 6
jpo     do_map_6  ; episode 3
mov     ah, 2
jmp     do_map_2  ; episode 4
not_map_9:
do_default_map:
mov     ah, al  ; gamemap
do_map_2:
do_map_3:
do_map_5:
do_map_6:
do_map_8:
do_map_15:
do_map_30:
do_map_31:
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_next], ah

done_with_wbss_next_calc:

les     ax, dword ptr ds:[_totalkills]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_maxkills], ax
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_maxitems], es
mov     ax, word ptr ds:[_totalsecret]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_maxsecret], ax
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_in], 1 ; true
les     ax, dword ptr ds:[_player + PLAYER_T.player_killcount]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_skills], ax
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_sitems], es
mov     ax, word ptr ds:[_player + PLAYER_T.player_secretcount]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_ssecret], ax
les     ax, dword ptr ds:[_leveltime]
mov     dx, es
mov     bx, 35
call    dword ptr ds:[_FastDiv32u16u_addr]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_stime], ax
mov     ax, 1
mov     byte ptr ds:[_gamestate], al ; GS_INTERMISSION
mov     byte ptr ds:[_viewactive], ah ; false
mov     byte ptr ds:[_automapactive], ah ; false


;    WI_Start (&wminfo, secretexit); 

mov     ax, OFFSET _wminfo
mov     dl, byte ptr ds:[_secretexit]  ; todo get this from inside the func?

; inlined wi_start

mov   byte ptr cs:[_unloaded], 0
mov   byte ptr cs:[_wi_secretexit], dl
call  WI_initVariables_
call  WI_Init_
call  WI_loadData_
call  WI_initStats_



pop     di
pop     dx
pop     cx
pop     bx

retf

ENDP


PROC   WI_DrawPatch_ NEAR

; ax is x
; dl is y
; bx is patch offset
; cx is unused
; es is patch segment

 cmp   byte ptr ds:[_skipdirectdraws], 0
 jne   exit_early

push  si 
push  di 
push  cx

; bx = 2*ax for word lookup
mov   di, bx
mov   cx, es   
mov   es, word ptr ds:[_screen_segments]   ;todo move to cs.
mov   ds, cx    ; ds:di is seg

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch

; ds:di is patch
mov   word ptr cs:[_SELFMODIFY_add_patch_offset+2], di
sub   dx, word ptr ds:[di + PATCH_T.patch_topoffset]


; calculate x + (y * screenwidth)


IF COMPISA GE COMPILE_186

    imul  si, dx , SCREENWIDTH
    add   si, ax

ELSE
    xchg  ax, si  ; si gets x
    mov   al, SCREENWIDTH / 2
    mul   dl
    sal   ax, 1
    xchg  ax, si  ; si gets x
    add   si, ax


ENDIF

; ax, dx maintained for markrect

sub   si, word ptr ds:[di + PATCH_T.patch_leftoffset]
mov   word ptr cs:[_SELFMODIFY_offset_add_di + 2], si





push  ds
push  es 	; restore previously looked up segment.


les   bx, dword ptr ds:[di + PATCH_T.patch_width] 
mov   cx, es    ; height


push  ss
pop   ds
call  WI_MarkRect_
pop   es
pop   ds




;    w = (patch->width); 
mov   cx, word ptr ds:[di + PATCH_T.patch_width]  ; count
lea   bx, [di + PATCH_T.patch_columnofs]          ; set up columnofs ptr
mov   dx, SCREENWIDTH - 1                         ; loop constant

draw_next_column:
push  cx            ; store patch width for outer loop iter
xor   cx, cx        ; clear ch specifically


; es:di is screen pixel target

mov   si, word ptr ds:[bx]           ; ds:bx is current patch col offset to draw

_SELFMODIFY_add_patch_offset:
add   si, 01000h

lodsw
;		while (column->topdelta != 0xff )  

cmp  al, 0FFh               ; al topdelta, ah length
je   column_done

draw_next_patch_column:

; here we render the next patch in the column.

xchg  cl, ah          ; cx is now col length, ah is now 0
inc   si      


IF COMPISA GE COMPILE_186
imul   di, ax, SCREENWIDTH   ; ax has topdelta.

ELSE
; cant fit screenwidth in 1 byte but we can do this...
mov   ah, SCREENWIDTH / 2
mul   ah
sal   ax, 1
xchg  ax, di
ENDIF



_SELFMODIFY_offset_add_di:
add   di, 01000h   ; retrieve offset

; todo lazy len 8 or 16 unrolle dloop


draw_next_patch_pixel:

movsb
add   di, dx
loop  draw_next_patch_pixel 

check_for_next_column:

inc   si
lodsw
cmp   al, 0FFh
jne   draw_next_patch_column

column_done:
add   bx, 4
inc   word ptr cs:[_SELFMODIFY_offset_add_di + 2]   ; pixel offset increments each column
pop   cx
loop  draw_next_column		; relative out of range by 5 bytes

done_drawing:
push  ss
pop   ds
pop   cx
pop   di
pop   si
exit_early:

ret

ENDP




;void __far V_MarkRect ( int16_t x, int16_t y, int16_t width, int16_t height )  { 
PROC   WI_MarkRect_ NEAR
PUBLIC WI_MarkRect_


;    M_AddToBox16 (dirtybox, x, y); 
;    M_AddToBox16 (dirtybox, x+width-1, y+height-1); 

push      di

mov       di, OFFSET _dirtybox

add       cx, dx   
dec       cx      ; y + height - 1
add       bx, ax
dec       bx      ; x + width - 1

push      bx
call      WI_AddToBox16_
pop       ax  ; restore bx
mov       dx, cx
call      WI_AddToBox16_


pop       di
ret   


ENDP

;void __near M_AddToBox16 ( int16_t	x, int16_t	y, int16_t __near*	box  );

PROC    WI_AddToBox16_ NEAR
PUBLIC  WI_AddToBox16_

mov   bx, (2 * BOXLEFT)
cmp   ax, word ptr ds:[di + bx]
jl    write_x_to_left
mov   bl, (2 * BOXRIGHT)
cmp   ax, word ptr ds:[di + bx]
jle   do_y_compare
write_x_to_left:
mov   word ptr ds:[di + bx], ax
do_y_compare:
xchg  ax, dx
mov   bl, 2 * BOXBOTTOM
cmp   ax, word ptr ds:[di + bx]
jl    write_y_to_bottom
mov   bl, 2 * BOXTOP
cmp   ax, word ptr ds:[di + bx]
jng   exit_m_addtobox16
write_y_to_bottom:
mov   word ptr ds:[di + bx], ax
exit_m_addtobox16:
ret   


ENDP

PROC WI_ENDMARKER_ NEAR
PUBLIC WI_ENDMARKER_
ENDP

ENDS

END