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


SEGMENT R_COL0_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:R_COL0_TEXT
 









PROC R_COLUMN0_STARTMARKER_
PUBLIC R_COLUMN0_STARTMARKER_
ENDP 

_colfunc_jump_target:
dw 00255h, 00252h, 0024Fh, 0024Ch, 00249h, 00246h, 00243h, 00240h
dw 0023Dh, 0023Ah, 00237h, 00234h, 00231h, 0022Eh, 0022Bh, 00228h
dw 00225h, 00222h, 0021Fh, 0021Ch, 00219h, 00216h, 00213h, 00210h
dw 0020Dh, 0020Ah, 00207h, 00204h, 00201h, 001FEh, 001FBh, 001F8h
dw 001F5h, 001F2h, 001EFh, 001ECh, 001E9h, 001E6h, 001E3h, 001E0h
dw 001DDh, 001DAh, 001D7h, 001D4h, 001D1h, 001CEh, 001CBh, 001C8h
dw 001C5h, 001C2h, 001BFh, 001BCh, 001B9h, 001B6h, 001B3h, 001B0h
dw 001ADh, 001AAh, 001A7h, 001A4h, 001A1h, 0019Eh, 0019Bh, 00198h
dw 00195h, 00192h, 0018Fh, 0018Ch, 00189h, 00186h, 00183h, 00180h
dw 0017Dh, 0017Ah, 00177h, 00174h, 00171h, 0016Eh, 0016Bh, 00168h
dw 00165h, 00162h, 0015Fh, 0015Ch, 00159h, 00156h, 00153h, 00150h
dw 0014Dh, 0014Ah, 00147h, 00144h, 00141h, 0013Eh, 0013Bh, 00138h
dw 00135h, 00132h, 0012Fh, 0012Ch, 00129h, 00126h, 00123h, 00120h
dw 0011Dh, 0011Ah, 00117h, 00114h, 00111h, 0010Eh, 0010Bh, 00108h
dw 00105h, 00102h, 000FFh, 000FCh, 000F9h, 000F6h, 000F3h, 000F0h
dw 000EDh, 000EAh, 000E7h, 000E4h, 000E1h, 000DEh, 000DBh, 000D8h
dw 000D5h, 000D2h, 000CFh, 000CCh, 000C9h, 000C6h, 000C3h, 000C0h
dw 000BDh, 000BAh, 000B7h, 000B4h, 000B1h, 000AEh, 000ABh, 000A8h
dw 000A5h, 000A2h, 0009Fh, 0009Ch, 00099h, 00096h, 00093h, 00090h
dw 0008Dh, 0008Ah, 00087h, 00084h, 00081h, 0007Eh, 0007Bh, 00078h
dw 00075h, 00072h, 0006Fh, 0006Ch, 00069h, 00066h, 00063h, 00060h
dw 0005Dh, 0005Ah, 00057h, 00054h, 00051h, 0004Eh, 0004Bh, 00048h
dw 00045h, 00042h, 0003Fh, 0003Ch, 00039h, 00036h, 00033h, 00030h
dw 0002Dh, 0002Ah, 00027h, 00024h, 00021h, 0001Eh, 0001Bh, 00018h
dw 00015h, 00012h, 0000Fh, 0000Ch, 00009h, 00006h, 00003h, 00000h

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
	
PROC    R_DrawColumn0_ FAR
PUBLIC  R_DrawColumn0_

; no need to push anything. outer function just returns and pops

    ; di contains shifted dc_x relative to detailshift
    ;  prep our loop variables
   mov     ax, ss
   mov     ds, ax
   xor     bx, bx
   les     si, dword ptr ds:[_dc_source_segment-2]  ; si to 004Fh (hardcoded)
   mov     al, byte ptr es:[bx]                     ; get first pixel in column.
   xlat    byte ptr cs:[bx]                          ; before calling this function we already set CS to the correct segment..
MARKER_SM_COLFUNC_set_destview_segment0_:
PUBLIC MARKER_SM_COLFUNC_set_destview_segment0_
   mov     dx, 01000h   
   mov     es, dx; ready the viewscreen segment



MARKER_SM_COLFUNC_jump_offset0_:
PUBLIC MARKER_SM_COLFUNC_jump_offset0_
   jmp loop_done         ; relative jump to be modified before function is called


pixel_loop_fast:


DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didnt make anything faster.
   ; todo retry on real 286

	stosb
	add    di,si                  ; si has 79 (0x4F) and stos added one
ENDM


REPT 199
    DRAW_SINGLE_PIXEL
ENDM

; draw last pixel, cut off the add

	stosb

loop_done:
; clean up

; restore ds without going to memory.


    retf


ENDP






; end marker for this asm file
PROC R_COLUMN0_ENDMARKER_ 
PUBLIC R_COLUMN0_ENDMARKER_ 
ENDP

ENDS


END