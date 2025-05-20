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
	;fixed_t	x, 
	;fixed_t	y, 
	; int16_t linedx, 
	; int16_t linedy,
	; int16_t v1x,
	; int16_t v1y);

; DX:AX   x
; CX:BX   y
; bp + 4  linedx
; bp + 6  linedy
; bp + 8  v1x
; bp + 0Ah  v1y

PROC P_PointOnLineSide_ NEAR
PUBLIC P_PointOnLineSide_ 

push  si
push  di
push  bp
mov   bp, sp

mov   di, ax			; di gets x low 	dx:di x
mov   si, bx			; si gets y low
mov   bx, word ptr [bp + 0Ch]  ; bx gets linedx
;mov   ax, cx			; ax gets y hibits    ax:si y
cmp   word ptr [bp + 8], 0	; compare linedx

;    if (!linedx) {
jne   linedx_nonzero
;		if (x <= temp.w) {
cmp   dx, bx			; compare hi bits
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
pop   di
pop   si
ret   8

x_smaller_than_v1x:
cmp   word ptr [bp + 0Ah], 0	; compare linedy
jle   return_0_pointonlineside

return_1_pointonlineside:
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
ret   8

linedx_nonzero:

cmp   word ptr [bp + 0Ah], 0	; compare linedy
jne   linedy_nonzero
cmp   cx, word ptr [bp + 0Eh]	; v1y
jl    y_smaller_than_v1y
jne   y_greater_than_v1y
test  si, si
jbe   y_smaller_than_v1y
y_greater_than_v1y:
cmp   word ptr [bp + 8], 0		; compare linedx
jle   return_0_pointonlineside
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
ret   8

y_smaller_than_v1y:
cmp   word ptr [bp + 8], 0
jge   return_0_pointonlineside
return_1_pointonlineside_2:
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
ret   8

linedy_nonzero:


;	temp.h.intbits = v1x;
;   dx = (x - temp.w);
;	temp.h.intbits = v1y;
;   dy = (y - temp.w);

sub   dx, bx					; dx:di = "dx"

sub   cx, word ptr [bp + 0Eh]	; cx:si = "dy"


;    left = FixedMul1632 ( linedy , dx );
;    right = FixedMul1632 ( linedx , dy);


mov   bx, di					; cx:bx = dx
mov   di, cx					; store dy hi
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
jl    exit_pointonlineside_return_0
jne   return_1_pointonlineside_2
cmp   ax, di
jae   return_1_pointonlineside_2
exit_pointonlineside_return_0:
xor   al, al
LEAVE_MACRO
pop   di
pop   si
ret   8

ENDP

COMMENT @

PROC P_BoxOnLineSide_ NEAR
PUBLIC P_BoxOnLineSide_ 

0x0000000000000000:  56             push  si
0x0000000000000001:  57             push  di
0x0000000000000002:  55             push  bp
0x0000000000000003:  89 E5          mov   bp, sp
0x0000000000000005:  83 EC 06       sub   sp, 6
0x0000000000000008:  52             push  dx
0x0000000000000009:  89 DF          mov   di, bx
0x000000000000000b:  89 CE          mov   si, cx
0x000000000000000d:  31 D2          xor   dx, dx
0x000000000000000f:  3D 00 40       cmp   ax, 0x4000
0x0000000000000012:  73 47          jae   0x5b
0x0000000000000014:  85 C0          test  ax, ax
0x0000000000000016:  75 32          jne   0x4a
0x0000000000000018:  BB F0 04       mov   bx, 0x4f0
0x000000000000001b:  8B 46 08       mov   ax, word ptr [bp + 8]
0x000000000000001e:  8B 4F 02       mov   cx, word ptr [bx + 2]
0x0000000000000021:  39 C1          cmp   cx, ax
0x0000000000000023:  7F 07          jg    0x2c
0x0000000000000025:  75 31          jne   0x58
0x0000000000000027:  83 3F 00       cmp   word ptr [bx], 0
0x000000000000002a:  76 2C          jbe   0x58
0x000000000000002c:  B3 01          mov   bl, 1
0x000000000000002e:  88 5E FE       mov   byte ptr [bp - 2], bl
0x0000000000000031:  BB F4 04       mov   bx, 0x4f4
0x0000000000000034:  3B 47 02       cmp   ax, word ptr [bx + 2]
0x0000000000000037:  7C 06          jl    0x3f
0x0000000000000039:  75 53          jne   0x8e
0x000000000000003b:  3B 17          cmp   dx, word ptr [bx]
0x000000000000003d:  73 4F          jae   0x8e
0x000000000000003f:  B0 01          mov   al, 1
0x0000000000000041:  88 46 FC       mov   byte ptr [bp - 4], al
0x0000000000000044:  83 7E F8 00    cmp   word ptr [bp - 8], 0
0x0000000000000048:  7C 39          jl    0x83
0x000000000000004a:  8A 46 FE       mov   al, byte ptr [bp - 2]
0x000000000000004d:  3A 46 FC       cmp   al, byte ptr [bp - 4]
0x0000000000000050:  75 3E          jne   0x90
0x0000000000000052:  C9             leave 
0x0000000000000053:  5F             pop   di
0x0000000000000054:  5E             pop   si
0x0000000000000055:  C2 02 00       ret   2
0x0000000000000058:  E9 91 00       jmp   0xec
0x000000000000005b:  77 3A          ja    0x97
0x000000000000005d:  BB FC 04       mov   bx, 0x4fc
0x0000000000000060:  89 C8          mov   ax, cx
0x0000000000000062:  3B 4F 02       cmp   cx, word ptr [bx + 2]
0x0000000000000065:  7F 2C          jg    0x93
0x0000000000000067:  30 DB          xor   bl, bl
0x0000000000000069:  88 5E FE       mov   byte ptr [bp - 2], bl
0x000000000000006c:  BB F8 04       mov   bx, 0x4f8
0x000000000000006f:  3B 47 02       cmp   ax, word ptr [bx + 2]
0x0000000000000072:  7F 06          jg    0x7a
0x0000000000000074:  75 1F          jne   0x95
0x0000000000000076:  3B 17          cmp   dx, word ptr [bx]
0x0000000000000078:  76 1B          jbe   0x95
0x000000000000007a:  B0 01          mov   al, 1
0x000000000000007c:  88 46 FC       mov   byte ptr [bp - 4], al
0x000000000000007f:  85 FF          test  di, di
0x0000000000000081:  7D C7          jge   0x4a
0x0000000000000083:  34 01          xor   al, 1
0x0000000000000085:  80 76 FE 01    xor   byte ptr [bp - 2], 1
0x0000000000000089:  88 46 FC       mov   byte ptr [bp - 4], al
0x000000000000008c:  EB BC          jmp   0x4a
0x000000000000008e:  EB 61          jmp   0xf1
0x0000000000000090:  E9 C2 00       jmp   0x155
0x0000000000000093:  EB 61          jmp   0xf6
0x0000000000000095:  EB 64          jmp   0xfb
0x0000000000000097:  3D 00 C0       cmp   ax, 0xc000
0x000000000000009a:  74 64          je    0x100
0x000000000000009c:  3D 00 80       cmp   ax, 0x8000
0x000000000000009f:  75 A9          jne   0x4a
0x00000000000000a1:  FF 76 08       push  word ptr [bp + 8]
0x00000000000000a4:  51             push  cx
0x00000000000000a5:  53             push  bx
0x00000000000000a6:  BB F0 04       mov   bx, 0x4f0
0x00000000000000a9:  8B 07          mov   ax, word ptr [bx]
0x00000000000000ab:  8B 4F 02       mov   cx, word ptr [bx + 2]
0x00000000000000ae:  BB F8 04       mov   bx, 0x4f8
0x00000000000000b1:  8B 17          mov   dx, word ptr [bx]
0x00000000000000b3:  FF 76 F8       push  word ptr [bp - 8]
0x00000000000000b6:  89 56 FA       mov   word ptr [bp - 6], dx
0x00000000000000b9:  8B 57 02       mov   dx, word ptr [bx + 2]
0x00000000000000bc:  89 C3          mov   bx, ax
0x00000000000000be:  8B 46 FA       mov   ax, word ptr [bp - 6]
0x00000000000000c1:  E8 92 FE       call  0xff56
0x00000000000000c4:  FF 76 08       push  word ptr [bp + 8]
0x00000000000000c7:  BB F4 04       mov   bx, 0x4f4
0x00000000000000ca:  88 46 FE       mov   byte ptr [bp - 2], al
0x00000000000000cd:  56             push  si
0x00000000000000ce:  8B 07          mov   ax, word ptr [bx]
0x00000000000000d0:  8B 4F 02       mov   cx, word ptr [bx + 2]
0x00000000000000d3:  57             push  di
0x00000000000000d4:  BB FC 04       mov   bx, 0x4fc
0x00000000000000d7:  FF 76 F8       push  word ptr [bp - 8]
0x00000000000000da:  8B 37          mov   si, word ptr [bx]
0x00000000000000dc:  8B 57 02       mov   dx, word ptr [bx + 2]
0x00000000000000df:  89 C3          mov   bx, ax
0x00000000000000e1:  89 F0          mov   ax, si
0x00000000000000e3:  E8 70 FE       call  0xff56
0x00000000000000e6:  88 46 FC       mov   byte ptr [bp - 4], al
0x00000000000000e9:  E9 5E FF       jmp   0x4a
0x00000000000000ec:  30 DB          xor   bl, bl
0x00000000000000ee:  E9 3D FF       jmp   0x2e
0x00000000000000f1:  30 C0          xor   al, al
0x00000000000000f3:  E9 4B FF       jmp   0x41
0x00000000000000f6:  B3 01          mov   bl, 1
0x00000000000000f8:  E9 6E FF       jmp   0x69
0x00000000000000fb:  30 C0          xor   al, al
0x00000000000000fd:  E9 7C FF       jmp   0x7c
0x0000000000000100:  FF 76 08       push  word ptr [bp + 8]
0x0000000000000103:  51             push  cx
0x0000000000000104:  53             push  bx
0x0000000000000105:  BB F0 04       mov   bx, 0x4f0
0x0000000000000108:  FF 76 F8       push  word ptr [bp - 8]
0x000000000000010b:  8B 07          mov   ax, word ptr [bx]
0x000000000000010d:  8B 57 02       mov   dx, word ptr [bx + 2]
0x0000000000000110:  BB FC 04       mov   bx, 0x4fc
0x0000000000000113:  89 56 FA       mov   word ptr [bp - 6], dx
0x0000000000000116:  8B 17          mov   dx, word ptr [bx]
0x0000000000000118:  8B 5F 02       mov   bx, word ptr [bx + 2]
0x000000000000011b:  8B 4E FA       mov   cx, word ptr [bp - 6]
0x000000000000011e:  89 5E FA       mov   word ptr [bp - 6], bx
0x0000000000000121:  89 C3          mov   bx, ax
0x0000000000000123:  89 D0          mov   ax, dx
0x0000000000000125:  8B 56 FA       mov   dx, word ptr [bp - 6]
0x0000000000000128:  E8 2B FE       call  0xff56
0x000000000000012b:  FF 76 08       push  word ptr [bp + 8]
0x000000000000012e:  BB F4 04       mov   bx, 0x4f4
0x0000000000000131:  88 46 FE       mov   byte ptr [bp - 2], al
0x0000000000000134:  56             push  si
0x0000000000000135:  8B 07          mov   ax, word ptr [bx]
0x0000000000000137:  8B 4F 02       mov   cx, word ptr [bx + 2]
0x000000000000013a:  57             push  di
0x000000000000013b:  BB F8 04       mov   bx, 0x4f8
0x000000000000013e:  FF 76 F8       push  word ptr [bp - 8]
0x0000000000000141:  8B 17          mov   dx, word ptr [bx]
0x0000000000000143:  8B 77 02       mov   si, word ptr [bx + 2]
0x0000000000000146:  89 C3          mov   bx, ax
0x0000000000000148:  89 D0          mov   ax, dx
0x000000000000014a:  89 F2          mov   dx, si
0x000000000000014c:  E8 07 FE       call  0xff56
0x000000000000014f:  88 46 FC       mov   byte ptr [bp - 4], al
0x0000000000000152:  E9 F5 FE       jmp   0x4a
0x0000000000000155:  B0 FF          mov   al, 0xff
0x0000000000000157:  C9             leave 
0x0000000000000158:  5F             pop   di
0x0000000000000159:  5E             pop   si
0x000000000000015a:  C2 02 00       ret   2
0x000000000000015d:  FC             cld   

ENDP

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
0x000000000000003a:  C9                leave 
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
0x000000000000006f:  C9                leave 
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
0x0000000000000085:  C9                leave 
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
0x00000000000000bf:  C9                leave 
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
0x00000000000000fa:  C9                leave 
0x00000000000000fb:  5F                pop   di
0x00000000000000fc:  5E                pop   si
0x00000000000000fd:  C3                ret  

ENDP

@
END
