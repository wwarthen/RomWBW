===== QP/M Disk for RomWBW =====

This disk contains the distribution files for the QP/M Operating
System.  The disk is bootable with QP/M already installed on the
system tracks.  The qpm.sys file and the QP/M image on the system
tracks was created using QINSTALL with default settings EXCEPT
for the two settings described under Notes (current drive/user
storage address and TIMDAT vector).

QINSTALL can be run again as desired to further customize your 
installation.  However, note that QINSTALL does NOT remember prior 
settings, so you must reapply all settings you made previously
especially the two setting changes described below.

This disk includes the standard DRI CP/M 2.2 files in addition to the
QP/M files.  QP/M generally assumes you already had DRI CP/M 2.2
prior to adding QP/M features.  Since QP/M does not replace all
features of CP/M 2.2, the CP/M 2.2 files are also included.

== Notes ==

By default, QP/M saves the current drive/user (2 byte value) at address 0x0008.
This is also the address of the Z80 RST 08 restart vector and conflicts with
RomWBW.  When running QINSTALL, you must change the QP/M address for this value
to something else.  I have been using 0x000E without issue.

RomWBW CBIOS has been modified to put the QP/M TIMDAT vector at 0x0010.  The
vector points into CBIOS where the actual TIMDAT routine is located.  The
TIMDAT routine reads the current date/time from HBIOS, changes the values from
BCD to binary, and rearranges some bytes for QP/M compatibilty.  When
running QINSTALL, you should set the TIMDAT vector to 0x0010 to
enabled QP/M to use your RomWBW real time clock.

By default, DEBUGZ utilizes the RST 38 restart vector for setting
code brakpoints.  This conflicts the use of that vector for any
system that is using interrupt mode 1.  DEBUGZ can be configured
(using DBGINST) to use a different vector.

The QSTAMP program, which is used to initialize a disk for date/time
stamping, misbehavews when run on the (new) RomWBW 1024 directory
format disks.  It creates an invalid directory entry for the
date/time stamp data file.  This is definitely a QP/M issue.  The
directory entry can be manually corrected.

== ZSDOS 1.1 Files ==

The following files came from the official QP/M distribution.  Actually,
they came from 3 Microcode Consulting files (qpm27.zip, debugz.zip,
and linkz.zip).  The original distribution files can be found on the
Microcode Consulting website at https://www.microcodeconsulting.com/.
Documentation (pdf) files are incuded in these original distribution
.zip files.  These documentation files have not been included in the
RomWBW distribution.  Please retrieve them yourself from the website
if desired.

D.COM - Directory lister
DBGINST.COM - Configures DEBUGZ debugger
DEBUGZ.COM - QP/M debugger
DEBUGZ.HLP - QP/M debugger help file
DHORIZ.COM - Version of directory lister for horizontal file sorting
HELLO.QPM - Text file with QP/M version information
LZ.COM - QP/M linker
QBACKUP.COM - Data backup application
QINSTALL.COM - QP/M installer / configurator
QPATCH.COM - Patches (customizes) a few QP/M applications
QPIP.COM - QP/M enhanced version of CP/M 2.2 PIP application
QPM.SYS - RomWBW configured QP/M system image (for use with SYSCOPY)
QPMCLK.MAC - Example of QP/M clock assembler routine
QPMCMDS.TXT - Brief summary of QP/M commands
QPMUTILS.TXT - Brief summary of QP/M utilities
QSTAMP.COM - Initializes disk for date/time stamping
QSTAMPV.COM - Initializes disk for date/time stamping (vertical sort)
QSTAMPX.COM - Initializes disk for date/time stamping (horizontal sort)
QSTAT.COM - QP/M enhanced version of CP/M 2.2 STAT application
QSUB.COM - QP/M batch file submission program
QSWEEP.COM - QP/M directory sweep utility
QTERM.DAT - Terminal control codes used by DEBUGZ
QTERMS.LIB - Library of available terminal definitions
SETQTERM.COM - Configures QTERM.DAT
TDCNFG.COM - Configures date/time directory display preferences

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

--WBW 4:41 PM 6/10/2022
