This file contains information useful to those upgrading to a new
release of RomWBW.

All Versions
============

- Please review the "Upgrading" Section of the RomWBW User Guide.

- Many RomWBW-specific applications are locked to the ROM version
  being used.  After upgrading your ROM, you will need to upgrade
  your disk-based RomWBW applications and OS boot files.

Version 3.5
===========

- RomWBW is now more strict with respect to hard disk partition
  tables.  If your hard disk media was created using any of the
  pre-built disk image files, this will **not** affect you.  Otherwise,
  you may find you are unable to access slices beyond the first
  slice.  If so, use FDISK80 to reset the partition table on the
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