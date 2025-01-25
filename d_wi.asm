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


.CODE
EXTRN M_Random_:PROC


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




END