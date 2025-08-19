//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//      Handles WAD file header, directory, lump I/O.
//


#include <ctype.h>
#include <fcntl.h>
#include <dos.h>

#include "doomtype.h"
#include "doomstat.h"
#include "i_system.h"
#include "z_zone.h"

#include "w_wad.h"
#include "r_defs.h"
#include "r_state.h"
#include "m_memory.h"
#include "m_near.h"




//
// GLOBALS
//

// Location of each lump on disk.







#define FREAD_BUFFER_SIZE 512

void  __far locallib_far_fread(void __far* dest, uint16_t elementsize, uint16_t elementcount, FILE * fp) {
	// cheating with size/element count
	uint16_t totalsize = elementsize * elementcount;
	uint16_t totalreadsize = 0;
	uint16_t copysize;
	uint16_t remaining;
	byte stackbuffer[FREAD_BUFFER_SIZE];
	byte __far* stackbufferfar = (byte __far *)stackbuffer;
	byte __far* destloc = dest;
	while (totalreadsize < totalsize) {

		remaining = totalsize - totalreadsize;
		copysize = (FREAD_BUFFER_SIZE > remaining) ? remaining : FREAD_BUFFER_SIZE;
		fread(stackbuffer, copysize, 1, fp);
		FAR_memcpy(destloc, stackbufferfar, copysize);

		destloc += copysize;
		totalreadsize += copysize;
	}

}

/*
void  _far_read(int16_t filehandle, void __far* dest, uint16_t totalsize) {

	// cheating with size/element count
	uint16_t totalreadsize = 0;
	int16_t copysize;
	uint16_t remaining;
	byte stackbuffer[FREAD_BUFFER_SIZE];
	byte __far* stackbufferfar = (byte __far *)stackbuffer;
	byte __far* destloc = dest;
	while (totalreadsize < totalsize) {

		remaining = totalsize - totalreadsize;
		copysize = (FREAD_BUFFER_SIZE > remaining) ? remaining : FREAD_BUFFER_SIZE;
		read(filehandle, stackbuffer, copysize);

		FAR_memcpy(destloc, stackbufferfar, copysize);

		destloc += copysize;
		totalreadsize += copysize;
	}

}
*/
// unused outside of debug stuff
filelength_t  __far locallib_far_fwrite(void __far* src, uint16_t elementsize, uint16_t elementcount, FILE * fp) {
	// cheating with size/element count
	uint16_t totalsize = elementsize * elementcount;
	filelength_t totalreadsize = 0;
	uint16_t copysize;
	uint16_t remaining;
	byte stackbuffer[FREAD_BUFFER_SIZE];
	byte __far* stackbufferfar = (byte __far *)stackbuffer;
	byte __far* srcloc = src;
	while (totalreadsize < totalsize) {
		remaining = totalsize - totalreadsize;
		copysize = (FREAD_BUFFER_SIZE > remaining) ? remaining : FREAD_BUFFER_SIZE;
		FAR_memcpy(stackbufferfar, srcloc, copysize);
		fwrite(stackbuffer, copysize, 1, fp);
		srcloc += copysize;
		totalreadsize += copysize;
	}
	return totalreadsize;
}

#ifdef __COMPILER_WATCOM

#else
void __far  _fstrncpy(char __far *dst, const char __far *src, size_t totalsize) {

	// very jank. only used for size 8 or 9 or so 

	/*
	byte stackbuffer[FREAD_BUFFER_SIZE];
	byte __far* stackbufferfar = (byte __far *)stackbuffer;
	byte __far* destloc = dest;
	*/

	_fmemcpy(dst, src, totalsize);
	//return dst;
}

/*
void  _fmemset(void __far* dest, int16_t value, size_t size);
void _fmemcpy(void __far* dest, void __far* src, size_t size);
void  _fstrncpy(char __far *dest, const char __far *src, size_t size);
void _fstrcpy(char __far *dest, const char __far *src);
void _fmemmove(char __far *dest, const void __far *src, size_t size);
*/
#endif


//
// W_CheckNumForName
// Returns -1 if name not found.
//


int16_t __far W_CheckNumForName (int8_t* name) {
    union {
		int8_t    s[9];
		int16_t     x[4];
        
    } name8;
    
	int16_t         v1;
	int16_t         v2;
	int16_t         v3;
	int16_t         v4;
	int16_t			currentcounter;
	int16_t         counter = numlumps;
	int16_t         returnval = -1;
	lumpinfo_t __far* lump_p;
	//lumpinfo_t __far* lumpinfo = lumpinfo9000;
    // make the name into two integers for easy compares
	
	memset(&name8, 0, 9);
	copystr8 (name8.s,name);
	//name8.s[8] = '\0';

    
    // case insensitive
    //locallib_strupr (name8.s);           
	locallib_strupr(name8.s);

    v1 = name8.x[0];
    v2 = name8.x[1];
    v3 = name8.x[2];
    v4 = name8.x[3];


	currentcounter = numlumps & (LUMP_PER_EMS_PAGE-1);
	
	Z_QuickMapWADPageFrame(numlumps);


	// scan backwards so patch lump files take precedence
    lump_p = &lumpinfoD800[currentcounter];

    while (true) {

		if ( *(int16_t __far *)lump_p->name == v1
             && *(int16_t __far *)&lump_p->name[2] == v2
             && *(int16_t __far *)&lump_p->name[4] == v3
             && *(int16_t __far *)&lump_p->name[6] == v4 ) {
				returnval = counter;
				break;
        }
		if (currentcounter == 0) {
			if (counter){
				Z_QuickMapWADPageFrame(counter-1);
				currentcounter = LUMP_PER_EMS_PAGE-1;
				// todo mkfp
				lump_p = (lumpinfo_t __far*)MK_FP(WAD_PAGE_FRAME_SEGMENT, 0x4000);
			} else {
				break;
			}
		} else {
			currentcounter--;
		}
		counter--;
		lump_p--;

    }
 
    // TFB. Not found.
    return returnval;
}

//
// W_GetNumForName
// Calls W_CheckNumForName, but bombs out if not found.
//
int16_t __far W_GetNumForName(int8_t* name) {
	int16_t i;

    i = W_CheckNumForName (name);

#ifdef CHECK_FOR_ERRORS
	if (i == -1)
		I_Error("\nW_GetNumForName: %s not found!", name);
#endif

    return i;
}


//
// W_LumpLength
// Returns the buffer size needed to load the given lump.
//



int32_t __far W_LumpLength (int16_t lump) {
	int8_t i;
	// todo make this not a for loop.

	// if (lump < 0){
	// 	I_Error("-1 lump in lump length!");
	// 	return 0;
	// }
	for (i = 0; i < currentloadedfileindex-1; i++){
		if (lump == filetolumpindex[i]){
			return filetolumpsize[i];
		}
	}

	Z_QuickMapWADPageFrame(lump);

	// todo asm optim this...
	lump &= (LUMP_PER_EMS_PAGE-1);


	return lumpinfoD800[lump].size;
}


//
// W_ReadLump
// Loads the lump into the given buffer,
//  which must be >= W_LumpLength().
//


void __far W_ReadLump (int16_t lump, byte __far* dest, int32_t start, int32_t size ) {
	//filelength_t         c;  // size, leave as 32 bit
    lumpinfo_t __far* l;
#ifdef CHECK_FOR_ERRORS
	int32_t sizetoread;
#endif
    int32_t startoffset;
	filelength_t         lumpsize;
	int8_t  fileindex = 0;
	int8_t  i;

	// do this on outside? 
	// if (lump < 0){
	// 	I_Error("-1 lump in read lump!");
	// 	return;
	// }



	
	Z_QuickMapWADPageFrame(lump);
	l = &(lumpinfoD800[lump & (LUMP_PER_EMS_PAGE-1)]);



#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps)
        I_Error ("W_ReadLump: %i >= numlumps",lump);
#endif
	lumpsize = l->size;

	
	if (lump == 1) {//colormaps hack.
		lumpsize = 33 * 256; // hack to override lumpsize of colormaps
	}

	#ifdef ENABLE_DISK_FLASH
    	I_BeginRead ();
	#endif

	for (i = 0; i < currentloadedfileindex-1; i++){
		if (lump == filetolumpindex[i]){
			fileindex = i+1;	// this is a single lump file
			break;
		}
	}
	startoffset = l->position + start;

    fseek(wadfiles[fileindex], startoffset, SEEK_SET);

	FAR_fread(dest, size ? size : (lumpsize - start), 1, wadfiles[fileindex]);

	#ifdef ENABLE_DISK_FLASH
    	I_EndRead ();
	#endif
}



  
 
 

void __far W_CacheLumpNameDirect (int8_t* name, byte __far* dest ) {
	W_ReadLump(W_GetNumForName(name), dest, 0, 0);
}


void __far W_CacheLumpNumDirect (int16_t lump, byte __far* dest ) {
	W_ReadLump(lump, dest, 0, 0);
}

void __far W_CacheLumpNumDirectWithOffset (int16_t lump, byte __far* dest, uint16_t offset, uint16_t length) {
	W_ReadLump(lump, dest, offset, length);
}

 
// used for stuff > 64k, especially titlepics, to draw one ems frame at a tiem
void __far W_CacheLumpNumDirectFragment (int16_t lump, byte __far* dest,int32_t offset){
 
	W_ReadLump(lump, dest, offset, 16384);
    
}

 
