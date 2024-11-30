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


.CODE

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
push      si
push      di


mov       ax, SCREEN0_SEGMENT
mov       es, ax
xor       si, si
mov       di, si
mov       ax, SCREEN2_SEGMENT
mov       ds, ax
mov       cx, 07D00h  ; SCREENWIDTH * SCREENHEIGHT / 2
rep movsw 
mov       ax, ss
mov       ds, ax

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _Z_QuickMapScratch_5000_addr

mov       ax, SCREEN2_SEGMENT
call      wipe_shittyColMajorXform_
mov       ax, SCREEN3_SEGMENT
call      wipe_shittyColMajorXform_

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _M_Random_addr



;    y[0] = -(M_Random()%16);

and       ax, 0Fh ;
neg       ax

xor       di, di
mov       si, FWIPE_YCOLUMNS_SEGMENT
mov       es, si
;mov       word ptr es:[di], ax
;mov       di, 2
stosw

mov       cx, SCREENWIDTH
mov       bl, 3

loop_screenwidth:
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _M_Random_addr

xor       ah, ah
div       bl     ; modulo 3...
mov       al, ah
cbw
mov       es, si  ; do we know if M_Random_ wrecks es? ... probaly does... todo inline M_Random
dec       ax
add       ax, word ptr es:[di - 2]
stosw     ;word ptr es:[di], ax
test      ax, ax
jle       set_r
mov       word ptr es:[di-2], 0
done_comparing_r:
loop      loop_screenwidth


mov       ax, FWIPE_MUL160LOOKUP_SEGMENT
mov       es, ax
xor       di, di
mov       ax, di


mov       cx, SCREENHEIGHT
loop_screenheight:
stosw
add       ax, SCREENWIDTHOVER2
loop        loop_screenheight

pop       di
pop       si
pop       cx
pop       bx
ret 

set_r:
cmp       ax, 0FFF0h
jne       done_comparing_r
mov       word ptr es:[di], 0FFF1h
jmp       done_comparing_r


endp

PROC wipe_StartScreen_ FAR
PUBLIC wipe_StartScreen_

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _Z_QuickMapWipe_addr

mov   	ax, SCREEN2_SEGMENT
call  	I_ReadScreen_

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _Z_QuickMapPhysics_addr


retf

endp

PROC wipe_WipeLoop_ FAR
PUBLIC wipe_WipeLoop_

push      bx
push      cx
push      dx
push      si
push      di
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _Z_QuickMapWipe_addr
mov       ax, SCREEN3_SEGMENT
mov       cx, SCREENHEIGHT
mov       bx, SCREENWIDTH
call      I_ReadScreen_
xor       ax, ax
cwd
mov       si, ax
mov       di, ax

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _V_MarkRect_addr

mov       CX, 07D00h   ; SCREENWIDTH * SCREENHEIGHT / 2
mov       ax, SCREEN0_SEGMENT
mov       es, ax
mov       ax, SCREEN2_SEGMENT
mov       ds, ax
rep movsw 
mov       ax, ss
mov       ds, ax

call      wipe_initMelt_
mov       bx, word ptr ds:[_ticcount]
dec       bx
mov       cx, bx     ; store wipestart
ticcount_loop:
mov       dx, word ptr ds:[_ticcount]
mov       ax, dx
sub       ax, bx
je        ticcount_loop

mov       bx, dx	; update wipestart

mov       word ptr ds:[_dirtybox], SCREENHEIGHT
mov       word ptr ds:[_dirtybox+2], 0
mov       word ptr ds:[_dirtybox+4], 0
mov       word ptr ds:[_dirtybox+6], SCREENWIDTH

call      wipe_doMelt_
mov       dx, ax    ; store "done" result from wipe_doMelt_

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _I_UpdateNoBlit_addr


mov       ax, 1
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _M_Drawer_addr

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _I_FinishUpdate_addr

test      dl, dl
je        ticcount_loop

mov       byte ptr ds:[_hudneedsupdate], 6

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _Z_QuickMapPhysics_addr

IFDEF DETAILED_BENCH_STATS
mov       ax, word ptr ds:[_ticcount]
sub       ax, cx
mov       word ptr ds:[_wipeduration], ax
ENDIF

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
 
endp

end