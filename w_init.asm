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


EXTRN locallib_fseek_:NEAR
EXTRN locallib_ftell_:NEAR
EXTRN locallib_fopen_:NEAR
EXTRN locallib_far_fread_:NEAR


EXTRN DEBUG_PRINT_:NEAR



.DATA


; leave space for title text which is there
LUMPINFO_INIT_SEGMENT = BASE_LOWER_MEMORY_SEGMENT + 020h

.CODE

EXTRN SELFMODIFY_start_lump_for_search:BYTE

PROC    W_INIT_STARTMARKER_ NEAR
PUBLIC  W_INIT_STARTMARKER_
ENDP

str_good_wad:
db 09h, "adding %s", 0Ah, 0
str_bad_wad:
db 09h, "couldn't open %s", 0Ah, 0
handle_bad_file_couldnt_open:
mov     ax, OFFSET str_bad_wad
push    ax
call    DEBUG_PRINT_
jmp     exit_addfile

jump_to_do_non_wad:
jmp     do_non_wad


PROC    W_AddFile_ NEAR
PUBLIC  W_AddFile_

PUSHA_NO_AX_MACRO
push    bp
mov     bp, sp
sub     sp, SIZE WADINFO_T ; see mov ax, sp

xchg    ax, si 
mov     di, si ; backup addfile filename in di
xor     cx, cx ; iswad
do_next_char:
lodsb
test    al, al
je      not_wad
cmp    al, '.'
jne    do_next_char
cmp    word ptr ds:[si], 'w' + ('a' SHL 8)
jne    do_next_char
cmp    byte ptr ds:[si+2], 'd'
jne    do_next_char
not_filename_ext:
inc    cx  ; iswad = true

not_wad:




;usefp = wadfiles[currentloadedfileindex];

 
mov    ax, di
mov    dl, (FILEFLAG_READ OR FILEFLAG_BINARY)
call   locallib_fopen_

push   di  ; filename
push   cs  ; common DEBUG_PRINT args

test   ax, ax
je     handle_bad_file_couldnt_open

xchg   ax, si ; si gets fp
mov    al, byte ptr ds:[_currentloadedfileindex]
cbw
sal    ax, 1
xchg   ax, bx
mov    word ptr ds:[_wadfiles + bx], si     ;wadfiles[currentloadedfileindex] = fopen(filename, "rb");


mov    ax, OFFSET str_good_wad
push   ax
call   DEBUG_PRINT_
; this adds six to sp... just handle it later with leave_macro
 

jcxz   jump_to_do_non_wad


mov    bx, SIZE WADINFO_T ; 12
mov    ax, sp
mov    dx, ss
mov    cx, si
call   locallib_far_fread_
pop    ax
cmp    ax,  ('W' SHL 8) + 'I'  ; "IW"
pop    ax
jne    not_modified
cmp    ax,  ('D' SHL 8) + 'A'  ; "AD"
jne    not_modified
mov    byte ptr ds:[_modifiedgame], 1
not_modified:
pop    di   ; numlumps. hold on to that...


mov    ax, si  ; fp
pop    bx		
pop    bx	; infotableofs
pop    cx   ; infotableofs
xor    dx, dx ; SEEKSET
call   locallib_fseek_   ; fseek(usefp, header.infotableofs, SEEK_SET);
		

	

mov    ax, SIZE LUMPINFO_T
mul    di       ; length = header.wad_numlumps * sizeof(filelump_t);

xchg   ax, bx ; length
mov    cx, si ; fp
xor    ax, ax
mov    dx, SCRATCH_SEGMENT_5000

		


call   locallib_far_fread_  ;locallib_far_fread(fileinfo, length, usefp);

;call   W_UpdateNumLumps_  ; inlineable?
mov    ax, word ptr ds:[_numlumps]
add    word ptr ds:[_numlumps], di ; numlumps += header.wad_numlumps;


done_processing_wad_file:


inc    byte ptr ds:[_currentloadedfileindex] ; currentloadedfileindex++;

; ax has startlump
xchg   ax, bx ; now bx has it

;	for (i = startlump; i < numlumps; i++, lump_p++, fileinfo++) {

mov    ax, SIZE FILEINFO_T
mul    bx
xchg   ax, di  ; es:di gets lump_p
mov    dx, word ptr ds:[_numlumps]
mov    word ptr cs:[SELFMODIFY_start_lump_for_search+1], dx ; W_UpdateNumLumps_

mov    ax, SCRATCH_SEGMENT_5000
mov    ds, ax
mov    ax, LUMPINFO_INIT_SEGMENT
mov    es, ax
xor    si, si ; ds:si is fileinfo..
xor    cx, cx ; ch 0
loop_next_lump:

add    di, 8  ; name comes later
mov    cl, 4
;		lump_p->position = (fileinfo->filepos);
;		lump_p->size = (fileinfo->size);
rep    movsw
sub    di, size FILEINFO_T
mov    cl, 8

loop_next_filename_char:
lodsb
test   al, al
je     end_filename
stosb
loop   loop_next_filename_char
inc    si ; make up for the below case
end_filename:
add    si, cx
dec    si  ; lodsb would have run one extra in the break case
rep    stosb

add    di, 8 ; skip already copied stuff
inc    bx
cmp    bx, dx
jl     loop_next_lump


push   ss
pop    ds
; todo: necessary?
; mov    cx, 32768
; mov    ax, SCRATCH_SEGMENT_5000
; mov    es, ax
; xor    ax, ax
; xor    di, di
; rep    movsw

exit_addfile:
LEAVE_MACRO
POPA_NO_AX_MACRO
ret

do_non_wad:


mov    ax, LUMPINFO_INIT_SEGMENT
mov    es, ax
mov    ax, word ptr ds:[_numlumps]
push   ax   ; numlumps [MATCH A]
push   si   ; fp       [MATCH B]

mov    si, di ; filename




mov    dx, SIZE FILEINFO_T
mul    dx
xchg   ax, di  ; es:di gets lump_p

; inlined str_upper here
; copy upper filename

mov    cx, 8
loop_next_char_strupr:
lodsb
test   al, al
je     end_early
cmp    al, '.'
je     end_early
cmp    al, 'a'
jb     go_loop_next_char_strupr
cmp    al, 'z'
ja     go_loop_next_char_strupr
sub    al, 32
go_loop_next_char_strupr:
stosb
loop   loop_next_char_strupr
end_early:
xor    ax, ax
rep    stosb 

; done copying upper filename
pop    si  ; fp  [MATCH B]

mov    ax, cx ; 0
stosw
stosw  ; 0 offset dword

;xor    cx, cx
xor    bx, bx
mov    ax, si
mov    dx, 2 ; SEEKEND
call   locallib_fseek_  ; fseek(usefp, 0L, SEEK_END);
mov    ax, si
call   locallib_ftell_  ; singleinfo.size = ftell(usefp);

mov    cx, LUMPINFO_INIT_SEGMENT
mov    es, cx


stosw  ; size lo
xchg   ax, dx
stosw  ; size hi

xor    bx, bx
mov    bl, byte ptr ds:[_currentloadedfileindex]
dec    bx
shl    bx, 1

pop    word ptr ds:[bx + _filetolumpindex]  ;  [MATCH A]        filetolumpindex[currentloadedfileindex-1] = numlumps;
shl    bx, 1 ; dword lookup
mov    word ptr ds:[bx + _filetolumpsize], dx
mov    word ptr ds:[bx + _filetolumpsize + 2], ax ; filetolumpsize[currentloadedfileindex-1] = singleinfo.size;


xor    cx, cx
xor    bx, bx
xchg   ax, si
xor    dx, dx ; SEEK_SET
call   locallib_fseek_ ; ; fseek(usefp, 0L, SEEK_SET);


inc    word ptr ds:[_numlumps]  ; numlumps++;
inc    byte ptr ds:[_currentloadedfileindex] ; currentloadedfileindex++;


jmp    exit_addfile


ENDP
 
; used nowhere?
; old impl
COMMENT @ 
PROC   locallib_strupr_ NEAR
PUBLIC locallib_strupr_

push   si
xchg   ax, si
mov    ds, dx
loop_next_char_strupr:
lodsb
test   al, al
je     done_with_strupr
cmp    al, 'a'
jb     loop_next_char_strupr
cmp    al, 'z'
ja     loop_next_char_strupr
sub    al, 32
mov    byte ptr ds:[si-1], al
jmp    loop_next_char_strupr
done_with_strupr:
push   ss
pop    ds
pop    si

ret
ENDP
@

PROC    W_INIT_ENDMARKER_ NEAR
PUBLIC  W_INIT_ENDMARKER_
ENDP


END

