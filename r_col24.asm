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

_colfunc_jump_target:
dw 00AE2h, 00AD4h, 00AC6h, 00AB8h, 00AAAh, 00A9Ch, 00A8Eh, 00A80h
dw 00A72h, 00A64h, 00A56h, 00A48h, 00A3Ah, 00A2Ch, 00A1Eh, 00A10h
dw 00A02h, 009F4h, 009E6h, 009D8h, 009CAh, 009BCh, 009AEh, 009A0h
dw 00992h, 00984h, 00976h, 00968h, 0095Ah, 0094Ch, 0093Eh, 00930h
dw 00922h, 00914h, 00906h, 008F8h, 008EAh, 008DCh, 008CEh, 008C0h
dw 008B2h, 008A4h, 00896h, 00888h, 0087Ah, 0086Ch, 0085Eh, 00850h
dw 00842h, 00834h, 00826h, 00818h, 0080Ah, 007FCh, 007EEh, 007E0h
dw 007D2h, 007C4h, 007B6h, 007A8h, 0079Ah, 0078Ch, 0077Eh, 00770h
dw 00762h, 00754h, 00746h, 00738h, 0072Ah, 0071Ch, 0070Eh, 00700h
dw 006F2h, 006E4h, 006D6h, 006C8h, 006BAh, 006ACh, 0069Eh, 00690h
dw 00682h, 00674h, 00666h, 00658h, 0064Ah, 0063Ch, 0062Eh, 00620h
dw 00612h, 00604h, 005F6h, 005E8h, 005DAh, 005CCh, 005BEh, 005B0h
dw 005A2h, 00594h, 00586h, 00578h, 0056Ah, 0055Ch, 0054Eh, 00540h
dw 00532h, 00524h, 00516h, 00508h, 004FAh, 004ECh, 004DEh, 004D0h
dw 004C2h, 004B4h, 004A6h, 00498h, 0048Ah, 0047Ch, 0046Eh, 00460h
dw 00452h, 00444h, 00436h, 00428h, 0041Ah, 0040Ch, 003FEh, 003F0h
dw 003E2h, 003D4h, 003C6h, 003B8h, 003AAh, 0039Ch, 0038Eh, 00380h
dw 00372h, 00364h, 00356h, 00348h, 0033Ah, 0032Ch, 0031Eh, 00310h
dw 00302h, 002F4h, 002E6h, 002D8h, 002CAh, 002BCh, 002AEh, 002A0h
dw 00292h, 00284h, 00276h, 00268h, 0025Ah, 0024Ch, 0023Eh, 00230h
dw 00222h, 00214h, 00206h, 001F8h, 001EAh, 001DCh, 001CEh, 001C0h
dw 001B2h, 001A4h, 00196h, 00188h, 0017Ah, 0016Ch, 0015Eh, 00150h
dw 00142h, 00134h, 00126h, 00118h, 0010Ah, 000FCh, 000EEh, 000E0h
dw 000D2h, 000C4h, 000B6h, 000A8h, 0009Ah, 0008Ch, 0007Eh, 00070h
dw 00062h, 00054h, 00046h, 00038h, 0002Ah, 0001Ch, 0000Eh, 00000h

; mul 80 table.
_dc_yl_lookup_table:
dw 00000h, 00050h, 000A0h, 000F0h, 00140h, 00190h, 001E0h, 00230h
dw 00280h, 002D0h, 00320h, 00370h, 003C0h, 00410h, 00460h, 004B0h
dw 00500h, 00550h, 005A0h, 005F0h, 00640h, 00690h, 006E0h, 00730h
dw 00780h, 007D0h, 00820h, 00870h, 008C0h, 00910h, 00960h, 009B0h
dw 00A00h, 00A50h, 00AA0h, 00AF0h, 00B40h, 00B90h, 00BE0h, 00C30h
dw 00C80h, 00CD0h, 00D20h, 00D70h, 00DC0h, 00E10h, 00E60h, 00EB0h
dw 00F00h, 00F50h, 00FA0h, 00FF0h, 01040h, 01090h, 010E0h, 01130h
dw 01180h, 011D0h, 01220h, 01270h, 012C0h, 01310h, 01360h, 013B0h
dw 01400h, 01450h, 014A0h, 014F0h, 01540h, 01590h, 015E0h, 01630h
dw 01680h, 016D0h, 01720h, 01770h, 017C0h, 01810h, 01860h, 018B0h
dw 01900h, 01950h, 019A0h, 019F0h, 01A40h, 01A90h, 01AE0h, 01B30h
dw 01B80h, 01BD0h, 01C20h, 01C70h, 01CC0h, 01D10h, 01D60h, 01DB0h
dw 01E00h, 01E50h, 01EA0h, 01EF0h, 01F40h, 01F90h, 01FE0h, 02030h
dw 02080h, 020D0h, 02120h, 02170h, 021C0h, 02210h, 02260h, 022B0h
dw 02300h, 02350h, 023A0h, 023F0h, 02440h, 02490h, 024E0h, 02530h
dw 02580h, 025D0h, 02620h, 02670h, 026C0h, 02710h, 02760h, 027B0h
dw 02800h, 02850h, 028A0h, 028F0h, 02940h, 02990h, 029E0h, 02A30h
dw 02A80h, 02AD0h, 02B20h, 02B70h, 02BC0h, 02C10h, 02C60h, 02CB0h
dw 02D00h, 02D50h, 02DA0h, 02DF0h, 02E40h, 02E90h, 02EE0h, 02F30h
dw 02F80h, 02FD0h, 03020h, 03070h, 030C0h, 03110h, 03160h, 031B0h
dw 03200h, 03250h, 032A0h, 032F0h, 03340h, 03390h, 033E0h, 03430h
dw 03480h, 034D0h, 03520h, 03570h, 035C0h, 03610h, 03660h, 036B0h
dw 03700h, 03750h, 037A0h, 037F0h, 03840h, 03890h, 038E0h, 03930h
dw 03980h, 039D0h, 03A20h, 03A70h, 03AC0h, 03B10h, 03B60h, 03BB0h
dw 03C00h, 03C50h, 03CA0h, 03CF0h, 03D40h, 03D90h, 03DE0h, 03E30h


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

MARKER_SELFMODIFY_COLFUNC_subtract_centery24_:
PUBLIC MARKER_SELFMODIFY_COLFUNC_subtract_centery24_
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


   push    bp
   ;  prep our loop variables

MARKER_SELFMODIFY_COLFUNC_set_destview_segment24_:
PUBLIC MARKER_SELFMODIFY_COLFUNC_set_destview_segment24_
   mov     bp, 01000h   
   mov     es, bp; ready the viewscreen segment


   lds     bp, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and bp to 004Fh (hardcoded)


MARKER_SELFMODIFY_COLFUNC_jump_offset24_:
PUBLIC MARKER_SELFMODIFY_COLFUNC_jump_offset24_

   jmp loop_done         ; relative jump to be modified before function is called


pixel_loop_fast:

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


; TODO: make colormaps duplicate at F offset and sti/cli for 12 byte version.

; and    SI, SP                  ; SP is 7F
; LODSB
; XLAT    cs:[bx]
; stos    es:[di]
; add    ??, dx  
; adc    si, cx
; add    di, bp

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
    pop  bp

    retf


ENDP






; end marker for this asm file
PROC R_COLUMN24_ENDMARKER_ 
PUBLIC R_COLUMN24_ENDMARKER_ 
ENDP

ENDS


END