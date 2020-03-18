***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory is the root directory for the source tree for RomWBW.

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
    - Add or remove programs or files contained on the ROM disk.
    
Thought not necessary, advanced users can easily modify any of
the software including the operating systems.

A cross-platform approach is used to build the RomWBW firmware. 
The software is built using a modern Windows, Linux, or Mac
computer, then the resulting firmware image is programmed into
the ROM of your RetroBrew Computer CPU board.

Build System Requirements
-------------------------

For Linux/Mac computers, refer to the ReadMe.unix file in the
top directory of the distribution.

For Microsoft Windows computers, All that is required to build the
firmware is the RomWBW distribution zip archive file.  The zip
archive package includes all of the required source code 
(including the operating systems) and the programs required to run 
the build.

The build process is run via some simple scripts that automate the 
process.  These scripts utilize both batch command files as well as 
Windows PowerShell.  All versions of Microsoft Windows starting with 
Vista include PowerShell and will run the build process with no 
addtional programs required.  Either 32 or 64 bit versions of 
Microsoft Windows are fine.

Process Overview
----------------

The basic steps to create a custom ROM are:

  1) Create/update configuration file

  2) Update/Add/Delete any files you want incorporated in the
     ROM Disk

  3) Run the build scripts and confirm there are no errors.

  4) Program the resultant ROM image and try it.

Note that steps 1 and 2 are performed to customize your ROM as 
desired.  If you want to simply build a standard configuration, it is 
*not* necessary to perform steps 1 or 2 before running a build.  In 
fact, I strongly recommend that you skip steps 1 and 2 initially and 
just perform perform steps 3 and 4 using the standard configuraion to 
make sure that you have no issues building and programming a ROM that 
works the same as a pre-built ROM.

Each of the 4 steps above is described in more detail below.

1. Create/Update Configuration File
-----------------------------------

The options for a build are primarily controled by a configuration 
file that is included in the build process.  In order to customize 
your settings, it is easiest to make a copy of an existing 
configuration file and make your changes there.

Configuration files are found in the Source\HBIOS\Config 
directory.  If you look in the this directory, you will see a 
series of files named <plt>_<cfg>.asm where <plt> refers to the 
CPU board in your system and <cfg> is used to name the specific 
configuration so you can maintain multiple configurations.

You will notice that there is generaly one configuration file for 
each CPU platform with a name of "std".  For example, you there is 
a file called MK4_std.asm.  This is the standard ("std") 
configuration for a Mark IV CPU board.

The platform names are predefined.  Refer to the following table 
to determine the <plt> component of the configuration filename:

	SBC V1/V2	SBC_std.rom
	SBC SimH	SBC_simh.rom
	Zeta V1		ZETA_std.rom
	Zeta V2		ZETA2_std.rom
	N8		N8_std.rom
	Mark IV		MK4_std.rom
	RC2014 w/ Z80	RCZ80_std.rom
	RC2014 w/ Z180	RCZ180_nat.rom	(native Z180 memory addressing)
	RC2014 w/ Z180	RCZ180_ext.rom	(external 512K RAM/ROM module)
	SCZ180		SC126, SC130, SC131
	Easy Z80	EZZ180_std.rom
	Dyno		DYNO_std.rom

You can use any name you choose for the <cfg> component of the 
configuration filename.  So, let's say you want to create a custom 
ROM for the Mark IV.  You would simply copy "MK4_std.asm" to 
something like "MK4_cust.asm".  Now, just edit the new file 
("MK4_cust.asm" in this example) as desired.

You will see that the file already has lines for all of the common 
options and there is a comment after each option indicating the 
possible values.

In our example, let's say you have added a Dual-IDE board to your 
Mark IV system and want to include floppy support. You will see a 
couple lines similar to these in the config file:

FDENABLE  .SET	FALSE		; TRUE FOR FLOPPY DEVICE SUPPORT
FDMODE    .SET	FDMODE_DIDE	; FDMODE_DIO, FDMODE_DIDE, FDMODE_DIO3

To enable floppy support, you would just change FDENABLE to TRUE:

FDENABLE  .SET	TRUE		; TRUE FOR FLOPPY DEVICE SUPPORT

Since FDMODE is already set to FDMODE_DIDE, it is correct as is.  
If instead, you had added a DiskIO V3 board and wanted to use it 
for floppy support, you would also change FDMODE to 
FDMODE_FDMODE_DIO3:

FDMODE    .SET	FDMODE_DIO3	; FDMODE_DIO, FDMODE_DIDE, FDMODE_DIO3

2. Update/Add/Delete ROM Disk Files
-----------------------------------

The files that are included on the ROM Disk of your ROM are copied 
from a set of directories during the build process.  This allows 
you to have complete flexibility over the files you want included 
in your ROM.

These directories are already populated in the distribution.  You do 
not need to do anything unless you want to change the files that are 
included in the ROM Disk.

In summary, the ROM Disk imbedded in the ROM firmware you build, 
will include the files from the ROM_512KB directory (or the 
ROM_1024KB directory if building a 1024KB firmware).  
Additionally, files will be added from the directory associated 
with the platform specified in the ROM Build.

There is a ReadMe.txt document in the \Source\RomDsk directory 
with a more detailed description of this process.

Note that the standard 512K ROM disk is absolutely full.  So, if
you want to add files to it, you will need to delete other files
to free up some space.

3. Run the Build Process
------------------------

This section describes the build process for Microsoft Windows
computers.  The build process for Linux/Mac computers is described
in the ReadMe.unix file in the top level directory of the
distribution.

The build involves running commands at the command prompt.  Open a 
command prompt window for the Source directory.  If you unzipped 
the distribution to "C:\", then your command prompt should look 
like this:

    C:\RomWBW\Source>

Now run the first of two commands, the BuildShared command:

    C:\RomWBW\Source> BuildShared

This command will run a series of commands that generate the 
software which is "shared" by all ROM builds.  It is normal to 
have some lines indicating a warning like the following.  This is 
normal and expected.

    ++ Warning: program origin NOT at 100H ++
    
A sample run of the BuildShared command is provided later in this 
document.

Now run the second command, the BuildROM command:

    C:\RomWBW\Source> BuildROM

This command will prompt you twice as it runs.  These prompts 
determine the platform and configuration to be built.  The first 
prompt is for the platform, as shown below:

    Platform [SBC|ZETA|ZETA2|RCZ80|EZZ80|UNA|N8|MK4|RCZ180|SCZ180|DYNO]:

Enter the option corresponding to the platform of the ROM firmware 
you are building.  If you enter something other than one of the 
possible options, the prompt will be repeated until you provide an 
acceptable response.

Next, you will be prompted for the specific configuration of the 
platform to be built.  The options presented will be based on the 
configuration files in the Config directory.  So, if you have made 
a copy of the MK4_std.asm config and called it MK4_cust.asm, you 
would see a prompt like this:

    Configurations available:
     > std
     > cust
    Configuration:

Enter one of the configuration options to build a ROM with the 
associated config file.

At this point, the build should run and you will see output 
related to the assembler runs and some utility invocations.  Just 
review the output for any obvioius errors.  Normally, all errors 
will cause the build to stop immediately and display an error 
message in red.

A sample run of the BuildROM command is provided later in this 
document.

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

Optionally, you can run one more command that will create the
RomWBW disk images that can be subsequently written to actual
disk media.

    C:\RomWBW\Source> BuildImages

After running this command, you will find the resultant
disk image file in the Binary directory with names in the
format fd_xxx.img for floppy media or hd_xxx.img for
hard disk media.  Refer to the DiskList.txt file in the
Binary directory for more information on using the disk
image files.

4. Deploy the ROM
-----------------

Upon completion of a successful build, you should find the 
resulting firmware in the Binary directory.  These output files 
will have names that match the config filename, but with different 
extensions.

Three output files will be created for a single BuildROM run:

     <plt>_<cfg>.rom - binary ROM image to burn to EEPROM
     <plt>_<cfg>.com - executable version of the system image
                       that can be copied via X-Modem to a
		       running system to test the build.

The actual ROM image is the file ending in .rom.  It should be 
exactly 512KB.  Simply burn the .rom image to your ROM and install 
it in your hardware.  The process for programming your ROM depends 
on your hardware, but the .rom file is in a pure binary format (it 
is not hex encoded).

Refer to the document ReadMe.txt in the Binary directory for more 
information on the other two file extensions created.

Specifying Build Options on Command Line
----------------------------------------

If you don't want to be prompted for the options to the "BuildROM" 
command, you can specify the options right on the command line.

For example:

    C:\RomWBW\Source> BuildROM MK4 cust

In this case, you will not be prompted.  This is useful if you wish 
to automate your build process.

There is a third parameter that you can specify to the BuildROM 
command via a command line.  If you want to build a 1024K (1MB) ROM, 
you can add "1024" to the end of the line, like this:

    C:\RomWBW\Source> BuildROM MK4 cust 1024

You must ensure that your system actually supports a 1024K ROM.

Special Build Commands
----------------------

You may notice there are a few additional Build*.cmd files in the 
Source directory.  They are not used or required for building ROM 
firmware.  Their purpose is described below:

BuildProp: Some RetroBrew Computer peripheral boards are based
           on the Parallax Propeller.  The Propeller requires
           custom onboard EEPROM firmware to operate.  This
           command file builds the firmware images for each
           of the Propeller-based boards.

BuildImages: RomWBW has the ability to create floppy disk and hard
             disk images for use on systems running the RomWBW
	     firmware.  This script allows you to place the files
	     you want on a CP/M floppy or hard disk in a directory
	     and will turn them into a writable disk image.  Refer
	     to the ReadMe.txt document in the Source\Images
	     directory for a detailed description of this process.
	     N.B., BuildShared must be run prior to BuildImages.

BuildBP: This command builds another OS variant called BPBIOS.  It
         is a work in progress and should not be used at this time
	 without contacting Wayne Warthen.

Example BuildShared Run
-----------------------

C:\RomWBW\Source> BuildShared

Building SysCopy...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building Assign...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building Format...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building Talk...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building OSLdr...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0

Z80ASM Copyright (C) 1983-86 by SLR Systems Rel. 1.32 #AB1234

 SYSGEN/F
End of file Pass 1
End of file Pass 2
 0 Error(s) Detected.
 1132 Absolute Bytes. 80 Symbols Detected.



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

Data    0100    08F7    < 2039>

51779 Bytes Free
[0000   08F7        8]



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


Building CBIOS for RomWBW...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
CBIOS extension info occupies 6 bytes.
UTIL occupies 485 bytes.
INIT code slack space: 2924 bytes.
HEAP space: 4450 bytes.
CBIOS total space used: 6144 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building CBIOS for UNA...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
CBIOS extension info occupies 6 bytes.
UTIL occupies 485 bytes.
INIT code slack space: 2909 bytes.
HEAP space: 4263 bytes.
CBIOS total space used: 6400 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Example BuildROM Run
-----------------------

C:\RomWBW\Source> BuildROM
Platform [SBC|ZETA|ZETA2|N8|MK4|UNA]: MK4
Configurations available:
 > std
 > cust
Configuration: cust

Building MK4_cust: 512KB ROM configuration cust for Z180...

tasm -t180 -g3  dbgmon.asm dbgmon.bin dbgmon.lst
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
DBGMON space remaining: 1533 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
tasm -t180 -g3  prefix.asm prefix.bin prefix.lst
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
tasm: pass 2 complete.
tasm: Number of errors = 0
tasm -t180 -g3  romldr.asm romldr.bin romldr.lst
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
LOADER space remaining: 1217 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
tasm -t180 -g3 -dROMBOOT hbios.asm hbios_rom.bin hbios_rom.lst
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
HBIOS PROXY STACK space: 38 bytes.
HBIOS INT space remaining: 82 bytes.
DSRTC occupies 423 bytes.
UART occupies 716 bytes.
ASCI occupies 580 bytes.
MD occupies 451 bytes.
IDE occupies 1276 bytes.
SD occupies 2191 bytes.
HBIOS space remaining: 21454 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
tasm -t180 -g3 -dAPPBOOT hbios.asm hbios_app.bin hbios_app.lst
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
HBIOS PROXY STACK space: 38 bytes.
HBIOS INT space remaining: 82 bytes.
DSRTC occupies 423 bytes.
UART occupies 716 bytes.
ASCI occupies 580 bytes.
MD occupies 451 bytes.
IDE occupies 1276 bytes.
SD occupies 2191 bytes.
HBIOS space remaining: 21434 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
tasm -t180 -g3 -dIMGBOOT hbios.asm hbios_img.bin hbios_img.lst
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
HBIOS PROXY STACK space: 38 bytes.
HBIOS INT space remaining: 82 bytes.
DSRTC occupies 423 bytes.
UART occupies 716 bytes.
ASCI occupies 580 bytes.
MD occupies 451 bytes.
IDE occupies 1276 bytes.
SD occupies 2191 bytes.
HBIOS space remaining: 21434 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
Building MK4_cust output files...
Building 512KB MK4_cust ROM disk data file...
