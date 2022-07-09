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

Configuration files are found in the Source\HBIOS\Config 
directory.  If you look in the this directory, you will see a 
series of files named <plt>_<cfg>.asm where <plt> refers to the 
CPU board in your system and <cfg> is used to name the specific 
configuration so you can maintain multiple configurations.

You will notice that there is generally one configuration file for 
each CPU platform with a name of "std".  For example, you there is 
a file called MK4_std.asm.  This is the standard ("std") 
configuration for a Mark IV CPU board.

The platform names are predefined.  Refer to the following table 
to determine the <plt> component of the configuration filename:

	SBC V1/V2	SBC_std.rom
	SBC SimH	SBC_simh.rom
	MBC		MBC_std.asm
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

In summary, the ROM Disk embedded in the ROM firmware you build, 
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

    Platform [SBC|MBC|ZETA|ZETA2|RCZ80|EZZ80|UNA|N8|MK4|RCZ180|SCZ180|DYNO|RCZ280]:

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

In the past, the size of the ROM could be specified as the third
parameter of the command.  This parameter is now deprecated and
the size of the ROM is specified in your configuration file
using the ROMSIZE variable.

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

C:\RomWBW\Source>BuildShared
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
UTIL occupies 497 bytes.
INIT code slack space: 2282 bytes.
HEAP space: 4106 bytes.
CBIOS total space used: 6144 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building CBIOS for UNA...

TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
CBIOS extension info occupies 6 bytes.
UTIL occupies 497 bytes.
INIT code slack space: 2073 bytes.
HEAP space: 3920 bytes.
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

Data    0100    08F5    < 2037>

51781 Bytes Free
[0000   08F5        8]



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
 0 Error(s) Detected. 639 Program Bytes. 324 Data Bytes.
 123 Symbols Detected.



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

@ADRV    07E7   @RDRV    07E8   @TRK     07E9   @SECT    07EB
@DMA     07ED   @DBNK    07F0   @CNT     07EF   @CBNK    023D
@COVEC   FE24   @CIVEC   FE22   @AOVEC   FE28   @AIVEC   FE26
@LOVEC   FE2A   @MXTPA   FE62   @BNKBF   FE35   @CTBL    04DC
@DTBL    0591   @CRDMA   FE3C   @CRDSK   FE3E   @VINFO   FE3F
@RESEL   FE41   @FX      FE43   @USRCD   FE44   @MLTIO   FE4A
@ERMDE   FE4B   @ERDSK   FE51   @MEDIA   FE54   @BFLGS   FE57
@DATE    FE58   @HOUR    FE5A   @MIN     FE5B   @SEC     FE5C
@CCPDR   FE13   @SRCH1   FE4C   @SRCH2   FE4D   @SRCH3   FE4E
@SRCH4   FE4F   @BOOTDU  0493   @BOOTSL  0494   @HBBIO   0589
ADDHLA   066D   BCD2BIN  06CF   BIN2BCD  06E2   DPH0     093F
@HBUSR   058C   DPH1     0966   DPH10    0AC5   DPH11    0AEC
DPH12    0B13   DPH13    0B3A   DPH14    0B61   DPH15    0B88
DPH2     098D   DPH3     09B4   DPH4     09DB   DPH5     0A02
DPH6     0A29   DPH7     0A50   DPH8     0A77   DPH9     0A9E
@SYSDR   066C   CIN      06A5   COUT     06B1   CRLF     06C2
CRLF2    06BF   PHEX16   0672   PHEX8    067D

ABSOLUTE     0000
CODE SIZE    06F5 (0000-06F4)
DATA SIZE    096B (06F5-105F)
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
 0 Error(s) Detected. 707 Program Bytes. 347 Data Bytes.
 126 Symbols Detected.



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
@LOVEC   FE2A   @MXTPA   FE62   @BNKBF   FE35   @CTBL    0525
@DTBL    05DA   @CRDMA   FE3C   @CRDSK   FE3E   @VINFO   FE3F
@RESEL   FE41   @FX      FE43   @USRCD   FE44   @MLTIO   FE4A
@ERMDE   FE4B   @ERDSK   FE51   @MEDIA   FE54   @BFLGS   FE57
@DATE    FE58   @HOUR    FE5A   @MIN     FE5B   @SEC     FE5C
@CCPDR   FE13   @SRCH1   FE4C   @SRCH2   FE4D   @SRCH3   FE4E
@SRCH4   FE4F   @BOOTDU  04DC   @BOOTSL  04DD   @HBBIO   05D2
ADDHLA   06B6   BCD2BIN  0718   BIN2BCD  072B   DPH0     0A61
@HBUSR   05D5   DPH1     0A88   DPH10    0BE7   DPH11    0C0E
DPH12    0C35   DPH13    0C5C   DPH14    0C83   DPH15    0CAA
DPH2     0AAF   DPH3     0AD6   DPH4     0AFD   DPH5     0B24
DPH6     0B4B   DPH7     0B72   DPH8     0B99   DPH9     0BC0
@SYSDR   06B5   CIN      06EE   COUT     06FA   CRLF     070B
CRLF2    0708   PHEX16   06BB   PHEX8    06C6

ABSOLUTE     0000
CODE SIZE    073E (0000-073D)
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
 0 Error(s) Detected. 703 Program Bytes. 347 Data Bytes.
 126 Symbols Detected.



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
@LOVEC   FE2A   @MXTPA   FE62   @BNKBF   FE35   @CTBL    0521
@DTBL    05D6   @CRDMA   FE3C   @CRDSK   FE3E   @VINFO   FE3F
@RESEL   FE41   @FX      FE43   @USRCD   FE44   @MLTIO   FE4A
@ERMDE   FE4B   @ERDSK   FE51   @MEDIA   FE54   @BFLGS   FE57
@DATE    FE58   @HOUR    FE5A   @MIN     FE5B   @SEC     FE5C
@CCPDR   FE13   @SRCH1   FE4C   @SRCH2   FE4D   @SRCH3   FE4E
@SRCH4   FE4F   @BOOTDU  04D8   @BOOTSL  04D9   @HBBIO   05CE
ADDHLA   06B2   BCD2BIN  0714   BIN2BCD  0727   DPH0     0A61
@HBUSR   05D1   DPH1     0A88   DPH10    0BE7   DPH11    0C0E
DPH12    0C35   DPH13    0C5C   DPH14    0C83   DPH15    0CAA
DPH2     0AAF   DPH3     0AD6   DPH4     0AFD   DPH5     0B24
DPH6     0B4B   DPH7     0B72   DPH8     0B99   DPH9     0BC0
@SYSDR   06B1   CIN      06EA   COUT     06F6   CRLF     0707
CRLF2    0704   PHEX16   06B7   PHEX8    06C2

ABSOLUTE     0000
CODE SIZE    073A (0000-0739)
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
 1132 Absolute Bytes. 80 Symbols Detected.


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


SLR180 Copyright (C) 1985-86 by SLR Systems Rel. 1.31 #AB1234

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


SLR180 Copyright (C) 1985-86 by SLR Systems Rel. 1.31 #AB1234

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
SYSTEM TIMER: NONE
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


Preparing compressed font files...
        1 file(s) copied.
        1 file(s) copied.
Making ROM Disk rom256_wbw
Making ROM Disk rom256_una
Making ROM Disk rom512_wbw
Making ROM Disk rom512_una
Making ROM Disk rom1024_wbw
Making ROM Disk rom1024_una

C:\RomWBW\Source>

Example BuildROM Run
-----------------------

C:\RomWBW\Source>BuildROM
Platform [SBC|MBC|ZETA|ZETA2|RCZ80|EZZ80|UNA|N8|MK4|RCZ180|SCZ180|DYNO|RCZ280]: MK4
Configurations available:
 > cust
 > std
Configuration: cust
Building 512K ROM MK4_cust for Z180 CPU...
..\Fonts\font8x11c.asm
..\Fonts\font8x11u.asm
..\Fonts\font8x16c.asm
..\Fonts\font8x16u.asm
..\Fonts\font8x8c.asm
..\Fonts\font8x8u.asm
        6 file(s) copied.
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
HBIOS INT STACK space: 48 bytes.
HBIOS TEMP STACK space: 20 bytes.
DSRTC occupies 697 bytes.
ASCI occupies 839 bytes.
UART occupies 807 bytes.
VGA occupies 1046 bytes.
CVDU occupies 874 bytes.
FONTS 8X16 occupy 1466 bytes.
KBD occupies 1043 bytes.
PRP occupies 1397 bytes.
MD occupies 449 bytes.
FD occupies 2397 bytes.
IDE occupies 1591 bytes.
SD occupies 2259 bytes.
TERM occupies 2078 bytes.
RTCDEF=32
UNLZSA2 for Z80.
HBIOS space remaining: 8370 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
HBIOS INT STACK space: 48 bytes.
HBIOS TEMP STACK space: 20 bytes.
DSRTC occupies 697 bytes.
ASCI occupies 839 bytes.
UART occupies 807 bytes.
VGA occupies 1046 bytes.
CVDU occupies 874 bytes.
FONTS 8X16 occupy 1466 bytes.
KBD occupies 1043 bytes.
PRP occupies 1397 bytes.
MD occupies 449 bytes.
FD occupies 2397 bytes.
IDE occupies 1591 bytes.
SD occupies 2259 bytes.
TERM occupies 2078 bytes.
RTCDEF=32
UNLZSA2 for Z80.
HBIOS space remaining: 8414 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0
TASM Z180 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
HBIOS INT STACK space: 48 bytes.
HBIOS TEMP STACK space: 20 bytes.
DSRTC occupies 697 bytes.
ASCI occupies 839 bytes.
UART occupies 807 bytes.
VGA occupies 1046 bytes.
CVDU occupies 874 bytes.
FONTS 8X16 occupy 1466 bytes.
KBD occupies 1043 bytes.
PRP occupies 1397 bytes.
MD occupies 449 bytes.
FD occupies 2397 bytes.
IDE occupies 1591 bytes.
SD occupies 2259 bytes.
TERM occupies 2078 bytes.
RTCDEF=32
UNLZSA2 for Z80.
HBIOS space remaining: 8451 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building dbgmon...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
DBGMON space remaining: 1032 bytes.
tasm: pass 2 complete.
tasm: Number of errors = 0

Building romldr...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
LOADER space remaining: 932 bytes.
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

Building tastybasic...
TASM Z80 Assembler.       Version 3.2 September, 2001.
 Copyright (C) 2001 Squak Valley Software
tasm: pass 1 complete.
SYSTEM TIMER: Z180
TASTYBASIC space remaining: 56 bytes.
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
User ROM space remaining: 6019 bytes.
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
tastybasic.bin
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
C:\RomWBW\Source>