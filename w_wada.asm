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


EXTRN Z_QuickMapWADPageFrame_:FAR

.DATA

EXTRN _numlumps:WORD


.CODE

; todo constant
LUMP_PER_EMS_PAGE = 1024 


PROC    W_WAD_STARTMARKER_ NEAR
PUBLIC  W_WAD_STARTMARKER_
ENDP


; note: some of the math here assums tics wont differ by more than 16 bits signed (32768 tics) per call, which i think is more than more than enough precision in any case.

PROC    W_CheckNumForNameFarString_ NEAR
PUBLIC  W_CheckNumForNameFarString_

mov    ds, dx
; fall thru

PROC    W_CheckNumForName_ NEAR
PUBLIC  W_CheckNumForName_

PUSHA_NO_AX_OR_BP_MACRO

xchg  ax, si

xor   ax, ax
mov   cx, ax
mov   dx, ax
mov   di, ax
mov   bx, ax 

lodsb
cmp   al, 061h
jb    skip_upper_1
cmp   al, 07Ah
ja    skip_upper_1
sub   al, 020h
skip_upper_1:
cmp   al, 0
je    done_uppering
xchg  ax,  cx
lodsb
cmp   al, 0
je    done_uppering
cmp   al, 061h
jb    skip_upper_2
cmp   al, 07Ah
ja    skip_upper_2
sub   al, 020h
skip_upper_2:
mov   ch, al ;   cx stores first uppercase word


lodsb
cmp   al, 0
je    done_uppering
cmp   al, 061h
jb    skip_upper_3
cmp   al, 07Ah
ja    skip_upper_3
sub   al, 020h
skip_upper_3:
xchg  ax, bx
lodsb
cmp   al, 0
je    done_uppering
cmp   al, 061h
jb    skip_upper_4
cmp   al, 07Ah
ja    skip_upper_4
sub   al, 020h
skip_upper_4:
mov  bh, al ;   bx stores second uppercase word

lodsb
cmp   al, 0
je    done_uppering
cmp   al, 061h
jb    skip_upper_5
cmp   al, 07Ah
ja    skip_upper_5
sub   al, 020h
skip_upper_5:
xchg  ax, dx
lodsb
cmp   al, 0
je    done_uppering
cmp   al, 061h
jb    skip_upper_6
cmp   al, 07Ah
ja    skip_upper_6
sub   al, 020h
skip_upper_6:
mov  dh, al ;   dx stores third uppercase word

lodsb
cmp   al, 0
je    done_uppering
cmp   al, 061h
jb    skip_upper_7
cmp   al, 07Ah
ja    skip_upper_7
sub   al, 020h
skip_upper_7:
xchg  ax, di
lodsb
cmp   al, 0
je    done_uppering
cmp   al, 061h
jb    skip_upper_8
cmp   al, 07Ah
ja    skip_upper_8
sub   al, 020h
skip_upper_8:
xchg  al, ah
or    di, ax ; di stores fourth uppercase word

done_uppering:


push  ss
pop   ds

mov   ax, word ptr ds:[_numlumps]
mov   si, ax
call  Z_QuickMapWADPageFrame_



mov   ax, 0D800h ; todo constant
mov   ds, ax

mov   ax, si
xchg  ax, cx     ; cx gets numlumps and ax gets first word

and   si, (LUMP_PER_EMS_PAGE-1)   ;currentcounter
SHIFT_MACRO sal si 4  ; sizeof lumpinfo_t



loop_next_lump_check:
sub   si, SIZE LUMPINFO_T
js    reset_page  ; underflow, get next wad page...
return_to_lump_check:
cmp   ax, word ptr ds:[si]
jne   no_match
cmp   bx, word ptr ds:[si+2]
jne   no_match
cmp   dx, word ptr ds:[si+4]
jne   no_match
cmp   di, word ptr ds:[si+6]
je    found_match_return

no_match:

loop loop_next_lump_check

break_wad_loop:         ; negative 1 return val on fail

found_match_return:     ; cx is always one high in loop due to loop end condition. dec one extra
dec   cx ; negative 1 return val


mov   es, cx ; store ret

push  ss
pop   ds

POPA_NO_AX_OR_BP_MACRO
mov   ax, es
ret

reset_page:

jcxz   break_wad_loop ; notthing left

xchg  ax, si ; backup
mov   ax, cx
dec   ax

push  ss
pop   ds

call  Z_QuickMapWADPageFrame_

mov   ax, 0D800h
mov   ds, ax
xchg  ax, si ; restore

mov   si, (LUMP_PER_EMS_PAGE - 1) SHL 4
jmp   return_to_lump_check


ENDP




PROC    W_WAD_ENDMARKER_ NEAR
PUBLIC  W_WAD_ENDMARKER_
ENDP


END