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

MASKEDPOSTDATAOFS_OFFSET = (MASKEDPOSTDATAOFS_SEGMENT - MASKEDPOSTDATA_SEGMENT) SHL 4
MASKEDPIXELDATAOFS_OFFSET = (MASKEDPIXELDATAOFS_SEGMENT - MASKEDPOSTDATA_SEGMENT) SHL 4
MASKED_LOOKUP_OFFSET = (MASKED_LOOKUP_SEGMENT - MASKEDPOSTDATA_SEGMENT) SHL 4

TEXTUREDEFS_OFFSET_SEGMENT = (TEXTUREDEFS_OFFSET_SEGMENT - TEXTUREDEFS_BYTES_SEGMENT) SHL 4

PROC    R_GenerateLookup_ NEAR
PUBLIC  R_GenerateLookup_ 

PUSHA_NO_AX_OR_BP_MACRO
push      bp
mov       bp, sp

push      ax      ; bp - 2: texnum
xchg      ax, bx  ; texnum
mov       ax, MASKED_LOOKUP_SEGMENT
mov       es, ax
mov       byte ptr es:[bx], 0FFh  ; default state...   todo do this in a single big movsw earlier.
sal       bx, 1   ; texnum x 2
mov       ax, word ptr ds:[_currentlumpindex]
mov       word ptr ds:[bx + _texturepatchlump_offset], ax

;	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);
;	texturewidth = texture->width + 1;
;	textureheight = texture->height + 1;
;	usedtextureheight = textureheight + ((16 - (textureheight &0xF) ) & 0xF);

; todo use ds and lodsw?
; todo use same segment for these

mov       dx, TEXTUREDEFS_BYTES_SEGMENT   
mov       es, dx
mov       bx, word ptr es:[bx + TEXTUREDEFS_OFFSET_SEGMENT] ; texturedefs_offset[texnum]


;	textureheight = texture->height + 1;
;	usedtextureheight = textureheight + ((16 - (textureheight &0xF) ) & 0xF);
;	texturewidth = texture->width + 1;

xor       ax, ax
mov       byte ptr cs:[SELFMODIFY_is_masked+1], al       ; ismaskedtexture= 0

push      ax  ; bp - 4: currenttexturepixelbytecount = 0
mov       word ptr cs:[SELFMODIFY_set_currenttexturepostoffset + 1], ax ; set to 0
dec       ax  ; -1
mov       word ptr cs:[SELFMODIFY_compare_lastpatch+2], ax ; update lastpatch
; this gets updated first run anyway. does not to be initialized
;mov       word ptr cs:[SELFMODIFY_set_patchusedheight+1], ax ; patchusedheight

neg       ax  ; 1
mov       byte ptr cs:[SELFMODIFY_isSingleRLERun+1], al   ; isSingleRLERun = 1
mov       al, byte ptr es:[bx + TEXTURE_T.texture_height]
inc       ax  ; max 128
mov       word ptr cs:[SELFMODIFY_compare_textureheight+2], ax
add       al, 00Fh
and       al, 0F0h
mov       word ptr cs:[SELFMODIFY_add_usedtextureheight + 1], ax
mov       al, byte ptr es:[bx + TEXTURE_T.texture_width]
inc       ax
push      ax  ; bp - 6: texturewidth

push      dx  ; store TEXTUREDEFS_BYTES_SEGMENT [MATCH A]
mov       dl, byte ptr es:[bx + TEXTURE_T.texture_patchcount]  ; texturepatchcount = texture->patchcount;


;	for (eraseoffset = 0xFF00; eraseoffset != 0; eraseoffset+=2) {
;		*((uint16_t __far *) MK_FP(SCRATCH_PAGE_SEGMENT_7000, eraseoffset)) = 0;
;	}
    
; todo maskednum = -1 up here?

mov       si, SCRATCH_PAGE_SEGMENT_7000
mov       es, si

mov       di, 0FF00h
mov       cx, 128
xor       ax, ax
rep       stosw
pop       es ; TEXTUREDEFS_BYTES_SEGMENT   [MATCH A]
mov       ds, si ; SCRATCH_PAGE_SEGMENT_7000



; ch is 0 from rep stosw
mov       cl, dl   ; cx gets texturepatchcount
mov       byte ptr cs:[SELFMODIFY_set_texturepatchcount+1], cl

; es texturebytes
; ds 7000
; ? maybe we want to swap ds/es
; wadpatch = 7000

; patch    = texturebytes   (bx)


lea       bx, [bx + 0Bh] ; + 0Bh TEXTURE_T.texture_patches


loop_next_texture_patch:

; bx seems to be wrong.


mov       ax, word ptr es:[bx + TEXPATCH_T.texpatch_patch]
cwd       ; we will neg if ORIGINX_SIGN_FLAG is set. put sign bits in dx
and       ah, (PATCHMASK SHR 8)
xchg      ax, di   ; di gets patchpatch
xor       ax, ax
mov       al, byte ptr es:[bx + TEXPATCH_T.texpatch_originx] ; uint8_t to have neg flag applied
xor       ax, dx  ; cwd still set
sub       ax, dx  ; neg if 0

xchg      ax, si   ; si gets x1

; ds already 7000

SELFMODIFY_set_patchusedheight:
mov       ax, 01000h

push      bx  ; bx is popped till used way later [MATCH H]

SELFMODIFY_compare_lastpatch:
cmp       di, 01000h ; lastpatch
je        skip_patch_load

do_patch_load:
mov       ax, di  ; ax gets patchpatch
mov       word ptr cs:[SELFMODIFY_compare_lastpatch+2], ax ; update lastpatch
mov       word ptr cs:[SELFMODIFY_set_lastpatch+4], ax ; update lastpatch

push      cx ; backup [MATCH B]
push      ds ; backup [MATCH B]
mov       cx, ds   ; SCRATCH_PAGE_SEGMENT_7000
xor       bx, bx

push      ss
pop       ds

call      W_CacheLumpNumDirect_


pop       ds ; restore [MATCH B]
pop       cx ; restore [MATCH B]


mov       al, byte ptr ds:[0 + PATCH_T.patch_height]
add       al, 00Fh
and       ax, 000F0h ; xor ah here too
mov       word ptr cs:[SELFMODIFY_set_patchusedheight+1], ax ; patchusedheight


skip_patch_load:

; ds is 07000h
; dx is 0
; ax is patchusedheight from above


cwd       ; zero dx.... ah is known zero

; todo this
SELFMODIFY_subtract_firstpatch:
sub       di, word ptr ss:[_firstpatch]
sal       di, 1
; dx is zeroed above by a cbw
mov       dx, word ptr ds:[0 + PATCH_T.patch_width]
; if zero then make handle as 256 rare case so make it default to not doing that.
test      dl, dl
jz        handle_256_mul
mul       dl   ; patchusedheight * wadpatch->width; // used for non masked sizes. doesnt include colofs, headers.
dont_do_width_mul:

mov       word ptr cs:[SELFMODIFY_set_wadpatch_width+4], dx ; update lastpatch


mov       word ptr ss:[di + _patch_sizes], ax
;       x1 = patch->originx * (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);
;		x2 = x1 + (wadpatch->width);
mov       ax, si   ; x1 into ax
add       si, dx   ; ax = x1, si = x2
;		if (x1 < 0) {
;			x = 0;
;		} else {
;			x = x1;
;		}


cwd                 ; thanks smartest_blob
not       dx        ;
and       dx, ax    ; 0 if negative..

xchg      ax, si
; dx = x, ax = x2. si free (technicaly x1 not used)

mov       byte ptr cs:[SELFMODIFY_set_startx+4], dl ; startx = x...

cmp       ax, word ptr [bp - 6]  ; texturewidth
jle       dont_cap_x2       
mov       ax, word ptr [bp - 6]
dont_cap_x2:

cmp       dx, ax
jge       jump_to_done_with_patchcolumn ; gross

; inner loop iterates from x to x2. x1 no longer necessary, x2 can be selfmodified at the end


mov       word ptr cs:[SELFMODIFY_x2_compare+2], ax
mov       bx, dx                        ; startx = x


jmp       loop_next_patchcolumn         ; gross all gross
handle_256_mul:
mov       ah, al
xor       al, al
jmp       dont_do_width_mul
jump_to_done_with_patchcolumn:          
jmp       done_with_patchcolumn         ; gross make it stop
;  


;  cx in use in outer scope (numtextures) 
;  7000:si is the column

loop_next_patchcolumn:

inc       byte ptr ds:[0FF00h + bx] ; columnpatchcount[x]++;

SELFMODIFY_set_startx:
mov       byte ptr ds:[0F700h + bx], 010h  ; startpixel[x] = startx;
sal       bx, 1
SELFMODIFY_set_lastpatch:
mov       word ptr ds:[0F800h + bx], 01000h  ; texcollump[x] = patchpatch;
SELFMODIFY_set_wadpatch_width:
mov       word ptr ds:[0F500h + bx], 01000h  ; wadpatch->width;
xor       dx, dx ; column total size
mov       word ptr cs:[SELFMODIFY_getpatchcount+1], dx ; 0

SELFMODIFY_set_texturepatchcount:
mov       al, 010h
cmp       al, 1  
jne       multi_patch_skip  ; note in practice all masked textures are single patch. so we can skip masked preprocessing for any multi-patch texture..

;	maskedpixlofs[x] = currenttexturepixelbytecount; 
;	maskedtexpostdataofs[x] = (currentpostdataoffset)+ (currenttexturepostoffset << 1);

;	uint16_t __far*              maskedpixlofs        = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFC00);
;	uint16_t __far*              maskedtexpostdataofs = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFA00);

mov       ax, word ptr [bp - 4]          ; currenttexturepixelbytecount
mov       word ptr ds:[0FC00h + bx], ax  ; maskedpixlofs[x] = currenttexturepixelbytecount; 

SELFMODIFY_set_currenttexturepostoffset: 
mov       di, 01000h                     ; currenttexturepostoffset
; todo did something have to be SALed?
; maskedtexpostdataofs[x] = (currentpostdataoffset)+ (currenttexturepostoffset << 1);
mov       ax, word ptr ss:[_currentpostdataoffset]      ; todo make cs
add       ax, di
mov       si, bx  ;dword lookup
mov       si, word ptr ds:[si + bx + PATCH_T.patch_columnofs]

add       di, 0E000h    ; texmaskedpostdata offset
lodsw
cmp       al, 0FFh
je        found_end_of_patchcolumn
				; for ( ; (column->topdelta != 0xff)  ; )  {


loop_next_patchpost:

; es is also 7000h..
stosw  ; texmaskedpostdata[currenttexturepostoffset] = *((uint16_t __far *)column);

mov       al, ah
xor       ah, ah
add       si, ax                 ; add length to column
add       dx, ax                 ; columntotalsize += runsize;
add       al, 00Fh
and       al, 0F0h               ; runsize += (16 - ((runsize &0xF)) &0xF);
add       word ptr [bp - 4], ax  ; currenttexturepixelbytecount += runsize;

;	// copy both topdelta and length at once
;	texmaskedpostdata[currenttexturepostoffset] = *((uint16_t __far *)column);
;	currenttexturepostoffset ++;
inc       word ptr cs:[SELFMODIFY_getpatchcount+1]

; texmaskedpostdata[currenttexturepostoffset] = *((uint16_t __far *)column);

inc       si
inc       si  ; length + 4, but did lodsw already.
lodsw
cmp       al, 0FFh
jne       loop_next_patchpost

found_end_of_patchcolumn:


;	texmaskedpostdata[currenttexturepostoffset] = 0xFFFF; // end the post.
;	currenttexturepostoffset ++;
stosb ; texmaskedpostdata[currenttexturepostoffset] = *((uint16_t __far *)column);
stosb ; al was 0FFh. write it twice..

sub       di, 0E000h

mov       word ptr cs:[SELFMODIFY_set_currenttexturepostoffset + 1], di  ; write back for next iter


SELFMODIFY_getpatchcount:
mov       ax, 01000h
;   
;    all masked textures (NOT SPRITES) have at least one col with multiple columns
;    which adds up to less than texture height; seems to be an accurate enough check...
; if (colpatchcount > 1 && columntotalsize < textureheight ){
SELFMODIFY_compare_textureheight:
cmp       dx, 01000h
jge       not_masked
cmp       ax, 1
jle       not_masked

;	// most masked textures are not 256 wide. (the ones that are have tons of col patches.)
;	// but theres a couple bugged doom2 256x128 textures that have a pixel gap but arent masked. 
;	// However doom1 has some masked textures that have tons of gaps... We kind of hack around this bad data.
;	
;	if (texturewidth != 256 || colpatchcount > 3){
;		ismaskedtexture = 1;
;	}
cmp       ax, 3
jg        is_masked
cmp       word ptr [bp - 6], 256
je        not_masked
is_masked:
mov       byte ptr cs:[SELFMODIFY_is_masked+1], al ; known to be at least 3..

not_masked:

multi_patch_skip:

sar       bx, 1 ; undo word lookup
inc       bx
SELFMODIFY_x2_compare:
cmp       bx, 01000h
jge       done_with_patchcolumn
jmp       loop_next_patchcolumn
jump_to_loop_next_texture_patch:
jmp       loop_next_texture_patch
done_with_patchcolumn:
pop       bx  ; patch offset [MATCH H]

add       bx, 4 ; increment patch number
mov       ax, TEXTUREDEFS_BYTES_SEGMENT
mov       es, ax

loop      jump_to_loop_next_texture_patch


SELFMODIFY_is_masked:
mov       al, 010h


mov       cx, word ptr [bp - 6]         ; texturewidth


; note: dx and si and bx all free again?
mov       si, word ptr [bp - 2]  ; texnum
sal       si, 1
test      al, al
jz        skip_masked_stuff

;	uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, currentpixeloffset);
;	uint16_t __far* postofs    =  MK_FP(maskedpostdataofs_segment, currentpostoffset);
;	uint16_t __far* postdata   =  MK_FP(maskedpostdata_segment, currentpostdataoffset);
; we will use 8400 segment with offsets for all 3.

push      ds    ; store SCRATCH_PAGE_SEGMENT_7000 for ds later  [MATCH F]
push      ss
pop       ds    ; ds back to normal
mov       di, word ptr ds:[_maskedcount]  

mov       ax, MASKEDPOSTDATA_SEGMENT
mov       es, ax
mov       word ptr es:[si + MASKED_LOOKUP_OFFSET], di ;		masked_lookup[texnum] = maskedcount;	// index to lookup of struct...

SHIFT_MACRO  sal di 3
push      ds
pop       es  ; get normal data segment for stosw

push      ax  ; store MASKEDPOSTDATA_SEGMENT [MATCH D]

add       di, _masked_headers
mov       ax, word ptr ds:[_currentpixeloffset]                     ; currentpixeloffset 
stosw     ; masked_headers[maskedcount].pixelofsoffset = currentpixeloffset;
xchg      ax, bx  ; bx gets currentpixeloffset

mov       ax, word ptr ds:[_currentpostoffset]                      ; currentpostoffset
stosw     ; masked_headers[maskedcount].postofsoffset = currentpostoffset;
xchg      ax, si  ; si gets postsoffset



mov       ax, word ptr [bp - 4]           ; currenttexturepixelbytecount
stosw     ; masked_headers[maskedcount].texturesize = currenttexturepixelbytecount;
inc       word ptr ds:[_maskedcount]

; di free. done with ES as DS for maskedheaders writes

pop       es ; recover MASKEDPOSTDATA_SEGMENT [MATCH D]
pop       ds  ; SCRATCH_PAGE_SEGMENT_7000 [MATCH F]

;	// copy the offset data...
;	for (i = 0; i < texturewidth; i++){
;		pixelofs[i] = maskedpixlofs[i] >> 4;
;		postofs[i] = maskedtexpostdataofs[i];
;	}

; issues here 

mov       dx, cx ; backup texturewidth
lea       di, [si + MASKEDPOSTDATAOFS_OFFSET] 
mov       si, 0FA00h        ; maskedtexpostdataofs = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFA00);
rep       movsw
; todo self modify right above?
sub       di, MASKEDPOSTDATAOFS_OFFSET
mov       word ptr ss:[_currentpostoffset], di ; has been advanced the right amount

mov       cx, dx
lea       di, [bx + MASKEDPIXELDATAOFS_OFFSET]
mov       si, 0FC00h
write_next_pixel_data:
lodsw
SHIFT_MACRO sar ax 4
stosw
loop      write_next_pixel_data
; todo self modify right above?
sub       di, MASKEDPIXELDATAOFS_OFFSET
mov       word ptr ss:[_currentpixeloffset], di ; has been advanced the right amount


;	// copy the actual post data
;	for (i = 0; i < currenttexturepostoffset; i++){
;		postdata[i] = texmaskedpostdata[i];
;    }


mov       cx, word ptr cs:[SELFMODIFY_set_currenttexturepostoffset + 1]
mov       di, word ptr ss:[_currentpostdataoffset]
mov       si, 0E000h
rep       movsw
; todo self modify right above?
mov       word ptr ss:[_currentpostdataoffset], di ; has been advanced the right amount


mov       cx, dx      ; recover texturewidth

skip_masked_stuff:

; ds is 07000h
; cx is texturewidth

mov       si, 0FF00h                      ; columnpatchcount
xor       dx, dx                          ; totalcompositecolumns = 0;
xor       bx, bx                          ; word offset
mov       di, word ptr [bp - 2]           ; texnum
sal       di, 1                           ; textnum word offset
mov       ax, TEXTURECOMPOSITESIZES_SEGMENT
mov       es, ax
push      bp  ; we will use this in following loops

SELFMODIFY_add_usedtextureheight:
mov       bp, 01000h  ; usedtextureheight
push      cx   ; save texturewidth for post loop [MATCH I]
loop_next_column_check_2:
lodsb
; if al is zero this is a missing column.
cmp      al, 1
jb       do_error_no_column
je       not_composite
	; two plus patches in this column!
	; so it's composite.

mov      word ptr ds:[0F800h + bx], -1            ;   texcollump[x] = -1;
add      word ptr es:[di], bp                     ;   texturecompositesizes[texnum] += usedtextureheight;
; minus one extra for lodsb..
mov      byte ptr ds:[((0F000h - 0FF00h) - 1) + si], dl ;   startpixel[x] = totalcompositecolumns;
mov      word ptr ds:[0F500h + bx], MAXSHORT      ;   columnwidths[x] = MAXSHORT;
inc      dx                                       ;   totalcompositecolumns ++;

not_composite:
inc      bx
inc      bx  ; word offset

loop     loop_next_column_check_2
jmp      continue_to_final_rle_loop
do_error_no_column:
push      ss
pop       ds
push      cs
mov       ax, OFFSET str_bad_column_patch 
push      ax
call      I_Error_
jmp       exit_r_generate_composite
continue_to_final_rle_loop:
pop      cx  ; retrieve texturewidth  [MATCH I]

mov      ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov      es, ax
mov      ax, word ptr ds:[0F800h]               ; currentcollump = texcollump[0];
xor      bx, bx                                 ; currentcollumpRLEStart = 0;
mov      dx, word ptr ds:[0F700h]               ; startx = startpixel[0];
mov      si, 1
mov      di, word ptr ss:[_currentlumpindex]
sal      di, 1                                  ; word lookup

; es:di is collumps..


loop_next_RLE_run:

mov      bp, si                              ; bp + si for word lookup
cmp      ax, word ptr ds:[0F800h + si + bp]  ; if (currentcollump != texcollump[x] 
jne      do_new_RLE_run
mov      bp, word ptr ds:[0F500h + si + bp]  ; || (x - currentcollumpRLEStart) >= columnwidths[x]
add      bp, bx
cmp      bp, si
jbe      do_new_RLE_run     ; do unsigned becasue of MAXSHORT case...
mov      bp, si
cmp      word ptr ds:[0F800h + si + bp], -1  ; || (texcollump[x] != -1
je       not_new_RLE_run
cmp      dl, byte ptr ds:[0F700h + si]  ; && (startpixel[x] != startx))    // this handles cases like PLANET1 where AG128_1 ends then restarts again with other composite textures in between.
je       not_new_RLE_run
do_new_RLE_run:

mov      byte ptr cs:[SELFMODIFY_isSingleRLERun+1], 0       ; issingleRLErun = false;
mov      bp, si                                             ; bp + si for word lookup..
stosw         ; collump[currentlumpindex].h = currentcollump;
  ; es might be texturebytes??
;   es = 9000, di = b22
; currentlumpindex overran

; si is x
; bx is currentcollumpRLEStart

 neg     bx      ; (- currentcollumpRLEStart)
 dec     bx      ; -1
 lea     ax, [bx + si]  ; x + (-currentcollumpRLEStart - 1)     result: (x - currentcollumpRLEStart) - 1
 stosb                                    ; collump[currentlumpindex + 1].bu.bytelow = (x - currentcollumpRLEStart) - 1; 
 
 xchg    ax, dx
 stosb                                    ; collump[currentlumpindex + 1].bu.bytehigh = startx;

; di/currentlumpindex has been incremented via stosb

 mov     bx, si                           ; currentcollumpRLEStart = x;
 mov     dl, byte ptr ds:[0F700h + si]    ; startx = startpixel[x];
 
 mov     ax, word ptr ds:[0F800h + si + bp]    ; currentcollump = texcollump[x];


 

not_new_RLE_run:
 inc      si
 cmp      si, cx  ; x < texturewidth
 jl       loop_next_RLE_run

pop      bp  ; restore bp

stosw       ;	collump[currentlumpindex].h = currentcollump;

SELFMODIFY_isSingleRLERun:
mov      al, 010h;
test     al, al
je       not_single_run
;if (issingleRLErun)
;   startx = texturewidth-1;
mov      dx, cx   ; texturewidth
dec      dx
not_single_run:



; si is texturewidth upon loop completion

neg     bx      ; (- currentcollumpRLEStart)
dec     bx      ; -1
lea     ax, [bx + si]  ; x + (-currentcollumpRLEStart - 1)     result: (texturewidth - currentcollumpRLEStart) - 1 (x == texturewidth at loop end)
 
stosb                           ; collump[currentlumpindex + 1].bu.bytelow = (texturewidth - currentcollumpRLEStart) - 1;
xchg    ax, dx
stosb                           ; collump[currentlumpindex + 1].bu.bytehigh = startx;
sar     di, 1 
push    ss
pop     ds

mov     word ptr ds:[_currentlumpindex], di


exit_r_generate_composite:


LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret



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