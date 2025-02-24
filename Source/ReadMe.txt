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
of Microsoft Windows are fine.  No additional programs need to be 
installed to run the build.

You may find that you get messages such as this during the Windows
build process:

Security warning
Run only scripts that you trust. While scripts from the internet can be 
useful, this script can potentially harm your computer. If you trust 
this script, use the Unblock-File cmdlet to allow the script to run 
without this warning message. Do you want to run 
C:\Temp\RomWBW-v3.5.0-dev.67-Package\Source\Images\BuildDisk.ps1?
[D] Do not run  [R] Run once  [S] Suspend  [?] Help (default is "D"):

These prompts occur if Windows has marked the files as "blocked"
because they were downloaded from the Internet.  To unblock all of
the files in the entire RomWBW distribution tree, start PowerShell
and navigate to the root of the distribution.  Enter the following
command:

	dir -recurse | unblock-file

This will unblock all files within the distribution and preclude the
security warning messages.  Obviously, you should make sure you have
downloaded the RomWBW distribution from a valid/trustworthy source
before removing the file block protection.

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
file that is included in the build process.

RomWBW uses cascading configuration files as indicated below:

cfg_MASTER.asm				- MASTER: CONFIGURATION FILE DEFINES ALL POSSIBLE ROMWBW SETTINGS
|
+-> cfg_<platform>.asm			- PLATFORM: DEFAULT SETTINGS FOR SPECIFIC PLATFORM
    |
    +-> Config/<plt>_std.asm		- BUILD: SETTINGS FOR EACH OFFICIAL DIST BUILD
        |
        +-> Config/<plt>_<cust>.asm	- USER: CUSTOM USER BUILD SETTINGS

The top (master configuration) file defines all possible RomWBW
configuration settings. Each file below the master configuration file
inherits the cumulative settings of the files above it and may
override these settings as desired.

Other than the top master file, each file must "#INCLUDE" its parent 
file.  The top two files should not be modified.  To customize your 
build settings you should modify the default build settings 
(config/<platform>_std.asm) or preferably create an optional custom 
user settings file that includes the default build settings file (see 
example Config/SBC_user.asm).

By creating a custom user settings file, you are less likely to be
impacted by future changes because you will only be inheriting most
of your settings which will be updated by authors as RomWBW evolves.

RomWBW uses the concept of a "platform" and "configuration" to
define the settings for a build.  Platform refers to one of the core
systems supported.  Configuration refers to the settings that
customize the build.  The configuration is modifies the platform
defaults as desired.

The platform names are predefined.  Refer to the following table 
to determine the <plt> component of the configuration filename:

	SBC		Z80 SBC (v1 or v2) w/ ECB interface
	ZETA		Standalone Z80 SBC w/ SBC compatibility
	ZETA2		Second version of ZETA with enhanced memory bank switching
	N8		MSX-ish Z180 SBC w/ onboard video and sound
	MK4		Mark IV Z180 based SBC w/ ECB interface
	UNA		Any Z80/Z180 computer with UNA BIOS
	RCZ80		RCBUS based system with 512K banked RAM/ROM card
	RCZ180		RCBUS based system with Z180 CPU
	EZZ80		Easy Z80, Z80 SBC w/ RCBUS and CTC
	SCZ180		Steve Cousins Z180 based system
	DYNO		Steve Garcia's Dyno Micro-ATX Motherboard
	RCZ280		Z280 CPU on RCBUS or ZZ80MB
	MBC		Andrew Lynch's Multi Board Computer
	RPH		Andrew Lynch's RHYOPHYRE Graphics Computer
	Z80RETRO	Peter Wilson's Z80-Retro Computer
	S100		S100 Computers Z180-based System
	DUO		Andrew Lynch's Duodyne Computer
	HEATH		Les Bird's Heath Z80 Board
	EPITX		Alan Cox' Mini-ITX System
	MON		Jacques Pelletier's Monsputer
	GMZ180		Doug Jacksons' Genesis Z180 System
	NABU		NABU w/ Les Bird's RomWBW Option Board
	FZ80		S100 Computers FPGA Z80

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
platform.  This is accomplished via the "#INCLUDE" directive near
the top of the file.  For the "MK4_std.asm" configuration file,
this line reads:

#INCLUDE "cfg_MK4.asm"

When the configuration file (MK4_std.asm) is processed, it will first
read in all the default platform settings from "cfg_MK4.asm".  All of
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
normal build run called Sample_Build.log is included in the Source directory.
The sample build is from a typical build run under Windows.

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
review the output for any obvious errors.  Normally, all errors 
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