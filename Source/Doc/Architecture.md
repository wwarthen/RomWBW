!include(Common.inc)
!def(document)(Architecture)
---
title: |
   | !product
   |
   | !document
author: !author (mailto:!authmail)
date: !date
institution: !orgname
documentclass: book
classoption:
- oneside
toc: true
toc-depth: 1
numbersections: true
secnumdepth: 1
papersize: letter
geometry:
- top=1.5in
- bottom=1.5in
- left=1.5in
- right=1.5in
# - showframe
# - pass
linestretch: 1.25
colorlinks: true
fontfamily: helvet
fontsize: 12pt
header-includes:
- \setlength{\headheight}{15pt}
- |
  ```{=latex}
  \usepackage{fancyhdr}
  \usepackage{xcolor}
  \usepackage{xhfill}
  \renewcommand*{\familydefault}{\sfdefault}
  \renewcommand{\maketitle}{
    \begin{titlepage}
      \centering
      \par
      \vspace*{0pt}
      \includegraphics[width=\paperwidth]{Graphics/Logo.pdf} \par
      \vfill
      \raggedleft
      {\scshape \bfseries \fontsize{48pt}{56pt} \selectfont !product \par}
      {\bfseries \fontsize{32pt}{36pt} \selectfont !document \par}
      \vspace{24pt}
      {\huge Version !ver \\ !date \par}
      \vspace{24pt}
      {\large \itshape !orgname \\ \href{http://!orgurl}{!orgurl} \par}
      \vspace{12pt}
      {\large \itshape !author \\ \href{mailto:authmail}{!authmail} \par}
    \end{titlepage}
  }
  \pagestyle{empty}
  ```
include-before:
- \renewcommand{\chaptername}{Section}
- |
  ```{=latex}
  \pagestyle{fancyplain}
  \fancyhf{}
  \lfoot{\small RetroBrew Computing Group ~~ {\xrfill[3pt]{1pt}[cyan]} ~~ \thepage}
  \pagenumbering{roman}
  ```
---

```{=latex}
\clearpage
\pagenumbering{arabic}
\lhead{\fancyplain{}{\nouppercase{\footnotesize \bfseries \leftmark \hfill !product  !document}}}
```

Overview
========

RomWBW provides a complete firmware package for all of the Z80 and Z180
based systems that are available in the RetroBrew Computers Community
(see
[http://www.retrobrewcomputers.org](http://www.retrobrewcomputers.org/))
as well as support for the RC2014 platform. Each of these systems
provides for a fairly large ROM memory (typically, 512KB or more).
RomWBW allows you to configure and build appropriate contents for such a
ROM.

Typically, a computer will contain a small ROM that contains the BIOS
(Basic Input/Output System) functions as well as code to start the
system by booting an operating system from a disk. Since the RetroBrew
Computers Projects provide a large ROM space, RomWBW provides a much
more comprehensive software package. In fact, it is entirely possible to
run a fully functioning RetroBrew Computers System with nothing but the
ROM.

RomWBW firmware includes:

* System startup code (bootstrap)

* A basic system/debug monitor

* HBIOS (Hardware BIOS) providing support for the vast majority of
RetroBrew Computers I/O components

* A complete operating system (either CP/M 2.2 or ZSDOS 1.1)

* A built-in CP/M filesystem containing the basic applications and
utilities for the operating system and hardware being used

It is appropriate to note that much of the code and components that make
up a complete RomWBW package are derived from pre-existing work. Most
notably, the embedded operating system is simply a ROM-based copy of
generic CP/M or ZSDOS. Much of the hardware support code was originally
produced by other members of the RetroBrew Computers Community.

The remainder of this document will focus on the HBIOS portion of the
ROM. HBIOS contains the vast majority of the custom-developed code for
the RetroBrew Computers hardware platforms. It provides a formal,
structured interface that allows the operating system to be hosted with
relative ease.

Background
==========

The Z80 CPU architecture has a limited, 64K address range. In general,
this address space must accommodate a running application, disk
operating system, and hardware support code.

All RetroBrew Computers Z80 CPU platforms provide a physical address
space that is much larger than the CPU address space (typically 512K or
1MB physical RAM). This additional memory can be made available to the
CPU using a technique called bank switching. To achieve this, the
physical memory is divided up into chunks (banks) of 32K each. A
designated area of the CPU's 64K address space is then reserved to "map"
any of the physical memory chunks. You can think of this as a window
that can be adjusted to view portions of the physical memory in 32K
blocks. In the case of RetroBrew Computers platforms, the lower 32K of
the CPU address space is used for this purpose (the window). The upper
32K of CPU address space is assigned a fixed 32K area of physical memory
that never changes. The lower 32K can be "mapped" on the fly to any of
the 32K banks of physical memory at a time. The only constraint is that
the CPU cannot be executing code in the lower 32K of CPU address space
at the time that a bank switch is performed.

By cleverly utilizing the pages of physical RAM for specific purposes
and swapping in the correct page when needed, it is possible to utilize
substantially more than 64K of RAM. Because the RetroBrew Computers
Project has now produced a very large variety of hardware, it has become
extremely important to implement a bank switched solution to accommodate
the maximum range of hardware devices and desired functionality.

General Design Strategy
=======================

The design goal is to locate as much of the hardware dependent code as
possible out of normal 64KB CP/M address space and into a bank switched
area of memory. A very small code shim (proxy) is located in the top 512
bytes of CPU memory. This proxy is responsible for redirecting all
hardware BIOS (HBIOS) calls by swapping the "driver code" bank of
physical RAM into the lower 32K and completing the request. The
operating system is unaware this has occurred. As control is returned to
the operating system, the lower 32KB of memory is switched back to the
original memory bank.

HBIOS is completely agnostic with respect to the operating system (it
does not know or care what operating system is using it). The operating
system makes simple calls to HBIOS to access any desired hardware
functions. Since the HBIOS proxy occupies only 512 bytes at the top of
memory, the vast majority of the CPU memory is available to the
operating system and the running application. As far as the operating
system is concerned, all of the hardware driver code has been magically
implemented inside of a small 512 byte area at the top of the CPU
address space.

Unlike some other Z80 bank switching schemes, there is no attempt to
build bank switching into the operating system itself. This is
intentional so as to ensure that any operating system can easily be
adapted without requiring invasive modifications to the operating system
itself. This also keeps the complexity of memory management completely
away from the operating system and applications.

There are some operating systems that have built-in support for bank
switching (e.g., CP/M 3). These operating systems are allowed to make
use of the bank switched memory and are compatible with HBIOS. However,
it is necessary that the customization of these operating systems take
into account the banks of memory used by HBIOS and not attempt to use
those specific banks.

Note that all code and data are located in RAM memory during normal
execution. While it is possible to use ROM memory to run code, it would
require that more upper memory be reserved for data storage. It is
simpler and more memory efficient to keep everything in RAM. At startup
(boot) all required code is copied to RAM for subsequent execution.

Runtime Memory Layout
=====================

![Banked Switched Memory Layout](Graphics/Bank Switched Memory){ width=80% }

System Boot Process
===================

A multi-phase boot strategy is employed. This is necessary because at
cold start, the CPU is executing code from ROM in lower memory which is
the same area that is bank switched.

Boot Phase 1 copies the phase 2 code to upper memory and jumps to it to
continue the boot process. This is required because the CPU starts at
address \$0000 in low memory. However, low memory is used as the area
for switching ROM/RAM banks in and out. Therefore, it is necessary to
relocate execution to high memory in order to initialize the RAM memory
banks.

Boot Phase 2 manages the setup of the RAM page banks for HBIOS
operation, performs hardware initialization, and then executes the boot
loader.

Boot Phase 3 is the loading of the selecting operating system (or debug
monitor) by the Boot Loader. The Boot Loader is responsible for
prompting the user to select a target operating system to load, loading
it into RAM, then transferring control to it. The Boot Loader is capable
of loading a target operating system from a variety of locations
including disk drives and ROM.

Note that the entire boot process is entirely operating system agnostic.
It is unaware of the operating system being loaded. The Boot Loader
prompts the user for the location of the binary image to load, but does
not know anything about what is being loaded (the image is usually an
operating system, but could be any executable code image). Once the Boot
Loader has loaded the image at the selected location, it will transfer
control to it. Assuming the typical situation where the image was an
operating system, the loaded operating system will then perform it's own
initialization and begin normal operation.

There are actually two ways to perform a system boot. The first, and
most commonly used, method is a "ROM Boot". This refers to booting the
system directly from the startup code contained on the physical ROM
chip. A ROM Boot is always performed upon power up or when a hardware
reset is performed.

Once the system is running (operating system loaded), it is possible to
reboot the system from a system image contained on the file system. This
is referred to as an "Application Boot". This mechanism allows a
temporary copy of the system to be uploaded and stored on the file
system of an already running system and then used to boot the system.
This boot technique is useful to: 1) test a new build of a system image
before programming it to the ROM; or 2) easily switch between system
images on the fly.

A more detailed explanation of these two boot processes is presented
below.

ROM Boot
--------

At power on (or hardware reset), ROM page 0 is automatically mapped to
lower memory by hardware level system initialization. Page Zero (first
256 bytes of the CPU address space) is reserved to contain dispatching
instructions for interrupt instructions. Address \$0000 performs a jump
to the start of the phase 1 code so that this first page can be
reserved.

The phase 1 code now copies the phase 2 code from lower memory to upper
memory and jumps to it. The phase 2 code now initializes the HBIOS by
copying the ROM resident HBIOS from ROM to RAM. It subsequently calls
the HBIOS initialization routine. Finally, it starts the Boot Loader
which prompts the user for the location of the target system image to
execute.

Once the boot loader transfers control to the target system image, all
of the Phase 1, Phase 2, and Boot Loader code is abandoned and the space
it occupied is normally overwritten by the operating system.

Application Boot
----------------

When a new system image is built, one of the output files produced is an
actual CP/M application (an executable .COM program file). Once you have
a running CP/M (or compatible) system, you can upload/copy this
application file to the filesystem. By executing this file, you will
initiate an Application Boot using the system image contained in the
application file itself.

Upon execution, the Application Boot program is loaded into memory by
the previously running operating system starting at \$0100. Note that
program image contains a copy of the HBIOS to be installed and run. Once
the Application Boot program is loaded by the previous operating system,
control is passed to it and it performs a system initialization similar
to the ROM Boot, but using the image loaded in RAM.

Specifically, the code at \$0100 (in low memory) copies phase 2 boot
code to upper memory and transfers control to it. The phase 2 boot code
copies the HBIOS image from application RAM to RAM, then calls the HBIOS
initialization routine. At this point, the prior HBIOS code has been
discarded and overwritten. Finally, the Boot Loader is invoked just like
a ROM Boot.

Notes
-----

1. Size of ROM disk and RAM disk will be decreased as needed to
accommodate RAM and ROM memory bank usage for the banked BIOS.

2. There is no support for interrupt driven drivers at this time. Such
support should be possible in a variety of ways, but none are yet
implemented.

Driver Model
============

The framework code for bank switching also allows hardware drivers to be
implemented mostly without concern for memory management. Drivers are
coded to simply implement the HBIOS functions appropriate for the type
of hardware being supported. When the driver code gets control, it has
already been mapped to the CPU address space and simply performs the
requested function based on parameters passed in registers. Upon return,
the bank switching framework takes care of restoring the original memory
layout expected by the operating system and application.

However, the one constraint of hardware drivers is that any data buffers
that are to be returned to the operating system or applications must be
allocated in high memory. Buffers inside of the driver's memory bank
will be swapped out of the CPU address space when control is returned to
the operating system.

If the driver code must make calls to other code, drivers, or utilities
in the driver bank, it must make those calls directly (it must not use
RST 08). This is to avoid a nested bank switch which is not supported at
this time.

Character / Emulation / Video Services
======================================

In addition to a generic set of routines to handle typical character
input/output, HBIOS also includes functionality for managing built-in
video display adapters. To start with there is a basic set of character
input/output functions, the CIOXXX functions, which allow for simple
character data streams. These functions fully encompass routing byte
stream data to/from serial ports. Note that there is a special character
pseudo-device called "CRT". When characters are read/written to/from the
CRT character device, the data is actually passed to a built-in terminal
emulator which, in turn, utilizes a set of VDA (Video Display Adapter)
functions (such as cursor positioning, scrolling, etc.).

Figure 7.1 depicts the relationship between these components
of HBIOS video processing:

![Character / Emulation / Video Services](Graphics/Character Emulation Video Services){ width=100% }

Normally, the operating system will simply utilize the CIOXXX functions
to send and receive character data. The Character I/O Services will
route I/O requests to the specified physical device which is most
frequently a serial port (such as UART or ASCI). As shown above, if the
CRT device is targeted by a CIOXXX function, it will actually be routed
to the Emulation Services which implement TTY, ANSI, etc. escape
sequences. The Emulation Services subsequently rely on the Video Display
Adapter Services as an additional layer of abstraction. This allows the
emulation code to be completely unaware of the actual physical device
(device independent). Video Display Adapter (VDA) Services contains
drivers as needed to handle the available physical video adapters.

Note that the Emulation and VDA Services API functions are available to
be called directly. Doing so must be done carefully so as to not corrupt
the "state" of the emulation logic.

Before invoking CIOXXX functions targeting the CRT device, it is
necessary that the underlying layers (Emulation and VDA) be properly
initialized. The Emulation Services must be initialized to specify the
desired emulation and specific physical VDA device to target. Likewise,
the VDA Services may need to be initialized to put the specific video
hardware into the proper mode, etc.

HBIOS Reference
===============

Invocation
----------

HBIOS functions are invoked by placing the required parameters in CPU
registers and executing an RST 08 instruction. Note that HBIOS does not
preserve register values that are unused. However, it will not modify the
Z80 alternate registers or IX/IY (these registers may be used within HBIOS,
but will be saved and restored internally).

Normally, applications will not call HBIOS functions directly. It is
intended that the operating system makes all HBIOS function calls.
Applications that are considered system utilities may use HBIOS, but must
be careful not to modify the operating environment in any way that the
operating system does not expect.

In general, the desired function is placed in the B register. Register C is
frequently used to specify a subfunction or a target device unit number.
Additional registers are used as defined by the specific function. Register
A should be used to return function result information. A=0 should
indicate success, other values are function specific.

The character, disk, and video device functions all refer to target devices
using a logical device unit number that is passed in the C register. Keep
in mind that these unit numbers are assigned dynamically at HBIOS
initialization during the device discovery process. The assigned unit
numbers are displayed on the consoled at the conclusion of device
initialization. The unit assignments will never change after HBIOS
initialization. However, they can change at the next boot if there have
been hardware or BIOS customization changes. Code using HBIOS functions
should not assume fixed unit assignments.

Some functions utilize pointers to memory buffers. Unless otherwise stated,
such buffers can be located anywhere in the Z80 CPU 64K address space.
However, performance sensitive buffers (primarily disk I/O buffers) will
require double-buffering if the caller’s buffer is in the lower 32K of CPU
address space. For optimal performance, such buffers should be placed in
the upper 32K of CPU address space.

Error Codes
-----------

The following error codes are defined generically for all HBIOS functions.
Most function calls will return a result in register A.

_Code_ | _Meaning_
------ | ---------
0      | function succeeded
-1     | undefined error
-2     | function not implemented
-3     | invalid function
-4     | invalid unit numberr
-5     | out of memory
-6     | parameter out of range
-7     | media not present
-8     | hardware not present
-9     | I/O error
-10    | write request to read-only media
-11    | device timeout
-12    | invalid configuration

`\clearpage`{=latex}

Character Input/Output (CIO)
----------------------------

Character input/output functions require that a Character Unit be specified
in the C register. This is the logical device unit number assigned during
the boot process that identifies all character I/O devices uniquely. A
special value of 0x80 can be used for Unit to refer to the current console
device.

Character devices can usually be configured with line characteristics
such as speed, framing, etc. A word value (16 bit) is used to describe
the line characteristics as indicated below:

_Bits_ | _Function_
------ | ----------
15-14  | Reserved (set to 0)
13     | RTS
12-8   | Baud Rate (see below)
7      | DTR
6      | XON/XOFF Flow Control
5-3    | Parity (???)
2      | Stop Bits (???)
1-0    | Data Bits (???)

The 5-bit baud rate value (V) is encoded as V = 75 \* 2\^X \* 3\^Y. The
bits are defined as YXXXX.

### Function 0x00 -- Character Input (CIOIN)

| _Entry Parameters_
|       B: 0x00
|       C: Serial Device Unit Number

| _Exit Results_
|       A: Status (0=OK, else error)
|       E: Character Received

Read a character from the device unit specified in register C and return
the character value in E. If no character(s) are available, this function
will wait indefinitely.

### Function 0x01 -- Character Output (CIOOUT)

| _Entry Parameters_
|       B: 0x01
|       C: Serial Device Unit Number
|       E: Character to Send

| _Exit Results_
|       A: Status (0=OK, else error)

Send character value in register E to device specified in register C. If
device is not ready to send, function will wait indefinitely.

### Function 0x02 -- Character Input Status (CIOIST)

| _Entry Parameters_
|       B: 0x02
|       C: Serial Device Unit Number

| _Exit Results_
|       A: Bytes Pending

Return the number of characters available to read in the input buffer of
the unit specified. If the device has no input buffer, it is acceptable to
return simply 0 or 1 where 0 means there is no character available to read
and 1 means there is at least one character available to read.

### Function 0x03 -- Character Output Status (CIOOST)

| _Entry Parameters_
|       B: 0x03
|       C: Serial Device Unit Number

| _Exit Results_
|       A: Output Buffer Bytes Available

Return the space available in the output buffer expressed as a character
count. If a 16 byte output buffer contained 6 characters waiting to be
sent, this function would return 10, the number of positions available in
the output buffer. If the port has no output buffer, it is acceptable to
return simply 0 or 1 where 0 means the port is busy and 1 means the port is
ready to output a character.

### Function 0x04 -- Character IO Initialization (CIOINIT)

| _Entry Parameters_
|       B: 0x04
|       C: Serial Device Unit Number
|       DE: Line Characteristics

| _Exit Results_
|       A: Status (0=OK, else error)

Setup line characteristics (baudrate, framing, etc.) of the specified unit.
Register pair DE specifies line characteristics. If DE contains -1
(0xFFFF), then the device will be reinitialized with the last line
characteristics used. Result of function is returned in A with zero
indicating success.

### Function 0x05 -- Character IO Query (CIOQUERY)

| _Entry Parameters_
|       B: 0x05
|       C: Serial Device Unit Number

| _Exit Results_
|       A: Status (0=OK, else error)
|       DE: Line Characteristics

Reports the line characteristics (baudrate, framing, etc.) of the specified
unit. Register pair DE contains the line characteristics upon return.

### Function 0x06 -- Character IO Device (CIODEVICE)

| _Entry Parameters_
|       B: 0x06
|       C: Serial Device Unit Number

| _Exit Results_
|       A: Status (0=OK, else error)
|       C: Serial Device Attributes
|       D: Serial Device Type
|       E: Serial Device Number
|       H: Serial Device Unit Mode
|       L: Serial Device Unit I/O Base Address

Reports information about the character device unit specified. Register C
indicates the device attributes: 0=RS-232 and 1=Terminal. Register D
indicates the device type (driver) and register E indicates the physical
device number assigned by the driver.

Each character device is handled by an appropriate driver (UART, ASCI,
etc.). The driver can be identified by the Device Type. The assigned Device
Types are listed below.

_Id_ | _Device Type / Driver_
---- | ----------------------
0x00 | UART
0x10 | ASCI
0x20 | Terminal
0x30 | PropIO VGA
0x40 | ParPortProp VGA
0x50 | SIO
0x60 | ACIA
0x70 | PIO
0x80 | UF

`\clearpage`{=latex}

Disk Input/Output (DIO)
-----------------------

Character input/output functions require that a character unit be specified
in the C register. This is the logical disk unit number assigned during
the boot process that identifies all disk i/o devices uniquely.

A fixed set of media types are defined. The currently defined media types
are listed below. Each driver will support a subset of the defined media
types.

**Media ID** | **Value** | **Format**
------------ | --------- | ----------
MID\_NONE    | 0         | No media installed
MID\_MDROM   | 1         | ROM Drive
MID\_MDRAM   | 2         | RAM Drive
MID\_RF      | 3         | RAM Floppy (LBA)
MID\_HD      | 4         | Hard Disk (LBA)
MID\_FD720   | 5         | 3.5" 720K Floppy
MID\_FD144   | 6         | 3.5" 1.44M Floppy
MID\_FD360   | 7         | 5.25" 360K Floppy
MID\_FD120   | 8         | 5.25" 1.2M Floppy
MID\_FD111   | 9         | 8" 1.11M Floppy

### Function 0x10 -- Disk Status (DIOSTATUS)

| _Entry Parameters_
|       B: 0x10

| _Exit Results_
|       A: Status (0=OK, else error)

### Function 0x11 -- Disk Status (DIORESET)

| _Entry Parameters_
|       B: 0x11
|       C: Disk Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)

Reset the physical interface associated with the specified unit. Flag
all units associated with the interface for unit initialization at next
I/O call. Clear media identified unless locked. Reset result code of all
associated units of the physical interface.

### Function 0x12 -- Disk Seek (DIOSEEK)

| _Entry Parameters_
|       B: 0x12
|       C: Disk Device Unit ID
|       D7: Address Type (0=CHS, 1=LBA)

|       if CHS:
|           D6-0: Head
|           E: Sector
|           HL: Track

|       if LBA:
|           DE:HL: Block Address

| _Exit Results_
|       A: Status (0=OK, else error)

Update target CHS or LBA for next I/O request on designated unit. Physical
seek is typically deferred until subsequent I/O operation.

Bit 7 of D indicates whether the disk seek address is specified as
cylinder/head/sector (CHS) or Logical Block Address (LBA). If D:7=1, then
the remaining bits of of the 32 bit register set DE:HL specify a linear,
zero offset, block number. If D:7=0, then the remaining bits of D specify
the head, E specifies sector, and HL specifies track.

Note that not all devices will accept both types of addresses.
Specifically, floppy disk devices must have CHS addresses. All other
devices will accept either CHS or LBA. The DIOGEOM function can be used to
determine if the device supports LBA addressing.

### Function 0x13 -- Disk Read (DIOREAD)

| _Entry Parameters_
|       B: 0x13
|       C: Disk Device Unit ID
|       E: Block Count
|       HL: Buffer Address

| _Exit Results_
|       A: Status (0=OK, else error)
|       E: Blocks Read

Read Block Count sectors to buffer address starting at current target
sector. Current sector must be established by prior seek function; however,
multiple read/write/verify function calls can be made after a seek
function. Current sector is incremented after each sector successfully
read. On error, current sector is sector is sector where error occurred.
Blocks read indicates number of sectors successfully read.

Caller must ensure: 1) buffer address is large enough to contain data for
all sectors requested, and 2) entire buffer area resides in upper 32K of
memory.

### Function 0x14 -- Disk Write (DIOWRITE)

| _Entry Parameters_
|       B: 0x14
|       C: Disk Device Unit ID
|       E: Block Count
|       HL: Buffer Address

| _Exit Results_
|       A: Status (0=OK, else error)
|       E: Blocks Written

Write Block Count sectors to buffer address starting at current target
sector. Current sector must be established by prior seek function; however,
multiple read/write/verify function calls can be made after a seek
function. Current sector is incremented after each sector successfully
written. On error, current sector is sector is sector where error occurred.
Blocks written indicates number of sectors successfully written.

Caller must ensure: 1) buffer address is large enough to contain data for
all sectors being written, and 2) entire buffer area resides in upper 32K
of memory.

### Function 0x15 -- Disk Verify (DIOVERIFY)

| _Entry Parameters_
|       B: 0x15
|       C: Disk Device Unit ID
|       HL: Buffer Address
|       E: Block Count

| _Exit Results_
|       A: Status (0=OK, else error)
|       E: Blocks Verified

\*\*\*Not Implemented\*\*\*

### Function 0x16 -- Disk Format (DIOFORMAT)

| _Entry Parameters_
|       B: 0x16
|       C: Disk Device Unit ID
|       D: Head
|       E: Fill Byte
|       HL: Cylinder

| _Exit Results_
|       A: Status (0=OK, else error)

\*\*\*Not Implemented\*\*\*

### Function 0x17 -- Disk DEVICE (DIODEVICE)

| _Entry Parameters_
|       B: 0x17
|       C: Disk Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)
|       C: Attributes
|       D: Device Type
|       E: Device Number
|       H: Disk Device Unit Mode
|       L: Disk Device Unit I/O Base Address

Reports information about the character device unit specified. Register D
indicates the device type (driver) and register E indicates the physical
device number assigned by the driver.

Register C reports the following device attributes:

Bit 7: 1=Floppy, 0=Hard Disk (or similar, e.g. CF, SD, RAM)

| If Floppy:
|     Bits 6-5: Form Factor (0=8", 1=5.25", 2=3.5", 3=Other)
|     Bit 4: Sides (0=SS, 1=DS)
|     Bits 3-2: Density (0=SD, 1=DD, 2=HD, 3=ED)
|     Bits 1-0: Reserved

| If Hard Disk:
|     Bit 6: Removable\
|     Bits: 5-3: Type (0=Hard, 1=CF, 2=SD, 3=USB,
|                      4=ROM, 5=RAM, 6=RAMF, 7=Reserved)
|     Bits 2-0: Reserved

Each disk device is handled by an appropriate driver (IDE, SD,
etc.) which is identified by a device type id from the table below.

**Type ID** | **Disk Device Type**
----------- | --------------------
0x00        | Memory Disk
0x10        | Floppy Disk
0x20        | RAM Floppy
0x30        | IDE Disk
0x40        | ATAPI Disk (not implemented)
0x50        | PPIDE Disk
0x60        | SD Card
0x70        | PropIO SD Card
0x80        | ParPortProp SD Card
0x90        | SIMH HDSK Disk

### Function 0x18 -- Disk Media (DIOMEDIA)

| _Entry Parameters_
|       B: 0x18
|       C: Disk Device Unit ID
|       E0: Enable Media Discovery

| _Exit Results_
|       A: Status (0=OK, else error)
|       E: Media ID

Report the media definition for media in specified unit. If bit 0 of E is
set, then perform media discovery or verification. If no media in device,
function will return an error status.

### Function 0x19 -- Disk Define Media (DIODEFMED)

| _Entry Parameters_
|       B: 0x19
|       C: Disk Device Unit ID
|       E: Media ID

| _Exit Results_
|       A: Status (0=OK, else error)

\*\*\* Not implemented \*\*\*

### Function 0x1A -- Disk Capacity (DIOCAPACITY)

| _Entry Parameters_
|       B: 0x1A
|       C: Disk Device Unit ID
|       HL: Buffer Address

| _Exit Results_
|       A: Status (0=OK, else error)
|       DE:HL: Blocks on Device
|       BC: Block Size

Report current media capacity information. DE:HL is a 32 bit number
representing the total number of blocks on the device. BC contains the
block size. If media is unknown, an error will be returned.

### Function 0x1B -- Disk Geometry (DIOGEOMETRY)

| _Entry Parameters_
|       B: 0x1B
|       C: Disk Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)
|       HL: Cylinders
|       D7: LBA Capability
|       BC: Block Size

Report current media geometry information. If media is unknown, return
error (no media).

`\clearpage`{=latex}

Real Time Clock (RTC)
---------------------

The Real Time Clock functions provide read/write access to the clock and
related Non-Volatile RAM.

The time functions (RTCGTM and RTCSTM) require a 6 byte date/time buffer
of the following format. Each byte is BCD encoded.

**Offset** | **Contents**
---------- | ------------
0          | Year (00-99)
1          | Month (01-12)
2          | Date (01-31)
3          | Hours (00-24)
4          | Minutes (00-59)
5          | Seconds (00-59)

### Function 0x20 -- RTC Get Time (RTCGETTIM)

| _Entry Parameters_
|       B: 0x20
|       HL: Time Buffer Address

| _Exit Results_
|       A: Status (0=OK, else error)

Read the current value of the clock and store the date/time in the
buffer pointed to by HL.

### Function 0x21 -- RTC Set Time (RTCSETTIM)

| _Entry Parameters_
|       B: 0x21
|       HL: Time Buffer Address

| _Exit Results_
|       A: Status (0=OK, else error)

Set the current value of the clock based on the date/time in the buffer
pointed to by HL.

### Function 0x22 -- RTC Get NVRAM Byte (RTCGETBYT)

| _Entry Parameters_
|       B: 0x22
|       C: Index

| _Exit Results_
|       A: Status (0=OK, else error)
|       E: Value

Read a single byte value from the Non-Volatile RAM at the index specified
by C. The value is returned in register E.

### Function 0x23 -- RTC Set NVRAM Byte (RTCSETBYT)

| _Entry Parameters_
|       B: 0x23
|       C: Index

| _Exit Results_
|       A: Status (0=OK, else error)
|       E: Value

Write a single byte value into the Non-Volatile RAM at the index specified
by C. The value to be written is specified in E.

### Function 0x24 -- RTC Get NVRAM Block (RTCGETBLK)

| _Entry Parameters_
|       B: 0x24
|       HL: Buffer

| _Exit Results_
|       A: Status (0=OK, else error)

Read the entire contents of the Non-Volatile RAM into the buffer pointed
to by HL. HL must point to a location in the top 32K of CPU address space.

### Function 0x25 -- RTC Set NVRAM Block (RTCSETBLK)

| _Entry Parameters_
|       B: 0x25
|       HL: Buffer

| _Exit Results_
|       A: Status (0=OK, else error)

Write the entire contents of the Non-Volatile RAM from the buffer pointed
to by HL. HL must point to a location in the top 32K of CPU address space.

### Function 0x26 -- RTC Get Alarm (RTCGETALM)

| _Entry Parameters_
|       B: 0x26

| _Exit Results_
|       A: Status (0=OK, else error)

Documentation required...

### Function 0x27 -- RTC Set Alarm (RTCSETALM)

| _Entry Parameters_
|       B: 0x27

| _Exit Results_
|       A: Status (0=OK, else error)

Documentation required...

### Function 0x28 -- RTC DEVICE (RTCDEVICE)

| _Entry Parameters_
|       B: 0x28
|       C: RTC Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)
|       D: Device Type
|       E: Device Number
|       H: RTC Device Unit Mode
|       L: RTC Device Unit I/O Base Address

Reports information about the RTC device unit specified. Register D
indicates the device type (driver) and register E indicates the physical
device number assigned by the driver.

Each RTC device is handled by an appropriate driver (DSRTC, BQRTC,
etc.) which is identified by a device type id from the table below.

**Type ID** | **Disk Device Type**
----------- | --------------------
0x00        | DS1302
0x10        | BQ4845P
0x20        | SIMH
0x30        | System Periodic Timer

`\clearpage`{=latex}

Video Display Adapter (VDA)
---------------------------

The VDA functions are provided as a common interface to Video Display
Adapters. Not all VDAs will include keyboard hardware. In this case, the
keyboard functions should return a failure status.

Depending on the capabilities of the hardware, the use of colors and
attributes may or may not be supported. If the hardware does not support
these capabilities, they will be ignored.

Color byte values are constructed using typical RGBI
(Red/Green/Blue/Intensity) bits. The high four bits of the value determine
the background color and the low four bits determine the foreground color.
This results in 16 unique color values for both foreground and background.
The following table illustrates the color byte value construction:

&nbsp;     | **Bit** | **Color**
---------- | ------- | ---------
Background | 7       | Intensity
&nbsp;     | 6       | Blue
&nbsp;     | 5       | Green
&nbsp;     | 4       | Red
Foreground | 3       | Intensity
&nbsp;     | 2       | Blue
&nbsp;     | 1       | Green
&nbsp;     | 0       | Red

The following table illustrates the resultant color for each of the
possible 16 values for foreground or background:

**Foreground**     | **Background**     | **Color**
------------------ | ------------------ | ----------------
\_0   \_\_\_\_0000 | 0\_   0000\_\_\_\_ | Black
\_1   \_\_\_\_0001 | 1\_   0001\_\_\_\_ | Red
\_2   \_\_\_\_0010 | 2\_   0010\_\_\_\_ | Green
\_3   \_\_\_\_0011 | 3\_   0011\_\_\_\_ | Brown
\_4   \_\_\_\_0100 | 4\_   0100\_\_\_\_ | Blue
\_5   \_\_\_\_0101 | 5\_   0101\_\_\_\_ | Magenta
\_6   \_\_\_\_0110 | 6\_   0110\_\_\_\_ | Cyan
\_7   \_\_\_\_0111 | 7\_   0111\_\_\_\_ | White
\_8   \_\_\_\_1000 | 8\_   1000\_\_\_\_ | Gray
\_9   \_\_\_\_1001 | 9\_   1001\_\_\_\_ | Light Red
\_A   \_\_\_\_1010 | A\_   1010\_\_\_\_ | Light Green
\_B   \_\_\_\_1011 | B\_   1011\_\_\_\_ | Yellow
\_C   \_\_\_\_1100 | C\_   1100\_\_\_\_ | Light Blue
\_D   \_\_\_\_1101 | D\_   1101\_\_\_\_ | Light Magenta
\_E   \_\_\_\_1110 | E\_   1110\_\_\_\_ | Light Cyan
\_F   \_\_\_\_1111 | F\_   1111\_\_\_\_ | Bright White

Attribute byte values are constructed using the following bit encoding:

**Bit** | **Effect**
------- | ----------
7       | n/a (0)
6       | n/a (0)
5       | n/a (0)
4       | n/a (0)
3       | n/a (0)
2       | Reverse
1       | Underline
0       | Blink

The following codes are returned by a keyboard read to signify non-ASCII
keystrokes:

**Value** | **Keystroke** | **Value** | **Keystroke**
--------- | ------------- | --------- | -------------
0xE0      | F1            | 0xF0      | Insert
0xE1      | F2            | 0xF1      | Delete
0xE2      | F3            | 0xF2      | Home
0xE3      | F4            | 0xF3      | End
0xE4      | F5            | 0xF4      | PageUp
0xE5      | F6            | 0xF5      | PadeDown
0xE6      | F7            | 0xF6      | UpArrow
0xE7      | F8            | 0xF7      | DownArrow
0xE8      | F9            | 0xF8      | LeftArrow
0xE9      | F10           | 0xF9      | RightArrow
0xEA      | F11           | 0xFA      | Power
0xEB      | F12           | 0xFB      | Sleep
0xEC      | SysReq        | 0xFC      | Wake
0xED      | PrintScreen   | 0xFD      | Break
0xEE      | Pause         | 0xFE      |
0xEF      | App           | 0xFF      |

### Function 0x40 -- Video Initialize (VDAINI)

| _Entry Parameters_
|       B: 0x40
|       C: Video Device Unit ID
|       E: Video Mode (device specific)
|       HL: Font Bitmap Buffer Address (optional)

| _Exit Results_
|       A: Status (0=OK, else error)

Performs a full (re)initialization of the specified video device. The
screen is cleared and the keyboard buffer is flushed. If the specified
VDA supports multiple video modes, the requested mode can be specified
in E (set to 0 for default/not specified). Mode values are specific to
each VDA.

HL may point to a location in memory with the character bitmap to be
loaded into the VDA video processor. The location MUST be in the top 32K
of the CPU memory space. HL must be set to zero if no character bitmap
is specified (the VDA video processor will utilize a default character
bitmap).

### Function 0x41 -- Video Query (VDAQRY)

| _Entry Parameters_
|       B: 0x41
|       C: Video Device Unit ID
|       HL: Font Bitmap Buffer Address (optional)

| _Exit Results_
|       A: Status (0=OK, else error)
|       C: Video Mode
|       D: Row Count
|       E: Column Count
|       HL: Font Bitmap Buffer Address (0 if N/A)

Return information about the specified video device. C will be set to
the current video mode. DE will return the dimensions of the video
display as measured in rows and columns. Note that this is the **count**
of rows and columns, not the **last** row/column number.

If HL is not zero, it must point to a suitably sized memory buffer in
the upper 32K of CPU address space that will be filled with the current
character bitmap data. It is critical that HL be set to zero if it does
not point to a proper buffer area or memory corruption will result. The
video device driver may not have the ability to provide character bitmap
data. In this case, on return, HL will be set to zero.

### Function 0x42 -- Video Reset (VDARES)

| _Entry Parameters_
|       B: 0x42
|       C: Video Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)

Performs a soft reset of the Video Display Adapter. Should clear the
screen, home the cursor, restore active attribute and color to defaults.
Keyboard should be flushed.

### Function 0x43 -- Video Device (VDADEV)

| _Entry Parameters_
|       B: 0x43
|       C: Video Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)
|       D: Device Type
|       E: Device Number
|       H: VDA Device Unit Mode
|       L: VDA Device Unit I/O Base Address

Reports information about the video device unit specified.

Register D reports the video device type (see below).

Register E reports the driver relative physical device number.

The currently defined video device types are:

VDA ID     | Value | Device
---------- | ----- | ------
VDA\_NONE  | 0x00  | No VDA
VDA\_VDU   | 0x10  | ECB VDU board
VDA\_CVDU  | 0x20  | ECB Color VDU board
VDA\_7220  | 0x30  | ECB uPD7220 video display board
VDA\_N8    | 0x40  | TMS9918 video display built-in to N8
VDA\_VGA   | 0x50  | ECB VGA board

### Function 0x44 -- Video Set Cursor Style (VDASCS)

| _Entry Parameters_
|       B: 0x44
|       C: Video Device Unit ID
|       D: Start/End Pixel Row
|       E: Style

| _Exit Results_
|       A: Status (0=OK, else error)

If supported by the video hardware, adjust the format of the cursor such
that the cursor starts at the pixel specified in the top nibble of D and
end at the pixel specified in the bottom nibble of D. So, if D=\$08, a
block cursor would be used that starts at the top pixel of the character
cell and ends at the ninth pixel of the character cell.

Register E is reserved to control the style of the cursor (blink,
visibility, etc.), but is not yet implemented.

Adjustments to the cursor style may or may not be possible for any given
video hardware.

### Function 0x45 -- Video Set Cursor Position (VDASCP)

| _Entry Parameters_
|       B: 0x45
|       C: Video Device Unit ID
|       D: Row (0 indexed)
|       E: Column (0 indexed)

| _Exit Results_
|       A: Status (0=OK, else error)

Reposition the cursor to the specified row and column. Specifying a
row/column that exceeds the boundaries of the display results in
undefined behavior. Cursor coordinates are 0 based (0,0 is the upper
left corner of the display).

### Function 0x46 -- Video Set Character Attribute (VDASAT)

| _Entry Parameters_
|       B: 0x46
|       C: Video Device Unit ID
|       E: Character Attribute Code

| _Exit Results_
|       A: Status (0=OK, else error)

Assign the specified character attribute code to be used for all
subsequent character writes/fills. This attribute is used to fill new
lines generated by scroll operations. Refer to the character attribute
for a list of the available attribute codes. Note that a given video
display may or may not support any/all attributes.

### Function 0x47 -- Video Set Character Color (VDASCO)

| _Entry Parameters_
|       B: 0x47
|       C: Video Device Unit ID
|       E: Character Color Code

| _Exit Results_
|       A: Status (0=OK, else error)

Assign the specified color code to be used for all subsequent character
writes/fills. This color is also used to fill new lines generated by
scroll operations. Refer to color code table for a list of the available
color codes. Note that a given video display may or may not support
any/all colors.

### Function 0x48 -- Video Set Write Character (VDAWRC)

| _Entry Parameters_
|       B: 0x48
|       C: Video Device Unit ID
|       E: Character

| _Exit Results_
|       A: Status (0=OK, else error)

Write the character specified in E. The character is written starting at
the current cursor position and the cursor is advanced. If the end of
the line is encountered, the cursor will be advanced to the start of the
next line. The display will **not** scroll if the end of the screen is
exceeded.

### Function 0x49 -- Video Fill (VDAFIL)

| _Entry Parameters_
|       B: 0x49
|       C: Video Device Unit ID
|       E: Character
|       HL: Count

| _Exit Results_
|       A: Status (0=OK, else error)

Write the character specified in E to the display the number of times
specified in HL. Characters are written starting at the current cursor
position and the cursor is advanced by the number of characters written.
If the end of the line is encountered, the characters will continue to
be written starting at the next line as needed. The display will **not**
scroll if the end of the screen is exceeded.

### Function 0x4A -- Video Copy (VDACPY)

| _Entry Parameters_
|       B: 0x4A
|       C: Video Device Unit ID
|       D: Source Row
|       E: Source Column
|       L: Count

| _Exit Results_
|       A: Status (0=OK, else error)

Copy count (L) bytes from the source row/column (DE) to current cursor
position. The cursor position is not updated. The maximum count is 255.
Copying to/from overlapping areas is not supported and will have an
undefined behavior. The display will **not** scroll if the end of the
screen is exceeded. Copying beyond the active screen buffer area is not
supported and results in undefined behavior.

### Function 0x4B -- Video Scroll (VDASCR)

| _Entry Parameters_
|       B: 0x4B
|       C: Video Device Unit ID
|       E: Scroll Distance (Line Count)

| _Exit Results_
|       A: Status (0=OK, else error)

Scroll the video display by the number of lines specified in E. If E
contains a negative number, then reverse scroll should be performed.

### Function 0x4C -- Video Keyboard Status (VDAKST)

| _Entry Parameters_
|       B: 0x4C
|       C: Video Device Unit ID

| _Exit Results_
|       A:Count of Key Codes in Keyboard Buffer

Return a count of the number of key codes in the keyboard buffer. If it
is not possible to determine the actual number in the buffer, it is
acceptable to return 1 to indicate there are key codes available to read
and 0 if there are none available.

### Function 0x4D -- Video Keyboard Flush (VDAKFL)

| _Entry Parameters_
|       B: 0x4D
|       C: Video Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)

If a keyboard buffer is in use, it should be purged and all contents
discarded.

### Function 0x4E -- Video Keyboard Read (VDAKRD)

| _Entry Parameters_
|       B: 0x4E
|       C: Video Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)
|       C: Scancode
|       D: Keystate
|       E: Keycode

Read next key code from keyboard. If a keyboard buffer is used, return
the next key code in the buffer. If no key codes are available, wait for
a keypress and return the keycode.

The scancode value is the raw scancode from the keyboard for the
keypress. Scancodes are from scancode set 2 standard.

The keystate is a bitmap representing the value of all modifier keys and
shift states as they existed at the time of the keystroke. The bitmap is
defined as:

Bit | Keystate Indication
--- | --------------------------------
7   | Key pressed was from the num pad
6   | Caps Lock was active
5   | Num Lock was active
4   | Scroll Lock was active
3   | Windows key was held down
2   | Alt key was held down
1   | Control key was held down
0   | Shift key was held down

Keycodes are generally returned as appropriate ASCII values, if
possible. Special keys, like function keys, are returned as reserved
codes as described at the start of this section.

`\clearpage`{=latex}

Sound (SND)
------------

### Function 0x50 -- Sound Reset (SNDRESET)

| _Entry Parameters_
|       B: 0x50
|       C: Audio Device Unit ID

| _Exit Results_
|       A: Status (0=OK, else error)

Reset the sound chip.  Turn off all sounds and set volume on all
channels to silence.

### Function 0x51 -- Sound Volume (SNDVOL)

| _Entry Parameters_
|       B: 0x51
|       C: Audio Device Unit ID
|       L: Volume (00=Silence, FF=Maximum)

| _Exit Results_
|       A: Status (0=OK, else error)

This function sets the sound chip volume parameter.  The volume will
be applied when the next SNDPLAY function is invoked.

Note that not all sounds chips implement 256 volume levels.  The
driver will scale the volume to the closest possible level the
chip provides.

### Function 0x52 -- Sound Period (SNDPRD)

| _Entry Parameters_
|       B: 0x52
|       C: Audio Device Unit ID
|       HL: Period

|      _Returned Values_
|           A: Status (0=OK, else error)

This function sets the sound chip period parameter.  The period will
be applied when the next SNDPLAY function is invoked.

The period value is a driver specific value.  To play standardized
notes, use the SNDNOTE function.  A higher value will generate a lower
note.  The maximum value that can be used is driver specific. If value
supplied is beyond driver capabilities, register A will be set to $FF.

### Function 0x53 -- Sound Note (SNDNOTE)

| _Entry Parameters_
|       B: 0x53
|       C: Audio Device Unit ID
|       HL: Value of note to play

|      _Returned Values_
|           A: Status (0=OK, else error)

This function sets the sound chip period parameter with steps of quarter
of a semitone.  The value of 0 (lowest) corresponds to Bb/A# in octave 0.

Increase by steps of 4 to select the next corresponding note.

Increase by steps of 48 to select the same note in next octave.

If the driver is able to generate the requested note, a success (0) is
returned, otherwise a non-zero error state will be returned.

The sound chip resolution and its oscillator limit the range and
accuracy of the notes played. The typically range of the AY-3-8910
is six octaves, Bb2/A#2-A7, where each value is a unique tone. Values
above and below can still be played but each quarter tone step may not
result in a note change.

The following table shows the mapping of the input value in HL
to the corresponding octave and note.

| Note  | Oct 0 | Oct 1 | Oct 2 | Oct 3 | Oct 4 | Oct 5 | Oct 6 | Oct 7 |
|:----- | -----:| -----:| -----:| -----:| -----:| -----:| -----:| -----:|
| Bb/A# |   0   |   48  |  96   |  144  |  192  |  240  |  288  |  336  |
| B     |   4   |   52  |  100  |  148  |  196  |  244  |  292  |  340  |
| C     |   8   |   56  |  104  |  152  |  200  |  248  |  296  |  344  |
| C#/Db |   12  |   60  |  108  |  156  |  204  |  252  |  300  |  348  |
| D     |   16  |   64  |  112  |  160  |  208  |  256  |  304  |  352  |
| Eb/D# |   20  |   68  |  116  |  164  |  212  |  260  |  308  |  356  |
| E     |   24  |   72  |  120  |  168  |  216  |  264  |  312  |  360  |
| F     |   28  |   76  |  124  |  172  |  220  |  268  |  316  |  364  |
| F#/Gb |   32  |   80  |  128  |  176  |  224  |  272  |  320  |  368  |
| G     |   36  |   84  |  132  |  180  |  228  |  276  |  324  |  372  |
| Ab/G# |   40  |   88  |  136  |  184  |  232  |  280  |  328  |  376  |
| A     |   44  |   92  |  140  |  188  |  236  |  284  |  332  |  380  |

### Function 0x54 -- Sound Play SNDPLAY)

| _Entry Parameters_
|       B: 0x54
|       C: Audio Device Unit ID
|       D: Channel

|      _Returned Values_
|           A: Status (0=OK, else error)

This function applies the previously specified volume and period by
programming the sound chip with the appropriate values.  The values
are applied to the specified channel of the chip.

For example, to play a specific note on Audio Device UNit 0,
the following HBIOS calls would need to be made:

```
HBIOS B=51 C=00 L=80      ; Set volume to half level
HBIOS B=53 C=00 L=69      ; Select Middle C (C4) assuming SN76489
HBIOS B=54 C=00 D=01      ; Play note on Channel 1
```

### Function 0x55 -- Sound Query (SNDQUERY)

| _Entry Parameters_
|       B: 0x55
|       C: Audio Device Unit ID
|       E: Subfunction

|      _Returned Values_
|           A: Status (0=OK, else error)

This function will return the status of the current pending command or
key aspects of the specific Audio Device.

#### SNDQUERY Subfunction 0x01 -- Get count of audio channels supported (SNDQ_CHCNT)

|      _Entry Parameters_
|           B: 0x55
|           E: 0x01

|      _Returned Values_
|           A: Status (0=OK, else error)
|           B: Count of standard tone channels
|           C: Count of noise tone channels

#### SNDQUERY Subfunction 0x02		 -- Get current volume setting (SNDQ_VOL)

|      _Entry Parameters_
|           B: 0x55
|           E: 0x02

|      _Returned Values_
|           A: Status (0=OK, else error)
|           H: 0
|           L: Current volume setting

#### SNDQUERY Subfunction 0x03 -- Get current period setting (SNDQ_PERIOD)

|      _Entry Parameters_
|           B: 0x55
|           E: 0x03

|      _Returned Values_
|           A: Status (0=OK, else error)
|           HL: Current period setting

#### SNDQUERY Subfunction 0x04 -- Get device details (SNDQ_DEV)

|      _Entry Parameters_
|           B: 0x55
|           E: 0x04

|      _Returned Values_
|           A: Status (0=OK, else error)
|           B: Driver identity
|           HL: Driver specific port settings
|           DE: Driver specific port settings

Reports information about the audio device unit specified.

Register B reports the audio device type (see below).

Registers HL and DE contain relevant port addresses for the hardware
specific to each device type.

The currently defined audio device types are:

AUDIO ID       | Value | Device     | Returned registers
-------------- | ----- | ---------- | --------------------------------------------
SND_SN76489    | 0x01  | SN76489    | E: Left channel port, L: Right channel port
SND_AY38910    | 0x02  | AY-3-8910  | D: Address port, E: Data port
SND_BITMODE    | 0x03  | I/O PORT   | D: Address port, E: Bit mask

### Function 0x56 -- Sound Duration (SNDDUR)

| _Entry Parameters_
|       B: 0x56
|       C: Audio Device Unit ID
|       HL: Duration

|      _Returned Values_
|           A: Status (0=OK, else error)

This function sets the duration of the note to be played in milliseconds.

If the duration is set to zero, then the play function will operate in a non-blocking
mode. i.e. a tone will start playing and the play function will return. The tone will
continue to play until the next tone is played. I/O PORT are not compatible and will
not play a note if the duration is zero.

For other values, when a tone is played, it will play for the duration defined in HL
and then return.

### Function 0x57 -- Sound Device (SNDDEVICE)

| _Entry Parameters_
|       B: 0x57
|       C: Sound Device Unit Number

| _Exit Results_
|       A: Status (0=OK, else error)
|       D: Serial Device Type
|       E: Serial Device Number
|       H: Serial Device Unit Mode
|       L: Serial Device Unit I/O Base Address

Reports information about the sound device unit specified.  Register D
indicates the device type (driver) and register E indicates the physical
device number assigned by the driver.

Each character device is handled by an appropriate driver (AY38910, SN76489,
etc.). The driver can be identified by the Device Type. The assigned Device
Types are listed below.

_Id_ | _Device Type / Driver_
---- | ----------------------
0x00 | SN76489
0x10 | AY38910
0x20 | BITMODE

`\clearpage`{=latex}

System (SYS)
------------

### Function 0xF0 -- System Reset (SYSRESET)

| _Entry Parameters_
|       B: 0xF0
|       C: Subfunction (see below)

| _Exit Results_
|       A: Status (0=OK, else error)

This function performs various forms of a system reset depending on
the value of the subfucntion.  See subfunctions below.

#### SYSRESET Subfunction 0x00 -- Internal HBIOS Reset (RESINT)

|      _Entry Parameters_
|           BC: 0xFD00

|      _Returned Values_
|           A: Status (0=OK, else error)

Perform a soft reset of HBIOS. Releases all HBIOS memory allocated by
current OS. Does not reinitialize physical devices.

#### SYSRESET Subfunction 0x01 -- Warm Start System (RESWARM)

|      _Entry Parameters_
|           BC: 0xFD01

|      _Returned Values_
|           <none>

Warm start the system returning to the boot loader prompt.  Does not
reinitialize physical devices.

#### SYSRESET Subfunction 0x02 -- Cold Start System (RESCOLD)

|      _Entry Parameters_
|           BC: 0xFD02

|      _Returned Values_
|           <none>

Perform a system cold start (like a power on).  All devices are
reinitialized.

### Function 0xF1 -- System Version (SYSVER)

| _Entry Parameters_
|       B: 0xF1
|       C: Reserved (set to 0)

| _Exit Results_
|       A: Status (0=OK, else error)
|       DE: Version (Maj/Min/Upd/Pat)
|       L: Platform ID

This function will return the HBIOS version number. The version number
is returned in DE. High nibble of D is the major version, low nibble of
D is the minor version, high nibble of E is the patch number, and low
nibble of E is the build number.

The hardware platform is identified in L:

Id | Platform
-- | ---------------------------------------------------
1  | SBC V1 or V2
2  | Zeta
3  | Zeta V2
4  | N8
5  | Mark IV
6  | UNA
7  | RC2014 w/ Z80
8  | RC2014 w/ Z180 & banked memory module
9  | RC2014 w/ Z180 & linear memory module
10 | SCZ180 (SC126, SC130, SC131)
11 | Dyno

### Function 0xF2 -- System Set Bank (SYSSETBNK)

| _Entry Parameters_
|       B: 0xF2
|       C: Bank ID

| _Exit Results_
|       A: Status (0=OK, else error)
|       C: Previously Active Bank ID

Activates the Bank ID specified in C and returns the previously active
Bank ID in C. The caller MUST be invoked from code located in the upper
32K and the stack **must** be in the upper 32K.

### Function 0xF3 -- System Get Bank (SYSGETBNK)

| _Entry Parameters_
|       B: 0xF3

| _Exit Results_
|       A: Status (0=OK, else error)
|       C: Active Bank ID

Returns the currently active Bank ID in C.

### Function 0xF4 -- System Set Copy (SYSSETCPY)

| _Entry Parameters_
|       B: 0xF4
|       D: Destination Bank ID
|       E: Source Bank ID
|       HL: Count of Bytes to Copy

| _Exit Results_
|       A: Status (0=OK, else error)

Prepare for a subsequent interbank memory copy (SYSBNKCPY) function by
setting the source bank, destination bank, and byte count for the copy.
The bank id's are not range checked and must be valid for the system in
use.

No bytes are copied by this function. The SYSBNKCPY must be called to
actually perform the copy. The values setup by this function will remain
unchanged until another call is make to this function. So, after calling
SYSSETCPY, you may make multiple calls to SYSBNKCPY as long as you want
to continue to copy between the already established Source/Destination
Banks and the same size copy if being performed.

### Function 0xF5 -- System Bank Copy (SYSBNKCPY)

| _Entry Parameters_
|       B: 0xF5
|       DE: Destination Address
|       HL: Source Address

| _Exit Results_
|       A: Status (0=OK, else error)

Copy memory between banks. The source bank, destination bank, and byte
count to copy MUST be established with a prior call to SYSSETCPY.
However, it is not necessary to call SYSSETCPY prior to subsequent calls
to SYSBNKCPY if the source/destination banks and copy length do not
change.

WARNINGS:

* This function is inherently dangerous and does not prevent you from
corrupting critical areas of memory. Use with **extreme** caution.

* Overlapping source and destination memory ranges are not supported and
will result in undetermined behavior.

* Copying of byte ranges that cross bank boundaries is undefined.

### Function 0xF6 -- System Alloc (SYSALLOC)

| _Entry Parameters_
|       B: 0xF6
|       HL: Size in Bytes

| _Exit Results_
|       A: Status (0=OK, else error)
|       HL: Address of Allocated Memory

This function will attempt to allocate a block of memory of HL bytes
from the internal HBIOS heap. The HBIOS heap resides in the HBIOS bank
in the area of memory left unused by HBIOS. If the allocation is
successful, the address of the allocated memory block is returned in HL.
You will typically want to use the SYSBNKCPY function to read/write the
allocated memory.

### Function 0xF7 -- System Free (SYSFREE)

|      _Entry Parameters_
|           B: 0xF7
|           HL: Address of Memory Block to Free

|      _Returned Values_
|           A: Status (0=OK, else error)

\*\*\* This function is not yet implemented \*\*\*

### Function 0xF8 -- System Get (SYSGET)

|      _Entry Parameters_
|           B: 0xF8
|           C: Subfunction (see below)

|      _Returned Values_
|           A: Status (0=OK, else error)

This function will report various system information based on the
sub-function value. The following lists the subfunctions
available along with the registers/information returned.

#### SYSGET Subfunction 0x00 -- Get Serial Device Unit Count (CIOCNT)

|      _Entry Parameters_
|           BC: 0xF800

|      _Returned Values_
|           A: Status (0=OK, else error)
|           E: Count of Serial Device Units

#### SYSGET Subfunction 0x01 -- Get Serial Unit Function (CIOFN)

|      _Entry Parameters_
|           BC: 0xF801
|           D: CIO Function
|           E: Unit

|      _Returned Values_
|           A: Status (0=OK, else error)
|           HL: Driver Function Address
|           DE: Unit Data Address

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
CIO function number to lookup in D and the CIO unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).  See
Appendix A for details.

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0x10 -- Get Disk Device Unit Count (DIOCNT)

|      _Entry Parameters_
|           BC: 0xF810

|      _Returned Values_
|           A: Status (0=OK, else error)
|           E: Count of Disk Device Units

#### SYSGET Subfunction 0x11 -- Get Disk Unit Function (DIOFN)

|      _Entry Parameters_
|           BC: 0xF811
|           D: DIO Function
|           E: Unit

|      _Returned Values_
|           A: Status (0=OK, else error)
|           HL: Driver Function Address
|           DE: Unit Data Address

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
DIO function number to lookup in D and the DIO unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0x20 -- Get Disk Device Unit Count (RTCCNT)

|      _Entry Parameters_
|           BC: 0xF820

|      _Returned Values_
|           A: Status (0=OK, else error)
|           E: Count of RTC Device Units

#### SYSGET Subfunction 0x40 -- Get Video Device Unit Count (VDACNT)

|      _Entry Parameters_
|           BC: 0xF840

|      _Returned Values_
|           A: Status (0=OK, else error)
|           E: Count of Video Device Units

#### SYSGET Subfunction 0x41 -- Get Video Unit Function (VDAFN)

|      _Entry Parameters_
|           BC: 0xF841
|           D: VDA Function
|           E: Unit

|      _Returned Values_
|           A: Status (0=OK, else error)
|           HL: Driver Function Address
|           DE: Unit Data Address

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
VDA function number to lookup in D and the VDA unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).  See
Appendix A for details.

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0x50 -- Get Sound Device Unit Count (SNDCNT)

|      _Entry Parameters_
|           BC: 0xF850

|      _Returned Values_
|           A: Status (0=OK, else error)
|           E: Count of Sound Device Units

#### SYSGET Subfunction 0x51 -- Get Sound Unit Function (SNDFN)

|      _Entry Parameters_
|           BC: 0xF851
|           D: SND Function
|           E: Unit

|      _Returned Values_
|           A: Status (0=OK, else error)
|           HL: Driver Function Address
|           DE: Unit Data Address

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
SND function number to lookup in D and the SND unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).  See
Appendix A for details.

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0xD0 -- Get Timer Tick Count (TIMER)

|      _Entry Parameters_
|           BC: 0xF8D0

|      _Returned Values_
|           A: Status (0=OK, else error)
|           DE:HL: Current Timer Tick Count Value
|           C: Tick frequency (typically 50 or 60)

#### SYSGET Subfunction 0xD1 -- Get Seconds Count (SECONDS)

|      _Entry Parameters_
|           BC: 0xF8D1

|      _Returned Values_
|           A: Status (0=OK, else error)
|           DE:HL: Current Seconds Count Value
|           C: Ticks within Second Value

#### SYSGET Subfunction 0xE0 -- Get Boot Information (BOOTINFO)

|      _Entry Parameters_
|           BC: 0xF8E0

|      _Returned Values_
|           A: Status (0=OK, else error)
|           L: Boot Bank ID
|           D: Boot Disk Device Unit ID
|           E: Boot Disk Slice

#### SYSGET Subfunction 0xF0 -- Get CPU Information (CPUINFO)

|      _Entry Parameters_
|           BC: 0xF8F0

|      _Returned Values_
|           A: Status (0=OK, else error)
|           H: Z80 CPU Variant
|           L: CPU Speed in MHz
|           DE: CPU Speed in KHz

#### SYSGET Subfunction 0xF1 -- Get Memory Information (MEMINFO)

|      _Entry Parameters_
|           BC: 0xF8F1

|      _Returned Values_
|           A: Status (0=OK, else error)
|           D: Count of 32K ROM Banks
|           E: Count of 32K RAM Banks

#### SYSGET Subfunction 0xF2 -- Get Bank Information (BNKINFO)

|      _Entry Parameters_
|           BC: 0xF8F2

|      _Returned Values_
|           A: Status (0=OK, else error)
|           D: BIOS Bank ID
|           E: User Bank ID

### Function 0xF9 -- System Set (SYSSET)

|      _Entry Parameters_
|           B: 0xF9
|           C: Subfunction (see below)

|      _Returned Values_
|           A: Status (0=OK, else error)

This function will set various system parameters based on the
sub-function value. The following lists the subfunctions
available along with the registers/information used as input.

#### SYSSET Subfunction 0xD0 -- Set Timer Tick Count (TIMER)

|      _Entry Parameters_
|           BC: 0xF9D0
|           DE:HL: Timer Tick Count Value

|      _Returned Values_
|           A: Status (0=OK, else error)


#### SYSSET Subfunction 0xD1 -- Set Seconds Count (SECONDS)

|      _Entry Parameters_
|           BC: 0xF9D1
|           DE:HL: Seconds Count Value

|      _Returned Values_
|           A: Status (0=OK, else error)

#### SYSSET Subfunction 0xE0 -- Set Boot Information (BOOTINFO)

|      _Entry Parameters_
|           BC: 0xF9E0
|           L: Boot Bank ID
|           D: Boot Disk Device Unit ID
|           E: Boot Disk Slice

|      _Returned Values_
|           A: Status (0=OK, else error)

### Function 0xFA -- System Peek (SYSPEEK)

|      _Entry Parameters_
|           B: 0xFA
|           D: Bank ID
|           HL: Memory Address

|      _Returned Values_
|           A: Status (0=OK, else error)
|           E: Byte Value

This function gets a single byte value at the specified bank/address.
The bank specified is not range checked.

### Function 0xFB -- System Poke (SYSPOKE)

|      _Entry Parameters_
|           B: 0xFB
|           D: Bank ID
|           E: Value
|           HL: Memory Address

|      _Returned Values_
|           A: Status (0=OK, else error)

This function sets a single byte value at the specified bank/address.
The bank specified is not range checked.

### Function 0xFC -- System Interrupt Management (SYSINT)

|      _Entry Parameters_
|           B: 0xFC
|           C: Subfunction (see below)

|      _Returned Values_
|           A: Status (0=OK, else error)

This function allows the caller to query information about the interrupt
configuration of the running system and allows adding or hooking interrupt
handlers dynamically. Register C is used to specify a subfunction.
Additional input and output registers may be used as defined by the
sub-function.

Note that during interrupt processing, the lower 32K of CPU address space
will contain the RomWBW HBIOS code bank, not the lower 32K of application
TPA. As such, a dynamically installed interrupt handler does not have
access to the lower 32K of TPA and must be careful to avoid modifying the
contents of the lower 32K of memory. Invoking RomWBW HBIOS functions
within an interrupt handler is not supported.

Interrupt handlers are different for IM1 or IM2.

For IM1:

> The new interrupt handler is responsible for chaining (JP) to the
previous vector if the interrupt is not handled. If the interrupt is
handled, the new handler may simply return (RET). When chaining to the
previous interrupt handler, ZF must be set if interrupt is handled and
ZF cleared if not handled. The interrupt management framework takes care
of saving and restoring AF, BC, DE, HL, and IY. Any other registers
modified must be saved and restored by the interrupt handler.

For IM2:

> The new interrupt handler may either replace or hook the previous
interrupt handler. To replace the previous interrupt handler, the new
handler just returns (RET) when done. To hook the previous handler, the
new handler can chain (JP) to the previous vector. Note that initially
all IM2 interrupt vectors are set to be handled as “BAD” meaning that the
interrupt is unexpected. In most cases, you do not want to chain to the
previous vector because it will cause the interrupt to display a “BAD
INT” system panic message.

The interrupt framework will take care of issuing an EI and RETI
instruction. Do not put these instructions in your new handler.
Additionally, interrupt management framework takes care of saving and
restoring AF, BC, DE, HL, and IY. Any other registers modified must be
saved and restored by the interrupt handler.

If the caller is transient, then the caller must remove the new interrupt
handler and restore the original one prior to termination. This is
accomplished by calling this function with the Interrupt Vector set to the
Previous Vector returned in the original call.

The caller is responsible for disabling interrupts prior to making an
INTSET call and enabling them afterwards. The caller is responsible for
ensuring that a valid interrupt handler is installed prior to enabling any
hardware interrupts associated with the handler. Also, if the handler is
transient, the caller must disable the hardware interrupt(s) associated
with the handler prior to uninstalling it.

#### SYSINT Subfunction 0x00 -- Interrupt Info (INTINF)

|      _Entry Parameters_
|           BC: 0xFC00

|      _Returned Values_
|           A: Status (0=OK, else error)
|           D: Interrupt Mode
|           E: Size (# entries) of Interrupt Vector Table

Return interrupt mode in D and size of interrupt vector table in E. For
IM1, the size of the table is the number of vectors chained together.
For IM2, the size of the table is the number of slots in the vector
table.

#### SYSINT Subfunction 0x10) -- Get Interrupt (INTGET)

|      _Entry Parameters_
|           BC: 0xFC10
|           E: Interrupt Vector Table Index

|      _Returned Values_
|           A: Status (0=OK, else error)
|           HL: Current Interrupt Vector Address

On entry, register E must contain an index into the interrupt vector
table. On return, HL will contain the address of the current interrupt
vector at the specified index.

#### SYSINT Subfunction 0x20) -- Set Interrupt (INTSET)

|      _Entry Parameters_
|           BC: 0xFC20
|           E: Interrupt Vector Table Index
|           HL: Interrupt Address to be Assigned

|      _Returned Values_
|           A: Status (0=OK, else error)
|           HL: Previous Interrupt Vector Address
|           DE: Interrupt Routing Engine Address (IM2)

On entry, register E must contain an index into the interrupt vector table
and register HL must contain the address of the new interrupt vector to
be inserted in the table at the index. On return, HL will contain the
previous address in the table at the index.


`\clearpage`{=latex}

### Appendix A Driver Instance Data fields

The following section outlines the read only data referenced by the
`SYSGET`, subfunctions `xxxFN` for specific drivers.


#### TMS9918 Driver:

| Name   | Offset | Size (bytes)| Description |
|--------|--------|-------------|-------------|
| PPIA	 | 0      | 1	          | PPI PORT A  |
| PPIB	 | 1      | 1           | PPI PORT B  |
| PPIC	 | 2      | 1           | PPI PORT C  |
| PPIX	 | 3      | 1           | PPI CONTROL PORT |
| DATREG | 4      | 1           | IO PORT ADDRESS FOR MODE 0 |
| CMDREG | 5      | 1           | IO PORT ADDRESS FOR MODE 1 |
| The following are the register mirror values that HBIOS used for initialisation |
|	REG. 0 | 6      | 1           | $00	       - NO EXTERNAL VID
| REG. 1 | 7      | 1           |	$50 or $70 - SET MODE 1 and interrupt if enabled |
| REG. 2 | 8      | 1           |	$00	       - PATTERN NAME TABLE := 0
| REG. 3 | 9      | 1           |	$00	       - NO COLOR TABLE
| REG. 4 | 10     | 1           |	$01	       - SET PATTERN GENERATOR TABLE TO $800
| REG. 5 | 11     | 1           |	$00	       - SPRITE ATTRIBUTE IRRELEVANT
| REG. 6 | 12     | 1           |	$00	       - NO SPRITE GENERATOR TABLE
| REG. 7 | 13     | 1           |	$F0	       - WHITE ON BLACK
| DCNTL* | 14     | 1           | Z180 DMA/WAIT CONTROL |

* ONLY PRESENT FOR Z180 BUILDS
