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


ENDIF





PROC    Z_INIT_ENDMARKER_
PUBLIC  Z_INIT_ENDMARKER_
ENDP


END