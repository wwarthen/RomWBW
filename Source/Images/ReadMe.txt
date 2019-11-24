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
images may be copied directly to floppy or hard disk media or used 
for SIMH emulator disk images.
 
System Requirements
-------------------

The scripts run on Microsoft Windows XP or greater (32 and 64 bit 
variants of Windows are fine).  You will need to have Microsoft 
PowerShell installed. All variants of Windows XP and later support 
PowerShell. It is included in all versions after Windows XP.  If you 
are using Windows XP, you will need to download it from Microsoft and 
install it (free download).

The cpmtools toolset is used to generate the actual disk images.  
This toolset is included in the distribution.

Preparing the Source Directory Contents
---------------------------------------

The script expects your files to be found inside a specific directory 
structure.  Note that you will see there are some CP/M files in the 
Source directory tree in the distribution.  These are simply test 
files I used and have no specific meaing.  You will probably want to 
replace them with your own files as desired.

If you look at the Images directory, you will find 4 
sub-directories.  fd0 and fd1 will contain the files to be placed in 
the two floppy images gneerated. hd0 and hd1 will contain the files 
to be used to generate the two hard disk images.  There is nothing 
magic about the fact that there are two of each kind of image 
generated.  It just seemed like a good number to the author.  A quick 
review of the scripts and you will see it is very easy to modify the 
number of images generated if you want.

For floppy disks, the structure is:

  fd0 --+--> u0
        +--> u1
	|
	+--> u15

Above, fd0 refers to the first floppy disk image and u0...u15 refer 
to the user areas on the disk.  You place whatever files you want on 
fd0, user 0 in the fd0\u0 directory.  You will notice that not all of 
the u0...u15 directories exist.  The script does not care and treats 
a non-existent directory as a directory with no files.  The fd1 
directory is exactly the same as fd0 -- it is simply the second 
floppy image.

At present, the scripts assume that the floppy media is 1.44MB.  You 
will need to modify the scripts if you want to create different media.

For hard disks, the structure has one more level:

  hd0 --+--> s0 --+--> u0
        |         +--> u1
	|         |
	|         +--> u15
	|
        +--> s1 --+--> u0
        |         +--> u1
	|         |
	|         +--> u15
	|
        +--> s2 --+--> u0
        |         +--> u1
	|         |
	|         +--> u15
	|
        +--> s3 --+--> u0
                  +--> u1
	          |
	          +--> u15

The above uses the same concept as the floppy disk source structure, 
but includes an additional directory layer to represent the first 4 
slices of the hard disk.  For most RomWBW builds, s0-s3 would show up 
as the first 4 hard disk drive letters, frequently E: to H:.

No files should be placed in the first two layers of the tree (hd0 or 
s0-s3).  All files go into the lowest level of the tree (u0-u15).  As 
above, empty or non-existent directories are not a problem for the 
script.  Just fill in or create the appropriate directories.  The 
only constraint is the the script will only look for two hard disks 
(hd0-hd1), 4 slices (s0-s4), and 16 user areas (u0-u15).  The number 
of hard disks and number of slices could be changed by modifying the 
generation scripts.

Building the Images
-------------------

The image creation process simply traverses the directory structures 
described above and builds a raw image each floppy disk or hard 
disk.  Note that cpmtools is used to generate the images and is 
included in the distribution under the Tools directory.

The scripts are intended to be run from a command prompt.  Open a 
command prompt and navigate to the Images directory.  To build the 
floppy disk images (fd0 and fd1), use the command "BuildFD". To build 
the hard disk images (hd0, hd1), use the command "BuildHD".  You can 
use the command "BuildAll" to build both the floppy and hard disk 
images in one run.

After completion of the script, the resultant image files are placed 
in the Binary directory with names such as fd0.img and hd0.img.

Below is sample output from building the hard disk images:

  | C:\Users\WWarthen\Projects\N8VEM\Build\RomWBW\Images>BuildHD
  | Creating work file...
  | Creating hard disk images...
  | Generating Hard Disk 0...
  | Adding files to slice 0...
  | cpmcp -f wbw_hd0 slice0.tmp Source/hd0/s0/u0/*.* 0:
  | cpmcp -f wbw_hd0 slice0.tmp Source/hd0/s0/u2/*.* 2:
  | Adding files to slice 1...
  | cpmcp -f wbw_hd0 slice1.tmp Source/hd0/s1/u0/*.* 0:
  | Adding files to slice 2...
  | Adding files to slice 3...
  | Combining slices into final disk image hd0...
  | slice0.tmp
  | slice1.tmp
  | slice2.tmp
  | slice3.tmp
  |         1 file(s) copied.
  | Generating Hard Disk 1...
  | Adding files to slice 0...
  | Adding files to slice 1...
  | Adding files to slice 2...
  | Adding files to slice 3...
  | Combining slices into final disk image hd1...
  | slice0.tmp
  | slice1.tmp
  | slice2.tmp
  | slice3.tmp
  |         1 file(s) copied.
  | 
  | C:\Users\WWarthen\Projects\N8VEM\Build\RomWBW\Images>

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
the distribution. This tool will write your floppy image (fd0.img or 
fd1.img) to a floppy disk using a raw block transfer.  The tool is 
GUI based and it's operation is self explanatory.

To install a hard disk image on a CF card or SD card, you must have 
the appropriate media card slot on your computer. If you do, you can 
use the tool called Win32 Disk Imager. This tool is also included in 
the Tools directory of the distribution.  This tool will write your 
hard disk image (hd0.img or hd1.img) to the designated media card.  
This tool is also GUI based and self explanatory.

Use of the SIMH emulator is outside of the scope of this document.  
However, if you use SIMH, you will find that you can attach the hard 
disk images to the emulator with lines such as the following in your 
SIMH configuration file:

  | attach hdsk0 hd0.img
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

You would use a command like the following to make drive C bootable.

  | B>SYSCOPY C:=CPM.SYS
  
Notes
-----

I realize these instructions are very minimal.  I am happy to answer 
questions.  You will find the RetroBrew Computers Forum at 
https://www.retrobrewcomputers.org/forum/ to be a great source of 
information as well.