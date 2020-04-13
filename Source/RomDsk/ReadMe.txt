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
in 512KB directory will be pulled in.

You may freely add/delete/update the files in these directories to
change the contents of the ROM Disk of your ROM firmware.

CAUTION: The space on the ROM Disk is very limited and adding files
is likely to cause the ROM Disk to run out of space.  If this
happens, you will see an error like the following when running the
BuildROM script:

    cpmcp: can not write cpm.sys: device full

The resulting ROM Disk is still OK to use, but will not contain the
file(s) that did not fit.
