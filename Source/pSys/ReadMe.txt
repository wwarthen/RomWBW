This directory contains a port of p-System IV.0 for RomWBW.

It was derived from the p-System Adaptable Z80 System.  Unlike some 
other distributions, this implements a native p-System Z80 Extended 
BIOS, it does not use a CP/M BIOS layer.

Files:

loader.asm     p-System primary loader for RomWBW
bios.asm       p-System BIOS for RomWBW HBIOS source (TASM)
biostest.dat   binary image of SBIOSTESTER
boot.dat       binary image of p-System bootstrap
psys.vol       first (boot) slice, all p-System dist files
blank.vol      a generic blank p-System volume
fill.asm       used to complete the track 0 build (see below)

Notes:

This adatation runs on a single RomWBWW HBIOS hard disk type device (CF 
Cart, SD Card, IDE drive, etc.).  The image built (psys.img) should be 
copied to your disk media start at the first sector.  You can then boot 
by selecting the corresponding disk device unit number from the RomWBW 
boot loader prompt.  The p-System disk image (psys.img) is entirely 
different from the RomWBW CP/M-style disk images.

The boot device hard disk is broken up into 6 logical p-System 
volumes.  These are referred to as p-System slices.  A single RomWBW 
disk device can contain either CP/M-style slices or p-System slices, 
but not both. Each p-System slices is exactly 8 MB and support for 
exactly 6 slices is provided.

The first track of each volume contains all of the code required to 
boot the p-System.  However, the assignment of the volumes is always in 
the order that the slices appear physically on the hard disk device.  
Normally, you would just boot to slice 0 from the RomWBW Boot Loader.

The first track contains the following:
 - 4 sector p-System primary loader for RomWBW HBIOS
 - 1.5 sector p-System BIOS for RomWBW HBIOS
 - 4 sector p-System bootstrap
 - 6.5 sector filler to complete a full track

The p-System bootstrap is a binary image provided in the p-System 
distribution.  The loader and the BIOS are custom for RomWBW and the 
source is provided here.

The layout of the first track does not conform exactly to the 
recommended p-System layout.  The recommended layout is not possible 
because it conflicts with the RomWBW definition for a boot track.  
However, the changes are only slightly different sector assignments for 
the different boot componets -- the general boot sequence and mechanism 
for the p-System is completely standard.

The logical disk geometry used by this p-System
adaptation is:
 - 512 byte sector length
 - 16 sectors per track
 - 192 tracks per disk

This layout does not occupy the full 8MB slice size allocated.  This is 
to allow for future expansion of the filesystems.

The p-System distribution includes a BIOS tester that is provided as a 
binary image.  This tester was used to test the BIOS code in this 
adaptation.  It turns out that this code has a blatant error that
causes it to fail for 512 byte sector sizes (which are allowed).
To resolve this, biostest.dat was disassembled and patched to correct
the error.  The original version is retained as biostest.old.

The boot disk provided here was constructed by simply copying all of 
the content from the p-System distribution disks onto the boot disk.  
SYSTEM.MISCINFO was updated for an ANSI terminal.  The GOTOXY routine 
in SYSTEM.PASCAL was also updated for an ANSI terminal. Note that the 
BIOS conwrit routine is hacked to add a '[' to any output escape 
character.  This is needed because p-System has a very limited terminal 
escape sequence handling configuration.  The debugger code as added to 
SYSTEM.PASCAL to enable the debug function.  SYSTEM.INTERP was modified 
to enable the extended BIOS functions.

The build/makefile creates the psys disk image (psys.img) by adding 
concatentating psys.vol and blank.vol (after adding track 0 contents to 
each).  psys.vol and blank.vol are recognized by CiderPress and 
CiderPress can be used to add/remove files from these volumes.  
However, there is currently no straightforward way to extract the 
volumes from the disk image.  If you are good with a binary disk 
editor, you can do it that way.  Please contact me if you are 
interested in pursuing that.

There is currently no support for floppy drives.

Wayne Warthen
wwarthen@gmail.com

5:42 PM Sunday, January 15, 2023