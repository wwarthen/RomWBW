===== DOS/65 Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with RomWBW.  
It contains the files to start and run DOS/65 on a Nhyodyne system that
with a 6502 processor board.

WARNING: This is a work in progress.  Use of this disk image requires
specific hardware and configuration.  You should contact Dan Werner
before attempting to use this disk image.

More information on the contents of this disk and the associated
6502 processor board can be found at the following link:

https://github.com/lynchaj/nhyodyne/tree/main/6502PROC

== Usage ==

  - The disk is configured to boot under ZSDOS 1.1 (via primary Z80
    CPU).  Once booted, you can launch DOS/65 on a secondary 6502
    CPU using the "DOS65" command.
    
== Notes ==

  - DOS/65 is generally compatible with the CP/M 2.2 filesystem.  Once
    launched, you will have access to the filesystem of the boot disk.

  - DOS/65 does not utilize any of the RomWBW framework or drivers, so
    it will only support devices built into DOS/65 itself.  Once
    launched DOS/65 takes over the hardware completely.
    
  - The contents of this disk are purely a redistribution of the work
    of Dan Werner.

-- WBW 3:56 PM 10/22/2024