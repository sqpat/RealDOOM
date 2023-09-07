# RealDOOM

There are a few people looking at this repo now so I figured I would write up something very quickly here.

RealDOOM is a (currently in progress) port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode, to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical fidelity as the original game.

While the port current builds to Real Mode, it fails during before drawing on the first frame, so it is not playable yet. In order to build the 16-bit build, run make16.bat. 16-bit RealDOOM requires EMS 3.2 or higher for 4 pages of EMS memory.

The port also builds to 32 bit mode (for development and testing purposes) and runs with many of the 16 bit constraints in mind such as using an EMS simulator. To build this build, run make.bat.
 

You can adjust the EMS page frames available by changing NUM_EMS_PAGES in doomdefs.h from 4 to a higher number. This is not really hooked up in 16-bit mode yet. Eventually, 8-10 EMS active pages will represent a very well-configured 286 system and 'best case' performance for a 16 bit cpu running the game.



### Removed features (not planned to be re-added)
 - multiplayer and netplay
 - joystick support
 

###  Broken/unimplemented features (planned to be fixed)
 - sound (will require a 16 bit library)
 - savegames (will require a rewrite of the archive/unarchive code)
 - TitlePic/etc display (requires 65k memory allocations, which is bigger than the 64k that 4 EMS pages requires). This can probably be fixed with custom code but isn't a high priority now.


There are also a lot of hard caps on things like texture size and count, node count, etc, which will probably make many WADs unplayable. oh well.

For those interested in the technical details, a quick summary of what has been done is:
 - Moved all Z_Malloc allocations to an EMS based version and new Zone Memory manager that supports 16k memory blocks
 - Rewrote much of the game code to prevent pulling too many heap variables at once, as they will get paged out and dereferenced
 - Changed many 32 bit variables internally to 16 and 8 bit when those extra bits weren't being used.


### Known bugs:
 - melee attack range seems to be broken
 - there is a texture mapping bug especially with animated textures and doors. i think it has something to do with texture offsets having been made 8 bits.
 - sound, saves are unimplemented/nonfunctional
 - various fullscreen artwork will fail to allocate due to being > 64k 
 - content outside of doom1 shareware has not been tested at all and may be very broken
 - finale has not been tested at all
 - there is a particular render bug with fuzz draws, it comes up twice in demo3 early on where you see a vertical fuzzy line drawn around the first spectre towards when its killed. not sure the cause of this yet.

### Long term ideas:
~~ - If conventional memory has enough space, add wolf3d-style conventional allocations of key variables~~
~~ - Move strings into an external file so we can load it into an ems variable at runtime and free several KB of static space.~~
 - Use Z_Malloc "source hints" to store items in EMS pages locally to other fields that will be used at the same time. having pages dedicated to mobj_t allocations will probably result in much less paging.
 - Reduce backbuffer usage or add option to get rid of it (probably)
 - More aggressive use of overlays and rewriting of some files to increase the amount of memory saved by overlays



## Progress of 16-bit build
The 16 bit build just randomly fails to complete certain function calls like NetTics after the level is setup. I'm not sure what is going on - i will have to try debugging on real hardware or a better environment in a few days.
In the short term I will just go back to a couple of general improvements to lower memory usage as i have wanted to do for a while, then go back to tackling the 16 bit build.
