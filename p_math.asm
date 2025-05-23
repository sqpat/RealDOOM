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


EXTRN FixedMul16u32_:FAR
EXTRN FixedMul1632_:FAR
EXTRN FixedMul2424_:FAR
EXTRN FixedMul2432_:FAR
EXTRN FixedDiv_:FAR
EXTRN P_TraverseIntercepts_:NEAR
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA

EXTRN _trace:WORD
EXTRN _lineopening:WORD
EXTRN _intercept_p:WORD

.CODE



;R_PointOnSide_
; called in a loop. destructive to ds

PROC R_PointOnSide_ NEAR
PUBLIC R_PointOnSide_ 

; todo optimize to keep params on the stack from the otuside.

; DX:AX = x
; CX:BX = y
; segindex = si


; node_t
;    int16_t	x;
;    int16_t	y;
;    int16_t	dx;
;    int16_t	dy;
;    uint16_t   children[2];

; nodes are 8 bytes each. node children are 4 each.

; todo eventually return child value instead of node




push      word ptr ds:[si] 		     ; child 0
push      word ptr ds:[si+2]         ; child 1 on stack 

shl   si, 1     ; 8 indexed NOTE: 

mov   ax, NODES_SEGMENT
mov   ds, ax  ; DS for nodes lookup


;  get lx, ly, ldx, ldy

; todo use ds here

les   bx, dword ptr ds:[si + 0]   ; lx  
mov   di, es   					  ; ly
les   ax, dword ptr ds:[si + 4]   ; ldx
mov   si, es                      ; ldy


pop   es ; shove child 1 in es..
pop   ds ; shove child 0 in ds..




; ax = ldx
; si = ldy
; bx = lx
; di = ly
; dx = x highbits
; cx = y highbits
; bp - 4 = x lowbits
; bp - 2 = y lowbits
; ds = child 0
; es = child 1

;    if (!node->dx) 

test  ax, ax
jne   node_dx_nonequal

;        if (x <= (node->x shift 16) )
;  compare high bits
cmp   dx, bx
jl    return_node_dy_greater_than_0
jne   return_node_dy_less_than_0

; compare low bits

cmp   word ptr [bp - 04h], 0
jbe   return_node_dy_greater_than_0

 
return_node_dy_less_than_0:
;        return node->dy < 0;
cmp   si, 0
jl    return_true

return_false:
mov   ax, ds
ret   

;            return node->dy > 0;

return_node_dy_greater_than_0:
cmp  si, 0
jle  return_false

return_true:
mov   ax, es
ret   

node_dx_nonequal:


;    if (!node->dy) {
test  si, si

jne   node_dy_nonzero

;        if (y.w <= (node_y shift 16))
;  compare high bits

cmp   cx, di
jl    ret_node_dx_less_than_0
jne   ret_ldx_greater_than_0
;  compare low bits
cmp   word ptr [bp - 02h], 0
jbe   ret_node_dx_less_than_0
ret_ldx_greater_than_0:
;        return node->dx > 0
cmp   ax, 0
jg    return_true

; return false
mov   ax, ds
ret    
ret_node_dx_less_than_0:

;            return node->dx < 0;

cmp    ax, 0
jl    return_true

; return false
mov   ax, ds
ret   

node_dy_nonzero:



;    dx.w = (x.w - (lx shift 16));
;    dy.w = (y.w - (ly shift 16));



sub   dx, bx
sub   cx, di




;    Try to quickly decide by looking at sign bits.
;    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )  // returns 1


mov   bx, ax
xor   bx, si
xor   bx, dx
xor   bx, cx
test  bh, 080h
jne   do_sign_bit_return

xchg si, ax

; gross - we must do a lot of work in this case. 

;    left.w = FixedMul1632 ( node->dy , dx.w );
;    right.w = FixedMul1632 (node->dx, dy.w );


mov   word ptr cs:[SELFMODIFY_returnchild1+1], es

mov   di, cx  ; store cx.. 
mov   bx, word ptr [bp - 4] ; grab lobits
mov   cx, dx


call FixedMul1632_

; set up params..
xchg  si, ax
mov   bx, word ptr [bp - 2]  ; grab lobits
mov   cx, di

mov   di, dx
call FixedMul1632_
cmp   dx, di
jg    return_true_2
je    check_lowbits

return_false_2:
mov   ax, ds
ret   

check_lowbits:
cmp   ax, si
jb    return_false_2
return_true_2:
SELFMODIFY_returnchild1:
mov   ax, 01000h
;mov   ax, es

ret   
do_sign_bit_return:

;		// (left is negative)
;		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1

xor   si, dx
jl    return_true

mov   ax, ds
ret   


ENDP


; fixed_t __near P_AproxDistance ( fixed_t	dx, fixed_t	dy ) {

PROC P_AproxDistance_ NEAR
PUBLIC P_AproxDistance_ 

or   dx, dx
jge  skip_labs_1
neg  ax
adc  dx, 0
neg  dx
skip_labs_1:

or   cx, cx
jge  skip_labs_2
neg  bx
adc  cx, 0
neg  cx
skip_labs_2:

cmp  cx, dx
jl   dx_greater_than_dy
jne  dx_less_than_dy
cmp  bx, ax
jae  dx_less_than_dy

dx_greater_than_dy:
add  ax, bx
adc  dx, cx		; dx:ax = dx + dy

sar  cx, 1
rcr  bx, 1		; dy >> 1

sub  ax, bx
sbb  dx, cx

ret  

dx_less_than_dy:


add  bx, ax
adc  cx, dx		; cx:bx = dx + dy

sar  dx, 1
rcr  ax, 1		; dx >> 1

sub  bx, ax
sbb  cx, dx

mov  dx, cx
xchg ax, bx		; swap to return register.
ret

ENDP

; boolean __near P_PointOnLineSide ( 
	; fixed_t	x, 
	; fixed_t	y, 
	; int16_t linedx, 
	; int16_t linedy,
	; int16_t v1x,
	; int16_t v1y);

; DX:AX     x
; CX:BX     y
; bp + 4    linedx
; bp + 6    linedy
; bp + 8    v1x
; bp + 0Ah  v1y

; todo consider si:di params for linedx/linedy?
 
PROC P_PointOnLineSide_ NEAR
PUBLIC P_PointOnLineSide_ 

push  bp		; bp + 2?
mov   bp, sp

cmp   word ptr [bp + 4], 0	; compare linedx

;    if (!linedx) {
jne   linedx_nonzero
;		if (x <= temp.w) {
cmp   dx, word ptr [bp + 8]			; compare hi bits to linedx
jl    x_smaller_than_v1x
jne   x_greater_than_v1x
test  ax, ax
jbe   x_smaller_than_v1x
x_greater_than_v1x:
cmp   word ptr [bp + 6], 0
jl    return_1_pointonlineside
return_0_pointonlineside:
xor   ax, ax	; zero
exit_pointonlineside:
LEAVE_MACRO
ret   8

x_smaller_than_v1x:
cmp   word ptr [bp + 6], 0	; compare linedy
jle   return_0_pointonlineside

return_1_pointonlineside:
mov   al, 1
LEAVE_MACRO
ret   8

linedx_nonzero:

cmp   word ptr [bp + 6], 0	; compare linedy
jne   linedy_nonzero
cmp   cx, word ptr [bp + 0Ah]	; v1y
jl    y_smaller_than_v1y
jne   y_greater_than_v1y
test  bx, bx
jbe   y_smaller_than_v1y
y_greater_than_v1y:
cmp   word ptr [bp + 4], 0		; compare linedx
jle   return_0_pointonlineside
mov   al, 1
LEAVE_MACRO
ret   8

y_smaller_than_v1y:
cmp   word ptr [bp + 4], 0
jge   return_0_pointonlineside
mov   al, 1
LEAVE_MACRO
ret   8

linedy_nonzero:


;	temp.h.intbits = v1x;
;   dx = (x - temp.w);
;	temp.h.intbits = v1y;
;   dy = (y - temp.w);

push  di
push  si


sub   dx, word ptr [bp + 8]	; dx:ax = "dx"

sub   cx, word ptr [bp + 0Ah]	; cx:bx = "dy"


;    left = FixedMul1632 ( linedy , dx );
;    right = FixedMul1632 ( linedx , dy);


mov   si, bx					; store dy low
mov   di, cx					; store dy hi	di:si = dy
mov   bx, ax					; cx:bx = dx
mov   cx, dx	

mov   ax, word ptr [bp + 6]	; ax = lindedy

call  FixedMul1632_				; AX  *  CX:BX

;dx:ax = left

mov   bx, si
mov   cx, di
mov   di, ax
mov   si, dx
mov   ax, word ptr [bp + 4]		; get linedx

call  FixedMul1632_				; AX  *  CX:BX
cmp   dx, si
pop   si						; only do this once here..
jl    exit_pointonlineside_return_0
jne   return_1_pointonlineside_3
cmp   ax, di
jae   return_1_pointonlineside_3
exit_pointonlineside_return_0:
xor   al, al
pop   di
LEAVE_MACRO
ret   8

return_1_pointonlineside_3:		; this one pops di
mov   al, 1
pop   di
LEAVE_MACRO
ret   8

ENDP


PROC P_BoxOnLineSide_ NEAR
PUBLIC P_BoxOnLineSide_ 

;// Considers the line to be infinite
;// Returns side 0 or 1, -1 if box crosses the line.


; todo switch on high bits instead of whole word?
; todo put v1y in si instead of stack!

;int8_t __near P_BoxOnLineSide (  
	; slopetype_t	lineslopetype 
	; int16_t linedx, 
	; int16_t linedy, 
	; int16_t v1x, 
	; int16_t v1y ) 

;	ax: lineslopetype
;   dx: linedx
;   bx: linedy
;   cx: v1x
;   si: v1y




cmp   ax, ST_VERTICAL_HIGH
jae   non_zero_slopetype

; ST_HORIZONTAL_HIGH case

;	  	temp.h.intbits = v1y;
;		p1 = tmbbox[BOXTOP].w > temp.w;
;		p2 = tmbbox[BOXBOTTOM].w > temp.w;

; in this case we have to check the low bits for nonzero

cmp   si, word ptr ds:[_tmbbox + (BOXTOP * 4) + 2]
jng   set_p1_to_1_2

jne   set_p1_to_0
cmp   word ptr ds:[_tmbbox + (BOXTOP * 4)], 0	; check lo bits..
jne   set_p1_to_1_2

set_p1_to_0:
xor   ah, ah

check_p2_2:

cmp   si, word ptr ds:[_tmbbox + (BOXBOTTOM * 4) + 2]
jl    set_p2_to_1_2

jne   set_p2_to_0
cmp   word ptr ds:[_tmbbox + (BOXBOTTOM * 4)], 0	; check lo bits..
jne   set_p2_to_1_2

set_p2_to_0:
xor   al, al

check_linedx:

cmp   dx, 0
jl    xor_p1_p2

done_with_switchblock_boxonlineside_ah:  ; ah has p1
cmp   al, ah
jne   return_minusone_boxonlineside
ret



set_p1_to_1_2:
mov   ah, 1
jmp   check_p2_2

set_p2_to_1_2:
mov   al, 1
jmp   check_linedx


non_zero_slopetype:
ja    not_vertical_high
; ST_VERTICAL_HIGH

;	  	temp.h.intbits = v1x;
;		p1 = tmbbox[BOXRIGHT].w < temp.w;
;		p2 = tmbbox[BOXLEFT].w < temp.w;

xor   ax, ax
; carry bit 1, cx (temp.w) is greater
; carry bit 0, cx (temp.w) is <=

; need to xor high bit for signed compare reasons

mov   dl, 080h
xor   ch, dl
mov   bx, word ptr ds:[_tmbbox + (BOXRIGHT * 4) + 2]
xor   bh, dl
cmp   bx, cx
rcl   ah, 1      	; get carry bit

mov   bx, word ptr ds:[_tmbbox + (BOXLEFT * 4) + 2]
xor   bh, dl
cmp   bx, cx
rcl   al, 1			; get carry bit

test  bx, bx		; test linedy
jge   done_with_switchblock_boxonlineside_ah_2
xor_p1_p2:
xor   ax, 00101h
done_with_switchblock_boxonlineside_ah_2:
cmp   al, ah		; -1, 0, or 1 result...
jne   return_minusone_boxonlineside
ret   

return_minusone_boxonlineside:
mov   al, -1
ret   



not_vertical_high:

; shared code for both cases



push  si	; P_PointOnLineSide_ params call 1
push  cx
push  bx
push  dx


cmp   ax, ST_NEGATIVE_HIGH
je    negative_high_slopetype
; ST_POSITIVE_HIGH



les   bx, dword ptr ds:[_tmbbox + BOXTOP * 4]  ; sizeof fixed_t_union
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXLEFT * 4]
mov   dx, es
cli   ; todo see "big todo"
call  P_PointOnLineSide_

sub   sp, 8  ; reuse same params for next call
sti   ; todo see "big todo"

xchg  ax, si   ; store p1

les   bx, dword ptr ds:[_tmbbox + BOXBOTTOM * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXRIGHT * 4]
mov   dx, es

call  P_PointOnLineSide_

done_with_switchblock_boxonlineside:

mov   dx, si
cmp   al, dl ; cmp p1/p2
jne   return_minusone_boxonlineside
ret   


negative_high_slopetype:
; ST_NEGATIVE_HIGH






les   bx, dword ptr ds:[_tmbbox + BOXTOP * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXRIGHT * 4]
mov   dx, es



cli   ; todo see "big todo"
call  P_PointOnLineSide_

sub   sp, 8  ; reuse same params for next call
sti   ; todo see "big todo"

xchg  ax, si   ; store p1

les   bx, dword ptr ds:[_tmbbox + BOXBOTTOM * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXLEFT * 4]
mov   dx, es

call  P_PointOnLineSide_

mov   dx, si
cmp   al, dl ; cmp p1/p2
jne   return_minusone_boxonlineside

ret   



ENDP

; boolean __near P_PointOnDivlineSide ( fixed_t	x, fixed_t	y ) {

; dx:ax : x
; cx:bx : y

;typedef struct {
;
;	fixed_t_union	x;  0, 2
;	fixed_t_union	y;  4, 6
;   fixed_t_union	dx; 8, A
;	fixed_t_union	dy; C, E
;    
;} divline_t;

PROC P_PointOnDivlineSide_ NEAR
PUBLIC P_PointOnDivlineSide_ 


; maybe mov di, _trace?
mov   es, ax  ; backup

mov   ax, word ptr ds:[_trace + 0Ah]
or    ax, word ptr ds:[_trace + 8]
jne   line_dx_nonzero

;	if (x <= line->x.w)
;	    return line->dy.w > 0;
;	return line->dy.w < 0;

cmp   dx, word ptr ds:[_trace + 2]
jl    x_lte_linex
jne   x_gt_linex
mov   ax, es	; restore ax
cmp   ax, word ptr ds:[_trace]
ja    x_gt_linex
x_lte_linex:
cmp   word ptr ds:[_trace + 0Eh], 0
jg    return_1_pointondivlineside
jne   return_0_pointondivlineside_2
cmp   word ptr ds:[_trace + 0Ch], 0
je    return_0_pointondivlineside_2
return_1_pointondivlineside:
mov   al, 1
ret   
return_0_pointondivlineside_2:
xor   al, al
ret   
x_gt_linex:
cmp   word ptr ds:[_trace + 0Eh], 0
jl    return_1_pointondivlineside
xor   al, al
ret   


line_dx_nonzero:
mov   ax, word ptr ds:[_trace + 0Eh]
or    ax, word ptr ds:[_trace + 0Ch]
jne   line_dy_nonzero

;	if (y <= line->y.w)
;	    return line->dx.w < 0;
;	return line->dx.w > 0;

cmp   cx, word ptr ds:[_trace + 6]
jl    y_lte_liney
jne   y_gt_liney
cmp   bx, word ptr ds:[_trace + 4]  
ja    y_gt_liney
y_lte_liney:
cmp   word ptr ds:[_trace + 0Ah], 0
jl    return_1_pointondivlineside
xor   al, al
ret   
y_gt_liney:
cmp   word ptr ds:[_trace + 0Ah], 0
jg    return_1_pointondivlineside
jne   return_0_pointondivlineside_3
cmp   word ptr ds:[_trace + 8], 0
ja    return_1_pointondivlineside
return_0_pointondivlineside_3:
xor   al, al
ret   

line_dy_nonzero:


;    dx.w = (x - line->x.w);
;    dy.w = (y - line->y.w);

mov   ax, es	; restore x low

sub   ax, word ptr ds:[_trace]		; dx is dx:si
sbb   dx, word ptr ds:[_trace + 2]
sub   bx, word ptr ds:[_trace + 4]  ; dy is cx:bx
sbb   cx, word ptr ds:[_trace + 6]

mov   es, ax     ; store ax low
mov   ax, word ptr ds:[_trace + 0Eh]

;    if ( (line->dy.h.intbits ^ line->dx.h.intbits ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )

xor   ax, word ptr ds:[_trace + 0Ah]
xor   ax, dx
xor   ax, cx
test  ah, 080h
je    sign_check_failed

;		if ((line->dy.h.intbits ^ dx.h.intbits) & 0x8000)

xor   dx, word ptr ds:[_trace + 0Eh]
test  dh, 080h
je    return_0_pointondivlineside
jump_to_return_1_pointondivlineside:
jmp   return_1_pointondivlineside
return_0_pointondivlineside:
xor   al, al
ret   

sign_check_failed:

push  si
push  di


; dx is dx:si
; dy is cx:bx
mov   si, es  
mov   di, dx  ; di:si are now dx


;	//todo is there a faster way to use just the 3 bytes?
;    // note these are internally being shifted by fixedmul2424
;    right = FixedMul2424 ( dy.w , line->dx.w );
;	left = FixedMul2424 ( line->dy.w, dx.w );



les   ax, dword ptr ds:[_trace + 08h]  ; line->dx
mov   dx, es

call  FixedMul2424_

; dx:ax is right

les   bx, dword ptr ds:[_trace + 0Ch]
mov   cx, es

xchg  dx, di   ; backup dx in di  get old value
xchg  ax, si   ; backup ax in si, get old value

call  FixedMul2424_

;dx:ax are left
;di:si are right
	;	return (right >= left);

cmp   di, dx
jg    return_1_pointondivlineside_popdisi
jne   return_0_pointondivlineside_4
cmp   si, ax
jae   return_1_pointondivlineside_popdisi
return_0_pointondivlineside_4:
xor   al, al

pop   di
pop   si
ret  
return_1_pointondivlineside_popdisi:
mov   al, 1
pop   di
pop   si
ret   


ENDP

;fixed_t __near P_InterceptVector ( divline_t __near*	v1 ) ;

PROC P_InterceptVector_ NEAR
PUBLIC P_InterceptVector_   

; todo sometimes this is called with all fracbits as 0. 
; Could be worth a 16 bit version. would be smaller

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp

;    den = FixedMul2432 (v1->dy.w,v2->dx.w) - 
;		FixedMul2432(v1->dx.w ,v2->dy.w);

; bp - 4  den hi (di den lo)


xchg  si, ax	; v1 divline ptr to si

les   bx, dword ptr ds:[_trace+8]
mov   cx, es
les   ax, dword ptr [si + 0Ch]
mov   dx, es
call  FixedMul2432_

les   bx, dword ptr ds:[_trace+0Ch]
mov   cx, es
push  ax	   ; bp-2
mov   di, dx

les   ax, dword ptr [si + 8]
mov   dx, es
call  FixedMul2432_

sub   word ptr [bp - 2], ax
sbb   di, dx		; den = ax:di 
push  di        ; bp - 4
or    di, word ptr [bp - 2]	; test for 0

; den is [bp-4]:[bp-2]

jne   den_not_zero
xchg  ax, di   ; di was 0
cwd
LEAVE_MACRO
pop   di
pop   si
pop   cx
pop   bx
ret   

den_not_zero:

;num = FixedMul2432 ( (v1->x.w - v2->x.w) ,v1->dy.w) + 
;		FixedMul2432 ( (v2->y.w - v1->y.w), v1->dx.w);

les   bx, dword ptr [si + 0Ch]
mov   cx, es
les   ax, dword ptr [si]
mov   dx, es
sub   ax, word ptr ds:[_trace]
sbb   dx, word ptr ds:[_trace+2]
call  FixedMul2432_

mov   bx, si  ; bx gets  v1
xchg  si, ax  ;  di:si = first half
mov   di, dx

les   ax, dword ptr ds:[_trace+4]
mov   dx, es

sub   ax, word ptr [bx + 4]
sbb   dx, word ptr [bx + 6]

les   bx, dword ptr [bx + 8]
mov   cx, es

call  FixedMul2432_

;    frac = FixedDiv (num , den);
;    return frac

pop   cx	; retrieve den
pop   bx  
add   ax, si
adc   dx, di

call FixedDiv_
LEAVE_MACRO
pop   di
pop   si
pop   cx
pop   bx
ret

ENDP


;void __near P_LineOpening (int16_t lineside1, int16_t linefrontsecnum, int16_t linebacksecnum);


; ax lineside 1
; dx linefrontsecnum
; bx linebacksecnum

; typedef struct lineopening_s {
;	short_height_t		opentop;
;	short_height_t 		openbottom;
;	short_height_t		lowfloor;
;	//short_height_t		openrange; // not worth storing thousands of bytes of a subtraction result
;} lineopening_t;

PROC P_LineOpening_ NEAR
PUBLIC P_LineOpening_ 


;    if (lineside1 == -1) {
;		// single sided line
; 		return;
;	}


cmp  ax, 0FFFFh
je   return_lineopening
mov  ax, SECTORS_SEGMENT
mov  ds, ax
SHIFT_MACRO shl  dx 4
SHIFT_MACRO shl  bx 4

;	front = &sectors[linefrontsecnum];
;	back = &sectors[linebacksecnum];

;if (front->ceilingheight < back->ceilingheight) {
;	lineopening.opentop = front->ceilingheight;
;} else {
;	lineopening.opentop = back->ceilingheight;
;}



; ds:dx = front
; ds:bx = back


les  ax, dword ptr ds:[bx] ; back + 0
mov  bx, dx	; [front]
mov  dx, es ; back + 2


les  bx, dword ptr ds:[bx] ; front + 0
; es has front + 2

; ax has back + 0
; dx has back + 2
; bx has front + 0
; es has front + 2

;	if (front->floorheight > back->floorheight) {
;		lineopening.openbottom = front->floorheight;
;		lineopening.lowfloor = back->floorheight;
;	} else {
;		lineopening.openbottom = back->floorheight;
;		lineopening.lowfloor = front->floorheight;
;	}


cmp  bx, ax
jle  front_floor_above_back_floor
xchg ax, bx ; swap param to write..

front_floor_above_back_floor:
mov  word ptr ss:[_lineopening+2], ax
mov  ax, ss
mov  ds, ax
mov  word ptr ds:[_lineopening+4], bx


mov  ax, es  ; front+2
cmp  ax, dx
jl   front_ceiling_below_back_ceiling
xchg ax, dx   ; swap what to write

front_ceiling_below_back_ceiling:
mov  word ptr ds:[_lineopening+0], ax  ; set opentop


return_lineopening:
ret  



ENDP



;void __near P_UnsetThingPosition (mobj_t __near* thing, uint16_t mobj_pos_offset);

PROC P_UnsetThingPosition_ NEAR
PUBLIC P_UnsetThingPosition_ 

; #define GETTHINKERREF(a) ((((uint16_t)((byte __near*)a - (byte __near*)thinkerlist))-4)/SIZEOF_THINKER_T)

; ax = thing
; dx = thingpos offset

; bp - 2   bnextRef

push  bx
push  cx
push  si
push  di
mov   si, ax

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
mov   bx, dx  ; move offset over. es:bx is mobjpos

lodsw     ; si + 0	; sprevRef
xchg  ax, dx    ; dx stores sprevRef

lodsw     ; si + 2 bnextRef
push  ax  ; bp - 2


; calculate thisref numerator. only div to calculate in the end if necessary
lea   cx, ds:[si - (_thinkerlist + 4) - 4]






mov   di, word ptr es:[bx + 0Ch]	; snextRef


;	if (!(thingflags1 & MF_NOSECTOR)) {

test  byte ptr es:[bx + 014h], MF_NOSECTOR  ; flags1
jne   mobj_inert_not_in_blockmap

;		if (thingsnextRef) {
;			changeThing = (mobj_t __near*)&thinkerlist[thingsnextRef].data;
;			changeThing->sprevRef = thingsprevRef;
;		}


test  di, di
je    no_next_ref


IF COMPILE_INSTRUCTIONSET GE COMPILE_186

xchg  ax, si ; store si in ax
imul  si, di, SIZEOF_THINKER_T

ELSE

push  dx

xor   dx, dx
mov   ax, SIZEOF_THINKER_T
mul   di
xchg  ax, si ; store si in ax, si gets value..

pop   dx


ENDIF

mov   word ptr ds:[si + (_thinkerlist + 4)], dx
xchg  ax, si  ; restore si

no_next_ref:

;		if (thingsprevRef) {
;			changeThing_pos = &mobjposlist_6800[thingsprevRef];
;			changeThing_pos->snextRef = thingsnextRef;
;		}

test  dx, dx
jne   has_prev_ref

;			sectors[thingsecnum].thinglistRef = thingsnextRef;

lodsw         ; si + 4  get secnum
SHIFT_MACRO  shl ax 4
xchg  ax, si  ; si gets secnum 

mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   word ptr es:[si + 8], di

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax

jmp   done_clearing_blockmap

exit_unset_position_and_pop_once:
pop   ax	; undo bp - 2
pop   di
pop   si
pop   cx
pop   bx
ret   


has_prev_ref:
;			changeThing_pos = &mobjposlist_6800[thingsprevRef];
;			changeThing_pos->snextRef = thingsnextRef;

; dx is thingsprevRef
; di is thingsnextRef

IF COMPILE_INSTRUCTIONSET GE COMPILE_186

imul  si, dx, SIZEOF_MOBJ_POS_T

ELSE

; 017h

sal   dx, 1
sal   dx, 1
sal   dx, 1
mov   si, dx
sal   dx, 1
add   si, dx


ENDIF

mov   word ptr es:[si + 0Ch], di
mobj_inert_not_in_blockmap:
done_clearing_blockmap:

;    if (! (thingflags1 & MF_NOBLOCKMAP) ) {


test  byte ptr es:[bx + 014h], MF_NOBLOCKMAP  ; flags1
jne   exit_unset_position_and_pop_once

;		blockx = (thingx.h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
;		blocky = (thingy.h.intbits - bmaporgy) >> MAPBLOCKSHIFT;
;		if (blockx >= 0 && blockx < bmapwidth && blocky >= 0 && blocky < bmapheight){


; do zero checks first. then we can do a faster unsigned shift. in 286 case

mov   ax, word ptr es:[bx + 6]  ; y high word
sub   ax, word ptr ds:[_bmaporgy]
jl    exit_unset_position_and_pop_once

mov   bx, word ptr es:[bx + 2]  ; x high word
sub   bx, word ptr ds:[_bmaporgx]
jl    exit_unset_position_and_pop_once

; shift ax 7

IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   ax, MAPBLOCKSHIFT
ELSE
	sal al, 1
	mov al, ah
	cbw
	rcl ax, 1
ENDIF

cmp   ax, word ptr ds:[_bmapheight]
jge   exit_unset_position_and_pop_once

; NOTE: this would not properly handle negatives in bh.
; however we caught negatives above.

; shift bx 7
IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   bx, MAPBLOCKSHIFT
ELSE
	sal bl, 1
	mov bl, bh
	rcl bx, 1
	and bh, 1
ENDIF

cmp   bx, word ptr ds:[_bmapwidth]
jge   exit_unset_position_and_pop_once








;			int16_t bindex = blocky * bmapwidth + blockx;
;			nextRef = blocklinks[bindex];

; ax is blocky
; bx is blockX

imul  word ptr ds:[_bmapwidth]  ; bmapwidth * blocky
add   bx, ax   ; add blockx
mov   ax, BLOCKLINKS_SEGMENT
mov   es, ax
sal   bx, 1   ; word lookup...
mov   ax, word ptr es:[bx]

;			while (nextRef) {
;				mobj_t __near* innerthing = &thinkerlist[nextRef].data;
;				if (innerthing->bnextRef == thisRef) {
;					innerthing->bnextRef = thingbnextRef;
;					break;
;				}
;				nextRef = innerthing->bnextRef;
;			}

; iterate to end of blockmap list.
; stop if we find ourselves.

test  ax, ax
je    exit_unset_position_and_pop_once

; only do the div to calculate thisref at the end if very necessary
xor   dx, dx
xchg  ax, cx
mov   di, SIZEOF_THINKER_T
div   di					; calculate thisref. todo move this way later. usually not used.
xchg  cx, ax			    ; cx gets thisref. ax restored.

pop   di	; di gets bnextRef

do_next_check_nextref_loop_iter:
; ax is nextref
; si becomes thinkerlist[nextref]
; cx is thisRef numerator (from way above..)
; bx is blockmap ref
; di is bnextRef


IF COMPILE_INSTRUCTIONSET GE COMPILE_186

imul  si, ax, SIZEOF_THINKER_T

ELSE

xor  dx, dx
xchg ax, si
mov  ax, SIZEOF_THINKER_T
mul  si
xchg ax, si

ENDIF

add   si, (_thinkerlist + 4) + 2
cmp   cx, word ptr [si]
jne   ref_not_a_match
; write bnextref and break look

mov   word ptr [si], di
check_nextref_loop_done:

;	if (nextRef == NULL_THINKERREF) {
;		blocklinks[bindex] = thingbnextRef;
;	}

test  ax, ax
je    not_found_in_blocklink
exit_unset_position:
pop   di
pop   si
pop   cx
pop   bx
ret   

ref_not_a_match:
; nextRef = innerthing->bnextRef;
mov   ax, word ptr [si]
test  ax, ax
jne   do_next_check_nextref_loop_iter

not_found_in_blocklink:
; es already blocklinks_segment

mov   word ptr es:[bx], di

pop   di
pop   si
pop   cx
pop   bx
ret   


ENDP



;void __far P_SetThingPosition (mobj_t __near* thing, uint16_t thing_pos_offset, int16_t knownsecnum);

; ax   	thing
; dx    thing_pos_offset
; bx    knownsecnum

PROC P_SetThingPosition_ FAR
PUBLIC P_SetThingPosition_ 

push  cx
push  si
push  di
push  bp
mov   bp, sp   ; todo remove once inner function call in asm

mov   cx, bx  ; knownsecnum

mov   di, ax  ; thing
mov   si, dx  ; thing_pos offset


;	THINKERREF thingRef = GETTHINKERREF(thing);

mov   bx, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + 4)
xor   dx, dx
div   bx
push  ax	;bp - 2 is thingref

mov   bx, MOBJPOSLIST_6800_SEGMENT
mov   es, bx


;	if (knownsecnum != -1) {

cmp   cx, -1
jne   secnum_ready

;		int16_t	subsecnum = R_PointInSubsector(thing_pos->x, thing_pos->y);;
;		int16_t subsectorsecnum = subsectors[subsecnum].secnum;
;		thing->secnum = subsectorsecnum;

les   ax, dword ptr es:[si]
mov   dx, es
mov   es, bx   ; was the segment above..
les   bx, dword ptr es:[si + 4]
mov   cx, es
sub   si, 8
call  R_PointInSubsector_
SHIFT_MACRO shl   ax 2
xchg  ax, bx
mov   ax, SUBSECTORS_SEGMENT
mov   es, ax
mov   cx, word ptr es:[bx]
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax

secnum_ready:

;		thing->secnum = knownsecnum;

mov   word ptr [di + 4], cx

;pop   cx  ; cx gets thingRef
mov    cx, word ptr [bp - 2]

;	if (!(thing_pos->flags1 & MF_NOSECTOR)) {

test  byte ptr es:[si + 014h], MF_NOSECTOR
jne   done_setting_sector_stuff


;		oldsectorthinglist = sectors[thing->secnum].thinglistRef;
;		sectors[thing->secnum].thinglistRef = thingRef;

mov   bx, word ptr [di + 4]
mov   ax, SECTORS_SEGMENT
mov   es, ax
SHIFT_MACRO shl   bx  4

mov   ax, cx
mov   dx, ax
xchg  ax, word ptr es:[bx + 8]

;		thing = (mobj_t __near*)&thinkerlist[thingRef].data;
;		thing_pos = &mobjposlist_6800[thingRef];


imul  di, dx, SIZEOF_THINKER_T
add   di, (_thinkerlist + 4)
mov   si, MOBJPOSLIST_6800_SEGMENT
mov   es, si

imul  si, dx, SIZEOF_MOBJ_POS_T

;		thing->sprevRef = NULL_THINKERREF;
mov   word ptr [di], 0
;		thing_pos->snextRef = oldsectorthinglist;
mov   word ptr es:[si + 0Ch], ax
;		if (thing_pos->snextRef) {
test  ax, ax


je    done_setting_sector_stuff

;			thingList = (mobj_t __near*)&thinkerlist[thing_pos->snextRef].data;
;			thingList->sprevRef = thingRef;

imul  bx, ax, SIZEOF_THINKER_T
mov   word ptr ds:[bx + (_thinkerlist + 4)], dx

done_setting_sector_stuff:

;    if (! (thingflags1 & MF_NOBLOCKMAP) ) {

test  byte ptr es:[si + 014h], MF_NOBLOCKMAP
jne   exit_set_position


;		temp = thing_pos->x;
;		blockx = (temp.h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
;		temp = thing_pos->y;
;		blocky = (temp.h.intbits - bmaporgy) >> MAPBLOCKSHIFT;

;		if (blockx>=0 && blockx < bmapwidth && blocky>=0 && blocky < bmapheight) {


mov   ax, word ptr es:[si + 6]
sub   ax, word ptr ds:[_bmaporgy]
jl    set_null_bnextref_and_exit ; quick check branches early

mov   bx, word ptr es:[si + 2]
sub   bx, word ptr ds:[_bmaporgx]
jl    set_null_bnextref_and_exit ; quick check branches early

; shift ax 7
IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   ax, MAPBLOCKSHIFT
ELSE
	sal al, 1
	mov al, ah
	cbw
	rcl ax, 1
ENDIF
; si is free now..


cmp   ax, word ptr ds:[_bmapheight]
jge   set_null_bnextref_and_exit ; quick check branches early

; NOTE: this would not properly handle negatives in bh.
; however we caught negatives above.

; shift bx 7
IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   bx, MAPBLOCKSHIFT
ELSE
	sal bl, 1
	mov bl, bh
	rcl bx, 1
	and bh, 1
ENDIF

mov   si, word ptr ds:[_bmapwidth]
cmp   bx, si
jge   set_null_bnextref_and_exit ; quick check branches early



;			int16_t bindex = blocky * bmapwidth + blockx;


imul  si  ; bmapwidth
add   bx, ax
sal   bx, 1

mov   ax, BLOCKLINKS_SEGMENT
mov   es, ax


;			linkRef = blocklinks[bindex];
;			thing->bnextRef = linkRef;		 
;			blocklinks[bindex] = thingRef;
; cx is already thingRef;

xchg  cx, word ptr es:[bx]  ; set thingref. get linkref
mov   word ptr [di + 2], cx ; set linkref


exit_set_position:
LEAVE_MACRO
pop   di
pop   si
pop   cx
retf  

set_null_bnextref_and_exit:

;			thing->bnextRef = NULL_THINKERREF;

mov   word ptr [di + 2], 0
LEAVE_MACRO
pop   di
pop   si
pop   cx
retf  

ENDP


; int16_t __near R_PointInSubsector ( fixed_t_union	x, fixed_t_union	y ) {

PROC R_PointInSubsector_ NEAR
PUBLIC R_PointInSubsector_ 


mov   word ptr cs:[SELFMODIFY_rpis_set_dx+1], dx
mov   word ptr cs:[SELFMODIFY_rpis_set_cx+1], cx

xchg  ax, dx  ; store dx
mov   ax, word ptr ds:[_numnodes]
test  ax, ax
je    exit_r_pointinsubsector  ; return 0

; set up loop.
dec   ax						; nodenum = numnodes - 1

push  di  ; inner functions in loop uses di..
push  si
push  bp  ; create stack frame here instead of inner func
mov   bp, sp

push  bx   ; bx, will be bp - 2
push  dx   ; old ax. will be bp - 4


; todo this might get blown up by a bigger prefetch queue. if so then move this behind the function?
continue_looping_point_on_side:

SHIFT_MACRO shl ax 2
xchg  si, ax				; si gets nodenum

mov   ax, NODE_CHILDREN_SEGMENT
mov   ds, ax

SELFMODIFY_rpis_set_dx:
mov   dx, 01000h
SELFMODIFY_rpis_set_cx:
mov   cx, 01000h

call  R_PointOnSide_   ; todo inline? only used here....
; ax has new nodenum...
test  ah, (NF_SUBSECTOR SHR 8)
je    continue_looping_point_on_side
skip_loop:

;	return nodenum & ~NF_SUBSECTOR;
and   ah, (NOT_NF_SUBSECTOR SHR 8)

; clean up loop stuff
LEAVE_MACRO
mov   bx, ss ;  restore ds
mov   ds, bx
pop   si
pop   di

exit_r_pointinsubsector:
ret  


ENDP


; boolean __near P_BlockLinesIterator ( int16_t x, int16_t y, boolean __near(*   func )(line_physics_t __far*, int16_t) );

PROC P_BlockLinesIterator_ NEAR
PUBLIC P_BlockLinesIterator_ 

push  cx
push  si
push  di

mov   cx, bx		; store function ptr in cx.


;if (x<0
;|| y<0
;|| x>=bmapwidth
;|| y>=bmapheight)
;{
;return true;
;}

test  ax, ax
jl    exit_blocklinesiterator_return_1
test  dx, dx
jl    exit_blocklinesiterator_return_1
cmp   ax, word ptr ds:[_bmapwidth]
jge   exit_blocklinesiterator_return_1
cmp   dx, word ptr ds:[_bmapheight]
jge   exit_blocklinesiterator_return_1

;    offset = y*bmapwidth+x;
;	offset = *(blockmaplump_plus4 + offset);


xchg  ax, bx  ; bx gets x

; set stuff up up ahead...
mov   ax, ds:[_validcount_global]
mov   word ptr cs:[SELFMODIFY_validcountglobal_1 + 1], ax

xchg  ax, dx  ; ax gets y 
imul  word ptr ds:[_bmapwidth]  ; y * width
add   bx, ax					; plus x
sal   bx, 1

mov   ax, BLOCKMAPLUMP_SEGMENT
mov   es, ax

mov   di, word ptr es:[bx + 8]	; blockmaplump plus 4
sal   di, 1   ; word offset

;    for ( index = offset ; blockmaplump[index] != -1 ; index++) {

loop_check_block_line:
mov   ax, BLOCKMAPLUMP_SEGMENT
mov   es, ax
mov   bx, word ptr es:[di]
cmp   bx, 0FFFFh
je    exit_blocklinesiterator_return_1

mov   si, bx
SHIFT_MACRO shl   si 4
mov   dx, LINES_PHYSICS_SEGMENT
mov   es, dx
SELFMODIFY_validcountglobal_1:
mov   ax, 01000h
cmp   ax, word ptr es:[si + 8]

; if (ld_physics->validcount == validcount_global) {

jne   check_block_line
check_next_block_line:
add   di, 2
jmp   loop_check_block_line
exit_blocklinesiterator_return_1:
mov   al, 1
pop   di
pop   si
pop   cx
ret   
check_block_line:

;		ld_physics->validcount = validcount_global;			
;		if (!func(ld_physics, list)) {
;			return false;
;		}


mov   word ptr es:[si + 8], ax  ; set validcount
mov   ax, si
call  cx
test  al, al
jne   check_next_block_line
; al = 0, return false
pop   di
pop   si
pop   cx
ret   

ENDP


;boolean __near P_BlockThingsIterator ( int16_t x, int16_t y, 
;boolean __near(*   func )(THINKERREF, mobj_t __near*, mobj_pos_t __far*) ){

PROC P_BlockThingsIterator_ NEAR
PUBLIC P_BlockThingsIterator_

push cx
push si
push di
mov  di, bx  ; func
;mov  si, ax
;mov  ax, dx

;    if ( x<0 || y<0 || x>=bmapwidth || y>=bmapheight) {
;		return true;
;	}


test ax, ax
jl   exit_blockthingsiterator_return1
test dx, dx
jl   exit_blockthingsiterator_return1
cmp  ax, word ptr ds:[_bmapwidth]
jge  exit_blockthingsiterator_return1
cmp  dx, word ptr ds:[_bmapheight]
jge  exit_blockthingsiterator_return1

;	for (mobjRef = blocklinks[y*bmapwidth + x]; mobjRef; mobjRef = mobj->bnextRef) {

xchg ax, bx  ; bx gets x
xchg ax, dx  ; ax gets y
imul word ptr ds:[_bmapwidth]
add  bx, ax
sal  bx, 1
mov  ax, BLOCKLINKS_SEGMENT
mov  es, ax

mov  si, word ptr es:[bx]
test si, si
je   exit_blockthingsiterator_return1


loop_check_next_block_thing:

IF COMPILE_INSTRUCTIONSET GE COMPILE_186

imul bx, si, SIZEOF_MOBJ_POS_T
mov  ax, si
imul si, si, SIZEOF_THINKER_T

ELSE

xor  dx, dx
mov  ax, SIZEOF_MOBJ_POS_T
mul  si
mov  bx, ax
;xor  dx, dx
mov  ax, SIZEOF_THINKER_T
mul  si
xchg ax, si	; si gets ptr, ax gets index

ENDIF

add  si, (_thinkerlist + 4)
mov  cx, MOBJPOSLIST_6800_SEGMENT
mov  dx, si
call di
test al, al
je   exit_blockthingsiterator
mov  si, word ptr [si + 2]
test si, si
jne  loop_check_next_block_thing
exit_blockthingsiterator_return1:
mov  al, 1
exit_blockthingsiterator:
pop  di
pop  si
pop  cx
ret
ENDP


;boolean __near  PIT_AddLineIntercepts (line_physics_t __far* ld_physics, int16_t linenum) {

PROC PIT_AddLineIntercepts_ NEAR
PUBLIC PIT_AddLineIntercepts_ 

; bp - 2 line_physics segment (constant)
; bp - 4 linenum

; bp - 014h divline

;	temp.h.fracbits = 0;
;	temp.h.intbits = v1x;
;	dl.x = temp;
;	temp.h.intbits = v1y;
;	dl.y = temp;

;	temp.h.intbits = linedx;
;	dl.dx.w = temp.w;
;	temp.h.intbits = linedy;
;	dl.dy.w = temp.w;



push  cx
push  si
push  bp
mov   bp, sp

xchg  ax, si
push  dx   ; bp - 2
mov   es, dx
push  bx   ; bp - 4


; todo move this after if/else?
xor   ax, ax
push  word ptr es:[si + 6]  ; bp - 6   line dy
push  ax					; bp - 8   0
push  word ptr es:[si + 4]  ; bp - 0Ah line dx
push  ax					; bp - 0Ch 0

les   bx, dword ptr es:[si]
mov   cx, es ; store si + 2 in cx for now
SHIFT_MACRO shl   bx 2

mov   dx, VERTEXES_SEGMENT
mov   es, dx

les   dx, dword ptr es:[bx]

push  es					; bp - 0Eh  vertex y
push  ax    				; bp - 010h
push  dx                    ; bp - 012h vertex x
push  ax    				; bp - 014h




;	if ( trace.dx.h.intbits > 16 || trace.dy.h.intbits > 16 || 
; trace.dx.h.intbits < -16 || trace.dy.h.intbits < -16) {

mov   al, 16  ; ah already 0

cmp   ax, word ptr ds:[_trace+0Ah]
jng   do_point_on_divlineside
cmp   ax, word ptr ds:[_trace+0Eh]
jng   do_point_on_divlineside
neg   ax
cmp   ax, word ptr ds:[_trace+0Ah]
jnl   do_point_on_divlineside
cmp   ax, word ptr ds:[_trace+0Eh]
jl   do_high_precision

do_point_on_divlineside:

; this happens about 3:1 compared to hi prec

;		// we actually know the vertex fields to be 16 bit, but trace has 32 bit fields

;		int16_t linev2Offset = ld_physics->v2Offset & VERTEX_OFFSET_MASK;
;		tempx.h.intbits = v1x;
;		tempy.h.intbits = v1y;
;		s1 = P_PointOnDivlineSide16(tempx.w, tempy.w);
;		tempx.h.intbits = vertexes[linev2Offset].x;
;		tempy.h.intbits = vertexes[linev2Offset].y;
;		s2 = P_PointOnDivlineSide16(tempx.w, tempy.w);


and   ch, (VERTEX_OFFSET_MASK SHR 8)
push  cx
; dx already v1x
mov   cx, es ;v1y
xor   ax, ax
mov   bx, ax
call  P_PointOnDivlineSide_
pop   bx
SHIFT_MACRO shl   bx 2
mov   byte ptr cs:[SELFMODIFY_compares1s2+1], al  ; store s1
mov   ax, VERTEXES_SEGMENT
mov   es, ax
les   dx, dword ptr es:[bx]
mov   cx, es
xor   ax, ax
mov   bx, ax
call  P_PointOnDivlineSide_
SELFMODIFY_compares1s2:
compare_s1s2:
cmp   al, 00h
jne   s1_s2_not_equal
exit_addlineintercepts_return_1:
mov   al, 1
LEAVE_MACRO
pop   si
pop   cx
ret   

do_high_precision:

;		s1 = P_PointOnLineSide (trace.x.w, trace.y.w, linedx, linedy, v1x, v1y);
;		s2 = P_PointOnLineSide (trace.x.w+trace.dx.w, trace.y.w+trace.dy.w, linedx, linedy, v1x, v1y);



push  es ;v1y
push  dx ;v1x
push  word ptr [bp - 6]
push  word ptr [bp - 0Ah]
les   ax, dword ptr ds:[_trace+0]
mov   dx, es
les   bx, dword ptr ds:[_trace+4]
mov   cx, es
cli   ; todo see "big todo"
call  P_PointOnLineSide_

sub   sp, 8

sti   ; todo see "big todo"

cbw  

   ; BIG TODO this sub sp, 8 is potentially killed by interrupts. 
   ; once every call to this func is in asm we can do this without 'ret 8' on the inside.




; store s1
mov   byte ptr cs:[SELFMODIFY_compares1s2+1], al


les   ax, dword ptr ds:[_trace+0]
mov   dx, es
les   bx, dword ptr ds:[_trace+4]
mov   cx, es

add   ax, word ptr ds:[_trace+8]
adc   dx, word ptr ds:[_trace+0Ah]
add   bx, word ptr ds:[_trace+0Ch]
adc   cx, word ptr ds:[_trace+0Eh]
call  P_PointOnLineSide_
jmp   compare_s1s2
s1_s2_not_equal:

; hit the line


;	temp.h.fracbits = 0;
;	temp.h.intbits = v1x;
;	dl.x = temp;
;	temp.h.intbits = v1y;
;	dl.y = temp;

;	temp.h.intbits = linedx;
;	dl.dx.w = temp.w;
;	temp.h.intbits = linedy;
;	dl.dy.w = temp.w;

; about one fourth of calls make it here to the expensive part of the call.
; maybe all that stack stuff shouldnt be done above? is it too expensive?

;lea   ax, [bp - 014h]
mov    ax, sp

;    frac = P_InterceptVector (&dl);
call  P_InterceptVector_   ; todo worth having a 16 bit version considering all the fracbits are 0...?

test  dx, dx
jnge  exit_addlineintercepts_return_1

SELFMODIFY_skip_early_out:
jmp   SHORT skip_early_out   ; jump when earlyout 0
SELFMODIFY_skip_early_out_AFTER:
cmp   dx, 1
jge   skip_early_out
mov   es, word ptr [bp - 2]
cmp   word ptr es:[si + 0Ch], -1
jne   skip_early_out
xor   al, al
LEAVE_MACRO
pop   si
pop   cx
ret   

SELFMODIFY_skip_early_out_TARGET:

skip_early_out:

 
;    intercept_p->frac = frac;
;    intercept_p->isaline = true;
;    intercept_p->d.linenum = linenum;
;    intercept_p++;
push  di
les   di, dword ptr ds:[_intercept_p]
stosw
xchg  ax, dx
stosw
mov   al, 1
stosb
mov   ax, word ptr [bp - 4]
stosw
mov   word ptr ds:[_intercept_p], di
mov   al, 1
pop   di
LEAVE_MACRO
pop   si
pop   cx
ret   



ENDP


;boolean __near  PIT_AddThingIntercepts (THINKERREF thingRef, mobj_t __near* thing, mobj_pos_t __far* thing_pos) ;

PROC PIT_AddThingIntercepts_ NEAR
PUBLIC PIT_AddThingIntercepts_ 

; ax  thingref
; dx  thing ptr
; cx:bx thing pos


; divline on stack is:

;    dl.x = x1;
;    dl.y = y1;
;    dl.dx.w = x2.w-x1.w;
;    dl.dy.w = y2.w-y1.w;



; bp - 2     2*radius or negative 2 * radius
; bp - 4     0
; bp - 6     2 * radius
; bp - 8     0
; bp - 0Ah   y1 hibits
; bp - 0Ch   y1 lobits
; bp - 0Eh   x1 hibits
; bp - 010h  x1 lobits
; bp - 012h  thingref

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
mov   di, sp
mov   si, bx  ; si gets thingpos ptr
push  ax  ; - 012h store thingref

;	x1 = x2 = thing_pos->x;
;	y1 = y2 = thing_pos->y;
;	x1.h.intbits -= thing->radius;
;	x2.h.intbits += thing->radius;


mov   bx, dx  ; get thingptr for radius
mov   bl, byte ptr ds:[bx + 01Eh]   ; radius byte
xor   bh, bh   ; zero radius high

mov   ds, cx ; ds:si setup (si above)
mov   ax, ss ; es:di setup (di above)
mov   es, ax

movsw   ; x lobits  bp - 010h
lodsw   ; x hibits  
mov   dx, ax  ; store x hibits
add   dx, bx  ; x2 hibits, add radius
sub   ax, bx  ; x1 hibits, sub radius
stosw	; x1 hibits      bp - 0Eh  
movsw   ; y1 lobits      bp - 0Ch
lodsw   ; y1 hibits  

mov   si, ax  ; store y hibits

mov   cx, ss
mov   ds, cx ; restore ds..



;	tracepositive = (trace.dx.h.intbits ^ trace.dy.h.intbits) > 0;
; probably enough to do high bytes?
mov   cx, word ptr ds:[_trace+0Ah]
xor   cx, word ptr ds:[_trace+0Eh]

;	if (tracepositive) {
;		y1.h.intbits += thing->radius;
;		y2.h.intbits -= thing->radius;
;	} else {

jle   tracepositive_false
add   ax, bx   ; y1 hibits
sub   si, bx   ; y2 hibits
stosw          ; y1 hibits bp - 0Ah
xchg  ax, cx   ; backup y1hi in cx
xor   ax, ax
stosw          ; bp - 08h
xchg  ax, bx
sal   ax, 1	   ; 2x radius
stosw          ; bp - 06h
neg   ax       ; in this case, negative 2x radius


do_divlinesides:

xchg  ax, bx
stosw     ; bp - 04h (zero)
xchg  ax, bx
stosw     ; bp - 02h (2xradius or negative)

; ax has double or double negative radius
; bx has 0
; cx has y1 hibits
; dx has x2 hibits
; di has garbage (bp)
; si has y2 hibits

mov di, dx  ; store x2 hibits

les ax, dword ptr [bp - 010h] ; x lobits
mov dx, es
mov bx, word ptr  [bp - 0Ch]  ; y lobits

; todo reorder stack for two LES


;	s1 = P_PointOnDivlineSide (x1.w, y1.w);

call  P_PointOnDivlineSide_

mov   byte ptr cs:[SELFMODIFY_compares1s2_2+1], al
mov   cx, si ; retrieve y2hibits
mov   dx, di ; retrieve x2hibits
mov   ax, word ptr [bp - 010h]  ; x lobits
mov   bx, word ptr [bp - 0Ch]   ; y lobits

;    s2 = P_PointOnDivlineSide (x2.w, y2.w);

call  P_PointOnDivlineSide_
SELFMODIFY_compares1s2_2:
cmp   al, 01h 
jne   s1_s2_not_equal_2
exit_addthingintercepts_return_1:
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
ret   

tracepositive_false:
;		y1.h.intbits -= thing->radius;
;		y2.h.intbits += thing->radius;
sub   ax, bx   ; y1 hibits
add   si, bx   ; y2 hibits
stosw     ; y1 hibits bp - 0Ah
xchg  ax, cx  ; backup y1hi in cx
xor   ax, ax
stosw     ; bp - 08h
xchg  ax, bx
sal   ax, 1		; 2x radius
stosw     ; bp - 06h
jmp   do_divlinesides

s1_s2_not_equal_2:

;    dl.x = x1;
;    dl.y = y1;
;    dl.dx.w = x2.w-x1.w;
;    dl.dy.w = y2.w-y1.w;


; divline is on the stack instead of in a variable. 
; calculations done up above
lea   ax, [bp - 010h] ; divline already on the stack.
;    frac = P_InterceptVector (&dl);

call  P_InterceptVector_
test  dx, dx ; test sign

;	if (frac < 0) {
;		return true;		// behind source
;	}

jl    exit_addthingintercepts_return_1
les   di, dword ptr ds:[_intercept_p]
stosw
xchg  ax, dx
stosw
xor   al, al
stosb
pop   ax ; word ptr [bp - 012h]
stosw
mov   word ptr ds:[_intercept_p], di

mov   al, 1
LEAVE_MACRO
pop   di
pop   si
ret   

ENDP

COMMENT @


; void __near P_TraverseIntercepts( traverser_t	func);

PROC P_TraverseIntercepts_ NEAR
PUBLIC P_TraverseIntercepts_ 

0x0000000000000000:  53                   push  bx
0x0000000000000001:  51                   push  cx
0x0000000000000002:  52                   push  dx
0x0000000000000003:  56                   push  si
0x0000000000000004:  55                   push  bp
0x0000000000000005:  89 E5                mov   bp, sp
0x0000000000000007:  83 EC 04             sub   sp, 4
0x000000000000000a:  50                   push  ax
0x000000000000000b:  A1 90 1C             mov   ax, word ptr ds:[_intercept_p]
0x000000000000000e:  BB 07 00             mov   bx, 7  ; sizeof intercept p
0x0000000000000011:  99                   cwd   
0x0000000000000012:  F7 FB                idiv  bx
0x0000000000000014:  31 F6                xor   si, si
0x0000000000000016:  89 76 FC             mov   word ptr [bp - 4], si
0x0000000000000019:  89 C1                mov   cx, ax
0x000000000000001b:  49                   dec   cx
0x000000000000001c:  83 F9 FF             cmp   cx, -1
0x000000000000001f:  74 44                je    0x65
0x0000000000000021:  BA FF FF             mov   dx, 0xffff
0x0000000000000024:  B8 FF 7F             mov   ax, 0x7fff
0x0000000000000027:  C7 46 FE 6C 4C       mov   word ptr [bp - 2], 0x4c6c
0x000000000000002c:  31 DB                xor   bx, bx
0x000000000000002e:  83 3E 90 1C 00       cmp   word ptr ds:[_intercept_p], 0
0x0000000000000033:  76 25                jbe   0x5a
0x0000000000000035:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000000038:  26 3B 47 02          cmp   ax, word ptr es:[bx + 2]
0x000000000000003c:  7F 07                jg    0x45
0x000000000000003e:  75 11                jne   0x51
0x0000000000000040:  26 3B 17             cmp   dx, word ptr es:[bx]
0x0000000000000043:  76 0C                jbe   0x51
0x0000000000000045:  89 DE                mov   si, bx
0x0000000000000047:  8C 46 FC             mov   word ptr [bp - 4], es
0x000000000000004a:  26 8B 17             mov   dx, word ptr es:[bx]
0x000000000000004d:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x0000000000000051:  83 C3 07             add   bx, 7
0x0000000000000054:  3B 1E 90 1C          cmp   bx, word ptr ds:[_intercept_p]
0x0000000000000058:  72 DE                jb    0x38
0x000000000000005a:  3D 01 00             cmp   ax, 1
0x000000000000005d:  7F 06                jg    0x65
0x000000000000005f:  75 0A                jne   0x6b
0x0000000000000061:  85 D2                test  dx, dx
0x0000000000000063:  76 06                jbe   0x6b
0x0000000000000065:  C9                   leave 
0x0000000000000066:  5E                   pop   si
0x0000000000000067:  5A                   pop   dx
0x0000000000000068:  59                   pop   cx
0x0000000000000069:  5B                   pop   bx
0x000000000000006a:  C3                   ret   
0x000000000000006b:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x000000000000006e:  89 F0                mov   ax, si
0x0000000000000070:  FF 56 FA             call  word ptr [bp - 6]
0x0000000000000073:  84 C0                test  al, al
0x0000000000000075:  74 EE                je    0x65
0x0000000000000077:  8E 46 FC             mov   es, word ptr [bp - 4]
0x000000000000007a:  26 C7 04 FF FF       mov   word ptr es:[si], 0xffff
0x000000000000007f:  26 C7 44 02 FF 7F    mov   word ptr es:[si + 2], 0x7fff
0x0000000000000085:  EB 94                jmp   0x1b

ENDP

@

;void __near P_PathTraverse ( fixed_t_union x1, fixed_t_union y1, fixed_t_union x2, fixed_t_union y2, uint8_t flags, boolean __near(*   trav) (intercept_t  __far*));

; DX:AX x1
; CX:BX y1

; bp + 2    old si
; bp + 4    old di
; bp + 6    old bp
; bp + 8    x1 hibits
; bp + 0Ah  x2 hibits
; bp + 0Ch  y2 lobits
; bp + 0Eh  y2 hibits
; bp + 010h flags
; bp + 012h trav  (function ptr)


; bp - 2    unused
; bp - 6    unused
; bp - 8    yintercept hibits  (di is lobits)
; bp - 0Ah  xintercept hibits
; bp - 0Ch  xintercept lobits
; bp - 0Eh  yt2
; bp - 010h xt2
; bp - 012h unused
; bp - 014h unused
; bp - 016h unused
; bp - 018h xt1
; bp - 01Ah unused
; bp - 01Ch x1mapblockshifted intbits?
; bp - 01Eh x1mapblockshifted lobits
; bp - 020h yt1
; bp - 022h unused
; bp - 024h unused
; bp - 026h unused

; bp - 028h x1 lobits
; bp - 02Ah x1 hibits
; bp - 02Ch y1 lobits
; bp - 02Eh y1 hibits

PROC P_PathTraverse_ NEAR
PUBLIC P_PathTraverse_ 

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 026h


; todo put trace on stack? then we can just push this stuff once... maybe
mov   word ptr ds:[_trace + 0], ax
mov   word ptr ds:[_trace + 2], dx
mov   word ptr ds:[_trace + 4], bx
mov   word ptr ds:[_trace + 6], cx


xchg ax, di  ; di stores x1 low bits

les   ax, dword ptr [bp + 8]
sub   ax, di
mov   word ptr ds:[_trace + 8], ax
mov   ax, es
sbb   ax, dx
mov   word ptr ds:[_trace + 0Ah], ax

les   ax, dword ptr [bp + 0Ch]
sub   ax, bx
mov   word ptr ds:[_trace + 0Ch], ax
mov   ax, es
sbb   ax, cx
mov   word ptr ds:[_trace + 0Eh], ax
;    x1.h.intbits -= bmaporgx;
;    y1.h.intbits -= bmaporgy;

;    x2.h.intbits -= bmaporgx;
;    y2.h.intbits -= bmaporgy;

les   ax, dword ptr ds:[_bmaporgx]
sub   dx, ax
sub   word ptr [bp + 0Ah], ax
mov   ax, es  ; _bmaporgy
sub   cx, ax
sub   word ptr [bp + 0Eh], ax
mov   ax, word ptr [bp - 02Ah]

; push these values on stack
push  di
push  dx
push  bx
push  cx



test  byte ptr [bp + 010h], PT_EARLYOUT

; jump when 0
jne   write_noop_to_earlyout
; zero. write jump
mov   ax, ((SELFMODIFY_skip_early_out_TARGET - SELFMODIFY_skip_early_out_AFTER) SHL 8) + 0EBh
jmp   do_earlyout_write
write_noop_to_earlyout:
mov   ax, 0c089h 	; noop
do_earlyout_write:
mov   word ptr cs:[SELFMODIFY_skip_early_out], ax

xor   ax, ax

;    trace.x = x1;
;    trace.y = y1;
;    trace.dx.w = x2.w - x1.w;
;    trace.dy.w = y2.w - y1.w;

mov   word ptr ds:[_intercept_p], ax
; todo move to static addr. hardcode intercepts segment.
mov   word ptr ds:[_intercept_p+2], INTERCEPTS_SEGMENT
inc   word ptr ds:[_validcount_global]

; just dx?
;    xt1 = x1.h.intbits>> MAPBLOCKSHIFT;

;	x1mapblockshifted.w = (x1.w >> MAPBLOCKSHIFT);

; shift ax:dx right 7
xchg  ax, dx ; x1 hibits in ax
mov   dx, di ; x1 lobits

sal   dl, 1  ; store overflow fit
mov   dl, dh ; shift 8
mov   dh, al ; shift 8
mov   al, ah ; shift 8
cbw          ; replace ah with sign bits
rcl   dx, 1  ; undo a shift - LSB becomes old bit
rcl   ax, 1



mov   word ptr [bp - 01Eh], dx

;	xintercept = x1mapblockshifted;
mov   word ptr [bp - 0Ch], dx
mov   word ptr [bp - 0Ah], ax
; xt1
mov   word ptr [bp - 018h], ax





;	y1mapblockshifted.w = (y1.w >> MAPBLOCKSHIFT);
;    yt1 = y1.h.intbits >> MAPBLOCKSHIFT;

mov   ax, cx  ; y1 hibits in ax
mov   dx, bx  ; y1 lobits in dx


sal   dl, 1  ; store overflow fit
mov   dl, dh ; shift 8
mov   dh, al ; shift 8
mov   al, ah ; shift 8
cbw          ; replace ah with sign bits
rcl   dx, 1  ; undo a shift - LSB becomes old bit
rcl   ax, 1

mov   word ptr [bp - 020h], ax   ; store yt1

mov   word ptr [bp - 01Ah], dx  ; store lobits
mov   di, dx
mov   word ptr [bp - 8], ax     ; store hibits

;todo remove once forward logic is cleaned up
 xchg  ax, si   ; si gets hibits
 

;    xt2 = x2.h.intbits >> MAPBLOCKSHIFT;
;    yt2 = y2.h.intbits >> MAPBLOCKSHIFT;



mov   ax, word ptr [bp + 0Ah]

; shift ax 7
IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   ax, MAPBLOCKSHIFT
ELSE
	sal al, 1
	mov al, ah
	cbw
	rcl ax, 1
ENDIF

mov   word ptr [bp - 010h], ax
xchg  ax, dx  ; dx stores xt2

mov   ax, word ptr [bp + 0Eh]

; shift ax 7
IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   ax, MAPBLOCKSHIFT
ELSE
	sal al, 1
	mov al, ah
	cbw
	rcl ax, 1
ENDIF


mov   word ptr [bp - 0Eh], ax
; ax has yt2
; dx has xt2






;	if (xt2 == xt1) {

; todo pull this logic earlier... 
cmp   dx, word ptr [bp - 018h]   ; dx holds xt2

je    xt2_equals_xt1

; xt2 != xt1

;		ystep = FixedDiv(y2.w - y1.w, labs(x2.w - x1.w));

; todo: some y1/x1 fields should still be in registers?
mov   ax, word ptr [bp + 8h]
sub   ax, word ptr [bp - 028h]
mov   dx, word ptr [bp + 0Ah]
sbb   dx, word ptr [bp - 02Ah]
mov   si, word ptr [bp + 0Ch]
or    dx, dx
jge   skip_labs_4
neg   ax
adc   dx, 0
neg   dx
skip_labs_4:
mov   cx, dx
sub   si, bx
mov   bx, ax
mov   dx, word ptr [bp + 0Eh]
sbb   dx, word ptr [bp - 02Eh]
mov   ax, si
call  FixedDiv_


mov   word ptr cs:[SELFMODIFY_add_yintercept_lo+2], ax
mov   word ptr cs:[SELFMODIFY_add_yintercept_hi+5], dx

xchg  bx, ax  ; cx, bx store ystep.
mov   cx, dx
;		partial = x1mapblockshifted.h.fracbits;

mov   ax, word ptr [bp - 01Eh] ; get x1mapblockshifted..

mov   dx, word ptr [bp - 010h] ; todo maybe put these together..

;		if (xt2 > xt1) {

cmp   dx, word ptr [bp - 018h]
jle   xt2_not_greater_than_xt1
neg   ax
mov   byte ptr cs:[SELFMODIFY_mapxstep_instruction], 041h   ; inc cx
add_to_yintercept:

;		yintercept.w += FixedMul16u32(partial, ystep);

; cx:bx = ystep

call  FixedMul16u32_
add   di, ax
adc   word ptr [bp - 8], dx
jmp   done_with_xt_check
xt2_not_greater_than_xt1:
;	mapxstep = -1;
mov   byte ptr cs:[SELFMODIFY_mapxstep_instruction], 049h   ; dec cx
jmp   add_to_yintercept

xt2_equals_xt1:

;		mapxstep = 0;
;		yintercept.h.intbits += 256;

mov   byte ptr cs:[SELFMODIFY_mapxstep_instruction], 090h   ; nop
inc   byte ptr [bp - 7]

done_with_xt_check:

;	if (yt2 == yt1) {

mov   ax, word ptr [bp - 0Eh] ; yt2
cmp   ax, word ptr [bp - 020h]
je    yt2_equals_yt1

;		xstep = FixedDiv(x2.w - x1.w, labs(y2.w - y1.w));

les   ax, dword ptr [bp + 0Ch]
mov   dx, es
sub   ax, word ptr [bp - 02Ch]
sbb   dx, word ptr [bp - 02Eh]

jge   skip_labs_3
neg   ax
adc   dx, 0
neg   dx
skip_labs_3:
mov   cx, dx
xchg  ax, bx   ; cx:bx gets labs result

; x2 - x1
les   ax, dword ptr [bp + 8]
mov   dx, es
sub   ax, word ptr [bp - 028h]
sbb   dx, word ptr [bp - 02Ah]

call  FixedDiv_

mov   word ptr cs:[SELFMODIFY_add_xintercept_lo+3], ax
mov   word ptr cs:[SELFMODIFY_add_xintercept_hi+5], dx


; cx:bx gets xstep
xchg  ax, bx
mov   cx, dx

;		partial = y1mapblockshifted.h.fracbits;
mov   ax, word ptr [bp - 01Ah]

mov   dx, word ptr [bp - 0Eh]

;	if (yt2 > yt1) {
cmp   dx, word ptr [bp - 020h]
jle   yt2_not_greater_than_yt1

;			mapystep = 1;
;			partial ^= 0xFFFF;
;			partial++;

neg   ax
mov   byte ptr cs:[SELFMODIFY_mapystep_instruction], 046h   ; inc si
add_to_xintercept:


;		xintercept.w += FixedMul16u32(partial, xstep);

call  FixedMul16u32_
add   word ptr [bp - 0Ch], ax
adc   word ptr [bp - 0Ah], dx
jmp   done_with_yt_check
yt2_not_greater_than_yt1:
;			mapystep = -1;
mov   byte ptr cs:[SELFMODIFY_mapystep_instruction], 04Eh   ; dec si
jmp   add_to_xintercept

yt2_equals_yt1:

;		xintercept.h.intbits += 256;
;		mapystep = 0;

mov   byte ptr cs:[SELFMODIFY_mapystep_instruction], 090h   ; nop
inc   byte ptr [bp - 9]

done_with_yt_check:

;    mapx = xt1;
 ;   mapy = yt1;

; NOTE: here we will do selfmodifying code to reduce stack/memory 
; usage and go with a bunch of immediates.

les   ax, dword ptr [bp - 0Ah]
mov   word ptr cs:[SELFMODIFY_yintercept_intbits+2], es  ; bp - 8
mov   word ptr cs:[SELFMODIFY_xintercept_intbits+2], ax

mov   cx, word ptr [bp - 018h]  ; xt1
mov   si, word ptr [bp - 020h]  ; yt1
mov   byte ptr [bp - 4], 64     ; count


;	for (count = 0 ; count < 64 ; count++) {

loop_traverse_loop:
; todo selfmodify
;		if (flags & PT_ADDLINES) {
test  byte ptr [bp + 010h], 1
jne   do_addlines_check
addlines_fallthru:
test  byte ptr [bp + 010h], 2
jne   do_addthings_check
addthings_fallthru:
;		if (mapx == xt2 && mapy == yt2) {

; todo selfmodify these into constants
cmp   cx, word ptr [bp - 010h]
jne   xt2yt2_not_equal
cmp   si, word ptr [bp - 0Eh]
je    traverse_loop_done
xt2yt2_not_equal:

;		if ( (yintercept.h.intbits) == mapy) {

SELFMODIFY_yintercept_intbits:
cmp   si, 01000h
jne   intercept_not_mapy

;			yintercept.w += ystep;
;			mapx += mapxstep;

SELFMODIFY_add_yintercept_lo:
add   di, 01000h
SELFMODIFY_add_yintercept_hi:
adc   word ptr cs:[SELFMODIFY_yintercept_intbits+2], 01000h

; this becomes either
; inc cx 0x41
; dec cx 0x49
; nop    0x90

SELFMODIFY_mapxstep_instruction:
inc   cx

decrement_loop_counter_and_continue:
dec   byte ptr [bp - 4]
jnz    loop_traverse_loop
traverse_loop_done:
mov   ax, word ptr [bp + 012h]
call  P_TraverseIntercepts_
exit_path_traverse:
LEAVE_MACRO
pop   di
pop   si
ret   0Ch

do_addlines_check:

;			if (!P_BlockLinesIterator (mapx, mapy,PIT_AddLineIntercepts))
;				return;	// early out

mov   bx, OFFSET PIT_AddLineIntercepts_
mov   dx, si
mov   ax, cx
call  P_BlockLinesIterator_
test  al, al
je   exit_path_traverse

jmp   addlines_fallthru
do_addthings_check:
;			if (!P_BlockThingsIterator (mapx, mapy,PIT_AddThingIntercepts))
;				return;	// early out

mov   bx, OFFSET PIT_AddThingIntercepts_
mov   dx, si
mov   ax, cx
call  P_BlockThingsIterator_
test  al, al
je    exit_path_traverse
jmp   addthings_fallthru
intercept_not_mapy:
;		} else if ( (xintercept.h.intbits) == mapx) {

SELFMODIFY_xintercept_intbits:
cmp   cx, 01000h
jne   decrement_loop_counter_and_continue

;			xintercept.w += xstep;
;			mapy += mapystep;

SELFMODIFY_add_xintercept_lo:
add   word ptr [bp - 0Ch], 01000h
SELFMODIFY_add_xintercept_hi:
adc   word ptr cs:[SELFMODIFY_xintercept_intbits+2], 01000h

; this becomes either
; inc si 0x46
; dec si 0x4E
; nop    0x90
SELFMODIFY_mapystep_instruction:
inc   si
jmp   decrement_loop_counter_and_continue

ENDP

COMMENT  @
PROC P_PathTraverse_ NEAR
PUBLIC P_PathTraverse_ 

ENDP
@





END
