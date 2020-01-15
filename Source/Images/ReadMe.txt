***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory contains a toolset for RomWBW that builds floppy and 
hard disk media images that can be used on RomWBW by writing the 
image to a floppy or hard disk (including CF and SD cards).

In summary, CP/M files are placed inside of a pre-defined Windows 
directory structure.  A script is then run to create the floppy and 
hard disk images from the directory tree contents.  The resultant 
images may be copied directly to floppy or hard disk media or used as 
SIMH emulator disk images.
 
System Requirements
-------------------

The scripts run on Microsoft Windows XP or greater (32 and 64 bit 
variants of Windows are fine).  You will need to have Microsoft 
PowerShell installed. All variants of Windows XP and later support 
PowerShell. It is included in all versions after Windows XP.  If you 
are using Windows XP, you will need to download it from Microsoft and 
install it (free download).

The cpmtools toolset is used to generate the actual disk images.  
This toolset is included in the distribution, so you do not need to 
download or install it.

Preparing the Source Directory Contents
---------------------------------------

The script expects your files to be found inside a specific directory 
structure.  The structure is:

  d_xxx --+--> u0
          +--> u1
	  +--> u2
	  |    .
	  |    .
	  |    .
	  +--> u15

A given disk is reprsented by a directory named d_xxx where xxx can 
be anything you want.  Within the d_xxx directory, the CP/M user 
areas are represented by subdirectories names u0 thru u15. The files 
to be placed in the disk image are placed inside of the u0 thru u15 
directories depending on which user area you want the file(s) to 
appear.  You do not need to create all of the u## subdirectories, 
only the ones corresponding to the user areas you want to put files in.

To build the disk images, you run the Build.cmd batch file from a 
command prompt.  Build.cmd in turn invokes separate scripts to create 
the floppy and hard disk images.

As distributed, you will see that there are several d_ directories 
populated with files.  If you look at the Build.cmd 
script, you will find that the names of each of these directories is 
listed.  If you want to add a new d_ directory to be converted into a 
disk image, you will need to add the name of your new directory to 
this list.  Note that each d_ directory may be turned into a floppy 
image or a hard disk image or both.

At present, the scripts assume that the floppy media is 1.44MB.  You 
will need to modify the scripts if you want to create different media.

Building the Images
-------------------

The image creation process simply traverses the directory structures 
described above and builds a raw disk image for each floppy disk or 
hard disk.  Note that cpmtools is used to generate the images and is 
included in the distribution under the Tools directory.

The scripts are intended to be run from a command prompt.  Open a 
command prompt and navigate to the Images directory.  Use the command
"Build" to build both the floppy and hard disk images in one run.
You can build a single disk image by running either BuildFD.cmd or
BuildHD.cmd with a single parameter specifying the disk name.

After completion of the script, the resultant image files are placed 
in the Binary directory with names such as fd_xxx.img and hd_xxx.img.

Below is sample output from building the hard disk images:

  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images>BuildHD.cmd
  | Creating work file...
  | Creating hard disk images...
  | Generating Hard Disk cpm3...
  | cpmcp -f wbw_hd0 hd_cpm3.img d_cpm3/u0/*.* 0:
  | Generating Hard Disk cpm22...
  | cpmcp -f wbw_hd0 hd_cpm22.img d_cpm22/u0/*.* 0:
  | cpmcp -f wbw_hd0 hd_cpm22.img d_cpm22/u1/*.* 1:
  | cpmcp -f wbw_hd0 hd_cpm22.img d_cpm22/u3/*.* 3:
  | Generating Hard Disk nzcom...
  | cpmcp -f wbw_hd0 hd_nzcom.img d_nzcom/u0/*.* 0:
  | Generating Hard Disk ws4...
  | cpmcp -f wbw_hd0 hd_ws4.img d_ws4/u0/*.* 0:
  | Generating Hard Disk zpm3...
  | cpmcp -f wbw_hd0 hd_zpm3.img d_zpm3/u0/*.* 0:
  | cpmcp -f wbw_hd0 hd_zpm3.img d_zpm3/u10/*.* 10:
  | cpmcp -f wbw_hd0 hd_zpm3.img d_zpm3/u14/*.* 14:
  | cpmcp -f wbw_hd0 hd_zpm3.img d_zpm3/u15/*.* 15:
  | Generating Hard Disk zsdos...
  | cpmcp -f wbw_hd0 hd_zsdos.img d_zsdos/u0/*.* 0:
  | cpmcp -f wbw_hd0 hd_zsdos.img d_zsdos/u1/*.* 1:
  | cpmcp -f wbw_hd0 hd_zsdos.img d_zsdos/u3/*.* 3:
  | Moving images into output directory...
  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images\hd_cpm22.img
  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images\hd_cpm3.img
  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images\hd_nzcom.img
  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images\hd_ws4.img
  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images\hd_zpm3.img
  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images\hd_zsdos.img
  |         6 file(s) moved.
  | 
  | C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images>

Be aware that the script always builds the image file from scratch.  
It will not update the previous contents. Any contents of a 
pre-existing image file will be permanently destroyed.

Installing Images
-----------------

First of all, a MAJOR WARNING!!!!  The tools described below are 
quite capable of obliterating your running Windows system drive.  Use 
with extreme caution and make sure you have backups.

To install a floppy image on floppy media, you can use the tool 
called RaWriteWin.  This tool is included in the Tools directory of 
the distribution. This tool will write your floppy image (fd_xxx.img) 
to a floppy disk using a raw block transfer.  The tool is GUI based 
and it's operation is self explanatory.

To install a hard disk image on a CF card or SD card, you must have 
the appropriate media card slot on your computer. If you do, you can 
use the tool called Win32 Disk Imager. This tool is also included in 
the Tools directory of the distribution.  This tool will write your 
hard disk image (hd_xxx.img) to the designated media card.  This tool 
is also GUI based and self explanatory.

Use of the SIMH emulator is outside of the scope of this document.  
However, if you use SIMH, you will find that you can attach the hard 
disk images to the emulator with lines such as the following in your 
SIMH configuration file:

  | attach hdsk0 hd_cpm22.img
  | set hdsk0 format=HDSK
  | set hdsk0 geom=T:520/N:256/S:512
  | set hdsk0 wrtenb
  
Making Disk Images Bootable
---------------------------

The current generation of these scripts does not make the resultant 
media bootable.  This is primarily because there are multiple choices 
for what you can put on the boot tracks of the media and that is a 
choice best left to the user.

The simplest way to make a resultant image bootable is to do it from 
your running CP/M system.  Boot your system using the ROM selection, 
then use the SYSCOPY command to make the desired drive bootable.

You would use a command like the following to make drive C bootable:

  | B>SYSCOPY C:=CPM.SYS
  
Slices
------

A RomWBW CP/M filesystem is fixed at 8MB.  This is because it is the 
largest size filesystem supported by all common CP/M variants. Since 
all modern hard disks (including SD Cards and CF Cards) are much 
larger than 8MB, RomWBW supports the concept of "slices".  This 
simply means that you can concatenate multiple CP/M filesystems (up 
to 256 of them) on a single physical hard disk and RomWBW will allow 
you to assign drive letters to them and treat them as multiple 
independent CP/M drives.

The disk image creation scripts in this directory will only create a 
single CP/M file system (i.e., a single slice).  However, you can 
easily create a multi-slice disk image by merely concatenating 
multiple images together.  For example, if you wanted to create a 2 
slice disk image that has ZSDOS in the first slice and Wordstar in 
the second slice, you could use the following command from a Windows 
command prompt:

  | C:\RomWBW\Binary>copy /b hd_zsdos.img + hd_ws.img hd_multi.img

You can now write hd_multi.img onto your SD or CF Card and you will 
have ZSDOS in the first slice and Wordstar in the second slice.

The concept of slices applies ONLY to hard disks.  Floppy disks are 
not large enough to support multiple slices.

Disk Images
-----------

RomWBW comes with several disk images.  These disk images are
created from this directory using the process described above.
This is a brief description of the disk images:

cpm22 - DRI CP/M 2.2 (Floppy and Hard Disk)

Standard DRI CP/M 2.2 distribution files along with a few commonly
used utilities.

zsdos - ZCPR1 + ZSDOS 1.1 (Floppy and Hard Disk)

Contains ZCPR1 and ZSDOS 1.1.  This is roughly equivalent to the
ROM boot contents, but provides a full set of the applications
are related files that would not all fit on the ROM drive.

nzcom - NZCOM (Floppy and Hard Disk)

Standard NZCOM distribution.  Note that you will need to run the
NZCOM setup before this will run properly.  You will need
to refer to the NZCOM documentation.

cpm3 - DRI CP/M3 (Floppy and Hard Disk)

Standard DRI CP/M 3 adaptation for RomWBW that is ready to run.
It can be started by running CPMLDR.

zpm3 - ZPM3 (Floppy and Hard Disk)

Simeon Cran's ZCPR 3 compatible OS for CP/M 3 adapted for RomWBW and 
ready to run.  It can be started by running CPMLDR (which seems 
wrong, but ZPMLDR is somewhat broken).

ws4 - WorkStar 4 (Floppy and Hard Disk)

Micropro Wordstar 4 full distribution.

bp - BPBIOS (Hard Disk only)

Adaptation of BPBIOS for RomWBW.  This is not complete and NOT
useable in it's current state.
  
Notes
-----

I realize these instructions are very minimal.  I am happy to answer 
questions.  You will find the RetroBrew Computers Forum at 
https://www.retrobrewcomputers.org/forum/ to be a great source of 
information as well.