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
EXTRN _scaledviewwidth:WORD
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

; todo swap param order?

push      si
push      bp
mov       bp, sp
les       si, dword ptr [bp + 8]
xchg      ax, si
sub       ax, si
mov       si, es
sbb       si, dx
mov       dx, si
les       si, dword ptr [bp + 0Ch]
sub       si, bx
mov       bx, si
mov       si, es
sbb       si, cx
mov       cx, si

call      R_PointToAngle_
pop       bp
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
mov       cx, dx
xchg      ax, dx
xor       ax, ax
mov       bx, ax
call      R_PointToAngle_
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
xor       dh, dh
mov       byte ptr ds:[_setsizeneeded], 1
mov       word ptr ds:[_pendingdetail], dx
retf      

ENDP


;R_RenderPlayerView_

PROC R_RenderPlayerView_ NEAR
PUBLIC R_RenderPlayerView_ 



PUSHA_NO_AX_MACRO

;	r_cachedplayerMobjsecnum = playerMobj->secnum;
mov       bx, word ptr ds:[_playerMobj]
push      word ptr ds:[bx + 4]  ; playerMobj->secnum
pop       word ptr ds:[_r_cachedplayerMobjsecnum]

lds       si, dword ptr ds:[_playerMobj_pos]
mov       dx, ss
mov       es, dx
mov       di, OFFSET _viewx

mov       cx, 4
rep       movsw ; viewx, viewy

add       si, 6
mov       di, OFFSET _viewangle
movsw
lodsw     ; ax has viewangle hi
stosw

; cx is 0. write to something that is 0?


mov       ds, dx ; dx already had ds
shr       ax, 1
;	viewangle_shiftright1 = (viewangle.hu.intbits >> 1) & 0xFFFC;
and       al, 0FCh
mov       word ptr ds:[_viewangle_shiftright1], ax
mov       ax, word ptr ds:[_viewangle + 2]
SHIFT_MACRO shr       ax 3
mov       word ptr ds:[_viewangle_shiftright3], ax

call      Z_QuickMapRender_
; call      R_SetupFrame_
; INLINED setupframe



;    extralight = player.extralightvalue;
mov       al, byte ptr ds:[_player + 05Eh]  ; player.extralightvalue
mov       byte ptr ds:[_extralight], al

;    viewz = player.viewzvalue;
les       ax, dword ptr ds:[_player + 8] ; player.viewzvalue
mov       word ptr ds:[_viewz], ax
mov       word ptr ds:[_viewz + 2], es
mov       dx, es
;	viewz_shortheight = viewz.w >> (16 - SHORTFLOORBITS);

sal       ax, 1
rcl       dx, 1
sal       ax, 1
rcl       dx, 1
sal       ax, 1
rcl       dx, 1


mov       word ptr ds:[_viewz_shortheight], dx

;    if (player.fixedcolormapvalue) {

mov       al, byte ptr ds:[_player + 05Fh]
test      al, al
jne       set_fixed_colormap_nonzero

set_fixed_colormap_zero:
;		fixedcolormap = 0;
mov       byte ptr ds:[_fixedcolormap], al   ; al is zero

done_setting_colormap:

;    validcount_global++;
inc       word ptr ds:[_validcount_global]

;	destview = (byte __far*)(destscreen.w + viewwindowoffset);
les       ax, dword ptr ds:[_destscreen]
add       ax, word ptr ds:[_viewwindowoffset]
mov       word ptr ds:[_destview], ax
mov       word ptr ds:[_destview + 2], es



call      R_WriteBackFrameConstants_
call      R_ClearClipSegs_

mov       word ptr ds:[_ds_p],     SIZEOF_DRAWSEG_T             ; drawsegs_PLUSONE
mov       word ptr ds:[_ds_p + 2], DRAWSEGS_BASE_SEGMENT        ; nseed to be written because masked subs 02000h from it due to remapping...
call      R_ClearPlanes_
mov       word ptr ds:[_vissprite_p], cx  ; cx is 0

;    FAR_memset (cachedheight, 0, sizeof(fixed_t) * SCREENHEIGHT);

call      NetUpdate_

mov       ax, word ptr ds:[_numnodes]
dec       ax

call      R_RenderBSPNode_
call      NetUpdate_
call      R_PrepareMaskedPSprites_
call      Z_QuickMapRenderPlanes_

mov       ax, CACHEDHEIGHT_SEGMENT
mov       es, ax
mov       di, cx  ; 0
mov       ax, cx  ; 0
mov       cx, 400

rep stosw 

cmp       byte ptr ds:[_visplanedirty], al   ; 0
jne       visplane_dirty_do_revert
done_with_visplane_revert:
call      dword ptr ds:[_R_DrawPlanesCall]
call      Z_QuickMapUndoFlatCache_
call      dword ptr ds:[_R_WriteBackMaskedFrameConstantsCall]
call      dword ptr ds:[_R_DrawMaskedCall]

call      Z_QuickMapPhysics_

call      NetUpdate_
POPA_NO_AX_MACRO
retf      
set_fixed_colormap_nonzero:

;		fixedcolormap =  player.fixedcolormapvalue << 2; 
SHIFT_MACRO shl       al 2
mov       byte ptr ds:[_fixedcolormap], al

;		for (i=0 ; i<MAXLIGHTSCALE ; i++){
;			scalelightfixed[i] = fixedcolormap;
;		}

mov       ah, al


mov       cx, ds
mov       es, cx
mov       cx, MAXLIGHTSCALE / 2
mov       di, OFFSET _scalelightfixed
rep       stosw
;		for (i=0 ; i<MAXLIGHTSCALE ; i++){
;			scalelightfixed[i] = fixedcolormap;
;		}

jmp       done_setting_colormap

visplane_dirty_do_revert:
call      Z_QuickMapVisplaneRevert_

jmp       done_with_visplane_revert

ENDP



;R_VideoErase_

PROC R_VideoErase_ NEAR
PUBLIC R_VideoErase_ 



push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
mov   bx, dx
mov   al, 2
mov   dx, SC_INDEX
out   dx, al
mov   al, 00Fh
mov   dx, SC_DATA
out   dx, al
mov   al, 5
mov   dx, GC_INDEX
mov   cx, si
out   dx, al
mov   dx, GC_INDEX+1
mov   si, OFFSET _destscreen
in    al, dx
sub   ah, ah
or    al, 1
SHIFT_MACRO shr   cx 2
out   dx, al
mov   di, word ptr [si]
xor   ax, ax
add   di, cx
mov   word ptr [bp - 2], di
mov   di, word ptr [si + 2]
adc   di, ax
mov   ax, bx
cwd
SHIFT_MACRO shl   dx 2
sbb   ax, dx
SHIFT_MACRO sar   ax 2
mov   si, word ptr [bp - 2]
mov   bx, cx
mov   cx, 0AC00h   ; todo
add   si, ax
add   bx, ax
label_2:
add   si, -1
add   ax, 0FFFFh   
add   bx, -1
test  ax, ax
jl    label_1
mov   es, cx
mov   dl, byte ptr es:[bx]
mov   es, di
mov   byte ptr es:[si], dl
jmp   label_2
label_1:
mov   al, 5
mov   dx, GC_INDEX
out   dx, al
mov   dx, GC_INDEX+1
in    al, dx
sub   ah, ah
and   al, 0FEh
out   dx, al
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
retf  

ENDP


;R_DrawViewBorder_

PROC R_DrawViewBorder_ NEAR
PUBLIC R_DrawViewBorder_ 


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   ax, word ptr ds:[_scaledviewwidth]
cmp   ax, SCREENWIDTH
jne   label_3
exit_drawviewborder:
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
label_3:
mov   bx, OFFSET _viewheight
mov   cx, SCREENHEIGHT - SBARHEIGHT
sub   cx, word ptr [bx]
mov   bx, cx
shr   bx, 1
mov   word ptr [bp - 2], bx
imul  si, bx, SCREENWIDTH
mov   di, SCREENWIDTH
sub   di, ax
sar   di, 1
mov   cx, si
add   cx, di
xor   ax, ax
mov   dx, cx
mov   bx, OFFSET _viewheight
push  cs
call  R_VideoErase_
mov   bx, word ptr [bx]
mov   ax, bx
add   ax, word ptr [bp - 2]
imul  ax, ax, SCREENWIDTH
mov   dx, cx
lea   bx, [si + SCREENWIDTH]
mov   cx, 1
mov   si, OFFSET _viewheight
sub   ax, di
sub   bx, di
push  cs
call  R_VideoErase_
add   di, di
label_4:
cmp   cx, word ptr [si]
jae   exit_drawviewborder
mov   dx, di
mov   ax, bx
push  cs
call  R_VideoErase_
inc   cx
add   bx, SCREENWIDTH
jmp   label_4


ENDP


END