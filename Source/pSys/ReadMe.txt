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

This adaptation runs on a single RomWBW HBIOS hard disk type device (CF 
Card, SD Card, IDE drive, etc.).  The image built (psys.img) should be 
copied to your disk media starting at the first sector.  You can then 
boot by selecting the corresponding disk device unit number from the 
RomWBW boot loader prompt.  The p-System disk image (psys.img) is 
entirely different from the RomWBW CP/M-style disk images.

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

So, it turns out that the serial line support in p-System is seriously 
deficient.  It insists on polling all of the serial input devices 
(console, remote, and printer) when the sytem is idle with the idea 
that it will queue up any characters received.  I guess the idea is 
that this will help in scenarios where characters are coming in too 
fast to be processed. However, the basic/default interpreter does not 
support the queues! Strangely, it still polls the the devices and 
literally discards anything received.  This completely undermines the 
ability of the underlying hardware which is doing it's own robust
interrupt or hardware based buffering and flow control.

I have relinked the interpreter (SYSTEM.INTERP) so that it now uses
the BIOS version that supports the queues (BIOS.CRP).  This mostly
resolves the situation, but needlessly increases the size of the
interpreter.  Additionally, I believe that if the p-System queue gets
full, it will still poll and discard any new characters received.  I
have not seen any documentation indicating the size of the queues.

Seriously, what were they thinking.

One last thing in case anyone actually reads this.  As indicated
above, this is an adaptation of p-System IV.0.  It is well documented
that SofTech produced a IV.1 with some nice enhancements (like
subsidiary volumes and decent support for ANSI/VT-100 terminals).  I
have been unable to track down the IV.1 distribution media despite
trying very hard.  If anyone knows of a source for the media of the
Adapable p-System for Z80, I would love to get hold of it.

3:58 PM Tuesday, January 17, 2023

I forgot to discuss the terminal handling.

The p-System has a setup program (SETUP.CODE) that is used to define
terminal handling escape sequences.  However, it is limited to a
single character to introduce the escape sequences.  Since ANSI
and VT-100 escape sequences start with 2 characters, this is
problematic.  The BIOS for RomWBW borrows a hack used by Udo Monk.
Specifically, whenever an outbound <esc> is seen, a '[' is added
in flight.

Likewise, it is problematic to define a way to interpret the
arrow keys transmitted by an ANSI/VT-100 terminal.  In this case,
the setup program was used to define up/down/left/right like
WordStar does: ^E,^X,^S,^D.

5:48 PM Tuesday, January 17, 2023