===== NZCOM Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with
RomWBW.  It contains NZ-COM, which is an implementation of the
Z-System.  You may also see NZ-COM referred to as ZCPR 3.4.  This is
a powerful replacement for CP/M 2.2 w/ full backward compatibility.

The disk is bootable as is (the operating system image is already
embedded in the system tracks) and can be launched from the RomWBW
Loader prompt.  See the Usage and Notes sections below for more
information on how NZ-COM is loaded.

The remainder of this document describes the usage and contents of
this disk.  It is highly recommended that you review the "RomWBW
Getting Started.pdf" document found in the Doc directory of the
RomWBW Distribution.

The primary documentation for NZ-COM is the "NZCOM Users Manual.pdf" 
document  contained in the Doc directory of the RomWBW distribution.  
This document is a supplement to the primary documentation.  Additionally,
please review the file called RELEASE.NOT on this disk which contains
a variety of updates regarding the NZ-COM distribuition.

The starting point for the disk content was the final official release of
NZ-COM which is generally available on the Internet.  A minimal
system generation was done just sufficient to get NZ-COM to run under
RomWBW.  NZ-COM is extremely configurable and far more powerful than
DRI CP/M.  It is almost mandatory that you read the NZ-COM manual to
use the system effectively.

== Usage ==

NZCOM is not designed to load directly from the boot tracks of a
disk.  Instead, it expects to be loaded from an already running
OS.  This disk has been configured to boot using ZSDOS with a
PROFILE.SUB command file that automatically loads NZCOM.  So, NZCOM
will load completely without any intervention, but you may notice
that ZSDOS loads first, then ZSDOS loads NZCOM.  This is normal.

There is no DIR command.  Use SDZ or ZXD instead.

*** TODO: Date stamping ***

== Notes ==

NZCOM is distributed in an unconfigured state.  The following was
done to create a minimal ready-to-run setup for RomWBW:

  - Ran MKZCM and saved default configuration to NZCOM.ZCM and
    NZCOM.ENV.
  - Extract VT100 TCAP from Z3TCAP.LBR and saved it as TCAP.Z3T.
  - Created PROFILE.SUB to launch NZCOM at startup.
  - Created empty STARTZCM.COM.
  - TCSELECT.COM was removed because a later version is provided
    from the Z3 files.
  - Z3LOC.COM and LBREXT.COM were removed because more recent
    versions are provided from Common files.
  - Replaced ZRDOS with ZSDOS in NZCOM.LBR.  The standalone
    ZRDOS.ZRL and ZSDOS.ZRL files were saved.

The following additional customizations were also performed:

  - The following files from the original distribution were removed
    because newer versions are included:
    
    - COPY.COM
    - CRUNCH.COM
    - LBREXT.COM
    - TCSELECT.COM
    - UNCRUNCH.COM
    - Z3LOC.COM
    - ZCNFG.COM

== NZCOM Files ==

The following files came from the official NZCOM distribution.  These 
are generally documented in the "NZCOM Users Manual.pdf" document in 
the Doc directory of the RomWBW distribution.  Note that some of the 
files included in the NZ-COM distribution are not listed below because 
they have been superseded by more recent versions listed in other 
sections below.  For example, TCSELECT is not listed here, but a more 
recent version is included and documented in the General Purpose 
Applications section below.

!(C)1988 - Original copyright (since placed in public domain)
!NZ-COM - Software marker directory entry (empty file)
!VERS--1.2H - Version marker directory entry (empty file)
ALIAS.CMD - Sample alias definitions for use with ARUNZ
ARUNZ.COM - Alias-RUN-forZ-System command alias execution
BGZRDS19.LBR - ???
CLEDINST.COM - Configure RCP-resident command line editor
CLEDSAVE.COM - Save RCP-resident command line editor history
CONFIG.LBR - Various configuration files for use with ZCNFG
CPSET.COM - Displays/defines CRT/PRT characteristics
DOCFILES.LBR - Documentation and help files collected into an LBR file
EDITNDR.COM - Edit named directory register in memory
FCP.LBR - Library of alternative FCP modules
FF.COM - File finder utility
HELP.COM - (HELPC14) is an improved version of the help utility
HLPFILES.LBR - Various app help files for use with LBRHELP
IF.COM - Extended flow control tester
JETLDR.COM - Z-System package loader
LBRHELP.COM - Help file viewer for use with help file libraries (.LBR)
LDIR.COM - Directory lister for libraries (.LBR)
LPUT.COM - Puts file(s) into a library (.LBR)
LSH-HELP.COM - Display LSH help when LSH is running
LSH.COM - Command history shell and command line editor
LSH.WZ - User manual for LSH
LSHINST.COM - LSH configuration editor
LX.COM - Execute programs directly from a library (.LBR)
MKZCM.COM - Create/update NZ-COM load environment
NAME.COM - Quickly add or remove a name for a single directory
NZ-DBASE.INF - dBase II application note regarding SUBMIT files
NZBLITZ.COM - Rapid coldboot of complete NZ-COM system image
NZBLTZ14.CFG - ZCNFG configuration file for NZBLITZ
NZBLTZ14.HZP - Help file for NZBLITZ
NZCOM.COM - Loads and launches NZ-COM system
NZCOM.ENV - Z-System environment descriptor
NZCOM.LBR - Library containing NZ-COM system modules
NZCOM.ZCM - NZ-COM environment descriptor (alternate format)
NZCPR.LBR - Library of alternative ZCPR modules
PATH.COM - Set/display command search path
PROFILE.SUB - Command file to auto-start NZ-COM at system boot
PUBLIC.COM - Specify ZRDOS public directories/user areas
PWD.COM - Displays DU and Directory Names with paging
RCP.LBR - Library of alternative RCP modules
RELEASE.NOT - Update information on NZ-COM
SAINST.COM - Install/configure SALIAS
SALIAS.COM - Screen oriented alias editor
SAVENDR.COM - Writes the named directory register to disk
SDZ.COM - Enhanced directory lister
SHOW.COM - Display Z-System configuration information
STARTZCM.COM - Commands to execute after NZ-COM is launched
SUB.COM - Enhanced version of SUBMIT
TCJ.INF - Description of included articles from The Computer Journal
TCJ*.WZ - Selected articles from The Computer Journal
TY3ERA.COM - Type 3 erase command
TY3REN.COM - Type 3 rename command
TY4ERA.COM - Type 4 erase command
TY4REN.COM - Type 4 rename command
TY4SAVE.COM - Type 4 save command
TY4SP.COM - Type 4 disk space command
VIEW.COM - Quad directional file viewer
XTCAP.COM - Interactive Extended TCAP Installer
Z3TCAP.TCP - Database of terminal descriptors
ZERR.COM - Z34 Error Handler
ZEX.COM - Powerful command line processor
ZF-DIM.COM - Point-and-shoot user interface for dim-video terminals
ZF-REV.COM - Point-and-shoot user interface for reverse-video terminals
ZFILEB38.LZT - Brief listing of Z-System support programs
ZFILER.CMD - Macro script file for ZFILER
ZHELPERS.LZT - List of volunteers who will help installing Z-System
ZLT.COM - File lister with support for compressed files
ZNODES66.LZT - List of Z-Node remote access systems
ZRDOS.ZRL - Relocatable version of ZRDOS BDOS module
ZSDOS.ZRL - Relocatable version of ZSDOS 1.1 BDOS module
ZSYSTEM.IZF - Information on Z-System and related products

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

== ZSDOS Files ==

The following files came from the official ZSDOS distribution.  These
are generally documented in the "ZSDOS Manual.pdf" document in the Doc
directory of the RomWBW distribution.  These files are relevant under
NZ-COM because ZSDOS is a part of the NZ-COM system.

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