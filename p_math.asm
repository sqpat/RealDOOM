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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA

EXTRN _trace:WORD

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

push  si
push  di
push  bp
mov   bp, sp
mov   di, ax
mov   si, bx
mov   ax, dx
mov   dx, cx  ; todo clean up this juggle
mov   bx, word ptr ds:[_trace + 0Ah]
or    bx, word ptr ds:[_trace + 8]
jne   line_dx_nonzero

;	if (x <= line->x.w)
;	    return line->dy.w > 0;
;	return line->dy.w < 0;


cmp   ax, word ptr ds:[_trace + 2]
jl    x_lte_linex
jne   x_gt_linex
cmp   di, word ptr ds:[_trace]
ja    x_gt_linex
x_lte_linex:
mov   ax, word ptr ds:[_trace + 0Eh]
test  ax, ax
jg    return_1_pointondivlineside
jne   return_0_pointondivlineside_2
cmp   word ptr ds:[_trace + 0Ch], 0
jbe   return_0_pointondivlineside_2
return_1_pointondivlineside:
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
ret   
return_0_pointondivlineside_2:
xor   al, al
LEAVE_MACRO
pop   di
pop   si
ret   
x_gt_linex:
mov   ax, word ptr ds:[_trace + 0Eh]
test  ax, ax
jl    return_1_pointondivlineside
xor   al, al
LEAVE_MACRO
pop   di
pop   si
ret   


line_dx_nonzero:
mov   bx, word ptr ds:[_trace + 0Eh]
or    bx, word ptr ds:[_trace + 0Ch]
jne   line_dy_nonzero

;	if (y <= line->y.w)
;	    return line->dx.w < 0;
;	return line->dx.w > 0;

mov   ax, word ptr ds:[_trace + 6]
cmp   cx, ax
jl    y_lte_liney
jne   y_gt_liney
cmp   si, word ptr ds:[_trace + 4]
ja    y_gt_liney
y_lte_liney:
mov   ax, word ptr ds:[_trace + 0Ah]
test  ax, ax
jl    return_1_pointondivlineside
xor   al, al
LEAVE_MACRO
pop   di
pop   si
ret   
y_gt_liney:
mov   ax, word ptr ds:[_trace + 0Ah]
test  ax, ax
jg    return_1_pointondivlineside
jne   return_0_pointondivlineside_3
cmp   word ptr ds:[_trace + 8], 0
ja    return_1_pointondivlineside
return_0_pointondivlineside_3:
xor   al, al
LEAVE_MACRO
pop   di
pop   si
ret   

line_dy_nonzero:
mov   dx, word ptr ds:[_trace + 0Eh]
mov   bx, di
mov   di, cx
sub   bx, word ptr ds:[_trace]
sbb   ax, word ptr ds:[_trace + 2]
sub   si, word ptr ds:[_trace + 4]
sbb   di, word ptr ds:[_trace + 6]

;    if ( (line->dy.h.intbits ^ line->dx.h.intbits ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )

xor   dx, word ptr ds:[_trace + 0Ah]
xor   dx, ax
xor   dx, di
test  dh, 080h
je    sign_check_failed
xor   ax, word ptr ds:[_trace + 0Eh]
test  ah, 080h
je    return_0_pointondivlineside
jump_to_return_1_pointondivlineside:
jmp   return_1_pointondivlineside
return_0_pointondivlineside:
xor   al, al
LEAVE_MACRO
pop   di
pop   si
ret   

sign_check_failed:
mov   cx, ax

mov   ax, word ptr ds:[_trace + 0Ch]
mov   dx, word ptr ds:[_trace + 0Eh]

call  FixedMul2424_
mov   bx, word ptr ds:[_trace + 8]
mov   cx, word ptr ds:[_trace + 0Ah]
xchg  ax, di   ; backup ax in di
xchg  ax, dx   ; dx gets old di
xchg  ax, si   ; ax gets si. si gets old dx

call  FixedMul2424_
cmp   dx, si
jg    jump_to_return_1_pointondivlineside
jne   return_0_pointondivlineside_4
cmp   ax, di
jae   jump_to_return_1_pointondivlineside
return_0_pointondivlineside_4:
xor   al, al
LEAVE_MACRO
pop   di
pop   si
ret  

ENDP

END
