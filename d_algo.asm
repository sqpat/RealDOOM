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



EXTRN Z_QuickMapScratch_5000_:PROC
EXTRN M_Random_:PROC


.CODE


PROC wipe_doMelt_ 
PUBLIC wipe_doMelt_


; int16_t __near wipe_doMelt ( int16_t	ticks ) { 

; notes:
; try to put dy in dx?
; ah maintained in i is good

; bp - 2     mulI
; bp - 4     ticks (ax)


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 02h
push  ax
mov   al, 1
decrement_tick_loop:
dec   word ptr [bp - 4h]
cmp   word ptr [bp - 4h], -1
jne   skip_exit

cbw  ; returning a bool, make sure ah is zero

mov cx, ss
mov ds, cx

LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf

skip_exit:
mov   word ptr [bp - 2], 0

xor   ah, ah

mov   dx, FWIPE_YCOLUMNS_SEGMENT
mov   es, dx

next_horizontal_pixel:


;			if (y[i]<0) {
;				y[i]++; 
;			done = false;
;			} 

mov   bl, ah
xor   bh, bh
add   bx, bx	; bx = 2 * i
cmp   word ptr es:[bx], 0

jge   skip_inc

xor   al, al
inc   word ptr es:[bx]
jmp   continue_main_loop

skip_inc:
cmp   word ptr es:[bx], SCREENHEIGHT
jb    do_next_iteration


continue_main_loop:

inc   ah
add   word ptr [bp - 2], SCREENHEIGHT
cmp   ah, (SCREENWIDTH / 2)
JAE   reached_last_pixel


jmp   next_horizontal_pixel
reached_last_pixel:
jmp   decrement_tick_loop

do_next_iteration:

;				dy = (y[i] < 16) ? y[i]+1 : 8;
; es:[bx] is y[i]

; this process zeroes out ch implicitly..
cmp   word ptr es:[bx], 16
jl    yi_less_than_16
mov   cx, 8
jmp   dy_set

yi_less_than_16:
mov   cx, word ptr es:[bx]
inc   cx
dy_set:

;				if (y[i] + dy >= SCREENHEIGHT) {
;					dy = SCREENHEIGHT - y[i];
;				}


mov   dx, cx  
add   dx, word ptr es:[bx]	; dx = dy + y[i] + 
cmp   dx, SCREENHEIGHT

jb    dy_good
; set dy to SCREENHEIGHT - y[i]
; overwrite al as new dy
mov   cl, SCREENHEIGHT
sub   cl, byte ptr es:[bx]
dy_good:

;				source = MK_FP(screen3_segment, 2*(	mulI+y[i]));
;				dest   = MK_FP(screen0_segment, 2*(mul160lookup[y[i]] + i));



mov   si, word ptr [bp - 2] ; si = mulI
mov   di, word ptr es:[bx]	; di = y[i]
add   si, di
add   si, si	; si is setup. si = 2*[y[i] + muli]

add   di, di	; di = 2 * y[i]
mov   di, word ptr es:[di + (16 * (FWIPE_MUL160LOOKUP_SEGMENT - FWIPE_YCOLUMNS_SEGMENT))]  ; mul160lookup[2*y[i]]

add   di, di	
add   di, bx    ; di is setup
mov   al, cl    ; cache dy
test  cl, cl
je    skip_first_copy


;		for (j=dy;j;j--) {
;			dest[idx] = *(source++);
;			idx += SCREENWIDTHOVER2;
;		}


mov   dx, SCREEN0_SEGMENT
mov   es, dx
mov   dx, SCREEN3_SEGMENT
mov   ds, dx
mov   dx, (SCREENWIDTH - 2)
mov   ch, cl
shr   ch, 1
shr   ch, 1
shr   ch, 1
je    done_outer_loop
push  ax     ;gross. anywhere else we can store eight bits..?
mov   ah, cl
and   ah, 7
mov   cl, ch
mov   ch, 0

; todo unroll?
first_copy:
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
loop   first_copy
mov   cl, ah
pop   ax
test  cl, cl
je    skip_first_copy

done_outer_loop:
;  ch is 0 anyway...


first_copy_2:
movsw
add    di, dx
loop   first_copy_2

skip_first_copy:

;				y[i] += dy;


mov   dx, FWIPE_YCOLUMNS_SEGMENT
mov   ds, dx


;				source = &((int16_t __far*)screen2)	[mulI];
;				dest = &((int16_t __far*)screen0)	[mul160lookup[y[i]] + i];

mov   si, word ptr [bp - 2]    
sal   si, 1					; si is ready

; still bx = 2 * i 
mov   cl, al   ; copy dy over
xor   dh, dh
add   word ptr ds:[bx], cx		; add to dy in  y[i]
mov   di, word ptr ds:[bx]
mov   cx, di
mov   dx, FWIPE_MUL160LOOKUP_SEGMENT
mov   es, dx
add   di, di
mov   di, word ptr es:[di]

add   di, di			; 
add   di, bx			; di is ready

sub   cl, SCREENHEIGHT
NEG   cl
je    skip_second_copy

; set up loop


;  		for (j= SCREENHEIGHT -y[i];j;j--) {
;			dest[idx] = *(source++);
;			idx += SCREENWIDTHOVER2;
;		}

mov   dx, SCREEN2_SEGMENT
mov   ds, dx
mov   dx, SCREEN0_SEGMENT
mov   es, dx
mov   dx, (SCREENWIDTH - 2)

mov   ch, cl
shr   ch, 1
shr   ch, 1
shr   ch, 1
je    done_outer_loop_2
push  ax     ;gross. anywhere else we can store eight bits..?
mov   ah, cl
and   ah, 7
mov   cl, ch
mov   ch, 0

; todo unroll?
second_copy:
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
movsw
add    di, dx
loop   second_copy
mov   cl, ah
pop   ax
test  cl, cl
je    skip_second_copy

done_outer_loop_2:
;  ch is 0 anyway...


second_copy_2:
movsw
add    di, dx
loop   second_copy_2
skip_second_copy:
xor   al, al

mov   dx, FWIPE_YCOLUMNS_SEGMENT
mov   es, dx

jmp continue_main_loop



ENDP


PROC I_ReadScreen_ NEAR
PUBLIC I_ReadScreen_


push  bx
push  dx
push  si
push  di


mov   es, ax ; copy segment to es...
mov   al, GC_READMAP
mov   dx, GC_INDEX

out   dx, al
xor	  ax, ax

cld   
;mov   dx, GC_INDEX + 1
inc    dx

lds   bx, dword ptr ds:[_currentscreen]


increment_screen_plane:
out   dx, al
mov   si, bx  ; reset si for this loop
mov   di, ax  ; di = "i" 

loop_screen_plane_read:
; could unroll this a bit. dont think it matters?
; scr[i+j*4u] = currentscreen[j];
movsb 
add   di, 3

cmp   di, 0FA00h  ;  SCREENWIDTH * SCREENHEIGHT
jb    loop_screen_plane_read

inc   al
cmp   al, 4
jb    increment_screen_plane


mov   ax, ss
mov   ds, ax

pop   di
pop   si
pop   dx
pop   bx
ret   

endp



PROC wipe_shittyColMajorXform_ NEAR
PUBLIC wipe_shittyColMajorXform_

push      bx
push      cx
push      dx
push      si
push      di

mov       es, ax  					; set dest segment

mov       cx, SCREENHEIGHT

; dx is x
; di is y

mov       ds, ax
mov       ax, SCRATCH_PAGE_SEGMENT_5000
mov       es, ax

; ax unused in loops...


xor       ax, ax
mov       bx, ax
mov       dx, ((SCREENHEIGHT*2) - 2)

loopy:

mov       si, bx
mov       di, (SCREENHEIGHT)
sub       di, cx
add       di, di

mov       ax, cx
mov       cx, SCREENWIDTHOVER2

loopx:
movsw
add       di, dx
loop      loopx

mov       cx, ax
add       bx, SCREENWIDTH
loop      loopy

mov       ax, ds
mov       es, ax
mov       ax, SCRATCH_PAGE_SEGMENT_5000
mov       ds, ax
xor       si, si
mov       di, si


cld
mov       cx, 32000
rep movsw 


mov       ax, ss
mov       ds, ax

pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret      

endp


PROC wipe_initMelt_ NEAR
PUBLIC wipe_initMelt_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 6
mov       ax, 0FA00h
mov       cx, 07000h
mov       dx, 08000h
xor       si, si
xor       di, di
mov       es, dx
push      ds
push      di
xchg      ax, cx
mov       ds, ax
shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 
pop       di
pop       ds
call      Z_QuickMapScratch_5000_
mov       ax, 07000h
call      wipe_shittyColMajorXform_
mov       ax, 06000h
call      wipe_shittyColMajorXform_
push      cs
call      M_Random_
nop       
mov       dl, al
xor       dh, dh
mov       ax, dx
sar       ax, 0Fh
mov       word ptr [bp - 4], 07FA0h
xor       dx, ax
mov       word ptr [bp - 2], 07FE0h
sub       dx, ax
xor       bx, bx
xor       dh, dh
mov       word ptr [bp - 6], bx
and       dl, 0Fh
mov       cx, 1
xor       dx, ax
mov       es, word ptr [bp - 4]
sub       dx, ax
mov       si, 07FA0h
mov       word ptr es:[bx], dx
mov       di, 3
neg       word ptr es:[bx]
mov       bx, 2
cld       
label1:
push      cs
call      M_Random_
nop       
xor       ah, ah
cwd       
idiv      di
mov       es, si
dec       dx
add       dx, word ptr es:[bx - 2]
mov       word ptr es:[bx], dx
test      dx, dx
jle       label2
mov       word ptr es:[bx], 0
label4:
inc       cx
add       bx, 2
cmp       cx, SCREENWIDTH
jl        label1
mov       bx, word ptr [bp - 6]
mov       es, word ptr [bp - 2]
xor       dx, dx
xor       ax, ax
cld       
label3:
inc       ax
mov       word ptr es:[bx], dx
add       bx, 2
add       dx, 0A0h
cmp       ax, 0C8h
jb        label3
xor       ax, ax

LEAVE_MACRO

pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
label2:
cmp       dx, 0FFF0h
jne       label4
mov       word ptr es:[bx], 0FFF1h
jmp       label4


endp



PROC resetDS_ FAR
PUBLIC resetDS_

;todo is ax necessary? if 286+ can push immediate.
push ax
mov ax, 03C00h
mov ds, ax
pop ax

retf
endp


PROC hackDS_ FAR
PUBLIC hackDS_

;todo: make cli held for less time

cli
push cx
push si
push di

mov ds:[_stored_ds], ds
xor di, di
mov si, di
mov cx, 03C00h

;mov cx, ds
;add cx, 400h
mov es, cx

mov CX, 2000h    ; 4000h bytes
rep movsw

mov cx, es
mov ds, cx
mov ss, cx

COMMENT @

;; clear out BASE_LOWER_MEMORY_SEGMENT. Not needed? if we do this then push/pop ax!
push ax
mov cx, BASE_LOWER_MEMORY_SEGMENT
mov es, cx

; zero up till 3C00h
mov cx, 03C00h
sub cx, BASE_LOWER_MEMORY_SEGMENT
sal cx, 1 ; 16 bytes per paragraphs divided by 2 (word writes) = shift 8
sal cx, 1
sal cx, 1 
xor ax, ax
mov di, ax
rep stosw
pop ax
@

pop di
pop si
pop cx




sti



retf

ENDP





PROC hackDSBack_ FAR
PUBLIC hackDSBack_

cli
push cx
push si
push di

mov es, ds:[_stored_ds]

xor di, di
mov si, di
mov CX, 2000h   ; 4000h bytes
rep movsw
mov cx, es
mov ds, cx
mov ss, cx


pop di
pop si
pop cx


sti



retf

ENDP



END