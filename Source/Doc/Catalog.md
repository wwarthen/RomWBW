$define{doc_title}{Disk Catalog}$
$define{doc_author}{Mykl Orders}$
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

## Sources

- **RomWBW**: RomWBW Custom Applications

  Documentation: RomWBW Applications.pdf*

  These files are custom applications built exclusively to enhance the
  functionality of RomWBW.  In some cases they are built from scratch
  while others are customized versions of well known CP/M tools.

- **CPM22**: Digital Research CP/M-80 2.2 Distribution Files

  Documentation: CPM Manual.pdf

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

- **ZPM3**: Digital Research CP/M-80 2.2 Distribution Files

  Documentation: *CPM Manual.pdf*

  These files are from Simeon Cran's ZPM3 operating system distribution.

`\clearpage`{=latex}

# CPM 2.2 Boot Disk

| Floppy Disk Image: **fd_cpm22.img**
| Hard Disk Image: **hd_cpm22.img**
| Combo Disk Image: **Slice 0**

| **User 0**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ASM.COM`      | CPM22      | DRI 8080 Assembler |
| `CR.COM`       |     --     | Crunch archiver |
| `DDT.COM`      | CPM22      | DRI Dynamic Debugger |
| `DDTZ.DOC`     |     --     | Z80 replacement for DDT |
| `DIRX.COM`     |     --     | Directory lister with file sizes |
| `DUMP.COM`     | CPM22      | DRI type contents of disk file in hex |
| `ED.COM`       | CPM22      | DRI context editor |
| `KERMIT.COM`   |     --     | Generic CP/M 2.2 Kermit communication application |
| `LBREXT.COM`   |     --     | Extract library files |
| `LIB.COM`      |     --     | DRI Library manager |
| `LINK.COM`     |     --     | DRI CPM relocatable linker |
| `LOAD.COM`     |     --     | DRI hex file loader into memory |
| `MAC.COM`      |     --     | DRI CPM macro assembler |
| `MBASIC.COM`   |     --     | Microsoft Basic |
| `PIP.COM`      | CPM22      | DRI Periperal Interchange Program |
| `PMARC.COM`    |     --     | LHA file compressor |
| `PMEXT.COM`    |     --     | Extractor for PMARC archives |
| `RMAC.COM`     |     --     | DRI Relocatable Macro Assembler |
| `STAT.COM`     | CPM22      | DRI statistices about file storage and device  assignment |
| `SUBMIT.COM`   | CPM22      | DRI batch processor |
| `UNCR.COM`     |     --     | NZCOM Uncrunch decompression |
| `UNZIP.COM`    |     --     | Extractor for ZIP archives |
| `XSUB.COM`     | CPM22      | DRI eXtended submit |
| `ZSID.COM`     |     --     | DRI Z80 symbolic instruction debugger |
| `ASSIGN.COM`   | RomWBW     | RomWBW Drive/Slice mapper |
| `FAT.COM`      | RomWBW     | RomWBW FAT filesystem access |
| `FDU.COM`      | RomWBW     | RomWBW Floppy Disk Utility |
| `FORMAT.COM`   | RomWBW     | RomWBW media formatter (placeholder) |
| `INTTEST.COM`  | RomWBW     | RomWBW Interrupt test |
| `MODE.COM`     | RomWBW     | RomWBW Modify serial port characteristics |
| `RTC.COM`      | RomWBW     | RomWBW Display and set RTC |
| `SURVEY.COM`   | RomWBW     | System survey |
| `SYSCOPY.COM`  | RomWBW     | RomWBW Read/write system boot image |
| `SYSGEN.COM`   | RomWBW     | DRI CPM SYSGEN to put CPM onto a new drive |
| `TALK.COM`     | RomWBW     | RomWBW Direct console I/O to a serial port |
| `TIMER.COM`    | RomWBW     | RomWBW Display timer tick counter |
| `TUNE.COM`     | RomWBW     | RomWBW Play PT or MYM sound files |
| `XM.COM`       | RomWBW     | RomWBW XMODEM file transfer |
| `CPM.SYS`      | RomWBW     | CPM2.2 system image |
| `CLRDIR.COM`   |     --     | Max Scane's disk directory cleaner |
| `COMPARE.COM`  |     --     | FoxHollow compare two files |
| `DDTZ.COM`     |     --     | Z80 replacement for DDT |
| `FDISK80.COM`  |     --     | John Coffman's Partition editor for FAT filesystem |
| `FLASH.COM`    |     --     | Will Sowerbutts' in-situ EEPROM programmer |
| `NULU.COM`     |     --     | NZCOM new library utility |
| `UNARC.COM`    |     --     | Extractor for ARC archives |
| `ZAP.COM`      |     --     | Disk editor/patcher |
| `ZDE.COM`      |     --     | Z-system display editor |
| `ZDENST.COM`   |     --     | ZDE Installer |

| **User 1**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `SAMPKEY.DOC`  |     --     | ZDE Distribution File |
| `SAMPKEY.ZDK`  |     --     | ZDE Distribution File |
| `SAMPKEY.ZDT`  |     --     | ZDE Distribution File |
| `ZDE10.DOC`    |     --     | ZDE Distribution File |
| `ZDE10.FOR`    |     --     | ZDE Distribution File |
| `ZDE10.NEW`    |     --     | ZDE Distribution File |
| `ZDE10.QRF`    |     --     | ZDE Distribution File |
| `ZDE10.TOC`    |     --     | ZDE Distribution File |
| `ZDE13.FOR`    |     --     | ZDE Distribution File |
| `ZDE13.NEW`    |     --     | ZDE Distribution File |
| `ZDE16.COM`    |     --     | ZDE Distribution File |
| `ZDE16.DIR`    |     --     | ZDE Distribution File |
| `ZDE16.FIX`    |     --     | ZDE Distribution File |
| `ZDE16.FOR`    |     --     | ZDE Distribution File |
| `ZDE16.NEW`    |     --     | ZDE Distribution File |
| `ZDE16A.COM`   |     --     | ZDE Distribution File |
| `ZDE16A.PAT`   |     --     | ZDE Distribution File |
| `ZDENST16.COM` |     --     | ZDE Distribution File |
| `ZDEPROP.DOC`  |     --     | ZDE Distribution File |
| `ZDEPROP.Z80`  |     --     | ZDE Distribution File |
| `ZDKCOM13.COM` |     --     | ZDE Distribution File |
| `ZDKCOM13.DOC` |     --     | ZDE Distribution File |

| **User 3**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ATTACK.PT3`   |     --     | Sound File |
| `BACKUP.PT3`   |     --     | Sound File |
| `BADMICE.PT3`  |     --     | Sound File |
| `DEMO.MYM`     |     --     | Sound File |
| `DEMO1.MYM`    |     --     | Sound File |
| `DEMO3.MYM`    |     --     | Sound File |
| `DEMO3MIX.MYM` |     --     | Sound File |
| `DEMO4.MYM`    |     --     | Sound File |
| `HOWRU.PT3`    |     --     | Sound File |
| `ITERATN.PT3`  |     --     | Sound File |
| `LOOKBACK.PT3` |     --     | Sound File |
| `LOUBOUTN.PT3` |     --     | Sound File |
| `NAMIDA.PT3`   |     --     | Sound File |
| `RECOLL.PT3`   |     --     | Sound File |
| `SANXION.PT3`  |     --     | Sound File |
| `SYNCH.PT3`    |     --     | Sound File |
| `TOSTAR.PT3`   |     --     | Sound File |
| `VICTORY.PT3`  |     --     | Sound File |
| `WICKED.PT3`   |     --     | Sound File |
| `YEOLDE.PT3`   |     --     | Sound File |
| `YEOVIL.PT3`   |     --     | Sound File |

`\clearpage`{=latex}

# ZSDOS 1.1 Boot Disk

| Floppy Disk Image: **fd_zsdos.img**
| Hard Disk Image: **hd_zsdos.img**
| Combo Disk Image: **Slice 1**

| **User 0**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ASM.COM`      | CPM22      | DRI 8080 Assembler |
| `CLOCKS.DAT`   | ZSDOS      | ZSDOS Library of clock drivers |
| `COPY.CFG`     | ZSDOS      | ZSDOS Configuration file for COPY.COM |
| `COPY.COM`     | ZSDOS      | ZSDOS File copier with file dates and archiving |
| `COPY.UPD`     | ZSDOS      | ZSDOS ??? |
| `CR.COM`       |     --     | Crunch archiver |
| `DATSWEEP.COM` | ZSDOS      | ZSDOS Comprehensive file management utility |
| `DDT.COM`      | CPM22      | DRI Dynamic Debugger |
| `DDTZ.DOC`     |     --     | Z80 replacement for DDT |
| `DIRX.COM`     |     --     | Directory lister with file sizes |
| `DSCONFIG.COM` | ZSDOS      | ZSDOS DATSWEEP configuration tool |
| `DUMP.COM`     | CPM22      | DRI type contents of disk file in hex |
| `ED.COM`       | CPM22      | DRI context editor |
| `FA16.CFG`     | ZSDOS      | ZSDOS FILEATTR.COM v1.6 configuration file |
| `FA16.DOC`     | ZSDOS      | ZSDOS FILEATTR.COM v1.6 documentation |
| `FA16A.FOR`    | ZSDOS      | ZSDOS FILEATTR.COM v1.6a information |
| `FA16CFG.TXT`  | ZSDOS      | ZSDOS FILEATTR.COM v1.6 configuration instructions |
| `FILEATTR.COM` | ZSDOS      | ZSDOS Modify file attributes |
| `FILEDATE.CFG` | ZSDOS      | ZSDOS Configuration file for FILEDATE.COM |
| `FILEDATE.COM` | ZSDOS      | ZSDOS Disk directory that allows sorting and selecting by date and name |
| `FILEDATE.COM` | ZSDOS      | ZSDOS Disk directory that allows sorting and selecting by date and name |
| `INITDIR.CFG`  | ZSDOS      | ZSDOS Configuration file for INITDIR.COM |
| `INITDIR.COM`  | ZSDOS      | ZSDOS Prepare disks for P2DOS Stamps |
| `KERMIT.COM`   |     --     | Generic CP/M 2.2 Kermit communication application |
| `LBREXT.COM`   |     --     | Extract library files |
| `LDDS.COM`     | ZSDOS      | Clock driver |
| `LDNZT.COM`    | ZSDOS      | Clock driver |
| `LDP2D.COM`    | ZSDOS      | Clock driver |
| `LIB.COM`      |     --     | DRI Library manager |
| `LINK.COM`     |     --     | DRI CPM relocatable linker |
| `LOAD.COM`     |     --     | DRI hex file loader into memory |
| `MAC.COM`      |     --     | DRI CPM macro assembler |
| `MBASIC.COM`   |     --     | Microsoft Basic |
| `PIP.COM`      | CPM22      | DRI Periperal Interchange Program |
| `PMARC.COM`    |     --     | LHA file compressor |
| `PMEXT.COM`    |     --     | Extractor for PMARC archives |
| `PUTBG.COM`    | ZSDOS      | ZSDOS Prepare disk for backgrounder |
| `PUTDS.COM`    | ZSDOS      | ZSDOS Prepare disk for datestamper |
| `RELOG.COM`    | ZSDOS      | ZSDOS relog disks after program that bypasses BDOS |
| `RMAC.COM`     |     --     | DRI Relocatable Macro Assembler |
| `SETTERM.COM`  | ZSDOS      | ZSDOS Installs terminal control codes into DateSamper utilities |
| `SETUPZST.COM` | ZSDOS      | ZSDOS Select clock driver |
| `STAMPS.DAT`   | ZSDOS      | ZSDOS Library of stamping routines |
| `STAT.COM`     | CPM22      | DRI statistices about file storage and device assignment |
| `SUBMIT.COM`   | CPM22      | DRI batch processor |
| `SUPERSUB.COM` | ZSDOS      |  |
| `TD.CFG`       | ZSDOS      | ZSDOS Configuration file for TD.COM |
| `TD.COM`       | ZSDOS      | ZSDOS Time/Date utility |
| `TERMBASE.DAT` | ZSDOS      | ZSDOS Terminal information library for SETTERM |
| `TESTCLOK.COM` | ZSDOS      | ZSDOS Test various clock drivers |
| `UNCR.COM`     |     --     | NZCOM Uncrunch decompression |
| `UNZIP.COM`    |     --     | Extractor for ZIP archives |
| `XSUB.COM`     | CPM22      | DRI eXtended submit |
| `ZCAL.COM`     | ZSDOS      | ZSDOS Show month calendar |
| `ZCNFG.COM`    | ZSDOS      | ZSDOS Configure various utilities |
| `ZCNFG24.CFG`  | ZSDOS      | ZSDOS Configuration file for ZCNFG.COM |
| `ZPATH.COM`    | ZSDOS      | ZSDOS Set BDOS and/or ZCPR command path |
| `ZSCONFIG.COM` | ZSDOS      | ZSDOS Dynamically regulate many of ZSDOS features |
| `ZSID.COM`     |     --     | DRI Z80 symbolic instruction debugger |
| `ZSVSTAMP.COM` | ZSDOS      | ZSDOS Save/restore file timestamp |
| `ZSVSTAMP.DOC` | ZSDOS      | ZSDOS ZSVSTAMP.COM documentation |
| `ZXD.CFG`      | ZSDOS      | ZSDOS Configuration file for ZXD.COM |
| `ZXD.COM`      | ZSDOS      | ZSDOS Extended directory utility |
| `ASSIGN.COM`   | RomWBW     | RomWBW Drive/Slice mapper |
| `FAT.COM`      | RomWBW     | RomWBW FAT filesystem access |
| `FDU.COM`      | RomWBW     | RomWBW Floppy Disk Utility |
| `FORMAT.COM`   | RomWBW     | RomWBW media formatter (placeholder) |
| `INTTEST.COM`  | RomWBW     | RomWBW Interrupt test |
| `MODE.COM`     | RomWBW     | RomWBW Modify serial port characteristics |
| `RTC.COM`      | RomWBW     | RomWBW Display and set RTC |
| `SURVEY.COM`   | RomWBW     | System survey |
| `SYSCOPY.COM`  | RomWBW     | RomWBW Read/write system boot image |
| `SYSGEN.COM`   | RomWBW     | DRI CPM SYSGEN to put CPM onto a new drive |
| `TALK.COM`     | RomWBW     | RomWBW Direct console I/O to a serial port |
| `TIMER.COM`    | RomWBW     | RomWBW Display timer tick counter |
| `TUNE.COM`     | RomWBW     | RomWBW Play PT or MYM sound files |
| `XM.COM`       | RomWBW     | RomWBW XMODEM file transfer |
| `ZSYS.SYS`     | RomWBW     | ZSDOS system image |
| `CLRDIR.COM`   |     --     | Max Scane's disk directory cleaner |
| `COMPARE.COM`  |     --     | FoxHollow compare two files |
| `DDTZ.COM`     |     --     | Z80 replacement for DDT |
| `FDISK80.COM`  |     --     | John Coffman's Partition editor for FAT filesystem |
| `FLASH.COM`    |     --     | Will Sowerbutts' in-situ EEPROM programmer |
| `NULU.COM`     |     --     | NZCOM new library utility |
| `UNARC.COM`    |     --     | Extractor for ARC archives |
| `ZAP.COM`      |     --     | Disk editor/patcher |
| `ZDE.COM`      |     --     | Z-system display editor |
| `ZDENST.COM`   |     --     | ZDE Installer |

| **User 1**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `SAMPKEY.DOC`  |     --     | ZDE Distribution File |
| `SAMPKEY.ZDK`  |     --     | ZDE Distribution File |
| `SAMPKEY.ZDT`  |     --     | ZDE Distribution File |
| `ZDE10.DOC`    |     --     | ZDE Distribution File |
| `ZDE10.FOR`    |     --     | ZDE Distribution File |
| `ZDE10.NEW`    |     --     | ZDE Distribution File |
| `ZDE10.QRF`    |     --     | ZDE Distribution File |
| `ZDE10.TOC`    |     --     | ZDE Distribution File |
| `ZDE13.FOR`    |     --     | ZDE Distribution File |
| `ZDE13.NEW`    |     --     | ZDE Distribution File |
| `ZDE16.COM`    |     --     | ZDE Distribution File |
| `ZDE16.DIR`    |     --     | ZDE Distribution File |
| `ZDE16.FIX`    |     --     | ZDE Distribution File |
| `ZDE16.FOR`    |     --     | ZDE Distribution File |
| `ZDE16.NEW`    |     --     | ZDE Distribution File |
| `ZDE16A.COM`   |     --     | ZDE Distribution File |
| `ZDE16A.PAT`   |     --     | ZDE Distribution File |
| `ZDENST16.COM` |     --     | ZDE Distribution File |
| `ZDEPROP.DOC`  |     --     | ZDE Distribution File |
| `ZDEPROP.Z80`  |     --     | ZDE Distribution File |
| `ZDKCOM13.COM` |     --     | ZDE Distribution File |
| `ZDKCOM13.DOC` |     --     | ZDE Distribution File |

| **User 3**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ATTACK.PT3`   |     --     | Sound File |
| `BACKUP.PT3`   |     --     | Sound File |
| `BADMICE.PT3`  |     --     | Sound File |
| `DEMO.MYM`     |     --     | Sound File |
| `DEMO1.MYM`    |     --     | Sound File |
| `DEMO3.MYM`    |     --     | Sound File |
| `DEMO3MIX.MYM` |     --     | Sound File |
| `DEMO4.MYM`    |     --     | Sound File |
| `HOWRU.PT3`    |     --     | Sound File |
| `ITERATN.PT3`  |     --     | Sound File |
| `LOOKBACK.PT3` |     --     | Sound File |
| `LOUBOUTN.PT3` |     --     | Sound File |
| `NAMIDA.PT3`   |     --     | Sound File |
| `RECOLL.PT3`   |     --     | Sound File |
| `SANXION.PT3`  |     --     | Sound File |
| `SYNCH.PT3`    |     --     | Sound File |
| `TOSTAR.PT3`   |     --     | Sound File |
| `VICTORY.PT3`  |     --     | Sound File |
| `WICKED.PT3`   |     --     | Sound File |
| `YEOLDE.PT3`   |     --     | Sound File |
| `YEOVIL.PT3`   |     --     | Sound File |

`\clearpage`{=latex}

# NZCOM Boot Disk

| Floppy Disk Image: **fd_nzcom.img**
| Hard Disk Image: **hd_nzcom.img**
| Combo Disk Image: **Slice 2**

| **User 0**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `!(C)1988`     | NZCOM      |  |
| `!NZ-COM`      | NZCOM      |  |
| `!VERS--1.2H`  | NZCOM      |  |
| `ALIAS.CMD`    | NZCOM      | NZCOM Aliases file for ARUNZ.COM |
| `ARUNZ.COM`    | NZCOM      | NZCOM Invoke an alias in ALIAS.CMD |
| `BGZRDS19.LBR` | NZCOM      |  |
| `CLEDINST.COM` | NZCOM      | Command line editing and history shell installer |
| `CLEDSAVE.COM` | NZCOM      | Write command line history to disk |
| `CONFIG.LBR`   | NZCOM      |  |
| `COPY.COM`     | NZCOM      | ZSDOS File copier with file dates and archiving |
| `CPSET.COM`    | NZCOM      | NZCOM Create multiple definitions for CRT and PRT |
| `CRUNCH.COM`   | NZCOM      | NZCOM Text compression |
| `DOCFILES.LBR` | NZCOM      |  |
| `EDITNDR.COM`  | NZCOM      | NZCOM Associate names with directories |
| `FCP.LBR`      | NZCOM      | NZCOM ??? Flow control |
| `FF.COM`       | NZCOM      | NZCOM File finder |
| `HELP.COM`     | NZCOM      | DRI CPM+ |
| `HLPFILES.LBR` | NZCOM      |  |
| `IF.COM`       | NZCOM      | NZCOM  Flow condition tester for FCP |
| `JETLDR.COM`   | NZCOM      | NZCOM General-purpose module loader |
| `KERMIT.COM`   |     --     | Generic CP/M 2.2 Kermit communication application |
| `LBREXT.COM`   | NZCOM      | Extract library files |
| `LBRHELP.COM`  | NZCOM      |  |
| `LDIR.COM`     | NZCOM      | NZCOM Display the directory of a library |
| `LPUT.COM`     | NZCOM      | NZCOM Put files into a library |
| `LSH-HELP.COM` | NZCOM      |  |
| `LSH.COM`      | NZCOM      |  |
| `LSH.WZ`       | NZCOM      |  |
| `LSHINST.COM`  | NZCOM      |  |
| `LX.COM`       | NZCOM      | NZCOM Extract and execute a memeber of a library |
| `MKZCM.COM`    | NZCOM      | NZCOM NZCOM system defining utility |
| `NAME.COM`     | NZCOM      | NZCOM Name a drive/user |
| `NZ-DBASE.INF` | NZCOM      | NZCOM Dbase information |
| `NZBLITZ.COM`  | NZCOM      |  |
| `NZBLTZ14.CFG` | NZCOM      |  |
| `NZBLTZ14.HZP` | NZCOM      |  |
| `NZCOM.COM`    | NZCOM      | NZCOM system loader from CP/M |
| `NZCOM.LBR`    | NZCOM      | NZCOM Library of NZCOM system modules |
| `NZCPR.LBR`    | NZCOM      | NZCOM Default command processor |
| `PATH.COM`     | NZCOM      | NZCOM Set/display command search path |
| `PUBLIC.COM`   | NZCOM      |  |
| `PWD.COM`      | NZCOM      |  |
| `RCP.LBR`      | NZCOM      | NZCOM Resident command package |
| `RELEASE.NOT`  | NZCOM      |  |
| `SAINST.COM`   | NZCOM      |  |
| `SALIAS.COM`   | NZCOM      | NZCOM Screen alias |
| `SAVENDR.COM`  | NZCOM      | NZCOM Save named directory assignments to a file |
| `SDZ.COM`      | NZCOM      | NZCOM Super directory |
| `SHOW.COM`     | NZCOM      | NZCOM Show resident commands |
| `SUB.COM`      | NZCOM      |  |
| `SUBMIT.COM`   |     --     | DRI batch processor |
| `TCAP.LBR`     | NZCOM      | NZCOM Terminal capability descriptor library |
| `TCJ.INF`      | NZCOM      |  |
| `TCJ25.WZ`     | NZCOM      |  |
| `TCJ26.WZ`     | NZCOM      |  |
| `TCJ27.WZ`     | NZCOM      |  |
| `TCJ28.WZ`     | NZCOM      |  |
| `TCJ29.WZ`     | NZCOM      |  |
| `TCJ30.WZ`     | NZCOM      |  |
| `TCJ31UPD.WZ`  | NZCOM      |  |
| `TCJ32.WZ`     | NZCOM      |  |
| `TCJ33UPD.WZ`  | NZCOM      |  |
| `TCSELECT.COM` | NZCOM      | NZCOM Create terminal capability file |
| `TY3ERA.COM`   | NZCOM      | NZCOM Type-3 transient program to erase a file |
| `TY3REN.COM`   | NZCOM      | NZCOM Type-3 transient program to rename a file |
| `TY4ERA.COM`   | NZCOM      | NZCOM Type-4 transient program to erase a file |
| `TY4REN.COM`   | NZCOM      | NZCOM Type-4 transient program to rename a file |
| `TY4SAVE.COM`  | NZCOM      | NZCOM Type-4 transient program to save memory to a file |
| `TY4SP.COM`    | NZCOM      | NZCOM Type-4 transient program ti display disk space |
| `UNCRUNCH.COM` | NZCOM      | NZCOM Text decompressor |
| `VIEW.COM`     | NZCOM      |  |
| `XTCAP.COM`    | NZCOM      |  |
| `Z3LOC.COM`    | NZCOM      | NZCOM Display the addresses of the ZCPR3 CCP, BDOS, and BIOS |
| `Z3TCAP.TCP`   | NZCOM      | NZCOM Database of terminal descriptors |
| `ZCNFG.COM`    | NZCOM      | ZSDOS Configure various utilities |
| `ZERR.COM`     | NZCOM      |  |
| `ZEX.COM`      | NZCOM      | NZCOM Memory-based batch processor |
| `ZF-DIM.COM`   | NZCOM      | NZCOM ZFILER shell for dim-video terminals |
| `ZF-REV.COM`   | NZCOM      | NZCOM ZFILER shell for reverse-video terminals |
| `ZFILEB38.LZT` | NZCOM      |  |
| `ZFILER.CMD`   | NZCOM      | NZCOM Macro script file for ZFILER |
| `ZHELPERS.LZT` | NZCOM      |  |
| `ZLT.COM`      | NZCOM      |  |
| `ZNODES66.LZT` | NZCOM      |  |
| `ZSDOS.ZRL`    | NZCOM      |  |
| `ZSYSTEM.IZF`  | NZCOM      |  |
| `ASSIGN.COM`   | RomWBW     | RomWBW Drive/Slice mapper |
| `FAT.COM`      | RomWBW     | RomWBW FAT filesystem access |
| `FDU.COM`      | RomWBW     | RomWBW Floppy Disk Utility |
| `FORMAT.COM`   | RomWBW     | RomWBW media formatter (placeholder) |
| `INTTEST.COM`  | RomWBW     | RomWBW Interrupt test |
| `MODE.COM`     | RomWBW     | RomWBW Modify serial port characteristics |
| `RTC.COM`      | RomWBW     | RomWBW Display and set RTC |
| `SURVEY.COM`   | RomWBW     | System survey |
| `SYSCOPY.COM`  | RomWBW     | RomWBW Read/write system boot image |
| `SYSGEN.COM`   | RomWBW     | DRI CPM SYSGEN to put CPM onto a new drive |
| `TALK.COM`     | RomWBW     | RomWBW Direct console I/O to a serial port |
| `TIMER.COM`    | RomWBW     | RomWBW Display timer tick counter |
| `TUNE.COM`     | RomWBW     | RomWBW Play PT or MYM sound files |
| `XM.COM`       | RomWBW     | RomWBW XMODEM file transfer |
| `CPM.SYS`      | RomWBW     |  |
| `ZSYS.SYS`     | RomWBW     |  |
| `CLRDIR.COM`   |     --     | Max Scane's disk directory cleaner |
| `COMPARE.COM`  |     --     | FoxHollow compare two files |
| `DDTZ.COM`     |     --     | Z80 replacement for DDT |
| `FDISK80.COM`  |     --     | John Coffman's Partition editor for FAT filesystem |
| `FLASH.COM`    |     --     | Will Sowerbutts' in-situ EEPROM programmer |
| `NULU.COM`     |     --     | NZCOM new library utility |
| `UNARC.COM`    |     --     | Extractor for ARC archives |
| `ZAP.COM`      |     --     | Disk editor/patcher |
| `ZDE.COM`      |     --     | Z-system display editor |
| `ZDENST.COM`   |     --     | ZDE Installer |

| **User 3**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ATTACK.PT3`   |     --     | Sound File |
| `BACKUP.PT3`   |     --     | Sound File |
| `BADMICE.PT3`  |     --     | Sound File |
| `DEMO.MYM`     |     --     | Sound File |
| `DEMO1.MYM`    |     --     | Sound File |
| `DEMO3.MYM`    |     --     | Sound File |
| `DEMO3MIX.MYM` |     --     | Sound File |
| `DEMO4.MYM`    |     --     | Sound File |
| `HOWRU.PT3`    |     --     | Sound File |
| `ITERATN.PT3`  |     --     | Sound File |
| `LOOKBACK.PT3` |     --     | Sound File |
| `LOUBOUTN.PT3` |     --     | Sound File |
| `NAMIDA.PT3`   |     --     | Sound File |
| `RECOLL.PT3`   |     --     | Sound File |
| `SANXION.PT3`  |     --     | Sound File |
| `SYNCH.PT3`    |     --     | Sound File |
| `TOSTAR.PT3`   |     --     | Sound File |
| `VICTORY.PT3`  |     --     | Sound File |
| `WICKED.PT3`   |     --     | Sound File |
| `YEOLDE.PT3`   |     --     | Sound File |
| `YEOVIL.PT3`   |     --     | Sound File |

`\clearpage`{=latex}

# CP/M 3 Boot Disk

| Floppy Disk Image: **fd_cpm3.img**
| Hard Disk Image: **hd_cpm3.img**
| Combo Disk Image: **Slice 3**

| **User 0**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `DATE.COM`     | CPM3       | DRI CPM+ Set or display the date and time |
| `DEVICE.COM`   | CPM3       | DRI CPM+ Assign logical devices with one or more physical devices |
| `DIR.COM`      | CPM3       | DRI CPM+ DIR with options |
| `DUMP.COM`     | CPM3       | DRI type contents of disk file in hex |
| `ED.COM`       | CPM3       | DRI context editor |
| `ERASE.COM`    | CPM3       | DRI file deletion |
| `GENCOM.COM`   | CPM3       | DRI CPM+ Generate special COM file with attached RSX files |
| `GET.COM`      | CPM3       | DRI CPM+ Temporarily get console input form a disk file |
| `HELP.COM`     | CPM3       | DRI CPM+ Display information on how to use commands |
| `HELP.HLP`     | CPM3       | DRI CPM+ Databse of help information for HELP.COM |
| `HEXCOM.CPM`   | CPM3       | DRI CPM+ Create a COM file from a nex file output by MAC |
| `INITDIR.COM`  | CPM3       | DRI CPM+ Initializes a disk to allow time and date stamping |
| `KERMIT.COM`   |     --     | Generic CP/M 3 Kermit communication application |
| `PATCH.COM`    | CPM3       | DRI CPM+ Display or install patch to the CPM+ system or command files |
| `PIP.COM`      | CPM3       | DRI Periperal Interchange Program |
| `PUT.COM`      | CPM3       | DIR CPM+ Temporarily redirect printer or console output to a disk file |
| `RENAME.COM`   | CPM3       | DRI CPM+ Rename a file |
| `ROMWBW.TXT`   | RomWBW     |  |
| `SAVE.COM`     | CPM3       | DRI CPM+ Copy the contents of memory to a file |
| `SET.COM`      | CPM3       | DIR CPM+ Set file options |
| `SETDEF.COM`   | CPM3       | DIR CPM+ Set system options including the drive search chain |
| `SHOW.COM`     | CPM3       | DIR CPM+ Display disk and drive statistics |
| `SUBMIT.COM`   | CPM3       | DRI batch processor |
| `TYPE.COM`     | CPM3       | DIR CPM+ Display the contents of an ASCII character file |
| `ZSID.COM`     | CPM3       | DRI Z80 symbolic instruction debugger |
| `CPMLDR.COM`   | RomWBW     | DRI CPM 3.0 loader |
| `CPMLDR.SYS`   | RomWBW     | DRI CPM 3.0 loader |
| `CCP.COM`      | CPM3       | DRI CPM+ Console Command Processor |
| `GENCPM.COM`   | CPM3       | DRI CPM+ Create a memory image of CPM3.SYS |
| `GENRES.DAT`   | RomWBW     |  |
| `GENBNK.DAT`   | RomWBW     |  |
| `BIOS3.SPR`    | RomWBW     | DRI CPM+ GENCPM input file for non-banked BIOS |
| `BNKBIOS3.SPR` | RomWBW     | DRI CPM+ GENCPM input file for banked BIOS |
| `BDOS3.SPR`    | CPM3       | DRI CPM+ GENCPM input file for the non-banked BDOS |
| `BNKBDOS3.SPR` | CPM3       | DRI CPM+ GENCPM input file for banked BDOS |
| `RESBDOS3.SPR` | CPM3       | DRI CPM+ GENCPM input file for resident BDOS |
| `CPM3RES.SYS`  | RomWBW     | DRI CPM+ (non-banked) memory image |
| `CPM3BNK.SYS`  | RomWBW     | DRI CPM+ (banked) memory image |
| `GENCPM.DAT`   | RomWBW     | DRI CPM+ System generation tool data file |
| `CPM3.SYS`     | RomWBW     | DRI CPM+ (non-banked) memory image |
| `README.1ST`   | CPM3       |  |
| `CPM3FIX.PAT`  | CPM3       |  |
| `ASSIGN.COM`   | RomWBW     | RomWBW Drive/Slice mapper |
| `FAT.COM`      | RomWBW     | RomWBW FAT filesystem access |
| `FDU.COM`      | RomWBW     | RomWBW Floppy Disk Utility |
| `FORMAT.COM`   | RomWBW     | RomWBW media formatter (placeholder) |
| `INTTEST.COM`  | RomWBW     | RomWBW Interrupt test |
| `MODE.COM`     | RomWBW     | RomWBW Modify serial port characteristics |
| `RTC.COM`      | RomWBW     | RomWBW Display and set RTC |
| `SURVEY.COM`   | RomWBW     | System survey |
| `SYSCOPY.COM`  | RomWBW     | RomWBW Read/write system boot image |
| `SYSGEN.COM`   | RomWBW     | DRI CPM SYSGEN to put CPM onto a new drive |
| `TALK.COM`     | RomWBW     | RomWBW Direct console I/O to a serial port |
| `TIMER.COM`    | RomWBW     | RomWBW Display timer tick counter |
| `TUNE.COM`     | RomWBW     | RomWBW Play PT or MYM sound files |
| `XM.COM`       | RomWBW     | RomWBW XMODEM file transfer |
| `CLRDIR.COM`   |     --     | Max Scane's disk directory cleaner |
| `COMPARE.COM`  |     --     | FoxHollow compare two files |
| `DDTZ.COM`     |     --     | Z80 replacement for DDT |
| `FDISK80.COM`  |     --     | John Coffman's Partition editor for FAT filesystem |
| `FLASH.COM`    |     --     | Will Sowerbutts' in-situ EEPROM programmer |
| `NULU.COM`     |     --     | NZCOM new library utility |
| `UNARC.COM`    |     --     | Extractor for ARC archives |
| `ZAP.COM`      |     --     | Disk editor/patcher |
| `ZDE.COM`      |     --     | Z-system display editor |
| `ZDENST.COM`   |     --     | ZDE Installer |

| **User 3**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ATTACK.PT3`   |     --     | Sound File |
| `BACKUP.PT3`   |     --     | Sound File |
| `BADMICE.PT3`  |     --     | Sound File |
| `DEMO.MYM`     |     --     | Sound File |
| `DEMO1.MYM`    |     --     | Sound File |
| `DEMO3.MYM`    |     --     | Sound File |
| `DEMO3MIX.MYM` |     --     | Sound File |
| `DEMO4.MYM`    |     --     | Sound File |
| `HOWRU.PT3`    |     --     | Sound File |
| `ITERATN.PT3`  |     --     | Sound File |
| `LOOKBACK.PT3` |     --     | Sound File |
| `LOUBOUTN.PT3` |     --     | Sound File |
| `NAMIDA.PT3`   |     --     | Sound File |
| `RECOLL.PT3`   |     --     | Sound File |
| `SANXION.PT3`  |     --     | Sound File |
| `SYNCH.PT3`    |     --     | Sound File |
| `TOSTAR.PT3`   |     --     | Sound File |
| `VICTORY.PT3`  |     --     | Sound File |
| `WICKED.PT3`   |     --     | Sound File |
| `YEOLDE.PT3`   |     --     | Sound File |
| `YEOVIL.PT3`   |     --     | Sound File |

`\clearpage`{=latex}

# ZPM3 Boot Disk

| Floppy Disk Image: **fd_zpm3.img**
| Hard Disk Image: **hd_zpm3.img**
| Combo Disk Image: **Slice 4**

| **User 0**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `HELP.HLP`     | ZPM3       |  |
| `ROMWBW.TXT`   | RomWBW     |  |
| `ZPMLDR.COM`   | RomWBW     |  |
| `ZPMLDR.SYS`   | RomWBW     |  |
| `CPMLDR.COM`   | RomWBW     |  |
| `CPMLDR.SYS`   | RomWBW     |  |
| `CPM3.SYS`     | RomWBW     |  |
| `ZCCP.COM`     | ZPM3       |  |
| `ZINSTAL.ZPM`  | ZPM3       |  |
| `STARTZPM.COM` | ZPM3       |  |
| `MAKEDOS.COM`  | ZPM3       |  |
| `GENCPM.DAT`   | RomWBW     |  |
| `BNKBIOS3.SPR` | RomWBW     |  |
| `BNKBDOS3.SPR` | ZPM3       |  |
| `RESBDOS3.SPR` | ZPM3       |  |

| **User 3**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ATTACK.PT3`   |     --     | Sound File |
| `BACKUP.PT3`   |     --     | Sound File |
| `BADMICE.PT3`  |     --     | Sound File |
| `DEMO.MYM`     |     --     | Sound File |
| `DEMO1.MYM`    |     --     | Sound File |
| `DEMO3.MYM`    |     --     | Sound File |
| `DEMO3MIX.MYM` |     --     | Sound File |
| `DEMO4.MYM`    |     --     | Sound File |
| `HOWRU.PT3`    |     --     | Sound File |
| `ITERATN.PT3`  |     --     | Sound File |
| `LOOKBACK.PT3` |     --     | Sound File |
| `LOUBOUTN.PT3` |     --     | Sound File |
| `NAMIDA.PT3`   |     --     | Sound File |
| `RECOLL.PT3`   |     --     | Sound File |
| `SANXION.PT3`  |     --     | Sound File |
| `SYNCH.PT3`    |     --     | Sound File |
| `TOSTAR.PT3`   |     --     | Sound File |
| `VICTORY.PT3`  |     --     | Sound File |
| `WICKED.PT3`   |     --     | Sound File |
| `YEOLDE.PT3`   |     --     | Sound File |
| `YEOVIL.PT3`   |     --     | Sound File |

| **User 10**    | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ALIAS.HLP`    |     --     |  |
| `HP-RPN.HLP`   |     --     |  |
| `HP-ZP.HLP`    |     --     |  |
| `IF.HLP`       |     --     |  |
| `MENU.HLP`     |     --     |  |
| `VLU.HLP`      |     --     |  |
| `ZFHIST.HLP`   |     --     |  |
| `ZFILER.HLP`   |     --     |  |
| `ZFMACRO.HLP`  |     --     |  |
| `ZP.HLP`       |     --     |  |

| **User 14**    | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `COPY.CFG`     |     --     |  |
| `ERASE.CFG`    |     --     |  |
| `HELPC15.CFG`  |     --     |  |
| `ZCNFG24.CFG`  |     --     |  |
| `ZEX.CFG`      |     --     |  |
| `ZF11.CFG`     |     --     |  |
| `ZP17.CFG`     |     --     |  |

| **User 15**    | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ALIAS.COM`    |     --     |  |
| `ARUNZ.COM`    |     --     |  |
| `COPY.COM`     |     --     |  |
| `DATE.COM`     | CPM3       |  |
| `DEV.COM`      |     --     |  |
| `DEVICE.COM`   | CPM3       |  |
| `DIR.COM`      | CPM3       |  |
| `DISKINFO.COM` |     --     |  |
| `DU.COM`       |     --     |  |
| `DUMP.COM`     | CPM3       |  |
| `ED.COM`       | CPM3       |  |
| `ERASE.COM`    | CPM3       |  |
| `GENCOM.COM`   | CPM3       |  |
| `GENCPM.COM`   | CPM3       |  |
| `GET.COM`      | CPM3       |  |
| `GOTO.COM`     |     --     |  |
| `HELP.COM`     | CPM3       |  |
| `HEXCOM.COM`   | CPM3       |  |
| `IF.COM`       |     --     |  |
| `INITDIR.COM`  | CPM3       |  |
| `KERMIT.COM`   | CPM3       |  |
| `LBREXT.COM`   |     --     |  |
| `LIB.COM`      |     --     |  |
| `LINK.COM`     |     --     |  |
| `LOADSEG.COM`  |     --     |  |
| `MAC.COM`      |     --     |  |
| `MBASIC.COM`   |     --     |  |
| `NAMES.NDR`    |     --     |  |
| `PATCH.COM`    | CPM3       |  |
| `PIP.COM`      | CPM3       |  |
| `PUT.COM`      | CPM3       |  |
| `REMOVE.COM`   |     --     |  |
| `RENAME.COM`   | CPM3       |  |
| `RMAC.COM`     |     --     |  |
| `RSXDIR.COM`   |     --     |  |
| `SAINST.COM`   |     --     |  |
| `SALIAS.COM`   |     --     |  |
| `SAVE.COM`     | CPM3       |  |
| `SET.COM`      | CPM3       |  |
| `SETDEF.COM`   | CPM3       |  |
| `SETPATH.COM`  |     --     |  |
| `SHOW.COM`     | CPM3       |  |
| `SUBMIT.COM`   | CPM3       |  |
| `TCAP.Z3T`     |     --     |  |
| `TYPE.COM`     | CPM3       |  |
| `VERROR.COM`   |     --     |  |
| `VLU.COM`      |     --     |  |
| `XREF.COM`     |     --     |  |
| `ZCNFG.COM`    |     --     |  |
| `ZERASE.COM`   |     --     |  |
| `ZEX.COM`      |     --     |  |
| `ZFILER.COM`   |     --     |  |
| `ZHELP.COM`    |     --     |  |
| `ZP.COM`       |     --     |  |
| `ZSHOW.COM`    |     --     |  |
| `ZSID.COM`     |     --     |  |
| `ZXD.COM`      |     --     |  |
| `AUTOTOG.COM`  | ZPM3       |  |
| `CLRHIST.COM`  | ZPM3       |  |
| `SETZ3.COM`    | ZPM3       |  |
| `ASSIGN.COM`   | RomWBW     |  |
| `FAT.COM`      | RomWBW     |  |
| `FDU.COM`      | RomWBW     |  |
| `FORMAT.COM`   | RomWBW     |  |
| `INTTEST.COM`  | RomWBW     |  |
| `MODE.COM`     | RomWBW     |  |
| `RTC.COM`      | RomWBW     |  |
| `SURVEY.COM`   | RomWBW     |  |
| `SYSCOPY.COM`  | RomWBW     |  |
| `SYSGEN.COM`   | RomWBW     |  |
| `TALK.COM`     | RomWBW     |  |
| `TIMER.COM`    | RomWBW     |  |
| `TUNE.COM`     | RomWBW     |  |
| `XM.COM`       | RomWBW     |  |
| `CLRDIR.COM`   |     --     |  |
| `COMP.COM`     |     --     |  |
| `DDTZ.COM`     |     --     |  |
| `FDISK80.COM`  |     --     |  |
| `FLASH.COM`    |     --     |  |
| `NULU.COM`     |     --     |  |
| `TCVIEW.COM`   |     --     |  |
| `UNARC.COM`    |     --     |  |
| `Z3LOC.COM`    |     --     |  |
| `ZAP.COM`      |     --     |  |
| `ZDE.COM`      |     --     |  |
| `ZDENST.COM`   |     --     |  |

`\clearpage`{=latex}

# WordStar 4 Application Disk

| Floppy Disk Image: **fd_ws4.img**
| Hard Disk Image: **hd_ws4.img**
| Combo Disk Image: **Slice 5**

| **User 0**     | **Source** | **Description** |
| -------------- | ---------- | ------------------------------------------------------------ |
| `ANAGRAM.COM`  | WS4        | MicroPro WordStar 4 Distribution File |
| `CHAPTER1.DOC` | WS4        | MicroPro WordStar 4 Distribution File |
| `CHAPTER2.DOC` | WS4        | MicroPro WordStar 4 Distribution File |
| `CHAPTER3.DOC` | WS4        | MicroPro WordStar 4 Distribution File |
| `DIARY.DOC`    | WS4        | MicroPro WordStar 4 Distribution File |
| `DICTSORT.COM` | WS4        | MicroPro WordStar 4 Distribution File |
| `FIND.COM`     | WS4        | MicroPro WordStar 4 Distribution File |
| `HOMONYMS.TXT` | WS4        | MicroPro WordStar 4 Distribution File |
| `HYEXCEPT.TXT` | WS4        | MicroPro WordStar 4 Distribution File |
| `HYPHEN.COM`   | WS4        | MicroPro WordStar 4 Distribution File |
| `LOOKUP.COM`   | WS4        | MicroPro WordStar 4 Distribution File |
| `MAINDICT.CMP` | WS4        | MicroPro WordStar 4 Distribution File |
| `MARKFIX.COM`  | WS4        | MicroPro WordStar 4 Distribution File |
| `MOVEPRN.COM`  | WS4        | MicroPro WordStar 4 Distribution File |
| `PATCH.LST`    | WS4        | MicroPro WordStar 4 Distribution File |
| `PRINT.TST`    | WS4        | MicroPro WordStar 4 Distribution File |
| `READ.ME`      | WS4        | MicroPro WordStar 4 Distribution File |
| `README.`      | WS4        | MicroPro WordStar 4 Distribution File |
| `REVIEW.COM`   | WS4        | MicroPro WordStar 4 Distribution File |
| `RULER.DOC`    | WS4        | MicroPro WordStar 4 Distribution File |
| `SAMPLE1.DOC`  | WS4        | MicroPro WordStar 4 Distribution File |
| `SAMPLE2.DOC`  | WS4        | MicroPro WordStar 4 Distribution File |
| `SAMPLE3.DOC`  | WS4        | MicroPro WordStar 4 Distribution File |
| `SPELL.COM`    | WS4        | MicroPro WordStar 4 Distribution File |
| `TABLE.DOC`    | WS4        | MicroPro WordStar 4 Distribution File |
| `TEXT.DOC`     | WS4        | MicroPro WordStar 4 Distribution File |
| `TW.COM`       | WS4        | MicroPro WordStar 4 Distribution File |
| `WC.COM`       | WS4        | MicroPro WordStar 4 Distribution File |
| `WINSTALL.COM` | WS4        | MicroPro WordStar 4 Distribution File |
| `WORDFREQ.COM` | WS4        | MicroPro WordStar 4 Distribution File |
| `WS.COM`       | WS4        | MicroPro WordStar 4 Distribution File |
| `WS.OVR`       | WS4        | MicroPro WordStar 4 Distribution File |
| `WSCHANGE.COM` | WS4        | MicroPro WordStar 4 Distribution File |
| `WSCHANGE.OVR` | WS4        | MicroPro WordStar 4 Distribution File |
| `WSCHHELP.OVR` | WS4        | MicroPro WordStar 4 Distribution File |
| `WSHELP.OVR`   | WS4        | MicroPro WordStar 4 Distribution File |
| `WSINDEX.XCL`  | WS4        | MicroPro WordStar 4 Distribution File |
| `WSMSGS.OVR`   | WS4        | MicroPro WordStar 4 Distribution File |
| `WSPRINT.OVR`  | WS4        | MicroPro WordStar 4 Distribution File |
| `WSSHORT.OVR`  | WS4        | MicroPro WordStar 4 Distribution File |
