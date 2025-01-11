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
//	Savegame I/O, archiving, persistence.
//


#ifndef __P_SAVEG__
#define __P_SAVEG__


// Persistent storage/archiving.
// These are the load / save game routines.
void __far P_ArchivePlayers (void);
void __far P_UnArchivePlayers (void);
void __far P_ArchiveWorld (void);
void __far P_UnArchiveWorld (void);
void __far P_ArchiveThinkers (void);
void __far P_UnArchiveThinkers (void);
void __far P_ArchiveSpecials (void);
void __far P_UnArchiveSpecials (void);



#endif
