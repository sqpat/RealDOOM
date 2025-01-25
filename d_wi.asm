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

EXTRN W_CacheLumpNameDirect_:PROC
EXTRN S_StartSound_:PROC
EXTRN M_Random_:PROC
EXTRN combine_strings_:PROC

.DATA


EXTRN _bcnt:WORD
EXTRN _wbs:WORD
EXTRN _wianims:WORD
EXTRN _NUMANIMS:WORD
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
EXTRN _F_StartFinale:DWORD
EXTRN _cnt_time:WORD
EXTRN _unloaded:BYTE
EXTRN _plrs:WORD





.CODE




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

PROC maketwocharint_ NEAR
PUBLIC maketwocharint_

push      dx
push      si
mov       si, ax
mov       es, cx
mov       cx, 10
cwd       
idiv      cx
add       ax, 030h   ; '0' char
mov       byte ptr es:[bx], al
mov       ax, si
cwd       
idiv      cx
mov       byte ptr es:[bx + 2], 0
add       dx, 030h   ; '0' char
mov       byte ptr es:[bx + 1], dl
pop       si
pop       dx
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
push  bp
mov   bp, sp
sub   sp, 8
mov   bx, ax
mov   word ptr [bp - 8], dx
mov   si, word ptr ds:[_wbs]
mov   al, byte ptr [si]
cbw  
mov   dx, ax
shl   ax, 2
add   ax, dx
add   ax, ax
add   bx, ax
mov   ax, LNODEX_SEGMENT
add   bx, bx
mov   es, ax
mov   ax, word ptr es:[bx]
mov   word ptr [bp - 6], ax
mov   ax, LNODEY_SEGMENT
mov   byte ptr [bp - 2], 0
mov   es, ax
xor   cx, cx
mov   ax, word ptr es:[bx]
mov   si, word ptr [bp - 8]
mov   word ptr [bp - 4], ax
label_3:
mov   al, byte ptr [si]
xor   ah, ah
call  WI_GetPatch_
mov   bx, ax
mov   es, dx
mov   dx, word ptr [bp - 6]
mov   ax, word ptr [bp - 4]
mov   di, word ptr es:[bx]
sub   dx, word ptr es:[bx + 4]
sub   ax, word ptr es:[bx + 6]
add   di, dx
mov   bx, word ptr es:[bx + 2]
add   bx, ax
test  dx, dx
jl    label_1
cmp   di, SCREENWIDTH
jge   label_1
test  ax, ax
jl    label_1
cmp   bx, SCREENHEIGHT
jae   label_1
label_4:
cmp   cx, 2
jl    label_2
exit_wi_drawonlnode:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_1:
inc   cx
inc   si
cmp   cx, 2
jne   label_3
cmp   byte ptr [bp - 2], 0
jne   label_4
jmp   exit_wi_drawonlnode
label_2:
mov   bx, word ptr [bp - 8]
add   bx, cx
mov   al, byte ptr [bx]
xor   ah, ah
call  WI_GetPatch_
xor   bx, bx
push  dx
mov   dx, word ptr [bp - 4]
push  ax
mov   ax, word ptr [bp - 6]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

LEAVE_MACRO
pop   di
pop   si
pop   cx
pop   bx
ret   


ENDP

exit_update_animated_back:
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   


PROC WI_updateAnimatedBack_ NEAR
PUBLIC WI_updateAnimatedBack_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   bx, OFFSET _commercial
cmp   byte ptr ds:[bx], 0
jne   exit_update_animated_back
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 2		; check episode
jg    exit_update_animated_back
xor   cx, cx
xor   si, si
label_6:
mov   bx, word ptr ds:[_wbs]
mov   al, byte ptr [bx]
cbw  
mov   bx, ax
mov   al, byte ptr ds:[bx + _NUMANIMS]
cbw  
cmp   cx, ax
jge   exit_update_animated_back
shl   bx, 2
mov   dx, word ptr ds:[bx + _wianims]
mov   ax, word ptr ds:[bx + _wianims + 2]
mov   bx, dx
mov   dx, word ptr [_bcnt]
add   bx, si
mov   es, ax
mov   word ptr [bp - 2], ax
cmp   dx, word ptr es:[bx + 0Ch]
je    label_5
label_12:
add   si, SIZEOF_WIANIM_T
inc   cx
jmp   label_6

label_5:
mov   al, byte ptr es:[bx]
cmp   al, 2
jne   label_10
cmp   byte ptr [_state], 0
jne   label_11
cmp   cx, 7
je    label_12
label_11:
mov   di, word ptr ds:[_wbs]
mov   al, byte ptr [di + 3]
mov   es, word ptr [bp - 2]
cmp   al, byte ptr es:[bx + 5]
jne   label_12
inc   byte ptr es:[bx + 0Eh]
mov   al, byte ptr es:[bx + 0Eh]
cmp   al, byte ptr es:[bx + 2]
jne   label_13
dec   byte ptr es:[bx + 0Eh]
label_13:
mov   es, word ptr [bp - 2]
mov   dl, byte ptr es:[bx + 1]
mov   ax, word ptr [_bcnt]
xor   dh, dh
add   ax, dx
mov   word ptr es:[bx + 0Ch], ax
add   si, SIZEOF_WIANIM_T
inc   cx
jmp   label_6
label_10:
cmp   al, 1
jne   label_16
add   byte ptr es:[bx + 0Eh], al
mov   al, byte ptr es:[bx + 0Eh]
cmp   al, byte ptr es:[bx + 2]
je    label_14
mov   al, byte ptr es:[bx + 1]
xor   ah, ah
add   ax, dx
mov   word ptr es:[bx + 0Ch], ax
add   si, SIZEOF_WIANIM_T
inc   cx
jmp   label_6
label_16:
test  al, al
jne   label_12
inc   byte ptr es:[bx + 0Eh]
mov   al, byte ptr es:[bx + 0Eh]
cmp   al, byte ptr es:[bx + 2]
jl    label_15
mov   byte ptr es:[bx + 0Eh], 0
label_15:
mov   es, word ptr [bp - 2]
mov   dl, byte ptr es:[bx + 1]
mov   ax, word ptr [_bcnt]
xor   dh, dh
add   ax, dx
mov   word ptr es:[bx + 0Ch], ax
add   si, SIZEOF_WIANIM_T
inc   cx
jmp   label_6
label_14:
mov   al, byte ptr es:[bx + 5]
cbw  
mov   byte ptr es:[bx + 0Eh], -1
mov   di, ax

call  M_Random_
nop   
xor   ah, ah
cwd   
idiv  di
mov   ax, word ptr [_bcnt]
mov   es, word ptr [bp - 2]
add   ax, dx
mov   word ptr es:[bx + 0Ch], ax
add   si, SIZEOF_WIANIM_T
inc   cx
jmp   label_6

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
mov   bx, OFFSET _commercial
cmp   byte ptr ds:[bx], 0
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
mov   al, byte ptr [bx + _NUMANIMS]
cbw  
cmp   cx, ax
jge   jump_to_exit_update_animated_back
shl   bx, 2
mov   ax, word ptr ds:[bx + _wianims]
mov   dx, word ptr ds:[bx + _wianims+2]
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



PROC WI_initAnimatedBack_ NEAR
PUBLIC WI_initAnimatedBack_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   bx, OFFSET _commercial
cmp   byte ptr ds:[bx], 0
jne   jump_to_label_19
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 2
jg    jump_to_label_19
xor   si, si
xor   di, di
label_18:
mov   bx, word ptr ds:[_wbs]
mov   al, byte ptr [bx]
cbw  
mov   bx, ax
mov   al, byte ptr [bx + _NUMANIMS]
cbw  
cmp   si, ax
jge   exit_init_animated_back
shl   bx, 2
mov   ax, word ptr [bx + _wianims]
mov   dx, word ptr [bx + _wianims + 2]
mov   bx, ax
mov   es, dx
add   bx, di
mov   word ptr [bp - 2], dx
mov   al, byte ptr es:[bx]
mov   byte ptr es:[bx + 0Eh], -1
test  al, al
je    label_21
cmp   al, 1
jne   label_22
mov   al, byte ptr es:[bx + 5]
cbw  
mov   cx, ax

call  M_Random_
xor   ah, ah
label_20:
cwd   
idiv  cx
mov   ax, word ptr ds:[_bcnt]
inc   ax
mov   es, word ptr [bp - 2]
add   ax, dx
label_19:
mov   word ptr es:[bx + 0Ch], ax
label_35:
add   di, SIZEOF_WIANIM_T
inc   si
jmp   label_18
jump_to_label_19:
jmp   exit_init_animated_back
label_21:
mov   cl, byte ptr es:[bx + 1]

call  M_Random_
nop   
xor   ah, ah
xor   ch, ch
jmp   label_20
label_22:
cmp   al, 2
jne   label_35
mov   ax, word ptr ds:[_bcnt]
inc   ax
jmp   label_19

exit_init_animated_back:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

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
xor   ax, ax
mov   word ptr ds:[_cnt], 10
mov   word ptr ds:[_acceleratestage], ax
ret   

ENDP

PROC WI_initShowNextLoc_ NEAR
PUBLIC WI_initShowNextLoc_


mov   byte ptr ds:[_state], 1
xor   ax, ax
mov   word ptr ds:[_cnt], SHOWNEXTLOCDELAY * TICRATE
mov   word ptr ds:[_acceleratestage], ax
jmp 	WI_initAnimatedBack_

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
jae   label_43
mov   al, 1
mov   byte ptr ds:[_snl_pointeron], al
ret   
label_43:
xor   al, al
mov   byte ptr ds:[_snl_pointeron], al
ret   

label_36:
call  WI_drawEL_
pop   dx
pop   cx
pop   bx
ret   
label_44:
cbw  
jmp   label_39

ENDP

PROC WI_drawNoState_ NEAR
PUBLIC WI_drawNoState_

mov   byte ptr ds:[_snl_pointeron], 1
call  WI_drawShowNextLoc_
ret
; could just fall thru...
ENDP

PROC WI_drawShowNextLoc_ NEAR
PUBLIC WI_drawShowNextLoc_

push  bx
push  cx
push  dx
mov   bx, OFFSET _commercial
call  WI_slamBackground_
call  WI_drawAnimatedBack_
cmp   byte ptr ds:[_commercial], 0
jne   label_37
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx], 2
jg    label_36
mov   al, byte ptr [bx + 2]
cmp   al, 8
jne   label_44
mov   al, byte ptr [bx + 3]
cbw  
dec   ax
label_39:
mov   cx, ax
xor   bx, bx
test  ax, ax
jl    label_45
label_47:
mov   dx, OFFSET _splatRef
mov   ax, bx
inc   bx
call  WI_drawOnLnode_
cmp   bx, cx
jle   label_47
label_45:
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx + 1], 0
je    label_46
mov   dx, OFFSET _splatRef
mov   ax, 8
call  WI_drawOnLnode_
label_46:
cmp   byte ptr ds:[_snl_pointeron], 0
je    label_37
mov   bx, word ptr ds:[_wbs]
mov   al, byte ptr [bx + 3]
mov   dx, OFFSET _yahRef
cbw  
call  WI_drawOnLnode_
label_37:
mov   bx, OFFSET _commercial
cmp   byte ptr [bx], 0
je    label_36
mov   bx, word ptr ds:[_wbs]
cmp   byte ptr [bx + 3], 30
je    exit_this_func_todo
jmp   label_36
exit_this_func_todo:
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC WI_initStats_ NEAR
PUBLIC WI_initStats_

xor   al, al
mov   byte ptr ds:[_state], al
xor   ah, ah
mov   word ptr ds:[_sp_state], 1
mov   word ptr ds:[_acceleratestage], ax
mov   ax, -1
mov   word ptr ds:[_cnt_pause], TICRATE
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
je    label_92
cmp   word ptr ds:[_sp_state], 10
je    label_92
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
call  S_StartSound_
mov   word ptr ds:[_sp_state], 10
label_55:
cmp   word ptr ds:[_acceleratestage], 0
jne   jump_to_label_89
exit_wi_updatestats:
pop   dx
pop   cx
pop   bx
ret   
label_92:
mov   ax, word ptr ds:[_sp_state]
cmp   ax, 2
jne   label_91
add   word ptr ds:[_cnt_kills], ax
test  byte ptr ds:[_bcnt], 3
jne   label_90
mov   dx, 1
xor   ax, ax
call  S_StartSound_
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
call  S_StartSound_
inc   word ptr ds:[_sp_state]
jmp   exit_wi_updatestats
jump_to_label_89:
jmp   label_89
label_91:
cmp   ax, 4
jne   label_87
add   word ptr ds:[_cnt_items], 2
test  byte ptr ds:[_bcnt], 3
jne   label_88
mov   dx, sfx_pistol
xor   ax, ax
call  S_StartSound_
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
call  S_StartSound_
inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
label_87:
cmp   ax, 6
jne   label_58
add   word ptr ds:[_cnt_secret], 2
test  byte ptr ds:[_bcnt], 3
jne   label_57
mov   dx, sfx_pistol
xor   ax, ax
call  S_StartSound_
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
call  S_StartSound_
inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
label_58:
cmp   ax, 8
jne   label_59
test  byte ptr ds:[_bcnt], 3
jne   label_60
mov   dx, 1
xor   ax, ax
call  S_StartSound_
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
call  S_StartSound_
inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
label_59:
cmp   ax, 10
jne   label_56
jmp   label_55
label_56:
test  byte ptr ds:[_sp_state], 1
jne   label_54
jump_to_exit_wi_updatestats:
jmp   exit_wi_updatestats
label_54:
dec   word ptr ds:[_cnt_pause]
jne   jump_to_exit_wi_updatestats
mov   word ptr ds:[_cnt_pause], TICRATE
inc   word ptr ds:[_sp_state]
pop   dx
pop   cx
pop   bx
ret   
label_89:
mov   dx, 3
xor   ax, ax
mov   bx, OFFSET _commercial
call  S_StartSound_
cmp   byte ptr [bx], 0
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
str_wia:
db "WIA", 0

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
movsb 
lea   di, [bp - 02Ch]
mov   si, OFFSET str_wi_name2
movsw 
movsw 
movsw 
movsw 
movsb 
push    ss
pop     ds

mov   bx, OFFSET _commercial
lea   di, [bp - 02Ch]
cmp   byte ptr [bx], 0
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
mov   bx, OFFSET _commercial

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawFullscreenPatch_addr

mov   al, byte ptr [bx]
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
mov   al, byte ptr ds:[bx + _NUMANIMS]
cbw  
cmp   ax, word ptr [bp - 0Ah]
jle   label_61
shl   bx, 2
mov   word ptr [bp - 2], 0
mov   dx, word ptr [bx + _wianims]
mov   ax, word ptr [bx + _wianims+2]
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
mov   al, byte ptr [bx]
mov   cx, ds
add   al, 030h					; '0' char
lea   bx, [bp - 01eh]
mov   byte ptr [bp - 01ah], al
mov   ax, word ptr [bp - 0Ah]
mov   byte ptr [bp - 019h], 0
call  maketwocharint_
lea   bx, [bp - 022h]
mov   ax, word ptr [bp - 2]
mov   cx, ds
lea   dx, [bp - 01ah]
call  maketwocharint_
push  ds
push  dx
mov   cx, cs
mov   bx, OFFSET str_wia
mov   dx, ds
mov   ax, di


; cx is ds
; ax is di (stack ptr)
; bx is offset
; dx is ds
; first pushed is ds
; first pushed is offset
; first pushed is cs

call  combine_strings_
nop   
lea   dx, [bp - 01eh]
push  ds
mov   bx, di
mov   cx, ds
mov   ax, di
push  dx
mov   dx, ds

call  combine_strings_
nop   
lea   dx, [bp - 022h]
push  ds
mov   bx, di
mov   cx, ds
mov   ax, di
push  dx
mov   dx, ds

call  combine_strings_
nop   
mov   bx, word ptr [bp - 012h]
mov   ax, di
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



label_68:
cmp   al, 31
je    label_72
cmp   al, 30
je    label_71
cmp   al, 014h
jmp   label_70



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

push  bx
mov   bx, OFFSET _gameaction
mov   byte ptr [bx], 8
cmp   byte ptr ds:[_secretexit], 0
jne   label_85
label_73:
mov   bx, OFFSET _commercial
cmp   byte ptr [bx], 0
je    label_69
mov   bx, OFFSET _gamemap
mov   al, byte ptr [bx]
cmp   al, 15
jae   jump_to_label_68
cmp   al, 11
je    label_71
cmp   al, 6
label_70:
je    label_71
label_69:
pop   bx
ret   

label_85:
mov   byte ptr [_player + 061h], 1 	; player didsecret
jmp   label_73
jump_to_label_68:
ja    label_68
label_72:
cmp   byte ptr ds:[_secretexit], 0
je    label_69
label_71:
mov   ax, 2

call  Z_SetOverlay_			; todo remove.

call  dword ptr ds:[_F_StartFinale]

;db 
;dw    F_StartFinaleOffset    ; todo doesnt exist?
;dw    code_overlay_segment

pop   bx
ret   

ENDP


END