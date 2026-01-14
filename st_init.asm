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



EXTRN W_LumpLength_:FAR
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN W_CacheLumpNameDirectFarString_:FAR
EXTRN Z_QuickMapPhysics_:NEAR
EXTRN Z_QuickMapPalette_:FAR
EXTRN Z_QuickMapStatus_:NEAR





.DATA



.CODE



PROC    ST_INIT_STARTMARKER_ NEAR
PUBLIC  ST_INIT_STARTMARKER_
ENDP

st_init_str_1:
db "STTNUM0", 0
st_init_str_2:
db "STYSNUM0", 0
st_init_str_3:
db "STKEYS0", 0
st_init_str_4:
db "STGNUM2", 0
st_init_str_5:
db "STFST00", 0
 
st_init_str_6:
db "STFTR00", 0
st_init_str_7:
db "STFTL00", 0
st_init_str_8:
db "STFOUCH0", 0
st_init_str_9:
db "STFEVL0", 0
st_init_str_10:
db "STFKILL0", 0

st_init_str_11:
db "STTPRCNT", 0

st_init_str_12:
db "STARMS", 0

st_init_str_13:
db "STFB0", 0
st_init_str_14:
db "STBAR", 0
st_init_str_15:
db "STFGOD0", 0
st_init_str_16:
db "STFDEAD0", 0
st_init_str_17:
db "PLAYPAL", 0




PROC    ST_load_and_rundownoffset_ NEAR

mov   dx, cs
push  ax
call  W_CheckNumForNameFarString_
call  W_LumpLength_
sub   si, ax
pop   ax
mov   bx, si
mov   cx, ST_GRAPHICS_SEGMENT
mov   dx, cs
call  W_CacheLumpNameDirectFarString_
mov   dx, PHYSICS_HIGHCODE_SEGMENT
mov   es, dx
ret
ENDP

PALETTEBYTES_SEGMENT = 09000h ; todo


; everything inlined
PROC    ST_Init_ NEAR
PUBLIC  ST_Init_

PUSHA_NO_AX_MACRO


;ST_loadGraphics

;	int16_t lu_palette = W_GetNumForName("PLAYPAL");
;	Z_QuickMapPalette();
;	W_CacheLumpNumDirect(lu_palette, palettebytes);
;	Z_QuickMapStatus();
;	ST_loadGraphics();

call   Z_QuickMapPalette_

mov    ax, OFFSET st_init_str_17
mov    dx, cs
mov    cx, PALETTEBYTES_SEGMENT
xor    bx, bx

call   W_CacheLumpNameDirectFarString_


call   Z_QuickMapStatus_


; running offset
mov   si, word ptr ds:[OFFSET _hu_font + (2 * (HU_FONTSIZE - 1))]

xor   di, di  ; offset for writes
loop_load_next_num_graphics:

mov   ax, OFFSET st_init_str_1
call  ST_load_and_rundownoffset_

mov   ax, PHYSICS_HIGHCODE_SEGMENT
mov   es, ax

mov   word ptr es:[di + TALLNUM_CS_OFFSET], si


mov   ax, OFFSET st_init_str_2
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + SHORTNUM_CS_OFFSET], si

inc   byte ptr cs:[st_init_str_1 + 6]
inc   byte ptr cs:[st_init_str_2 + 7]

inc   di
inc   di
cmp   di, 20
jl    loop_load_next_num_graphics


mov   ax, OFFSET st_init_str_11
call  ST_load_and_rundownoffset_
mov   word ptr es:[TALLPERCENT_CS_OFFSET], si




xor   di, di  ; offset for writes
loop_load_next_key_graphics:

mov   ax, OFFSET st_init_str_3
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + KEYS_CS_OFFSET], si

inc   byte ptr cs:[st_init_str_3 + 6]

inc   di
inc   di
cmp   di, NUMCARDS * 2
jl    loop_load_next_key_graphics


mov   ax, OFFSET st_init_str_12
call  ST_load_and_rundownoffset_
mov   word ptr es:[ARMSBG_CS_OFFSET], si

mov   word ptr es:[ARMSBGARRAY_CS_OFFSET], si


xor   di, di  ; offset for writes
loop_load_next_arms_graphics:

mov   ax, OFFSET st_init_str_4
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + ARMS_CS_OFFSET], si

mov   bx, di
sar   bx, 1
push  word ptr es:[bx + SHORTNUM_CS_OFFSET + 4]
pop   word ptr es:[di + ARMS_CS_OFFSET + 2]


inc   byte ptr es:[st_init_str_4 + 6]

add   di, 4
cmp   di, 6 * 4
jl    loop_load_next_arms_graphics


mov   ax, OFFSET st_init_str_13
call  ST_load_and_rundownoffset_
mov   word ptr es:[FACEBACK_CS_OFFSET], si

mov   ax, OFFSET st_init_str_14
call  ST_load_and_rundownoffset_
mov   word ptr es:[SBAR_CS_OFFSET], si

;facenum
xor   di, di

loop_next_pain_state:
    lea   bp, [di + 6]
    loop_next_straight_face:
    mov   ax, OFFSET st_init_str_5
    call  ST_load_and_rundownoffset_
    mov   word ptr es:[di + FACES_CS_OFFSET], si

    
    inc   byte ptr cs:[st_init_str_5 + 6]

    inc   di
    inc   di

    cmp   di, bp
    jl    loop_next_straight_face

mov   byte ptr cs:[st_init_str_5 + 6], '0'
inc   byte ptr cs:[st_init_str_5 + 5]

mov   ax, OFFSET st_init_str_6
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + FACES_CS_OFFSET], si
inc   di
inc   di

mov   ax, OFFSET st_init_str_7
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + FACES_CS_OFFSET], si
inc   di
inc   di

mov   ax, OFFSET st_init_str_8
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + FACES_CS_OFFSET], si
inc   di
inc   di

mov   ax, OFFSET st_init_str_9
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + FACES_CS_OFFSET], si
inc   di
inc   di


mov   ax, OFFSET st_init_str_10
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + FACES_CS_OFFSET], si
inc   di
inc   di

inc   byte ptr cs:[st_init_str_6 + 5]
inc   byte ptr cs:[st_init_str_7 + 5]
inc   byte ptr cs:[st_init_str_8 + 7]
inc   byte ptr cs:[st_init_str_9 + 6]
inc   byte ptr cs:[st_init_str_10 + 7]
cmp   di, ((ST_NUMFACES - 2) * 2)
jl    jump_to_loop_next_pain_state
    
mov   ax, OFFSET st_init_str_15
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + FACES_CS_OFFSET], si
inc   di
inc   di

mov   ax, OFFSET st_init_str_16
call  ST_load_and_rundownoffset_
mov   word ptr es:[di + FACES_CS_OFFSET], si

call  Z_QuickMapPhysics_


POPA_NO_AX_MACRO
ret

ENDP

jump_to_loop_next_pain_state:
jmp   loop_next_pain_state


PROC    ST_INIT_ENDMARKER_ NEAR
PUBLIC  ST_INIT_ENDMARKER_
ENDP

END