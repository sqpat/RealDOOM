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
sub       sp, 2
mov       di, 5 * 2
mov       ax, WIOFFSETS_SEGMENT
mov       cx, WIANIMSPAGE_SEGMENT
mov       dx, 2
xor       si, si
xor       bx, bx
mov       es, ax
mov       ax, SCREENWIDTH
mov       di, word ptr es:[di]
mov       es, cx
push      cx
sub       ax, word ptr es:[si]
push      si
sar       ax, 1
mov       word ptr [bp - 2], WIGRAPHICSPAGE0_SEGMENT

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_DrawPatch_addr

push      WIGRAPHICSPAGE0_SEGMENT
mov       es, cx
mov       ax, SCREENWIDTH
mov       si, word ptr es:[si + 2]
xor       bx, bx
mov       dx, si
push      di
shl       dx, 2
mov       es, word ptr [bp - 2]
add       dx, si
sub       ax, word ptr es:[di]
sar       dx, 2
sar       ax, 1
add       dx, 2

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


SIZEOF_WIANIM_T = 010h

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
push  cs
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

END