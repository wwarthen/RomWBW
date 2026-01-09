RomWBW Loader for MSX
=====================

The loader can be started from the MSX-DOS 1, MSX-DOS 2 or Nextor 
command prompt.

It will check the RAM mapper requirements based on the size of the rom 
image file.

The "MSX_std.rom" image must be copied to "MSX-STD.ROM" on the MSX disk 
media together with "MSX-LDR.COM".

RomWBW MSX Combo Disk Creation
==============================

This folder contains Windows scripts to create a RomWBW MSX combo disk 
image.

Usage
-----

1. Copy the Source folder into the RomWBW folder.
2. Download mtools for Windows: https://github.com/YawHuei/mtools_win32 
3. Copy the mtools executables into the (new) RomWBW\Tools\mtools folder
4. Run the RomWBW build script for your platform e.g. "build msx std"
   or "build rcz80 std"
5. In the Source\MSX folder run "BuildMsxDsk.cmd"

If the scripts run successfully the Binary\msx_combo.dsk file is created.

Disk image contents
-------------------

The disk image will contain three partitions:
- RomWBW partition with 16 slices (128MB)
- MSX-DOS FAT12 system partition (8MB)
- FAT16 data partition (100MB)

The RomWBW partition contains the standard RomWBW slices, the games 
slice, the msx system slice and 8 blank slices.  The msx system slice 
contains the CP/M loader program to start the MSX system from RomWBW.

The FAT12 system partition contains the MSX-DOS system files and loader 
to start RomWBW on a MSX system. If the MSX system is started from 
RomWBW this will be the A-drive.

The FAT16 data partition is a formatted empty partition.
If the MSX system is started from RomWBW this will be the B-drive.

Note
----
This is a work in progress and subject to change without notice.