===== CP/M-80 2.2 Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with RomWBW.  
It contains a vanilla distribution of DRI's CP/M-80 2.2 adapted for 
RomWBW.  The disk is bootable as is (the operating system image is 
already embedded in the system tracks) and can be launched from the 
RomWBW Loader prompt.

The remainder of this document describes the usage and contents of
this disk.  It is highly recommended that you review the "RomWBW
Getting Started.pdf" document found in the Doc directory of the
RomWBW Distribution.

== Usage ==

  - All installation steps needed to run CP/M 2.2 have already been
    performed.  It is not necessary to perform the steps in the
    Alteration section of the CPM Manual.
  - The MOVCPM application referred to in the manual is not needed
    with RomWBW and is not included.
  - The manual refers to the use of SYSGEN to install a copy of CP/M 2.2
    on the boot tracks of a disk to make it bootable.  Under RomWBW, it
    is recommended that you use SYSCOPY instead.  SYSGEN is included,
    but SYSCOPY is more flexible.  The use of SYSCOPY is documented in
    the RomWBW Applications document.

== Notes ==

  - SUBMIT.COM has been patched per the official DRI patch list such
    that the submit file will always be placed on the A: drive which
    ensures it will be run properly even if your default drive is not
    currently A:.
  - DDT, DDTZ, and ZSID have been patched to use RST 6 instead of the
    original RST 7 vector for single step debugging.  This is mandatory
    for a Z80 CPU which uses RST 7 for hardware interrupts.
  - CP/M 2.2 was not distributed with a help system.  Douglas Miller
    has adapted the CP/M 3 help system for CP/M 2.2 and is included.
    The HELP.HLP data file must be found on the current default drive
    and user area when HELP.COM is run.

== CP/M 2.2 Files ==

The following CP/M 2.2 files were distributed by DRI with the operating
system or as supplemental add-on programs.  They are documented in the
"CP/M Manual.pdf" document in the Doc directory of the Rom WBW
distribution.  MAC, RMAC, ZSID are supplemental programs from DRI
with separate standalone documentation which is not included in the
RomWBW package (but easily found on the Internet via Google search).

ASM.COM - DRI 8080 assembler producing Intel hex files
DDT.COM - DRI 8080 debugger
DUMP.COM - Tool to dump a file in hex
ED.COM - DRI line editor
HELP.COM - HELP display program (derived from CP/M 3 HELP.COM)
HELP.HLP - HELP data file
LIB.COM - DRI relocatable object file librarian
LINK.COM - DRI relocatable object file linker
LOAD.COM - DRI loader for Intel hex files
MAC.COM - DRI 8080 macro assembler producing Intel hex files
PIP.COM - DRI file transfer (Peripheral Interchange Program)
RMAC.COM - DRI 8080 macro assembler producing relocatable object files
STAT.COM - DRI multi-purpose file/disk/device info & configuration tool
SUBMIT.COM - DRI batch file submission tool
XSUB.COM - DRI batch file enhancer resident system extension
ZSID.COM - DRI enhanced debugger for Z80 CPU

== RomWBW Supplemental Applications ==

The following files provide specific functionality enabled by
RomWBW enhancements.  These applications are documented in the
"RomWBW Applications.pdf" document in the Doc directory of the
RomWBW Distribution.

ASSIGN.COM - Assign,remove,swap drive letters of RomWBW disk slices
FAT.COM - MS-DOS FAT filesystem tool (list, copy, delete, format, etc.)
FDU.COM - Test floppy hardware and format floppy disks
FORMAT.COM - Placeholder application with formatting instructions
INTTEST.COM - Test RomWBW interrupt processing on your hardware
MODE.COM - Change serial line characteristics (baud rate, etc.)
RTC.COM - Test real time clock hardware on your system
SURVEY.COM - Display system resources summary
SYSCOPY.COM - Copy system tracks to disks (make bootable)
SYSGEN.COM - Copy system tracks to disks (DRI version)
TALK.COM - Route console I/O to & from specified serial port
TIMER.COM - Test and display system timer ticks
TUNE.COM - Play .PT2, .PT3, and .MYM audio files on supported hardware
XM.COM - XModem file transfer application
ZMP.COM - ZModem communications program (requires dedicated comm port)
ZMP.DOC - Documentation for ZMP
ZMP.HLP - Help file for ZMP
ZMXFER.OVR - Overlay file for ZMP
ZMTERM.OVR - Overlay file for ZMP
ZMINIT.OVR - Overlay file for ZMP
ZMCONFIG.OVR - Overlay file for ZMP

== General Purpose Applications ==

The following files are commonly used CP/M applications that
are generally useful in any CP/M-like system.  In general, there is
no documentation for these applications included with the RomWBW
distribution.  Some provide command line help themselves.  Some
are fairly obvious.

CLRDIR.COM - Initializes the directory area of a disk
COMPARE.COM - Compare content of two files (binary)
CRUNCH.COM - Compress file(s) using Crunch algorithm
CRUNCH28.CFG - ZCNFG configuration file for CRUNCH & UNCR
DDTZ.COM - Z80 debug tool (modified to use RST 6)
DDTZ.DOC - Documentation for DDTZ
EX.COM - Batch file processor (alternative to DRI SUBMIT)
FDISK80.COM - Hard disk partitioning tool (from John Coffman)
FIND.COM - Search all drives for a file (from Jay Cotton)
FLASH.COM - Program FLASH chips in-situ (from Will Sowerbutts)
FLASH.DOC - Documentation for FLASH
MBASIC.COM - Microsoft BASIC language interpreter
NULU.COM - Library (.LBR) management tool
PMARC.COM - Create or add file(s) to .PMA archive
PMEXT.COM - Extract file(s) from .PMA/.LZH/.LHA archive
RMXSUB1.COM - Remove XSUB1 RSX from memory (from Lars Nelson)
SUPERSUB.COM - Enhanced replacement for DRI SUBMIT
SUPERSUB.DOC - Documentation for SUPERSUB
TDLBASIC.COM - TDL Zapple 12K BASIC language interpreter
UNARC.COM - Extract file(s) from .ARC or .ARK archive
UNARC.DOC - Documentation for UNARC
UNCR.COM - Decompress Crunched file(s)
UNZIP.COM - UNZIPZ extracts from all MS-DOS ZIP files (from Lars Nelson)
UNZIP.DOC - Documentation for UNZIPZ
XSUB1.COM - Replacement for DRI SUB (from Lars Nelson)
ZAP.COM - Interactive disk & file utility
ZDE.COM - Compact WordStar-like editor
ZDENST.COM - Installation/configuration tool for ZDE
KERCPM22.COM - Kermit file transfer application
LBREXT.COM - Extract file from .LBR libraries
LBREXT36.CFG - ZCNFG configuration file for LBREXT
ZXD.COM - Enhanced directory lister w/ date/time stamp support
ZXD.CFG - ZCNFG configuration file for ZXD

== Testing Applications (User Area 2) ==

User area 2 contains a variety of hardware testing applications.
These are generally user contributed and have no documentation.

N.B., these applications are frequently not compatible with all RomWBW 
hardware.  They are included here as a convenience.  If applicable, 
your hardware documentation should refer to them and provide usage 
instructions.

== Sample Tune Files (User Area 3) ==

User area 3 contains sample audio files that can be played using
the TUNE application.

== CP/NET 1.2 (User Area 4) ==

User area 4 contains a full implementation of the CP/NET 1.2
client provided by Doug Miller.  Please read the README.TXT file
in this user area for more information.

N.B., at a minimum, some of the files in this user area must be copied
to user area 0 for CP/NET to work properly.

-- WBW 3:20 PM 8/27/2021