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


EXTRN FixedMul1632_:FAR
EXTRN FixedMul2424_:FAR
EXTRN FixedMul2432_:FAR
EXTRN FixedDiv_:FAR
EXTRN R_PointInSubsector_	:PROC
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA

EXTRN _trace:WORD
EXTRN _lineopening:WORD

.CODE



;R_PointOnSide_

PROC R_PointOnSide_ NEAR
PUBLIC R_PointOnSide_ 

push  di
push  bp
mov   bp, sp
push  bx
push  ax

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

SHIFT_MACRO shl si 2

mov   ax, NODE_CHILDREN_SEGMENT
mov   es, ax



; todo lds?
mov   ds, word ptr es:[si + 00h]   ; child 0
mov   di, word ptr es:[si + 02h]   ; child 1

push  di ; child 1 to go into es later...

shl   si, 1     ; 8 indexed
mov   ax, NODES_SEGMENT
mov   es, ax  ; ES for nodes lookup


;  get lx, ly, ldx, ldy

les   bx, dword ptr es:[si + 0]   ; lx
mov   di, es   					  ; ly
mov   es, ax

les   ax, dword ptr es:[si + 4]   ; ldx
mov   si, es                      ; ldy



pop   es ; shove child 1 in es..




; ax = ldx
; si = ldy
; bx = lx
; di = ly
; dx = x highbits
; cx = y highbits
; bp -4h = x lowbits
; bp -2h = y lowbits
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
mov   di, ss ;  restore ds
mov   ds, di
LEAVE_MACRO
pop   di
ret   

;            return node->dy > 0;

return_node_dy_greater_than_0:
cmp  si, 0
jle  return_false

return_true:


mov   ax, es
mov   di, ss ;  restore ds
mov   ds, di
LEAVE_MACRO
pop   di
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

mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
ret    
ret_node_dx_less_than_0:

;            return node->dx < 0;

cmp    ax, 0
jl    return_true

; return false
mov   ax, ds

mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
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
mov   di, cx  ; store cx.. 
pop bx
mov   cx, dx
push  es ; note - fixedmul clobbers ES. need to store that.


call FixedMul1632_

; set up params..
xchg  si, ax
pop   es
pop   bx
mov   cx, di

mov   di, dx
push  es ; note - fixedmul clobbers ES. need to store that.
call FixedMul1632_
pop  es
cmp   dx, di
jg    return_true_2
je    check_lowbits

return_false_2:
mov   ax, ds
mov   di, ss ;  restore ds
mov   ds, di
pop   bp
pop   di
ret   

check_lowbits:
cmp   ax, si
jb    return_false_2
return_true_2:
mov   ax, es

mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
ret   
do_sign_bit_return:

;		// (left is negative)
;		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1

xor   si, dx
jl    return_true_2

mov   ax, ds


mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
ret   


endp


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
call  P_PointOnLineSide_

sub   sp, 8  ; reuse same params for next call

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



call  P_PointOnLineSide_

sub   sp, 8  ; reuse same params for next call

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



;void __near P_UnsetThingPosition (mobj_t __near* thing, mobj_pos_t __far* thing_pos);

PROC P_UnsetThingPosition_ NEAR
PUBLIC P_UnsetThingPosition_ 

; #define GETTHINKERREF(a) ((((uint16_t)((byte __near*)a - (byte __near*)thinkerlist))-4)/SIZEOF_THINKER_T)

; ax = thing
; cx:bx = thingpos...
; cx is constant.      todo make it pass in 8 bits

; bp - 2   sprevRef
; bp - 4   bnextRef
; bp - 6   secnum

push  dx
push  si
push  di
push  bp
mov   bp, sp
mov   si, ax

lodsw     ; si + 0	; sprevRef
push  ax  ; bp - 2
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
lodsw     ; si + 2 bnextRef
push  ax  ; bp - 4

lodsw     ; si + 4  ; secnum
push  ax  ; bp - 6

; calculate thisref numerator. only div to calculate in the end if necessary
lea   cx, ds:[si - (_thinkerlist + 4) - 6]






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
imul  si, di, SIZEOF_THINKER_T
mov   ax, word ptr [bp - 2]
mov   word ptr ds:[si + (_thinkerlist + 4)], ax

no_next_ref:

;		if (thingsprevRef) {
;			changeThing_pos = &mobjposlist_6800[thingsprevRef];
;			changeThing_pos->snextRef = thingsnextRef;
;		}

mov   ax, word ptr [bp - 2]
test  ax, ax
jne   has_prev_ref

;			sectors[thingsecnum].thinglistRef = thingsnextRef;

pop   si   ; get secnum
mov   ax, SECTORS_SEGMENT
shl   si, 4
mov   es, ax
mov   word ptr es:[si + 8], di

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax

jmp   done_clearing_blockmap

has_prev_ref:
;			changeThing_pos = &mobjposlist_6800[thingsprevRef];
;			changeThing_pos->snextRef = thingsnextRef;

; ax is thingsprevRef
; di is thingsnextRef

imul  si, ax, SIZEOF_MOBJ_POS_T
mov   word ptr es:[si + 0Ch], di
mobj_inert_not_in_blockmap:
done_clearing_blockmap:

;    if (! (thingflags1 & MF_NOBLOCKMAP) ) {


test  byte ptr es:[bx + 014h], MF_NOBLOCKMAP  ; flags1
jne   exit_unset_position

;		blockx = (thingx.h.intbits - bmaporgx) >> MAPBLOCKSHIFT;
;		blocky = (thingy.h.intbits - bmaporgy) >> MAPBLOCKSHIFT;
;		if (blockx >= 0 && blockx < bmapwidth && blocky >= 0 && blocky < bmapheight){


; do zero checks first. then we can do a faster unsigned shift. in 286 case

mov   ax, word ptr es:[bx + 6]  ; y high word
sub   ax, word ptr ds:[_bmaporgy]
jl    exit_unset_position

mov   bx, word ptr es:[bx + 2]  ; x high word
sub   bx, word ptr ds:[_bmaporgx]
jl    exit_unset_position



; shift bx 7
IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   bx, MAPBLOCKSHIFT
ELSE
	sal bl, 1
	mov bl, bh
	rcl bx, 1
	and bh, 1
ENDIF

; shift ax 7

IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   ax, MAPBLOCKSHIFT
ELSE
	sal al, 1
	mov al, ah
	rcl ax, 1
	and ah, 1
ENDIF




cmp   bx, word ptr ds:[_bmapwidth]
jge   exit_unset_position

cmp   ax, word ptr ds:[_bmapheight]
jge   exit_unset_position

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


test  ax, ax
je    exit_unset_position

; only do the div to calculate thisref at the end if very necessary
xor   dx, dx
xchg  ax, cx
mov   di, SIZEOF_THINKER_T
div   di					; calculate thisref. todo move this way later. usually not used.
xchg  cx, ax			    ; cx gets thisref. ax restored.


do_next_check_nextref_loop_iter:
; ax is nextref
; si becomes thinkerlist[nextref]
; cx is thisRef numerator (from way above..)
; bx is blockmap ref


imul  si, ax, SIZEOF_THINKER_T
add   si, (_thinkerlist + 4) + 2
cmp   cx, word ptr [si]
jne   ref_not_a_match
; write bnextref and break look
mov   cx, word ptr [bp - 4]
mov   word ptr [si], cx
check_nextref_loop_done:

;	if (nextRef == NULL_THINKERREF) {
;		blocklinks[bindex] = thingbnextRef;
;	}

test  ax, ax
je    not_found_in_blocklink
exit_unset_position:
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   

ref_not_a_match:
; nextRef = innerthing->bnextRef;
mov   ax, word ptr [si]
test  ax, ax
jne   do_next_check_nextref_loop_iter

not_found_in_blocklink:
; es already blocklinks_segment
mov   ax, word ptr [bp - 4]
mov   word ptr es:[bx], ax
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   

ENDP

COMMENT @


;void __far P_SetThingPosition (mobj_t __near* thing, mobj_pos_t __far* thing_pos, int16_t knownsecnum);

PROC P_SetThingPosition_ FAR
PUBLIC P_SetThingPosition_ 

0x0000000000000000:  56                push  si
0x0000000000000001:  57                push  di
0x0000000000000002:  55                push  bp
0x0000000000000003:  89 E5             mov   bp, sp
0x0000000000000005:  83 EC 04          sub   sp, 4
0x0000000000000008:  89 C7             mov   di, ax
0x000000000000000a:  89 DE             mov   si, bx
0x000000000000000c:  89 4E FE          mov   word ptr [bp - 2], cx
0x000000000000000f:  89 D1             mov   cx, dx
0x0000000000000011:  BB 2C 00          mov   bx, SIZEOF_THINKER_T
0x0000000000000014:  2D 04 40          sub   ax, (_thinkerlist + 4)
0x0000000000000017:  31 D2             xor   dx, dx
0x0000000000000019:  F7 F3             div   bx
0x000000000000001b:  89 46 FC          mov   word ptr [bp - 4], ax
0x000000000000001e:  83 F9 FF          cmp   cx, -1
0x0000000000000021:  75 03             jne   0x26
0x0000000000000023:  E9 A9 00          jmp   0xcf
0x0000000000000026:  89 4D 04          mov   word ptr [di + 4], cx
0x0000000000000029:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000002c:  26 F6 44 14 08    test  byte ptr es:[si + 014h], 8
0x0000000000000031:  75 44             jne   0x77
0x0000000000000033:  8B 5D 04          mov   bx, word ptr [di + 4]
0x0000000000000036:  B8 00 E0          mov   ax, SECTORS_SEGMENT
0x0000000000000039:  C1 E3 04          shl   bx, 4
0x000000000000003c:  8E C0             mov   es, ax
0x000000000000003e:  8B 56 FC          mov   dx, word ptr [bp - 4]
0x0000000000000041:  26 8B 47 08       mov   ax, word ptr es:[bx + 8]
0x0000000000000045:  26 89 57 08       mov   word ptr es:[bx + 8], dx
0x0000000000000049:  6B FA 2C          imul  di, dx, SIZEOF_THINKER_T
0x000000000000004c:  83 C3 08          add   bx, 8
0x000000000000004f:  6B DA 18          imul  bx, dx, 0x18
0x0000000000000052:  81 C7 04 40       add   di, (_thinkerlist + 4)
0x0000000000000056:  C7 46 FE F5 6A    mov   word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT
0x000000000000005b:  C7 05 00 00       mov   word ptr [di], 0
0x000000000000005f:  8E 46 FE          mov   es, word ptr [bp - 2]
0x0000000000000062:  89 DE             mov   si, bx
0x0000000000000064:  26 89 47 0C       mov   word ptr es:[bx + 0xc], ax
0x0000000000000068:  85 C0             test  ax, ax
0x000000000000006a:  74 0B             je    0x77
0x000000000000006c:  6B D8 2C          imul  bx, ax, SIZEOF_THINKER_T
0x000000000000006f:  89 97 04 40       mov   word ptr ds:[bx + (_thinkerlist + 4)], dx
0x0000000000000073:  81 C3 04 40       add   bx, (_thinkerlist + 4)
0x0000000000000077:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000007a:  26 F6 44 14 10    test  byte ptr es:[si + 014h], 010h
0x000000000000007f:  75 4A             jne   0xcb
0x0000000000000081:  BB E0 05          mov   bx, _bmaporgx
0x0000000000000084:  26 8B 44 02       mov   ax, word ptr es:[si + 2]
0x0000000000000088:  2B 07             sub   ax, word ptr [bx]
0x000000000000008a:  89 C3             mov   bx, ax
0x000000000000008c:  26 8B 44 06       mov   ax, word ptr es:[si + 6]
0x0000000000000090:  BE E2 05          mov   si, _bmaporgy
0x0000000000000093:  2B 04             sub   ax, word ptr [si]
0x0000000000000095:  C1 FB 07          sar   bx, MAPBLOCKSHIFT
0x0000000000000098:  C1 F8 07          sar   ax, MAPBLOCKSHIFT
0x000000000000009b:  85 DB             test  bx, bx
0x000000000000009d:  7C 58             jl    0xf7
0x000000000000009f:  BE DC 05          mov   si, _bmapwidth
0x00000000000000a2:  3B 1C             cmp   bx, word ptr [si]
0x00000000000000a4:  7D 51             jge   0xf7
0x00000000000000a6:  85 C0             test  ax, ax
0x00000000000000a8:  7C 4D             jl    0xf7
0x00000000000000aa:  BE DE 05          mov   si, _bmapheight
0x00000000000000ad:  3B 04             cmp   ax, word ptr [si]
0x00000000000000af:  7D 46             jge   0xf7
0x00000000000000b1:  BE DC 05          mov   si, _bmapwidth
0x00000000000000b4:  F7 2C             imul  word ptr [si]
0x00000000000000b6:  01 C3             add   bx, ax
0x00000000000000b8:  B8 00 64          mov   ax, BLOCKLINKS_SEGMENT
0x00000000000000bb:  01 DB             add   bx, bx
0x00000000000000bd:  8E C0             mov   es, ax
0x00000000000000bf:  26 8B 07          mov   ax, word ptr es:[bx]
0x00000000000000c2:  89 45 02          mov   word ptr [di + 2], ax
0x00000000000000c5:  8B 46 FC          mov   ax, word ptr [bp - 4]
0x00000000000000c8:  26 89 07          mov   word ptr es:[bx], ax
0x00000000000000cb:  C9                LEAVE_MACRO
0x00000000000000cc:  5F                pop   di
0x00000000000000cd:  5E                pop   si
0x00000000000000ce:  CB                retf  
0x00000000000000cf:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000000d2:  26 8B 5C 04       mov   bx, word ptr es:[si + 4]
0x00000000000000d6:  26 8B 4C 06       mov   cx, word ptr es:[si + 6]
0x00000000000000da:  26 8B 04          mov   ax, word ptr es:[si]
0x00000000000000dd:  26 8B 54 02       mov   dx, word ptr es:[si + 2]
0x00000000000000e1:  E8 F2 DA          call  R_PointInSubsector_
0x00000000000000e4:  89 C3             mov   bx, ax
0x00000000000000e6:  B8 29 EA          mov   ax, SUBSECTORS_SEGMENT
0x00000000000000e9:  C1 E3 02          shl   bx, 2
0x00000000000000ec:  8E C0             mov   es, ax
0x00000000000000ee:  26 8B 07          mov   ax, word ptr es:[bx]
0x00000000000000f1:  89 45 04          mov   word ptr [di + 4], ax
0x00000000000000f4:  E9 32 FF          jmp   0x29
0x00000000000000f7:  C7 45 02 00 00    mov   word ptr [di + 2], 0
0x00000000000000fc:  C9                LEAVE_MACRO
0x00000000000000fd:  5F                pop   di
0x00000000000000fe:  5E                pop   si
0x00000000000000ff:  CB                retf  

ENDP

@


; boolean __near P_BlockLinesIterator ( int16_t x, int16_t y, boolean __near(*   func )(line_physics_t __far*, int16_t) );


END
