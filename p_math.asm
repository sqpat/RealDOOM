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
EXTRN FixedMul_:FAR
EXTRN FixedDiv_:FAR
EXTRN S_StartSound_:FAR
EXTRN P_UseSpecialLine_:PROC
EXTRN FixedMulTrigNoShift_:PROC
EXTRN R_PointToAngle2_16_:PROC
EXTRN R_PointToAngle2_:PROC
EXTRN P_Random_:NEAR
EXTRN P_DamageMobj_:NEAR
EXTRN P_SetMobjState_:NEAR
EXTRN P_TouchSpecialThing_:NEAR
EXTRN P_CrossSpecialLine_:NEAR
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA

EXTRN _tmy:DWORD
EXTRN _tmx:DWORD
EXTRN _tmymove:DWORD
EXTRN _tmxmove:DWORD
EXTRN _tmceilingz:WORD
EXTRN _tmfloorz:WORD
EXTRN _tmthing:WORD
EXTRN _tmthing_pos:WORD
EXTRN _tmdropoffz:WORD
EXTRN _tmflags1:WORD
EXTRN _ceilinglinenum:WORD
EXTRN _trace:WORD
EXTRN _lineopening:WORD
EXTRN _intercept_p:WORD
EXTRN _playerMobjRef:WORD
EXTRN _playerMobj:WORD
EXTRN _playerMobj_pos:WORD
EXTRN _bestslidefrac:WORD
EXTRN _bestslidelinenum:WORD
EXTRN _numspechit:WORD
EXTRN _lastcalculatedsector:WORD
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

cmp   word ptr [bp - 4], 0
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
cmp   word ptr [bp - 2], 0
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
	; int16_t v1x,
	; int16_t v1y,
	; int16_t linedx, 
	; int16_t linedy);

; DX:AX     x
; CX:BX     y
; bp + 4    v1x
; bp + 6    v1y
; bp + 8    linedx
; bp + 0Ah  linedy

; todo consider si:di params for linedx/linedy?
 
; CALLING NOTE: this does not ret 8. it is often called twice in a row
; with the same stack params, so in order to not have to push twice, we
; just ret. this means the caller may sometimes have to manually add 8 to sp,
; especially if the caller lacks its own stack frame

PROC P_PointOnLineSide_ NEAR
PUBLIC P_PointOnLineSide_ 

push  bp		; bp + 2?
mov   bp, sp

cmp   word ptr [bp + 8], 0	; compare linedx

;    if (!linedx) {
jne   linedx_nonzero
;		if (x <= temp.w) {
cmp   dx, word ptr [bp + 4]			; compare hi bits to linedx
jl    x_smaller_than_v1x
jne   x_greater_than_v1x
test  ax, ax
jbe   x_smaller_than_v1x
x_greater_than_v1x:
cmp   word ptr [bp + 0Ah], 0
jl    return_1_pointonlineside
return_0_pointonlineside:
xor   ax, ax	; zero
exit_pointonlineside:
LEAVE_MACRO
ret

x_smaller_than_v1x:
cmp   word ptr [bp + 0Ah], 0	; compare linedy
jle   return_0_pointonlineside

return_1_pointonlineside:
mov   al, 1
LEAVE_MACRO
ret

linedx_nonzero:

cmp   word ptr [bp + 0Ah], 0	; compare linedy
jne   linedy_nonzero
cmp   cx, word ptr [bp + 6]	; v1y
jl    y_smaller_than_v1y
jne   y_greater_than_v1y
test  bx, bx
jbe   y_smaller_than_v1y
y_greater_than_v1y:
cmp   word ptr [bp + 8], 0		; compare linedx
jle   return_0_pointonlineside
mov   al, 1
LEAVE_MACRO
ret

y_smaller_than_v1y:
cmp   word ptr [bp + 8], 0
jge   return_0_pointonlineside
mov   al, 1
LEAVE_MACRO
ret

linedy_nonzero:


;	temp.h.intbits = v1x;
;   dx = (x - temp.w);
;	temp.h.intbits = v1y;
;   dy = (y - temp.w);

push  di
push  si

sub   dx, word ptr [bp + 4]	; dx:ax = "dx"
sub   cx, word ptr [bp + 6]	; cx:bx = "dy"


;    left = FixedMul1632 ( linedy , dx );
;    right = FixedMul1632 ( linedx , dy);


mov   si, bx					; store dy low
mov   di, cx					; store dy hi	di:si = dy
mov   bx, ax					; cx:bx = dx
mov   cx, dx	

mov   ax, word ptr [bp + 0Ah]	; ax = lindedy

call  FixedMul1632_				; AX  *  CX:BX

;dx:ax = left

mov   bx, si
mov   cx, di
mov   di, ax
mov   si, dx
mov   ax, word ptr [bp + 8]		; get linedx

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
ret

return_1_pointonlineside_3:		; this one pops di
mov   al, 1
pop   di
LEAVE_MACRO
ret

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



push  bx
push  dx
push  si	; P_PointOnLineSide_ params call 1
push  cx


cmp   ax, ST_NEGATIVE_HIGH
je    negative_high_slopetype
; ST_POSITIVE_HIGH



les   bx, dword ptr ds:[_tmbbox + BOXTOP * 4]  ; sizeof fixed_t_union
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXLEFT * 4]
mov   dx, es

call  P_PointOnLineSide_ ; this does not remove arguments from the stack so we can call again with same stack params


xchg  ax, si   ; store p1

les   bx, dword ptr ds:[_tmbbox + BOXBOTTOM * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXRIGHT * 4]
mov   dx, es

call  P_PointOnLineSide_

add   sp, 8  ; no stack frame, just directly do this

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



call  P_PointOnLineSide_ ; this does not remove arguments from the stack so we can call again with same stack params


xchg  ax, si   ; store p1

les   bx, dword ptr ds:[_tmbbox + BOXBOTTOM * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXLEFT * 4]
mov   dx, es

call  P_PointOnLineSide_ 

add   sp, 8  ; no stack frame, just directly do this

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

; todo di as func?

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
mov   es, dx
push  bx   ; bp - 2


; todo move this after if/else?
xor   ax, ax
push  word ptr es:[si + 6]  ; bp - 4   line dy
push  ax					; bp - 6   0
push  word ptr es:[si + 4]  ; bp - 8   line dx
push  ax					; bp - 0Ah 0

les   bx, dword ptr es:[si]
mov   cx, es ; store si + 2 in cx for now
SHIFT_MACRO shl   bx 2

mov   dx, VERTEXES_SEGMENT
mov   es, dx

les   dx, dword ptr es:[bx]

push  es					; bp - 0Ch  vertex y
push  ax    				; bp - 0Eh
push  dx                    ; bp - 010h vertex x
push  ax    				; bp - 012h




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



push  word ptr [bp - 4]
push  word ptr [bp - 8]
push  es ;v1y
push  dx ;v1x
les   ax, dword ptr ds:[_trace+0]
mov   dx, es
les   bx, dword ptr ds:[_trace+4]
mov   cx, es

call  P_PointOnLineSide_ ; this does not remove arguments from the stack so we can call again with same stack params







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
call  P_PointOnLineSide_   ; note this does not remove the pushed stuff from the stack.
add   sp, 8  ; no stack frame, just directly do this. necessary because we use sp below..

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

;lea   ax, [bp - 012h]
mov    ax, sp

;    frac = P_InterceptVector (&dl);
call  P_InterceptVector_   ; todo worth having a 16 bit version considering all the fracbits are 0...?

test  dx, dx
jnge  exit_addlineintercepts_return_1


 
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
mov   ax, word ptr [bp - 2]
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
stosw     ; bp - 4 (zero)
xchg  ax, bx
stosw     ; bp - 2 (2xradius or negative)

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



; void __near P_TraverseIntercepts( traverser_t	func);
; NOTE: This is now jumped to instead of called. 
PROC P_TraverseIntercepts_ NEAR
PUBLIC P_TraverseIntercepts_ 

; [bp + 12] is traverser func


;	count = intercept_p - intercepts;

mov   ax, word ptr ds:[_intercept_p]
mov   bl, 7  ; sizeof intercept p
cwd   
div   bl
xor   ah, ah
mov   cx, ax
xor   si, si

mov   dx, INTERCEPTS_SEGMENT ; todo get rid of it?
mov   es, dx

loop_next_intercept:
dec   cx
cmp   cx, -1
je    exit_traverse_intercepts
; todo reverse order?


;		dist.w = MAXLONG;

mov   dx, 0FFFFh  ; MAXLONG
mov   ax, 07FFFh

xor   bx, bx
cmp   word ptr ds:[_intercept_p], 0
jbe   done_scanning_intercepts

;		for (scan = intercepts ; scan<intercept_p ; scan++) {

scan_next_intercept:
cmp   ax, word ptr es:[bx + 2]
jg    record_scan
jne   iterate_next_intercept
cmp   dx, word ptr es:[bx]
jbe   iterate_next_intercept
record_scan:
mov   si, bx			; si holds best
mov   dx, word ptr es:[bx]
mov   ax, word ptr es:[bx + 2]
iterate_next_intercept:
add   bx, 7
cmp   bx, word ptr ds:[_intercept_p]
jb    scan_next_intercept
done_scanning_intercepts:

cmp   ax, 1
jg    exit_traverse_intercepts
jne   do_func_call
test  dx, dx
jbe   do_func_call
exit_traverse_intercepts:
; same as the outer function...
LEAVE_MACRO
pop   di
pop   si
ret   0Ch


do_func_call:

;		if (!func(in)) {

mov   dx, INTERCEPTS_SEGMENT ; todo get rid of it?
mov   ax, si
push  es

call  word ptr [bp + 012h]  ; from outer function frame
test  al, al
je    exit_traverse_intercepts

pop   es

;		in->frac = MAXLONG;

mov   word ptr es:[si], 0FFFFh   ; MAX_LONG
mov   word ptr es:[si + 2], 07FFFh
jmp   loop_next_intercept

ENDP


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


; bp - 2    yt1
; bp - 4    xt1
; bp - 6    loop count
; bp - 8    yintercept hibits  (di is lobits)
; bp - 0Ah  xintercept hibits
; bp - 0Ch  xintercept lobits
; bp - 0Eh  yt2
; bp - 010h xt2
; bp - 012h y1mapblockshifted lo bits
; bp - 014h x1mapblockshifted lo bits

; bp - 016h x1 lobits
; bp - 018h x1 hibits
; bp - 01Ah y1 lobits
; bp - 01Ch y1 hibits



PROC P_PathTraverse_ NEAR
PUBLIC P_PathTraverse_ 

; todo!!   doublecheck this stuff from c. seems to not be compiled/optimized out.
;	if (x1.h.fracbits & MAPBLOCK1000_LOWBITMASK == 0) {


push  si
push  di
push  bp
mov   bp, sp
sub   sp, 014h


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

; push these values on stack
push  di
push  dx
push  bx
push  cx





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



mov   word ptr [bp - 014h], dx

;	xintercept = x1mapblockshifted;
mov   word ptr [bp - 0Ch], dx
mov   word ptr [bp - 0Ah], ax
; xt1
mov   word ptr [bp - 4], ax





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

mov   word ptr [bp - 2], ax   ; store yt1

mov   word ptr [bp - 012h], dx  ; store lobits
mov   di, dx
mov   word ptr [bp - 8], ax     ; store hibits

; todo store something in si?

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
cmp   dx, word ptr [bp - 4]   ; dx holds xt2

je    xt2_equals_xt1

; xt2 != xt1

;		ystep = FixedDiv(y2.w - y1.w, labs(x2.w - x1.w));

; todo: some y1/x1 fields should still be in registers?
les   ax, dword ptr [bp + 8]
mov   dx, es
sub   ax, word ptr [bp - 016h]
sbb   dx, word ptr [bp - 018h]

or    dx, dx
jge   skip_labs_4
neg   ax
adc   dx, 0
neg   dx
skip_labs_4:
; dx:ax has result for labs that needs to go into cx:bx
; but cx:bx has y1, which needs to be subbed from y2

les   si, dword ptr [bp + 0Ch]  ; y2 dword
sub   si, bx
xchg  ax, bx   ; bx gets labs result lo
xchg  ax, si   ; ax gets y2 - y1 lo

mov   si, es   ; y2 hi
sbb   si, cx   ; y2 - y1 hi
mov   cx, dx   ; cx gets labs result hi 
mov   dx, si   ; dx gets y2 - y1 hi

call  FixedDiv_


mov   word ptr cs:[SELFMODIFY_add_yintercept_lo+2], ax
mov   word ptr cs:[SELFMODIFY_add_yintercept_hi+5], dx

xchg  bx, ax  ; cx, bx store ystep.
mov   cx, dx
;		partial = x1mapblockshifted.h.fracbits;

mov   ax, word ptr [bp - 014h] ; get x1mapblockshifted..

mov   dx, word ptr [bp - 010h] ; todo maybe put these together..

;		if (xt2 > xt1) {

cmp   dx, word ptr [bp - 4]
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
cmp   ax, word ptr [bp - 2]
je    yt2_equals_yt1

;		xstep = FixedDiv(x2.w - x1.w, labs(y2.w - y1.w));

les   ax, dword ptr [bp + 0Ch]
mov   dx, es
sub   ax, word ptr [bp - 01Ah]
sbb   dx, word ptr [bp - 01Ch]

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
sub   ax, word ptr [bp - 016h]
sbb   dx, word ptr [bp - 018h]

call  FixedDiv_

mov   word ptr cs:[SELFMODIFY_add_xintercept_lo+3], ax
mov   word ptr cs:[SELFMODIFY_add_xintercept_hi+5], dx


; cx:bx gets xstep
xchg  ax, bx
mov   cx, dx

;		partial = y1mapblockshifted.h.fracbits;
mov   ax, word ptr [bp - 012h]

mov   dx, word ptr [bp - 0Eh]

;	if (yt2 > yt1) {
cmp   dx, word ptr [bp - 2]
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

mov   dx, 0C089h   ; 2 byte nop
mov   al, byte ptr [bp + 010h]
test  al, PT_ADDLINES

je    write_addlines_jump
mov   dx, ((SELFMODIFY_addlines_jump_TARGET - SELFMODIFY_addlines_jump_AFTER) SHL 8) + 0EBh
write_addlines_jump:
mov   word ptr cs:[SELFMODIFY_addlines_jump], dx

mov   dx, 0c089h   ; 2 byte nop
test  al, PT_ADDTHINGS
je    write_addthings_jump
mov   dx, ((SELFMODIFY_addthings_jump_TARGET - SELFMODIFY_addthings_jump_AFTER) SHL 8) + 0EBh
write_addthings_jump:
mov   word ptr cs:[SELFMODIFY_addthings_jump], dx




les   ax, dword ptr [bp - 010h]
mov   word ptr cs:[SELFMODIFY_yt2_check+2], es  ; bp - 0Eh
mov   word ptr cs:[SELFMODIFY_xt2_check+2], ax


les   ax, dword ptr [bp - 0Ah]
mov   word ptr cs:[SELFMODIFY_yintercept_intbits+2], es  ; bp - 8
mov   word ptr cs:[SELFMODIFY_xintercept_intbits+2], ax

les   cx, dword ptr [bp - 4]  ; xt1
mov   si, es
mov   byte ptr [bp - 6], 64     ; count


;	for (count = 0 ; count < 64 ; count++) {

loop_traverse_loop:
; todo selfmodify
;		if (flags & PT_ADDLINES) {
SELFMODIFY_addlines_jump:
jmp   SHORT do_addlines_check
SELFMODIFY_addlines_jump_AFTER:
addlines_fallthru:
SELFMODIFY_addthings_jump:
jmp   SHORT do_addthings_check
SELFMODIFY_addthings_jump_AFTER:
addthings_fallthru:
;		if (mapx == xt2 && mapy == yt2) {


SELFMODIFY_xt2_check:
cmp   cx, 01000h
jne   xt2yt2_not_equal
SELFMODIFY_yt2_check:
cmp   si, 01000h
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
dec   byte ptr [bp - 6]
jnz    loop_traverse_loop
traverse_loop_done:


; could just inline...
jmp  P_TraverseIntercepts_

exit_path_traverse:
LEAVE_MACRO
pop   di
pop   si
ret   0Ch

SELFMODIFY_addlines_jump_TARGET:
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
SELFMODIFY_addthings_jump_TARGET:
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


; boolean	__near PTR_UseTraverse (intercept_t __far* in) ;

PROC PTR_UseTraverse_ NEAR
PUBLIC PTR_UseTraverse_ 

; dx is fixed as intercepts segment. get rid of it?

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp

;	line_physics_t __far* line_physics = &lines_physics[in->d.linenum];

xchg  ax, si  ; ax gets intercept..
mov   es, dx
mov   bx, word ptr es:[si + 5]   ; in->d.linenum
mov   di, bx	; linenum


;	if (!line_physics->special) {


mov   cx, LINES_PHYSICS_SEGMENT
mov   es, cx
SHIFT_MACRO shl   bx 2
mov   si, bx
SHIFT_MACRO shl   bx 2
cmp   byte ptr es:[bx + 0Fh], 0
jne   no_line_special

;		line_t __far* line = &lines[in->d.linenum];
;		P_LineOpening(line->sidenum[1], line_physics->frontsecnum, line_physics->backsecnum);

; get frontsecnum and backsecnum
les   dx, dword ptr es:[bx + 0Ah]  ; es:bx lines_physics
mov   bx, es
mov   ax, LINES_SEGMENT
mov   es, ax
mov   ax, word ptr es:[si + 2] ; sidenum[1] ; si preshifted 2
call  P_LineOpening_

; 		if (lineopening.opentop < lineopening.openbottom) {

mov   ax, word ptr ds:[_lineopening]
cmp   ax, word ptr ds:[_lineopening+2]
jl    use_thru_wall
; cant use thru wall
mov   al, 1
exit_usetraverse:
LEAVE_MACRO
pop   di
pop   si
pop   cx
pop   bx
ret   
use_thru_wall:

mov   ax, word ptr ds:[_playerMobj]
mov   dx, SFX_NOWAY
call  S_StartSound_
xor   al, al
jmp   exit_usetraverse
no_line_special:



; es:nbx lines_special
push  word ptr es:[bx + 6]
push  word ptr es:[bx + 4]

mov   bx, word ptr es:[bx]  ; get vertex
SHIFT_MACRO shl   bx 2

mov   ax, VERTEXES_SEGMENT
mov   es, ax
push  word ptr es:[bx+2]
push  word ptr es:[bx]

les   bx, dword ptr ds:[_playerMobj_pos]

;    side = 0;

xor   si, si		; side = 0
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
les   bx, dword ptr es:[bx + 4]
mov   cx, es

;	if (P_PointOnLineSide(playerMobj_pos->x.w, playerMobj_pos->y.w, line_physics->dx, line_physics->dy, vertexes[line_physics->v1Offset].x, vertexes[line_physics->v1Offset].y) == 1) {
;		side = 1;
;	}

call  P_PointOnLineSide_

cmp   al, 1
jne   use_side_0
inc   si		; si = 1
use_side_0:
mov   cx, word ptr ds:[_playerMobjRef]
mov   ax, word ptr ds:[_playerMobj]
mov   bx, si
mov   dx, di	; linenum
call  P_UseSpecialLine_
xor   al, al
LEAVE_MACRO
pop   di
pop   si
pop   cx
pop   bx
ret   

ENDP


;boolean __near PTR_SlideTraverse (intercept_t __far* in) {

PROC PTR_SlideTraverse_ NEAR
PUBLIC PTR_SlideTraverse_ 

push  bx
push  cx
push  si
push  di
xchg  ax, si   ; intercept to si



mov   es, dx   ; intercept segment

mov   bx, word ptr es:[si + 5] ; get linenum
mov   ax, LINEFLAGSLIST_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx]	; get lineflags in al

mov   dx, LINES_PHYSICS_SEGMENT
mov   di, bx
SHIFT_MACRO shl   di 2
SHIFT_MACRO shl   bx 4

;    if ( ! (lineflags & ML_TWOSIDED) ) {
mov   es, dx

test  al, ML_TWOSIDED
jne   not_twosided

push  word ptr es:[bx + 6]
push  word ptr es:[bx + 4]

mov   bx, word ptr es:[bx]
SHIFT_MACRO shl   bx 2

mov   ax, VERTEXES_SEGMENT
mov   es, ax

push  word ptr es:[bx+2]
push  word ptr es:[bx]

les   bx, dword ptr ds:[_playerMobj_pos]
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
les   bx, dword ptr es:[bx + 4]
mov   cx, es
call  P_PointOnLineSide_
add   sp, 8  ; no stack frame, just directly do this

test  al, al
je   is_blocking
exit_slidetraverse_return_1:
mov   al, 1
pop   di
pop   si
pop   cx
pop   bx
ret   


not_twosided:

;	P_LineOpening (li->sidenum[1], li_physics->frontsecnum, li_physics->backsecnum);

les   dx, dword ptr es:[bx + 0Ah]
mov   bx, es
mov   ax, LINES_SEGMENT
mov   es, ax
mov   ax, word ptr es:[di + 2]

call  P_LineOpening_

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, (lineopening.opentop - lineopening.openbottom));

mov   bx, word ptr ds:[_playerMobj]
mov   ax, word ptr ds:[_lineopening+0]
sub   ax, word ptr ds:[_lineopening+2]

SHIFT_MACRO sar   ax 3
cmp   ax, word ptr [bx + 0Ch]
jl    is_blocking

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.openbottom);
;    if (temp.w - playerMobj_pos->z.w > 24*FRACUNIT )
;		goto isblocking;		// too big a step up


xor       ax, ax
mov       dx, word ptr [_lineopening+0]
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1

les   di, dword ptr ds:[_playerMobj_pos]

;    if (temp.h.intbits < playerMobj->height.h.intbits) // 16 bit okay

sub   ax, word ptr es:[di + 8]		; subtract height
sbb   dx, word ptr es:[di + 0Ah]	; subtract height
cmp   dx, word ptr [bx + 0Ch]
jge   continue_blocking_check
is_blocking:

 ;   if (in->frac < bestslidefrac.w) {
;		bestslidefrac.w = in->frac;
;		bestslidelinenum = in->d.linenum;
;    }


mov   ax, INTERCEPTS_SEGMENT
mov   es, ax
mov   cx, word ptr  es:[si + 5]
les   dx, dword ptr es:[si + 0]
mov   ax, es
cmp   ax, word ptr ds:[_bestslidefrac+2]
jl    record_bestslide
jne   exit_slidetraverse_return_0
cmp   dx, word ptr ds:[_bestslidefrac+0]
jae   exit_slidetraverse_return_0
record_bestslide:
mov   word ptr ds:[_bestslidefrac+2], ax
mov   word ptr ds:[_bestslidefrac+0], dx
mov   word ptr ds:[_bestslidelinenum], cx
exit_slidetraverse_return_0:
xor   al, al
pop   di
pop   si
pop   cx
pop   bx
ret   
continue_blocking_check:

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, lineopening.openbottom);
;    if (temp.w - playerMobj_pos->z.w > 24*FRACUNIT )
;		goto isblocking;		// too big a step up


jne   continue_blocking_check_2
cmp   ax, word ptr [bx + 0Ah]
jb    is_blocking
continue_blocking_check_2:


xor       cx, cx
mov       ax, word ptr [_lineopening+2]
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1



sub   cx, word ptr es:[di + 8]
sbb   ax, word ptr es:[di + 0Ah]
cmp   ax, 24    ; too big a step up
jg    is_blocking
jne   exit_slidetraverse_return_2
test  cx, cx
ja    is_blocking		; jcxnz
exit_slidetraverse_return_2:
mov   al, 1

pop   di
pop   si
pop   cx
pop   bx
ret   

ENDP


; boolean __near P_TryMove (mobj_t __near* thing, mobj_pos_t __far* thing_pos, fixed_t_union	x, fixed_t_union	y );

; ax thing ptr
; cx:bx thingpos

PROC P_TryMove_ NEAR
PUBLIC P_TryMove_ 

; bp - 2	  thing_pos hi (segment)
; bp - 3      side
; bp - 4      linespecial


; bp + 0Ah   ; x lo
; bp + 0Ch   ; x hi
; bp + 0Eh   ; y lo
; bp + 010h  ; y hi



push  dx
push  si
push  di

push  bp
mov   bp, sp

push  cx ; bp - 2



mov   si, ax;  ; si gets thing ptr. dont xchg, ax is needed below
mov   di, bx   ; di gets thingpos offset
sub   sp, 2


;	if (!P_CheckPosition(thing, x, y, -1)) {
;		return false;		// solid wall or thing
;	}


push  word ptr [bp + 010h]
push  word ptr [bp + 0Eh]

mov   byte ptr ds:[_floatok], 0
les   bx, dword ptr [bp + 0Ah]
mov   cx, es
mov   dx, -1
call  P_CheckPosition_
test  al, al
je    exit_trymove_return


;    if ( !(thing_pos->flags1 & MF_NOCLIP) ) {


mov   es, word ptr [bp - 2]  ; thispos
mov   dl, byte ptr es:[di + 015h]  ; flags
test  dl, (MF_NOCLIP SHR 8)
jne   move_ok_do_unset_position

;		if (temp.h.intbits < thing->height.h.intbits) { // 16 bit logic handles the fractional fine
;			return false;	// doesn't fit
;		}

mov   ax, word ptr ds:[_tmceilingz]
sub   ax, word ptr ds:[_tmfloorz]
SHIFT_MACRO sar   ax 3
cmp   ax, word ptr [si + 0Ch]
jnge  exit_trymove_return0

;		floatok = true;

inc   byte ptr ds:[_floatok]

;		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, tmceilingz);
;		if (!(thing_pos->flags1&MF_TELEPORT) && temp.w - thing_pos->z.w < thing->height.w) {
;			return false;	// mobj must lower itself to fit
;		}


test  dl, (MF_TELEPORT SHR 8)     ; check both of these teleport flags once. 
jne   skip_checks_for_teleport

mov   ax, word ptr ds:[_tmceilingz]
xor   cx, cx
sar   ax, 1
rcr   cx, 1
sar   ax, 1
rcr   cx, 1
sar   ax, 1
rcr   cx, 1

sub   cx, word ptr es:[di + 8]
sbb   ax, word ptr es:[di + 0Ah]

cmp   ax, word ptr [si + 0Ch]
jl    exit_trymove_return0
jne   mobj_top_ok
cmp   cx, word ptr [si + 0Ah]
jb    exit_trymove_return0  ; mobj must lower itself to fit
mobj_top_ok:


mov   ax, word ptr ds:[_tmfloorz]
xor   cx, cx
sar   ax, 1
rcr   cx, 1
sar   ax, 1
rcr   cx, 1
sar   ax, 1
rcr   cx, 1


sub   cx, word ptr es:[di + 8]
sbb   ax, word ptr es:[di + 0Ah]
cmp   ax, 24
jg    exit_trymove_return0
jne   mobj_bot_ok
test  cx, cx
jbe   mobj_bot_ok
exit_trymove_return0:
xor   al, al
exit_trymove_return:
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   8

mobj_bot_ok:
skip_checks_for_teleport:

test  dl, ((MF_DROPOFF + MF_FLOAT) SHR 8)
jne   move_ok_do_unset_position
mov   ax, word ptr ds:[_tmfloorz]
sub   ax, word ptr ds:[_tmdropoffz]
cmp   ax, 0C0h  ; (24<<SHORTFLOORBITS)
jg    exit_trymove_return0

move_ok_do_unset_position:

; si is thing ptr
; di is thing segment
mov   ax, si
mov   dx, di
call  P_UnsetThingPosition_

; TODO push these?

;   oldx = thing_pos->x;
;   oldy = thing_pos->y;

;   thing->floorz = tmfloorz;
;   thing->ceilingz = tmceilingz;	

mov   ax, word ptr ds:[_tmfloorz]
mov   word ptr [si + 6], ax
mov   ax, word ptr ds:[_tmceilingz]
mov   word ptr [si + 8], ax

; selfmodify oldx/oldx as immediates in loop

mov   es, word ptr [bp - 2] 
mov   ax, es
mov   ds, ax  

xchg  si, di
lodsw 
mov   word ptr cs:[SELFMODIFY_set_oldx_lo + 1], ax
lodsw
mov   word ptr cs:[SELFMODIFY_set_oldx_hi + 1], ax
lodsw
mov   word ptr cs:[SELFMODIFY_set_oldy_lo + 1], ax
lodsw
mov   word ptr cs:[SELFMODIFY_set_oldy_hi + 1], ax

sub   si, 8
xchg  si, di


;	thing_pos->x = x;
;	thing_pos->y = y;


lds   ax, dword ptr [bp + 0Ah]
stosw
mov   ax, ds
stosw
lds   ax, dword ptr [bp + 0Eh]
stosw
mov   ax, ds
stosw

sub   di, 8

mov   ax, ss
mov   ds, ax   ; restore ds

;	// we calculated the sector above in checkposition, now it's cached.
;	P_SetThingPosition (thing, FP_OFF(thing_pos), lastcalculatedsector);


mov   dx, di  ; thingpos
mov   ax, si  ; thing ptr
mov   bx, word ptr ds:[_lastcalculatedsector]

call  P_SetThingPosition_

; selfmodify newx/newy as immediates in loop

mov   ds, word ptr [bp - 2]  ; thingpos

mov   bx, si  ; backup si
mov   si, di
lodsw 
mov   word ptr cs:[SELFMODIFY_set_newx_lo + 1], ax
lodsw
mov   word ptr cs:[SELFMODIFY_set_newx_hi + 1], ax
lodsw
mov   word ptr cs:[SELFMODIFY_set_newy_lo + 1], ax
lodsw
mov   word ptr cs:[SELFMODIFY_set_newy_hi + 1], ax


;    if (! (thing_pos->flags1&(MF_TELEPORT|MF_NOCLIP)) ) {

test  byte ptr ds:[di + 015h], ((MF_TELEPORT+MF_NOCLIP) SHR 8)
mov   ax, ss
mov   ds, ax   ; restore ds
mov   si, bx
je    loop_next_num_spec
exit_trymove_return1:
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   8

loop_next_num_spec:
dec   word ptr ds:[_numspechit]
; todo jump direct
js    exit_trymove_return1   ; jump if negative 1

;			ld_physics = &lines_physics[spechit[numspechit]];
;			lddx = ld_physics->dx;
;			lddy = ld_physics->dy;
;			ldv1Offset = ld_physics->v1Offset;
;			v1x = vertexes[ldv1Offset].x;
;			v1y = vertexes[ldv1Offset].y;
;			ldspecial = ld_physics->special;

mov   bx, word ptr ds:[_numspechit]
sal   bx, 1
mov   bx, word ptr ds:[bx + _spechit]
mov   dx, LINES_PHYSICS_SEGMENT
mov   es, dx
SHIFT_MACRO shl   bx 4

mov   al, byte ptr es:[bx + 0Fh]
mov   byte ptr [bp - 4], al    ; ld->special   

push  word ptr es:[bx + 6] 
push  word ptr es:[bx + 4] 

mov   bx, word ptr es:[bx] ; vertexes
SHIFT_MACRO shl   bx 2
mov   ax, VERTEXES_SEGMENT
mov   es, ax

push  word ptr es:[bx+2]
push  word ptr es:[bx]



;			side = P_PointOnLineSide (newx.w, newy.w, lddx, lddy, v1x, v1y);




SELFMODIFY_set_newy_hi:
mov   cx, 01000h
SELFMODIFY_set_newy_lo:
mov   bx, 01000h
SELFMODIFY_set_newx_hi:
mov   dx, 01000h
SELFMODIFY_set_newx_lo:
mov   ax, 01000h


call  P_PointOnLineSide_ ; this does not remove arguments from the stack so we can call again with same stack params


;			oldside = P_PointOnLineSide (oldx.w, oldy.w, lddx, lddy, v1x, v1y);

mov   byte ptr [bp - 3], al	; store side


SELFMODIFY_set_oldy_hi:
mov   cx, 01000h
SELFMODIFY_set_oldy_lo:
mov   bx, 01000h
SELFMODIFY_set_oldx_hi:
mov   dx, 01000h
SELFMODIFY_set_oldx_lo:
mov   ax, 01000h

call  P_PointOnLineSide_
add   sp, 8  ; no stack frame, just directly do this. needed because this is a loop..

; todo test cbw and test a word

cmp   al, byte ptr [bp - 3]  ; return 
je   loop_next_num_spec		; todo je

;				if (ldspecial) {
cmp   word ptr [bp - 4], 0
je    loop_next_num_spec		; todo direct

;	P_CrossSpecialLine(spechit[numspechit], oldside, thing, thing_pos);

push  word ptr [bp - 2]     ; thing segment. could just do immediate?
push  di    				; thing pos
mov   bx, word ptr ds:[_numspechit]
sal   bx, 1
cbw	  ; fill out ah from before
mov   dx, ax
mov   ax, word ptr ds:[bx + _spechit]
mov   bx, si
call  P_CrossSpecialLine_
jmp   loop_next_num_spec

ENDP

; boolean __near DoBlockmapLoop(int16_t xl, int16_t yl, int16_t xh, int16_t yh, boolean __near(*   func )(THINKERREF, mobj_t __near*, mobj_pos_t __far*) , int8_t returnOnFalse);

; NOTE: tried selfmodifies here, but i think it is possible
; to recursively call this via the func passed in.
PROC DoBlockmapLoop_ NEAR
PUBLIC DoBlockmapLoop_

; xl   ax
; yl   dx
; xh   bx
; xl   cx
; func si
; returnonfalse di



;	if (xh >= bmapwidth) {
;		xh = bmapwidth - 1;
;	}
;	if (yh >= bmapheight) {
;		yh = bmapheight - 1;
;	}

cmp   bx, word ptr ds:[_bmapwidth]
jnge  dont_cap_xh
mov   bx, word ptr ds:[_bmapwidth]
dec   bx
dont_cap_xh:

cmp   cx, word ptr ds:[_bmapheight]
jnge  dont_cap_yh
mov   cx, word ptr ds:[_bmapheight]
dec   cx
dont_cap_yh:

; bx/cx now free..




;	if (xl < 0) {
;		xl = 0;
;	}
;	if (yl < 0) {
;		yl = 0;
 


test  dx, dx
jnl   dont_set_yl_0
xor   dx, dx		; cwd probably fine
dont_set_yl_0:

; si gets DX by default from this self-modified move above



test  ax, ax
jnl   dont_set_xl_0
xor   ax, ax
dont_set_xl_0:


cmp   ax, bx
jg	  exit_doblockmaploop_return_0
cmp   dx, cx
jg	  exit_doblockmaploop_return_0

; loop setup...

push  bp
mov   bp, sp

push   dx  ; bp - 2
push   si  ; bp - 4
push   bx  ; bp - 6
push   cx  ; bp - 8


mov   cx, di  ; cx (cl) gets the boolean
dec   cx  ; if it was 1, now its 0.

;for (; xl <= xh; xl++) {
;		for (by = yl; by <= yh; by++) {
;			if (!P_BlockThingsIterator(xl, by, func)) {
;				if (returnOnFalse)
;					return false;
;			}
;		}
;	}


do_first_blockmaploop:

mov   di, ax  ; backup ax in di for inner loop duration

mov   si, [bp - 2]  ; by = yl
do_second_blockmaploop:

; ax already xl
mov   bx, [bp - 4]
mov   dx, si       ; set dx as by
call  P_BlockThingsIterator_

or    al, cl ; if al and cl are zero (returnOnFalse true after dec DI) and AX is 0 then jump and exit
je    exit_doblockmaploop_return_0_thru

mov   ax, di  ; retrieve ax

inc   si

cmp   si, [bp - 8]
jle   do_second_blockmaploop

finish_blockmap_inner_loop_iter:
inc   ax

cmp    ax, [bp - 6]
jle   do_first_blockmaploop


exit_doblockmaploop_return_1:
mov  al, 1
exit_doblockmaploop_return_0_thru:
LEAVE_MACRO
ret   
exit_doblockmaploop_return_0:
xor  al, al  ; no stack frame cleanup!
ret   

ENDP




; void __near P_HitSlideLine (int16_t linenum);

zero_tmx_and_exit:
xor   ah, ah
mov   word ptr ds:[_tmxmove+0], ax
mov   word ptr ds:[_tmxmove+2], ax
exit_hitslideline:
POPA_NO_AX_MACRO
ret   
zero_tmy_and_exit:
mov   word ptr ds:[_tmymove+0], ax
mov   word ptr ds:[_tmymove+2], ax
jmp   exit_hitslideline

PROC P_HitSlideLine_ NEAR
PUBLIC P_HitSlideLine_ 

PUSHA_NO_AX_MACRO


SHIFT_MACRO shl   ax 4
xchg  ax, si  ; si gets linenum linephysics lookup
mov   di, LINES_PHYSICS_SEGMENT
mov   es, di



;    if ((ld_physics->v2Offset&LINE_VERTEX_SLOPETYPE) == ST_HORIZONTAL_HIGH) {
;		tmymove.w = 0;
;		return;
;    }
    
xor   ax, ax
test  byte ptr es:[si + 3], (LINE_VERTEX_SLOPETYPE SHR 8)
je    zero_tmy_and_exit
mov   ax, word ptr es:[si + 2]
xor   al, al
and   ah, (LINE_VERTEX_SLOPETYPE SHR 8)

;    if ((ld_physics->v2Offset&LINE_VERTEX_SLOPETYPE) == ST_VERTICAL_HIGH) {
;		tmxmove.w = 0;
;		return;
;    }


cmp   ax, ST_VERTICAL_HIGH
je    zero_tmx_and_exit



;    side = P_PointOnLineSide (playerMobj_pos->x.w, playerMobj_pos->y.w, vertexes[ld_physics->v1Offset].x, vertexes[ld_physics->v1Offset].y, ld_physics->dx, ld_physics->dy);

push  word ptr es:[si + 6]
push  word ptr es:[si + 4]

mov   bx, word ptr es:[si] ; get vertex
SHIFT_MACRO shl   bx 2

mov   ax, VERTEXES_SEGMENT
mov   es, ax

push  word ptr es:[bx+2] ; push vertices
push  word ptr es:[bx]
les   bx, dword ptr ds:[_playerMobj_pos]
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx+2]
les   bx, dword ptr es:[bx + 4]
mov   cx, es
call  P_PointOnLineSide_

add   sp, 8  ; no stack frame, just directly do this

xchg  ax, bx	; bx gets side
mov   es, di   ; lines_physics
les   ax, dword ptr es:[si + 4]
mov   dx, es
call  R_PointToAngle2_16_

;    if (side == 1)
;		lineangle.hu.intbits += ANG180_HIGHBITS;


mov   si, ax
cmp   bl, 1
jne   dont_add_hibits
add   dh, (ANG180_HIGHBITS SHR 8)
dont_add_hibits:

mov   di, dx
push  word ptr ds:[_tmymove+2]
push  word ptr ds:[_tmymove+0]
push  word ptr ds:[_tmxmove+2]
push  word ptr ds:[_tmxmove+0]
xor   ax, ax
cwd
mov   bx, ax
mov   cx, ax
call  R_PointToAngle2_  ; todo this is a weird function call. 
sub   ax, si
sbb   dx, di
cmp   dx, ANG180_HIGHBITS
ja    add_hibits
jne   dont_add_hibits_2
test  ax, ax
jbe   dont_add_hibits_2
add_hibits:
add   dh, (ANG180_HIGHBITS SHR 8)

dont_add_hibits_2:

;    lineangle.hu.intbits = (lineangle.hu.intbits >> 1) & 0xFFFC;
;    deltaangle.hu.intbits = (deltaangle.hu.intbits >> 1) & 0xFFFC;

shr   di, 1
and   di, 0FFFCh ; line hubits

shr   dx, 1
and   dl, 0FCh   ; delta hubits
mov   si, dx     ; in si

;    movelen = P_AproxDistance (tmxmove.w, tmymove.w);

les   bx, dword ptr ds:[_tmymove+0]
mov   cx, es
les   ax, dword ptr ds:[_tmxmove+0]
mov   dx, es
call  P_AproxDistance_

;    newlen = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, deltaangle.hu.intbits, movelen);


mov   bx, ax
mov   cx, dx

mov   dx, si     ; si is now free
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigNoShift_


;    tmxmove.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, lineangle.hu.intbits, newlen);
;    tmymove.w = FixedMulTrigNoShift(FINE_SINE_ARGUMENT, lineangle.hu.intbits, newlen);


xchg  ax, si  	; back up dx:ax as di:si
xchg  dx, di	; dx also gets di (lineangle)
push  dx        ; need this once more

mov   bx, si
mov   cx, di
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigNoShift_
mov   word ptr ds:[_tmxmove+0], ax
mov   word ptr ds:[_tmxmove+2], dx
mov   bx, si
mov   cx, di
pop   dx
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigNoShift_
mov   word ptr ds:[_tmymove+0], ax
mov   word ptr ds:[_tmymove+2], dx
POPA_NO_AX_MACRO
ret   
ENDP

; todo constants.c
ML_BLOCKING = 1

; boolean __near PIT_CheckLine (line_physics_t __far* ld_physics, int16_t linenum) {

PROC PIT_CheckLine_ NEAR
PUBLIC PIT_CheckLine_

; dx:ax ld_physics
; bx: linenum  (SAME LINE, so shift 4?)

; bp - 2    ld_physics segment
; bp - 4    linenum
; bp - 6    lineslopetype 
; bp - 8    v1x?
; bp - 0Ah  linetop
; bp - 0Ch  lineleft
; bp - 0Eh  lineright
; bp - 010h v2x?

; bp - 012h lineside1

; bp - 014h frontsecnum
; bp - 016h backsecnum

push  cx
push  si
push  di
push  bp
mov   bp, sp
mov   di, ax
push  dx  ; bp - 2
push  bx  ; bp - 4

mov   es, dx
SHIFT_MACRO shl   bx 2		; lines lookup

mov   si, word ptr es:[di]   ; vertex
mov   ax, word ptr es:[di + 2]
xor   al, al					; todo just get byte?
and   ah, (LINE_VERTEX_SLOPETYPE SHR 8)

push  ax ; bp - 6  ; unused!

les   dx, dword ptr es:[di + 4]    ; dx
mov   cx, es                       ; dy

SHIFT_MACRO shl   si 2
mov   ax, VERTEXES_SEGMENT
mov   es, ax

les   si, dword ptr es:[si]

push  si ; bp - 8
push  es ; bp - 0Ah
push  si ; bp - 0Ch
push  si ; bp - 0Eh
push  es ; bp - 010h 

mov   si, es ; store v1y as linebot



mov   ax, LINES_SEGMENT
mov   es, ax
;	int16_t lineside1 = ld->sidenum[1];

mov   bx, word ptr es:[bx + 2]	; lineside1
push  bx ; bp - 012h


;	int16_t linefrontsecnum = ld_physics->frontsecnum;
;	int16_t linebacksecnum = ld_physics->backsecnum;

mov   es, word ptr [bp - 2]



push  word ptr es:[di + 0Ah]  ; frontsecnum bp - 014h
push  word ptr es:[di + 0Ch]  ; backsecnum  bp - 016h

; si is linebot
; ax is free
; bx is free
; dx is linedx
; cx is linedy

;	if (linedx > 0) {
;		lineright += linedx;
;	} else if (linedx < 0){
;		lineleft += linedx;
;	}

test  dx, dx
jg    add_to_lineright
jnl   done_adding_linedx
add   word ptr [bp - 0Ch], dx
jmp   done_adding_linedx
add_to_lineright:
add   word ptr [bp - 0Eh], dx
done_adding_linedx:

;	if (linedy > 0) {
;		linetop += linedy;
;	} else if (linedy < 0) {
;		linebot += linedy;
;	}


; si is linebot

test  cx, cx
jg    add_to_linetop
jnl   done_adding_linedy
add   si, cx
jmp   done_adding_linedy
add_to_linetop:
add   word ptr [bp - 0Ah], cx
done_adding_linedy:

;	if (tmbbox[BOXLEFT].h.intbits >= lineright || tmbbox[BOXBOTTOM].h.intbits >= linetop
;		|| ((tmbbox[BOXRIGHT].h.intbits < lineleft) || ((tmbbox[BOXRIGHT].h.intbits == lineleft   && tmbbox[BOXRIGHT].h.fracbits == 0)))
;		|| ((tmbbox[BOXTOP].h.intbits < linebot) || ((tmbbox[BOXTOP].h.intbits   == linebot) &&  tmbbox[BOXTOP].h.fracbits == 0))
;		) {
;		
; 		return true;
;	}

mov   ax, word ptr ds:[_tmbbox + (4 * BOXLEFT) + 2]
cmp   ax, word ptr [bp - 0Eh] ;lineright
jl    check_linetop
exit_checkline_return_1_2:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   

check_linetop:
mov   ax, word ptr ds:[_tmbbox + (4 * BOXBOTTOM) + 2]
cmp   ax, word ptr [bp - 0Ah] ; linetop
jge   exit_checkline_return_1_2
mov   ax, word ptr ds:[_tmbbox + (4 * BOXRIGHT) + 2]
cmp   ax, word ptr [bp - 0Ch] ; lineleft
jl    exit_checkline_return_1_2
jne   done_checking_left_lowbits
cmp   word ptr ds:[_tmbbox + (4 * BOXRIGHT) ], 0
je    exit_checkline_return_1_2
done_checking_left_lowbits:
cmp   si, word ptr ds:[_tmbbox + (4 * BOXTOP) + 2]
jg    exit_checkline_return_1_2
jne   not_in_box
cmp   word ptr ds:[_tmbbox + (4 * BOXTOP)], 0
je    exit_checkline_return_1_2 ;1ah bytes

not_in_box:
;    dx already linedx
mov   bx, cx  ; linedy i guess?
mov   si, word ptr [bp - 010h]
mov   cx, word ptr [bp - 8]
mov   ax, word ptr [bp - 6]  ; slopetype
call  P_BoxOnLineSide_
cmp   al, -1
jne   exit_checkline_return_1_2 ; 8 bytes

;	if (ld_physics->backsecnum == SECNUM_NULL) {
;		return false;		// one sided line
;	}


mov   es, word ptr [bp - 2]
cmp   word ptr es:[di + 0Ch], SECNUM_NULL
jne   sector_not_null  ; 7 bytes

exit_checkline_return_0:
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   
sector_not_null:

;    if (!(tmthing_pos->flags2 & MF_MISSILE) ) {

mov   ax, LINEFLAGSLIST_SEGMENT
mov   es, ax
mov   bx, word ptr [bp - 4]
mov   al, byte ptr es:[bx]
les   bx, dword ptr ds:[_tmthing_pos]
test  byte ptr es:[bx + 016h], MF_MISSILE
jne   skip_blocking

;		if (flags & ML_BLOCKING) {
;			return false;	// explicitly blocking everything
;		}

test  al, ML_BLOCKING
jne   exit_checkline_return_0

;		if (tmthing->type != MT_PLAYER && flags & ML_BLOCKMONSTERS) {
;			return false;	// block monsters only
;		}

mov   bx, word ptr ds:[_tmthing]
cmp   byte ptr ds:[bx + 01Ah], MT_PLAYER
je    skip_blocking
test  al, ML_BLOCKMONSTERS
jne   exit_checkline_return_0
skip_blocking:

mov   bx, word ptr [bp - 016h] ; backsecnum
mov   dx, word ptr [bp - 014h] ; frontsecnum
mov   ax, word ptr [bp - 012h] ; lineside1
call  P_LineOpening_

;    // adjust floor / ceiling heights
;    if (lineopening.opentop < tmceilingz) {
;		tmceilingz = lineopening.opentop;
;		ceilinglinenum = linenum;
;    } 

mov   ax, word ptr ds:[_lineopening+0]
cmp   ax, word ptr ds:[_tmceilingz]

jge   dont_adjust_ceil
mov   bx, word ptr [bp - 4]
mov   word ptr ds:[_tmceilingz], ax
mov   word ptr ds:[_ceilinglinenum], bx
dont_adjust_ceil:

;	if (lineopening.openbottom > tmfloorz) {
;		tmfloorz = lineopening.openbottom;
;	}

mov   ax, word ptr ds:[_lineopening+2]
cmp   ax, word ptr ds:[_tmfloorz]
jle   dont_adjust_floor
mov   word ptr ds:[_tmfloorz], ax
dont_adjust_floor:

;	if (lineopening.lowfloor < tmdropoffz) {
;		tmdropoffz = lineopening.lowfloor;
;	}

mov   ax, word ptr ds:[_lineopening+4]
cmp   ax, word ptr ds:[_tmdropoffz]
jge   dont_adjust_dropoff
mov   word ptr ds:[_tmdropoffz], ax
dont_adjust_dropoff:

;    if (ld_physics->special) {

mov   es, word ptr [bp - 2]
cmp   byte ptr es:[di + 0Fh], 0
je    exit_checkline_return_1
; adjust specials

;		spechit[numspechit] = linenum;
;		numspechit++;
mov   bx, word ptr ds:[_numspechit]
sal   bx, 1
mov   ax, word ptr [bp - 4]
inc   word ptr ds:[_numspechit]
mov   word ptr ds:[bx + _spechit], ax
exit_checkline_return_1:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   



ENDP


; boolean __near PIT_CheckThing (THINKERREF thingRef, mobj_t __near*	thing, mobj_pos_t __far* thing_pos);

; todo no stack frame or push pop di/si on this one
exit_checkthing_return_1:
mov   al, 1
ret   

; bp - 2      thing (bx param)

; bp - 4      thingz hi
; bp - 6      thingz lo
; bp - 8      thingy hi
; bp - 0Ah    thingy lo
; bp - 0Ch    thingx hi
; bp - 0Eh    thingx lo     ; do rep movsw for this area

; bp - 010h   thingheight hi
; bp - 012h   thingheight lo

; bp - 014h   thingtype
; bp - 016h   tmthingheight hi
; bp - 018h   tmthingheight lo
; bp - 01Ah   tmthingz lo
; bp - 01Ch   tmthingtargetRef
; bp - 01Eh   solid (pushed later)



PROC PIT_CheckThing_ NEAR
PUBLIC PIT_CheckThing_


;	if (thing == tmthing) {
;		return true;
;	}

cmp   dx, word ptr ds:[_tmthing]
je    exit_checkthing_return_1

;	thingflags1 = thing_pos->flags1;
;	if (!(thingflags1 & (MF_SOLID | MF_SPECIAL | MF_SHOOTABLE))) {
;			return true;
;	}
mov   es, cx

test  byte ptr es:[bx + 014h], (MF_SOLID OR MF_SPECIAL OR MF_SHOOTABLE)
je    exit_checkthing_return_1

; NOW do stack frame.
push  si
push  di
push  bp
mov   bp, sp




; todo investigate not doing this..
;	thingtype = thing->type;
;	thingx = thing_pos->x;
;	thingy = thing_pos->y;
;	thingz = thing_pos->z;
;	thingheight = thing->height;


push  bx  				   ; bp - 2
sub   sp, 0Ch  ; create stack room for rep movsw

lea   di, [bp - 0Eh]
mov   ax, ss
mov   es, ax

mov   ds, cx  
mov   si, bx

mov   cx, 6 
rep   movsw ; copy x y z dwords

mov   cx, word ptr ds:[bx + 014h]

mov   si, dx

mov   ax, ss
mov   ds, ax

push  word ptr [si + 0Ch]  ; bp - 010h
push  word ptr [si + 0Ah]  ; bp - 012h
push  word ptr [si + 01Ah] ; bp - 014h ; hi byte garbage.

mov   di, word ptr ds:[_tmthing]


;	thingradius.h.intbits = thing->radius;
;	thingradius.h.fracbits = 0;
;	thingradius.h.intbits += tmthing->radius;

mov   al, byte ptr [si + 01Eh]
mov   dl, byte ptr [di + 01Eh]
xor   ah, ah
xor   dh, dh
add   ax, dx
xchg  ax, di

; di =  sum of radii
;    if ( labs(thingx.w - tmx.w) >= blockdist.w || labs(thingy.w - tmy.w) >= blockdist.w ) {
;		// didn't hit it
;			return true;
;    }


les   ax, dword ptr [bp - 0Eh]
mov   dx, es
sub   ax, word ptr ds:[_tmx+0]
sbb   dx, word ptr ds:[_tmx+2]

jge   dont_neg_thing_x
neg   ax
adc   dx, 0
neg   dx
dont_neg_thing_x:

cmp   dx, di
jge   exit_checkthing_return_1_3
les   ax, dword ptr [bp - 0Ah]
mov   dx, es
sub   ax, word ptr ds:[_tmy+0]
sbb   dx, word ptr ds:[_tmy+2]

jge   dont_neg_thing_y
neg   ax
adc   dx, 0
neg   dx
dont_neg_thing_y:
cmp   dx, di
jge  exit_checkthing_return_1_3

;	tmthingheight = tmthing->height;
;	tmthingz = tmthing_pos->z;
;	tmthingtargetRef = tmthing->targetRef;

mov   di, word ptr ds:[_tmthing]
push  word ptr [di + 0Ch] ; bp - 016h
push  word ptr [di + 0Ah] ; bp - 018h

les   bx, dword ptr ds:[_tmthing_pos]
push  word ptr es:[bx + 8] ; bp - 01Ah

mov   ax, word ptr es:[bx + 0Ah]  ; store tmthingz hi in ax
push  word ptr [di + 022h] ; bp - 01Ch


test  byte ptr es:[bx + 017h], (MF_SKULLFLY SHR 8)
je    not_skullfly_collision

;    if (tmthing_pos->flags2 & MF_SKULLFLY) {

jmp   do_skull_fly_into_thing


not_skullfly_collision:

;    if (tmthing_pos->flags2 & MF_MISSILE) {

test  byte ptr es:[bx + 016h], MF_MISSILE  ;todo
jne   do_missile_collision

;    if (thingflags1 & MF_SPECIAL) {

test  cl, MF_SPECIAL
je    exit_checkthing_return_notsolid

;		solid = thingflags1 &MF_SOLID;

and   cl, MF_SOLID
push  cx

;		if (tmflags1&MF_PICKUP) {

test  byte ptr ds:[_tmflags1+1], (MF_PICKUP SHR 8)
je    dont_touch_anything

;			P_TouchSpecialThing (thing, tmthing, thing_pos, tmthing_pos);

push  es
push  bx
mov   bx, word ptr [bp - 2]
mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   dx, word ptr ds:[_tmthing]
xchg  ax, si   ; get si in ax
call  P_TouchSpecialThing_
dont_touch_anything:
cmp   byte ptr [bp - 01Eh], 0
jne   exit_checkthing_return_0_2

exit_checkthing_return_1_3:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
ret   

exit_checkthing_return_0_2:
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
ret   
exit_checkthing_return_notsolid:
test  cl, MF_SOLID
je    exit_checkthing_return_1_3
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
ret   



do_missile_collision:

;		// see if it went over / under
;		if (tmthingz.w > thingz.w + thingheight.w) {
;			return true;		// overhead
;		}

les   bx, dword ptr [bp - 6]
mov   dx, es
add   bx, word ptr [bp - 012h]
adc   dx, word ptr [bp - 010h]
cmp   ax, dx					; ax has tmthingz hi?
jg    exit_checkthing_return_1_3
jne   did_not_go_over
cmp   bx, word ptr [bp - 01Ah]
jb    exit_checkthing_return_1_3
did_not_go_over:

;  reuse tmthingz in ax

;		if (tmthingz.w + tmthingheight.w < thingz.w) {
;			return true;		// underneath
;		}

mov   dx, word ptr [bp - 01Ah]
add   dx, word ptr [bp - 018h]
adc   ax, word ptr [bp - 016h]
cmp   ax, word ptr [bp - 4]
jl    exit_checkthing_return_1_3
jne   did_not_go_under
cmp   dx, word ptr [bp - 6]
jb    exit_checkthing_return_1_3
did_not_go_under:

; tmthingtarget


;		if (tmthingTarget) {

mov   ax, word ptr [bp - 01Ch]
test  ax, ax  ; NULL_THINKERREF check
je    good_missile_target  

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
	imul  bx, ax, SIZEOF_THINKER_T
add   bx, (_thinkerlist + 4)
ELSE
	mov   bx, SIZEOF_THINKER_T
	mul   bx
	add   ax, (_thinkerlist + 4)
	xchg  ax, bx
ENDIF

mov   al, byte ptr [bx + 01Ah]
mov   ah, byte ptr [bp - 014h]    ; get thingtype in ah
cmp   al, ah
je    dont_damage_target

; do_bruiser_knight_check
;			if (tmthingTargettype == thingtype || (tmthingTargettype == MT_KNIGHT && thingtype == MT_BRUISER)|| (tmthingTargettype == MT_BRUISER && thingtype == MT_KNIGHT) ) {

cmp   ax, MT_KNIGHT + (MT_BRUISER SHL 8)
je    dont_damage_target
cmp   ax, MT_BRUISER + (MT_KNIGHT SHL 8)
jne   good_missile_target

dont_damage_target:
cmp   si, bx
je    exit_checkthing_return_1_3

cmp   ah, MT_PLAYER
jne   exit_checkthing_return_0
good_missile_target:
test  cl, MF_SHOOTABLE
jne   do_missile_damage
test  cl, MF_SOLID
jne   exit_checkthing_return_0
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
ret   

;		damage = ((P_Random()%8)+1)*getDamage(tmthing->type);
do_skull_fly_into_thing:

;		damage = ((P_Random()%8)+1)*getDamage(tmthing->type);

call  P_Random_
and   ax, 7
inc   ax
xchg  ax, cx  ; store random in cl
mov   bx, word ptr ds:[_tmthing]
mov   al, byte ptr [bx + 01Ah]

db    09Ah
dw    GETDAMAGEADDR, INFOFUNCLOADSEGMENT

;		P_DamageMobj (thing, tmthing, tmthing, damage);

mul   cl ; this will fill up the queue so use mov not xchg

mov   dx, bx   ; tmthing
mov   cx, ax   ; cx gets mul result
mov   ax, si
call  P_DamageMobj_

;		tmthing_pos->flags2 &= ~MF_SKULLFLY;

les   bx, dword ptr ds:[_tmthing_pos]
and   byte ptr es:[bx + 017h], ((NOT MF_SKULLFLY) SHR 8)  ; 0FEh
mov   bx, word ptr ds:[_tmthing]
lea   di, [bx + 0Eh]
;		tmthing->momx.w = tmthing->momy.w = tmthing->momz.w = 0;
mov   cx, 6
mov   ax, ds
mov   es, ax
xor   ax, ax
rep   stosw
;mov   word ptr [bx + 018h], ax
;mov   word ptr [bx + 016h], ax
;mov   word ptr [bx + 014h], ax
;mov   word ptr [bx + 012h], ax
;mov   word ptr [bx + 010h], ax
;mov   word ptr [bx + 0Eh], ax

mov   al, byte ptr [di]  ; bx + 01Ah
mov   dl, SIZEOF_MOBJINFO_T
mul   dl

;		P_SetMobjState (tmthing, mobjinfo[tmthing->type].spawnstate);


xchg  ax, bx   ; ax gets tmthing from above, bx gets mobjinfo ptr
mov   dx, word ptr ds:[bx + _mobjinfo]
call  P_SetMobjState_
exit_checkthing_return_0:
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
ret   


do_missile_damage:

; bx is tmthingtarget
;		damage = ((P_Random()%8)+1)*getDamage(tmthing->type);

call  P_Random_
and   ax, 7
inc   ax
xchg  ax, cx  ; store random in cl. keep ah 0
mov   di, word ptr ds:[_tmthing]
mov   al, byte ptr [di + 01Ah]


db    09Ah
dw    GETDAMAGEADDR, INFOFUNCLOADSEGMENT

mul   cl ; this will fill up the queue so use mov not xchg

;		P_DamageMobj (thing, tmthing, tmthingTarget, damage);

mov   cx, ax   ; cx gets mul result
mov   dx, di   ; tmthing
mov   ax, si   ; ax gets thing ptr   
call  P_DamageMobj_
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
ret   


ENDP


; boolean __near P_CheckPosition (mobj_t __near* thing, int16_t oldsecnum, fixed_t_union	x, fixed_t_union	y );

PROC P_CheckPosition_ NEAR
PUBLIC P_CheckPosition_

; - bp - 2   xl2
; - bp - 4   yh2
; - bp - 6   yl2
; - bp - 8   xh2
; - bp - 0Ah x lowbits (bx)   (di is hibits)
; - bp - 0Eh x oldsecnum (dx)

;   y hi ; + 0Ah
;   y lo ; + 8
;     ip ; + 6      
push  si ; + 4
push  di ; + 2
push  bp ; + 0
mov   bp, sp
sub   sp, 0Ch
push  dx  ; bp - 0Eh
mov   si, ax ; thing ptr
mov   word ptr [bp - 0Ah], bx
mov   di, cx
mov   cx, word ptr [bp + 8]
mov   bx, SIZEOF_THINKER_T
mov   word ptr ds:[_tmthing], ax
sub   ax, (_thinkerlist + 4)
xor   dx, dx  ; cwd seems bad??? are we passing in -1?
div   bx
imul  bx, ax, SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   word ptr ds:[_tmthing_pos+0], bx
mov   word ptr ds:[_tmthing_pos+2], ax  ;todo remove once fixed?
mov   es, ax
mov   ax, word ptr es:[bx + 014h]

mov   word ptr ds:[_tmflags1], ax
mov   ax, word ptr [bp - 0Ah]
mov   word ptr ds:[_tmbbox + (4 * BOXTOP)], cx
mov   word ptr ds:[_tmx+0], ax
mov   ax, word ptr [bp + 0Ah]
mov   word ptr ds:[_tmbbox + (4 * BOXTOP) + 2], ax
mov   word ptr ds:[_tmy+2], ax
mov   al, byte ptr [si + 01Eh]
xor   ah, ah
add   word ptr ds:[_tmbbox + (4 * BOXTOP) + 2], ax
mov   al, byte ptr [si + 01Eh]
mov   dx, ax
mov   ax, cx
sub   ax, 0
mov   bx, word ptr [bp + 0Ah]
sbb   bx, dx
mov   word ptr [bp - 0Ch], bx

mov   word ptr ds:[_tmbbox + (4 * BOXBOTTOM)], ax
mov   ax, word ptr [bp - 0Ch]
mov   word ptr ds:[_tmbbox + (4 * BOXBOTTOM)+ 2], ax
mov   ax, word ptr [bp - 0Ah]
mov   word ptr ds:[_tmbbox + (4 * BOXRIGHT)], ax
mov   word ptr ds:[_tmbbox + (4 * BOXRIGHT) + 2], di
mov   word ptr ds:[_tmx+2], di
mov   al, byte ptr [si + 01Eh]
xor   ah, ah
mov   si, word ptr [bp - 0Ah]
add   word ptr ds:[_tmbbox + (4 * BOXRIGHT) + 2], ax
sub   si, 0
mov   ax, di
sbb   ax, dx
mov   word ptr ds:[_tmy+0], cx
mov   word ptr ds:[_tmbbox + (4 * BOXLEFT) + 2], ax
mov   ax, word ptr [bp - 0Eh]
mov   word ptr ds:[_tmbbox + (4 * BOXLEFT)], si
cmp   ax, -1
jne   use_cached_secnum
mov   ax, word ptr [bp - 0Ah]
mov   bx, cx
mov   dx, di
mov   cx, word ptr [bp + 0Ah]
call  R_PointInSubsector_
mov   bx, ax
mov   ax, SUBSECTORS_SEGMENT
SHIFT_MACRO shl   bx 2
mov   es, ax
mov   ax, word ptr es:[bx]


use_cached_secnum:
mov   word ptr ds:[_lastcalculatedsector], ax
mov   word ptr ds:[_ceilinglinenum], -1
mov   bx, word ptr ds:[_lastcalculatedsector]
mov   ax, SECTORS_SEGMENT
SHIFT_MACRO shl   bx 4
mov   es, ax
mov   ax, word ptr es:[bx]
mov   word ptr ds:[_tmdropoffz], ax
mov   word ptr ds:[_tmfloorz], ax
mov   ax, word ptr es:[bx+2]
mov   word ptr ds:[_tmceilingz], ax
xor   ax, ax
inc   word ptr ds:[_validcount_global]
mov   word ptr ds:[_numspechit], ax
test  byte ptr ds:[_tmflags1+1], (MF_NOCLIP SHR 8 )
je    set_up_blockmap_loop
exit_checkposition_return_1:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
ret   4
set_up_blockmap_loop:


;	blocktemp.h = (tmbbox[BOXLEFT].h.intbits - bmaporgx - MAXRADIUSNONFRAC);
;	xl2 = (blocktemp.h & 0x0060) == 0x0060 ? 1 : 0; // if 64 and 32 bit are set then we subtracted from one 128 aligned block down. add 1 later
;	xl = blocktemp.h >> MAPBLOCKSHIFT;
;	xl2 += xl;

mov   di, MAXRADIUSNONFRAC
mov   ch, 040h  ; (0100h - 0C0h)  the point is to catch 01100000 bit pattern. shift left 1 then add 64 and catch carry flags

mov   si, word ptr ds:[_bmaporgx]
mov   ax, word ptr ds:[_tmbbox + (4 * BOXLEFT) + 2]
sub   ax, si
sub   ax, di

;// if 64 and 32 bit are set then we subtracted from one 128 aligned block down. add 1 later


; shift ax 7 and give cl 1 shifted left

IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    mov   cl, al
    sar   ax, MAPBLOCKSHIFT
    sal   cl, 1

ELSE
	sal al, 1
    mov cl, al
	mov al, ah
	cbw
	rcl ax, 1
ENDIF

add   cl, ch ; (192 + 64 = 256, hits carry flag)
mov   es, ax  ; es stores xl
adc   ax, 0
mov   word ptr [bp - 2], ax


;	blocktemp.h = (tmbbox[BOXRIGHT].h.intbits - bmaporgx + MAXRADIUSNONFRAC);
;	xh2 = blocktemp.h & 0x0060 ? 0 : -1; // if niether 64 nor 32 bit are set then we added from one 128 aligned block up. sub 1 later
;	xh = blocktemp.h >> MAPBLOCKSHIFT;
;	xh2 += xh;

mov   ax, word ptr ds:[_tmbbox + (4 * BOXRIGHT) + 2]
sub   ax, si
add   ax, di

mov   cl, al

; shift ax 7

IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   ax, MAPBLOCKSHIFT
ELSE
	sal al, 1
	mov al, ah
	cbw
	rcl ax, 1
ENDIF

and   cl, 060h
add   cl, 0FFh
mov   bx, ax   ; bx stores xh
adc   ax, 0FFFFh
mov   word ptr [bp - 8], ax


;	blocktemp.h = (tmbbox[BOXBOTTOM].h.intbits - bmaporgy - MAXRADIUSNONFRAC);
;	yl2 = (blocktemp.h & 0x0060) == 0x0060 ? 1 : 0;
;	yl = blocktemp.h >> MAPBLOCKSHIFT;
;	yl2 += yl;

mov   si, word ptr ds:[_bmaporgy]

mov   ax, word ptr ds:[_tmbbox + (4 * BOXBOTTOM) + 2]
sub   ax, si
sub   ax, di

; shift ax 7 and give cl 1 shifted left

IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    mov   cl, al
    sar   ax, MAPBLOCKSHIFT
    sal   cl, 1

ELSE
	sal al, 1
    mov cl, al
	mov al, ah
	cbw
	rcl ax, 1
ENDIF

add   cl, ch ; (192 + 64 = 256, hits carry flag)
mov   dx, ax   ; dx stores yl
adc   ax, 0
mov   word ptr [bp - 6], ax

;	blocktemp.h = (tmbbox[BOXTOP].h.intbits - bmaporgy + MAXRADIUSNONFRAC);
;	yh2 = blocktemp.h & 0x0060 ? 0 : -1;
;	yh = blocktemp.h >> MAPBLOCKSHIFT;
;	yh2 += yh;

mov   ax, word ptr ds:[_tmbbox + (4 * BOXTOP) + 2]
sub   ax, si
add   ax, di

mov   cl, al

; shift ax 7

IF COMPILE_INSTRUCTIONSET GE COMPILE_386
    sar   ax, MAPBLOCKSHIFT
ELSE
	sal al, 1
	mov al, ah
	cbw
	rcl ax, 1
ENDIF

and   cl, 060h
add   cl, 0FFh
mov   cx, ax  ; cx gets yh
adc   ax, 0FFFFh
mov   word ptr [bp - 4], ax

;	if (!DoBlockmapLoop(xl, yl, xh, yh, PIT_CheckThing, true)){

mov   di, 1     ; true
mov   ax, es	; di gets 1
mov   si, OFFSET PIT_CheckThing_
call  DoBlockmapLoop_

test  al, al
je    exit_checkposition

;	if (xl2 < 0) xl2 = 0;
;	if (yl2 < 0) yl2 = 0;


cmp   word ptr [bp - 2], 0
jnl   dont_zero_xl2
mov   word ptr [bp - 2], 0
dont_zero_xl2:
cmp   word ptr [bp - 6], 0
jnl   dont_zero_yl2
mov   word ptr [bp - 6], 0
dont_zero_yl2:

;	if (xh2 >= bmapwidth) {
;		xh2 = bmapwidth - 1;
;	}
;	if (yh2 >= bmapheight) {
;		yh2 = bmapheight - 1;
;	}

mov   ax, word ptr ds:[_bmapwidth]
cmp   ax, word ptr [bp - 8]
jnl   dont_cap_xh2
dec   ax
mov   word ptr [bp - 8], ax
dont_cap_xh2:
mov   ax, word ptr ds:[_bmapheight]
cmp   ax, word ptr [bp - 4]
jge  dont_cap_yh2
dec   ax
mov   word ptr [bp - 4], ax
dont_cap_yh2:

;	for (; xl2 <= xh2; xl2++) {
;		for (by = yl2; by <= yh2; by++) {
;			if (!P_BlockLinesIterator(xl2, by, PIT_CheckLine)) {
;				return false;
;			}
;		}
;	}

les   di, dword ptr [bp - 4]
mov   si, es

check_position_do_next_x_loop:
cmp   si, word ptr [bp - 8]  ; cl2 < xh2
jg    exit_checkposition_return_1_2
mov   cx, word ptr [bp - 6]   ; by = yl2
cmp   cx, di   				  ; cmp yh2
jg    check_position_increment_x_loop
check_position_do_next_y_loop:
mov   ax, si
mov   bx, OFFSET PIT_CheckLine_
mov   dx, cx
call  P_BlockLinesIterator_
test  al, al
je    exit_checkposition  ; return 0
inc   cx
cmp   cx, di
jle   check_position_do_next_y_loop
check_position_increment_x_loop:
inc   si
jmp   check_position_do_next_x_loop

exit_checkposition_return_1_2:
mov   al, 1
exit_checkposition:
LEAVE_MACRO 
pop   di
pop   si
ret   4



ENDP


; void __near P_SlideMove (){

PROC P_SlideMove_ NEAR
PUBLIC P_SlideMove_ 

; todo pusha

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 016h
mov   word ptr [bp - 0Ch], 0
label_18:
inc   word ptr [bp - 0Ch]
cmp   word ptr [bp - 0Ch], 3
jne   label_16
jmp   label_8
label_16:
mov   byte ptr [bp - 9], 0
mov   bx, word ptr ds:[_playerMobj]
les   si, dword ptr ds:[_playerMobj_pos]
mov   al, byte ptr [bx + 01Eh]
xor   dx, dx
mov   byte ptr [bp - 0Ah], al
mov   ax, word ptr [bp - 0Ah]
mov   cx, word ptr es:[si]
mov   di, word ptr es:[si + 2]
mov   word ptr [bp - 2], cx
mov   word ptr [bp - 010h], cx
mov   cx, word ptr es:[si + 4]
mov   word ptr [bp - 4], di
mov   word ptr [bp - 014h], cx
mov   si, word ptr es:[si + 6]
mov   word ptr [bp - 8], cx
mov   word ptr [bp - 6], si
cmp   word ptr [bx + 010h], 0
jg    label_1
je    label_2
jump_to_label_3:
jmp   label_3
label_2:
cmp   word ptr [bx + 0Eh], 0
jbe   jump_to_label_3
label_1:
mov   bx, word ptr [bp - 2]
add   di, ax
sub   bx, dx
mov   word ptr [bp - 010h], bx
sbb   word ptr [bp - 4], ax
label_13:
mov   bx, word ptr ds:[_playerMobj]
cmp   word ptr [bx + 014h], 0
jg    label_4
je    label_5
jump_to_label_6:
jmp   label_6
label_5:
cmp   word ptr [bx + 012h], 0
jbe   jump_to_label_6
label_4:
add   si, ax
sub   word ptr [bp - 8], dx
sbb   word ptr [bp - 6], ax
label_14:
mov   ax, 1
mov   dx, word ptr [bp - 2]
mov   cx, word ptr [bp - 014h]
push  OFFSET PTR_SlideTraverse_
mov   bx, word ptr ds:[_playerMobj]
push  PT_ADDLINES
mov   word ptr ds:[_bestslidefrac], ax
mov   word ptr ds:[_bestslidefrac+2], ax
add   dx, word ptr [bx + 0Eh]
mov   ax, word ptr [bx + 010h]
adc   ax, di
add   cx, word ptr [bx + 012h]
mov   bx, word ptr [bx + 014h]
adc   bx, si
mov   word ptr [bp - 016h], cx
push  bx
mov   word ptr [bp - 0Eh], bx
push  cx
mov   bx, word ptr [bp - 014h]
push  ax
mov   cx, si
mov   ax, word ptr [bp - 2]
push  dx
mov   dx, di
call  P_PathTraverse_
mov   ax, word ptr [bp - 014h]
mov   bx, word ptr ds:[_playerMobj]
push  OFFSET PTR_SlideTraverse_
add   ax, word ptr [bx + 012h]
mov   word ptr [bp - 016h], ax
mov   ax, word ptr [bx + 014h]
adc   ax, si
push  PT_ADDLINES
mov   word ptr [bp - 0Eh], ax
mov   cx, si
push  word ptr [bp - 0Eh]
mov   ax, word ptr [bp - 010h]
push  word ptr [bp - 016h]
add   ax, word ptr [bx + 0Eh]
mov   dx, word ptr [bp - 4]
adc   dx, word ptr [bx + 010h]
mov   bx, word ptr [bp - 014h]
push  dx
mov   dx, word ptr [bp - 4]
push  ax
mov   ax, word ptr [bp - 010h]
call  P_PathTraverse_
mov   dx, word ptr [bp - 2]
mov   cx, word ptr [bp - 8]
push  OFFSET PTR_SlideTraverse_
mov   bx, word ptr ds:[_playerMobj]
push  PT_ADDLINES
add   dx, word ptr [bx + 0Eh]
mov   ax, word ptr [bx + 010h]
adc   ax, di
add   cx, word ptr [bx + 012h]
mov   si, word ptr [bp - 6]
adc   si, word ptr [bx + 014h]
push  si
mov   bx, word ptr [bp - 8]
push  cx
mov   cx, word ptr [bp - 6]
push  ax
mov   ax, word ptr [bp - 2]
push  dx
mov   dx, di
call  P_PathTraverse_
cmp   word ptr ds:[_bestslidefrac+2], 1
jne   label_7
cmp   word ptr ds:[_bestslidefrac], 1
jne   label_7
jmp   label_8
label_7:
add   word ptr ds:[_bestslidefrac], 0F800h
adc   word ptr ds:[_bestslidefrac+2], -1
mov   ax, word ptr ds:[_bestslidefrac+2]
test  ax, ax
jle   label_17
jump_to_label_10:
jmp   label_10
label_17:
jne   label_9
cmp   word ptr ds:[_bestslidefrac], 0
ja    jump_to_label_10
label_9:
cmp   word ptr ds:[_bestslidefrac], 0F800h
je    label_11
jmp   label_12
label_11:
mov   bx, word ptr ds:[_playerMobj]
mov   ax, word ptr [bx + 0Eh]
mov   dx, word ptr [bx + 010h]
mov   word ptr ds:[_tmxmove+0], ax
mov   word ptr ds:[_tmxmove+2], dx
mov   ax, word ptr [bx + 012h]
mov   dx, word ptr [bx + 014h]
label_15:
mov   word ptr ds:[_tmymove+0], ax
mov   word ptr ds:[_tmymove+2], dx
mov   ax, word ptr ds:[_bestslidelinenum]
call  P_HitSlideLine_
mov   si, word ptr ds:[_playerMobj]
mov   ax, word ptr ds:[_tmxmove+0]
mov   dx, word ptr ds:[_tmxmove+2]
mov   word ptr [si + 0Eh], ax
mov   word ptr [si + 010h], dx
mov   ax, word ptr ds:[_tmymove+0]
mov   dx, word ptr ds:[_tmymove+2]
mov   word ptr [si + 012h], ax
mov   bx, word ptr ds:[_playerMobj_pos]
mov   word ptr [si + 014h], dx
mov   es, word ptr ds:[_playerMobj_pos+2]
mov   di, word ptr es:[bx]
mov   cx, word ptr es:[bx + 2]
mov   dx, word ptr es:[bx + 4]
mov   ax, word ptr es:[bx + 6]
add   di, word ptr ds:[_tmxmove+0]
adc   cx, word ptr ds:[_tmxmove+2]
add   dx, word ptr ds:[_tmymove+0]
adc   ax, word ptr ds:[_tmymove+2]
push  ax
push  dx
push  cx
mov   ax, si
push  di
mov   cx, es
call  P_TryMove_
test  al, al
jne   exit_slidemove
jmp   label_18
exit_slidemove:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_3:
sub   word ptr [bp - 2], dx
sbb   di, ax
add   word ptr [bp - 4], ax
jmp   label_13
label_6:
sub   word ptr [bp - 014h], dx
sbb   si, ax
add   word ptr [bp - 6], ax
jmp   label_14
label_8:
les   bx, dword ptr ds:[_playerMobj_pos]
mov   si, word ptr ds:[_playerMobj]
mov   ax, word ptr es:[bx + 4]
mov   dx, word ptr es:[bx + 6]
add   ax, word ptr [si + 012h]
adc   dx, word ptr [si + 014h]
push  dx
push  ax
push  word ptr es:[bx + 2]
mov   cx, es
push  word ptr es:[bx]
mov   ax, si
call  P_TryMove_
test  al, al
jne   exit_slidemove
les   bx, dword ptr ds:[_playerMobj_pos]
mov   si, word ptr ds:[_playerMobj]
mov   ax, word ptr es:[bx]
push  word ptr es:[bx + 6]
mov   word ptr [bp - 012h], ax
mov   dx, word ptr [si + 0Eh]
push  word ptr es:[bx + 4]
mov   ax, word ptr es:[bx + 2]
add   word ptr [bp - 012h], dx
adc   ax, word ptr [si + 010h]
push  ax
mov   cx, es
push  word ptr [bp - 012h]
mov   ax, si
call  P_TryMove_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_10:
mov   si, word ptr ds:[_bestslidefrac]
mov   bx, word ptr ds:[_playerMobj]
mov   cx, ax
mov   ax, word ptr [bx + 0Eh]
mov   dx, word ptr [bx + 010h]
mov   bx, si
call  FixedMul_
les   bx, dword ptr ds:[_playerMobj_pos]
mov   cx, word ptr es:[bx]
mov   si, word ptr ds:[_bestslidefrac]
add   cx, ax
mov   word ptr [bp - 012h], cx
mov   cx, word ptr ds:[_bestslidefrac+2]
mov   di, word ptr es:[bx + 2]
mov   bx, word ptr ds:[_playerMobj]
adc   di, dx
mov   ax, word ptr [bx + 012h]
mov   dx, word ptr [bx + 014h]
mov   bx, si
call  FixedMul_
les   bx, dword ptr ds:[_playerMobj_pos]
add   ax, word ptr es:[bx + 4]
adc   dx, word ptr es:[bx + 6]
push  dx
push  ax
push  di
mov   cx, es
push  word ptr [bp - 012h]
mov   ax, word ptr ds:[_playerMobj]
call  P_TryMove_
test  al, al
jne   jump_to_label_9
jmp   label_8
jump_to_label_9:
jmp   label_9
label_12:
add   word ptr ds:[_bestslidefrac], 07FFh
mov   bx, word ptr ds:[_playerMobj]
xor   word ptr ds:[_bestslidefrac], 0FFFFh
mov   ax, word ptr [bx + 0Eh]
mov   cx, word ptr [bx + 010h]
mov   dx, word ptr ds:[_bestslidefrac]
mov   bx, ax
mov   ax, dx
call  FixedMul16u32_
mov   bx, word ptr ds:[_playerMobj]
mov   word ptr ds:[_tmxmove+0], ax
mov   word ptr ds:[_tmxmove+2], dx
mov   dx, word ptr ds:[_bestslidefrac]
mov   ax, word ptr [bx + 012h]
mov   cx, word ptr [bx + 014h]
mov   bx, ax
mov   ax, dx
call  FixedMul16u32_
jmp   label_15

ENDP

COMMENT  @


PROC PTR_AimTraverse_ NEAR
PUBLIC PTR_AimTraverse_


ENDP


boolean __near PTR_AimTraverse (intercept_t __far* in);

PROC PTR_AimTraverse_ NEAR
PUBLIC PTR_AimTraverse_


ENDP
@





END
