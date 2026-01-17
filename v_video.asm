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

; this is the only case that uses SCREEN1_SEGMENT
mov    word ptr cs:[_screen_lookup], SCREEN1_SEGMENT
call   V_DrawFullscreenPatch_
mov    word ptr cs:[_screen_lookup], SCREEN0_SEGMENT
call   Z_QuickMapIntermission_
retf
ENDP


PROC   V_DrawFullscreenPatch_FromMenu_ FAR
PUBLIC V_DrawFullscreenPatch_FromMenu_
call   V_DrawFullscreenPatch_
call   Z_QuickMapMenu_
retf
ENDP

_screen_lookup:
dw SCREEN0_SEGMENT

PROC   V_DrawFullscreenPatch_ FAR
PUBLIC V_DrawFullscreenPatch_



PUSHA_NO_AX_OR_BP_MACRO
push      bp
mov       bp, sp
push      bp



xor       si, si
mov       bp, si   ; offset lo

mov       word ptr cs:[_SELFMODIFY_add_extra_offset+2], si ; offset
mov       word ptr cs:[_SELFMODIFY_set_desttop+1], si      ; desttop


mov       di, SCRATCH_SEGMENT_5000




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








;	if (screen == 1) {
;		desttop = screen1;
;	} else {
;		desttop = screen0;
;	}

; direct markrect fullscreen

mov       bx, OFFSET _dirtybox



mov       word ptr ds:[bx + 2 * BOXBOTTOM], si ; 0
mov       word ptr ds:[bx + 2 * BOXLEFT],   si ; 0
mov       word ptr ds:[bx + 2 * BOXTOP],    SCREENHEIGHT - 1
mov       word ptr ds:[bx + 2 * BOXRIGHT],  SCREENWIDTH - 1




mov       bx, PATCH_T.patch_columnofs  ; column offset

mov       ds, di   ; SCRATCH_SEGMENT_5000
mov       cx, word ptr ds:[si + PATCH_T.patch_width]      ;	w = (patch->width);


mov       es, word ptr cs:[_screen_lookup]
do_next_fullscreen_column:

push      cx

; column = (column_t  __far*)((byte  __far*)extradata + ((patch->columnofs[col]) - offset));
;		pageoffset = (byte  __far*)column - extradata;

mov       si, word ptr ds:[bx]  ; columnofs
sub       si, bp  ; - offset
mov       ax, si
_SELFMODIFY_add_extra_offset:
add       si, 01000h

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
xor       cx, cx

;  dest = desttop + column->topdelta * SCREENWIDTH;
mov       cl, ah   
mov       ah, SCREENWIDTHOVER2
mul       ah
sal       ax, 1
_SELFMODIFY_set_desttop:
mov       di, 01000h  ; desttop
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
lodsw
cmp       al, 0FFh
jne       column_has_post


column_has_no_posts:
add       bx, 4    ; next column?
inc       word ptr cs:[_SELFMODIFY_set_desttop+1]       ; inc dest x pixel.
pop       cx  ; restore loop ptr

loop      do_next_fullscreen_column  ;1fh bytes..

exit_drawfullscreenpatch:

push      ss
pop       ds

call       Z_QuickMapPhysics_

pop       bp
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
retf      
load_next_lump_fragment:




;    byte __far*	patch2 = (byte __far *) (0x50008000);

mov       cx, ds  ; patch2

push      bx
push      es
push      ds

push      ss
pop       ds


xor       bx, bx
push      bx  ; 0 argument for high bits of offset
mov       bx, 08000h ; offset

;    offset += pageoffset;
add       bp, ax



SELFMODIFY_set_ax_to_lump:
mov       ax, 01000h

;    extradata = patch2;
mov       word ptr cs:[_SELFMODIFY_add_extra_offset+2], bx ; offset
push      bp   ; 2nd arg low bits of offset
;    W_CacheLumpNumDirectFragment(lump, patch2,  offset);

call      W_CacheLumpNumDirectFragment_


;    column = (column_t  __far*)((byte  __far*)extradata + patch->columnofs[col] - offset);

pop       ds
pop       es
pop       bx
mov       si, word ptr ds:[bx]
add       si, 08000h ; offset
sub       si, bp

jmp       lump_fragment_loaded

ENDP

END
