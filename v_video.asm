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

EXTRN M_AddToBox16_:NEAR
.DATA


.CODE
EXTRN W_CacheLumpNameDirect_:FAR
EXTRN Z_QuickMapScratch_5000_:FAR  
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN W_CacheLumpNumDirectFragment_:FAR
EXTRN Z_QuickMapByTaskNum_:FAR
EXTRN Z_QuickMapPhysics_FunctionAreaOnly_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapPalette_:FAR


_jump_mult_table_3:
db 19, 18, 15, 12,  9,  6,  3, 0

PROC V_DrawPatch_ FAR
PUBLIC V_DrawPatch_

; ax is x
; dl is y
; bl is screen
; cx is unused?
; bp + 0c is ptr to patch

 

; todo: modify stack amount
; todo: use dx for storing a loop var
; todo: use cx more effectively. ch and cl?
; todo: change input to not be bp based
; possible todo: interrupts, sp
; todo: make 8086

push  cx   ; +2
push  si   ; +4
push  di   ; +6
push  bp   ; +8       thus 0A 0C is far patch
mov   bp, sp
push  dx

mov   cl, bl   ; do push?
; bx = 2*ax for word lookup
sal   bl, 1
xor   bh, bh
mov   es, word ptr ds:[bx + _screen_segments]


cmp   byte ptr ds:[_skipdirectdraws], 0
je    doing_draws
jumptoexit:
jmp   jumpexit
doing_draws:

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch

lds   bx, dword ptr [bp + 0Ch]
sub   dl, byte ptr ds:[bx + 6]
add   bx, 8
; for 486 with larger prefetch queues we must write this BX as early as possible.
mov   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction + 1], bx  ; store column

xor   dh, dh

; si = y * screenwidth



IF COMPISA GE COMPILE_186

imul   si, dx , SCREENWIDTH

ELSE

mov    si, dx
mov    di, ax
mov    ax, SCREENWIDTH
mul    dx
mov    dx, si
mov    si, ax
mov    ax, di


ENDIF

add    si, ax


sub   si, word ptr ds:[bx - 4]	; bx has 8 added to it


cmp   cl, 0
jne   dontmarkrect
jmp   domarkrect
dontmarkrect:
donemarkingrect:

; 	desttop = MK_FP(screen_segments[scrn], offset); 



; load patch addr again
mov   word ptr cs:[OFFSET SELFMODIFY_offset_add_di + 2], si
mov   bx, word ptr [bp + 0Ch]

;    w = (patch->width); 
mov   ax, word ptr ds:[bx]

mov   word ptr cs:[OFFSET SELFMODIFY_compare_instruction + 1], ax  ; store width
test  ax, ax
jle   jumptoexit
; store patch segment (???) remove;

draw_next_column:

dec   word ptr cs:[OFFSET SELFMODIFY_compare_instruction + 1] ; decrement count ahead of time

;		column = (column_t __far *)((byte __far*)patch + (patch->columnofs[col])); 

; ds:si is patch segment
; es:di is screen pixel target

; grab patch offset into di
mov   si, word ptr [bp + 0Ch]
SELFMODIFY_setup_bx_instruction:
mov   bx, 0F030h               ; F030h is target for self modifying code     
; si equals colofs lookup
add   si, word ptr ds:[bx]

;		while (column->topdelta != 0xff )  
; check topdelta for 0xFFh
cmp   byte ptr ds:[si], 0FFh
je   column_done


; here we render the next patch in the column.
draw_next_column_patch:


; grab both column fields at once. si + 0 is topdelta. si + 1 is column length
mov   ax, word ptr ds:[si]

mov   cl, ah

; cant optimize this because of the negative case with imul apparently.

IF COMPISA GE COMPILE_186
xor    ah, ah      ; al contains topdelta
imul   di, ax, SCREENWIDTH
mov    dx, SCREENWIDTH - 1 

ELSE
; cant fit screenwidth in 1 byte but we can do this...
mov   ah, SCREENWIDTH / 2
mul   ah
sal   ax, 1
mov   dx, SCREENWIDTH - 1
mov   di, ax


ENDIF



SELFMODIFY_offset_add_di:
add   di, 0F030h   ; retrieve offset


add   si, 3
; figure out loop counts
mov   bl, cl
and   bx, 0007h
mov   al, byte ptr cs:[_jump_mult_table_3 + bx]
mov   byte ptr cs:[SELFMODIFY_offset_draw_remaining_pixels + 1], al
SHIFT_MACRO shr cx 3
je    done_drawing_8_pixels


; bx, cx unused...

;  todo full unroll

draw_8_more_pixels:

movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx

loop   draw_8_more_pixels


done_drawing_8_pixels:

SELFMODIFY_offset_draw_remaining_pixels:
db 0EBh, 00h		; jump rel8


movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb
add di, dx
movsb


; restore stuff we changed above
done_drawing_pixels:
check_for_next_column:

inc si
cmp   byte ptr ds:[si], 0FFh


jne   draw_next_column_patch
column_done:
add   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction + 1], 4
inc   word ptr cs:[OFFSET SELFMODIFY_offset_add_di + 2]
xor   ax, ax
SELFMODIFY_compare_instruction:
cmp   ax, 0F030h		; compare to width
;jnge  draw_next_column		; relative out of range by 5 bytes
jge   jumpexit
jmp   draw_next_column
jumpexit:
pop   dx
mov   ax, ss
mov   ds, ax
LEAVE_MACRO
pop   di
pop   si
pop   cx
retf  4

domarkrect:
push  ds
lds   bx, dword ptr ds:[bx - 8]
mov   cx, ds

mov  di, ss
mov  ds, di


push es 	; remove push/pop es and read this screen crashes
call  V_MarkRect_
pop  es
pop  ds
jmp   donemarkingrect

ENDP









PROC   R_FillBackScreen_ForceBufferRedraw_ NEAR
PUBLIC R_FillBackScreen_ForceBufferRedraw_

mov    byte ptr ds:[_hudneedsupdate], 6
mov    byte ptr ds:[_borderdrawcount], 3
call   Z_QuickMapPhysics_  ; page in code and screen 0

; fall thru
;call  R_FillBackScreen_
db      09Ah
dw      R_FILLBACKSCREEN_OFFSET, PHYSICS_HIGHCODE_SEGMENT


ret
ENDP


;void __far V_MarkRect ( int16_t x, int16_t y, int16_t width, int16_t height )  { 
PROC V_MarkRect_ FAR
PUBLIC V_MarkRect_


;    M_AddToBox16 (dirtybox, x, y); 
;    M_AddToBox16 (dirtybox, x+width-1, y+height-1); 

push      di

add       cx, dx   
dec       cx      ; y + height - 1
add       bx, ax
dec       bx      ; x + width - 1
mov       di, bx

mov       bx, OFFSET _dirtybox

call      M_AddToBox16_

xchg      ax, di
mov       dx, cx
mov       bx, OFFSET _dirtybox
call      M_AddToBox16_

pop       di

retf      

ENDP



;void __far V_DrawFullscreenPatch ( int8_t __far* pagename, int8_t screen) {

PROC V_DrawFullscreenPatch_ FAR
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

;	V_MarkRect(0, 0, w, (patch->height));
call      V_MarkRect_

;	if (screen == 1) {
;		desttop = screen1;
;	} else {
;		desttop = screen0;
;	}


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

mov       al, byte ptr ds:[_currenttask]
call      Z_QuickMapByTaskNum_  ; todo get rid of this? call safely
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
