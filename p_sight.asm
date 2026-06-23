; Copyright (C) 1993-1996 Id Software, Inc.
; Copyright (C) 1993-2008 Raven Software
; Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
; Copyright (C) 2023-2026 Patrick Goncalves (sqpat17)
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




INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO_NO_MEDIUM
;.CODE PARA
EXTRN FixedDiv_MapLocal_:NEAR
EXTRN FixedMul_8_8_:NEAR
EXTRN FixedMul_16_0_:NEAR


SEGMENT P_SIGHT_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:P_SIGHT_TEXT

PROC    P_SIGHT_STARTMARKER_ 
PUBLIC  P_SIGHT_STARTMARKER_
ENDP

JMP_SHORT_REL8_OPCODE  = 0EBh
TWO_BYTE_NOP		   = 0C089h
MOV_AL_IMM8_OPCODE 	   = 0B0h
JE_IMM8_OPCODE 		   = 074h
RET_OPCODE 			   = 0C3h
JS_IMM8_OPCODE 		   = 078h
JNS_IMM8_OPCODE        = 079h


ALIGN_MACRO
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

; 9000:0100 or 9010
_anims:
PUBLIC _anims
REPT 192
 db 0
ENDM

; 9000:01C0 or 901C
_switchlist:
PUBLIC _switchlist
REPT 200
 db 0
ENDM


ALIGN_MACRO
_divline_side_lookups:
dw  OFFSET P_DivlineSide16_ - OFFSET SELFMODIFY_psight_divlinesize16_call_1_AFTER
dw  OFFSET P_DivlineSide16_ - OFFSET SELFMODIFY_psight_divlinesize16_call_2_AFTER

dw  OFFSET P_DivlineSide16_DXZero_ - OFFSET SELFMODIFY_psight_divlinesize16_call_1_AFTER
dw  OFFSET P_DivlineSide16_DXZero_ - OFFSET SELFMODIFY_psight_divlinesize16_call_2_AFTER

dw  OFFSET P_DivlineSide16_DYZero_ - OFFSET SELFMODIFY_psight_divlinesize16_call_1_AFTER
dw  OFFSET P_DivlineSide16_DYZero_ - OFFSET SELFMODIFY_psight_divlinesize16_call_2_AFTER



; boolean __far P_CheckSight (  mobj_t __near* t1, mobj_t __near* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos ) {

; ax = t1 (near ptr)
; dx = t2 (near ptr)
; bx = t1_pos (far offset)
; cx = t2_pos (far offset)
; return in carry
ALIGN_MACRO
PROC    P_CheckSight_ NEAR
PUBLIC  P_CheckSight_
  PUSH SI
  PUSH DI
    
  XCHG AX, DI
  MOV SI, DX
    
  MOV DX, REJECTMATRIX_SEGMENT
  MOV ES, DX
    
  MOV AX, WORD PTR ds:[_numsectors]
  MUL WORD PTR ds:[DI + MOBJ_T.m_secnum]
  ADD AX, WORD PTR ds:[SI + MOBJ_T.m_secnum]
  ADC DX, 0

IF COMPISA LE COMPILE_286
  MOV DH, CL ; DH can't change lookup value

  MOV   CL, 7
  AND   CL, AL

  SHIFT32_MACRO_RIGHT DL AX 3
  XCHG  AX, SI

  MOV   DL, 1
  SHL   DL, CL
  
  TEST  DL, BYTE PTR ES:[SI]
  JZ    not_in_reject_table
ELSE
  MOVZX EDX, DX
  SHL   EDX, 12
  BT    WORD PTR ES:[EDX], AX
  JNC   not_in_reject_table
ENDIF
  CLC
  POP  DI
  POP  SI
  RET
ALIGN_MACRO

not_in_reject_table:
IF COMPISA LE COMPILE_286
  MOV  CL, DH ; restore CL
  XCHG AX, SI ; restore SI with t2
ENDIF

; cx/bx properly have t1/t2

inc   word ptr ds:[_validcount_global]
mov   ax, word ptr ds:[_validcount_global]
mov   word ptr cs:[SELFMODIFY_psight_cmp_validcount+3], ax
mov   word ptr cs:[SELFMODIFY_psight_set_validcount+3], ax




mov   es, word ptr ds:[_MOBJPOSLIST_SEGMENT_PTR] ; todo go straight to ds with this once everything moves to stack

push  bp
mov   bp, cx ; hold t2

; bx tied up holding t2_pos for a while
; bp has t1_pos
; si has t2
; di has t1

;    sightzstart = t1_pos->z.w + t1->height.w - (t1->height.w>>2);

les   cx, dword ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   ax, es
les   di, dword ptr ds:[di + MOBJ_T.m_height + 0] ; last use of t1
mov   dx, es
add   cx, di
adc   ax, dx			; ax:cx result

SHIFT32_MACRO_RIGHT dx di 2

sub   cx, di
sbb   ax, dx

; do while this is in ax
mov   word ptr cs:[SELFMODIFY_psight_sightzstart_hi_1+2], ax
mov   word ptr cs:[SELFMODIFY_psight_sightzstart_hi_2+2], ax
mov   word ptr cs:[SELFMODIFY_psight_sightzstart_lo_1+1], cx
mov   word ptr cs:[SELFMODIFY_psight_sightzstart_lo_2+1], cx

xchg  ax, di  ; swap. todo find a way to work this out

; bx tied up holding t2_pos for a while
; bp has t1_pos
; si has t2
; di:cx has sightzstart
; ax, dx free

;    topslope = (t2_pos->z.w+t2->height.w) - sightzstart;
les   ax, dword ptr ds:[si + MOBJ_T.m_height + 0] ; last use of t2 
mov   dx, es

mov   ds, word ptr ds:[_MOBJPOSLIST_SEGMENT_PTR]

les   si, dword ptr ds:[bp + MOBJ_POS_T.mp_z + 0] ; si is free
add   ax, si
mov   si, es
adc   dx, si

mov   si, bp  ; si gets mobjpos_t
mov   bp, di  ; bp gets sightzstart hi (todo remove)
mov   di, OFFSET _topslope

sub   ax, cx			; subtract sightzstart	
sbb   dx, bp

; swap es and ds...
push  ss
pop   es

; bp:cx is still sightzstart
; es:di is pointing to our vars, but wille ventually be pushes
; ds:si is t1_pos. ds_bx is t2_pos

; TODO all this should go on stack (push not stosw.)

; write topslope
stosw
xchg  ax, dx
stosw

; cx:bp has sightzstart 

mov   ax, word ptr ds:[si + MOBJ_POS_T.mp_z + 0]
mov   dx, word ptr ds:[si + MOBJ_POS_T.mp_z + 2]
sub   ax, cx			; subtract sightzstart. last use of bx/bp
sbb   dx, bp
; write bottomslope
stosw
xchg  ax, dx
stosw	


;di = _cachedt2x
lodsw

mov   dx, ds
mov   es, dx
mov   dx, cs
mov   ds, dx


mov   word ptr ds:[SELFMODIFY_psight_t2x_lo_1+1], ax
mov   word ptr ds:[SELFMODIFY_psight_t2x_lo_2+1], ax

xchg  ax, dx
lods  word ptr es:[si]
mov   word ptr ds:[SELFMODIFY_psight_t2x_hi_1+1], ax
mov   word ptr ds:[SELFMODIFY_psight_t2x_hi_2+1], ax

xchg  ax, cx	; cx:dx has t2x


;di = _cachedt2y
lods  word ptr es:[si]
mov   word ptr ds:[SELFMODIFY_psight_t2y_lo_1+1], ax
mov   word ptr ds:[SELFMODIFY_psight_t2y_lo_2+1], ax
xchg  ax, bp
lods  word ptr es:[si]
mov   word ptr ds:[SELFMODIFY_psight_t2y_hi_1+1], ax
mov   word ptr ds:[SELFMODIFY_psight_t2y_hi_2+1], ax



mov   si, bx    ; bx now free.


;di = _strace dx/y
xchg  ax, di  ; store t2y hi in di.   di:bp

lods  word ptr es:[si]
mov   word ptr ds:[SELFMODIFY_psight_strace_x_lo_4+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_x_lo_5+1], ax

mov   bl, JE_IMM8_OPCODE
test  ax, ax
je    strace_dx_lo_zero
mov   bl, RET_OPCODE
strace_dx_lo_zero:
mov   byte ptr ds:[SELFMODIFY_do_equals_2_check_dx_16], bl

xchg  ax, bx

lods  word ptr es:[si]
sub   dx, bx
sbb   cx, ax
neg   bx
mov   word ptr ds:[SELFMODIFY_psight_strace_x_lo_1+1], bx
mov   word ptr ds:[SELFMODIFY_psight_strace_x_hi_2+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_x_hi_4+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_x_hi_5+1], ax

adc   ax, 0

mov   word ptr ds:[SELFMODIFY_psight_strace_x_hi_1+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_x_hi_3+1], ax



lods  word ptr es:[si]
mov   word ptr ds:[SELFMODIFY_psight_strace_y_lo_1+1], ax

mov   word ptr ds:[SELFMODIFY_psight_strace_y_lo_4+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_y_lo_5+1], ax
mov   bl, JMP_SHORT_REL8_OPCODE
test  ax, ax
je    strace_dy_lo_zero
mov   bl, MOV_AL_IMM8_OPCODE
strace_dy_lo_zero:
mov   byte ptr ds:[SELFMODIFY_do_equals_2_check_dy_16], bl

xchg  ax, bx
lods  word ptr es:[si]
mov   word ptr ds:[SELFMODIFY_psight_strace_y_hi_1+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_y_hi_2+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_y_hi_4+1], ax
mov   word ptr ds:[SELFMODIFY_psight_strace_y_hi_5+1], ax

sub   bp, bx
sbb   di, ax

neg   bx

adc   ax, 0
mov   word ptr ds:[SELFMODIFY_psight_strace_y_hi_3+2], ax	



; _strace dx/dy


mov    word ptr ds:[SELFMODIFY_psight_strace_dx_lo_1+1], dx
mov    ax, cx 
mov    word ptr ds:[SELFMODIFY_psight_strace_dx_hi_1+1], ax
mov    word ptr ds:[SELFMODIFY_psight_strace_dx_hi_2+1], ax

rol    ax, 1
and    al, 1
mov    ah, al
xor    al, 1
; if negative, 0100
; if positive, 0001
mov    word ptr ds:[SELFMODIFY_psight_dx_greater_than_zero+1], ax



xchg   ax, di  ; get t2dy back
mov    word ptr ds:[SELFMODIFY_psight_strace_dy_lo_1+1], bp
mov    word ptr ds:[SELFMODIFY_psight_strace_dy_hi_1+1], ax
mov    word ptr ds:[SELFMODIFY_psight_strace_dy_hi_2+1], ax

mov    bx, ax  ; sign backup
rol    ax, 1
and    al, 1
mov    ah, al
xor    al, 1
; if negative, 0100
; if positive, 0001
mov    word ptr ds:[SELFMODIFY_psight_dy_greater_than_zero+1], ax

mov    ax, cx
xor    ax, bx  ; xor signs
mov    al, JS_IMM8_OPCODE 
mov    ah, ch
jns    dy_dx_signs_equal
inc    ax  ;  mov    al,JNS_IMM8_OPCODE
mov    ah, 	bh
dy_dx_signs_equal:
mov    byte ptr ds:[SELFMODIFY_psight_left_right_sign_compare], al
mov    byte ptr ds:[SELFMODIFY_psight_left_right_xor+2], ah

; todo make this a little better
mov    ax, 4
or     dx, cx
jz     use_dx_zero_jmp
mov    al, 8
or     bx, bp
jz     use_dy_zero_jmp	
mov    al, 0
use_dx_zero_jmp:
use_dy_zero_jmp:
xchg   ax, bx
les    ax, dword ptr ds:[bx+_divline_side_lookups]
mov   word ptr ds:[SELFMODIFY_psight_divlinesize16_call_1+1], ax
mov   word ptr ds:[SELFMODIFY_psight_divlinesize16_call_2+1], es



MOV   AX, WORD PTR SS:[_numnodes]
DEC   AX
MOV   DX, NODES_SEGMENT
MOV   DS, DX

call  P_CrossBSPNode_ ; return carry thru 

mov   dx, ss
mov   ds, dx

pop   bp
pop   di
pop   si
ret 

ENDP


;int16_t __near P_DivlineSide ( fixed_t_union	x, fixed_t_union	y, divline_t __near*	node ) {

; node si
; dx:ax x
; cx:bx y


ALIGN_MACRO
PROC    P_DivlineSide_ NEAR
PUBLIC  P_DivlineSide_
    MOV  CX, WORD PTR DS:[SI + NODE_T.n_dx]
    JCXZ node_dx_zero
    MOV  DI, WORD PTR DS:[SI + NODE_T.n_dy]
    TEST DI, DI
    JZ   node_dy_zero
    SUB  AX, WORD PTR DS:[SI + NODE_T.n_x]
    IMUL DI
    MOV  DI, ES
    SUB  DI, WORD PTR DS:[SI + NODE_T.n_y]
    XCHG AX, DI
    MOV  BP, DX
    IMUL CX
    SUB  AX, DI
    SBB  DX, BP
    JS   return_0
    OR   AX, DX
    JZ   return_2
    MOV  AL, 1
    RET


ALIGN_MACRO
node_dy_zero:
    MOV  DI, WORD PTR DS:[SI + NODE_T.n_y]
    XOR  AX, DI
    OR   DX, AX
    JZ   return_2
    XOR  AX, AX
    CMP  AX, BP
	MOV  BP, ES
    SBB  DI, BP
    JGE  test_dx_below_zero
    NEG  CX
ALIGN_MACRO
test_dx_below_zero:
    SHL  CX, 1
    RCL  AX, 1
    RET
ENDP
ALIGN_MACRO
test_dy_above_zero:
    MOV AX, WORD PTR DS:[SI + NODE_T.n_dy]
    NEG AX
    ROL AX, 1
    AND AL, 1
    RET

ALIGN_MACRO
node_dx_zero:
    SUB AX, WORD PTR DS:[SI + NODE_T.n_x]
    JS test_dy_above_zero
    OR AX, DX
    JZ return_2
    XOR AX, AX
    MOV AH, BYTE PTR DS:[SI + NODE_T.n_dy + 1]
    ROL AX, 1
    RET


ALIGN_MACRO
return_0:
    XOR  AX, AX
    RET
ALIGN_MACRO
return_2:
    MOV  AL, 2
    RET


; bx is always equal to strace
ALIGN_MACRO
PROC    P_DivlineSide16_ NEAR
PUBLIC  P_DivlineSide16_

SELFMODIFY_psight_strace_y_hi_3:
    sub  si, 01000h	  		; dy = (y - node->y);

SELFMODIFY_psight_strace_x_hi_3:
	sub  ax, 01000h			; dx = (x - node->x);


    mov  dx, si
	xor  dx, ax  ; 

SELFMODIFY_psight_left_right_sign_compare:
    js   divline_16_return_sign_based_result   ; todo branch test?
SELFMODIFY_psight_left_right_sign_compare_AFTER:
SELFMODIFY_psight_strace_dy_hi_2:
	mov  dx, 01000h
	IMUL DX			; left =  (node->dy>>FRACBITS) * (dx>>FRACBITS);

    mov  di, dx
    xchg ax, si  ; store results. get y


SELFMODIFY_psight_strace_dx_hi_2:
	mov  dx, 01000h
		
	IMUL DX			; right = (dy>>FRACBITS) * (node->dx>>FRACBITS);
	
    SUB  AX, SI
    SBB  DX, DI		; return right > left
    JS   return_0
    OR   AX, DX
    JZ   return_2
    MOV  AL, 1
    RET
	ALIGN_MACRO
divline_16_return_sign_based_result:
  ; return right > left, so
  ; return 1 if left was negative, 0 if its positive...
SELFMODIFY_psight_left_right_xor:
    xor  ah, 010h  ; xor x by dy if js, by dx if jns
    rol  ax, 1
	and  al, 1
    ret

ENDP

ALIGN_MACRO
PROC P_DivlineSide16_DYZero_ NEAR

SELFMODIFY_psight_strace_y_hi_2:
    mov  dx, 01000h
    
SELFMODIFY_do_equals_2_check_dy_16:
	jmp  do_equals_2_check_dy_16  ; mov al, imm8 if lo != 0
continue_dy_check:
SELFMODIFY_psight_dx_greater_than_zero:
    mov  ax, 01000h ; return values. 0100 or 00001
	cmp  si, dx  ; compare hi y vs y
	jl   return_dx_less_than_zero
return_dx_greater_than_zero:
    RET
do_equals_2_check_dy_16:
	cmp  ax, dx  ; compare x == y. maintaining bug compatibility!
    jne  continue_dy_check
	mov  al, 2
	ret   
return_dx_less_than_zero:
    mov  al, ah	
    ret
ENDP


ALIGN_MACRO
PROC P_DivlineSide16_DXZero_ NEAR
SELFMODIFY_psight_strace_x_hi_2:
    cmp  ax, 01000h  ; compare hi 
SELFMODIFY_psight_dy_greater_than_zero:
    mov  ax, 01000h ; return values. 0100 or 00001
    jg   return_dy_greater_than_zero
    mov  al, ah	   ;  dy_less_than_zero 
SELFMODIFY_do_equals_2_check_dx_16:
    je   return_2   ; je becomes RET unless strace dx lo = 0
return_dy_greater_than_zero: ; result already in al
    RET

ENDP






; what the heck?
; openwatcom turned this from a recursive to iterative function??? hello?? 


; todo update to new bsp traversal method?

;return carry
ALIGN_MACRO
cross_bsp_node_return_true:
    STC
cross_bsp_node_return_false:
    POP SI
    RET
ALIGN_MACRO
PROC    P_CrossBSPNode_ NEAR
PUBLIC  P_CrossBSPNode_
    ; Register state
    ; DS = NODES_SEGMENT
    ; SS = FIXED_DS_SEGMENT
    ; AX = bspnum
    SHL  AX, 1
    JC   is_subsector
    PUSH SI
iterate_bsp_recursion:
    SHL  AX, 1
    SHL  AX, 1
    XCHG AX, SI
SELFMODIFY_psight_strace_x_lo_4:
    MOV  DX, 01000h
SELFMODIFY_psight_strace_x_hi_4:
    MOV  AX, 01000h
SELFMODIFY_psight_strace_y_hi_4:
    MOV  BP, 01000h
    MOV  ES, BP
SELFMODIFY_psight_strace_y_lo_4:
    MOV  BP, 01000h
    ; Register state
    ; DS = NODES_SEGMENT
    ; SS = FIXED_DS_SEGMENT
    ; AX:DS = _strace.x
    ; ES:BP = _strace.y
    ; SI = bspnum * 8
    CALL P_DivlineSide_
    AND  AX, 1
    PUSH AX ; Store side for later
    XCHG AX, BX
    SHL  BX, 1
    SHR  SI, 1
    MOV  AX, NODE_CHILDREN_SEGMENT
    MOV  ES, AX
    MOV  AX, WORD PTR ES:[BX + SI]
    ; Register state
    ; DS = NODES_SEGMENT
    ; SS = FIXED_DS_SEGMENT
    ; AX = bsp->children[side]
    ; BX = side * 2
    ; SI = bspnum * 4
    CALL P_CrossBSPNode_
    POP  BX ; Retrieve side
    JNC  cross_bsp_node_return_false
    SHL  SI, 1
SELFMODIFY_psight_t2x_lo_1:
    MOV  DX, 01000h
SELFMODIFY_psight_t2x_hi_1:
    MOV  AX, 01000h
SELFMODIFY_psight_t2y_hi_1:
    MOV  BP, 01000h
    MOV  ES, BP
SELFMODIFY_psight_t2y_lo_1:
    MOV  BP, 01000h
    ; Register state
    ; DS = NODES_SEGMENT
    ; SS = FIXED_DS_SEGMENT
    ; AX:DX = t2.x
    ; BX = side
    ; ES:BP = t2.y
    ; SI = bspnum * 8
    CALL P_DivlineSide_
    CMP  BL, AL
    JE   cross_bsp_node_return_true
    MOV  AX, NODE_CHILDREN_SEGMENT
    MOV  ES, AX
    XOR  BL, 1
    SHL  BL, 1
    SHR  SI, 1
    MOV  AX, WORD PTR ES:[BX + SI]
    SHL  AX, 1
    JNC  iterate_bsp_recursion
    POP  SI
is_subsector:
    XOR  AX, -2 ; 0xFFFE
    JZ   is_subsector_neg_one
	NOT  AX
    SHR  AX, 1
is_subsector_neg_one:
    

STACK_DIVLINE_POSITION = 0Eh

P_CrossSubsector_:
PUBLIC P_CrossSubsector_
; INLINED  P_CrossSubsector_ 
; return in carry

; bp - 2	lineflags
; bp - 4    frac hibits
; bp - 6	frac lobits
; bp - 8    (divl end)
; bp - 0A   (divl)
; bp - 0C   (divl)
; bp - 0E   divl start (NODE_T struct)




mov   bx, ax		; todo swap this argument order
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax
mov   dx, SUBSECTORS_SEGMENT
mov   al, byte ptr es:[bx]			; count todo selfmodify this
SHIFT_MACRO_SMALL shl bx 2
xor   ah, ah
mov   es, dx
test  ax, ax
je    cross_subsector_return_1 ; no stack frame, ds modification necessary

push  ss
pop   ds
push  si
push  bp
mov   bp, sp
sub   sp, 0Eh

xchg  ax, cx   ; cx gets iterator count
mov   si, word ptr es:[bx + SUBSECTOR_T.ss_firstline]		; get segnum/firstline   ; todo move after test?
sal   si, 1 ; segnum (word ptr)

mov   di, SEG_LINEDEFS_SEGMENT
mov   es, di
mov   di, LINES_PHYSICS_SEGMENT
mov   ds, di
cross_subsector_mainloop:
ENSUREALIGN_908:
lods  word ptr es:[si]
mov   bx, ax
SHIFT_MACRO_SMALL shl bx 4

SELFMODIFY_psight_cmp_validcount:
cmp   word ptr ds:[bx + LINE_PHYSICS_T.lp_validcount], 01000h
jne   do_full_loop_iteration
cross_subsector_mainloop_increment:

loop  cross_subsector_mainloop	

mov   dx, NODES_SEGMENT
mov   ds, dx

LEAVE_MACRO 
pop   si
cross_subsector_return_1:  ; ds/bp not modified
stc
ret   
ALIGN_MACRO
do_full_loop_iteration:

push  cx ; loop iterator popped on reentry to iterator
push  si ; segnum popped on reentry to iterator

mov   dx, LINEFLAGSLIST_SEGMENT
mov   es, dx
xchg  ax, si  ; linenum
lods  byte ptr es:[si]
mov   byte ptr [bp - 2], al	

; ds still LINES_PHYSICS_SEGMENT
SELFMODIFY_psight_set_validcount:
mov   word ptr ds:[bx + LINE_PHYSICS_T.lp_validcount], 01000h
les   di, dword ptr ds:[bx]		; linev1Offset
mov   bx, es					; linev2Offset
SHIFT_MACRO_SMALL shl   di 2
and   bh, (VERTEX_OFFSET_MASK SHR 8)
SHIFT_MACRO_SMALL shl   bx 2
mov   ax, VERTEXES_SEGMENT
mov   ds, ax
les   ax, dword ptr ds:[di + VERTEX_T.v_x]		; v1.x
mov   si, es  							       ; v1.y into si
les   bx, dword ptr ds:[bx]		; v2.x

mov   word ptr [bp - STACK_DIVLINE_POSITION + NODE_T.n_x], ax  ;   v1.x
mov   word ptr [bp - STACK_DIVLINE_POSITION + NODE_T.n_y], si	;   v1.y


mov   di, bx
sub   di, ax
mov   word ptr [bp - STACK_DIVLINE_POSITION + NODE_T.n_dx], di   ;	divl.dx.h.intbits = v2.x - v1.x;
mov   di, es					; v2.y
sub   di, si
mov   word ptr [bp - STACK_DIVLINE_POSITION + NODE_T.n_dy], di  ;	divl.dy.h.intbits = v2.y - v1.y;


; si = v1.y
; ax = v1.x

; es/bx in use.
; di free
; dx free	

; callng convention: ax = x, si = y

; cx is free, could pass something into both calls?

SELFMODIFY_psight_divlinesize16_call_1:
call  P_DivlineSide16_
SELFMODIFY_psight_divlinesize16_call_1_AFTER:

xchg  bx, ax	; store s1 result, get v2.x
mov   si, es    ; backed up v2.y

SELFMODIFY_psight_divlinesize16_call_2:
call  P_DivlineSide16_
SELFMODIFY_psight_divlinesize16_call_2_AFTER:
cmp   al, bl
je    jump_to_cross_subsector_mainloop_increment

push  ss
pop   ds

push  bp

LEA   SI, [BP - STACK_DIVLINE_POSITION]

SELFMODIFY_psight_strace_x_lo_5:
    MOV  DX, 01000h
SELFMODIFY_psight_strace_x_hi_5:
    MOV  AX, 01000h
SELFMODIFY_psight_strace_y_hi_5:
    MOV  BP, 01000h
    MOV  ES, BP
SELFMODIFY_psight_strace_y_lo_5:
    MOV  BP, 01000h
CALL  P_DivlineSide_
XCHG  AX, BX ; store result


SELFMODIFY_psight_t2x_lo_2:
MOV   DX, 01000h
SELFMODIFY_psight_t2x_hi_2:
MOV   AX, 01000h
SELFMODIFY_psight_t2y_hi_2:
MOV   BP, 01000h
MOV   ES, BP
SELFMODIFY_psight_t2y_lo_2:
MOV   BP, 01000h
CALL  P_DivlineSide_

pop   bp

CMP   BL, AL
je    side_crossed

test  byte ptr [bp - 2], ML_TWOSIDED		; test flag
je    jump_to_cross_bsp_node_return_0_2	; todo optim out fallthru

two_sided:

mov   ax, SEG_LINEDEFS_SEGMENT
mov   ds, ax
pop   bx   ; segnum (kinda gross... improve)
push  bx
mov   si, word ptr ds:[bx - 2] ; lodsw overshot earlier
SHIFT_MACRO_SMALL shl si 4
mov   di, LINES_PHYSICS_SEGMENT
mov   ds, di
les   di, dword ptr ds:[si + LINE_PHYSICS_T.lp_frontsecnum]
mov   si, es

SHIFT_MACRO_SMALL shl di 4
SHIFT_MACRO_SMALL shl si 4


; di/si not preshfited

mov   ax, SECTORS_SEGMENT
mov   ds, ax


mov   ax, word ptr ds:[di + SECTOR_T.sec_floorheight]

cmp   ax, word ptr ds:[si + SECTOR_T.sec_floorheight]
mov   ax, word ptr ds:[di + SECTOR_T.sec_ceilingheight]
jne   floor_ceiling_heights_dont_match
cmp   ax, word ptr ds:[si + SECTOR_T.sec_ceilingheight]
je    jump_to_cross_subsector_mainloop_increment
floor_ceiling_heights_dont_match:
cmp   ax, word ptr ds:[si + SECTOR_T.sec_ceilingheight]
jl    set_opentop_to_frontsector
mov   ax, word ptr ds:[si + SECTOR_T.sec_ceilingheight]
jmp   opentop_set
ALIGN_MACRO
side_crossed:
jump_to_cross_subsector_mainloop_increment:
mov   di, SEG_LINEDEFS_SEGMENT
mov   es, di
mov   di, LINES_PHYSICS_SEGMENT
mov   ds, di
pop   si  ; segnum
pop   cx  ; iterator
jmp   cross_subsector_mainloop_increment
ALIGN_MACRO

set_opentop_to_frontsector:
mov   ax, word ptr ds:[di + SECTOR_T.sec_ceilingheight]

opentop_set:
mov   cx, ax	; store opentop
mov   word ptr cs:[SELFMODIFY_PSIGHT_setopentop + 1 - P_SIGHT_STARTMARKER_], ax
mov   ax, word ptr ds:[di + SECTOR_T.sec_floorheight]
cmp   ax, word ptr ds:[si + SECTOR_T.sec_floorheight]
jg    set_openbottom_to_frontsector
mov   bx, word ptr ds:[si + SECTOR_T.sec_floorheight]
jmp   openbottom_set
ALIGN_MACRO
jump_to_cross_bsp_node_return_0_2:
jmp   cross_bsp_node_return_0	; todo optim out fallthru
ALIGN_MACRO
set_openbottom_to_frontsector:
mov   bx, word ptr ds:[di + SECTOR_T.sec_floorheight]
openbottom_set:
cmp   bx, cx
jge   jump_to_cross_bsp_node_return_0_2

PUSH BX
PUSH SI
PUSH DI

SELFMODIFY_psight_strace_dy_lo_1:
MOV  BX, 01000h
SELFMODIFY_psight_strace_dy_hi_1:
MOV  CX, 01000h
LES  AX, DWORD PTR [BP - STACK_DIVLINE_POSITION + NODE_T.n_dx]
CALL FixedMul_8_8_ ; DX.AX = AH.AL * CX.BX
XCHG AX, DI
MOV  AX, ES ; NODE_T.n_dy
MOV  ES, DX
SELFMODIFY_psight_strace_dx_lo_1:
MOV  BX, 01000h
SELFMODIFY_psight_strace_dx_hi_1:
MOV  CX, 01000h
CALL FixedMul_8_8_ ; DX.AX = AH.AL * CX.BX
SUB  AX, DI
MOV  DI, ES
SBB  DX, DI

MOV  SI, AX
OR   AX, DX
JZ   denominator_0

PUSH DX ; save high den

LES  DI, DWORD PTR [BP - STACK_DIVLINE_POSITION + NODE_T.n_x]  ; di has x dx has y
MOV  DX, ES ; NODE_T.n_y

SELFMODIFY_psight_strace_y_lo_1:
MOV  BX, 01000h ; shrink to MOV BH?
SELFMODIFY_psight_strace_y_hi_1:
MOV  AX, 01000h
SUB  AX, DX

LES  CX, DWORD PTR [BP - STACK_DIVLINE_POSITION + NODE_T.n_dx]

CALL FixedMul_16_0_ ; DX.AX = CX.0 * AX.BX

XCHG AX, DI ; NODE_T.n_x
MOV  CX, ES
MOV  ES, DX

SELFMODIFY_psight_strace_x_lo_1:
MOV  BX, 01000h
SELFMODIFY_psight_strace_x_hi_1:
SUB  AX, 01000h

CALL FixedMul_16_0_ ; DX.AX = CX.0 * AX.BX

MOV  BX, SI
POP  CX ; high den

MOV  SI, ES

ADD  AX, DI
ADC  DX, SI

CALL FixedDiv_MapLocal_

denominator_0:
POP  DI
POP  SI
POP  BX

mov   word ptr [bp - 6], ax	; store frac
mov   word ptr [bp - 4], dx

; ds still SECTORS_SEGMENT
mov   cx, word ptr ds:[di + SECTOR_T.sec_floorheight]
cmp   cx, word ptr ds:[si + SECTOR_T.sec_floorheight]
push  ss
pop   ds
je    done_setting_bottomslope

; fixed height from shortheight

xor   cx, cx
SHIFT32_MACRO_RIGHT bx cx 3

; BX:CX has what should become dx:ax
; dx:ax has what should become cx:bx...

xchg ax, cx
SELFMODIFY_psight_sightzstart_lo_1:
sub   ax, 01000h
xchg dx, bx
SELFMODIFY_psight_sightzstart_hi_1:
sbb   dx, 01000h
xchg cx, bx			;  frac into cx:bx

call  FixedDiv_MapLocal_



mov   bx, OFFSET _bottomslope
cmp   dx, word ptr ds:[bx + 2]
jg    update_bottom_slope
jne   done_setting_bottomslope
cmp   ax, word ptr ds:[bx]
jbe   done_setting_bottomslope
update_bottom_slope:
mov   word ptr ds:[bx], ax
mov   word ptr ds:[bx + 2], dx
done_setting_bottomslope:
mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   ax, word ptr es:[di + SECTOR_T.sec_ceilingheight]
cmp   ax, word ptr es:[si + SECTOR_T.sec_ceilingheight]
je    done_setting_topslope

; fixed height from shortheight
xor   ax, ax
SELFMODIFY_PSIGHT_setopentop:
mov   dx, 01000h		; opentop
SHIFT32_MACRO_RIGHT dx ax 3


SELFMODIFY_psight_sightzstart_lo_2:
sub   ax, 01000h
SELFMODIFY_psight_sightzstart_hi_2:
sbb   dx, 01000h

les   bx, dword ptr [bp - 6]	; load frac into cx:bx
mov   cx, es

call  FixedDiv_MapLocal_


mov   bx, OFFSET _topslope
cmp   dx, word ptr ds:[bx + 2]
jl    update_topslope
jne   done_setting_topslope
cmp   ax, word ptr ds:[bx]
jae   done_setting_topslope
update_topslope:
mov   word ptr ds:[bx], ax
mov   word ptr ds:[bx + 2], dx
done_setting_topslope:
les   dx, dword ptr ds:[_topslope]
mov   ax, es
cmp   ax, word ptr ds:[_bottomslope + 2]
jl    cross_bsp_node_return_0
jne   jump_to_cross_subsector_mainloop_increment_2
cmp   dx, word ptr ds:[_bottomslope]
ja    jump_to_cross_subsector_mainloop_increment_2
cross_bsp_node_return_0:
clc
LEAVE_MACRO

pop   si
mov   dx, NODES_SEGMENT
mov   ds, dx
ret
jump_to_cross_subsector_mainloop_increment_2:
mov   di, SEG_LINEDEFS_SEGMENT
mov   es, di
mov   di, LINES_PHYSICS_SEGMENT
mov   ds, di
pop   si  ; segnum
pop   cx  ; iterator
jmp   cross_subsector_mainloop_increment


ENDP





PROC    P_SIGHT_ENDMARKER_
PUBLIC  P_SIGHT_ENDMARKER_
ENDP

PUBLIC ENSUREALIGN_908

ENDS

END