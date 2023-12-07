# RealDOOM

[![Old Demo Recording](http://img.youtube.com/vi/O613ctZRBuY/0.jpg)](https://www.youtube.com/watch?v=O613ctZRBuY "RealDOOM v 0.1 Timedemo On 4.77 MhZ 8088")

RealDOOM is an in progress port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode, to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical detail as the original game.

As of release 0.1, the game is mostly playable with the shareware DOOM1.WAD file. 

The port also builds to 32-bit mode (for development and testing purposes) and runs with many of the 16 bit constraints in mind such as using an EMS simulator. To build this build, run make.bat. The 16-bit build uses make16.bat

86box is  recommended over DOSBox for the 16 bit version, as it is quite faster. If running on real hardware, a pentium or fast 486 is current recommended.

### Removed features (not planned to be re-added)
 - multiplayer and netplay
 - joystick support
 

###  Broken/unimplemented features (planned to be fixed)
 - sound (will require a 16 bit library)
 - savegames (will require a rewrite of the archive/unarchive code)
 - screen wipe
 - finale/credits screen

There are also a lot of hard caps on things like texture size and count, node count, etc, which will probably make many custom WADs unplayable. oh well.

For those interested in the technical details, a quick summary of what has been done is:
 - Moved all Z_Malloc allocations to an EMS based version and new Zone Memory manager that supports 16k memory blocks
 - Rewrote much of the game code to prevent pulling too many heap variables at once, as they will get paged out and dereferenced
 - Changed many 32 bit variables internally to 16 and 8 bit when those extra bits weren't being used.


### Known bugs:
 - content outside of doom1 shareware has not been tested at all and may be very broken.
 - there is a particular render bug with fuzz draws, it comes up twice in demo3 early on where you see a vertical fuzzy line drawn around the first spectre towards when its killed. not sure the cause of this yet.
 - some issues with fullscreen drawing/backbuffer, especially in intermissions
 - memory (or memory refs) eventually run out during a long term session
 

### Long term ideas:
 - ~~Use of UMBs for extra memory~~ Done
 - Use of EMS 4.0 multitasking features for better, faster memory swapping
 - Assembly code versions of the main math and render functions


### Speed

Current Realtics/FPS for timedemo3 with screenblocks 5 and high quality:

| Machine Specs  | 86box  |  FPS | Real Hardware | FPS |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| Pentium MMX 233  | 1148 | 65.06 |  830  | 89.99 |
| Pentium 133  | 1695  |44.06 |||
| AMD 5x86 P90  | 2637 | 28.32 |||
| 486 DX2-66  | 5637|  13.25 |||
| 486 SX-33  | 10529 | 7.09| ||
| 386 DX-40  | 12989  | 5.75| 12534| 5.96|
| 286-25  | 31821   | 2.35| ||
| 286-20  ||| 32377 | 2.31|
| v20 9.5 MhZ  | || 162157   | 0.46 |  
| 8088 4.77 MhZ  | || 351970   | 0.21 |  


I think we are looking for around 5-10x performance uplift from the current point to reach playability on fast 286es.
