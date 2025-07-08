$define{doc_title}{Disk Catalog}$
$define{doc_author}{Mark Pruden \& Mykl Orders}$
$define{doc_authmail}{}$
$include{"Book.h"}$

# RomWBW Distribution File Catalog

This document is a reference to the files found on the disk media
distributed with RomWBW.  Specifically, RomWBW provides a set
of floppy and hard disk images in the Binary directory of the
distribution.  The contents of these images is listed here.

The files on the disk images were sourced from a variety of locations.
The primary sources of these files are listed below.  Note that the
primary documentation for each of these sources is listed.  You are
strongly encouraged to refer to this documentation for more information
on using the applications and files listed.

This document primarily describes to contents of the hard disk images.
Floppy disk images may contain a cut down (sub-set) of the files on
a hard disk. This is of course to conserve disk space

Note: This document received a major update in October 2024, when
while still not fully complete, most of the core operating system
disks should now be fully described.

## Sources

- **RomWBW**: RomWBW Custom Applications

  Documentation: *RomWBW Applications.pdf*

  These files are custom applications built exclusively to enhance the
  functionality of RomWBW.  In some cases they are built from scratch
  while others are customized versions of well known CP/M tools.

- **CPM22**: Digital Research CP/M-80 2.2 Distribution Files

  Documentation: *CPM Manual.pdf*

  These files are from the official Digital Research distribution
  of CP/M 2.2.  Applications have been patched according to the
  DRI patch list.

- **ZSDOS**: ZSDOS 1.1 Disk Operating System Distribution Files

  Documentation: *ZSDOS Manual.pdf*

  These files are from the official ZSDOS 1.1 distribution.  Some of
  the files are redistributions of applications from other sources.

- **ZCPR**: ZCPR 1.0 Command Processor Distribution Files

  Documentation: *ZCPR Manual.pdf*

  These files are from the ZCPR 1.0 distribution.

- **NZCOM**: NZCOM Automatic Z-System Distribution Files

  Documentation: *NZCOM Users Manual.pdf*

  These files are from the last official release of NZCOM.

- **CPM3**: Digital Research CP/M 3 Distribution Files

  Documentation: *CPM3 Users Guide.pdf*, *CPM3 System Guide.pdf*,
  *CPM3 Programmers Guide.pdf*, *CPM3 Command Summary.pdf*

  These files are from the official Digital Research distribution of
  CP/M 3.  Applications have been patched according to the DRI
  patch list.

- **ZPM3**: ZPM3 Distribution Files

  Documentation: *ZPM3.txt*

  These files are from Simeon Cran's official distribution of ZPM3. 
  All known patches have been applied.

`\clearpage`{=latex}

# Operating System Boot Disks

RomWBW contains several ready-to-run disks, that have been
adapted for RomWBW.  Theses disks are bootable as is 
(the operating system image is already embedded in the system tracks) 
and can be launched from the RomWBW Loader prompt.

Each Disk contains the following file

| **File**                 | **Description**                             |
|--------------------------|---------------------------------------------|
| `README.TXT`             | Information about the Operating System      |

## CP/M 2.2

A vanilla distribution of DRI's CP/M-80 2.2 adapted for RomWBW.  

| Floppy Disk Image: **fd_cpm22.img**
| Hard Disk Image: **hd_cpm22.img**
| Combo Disk Image: **Slice 0**

### CP/M 2.2 OS Files

These are built and provide the OS. CP/M 2.2 Typically has no boot files 
stored on the disk. It entirely boots from the system track

The following files appear in User Area 0

| **File**        | **Source**      | **Description**                    |
|-----------------|-----------------|------------------------------------|
| `CPM.SYS`       | RomWBW          | DRI CPM 2.2 Boot Image for SYSCOPY |

### CP/M 2.2 Files

The following CP/M 2.2 files were distributed by DRI with the operating
system or as supplemental add-on programs.  They are documented in the
"CP/M Manual.pdf" document in the Doc/CPM directory of the Rom WBW
distribution.  

The following files appear in User Area 0

| **File**        | **Description**                                      |
|-----------------|------------------------------------------------------|
| `ASM.COM`       | DRI 8080 assembler                                   |
| `DDT.COM`       | 8080 dynamic debugger                                |
| `DUMP.COM`      | DRI type contents of file in hex                     |
| `ED.COM`        | DRI line editor                                      |
| `HELP.COM`      | CP/M 3 derived HELP display                          |
| `HELP.HLP`      | CP/M 3 derived HELP data file                        |
| `LIB.COM`       | DRI object file library manager                      |
| `LINK.COM`      | DRI object file linker                               |
| `LOAD.COM`      | DRI loader for Intel hex files                       |
| `MAC.COM`       | DRI 8080 macro assembler                             |
| `PIP.COM`       | DRI periperal interchange program                    |
| `RMAC.COM`      | DRI 8080 relocating macro assembler                  |
| `STAT.COM`      | DRI file/disk/device info & config                   |
| `SUBMIT.COM`    | DRI batch file submission tool                       |
| `XREF.COM`      | DRI assembler cross reference listing utility        |
| `XSUB.COM`      | DRI batch file resident extension                    |
| `ZSID.COM`      | DRI Z80 symbolic debugger                            |

**NOTE:** The above files are also included in the NZCOM disk image.

MAC, RMAC, XREF, and ZSID are supplemental programs from DRI
with separate standalone documentation which is not included in the
RomWBW package (but easily found on the Internet via Google search).

### Additional Files

| **File** | **Documentation**                  | **User Area** |
|----------|------------------------------------|---------------|
|          | [OS General Files]                 | 0             |
|          | [General Purpose Applications]     | 0             |
|          | [Testing Applications]             | 2             |
|          | [Sample Audio Files]               | 3             |
|          | [CP/NET 1.2]                       | 4             |
|          | [SIMH Simulator]                   | 13            |

`\clearpage`{=latex}

## ZSDOS 1.1

It contains a customized version of ZSDOS 1.1 for RomWBW.
The disk is bootable as is (the operating system image is already
embedded in the system tracks) and can be launched from the RomWBW
Loader prompt.

The starting point for the disk content was the final public release of
ZSDOS which is generally available on the Internet. 

| Floppy Disk Image: **fd_zsdos.img**
| Hard Disk Image: **hd_zsdos.img**
| Combo Disk Image: **Slice 1**

### ZSDOS 1.1 OS Files

These are built and provide the OS. ZSDOS Typically has no boot files 
stored on the disk. It entirely boots from the system track

The following files appear in User Area 0

| **File**          | **Source**           | **Description**              |
|-------------------|----------------------|------------------------------|
| `ZSYS.SYS`        | RomWBW               | ZSDOS Boot Image for SYSCOPY |

### ZSDOS 1.1 Files

The following files came from the official ZSDOS distribution.  These
are generally documented in the "ZSDOS Manual.pdf" document in the Doc/CPM
directory of the RomWBW distribution.  

Note: Some of the files included in the ZSDOS distribution are not listed 
below because they have been superseded by more recent versions listed in 
other sections below.  

The following files appear in User Area 0

| **File**       | **Description**                                        |
|----------------|--------------------------------------------------------|
| `BGPATCH.HEX`  | Patches BackGrounder II for ZSDOS 1.1 compatibility    |
| `CLOCKS.DAT`   | Library of clock drivers                               |
| `COPY.UPD`     | Document describing updates to COPY program            |
| `DATSWEEP.COM` | Comprehensive file management w/ date stamp awareness  |
| `DSCONFIG.COM` | Program to configure DATSWEEP                          |
| `FA16.CFG`     | ZCNFG configuration file for FILEATTR.COM              |
| `FA16.DOC`     | Documentation for FILEATTR.COM                         |
| `FA16A.FOR`    | Summary Information for FILEATTR.COM                   |
| `FA16CFG.TXT`  | describes configuration options for FILEATTR.COM       |
| `FILEATTR.COM` | Set and/or display file attributes                     |
| `FILEDATE.COM` | Date/time stamping aware disk directory utility        |
| `FILEDATE.CFG` | ZCNFG configuration fie for FILEDATE                   |
| `INITDIR.COM`  | Prepare disk for P2DOS date/time stamping              |
| `INITDIR.CFG`  | ZCNFG configuration file for INITDIR                   |
| `LDDS.COM`     | Load DateStamper date/time stamping resident extension |
| `LDNZT.COM`    | Load NZT date/time stamping resident extension         |
| `LDP2D.COM`    | Load P2DOS date/time stamping resident extension       |
| `PUTBG.COM`    | Updated replacement for BackGrounder II PUTBG program  |
| `PUTDS.COM`    | Prepare disk for datestamper date/time stamping        |
| `RELOG.COM`    | Clear fixed disk login vector in ZSDOS                 |
| `SETTERM.COM`  | Terminal configuration utility for DATSWEEP & DSCONFIG |
| `SETUPZST.COM` | Creates date/time stamping resident extensions         |
| `STAMPS.DAT`   | Library of date/time stamping modules for SETUPZST     |
| `TD.COM`       | Read and set system real-time clock                    |
| `TD.CFG`       | ZCNFG Configuration file for TD.COM                    |
| `TERMBASE.DAT` | Library of terminals used by SETTERM                   |
| `TESTCLOK.COM` | Test a selected clock driver                           |
| `ZCAL.COM`     | Display a small one-month calendar to the screen       |
| `ZPATH.COM`    | Set or display ZSDOS and ZCPR search paths             |
| `ZSCONFIG.COM` | Configure features of ZSDOS operating systems          |
| `ZSVSTAMP.COM` | Preserves file date/time stamp across modifications    |
| `ZSVSTAMP.DOC` | Document describes the use and operation of ZSVSTAMP   |

**NOTE:** The above files are also included in the NZ-COM disk image distribution

### Additional Files

|     | **Documentation**                  | **User Area** |
|-----|------------------------------------|---------------|
|     | [CP/M 2.2 Files]                   | 0             |
|     | [OS General Files]                 | 0             |
|     | [General Purpose Applications]     | 0             |
|     | [Testing Applications]             | 2             |
|     | [Sample Audio Files]               | 3             |
|     | [SIMH Simulator]                   | 13            |

`\clearpage`{=latex}

## NZCOM

This disk contains NZ-COM, which is an implementation of the
Z-System.  You may also see NZ-COM referred to as ZCPR 3.4.  This is
a powerful replacement for CP/M 2.2 w/ full backward compatibility.
NZ-COM is extremely configurable and far more powerful than
DRI CP/M.  It is almost mandatory that you read the NZ-COM manual to
use the system effectively.

| Floppy Disk Image: **fd_nzcom.img**
| Hard Disk Image: **hd_nzcom.img**
| Combo Disk Image: **Slice 2**

### NZ-COM OS Files

NZ-COM is not designed to load directly from the boot tracks of a
disk.  Instead, it expects to be loaded from an already running OS.  

This disk has been configured to boot using ZSDOS with a PROFILE.SUB 
command file that automatically loads NZ-COM. So, NZ-COM will load completely 
without any intervention, but you may notice that ZSDOS loads first, 
then ZSDOS loads NZ-COM.

The following files appear in User Area 0

| **File**       | **Source** | **Description**                                    |
|----------------|------------|----------------------------------------------------|
| `!(C)1988`     | NZCOM      | Original copyright (since placed in public domain) |
| `!NZ-COM`      | NZCOM      | Software marker directory entry (empty file)       |
| `!VERS--1.2H`  | NZCOM      | Version marker directory entry (empty file)        |
| `NZCOM.COM`    | NZCOM      | Loads and launches NZ-COM system                   |
| `NZCOM.ENV`    | RomWBW     | Z-System environment descriptor                    |
| `NZCOM.LBR`    | NZCOM      | Library of NZCOM system modules                    |
| `NZCOM.ZCM`    | RomWBW     | Environment descriptor (alternate format)          |
| `NZCPR.LBR`    | NZCOM      | Library of alternative ZCPR modules                |
| `PROFILE.SUB`  | RomWBW     | Command file to auto-start NZ-COM at system boot   |
| `RCP.LBR`      | NZCOM      | Library of alternative RCP modules                 |
| `STARTZCM.COM` | RomWBW     | Commands to execute after NZ-COM is launched       |
| `ZRDOS.ZRL`    | ZRDOS      | Relocatable version of ZRDOS BDOS module           |
| `ZSDOS.ZRL`    | ZSDOS      | Relocatable version of ZSDOS 1.1 BDOS module       |
| `ZSYS.SYS`     | RomWBW     | ZSDOS Boot Image for SYSCOPY                       |

### NZ-COM Files

The following files came from the official NZ-COM distribution.  These
are generally documented in the "NZCOM Users Manual.pdf" document in
the Doc/CPM directory of the RomWBW distribution.

NOTE: It may appear theat there are not many files, this is because most of the OS
files are shared with Z3PLUS. See here for a list [NZ-COM Z3PLUS OS Files]

The following file are in User Area 15, and where noted 
10 for help files, or 14 for config files.  

| **File**       | **Description**                                          |
|----------------|----------------------------------------------------------|
| `ALIAS.CMD`    | Sample alias definitions for use with ARUNZ              |
| `BGZRDS19.LBR` | Patch for Backgrounder II (U10)                          |
| `CMDRUN.COM`   | Extended Command Processor (copied from ARUNZ)           |
| `MKZCM.COM`    | Create/update NZ-COM load environment                    |
| `NZBLITZ.COM`  | Rapid coldboot of complete NZ-COM system image           |
| `NZBLTZ14.CFG` | ZCNFG configuration file for NZBLITZ. (U14)              |
| `NZBLTZ14.HZP` | Help file for NZBLITZ (U10)                              |
| `NZ-DBASE.INF` | dBase II application note regarding SUBMIT files (U10)   |
| `PUBLIC.COM`   | Specify ZRDOS public directories/user areas              |
| `RELEASE.NOT`  | Update information on NZ-COM (U10)                       |
| `SUB.COM`      | Enhanced version of SUBMIT                               |

### Additional Files

|     | **Documentation**              | **User Area** |
|-----|--------------------------------|---------------|
|     | [Testing Applications]         | 2             |
|     | [Sample Audio Files]           | 3             |
|     | [CP/NET 1.2]                   | 4             |
|     | [SIMH Simulator]               | 13            |
|     | [CP/M 2.2 Files]               | 15            |
|     | [ZSDOS 1.1 Files]              | 15, 14, 10    |
|     | [NZ-COM Z3PLUS OS Files]       | 15, 14, 10    |
|     | [OS General Files]             | 15, 14, 10    |
|     | [General Purpose Applications] | 15, 10        |

`\clearpage`{=latex}

## CP/M 3

A vanilla distribution of DRI's CP/M 3, also known as CP/M Plus adapted for RomWBW.

| Floppy Disk Image: **fd_cpm3.img**
| Hard Disk Image: **hd_cpm3.img**
| Combo Disk Image: **Slice 3**

### CP/M 3 OS Files

The following files appear in User Area 0

| **File**       | **Source** | **Description**                                    |
|----------------|------------|----------------------------------------------------|
| `BDOS3.SPR`    | CPM3       | DRI CPM+ GENCPM input file for the non-banked BDOS |
| `BIOS3.SPR`    | RomWBW     | DRI CPM+ GENCPM input file for non-banked BIOS     |
| `BNKBIOS3.SPR` | RomWBW     | DRI CPM+ GENCPM input file for banked BIOS         |
| `BNKBDOS3.SPR` | CPM3       | DRI CPM+ GENCPM input file for banked BDOS         |
| `CCP.COM`      | CPM3       | DRI CPM+ Console Command Processor                 |
| `CPM3.SYS`     | RomWBW     | DRI CPM+ (non-banked) memory image                 |
| `CPM3RES.SYS`  | RomWBW     | DRI CPM+ (non-banked) memory image                 |
| `CPM3BNK.SYS`  | RomWBW     | DRI CPM+ (banked) memory image                     |
| `CPM3FIX.PAT`  | CPM3       | DRI CPM+ patch list                                |
| `CPMLDR.COM`   | RomWBW     | DRI CPM 3.0 Boot Loader Application                |
| `CPMLDR.SYS`   | RomWBW     | DRI CPM 3.0 Boot Loader for SYSCOPY                |
| `GENBNK.DAT`   | RomWBW     | GENCPM config data file (banked)                   |
| `GENRES.DAT`   | RomWBW     | GENCPM config data file (non-banked)               |
| `GENCPM.DAT`   | RomWBW     | Current GENCPM config data file                    |
| `GENCPM.COM`   | CPM3       | DRI CPM+ Create a memory image of CPM3.SYS         |
| `RESBDOS3.SPR` | CPM3       | DRI CPM+ GENCPM input file for resident BDOS       |

### CP/M 3 Files

The following CP/M 3 files were distributed by DRI with the operating
system or as supplemental add-on programs.  They are documented in the
"CPM3 Command Summary.pdf" document in the Doc/CPM directory of the Rom WBW
distribution. 

The following files appear in User Area 0

| **File**      | **Description**                                                        |
|---------------|------------------------------------------------------------------------|
| `DATE.COM`    | DRI CPM+ Set or display the date and time                              |
| `DEVICE.COM`  | DRI CPM+ Assign logical devices with one or more physical devices      |
| `DIR.COM`     | DRI CPM+ DIR with options                                              |
| `DUMP.COM`    | DRI type contents of disk file in hex                                  |
| `ED.COM`      | DRI CPM+ line editor                                                   |
| `ERASE.COM`   | DRI CPM+ file deletion                                                 |
| `GENCOM.COM`  | DRI CPM+ Generate special COM file with attached RSX files             |
| `GET.COM`     | DRI CPM+ Temporarily get console input form a disk file                |
| `HELP.COM`    | DRI CPM+ Display information on how to use commands                    |
| `HELP.HLP`    | DRI CPM+ Databse of help information for HELP.COM                      |
| `HEXCOM.COM`  | DRI CPM+ Create a COM file from a hex file (replaces LOAD.COM)         |
| `INITDIR.COM` | DRI CPM+ Initializes a disk to allow time and date stamping            |
| `LIB.COM`     | DRI object file library manager                                        |
| `LINK.COM`    | DRI object file linker                                                 |
| `MAC.COM`     | DRI 8080 macro assembler                                               |
| `PATCH.COM`   | DRI CPM+ Display or install patch to the CPM+ system or command files  |
| `PIP.COM`     | DRI CPM+ Periperal Interchange Program                                 |
| `PUT.COM`     | DIR CPM+ Temporarily redirect printer or console output to a disk file |
| `RENAME.COM`  | DRI CPM+ Rename a file                                                 |
| `RMAC.COM`    | DRI 8080 relocating macro assembler                                    |
| `SAVE.COM`    | DRI CPM+ Copy the contents of memory to a file                         |
| `SET.COM`     | DIR CPM+ Set file options                                              |
| `SETDEF.COM`  | DIR CPM+ Set system options including the drive search chain           |
| `SHOW.COM`    | DIR CPM+ Display disk and drive statistics                             |
| `SUBMIT.COM`  | DRI CPM+ batch processor                                               |
| `TYPE.COM`    | DRI CPM+ Display the contents of an ASCII character file               |
| `XREF.COM`    | DRI assembler cross reference listing utility                          |
| `ZSID.COM`    | DRI Z80 symbolic instruction debugger                                  |                                                                    |

**NOTE:** The above files are also included in the ZPM3 and Z3PLUS disk images.

ZSID is a supplemental program from DRI
with separate standalone documentation which is not included in the
RomWBW package (but easily found on the Internet via Google search).

### Additional Files

|     | **Documentation**                  | **User Area** |
|-----|------------------------------------|---------------|
|     | [OS General Files]                 | 0             |
|     | [General Purpose Applications]     | 0             |
|     | [Testing Applications]             | 2             |
|     | [Sample Audio Files]               | 3             |
|     | [CP/NET 1.2]                       | 4             |
|     | [SIMH Simulator]                   | 13            |

`\clearpage`{=latex}

## Z3PLUS

### Z3PLUS OS Files

Z3PLUS is not designed to load directly from the boot tracks of a
disk.  Instead, it expects to be loaded from an already running OS.

This disk has been configured to boot using CP/M 3 with a PROFILE.SUB
command file that automatically loads Z3PLUS. So, Z3PLUS will load completely
without any intervention, but you may notice that CP/M 3 loads first.

The following Z3PLUS files appear in User Area 0

| **File**       | **Source**  | **Description**                                    |
|----------------|-------------|----------------------------------------------------|
| `!(C)1988`     | Z3PLUS      | Original copyright (since placed in public domain) |
| `!VERS--1.02F` | Z3PLUS      | Version marker directory entry (empty file)        |
| `!Z3PLUS`      | Z3PLUS      | Software marker directory entry (empty file)       |
| `NAMES.NDR`    | RomWBW      | Default Directory Names loaded at boot             |
| `RCP.LBR`      | Z3PLUS      | Library of alternative RCP modules                 |
| `PROFILE.SUB`  | RomWBW      | Command file to auto-start Z3PLUS at system boot   |
| `STARTZ3P.COM` | RomWBW      | Commands to execute after Z3PLUS is launched       |
| `Z3PLUS.COM`   | Z3PLUS      | Loads and launches Z3PLUS system                   |
| `Z3PLUS.LBR`   | Z3PLUS      | Library of Z3PLUS system modules                   |

### Z3PLUS Files

The following files came from the official Z3PLUS distribution.  These
are generally documented in the "Z3PLUS Users Manual.pdf" document in
the Doc/CPM directory of the RomWBW distribution. Note:  

NOTE: It may appear theat there are not many files, this is because most of the OS
files are shared with NZCOM. See here for a list [NZ-COM Z3PLUS OS Files]

The following file are in User Area 15, and where noted 10 for help files.

| **File**       | **Description**                             |
|----------------|---------------------------------------------|
| `ALIAS.CMD`    | Sample alias definitions for use with ARUNZ |
| `PATCHSK.SUB`  | Patch smartkey II v. 1.0A (U10)             |
| `PATCH4SK.HEX` | Patch smartkey II v. 1.0A - Hex File (U10)  |
| `RELEASE.NOT`  | Update information on Z3PLUS (U10)          |

### Additional Files

|     | **Documentation**              | **User Area** |
|-----|--------------------------------|---------------|
|     | [Testing Applications]         | 2             |
|     | [Sample Audio Files]           | 3             |
|     | [CP/NET 1.2]                   | 4             |
|     | [SIMH Simulator]               | 13            |
|     | [CP/M 3 Files]                 | 15            |
|     | [NZ-COM Z3PLUS OS Files]       | 15, 14, 10    |
|     | [OS General Files]             | 15, 14, 10    |
|     | [General Purpose Applications] | 15, 10        |

`\clearpage`{=latex}

## ZPM3

This is a generic ZPM3 adaptation for RomWBW.

| Floppy Disk Image: **fd_zpm3.img**
| Hard Disk Image: **hd_zpm3.img**
| Combo Disk Image: **Slice 4**

Per ZPM3 standard, files are distributed across different user areas
depending on their usage.  Normal applications are in user area 15.  Help
files in user area 10.  Configuration files in user area 14.

### ZPM3 OS Files

The following files appear in User Area 0

| **File**       | **Source** | **Description**                               |
|----------------| ---------- |-----------------------------------------------|
| `BNKBIOS3.SPR` | RomWBW     | Banked BIOS                                   |
| `BNKBDOS3.SPR` | ZPM3       | Banked BDOS                                   |
| `CPM3.SYS`     | RomWBW     | ZPM3 system file (See Note)                   |
| `GENCPM.DAT`   | RomWBW     | DRI CPM+ System generation tool data file     |
| `HELP.HLP`     | ZPM3       | System Help File                              |
| `MAKEDOS.COM`  | ZPM3       | Utility to overlay your system file with ZPM3 |
| `STARTZPM.COM` | RomWBW     | Commands to execute after ZPM is launched     |
| `RESBDOS3.SPR` | ZPM3       | Resident BDOS                                 |
| `ZCCP.COM`     | ZPM3       | ZCCP replacement for CCP.COM                  |
| `ZINSTAL.ZPM`  | ZPM3       | Segment containing environment information    |
| `ZPMLDR.COM`   | RomWBW     | ZPM3 Boot Loader Application                  |
| `ZPMLDR.SYS`   | RomWBW     | ZPM3 Boot Loader for SYSCOPY                  |

**NOTE:** Currently `GENCPM.COM` is located in User Area 15

**NOTE:** The ZPM3 system file is called CPM3.SYS. This is the ZPM3 
default configuration. It is done to maximize compatibility with CP/M 3. 

Either ZPMLDR or CPMLDR can be used to launch ZPM3. CPMLDR is equivalent to ZPMLDR.

The following files appear in User Area 15

| **File**      | **Source** | **Description** |
|---------------| ---------- |-----------------|
| `AUTOTOG.COM` | ZPM3       |                 |
| `CLRHIST.COM` | ZPM3       |                 |
| `SETZ3.COM`   | ZPM3       |                 |

### ZPM3 Files

This is a generic ZPM3 adaptation for RomWBW.

| **File**       | **User Area** | **Description**                                              |
|----------------|---------------|--------------------------------------------------------------|
| `ARUNZ.COM`    | 15            | Alias-RUN-forZ-System command alias exec (v1.1 Type3)        |
| `DEV.COM`      | 15            |                                                              |
| `DISKINFO.COM` | 15            | ZCPR utility which gives information about your disks.       |
| `DU.COM`       | 15            |                                                              |
| `ERASE.CFG`    | 14            |                                                              |
| `GENCPM.COM`   | 15            | DRI CPM3 Utility to Create a memory image of CPM3.SYS        |
| `GOTO.COM`     | 15            |                                                              |
| `HELPC15.CFG`  | 14            |                                                              |
| `IF.COM`       | 15            | Extended flow control tester for FCP (v1.6 Type 3)           |
| `IF.HLP`       | 10            |                                                              |
| `LOADSEG.COM`  | 15            | ZCCP Utility to Load RSXes, TCAPs and Named Directory files. |
| `MENU.HLP`     | 10            |                                                              |
| `NAMES.NDR`    | 15            | Default Directory Names loaded at boot                       |
| `REMOVE.COM`   | 15            |                                                              |
| `RSXDIR.COM`   | 15            | ZCPR Utility which displays RSXes in memory                  |
| `SETPATH.COM`  | 15            | used to set the command search path.                         |
| `VERROR.COM`   | 15            | Installs a resident error handler                            |
| `VLU.COM`      | 15            | Video Library Utility views or extracts files from libraries |
| `VLU.HLP`      | 10            |                                                              |
| `XREF.COM`     | 15            |                                                              |
| `ZERASE.COM`   | 15            |                                                              |
| `ZFHIST.HLP`   | 10            |                                                              |
| `ZFILER.COM`   | 15            | File management shell, with GUI.                             |
| `ZFILER.HLP`   | 10            | Help file for ZFILER.COM                                     |
| `ZF11.CFG`     | 14            |                                                              |
| `ZFMACRO.HLP`  | 10            |                                                              |
| `ZHELP.COM`    | 15            |                                                              |
| `ZSHOW.COM`    | 15            | displays amount of information about your Z-System           |

### Additional Files

|     | **Documentation**                  | **User Area** |
|-----|------------------------------------|---------------|
|     | [Testing Applications]             | 2             |
|     | [Sample Audio Files]               | 3             |
|     | [SIMH Simulator]                   | 13            |
|     | [CP/M 3 Files]                     | 15            |
|     | [OS General Files]                 | 15, 14, 10    |
|     | [General Purpose Applications]     | 15, 10        |

## QPM 2.7

The following files came from from Microcode Consulting. The official
distribution files can be found on the Microcode Consulting website at
<https://www.microcodeconsulting.com/z80/qpm.htm>.
Also included in this image are debugz, and linkz frm the same company.

This disk includes the standard DRI CP/M 2.2 files in addition to the
QP/M files.  QP/M generally assumes you already had DRI CP/M 2.2
prior to adding QP/M features.

### QPM 2.7 OS Files

These are built and provide the OS.
QPM Typically has no boot files stored on the disk.
It entirely boots from the system track

The following files appear in User Area 0

| **File**   | **Description**                                            |
|------------|------------------------------------------------------------|
| `QPM.SYS`  | RomWBW configured QP/M system image (for use with SYSCOPY) |                                                        

The qpm.sys file and the QP/M image on the system
tracks was created using QINSTALL with default settings EXCEPT
for the two settings described under Notes (current drive/user
storage address and TIMDAT vector).

### QPM 2.7 Files

The following files appear in User Area 0

| **File**       | **Description**                                           |
|----------------|-----------------------------------------------------------|
| `D.COM`        | Directory lister                                          |
| `DBGINST.COM`  | Configures DEBUGZ debugger                                |
| `DEBUGZ.COM`   | Symbolic debugger for Z80                                 |
| `DEBUGZ.HLP`   | Symbolic debugger help file                               |
| `DHORIZ.COM`   | Version of directory lister for horizontal file sorting   |
| `HELLO.QPM`    | Text file with QP/M version information                   |
| `LZ.COM`       | Z80 Linking Loader                                        |
| `QBACKUP.COM`  | Data backup application                                   |
| `QINSTALL.COM` | QP/M installer / configurator                             |
| `QPATCH.COM`   | Patches (customizes) a few QP/M applications              |
| `QPIP.COM`     | QP/M enhanced version of CP/M 2.2 PIP application         |                                                          
| `QPMCLK.MAC`   | Example of QP/M clock assembler routine                   |
| `QPMCMDS.TXT`  | Brief summary of QP/M commands                            |
| `QPMUTILS.TXT` | Brief summary of QP/M utilities                           |
| `QSTAMP.COM`   | Initializes disk for date/time stamping                   |
| `QSTAMPV.COM`  | Initializes disk for date/time stamping (vertical sort)   |
| `QSTAMPX.COM`  | Initializes disk for date/time stamping (horizontal sort) |
| `QSTAT.COM`    | QP/M enhanced version of CP/M 2.2 STAT application        |
| `QSUB.COM`     | QP/M batch file submission program - Like SUBMIT          |
| `QSWEEP.COM`   | QP/M directory sweep utility                              |
| `QTERM.DAT`    | Terminal control codes used by DEBUGZ                     |
| `QTERMS.LIB`   | Library of available terminal definitions                 |
| `SETQTERM.COM` | Configures QTERM.DAT                                      |
| `TDCNFG.COM`   | Configures date/time directory display preferences        |

There are two text files (QPMCMDS.TXT and QPMUTILS.TXT) included.  
These files have escape sequences imbedded in them which makes them 
look a little strange depending on the terminal emulation you are using.

### Additional Files

|     | **Documentation**                  | **User Area** |
|-----|------------------------------------|---------------|
|     | [CP/M 2.2 Files]                   | 0             |
|     | [OS General Files]                | 0             |
|     | [General Purpose Applications]     | 0             |
|     | [Testing Applications]             | 2             |
|     | [Sample Audio Files]               | 3             |
|     | [SIMH Simulator]                   | 13            |

`\clearpage`{=latex}

# Common Disk Contents

## CP/NET 1.2

User area 4 contains a full implementation of the CP/NET 1.2 client 
provided by Doug Miller. Please refer to
<https://github.com/durgadas311/cpnet-z80> for more information, 
complete documentation and the latest source code.

Please refer to the RomWBW User Guide for instructions on installing
and using these these packages. Either the MT011 RCBus module or the
Duodyne Disk I/O board is required.  In general, to use CP/NET on RomWBW, 
it is intended that you will extract the appropriate set of files 
into your default directory in user area 0.

The following are found in

*  /Binary/CPNET

| **File**        | **CP/NET Version**  | **OS**          | **Hardware**            |
|-----------------|---------------------|-----------------|-------------------------|
| `CPN12MT.LBR`   | CP/NET 1.2          | CP/M 2.2        | RCBus w/ MT011          |
| `CPN3MT.LBR`    | CP/NET 3            | CP/M 3          | RCBus w/ MT011          |
| `CPN12DUO.LBR`  | CP/NET 1.2          | CP/M 2.2        | Duodyne w/ Disk I/O     |
| `CPN3DUO.LBR`   | CP/NET 3            | CP/M 3          | Duodyne w/ Disk I/O     |
| `CPN12SER.LBR`  | CP/NET 1.2          | CP/M 2.2        | RomWBW Serial Port      |
| `CPN3SER.LBR`   | CP/NET 3            | CP/M 3          | RomWBW Serial Port      |

## General Purpose Applications

The following files are general purpose an provided in (mostly) all OS images  

The following files are found in

* /Source/Apps/*
* /Source/Images/Common/All
* /Source/TastyBasic

The following files provide specific functionality enabled by
RomWBW enhancements.  These applications are typically documented in the
"RomWBW Applications.pdf" document in the Doc directory of the
RomWBW Distribution.

| **File**       | **Source**        | **Description**                                               |
|----------------|-------------------|---------------------------------------------------------------|
| `ASSIGN.COM`   | RomWBW            | Assign,remove,swap drive letters of RomWBW disk slices        |
| `CLRDIR.COM`   | Max Scane         | Initializes the directory area of a disk                      |  
| `COPYSL.COM`   | M.Pruden          | Copy CPM Hard Disk Slices                                     |  
| `COPYSL.DOC`   | M.Pruden          | Documentation for COPYSL.COM                                  |  
| `CPUSPD.COM`   | RomWBW            | CPU Speed                                                     |  
| `FAT.COM`      | RomWBW            | MS-DOS FAT filesystem tool (list, copy, delete, format, etc.) |  
| `FDISK80.COM`  | John Coffman      | Hard disk partitioning tool                                   |  
| `FDU.COM`      | RomWBW            | Floppy Disk Utility, Test and format floppy disks             |  
| `FDU.DOC`      | RomWBW            | Documentation for FDU                                         |  
| `FLASH.COM`    | Will Sowerbutts   | Program FLASH chips in-situ                                   |  
| `FLASH.DOC`    | Will Sowerbutts   | Documentation for FLASH                                       |  
| `FORMAT.COM`   | RomWBW            | Placeholder application with formatting instructions          |  
| `HTALK.COM`    | Tom Plano         | Terminal utility talking directly to HBIOS Character Units    |  
| `MODE.COM`     | RomWBW            | Change serial line characteristics (baud rate, etc.)          |  
| `REBOOT.COM`   | MartinR           | Cold or Warm Boot the RomWBW System                           |  
| `RTC.COM`      | Andrew Lynch      | Test real time clock hardware on your system                  |  
| `SURVEY.COM`   | RomWBW            | Display system resources summary                              |  
| `SYSCOPY.COM`  | RomWBW            | Copy system tracks to disks (make bootable)                   |  
| `TALK.COM`     | RomWBW            | Route console I/O to & from specified serial port             |  
| `TIMER.COM`    | RomWBW            | Test and display system timer ticks                           |  
| `TUNE.COM`     | RomWBW            | Play .PT2, .PT3, and .MYM audio files on supported hardware   |  
| `VGMPLAY.COM`  |                   | Simple player for VGM (Video Game Music) files.               |
| `WDATE.COM`    | Kevin Boone       | Utility to configure RTC Date.                                |  
| `XM.COM`       | RomWBW            | XModem file transfer application                              |  

Then we have some more general purpose applications.
In general, there is no documentation for these applications included with the RomWBW
distribution.  Some provide command line help themselves.  Some are fairly obvious.

| **File**       | **Source**        | **Description**                                        |
|----------------|-------------------|--------------------------------------------------------|
| `BBCBASIC.COM` | R.T.Russell       | BBC BASIC CP/M Version                                 |
| `BBCBASIC.TXT` | R.T.Russell       | Help file for BBC BASIC                                |
| `COMPARE.COM`  |                   | Compare content of two files (binary)                  |                                                                 
| `CRUNCH.COM`   |                   | Compress file(s) using Crunch algorithmn               |                                            
| `CRUNCH28.CFG` |                   | ZCNFG configuration file for CRUNCH & UNCR             |                                            
| `DDTZ.COM`     |                   | Z80 debug tool (modified to use RST 6)                 |                                             
| `DDTZ.DOC`     |                   | Documentation for DDTZ                                 |  
| `EX.COM`       |                   | Batch file processor (alternative to DRI SUBMIT)       |  
| `FIND.COM`     | Jay Cotton        | Search all drives for a file ()                        |  
| `GENHEX.COM`   |                   | Generates an Intel Hex file from the input file        |  
| `LS.COM`       |                   | An alternative file listing to DIR                     |  
| `LSWEEP.COM`   |                   | Extract and view member files of an .LBR archive       |  
| `MBASIC.COM`   | Microsoft         | Microsoft BASIC language interpreter                   |  
| `NULU.COM`     |                   | NZCOM new library utility (.LBR) management tool       |  
| `PMARC.COM`    |                   | Create or add file(s) to LHA .PMA archive              |  
| `PMEXT.COM`    |                   | Extract file(s) from .PMA/.LZH/.LHA archive            |  
| `RMXSUB1.COM`  | Lars Nelson       | Remove XSUB1 RSX from memory                           |  
| `SUPERSUB.COM` |                   | Enhanced replacement for DRI SUBMIT                    |  
| `SUPERSUB.DOC` |                   | Documentation for SUPERSUB                             |  
| `SYSGEN.COM`   | DRI               | Copy system tracks to disks                            |  
| `TBASIC.COM`   | Dimitri Theulings | Tasty Basic. This also exists as a Rom appication      |
| `TDLBASIC.COM` |                   | TDL Zapple 12K BASIC language interpreter              |
| `TE.COM`       | Ladislau Szilagyi | RomWBW enhanced version of TE editor                   |  
| `TE.DOC`       | Ladislau Szilagyi | TE Editor Documentation                                |  
| `UNARC.COM`    |                   | Extract file(s) from .ARC or .ARK archive              |  
| `UNARC.DOC`    |                   | Documentation for UNARC                                |  
| `UNCR.COM`     |                   | Decompress Crunched file(s). See CRUNCH.COM            |  
| `UNZIP.COM`    | Lars Nelson       | UNZIP extracts from MS-DOS ZIP files                   |  
| `UNZIP.DOC`    |                   | Documentation for UNZIP                                |  
| `XSUB1.COM`    | Lars Nelson       | Replacement for DRI XSUB                               |  
| `ZAP.COM`      |                   | Interactive disk & file utility                        |  
| `ZDE.COM`      |                   | Compact WordStar-like editor                           |  
| `ZDE.DOC`      |                   | ZDE Documentation                                      |  
| `ZDENST.COM`   |                   | Installation/configuration tool for ZDE                |  
| `ZMRX.COM`     |                   |                                                        |  
| `ZMTX.COM`     |                   |                                                        |  
| `ZMD.COM`      | R.W.K             | Z80 RCP/M File Transfer Program (Robert W. Kramer III) |
| `ZMP.COM `     |                   | ZModem communications program (dedicated port)         |  
| `ZMP.DOC`      |                   | Documentation for ZMP                                  |  
| `ZMP.HLP`      |                   | Help file for ZMP                                      |  
| `ZMXFER.OVR`   |                   | Overlay file for ZMP                                   |  
| `ZMTERM.OVR`   |                   | Overlay file for ZMP                                   |  
| `ZMINIT.OVR`   |                   | Overlay file for ZMP                                   |  
| `ZMCONFIG.OVR` |                   | Overlay file for ZMP                                   |  

## OS General Files

The following files are spcific files share across several OS's.  
In general, there is no documentation for these applications included with 
the RomWBW distribution.  Some provide command line help themselves.  
Some are fairly obvious.

The following files are found in

*  /Source/Images/Common/CPM22 
*  /Source/Images/Common/CPM3 
*  /Source/Images/Common/Z
*  /Source/Images/Common/Z3

| **File**       | **Applicability** | **Description**                                       |
|----------------|-------------------|-------------------------------------------------------|
| `ALIAS.COM`    | Z3                | Create an Alias (v1.1)                                |
| `ALIAS.HLP`    | Z3                | Help File for ALIAS.COM                               |
| `COPY.COM`     | Z                 | File copier with ZSDOS date stamping awareness        |
| `COPY.CFG`     | Z                 | ZCNFG configuration file for COPY application         |
| `EDITNDR.COM`  | Z3                | Edit named directory register in memory.              |
| `HP-RPN.HLP`   | Z3                | Help File for ZP.COM - HP RPN Calculators             |
| `HP-ZP.HLP`    | Z3                | Help File for ZP.COM - HP ZP Calculators              |
| `KERCPM22.COM` | CPM22             | Kermit communication application                      |
| `KERCPM3.COM`  | CPM3              | Kermit communication application                      |
| `LBREXT.COM`   | Z                 | Extract file from .LBR libraries                      |
| `LBREX36.CFG`  | Z                 | ZCNFG configuration file for LBREXT                   |
| `RZ.COM`       | CPM3              | Receive files with X/Y/ZModem (experimental)          |
| `RZSC.FOR`     | CPM3              | Description of RZ/SZ programs                         |
| `SAINST.COM`   | Z3                | Install/configure SALIAS.                             |
| `SALIAS.COM`   | Z3                | Screen oriented alias editor. (v1.6)                  |
| `SAVENDR.COM`  | Z3                | Writes the named directory to disk.                   |
| `SDZ.COM`      | Z3                | Enhanced directory lister.                            |
| `SCOPY.COM`    | Z3                | Screen-oriented file copy for ZCPR3                   |  
| `SCOPY10.CFG`  | Z3                | ZCNFG configuration file for SCOPY                    |  
| `SCOPY.HLP`    | Z3                | Primary help file for SCOPY                           |  
| `SCOPY10F.HLP` | Z3                | Secondary help file for SCOPY                         |  
| `SZ.COM`       | CPM3              | Send files with X/Y/ZModem (experimental)             |
| `TCAP.Z3T`     | Z3                | Terminal capabilities for ZCPR3 (VT100)               |  
| `TCSELECT.COM` | Z3                | NZCOM Create terminal capability file (newer version) |
| `TCVIEW.COM`   | Z3                | View zcpr3 terminal capabilities                      |  
| `UMAP.COM`     | Z3                | Shows directory usage                                 |  
| `UMAP18.CFG`   | Z3                | ZCNFG configuration file for UMAP program             |  
| `UNARCU1.CFG`  | Z                 | ZCNFG configuration file for UNARC program            |
| `ZCNFG.COM`    | Z                 | Configuration tool for programs with .CFG files       |
| `ZCNFG24.CFG`  | Z                 | Configuration file for ZCNFG.COM                      |
| `ZEX.COM`      | Z3                | A memory-based command file processor, like SUBMIT    |
| `ZEX.CFG`      | Z3                | ZCNFG configuration file for ZEX program              |
| `ZP.COM`       | Z3                | Screen-oriented file/disk/memory record patcher (ZAP) |
| `ZP.HLP`       | Z3                | Help File for ZP.COM                                  |
| `ZP17.CFG`     | Z3                | Configuration file for ZP.COM                         |
| `ZXD.CFG`      | Z                 | Configuration file for ZXD.COM                        |
| `ZXD.COM`      | Z                 | Extended directory utility w/ date/time stamp support |
| `Z3LOC.COM`    | Z3                | Display info of the ZCPR3 CCP, BDOS, and BIOS         |  
| `Z3TCAP.LBR`   | Z3                | Database of terminal descriptions                     |  

Applicability:

* CPM22 - Included in all CP/M 2.2 OS's (CPM2.2, ZSDOS, NZ-COM, QPM)
* CPM3 - Included in all CP/M 3 OS's (CPM3, Z3PLUS, ZPM3)
* Z - Included in All Z OS's (ZSDOS, NZ-COM, Z3PLUS, ZPM3)
* Z3 - Included in ZCPR3 OS's (NZ-COM, Z3PLUS, ZPM3)

## NZ-COM Z3PLUS OS Files

The following files are specific files share across two operating systems.

* NZ-COM - The Automatic Z-System - Alpha Systems
* Z3PLUS - The Z-System for CP/M-Plus - Plu*Perfect Systems

These 2 operating systems are identical in all respects, except for the underlying
operating system that they run on. 

The following files are found in

* /Source/Images/Common/NZ3PLUS

The following file are in User Area 15, and where noted 14 for config files.

| **File**       | **Description**                                          |
|----------------|----------------------------------------------------------|
| `ARUNZ.COM`    | Alias-RUN-forZ-System command alias exec (v0.9u Type4)   |
| `CLEDINST.COM` | Command line editing and history shell installer         |
| `CLEDSAVE.COM` | Save RCP-resident command line editor history            |
| `CONFIG.LBR`   | Various configuration files for use with ZCNFG. (U14)    |
| `CPSET.COM`    | Displays/defines CRT/PRT characteristics                 |
| `FCP.LBR`      | Library of alternative FCP modules                       |
| `FF.COM`       | File finder utility                                      |
| `IF.COM`       | Extended flow control tester for FCP (v1.5 Type4)        |
| `JETLDR.COM`   | Z-System General-purpose module loader                   |
| `LBRHELP.COM`  | Help file viewer for use with help file libraries (.LBR) |
| `LDIR.COM`     | Directory lister for libraries (.LBR)                    |
| `LPUT.COM`     | Puts file(s) into a library (.LBR)                       |
| `LSH.COM`      | Command history shell and command line editor            |
| `LSH-HELP.COM` | Display LSH help when LSH is running                     |
| `LSHINST.COM`  | LSH configuration editor                                 |
| `LX.COM`       | Execute programs directly from a library (.LBR)          |
| `NAME.COM`     | Quickly add or remove a name for a single directory      |
| `PATH.COM`     | Set/display command search path                          |
| `PWD.COM`      | Displays DU and Directory Names with paging              |
| `TY3ERA.COM`   | Type-3 program to erase a file                           |
| `TY3REN.COM`   | Type-3 program to rename a file                          |
| `TY4ERA.COM`   | Type-4 program to erase a file                           |
| `TY4REN.COM`   | Type-4 program to rename a file                          |
| `TY4SAVE.COM`  | Type-4 program to save memory to a file                  |
| `TY4SP.COM`    | Type-4 program to display disk space                     |
| `VIEW.COM`     | Quad directional file viewer                             |
| `XTCAP.COM`    | Interactive Extended TCAP Installer                      |
| `ZERR.COM`     | Z34 Error Handler                                        |
| `ZF-DIM.COM`   | ZFILER shell for dim-video terminals                     |
| `ZF-REV.COM`   | ZFILER shell for reverse-video terminals                 |
| `ZFILER.CMD`   | Macro script file for ZFILER                             |
| `ZHELP.COM`    | (HELPC14) is an improved version of the help utility     |
| `ZLT.COM`      | File lister with support for compressed files            |
| `ZSHOW.COM`    | Display Z-System configuration information               |

The following documentation files are in User Area 10

| **File**       | **Description**                                         |
|----------------|---------------------------------------------------------|
| `DOCFILES.LBR` | Documentation and help files collected into an LBR file |
| `HLPFILES.LBR` | Various app help files for use with LBRHELP             |
| `LSH.WZ`       | User manual for LSH                                     |
| `TCJ.INF`      | Subscription information for The Computer Journal       |
| `TCJ*.WZ`      | Selected articles from The Computer Journal             |
| `ZFILEB38.LZT` | Brief listing of Z-System support programs              |
| `ZHELPERS.LZT` | List of volunteers who will help installing Z-System    |
| `ZNODES66.LZT` | List of Z-Node remote access systems                    |
| `ZSYSTEM.IZF`  | Information on Z-System and related products            |

## Sample Audio Files

User area 3 contains sample audio files that can be played using
the TUNE or VGMPLAY applications. 

**NOTE** These files are NOT present on floppy disk images

The following files are found in

*  /Binary/Apps/Tunes

| **File**          | **File**          | **File**         | **File**       |
|-------------------|-------------------|------------------|----------------|
| `ATTACK.PT3`      | `DEMO4.MYM`       | `NAMIDA.PT3`     | `VICTORY.PT3`  |
| `BACKUP.PT3`      | `ENDING.VGM`      | `RECOLL.PT3`     | `WICKED.PT3`   |
| `BADMICE.PT3`     | `HOWRU.PT3`       | `SANXION.PT3`    | `WONDER01.VGM` |
| `DEMO.MYM`        | `INCHINA.VGM`     | `SHIRAKAW.VGM`   | `YEOLDE.PT3`   |
| `DEMO1.MYM`       | `ITERATN.PT3`     | `STARTDEM.VGM`   | `YEOVIL.PT3`   |
| `DEMO3.MYM`       | `LOOKBACK.PT3`    | `SYNCH.PT3`      |                |
| `DEMO3MIX.MYM`    | `LOUBOUTN.PT3`    | `TOSTAR.PT3`     |                |

## SIMH Simulator

Files for use with the SIMH Simulator

The following files are found in

*  /Source/Images/Common/SIMH

| **File**       | **Description**                                           |
|----------------|-----------------------------------------------------------|
| `HDIR.COM`     |                                                           |
| `R.COM`        | transfer files between the simulator and host file system |
| `RSETSIMH.COM` | --                                                        |
| `TIMER.COM`    | --                                                        |
| `URL.COM`      | --                                                        |
| `W.COM`        | transfer files between the simulator and host file system |

## Testing Applications

User area 2 contains a variety of hardware testing applications.
These are generally user contributed and have no documentation.

These applications are frequently not compatible with all RomWBW
hardware.  They are included here as a convenience.  If applicable,
your hardware documentation should refer to them and provide usage
instructions.

**NOTE** These files are NOT present on floppy disk images

The following files are found in

* /Binary/Apps/Test
* /Source/Images/Common/Test

| **File**            | **Description**                                         |
|---------------------|---------------------------------------------------------|
| `2PIOTST.COM`       | ECB-ZILOG PERIPHERALS BOARD TEST 2 PIO's                |
| `AY-TEST.COM`       | AY-3-8910 Sound Test Program (SOUND)                    |
| `BANKTEST.COM`      | Test RomWBW bank management API                         |
| `DMAMON.COM`        | Verify operation of the Z80 MBC DMA board               |
| `I2CLCD.COM`        | PCF8584 HD44780  I2C LCD UTILITY                        |
| `I2CSCAN.COM`       | I2C BUS SCANNER                                         |
| `INTTEST.COM`       | Test HBIOS interrupt API functions                      |
| `KBDTEST.COM`       | test program to work with the Z80 KBDMSE board          |
| `PIOMON.COM`        | Zilog PIO Monitor & Hardware Testing Application        |
| `PORTSCAN.COM`      | Reads all ports and displays values read                |
| `PPIDETST.COM`      | PPI IDE test for checkout of all 8255 IDE drives        |
| `PS2INFO.COM`       | PS/2 Keyboard/Mouse Information Utility                 |
| `RAMTEST.COM`       | RAM_TEST_PROGRAM                                        |
| `RTCDS7.COM`        | PCF8584/DS1307 I2C DATE AND TIME UTILITY (I2C)          |
| `RZ.COM`            | Receive Zmodem disassembly of CP/M 3 binaries           |
| `SOUND.COM`         | RomWBW HBIOS Sound Device Test Tool (SOUND)             |
| `SROM.COM`          | I2C Serial ROM Read/Write Utility (I2C)                 |
| `SZ.COM`            | Send Zmodem is a disassembly of CP/M 3 binaries         |
| `TESTH8P.COM`       | H8 Panel Test                                           |
| `TSTDSKNG.COM`      | DSKY NEXT GENERATION TEST APPLICATION                   |
| `VDCONLY.COM`       | COLOR VDU TEST                                          |
| `VDCTEST.COM`       | COLOR VDU TEST                                          |
| `ZEXALL.COM`        | Z80 Instruction Set Exerciser                           |
| `ZEXDOC.COM`        | Z80 Instruction Set Exerciser                           |

And The following CPU Tests - Which are probably originally from this source. 
<https://github.com/raxoft/z80test>

| **File**       | **Description**                                               |
|----------------|---------------------------------------------------------------|
| `Z80CCF.COM`   | tests flags after executing CCF after each instruction.       |
| `Z80DOC.COM`   | tests registers, but only officially documented flags         |
| `Z80DOCF.COM`  |                                                               |
| `Z80FLAGS.COM` | tests flags, ignores registers.                               |
| `Z80FULL.COM`  | tests flags and registers                                     |
| `Z80MPTR.COM`  | tests flags after executing BIT N,(HL) after each instruction |

# Application Standalone Disks

## Aztec C Compiler

| Floppy Disk Image: **fd_aztecc.img**
| Hard Disk Image: **hd_aztecc.img**

Aztec C is a discontinued programming language for a variety of platforms
including MS-DOS, Apple II DOS 3.3 and PRoDOS, Commodore 64, Macintosh and
Amiga. This disk contains the CP/M version of that compiler. A cross-compiler
for MS-DOS or Windows XP is also available.

For full documentation, see <https://www.aztecmuseum.ca> 
The user manual is available in the Doc/Language directory
Aztec_C_1.06_User_Manual_Mar84.pdf

The following files are found in

*  /Source/Images/d_aztec

| **File** | **Description** |
|----------|-----------------|
| --       |       --        |

NOTE : The above is incomplete

## Microsoft Basic Compiler

| Floppy Disk Image: **fd_bascomp.img**
| Hard Disk Image: **hd_bascomp.img**

The Microsoft BASIC Compiler is a highly efficient programming tool that
converts BASIC programs from BASIC source code into machine code. This
provides much faster BASIC program execution than has previously been
possible. It can make programs run an average of 3 to 10 times faster than
programs run under BASIC-80. Compiled programs can be up to 30 times
faster than interpreted programs if maximum use of integer variables is
made.

View BASCOM.HLP included in the disk image using HELP.COM for documentation.

The following files are found in

*  /Source/Images/d_bascomp

| **File** | **Description** |
|----------|-----------------|
| --       |       --        |

NOTE : The above is incomplete

## Cowgol Compiler

| Floppy Disk Image: **fd_cowgol.img**
| Hard Disk Image: **hd_cowgol.img**

The Cowgol 2.0 compiler and related tools.
These files were provided by Ladislau Szilagyi and were sourced
from his GitHub repository at <https://github.com/Laci1953/Cowgol_on_CP_M>.

The primary distribution site for Cowgol 2.0 is at
<https://github.com/davidgiven/cowgol>.
The user manual is available in the Doc/Language directory
Cowgol Language.pdf.

The following files are found in

*  /Source/Images/d_cowgol

| **File**       | **Description**                            |
|----------------|--------------------------------------------|
| `$EXEC.COM`    | HiTech C batch processor which launches the Cowgol toolchain executables |
| `ADVENT.COW`   | Adventure game program source |
| `ADVENT.SUB`   | SUBMIT file to build Adventure game |
| `ADVENT?.TXT`  | Adventure game program resources |
| `ADVMAIN.COW`  | Adventure game program source |
| `ADVTRAV.COW`  | Adventure game component source |
| `ARGV.COH`     | Cowgol include file providing command line argument processing |
| `C.LIB`        | HI-TECH C runtime library |
| `CGEN.COM`     | HiTech C compiler pass 2 |
| `COMMFILE.COH` | Include file providing file I/O |
| `COMMON.COH`   | Include file providing common functions |
| `COWBE.COM`    | Cowgol back end which builds the cowgol object files (optimized) |
| `COWFE.COM`    | Cowgol front end which parses the source file (optimized) |
| `COWFIX.COM`   | Interface to Z80AS -- performs code optimizations |
| `COWGOL.COH`   | Include file providing standard Cowgol functions |
| `COWGOL.COM`   | Interprets the command line and generates $EXEC run requests (a variant of HiTech C.COM) |
| `COWGOL.COO`   | Cowgol object file with ??? |
| `COWGOL.LIB`   | ??? |
| `COWGOLC.COH`  | Cowgol include file providing ??? |
| `COWLINK.COM`  | Cowgol linker which binds all the cowgol object files and outputs a Z80 assembler file (optimized) |
| `CPP.COM`      | HiTech C pre-processor, modified to accept // style comments |
| `DYNMSORT.COW` | Sort algorithm sample program source |
| `DYNMSORT.SUB` | SUBMIT file to build DYNMSORT sample application |
| `FACT.COW`     | Factorial computation sample program source |
| `FILE.COH`     | Include file providing CP/M file processing support |
| `FILEIO.COH`   | Include file providing CP/M file processing support |
| `HEXDUMP.COW`  | Hex file dump sample  source |
| `HEXDUMP.SUB`  | SUBMIT file to build HEXDUMP sample program |
| `LIBBASIC.COH` | Include file providing ??? |
| `LIBBIOS.COH`  | Include file providing ??? |
| `LIBCONIO.COH` | Include file providing console I/O |
| `LIBFP.COH`    | Include file providing floating point support |
| `LIBR.COM`     | HiTech object file librarian |
| `LIBSTR.COH`   | Include file providing string functions |
| `LINK.COM`     | HiTech linker which builds the final executable from object and library files |
| `MALLOC.COH`   | Include file providing dynamic memory management functions |
| `MERGES.C`     | Merge sort sample function C language source |
| `MISC.COH`     | Include file providing miscellaneous functions |
| `MISC.COO`     | Miscellaneous functions object file |
| `MISC.COW`     | Miscellaneous functions source file |
| `OPTIM.COM`    | HiTech C compiler optimizer |
| `P1.COM`       | HiTech C compiler first pass |
| `RAND.AS`      | Pseudo-random number generator source in assembly language |
| `RANFILE.COH`  | Include file providing random file access functions |
| `RANFILE.COO`  | Random file access functions object file |
| `RANFILE.COW`  | Random file access functions source file |
| `README.TXT`   | Cowgol disk image release notes |
| `SEQFILE.COH`  | Include file providing sequential file access functions |
| `SEQFILE.COO`  | Sequential file access functions object file |
| `SEQFILE.COW`  | Sequential file access functions source file |
| `STDCOW.COH`   | Include file providing standard library functions |
| `STRING.COH`   | Include file providing string functions |
| `STRING.COO`   | String functions object file |
| `STRING.COW`   | String functions source file |
| `STRINGS.COH`  | Include file implementing string functions |
| `TESTAS.COW`   | Assembly language interface sample program source |
| `TESTAS.SUB`   | SUBMIT file to build TESTAS sample program |
| `Z80AS.COM`    | Z80 assembler which assembles the output of COWFIX and other Z80 source files (see <https://github.com/Laci1953/Z80AS>) |

## Microsoft Fortran 80

| Floppy Disk Image: **fd_fortran.img**
| Hard Disk Image: **hd_fortran.img**

This is Microsoft's implementation of the FORTRAN scientific-oriented high level
programming language. It was one of their early core languages developed for the
8-bit computers and later brought to the 8086 and IBM PC. In 1993 Microsoft
rebranded the product as Microsoft Fortran Powerstation. (Note: -80 refers to
the 8080/Z80 platform, not the language specification version)

The user manual is available in the Doc/Language directory,
Microsoft_FORTRAN-80_Users_Manual_1977.pdf

The following files are found in

*  /Source/Images/d_fortram

| **File** | **Description** |
|----------|-----------------|
| --       |       --        |

NOTE : The above is incomplete

## Games

| Floppy Disk Image: **fd_games.img**
| Hard Disk Image: **hd_games.img**

This disk contains several games for CP/M including the Infocom games
Zork 1 through 3, Planetfall and Hitchhiker's Guide to the Galaxy.

Nemesis and Dungeon Master is a Rogue-like game released in 1981. It is playable
on a text terminal using ASCII graphics to represent the dungeon. Only a few
thousand copies of the game were ever made, making it very rare. See
<http://crpgaddict.blogspot.com/2019/03/game-322-nemesis-1981.html>

Colossal Cave Adventure is a CP/M port of the 1976 classic game originally
written by Will Crowther for the PDP-10 mainframe. See
<https://en.wikipedia.org/wiki/Colossal_Cave_Adventure> and
<https://if50.substack.com/p/1976-adventure>

The following files are found in

*  /Source/Images/d_games

| **File** | **Description** |
|----------|-----------------|
| --       |       --        |

NOTE : The above is incomplete

## HI-TECH C Compiler

| Floppy Disk Image: **fd_hitechc.img**
| Hard Disk Image: **hd_hitechc.img**

The HI-TECH C Compiler is a set of software which
translates  programs written in the C language to executable
machine code programs. Versions are available which  compile
programs  for  operation under the host operating system, or
which produce programs for  execution  in  embedded  systems
without an operating system.

This is the Jun 2, 2025 update 19 released by Tony Nicholson who
currently maintains HI-TECH C at
<https://github.com/agn453/HI-TECH-Z80-C>.

The manual is available in the Doc/Language directory,
HI-TECH Z80 C Compiler Manual.txt.  A textual description of all error
and warning messages is found in the same directory, HI-TECH Z80 C
Compiler Messages.txt. 

A good blog post about the HI-TECH C Compiler is available at
<https://techtinkering.com/2008/10/22/installing-the-hi-tech-z80-c-compiler-for-cpm>.

User area 1 contains another complete copy of the HI-TECH C Compiler.
It is identical to the copy in user area 0 except for the following files
which were enhanced by Ladislau Szilagyi from his GitHub Repository at
<https://github.com/Laci1953/HiTech-C-compiler-enhanced>.  The files
take advantage of additional banked memory using the RomWBW HBIOS API.
As such, they require RomWBW to operate.  They should be compatible with
all CP/M and compatible operations systems provided in RomWBW.

The enhanced files are:

- `CGEN.COM`
- `CPP.COM`
- `OPTIM.COM`
- `P1.COM`
- `ZAS.COM`

A thread discussing this enhanced version of HI-TECH C is found at
<https://groups.google.com/g/rc2014-z80/c/sBCCIpOnnGg>.

The following files are found in

*  /Source/Images/d_hitechc

| **File**       | **Description**                            |
|----------------|--------------------------------------------|
| `$EXEC.COM`    | Compiler execution manager |
| `ASSERT.H`     | Language include file |
| `C.COM`        | Compiler invocation application (updated) |
| `C309.COM`     | Compiler invocation application (original) |
| `CGEN.COM`     | The code generator - produces assembler code |
| `CONIO.H`      | Language include file (see manual) |
| `CPM.H`        | Language include file (see manual) |
| `CPP.COM`      | Pre-processor - handles macros and conditional compilation |
| `CREF.COM`     | Produces cross-reference listings of C or assembler programs |
| `CRTCPM.OBJ`   | Startup Object File (standard) |
| `CTYPE.H`      | Language include file (see manual) |
| `DEBUG.COM`    | C Debugger (Z80) |
| `DRTCPM.OBJ`   | Startup Object File (???) |
| `EXEC.H`       | Language include file (see manual) |
| `FLOAT.H`      | Language include file (see manual) |
| `HITECH.H`     | Language include file (see manual) |
| `LIBC.LIB`     | Standard C Runtime Library |
| `LIBF.LIB`     | Floating Point Library |
| `LIBOVR.LIB`   | Overlay Library |
| `LIBR.COM`     | Creates and maintains libraries of object modules |
| `LIMITS.H`     | Language include file (see manual) |
| `LINQ.COM`     | Link editor - links object files with libraries |
| `MATH.H`       | Language include file (see manual) |
| `NRTCPM.OBJ`   | Startup Object File (minimal getargs) |
| `OBJTOHEX.COM` | Converts the output of LINK into the appropriate executable file format (e.g., .EXE or .PRG or .HEX) |
| `OPTIM.COM`    | Code improver - may optionally be omitted, reducing compilation  time at a cost of larger, slower code produced |
| `OPTIONS`      | Compiler usage help file |
| `OVERLAY.H`    | Language include file |
| `P1.COM`       | The syntax and  semantic analysis pass - writes intermediate code for the code generator to read |
| `RRTCPM.OBJ`   | Startup Object File (self relocating) |
| `SETJMP.H`     | Language include file (see manual) |
| `SIGNAL.H`     | Language include file (see manual) |
| `STAT.H`       | Language include file (see manual) |
| `STDARG.H`     | Language include file (see manual) |
| `STDDEF.H`     | Language include file (see manual) |
| `STDINT.H`     | Language include file (see manual) |
| `STDIO.H`      | Language include file (see manual) |
| `STDLIB.H`     | Language include file (see manual) |
| `STRING.H`     | Language include file (see manual) |
| `SYMTOAS.COM`  | Convert symbol file to assembler |
| `SYS.H`        | Language include file (see manual) |
| `TIME.H`       | Language include file (see manual) |
| `UNIXIO.H`     | Language include file (see manual) |
| `ZAS.COM`      | The assembler - in fact a general purpose macro  assembler |

## Infocom (Text Adventure Games)

| Hard Disk Image: **hd_infocom.img**

A collection of all Official releases of the interactive fiction games
produced by Infocom in the 1980's

The following files are found in

*  /Source/Images/d_infocom

| **File**    | **Description**                                    |
|-------------|----------------------------------------------------|
| amfv.z4     | A Mind Forever Voyaging (*)                        |
| arthur.z6   | Arthur - The Quest for Excalibur (*)               |
| ballyhoo.z3 | Ballyhoo                                           |
| beyond.z5   | Beyond Zork (*)                                    |
| border.z5   | Border Zone (*)                                    |
| bureau.z4   | Bureaucracy (*)                                    |
| cutthr.z3   | Cutthroats                                         |
| deadline.z3 | Deadline                                           |
| enchant.z3  | Enchanter                                          |
| h2g2.z3     | The Hitchhiker's Guide to the Galaxy               |
| hollyw.z3   | Hollywood Hijinx                                   |
| infidel.z3  | Infidel                                            |
| journey.z6  | Journey (*)                                        |
| leather.z3  | Leather Goddesses of Phobos                        |
| lurking.z3  | The Lurking Horror                                 |
| moonmist.z3 | Moonmist                                           |
| nordbert.z4 | Nord and Bert Couldn't Make Head or Tail of It (*) |
| planet.z3   | Planetfall                                         |
| plunder.z3  | Plundered Hearts                                   |
| readme.txt  | Additional Documentation                           |
| seastalk.z3 | Seastalker                                         |
| sherlock.z5 | Sherlock (*)                                       |
| shogun.z6   | Shogun (*)                                         |
| sorcerer.z3 | Sorcerer                                           |
| spellb.z3   | Spellbreaker                                       |
| starcros.z3 | Starcross                                          |
| stationf.z3 | Stationfall                                        |
| suspect.z3  | Suspect                                            |
| suspend.z3  | Suspended                                          |
| trinity.z4  | Trinity (*)                                        |
| wishb.z3    | Wishbringer                                        |
| witness.z3  | Witness                                            |
| zork0.z6    | Zork Zero (*)                                      |
| zork1.z3    | Zork I                                             |
| zork2.z3    | Zork II                                            |
| zork3.z3    | Zork III                                           |

The above games have been curated from here <https://eblong.com/infocom/>.
Full game documentation can be found here <https://infodoc.plover.net/>

The game files are a virtual machine code commonly known as Z-Machine, they
are portable and will run on any machine that has a Z-Machine interpreter.

* All the Z3 games come with the official CP/M interpreter (the `COM` file) 
  version C last updated by Inforcom on 5th Feb 1985. You can simply run the
  game by running it from the `COM` program  
* All latter games Z4, Z5,.. and above, (Marked as * in the listing above)
  are more sophisticated and require a better interpreter. i.e. VEZZA. 

#### VEZZA (User Area 15)

Vezza is a modern Infocom/Inform/Z-machine text adventure interpreter for 8 bit
z80 based computers.  What makes it modern is that it is written in hand-crafted
z80 assembler for maximum speed, and can load not only the classics such as
Zork 1,2 and 3 but also the later games.

It can run Z1 up to Z8 inform format interactive fiction game files. To run 
a game with Vezza just type Vezza followed by the game you want to run. e.g.

`VEZZA ZORK0.Z6`

**Note:** One of the bigger constraints is available RAM. An OS such as ZPM
since it uses banked RAM does have a good amount of available RAM and was 
used to test these games work.

This tool is free but the developer accepts your support by letting
you pay what you think is fair for the tool. If you find this useful
consider donating at: 

<https://sijnstra.itch.io/vezza>

You should (test and) choose one that works on you configuration,
and best to copy and rename it as vezza.com

| **File**     | **Description**                                                   |
|--------------|-------------------------------------------------------------------|
| vezza-B.com  | 80x24, VT52 + Banked CP/M 3                                       |
| vezza-FG.com | 80x25, VT100/ANSI (16 color) + CP/M 3                             |
| vezza-C2.com | 80x24, VT100 - CP/M 2.2 large memory, no timed input              |
| vezza-CC.com | 80x24, VT100 (256 colour) - CP/M 2.2 large memory, no timed input |
| vezza-AV.com | 80x24, VT100 (16 colour) - CP/M 2.2 high RAM.                     |
| vezza-AX.com | 80x25, VT100/ANSI (16 colour) - CP/M 2.2 high RAM.                |
| vezza-RW.com | 80x24, VT100 - CP/M 2.2                                           |

The above is a subset of available builds. The full repository including 
documentation is available at <https://gitlab.com/sijnstra1/vezza/>

## MSX ROMS

| Hard Disk Image: **hd_msxroms1.img**
| Hard Disk Image: **hd_msxroms2.img**

The collection of MSX ROMs (2 disks) as provided by Les Bird.  
These ROMs are "run" by using the
appropriate variant of Les' MSX8 ROM loader.  You can download the
loader binaries from <https://github.com/lesbird/MSX8>.  You will need
appropriate hardware to run the loader.

Please review the file ROMLIST.TXT for information on the current
operational status of the ROM and it's long file name/description.

This disk (RomWBW slice) is not automatically included with the
RomWBW "combo" disk images.  You can simply add it to a combo
image by appending it to the end.  After booting your system,
you can use the ASSIGN command to map the slice to a drive letter.
Refer to the RomWBW User Guide for more information on this
process.

The ROM files are found in

*  /Source/Images/d_msxroms1
*  /Source/Images/d_msxroms2

## Turbo Pascal Compiler

| Floppy Disk Image: **fd_tpascal.img**
| Hard Disk Image: **hd_tpascal.img**

The Borland Turbo Pascal Compiler.
Pascal is a general-purpose, high level programming language originally
designed by Professor Niklaus Wirth of the Technical University of Zurich,
Switzerland and named in honor of Blise Pascal, the famous French philosopher
and mathematician.

Turbo Pascal closely follows the definition of Standard Pascal as defined in
the Pascal User Manual and Report with a few minor differences.

The manual can be found in the Docs/Language directory,
Turbo_Pascal_Version_3.0_Reference_Manual_1986.pdf

A good overview of using Turbo Pascal in CP/M is available at
<https://techtinkering.com/2013/03/05/turbo-pascal-a-great-choice-for-programming-under-cpm>

The following files are found in

*  /Source/Images/d_tpascal

| **File**       | **Description**                |
|----------------|--------------------------------|
| `ART.TXT`      | Part of the Example program    |
| `SA.PAS`       | Example Program                |
| `TINST.COM`    | Installation and Configuration |
| `TINST.DTA`    | Part of TINST                  |
| `TINST.MSG`    | Part of TINST                  |
| `TURBO.COM`    | The main Turbo Pascal program  |
| `TURBO.MSG`    | Part of TURBO Pascal           |
| `TURBO.OVR`    | Part of TURBO Pascal           |
| `TURBOMSG.OVR` | Part of TURBO Pascal           |

## WordStar 4 (Word processor)

| Floppy Disk Image: **fd_ws4.img**
| Hard Disk Image: **hd_ws4.img**
| Combo Disk Image: **Slice 5**

The following files are found in

*  /Source/Images/d_ws4

| **File**       | **Description** |
|----------------|-----------------|
| `ANAGRAM.COM`  |                 |
| `CHAPTER1.DOC` |                 |
| `CHAPTER2.DOC` |                 |
| `CHAPTER3.DOC` |                 |
| `DIARY.DOC`    |                 |
| `DICTSORT.COM` |                 |
| `FIND.COM`     |                 |
| `HOMONYMS.TXT` |                 |
| `HYEXCEPT.TXT` |                 |
| `HYPHEN.COM`   |                 |
| `LOOKUP.COM`   |                 |
| `MAINDICT.CMP` |                 |
| `MARKFIX.COM`  |                 |
| `MOVEPRN.COM`  |                 |
| `PATCH.LST`    |                 |
| `PRINT.TST`    |                 |
| `READ.ME`      |                 |
| `README.`      |                 |
| `REVIEW.COM`   |                 |
| `RULER.DOC`    |                 |
| `SAMPLE1.DOC`  |                 |
| `SAMPLE2.DOC`  |                 |
| `SAMPLE3.DOC`  |                 |
| `SPELL.COM`    |                 |
| `TABLE.DOC`    |                 |
| `TEXT.DOC`     |                 |
| `TW.COM`       |                 |
| `WC.COM`       |                 |
| `WINSTALL.COM` |                 |
| `WORDFREQ.COM` |                 |
| `WS.COM`       |                 |
| `WS.OVR`       |                 |
| `WSCHANGE.COM` |                 |
| `WSCHANGE.OVR` |                 |
| `WSCHHELP.OVR` |                 |
| `WSHELP.OVR`   |                 |
| `WSINDEX.XCL`  |                 |
| `WSMSGS.OVR`   |                 |
| `WSPRINT.OVR`  |                 |
| `WSSHORT.OVR`  |                 |

Also contained on this image in User Area 1 are.

| **File**       | **Description**       |
|----------------|-----------------------|
| `SAMPKEY.DOC`  | ZDE Distribution File |
| `SAMPKEY.ZDK`  | ZDE Distribution File |
| `SAMPKEY.ZDT`  | ZDE Distribution File |
| `ZDE10.DOC`    | ZDE Distribution File |
| `ZDE10.FOR`    | ZDE Distribution File |
| `ZDE10.NEW`    | ZDE Distribution File |
| `ZDE10.QRF`    | ZDE Distribution File |
| `ZDE10.TOC`    | ZDE Distribution File |
| `ZDE13.FOR`    | ZDE Distribution File |
| `ZDE13.NEW`    | ZDE Distribution File |
| `ZDE16.COM`    | ZDE Distribution File |
| `ZDE16.DIR`    | ZDE Distribution File |
| `ZDE16.FIX`    | ZDE Distribution File |
| `ZDE16.FOR`    | ZDE Distribution File |
| `ZDE16.NEW`    | ZDE Distribution File |
| `ZDE16A.COM`   | ZDE Distribution File |
| `ZDE16A.PAT`   | ZDE Distribution File |
| `ZDENST16.COM` | ZDE Distribution File |
| `ZDEPROP.DOC`  | ZDE Distribution File |
| `ZDEPROP.Z80`  | ZDE Distribution File |
| `ZDKCOM13.COM` | ZDE Distribution File |
| `ZDKCOM13.DOC` | ZDE Distribution File |

## Z80ASM Macro Assembler

| Floppy Disk Image: **fd_z80asm.img**
| Hard Disk Image: **hd_z80asm.img**

This disk contains 6 major components

* Z80ASM is a relocating macro assembler for CP/M. It takes assembly language
source statements from a disk file, converts them into their binary equivalent,
and stores the output in either a core-image, Intel hex format, or relocatable
object file. The mnemonics recognized are those of Zilog/Mostek. The optional
listing output may be sent to a disk file, the console and/or the printer, in
any combination. Output files may also be generated containing cross-reference
information on each symbol used.

* Z80ASMP (Z80ASM Plus). Referred to as the "Virtual Memory" version which 
uses disk for working storage, thus not constrained by RAM.

* SLR180 is a powerful relocating macro assembler for Z80
compatible CP/M systems. It takes assembly language source
statements from a disk file, converts them into their binary
equivalent, and stores the output in either a core-image, Intel
hex format, or relocatable object file. The mnemonics recognized
are those of Zilog (Z180)/Hitachi. The optional listing output may be
sent to a disk file, the console and/or the printer, in any
combination. Output files may also be generated containing
cross-reference information on each symbol used.

* SLRMAC relocating macro assembler for Intel 8080 mnemonics

* SLRNK is a powerful linking loader for Z80-based CP/M systems.
It takes relocatable binary information in either Microsoft or
SLR Systems format from a disk file, resolves external and entry
point references, and stores the output in memory for execution
or outputs it to a disk file.

* SLRNKP (SLRNK Plus). Referred to as the "Virtual Memory" version which
uses disk for working storage, thus not constrained by RAM.

* Z80DIS is an entirely new disassembler for Z80 based CP/M sys-
tems. Z80DIS is written in TURBO PASCAL. Z80DIS generates Z80
mnemonics and prepares an assembly language file with many
special features for ease of understanding the intent of the
code. The program and documantation are Copyright 1985, by
Kenneth Gielow, Palo Alto, CA. All rights are reserved.

The manual(s) are available in the Doc/Language directory,

* z80asm (SLR Systems).pdf
* SL180 (SLR Systems 1985).pdf
* SLRNK (SLR Systems 1984).pdf
* Z80DIS User Manual (1985).pdf

A run through of using the assembler is available at
<https://8bitlabs.ca/Posts/2023/05/20/learning-z80-asm>

And another shorter, but shows linker usage guide
<https://pollmyfinger.wordpress.com/2022/01/10/modular-retro-z80-assembly-language-programming-using-slr-systems-z80asm-and-srlnk/>

The following files are found in

*  /Source/Images/d_z80asm

User Area 0 - Assembler

| **File**      | **Description**                             |
|---------------|---------------------------------------------|
| `180FIG.COM`  | Configuration utility for SLR180.COM        |
| `8080.MAC`    | ?                                           |
| `CONFIG.COM`  | Configuration utility for Z80ASM.COM        |
| `CONFIGP.COM` | Configuration utility for Z80ASMP.COM       |
| `DUMP.*`      | Sample Program                              |
| `MAKESYM.COM` | Symbol File .SYM file generation            |
| `MAKESYM.DOC` | Documentation for MAKESYM.COM               |
| `SLR180.COM`  | HD64180 (Z180) Relocating Macro Assembler   |
| `SLR180.DOC`  | Release Notes for SLR180.COM                |
| `SLRMAC.COM`  | 8080 Relocating Macro Assembler             |
| `SYNTAX.HLP`  | Documentation basic usage for all SLR Tools |
| `SYNTAX.TXT`  | Documentation basic usage for all SLR Tools |
| `TEST.\*`     | Sample Program                              |
| `Z80ASM.COM`  | Z80 Relocating Macro Assembler              |
| `Z80ASMP.COM` | Z80 Relocating Macro Assembler (PLUS)       |
| `Z80ASM.DOC`  | Release Notes for Z80ASM.COM                |

User Area 1 - Linker and Library Management

| **File**       | **Description**                               |
|----------------|-----------------------------------------------|
| `LNKFIG.COM`   | Configuration utility for SLRNK.COM           |
| `NZLNKFIX.ZEX` | ?                                             |
| `SLRIB.COM`    | SuperLibrarian, library manager               |
| `SLRNK.COM`    | SuperLinker, the main linker tool             |
| `SLRNKP.COM`   | SuperLinker (PLUS)                            |
| `SLRNK.DOC`    | Release Notes for SLRNK.COM                   |
| `SLRNKFIX.ZEX` | ?                                             |
| `SYNTAX.HLP`   | Documentation basic usage for all SLR Tools   |
| `SYNTAX.TXT`   | Documentation basic usage for all SLR Tools   |
| `SYSSLR.REL`   | SYSLIB (older) Library compatible with SLR    |
| `VSLR.REL`     | VLIB (older) Library compatible with SLR      |
| `Z3SLR.REL`    | Z3LIB (older) Library compatible with SLR     |

User Area 2 - Disassembler

| **File**       | **Description**                  |
|----------------|----------------------------------|
| `README.22`    | Documentation for Z80DIS         |
| `Z80DIS.000`   | Overlay File for Z80DIS.COM      |
| `Z80DIS.001`   | Overlay File for Z80DIS.COM      |
| `Z80DIS.002`   | Overlay File for Z80DIS.COM      |
| `Z80DIS.COM`   | Z80DIS Disassembler main program |
| `Z80DIS22.DOC` | Main Documentation for Z80DIS    |
| `ZDINSTAL.COM` | Instal and Config for Z80DIS.COM |
| `ZDINSTAL.DTA` | Overlay file for ZDINSTAL.COM    |
| `ZDINSTAL.MSG` | Overlay file for ZDINSTAL.COM    |

