This tree now contains makefiles and tools to build on Linux and 
macOS. Linux is rather more thoroughly tested compared to macOS.

To get here, TASM and the propeller generation tools needed to be 
replaced, and since the unix filesystem is usually case-sensitive, 
and CP/M and windows are not, the cpm tools were made case-insensitive.

TASM was replaced with uz80as, which implements a subset of TASM and 
fixes some bugs.  However, I needed to add some functionality to make 
it build the sources as they exist in this tree.   In particular, one 
thing to be very careful of is that TASM is not entirely consistent 
with respect to the .DS directive. it's usually a bad idea to mix 
.DS, .FILL, .DB with .ORG.

	.DS n is best thought of as .ORG $ + n
	.ORG  changes the memory pointer, but does not change the file
	      output point.  It works a lot more like M80, SLR* .PHASE

It assumes that you have some standard system tools and libraries 
installed, specifically: gcc, gnu make, libncurses, and srecord.
Typically, something like this will take care of adding all
required packages in Linux:

	sudo apt install build-essential libncurses-dev srecord

For MacOS, you will need:

	brew install srecord

To build:
	cd to the top directory and type "make".

By default, this will generate all of the standard configurations of
RomWBW for all platforms.  If you just want to build the ROM for a
specific platform and configuration you can use

	make ROM_PLATFORM=<platform> ROM_CONFIG=<config>

where <platform> is one of the supported platforms such as SBC, RCZ80, 
etc. and <config> is a configuration of that platform.  For example,
to build the "126" configuration of the "SCZ180" platform:

	make ROM_PLATFORM=SCZ180 ROM_CONFIG=126

Please be aware that the make-based build does have a few deficiencies.

First and most important, the Makefiles do not handle reruns very well.
To ensure a full buld, use "make clean" from the top level directory
before running the actual build.

Second, there are some build failures that will not stop the make 
process.  Most of this is because real CP/M 2.2 tools are used in 
places and CP/M 2.2 does not allow programs to return a result code.

Third, not all dependencies are properly handled.  So, changes to some
files will not cause things to rebuild as appropriate.  In general, I
recommend doing a "make clean" before running "make" to ensure that
everything is fully rebuilt.

For macOS users, you may encounter a failure reading or writing files.
This is caused by protection features in macOS (at least, in Catalina)
that prevent programs built on your local system (unsigned) from
running.  To disable this feature:

1) Make sure you exit System Preferences.
2) Open a terminal session and type the following.  You will need to
   authenticate with an admin account.  sudo spctl --master-disable
3) Exit terminal
4) Go into System Preferences and choose Security and Privacy
5) Select the General tab if it isn't already selected
6) You should now see a third selection under
   "Allow apps downloaded from:" of Anywhere - select this.
7) Now you can run the build successfully.

DISCLAIMER: You do this at your own risk.  I highly recommend that you
return the settings back to normal immediately after doing a build.

Heavy use is made of make's include facility and pattern rules. The 
master rule set is in Tools/Makefile.inc.  Changes here will affect 
almost every Makefile, and where exceptions are needed, the overrides 
are applied in the lower Makefiles.

These tools can run a windows-linux regression test, where all the 
binaries are compared to a baseline windows build.

Credit:

	uz80as was written by Jorge Giner Cordero, 
	jorge.giner@hotmail.com, and the original source can be found 
	at https://github.com/jorgicor/uz80as.

	The propeller tools use bstc and openspin, parallax tools from 
	http://www.fnarfbargle.com/bst.html 
	https://github.com/parallaxinc/OpenSpin Note that bst is not 
	open source or even currently maintained, so I could not 
	generate a version for 64 bit macOS.

	cpmtools were the most current I could find, and it has been 
	hacked to do case-insensitivity. These are not marked, and are 
	not extensive.

	zxcc is from the distributed version, and also has local hacks 
	for case insensitivity.

	Both zxcc and cpmtools ship with an overly complicated makefile 
	generation system and this is ignored.

	This whole Linux build framework is the work of Curt Mayer, 
	curt@zen-room.org. Use it for whatever you like; this is not 
	my day job.
