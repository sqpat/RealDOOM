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
        if (++length == 9)
            I_Error ("Filename base of %s >8 chars",path);

        *dest++ = toupper((int32_t)*src++);
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
    wadinfo_t           header;
    lumpinfo_t*         lump_p;
	uint16_t            i;
	int32_t                 handle;
	int32_t                 length;
	uint16_t                 startlump;
    filelump_t*         fileinfo;
    filelump_t          singleinfo;
	int32_t                 storehandle;
    
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
        printf ("\tcouldn't open %s\n",filename);
        return;
    }

    printf ("\tadding %s\n",filename);
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
            // Homebrew levels?
            if (strncmp(header.identification,"PWAD",4))
            {
                I_Error ("Wad file %s doesn't have IWAD "
                         "or PWAD id\n", filename);
            }
            
            modifiedgame = true;                
        }
        header.numlumps = (header.numlumps);
        header.infotableofs = (header.infotableofs);
        length = header.numlumps*sizeof(filelump_t);
        fileinfo = alloca (length);
        lseek (handle, header.infotableofs, SEEK_SET);
        read (handle, fileinfo, length);
        numlumps += header.numlumps;
    }
// numlumps 1264
    
    
    // Fill in lumpinfo
    lumpinfo = realloc (lumpinfo, numlumps*sizeof(lumpinfo_t));

    if (!lumpinfo)
        I_Error ("Couldn't realloc lumpinfo");

    lump_p = &lumpinfo[startlump];
        
    storehandle = reloadname ? -1 : handle;
        
    for (i=startlump ; i<numlumps ; i++,lump_p++, fileinfo++)
    {
        lump_p->handle = storehandle;
        lump_p->position = (fileinfo->filepos);
        lump_p->size = (fileinfo->size);
        strncpy (lump_p->name, fileinfo->name, 8);
    }
        
    if (reloadname)
        close (handle);
}




//
// W_Reload
// Flushes any of the reloadable lumps in memory
//  and reloads the directory.
//
void W_Reload (void)
{
    wadinfo_t           header;
	uint16_t                 lumpcount;
    lumpinfo_t*         lump_p;
	uint16_t            i;
	int32_t                 handle;
	int32_t                 length;
    filelump_t*         fileinfo;
        
    if (!reloadname)
        return;
                
    if ( (handle = open (reloadname,O_RDONLY | O_BINARY)) == -1)
        I_Error ("W_Reload: couldn't open %s",reloadname);

    read (handle, &header, sizeof(header));
    lumpcount = (header.numlumps);
    header.infotableofs = (header.infotableofs);
    length = lumpcount*sizeof(filelump_t);
    fileinfo = alloca (length);
    lseek (handle, header.infotableofs, SEEK_SET);
    read (handle, fileinfo, length);
    
    // Fill in lumpinfo
    lump_p = &lumpinfo[reloadlump];
        
    for (i=reloadlump ;
         i<reloadlump+lumpcount ;
         i++,lump_p++, fileinfo++)
    {

        lump_p->position = (fileinfo->filepos);
        lump_p->size = (fileinfo->size);

		if (lumpcacheEMS[i]) {
			Z_FreeEMSNew(lumpcacheEMS[i]);
		}


    }
        
    close (handle);
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
	int32_t         size;
    
    // open all the files, load headers, and count lumps
    numlumps = 0;

    // will be realloced as lumps are added
    lumpinfo = malloc(1);       

    for ( ; *filenames ; filenames++)
        W_AddFile (*filenames);

    if (!numlumps)
        I_Error ("W_InitFiles: no files found");
    

	size = numlumps * sizeof(*lumpcacheEMS);
	lumpcacheEMS = malloc(size);

	if (!lumpcacheEMS)
		I_Error("Couldn't allocate lumpcacheEMS");

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
int16_t W_GetNumForName (int8_t* name)
{
	int16_t i;

    i = W_CheckNumForName (name);
    
    if (i == -1)
      I_Error ("W_GetNumForName: %s not found!", name);
      
    return i;
}


//
// W_LumpLength
// Returns the buffer size needed to load the given lump.
//
int32_t W_LumpLength (int16_t lump)
{
    if (lump >= numlumps)
        I_Error ("W_LumpLength: %i >= numlumps",lump);

    return lumpinfo[lump].size;
}



//
// W_ReadLump
// Loads the lump into the given buffer,
//  which must be >= W_LumpLength().
//
void
W_ReadLumpEMS
(int16_t           lump,
  MEMREF         lumpRef )
{
	int32_t         c;  // size, leave as 32 bit
    lumpinfo_t* l;
	int32_t         handle;
	byte		*dest;
	mapsidedef_t* data;

    if (lump >= numlumps)
        I_Error ("W_ReadLump: %i >= numlumps",lump);

    l = lumpinfo+lump;
        
    I_BeginRead ();
        
    if (l->handle == -1)
    {
        // reloadable file, so use open / read / close
        if ( (handle = open (reloadname,O_RDONLY | O_BINARY)) == -1)
            I_Error ("W_ReadLump: couldn't open %s",reloadname);
    }
    else
        handle = l->handle;
	dest = Z_LoadBytesFromEMS(lumpRef);
    lseek (handle, l->position, SEEK_SET);
    c = read (handle, dest, l->size);

    if (c < l->size)
        I_Error ("W_ReadLump: only read %i of %i on lump %i",
                 c,l->size,lump);       

    if (l->handle == -1)
        close (handle);

	if (lump == 75) {
		data = (mapsidedef_t *)dest;
		//I_Error("data is %i %i %i %s", lump, lumpRef, l->size, data->toptexture);



	}


    I_EndRead ();
}




void
W_ReadLump
(int16_t           lump,
	void*         dest)
{
	int32_t         c;
	lumpinfo_t* l;
	int32_t         handle;

	if (lump >= numlumps)
		I_Error("W_ReadLump: %i >= numlumps", lump);

	l = lumpinfo + lump;

	I_BeginRead();

	if (l->handle == -1)
	{
		// reloadable file, so use open / read / close
		if ((handle = open(reloadname, O_RDONLY | O_BINARY)) == -1)
			I_Error("W_ReadLump: couldn't open %s", reloadname);
	}
	else
		handle = l->handle;

	lseek(handle, l->position, SEEK_SET);
	c = read(handle, dest, l->size);

	if (c < l->size)
		I_Error("W_ReadLump: only read %i of %i on lump %i",
			c, l->size, lump);

	if (l->handle == -1)
		close(handle);

	I_EndRead();
}


int16_t W_CacheLumpNumCheck(int16_t lump, int16_t error) {


	if (lump >= numlumps) {
		printf("W_CacheLumpNumCheck: %i %i",  lump, error);
		I_Error("W_CacheLumpNumCheck: %i %i",  lump, error);
		return true;
	}
	return false;
}

 
//
// W_CacheLumpNum
//
MEMREF
W_CacheLumpNumEMS
(	int16_t           lump,
	int8_t			tag)
{
	byte	*lumpmem;
	if (lump >= numlumps)
		I_Error("W_CacheLumpNum: %i >= numlumps", lump);


//	if (!lumpcache[lump])
	if (!lumpcacheEMS[lump]) {
		// read the lump in
		//printf ("cache miss on lump %i\n",lump);
		// needs an 'owner' apparently...
		lumpcacheEMS[lump] = Z_MallocEMSNewWithBackRef(W_LumpLength(lump), tag, 0xFF, ALLOC_TYPE_CACHE_LUMP, lump + BACKREF_LUMP_OFFSET);

		W_ReadLumpEMS(lump, lumpcacheEMS[lump]);
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
	int8_t           tag)
{
	return W_CacheLumpNumEMS(W_GetNumForName(name), tag);
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
