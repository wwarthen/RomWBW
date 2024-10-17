***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory contains the ZSDOS system files for the RomWBW ZSDOS
adaptation.  All of these files are already included on the ZSDOS
boot disk images.  However if you are creating a ZSDOS boot disk
manually, you should copy all of these files to the boot disk.

Note: Two file have been provided one for RomWBW HBIOS, and one for UNA
BIOS. One of these files must be installed on the system boot track.
This is usually achieved by the SYSCOPY utility e.g.

SYSCOPY a:=zsys_wbw.sys

These files should also be copied to any ZSDOS boot disks on your
system when you upgrade your ROM firmware.  Some of these files
*must* match the version of the RomWBW firmware you are using for
proper operation of your system.
