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
INSTRUCTION_SET_MACRO_NO_MEDIUM


SEGMENT F_WIPE_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:F_WIPE_TEXT



PROC    F_WIPE_STARTMARKER_ 
PUBLIC  F_WIPE_STARTMARKER_
ENDP


_rndtable_9000:

 db 0,   8, 109, 220, 222, 241, 149, 107,  75, 248, 254, 140,  16,  66  
 db 74,  21, 211,  47,  80, 242, 154,  27, 205, 128, 161,  89,  77,  36 
 db 95, 110,  85,  48, 212, 140, 211, 249,  22,  79, 200,  50,  28, 188 
 db 52, 140, 202, 120,  68, 145,  62,  70, 184, 190,  91, 197, 152, 224 
 db 149, 104,  25, 178, 252, 182, 202, 182, 141, 197,   4,  81, 181, 242
 db 145,  42,  39, 227, 156, 198, 225, 193, 219,  93, 122, 175, 249,   0
 db 175, 143,  70, 239,  46, 246, 163,  53, 163, 109, 168, 135,   2, 235
 db 25,  92,  20, 145, 138,  77,  69, 166,  78, 176, 173, 212, 166, 113 
 db 94, 161,  41,  50, 239,  49, 111, 164,  70,  60,   2,  37, 171,  75 
 db 136, 156,  11,  56,  42, 146, 138, 229,  73, 146,  77,  61,  98, 196
 db 135, 106,  63, 197, 195,  86,  96, 203, 113, 101, 170, 247, 181, 113
 db 80, 250, 108,   7, 255, 237, 129, 226,  79, 107, 112, 166, 103, 241 
 db 24, 223, 239, 120, 198,  58,  60,  82, 128,   3, 184,  66, 143, 224 
 db 145, 224,  81, 206, 163,  45,  63,  90, 168, 114,  59,  33, 159,  95
 db 28, 139, 123,  98, 125, 196,  15,  70, 194, 253,  54,  14, 109, 226 
 db 71,  17, 161,  93, 186,  87, 244, 138,  20,  52, 123, 251,  26,  36 
 db 17,  46,  52, 231, 232,  76,  31, 221,  84,  37, 216, 165, 212, 106 
 db 197, 242,  98,  43,  39, 175, 254, 145, 190,  84, 118, 222, 187, 136
 db 120, 163, 236, 249

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

ENDP

PROC I_FinishUpdate_Fwipe_local_  NEAR
PUBLIC I_FinishUpdate_Fwipe_local_


;	outpw(CRTC_INDEX, (destscreen.h.fracbits & 0xff00L) + 0xc);
;	//Next plane
;    destscreen.h.fracbits += 0x4000;
;	if ((uint16_t)destscreen.h.fracbits == 0xc000) {
;		destscreen.h.fracbits = 0x0000;
;	}


push  dx
mov   ax, word ptr ds:[_destscreen]
mov   dx, CRTC_INDEX
mov   al, 0Ch
out   dx, ax
add   byte ptr ds:[_destscreen + 1], 040h
;cmp   byte ptr ds:[_destscreen + 1], 0C0h
jl    set_destscreen_0 ; SF != OF
pop   dx
ret
set_destscreen_0:
mov   byte ptr ds:[_destscreen+1], 0
pop   dx
ret



ENDP

PROC I_UpdateBox_Fwipe_local_  NEAR
PUBLIC I_UpdateBox_Fwipe_local_




push  si
push  di

mov   word ptr cs:[SELFMODIFY_set_h_check+2 - OFFSET F_WIPE_STARTMARKER_], cx

mov   cx, ax

; mul dx by screenwidth
mov   al, SCREENWIDTHOVER2
mul   dl
sal   ax, 1
xchg  ax, dx  ; dx gets dx * screenwidth
mov   ax, cx ; retrieve ax

;    sp_x1 = x >> 3;
;    sp_x2 = (x + w) >> 3;

add   ax, bx
SHIFT_MACRO sar   ax 3
mov   bx, cx   ; store this
SHIFT_MACRO sar   cx 3

;    count = sp_x2 - sp_x1 + 1;
sub   ax, cx
inc   ax        ; ax is count

; mul done earlier to dx
;    offset = (uint16_t)y * SCREENWIDTH + (sp_x1 << 3);
and   bx, 0FFF8h ; shift right 3, shift left 3. just clear bottom 3 bits.
add   bx, dx    ; bx is offset

;    poffset = offset >> 2;


mov   word ptr cs:[SELFMODIFY_set_offset+1 - OFFSET F_WIPE_STARTMARKER_], bx ; set
SHIFT_MACRO shr   bx 2  ; poffset
mov   word ptr cs:[SELFMODIFY_add_poffset+1 - OFFSET F_WIPE_STARTMARKER_], bx ; set


les   di, dword ptr ds:[_destscreen]
add   word ptr cs:[SELFMODIFY_set_original_destscreen_offset+1 - OFFSET F_WIPE_STARTMARKER_], di ; add in by default


;    step = SCREENWIDTH - (count << 3);

mov   word ptr cs:[SELFMODIFY_set_count+1 - OFFSET F_WIPE_STARTMARKER_], ax



SHIFT_MACRO shl   ax 3
mov   dx, SCREENWIDTH
sub   dx, ax            ; dx is step



;    pstep = step >> 2;

mov   ax, dx
mov   word ptr cs:[SELFMODIFY_add_step+2 - OFFSET F_WIPE_STARTMARKER_], ax
SHIFT_MACRO sar   ax 2
mov   word ptr cs:[SELFMODIFY_add_pstep+2 - OFFSET F_WIPE_STARTMARKER_], ax
mov   dx, SC_INDEX
mov   al, SC_MAPMASK
out   dx, al

mov   ax, SCREEN0_SEGMENT
mov   ds, ax
xor   cx, cx ; loopcount

loop_next_vga_plane:

;	outp(SC_INDEX + 1, 1 << i);

mov   al, 1
mov   dx, SC_DATA
; bx is offset
shl   ax, cl
out   dx, al

;        source = &screen0[offset + i];
; source is ds:si
SELFMODIFY_set_offset:
mov   si, 01000h
add   si, cx   ; screen0 offset = offset + i


;        dest = (byte __far*) (destscreen.w + poffset);
; dest is es:di
SELFMODIFY_set_original_destscreen_offset:
SELFMODIFY_add_poffset:
mov   di, 01000h ; just add it beforehand

xor   bx, bx  ; j = 0 loop counter


loop_next_pixel:
SELFMODIFY_set_count:
mov   dx, 01000h;
dec   dx

inner_inner_loop:

;    while (k--) {
;        *(uint16_t __far *)dest = (uint16_t)(((*(source + 4)) << 8) + (*source));
;        dest += 2;
;        source += 8;
;    }

;mov   al, byte ptr ds:[si]
lodsb
mov   ah, byte ptr ds:[si + 3]

stosw 
add   si, 7
dec   dx
jns    inner_inner_loop

inner_inner_loop_done:
inc   bx
SELFMODIFY_add_step:
add   si, 01000h
SELFMODIFY_add_pstep:
add   di, 01000h

;        for (j = 0; j < h; j++) {

SELFMODIFY_set_h_check:
cmp   bx, 01000h
jb    loop_next_pixel
inner_box_loop_done:
inc   cx
cmp   cx, 4
jb    loop_next_vga_plane

mov   ax, ss
mov   ds, ax  ; restore ds

pop   di
pop   si
ret   


ENDP


PROC I_UpdateNoBlit_Fwipe_local_  NEAR
PUBLIC I_UpdateNoBlit_Fwipe_local_


PUSHA_NO_AX_OR_BP_MACRO
; todo word only. segment should be fixed..?
les  ax, dword ptr ds:[_destscreen]
mov  word ptr ds:[_currentscreen], ax
mov  word ptr ds:[_currentscreen + 2], es



; cx is realdr[BOXTOP]
; bx is realdr[BOXRIGHT]
; dx is realdr[BOXBOTTOM]
; ax is realdr[BOXLEFT]

;    // Update dirtybox size
;    realdr[BOXTOP] = dirtybox[BOXTOP];
;    if (realdr[BOXTOP] < olddb[0+BOXTOP]) {
;        realdr[BOXTOP] = olddb[0+BOXTOP];
;    }
;    if (realdr[BOXTOP] < olddb[4+BOXTOP]) {
;        realdr[BOXTOP] = olddb[4+BOXTOP];
;    }

mov  si, OFFSET _olddb
mov  di, OFFSET _dirtybox

; cx gets boxtop

lodsw  ; ax = olddb[0+BOXTOP]
mov  cx, word ptr ds:[di + (BOXTOP * 2)]        ; realdr[BOXTOP]
cmp  cx, ax
jge  dont_cap_top_1
xchg cx, ax
dont_cap_top_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  cx, ax
jge  dont_cap_top_2
xchg cx, ax
dont_cap_top_2:

;    realdr[BOXBOTTOM] = dirtybox[BOXBOTTOM];
;    if (realdr[BOXBOTTOM] > olddb[0+BOXBOTTOM]) {
;        realdr[BOXBOTTOM] = olddb[0+BOXBOTTOM];
;    }
;    if (realdr[BOXBOTTOM] > olddb[4+BOXBOTTOM]) {
;        realdr[BOXBOTTOM] = olddb[4+BOXBOTTOM];
;    }

;  dx gets boxbottom

lodsw  ; ax = olddb[0+BOXBOTTOM]
mov  dx, word ptr ds:[di + (BOXBOTTOM * 2)]  ; realdr[BOXBOTTOM]
cmp  dx, ax         
jle  dont_cap_bot_1
xchg dx, ax
dont_cap_bot_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  dx, ax
jle  dont_cap_bot_2
xchg dx, ax
dont_cap_bot_2:


;    realdr[BOXLEFT] = dirtybox[BOXLEFT];
;    if (realdr[BOXLEFT] > olddb[0+BOXLEFT]) {
;        realdr[BOXLEFT] = olddb[0+BOXLEFT];
;    }
;    if (realdr[BOXLEFT] > olddb[4+BOXLEFT]) {
;        realdr[BOXLEFT] = olddb[4+BOXLEFT];
;    }

; bx stores boxleft for now

lodsw  ; ax = olddb[0+BOXLEFT]
mov  bx, word ptr ds:[di + (BOXLEFT * 2)]  ; ; realdr[BOXLEFT]
cmp  bx, ax
jle  dont_cap_left_1
xchg bx, ax
dont_cap_left_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  bx, ax
jle  dont_cap_left_2
xchg bx, ax
dont_cap_left_2:


;    realdr[BOXRIGHT] = dirtybox[BOXRIGHT];
;    if (realdr[BOXRIGHT] < olddb[0+BOXRIGHT]) {
;        realdr[BOXRIGHT] = olddb[0+BOXRIGHT];
;    }
;    if (realdr[BOXRIGHT] < olddb[4+BOXRIGHT]) {
;        realdr[BOXRIGHT] = olddb[4+BOXRIGHT];
;    }
; di stores boxright for now

lodsw  ; ax = olddb[0+BOXRIGHT]
mov  di, word ptr ds:[di + (BOXRIGHT * 2)]
cmp  di, ax
jge  dont_cap_right_1
xchg di, ax
dont_cap_right_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  di, ax
jge  dont_cap_right_2
xchg di, ax
dont_cap_right_2:

xchg ax, di ; ax gets boxright
xchg ax, bx ; ax gets boxleft. bx gets boxright.

;    // Leave current box for next update
;    olddb[0] = olddb[4];
;    olddb[1] = olddb[5];
;    olddb[2] = olddb[6];
;    olddb[3] = olddb[7];
;    olddb[4] = dirtybox[0];
;    olddb[5] = dirtybox[1];
;    olddb[6] = dirtybox[2];
;    olddb[7] = dirtybox[3];

mov  di, ds
mov  es, di
;mov  si, OFFSET _olddb + (4 * 2)  ; si is already set thru lodsw
mov  di, OFFSET _olddb
movsw
movsw
movsw
movsw
mov  si, OFFSET _dirtybox  ; worth making them adjacent and removing this?
movsw
movsw
movsw
movsw


; cx is realdr[BOXTOP]
; bx is realdr[BOXRIGHT]
; dx is realdr[BOXBOTTOM]
; ax is realdr[BOXLEFT]

;    // Update screen
;    if (realdr[BOXBOTTOM] <= realdr[BOXTOP]) {
;        x = realdr[BOXLEFT];
;        y = realdr[BOXBOTTOM];
;        w = realdr[BOXRIGHT] - realdr[BOXLEFT] + 1;
;        h = realdr[BOXTOP] - realdr[BOXBOTTOM] + 1;
;        I_UpdateBox(x, y, w, h); // todo inline, only use.
;    }

cmp  dx, cx
jnle  dont_update_box

sub  bx, ax
sub  cx, dx
inc  bx
inc  cx
call I_UpdateBox_Fwipe_local_  ; cx guaranteed 1 or more
mov  ax, ds
mov  es, ax

dont_update_box:

;	// Clear box
;	dirtybox[BOXTOP] = dirtybox[BOXRIGHT] = MINSHORT;
;	dirtybox[BOXBOTTOM] = dirtybox[BOXLEFT] = MAXSHORT;
mov  ax, MINSHORT
mov  di, OFFSET _dirtybox
stosw       ; boxtop    = minshort
dec   ax
stosw       ; boxbottom = maxshort
stosw       ; boxleft   = maxshort
inc   ax
stosw       ; boxright  = minshort

POPA_NO_AX_OR_BP_MACRO
ret 

ENDP


PROC wipe_doMelt_   NEAR
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
ret

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
SHIFT_MACRO shr ch 3
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
SHIFT_MACRO shr ch 3
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
mov       ax, SCRATCH_SEGMENT_5000
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
mov       ax, SCRATCH_SEGMENT_5000
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


PUSHA_NO_AX_OR_BP_MACRO


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

;call      Z_QuickMapScratch_5000_
Z_QUICKMAPAI4 pageswapargs_scratch5000_offset_size INDEXED_PAGE_5000_OFFSET



mov       ax, SCREEN2_SEGMENT
call      wipe_shittyColMajorXform_
mov       ax, SCREEN3_SEGMENT
call      wipe_shittyColMajorXform_

;call      FWIPE_M_Random_

xor       ax, ax
mov       bx, ax
mov       bl, byte ptr ds:[_rndindex]
inc       bl
xlat      byte ptr cs:[bx]



;    y[0] = -(M_Random()%16);

and       al, 0Fh 
neg       ax

xor       di, di
mov       si, FWIPE_YCOLUMNS_SEGMENT
mov       es, si
stosw

mov       cx, SCREENWIDTH
mov       dl, 3

loop_screenwidth:

xor       ax, ax
inc       bl
xlat      byte ptr cs:[bx]  ; inlined m_random..

div       dl      ; modulo 3...  ; overkill. but in theory could have a pre-calculated mod 3 table of prndindex!
mov       al, ah
cbw

dec       ax
add       ax, word ptr es:[di - 2]
stosw     ;   word ptr es:[di], ax
;test      ax, ax
jle       set_r

mov       word ptr es:[di-2], 0
done_comparing_r:
loop      loop_screenwidth

mov       byte ptr ds:[_rndindex], bl   ; write back


mov       ax, FWIPE_MUL160LOOKUP_SEGMENT
mov       es, ax
xor       di, di
mov       ax, di

mov       bx, SCREENWIDTHOVER2
mov       cx, SCREENHEIGHT/10
loop_screenheight:
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
stosw
add       ax, bx
loop        loop_screenheight

POPA_NO_AX_OR_BP_MACRO
ret 

set_r:
cmp       ax, 0FFF0h
jne       done_comparing_r
mov       word ptr es:[di], 0FFF1h
jmp       done_comparing_r


endp

PROC wipe_StartScreen_ FAR
PUBLIC wipe_StartScreen_

push    dx
push    cx
push    si

;call Z_QuickMapWipe_

Z_QUICKMAPAI4 pageswapargs_wipe_offset_size    INDEXED_PAGE_9000_OFFSET

Z_QUICKMAPAI8_NO_DX (pageswapargs_wipe_offset_size+4)  INDEXED_PAGE_6000_OFFSET

mov   	ax, SCREEN2_SEGMENT
call  	I_ReadScreen_

;call Z_QuickMapPhysics_
Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET

mov   byte ptr ds:[_currenttask], TASK_PHYSICS


pop     si
pop     cx
pop     dx


retf

endp

PROC wipe_WipeLoop_ FAR
PUBLIC wipe_WipeLoop_

push      bx
push      cx
push      dx
push      si
push      di

;call Z_QuickMapWipe_
Z_QUICKMAPAI4 pageswapargs_wipe_offset_size    INDEXED_PAGE_9000_OFFSET

Z_QUICKMAPAI8_NO_DX (pageswapargs_wipe_offset_size+4)  INDEXED_PAGE_6000_OFFSET

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

call      I_UpdateNoBlit_Fwipe_local_

push      dx

; Z_QuickmapMenu_. pages in menu code and graphics for m_drawer.
Z_QUICKMAPAI8 pageswapargs_menu_offset_size INDEXED_PAGE_5000_OFFSET

; mov   byte ptr ds:[_currenttask], TASK_MENU
db    09Ah
dw    M_DRAWEROFFSET, MENU_CODE_AREA_SEGMENT
; mov   byte ptr ds:[_currenttask], TASK_WIPE

; NOTE: m_drawer clobbers 5000-6fff via Z_QuickMapMenu, 
; but in turn may call Z_QuickMapStatus_ which clobbers 7000-7FFF and 9C00-9FFF
; Z_QuickMapWipe_. page back necessary fwipe data etc
Z_QUICKMAPAI4 pageswapargs_wipe_offset_size    INDEXED_PAGE_9000_OFFSET
Z_QUICKMAPAI8_NO_DX (pageswapargs_wipe_offset_size+4)  INDEXED_PAGE_6000_OFFSET
;call      Z_QuickMapScratch_5000_
;Z_QUICKMAPAI4 pageswapargs_scratch5000_offset_size INDEXED_PAGE_5000_OFFSET

pop       dx


call      I_FinishUpdate_Fwipe_local_

test      dl, dl
je        ticcount_loop

mov       byte ptr ds:[_hudneedsupdate], 6

;call Z_QuickMapPhysics_
Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET
mov     byte ptr ds:[_currenttask], TASK_PHYSICS

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
 
ENDP


PROC    F_WIPE_ENDMARKER_ 
PUBLIC  F_WIPE_ENDMARKER_
ENDP

ENDS

END