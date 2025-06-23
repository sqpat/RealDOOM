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


EXTRN R_PointToAngle_:NEAR
EXTRN Z_QuickMapVisplaneRevert_:PROC
EXTRN Z_QuickMapUndoFlatCache_:PROC
EXTRN Z_QuickMapRenderPlanes_:PROC
EXTRN R_PrepareMaskedPSprites_:NEAR
EXTRN R_RenderBSPNode_:PROC
EXTRN R_ClearPlanes_:NEAR

EXTRN Z_QuickMapRender_:PROC
EXTRN Z_QuickMapPhysics_:PROC
EXTRN NetUpdate_:PROC

EXTRN R_WriteBackFrameConstants_:NEAR
EXTRN R_ClearClipSegs_:NEAR

.DATA

EXTRN _player:PLAYER_T
EXTRN _setblocks:BYTE
EXTRN _setsizeneeded:BYTE
EXTRN _pendingdetail:WORD
EXTRN _playerMobj:WORD
EXTRN _playerMobj_pos:WORD
EXTRN _viewwindowoffset:WORD
EXTRN _r_cachedplayerMobjsecnum:WORD
EXTRN _R_DrawMaskedCall:DWORD
EXTRN _R_DrawPlanesCall:DWORD
EXTRN _R_WriteBackMaskedFrameConstantsCall:DWORD


.CODE




;R_PointToAngle2_

PROC R_PointToAngle2_ FAR
PUBLIC R_PointToAngle2_ 


;uint32_t __far R_PointToAngle2 ( fixed_t_union	x1, fixed_t_union	y1, fixed_t_union	x2, fixed_t_union	y2 ) {	
;    return R_PointToAngle (x2, y2);
;	x2.w -= x1.w;
;	y2.w -= y1.w;

; todo swap param order.

push      si
push      di
push      bp
mov       bp, sp
mov       si, word ptr [bp + 0Ah]
mov       di, word ptr [bp + 010h]
sub       si, ax
sbb       word ptr [bp + 0Ch], dx
mov       ax, si
mov       dx, word ptr [bp + 0Ch]
sub       word ptr [bp + 0Eh], bx
sbb       di, cx
mov       bx, word ptr [bp + 0Eh]
mov       cx, di
call      R_PointToAngle_
pop       bp
pop       di
pop       si
retf      8

ENDP


;R_PointToAngle2_16_

PROC R_PointToAngle2_16_ FAR
PUBLIC R_PointToAngle2_16_ 

;uint32_t __far R_PointToAngle2_16 (  int16_t	x2, int16_t	y2 ) {	
;	fixed_t_union x2fp, y2fp;
;	x2fp.h.intbits = x2;
;	y2fp.h.intbits = y2;
;	x2fp.h.fracbits = 0;
;	y2fp.h.fracbits = 0;
;    return R_PointToAngle (x2fp, y2fp);

push      bx
push      cx
push      si
mov       si, ax
mov       cx, dx
xor       bx, bx
xor       ax, ax
mov       dx, si
call      R_PointToAngle_
pop       si
pop       cx
pop       bx
retf      


ENDP



;R_SetViewSize_

PROC R_SetViewSize_ FAR
PUBLIC R_SetViewSize_ 


;void __far R_SetViewSize ( uint8_t		blocks, uint8_t		detail ) {
;    setsizeneeded = true;
;    setblocks = blocks;
;    pendingdetail = detail;
;}

; todo inline and move vars to fixeddata

mov       byte ptr ds:[_setblocks], al
mov       al, dl
xor       ah, ah
mov       byte ptr ds:[_setsizeneeded], 1
mov       word ptr ds:[_pendingdetail], ax
retf      

ENDP


;R_SetupFrame_

PROC R_SetupFrame_ NEAR
PUBLIC R_SetupFrame_ 



; todo constants.inc
SHORTFLOORBITS = 3   

; 218f

push      bx
push      cx
push      dx
push      si
mov       bx, OFFSET _extralight
mov       al, byte ptr ds:[_player + 05Eh]
mov       byte ptr ds:[bx], al
mov       bx, OFFSET _viewz
mov       ax, word ptr ds:[_player + 8]
mov       dx, word ptr ds:[_player + 0Ah]
mov       word ptr ds:[bx], ax
mov       word ptr ds:[bx + 2], dx
mov       ax, word ptr ds:[bx]
mov       bx, dx
mov       cx, 16 - SHORTFLOORBITS
label_1:
sar       bx, 1
rcr       ax, 1
loop      label_1
mov       bx, offset _viewz_shortheight
mov       word ptr ds:[bx], ax
mov       al, byte ptr ds:[_player + 05Fh]
test      al, al
je        label_2
mov       bx, OFFSET _fixedcolormap
mov       si, OFFSET _fixedcolormap
SHIFT_MACRO shl       al 2
xor       dl, dl
mov       byte ptr ds:[bx], al

label_4:
mov       al, dl
cbw      
mov       bx, ax
add       bx, OFFSET _scalelightfixed
mov       al, byte ptr ds:[si]
inc       dl
mov       byte ptr ds:[bx], al
cmp       dl, MAXLIGHTSCALE
jl        label_4
label_3:
mov       si, OFFSET _validcount_global
mov       ax, word ptr ds:[_viewwindowoffset]
mov       bx, OFFSET _destscreen
cwd       
inc       word ptr ds:[si]
add       ax, word ptr ds:[bx]
adc       dx, word ptr ds:[bx + 2]
mov       bx, OFFSET _destview
mov       word ptr ds:[bx], ax
mov       word ptr ds:[bx + 2], dx
pop       si
pop       dx
pop       cx
pop       bx
ret      
label_2:
mov       bx, OFFSET _fixedcolormap
mov       byte ptr ds:[bx], al
jmp       label_3

ENDP


;R_RenderPlayerView_

PROC R_RenderPlayerView_ NEAR
PUBLIC R_RenderPlayerView_ 



push      bx
push      cx
push      dx
push      si
push      di
mov       bx, word ptr ds:[_playerMobj]
mov       ax, word ptr ds:[bx + 4]
mov       bx, word ptr ds:[_playerMobj_pos]
mov       word ptr ds:[_r_cachedplayerMobjsecnum], ax
mov       es, word ptr ds:[_playerMobj_pos+2]
mov       si, OFFSET _viewx
mov       dx, word ptr ds:es:[bx]
mov       ax, word ptr ds:es:[bx + 2]
mov       word ptr ds:[si], dx
mov       word ptr ds:[si + 2], ax
mov       si, OFFSET _viewy
mov       ax, word ptr ds:es:[bx + 4]
mov       dx, word ptr ds:es:[bx + 6]
mov       word ptr ds:[si], ax
mov       word ptr ds:[si + 2], dx
mov       si, OFFSET _viewangle
mov       ax, word ptr ds:es:[bx + 0Eh]
mov       dx, word ptr ds:es:[bx + 010h]
mov       word ptr ds:[si], ax
mov       bx, OFFSET _viewangle + 2
mov       word ptr ds:[si + 2], dx
mov       ax, word ptr ds:[bx]
shr       ax, 1
mov       bx, OFFSET _viewangle_shiftright1
;	viewangle_shiftright1 = (viewangle.hu.intbits >> 1) & 0xFFFC;
and       al, 0FCh
mov       word ptr ds:[bx], ax
mov       bx, OFFSET _viewangle + 2
mov       ax, word ptr ds:[bx]
mov       bx, OFFSET _viewangle_shiftright3
SHIFT_MACRO shr       ax 3
mov       word ptr ds:[bx], ax

call      Z_QuickMapRender_

call      R_SetupFrame_
mov       bx, OFFSET _ds_p
call      R_WriteBackFrameConstants_
call      R_ClearClipSegs_
mov       word ptr ds:[bx], SIZEOF_DRAWSEG_T             ; drawsegs_PLUSONE
mov       word ptr ds:[bx + 2], DRAWSEGS_BASE_SEGMENT
mov       bx, OFFSET _vissprite_p
call      R_ClearPlanes_
mov       word ptr ds:[bx], 0
mov       bx, OFFSET _numnodes

;    FAR_memset (cachedheight, 0, sizeof(fixed_t) * SCREENHEIGHT);

mov       cx, 400
call      NetUpdate_
mov       ax, word ptr ds:[bx]
xor       di, di
dec       ax
mov       dx, CACHEDHEIGHT_SEGMENT

call      R_RenderBSPNode_
call      NetUpdate_
call      R_PrepareMaskedPSprites_

call      Z_QuickMapRenderPlanes_

mov       es, dx
xor       al, al
mov       bx, OFFSET _visplanedirty
push      di
mov       ah, al
rep stosw 
pop       di
cmp       byte ptr ds:[bx], 0
jne       label_6
label_5:
call      dword ptr ds:[_R_DrawPlanesCall]

call      Z_QuickMapUndoFlatCache_
call      dword ptr ds:[_R_WriteBackMaskedFrameConstantsCall]
call      dword ptr ds:[_R_DrawMaskedCall]

call      Z_QuickMapPhysics_

call      NetUpdate_
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      

label_6:
call      Z_QuickMapVisplaneRevert_

jmp       label_5

ENDP



END