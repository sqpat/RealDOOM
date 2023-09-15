# RealDOOM

![](https://github.com/sqpat/RealDOOM/blob/master/superalpha.gif)

RealDOOM is a (currently in progress) port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode, to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical fidelity as the original game.

While the port current builds to Real Mode, it still has many issues as you can see from the gif above.

The port also builds to 32 bit mode (for development and testing purposes) and runs with many of the 16 bit constraints in mind such as using an EMS simulator. To build this build, run make.bat.

You can adjust the EMS page frames available by changing NUM_EMS_PAGES in doomdefs.h from 4 to a higher number. This is not really hooked up in 16-bit mode yet. Eventually, 8-10 EMS active pages will represent a very well-configured 286 system and 'best case' performance for a 16 bit cpu running the game.



### Removed features (not planned to be re-added)
 - multiplayer and netplay
 - joystick support
 

###  Broken/unimplemented features (planned to be fixed)
 - sound (will require a 16 bit library)
 - savegames (will require a rewrite of the archive/unarchive code)
 

There are also a lot of hard caps on things like texture size and count, node count, etc, which will probably make many WADs unplayable. oh well.

For those interested in the technical details, a quick summary of what has been done is:
 - Moved all Z_Malloc allocations to an EMS based version and new Zone Memory manager that supports 16k memory blocks
 - Rewrote much of the game code to prevent pulling too many heap variables at once, as they will get paged out and dereferenced
 - Changed many 32 bit variables internally to 16 and 8 bit when those extra bits weren't being used.


### Known bugs:
 - sound, saves are unimplemented/nonfunctional
 - content outside of doom1 shareware has not been tested at all and may be very broken
 - finale has not been tested at all
 - there is a particular render bug with fuzz draws, it comes up twice in demo3 early on where you see a vertical fuzzy line drawn around the first spectre towards when its killed. not sure the cause of this yet.
 - some issues with fullscreen drawing/backbuffer, especially in intermissions and help screen
 

### Long term ideas:
 - <strike> If conventional memory has enough space, add wolf3d-style conventional allocations of key variables </strike>
 - <strike> Move strings into an external file so we can load it into an ems variable at runtime and free several KB of static space. </strike>
 - Use Z_Malloc "source hints" to store items in EMS pages locally to other fields that will be used at the same time. having pages dedicated to mobj_t allocations will probably result in much less paging.
 - <strike> Reduce backbuffer usage or add option to get rid of it (probably) </strike>
 - More aggressive use of overlays and rewriting of some files to increase the amount of memory saved by overlays



## Progress of 16-bit build
 - Update! Fixed a number of bugs, mostly around pointer arithmetic. Timedemos can play, but play wrong. the video is also all wrong. But the game is sort of running in 16 bit mode! This was great progress after a long time with no progress and mysterious crashes. There are going to be many bugs to fix, but it's a lot better than figuring out memory corruption.

