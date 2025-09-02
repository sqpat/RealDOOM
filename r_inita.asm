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


EXTRN DEBUG_PRINT_:FAR
EXTRN I_Error_:FAR
;todo inline quickmaps?
EXTRN Z_QuickMapScratch_5000_:FAR
EXTRN Z_QuickMapUndoFlatCache_:FAR
EXTRN Z_QuickMapRender_:FAR
EXTRN W_CacheLumpNumDirect_:FAR
EXTRN W_CacheLumpNameDirect_:FAR

.DATA

EXTRN _numspritelumps:WORD
EXTRN _numflats:WORD
EXTRN _numpatches:WORD
EXTRN _numtextures:WORD

EXTRN _currentlumpindex:WORD
EXTRN _maskedcount:WORD

EXTRN _currentpostdataoffset:WORD
EXTRN _currentpostoffset:WORD
EXTRN _currentpixeloffset:WORD

.CODE


str_dot:
db ".", 0

str_bad_column_patch:
db "R_GenerateLookup: column without a patch", 0

do_print_dot:
push      cs
mov       ax, OFFSET str_dot
push      ax
call      DEBUG_PRINT_       
add       sp, 4
jmp       done_printing_dot


PROC   R_InitSpriteLumps_ NEAR
PUBLIC R_InitSpriteLumps_

PUSHA_NO_AX_MACRO

xor       dx, dx
cmp       byte ptr ds:[_is_ultimate], dl ; 0
mov       ax, SPRITEWIDTHS_NORMAL_SEGMENT
je        not_ultimate
mov       ax, SPRITEWIDTHS_ULT_SEGMENT

not_ultimate:
mov       word ptr ds:[_spritewidths_segment], ax
mov       bp, dx ; 0

continue_spritelumps:

loop_next_sprite:
xor       ax, ax


test      bp, 63
je        do_print_dot
done_printing_dot:
call      Z_QuickMapScratch_5000_
mov       ax, word ptr ds:[_firstspritelump]
mov       cx, SCRATCH_SEGMENT_5000
add       ax, bp
xor       bx, bx

call      W_CacheLumpNumDirect_

mov       es, word ptr ds:[_spritewidths_segment]
mov       ax, SCRATCH_SEGMENT_5000
mov       ds, ax

mov       ax, word ptr ds:[0 + PATCH_T.patch_width]
mov       byte ptr es:[bp], al
xchg      ax, cx ; cx gets patchwidth

; abs ax. todo just use cbw?
mov       ax, word ptr ds:[0 + PATCH_T.patch_leftoffset]
cwd       
xor       ax, dx
sub       ax, dx

mov       dx, SPRITEOFFSETS_SEGMENT
mov       es, dx
mov       byte ptr es:[bp], al

mov       ax, SPRITETOPOFFSETS_SEGMENT
mov       es, ax
mov       ax, word ptr ds:[0 + PATCH_T.patch_topoffset]

cmp       ax, 129
jne       handle_normal_sprite_offset
handle_129_spritetopoffset:
mov       al, 080h  ; - 128
handle_normal_sprite_offset:
mov       byte ptr es:[bp], al


;   cx has patchwidth for looping
xor       ax, ax  ; ah 0 for whole loop
cwd               ; dx = pixelsize
mov       di, ax  ; di = postdatasize
mov       bx, 8   ; PATCH_T.patch_columnofs

; ds still 05000h

loop_next_spritecolumn:

; bx is column
mov       si, word ptr ds:[bx] ; si is post
lodsb
cmp       al, 0FFh
je        found_end_of_spritecolumn

loop_next_spritepost:
lodsb     ; length ; max value of 127 i think?
add       si, ax
add       al, 00Fh
and       al, 0F0h ; round to next paragraph
add       dx, ax
inc       si
inc       si  ; length + 4, but did two lodsb already.
inc       di  ; add by 2, will shift later
lodsb
cmp       al, 0FFh
jne       loop_next_spritepost
found_end_of_spritecolumn:
add       bx, 4 ; next column
inc       di    ; add by 2, will shift later
loop      loop_next_spritecolumn
finished_sprite_loading_loop:
push      ss
pop       ds

;		startoffset = 8 + (patchwidth << 2) + postdatasize;
;		startoffset += (16 - ((startoffset &0xF)) &0xF); // round up so first pixel data starts aligned of course.

sal       di, 1

mov       bx, word ptr ds:[0 + PATCH_T.patch_width]

SHIFT_MACRO shl       bx 2
lea       ax, [bx + di + 8] ; di is post size


add       ax, 0Fh
and       ax, 0FFF0h
add       dx, ax  ; pixelsize + startoffset


; todo... dont do quickmap in a loop! so what? push a bunch and memcpy at the end?

call      Z_QuickMapUndoFlatCache_
mov       bx, bp
sal       bx, 1

mov       ax, SPRITETOTALDATASIZES_SEGMENT
mov       es, ax
mov       word ptr es:[bx], dx

mov       ax, SPRITEPOSTDATASIZES_SEGMENT
mov       es, ax
mov       word ptr es:[bx], di


call      Z_QuickMapRender_

inc       bp 
cmp       bp, word ptr ds:[_numspritelumps]
jge       exit_r_initspritelumps
jmp       loop_next_sprite
exit_r_initspritelumps:
 
POPA_NO_AX_MACRO
ret      


ENDP



PROC    R_GenerateLookup_ NEAR
PUBLIC  R_GenerateLookup_ 

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 082h
push      ax
sub       bp, 080h
mov       word ptr [bp + 4], 0FFFFh
mov       byte ptr [bp + 07ch], 0
mov       byte ptr [bp + 07eh], 1
mov       word ptr [bp + 6], 0E000h
mov       word ptr [bp + 010h], 07000h
mov       word ptr [bp + 040h], 0F500h
mov       word ptr [bp + 03eh], 07000h
mov       word ptr [bp + 022h], 0F700h
xor       ax, ax
mov       si, word ptr [bp - 4]
mov       word ptr [bp + 01ch], ax
add       si, si
mov       ax, word ptr ds:[_currentlumpindex]
lea       bx, [si + _texturepatchlump_offset]
mov       word ptr [bp + 0Eh], 07000h
mov       word ptr ds:[bx], ax
mov       ax, TEXTUREDEFS_OFFSET_SEGMENT
mov       word ptr [bp + 02ch], 0F800h
mov       es, ax
mov       cx, TEXTUREDEFS_BYTES_SEGMENT
mov       si, word ptr es:[si]
mov       es, cx
mov       word ptr [bp + 024h], 07000h
mov       al, byte ptr es:[si + 8]
mov       word ptr [bp + 016h], 0FA00h
xor       ah, ah
mov       word ptr [bp + 04ah], 07000h
inc       ax
mov       word ptr [bp + 04ch], 0FC00h
mov       word ptr [bp + 8], ax
mov       al, byte ptr es:[si + 9]
mov       word ptr [bp + 014h], 07000h
xor       ah, ah
mov       word ptr [bp + 052h], 0FF00h
inc       ax
mov       word ptr [bp + 054h], 07000h
mov       word ptr [bp + 0Ch], ax
xor       ah, ah
mov       dx, 16
and       al, 0Fh
mov       word ptr [bp + 018h], 0
sub       dx, ax
mov       word ptr [bp + 01ah], 09000h
mov       ax, dx
xor       di, di
xor       ah, dh
mov       dx, word ptr [bp + 0Ch]
and       al, 0Fh
mov       bx, 0FF00h
add       dx, ax
mov       ax, 07000h
mov       word ptr [bp + 038h], dx
label_6:
mov       es, ax
mov       word ptr es:[bx], 0
add       bx, 2
jne       label_6
mov       word ptr [bp + 0Ah], 07000h
mov       es, cx
mov       word ptr [bp + 026h], bx
mov       word ptr [bp + 034h], bx
add       si, 0Bh ; todo
mov       word ptr [bp + 05ch], cx
mov       al, byte ptr es:[si - 1]
mov       word ptr [bp + 05ah], si
mov       byte ptr [bp + 07ah], al
label_20:
mov       al, byte ptr [bp + 07ah]
xor       ah, ah
cmp       ax, word ptr [bp + 034h]
jg        label_1
jmp       label_2
label_1:
mov       cx, word ptr [bp + 05ch]
mov       bx, word ptr [bp + 05ah]
mov       es, cx
mov       si, bx
test      byte ptr es:[si + 3], (ORIGINX_SIGN_FLAG SHR 8)
jne       label_3
jmp       label_4
label_3:
mov       dx, -1
label_16:
mov       es, cx
mov       al, byte ptr es:[bx]
xor       ah, ah
imul      dx
mov       si, ax
mov       ax, word ptr es:[bx + 2]
and       ah, 07Fh
mov       word ptr [bp + 020h], ax
mov       ax, word ptr [bp + 4]
cmp       ax, word ptr [bp + 020h]
je        label_5
mov       cx, 07000h
mov       ax, word ptr [bp + 020h]
xor       bx, bx

call      W_CacheLumpNumDirect_
mov       es, word ptr [bp + 0Ah]
mov       bx, word ptr [bp + 026h]
mov       ax, word ptr es:[bx + 2]
mov       word ptr [bp + 2], ax
xor       ah, ah
mov       dx, 16
and       al, 0Fh
sub       dx, ax
mov       ax, dx
xor       ah, dh
and       al, 0Fh
add       word ptr [bp + 2], ax
label_5:
mov       es, word ptr [bp + 0Ah]
mov       bx, word ptr [bp + 026h]
mov       ax, word ptr [bp + 2]
imul      word ptr es:[bx]
mov       bx, _firstpatch
mov       dx, word ptr [bp + 020h]
sub       dx, word ptr ds:[bx]
add       dx, dx
mov       bx, dx
mov       word ptr ds:[bx + _patch_sizes], ax
add       bx, _patch_sizes
mov       ax, word ptr [bp + 020h]
mov       bx, word ptr [bp + 026h]
mov       word ptr [bp + 4], ax
mov       ax, word ptr es:[bx]
add       ax, si
mov       word ptr [bp + 032h], ax
test      si, si
jge       label_7
jmp       label_8
label_7:
mov       word ptr [bp], si
label_17:
mov       ax, word ptr [bp + 032h]
cmp       ax, word ptr [bp + 8]
jle       label_9
mov       ax, word ptr [bp + 8]
mov       word ptr [bp + 032h], ax
label_9:
mov       bx, word ptr [bp]
mov       dh, byte ptr [bp]
mov       ax, word ptr [bp]
shl       bx, 2
cmp       ax, word ptr [bp + 032h]
jl        label_10
jmp       label_11
label_10:
mov       si, word ptr [bp + 040h]
mov       cx, word ptr [bp + 03eh]
add       ax, ax
mov       word ptr [bp + 058h], 07000h
add       si, ax
mov       word ptr [bp + 056h], bx
mov       word ptr [bp + 03ah], si
mov       si, word ptr [bp + 022h]
mov       word ptr [bp + 03ch], cx
add       si, word ptr [bp]
mov       cx, word ptr [bp + 0Eh]
mov       word ptr [bp + 042h], si
mov       si, word ptr [bp + 02ch]
mov       word ptr [bp + 044h], cx
add       si, ax
mov       ax, word ptr [bp + 024h]
mov       word ptr [bp + 046h], si
mov       si, word ptr [bp + 052h]
mov       word ptr [bp + 048h], ax
add       si, word ptr [bp]
mov       ax, word ptr [bp + 054h]
mov       word ptr [bp + 04eh], si
mov       word ptr [bp + 050h], ax
label_19:
les       bx, dword ptr [bp + 04eh]
mov       si, word ptr [bp + 046h]
inc       byte ptr es:[bx]
mov       es, word ptr [bp + 048h]
mov       bx, word ptr [bp + 020h]
mov       word ptr es:[si], bx
les       bx, dword ptr [bp + 042h]
mov       ax, word ptr [bp]
mov       byte ptr es:[bx], dh
mov       es, word ptr [bp + 0Ah]
mov       bx, word ptr [bp + 026h]
mov       si, word ptr [bp + 03ah]
mov       bx, word ptr es:[bx]
mov       es, word ptr [bp + 03ch]
add       ax, ax
mov       word ptr es:[si], bx
cmp       byte ptr [bp + 07ah], 1
je        label_12
jmp       label_13
label_12:
les       bx, dword ptr [bp + 056h]
mov       si, word ptr [bp + 04ch]
mov       cx, word ptr [bp + 01ch]
mov       bx, word ptr es:[bx + 8]
add       si, ax
mov       es, word ptr [bp + 014h]
mov       word ptr [bp + 028h], 0
mov       word ptr es:[si], cx
mov       cx, di
mov       si, word ptr ds:[_currentpostdataoffset]
add       cx, di
mov       word ptr [bp + 012h], 07000h
add       si, cx
xor       dl, dl
mov       word ptr [bp + 02ah], si
mov       si, word ptr [bp + 016h]
mov       es, word ptr [bp + 04ah]
add       si, ax
mov       ax, word ptr [bp + 02ah]
mov       word ptr es:[si], ax
mov       ax, word ptr [bp + 010h]
mov       si, word ptr [bp + 6]
mov       word ptr [bp + 036h], ax
add       si, cx
label_15:
mov       es, word ptr [bp + 012h]
inc       di
cmp       byte ptr es:[bx], 0FFh
je        label_14
mov       al, byte ptr es:[bx + 1]
xor       ah, ah
mov       cx, ax
and       cl, 0Fh
mov       word ptr [bp + 02ah], cx
mov       cx, 16
sub       cx, word ptr [bp + 02ah]
and       cx, 0Fh
add       word ptr [bp + 028h], ax
add       ax, cx
add       word ptr [bp + 01ch], ax
mov       ax, word ptr es:[bx]
mov       es, word ptr [bp + 036h]
mov       word ptr es:[si], ax
mov       es, word ptr [bp + 012h]
mov       al, byte ptr es:[bx + 1]
add       si, 2
xor       ah, ah
inc       dl
add       bx, ax
add       bx, 4
jmp       label_15
label_4:
mov       dx, 1
jmp       label_16
label_8:
mov       word ptr [bp], 0
jmp       label_17
label_14:
mov       es, word ptr [bp + 036h]
mov       word ptr es:[si], -1
cmp       dl, 1
jle       label_13
mov       ax, word ptr [bp + 028h]
cmp       ax, word ptr [bp + 0Ch]
jge       label_13
cmp       word ptr [bp + 8], 0100h
je        label_18
label_21:
mov       byte ptr [bp + 07ch], 1
label_13:
add       word ptr [bp + 03ah], 2
inc       word ptr [bp + 042h]
add       word ptr [bp + 046h], 2
inc       word ptr [bp]
inc       word ptr [bp + 04eh]
mov       ax, word ptr [bp]
add       word ptr [bp + 056h], 4
cmp       ax, word ptr [bp + 032h]
jge       label_11
jmp       label_19
label_11:
add       word ptr [bp + 05ah], 4
inc       word ptr [bp + 034h]
jmp       label_20
label_18:
cmp       dl, 3
jg        label_21
jmp       label_13
label_2:
mov       ax, MASKED_LOOKUP_SEGMENT
mov       bx, word ptr [bp - 4]
mov       es, ax
mov       byte ptr es:[bx], 0FFh
cmp       byte ptr [bp + 07ch], 0
jne       label_22
jmp       label_23
label_22:
mov       ax, word ptr ds:[_currentpostdataoffset]
mov       word ptr [bp + 02eh], ax
mov       al, byte ptr ds:[_maskedcount]
mov       byte ptr es:[bx], al
mov       bx, word ptr ds:[_maskedcount]
mov       ax, word ptr [bp + 01ch]
shl       bx, 3
mov       cx, word ptr ds:[_currentpixeloffset]
mov       word ptr ds:[bx + _masked_headers + 4], ax
mov       dx, word ptr ds:[_currentpostoffset]
mov       word ptr ds:[bx + _masked_headers + 0], cx
mov       word ptr [bp + 030h], MASKEDPOSTDATA_SEGMENT
mov       word ptr ds:[bx + _masked_headers + 2], dx
xor       ax, ax
cmp       word ptr [bp + 8], 0
jle       label_24
mov       word ptr [bp + 060h], MASKEDPOSTDATAOFS_SEGMENT  ; todo use offset from 8400
mov       bx, word ptr [bp + 016h]
mov       word ptr [bp + 066h], MASKEDPIXELDATAOFS_SEGMENT  ; todo use offset from 8400
mov       word ptr [bp + 05eh], dx
mov       dx, word ptr [bp + 04ah]
mov       word ptr [bp + 062h], bx
mov       word ptr [bp + 064h], dx
mov       bx, cx
mov       dx, word ptr [bp + 014h]
mov       cx, word ptr [bp + 04ch]
mov       word ptr [bp + 068h], dx
label_25:
mov       es, word ptr [bp + 068h]
mov       si, cx
add       bx, 2
inc       ax
add       cx, 2
mov       dx, word ptr es:[si]
mov       es, word ptr [bp + 066h]
shr       dx, 4
mov       si, word ptr [bp + 062h]
mov       word ptr es:[bx - 2], dx
mov       es, word ptr [bp + 064h]
add       word ptr [bp + 062h], 2
mov       dx, word ptr es:[si]
les       si, dword ptr [bp + 05eh]
add       word ptr [bp + 05eh], 2
mov       word ptr es:[si], dx
cmp       ax, word ptr [bp + 8]
jl        label_25
label_24:
xor       ax, ax
test      di, di
jbe       label_26
mov       si, word ptr [bp + 02eh]
mov       dx, word ptr [bp + 030h]
mov       bx, word ptr [bp + 6]
mov       cx, word ptr [bp + 010h]
mov       word ptr [bp + 06ah], dx
label_27:
mov       es, cx
add       bx, 2
add       si, 2
mov       dx, word ptr es:[bx - 2]
mov       es, word ptr [bp + 06ah]
inc       ax
mov       word ptr es:[si - 2], dx
cmp       ax, di
jb        label_27
label_26:
mov       ax, word ptr [bp + 8]
inc       word ptr ds:[_maskedcount]
add       di, di
add       ax, ax
add       word ptr ds:[_currentpostdataoffset], di
add       word ptr ds:[_currentpostoffset], ax
add       word ptr ds:[_currentpixeloffset], ax
label_23:
mov       word ptr [bp], 0
xor       al, al
cmp       word ptr [bp + 8], 0
jg        label_28
jmp       label_29
label_28:
mov       dx, word ptr [bp - 4]
mov       bx, word ptr [bp + 052h]
mov       cx, word ptr [bp + 054h]
mov       si, word ptr [bp + 040h]
mov       di, word ptr [bp + 022h]
mov       word ptr [bp + 06ch], cx
mov       word ptr [bp + 06eh], si
mov       cx, word ptr [bp + 03eh]
add       dx, dx
mov       word ptr [bp + 070h], cx
mov       cx, word ptr [bp + 0Eh]
mov       si, word ptr [bp + 02ch]
mov       word ptr [bp + 072h], cx
mov       cx, word ptr [bp + 024h]
mov       word ptr [bp + 076h], si
mov       word ptr [bp + 074h], cx
label_33:
mov       es, word ptr [bp + 06ch]
cmp       byte ptr es:[bx], 0
jne       label_30
jmp       bad_patch_error
label_30:
cmp       byte ptr es:[bx], 1
jbe       label_32
mov       es, word ptr [bp + 074h]
mov       si, word ptr [bp + 076h]
mov       cx, TEXTURECOMPOSITESIZES_SEGMENT
mov       word ptr es:[si], -1
mov       es, cx
mov       si, dx
mov       cx, word ptr [bp + 038h]
add       word ptr es:[si], cx
mov       es, word ptr [bp + 072h]
mov       si, word ptr [bp + 06eh]
mov       byte ptr es:[di], al
mov       es, word ptr [bp + 070h]
inc       al
mov       word ptr es:[si], 07FFFh ; todo
label_32:
add       word ptr [bp + 06eh], 2
add       word ptr [bp + 076h], 2
inc       word ptr [bp]
inc       bx
mov       cx, word ptr [bp]
inc       di
cmp       cx, word ptr [bp + 8]
jl        label_33
label_29:
mov       es, word ptr [bp + 024h]
mov       bx, word ptr [bp + 02ch]
mov       word ptr [bp], 1
xor       dx, dx
mov       ax, word ptr es:[bx]
mov       es, word ptr [bp + 0Eh]
mov       bx, word ptr [bp + 022h]
mov       word ptr [bp + 01eh], ax
mov       al, byte ptr es:[bx]
cmp       word ptr [bp + 8], 1
jg        label_35
jmp       label_34
label_35:
mov       cx, word ptr [bp + 024h]
lea       si, [bx + 1]
mov       word ptr [bp - 2], es
mov       bx, word ptr [bp + 02ch]
mov       word ptr [bp + 078h], cx
add       bx, 2
label_38:
mov       di, word ptr [bp]
mov       cx, word ptr [bp + 01eh]
mov       es, word ptr [bp + 078h]
add       di, di
cmp       cx, word ptr es:[bx]
jne       label_36
jmp       label_37
label_36:
mov       di, word ptr ds:[_currentlumpindex]
mov       cx, word ptr [bp + 01eh]
add       di, di
mov       es, word ptr [bp + 01ah]
add       di, word ptr [bp + 018h]
mov       byte ptr [bp + 07eh], 0
mov       word ptr es:[di], cx
mov       cx, word ptr ds:[_currentlumpindex]
mov       ah, byte ptr [bp]
mov       di, cx
sub       ah, dl
add       di, cx
dec       ah
add       di, word ptr [bp + 018h]
mov       dx, word ptr [bp]
mov       byte ptr es:[di + 2], ah
add       cx, 2
mov       byte ptr es:[di + 3], al
mov       es, word ptr [bp + 078h]
mov       word ptr ds:[_currentlumpindex], cx
mov       ax, word ptr es:[bx]
mov       es, word ptr [bp - 2]
mov       word ptr [bp + 01eh], ax
mov       al, byte ptr es:[si]
label_42:
inc       word ptr [bp]
inc       si
mov       cx, word ptr [bp]
add       bx, 2
cmp       cx, word ptr [bp + 8]
jl        label_38
label_34:
cmp       byte ptr [bp + 07eh], 0
je        label_39
mov       al, byte ptr [bp + 8]
dec       al
label_39:
mov       cx, word ptr ds:[_currentlumpindex]
mov       bx, cx
add       bx, cx
mov       es, word ptr [bp + 01ah]
add       bx, word ptr [bp + 018h]
mov       byte ptr es:[bx + 3], al
mov       ax, word ptr [bp + 01eh]
mov       word ptr es:[bx], ax
mov       al, byte ptr [bp + 8]
sub       al, dl
add       cx, 2
dec       al
mov       word ptr ds:[_currentlumpindex], cx
mov       byte ptr es:[bx + 2], al
lea       sp, [bp + 080h]
pop       bp
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret      

bad_patch_error:
push      cs
mov       ax, OFFSET str_bad_column_patch 
push      ax
call      I_Error_
add       sp, 4
lea       sp, [bp + 080h]
pop       bp
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret      
label_37:
mov       cx, word ptr [bp]
mov       es, word ptr [bp + 03eh]
sub       cx, dx
add       di, word ptr [bp + 040h]
cmp       cx, word ptr es:[di]
jl        label_40
jump_to_label_36:
jmp       label_36
label_40:
mov       es, word ptr [bp + 078h]
cmp       word ptr es:[bx], -1
jne       label_41
jmp       label_42
label_41:
mov       es, word ptr [bp - 2]
cmp       al, byte ptr es:[si]
jne       jump_to_label_36
jmp       label_42

ENDP

COMMENT @

PROC   R_InitTextures_ NEAR

0x0000000000000ce2:  53                push      bx
0x0000000000000ce3:  51                push      cx
0x0000000000000ce4:  52                push      dx
0x0000000000000ce5:  56                push      si
0x0000000000000ce6:  57                push      di
0x0000000000000ce7:  55                push      bp
0x0000000000000ce8:  89 E5             mov       bp, sp
0x0000000000000cea:  81 EC D8 03       sub       sp, 03d8h
0x0000000000000cee:  B8 17 14          mov       ax, 0x1417
0x0000000000000cf1:  BB 26 01          mov       bx, _firstpatch
0x0000000000000cf4:  0E                
0x0000000000000cf5:  E8 4C 9D          call      W_GetNumForName_
0x0000000000000cf8:  90                       
0x0000000000000cf9:  40                inc       ax
0x0000000000000cfa:  89 07             mov       word ptr ds:[bx], ax
0x0000000000000cfc:  B8 1F 14          mov       ax, 0x141f
0x0000000000000cff:  0E                
0x0000000000000d00:  3E E8 40 9D       call      W_GetNumForName_
0x0000000000000d04:  48                dec       ax
0x0000000000000d05:  2B 07             sub       ax, word ptr ds:[bx]
0x0000000000000d07:  40                inc       ax
0x0000000000000d08:  A3 96 18          mov       word ptr ds:[_numpatches], ax
0x0000000000000d0b:  B8 25 14          mov       ax, 0x1425
0x0000000000000d0e:  BB 6E 01          mov       bx, 0x16e
0x0000000000000d11:  0E                
0x0000000000000d12:  3E E8 2E 9D       call      W_GetNumForName_
0x0000000000000d16:  40                inc       ax
0x0000000000000d17:  89 07             mov       word ptr ds:[bx], ax
0x0000000000000d19:  B8 2D 14          mov       ax, 0x142d
0x0000000000000d1c:  0E                
0x0000000000000d1d:  E8 24 9D          call      W_GetNumForName_
0x0000000000000d20:  90                       
0x0000000000000d21:  48                dec       ax
0x0000000000000d22:  2B 07             sub       ax, word ptr ds:[bx]
0x0000000000000d24:  40                inc       ax
0x0000000000000d25:  A3 9C 18          mov       word ptr ds:[_numflats], ax
0x0000000000000d28:  B8 33 14          mov       ax, 0x1433
0x0000000000000d2b:  BB E6 00          mov       bx, 0xe6
0x0000000000000d2e:  0E                
0x0000000000000d2f:  E8 12 9D          call      W_GetNumForName_
0x0000000000000d32:  90                       
0x0000000000000d33:  40                inc       ax
0x0000000000000d34:  89 07             mov       word ptr ds:[bx], ax
0x0000000000000d36:  B8 3B 14          mov       ax, 0x143b
0x0000000000000d39:  0E                
0x0000000000000d3a:  3E E8 06 9D       call      W_GetNumForName_
0x0000000000000d3e:  48                dec       ax
0x0000000000000d3f:  2B 07             sub       ax, word ptr ds:[bx]
0x0000000000000d41:  B9 00 70          mov       cx, 07000h
0x0000000000000d44:  40                inc       ax
0x0000000000000d45:  31 DB             xor       bx, bx
0x0000000000000d47:  A3 9A 18          mov       word ptr ds:[_numspritelumps], ax
0x0000000000000d4a:  B8 41 14          mov       ax, 0x1441
0x0000000000000d4d:  C6 46 DC 00       mov       byte ptr [bp - 024h], 0
0x0000000000000d51:  0E                
0x0000000000000d52:  3E E8 F0 9D       call      W_CacheLumpNameDirect_
0x0000000000000d56:  B8 00 70          mov       ax, 07000h
0x0000000000000d59:  31 DB             xor       bx, bx
0x0000000000000d5b:  8E C0             mov       es, ax
0x0000000000000d5d:  C7 46 EA 00 70    mov       word ptr [bp - 016h], 07000h
0x0000000000000d62:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000d65:  89 5E E8          mov       word ptr [bp - 018h], bx
0x0000000000000d68:  89 46 E2          mov       word ptr [bp - 01eh], ax
0x0000000000000d6b:  85 C0             test      ax, ax
0x0000000000000d6d:  7E 30             jle       0xd9f
0x0000000000000d6f:  BE 04 00          mov       si, 4
0x0000000000000d72:  8C 46 E0          mov       word ptr [bp - 020h], es
0x0000000000000d75:  31 FF             xor       di, di
0x0000000000000d77:  8B 4E E0          mov       cx, word ptr [bp - 020h]
0x0000000000000d7a:  8D 46 D4          lea       ax, [bp - 02ch]
0x0000000000000d7d:  89 F3             mov       bx, si
0x0000000000000d7f:  8C DA             mov       dx, ds
0x0000000000000d81:  E8 FA 59          call      copystr8_
0x0000000000000d84:  83 C7 02          add       di, 2
0x0000000000000d87:  8D 46 D4          lea       ax, [bp - 02ch]
0x0000000000000d8a:  FF 46 E8          inc       word ptr [bp - 018h]
0x0000000000000d8d:  E8 10 9E          call      W_CheckNumForName_
0x0000000000000d90:  89 83 26 FC       mov       word ptr [bp + di - 0x3da], ax
0x0000000000000d94:  8B 46 E8          mov       ax, word ptr [bp - 018h]
0x0000000000000d97:  83 C6 08          add       si, 8
0x0000000000000d9a:  3B 46 E2          cmp       ax, word ptr [bp - 01eh]
0x0000000000000d9d:  7C D8             jl        0xd77
0x0000000000000d9f:  B9 00 70          mov       cx, 07000h
0x0000000000000da2:  B8 48 14          mov       ax, 0x1448
0x0000000000000da5:  31 DB             xor       bx, bx
0x0000000000000da7:  0E                
0x0000000000000da8:  3E E8 9A 9D       call      W_CacheLumpNameDirect_
0x0000000000000dac:  B8 00 70          mov       ax, 07000h
0x0000000000000daf:  31 DB             xor       bx, bx
0x0000000000000db1:  8E C0             mov       es, ax
0x0000000000000db3:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000db6:  C7 46 DE 04 00    mov       word ptr [bp - 022h], 4
0x0000000000000dbb:  89 46 E4          mov       word ptr [bp - 01ch], ax
0x0000000000000dbe:  A3 98 18          mov       word ptr ds:[_numtextures], ax
0x0000000000000dc1:  B8 51 14          mov       ax, 0x1451
0x0000000000000dc4:  8C 46 E6          mov       word ptr [bp - 01ah], es
0x0000000000000dc7:  E8 D6 9D          call      W_CheckNumForName_
0x0000000000000dca:  3D FF FF          cmp       ax, -1
0x0000000000000dcd:  74 19             je        0xde8
0x0000000000000dcf:  B9 00 78          mov       cx, 0x7800
0x0000000000000dd2:  B8 51 14          mov       ax, 0x1451
0x0000000000000dd5:  0E                
0x0000000000000dd6:  3E E8 6C 9D       call      W_CacheLumpNameDirect_
0x0000000000000dda:  B8 00 78          mov       ax, 0x7800
0x0000000000000ddd:  31 DB             xor       bx, bx
0x0000000000000ddf:  8E C0             mov       es, ax
0x0000000000000de1:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000de4:  01 06 98 18       add       word ptr ds:[_numtextures], ax
0x0000000000000de8:  B8 3B 14          mov       ax, 0x143b
0x0000000000000deb:  0E                
0x0000000000000dec:  3E E8 54 9C       call      W_GetNumForName_
0x0000000000000df0:  89 C2             mov       dx, ax
0x0000000000000df2:  89 D7             mov       di, dx
0x0000000000000df4:  B8 33 14          mov       ax, 0x1433
0x0000000000000df7:  4F                dec       di
0x0000000000000df8:  0E                
0x0000000000000df9:  E8 48 9C          call      W_GetNumForName_
0x0000000000000dfc:  90                       
0x0000000000000dfd:  29 C7             sub       di, ax
0x0000000000000dff:  8D 45 3F          lea       ax, [di + 03Fh]
0x0000000000000e02:  99                cwd       
0x0000000000000e03:  C1 E2 06          shl       dx, 6
0x0000000000000e06:  1B C2             sbb       ax, dx
0x0000000000000e08:  C1 F8 06          sar       ax, 6
0x0000000000000e0b:  89 C7             mov       di, ax
0x0000000000000e0d:  A1 98 18          mov       ax, word ptr ds:[_numtextures]
0x0000000000000e10:  05 3F 00          add       ax, 0x3f
0x0000000000000e13:  99                cwd       
0x0000000000000e14:  C1 E2 06          shl       dx, 6
0x0000000000000e17:  1B C2             sbb       ax, dx
0x0000000000000e19:  C1 F8 06          sar       ax, 6
0x0000000000000e1c:  1E                push      ds
0x0000000000000e1d:  31 F6             xor       si, si
0x0000000000000e1f:  68 5A 14          push      0x145a
0x0000000000000e22:  01 C7             add       di, ax
0x0000000000000e24:  0E                
0x0000000000000e25:  E8 B8 1A          call      DEBUG_PRINT_
0x0000000000000e28:  90                       
0x0000000000000e29:  83 C4 04          add       sp, 4
0x0000000000000e2c:  85 FF             test      di, di
0x0000000000000e2e:  7E 11             jle       0xe41
0x0000000000000e30:  1E                push      ds
0x0000000000000e31:  68 5C 14          push      0x145c
0x0000000000000e34:  46                inc       si
0x0000000000000e35:  0E                
0x0000000000000e36:  3E E8 A6 1A       call      DEBUG_PRINT_
0x0000000000000e3a:  83 C4 04          add       sp, 4
0x0000000000000e3d:  39 FE             cmp       si, di
0x0000000000000e3f:  7C EF             jl        0xe30
0x0000000000000e41:  1E                push      ds
0x0000000000000e42:  68 5E 14          push      0x145e
0x0000000000000e45:  31 D2             xor       dx, dx
0x0000000000000e47:  0E                
0x0000000000000e48:  3E E8 94 1A       call      DEBUG_PRINT_
0x0000000000000e4c:  83 C4 04          add       sp, 4
0x0000000000000e4f:  85 FF             test      di, di
0x0000000000000e51:  7E 11             jle       0xe64
0x0000000000000e53:  1E                push      ds
0x0000000000000e54:  68 69 14          push      0x1469
0x0000000000000e57:  42                inc       dx
0x0000000000000e58:  0E                
0x0000000000000e59:  E8 84 1A          call      DEBUG_PRINT_
0x0000000000000e5c:  90                       
0x0000000000000e5d:  83 C4 04          add       sp, 4
0x0000000000000e60:  39 FA             cmp       dx, di
0x0000000000000e62:  7C EF             jl        0xe53
0x0000000000000e64:  1E                push      ds
0x0000000000000e65:  68 6B 14          push      0x146b
0x0000000000000e68:  C7 46 F0 00 00    mov       word ptr [bp - 010h], 0
0x0000000000000e6d:  0E                
0x0000000000000e6e:  3E E8 6E 1A       call      DEBUG_PRINT_
0x0000000000000e72:  83 C4 04          add       sp, 4
0x0000000000000e75:  83 3E 98 18 00    cmp       word ptr ds:[_numtextures], 0
0x0000000000000e7a:  7F 03             jg        0xe7f
0x0000000000000e7c:  E9 C2 01          jmp       0x1041
0x0000000000000e7f:  C7 46 EC 02 00    mov       word ptr [bp - 014h], 2
0x0000000000000e84:  C7 46 EE 00 00    mov       word ptr [bp - 012h], 0
0x0000000000000e89:  F6 46 F0 3F       test      byte ptr [bp - 010h], 0x3f
0x0000000000000e8d:  75 03             jne       0xe92
0x0000000000000e8f:  E9 D8 00          jmp       0xf6a
0x0000000000000e92:  8B 46 F0          mov       ax, word ptr [bp - 010h]
0x0000000000000e95:  3B 46 E4          cmp       ax, word ptr [bp - 01ch]
0x0000000000000e98:  75 0F             jne       0xea9
0x0000000000000e9a:  C7 46 EA 00 78    mov       word ptr [bp - 016h], 0x7800
0x0000000000000e9f:  C7 46 DE 04 00    mov       word ptr [bp - 022h], 4
0x0000000000000ea4:  C7 46 E6 00 78    mov       word ptr [bp - 01ah], 0x7800
0x0000000000000ea9:  8E 46 E6          mov       es, word ptr [bp - 01ah]
0x0000000000000eac:  8B 46 F0          mov       ax, word ptr [bp - 010h]
0x0000000000000eaf:  8B 76 DE          mov       si, word ptr [bp - 022h]
0x0000000000000eb2:  40                inc       ax
0x0000000000000eb3:  26 8B 34          mov       si, word ptr es:[si]
0x0000000000000eb6:  8E 46 EA          mov       es, word ptr [bp - 016h]
0x0000000000000eb9:  89 F3             mov       bx, si
0x0000000000000ebb:  8C C2             mov       dx, es
0x0000000000000ebd:  3B 06 98 18       cmp       ax, word ptr ds:[_numtextures]
0x0000000000000ec1:  7D 03             jge       0xec6
0x0000000000000ec3:  E9 B3 00          jmp       0xf79
0x0000000000000ec6:  B8 2D 93          mov       ax, TEXTUREDEFS_OFFSET_SEGMENT
0x0000000000000ec9:  8B 76 EE          mov       si, word ptr [bp - 012h]
0x0000000000000ecc:  8E C0             mov       es, ax
0x0000000000000ece:  26 8B 34          mov       si, word ptr es:[si]
0x0000000000000ed1:  8E C2             mov       es, dx
0x0000000000000ed3:  C7 46 F6 B2 90    mov       word ptr [bp - 0xa], TEXTUREDEFS_BYTES_SEGMENT
0x0000000000000ed8:  26 8A 47 0C       mov       al, byte ptr es:[bx + 0Ch]
0x0000000000000edc:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x0000000000000edf:  FE C8             dec       al
0x0000000000000ee1:  26 88 44 08       mov       byte ptr es:[si + 8], al
0x0000000000000ee5:  8E C2             mov       es, dx
0x0000000000000ee7:  26 8A 47 0E       mov       al, byte ptr es:[bx + 0Eh]
0x0000000000000eeb:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x0000000000000eee:  FE C8             dec       al
0x0000000000000ef0:  26 88 44 09       mov       byte ptr es:[si + 9], al
0x0000000000000ef4:  8E C2             mov       es, dx
0x0000000000000ef6:  26 8A 47 14       mov       al, byte ptr es:[bx + 014h]
0x0000000000000efa:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x0000000000000efd:  C7 46 FC B2 90    mov       word ptr [bp - 4], TEXTUREDEFS_BYTES_SEGMENT
0x0000000000000f02:  26 88 44 0A       mov       byte ptr es:[si + 0Ah], al
0x0000000000000f06:  C7 46 F8 B2 90    mov       word ptr [bp - 8], TEXTUREDEFS_BYTES_SEGMENT
0x0000000000000f0b:  26 8A 44 08       mov       al, byte ptr es:[si + 8]
0x0000000000000f0f:  89 D1             mov       cx, dx
0x0000000000000f11:  30 E4             xor       ah, ah
0x0000000000000f13:  89 76 F4          mov       word ptr [bp - 0xc], si
0x0000000000000f16:  40                inc       ax
0x0000000000000f17:  8B 7E F4          mov       di, word ptr [bp - 0xc]
0x0000000000000f1a:  89 46 F2          mov       word ptr [bp - 0xe], ax
0x0000000000000f1d:  26 8A 44 09       mov       al, byte ptr es:[si + 9]
0x0000000000000f21:  8E 46 FC          mov       es, word ptr [bp - 4]
0x0000000000000f24:  88 46 FE          mov       byte ptr [bp - 2], al
0x0000000000000f27:  89 DE             mov       si, bx
0x0000000000000f29:  B8 08 00          mov       ax, 8
0x0000000000000f2c:  C7 46 FA 00 00    mov       word ptr [bp - 6], 0
0x0000000000000f31:  1E                push      ds
0x0000000000000f32:  57                push      di
0x0000000000000f33:  91                xchg      ax, cx
0x0000000000000f34:  8E D8             mov       ds, ax
0x0000000000000f36:  D1 E9             shr       cx, 1
0x0000000000000f38:  F3 A5             rep movsw word ptr es:[di], word ptr ds:[si]
0x0000000000000f3a:  13 C9             adc       cx, cx
0x0000000000000f3c:  F3 A4             rep movsb byte ptr es:[di], byte ptr ds:[si]
0x0000000000000f3e:  5F                pop       di
0x0000000000000f3f:  1F                pop       ds
0x0000000000000f40:  83 C3 16          add       bx, 0x16
0x0000000000000f43:  89 D1             mov       cx, dx
0x0000000000000f45:  8D 75 0B          lea       si, [di + 0Bh]
0x0000000000000f48:  C4 7E F4          les       di, ptr [bp - 0xc]
0x0000000000000f4b:  26 8A 45 0A       mov       al, byte ptr es:[di + 0Ah]
0x0000000000000f4f:  30 E4             xor       ah, ah
0x0000000000000f51:  3B 46 FA          cmp       ax, word ptr [bp - 6]
0x0000000000000f54:  7F 42             jg        0xf98
0x0000000000000f56:  C7 46 FA 01 00    mov       word ptr [bp - 6], 1
0x0000000000000f5b:  8B 46 FA          mov       ax, word ptr [bp - 6]
0x0000000000000f5e:  01 C0             add       ax, ax
0x0000000000000f60:  3B 46 F2          cmp       ax, word ptr [bp - 0xe]
0x0000000000000f63:  7F 79             jg        0xfde
0x0000000000000f65:  89 46 FA          mov       word ptr [bp - 6], ax
0x0000000000000f68:  EB F1             jmp       0xf5b
0x0000000000000f6a:  1E                push      ds
0x0000000000000f6b:  68 12 14          push      0x1412
0x0000000000000f6e:  0E                
0x0000000000000f6f:  E8 6E 19          call      DEBUG_PRINT_
0x0000000000000f72:  90                       
0x0000000000000f73:  83 C4 04          add       sp, 4
0x0000000000000f76:  E9 19 FF          jmp       0xe92
0x0000000000000f79:  26 8B 44 14       mov       ax, word ptr es:[si + 014h]
0x0000000000000f7d:  B9 2D 93          mov       cx, TEXTUREDEFS_OFFSET_SEGMENT
0x0000000000000f80:  48                dec       ax
0x0000000000000f81:  8B 76 EE          mov       si, word ptr [bp - 012h]
0x0000000000000f84:  C1 E0 02          shl       ax, 2
0x0000000000000f87:  8E C1             mov       es, cx
0x0000000000000f89:  05 0F 00          add       ax, 0xf
0x0000000000000f8c:  26 03 04          add       ax, word ptr es:[si]
0x0000000000000f8f:  8B 76 EC          mov       si, word ptr [bp - 014h]
0x0000000000000f92:  26 89 04          mov       word ptr es:[si], ax
0x0000000000000f95:  E9 2E FF          jmp       0xec6
0x0000000000000f98:  8E C1             mov       es, cx
0x0000000000000f9a:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000f9d:  99                cwd       
0x0000000000000f9e:  33 C2             xor       ax, dx
0x0000000000000fa0:  2B C2             sub       ax, dx
0x0000000000000fa2:  8E 46 F8          mov       es, word ptr [bp - 8]
0x0000000000000fa5:  26 88 04          mov       byte ptr es:[si], al
0x0000000000000fa8:  8E C1             mov       es, cx
0x0000000000000faa:  26 8A 47 02       mov       al, byte ptr es:[bx + 2]
0x0000000000000fae:  8E 46 F8          mov       es, word ptr [bp - 8]
0x0000000000000fb1:  26 88 44 01       mov       byte ptr es:[si + 1], al
0x0000000000000fb5:  8E C1             mov       es, cx
0x0000000000000fb7:  26 8B 7F 04       mov       di, word ptr es:[bx + 4]
0x0000000000000fbb:  01 FF             add       di, di
0x0000000000000fbd:  26 83 3F 00       cmp       word ptr es:[bx], 0
0x0000000000000fc1:  7C 1D             jl        0xfe0
0x0000000000000fc3:  31 D2             xor       dx, dx
0x0000000000000fc5:  FF 46 FA          inc       word ptr [bp - 6]
0x0000000000000fc8:  83 C6 04          add       si, 4
0x0000000000000fcb:  8B 83 28 FC       mov       ax, word ptr [bp + di - 0x3d8]
0x0000000000000fcf:  8E 46 F8          mov       es, word ptr [bp - 8]
0x0000000000000fd2:  01 D0             add       ax, dx
0x0000000000000fd4:  83 C3 0A          add       bx, 0xa
0x0000000000000fd7:  26 89 44 FE       mov       word ptr es:[si - 2], ax
0x0000000000000fdb:  E9 6A FF          jmp       0xf48
0x0000000000000fde:  EB 05             jmp       0xfe5
0x0000000000000fe0:  BA 00 80          mov       dx, 0x8000
0x0000000000000fe3:  EB E0             jmp       0xfc5
0x0000000000000fe5:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000fe8:  BA A2 82          mov       dx, 0x82a2
0x0000000000000feb:  8B 5E F0          mov       bx, word ptr [bp - 010h]
0x0000000000000fee:  8E C2             mov       es, dx
0x0000000000000ff0:  FE C8             dec       al
0x0000000000000ff2:  26 88 07          mov       byte ptr es:[bx], al
0x0000000000000ff5:  B8 99 3C          mov       ax, 0x3c99
0x0000000000000ff8:  8E C0             mov       es, ax
0x0000000000000ffa:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000ffd:  26 88 07          mov       byte ptr es:[bx], al
0x0000000000001000:  30 E4             xor       ah, ah
0x0000000000001002:  40                inc       ax
0x0000000000001003:  89 C2             mov       dx, ax
0x0000000000001005:  30 E6             xor       dh, ah
0x0000000000001007:  BB 10 00          mov       bx, 0x10
0x000000000000100a:  80 E2 0F          and       dl, 0xf
0x000000000000100d:  29 D3             sub       bx, dx
0x000000000000100f:  89 DA             mov       dx, bx
0x0000000000001011:  83 46 EC 02       add       word ptr [bp - 014h], 2
0x0000000000001015:  30 FE             xor       dh, bh
0x0000000000001017:  83 46 EE 02       add       word ptr [bp - 012h], 2
0x000000000000101b:  80 E2 0F          and       dl, 0xf
0x000000000000101e:  8B 5E F0          mov       bx, word ptr [bp - 010h]
0x0000000000001021:  01 D0             add       ax, dx
0x0000000000001023:  BA 30 4F          mov       dx, 0x4f30
0x0000000000001026:  C1 F8 04          sar       ax, 4
0x0000000000001029:  8E C2             mov       es, dx
0x000000000000102b:  FF 46 F0          inc       word ptr [bp - 010h]
0x000000000000102e:  26 88 07          mov       byte ptr es:[bx], al
0x0000000000001031:  8B 46 F0          mov       ax, word ptr [bp - 010h]
0x0000000000001034:  83 46 DE 04       add       word ptr [bp - 022h], 4
0x0000000000001038:  3B 06 98 18       cmp       ax, word ptr ds:[_numtextures]
0x000000000000103c:  7D 03             jge       0x1041
0x000000000000103e:  E9 48 FE          jmp       0xe89
0x0000000000001041:  C9                LEAVE_MACRO     
0x0000000000001042:  5F                pop       di
0x0000000000001043:  5E                pop       si
0x0000000000001044:  5A                pop       dx
0x0000000000001045:  59                pop       cx
0x0000000000001046:  5B                pop       bx
0x0000000000001047:  CB                retf      

ENDP

PROC   R_InitTextures2_ NEAR


0x0000000000001048:  53                push      bx
0x0000000000001049:  52                push      dx
0x000000000000104a:  56                push      si
0x000000000000104b:  0E                
0x000000000000104c:  3E E8 97 A4       call      Z_QuickMapMaskedExtraData_
0x0000000000001050:  0E                
0x0000000000001051:  E8 EE A3          call      Z_QuickMapScratch_7000_
0x0000000000001054:  90                       
0x0000000000001055:  BA 2D 93          mov       dx, TEXTUREDEFS_OFFSET_SEGMENT
0x0000000000001058:  31 DB             xor       bx, bx
0x000000000000105a:  8E C2             mov       es, dx
0x000000000000105c:  31 D2             xor       dx, dx
0x000000000000105e:  26 89 1F          mov       word ptr es:[bx], bx
0x0000000000001061:  83 3E 98 18 00    cmp       word ptr ds:[_numtextures], 0
0x0000000000001066:  7E 26             jle       0x108e
0x0000000000001068:  BE 4B 4F          mov       si, 0x4f4b
0x000000000000106b:  8E C6             mov       es, si
0x000000000000106d:  89 DE             mov       si, bx
0x000000000000106f:  26 C7 04 00 00    mov       word ptr es:[si], 0
0x0000000000001074:  BE 63 3C          mov       si, 0x3c63
0x0000000000001077:  8E C6             mov       es, si
0x0000000000001079:  89 DE             mov       si, bx
0x000000000000107b:  89 D0             mov       ax, dx
0x000000000000107d:  26 89 14          mov       word ptr es:[si], dx
0x0000000000001080:  0E                
0x0000000000001081:  E8 A4 F6          call      R_GenerateLookup_
0x0000000000001084:  42                inc       dx
0x0000000000001085:  83 C3 02          add       bx, 2
0x0000000000001088:  3B 16 98 18       cmp       dx, word ptr ds:[_numtextures]
0x000000000000108c:  7C DA             jl        0x1068
0x000000000000108e:  0E                
0x000000000000108f:  E8 B8 A2          call      Z_QuickMapRender_
0x0000000000001092:  90                       
0x0000000000001093:  5E                pop       si
0x0000000000001094:  5A                pop       dx
0x0000000000001095:  5B                pop       bx
0x0000000000001096:  CB                retf      

ENDP

PROC   R_InitPatches_ NEAR


0x0000000000001098:  53                push      bx
0x0000000000001099:  51                push      cx
0x000000000000109a:  52                push      dx
0x000000000000109b:  56                push      si
0x000000000000109c:  57                push      di
0x000000000000109d:  BF 00 70          mov       di, 07000h
0x00000000000010a0:  31 F6             xor       si, si
0x00000000000010a2:  31 D2             xor       dx, dx
0x00000000000010a4:  83 3E 96 18 00    cmp       word ptr ds:[_numpatches], 0
0x00000000000010a9:  7E 53             jle       0x10fe
0x00000000000010ab:  BB 26 01          mov       bx, _firstpatch
0x00000000000010ae:  8B 07             mov       ax, word ptr ds:[bx]
0x00000000000010b0:  B9 00 70          mov       cx, 07000h
0x00000000000010b3:  01 D0             add       ax, dx
0x00000000000010b5:  31 DB             xor       bx, bx
0x00000000000010b7:  0E                
0x00000000000010b8:  3E E8 AA 9A       call      W_CacheLumpNumDirect_
0x00000000000010bc:  B9 7E 93          mov       cx, 0x937e
0x00000000000010bf:  8E C7             mov       es, di
0x00000000000010c1:  89 D3             mov       bx, dx
0x00000000000010c3:  26 8A 04          mov       al, byte ptr es:[si]
0x00000000000010c6:  8E C1             mov       es, cx
0x00000000000010c8:  26 88 07          mov       byte ptr es:[bx], al
0x00000000000010cb:  8E C7             mov       es, di
0x00000000000010cd:  26 8B 44 02       mov       ax, word ptr es:[si + 2]
0x00000000000010d1:  89 C3             mov       bx, ax
0x00000000000010d3:  30 E7             xor       bh, ah
0x00000000000010d5:  B9 10 00          mov       cx, 0x10
0x00000000000010d8:  80 E3 0F          and       bl, 0xf
0x00000000000010db:  29 D9             sub       cx, bx
0x00000000000010dd:  89 CB             mov       bx, cx
0x00000000000010df:  30 EF             xor       bh, ch
0x00000000000010e1:  80 E3 0F          and       bl, 0xf
0x00000000000010e4:  01 D8             add       ax, bx
0x00000000000010e6:  89 C3             mov       bx, ax
0x00000000000010e8:  C1 FB 04          sar       bx, 4
0x00000000000010eb:  09 D8             or        ax, bx
0x00000000000010ed:  BB 9C 93          mov       bx, 0x939c
0x00000000000010f0:  8E C3             mov       es, bx
0x00000000000010f2:  89 D3             mov       bx, dx
0x00000000000010f4:  42                inc       dx
0x00000000000010f5:  26 88 07          mov       byte ptr es:[bx], al
0x00000000000010f8:  3B 16 96 18       cmp       dx, word ptr ds:[_numpatches]
0x00000000000010fc:  7C AD             jl        0x10ab
0x00000000000010fe:  5F                pop       di
0x00000000000010ff:  5E                pop       si
0x0000000000001100:  5A                pop       dx
0x0000000000001101:  59                pop       cx
0x0000000000001102:  5B                pop       bx
0x0000000000001103:  C3                ret       

ENDP

PROC   R_InitData_ NEAR


0x0000000000001104:  53                push      bx
0x0000000000001105:  52                push      dx
0x0000000000001106:  B8 2D 93          mov       ax, TEXTUREDEFS_OFFSET_SEGMENT
0x0000000000001109:  8E C0             mov       es, ax
0x000000000000110b:  31 DB             xor       bx, bx
0x000000000000110d:  26 89 1F          mov       word ptr es:[bx], bx
0x0000000000001110:  0E                
0x0000000000001111:  E8 CE FB          call      R_InitTextures_
0x0000000000001114:  0E                
0x0000000000001115:  E8 30 FF          call      R_InitTextures2_
0x0000000000001118:  1E                push      ds
0x0000000000001119:  68 76 14          push      0x1476
0x000000000000111c:  0E                
0x000000000000111d:  E8 C0 17          call      DEBUG_PRINT_
0x0000000000001120:  90                       
0x0000000000001121:  83 C4 04          add       sp, 4
0x0000000000001124:  30 D2             xor       dl, dl
0x0000000000001126:  E8 6F FF          call      R_InitPatches_
0x0000000000001129:  88 D0             mov       al, dl
0x000000000000112b:  30 E4             xor       ah, ah
0x000000000000112d:  3B 06 9C 18       cmp       ax, word ptr ds:[_numflats]
0x0000000000001131:  7D 0E             jge       0x1141
0x0000000000001133:  BB 59 3C          mov       bx, 0x3c59
0x0000000000001136:  8E C3             mov       es, bx
0x0000000000001138:  89 C3             mov       bx, ax
0x000000000000113a:  26 88 17          mov       byte ptr es:[bx], dl
0x000000000000113d:  FE C2             inc       dl
0x000000000000113f:  EB E8             jmp       0x1129
0x0000000000001141:  0E                
0x0000000000001142:  E8 4B F4          call      R_InitSpriteLumps_
0x0000000000001145:  1E                push      ds
0x0000000000001146:  68 12 14          push      0x1412
0x0000000000001149:  0E                
0x000000000000114a:  3E E8 92 17       call      DEBUG_PRINT_
0x000000000000114e:  83 C4 04          add       sp, 4
0x0000000000001151:  5A                pop       dx
0x0000000000001152:  5B                pop       bx
0x0000000000001153:  C3                ret       


ENDP

PROC   R_Init_ NEAR


0x0000000000001154:  53                push      bx
0x0000000000001155:  51                push      cx
0x0000000000001156:  52                push      dx
0x0000000000001157:  0E                
0x0000000000001158:  3E E8 EE A1       call      Z_QuickMapRender_
0x000000000000115c:  B9 00 98          mov       cx, 0x9800
0x000000000000115f:  B8 01 00          mov       ax, 1
0x0000000000001162:  31 DB             xor       bx, bx
0x0000000000001164:  0E                
0x0000000000001165:  E8 FE 99          call      W_CacheLumpNumDirect_
0x0000000000001168:  90                       
0x0000000000001169:  E8 98 FF          call      R_InitData_
0x000000000000116c:  1E                push      ds
0x000000000000116d:  68 76 14          push      0x1476
0x0000000000001170:  BB 69 0A          mov       bx, 0xa69
0x0000000000001173:  0E                
0x0000000000001174:  3E E8 68 17       call      DEBUG_PRINT_
0x0000000000001178:  8A 07             mov       al, byte ptr ds:[bx]
0x000000000000117a:  83 C4 04          add       sp, 4
0x000000000000117d:  30 E4             xor       ah, ah
0x000000000000117f:  BB 9B 01          mov       bx, 0x19b
0x0000000000001182:  89 C2             mov       dx, ax
0x0000000000001184:  8A 07             mov       al, byte ptr ds:[bx]
0x0000000000001186:  0E                
0x0000000000001187:  E8 F5 96          call      R_SetViewSize_
0x000000000000118a:  90                       
0x000000000000118b:  1E                push      ds
0x000000000000118c:  68 79 14          push      0x1479
0x000000000000118f:  0E                
0x0000000000001190:  3E E8 4C 17       call      DEBUG_PRINT_
0x0000000000001194:  83 C4 04          add       sp, 4
0x0000000000001197:  0E                
0x0000000000001198:  3E E8 68 A1       call      Z_QuickMapPhysics_
0x000000000000119c:  B8 7D 14          mov       ax, 0x147d
0x000000000000119f:  E8 EE 1A          call      R_FlatNumForName_
0x00000000000011a2:  1E                push      ds
0x00000000000011a3:  BB 98 01          mov       bx, 0x198
0x00000000000011a6:  68 12 14          push      0x1412
0x00000000000011a9:  88 07             mov       byte ptr ds:[bx], al
0x00000000000011ab:  0E                
0x00000000000011ac:  3E E8 30 17       call      DEBUG_PRINT_
0x00000000000011b0:  83 C4 04          add       sp, 4
0x00000000000011b3:  5A                pop       dx
0x00000000000011b4:  59                pop       cx
0x00000000000011b5:  5B                pop       bx
0x00000000000011b6:  C3                ret     


ENDP

@

END