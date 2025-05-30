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
EXTRN FixedMulBig1632_:FAR
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

push  es					; bp - 4  vertex y
push  ax    				; bp - 6
push  dx                    ; bp - 8 vertex x
push  ax    				; bp - 0Ah




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


; todo push stuff

; boolean __near P_CheckPosition (mobj_t __near* thing, int16_t oldsecnum, fixed_t_union	x, fixed_t_union	y );

PROC P_CheckPosition_ NEAR
PUBLIC P_CheckPosition_

; - bp - 2   oldsecnum (dx)
; - bp - 4   x lowbits (bx)   (di is hibits)
; - bp - 6   xl2
; - bp - 8   xh2
; - bp - 0Ah yl2
; - bp - 0Ch yh2

;   y hi ; + 0Ah
;   y lo ; + 8
;     ip ; + 6      
push  si ; + 4
push  di ; + 2
push  bp ; + 0
mov   bp, sp

push  dx  ; bp - 2
push  bx  ; bp - 4
mov   si, ax ; thing ptr
mov   di, cx
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


mov   ax, word ptr [bp + 8]
mov   word ptr ds:[_tmbbox + (4 * BOXTOP)], ax
mov   word ptr ds:[_tmy+0], ax
mov   word ptr ds:[_tmbbox + (4 * BOXBOTTOM)], ax
xchg  ax, cx

mov   ax, word ptr [bp - 4]
mov   word ptr ds:[_tmx+0], ax
mov   word ptr ds:[_tmbbox + (4 * BOXRIGHT)], ax
mov   word ptr ds:[_tmbbox + (4 * BOXLEFT)], ax



mov   al, byte ptr [si + 01Eh]
xor   ah, ah
mov   word ptr ds:[_tmbbox + (4 * BOXTOP) + 2], ax
mov   al, byte ptr [si + 01Eh]
xchg  ax, dx

mov   ax, word ptr [bp + 0Ah]
add   word ptr ds:[_tmbbox + (4 * BOXTOP) + 2], ax
mov   word ptr ds:[_tmy+2], ax

sub   ax, dx
mov   word ptr ds:[_tmbbox + (4 * BOXBOTTOM)+ 2], ax

mov   word ptr ds:[_tmbbox + (4 * BOXRIGHT) + 2], di
mov   word ptr ds:[_tmx+2], di

mov   al, byte ptr [si + 01Eh]
xor   ah, ah
add   word ptr ds:[_tmbbox + (4 * BOXRIGHT) + 2], ax
mov   ax, di
sub   ax, dx
mov   word ptr ds:[_tmbbox + (4 * BOXLEFT) + 2], ax
mov   ax, word ptr [bp - 2]
cmp   ax, -1
jne   use_cached_secnum
mov   ax, word ptr [bp - 4]
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
push  ax  ; bp - 6


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
push  ax   ; bp - 8


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
push  ax  ; bp - 0Ah

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
push  ax   ; bp - 0Ch

;	if (!DoBlockmapLoop(xl, yl, xh, yh, PIT_CheckThing, true)){

mov   di, 1     ; true
mov   ax, es	; di gets 1
mov   si, OFFSET PIT_CheckThing_
call  DoBlockmapLoop_

test  al, al
je    exit_checkposition

;	if (xl2 < 0) xl2 = 0;
;	if (yl2 < 0) yl2 = 0;


cmp   word ptr [bp - 6], 0
jnl   dont_zero_xl2
mov   word ptr [bp - 6], 0
dont_zero_xl2:
cmp   word ptr [bp - 0Ah], 0
jnl   dont_zero_yl2
mov   word ptr [bp - 0Ah], 0
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
cmp   ax, word ptr [bp - 0Ch]
jge  dont_cap_yh2
dec   ax
mov   word ptr [bp - 0Ch], ax
dont_cap_yh2:

;	for (; xl2 <= xh2; xl2++) {
;		for (by = yl2; by <= yh2; by++) {
;			if (!P_BlockLinesIterator(xl2, by, PIT_CheckLine)) {
;				return false;
;			}
;		}
;	}

pop   di  				     ; bp - 0Ch
mov   si, word ptr [bp - 6]  ; xl2

check_position_do_next_x_loop:
cmp   si, word ptr [bp - 8]  ; xl2 < xh2
jg    exit_checkposition_return_1_2
mov   cx, word ptr [bp - 0Ah]   ; by = yl2
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

; bp - 2    retry counter
; bp - 4    leadx hi
; bp - 6    leadx lo

; bp - 8    trailx hi
; bp - 0Ah  trailx lo
; bp - 0Ch  leady hi
; bp - 0Eh  leady lo
; bp - 010h traily hi
; bp - 012h traily lo



PUSHA_NO_AX_MACRO
push  bp
mov   bp, sp
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
	push  2  ; bp - 2 loopcount  
ELSE
	mov   ax, 2
	push  ax
ENDIF

slidemove_retry:

;	temp.h.fracbits = 0;
;	temp.h.intbits = playerMobj->radius;
;	leadx = playerMobj_pos->x;
;	trailx = playerMobj_pos->x;
;	leady = playerMobj_pos->y;
;	traily = playerMobj_pos->y;



mov   si, word ptr ds:[_playerMobj]
les   bx, dword ptr ds:[_playerMobj_pos]
xor   ax, ax

mov   al, byte ptr [si + 01Eh]  ; radius


mov   cx, word ptr es:[bx]
mov   di, word ptr es:[bx + 2]
mov   dx, di  ; 





;	if (playerMobj->momx.w > 0) {
;		leadx.h.intbits += temp.h.intbits;
;		trailx.w -= temp.w;
;    } else {
;		leadx.w -= temp.w;
;		trailx.h.intbits += temp.h.intbits;
;    }

cmp   word ptr [si + 010h], 0
jg    momx_greater_than_zero
jne   momx_lte_0
cmp   word ptr [si + 0Eh], 0
jnbe  momx_greater_than_zero
momx_lte_0:
sub   di, ax
add   dx, ax
jmp   done_with_momx_check

momx_greater_than_zero:
add   di, ax
sub   dx, ax

done_with_momx_check:

push  di  ; bp - 4
push  cx  ; bp - 6
push  dx  ; bp - 8
push  cx  ; bp - 0Ah


les   bx, dword ptr es:[bx + 4]
mov   dx, es
mov   cx, dx




;    if (playerMobj->momy.w > 0) {
;		leady.h.intbits += temp.h.intbits;
;		traily.w -= temp.w;
;    } else {
;		leady.w -= temp.w;
;		traily.h.intbits += temp.h.intbits;
;    } 

cmp   word ptr [si + 014h], 0
jg    momy_greater_than_zero
jne   momy_lte_0
cmp   word ptr [si + 012h], 0
jnbe  momy_greater_than_zero

momy_lte_0:
sub   cx, ax
add   dx, ax
jmp   done_with_momy_check

momy_greater_than_zero:
add   cx, ax
sub   dx, ax

done_with_momy_check:

push  cx ; bp - 0Ch
push  bx ; bp - 0Eh
push  dx ; bp - 010h
push  bx ; bp - 012h


;	bestslidefrac.w = FRACUNIT + 1;

mov   ax, 1
mov   word ptr ds:[_bestslidefrac], ax
mov   word ptr ds:[_bestslidefrac+2], ax

xchg  ax, bx;  
; dx:ax are bp - 012h / traily



;	temp.w = leadx.w + playerMobj->momx.w;


les   bx, dword ptr [si + 0Eh] ; momx
mov   cx, es
add   bx, word ptr [bp - 6]    ; leadx lo (di is hi)
adc   cx, di  				   ; leadx hi


; ready args

; call 3
;	P_PathTraverse(leadx, traily, temp, temp4, PT_ADDLINES, PTR_SlideTraverse);

;	temp4.w = traily.w + playerMobj->momy.w;
;    dx/ax already equal traily
add   ax, word ptr [si + 012h]
adc   dx, word ptr [si + 014h]

push  OFFSET PTR_SlideTraverse_
push  PT_ADDLINES
push  dx ; temp4
push  ax
push  cx ; temp
push  bx


;	temp2.w = leady.w + playerMobj->momy.w;

les   ax, dword ptr [si + 012h] ; momy
mov   dx, es
add   ax, word ptr [bp - 0Eh]
adc   dx, word ptr [bp - 0Ch]

; call 2
;	P_PathTraverse(trailx, leady, temp3, temp2, PT_ADDLINES, PTR_SlideTraverse);

push  OFFSET PTR_SlideTraverse_
push  PT_ADDLINES
push  dx ; temp 2
push  ax

;	temp3.w = trailx.w + playerMobj->momx.w;


les   si, dword ptr [si + 0Eh]
mov   di, es
add   si, word ptr [bp - 0Ah]
adc   di, word ptr [bp - 8]
push  di ; temp 3 hi
push  si ; temp 3 lo

; call 1

;	P_PathTraverse(leadx, leady, temp, temp2, PT_ADDLINES, PTR_SlideTraverse);


push  OFFSET PTR_SlideTraverse_
push  PT_ADDLINES
push  dx ; temp 2
push  ax 
push  cx ; temp
push  bx 




;P_PathTraverse(leadx, leady, temp, temp2, PT_ADDLINES, PTR_SlideTraverse);

les   bx, dword ptr [bp - 0Eh]  ; leady lo
mov   cx, es 					; leady hi
les   ax, dword ptr [bp - 6]    ; leadx lo
mov   dx, es					; leadx hi
call  P_PathTraverse_

;P_PathTraverse(trailx, leady, temp3, temp2, PT_ADDLINES, PTR_SlideTraverse);

les   bx, dword ptr [bp - 0Eh]   ; leady  lo
mov   cx, es 				     ; leady  hi
les   ax, dword ptr [bp - 0Ah]   ; trailx lo
mov   dx, es  				     ; trailx hi
call  P_PathTraverse_

;P_PathTraverse(leadx, traily, temp, temp4, PT_ADDLINES, PTR_SlideTraverse);

les   bx, dword ptr [bp - 012h]	 ; traily lo
mov   cx, es					 ; traily hi
les   ax, dword ptr [bp - 6]     ; leadx  lo
mov   dx, es					 ; leadx  hi
call  P_PathTraverse_

cmp   word ptr ds:[_bestslidefrac+2], 1
jne   not_stairstep
cmp   word ptr ds:[_bestslidefrac], 1
jne   not_stairstep
jmp   stairstep
not_stairstep:

;    // fudge a bit to make sure it doesn't hit
;    bestslidefrac.w -= 0x800;	

add   word ptr ds:[_bestslidefrac], 0F800h
adc   word ptr ds:[_bestslidefrac+2], -1
mov   ax, word ptr ds:[_bestslidefrac+2]

;    if (bestslidefrac.w > 0) {

test  ax, ax
jle   continiue_check_bestslidefrac_lessthanzero
bestslidefrac_greaterthanzero:


;newx.w = FixedMul (playerMobj->momx.w, bestslidefrac.w);

xchg  ax, cx  						   ; ax has +2 todo cleanup
mov   bx, word ptr ds:[_bestslidefrac] ; bx gets+0

mov   di, word ptr ds:[_playerMobj]
les   ax, dword ptr [di + 0Eh]
mov   dx, es

call  FixedMul_

;newx.w += playerMobj_pos->x.w;

les   si, dword ptr ds:[_playerMobj_pos]
les   si, dword ptr es:[si]   ; es:si has this...
mov   bx, es

add   si, ax  ; bx:si is newx.w
adc   bx, dx

;newy.w = FixedMul (playerMobj->momy.w, bestslidefrac.w);

les   ax, dword ptr [di + 012h]
mov   dx, es

mov   di, bx  ; di:si is newx

les   bx, dword ptr ds:[_bestslidefrac]
mov   cx, es

call  FixedMul_

; newy.w += playerMobj_pos->y.w;

les   bx, dword ptr ds:[_playerMobj_pos]
mov   cx, es
add   ax, word ptr es:[bx + 4]
adc   dx, word ptr es:[bx + 6]

;   if (!P_TryMove (playerMobj, playerMobj_pos, newx, newy)) {


push  dx ; newy
push  ax
push  di ; newx
push  si
mov   ax, word ptr ds:[_playerMobj]
call  P_TryMove_

test  al, al
jne   bestslidefrac_lessthanzero
jmp   stairstep   ; 3D bytes off..
continiue_check_bestslidefrac_lessthanzero:
jne   bestslidefrac_lessthanzero
cmp   word ptr ds:[_bestslidefrac], 0
ja    bestslidefrac_greaterthanzero
bestslidefrac_lessthanzero:

;	if (bestslidefrac.hu.fracbits == 0xF800) {
mov   si, word ptr ds:[_playerMobj]

cmp   word ptr ds:[_bestslidefrac], 0F800h
je    bestslidefrac_f800  ; 061h bytes left

;		// same as 1 - (this+0x800) 
;		bestslidefrac.hu.fracbits += 0x7FF; 
;		bestslidefrac.hu.fracbits ^= 0xFFFF;



add   word ptr ds:[_bestslidefrac], 07FFh
xor   word ptr ds:[_bestslidefrac], 0FFFFh

;		tmxmove.w = FixedMul16u32(bestslidefrac.hu.fracbits, playerMobj->momx.w);
;		tmymove.w = FixedMul16u32(bestslidefrac.hu.fracbits, playerMobj->momy.w);


les   bx, dword ptr [si + 0Eh]
mov   cx, es

mov   di, word ptr ds:[_bestslidefrac]
mov   ax, di
call  FixedMul16u32_

mov   word ptr ds:[_tmxmove+0], ax
mov   word ptr ds:[_tmxmove+2], dx

les   bx, dword ptr [si + 012h]
mov   cx, es
xchg  ax, di  ; bestslidefrac

call  FixedMul16u32_
jmp   do_hitslideline
bestslidefrac_f800:

;		tmxmove = playerMobj->momx;
;		tmymove = playerMobj->momy;


les   ax, dword ptr [si + 0Eh]
mov   dx, es
mov   word ptr ds:[_tmxmove+0], ax
mov   word ptr ds:[_tmxmove+2], dx
les   ax, dword ptr [si + 012h]
mov   dx, es
do_hitslideline:

;    P_HitSlideLine (bestslidelinenum);	// clip the moves

mov   word ptr ds:[_tmymove+0], ax
mov   word ptr ds:[_tmymove+2], dx

;    P_HitSlideLine (bestslidelinenum);	// clip the moves

mov   ax, word ptr ds:[_bestslidelinenum]
call  P_HitSlideLine_


les   ax, dword ptr ds:[_tmxmove+0]
mov   word ptr [si + 0Eh], ax
mov   word ptr [si + 010h], es
les   ax, dword ptr ds:[_tmymove+0]
mov   word ptr [si + 012h], ax
mov   word ptr [si + 014h], es
les   bx, dword ptr ds:[_playerMobj_pos]
mov   cx, es

mov   ax, word ptr es:[bx + 4]
mov   dx, word ptr es:[bx + 6]
add   ax, word ptr ds:[_tmymove+0]
adc   dx, word ptr ds:[_tmymove+2]
push  dx
push  ax

les   ax, dword ptr es:[bx]
mov   dx, es
add   ax, word ptr ds:[_tmxmove+0]
adc   dx, word ptr ds:[_tmxmove+2]


push  dx
push  ax
xchg  ax, si
call  P_TryMove_
test  al, al
jne   exit_slidemove

dec   word ptr [bp - 2]
jz    stairstep
add   sp, 010h  	 ; undo stack
jmp   slidemove_retry

exit_slidemove:
LEAVE_MACRO 
POPA_NO_AX_MACRO
ret   

stairstep:
les   bx, dword ptr ds:[_playerMobj_pos]
mov   si, word ptr ds:[_playerMobj]
mov   ax, word ptr es:[bx + 4]
mov   dx, word ptr es:[bx + 6]
add   ax, word ptr [si + 012h]
adc   dx, word ptr [si + 014h]
push  dx
push  ax
mov   cx, es
les   ax, dword ptr es:[bx]
push  es
push  ax
xchg  ax, si
call  P_TryMove_
test  al, al
jne   exit_slidemove
les   bx, dword ptr ds:[_playerMobj_pos]
mov   si, word ptr ds:[_playerMobj]
push  word ptr es:[bx + 6]
push  word ptr es:[bx + 4]
mov   cx, es

les   ax, dword ptr es:[bx]
mov   dx, es
add   ax, word ptr [si + 0Eh]
adc   dx, word ptr [si + 010h]
push  dx
push  ax

xchg  ax, si

call  P_TryMove_
LEAVE_MACRO 
POPA_NO_AX_MACRO
ret   



ENDP


; fixed_t __near P_GetAttackRangeMult(int16_t range, fixed_t frac){

PROC P_GetAttackRangeMult_ NEAR
PUBLIC P_GetAttackRangeMult_


cmp   ax, CHAINSAWRANGE
jae   above_melee_range
cmp   ax, MELEERANGE
jne   return_0_range


; shift left 6
xor   ax, ax

shr   cx, 1
rcr   bx, 1
rcr   al, 1
shr   cx, 1
rcr   bx, 1
rcr   al, 1
mov   dh, cl
mov   dl, bh
mov   ah, bl
ret   
above_melee_range:
je    chainsaw_range
cmp   ax, HALFMISSILERANGE
je    half_missile_range
cmp   ax, MISSILERANGE
jne   return_0_range

missile_range:
;			return frac << 11; 

; al guaranteed 0

shl   bx, 1
rcl   cx, 1
half_missile_range: ;			return frac << 10; 

shl   bx, 1
rcl   cx, 1
shl   bx, 1
rcl   cx, 1
mov   dh, cl
mov   dl, bh
mov   ah, bl


ret   

chainsaw_range:
; mov   ax, 041h
call  FixedMulBig1632_
ret   
return_0_range:
; shouldnt ever happen?
xor   ax, ax
cwd  
ret   

ENDP



; boolean __near P_ThingHeightClip (mobj_t __near* thing, mobj_pos_t __far* thing_pos){

PROC P_ThingHeightClip_ NEAR
PUBLIC P_ThingHeightClip_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6

;	temp.h.fracbits = 0;
;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->floorz);
;    onfloor = (thing_pos->z.w == temp.w);


mov   si, ax	; si gets thing ptr
mov   di, bx    ; es:di gets thingpos
mov   word ptr [bp - 4], cx
mov   es, cx

mov   ax, word ptr [si + 6]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1



;    onfloor = (thing_pos->z.w == temp.w);
mov   byte ptr [bp - 2], 0

cmp   ax, word ptr es:[di + 0Ah]
jne   done_setting_onfloor
cmp   dx, word ptr es:[di + 8]
jne   done_setting_onfloor
inc   byte ptr [bp - 2]		; onfloor = 1


done_setting_onfloor:

;    P_CheckPosition (thing, thing->secnum, thing_pos->x, thing_pos->y);

mov   ax, si
mov   dx, word ptr [si + 4]
push  word ptr es:[di + 6]
push  word ptr es:[di + 4]
les   bx, dword ptr es:[di]
mov   cx, es
call  P_CheckPosition_

mov   ax, word ptr ds:[_tmfloorz]
mov   word ptr [si + 6], ax
mov   dx, word ptr ds:[_tmceilingz]
mov   word ptr [si + 8], dx

;if (onfloor) {

cmp   byte ptr [bp - 2], 0
je    not_on_floor

;todo reuse from above!
;		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->floorz);
;		thing_pos->z.w = temp.w;

xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

mov   es, word ptr [bp - 4]
mov   word ptr es:[di + 0Ah], ax
mov   word ptr es:[di + 8], dx
label_5:
mov   ax, word ptr [si + 8]
sub   ax, word ptr [si + 6]
sar   ax, 3
cmp   ax, word ptr [si + 0Ch]
jge   exit_thingheightclip_return_1
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

not_on_floor:

; dx already has ceilingz
;	// don't adjust a floating monster unless forced to
;		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, thing->ceilingz);
;		if (thing_pos->z.w+ thing->height.w > temp.w)
;			thing_pos->z.w = temp.w - thing->height.w;


xor   ax, ax
xchg  ax, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

mov   es, word ptr [bp - 4]

mov   bx, word ptr es:[di + 8]
mov   cx, word ptr [si + 0Ah]
mov   word ptr [bp - 6], bx
mov   bx, word ptr es:[di + 0Ah]
add   word ptr [bp - 6], cx
adc   bx, word ptr [si + 0Ch]
cmp   bx, ax
jg    label_4
jne   label_5
cmp   dx, word ptr [bp - 6]
jae   label_5
label_4:
mov   bx, word ptr [si + 0Ch]
sub   dx, cx
sbb   ax, bx
mov   word ptr es:[di + 8], dx
mov   word ptr es:[di + 0Ah], ax
jmp   label_5
exit_thingheightclip_return_1:
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   

ENDP

COMMENT  @


; boolean __near PTR_ShootTraverse (intercept_t __far* in){

PROC PTR_ShootTraverse_ NEAR
PUBLIC PTR_ShootTraverse_

0x0000000000000000:  53                push  bx
0x0000000000000001:  51                push  cx
0x0000000000000002:  56                push  si
0x0000000000000003:  57                push  di
0x0000000000000004:  55                push  bp
0x0000000000000005:  89 E5             mov   bp, sp
0x0000000000000007:  83 EC 30          sub   sp, 0x30
0x000000000000000a:  89 C6             mov   si, ax
0x000000000000000c:  89 56 FE          mov   word ptr [bp - 2], dx
0x000000000000000f:  8E C2             mov   es, dx
0x0000000000000011:  26 80 7C 04 00    cmp   byte ptr es:[si + 4], 0
0x0000000000000016:  75 03             jne   0x1b
0x0000000000000018:  E9 BB 02          jmp   0x2d6
0x000000000000001b:  B8 BA E9          mov   ax, 0xe9ba
0x000000000000001e:  26 8B 5C 05       mov   bx, word ptr es:[si + 5]
0x0000000000000022:  8E C0             mov   es, ax
0x0000000000000024:  26 8A 0F          mov   cl, byte ptr es:[bx]
0x0000000000000027:  8E C2             mov   es, dx
0x0000000000000029:  26 8B 5C 05       mov   bx, word ptr es:[si + 5]
0x000000000000002d:  C7 46 E0 01 E8    mov   word ptr [bp - 0x20], 0xe801
0x0000000000000032:  C1 E3 02          shl   bx, 2
0x0000000000000035:  B8 00 70          mov   ax, 0x7000
0x0000000000000038:  89 5E DC          mov   word ptr [bp - 0x24], bx
0x000000000000003b:  26 8B 5C 05       mov   bx, word ptr es:[si + 5]
0x000000000000003f:  89 46 FA          mov   word ptr [bp - 6], ax
0x0000000000000042:  C1 E3 04          shl   bx, 4
0x0000000000000045:  8E C0             mov   es, ax
0x0000000000000047:  89 5E F8          mov   word ptr [bp - 8], bx
0x000000000000004a:  26 80 7F 0F 00    cmp   byte ptr es:[bx + 0xf], 0
0x000000000000004f:  74 0C             je    0x5d
0x0000000000000051:  8E C2             mov   es, dx
0x0000000000000053:  A1 F8 1E          mov   ax, word ptr [0x1ef8]
0x0000000000000056:  26 8B 54 05       mov   dx, word ptr es:[si + 5]
0x000000000000005a:  E8 15 3C          call  0x3c72
0x000000000000005d:  F6 C1 04          test  cl, 4
0x0000000000000060:  74 03             je    0x65
0x0000000000000062:  E9 1B 01          jmp   0x180
0x0000000000000065:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x0000000000000068:  3D 41 00          cmp   ax, 0x41
0x000000000000006b:  72 03             jb    0x70
0x000000000000006d:  E9 31 02          jmp   0x2a1
0x0000000000000070:  3D 40 00          cmp   ax, 0x40
0x0000000000000073:  75 14             jne   0x89
0x0000000000000075:  8E 46 FE          mov   es, word ptr [bp - 2]
0x0000000000000078:  26 8B 3C          mov   di, word ptr es:[si]
0x000000000000007b:  81 C7 00 F0       add   di, 0xf000
0x000000000000007f:  26 8B 44 02       mov   ax, word ptr es:[si + 2]
0x0000000000000083:  15 FF FF          adc   ax, 0xffff
0x0000000000000086:  89 46 FC          mov   word ptr [bp - 4], ax
0x0000000000000089:  8B 4E FC          mov   cx, word ptr [bp - 4]
0x000000000000008c:  A1 10 1A          mov   ax, word ptr [0x1a10]
0x000000000000008f:  8B 16 12 1A       mov   dx, word ptr [0x1a12]
0x0000000000000093:  89 FB             mov   bx, di
0x0000000000000095:  9A 98 5B 81 0A    lcall 0xa81:0x5b98
0x000000000000009a:  8B 1E 08 1A       mov   bx, word ptr [0x1a08]
0x000000000000009e:  8B 4E FC          mov   cx, word ptr [bp - 4]
0x00000000000000a1:  01 C3             add   bx, ax
0x00000000000000a3:  89 5E D8          mov   word ptr [bp - 0x28], bx
0x00000000000000a6:  89 FB             mov   bx, di
0x00000000000000a8:  A1 0A 1A          mov   ax, word ptr [0x1a0a]
0x00000000000000ab:  11 D0             adc   ax, dx
0x00000000000000ad:  8B 16 16 1A       mov   dx, word ptr [0x1a16]
0x00000000000000b1:  89 46 DA          mov   word ptr [bp - 0x26], ax
0x00000000000000b4:  A1 14 1A          mov   ax, word ptr [0x1a14]
0x00000000000000b7:  9A 98 5B 81 0A    lcall 0xa81:0x5b98
0x00000000000000bc:  8B 1E 0C 1A       mov   bx, word ptr [0x1a0c]
0x00000000000000c0:  8B 4E FC          mov   cx, word ptr [bp - 4]
0x00000000000000c3:  01 C3             add   bx, ax
0x00000000000000c5:  89 5E D6          mov   word ptr [bp - 0x2a], bx
0x00000000000000c8:  A1 0E 1A          mov   ax, word ptr [0x1a0e]
0x00000000000000cb:  11 D0             adc   ax, dx
0x00000000000000cd:  89 FB             mov   bx, di
0x00000000000000cf:  89 46 E6          mov   word ptr [bp - 0x1a], ax
0x00000000000000d2:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x00000000000000d5:  E8 64 F9          call  0xfa3c
0x00000000000000d8:  8B 36 A4 1C       mov   si, word ptr [0x1ca4]
0x00000000000000dc:  8B 3E A6 1C       mov   di, word ptr [0x1ca6]
0x00000000000000e0:  89 C3             mov   bx, ax
0x00000000000000e2:  89 D1             mov   cx, dx
0x00000000000000e4:  89 F0             mov   ax, si
0x00000000000000e6:  89 FA             mov   dx, di
0x00000000000000e8:  9A 98 5B 81 0A    lcall 0xa81:0x5b98
0x00000000000000ed:  8B 1E A8 1C       mov   bx, word ptr [0x1ca8]
0x00000000000000f1:  8B 76 F8          mov   si, word ptr [bp - 8]
0x00000000000000f4:  01 C3             add   bx, ax
0x00000000000000f6:  A1 AA 1C          mov   ax, word ptr [0x1caa]
0x00000000000000f9:  8E 46 FA          mov   es, word ptr [bp - 6]
0x00000000000000fc:  11 D0             adc   ax, dx
0x00000000000000fe:  26 8B 74 0A       mov   si, word ptr es:[si + 0xa]
0x0000000000000102:  BA 00 E0          mov   dx, 0xe000
0x0000000000000105:  C1 E6 04          shl   si, 4
0x0000000000000108:  8E C2             mov   es, dx
0x000000000000010a:  8D 7C 05          lea   di, [si + 5]
0x000000000000010d:  B9 98 01          mov   cx, 0x198
0x0000000000000110:  26 8A 15          mov   dl, byte ptr es:[di]
0x0000000000000113:  89 CF             mov   di, cx
0x0000000000000115:  3A 15             cmp   dl, byte ptr [di]
0x0000000000000117:  75 4E             jne   0x167
0x0000000000000119:  26 8B 4C 02       mov   cx, word ptr es:[si + 2]
0x000000000000011d:  26 8B 54 02       mov   dx, word ptr es:[si + 2]
0x0000000000000121:  30 ED             xor   ch, ch
0x0000000000000123:  83 C6 02          add   si, 2
0x0000000000000126:  80 E1 07          and   cl, 7
0x0000000000000129:  C1 FA 03          sar   dx, 3
0x000000000000012c:  C1 E1 0D          shl   cx, 0xd
0x000000000000012f:  39 D0             cmp   ax, dx
0x0000000000000131:  7F 2C             jg    0x15f
0x0000000000000133:  75 04             jne   0x139
0x0000000000000135:  39 CB             cmp   bx, cx
0x0000000000000137:  77 26             ja    0x15f
0x0000000000000139:  C4 76 F8          les   si, ptr [bp - 8]
0x000000000000013c:  26 83 7C 0C FF    cmp   word ptr es:[si + 0xc], -1
0x0000000000000141:  74 24             je    0x167
0x0000000000000143:  89 F7             mov   di, si
0x0000000000000145:  26 8B 7D 0C       mov   di, word ptr es:[di + 0xc]
0x0000000000000149:  BA 00 E0          mov   dx, 0xe000
0x000000000000014c:  C1 E7 04          shl   di, 4
0x000000000000014f:  8E C2             mov   es, dx
0x0000000000000151:  BE 98 01          mov   si, 0x198
0x0000000000000154:  26 8A 55 05       mov   dl, byte ptr es:[di + 5]
0x0000000000000158:  83 C7 05          add   di, 5
0x000000000000015b:  3A 14             cmp   dl, byte ptr [si]
0x000000000000015d:  75 08             jne   0x167
0x000000000000015f:  30 C0             xor   al, al
0x0000000000000161:  C9                LEAVE_MACRO 
0x0000000000000162:  5F                pop   di
0x0000000000000163:  5E                pop   si
0x0000000000000164:  59                pop   cx
0x0000000000000165:  5B                pop   bx
0x0000000000000166:  C3                ret   
0x0000000000000167:  8B 4E E6          mov   cx, word ptr [bp - 0x1a]
0x000000000000016a:  8B 56 DA          mov   dx, word ptr [bp - 0x26]
0x000000000000016d:  50                push  ax
0x000000000000016e:  8B 46 D8          mov   ax, word ptr [bp - 0x28]
0x0000000000000171:  53                push  bx
0x0000000000000172:  8B 5E D6          mov   bx, word ptr [bp - 0x2a]
0x0000000000000175:  E8 7A 5B          call  0x5cf2
0x0000000000000178:  30 C0             xor   al, al
0x000000000000017a:  C9                LEAVE_MACRO 
0x000000000000017b:  5F                pop   di
0x000000000000017c:  5E                pop   si
0x000000000000017d:  59                pop   cx
0x000000000000017e:  5B                pop   bx
0x000000000000017f:  C3                ret   
0x0000000000000180:  C4 5E F8          les   bx, ptr [bp - 8]
0x0000000000000183:  26 8B 47 0C       mov   ax, word ptr es:[bx + 0xc]
0x0000000000000187:  26 8B 57 0A       mov   dx, word ptr es:[bx + 0xa]
0x000000000000018b:  8E 46 E0          mov   es, word ptr [bp - 0x20]
0x000000000000018e:  8B 5E DC          mov   bx, word ptr [bp - 0x24]
0x0000000000000191:  26 8B 4F 02       mov   cx, word ptr es:[bx + 2]
0x0000000000000195:  89 C3             mov   bx, ax
0x0000000000000197:  89 C8             mov   ax, cx
0x0000000000000199:  E8 0D 0E          call  0xfa9
0x000000000000019c:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000019f:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x00000000000001a2:  26 8B 1C          mov   bx, word ptr es:[si]
0x00000000000001a5:  26 8B 4C 02       mov   cx, word ptr es:[si + 2]
0x00000000000001a9:  E8 90 F8          call  0xfa3c
0x00000000000001ac:  C4 5E F8          les   bx, ptr [bp - 8]
0x00000000000001af:  26 8B 5F 0A       mov   bx, word ptr es:[bx + 0xa]
0x00000000000001b3:  C1 E3 04          shl   bx, 4
0x00000000000001b6:  C7 46 D4 00 E0    mov   word ptr [bp - 0x2c], 0xe000
0x00000000000001bb:  89 5E D2          mov   word ptr [bp - 0x2e], bx
0x00000000000001be:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x00000000000001c1:  C7 46 D0 00 E0    mov   word ptr [bp - 0x30], 0xe000
0x00000000000001c6:  26 8B 5F 0C       mov   bx, word ptr es:[bx + 0xc]
0x00000000000001ca:  89 46 E2          mov   word ptr [bp - 0x1e], ax
0x00000000000001cd:  C1 E3 04          shl   bx, 4
0x00000000000001d0:  8E 46 D4          mov   es, word ptr [bp - 0x2c]
0x00000000000001d3:  89 5E D4          mov   word ptr [bp - 0x2c], bx
0x00000000000001d6:  8B 5E D2          mov   bx, word ptr [bp - 0x2e]
0x00000000000001d9:  89 56 E4          mov   word ptr [bp - 0x1c], dx
0x00000000000001dc:  26 8B 0F          mov   cx, word ptr es:[bx]
0x00000000000001df:  8E 46 D0          mov   es, word ptr [bp - 0x30]
0x00000000000001e2:  8B 5E D4          mov   bx, word ptr [bp - 0x2c]
0x00000000000001e5:  26 3B 0F          cmp   cx, word ptr es:[bx]
0x00000000000001e8:  75 3B             jne   0x225
0x00000000000001ea:  C4 5E F8          les   bx, ptr [bp - 8]
0x00000000000001ed:  C7 46 D0 00 E0    mov   word ptr [bp - 0x30], 0xe000
0x00000000000001f2:  C7 46 D4 00 E0    mov   word ptr [bp - 0x2c], 0xe000
0x00000000000001f7:  26 8B 57 0A       mov   dx, word ptr es:[bx + 0xa]
0x00000000000001fb:  26 8B 4F 0C       mov   cx, word ptr es:[bx + 0xc]
0x00000000000001ff:  C1 E2 04          shl   dx, 4
0x0000000000000202:  8E 46 D0          mov   es, word ptr [bp - 0x30]
0x0000000000000205:  83 C2 02          add   dx, 2
0x0000000000000208:  C1 E1 04          shl   cx, 4
0x000000000000020b:  89 D3             mov   bx, dx
0x000000000000020d:  83 C1 02          add   cx, 2
0x0000000000000210:  26 8B 07          mov   ax, word ptr es:[bx]
0x0000000000000213:  8E 46 D4          mov   es, word ptr [bp - 0x2c]
0x0000000000000216:  89 CB             mov   bx, cx
0x0000000000000218:  26 3B 07          cmp   ax, word ptr es:[bx]
0x000000000000021b:  75 4A             jne   0x267
0x000000000000021d:  B0 01             mov   al, 1
0x000000000000021f:  C9                LEAVE_MACRO 
0x0000000000000220:  5F                pop   di
0x0000000000000221:  5E                pop   si
0x0000000000000222:  59                pop   cx
0x0000000000000223:  5B                pop   bx
0x0000000000000224:  C3                ret   
0x0000000000000225:  8B 0E 4A 1E       mov   cx, word ptr [0x1e4a]
0x0000000000000229:  83 E1 07          and   cx, 7
0x000000000000022c:  8B 1E 4A 1E       mov   bx, word ptr [0x1e4a]
0x0000000000000230:  C1 E1 0D          shl   cx, 0xd
0x0000000000000233:  C1 FB 03          sar   bx, 3
0x0000000000000236:  2B 0E A8 1C       sub   cx, word ptr [0x1ca8]
0x000000000000023a:  1B 1E AA 1C       sbb   bx, word ptr [0x1caa]
0x000000000000023e:  89 4E D2          mov   word ptr [bp - 0x2e], cx
0x0000000000000241:  89 5E D0          mov   word ptr [bp - 0x30], bx
0x0000000000000244:  89 D1             mov   cx, dx
0x0000000000000246:  8B 56 D0          mov   dx, word ptr [bp - 0x30]
0x0000000000000249:  89 C3             mov   bx, ax
0x000000000000024b:  8B 46 D2          mov   ax, word ptr [bp - 0x2e]
0x000000000000024e:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x0000000000000253:  3B 16 A6 1C       cmp   dx, word ptr [0x1ca6]
0x0000000000000257:  7E 03             jle   0x25c
0x0000000000000259:  E9 09 FE          jmp   0x65
0x000000000000025c:  75 8C             jne   0x1ea
0x000000000000025e:  3B 06 A4 1C       cmp   ax, word ptr [0x1ca4]
0x0000000000000262:  76 86             jbe   0x1ea
0x0000000000000264:  E9 FE FD          jmp   0x65
0x0000000000000267:  A1 48 1E          mov   ax, word ptr [0x1e48]
0x000000000000026a:  8B 5E E2          mov   bx, word ptr [bp - 0x1e]
0x000000000000026d:  30 E4             xor   ah, ah
0x000000000000026f:  8B 4E E4          mov   cx, word ptr [bp - 0x1c]
0x0000000000000272:  24 07             and   al, 7
0x0000000000000274:  8B 16 48 1E       mov   dx, word ptr [0x1e48]
0x0000000000000278:  C1 E0 0D          shl   ax, 0xd
0x000000000000027b:  C1 FA 03          sar   dx, 3
0x000000000000027e:  2B 06 A8 1C       sub   ax, word ptr [0x1ca8]
0x0000000000000282:  1B 16 AA 1C       sbb   dx, word ptr [0x1caa]
0x0000000000000286:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x000000000000028b:  3B 16 A6 1C       cmp   dx, word ptr [0x1ca6]
0x000000000000028f:  7C C8             jl    0x259
0x0000000000000291:  75 8A             jne   0x21d
0x0000000000000293:  3B 06 A4 1C       cmp   ax, word ptr [0x1ca4]
0x0000000000000297:  72 C0             jb    0x259
0x0000000000000299:  B0 01             mov   al, 1
0x000000000000029b:  C9                LEAVE_MACRO 
0x000000000000029c:  5F                pop   di
0x000000000000029d:  5E                pop   si
0x000000000000029e:  59                pop   cx
0x000000000000029f:  5B                pop   bx
0x00000000000002a0:  C3                ret   
0x00000000000002a1:  77 0D             ja    0x2b0
0x00000000000002a3:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000002a6:  26 8B 3C          mov   di, word ptr es:[si]
0x00000000000002a9:  81 C7 01 F0       add   di, 0xf001
0x00000000000002ad:  E9 CF FD          jmp   0x7f
0x00000000000002b0:  3D 00 08          cmp   ax, 0x800
0x00000000000002b3:  75 0C             jne   0x2c1
0x00000000000002b5:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000002b8:  26 8B 3C          mov   di, word ptr es:[si]
0x00000000000002bb:  83 C7 80          add   di, -0x80
0x00000000000002be:  E9 BE FD          jmp   0x7f
0x00000000000002c1:  3D 00 04          cmp   ax, 0x400
0x00000000000002c4:  74 03             je    0x2c9
0x00000000000002c6:  E9 C0 FD          jmp   0x89
0x00000000000002c9:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000002cc:  26 8B 3C          mov   di, word ptr es:[si]
0x00000000000002cf:  81 C7 00 FF       add   di, 0xff00
0x00000000000002d3:  E9 A9 FD          jmp   0x7f
0x00000000000002d6:  26 8B 44 05       mov   ax, word ptr es:[si + 5]
0x00000000000002da:  6B D0 2C          imul  dx, ax, 0x2c
0x00000000000002dd:  81 C2 04 40       add   dx, 0x4004
0x00000000000002e1:  89 56 F2          mov   word ptr [bp - 0xe], dx
0x00000000000002e4:  3B 16 F8 1E       cmp   dx, word ptr [0x1ef8]
0x00000000000002e8:  74 18             je    0x302
0x00000000000002ea:  6B D8 18          imul  bx, ax, 0x18
0x00000000000002ed:  B8 F5 6A          mov   ax, 0x6af5
0x00000000000002f0:  89 5E F4          mov   word ptr [bp - 0xc], bx
0x00000000000002f3:  89 5E DE          mov   word ptr [bp - 0x22], bx
0x00000000000002f6:  8E C0             mov   es, ax
0x00000000000002f8:  89 46 F6          mov   word ptr [bp - 0xa], ax
0x00000000000002fb:  26 F6 47 14 04    test  byte ptr es:[bx + 0x14], 4
0x0000000000000300:  75 08             jne   0x30a
0x0000000000000302:  B0 01             mov   al, 1
0x0000000000000304:  C9                LEAVE_MACRO 
0x0000000000000305:  5F                pop   di
0x0000000000000306:  5E                pop   si
0x0000000000000307:  59                pop   cx
0x0000000000000308:  5B                pop   bx
0x0000000000000309:  C3                ret   
0x000000000000030a:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000030d:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x0000000000000310:  26 8B 1C          mov   bx, word ptr es:[si]
0x0000000000000313:  26 8B 4C 02       mov   cx, word ptr es:[si + 2]
0x0000000000000317:  E8 22 F7          call  0xfa3c
0x000000000000031a:  C4 5E F4          les   bx, ptr [bp - 0xc]
0x000000000000031d:  89 46 E8          mov   word ptr [bp - 0x18], ax
0x0000000000000320:  89 56 EA          mov   word ptr [bp - 0x16], dx
0x0000000000000323:  26 8B 57 08       mov   dx, word ptr es:[bx + 8]
0x0000000000000327:  26 8B 47 0A       mov   ax, word ptr es:[bx + 0xa]
0x000000000000032b:  8B 5E F2          mov   bx, word ptr [bp - 0xe]
0x000000000000032e:  03 57 0A          add   dx, word ptr [bx + 0xa]
0x0000000000000331:  13 47 0C          adc   ax, word ptr [bx + 0xc]
0x0000000000000334:  8B 4E EA          mov   cx, word ptr [bp - 0x16]
0x0000000000000337:  89 C3             mov   bx, ax
0x0000000000000339:  89 D0             mov   ax, dx
0x000000000000033b:  89 DA             mov   dx, bx
0x000000000000033d:  8B 5E E8          mov   bx, word ptr [bp - 0x18]
0x0000000000000340:  2B 06 A8 1C       sub   ax, word ptr [0x1ca8]
0x0000000000000344:  1B 16 AA 1C       sbb   dx, word ptr [0x1caa]
0x0000000000000348:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x000000000000034d:  3B 16 A6 1C       cmp   dx, word ptr [0x1ca6]
0x0000000000000351:  7C 08             jl    0x35b
0x0000000000000353:  75 0E             jne   0x363
0x0000000000000355:  3B 06 A4 1C       cmp   ax, word ptr [0x1ca4]
0x0000000000000359:  73 08             jae   0x363
0x000000000000035b:  B0 01             mov   al, 1
0x000000000000035d:  C9                LEAVE_MACRO 
0x000000000000035e:  5F                pop   di
0x000000000000035f:  5E                pop   si
0x0000000000000360:  59                pop   cx
0x0000000000000361:  5B                pop   bx
0x0000000000000362:  C3                ret   
0x0000000000000363:  C4 5E F4          les   bx, ptr [bp - 0xc]
0x0000000000000366:  8B 4E EA          mov   cx, word ptr [bp - 0x16]
0x0000000000000369:  26 8B 47 08       mov   ax, word ptr es:[bx + 8]
0x000000000000036d:  26 8B 57 0A       mov   dx, word ptr es:[bx + 0xa]
0x0000000000000371:  8B 5E E8          mov   bx, word ptr [bp - 0x18]
0x0000000000000374:  2B 06 A8 1C       sub   ax, word ptr [0x1ca8]
0x0000000000000378:  1B 16 AA 1C       sbb   dx, word ptr [0x1caa]
0x000000000000037c:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x0000000000000381:  3B 16 A6 1C       cmp   dx, word ptr [0x1ca6]
0x0000000000000385:  7F D4             jg    0x35b
0x0000000000000387:  75 06             jne   0x38f
0x0000000000000389:  3B 06 A4 1C       cmp   ax, word ptr [0x1ca4]
0x000000000000038d:  77 CC             ja    0x35b
0x000000000000038f:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x0000000000000392:  3D 41 00          cmp   ax, 0x41
0x0000000000000395:  72 03             jb    0x39a
0x0000000000000397:  E9 C9 00          jmp   0x463
0x000000000000039a:  3D 40 00          cmp   ax, 0x40
0x000000000000039d:  75 14             jne   0x3b3
0x000000000000039f:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000003a2:  26 8B 3C          mov   di, word ptr es:[si]
0x00000000000003a5:  81 C7 00 D8       add   di, 0xd800
0x00000000000003a9:  26 8B 44 02       mov   ax, word ptr es:[si + 2]
0x00000000000003ad:  15 FF FF          adc   ax, 0xffff
0x00000000000003b0:  89 46 FC          mov   word ptr [bp - 4], ax
0x00000000000003b3:  8B 4E FC          mov   cx, word ptr [bp - 4]
0x00000000000003b6:  A1 10 1A          mov   ax, word ptr [0x1a10]
0x00000000000003b9:  8B 16 12 1A       mov   dx, word ptr [0x1a12]
0x00000000000003bd:  89 FB             mov   bx, di
0x00000000000003bf:  9A 98 5B 81 0A    lcall 0xa81:0x5b98
0x00000000000003c4:  8B 1E 08 1A       mov   bx, word ptr [0x1a08]
0x00000000000003c8:  8B 4E FC          mov   cx, word ptr [bp - 4]
0x00000000000003cb:  01 C3             add   bx, ax
0x00000000000003cd:  89 5E F0          mov   word ptr [bp - 0x10], bx
0x00000000000003d0:  89 FB             mov   bx, di
0x00000000000003d2:  A1 0A 1A          mov   ax, word ptr [0x1a0a]
0x00000000000003d5:  11 D0             adc   ax, dx
0x00000000000003d7:  8B 16 16 1A       mov   dx, word ptr [0x1a16]
0x00000000000003db:  89 46 EC          mov   word ptr [bp - 0x14], ax
0x00000000000003de:  A1 14 1A          mov   ax, word ptr [0x1a14]
0x00000000000003e1:  9A 98 5B 81 0A    lcall 0xa81:0x5b98
0x00000000000003e6:  8B 1E 0C 1A       mov   bx, word ptr [0x1a0c]
0x00000000000003ea:  01 C3             add   bx, ax
0x00000000000003ec:  89 5E EE          mov   word ptr [bp - 0x12], bx
0x00000000000003ef:  8B 3E 0E 1A       mov   di, word ptr [0x1a0e]
0x00000000000003f3:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000003f6:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x00000000000003f9:  26 8B 1C          mov   bx, word ptr es:[si]
0x00000000000003fc:  26 8B 4C 02       mov   cx, word ptr es:[si + 2]
0x0000000000000400:  11 D7             adc   di, dx
0x0000000000000402:  E8 37 F6          call  0xfa3c
0x0000000000000405:  8B 1E A4 1C       mov   bx, word ptr [0x1ca4]
0x0000000000000409:  8B 36 A6 1C       mov   si, word ptr [0x1ca6]
0x000000000000040d:  89 D1             mov   cx, dx
0x000000000000040f:  89 5E D4          mov   word ptr [bp - 0x2c], bx
0x0000000000000412:  89 F2             mov   dx, si
0x0000000000000414:  89 C3             mov   bx, ax
0x0000000000000416:  8B 46 D4          mov   ax, word ptr [bp - 0x2c]
0x0000000000000419:  9A 98 5B 81 0A    lcall 0xa81:0x5b98
0x000000000000041e:  8B 5E DE          mov   bx, word ptr [bp - 0x22]
0x0000000000000421:  03 06 A8 1C       add   ax, word ptr [0x1ca8]
0x0000000000000425:  13 16 AA 1C       adc   dx, word ptr [0x1caa]
0x0000000000000429:  8E 46 F6          mov   es, word ptr [bp - 0xa]
0x000000000000042c:  26 F6 47 16 08    test  byte ptr es:[bx + 0x16], 8
0x0000000000000431:  74 66             je    0x499
0x0000000000000433:  8B 5E EE          mov   bx, word ptr [bp - 0x12]
0x0000000000000436:  52                push  dx
0x0000000000000437:  89 F9             mov   cx, di
0x0000000000000439:  8B 56 EC          mov   dx, word ptr [bp - 0x14]
0x000000000000043c:  50                push  ax
0x000000000000043d:  8B 46 F0          mov   ax, word ptr [bp - 0x10]
0x0000000000000440:  E8 AF 58          call  0x5cf2
0x0000000000000443:  A1 F4 1E          mov   ax, word ptr [0x1ef4]
0x0000000000000446:  85 C0             test  ax, ax
0x0000000000000448:  75 03             jne   0x44d
0x000000000000044a:  E9 12 FD          jmp   0x15f
0x000000000000044d:  8B 16 F8 1E       mov   dx, word ptr [0x1ef8]
0x0000000000000451:  89 C1             mov   cx, ax
0x0000000000000453:  8B 46 F2          mov   ax, word ptr [bp - 0xe]
0x0000000000000456:  89 D3             mov   bx, dx
0x0000000000000458:  E8 79 EE          call  0xf2d4
0x000000000000045b:  30 C0             xor   al, al
0x000000000000045d:  C9                LEAVE_MACRO 
0x000000000000045e:  5F                pop   di
0x000000000000045f:  5E                pop   si
0x0000000000000460:  59                pop   cx
0x0000000000000461:  5B                pop   bx
0x0000000000000462:  C3                ret   
0x0000000000000463:  77 0D             ja    0x472
0x0000000000000465:  8E 46 FE          mov   es, word ptr [bp - 2]
0x0000000000000468:  26 8B 3C          mov   di, word ptr es:[si]
0x000000000000046b:  81 C7 01 D8       add   di, 0xd801
0x000000000000046f:  E9 37 FF          jmp   0x3a9
0x0000000000000472:  3D 00 08          cmp   ax, 0x800
0x0000000000000475:  75 0D             jne   0x484
0x0000000000000477:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000047a:  26 8B 3C          mov   di, word ptr es:[si]
0x000000000000047d:  81 C7 C0 FE       add   di, 0xfec0
0x0000000000000481:  E9 25 FF          jmp   0x3a9
0x0000000000000484:  3D 00 04          cmp   ax, 0x400
0x0000000000000487:  74 03             je    0x48c
0x0000000000000489:  E9 27 FF          jmp   0x3b3
0x000000000000048c:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000048f:  26 8B 3C          mov   di, word ptr es:[si]
0x0000000000000492:  81 C7 80 FD       add   di, 0xfd80
0x0000000000000496:  E9 10 FF          jmp   0x3a9
0x0000000000000499:  8B 5E EE          mov   bx, word ptr [bp - 0x12]
0x000000000000049c:  FF 36 F4 1E       push  word ptr [0x1ef4]
0x00000000000004a0:  89 F9             mov   cx, di
0x00000000000004a2:  52                push  dx
0x00000000000004a3:  8B 56 EC          mov   dx, word ptr [bp - 0x14]
0x00000000000004a6:  50                push  ax
0x00000000000004a7:  8B 46 F0          mov   ax, word ptr [bp - 0x10]
0x00000000000004aa:  E8 05 59          call  0x5db2
0x00000000000004ad:  EB 94             jmp   0x443

ENDP


;boolean __near PTR_AimTraverse (intercept_t __far* in);

PROC PTR_AimTraverse_ NEAR
PUBLIC PTR_AimTraverse_

0x0000000000000000:  53                push  bx
0x0000000000000001:  51                push  cx
0x0000000000000002:  56                push  si
0x0000000000000003:  57                push  di
0x0000000000000004:  55                push  bp
0x0000000000000005:  89 E5             mov   bp, sp
0x0000000000000007:  83 EC 1C          sub   sp, 0x1c
0x000000000000000a:  89 C6             mov   si, ax
0x000000000000000c:  89 56 FE          mov   word ptr [bp - 2], dx
0x000000000000000f:  8E C2             mov   es, dx
0x0000000000000011:  26 80 7C 04 00    cmp   byte ptr es:[si + 4], 0
0x0000000000000016:  74 17             je    0x2f
0x0000000000000018:  B8 BA E9          mov   ax, 0xe9ba
0x000000000000001b:  26 8B 5C 05       mov   bx, word ptr es:[si + 5]
0x000000000000001f:  8E C0             mov   es, ax
0x0000000000000021:  26 F6 07 04       test  byte ptr es:[bx], 4
0x0000000000000025:  75 0B             jne   0x32
0x0000000000000027:  30 C0             xor   al, al
0x0000000000000029:  C9                LEAVE_MACRO 
0x000000000000002a:  5F                pop   di
0x000000000000002b:  5E                pop   si
0x000000000000002c:  59                pop   cx
0x000000000000002d:  5B                pop   bx
0x000000000000002e:  C3                ret   
0x000000000000002f:  E9 3B 01          jmp   0x16d
0x0000000000000032:  B8 01 E8          mov   ax, 0xe801
0x0000000000000035:  8E C2             mov   es, dx
0x0000000000000037:  C7 46 FC 00 70    mov   word ptr [bp - 4], 0x7000
0x000000000000003c:  26 8B 5C 05       mov   bx, word ptr es:[si + 5]
0x0000000000000040:  26 8B 7C 05       mov   di, word ptr es:[si + 5]
0x0000000000000044:  8E 46 FC          mov   es, word ptr [bp - 4]
0x0000000000000047:  C1 E7 04          shl   di, 4
0x000000000000004a:  C1 E3 02          shl   bx, 2
0x000000000000004d:  26 8B 4D 0C       mov   cx, word ptr es:[di + 0xc]
0x0000000000000051:  26 8B 55 0A       mov   dx, word ptr es:[di + 0xa]
0x0000000000000055:  8E C0             mov   es, ax
0x0000000000000057:  26 8B 47 02       mov   ax, word ptr es:[bx + 2]
0x000000000000005b:  89 CB             mov   bx, cx
0x000000000000005d:  E8 D5 11          call  0x1235
0x0000000000000060:  A1 4A 1E          mov   ax, word ptr [0x1e4a]
0x0000000000000063:  89 7E F4          mov   word ptr [bp - 0xc], di
0x0000000000000066:  3B 06 48 1E       cmp   ax, word ptr [0x1e48]
0x000000000000006a:  7D BB             jge   0x27
0x000000000000006c:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000006f:  C7 46 E6 00 E0    mov   word ptr [bp - 0x1a], 0xe000
0x0000000000000074:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x0000000000000077:  26 8B 1C          mov   bx, word ptr es:[si]
0x000000000000007a:  26 8B 4C 02       mov   cx, word ptr es:[si + 2]
0x000000000000007e:  C7 46 E4 00 E0    mov   word ptr [bp - 0x1c], 0xe000
0x0000000000000083:  E8 42 FC          call  0xfcc8
0x0000000000000086:  8E 46 FC          mov   es, word ptr [bp - 4]
0x0000000000000089:  89 C6             mov   si, ax
0x000000000000008b:  26 8B 4D 0A       mov   cx, word ptr es:[di + 0xa]
0x000000000000008f:  26 8B 5D 0C       mov   bx, word ptr es:[di + 0xc]
0x0000000000000093:  C1 E1 04          shl   cx, 4
0x0000000000000096:  8E 46 E6          mov   es, word ptr [bp - 0x1a]
0x0000000000000099:  89 CF             mov   di, cx
0x000000000000009b:  C1 E3 04          shl   bx, 4
0x000000000000009e:  26 8B 0D          mov   cx, word ptr es:[di]
0x00000000000000a1:  8E 46 E4          mov   es, word ptr [bp - 0x1c]
0x00000000000000a4:  89 56 EA          mov   word ptr [bp - 0x16], dx
0x00000000000000a7:  26 3B 0F          cmp   cx, word ptr es:[bx]
0x00000000000000aa:  74 3F             je    0xeb
0x00000000000000ac:  8B 1E 4A 1E       mov   bx, word ptr [0x1e4a]
0x00000000000000b0:  30 FF             xor   bh, bh
0x00000000000000b2:  8B 3E 4A 1E       mov   di, word ptr [0x1e4a]
0x00000000000000b6:  80 E3 07          and   bl, 7
0x00000000000000b9:  89 D1             mov   cx, dx
0x00000000000000bb:  C1 E3 0D          shl   bx, 0xd
0x00000000000000be:  C1 FF 03          sar   di, 3
0x00000000000000c1:  2B 1E A8 1C       sub   bx, word ptr [0x1ca8]
0x00000000000000c5:  89 5E E6          mov   word ptr [bp - 0x1a], bx
0x00000000000000c8:  1B 3E AA 1C       sbb   di, word ptr [0x1caa]
0x00000000000000cc:  89 C3             mov   bx, ax
0x00000000000000ce:  89 FA             mov   dx, di
0x00000000000000d0:  8B 46 E6          mov   ax, word ptr [bp - 0x1a]
0x00000000000000d3:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x00000000000000d8:  BB 5C 06          mov   bx, 0x65c
0x00000000000000db:  3B 57 02          cmp   dx, word ptr [bx + 2]
0x00000000000000de:  7F 06             jg    0xe6
0x00000000000000e0:  75 09             jne   0xeb
0x00000000000000e2:  3B 07             cmp   ax, word ptr [bx]
0x00000000000000e4:  76 05             jbe   0xeb
0x00000000000000e6:  89 07             mov   word ptr [bx], ax
0x00000000000000e8:  89 57 02          mov   word ptr [bx + 2], dx
0x00000000000000eb:  8E 46 FC          mov   es, word ptr [bp - 4]
0x00000000000000ee:  8B 5E F4          mov   bx, word ptr [bp - 0xc]
0x00000000000000f1:  B9 00 E0          mov   cx, 0xe000
0x00000000000000f4:  8B 7E F4          mov   di, word ptr [bp - 0xc]
0x00000000000000f7:  26 8B 5F 0A       mov   bx, word ptr es:[bx + 0xa]
0x00000000000000fb:  26 8B 7D 0C       mov   di, word ptr es:[di + 0xc]
0x00000000000000ff:  C1 E3 04          shl   bx, 4
0x0000000000000102:  C1 E7 04          shl   di, 4
0x0000000000000105:  8E C1             mov   es, cx
0x0000000000000107:  83 C7 02          add   di, 2
0x000000000000010a:  26 8B 47 02       mov   ax, word ptr es:[bx + 2]
0x000000000000010e:  83 C3 02          add   bx, 2
0x0000000000000111:  26 3B 05          cmp   ax, word ptr es:[di]
0x0000000000000114:  74 36             je    0x14c
0x0000000000000116:  A1 48 1E          mov   ax, word ptr [0x1e48]
0x0000000000000119:  8B 4E EA          mov   cx, word ptr [bp - 0x16]
0x000000000000011c:  30 E4             xor   ah, ah
0x000000000000011e:  8B 16 48 1E       mov   dx, word ptr [0x1e48]
0x0000000000000122:  24 07             and   al, 7
0x0000000000000124:  89 F3             mov   bx, si
0x0000000000000126:  C1 E0 0D          shl   ax, 0xd
0x0000000000000129:  C1 FA 03          sar   dx, 3
0x000000000000012c:  2B 06 A8 1C       sub   ax, word ptr [0x1ca8]
0x0000000000000130:  1B 16 AA 1C       sbb   dx, word ptr [0x1caa]
0x0000000000000134:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x0000000000000139:  BB 58 06          mov   bx, 0x658
0x000000000000013c:  3B 57 02          cmp   dx, word ptr [bx + 2]
0x000000000000013f:  7C 06             jl    0x147
0x0000000000000141:  75 09             jne   0x14c
0x0000000000000143:  3B 07             cmp   ax, word ptr [bx]
0x0000000000000145:  73 05             jae   0x14c
0x0000000000000147:  89 07             mov   word ptr [bx], ax
0x0000000000000149:  89 57 02          mov   word ptr [bx + 2], dx
0x000000000000014c:  BE 58 06          mov   si, 0x658
0x000000000000014f:  BB 5C 06          mov   bx, 0x65c
0x0000000000000152:  8B 44 02          mov   ax, word ptr [si + 2]
0x0000000000000155:  8B 14             mov   dx, word ptr [si]
0x0000000000000157:  3B 47 02          cmp   ax, word ptr [bx + 2]
0x000000000000015a:  7D 03             jge   0x15f
0x000000000000015c:  E9 C8 FE          jmp   0x27
0x000000000000015f:  75 04             jne   0x165
0x0000000000000161:  3B 17             cmp   dx, word ptr [bx]
0x0000000000000163:  76 F7             jbe   0x15c
0x0000000000000165:  B0 01             mov   al, 1
0x0000000000000167:  C9                LEAVE_MACRO 
0x0000000000000168:  5F                pop   di
0x0000000000000169:  5E                pop   si
0x000000000000016a:  59                pop   cx
0x000000000000016b:  5B                pop   bx
0x000000000000016c:  C3                ret   
0x000000000000016d:  26 6B 44 05 2C    imul  ax, word ptr es:[si + 5], 0x2c
0x0000000000000172:  05 04 40          add   ax, 0x4004
0x0000000000000175:  89 46 F8          mov   word ptr [bp - 8], ax
0x0000000000000178:  3B 06 F8 1E       cmp   ax, word ptr [0x1ef8]
0x000000000000017c:  74 17             je    0x195
0x000000000000017e:  26 6B 7C 05 18    imul  di, word ptr es:[si + 5], 0x18
0x0000000000000183:  B8 F5 6A          mov   ax, 0x6af5
0x0000000000000186:  89 46 FA          mov   word ptr [bp - 6], ax
0x0000000000000189:  8E C0             mov   es, ax
0x000000000000018b:  89 7E E8          mov   word ptr [bp - 0x18], di
0x000000000000018e:  26 F6 45 14 04    test  byte ptr es:[di + 0x14], 4
0x0000000000000193:  75 08             jne   0x19d
0x0000000000000195:  B0 01             mov   al, 1
0x0000000000000197:  C9                LEAVE_MACRO 
0x0000000000000198:  5F                pop   di
0x0000000000000199:  5E                pop   si
0x000000000000019a:  59                pop   cx
0x000000000000019b:  5B                pop   bx
0x000000000000019c:  C3                ret   
0x000000000000019d:  8E C2             mov   es, dx
0x000000000000019f:  A1 F0 1E          mov   ax, word ptr [0x1ef0]
0x00000000000001a2:  26 8B 1C          mov   bx, word ptr es:[si]
0x00000000000001a5:  26 8B 4C 02       mov   cx, word ptr es:[si + 2]
0x00000000000001a9:  E8 1C FB          call  0xfcc8
0x00000000000001ac:  C4 5E F8          les   bx, ptr [bp - 8]
0x00000000000001af:  89 56 EE          mov   word ptr [bp - 0x12], dx
0x00000000000001b2:  89 46 EC          mov   word ptr [bp - 0x14], ax
0x00000000000001b5:  8B 4E EE          mov   cx, word ptr [bp - 0x12]
0x00000000000001b8:  26 8B 45 08       mov   ax, word ptr es:[di + 8]
0x00000000000001bc:  26 8B 55 0A       mov   dx, word ptr es:[di + 0xa]
0x00000000000001c0:  03 47 0A          add   ax, word ptr [bx + 0xa]
0x00000000000001c3:  13 57 0C          adc   dx, word ptr [bx + 0xc]
0x00000000000001c6:  8B 5E EC          mov   bx, word ptr [bp - 0x14]
0x00000000000001c9:  2B 06 A8 1C       sub   ax, word ptr [0x1ca8]
0x00000000000001cd:  1B 16 AA 1C       sbb   dx, word ptr [0x1caa]
0x00000000000001d1:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x00000000000001d6:  BB 5C 06          mov   bx, 0x65c
0x00000000000001d9:  89 46 F6          mov   word ptr [bp - 0xa], ax
0x00000000000001dc:  89 D6             mov   si, dx
0x00000000000001de:  89 46 F0          mov   word ptr [bp - 0x10], ax
0x00000000000001e1:  8B 47 02          mov   ax, word ptr [bx + 2]
0x00000000000001e4:  89 56 F2          mov   word ptr [bp - 0xe], dx
0x00000000000001e7:  39 C2             cmp   dx, ax
0x00000000000001e9:  7C 09             jl    0x1f4
0x00000000000001eb:  75 0F             jne   0x1fc
0x00000000000001ed:  8B 46 F6          mov   ax, word ptr [bp - 0xa]
0x00000000000001f0:  3B 07             cmp   ax, word ptr [bx]
0x00000000000001f2:  73 08             jae   0x1fc
0x00000000000001f4:  B0 01             mov   al, 1
0x00000000000001f6:  C9                LEAVE_MACRO 
0x00000000000001f7:  5F                pop   di
0x00000000000001f8:  5E                pop   si
0x00000000000001f9:  59                pop   cx
0x00000000000001fa:  5B                pop   bx
0x00000000000001fb:  C3                ret   
0x00000000000001fc:  8E 46 FA          mov   es, word ptr [bp - 6]
0x00000000000001ff:  8B 5E EC          mov   bx, word ptr [bp - 0x14]
0x0000000000000202:  8B 4E EE          mov   cx, word ptr [bp - 0x12]
0x0000000000000205:  26 8B 45 08       mov   ax, word ptr es:[di + 8]
0x0000000000000209:  26 8B 55 0A       mov   dx, word ptr es:[di + 0xa]
0x000000000000020d:  2B 06 A8 1C       sub   ax, word ptr [0x1ca8]
0x0000000000000211:  1B 16 AA 1C       sbb   dx, word ptr [0x1caa]
0x0000000000000215:  9A E5 5E 81 0A    lcall 0xa81:0x5ee5
0x000000000000021a:  BB 58 06          mov   bx, 0x658
0x000000000000021d:  89 C1             mov   cx, ax
0x000000000000021f:  89 C7             mov   di, ax
0x0000000000000221:  89 D0             mov   ax, dx
0x0000000000000223:  3B 57 02          cmp   dx, word ptr [bx + 2]
0x0000000000000226:  7F CC             jg    0x1f4
0x0000000000000228:  75 04             jne   0x22e
0x000000000000022a:  3B 0F             cmp   cx, word ptr [bx]
0x000000000000022c:  77 C6             ja    0x1f4
0x000000000000022e:  8B 56 F6          mov   dx, word ptr [bp - 0xa]
0x0000000000000231:  3B 77 02          cmp   si, word ptr [bx + 2]
0x0000000000000234:  7F 06             jg    0x23c
0x0000000000000236:  75 0F             jne   0x247
0x0000000000000238:  3B 17             cmp   dx, word ptr [bx]
0x000000000000023a:  76 0B             jbe   0x247
0x000000000000023c:  8B 17             mov   dx, word ptr [bx]
0x000000000000023e:  89 56 F0          mov   word ptr [bp - 0x10], dx
0x0000000000000241:  8B 57 02          mov   dx, word ptr [bx + 2]
0x0000000000000244:  89 56 F2          mov   word ptr [bp - 0xe], dx
0x0000000000000247:  BB 5C 06          mov   bx, 0x65c
0x000000000000024a:  3B 47 02          cmp   ax, word ptr [bx + 2]
0x000000000000024d:  7C 06             jl    0x255
0x000000000000024f:  75 09             jne   0x25a
0x0000000000000251:  3B 3F             cmp   di, word ptr [bx]
0x0000000000000253:  73 05             jae   0x25a
0x0000000000000255:  8B 3F             mov   di, word ptr [bx]
0x0000000000000257:  8B 47 02          mov   ax, word ptr [bx + 2]
0x000000000000025a:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x000000000000025d:  89 1E F6 1E       mov   word ptr [0x1ef6], bx
0x0000000000000261:  03 7E F0          add   di, word ptr [bp - 0x10]
0x0000000000000264:  8B 56 F2          mov   dx, word ptr [bp - 0xe]
0x0000000000000267:  11 C2             adc   dx, ax
0x0000000000000269:  89 F8             mov   ax, di
0x000000000000026b:  8B 5E E8          mov   bx, word ptr [bp - 0x18]
0x000000000000026e:  D1 FA             sar   dx, 1
0x0000000000000270:  D1 D8             rcr   ax, 1
0x0000000000000272:  89 1E A0 1C       mov   word ptr [0x1ca0], bx
0x0000000000000276:  A3 A4 1C          mov   word ptr [0x1ca4], ax
0x0000000000000279:  8B 46 FA          mov   ax, word ptr [bp - 6]
0x000000000000027c:  89 16 A6 1C       mov   word ptr [0x1ca6], dx
0x0000000000000280:  A3 A2 1C          mov   word ptr [0x1ca2], ax
0x0000000000000283:  30 C0             xor   al, al
0x0000000000000285:  C9                LEAVE_MACRO 
0x0000000000000286:  5F                pop   di
0x0000000000000287:  5E                pop   si
0x0000000000000288:  59                pop   cx
0x0000000000000289:  5B                pop   bx
0x000000000000028a:  C3                ret   

ENDP



;boolean __near PTR_AimTraverse (intercept_t __far* in);

PROC PTR_AimTraverse_ NEAR
PUBLIC PTR_AimTraverse_


ENDP


@





END
