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
#include <malloc.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "doomtype.h"
#include "doomstat.h"
#include "i_system.h"
#include "z_zone.h"

#include "w_wad.h"
#include "r_defs.h"
#include <dos.h>

extern filehandle_t				wadfilehandle;
extern lumpinfo_t*             lumpinfo;
extern uint16_t                     numlumps;
extern byte near	lumpbytes[LUMPINFO_SIZE];


void
ExtractFileBase
(int8_t*         path,
	int8_t*         dest)
{
	int8_t*       src;
	int16_t         length;

	src = path + strlen(path) - 1;

	// back up until a \ or the start
	while (src != path
		&& *(src - 1) != '\\'
		&& *(src - 1) != '/')
	{
		src--;
	}

	// copy up to eight characters
	memset(dest, 0, 8);
	length = 0;

	while (*src && *src != '.')
	{
		if (++length == 9) {
#ifdef CHECK_FOR_ERRORS
			I_Error("Filename base of %s >8 chars", path);
#endif
		}

		*dest = toupper(*src);
		dest++;
		src++;
	}
}





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

extern uint16_t                     reloadlump;
extern int8_t*                   reloadname;


void W_AddFile(int8_t *filename)
{
	wadinfo_t			header;
	lumpinfo_t*			lump_p;
	uint16_t			i;
	uint16_t			j = 65535;
	filehandle_t		handle;
	int32_t				length;
	uint16_t			startlump;
	filelump_t*			fileinfo;
	filelump_t			singleinfo;
	filehandle_t		storehandle;

	int32_t lastpos = 0;
	int32_t lastsize = 0;
	int32_t diff;


	// open the file and add to directory

	// handle reload indicator.
	if (filename[0] == '~')
	{
		filename++;
		reloadname = filename;
		reloadlump = numlumps;
	}

	if ((handle = open(filename, O_RDONLY | O_BINARY)) == -1)
	{
		DEBUG_PRINT("\tcouldn't open %s\n", filename);
		return;
	}
	DEBUG_PRINT("\n", filename);

	DEBUG_PRINT("\tadding %s\n", filename);
	startlump = numlumps;

	if (strcmpi(filename + strlen(filename) - 3, "wad"))
	{
		// single lump file
		fileinfo = &singleinfo;
		singleinfo.filepos = 0;
		singleinfo.size = (filelength(handle));
		ExtractFileBase(filename, singleinfo.name);
		numlumps++;
	}
	else
	{
		// WAD file
		read(handle, &header, sizeof(header));
		if (strncmp(header.identification, "IWAD", 4))
		{
#ifdef CHECK_FOR_ERRORS
			// Homebrew levels?
			if (strncmp(header.identification, "PWAD", 4))
			{
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
		fileinfo = (filelump_t*)MK_FP(0x5000, 0);
		lseek(handle, header.infotableofs, SEEK_SET);
		read(handle, fileinfo, length);
		numlumps += header.numlumps;
	}
	// numlumps 1264

	 

	lump_p = &lumpinfo[startlump];

	storehandle = reloadname ? -1 : handle;

#ifdef	SUPPORT_MULTIWAD
	if (currentfilehandle >= MAX_WAD_FILES) {
		I_Error("Too many wad handles!");
	}
	filehandles[currentfilehandle] = storehandle;
#else
	wadfilehandle = storehandle;
#endif
	for (i = startlump; i < numlumps; i++, lump_p++, fileinfo++)
	{

#ifdef	SUPPORT_MULTIWAD
		lump_p->handleindex = currentfilehandle;
#endif
		lump_p->position = (fileinfo->filepos);

		// set up the diff
		if (i) {
			diff = fileinfo->filepos - lastpos;
			if (fileinfo->filepos) { // sometimes there are 0 size 'marker' items that also lie and set their position as 0... just skip these as it throws off the algorithm

				diff = lastsize - diff;

				// we need to backtrack and push all 0 length items to the position of the next nonzero length item so size calculations work
				if (j != 65535) {
					for (; j < i; j++) {
						lumpinfo[j].position = fileinfo->filepos;
					}
					j = 65535;
				}
				//				if (lastsize != diff) {
				//					if (diff > 127 || diff < -128)
				//						I_Error("\nbad size? %i %i %i %i", i, lastsize, lastpos, fileinfo->filepos);
				//				}
				lastpos = fileinfo->filepos;
				lastsize = fileinfo->size;
			}
			else {
				if (j == 65535)
					j = i;

				diff = 0;
				lump_p->position = lastpos;
			}
			lumpinfo[i - 1].sizediff = diff;

		}
		else {
			lastsize = fileinfo->size;
		}
		strncpy(lump_p->name, fileinfo->name, 8);
	}
	lumpinfo[i - 1].sizediff = 0;
#ifdef	SUPPORT_MULTIWAD
	currentfilehandle++;
#endif

	if (reloadname)
		close(handle);
	
	memset(MK_FP(0x5000, 0), 0, 65535);
}



//
// W_InitMultipleFiles
// Pass a null terminated list of files to use.
// All files are optional, but at least one file
//  must be found.
// Files with a .wad extension are idlink files
//  with multiple lumps.
// Other files are single lumps with the base filename
//  for the lump name.
// Lump names can appear multiple times.
// The name searcher looks backwards, so a later file
//  does override all earlier ones.
//
void W_InitMultipleFiles(int8_t** filenames)
{
	//filelength_t         size;
	//printf("\n\nsize is %u \n\n", _memmax());

	// open all the files, load headers, and count lumps
	numlumps = 0;

	// will be realloced as lumps are added
	lumpinfo = (lumpinfo_t*)lumpbytes;

	for (; *filenames; filenames++)
		W_AddFile(*filenames);
	//printf("\n\nsize is %u \n\n", _memmax());

#ifdef CHECK_FOR_ERRORS
	if (!numlumps)
		I_Error("W_InitFiles: no files found");
#endif

 	//I_Error("size %li", size);

	 
 

}
