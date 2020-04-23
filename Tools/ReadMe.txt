***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory ("Tools") is part of the RomWBW System Software 
distribution archive.  It is the root directory for a series of 
programs that are used during the RomWBW build process.  These 
tools are included here as a convenience and their individual 
licenses are unaltered by their inclusion here.

ansicon:

ANSICON provides ANSI escape sequences for Windows console 
programs.  It provides much the same functionality as 'ANSI.SYS' 
does for MS-DOS.

bst:

The bst tool set is a multi-platform set of tools for developing with 
the Parallax Propeller microcontroller. bst stands for “Brad's Spin 
Tool”, however it is never capitalised.  This toolset is used to 
compile the Propeller firmware for PropIO and ParPortProp.

cpm:

This is the root of a directory tree containing native CP/M-80 
programs. These programs cannot be invoked directly by DOS/Windows.
Instead, they are executed via the Windows CP/M command line 
emulator 'zx' to build certain components of RomWBW.  The use of 
real CP/M-80 programs as part of the build process ensures proper 
construction of these components.

cpmtools:

This is a package of tools that allow a CP/M file system image to 
be created and managed from a Windows command line.  These tools 
are used to construct CP/M file system images included with the 
RomWBW distribution including the ROM disk image, floppy images, 
and hard disk images.

hex2bin:

A pair of programs by John Coffman to translate between Intel hex 
file format and pure binary images.

rawwritewin:

Program which can be used to write a floppy disk image to an 
actual floppy disk.

simh:

A Z80 simulator for Windows.  This simulator allows RomWBW ROM 
images to be tested on Windows, if desired.

tasm32:

A cross-compiler that runs on Windows and assembles standard 
Z80-based source files.  This tool is the primary assembler for 
the RomWBW HBIOS.

Win32 Disk Imager:

Program which can read or write hard disk images directly to or 
from CF Cards or SD Cards.

zx:

A port of zxcc for Windows.  This program is a command line 
CP/M-80 emulator.  It allows many CP/M-80 programs to run directly 
from a Windows command prompt.  This tool is used to run the CP/M 
programs in the cpm directory listed above.