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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA
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
;   bp + 8  v1y ?

;   bp - 2 is p1
;   bp - 4 is linedx ?

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
push  dx
mov   di, bx	; di has linedy
mov   si, cx	; si has v1x
xor   dx, dx	; dx is 0
cmp   ax, ST_VERTICAL_HIGH
jae   non_zero_slopetype

; ST_HORIZONTAL_HIGH case
mov   ax, word ptr [bp + 8]	; v1y
mov   cx, word ptr ds:[_tmbbox + (BOXTOP * 4) + 2]
cmp   cx, ax
jg    set_p1_to_1_2

jne   set_p1_to_0
cmp   word ptr ds:[_tmbbox + (BOXTOP * 4)], 0	; check lo bits..
jne   set_p1_to_1_2

set_p1_to_0:
xor   bl, bl

check_p2_2:

cmp   ax, word ptr ds:[_tmbbox + (BOXBOTTOM * 4) + 2]
jl    set_p2_to_1_2

jne   set_p2_to_0
cmp   word ptr ds:[_tmbbox + (BOXBOTTOM * 4)], 0	; check lo bits..
jne   set_p2_to_1_2

set_p2_to_0:
xor   al, al

check_linedx:

cmp   word ptr [bp - 4], 0
jl    xor_p1_p2

done_with_switchblock_boxonlineside_bl:  ; bl has p1
cmp   al, bl
jne   jump_to_return_minusone_boxonlineside
LEAVE_MACRO
pop   di
pop   si
ret   2



set_p1_to_1_2:
mov   bl, 1
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


mov   ax, cx
cmp   cx, word ptr ds:[_tmbbox + (BOXRIGHT * 4) + 2]
jg    set_p1_to_1
xor   bl, bl
check_p2:

cmp   ax, word ptr ds:[_tmbbox + (BOXLEFT * 4) + 2]
jg    set_p2_to_1
xor   al, al
check_linedy:

test  di, di		; test linedy
jge   done_with_switchblock_boxonlineside_bl
xor_p1_p2:
xor   al, 1
xor   bl, 1

jmp   done_with_switchblock_boxonlineside_bl
set_p2_to_1:
mov   al, 1
jmp   check_linedy

jump_to_return_minusone_boxonlineside:
jmp   return_minusone_boxonlineside
set_p1_to_1:
mov   bl, 1
jmp   check_p2


not_vertical_high:
cmp   ax, ST_NEGATIVE_HIGH
je    negative_high_slopetype
; ST_POSITIVE_HIGH

push  word ptr [bp + 8]
push  cx
push  bx
push  word ptr [bp - 4]
les   bx, dword ptr ds:[_tmbbox + BOXTOP * 4]  ; sizeof fixed_t_union
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXLEFT * 4]
mov   dx, es
call  P_PointOnLineSide_
mov   byte ptr [bp - 2], al
push  word ptr [bp + 8]
push  si
push  di

push  word ptr [bp - 4]

les   bx, dword ptr ds:[_tmbbox + BOXBOTTOM * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXRIGHT * 4]
mov   dx, es

call  P_PointOnLineSide_

done_with_switchblock_boxonlineside:
cmp   al, byte ptr [bp - 2] ; cmp p1/p2
jne   jump_to_return_minusone_boxonlineside
LEAVE_MACRO
pop   di
pop   si
ret   2

negative_high_slopetype:
; ST_NEGATIVE_HIGH
push  word ptr [bp + 8]
push  cx
push  bx

push  word ptr [bp - 4]
les   bx, dword ptr ds:[_tmbbox + BOXTOP * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXRIGHT * 4]
mov   dx, es



call  P_PointOnLineSide_
push  word ptr [bp + 8]
mov   byte ptr [bp - 2], al
push  si
push  di

push  word ptr [bp - 4]
les   bx, dword ptr ds:[_tmbbox + BOXBOTTOM * 4]
mov   cx, es
les   ax, dword ptr ds:[_tmbbox + BOXLEFT * 4]
mov   dx, es

call  P_PointOnLineSide_

jmp   done_with_switchblock_boxonlineside
return_minusone_boxonlineside:
mov   al, -1
LEAVE_MACRO
pop   di
pop   si
ret   2

ENDP

COMMENT @

PROC P_PointOnDivlineSide_ NEAR
PUBLIC P_PointOnDivlineSide_ 

0x0000000000000000:  56                push  si
0x0000000000000001:  57                push  di
0x0000000000000002:  55                push  bp
0x0000000000000003:  89 E5             mov   bp, sp
0x0000000000000005:  83 EC 04          sub   sp, 4
0x0000000000000008:  89 C7             mov   di, ax
0x000000000000000a:  89 DE             mov   si, bx
0x000000000000000c:  89 D0             mov   ax, dx
0x000000000000000e:  89 CA             mov   dx, cx
0x0000000000000010:  8B 1E 22 1A       mov   bx, word ptr [0x1a22]
0x0000000000000014:  0B 1E 20 1A       or    bx, word ptr [0x1a20]
0x0000000000000018:  75 33             jne   0x4d
0x000000000000001a:  3B 06 1A 1A       cmp   ax, word ptr [0x1a1a]
0x000000000000001e:  7C 08             jl    0x28
0x0000000000000020:  75 20             jne   0x42
0x0000000000000022:  3B 3E 18 1A       cmp   di, word ptr [0x1a18]
0x0000000000000026:  77 1A             ja    0x42
0x0000000000000028:  A1 26 1A          mov   ax, word ptr [0x1a26]
0x000000000000002b:  85 C0             test  ax, ax
0x000000000000002d:  7F 09             jg    0x38
0x000000000000002f:  75 0D             jne   0x3e
0x0000000000000031:  83 3E 24 1A 00    cmp   word ptr [0x1a24], 0
0x0000000000000036:  76 06             jbe   0x3e
0x0000000000000038:  B0 01             mov   al, 1
0x000000000000003a:  C9                LEAVE_MACRO
0x000000000000003b:  5F                pop   di
0x000000000000003c:  5E                pop   si
0x000000000000003d:  C3                ret   
0x000000000000003e:  30 C0             xor   al, al
0x0000000000000040:  EB F8             jmp   0x3a
0x0000000000000042:  A1 26 1A          mov   ax, word ptr [0x1a26]
0x0000000000000045:  85 C0             test  ax, ax
0x0000000000000047:  7C EF             jl    0x38
0x0000000000000049:  30 C0             xor   al, al
0x000000000000004b:  EB ED             jmp   0x3a
0x000000000000004d:  8B 1E 26 1A       mov   bx, word ptr [0x1a26]
0x0000000000000051:  0B 1E 24 1A       or    bx, word ptr [0x1a24]
0x0000000000000055:  75 32             jne   0x89
0x0000000000000057:  A1 1E 1A          mov   ax, word ptr [0x1a1e]
0x000000000000005a:  39 C1             cmp   cx, ax
0x000000000000005c:  7C 08             jl    0x66
0x000000000000005e:  75 13             jne   0x73
0x0000000000000060:  3B 36 1C 1A       cmp   si, word ptr [0x1a1c]
0x0000000000000064:  77 0D             ja    0x73
0x0000000000000066:  A1 22 1A          mov   ax, word ptr [0x1a22]
0x0000000000000069:  85 C0             test  ax, ax
0x000000000000006b:  7C CB             jl    0x38
0x000000000000006d:  30 C0             xor   al, al
0x000000000000006f:  C9                LEAVE_MACRO
0x0000000000000070:  5F                pop   di
0x0000000000000071:  5E                pop   si
0x0000000000000072:  C3                ret   
0x0000000000000073:  A1 22 1A          mov   ax, word ptr [0x1a22]
0x0000000000000076:  85 C0             test  ax, ax
0x0000000000000078:  7F BE             jg    0x38
0x000000000000007a:  75 07             jne   0x83
0x000000000000007c:  83 3E 20 1A 00    cmp   word ptr [0x1a20], 0
0x0000000000000081:  77 B5             ja    0x38
0x0000000000000083:  30 C0             xor   al, al
0x0000000000000085:  C9                LEAVE_MACRO
0x0000000000000086:  5F                pop   di
0x0000000000000087:  5E                pop   si
0x0000000000000088:  C3                ret   
0x0000000000000089:  8B 16 26 1A       mov   dx, word ptr [0x1a26]
0x000000000000008d:  89 FB             mov   bx, di
0x000000000000008f:  89 CF             mov   di, cx
0x0000000000000091:  2B 1E 18 1A       sub   bx, word ptr [0x1a18]
0x0000000000000095:  1B 06 1A 1A       sbb   ax, word ptr [0x1a1a]
0x0000000000000099:  2B 36 1C 1A       sub   si, word ptr [0x1a1c]
0x000000000000009d:  1B 3E 1E 1A       sbb   di, word ptr [0x1a1e]
0x00000000000000a1:  33 16 22 1A       xor   dx, word ptr [0x1a22]
0x00000000000000a5:  31 C2             xor   dx, ax
0x00000000000000a7:  31 FA             xor   dx, di
0x00000000000000a9:  89 76 FE          mov   word ptr [bp - 2], si
0x00000000000000ac:  F6 C6 80          test  dh, 0x80
0x00000000000000af:  74 12             je    0xc3
0x00000000000000b1:  33 06 26 1A       xor   ax, word ptr [0x1a26]
0x00000000000000b5:  F6 C4 80          test  ah, 0x80
0x00000000000000b8:  74 03             je    0xbd
0x00000000000000ba:  E9 7B FF          jmp   0x38
0x00000000000000bd:  30 C0             xor   al, al
0x00000000000000bf:  C9                LEAVE_MACRO
0x00000000000000c0:  5F                pop   di
0x00000000000000c1:  5E                pop   si
0x00000000000000c2:  C3                ret   
0x00000000000000c3:  8B 16 24 1A       mov   dx, word ptr [0x1a24]
0x00000000000000c7:  8B 36 26 1A       mov   si, word ptr [0x1a26]
0x00000000000000cb:  89 C1             mov   cx, ax
0x00000000000000cd:  89 D0             mov   ax, dx
0x00000000000000cf:  89 F2             mov   dx, si
0x00000000000000d1:  9A 6A 5C 81 0A    lcall 0xa81:0x5c6a
0x00000000000000d6:  8B 1E 20 1A       mov   bx, word ptr [0x1a20]
0x00000000000000da:  8B 0E 22 1A       mov   cx, word ptr [0x1a22]
0x00000000000000de:  89 46 FC          mov   word ptr [bp - 4], ax
0x00000000000000e1:  89 D6             mov   si, dx
0x00000000000000e3:  8B 46 FE          mov   ax, word ptr [bp - 2]
0x00000000000000e6:  89 FA             mov   dx, di
0x00000000000000e8:  9A 6A 5C 81 0A    lcall 0xa81:0x5c6a
0x00000000000000ed:  39 F2             cmp   dx, si
0x00000000000000ef:  7F C9             jg    0xba
0x00000000000000f1:  75 05             jne   0xf8
0x00000000000000f3:  3B 46 FC          cmp   ax, word ptr [bp - 4]
0x00000000000000f6:  73 C2             jae   0xba
0x00000000000000f8:  30 C0             xor   al, al
0x00000000000000fa:  C9                LEAVE_MACRO
0x00000000000000fb:  5F                pop   di
0x00000000000000fc:  5E                pop   si
0x00000000000000fd:  C3                ret  

ENDP

@
END
