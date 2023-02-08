***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory is the root directory of the source tree for RomWBW.

This document describes the process to build a customized version 
of the RomWBW firmware.  RomWBW was explicitly organized in a way 
that makes it very easy to rebuild the firmware.

Significant customization can be achieved with a custom built 
firmware using simple option configuration files.  You can 
customize your firmware to:

    - Include support for add-on support boards such as
      the DiskIO, Dual-IDE, etc.
    - Modify operational parameters such as serial port
      speed or wait state insertion.
    - Add or remove programs or files contained on the disk images.
    
Virtually all source code is provided including the operating
systems themselves, so advanced users can easily modify any of
the software.

A cross-platform approach is used to build the RomWBW firmware. 
The software is built using a modern Windows, Linux, or Mac
computer, then the resulting firmware image is programmed into
the ROM of your RetroBrew Computer CPU board.

Windows Build System Requirements
---------------------------------

For Microsoft Windows computers, all that is required to build the
firmware is the RomWBW distribution zip archive file.  The zip
archive package includes all of the required source code 
(including the operating systems) and the programs required to run 
the build.

The build process is run via some simple scripts that automate the 
process.  These scripts utilize both batch command files as well as 
Windows PowerShell.  Windows 7 or greater is recommended.  If you want 
to use Windows Vista or XP, you will need to first install PowerShell 
which available for free from Microsoft.  Either 32 or 64 bit versions 
of Microsoft Windows are fine.No additional programs need to be 
installed to run the build.

Linux Build System Requirements
-------------------------------

You must have some standard system tools and libraries 
installed, specifically: gcc, gnu make, libncurses, and srecord.
Typically, something like this will take care of adding all
required packages in Linux:

	sudo apt install build-essential libncurses-dev srecord

Since there are many variants and releases of Linux, it is difficult
to ensure the build will work in all cases.  The current stable
release of Ubuntu is used to verify the build runs.

MacOS Build System Requirements
-------------------------------

You will need to install the srecord package to complete the
build process:

	brew install srecord

You may encounter a failure reading or writing files. This is caused by 
protection features in MacOS (at least, in Catalina) that prevent 
programs built on your local system (unsigned) from running.  To 
disable this feature:

1) Make sure you exit System Preferences.
2) Open a terminal session and type the following.  You will need to
   authenticate with an admin account: sudo spctl --master-disable
3) Exit terminal
4) Go into System Preferences and choose Security and Privacy
5) Select the General tab if it isn't already selected
6) You should now see a third selection under
   "Allow apps downloaded from:" of Anywhere - select this.
7) Now you can run the build successfully.

DISCLAIMER: You do this at your own risk.  I highly recommend that you
return the settings back to normal immediately after doing a build.

Process Overview
----------------

The basic steps to create a custom ROM are:

  1) Create/update configuration file (optional).

  2) Update/Add/Delete any files as desired to customize the disk
     images (optional).

  3) Run the build scripts and confirm there are no errors.

  4) Program the resultant ROM image and/or write thedisk images.

Note that steps 1 and 2 are performed to customize your ROM as 
desired.  If you want to simply build a standard configuration, it is 
*not* necessary to perform steps 1 or 2 before running a build.  In 
fact, I strongly recommend that you skip steps 1 and 2 initially and 
just perform perform steps 3 and 4 using the standard configuration to 
make sure that you have no issues building and programming a ROM that 
works the same as a pre-built ROM.

Each of the 4 steps above is described in more detail below.

1. Create/Update Configuration File
-----------------------------------

The options for a build are primarily controlled by a configuration 
file that is included in the build process.  In order to customize 
your settings, it is easiest to make a copy of an existing 
configuration file and make your changes there.

RomWBW uses the concept of a "platform" and "configuration" to
define the settings for a build.  Platform refers to one of the core
systems supported.  Configuration refers to the settings that
customize the build.  The configuration is modifies the platform
defaults as desired.

The platform names are predefined.  Refer to the following table 
to determine the <plt> component of the configuration filename:

	SBC		Retrocomputing ECB Z80 SBC V1/V2
	N8		RetroComputing N8 SBC
	MK4		RetroComputing Mark IV Z180
	ZETA		Sergey Kiselev's Zeta Z80
	ZETA2		Sergey Kiselev's Zeta V2 Z80
	RCZ80		RCBus Z80
	RCZ180		RCBus Z180
	SCZ180		Stephen Cousins' Z180 Systems
	RCZ280		RCBus Z280
	EZZ80		Sergey Kiselev's Easy/Tiny Z80
	DYNO		Dyno Z180 Single Board Computer
	MBC		Andrew Lynch's Nhyodyne Z80 MBC
	RPH		Andrew Lynch's Rhyophyre Z180 SBC
	UNA		John Coffman's UNA System

Configuration files are found in the Source\HBIOS\Config 
directory.  If you look in the this directory, you will see a 
series of files named <plt>_<cfg>.asm.  By convention, all
configuration files start with the platform identifier followed
by an underscore.  You will see later that the build process does
require this naming convention and it allows you to easily see which
configuration files apply to each of the platforms supported.

Each of the possible platforms has at least one configuration file.  In 
many cases, there will be a standard ("std") configuration for the 
platform.  For example, there is a file called MK4_std.asm.  This is 
the standard ("std") configuration for a Mark IV CPU board.

The <cfg> portion of the filename can be anything desired.  To create
your own custom configuration, you can modify an existing configuration
file or (preferably), you could copy an existing configuration file
to a new name of your choosing and make your changes there.  For
example, you could copy "MK4_std.asm" to something like "MK4_cust.asm".
Now, you can make changes to your private copy of the configuration
and easily revert back to the original if you have problems.

It is important to understand how configuration files are processed.
They start by inheriting all of the default settings for the
platform.  This is accomplished via the "#include" directive near
the top of the file.  For the "MK4_std.asm" configuration file,
this line reads:

#include "cfg_mk4.asm"

When the configuration file (MK4_std.asm) is processed, it will first
read in all the default platform settings from "cfg_mk4.asm".  All of
the platform default configuration files are found in the parent
directory (the HBIOS directory).  You will see a "cfg_<plt>.asm" for
each platform in the parent directory.

If you look at the platform configuration file, you will see that it
has many more settings than you found in the build configuration file.
The platform configuration file contains *all* possible settings for
the platform and defines their default value.  The settings in the
build configuration file just override the platform default settings.

Note that the settings in the platform configuration file are all
defined using ".EQU" whereas the build configuration file uses ".SET".
This is because ".EQU" defines the initial value for a variable and
".SET" modifies a pre-existing value.  You *must* use ".EQU" and ".SET"
correctly or the assembler will complain very loudly.

In our example, let's say you have added a DiskIO V3 board to your 
Mark IV system and want to include floppy support. You will see a 
couple lines similar to these in the config file:

FDENABLE	.SET	TRUE		; FD: ENABLE FLOPPY DISK DRIVER (FD.ASM)
FDMODE		.SET	FDMODE_DIDE	; FD: DRIVER MODE: FDMODE_[DIO|ZETA|ZETA2|DIDE|N8|DIO3|RCSMC|RCWDC|DYNO|EPWDC]

FDENABLE is already set to TRUE, so that is fine.  However, FDMODE
is not correct because it specifies a different board.  To fix this,
just modify the line to read:

FDMODE		.SET	FDMODE_DIO3	; FD: DRIVER MODE: FDMODE_[DIO|ZETA|ZETA2|DIDE|N8|DIO3|RCSMC|RCWDC|DYNO|EPWDC]

You are now probably wondering where to find detailed instructions for 
each of the configuration settings.  Sadly, this is an area where 
RomWBW is very deficient.  The changes to hardware support happen so 
fast that is have been virtually impossible to create such a document. 
If it is not obvious what you need to do when looking at the build 
configuration file, I recommend that you look at the platform 
configuration file in the parent directory.  It will contain all of the 
possible settings and their default values as well as a brief comment.  
In many cases this is enough information to figure out what to do.  If 
not, you will need to either look at the HBIOS source code or request 
help in any of the RomWBW support communities (people are typically 
very helpful).  You can also post questions or issues on the GitHub 
repository.

2. Update/Add/Delete Disk Files
-------------------------------

A major part of the RomWBW build process is the creation of the
ROM disk contents and the floppy/hard disk image files.

The files that are included on the ROM Disk of your ROM are copied 
from a set of directories during the build process.  This allows 
you to have complete flexibility over the files you want included 
in your ROM.

The ROM disk process starts in the Source/RomDsk directory.  Within
that directory, there are subdirectories for each of the different
possible ROM sizes that can be created.  The vast majority of all
ROMs are 512KB, so you will probably be interested primarily in the
ROM_512KB subdirectory.

These subdirectories are already populated in the distribution.  You do 
not need to do anything unless you want to change the files that are 
included on your ROM Disk.

In summary, the ROM Disk embedded in the ROM firmware you build, 
will include the files from the ROM_512KB directory (or the 
ROM_1024KB directory if building a 1024KB firmware, etc.).  

There is a ReadMe.txt document in the \Source\RomDsk directory 
with a more detailed description of this process.

Note that the standard 512K ROM disk is almost full.  So, if
you want to add files to it, you will need to delete other files
to free up some space.

Creation of the floppy/hard disk images is similar, but these
images are much larger and have many more files.  Additionally, the
process pulls in files from multiple places and creates multiple
formats.  The Source/Images directory of the distribution handles
the creations of these disk images.  There is a ReadMe.txt file there
that describes the process and how to customize your disk images.

3. Run the Build Process
------------------------

Regardless of whether you are using Windows, Linux, or MacOS to perform
the build, you will initiate the build at a command prompt.  So, you
start by starting a command window/terminal.  Make sure your
command prompt has the root "RomWBW" directory as the default.

For a Windows computer, the build is initiated by simply running the
command "Build".  To delete all files created during a build process,
use the "Clean" command.  I recommend doing this before each build.  It
will operate recursively on all directories.

For Linux or MacOS, you will use the command "make".  To delete all
files created during a prior build run, use the command "make clean".
I strongly recommend doing this before each build.

This will launch the build process for a complete RomWBW build including
ROM and disk images.  Some of the output may be confusing, so a sample
normal build run is included at the end of this document.

At a point in the middle of the build, you will be prompted to choose
the specific platform and configuration for your ROM.  For platform, be
sure to enter the platform identifier that corresponds to the ROM you
are creating.  The prompt will look something like this:

    Platform [SBC|MBC|ZETA|ZETA2|RCZ80|EZZ80|UNA|N8|MK4|RCZ180|SCZ180|DYNO|RCZ280]:

You will subsequently be prompted for the specific configuration that
you want to build.  It will display the available possibilities based
on the platform you previously chose.  Notice that you are choosing
the portion of the configuration filename that follows the platform
id:

    Configurations available:
     > std
     > cust
    Configuration:

Enter one of the configuration options to build a ROM with the 
associated config file.

At this point, the build should continue and you will see output 
related to the assembler runs and some utility invocations.  Just 
review the output for any obvioius errors.  Normally, all errors 
will cause the build to stop immediately and display an error 
message in red.

You will see some lines in the output indicating the amount of 
space various components have taken.  You should check these to 
make sure you do not see any negative numbers which would indicate 
that you have included too many features/drivers for the available 
memory space.  Here are examples of the lines showing the space 
used:

    HBIOS PROXY STACK space: 38 bytes.
    HBIOS INT space remaining: 82 bytes.
    DSRTC occupies 423 bytes.
    UART occupies 716 bytes.
    ASCI occupies 580 bytes.
    MD occupies 451 bytes.
    IDE occupies 1276 bytes.
    SD occupies 2191 bytes.
    HBIOS space remaining: 21434 bytes.

At the completion of the build process, you will find the resultant
ROM and disk image files in the Binary directory.  

There will be many disk image (".img") files created.  These are 
described in the RomWBW User Guide document.  Since RomWBW
encapsulates all hardware interface code in the ROM itself, the
disk image files are generic for all ROMs.  The only reason they
are built is to accommodate any disk content changes you may have
made.

4. Deploy the ROM
-----------------

Upon completion of a successful build, you should find the 
resulting firmware in the Binary directory.  The ROM file
will be called <plt>_<cfg>.rom matching the platform identifier
and configuration you chose.

Three output files will be created for a single build:

     <plt>_<cfg>.rom -	binary ROM image to burn to EEPROM
     <plt>_<cfg>.com -	executable version of the system image
			that can be copied via X-Modem to a
			running system to test the build
     <plt>_<cfg>.upd -	partial ROM image containing just the
			first 128KB which can be used to update
			only the "code" portion of your ROM
			and not modify the ROM disk

The actual ROM image is the file ending in .rom.  It will normally be 
512KB.  Simply burn the .rom image to your ROM and install 
it in your hardware.  The process for programming your ROM depends 
on your hardware, but the .rom file is in a pure binary format (it 
is not hex encoded).

You can alternatively reprogram your ROM in-situ (most hardware
supports this) using the FLASH application included with RomWBW.  This
is described in the "Upgrading" section of the RomWBW User Guide.

Refer to the document ReadMe.txt in the Binary directory for more 
information on the other two file extensions created.

Specifying Build Options on Command Line
----------------------------------------

If you are repeatedly running the build process, you may prefer to
specify the platform and configuration on the command line to avoid
being prompted each time.

Under Windows, you can specify the platform and configuration
like this:

    Build MK4 cust

Under Linux or MacOS, you can do the same thing like this:

    make ROM_PLATFORM=MK4 ROM_CONFIG=cust

In this case, you will not be prompted.  This is useful if you wish 
to automate your build process.

In the past, the size of the ROM could be specified as the third
parameter of the command.  This parameter is now deprecated and
the size of the ROM is specified in your configuration file
using the ROMSIZE variable.




Example Build Run (Windows)
---------------------------

C:\Users\Wayne\Projects\RomWBW>build

Building PropIO...
Brads Spin Tool Compiler v0.15.3 - Copyright 2008,2009 All rights reserved
Compiled for i386 Win32 at 08:17:48 on 2009/07/20
Loading Object PropIO
Loading Object AnsiTerm
Loading Object vgacolour
Loading Object E555_SPKEngine
Loading Object Keyboard
Loading Object safe_spi
Loading Object Parallax Serial Terminal Null
Program size is 13416 longs
Compiled 2227 Lines of Code in 0.054 Seconds
        1 file(s) moved.

Building PropIO2...
Brads Spin Tool Compiler v0.15.3 - Copyright 2008,2009 All rights reserved
Compiled for i386 Win32 at 08:17:48 on 2009/07/20
Loading Object PropIO2
Loading Object AnsiTerm
Loading Object vgacolour
Loading Object E555_SPKEngine
Loading Object Keyboard
Loading Object safe_spi
Loading Object Parallax Serial Terminal Null
Program size is 13420 longs
Compiled 2227 Lines of Code in 0.053 Seconds
        1 file(s) moved.

Building ParPortProp...
Brads Spin Tool Compiler v0.15.3 - Copyright 2008,2009 All rights reserved
Compiled for i386 Win32 at 08:17:48 on 2009/07/20
Loading Object ParPortProp
Loading Object AnsiTerm
Loading Object vgacolour
Loading Object E555_SPKEngine
Loading Object Keyboard
Loading Object safe_spi
Loading Object Parallax Serial Terminal Null
Loading Object FullDuplexSerial
Program size is 15484 longs
Compiled 2631 Lines of Code in 0.065 Seconds
        1 file(s) moved.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
        1 file(s) copied.

Building CBIOS for RomWBW...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
CBIOS extension info occupies 6 bytes.
UTIL occupies 525 bytes.
INIT code slack space: 2184 bytes.
HEAP space: 4034 bytes.
CBIOS total space used: 6144 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building CBIOS for UNA...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
CBIOS extension info occupies 6 bytes.
UTIL occupies 525 bytes.
INIT code slack space: 2025 bytes.
HEAP space: 3887 bytes.
CBIOS total space used: 6400 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building ccpb03...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building bdosb01...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
CP/M MACRO ASSEM 2.0
D7F2
00BH USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 1887 bytes (075FH) to file P0:CCP.BIN
Start address: D000H  Ending address: D7BAH  Bias: 0000H
Saved image size: 2048 bytes (0800H, - 16 records)

++ Warning: program origin NOT at 100H ++

CP/M MACRO ASSEM 2.0
E5EE
017H USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 3453 bytes (0D7DH) to file P0:BDOS.BIN
Start address: D800H  Ending address: E5B2H  Bias: 0000H
Saved image size: 3584 bytes (0E00H, - 28 records)

++ Warning: program origin NOT at 100H ++

CP/M MACRO ASSEM 2.0
D7F2
008H USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 1906 bytes (0772H) to file P0:CCP22.BIN
Start address: D000H  Ending address: D7CCH  Bias: 0000H
Saved image size: 2048 bytes (0800H, - 16 records)

++ Warning: program origin NOT at 100H ++

CP/M MACRO ASSEM 2.0
E633
012H USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 3518 bytes (0DBEH) to file P0:BDOS22.BIN
Start address: D800H  Ending address: E5EDH  Bias: 0000H
Saved image size: 3584 bytes (0E00H, - 28 records)

++ Warning: program origin NOT at 100H ++

CP/M MACRO ASSEM 2.0

D7F2
00BH USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 1887 bytes (075FH) to file P0:OS2CCP.BIN
Start address: D000H  Ending address: D7BAH  Bias: 0000H
Saved image size: 2048 bytes (0800H, - 16 records)

++ Warning: program origin NOT at 100H ++

CP/M MACRO ASSEM 2.0
E5EE
017H USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 3453 bytes (0D7DH) to file P0:OS3BDOS.BIN
Start address: D800H  Ending address: E5B2H  Bias: 0000H
Saved image size: 3584 bytes (0E00H, - 28 records)

++ Warning: program origin NOT at 100H ++

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
os2ccp.bin
os3bdos.bin
..\cbios\cbios_wbw.bin
        1 file(s) copied.
os2ccp.bin
os3bdos.bin
..\cbios\cbios_una.bin
        1 file(s) copied.
loader.bin
cpm_wbw.bin
        1 file(s) copied.
loader.bin
cpm_una.bin
        1 file(s) copied.
CP/M MACRO ASSEM 2.0
D7EF
00EH USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 1888 bytes (0760H) to file P0:ZCPR.BIN
Start address: D000H  Ending address: D7EEH  Bias: 0000H
Saved image size: 2048 bytes (0800H, - 16 records)

++ Warning: program origin NOT at 100H ++

CP/M MACRO ASSEM 2.0
01B3
000H USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 179 bytes (00B3H) to file P0:BDLOC.COM
Start address: 0100H  Ending address: 01B2H  Bias: 0000H
Saved image size: 256 bytes (0100H, - 2 records)


No Fatal error(s)


Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    08FF    < 2047>

51771 Bytes Free
[0000   08FF        8]


No Fatal error(s)


Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    091A    < 2074>

51744 Bytes Free
[0000   091A        9]



ZMAC Relocating Macro Assembler v 1.7, 04/09/93
  Copyright 1988,1989 by A.E. Hawley


      P0:ZSDOS.Z80      assembled with   NO ERRORS

..To produce:

P0:ZSDOS.REL, P0:ZSDOS.PRN

Source Lines    3345          Unused Memory   7995H
Labels           429          Total Code Size 0DF6H
Macros  -Read   none
    -Expanded   none

               ===  SEGMENT SIZES  ===

ASEG    =empty   CSEG    =0DF6H   DSEG    =empty   BLANK   =empty

 Named COMMON segments

_BIOS_
LINK 1.31

/_BIOS_/ E600

ABSOLUTE     0000
CODE SIZE    0E00 (D800-E5FF)
DATA SIZE    0000
COMMON SIZE  0000
USE FACTOR     1C

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
..\zcpr-dj\zcpr.bin
zsdos.bin
..\cbios\cbios_wbw.bin
        1 file(s) copied.
..\zcpr-dj\zcpr.bin
zsdos.bin
..\cbios\cbios_una.bin
        1 file(s) copied.
loader.bin
zsys_wbw.bin
        1 file(s) copied.
loader.bin
zsys_una.bin
        1 file(s) copied.


*** CPM Loader ***

CP/M RMAC ASSEM 1.1
0A00
015H USE FACTOR
END OF ASSEMBLY


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 UTIL/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 136 Program Bytes.
 12 Symbols Detected.


        1 file(s) copied.

Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 BIOSLDR/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 1127 Program Bytes.
 142 Symbols Detected.


        1 file(s) moved.
        1 file(s) moved.
LINK 1.31

COUT     0FAB   ADDHLA   0F67   BCD2BIN  0FC9   BIN2BCD  0FDC
CIN      0F9F   CRLF     0FBC   CRLF2    0FB9   PHEX16   0F6C
PHEX8    0F77

ABSOLUTE     0000
CODE SIZE    0EEF (0100-0FEE)
DATA SIZE    0000
COMMON SIZE  0000
USE FACTOR     1E

        1 file(s) moved.
        1 file(s) copied.

Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 BIOSLDR/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 1203 Program Bytes.
 145 Symbols Detected.


        1 file(s) moved.
        1 file(s) moved.
LINK 1.31

CIN      0FEB   COUT     0FF7   ADDHLA   0FB3   BCD2BIN  1015
BIN2BCD  1028   CRLF     1008   CRLF2    1005   PHEX16   0FB8
PHEX8    0FC3

ABSOLUTE     0000
CODE SIZE    0F3B (0100-103A)
DATA SIZE    0000
COMMON SIZE  0000
USE FACTOR     1F

        1 file(s) moved.


*** Resident CPM3 BIOS ***

        1 file(s) copied.
        1 file(s) copied.
CP/M RMAC ASSEM 1.1
023E
00AH USE FACTOR
END OF ASSEMBLY

CP/M RMAC ASSEM 1.1
0000
002H USE FACTOR
END OF ASSEMBLY


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 BOOT/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 655 Program Bytes. 324 Data Bytes.
 125 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 CHARIO/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 128 Program Bytes.
 28 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 MOVE/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 84 Program Bytes.
 14 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 DRVTBL/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 32 Program Bytes.
 22 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 DISKIO/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 188 Program Bytes. 1835 Data Bytes.
 114 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 UTIL/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 136 Program Bytes.
 12 Symbols Detected.


LINK 1.31

@ADRV    07F7   @RDRV    07F8   @TRK     07F9   @SECT    07FB
@DMA     07FD   @DBNK    0800   @CNT     07FF   @CBNK    023D
@COVEC   FE24   @CIVEC   FE22   @AOVEC   FE28   @AIVEC   FE26
@LOVEC   FE2A   @MXTPA   FE62   @BNKBF   FE35   @CTBL    04EC
@DTBL    05A1   @CRDMA   FE3C   @CRDSK   FE3E   @VINFO   FE3F
@RESEL   FE41   @FX      FE43   @USRCD   FE44   @MLTIO   FE4A
@ERMDE   FE4B   @ERDSK   FE51   @MEDIA   FE54   @BFLGS   FE57
@DATE    FE58   @HOUR    FE5A   @MIN     FE5B   @SEC     FE5C
@CCPDR   FE13   @SRCH1   FE4C   @SRCH2   FE4D   @SRCH3   FE4E
@SRCH4   FE4F   @BOOTDU  04A3   @BOOTSL  04A4   @HBBIO   0599
ADDHLA   067D   BCD2BIN  06DF   BIN2BCD  06F2   DPH0     094F
@HBUSR   059C   DPH1     0976   DPH10    0AD5   DPH11    0AFC
DPH12    0B23   DPH13    0B4A   DPH14    0B71   DPH15    0B98
DPH2     099D   DPH3     09C4   DPH4     09EB   DPH5     0A12
DPH6     0A39   DPH7     0A60   DPH8     0A87   DPH9     0AAE
@SYSDR   067C   CIN      06B5   COUT     06C1   CRLF     06D2
CRLF2    06CF   PHEX16   0682   PHEX8    068D

ABSOLUTE     0000
CODE SIZE    0705 (0000-0704)
DATA SIZE    096B (0705-106F)
COMMON SIZE  0000
USE FACTOR     21



CP/M 3.0 System Generation
Copyright (C) 1982, Digital Research

Default entries are shown in (parens).
Default base is Hex, precede entry with # for decimal

Use GENCPM.DAT for defaults (Y) ?

Create a new GENCPM.DAT file (N) ?

Display Load Map at Cold Boot (Y) ?

Number of console columns (#80) ?
Number of lines in console page (#24) ?
Backspace echoes erased character (N) ?
Rubout echoes erased character (N) ?

Initial default drive (A:) ?

Top page of memory (FD) ?
Bank switched memory (N) ?

Double allocation vectors (N) ?

Accept new system definition (Y) ?

Setting up Allocation vector for drive A:
Setting up Checksum vector for drive A:
Setting up Allocation vector for drive B:
Setting up Checksum vector for drive B:
Setting up Allocation vector for drive C:
Setting up Checksum vector for drive C:
Setting up Allocation vector for drive D:
Setting up Checksum vector for drive D:
Setting up Allocation vector for drive E:
Setting up Checksum vector for drive E:
Setting up Allocation vector for drive F:
Setting up Checksum vector for drive F:
Setting up Allocation vector for drive G:
Setting up Checksum vector for drive G:
Setting up Allocation vector for drive H:
Setting up Checksum vector for drive H:
Setting up Allocation vector for drive I:
Setting up Checksum vector for drive I:
Setting up Allocation vector for drive J:
Setting up Checksum vector for drive J:
Setting up Allocation vector for drive K:
Setting up Checksum vector for drive K:
Setting up Allocation vector for drive L:
Setting up Checksum vector for drive L:
Setting up Allocation vector for drive M:
Setting up Checksum vector for drive M:
Setting up Allocation vector for drive N:
Setting up Checksum vector for drive N:
Setting up Allocation vector for drive O:
Setting up Checksum vector for drive O:
Setting up Allocation vector for drive P:
Setting up Checksum vector for drive P:

Setting up directory hash tables:
 Enable hashing for drive A: (N) ?
 Enable hashing for drive B: (N) ?
 Enable hashing for drive C: (N) ?
 Enable hashing for drive D: (N) ?
 Enable hashing for drive E: (N) ?
 Enable hashing for drive F: (N) ?
 Enable hashing for drive G: (N) ?
 Enable hashing for drive H: (N) ?
 Enable hashing for drive I: (N) ?
 Enable hashing for drive J: (N) ?
 Enable hashing for drive K: (N) ?
 Enable hashing for drive L: (N) ?
 Enable hashing for drive M: (N) ?
 Enable hashing for drive N: (N) ?
 Enable hashing for drive O: (N) ?
 Enable hashing for drive P: (N) ?

Setting up Blocking/Deblocking buffers:

The physical record size is 0200H:

     Available space in 256 byte pages:
     TPA = 00AEH

     *** Directory buffer required  ***
     *** and allocated for drive A: ***

     Available space in 256 byte pages:
     TPA = 00ABH

     *** Data buffer required and ***
     *** allocated for drive A:   ***

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive B: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive B: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive C: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive C: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive D: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive D: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive E: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive E: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive F: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive F: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive G: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive G: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive H: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive H: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive I: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive I: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive J: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive J: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive K: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive K: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive L: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive L: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive M: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive M: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive N: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive N: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive O: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive O: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Directory buffer for drive P: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H

               Overlay Data buffer for drive P: (Y) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00A9H


Accept new buffer definitions (Y) ?

 BIOS3    SPR  C900H  1100H
 BDOS3    SPR  AA00H  1F00H

*** CP/M 3.0 SYSTEM GENERATION DONE ***
        1 file(s) copied.


*** Banked CPM3 BIOS ***

        1 file(s) copied.
        1 file(s) copied.
CP/M RMAC ASSEM 1.1
0243
00AH USE FACTOR
END OF ASSEMBLY

CP/M RMAC ASSEM 1.1
0000
002H USE FACTOR
END OF ASSEMBLY


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 BOOT/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 723 Program Bytes. 347 Data Bytes.
 128 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 CHARIO/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 128 Program Bytes.
 28 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 MOVE/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 84 Program Bytes.
 14 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 DRVTBL/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 32 Program Bytes.
 22 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 DISKIO/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 188 Program Bytes. 1838 Data Bytes.
 114 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 UTIL/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 136 Program Bytes.
 12 Symbols Detected.


LINK 1.31

@ADRV    08F2   @RDRV    08F3   @TRK     08F4   @SECT    08F6
@DMA     08F8   @DBNK    08FB   @CNT     08FA   @CBNK    0242
@COVEC   FE24   @CIVEC   FE22   @AOVEC   FE28   @AIVEC   FE26
@LOVEC   FE2A   @MXTPA   FE62   @BNKBF   FE35   @CTBL    0535
@DTBL    05EA   @CRDMA   FE3C   @CRDSK   FE3E   @VINFO   FE3F
@RESEL   FE41   @FX      FE43   @USRCD   FE44   @MLTIO   FE4A
@ERMDE   FE4B   @ERDSK   FE51   @MEDIA   FE54   @BFLGS   FE57
@DATE    FE58   @HOUR    FE5A   @MIN     FE5B   @SEC     FE5C
@CCPDR   FE13   @SRCH1   FE4C   @SRCH2   FE4D   @SRCH3   FE4E
@SRCH4   FE4F   @BOOTDU  04EC   @BOOTSL  04ED   @HBBIO   05E2
ADDHLA   06C6   BCD2BIN  0728   BIN2BCD  073B   DPH0     0A61
@HBUSR   05E5   DPH1     0A88   DPH10    0BE7   DPH11    0C0E
DPH12    0C35   DPH13    0C5C   DPH14    0C83   DPH15    0CAA
DPH2     0AAF   DPH3     0AD6   DPH4     0AFD   DPH5     0B24
DPH6     0B4B   DPH7     0B72   DPH8     0B99   DPH9     0BC0
@SYSDR   06C5   CIN      06FE   COUT     070A   CRLF     071B
CRLF2    0718   PHEX16   06CB   PHEX8    06D6

ABSOLUTE     0000
CODE SIZE    074E (0000-074D)
DATA SIZE    0985 (0800-1184)
COMMON SIZE  0000
USE FACTOR     22



CP/M 3.0 System Generation
Copyright (C) 1982, Digital Research

Default entries are shown in (parens).
Default base is Hex, precede entry with # for decimal

Use GENCPM.DAT for defaults (Y) ?

Create a new GENCPM.DAT file (N) ?

Display Load Map at Cold Boot (Y) ?

Number of console columns (#80) ?
Number of lines in console page (#24) ?
Backspace echoes erased character (N) ?
Rubout echoes erased character (N) ?

Initial default drive (A:) ?

Top page of memory (FD) ?
Bank switched memory (Y) ?
Common memory base page (80) ?

Long error messages (Y) ?

Accept new system definition (Y) ?

Setting up Allocation vector for drive A:
Setting up Checksum vector for drive A:
Setting up Allocation vector for drive B:
Setting up Checksum vector for drive B:
Setting up Allocation vector for drive C:
Setting up Checksum vector for drive C:
Setting up Allocation vector for drive D:
Setting up Checksum vector for drive D:
Setting up Allocation vector for drive E:
Setting up Checksum vector for drive E:
Setting up Allocation vector for drive F:
Setting up Checksum vector for drive F:
Setting up Allocation vector for drive G:
Setting up Checksum vector for drive G:
Setting up Allocation vector for drive H:
Setting up Checksum vector for drive H:
Setting up Allocation vector for drive I:
Setting up Checksum vector for drive I:
Setting up Allocation vector for drive J:
Setting up Checksum vector for drive J:
Setting up Allocation vector for drive K:
Setting up Checksum vector for drive K:
Setting up Allocation vector for drive L:
Setting up Checksum vector for drive L:
Setting up Allocation vector for drive M:
Setting up Checksum vector for drive M:
Setting up Allocation vector for drive N:
Setting up Checksum vector for drive N:
Setting up Allocation vector for drive O:
Setting up Checksum vector for drive O:
Setting up Allocation vector for drive P:
Setting up Checksum vector for drive P:

*** Bank 1 and Common are not included ***
*** in the memory segment table.       ***

Number of memory segments (#4) ?

CP/M 3 Base,size,bank (18,68,00)

Enter memory segment table:
 Base,size,bank (01,43,00) ?

ERROR:  Memory conflict - segment trimmed.
 Base,size,bank (01,17,00) ?
 Base,size,bank (0E,72,02) ?
 Base,size,bank (01,7F,03) ?
 Base,size,bank (01,7F,04) ?

 CP/M 3 Sys    1800H 6800H  Bank 00
 Memseg No. 00 0100H 1700H  Bank 00
 Memseg No. 01 0E00H 7200H  Bank 02
 Memseg No. 02 0100H 7F00H  Bank 03
 Memseg No. 03 0100H 7F00H  Bank 04

Accept new memory segment table entries (Y) ?

Setting up directory hash tables:
 Enable hashing for drive A: (Y) ?
 Enable hashing for drive B: (Y) ?
 Enable hashing for drive C: (Y) ?
 Enable hashing for drive D: (Y) ?
 Enable hashing for drive E: (Y) ?
 Enable hashing for drive F: (Y) ?
 Enable hashing for drive G: (Y) ?
 Enable hashing for drive H: (Y) ?
 Enable hashing for drive I: (Y) ?
 Enable hashing for drive J: (Y) ?
 Enable hashing for drive K: (Y) ?
 Enable hashing for drive L: (Y) ?
 Enable hashing for drive M: (Y) ?
 Enable hashing for drive N: (Y) ?
 Enable hashing for drive O: (Y) ?
 Enable hashing for drive P: (Y) ?

Setting up Blocking/Deblocking buffers:

The physical record size is 0200H:

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0017H, Other banks = 0070H

               Number of directory buffers for drive A: (#8) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0006H, Other banks = 0070H

               Number of data buffers for drive A: (#16) ?
               Allocate buffers outside of Common (Y) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive B: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive B: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive C: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive C: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive D: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive D: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive E: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive E: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive F: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive F: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive G: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive G: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive H: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive H: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive I: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive I: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive J: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive J: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive K: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive K: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive L: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive L: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive M: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive M: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive N: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive N: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive O: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive O: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive P: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive P: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H


Accept new buffer definitions (Y) ?

 BNKBIOS3 SPR  F600H  0800H
 BNKBIOS3 SPR  4500H  3B00H
 RESBDOS3 SPR  F000H  0600H
 BNKBDOS3 SPR  1700H  2E00H

*** CP/M 3.0 SYSTEM GENERATION DONE ***
        1 file(s) copied.


*** Banked ZPM3 BIOS ***

        1 file(s) copied.
        1 file(s) copied.
CP/M RMAC ASSEM 1.1
0243
00AH USE FACTOR
END OF ASSEMBLY

CP/M RMAC ASSEM 1.1
0000
002H USE FACTOR
END OF ASSEMBLY


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 BOOT/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 719 Program Bytes. 347 Data Bytes.
 128 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 CHARIO/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 128 Program Bytes.
 28 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 MOVE/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 84 Program Bytes.
 14 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 DRVTBL/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 32 Program Bytes.
 22 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 DISKIO/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 188 Program Bytes. 1838 Data Bytes.
 114 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 UTIL/MF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected. 136 Program Bytes.
 12 Symbols Detected.


LINK 1.31

@ADRV    08F2   @RDRV    08F3   @TRK     08F4   @SECT    08F6
@DMA     08F8   @DBNK    08FB   @CNT     08FA   @CBNK    0242
@COVEC   FE24   @CIVEC   FE22   @AOVEC   FE28   @AIVEC   FE26
@LOVEC   FE2A   @MXTPA   FE62   @BNKBF   FE35   @CTBL    0531
@DTBL    05E6   @CRDMA   FE3C   @CRDSK   FE3E   @VINFO   FE3F
@RESEL   FE41   @FX      FE43   @USRCD   FE44   @MLTIO   FE4A
@ERMDE   FE4B   @ERDSK   FE51   @MEDIA   FE54   @BFLGS   FE57
@DATE    FE58   @HOUR    FE5A   @MIN     FE5B   @SEC     FE5C
@CCPDR   FE13   @SRCH1   FE4C   @SRCH2   FE4D   @SRCH3   FE4E
@SRCH4   FE4F   @BOOTDU  04E8   @BOOTSL  04E9   @HBBIO   05DE
ADDHLA   06C2   BCD2BIN  0724   BIN2BCD  0737   DPH0     0A61
@HBUSR   05E1   DPH1     0A88   DPH10    0BE7   DPH11    0C0E
DPH12    0C35   DPH13    0C5C   DPH14    0C83   DPH15    0CAA
DPH2     0AAF   DPH3     0AD6   DPH4     0AFD   DPH5     0B24
DPH6     0B4B   DPH7     0B72   DPH8     0B99   DPH9     0BC0
@SYSDR   06C1   CIN      06FA   COUT     0706   CRLF     0717
CRLF2    0714   PHEX16   06C7   PHEX8    06D2

ABSOLUTE     0000
CODE SIZE    074A (0000-0749)
DATA SIZE    0985 (0800-1184)
COMMON SIZE  0000
USE FACTOR     22

        1 file(s) copied.
        1 file(s) copied.
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
loader.bin
cpmldr.bin
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.


*** ZPM Loader ***

LINK 1.31

COUT     0FAB   ADDHLA   0F67   BCD2BIN  0FC9   BIN2BCD  0FDC
CIN      0F9F   CRLF     0FBC   CRLF2    0FB9   PHEX16   0F6C
PHEX8    0F77

ABSOLUTE     0000
CODE SIZE    0EEF (0100-0FEE)
DATA SIZE    0000
COMMON SIZE  0000
USE FACTOR     1B

        1 file(s) moved.
LINK 1.31

CIN      0FEB   COUT     0FF7   ADDHLA   0FB3   BCD2BIN  1015
BIN2BCD  1028   CRLF     1008   CRLF2    1005   PHEX16   0FB8
PHEX8    0FC3

ABSOLUTE     0000
CODE SIZE    0F3B (0100-103A)
DATA SIZE    0000
COMMON SIZE  0000
USE FACTOR     1C

        1 file(s) moved.


*** Banked ZPM3 ***

        1 file(s) copied.


CP/M 3.0 System Generation
Copyright (C) 1982, Digital Research

Default entries are shown in (parens).
Default base is Hex, precede entry with # for decimal

Use GENCPM.DAT for defaults (Y) ?

Create a new GENCPM.DAT file (N) ?

Display Load Map at Cold Boot (Y) ?

Number of console columns (#80) ?
Number of lines in console page (#24) ?
Backspace echoes erased character (N) ?
Rubout echoes erased character (N) ?

Initial default drive (A:) ?

Top page of memory (FD) ?
Bank switched memory (Y) ?
Common memory base page (80) ?

Long error messages (Y) ?

Accept new system definition (Y) ?

Setting up Allocation vector for drive A:
Setting up Checksum vector for drive A:
Setting up Allocation vector for drive B:
Setting up Checksum vector for drive B:
Setting up Allocation vector for drive C:
Setting up Checksum vector for drive C:
Setting up Allocation vector for drive D:
Setting up Checksum vector for drive D:
Setting up Allocation vector for drive E:
Setting up Checksum vector for drive E:
Setting up Allocation vector for drive F:
Setting up Checksum vector for drive F:
Setting up Allocation vector for drive G:
Setting up Checksum vector for drive G:
Setting up Allocation vector for drive H:
Setting up Checksum vector for drive H:
Setting up Allocation vector for drive I:
Setting up Checksum vector for drive I:
Setting up Allocation vector for drive J:
Setting up Checksum vector for drive J:
Setting up Allocation vector for drive K:
Setting up Checksum vector for drive K:
Setting up Allocation vector for drive L:
Setting up Checksum vector for drive L:
Setting up Allocation vector for drive M:
Setting up Checksum vector for drive M:
Setting up Allocation vector for drive N:
Setting up Checksum vector for drive N:
Setting up Allocation vector for drive O:
Setting up Checksum vector for drive O:
Setting up Allocation vector for drive P:
Setting up Checksum vector for drive P:

*** Bank 1 and Common are not included ***
*** in the memory segment table.       ***

Number of memory segments (#4) ?

CP/M 3 Base,size,bank (18,68,00)

Enter memory segment table:
 Base,size,bank (01,43,00) ?

ERROR:  Memory conflict - segment trimmed.
 Base,size,bank (01,17,00) ?
 Base,size,bank (0E,72,02) ?
 Base,size,bank (01,7F,03) ?
 Base,size,bank (01,7F,04) ?

 CP/M 3 Sys    1800H 6800H  Bank 00
 Memseg No. 00 0100H 1700H  Bank 00
 Memseg No. 01 0E00H 7200H  Bank 02
 Memseg No. 02 0100H 7F00H  Bank 03
 Memseg No. 03 0100H 7F00H  Bank 04

Accept new memory segment table entries (Y) ?

Setting up directory hash tables:
 Enable hashing for drive A: (Y) ?
 Enable hashing for drive B: (Y) ?
 Enable hashing for drive C: (Y) ?
 Enable hashing for drive D: (Y) ?
 Enable hashing for drive E: (Y) ?
 Enable hashing for drive F: (Y) ?
 Enable hashing for drive G: (Y) ?
 Enable hashing for drive H: (Y) ?
 Enable hashing for drive I: (Y) ?
 Enable hashing for drive J: (Y) ?
 Enable hashing for drive K: (Y) ?
 Enable hashing for drive L: (Y) ?
 Enable hashing for drive M: (Y) ?
 Enable hashing for drive N: (Y) ?
 Enable hashing for drive O: (Y) ?
 Enable hashing for drive P: (Y) ?

Setting up Blocking/Deblocking buffers:

The physical record size is 0200H:

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0017H, Other banks = 0070H

               Number of directory buffers for drive A: (#8) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0006H, Other banks = 0070H

               Number of data buffers for drive A: (#16) ?
               Allocate buffers outside of Common (Y) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive B: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive B: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive C: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive C: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive D: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive D: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive E: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive E: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive F: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive F: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive G: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive G: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive H: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive H: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive I: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive I: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive J: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive J: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive K: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive K: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive L: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive L: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive M: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive M: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive N: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive N: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive O: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive O: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of directory buffers for drive P: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H

               Number of data buffers for drive P: (#0) ?
               Share buffer(s) with which drive (A:) ?

     Available space in 256 byte pages:
     TPA = 00F0H, Bank 0 = 0005H, Other banks = 0050H


Accept new buffer definitions (Y) ?

 BNKBIOS3 SPR  F600H  0800H
 BNKBIOS3 SPR  4500H  3B00H
 RESBDOS3 SPR  F000H  0600H
 BNKBDOS3 SPR  1700H  2E00H

*** CP/M 3.0 SYSTEM GENERATION DONE ***

Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 clrhist/F
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 19 Absolute Bytes. 7 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 setz3/F
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 235 Absolute Bytes. 12 Symbols Detected.



Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 autotog/F
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 437 Absolute Bytes. 20 Symbols Detected.


TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
loader.bin
zpmldr.bin
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.

Building p-System BIOS Tester Loader for RomWBW...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building p-System BIOS for RomWBW...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
pSystem BIOS space remaining: 71 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building p-System Loader for RomWBW...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Generating p-System BIOS Tester filler...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Generating p-System Boot Track filler...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Creating p-System BIOS Tester boot image

..\Images\hd1k_prefix.dat
testldr.bin
bios.bin
biostest.dat
testfill.bin
        1 file(s) copied.

Generating p-System Boot Track...

loader.bin
bios.bin
boot.dat
fill.bin
        1 file(s) copied.

Generating p-System Disk Image...

..\Images\hd1k_prefix.dat
trk0.bin
psys.vol
trk0.bin
blank.vol
        1 file(s) copied.
        1 file(s) copied.

Building syscopy...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building assign...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building format...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building talk...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building mode...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building rtc...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building timer...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building rtchb...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
rtchb
tasm: pass 2 complete.
tasm: Number of errors = 0

Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 SYSGEN/F
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 1164 Absolute Bytes. 80 Symbols Detected.


CP/M MACRO ASSEM 2.0
0577
009H USE FACTOR
END OF ASSEMBLY

MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 1115 bytes (045BH) to file P0:SURVEY.COM
Start address: 0100H  Ending address: 055AH  Bias: 0000H
Saved image size: 1152 bytes (0480H, - 9 records)

CP/M MACRO ASSEM 2.0
1B80
018H USE FACTOR
END OF ASSEMBLY


SLR180 Copyright (C) 1985-86 by SLR Systems Rel. 1.32 #NL0029

 xmhb/HF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 996 Absolute Bytes. 111 Symbols Detected.


MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 6422 bytes (1916H) to file P0:XM.COM
Start address: 0100H  Ending address: 1B07H  Bias: 0000H
Saved image size: 6784 bytes (1A80H, - 53 records)


SLR180 Copyright (C) 1985-86 by SLR Systems Rel. 1.32 #NL0029

 xmhb_old/HF
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 871 Absolute Bytes. 129 Symbols Detected.


MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 6297 bytes (1899H) to file P0:XMOLD.COM
Start address: 0100H  Ending address: 1B07H  Bias: 0000H
Saved image size: 6784 bytes (1A80H, - 53 records)

        1 file(s) copied.
        1 file(s) copied.
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
tune.com
tunemsx.com
tunezx.com
        3 file(s) copied.
Tunes\Attack.pt3
Tunes\Backup.pt3
Tunes\BadMice.pt3
Tunes\Demo.mym
Tunes\Demo1.mym
Tunes\Demo3.mym
Tunes\Demo3mix.mym
Tunes\Demo4.mym
Tunes\HowRU.pt3
Tunes\Iteratn.pt3
Tunes\LookBack.pt3
Tunes\Louboutn.pt3
Tunes\Namida.pt3
Tunes\Recoll.pt3
Tunes\Sanxion.pt3
Tunes\Synch.pt3
Tunes\ToStar.pt3
Tunes\Victory.pt3
Tunes\Wicked.pt3
Tunes\YeOlde.pt3
Tunes\Yeovil.pt3
       21 file(s) copied.
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
loader.bin
dbgmon.bin
        1 file(s) copied.
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
i2cscan
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
rtcds7
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
i2clcd
tasm: pass 2 complete.
tasm: Number of errors = 0
i2clcd.com
i2cscan.com
        2 file(s) copied.
rtcds7.com
        1 file(s) copied.
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
Comparing files rz.com and RZ.COM.ORIG
FC: no differences encountered

Comparing files sz.com and SZ.COM.ORIG
FC: no differences encountered

        1 file(s) copied.
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
'Pass 1 complete'
'Pass 2 complete'
'Assembly complete'

No Fatal error(s)


Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    056F    < 1135>

52683 Bytes Free
[0000   056F        5]

        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.

Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 ZMO-RW01/H
End of file Pass 1
 0 Error(s) Detected.
 937 Absolute Bytes. 91 Symbols Detected.


MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 927 bytes (039FH) to file P0:ZMP.COM
Over a 16000 byte binary file
Start address: 0100H  Ending address: 3F80H  Bias: 0000H
Saved image size: 16000 bytes (3E80H, - 125 records)

        1 file(s) copied.
zmconfig.ovr
zminit.ovr
zmterm.ovr
zmxfer.ovr
        4 file(s) copied.
zmp.hlp
        1 file(s) copied.
        1 file(s) copied.

Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 zmd/fm
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 14893 Absolute Bytes. 687 Symbols Detected.



Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    5253    <20819>

30660 Bytes Free
[0000   5253       82]


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 zmap/fm
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 4447 Absolute Bytes. 201 Symbols Detected.



Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    18B0    < 6064>

46412 Bytes Free
[0000   18B0       24]


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 znews/fm
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 4312 Absolute Bytes. 201 Symbols Detected.



Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    1B9C    < 6812>

45440 Bytes Free
[0000   1B9C       27]


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 znewp/fm
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 4706 Absolute Bytes. 223 Symbols Detected.



Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    1C8A    < 7050>

45274 Bytes Free
[0000   1C8A       28]


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 zfors/fm
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 4156 Absolute Bytes. 196 Symbols Detected.



Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    221F    < 8479>

43629 Bytes Free
[0000   221F       34]


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 zforp/fm
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 4910 Absolute Bytes. 219 Symbols Detected.



Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    1D58    < 7256>

45073 Bytes Free
[0000   1D58       29]


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 zmdel/fm
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 4256 Absolute Bytes. 200 Symbols Detected.



Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    0100    1AE0    < 6624>

45716 Bytes Free
[0000   1AE0       26]


Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 zmdhb/fh
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 1109 Absolute Bytes. 116 Symbols Detected.


MLOAD v25  Copyright (c) 1983, 1984, 1985, 1988
by NightOwl Software, Inc.
Loaded 1017 bytes (03F9H) to file P0:ZMD.COM
Over a 20864 byte binary file
Start address: 0100H  Ending address: 5280H  Bias: 0000H
Saved image size: 20864 bytes (5180H, - 163 records)

        1 file(s) copied.
Building Dev...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
Tunes\bgm.vgm
Tunes\ending.vgm
Tunes\inchina.vgm
Tunes\shirakaw.vgm
Tunes\startdem.vgm
Tunes\wonder01.vgm
        6 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
assign.com
format.com
mode.com
rtc.com
rtchb.com
survey.com
syscopy.com
sysgen.com
talk.com
timer.com
       10 file(s) copied.
Z80/Z180/Z280 Macro-Assembler V4.4

Errors: 0
Finished.

LINK 1.31

ABSOLUTE     0000
CODE SIZE    1700 (0200-18FF)
DATA SIZE    0000
COMMON SIZE  0000
USE FACTOR     00

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
TASTYBASIC ROM padding: 66 bytes.
TASTYBASIC space remaining: 68 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
TASTYBASIC ROM padding: 107 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
        1 file(s) copied.
        1 file(s) copied.

Preparing compressed font files...
        1 file(s) copied.
        1 file(s) copied.
Making ROM Disk rom256_wbw
Making ROM Disk rom256_una
Making ROM Disk rom512_wbw
Making ROM Disk rom512_una
Making ROM Disk rom1024_wbw
Making ROM Disk rom1024_una

Building Floppy Disk Images...

Generating cpm22 1.44MB Floppy Disk...
cpmcp -f wbw_fd144 fd144_cpm22.img d_cpm22/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_cpm22.img d_cpm22/ReadMe.txt 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_fd144 fd144_cpm22.img ../CPM22/cpm_wbw.sys 0:cpm.sys
cpmcp -f wbw_fd144 fd144_cpm22.img Common/All/*.* 0:
cpmcp -f wbw_fd144 fd144_cpm22.img Common/CPM22/*.* 0:
Moving image fd144_cpm22.img into output directory...
Generating zsdos 1.44MB Floppy Disk...
cpmcp -f wbw_fd144 fd144_zsdos.img d_zsdos/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_zsdos/ReadMe.txt 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/ASM.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/LIB.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/LINK.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/LOAD.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/MAC.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/RMAC.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/STAT.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/SUBMIT.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img d_cpm22/u0/XSUB.COM 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_fd144 fd144_zsdos.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
cpmcp -f wbw_fd144 fd144_zsdos.img Common/All/*.* 0:
cpmcp -f wbw_fd144 fd144_zsdos.img Common/CPM22/*.* 0:
cpmcp -f wbw_fd144 fd144_zsdos.img Common/Z/u14/*.* 0:
cpmcp -f wbw_fd144 fd144_zsdos.img Common/Z/u15/*.* 0:
Moving image fd144_zsdos.img into output directory...
Generating nzcom 1.44MB Floppy Disk...
cpmcp -f wbw_fd144 fd144_nzcom.img d_nzcom/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_nzcom.img d_nzcom/ReadMe.txt 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_fd144 fd144_nzcom.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
cpmcp -f wbw_fd144 fd144_nzcom.img Common/All/*.* 0:
cpmcp -f wbw_fd144 fd144_nzcom.img Common/CPM22/*.* 0:
cpmcp -f wbw_fd144 fd144_nzcom.img Common/Z/u14/*.* 0:
cpmcp -f wbw_fd144 fd144_nzcom.img Common/Z/u15/*.* 0:
cpmcp -f wbw_fd144 fd144_nzcom.img Common/Z3/u10/*.* 0:
cpmcp -f wbw_fd144 fd144_nzcom.img Common/Z3/u14/*.* 0:
cpmcp -f wbw_fd144 fd144_nzcom.img Common/Z3/u15/*.* 0:
Moving image fd144_nzcom.img into output directory...
Generating cpm3 1.44MB Floppy Disk...
cpmcp -f wbw_fd144 fd144_cpm3.img d_cpm3/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpmldr.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpmldr.sys 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/ccp.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/gencpm.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/genres.dat 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/genbnk.dat 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bios3.spr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bnkbios3.spr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bdos3.spr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bnkbdos3.spr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/resbdos3.spr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3res.sys 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3bnk.sys 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/gencpm.dat 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3.sys 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/readme.1st 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3fix.pat 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_fd144 fd144_cpm3.img Common/All/*.* 0:
cpmcp -f wbw_fd144 fd144_cpm3.img Common/CPM3/*.* 0:
Moving image fd144_cpm3.img into output directory...
Generating zpm3 1.44MB Floppy Disk...
cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u10/*.* 10:
cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u14/*.* 14:
cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u15/*.* 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zpmldr.com 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zpmldr.sys 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../CPM3/cpmldr.com 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../CPM3/cpmldr.sys 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/autotog.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/clrhist.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/setz3.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/cpm3.sys 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zccp.com 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zinstal.zpm 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/startzpm.com 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/makedos.com 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/gencpm.dat 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/bnkbios3.spr 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/bnkbdos3.spr 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/resbdos3.spr 0:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/assign.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/cpuspd.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/fat.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/fdu.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/fdu.doc 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/mode.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/rtc.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/survey.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/syscopy.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/sysgen.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/talk.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/tbasic.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/timer.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/tune.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/xm.com 15:
cpmcp -f wbw_fd144 fd144_zpm3.img Common/All/*.* 15:
cpmcp -f wbw_fd144 fd144_zpm3.img Common/CPM3/*.* 15:
cpmcp -f wbw_fd144 fd144_zpm3.img Common/Z/u14/*.* 14:
cpmcp -f wbw_fd144 fd144_zpm3.img Common/Z/u15/*.* 15:
cpmcp -f wbw_fd144 fd144_zpm3.img Common/Z3/u10/*.* 10:
cpmcp -f wbw_fd144 fd144_zpm3.img Common/Z3/u14/*.* 14:
cpmcp -f wbw_fd144 fd144_zpm3.img Common/Z3/u15/*.* 15:
Moving image fd144_zpm3.img into output directory...
Generating ws4 1.44MB Floppy Disk...
cpmcp -f wbw_fd144 fd144_ws4.img d_ws4/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_ws4.img d_ws4/u1/*.* 1:
Moving image fd144_ws4.img into output directory...
Generating qpm 1.44MB Floppy Disk...
cpmcp -f wbw_fd144 fd144_qpm.img d_qpm/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_qpm.img d_qpm/ReadMe.txt 0:
cpmcp -f wbw_fd144 fd144_qpm.img d_cpm22/u0/*.* 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_fd144 fd144_qpm.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_fd144 fd144_qpm.img ../CPM22/cpm_wbw.sys 0:cpm.sys
cpmcp -f wbw_fd144 fd144_qpm.img Common/All/*.* 0:
cpmcp -f wbw_fd144 fd144_qpm.img Common/CPM22/*.* 0:
Moving image fd144_qpm.img into output directory...

Building Hard Disk Images (512 directory entry format)...

Generating cpm22 Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_cpm22.img d_cpm22/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_cpm22.img d_cpm22/ReadMe.txt 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd512 hd512_cpm22.img Test/*.* 2:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd512 hd512_cpm22.img cpnet12/*.* 4:
cpmcp -f wbw_hd512 hd512_cpm22.img ../CPM22/cpm_wbw.sys 0:cpm.sys
cpmcp -f wbw_hd512 hd512_cpm22.img Common/All/*.* 0:
cpmcp -f wbw_hd512 hd512_cpm22.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd512 hd512_cpm22.img Common/SIMH/*.* 13:
Moving image hd512_cpm22.img into output directory...
Generating zsdos Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_zsdos.img d_zsdos/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_zsdos/ReadMe.txt 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/ASM.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/LIB.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/LINK.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/LOAD.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/MAC.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/RMAC.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/STAT.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/SUBMIT.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img d_cpm22/u0/XSUB.COM 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd512 hd512_zsdos.img Test/*.* 2:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd512 hd512_zsdos.img cpnet12/*.* 4:
cpmcp -f wbw_hd512 hd512_zsdos.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
cpmcp -f wbw_hd512 hd512_zsdos.img Common/All/*.* 0:
cpmcp -f wbw_hd512 hd512_zsdos.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd512 hd512_zsdos.img Common/Z/u14/*.* 0:
cpmcp -f wbw_hd512 hd512_zsdos.img Common/Z/u15/*.* 0:
cpmcp -f wbw_hd512 hd512_zsdos.img Common/SIMH/*.* 13:
Moving image hd512_zsdos.img into output directory...
Generating nzcom Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_nzcom.img d_nzcom/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_nzcom/ReadMe.txt 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/ASM.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/LIB.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/LINK.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/LOAD.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/MAC.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/RMAC.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/STAT.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/SUBMIT.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_cpm22/u0/XSUB.COM 0:
cpmcp -f wbw_hd512 hd512_nzcom.img d_zsdos/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd512 hd512_nzcom.img Test/*.* 2:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd512 hd512_nzcom.img cpnet12/*.* 4:
cpmcp -f wbw_hd512 hd512_nzcom.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
cpmcp -f wbw_hd512 hd512_nzcom.img Common/All/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img Common/Z/u14/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img Common/Z/u15/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img Common/Z3/u10/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img Common/Z3/u14/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img Common/Z3/u15/*.* 0:
cpmcp -f wbw_hd512 hd512_nzcom.img Common/SIMH/*.* 13:
Moving image hd512_nzcom.img into output directory...
Generating cpm3 Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_cpm3.img d_cpm3/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpmldr.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpmldr.sys 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/ccp.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/gencpm.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/genres.dat 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/genbnk.dat 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bios3.spr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bnkbios3.spr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bdos3.spr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bnkbdos3.spr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/resbdos3.spr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3res.sys 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3bnk.sys 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/gencpm.dat 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3.sys 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/readme.1st 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3fix.pat 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd512 hd512_cpm3.img Test/*.* 2:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd512 hd512_cpm3.img cpnet3/*.* 4:
cpmcp -f wbw_hd512 hd512_cpm3.img Common/All/*.* 0:
cpmcp -f wbw_hd512 hd512_cpm3.img Common/CPM3/*.* 0:
cpmcp -f wbw_hd512 hd512_cpm3.img Common/SIMH/*.* 13:
Moving image hd512_cpm3.img into output directory...
Generating zpm3 Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u10/*.* 10:
cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u14/*.* 14:
cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u15/*.* 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zpmldr.com 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zpmldr.sys 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../CPM3/cpmldr.com 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../CPM3/cpmldr.sys 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/autotog.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/clrhist.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/setz3.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/cpm3.sys 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zccp.com 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zinstal.zpm 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/startzpm.com 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/makedos.com 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/gencpm.dat 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/bnkbios3.spr 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/bnkbdos3.spr 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/resbdos3.spr 0:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/assign.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/cpuspd.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/fat.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/fdu.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/fdu.doc 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/format.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/mode.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/rtc.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/survey.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/syscopy.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/sysgen.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/talk.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/tbasic.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/timer.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/tune.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/xm.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zmp.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zmp.hlp 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zmp.doc 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zmxfer.ovr 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zmterm.ovr 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zminit.ovr 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zmconfig.ovr 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/zmd.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/vgmplay.com 15:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd512 hd512_zpm3.img Test/*.* 2:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd512 hd512_zpm3.img cpnet3/*.* 4:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/All/*.* 15:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/CPM3/*.* 15:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/Z/u14/*.* 14:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/Z/u15/*.* 15:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/Z3/u10/*.* 10:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/Z3/u14/*.* 14:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/Z3/u15/*.* 15:
cpmcp -f wbw_hd512 hd512_zpm3.img Common/SIMH/*.* 13:
Moving image hd512_zpm3.img into output directory...
Generating ws4 Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_ws4.img d_ws4/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_ws4.img d_ws4/u1/*.* 1:
Moving image hd512_ws4.img into output directory...
Generating dos65 Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_dos65.img d_dos65/u0/*.* 0:
Moving image hd512_dos65.img into output directory...
Generating qpm Hard Disk (512 directory entry format)...
cpmcp -f wbw_hd512 hd512_qpm.img d_qpm/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_qpm.img d_qpm/ReadMe.txt 0:
cpmcp -f wbw_hd512 hd512_qpm.img d_cpm22/u0/*.* 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd512 hd512_qpm.img Test/*.* 2:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd512 hd512_qpm.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd512 hd512_qpm.img cpnet12/*.* 4:
cpmcp -f wbw_hd512 hd512_qpm.img ../CPM22/cpm_wbw.sys 0:cpm.sys
cpmcp -f wbw_hd512 hd512_qpm.img Common/All/*.* 0:
cpmcp -f wbw_hd512 hd512_qpm.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd512 hd512_qpm.img Common/SIMH/*.* 13:
Moving image hd512_qpm.img into output directory...

Building Combo Disk (512 directory entry format) Image...
..\..\Binary\hd512_cpm22.img
..\..\Binary\hd512_zsdos.img
..\..\Binary\hd512_nzcom.img
..\..\Binary\hd512_cpm3.img
..\..\Binary\hd512_zpm3.img
..\..\Binary\hd512_ws4.img
        1 file(s) copied.

Building Hard Disk Images (1024 directory entry format)...

Generating cpm22 Hard Disk (1024 directory entry format)...
cpmcp -f wbw_hd1k hd1k_cpm22.img d_cpm22/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img d_cpm22/ReadMe.txt 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd1k hd1k_cpm22.img Test/*.* 2:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd1k hd1k_cpm22.img cpnet12/*.* 4:
cpmcp -f wbw_hd1k hd1k_cpm22.img ../CPM22/cpm_wbw.sys 0:cpm.sys
cpmcp -f wbw_hd1k hd1k_cpm22.img Common/All/*.* 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd1k hd1k_cpm22.img Common/SIMH/*.* 13:
Moving image hd1k_cpm22.img into output directory...
Generating zsdos Hard Disk (1024 directory entry format)...
cpmcp -f wbw_hd1k hd1k_zsdos.img d_zsdos/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_zsdos/ReadMe.txt 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/ASM.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/LIB.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/LINK.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/LOAD.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/MAC.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/RMAC.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/STAT.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/SUBMIT.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img d_cpm22/u0/XSUB.COM 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd1k hd1k_zsdos.img Test/*.* 2:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd1k hd1k_zsdos.img cpnet12/*.* 4:
cpmcp -f wbw_hd1k hd1k_zsdos.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
cpmcp -f wbw_hd1k hd1k_zsdos.img Common/All/*.* 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img Common/Z/u14/*.* 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img Common/Z/u15/*.* 0:
cpmcp -f wbw_hd1k hd1k_zsdos.img Common/SIMH/*.* 13:
Moving image hd1k_zsdos.img into output directory...
Generating nzcom Hard Disk (1024 directory entry format)...
cpmcp -f wbw_hd1k hd1k_nzcom.img d_nzcom/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_nzcom/ReadMe.txt 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/ASM.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/LIB.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/LINK.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/LOAD.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/MAC.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/RMAC.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/STAT.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/SUBMIT.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_cpm22/u0/XSUB.COM 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img d_zsdos/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd1k hd1k_nzcom.img Test/*.* 2:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd1k hd1k_nzcom.img cpnet12/*.* 4:
cpmcp -f wbw_hd1k hd1k_nzcom.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/All/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/Z/u14/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/Z/u15/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/Z3/u10/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/Z3/u14/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/Z3/u15/*.* 0:
cpmcp -f wbw_hd1k hd1k_nzcom.img Common/SIMH/*.* 13:
Moving image hd1k_nzcom.img into output directory...
Generating cpm3 Hard Disk (1024 directory entry format)...
cpmcp -f wbw_hd1k hd1k_cpm3.img d_cpm3/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpmldr.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpmldr.sys 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/ccp.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/gencpm.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/genres.dat 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/genbnk.dat 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bios3.spr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bnkbios3.spr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bdos3.spr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bnkbdos3.spr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/resbdos3.spr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3res.sys 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3bnk.sys 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/gencpm.dat 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3.sys 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/readme.1st 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3fix.pat 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd1k hd1k_cpm3.img Test/*.* 2:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd1k hd1k_cpm3.img cpnet3/*.* 4:
cpmcp -f wbw_hd1k hd1k_cpm3.img Common/All/*.* 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img Common/CPM3/*.* 0:
cpmcp -f wbw_hd1k hd1k_cpm3.img Common/SIMH/*.* 13:
Moving image hd1k_cpm3.img into output directory...
Generating zpm3 Hard Disk (1024 directory entry format)...
cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u10/*.* 10:
cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u14/*.* 14:
cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u15/*.* 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zpmldr.com 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zpmldr.sys 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../CPM3/cpmldr.com 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../CPM3/cpmldr.sys 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/autotog.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/clrhist.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/setz3.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/cpm3.sys 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zccp.com 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zinstal.zpm 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/startzpm.com 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/makedos.com 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/gencpm.dat 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/bnkbios3.spr 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/bnkbdos3.spr 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/resbdos3.spr 0:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/assign.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/cpuspd.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/fat.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/fdu.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/fdu.doc 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/format.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/mode.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/rtc.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/survey.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/syscopy.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/sysgen.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/talk.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/tbasic.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/timer.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/tune.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/xm.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zmp.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zmp.hlp 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zmp.doc 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zmxfer.ovr 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zmterm.ovr 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zminit.ovr 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zmconfig.ovr 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/zmd.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/vgmplay.com 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd1k hd1k_zpm3.img Test/*.* 2:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd1k hd1k_zpm3.img cpnet3/*.* 4:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/All/*.* 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/CPM3/*.* 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/Z/u14/*.* 14:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/Z/u15/*.* 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/Z3/u10/*.* 10:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/Z3/u14/*.* 14:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/Z3/u15/*.* 15:
cpmcp -f wbw_hd1k hd1k_zpm3.img Common/SIMH/*.* 13:
Moving image hd1k_zpm3.img into output directory...
Generating ws4 Hard Disk (1024 directory entry format)...
cpmcp -f wbw_hd1k hd1k_ws4.img d_ws4/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_ws4.img d_ws4/u1/*.* 1:
Moving image hd1k_ws4.img into output directory...
Generating qpm Hard Disk (1024 directory entry format)...
cpmcp -f wbw_hd1k hd1k_qpm.img d_qpm/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_qpm.img d_qpm/ReadMe.txt 0:
cpmcp -f wbw_hd1k hd1k_qpm.img d_cpm22/u0/*.* 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/assign.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/cpuspd.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/fat.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/fdu.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/fdu.doc 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/format.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/mode.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/rtc.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/survey.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/syscopy.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/sysgen.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/talk.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/tbasic.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/timer.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/tune.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/xm.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zmp.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zmp.hlp 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zmp.doc 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zmxfer.ovr 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zmterm.ovr 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zminit.ovr 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zmconfig.ovr 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/zmd.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/vgmplay.com 0:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/Test/*.com 2:
cpmcp -f wbw_hd1k hd1k_qpm.img Test/*.* 2:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/Tunes/*.pt? 3:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/Tunes/*.mym 3:
cpmcp -f wbw_hd1k hd1k_qpm.img ../../Binary/Apps/Tunes/*.vgm 3:
cpmcp -f wbw_hd1k hd1k_qpm.img cpnet12/*.* 4:
cpmcp -f wbw_hd1k hd1k_qpm.img ../CPM22/cpm_wbw.sys 0:cpm.sys
cpmcp -f wbw_hd1k hd1k_qpm.img Common/All/*.* 0:
cpmcp -f wbw_hd1k hd1k_qpm.img Common/CPM22/*.* 0:
cpmcp -f wbw_hd1k hd1k_qpm.img Common/SIMH/*.* 13:
Moving image hd1k_qpm.img into output directory...
        1 file(s) copied.

Building Combo Disk (1024 directory entry format) Image...
hd1k_prefix.dat
..\..\Binary\hd1k_cpm22.img
..\..\Binary\hd1k_zsdos.img
..\..\Binary\hd1k_nzcom.img
..\..\Binary\hd1k_cpm3.img
..\..\Binary\hd1k_zpm3.img
..\..\Binary\hd1k_ws4.img
        1 file(s) copied.
Platform [SBC|MBC|ZETA|ZETA2|RCZ80|EZZ80|UNA|N8|MK4|RCZ180|SCZ180|DYNO|RPH|RCZ280]: MK4
Configurations available:
 > dbg
 > std
 > wbw
Configuration: std
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
tasm: pass 2 complete.
tasm: Number of errors = 0
Building 512K ROM MK4_std for Z180 CPU...
..\Fonts\font8x11c.asm
..\Fonts\font8x11u.asm
..\Fonts\font8x16c.asm
..\Fonts\font8x16u.asm
..\Fonts\font8x8c.asm
..\Fonts\font8x8u.asm
..\Fonts\fontcgac.asm
..\Fonts\fontcgau.asm
        8 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
HBIOS INT STACK space: 46 bytes.
HBIOS TEMP STACK space: 20 bytes.
DSRTC occupies 697 bytes.
ASCI occupies 839 bytes.
UART occupies 802 bytes.
VGA occupies 1051 bytes.
CVDU occupies 904 bytes.
FONTS 8X16 occupy 1466 bytes.
KBD occupies 1064 bytes.
PRP occupies 1397 bytes.
MD occupies 449 bytes.
FD occupies 2397 bytes.
IDE occupies 1606 bytes.
SD occupies 2254 bytes.
TERM occupies 2091 bytes.
RTCDEF=32
UNLZSA2 for Z80.
HBIOS space remaining: 7689 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
HBIOS INT STACK space: 46 bytes.
HBIOS TEMP STACK space: 20 bytes.
DSRTC occupies 697 bytes.
ASCI occupies 839 bytes.
UART occupies 802 bytes.
VGA occupies 1051 bytes.
CVDU occupies 904 bytes.
FONTS 8X16 occupy 1466 bytes.
KBD occupies 1064 bytes.
PRP occupies 1397 bytes.
MD occupies 449 bytes.
FD occupies 2397 bytes.
IDE occupies 1606 bytes.
SD occupies 2254 bytes.
TERM occupies 2091 bytes.
RTCDEF=32
UNLZSA2 for Z80.
HBIOS space remaining: 7744 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
HBIOS INT STACK space: 46 bytes.
HBIOS TEMP STACK space: 20 bytes.
DSRTC occupies 697 bytes.
ASCI occupies 839 bytes.
UART occupies 802 bytes.
VGA occupies 1051 bytes.
CVDU occupies 904 bytes.
FONTS 8X16 occupy 1466 bytes.
KBD occupies 1064 bytes.
PRP occupies 1397 bytes.
MD occupies 449 bytes.
FD occupies 2397 bytes.
IDE occupies 1606 bytes.
SD occupies 2254 bytes.
TERM occupies 2091 bytes.
RTCDEF=32
UNLZSA2 for Z80.
HBIOS space remaining: 7770 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building dbgmon...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
DBGMON space remaining: 793 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building romldr...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
LOADER space remaining: 703 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building eastaegg...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
EASTEREGG space remaining: 78 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building nascom...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
BASIC space remaining: 247 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building game...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
GAME space remaining: 189 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building usrrom...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
User ROM space remaining: 5763 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building updater...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
ROM Updater space remaining: 257 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building imgpad2...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
Padspace space created: 32768 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
romldr.bin
dbgmon.bin
..\zsdos\zsys_wbw.bin
..\cpm22\cpm_wbw.bin
        1 file(s) copied.
..\Forth\camel80.bin
nascom.bin
..\tastybasic\src\tastybasic.bin
game.bin
eastaegg.bin
netboot.mod
updater.bin
usrrom.bin
        1 file(s) copied.
        1 file(s) copied.
romldr.bin
dbgmon.bin
..\zsdos\zsys_wbw.bin
        1 file(s) copied.
hbios_rom.bin
osimg.bin
osimg1.bin
osimg2.bin
..\RomDsk\rom512_wbw.dat
        1 file(s) copied.
hbios_rom.bin
osimg.bin
osimg1.bin
osimg2.bin
        1 file(s) copied.
hbios_app.bin
osimg_small.bin
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.
        1 file(s) copied.

C:\Users\Wayne\Projects\RomWBW>