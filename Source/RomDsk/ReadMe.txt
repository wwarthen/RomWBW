***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This is the parent directory for all files to be included in the ROM
Disk when a ROM is built.

When constructing the ROM disk as part of a build, the build process
first grabs all of the "standard" files for the size of ROM being
built.  So, if you are building a normal 512KB ROM, all of the files
in ROM_512KB directory will be pulled in.

You may freely add/delete/update the files in these directories to
change the contents of the ROM Disk of your ROM firmware.

CAUTION: The space on the ROM Disk is very limited and adding files
is likely to cause the ROM Disk to run out of space.  If this
happens, you will see an error like the following when running the
BuildROM script:

    cpmcp: can not write cpm.sys: device full

The resulting ROM Disk is still OK to use, but will not contain the
file(s) that did not fit.

RomWBW also supports the concept of a "ROMless" system in which an
external bootstrap pre-loads the RAM.  The RAM_xxxKB directories
contain the files to be used for such systems.  Note the size of the
RAM disk on a 512KB ROMless system is not the same as the RAM disk
on a normal system.  This is due to different bank layout and overhead.

System		ROM Disk Image		RAM Disk Image
------		--------------		--------------
128KB		n/a			n/a
256KB		128KB ROM Disk		n/a
512KB		384KB ROM Disk		256KB RAM Disk
1024KB		896KB ROM Disk		768KB RAM Disk ???
2048KB		n/a			1792KB RAM Disk ???