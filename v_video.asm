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
EXTRN W_CacheLumpNumDirectFragment_:PROC  
EXTRN Z_QuickMapByTaskNum_:FAR



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
mov   al, byte ptr ss:[_jump_mult_table_3 + bx]
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



PROC V_DrawPatch5000Screen0_ NEAR
PUBLIC V_DrawPatch5000Screen0_

; ax is x
; dl is y

; patch is 5000:0000

 

; todo: modify stack amount
; todo: use dx for storing a loop var
; todo: use cx more effectively. ch and cl?
; todo: change input to not be bp based
; possible todo: interrupts, sp
; todo: make 8086

push  cx
push  si
push  di
push  dx
push  bx
push  ds
mov   es, word ptr ds:[_screen_segments]


cmp   byte ptr ds:[_skipdirectdraws], 0
je    doing_draws5000Screen0_
jumptoexit5000Screen0_:
jmp   jumpexit5000Screen0_
doing_draws5000Screen0_:

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
;	offset = y * SCREENWIDTH + x;

; load patch
; for 486 with larger prefetch queues we must write this BX as early as possible.
mov   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction5000Screen0_ + 1], 8  ; store column

mov   bx, SCRATCH_SEGMENT_5000
mov   ds, bx
xor   bx, bx



sub   dl, byte ptr ds:[bx + 6]	; patch topoffset
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


sub   si, word ptr ds:[bx + 4]	; patch left offset



; no need to mark rect. we do it in outer func..


; 	desttop = MK_FP(screen_segments[scrn], offset); 


; load patch addr again
mov   word ptr cs:[OFFSET SELFMODIFY_offset_add_di5000Screen0_ + 2], si

;    w = (patch->width); 
mov   ax, word ptr ds:[bx]

mov   word ptr cs:[OFFSET SELFMODIFY_compare_instruction5000Screen0_ + 1], ax  ; store width
test  ax, ax
jle   jumptoexit5000Screen0_
; store patch segment (???) remove;

draw_next_column5000Screen0_:

dec   word ptr cs:[OFFSET SELFMODIFY_compare_instruction5000Screen0_ + 1] ; decrement count ahead of time

;		column = (column_t __far *)((byte __far*)patch + (patch->columnofs[col])); 

; ds:si is patch segment
; es:di is screen pixel target

SELFMODIFY_setup_bx_instruction5000Screen0_:
mov   bx, 0F030h               ; F030h is target for self modifying code     

; si equals colofs lookup
mov   si, word ptr ds:[bx]

;		while (column->topdelta != 0xff )  
; check topdelta for 0xFFh
cmp   byte ptr ds:[si], 0FFh
jne   draw_next_column_patch5000Screen0_
jmp   column_done5000Screen0_


; here we render the next patch in the column.
draw_next_column_patch5000Screen0_:


; grab both column fields at once. si + 0 is topdelta. si + 1 is column length
mov   ax, word ptr ds:[si]

mov   cl, ah
xor   ah, ah      ; al contains topdelta

; todo: figure this out.
; either one works on its own, but the else branch will fail regardless
; of which code is in it if the if is active. Probably related to 
; selfmodifying code references.

IF COMPISA GE COMPILE_186
imul   di, ax, SCREENWIDTH
mov    dx, SCREENWIDTH - 1 

ELSE

mov   di, SCREENWIDTH
mul   di
mov   dx, di
mov   di, ax
dec   dx

ENDIF



SELFMODIFY_offset_add_di5000Screen0_:
add   di, 0F030h   ; retrieve offset


add   si, 3
; figure out loop counts
mov   bl, cl
and   bx, 0007h
mov   al, byte ptr ss:[_jump_mult_table_3 + bx]
mov   byte ptr cs:[SELFMODIFY_offset_draw_remaining_pixels5000Screen0_ + 1], al
SHIFT_MACRO shr cx 3
je    done_drawing_8_pixels5000Screen0_


; bx, cx unused...

;  todo full unroll

draw_8_more_pixels5000Screen0_:

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

loop   draw_8_more_pixels5000Screen0_

; todo: variable jmp here

done_drawing_8_pixels5000Screen0_:

SELFMODIFY_offset_draw_remaining_pixels5000Screen0_:
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
done_drawing_pixels5000Screen0_:
check_for_next_column5000Screen0_:

inc si
cmp   byte ptr ds:[si], 0FFh


jne   draw_next_column_patch5000Screen0_
column_done5000Screen0_:
add   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction5000Screen0_ + 1], 4
inc   word ptr cs:[OFFSET SELFMODIFY_offset_add_di5000Screen0_ + 2]
xor   ax, ax
SELFMODIFY_compare_instruction5000Screen0_:
cmp   ax, 0F030h		; compare to width
;jnge  draw_next_column5000Screen0_   ; out of range 5 bytes
jge   jumpexit5000Screen0_
jmp   draw_next_column5000Screen0_

jumpexit5000Screen0_:
pop   ds
pop   bx
pop   dx
pop   di
pop   si
pop   cx
ret

ENDP





jumptoexitdirect:
jmp   jumpexitdirect

PROC V_DrawPatchDirect_ FAR
PUBLIC V_DrawPatchDirect_

; CX:BX is patch
; dx is y
; ax is x

;bp  - 2 is ax  (x)

push  si
push  di
push  bp
mov   bp, sp

mov   es, cx

;    y -= (patch->topoffset); 
;    x -= (patch->leftoffset); 
 

; patch is es:bx
sub   ax, word ptr es:[bx + 4]	; leftoffset
sub   dx, word ptr es:[bx + 6]  ; topoffset
mov   si, ax  ; store x
mov   ax, (SCREENWIDTH / 4)
mul   dx

mov   word ptr cs:[SELFMODIFY_retrievepatchoffset+1], bx
; load destscreen into es:bx to calc desttop
mov   di, bx
mov   word ptr cs:[SELFMODIFY_retrievenextcoloffset + 1], di
les   bx, dword ptr ds:[_destscreen]
mov   ds, cx

   
add   bx, ax
mov   ax, si

;	desttop = (byte __far*)(destscreen->w + y * (SCREENWIDTH / 4) + (x>>2));
;   es:bx is desttop

SHIFT_MACRO SAR AX 2

;    w = (patch->width); 
;    for ( col = 0 ; col<w ; col++) 


;	column = (column_t  __far*)((byte  __far*)patch + (patch->columnofs[col]));

mov   word ptr cs:[SELFMODIFY_col_increment+1], 0

add   ax, bx

mov   word ptr cs:[SELFMODIFY_offset_set_di+1], ax
mov   ax, word ptr ds:[di]  ; get width
mov   word ptr cs:[SELFMODIFY_compare_instruction_direct + 1], ax
test  ax, ax
jle   jumptoexitdirect

draw_next_column_direct:

;		outp (SC_INDEX+1,1<<(x&3));
inc   word ptr cs:[SELFMODIFY_col_increment+1]    ; col++

mov   cx, si ; retrieve x
mov   ax, 1


mov   dx, SC_DATA
and   cl, 3
SELFMODIFY_retrievenextcoloffset:
mov   di, 0F030h
shl   ax, cl
SELFMODIFY_retrievepatchoffset:
mov   bx, 0F030h



out   dx, al
mov   dx, si  ; store x in dx
add   bx, word ptr ds:[di + 8]
cmp   byte ptr ds:[bx], 0FFh
je    check_desttop_increment
draw_next_column_patch_direct:
mov   al, byte ptr ds:[bx]
mov   ah, (SCREENWIDTH / 4)
mul   ah
SELFMODIFY_offset_set_di:
mov   di, 0F030h
add   di, ax
mov   cl, byte ptr ds:[bx + 1]  ; get col length
xor   ch, ch
mov   si, cx
and   si, 0007h
mov   al, byte ptr ss:[_jump_mult_table_3 + si]
mov   byte ptr cs:[SELFMODIFY_offset_draw_remaining_pixels_direct + 1], al
mov   ax,  ((SCREENWIDTH / 4) - 1)
lea   si, [bx + 3]
SHIFT_MACRO shr cx 3
je    done_drawing_8_pixels_direct


draw_8_more_pixels_direct:

movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
loop draw_8_more_pixels_direct

done_drawing_8_pixels_direct:

SELFMODIFY_offset_draw_remaining_pixels_direct:
db 0EBh, 00h		; jump rel8

movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb
add   di, ax
movsb


done_drawing_column:
mov   al, byte ptr ds:[bx + 1]
; ah is 0
add   bx, ax
add   bx, 4
cmp   byte ptr ds:[bx], 0FFh
jne   draw_next_column_patch_direct
check_desttop_increment:

;	if ( ((++x)&3) == 0 ) 
;	    desttop++;	// go to next byte, not next plane 
;    }


inc   dx
test  dx, 3
jne   dont_increment_desttop						; todo change branch? 1/4 chance of fallthru?
inc   word ptr cs:[SELFMODIFY_offset_set_di+1]
dont_increment_desttop:
SELFMODIFY_col_increment:
mov   ax, 0F030h
add   word ptr cs:[SELFMODIFY_retrievenextcoloffset + 1], 4
SELFMODIFY_compare_instruction_direct:
cmp   ax, 0F030h
jge   jumpexitdirect

mov   si, dx
jmp   draw_next_column_direct
jumpexitdirect:
mov   ax, ss
mov   ds, ax
LEAVE_MACRO
pop   di
pop   si
retf  

ENDP



; copy string from cs:bx to ds:_filename_argument
; return _filename_argument in ax
; todo make use cs:si or something?

PROC CopyString9_ NEAR
PUBLIC CopyString9_

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

PROC R_FillBackScreen_ NEAR
PUBLIC R_FillBackScreen_


PUSHA_NO_AX_OR_BP_MACRO

cmp       word ptr ds:[_scaledviewwidth], SCREENWIDTH
jne       continue_fillbackscreen
jmp       exit_fillbackscreen

continue_fillbackscreen:
cmp       byte ptr ds:[_commercial], 0
jne       is_doom2
; not doom2
mov       bx, OFFSET str_name_1
jmp       name_ready
is_doom2:
mov       bx, OFFSET str_name_2
name_ready:
call      Z_QuickMapScratch_5000_
xchg      ax, bx
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_		; todo once this is in asm dont re-set cx a billion times... push cx pop cx

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
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_

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
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_

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
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_

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
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_

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
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_


;mov       di, word ptr ds:[_viewwindowy]
mov       si, word ptr ds:[_viewwindowx]


lea       dx, [di - 8]
lea       ax, [si - 8]

call      V_DrawPatch5000Screen0_		; todo make a version based on segment 5000


mov       ax, OFFSET str_brdr_tr
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_



lea       dx, [di - 8]
mov       ax, si

add       ax, word ptr ds:[_scaledviewwidth]
call      V_DrawPatch5000Screen0_

mov       ax, OFFSET str_brdr_bl
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_

mov       dx, di
lea       ax, [si - 8]

add       dx, word ptr ds:[_viewheight]

call      V_DrawPatch5000Screen0_

mov       ax, OFFSET str_brdr_br
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_SEGMENT_5000
call      W_CacheLumpNameDirect_

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


;void __far V_CopyRect ( uint16_t srcoffset, uint16_t destoffset, uint16_t width, uint16_t height) { 

PROC V_CopyRect_ FAR
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
mov       ax, ss
mov       ds, ax 
pop       di
pop       si
exit_v_copyrect:
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
