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

void __near W_UpdateNumLumps();

void __near W_AddFile(int8_t *filename) {
	wadinfo_t			header;
	lumpinfo_t __far*		lump_p;
	uint16_t			i;
	uint16_t			j = 65535;
	int32_t				length;
	uint16_t			startlump;
	filelump_t __far*		fileinfo;
    filelump_t		singleinfo;
	FILE* usefp;


	int32_t lastpos = 0;
	int32_t lastsize = 0;
	int32_t diff;
	int8_t  iswad = false;

	// bleh. can a file be called "A.wad.wad" ?
	for (i = 0; filename[i] != '\0'; i++){
		if (filename[i+0] == '.'){
			if (filename[i+1] == 'w'){
				if (filename[i+2] == 'a'){
					if (filename[i+3] == 'd'){
						if (filename[i+4] == '\0'){
							iswad = true;
							break;
						}
					}
				}
			}
		}
	}


	// open the file and add to directory

	// handle reload indicator.
	/*
	if (filename[0] == '~') {
		filename++;
		reloadname = filename;
		reloadlump = numlumps;
	}
	*/

	wadfiles[currentloadedfileindex] = fopen(filename, "rb");
	usefp = wadfiles[currentloadedfileindex];




	if (!usefp) {
		DEBUG_PRINT("\tcouldn't open %s\n", filename);
		return;
	}


	DEBUG_PRINT("\n\tadding %s\n", filename);
	startlump = numlumps;
 
	if (!iswad) {
		// single lump file
		int8_t upr_name[8];

		fileinfo = &singleinfo;
		singleinfo.filepos = 0;
		fseek(usefp, 0L, SEEK_END);
		singleinfo.size = ftell(usefp);
		fseek(usefp, 0L, SEEK_SET);
		
		// first file is always a real wad. that doesn't use these fields.
		filetolumpindex[currentloadedfileindex-1] = numlumps;
		filetolumpsize[currentloadedfileindex-1] = singleinfo.size;
		numlumps++;
		memset(upr_name, 0, 8);
		// not perfect, what if filename has multiple dots or no dot, etc.
		for (i = 0; (filename[i] != '.') && (i < 8); i++){
			upr_name[i] = filename[i];
		}

		locallib_strupr(upr_name);
		// upper the name and make it a wad lump name...
		FAR_memcpy(singleinfo.name, upr_name, 8);

	} else {
		// WAD file
		locallib_far_fread(&header, sizeof(wadinfo_t), usefp);	

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
		//header.wad_numlumps = (header.wad_numlumps);
		//header.infotableofs = (header.infotableofs);
		length = header.wad_numlumps * sizeof(filelump_t);

		// let's piggyback off scratch EMS block
		fileinfo = SCRATCH_FILE_LOAD_LOCATION;
		fseek(usefp, header.infotableofs, SEEK_SET);
		locallib_far_fread(fileinfo, length, usefp);
		numlumps += header.wad_numlumps;

		W_UpdateNumLumps();

	}

	currentloadedfileindex++;
	

 
	lump_p = &lumpinfoinit[startlump];


	for (i = startlump; i < numlumps; i++, lump_p++, fileinfo++) {

		lump_p->position = (fileinfo->filepos);
		lump_p->size = (fileinfo->size);

		// set up the diff
		
		
		FAR_memset(lump_p->name, 0, 8);
		copystr8(lump_p->name, fileinfo->name);

	}

	
	FAR_memset(SCRATCH_FILE_LOAD_LOCATION, 0, 65535);
}



