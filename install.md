## Installing
Usually, a package comes with binaries pre-compiled for Windows. Thus, all you have to do is extract the package that Nebunoid and its assets were in, and you are all set. Nebunoid has been tested on Windows 10. It has been compiled using FreeBASIC 1.09.0.

To build new Windows binaries isn't *that* difficult, but you'll need to install additional libraries to ensure proper linking. Afterwards, just type in `fbc Nebunoid.bas Nebunoid.rc -s gui` in a command shell to compile the main game, or use an IDE able to pass that command. `fbc NebEdit.bas Nebunoid.rc -s gui` will instead build the level editor.

### Common Libraries
Regardless of platform, you will need to install [FBSound](https://www.freebasic.net/forum/viewtopic.php?t=17740).

### GNU/Linux
Installing under GNU/Linux, on the other hand, is not so simple. Since the architecture for this system is all over the place, no binaries are provided for GNU/Linux. A simple makefile is supplied.

### FreeBSD
We presume instructions are similiar to GNU/Linux, but this is untested. Feel free to experiment as need be, until you are able to build your own program.

### Wine
Alternatively, if you can figure out how to use [Wine](http://www.winehq.org/), then you can use it to run the pre-compiled Windows binaries. This is likely the only way to run Nebunoid outside of the systems above, as FreeBASIC compiler tools are not provided for any other platforms (except DOS).

That being said, it *might* be remotely possible to compile a native DOS build, but this is extremely tricky to pull off, and is impossible to cross-compile from a 64-bit Windows system. Building for DOS is untested.
