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

found_lump_file_2:
shl       bx, 1 ; dword lookup
les       ax, dword ptr ds:[bx + _filetolumpsize + 0]
mov       dx, es
pop       cx
pop       bx
retf      


PROC    W_LumpLength_ FAR
PUBLIC  W_LumpLength_

push      bx
push      cx
xchg      ax, cx   ; cx gets lump
xor       dl, dl

xor       bx, bx
mov       al, byte ptr ds:[_currentloadedfileindex]
cbw      
dec       ax
jz        skip_loop_2
shl       ax, 1

loop_next_fileindex_2:
cmp       cx, word ptr ds:[bx + _filetolumpindex]
je        found_lump_file_2
inc       bx
inc       bx
cmp       bx, ax

jl        loop_next_fileindex_2
xor       bx, bx

skip_loop_2:

mov       ax, cx
call      Z_QuickMapWADPageFrame_
and       ch, 3     ;      ; (LUMP_PER_EMS_PAGE - 1 ) SHR 8
SELFMODIFY_set_lumpinfo_segment_3:
mov       ax, 0D800h
mov       es, ax

mov       bx, cx
SHIFT_MACRO shl       bx 4
les       ax, dword ptr es:[bx + LUMPINFO_T.lumpinfo_size + 0]
mov       dx, es

pop       cx
pop       bx
retf      


ENDP

; void __near W_ReadLump (int16_t lump, byte __far* dest, int32_t start, int32_t size ) {

; dx size

do_colormaps_size:
mov       di, COLORMAPS_SIZE
jmp       got_lump_size
found_lump_file:
inc       bx    ; fileindex = i+1
inc       bx    ; fileindex = i+1 (word lookup)
jmp       done_finding_lump_file


PROC    W_ReadLump_ NEAR
PUBLIC  W_ReadLump_

; bp - 4 dest



push      dx
push      si
push      di


mov       si, ax
push      cx  ; [MATCH A] store dest segment
push      bx  ; [MATCH A] store dest offset

call      Z_QuickMapWADPageFrame_
mov       bx, si

;	l = &(lumpinfoD800[lump & (LUMP_PER_EMS_PAGE-1)]);


SELFMODIFY_set_lumpinfo_segment_4:
mov       ax, 0D800h
mov       es, ax

and       bh, 3      ; (LUMP_PER_EMS_PAGE - 1 ) SHR 8
SHIFT_MACRO shl       bx 4


mov       di, word ptr es:[bx + LUMPINFO_T.lumpinfo_size]  ; di has size

cmp       si, 1
je        do_colormaps_size
got_lump_size:

; di has size to read (16 bit)


les       dx, dword ptr es:[bx + LUMPINFO_T.lumpinfo_position]
mov       cx, es
; dx has position low
; cx has position high

;	for (i = 0; i < currentloadedfileindex-1; i++){
;		if (lump == filetolumpindex[i]){
;			fileindex = i+1;	// this is a single lump file
;			break;
;		}
;	}

; si = lump

xor       bx, bx
mov       al, byte ptr ds:[_currentloadedfileindex]
cbw      
dec       ax
jz        skip_loop
shl       ax, 1

loop_next_fileindex:
cmp       si, word ptr ds:[bx + _filetolumpindex]
je        found_lump_file
inc       bx
inc       bx
cmp       bx, ax

jl        loop_next_fileindex
xor       bx, bx

done_finding_lump_file:
skip_loop:

mov       ax, word ptr ds:[bx + _wadfiles]

mov       bx, dx   ; get position low

;	startoffset = l->position + start;

SELFMODIFY_set_start_offset_low:
mov       si, 0h
add       bx, si
SELFMODIFY_add_start_offset_high:
db 081h, 0D1h, 00, 00       ; 81 D1 00 00    ; adc cx, 0


sub       di, si   ; di now equals lumpsize - start if needed

xor       dx, dx  ; SEEK_SET
mov       si, ax  ; store fp
call      fseek_  ;    fseek(wadfiles[fileindex], startoffset, SEEK_SET);


SELFMODIFY_set_length:
db 0BBh, 00, 00   ;  BB 00 00    mov bx, 0
test      bx, bx
jne       skip_lumpsize_load
mov       bx, di  ; (lumpsize - start)

skip_lumpsize_load:

pop       ax ; [MATCH A] get dest offset
pop       dx ; [MATCH A] get dest segment
mov       cx, 1   ; blocksize

push      si ; fp arg to function
call      locallib_far_fread_ ; FAR_fread(dest, size ? size : (lumpsize - start), 1, wadfiles[fileindex]);

pop       di
pop       si
pop       dx
ret



ENDP

PROC    W_CacheLumpNameDirect_ FAR
PUBLIC  W_CacheLumpNameDirect_


call      W_CheckNumForName_
call      W_ReadLump_
retf      


ENDP

PROC    W_CacheLumpNameDirectFarString_ FAR
PUBLIC  W_CacheLumpNameDirectFarString_

call      W_CheckNumForNameFarString_
call      W_ReadLump_
retf      


ENDP

PROC    W_CacheLumpNumDirect_ FAR
PUBLIC  W_CacheLumpNumDirect_

call      W_ReadLump_
retf      

ENDP


; void __near W_CacheLumpNumDirectSmall (int16_t lump, byte __far* dest ) {

PROC    W_CacheLumpNumDirectSmall_ NEAR
PUBLIC  W_CacheLumpNumDirectSmall_



push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 8
mov       di, bx
mov       si, cx      ; si:di is dest
mov       bx, ax

call      Z_QuickMapWADPageFrame_

and       bh, 3      ; (LUMP_PER_EMS_PAGE - 1 ) SHR 8

SHIFT_MACRO shl       bx 4
SELFMODIFY_set_lumpinfo_segment_5:
mov       ax, 0D800h
mov       es, ax



xor       dx, dx  ; SEEK_SET
mov       ax, word ptr ds:[_wadfiles]
les       bx, dword ptr es:[bx + LUMPINFO_T.lumpinfo_position]
mov       cx, es
push      ax   ; fp
call      fseek_  ;    fseek(usedfile, l->position, SEEK_SET);



mov       bx, 1
mov       dx, 8
lea       ax, [bp - 8]
pop       cx  ; fp
push      ax  ; src
call      fread_   ;	fread(stackbuffer, 4, 2, usedfile);


mov       es, si   ; dest seg
pop       si       ; src  offset

movsw
movsw
movsw
movsw

LEAVE_MACRO     
pop       di
pop       si
pop       dx
ret       


ENDP

PROC    W_CacheLumpNumDirectWithOffset_ FAR
PUBLIC  W_CacheLumpNumDirectWithOffset_


; offset in dx
; size in si

mov       word ptr cs:[SELFMODIFY_set_start_offset_low + 1], dx
mov       word ptr cs:[SELFMODIFY_set_length + 1], si

call      W_ReadLump_

xor       ax, ax
mov       word ptr cs:[SELFMODIFY_set_start_offset_low + 1], ax
mov       word ptr cs:[SELFMODIFY_set_length + 1], ax


retf      


ENDP

; todo suck less

PROC    W_CacheLumpNumDirectFragment_ FAR
PUBLIC  W_CacheLumpNumDirectFragment_

push      bp
mov       bp, sp
mov       word ptr cs:[SELFMODIFY_set_length + 1], 16384
push      ax
mov       ax, word ptr [bp + 6]
mov       word ptr cs:[SELFMODIFY_set_start_offset_low + 1], ax
mov       ax, word ptr [bp + 8]
mov       word ptr cs:[SELFMODIFY_add_start_offset_high + 2], ax
pop       ax
call      W_ReadLump_
; reset it all to base
xor       ax, ax
mov       word ptr cs:[SELFMODIFY_set_length + 1], ax
mov       word ptr cs:[SELFMODIFY_set_start_offset_low + 1], ax
mov       word ptr cs:[SELFMODIFY_add_start_offset_high + 2], ax

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