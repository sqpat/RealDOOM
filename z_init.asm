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

INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

;=================================

EXTRN locallib_dos_getvect_:NEAR
EXTRN locallib_freadfromfar_:FAR
EXTRN I_Error_:FAR
EXTRN DEBUG_PRINT_NOARG_CS_:NEAR
EXTRN Z_QuickMapWADPageFrame_:FAR
EXTRN Z_QuickMapMusicPageFrame_:FAR
EXTRN Z_QuickMapSFXPageFrame_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapRender_:FAR
EXTRN Z_QuickMapRender4000_:FAR
EXTRN Z_QuickMapVisplanePage_:FAR
EXTRN Z_QuickMapIntermission_:FAR
EXTRN Z_QuickMapMenu_:FAR
EXTRN locallib_fread_nearsegment_:NEAR
EXTRN locallib_fseek_:NEAR
EXTRN locallib_fseekfromfar_:FAR
EXTRN locallib_fread_:NEAR
EXTRN Z_QuickMapRenderPlanes_:FAR
EXTRN Z_QuickMapPalette_:FAR
EXTRN Z_QuickMapMaskedExtraData_:FAR

EXTRN W_CacheLumpNumDirect_:FAR
EXTRN W_LumpLength_:FAR
EXTRN W_CacheLumpNameDirect_:FAR
EXTRN W_CacheLumpNumDirectFragment_:FAR
EXTRN W_GetNumForName_:FAR
EXTRN NetUpdate_:FAR
EXTRN locallib_fopen_nobuffering_:NEAR
EXTRN locallib_fopenfromfar_nobuffer_:FAR
EXTRN locallib_fclose_:NEAR
EXTRN locallib_fclosefromfar_:NEAR

EXTRN locallib_ftell_:NEAR
EXTRN getStringByIndex_:FAR
EXTRN I_Error_:FAR
EXTRN P_InitThinkers_:FAR
EXTRN ST_Start_:FAR
EXTRN Z_SetOverlay_:FAR
EXTRN Z_QuickMapMusicPageFrame_:FAR
EXTRN FixedMul_:FAR
EXTRN FixedMul2432_:FAR
EXTRN FixedDiv_:FAR
EXTRN FixedMulTrigNoShift_:FAR
EXTRN FastDiv32u16u_:FAR
EXTRN FixedDivWholeA_:FAR
EXTRN cht_CheckCheat_Far_:FAR
EXTRN FastDiv3216u_:FAR
EXTRN FixedMulTrigSpeedNoShift_:FAR
EXTRN FixedMulTrigSpeed_:FAR
EXTRN FixedMulTrig_:FAR
EXTRN R_PointToAngle2_16_:FAR
EXTRN R_PointToAngle2_:FAR
EXTRN R_SetViewSize_:FAR
EXTRN OutOfThinkers_:FAR
EXTRN S_InitSFXCache_:FAR
EXTRN I_Quit_:FAR
EXTRN I_WaitVBL_:FAR
EXTRN I_SetPalette_:FAR
EXTRN V_MarkRect_:FAR
EXTRN V_DrawPatchDirect_:FAR
EXTRN V_DrawPatch_:FAR
EXTRN V_DrawFullscreenPatch_:FAR
EXTRN SFX_PlayPatch_:FAR
EXTRN S_DecreaseRefCountFar_:FAR
EXTRN W_CheckNumForNameFar_:FAR

EXTRN CopyString13_:NEAR





SCAMP_PAGE_SELECT_REGISTER = 0E8h
SCAMP_PAGE_SET_REGISTER = 0EAh
SCAMP_PAGE_CHIPSET_SELECT_REGISTER = 0ECh
SCAMP_PAGE_CHIPSET_SET_REGISTER = 0EDh
HT18_PAGE_SELECT_REGISTER = 01EEh
HT18_PAGE_SET_REGISTER = 01ECh




.DATA




.CODE

EXTRN _SELFMODIFY_R_WRITEBACKVIEWCONSTANTSSPANCALL:DWORD
EXTRN _SELFMODIFY_R_WRITEBACKVIEWCONSTANTSMASKEDCALL:DWORD
EXTRN _SELFMODIFY_R_WRITEBACKVIEWCONSTANTS:DWORD

EXTRN _SELFMODIFY_R_RENDERPLAYERVIEW_CALL:DWORD
EXTRN _musdriverstartposition:DWORD
EXTRN _codestartposition:DWORD
EXTRN _codestartposition_END:BYTE


EXTRN _doomcode_filename:BYTE

PROC    Z_INIT_STARTMARKER_
PUBLIC  Z_INIT_STARTMARKER_
ENDP


_doomdata_bin_string:
db "DOOMDATA.BIN", 0
PUBLIC _doomdata_bin_string

str_two_dot:
db "."
str_dot:
db ".", 0


IFDEF COMP_CH

    ; todo test and copy to scat ht18 etc

    PROC    Z_GetEMSPageMap_ NEAR
    PUBLIC  Z_GetEMSPageMap_


    push    si
    push    di
    push    cx
    push    dx

	;currentpageframes[0] = 0xFF;
	;currentpageframes[1] = 0xFF;
	;currentpageframes[2] = 0xFF;
	;currentpageframes[3] = 0xFF;
    ; two word writes
    mov     word ptr ds:[_currentpageframes + 0], 0FFFFh
    mov     word ptr ds:[_currentpageframes + 2], 0FFFFh

	;for (i = 0; i <= ((numlumps-1) / LUMP_PER_EMS_PAGE); i++){
	;	Z_QuickMapWADPageFrame(i*LUMP_PER_EMS_PAGE);
	;	FAR_memcpy((byte __far *) MK_FP(WAD_PAGE_FRAME_PTR, 0), MK_FP(lumpinfoinitsegment,  i * 16384u), 16384u); // copy the wad lump stuff over. gross
	;}

    xor   si, si
    mov   ax, word ptr ds:[_numlumps]
    dec   ax   ; numlumps - 1
    ; divide by 1024.
    SHIFT_MACRO shr ax 10
    xchg   ax, dx   ; dl stores max. dh = i = 0 now.

    loop_next_wad_page_frame_copy:
    
    mov   ah, dh    ; i * 1024
    SHIFT_MACRO shl ah 2
    xor   al, al    ; i * 1024 = i*LUMP_PER_EMS_PAGE
    call  Z_QuickMapWADPageFrame_   

    mov   es, word ptr ds:[_WAD_PAGE_FRAME_PTR]
    xor   di, di
    mov   cx, (16384 / 2)

    mov   ax, LUMPINFOINITSEGMENT
    mov   ds, ax
    rep   movsw
    push  ss
    pop   ds

    inc   dh
    cmp   dh, dl
    jle   loop_next_wad_page_frame_copy

    xor ax, ax
	call  Z_QuickMapMusicPageFrame_
    xor ax, ax
	call  Z_QuickMapSFXPageFrame_
    xor ax, ax
	call  Z_QuickMapWADPageFrame_
	; todo music driver?

	call  Z_QuickMapPhysics_  ;  map default page map


    pop     dx
    pop     cx
    pop     di
    pop     si
    ret  

    ENDP


  IF COMP_CH EQ CHIPSET_SCAMP

    PROC    Z_InitEMS_ NEAR
    PUBLIC  Z_InitEMS_

    mov    word ptr ds:[_EMS_PAGE], 0D000h   ; TODO unhardcode
    mov    al, 000h
    out    0FBh, al  ;  dummy write configuration enable
	
    mov    al, 00Bh
    out    SCAMP_PAGE_CHIPSET_SELECT_REGISTER, al
    mov    al, 0C0h
    out    SCAMP_PAGE_CHIPSET_SET_REGISTER, al  ; enable EMS and backfill
	
    mov    al, 00Ch
    out    SCAMP_PAGE_CHIPSET_SELECT_REGISTER, al
    mov    al, 0F0h
    out    SCAMP_PAGE_CHIPSET_SET_REGISTER, al  ; enabled page D000 as page frame


    ;mov    al, 010h
    ;out    SCAMP_PAGE_CHIPSET_SELECT_REGISTER, al
    ;mov    al, 0FFh
    ;out    SCAMP_PAGE_CHIPSET_SET_REGISTER, al  ; enable page D000 UMBs

    ;mov    al, 011h
    ;out    SCAMP_PAGE_CHIPSET_SELECT_REGISTER, al
    ;mov    al, 0AFh
    ;out    SCAMP_PAGE_CHIPSET_SET_REGISTER, al  ; enable page E000 UMBs. F000 read only.

    ; set default pages
    loop_next_page_setup:
    mov     ax, 0Ch

    out    SCAMP_PAGE_SELECT_REGISTER, al
    add    al, 4
    out    SCAMP_PAGE_SET_REGISTER, ax  ; set default EMS pages for global stuff...
    sub    al, 3     ; undo plus 4, inc ax 1    
    cmp     al, 024h
    jl      loop_next_page_setup


    mov    al, 7
    out    SCAMP_PAGE_SELECT_REGISTER, al
    mov    ax, EMS_MEMORY_PAGE_OFFSET + BSP_CODE_PAGE
    out    SCAMP_PAGE_SET_REGISTER, ax  ; set default EMS page for bsp code?
    sub    al, 3     ; undo plus 4, inc ax 1    

    ret

    ENDP



  ELSEIF COMP_CH EQ CHIPSET_SCAT

    PROC    Z_InitEMS_ NEAR
    PUBLIC  Z_InitEMS_


    mov    word ptr ds:[_EMS_PAGE], 0D000h   ; TODO unhardcode
    ; todo configure
    ret
    ENDP


  ELSEIF COMP_CH EQ CHIPSET_HT18

    PROC    Z_InitEMS_ NEAR
    PUBLIC  Z_InitEMS_

    push   dx
    mov    word ptr ds:[_EMS_PAGE], 0D000h   ; TODO unhardcode

    ;   set d000 pages to working values
    mov    dx, HT18_PAGE_SELECT_REGISTER
    mov    al, 01Ch
    out    dx, al
    dec    dx
    dec    dx
    mov    al, 03Ch
    out    dx, al
    
    inc    dx
    inc    dx
    mov    al, 01Dh
    out    dx, al
    dec    dx
    dec    dx
    mov    al, 03Dh
    out    dx, al

    inc    dx
    inc    dx
    mov    al, 01Eh
    out    dx, al
    dec    dx
    dec    dx
    mov    al, 03Eh
    out    dx, al

    inc    dx
    inc    dx
    mov    al, 01Fh
    out    dx, al
    dec    dx
    dec    dx
    mov    al, 03Fh
    out    dx, al


    pop    dx
    ret
    ENDP


  ENDIF

ELSE   ; NO CHIPSET



str_checking_ems:
db  9, "Checking EMS...", 0

_EMM_DRIVER_NAME:
db "EMMXXXX0", 0

str_required_ems_pages:
db  "%i pages required, %i pages available at frame %x", 0Ah, 0

str_no_ems_driver:
db 0Ah, " ERROR: EMS Driver not installed!", 0

str_generic_ems_error:
db 0Ah, 0Ah, "EMS Error: Call %x Error %x", 0

str_ems_ver_low:
db 0Ah, "ERROR: EMS Driver version below 4.0!", 0

str_ems_page_count:
db 0Ah, "ERROR: minimum of %i EMS pages required", 0

str_ems_mappable_page_count:
db 0Ah, "Insufficient mappable pages! ", 0Ah, "28 pages required (24 conventional and 4 page frame pages)! Only %i found.", 0Ah, " EMS 4.0 conventional features unsupported", 0

str_page_9000_not_found:
db 0Ah, "Mappable page for segment 0x9000 NOT FOUND! EMS 4.0 conventional features unsupported?", 0Ah, 0

str_ems_successfully_initialized:
db "EMS Iniitaliation Successful!", 0Ah, 0


; todo increment error code in cx and return for error print when in asm?


    PROC   Z_CheckEMSDriverPresence_ NEAR


    push   cs
    pop    ds

    ; open file
    mov    ax, 03D00h
    mov    dx, OFFSET _EMM_DRIVER_NAME
    int    021h ; try to open EMMXXXX0 file
    xchg   ax, bx   ; bx stores handle
    mov    ax, 0
    jc     return_no_ems_driver_found  ; EMMXXXX0 file not found

    ; check device status
    mov    ax, 04400h
    ; bx already set
    int    021h   ; check driver device status
    mov    ax, 0
    jc     return_no_ems_driver_found  ; error checking status?

    test    dl, 080h  ; confirm its a character device (does block ems device even exist)
    je      return_no_ems_driver_found

    ; check io
    mov    ax, 04407h
    ; bx already set
    int    021h ; check driver output status readiness
    jc     return_no_ems_driver_found  ; 
    test   al, al
    je     return_no_ems_driver_found

    ; close file
    mov    ah, 03Eh
    ; bx already set
    int    021h ; close EMMXXXX0 file


    push   ss
    pop    ds

    ret
    ENDP

    return_no_ems_driver_found:
    

    return_ems_driver_found:
    push   ss
    pop    ds
    mov    ax, OFFSET str_no_ems_driver
    push   cs
    push   ax
    call   I_Error_
    




    handle_ems_error_version_low:
    mov    ax, OFFSET str_ems_ver_low
    jmp    print_ems_error

    handle_ems_error_page_count:
    mov    ax, NUM_EMS4_SWAP_PAGES
    push   ax
    mov    ax, OFFSET str_ems_page_count
    jmp    print_ems_error


    handle_ems_error:
    mov    al, ah
    xor    ah, ah
    push   ax  ; error number
    push   cx  ; call number
    mov    ax, OFFSET str_generic_ems_error
    print_ems_error:
    push   cs
    push   ax
    call   I_Error_



    PROC    Z_InitEMS_ NEAR
    PUBLIC  Z_InitEMS_

    push    dx
    push    cx
    push    bx

    mov     ax, OFFSET str_checking_ems
    call    DEBUG_PRINT_NOARG_CS_
    call    Z_CheckEMSDriverPresence_

    ; Get EMS Memory Manager Status
    mov     ax, 04000h
    mov     cx, ax
    int     067h
    or      ah, ah
    jnz     handle_ems_error

    ; Check Version
    mov     ax, 04600h
    mov     cx, ax
    int     067h
    or      ah, ah
    jnz     handle_ems_error
    cmp     al, 040h
    jl      handle_ems_error_version_low

    ; Get Page Frame Address
    mov     ax, 04100h
    mov     cx, ax
    int     067h
    or      ah, ah
    jnz     handle_ems_error
    mov     word ptr ds:[_EMS_PAGE], bx  ; bx has ems page register

    ; TODO PRINT THIS
    ;mov     ax, OFFSET str_required_ems_pages
    ;call    DEBUG_PRINT_NOARG_CS_


    ; Get Unallocated Page Count
    mov     ax, 04200h
    mov     cx, ax
    int     067h
    or      ah, ah
    jnz     handle_ems_error
    cmp     bx, NUM_EMS4_SWAP_PAGES
    jl      handle_ems_error_page_count


    ; Allocate pages
    mov     ax, 04300h
    mov     cx, ax
    mov     bx, NUM_EMS4_SWAP_PAGES
    int     067h
    or      ah, ah
    jnz     handle_ems_error
    mov     word ptr ds:[_emshandle], dx

    ; page default page frame locations
        ; Allocate pages
    mov     ax, 04400h
    ;mov     dx, word ptr ds:[_emshandle]   ; already set above
    mov     bx, MUS_DATA_PAGES
    int     067h

    mov     ax, 04401h
    mov     dx, word ptr ds:[_emshandle]
    mov     bx, SFX_DATA_PAGES
    int     067h

    mov     ax, 04402h
    mov     dx, word ptr ds:[_emshandle]
    mov     bx, FIRST_LUMPINFO_LOGICAL_PAGE
    int     067h

    mov     ax, 04403h
    mov     dx, word ptr ds:[_emshandle]
    mov     bx, BSP_CODE_PAGE
    int     067h

	;currentpageframes[0] = 0;
	;currentpageframes[1] = NUM_MUSIC_PAGES;
	;currentpageframes[2] = NUM_MUSIC_PAGES+1;	// todo
	;currentpageframes[3] = NUM_MUSIC_PAGES+NUM_SFX_PAGES;

    ; two word writes
    mov     word ptr ds:[_currentpageframes], (NUM_MUSIC_PAGES SHL 8) + 00
    mov     word ptr ds:[_currentpageframes + 2], ((NUM_MUSIC_PAGES+NUM_SFX_PAGES) SHL 8) + (NUM_MUSIC_PAGES+1)


    mov     ax, OFFSET str_ems_successfully_initialized
    call    DEBUG_PRINT_NOARG_CS_


    
    pop    bx
    pop    cx
    pop    dx
    
    ret
    ENDP


    do_5801_error:
    mov    cx, 05801h
    jmp    handle_ems_error
    do_5800_error:
    mov    cx, 05800h
    jmp    handle_ems_error

    insufficient_page_count:
    mov    ax, OFFSET str_ems_mappable_page_count
    push   cx
    jmp    print_ems_error

    PROC    Z_GetEMSPageMap_ NEAR
    PUBLIC  Z_GetEMSPageMap_


    PUSHA_NO_AX_OR_BP_MACRO
    push    bp
    mov     bp, sp
    sub     sp, 256


    mov     ax, 05801h
    int     067h

    cmp     cx, 28  ; minimum number of pages necessary
    jl      insufficient_page_count
    or      ah, ah
    jnz     do_5801_error

    mov     ax, 05800h
    push    ss
    pop     es
    mov     di, sp  ; mappable_phys_page = es:di
    int     067h

    or      ah, ah
    jnz     do_5800_error

    mov     si, sp
    
    mov     ax, 09000h   ; find the 09000h page


    ; complicated to repne scasw because its a list of pairs...

    check_next_mappable_page:
    cmp     ds:[si], ax
    je      found_9000_page
    add     si, 4
    loop    check_next_mappable_page

    ; fall thru = error
    mov    ax, OFFSET str_page_9000_not_found
    jmp    print_ems_error

    
    found_9000_page:
    mov     ax, word ptr ds:[si + 2]
    mov     word ptr ds:[_pagenum9000], ax       ; pagedata[(i << 1) + 1]
    inc     byte ptr ds:[_emsconventional]   ; mappable conventional okay.

	;for (i = 1; i < total_pages; i+= 2) {
	;	pageswapargs[i] += pagenum9000;
	;}
    
    mov     si, OFFSET _pageswapargs + 2
    mov     cx, (TOTAL_PAGES / 2)

    increment_next_pageswaparg:
    add     ds:[si], ax
    add     si, 4
    loop    increment_next_pageswaparg



	;for (i = 0; i <= ((numlumps-1) / LUMP_PER_EMS_PAGE); i++){
	;	Z_QuickMapWADPageFrame(i*LUMP_PER_EMS_PAGE);
	;	FAR_memcpy((byte __far *) MK_FP(WAD_PAGE_FRAME_PTR, 0), MK_FP(lumpinfoinitsegment,  i * 16384u), 16384u); // copy the wad lump stuff over. gross
	;}

    xor   si, si
    mov   ax, word ptr ds:[_numlumps]
    dec   ax   ; numlumps - 1
    ; divide by 1024.
    SHIFT_MACRO shr ax 10

    xchg   ax, dx   ; dl stores max. dh = i = 0 now.
    
    loop_next_wad_page_frame_copy:
    
    mov   ah, dh    ; i * 1024
    SHIFT_MACRO shl ah 2
    xor   al, al    ; i * 1024 = i*LUMP_PER_EMS_PAGE
    call  Z_QuickMapWADPageFrame_   

    mov   es, word ptr ds:[_WAD_PAGE_FRAME_PTR]
    xor   di, di
    mov   cx, (16384 / 2)

    mov   ax, LUMPINFOINITSEGMENT
    mov   ds, ax
    rep   movsw
    push  ss
    pop   ds

    inc   dh
    cmp   dh, dl
    jle   loop_next_wad_page_frame_copy

	call  Z_QuickMapPhysics_  ;  map default page map

    LEAVE_MACRO
    POPA_NO_AX_OR_BP_MACRO
    ret  

    ENDP

ENDIF

;void  __near ReadFileRegionWithIndex(FILE* fp, int16_t index, uint32_t target_addr){


PROC    Z_ReadFileRegionWithIndex_ NEAR
PUBLIC  Z_ReadFileRegionWithIndex_

; ax = fp
; dx = index
; cx:bx = target_addr


push  si
push  di
push  bp
mov   bp, sp
push  cx      ; bp - 2
push  bx      ; bp - 4
push  bx      ; codesize ptr (sp = bp - 6)
mov   si, dx  ; index
mov   di, ax  ; fp

do_next_index:


;   fread(&codesize, 2, 1, fp);
mov    ax, sp  ; bp - 6
mov    bx, 1 * 2 ; read 2 bytes
mov    cx, di  ; fp
call   locallib_fread_nearsegment_


test   si, 00FFh
jne    just_fseek
;	locallib_far_fread((byte __far*) target_addr, codesize, fp);
les    ax, dword ptr ss:[bp - 4]  ; target_addr
mov    dx, es   
mov    bx, word ptr ss:[bp - 6]  ; codesize
mov    cx, di   ; fp
call   locallib_fread_

jmp    continue_readfile_loop

just_fseek:


;    fseek(fp, codesize, SEEK_CUR);
mov    ax, di   ; fp
mov    bx, word ptr ss:[bp - 6]
xor    cx, cx
mov    dx, 1    ; SEEK_CUR

call   locallib_fseek_



continue_readfile_loop:
sub   si, 0101h     ;   index -= 0x101;
jge   do_next_index

LEAVE_MACRO

pop   di
pop   si
ret    

ENDP


SPANFUNC_JUMP_LOOKUP_9000_SEGMENT =  SPANFUNC_JUMP_LOOKUP_SEGMENT - 09C00h + 09000h


PROC    Z_DoRenderCodeLoad_ NEAR
PUBLIC  Z_DoRenderCodeLoad_

PUSHA_NO_AX_OR_BP_MACRO

mov    di, ax   ; fp storage
mov    si, 0400h  ; usedcolumnvalue

	;int16_t usedcolumnvalue = 0x400;
	;int16_t usedspanvalue = 0x400;
	;int16_t usedskyvalue = 0x200;

	;if (columnquality <= 3) usedcolumnvalue += columnquality;		
mov    al, byte ptr ds:[_columnquality]
cmp    al, 3
ja     skip_col_quality
cbw
add    si, ax
skip_col_quality:

call   Z_RemapRenderFunctions_
mov    ax, di  ; fp
mov    dx, si  ; usedcolumnvalue
mov    cx, COLFUNC_JUMP_LOOKUP_6800_SEGMENT
xor    bx, bx
call   Z_ReadFileRegionWithIndex_  ; (fp, usedcolumnvalue, (uint32_t)colfunc_jump_lookup_6800);

call   Z_QuickMapPalette_

;if (spanquality <= 3) usedspanvalue += spanquality;

mov    dx, 0400h
mov    al, byte ptr ds:[_spanquality]
cmp    al, 3
ja     skip_span_quality
add    dl, al
skip_span_quality:
mov    ax, di  ; fp
mov    cx, SPANFUNC_JUMP_LOOKUP_9000_SEGMENT
xor    bx, bx

call   Z_ReadFileRegionWithIndex_   ; (fp, usedspanvalue, (uint32_t)spanfunc_jump_lookup_9000);

call   Z_QuickMapMaskedExtraData_


mov    ax, di  ; fp
mov    dx, si  ; usedcolumnvalue
mov    cx, DRAWFUZZCOL_AREA_SEGMENT
xor    bx, bx
call   Z_ReadFileRegionWithIndex_   ;(fp, usedcolumnvalue, (uint32_t)drawfuzzcol_area);
mov    ax, di  ; fp
mov    dx, si  ; usedcolumnvalue
mov    cx, MASKEDCONSTANTS_FUNCAREA_SEGMENT
xor    bx, bx
call   Z_ReadFileRegionWithIndex_   ;(fp, usedcolumnvalue, (uint32_t)maskedconstants_funcarea);

call   Z_QuickMapRenderPlanes_

	;if (skyquality <= 1) usedskyvalue += skyquality;
mov    dx, 0200h
mov    al, byte ptr ds:[_skyquality]
cmp    al, 1
ja     skip_sky_quality
add    dl, al
skip_sky_quality:
mov    ax, di  ; fp
mov    cx, DRAWSKYPLANE_AREA_SEGMENT
xor    bx, bx

call   Z_ReadFileRegionWithIndex_   ; (fp, usedskyvalue, (uint32_t)drawskyplane_area);


mov    ax, di  ; fp
mov    dx, si  ; usedcolumnvalue
mov    cx, word ptr ds:[_BSP_CODE_SEGMENT_PTR]
xor    bx, bx

call   Z_ReadFileRegionWithIndex_   ;(fp, usedcolumnvalue, (uint32_t)MK_FP(BSP_CODE_SEGMENT_PTR, 0));

	



POPA_NO_AX_OR_BP_MACRO
ret

ENDP


PROC    Z_RemapRenderFunctions_ NEAR

PUSHA_NO_AX_MACRO

mov     al, byte ptr ds:[_columnquality]
cmp     al, 3
je      col_qual_3
ja      col_qual_default
cmp     al, 1
je      col_qual_1
ja      col_qual_2

; todo turn into a data table in cs, save a few dozen bytes..

col_qual_0:
col_qual_default:
mov     ax, R_GETPATCHTEXTURE24OFFSET
mov     dx, R_GETCOMPOSITETEXTURE24OFFSET
mov     bx, R_WRITEBACKMASKEDFRAMECONSTANTS24OFFSET
mov     cx, R_DRAWMASKED24OFFSET
mov     si, R_RENDERPLAYERVIEW24OFFSET
mov     di, R_WRITEBACKVIEWCONSTANTSMASKED24OFFSET
mov     bp, R_WRITEBACKVIEWCONSTANTS24OFFSET

jmp     gotcolvars

col_qual_1:
mov     ax, R_GETPATCHTEXTURE16OFFSET
mov     dx, R_GETCOMPOSITETEXTURE16OFFSET
mov     bx, R_WRITEBACKMASKEDFRAMECONSTANTS16OFFSET
mov     cx, R_DRAWMASKED16OFFSET
mov     si, R_RENDERPLAYERVIEW16OFFSET
mov     di, R_WRITEBACKVIEWCONSTANTSMASKED16OFFSET
mov     bp, R_WRITEBACKVIEWCONSTANTS16OFFSET

jmp     gotcolvars

col_qual_2:
mov     ax, R_GETPATCHTEXTURE0OFFSET
mov     dx, R_GETCOMPOSITETEXTURE0OFFSET
mov     bx, R_WRITEBACKMASKEDFRAMECONSTANTS0OFFSET
mov     cx, R_DRAWMASKED0OFFSET
mov     si, R_RENDERPLAYERVIEW0OFFSET
mov     di, R_WRITEBACKVIEWCONSTANTSMASKED0OFFSET
mov     bp, R_WRITEBACKVIEWCONSTANTS0OFFSET

jmp     gotcolvars
col_qual_3:
mov     ax, R_GETPATCHTEXTUREFLOFFSET
mov     dx, R_GETCOMPOSITETEXTUREFLOFFSET
mov     bx, R_WRITEBACKMASKEDFRAMECONSTANTSFLOFFSET
mov     cx, R_DRAWMASKEDFLOFFSET
mov     si, R_RENDERPLAYERVIEWFLOFFSET
mov     di, R_WRITEBACKVIEWCONSTANTSMASKEDFLOFFSET
mov     bp, R_WRITEBACKVIEWCONSTANTSFLOFFSET

gotcolvars:
mov     word ptr ds:[_R_GetPatchTexture_addr], ax
mov     word ptr ds:[_R_GetCompositeTexture_addr], dx
mov     word ptr ds:[_R_WriteBackMaskedFrameConstantsCallOffset], bx
mov     word ptr ds:[_R_DrawMaskedCallOffset], cx
mov     word ptr cs:[_SELFMODIFY_R_RENDERPLAYERVIEW_CALL+0], si
mov     word ptr cs:[_SELFMODIFY_R_WRITEBACKVIEWCONSTANTSMASKEDCALL], di
mov     word ptr cs:[_SELFMODIFY_R_WRITEBACKVIEWCONSTANTS], bp

; this cant be hardcoded because _BSP_CODE_SEGMENT_PTR is dependent on the page frame value which is not known at build time.
mov     ax, word ptr ds:[_BSP_CODE_SEGMENT_PTR]
mov     word ptr ds:[_R_GetPatchTexture_addr + 2], ax
mov     word ptr ds:[_R_GetCompositeTexture_addr + 2], ax
mov     word ptr cs:[_SELFMODIFY_R_RENDERPLAYERVIEW_CALL+2], ax
mov     word ptr cs:[_SELFMODIFY_R_WRITEBACKVIEWCONSTANTS+2], ax

mov     al, byte ptr ds:[_skyquality]
cmp     al, 1
jne     dont_change_sky

mov     word ptr ds:[_R_DrawSkyPlane_addr_Offset], R_DRAWSKYPLANEFLOFFSET
mov     word ptr ds:[_R_DrawSkyPlaneDynamic_addr_Offset], R_DRAWSKYPLANEDYNAMICFLOFFSET

dont_change_sky:


mov     al, byte ptr ds:[_spanquality]
cmp     al, 3
je      span_qual_3
ja      span_qual_default
cmp     al, 1
je      span_qual_1
ja      span_qual_2
span_qual_0:
span_qual_default:
mov     ax, R_DRAWPLANES24OFFSET
mov     dx, R_WRITEBACKVIEWCONSTANTSSPAN24OFFSET
mov     bx, DRAWSPAN_AH_OFFSET

jmp     gotspanvars

span_qual_1:
mov     ax, R_DRAWPLANES16OFFSET
mov     dx, R_WRITEBACKVIEWCONSTANTSSPAN16OFFSET
mov     bx, DRAWSPAN_BX_OFFSET


jmp     gotspanvars

span_qual_2:
mov     ax, R_DRAWPLANES0OFFSET
mov     dx, R_WRITEBACKVIEWCONSTANTSSPAN0OFFSET
mov     bx, DRAWSPAN_AH_OFFSET

jmp     gotspanvars
span_qual_3:
mov     ax, R_DRAWPLANESFLOFFSET
mov     dx, R_WRITEBACKVIEWCONSTANTSSPANFLOFFSET
mov     bx, DRAWSPAN_AH_OFFSET

gotspanvars:
mov     word ptr ds:[_R_DrawPlanesCallOffset], ax
mov     word ptr cs:[_SELFMODIFY_R_WRITEBACKVIEWCONSTANTSSPANCALL], dx
mov     word ptr ds:[_ds_source_offset], bx



POPA_NO_AX_MACRO

ret
ENDP


_linkfunclist:
dw OFFSET _W_CacheLumpNumDirect_addr           , OFFSET W_CacheLumpNumDirect_
dw OFFSET _W_LumpLength_addr                   , OFFSET W_LumpLength_
dw OFFSET _W_CacheLumpNameDirect_addr          , OFFSET W_CacheLumpNameDirect_
dw OFFSET _W_CacheLumpNumDirectFragment_addr   , OFFSET W_CacheLumpNumDirectFragment_
dw OFFSET _W_GetNumForName_addr                , OFFSET W_GetNumForName_
dw OFFSET _NetUpdate_addr                      , OFFSET NetUpdate_
dw OFFSET _fopen_addr                          , OFFSET locallib_fopenfromfar_nobuffer_
dw OFFSET _fseek_addr                          , OFFSET locallib_fseekfromfar_
dw OFFSET _fread_addr                          , OFFSET locallib_freadfromfar_
dw OFFSET _fclose_addr                         , OFFSET locallib_fclosefromfar_
dw OFFSET _getStringByIndex_addr               , OFFSET getStringByIndex_
dw OFFSET _I_Error_addr                        , OFFSET I_Error_
dw OFFSET _P_InitThinkers_addr                 , OFFSET P_InitThinkers_
dw OFFSET _ST_Start_addr                       , OFFSET ST_Start_
dw OFFSET _Z_SetOverlay_addr                   , OFFSET Z_SetOverlay_
dw OFFSET _Z_QuickMapMusicPageFrame_addr       , OFFSET Z_QuickMapMusicPageFrame_
dw OFFSET _FixedMul_addr                       , OFFSET FixedMul_
dw OFFSET _FixedMul2432_addr                   , OFFSET FixedMul2432_
dw OFFSET _FixedDiv_addr                       , OFFSET FixedDiv_
dw OFFSET _FixedMulTrigNoShift_addr            , OFFSET FixedMulTrigNoShift_
dw OFFSET _FastDiv32u16u_addr                  , OFFSET FastDiv32u16u_
dw OFFSET _FixedDivWholeA_addr                 , OFFSET FixedDivWholeA_
dw OFFSET _cht_CheckCheat_Far_addr             , OFFSET cht_CheckCheat_Far_
dw OFFSET _FastDiv3216u_addr                   , OFFSET FastDiv3216u_
dw OFFSET _FixedMulTrigSpeedNoShift_addr       , OFFSET FixedMulTrigSpeedNoShift_
dw OFFSET _FixedMulTrigSpeed_addr              , OFFSET FixedMulTrigSpeed_
dw OFFSET _FixedMulTrig_addr                   , OFFSET FixedMulTrig_
dw OFFSET _R_PointToAngle2_16_addr             , OFFSET R_PointToAngle2_16_
dw OFFSET _R_PointToAngle2_addr                , OFFSET R_PointToAngle2_
dw OFFSET _R_SetViewSize_addr                  , OFFSET R_SetViewSize_
dw OFFSET _OutOfThinkers_addr                  , OFFSET OutOfThinkers_
dw OFFSET _S_InitSFXCache_addr                 , OFFSET S_InitSFXCache_
dw OFFSET _I_Quit_addr                         , OFFSET I_Quit_
dw OFFSET _I_WaitVBL_addr                      , OFFSET I_WaitVBL_
dw OFFSET _I_SetPalette_addr                   , OFFSET I_SetPalette_
dw OFFSET _V_MarkRect_addr                     , OFFSET V_MarkRect_
dw OFFSET _V_DrawPatchDirect_addr              , OFFSET V_DrawPatchDirect_
dw OFFSET _V_DrawPatch_addr                    , OFFSET V_DrawPatch_
dw OFFSET _V_DrawFullscreenPatch_addr          , OFFSET V_DrawFullscreenPatch_
dw OFFSET _SFX_PlayPatch_addr                  , OFFSET SFX_PlayPatch_
dw OFFSET _S_DecreaseRefCountFar_addr          , OFFSET S_DecreaseRefCountFar_
dw OFFSET _W_CheckNumForNameFar_addr           , OFFSET W_CheckNumForNameFar_

_linkfunclist_END:



PROC    GetCodeSize_   NEAR
;    fread(&codesize, 2, 1, fp);
; return result in bx for fread
; fp in si
push  ax
mov   ax, sp 
mov   bx, 1 * 2
mov   cx, si
call  locallib_fread_nearsegment_
pop   bx
ret


ENDP

_music_driver_lookup:
db MUS_DRIVER_TYPE_NONE
db MUS_DRIVER_TYPE_NONE
db MUS_DRIVER_TYPE_OPL2
db MUS_DRIVER_TYPE_OPL3
db MUS_DRIVER_TYPE_NONE
db MUS_DRIVER_TYPE_NONE
db MUS_DRIVER_TYPE_SBMIDI
db MUS_DRIVER_TYPE_MPU401
db MUS_DRIVER_TYPE_MPU401


PROC    Z_LoadBinaries_ NEAR
PUBLIC  Z_LoadBinaries_

PUSHA_NO_AX_MACRO



mov   ax, OFFSET _doomdata_bin_string

call  CopyString13_
mov   dl, (FILEFLAG_READ OR FILEFLAG_BINARY)
call  locallib_fopen_nobuffering_        ; fopen("DOOMDATA.BIN", "rb"); 
mov   di, ax ; di stores fp

;	fseek(fp, DATA_DOOMDATA_OFFSET, SEEK_SET);
xor   dx, dx ; SEEK_SET
mov   bx, DATA_DOOMDATA_OFFSET
xor   cx, cx
call  locallib_fseek_

;	locallib_far_fread(rndtable, 256, fp);
xor   ax, ax
mov   dx, RNDTABLE_SEGMENT
mov   bx, 256
mov   cx, di
call  locallib_fread_

; fread(mobjinfo, sizeof(mobjinfo_t), NUMMOBJTYPES, fp);
mov   ax, OFFSET _mobjinfo
mov   bx, (SIZE MOBJINFO_T) * NUMMOBJTYPES
mov   cx, di
call  locallib_fread_nearsegment_

mov     ax, OFFSET str_dot
call    DEBUG_PRINT_NOARG_CS_

;	locallib_far_fread(states, sizeof(state_t) * NUMSTATES, fp);
xor   ax, ax
mov   dx, word ptr ds:[_STATES_SEGMENT_PTR]
mov   bx, (SIZE STATE_T) * NUMSTATES
mov   cx, di
call  locallib_fread_

mov     ax, OFFSET str_dot
call    DEBUG_PRINT_NOARG_CS_

;	locallib_far_fread(gammatable, 5 * 256, fp);
xor   ax, ax
mov   dx, GAMMATABLE_SEGMENT
mov   bx, 5 * 256
mov   cx, di
call  locallib_fread_

mov     ax, OFFSET str_dot
call    DEBUG_PRINT_NOARG_CS_


;	locallib_far_fread(finesine, 4 * 10240u, fp);
xor   ax, ax
mov   dx, FINESINE_SEGMENT
mov   bx, 4 * 10240
mov   cx, di
call  locallib_fread_

mov     ax, OFFSET str_dot
call    DEBUG_PRINT_NOARG_CS_


call    Z_QuickMapRender_

;	locallib_far_fread(finetangentinner, 4 * 2048, fp);
xor   ax, ax
mov   dx, FINETANGENTINNER_SEGMENT
mov   bx, 4 * 2048
mov   cx, di
call  locallib_fread_


;	FAR_memset(visplanes_8400, 0x00,   0xC000);
mov   cx, 0C000h / 2
mov   ax, VISPLANES_8400_SEGMENT
mov   es, ax
xor   ax, ax
cwd
xchg  dx, di  ; store fp
rep   stosw
xchg  dx, di  ; put fp back

;	Z_QuickMapVisplanePage(3, 1);
;	Z_QuickMapVisplanePage(4, 2);
mov   ax, 3
mov   dx, 1
call  Z_QuickMapVisplanePage_
mov   ax, 4
mov   dx, 2
call  Z_QuickMapVisplanePage_

;	FAR_memset(visplanes_8800, 0x00,   0x8000);
mov   cx, 08000h / 2
mov   ax, VISPLANES_8800_SEGMENT
mov   es, ax
xor   ax, ax
cwd
xchg  dx, di  ; store fp
rep   stosw
xchg  dx, di  ; put fp back


mov     ax, OFFSET str_dot
call    DEBUG_PRINT_NOARG_CS_

call    Z_QuickMapPhysics_

;	locallib_far_fread(doomednum_far, 2 * NUMMOBJTYPES, fp);
xor   ax, ax
mov   dx, DOOMEDNUM_SEGMENT
mov   bx, 2 * NUMMOBJTYPES
mov   cx, di
call  locallib_fread_

call  Z_QuickMapRender4000_


;	for (i = 0; i < NUMSTATES; i++){
;		states_render[i].sprite = states[i].sprite;
;		states_render[i].frame  = states[i].frame;
;	}

xchg  dx, di  ; store fp
mov   ax, STATES_RENDER_SEGMENT
mov   es, ax
mov   ax, STATES_SEGMENT
mov   ds, ax
xor   si, si   ; sprite, frame are bytes 0, 1
mov   di, si   ; same for state_render
mov   cx, NUMSTATES


loop_copy_state_spriteframes:
movsw
add    si, (SIZE STATE_T) - 2
loop   loop_copy_state_spriteframes

xchg   dx, di  ; put fp back
push   ss
pop    ds

call   Z_QuickMapRender_

;	locallib_far_fread(zlight, 2048, fp);
xor   ax, ax
mov   dx, ZLIGHT_SEGMENT
mov   bx, 2048
mov   cx, di
call  locallib_fread_

xchg  ax, di
call  locallib_fclose_

call  Z_QuickMapPhysics_

mov   ax, OFFSET _doomcode_filename
call  CopyString13_
mov   dl, (FILEFLAG_READ OR FILEFLAG_BINARY)
call  locallib_fopen_nobuffering_        ; fopen("DOOMDATA.BIN", "rb"); 
mov   si, ax ; si stores fp
call  Z_DoRenderCodeLoad_

call  Z_QuickMapIntermission_

call  GetCodeSize_
;	locallib_far_fread(wianim_codespace, codesize, fp);
xor   ax, ax
mov   dx, WIANIM_CODESPACE_SEGMENT
mov   cx, si
call  locallib_fread_

call  Z_QuickMapPhysics_

call  GetCodeSize_
;    locallib_far_fread(psight_codespace, codesize, fp);
xor   ax, ax
mov   dx, PHYSICS_HIGHCODE_SEGMENT
mov   cx, si
call  locallib_fread_

call  Z_QuickMapMenu_

call  GetCodeSize_
;    locallib_far_fread(menu_code_area, codesize, fp);
xor   ax, ax
mov   dx, MENU_CODE_AREA_SEGMENT
mov   cx, si
call  locallib_fread_

call  Z_QuickMapPhysics_


mov   di, OFFSET _codestartposition

loop_write_next_codestart_position:

mov   ax, si
call  locallib_ftell_
push  cs
pop   es
stosw
xchg  ax, dx
stosw

cmp   di, OFFSET _codestartposition_END
jge   done_writing_codestart


call  GetCodeSize_
; bx is codesize
;	fseek(fp, codesize, SEEK_CUR);
mov   ax, si
mov   dx, 1  ; SEEK_CUR
xor   cx, cx
call  locallib_fseek_

jmp    loop_write_next_codestart_position
done_writing_codestart:

xor     ax, ax
mov     bx, ax
mov     bl, byte ptr ds:[_snd_DesiredMusicDevice]
cmp     bl, 8
ja      use_none
mov     al, byte ptr cs:[_music_driver_lookup + bx]


use_none:
dec     ax
xchg    ax, bp    ; bp holds driver index

;	for (i = 0; i < MUS_DRIVER_COUNT-1; i++){
;		fread(&codesize, 2, 1, fp);
;		fseek(fp, codesize, SEEK_CUR);
;		if (i == index){
;			musdriverstartposition  = ftell(fp);
;		}
;	}

xor   di, di   ; di holds i

loop_next_mus_driver:

call  GetCodeSize_
;	fseek(fp, codesize, SEEK_CUR);
mov   ax, si
mov   dx, 1  ; SEEK_CUR
xor   cx, cx
call  locallib_fseek_
cmp   di, bp
jne   iter_loop_next_mus_driver
mov   ax, si
call  locallib_ftell_
mov   word ptr cs:[_musdriverstartposition+0], ax
mov   word ptr cs:[_musdriverstartposition+2], dx

iter_loop_next_mus_driver:
inc     di
cmp     di, MUS_DRIVER_COUNT-1
jl      loop_next_mus_driver



xchg    ax, si
call    locallib_fclose_



mov     ax, OFFSET str_two_dot
call    DEBUG_PRINT_NOARG_CS_
;call    Z_LinkFunctions_
; inline

; manual runtime linking. these are all called from other segments in externalized code and need their addresses in constant variable locatioons

; set some function addresses for asm calls. 
; as these move to asm and EMS memory space themselves, these references can go away

push  ds
pop   es
mov   si, OFFSET _linkfunclist
loop_next_function:
lods  word ptr cs:[si]
xchg  ax, di
movs  word ptr es:[di], word ptr cs:[si]
mov   word ptr es:[di], cs          ; segment for far call
cmp   si, OFFSET _linkfunclist_END
jl    loop_next_function


; MainLogger_addr =  					(uint32_t)(MainLogger);



POPA_NO_AX_MACRO


ret

ENDP


PROC    Z_INIT_ENDMARKER_
PUBLIC  Z_INIT_ENDMARKER_
ENDP


END