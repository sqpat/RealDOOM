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
INSTRUCTION_SET_MACRO_NO_MEDIUM

;=================================


SEGMENT R_COL24_TEXT USE16 PARA PUBLIC'CODE'
ASSUME  CS:R_COL24_TEXT
 
PROC R_COLUMN24_STARTMARKER_
PUBLIC R_COLUMN24_STARTMARKER_
ENDP 



;
; R_DrawColumn
;
	




ALIGN 16


MARKER_COLFUNC_NOLOOP_FUNCTION_AREA_OFFSET_:
PUBLIC MARKER_COLFUNC_NOLOOP_FUNCTION_AREA_OFFSET_

PROC    R_DrawColumn24NoLoop_ FAR
PUBLIC  R_DrawColumn24NoLoop_

    ; di contains screen coord
    ; ax contains dc_yl
    ; CL:SI = dc_texturemid
    ; CH:BX = dc_iscale

   mov     word ptr cs:[((COLFUNC_FUNCTION_AREA_SEGMENT - COLORMAPS_SEGMENT) SHL 4) +  MARKER_SM_COLFUNC_jump_offset24_noloop_+1], dx ; five bytes

   MOV  DX, AX  ; copy center24y
   MUL  CH
   ADD  CL, AL
   MOV  AX, DX ; restore center_y
   AND  DH, BL
   SUB  CL, DH  ; apply neg sign
   MUL  BX
   ADD  SI, AX
   ADC  CL, DL

   xchg bp, bx   ; bp gets lowstep, bx gets xlat lookup

   xor  dx, dx   ; dx gets 0
   xchg dl, ch   ; zero ch fo xchg into si. dx gets hi step
   dec  dx       ; minus one to account for lodsb
   xchg cx, si      


MARKER_SM_COLFUNC_set_destview_segment24_noloop_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment24_noloop_
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment

   ;  prep our loop variables
   
   cli 
   ;lds     ax, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and bp to 004Fh (hardcoded)

   mov     ss, sp
   mov     sp, 04Fh


MARKER_SM_COLFUNC_jump_offset24_noloop_:
PUBLIC MARKER_SM_COLFUNC_jump_offset24_noloop_

   jmp loop_done_noloop         ; relative jump to be modified before function is called
; currently EVEN
; 10 bytes each
ENSUREALIGN_201:

DRAW_SINGLE_PIXEL_NOLOOP MACRO 

    lods   BYTE PTR ds:[si]        
	xlat   BYTE PTR cs:[bx]        ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]        ;
	add    cx, bp                  ; add 16 low bits of precision
    adc    si, dx                  ; carry result into this add
	add    di, sp                  ; sp has 79 (0x4F) and stos added one
    
ENDM


REPT 199
    DRAW_SINGLE_PIXEL_NOLOOP
ENDM

; draw last pixel, cut off the add

    lods   BYTE PTR ds:[si]
	xlat   BYTE PTR cs:[bx]
	stos   BYTE PTR es:[di]

loop_done_noloop:
; clean up


; restore ds without going to memory.
    mov  sp, ss
    mov  ax, FIXED_DS_SEGMENT
    mov  ss, ax
    sti

    retf


ENDP

; NOTE r_mask cannot reach this function. it only maps one EMS page including colormaps instead of also the one after it.

ALIGN 16


MARKER_COLFUNC_NOLOOPANDSTRETCH_FUNCTION_AREA_OFFSET_:
PUBLIC MARKER_COLFUNC_NOLOOPANDSTRETCH_FUNCTION_AREA_OFFSET_

PROC    R_DrawColumn24NoLoopStretch_ FAR
PUBLIC  R_DrawColumn24NoLoopStretch_

    ; di contains screen coord
    ; ax contains dc_yl
    ; CL:SI = dc_texturemid
    ; 00:BX = dc_iscale
   
   mov   word ptr cs:[((COLFUNC_FUNCTION_AREA_SEGMENT - COLORMAPS_SEGMENT) SHL 4) + MARKER_SM_COLFUNC_jump_offset24_noloopandstretch_+1], dx ; five bytes


    ; ch is unset (garbage), but implied value 0. skip the mul ch step

   MOV  DX, AX  ; copy center24y
   
   AND  DH, BL
   SUB  CL, DH  ; apply neg sign
   MUL  BX
   ADD  SI, AX
   ADC  CL, DL


   xchg bx, bp   ; bx gets colormap offset, bp gets high step



   ;  prep our loop variables
   
   ;lds  dx, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and dx to 004Fh (hardcoded)
   mov  dx, 04Fh
   mov  ch, dh   ; ch gets 0
   xchg si, cx   ; si gets hi texel, cx gets low texel 


MARKER_SM_COLFUNC_set_destview_segment24_noloopandstretch_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment24_noloopandstretch_
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment

MARKER_SM_COLFUNC_jump_offset24_noloopandstretch_:
PUBLIC MARKER_SM_COLFUNC_jump_offset24_noloopandstretch_

   jmp loop_done_noloopandstretch         ; relative jump to be modified before function is called
; currently EVEN
; 10 bytes each
ENSUREALIGN_202:


; 10 bytes each
DRAW_SINGLE_PIXEL_NOLOOPANDSTRETCH MACRO 

    lods   BYTE PTR ds:[si]        
	xlat   BYTE PTR cs:[bx]        ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]        ;
	add    di, dx                  ; bp has 79 (0x4F) and stos added one
	add    cx, bp                  ; add 16 low bits of precision
    db     073h, 003h              ; jnc past lods xlat into next stos
    
ENDM


REPT 199
    DRAW_SINGLE_PIXEL_NOLOOPANDSTRETCH
ENDM

; draw last pixel, cut off the add

    lods   BYTE PTR ds:[si]
	xlat   BYTE PTR cs:[bx]
	stos   BYTE PTR es:[di]

loop_done_noloopandstretch:
; clean up

; restore ds without going to memory.
    mov  ax, ss

    retf
ENDP


ALIGN 16



MARKER_COLFUNC_NORMAL_FUNCTION_AREA_OFFSET_:
PUBLIC MARKER_COLFUNC_NORMAL_FUNCTION_AREA_OFFSET_

PROC    R_DrawColumn24Normal_ FAR
PUBLIC  R_DrawColumn24Normal_

; 7Fh in BL to AND to SI, high byte helps point to the colormap for xlat
; 417Fh
COLORMAPS_F_OFFSET = 07Fh + (((COLORMAPS_F_DUPE_SEGMENT) - COLORMAPS_SEGMENT) SHL 4)


   mov   word ptr cs:[((COLFUNC_FUNCTION_AREA_SEGMENT - COLORMAPS_SEGMENT) SHL 4) + MARKER_SM_COLFUNC_jump_offset24_+1], dx ; five bytes


; credit to zero318 for various ideas for the function
   MOV  DX, AX  ; copy center24y
   MUL  CH
   ADD  CL, AL
   MOV  AX, DX ; restore center_y
   AND  DH, BL
   SUB  CL, DH  ; apply neg sign
   MUL  BX
   ADD  SI, AX
   ADC  CL, DL
   
   MOV  DX, BX
   LEA  BX, [bp + COLORMAPS_F_OFFSET]   ; for ANDing to SI and XLAT

; todo clean this up...

   xor  ax, ax   ; ah gets 0
   xchg al, ch   ; al gets value for bp, ch gets 0
   mov  bp, ax   ; bp gets integer texel step
   dec  bp       ; minus 1 for lods 

   xchg cx, si   ; si gets hi texel, cx gets low texel


   ;  prep our loop variables

MARKER_SM_COLFUNC_set_destview_segment24_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment24_
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment


   cli 
   ;lds     ax, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and ax to 004Fh (hardcoded) to mvoe into sp
   mov     ss, sp
   mov     sp, 04Fh


MARKER_SM_COLFUNC_jump_offset24_:
PUBLIC MARKER_SM_COLFUNC_jump_offset24_

   jmp loop_done         ; relative jump to be modified before function is called
; currently EVEN
; 12 bytes each
ENSUREALIGN_203:



   ;; 12 bytes loop iter

; 0xC size
DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didn't make anything faster.
   ; todo retry on real 286


	and    si, bx                  ; bx is 7F
	lods   BYTE PTR ds:[si]        ;
	xlat   BYTE PTR cs:[bx]        ; cs:[bx + 7F] is colormaps
	stos   BYTE PTR es:[di]        ;
	add    cx, dx                  ; add 16 low bits of precision
    adc    si, bp                  ; carry result into this add
	add    di, sp                  ; sp has 79 (0x4F) and stos added one
ENDM

REPT 199
    DRAW_SINGLE_PIXEL
ENDM

; draw last pixel, cut off the add

	and    si, bx                  ; bx is 7F
	lods   BYTE PTR ds:[si]        ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;

loop_done:
; clean up

; restore ds without going to memory.

    mov  sp, ss
    mov  ax, FIXED_DS_SEGMENT
    mov  ss, ax

    sti

    retf


ENDP


ALIGN 16


MARKER_COLFUNC_NORMALSTRETCH_FUNCTION_AREA_OFFSET_:
PUBLIC MARKER_COLFUNC_NORMALSTRETCH_FUNCTION_AREA_OFFSET_

PROC    R_DrawColumn24NormalStretch_ FAR
PUBLIC  R_DrawColumn24NormalStretch_

  mov   word ptr cs:[((COLFUNC_FUNCTION_AREA_SEGMENT - COLORMAPS_SEGMENT) SHL 4) + MARKER_SM_COLFUNC_jump_offset24_normalstretch_+1], dx ; five bytes


   ; ch is unset (garbage), but implied value 0. skip the mul ch step

; credit to zero318 for various ideas for the function
   MOV  DX, AX  ; copy center24y

   AND  DH, BL
   SUB  CL, DH  ; apply neg sign
   MUL  BX
   ADD  SI, AX
   ADC  CL, DL
   
   xchg bx, bp   ; bx gets xlat lookup, bp gets high adder

   mov  dx, 07Fh
    ; dont need to zero ch. first use of SI is ANDed anyway.

; todo clean this up...
   
   xchg si, cx   ; si gets hi texel, cx gets low texel 


   ;  prep our loop variables

MARKER_SM_COLFUNC_set_destview_segment24_normalstretch_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment24_normalstretch_
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment

   cli 
   ;lds     ax, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and ax to 004Fh (hardcoded) to mvoe into sp
   mov     ss, sp
   mov     sp, 04Fh


MARKER_SM_COLFUNC_jump_offset24_normalstretch_:
PUBLIC MARKER_SM_COLFUNC_jump_offset24_normalstretch_

   jmp loop_done_normalstretch         ; relative jump to be modified before function is called
; currently EVEN
; 12 bytes each
ENSUREALIGN_204:


   ;; 12 bytes loop iter

; 0xC size
DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didn't make anything faster.
   ; todo retry on real 286


	and    si, dx                  ; dx is 7F
	lods   BYTE PTR ds:[si]        ;
	xlat   BYTE PTR cs:[bx]        ; cs:[bx] is colormaps
	stos   BYTE PTR es:[di]        ;
	add    di, sp                  ; sp has 79 (0x4F) and stos added one
	add    cx, bp                  ; add 16 low bits of precision
    db     073h, 005h              ; jnc past and lods xlat into next stos

ENDM

REPT 199
    DRAW_SINGLE_PIXEL
ENDM

; draw last pixel, cut off the add

	and    si, dx                  ; bp is 7F
	lods   BYTE PTR ds:[si]        ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;

loop_done_normalstretch:
; clean up

; restore ds without going to memory.

    mov  sp, ss
    mov  ax, FIXED_DS_SEGMENT
    mov  ss, ax

    sti

    retf



ENDP

public ENSUREALIGN_201
public ENSUREALIGN_202
public ENSUREALIGN_203
public ENSUREALIGN_204

; end marker for this asm file
PROC R_COLUMN24_ENDMARKER_ 
PUBLIC R_COLUMN24_ENDMARKER_ 
ENDP

ENDS


END