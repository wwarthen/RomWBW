Introduction
============

OpenSpin is an open source compiler for the Spin/PASM language of the Parallax Propeller. It was ported from Chip Gracey's original x86 assembler code. The only binary differences in the output are from the corrected handling of floating point numbers (which is now IEEE compliant).

There are solution/project files for VS 2015 & VS 2017, and there are make files for use with GCC/clang/etc. Tested on MinGW, linux, and Mac OSX. They build the PropellerCompiler library and openspin.exe.

The code successfully compiles all of the Library files shipped with PropTool as well as all of the files available in the OBEX as of August 2012. That's approximately 1450 spin files.

OpenSpin allows symbols to be 254 characters long (instead of 31), has unused method elimination, and supports a basic [preprocessor](https://github.com/reltham/OpenSpin/wiki/Preprocessor). 

PropellerCompiler library
-------------------------

PropellerCompiler.cpp/h contain the interface to the compiler. Look at openspin.cpp for an example of how to work with the interface.

openspin.exe
------------

openspin.exe is a command line wrapper for the compiler library. You give it a spin file and it passes it through the compiler and produces a .binary (or optional .eeprom) file with the same base name as the passed in spin file. There are several [command line options](https://github.com/reltham/OpenSpin/wiki/CommandLine) available. Run openspin.exe with no arguments to get a usage description.

Downloads
---------

### Builds provided by David Zemon's TeamCity service:
 Note: These are updated automatically whenever changes are submitted here, so they include changes between releases.
* [Linux x86_64](http://david.zemon.name:8111/repository/download/OpenSpin_LinuxX8664/lastSuccessful/openspin.tar.gz?guest=1)
* [Windows x86](http://david.zemon.name:8111/repository/download/OpenSpin_WindowsX86/lastSuccessful/openspin.zip?guest=1)
* [Mac OS X](http://david.zemon.name:8111/repository/download/OpenSpin_MacOsX/2548:id/openspin.tar.gz?guest-1)
* [Raspberry Pi](http://david.zemon.name:8111/repository/download/OpenSpin_RaspberryPi/lastSuccessful/openspin.tar.gz?guest=1)

Thanks
------

* Thanks to Steve Denson, for the Makefile and testing on linux!
* Thanks to David Betz for testing on Mac OSX.
* Thanks to Eric Smith for providing the code and helping with integrating the preprocessor.
