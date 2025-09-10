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
EXTRN fread_:FAR
EXTRN fseek_:FAR
EXTRN locallib_far_fread_:FAR

.DATA

EXTRN _wadfiles:WORD
EXTRN _filetolumpindex:WORD
EXTRN _filetolumpsize:WORD
EXTRN _currentloadedfileindex:WORD
EXTRN _numlumps:WORD


COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE


PROC    W_WAD_STARTMARKER_ NEAR
PUBLIC  W_WAD_STARTMARKER_
ENDP

PUBLIC  SELFMODIFY_end_lump_for_search
PUBLIC  SELFMODIFY_start_lump_for_search


PROC    W_UpdateNumLumps_ NEAR
PUBLIC  W_UpdateNumLumps_

mov     ax, word ptr ds:[_numlumps]
mov     word ptr cs:[SELFMODIFY_start_lump_for_search+1], ax
ret     

ENDP



PROC    W_CheckNumForNameFarString_ NEAR
PUBLIC  W_CheckNumForNameFarString_

mov    ds, dx
; fall thru
ENDP

PROC    W_CheckNumForName_ NEAR
PUBLIC  W_CheckNumForName_

PUSHA_NO_AX_OR_BP_MACRO


xchg  ax, si


done_setting_hint:

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

SELFMODIFY_start_lump_for_search:
mov   ax, 01000h
mov   si, ax
call  Z_QuickMapWADPageFrame_


SELFMODIFY_set_lumpinfo_segment_1:
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
je    continue_checks

no_match:
dec   cx
SELFMODIFY_end_lump_for_search:
db    081h, 0F9h, 00h, 00h   ; cmp cx, 0
ja    loop_next_lump_check


exit_early:
xor   cx, cx

break_wad_loop:         ; negative 1 return val on fail

found_match_return:     ; cx is always one high in loop due to loop end condition. dec one extra
dec   cx ; negative 1 return val


mov   es, cx ; store ret

push  ss
pop   ds

POPA_NO_AX_OR_BP_MACRO
mov   ax, es
ret



continue_checks:
jne   no_match
cmp   bx, word ptr ds:[si+2]
jne   no_match
cmp   dx, word ptr ds:[si+4]
jne   no_match
cmp   di, word ptr ds:[si+6]
je    found_match_return
jmp   no_match





reset_page:

jcxz   break_wad_loop ; notthing left

xchg  ax, si ; backup
mov   ax, cx
dec   ax

push  ss
pop   ds

call  Z_QuickMapWADPageFrame_

SELFMODIFY_set_lumpinfo_segment_2:
mov   ax, 0D800h
mov   ds, ax
xchg  ax, si ; restore

mov   si, (LUMP_PER_EMS_PAGE - 1) SHL 4
jmp   return_to_lump_check


ENDP

PROC    W_GetNumForName_ FAR
PUBLIC  W_GetNumForName_


call      W_CheckNumForName_
retf   

ENDP

PROC    W_LumpLength_ FAR
PUBLIC  W_LumpLength_

push      bx
push      cx
mov       cx, ax
xor       dl, dl
label_3:
mov       al, byte ptr ds:[_currentloadedfileindex]
cbw      
mov       bx, ax
mov       al, dl
dec       bx
cbw      
cmp       ax, bx
jge       label_1
mov       bx, ax
add       bx, ax
cmp       cx, word ptr ds:[bx + _filetolumpindex]
je        label_2
inc       dl
jmp       label_3
label_2:
mov       bx, ax
shl       bx, 2
mov       ax, word ptr ds:[bx + _filetolumpsize + 0]
mov       dx, word ptr ds:[bx + _filetolumpsize + 2]
pop       cx
pop       bx
retf      
label_1:
mov       ax, cx
call      Z_QuickMapWADPageFrame_
and       ch, 3
SELFMODIFY_set_lumpinfo_segment_3:
mov       ax, 0D800h
mov       es, ax
mov       bx, cx
shl       bx, 4
mov       ax, word ptr es:[bx + 0Ch]
mov       dx, word ptr es:[bx + 0Eh]

pop       cx
pop       bx
retf      


ENDP

PROC    W_ReadLump_ NEAR
PUBLIC  W_ReadLump_


push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4
mov       si, ax
mov       word ptr [bp - 4], bx
mov       di, cx
call      Z_QuickMapWADPageFrame_
mov       bx, si
SELFMODIFY_set_lumpinfo_segment_4:
mov       ax, 0D800h
and       bh, 3
mov       es, ax
shl       bx, 4
xor       dh, dh
mov       ax, word ptr es:[bx + 0Ch]
mov       cx, bx
mov       word ptr [bp - 2], ax
cmp       si, 1
je        label_4
label_8:
xor       dl, dl
label_7:
mov       al, byte ptr ds:[_currentloadedfileindex]
cbw      
mov       bx, ax
mov       al, dl
dec       bx
cbw      
cmp       ax, bx
jge       label_5
mov       bx, ax
add       bx, ax
cmp       si, word ptr ds:[bx + _filetolumpindex]
je        label_6
inc       dl
jmp       label_7
label_4:
mov       word ptr [bp - 2], COLORMAPS_SIZE
jmp       label_8
label_6:
mov       dh, dl
inc       dh
label_5:
mov       bx, cx
mov       si, cx
mov       bx, word ptr es:[bx + 8]
mov       al, dh
add       bx, word ptr [bp + 0Ah]
mov       cx, word ptr es:[si + 0Ah]
adc       cx, word ptr [bp + 0Ch]
cbw      
mov       si, ax
add       si, ax
xor       dx, dx
mov       ax, word ptr ds:[si + _wadfiles]

call      fseek_

mov       cx, 1
mov       ax, word ptr [bp + 010h]
push      word ptr ds:[si + _wadfiles]
or        ax, word ptr [bp + 0Eh]
je        label_9
mov       bx, word ptr [bp + 0Eh]
label_10:
mov       ax, word ptr [bp - 4]
mov       dx, di

call      locallib_far_fread_
LEAVE_MACRO     
pop       di
pop       si
pop       dx
ret       8
label_9:
mov       bx, word ptr [bp - 2]
sub       bx, word ptr [bp + 0Ah]
jmp       label_10


ENDP

PROC    W_CacheLumpNameDirect_ FAR
PUBLIC  W_CacheLumpNameDirect_


push      0
push      0
push      0
push      0
call      W_CheckNumForName_
call      W_ReadLump_
retf      


ENDP

PROC    W_CacheLumpNameDirectFarString_ FAR
PUBLIC  W_CacheLumpNameDirectFarString_

push      0
push      0
push      0
push      0
call      W_CheckNumForNameFarString_
call      W_ReadLump_
retf      


ENDP

PROC    W_CacheLumpNumDirect_ FAR
PUBLIC  W_CacheLumpNumDirect_

push      0
push      0
push      0
push      0
call      W_ReadLump_
retf      

ENDP

PROC    W_CacheLumpNumDirectSmall_ NEAR
PUBLIC  W_CacheLumpNumDirectSmall_



push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 0Ah
mov       dx, ax
mov       di, bx
mov       word ptr [bp - 2], cx
mov       si, word ptr ds:[_wadfiles]
and       dh, 3
call      Z_QuickMapWADPageFrame_
mov       bx, dx
SELFMODIFY_set_lumpinfo_segment_5:
mov       ax, 0D800h
shl       bx, 4
mov       es, ax
xor       dx, dx
mov       ax, word ptr es:[bx + 8]
mov       cx, word ptr es:[bx + 0Ah]
mov       bx, ax
mov       ax, si
call      fseek_
mov       bx, 2
mov       dx, 4
lea       ax, [bp - 0Ah]
mov       cx, si
call      fread_
mov       ax, 8
lea       si, [bp - 0Ah]
mov       es, word ptr [bp - 2]
mov       cx, ds
push      ds
push      di
xchg      ax, cx
mov       ds, ax
shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 
pop       di
pop       ds
LEAVE_MACRO     
pop       di
pop       si
pop       dx
ret       


ENDP

PROC    W_CacheLumpNumDirectWithOffset_ FAR
PUBLIC  W_CacheLumpNumDirectWithOffset_

push      bp
mov       bp, sp
push      0
push      word ptr [bp + 6]
push      0
push      dx
call      W_ReadLump_
pop       bp
retf      2


ENDP

PROC    W_CacheLumpNumDirectFragment_ FAR
PUBLIC  W_CacheLumpNumDirectFragment_

push      bp
mov       bp, sp
push      0
push      16384
push      word ptr [bp + 8]
push      word ptr [bp + 6]
call      W_ReadLump_
pop       bp
retf      4

ENDP

PROC    W_SetLumpInfoConstant_ NEAR
PUBLIC  W_SetLumpInfoConstant_

; if this grows much turn it into a lodsw situation?

mov     word ptr cs:[SELFMODIFY_set_lumpinfo_segment_1+1], ax
mov     word ptr cs:[SELFMODIFY_set_lumpinfo_segment_2+1], ax
mov     word ptr cs:[SELFMODIFY_set_lumpinfo_segment_3+1], ax
mov     word ptr cs:[SELFMODIFY_set_lumpinfo_segment_4+1], ax
mov     word ptr cs:[SELFMODIFY_set_lumpinfo_segment_5+1], ax

ret
ENDP




PROC    W_WAD_ENDMARKER_ NEAR
PUBLIC  W_WAD_ENDMARKER_
ENDP


END