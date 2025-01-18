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

_destscreen = (_NULL_OFFSET + 0008h)


.CODE
EXTRN V_MarkRect_:PROC
EXTRN _viewwindowx:WORD
EXTRN _viewwindowy:WORD
EXTRN _scaledviewwidth:WORD
EXTRN W_CacheLumpNameDirect_:PROC  
EXTRN Z_QuickMapScratch_5000_:PROC  

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

push  cx
push  si
push  di
push  bp
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
xor   dh, dh

; si = y * screenwidth



IF COMPILE_INSTRUCTIONSET GE COMPILE_186

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


sub   si, word ptr ds:[bx + 4]


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

add   bx, 8
mov   word ptr cs:[OFFSET SELFMODIFY_compare_instruction + 1], ax  ; store width
mov   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction + 1], bx  ; store column
test  ax, ax
jle   jumptoexit
; store patch segment (???) remove;

draw_next_column:

dec   word ptr cs:[OFFSET SELFMODIFY_compare_instruction + 1] ; decrement count ahead of time

;		column = (column_t __far *)((byte __far*)patch + (patch->columnofs[col])); 

; ds:si is patch segment
; es:di is screen pixel target

SELFMODIFY_setup_bx_instruction:
mov   bx, 0F030h               ; F030h is target for self modifying code     
; grab patch offset into di
mov   si, word ptr [bp + 0Ch]
; si equals colofs lookup
add   si, word ptr ds:[bx]

;		while (column->topdelta != 0xff )  
; check topdelta for 0xFFh
cmp   byte ptr ds:[si], 0FFh
jne   draw_next_column_patch
jmp   column_done


; here we render the next patch in the column.
draw_next_column_patch:


; grab both column fields at once. si + 0 is topdelta. si + 1 is column length
mov   ax, word ptr ds:[si]

mov   cl, ah
xor   ah, ah      ; al contains topdelta

; todo: figure this out.
; either one works on its own, but the else branch will fail regardless
; of which code is in it if the if is active. Probably related to 
; selfmodifying code references.

;IF COMPILE_INSTRUCTIONSET GE COMPILE_186
;imul   di, ax, SCREENWIDTH
;mov    dx, SCREENWIDTH - 1 

;ELSEIF

mov   di, SCREENWIDTH
mul   di
mov   dx, di
mov   di, ax
dec   dx

;ENDIF



SELFMODIFY_offset_add_di:
add   di, 0F030h   ; retrieve offset


add   si, 3
; figure out loop counts
mov   bl, cl
and   bx, 0007h
mov   al, byte ptr ss:[_jump_mult_table_3 + bx]
mov   byte ptr cs:[SELFMODIFY_offset_draw_remaining_pixels + 1], al
shr   cx, 1
shr   cx, 1
shr   cx, 1
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

; todo: variable jmp here

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
add di, dx


; restore stuff we changed above
done_drawing_pixels:
check_for_next_column:

inc si
cmp   byte ptr ds:[si], 0FFh


je    column_done
jmp   draw_next_column_patch
column_done:
add   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction + 1], 4
inc   word ptr cs:[OFFSET SELFMODIFY_offset_add_di + 2]
xor   ax, ax
SELFMODIFY_compare_instruction:
cmp   ax, 0F030h		; compare to width
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
mov   cx, word ptr ds:[bx + 2]
mov   bx, word ptr ds:[bx]
push ds

mov  di, ss
mov  ds, di


push es
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

mov   bx, SCRATCH_PAGE_SEGMENT_5000
mov   ds, bx
xor   bx, bx


sub   dl, byte ptr ds:[bx + 6]	; patch width
xor   dh, dh

; si = y * screenwidth


IF COMPILE_INSTRUCTIONSET GE COMPILE_186

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


sub   si, word ptr ds:[bx + 4]


cmp   cl, 0


mov   cx, word ptr ds:[bx + 2]
mov   bx, word ptr ds:[bx]
push ds

mov  di, ss
mov  ds, di


push es
call  V_MarkRect_
pop  es
pop  ds


; 	desttop = MK_FP(screen_segments[scrn], offset); 



; load patch addr again
mov   word ptr cs:[OFFSET SELFMODIFY_offset_add_di5000Screen0_ + 2], si
xor   bx, bx

;    w = (patch->width); 
mov   ax, word ptr ds:[bx]

add   bx, 8
mov   word ptr cs:[OFFSET SELFMODIFY_compare_instruction5000Screen0_ + 1], ax  ; store width
mov   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction5000Screen0_ + 1], bx  ; store column
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

;IF COMPILE_INSTRUCTIONSET GE COMPILE_186
;imul   di, ax, SCREENWIDTH
;mov    dx, SCREENWIDTH - 1 

;ELSEIF

mov   di, SCREENWIDTH
mul   di
mov   dx, di
mov   di, ax
dec   dx

;ENDIF



SELFMODIFY_offset_add_di5000Screen0_:
add   di, 0F030h   ; retrieve offset


add   si, 3
; figure out loop counts
mov   bl, cl
and   bx, 0007h
mov   al, byte ptr ss:[_jump_mult_table_3 + bx]
mov   byte ptr cs:[SELFMODIFY_offset_draw_remaining_pixels5000Screen0_ + 1], al
shr   cx, 1
shr   cx, 1
shr   cx, 1
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
add di, dx


; restore stuff we changed above
done_drawing_pixels5000Screen0_:
check_for_next_column5000Screen0_:

inc si
cmp   byte ptr ds:[si], 0FFh


je    column_done5000Screen0_
jmp   draw_next_column_patch5000Screen0_
column_done5000Screen0_:
add   word ptr cs:[OFFSET SELFMODIFY_setup_bx_instruction5000Screen0_ + 1], 4
inc   word ptr cs:[OFFSET SELFMODIFY_offset_add_di5000Screen0_ + 2]
xor   ax, ax
SELFMODIFY_compare_instruction5000Screen0_:
cmp   ax, 0F030h		; compare to width
jge   jumpexit5000Screen0_
jmp   draw_next_column5000Screen0_
jumpexit5000Screen0_:
pop   dx
mov   ax, ss
mov   ds, ax

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
sub   ax, word ptr es:[bx + 4]
sub   dx, word ptr es:[bx + 6]
mov   si, ax  ; store x
mov   ax, (SCREENWIDTH / 4)
mul   dx

mov   word ptr cs:[SELFMODIFY_retrievepatchoffset+1], bx
; load destscreen into es:bx to calc desttop
mov   di, bx
les   bx, dword ptr ds:[_destscreen]
mov   ds, cx

   
add   bx, ax
mov   ax, si

;	desttop = (byte __far*)(destscreen->w + y * (SCREENWIDTH / 4) + (x>>2));
;   es:bx is desttop

sar   ax, 1
sar   ax, 1

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
mov   word ptr cs:[SELFMODIFY_retrievenextcoloffset + 1], di

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
shr   cx, 1
shr   cx, 1
shr   cx, 1
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
add   di, ax


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
jne   dont_increment_desttop
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

mov   si, bx

mov   ax, 0
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

PROC R_FillBackScreen_ FAR
PUBLIC R_FillBackScreen_

SBARHEIGHT = 32

push      bx
push      cx
push      dx
push      si
push      di

cmp       word ptr [_scaledviewwidth], SCREENWIDTH
jne       continue_fillbackscreen
jmp       exit_fillbackscreen

continue_fillbackscreen:
mov       bx, OFFSET _commercial
cmp       byte ptr [bx], 0
jne       is_doom2
; not doom2
mov       bx, OFFSET str_name_1
jmp       name_ready
is_doom2:
mov       bx, OFFSET str_name_2
name_ready:
call      Z_QuickMapScratch_5000_

call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_PAGE_SEGMENT_5000
call      W_CacheLumpNameDirect_

xor       bx, bx
mov       ax, SCREEN0_SEGMENT
mov       es, ax
mov       ax, SCRATCH_PAGE_SEGMENT_5000
mov       ds, ax

xor       di, di
mov       dx, 32
xor       ax, ax
cld       
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

add       ax, 64	  ; add 64
and       ax, 00FFFh  ; mod by flat size

inc       bx
cmp       bx, (SCREENHEIGHT - SBARHEIGHT)
jb        loop_border_copy_outer

push      ss
pop       ds


mov       bx, OFFSET str_brdr_tl
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_PAGE_SEGMENT_5000
call      W_CacheLumpNameDirect_

mov       di, word ptr [_viewwindowy]
mov       si, word ptr [_viewwindowx]

mov       dx, di
mov       ax, si

sub       dx, 8
sub       ax, 8
call      V_DrawPatch5000Screen0_		; todo make a version based on segment 5000


mov       bx, OFFSET str_brdr_tr
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_PAGE_SEGMENT_5000
call      W_CacheLumpNameDirect_



mov       dx, di
mov       ax, si

sub       dx, 8
add       ax, word ptr [_scaledviewwidth]
call      V_DrawPatch5000Screen0_

mov       bx, OFFSET str_brdr_bl
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_PAGE_SEGMENT_5000
call      W_CacheLumpNameDirect_

mov       dx, di
mov       ax, si

sub       ax, 8
add       dx, word ptr ds:[_viewheight]

call      V_DrawPatch5000Screen0_

mov       bx, OFFSET str_brdr_br
call      CopyString9_
xor       bx, bx
mov       cx, SCRATCH_PAGE_SEGMENT_5000
call      W_CacheLumpNameDirect_

mov       dx, di
mov       ax, si

add       ax, word ptr [_scaledviewwidth]
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

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf     


ENDP



END
