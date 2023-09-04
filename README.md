# RealDOOM

There are a few people looking at this repo now so I figured I would write up something very quickly here.


RealDOOM is a (currently in progress) port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode, to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical fidelity as the original game.

While the port current builds to Real Mode, it fails during before drawing on the first frame, so it is not playable yet. In order to build the 16-bit build, run make16.bat. 16-bit RealDOOM requires EMS 3.2 or higher for 4 pages of EMS memory.

The port also builds to 32 bit mode (for development and testing purposes) and runs with many of the 16 bit constraints in mind such as using an EMS simulator. To build this build, run make.bat.

Right now the primary focus of RealDOOM is accuracy - speed is a nice 2nd.


You can adjust the EMS page frames available by changing NUM_EMS_PAGES from 4 to a higher number. This is not really hooked up in 16-bit mode yet.


There are a few features removed from RealDOOM including:
 - multiplayer and netplay
 - joystick support
 

And a few features broken and unimplemented:
 - sound (will require a 16 bit library)
 - savegames (will require a rewrite of the archive/unarchive code)
 - TitlePic/etc display (requires 65k memory allocations, which is bigger than the 64k that 4 EMS pages requires). This can probably be fixed with custom code but isn't a high priority now.


There are also a lot of hard caps on things like texture size and count, node count, etc, which will probably make many WADs unplayable. oh well.

For those interested in the technical details, a quick summary of what has been done is:
 - Moved all Z_Malloc allocations to an EMS based version and new Zone Memory manager that supports 16k memory blocks
 - Rewrote much of the game code to prevent pulling too many heap variables at once, as they will get paged out and dereferenced
 - Changed many 32 bit variables internally to 16 and 8 bit when those extra bits weren't being used.
