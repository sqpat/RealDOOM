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
.MODEL  medium
INCLUDE defs.inc
INSTRUCTION_SET_MACRO


EXTRN EV_DoFloor_:FAR
EXTRN EV_DoDoor_:FAR
EXTRN EV_DoPlat_:NEAR
EXTRN EV_DoCeiling_:NEAR
EXTRN EV_BuildStairs_:NEAR
EXTRN EV_StartLightStrobing_:NEAR
EXTRN EV_Teleport_:NEAR
EXTRN EV_PlatFunc_:NEAR
EXTRN EV_LightChange_:NEAR
EXTRN EV_CeilingCrushStop_:NEAR
EXTRN G_SecretExitLevel_:FAR
EXTRN G_ExitLevel_:FAR
EXTRN P_ChangeSwitchTexture_:NEAR
EXTRN P_DamageMobj_:FAR
EXTRN P_Random_:NEAR
EXTRN S_StartSoundWithParams_:FAR

.DATA

EXTRN _buttonlist:WORD
EXTRN _numlinespecials:WORD
EXTRN _levelTimer:BYTE
EXTRN _levelTimeCount:DWORD
EXTRN _anims:WORD
EXTRN _lastanim:WORD
EXTRN _buttonlist:WORD



.CODE


MAX_ADJOINING_SECTORS = 256



PROC    P_SPEC_STARTMARKER_ 
PUBLIC  P_SPEC_STARTMARKER_
ENDP


PROC    twoSided_ NEAR
PUBLIC  twoSided_

;int16_t __near twoSided( int16_t	sector,int16_t	line ){

;	line = sectors[sector].linesoffset + line;
;	line = linebuffer[line];
;   return lineflagslist[line] & ML_TWOSIDED;



push      bx
SHIFT_MACRO shl       ax 4
xchg      ax, bx
mov       ax, SECTORS_SEGMENT
mov       es, ax
mov       bx, word ptr es:[bx + SECTOR_T.sec_linesoffset]
add       bx, dx
sal       bx, 1
mov       bx, word ptr ds:[bx + _linebuffer]
mov       ax, LINEFLAGSLIST_SEGMENT
mov       es, ax
mov       al, byte ptr es:[bx]
and       ax, ML_TWOSIDED
pop       bx
ret       

ENDP



; todo make arg 5 this si argument.


;int16_t __near getNextSectorList(int16_t __near * linenums,int16_t	sec,int16_t __near* secnums,int16_t linecount,boolean onlybacksecnums){

PROC    getNextSectorList_  NEAR
PUBLIC  getNextSectorList_



push      si
push      di
push      bp
mov       bp, sp  ; need stack frame due to bp + 8 arg. can be removed later with selfmodify and si param.

mov       di, ax

mov       word ptr cs:[OFFSET SELFMODIFY_pspec_secnum+2], dx
mov       word ptr cs:[OFFSET SELFMODIFY_pspec_subtract_secnums_base+1], bx


mov       ax, LINEFLAGSLIST_SEGMENT
mov       es, ax
mov       ax, LINES_PHYSICS_SEGMENT
mov       ds, ax

xor       ax, ax   ; ax stores i

test      cx, cx
jle       done_iterating_over_linecount
loop_next_line:
mov       si, word ptr ss:[di]

test      byte ptr es:[si], ML_TWOSIDED
jne       found_sector_opening
dec       bx
dec       bx  
do_next_line:
inc       ax
inc       di
inc       di
inc       bx
inc       bx ; secnums
cmp       ax, cx
jl        loop_next_line
done_iterating_over_linecount:


;	return linecount - skipped. which is the bx index because i == linecount and loopend and bx is i - skipped

xchg      ax, bx   
SELFMODIFY_pspec_subtract_secnums_base:
sub       ax, 01000h  ; remove array base
sar       ax, 1       ; undo word ptr shift



mov       dx, ss
mov       ds, dx  ; restore ds
LEAVE_MACRO     
pop       di
pop       si
ret       2

found_sector_opening:

;		line_physics = &lines_physics[linenums[i]];

SHIFT_MACRO shl       si, 4
; bx already has ptr.

mov       dx, word ptr ds:[si + LINE_PHYSICS_T.lp_frontsecnum]
SELFMODIFY_pspec_secnum:
cmp       dx, 01000h
jne       not_frontsecnum
push      word ptr ds:[si + LINE_PHYSICS_T.lp_backsecnum]
pop       word ptr ss:[bx]
jmp       do_next_line

not_frontsecnum:
cmp       byte ptr [bp + 8], 0  ;only_backsecnums check
jne       do_next_line
mov       word ptr ss:[bx], dx
jmp       do_next_line

ENDP

;short_height_t __near P_FindHighestOrLowestFloorSurrounding(int16_t secnum, int8_t isHigh){

JGE_OPCODE = 07Dh
JLE_OPCODE = 07Eh

PROC    P_FindHighestOrLowestFloorSurrounding_  NEAR
PUBLIC  P_FindHighestOrLowestFloorSurrounding_

; bp - 0200h secnumlist
; bp - 0400h linebufferlines

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4 * MAX_ADJOINING_SECTORS  ; 400

mov       cx, ax
xchg      ax, bx
SHIFT_MACRO shl       bx 4
mov       ax, SECTORS_SEGMENT
mov       es, ax

lea       di, [bp - 0400h]
mov       si, word ptr es:[bx + SECTOR_T.sec_linesoffset]
mov       ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
mov       dh, JGE_OPCODE
cmp       dl, 0 ; ishigh check
je        done_with_floorheight
mov       ax, 0F060h  ;   (-500 SHL 3); -500 << SHORTFLOORBITS 0xf060
mov       dh, JLE_OPCODE
done_with_floorheight:
mov       byte ptr cs:[OFFSET SELFMODIFY_ishigh_jle_jge], dh

mov       dx, cx  ; dx gets secnum for func call.

mov       bx, word ptr es:[bx + SECTOR_T.sec_linecount]
sal       si, 1
mov       cx, bx
add       si, OFFSET _linebuffer


;	memcpy(linebufferlines, &linebuffer[offset], linecount << 1);
push      ds
pop       es
rep movsw 

xchg      ax, di   ; di stores floorheight


push      cx  ; should be 0. false parameter. todo move to si...?
; dx already has secnum...
mov       cx, bx
lea       bx, [bp - 0200h]
lea       ax, [bp - 0400h]

;	linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);

call      getNextSectorList_


mov       cx, ax
jcxz      skip_loop
lea       si, [bp - 0200h]

mov       dx, SECTORS_SEGMENT
mov       es, dx


loop_next_sector:
lodsw   ; inc si 2

xchg      ax, bx
SHIFT_MACRO shl       bx 4

mov       ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
cmp       ax, di
SELFMODIFY_ishigh_jle_jge:   ;    use jle if ishigh false. use jge if ishigh true
jle       dont_update_floorheight
mov       di, ax
dont_update_floorheight:

loop      loop_next_sector

skip_loop:
xchg      ax, di
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       


ENDP



PROC    P_FindNextHighestFloor_  NEAR
PUBLIC  P_FindNextHighestFloor_
;short_height_t __near P_FindNextHighestFloor( int16_t	secnum,short_height_t		currentheight ){

; bp - 0200h linebufferlines
; bp - 0400h

push      bx
push      cx
push      si
push      di

push      bp
mov       bp, sp
sub       sp, 0400h
mov       cx, SECTORS_SEGMENT
mov       es, cx

mov       bx, ax
SHIFT_MACRO shl       bx 4

mov       si, word ptr es:[bx + SECTOR_T.sec_linesoffset]
sal       si, 1
add       si, OFFSET _linebuffer
lea       di, [bp - 0200h]

mov       bx, word ptr es:[bx + SECTOR_T.sec_linecount]
mov       cx, bx


;	memcpy(linebufferlines, &linebuffer[offset], linecount << 1);
push      ds
pop       es
rep movsw 

push      cx  ; cx is 0. push as func arg

xchg      ax, dx ; dx gets secnum
xchg      ax, di ; di gets currentheight
mov       cx, bx ; cx gets linecount

lea       bx, [bp - 0400h]
lea       ax, [bp - 0200h]
;	linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);
call      getNextSectorList_


; di keeps highest.
; dx keeps next highest (starts as MINSHORT) 
mov       dx, 08000h

xchg      ax, cx ; cx gets linecount


mov       ax, SECTORS_SEGMENT
mov       es, ax
; for this loop ds is sectors for lodsw and es is ds for stosw to stack.    

lea       si, [bp - 0400h]
xor       ch, ch


loop_next_sector_floor:

lodsw
SHIFT_MACRO shl       ax 4
xchg      ax, bx
mov       ax, word ptr es:[bx + SECTOR_T.sec_floorheight]
cmp       ax, di ; compare to height..
jle       iter_next_sector_floor  ; NOTE: dont keep ties!
cmp       dx, 08000h
je        force_first_height
cmp       ax, dx
jg        iter_next_sector_floor
force_first_height:
xchg      dx, ax ; this is next highest.
iter_next_sector_floor:

loop      loop_next_sector_floor


finished_floor_height_loop:

xchg      ax, dx
cmp       ax, 08000h
jne       use_recorded_height
xchg      ax, di
use_recorded_height:

LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
ENDP

PROC    P_FindLowestOrHighestCeilingSurrounding_  NEAR
PUBLIC  P_FindLowestOrHighestCeilingSurrounding_

; bp - 0200h secnumlist
; bp - 0400h linebufferlines

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4 * MAX_ADJOINING_SECTORS  ; 400

mov       cx, ax
xchg      ax, bx
SHIFT_MACRO shl       bx 4
mov       ax, SECTORS_SEGMENT
mov       es, ax

lea       di, [bp - 0400h]
mov       si, word ptr es:[bx + SECTOR_T.sec_linesoffset]
mov       ax, 07FFFh        ; MAXSHORT
mov       dh, JGE_OPCODE
cmp       dl, 0 ; ishigh check
je        done_with_ceilheight
mov       dh, JLE_OPCODE
xor       ax, ax
done_with_ceilheight:
mov       byte ptr cs:[OFFSET SELFMODIFY_ishigh_jle_jge_ceiling], dh

mov       dx, cx  ; dx gets secnum for func call.

mov       bx, word ptr es:[bx + SECTOR_T.sec_linecount]
sal       si, 1
mov       cx, bx
add       si, OFFSET _linebuffer


;	memcpy(linebufferlines, &linebuffer[offset], linecount << 1);
push      ds
pop       es
rep movsw 

xchg      ax, di   ; di stores floorheight


push      cx  ; should be 0. false parameter. todo move to si...?
; dx already has secnum...
mov       cx, bx
lea       bx, [bp - 0200h]
lea       ax, [bp - 0400h]

;	linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);

call      getNextSectorList_


mov       cx, ax
jcxz      skip_loop_ceiling
lea       si, [bp - 0200h]

mov       dx, SECTORS_SEGMENT
mov       es, dx


loop_next_sector_ceiling:
lodsw   ; inc si 2

xchg      ax, bx
SHIFT_MACRO shl       bx 4

mov       ax, word ptr es:[bx + SECTOR_T.sec_ceilingheight]
cmp       ax, di
SELFMODIFY_ishigh_jle_jge_ceiling:   ;    use jle if ishigh false. use jge if ishigh true
jle       dont_update_ceilheight
mov       di, ax
dont_update_ceilheight:

loop      loop_next_sector_ceiling

skip_loop_ceiling:
xchg      ax, di
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       


ENDP


;void __near P_FindSectorsFromLineTag ( int8_t		linetag,int16_t*		foundsectors,boolean		includespecials){

PROC    P_FindSectorsFromLineTag_  NEAR
PUBLIC  P_FindSectorsFromLineTag_

push      di
test      bl, bl
mov       bl, OFFSET check_special - OFFSET SELFMODIFY_checkspecial_AFTER
je        dont_include_special
mov       bl, OFFSET linetags_equal_skip_special_check - OFFSET SELFMODIFY_checkspecial_AFTER
dont_include_special:
mov       byte ptr cs:[OFFSET SELFMODIFY_checkspecial + 1], bl

xchg      ax, dx ; linetag to dl. foundsectors to ax.
xchg      ax, di ; foundsectors to di

xor       ax, ax
mov       bx, OFFSET _sectors_physics
push      ds
pop       es  ; for stosw.

loop_next_sector_linetag:
cmp       ax, word ptr ds:[_numsectors]
jge       done_iterating_linetag_sectors

cmp       dl, byte ptr ds:[bx + SECTOR_PHYSICS_T.secp_tag]
SELFMODIFY_checkspecial:
je        check_special
SELFMODIFY_checkspecial_AFTER:

iter_next_sector:
add       bx, SIZEOF_SECTOR_PHYSICS_T
inc       ax
jmp       loop_next_sector_linetag

check_special:

cmp       word ptr ds:[bx + SECTOR_PHYSICS_T.secp_specialdataRef], 0
jne       iter_next_sector

linetags_equal_skip_special_check:
linetags_equal:

stosw     ; store ax in es:di
jmp       iter_next_sector

done_iterating_linetag_sectors:

mov       word ptr ds:[di], -1

pop       di
ret       
ENDP



PROC    P_FindMinSurroundingLight_  NEAR
PUBLIC  P_FindMinSurroundingLight_

; bp - 0200h secnumlist
; bp - 0400h linebufferlines

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4 * MAX_ADJOINING_SECTORS  ; 400

mov       cx, ax
xchg      ax, bx
SHIFT_MACRO shl       bx 4
mov       ax, SECTORS_SEGMENT
mov       es, ax
xchg      ax, dx ; ax stores max

lea       di, [bp - 0400h]
mov       si, word ptr es:[bx + SECTOR_T.sec_linesoffset]


mov       bx, word ptr es:[bx + SECTOR_T.sec_linecount]
mov       dx, cx  ; dx gets secnum for func call.
sal       si, 1
mov       cx, bx
add       si, OFFSET _linebuffer


;	memcpy(linebufferlines, &linebuffer[offset], linecount << 1);
push      ds
pop       es
rep movsw 

xchg      ax, di   ; di stores max


push      cx  ; should be 0. false parameter. todo move to si...?
; dx already has secnum...
mov       cx, bx
lea       bx, [bp - 0200h]
lea       ax, [bp - 0400h]

;	linecount = getNextSectorList(linebufferlines, secnum, secnumlist, linecount, false);

call      getNextSectorList_


xchg      ax, cx
mov       dx, di  ; dx stores max again
xor       dh, dh

jcxz      skip_loop_light
lea       si, [bp - 0200h]

mov       di, SECTORS_SEGMENT
mov       es, di


loop_next_sector_light:
lodsw   ; inc si 2

xchg      ax, bx
SHIFT_MACRO shl       bx 4

mov       al, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
cmp       al, dl
jge       dont_update_light
mov       dl, al

dont_update_light:
loop      loop_next_sector_light

skip_loop_light:
xchg      ax, dx

LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       


ENDP

skip_special_mobj_types:
db MT_ROCKET, MT_PLASMA, MT_BFG, MT_TROOPSHOT, MT_HEADSHOT, MT_BRUISERSHOT
COMMENT @
	  case MT_ROCKET:
	  case MT_PLASMA:
	  case MT_BFG:
	  case MT_TROOPSHOT:
	  case MT_HEADSHOT:
	  case MT_BRUISERSHOT:
	    return;
	    break;
@


skip_special_tags:
db 39, 97, 125, 126, 4, 10, 88

COMMENT @
	  case 39:	// TELEPORT TRIGGER
	  case 97:	// TELEPORT RETRIGGER
	  case 125:	// TELEPORT MONSTERONLY TRIGGER
	  case 126:	// TELEPORT MONSTERONLY RETRIGGER
	  case 4:	// RAISE DOOR
	  case 10:	// PLAT DOWN-WAIT-UP-STAY TRIGGER
	  case 88:	// PLAT DOWN-WAIT-UP-STAY RETRIGGER
@


cross_special_line_jump_table:
dw switch_case_2, switch_case_3, switch_case_4, switch_case_5, switch_case_6, switch_case_default, switch_case_8, switch_case_default, switch_case_10, switch_case_default, switch_case_12 
dw switch_case_13, switch_case_default, switch_case_default, switch_case_16, switch_case_17, switch_case_default, switch_case_19, switch_case_default, switch_case_default, switch_case_22, switch_case_default 
dw switch_case_default, switch_case_25, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_30, switch_case_default, switch_case_default, switch_case_default, switch_case_default 
dw switch_case_35, switch_case_36, switch_case_37, switch_case_38, switch_case_39, switch_case_40, switch_case_default, switch_case_default, switch_case_default, switch_case_44, switch_case_default
dw switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_52, switch_case_53, switch_case_54, switch_case_default, switch_case_56
dw switch_case_57, switch_case_58, switch_case_59, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default
dw switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_72, switch_case_73, switch_case_74, switch_case_75, switch_case_76, switch_case_77, switch_case_default
dw switch_case_79, switch_case_80, switch_case_81, switch_case_82, switch_case_83, switch_case_84, switch_case_default, switch_case_86, switch_case_87, switch_case_88, switch_case_89
dw switch_case_90, switch_case_91, switch_case_92, switch_case_93, switch_case_94, switch_case_95, switch_case_96, switch_case_97, switch_case_98, switch_case_default, switch_case_100
dw switch_case_default, switch_case_default, switch_case_default, switch_case_104, switch_case_105, switch_case_106, switch_case_107, switch_case_108, switch_case_109, switch_case_110, switch_case_default
dw switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_119, switch_case_120, switch_case_121, switch_case_default
dw switch_case_default, switch_case_124, switch_case_125, switch_case_126, switch_case_default, switch_case_128, switch_case_129, switch_case_130, switch_case_default, switch_case_default, switch_case_default
dw switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_default, switch_case_141

PROC    P_CrossSpecialLine_  FAR
PUBLIC  P_CrossSpecialLine_

; todo consider thingpos not on stack. pass in cx.

;void __far P_CrossSpecialLine( int16_t		linenum,int16_t		side,mobj_t __near*	thing,mobj_pos_t __far* thing_pos){

; bp - 2:  unused
; bp - 4:  unused
; bp - 6:  LP segment
; bp - 8:  LP offset

push      cx
push      si
push      di
push      bp
mov       bp, sp
xchg      ax, si  ; si gets linenum.
SHIFT_MACRO shl       si 4


mov       ax, LINES_PHYSICS_SEGMENT
mov       es, ax
push      es ; bp - 2 in case needed
push      si ; bp - 4 in case needed

push      dx ; bp - 6 need to juggle this (side argument) for a second
push      bx ; bp - 8 need to juggle this (mobj argument) for a second
xor       ax, ax
cwd

mov       al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
mov       dl, byte ptr es:[si + LINE_PHYSICS_T.lp_special]
mov       bl, byte ptr es:[si + LINE_PHYSICS_T.lp_tag]
mov       si, word ptr es:[si + LINE_PHYSICS_T.lp_frontsecnum]

xor       bh, bh


test      al, al
je        thing_is_player
mov       di, OFFSET skip_special_mobj_types
push      cs
pop       es
mov       cx, 6 
repne     scasb
jz        exit_p_crossspecialline

mov       cx, 7
xchg      ax, dx
repne     scasb
jz        monser_only_special_ok
jmp       exit_p_crossspecialline

monser_only_special_ok:
xchg      ax, dx
thing_is_player:

sub       dx, 2
cmp       dx, 139
ja        jump_to_done_with_switch_block
sal       dx, 1
mov       di, dx
xchg      ax, bx

pop       es  ; es holds mobj if necessary
pop       cx  ; retrieve side parameter

mov       dx, si
mov       si, -1

; ax is linetag
; bx is mobjtype
; cx is side
; dx is frontsecnum
; si is linespecial (-1)
; es is mobj
; almost everything uses tag in ax.





jmp       word ptr cs:[di + OFFSET cross_special_line_jump_table]
jump_to_done_with_switch_block:
jmp       done_with_switch_block
switch_case_75:
mov       dx, DOOR_CLOSE
jmp       call_do_door_no_si_inc
switch_case_76:
mov       dx, DOOR_CLOSE30THENOPEN
jmp       call_do_door_no_si_inc
switch_case_86:
mov       dx, DOOR_OPEN
jmp       call_do_door_no_si_inc
switch_case_90:
xor       dx, dx ; DOOR_NORMAL
jmp       call_do_door_no_si_inc
switch_case_105:
mov       dx, DOOR_BLAZERAISE
jmp       call_do_door_no_si_inc
switch_case_106:
mov       dx, DOOR_BLAZEOPEN
jmp       call_do_door_no_si_inc
switch_case_107:
mov       dx, DOOR_BLAZECLOSE
jmp       call_do_door_no_si_inc
switch_case_3:
mov       dx, DOOR_CLOSE
jmp       call_do_door_with_si_inc
switch_case_4:
xor       dx, dx
jmp       call_do_door_with_si_inc
switch_case_16:
mov       dx, DOOR_CLOSE30THENOPEN
jmp       call_do_door_with_si_inc
switch_case_108:
mov       dx, DOOR_BLAZERAISE
jmp       call_do_door_with_si_inc
switch_case_109:
mov       dx, DOOR_BLAZEOPEN
jmp       call_do_door_with_si_inc
switch_case_110:
mov       dx, DOOR_BLAZECLOSE
jmp       call_do_door_with_si_inc
switch_case_2:
mov       dx, DOOR_OPEN
call_do_door_with_si_inc:
inc       si ; si becomes 0
call_do_door_no_si_inc:
call      EV_DoDoor_

switch_case_default:
done_with_switch_block:
cmp       si, -1
je        exit_p_crossspecialline

;		line_physics[linenum].special = setlinespecial;

pop       bx  ;  bp - 4
pop       es  ;  bp - 2

xchg      ax, si ; linespecial into ax.

mov       byte ptr es:[bx + LINE_PHYSICS_T.lp_special], al

exit_p_crossspecialline:
LEAVE_MACRO     
pop       di
pop       si
pop       cx
retf      4
switch_case_124:
call      G_SecretExitLevel_
jmp       done_with_switch_block

switch_case_52:
call      G_ExitLevel_
jmp       done_with_switch_block


switch_case_91:
mov       bx, FLOOR_RAISEFLOOR
jmp       call_do_floor_no_si_inc
switch_case_5:
mov       bx, FLOOR_RAISEFLOOR
call_do_floor_with_si_inc:
inc       si ; si becomes 0
call_do_floor_no_si_inc:
call      EV_DoFloor_
jmp       done_with_switch_block

switch_case_19:
xor       bx, bx ; FLOOR_LOWERFLOOR
jmp       call_do_floor_with_si_inc
switch_case_83:
xor       bx, bx ; FLOOR_LOWERFLOOR
jmp       call_do_floor_no_si_inc
switch_case_30:
mov       bx, FLOOR_RAISETOTEXTURE
jmp       call_do_floor_with_si_inc
switch_case_96:
mov       bx, FLOOR_RAISETOTEXTURE
jmp       call_do_floor_no_si_inc
switch_case_36:
mov       bx, FLOOR_TURBOLOWER
jmp       call_do_floor_with_si_inc
switch_case_98:
mov       bx, FLOOR_TURBOLOWER
jmp       call_do_floor_no_si_inc
switch_case_37:
mov       bx, FLOOR_LOWERANDCHANGE
jmp       call_do_floor_with_si_inc
switch_case_84:
mov       bx, FLOOR_LOWERANDCHANGE
jmp       call_do_floor_no_si_inc
switch_case_38:
mov       bx, FLOOR_LOWERFLOORTOLOWEST
jmp       call_do_floor_with_si_inc
switch_case_82:
mov       bx, FLOOR_LOWERFLOORTOLOWEST
jmp       call_do_floor_no_si_inc
switch_case_56:
mov       bx, FLOOR_RAISEFLOORCRUSH
jmp       call_do_floor_with_si_inc
switch_case_94:
mov       bx, FLOOR_RAISEFLOORCRUSH
jmp       call_do_floor_no_si_inc
switch_case_58:
mov       bx, FLOOR_RAISEFLOOR24
jmp       call_do_floor_with_si_inc
switch_case_92:
mov       bx, FLOOR_RAISEFLOOR24
jmp       call_do_floor_no_si_inc
switch_case_59:
mov       bx, FLOOR_RAISEFLOOR24ANDCHANGE
jmp       call_do_floor_with_si_inc
switch_case_93:
mov       bx, FLOOR_RAISEFLOOR24ANDCHANGE
jmp       call_do_floor_no_si_inc
switch_case_119:
mov       bx, FLOOR_RAISEFLOORTONEAREST
jmp       call_do_floor_with_si_inc
switch_case_128:
mov       bx, FLOOR_RAISEFLOORTONEAREST
jmp       call_do_floor_no_si_inc
switch_case_130:
mov       bx, FLOOR_RAISEFLOORTURBO
jmp       call_do_floor_with_si_inc
switch_case_129:
mov       bx, FLOOR_RAISEFLOORTURBO
jmp       call_do_floor_no_si_inc

switch_case_88:
mov       bx, PLATFORM_DOWNWAITUPSTAY
jmp       call_do_plat_no_si_inc
switch_case_10:
mov       bx, PLATFORM_DOWNWAITUPSTAY
call_do_plat_with_si_inc:
inc       si ; si becomes 0
call_do_plat_no_si_inc:
xor       cx, cx
call      EV_DoPlat_
jmp       done_with_switch_block
switch_case_22:
mov       bx, PLATFORM_RAISETONEARESTANDCHANGE
jmp       call_do_plat_with_si_inc
switch_case_95:
mov       bx, PLATFORM_RAISETONEARESTANDCHANGE
jmp       call_do_plat_no_si_inc
switch_case_53:
mov       bx, PLATFORM_PERPETUALRAISE
jmp       call_do_plat_with_si_inc
switch_case_87:
xor       bx, bx ; PLATFORM_PERPETUALRAISE
jmp       call_do_plat_no_si_inc
switch_case_121:
mov       bx, PLATFORM_BLAZEDWUS
jmp       call_do_plat_with_si_inc
switch_case_120:
mov       bx, PLATFORM_BLAZEDWUS
jmp       call_do_plat_no_si_inc

switch_case_77:
mov       dx, CEILING_FASTCRUSHANDRAISE
jmp       call_do_ceiling_no_si_inc
switch_case_6:
mov       dx, CEILING_FASTCRUSHANDRAISE
call_do_ceiling_with_si_inc:
inc       si ; si becomes 0
call_do_ceiling_no_si_inc:
call      EV_DoCeiling_
jmp       done_with_switch_block
switch_case_25:
mov       dx, CEILING_CRUSHANDRAISE
jmp       call_do_ceiling_with_si_inc
switch_case_73:
mov       dx, CEILING_CRUSHANDRAISE
jmp       call_do_ceiling_no_si_inc
switch_case_44:
mov       dx, CEILING_LOWERANDCRUSH
jmp       call_do_ceiling_with_si_inc
switch_case_72:
mov       dx, CEILING_LOWERANDCRUSH
jmp       call_do_ceiling_no_si_inc
switch_case_141:
mov       dx, CEILING_SILENTCRUSHANDRAISE
jmp       call_do_ceiling_with_si_inc



switch_case_8:
inc       si ; si becomes 0
xor       dx, dx ; STAIRS_BUILD8
call_buildstairs:
call      EV_BuildStairs_
jmp       done_with_switch_block
switch_case_100:
mov       dx, STAIRS_TURBO16
jmp       call_buildstairs


switch_case_12:
inc       si ; si becomes 0
switch_case_80:
xor       bx, bx
call_lightchange_dx_1:
mov       dx, 1
call_lightchange:
call      EV_LightChange_
jmp       done_with_switch_block
switch_case_13:
inc       si ; si becomes 0
switch_case_81:
mov       bx, 255
jmp       call_lightchange_dx_1
switch_case_35:
inc       si ; si becomes 0
switch_case_79:
mov       bx, 35
jmp       call_lightchange_dx_1
switch_case_104:
inc       si ; si becomes 0
xor       dx, dx
xor       bx, bx
jmp       call_lightchange


switch_case_17:
inc       si ; si becomes 0
call      EV_StartLightStrobing_
jmp       done_with_switch_block

switch_case_39:
;		EV_Teleport( linetag, side, thing, thing_pos );
do_monster_only_teleport:
inc       si ; si becomes 0
do_monster_only_teleport_no_si_inc:
switch_case_97:
mov       dx, cx
; todo make this not use stack...
push      word ptr [bp + 0Eh]
push      word ptr [bp + 0Ch]
mov       bx, es
call      EV_Teleport_
jmp       done_with_switch_block
switch_case_125:
test      bl, bl
jne       do_monster_only_teleport
jmp       done_with_switch_block
switch_case_126:
test      bl, bl
jne       do_monster_only_teleport_no_si_inc
jmp       done_with_switch_block

switch_case_40:
inc       si ; si becomes 0
mov       bx, ax ; store linetag
mov       cx, dx ; store linefrontsecnum
mov       dx, CEILING_RAISETOHIGHEST
call      EV_DoCeiling_
xchg      ax, bx ; retrieve
mov       dx, cx
mov       bx, FLOOR_LOWERFLOORTOLOWEST
call      EV_DoFloor_
jmp       done_with_switch_block


switch_case_54:
inc       si ; si becomes 0
switch_case_89:
mov       dx, PLAT_FUNC_STOP_PLAT
call      EV_PlatFunc_
jmp       done_with_switch_block

switch_case_57:
inc       si ; si becomes 0
switch_case_74:
call      EV_CeilingCrushStop_
jmp       done_with_switch_block











ENDP


PROC    P_ShootSpecialLine_  FAR
PUBLIC  P_ShootSpecialLine_

PUSHA_NO_AX_OR_BP_MACRO

xchg      ax, si  ; si gets thing
mov       di, dx  ; di gets linenum
mov       bx, dx
mov       dl, byte ptr ds:[si + MOBJ_T.m_mobjtype]  ; cl holds thing type.

mov       bx, word ptr ds:[bx + di + _linebuffer]
mov       ax, LINES_PHYSICS_SEGMENT
mov       es, ax
SHIFT_MACRO shl       bx 2
mov       si, bx

mov       al, byte ptr es:[bx + si + LINE_PHYSICS_T.lp_tag]
mov       cx, word ptr es:[bx + si + LINE_PHYSICS_T.lp_frontsecnum]
mov       bl, byte ptr es:[bx + si + LINE_PHYSICS_T.lp_special]
xor       ah, ah
xor       bh, bh

cmp       dl, 0                 ; PENDING COMPARE
mov       dx, LINES_SEGMENT
mov       es, dx
mov       si, word ptr es:[si + LINE_T.l_sidenum] ; lineside0


; ax linetag
; dx garbage
; bx linespeical
; cl frontsecnum
; si lineside0
; di linenum

je        shoot_thing_is_player
cmp       bl, 46
jne       exit_shootspecialline

; 

shoot_thing_is_player:
cmp       bl, 47
je        case_47
cmp       bl, 46
je        case_46
cmp       bl, 24
jne       exit_shootspecialline
case_24:
push      bx
mov       bx, FLOOR_RAISEFLOOR
mov       dx, cx ; linefrontsecnum
call      EV_DoFloor_
do_change_switch_texture_call_pop_bx:
pop       bx

do_change_switch_texture_call:
xor       ax, ax
push      ax
mov       dx, si
xchg      ax, di
call      P_ChangeSwitchTexture_

exit_shootspecialline:
POPA_NO_AX_OR_BP_MACRO
retf      

case_46:
mov       dx, DOOR_OPEN
call      EV_DoDoor_
jmp       do_change_switch_texture_call

case_47:
push      bx
mov       dx, cx
mov       bx, PLATFORM_RAISETONEARESTANDCHANGE
push      cx
xor       cx, cx
call      EV_DoPlat_
pop       cx
jmp       do_change_switch_texture_call_pop_bx


ENDP



player_in_special_sector_jump_table:
dw  specialsector_switch_block_4, specialsector_switch_block_5, exit_p_playerinspecialsector
dw  specialsector_switch_block_7, exit_p_playerinspecialsector, specialsector_switch_block_9
dw  exit_p_playerinspecialsector, specialsector_switch_block_11, exit_p_playerinspecialsector
dw  exit_p_playerinspecialsector, exit_p_playerinspecialsector, exit_p_playerinspecialsector
dw  specialsector_switch_block_16



ENDP

PROC    P_PlayerInSpecialSector_  NEAR
PUBLIC  P_PlayerInSpecialSector_


PUSHA_NO_AX_OR_BP_MACRO


mov       di, word ptr ds:[_playerMobj]
mov       bx, word ptr ds:[di + MOBJ_T.m_secnum]
SHIFT_MACRO shl       bx 4
mov       ax, SECTORS_SEGMENT
mov       es, ax
xor       ax, ax
mov       dx, word ptr es:[bx + SECTOR_T.sec_floorheight]
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
les       si, dword ptr ds:[_playerMobj_pos]

cmp       dx, word ptr es:[si + MOBJ_POS_T.mp_z + 2]
jne       exit_p_playerinspecialsector
cmp       ax, word ptr es:[si + MOBJ_POS_T.mp_z + 0]
jne       exit_p_playerinspecialsector


mov       al, byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special]
sub       al, 4
cmp       al, 0Ch
ja        exit_p_playerinspecialsector
xor       ah, ah
mov       si, ax
add       si, ax
jmp       word ptr cs:[si + OFFSET player_in_special_sector_jump_table]

specialsector_switch_block_4:
specialsector_switch_block_16:
cmp       word ptr ds:[_player + PLAYER_T.player_powers + (2 * PW_IRONFEET)], 0
je        take_floor_hazard_damage

call      P_Random_
cmp       al, 5
jnb       exit_p_playerinspecialsector

take_floor_hazard_damage:
test      byte ptr ds:[_leveltime], 01Fh
jne       exit_p_playerinspecialsector

mov       cx, 20   
do_floor_damage_and_exit:
xor       dx, dx
mov       ax, word ptr ds:[_playerMobj]
xor       bx, bx
call      P_DamageMobj_
exit_p_playerinspecialsector:
POPA_NO_AX_OR_BP_MACRO
ret       
specialsector_switch_block_5:
cmp       word ptr ds:[_player + PLAYER_T.player_powers + (2 * PW_IRONFEET)], 0
jne       exit_p_playerinspecialsector

test      byte ptr ds:[_leveltime], 01Fh
jne       exit_p_playerinspecialsector

mov       cx, 10
jmp       do_floor_damage_and_exit

specialsector_switch_block_7:
cmp       word ptr ds:[_player + PLAYER_T.player_powers + (2 * PW_IRONFEET)], 0
jne       exit_p_playerinspecialsector
test      byte ptr ds:[_leveltime], 01Fh
jne       exit_p_playerinspecialsector
mov       cx, 5
jmp       do_floor_damage_and_exit

specialsector_switch_block_9:

inc       word ptr ds:[_player + PLAYER_T.player_secretcount]
mov       byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], ah ; zero
POPA_NO_AX_OR_BP_MACRO
ret       
specialsector_switch_block_11:
and       byte ptr ds:[_player + PLAYER_T.player_cheats], (NOT CF_GODMODE)
test      byte ptr ds:[_leveltime], 01Fh
jne       dont_damage_this_tic
mov       cx, 20
xor       dx, dx
mov       ax, word ptr ds:[_playerMobj]
xor       bx, bx

call      P_DamageMobj_
dont_damage_this_tic:
cmp       word ptr ds:[_player + PLAYER_T.player_health], 10
jle       call_exit_level_and_exit
jmp       exit_p_playerinspecialsector_2
call_exit_level_and_exit:
call      G_ExitLevel_
exit_p_playerinspecialsector_2:
POPA_NO_AX_OR_BP_MACRO
ret       


ENDP


PROC    P_UpdateSpecials_  NEAR
PUBLIC  P_UpdateSpecials_


PUSHA_NO_AX_OR_BP_MACRO
push      bp
mov       bp, sp
sub       sp, 4
cmp       byte ptr ds:[_levelTimer], 1
jne       level_timer_check_ok

add       word ptr ds:[_levelTimeCount+0], -1
adc       word ptr ds:[_levelTimeCount+2], -1
mov       ax, word ptr ds:[_levelTimeCount+0]
or        ax, word ptr ds:[_levelTimeCount+2]
jne       level_timer_check_ok
call      G_ExitLevel_
jmp       level_timer_check_ok

level_timer_check_ok:
mov       di, OFFSET _anims
cmp       di, word ptr ds:[_lastanim]
jae       done_with_anims_loop
loop_next_anim_outer:
mov       cx, word ptr ds:[di + P_SPEC_ANIM_T.pspecanim_basepic] ; cx is i
mov       si, cx
mov       dl, byte ptr ds:[di + P_SPEC_ANIM_T.pspecanim_numpics]
xor       dh, dh
add       si, dx  ; end condition in si.
loop_next_anim_inner:

;		for (i = anim->basepic; i < anim->basepic + anim->numpics; i++) {
cmp       cx, si
jae       iter_next_anim_outer

;			pic = anim->basepic + (((leveltime.hu.fracbits >> 3)  + i) % anim->numpics);

mov       ax, word ptr ds:[_leveltime]
SHIFT_MACRO shr       ax 3

add       ax, cx
div       dl
mov       al, ah
cbw
add       ax, word ptr ds:[di + P_SPEC_ANIM_T.pspecanim_basepic]
cmp       byte ptr ds:[di + P_SPEC_ANIM_T.pspecanim_istexture], 0
je        do_flat_translation_lookup

mov       bx, TEXTURETRANSLATION_SEGMENT
mov       es, bx
mov       bx, cx
sal       bx, 1
mov       word ptr es:[bx], ax

iter_next_anim_inner:
inc       cx
jmp       loop_next_anim_inner
do_flat_translation_lookup:
mov       bx, FLATTRANSLATION_SEGMENT
mov       es, bx
mov       bx, cx
mov       byte ptr es:[bx], al
jmp       iter_next_anim_inner

iter_next_anim_outer:
add       di, SIZEOF_P_SPEC_ANIM_T
cmp       di, word ptr ds:[_lastanim]
jb        loop_next_anim_outer

done_with_anims_loop:
xor       cx, cx
cmp       word ptr ds:[_numlinespecials], cx
jle       done_with_line_specials
mov       dx, LINESPECIALLIST_SEGMENT

loop_next_line_special:
mov       bx, cx
sal       bx, 1
mov       es, dx
mov       di, word ptr es:[bx]
SHIFT_MACRO shl       di 4
mov       ax, LINES_PHYSICS_SEGMENT
mov       es, ax
cmp       byte ptr es:[di + LINE_PHYSICS_T.lp_special], 48
jne       not_line_special_48
;    // EFFECT FIRSTCOL SCROLL +
;    sides[lines[linespeciallist_far[i]].sidenum[0]].textureoffset += 1; // todo mod by tex width?

mov       es, dx
mov       bx, word ptr es:[bx]
SHIFT_MACRO shl       bx 2
mov       ax, LINES_SEGMENT
mov       es, ax
mov       bx, word ptr es:[bx + LINE_T.l_sidenum]
SHIFT_MACRO shl       bx 3
mov       ax, SIDES_SEGMENT
mov       es, ax
inc       word ptr es:[bx + SIDE_T.s_textureoffset]
not_line_special_48:
inc       cx

cmp       cx, word ptr ds:[_numlinespecials]
jl        loop_next_line_special

done_with_line_specials:
mov       word ptr [bp - 4], OFFSET _buttonlist
xor       si, si
label_17:
imul      bx, si, 9
cmp       word ptr ds:[bx + OFFSET _buttonlist + BUTTON_T.button_btimer], 0
je        label_15
dec       word ptr ds:[bx + OFFSET _buttonlist + BUTTON_T.button_btimer]
jne       label_15
mov       di, word ptr ds:[bx + _buttonlist]
mov       ax, LINES_SEGMENT
shl       di, 2
mov       es, ax
mov       ax, word ptr es:[di]
mov       dl, byte ptr ds:[bx + OFFSET _buttonlist + BUTTON_T.button_where]
shl       ax, 3
cmp       dl, 2
jne       label_16
mov       dx, SIDES_SEGMENT
mov       di, ax
mov       es, dx
add       di, 2
label_1:
mov       ax, word ptr ds:[bx + OFFSET _buttonlist + BUTTON_T.button_btexture]
mov       word ptr es:[di], ax
label_2:
imul      bx, si, SIZEOF_BUTTON_T
mov       dx, SFX_SWTCHN
mov       cx, 9
mov       ax, word ptr ds:[bx + OFFSET _buttonlist + BUTTON_T.button_soundorg]
mov       di, word ptr [bp - 4]

call      S_StartSoundWithParams_
xor       al, al
push      di
push      ds
pop       es
mov       ah, al
shr       cx, 1
rep stosw 
adc       cx, cx
rep stosb 
pop       di
label_15:
inc       si
add       word ptr [bp - 4], SIZEOF_BUTTON_T
cmp       si, 4
jl        label_17
LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
ret       
label_16:
cmp       dl, 1
jne       label_4
mov       dx, SIDES_SEGMENT
mov       di, ax
mov       es, dx
add       di, 4
jmp       label_1
label_4:
test      dl, dl
jne       label_2
mov       dx, SIDES_SEGMENT
mov       di, ax
mov       es, dx
jmp       label_1

ENDP

COMMENT @


PROC    EV_DoDonut_  NEAR
PUBLIC  EV_DoDonut_


0x0000000000005488:  53                   push      bx
0x0000000000005489:  51                   push      cx
0x000000000000548a:  52                   push      dx
0x000000000000548b:  56                   push      si
0x000000000000548c:  57                   push      di
0x000000000000548d:  55                   push      bp
0x000000000000548e:  89 E5                mov       bp, sp
0x0000000000005490:  81 EC 0A 08          sub       sp, 0x80a
0x0000000000005494:  8D 96 F6 FD          lea       dx, [bp - 0x20a]
0x0000000000005498:  98                   cbw      
0x0000000000005499:  31 DB                xor       bx, bx
0x000000000000549b:  C7 46 F8 FF FF       mov       word ptr [bp - 8], 0xffff
0x00000000000054a0:  E8 1D F4             call      0x48c0
0x00000000000054a3:  31 C9                xor       cx, cx
0x00000000000054a5:  83 BE F6 FD FF       cmp       word ptr [bp - 0x20a], -1
0x00000000000054aa:  74 27                je        0x54d3
0x00000000000054ac:  31 F6                xor       si, si
0x00000000000054ae:  8B 82 F6 FD          mov       ax, word ptr [bp + si - 0x20a]
0x00000000000054b2:  85 C0                test      ax, ax
0x00000000000054b4:  7C 26                jl        0x54dc
0x00000000000054b6:  89 46 FE             mov       word ptr [bp - 2], ax
0x00000000000054b9:  89 C3                mov       bx, ax
0x00000000000054bb:  B8 90 21             mov       ax, SECTORS_SEGMENT
0x00000000000054be:  C1 E3 04             shl       bx, 4
0x00000000000054c1:  8E C0                mov       es, ax
0x00000000000054c3:  83 C6 02             add       si, 2
0x00000000000054c6:  26 8B 47 0C          mov       ax, word ptr es:[bx + 0xc]
0x00000000000054ca:  83 C3 0C             add       bx, 0xc
0x00000000000054cd:  89 82 F4 F9          mov       word ptr [bp + si - 0x60c], ax
0x00000000000054d1:  EB DB                jmp       0x54ae
0x00000000000054d3:  31 C0                xor       ax, ax
0x00000000000054d5:  C9                   LEAVE_MACRO     
0x00000000000054d6:  5F                   pop       di
0x00000000000054d7:  5E                   pop       si
0x00000000000054d8:  5A                   pop       dx
0x00000000000054d9:  59                   pop       cx
0x00000000000054da:  5B                   pop       bx
0x00000000000054db:  C3                   ret       
0x00000000000054dc:  C7 82 F6 F9 FF FF    mov       word ptr [bp + si - 0x60a], 0xffff
0x00000000000054e2:  31 F6                xor       si, si
0x00000000000054e4:  83 BE F6 F9 00       cmp       word ptr [bp - 0x60a], 0
0x00000000000054e9:  7C 21                jl        0x550c
0x00000000000054eb:  8B 82 F6 F9          mov       ax, word ptr [bp + si - 0x60a]
0x00000000000054ef:  89 46 FE             mov       word ptr [bp - 2], ax
0x00000000000054f2:  01 C0                add       ax, ax
0x00000000000054f4:  83 C6 02             add       si, 2
0x00000000000054f7:  89 C3                mov       bx, ax
0x00000000000054f9:  8B 87 50 CA          mov       ax, word ptr ds:[bx - 0x35b0]
0x00000000000054fd:  89 82 F4 F9          mov       word ptr [bp + si - 0x60c], ax
0x0000000000005501:  81 C3 50 CA          add       bx, OFFSET _linebuffer
0x0000000000005505:  83 BA F6 F9 00       cmp       word ptr [bp + si - 0x60a], 0
0x000000000000550a:  7D DF                jge       0x54eb
0x000000000000550c:  BF 00 70             mov       di, LINES_PHYSICS_SEGMENT
0x000000000000550f:  31 C0                xor       ax, ax
0x0000000000005511:  89 C6                mov       si, ax
0x0000000000005513:  01 C6                add       si, ax
0x0000000000005515:  83 BA F6 F9 00       cmp       word ptr [bp + si - 0x60a], 0
0x000000000000551a:  7C 36                jl        0x5552
0x000000000000551c:  BA 4A 2B             mov       dx, 0x2b4a
0x000000000000551f:  8B 9A F6 F9          mov       bx, word ptr [bp + si - 0x60a]
0x0000000000005523:  8B B2 F6 F9          mov       si, word ptr [bp + si - 0x60a]
0x0000000000005527:  8E C2                mov       es, dx
0x0000000000005529:  C1 E3 04             shl       bx, 4
0x000000000000552c:  26 F6 04 04          test      byte ptr es:[si], 4
0x0000000000005530:  75 04                jne       0x5536
0x0000000000005532:  41                   inc       cx
0x0000000000005533:  40                   inc       ax
0x0000000000005534:  EB DB                jmp       0x5511
0x0000000000005536:  89 C6                mov       si, ax
0x0000000000005538:  8E C7                mov       es, di
0x000000000000553a:  29 CE                sub       si, cx
0x000000000000553c:  26 8B 57 0A          mov       dx, word ptr es:[bx + 0xa]
0x0000000000005540:  01 F6                add       si, si
0x0000000000005542:  3B 56 FE             cmp       dx, word ptr [bp - 2]
0x0000000000005545:  75 04                jne       0x554b
0x0000000000005547:  26 8B 57 0C          mov       dx, word ptr es:[bx + 0xc]
0x000000000000554b:  89 92 F6 FD          mov       word ptr [bp + si - 0x20a], dx
0x000000000000554f:  40                   inc       ax
0x0000000000005550:  EB BF                jmp       0x5511
0x0000000000005552:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x0000000000005555:  C1 E0 04             shl       ax, 4
0x0000000000005558:  89 76 FC             mov       word ptr [bp - 4], si
0x000000000000555b:  89 46 FA             mov       word ptr [bp - 6], ax
0x000000000000555e:  8B 76 FC             mov       si, word ptr [bp - 4]
0x0000000000005561:  8B 82 F6 FD          mov       ax, word ptr [bp + si - 0x20a]
0x0000000000005565:  85 C0                test      ax, ax
0x0000000000005567:  7D 03                jge       0x556c
0x0000000000005569:  E9 0B 01             jmp       0x5677
0x000000000000556c:  89 46 F6             mov       word ptr [bp - 0xa], ax
0x000000000000556f:  C1 E0 04             shl       ax, 4
0x0000000000005572:  BA 90 21             mov       dx, SECTORS_SEGMENT
0x0000000000005575:  89 C3                mov       bx, ax
0x0000000000005577:  8E C2                mov       es, dx
0x0000000000005579:  83 C3 0A             add       bx, 0xa
0x000000000000557c:  8D BE F6 F7          lea       di, [bp - 0x80a]
0x0000000000005580:  26 8B 17             mov       dx, word ptr es:[bx]
0x0000000000005583:  89 C3                mov       bx, ax
0x0000000000005585:  89 D1                mov       cx, dx
0x0000000000005587:  26 8B 77 0C          mov       si, word ptr es:[bx + 0xc]
0x000000000000558b:  83 C3 0C             add       bx, 0xc
0x000000000000558e:  01 F6                add       si, si
0x0000000000005590:  01 D1                add       cx, dx
0x0000000000005592:  81 C6 50 CA          add       si, OFFSET _linebuffer
0x0000000000005596:  8D 9E F6 FB          lea       bx, [bp - 0x40a]
0x000000000000559a:  57                   push      di
0x000000000000559b:  8C D8                mov       ax, ds
0x000000000000559d:  8E C0                mov       es, ax
0x000000000000559f:  D1 E9                shr       cx, 1
0x00000000000055a1:  F3 A5                rep movsw 
0x00000000000055a3:  13 C9                adc       cx, cx
0x00000000000055a5:  F3 A4                rep movsb 
0x00000000000055a7:  5F                   pop       di
0x00000000000055a8:  6A 01                push      1
0x00000000000055aa:  8D 86 F6 F7          lea       ax, [bp - 0x80a]
0x00000000000055ae:  89 D1                mov       cx, dx
0x00000000000055b0:  8B 56 F8             mov       dx, word ptr [bp - 8]
0x00000000000055b3:  E8 56 F0             call      getNextSectorList_
0x00000000000055b6:  89 C3                mov       bx, ax
0x00000000000055b8:  89 C2                mov       dx, ax
0x00000000000055ba:  31 C0                xor       ax, ax
0x00000000000055bc:  85 DB                test      bx, bx
0x00000000000055be:  7E 9E                jle       0x555e
0x00000000000055c0:  31 F6                xor       si, si
0x00000000000055c2:  8B 9A F6 FB          mov       bx, word ptr [bp + si - 0x40a]
0x00000000000055c6:  3B 5E FE             cmp       bx, word ptr [bp - 2]
0x00000000000055c9:  75 03                jne       0x55ce
0x00000000000055cb:  E9 9B 00             jmp       0x5669
0x00000000000055ce:  89 DA                mov       dx, bx
0x00000000000055d0:  B8 90 21             mov       ax, SECTORS_SEGMENT
0x00000000000055d3:  C1 E2 04             shl       dx, 4
0x00000000000055d6:  8E C0                mov       es, ax
0x00000000000055d8:  89 D3                mov       bx, dx
0x00000000000055da:  BF 2C 00             mov       di, 0x2c
0x00000000000055dd:  26 8A 47 04          mov       al, byte ptr es:[bx + 4]
0x00000000000055e1:  83 C3 04             add       bx, 4
0x00000000000055e4:  30 E4                xor       ah, ah
0x00000000000055e6:  89 D3                mov       bx, dx
0x00000000000055e8:  89 C1                mov       cx, ax
0x00000000000055ea:  26 8B 1F             mov       bx, word ptr es:[bx]
0x00000000000055ed:  B8 00 28             mov       ax, 0x2800
0x00000000000055f0:  31 D2                xor       dx, dx
0x00000000000055f2:  0E                   
0x00000000000055f3:  E8 34 0F             call      0x652a
0x00000000000055f7:  89 C6                mov       si, ax
0x00000000000055f9:  2D 04 34             sub       ax, 0x3404
0x00000000000055fc:  F7 F7                div       di
0x00000000000055fe:  8B 56 F6             mov       dx, word ptr [bp - 0xa]
0x0000000000005601:  C1 E2 04             shl       dx, 4
0x0000000000005604:  89 D7                mov       di, dx
0x0000000000005606:  89 85 38 DE          mov       word ptr ds:[di - 0x21c8], ax
0x000000000000560a:  C6 04 0B             mov       byte ptr ds:[si], 0xb
0x000000000000560d:  C6 44 04 01          mov       byte ptr ds:[si + 4], 1
0x0000000000005611:  C7 44 09 04 00       mov       word ptr ds:[si + 9], 4
0x0000000000005616:  88 6C 01             mov       byte ptr ds:[si + 1], ch
0x0000000000005619:  88 4C 06             mov       byte ptr ds:[si + 6], cl
0x000000000000561c:  88 6C 05             mov       byte ptr ds:[si + 5], ch
0x000000000000561f:  8B 46 F6             mov       ax, word ptr [bp - 0xa]
0x0000000000005622:  89 5C 07             mov       word ptr ds:[si + 7], bx
0x0000000000005625:  31 D2                xor       dx, dx
0x0000000000005627:  89 44 02             mov       word ptr ds:[si + 2], ax
0x000000000000562a:  B8 00 28             mov       ax, 0x2800
0x000000000000562d:  B9 2C 00             mov       cx, 0x2c
0x0000000000005630:  0E                   
0x0000000000005631:  E8 F6 0E             call      0x652a
0x0000000000005635:  89 C6                mov       si, ax
0x0000000000005637:  2D 04 34             sub       ax, 0x3404
0x000000000000563a:  F7 F1                div       cx
0x000000000000563c:  81 C7 38 DE          add       di, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
0x0000000000005640:  8B 56 FA             mov       dx, word ptr [bp - 6]
0x0000000000005643:  89 D7                mov       di, dx
0x0000000000005645:  89 85 38 DE          mov       word ptr ds:[di - 0x21c8], ax
0x0000000000005649:  C6 04 00             mov       byte ptr ds:[si], 0
0x000000000000564c:  C6 44 01 00          mov       byte ptr ds:[si + 1], 0
0x0000000000005650:  C6 44 04 FF          mov       byte ptr ds:[si + 4], 0xff
0x0000000000005654:  C7 44 09 04 00       mov       word ptr ds:[si + 9], 4
0x0000000000005659:  8B 46 FE             mov       ax, word ptr [bp - 2]
0x000000000000565c:  89 5C 07             mov       word ptr ds:[si + 7], bx
0x000000000000565f:  81 C7 38 DE          add       di, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
0x0000000000005663:  89 44 02             mov       word ptr ds:[si + 2], ax
0x0000000000005666:  E9 F5 FE             jmp       0x555e
0x0000000000005669:  40                   inc       ax
0x000000000000566a:  83 C6 02             add       si, 2
0x000000000000566d:  39 D0                cmp       ax, dx
0x000000000000566f:  7D 03                jge       0x5674
0x0000000000005671:  E9 4E FF             jmp       0x55c2
0x0000000000005674:  E9 E7 FE             jmp       0x555e
0x0000000000005677:  B8 01 00             mov       ax, 1
0x000000000000567a:  C9                   LEAVE_MACRO     
0x000000000000567b:  5F                   pop       di
0x000000000000567c:  5E                   pop       si
0x000000000000567d:  5A                   pop       dx
0x000000000000567e:  59                   pop       cx
0x000000000000567f:  5B                   pop       bx
0x0000000000005680:  C3                   ret    




ENDP

dw 05719h, 05720h, 0572Ch, 0573Bh, 05702h, 05702h, 05702h, 0574Ah, 05751h, 05770h, 05702h, 0577Ch, 0578Eh, 057A0h, 05702h, 05702h, 057ACh

PROC    P_SpawnSpecials_  NEAR
PUBLIC  P_SpawnSpecials_



0x00000000000056a4:  53                   push      bx
0x00000000000056a5:  51                   push      cx
0x00000000000056a6:  52                   push      dx
0x00000000000056a7:  56                   push      si
0x00000000000056a8:  57                   push      di
0x00000000000056a9:  55                   push      bp
0x00000000000056aa:  89 E5                mov       bp, sp
0x00000000000056ac:  83 EC 04             sub       sp, 4
0x00000000000056af:  B8 64 18             mov       ax, 0x1864
0x00000000000056b2:  0E                   
0x00000000000056b3:  E8 4E 1C             call      OFFSET _playerMobj_pos4
0x00000000000056b7:  31 C9                xor       cx, cx
0x00000000000056b9:  31 FF                xor       di, di
0x00000000000056bb:  C6 06 49 20 00       mov       byte ptr ds:[_levelTimer], 0
0x00000000000056c0:  BB CE 05             mov       bx, 0x5ce
0x00000000000056c3:  3B 0F                cmp       cx, word ptr ds:[bx]
0x00000000000056c5:  7C 29                jl        0x56f0
0x00000000000056c7:  31 C0                xor       ax, ax
0x00000000000056c9:  31 C9                xor       cx, cx
0x00000000000056cb:  31 D2                xor       dx, dx
0x00000000000056cd:  A3 4A 1F             mov       word ptr ds:[_numlinespecials], ax
0x00000000000056d0:  BB D0 05             mov       bx, 0x5d0
0x00000000000056d3:  3B 07                cmp       ax, word ptr ds:[bx]
0x00000000000056d5:  7D 61                jge       0x5738
0x00000000000056d7:  BB 00 70             mov       bx, LINES_PHYSICS_SEGMENT
0x00000000000056da:  89 CE                mov       si, cx
0x00000000000056dc:  8E C3                mov       es, bx
0x00000000000056de:  26 8A 5C 0F          mov       bl, byte ptr es:[si + 0xf]
0x00000000000056e2:  83 C6 0F             add       si, 0xf
0x00000000000056e5:  80 FB 30             cmp       bl, 0x30
0x00000000000056e8:  74 6E                je        0x5758
0x00000000000056ea:  83 C1 10             add       cx, 0x10
0x00000000000056ed:  40                   inc       ax
0x00000000000056ee:  EB E0                jmp       0x56d0
0x00000000000056f0:  89 7E FC             mov       word ptr [bp - 4], di
0x00000000000056f3:  8D B5 3E DE          lea       si, [di - 0x21c2]
0x00000000000056f7:  8A 04                mov       al, byte ptr ds:[si]
0x00000000000056f9:  C7 46 FE 00 00       mov       word ptr [bp - 2], 0
0x00000000000056fe:  84 C0                test      al, al
0x0000000000005700:  75 06                jne       0x5708
0x0000000000005702:  83 C7 10             add       di, 0x10
0x0000000000005705:  41                   inc       cx
0x0000000000005706:  EB B8                jmp       0x56c0
0x0000000000005708:  FE C8                dec       al
0x000000000000570a:  3C 10                cmp       al, 0x10
0x000000000000570c:  77 F4                ja        0x5702
0x000000000000570e:  30 E4                xor       ah, ah
0x0000000000005710:  89 C3                mov       bx, ax
0x0000000000005712:  01 C3                add       bx, ax
0x0000000000005714:  2E FF A7 82 56       jmp       word ptr cs:[bx + 0x5682]
0x0000000000005719:  89 C8                mov       ax, cx
0x000000000000571b:  E8 A6 E7             call      P_SpawnLightFlash_
0x000000000000571e:  EB E2                jmp       0x5702
0x0000000000005720:  BA 0F 00             mov       dx, 0xf
0x0000000000005723:  89 C8                mov       ax, cx
0x0000000000005725:  31 DB                xor       bx, bx
0x0000000000005727:  E8 48 E8             call      P_SpawnStrobeFlash_
0x000000000000572a:  EB D6                jmp       0x5702
0x000000000000572c:  BA 23 00             mov       dx, 0x23
0x000000000000572f:  89 C8                mov       ax, cx
0x0000000000005731:  31 DB                xor       bx, bx
0x0000000000005733:  E8 3C E8             call      P_SpawnStrobeFlash_
0x0000000000005736:  EB CA                jmp       0x5702
0x0000000000005738:  E9 7D 00             jmp       0x57b8
0x000000000000573b:  BA 0F 00             mov       dx, 0xf
0x000000000000573e:  89 C8                mov       ax, cx
0x0000000000005740:  31 DB                xor       bx, bx
0x0000000000005742:  E8 2D E8             call      P_SpawnStrobeFlash_
0x0000000000005745:  C6 04 04             mov       byte ptr ds:[si], 4
0x0000000000005748:  EB B8                jmp       0x5702
0x000000000000574a:  89 C8                mov       ax, cx
0x000000000000574c:  E8 11 EA             call      P_SpawnGlowingLight_
0x000000000000574f:  EB B1                jmp       0x5702
0x0000000000005751:  BB 20 01             mov       bx, 0x120
0x0000000000005754:  FF 07                inc       word ptr ds:[bx]
0x0000000000005756:  EB AA                jmp       0x5702
0x0000000000005758:  BB D8 4C             mov       bx, LINESPECIALLIST_SEGMENT
0x000000000000575b:  89 D6                mov       si, dx
0x000000000000575d:  8E C3                mov       es, bx
0x000000000000575f:  83 C2 02             add       dx, 2
0x0000000000005762:  FF 06 4A 1F          inc       word ptr ds:[_numlinespecials]
0x0000000000005766:  26 89 04             mov       word ptr es:[si], ax
0x0000000000005769:  83 C1 10             add       cx, 0x10
0x000000000000576c:  40                   inc       ax
0x000000000000576d:  E9 60 FF             jmp       0x56d0
0x0000000000005770:  89 C8                mov       ax, cx
0x0000000000005772:  E8 9D D0             call      P_SpawnDoorCloseIn30_
0x0000000000005775:  83 C7 10             add       di, 0x10
0x0000000000005778:  41                   inc       cx
0x0000000000005779:  E9 44 FF             jmp       0x56c0
0x000000000000577c:  BB 01 00             mov       bx, 1
0x000000000000577f:  BA 23 00             mov       dx, 0x23
0x0000000000005782:  89 C8                mov       ax, cx
0x0000000000005784:  E8 EB E7             call      P_SpawnStrobeFlash_
0x0000000000005787:  83 C7 10             add       di, 0x10
0x000000000000578a:  41                   inc       cx
0x000000000000578b:  E9 32 FF             jmp       0x56c0
0x000000000000578e:  BB 01 00             mov       bx, 1
0x0000000000005791:  BA 0F 00             mov       dx, 0xf
0x0000000000005794:  89 C8                mov       ax, cx
0x0000000000005796:  E8 D9 E7             call      P_SpawnStrobeFlash_
0x0000000000005799:  83 C7 10             add       di, 0x10
0x000000000000579c:  41                   inc       cx
0x000000000000579d:  E9 20 FF             jmp       0x56c0
0x00000000000057a0:  89 C8                mov       ax, cx
0x00000000000057a2:  E8 B5 D0             call      P_SpawnDoorRaiseIn5Mins_
0x00000000000057a5:  83 C7 10             add       di, 0x10
0x00000000000057a8:  41                   inc       cx
0x00000000000057a9:  E9 14 FF             jmp       0x56c0
0x00000000000057ac:  89 C8                mov       ax, cx
0x00000000000057ae:  E8 7F E6             call      P_SpawnFireFlicker_
0x00000000000057b1:  83 C7 10             add       di, 0x10
0x00000000000057b4:  41                   inc       cx
0x00000000000057b5:  E9 08 FF             jmp       0x56c0
0x00000000000057b8:  B9 3C 00             mov       cx, 0x3c
0x00000000000057bb:  BF 00 06             mov       di, 0x600
0x00000000000057be:  30 C0                xor       al, al
0x00000000000057c0:  57                   push      di
0x00000000000057c1:  1E                   push      ds
0x00000000000057c2:  07                   pop       es
0x00000000000057c3:  8A E0                mov       ah, al
0x00000000000057c5:  D1 E9                shr       cx, 1
0x00000000000057c7:  F3 AB                rep stosw 
0x00000000000057c9:  13 C9                adc       cx, cx
0x00000000000057cb:  F3 AA                rep stosb 
0x00000000000057cd:  5F                   pop       di
0x00000000000057ce:  B9 3C 00             mov       cx, 0x3c
0x00000000000057d1:  BF 6C 1D             mov       di, 0x1d6c
0x00000000000057d4:  57                   push      di
0x00000000000057d5:  1E                   push      ds
0x00000000000057d6:  07                   pop       es
0x00000000000057d7:  8A E0                mov       ah, al
0x00000000000057d9:  D1 E9                shr       cx, 1
0x00000000000057db:  F3 AB                rep stosw 
0x00000000000057dd:  13 C9                adc       cx, cx
0x00000000000057df:  F3 AA                rep stosb 
0x00000000000057e1:  5F                   pop       di
0x00000000000057e2:  B9 24 00             mov       cx, 0x24
0x00000000000057e5:  BF 40 1D             mov       di, _buttonlist
0x00000000000057e8:  57                   push      di
0x00000000000057e9:  1E                   push      ds
0x00000000000057ea:  07                   pop       es
0x00000000000057eb:  8A E0                mov       ah, al
0x00000000000057ed:  D1 E9                shr       cx, 1
0x00000000000057ef:  F3 AB                rep stosw 
0x00000000000057f1:  13 C9                adc       cx, cx
0x00000000000057f3:  F3 AA                rep stosb 
0x00000000000057f5:  5F                   pop       di
0x00000000000057f6:  C9                   LEAVE_MACRO     
0x00000000000057f7:  5F                   pop       di
0x00000000000057f8:  5E                   pop       si
0x00000000000057f9:  5A                   pop       dx
0x00000000000057fa:  59                   pop       cx
0x00000000000057fb:  5B                   pop       bx
0x00000000000057fc:  CB                   retf      

ENDP

@



PROC    P_SPEC_ENDMARKER_ 
PUBLIC  P_SPEC_ENDMARKER_
ENDP


END
