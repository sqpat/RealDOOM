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

.MODEL  medium
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

;=================================
.DATA


EXTRN _playingtime:DWORD
EXTRN _playingdriver:DWORD
EXTRN _snd_MusicVolume:BYTE
EXTRN _playingstate:BYTE

.CODE

ZERO_BYTE MACRO 
    db 0
ENDM


ADLIB_PORT = 0388h

PAN_RIGHT_CHANNEL = 020h
PAN_LEFT_CHANNEL  = 010h
PAN_BOTH_CHANNELS = 030h

REGISTER_VOLUME     = 040h
REGISTER_MODULATOR  = 020h
REGISTER_ATTACK     = 060h
REGISTER_SUSTAIN    = 080h
REGISTER_FEEDBACK   = 0C0h
REGISTER_WAVEFORM   = 0E0h
REGISTER_KEY_ON_OFF = 0B0h



MIDI_NOTE_OFF	 = 0x80	; release key,   <note#>, <velocity>
MIDI_NOTE_ON	 = 0x90	; press key,     <note#>, <velocity>
MIDI_NOTE_TOUCH	 = 0xA0	; key after-touch, <note#>, <velocity>
MIDI_CONTROL	 = 0xB0	; control change, <controller>, <value>
MIDI_PATCH	     = 0xC0	; patch change,  <patch#>
MIDI_CHAN_TOUCH	 = 0xD0	; channel after-touch (??), <channel#>
MIDI_PITCH_WHEEL = 0xE0	; pitch wheel,   <bottom>, <top 7 bits>
MIDI_EVENT_MASK	 = 0xF0	; value to mask out the event number, not a command!

CTRLPATCH 			= 0
CTRLBANK 			= 1
CTRLMODULATION 		= 2
CTRLVOLUME 			= 3
CTRLPAN 			= 4
CTRLEXPRESSION		= 5
CTRLREVERB			= 6
CTRLCHORUS			= 7
CTRLSUSTAINPEDAL	= 8
CTRLSOFTPEDAL		= 9
CTRLSOUNDSOFF		= 10
CTRLNOTESOFF		= 11
CTRLMONO			= 12
CTRLPOLY			= 13
CTRLRESETCTRLS		= 14

CONTROLLER_DATA_SIZE = 010h

NUM_CONTROLLERS     = 10

DEFAULT_PITCH_BEND   = 080h
CH_FREE              = 080h
CH_SUSTAIN           = 002h
SIZEOF_OP2INSTRENTRY = 024h
MAX_MUSIC_CHANNELS   = 16
OPL3CHANNELS         = 18

PLAYING_PERCUSSION_MASK     = 08000h

MAX_INSTRUMENTS = 175
MAX_INSTRUMENTS_PER_TRACK = 01Ch ; largest in doom1 or doom2


ADLIBINSTRUMENTLIST_SEGMENT = 0CC00h
;ADLIBCHANNELS_SEGMENT       = 0CC3Fh
INSTRUMENTLOOKUP_SEGMENT    = 0CC51h

SIZE_ADLIBCHANNELS          = 0120h

PLAYING_PERCUSSION_MASK     = 08000h

MIDIDRIVERDATA_SEGMENT      = 0CC00h
MIDI_CHANNELS_SEGMENT       = 0CC0Eh
MIDI_PERC                   = 9
MIDITIME_SEGMENT            = 0CC12h

SIZE_MIDICHANNELS           = 010h
SIZE_MIDITIME               = 040h


MIDIDATA_CONTROLLERS_OFFSET = 000h
MIDIDATA_LAST_VOLUME_OFFSET = 0A0h
MIDIDATA_PITCH_WHEEL_OFFSET = 0B0h
MIDIDATA_REALCHANNEL_OFFSET = 0C0h
MIDIDATA_PERCUSSIONS_OFFSET = 0D0h
	


PROC  SM_SBMID_STARTMARKER_
PUBLIC  SM_SBMID_STARTMARKER_

ENDP

PROC  calcVolume_   NEAR
PUBLIC  calcVolume_


0x0000000000000000:  C1 E0 02          shl       ax, 2
0x0000000000000003:  30 F6             xor       dh, dh
0x0000000000000005:  F7 E2             mul       dx
0x0000000000000007:  88 E0             mov       al, ah
0x0000000000000009:  88 D4             mov       ah, dl
0x000000000000000b:  3D 7F 00          cmp       ax, 07Fh
0x000000000000000e:  76 02             jbe       return_vol_as_is
0x0000000000000010:  B0 7F             mov       al, 07Fh
return_vol_as_is:
0x0000000000000012:  CB                ret  


ENDP

PROC  stopChannel_    NEAR
PUBLIC  stopChannel_


0x0000000000000014:  53                push      bx
0x0000000000000015:  51                push      cx
0x0000000000000016:  52                push      dx
0x0000000000000017:  56                push      si
0x0000000000000018:  88 C1             mov       cl, al
0x000000000000001a:  BB 7F 00          mov       bx, 07Fh
0x000000000000001d:  80 C9 B0          or        cl, MIDI_CONTROL
0x0000000000000020:  BA 78 00          mov       dx, 120
0x0000000000000023:  30 ED             xor       ch, ch
0x0000000000000025:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x0000000000000029:  89 C8             mov       ax, cx
0x000000000000002b:  FF 5C 34          call      dword ptr [si + 034h]            ; todo sendmidi
0x000000000000002e:  BB 7F 00          mov       bx, 07Fh
0x0000000000000031:  BA 79 00          mov       dx, 121
0x0000000000000034:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]   ; todo sendmidi
0x0000000000000038:  89 C8             mov       ax, cx
0x000000000000003a:  FF 5C 34          call      dword ptr [si + 034h]
0x000000000000003d:  5E                pop       si
0x000000000000003e:  5A                pop       dx
0x000000000000003f:  59                pop       cx
0x0000000000000040:  5B                pop       bx
0x0000000000000041:  CB                ret      


ENDP

PROC  findFreeMIDIChannel_  NEAR
PUBLIC  findFreeMIDIChannel_

0x0000000000000042:  53                push      bx
0x0000000000000043:  51                push      cx
0x0000000000000044:  52                push      dx
0x0000000000000045:  56                push      si
0x0000000000000046:  57                push      di
0x0000000000000047:  55                push      bp
0x0000000000000048:  89 E5             mov       bp, sp
0x000000000000004a:  83 EC 02          sub       sp, 2
0x000000000000004d:  88 46 FE          mov       byte ptr [bp - 2], al
0x0000000000000050:  88 C1             mov       cl, al
0x0000000000000052:  B8 01 00          mov       ax, 1
0x0000000000000055:  D3 E0             shl       ax, cl
0x0000000000000057:  85 06 A0 0D       test      ax, PLAYING_PERCUSSION_MASK
0x000000000000005b:  75 48             jne       return_perc
0x000000000000005d:  BA 0E CC          mov       dx, MIDI_CHANNELS_SEGMENT
0x0000000000000060:  30 C0             xor       al, al
loop_music_channels:
0x0000000000000062:  88 C3             mov       bl, al
0x0000000000000064:  8E C2             mov       es, dx
0x0000000000000066:  30 FF             xor       bh, bh
0x0000000000000068:  26 80 3F FF       cmp       byte ptr es:[bx], 0FFh
0x000000000000006c:  74 40             je        set_found_channel
0x000000000000006e:  FE C0             inc       al
0x0000000000000070:  3C 10             cmp       al, MAX_MUSIC_CHANNELS
0x0000000000000072:  72 EE             jb        loop_music_channels
0x0000000000000074:  8B 0E A4 0D       mov       cx, word ptr [_playingtime]
0x0000000000000078:  8B 16 A6 0D       mov       dx, word ptr [_playingtime + 2]
0x000000000000007c:  B4 FF             mov       ah, 0FFh
0x000000000000007e:  BE 12 CC          mov       si, MIDITIME_SEGMENT
0x0000000000000081:  30 C0             xor       al, al
loop_channels_find_oldest:
0x0000000000000083:  88 C3             mov       bl, al
0x0000000000000085:  30 FF             xor       bh, bh
0x0000000000000087:  8E C6             mov       es, si
0x0000000000000089:  C1 E3 02          shl       bx, 2
0x000000000000008c:  26 3B 57 02       cmp       dx, word ptr es:[bx + 2]
0x0000000000000090:  77 24             ja        update_time_oldest
0x0000000000000092:  75 05             jne       inc_loop_channels_find_oldest
0x0000000000000094:  26 3B 0F          cmp       cx, word ptr es:[bx]
0x0000000000000097:  77 1D             ja        update_time_oldest
inc_loop_channels_find_oldest:
0x0000000000000099:  FE C0             inc       al
0x000000000000009b:  3C 10             cmp       al, MAX_MUSIC_CHANNELS
0x000000000000009d:  73 22             jae       done_looping_channels_find_oldest
0x000000000000009f:  3C 09             cmp       al, MIDI_PERC
0x00000000000000a1:  75 E0             jne       loop_channels_find_oldest
0x00000000000000a3:  EB F4             jmp       inc_loop_channels_find_oldest
return_perc:
0x00000000000000a5:  B0 09             mov       al, MIDI_PERC
return_found_channel:
0x00000000000000a7:  C9                LEAVE_MACRO     
0x00000000000000a8:  5F                pop       di
0x00000000000000a9:  5E                pop       si
0x00000000000000aa:  5A                pop       dx
0x00000000000000ab:  59                pop       cx
0x00000000000000ac:  5B                pop       bx
0x00000000000000ad:  CB                ret      
set_found_channel:
0x00000000000000ae:  8A 66 FE          mov       ah, byte ptr [bp - 2]
0x00000000000000b1:  26 88 27          mov       byte ptr es:[bx], ah
0x00000000000000b4:  EB F1             jmp       return_found_channel
update_time_oldest:
0x00000000000000b6:  88 C4             mov       ah, al
0x00000000000000b8:  26 8B 0F          mov       cx, word ptr es:[bx]
0x00000000000000bb:  26 8B 57 02       mov       dx, word ptr es:[bx + 2]
0x00000000000000bf:  EB D8             jmp       inc_loop_channels_find_oldest
done_looping_channels_find_oldest:
0x00000000000000c1:  88 E2             mov       dl, ah
0x00000000000000c3:  80 FC FF          cmp       ah, 0FFh
0x00000000000000c6:  74 2B             je        dont_stop_channel:
0x00000000000000c8:  BF 0E CC          mov       di, MIDI_CHANNELS_SEGMENT
0x00000000000000cb:  88 E3             mov       bl, ah
0x00000000000000cd:  8E C7             mov       es, di
0x00000000000000cf:  30 FF             xor       bh, bh
0x00000000000000d1:  26 8A 07          mov       al, byte ptr es:[bx]
0x00000000000000d4:  30 E4             xor       ah, ah
0x00000000000000d6:  B9 00 CC          mov       cx, MIDIDRIVERDATA_SEGMENT
0x00000000000000d9:  89 C6             mov       si, ax
0x00000000000000db:  8E C1             mov       es, cx
0x00000000000000dd:  81 C6 C0 00       add       si, MIDIDATA_REALCHANNEL_OFFSET
0x00000000000000e1:  89 D8             mov       ax, bx
0x00000000000000e3:  26 C6 04 FF       mov       byte ptr es:[si], 0FFh
0x00000000000000e7:  0E                push      cs
0x00000000000000e8:  E8 29 FF          call      stopChannel_
0x00000000000000eb:  8E C7             mov       es, di
0x00000000000000ed:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000000f0:  26 88 07          mov       byte ptr es:[bx], al
dont_stop_channel:
0x00000000000000f3:  88 D0             mov       al, dl
0x00000000000000f5:  C9                LEAVE_MACRO     
0x00000000000000f6:  5F                pop       di
0x00000000000000f7:  5E                pop       si
0x00000000000000f8:  5A                pop       dx
0x00000000000000f9:  59                pop       cx
0x00000000000000fa:  5B                pop       bx
0x00000000000000fb:  CB                ret



ENDP

PROC  updateControllers_    NEAR
PUBLIC  updateControllers_

0x00000000000000fc:  53                push      bx
0x00000000000000fd:  51                push      cx
0x00000000000000fe:  52                push      dx
0x00000000000000ff:  56                push      si
0x0000000000000100:  57                push      di
0x0000000000000101:  55                push      bp
0x0000000000000102:  89 E5             mov       bp, sp
0x0000000000000104:  83 EC 04          sub       sp, 4
0x0000000000000107:  88 46 FE          mov       byte ptr [bp - 2], al
0x000000000000010a:  88 C3             mov       bl, al
0x000000000000010c:  B8 00 CC          mov       ax, MIDIDRIVERDATA_SEGMENT
0x000000000000010f:  30 FF             xor       bh, bh
0x0000000000000111:  8E C0             mov       es, ax
0x0000000000000113:  8D B7 C0 00       lea       si, [bx + MIDIDATA_REALCHANNEL_OFFSET]
0x0000000000000117:  26 8A 2C          mov       ch, byte ptr es:[si]
0x000000000000011a:  84 ED             test      ch, ch
0x000000000000011c:  7D 07             jge       controller_not_zero
0x000000000000011e:  C9                LEAVE_MACRO     
0x000000000000011f:  5F                pop       di
0x0000000000000120:  5E                pop       si
0x0000000000000121:  5A                pop       dx
0x0000000000000122:  59                pop       cx
0x0000000000000123:  5B                pop       bx
0x0000000000000124:  CB                ret      

controller_not_zero:
0x0000000000000125:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x0000000000000129:  88 E8             mov       al, ch
0x000000000000012b:  26 8A 17          mov       dl, byte ptr es:[bx]
0x000000000000012e:  0C C0             or        al, MIDI_PATCH
0x0000000000000130:  30 F6             xor       dh, dh
0x0000000000000132:  30 DB             xor       bl, bl
0x0000000000000134:  30 E4             xor       ah, ah
0x0000000000000136:  B1 01             mov       cl, 1
0x0000000000000138:  FF 5C 34          call      dword ptr [si + 034h]
0x000000000000013b:  88 E8             mov       al, ch
0x000000000000013d:  0C B0             or        al, MIDI_CONTROL           ; is this right?
0x000000000000013f:  88 46 FC          mov       byte ptr [bp - 4], al
controller_loop:
0x0000000000000142:  88 C8             mov       al, cl
0x0000000000000144:  30 E4             xor       ah, ah
0x0000000000000146:  BA 00 CC          mov       dx, MIDIDRIVERDATA_SEGMENT
0x0000000000000149:  89 C3             mov       bx, ax
0x000000000000014b:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x000000000000014e:  C1 E3 04          shl       bx, 4
0x0000000000000151:  8E C2             mov       es, dx
0x0000000000000153:  01 C3             add       bx, ax
0x0000000000000155:  26 8A 07          mov       al, byte ptr es:[bx]
0x0000000000000158:  80 F9 03          cmp       cl, CTRLVOLUME
0x000000000000015b:  75 54             jne       not_volume_control
0x000000000000015d:  80 FD 09          cmp       ch, MIDI_PERC
0x0000000000000160:  75 44             jne       go_calculate_volume:

increment_controller_loop:
0x0000000000000162:  FE C1             inc       cl
0x0000000000000164:  80 F9 0A          cmp       cl, NUM_CONTROLLERS
0x0000000000000167:  72 D9             jb        controller_loop
0x0000000000000169:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x000000000000016c:  BA 00 CC          mov       dx, MIDIDRIVERDATA_SEGMENT
0x000000000000016f:  30 E4             xor       ah, ah
0x0000000000000171:  8E C2             mov       es, dx
0x0000000000000173:  89 C3             mov       bx, ax
0x0000000000000175:  26 8A 97 B0 00    mov       dl, byte ptr es:[bx + MIDIDATA_PITCH_WHEEL_OFFSET]       ; pitchWheel

; calculate pitch
0x000000000000017a:  88 D0             mov       al, dl
0x000000000000017c:  D1 F8             sar       ax, 1
0x0000000000000182:  24 7F             and       al, 07Fh
0x0000000000000184:  F6 C2 01          ror       dl, 1      ; 1s bit into 080h bit
0x0000000000000189:  BA 80 00          and       dx, 080h

0x000000000000018c:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]

0x0000000000000190:  88 C3             mov       bl, al
0x0000000000000192:  88 E8             mov       al, ch
0x0000000000000194:  30 F6             xor       dh, dh
0x0000000000000196:  0C E0             or        al, MIDI_PITCH_WHEEL
0x0000000000000198:  30 FF             xor       bh, bh
0x000000000000019a:  30 E4             xor       ah, ah
0x000000000000019c:  FF 5C 34          call      dword ptr [si + 034h]
0x000000000000019f:  C9                LEAVE_MACRO     
0x00000000000001a0:  5F                pop       di
0x00000000000001a1:  5E                pop       si
0x00000000000001a2:  5A                pop       dx
0x00000000000001a3:  59                pop       cx
0x00000000000001a4:  5B                pop       bx
0x00000000000001a5:  CB                ret
go_calculate_volume:
0x00000000000001a6:  88 C2             mov       dl, al
0x00000000000001a8:  A0 2B 1F          mov       al, byte ptr [_snd_MusicVolume]
0x00000000000001ab:  30 F6             xor       dh, dh
0x00000000000001ae:  E8 4F FE          call      calcVolume_
not_volume_control:
0x00000000000001b1:  88 C3             mov       bl, al
0x00000000000001b3:  88 C8             mov       al, cl
0x00000000000001b5:  30 E4             xor       ah, ah
0x00000000000001b7:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x00000000000001bb:  89 C7             mov       di, ax
0x00000000000001bd:  30 FF             xor       bh, bh
0x00000000000001bf:  8A 95 B0 0D       mov       dl, byte ptr [di + _MUS2MIDIctrl]
0x00000000000001c3:  8A 46 FC          mov       al, byte ptr [bp - 4]

0x00000000000001c6:  30 F6             xor       dh, dh
0x00000000000001c8:  FF 5C 34          call      dword ptr [si + 034h]
0x00000000000001cb:  EB 95             jmp       increment_controller_loop




ENDP

PROC  MIDIplayNote_    FAR
PUBLIC  MIDIplayNote_

0x0000000000000200:  51                push      cx
0x0000000000000201:  56                push      si
0x0000000000000202:  55                push      bp
0x0000000000000203:  89 E5             mov       bp, sp
0x0000000000000205:  83 EC 02          sub       sp, 2
0x0000000000000208:  88 C5             mov       ch, al
0x000000000000020a:  88 56 FE          mov       byte ptr [bp - 2], dl
0x000000000000020d:  30 E4             xor       ah, ah
0x000000000000020f:  BA 00 CC          mov       dx, MIDIDRIVERDATA_SEGMENT
0x0000000000000212:  89 C6             mov       si, ax
0x0000000000000214:  8E C2             mov       es, dx
0x000000000000021a:  26 8A 3C          mov       bh, byte ptr es:[si + MIDIDATA_REALCHANNEL_OFFSET]
0x0000000000000223:  80 FB FF          cmp       bl, -1
0x0000000000000226:  74 03             je        use_last_volume
0x00000000000002b3:  26 88 1C          mov       byte ptr es:[si], bl
0x00000000000002b6:  E9 75 FF          jmp       got_volume
go_find_channel:
0x00000000000002b9:  88 EA             mov       dl, ch
0x00000000000002bb:  30 F6             xor       dh, dh
0x00000000000002bd:  89 D0             mov       ax, dx
0x00000000000002c0:  E8 7F FD          call      findFreeMIDIChannel_
0x00000000000002c3:  88 C7             mov       bh, al
0x00000000000002c5:  84 C0             test      al, al
0x00000000000002c7:  7C E6             jl        exit_playnote
0x00000000000002c9:  BE 00 CC          mov       si, MIDIDRIVERDATA_SEGMENT
0x00000000000002cc:  8E C6             mov       es, si
0x00000000000002ce:  89 D6             mov       si, dx
0x00000000000002d0:  26 88 84 C0 00    mov       byte ptr es:[si + MIDIDATA_REALCHANNEL_OFFSET], al
0x00000000000002d5:  89 D0             mov       ax, dx
0x00000000000002dc:  E8 1D FE          call      updateControllers_
0x00000000000002df:  E9 53 FF          jmp       channel_positive

use_last_volume:
0x000000000000022b:  26 8A 1C          mov       bl, byte ptr es:[si+MIDIDATA_LAST_VOLUME_OFFSET]
got_volume:
0x000000000000022e:  84 FF             test      bh, bh
0x0000000000000230:  7D 03             jnge      go_find_channel

channel_positive:
0x0000000000000235:  80 FF 09          cmp       bh, MIDI_PERC
0x0000000000000238:  75 3F             jne       play_not_percussion
0x000000000000023a:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x000000000000023d:  BA 00 CC          mov       dx, MIDIDRIVERDATA_SEGMENT
0x0000000000000240:  30 E4             xor       ah, ah
0x0000000000000242:  8E C2             mov       es, dx
0x0000000000000244:  89 C6             mov       si, ax
0x0000000000000246:  88 C1             mov       cl, al
0x0000000000000248:  B0 01             mov       al, 1
0x000000000000024a:  80 E1 07          and       cl, 7
0x000000000000024d:  C1 FE 03          sar       si, 3
0x0000000000000250:  D2 E0             shl       al, cl
0x0000000000000252:  88 E9             mov       cl, ch

0x0000000000000258:  30 ED             xor       ch, ch
0x000000000000025a:  26 08 04          or        byte ptr es:[si+MIDIDATA_PERCUSSIONS_OFFSET], al
0x000000000000025d:  89 CE             mov       si, cx
0x000000000000025f:  26 8A 54 30       mov       dl, byte ptr es:[si + CTRLVOLUME * CONTROLLER_DATA_SIZE]
0x0000000000000263:  A0 2B 1F          mov       al, byte ptr [_snd_MusicVolume]
0x0000000000000266:  30 F6             xor       dh, dh


0x000000000000026c:  E8 91 FD          call      calcVolume_
0x0000000000000273:  F6 E4             mul       bl
0x0000000000000271:  B2 7F             mov       dl, 127
0x0000000000000275:  F6 F2             div       dl
0x0000000000000277:  88 C3             mov       bl, al

play_not_percussion:
0x0000000000000279:  88 F8             mov       al, bh
0x000000000000027b:  98                cbw      
0x000000000000027c:  89 C6             mov       si, ax
0x000000000000027e:  B8 12 CC          mov       ax, MIDITIME_SEGMENT
0x0000000000000281:  C1 E6 02          shl       si, 2
0x0000000000000284:  8E C0             mov       es, ax
0x0000000000000286:  8B 16 A4 0D       mov       dx, word ptr [_playingtime]
0x000000000000028a:  A1 A6 0D          mov       ax, word ptr [_playingtime + 2]
0x000000000000028d:  26 89 14          mov       word ptr es:[si], dx
0x0000000000000290:  88 F9             mov       cl, bh
0x0000000000000292:  26 89 44 02       mov       word ptr es:[si + 2], ax
0x0000000000000296:  8A 56 FE          mov       dl, byte ptr [bp - 2]
0x0000000000000299:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x000000000000029d:  88 D8             mov       al, bl
0x000000000000029f:  80 C9 90          or        cl, MIDI_NOTE_ON
0x00000000000002a2:  30 E4             xor       ah, ah
0x00000000000002a4:  30 F6             xor       dh, dh
0x00000000000002a6:  30 ED             xor       ch, ch
0x00000000000002a8:  89 C3             mov       bx, ax
0x00000000000002aa:  89 C8             mov       ax, cx
0x00000000000002ac:  FF 5C 34          call      dword ptr [si + 034h]
exit_playnote:
0x00000000000002af:  C9                LEAVE_MACRO     
0x00000000000002b0:  5E                pop       si
0x00000000000002b1:  59                pop       cx
0x00000000000002b2:  CB                retf      


ENDP

PROC  MIDIplayNote_    FAR
PUBLIC  MIDIplayNote_

0x00000000000002e2:  53                push      bx
0x00000000000002e3:  51                push      cx
0x00000000000002e4:  56                push      si
0x00000000000002e5:  88 D6             mov       dh, dl
0x00000000000002e7:  BB 00 CC          mov       bx, MIDIDRIVERDATA_SEGMENT
0x00000000000002ea:  30 E4             xor       ah, ah
0x00000000000002ec:  8E C3             mov       es, bx
0x00000000000002ee:  89 C3             mov       bx, ax
0x00000000000002f0:  26 8A 97 C0 00    mov       dl, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]
0x00000000000002f9:  84 D2             test      dl, dl
0x00000000000002fb:  7C 4F             jl        exit_releasenote
0x00000000000002fd:  80 FA 09          cmp       dl, MIDI_PERC
0x0000000000000300:  75 19             jne       release_non_percussion
0x0000000000000302:  88 F0             mov       al, dh
0x0000000000000304:  88 F1             mov       cl, dh
0x0000000000000306:  89 C3             mov       bx, ax
0x0000000000000308:  80 E1 07          and       cl, 7
0x000000000000030b:  B0 01             mov       al, 1
0x000000000000030d:  C1 FB 03          sar       bx, 3
0x0000000000000310:  D2 E0             shl       al, cl
0x0000000000000316:  F6 D0             not       al
0x0000000000000318:  26 20 07          and       byte ptr es:[bx+MIDIDATA_PERCUSSIONS_OFFSET], al
release_non_percussion:
0x000000000000031b:  88 D0             mov       al, dl
0x000000000000031d:  98                cbw      
0x000000000000031e:  89 C3             mov       bx, ax
0x0000000000000320:  B8 12 CC          mov       ax, MIDITIME_SEGMENT
0x0000000000000323:  C1 E3 02          shl       bx, 2
0x0000000000000326:  8E C0             mov       es, ax
0x0000000000000328:  A1 A4 0D          mov       ax, word ptr [_playingtime]
0x000000000000032b:  8B 0E A6 0D       mov       cx, word ptr [_playingtime + 2]
0x000000000000032f:  26 89 07          mov       word ptr es:[bx], ax
0x0000000000000332:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x0000000000000336:  26 89 4F 02       mov       word ptr es:[bx + 2], cx
0x000000000000033a:  BB 7F 00          mov       bx, 127
0x000000000000033d:  88 F1             mov       cl, dh
0x000000000000033f:  88 D0             mov       al, dl
0x0000000000000341:  30 ED             xor       ch, ch
0x0000000000000343:  0C 80             or        al, MIDI_NOTE_OFF
0x0000000000000345:  89 CA             mov       dx, cx
0x0000000000000347:  30 E4             xor       ah, ah
0x0000000000000349:  FF 5C 34          call      dword ptr [si + 034h]
exit_releasenote:
0x000000000000034c:  5E                pop       si
0x000000000000034d:  59                pop       cx
0x000000000000034e:  5B                pop       bx
0x000000000000034f:  CB                retf      


ENDP

PROC  MIDIpitchWheel_    FAR
PUBLIC  MIDIpitchWheel_

0x0000000000000350:  53                push      bx
0x0000000000000351:  51                push      cx
0x0000000000000352:  56                push      si
0x0000000000000353:  88 C3             mov       bl, al
0x0000000000000355:  88 D0             mov       al, dl
0x0000000000000357:  30 FF             xor       bh, bh
0x0000000000000359:  BA 00 CC          mov       dx, MIDIDRIVERDATA_SEGMENT
0x0000000000000360:  8E C2             mov       es, dx
0x0000000000000366:  26 8A 14          mov       dl, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]
0x0000000000000369:  26 88 07          mov       byte ptr es:[bx + MIDIDATA_PITCH_WHEEL_OFFSET], al
0x000000000000036c:  84 D2             test      dl, dl
0x000000000000036e:  7C 47             jl        exit_pitchwheel
0x0000000000000370:  88 C3             mov       bl, al
0x0000000000000372:  30 FF             xor       bh, bh
0x0000000000000374:  D1 FB             sar       bx, 1
0x0000000000000376:  88 DE             mov       dh, bl
0x0000000000000378:  80 E6 7F          and       dh, 07Fh
0x000000000000037b:  A8 01             ror       al, 1
0x000000000000037b:  A8 01             xchg      ax, cx
0x000000000000037f:  B9 80 00          and       cx, 080h       ; cx gets al low bit ? 080h : 000h
0x0000000000000382:  88 D0             mov       al, dl
0x0000000000000384:  98                cbw      
0x0000000000000385:  89 C3             mov       bx, ax
0x0000000000000387:  B8 12 CC          mov       ax, MIDITIME_SEGMENT
0x000000000000038a:  C1 E3 02          shl       bx, 2
0x000000000000038d:  8E C0             mov       es, ax
0x000000000000038f:  A1 A4 0D          mov       ax, word ptr [_playingtime]
0x0000000000000392:  8B 36 A6 0D       mov       si, word ptr [_playingtime + 2]
0x0000000000000396:  26 89 07          mov       word ptr es:[bx], ax
0x0000000000000399:  26 89 77 02       mov       word ptr es:[bx + 2], si
0x000000000000039d:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x00000000000003a1:  88 F3             mov       bl, dh
0x00000000000003a3:  88 C8             mov       al, cl
0x00000000000003a5:  88 D1             mov       cl, dl
0x00000000000003a7:  30 FF             xor       bh, bh
0x00000000000003a9:  80 C9 E0          or        cl, MIDI_PITCH_WHEEL
0x00000000000003ac:  30 E4             xor       ah, ah
0x00000000000003ae:  30 ED             xor       ch, ch
0x00000000000003b0:  89 C2             mov       dx, ax
0x00000000000003b2:  89 C8             mov       ax, cx
0x00000000000003b4:  FF 5C 34          call      dword ptr [si + 034h]
exit_pitchwheel:
0x00000000000003b7:  5E                pop       si
0x00000000000003b8:  59                pop       cx
0x00000000000003b9:  5B                pop       bx
0x00000000000003ba:  CB                retf      

ENDP

PROC  MIDIchangeControl_    FAR
PUBLIC  MIDIchangeControl_


0x00000000000003c0:  51                push      cx
0x00000000000003c1:  56                push      si
0x00000000000003c2:  57                push      di
0x00000000000003c3:  55                push      bp
0x00000000000003c4:  89 E5             mov       bp, sp
0x00000000000003c6:  83 EC 02          sub       sp, 2
0x00000000000003c9:  88 C6             mov       dh, al
0x00000000000003cb:  88 D7             mov       bh, dl
0x00000000000003cd:  B9 00 CC          mov       cx, MIDIDRIVERDATA_SEGMENT
0x00000000000003d0:  30 E4             xor       ah, ah
0x00000000000003d2:  8E C1             mov       es, cx
0x00000000000003d4:  89 C6             mov       si, ax
0x00000000000003d6:  26 8A 8C C0 00    mov       cl, byte ptr es:[si + MIDIDATA_REALCHANNEL_OFFSET]
0x00000000000003df:  80 FA 0A          cmp       dl, NUM_CONTROLLERS
0x00000000000003e2:  72 66             jnb       done_recording_controller_value
record_controller_value:
0x000000000000044a:  88 56 FE          mov       byte ptr [bp - 2], dl
0x000000000000044d:  88 66 FF          mov       byte ptr [bp - 1], ah
0x0000000000000450:  8B 76 FE          mov       si, word ptr [bp - 2]
0x0000000000000453:  C1 E6 04          shl       si, 4
0x0000000000000456:  01 C6             add       si, ax
0x0000000000000458:  26 88 1C          mov       byte ptr es:[si], bl

done_recording_controller_value:
0x00000000000003e4:  84 C9             test      cl, cl
0x00000000000003e6:  7C 5D             jl        exit_changecontrol
0x00000000000003e8:  88 C8             mov       al, cl
0x00000000000003ea:  98                cbw      
0x00000000000003eb:  89 C6             mov       si, ax
0x00000000000003ed:  B8 12 CC          mov       ax, MIDITIME_SEGMENT
0x00000000000003f0:  C1 E6 02          shl       si, 2
0x00000000000003f3:  8E C0             mov       es, ax
0x00000000000003f5:  8B 3E A4 0D       mov       di, word ptr [_playingtime]
0x00000000000003f9:  A1 A6 0D          mov       ax, word ptr [_playingtime + 2]
0x00000000000003fc:  26 89 3C          mov       word ptr es:[si], di
0x00000000000003ff:  26 89 44 02       mov       word ptr es:[si + 2], ax
0x0000000000000403:  84 FF             test      bh, bh
0x0000000000000405:  74 56             je        do_patch_instrument
0x0000000000000407:  80 FF 0E          cmp       bh, CTRLRESETCTRLS
0x000000000000040a:  77 39             ja        exit_changecontrol
0x000000000000040c:  74 61             je        do_reset_ctrls
0x000000000000040e:  80 FF 03          cmp       bh, CTRLVOLUME
0x0000000000000411:  75 14             jne       do_generic_control
do_volume_control:
0x0000000000000413:  80 F9 09          cmp       cl, MIDI_PERC
0x0000000000000416:  74 2D             je        exit_changecontrol
0x0000000000000418:  88 DA             mov       dl, bl
0x000000000000041a:  A0 2B 1F          mov       al, byte ptr [_snd_MusicVolume]
0x000000000000041d:  30 F6             xor       dh, dh
0x000000000000041f:  30 E4             xor       ah, ah
0x0000000000000421:  0E                push      cs
0x0000000000000422:  E8 DB FB          call      calcVolume_
0x0000000000000425:  88 C3             mov       bl, al
do_generic_control:
0x0000000000000427:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x000000000000042b:  88 D8             mov       al, bl
0x000000000000042d:  80 C9 B0          or        cl, MIDI_CONTROL
0x0000000000000430:  88 FB             mov       bl, bh
0x0000000000000432:  30 E4             xor       ah, ah
0x0000000000000434:  30 FF             xor       bh, bh
0x0000000000000436:  30 ED             xor       ch, ch
0x0000000000000438:  8A 97 B0 0D       mov       dl, byte ptr [bx + _MUS2MIDIctrl]
0x000000000000043c:  89 C3             mov       bx, ax
0x000000000000043e:  30 F6             xor       dh, dh
0x0000000000000440:  89 C8             mov       ax, cx
send_midi_and_exit:
0x0000000000000442:  FF 5C 34          call      dword ptr [si + 034h]
exit_changecontrol:
0x0000000000000445:  C9                LEAVE_MACRO     
0x0000000000000446:  5F                pop       di
0x0000000000000447:  5E                pop       si
0x0000000000000448:  59                pop       cx
0x0000000000000449:  CB                retf      

do_patch_instrument:
0x000000000000045d:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x0000000000000461:  88 C8             mov       al, cl
0x0000000000000463:  88 DA             mov       dl, bl
0x0000000000000465:  0C C0             or        al, MIDI_PATCH
0x0000000000000467:  30 F6             xor       dh, dh
0x0000000000000469:  30 DB             xor       bl, bl
0x000000000000046b:  30 E4             xor       ah, ah
0x000000000000046d:  EB D3             jmp       send_midi_and_exit
do_reset_ctrls:
0x0000000000000471:  30 E4             xor       ax, ax
0x000000000000046f:  88 F0             mov       al, dh
0x0000000000000476:  89 C6             mov       si, ax
0x0000000000000473:  BA 00 CC          mov       ax, MIDIDRIVERDATA_SEGMENT
0x0000000000000478:  8E C2             mov       es, ax
0x0000000000000471:  30 E4             xor       ax, ax
0x000000000000047d:  26 88 24          mov       byte ptr es:[si + CTRLBANK * CONTROLLER_DATA_SIZE], al
0x0000000000000485:  26 88 24          mov       byte ptr es:[si + CTRLMODULATION * CONTROLLER_DATA_SIZE], al
0x000000000000048d:  26 C6 04 40       mov       byte ptr es:[si + CTRLPAN * CONTROLLER_DATA_SIZE], 64
0x0000000000000496:  26 C6 04 7F       mov       byte ptr es:[si + CTRLEXPRESSION * CONTROLLER_DATA_SIZE], 127
0x00000000000004a0:  26 88 24          mov       byte ptr es:[si + CTRLSUSTAINPEDAL * CONTROLLER_DATA_SIZE], al
0x00000000000004a9:  26 88 24          mov       byte ptr es:[si + CTRLSOFTPEDAL * CONTROLLER_DATA_SIZE], al
0x00000000000004b2:  26 C6 04 80       mov       byte ptr es:[si + MIDIDATA_PITCH_WHEEL_OFFSET], DEFAULT_PITCH_BEND
0x00000000000004b6:  E9 6E FF          jmp       do_generic_control

ENDP

PROC  MIDIplayMusic_    FAR
PUBLIC  MIDIplayMusic_

;    FAR_memset((void __far*) (mididriverData->percussions), 0, sizeof(uint8_t) * (128/8));


0x00000000000004ba:  53                push      bx
0x00000000000004bb:  51                push      cx
0x00000000000004bc:  52                push      dx
0x00000000000004bd:  56                push      si
0x00000000000004be:  57                push      di
0x00000000000004bf:  B9 10 00          mov       cx, 010h / 2
0x00000000000004c2:  BF D0 00          mov       di, 0D0h
0x00000000000004c5:  31 D2             mov       ax, MIDIDRIVERDATA_SEGMENT
0x00000000000004c9:  8E C2             mov       es, ax
0x00000000000004c7:  30 C0             xor       ax, ax
0x00000000000004d0:  F3 AB             rep stosw 
0x00000000000004d7:  30 D2             mov       bx, ax  ; zero out

loop_ready_channels:

; todo make this a 16 byte string in cs and rep movsw over and over

0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLPATCH        * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLBANK         * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLMODULATION   * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLVOLUME       * CONTROLLER_DATA_SIZE], 127
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLPAN          * CONTROLLER_DATA_SIZE], 64
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLEXPRESSION   * CONTROLLER_DATA_SIZE], 127
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLREVERB       * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLCHORUS       * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLMODULATION   * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLSUSTAINPEDAL * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + CTRLSOFTPEDAL    * CONTROLLER_DATA_SIZE], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + MIDIDATA_LAST_VOLUME_OFFSET], al
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + MIDIDATA_PITCH_WHEEL_OFFSET], DEFAULT_PITCH_BEND
0x00000000000004e9:  26 88 77 F0       mov       byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET], 0FFh
0x000000000000054e:  FE C2             inc       bl
0x0000000000000554:  80 FA 10          cmp       bl, 0x10
0x0000000000000557:  7C 83             jl        loop_ready_channels

0x0000000000000559:  BB 7F 00          mov       bx, 127
0x000000000000055c:  B8 B9 00          mov       ax, MIDI_CONTROL OR MIDI_PERC
0x000000000000055f:  8A 16 B3 0D       mov       dl, 7   ; volume control
0x0000000000000563:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x0000000000000567:  30 F6             xor       dh, dh
0x0000000000000569:  FF 5C 34          call      dword ptr [si + 034h]

0x000000000000056c:  B8 B9 00          mov       ax, MIDI_CONTROL OR MIDI_PERC
0x000000000000056f:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x0000000000000573:  8A 16 BE 0D       mov       dl, 121  ; byte ptr [_MUS2MIDIctrl + e]
0x0000000000000577:  31 DB             xor       bx, bx
0x0000000000000579:  30 F6             xor       dh, dh
0x000000000000057b:  FF 5C 34          call      dword ptr [si + 034h]

0x000000000000057e:  5F                pop       di
0x000000000000057f:  5E                pop       si
0x0000000000000580:  5A                pop       dx
0x0000000000000581:  59                pop       cx
0x0000000000000582:  5B                pop       bx
0x0000000000000583:  CB                retf      



ENDP



PROC  MIDIpauseMusic_    FAR
PUBLIC  MIDIpauseMusic_
ENDP
; just calls stop music, fall thru

PROC  MIDIstopMusic_    FAR
PUBLIC  MIDIstopMusic_


0x0000000000000584:  53                push      bx
0x0000000000000585:  51                push      cx
0x0000000000000586:  52                push      dx
0x0000000000000587:  56                push      si
0x0000000000000588:  57                push      di
0x0000000000000589:  55                push      bp
0x000000000000058a:  89 E5             mov       bp, sp
0x000000000000058c:  83 EC 02          sub       sp, 2
0x000000000000058f:  C6 46 FE 00       mov       byte ptr [bp - 2], 0
0x0000000000000593:  BF 89 00          mov       di, MIDI_NOTE_OFF OR MIDI_PERC
loop_stop_channels:
0x0000000000000596:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000599:  BA 00 CC          mov       dx, MIDIDRIVERDATA_SEGMENT
0x000000000000059c:  98                cbw      
0x000000000000059d:  8E C2             mov       es, dx
0x000000000000059f:  89 C3             mov       bx, ax
0x00000000000005a1:  26 8A 87 C0 00    mov       al, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]
0x00000000000005aa:  84 C0             test      al, al
0x00000000000005ac:  7C 3E             jl        inc_loop_stop_channels
0x00000000000005ae:  3C 09             cmp       al, MIDI_PERC
0x00000000000005b0:  75 4B             jne       stop_non_perc_channel
0x00000000000005b2:  30 ED             xor       ch, ch
loop_stop_channels_perc:
0x00000000000005b4:  88 EA             mov       dl, ch
0x00000000000005b6:  30 F6             xor       dh, dh
0x00000000000005b8:  B8 00 CC          mov       ax, MIDIDRIVERDATA_SEGMENT
0x00000000000005bb:  89 D3             mov       bx, dx
0x00000000000005bd:  8E C0             mov       es, ax
0x00000000000005bf:  C1 FB 03          sar       bx, 3
0x00000000000005c2:  88 E9             mov       cl, ch
0x00000000000005c4:  81 C3 D0 00       add       bx, MIDIDATA_PERCUSSIONS_OFFSET
0x00000000000005c8:  80 E1 07          and       cl, 7
0x00000000000005cb:  26 8A 07          mov       al, byte ptr es:[bx]
0x00000000000005ce:  BB 01 00          mov       bx, 1
0x00000000000005d1:  30 E4             xor       ah, ah
0x00000000000005d3:  D3 E3             shl       bx, cl
0x00000000000005d5:  85 D8             test      ax, bx
0x00000000000005d7:  74 0C             je        inc_loop_stop_channels_perc
0x00000000000005d9:  BB 7F 00          mov       bx, 127
0x00000000000005dc:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x00000000000005e0:  89 F8             mov       ax, di
0x00000000000005e2:  FF 5C 34          call      dword ptr [si + 034h]
inc_loop_stop_channels_perc:
0x00000000000005e5:  FE C5             inc       ch
0x00000000000005e7:  80 FD 80          cmp       ch, 128
0x00000000000005ea:  72 C8             jb        loop_stop_channels_perc

inc_loop_stop_channels:
0x00000000000005ec:  FE 46 FE          inc       byte ptr [bp - 2]
0x00000000000005ef:  80 7E FE 10       cmp       byte ptr [bp - 2], MAX_MUSIC_CHANNELS
0x00000000000005f3:  7C A1             jl        loop_stop_channels
0x00000000000005f5:  C9                LEAVE_MACRO     
0x00000000000005f6:  5F                pop       di
0x00000000000005f7:  5E                pop       si
0x00000000000005f8:  5A                pop       dx
0x00000000000005f9:  59                pop       cx
0x00000000000005fa:  5B                pop       bx
0x00000000000005fc:  CB                retf      
stop_non_perc_channel:
0x00000000000005fd:  30 E4             xor       ah, ah
0x00000000000005ff:  0E                push      cs
0x0000000000000600:  E8 11 FA          call      stopChannel_
0x0000000000000603:  EB E7             jmp       inc_loop_stop_channels


PROC MIDIchangeSystemVolume_  FAR
PUBLIC MIDIchangeSystemVolume_

0x0000000000000606:  80 3E 9E 0D 02    cmp       byte ptr [_playingstate], 2
0x000000000000060b:  74 01             je        actually_change_system_volume
0x000000000000060d:  CB                retf      

actually_change_system_volume:
0x000000000000060e:  30 E4             xor       ah, ah
0x0000000000000610:  53                push      bx
0x0000000000000611:  51                push      cx
0x0000000000000612:  52                push      dx
0x0000000000000613:  56                push      si
0x0000000000000614:  55                push      bp
0x0000000000000615:  89 E5             mov       bp, sp
0x0000000000000617:  83 EC 02          sub       sp, 2
0x000000000000061a:  88 46 FE          mov       byte ptr [bp - 2], al
0x000000000000061d:  30 C9             xor       cl, cl

loop_change_system_volume:
0x0000000000000620:  88 C8             mov       al, cl
0x0000000000000622:  BA 00 CC          mov       dx, MIDIDRIVERDATA_SEGMENT
0x0000000000000625:  98                cbw      
0x0000000000000626:  8E C2             mov       es, dx
0x0000000000000628:  89 C3             mov       bx, ax
0x000000000000062a:  26 8A AF C0 00    mov       ch, byte ptr es:[bx + MIDIDATA_REALCHANNEL_OFFSET]

0x0000000000000633:  84 ED             test      ch, ch
0x0000000000000635:  7C 08             jl        inc_loop_change_system_volume
0x0000000000000637:  80 FD 09          cmp       ch, MIDI_PERC
0x000000000000063a:  74 03             je        inc_loop_change_system_volume
; inlined sendSystemVolume
0x00000000000001d1:  89 C3             mov       bx, ax
0x00000000000001d3:  8B 36 9A 0D       mov       si, word ptr [_playingdriver]
0x00000000000001d7:  26 8A 57 30       mov       dl, byte ptr es:[bx + CTRLVOLUME * CONTROLLER_DATA_SIZE]
0x00000000000001db:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000001de:  30 F6             xor       dh, dh
0x00000000000001e0:  30 E4             xor       ah, ah

0x00000000000001e6:  E8 17 FE          call      calcVolume_

0x00000000000001e9:  8A 16 B3 0D       mov       dl, 7          ; byte ptr [_MUS2MIDIctrl + CTRLVOLUME]
0x00000000000001ed:  88 C3             mov       bl, al
0x00000000000001ef:  88 E8             mov       al, ch
0x00000000000001f1:  30 FF             xor       bh, bh
0x00000000000001f3:  0C B0             or        al, MIDI_CONTROL
0x00000000000001f5:  30 F6             xor       dh, dh
0x00000000000001f7:  30 E4             xor       ah, ah
0x00000000000001f9:  FF 5C 34          call      dword ptr [si + 034h]
inc_loop_change_system_volume:
0x000000000000063f:  FE C1             inc       cl
0x0000000000000641:  80 F9 10          cmp       cl, MAX_MUSIC_CHANNELS
0x0000000000000644:  7C DA             jl        loop_change_system_volume

0x0000000000000646:  C9                LEAVE_MACRO     
0x0000000000000647:  5E                pop       si
0x0000000000000648:  5A                pop       dx
0x0000000000000649:  59                pop       cx
0x000000000000064a:  5B                pop       bx
ENDP



PROC  MIDIresumeMusic_    FAR
PUBLIC  MIDIresumeMusic_


0x000000000000064b:  CB                retf    

ENDP



PROC  MIDIinitDriver_    FAR
PUBLIC  MIDIinitDriver_

0x000000000000064d:  51                push      cx
0x000000000000064f:  57                push      di
0x0000000000000650:  B9 10 00          mov       cx, SIZE_MIDICHANNELS / 2
0x0000000000000655:  BA 0E CC          mov       ax, MIDI_CHANNELS_SEGMENT
0x000000000000065a:  8E C2             mov       es, ax
0x0000000000000653:  B0 FF             mov       ax, 0FFFFh
0x0000000000000658:  31 FF             xor       di, di
0x0000000000000664:  F3 AB             rep       stosw 
0x000000000000065c:  BB 09 00          mov       di, MIDI_PERC
0x000000000000066b:  B9 40 00          mov       cx, SIZE_MIDITIME / 2
0x0000000000000671:  26 C6 07 80       mov       byte ptr es:[di], 0x80
0x000000000000066e:  BA 12 CC          mov       ax, MIDITIME_SEGMENT
0x0000000000000677:  8E C2             mov       es, ax
0x0000000000000675:  30 C0             xor       ax, ax
0x0000000000000675:  30 C0             mov       di, ax
0x000000000000067e:  F3 AB             rep       stosw 
0x0000000000000685:  5F                pop       di
0x0000000000000687:  59                pop       cx
0x0000000000000689:  CB                retf      

ENDP

;;;; END OF GENERIC MIDI STUFF. 
;;;; FOLLOWING IS SBMIDI


0x000000000000068a:  00 00             add       byte ptr [bx + si], al
0x000000000000068c:  00 00             add       byte ptr [bx + si], al
0x000000000000068e:  00 00             add       byte ptr [bx + si], al
0x0000000000000690:  53                push      bx
0x0000000000000691:  52                push      dx
0x0000000000000692:  88 C7             mov       bh, al
0x0000000000000694:  B3 FF             mov       bl, 0xff
0x0000000000000696:  8B 16 AA 0D       mov       dx, word ptr [0xdaa]
0x000000000000069a:  83 C2 0C          add       dx, 0xc
0x000000000000069d:  EC                in        al, dx
0x000000000000069e:  2A E4             sub       ah, ah
0x00000000000006a0:  A8 80             test      al, 0x80
0x00000000000006a2:  74 04             je        0x6a8
0x00000000000006a4:  FE CB             dec       bl
0x00000000000006a6:  75 EE             jne       0x696
0x00000000000006a8:  84 DB             test      bl, bl
0x00000000000006aa:  74 22             je        0x6ce
0x00000000000006ac:  8B 16 AA 0D       mov       dx, word ptr [0xdaa]
0x00000000000006b0:  B0 38             mov       al, 0x38
0x00000000000006b2:  83 C2 0C          add       dx, 0xc
0x00000000000006b5:  B3 FF             mov       bl, 0xff
0x00000000000006b7:  EE                out       dx, al
0x00000000000006b8:  8B 16 AA 0D       mov       dx, word ptr [0xdaa]
0x00000000000006bc:  83 C2 0C          add       dx, 0xc
0x00000000000006bf:  EC                in        al, dx
0x00000000000006c0:  2A E4             sub       ah, ah
0x00000000000006c2:  A8 80             test      al, 0x80
0x00000000000006c4:  74 04             je        0x6ca
0x00000000000006c6:  FE CB             dec       bl
0x00000000000006c8:  75 EE             jne       0x6b8
0x00000000000006ca:  84 DB             test      bl, bl
0x00000000000006cc:  75 05             jne       0x6d3
0x00000000000006ce:  B0 FF             mov       al, 0xff
0x00000000000006d0:  5A                pop       dx
0x00000000000006d1:  5B                pop       bx
0x00000000000006d2:  CB                retf      
0x00000000000006d3:  8B 16 AA 0D       mov       dx, word ptr [0xdaa]
0x00000000000006d7:  88 F8             mov       al, bh
0x00000000000006d9:  83 C2 0C          add       dx, 0xc
0x00000000000006dc:  EE                out       dx, al
0x00000000000006dd:  30 F8             xor       al, bh
0x00000000000006df:  5A                pop       dx
0x00000000000006e0:  5B                pop       bx
0x00000000000006e1:  CB                retf      
0x00000000000006e2:  53                push      bx
0x00000000000006e3:  89 C3             mov       bx, ax
0x00000000000006e5:  C6 06 AC 0D 00    mov       byte ptr [0xdac], 0
0x00000000000006ea:  FA                cli       
0x00000000000006eb:  4A                dec       dx
0x00000000000006ec:  83 FA FF          cmp       dx, -1
0x00000000000006ef:  75 06             jne       0x6f7
0x00000000000006f1:  FB                sti       
0x00000000000006f2:  FC                cld       
0x00000000000006f3:  31 C0             xor       ax, ax
0x00000000000006f5:  5B                pop       bx
0x00000000000006f6:  CB                retf      
0x00000000000006f7:  8A 07             mov       al, byte ptr [bx]
0x00000000000006f9:  30 E4             xor       ah, ah
0x00000000000006fb:  43                inc       bx
0x00000000000006fc:  0E                push      cs
0x00000000000006fd:  E8 90 FF          call      0x690
0x0000000000000700:  EB E9             jmp       0x6eb
0x0000000000000702:  88 D6             mov       dh, dl
0x0000000000000704:  88 C2             mov       dl, al
0x0000000000000706:  80 E2 F0          and       dl, 0xf0
0x0000000000000709:  80 FA 80          cmp       dl, 0x80
0x000000000000070c:  75 06             jne       0x714
0x000000000000070e:  24 0F             and       al, 0xf
0x0000000000000710:  30 DB             xor       bl, bl
0x0000000000000712:  0C 90             or        al, 0x90
0x0000000000000714:  FA                cli       
0x0000000000000715:  3A 06 AC 0D       cmp       al, byte ptr [0xdac]
0x0000000000000719:  74 09             je        0x724
0x000000000000071b:  A2 AC 0D          mov       byte ptr [0xdac], al
0x000000000000071e:  30 E4             xor       ah, ah
0x0000000000000720:  0E                push      cs
0x0000000000000721:  E8 6C FF          call      0x690
0x0000000000000724:  88 F0             mov       al, dh
0x0000000000000726:  30 E4             xor       ah, ah
0x0000000000000728:  0E                push      cs
0x0000000000000729:  E8 64 FF          call      0x690
0x000000000000072c:  80 FA C0          cmp       dl, 0xc0
0x000000000000072f:  74 0D             je        0x73e
0x0000000000000731:  80 FA D0          cmp       dl, 0xd0
0x0000000000000734:  74 08             je        0x73e
0x0000000000000736:  30 FF             xor       bh, bh
0x0000000000000738:  89 D8             mov       ax, bx
0x000000000000073a:  0E                push      cs
0x000000000000073b:  E8 52 FF          call      0x690
0x000000000000073e:  FB                sti       
0x000000000000073f:  FC                cld       
0x0000000000000740:  30 C0             xor       al, al
0x0000000000000742:  CB                retf      
0x0000000000000743:  FC                cld       
0x0000000000000744:  C6 06 AC 0D 00    mov       byte ptr [0xdac], 0
0x0000000000000749:  B0 01             mov       al, 1
0x000000000000074b:  CB                retf      
0x000000000000074c:  A3 AA 0D          mov       word ptr [0xdaa], ax
0x000000000000074f:  FC                cld       
0x0000000000000750:  30 C0             xor       al, al
0x0000000000000752:  A2 AC 0D          mov       byte ptr [0xdac], al
0x0000000000000755:  CB                retf      






PROC  SM_SBMID_ENDMARKER_
PUBLIC  SM_SBMID_ENDMARKER_
ENDP



END

