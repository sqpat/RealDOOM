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
EXTRN I_Error_:FAR
EXTRN DEBUG_PRINT_NOARG_CS_:NEAR
EXTRN Z_QuickMapWADPageFrame_:FAR
EXTRN Z_QuickMapMusicPageFrame_:FAR
EXTRN Z_QuickMapSFXPageFrame_:FAR
EXTRN Z_QuickMapPhysics_:FAR

SCAMP_PAGE_SELECT_REGISTER = 0E8h
SCAMP_PAGE_SET_REGISTER = 0EAh
SCAMP_PAGE_CHIPSET_SELECT_REGISTER = 0ECh
SCAMP_PAGE_CHIPSET_SET_REGISTER = 0EDh
HT18_PAGE_SELECT_REGISTER = 01EEh
HT18_PAGE_SET_REGISTER = 01ECh




.DATA





.CODE



PROC    Z_INIT_STARTMARKER_
PUBLIC  Z_INIT_STARTMARKER_
ENDP



IFDEF COMP_CH



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
db  "%i pages required, %i pages available at frame %x", 020h, 0

str_no_ems_driver:
db 020h, " ERROR: EMS Driver not installed!", 0

str_generic_ems_error:
db 020h, 020h, "EMS Error: Call %x Error %x", 0

str_ems_ver_low:
db 020h, "ERROR: EMS Driver version below 4.0!", 0

str_ems_page_count:
db 020h, "ERROR: minimum of %i EMS pages required", 0

str_ems_mappable_page_count:
db 020h, "Insufficient mappable pages! ", 020h, "28 pages required (24 conventional and 4 page frame pages)! Only %i found.", 020h, " EMS 4.0 conventional features unsupported", 0

str_page_9000_not_found:
db 020h, "Mappable page for segment 0x9000 NOT FOUND! EMS 4.0 conventional features unsupported?", 020h, 0

; todo move to z_init asm
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





PROC    Z_INIT_ENDMARKER_
PUBLIC  Z_INIT_ENDMARKER_
ENDP


END