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
.DATA

 








;=================================

.CODE


PROC R_COLUMN16_STARTMARKER_
PUBLIC R_COLUMN16_STARTMARKER_
ENDP 

_colfunc_jump_target:
dw 00954h, 00948h, 0093Ch, 00930h, 00924h, 00918h, 0090Ch, 00900h
dw 008F4h, 008E8h, 008DCh, 008D0h, 008C4h, 008B8h, 008ACh, 008A0h
dw 00894h, 00888h, 0087Ch, 00870h, 00864h, 00858h, 0084Ch, 00840h
dw 00834h, 00828h, 0081Ch, 00810h, 00804h, 007F8h, 007ECh, 007E0h
dw 007D4h, 007C8h, 007BCh, 007B0h, 007A4h, 00798h, 0078Ch, 00780h
dw 00774h, 00768h, 0075Ch, 00750h, 00744h, 00738h, 0072Ch, 00720h
dw 00714h, 00708h, 006FCh, 006F0h, 006E4h, 006D8h, 006CCh, 006C0h
dw 006B4h, 006A8h, 0069Ch, 00690h, 00684h, 00678h, 0066Ch, 00660h
dw 00654h, 00648h, 0063Ch, 00630h, 00624h, 00618h, 0060Ch, 00600h
dw 005F4h, 005E8h, 005DCh, 005D0h, 005C4h, 005B8h, 005ACh, 005A0h
dw 00594h, 00588h, 0057Ch, 00570h, 00564h, 00558h, 0054Ch, 00540h
dw 00534h, 00528h, 0051Ch, 00510h, 00504h, 004F8h, 004ECh, 004E0h
dw 004D4h, 004C8h, 004BCh, 004B0h, 004A4h, 00498h, 0048Ch, 00480h
dw 00474h, 00468h, 0045Ch, 00450h, 00444h, 00438h, 0042Ch, 00420h
dw 00414h, 00408h, 003FCh, 003F0h, 003E4h, 003D8h, 003CCh, 003C0h
dw 003B4h, 003A8h, 0039Ch, 00390h, 00384h, 00378h, 0036Ch, 00360h
dw 00354h, 00348h, 0033Ch, 00330h, 00324h, 00318h, 0030Ch, 00300h
dw 002F4h, 002E8h, 002DCh, 002D0h, 002C4h, 002B8h, 002ACh, 002A0h
dw 00294h, 00288h, 0027Ch, 00270h, 00264h, 00258h, 0024Ch, 00240h
dw 00234h, 00228h, 0021Ch, 00210h, 00204h, 001F8h, 001ECh, 001E0h
dw 001D4h, 001C8h, 001BCh, 001B0h, 001A4h, 00198h, 0018Ch, 00180h
dw 00174h, 00168h, 0015Ch, 00150h, 00144h, 00138h, 0012Ch, 00120h
dw 00114h, 00108h, 000FCh, 000F0h, 000E4h, 000D8h, 000CCh, 000C0h
dw 000B4h, 000A8h, 0009Ch, 00090h, 00084h, 00078h, 0006Ch, 00060h
dw 00054h, 00048h, 0003Ch, 00030h, 00024h, 00018h, 0000Ch, 00000h



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
	
PROC  R_DrawColumn16_
PUBLIC  R_DrawColumn16_

; no need to push anything. outer function just returns and pops

    ; di contains shifted dc_x relative to detailshift
    ; ax contains dc_yl
    ; si:bp is dc_texturemid
    ; bx contains dc_iscale+0
    ; cx contains dc_iscale+1 (we never use byte 4)

    ; todo just move this above to prevenet the need for the mov ax
    ;SELFMODIFY_COLFUNC_subtract_centery16
    sub   ax, 01000h
    mov   ds, ax              ; save low(M1)

;    this is now done outside the call, including the register swap    
;    mov   bx, word ptr ds:[_dc_iscale + 0]   
;    mov   ch, byte ptr ds:[_dc_iscale + 2]      ; 2nd byte of high word not used up ahead...
;    mov   cl, bh                             ; construct dc_iscale + 1 word
     mov   es, cx                             ; cache for later to avoid going to memory



;  DX:AX * CX:BX

; note this is 8 bit times 32 bit and we want the mid 16

; begin multiply
	CWD
	AND DX, BX
	NEG DX

    mul     ch;             ; only the bottom 16 bits are necessary.
    add     dx,ax           ; - add to total
    mov     cx,dx           ; - hold total in cx
    mov     ax,ds           ; restore low(M1)
    mul     bx              ; low(M2) * low(M1)
    add     dx,cx           ; add previously computed high part
; end multiply    

; multiply completed. 
; dx:ax is the 32 bits of the mul. we want dx to have the mid 16.

;    finishing  dc_texturemid.w + (dc_yl-centery)*fracstep.w


    
    add   ax, bp
    adc   dx, si ; si was holding onto _dc_texturemid+2

    mov   cx, es        ; cx gets dc_iscale + 1


    mov   dh, dl
    mov   dl, ah        ; mid 16 bits of the 32 bit dx:ax into dx

    
    

    

    ; for fixing jaggies... need extra precision from time to time


   ;  prep our loop variables

;SELFMODIFY_COLFUNC_set_destview_segment16:
   mov     ax, 01000h   
   mov     es, ax; ready the viewscreen segment
   xor     bx, bx       ; common bx offset of zero in the xlats ahead

   lds     si, dword ptr ss:[_dc_source_segment-2]  ; sets ds, and si to 004Fh (hardcoded)

   mov     ah,  7Fh   ; for ANDing to AX to mod al by 128 and preserve AH

COLFUNC_JUMP_OFFSET:
   jmp loop_done         ; relative jump to be modified before function is called


; 24 case:
; step is  bp:cl
; total is dx:ch
; we want to use
; step is cx
; total is dx
; which means get rid of whats happening in ch.

pixel_loop_fast:

   ;; 12 bytes loop iter

; 0xE size
DRAW_SINGLE_PIXEL MACRO 
    mov    al,dh
    and    al,ah                  ; ah has 0x7F (127 for al)
    xlat   BYTE PTR ds:[bx]       ;
    xlat   BYTE PTR cs:[bx]       ; cs points to colormap
    stos   BYTE PTR es:[di]       ;
    add    dx,cx
    add    di,si                  ; si has 79 (0x4F) and stos added one
ENDM


REPT 199
    DRAW_SINGLE_PIXEL
ENDM

; draw last pixel, cut off the add
    mov    al,dh
    and    al,ah                  ; ah has 0x7F (127 for al)
    xlat   BYTE PTR ds:[bx]       ;
    xlat   BYTE PTR cs:[bx]       ; cs points to colormap
    stos   BYTE PTR es:[di]       ;


loop_done:
; clean up

; restore ds without going to memory.

    mov ax, ss
    mov ds, ax

    retf


ENDP






; end marker for this asm file
PROC R_COLUMN16_ENDMARKER_ 
PUBLIC R_COLUMN16_ENDMARKER_ 
ENDP




END