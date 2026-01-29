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





; mul 80 table. common table to put at segment:[0000]
_dc_yl_lookup_table:
PUBLIC _dc_yl_lookup_table
sumof80s = 0
MAX_PIXELS = 200
REPT MAX_PIXELS
    dw sumof80s 
    sumof80s = sumof80s + 80
ENDM


MARKER_COLFUNC_JUMP_TARGET24_:
PUBLIC MARKER_COLFUNC_JUMP_TARGET24_
BYTES_PER_PIXEL = 14
MAX_PIXELS = 200
bytecount = MAX_PIXELS * BYTES_PER_PIXEL
REPT MAX_PIXELS
    bytecount = bytecount - BYTES_PER_PIXEL
    dw bytecount 
ENDM

;
; R_DrawColumn
;
	
PROC    R_DrawColumn24_ FAR
PUBLIC  R_DrawColumn24_

    ; di contains screen coord
    ; ax contains dc_yl
    ; CL:SI = dc_texturemid
    ; CH:BX = dc_iscale

; thoughts: 
; every call to this functions has an xchg ax, bx to put dc_yl into ax
; can consider just having it in bx? and dc_iscale low in ax


COLFUNC_NOLOOP_FUNCTION_AREA_SEGMENT_:
public COLFUNC_NOLOOP_FUNCTION_AREA_SEGMENT_


MARKER_COLFUNC_NOLOOPANDSTRETCH_JUMPTABLE_SIZE_OFFSET_:
public MARKER_COLFUNC_NOLOOPANDSTRETCH_JUMPTABLE_SIZE_OFFSET_
MARKER_COLFUNC_NOLOOP_JUMPTABLE_SIZE_OFFSET_:
public MARKER_COLFUNC_NOLOOP_JUMPTABLE_SIZE_OFFSET_
BYTES_PER_PIXEL = 10
MAX_PIXELS = 200
bytecount = MAX_PIXELS * BYTES_PER_PIXEL
REPT MAX_PIXELS
    bytecount = bytecount - BYTES_PER_PIXEL
    dw bytecount
ENDM




MARKER_COLFUNC_NOLOOP_FUNCTION_AREA_OFFSET_:
PUBLIC MARKER_COLFUNC_NOLOOP_FUNCTION_AREA_OFFSET_

PROC    R_DrawColumn24NoLoop_ FAR
PUBLIC  R_DrawColumn24NoLoop_

    ; di contains screen coord
    ; ax contains dc_yl
    ; CL:SI = dc_texturemid
    ; CH:BX = dc_iscale


MARKER_SM_COLFUNC_subtract_centery24_noloop_:
PUBLIC MARKER_SM_COLFUNC_subtract_centery24_noloop_
    sub   ax, 01000h

   MOV  DX, AX  ; copy center24y
   MUL  CH
   ADD  CL, AL
   MOV  AX, DX ; restore center_y
   AND  DH, BL
   SUB  CL, DH  ; apply neg sign
   MUL  BX
   ADD  SI, AX
   ADC  CL, DL
   xor  dx, dx   ; zero dx
   xchg DX, BX   ; dx gets bx, bx gets  0 

; todo clean this up...



   mov  ax, bx   ; ax gets 0
   mov  al, ch
   mov  bp, ax   ; bl gets texel step
   mov  al, cl
   xchg ax, si   ; si gets hi texel
   xchg ax, cx   ; sx gets low texel (previously cx)
   dec  bp       ; minus one to account for lodsb



   ;  prep our loop variables
   
   cli 
   lds     ax, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and bp to 004Fh (hardcoded)
   mov     ss, sp
   xchg    ax, sp

MARKER_SM_COLFUNC_set_destview_segment24_noloop_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment24_noloop_
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment




MARKER_SM_COLFUNC_jump_offset24_noloop_:
PUBLIC MARKER_SM_COLFUNC_jump_offset24_noloop_

   jmp loop_done_noloop         ; relative jump to be modified before function is called


DRAW_SINGLE_PIXEL_NOLOOP MACRO 

    lods   BYTE PTR ds:[si]        
	xlat   BYTE PTR cs:[bx]        ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]        ;
	add    cx, dx                  ; add 16 low bits of precision
    adc    si, bp                  ; carry result into this add
	add    di, sp                  ; bp has 79 (0x4F) and stos added one
    
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
    mov  ds, ax
    mov  ss, ax



    sti

    retf


ENDP

; NOTE r_mask cannot reach this function. it only maps one EMS page including colormaps instead of also the one after it.

ALIGN 16

MARKER_COLFUNC_NOLOOPANDSTRETCH_FUNCTION_AREA_OFFSET_:
PUBLIC MARKER_COLFUNC_NOLOOPANDSTRETCH_FUNCTION_AREA_OFFSET_

PROC    R_DrawColumn24NoLoopAndStretch_ FAR
PUBLIC  R_DrawColumn24NoLoopAndStretch_

    ; di contains screen coord
    ; ax contains dc_yl
    ; CL:SI = dc_texturemid
    ; CH:BX = dc_iscale


MARKER_SM_COLFUNC_subtract_centery24_noloopandstretch_:
PUBLIC MARKER_SM_COLFUNC_subtract_centery24_noloopandstretch_
    sub   ax, 01000h

   MOV  DX, AX  ; copy center24y
   MUL  CH
   ADD  CL, AL
   MOV  AX, DX ; restore center_y
   AND  DH, BL
   SUB  CL, DH  ; apply neg sign
   MUL  BX
   ADD  SI, AX
   ADC  CL, DL
   xor  dx, dx   ; zero dx
   xchg DX, BX   ; dx gets bx, bx gets  0 

; todo clean this up...

   mov  ax, bx   ; ax gets 0
   mov  al, cl
   xchg ax, si   ; si gets hi texel
   xchg ax, cx   ; cx gets low texel (previously si)


   ;  prep our loop variables
   
   lds     bp, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and bp to 004Fh (hardcoded)


MARKER_SM_COLFUNC_set_destview_segment24_noloopandstretch_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment24_noloopandstretch_
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment

MARKER_SM_COLFUNC_jump_offset24_noloopandstretch_:
PUBLIC MARKER_SM_COLFUNC_jump_offset24_noloopandstretch_

   jmp loop_done_noloopandstretch         ; relative jump to be modified before function is called


DRAW_SINGLE_PIXEL_NOLOOPANDSTRETCH MACRO 

    lods   BYTE PTR ds:[si]        
	xlat   BYTE PTR cs:[bx]        ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]        ;
	add    di, bp                  ; bp has 79 (0x4F) and stos added one
	add    cx, dx                  ; add 16 low bits of precision
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
    mov  ds, ax

    retf
ENDP


ALIGN 16

MARKER_SM_COLFUNC_subtract_centery24_1_:
PUBLIC MARKER_SM_COLFUNC_subtract_centery24_1_
    sub   ax, 01000h

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
   mov  AH,  7Fh   ; for ANDing to AX to mod al by 128 and preserve AH
   CWD           ; zero dx
   xchg DX, BX   ; dx gets bx, bx gets  0 



   ;  prep our loop variables

MARKER_SM_COLFUNC_set_destview_segment24_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment24_
   mov     bp, 01000h   
   mov     es, bp; ready the viewscreen segment


   lds     bp, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and bp to 004Fh (hardcoded)


MARKER_SM_COLFUNC_jump_offset24_:
PUBLIC MARKER_SM_COLFUNC_jump_offset24_

   jmp loop_done         ; relative jump to be modified before function is called



   ;; 14 bytes loop iter

; 0xE size
DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didn't make anything faster.
   ; todo retry on real 286

    mov    al, cl
	and    al, ah                  ; ah is 7F
	xlat   BYTE PTR ds:[bx]        ;
	xlat   BYTE PTR cs:[bx]        ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]        ;
	add    si, dx                  ; add 16 low bits of precision
    adc    cl, ch                  ; carry result into this add
	add    di, bp                  ; bp has 79 (0x4F) and stos added one
ENDM

REPT 199
    DRAW_SINGLE_PIXEL
ENDM

; draw last pixel, cut off the add

    mov    al, cl
	and    al, ah                 ; ah is 7F
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;

loop_done:
; clean up

; restore ds without going to memory.

    mov  ax, ss
    mov  ds, ax


    retf


ENDP




; end marker for this asm file
PROC R_COLUMN24_ENDMARKER_ 
PUBLIC R_COLUMN24_ENDMARKER_ 
ENDP

ENDS


END