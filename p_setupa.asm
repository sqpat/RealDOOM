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
EXTRN Z_QuickMapScratch_4000_:FAR
EXTRN Z_QuickMapScratch_5000_:FAR
EXTRN Z_QuickMapScratch_8000_:FAR
EXTRN W_ReadLump_:NEAR
EXTRN Z_QuickMapRender4000_:FAR
EXTRN copystr8_:NEAR
EXTRN R_FlatNumForName_:NEAR
EXTRN W_CacheLumpNumDirectFragment_:FAR ; todo can this be near?
EXTRN Z_QuickMapRender_4000To9000_:FAR  ; todo inline
EXTRN Z_QuickMapRender_9000To6000_:NEAR  ; todo inline
EXTRN R_TextureNumForName_:NEAR
EXTRN M_AddToBox16_:NEAR
EXTRN locallib_fseek_:NEAR
EXTRN locallib_fopen_nobuffering_:NEAR
EXTRN locallib_fclose_:NEAR
EXTRN locallib_fread_:NEAR
EXTRN CopyString13_:NEAR

.DATA


.CODE

EXTRN _doomdata_bin_string


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
SCRATCH_SEGMENT_4000 = 04000h

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

call   gettag_


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
ENDP

; processes 2 byte special case tags into single byte


PROC   gettag_  NEAR

; we could make this 20 bytes smaller but it'd be significntly slower..

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
ret

set_666:
mov ax, TAG_666
ret
set_667:
mov ax, TAG_667
ret
set_999:
mov ax, TAG_999
ret
set_99:
mov al, TAG_99
ret
set_77:
mov al, TAG_77
ret
set_1323:
mov ax, TAG_1323
ret
set_1044:
mov ax, TAG_1044
ret
set_86:
mov al, TAG_86
ret

ENDP



PROC   P_LoadSideDefs_ NEAR
PUBLIC P_LoadSideDefs_

PUSHA_NO_AX_OR_BP_MACRO

push    bp
mov     bp, sp
sub     sp, 24  ; tex strings...

mov    si, ax  ; back up lump


call   W_LumpLength_
; dx may be non zero

mov    bx, SIZE MAPSIDEDEF_T
div    bx


mov    word ptr ds:[_numsides], ax  

call Z_QuickMapRender_4000To9000_
call Z_QuickMapRender_9000To6000_  ; for R_TextureNumForName





call   Z_QuickMapScratch_5000_


xchg   ax, si   ; get lump back
mov    cx, SCRATCH_SEGMENT_5000
xor    bx, bx
mov    word ptr ds:[_cached_psetup_lump_offset+0], dx  ; write 0
mov    word ptr ds:[_cached_psetup_lump_offset+2], dx  ; write 0

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
call   Z_QuickMapPhysics_

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




PROC   P_LoadBlockMap_ NEAR
PUBLIC P_LoadBlockMap_

push   si
push   di
push   cx
push   bx

xchg   ax, bx   ; store lump

call   Z_QuickMapPhysics_

xchg   ax, bx   ; retrieve lump

xor    bx, bx
mov    cx, BLOCKMAPLUMP_SEGMENT
call   W_ReadLump_

mov    cx, BLOCKMAPLUMP_SEGMENT
mov    es, cx
xor    si, si
lods   word ptr es:[si]
mov    word ptr ds:[_bmaporgx], ax
lods   word ptr es:[si]
mov    word ptr ds:[_bmaporgy], ax
lods   word ptr es:[si]
mov    word ptr ds:[_bmapwidth], ax
lods   word ptr es:[si]
mov    word ptr ds:[_bmapheight], ax

xor    ax, ax
mov    cx, BLOCKLINKS_SEGMENT
mov    es, cx
xor    di, di
mov    cx, MAX_BLOCKLINKS_SIZE / 2

rep    stosw

pop    bx
pop    cx
pop    di
pop    si
ret

ENDP


PROC   P_LoadLineDefs_ NEAR
PUBLIC P_LoadLineDefs_

PUSHA_NO_AX_MACRO


mov    si, ax  ; back up lump

call   W_LumpLength_

mov    bx, SIZE MAPLINEDEF_T
div    bx

mov    word ptr ds:[_numlines], ax  



;	FAR_memset(lines, 0, MAX_LINES_SIZE);
;	FAR_memset(lines_physics, 0, MAX_LINES_PHYSICS_SIZE);
;	FAR_memset(seenlines_6800, 0, MAX_SEENLINES_SIZE);

xor  ax, ax

mov  es, word ptr ds:[_LINES_SEGMENT_PTR]
xor  di, di
mov  cx, MAX_LINES_SIZE /2 
rep  stosw

mov  es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]
xor  di, di
mov  cx, MAX_LINES_PHYSICS_SIZE /2 
rep  stosw

mov  es, word ptr ds:[_SEENLINES_6800_SEGMENT_PTR]
xor  di, di
mov  cx, (MAX_SEENLINES_SIZE /2) + 1   ; could be odd?
rep  stosw


call Z_QuickMapScratch_5000_

xchg ax, si   ; get lump
mov  cx, SCRATCH_SEGMENT_5000
xor  bx, bx

call W_ReadLump_

call Z_QuickMapRender4000_


mov  cx, word ptr ds:[_numlines]

xor  si, si  ; maplinedefs
mov  di, si  ; line physics_t
mov  bp, si  ; lineflagslist


mov  es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]
mov  ax, SCRATCH_SEGMENT_5000
mov  ds, ax
loop_next_linedef:

push cx


lodsw           ; maplinedef_v1
stosw
xchg ax, dx
lodsw           ; maplinedef_v2
stosw
xchg ax, bx



SHIFT_MACRO shl bx 2
mov  ds, word ptr ss:[_VERTEXES_SEGMENT_PTR]
mov  ax, word ptr ds:[bx + 0]
mov  bx, word ptr ds:[bx + 2]
xchg bx, dx
SHIFT_MACRO shl bx 2

xor  cx, cx ; flags to OR to v2Offset

sub  ax, word ptr ds:[bx + 0] ; calculate dx
jne  dont_set_v2_flag_vertical
mov  ch, (ST_VERTICAL_HIGH SHR 8)
dont_set_v2_flag_vertical:
sub  dx, word ptr ds:[bx + 2] ; dy

stosw   ; dx
xchg ax, dx
stosw   ; dy

; if zero flag is set then ST_HORIZONTAL_HIGH is set, which is actually 0 
; and falls thru fine without further check. but ST_VERTICAL_HIGH takes
; precedence and thats fine too.
je   done_checking_flags  
jcxz calculate_flags      ; also not ST_VERTICAL_HIGH, check other cases

done_checking_flags:

or   byte ptr es:[di - 5], ch  ; v2Offset |= flag

mov  ax, SCRATCH_SEGMENT_5000
mov  ds, ax

lodsw       ; flags

mov  es, word ptr ss:[_LINEFLAGSLIST_SEGMENT_PTR]
mov  byte ptr es:[bp], al
inc  bp

lodsw       ; special
mov  dh, al
lodsw       ; tag

call gettag_

mov  dl, al ; dx = tag low special high


; line is 4 bytes long
; line_physics is 16 bytes long, current at index 8
; we want to determine line offset from line_physics.
; line offset = (line_physics >> 2) - 2
; shift 2 to get the line index for a given line_physics
mov   cx, di   ; back up
SHIFT_MACRO shr di 2

; di was offset by 8, or 2 after 2 shifts. so undo that..
dec   di
dec   di

mov   es, word ptr ss:[_LINES_SEGMENT_PTR]
lodsw
stosw
xchg  ax, bx  ; store side 0
lodsw
stosw
mov   di, cx  ; restore di



xchg  ax, cx  ; store side 1
xor   ax, ax
mov   es, word ptr ss:[_LINES_PHYSICS_SEGMENT_PTR]
stosw     ; validcount

xchg  ax, bx  ; side 0
test  ax, ax  
jns   calc_secnum_0
store_secnum_0:
stosw      ; secnum0

xchg  ax, cx ; side 1
test  ax, ax  
jns   calc_secnum_1
store_secnum_1:
stosw      ; secnum1

xchg ax, dx
stosw      ; special, tag


pop  cx

loop loop_next_linedef

push ss
pop  ds


POPA_NO_AX_MACRO

call Z_QuickMapPhysics_


ret

calculate_flags:
; already checked for st_vertical_high
; zero flag set if v2offset is 0
mov   ch, (ST_POSITIVE_HIGH SHR 8)
xor   ax, dx
jns   done_checking_flags   ; or jge?
mov   ch, (ST_NEGATIVE_HIGH SHR 8)
jmp   done_checking_flags

calc_secnum_0:
xchg ax, bx
SHIFT_MACRO shl bx 2
mov  ax, word ptr ss:[_sides_render + bx + SIDE_RENDER_T.sr_secnum]
jmp  store_secnum_0

calc_secnum_1:
xchg ax, bx
SHIFT_MACRO shl bx 2
mov  ax, word ptr ss:[_sides_render + bx + SIDE_RENDER_T.sr_secnum]
jmp  store_secnum_1

ENDP


PROC    P_LoadSubsectors_ NEAR
PUBLIC  P_LoadSubsectors_

PUSHA_NO_AX_OR_BP_MACRO

mov    si, ax  ; back up lump

call   W_LumpLength_


SHIFT_MACRO  shr ax 2   ; SIZE MAPSUBSECTOR_T
mov    word ptr ds:[_numsubsectors], ax      ; todo is this field ever actually used? 
;	FAR_memset(subsectors, 0, MAX_SUBSECTORS_SIZE);


mov    ax, SUBSECTORS_SEGMENT
mov    es, ax
xor    di, di
mov    cx, MAX_SUBSECTORS_SIZE / 2
xor    ax, ax
rep    stosw

call   Z_QuickMapScratch_5000_

xchg   ax, si   ; get lump
mov    cx, SCRATCH_SEGMENT_5000
xor    bx, bx

call   W_ReadLump_

mov    cx, word ptr ds:[_numsubsectors]

xor    di, di
mov    si, di

mov    dx, SUBSECTOR_LINES_SEGMENT
mov    bx, SUBSECTORS_SEGMENT
mov    ax, SCRATCH_SEGMENT_5000
mov    ds, ax

loop_next_subsector:

; we write to a byte in a byte array
; then we write to word 2 in a 4-byte array

;  stosb  shl dec shl  stosw    shr 2
; 0 -> 1    -> 2       -> 4   -> 1
;  stosb  shl dec shl  stosw    shr 2
; 1 ->  2   -> 6       -> 8   -> 2

lodsw   ; mapss_nummapsectorsegs
mov    es, dx
stosb                   ;		subsector_lines[i]  = (ms->nummapsectorsegs);
lodsw   ; mapss_firstseg
mov    es, bx

shl    di, 1
dec    di
shl    di, 1   ; gets us offset 2 in the previous dword index
stosw                   ; 		subsectors[i].firstline = (ms->firstseg);
SHIFT_MACRO  shr di 2


loop   loop_next_subsector

push   ss
pop    ds


POPA_NO_AX_OR_BP_MACRO

ret

ENDP




PROC    P_LoadNodes_ NEAR
PUBLIC  P_LoadNodes_

PUSHA_NO_AX_MACRO

mov    si, ax  ; back up lump

call   W_LumpLength_

mov    bx, SIZE MAPNODE_T
div    bx

mov    word ptr ds:[_numnodes], ax

call   Z_QuickMapRender_4000To9000_
call   Z_QuickMapScratch_5000_

xchg   ax, si   ; get lump
mov    cx, SCRATCH_SEGMENT_5000
xor    bx, bx

call   W_ReadLump_


mov    cx, word ptr ds:[_numnodes]

xor    di, di
mov    si, di

mov    dx, NODES_SEGMENT
mov    bp, NODE_CHILDREN_SEGMENT
mov    bx, NODES_RENDER_SEGMENT

mov    ax, SCRATCH_SEGMENT_5000
mov    ds, ax

mov    ax, 8


loop_next_node:

push   cx

mov    cx, ax  ; 8

mov    es, dx  ; NODES_SEGMENT   ; 8 bytes each
rep    movsb


mov    es, bx   ; NODES_RENDER_SEGMENT ; 16 bytes each
sub    di, ax  ; 8
shl    di, 1
mov    cx, ax
rep    movsw

shr   di, 1
sub   di, ax
shr   di, 1

mov    es, bp   ; NODE_CHILDREN_SEGMENT ; 4 bytes each
movsw
movsw

shl    di, 1

pop    cx

loop   loop_next_node

push   ss
pop    ds

call   Z_QuickMapPhysics_

POPA_NO_AX_OR_BP_MACRO

ret


ENDP

FINE_ANGLE_HIGH_BYTE = 01Fh

TEMPSECNUMS_OFFSET = 0C000h

PROC    P_LoadSegs_ NEAR
PUBLIC  P_LoadSegs_

PUSHA_NO_AX_OR_BP_MACRO

mov    si, ax  ; back up lump
call   W_LumpLength_

mov    bx, SIZE MAPSEG_T
div    bx

mov    word ptr ds:[_numsegs], ax

call   Z_QuickMapRender_4000To9000_
call   Z_QuickMapScratch_5000_

; shouldnt be necessary.

;	FAR_memset(seg_linedefs, 0xff, size_seg_linedefs + size_seg_sides);
;xor    di, di
;mov    cx, (SIZE_SEG_LINEDEFS + SIZE_SEG_SIDES + 1) / 2   ; may be odd?
;mov    ax, SEG_LINEDEFS_SEGMENT
;mov    es, ax
;mov    ax, 0FFFFh
;rep    stosw

xchg   ax, si   ; get lump
mov    cx, SCRATCH_SEGMENT_5000
xor    bx, bx

call   W_ReadLump_


mov    cx, word ptr ds:[_numsegs]

xor    di, di  ; side_render
mov    si, di
mov    bx, di

mov    ax, SCRATCH_SEGMENT_5000
mov    ds, ax
mov    ax, SEGS_RENDER_9000_SEGMENT  ; default es value, use push/pops to make loop small enough for relative loop jmp
mov    es, ax



loop_next_seg:

push   cx
push   es
movsw  ; v1
movsw  ; v2

mov    ax, SEG_NORMALANGLES_9000_SEGMENT
mov    es, ax


; seg_normalangles_9000[i] = MOD_FINE_ANGLE((mlangle >> SHORTTOFINESHIFT) + FINE_ANG90);
lodsw  ; angle
SHIFT_MACRO shr ax 3   
add    ax, FINE_ANG90
and    ah, FINE_ANGLE_HIGH_BYTE
mov    word ptr es:[bx], ax

mov    ax, SEG_LINEDEFS_SEGMENT
mov    es, ax

lodsw  ; linedef
mov    word ptr es:[bx], ax

;		ldefflags = lineflagslist[mllinedef];
xchg   ax, bp   ; linedef in bp

lodsw  ; side
shr    bx, 1  ; byte ptr 
mov    byte ptr es:[bx + seg_sides_offset_in_seglines], al

mov    es, word ptr ss:[_LINEFLAGSLIST_SEGMENT_PTR]
mov    dl, byte ptr es:[bp]  ; get flags
SHIFT_MACRO shl bp 2


mov    es, word ptr ss:[_LINES_SEGMENT_PTR]
les    bp, dword ptr es:[bp]
test   ax, ax
; bp has side 0, es has side 1. ax has side 0/1 designator
mov    ax, es
je     skip_swap
xchg   ax, bp
skip_swap:
; bp has ldefsidenum
; ax has ldefothersidenum

pop    es  ;  ; base pointer for di

movsw   ; offset
xchg   ax, bp
stosw   ; ldefsidenum

; ax has ldefsidenum
; bp has ldefothersidenum

;    sidesecnum = sides_render_9000[ldefsidenum].secnum;
;    othersidesecnum = sides_render_9000[ldefothersidenum].secnum;

SHIFT_MACRO  shl bx 2   ; for tempsecnums dword offset

SHIFT_MACRO  shl ax 2
xchg   ax, bp

push   es

mov    cx, SIDES_RENDER_9000_SEGMENT
mov    es, cx

mov    bp, word ptr es:[bp + SIDE_RENDER_T.sr_secnum]
xchg   ax, bp   ; ax gets sidesecnum value. bp gets ldefothersidenum

test   dl, ML_TWOSIDED
mov    dx, SECNUM_NULL   ;-1
jne    calc_second_secnum

got_second_secnum:

pop    es

mov    word ptr ds:[bx + TEMPSECNUMS_OFFSET + 0], ax  ; 5000 segment
mov    word ptr ds:[bx + TEMPSECNUMS_OFFSET + 2], dx  ; 5000 segment

SHIFT_MACRO  shr bx 1  ; word ptr again

inc    bx   ; increment word offset
inc    bx
pop    cx
loop   loop_next_seg


push   ss
pop    ds

call   Z_QuickMapPhysics_
call   Z_QuickMapScratch_5000_

;	FAR_memcpy(segs_physics, MK_FP(0x5000, 0xc000), numsegs*4);

mov   cx, word ptr ds:[_numsegs]
shl   cx, 1 ; x4 bytes = x2 words

mov   ax, SCRATCH_SEGMENT_5000
mov   ds, ax
mov   si, TEMPSECNUMS_OFFSET
mov   ax, SEGS_PHYSICS_SEGMENT
mov   es, ax
xor   di, di

rep   movsw


push  ss
pop   ds


POPA_NO_AX_MACRO

ret

calc_second_secnum:

SHIFT_MACRO  shl bp 2
mov    dx, word ptr es:[bp + SIDE_RENDER_T.sr_secnum]


jmp  got_second_secnum


ENDP

PROC    P_GroupLines_ NEAR
PUBLIC  P_GroupLines_

PUSHA_NO_AX_MACRO

call   Z_QuickMapRender_4000To9000_

mov    cx, word ptr ds:[_numsubsectors]
mov    dx, SUBSECTORS_SEGMENT
mov    ds, dx
mov    dx, SEGS_RENDER_9000_SEGMENT
mov    di, SIDES_RENDER_9000_SEGMENT

mov    si, OFFSET SUBSECTOR_T.ss_firstline

loop_next_line_lookup:

lodsw
xchg   ax, bx
SHIFT_MACRO shl bx 3
mov    es, dx ; SEGS_RENDER_9000_SEGMENT
mov    bx, word ptr es:[bx + SEG_RENDER_T.sr_sidedefOffset] ; size 8 per

SHIFT_MACRO shl bx 2
mov    es, di ; SIDES_RENDER_9000_SEGMENT
push   word ptr es:[bx + SIDE_RENDER_T.sr_secnum] ; get secnum  ; size 4 per
pop    word ptr ds:[si - 4]                       ; write secnum
inc    si
inc    si ; skip other param

loop   loop_next_line_lookup

push   ss
pop    ds

call   Z_QuickMapPhysics_



mov    cx, word ptr ds:[_numlines]

mov    di, SECTORS_SEGMENT
mov    es, di
mov    ds, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]
mov    si, LINE_PHYSICS_T.lp_frontsecnum
mov    di, SECTOR_T.sec_linecount

loop_next_line_count_lookup:

lodsw
mov    dx, ax  ; unshifted copy
xchg   ax, bx  ; linefrontsecnum in bx
lodsw          ; linebacksecnum  in ax
SHIFT_MACRO  shl bx 4
inc    word ptr es:[bx + di]

test   ax, ax
js     dont_count_backsecnum
cmp    ax, dx
je     dont_count_backsecnum

xchg   ax, bx  ; linebacksecnum
SHIFT_MACRO  shl bx 4
inc    word ptr es:[bx + di]


dont_count_backsecnum:
add    si, (SIZE LINE_PHYSICS_T) - 4 

loop   loop_next_line_count_lookup

push   ss
pop    ds




xor    cx, cx   ; linebufferindex
xor    si, si   ; sector ptr
mov    bp, si

loop_next_sector_bbox:

;	bbox[BOXTOP] = bbox[BOXRIGHT] = MINSHORT;
;	bbox[BOXBOTTOM] = bbox[BOXLEFT] = MAXSHORT;

push   si ; store sector[i] ptr so we can modify it

mov    ax, MINSHORT  ; 08000h
push   ax  ; sp + 6 = BOXRIGHT  = MINSHORT = 08000h
dec    ax 
push   ax  ; sp + 4 = BOXLEFT   = MAXSHORT = 07FFFh
push   ax  ; sp + 2 = BOXBOTTOM = MAXSHORT = 07FFFh
inc    ax
push   ax  ; sp + 0 = BOXTOP    = MINSHORT = 08000h

mov    es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov    word ptr es:[bp + SECTOR_T.sec_linesoffset], cx

xor    dx, dx
mov    bx, dx
mov    es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]

loop_next_sector_line:

; if (li_physics->frontsecnum == i || li_physics->backsecnum == i) {

cmp    si, word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum]
je     add_this_line
cmp    si, word ptr es:[bx + LINE_PHYSICS_T.lp_backsecnum]
je     add_this_line
continue_line_physics_iteration:
add    bx, SIZE LINE_PHYSICS_T
inc    dx
cmp    dx, word ptr ds:[_numlines]
jb     loop_next_sector_line

mov    ax, SECTORS_SOUNDORGS_SEGMENT
mov    es, ax

SHIFT_MACRO shl si 2  ; dword ptr

pop    ax ; BOXTOP
pop    dx ; BOXBOTTOM
pop    di ; BOXLEFT
pop    bx ; BOXRIGHT

push   cx

;		sectors_soundorgs[i].soundorgX = (bbox[BOXRIGHT] + bbox[BOXLEFT]) >> 1;
;		sectors_soundorgs[i].soundorgY = (bbox[BOXTOP] + bbox[BOXBOTTOM]) >> 1;

lea    cx, [bx + di]
;add    cx, bx
sar    cx, 1
mov    word ptr es:[si + SECTOR_SOUNDORG_T.secso_soundorgX], cx

mov    cx, ax
add    cx, dx
sar    cx, 1
mov    word ptr es:[si + SECTOR_SOUNDORG_T.secso_soundorgY], cx


; bp still 16 byte struct ptr

mov    cx, word ptr ds:[_bmaporgy]
mov    si, word ptr ds:[_bmapheight]

call   set_blockbox_high_  ; top
xchg   ax, dx
call   set_blockbox_low_   ; bottom

mov    cx, word ptr ds:[_bmaporgx]
mov    si, word ptr ds:[_bmapwidth]

xchg   ax, di
call   set_blockbox_low_   ; left
xchg   ax, bx
call   set_blockbox_high_  ; right


pop    cx
pop    si

inc   si
add   bp, 8  ; add the other 8 bytes of 16 for next iter
cmp   si, word ptr ds:[_numsectors]
jb    loop_next_sector_bbox

push  ss
pop   ds

POPA_NO_AX_MACRO

ret

add_this_line:

mov    di, cx
shl    di, 1   ; word ptr
mov    word ptr ds:[_linebuffer + di], dx       ; linebuffer[linebufferindex] = j;

inc    cx   ; linebufferindex++
mov    di, sp  ; store stack pointer/bbox ptr..



push   bx
push   es
push   dx

; es already line physics..

les    bx, dword ptr es:[bx + LINE_PHYSICS_T.lp_v1Offset]
mov    ax, es
and    ax, VERTEX_OFFSET_MASK   ; v2
mov    es, word ptr ds:[_VERTEXES_SEGMENT_PTR]
SHIFT_MACRO shl bx 2

push   ax                     ; v2
les    ax, dword ptr es:[bx]  ; v1.x
mov    dx, es                 ; v1.y
mov    bx, di                 ; bbox


call   M_AddToBox16_

pop    bx                     ; v2
SHIFT_MACRO shl bx 2
mov    es, word ptr ds:[_VERTEXES_SEGMENT_PTR]
les    ax, dword ptr es:[bx]  ; v2.x
mov    dx, es                 ; v2.y
mov    bx, di                 ; bbox     

call   M_AddToBox16_

pop    dx
pop    es
pop    bx


jmp    continue_line_physics_iteration

ENDP

PROC    set_blockbox_high_ NEAR

;		block = (bbox[BOXTOP] - bmaporgy + MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
;		block = block >= bmapheight ? bmapheight - 1 : block;
;		sectors_physics[i].blockbox[BOXTOP] = block;


sub    ax, cx
add    ax, MAXRADIUSNONFRAC
SHIFT_MACRO sar ax 7
cmp    ax, si
jl     dont_cap_high
xchg   ax, si   ; only can happen once, xchg is fine
dec    ax
dont_cap_high:
dont_cap_low:
do_write_and_ret:
mov    word ptr ss:[bp + _sectors_physics + SECTOR_PHYSICS_T.secp_blockbox], ax

inc    bp
inc    bp

ret

ENDP

PROC    set_blockbox_low_ NEAR

;		block = (bbox[BOXBOTTOM] - bmaporgy - MAXRADIUSNONFRAC) >> MAPBLOCKSHIFT;
;		block = block < 0 ? 0 : block;

sub    ax, cx
sub    ax, MAXRADIUSNONFRAC
js     cap_low
SHIFT_MACRO sar ax 7
jmp    dont_cap_low

cap_low:
xor    ax, ax
jmp    do_write_and_ret


ENDP


PROC    P_LoadThings_ NEAR
PUBLIC  P_LoadThings_

PUSHA_NO_AX_OR_BP_MACRO

mov    si, ax  ; store lump

call   W_LumpLength_

mov    bx, SIZE MAPTHING_T
div    bx
push   ax ; num things



mov     cx, ((SIZE MAPTHING_T) * MAX_THINKERS) / 2
mov     ax, NIGHTMARESPAWNS_SEGMENT
mov     es, ax
xor     ax, ax
mov     di, ax
rep     stosw

call    Z_QuickMapScratch_8000_

xchg    ax, si  ; get lump back
mov     cx, SCRATCH_SEGMENT_8000
xor     bx, bx

call   W_ReadLump_




pop     cx  ; numthings

xor     si, si
mov     di, si
mov     bl, byte ptr ds:[_commercial]

loop_next_thing:

mov     ax, SCRATCH_SEGMENT_8000
mov     es, ax
cmp     word ptr es:[si + MAPTHING_T.mapthing_type], 1
je      set_player_stuff


test    bl, bl
jne     just_do_spawn

mov     ax, word ptr es:[si + MAPTHING_T.mapthing_type]

cmp     ax, 68           ; Arachnotron
je      end_spawns_early
cmp     ax, 64           ; Archvile
je      end_spawns_early
cmp     ax, 88           ; Boss Brain
je      end_spawns_early
cmp     ax, 89           ; Boss Shooter
je      end_spawns_early
cmp     ax, 69           ; Hell Knight
je      end_spawns_early
cmp     ax, 67           ; Mancubus
je      end_spawns_early
cmp     ax, 71           ; Pain Elemental
je      end_spawns_early
cmp     ax, 65           ; Former Human Commando
je      end_spawns_early
cmp     ax, 66           ; Revenant
je      end_spawns_early
cmp     ax, 84           ; Wolf SS
je      end_spawns_early


done_with_player_setup:
just_do_spawn:


; todo clean up
push    word ptr es:[si+8]
push    word ptr es:[si+6]
push    word ptr es:[si+4]
push    word ptr es:[si+2]
push    word ptr es:[si+0]
mov     ax, sp

db      09Ah  ; call
dw      P_SPAWNMAPTHINGOFFSET, PHYSICS_HIGHCODE_SEGMENT


inc     di
add     si, SIZE MAPTHING_T
loop    loop_next_thing


end_spawns_early:

POPA_NO_AX_OR_BP_MACRO
ret
set_player_stuff:
mov     word ptr ds:[_playerMobjRef], di

; #define playerMobjMakerExpression		((mobj_t __near *) (((byte __far*)thinkerlist) + (playerMobjRef*sizeof(thinker_t) + 2 * sizeof(THINKERREF))))
mov     ax, SIZE THINKER_T
mul     di
add     ax, OFFSET _thinkerlist + (2 * 2)
mov     word ptr ds:[_playerMobjRef], di
mov     word ptr ds:[_playerMobj], ax
mov     ax, SIZE MOBJ_POS_T
mul     di
mov     word ptr ds:[_playerMobj_pos+0], ax
mov     word ptr ds:[_playerMobj_pos+2], MOBJPOSLIST_6800_SEGMENT   ; todo necessary?
jmp     done_with_player_setup

ENDP


PROC   R_LoadPatchColumnsColormap0_ NEAR
PUBLIC R_LoadPatchColumnsColormap0_

PUSHA_NO_AX_MACRO

xchg   ax, si  ; store lump

call   Z_QuickMapScratch_4000_  ; render col info has been paged out..


xchg   ax, si
mov    cx, SCRATCH_SEGMENT_4000
xor    bx, bx

call   W_ReadLump_


OFFSET_SEG_4000_IN_SS = (SCRATCH_SEGMENT_4000 - FIXED_DS_SEGMENT) SHL 4

mov    dx, COLORMAPS_SEGMENT
mov    ds, dx
xor    bx, bx  ; colormap 0 xlat
mov    di, bx
mov    dx, SKYTEXTURE_TEXTURE_SEGMENT
mov    es, dx
mov    bp, OFFSET_SEG_4000_IN_SS
mov    dx, word ptr ss:[bp + PATCH_T.patch_width]
add    bp, OFFSET PATCH_T.patch_columnofs
xor    ax, ax ; zero ah
xor    cx, cx ; zero cx

loop_next_sky_column:

;column_t __far * column = (column_t __far *)(SCRATCH_ADDRESS_4000 + patch->columnofs[col]);

mov    si, word ptr ss:[bp]  ; get column
add    si, OFFSET_SEG_4000_IN_SS
loop_until_last_post:

lods   byte ptr ss:[si]           ; topdelta al   length ah
cmp    al, 0FFh                   ; todo reg
je     done_with_column_posts

do_another_post:

lods   byte ptr ss:[si]           ; get length
xchg   ax, cx                     ; ah known zero, thus ch known zero. cx known zero so ah continues as zero
inc    si                         ; source tex addr is col + 3...

do_another_pixel:

lods   byte ptr ss:[si]           ; get source pixel
xlat   byte ptr ds:[bx]           ; colormap zero lookup
stosb                             ; store the pixel

loop   do_another_pixel

; post done

inc    si

lods   byte ptr ss:[si]           ; topdelta al   length ah
cmp    al, 0FFh  ; todo reg
jne    do_another_post


done_with_column_posts:

add    bp, 4
dec    dx
jne    loop_next_sky_column

push   ss
pop    ds

call   Z_QuickMapRender4000_

POPA_NO_AX_MACRO
ret

ENDP

; todo add another 1500 bytes or so of data to this clobbered region

PROC    Z_ClearDeadCode_ NEAR
PUBLIC  Z_ClearDeadCode_

cmp   word ptr ds:[_tantoangle_segment], 0
jne   skip_clear_dead_code

PUSHA_NO_AX_OR_BP_MACRO

mov   ax, OFFSET _doomdata_bin_string  ; technically this string is about to get clobbered! but its ok. we check above and dont re-run the func.
call  CopyString13_
mov   dl, (FILEFLAG_READ OR FILEFLAG_BINARY)
call  locallib_fopen_nobuffering_        ; fopen("DOOMDATA.BIN", "rb"); 
mov   di, ax ; di stores fp

xor   dx, dx  ; SEEK_SET
mov   bx, TANTOA_DOOMDATA_OFFSET AND 0FFFFh
mov   cx, TANTOA_DOOMDATA_OFFSET SHR 16
call  locallib_fseek_  ;    fseek(fp, SWITCH_DOOMDATA_OFFSET, SEEK_SET);

xor   ax, ax
mov   dx, cs
mov   word ptr ds:[_tantoangle_segment], dx
mov   cx, di ; fp
mov   bx, 4 * 2049
call  locallib_fread_

xchg  ax, di
call  locallib_fclose_

POPA_NO_AX_OR_BP_MACRO


; size of code to clobber
;mov   cx, (P_INIT_ENDMARKER - D_INIT_STARTMARKER) AND 0FFF0H  

skip_clear_dead_code:  ; already has been done

ret
ENDP


PROC    Z_FreeConventionalAllocations_  NEAR
PUBLIC  Z_FreeConventionalAllocations_

PUSHA_NO_AX_OR_BP_MACRO

	; we should be paged to physics now - should be ok

; clear thinkers 
; memset(thinkerlist, 0, MAX_THINKERS * sizeof(thinker_t));
xor   ax, ax
cwd   ; dx zero for later
mov   cx, (MAX_THINKERS * (SIZE THINKER_T)) / 2
mov   di, _thinkerlist
push  ds
pop   es
rep   stosw

; consecutive. do both
;	memset(usedtexturepagemem, 00, sizeof(uint8_t) * NUM_TEXTURE_PAGES);
;	memset(usedspritepagemem, 00, sizeof(uint8_t) * NUM_SPRITE_CACHE_PAGES);
mov   di, _usedspritepagemem
mov   cx, (_sfx_page_reference_count - _usedspritepagemem) / 2
rep   stosw


;	for ( i = 0; i < NUM_FLAT_CACHE_PAGES; i++) {
;		allocatedflatsperpage[i] = 0;
;	}  

mov   cl, NUM_FLAT_CACHE_PAGES / 2
mov   di, _allocatedflatsperpage
rep   stosw


;	// L2 cache stuff

; adjacent values
;	flatcache_l2_head = 0;
;	flatcache_l2_tail = NUM_FLAT_CACHE_PAGES-1;
;	spritecache_l2_head = 0;
;	spritecache_l2_tail = NUM_SPRITE_CACHE_PAGES-1;
;	texturecache_l2_head = 0;
;	texturecache_l2_tail = NUM_TEXTURE_PAGES-1;

mov   word ptr ds:[_flatcache_l2_head], (NUM_FLAT_CACHE_PAGES - 1) SHL 8
mov   word ptr ds:[_spritecache_l2_head], (NUM_SPRITE_CACHE_PAGES - 1) SHL 8
mov   word ptr ds:[_texturecache_l2_head], (NUM_TEXTURE_PAGES - 1) SHL 8

mov   cl, NUM_FLAT_CACHE_PAGES
mov   ax, 0FF01h
mov   di, _flatcache_nodes

loop_next_flatcache_page:
stosw
add    ax, 0101h
loop   loop_next_flatcache_page

mov    ax, 0FF01h
mov    byte ptr ds:[di-2], ah   ; 0FFh,  flatcache_nodes[flatcache_l2_tail].prev = -1;

; dx is zero

mov   cl, NUM_SPRITE_CACHE_PAGES
mov   di, _spritecache_nodes
mov   ax, 0FF01h

loop_next_spritecache_page:
stosw
xchg  ax, dx
stosw
xchg  ax, dx

add   ax, 0101h
loop  loop_next_spritecache_page

mov   ax, 0FF01h
mov   byte ptr ds:[di-4], ah  ; spritecache_nodes[spritecache_l2_tail].prev = -1;

mov   cl, NUM_TEXTURE_PAGES
;mov   di, _texturecache_nodes     ; should be equivalent to this already.

loop_next_texturecache_page:
stosw
xchg  ax, dx
stosw
xchg  ax, dx

add   ax, 0101h
loop  loop_next_texturecache_page


mov   byte ptr ds:[di-4], 0FFh   ; 0FFh,  texturecache_nodes[texturecache_l2_tail].prev = -1;



;	currentflatpage[0] = 0;
;	currentflatpage[1] = 1;
;	currentflatpage[2] = 2;
;	currentflatpage[3] = 3;
;
;	lastflatcacheindicesused[0]= 0;
;	lastflatcacheindicesused[1]= 1;
;	lastflatcacheindicesused[2]= 2;
;	lastflatcacheindicesused[3]= 3;

mov   ax, 0100h
mov   word ptr ds:[_currentflatpage+0], ax
mov   word ptr ds:[_lastflatcacheindicesused+0], ax
mov   ax, 0302h
mov   word ptr ds:[_currentflatpage+2], ax
mov   word ptr ds:[_lastflatcacheindicesused+2], ax
	



xor   ax, ax


;; ES no longer DS

;erase the level data region
; FAR_memset(((byte __far*) baselowermemoryaddress), 0, (sfx_data_segment - base_lower_memory_segment) << 4);
mov   dx, BASE_LOWER_MEMORY_SEGMENT
mov   es, dx
xor   di, di
mov   cx, (SFX_DATA_SEGMENT - BASE_LOWER_MEMORY_SEGMENT) SHL 3  ; 3 not 4 because stosw
rep   stosw


; todo make this area less jank. We want to free all the ems 4.0 region level data...
;  handles blockmaps and lines_physics...
;  do we really have to do this anyway?
; FAR_memset(MK_FP(0x7000, 0), 0, (states_segment - lines_physics_segment) << 4);

mov   dx, LINES_PHYSICS_SEGMENT
mov   es, dx
xor   di, di
mov   cx, (STATES_SEGMENT - LINES_PHYSICS_SEGMENT) SHL 3  ; 3 not 4 because stosw
rep   stosw

call  Z_QuickMapRender_

	;reset texture cache


mov   ax, 0FFFFh

; these two are consecutive in memory
;	FAR_memset(compositetexturepage, 0xFF, sizeof(uint8_t) * (MAX_TEXTURES));
;	FAR_memset(compositetextureoffset,0xFF, sizeof(uint8_t) * (MAX_TEXTURES));

mov   dx, COMPOSITETEXTUREPAGE_SEGMENT
mov   es, dx
xor   di, di
mov   cx, (2 * MAX_TEXTURES) / 2
rep   stosw

	
; these two are consecutive in memory
;	FAR_memset(patchpage, 0xFF, sizeof(uint8_t) * (MAX_PATCHES));
;	FAR_memset(patchoffset, 0xFF, sizeof(uint8_t) * (MAX_PATCHES));

mov   dx, PATCHPAGE_SEGMENT
mov   es, dx
xor   di, di
mov   cx, (2 * MAX_PATCHES) / 2
rep   stosw

; these two are consecutive in memory
;	FAR_memset(spritepage, 0xFF, sizeof(uint8_t) * (MAX_SPRITE_LUMPS));
;	FAR_memset(spriteoffset, 0xFF, sizeof(uint8_t) * (MAX_SPRITE_LUMPS));

mov   dx, SPRITEPAGE_SEGMENT
mov   es, dx
xor   di, di
mov   cx, (2 * MAX_SPRITE_LUMPS) / 2
rep   stosw


;	FAR_memset(flatindex, 0xFF, size_flatindex);


mov   dx, FLATINDEX_SEGMENT
mov   es, dx
xor   di, di
mov   cx, (MAX_FLATS)
rep   stosb


;	for (i = 0; i < MAX_FLATS; i++){
;		flattranslation[i] = i;
;	}

mov   cx, MAX_FLATS
mov   dx, FLATTRANSLATION_SEGMENT
mov   es, dx
xor   ax, ax
xor   di, di

; BYTES
loop_inc_next_flat_translation:
stosb
inc   ax
loop  loop_inc_next_flat_translation


;	for (i = 0; i < MAX_TEXTURES; i++){
;		texturetranslation[i] = i;
;	}


mov   cx, MAX_TEXTURES
mov   dx, TEXTURETRANSLATION_SEGMENT
mov   es, dx
xor   ax, ax
xor   di, di

; WORDS
loop_inc_next_tex_translation:
stosw
inc   ax
loop  loop_inc_next_tex_translation


call  Z_QuickMapPhysics_



;	// reset ems cache settings
;	for (i = 0; i < NUM_FLAT_L1_CACHE_PAGES; i ++){
;		pageswapargs[pageswapargs_flatcache_offset + i * PAGE_SWAP_ARG_MULT] = _EPR(FIRST_FLAT_CACHE_LOGICAL_PAGE+i);
;	}	

mov   cx, NUM_FLAT_L1_CACHE_PAGES
mov   dx, FIRST_FLAT_CACHE_LOGICAL_PAGE
mov   di, OFFSET _pageswapargs + PAGESWAPARGS_FLATCACHE_OFFSET * 2
push  ds
pop   es

loop_next_flatcache_ems_setup:
mov   ax, dx
EPR_MACRO ax
stosw

add   di, (2 * PAGE_SWAP_ARG_MULT) - 2  ; might be zero...
inc   dx
loop loop_next_flatcache_ems_setup


; these following two loops could probably be combined into one but i dont think we need the space 


mov   cx, NUM_TEXTURE_L1_CACHE_PAGES
mov   dx, FIRST_TEXTURE_LOGICAL_PAGE
xor   bx, bx  ; i
mov   di, OFFSET _pageswapargs + PAGESWAPARGS_REND_TEXTURE_OFFSET * 2

loop_next_texcache_ems_setup:

mov   ax, dx
EPR_MACRO ax
stosw


;    activetexturepages[i] = FIRST_TEXTURE_LOGICAL_PAGE + i;
mov   byte ptr ds:[_activetexturepages + bx], dl
mov   byte ptr ds:[_textureL1LRU + bx], bl
mov   byte ptr ds:[_activenumpages + bx], bh ; 0

add   di, (2 * PAGE_SWAP_ARG_MULT) - 2  ; might be zero...
inc   dx
inc   bx
loop loop_next_texcache_ems_setup


mov   cx, NUM_SPRITE_L1_CACHE_PAGES
mov   dx, FIRST_SPRITE_CACHE_LOGICAL_PAGE
xor   bx, bx  ; i
mov   di, OFFSET _pageswapargs + PAGESWAPARGS_SPRITECACHE_OFFSET * 2

loop_next_spritecache_ems_setup:

mov   ax, dx
EPR_MACRO ax
stosw

mov   byte ptr ds:[_activespritepages + bx], dl
mov   byte ptr ds:[_spriteL1LRU + bx], bl
mov   byte ptr ds:[_activespritenumpages + bx], bh ; 0

add   di, (2 * PAGE_SWAP_ARG_MULT) - 2  ; might be zero...
inc   dx
inc   bx
loop loop_next_spritecache_ems_setup


POPA_NO_AX_OR_BP_MACRO
ret

ENDP

	



PROC    P_SETUP_ENDMARKER_ NEAR
PUBLIC  P_SETUP_ENDMARKER_
ENDP


END