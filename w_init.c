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
#include <fcntl.h>

#include "doomtype.h"
#include "doomstat.h"
#include "i_system.h"
#include "z_zone.h"
#include "m_memory.h"

#include "w_wad.h"
#include "r_defs.h"
#include <dos.h>
#include "m_near.h"


 





//
// LUMP BASED ROUTINES.
//

//
// W_AddFile
// All files are optional, but at least one file must be
//  found (PWAD, if all required lumps are present).
// Files with a .wad extension are wadlink files
//  with multiple lumps.
// Other files are single lumps with the base filename
//  for the lump name.
//
// If filename starts with a tilde, the file is handled
//  specially to allow map reloads.
// But: the reload feature is a fragile hack...

#define SCRATCH_FILE_LOAD_LOCATION  (filelump_t __far*)(0x50000000)

void __near W_AddFile(int8_t *filename) {
	wadinfo_t			header;
	lumpinfo_t __far*		lump_p;
	uint16_t			i;
	uint16_t			j = 65535;
	int32_t				length;
	uint16_t			startlump;
	filelump_t __far*		fileinfo;
	FILE* usefp;


	int32_t lastpos = 0;
	int32_t lastsize = 0;
	int32_t diff;


	// open the file and add to directory

	// handle reload indicator.
	/*
	if (filename[0] == '~') {
		filename++;
		reloadname = filename;
		reloadlump = numlumps;
	}
	*/

	if (!wadfilefp){
		wadfilefp = fopen(filename, "rb");
		usefp = wadfilefp;
	} else {
		// timedemo case
		wadfilefp2 = fopen(filename, "rb");
		usefp = wadfilefp2;
	}

	if (!usefp) {
		DEBUG_PRINT("\tcouldn't open %s\n", filename);
		return;
	}


	DEBUG_PRINT("\n\tadding %s\n", filename);
	startlump = numlumps;
 
	// WAD file
	FAR_fread(&header, sizeof(header), 1, usefp);
	



	// 0x4957 == "IW" && 0x4144 == "AD"
	if (((uint16_t)(header.identification[0])) == 0x4957 && 
	 	((uint16_t)(header.identification[2])) == 0x4144
	 ) {
#ifdef CHECK_FOR_ERRORS
		// Homebrew levels?
	// 0x5057 == "PW" && 0x4144 == "AD"
	if (((uint16_t)(header.identification[0])) == 0x5057 && 
	 	((uint16_t)(header.identification[2])) == 0x4144
	 ) {
			I_Error("Wad file %s doesn't have IWAD "
				"or PWAD id\n", filename);
		}
#endif

		modifiedgame = true;
	}
	//header.numlumps = (header.numlumps);
	//header.infotableofs = (header.infotableofs);
	length = header.numlumps * sizeof(filelump_t);

	// let's piggyback off scratch EMS block
	fileinfo = SCRATCH_FILE_LOAD_LOCATION;
	fseek(usefp, header.infotableofs, SEEK_SET);
	FAR_fread(fileinfo, length, 1, usefp);
	numlumps += header.numlumps;
	
	if (numlumps == 2306){
		// todo: find a better check than this. 
		is_ultimate = true;
	}
	// numlumps 1264
 
	lump_p = &lumpinfoinit[startlump];


	for (i = startlump; i < numlumps; i++, lump_p++, fileinfo++) {

		lump_p->position = (fileinfo->filepos);

		// set up the diff
		if (i) {
			diff = fileinfo->filepos - lastpos;
			if (fileinfo->filepos) { // sometimes there are 0 size 'marker' items that also lie and set their position as 0... just skip these as it throws off the algorithm

				diff = lastsize - diff;

				// we need to backtrack and push all 0 length items to the position of the next nonzero length item so size calculations work
				if (j != 65535) {
					for (; j < i; j++) {
						lumpinfoinit[j].position = fileinfo->filepos;
					}
					j = 65535;
				}
				lastpos = fileinfo->filepos;
				lastsize = fileinfo->size;
			}
			else {
				// filepos is 0 case, usually markers....
				if (j == 65535)
					j = i;

				diff = 0;
				lump_p->position = lastpos + lastsize;
			}
			lumpinfoinit[i - 1].sizediff = diff;

		}
		else {
			lastsize = fileinfo->size;
		}
		FAR_memset(lump_p->name, 0, 8);
		copystr8(lump_p->name, fileinfo->name);

	}
	lumpinfoinit[i - 1].sizediff = 0;

	
	FAR_memset(SCRATCH_FILE_LOAD_LOCATION, 0, 65535);
}



