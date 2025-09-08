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
EXTRN Z_QuickMapRender_:FAR
EXTRN W_CacheLumpNumDirect_:FAR
EXTRN W_CacheLumpNameDirectFarString_:FAR
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN copystr8_:NEAR
EXTRN R_SetViewSize_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapMaskedExtraData_:FAR
EXTRN Z_QuickMapScratch_7000_:FAR
EXTRN R_FlatNumForName_:NEAR

.DATA

EXTRN _numspritelumps:WORD
EXTRN _numflats:WORD
EXTRN _numpatches:WORD
EXTRN _numtextures:WORD



.CODE


str_dot:
db ".", 0

str_bad_column_patch:
db "R_GenerateLookup: column without a patch", 0

str_triple_dot:
db '.'
str_double_dot:
db '.'
str_single_dot:
db '.', 0
str_f_sky1:
db "F_SKY1", 0


; num int16_ts needed on stack
MAX_PATCH_COUNT = 470

str_patch_start:
db "P_START", 0
str_patch_end:
db "P_END", 0

str_flat_start:
db "F_START", 0
str_flat_end:
db "F_END", 0

str_sprite_start:
db "S_START", 0
str_sprite_end:
db "S_END", 0


str_pnames:
db "PNAMES", 0
str_texture1:
db "TEXTURE1", 0
str_texture2:
db "TEXTURE2", 0
str_leftbracket:
db "[", 0
str_rightbracket:
db "         ]", 0
str_single_space:
db " ", 0
str_single_backspace:
db 08h, 0





COLORMAP_LUMP = 1





MASKEDPOSTDATAOFS_OFFSET = (MASKEDPOSTDATAOFS_SEGMENT - MASKEDPOSTDATA_SEGMENT) SHL 4
MASKEDPIXELDATAOFS_OFFSET = (MASKEDPIXELDATAOFS_SEGMENT - MASKEDPOSTDATA_SEGMENT) SHL 4
MASKED_LOOKUP_OFFSET = (MASKED_LOOKUP_SEGMENT - MASKEDPOSTDATA_SEGMENT) SHL 4

TEXTUREDEFS_OFFSET_OFFSET = (TEXTUREDEFS_OFFSET_SEGMENT - TEXTUREDEFS_BYTES_SEGMENT) SHL 4

PROC    R_GenerateLookup_ NEAR


PUSHA_NO_AX_MACRO


;	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);
;	texturewidth = texture->width + 1;
;	textureheight = texture->height + 1;
;	usedtextureheight = textureheight + ((16 - (textureheight &0xF) ) & 0xF);

; todo use ds and lodsw?
; todo use same segment for these



;	textureheight = texture->height + 1;
;	usedtextureheight = textureheight + ((16 - (textureheight &0xF) ) & 0xF);
;	texturewidth = texture->width + 1;

xor       ax, ax
mov       byte ptr cs:[SELFMODIFY_is_masked+1], al       ; ismaskedtexture= 0

mov       word ptr cs:[SELFMODIFY_currenttexturepixelbytecount + 1], ax          ; currenttexturepixelbytecount
mov       word ptr cs:[SELFMODIFY_set_currenttexturepostoffset + 1], ax ; set to 0
dec       ax  ; -1
mov       word ptr cs:[SELFMODIFY_compare_lastpatch+2], ax       		; update lastpatch
; this gets updated first run anyway. does not to be initialized
;mov       word ptr cs:[SELFMODIFY_set_patchusedheight+1], ax 		    ; patchusedheight

neg       ax  ; 1
mov       byte ptr cs:[SELFMODIFY_isSingleRLERun+1], al   			    ; isSingleRLERun = 1
mov       al, byte ptr es:[bx + TEXTURE_T.texture_height]
inc       ax  ; max 128
mov       word ptr cs:[SELFMODIFY_compare_textureheight+2], ax
add       al, 00Fh
and       al, 0F0h
mov       word ptr cs:[SELFMODIFY_add_usedtextureheight + 1], ax
mov       al, byte ptr es:[bx + TEXTURE_T.texture_width]
inc       ax
xchg      ax, bp  ; bp = texturewidth

push      es  ; store TEXTUREDEFS_BYTES_SEGMENT [MATCH A]  ; carried in from outside frame
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
shl       di, 1
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

cmp       ax, bp  ; texturewidth
jle       dont_cap_x2       
mov       ax, bp
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
shl       bx, 1
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

push      cx
SELFMODIFY_currenttexturepixelbytecount:
mov       cx, 01000h          ; currenttexturepixelbytecount
mov       word ptr ds:[0FC00h + bx], cx  ; maskedpixlofs[x] = currenttexturepixelbytecount; 

SELFMODIFY_set_currenttexturepostoffset: 
mov       di, 01000h                     ; currenttexturepostoffset << 1

SELFMODIFY_set_currentpostdataoffset: 
mov       ax, 01000h
add       ax, di

mov       word ptr ds:[0FA00h + bx], ax          ; maskedtexpostdataofs[x] = (currentpostdataoffset)+ (currenttexturepostoffset << 1);

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
add       cx, ax  ; currenttexturepixelbytecount += runsize;

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

mov       word ptr cs:[SELFMODIFY_currenttexturepixelbytecount + 1], cx          ; currenttexturepixelbytecount
pop       cx

;	texmaskedpostdata[currenttexturepostoffset] = 0xFFFF; // end the post.
;	currenttexturepostoffset ++;
stosb ; texmaskedpostdata[currenttexturepostoffset] = *((uint16_t __far *)column);
stosb ; al was 0FFh. write it twice..

sub       di, 0E000h

mov       word ptr cs:[SELFMODIFY_set_currenttexturepostoffset + 1], di  ; write back for next iter


SELFMODIFY_getpatchcount:
mov       ax, 01000h
;   
;    all masked textures (NOT SPRITES) have at least one col with multiple posts
;    which adds up to less than texture height; seems to be an accurate enough check...
; if (colpatchcount > 1 && columntotalsize < textureheight ){
SELFMODIFY_compare_textureheight:
cmp       dx, 01000h
jge       not_masked
cmp       al, 1
jle       not_masked

;	// most masked textures are not 256 wide. (the ones that apusre have tons of col patches.)
;	// but theres a couple bugged doom2 256x128 textures that have a pixel gap but arent masked. 
;	// However doom1 has some masked textures that have tons of gaps... We kind of hack around this bad data.
;	
;	if (texturewidth != 256 || colpatchcount > 3){
;		ismaskedtexture = 1;
;	}
cmp       al, 3
ja        is_masked
cmp       bp, 256
je        not_masked
is_masked:
mov       byte ptr cs:[SELFMODIFY_is_masked+1], al ; known to be at least 3..

not_masked:

multi_patch_skip:

shr       bx, 1 ; undo word lookup
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


mov       cx, bp         ; texturewidth


; note: dx and si and bx all free again?
test      al, al
jz        skip_masked_stuff

;	uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, currentpixeloffset);
;	uint16_t __far* postofs    =  MK_FP(maskedpostdataofs_segment, currentpostoffset);
;	uint16_t __far* postdata   =  MK_FP(maskedpostdata_segment, currentpostdataoffset);
; we will use 8400 segment with offsets for all 3.

push      ds    ; store SCRATCH_PAGE_SEGMENT_7000 for ds later  [MATCH F]
push      ss
pop       ds    ; ds back to normal

mov       ax, MASKEDPOSTDATA_SEGMENT
mov       es, ax
push      ax  ; store MASKEDPOSTDATA_SEGMENT [MATCH D]
SELFMODIFY_get_texnum:
mov       di, 01000h  ; texnum
SELFMODIFY_get_maskedcount:
mov       al, 00h;
cbw
mov       byte ptr es:[di + MASKED_LOOKUP_OFFSET], al ;		masked_lookup[texnum] = maskedcount;	// index to lookup of struct...
xchg      ax, di

SHIFT_MACRO  shl di 3
push      ds
pop       es  ; get normal data segment for stosw


add       di, _masked_headers
SELFMODIFY_set_currentpixeloffset:
mov       ax, 01000h							                     ; currentpixeloffset 
stosw     ; masked_headers[maskedcount].pixelofsoffset = currentpixeloffset;
xchg      ax, bx  ; bx gets currentpixeloffset


SELFMODIFY_set_currentpostoffset:
mov       ax, 01000h   					                      		; currentpostoffset


stosw     ; masked_headers[maskedcount].postofsoffset = currentpostoffset;
xchg      ax, si  ; si gets postsoffset



mov       ax, word ptr cs:[SELFMODIFY_currenttexturepixelbytecount + 1]  ; currenttexturepixelbytecount
stosw     ; masked_headers[maskedcount].texturesize = currenttexturepixelbytecount;
inc       byte ptr cs:[SELFMODIFY_get_maskedcount+1]

; di free. done with ES as DS for maskedheaders writes

pop       es ; recover MASKEDPOSTDATA_SEGMENT [MATCH D]
pop       ds  ; SCRATCH_PAGE_SEGMENT_7000 [MATCH F]

;	// copy the offset data...
;	for (i = 0; i < texturewidth; i++){
;		pixelofs[i] = maskedpixlofs[i] >> 4;
;		postofs[i] = maskedtexpostdataofs[i];
;	}

; issues here 

lea       di, [si + MASKEDPOSTDATAOFS_OFFSET] 
mov       si, 0FA00h        ; maskedtexpostdataofs = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFA00);
rep       movsw
; todo self modify right above?
sub       di, MASKEDPOSTDATAOFS_OFFSET
mov     word ptr cs:[SELFMODIFY_set_currentpostoffset+1], di

mov       cx, bp
lea       di, [bx + MASKEDPIXELDATAOFS_OFFSET]
mov       si, 0FC00h
write_next_pixel_data:
lodsw
SHIFT_MACRO shr ax 4
stosw
loop      write_next_pixel_data
; todo self modify right above?
sub       di, MASKEDPIXELDATAOFS_OFFSET

mov       word ptr cs:[SELFMODIFY_set_currentpixeloffset+1], di ; has been advanced the right amount


;	// copy the actual post data
;	for (i = 0; i < currenttexturepostoffset; i++){
;		postdata[i] = texmaskedpostdata[i];
;    }


mov       cx, word ptr cs:[SELFMODIFY_set_currenttexturepostoffset + 1]
shr       cx, 1 ; was a word lookup before..
mov       di, word ptr cs:[SELFMODIFY_set_currentpostdataoffset+1]
mov       si, 0E000h
rep       movsw

mov       word ptr cs:[SELFMODIFY_set_currentpostdataoffset+1], di ; has been advanced the right amount


mov       cx, bp      ; recover texturewidth

skip_masked_stuff:

; ds is 07000h
; cx is texturewidth

mov       si, 0FF00h                      ; columnpatchcount
xor       dx, dx                          ; totalcompositecolumns = 0;
xor       bx, bx                          ; word offset
SELFMODIFY_get_texnum_shifted:
mov       di, 01000h                      ; texnum sal 1
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
mov      byte ptr ds:[((0F700h - 0FF00h) - 1) + si], dl ;   startpixel[x] = totalcompositecolumns;
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
mov      di, word ptr cs:[SELFMODIFY_set_currentlumpindex+1]
shl      di, 1                                  ; word lookup

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
shr     di, 1 
push    ss
pop     ds

mov     word ptr cs:[SELFMODIFY_set_currentlumpindex+1] ,di



exit_r_generate_composite:

; todo clean up accurately...

POPA_NO_AX_MACRO
ret



ENDP




TEX_LOAD_ADDRESS_SEGMENT = 07000h
TEX_LOAD_ADDRESS_2_SEGMENT = 07800h

PROC   R_InitTextures_ NEAR


PUSHA_NO_AX_OR_BP_MACRO

push      bp
mov       bp, sp
sub       sp, 10 + (2 * MAX_PATCH_COUNT);  03B6h
mov       ax, OFFSET str_patch_start
mov       dx, cs
call      W_CheckNumForNameFarString_
inc       ax
mov       word ptr ds:[_firstpatch], ax
xchg      ax, cx
mov       ax, OFFSET str_patch_end
mov       dx, cs
call      W_CheckNumForNameFarString_
sub       ax, cx
mov       word ptr ds:[_numpatches], ax

mov       word ptr cs:[SELFMODIFY_set_numpatches+2], ax

mov       ax, OFFSET str_flat_start
mov       dx, cs
call      W_CheckNumForNameFarString_
inc       ax
mov       word ptr ds:[_firstflat], ax

xchg      ax, cx

mov       ax, OFFSET str_flat_end
mov       dx, cs
call      W_CheckNumForNameFarString_
sub       ax, cx
mov       word ptr ds:[_numflats], ax

mov       ax, OFFSET str_sprite_start
mov       dx, cs
call      W_CheckNumForNameFarString_

inc       ax
mov       word ptr ds:[_firstspritelump], ax
xchg      ax, cx

mov       ax, OFFSET str_sprite_end
mov       dx, cs
call      W_CheckNumForNameFarString_

sub       ax, cx
mov       word ptr ds:[_numspritelumps], ax

mov       word ptr cs:[SELFMODIFY_set_temp_to_numsprites+1], ax


mov       ax, OFFSET str_pnames

mov       di, TEX_LOAD_ADDRESS_SEGMENT
mov       cx, di
xor       bx, bx
mov       dx, cs
call      W_CacheLumpNameDirectFarString_  ; W_CacheLumpNameDirect("PNAMES", (byte __far*)TEX_LOAD_ADDRESS);



mov       es, di  ; 7000
xor       bx, bx
mov       byte ptr [bp - 2], bl   ; name[9] = 0;


mov       di, word ptr es:[bx]
mov       word ptr cs:[SELFMODIFY_pnames_loop_value+2], di

mov       di, bx ; 0 
mov       si, 4 ; name_p

;	temp = (*((int32_t  __far*)TEX_LOAD_ADDRESS));
;	name_p = (int8_t __far*)(TEX_LOAD_ADDRESS + 4);
;	for (i = 0; i < temp; i++) {
;		copystr8(name, name_p + (i << 3 ));
;		patchlookup[i] = W_CheckNumForName(name);
;	}


;alternatively movsw x4 instead of copystr8_?
; this is actually a pretty slow loop. could be improved... how?
loop_next_patchlookup:


mov       dx, ss
lea       ax, [bp - 0Ah]  
mov       bx, si
mov       cx, SCRATCH_PAGE_SEGMENT_7000
call      copystr8_

mov       dx, ss
lea       ax, [bp - 0Ah]  ; todo whatever
call      W_CheckNumForNameFarString_

shl       di, 1
mov       word ptr ds:[bp - 03B6h + di], ax         ; patchlookup[i] = W_CheckNumForName(name);
shr       di, 1


add       si, 8
inc       di
SELFMODIFY_pnames_loop_value:
cmp       di, 01000h
jl        loop_next_patchlookup  


mov       ax, OFFSET str_texture1
mov       di, SCRATCH_PAGE_SEGMENT_7000
mov       cx, di
xor       bx, bx
mov       dx, cs
call      W_CacheLumpNameDirectFarString_           ; W_CacheLumpNameDirect("TEXTURE1", (byte __far*)TEX_LOAD_ADDRESS);

mov       es, di
xor       bx, bx
mov       ax, word ptr es:[bx]  ; numtextures = numtextures1 = * ((int16_t __far*)TEX_LOAD_ADDRESS);
mov       word ptr cs:[SELFMODIFY_numtextures1 + 2], ax
mov       word ptr ds:[_numtextures], ax




mov       dx, cs
mov       ax, OFFSET str_texture2
call      W_CheckNumForNameFarString_
test      ax, ax 
js        no_texture2_patch                          ; if (W_CheckNumForName("TEXTURE2") != -1) {


mov       ax, OFFSET str_texture2
mov       cx, TEX_LOAD_ADDRESS_2_SEGMENT
xor       bx, bx
mov       dx, cs
call      W_CacheLumpNameDirectFarString_  ; W_CacheLumpNameDirect("TEXTURE2", (byte __far*)TEX_LOAD_ADDRESS);

;		numtextures +=  * ((int16_t __far*)TEX_LOAD_ADDRESS_2);

mov       ax, TEX_LOAD_ADDRESS_2_SEGMENT
mov       es, ax
xor       bx, bx
mov       ax, word ptr es:[bx]  
add       word ptr ds:[_numtextures], ax ; numtextures +=  * ((int16_t __far*)TEX_LOAD_ADDRESS_2);

no_texture2_patch:


;	DEBUG_PRINT("[");
;	for (i = 0; i < temp; i++) {
;		DEBUG_PRINT(" ");
;	}
;	DEBUG_PRINT("         ]");
;	for (i = 0; i < temp; i++) {
;		DEBUG_PRINT("\x8");
;	}
;	DEBUG_PRINT("\x8\x8\x8\x8\x8\x8\x8\x8\x8\x8");

SELFMODIFY_set_temp_to_numsprites:
mov       ax, 01000h            ;	temp = (W_GetNumForName("S_END") - 1) - W_GetNumForName("S_START");
add       ax, 63
SHIFT_MACRO shr ax 6
mov       cx, word ptr ds:[_numtextures]
mov       word ptr cs:[SELFMODIFY_compare_numtextures + 2], cx
add       cx, 63
SHIFT_MACRO shr cx 6
add       cx, ax                ; temp = ((temp + 63) / 64) + ((numtextures + 63) / 64);


push      cs
mov       ax, OFFSET str_leftbracket
push      ax
call      DEBUG_PRINT_
add       sp, 4

mov       bx, cx

loop_print_space:
push      cs
mov       ax, OFFSET str_single_space
push      ax
call      DEBUG_PRINT_
push      ax
add       sp, 4

loop      loop_print_space

push      cs
mov       ax, OFFSET str_rightbracket
push      ax
call      DEBUG_PRINT_
add       sp, 4

lea       cx, [bx + 10]  ; ten extra backspaces..

loop_print_backspace:
push      cs
mov       ax, OFFSET str_single_backspace
push      ax
call      DEBUG_PRINT_
add       sp, 4
loop      loop_print_backspace

xor       di, di   ; i


mov       ax, TEX_LOAD_ADDRESS_SEGMENT
mov       ds, ax
mov       bx, 4    ; "directory"/texture location  ; todo use si and lodsw pairs for smaller code...

; ds will be texaddress segment...
; es will mostly be tex1 or tex2 segment todo test doom2 with that.

; MAIN inittextures loop!
; MAIN inittextures loop!
; MAIN inittextures loop!


loop_init_next_texture:
test      di, 63
jne       done_printing_dot_2
print_another_dot:

push      ds  ; store ds
push      ss
pop       ds

push      cs
mov       ax, OFFSET str_single_dot
push      ax
call      DEBUG_PRINT_
add       sp, 4
pop       ds  ; recover ds
done_printing_dot_2:

SELFMODIFY_numtextures1:
cmp       di, 0EEEEh
jne       done_resetting_tex_vars

mov       ax, TEX_LOAD_ADDRESS_2_SEGMENT
mov       ds, ax
mov       bx, 4   ; alternatively just set bx to 8004?

done_resetting_tex_vars:



mov       si, word ptr ds:[bx]           ; mtexture = (maptexture_t  __far*)MK_FP(maptexsegment, *directory);
; ds:si is maptex

push    bx          ; [STACK D] bx
push    di          ; [STACK C] di
mov     ax, TEXTUREDEFS_BYTES_SEGMENT
mov     es, ax
mov     bx, di 
shl     bx, 1


lea       ax, [di + 1]
cmp       di, word ptr ss:[_numtextures]  ;	if ((i + 1) < numtextures) {
mov       di, word ptr es:[bx + TEXTUREDEFS_OFFSET_OFFSET]  ; texturedefs_offset[i]

jg        skip_setting_texdefoffset  

;	// texturedefs sizes are variable and dependent on texture size/texture patch count.
;	texturedefs_offset[i + 1] = texturedefs_offset[i] + (sizeof(texture_t) + sizeof(texpatch_t)*((mtexture->patchcount) - 1));
; todo selfmodify this ahead to the other di check (?)

mov       al, byte ptr ds:[si + MAPTEXTURE_T.maptexture_patchcount]
mov       ah, SIZE TEXPATCH_T
mul       ah

add       ax, di
add       ax, SIZE TEXTURE_T   ; todo double check 
mov       word ptr es:[bx + TEXTUREDEFS_OFFSET_OFFSET + 2], ax  ; texturedefs_offset[i + 1],



skip_setting_texdefoffset:

; ds:si is maptex
; es:di is tex

movsw
movsw
movsw
movsw ; name[8]     ; FAR_memcpy(texture->name, mtexture->name, sizeof(texture->name));
add     si, 4       ;           skip padding
lodsw   ; width     ;		texture->width = (mtexture->width) - 1;
push    ax          ;       [STACK B] texturewidth = texture->width + 1;
dec     ax
stosb
lodsw   ; height
dec     ax
push    ax          ;       [STACK A] textureheightval = texture->height; 
stosb               ;		texture->height = (mtexture->height) - 1;
add     si, 4       ;           skip padding
lodsw               ;		texture->patchcount = (mtexture->patchcount);
stosb




xchg    ax, cx
; cx gets patchcount


loop_next_patch:

lodsw
test    ax, ax
cwd     ; dx = 0 or FFFF
jns     dont_make_pos
neg     ax
dont_make_pos:
and     dx, 08000h  ; dx is 08000h or 0...
stosb       ; patch->originx = abs(mpatch->originx);
lodsw
stosb       ; patch->originy = (mpatch->originy);
lodsw
shl     ax, 1
xchg    ax, si
mov     si, word ptr ss:[bp - 03B6h + si]
xchg    ax, si 
add     ax, dx          ; (mpatch->originx < 0 ? 0x8000 : 0)
stosw                   ; patch->patch = patchlookup[(mpatch->patch)] + (mpatch->originx < 0 ? 0x8000 : 0);
add     si, 4            ; skip a couple unused int16_t fields..
loop    loop_next_patch

pop       dx            ; [STACK A] textureheightval
pop       cx            ; [STACK B] texturewidth
pop       di            ; [STACK C] di
pop       bx            ; [STACK D] bx

mov       ax, 1
shift_width_again:
shl       ax, 1
cmp       ax, cx ; texturewidth  ; todo alternatively shift until cx 0?
jle       shift_width_again
done_shifting_width:
shr       ax, 1 ; undo one
dec       ax   


push      es    ; [STACK A] es

mov       cx, TEXTUREWIDTHMASKS_SEGMENT
mov       es, cx
stosb                   ; texturewidthmasks[i] = j - 1;
dec       di            ; undo stosb

mov       cx, TEXTUREHEIGHTS_SEGMENT
mov       es, cx
xchg      ax, dx
stosb
dec       di

mov       cx, TEXTURECOLLENGTH_SEGMENT
mov       es, cx
inc       ax
add       al, 15
and       al, 0F0h
SHIFT_MACRO  shr al, 4
stosb

pop       es   ; [STACK A] es


add       bx, 4
; di incremented by last stosb...
SELFMODIFY_compare_numtextures:
cmp       di, 01000h
jge       exit_loop_init_next_texture
jmp       loop_init_next_texture
exit_loop_init_next_texture:

push      ss 
pop       ds  ; restore ds


call      Z_QuickMapMaskedExtraData_
call      Z_QuickMapScratch_7000_
mov       ax, TEXTUREDEFS_OFFSET_SEGMENT
mov       es, ax
xor       di, di
xor       dx, dx
mov       word ptr es:[di], di

mov       cx, word ptr ds:[_numtextures]
mov       dx, cx ; backup

;texturecompositesizes[i] = 0;
mov       ax, TEXTURECOMPOSITESIZES_SEGMENT
mov       es, ax
xor       ax, ax
mov       di, ax

rep       stosw

; inlined old R_InitTextures2_

mov       di, MASKED_LOOKUP_SEGMENT
mov       es, di
mov       di, ax  ; zero again
mov       cx, dx  ; get _numtextures back

dec       ax  ; ffh

shr       cx, 1
rep       stosw
rcl       cx, 1
rep       stosb

inc       ax  ; zero


mov       di, TEXTURETRANSLATION_SEGMENT
mov       es, di
mov       di, ax  ; zero again

mov       cx, dx  ; get _numtextures back


loop_next_texture:
stosw
inc       ax
loop      loop_next_texture

mov       cx, dx

mov       di, TEXTUREDEFS_BYTES_SEGMENT   

loop_next_lookup:
mov       ax, dx
sub       ax, cx

mov       word ptr cs:[SELFMODIFY_get_texnum+1], ax
sal       ax, 1
mov       word ptr cs:[SELFMODIFY_get_texnum_shifted+1], ax
xchg      ax, bx  ; texnum x 2

SELFMODIFY_set_currentlumpindex:
mov       ax, 01000h  ; currentlumpindex
mov       word ptr ds:[bx + _texturepatchlump_offset], ax

mov       es, di
mov       bx, word ptr es:[bx + TEXTUREDEFS_OFFSET_OFFSET] ; texturedefs_offset[texnum]

call      R_GenerateLookup_
loop      loop_next_lookup



call      Z_QuickMapRender_

LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret




ENDP











PROC   R_Init_ NEAR
PUBLIC R_Init_ 

PUSHA_NO_AX_OR_BP_MACRO

call      Z_QuickMapRender_

mov       cx, COLORMAPS_SEGMENT
mov       ax, COLORMAP_LUMP
xor       bx, bx

mov     word ptr cs:[SELFMODIFY_set_currentlumpindex+1], bx   ; zero this
mov     word ptr cs:[SELFMODIFY_set_currentpostoffset+1], bx  ; zero this
mov     word ptr cs:[SELFMODIFY_set_currentpixeloffset+1], bx  ; zero this
mov     word ptr cs:[SELFMODIFY_set_currentpostdataoffset+1], bx  ; zero this




call      W_CacheLumpNumDirect_
       
;call      R_InitData_

; inlined

mov       ax, TEXTUREDEFS_OFFSET_SEGMENT
mov       es, ax
xor       di, di
mov       word ptr es:[di], di
call      R_InitTextures_

push      cs
mov       ax, OFFSET str_double_dot
push      ax
call      DEBUG_PRINT_

;call      R_InitPatches_

;inlined

mov       si, SCRATCH_PAGE_SEGMENT_7000
xor       di, di   ; counters

loop_next_patch_init:
mov       ax, word ptr ds:[_firstpatch]  ; todo probably selfmodifiable from outside the func
mov       cx, si
add       ax, di
xor       bx, bx


; !!!!todo... can this be done by scanning wad data directly instead of loading every lump
; actually probably not that slow though (?)

call      W_CacheLumpNumDirect_ ;		W_CacheLumpNumDirect(patchindex, (byte __far*)wadpatch);


mov       es, si  ; 7000
les       ax, dword ptr es:[0 + PATCH_T.patch_width]      ; width
; mov       dx, word ptr es:[0 + PATCH_T.patch_height]  ; height
mov       dx, es  ; height
mov       cx, PATCHWIDTHS_SEGMENT
mov       es, cx ; patchheights

stosb
dec       di

xchg      ax, dx
add       al, 0Fh
and       al, 0F0h
mov       ah, al
SHIFT_MACRO SHR ah, 4
or        al, ah        ; patchheight |= (patchheight >> 4);
mov       cx, PATCHHEIGHTS_SEGMENT
mov       es, cx ; patchheights
stosb

SELFMODIFY_set_numpatches:
cmp       di, 01000h
jl        loop_next_patch_init
exit_r_initpatches:

mov       di, FLATTRANSLATION_SEGMENT
mov       es, di

xor       ax, ax
mov       di, ax
mov       cx, word ptr ds:[_numflats]
loop_next_anim:
stosb
inc       ax
loop      loop_next_anim

jmp       do_R_InitSpriteLumps_

do_print_dot:
push      cs
mov       ax, OFFSET str_dot
push      ax
call      DEBUG_PRINT_       
add       sp, 4
jmp       done_printing_dot


;call      R_InitSpriteLumps_
do_R_InitSpriteLumps_:
; inlined

xor       dx, dx
cmp       byte ptr ds:[_is_ultimate], dl ; 0
mov       ax, SPRITEWIDTHS_NORMAL_SEGMENT
je        not_ultimate
mov       ax, SPRITEWIDTHS_ULT_SEGMENT

not_ultimate:
mov       word ptr ds:[_spritewidths_segment], ax
mov       bp, dx ; 0


; set up sprite stuff in memory
Z_QUICKMAPAI3 pageswapargs_maskeddata_offset_size   	INDEXED_PAGE_8400_OFFSET


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

; abs ax
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

shl       di, 1

mov       bx, word ptr ds:[0 + PATCH_T.patch_width]

SHIFT_MACRO shl       bx 2
lea       ax, [bx + di + 8] ; di is post size


add       ax, 0Fh
and       ax, 0FFF0h
add       dx, ax  ; pixelsize + startoffset


mov       bx, bp
shl       bx, 1

mov       ax, SPRITETOTALDATASIZES_SEGMENT
mov       es, ax
mov       word ptr es:[bx], dx

mov       ax, SPRITEPOSTDATASIZES_SEGMENT
mov       es, ax
mov       word ptr es:[bx], di



inc       bp 
cmp       bp, word ptr ds:[_numspritelumps]
jge       exit_r_initspritelumps
jmp       loop_next_sprite
exit_r_initspritelumps:

call      Z_QuickMapRender_  ; undo flat cache stuff. 

push      cs
mov       ax, OFFSET str_single_dot
push      ax
call      DEBUG_PRINT_


push      cs
mov       ax, OFFSET str_double_dot
push      ax
call      DEBUG_PRINT_

mov       dl, byte ptr ds:[_detailLevel]
mov       al, byte ptr ds:[_screenblocks]
call      R_SetViewSize_
push      cs
mov       ax, OFFSET str_triple_dot
push      ax
call      DEBUG_PRINT_


call      Z_QuickMapPhysics_
mov       dx, cs
mov       ax, OFFSET str_f_sky1
call      R_FlatNumForName_
mov       byte ptr ds:[_skyflatnum], al

push      cs
mov       ax, OFFSET str_single_dot
push      ax

call      DEBUG_PRINT_
add       sp, 20  ; five debug prints..

POPA_NO_AX_OR_BP_MACRO
ret     


ENDP


END