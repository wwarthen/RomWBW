# B/P Bios
# Banked and Portable Basic IO System

# 1 Introduction

The Banked and Portable (B/P) Basic I/O System (BIOS) is an effort to standardize many of the logical to physical mapping mechanisms on Microcomputers running Z-Systems with ZSDOS. In expanding the capabilities of such systems, it became apparent that standard BIOSes do not contain the functionality necessary, adequate standardization in extended BIOS calls, nor an internal structure to fully support external determination of system parameters. B/P Bios provides a method of achieving these goals, while also possessing the flexibility to operate on a wide range of hardware systems with a much smaller level of systems programming than previously required.


## 1.1 About This Manual

Documentation on B/P Bios consists of this manual plus the latest addendum on the distribution disk in the file README.2ND. This manual is divided into the following sections:

* The Features of B/P Bios summarizes the significant features of B/P Bios in general, highlighting advantages and the few limitations in the system.

* Tailoring B/P Bios contains details on altering the many options to generate a customized `.REL` file tailored to your system.

* Installing a B/P Bios details the installation of B/P Bios in both Unbanked and Banked configurations in a "how to" fashion.

* Programming for B/P Bios describes the interfaces, data structures and recommended programming practices to insure the maximum benefit and performance from systems with B/P Bios.

* The B/P Bios Utilities describes the purpose, operation, and customization of all supplied B/P Bios utilities and support routines.

* Appendices which summarize various technical information.

* A glossary defining many technical terms used in this Manual.

* An index of key words and phrases used in this Manual.

For those not interested in the technical details, or who want to bring the system up with a pre-configured version as quickly as possible, Section 4, Installing a B/P Bios, will lead you through the installation steps needed to perform the final tailoring to your specific computer. Other chapters cover details of the individual software modules comprising the B/P Bios, and specifics on the utilities provided to ease you use of this product.


## 1.2 Notational Conventions

Various shorthand terms and notations are used throughout this manual. Terms are listed in the Glossary at the end of this manual.

Though the symbols seem cryptic at first, they are a consistent way of briefly summarizing program syntax. Once you learn to read them you can tell at a glance how to enter even the most complicated commands.

Several special symbols are used in program syntax descriptions. By convention, square brackets (\[\]) indicate optional command line items. You may or may not include items shown between brackets in your command, but if you do not, programs usually substitute a default value of their own. If items between brackets are used in a command, all other items between the brackets must also be used, unless these items are themselves bracketed.

All of the support utilities developed to support the B/P Bios system contain built-in help screens which use the above conventions to display helpful syntax summaries. Help is always invoked by following the command with two slashes (`//`). So for example,

`ZXD //`

invokes help for ZXD, the ZSDOS extended directory program. Interactive ZSDOS programs such as BPCNFG2 also contain more detailed help messages which appear as a session progresses.

Many utilities may be invoked from the command line with options which command the programs to behave in slightly different ways. By convention, options are given after other command parameters. For example, the `P` option in the command

`ZXD *.* P`

causes the ZXD directory utility to list all files (*.*) and send its output to the printer (P). For convenience, a single slash character (/) can often be used in place of leading parameters to signify that the rest of the command line consists of option characters. Therefore, the command

`ZXD /P`

is identical in meaning to the previous example (see 6.23 for more on ZXD).


## 1.3 What is B/P Bios?

B/P Bios is a set of software subroutines which directly control the chips and other hardware in your computer and present a standard software interface to the Operating System such as our ZSDOS/ZDDOS, Echelon's ZRDOS, or even Digital Research's CP/M 2.2. These routines comply with the CP/M 2.2 standards for a Basic IO System (BIOS) with many extensions; some based on CP/M 3.x (aka CP/M Plus), and others developed to provide necessary capabilities of modern software. When properly coded, the modules comprising a B/P Bios perform with all the standard support utilities, nearly all Z-System utilities, and most application programs without alteration.

The ability to operate Banked, Non-banked and Boot System versions of the Bios with a single suite of software, across a number of different hardware machines, plus the maximization of Transient Program Area for application programs in banked systems are features which are offered by no other system of which we are aware.


## 1.4 The History of B/P Bios

Our earlier work developing ZSDOS convinced us that we needed to attack the machine-dependent software in Z80-compatible computers and develop some standard enhancements in order to exercise the full potential of our machines. This premise is even more true today with large Hard Disks (over 100 Megabytes) being very common, needs for large RAM Drives, and an ever shrinking Transient Program Area. Attempts to gain flexibility with normal operating systems were constrained by the 64k addressable memory range in Z80-compatible systems, and forced frequent operating system changes exemplified by NZCOM and NZBLITZ where different operating configurations could be quickly changed to accommodate application program needs.

In the mid to late 1980's, several efforts had been made to bank portions of CP/M 2.2 "type" systems. XBIOS was a banked Bios for only the HD64180-based MicroMint SB-180 family. While it displayed an excellent and flexible interface and the ability to operate with a variety of peripherals, it had several quirks and noticeably degraded the computer performance. A banked Bios was also produced for the XLM-180 single board S-100 computer, but required special versions of many Z-System utilities, and was not produced in any significant quantity. Other spinoffs, such as the Epson portable, attempted banking of the Bios, but most failed to achieve our comprehensive goals of compatibility with the existing software base, high performance, and portability.

In 1989, Cam developed the first prototype of B/P Bios in a Non-banked mode on his TeleTek while Hal concentrated on extending ZSDOS and the Command Processor. As of 1997, B/P Bios has been installed on:

| Computer | Features |
| :--- | :--- |
| YASBEC | Z180 CPU, FD1772 FDC, DP8490 SCSI, 1MB RAM |
| Ampro LB w/MDISK | Z80 CPU, FD1770 FDC, MDISK 1MB RAM |
| MicroMint SB-180 | HD64180 CPU, SMS9266 FDC, 256KB RAM |
| MicroMint SB180FX | HD64180Z CPU, SMS9266 FDC, 512KB RAM |
| Compu/Time S-100 | Z80 CPU, FD1795 FDC, 1 MB RAM |
| Teletek | Z80 CPU, NEC765 FDC, 64KB RAM |
| D-X Designs P112 | Z182 CPU, SMC FDC37C665 FDC, Flash ROM, 512KB RAM (mods for 5380 SCSI and GIDE) |

