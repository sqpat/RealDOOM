PROC R_DrawSpan NEAR

; todo: cli, set up SP after call , clena up ss:sp after all this

; CL = position_x_high
; CH = position_y_high
; DL = position_x_low
; DH = step_y_high
; BX = ds_y << 1
; SP = step_y_low
; BP = position_y_low
; SI = ds_x2
; DI = ds_x1


; sp = xstep (set in func via selfmodify)
; dx = x position (must be passed in. juggled due to OUT)
; bp = ystep  (must be passed in)
; cx = y position (must be passed in)
; ah = 3Fh (set in func)

    SUB SI, DI
    ;JNS width_zero ; Does this ever happen?
    INC SI
    
    MOV AX, DI
    SHIFT_MACRO SHR DI 2
    ADD DI, DS:[BX + MULT_80]

IF POTATO_QUALITY
    MOV BX, DX ; 2 byte
    MOV AX, 0x3F0F ; 3 byte
    MOV DX, SC_DATA ; 3 byte
    OUT DX, AL ; 1 byte
    MOV DX, BX ; 2 byte
SELFMODIFY_SPAN_xstep_potato: ; Also modify the instruction that writes this
    MOV sp, 0x1000 ; 3 byte
    SHR SI, 1 ; 2 byte
    AND SI, 0xFFFE ; 3 byte
    JMP WORD CS:[SI + _spanfunc_jump_target + 2 - OFFSET R_SPAN24_STARTMARKER_] ; 5 byte
ELSEIF HIGH_QUALITY
    AND AX, 3 ; 3 byte
    INC AX ; 1 byte
    MOV CS:[SELFMODIFY_SPAN_di_offset+1 - OFFSET R_SPAN24_STARTMARKER_], AL ; 4 byte
    SHL AL, 1 ; 2 byte
    SHL AL, 1 ; 2 byte
    SHL AL, 1 ; 2 byte
    ADD AX, (plane_iter_high1 - OFFSET R_SPAN24_STARTMARKER_) - 8 ; 3 byte
    MOV CS:[SELFMODIFY_SPAN_plane_iter_addr+1 - OFFSET R_SPAN24_STARTMARKER_], AX ; 4 byte
    XCHG AX, BX ; 1 byte
    MOV AX, SI ; 2 byte
    ; Potato sequence ends here
    AND AX, 3 ; 3 byte
    XOR SI, AX ; 2 byte
    ADD AL, -5 ; 2 byte  Convert 0-3 to 5-2
    SHR SI, 1 ; 2 byte
ELSE ; LOW_QUALITY
    AND AX, 2 ; 4 byte (long encoding)
    MOV CS:[SELFMODIFY_SPAN_di_offset+1 - OFFSET R_SPAN24_STARTMARKER_], AL ; 4 byte
    SHL AL, 1 ; 2 byte
    SHL AL, 1 ; 2 byte
    ADD AX, plane_iter_low12 - OFFSET R_SPAN24_STARTMARKER_ ; 4 byte (long encoding)
    MOV CS:[SELFMODIFY_SPAN_plane_iter_addr+1 - OFFSET R_SPAN24_STARTMARKER_], AX ; 4 byte
    MOV BX, AX ; 2 byte
    SHR SI, 1 ; 2 byte
    ; Potato sequence ends here
    MOV AX, SI ; 2 byte
    AND AX, 1 ; 3 byte
    XOR SI, AX ; 2 byte
    ADD AL, -3 ; 2 byte Convert 0-1 to 3-2
ENDIF
    NEG AL
    MOV CS:[SELFMODIFY_SPAN_extra_pixel_cmp+1 - OFFSET R_SPAN24_STARTMARKER_], AL
    MOV AX, CS:[SI + _spanfunc_jump_target - OFFSET R_SPAN24_STARTMARKER_]
    MOV CS:[SELFMODIFY_SPAN_pixel_jump_target+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    MOV CS:[SELFMODIFY_SPAN_reset_di+2 - OFFSET R_SPAN24_STARTMARKER_], DI

SELFMODIFY_SPAN_xstep_not_potato: ; Also modify the instruction that writes this
    MOV sp, 0x1000
    
IF HIGH_QUALITY
    MOV AX, 0x3F04
ELSE ; LOW_QUALITY
    MOV AX, 0x3F02
ENDIF
    JMP start_plane_loop
    
_spanfunc_jump_target:
BYTES_PER_PIXEL = 0x14
MAX_PIXELS = 80 ; +1 for potato not having the extra offset
bytecount = 0
REPT MAX_PIXELS + 1
    dw (plane_loop_pixels - OFFSET R_SPAN24_STARTMARKER_) + (bytecount - BYTES_PER_PIXEL)
    bytecount = bytecount + BYTES_PER_PIXEL
ENDM

plane_loop_pixels:
REPT MAX_PIXELS - 1
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
    MOV BH, CH
    MOV BL, DH
    SHR BX, 1
    SHR BX, 1
    MOV AL, DS:[BX]
    MOV SI, AX
    MOVSB ES:[DI], SS:[SI]
IF POTATO_QUALITY
    JMP break_plane_loop
ELSE
    MOV SI, BX
ENDIF
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
    
plane_iter_high1:
    db 0
    db 0x08, 0x04, 0x02, 0x01
plane_iter_low12:
    db 0
    db 0xC0, 0x03
plane_iter_high2:
    db 0
    db 0x01, 0x08, 0x04, 0x02
plane_iter_low34:
    db 0
    db 0x03, 0xC0
plane_iter_high3:
    db 0
    db 0x02, 0x01, 0x08, 0x04
    db 0, 0, 0 ; 3 padding bytes
plane_iter_high4:
    db 0
    db 0x04, 0x02, 0x01, 0x08
    
break_plane_loop:
    ; Probably restore SS/SP here
    
ENDP