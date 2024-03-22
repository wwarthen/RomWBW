===== DOS/65 Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with RomWBW.  
It contains the files to start and run DOS/65 on an MBC system that
contains Dan Werner's 6502 processor.

WARNING: This is a work in progress.  Use of this disk image requires
specific hardware and configuration.  You should contact Dan Werner
before attempting to use this disk image.

The remainder of this document describes the usage and contents of
this disk.  It is highly recommended that you review the "RomWBW
User Guide.pdf" document found in the Doc directory of the
RomWBW Distribution.

== Usage ==

  - The disk is configured to boot under ZSDOS 1.1 (via primary Z80
    CPU).  Once booted, you can launch DOS/65 on a secondary 6502
    CPU using the "DOS65" command.
    
== Notes ==

  - DOS/65 is generally compatible with the CP/M 2.2 filesystem.  Once
    launched, you will have access to the fielsystem of the boot disk.

  - DOS/65 does not utilize any of the RomWBW framework or drivers, so
    it will only support devices built into DOS/65 itself.  Once
    launched DOS/65 takes over the hardware completely.
    
  - The contents of this disk are purely a redistribution of the work
    of Dan Werner.

-- WBW 2:47 PM 3/16/2023