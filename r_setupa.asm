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

EXTRN  Z_QuickMapPhysics_:FAR
EXTRN  Z_QuickMapRender_:FAR
EXTRN  Z_QuickMapRenderPlanes_:FAR
EXTRN  Z_QuickMapUndoFlatCache_:FAR
EXTRN  R_InitTextureMapping_:NEAR


.DATA

EXTRN _R_WriteBackViewConstants:DWORD
EXTRN _R_WriteBackViewConstantsSpanCall:DWORD
EXTRN _R_WriteBackViewConstantsMaskedCall:DWORD


.CODE



PROC    R_SETUP_STARTMARKER_ NEAR
PUBLIC  R_SETUP_STARTMARKER_
ENDP


PROC    R_ExecuteSetViewSize_ NEAR
PUBLIC  R_ExecuteSetViewSize_

push  cx
push  dx

xor   cx, cx
xor   ax, ax
mov   byte ptr ds:[_setsizeneeded], cl
mov   byte ptr ds:[_hudneedsupdate], 6
cmp   byte ptr ds:[_setblocks], 11
jne   notfullscreen
fullscreen:
mov   word ptr ds:[_scaledviewwidth], SCREENWIDTH
mov   byte ptr ds:[_viewheight], SCREENHEIGHT
jmp   done_with_screensize

notfullscreen:
mov   al, byte ptr ds:[_setblocks]
SHIFT_MACRO  sal ax 5
mov   word ptr ds:[_scaledviewwidth], ax
;		viewheight = (setblocks * 168 / 10)&~7;
mov   al, 168 
mul   byte ptr ds:[_setblocks]
mov   dl, 10
div   dl
and   al, 0F8h   ; make multiple of 8.
mov   byte ptr ds:[_viewheight], al

done_with_screensize:


;	detailshift.b.bytelow = pendingdetail;
;	detailshift.b.bytehigh = (pendingdetail << 2); // high bit contains preshifted by four pendingdetail


mov   al, byte ptr ds:[_pendingdetail]
mov   ah, al
SHIFT_MACRO  sal ah 2
mov   word ptr ds:[_detailshift], ax

;	detailshift2minus =  (2-pendingdetail);
;	detailshiftitercount = 1 << (detailshift2minus);
;	detailshiftandval = 0 - detailshiftitercount;

mov   ah, 2
sub   ah, al
mov   byte ptr ds:[_detailshift2minus], ah
mov   cl, ah
mov   ah, 1
sal   ah, cl
mov   byte ptr ds:[_detailshiftitercount], ah
neg   ah
mov   byte ptr ds:[_detailshiftandval], ah
mov   byte ptr ds:[_detailshiftandval+1], 0FFh   ; word value...

mov   cl, al

;	viewwidth = scaledviewwidth >> detailshift.b.bytelow;

mov   ax, word ptr ds:[_scaledviewwidth]
shr   ax, cl
mov   word ptr ds:[_viewwidth], ax


;	centerx = viewwidth >> 1;
shr   ax, 1
mov   word ptr ds:[_centerx], ax
;	centery = viewheight >> 1;

mov   ax, word ptr ds:[_viewheight]
shr   ax, 1
mov   word ptr ds:[_centery], ax

;   temp.h.intbits = centery;
;	centeryfrac_shiftright4.w = temp.w >> 4;
xor   cx, cx

shr   ax, 1
rcr   cx, 1
shr   ax, 1
rcr   cx, 1
shr   ax, 1
rcr   cx, 1
shr   ax, 1
rcr   cx, 1

mov   word ptr ds:[_centeryfrac_shiftright4+0], cx
mov   word ptr ds:[_centeryfrac_shiftright4+2], ax

;	// multiple of 16 guaranteed.. can be a segment instead of offset
;	viewwindowx = (SCREENWIDTH - scaledviewwidth) >> 1;
mov   cx, SCREENWIDTH
sub   cx, word ptr ds:[_scaledviewwidth]
shr   cx, 1
mov   word ptr ds:[_viewwindowx], cx


cmp   word ptr ds:[_scaledviewwidth], SCREENWIDTH
jne   raise_view_window_base
xor   ax, ax
jmp   set_view_window_base
raise_view_window_base:
;		viewwindowy = (SCREENHEIGHT - SBARHEIGHT - viewheight) >> 1;
mov   ax, (SCREENHEIGHT - SBARHEIGHT)
sub   ax, word ptr ds:[_viewheight]
shr   ax, 1

set_view_window_base:
mov   word ptr ds:[_viewwindowy], ax

;	viewwindowoffset = (viewwindowy*(SCREENWIDTH / 4)) + (viewwindowx >> 2);
mov   dx, (SCREENWIDTH / 4)
mul   dx

; viewwindowx >> 2
SHIFT_MACRO  shr cx 2  
add   ax, cx
mov   word ptr ds:[_viewwindowoffset], ax


call	Z_QuickMapRender_
call	R_InitTextureMapping_
call	dword ptr ds:[_R_WriteBackViewConstants]
call	Z_QuickMapRenderPlanes_
call	dword ptr ds:[_R_WriteBackViewConstantsSpanCall]
call	Z_QuickMapUndoFlatCache_
call	dword ptr ds:[_R_WriteBackViewConstantsMaskedCall]
call	Z_QuickMapPhysics_

;	spanfunc_outp[0] = 1;
;	spanfunc_outp[1] = 2;
;	spanfunc_outp[2] = 4;
;	spanfunc_outp[3] = 8;

mov     ax, 00201h ; detailshift 0 case
mov     word ptr ds:[_spanfunc_outp + 2], 0804h ; technically this never has to be changed 


;	if (detailshift.b.bytelow == 1){
;		spanfunc_outp[0] = 3;
;		spanfunc_outp[1] = 12;
;	}
;	if (detailshift.b.bytelow == 2){
;		spanfunc_outp[0] = 15;
;	}

cmp   byte ptr ds:[_detailshift], 1
jb    detail_0
ja    detail_2
detail_1:
mov   ax, 3 + (12 SHL 8)
jmp   done_checking_detail
detail_2:
mov   al, 15
done_checking_detail:
detail_0:

mov     word ptr ds:[_spanfunc_outp + 0], ax

pop   dx
pop   cx
ret

ENDP



PROC    R_SETUP_ENDMARKER_ NEAR
PUBLIC  R_SETUP_ENDMARKER_
ENDP
END