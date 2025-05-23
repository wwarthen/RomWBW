# RomWBW Release Notes

This file contains information useful to those upgrading to a new
release of RomWBW.

## All Versions

- **Please** review the "Upgrading" Section of the RomWBW User Guide.

- The RomWBW ROM and the RomWBW disk images are intended to be a
  matched set.  After upgrading your ROM, it is important to update
  the OS boot tracks of your disks as well as the RomWBW-specific
  applications.  This is discussed in the "Upgrading" section of the
  RomWBW User Guide.

## Version 3.5.1

This is a patch release of v3.5.

### Fixes

- Corrects an issue with the `CPMLDR.SYS` and `ZPMLDR.SYS` files that
  caused `SYSCOPY` to fail when used with them.

- Added missing `BCLOAD` file to the MS BASIC Compiler disk image.
  
### New Features

- Added `SLABEL` application (Mark Pruden).

- Variety of documentation improvements, especially an overhaul of
  the Hardware Document (Mark Pruden).

## Version 3.5

### Upgrade Notes

- RomWBW is now more strict with respect to hard disk partition
  tables.  If your hard disk media was created using any of the
  pre-built disk image files, this will **not** affect you.  Otherwise,
  you may find you are unable to access slices beyond the first
  slice.  If so, use `FDISK80` to reset the partition table on the
  disk.  This will restore normal access to all slices.  **Only** do
  this if you are having an issue.

- For those building custom ROMs that are overriding `DEFSERCFG`, note 
  that this setting has been moved to a `#DEFINE` instead of an equate 
  (`.SET` or `.EQU`).  You will find this `#DEFINE` at the top of all
  standard config files.  You will need to change your setting to a
  `#DEFINE` at the top of your config file and remove any `.SET` or
  `.EQU` lines for `DEFSERCFG`.

- Combining config settings `AUTOCON` and `VDAEMU_SERKBD` causes issues
  at the boot loader prompt.  So, all config files have been changed to
  consistently enable `AUTOCON` and disable `VDAEMU_SERKBD` (`$FF`).  If
  are want to use `VDAEMU_SERKBD`, you need to set it in your config
  file as well as disabling AUTOCON.
  
### New Features

- RC2014 Front Panel and LCD Screen support.

- Console "takeover" support at Boot Loader prompt by pressing the
  <space> key twice on an alternate console device.

- Cowgol disk image based on the work of Ladislau Szilagyi.

- TMS video is automatically reset after an OS warm boot which
  allows OS to recover from applications that reprogram the TMS
  video display controller.

- Implemented "application" RAM banks that can be discovered via
  the HBIOS API.

- Documentation improvements (Mark Pruden), including:

  - Reorganization into multiple directories.
  - Improved Disk Management section in User Guide.
  - Overhaul of Disk Catalog.
  
- Disk image for Z3PLUS (Mark Pruden).

- `REBOOT` application added (Martin R).  Also, reboot capability
  added to `CPUSPD` utility.

- `COPYSL` slice copy application (Mark Pruden).

- `SLABEL` slice label display/edit tool (Mark Pruden).

- Improved disk slice management and protection (Mark Pruden).

- Initial NVRAM configuration support (Mark Pruden).

- Enhancements to ASSIGN command to automatically assign drives
  (Mark Pruden).


### New Hardware Support

- NABU w/ RomWBW Option Board.

- EF9345 video display controller driver (Laszlo Szolnoki).

- Duodyne Disk I/O (CP/NET) and Media boards.

- PS/2 keyboard interface on RCBus systems.

- S100 FPGA-based Z80 including console, SD Cards, and RTC.

- Support for 16C550-family UART support on additional platforms.

- Genesis STD Bus Z180 platform (Doug Jackson).

- Support for Dinoboard eZ80 CPU board provided by Dean Netherton.

- Added interrupt support to PS/2 keyboard driver by Phil Summers.
