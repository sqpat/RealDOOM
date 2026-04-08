
FAST_SHL1 MACRO reg
IF COMPISA GE COMPILE_386
    ADD &reg, &reg
ELSE
    SHL &reg, 1
ENDM
ENDM
FAST_RCL1 MACRO reg
IF COMPISA GE COMPILE_386
    ADC &reg, &reg
ELSE
    RCL &reg, 1
ENDIF
ENDM

PUSH_IMM MACRO scratch imm
IF COMPISA GE COMPILE_186
    PUSH &imm
ELSE
    MOV &scratch, &imm
    PUSH &scratch
ENDIF
ENDM

; Documentation macro for correcting stack offsets.
; Positive argument is number of PUSH compared to normal frame.
; Negative argument is number of POP compared to normal frame.
PUSH_OFFSETS MACRO count
(&count * 2)
ENDM

; Documentation macro for correcting stack offsets.
; Argument is number of LODSW to subtract from the size
LODSW_OFFSETS MACRO count
(&count * -2)
ENDM

HALF_PI = 2048

    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
PROC   R_DrawPlanes24_ FAR
PUBLIC R_DrawPlanes24_

; ARGS
; none

; NORMAL STACK (negatives are pushed temps)
; SP - 2 = &_visplaneheaders[i]
; SP + 0 = visplaneoffset
; SP + 2 = visplanesegment
; SP + 4 = Return addr

; PRESERVE (Outer function has a POPA anyway)
; SS = FIXED_DS_SEGMENT
; DS = FIXED_DS_SEGMENT

local_visplaneoffset = 0
local_visplanesegment = 2
draw_planes_frame_size = 4

    PUSH_IMM DX FIRST_VISPLANE_PAGE_SEGMENT ; SP + 2
    XOR BP, BP ; SP + 0 (will be pushed later)
    
    MOV AX, CS ; 2 byte, 2 cycle
    MOV ES, AX ; 2 byte, 2 cycle
    
    MOV SI, _basexscale
IF COMPISA LE COMPILE_286
    MOV DI, SELFMODIFY_SPAN_basexscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    INC DI ; SELFMODIFY_SPAN_basexscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    
    MOV DI, SELFMODIFY_SPAN_baseyscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    INC DI ; SELFMODIFY_SPAN_baseyscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    
    MOV DI, SELFMODIFY_SPAN_viewx_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    ADD DI, 2 ; SELFMODIFY_SPAN_viewx_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    
    MOV DI, SELFMODIFY_SPAN_viewy_lo_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    ADD DI, 2 ; SELFMODIFY_SPAN_viewy_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
ELSE
    MOV DI, SELFMODIFY_SPAN_basexscale_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_baseyscale_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_viewx_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_viewy_full_1+3 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
ENDIF
    
IF COMPISA LE COMPILE_286
    LODSW
    XCHG AX, DX
    LODSW
    SHIFT32_MACRO_LEFT AX DX 3
ELSE
    LODSD DS:[SI]
    SHR EAX, 13
ENDIF
    MOV CS:[SELFMODIFY_SPAN_viewz_13_3_1+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    MOV AX, DS:[_destview]
    MOV CS:[SELFMODIFY_SPAN_destview_1+2 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    MOV AX, DS:[_skyflatnum]
    MOV CS:[SELFMODIFY_SPAN_skyflatnum+1 - OFFSET R_SPAN24_STARTMARKER_], AL
    SHIFT_MACRO SHL AH 4
    MOV CS:[SELFMODIFY_SPAN_extralight_1+2 - OFFSET R_SPAN24_STARTMARKER_], AH
    
    CMP BYTE DS:[_screenblocks], 10
    SBB AX, AX
    AND AX, OFFSET _R_DrawSkyPlaneDynamic_addr - OFFSET _R_DrawSkyPlane_addr
    ADD AX, OFFSET _R_DrawSkyPlane_addr
    MOV CS:[SELFMODIFY_SPAN_draw_skyplane_call + 2 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    MOV SI, OFFSET _visplaneheaders + VISPLANEHEADER_T.visplaneheader_minx
    
    MOV DI, OFFSET SELFMODIFY_SPAN_fixedcolormap_2+1 -  - OFFSET R_SPAN24_STARTMARKER_
    
    MOV AL, DS:[_fixedcolormap]
    TEST AL, AL
    JNZ do_span_fixedcolormap_selfmodify
    MOV AL, MAXLIGHTZ - 1
    STOSB
IF COMPISA LE COMPILE_286
    MOV AX, 0xFA83 ; CMP DX
ELSE
    MOV AX, 0x8366 ; CMP EDI
ENDIF
    STOSW
    MOV DI, SP
    JMP drawplanes_start
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
do_span_fixedcolormap_selfmodify:
    STOSB
    MOV AX, ((colormap_fixed - SELFMODIFY_SPAN_fixedcolormap_1+2) SHL 8) OR 0xEB ; JMP colormap_fixed
    STOSW
    MOV DI, SP
    JMP drawplanes_start
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
next_visplane_page:
    XOR BP, BP
    ADD WORD DS:[DI + local_visplanesegment + (PUSH_OFFSETS -1)], 0x400
    JMP visplane_set
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
exit_drawplanes:
    ADD SP, draw_planes_frame_size + (PUSH_OFFSETS -1)
    RETF
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
do_sky_flat_draw:
    ; Function preserves SI, DI, BP
    ; AX is still visplane.minx
    MOV BX, BP
    MOV CX, DS:[DI + local_visplanesegment + (PUSH_OFFSETS -1)]
    MOV DX, DS:[SI]
SELFMODIFY_SPAN_draw_skyplane_call:
    CALL FAR DWORD DS:[_R_DrawSkyPlane_addr] ; Can this be a modified 9A call?

ALIGN_MACRO
drawplanes_loop: ; LOOP DEPTH: 1
    ADD SI, SIZE VISPLANEHEADER_T - (LODSW_OFFSETS 1)
    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; BP = visplaneoffset
    ; SI = &_visplaneheaders[i].visplaneheader_minx
    ; DI = SP
    ADD BP, SIZE VISPLANE_T
    CMP BP, VISPLANE_BYTES_PER_PAGE
    JAE next_visplane_page
visplane_set:
drawplanes_start:
SELFMODIFY_SPAN_lastvisplane:
    CMP SI, 0x1000 ; TODO: self modify constant (&_visplaneheaders[_lastvisplane].visplaneheader_minx)
    JA exit_drawplanes
    
    LODSW ; fetch visplane minx
    CMP AX, DS:[SI] ; fetch visplane maxx
    JG drawplanes_loop
    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; BP = visplaneoffset
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    ; DI = SP
    MOV AX, DS:[SI - (VISPLANEHEADER_T.visplaneheader_piclight - VISPLANEHEADER_T.visplaneheader_maxx)]
SELFMODIFY_SPAN_skyflatnum:
    CMP AL, 0
    JE do_sky_flat_draw
    MOV CS:[SELFMODIFY_SPAN_lookuppicnum+2 - OFFSET R_SPAN24_STARTMARKER_], AL
    
    PUSH BP ; SP + 0
    XOR BX, BX
    
    MOV DX, FLATTRANSLATION_SEGMENT
    MOV ES, DX
    XLAT ES:[BX]
    MOV DX, FLATINDEX_SEGMENT
    MOV ES, DX
    XCHG AL, BL  ; NOTE: Just saves AL for later in BL,
    XLAT ES:[BX] ; doesn't matter for XLAT because BL was 0
    
SELFMODIFY_SPAN_extralight_1:
    ADD AH, 0
    SBB CX, CX
IF COMPISA LE COMPILE_286
    OR CL, AH
    SHL CX, 1
    SHL CX, 1
    SHL CX, 1
    AND CX, 0x0780
ELSE
    OR CX, AX
    SHR CX, 12
    SHL CX, 7
ENDIF
    MOV DS:[_planezlight], CX
    
    MOV CX, 0xFF01
    
    MOV AH, 0xBA ; MOV DX, imm
    
    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; ES = FLATINDEX_SEGMENT
    ; AL = usedflatindex
    ; AH = self modify instruction constant
    ; CL = 1
    ; CH = -1
    ; DX = FLATINDEX_SEGMENT
    ; BL = FLATINDEX_SEGMENT offset
    ; BH = 0
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    ; DI = SP
    
    CMP AL, CH
    JNE flat_loaded
    MOV BP, SI
    MOV DI, BX
    MOV SI, _allocatedflatsperpage + NUM_FLAT_CACHE_PAGES
    MOV BX, -(NUM_FLAT_CACHE_PAGES)
loop_find_flat: ; LOOP DEPTH: 2
    MOV AX, DS:[BX + SI]
    CMP AL, 4
    JB found_page_with_empty_spaceA
    INC BX
    CMP AH, 4
    JB found_page_with_empty_spaceB
    INC BX
    JNZ loop_find_flat
    ; LOOP DEPTH: 1
    
    MOV AX, DS:[_flatcache_l2_head] ; AL = head, AH = tail
    ; evictedpage = flatcache_l2_tail
    MOV BL, AH
    ; // all the other flats in this are cleared.
    ; allocatedflatsperpage[evictedpage] = 1
    MOV BYTE DS:[BX + SI - NUM_FLAT_CACHE_PAGES], CL
    MOV CL, AL
    MOV AL, AH
    MOV SI, OFFSET _flatcache_nodes
    FAST_SHL1 BL
    ; flatcache_l2_tail = flatcache_nodes[evictedpage].next
    MOV AH, DS:[BX + SI + 1]
    ; flatcache_l2_head = evictedpage
    MOV DS:[_flatcache_l2_head], AX
    ; flatcache_nodes[evictedpage].prev = flatcache_l2_head
    ; flatcache_nodes[evictedpage].next = -1
    MOV DS:[BX + SI], CX
    FAST_SHL1 BL
    ; flatcache_nodes[flatcache_l2_tail].prev = -1
    XCHG BL, AH
    FAST_SHL1 BL
    MOV DS:[BX + SI], CH
    ; flatcache_nodes[flatcache_l2_head].next = evictedpage
    MOV BL, CL
    FAST_SHL1 BL
    MOV DS:[BX + SI + 1], AL
    
    SHIFT_MACRO SHL AH 2
    XOR SI, SI
    MOV BX, -1
    MOV DS, DX ; NOTE: Can be removed if following flat loop isn't slower with ES:
    MOV DL, 0xFC
    MOV CX, MAX_FLATS
;   for (i = 0; i < MAX_FLATS; i++) {
;       if ((flatindex[i] >> 2) == evictedpage) {
;           flatindex[i] = 0xFF;
;       }
;  	}
ALIGN_MACRO
check_next_flat: ; LOOP DEPTH: 2
    LODSB
    AND AL, DL
    CMP AL, AH
    JE erase_flat
    LOOP check_next_flat
    MOV AL, AH
    JMP done_with_evict_flatcache_ems_page
erase_flat:
    MOV DS:[BX + SI], BL
    JMP check_next_flat
    
    ; ==================== HOLE HOLE HOLE ====================
    
found_page_with_empty_spaceB: ; LOOP DEPTH: 1
    MOV AL, AH
found_page_with_empty_spaceA:
    ADD CL, AL
    MOV DS:[BX + SI], CL
    SHIFT_MACRO SHL BL 2
    OR AL, BL
found_flat:
done_with_evict_flatcache_ems_page:
    STOSB
    MOV SI, BP
    MOV AH, 0xE9
flat_loaded:
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; AL = usedflatindex
    ; AH = self modify instruction constant
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    MOV CS:[SELFMODIFY_SPAN_flat_unloaded - OFFSET R_SPAN24_STARTMARKER_], AH
    
    MOV AH, AL
    AND AH, 3
    
    MOV BP, AX
    SHIFT_MACRO SHR AL 2
    
    MOV CX, SS
    MOV DS, CX ; NOTE: Can be removed if previous flat loop isn't slower with ES:
    MOV ES, CX
    
    MOV CX, 4
    MOV DI, _currentflatpage
    REPNE SCASB ; This should be fast since it takes advantage of CL afterwards
    ; TODO: Branch has a range issue on 286.
    ; Check if target code can fit in a nearby gap
    ; or just put a trampoline JMP in there.
    JNE update_l1_cache_from_l2
    XOR CL, 3 ; Convert 3-0 to 0-3
    ; Correct DI to consistently point to _currentflatpage+1
    ; MOV DI, _lastflatcacheindicesused would remove offsets though...
    SUB DI, CX
    
    MOV DX, DS:[DI + 3]
    CMP DL, CL
    JE in_flat_page_0
    MOV CH, DL
    CMP DH, CL
    JE in_flat_page_1
    MOV BX, DS:[DI + 5]
    CMP BL, CL
    JE in_flat_page_2
    MOV BH, BL
in_flat_page_2:
    MOV BL, DH
    MOV DS:[DI + 5], BX
in_flat_page_1:
    MOV DS:[DI + 3], CX
in_flat_page_0:
    XOR BH, BH
l1_cache_finished_updating:
    ; Register state (all not listed are junk/scratch):
    ; ES = DS = SS = FIXED_DS_SEGMENT
    ; AL = usedflatindex >> 2
    ; AH = usedflatindex & 3
    ; CL = flatpageindex
    ; BH = 0
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    
    ; NOTE: Could pull _flatcache_l2_head constant out of flatcachemruL2
    CMP AL, DS:[_flatcache_l2_head]
    ; TODO: Branch has a range issue on 286.
    ; Check if target code can fit in a nearby gap
    ; or just put a trampoline JMP in there.
    JNE flatcachemruL2
done_with_mruL2:
    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; AH = usedflatindex & 3
    ; CL = flatpageindex
    ; BH = 0
    ; SI = &_visplaneheaders[i].visplaneheader_maxx

    SHIFT_MACRO SHL CL 2
    ADD CL, (FLAT_CACHE_BASE_SEGMENT SHR 8)
    MOV CH, CL
    MOV CL, BH
SELFMODIFY_SPAN_flat_unloaded:
    JMP LONG flat_is_unloaded
    ADD CH, AH
flat_not_unloaded:
    MOV DS:[_ds_source_offset+3], CH
    
    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    
    MOV AX, DS:[SI - (VISPLANEHEADER_T.visplaneheader_height - VISPLANEHEADER_T.visplaneheader_maxx)]
SELFMODIFY_SPAN_viewz_13_3_1:
    SUB AX, 0x1000
    CWD ; ABS
    XOR AX, DX
    SUB AX, DX
    MOV CS:[SELFMODIFY_SPAN_plane_height+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    MOV DI, SP
    PUSH SI ; It's probably not worth a self-modify write ahead here...
    ; NOTE: SP relative indexing now needs +2 (except current DI)
    
    MOV BP, DS:[SI - (VISPLANEHEADER_T.visplaneheader_minx - VISPLANEHEADER_T.visplaneheader_maxx)]
    MOV BX, DS:[SI] ; Already pointing to visplaneheader_maxx
    MOV CS:[SELFMODIFY_SPAN_loop_stop+1 - OFFSET R_SPAN24_STARTMARKER_], BX ; stop = maxx (not +1 because of increment change)
    LDS SI, DS:[DI + local_visplaneoffset]
    
    MOV DX, 0x00FF
    
    ; NOTE: Handling of x2 is a bit of a hack, this section needs work
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = visplanesegment
    ; DL = 0xFF (initial t1 value)
    ; DH = 0
    ; BX = _visplaneheaders[i].visplaneheader_maxx
    ; BP = _visplaneheaders[i].visplaneheader_minx
    ; SI = &visplanes[i]
    
    MOV DS:[BX + SI + VISPLANE_T.vp_top + 1], DL ; visplanes[i].vp_top[maxx + 1] = 0xFF
    LEA SI, [BP + SI + VISPLANE_T.vp_top]
    MOV DS:[SI - 1], DL ; visplanes[i].vp_top[minx - 1] = 0xFF
    
    MOV AX, SI ; NOTE: Using NOT instead of NEG here allows omitting the +1 from stop
    NOT AX ; -(&visplanes[i].vp_top[minx + 1])
    MOV CS:[SELFMODIFY_SPAN_loop_calc_x+2 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    XCHG AX, BP
    MOV BP, SPANSTART_SEGMENT
    
    ; NOTE: There was originally a comparison here, but it's likely impossible to fail
    ; because the same condition was tested for at the very start of drawplanes_loop
    
    ; NOTE: t1 was just written, don't re-read
    MOV BX, DS:[SI + (VISPLANE_T.vp_bottom - VISPLANE_T.vp_top) - 1] ; b1/b2

ALIGN_MACRO
single_plane_draw_loop: ; LOOP DEPTH: 2

    MOV CS:[SELFMODIFY_SPAN_write_ahead_x2+1 - OFFSET R_SPAN24_STARTMARKER_], AX

    LODSB ; t2 = visplanes[i].vp_top[x++]
    
    ; NOTE: Saves 5 bytes of prefixes
    MOV DI, CS
    MOV DS, DI
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = CS
    ; AL = t2
    ; DX = t1
    ; BL = b1
    ; BH = b2
    ; BP = SPANSTART_SEGMENT
    ; SI = &visplanes[i].vp_top[x + 1]
    
    PUSH SI
    
    MOV DS:[SELFMODIFY_SPAN_t2_loop_index+1 - OFFSET R_SPAN24_STARTMARKER_], AL
    MOV DS:[SELFMODIFY_SPAN_b2_loop_index+1 - OFFSET R_SPAN24_STARTMARKER_], BH
    
    ; NOTE: Should test if any of these conditions are impossible,
    ; like if t1 is always larger than min(t2, b1 + 1) or such
    
    MOV SI, DX
    
    ; CL = b1 + 1
    ; CH = b2 + 1
    LEA CX, [BX + 0x0101] ; INC both BL and BH, values won't carry
    
    ; AL = t1_bound = min(t2, b1 + 1)
    MOV AH, AL
    SUB AL, CL
    SBB DH, DH
    AND AL, DH
    ADD AL, CL
    
    ; DL = t1_after = max(t1, t1_bound)
    SUB DL, AL
    CMC
    SBB DH, DH
    AND DL, DH
    ADD DL, AL
    
    ; AL = t2_bound = min(t1_after, b2 + 1)
    MOV AL, CH
    SUB AL, DL
    SBB DH, DH
    AND AL, DH
    ADD AL, DL
    
    ; CH = b1_bound = max(t1_after, b2 + 1)
    ; NOTE: only works because of how t2_bound was calculated
    XOR CH, AL
    XOR CH, DL
    
    ; CH = b1_after = min(b1, b1_bound - 1)
    SUB CH, CL
    SBB CL, CL
    AND CH, CL
    ADD CH, BL
    
    ; AL = t2_count = max(t2 - t2_bound, 0)
    SUB AL, AH
    CMC
    SBB CL, CL
    AND AL, CL
    MOV DS:[SELFMODIFY_SPAN_t2_loop_count+1 - OFFSET R_SPAN24_STARTMARKER_], AL
    ; AL = t2_after = t2 + t2_count
    ADD AL, AH
    
    ; AL = b2_bound = max(max(t2_after - 1, 0), b1_after)
    XOR DH, DH ; NOTE: DH needs to be 0 later anyway
    CMP DH, AL
    SBB AL, CH
    CMC
    SBB CL, CL
    AND AL, CL
    ADD AL, CH
    
    ; AL = b2_count = max(b2 - b2_bound, 0)
    SUB BH, AL
    CMC
    SBB AL, AL
    AND AL, BH
    MOV DS:[SELFMODIFY_SPAN_b2_loop_count+1 - OFFSET R_SPAN24_STARTMARKER_], AL
    
    MOV BH, CH
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = CS
    ; DX = t1_after (will always be >= t1)
    ; BL = b1
    ; BH = b1_after (will always be <= b1)
    ; BP = SPANSTART_SEGMENT
    ; SI = t1
    
    ; FIRST LOOP
    SUB DX, SI
    JZ skip_first_mapplane_loop
    PUSH BX
    MOV BYTE DS:[SELFMODIFY_SPAN_map_planes_dir_flag - OFFSET R_SPAN24_STARTMARKER_], 0x3E ; Useless DS prefix
    PUSH DX ; Count argument
    CALL R_MapPlanes24_
    XOR DX, DX
    POP BX
skip_first_mapplane_loop:
    ; DX = 0
    XCHG DL, BH
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DX = b1_after
    ; BX = b1
    ; BP = SPANSTART_SEGMENT
    
    ; SECOND LOOP
    MOV SI, BX
    SUB BX, DX
    JZ skip_second_mapplane_loop
    ; NOTE: Does this really *need* to go backwards? Test this, could simplify
    MOV BYTE CS:[SELFMODIFY_SPAN_map_planes_dir_flag - OFFSET R_SPAN24_STARTMARKER_], 0xFD ; STD
    PUSH BX ; Count argument
    CALL R_MapPlanes24_
skip_second_mapplane_loop:
    MOV ES, BP
    
    POP SI
SELFMODIFY_SPAN_loop_calc_x:
    LEA AX, [SI - 0x1000] ; Calculate X from current pointer
    
    ; NOTE: Only the low byte is written for
    ; these values so using 0x1000 would break
SELFMODIFY_SPAN_t2_loop_count:
    MOV CX, 0x0000
SELFMODIFY_SPAN_t2_loop_index:
    MOV DI, 0x0000
    MOV DX, DI ; Recover t2 to use as t1 next iter
    FAST_SHL1 DI
    REP STOSW
    ; CX = 0
SELFMODIFY_SPAN_b2_loop_count:
    MOV CL, 0x00
SELFMODIFY_SPAN_b2_loop_index:
    MOV DI, 0x0000
    MOV BX, DI ; Recover b2 to use as b1 next iter
    FAST_SHL1 DI
    STD
    REP STOSW
    CLD
    ; CX = 0
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; AX = X
    ; DX = t1
    ; BX = b1
    ; BP = SPANSTART_SEGMENT
    ; SI = &visplanes[i].vp_top[x] (for next iter)
    
SELFMODIFY_SPAN_loop_stop:
    CMP AX, 0x1000
    JA end_draw_loop_iteration
    
    INC AX
    
    MOV DI, SP
    MOV DS, SS:[DI + local_visplanesegment + (PUSH_OFFSETS 1)]
    MOV BH, DS:[SI + (VISPLANE_T.vp_bottom - VISPLANE_T.vp_top)] ; Get new b2
    ; NOTE: New t2 is read at the start of the loop
    JMP single_plane_draw_loop
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
end_draw_loop_iteration: ; LOOP DEPTH: 1
    POP SI ; Get back the visplane header pointer
    POP BP ; Read visplane offset into a register for use
    MOV AX, SS
    MOV DS, AX ; Finally restore DS = SS
    MOV DI, SP
    JMP drawplanes_loop

    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
update_l1_cache_from_l2:
    ; NOTE: _lastflatcacheindicesused is right after _currentflatpage
    ; so DI will point to it if this branch is taken
    XCHG AX, BP
    ; ES = DS = SS = FIXED_DS_SEGMENT
IF COMPISA GE COMPILE_386
    MOV EBX, DS:[DI]
    ROL EBX, 8
    MOV DS:[DI], EBX
ELSE
    MOV BH, DS:[DI]
    MOV CX, DS:[DI + 1]
    MOV BL, DS:[DI + 3]
    MOV DS:[DI], BX
    MOV DS:[DI + 2], CX
ENDIF
    CBW
    MOV BH, AH ; AH should be 0
    MOV DS:[BX + DI - 4], AL
    MOV CL, BL
IF PAGE_SWAP_ARG_MULT EQ 1
    FAST_SHL1 BL
ELSE
    SHIFT_MACRO SHL BL 2
ENDIF
IFDEF COMP_CH
    ADD AX, FIRST_FLAT_CACHE_LOGICAL_PAGE + EMS_MEMORY_PAGE_OFFSET
ELSE
    ADD AX, FIRST_FLAT_CACHE_LOGICAL_PAGE
ENDIF
    MOV DS:[BX + _pageswapargs + (pageswapargs_flatcache_offset * 2)], AX
    MOV BL, CL
    MOV DI, SI
    
    Z_QUICKMAPAI4 pageswapargs_flatcache_offset_size INDEXED_PAGE_7000_OFFSET
    
    MOV SI, DI
    MOV CL, BL
    XCHG AX, BP
    JMP l1_cache_finished_updating
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
flatcachemruL2:
    MOV BP, SI
    MOV ES, CX
    MOV SI, OFFSET _flatcache_nodes
    
    ; prev = nodelist[index].prev
    ; next = nodelist[index].next
    MOV BL, AL
    FAST_SHL1 BL
    MOV DX, DS:[BX + SI]
    
    MOV DI, _flatcache_l2_head
    
    MOV CX, DS:[DI] ; CL = head, CH = tail
    ; flatcache_l2_head = index
    MOV DS:[DI], AL ; NOTE: Can't STOSB, CL in ES
    
    ; if (index == flatcache_l2_tail) {
    ;    flatcache_l2_tail = next
    ; } else {
    ;     nodelist[prev].next = next
    ; }
    CMP AL, CH
    ; nodelist[index].prev = flatcache_l2_head
    ; nodelist[index].next = -1
    MOV CH, 0xFF
    MOV DS:[BX + SI], CX
    JE index_is_tail
    MOV BL, DL
    FAST_SHL1 BL
    LEA DI, [BX + SI]
index_is_tail:
    MOV DS:[DI + 1], DH
    
    ; nodelist[next].prev = prev
    MOV BL, DH
    FAST_SHL1 BL
    MOV DS:[BX + SI], DL
    
    ; nodelist[flatcache_l2_head].next = index
    MOV BL, CL
    FAST_SHL1 BL
    MOV DS:[BX + SI + 1], AL
    MOV CX, ES
    MOV SI, BP
    JMP done_with_mruL2
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
flat_is_unloaded:
    MOV DI, CX
    
    MOV BL, AH
IF COMPISA LE COMPILE_286
    MOV BL, DS:[BX + _MULT_4096] ; NOTE: table is half size
    XCHG BL, BH
ELSE
    SHL BX, 12
ENDIF
    XCHG AX, BP
    
    MOV DX, FLATTRANSLATION_SEGMENT
    MOV ES, DX
    
SELFMODIFY_SPAN_lookuppicnum:
    MOV AL, ES:[0x00FF]
    XOR AH, AH ; NOTE: Can this be CBW?
    ADD AX, DS:[_firstflat]
    
    CALL FAR DWORD DS:[_W_CacheLumpNumDirect_addr]
    
    LEA CX, [BP + DI]
    JMP flat_not_unloaded
    
ENDP
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
generate_distance_steps:

IF (COMPISA EQ COMPILE_8086) OR (COMPISA GE COMPILE_386)
    MOV DS:[SI], AX ; Handled by XCHG for 186/286
ENDIF
IF COMPISA LE COMPILE_286
    ; fastmul1632 with 13:3 value
    MOV CX, AX
    MUL WORD DS:[BX + SI + 2 + ((YSLOPE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    XCHG AX, CX
    MUL WORD DS:[BX + SI + ((YSLOPE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    ADD DX, CX
    
    ; NOW lets shift, avoiding a fixedmul.
    SHIFT32_MACRO_RIGHT DX AX 3
    
    MOV DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    MOV DS:[BX + SI + 2 + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], DX
    
    MOV DI, AX
    MOV ES, DX
    
SELFMODIFY_SPAN_baseyscale_lo_1:
    MOV BP, 0x1000
SELFMODIFY_SPAN_baseyscale_hi_1:
    MOV CX, 0x1000
    
    ; ds_ystep = cachedystep[y] = R_FixedMulLocal(distance, baseyscale)
    CALL R_FixedMulLocal24_
    
    ; Convert to 6.10
    SHL AX, 1
    RCL DX, 1
    SHL AX, 1
    RCL DX, 1
    MOV AL, AH
    MOV AH, DL
    
    MOV DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    
    MOV CS:[SELFMODIFY_SPAN_ds_ystep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
SELFMODIFY_SPAN_basexscale_lo_1:
    MOV BP, 0x1000
SELFMODIFY_SPAN_basexscale_hi_1:
    MOV CX, 0x1000
    
    MOV AX, DI
    MOV DX, ES
    
    ; ds_xstep = cachedxstep[y] = R_FixedMulLocal(distance, basexscale)
    CALL R_FixedMulLocal24_
    
    ; Convert to 6.10
    SHL AX, 1
    RCL DX, 1
    SHL AX, 1
    RCL DX, 1
    MOV AL, AH
    MOV AH, DL
    
    MOV DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    
    MOV CS:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
ELSE
    MOVZX EDI, AX
    IMUL EDI, DS:[BX + SI + ((YSLOPE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    SHR EDI, 3
    MOV DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], EDI
SELFMODIFY_SPAN_baseyscale_full_1:
    MOV EAX, 0x10000000
    IMUL EDI
    SHRD EAX, EDX, 22 ; Convert to 6.10
    MOV DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    MOV CS:[SELFMODIFY_SPAN_ds_ystep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
SELFMODIFY_SPAN_basexscale_full_1:
    MOV EAX, 0x10000000
    IMUL EDI
    SHRD EAX, EDX, 22 ; Convert to 6.10
    MOV DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    MOV CS:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
ENDIF
    JMP distance_steps_ready
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
PROC R_MapPlanes24_ NEAR

; ARGS
; BP = SPANSTART_SEGMENT
; SI = y

; NORMAL STACK (negatives are pushed temps)
; SP - 2 = y << 1
; SP + 0 = Return addr
; SP + 2 = loop_count

; PRESERVE
; SS = FIXED_DS_SEGMENT
; BP = SPANSTART_SEGMENT

local_loop_count = 2
map_planes_args_size = 2

; LOOKUP SEGMENT ORDER:

; SPANSTART_SEGMENT
; CACHEDHEIGHT_SEGMENT
; YSLOPE_SEGMENT
; CACHEDDISTANCE_SEGMENT
; CACHEDXSTEP_SEGMENT
; CACHEDYSTEP_SEGMENT
; DISTSCALE_SEGMENT
; DC_YL_LOOKUP_SEGMENT

    FAST_SHL1 SI ; Initial << 1
ALIGN_MACRO
map_planes_loop: ; LOOP DEPTH: 3
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; BP = SPANSTART_SEGMENT
    ; SI = y << 1
    MOV DS, BP

SELFMODIFY_SPAN_plane_height:
    MOV AX, 0x1000
    MOV BX, SI ; Convert to DWORD index
IF (COMPISA EQ COMPILE_8086) OR (COMPISA GE COMPILE_386)
    CMP AX, DS:[SI + ((CACHEDHEIGHT_SEGMENT - SPANSTART_SEGMENT) * 16)]
ELSE
    MOV DX, AX
    XCHG DX, DS:[SI + ((CACHEDHEIGHT_SEGMENT - SPANSTART_SEGMENT) * 16)]
    CMP AX, DX
ENDIF
    JNE generate_distance_steps ; NOTE: This *should* be in range
    MOV AX, DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]
    MOV CS:[SELFMODIFY_SPAN_ds_ystep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    MOV AX, DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]
    MOV CS:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
IF COMPISA LE COMPILE_286
    LES DI, DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)]
distance_steps_ready:
    MOV DX, ES
SELFMODIFY_SPAN_fixedcolormap_2:
    MOV AL, MAXLIGHTZ - 1
SELFMODIFY_SPAN_fixedcolormap_1:
    CMP DX, (MAXLIGHTZ SHL 4)
    JAE colormap_index_set
    MOV AX, DX
    SHIFT_MACRO SHR AX 4
ELSE
    MOV EDI, DS:[SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)]
distance_steps_ready:
SELFMODIFY_SPAN_fixedcolormap_2:
    MOV AL, MAXLIGHTZ - 1
SELFMODIFY_SPAN_fixedcolormap_1:
    CMP EDI, (MAXLIGHTZ SHL 20)
    JAE colormap_index_set
    SHLD EAX, EDI, 16
ENDIF
colormap_index_set:
    LES BX, SS:[_planezlight]
    XLAT ES:[BX]
colormap_fixed:
    MOV CS:[SELFMODIFY_SPAN_set_colormap_index_jump - OFFSET R_SPAN24_STARTMARKER_], AL
    
    MOV BX, DS:[SI + ((DC_YL_LOOKUP_SEGMENT - SPANSTART_SEGMENT) * 16)] ; MULT_80
    
SELFMODIFY_SPAN_map_planes_dir_flag:
    CLD
    LODSW ; grab x1
    CLD
    
    ; SI is useless until the very end of the loop now
    ; since it could've indexed in either direction.
    ; TODO: Test if backwards indexing is even necessary,
    ; it'd be nice to only read DC_YL_LOOKUP_SEGMENT later
    PUSH SI
    
IF COMPISA LE COMPILE_286
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = SPANSTART_SEGMENT
    ; AX = x1
    ; DX = distance_high
    ; BX = y * 80
    ; DI = distance_low
ELSE
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = SPANSTART_SEGMENT
    ; AX = x1
    ; BX = y * 80
    ; EDI = distance
ENDIF
    
    MOV SI, AX
    SHIFT_MACRO SHR SI 2
SELFMODIFY_SPAN_destview_1:
    LEA BX, [BX + SI + 0x1000]
    MOV CS:[SELFMODIFY_SPAN_write_ahead_start_pixel+1 - OFFSET R_SPAN24_STARTMARKER_], BX
    
SELFMODIFY_SPAN_write_ahead_x2:
    MOV SI, 0x1000
    SUB SI, AX
    ; SI should have the number pixels to render. Figure out what to do with this...
    
IF COMPISA LE COMPILE_286
    XCHG AX, DI
ELSE
    XCHG EAX, EDI
ENDIF
    FAST_SHL1 DI ; Convert to WORD index
    LES BX, SS:[_viewangle_shiftright3]
    ADD BX, ES:[DI] ; BX is unmodded fine angle.. DI is a word lookup
    FAST_SHL1 DI ; Convert to DWORD index
IF COMPISA LE COMPILE_286
    LES BP, DS:[DI + ((DISTSCALE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    MOV CX, ES
    AND BH, 0x1F ; MOD_FINE_ANGLE mod high bits
    MOV DI, BX
    CALL R_FixedMulLocal24_
    
    ; TODO: sine/cosine combo func
    ; ARGS:
    ; DI = angle
    ; ??? = length
    ; RETURN:
    ; DX:AX = cosine
    ; CX:BX = sine
    
SELFMODIFY_SPAN_viewx_lo_1:
    ADD AX, 0x1000
SELFMODIFY_SPAN_viewx_hi_1:
    ADC DX, 0x1000
    
    ; Convert to 6.10
    SHL AX, 1
    RCL DX, 1
    SHL AX, 1
    RCL DX, 1
    MOV AL, AH
    MOV AH, DL

    MOV CS:[SELFMODIFY_SPAN_ds_xfrac+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
SELFMODIFY_SPAN_viewy_lo_1:
    ADD BX, 0x1000
SELFMODIFY_SPAN_viewy_hi_1:
    ADC CX, 0x1000
    NEG CX
    NEG BX
    SBB CX, 0
    
    ; Convert to 6.10
    SHL BX, 1
    RCL CX, 1
    SHL BX, 1
    RCL CX, 1
    MOV AL, BH
    MOV AH, CL
    
    MOV CS:[SELFMODIFY_SPAN_ds_yfrac+1 - OFFSET R_SPAN24_STARTMARKER_], AX
ELSE
    ; FixedMul
    IMUL DWORD DS:[DI + ((DISTSCALE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    SHRD EAX, EDX, 16
    XCHG EAX, EDI
    MOV DX, FINESINE_SEGMENT
    MOV ES, DX
    SHL BX, 3 ; omit the initial AND of MOD_FINE_ANGLE
    MOVSX EAX, BX
    ADD AH, (HALF_PI SHL 3) SHR 8
    SHR BX, 2
    MOV CX, ES:[BX]
    XCHG AX, CX
    IMUL EDI ; FixedMul
    SHRD EAX, EDX, 16
SELFMODIFY_SPAN_viewy_full_1:
    ADD EAX, 0x10000000
    NEG EAX
    SHR EAX, 6 ; Convert to 6.10
    ;MOV CS:[SELFMODIFY_SPAN_ds_yfrac+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    XCHG AX, CX
    CWDE
    MOV AX, ES:[BX + (HALF_PI SHL 1)]
    IMUL EDI ; FixedMul
    SHRD EAX, EDX, 16
SELFMODIFY_SPAN_viewx_full_1:
    ADD EAX, 0x10000000
    SHR EAX, 6 ; Convert to 6.10
    ;MOV CS:[SELFMODIFY_SPAN_ds_xfrac+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    ; NOTE: Made up notation, HCX is the upper 16 bits of ECX
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = source segment
    ; ES = dest segment
    ; FS = colormap segment
    ; EAX = 4 byte array of VGA plane masks
    ; CL = 6
    ; CH = i (1,2,4 depending on quality)
    ; HCX = ystep (YYYYYYyy yyyyyyyy)
    ; DX = yfrac (YYYYYYyy yyyyyyyy)
    ; HDX = xfrac (XXXXXXxx xxxxxxxx)
    ; BX = yfrac_iter (YYYYYYyy yyyyyy__)
    ; HBX = xfrac_iter (XXXXXXxx xxxxxx__)
    ; HSP = dest_start
    ; BP = ystep * 4 (YYYYyyyy yyyyyy00)
    ; HBP = xstep * 4 (XXXXxxxx xxxxxx00)
    ; DI = dest_iter
    ; HDI = xstep (XXXXXXxx xxxxxxxx)
    
SELFMODIFY_SPAN_quality_data:
    MOV CX, 0xFF06
    
    ; DI = xstep (XXXXXXxx xxxxxxxx)
    ; HDI = ystep (YYYYYYyy yyyyyyyy)
SELFMODIFY_SPAN_step_values:
    MOV EDI, 0xFFFFFFFF
    
    
ENDIF

    ; WARNING: Rest of logic is very unfinished, needs to incorporate the pixel draw loop.
    ; A lot of the above logic will need to be changed to set it up properly, including
    ; self modify sequences.
    
    ; TODO: Transition into the actual pixel loop logic.
    ; Does this even need the step/frac values to be self-modified
    ; forwards anymore? Register pressure feels kinda low
    
SELFMODIFY_SPAN_write_ahead_start_pixel:
    MOV DI, 0x1000
    
    
    
IF COMPISA LE COMPILE_286

    ; Register state (all not listed are junk/scratch):
    ; SS = colormap segment
    ; DS = source segment
    ; ES = dest segment
    ; AH = 0x3F
    ; CX = yfrac 00YYYYYY yyyyyyyy
    ; DX = xfrac XXXXXXxx xxxxxx00
    ; SP = xstep * 4 (plane iter)
    ; BP = ystep * 4 (plane iter)
    ; DI = dest

BYTES_PER_PIXEL = 20
DRAW_SINGLE_SPAN_PIXEL MACRO
    MOV BH, CH
    MOV BL, DH
    SHR BX, 1
    SHR BX, 1
    MOV AL, DS:[BX]
    MOV SI, AX
    MOVSB ES:[DI], SS:[SI]
    ADD DX, SP ; DX = XXXXXXxx xxxxxx00
    ADD CX, BP ; CX = 00YYYYYY yyyyyyyy
    AND CH, AH
ENDM

ALIGN_MACRO
REPT 79
    DRAW_SINGLE_SPAN_PIXEL
ENDM
    MOV BH, CH
    MOV BL, DH
    SHR BX, 1
    SHR BX, 1
    MOV AL, DS:[BX]
    MOV SI, AX
    MOVSB ES:[DI], SS:[SI]

SELFMODIFY_SPAN_plane_iter_addr:
    MOV BX, 0x1000
    MOV AL, CS:[BX]
    DEC AL
    JZ break_plane_loop
    XOR DI, DI
SELFMODIFY_SPAN_di_offset:
    CMP AL, 0
SELFMODIFY_SPAN_reset_di:
    ADC DI, 0x1000
start_plane_loop:
    MOV CS:[BX], AL ; write back to plane_iter
SELFMODIFY_SPAN_extra_pixel_cmp:
    CMP AL, 0
    XLAT CS:[BX] ; get VGA plane mask for iter
    MOV BX, DX
    MOV DX, SC_DATA
    OUT DX, AL
    MOV DX, BX
    MOV BX, SI
    SBB SI, SI
    AND SI, BYTES_PER_PIXEL ; Can't overflow past 80 because of earlier math
SELFMODIFY_SPAN_pixel_jump_target:
    ADD SI, 0x1000
    JMP SI

ELSE

    ; WARNING: This was written before I realized
    ; 16 bit SHLD/SHRD with counts >16 were bad.
    ; It will need to be updated, but I'm leaving
    ; it here for now because it had some good ideas
    ; that can be reused.

    ; NOTE: Made up notation, HCX is the upper 16 bits of ECX
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = source segment
    ; ES = dest segment
    ; FS = colormap segment
    ; EAX = 4 byte array of VGA plane masks
    ; CL = 6
    ; CH = i (1,2,4 depending on quality)
    ; HCX = ystep (YYYYYYyy yyyyyyyy)
    ; DX = yfrac (YYYYYYyy yyyyyyyy)
    ; HDX = xfrac (XXXXXXxx xxxxxxxx)
    ; BX = yfrac_iter (YYYYYYyy yyyyyy__)
    ; HBX = xfrac_iter (XXXXXXxx xxxxxx__)
    ; HSP = dest_start
    ; BP = ystep * 4 (YYYYyyyy yyyyyy00)
    ; HBP = xstep * 4 (XXXXxxxx xxxxxx00)
    ; DI = dest_iter
    ; HDI = xstep (XXXXXXxx xxxxxxxx)

BYTES_PER_PIXEL = 16
DRAW_SINGLE_SPAN_PIXEL MACRO
    SHRD SI, BX, 26         ; SI = 00000000 00YYYYYY
    SHLD ESI, EBX, CL       ; SI = 0000YYYY YYXXXXXX
    MOVZX SI, BYTE DS:[SI]
    MOVSB ES:[DI], FS:[SI]
    ADD EBX, EBP            ; EBX = XXXXXXxx xxxxxx__ YYYYYYyy yyyyyy__
ENDM

ALIGN_MACRO
REPT 79
    DRAW_SINGLE_SPAN_PIXEL
ENDM
    SHRD SI, BX, 26
    SHLD ESI, EBX, CL
    MOVZX SI, BYTE DS:[SI]
    MOVSB ES:[DI], FS:[SI]
    
    DEC CH ; while (--i)
    JZ break_plane_loop
    
    ; frac_iter = (frac += step)
    SHLD ESI, ECX, 16 ; SI = HCX
    MOV DI, SI ; EDI = HDI:HCX
    LEA EBX, [EDI + EDX]
    
    ; dest_iter = dest_start + offset_for_plane
    SHLD ESI, ESP, 16 ; SI = HSP
    XOR DI, DI
SELFMODIFY_SPAN_di_offset:
    CMP CH, 0xFF
    ADC DI, SI ; DI = HSP + carry
    
    ; SC_DATA = plane_mask[i]
    SHR EAX, 8
start_plane_loop: ; LOOP START
    MOV DX, SC_DATA
    OUT DX, AL
    MOV EDX, EBX ; EDX does not need to be set on entry
SELFMODIFY_SPAN_extra_pixel_cmp:
    CMP CH, 0xFF
    SBB SI, SI
    AND SI, BYTES_PER_PIXEL ; Can't overflow past 80 because of earlier math
SELFMODIFY_SPAN_pixel_jump_target:
    ADD SI, 0x1000
    JMP SI
    
ENDIF
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
break_plane_loop:
IF COMPISA LE COMPILE_286
    MOV AX, FIXED_DS_SEGMENT
    MOV SS, AX
SELFMODIFY_SPAN_write_ahead_sp:
    MOV SP, 0x1000
    STI
ENDIF

    POP SI ; Retrieve SI for next iter
    
    MOV BP, SP
    DEC BYTE SS:[BP + local_loop_count]
    MOV BP, SPANSTART_SEGMENT
IF COMPISA LE COMPILE_286
    JZ SHORT break_map_planes
    JMP LONG map_planes_loop
    
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO
break_map_planes:
ELSE
    JNZ LONG map_planes_loop
ENDIF
    ; LOOP DEPTH: 2
    RET map_planes_args_size
ENDP

    ; ==================== HOLE HOLE HOLE ====================
    
IF COMPISA LE COMPILE_286
ALIGN_MACRO
PROC R_FixedMulLocal24_ NEAR
; ARGS
; DX:AX = Value1
; CX:BP = Value2

; PRESERVE
; ES
; DS
; SI
; DI
    MOV BX, DX
    PUSH AX
    MUL BP
    MOV CS:[_selfmodify_restore_dx+1], DX
    MOV AX, BX
    MUL CX
    XCHG AX, BX
    CWD
    AND DX, BP
    SUB BX, DX
    MUL BP
_selfmodify_restore_dx:
    ADD AX, 01000h
    ADC BX, DX
    XCHG AX, CX
    CWD
    POP BP
    AND DX, BP
    SUB BX, DX
    MUL BP
    ADD AX, CX
    ADC DX, BX
    RET
ENDP
ENDIF