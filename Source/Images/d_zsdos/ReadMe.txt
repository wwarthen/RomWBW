===== ZSDOS Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with
RomWBW.  It contains a customized version of ZSDOS 1.1 for RomWBW.
The disk is bootable as is (the operating system image is already
embedded in the system tracks) and can be launched from the RomWBW
Loader prompt.

The remainder of this document describes the usage and contents of
this disk.  It is highly recommended that you review the "RomWBW
Getting Started.pdf" document found in the Doc directory of the
RomWBW Distribution.

ZSDOS is a replacement for the BDOS portion of the CP/M 2.2 operating
system.  Since it does not include it's own command processor, the
the ZCPR D&J Command Processor has been included.

The primary documentation for ZSDOS and ZCPR 1 are contained in the Doc
directory of the RomWBW distribution.  The specific files are "ZSDOS
Manual.pdf", "ZCPR Manual.pdf", and "ZCPR-DJ.doc".  This document is a
supplement to the primary documentation.

The starting point for the disk content was the final public release of
ZSDOS which is generally available on the Internet.  Overall, the
following steps were performed:

1. System installation and integration with RomWBW.
2. Update files to newer versions, as available.
3. Configure applications for RomWBW (clock drivers, terminal emulation,
   etc.)
4. Add selected CP/M 2 applications (listed below).
5. Add selected RomWBW supplemental applications (listed below).
6. Add some useful general purpose applications (listed below).

Note that ZSDOS can be built as either ZSDOS or ZDDOS. It is the same
source file, but an equate determines which variation you want to
build. Basically, ZSDOS has more features. ZDDOS has less features, but
includes the date stamping code built-in. The ZSDOS Manual provides
more information.  I have chosen to use ZSDOS to pick up the maximum
number of features. Date stamping is still available, but must be
loaded as an RSX.

The source allows you to compile the OS code as either v1.1 or v1.2 via 
an equate. Version 1.2 was never distributed and contains only a few 
minor fixes.  Unfortunately, the use of v1.2 would make it incompatible 
with many support modules and overlays due to their reliance on 
hard-coded address assumptions.  This is probably why it was never 
distributed.  I encountered this myself with the date stamping code –- 
it won't work with v1.2 because it does a version check. For now, I have 
chosen to use v1.1 to maximize compatibility (seems to be what everyone 
is doing). Ultimately, I may go back and try to rebuild everything in 
the distribution to bring it all up to v1.2. That is for the future 
though.

== Usage ==

  - All installation steps needed to run ZSDOS have already been
    performed.  It is not necessary to perform any of the steps in
    the "Installing ZSDOS" section of the ZSDOS Manual unless you
    want to modify the installation.
  - ZSDOS has a concept of fast relog of drives. This means that after
    a warm start, it avoids the overhead of relogging all the disk
    drives. There are times when this causes issues. After using tools
    like CLRDIR or MAP, you may need to run "RELOG" to get the drive
    properly recognized by ZSDOS.
  - ZSVSTAMP from the original distribution is included, but requires a
    ZCPR 3.X command processor. The RomWBW ZSDOS disk image uses ZCPR 1.0
    (intentionally, to reduce space usage) and ZSVSTAMP will just abort
    in this case. It will work fine if you implement NZCOM. ZSVSTAMP is
    included solely to facilitate usage if/when you install NZCOM.
  - FILEDATE only works with DateStamper style date stamping. If you
    run it on a drive that is not initialized for DateStamper, it will
    complain "FILEDATE, !!!TIME&.DAT missing". This is normal and just
    means that you have not initialized that drive for DateStamper (using
    PUTDS).
  - ZXD will handle either DateStamper or P2DOS type date stamping.
    However, it MUST be configured appropriately. As distributed, it will
    look for DateStamper date stamps. Use ZCNFG to reconfigure it for
    P2DOS date stamps if that is what you are using.
  - Many of the tools can be configured (using either ZCNFG or
    DSCONFIG). The configuration process modifies the actual application
    file itself. This will fail if you try to modify one that is on the
    ROM disk because it will not be able to update the image.
  - DATSWEEP can be configured using DSCONFIG. However, DSCONFIG itself
    needs to be configured first for proper terminal emulation by using
    SETTERM. So, run SETTERM on DSCONFIG before using DSCONFIG to
    configure DATSWEEP!
  - After using PUTDS to initialize a directory for ZDS date stamping,
    I am finding that it is necessary to run RELOG before the stamping
    routines will actually start working.
  - Generic CP/M PIP and ZSDOS path searching do not mix well if you
    use PIP to copy to or from a directory in the ZSDOS search path. Best
    to use COPY from the ZSDOS distribution.
  - PUTBG.COM and BGPATCH.HEX are included, but note that they are for
    use with BackGrounder II software which is not included.  Refer to
    the ZSDOS Manual for information on implementing BackGrounder II if
    desired.

== Date Stamping Quick Start ==

== Notes ==

As I worked through the files in the distribution, it became clear that
there were problems with the distribution. For example, the .CFG files
for some apps (like FILEDATE.COM) are not acceptable to ZCNFG.
Additionally, the STAMPS.DAT file contains code that simply does not
work. In all of these cases, I found updated or fixed versions of the
files. However, the point is that I concluded I would need to go
through the distribution file-by-file and validate everything,
replacing anything that was not working as it should. See the notes below
for what I did.

The following list details the changes I made as I went along. In all
cases, my goal was to keep the result as close to the original
distribution as possible.

  - CLOCKS.DAT has been updated to include the RomWBW clock driver,
    WBWCLK. I have also added the SIMHCLOK clock driver.
  - STAMPS.DAT has been replaced with an updated version. The update
    was called STAMPS11.DAT and was found on the Walnut Creek CP/M CDROM.
    The original version has a bug that causes RSX (resident system
    extension) mode to fail to load properly.
  - The original LDTIMD.COM and LDTIMP.COM have been replaced with
    LDDS.COM (DateStamper) and LDP2D.COM (P2DOS) respectively.  They are
    equivalent but configured to use the RomWBW clock driver.  They were
    built exactly the same as the originals: Relative Clock driver w/ RSX
    mode loading.
  - A driver for NZT format time stamping has been added.  It is called
    LDNZT.COM.
  - Updated FILEDATE.COM and FILEDATE.CFG from original v1.7 to v2.1.
    The FILEDATE.CFG originally supplied was invalid.
  - Updated FILEATTR to v1.6A. Original FILEATTR.CFG was invalid.
    FILEATTR.CFG was replaced with FA16.CFG. Added associated files
    FA16.DOC, FA16A.FOR, FA16CFG.TXT.
  - Updated COPY.COM to v1.73.  Also updated COPY.CFG to the one
    distributed with COPY.COM v1.73. The original COPY.CFG was invalid
    and appeared to be for a much older version of COPY.
  - Configured DATSWEEP.COM and DSCONFIG to use ANSI Standard terminal
    definition using SETTERM.

== ZSDOS 1.1 Files ==

The following files came from the official ZSDOS distribution.  These
are generally documented in the "ZSDOS Manual.pdf" document in the Doc
directory of the RomWBW distribution.  Note that some of the files
included in the ZSDOS distribution are not listed below because they
have been superseded by more recent versions listed in other sections
below.  For example, ZXD is not listed here, but a more recent version is
included and documented in the General Purpose Applications section
below.

BGPATCH.HEX - Patches BackGrounder II for ZSDOS 1.1 compatibility
CLOCKS.DAT - Library of clock drivers
COPY.CFG - ZCNFG configuration file for COPY
COPY.COM - Enhanced file copy tool
COPY.UPD - Document describing updates to COPY program
DATSWEEP.COM - File management utility w/ date/time stamp awareness
DSCONFIG.COM - Program to configure DATSWEEP
FA16.CFG - ZCNFG configuration file for FILEATTR
FA16.DOC - Documentation for FILEATTR
FA16A.FOR - Summary of FILEATTR program version 16a
FA16CFG.TXT - Document describes FILEATTR configuration options
FILEATTR.COM - Set and/or display file attributes
FILEDATE.CFG - ZCNFG configuration fie for FILEDATE
FILEDATE.COM - Date/time stamping aware disk directory utility
INITDIR.CFG - ZCNFG configuration file for INITDIR
INITDIR.COM - Prepare disk for P2DOS date/time stamping
LDDS.COM - Load DateStamper date/time stamping resident extension
LDNZT.COM - Load NZT date/time stamping resident extension
LDP2D.COM - Load P2DOS date/time stamping resident extension
PUTBG.COM - Updated replacement for BackGrounder II PUTBG program
PUTDS.COM - Prepare disk for DateStamper date/time stamping
RELOG.COM - Clear fixed disk login vector in ZSDOS (see manual)
SETTERM.COM - Terminal configuration utility for DATSWEEP & DSCONFIG
SETUPZST.COM - Creates customized date/time stamping resident extensions
STAMPS.DAT - Library of available date/time stamping modules for SETUPZST
TD.CFG - ZCNFG configuration file for TD
TD.COM - Read and set system real-time clock
TERMBASE.DAT - Library of terminals used by SETTERM
TESTCLOK.COM - Test a selected clock driver
ZCAL.COM - Display a small one-month calendar to the screen
ZCNFG.COM - Configuration tool for programs with .CFG files
ZCNFG24.CFG - ZCNFG configuration file for ZCNFG
ZPATH.COM - Set or display ZSDOS and ZCPR search paths
ZSCONFIG.COM - Dynamically configure features of ZSDOS operating system
ZSVSTAMP.COM - Preserves file date/time stamp across modifications
ZSVSTAMP.DOC - Document describes the use and operation of ZSVSTAMP

== CP/M 2.2 Files ==

The following files have been included from CP/M 2.2.  These files
provide various functionality that is not really available from the
ZSDOS applications themselves.  For example, the CP/M 2.2 application
called STAT is useful for modifying the IOBYTE.  Most of these
applications are documented in the "CPM Manual.pdf" document in the Doc
directory of the RomWBW distribution.

ASM.COM - DRI 8080 assembler producing Intel hex files
LIB.COM - DRI relocatable object file librarian
LINK.COM - DRI relocatable object file linker
LOAD.COM - DRI loader for Intel hex files
MAC.COM - DRI 8080 macro assembler producing Intel hex files
RMAC.COM - DRI 8080 macro assembler producing relocatable object files
STAT.COM - DRI multi-purpose file/disk/device info & configuration tool
SUBMIT.COM - DRI batch file submission tool
XSUB.COM - DRI batch file enhancer resident system extension

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
Additionally, they are frequently not compatible with all RomWBW
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