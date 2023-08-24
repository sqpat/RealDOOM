/*
Copyright (C) 1994-1995 Apogee Software, Ltd.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
/**********************************************************************
   module: DPMI.H

   author: James R. Dose
   date:   March 31, 1994

   Inline functions for performing DPMI calls.

   (c) Copyright 1994 James R. Dose.  All Rights Reserved.
**********************************************************************/

#ifndef __DPMI_H
#define __DPMI_H

#define _dpmi_lockregion DPMI_LockMemory
#define _dpmi_unlockregion DPMI_UnlockMemory

enum DPMI_Errors
   {
   DPMI_Warning = -2,
   DPMI_Error   = -1,
   DPMI_Ok      = 0
   };

typedef struct
   {
   uint32_t  EDI;
   uint32_t  ESI;
   uint32_t  EBP;
   uint32_t  Reserved;
   uint32_t  EBX;
   uint32_t  EDX;
   uint32_t  ECX;
   uint32_t  EAX;
   uint16_t Flags;
   uint16_t ES;
   uint16_t DS;
   uint16_t FS;
   uint16_t GS;
   uint16_t IP;
   uint16_t CS;
   uint16_t SP;
   uint16_t SS;
   } dpmi_regs;

uint32_t DPMI_GetRealModeVector( int32_t num );
void DPMI_SetRealModeVector(int32_t num, uint32_t vector );
int32_t  DPMI_CallRealModeFunction( dpmi_regs *callregs );
int32_t  DPMI_GetDOSMemory( void **ptr, int32_t *descriptor, uint32_t length );
int32_t  DPMI_FreeDOSMemory(int32_t descriptor );
int32_t  DPMI_LockMemory( void *address, uint32_t length );
int32_t  DPMI_LockMemoryRegion( void *start, void *end );
int32_t  DPMI_UnlockMemory( void *address, uint32_t length );
int32_t  DPMI_UnlockMemoryRegion( void *start, void *end );

#define DPMI_Lock( variable ) \
   ( DPMI_LockMemory( &( variable ), sizeof( variable ) ) )

#define DPMI_Unlock( variable ) \
   ( DPMI_UnlockMemory( &( variable ), sizeof( variable ) ) )

#pragma aux DPMI_GetDOSMemory = \
   "mov    eax, 0100h",         \
   "add    ebx, 15",            \
   "shr    ebx, 4",             \
   "int    31h",                \
   "jc     DPMI_Exit",          \
   "movzx  eax, ax",            \
   "shl    eax, 4",             \
   "mov    [ esi ], eax",       \
   "mov    [ edi ], edx",       \
   "sub    eax, eax",           \
   "DPMI_Exit:",                \
   parm [ esi ] [ edi ] [ ebx ] modify exact [ eax ebx edx ];

#pragma aux DPMI_FreeDOSMemory = \
   "mov    eax, 0101h",          \
   "int    31h",                 \
   "jc     DPMI_Exit",           \
   "sub    eax, eax",            \
   "DPMI_Exit:",                 \
   parm [ edx ] modify exact [ eax ];

#endif
