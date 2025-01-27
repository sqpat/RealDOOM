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

EXTRN Z_SetOverlay_:PROC
EXTRN W_LumpLength_:PROC
EXTRN Z_QuickMapPhysics_:PROC
EXTRN Z_QuickMapIntermission_:PROC

.DATA

; these could mostly be local to the code if this code was loaded HIGH

EXTRN _bcnt:WORD
EXTRN _wbs:WORD
EXTRN _state:WORD

EXTRN _cnt_secret:WORD
EXTRN _cnt_items:WORD
EXTRN _cnt_kills:WORD
EXTRN _cnt_par:WORD
EXTRN _cnt_pause:WORD
EXTRN _yahRef:WORD
EXTRN _sp_state:WORD
EXTRN _splatRef:WORD
EXTRN _cnt:WORD
EXTRN _acceleratestage:WORD
EXTRN _numRef:WORD
EXTRN _snl_pointeron:WORD
EXTRN _tmxmove:WORD


EXTRN _player:PLAYER_T
EXTRN _secretexit:BYTE
EXTRN _rndindex:BYTE
EXTRN _F_StartFinale:DWORD
EXTRN _cnt_time:WORD
EXTRN _unloaded:BYTE
EXTRN _plrs:WORD





.CODE

PROC WI_STARTMARKER NEAR
PUBLIC WI_STARTMARKER
ENDP



_NUMANIMS:
db    10, 9, 6

_wianims:
dw 0, EPSD0ANIMINFO_SEGMENT, 0, EPSD1ANIMINFO_SEGMENT, 0, EPSD2ANIMINFO_SEGMENT




; todo optimed out??
PROC WI_GetPatch_ NEAR
PUBLIC WI_GetPatch_

push      bx
mov       bx, ax
add       bx, ax
mov       ax, WIOFFSETS_SEGMENT
mov       es, ax
mov       dx, WIGRAPHICSPAGE0_SEGMENT
mov       ax, word ptr es:[bx]
pop       bx
ret

ENDP

PROC WI_GetPatchESBX_ NEAR
PUBLIC WI_GetPatchESBX_

mov       bx, ax
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

mov       ax, RNDTABLE_SEGMENT
mov       es, ax
xor       ax, ax
mov       bx, ax
inc       byte ptr ds:[_rndindex]
mov       bl, byte ptr ds:[_rndindex]
mov       al, byte ptr es:[bx]

pop       bx
pop       es

ret

ENDP


PROC WI_GetAnimPatch_ NEAR
PUBLIC WI_GetAnimPatch_

push      bx
mov       bx, ax
add       bx, ax
mov       ax, WIANIMOFFSETS_SEGMENT
mov       es, ax
mov       dx, WIANIMSPAGE_SEGMENT
mov       ax, word ptr es:[bx]
pop       bx
ret

ENDP 

PROC WI_slamBackground_ NEAR
PUBLIC WI_slamBackground_


push      bx
push      cx
push      dx
push      si
push      di
mov       ax, SCREENWIDTH * SCREENHEIGHT
mov       cx, SCREEN1_SEGMENT
mov       dx, SCREEN0_SEGMENT
xor       si, si
xor       di, di
mov       es, dx
mov       bx, SCREENWIDTH
push      ds
push      di
xchg      ax, cx
mov       ds, ax
shr       cx, 1
rep       movsw 
adc       cx, cx
rep       movsb 
pop       di
pop       ds
mov       cx, SCREENHEIGHT
xor       dx, dx
xor       ax, ax

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_MarkRect_addr

pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       

ENDP

PROC WI_drawLF_ NEAR
PUBLIC WI_drawLF_


push      bx
push      cx
push      dx
push      si
push      di

push      bp
mov       bp, sp

mov       ax, WIGRAPHICSLEVELNAME_SEGMENT
mov       es, ax

xor       si, si

; patch
push      ax
push      si				; 0

; x
mov       ax, SCREENWIDTH
sub       ax, word ptr es:[si]
sar       ax, 1

; y
mov       dx, 2				; y = 2

;screen
xor       bx, bx			; set to FB

mov       si, word ptr es:[si + 2]			; grab height of lname


db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr


mov       ax, WIOFFSETS_SEGMENT
mov       es, ax

mov       di, word ptr es:[5 * 2]

mov       cx, WIGRAPHICSPAGE0_SEGMENT
mov       es, cx

; patch
push      cx
push      di


;	y += (5 * (lname->height)) >>2;
mov       dx, si
shl       dx, 1
shl       dx, 1
add       dx, si		; 5 * height
sar       dx, 1
sar       dx, 1
inc       dx			; += original 2
inc       dx			; += original 2

; x
mov       ax, SCREENWIDTH
sub       ax, word ptr es:[di]
sar       ax, 1

; screen
xor       bx, bx			; set to FB

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret      

ENDP

PROC WI_drawEL_ NEAR
PUBLIC WI_drawEL_


push      bx
push      dx
mov       bx, 27 * 2
mov       ax, WIOFFSETS_SEGMENT
mov       dx, WIGRAPHICSPAGE0_SEGMENT
mov       es, ax
push      dx
mov       ax, SCREENWIDTH
mov       bx, word ptr es:[bx]
mov       es, dx
push      bx
sub       ax, word ptr es:[bx]
mov       dx, 2
sar       ax, 1
xor       bx, bx

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

mov       ax, WIGRAPHICSLEVELNAME_SEGMENT
mov       bx, MAX_LEVEL_COMPLETE_GRAPHIC_SIZE
mov       es, ax
mov       dx, word ptr es:[bx + 2]
mov       ax, dx
push      es
shl       ax, 2
push      bx
add       dx, ax
mov       ax, SCREENWIDTH
sar       dx, 2
sub       ax, word ptr es:[bx]
add       dx, 2
sar       ax, 1
xor       bx, bx

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

pop       dx
pop       bx
ret       


ENDP



PROC WI_drawOnLnode_ NEAR
PUBLIC WI_drawOnLnode_


push  bx
push  cx
push  si
push  di

;int16_t index = wbs->epsd*10 + n;

mov   si, dx					; store cref in si.

xor   bx, bx
xchg  ax, bx					; store n in bx
mov   ah, byte ptr ds:[_wbs + 0]	; wbs->epsd

db    0D5h, 00Ah					; AAD to mul by 10

add   bx, ax						; plus n
shl   bx, 1   ; word lookup

mov   ax, LNODEX_SEGMENT		; eventually put this in the cs seg?
mov   es, ax
mov   di, word ptr es:[bx]		; di = lnodex

mov   ax, LNODEY_SEGMENT		; eventually put this in the cs seg?
mov   es, ax
mov   dx, word ptr es:[bx]		; dx = lnodey

mov   cx, 2

loop_drawonlnode:
mov   ax, cx
;     xor ah ah for free since cx is 0 or 1..
lodsb							    ;  WI_GetPatch(cRef[i]);
call  WI_GetPatchESBX_				; todo what if this just returned es:bx or whatever

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
push  es
push  bx
xor   bx, bx

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

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



PROC WI_updateAnimatedBack_ NEAR
PUBLIC WI_updateAnimatedBack_

push  bx
push  cx
push  dx

cmp   byte ptr ds:[_commercial], 0
jne   exit_update_animated_back   ; not for doom2 
mov   bx, word ptr ds:[_wbs]    ; 

mov   al, byte ptr [bx]         ; get epsd
cmp   al, 2                     ; > epsd 2?
jg    exit_update_animated_back
cbw

mov   dl, byte ptr [bx + 3]     ; cache wbs->next for loop

xor   cx, cx                    ; zero out ch..
xchg  ax, bx                    ; bx gets epsd

mov   cl, byte ptr cs:[bx + _NUMANIMS] ; cl gets num anims (loop amount)
sal   bx, 1
sal   bx, 1                             ; dword lookup 
les   bx, dword ptr cs:[bx + _wianims]  ; es:bx is wianims

loop_update_animated_back:

mov   ax, word ptr [_bcnt]
cmp   ax, word ptr es:[bx + 0Ch]
jne   finish_update_anim_loop_iter


mov   al, byte ptr es:[bx]      ; get anim type
cmp   al, ANIM_RANDOM
je    update_anim_random
cmp   al, ANIM_ALWAYS
je    update_anim_always
cmp   al, ANIM_LEVEL
je    update_anim_level

; fall thru
finish_update_anim_loop_iter:
add   bx, SIZEOF_WIANIM_T
loop  loop_update_animated_back

exit_update_animated_back:

pop   dx
pop   cx
pop   bx
ret   


update_anim_level:
cmp   byte ptr [_state], 0
jne   continue_level_check
cmp   cx, 7
je    finish_update_anim_loop_iter
continue_level_check:
mov   al, dl                        ; dh is cached wbs next

cmp   al, byte ptr es:[bx + 5]
jne   finish_update_anim_loop_iter
inc   byte ptr es:[bx + 0Eh]        ; increment ctr
mov   al, byte ptr es:[bx + 0Eh]
cmp   al, byte ptr es:[bx + 2]
jne   dont_dec_ctr
dec   byte ptr es:[bx + 0Eh]
dont_dec_ctr:

update_anim_set_nexttic_to_bcnt_plus_period:
xor   ax, ax
mov   al, byte ptr es:[bx + 1]
add   ax, word ptr [_bcnt]
mov   word ptr es:[bx + 0Ch], ax

jmp   finish_update_anim_loop_iter

update_anim_random:
inc   byte ptr es:[bx + 0Eh]
mov   al, byte ptr es:[bx + 0Eh]
cmp   al, byte ptr es:[bx + 2]
jne   update_anim_set_nexttic_to_bcnt_plus_period


call  WI_MRandomLocal_
div   byte ptr es:[bx + 5]
mov   al, ah
xor   ah, ah

add   ax, word ptr [_bcnt]
mov   word ptr es:[bx + 0Ch], ax
jmp   finish_update_anim_loop_iter

update_anim_always:
inc   byte ptr es:[bx + 0Eh]
mov   al, byte ptr es:[bx + 0Eh]
cmp   al, byte ptr es:[bx + 2]
jnge  update_anim_set_nexttic_to_bcnt_plus_period
mov   byte ptr es:[bx + 0Eh], 0

jmp   update_anim_set_nexttic_to_bcnt_plus_period





ENDP


PROC WI_drawAnimatedBack_ NEAR
PUBLIC WI_drawAnimatedBack_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
cmp   byte ptr ds:[_commercial], 0
je    label_7
jump_to_exit_update_animated_back:
jmp   exit_update_animated_back
label_7:
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 2
jg    jump_to_exit_update_animated_back
xor   cx, cx
xor   si, si

label_9:
mov   bx, word ptr ds:[_wbs]
mov   al, byte ptr [bx]
cbw  
mov   bx, ax
mov   al, byte ptr cs:[bx + _NUMANIMS]
cbw  
cmp   cx, ax
jge   jump_to_exit_update_animated_back
shl   bx, 2
mov   ax, word ptr cs:[bx + _wianims]
mov   dx, word ptr cs:[bx + _wianims+2]
mov   bx, ax
mov   es, dx
add   bx, si
mov   al, byte ptr es:[bx + 0Eh]
mov   word ptr [bp - 2], dx
test  al, al
jge   label_8
add   si, SIZEOF_WIANIM_T
inc   cx
jmp   label_9
label_8:
cbw  
mov   di, bx
add   ax, ax
add   di, ax
mov   ax, word ptr es:[di + 6]
call  WI_GetAnimPatch_
push  dx
mov   es, word ptr [bp - 2]
push  ax
mov   dl, byte ptr es:[bx + 4]
mov   al, byte ptr es:[bx + 3]
xor   dh, dh
xor   ah, ah
xor   bx, bx

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

add   si, SIZEOF_WIANIM_T
inc   cx
jmp   label_9


ENDP


PROC WI_initShowNextLoc_ NEAR
PUBLIC WI_initShowNextLoc_


mov   byte ptr ds:[_state], 1
mov   word ptr ds:[_cnt], SHOWNEXTLOCDELAY * TICRATE
mov   word ptr ds:[_acceleratestage], 0

; fall thru

ENDP

PROC WI_initAnimatedBack_ NEAR
PUBLIC WI_initAnimatedBack_

push  bx
push  cx
push  dx
cmp   byte ptr ds:[_commercial], 0
jne   exit_init_animated_back   ; not for doom2 
mov   bx, word ptr ds:[_wbs]    ; 

mov   al, byte ptr [bx]         ; get epsd
cmp   al, 2                     ; > epsd 2?
jg    exit_init_animated_back
cbw
xor   cx, cx                    ; zero out ch..

xchg  ax, bx                    ; bx gets epsd

mov   cl, byte ptr cs:[bx + _NUMANIMS] ; cl gets num anims (loop amount)

sal   bx, 1
sal   bx, 1                             ; dword lookup 
les   bx, dword ptr cs:[bx + _wianims]  ; es:bx is wianims
loop_init_animated_back:

mov   al, byte ptr es:[bx]              ; get anim type
mov   byte ptr es:[bx + 0Eh], -1        ; ctr -1
cmp   al, ANIM_ALWAYS
je    init_anim_always
cmp   al, ANIM_RANDOM
je    init_anim_random
cmp   al, ANIM_LEVEL
je    init_anim_level
finish_init_anim_loop_iter:
add   bx, SIZEOF_WIANIM_T               ; bx is next wi_anim


loop  loop_init_animated_back


exit_init_animated_back:

pop   dx
pop   cx
pop   bx
ret   

init_anim_always:
mov   dl, byte ptr es:[bx + 1]
call  WI_MRandomLocal_
jmp   do_modulostep

init_anim_random:
mov   dl, byte ptr es:[bx + 5]
call  WI_MRandomLocal_

do_modulostep:

div   dl
mov   al, ah            ; take modulo result.
xor   ah, ah

add_bcnt_plus_1_etc:
; plus bcnt plus 1
add   ax, word ptr ds:[_bcnt]
inc   ax
mov   word ptr es:[bx + 0Ch], ax    ; write nexttic

jmp   finish_init_anim_loop_iter

init_anim_level:
xor   ax, ax
jmp   add_bcnt_plus_1_etc



ENDP


PROC WI_drawNum_ NEAR
PUBLIC WI_drawNum_

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   di, ax
mov   word ptr [bp - 2], dx
mov   si, bx
mov   al, byte ptr [_numRef]
xor   ah, ah
call  WI_GetPatch_
mov   bx, ax
mov   es, dx
mov   ax, word ptr es:[bx]
mov   word ptr [bp - 4], ax
test  cx, cx
jl    label_23
label_27:
test  si, si
jl    label_24
xor   ax, ax
label_26:
mov   word ptr [bp - 6], ax
test  ax, ax
je    label_32
neg   si
label_32:
cmp   si, 1994				; if non-number dont draw it
je    label_31
label_29:
dec   cx
cmp   cx, -1
je    label_30
mov   ax, si
mov   bx, 10
cwd   
idiv  bx
mov   bx, dx
mov   al, byte ptr [bx + _numRef]
xor   ah, ah
sub   di, word ptr [bp - 4]
call  WI_GetPatch_
xor   bx, bx
push  dx
mov   dx, word ptr [bp - 2]
push  ax
mov   ax, di
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
mov   ax, si
mov   bx, 10
cwd   
idiv  bx
mov   si, ax
jmp   label_29
label_23:
test  si, si
jne   label_28
mov   cx, 1
jmp   label_27
label_28:
mov   ax, si
xor   cx, cx
test  si, si
je    label_27
mov   bx, 10
label_25:
cwd   
idiv  bx
inc   cx
test  ax, ax
jne   label_25
jmp   label_27
label_24:
mov   ax, 1
jmp   label_26
label_31:
xor   ax, ax
LEAVE_MACRO 
pop   di
pop   si
ret   
label_30:
cmp   word ptr [bp - 6], 0
je    label_33
mov   ax, 12
call  WI_GetPatch_
sub   di, 8
xor   bx, bx
push  dx
mov   dx, word ptr [bp - 2]
push  ax
mov   ax, di
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
label_33:
mov   ax, di
LEAVE_MACRO 
pop   di
pop   si
ret   

ENDP


PROC WI_drawPercent_ NEAR
PUBLIC WI_drawPercent_


push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
mov   di, dx
mov   word ptr [bp - 2], bx
test  bx, bx
jge   label_34
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   
label_34:
mov   ax, 13
call  WI_GetPatch_
push  dx
xor   bx, bx
push  ax
mov   dx, di
mov   ax, si
mov   cx, -1
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
mov   bx, word ptr [bp - 2]
mov   dx, di
mov   ax, si
call  WI_drawNum_
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   

ENDP

PROC WI_drawTime_ NEAR
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
mov   ax, 24
mov   si, 1
call  WI_GetPatch_
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 2], dx
label_48:
mov   ax, di
cwd   
idiv  si
mov   bx, 60
cwd   
idiv  bx
imul  si, si, 60
mov   cx, 2
mov   ax, word ptr [bp - 6]
mov   bx, dx
mov   dx, word ptr [bp - 8]
call  WI_drawNum_
les   bx, dword ptr [bp - 4]
sub   ax, word ptr es:[bx]
mov   word ptr [bp - 6], ax
cmp   si, 60
jne   label_40
label_41:
push  word ptr [bp - 2]
mov   dx, word ptr [bp - 8]
mov   ax, word ptr [bp - 6]
push  word ptr [bp - 4]
xor   bx, bx
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
label_42:
mov   ax, di
cwd   
idiv  si
test  ax, ax
jne   label_48
exit_wi_drawtime:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   

label_40:
mov   ax, di
cwd   
idiv  si
test  ax, ax
jne   label_41
jmp   label_42
draw_sucks:
mov   ax, 25
call  WI_GetPatch_
xor   bx, bx
mov   si, ax
push  dx
mov   es, dx
push  ax
mov   ax, word ptr [bp - 6]
mov   dx, word ptr [bp - 8]
sub   ax, word ptr es:[si]
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   

ENDP


PROC WI_initNoState_ NEAR
PUBLIC WI_initNoState_

mov   byte ptr ds:[_state], -1
mov   word ptr ds:[_cnt], 10
mov   word ptr ds:[_acceleratestage], 0
ret   

ENDP




PROC WI_updateShowNextLoc_ NEAR
PUBLIC WI_updateShowNextLoc_

call  WI_updateAnimatedBack_
dec   word ptr ds:[_cnt]
je    WI_initNoState_
cmp   word ptr ds:[_acceleratestage], 0
jne   WI_initNoState_
mov   ax, word ptr ds:[_cnt]
and   ax, 31
cmp   ax, 20
jae   set_ptr_off
mov   byte ptr ds:[_snl_pointeron], 1
ret   
set_ptr_off:
mov   byte ptr ds:[_snl_pointeron], 0
ret   

drawel_and_exit:
call  WI_drawEL_
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC WI_drawNoState_ NEAR
PUBLIC WI_drawNoState_

mov   byte ptr ds:[_snl_pointeron], 1

    ; fall thru
ENDP

PROC WI_drawShowNextLoc_ NEAR
PUBLIC WI_drawShowNextLoc_

push  bx
push  cx
push  dx
call  WI_slamBackground_
call  WI_drawAnimatedBack_
cmp   byte ptr ds:[_commercial], 0
jne   skip_drawing_pointer
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 2
jg    drawel_and_exit

;		last = (wbs->last == 8) ? wbs->next - 1 : wbs->last;

xor   ax, ax                ; zero out ah
mov   al, byte ptr [bx + 2]
cmp   al, 8
jne   set_last
mov   al, byte ptr [bx + 3]
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
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx + 1], 0
je    skip_drawing_secret_splat
mov   dx, OFFSET _splatRef
mov   ax, 8
call  WI_drawOnLnode_

skip_drawing_secret_splat:
cmp   byte ptr ds:[_snl_pointeron], 0
je    skip_drawing_pointer
mov   al, byte ptr [bx + 3]
mov   dx, OFFSET _yahRef
cbw  
call  WI_drawOnLnode_

skip_drawing_pointer:
cmp   byte ptr ds:[_commercial], 0
je    drawel_and_exit
cmp   byte ptr [bx + 3], 30
je    exit_this_func_todo
jmp   drawel_and_exit
exit_this_func_todo:
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC WI_initStats_ NEAR
PUBLIC WI_initStats_

xor   ax, ax
mov   byte ptr ds:[_state], al
mov   word ptr ds:[_acceleratestage], ax
mov   word ptr ds:[_sp_state], 1
mov   word ptr ds:[_cnt_pause], TICRATE
dec   ax    ; ax -1
mov   word ptr ds:[_cnt_secret], ax
mov   word ptr ds:[_cnt_items], ax
mov   word ptr ds:[_cnt_kills], ax
mov   word ptr ds:[_cnt_par], ax
mov   word ptr ds:[_tmxmove], ax
jmp   WI_initAnimatedBack_

ENDP




PROC WI_updateStats_ NEAR
PUBLIC WI_updateStats_

push  bx
push  cx
push  dx
call  WI_updateAnimatedBack_
cmp   word ptr ds:[_acceleratestage], 0
je    skip_accelerate
cmp   word ptr ds:[_sp_state], 10
je    skip_accelerate
xor   ax, ax
mov   word ptr ds:[_acceleratestage], ax
imul  ax, word ptr ds:[_plrs+1], 100
mov   bx, word ptr ds:[_wbs]
mov   cx, word ptr [bx + 4]
cwd   
idiv  cx
mov   word ptr ds:[_cnt_kills], ax
imul  ax, word ptr ds:[_plrs+3], 100
mov   cx, word ptr [bx + 6]
cwd   
idiv  cx
mov   word ptr ds:[_cnt_items], ax
imul  ax, word ptr ds:[_plrs+5], 100
mov   cx, word ptr [bx + 8]
cwd   
idiv  cx
mov   word ptr ds:[_cnt_secret], ax
mov   ax, word ptr ds:[_plrs+7]
mov   word ptr ds:[_cnt_time], ax
mov   ax, word ptr [bx + 0Ah]
mov   bx, TICRATE
cwd   
idiv  bx
mov   dx, SFX_BAREXP
mov   word ptr ds:[_cnt_par], ax
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
mov   word ptr ds:[_sp_state], 10
label_55:
cmp   word ptr ds:[_acceleratestage], 0
jne   jump_to_label_89
exit_wi_updatestats:
pop   dx
pop   cx
pop   bx
ret   


skip_accelerate:
mov   ax, word ptr ds:[_sp_state]
cmp   ax, 2
jne   sp_state_not_2
add   word ptr ds:[_cnt_kills], ax
test  byte ptr ds:[_bcnt], 3
jne   label_90
mov   dx, 1
xor   ax, ax

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

label_90:
imul  ax, word ptr ds:[_plrs+1], 100
mov   bx, word ptr ds:[_wbs]
cwd   
idiv  word ptr [bx + 4]
cmp   ax, word ptr ds:[_cnt_kills]
jg    exit_wi_updatestats
mov   dx, SFX_BAREXP
mov   word ptr ds:[_cnt_kills], ax
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

inc   word ptr ds:[_sp_state]
jmp   exit_wi_updatestats
jump_to_label_89:
jmp   label_89

sp_state_not_2:
cmp   ax, 4
jne   sp_state_not_4
add   word ptr ds:[_cnt_items], 2
test  byte ptr ds:[_bcnt], 3
jne   label_88
mov   dx, sfx_pistol
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

label_88:
imul  ax, word ptr ds:[_plrs+3], 100
mov   bx, word ptr ds:[_wbs]
cwd   
idiv  word ptr [bx + 6]
cmp   ax, word ptr ds:[_cnt_items]
jg    exit_wi_updatestats
mov   dx, SFX_BAREXP
mov   word ptr ds:[_cnt_items], ax
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
sp_state_not_4:
cmp   ax, 6
jne   sp_state_not_6
add   word ptr ds:[_cnt_secret], 2
test  byte ptr ds:[_bcnt], 3
jne   label_57
mov   dx, sfx_pistol
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

label_57:
imul  ax, word ptr ds:[_plrs+5], 100
mov   bx, word ptr ds:[_wbs]
cwd   
idiv  word ptr [bx + 8]
cmp   ax, word ptr ds:[_cnt_secret]
jle   label_83
jump_to_exit_wi_updatestats_2:
jmp   exit_wi_updatestats
label_83:
mov   dx, SFX_BAREXP
mov   word ptr ds:[_cnt_secret], ax
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
sp_state_not_6:
cmp   ax, 8
jne   sp_state_not_8
test  byte ptr ds:[_bcnt], 3
jne   label_60
mov   dx, 1
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

label_60:
add   word ptr ds:[_cnt_time], 3
mov   ax, word ptr ds:[_cnt_time]
cmp   ax, word ptr ds:[_plrs+7]
jl    label_86
mov   ax, word ptr ds:[_plrs+7]
mov   word ptr ds:[_cnt_time], ax
label_86:
mov   bx, word ptr ds:[_wbs]
mov   ax, word ptr [bx + 0Ah]
mov   cx, TICRATE
cwd   
idiv  cx
add   word ptr ds:[_cnt_par], 3
cmp   ax, word ptr ds:[_cnt_par]
jg    jump_to_exit_wi_updatestats_2
mov   word ptr ds:[_cnt_par], ax
mov   ax, word ptr ds:[_cnt_time]
cmp   ax, word ptr ds:[_plrs+7]
jl    jump_to_exit_wi_updatestats_2
mov   dx, SFX_BAREXP
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
sp_state_not_8:
cmp   ax, 10
jne   sp_state_not_10
jmp   label_55
sp_state_not_10:
test  byte ptr ds:[_sp_state], 1
jne   sp_state_is_odd
jump_to_exit_wi_updatestats:
jmp   exit_wi_updatestats
sp_state_is_odd:
dec   word ptr ds:[_cnt_pause]
jne   jump_to_exit_wi_updatestats
mov   word ptr ds:[_cnt_pause], TICRATE
inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
label_89:
mov   dx, SFX_SGCOCK
xor   ax, ax
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

cmp   byte ptr ds:[_commercial], 0
je    label_52
call  WI_initNoState_
pop   dx
pop   cx
pop   bx
ret   
label_52:
call  WI_initShowNextLoc_
pop   dx
pop   cx
pop   bx
ret   
cld   

ENDP


PROC WI_drawStats_ NEAR
PUBLIC WI_drawStats_


push  bx
push  cx
push  dx
push  si
mov   al, byte ptr ds:[_numRef]	; patch numref 0
xor   ah, ah
call  WI_GetPatch_
mov   si, ax
mov   es, dx
mov   dx, word ptr es:[si + 2]
mov   ax, dx
shl   ax, 2
sub   ax, dx
cwd   
sub   ax, dx
sar   ax, 1
mov   si, ax
call  WI_slamBackground_
call  WI_drawAnimatedBack_
call  WI_drawLF_
mov   ax, 3
xor   bx, bx
call  WI_GetPatch_
push  dx
mov   dx, SP_STATSY
push  ax
mov   ax, dx
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
mov   dx, SP_STATSY
mov   ax, SCREENWIDTH - SP_STATSX
mov   bx, word ptr ds:[_cnt_kills]
call  WI_drawPercent_
mov   ax, 4
lea   cx, [si + 032h]
call  WI_GetPatch_
push  dx
xor   bx, bx
push  ax
mov   dx, cx
mov   ax, SP_STATSY
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
mov   ax, SCREENWIDTH - SP_STATSX
mov   bx, word ptr ds:[_cnt_items]
mov   dx, cx
call  WI_drawPercent_
mov   ax, 26				; todo this patch
call  WI_GetPatch_
mov   cx, si
xor   bx, bx
push  dx
add   cx, cx
push  ax
add   cx, SP_STATSY
mov   ax, SP_STATSY
mov   dx, cx
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
mov   ax, SCREENWIDTH - SP_STATSX
mov   bx, word ptr ds:[_cnt_secret]
mov   dx, cx
call  WI_drawPercent_
mov   ax, 9
call  WI_GetPatch_
xor   bx, bx
push  dx
mov   dx, SP_TIMEY
push  ax
mov   ax, 16
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
mov   dx, SP_TIMEY
mov   ax, SCREENWIDTH/2 - SP_TIMEX
mov   bx, word ptr ds:[_cnt_time]
call  WI_drawTime_
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 3
jl    label_93
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_93:
mov   ax, 010
call  WI_GetPatch_
xor   bx, bx
push  dx
mov   dx, SP_TIMEY
push  ax
mov   ax, SCREENWIDTH/2 + SP_TIMEX
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr
mov   dx, SP_TIMEY
mov   ax, SCREENWIDTH - SP_TIMEX
mov   bx, word ptr ds:[_cnt_par]
call  WI_drawTime_
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP

PROC WI_checkForAccelerate_ NEAR
PUBLIC WI_checkForAccelerate_

test  byte ptr ds:[_player + 07h], BT_ATTACK			; player.cmd.buttons & BT_ATTACK
je    not_attack_pressed
cmp   byte ptr ds:[_player + 04Ch], 0					; if (!player.attackdown){
jne   attack_not_already_down
mov   word ptr ds:[_acceleratestage], 1					; accel
attack_not_already_down:
mov   byte ptr ds:[_player + 04Ch], 1					; player attackdown.
check_use:
test  byte ptr ds:[_player + 07h], BT_USE				; player.cmd.buttons & BT_USE
je    not_use_pressed
cmp   byte ptr ds:[_player + 04Dh], 0					; if (!player.usedown){
jne   use_not_altready_down
mov   word ptr ds:[_acceleratestage], 1					; accel
use_not_altready_down:
mov   byte ptr ds:[_player + 04Dh], 1
ret   
not_attack_pressed:
mov   byte ptr ds:[_player + 04Ch], 0
jmp   check_use
not_use_pressed:
mov   byte ptr ds:[_player + 04Dh], 0
ret   


ENDP



str_wi_name1:
db "INTERPIC", 0
str_wi_name2:
db "WIMAP0", 0

PROC WI_loadData_ NEAR
PUBLIC WI_loadData_

push  bx
push  cx
push  dx
push  si
push  di
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
je    label_77
lea   di, [bp - 036h]
label_50:
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 3
jne   label_51
lea   di, [bp - 036h]
label_51:
mov   dx, 1
mov   ax, di

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawFullscreenPatch_addr

mov   al, byte ptr ds:[_commercial]
test  al, al
je    label_76
label_61:
mov   word ptr [bp - 2], 0
cld   
label_75:

;	for (i = 0; i < 10; i++) {
;		numRef[i] = 14 + i;
;	}
        				

mov   al, byte ptr [bp - 2]
mov   bx, word ptr [bp - 2]
add   al, 14
inc   word ptr [bp - 2]
mov   byte ptr ds:[bx + _numRef], al
cmp   word ptr [bp - 2], 10
jl    label_75
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   


label_77:
mov   bx, word ptr ds:[_wbs]
mov   al, byte ptr [bx]
add   byte ptr [bp - 027h], al
jmp   label_50
label_76:
mov   byte ptr ds:[_yahRef+1], 1
mov   byte ptr ds:[_splatRef], 2
mov   bx, word ptr ds:[_wbs]
mov   byte ptr ds:[_yahRef], al
cmp   byte ptr [bx], 3
jge   label_61
xor   ah, ah
mov   word ptr [bp - 8], WIANIMSPAGE_SEGMENT
mov   word ptr [bp - 016h], ax
mov   word ptr [bp - 6], ax
mov   word ptr [bp - 012h], ax
mov   word ptr [bp - 0Ah], ax
mov   word ptr [bp - 014h], ax
label_63:
mov   bx, word ptr ds:[_wbs]
mov   al, byte ptr [bx]
cbw  
mov   bx, ax
mov   al, byte ptr cs:[bx + _NUMANIMS]
cbw  
cmp   ax, word ptr [bp - 0Ah]
jle   label_61
shl   bx, 2
mov   word ptr [bp - 2], 0
mov   dx, word ptr cs:[bx + _wianims]
mov   ax, word ptr cs:[bx + _wianims+2]
mov   bx, word ptr [bp - 014h]
mov   word ptr [bp - 0Eh], ax
mov   word ptr [bp - 0Ch], ax
add   bx, dx
mov   ax, word ptr [bp - 016h]
mov   word ptr [bp - 010h], bx
add   ax, ax
mov   word ptr [bp - 4], bx
mov   word ptr [bp - 018h], ax
label_74:
les   bx, dword ptr [bp - 010h]
mov   al, byte ptr es:[bx + 2]
cbw  
cmp   ax, word ptr [bp - 2]
jg    label_62
add   word ptr [bp - 014h], SIZEOF_WIANIM_T
inc   word ptr [bp - 0Ah]
jmp   label_63
label_62:
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 1
jne   label_64
jmp   label_65
label_64:
mov   bx, word ptr ds:[_wbs]



; "WIA" 57 49 41

mov   al, 041h					
mov   ah, byte ptr [bx]			; wbs->epsd
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


db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_GetNumForName_addr

mov   si, ax
call  W_LumpLength_
mov   dx, ax
mov   ax, si

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNumDirect_addr

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
label_67:
mov   word ptr es:[bx + 6], ax
add   word ptr [bp - 4], 2
inc   word ptr [bp - 2]
jmp   label_74
label_65:
cmp   word ptr [bp - 0Ah], 8
je    label_66
jmp   label_64
label_66:

;						// HACK ALERT!
;						anim->pRef[i] = epsd1animinfo[4].pRef[i];


mov   ax, EPSD1ANIMINFO_SEGMENT
mov   bx, word ptr [bp - 2]
mov   es, ax
add   bx, bx
add   bx, 046h 						; offset for this field
mov   ax, word ptr es:[bx]
mov   es, word ptr [bp - 0Ch]
mov   bx, word ptr [bp - 4]
jmp   label_67

ENDP






PROC WI_updateNoState_ NEAR
PUBLIC WI_updateNoState_

call  WI_updateAnimatedBack_

dec   word ptr ds:[_cnt]
je    WI_End_
ret   

ENDP

WI_End_:
WI_unloadData_:


mov   byte ptr ds:[_unloaded], 1
cld   

; can fall thru to G_WorldDone_.... but dont like that.
call    G_WorldDone_
ret



PROC G_WorldDone_ NEAR
PUBLIC G_WorldDone_


mov   byte ptr ds:[_gameaction], 8
cmp   byte ptr ds:[_secretexit], 0
jne   did_secret_stuff
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

did_secret_stuff:
mov   byte ptr [_player + 061h], 1 	; player didsecret
jmp   continue_world_done

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
cmp   byte ptr ds:[_secretexit], 0
je    exit_worlddone
gamemap_finalesetup:
mov   ax, 2

call  Z_SetOverlay_			; todo remove.

call  dword ptr ds:[_F_StartFinale]

;db 
;dw    F_StartFinaleOffset    ; todo doesnt exist?
;dw    code_overlay_segment

pop   bx
ret   

ENDP




PROC WI_Ticker_ FAR
PUBLIC WI_Ticker_

push  bx
push  dx
inc   word ptr ds:[_bcnt]
cmp   word ptr ds:[_bcnt], 1
jne   music_already_init
cmp   byte ptr ds:[_commercial], 0
je    set_doom1_music
;set doom2 music
mov   dx, 1
mov   ax, MUS_DM2INT
call_music:

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_ChangeMusic_addr

music_already_init:
call  Z_QuickMapIntermission_
call  WI_checkForAccelerate_
mov   al, byte ptr ds:[_state]
cmp   al, -1
je    branch_NoState
cmp   al, 1
je    branch_ShowNextLoc
test  al, al
je    branch_StatCount
done_with_state_branch:
call  Z_QuickMapPhysics_
pop   dx
pop   bx
retf  
set_doom1_music:
mov   dx, 1
mov   ax, MUS_INTER
jmp   call_music
branch_StatCount:
call  WI_updateStats_
jmp   done_with_state_branch
branch_ShowNextLoc:
call  WI_updateShowNextLoc_
jmp   done_with_state_branch
branch_NoState:
call  WI_updateNoState_
call  Z_QuickMapPhysics_
pop   dx
pop   bx
retf  

ENDP

PROC WI_Drawer_ FAR
PUBLIC WI_Drawer_

cmp   byte ptr ds:[_unloaded], 0
je    not_unloaded_do_draw
retf  
not_unloaded_do_draw:
call  Z_QuickMapIntermission_
mov   al, byte ptr ds:[_state]
cmp   al, -1
jne   not_nostate
call  WI_drawNoState_
invalid_state:
call  Z_QuickMapPhysics_
retf

not_nostate:
cmp   al, 1
je    do_ShowNextLoc
test  al, al
jne   invalid_state
call  WI_drawStats_
call  Z_QuickMapPhysics_
retf

do_ShowNextLoc:
call  WI_drawShowNextLoc_
call  Z_QuickMapPhysics_
retf

ENDP




PROC WI_initVariables_ NEAR
PUBLIC WI_initVariables_


push  bx
push  dx
push  si
push  di
mov   bx, ax
mov   dx, ax
xor   ax, ax
mov   word ptr ds:[_acceleratestage], ax
mov   word ptr ds:[_bcnt], ax
mov   word ptr ds:[_cnt], ax
mov   ax, ds
mov   es, ax
mov   di, OFFSET _plrs
lea   si, [bx + 0Ch]
movsw 
movsw 
movsw 
movsw 
movsb 
cmp   word ptr [bx + 4], 0
je    label_114
label_117:
mov   bx, dx
cmp   word ptr [bx + 6], 0
jne   label_115
mov   word ptr [bx + 6], 1
label_115:
mov   bx, dx
cmp   word ptr [bx + 8], 0
je    label_116
mov   word ptr ds:[_wbs], dx
pop   di
pop   si
pop   dx
pop   bx
ret   
label_114:
mov   word ptr [bx + 4], 1
jmp   label_117
label_116:
mov   word ptr [bx + 8], 1
mov   word ptr ds:[_wbs], dx
pop   di
pop   si
pop   dx
pop   bx
ret   



ENDP



PROC WI_Init_ NEAR
PUBLIC WI_Init_


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Eh					   ; room for lump name string

xor   si, si
mov   dx, si 					   ; loop ctr
mov   bx, si 					   ; size/dst offset

loop_wi_items:

mov   word ptr [bp - 0Ch], dx
mov   word ptr [bp - 0Eh], bx

mov   ax, WIGRAPHICS_SEGMENT
mov   ds, ax
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



db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_GetNumForName_addr


mov   di, ax				; ax has lump num, cache in di
call  W_LumpLength_

xchg  ax, di				; di gets size. ax gets lumpnum

mov   cx, WIGRAPHICSPAGE0_SEGMENT  ; dest segment for W_CacheLumpNameDirect_ for loop
mov   bx, word ptr [bp - 0Eh]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNumDirect_addr

mov   ax, WIOFFSETS_SEGMENT
mov   es, ax

mov   dx, word ptr [bp - 0Ch]  ; todo fix the above functions to not clobber registers.
mov   bx, word ptr [bp - 0Eh]

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
mov   si, word ptr ds:[_wbs]
lea   di, [bp - 0Ah]



cmp   byte ptr ds:[_commercial], 0
je    do_nondoom2_wi_init
; doom2 case


; 
; CWILV00  = 43 57 49 4C 56 30 30 0

mov   word ptr [di + 0], 05743h ; "CW"
mov   word ptr [di + 2], 04C49h ; "IL"
mov   byte ptr [di + 4], 056h ; "V"


mov   al, byte ptr [si+2]		; wbs ->last
db    0D4h, 00Ah	    ; divide by 10 using AAM
add   ax, 03030h				; add '0' to each character
mov   word ptr [di + 5], ax  ; numbers for string

mov   byte ptr [di + 7], 00h ; null terminator

mov   ax, di

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNameDirect_addr


mov   al, byte ptr [si+3]		; wbs ->next
db    0D4h, 00Ah	    ; divide by 10 using AAM
add   ax, 03030h				; add '0' to each character
mov   word ptr [di + 5], ax  ; numbers for string

jmp   do_final_init_call_and_exit

do_nondoom2_wi_init:
 
; WILV00  = 57 49 4C 56 30 30 0

mov   word ptr [di + 0], 04957h ; "WI"
mov   word ptr [di + 2], 0564Ch ; "LV"

mov   al, byte ptr [si]			; wbs ->epsd
mov   ah, byte ptr [si+2]		; wbs ->last
add   ax, 03030h				; add '0' to each character
mov   word ptr [di + 4], ax  ; numbers for string
mov   byte ptr [di + 6], 00h ; null terminator



mov   ax, di
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNameDirect_addr


mov   al, byte ptr [si+3]		; wbs ->next
add   al, 030h	 				; add '0' to character
mov   byte ptr [di + 5], al   ; update number for string


do_final_init_call_and_exit:


mov   bx, NEXT_OFFSET
mov   cx, WIGRAPHICSLEVELNAME_SEGMENT
;xchg  ax, di
lea   ax, [bp - 0Ah]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNameDirect_addr


do_exit:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP



PROC WI_Start_ FAR
PUBLIC WI_Start_

mov   byte ptr [_unloaded], 0
call  WI_initVariables_
call  WI_Init_
call  WI_loadData_
call  WI_initStats_

call  Z_QuickMapPhysics_
retf

ENDP



PROC WI_ENDMARKER NEAR
PUBLIC WI_ENDMARKER
ENDP

END