***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This is the parent directory for all files to be included in the ROM
Disk when a ROM is built.

When constructing the ROM Disk as part of a build, the build process
first grabs all of the "standard" files for the size of ROM being
built.  Note the table at the bottom of this file which indicates
the size of the ROM Disk that will be created depending on
the size of your ROM chip and the boot type of your system.  The
size of your ROM Disk determines which sub-folder will be used to
pull in your files.  For example, if you are using a typical 512KB
ROM chip and a normal ROM Boot process, you will have a 384KB ROM
Disk and the files will come from the ROM_384KB sub-folder.

You may freely add/delete/update the files in these directories to
change the contents of the ROM Disk of your ROM firmware.

CAUTION: The space on the ROM Disk is very limited and adding files
is likely to cause the ROM Disk to run out of space.  If this
happens, you will see an error like the following when running the
BuildROM script:

    cpmcp: can not write cpm.sys: device full

The resulting ROM Disk is still OK to use, but will not contain the
file(s) that did not fit.

The table below indicates the size of the ROM Disk that you will
have based on your ROM chip size and boot type.  The common boot
type is a ROM Boot where your system boots from code on the ROM.
Alternatively, some systems provide a ROMless boot where the
code is loaded from somewhere else (typically a disk or CF/SD Card).
In this case, you actually have no ROM disk, but instead you get
a pre-loaded RAM disk.

A normal ROM Boot system will have a ROM Disk that is 128KB less
than the size of the ROM chip.  A ROMless Boot system will have a
ROM Disk that is 256KB less than the size of the ROM chip.

ROM Chip	ROM Boot	ROMless Boot
--------------	--------------	--------------
128KB		n/a		n/a
256KB		128KB ROM Disk	n/a
512KB		384KB ROM Disk	256KB RAM Disk
1024KB		896KB ROM Disk	768KB RAM Disk
2048KB		n/a		1792KB RAM Disk