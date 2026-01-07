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
EXTRN W_LumpLength_:FAR
EXTRN Z_QuickMapScratch_5000_:FAR
EXTRN Z_QuickMapScratch_8000_:FAR
EXTRN W_CacheLumpNumDirect_:FAR
EXTRN W_ReadLump_:NEAR
EXTRN copystr8_:NEAR
EXTRN R_FlatNumForName_:NEAR
EXTRN W_CacheLumpNumDirectFragment_:FAR ; todo can this be near?
EXTRN Z_QuickMapRender_4000To9000_:FAR  ; todo inline
EXTRN Z_QuickMapRender_9000To6000_:NEAR  ; todo inline
EXTRN R_TextureNumForName_:NEAR
 
.DATA


.CODE



  ML_LABEL    = 0 ; 
  ML_THINGS   = 1 ; 
  ML_LINEDEFS = 2 ; 
  ML_SIDEDEFS = 3 ; 
  ML_VERTEXES = 4 ; 
  ML_SEGS     = 5 ; 
  ML_SSECTORS = 6 ; 
  ML_NODES    = 7 ; 
  ML_SECTORS  = 8 ; 
  ML_REJECT   = 9 ; 
  ML_BLOCKMAP = 10 ; 


PROC    P_SETUP_STARTMARKER_ NEAR
PUBLIC  P_SETUP_STARTMARKER_
ENDP



PROC    P_SpawnMapThingCallThrough_ NEAR
PUBLIC  P_SpawnMapThingCallThrough_

; ugly for now. so this is passed in a struct, not a pointer to a struct. 
; so theres a billion (or so) bytes on stack
; for now this is just a trampoline/placeholder func until p_setup is in asm
; we far jump to our func instead of calling. so it returns to the other place

; dx:ax is mapthing to push


xchg  ax, bx ; put ptr in bx to push struct
mov   ds, dx

; push 10 byte struct
push  ds:[bx+8]
push  ds:[bx+6]
push  ds:[bx+4]
push  ds:[bx+2]
push  ds:[bx+0]
push  ss
pop   ds
xchg  ax, bx ; put bx back.

db    09Ah  ; call
dw    P_SPAWNMAPTHINGOFFSET, PHYSICS_HIGHCODE_SEGMENT
ret
ENDP


PROC    P_SpawnSpecialsCallThrough_ NEAR
PUBLIC  P_SpawnSpecialsCallThrough_
db    09Ah  ; call
dw    P_SPAWNSPECIALSOFFSET, PHYSICS_HIGHCODE_SEGMENT
ret
ENDP

PROC    S_StartCallThrough_ NEAR
PUBLIC  S_StartCallThrough_
db    09Ah  ; call
dw    S_STARTOFFSET, PHYSICS_HIGHCODE_SEGMENT
ret
ENDP

PROC    P_InitThinkersCallThrough_ NEAR
PUBLIC  P_InitThinkersCallThrough_
call    P_InitThinkers_
ret
ENDP


PROC    P_InitThinkers_ FAR
PUBLIC  P_InitThinkers_

push    di
push    cx
push    dx

mov     di, OFFSET _thinkerlist
mov     dx, 1
mov     word ptr ds:[di + THINKER_T.t_next], dx
mov     word ptr ds:[di + THINKER_T.t_prevFunctype], dx
mov     ax, MAX_THINKERS  ; technically MAX_THINKERS | TF_NULL_HIGHBITS
mov     cx, ax
; dh already 0
mov     dl, (SIZE THINKER_T) - 2  ; account for stosw

push    ds
pop     es

;add    di, THINKER_T.t_prevFunctype    ; unncessary, equals 0.

loop_init_next_thinker:
stosw
add     di, dx
loop    loop_init_next_thinker

mov     word ptr ds:[_currentThinkerListHead], cx   ; cx is 0 after loop

pop     dx
pop     cx
pop     di

retf
ENDP

PROC   P_LoadVertexes_ NEAR
PUBLIC P_LoadVertexes_


push   dx
push   cx
push   bx

push   ax  ; backup lump
call   W_LumpLength_

SHIFT_MACRO  shr ax 2   ; div by 4 size of numvertexes
mov    word ptr ds:[_numvertexes], ax  


pop    ax  ; get lump back
mov    cx, VERTEXES_SEGMENT
xor    bx, bx

call   W_ReadLump_


pop    bx
pop    cx
pop    dx


ret
ENDP

SCRATCH_SEGMENT_8000 = 08000h

PROC   P_LoadSectors_ NEAR
PUBLIC P_LoadSectors_


PUSHA_NO_AX_OR_BP_MACRO

mov    si, ax  ; back up lump
call   W_LumpLength_

; dx should be zeroed...


mov    bx, SIZE MAPSECTOR_T
div    bx

mov    word ptr ds:[_numsectors], ax  



xor    ax, ax
mov    dx, SECTORS_SEGMENT
mov    es, dx
xor    di, di
mov    cx, MAX_SECTORS_SIZE / 2
rep    stosw

mov    dx, SECTORS_SOUNDORGS_SEGMENT
mov    es, dx
xor    di, di
mov    cx, MAX_SECTORS_SOUNDORGS_SIZE / 2
rep    stosw

mov    dx, SECTOR_SOUNDTRAVERSED_SEGMENT
mov    es, dx
xor    di, di
mov    cx, MAX_SECTORS_SOUNDTRAVERSED_SIZE / 2
rep    stosw

push   ds
pop    es
mov    di, OFFSET _sectors_physics
mov    cx, MAX_SECTORS_PHYSICS_SIZE / 2
rep    stosw


call   Z_QuickMapScratch_8000_  ; todo remove ?? unused

xchg   ax, si ; restore lump

xor    bx, bx
mov    cx, SCRATCH_SEGMENT_8000
call   W_ReadLump_

mov    cx, word ptr ds:[_numsectors]
xor    si, si
mov    bx, OFFSET _sectors_physics
xor    di, di

loop_next_sector:

mov    es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov    dx, SCRATCH_SEGMENT_8000
mov    ds, dx

lodsw
SHIFT_MACRO shl ax 3
stosw  ; floorheight
lodsw
SHIFT_MACRO shl ax 3
stosw  ; ceilingheight

push   ss
pop    ds
mov    ax, si
call   R_FlatNumForName_

mov    es, word ptr ds:[_SECTORS_SEGMENT_PTR]
stosb 
mov    dx, SCRATCH_SEGMENT_8000
lea    ax, [si + 8]
call   R_FlatNumForName_

add    si, 16
mov    es, word ptr ds:[_SECTORS_SEGMENT_PTR]
stosb 
mov    dx, SCRATCH_SEGMENT_8000
mov    ds, dx

lodsw
mov    byte ptr es:[di + SECTOR_T.sec_lightlevel - SECTOR_T.sec_validcount], al




lodsw ; special
xchg   ax, dx
lodsw

cmp    ax, 666
je     set_666
cmp    ax, 667
je     set_667
cmp    ax, 999
je     set_999
cmp    ax, 99
je     set_99
cmp    ax, 77
je     set_77
cmp    ax, 1323
je     set_1323
cmp    ax, 1044
je     set_1044
cmp    ax, 86
je     set_86

got_tag:
push   ss
pop    ds

mov    ah, al
mov    al, dl
mov    word ptr ds:[bx + SECTOR_PHYSICS_T.secp_special], ax
add    bx, SIZE SECTOR_PHYSICS_T
add    di, (SIZE SECTOR_T - SECTOR_T.sec_validcount)


loop   loop_next_sector

POPA_NO_AX_OR_BP_MACRO

ret

set_666:
mov ax, TAG_666
jmp got_tag
set_667:
mov ax, TAG_667
jmp got_tag
set_999:
mov ax, TAG_999
jmp got_tag
set_99:
mov ax, TAG_99
jmp got_tag
set_77:
mov ax, TAG_77
jmp got_tag
set_1323:
mov ax, TAG_1323
jmp got_tag
set_1044:
mov ax, TAG_1044
jmp got_tag
set_86:
mov ax, TAG_86
jmp got_tag

ENDP



PROC   P_LoadSideDefs_ NEAR
PUBLIC P_LoadSideDefs_

PUSHA_NO_AX_OR_BP_MACRO

push    bp
mov     bp, sp
sub     sp, 24  ; tex strings...

mov    si, ax  ; back up lump
call Z_QuickMapRender_4000To9000_
call Z_QuickMapRender_9000To6000_  ; for R_TextureNumForName

mov    ax, si  ; get lump 

call   W_LumpLength_

; dx may be non zero

mov    bx, SIZE MAPSIDEDEF_T
div    bx

; dx should be 0 now

mov    word ptr ds:[_numsides], ax  
mov    word ptr ds:[_cached_psetup_lump_offset+0], dx  ; write 0
mov    word ptr ds:[_cached_psetup_lump_offset+2], dx  ; write 0



call   Z_QuickMapScratch_5000_


xchg   ax, si   ; get lump back
mov    cx, SCRATCH_SEGMENT_5000
xor    bx, bx

push   bx
push   bx

call   W_CacheLumpNumDirectFragment_

mov    cx, word ptr ds:[_numsides]
xor    si, si
mov    di, si
mov    bx, si

loop_next_sidedef:

push   cx  ; store loop ptr

cmp    si, 16380 
jae    do_repage

done_repaging:

mov    dx, SIDES_RENDER_9000_SEGMENT
mov    es, dx

mov    dx, SCRATCH_SEGMENT_5000
mov    ds, dx


;    mapsidedef_textureoffset    dw ?         ; 00h
;    mapsidedef_rowoffset        dw ?         ; 02h
;    mapsidedef_toptexture       db 8 DUP(?)  ; 04h
;    mapsidedef_bottomtexture    db 8 DUP(?)  ; 0Ch
;    mapsidedef_midtexture       db 8 DUP(?)  ; 14h
;    mapsidedef_sector           dw ?         ; 1Ch

xchg   bx, di

lodsw
xchg   ax, dx ; dx stores textureoffset
movsw   ; siderender_t rowoffset
mov    ax, word ptr ds:[si + (MAPSIDEDEF_T.mapsidedef_sector - MAPSIDEDEF_T.mapsidedef_toptexture)]  ; + 24, read ahead..
stosw   ; siderender_t secnum, done

xchg   bx, di

mov    cx, 24 / 2  ;
lea    ax, [bp - 24]
xchg   ax, di
push   ss
pop    es
rep    movsw  ; copy all 3 tex strings!
xchg   ax, di

;		toptex = R_TextureNumForName(texnametop);
;		bottex = R_TextureNumForName(texnamebot);
;		midtex = R_TextureNumForName(texnamemid);

push   ss
pop    ds

mov    cx, word ptr ds:[_SIDES_SEGMENT_PTR]

lea    ax, [bp - 24]
call   R_TextureNumForName_
mov    es, cx
stosw

lea    ax, [bp - 16]
call   R_TextureNumForName_
mov    es, cx
stosw

lea    ax, [bp - 8]
call   R_TextureNumForName_
mov    es, cx
stosw

xchg   ax, dx ; get textureoffset back
stosw

inc    si
inc    si  ; add for the sector read

pop    cx  ; recover loop ptr

loop   loop_next_sidedef

LEAVE_MACRO

POPA_NO_AX_OR_BP_MACRO

ret

do_repage:

; TODO THIS

add    word ptr ds:[_cached_psetup_lump_offset+0], si  ; 16380
adc    word ptr ds:[_cached_psetup_lump_offset+2], 0

push   bx

push   word ptr ds:[_cached_psetup_lump_offset+2]
push   word ptr ds:[_cached_psetup_lump_offset+0]


xor    si, si

mov    ax, word ptr ds:[_cached_psetup_level_lump]
add    ax, ML_SIDEDEFS
mov    cx, SCRATCH_SEGMENT_5000
xor    bx, bx

call   W_CacheLumpNumDirectFragment_

pop    bx  ; restore ptr

jmp    done_repaging


ENDP





PROC    P_SETUP_ENDMARKER_ NEAR
PUBLIC  P_SETUP_ENDMARKER_
ENDP


END