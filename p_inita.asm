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

EXTRN  Z_QuickMapPhysics_:FAR
EXTRN  Z_QuickMapRender_:FAR
EXTRN  Z_QuickMapRenderPlanes_:FAR
EXTRN  Z_QuickMapUndoFlatCache_:FAR
EXTRN  FixedDivWholeA_:FAR
EXTRN  FixedMul_:FAR
EXTRN  FixedMul_:FAR
EXTRN  CopyString13_:NEAR
EXTRN fread_:FAR
EXTRN fseek_:FAR
EXTRN fopen_:FAR
EXTRN fclose_:FAR
EXTRN locallib_far_fread_:FAR
EXTRN DEBUG_PRINT_NOARG_CS_:NEAR
EXTRN R_TextureNumForName_:NEAR
 
.DATA



.CODE

EXTRN  _doomdata_bin_string:NEAR

PROC    P_INIT_STARTMARKER_ NEAR
PUBLIC  P_INIT_STARTMARKER_
ENDP


NUMSWITCHDEFS = 41
BAD_TEXTURE = 0FFFFh

PROC    P_InitSwitchList_ NEAR
PUBLIC  P_InitSwitchList_

PUSHA_NO_AX_OR_BP_MACRO
push   bp
mov    bp, sp
sub    sp, (NUMSWITCHDEFS * (SIZE SWITCHLIST_T))

mov   ax, OFFSET _doomdata_bin_string
call  CopyString13_
mov   dx, OFFSET  _fopen_rb_argument
call  fopen_        ; fopen("DOOMDATA.BIN", "rb"); 
mov   di, ax ; di stores fp

xor   dx, dx  ; SEEK_SET
mov   bx, SWITCH_DOOMDATA_OFFSET AND 0FFFFh
mov   cx, SWITCH_DOOMDATA_OFFSET SHR 16
call  fseek_  ;    fseek(fp, SWITCH_DOOMDATA_OFFSET, SEEK_SET);

;fread(alphSwitchList, sizeof(switchlist_t), NUMSWITCHDEFS, fp);
mov   ax, sp
mov   cx, di ; fp
mov   dx, SIZE SWITCHLIST_T
mov   bx, NUMSWITCHDEFS
call  fread_

xchg  ax, di
call  fclose_

;	if (registered){
;		episode = 2;
;	} else if (commercial){
;		episode = 3;
;	}


mov   bx, 1  ; episode
xor   ax, ax
cmp   byte ptr ds:[_registered], al
je    not_ep_2
inc   bx
jmp   got_ep
not_ep_2:
cmp   byte ptr ds:[_commercial], al
je    not_ep_3
inc   bx
inc   bx
not_ep_3:
got_ep:


;	for (index = 0, i = 0; i < MAXSWITCHES; i++) {
;		if (!alphSwitchList[i].episode) {
;			numswitches = index >> 1;
;			switchlist[index] = BAD_TEXTURE;
;			break;
;		}
;
;		if (alphSwitchList[i].episode <= episode) {
;
;			switchlist[index++] = R_TextureNumForName(alphSwitchList[i].name1);
;			switchlist[index++] = R_TextureNumForName(alphSwitchList[i].name2);
;		}
;	}

mov   di, OFFSET _switchlist
mov   si, sp

mov   dx, ss

mov   cx, NUMSWITCHDEFS


; es:di = switchlist[index]
; ds:si = alphSwitchList
; bx = episode

iter_next_switch:
cmp   word ptr ds:[si + SWITCHLIST_T.switchlist_episode], 0
je    episode_undefined

cmp   word ptr ds:[si + SWITCHLIST_T.switchlist_episode], bx
jg    skip_switch_for_episode

lea   ax, [si + SWITCHLIST_T.switchlist_name1]
call  R_TextureNumForName_
mov   es, dx
stosw
lea   ax, [si + SWITCHLIST_T.switchlist_name2]
call  R_TextureNumForName_
mov   es, dx
stosw

skip_switch_for_episode:
add   si, SIZE SWITCHLIST_T
loop  iter_next_switch

done_with_switches:
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret

episode_undefined:
mov   ds:[di], BAD_TEXTURE
sub   di, OFFSET _switchlist
SHIFT_MACRO shr       di 2
mov   word ptr ds:[_numswitches], di
jmp   done_with_switches





ENDP



PROC    P_INIT_ENDMARKER_ NEAR
PUBLIC  P_INIT_ENDMARKER_
ENDP
END