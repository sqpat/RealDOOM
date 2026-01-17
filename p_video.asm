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




PROC   P_VIDEO_STARTMARKER_ NEAR
PUBLIC P_VIDEO_STARTMARKER_
ENDP


;void __far V_MarkRect ( int16_t x, int16_t y, int16_t width, int16_t height )  { 
PROC   V_MarkRect_ NEAR
PUBLIC V_MarkRect_


;    M_AddToBox16 (dirtybox, x, y); 
;    M_AddToBox16 (dirtybox, x+width-1, y+height-1); 

push      di

mov       di, OFFSET _dirtybox

add       cx, dx   
dec       cx      ; y + height - 1
add       bx, ax
dec       bx      ; x + width - 1

push      bx
call      M_AddToBox16_
pop       ax  ; restore bx
mov       dx, cx
call      M_AddToBox16_


pop       di
ret      


ENDP

;void __near M_AddToBox16 ( int16_t	x, int16_t	y, int16_t __near*	box  );

PROC    M_AddToBox16_ NEAR
PUBLIC  M_AddToBox16_

mov   bx, (2 * BOXLEFT)
cmp   ax, word ptr ds:[di + bx]
jl    write_x_to_left
mov   bl, (2 * BOXRIGHT)
cmp   ax, word ptr ds:[di + bx]
jle   do_y_compare
write_x_to_left:
mov   word ptr ds:[di + bx], ax
do_y_compare:
xchg  ax, dx
mov   bl, 2 * BOXBOTTOM
cmp   ax, word ptr ds:[di + bx]
jl    write_y_to_bottom
mov   bl, 2 * BOXTOP
cmp   ax, word ptr ds:[di + bx]
jng   exit_m_addtobox16
write_y_to_bottom:
mov   word ptr ds:[di + bx], ax
exit_m_addtobox16:
ret   


ENDP


PROC   V_DrawPatch_ NEAR
PUBLIC V_DrawPatch_

; ax is x
; dl is y
; bl is screen
; cx is patch offset
; es is patch segment

 cmp   byte ptr ds:[_skipdirectdraws], 0
 jne   exit_early

push  si 
push  di 

; bx = 2*ax for word lookup
sal   bl, 1
xor   bh, bh
mov   di, cx
mov   cx, es   
mov   es, word ptr ds:[bx + _screen_segments]   ;todo move to cs.
mov   ds, cx    ; ds:di is seg

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch

; ds:di is patch
mov   word ptr cs:[_SELFMODIFY_add_patch_offset+2], di
sub   dx, word ptr ds:[di + PATCH_T.patch_topoffset]


; calculate x + (y * screenwidth)


IF COMPISA GE COMPILE_186

    imul  si, dx , SCREENWIDTH
    add   si, ax

ELSE
    xchg  ax, si  ; si gets x
    mov   al, SCREENWIDTH / 2
    mul   dl
    sal   ax, 1
    xchg  ax, si  ; si gets x
    add   si, ax


ENDIF

; ax, dx maintained for markrect

sub   si, word ptr ds:[di + PATCH_T.patch_leftoffset]
mov   word ptr cs:[_SELFMODIFY_offset_add_di + 2], si


cmp   bl, 0
jne   dontmarkrect


push  ds
push  es 	; restore previously looked up segment.


les   bx, dword ptr ds:[di + PATCH_T.patch_width] 
mov   cx, es    ; height


push  ss
pop   ds
call  V_MarkRect_
pop   es
pop   ds



donemarkingrect:
dontmarkrect:

;    w = (patch->width); 
mov   cx, word ptr ds:[di + PATCH_T.patch_width]  ; count
lea   bx, [di + PATCH_T.patch_columnofs]          ; set up columnofs ptr
mov   dx, SCREENWIDTH - 1                         ; loop constant

draw_next_column:
push  cx            ; store patch width for outer loop iter
xor   cx, cx        ; clear ch specifically


; es:di is screen pixel target

mov   si, word ptr ds:[bx]           ; ds:bx is current patch col offset to draw

_SELFMODIFY_add_patch_offset:
add   si, 01000h

lodsw
;		while (column->topdelta != 0xff )  

cmp  al, 0FFh               ; al topdelta, ah length
je   column_done

draw_next_patch_column:

; here we render the next patch in the column.

xchg  cl, ah          ; cx is now col length, ah is now 0
inc   si      


IF COMPISA GE COMPILE_186
imul   di, ax, SCREENWIDTH   ; ax has topdelta.

ELSE
; cant fit screenwidth in 1 byte but we can do this...
mov   ah, SCREENWIDTH / 2
mul   ah
sal   ax, 1
xchg  ax, di
ENDIF



_SELFMODIFY_offset_add_di:
add   di, 01000h   ; retrieve offset

; todo lazy len 8 or 16 unrolle dloop


draw_next_patch_pixel:

movsb
add   di, dx
loop  draw_next_patch_pixel 

check_for_next_column:

inc   si
lodsw
cmp   al, 0FFh
jne   draw_next_patch_column

column_done:
add   bx, 4
inc   word ptr cs:[_SELFMODIFY_offset_add_di + 2]   ; pixel offset increments each column
pop   cx
loop  draw_next_column		; relative out of range by 5 bytes

done_drawing:
mov   ax, ss
mov   ds, ax
pop   di
pop   si
exit_early:
ret


ENDP



PROC   V_DrawPatchDirect_ NEAR
PUBLIC V_DrawPatchDirect_

; CX:BX is patch
; dx is y
; ax is x


; ARGS:
; ax is x
; dl is y
; bl is screen
; cx is patch offset
; es is patch segment

cmp   byte ptr ds:[_skipdirectdraws], 0
jne   exit_direct_early

push  si 
push  di 
push  bp    ; bp maintains current pixel and 3

les   di, dword ptr ds:[_destscreen]
mov   ds, cx

; es:di  is scren
; ds:bx  is patch



;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch

; ds:bx is patch
mov   word ptr cs:[_SELFMODIFY_add_patch_offset_direct+2], bx
sub   ax, word ptr ds:[bx + PATCH_T.patch_leftoffset]
sub   dx, word ptr ds:[bx + PATCH_T.patch_topoffset]

mov   bp, ax        ; bp gets starting x. 
and   bp, 3
SHIFT_MACRO SHR AX 2

; calculate x + (y * screenwidth)


IF COMPISA GE COMPILE_186

    imul  si, dx , SCREENWIDTH / 4
    add   ax, si  ; add x >> 2

ELSE
    xchg  ax, si    
    mov   al, SCREENWIDTH / 4
    mul   dl
    add   ax, si  ; add x >> 2

ENDIF

add   ax, di ; add currentscreen offset
mov   word ptr cs:[_SELFMODIFY_offset_add_di_direct + 2], ax

; no mark rect

;    w = (patch->width); 
mov   cx, word ptr ds:[bx + PATCH_T.patch_width]  ; count
lea   bx, [bx + PATCH_T.patch_columnofs]          ; set up columnofs ptr

draw_next_column_direct:
push  cx            ; store patch width for outer loop iter

mov   cx, bp        ; get x. already ANDed to 3, ch is 0
mov   al, 1

; select plane... 

mov   dx, SC_DATA
shl   al, cl
out   dx, al
mov   dx, ((SCREENWIDTH / 4) - 1)                 ; add per pixel write

; es:di is screen pixel target

mov   si, word ptr ds:[bx]           ; ds:bx is current patch col offset to draw

_SELFMODIFY_add_patch_offset_direct:
add   si, 01000h

lodsw                                ; while (column->topdelta != 0xff )  

cmp  al, 0FFh               ; al topdelta, ah length
je   column_done_direct

draw_next_patch_column_direct:

; here we render the next patch in the column.

xchg  cl, ah          ; cx is now col length. note ah is not 0 but doesnt matter in this case.
inc   si      

mov   ah, SCREENWIDTH / 4
mul   ah
xchg  ax, di



_SELFMODIFY_offset_add_di_direct:
add   di, 01000h   ; retrieve offset

; todo lazy len 8 or 16 unrolled loop?


draw_next_patch_pixel_direct:

movsb
add   di, dx
loop  draw_next_patch_pixel_direct

check_for_next_column_direct:

inc   si
lodsw
cmp   al, 0FFh
jne   draw_next_patch_column_direct

column_done_direct:
add   bx, 4     ; next columnofs
inc   bp        ; next plane
and   bp, 3     ; check for plane 0
jne   skip_offset_inc
inc   word ptr cs:[_SELFMODIFY_offset_add_di_direct + 2]   ; pixel offset increments each 4 columns
skip_offset_inc:
pop   cx
loop  draw_next_column_direct		; relative out of range by 5 bytes

done_drawing_direct:
push  ss
pop   ds
pop   bp
pop   di
pop   si

exit_direct_early:
ret  

ENDP



str_name_1:
db "FLOOR7_2", 0
str_name_2:
db "GRNROCK", 0
str_brdr_t:
db "brdr_t", 0
str_brdr_l:
db "brdr_l", 0
str_brdr_r:
db "brdr_r", 0
str_brdr_b:
db "brdr_b", 0
str_brdr_tl:
db "brdr_tl", 0
str_brdr_bl:
db "brdr_bl", 0
str_brdr_tr:
db "brdr_tr", 0
str_brdr_br:
db "brdr_br", 0


PROC V_DrawPatch5000Screen0_ NEAR
PUBLIC V_DrawPatch5000Screen0_

; ax is x
; dl is y

; patch is 5000:0000



 cmp   byte ptr ds:[_skipdirectdraws], 0
 jne   exit_early_5000

PUSHA_NO_AX_OR_BP_MACRO


mov   es, word ptr ds:[_screen_segments]  ; 05000h

mov   bx, SCRATCH_SEGMENT_5000
mov   ds, bx
xor   bx, bx

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch

; ds:bx is patch
mov   word ptr cs:[_SELFMODIFY_add_patch_offset_5000+2], bx
sub   dx, word ptr ds:[bx + PATCH_T.patch_topoffset]



; calculate x + (y * screenwidth)


IF COMPISA GE COMPILE_186

    imul  si, dx , SCREENWIDTH
    add   si, ax

ELSE
    xchg  ax, si  ; si gets x
    mov   al, SCREENWIDTH / 2
    mul   dl
    sal   ax, 1
    xchg  ax, si  ; si gets x
    add   si, ax


ENDIF


sub   si, word ptr ds:[bx + PATCH_T.patch_leftoffset]

; no need to mark rect. we do it in outer func..

mov   word ptr cs:[_SELFMODIFY_offset_add_di_5000 + 2], si



;    w = (patch->width); 
mov   cx, word ptr ds:[bx + PATCH_T.patch_width]  ; count
mov   bl, PATCH_T.patch_columnofs                 ; set up columnofs ptr
mov   dx, SCREENWIDTH - 1                         ; loop constant

draw_next_column_5000:
push  cx            ; store patch width for outer loop iter
xor   cx, cx        ; clear ch specifically


; es:di is screen pixel target

mov   si, word ptr ds:[bx]           ; ds:bx is current patch col offset to draw

_SELFMODIFY_add_patch_offset_5000:
add   si, 01000h

lodsw
;		while (column->topdelta != 0xff )  

cmp  al, 0FFh               ; al topdelta, ah length
je   column_done_5000

draw_next_patch_column_5000:

; here we render the next patch in the column.

xchg  cl, ah          ; cx is now col length, ah is now 0
inc   si      


IF COMPISA GE COMPILE_186
imul   di, ax, SCREENWIDTH   ; ax has topdelta.

ELSE
; cant fit screenwidth in 1 byte but we can do this...
mov   ah, SCREENWIDTH / 2
mul   ah
sal   ax, 1
xchg  ax, di
ENDIF



_SELFMODIFY_offset_add_di_5000:
add   di, 01000h   ; retrieve offset

; todo lazy len 8 or 16 unrolle dloop


draw_next_patch_pixel_5000:

movsb
add   di, dx
loop  draw_next_patch_pixel_5000 

check_for_next_column_5000:

inc   si
lodsw
cmp   al, 0FFh
jne   draw_next_patch_column_5000

column_done_5000:
add   bx, 4
inc   word ptr cs:[_SELFMODIFY_offset_add_di_5000 + 2]   ; pixel offset increments each column
pop   cx
loop  draw_next_column_5000		; relative out of range by 5 bytes

done_drawing_5000:

POPA_NO_AX_OR_BP_MACRO

push  ss
pop   ds

exit_early_5000:

ret

ENDP

exit_fillbackscreen_early:
retf

PROC   R_FillBackScreen_ FAR
PUBLIC R_FillBackScreen_


cmp       word ptr ds:[_scaledviewwidth], SCREENWIDTH
je        exit_fillbackscreen_early

PUSHA_NO_AX_OR_BP_MACRO

continue_fillbackscreen:
cmp       byte ptr ds:[_commercial], 0
mov       bx, OFFSET str_name_1
je        name_ready ; not doom2
is_doom2:
mov       bx, OFFSET str_name_2
name_ready:

;call      Z_QuickMapScratch_5000_   
; inlined

Z_QUICKMAPAI4 pageswapargs_scratch5000_offset_size INDEXED_PAGE_5000_OFFSET


xchg      ax, bx
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]		; todo once this is in asm dont re-set cx a billion times... push cx pop cx

xor       bx, bx
mov       ax, SCREEN0_SEGMENT
mov       es, ax
mov       ax, SCRATCH_SEGMENT_5000
mov       ds, ax

xor       di, di
mov       dx, 32
xor       ax, ax
cld       				; prob not necessary
loop_border_copy_outer:



; do 5 times
mov       cx, dx
mov       si, ax	; reset source texture
rep 	  movsw
mov       cx, dx
mov       si, ax	; reset source texture
rep 	  movsw
mov       cx, dx
mov       si, ax	; reset source texture
rep 	  movsw
mov       cx, dx
mov       si, ax	; reset source texture
rep 	  movsw
mov       cx, dx
mov       si, ax	; reset source texture
rep 	  movsw

add       ax, 64	  ; add 64 (next texel row)
and       ax, 00FFFh  ; mod by flat size

inc       bx
cmp       bx, (SCREENHEIGHT - SBARHEIGHT)
jb        loop_border_copy_outer

push      ss
pop       ds


; note; ax is always _filename_argument ptr


mov       ax, OFFSET str_brdr_t
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]

; reused parameters for the next region of code

mov       di, word ptr ds:[_viewwindowy]
mov       si, word ptr ds:[_viewwindowx]


xor       bx, bx
lea       dx, [di - 8]
loop_brdr_top:
lea       ax, [si + bx]
call      V_DrawPatch5000Screen0_
add       bx, 8
cmp       bx, ds:[_scaledviewwidth]
jl        loop_brdr_top
done_with_brdr_top_loop:


mov       ax, OFFSET str_brdr_b
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]

mov       dx, word ptr ds:[_viewheight]
add       dx, di

xor       bx, bx
loop_brdr_bot:
lea       ax, [si + bx]
call      V_DrawPatch5000Screen0_
add       bx, 8
cmp       bx, word ptr ds:[_scaledviewwidth]
jl        loop_brdr_bot
done_with_brdr_bot_loop:


mov       ax, OFFSET str_brdr_l
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]

mov       si, word ptr ds:[_viewwindowx]
sub       si, 8
xor       bx, bx
loop_brdr_left:
lea       dx, [di + bx]
mov       ax, si
call      V_DrawPatch5000Screen0_
add       bx, 8
cmp       bx, word ptr ds:[_viewheight]
jl        loop_brdr_left

done_with_brdr_left_loop:


mov       ax, OFFSET str_brdr_r
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]

add       si, word ptr ds:[_scaledviewwidth]
add       si, 8

xor       bx, bx
loop_brdr_right:
lea       dx, [di + bx]
mov       ax, si
call      V_DrawPatch5000Screen0_

add       bx, 8

cmp       bx, word ptr ds:[_viewheight]
jl        loop_brdr_right

done_with_brdr_right_loop:

mov       ax, OFFSET str_brdr_tl
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]


;mov       di, word ptr ds:[_viewwindowy]
mov       si, word ptr ds:[_viewwindowx]


lea       dx, [di - 8]
lea       ax, [si - 8]

call      V_DrawPatch5000Screen0_		; todo make a version based on segment 5000


mov       ax, OFFSET str_brdr_tr
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]



lea       dx, [di - 8]
mov       ax, si

add       ax, word ptr ds:[_scaledviewwidth]
call      V_DrawPatch5000Screen0_

mov       ax, OFFSET str_brdr_bl
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]

mov       dx, di
lea       ax, [si - 8]

add       dx, word ptr ds:[_viewheight]

call      V_DrawPatch5000Screen0_

mov       ax, OFFSET str_brdr_br
call      CopyString9_MapLocal_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      dword ptr ds:[_W_CacheLumpNameDirect_addr]

mov       dx, di
mov       ax, si

add       ax, word ptr ds:[_scaledviewwidth]
add       dx, word ptr ds:[_viewheight]


call      V_DrawPatch5000Screen0_


xor       bx, bx
mov       ax, 0AC00h
mov       es, ax
mov       ax, SCREEN0_SEGMENT
mov       ds, ax

mov       dx, SC_INDEX
mov       ax, (SC_MAPMASK + 0100h)  ; al/ah will store the two bytes

loop_brdr_screencopy_outer:

out       dx, al
inc       dx				; 0x3C5

xchg      al, ah
out       dx, al
dec       dx
shl       al, 1				; plane bit for next iteration
xchg      al, ah

mov       si, bx
xor       di, di
mov       cx, SCREENWIDTH * (SCREENHEIGHT - SBARHEIGHT) / 4   ; 03480h

loop_brdr_screencopy_inner:	
movsb
add       si, 3
loop      loop_brdr_screencopy_inner

inc       bx
cmp       bx, 4
jl        loop_brdr_screencopy_outer

push      ss
pop       ds

exit_fillbackscreen:

POPA_NO_AX_OR_BP_MACRO
retf     


ENDP





; copy string from cs:bx to ds:_filename_argument
; return _filename_argument in ax
; todo make use cs:si or something?

PROC CopyString9_MapLocal_ NEAR

push  si
push  di
push  cx

mov   di, OFFSET _filename_argument

push  ds
pop   es    ; es = ds

push  cs
pop   ds    ; ds = cs

xchg  ax, si ; si gets ax...

xor   ax, 0
stosw       ; zero out
stosw
stosw
stosw
stosb
mov  cx, 9
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

mov   ax, OFFSET _filename_argument   ; ax now points to the near string

push  ss
pop   ds    ; restore ds

pop   cx
pop   di
pop   si

ret

ENDP




;void __far V_CopyRect ( uint16_t srcoffset, uint16_t destoffset, uint16_t width, uint16_t height) { 

PROC   V_CopyRect_ NEAR
PUBLIC V_CopyRect_


;	if (skipdirectdraws) {
;		return;
;	}

cmp       byte ptr ds:[_skipdirectdraws], 0
jne       exit_v_copyrect



jcxz      exit_v_copyrect    ; todo necessary? ever called with 0 height?

push      si
push      di

xchg      ax, si ; set src offset
mov       di, dx ; set dst offset

mov       ax, SCREEN0_SEGMENT
mov       es, ax
mov       ax, SCREEN4_SEGMENT
mov       ds, ax

mov       ax, SCREENWIDTH
sub       ax, bx        ; screenwidth minus width

mov       dx, cx  ; outer loop counter (height)


; bx holds width, refreshes cs

copy_next_rect_line:
mov       cx, bx

shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 

add       si, ax
add       di, ax

dec       dx
jnz       copy_next_rect_line
push      ss
pop       ds
pop       di
pop       si
exit_v_copyrect:
ret      

ENDP



PROC   P_VIDEO_ENDMARKER_ NEAR
PUBLIC P_VIDEO_ENDMARKER_ 
ENDP



END