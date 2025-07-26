;
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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

;=================================

.CODE

PROC R_SPANFL_STARTMARKER_
PUBLIC R_SPANFL_STARTMARKER_
ENDP 

R_DRAWSPANACTUAL_DIFF = (OFFSET R_DrawSpanFL_ - OFFSET R_SPANFL_STARTMARKER_)

DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_JUMP_LOOKUP_SEGMENT - COLORMAPS_SEGMENT)) 


;SPANFUNC_JUMP_LOOKUP_SEGMENT and COLORMAPS_SEGMENT difference is  006A0h


MAXLIGHTZ                      = 0080h
MAXLIGHTZ_UNSHIFTED            = 0800h





; NOTE: cs:offset stuff for self modifying code must be zero-normalized
;  (subtract offset of R_DrawSpan) because this code is being moved to
; segment:0000 at runtime and the cs offset stuff is absolute, not relative.





;
; R_DrawSpan
;
PROC  R_DrawSpanFL_
PUBLIC  R_DrawSpanFL_ 
; bx is colormaps offset within cs.
; cs is colormaps segment.

xor   cx, cx
mov   dx, SC_DATA						; outp 1 << i



; main loop start (i = 0, 1, 2, 3)
xor   si, si						; zero out si as loopcount

span_i_loop_repeat:
mov   es, ds:[_spanfunc_jump_segment_storage]  ; ES is segment indexed to relevant data...

mov   cl, byte ptr ds:[_spanfunc_inner_loop_count + si]
; es is already pre-set..
inc   cl  ; these are stored such that 0 = 1 draw... todo can be improved and stored properly to begin with? then jcxz instead..

jle   do_span_loop			; todo this so it doesnt loop in both cases


; outp to plane only if there was a pixel to draw
mov   al, byte ptr ds:[_spanfunc_outp + si]
out   dx, al



; 		dest = destview + ds_y * 80 + dsp_x1;
sal   si, 1

mov   di, word ptr ds:[_spanfunc_destview_offset + si]  ; destview offset precalculated..
; todo move this out of the loop
mov   es, word ptr ds:[_ds_source_segment+2]

mov   al, byte ptr es:[0] 		; ds:si is ds_source. BX is pulled in by lds as a constant (DRAWSPAN_BX_OFFSET)
xlat  byte ptr cs:[bx]          ; bx is colormaps ptr. cs:0 is colormaps 0

mov   ah, al

mov   es, word ptr ds:[_destview + 2]	; retrieve destview segment 

sar   cx, 1
rep   stosw
rcl   cx, 1
rep   stosb

sar   si, 1
do_span_loop:

inc   si

; loop if i < loopcount.
SELFMODIFY_SPAN_compare_span_counter:
cmp   si, 4
jnge  span_i_loop_repeat

span_i_loop_done:



retf  


ENDP




;
; R_DrawSpanPrep
;
	
PROC  R_DrawSpanPrep0_ NEAR


 
 ;  	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];

; predoubles _ds_y for lookup
 les   bx, dword ptr ds:[_ds_y]
 
 mov   ax, word ptr es:[bx]				; get dc_yl_lookup[ds_y]
SELFMODIFY_SPAN_destview_lo_1:
 add   ax, 01000h
 mov   es, word ptr [bp - 0Ah]			; es holds ds_x1
	
 xor   bl, bl							; zero out bl. use it as loop counter/ i
 ; todo carry this forward
 mov   word ptr cs:[SELFMODIFY_SPAN_destview_add+2 - OFFSET R_SPANFL_STARTMARKER_], ax			; store base view offset
 
; todo the following  feels like extraneous register juggling, reexamine

 spanfunc_arg_setup_loop_start:
 mov   al, bl							; al holds loop counter
 mov   dx, es							; get ds_x1
 CBW  									; zero out ah
 
;		int16_t dsp_x1 = (ds_x1 - i) >> shiftamount;
 sub   dx, ax							; subtract i 
 SELFMODIFY_SPAN_detailshift2minus_1:
 sar   dx, 1							; shift
 sar   dx, 1							; shift

; 		int16_t dsp_x2 = (ds_x2 - i) >> shiftamount;

SELFMODIFY_SPAN_ds_x2:
 mov   cx, word ptr [bp - 0Ch]		        ; cx holds ds_x2
 sub   cx, ax							; subtract i
 mov   si, ax							; put i in si
 
 mov   ax, dx							; copy dsp_x1 to ax
 
 SELFMODIFY_SPAN_detailshift2minus_2:
 shl   ax, 1							; shift dsp_x1 left
 shl   ax, 1							; shift dsp_x1 left
 SELFMODIFY_SPAN_detailshift2minus_3:
 sar   cx, 1							; shift ds_x2 right. di = dsp_x2
 sar   cx, 1							; shift ds_x2 right. di = dsp_x2
 
 mov   di, es							; get ds_x1 into di
 
;		if ((dsp_x1 << shiftamount) + i < ds_x1)

 add   ax, si							; ax = (dsp_x1 << shiftamount) + i
 cmp   ax, di			; if si <  (dsp_x1 << shiftamount) + i

 jge   dont_increment_ds_x1     ; signed so carry flag adc 0 doesnt work?
;		ds_x1 ++
 
 inc   dx
 dont_increment_ds_x1:
 mov   al, bl							; al holds loop counter
 CBW  
 mov   si, ax							; store loop counter in si

 ; 		countp = dsp_x2 - dsp_x1;
 
;     cx has dsp_x2
 sub   cx, dx							; cx is countp

 mov   byte ptr ds:[si + _spanfunc_inner_loop_count], cl  ; store it
 test  cx, cx										   ; if negative then loop
 jl    spanfunc_arg_setup_iter_done
 
; 		spanfunc_prt[i] = (dsp_x1 << shiftamount) - ds_x1 + i;
;		spanfunc_destview_offset[i] = baseoffset + dsp_x1;

 
 mov   ax, dx										   ; move dsp_x1 to ax
 SELFMODIFY_SPAN_detailshift2minus_4:
 shl   ax, 1										   ; shift dsp_x1 left
 shl   ax, 1
 sub   ax, di										   ; subtract ds_x1
 add   ax, si										   ; add i, prt is calculated
 add   si, si										   ; double i for word lookup index
 SELFMODIFY_SPAN_destview_add:
 add   dx, 01000h						   ; dsp_x1 + base view offset
 mov   word ptr ds:[si + _spanfunc_prt], ax			   ; store prt
 mov   word ptr ds:[si + _spanfunc_destview_offset], dx   ; store view offset
 
 spanfunc_arg_setup_iter_done:
 
 inc   bl
 
 SELFMODIFY_SPAN_detailshift_mainloopcount_2:
 cmp   bl, 0
 jl    spanfunc_arg_setup_loop_start
 
 spanfunc_arg_setup_complete:


; bx stores colormap.
SELFMODIFY_SPAN_set_colormap_index_jump:  ; todo these are shifted 2 due to previous implementation, fix
mov  bx, 01000h
sar  bx, 1
sar  bx, 1

; call R_DrawSpanFL_
db 09Ah
dw ((SPANFUNC_JUMP_LOOKUP_SEGMENT - COLORMAPS_SEGMENT) SHL 4) + (OFFSET R_DrawSpanFL_ - OFFSET R_SPANFL_STARTMARKER_)
dw COLORMAPS_SEGMENT




ret  

ENDP








;
; R_MapPlane0_
; void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 )
; bp - 02h   distance low
; bp - 04h   distance high

;cachedheight   9000:0000
;yslope         9032:0000
;distscale      9064:0000
;cacheddistance 90B4:0000
;cachedxstep    90E6:0000
;cachedystep    9118:0000
; 	rather than changing ES a ton we will just modify offsets by segment distance
;   confirmed to be faster even on 8088 with it's baby prefetch queue - i think on 16 bit busses it is only faster.



PROC  R_MapPlane0_ NEAR


push  cx
push  si
push  di
push  es
push  dx

; dont cache all the data. we really only need distance. 
; calculate it each time for now. investigate caching speed later.

; si is x * 4


les   ax, dword ptr [bp - 010h]
mov   dx, es

mov   es, ds:[_cachedheight_segment_storage]
shl   di, 1


; CACHEDHEIGHT LOOKUP

cmp   dx, word ptr es:[di+2]
jne   generate_distance_steps	; comparing high word

cmp   ax, word ptr es:[di] ; compare low word
jne   generate_distance_steps

; CACHED DISTANCE lookup
use_cached_values:

mov   ax, word ptr es:[di + 0 + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]


; technically we dont need to calculate distance if its fixed colormap.
; could we skip all this other crap...
; todo technically we only use the high word anyway.
distance_steps_ready:

; ax is distance high word

; 	if (fixedcolormap) {

SELFMODIFY_SPAN_fixedcolormap_1:
mov   ax, ax
SELFMODIFY_SPAN_fixedcolormap_1_AFTER:
; 		index = distance >> LIGHTZSHIFT;



;		if (index >= MAXLIGHTZ) {
;			index = MAXLIGHTZ - 1;
;		}



cmp   al, MAXLIGHTZ
jb    index_set
mov   al, MAXLIGHTZ - 1
index_set:

;		ds_colormap_segment = colormaps_segment;
;		ds_colormap_index = planezlight[index];

les    bx, dword ptr ds:[_planezlight]
xlat  byte ptr es:[bx]
; mov  al, byte ptr cs:[bx + _cs_zlight_offset]
colormap_ready:

mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump+2 - OFFSET R_SPANFL_STARTMARKER_], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep0_


pop   dx
pop   es
pop   di
pop   si
pop   cx
ret

SELFMODIFY_SPAN_fixedcolormap_1_TARGET:
SELFMODIFY_SPAN_fixedcolormap_2:
use_fixed_colormap:
mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump+2 - OFFSET R_SPANFL_STARTMARKER_], 00

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep0_


pop   dx
pop   es
pop   di
pop   si
pop   cx
ret  

generate_distance_steps:

mov   word ptr es:[di], ax
mov   word ptr es:[di + 2], dx   ; cachedheight into dx

les   bx, dword ptr es:[di + 0 (( YSLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   cx, es

; INLINED
;call R_FixedMulLocal0_


mov   es, ax	; store ax in es
mov   ds, dx    ; store dx in ds
mov   ax, dx	; ax holds dx
CWD				; S0 in DX

AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

; AX still stores DX
MUL  CX         ; DX*CX
add  SI, AX    ; low word result into high word return

mov  AX, DS    ; restore DX from ds
MUL  BX         ; DX*BX
XCHG BX, AX    ; BX will hold low word return. store bx in ax
add  SI, DX    ; add high word to result

mov  DX, ES    ; restore AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI

mov  CX, SS   ; restore DS
mov  DS, CX


mov   es, ds:[_cacheddistance_segment_storage]
xchg  ax, dx  ; we really only use the high word shifted right 4.
SHIFT_MACRO sar ax 4

stosw;   word ptr es:[si], ax			; store distance high word

jmp   distance_steps_ready


ENDP


;R_DrawPlanes_

PROC R_DrawPlanesFL_
PUBLIC R_DrawPlanesFL_


; ARGS none

; STACK
; bp - 10h planeheight lo
; bp - 0Eh planeheight hi
; bp - 0Ch ds_x2
; bp - 0Ah ds_x1
; bp - 8 visplaneoffset
; bp - 6 visplanesegment
; bp - 4 usedflatindex
; bp - 3 usedflatindex AND 3
; bp - 2 physindex

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 10h
xor   ax, ax
mov   word ptr [bp - 8], ax
mov   word ptr [bp - 6], FIRST_VISPLANE_PAGE_SEGMENT   ; todo make constant visplane segment
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 2], ax

; inline R_WriteBackSpanFrameConstants_
; get whole dword at the end here.

; lodsw, push pop si worth?
mov   si, _basexscale + 16


lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewz_lo_1+1 - OFFSET R_SPANFL_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewz_hi_1+2 - OFFSET R_SPANFL_STARTMARKER_], ax

mov   ax, word ptr ds:[_destview+0]
mov   word ptr cs:[SELFMODIFY_SPAN_destview_lo_1+1 - OFFSET R_SPANFL_STARTMARKER_], ax

mov   al, byte ptr ds:[_extralight]
mov   byte ptr cs:[SELFMODIFY_SPAN_extralight_1+1 - OFFSET R_SPANFL_STARTMARKER_], al


mov   al, byte ptr ds:[_fixedcolormap]
test  al, al 
jne   do_span_fixedcolormap_selfmodify
mov   ax, 0c089h  ; nop
jmp   done_with_span_fixedcolormap_selfmodify

do_next_drawplanes_loop:	

inc   byte ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPANFL_STARTMARKER_]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop
do_sky_flat_draw:
; todo revisit params. maybe these can be loaded in R_DrawSkyPlaneCallHigh
les   bx, dword ptr [bp - 8] ; get visplane offset
mov   cx, es ; and segment
les   ax, dword ptr ds:[si + 4]
mov   dx, es
;call  [_R_DrawSkyPlaneCallHigh]
SELFMODIFY_SPAN_draw_skyplane_call:
db    09Ah
dw    R_DRAWSKYPLANE_OFFSET
dw    DRAWSKYPLANE_AREA_SEGMENT
inc   byte ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPANFL_STARTMARKER_]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop

exit_drawplanes:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
mov   byte ptr cs:[(SELFMODIFY_SPAN_drawplaneiter+1) - OFFSET R_SPANFL_STARTMARKER_], 0
retf   
do_span_fixedcolormap_selfmodify:
mov   byte ptr cs:[SELFMODIFY_SPAN_fixedcolormap_2 + 5 - OFFSET R_SPANFL_STARTMARKER_], al
mov   ax, ((SELFMODIFY_SPAN_fixedcolormap_1_TARGET - SELFMODIFY_SPAN_fixedcolormap_1_AFTER) SHL 8) + 0EBh
; fall thru
done_with_span_fixedcolormap_selfmodify:
; modify instruction
mov   word ptr cs:[SELFMODIFY_SPAN_fixedcolormap_1 - OFFSET R_SPANFL_STARTMARKER_], ax








mov       ax, R_DRAWSKYPLANE_OFFSET
cmp       byte ptr ds:[_screenblocks], 10
jge       setup_dynamic_skyplane
mov       ax, R_DRAWSKYPLANE_DYNAMIC_OFFSET
setup_dynamic_skyplane:
mov       word ptr cs:[SELFMODIFY_SPAN_draw_skyplane_call + 1 - OFFSET R_SPANFL_STARTMARKER_], ax



drawplanes_loop:
SELFMODIFY_SPAN_drawplaneiter:
mov   ax, 0 ; get i value. this is at the start of the function so its hard to self modify. so we reset to 0 at the end of the function
cmp   ax, word ptr ds:[_lastvisplane]
jge   exit_drawplanes
SHIFT_MACRO shl ax 3


add   ax, offset _visplaneheaders
; todo lea si bx + _visplaneheaders
mov   si, ax
mov   ax, word ptr ds:[si + 4]			; fetch visplane minx
cmp   ax, word ptr ds:[si + 6]			; fetch visplane maxx
jnle   do_next_drawplanes_loop

loop_visplane_page_check:
cmp   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
jnb   check_next_visplane_page


; todo: DI is (mostly) unused here. Can probably be used to hold something usedful.

mov   bx, word ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPANFL_STARTMARKER_]

add   bx, bx
mov   cx, word ptr ds:[bx +  _visplanepiclights]
SELFMODIFY_SPAN_skyflatnum:
cmp   cl, 0
je    do_sky_flat_draw

do_nonsky_flat_draw:

mov   byte ptr cs:[SELFMODIFY_SPAN_lookuppicnum+2 - OFFSET R_SPANFL_STARTMARKER_], cl 
mov   al, ch
xor   ah, ah

SHIFT_MACRO sar ax LIGHTSEGSHIFT


SELFMODIFY_SPAN_extralight_1:
add   al, 0
cmp   al, LIGHTLEVELS
jb    lightlevel_in_range
mov   al, LIGHTLEVELS-1
lightlevel_in_range:
; ah is 0
; shift 7
xchg  al, ah
sar   ax, 1



mov   word ptr ds:[_planezlight], ax
;mov   word ptr ds:[_planezlight + 2], ZLIGHT_SEGMENT  ; this is static and set in memory.asm

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   ax, FLATINDEX_SEGMENT
mov   es, ax

mov   al, byte ptr es:[bx]
; going to use di to hold flatunloaded
xor   di, di
cmp   al, 0ffh
jne   flat_loaded
mov   bx, di
loop_find_flat:
cmp   byte ptr ds:[bx + _allocatedflatsperpage], 4   ; if (allocatedflatsperpage[j]<4){
jl    found_page_with_empty_space
inc   bl
cmp   bl, NUM_FLAT_CACHE_PAGES
jge   found_flat_page_to_evict
jmp   loop_find_flat

check_next_visplane_page:
; do next visplane page
sub   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
inc   byte ptr [bp - 2]
cmp   byte ptr [bp - 2], 3
je    do_visplane_pagination
lookup_visplane_segment:
mov   bx, word ptr [bp - 2]
add   bx, bx
mov   ax, word ptr ds:[bx + _visplanelookupsegments]
mov   word ptr [bp - 6], ax
jmp   loop_visplane_page_check
do_visplane_pagination:
mov   al, byte ptr ds:[_visplanedirty]
add   al, 3
mov   dx, 2
cbw  
mov   byte ptr [bp - 2], 2



call  Z_QuickMapVisplanePage_SpanLocal0_


jmp   lookup_visplane_segment




found_page_with_empty_space:

mov   al, bl ; bl is usedflatindex
SHIFT_MACRO shl al 2


mov   ah, byte ptr ds:[bx + _allocatedflatsperpage]
add   al, ah
inc   byte ptr ds:[bx + _allocatedflatsperpage]
found_flat:
; al is usedflatindex
mov   di, FLATTRANSLATION_SEGMENT
mov   es, di
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   di, FLATINDEX_SEGMENT
mov   es, di

; di already nonzero
;mov   di, 1 ; update flat unloaded

mov   byte ptr es:[bx], al	; flatindex[flattranslation[piclight.bytes.picnum]] = usedflatindex;

; check l2 cache next
flat_loaded:
; ah is already set above..
mov   ah, al
and   ah, 3
mov   word ptr [bp - 4], ax     ; store usedflatindex only once, along with AND 3 of it

; al is guaranteed usedflatindex...
; consider cwd mov dl, al
xor    ah, ah
mov    dx, ax

SHIFT_MACRO sar dl 2

; dl = flatcacheL2pagenumber
cmp   dl, byte ptr ds:[_currentflatpage+0]
je    in_flat_page_0

; check if L2 page is in L1 cache

cmp   dl, byte ptr ds:[_currentflatpage+1]
jne   not_in_flat_page_1
mov   cl, 1
jmp   SHORT update_l1_cache
found_flat_page_to_evict:


;call  R_EvictFlatCacheEMSPage_   ; al stores result..
jmp    do_evict_flatcache_ems_page
done_with_evict_flatcache_ems_page:
SHIFT_MACRO shl al 2

jmp   found_flat

not_in_flat_page_1:
cmp   dl, byte ptr ds:[_currentflatpage+2]
jne   not_in_flat_page_2
mov   cl, 2
jmp SHORT  update_l1_cache
not_in_flat_page_2:
cmp   dl, byte ptr ds:[_currentflatpage+3]
jne   not_in_flat_page_3
mov   cl, 3
jmp SHORT  update_l1_cache
not_in_flat_page_3:
; L2 page not in L1 cache. need to EMS remap

; doing word writes/reads instead of byte writes/reads when possible
mov   ch, byte ptr ds:[_lastflatcacheindicesused]
mov   ax, word ptr ds:[_lastflatcacheindicesused+1]
mov   cl, byte ptr ds:[_lastflatcacheindicesused+3]

mov   word ptr ds:[_lastflatcacheindicesused], cx
mov   word ptr ds:[_lastflatcacheindicesused+2], ax

mov   ax, dx

mov   bl, cl
xor   bh, bh   ; ugly... can i do cx above
mov   byte ptr ds:[bx + _currentflatpage], al
add   ax, FIRST_FLAT_CACHE_LOGICAL_PAGE

;call  Z_QuickMapFlatPage_
;	pageswapargs[pageswapargs_flatcache_offset + offset * PAGE_SWAP_ARG_MULT] = _EPR(page);
push  cx
push  si
shl   bx, 1
SHIFT_PAGESWAP_ARGS bx
; _EPR here
IFDEF COMP_CH
    add  ax, EMS_MEMORY_PAGE_OFFSET
ELSE
ENDIF
mov   word ptr ds:[_pageswapargs + (pageswapargs_flatcache_offset * 2) + bx], ax
Z_QUICKMAPAI4 pageswapargs_flatcache_offset_size INDEXED_PAGE_7000_OFFSET

pop   si
pop   cx


jmp  SHORT l1_cache_finished_updating
in_flat_page_0:
mov   cl, 0

update_l1_cache:
mov   ch, byte ptr ds:[_lastflatcacheindicesused]
cmp   ch, cl
je    l1_cache_finished_updating
mov   ah, byte ptr ds:[_lastflatcacheindicesused+1]
cmp   ah, cl
je    in_flat_page_1
mov   al, byte ptr ds:[_lastflatcacheindicesused+2]
cmp   al, cl
je    in_flat_page_2
mov   byte ptr ds:[_lastflatcacheindicesused+3], al
in_flat_page_2:
mov   byte ptr ds:[_lastflatcacheindicesused+2], ah
in_flat_page_1:
mov   word ptr ds:[_lastflatcacheindicesused], cx
l1_cache_finished_updating:
mov   al, byte ptr [bp - 4]
SHIFT_MACRO sar al 2

;cbw  


cmp       al, byte ptr ds:[_flatcache_l2_head]
jne       jump_to_flatcachemruL2
done_with_mruL2:


cmp   di, 0 ; di used to hold flatunlodaed
jnz   flat_is_unloaded
flat_not_unloaded:
; calculate ds_source_segment


;! todo use a single 16 element lookup instead of two four element ones.
; cl is flatcacheL1pagenumber 

; calculate flat page.
; 7000h + 400h * l1 pagenumber + 100h * (usedflatindex &3)
mov   al, cl
SHIFT_MACRO sal   al 2
add   al, byte ptr [bp - 3]
add   al, 070h

mov   byte ptr ds:[_ds_source_segment+3], al            ; low byte always zero!
les   ax, dword ptr ds:[si]
mov   dx, es
SELFMODIFY_SPAN_viewz_lo_1:
sub   ax, 01000h
SELFMODIFY_SPAN_viewz_hi_1:
sbb   dx, 01000h
or    dx, dx

; planeheight = labs(plheader->height - viewz.w);

jge   planeheight_already_positive	; labs check
neg   ax
adc   dx, 0
neg   dx
planeheight_already_positive:
mov   word ptr [bp - 010h], ax
mov   word ptr [bp - 0Eh], dx
mov   ax, word ptr ds:[si + 6]
mov   di, ax
les   bx, dword ptr [bp - 8]

mov   byte ptr es:[bx + di + 3], 0ffh
mov   si, word ptr ds:[si + 4]
mov   byte ptr es:[bx + si + 1], 0ffh
inc   ax

mov   word ptr cs:[SELFMODIFY_SPAN_comparestop+2 - OFFSET R_SPANFL_STARTMARKER_], ax ; set count value to be compared against in loop.

cmp   si, ax
jle   start_single_plane_draw_loop
jmp   do_next_drawplanes_loop

jump_to_flatcachemruL2:
jmp continue_flatcachemru

; flat is unloaded. load it in
flat_is_unloaded:

; flat cache page is 7000h + 400h * cl

push  cx
mov   ch, cl
xor   cl, cl
xor   bh, bh    ; for later

sal   cx, 1
sal   cx, 1   ; cx = 400h * cl 

add   cx, FLAT_CACHE_BASE_SEGMENT

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax

SELFMODIFY_SPAN_lookuppicnum:
mov   al, byte ptr es:[00]    ; uses picnum from way above.

xor   ah, ah
add   ax, word ptr ds:[_firstflat]
mov   bl, byte ptr [bp - 3]     ; usedflatindex AND 3

add   bx, bx
mov   bx, word ptr ds:[bx + _MULT_4096]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNumDirect_addr

;call  W_CacheLumpNumDirect_
pop   cx
jmp   flat_not_unloaded



start_single_plane_draw_loop:
; loop setup

single_plane_draw_loop:
; si is x, bx is plheader pointer. so adding si gets us plheader->top[x] etc.
les    bx, dword ptr [bp - 8]

;			t1 = pl->top[x - 1];
;			b1 = pl->bottom[x - 1];
;			t2 = pl->top[x];
;			b2 = pl->bottom[x];



mov   dx, word ptr es:[bx + si + 0143h]	; b1&b2
mov   cx, word ptr es:[bx + si + 1]		; t1&t2


mov   ax, SPANSTART_SEGMENT
mov   es, ax

; t1/t2 ch/cl
; b1/b2 dh/dl
dec   si	; x - 1  constant
mov   word ptr [bp - 0Ch], si
inc   si  ; add one back from the previous saved x-1 state

;    while (t1 < t2 && t1 <= b1)

cmp   cl, ch
jae   done_with_first_mapplane_loop
; set up the di parameter to be spanstart lookup index
mov   al, cl
xor   ah, ah
mov   di, ax
add   di, ax


loop_first_mapplane:
cmp   cl, dl
ja   done_with_first_mapplane_loop

mov   ax, word ptr es:[di]
mov   word ptr ds:[_ds_y], di   ; predoubled for lookup
mov   word ptr [bp - 0Ah], ax   ; store ds_x1
inc   cl

call  R_MapPlane0_

cmp   cl, ch
jae   done_with_first_mapplane_loop
inc   di
inc   di

jmp   loop_first_mapplane

end_single_plane_draw_loop_iteration:

;  todo: di not really in use at all in this loop. could be made to hold something useful
inc   si
SELFMODIFY_SPAN_comparestop:
cmp   si, 1000h
jle   single_plane_draw_loop

;jmp exit_drawplanes

jmp   do_next_drawplanes_loop

done_with_first_mapplane_loop:



cmp   dl, dh
jbe   done_with_second_mapplane_loop
; set up the di parameter to be spanstart lookup index
mov   al, dl
xor   ah, ah
mov   di, ax
add   di, ax

loop_second_mapplane:
cmp   cl, dl
ja   done_with_second_mapplane_loop

mov   ax, word ptr es:[di]
mov   word ptr ds:[_ds_y], di
mov   word ptr [bp - 0Ah], ax
dec   dl

call  R_MapPlane0_

cmp   dl, dh
jbe   done_with_second_mapplane_loop

dec   di
dec   di
jmp   loop_second_mapplane

done_with_second_mapplane_loop:

; update spanstarts



; b1 = dl
; b2 = dh
; t1 = cl
; t2 = ch

;			while (t2 < t1 && t2 <= b2) {
;				spanstart[t2] = x;

mov   ax, SPANSTART_SEGMENT
mov   es, ax

mov   bx, cx

sub   cl, ch     ; t2 < t1?
jbe   second_spanstart_update_loop
mov   ax, dx
sub   ah, ch     ; t2 <= b2?
jb    second_spanstart_update_loop

inc   ah		; add one for the >= 
cmp   ah, cl
ja    dont_swap_cx_params_1  ; todo jae and inc inside
mov   cl, ah
dont_swap_cx_params_1:


mov   al, ch  ; get t2 word lookup...
xor   ah, ah
add   ax, ax
mov   di, ax  ; di = offset

xor   ch, ch  ; cx loop count is set
mov   ax, bx
add   bh, cl  ; add the t2 increment

mov   ax, si  ;  ax = x
rep   stosw



second_spanstart_update_loop:


;			while (b2 > b1 && b2 >= t2) {
;				spanstart[b2] = x;
; b1 = dl
; b2 = dh
; t1 = bl
; t2 = bh

mov   ax, dx
sub   ah, al    ; b2 - b1
jbe   end_single_plane_draw_loop_iteration
mov   cl, dh	; store b2 copy for spanstart addr calculation
sub   dh, bh    ; b2 - t2
jb    end_single_plane_draw_loop_iteration

; add one for the >= case 
inc   dh
; ah and ch store the two values... take the smallest one to get loop count
cmp   ah, dh
ja    dont_swap_cx_params_2
mov   dh, ah
dont_swap_cx_params_2:


xor   ch, ch
mov   di, cx  ; cl held copied b2 from above
add   di, di  ; di = offset

mov   cl, dh  ; count


mov   ax, si  ;  ax = x
std   
rep   stosw
cld
jmp   end_single_plane_draw_loop_iteration



ENDP



;PROC R_MarkL2FlatCacheMRU0_ NEAR


;	if (index == flatcache_l2_head) {
;		return;
;	}

continue_flatcachemru:
push      si




;	cache_node_t far* nodelist  = flatcache_nodes;

mov       dl, al
mov       bx, OFFSET _flatcache_nodes


;	prev = nodelist[index].prev;
;	next = nodelist[index].next;


cbw      

add       ax, ax
mov       si, ax
mov       ax, word ptr ds:[si + bx]

mov       dh, al ; back up

;	if (index == flatcache_l2_tail) {
;		flatcache_l2_tail = next;	
;	} else {
;		nodelist[prev].next = next;
;	}

cmp       dl, byte ptr ds:[_flatcache_l2_tail]
jne       index_not_tail

mov       byte ptr ds:[_flatcache_l2_tail], ah
jmp       flat_tail_check_done

index_not_tail:

mov       si, ax
and       si, 000FFh      ; blegh
sal       si, 1
mov       byte ptr ds:[si + bx + 1], ah

flat_tail_check_done:

;	// guaranteed to have a next. if we didnt have one, it'd be head but we already returned from that case.
;	nodelist[next].prev = prev;

mov       al, ah
cbw      

mov       si, ax
sal       si, 1

mov       byte ptr ds:[si + bx], dh
mov       al, dl

mov       si, ax
sal       si, 1

;	nodelist[index].prev = flatcache_l2_head;
;	nodelist[index].next = -1;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx], al
mov       byte ptr ds:[si + bx + 1], 0FFh

mov       si, ax
sal       si, 1

;	nodelist[flatcache_l2_head].next = index;

mov       byte ptr ds:[si + bx + 1], dl

;	flatcache_l2_head = index;
mov       byte ptr ds:[_flatcache_l2_head], dl
exit_flatcachemru:
pop       si
jmp       done_with_mruL2

ENDP


;PROC R_EvictFlatCacheEMSPage0_ NEAR

do_evict_flatcache_ems_page:

push      bx
push      dx
push      si
mov       al, byte ptr ds:[_flatcache_l2_tail]
mov       dh, al
cbw      

;	evictedpage = flatcache_l2_tail;
mov       bx, OFFSET _flatcache_nodes
mov       si, ax        ; si gets evictedpage.

;	// all the other flats in this are cleared.
;	allocatedflatsperpage[evictedpage] = 1;
mov       byte ptr ds:[si + _allocatedflatsperpage], 1
sal       si, 1  ; now word lookup.

;	flatcache_l2_tail = flatcache_nodes[evictedpage].next;	// tail is nextmost

mov       dl, byte ptr ds:[si + bx + 1]         ; dl has flatcache_l2_tail
mov       byte ptr ds:[_flatcache_l2_tail], dl

;	flatcache_nodes[evictedpage].next = -1;
mov       byte ptr ds:[si + bx + 1], 0FFh

;	flatcache_nodes[evictedpage].prev = flatcache_l2_head;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx + 0], al

;	flatcache_nodes[flatcache_l2_head].next = evictedpage;
mov       si, ax
sal       si, 1
mov       byte ptr ds:[si + bx + 1], dh

;	flatcache_nodes[flatcache_l2_tail].prev = -1;

mov       al, dl
mov       si, ax
sal       si, 1
mov       byte ptr ds:[si + bx], 0FFh


;	flatcache_l2_head = evictedpage;


mov       byte ptr ds:[_flatcache_l2_head], dh


mov       bx, FLATINDEX_SEGMENT
mov       ds, bx
mov       ah, dh
xor       si, si
mov       bx, -1
mov       dx, MAX_FLATS


;   for (i = 0; i < MAX_FLATS; i++){
;	   if ((flatindex[i] >> 2) == evictedpage){
;         flatindex[i] = 0xFF;
;   	}
;  	}
check_next_flat:
lodsb       ; si is always one in front because of lodsb...

SHIFT_MACRO shr       al 2
cmp       al, ah
je        erase_flat
continue_erasing_flats:
cmp       si, dx
jb        check_next_flat
mov       al, ah
mov       bx, ss
mov       ds, bx
pop       si
pop       dx
pop       bx
jmp       done_with_evict_flatcache_ems_page
;ret   

erase_flat:
mov       byte ptr ds:[si+bx], bl   ; bx is -1. this both writes FF and subtracts the 1 from si
jmp       continue_erasing_flats

ENDP

PROC Z_QuickMapVisplanePage_SpanLocal0_ NEAR




;	int16_t usedpageindex = pagenum9000 + PAGE_8400_OFFSET + physicalpage;
;	int16_t usedpagevalue;
;	int8_t i;
;	if (virtualpage < 2){
;		usedpagevalue = FIRST_VISPLANE_PAGE + virtualpage;
;	} else {
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
;	}

push  bx
push  cx
push  si
mov   cl, al
mov   dh, dl
mov   al, dl
cbw  
IFDEF COMP_CH
mov   si, CHIPSET_PAGE_9000
ELSE
mov   si, word ptr ds:[_pagenum9000]
ENDIF
add   si, PAGE_8400_OFFSET ; sub 3
add   si, ax
mov   al, cl
cbw  
cmp   al, 2
jge   visplane_page_above_2
add   ax, FIRST_VISPLANE_PAGE
used_pagevalue_ready:

;		pageswapargs[pageswapargs_visplanepage_offset] = _EPR(usedpagevalue);

; _EPR here
IFDEF COMP_CH
    add  ax, EMS_MEMORY_PAGE_OFFSET
ELSE
ENDIF
mov   word ptr ds:[_pageswapargs + (pageswapargs_visplanepage_offset * 2)], ax


;pageswapargs[pageswapargs_visplanepage_offset+1] = usedpageindex;
IFDEF COMP_CH
ELSE
    mov   word ptr ds:[_pageswapargs + ((pageswapargs_visplanepage_offset+1) * 2)], si
ENDIF

;	physicalpage++;
inc   dh
mov   dl, 4

;	for (i = 4; i > 0; i --){
;		if (active_visplanes[i] == physicalpage){
;			active_visplanes[i] = 0;
;			break;
;		}
;	}

loop_next_visplane_page:
mov   al, dl
cbw  
mov   bx, ax
cmp   dh, byte ptr ds:[bx + _active_visplanes]
je    set_zero_and_break
dec   dl
test  dl, dl
jg    loop_next_visplane_page

done_with_visplane_loop:
mov   al, cl
cbw  
mov   bx, ax

mov   byte ptr ds:[bx + _active_visplanes], dh


IFDEF COMP_CH
    IF COMP_CH EQ CHIPSET_SCAT

        mov  	dx, SCAT_PAGE_SELECT_REGISTER
        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out  	dx, al
        mov     ax,  ds:[(pageswapargs_visplanepage_offset * 2) + _pageswapargs]
        mov  	dx, SCAT_PAGE_SET_REGISTER
        out 	dx, ax

    ELSEIF COMP_CH EQ CHIPSET_SCAMP

        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out     SCAMP_PAGE_SELECT_REGISTER, al
        mov     ax, ds:[_pageswapargs + (2 * pageswapargs_visplanepage_offset)]
        out 	SCAMP_PAGE_SET_REGISTER, ax

    ELSEIF COMP_CH EQ CHIPSET_HT18

        mov  	dx, HT18_PAGE_SELECT_REGISTER
        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out  	dx, al
        mov     ax,  ds:[(pageswapargs_visplanepage_offset * 2) + _pageswapargs]
        mov  	dx, HT18_PAGE_SET_REGISTER
        out 	dx, ax

    ENDIF

ELSE


    Z_QUICKMAPAI1 pageswapargs_visplanepage_offset_size unused_param



ENDIF


mov   byte ptr ds:[_visplanedirty], 1
pop   si
pop   cx
pop   bx
ret  
visplane_page_above_2:
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
add   ax, (EMS_VISPLANE_EXTRA_PAGE - 2)
jmp   used_pagevalue_ready

set_zero_and_break:
mov   byte ptr ds:[bx + _active_visplanes], 0
jmp   done_with_visplane_loop

ENDP



;
; The following functions are loaded into a different segment at runtime.
; However, at compile time they have access to the labels in this file.
;


;R_WriteBackViewConstantsSpan

PROC R_WriteBackViewConstantsSpanFL_ FAR
PUBLIC R_WriteBackViewConstantsSpanFL_ 



mov      ax, SPANFUNC_JUMP_LOOKUP_SEGMENT
mov      ds, ax


ASSUME DS:R_SPANFL_TEXT


mov      al, byte ptr ss:[_skyflatnum]

mov      byte ptr ds:[SELFMODIFY_SPAN_skyflatnum + 2 - OFFSET R_SPANFL_STARTMARKER_], al


mov      al, byte ptr ss:[_detailshift]
cmp      al, 1
je       do_detail_shift_one
jl       do_detail_shift_zero
jmp      do_detail_shift_two
do_detail_shift_zero:

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPANFL_STARTMARKER_], 4
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPANFL_STARTMARKER_], 4




; 2 minus

mov ax, 0e0d1h ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPANFL_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPANFL_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPANFL_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPANFL_STARTMARKER_], ax  ; shl   ax, 1
mov ax, 0FAD1h  ; shr   dx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPANFL_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPANFL_STARTMARKER_], ax  ; sar   dx, 1
mov ax, 0F9d1h  ; sar   cx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPANFL_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPANFL_STARTMARKER_], ax  ; sar   cx, 1



jmp     done_with_detailshift
do_detail_shift_one:

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPANFL_STARTMARKER_], 2
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPANFL_STARTMARKER_], 2






mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPANFL_STARTMARKER_], 0FAD1h  ; sar   dx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPANFL_STARTMARKER_], 0F9D1h  ; sar   cx, 1
mov      ax, 0E0D1h
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPANFL_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPANFL_STARTMARKER_], ax  ; shl   ax, 1


mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPANFL_STARTMARKER_], ax

jmp     done_with_detailshift

do_detail_shift_two:


mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPANFL_STARTMARKER_], 1
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPANFL_STARTMARKER_], 1



; two minus
mov   ax, 0c089h  ; nop

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPANFL_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPANFL_STARTMARKER_], ax

done_with_detailshift:




mov      ax, ss
mov      ds, ax





ASSUME DS:DGROUP

retf

ENDP





; end marker for this asm file
PROC R_SPANFL_ENDMARKER_ FAR
PUBLIC R_SPANFL_ENDMARKER_ 
ENDP



END
