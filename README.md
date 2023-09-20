# RealDOOM

[![Recent Demo Recording](http://img.youtube.com/vi/Hhpkw7wM1vI/0.jpg)](http://www.youtube.com/watch?v=Hhpkw7wM1vI "RealDOOM Timedemo 2 On 286")

Above is a youtube link that takes you to video of a recent demo playback showing off the port.

RealDOOM is a (currently in progress) port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode, to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical detail as the original game.

While the port current builds to Real Mode, it still has a number of issues compared to the 32 bit version. However, it is very nearly in a playable alpha or beta state.

The port also builds to 32-bit mode (for development and testing purposes) and runs with many of the 16 bit constraints in mind such as using an EMS simulator. To build this build, run make.bat. The 16-bit build uses make16.bat

You can adjust the EMS page frames available by changing NUM_EMS_PAGES in doomdefs.h from 4 to a higher number. This is not really hooked up in 16-bit mode yet. Eventually, 8-10 EMS active pages will represent a very well-configured 286 system and 'best case' performance for a 16 bit cpu running the game. EMM386 works great for 386 and later.

86box is heavily recommended over DOSBox for the 16 bit version. It is over 10 times faster. If running on real hardware, an MMX 233 or so should be fine to get decent framerate with the current build.

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
 - in 16 bit mode, there are some issues with physics causing timedemo desyncs.
 - in 16 bit mode, the intermission screens display all wrong
 - content outside of doom1 shareware has not been tested at all and may be very broken.
 - finale has not been tested at all
 - there is a particular render bug with fuzz draws, it comes up twice in demo3 early on where you see a vertical fuzzy line drawn around the first spectre towards when its killed. not sure the cause of this yet.
 - some issues with fullscreen drawing/backbuffer, especially in intermissions and help screen
 

### Long term ideas:
 - Use Z_Malloc "source hints" to store items in EMS pages locally to other fields that will be used at the same time. having pages dedicated to mobj_t allocations will probably result in much less paging.
 - More aggressive use of overlays and rewriting of some files to increase the amount of memory saved by overlays
 - Stick mobjs (or something) in that free 20-30k of the default data segment
 - Make smaller versions of mobjs that do not store momx, momy, health, and other such 'monster' type fields.
 - Improve blocklinks implementation
 - Hybride EMS/conventional visplanes
 - Assembly code versions of the main math and render functions
 - EMS 4.0 style support of more than 4 page frames in 16 bit mode


## Progress of 16-bit build
 - It ran on a 286! Poorly, as expected. There are still a few bugfixes necessary to fix desyncs, then work will continue on optimizations.
 

