***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory ("Binary") is part of the RomWBW System Software
distribution archive.  It contains the completed binary outputs of
the build process.  As described below, these files are used to
assemble a working RetroBrew Computers system.

The files in this directory are created by the build process that is
documented in the ReadMe.txt file in the Source directory.  When
released the directory is populated with the default output files.
However, the output of custom builds will be placed in this directory
as well.

If you only see a few files in this directory, then you downloaded
just the source from GitHub.  To retrieve the full release download
package, go to https://github.com/wwarthen/RomWBW.  On this page,
look for the text "XX releases" where XX is a number. Click on this
text to go to the releases page.  On this page, you will see the
latest releases listed.  For each release, you will see a package
file called something like "RomWBW-2.9.0-Package.zip".  Click on the
package file for the release you want to download.

ROM Firmware Images (<plt>_<cfg>.rom)
-------------------------------------

The files with a ".rom" extension are binary images ready to program
into an appropriate PROM.  These files are named with the format
<plt>_<cfg>.rom. <plt> refers to the primary platform such as Zeta,
N8, Mark IV, etc.  <cfg> refers to the specific configuration.  In
general, there will be a standard configuration ("std") for each
platform.  So, for example, the file called MK4_std.rom is a ROM
image for the Mark IV with the standard configuration. If a custom
configuration called "custom" is created and built, a new file called
MK4_custom.rom will be added to this directory.

Documentation of the pre-built ROM Images is contained in
"RomWBW User Guide.pdf" in the Doc directory.

ROM Firmware Update Images (<plt>_<cfg>.upd)
-------------------------------------

The files with a ".upd" extension are binary images identical to the
.rom files, but they only have the first 128K bytes.  The first 128K
is the system image without the ROM disk contents.  These files can be
used to update the system image without modifying the ROM disk
contents.  Refer to the RomWBW User Guide for more information.

ROM Executable Images (<plt>_<cfg>.com)
---------------------------------------

When a ROM image (".rom") is created, an executable version of the
ROM is also created.  These files have the same naming convention as
the ROM Image files, but have the extension ".com".  These files can
be copied to a working system and run like a normal CP/M application.

When run on the target system, they install in RAM just like they had
been loaded from  ROM.  This allows a new ROM build to be tested
without reprogramming the actual ROM.

WARNING: In a few cases the .com file is too big to load.  If you get
a message like "Full" or "BAD LOAD" when trying to load one of the
.com files, it is too big.  In these cases, you will not be able to
test the ROM prior to programming it.

VDU ROM Image (vdu.rom)
-----------------------

The VDU video board requires a dedicated onboard ROM containing the
font data.  The "vdu.rom" file contains the binary data to program
onto that chip.

Disk Images (fd_*.img, hd_*.img)
--------------------------------

RomWBW includes a mechanism for generating floppy disk and hard disk
binary images that are ready to copy directly to a floppy, hard disk,
CF Card, or SD Card which will then be ready for use in any
RomWBW-based system.

Essentially, these files contain prepared floppy and hard disk images
with a large set of programs and related files.  By copying the
contents of these files to appropriate media as described below, you
can quickly create ready-to-use media.  Win32DiskImager or
RawWriteWin can be used to copy images directly to media.  These
programs are included in the RomWBW Tools directory.

The fd_*.img files are floppy disk images.  They are sized for 1.44MB
floppy media and can be copied to actual floppy disks using
RawWriteWin (as long as you have access to a floppy drive on your
Windows computer).  The resulting floppy disks will be usable on any
RomWBW-based system with floppy drive(s).

Likewise, the hd512_*.img and hd1k_*.img files are hard disk images.
Each file is intended to be copied to the start of any type of hard
disk media (typically a CF Card or SD Card). The resulting media will
be usable on any RomWBW-based system that accepts the corresponding
media type.

NOTE: The hd512_*.img files are equivalent to the hd_*.img
files in previous distributions.  The hd1k_*.img files
contained a revised file system format that increases the
maximum number of CP/M directory entries from 512 to 1024.
Refer to the ReadMe.txt in the Source/Images directory
for details.

Documentation of the pre-built disk images is contained in the
"RomWBW User Guide" found in the Doc directory.  The contents of
the disk images is contained in the "RomWBW Disk Catalog", but it
is significantly out-of-date.

The contents of the floppy/hard disk images are created by
the BuildImages.cmd script in the Source directory.  Additional
information on how to generate custom disk images is found in the
Source\Images ReadMe.txt file.

Disk Images (hd512_combo.img, hd1k_combo.img, *_std_hd1k_combo.img)
-------------------------------------------------------------------

The hd512_combo.img and hd1k_combo.img file are the primary combo
disk image files suitable for most platforms.

The *_std_hd1k_combo.img files are platform specific combo files
typically used in romless platforms, they also contain RomWBW binary code
that is loaded at boot time into RAM

Disk Images (hd1k_prefix.dat, *_std_hd1k_prefix.dat)
----------------------------------------------------

The hd1k_prefix.dat file is part of the combo disk images and is
applied to hd1k image files as a prefix, it contains the standard
partion table.

The *_std_hd1k_prefix.dat files are platform specific prefixes
typically used in romless platforms, they also contain RomWBW binary code
that is loaded at boot time into RAM

Disk Images (psys.img)
----------------------

The psys.img file contains a full implementation of the UCSD p-System
for the Z80 running under RomWBW.  This image file must be placed on
disk media by itself (not appended or concatenated with hd*.img files.
Refer to the Source/pSys/ReadMe.txt file for more information on the
p-System implementation.

Propeller ROM Images (*.eeprom)
-------------------------------

The files with and extension of ".eeprom" contain the binary images
to be programmed into the Propeller-based boards.  The list below
indicates which file targets each of the Propeller board variants:

	ParPortProp	ParPortProp.eeprom
	PropIO V1	PropIO.eeprom
	PropIO V2	PropIO2.eeprom

Refer to the board documentation of the boards for more information
on how to program the EEPROMs on these boards.

SUB DIRECTORIES
===============

Apps Directory
--------------

The Apps subdirectory contains the executable application files that
are specific to RomWBW.  The source for these applications is found
in the Source\Apps directory of the distribution.

CPNET Directory
---------------

This directory contains the CP/NET client packages.  Please refer to
the RomWBW User Guide for instructions on installing these packages,
or see the Readme.txt file in this sub-directory

CPM22 CPM3 ZSDOS ZPM3 QPM Directories
-------------------------------------

These directories contains the system files for the RomWBW adaptations
for each operating system.  All of these files are already included on
the boot disk images.  However if you are creating a o/s boot disk
manually, you will need copy all of these files to the boot disk.

These files should also be copied to any boot disks on your
system when you upgrade your ROM firmware.  Some of these files
*must* match the version of the RomWBW firmware you are using for
proper operation of your system.
