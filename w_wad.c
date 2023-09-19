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
#include <alloca.h>

#include "doomtype.h"
#include "doomstat.h"
#include "i_system.h"
#include "z_zone.h"

#include "w_wad.h"
#include "r_defs.h"





//
// GLOBALS
//

// Location of each lump on disk.
lumpinfo_t*             lumpinfo;               
uint16_t                     numlumps;

MEMREF*					lumpcacheEMS;

// we use this explicitly for fullscreen graphics. 
MEMREF              pagedlumpcacheEMS[2];

// rather than storing a billion duplicate file handles, we'll store a couple
#ifdef	SUPPORT_MULTIWAD
filehandle_t				filehandles[MAX_WAD_FILES];
int8_t						currentfilehandle = 0;
#else
filehandle_t				wadfilehandle;
#endif

void
ExtractFileBase
( int8_t*         path,
  int8_t*         dest )
{
    int8_t*       src;
	int16_t         length;

    src = path + strlen(path) - 1;
    
    // back up until a \ or the start
    while (src != path
           && *(src-1) != '\\'
           && *(src-1) != '/')
    {
        src--;
    }
    
    // copy up to eight characters
    memset (dest,0,8);
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

uint16_t                     reloadlump;
int8_t*                   reloadname;


void W_AddFile (int8_t *filename)
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
                
    if ( (handle = open (filename,O_RDONLY | O_BINARY)) == -1)
    {
		DEBUG_PRINT("\tcouldn't open %s\n",filename);
        return;
    }

	DEBUG_PRINT("\tadding %s\n",filename);
    startlump = numlumps;
        
    if (strcmpi (filename+strlen(filename)-3 , "wad" ) )
    {
        // single lump file
        fileinfo = &singleinfo;
        singleinfo.filepos = 0;
        singleinfo.size = (filelength(handle));
        ExtractFileBase (filename, singleinfo.name);
        numlumps++;
    }
    else 
    {
        // WAD file
        read (handle, &header, sizeof(header));
        if (strncmp(header.identification,"IWAD",4))
        {
#ifdef CHECK_FOR_ERRORS
			// Homebrew levels?
            if (strncmp(header.identification,"PWAD",4))
            {
				I_Error ("Wad file %s doesn't have IWAD "
                         "or PWAD id\n", filename);
            }
#endif

            modifiedgame = true;                
        }
        //header.numlumps = (header.numlumps);
        //header.infotableofs = (header.infotableofs);
        length = header.numlumps*sizeof(filelump_t);
		fileinfo = alloca(length);
		/*
		fileinfo = _nmalloc (length);
		if (!fileinfo) {
			I_Error("couldn't _nmalloc for fileinfo");
		}*/
        lseek (handle, header.infotableofs, SEEK_SET);
		read (handle, fileinfo, length);
		numlumps += header.numlumps;
    }
// numlumps 1264
    
    
    // Fill in lumpinfo
    lumpinfo = realloc (lumpinfo, numlumps*sizeof(lumpinfo_t));
	// 25k in size! 
	// now 16.4k..

	//I_Error("lumpsize %i", numlumps * sizeof(lumpinfo_t));

    if (!lumpinfo)
        I_Error ("Couldn't realloc lumpinfo");

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
    for (i=startlump ; i<numlumps ; i++,lump_p++, fileinfo++)
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

				// we need to backtrack and push all 0 length items to the position of the next nonzero length item so size calculatiosn work
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
        strncpy (lump_p->name, fileinfo->name, 8);
    }
	lumpinfo[i - 1].sizediff = 0;
#ifdef	SUPPORT_MULTIWAD
	currentfilehandle++;
#endif
	 

    if (reloadname)
        close (handle);
	//free(fileinfo);
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
void W_InitMultipleFiles (int8_t** filenames)
{       
	filelength_t         size;
	//printf("\n\nsize is %u \n\n", _memmax());

    // open all the files, load headers, and count lumps
    numlumps = 0;

    // will be realloced as lumps are added
    lumpinfo = malloc(1);       

    for ( ; *filenames ; filenames++)
        W_AddFile (*filenames);
	//printf("\n\nsize is %u \n\n", _memmax());

#ifdef CHECK_FOR_ERRORS
	if (!numlumps)
        I_Error ("W_InitFiles: no files found");
#endif

	size = numlumps * sizeof(*lumpcacheEMS);
	lumpcacheEMS = malloc(size);
#ifdef CHECK_FOR_ERRORS

	if (!lumpcacheEMS)
		I_Error("Couldn't allocate lumpcacheEMS");
#endif
	memset(lumpcacheEMS, 0, size);

}


  


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
    lumpinfo_t* lump_p;

    // make the name into two integers for easy compares
    strncpy (name8.s,name,8);

    // in case the name was a fill 8 chars
    name8.s[8] = 0;

    // case insensitive
    strupr (name8.s);           

    v1 = name8.x[0];
    v2 = name8.x[1];
    v3 = name8.x[2];
    v4 = name8.x[3];


    // scan backwards so patch lump files take precedence
    lump_p = lumpinfo + numlumps;

    while (lump_p-- != lumpinfo)
    {
        if ( *(int16_t *)lump_p->name == v1
             && *(int16_t *)&lump_p->name[2] == v2
             && *(int16_t *)&lump_p->name[4] == v3
             && *(int16_t *)&lump_p->name[6] == v4
             
             )
        {
            return lump_p - lumpinfo;
        }
    }

    // TFB. Not found.
    return -1;
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
int32_t W_LumpLength (int16_t lump)
{
	int32_t size;
#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps)
        I_Error ("W_LumpLength: %i >= numlumps",lump);
#endif
    size = (lumpinfo[lump+1].position - lumpinfo[lump].position) + lumpinfo[lump].sizediff;
	if (size < 0) {
		I_Error("\nfound it %i %i %i", lump, size, lumpinfo[lump].sizediff, lumpinfo[lump + 1].position, lumpinfo[lump].position);
	}
	return size;
}


//
// W_ReadLump
// Loads the lump into the given buffer,
//  which must be >= W_LumpLength().
//




void
W_ReadLumpEMS
(int16_t           lump,
  MEMREF         lumpRef,
  int32_t           start,
  int32_t           size )
{
	filelength_t         c;  // size, leave as 32 bit
    lumpinfo_t* l;
	filehandle_t         handle;
	byte		*dest;
    int32_t sizetoread;
    int32_t startoffset;
	filelength_t         lumpsize;

 

#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps)
        I_Error ("W_ReadLump: %i >= numlumps",lump);
#endif
    l = lumpinfo+lump;
	lumpsize = ((lumpinfo + lump + 1)->position - l->position) + l->sizediff;

    I_BeginRead ();
        
#ifdef	SUPPORT_MULTIWAD
	if (filehandles[l->handleindex] == -1)
#else
	if (wadfilehandle == -1)
#endif
	{
		// reloadable file, so use open / read / close
		if ((handle = open(reloadname, O_RDONLY | O_BINARY)) == -1) {
#ifdef CHECK_FOR_ERRORS
			I_Error("W_ReadLump: couldn't open %s", reloadname);
#endif
		}
	}
	else {
#ifdef	SUPPORT_MULTIWAD
		handle = filehandles[l->handleindex];
#else
		handle = wadfilehandle;
#endif
	}
    dest = Z_LoadBytesFromEMS(lumpRef);
    startoffset = l->position + start;

#ifdef _M_I86
    sizetoread = size ? size : lumpsize;
#else
    sizetoread = size ? size : lumpsize;
#endif

    lseek(handle, startoffset, SEEK_SET);



	c = read(handle, dest, size ? size : lumpsize);
	// todo: make this work properly instead of using this hack to handle 32-64k filesize case
#ifdef _M_I86
	//c = _farread(handle, dest, lumpsize);

       if (c < sizetoread && c + 65536l != sizetoread ) // error check
#else
       if (c < (sizetoread)) 
#endif

{
#ifdef CHECK_FOR_ERRORS
		I_Error("\nW_ReadLump: only read %il of %il on lump %i",
			c, sizetoread, lump);
#endif
	}

#ifdef	SUPPORT_MULTIWAD
	   if (filehandles[l->handleindex] == -1)
#else
	   if (wadfilehandle == -1)
#endif
	   
        close (handle);
 


    I_EndRead ();
}




void
W_ReadLumpStatic
(int16_t           lump,
	void*         dest)
{
	filelength_t         c;
	lumpinfo_t* l;
	filehandle_t		handle;
	filelength_t		lumpsize;

#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps)
		I_Error("W_ReadLump: %i >= numlumps", lump);
#endif

	l = lumpinfo + lump;
	lumpsize = ((lumpinfo + lump + 1)->position - l->position) + l->sizediff;
	I_BeginRead();

#ifdef	SUPPORT_MULTIWAD
	if (filehandles[l->handleindex] == -1)
#else
	if (wadfilehandle == -1)
#endif
	{
		// reloadable file, so use open / read / close
		if ((handle = open(reloadname, O_RDONLY | O_BINARY)) == -1) {
#ifdef CHECK_FOR_ERRORS
			I_Error("W_ReadLump: couldn't open %s", reloadname);
#endif
		}
	}
	else {
#ifdef	SUPPORT_MULTIWAD
		handle = filehandles[l->handleindex];
#else
		handle = wadfilehandle;
#endif
	}
	lseek(handle, l->position, SEEK_SET);
	c = read(handle, dest, lumpsize);

	// todo make this suck less. 16 bit hack for large reads...
	if (c < lumpsize && c + 65536l != lumpsize) {
#ifdef CHECK_FOR_ERRORS
		I_Error("\nW_ReadLump: only read %il of %il on lump %i", c, lumpsize, lump);
#endif
	}

#ifdef	SUPPORT_MULTIWAD
	if (filehandles[l->handleindex] == -1)
#else
	if (wadfilehandle == -1)
#endif
		close(handle);

	I_EndRead();
	 

}


int16_t W_CacheLumpNumCheck(int16_t lump, int16_t error) {

#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps) {
		I_Error("W_CacheLumpNumCheck out of bounds: %i %i",  lump, error);
		return true;
	}
#endif
	return false;
}



 MEMREF
W_CacheLumpNumEMS
(	int16_t           lump,
	int8_t			tag)
{



#ifdef CHECK_FOR_ERRORS
	if (lump >= numlumps)
		I_Error("W_CacheLumpNum: %i >= numlumps", lump);
#endif

    //

//	if (!lumpcache[lump])
	if (!lumpcacheEMS[lump]) {
        //todo they are all 16k in this case but last one should be
		lumpcacheEMS[lump] = Z_MallocEMSNewWithBackRef(W_LumpLength(lump), tag, 0xFF, ALLOC_TYPE_CACHE_LUMP, lump + BACKREF_LUMP_OFFSET);

		W_ReadLumpEMS(lump, lumpcacheEMS[lump], 0, 0);
	} else {
		//printf ("cache hit on lump %i\n",lump);
		//I_Error("cache hit on lump %i and tag %i", lump, tag);
		Z_ChangeTagEMSNew(lumpcacheEMS[lump], tag);
	}

	return lumpcacheEMS[lump];
} 

//
// W_CacheLumpName
//
MEMREF
W_CacheLumpNameEMS
(int8_t*         name,
	int8_t           tag) {
	return W_CacheLumpNumEMS(W_GetNumForName(name), tag);
}

// used for stuff > 64k, especially titlepics, to draw one ems frame at a tiem
MEMREF
W_CacheLumpNameEMSFragment
(int8_t*         name,
	int8_t           tag,
    int16_t         pagenum,
    int32_t offset){
 

    if (pagedlumpcacheEMS[pagenum]){
        // erase cache
        Z_FreeEMSNew(pagedlumpcacheEMS[pagenum]);
    }

    pagedlumpcacheEMS[pagenum] = Z_MallocEMSNew(16384, tag, 0, ALLOC_TYPE_CACHE_LUMP);
    W_ReadLumpEMS(W_GetNumForName(name), pagedlumpcacheEMS[pagenum], offset, 16384);

    return pagedlumpcacheEMS[pagenum];
}
// W_CacheLumpName
//
patch_t*
W_CacheLumpNameEMSAsPatch
(int8_t*         name,
	int8_t           tag)
{
	return (patch_t*) Z_LoadBytesFromEMS(W_CacheLumpNumEMS(W_GetNumForName(name), tag));
}
 

void W_EraseLumpCache(int16_t index) {
	//I_Error("eraselumpcache %i", index);
	lumpcacheEMS[index] = 0;
}
