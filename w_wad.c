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
#include <string.h>
#include <unistd.h>
//#include <malloc.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "doomtype.h"
#include "doomstat.h"
#include "i_system.h"
#include "z_zone.h"

#include "w_wad.h"
#include "r_defs.h"
#include "r_state.h"
#include "memory.h"





//
// GLOBALS
//

// Location of each lump on disk.



uint16_t                     numlumps;

  
uint16_t                     reloadlump;
int8_t*                   reloadname;


// rather than storing a billion duplicate file handles, we'll store a couple
filehandle_t				wadfilehandle;




#define FREAD_BUFFER_SIZE 512

void  _far_fread(void __far* dest, uint16_t elementsize, uint16_t elementcount, FILE * fp) {
	// cheating with size/element count
	uint16_t totalsize = elementsize * elementcount;
	uint16_t totalreadsize = 0;
	uint16_t copysize;
	uint16_t remaining;
	byte stackbuffer[FREAD_BUFFER_SIZE];
	byte __far* stackbufferfar = (byte __far *)stackbuffer;
	byte __far* destloc = dest;
	while (totalreadsize < totalsize) {

		//DEBUG_PRINT("\n9 %Fp %Fp ", dest, destloc);
		remaining = totalsize - totalreadsize;
		copysize = (FREAD_BUFFER_SIZE > remaining) ? remaining : FREAD_BUFFER_SIZE;
		//DEBUG_PRINT("%u %u", totalsize, copysize);
		fread(stackbuffer, copysize, 1, fp);
		FAR_memcpy(destloc, stackbufferfar, copysize);

		destloc += copysize;
		totalreadsize += copysize;
	}

}
void  _far_read(int16_t filehandle, void __far* dest, uint16_t totalsize) {

	// cheating with size/element count
	uint16_t totalreadsize = 0;
	int16_t copysize;
	uint16_t remaining;
	//uint16_t start = _tell(filehandle);
	byte stackbuffer[FREAD_BUFFER_SIZE];
	byte __far* stackbufferfar = (byte __far *)stackbuffer;
	byte __far* destloc = dest;
	while (totalreadsize < totalsize) {

		//DEBUG_PRINT("\n9 %Fp %Fp ", dest, destloc);
		remaining = totalsize - totalreadsize;
		copysize = (FREAD_BUFFER_SIZE > remaining) ? remaining : FREAD_BUFFER_SIZE;
		//DEBUG_PRINT("%u %u", totalsize, copysize);
		read(filehandle, stackbuffer, copysize);

		FAR_memcpy(destloc, stackbufferfar, copysize);

		destloc += copysize;
		totalreadsize += copysize;
		//lseek(filehandle, totalreadsize+start, SEEK_SET);
	}

}


void  _far_fwrite(void __far* src, uint16_t elementsize, uint16_t elementcount, FILE * fp) {
	// cheating with size/element count
	uint16_t totalsize = elementsize * elementcount;
	uint16_t totalreadsize = 0;
	uint16_t copysize;
	uint16_t remaining;
	byte stackbuffer[FREAD_BUFFER_SIZE];
	byte __far* stackbufferfar = (byte __far *)stackbuffer;
	byte __far* srcloc = src;
	//DEBUG_PRINT("\n new %Fp %Fp ", src, srcloc);
	while (totalreadsize < totalsize) {
		//DEBUG_PRINT("_ %Fp %Fp ", src, srcloc);
		remaining = totalsize - totalreadsize;
		copysize = (FREAD_BUFFER_SIZE > remaining) ? remaining : FREAD_BUFFER_SIZE;
		//DEBUG_PRINT("%u %u", totalsize, copysize);
		FAR_memcpy(stackbufferfar, srcloc, copysize);
		fwrite(stackbuffer, copysize, 1, fp);
		srcloc += copysize;
		totalreadsize += copysize;
	}
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

int16_t W_CheckNumForName (int8_t* name)
{
    union {
		int8_t    s[9];
		int16_t     x[4];
        
    } name8;
    
	int16_t         v1;
	int16_t         v2;
	int16_t         v3;
	int16_t         v4;
	int16_t         counter = numlumps;
	int16_t         returnval = -1;
	lumpinfo_t __far* lump_p;
	//lumpinfo_t __far* lumpinfo = lumpinfo9000;
    // make the name into two integers for easy compares
    memset (name8.s, 0, 9);
	strncpy (name8.s,name,8);

    
    // case insensitive
    strupr (name8.s);           

    v1 = name8.x[0];
    v2 = name8.x[1];
    v3 = name8.x[2];
    v4 = name8.x[3];


	Z_QuickmapLumpInfo();
	// scan backwards so patch lump files take precedence
    lump_p = lumpinfo9000 + numlumps;

    while (true) {

		if ( *(int16_t __far *)lump_p->name == v1
             && *(int16_t __far *)&lump_p->name[2] == v2
             && *(int16_t __far *)&lump_p->name[4] == v3
             && *(int16_t __far *)&lump_p->name[6] == v4 ) {
				returnval = counter;
				break;
        }
		if (lump_p == lumpinfo9000) {
			break;
		}
		counter--;
		lump_p--;

    }

#ifdef CHECK_FOR_ERRORS
	if (returnval < -1) {
		I_Error("what? %s %i %Fp %Fp ", name, returnval, lump_p, lumpinfo9000);
	}
#endif

	Z_UnmapLumpInfo();
    // TFB. Not found.
    return returnval;
}

//
// W_GetNumForName
// Calls W_CheckNumForName, but bombs out if not found.
//
int16_t W_GetNumForName(int8_t* name)
//int16_t W_GetNumForName2 (int8_t* name, int8_t*file, int line)
{
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

int32_t W_LumpLength5000(int16_t lump) {
	return (lumpinfo5000[lump + 1].position - lumpinfo5000[lump].position) + lumpinfo5000[lump].sizediff;
}


int32_t W_LumpLength9000(int16_t lump) {
	return (lumpinfo9000[lump + 1].position - lumpinfo9000[lump].position) + lumpinfo9000[lump].sizediff;
}

int32_t W_LumpLength (int16_t lump)
{
	int32_t size;
#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps)
        I_Error ("W_LumpLength: %i >= numlumps",lump);
#endif


	 
	Z_QuickmapLumpInfo();
	size = W_LumpLength9000(lump);
	Z_UnmapLumpInfo();
	return size;
}


//
// W_ReadLump
// Loads the lump into the given buffer,
//  which must be >= W_LumpLength().
//


extern int setval;

void
W_ReadLump
(int16_t           lump,
  byte __far*         dest,
  int32_t           start,
  int32_t           size )
{
	//filelength_t         c;  // size, leave as 32 bit
    lumpinfo_t __far* l;
	filehandle_t         handle;
#ifdef CHECK_FOR_ERRORS
	int32_t sizetoread;
#endif
    int32_t startoffset;
	filelength_t         lumpsize;

	// use 5000 page if we are trying to write to 9000 page
	boolean is5000Page = ((int32_t) dest >= 0x90000000) && ((int32_t)dest < 0xA0000000);

	if (is5000Page) {
		Z_QuickmapLumpInfo5000();
		l = lumpinfo5000+lump;
	} else { 
		Z_QuickmapLumpInfo();
		l = lumpinfo9000+lump;
	}


#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps)
        I_Error ("W_ReadLump: %i >= numlumps",lump);
#endif
    //l = lumpinfo+lump;
	//lumpsize = ((lumpinfo + lump + 1)->position - l->position) + l->sizediff;
	lumpsize = is5000Page ? W_LumpLength5000(lump) : W_LumpLength9000(lump);

	
	if (dest == colormaps) {//todo unhack this...
		lumpsize = 33 * 256; // hack to override lumpsize of colormaps
	}

    I_BeginRead ();
        
	if (wadfilehandle == -1){
		// reloadable file, so use open / read / close
		if ((handle = open(reloadname, O_RDONLY | O_BINARY)) == -1) {
#ifdef CHECK_FOR_ERRORS
			I_Error("W_ReadLump: couldn't open %s", reloadname);
#endif
		}
	}
	else {
		handle = wadfilehandle;
	}
    
	startoffset = l->position + start;
    lseek(handle, startoffset, SEEK_SET);

	FAR_read(handle, dest, size ? size : lumpsize);
 

	if (wadfilehandle == -1) {
		close(handle);
	}
 

	if (is5000Page) {
		Z_UnmapLumpInfo5000();
	} else {
		Z_UnmapLumpInfo();
	}

    I_EndRead ();
}



  
 
 

void
W_CacheLumpNameDirect
(int8_t*         name,
	byte __far*			dest
) {
	//printf("\nA %s %i %lx", name, W_GetNumForName(name), dest);
	//printf("\nB %s %i %i %lx", name, *(int16_t __far*)dest, *((int16_t __far*)(dest + 1)), dest);
	W_ReadLump(W_GetNumForName(name), dest, 0, 0);
	//printf("\nC %s %i %i %lx", name, *(int16_t __far*)dest, *((int16_t __far*)(dest+1)),dest);

}


void
W_CacheLumpNumDirect
(int16_t lump,
	byte __far*			dest
) {
	W_ReadLump(lump, dest, 0, 0);
}

 
// used for stuff > 64k, especially titlepics, to draw one ems frame at a tiem
void
W_CacheLumpNumDirectFragment
(int16_t lump,
	byte __far*			dest,
    int16_t         pagenum,
    int32_t offset){
 
	W_ReadLump(lump, dest, offset, 16384);
    
}

 
