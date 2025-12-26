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

EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapRender_:FAR
EXTRN Z_QuickMapRenderPlanes_:FAR
EXTRN Z_QuickMapUndoFlatCache_:FAR
EXTRN Z_QuickMapWADPageFrame_:FAR
EXTRN copystr8_:NEAR
EXTRN FixedDivWholeA_:FAR
EXTRN FixedMul_:FAR
EXTRN FixedMul_:FAR
EXTRN CopyString13_:NEAR
EXTRN fread_:FAR
EXTRN fseek_:FAR
EXTRN fopen_:FAR
EXTRN fclose_:FAR
EXTRN locallib_far_fread_:FAR
EXTRN DEBUG_PRINT_NOARG_CS_:NEAR
EXTRN R_TextureNumForName_:NEAR
EXTRN R_CheckTextureNumForName_:NEAR
EXTRN R_FlatNumForName_:NEAR
EXTRN W_CheckNumForName_:NEAR
EXTRN R_InstallSpriteLump_:NEAR
EXTRN W_GetNumForName_:FAR
EXTRN Z_QuickMapRender_9000To6000_:NEAR
 
.DATA

EXTRN _p_init_maxframe:WORD
EXTRN _p_init_sprtemp:DWORD
.CODE

EXTRN  _doomdata_bin_string:NEAR

PROC    P_INIT_STARTMARKER_ NEAR
PUBLIC  P_INIT_STARTMARKER_
ENDP


NUMSWITCHDEFS = 41
BAD_TEXTURE = 0FFFFh
NUMANIMDEFS = 23
NUMSSPRITEDEFS = 29

PROC    P_InitSwitchList_ NEAR
PUBLIC  P_InitSwitchList_

PUSHA_NO_AX_OR_BP_MACRO
push   bp
mov    bp, sp
sub    sp, (NUMSWITCHDEFS * (SIZE SWITCHLIST_T))

mov   ax, OFFSET _doomdata_bin_string
call  CopyString13_
mov   dx, OFFSET  _fopen_rb_argument
call  fopen_        ; fopen("DOOMDATA.BIN", "rb"); 
mov   di, ax ; di stores fp

xor   dx, dx  ; SEEK_SET
mov   bx, SWITCH_DOOMDATA_OFFSET AND 0FFFFh
mov   cx, SWITCH_DOOMDATA_OFFSET SHR 16
call  fseek_  ;    fseek(fp, SWITCH_DOOMDATA_OFFSET, SEEK_SET);

;fread(alphSwitchList, sizeof(switchlist_t), NUMSWITCHDEFS, fp);
mov   ax, sp
mov   cx, di ; fp
mov   dx, SIZE SWITCHLIST_T
mov   bx, NUMSWITCHDEFS
call  fread_

xchg  ax, di
call  fclose_

;	if (registered){
;		episode = 2;
;	} else if (commercial){
;		episode = 3;
;	}


mov   bx, 1  ; episode
xor   ax, ax
cmp   byte ptr ds:[_registered], al
je    not_ep_2
inc   bx
jmp   got_ep
not_ep_2:
cmp   byte ptr ds:[_commercial], al
je    not_ep_3
inc   bx
inc   bx
not_ep_3:
got_ep:


;	for (index = 0, i = 0; i < MAXSWITCHES; i++) {
;		if (!alphSwitchList[i].episode) {
;			numswitches = index >> 1;
;			switchlist[index] = BAD_TEXTURE;
;			break;
;		}
;
;		if (alphSwitchList[i].episode <= episode) {
;
;			switchlist[index++] = R_TextureNumForName(alphSwitchList[i].name1);
;			switchlist[index++] = R_TextureNumForName(alphSwitchList[i].name2);
;		}
;	}

mov   di, OFFSET _switchlist
mov   si, sp

mov   dx, ss

mov   cx, NUMSWITCHDEFS


; es:di = switchlist[index]
; ds:si = alphSwitchList
; bx = episode

iter_next_switch:
cmp   word ptr ds:[si + SWITCHLIST_T.switchlist_episode], 0
je    episode_undefined

cmp   word ptr ds:[si + SWITCHLIST_T.switchlist_episode], bx
jg    skip_switch_for_episode

lea   ax, [si + SWITCHLIST_T.switchlist_name1]
call  R_TextureNumForName_
mov   es, dx
stosw
lea   ax, [si + SWITCHLIST_T.switchlist_name2]
call  R_TextureNumForName_
mov   es, dx
stosw

skip_switch_for_episode:
add   si, SIZE SWITCHLIST_T
loop  iter_next_switch

done_with_switches:
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret

episode_undefined:
mov   ds:[di], BAD_TEXTURE
sub   di, OFFSET _switchlist
SHIFT_MACRO shr       di 2
mov   word ptr ds:[_numswitches], di
jmp   done_with_switches

ENDP


PROC    P_InitPicAnims_ NEAR
PUBLIC  P_InitPicAnims_

PUSHA_NO_AX_OR_BP_MACRO
push   bp
mov    bp, sp
sub    sp, (NUMANIMDEFS * (SIZE ANIMDEF_T)) +1   ; +1 because its odd... i think odd SP is bad


mov   ax, OFFSET _doomdata_bin_string
call  CopyString13_
mov   dx, OFFSET  _fopen_rb_argument
call  fopen_        ; fopen("DOOMDATA.BIN", "rb"); 
mov   di, ax ; di stores fp

; no fseek? at the start of the file i guess

;fread(animdefs, sizeof(animdef_t), NUMANIMDEFS, fp);
mov   ax, sp
mov   cx, di ; fp
mov   dx, SIZE ANIMDEF_T
mov   bx, NUMANIMDEFS
call  fread_

xchg  ax, di
call  fclose_

mov   di, OFFSET _anims
mov   si, sp
mov   cx, NUMANIMDEFS


; di = anims/lastanim
; si = animdefs


loop_next_animdef:
lea   ax, [si + ANIMDEF_T.animdef_startname]
lea   bx, [si + ANIMDEF_T.animdef_endname]

cmp   byte ptr ds:[si + ANIMDEF_T.animdef_istexture], ch ; known zero
je    not_texture
is_texture:
; different episode?
;			if (R_CheckTextureNumForName(animdefs[i].startname) == BAD_TEXTURE)
;				continue;
call  R_CheckTextureNumForName_
cmp   ax, BAD_TEXTURE
je    continue_animdef_loop

;    lastanim->picnum = R_TextureNumForName(animdefs[i].endname);
;    lastanim->basepic = R_TextureNumForName(animdefs[i].startname);
xchg  ax, bx    ; bx stores startname result, ax gets endname ptr
call  R_TextureNumForName_
jmp   done_with_anim_picnames
not_texture:
;			if (W_CheckNumForName(animdefs[i].startname) == -1)
;				continue;
call  W_CheckNumForName_
cmp   ax, -1
je    continue_animdef_loop
lea   ax, [si + ANIMDEF_T.animdef_startname]
mov   dx, ss
call  R_FlatNumForName_
xchg  ax, bx    ; bx stores startname result, ax gets endname ptr
mov   dx, ss
call  R_FlatNumForName_

done_with_anim_picnames:

; todo reorder to make this easier to stosb? 0 2 4 5

;    lastanim->istexture = animdefs[i].istexture;
;	 lastanim->numpics = lastanim->picnum - lastanim->basepic + 1;


push  ds
pop   es
movsb ; 
push  ax  ; store for math...
sub   ax, bx
inc   ax
stosb ; lastanim->numpics
pop   ax  ; recover original
stosw ; lastanim->picnum
xchg  ax, bx
stosw ; lastanim->basepic

; advanced via stos 
;add   di, SIZE P_SPEC_ANIM_T

dec    si  ; undo that movsb..

continue_animdef_loop:

add   si, SIZE ANIMDEF_T

loop  loop_next_animdef

mov   word ptr ds:[_lastanim], di

LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret

ENDP

SIZE_SPRITE_NAMES = 5 * NUMSPRITES
SIZE_LOCALNAME =    (5 * NUMSPRITES) + 8
; plus 1 because odd..
SIZE_SPR_TEMP = (NUMSSPRITEDEFS * (SIZE SPRITEFRAME_T)) + (5 * NUMSPRITES) + 8 + 1

; 



PROC    R_InitSprites_ NEAR
PUBLIC  R_InitSprites_



PUSHA_NO_AX_OR_BP_MACRO
push   bp
mov    bp, sp
; 690 + 725 + 8 + 1 = 1424
sub    sp, SIZE_SPR_TEMP

;FAR_memset(negonearray, -1, SCREENWIDTH);
mov   ax, NEGONEARRAY_SEGMENT + (OFFSET_NEGONEARRAY SHR 4)
mov   es, ax
xor   di, di
mov   ax, 0FFFFh
mov   cx, SCREENWIDTH / 2
rep   stosw

; inlined now
; R_InitSpriteDefs();


mov   ax, OFFSET _doomdata_bin_string
call  CopyString13_
mov   dx, OFFSET  _fopen_rb_argument
call  fopen_        ; fopen("DOOMDATA.BIN", "rb"); 
mov   di, ax ; di stores fp

xor   dx, dx  ; SEEK_SET
mov   bx, SPLIST_DOOMDATA_OFFSET AND 0FFFFh
mov   cx, SPLIST_DOOMDATA_OFFSET SHR 16
call  fseek_  ;    fseek(fp, SWITCH_DOOMDATA_OFFSET, SEEK_SET);

;fread(namelist,  5, NUMSPRITES, fp);
lea   ax, [bp - SIZE_SPRITE_NAMES]
mov   cx, di ; fp
mov   dx, 5
mov   bx, NUMSPRITES
call  fread_

xchg  ax, di
call  fclose_


;	p_init_sprtemp = (spriteframe_t __far *) &sprtempbytes;
mov   word ptr ds:[_p_init_sprtemp+0], sp   ; equal to [bp - SIZE_SPR_TEMP]
mov   word ptr ds:[_p_init_sprtemp+2], ss
;	lumpinfo_t __far* lumpinfoInit = ((lumpinfo_t __far*) MK_FP(WAD_PAGE_FRAME_PTR, 0));
; localname is bp - SIZE_SPRITE_NAMES - 8



; loop start

mov   ax, word ptr ds:[_firstspritelump]	
mov   word ptr cs:[_SELFMODIFY_setstart + 1], ax
add   ax, word ptr ds:[_numspritelumps]
mov   word ptr cs:[_SELFMODIFY_set_end + 2], ax

lea   si, [bp - SIZE_SPRITE_NAMES]  ; namelist

loop_next_sprite:
les   di, dword ptr ds:[_p_init_sprtemp]
;		FAR_memset(p_init_sprtemp, -1, sizeof(p_init_sprtemp));
mov   ax, -1
mov   cx, ((NUMSSPRITEDEFS * (SIZE SPRITEFRAME_T)) / 2) + 1  ; round up... we added an extra byte anyway.
rep   stosw
mov   word ptr ds:[_p_init_maxframe], ax

lodsw
xchg  ax, dx
lodsw
xchg  ax, cx
; dx then cx are the 4 characters
inc   si  ; 5th byte of the name is 0, ignore

push  si  ; store this loop var.

_SELFMODIFY_setstart:
mov   si, 01000h

;		for (l = start + 1; l < end; l++) {

mov   di, si ; di will be the lump offset
; sizeof lumpinfo_t is 16
SHIFT_MACRO shl di 4

loop_start_to_end:

;    int16_t lump = l & (LUMP_PER_EMS_PAGE - 1);
mov   ax, si

call  Z_QuickMapWADPageFrame_
mov   es, word ptr ds:[_WAD_PAGE_FRAME_PTR]
and   di, 16383 


;     if (*(int32_t  __far*)lumpinfoInit[lump].name == intname) {
; compare four characters basically
cmp   dx, word ptr es:[di + 0]
jne   not_this_sprite
cmp   cx, word ptr es:[di + 2]
je    is_this_sprite
not_this_sprite:
done_processing_sprite_lump:

add   di, SIZE LUMPINFO_T
inc   si 
_SELFMODIFY_set_end:
cmp   si, 01000h
jb    loop_start_to_end

pop   si  ; recover name list index

;    // check the frames that were found for completeness
;    if (p_init_maxframe == -1) {
;        sprites[i].numframes = 0;
;        continue;
;    }

mov   ax, SPRITES_SEGMENT
mov   es, ax

;  si = [bp - SIZE_SPRITE_NAMES] + i * 5
;  so ax should be ((si - bp + SIZE_SPRITE_NAMES) / 5) to get i

lea   ax, [si + SIZE_SPRITE_NAMES - 5] ; minus 5 because we pre-advanced si via lodsw/lodsb
sub   ax, bp
mov   bl, 5
div   bl
;    ax is sprite index. sprite offset is * 3 (size spriteframe_t)
mov   bx, ax
shl   bx, 1
add   bx, ax


cmp   byte ptr ds:[_p_init_maxframe], ah ; known zero
jl    set_no_frames  ; less than 0 means -1 in this case

; p_init_maxframe++
inc   word ptr ds:[_p_init_maxframe]

; NOTE this whole loop only error checks. Remove?

COMMENT @
mov   cx, word ptr ds:[_p_init_maxframe]

;    for (frame = 0; frame < p_init_maxframe; frame++) {
lea   bx, [bp - SIZE_SPR_TEMP]
loop_spriteframe_rotation_check:
mov   al, byte ptr ds:[bx + SPRITEFRAME_T.spriteframe_rotate]

add    bx, SIZE SPRITEFRAME_T
loop   loop_spriteframe_rotation_check
@

;	sprites[i].numframes = p_init_maxframe; // this  isnever used outside of here and r_setup...
;	sprites[i].spriteframesOffset = currentspritememoryoffset;
;	currentspritememoryoffset += (p_init_maxframe * sizeof(spriteframe_t));


mov   al, byte ptr ds:[_p_init_maxframe]
mov   byte ptr es:[bx + SPRITEDEF_T.spritedef_numframes], al
mov   ah, SIZE SPRITEFRAME_T
mul   ah
xchg  ax, cx

_SELFMODIFY_set_new_currentspritememoryoffset:
mov   di, NUMSPRITES * SIZE SPRITEDEF_T ; default starting point for the data.
mov   word ptr es:[bx + SPRITEDEF_T.spritedef_spriteframesOffset], di

;	spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprites[i].spriteframesOffset]);
;	FAR_memcpy(spriteframes, p_init_sprtemp, p_init_maxframe * sizeof(spriteframe_t));

; es is already sprites segment. starting data for the sprite frame data comes after the spriteframe
; cx is already len
; di is already dest
; set si to source

lea   bx, [bp - SIZE_SPR_TEMP]
xchg  bx, si
shr   cx, 1
rep   movsw
adc   cx, cx
rep   movsb
xchg  bx, si

mov   word ptr cs:[_SELFMODIFY_set_new_currentspritememoryoffset + 1], di  ; new position for next data copy.

continue_inner_loop:

cmp   si, bp     ; bp is the end of this string list
jnb   exit_initspritedefs
jmp   loop_next_sprite


set_no_frames:
;			sprites[i].numframes = 0;
mov   byte ptr es:[bx + SPRITEDEF_T.spritedef_numframes], ah  ; known zero
jmp   continue_inner_loop; 

is_this_sprite:

; store name stuff
push  cx
push  dx  

;    if (modifiedgame) {
cmp   byte ptr ds:[_modifiedgame], 0
je    not_modified
is_modified:
;    copystr8(localname, lumpinfoInit[lump].name);
;    patched = W_GetNumForName(localname);

lea   ax, [bp - SIZE_LOCALNAME]
mov   dx, ss
mov   cx, es
mov   bx, di
call  copystr8_

lea   ax, [bp - SIZE_LOCALNAME]
mov   dx, ss
call  W_GetNumForName_
jmp   done_checking_patched
not_modified:
;    patched = l;
mov   ax, si
done_checking_patched:
; R_InstallSpriteLump(patched, frame, rotation, false);
;    frame = lumpinfoInit[lump].name[4] - 'A';
;    rotation = lumpinfoInit[lump].name[5] - '0';
mov   es, word ptr ds:[_WAD_PAGE_FRAME_PTR]
mov   dx, word ptr es:[di + 4]
sub   dx, 'A' + ('0' SHL 8)
mov   bl, dh
xor   dh, dh
xor   bh, bh
xor   cx, cx
call  R_InstallSpriteLump_

mov   es, word ptr ds:[_WAD_PAGE_FRAME_PTR]
mov   dx, word ptr es:[di + 6]
test  dl, dl
je    skip_flip
;	frame = lumpinfoInit[lump].name[6] - 'A';
;	rotation = lumpinfoInit[lump].name[7] - '0';
;	R_InstallSpriteLump(l, frame, rotation, true);

sub   dx, 'A' + ('0' SHL 8)
mov   ax, si
mov   bl, dh
xor   dh, dh
xor   bh, bh
mov   cx, 1
call  R_InstallSpriteLump_

skip_flip:
pop   dx
pop   cx

jmp   done_processing_sprite_lump
exit_initspritedefs:
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret


ENDP

; todo turn this into inlines, single stack frame, one func, etc.

PROC    P_Init_ NEAR
PUBLIC  P_Init_

call   Z_QuickMapRender_  
call   Z_QuickMapRender_9000To6000_  ; for R_TextureNumForName
call   P_InitSwitchList_  
call   P_InitPicAnims_  
call   R_InitSprites_  
call   Z_QuickMapPhysics_  

ret

ENDP


PROC    P_INIT_ENDMARKER_ NEAR
PUBLIC  P_INIT_ENDMARKER_
ENDP
END