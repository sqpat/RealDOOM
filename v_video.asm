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
INSTRUCTION_SET_MACRO


; NOTE i think a lot of this function is an optimization candidate
; todo move jump mult table to cs...


.DATA


.CODE
EXTRN W_CacheLumpNameDirect_:FAR
EXTRN Z_QuickMapScratch_5000_:NEAR  
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN W_CacheLumpNumDirectFragment_:FAR
EXTRN Z_QuickMapPhysics_:NEAR
EXTRN Z_QuickMapMenu_:NEAR
EXTRN Z_QuickMapIntermission_:NEAR








PROC   R_FillBackScreen_ForceBufferRedraw_ NEAR
PUBLIC R_FillBackScreen_ForceBufferRedraw_

mov    byte ptr ds:[_hudneedsupdate], 6
mov    byte ptr ds:[_borderdrawcount], 3
;call   Z_QuickMapPhysics_  ; page in code and screen 0

; fall thru
;call  R_FillBackScreen_
db      09Ah
dw      R_FILLBACKSCREEN_OFFSET, PHYSICS_HIGHCODE_SEGMENT


ret
ENDP






;void __far V_DrawFullscreenPatch ( int8_t __far* pagename, int8_t screen) {


PROC   V_DrawFullscreenPatch_FromIntermission_ FAR
PUBLIC V_DrawFullscreenPatch_FromIntermission_
call   V_DrawFullscreenPatch_
call   Z_QuickMapIntermission_
retf
ENDP


PROC   V_DrawFullscreenPatch_FromMenu_ FAR
PUBLIC V_DrawFullscreenPatch_FromMenu_
call   V_DrawFullscreenPatch_
call   Z_QuickMapMenu_
retf
ENDP


PROC   V_DrawFullscreenPatch_ FAR
PUBLIC V_DrawFullscreenPatch_

; bp - 2     desttop segment
; bp - 4     extradata ?
; bp - 6     offset lo
; bp - 8   desttop offset
; bp - 0Ah   SCRATCH_SEGMENT_5000
; bp - 0Ch   width



PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp

cmp       bl, 1
je        use_screen_1_for_fullscreendraw
mov       bx, SCREEN0_SEGMENT 
jmp       done_choosing_screen_for_fullscreendraw
use_screen_1_for_fullscreendraw:
mov       bx, SCREEN1_SEGMENT
done_choosing_screen_for_fullscreendraw:


push      bx        ; bp - 2
xor       si, si
push      si  ; bp - 4
push      si  ; bp - 6
push      si  ; bp - 8

mov       di, SCRATCH_SEGMENT_5000
push      di  ; bp - 0Ah



;	int16_t lump = W_GetNumForName(pagename);call      W_GetNumForName_
call      W_CheckNumForNameFarString_

mov       word ptr cs:[SELFMODIFY_set_ax_to_lump+1], ax 
mov       cx, di
mov       bx, si    ; cx:bx is extradata
xchg      ax, dx

call      Z_QuickMapScratch_5000_
mov       ax, dx

push      si    ; arg 0
push      si    ; arg 0
;	W_CacheLumpNumDirectFragment(lump, extradata, 0);
call      W_CacheLumpNumDirectFragment_

mov       es, di

mov       ax, si ; ax 0
cwd              ; dx 0
les       bx, dword ptr es:[si]      ;	w = (patch->width);
mov       cx, es                      ; patch->height arg

push      bx  ; bp - 0Ch


;	if (screen == 1) {
;		desttop = screen1;
;	} else {
;		desttop = screen0;
;	}

; direct markrect fullscreen

mov       bx, OFFSET _dirtybox
xor       ax, ax

mov       word ptr ds:[bx + 2 * BOXBOTTOM], ax
mov       word ptr ds:[bx + 2 * BOXLEFT],   ax
mov       word ptr ds:[bx + 2 * BOXTOP],    SCREENHEIGHT - 1
mov       word ptr ds:[bx + 2 * BOXRIGHT],  SCREENWIDTH - 1

mov       bx, 8  ; column offset


;	for (col = 0; col < w; col++, desttop++) {


mov       ds, di
mov       es, word ptr [bp - 2]
do_next_fullscreen_column:

; column = (column_t  __far*)((byte  __far*)extradata + ((patch->columnofs[col]) - offset));
;		pageoffset = (byte  __far*)column - extradata;

mov       si, word ptr ds:[bx]  ; columnofs
sub       si, word ptr [bp - 6]  ; - offset
mov       ax, si
add       si, word ptr [bp - 4]  ; + extradata offset





;		if (pageoffset > 16000) {
cmp       ax, 16000   ; todo more uh scientific number
jg        load_next_lump_fragment
lump_fragment_loaded:
mov       dx, SCREENWIDTH-1
load_next_column_post:
lodsw
cmp       al, 0FFh

;    while (column->topdelta != 0xff) {

je       column_has_no_posts

column_has_post:

;  dest = desttop + column->topdelta * SCREENWIDTH;
xor       cx, cx
mov       cl, ah   
mov       ah, SCREENWIDTHOVER2
mul       ah
sal       ax, 1
mov       di, word ptr [bp - 8]  ; desttop
add       di, ax

inc       si

; could loop 4 but who cares.
;			if ((count -= 2) >= 0) {
dec       cx
dec       cx
jl        draw_less_than_2_pixels


loop_2_pixels:
movsb
add       di, dx
movsb
add       di, dx

dec       cx
dec       cx
jge       loop_2_pixels

draw_less_than_2_pixels:
inc       cx
jne       zero_pixels_left_to_draw ; if still negative then its no draw


movsb ; one pixel left

zero_pixels_left_to_draw:

inc       si  ; set column post addr
jmp       load_next_column_post

column_has_no_posts:
add       bx, 4    ; next column?
inc       word ptr [bp - 8]       ; inc dest x pixel.
dec       word ptr [bp - 0Ch]
jne       do_next_fullscreen_column  ;1fh bytes..

exit_drawfullscreenpatch:

mov       ax, ss
mov       ds, ax ; restore ds

call       Z_QuickMapPhysics_

LEAVE_MACRO
POPA_NO_AX_MACRO
retf      
load_next_lump_fragment:


cwd     ; zero dx

;    byte __far*	patch2 = (byte __far *) (0x50008000);
mov       dx, bx ; store column..
xor       bx, bx
push      bx  ; 0 argument
mov       bx, 08000h ; offset
mov       cx, SCRATCH_SEGMENT_5000  ; patch2

;    offset += pageoffset;
add       word ptr [bp - 6], ax

mov       ax, ss
mov       ds, ax

SELFMODIFY_set_ax_to_lump:
mov       ax, 01000h

;    extradata = patch2;
mov       word ptr [bp - 4], bx ; offset
push      word ptr [bp - 6]
;    W_CacheLumpNumDirectFragment(lump, patch2,  offset);

call      W_CacheLumpNumDirectFragment_

mov       bx, dx ; restore column..

;    column = (column_t  __far*)((byte  __far*)extradata + patch->columnofs[col] - offset);

mov       es, word ptr [bp - 2]
mov       ds, word ptr [bp - 0Ah]
mov       si, word ptr ds:[bx]
add       si, 08000h ; offset
sub       si, word ptr [bp - 6]

jmp       lump_fragment_loaded

ENDP

END
