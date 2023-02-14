$define{doc_title}{System Guide}$
$include{"Book.h"}$

# Overview

The objective of RomWBW is to provide firmware, operating systems,
and applications targeting the Z80 family of CPUs.  The firmware,
in the form of a ROM module, acts as the hardware interface layer
with a well-defined API (the HBIOS).  The associated operating
systems and applications are adapted to the HBIOS API, not specific
hardware.

The HBIOS is modular and configurable.  New hardware interfaces can
be added in the form of straightforward driver modules.  Within certain
constraints, new hardware platforms can be supported by simply
adjusting values in a build configuration file.

RomWBW is geared toward hardware being developed in modern
retro-computing hobbyist communities, not as a replacement for
legacy hardware.  As a result, RomWBW requires at least 128KB
of bank switched RAM.

The CP/M family of operating systems has been adapted to run under
RomWBW including CP/M 2.2, Z-System, CP/M 3, and several other
variants.

RomWBW firmware (ROM) includes:

* System startup code (bootstrap) and bootloader

* A basic system/debug monitor

* HBIOS (Hardware BIOS) with support for most typical hardware
  components used in Z80 family computers

* Diagnostics and customizable debugging information.

* ROM-hosted operating systems (both CP/M 2.2 and Z-System)

* A ROM disk containing the standard OS applications and a
  RAM disk for working storage.

It is appropriate to note that much of the code and components that make
up a complete RomWBW package are derived from pre-existing work. Most
notably, the embedded operating system is simply a ROM-based copy of
generic CP/M or ZSDOS. Much of the hardware support code was originally
produced by other members of the RetroBrew Computers Community.

The remainder of this document focuses on HBIOS which is the
fundamental basis of RomWBW.

# Background

The Z80 CPU architecture has a limited, 64K address range. In general,
this address space must accommodate a running application, disk
operating system, and hardware support code.

Modern retro-computing Z80 CPU platforms provide a physical address 
space that is much larger than the CPU address space (typically 512K or 
1MB of physical RAM). This additional memory can be made available to 
the CPU using a technique called bank switching. To achieve this, the 
physical memory is divided up into chunks (banks) of 32K each. A 
designated area of the CPU's 64K address space is then reserved to "map"
 any of the physical memory chunks. You can think of this as a window 
that can be adjusted to view portions of the physical memory in 32K 
blocks. In the case of RomWBW, the lower 32K of the CPU address space is
 used for this purpose (the window). The upper 32K of CPU address space 
is assigned a fixed 32K area of physical memory that never changes. The 
lower 32K can be "mapped" on the fly to any of the 32K banks of physical
 memory at a time. The only constraint is that the CPU cannot be 
executing code in the lower 32K of CPU address space at the time that a 
bank switch is performed.

By utilizing the pages of physical RAM for specific purposes and 
swapping in the correct page when needed, it is possible to utilize 
substantially more than 64K of RAM. Because the retro-computing 
community has now produced a very large variety of hardware, it has 
become extremely important to implement a bank switched solution to 
accommodate the maximum range of hardware devices and desired 
functionality.

# General Design Strategy

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
implemented inside of the small 512 byte area at the top of the CPU
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
(boot) all required code is copied to RAM (shadowed) for subsequent 
execution.

# Runtime Memory Layout

![Bank Switched Memory Layout](Graphics/BankSwitchedMemory){ width=100% }

# System Boot Process

A multi-phase boot strategy is employed. This is necessary because at
cold start, the CPU is executing code from ROM in lower memory which is
the same area that is bank switched.

RomWBW supports multiple boot techniques as described below.  The
most common of these is the ROM boot.

## ROM Boot

The ROM boot process normally begins with a system cold start (power on 
or hardware reset).  The hardware is responsible for ensuring that the 
lower 32K of CPU memory (bank window) is mapped to the initial 32K of 
the ROM.  The Z80 CPU begins execution at address zero which will be 
address zero of the ROM.

The following steps occur during the ROM boot process:

#. The ROM code performs basic hardware initialization and ensures
   that the top 32K of CPU memory is mapped to the proper RAM bank.

#. The ROM code installs the HBIOS proxy code into the top 512
   bytes of the CPU memory (0xFE00-0xFFFF).

#. Using the proxy code services, the full HBIOS code is copied
   from the ROM bank to the RAM bank that it will use for normal
   processing.

#. Again using the proxy code services, the RAM copy of HBIOS is
   activated in the bank window and execution transitions to the
   RAM copy of HBIOS.

#. The HBIOS initializes the system console so that output can now
   be displayed to the user.

#. The HBIOS now performs the full hardware discovery and initialization
   process while displaying it's progress.

#. The HBIOS displays a final summary of the hardware device unit
   assignments and various configuration information.

#. The HBIOS loads the RomWBW Boot Loader from ROM into RAM and
   jumps to it.

At this point, the user would normally use Boot Loader commands
to select and launch an operating system or applications from either
ROM or disk.

Note that the boot process is entirely operating system agnostic.
It is unaware of the operating system being loaded. The Boot Loader
prompts the user for the location of the binary image to load, but does
not know anything about what is being loaded (the image is usually an
operating system, but could be any executable code image). Once the Boot
Loader has loaded the image at the selected location, it will transfer
control to it. Assuming the typical situation where the image was an
operating system, the loaded operating system will then perform it's own
initialization and begin normal operation.

## Application Boot

Once the system is running (operating system loaded), it is possible to 
reboot the system from a system image (file) contained on the OS file 
system. This is referred to as an "Application Boot".  The process is 
similar to a ROM boot, but the HBIOS code is loaded from an image file 
instead of ROM.  This boot technique is useful to: 1) test a new build 
of a system image before programming it to the ROM; or 2) easily switch 
between system images on the fly.

During the RomWBW build process, one of the output files produced is an
actual CP/M application (an executable .COM program file). Once you have
a running CP/M (or compatible) system, you can upload/copy this
application file to the filesystem. By executing this file, you will
initiate an Application Boot using the system image contained in the
application file itself.

Upon execution, the Application Boot program is loaded into memory by
the previously running operating system starting at $0100. Note that the
program image contains a full copy of the HBIOS to be installed and run. Once
the Application Boot program is loaded by the previous operating system,
control is passed to it and it performs a system initialization similar
to the ROM Boot, but using the image loaded in RAM.  Once te new
HBIOS completes it's initialization, it will launch the Boot Loader
just like a ROM boot.

The Application Boot program actually contains two other components
beyond the new HBIOS.  It has a copy of the Boot Loader and a copy of
the Z-System OS.  This is done in case the new HBIOS requires updated
versions of the Boot Loader or OS to run.  The Boot Loader is aware
of this boot mode and automatically adapts it's menu appropriately.

If you restart your system, then it will revert to a ROM Boot from
the currently installed ROM.

## RAM Boot

Some hardware supported by RomWBW has a special mechanism for loading 
the boot and HBIOS code.  These systems have no ROM chips.  However, 
they have a small hardware bootstrap that loads a chunk of code from a 
disk device directly into RAM at system startup.

The startup then proceeds very much like the Application Boot
process described above.  HBIOS is installed in it's operating bank
and control is passed to the Boot Loader.

# Driver Model

The framework code for bank switching also allows hardware drivers to be
implemented mostly without concern for memory management. Drivers are
coded to simply implement the HBIOS functions appropriate for the type
of hardware being supported. When the driver code gets control, it has
already been mapped to the CPU address space and simply performs the
requested function based on parameters passed in registers. Upon return,
the bank switching framework takes care of restoring the original memory
layout expected by the operating system and application.

Drivers do need to be aware of the bank switching if a buffer address
is being used in the function call.

* If the buffer address is in the lower 32K of RAM, then the memroy
  it points to will be from the User Bank, not the HBIOS bank which
  is now active.  In this case, the driver must use an inter-bank
  copy to access the data.

* If the buffer address is in the top 32K of RAM, then the driver will
  have access to it directly even after a bank switch, so no special
  steps are required.
  
For some functions, the location of the buffer is required to be
in the top 32K of RAM to simplify the operation of the driver.

It is usually better if the OS or application calling a buffered
function places the buffer in the top 32K because this may avoid
a double-copy operation.

If driver code must make calls to other code, drivers, or utilities in 
the HBIOS bank, it must make those calls directly (it must not use RST 
08). This is to avoid a nested bank switch which is not supported at 
this time.

# Character / Emulation / Video Services

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

![Character / Emulation / Video Services](Graphics/CharacterEmulationVideoServices){ width=100% }

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

# HBIOS Reference

## Invocation

HBIOS functions are invoked by placing the required parameters in CPU 
registers and executing an RST 08 instruction. Note that HBIOS does not 
preserve register values that are unused. However, the values of the Z80
alternate registers and IX/IY will be preserved (these registers may be
used within HBIOS, but will be saved and restored internally).

An alternate method of invoking HBIOS functions is to use `CALL 0xFFF0`.
Since the RST 08 vector exists in page zero of the CPU address space,
it may be paged out when alternate memory banks are selected.  If this
may be true when you are invoking a function, you should use the `CALL`
method.

Normally, applications will not call HBIOS functions directly. It is 
intended that the operating system makes all HBIOS function calls. 
Applications that are considered system utilities may use HBIOS, but 
must be careful not to modify the operating environment in any way that 
the operating system does not expect.

In general, the desired function is placed in the B register. Register C
is frequently used to specify a subfunction or a target device unit 
number. Additional registers are used as defined by the specific 
function. Register A should be used to return function result 
information.  See below for result code definitions.

The character, disk, and video device functions all refer to target 
devices using a logical device unit number that is passed in the C 
register. Keep in mind that these unit numbers are assigned dynamically 
at HBIOS initialization during the device discovery process. The 
assigned unit numbers are displayed on the console at the conclusion of 
device initialization. The unit assignments will never change after 
HBIOS initialization. However, they can change at the next boot if there
have been hardware or BIOS customization changes. Code using HBIOS 
functions should not assume fixed unit assignments.

Some functions utilize pointers to memory buffers. Unless otherwise 
stated, such buffers can be located anywhere in the Z80 CPU 64K address 
space. However, performance sensitive buffers (primarily disk I/O 
buffers) will require double-buffering if the caller’s buffer is in the 
lower 32K of CPU address space. For optimal performance, such buffers 
should be placed in the upper 32K of CPU address space.

## Result Codes

The following function result codes are defined generically for all 
HBIOS functions. Most function calls will return a result in register A.

| **Code** | **Definition**                         |
|---------:|----------------------------------------|
| 0        | function succeeded                     |
| -1       | undefined error                        |
| -2       | function not implemented               |
| -3       | invalid function                       |
| -4       | invalid unit numberr                   |
| -5       | out of memory                          |
| -6       | parameter out of range                 |
| -7       | media not present                      |
| -8       | hardware not present                   |
| -9       | I/O error                              |
| -10      | write request to read-only media       |
| -11      | device timeout                         |
| -12      | invalid configuration                  |

`\clearpage`{=latex}

## Character Input/Output (CIO)

Character Input/Output functions require that a Character Unit number be
specified in register C. This is the logical device unit number 
assigned during the boot process that identifies all character 
devices uniquely. A special value of 0x80 can be used for the Character 
Unit to refer to the current console device.

All character units are assigned a Device Type ID which indicates
the specific hardware device driver that handles the unit.  The table
below enumerates these values.

| **Device Type** | **ID** | **Description**                          | **Driver** |
|-----------------|-------:|------------------------------------------|------------|
| CIODEV_UART     | 0x00   | 16C550 Family Serial Interface           | uart.asm   |
| CIODEV_ASCI     | 0x10   | Z180 Built-in Serial Ports               | asci.asm   |
| CIODEV_TERM     | 0x20   | Terminal                                 | ansi.asm   |
| CIODEV_PRPCON   | 0x30   | PropIO Serial Console Interface          | prp.asm    |
| CIODEV_PPPCON   | 0x40   | ParPortProp Serial Console Interface     | ppp.asm    |
| CIODEV_SIO      | 0x50   | Zilog Serial Port Interface              | sio.asm    |
| CIODEV_ACIA     | 0x60   | MC68B50 Asynchronous Interface           | acia.asm   |
| CIODEV_PIO      | 0x70   | Zilog Parallel Interface Controller      | pio.asm    |
| CIODEV_UF       | 0x80   | FT232H-based ECB USB FIFO                | uf.asm     |
| CIODEV_DUART    | 0x90   | SCC2681 Family Dual UART                 | duart.asm  |
| CIODEV_Z2U      | 0xA0   | Zilog Z280 Built-in Serial Ports         | z2u.asm    |
| CIODEV_LPT      | 0xB0   | Parallel I/O Controller                  | lpt.asm    |

Character devices can usually be configured with line characteristics
such as speed, framing, etc. A word value (16 bit) is used to describe
the line characteristics as indicated below:

| **Bits** | **Characteristic**                     |
|---------:|----------------------------------------|
| 15-14    | Reserved (set to 0)                    |
| 13       | RTS                                    |
| 12-8     | Baud Rate (see below)                  |
| 7        | DTR                                    |
| 6        | XON/XOFF Flow Control                  |
| 5        | Stick Parity (set for true)            |
| 4        | Even Parity (set for true)             |
| 3        | Parity Enable (set for true)           |
| 2        | Stop Bits (set for true)               |
| 1-0      | Data Bits (5-8 encoded as 0-3)         |

The 5-bit Baud Rate value (V) is encoded as V = 75 * 2^X * 3^Y. The
bits are defined as YXXXX.

Actual character values are a single byte (8 bits).  The Character I/O
functions do not modify or interpret the values being sent/received
so they can be used to pass 8-bit binary data without corruption.  Note
that some OSes will modify character data (truncate to 7 bits, etc.).

### Function 0x00 -- Character Input (CIOIN)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x00                                | A: Status                              |
| C: Character Unit                      | E: Character                           |

Read and return a Character (E) from the specified Character Unit 
(C).  If no character(s) are available in the unit's input buffer, this 
function will wait indefinitely.  The returned Status (A) is a standard 
HBIOS result code.

### Function 0x01 -- Character Output (CIOOUT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x01                                | A: Status (0-OK, else error)           |
| C: Character Unit                      |                                        |
| E: Character                           |                                        |

Send a Character (E) via the specified Character Unit (C).  If 
there is no space available in the unit's output buffer, the function 
will wait indefinitely.  The returned Status (A) is a standard HBIOS result code.

### Function 0x02 -- Character Input Status (CIOIST)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x02                                | A: Status / Characters Pending         |
| C: Character Unit                      |                                        |

Return the count of Characters Pending (A) in the input buffer of the 
specified Character Unit (C).  If the unit has no input buffer or the 
buffer utilization is not available, the function may return simply 0 or
1 where 0 means there is no character available and 1 means there is at
least one character available.

The value returned in register A is used as both a Status (A) code and 
the return value. Negative values (bit 7 set) indicate a standard HBIOS 
result (error) code.  Otherwise, the return value represents the number 
of characters in the input buffer.

### Function 0x03 -- Character Output Status (CIOOST)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x03                                | A: Status / Space Free                 |
| C: Character Unit                      |                                        |

Return the count of buffer Space Free (A) for the specified 
Character Unit (C). For example, if a 16 byte output buffer contains 6 
characters waiting to be sent out the unit's serial interface, this 
function would return 10; the number of positions available in the 
output buffer. If the port has no output buffer or the buffer 
utilization is not available, the function may return simply 0 or 1 
where 0 means there is no buffer space available and 1 means there is 
space in the output buffer for at least one character.

The return value in register A is used as both a status code and the 
return value. Negative values (bit 7 set) indicate a standard HBIOS 
result (error) code.  Otherwise, the return value represents the buffer 
space available.

### Function 0x04 -- Character I/O Initialization (CIOINIT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x04                                | A: Status                              |
| C: Character Unit                      |                                        |
| DE: Line Characteristics               |                                        |

Condition the interface of the specified Character Unit (C) according to
the specified Line Characteristics (DE).  The definition of the line 
characteristics value is described above.  If DE contains -1 (0xFFFF), 
then the device will be reinitialized with the previous line 
characteristics used (a reset) and any buffer contents will be flushed.
The Status (A) is a standard HBIOS result code.

Not all line characteristics are supported by all character interfaces.
It is up to the driver of the character unit to decide how to deal
with characteristics that are not available.  For example, many
character drivers do not allow flow control settings (RTS/CTS, XON/XOFF)
to be modified dynamically.  In most cases, these settings are ignored
by the driver in this function call.

### Function 0x05 -- Character I/O Query (CIOQUERY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x05                                | A: Status                              |
| C: Character Unit                      | DE: Line Characteristics               |

Returns the current Line Characteristics (DE) of the specified Character
 Unit (C). The definition of the line characteristics value is described
 above. The returned status (A) is a standard HBIOS result code.

### Function 0x06 -- Character I/O Device (CIODEVICE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x06                                | A: Status                              |
| C: Character Unit                      | C: Device Attributes                   |
|                                        | D: Device Type                         |
|                                        | E: Device Number                       |
|                                        | H: Device Mode                         |
|                                        | L: Device I/O Base Address             |

Returns device information for the specified Character Unit (C).  The 
status (A) is a standard HBIOS result code.

Device Attribute (C) values are: 0 = RS/232, 1 = Terminal, 2 = Parallel.

Device Type (D) indicates the specific hardware driver that handles the 
specified Character Unit.  Values are listed at the start of this 
section. Device Number (E) indicates the physical device number assigned
per driver.  For example, a Device Type of 0x50 with a Device Number 
of 2 refers to the third port being handled by the SIO driver.

Device Mode (H) is used to indicate the variant of the chip or
circuit that is used by the specified unit.  For example, for a UART,
the value indicates the chip variant.  The Device I/O Base Address (L)
indicates the starting port address of the hardware interface that is
servicing the specified unit.  Both of these values are considered
driver specific.  Refer to the associated hardware driver for the
values used.

`\clearpage`{=latex}

## Disk Input/Output (DIO)

Disk Input/Output functions require that a Disk Unit number be specified
in register C. This is the logical device unit number assigned 
during the boot process that identifies all disk devices uniquely.

All character units are assigned a Device Type ID which indicates
the specific hardware device driver that handles the unit.  The table
below enumerates there values.

| **Device Type** | **ID** | **Description**                          | **Driver** |
|-----------------|-------:|------------------------------------------|------------|
| DIODEV_MD       | 0x00   | Memory Disk                              | md.asm     |
| DIODEV_FD       | 0x10   | Floppy Disk                              | fd.asm     |
| DIODEV_RF       | 0x20   | RAM Floppy                               | rf.asm     |
| DIODEV_IDE      | 0x30   | IDE Disk                                 | ide.asm    |
| DIODEV_ATAPI    | 0x40   | ATAPI Disk (not implemented)             |            |
| DIODEV_PPIDE    | 0x50   | PPIDE Disk                               | ppide.asm  |
| DIODEV_SD       | 0x60   | SD Card                                  | sd.asm     |
| DIODEV_PRPSD    | 0x70   | PropIO SD Card                           | prp.asm    |
| DIODEV_PPPSD    | 0x80   | ParPortProp SD Card                      | ppp.asm    |
| DIODEV_HDSK     | 0x90   | SIMH HDSK Disk                           | hdsk.asm   |

A fixed set of media types are defined. The currently defined media 
types identifiers are listed below. Each driver will support one or
more of the defined media types.

| **Media**     | **ID** | **Format**                                 |
|---------------|-------:|--------------------------------------------|
| MID_NONE      | 0      | No media installed                         |
| MID_MDROM     | 1      | ROM Drive                                  |
| MID_MDRAM     | 2      | RAM Drive                                  |
| MID_RF        | 3      | RAM Floppy (LBA)                           |
| MID_HD512     | 4      | Hard Disk (LBA) w/ 512 directory entries   |
| MID_FD720     | 5      | 3.5" 720K Floppy                           |
| MID_FD144     | 6      | 3.5" 1.44M Floppy                          |
| MID_FD360     | 7      | 5.25" 360K Floppy                          |
| MID_FD120     | 8      | 5.25" 1.2M Floppy                          |
| MID_FD111     | 9      | 8" 1.11M Floppy                            |
| MID_HD1K      | 10     | Hard Disk (LBA) w/ 1024 directory entries  |

HBIOS supports both Cylinder/Head/Sector (CHS) and Logical Block 
Addresses (CHS) when locating a sector for I/O (see DIOSEEK function). 
For devices that are natively CHS (e.g., floppy disk), the HBIOS driver 
can convert LBA values to CHS values according to the geometry of the 
current media.  For devices that are natively LBA (e.g., hard disk), the
 HBIOS driver simulates CHS using a fictitious geometry provided by the 
driver (typically 16 sectors per track and 16 heads per cylinder).

### Function 0x10 -- Disk Status (DIOSTATUS)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x10                                | A: Status                              |
| C: Disk Unit                           |                                        |

Returns the driver specific Status (A) of the specified disk device unit
(C) based on the last operation performed.

The return value in register A is used as both a device status and a 
standard HBIOS result code. Negative values (bit 7 set) indicate a 
standard HBIOS result (error) code.  Otherwise, the return value 
represents a driver-specific device status.  In call cases, the value 0 
means OK.

### Function 0x11 -- Disk Reset (DIORESET)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x11                                | A: Status                              |
| C: Disk Unit                           |                                        |

This function performs a device dependent reset operation on the Disk 
Unit specified (C).  The driver will clear any error status on the disk 
unit, attempt to reset the interface, and flag the disk unit for 
initialization on the next I/O function call. Any prior media 
identification will be cleared.  The returned Status (A) is a standard 
HBIOS result code.

If the specified disk unit (C) is one of multiple units on a single 
hardware bus, then all units on that bus will be reset.  For example, 
if the master disk on an IDE bus is reset, then the slave disk will 
also be reset.

### Function 0x12 -- Disk Seek (DIOSEEK)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x12                                | A: Status                              |
| C: Disk Unit                           |                                        |
| DEHL: Sector Address                   |                                        |

This function will set the desired sector to be used for the next I/O 
operation on the specified Disk Unit (C).  The returned Status (A) is a 
standard HBIOS result code.

An actual seek operation is generally not performed on the disk hardware
by this function.  The function typically just records the sector 
address for subsequent I/O function calls.

The double-word Sector Address (DEHL) can represent either a Logical 
Block Address (LBA) or a Cylinder/Head/Sector (CHS).  If the high bit of
register D is set, then an LBA value is specified.  Otherwise, the 
value is CHS.

For LBA mode operation, the high bit is cleared and the entire 
double-word is then treated as the logical sector address.

For CHS mode operation, the Sector Address (DEHL) registers are 
interpreted as: D=Head, E=Sector, and HL=Track.  All values (including 
sector) are 0 relative.

Prior versions of the floppy driver did not accept LBA mode addresses.
However, this restriction has been removed as of HBIOS v3.1.  At this
point, all disk drivers support both LBA and CHS addressing.

### Function 0x13 -- Disk Read (DIOREAD)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x13                                | A: Status                              |
| C: Disk Unit                           | E: Sectors Read                        |
| D: Buffer Bank ID                      |                                        |
| E: Sector Count                        |                                        |
| HL: Buffer Address                     |                                        |

Read Sector Count (E) sectors into the buffer located in Buffer Bank ID (D) 
at Buffer Address (HL) starting at the Current Sector.  The returned 
Status (A) is a standard HBIOS result code.

The Current Sector is established by a prior DIOSEEK function call;
however, multiple read/write/verify function calls can be made after a 
seek function. The Current Sector is incremented after each sector 
successfully read. On error, the Current Sector will be the sector where 
the error occurred. Sectors Read (E) indicates the number of sectors 
successfully read.

The caller must ensure that the Buffer Address is large enough to
contain all sectors requested.  Disk data transfers will be faster if
the buffer resides in the top 32K of memory because it avoids a
double buffer copy.

### Function 0x14 -- Disk Write (DIOWRITE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x14                                | A: Status                              |
| C: Disk Unit                           | E: Sectors Written                     |
| D: Buffer Bank ID                      |                                        |
| E: Sector Count                        |                                        |
| HL: Buffer Address                     |                                        |

Write Sector Count (E) sectors from the buffer located in Buffer Bank ID (D)
at Buffer Address (HL) starting at the Current Sector.  The returned 
Status (A) is a standard HBIOS result code.

The Current Sector is established by a prior DIOSEEK function call; 
however, multiple read/write/verify function calls can be made after a 
seek function. The Current Sector is incremented after each sector 
successfully written. On error, the Current Sector will be the sector 
where the error occurred. Sectors Written (E) indicates the number of 
sectors successfully written.

Disk data transfers will be faster if the buffer resides in the top 32K 
of memory because it avoids a double copy.

### Function 0x15 -- Disk Verify (DIOVERIFY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x15                                | A: Status                              |
| C: Disk Unit                           | E: Sectors Verified                    |
| E: Sector Count                        |                                        |

**\*\*\* Function Not Implemented \*\*\***

### Function 0x16 -- Disk Format (DIOFORMAT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x16                                | A: Status                              |
| C: Disk Unit                           |                                        |
| D: Head                                |                                        |
| E: Fill Byte                           |                                        |
| HL: Cylinder                           |                                        |

**\*\*\* Function Not Implemented \*\*\***

### Function 0x17 -- Disk Device (DIODEVICE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x17                                | A: Status                              |
| C: Disk Unit                           | C: Device Attributes                   |
|                                        | D: Device Type                         |
|                                        | E: Device Number                       |
|                                        | H: Device Unit Mode                    |
|                                        | L: Device I/O Base Address             |

Reports device information about the specified Disk Unit (C).  The 
Status (A) is a standard HBIOS result code.

Bit 7 of the Device Attribute (C) value returned indicates whether the 
device is a floppy disk.  If it is a floppy disk, the Device Attribute 
(C) value is encoded as follows:

| **Bits** | **Definition**                                   |
|---------:|--------------------------------------------------|
| 7        | = 1 (Floppy Disk)                                |
| 6-5      | Form Factor: 0=8", 1=5.25", 2=3.5", 3=Other      |
| 4        | Sides: 0=SS, 1=DS                                |
| 3-2      | Density: 0=SD, 1=DD, 2=HD, 3=ED                  |
| 1-0      | Reserved                                         |

If the Disk Unit (C) specified is a not floppy disk, then the Device 
Attribute (C) encoding is as follows:

| **Bits** | **Definition**                                   |
|---------:|--------------------------------------------------|
| 7        | = 0 (not Floppy Disk)                            |
| 6        | Removable                                        |
| 5-3      | Type: 0=Hard, 1=CF, 2=SD, 3=USB,                 |
|          | 4=ROM, 5=RAM, 6=RAMF, 7=FLASH                    |
| 2-0      | Reserved                                         |

Device Type (D) indicates the specific hardware driver that handles the 
specified Disk Unit (C).  Values are listed at the start of this 
section. Device Number (E) indicates the physical device number assigned
per driver.  For example, a Device Type of 0x30 with a Device Number 
of 1 refers to the second disk being handled by the IDE driver.

Device Mode (H) is used to indicate the variant of the chip or circuit 
that is used by the specified unit.  For example, for an IDE unit, the 
value indicates the IDE circuit variant.  The Device I/O Base Address 
(L) indicates the starting port address of the hardware interface that 
is servicing the specified unit.  Both of these values are considered 
driver specific.  Refer to the associated hardware driver for the values
used.

### Function 0x18 -- Disk Media (DIOMEDIA)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x18                                | A: Status                              |
| C: Disk Unit                           | E: Media ID                            |
| E: Flags                               |                                        |

Report the Media ID (E) for the for media in the specified Disk Unit 
(C). If bit 0 of Flags (E) is set, then media discovery or verification 
will be performed.  The Status (A) is a standard HBIOS result code. If 
there is no media in device, function will return an error status.

### Function 0x19 -- Disk Define Media (DIODEFMED)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x19                                | A: Status                              |
| C: Disk Unit                           |                                        |
| E: Media ID                            |                                        |

**\*\*\* Function Not Implemented \*\*\***

### Function 0x1A -- Disk Capacity (DIOCAPACITY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x1A                                | A: Status                              |
| C: Disk Unit                           | DEHL: Sector Count                     |
|                                        | BC: Block Size                         |

Report the current media capacity information for the specified Disk Unit (C). 
The Sector Count (DEHL) is a double-word number representing the 
total number of blocks on the device. Block Size (BC) contains the block
size in bytes. The Status (A) is a standard HBIOS result code. If the 
media is unknown, an error will be returned.

This function will not attempt to discover or verify the media loaded in
the unit specified.  You can use precede this function with the 
DIOMEDIA function to force this if desired.

### Function 0x1B -- Disk Geometry (DIOGEOMETRY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x1B                                | A: Status                              |
| C: Disk Unit                           | D: Heads                               |
|                                        | E: Sectors                             |
|                                        | HL: Cylinder Count                     |
|                                        | BC: Block Size                         |

Report the geometry for the media in the specified Disk Unit (C). If a 
device uses LBA mode addressing natively, then the drivers simulated 
geometry will be returned. The Status (A) is a standard HBIOS result 
code.  If the media is unknown, an error will be returned.

Heads (D) refers to the number of heads per cylinder.  Sectors (E)
refers to the number of sectors per track.  Cylinder Count (HL) is the
total number of cylinders addressable for the media.  Block Size (BC)
is the number of bytes in one sector.

`\clearpage`{=latex}

## Real Time Clock (RTC)

The Real Time Clock functions provide read/write access to the clock and
related Non-Volatile RAM.

HBIOS only supports a single RTC device since there is no reason to have
more than one at a time.  The RTC unit is assigned a Device Type ID 
which indicates the specific hardware device driver that handles the 
unit.  The table below enumerates these values.

| **Device Type** | **ID** | **Description**                          | **Driver** |
|-----------------|-------:|------------------------------------------|------------|
| RTCDEV_DS       | 0x00   | Maxim DS1302 Real-Time Clock w/ NVRAM    | dsrtc.asm  |
| RTCDEV_BQ       | 0x10   | BQ4845P Real Time Clock                  | bqrtc.asm  |
| RTCDEV_SIMH     | 0x20   | SIMH Simulator Real-Time Clock           | simrtc.asm |
| RTCDEV_INT      | 0x30   | Interrupt-based Real Time Clock          | intrtc.asm |
| RTCDEV_DS7      | 0x40   | Maxim DS1307 PCF I2C RTC w/ NVRAM        | ds7rtc.asm |
| RTCDEV_RP5      | 0x50   | Ricoh RPC01A Real-Time Clock w/ NVRAM    | rp5rtc.asm |

The time functions to get and set the time (RTCGTM and RTCSTM) require a
6 byte date/time buffer in the following format. Each byte is BCD 
encoded.

| **Offset** | **Contents**                            |
|-----------:|-----------------------------------------|
| 0          | Year (00-99)                            |
| 1          | Month (01-12)                           |
| 2          | Date (01-31)                            |
| 3          | Hours (00-24)                           |
| 4          | Minutes (00-59)                         |
| 5          | Seconds (00-59)                         |

### Function 0x20 -- RTC Get Time (RTCGETTIM)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x20                                | A: Status                              |
| HL: Date/Time Buffer Address           |                                        |

Read the current value of the real-time clock and store the date/time in
the Date/Time Buffer pointed to by HL.  The Status (A) is a standard 
HBIOS result code.

### Function 0x21 -- RTC Set Time (RTCSETTIM)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x21                                | A: Status                              |
| HL: Date/Time Buffer Address           |                                        |

Set the current value of the real-time clock based on the Date/Time 
Buffer pointed to by HL.  The Status (A) is a standard HBIOS result 
code.

### Function 0x22 -- RTC Get NVRAM Byte (RTCGETBYT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x22                                | A: Status                              |
| C: Index                               | E: Value                               |

Read a single byte Value (E) from the Non-Volatile RAM of the RTC at the
byte offset Index (C).  The Status (A) is a standard HBIOS result code.

### Function 0x23 -- RTC Set NVRAM Byte (RTCSETBYT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x23                                | A: Status                              |
| C: Index                               |                                        |
| E: Value                               |                                        |

Set a single byte Value (E) of the Non-Volatile RAM of the RTC at the 
byte offset Index (C).  The Status (A) is a standard HBIOS result code.

### Function 0x24 -- RTC Get NVRAM Block (RTCGETBLK)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x24                                | A: Status                              |
| HL: Buffer Address                     |                                        |

Read the entire contents of the Non-Volatile RAM into to a buffer 
pointed to by Buffer Address (HL).  The Status (A) is a standard HBIOS
result code.

### Function 0x25 -- RTC Set NVRAM Block (RTCSETBLK)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x25                                | A: Status                              |
| HL: Buffer Address                     |                                        |

Write the entire contents of the Non-Volatile RAM from the buffer 
pointed to by Buffer Address (HL).  The Status (A) is a standard HBIOS 
result code.

### Function 0x26 -- RTC Get Alarm (RTCGETALM)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x26                                | A: Status                              |
| HL: Date/Time Buffer Address           |                                        |

Work in progress, documentation required...

### Function 0x27 -- RTC Set Alarm (RTCSETALM)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x27                                | A: Status                              |
| HL: Date/Time Buffer Address           |                                        |

Work in progress, documentation required...

### Function 0x28 -- RTC DEVICE (RTCDEVICE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x28                                | A: Status                              |
|                                        | C: Device Attributes                   |
|                                        | D: Device Type                         |
|                                        | E: Device Number                       |
|                                        | H: Device Unit Mode                    |
|                                        | L: Device I/O Base Address             |

Returns device information for the RTC unit.  The Status (A) is a 
standard HBIOS result code.

Device Attribute (C) values are not yet defined.  Device Type (D) 
indicates the specific hardware driver that handles the specified 
character unit.  Values are listed at the start of this section. Device 
Number (E) indicates the physical device number assigned per driver 
which is always 0 for RTC.

Device Mode (H) is used to indicate the variant of the chip or circuit 
that is used by the specified unit.  The Device I/O Base Address (L) 
indicates the starting port address of the hardware interface that is 
servicing the specified unit.  Both of these values are considered 
driver specific.  Refer to the associated hardware driver for the values
used.

`\clearpage`{=latex}

## Video Display Adapter (VDA)

The VDA functions are provided as a common interface to Video Display
Adapters. Not all VDAs will include keyboard hardware. In this case, the
keyboard functions should return a failure status.

All video units are assigned a Device Type ID which indicates
the specific hardware device driver that handles the unit.  The table
below enumerates there values.

| **Device Type** | **ID** | **Description**                          | **Driver** |
|-----------------|-------:|------------------------------------------|------------|
| VDADEV_VDU      | 0x00   | MC6845 Family Video Display Controller   | vdu.asm    |
| VDADEV_CVDU     | 0x10   | MC8563-based Video Display Controller    | cvdu.asm   |
| VDADEV_GDC      | 0x20   | uPD7220 Video Display Controller         | gdc.asm    |
| VDADEV_TMS      | 0x30   | TMS9918/38/58 Video Display Controller   | tms.asm    |
| VDADEV_VGA      | 0x40   | HD6445CP4-based Video Display Controller | vga.asm    |

Depending on the capabilities of the hardware, the use of colors and
attributes may or may not be supported. If the hardware does not support
these capabilities, they will be ignored.

Color byte values are constructed using typical RGBI
(Red/Green/Blue/Intensity) bits. The high four bits of the value determine
the background color and the low four bits determine the foreground color.
This results in 16 unique color values for both foreground and background.
The following table illustrates the color byte value construction:

| &nbsp;     | **Bit** | **Color** |
|------------|--------:|-----------|
| Background | 7       | Intensity |
| &nbsp;     | 6       | Blue      |
| &nbsp;     | 5       | Green     |
| &nbsp;     | 4       | Red       |
| Foreground | 3       | Intensity |
| &nbsp;     | 2       | Blue      |
| &nbsp;     | 1       | Green     |
| &nbsp;     | 0       | Red       |

The following table illustrates the resultant color for each of the
possible 16 values for foreground or background:

| **Foreground**     | **Background**     | **Color**       |
|--------------------|--------------------| ----------------|
| n0   nnnn0000      | 0n   0000nnnn      | Black           |
| n1   nnnn0001      | 1n   0001nnnn      | Red             |
| n2   nnnn0010      | 2n   0010nnnn      | Green           |
| n3   nnnn0011      | 3n   0011nnnn      | Brown           |
| n4   nnnn0100      | 4n   0100nnnn      | Blue            |
| n5   nnnn0101      | 5n   0101nnnn      | Magenta         |
| n6   nnnn0110      | 6n   0110nnnn      | Cyan            |
| n7   nnnn0111      | 7n   0111nnnn      | White           |
| n8   nnnn1000      | 8n   1000nnnn      | Gray            |
| n9   nnnn1001      | 9n   1001nnnn      | Light Red       |
| nA   nnnn1010      | An   1010nnnn      | Light Green     |
| nB   nnnn1011      | Bn   1011nnnn      | Yellow          |
| nC   nnnn1100      | Cn   1100nnnn      | Light Blue      |
| nD   nnnn1101      | Dn   1101nnnn      | Light Magenta   |
| nE   nnnn1110      | En   1110nnnn      | Light Cyan      |
| nF   nnnn1111      | Fn   1111nnnn      | Bright White    |

Attribute byte values are constructed using the following bit encoding:

| **Bit** | **Effect** |
|--------:|------------|
| 7       | n/a (0)    |
| 6       | n/a (0)    |
| 5       | n/a (0)    |
| 4       | n/a (0)    |
| 3       | n/a (0)    |
| 2       | Reverse    |
| 1       | Underline  |
| 0       | Blink      |

The following codes are returned by a keyboard read to signify non-ASCII
keystrokes:

| **Value** | **Keystroke** | **Value** | **Keystroke** |
|----------:|---------------|----------:|---------------|
| 0xE0      | F1            | 0xF0      | Insert        |
| 0xE1      | F2            | 0xF1      | Delete        |
| 0xE2      | F3            | 0xF2      | Home          |
| 0xE3      | F4            | 0xF3      | End           |
| 0xE4      | F5            | 0xF4      | PageUp        |
| 0xE5      | F6            | 0xF5      | PadeDown      |
| 0xE6      | F7            | 0xF6      | UpArrow       |
| 0xE7      | F8            | 0xF7      | DownArrow     |
| 0xE8      | F9            | 0xF8      | LeftArrow     |
| 0xE9      | F10           | 0xF9      | RightArrow    |
| 0xEA      | F11           | 0xFA      | Power         |
| 0xEB      | F12           | 0xFB      | Sleep         |
| 0xEC      | SysReq        | 0xFC      | Wake          |
| 0xED      | PrintScreen   | 0xFD      | Break         |
| 0xEE      | Pause         | 0xFE      |               |
| 0xEF      | App           | 0xFF      |               |

### Function 0x40 -- Video Initialize (VDAINI)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x40                                | A: Status                              |
| C: Video Unit                          |                                        |
| E: Video Mode                          |                                        |
| HL: Font Bitmap                        |                                        |

Performs a full (re)initialization of the specified Video Unit (C). The 
screen is cleared and the keyboard buffer is flushed. If the specified 
Video Unit (C) supports multiple video modes, a Video Mode (E) can be 
specified (set to 0 for default/not specified). Video Mode (E) values 
are specific to each VDA.  The returned Status (A) is a standard HBIOS 
result code.

If the hardware and driver support it, you can specify a Font Bitmap 
(HL) buffer address containing the character bitmap data to be loaded 
into the video processor.  The buffer **must** be located entirely in the 
top 32K of the CPU memory space. HL must be set to zero if no character 
bitmap is specified (the driver will utilize a default character 
bitmap).

### Function 0x41 -- Video Query (VDAQRY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x41                                | A: Status                              |
| C: Video Unit                          | C: Video Mode                          |
| HL: Font Bitmap                        | D: Rows                                |
|                                        | E: Columns                             |
|                                        | HL: Font Bitmap                        |

Return information about the specified Video Unit (C). Video Mode (C) 
will be set to the current video mode. Rows (D) and Columns (E) will 
return the dimensions of the video display as measured in rows and 
columns. Note that this is the **count** of rows and columns, not the 
**last** row/column number.  The returned Status (A) is a standard HBIOS
result code.

If the hardware and driver support it, you can specify a Font Bitmap (HL)
buffer address that will be filled with the current
character bitmap data.  The buffer **must** be located entirely in the 
top 32K of the CPU memory space.  Font Bitmap (HL) **must** be set to
zero if it does not point to a proper buffer area or memory corruption
will result.

If HL is not zero, it must point to a suitably sized memory buffer in
the upper 32K of CPU address space that will be filled with the current
character bitmap data. It is critical that HL be set to zero if it does
not point to a proper buffer area or memory corruption will result. If
the video device driver does not have the ability to provide character bitmap
data, then Font Bitmap (HL) will be set to zero on return.

### Function 0x42 -- Video Reset (VDARES)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x42                                | A: Status                              |
| C: Video Unit                          |                                        |

Performs a soft reset of the specified Video Unit (C). Will clear the 
screen, home the cursor, and restore active attribute/color to defaults.
Keyboard will be flushed.  The current video mode will not be changed. 
The returned Status (A) is a standard HBIOS result code.

### Function 0x43 -- Video Device (VDADEV)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x43                                | A: Status                              |
| C: Video Unit                          | C: Device Attributes                   |
|                                        | D: Device Type                         |
|                                        | E: Device Number                       |
|                                        | H: Device Unit Mode                    |
|                                        | L: Device I/O Base Address             |

Reports device information about the specified Video Unit (C).  The 
Status (A) is a standard HBIOS result code.

Device Attribute (C) values are not yet defined.  

Device Type (D) indicates the specific hardware driver that handles the 
specified Video Unit (C).  Values are listed at the start of this 
section. Device Number (E) indicates the physical device number assigned
per driver.

Device Mode (H) is used to indicate the variant of the chip or circuit 
that is used by the specified unit.  For example, for an TMS video unit, the 
value indicates the TMS circuit variant.  The Device I/O Base Address 
(L) indicates the starting port address of the hardware interface that 
is servicing the specified unit.  Both of these values are considered 
driver specific.  Refer to the associated hardware driver for the values
used.

### Function 0x44 -- Video Set Cursor Style (VDASCS)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x44                                | A: Status                              |
| C: Video Unit                          |                                        |
| D: Start/End                           |                                        |
| E: Style                               |                                        |

If supported by the specified Video Unit (C), adjust the format of the 
cursor such that the cursor starts at the pixel specified in the top 
nibble of Start/End (D) and ends at the pixel specified in the bottom 
nibble of Start/End (D). So, if D=0x08, a block cursor would be used 
that starts at the top pixel of the character cell and ends at the ninth
pixel of the character cell.  The Status (A) is a standard HBIOS result
code.

Style (E) is reserved to control the style of the cursor (blink, 
visibility, etc.), but is not yet implemented.

Adjustments to the cursor style may or may not be possible for any given
video hardware and may be dependent on the active video mode.

### Function 0x45 -- Video Set Cursor Position (VDASCP)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x45                                | A: Status                              |
| C: Video Unit                          |                                        |
| D: Row                                 |                                        |
| E: Column                              |                                        |

Reposition the cursor of the specified Video Unit (C) to the specified 
Row (D) and Column (E). Specifying a row/column that exceeds the 
boundaries of the display results in undefined behavior. Cursor 
coordinates are 0 based (0,0 is the upper left corner of the display).
The Status (A) is a standard HBIOS result code.

### Function 0x46 -- Video Set Character Attribute (VDASAT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x46                                | A: Status                              |
| C: Video Unit                          |                                        |
| E: Attribute                           |                                        |

Assign the specified character Attribute (E) code to be used for all 
subsequent character writes/fills on the specified Video Unit (C). This 
attribute is used to fill new lines generated by scroll operations. The 
character attributes values are listed abovev. Note that a given video 
display may or may not support any/all attributes.  The Status (A) is a 
standard HBIOS result code.

### Function 0x47 -- Video Set Character Color (VDASCO)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x47                                | A: Status                              |
| C: Video Unit                          |                                        |
| E: Color                               |                                        |

Assign the specified Color (E) code to be used for all subsequent 
character writes/fills. This color is also used to fill new lines 
generated by scroll operations. Refer to the color code table above for 
a list of the available color codes. Note that a given video display may
or may not support any/all colors.  The Status (A) is a standard HBIOS 
result code.

### Function 0x48 -- Video Write Character (VDAWRC)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x48                                | A: Status                              |
| C: Video Unit                          |                                        |
| E: Character                           |                                        |

Write the Character (E) value to the display of the specified Video Unit
(C). The character is written starting at the current cursor position 
and the cursor is advanced. If the end of the line is encountered, the 
cursor will be advanced to the start of the next line. The display will 
**not** scroll if the end of the screen is exceeded.  The Status (A) is 
a standard HBIOS result code.

### Function 0x49 -- Video Fill (VDAFIL)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x49                                | A: Status                              |
| C: Video Unit                          |                                        |
| E: Character                           |                                        |
| HL: Count                              |                                        |

Write the Character (E) value to the Video Unit (C) display the number 
of times specified by Count (HL). Characters are written starting at the
current cursor position and the cursor is advanced by the number of 
characters written. If the end of the line is encountered, the 
characters will continue to be written starting at the next line as 
needed. The display will **not** scroll if the end of the screen is 
exceeded.  Writing characters beyond the end of the screen results in 
undefined behavior.  The Status (A) is a standard HBIOS result code.

### Function 0x4A -- Video Copy (VDACPY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x4A                                | A: Status                              |
| C: Video Unit                          |                                        |
| D: Source Row                          |                                        |
| E: Source Column                       |                                        |
| L: Count                               |                                        |

Copy Count (L) bytes from the specified Video Unit (C) display Source 
Row (D) and Source Column (E) to the current cursor position. The cursor
position is not updated. The maximum Count (L) value is 255. Copying 
to/from overlapping areas is not supported and will have an undefined 
behavior. The display will **not** scroll if the end of the screen is 
exceeded. Copying beyond the active screen buffer area is not supported 
and results in undefined behavior.  The Status (A) is a standard HBIOS 
result code.

### Function 0x4B -- Video Scroll (VDASCR)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x4B                                | A: Status                              |
| C: Video Unit                          |                                        |
| E: Lines                               |                                        |

Scroll the video display of the specified Video Unit (C) forward or 
backwards by number of Lines (E) specified.  If Lines (E) is positive, 
then a forward scroll is performed.  If Lines (E) contains a negative 
number, then a reverse scroll will be performed.  This function will 
scroll the entire screen contents.  New lines revealed during the scroll
 operation will be filled with space characters (0x20) using the active 
character attribute and color.  The cursor position will **not** be 
updated.  The Status (A) is a standard HBIOS result code.

### Function 0x4C -- Video Keyboard Status (VDAKST)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x4C                                | A: Status / Codes Pending              |
| C: Video Unit                          |                                        |

Return a count of the number of key Codes Pending (A) in the keyboard 
buffer for the specified Video Unit (C). If it is not possible to 
determine the actual number in the buffer, it is acceptable to return 1 
to indicate there are key codes available to read and 0 if there are 
none available.

The value returned in register A is used as both a Status (A) code and 
the return value. Negative values (bit 7 set) indicate a standard HBIOS 
result (error) code.  Otherwise, the return value represents the number 
of key codes pending.

### Function 0x4D -- Video Keyboard Flush (VDAKFL)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x4D                                | A: Status                              |
| C: Video Unit                          |                                        |

If a keyboard buffer is in use on the Video Unit (C) specified, it 
should be purged and all contents discarded.  The Status (A) is a 
standard HBIOS result code.

### Function 0x4E -- Video Keyboard Read (VDAKRD)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x4E                                | A: Status                              |
| C: Video Unit                          | C: Scancode                            |
|                                        | D: Keystate                            |
|                                        | E: Keycode                             |

Read the next key data from keyboard of the specified Video Unit (C). If
 a keyboard buffer is used, return the next key code in the buffer. If 
no key data is available, this function will wait indefinitely for a 
keypress.  The Status (A) is a standard HBIOS result code.

The Scancode (C) value is the raw scancode from the keyboard for the 
keypress. Scancodes are from the PS/2 scancode set 2 standard.

The Keystate (D) is a bitmap representing the value of all modifier keys
 and shift states as they existed at the time of the keystroke. The 
bitmap is defined as:

| **Bit** | **Keystate Indication**          |
|---------|----------------------------------|
| 7       | Key pressed was from the num pad |
| 6       | Caps Lock was active             |
| 5       | Num Lock was active              |
| 4       | Scroll Lock was active           |
| 3       | Windows key was held down        |
| 2       | Alt key was held down            |
| 1       | Control key was held down        |
| 0       | Shift key was held down          |

The Keycode (E) is generally returned as appropriate ASCII values, if 
possible. Special keys, like function keys and arrows, are returned as 
reserved codes as described at the start of this section.

`\clearpage`{=latex}

### Function 0x4F -- Read a character at current video position (VDARDC)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x4F                                | A: Status                              |
| C: Video Unit                          | E: Character                           |
|                                        | B: Color                               |
|                                        | E: Attribute                           |

This function will return the character data from the current cursor 
position of the display of the specified Video Unit (C).  The data 
returned includes the Character (E) value, the Color (B), and the 
Attribute (E) corresponding to the current cursor position. If the 
display does not support colors or attributes then this function will 
return color white on black with no attributes.  The ability to perform 
this function may not be available for all video devices. The Status (A)
is a standard HBIOS result code.

`\clearpage`{=latex}

## Sound (SND)

Sound functions require that a Sound Unit number be specified in 
register C. This is the logical device unit number assigned during the 
boot process that identifies all sound devices uniquely.

All sound units are assigned a Device Type ID which indicates
the specific hardware device driver that handles the unit.  The table
below enumerates these values.

| **Device Type** | **ID** | **Description**                              | **Driver**  |
|-----------------|-------:|----------------------------------------------|-------------|
| SNDDEV_SN76489  | $00    | SN76489 Programmable Sound Generator         | sn76489.asm |
| SNDDEV_AY38910  | $10    | AY-3-8910/YM2149 Programmable Sound Generator| ay38910.asm |
| SNDDEV_BITMODE  | $20    | Bit-bang Speaker                             | spk.asm     |
| SNDDEV_YM2612   | $30    | YM2612 Programmable Sound Generator          | ym2612.asm  |

The Sound functions defer the actual programming of the sound chip
until the SNDPLAY function is called.  You will call the volume
and period/note functions to preset the desired sound output, then
call SNDPLAY when you want the sound to change.

The Sound functions do not manage the duration of the sound
played.  A sound will play
indefinitely -- the caller must implement an appropriate timing
mechanism to manage the playing of a series of sounds.

```
HBIOS B=51 C=00 L=80      ; Set volume to half level
HBIOS B=53 C=00 HL=152    ; Select Middle C (C4)
HBIOS B=54 C=00 D=01      ; Play note on Channel 1
```

### Function 0x50 -- Sound Reset (SNDRESET)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x50                                | A: Status                              |
| C: Sound Unit                          |                                        |

Reset the sound chip of specified Sound Unit (C).  Turn off all sounds 
and set volume on all channels to silence.  The returned Status (A) is a
standard HBIOS result code.

### Function 0x51 -- Sound Volume (SNDVOL)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x51                                | A: Status                              |
| C: Sound Unit                          |                                        |
| L: Volume                              |                                        |

This function sets the sound chip Volume (L) for the specified Sound 
Unit (C).  Volume (L) is a binary value ranging from 0 (silence) to 255 
(maximum).  The volume will be applied when the next SNDPLAY function is
invoked.  The returned Status (A) is a standard HBIOS result code.

Note that not all sounds chips implement 256 volume levels.  The
driver will scale the volume to the closest possible level the
chip provides.

### Function 0x52 -- Sound Period (SNDPRD)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x52                                | A: Status                              |
| C: Sound Unit                          |                                        |
| HL: Period                             |                                        |

This function sets the sound chip Period (HL) for the specified Sound 
Unit (C).  The period will be applied when the next SNDPLAY function is 
invoked.  The returned Status (A) is a standard HBIOS result code.

The Period (HL) value is **not** a standardized value.  The value is 
programmed directly into the period or frequency register of the sound 
chip.  It is therefore a hardware dependent value.  To play standardized
notes, use the SNDNOTE function.

### Function 0x53 -- Sound Note (SNDNOTE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x53                                | A: Status                              |
| C: Sound Unit                          |                                        |
| HL: Note                               |                                        |

This function sets the frequency generated by the sound of the specified
Sound Unit (C).  The frequency is standardized and is specified by 
using values that correspond to musical notes.  The frequency will be 
applied when the next SNDPLAY function is invoked.  The returned Status 
(A) is a standard HBIOS result code.

The Note (HL) values correspond to quarter notes.  Increasing/decreasing
the value by 4 results in a full note increment/decrement.  
Increasing/decreasing the value by 48 results in a full octave 
increment/decrement.  The value 0 corresponds to Bb/A# in octave 0.

The sound chip resolution and its oscillator limit the range and 
accuracy of the notes played. The typical range of the AY-3-8910 is six 
octaves: Bb2/A#2 to A7, where each value is a unique tone.  Values above
and below can still be played but each quarter tone step may not result
in a note change.

The following table shows the mapping of the Note (HL) value to the 
corresponding octave and note.

+------------+-------+-------+-------+-------+-------+-------+-------+-------+
|            | **Octave**                                                    |
|            +-------+-------+-------+-------+-------+-------+-------+-------+
| **Note**   | **0** | **1** | **2** | **3** | **4** | **5** | **6** | **7** |
+============+=======+=======+=======+=======+=======+=======+=======+=======+
| **C**      | \-    | 8     | 56    | 104   | 152   | 200   | 248   | 296   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **C#/Db**  | \-    | 12    | 60    | 108   | 156   | 204   | 252   | 300   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **D**      | \-    | 16    | 64    | 112   | 160   | 208   | 256   | 304   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **D#/Eb**  | \-    | 20    | 68    | 116   | 164   | 212   | 260   | 308   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **E**      | \-    | 24    | 72    | 120   | 168   | 216   | 264   | 312   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **F**      | \-    | 28    | 76    | 124   | 172   | 220   | 268   | 316   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **F#/Gb**  | \-    | 32    | 80    | 128   | 176   | 224   | 272   | 320   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **G**      | \-    | 36    | 84    | 132   | 180   | 228   | 276   | 324   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **G#/Ab**  | \-    | 40    | 88    | 136   | 184   | 232   | 280   | 328   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **A**      | \-    | 44    | 92    | 140   | 188   | 236   | 284   | 332   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **A#/Bb**  | 0     | 48    | 96    | 144   | 192   | 240   | 288   | 336   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+
| **B**      | 4     | 52    | 100   | 148   | 196   | 244   | 292   | 340   |
+------------+-------+-------+-------+-------+-------+-------+-------+-------+

### Function 0x54 -- Sound Play (SNDPLAY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x54                                | A: Status                              |
| C: Sound Unit                          |                                        |
| D: Channel                             |                                        |

This function applies the previously specified volume and frequency of 
the specified Sound Unit (C) by programming the sound chip with the 
appropriate values.  The values are applied to the specified Channel (D)
of the chip.  The returned Status (A) is a standard HBIOS result code.

Note that there is no duration for the sound output -- the programmed 
sound will be played indefinitely.  It is up to the user to wait the 
desired amount of time, then change or silence the sound output as 
desired.

The number of channels available on a sound chip varies.  It is up to 
the caller to ensure that the appropriate number of channels are being 
programmed.

### Function 0x55 -- Sound Query (SNDQUERY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x55                                | A: Status                              |
| C: Sound Unit                          |                                        |
| E: Subfunction                         |                                        |

This function will return a variety of information for a specified Sound
Unit (C) according to the Subfunction (E) specified.  The returned 
Status (A) is a standard HBIOS result code.

#### SNDQUERY Subfunction 0x01 -- Get count of audio channels supported (SNDQ_CHCNT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x55                                | A: Status                              |
| C: Sound Unit                          | B: Tone Channels                       |
| E: 0x01                                | C: Noise Channels                      |

#### SNDQUERY Subfunction 0x02 -- Get current volume setting (SNDQ_VOL)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x55                                | A: Status                              |
| C: Sound Unit                          | L: Volume                              |
| E: 0x02                                |                                        |

#### SNDQdERY Subfunction 0x03 -- Get current period setting (SNDQ_PERIOD)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x55                                | A: Status                              |
| C: Sound Unit                          | HL: Period                             |
| E: 0x03                                |                                        |

#### SNDQUERY Subfunction 0x04 -- Get device details (SNDQ_DEV)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x55                                | A: Status                              |
| C: Sound Unit                          | B: Driver Identity                     |
| E: 0x04                                | HL: Ports                              |
|                                        | DE: Ports                              |

This subfunction reports detailed device informatoin for the specified 
Sound Unit (C).

Driver Identity (B) reports the audio device type.  Ports (HL & DE) 
return relevant port addresses for the hardware specific to each device 
type.

The following table defines the specific port information per device 
type:

| *Audio ID*     | *Value* | *Device*   | *Returned Registers*                        |
|----------------| -------:|------------|---------------------------------------------|
| SND_SN76489    | 0x01    | SN76489    | E=Left channel port, L=Right channel port   |
| SND_AY38910    | 0x02    | AY-3-8910  | D=Address port, E=Data port                 |
| SND_BITMODE    | 0x03    | I/O PORT   | D=Address port, E=Bit mask                  |
| SND_YM2612     | 0x04    | YM2612     | Part 0: D=Address port, E=Data port         |
|                |         |            | Part 1: D=Address port, L=Part 1 Data port  |

### Function 0x56 -- Sound Duration (SNDDUR)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x56                                | A: Status                              |
| C: Sound Unit                          |                                        |
| HL: Duration                           |                                        |

This function sets the Duration (HL) of the note to be played in 
milliseconds for the specified Sound Unit (C).  This function just sets 
the duration, the actual duration is applied in the SNDPLAY function.

If the Duration (HL) is set to zero, then the SNDPLAY function will 
operate in a non-blocking mode. i.e. a tone will start playing and the 
play function will return. The tone will continue to play until the next
 tone is played.  If the Duration (HL) is greater than zero, the the 
sound will play for the duration defined in HL and then return.

**\*\*\* Function Not Implemented \*\*\**

### Function 0x57 -- Sound Device (SNDDEVICE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0x57                                | A: Status                              |
| C: Disk Unit                           | C: Device Attributes                   |
|                                        | D: Device Type                         |
|                                        | E: Device Number                       |
|                                        | H: Device Unit Mode                    |
|                                        | L: Device I/O Base Address             |

Reports device information about the specified Sound Unit (C).  The 
Status (A) is a standard HBIOS result code.

The Device Attributes (C) value is not yet defined.

Device Type (D) indicates the specific hardware driver that handles the 
specified Sound Unit (C).  Values are listed at the start of this 
section. Device Number (E) indicates the physical device number assigned
per driver.

Device Mode (H) is used to indicate the variant of the chip or circuit 
that is used by the specified unit.  The Device I/O Base Address 
(L) indicates the starting port address of the hardware interface that 
is servicing the specified unit.  Both of these values are considered 
driver specific.  Refer to the associated hardware driver for the values
used.

`\clearpage`{=latex}

## System (SYS)

### Function 0xF0 -- System Reset (SYSRESET)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF0                                | A: Status                              |
| C: Subfunction                         |                                        |

This function performs various forms of a system reset depending on
the value of Subfunction (C):

Soft Reset (0x00):

  : Perform a soft reset of HBIOS. Releases all HBIOS memory allocated 
    by current OS. Does not reinitialize physical devices.

Warm Start (0x01):

  : Warm start the system returning to the boot loader prompt.  Does not
    reinitialize physical devices.
  
Cold Start (0x02):

  : Perform a system cold start (like a power on).  All devices are
    reinitialized.

The Status (A) is a standard HBIOS result code.

### Function 0xF1 -- System Version (SYSVER)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF1                                | A: Status                              |
| C: Reserved                            | DE: Version                            |
|                                        | L: Platform                            |

This function will return the HBIOS Version (DE) number and Platform (L)
identifier. The Status (A) is a standard HBIOS result code.

The Version (DE)number is encoded as BCD where the 4 digits are:

  [Major Version][Minor Version][Patch Level][Build Number]

So, for example, a Version (L) number of 0x3102 would indicate
version 3.1.0, build 2.

The hardware Platform (L) is identified as follows:

| **Name**      | **Id** | **Platform **                           |
|---------------|-------:|-----------------------------------------|
| PLT_SBC       |1       | ECB Z80 SBC                             |
| PLT_ZETA      |2       | ZETA Z80 SBC                            |
| PLT_ZETA2     |3       | ZETA Z80 V2 SBC                         |
| PLT_N8        |4       | N8 (HOME COMPUTER) Z180 SBC             |
| PLT_MK4       |5       | MARK IV                                 |
| PLT_UNA       |6       | UNA BIOS                                |
| PLT_RCZ80     |7       | RCBUS W/ Z80                            |
| PLT_RCZ180    |8       | RCBUS W/ Z180                           |
| PLT_EZZ80     |9       | EASY/TINY Z80                           |
| PLT_SCZ180    |10      | RCBUS SC126, SC130, SC131, SC140        |
| PLT_DYNO      |11      | DYNO MICRO-ATX MOTHERBOARD              |
| PLT_RCZ280    |12      | RCBUS W/ Z280                           |
| PLT_MBC       |13      | NHYODYNE MULTI-BOARD COMPUTER           |
| PLT_RPH       |14      | RHYOPHYRE GRAPHICS SBC                  |

### Function 0xF2 -- System Set Bank (SYSSETBNK)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF2                                | A: Status                              |
| C: Bank ID                             | C: Prior Bank ID                       |

Activates the specified memory Bank ID (C) and returns the Prior Bank ID
 (C). The function **must** be invoked from code located in the upper 
32K and the stack **must** be in the upper 32K.  The Status (A) is a 
standard HBIOS result code.

### Function 0xF3 -- System Get Bank (SYSGETBNK)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF3                                | A: Status                              |
|                                        | C: Bank ID                             |

Returns the currently active Bank ID (C).  The Status (A) is a standard 
HBIOS result code.

### Function 0xF4 -- System Set Copy (SYSSETCPY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF4                                | A: Status                              |
| D: Destination Bank ID                 |                                        |
| E: Source Bank ID                      |                                        |
| HL: Byte Count                         |                                        |

Prepare for a subsequent interbank memory copy (SYSBNKCPY) function call
by setting the Source Bank ID (E), Destination Bank ID (D), and Byte Count 
(HL) to be copied. The bank ID's are not range checked and must
be valid for the system in use.  The Status (A) is a standard 
HBIOS result code.

No bytes are copied by this function. The SYSBNKCPY function must be 
called to actually perform the copy. The values setup by this function 
will remain unchanged until another call is make to this function. So, 
after calling SYSSETCPY, you may make multiple calls to SYSBNKCPY as 
long as you want to continue to copy between the already established 
Source/Destination Banks and the same size copy is being performed.

### Function 0xF5 -- System Bank Copy (SYSBNKCPY)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF5                                | A: Status                              |
| DE: Destination Address                | DE: New Destination Address            |
| HL: Source Address                     | HL: New Source Address                 |

Copy a block of memory between banks. The Source Bank, Destination Bank, and Byte
Count to copy **must** be established with a prior call to SYSSETCPY.
However, it is not necessary to call SYSSETCPY prior to subsequent calls
to SYSBNKCPY if the source/destination banks and copy length do not
change.

On return, the New Destination Address (DE) will be value of the 
original Destination Address (DE) incremented by the count of bytes 
copied.  Likewise for the New Source Address (HL).  This allows 
iterative invocations of this function to continue copying where the 
prior invocation left off.

The Status (A) is a standard HBIOS result code.

WARNINGS:

* This function is inherently dangerous and does not prevent you from
  corrupting critical areas of memory. Use with **extreme** caution.

* Overlapping source and destination memory ranges are not supported and
  will result in undetermined behavior.

* Copying of byte ranges that cross bank boundaries is undefined.

### Function 0xF6 -- System Alloc (SYSALLOC)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF6                                | A: Status                              |
| HL: Block Size                         | HL: Block Address                      |

This function will attempt to allocate a Block Size (HL) bytes block of 
memory from the internal HBIOS heap. The HBIOS heap resides in the HBIOS
bank in the area of memory left unused by HBIOS. If the allocation is 
successful, the Block Address (HL) of the allocated memory block is 
returned in HL. You will typically need to use the SYSBNKCPY function to
read/write the allocated memory.  The Status (A) is a standard HBIOS 
result code.

### Function 0xF7 -- System Free (SYSFREE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF7                                | A: Status                              |
| HL: Block Address                      |                                        |

**\*\*\* Function Not Implemented \*\*\***

Note that all allocated memory can be freed by calling the SYSRESET
function with a subfunction code of 0x00 (Soft Reset).

### Function 0xF8 -- System Get (SYSGET)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: Subfunction                         |                                        |

This function will report various system information based on the 
sub-function value. The following lists the subfunctions available along
with the registers/information utilized.  The Status (A) is a standard 
HBIOS result code.

#### SYSGET Subfunction 0x00 -- Get Character Device Unit Count (CIOCNT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x00                                | E: Count                               |

Return the Count (E) of character device units.  The Status (A) is a 
standard HBIOS result code.

#### SYSGET Subfunction 0x01 -- Get Serial Unit Function (CIOFN)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x01                                | HL: Function Address                   |
| D: Function                            | DE: Unit Data Address                  |
| E: Unit                                |                                        |

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
CIO function number to lookup in D and the CIO unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).  See
Appendix A for details.  The returned Status (A) is a standard HBIOS 
result code.

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0x10 -- Get Disk Device Unit Count (DIOCNT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x10                                | E: Count                               |

Return the Count (E) of disk device units.  The Status (A) is a 
standard HBIOS result code.

#### SYSGET Subfunction 0x11 -- Get Disk Unit Function (DIOFN)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x11                                | HL: Function Address                   |
| D: Function                            | DE: Unit Data Address                  |
| E: Unit                                |                                        |

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
DIO function number to lookup in D and the DIO unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).  See
Appendix A for details.  The returned Status (A) is a standard HBIOS 
result code.

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0x20 -- Get RTC Device Unit Count (RTCCNT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x20                                | E: Count                               |

Return the Count (E) of RTC device units.  The Status (A) is a 
standard HBIOS result code.

#### SYSGET Subfunction 0x40 -- Get Video Device Unit Count (VDACNT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x40                                | E: Count                               |

Return the Count (E) of video device units.  The Status (A) is a 
standard HBIOS result code.

#### SYSGET Subfunction 0x41 -- Get Video Unit Function (VDAFN)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x41                                | HL: Function Address                   |
| D: Function                            | DE: Unit Data Address                  |
| E: Unit                                |                                        |

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
VDA function number to lookup in D and the VDA unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).  See
Appendix A for details.  The returned Status (A) is a standard HBIOS 
result code.

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0x50 -- Get Sound Device Unit Count (SNDCNT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x50                                | E: Count                               |

Return the Count (E) of sound device units.  The Status (A) is a 
standard HBIOS result code.

#### SYSGET Subfunction 0x51 -- Get Sound Unit Function (SNDFN)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0x51                                | HL: Function Address                   |
| D: Function                            | DE: Unit Data Address                  |
| E: Unit                                |                                        |

This function will lookup the actual driver function address and
unit data address inside the HBIOS driver.  On entry, place the
SND function number to lookup in D and the SND unit number in E.
On return, HL will contain the address of the requested function
in the HBIOS driver (in the HBIOS bank).  DE will contain the
associated unit data address (also in the HBIOS bank).  See
Appendix A for details.  The returned Status (A) is a standard HBIOS 
result code.

This function can be used to speed up HBIOS calls by looking up the
function and data address for a specific driver function.  After this,
the caller can use interbank calls directly to the function in the
driver which bypasses the overhead of the normal function invocation
lookup.

#### SYSGET Subfunction 0xD0 -- Get Timer Tick Count (TIMER)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0xD0                                | DEHL: Tick Count                       |
|                                        | C: Frequency                           |

Return the value of the global system timer Tick Count (DEHL).  This is 
a double-word binary value.  The frequency of the system timer in Hertz 
is returned in Frequncy (C). The returned Status (A) is a standard HBIOS
result code.

Note that not all hardware configuration have a system timer.  You
can determine if a timer exists by calling this function repeatedly
to see if it is incrementing.

#### SYSGET Subfunction 0xD1 -- Get Seconds Count (SECONDS)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0xD1                                | DEHL: Seconds Count                    |
|                                        | C: Ticks per Second                    |

Return the a Seconds Count (DEHL) with the number of seconds that have 
elapsed since the system was started.  This is a double-word binary 
value.  Additionally, the number of Ticks per Second (C) is returned.  
The returned Status (A) is a standard HBIOS result code.

This availability of the Seconds Count (DEHL) is dependent on having a 
system timer active.  If the hardware configuration has no system timer,
then Seconds Count (DEHL) will not increment.

#### SYSGET Subfunction 0xE0 -- Get Boot Information (BOOTINFO)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0xE0                                | L: Boot Bank ID                        |
|                                        | D: Boot Disk Unit                      |
|                                        | E: Boot Disk Slice                     |

This function returns information about the most recent boot operation 
performed.  It includes the Boot Bank ID (L), the Boot Disk Unit (D), 
and the Boot Disk Slice (E).  The returned Status (A) is a standard 
HBIOS result code.

#### SYSGET Subfunction 0xF0 -- Get CPU Information (CPUINFO)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0xF0                                | H: Z80 CPU Variant                     |
|                                        | L: CPU Speed MHz                       |
|                                        | DE: CPU Speed KHz                      |
|                                        | BC: Oscillator Speed KHz               |

This function returns information about the active CPU environment. The 
Z80 CPU Variant (H) will be one of: 0=Z80, 1=Z180, 2=Z180-K, 3=Z180-N, 
4=Z280.  The current CPU speed is provided as both CPU Speed MHz (L) and
CPU Speed KHz (DE).  The raw oscillator speed is provided as Oscillator
Speed KHz (BC).  The returned Status (A) is a standard HBIOS result 
code.

#### SYSGET Subfunction 0xF1 -- Get Memory Information (MEMINFO)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0xF1                                | D: ROM Bank Count                      |
|                                        | E: RAM Bank Count                      |

This function returns the systems ROM Bank Count (D) and RAM Bank Count 
(E).  Each bank is 32KB by definition.  The returned Status (A) is a 
standard HBIOS result code.

#### SYSGET Subfunction 0xF2 -- Get Bank Information (BNKINFO)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0xF2                                | D: BIOS Bank ID                        |
|                                        | E: User Bank ID                        |

Certain memory banks within a RomWBW system are special.  The exact bank
id for each of these varies depending on the configuration of the 
system.  This function can be used to determine the BIOS Bank ID (D) and
the User Bank ID (E).  The returned Status (A) is a standard HBIOS 
result code.

#### SYSGET Subfunction 0xF3 -- Get CPU Speed (CPUSPD)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF8                                | A: Status                              |
| C: 0xF3                                | L: Clock Mult                          |
|                                        | D: Memory Wait States                  |
|                                        | E: I/O Wait States                     |

This function will return the running CPU speed attributes of a system. 
The Clock Mult (L) returned indicates the frequency multiple being 
applied to the raw oscillator clock.  If is defined as: 0=Half, 2=Full, 
and 3=Double.  The wait states for the system are also provided as 
Memory Wait States (D) and I/O Wait States (E).  The value of Memory
Wait States (D) is the actual number of wait states, not the number
of wait states added.  The returned Status (A) is a standard HBIOS 
result code.

### Function 0xF9 -- System Set (SYSSET)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF9                                | A: Status                              |
| C: Subfunction                         |                                        |

This function will set various system parameters based on the 
sub-function value. The following lists the subfunctions available along
with the registers/information utilized.  The Status (A) is a standard 
HBIOS result code.

#### SYSSET Subfunction 0xD0 -- Set Timer Tick Count (TIMER)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF9                                | A: Status                              |
| C: 0xD0                                | DEHL: Timer Tick Count                 |

This function will explicitly set the system Timer Tick Count (DEHL) 
value.  DEHL is a double-word binary value.  The Status (A) is a 
standard HBIOS result code.

#### SYSSET Subfunction 0xD1 -- Set Seconds Count (SECONDS)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF9                                | A: Status                              |
| C: 0xD1                                |                                        |
| DEHL: Seconds Count                    |                                        |

This function will explicitly set the system Seconds Count (DEHL) value.
DEHL is a double-word binary value.  The Status (A) is a standard 
HBIOS result code.

#### SYSSET Subfunction 0xE0 -- Set Boot Information (BOOTINFO)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF9                                | A: Status                              |
| C: 0xE0                                |                                        |
| L: Boot Bank ID                        |                                        |
| D: Boot Disk Unit                      |                                        |
| E: Boot Disk Slice                     |                                        |

This function sets information about the most recent boot operation 
performed.  It includes the Boot Bank ID (L), the Boot Disk Unit (D), 
and the Boot Disk Slice (E).  The returned Status (A) is a standard 
HBIOS result code.

#### SYSSET Subfunction 0xF3 -- Set CPU Speed (CPUSPD)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xF9                                | A: Status                              |
| C: 0xF3                                |                                        |
| L: Clock Mult                          |                                        |
| D: Memory Wait States                  |                                        |
| E: I/O Wait States                     |                                        |

This function will modify the running CPU speed attributes of a system.
Note that it is frequently impossible to tell if a system is capable
of dynamic speed changes.  This function makes the changes blindly.
You can specify 0xFF for either of the wait state settings to have them
left alone.  If an attempt is made to change the speed of a system
that is definitely incapable of doing so, then an error result is
returned.  The returned Status (A) is a standard HBIOS result code.

The function will attempt to set the CPU speed based on the Clock Mult 
(L) value: 0=Half, 1=Full, 2=Double.  Memory Wait States (D) and I/O 
Wait States (E) will be set if possible.  The value of Memory Wait 
States (D) is the actual number of wait states, not the number of wait 
states added.

Some peripherals are dependant on the CPU speed.  For example, the Z180
ASCI baud rate and system timer are derived from the CPU speed.  The
Set CPU Speed function will attempt to adjust these peripherals for
correct operation after modifying the CPU speed.  However, in some
cases this may not be possible.  The baud rate of ASCI ports have a
limited set of divisors.  If there is no satisfactory divisor to
retain the existing baud rate under the new CPU speed, then the baud
rate of the ASCI port(s) will be affected.

### Function 0xFA -- System Peek (SYSPEEK)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xFA                                | A: Status                              |
| D: Bank ID                             | E: Byte Value                          |
| HL: Memory Address                     |                                        |

This function retrieves and returns the Byte Value from the specified 
Bank ID (D) and Memory Address (HL).  The bank specified is not range 
checked.  The Status (A) is a standard HBIOS result code.

### Function 0xFB -- System Poke (SYSPOKE)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xFB                                | A: Status                              |
| D: Bank ID                             |                                        |
| HL: Memory Address                     |                                        |
| E: Byte Value                          |                                        |

This function sets the Byte Value (E) in the specified Bank ID (D) and 
Memory Address (HL).  The bank specified is not range checked.  The 
Status (A) is a standard HBIOS result code.

### Function 0xFC -- System Interrupt Management (SYSINT)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xFC                                | A: Status                              |
| C: Subfunction                         |                                        |

This function allows the caller to query information about the interrupt
 configuration of the running system and allows adding or hooking 
interrupt handlers dynamically. Register C is used to specify a 
subfunction. Additional input and output registers may be used as 
defined by the sub-function.  The Status (A) is a standard 
HBIOS result code.

Note that during interrupt processing, the lower 32K of CPU address 
space will contain the RomWBW HBIOS code bank, not the lower 32K of 
application TPA. As such, a dynamically installed interrupt handler does
not have access to the lower 32K of TPA and must be careful to avoid 
modifying the contents of the lower 32K of memory. Invoking RomWBW HBIOS
functions within an interrupt handler is not supported.

Interrupt handlers are different under IM1 and IM2.

Interrupt Mode 1:

: The new interrupt handler is responsible for chaining (JP) to the
previous vector if the interrupt is not handled. If the interrupt is
handled, the new handler may simply return (RET). When chaining to the
previous interrupt handler, ZF must be set if interrupt is handled and
ZF cleared if not handled. The interrupt management framework takes care
of saving and restoring AF, BC, DE, HL, and IY. Any other registers
modified must be saved and restored by the interrupt handler.

Interrupt Mode 2:

: The new interrupt handler may either replace or hook the previous
interrupt handler. To replace the previous interrupt handler, the new
handler just returns (RET) when done. To hook the previous handler, the
new handler can chain (JP) to the previous vector. Note that initially
all IM2 interrupt vectors are set to be handled as “BAD” meaning that the
interrupt is unexpected. In most cases, you do not want to chain to the
previous vector because it will cause the interrupt to display a "BAD
INT" system panic message.

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

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xFC                                | A: Status                              |
| C: 0x00                                | D: Interrupt Mode                      |
|                                        | E: IVT Size                            |

Return current Interrupt Mode (D) of the system.  Also return the
number of Interrupt Vector Table (IVT) entries in IVT Size (E).
interrupt mode in D and size of interrupt vector table in E. For
IM1, the size of the table is the number of vectors chained together.
For IM2, the size of the table is the number of slots in the vector
table.  The Status (A) is a standard 
HBIOS result code.

#### SYSINT Subfunction 0x10 -- Get Interrupt (INTGET)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xFC                                | A: Status                              |
| C: 0x10                                | HL: IVT Address                        |
| E: IVT Index                           |                                        |

This function will return the IVT Address (HL) of the current interrupt
vector for the specified IVT Index (C).  The Status (A) is a standard 
HBIOS result code.

#### SYSINT Subfunction 0x20 -- Set Interrupt (INTSET)

| **Entry Parameters**                   | **Returned Values**                    |
|----------------------------------------|----------------------------------------|
| B: 0xFC                                | A: Status                              |
| C: 0x20                                | HL: Previous Interrupt Address         |
| E: IVT Index                           |                                        |
| HL: Interrupt Address                  |                                        |

This function will set a new Interrupt Address (HL) at the IVT Index (E)
specified.  On return, the Previous Interrupt Address (HL) will be
provided.

`\clearpage`{=latex}


# Errors and diagnostics

ROMWBW tries to provide useful information when a run time or build time
error occurs. Many sections of the code also have code blocks that can be 
enable to aid in debugging and in some cases the level of reporting detail
can be customized.

## Run Time Errors

### PANIC

A panic error indicates a non-recoverable error. The processor status is displayed on the console
and interrupts are disabled and execution is halted. A cold boot or reset is required to restart.

Example error message: 

```
>>> PANIC: @06C4[DFA3:DFC3:0100:F103:04FC:0000:2B5E] 

*** System Halted ***
```

The format of the information provided is 

`@XXXX [-AF-:-BC-:-DE-:-HL-:-SP-:-IX-:-IY-]`

Where `@XXXX` is the address the panic was called from. The other information
is the CPU register contents.

Possible reasons a PANIC may occur are:

- RAM Bank range error when attempting a read or write to a RAM disk.
- Sector read function has not been setup but a read was attempted.
- An interrupt vector has not been set up when an interrupt was received.
- There was an attempt to add more devices than the device table had room for.
- An illegal SD card command was encountered.

The `@XXXX` memory address can be cross referenced with the build source code to identify
which section of the software or hardware caused the fault.

### SYSCHK 

A syschk error is identified when an internal error is detected. When this 
occurs an error code is returned to the calling program in the A register.
A non-zero result indicates an error.

Syschk errors may be reported to the console. Whether this occurs depends on 
the value of the diagnosis level equate DIAGLVL. By default syschk errors
are not reported to the console.

If the diagnosis level is set to display the diagnosis information, then
memory address, register dump and error code is displayed.
A key differance with the PANIC error is that execution may be continued. 

Example error message:

\>>> SYSCHK: @06C4[DFA3:DFC3:0100:F103:04FC:0000:2B5E] FD
Continue (Y/N)

The format of the information provided is similar the PANIC report.

@XXXX [-AF-:-BC-:-DE-:-HL-:-SP-:-IX-:-IY-] YY

The syschk error codes YY is returned in the A register.

| Error                               | Code YY  |
| ----------------------------------- | -------- |
| Success                             |   0x00   | 
| Undefined Error                     |   0xFF   | 
| Function Not Implemented            |   0xFE   | 
| Invalid Function                    |   0xFD   | 
| Invalid Unit Number                 |   0xFC   | 
| Out Of Memory                       |   0xFB   | 
| Parameter Out Of Range              |   0xFA   | 
| Media Not Present                   |   0xF9   | 
| Hardware Not Present                |   0xF8   | 
| I/O Error                           |   0xF7   | 
| Write Request To Read-Only Media    |   0xF6   | 
| Device Timeout                      |   0xF5   | 
| Invalid Configuration               |   0xF4   | 
| Internal Error                      |   0xF3   | 

### Error Level reporting

placeholder

## Build time errors

### Build chain tool errors

place holder

### Assembly time check errors

placeholder

## Diagnostics

### Diagnostic LEDs

Progress through the boot and initialization process can be difficult to monitor 
due to the lack of console or video output. Access to these output devices does
not become available until late the in the boot process. If these output devices 
are also involved with the issue trying to be resolved then trouble shooting is 
even more difficult.

ROMWBW can be configured to display boot progress with the assistance of additional 
hardware. This take the form of an LED breakout debugging board connected to an
8-bit output port. As the boot code executes, the LED output display is updated.

To use a LED breakout board, it must be connected the computers data, reset and port
select lines.

To enable the DIAG option the following settings must be made in the systems .ini
configuration file, where 0xnn is the port address.

DIAGENABLE .SET TRUE
DIAGPORT   .SET 0xnn

The following table shows the ROMWBW process steps in relation to the LED display.

| **LED**    | **RomWBW Processes**                           |
|------------|------------------------------------------------|
| `........` | Initial boot                                   |
|            | Jump to start address                          |
|            | Disable interrupts                             |
|            | Set interrupt mode                             |
|            | Initialize critical ports and baud rate        |
| `.......O` | Setup initial stack                            |
|            | Memory manager and CPU configuration           |
|            | Set top bank to be RAM                         |
| `......OO` | Get and save battery condition                 |
|            | Install HBIOS proxy in upper memory            |
|            | If platform is MBC reconfigure memory manager  |
|            | Setup "ROMLESS" HBIOS image or ...             |
|            | Copy HBIOS from ROM to RAM if RAM flag not set |
|            | Jump to HBIOS in RAM                           |
|            | Set running in RAM flag                        |
| `.....OOO` | Finalize configuration for running in RAM      |
|            | Check battery condition                        |
|            | Check for recovery mode boot                   |
| `....OOOO` | Identify CPU type                              |
| `...OOOOO` | Set cpu oscillator speed                       |
|            | Setup counter-timers                           |
|            | Setup heap                                     |
| `..OOOOOO` | Preconsole initialization                      |
| `.OOOOOOO` | Boot delay                                     |
|            | Set boot console device                        |
|            | Bios announcement                              |
| `OOOOOOOO` | Display platform information                   |
|            | Display memory configuration                   |
|            | Display CPU family                             |
|            | Verify ROM checksum                            |
|            | Report battery condition                       |
|            | Perform device driver initialization           |
|            | Report watchdog status                         |
|            | Mark HBIOS heap so it is preserved             |
|            | Switch from boot console to CRT if active      |
|            | Display device summary                         |
|            | Execute boot loader                            |

`\clearpage`{=latex}

### Appendix A Driver Instance Data fields

**This section is a work in progress...**

The following section outlines the read only data referenced by the
`SYSGET`, subfunctions `xxxFN` for specific drivers.


#### TMS9918 Driver:

| **Name**  | **Offset** | **Bytes** | **Description** |
|--------|----|----|-----------------------|
| PPIA	 | 0  | 1  | PPI PORT A  |
| PPIB	 | 1  | 1  | PPI PORT B  |
| PPIC	 | 2  | 1  | PPI PORT C  |
| PPIX	 | 3  | 1  | PPI CONTROL PORT |
| DATREG | 4  | 1  | IO PORT ADDRESS FOR MODE 0 |
| CMDREG | 5  | 1  | IO PORT ADDRESS FOR MODE 1 |
|        |    |    | _Below are the register mirror values_ |
|        |    |    | _that HBIOS used for initialisation_ |
| REG. 0 | 6  | 1  | $00 - NO EXTERNAL VID
| REG. 1 | 7  | 1  | $50 or $70 - SET MODE 1 and interrupt if enabled |
| REG. 2 | 8  | 1  | $00 - PATTERN NAME TABLE := 0 |
| REG. 3 | 9  | 1  | $00 - NO COLOR TABLE |
| REG. 4 | 10 | 1  | $01 - SET PATTERN GENERATOR TABLE TO $800 |
| REG. 5 | 11 | 1  | $00 - SPRITE ATTRIBUTE IRRELEVANT |
| REG. 6 | 12 | 1  | $00 - NO SPRITE GENERATOR TABLE |
| REG. 7 | 13 | 1  | $F0 - WHITE ON BLACK |
| DCNTL* | 14 | 1  | Z180 DMA/WAIT CONTROL |

* ONLY PRESENT FOR Z180 BUILDS


