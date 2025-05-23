$define{doc_title}{Hardware}$
$include{"Book.h"}$
$define{doc_author}{Mark Pruden \& Wayne Warthen}$
$define{doc_authmail}{}$

# Overview

## Supported Platforms

This section contains a summary of the system configuration target
for each of the pre-built ROM images included in the RomWBW
distribution.  

It is intended to help you select the correct ROM
image and understand the basic hardware components supported.
Detailed hardware system configuration information should be obtained
from your system provider/designer.

The table below summarizes the hardware platforms currently supported
by RomWBW along with the standard pre-built ROM image(s).  

`\clearpage`{=latex}

#### RCBUS - General Configurations

RCBus refers to Spencer Owen's RC2014 bus specification and derivatives
including RC26, RC40, RC80, and BP80.

| **Description**                                             | **Bus** | **ROM Image File**           | **Baud Rate** |
|-------------------------------------------------------------|---------|------------------------------|--------------:|
| [RCBus Z80 CPU Module], 512K RAM/ROM                        | RCBus   | RCZ80_std.rom                | 115200        |
| [RCBus Z80 CPU Module (KIO)], 512K w/KIO                    | RCBus   | RCZ80_kio_std.rom            | 115200        |
| [RCBus Z180 CPU Module (External)]                          | RCBus   | RCZ180_ext_std.rom           | 115200        |
| [RCBus Z180 CPU Module (Native)]                            | RCBus   | RCZ180_nat_std.rom           | 115200        |
| [RCBus Z280 CPU Module (External)]                          | RCBus   | RCZ280_ext_std.rom           | 115200        |
| [RCBus Z280 CPU Module (Native)]                            | RCBus   | RCZ280_nat_std.rom           | 115200        |

KIO refers to a Zilog specific Serial/Parallel Counter/Timer (Z84C90).

The RCBus Z180 & Z280 require a separate RAM/ROM memory module. There are two types
of these modules, you must pick the correct ROM for your type of memory module:

* The first type of RAM/ROM module includes Z2 style memory bank
  switching on the memory module itself.  This is called "External" (ext)
  because the bank switching is external from the CPU itself.

* The second type of RAM/ROM module has no bank switching logic on the
  memory module.  Bank switching is implemented via the Z180 or Z280
  MMU – this is called “Native” (nat) because the CPU itself provides
  the bank switching logic.

Only Z180 and Z280 CPUs have the ability to do bank switching in the
CPU, so the ext/nat selection only applies to them.  Z80 CPUs have no
built-in bank switching logic, so they always require a RAM/ROM module
with Z2 style bank switching and the ROMs are always configured for
external bank switching.

`\clearpage`{=latex}

#### Custom / Specific Configurations

Andrew Lynch

| **Description**                                             | **Bus** | **ROM Image File**           | **Baud Rate** |
|-------------------------------------------------------------|---------|------------------------------|--------------:|
| [RetroBrew Z80 SBC V2]                                      | ECB     | SBC_std.rom                  | 38400         |
| [RetroBrew Z80 SimH]                                        | -       | SBC_simh.rom                 | 38400         |
| [Duodyne Z80 System]                                        | Duo     | DUO_std.rom                  | 38400         |
| [Nhyodyne Z80 MBC]                                          | MBC     | MBC_std.rom                  | 38400         |
| [Rhyophyre Z180 SBC]                                        | -       | RPH_std.rom                  | 38400         |
| [N8 Z180 SBC] (date >= 2312)                                | ECB     | N8_std.rom                   | 38400         |

Bill Shen

| **Description**                                             | **Bus** | **ROM Image File**           | **Baud Rate** |
|-------------------------------------------------------------|---------|------------------------------|--------------:|
| [EaZy80-512 Z80 CPU Module]                                 | RCBus   | RCZ80_ez512_std.rom          | 115200        |
| [K80W Z80 CPU Module]                                       | RCBus   | RCZ80_k80w_std.rom           | 115200        |
| [ZRC Z80 CPU Module]                                        | RCBus   | RCZ80_zrc_std.rom            | 115200        |
| [ZRC Z80 CPU Module (RAM)]                                  | RCBus   | RCZ80_zrc_ram_std.rom        | 115200        |
| [ZRC512 Z80 CPU Module]                                     | RCBus   | RCZ80_zrc512_std.rom         | 115200        |
| [Z1RCC Z180 CPU Module]                                     | RCBus   | RCZ180_z1rcc_std.rom         | 115200        |
| [ZZRCC Z280 CPU Module]                                     | RCBus   | RCZ280_zzrcc_std.rom         | 115200        |
| [ZZRCC Z280 CPU Module (RAM)]                               | RCBus   | RCZ280_zzrcc_ram_std.rom     | 115200        |
| [ZZ80MB Z280 SBC]                                           | RCBus   | RCZ280_zz80mb_std.rom        | 115200        |

Sergey Kiselev

| **Description**                                             | **Bus** | **ROM Image File**           | **Baud Rate** |
|-------------------------------------------------------------|---------|------------------------------|--------------:|
| [Easy Z80 SBC]                                              | RCBus   | EZZ80_easy_std.rom           | 115200        |
| [Tiny Z80 SBC]                                              | RCBus   | EZZ80_tiny_std.rom           | 115200        |
| [Z80-512K CPU/RAM/ROM Module]                               | RCBus   | RCZ80_skz_std.rom            | 115200        |
| [Zeta Z80 SBC]   , ParPortProp                              | -       | ZETA_std.rom                 | 38400         |
| [Zeta V2 Z80 SBC]   , ParPortProp                           | -       | ZETA2_std.rom                | 38400         |

`\clearpage`{=latex}

Stephen Cousins

| **Description**                                             | **Bus** | **ROM Image File**           | **Baud Rate** |
|-------------------------------------------------------------|---------|------------------------------|--------------:|
| [SC126 Z180 SBC]                                            | BP80    | SCZ180_sc126_std.rom         | 115200        |
| [SC130 Z180 SBC]                                            | RCBus   | SCZ180_sc130_std.rom         | 115200        |
| [SC131 Z180 Pocket Comp]                                    | -       | SCZ180_sc131_std.rom         | 115200        |
| [SC140 Z180 CPU Module]                                     | Z50     | SCZ180_sc140_std.rom         | 115200        |
| [SC503 Z180 CPU Module]                                     | Z50     | SCZ180_sc503_std.rom         | 115200        |
| [SC700 Z180 CPU Module]                                     | RCBus   | SCZ180_sc700_std.rom         | 115200        |

Others

| **Description**                                             | **Bus**  | **ROM Image File**          | **Baud Rate** |
|-------------------------------------------------------------|----------|-----------------------------|--------------:|
| [Dyno Z180 SBC]^6^                                          | Dyno     | DYNO_std.rom                |         38400 |
| [EP Mini-ITX Z180]^11^                                      | UEXT     | EPITX_std.rom               |        115200 |
| [eZ80 for RCBus Module]^13^, 512K RAM/ROM                   | RCBus    | RCEZ80_std.rom              |        115200 |
| [Genesis Z180 System]^12^                                   | STD      | GMZ180_std.rom              |        115200 |
| [Heath H8 Z80 System]^10^                                   | H8       | HEATH_std.rom               |        115200 |
| [NABU w/ RomWBW Option Board]^10^                           | NABU     | NABU_std.rom                |        115200 |
| [S100 Computers Z180 SBC]^9^                                | S100     | S100_std.rom                |         57600 |
| [S100 Computers FPGA Z80 SBC]^9^                            | S100     | FZ80_std.rom                |          9600 |
| [UNA Hardware BIOS]^3^                                      | -        | UNA_std.rom                 |             - |
| [Z80-Retro SBC]^8^                                          | -        | Z80RETRO_std.rom            |         38400 |
| [Z180 Mark IV SBC]^3^                                       | ECB      | MK4_std.rom                 |         38400 |

| ^3^Designed by John Coffman
| ^6^Designed by Steve Garcia
| ^8^Designed by Peter Wilson
| ^9^Designed by John Monahan
| ^10^Designed by Les Bird
| ^11^Designed by Alan Cox
| ^12^Designed by Doug Jackson
| ^13^Designed by Dean Netherton

`\clearpage`{=latex}

## General Guidance

The standard ROM images will detect and install support for certain
devices and peripherals that are on-board or frequently used with
each platform.  If the device or peripheral is not detected at boot, 
the ROM will simply bypass support appropriately.

In some cases, support for multiple hardware components with potentially
conflicting resource usage are handled by a single ROM image.  It is up
to the user to ensure that no conflicting hardware is in use.

CPU speed will be dynamically measured at startup if DSRTC is present

All pre-built ROM images are pure binary files (they are not "hex"
files).  They are intended to be programmed starting at the very start
of the ROM chip (address 0).  Most of the pre-built images are
512KB in size.  If your system utilizes a larger ROM, you can just
program the image into the first 512KB of the ROM for now.

For this document port addresses `IO=xxx` are represented in decimal.

The PropIO support is based on RomWBW specific firmware. Be sure to
program/update your PropIO firmware with the corresponding firmware
image provided in the Binary directory of the RomWBW distribution.

The use of high density floppy disks requires a CPU speed of 8 MHz or
greater.

`\clearpage`{=latex}

# Platform Configurations

## Duodyne Z80 System

Duodyne is a third generation ROMWBW focused retrocomputer incorporating lessons 
learned and improvements from my original ECB Z80 SBC (aka N8VEM) and the nhyodyne 
modular computer. It is literally designed around ROMWBW from the start for a 
robust OS and software environment.

Duodyne is a new design which integrates many functions into larger, modular 
boards on a backplane. The intent is to create a powerful and capable system 
like an SBC, but with modularity and an expandable backplane.

* Creator: Andrew Lynch
* Retrobrew Forums: [Introducing duodyne retrocomputer](https://www.retrobrewcomputers.org/forum/index.php?t=msg&th=765)
* Github: [DuoDyne](https://github.com/lynchaj/duodyne) 

#### ROM Image File:  DUO_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | Duo           |
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 38400 Baud    |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=66, SWIO=66
- DSRTC: MODE=STD, IO=148
- PCF: IO=86
- UART: IO=88
- UART: IO=168
- UART: IO=112
- UART: IO=120
- SIO MODE=ZP, IO=96, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=ZP, IO=96, CHANNEL B, INTERRUPTS ENABLED
- LPT: MODE=SPP, IO=72
- DMA: MODE=DUO, IO=64
- CH: IO=78
- CHUSB: IO=78
- CHSD: IO=78
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=DUO, IO=128, DRIVE 0, TYPE=3.5" HD
- FD: MODE=DUO, IO=128, DRIVE 1, TYPE=3.5" HD
- PPIDE: IO=136, MASTER
- PPIDE: IO=136, SLAVE
- SD: MODE=MT, IO=140, UNITS=1
- SPK: IO=148
- CTC: IO=96, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED

`\clearpage`{=latex}

## Dyno Z180 SBC

The Dyno Computer is a Zilog Z180-based computer initially designed to run Wayne Warthen’s ROMWBW

* Creator: Steve García
* Google Groups: [An Introduction](https://groups.google.com/g/retro-comp/c/niwPLsuc8R0)
* Website: [Dyno Computer](http://dynocomputer.fun/)

#### ROM Image File:  DYNO_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | Dyno•Bus      |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- BQRTC: IO=80
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=DYNO, IO=132, DRIVE 0, TYPE=3.5" HD
- FD: MODE=DYNO, IO=132, DRIVE 1, TYPE=3.5" HD
- PPIDE: IO=76, MASTER
- PPIDE: IO=76, SLAVE

`\clearpage`{=latex}

## EP Mini-ITX Z180

EtchedPixels Z180 Mini-ITX. The SC126 was almost my ideal retrobrew Z80/Z180 system but 
with a couple of niggles and lack of a convenient case option. 
This is the same core Z180 CPU/RAM/ROM design taken the other direction, of expandability.

* Creator: Alan Cox
* Google Groups: [Another new board](https://groups.google.com/g/rc2014-z80/c/rhXBX9ff184)
* Github: [Z180MiniITX](https://github.com/EtchedPixels/Z180MiniITX)

#### ROM Image File:  EPITX_std.rom

|                   |              |
|-------------------|--------------|
| Bus               | RCBus + UEXT |
| Default CPU Speed | 18.432 MHz   |
| Interrupts        | Mode 2       |
| System Timer      | Z180         |
| Serial Default    | 115200 Baud  |
| Memory Manager    | Z180         |
| ROM Size          | 512 KB       |
| RAM Size          | 512 KB       |

#### Supported Hardware

- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=160
- UART: IO=168
- TMS: MODE=MSX, IO=152, SCREEN=40X24, KEYBOARD=NONE
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=EPFDC, IO=72, DRIVE 0, TYPE=3.5" HD
- FD: MODE=EPFDC, IO=72, DRIVE 1, TYPE=3.5" HD
- SD: MODE=EPITX, IO=66, UNITS=1

`\clearpage`{=latex}

## Easy/Tiny Z80

### Easy Z80 SBC

This project is a simple, easy to understand, yet capable single board computer. 
It reuses the same memory paging mechanism I've implemented in Zeta SBC V2. 
It uses Zilog Z80 SIO/O and Z80 CTC peripheral ICs and implements daisy chain 
mode 2 interrupt configuration

(Not to be confused with EaZy80)

* Creator: Sergey Kiselev
* Google Groups: [Easy Z80 - Single Board Computer](https://groups.google.com/g/rc2014-z80/c/UfWIoJgm9Gs)
* Github: [Easy_Z80](https://github.com/skiselev/easy_z80)

#### ROM Image File:  EZZ80_easy_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 10.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=STD, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=STD, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1
- CTC: IO=136, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED

`\clearpage`{=latex}

### Tiny Z80 SBC

Tiny Z80 is a business card sized (size?!) single board computer (SBC). 
It is mostly compatible with Easy Z80, and offers similar capabilities
Tiny Z80 includes a USB to Serial converter IC on board connected to one 
of the SIO ports, for ease of use with modern computers.

* Creator: Sergey Kiselev
* Github: [Tiny_Z80](https://github.com/skiselev/tiny_z80)

#### ROM Image File:  EZZ80_tiny_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 16.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=STD, IO=24, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=STD, IO=24, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=144, MASTER
- IDE: MODE=RC, IO=144, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1
- CTC: IO=16, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED

`\clearpage`{=latex}

## S100 Computers FPGA Z80 SBC

An FPGA Z80 based S100 SBC

* Creator: John Monahan                                                                           |
* Website: [S100 Computers FPGA Z80 SBC](http://www.s100computers.com/My%20System%20Pages/FPGA%20Z80%20SBC/FPGA%20Z80%20SBC.htm)

#### ROM Image File:  FZ80_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | S100          |
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | None          |
| System Timer      | None          |
| Serial Default    | 9600 Baud     |
| Memory Manager    | Z2            |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=255
- DS5RTC: RTCIO=104, IO=104
- SSER: IO=52
- LPT: MODE=S100, IO=199
- FV: IO=192, KBD MODE=FV, KBD IO=3
- KBD: ENABLED
- SCON: IO=0
- MD: TYPE=RAM
- PPIDE: IO=48, MASTER
- PPIDE: IO=48, SLAVE
- SD: MODE=FZ80, IO=108, UNITS=2

#### Notes:

- Requires matching FPGA code

`\clearpage`{=latex}

## Genesis Z180 System

A Z180 based board with 512k ram, 512k rom, dual serial / parallel, RTC and SD Card, based on the STD bus.
This was inspired on Pulsar Little Big board and some designs of Stephen Cousins

* Creator: [Doug Jackson](https://www.vk1zdj.net/)
* Specific Links not Available

#### ROM Image File:  GMZ180_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | STD           |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- GM7303: IO=48
- DSRTC: MODE=STD, IO=132
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- IDE: MODE=GIDE, IO=32, MASTER
- IDE: MODE=GIDE, IO=32, SLAVE
- SD: MODE=GM, IO=132, UNITS=1

`\clearpage`{=latex}

## Heath H8 Z80 System

Turn your H8 into a RomWBW CP/M computer

* Creator: Les Bird
* Github Wiki: [H8-Z80-ROMWBW-V1.0](https://github.com/sebhc/sebhc/wiki/H8-Z80-ROMWBW-V1.0)

#### ROM Image File:  HEATH_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | H8            |
| Default CPU Speed | 16.384 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- H8P: IO=240
- INTRTC: ENABLED
- UART: IO=232
- UART: IO=224
- UART: IO=216
- UART: IO=208
- TMS: MODE=MSX, IO=152, SCREEN=80X24, KEYBOARD=NONE
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- AY38910: MODE=MSX, IO=160, CLOCK=1789772 HZ

`\clearpage`{=latex}

## Z180 Mark IV SBC

The Z180 Mark IV is a single board computer, meaning it may run stand-alone. 
It also has an interface to the RetroBrew bus (ECB) for access to additional peripheral boards.

* Creator: John Coffman
* Retrobrew Wiki: [Z180 Mark IV](https://www.retrobrewcomputers.org/doku.php?id=boards:sbc:z180_mark_iv:z180_mark_iv)

#### ROM Image File:  MK4_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | ECB           |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=138
- ASCI: IO=64, INTERRUPTS ENABLED
- ASCI: IO=65, INTERRUPTS ENABLED
- UART: IO=24
- UART: IO=128
- UART: IO=192
- UART: IO=200
- UART: IO=208
- UART: IO=216
- VGA: IO=224, KBD MODE=PS/2, KBD IO=224
- CVDU: MODE=ECB, IO=224, KBD MODE=PS/2, KBD IO=226
- KBD: ENABLED
- PRP: IO=168
- PRPCON: ENABLED
- PRPSD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=DIDE, IO=42, DRIVE 0, TYPE=3.5" HD
- FD: MODE=DIDE, IO=42, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=MK4, IO=128, MASTER
- IDE: MODE=MK4, IO=128, SLAVE
- SD: MODE=MK4, IO=137, UNITS=1

`\clearpage`{=latex}

## NABU w/ RomWBW Option Board

No modifications to the NABU motherboard needed. Leave the standard NABU ROM in its socket 
on the motherboard, no need to remove it. You can switch back to standard NABU mode 
by changing one jumper on the Option Card

* Creator: Les Bird
* Github Wiki: [NABU RomWBW Option Card](https://github.com/sebhc/sebhc/wiki/NABU#nabu-romwbw-option-card)

#### ROM Image File:  NABU_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | NABU          |
| Default CPU Speed | 3.580 MHz     |
| Interrupts        | Mode 2        |
| System Timer      | TMS           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- NABU: IO=64
- INTRTC: ENABLED
- UART: IO=72
- TMS: MODE=NABU, IO=160, SCREEN=80X24, KEYBOARD=NABU, INTERRUPTS ENABLED
- NABUKB: IO=144
- MD: TYPE=RAM
- MD: TYPE=ROM
- PPIDE: IO=96, MASTER
- PPIDE: IO=96, SLAVE
- AY38910: MODE=NABU, IO=65, CLOCK=1789772 HZ

#### Notes:

- TMS video assumes F18A replacement for TMS9918

`\clearpage`{=latex}

## Nhyodyne Z80 MBC

Nhyodyne: A Modular Backplane Computer (MBC). 

The purpose of this project is to revisit the design concepts behind my original 
Z80 SBC (aka test prototype) which has evolved into the SBC V2-005 over several 
years. Attempt to introduce some new concepts to make the design more modular, 
flexible, and less expensive.

The MBC consists of four core boards: Z80 backplane, Z80 processor, Z80 clock, 
and Z80 ROM. These are sufficient to build a working system of minimum capability.

* Creator: Andrew Lynch
* Retrobrew Forums: [Z80 Multi Board Computer](https://www.retrobrewcomputers.org/forum/index.php?t=msg&th=568)
* Github: [NhyoDyne](https://github.com/lynchaj/nhyodyne)
* Retrobrew Wiki: [Z80 Modular Backplane Computer](https://www.retrobrewcomputers.org/doku.php?id=builderpages:lynchaj:start)

#### ROM Image File:  MBC_std.rom

|                   |            |
|-------------------|------------|
| Bus               | MBC        |
| Default CPU Speed | 8.000 MHz  |
| Interrupts        | None       |
| System Timer      | None       |
| Serial Default    | 38400 Baud |
| Memory Manager    | MBC        |
| ROM Size          | 512 KB     |
| RAM Size          | 512 KB     |

#### Supported Hardware

- PKD: IO=96, SIZE=8X1
- DSRTC: MODE=STD, IO=112
- UART: IO=104
- UART: IO=128
- UART: IO=136
- SIO MODE=ZP, IO=176, CHANNEL A
- SIO MODE=ZP, IO=176, CHANNEL B
- PIO: IO=184, CHANNEL A
- PIO: IO=184, CHANNEL B
- PIO: IO=188, CHANNEL A
- PIO: IO=188, CHANNEL B
- LPT: MODE=SPP, IO=232
- CVDU: MODE=MBC, IO=224, KBD MODE=PS/2, KBD IO=226
- TMS: MODE=MBC, IO=152, SCREEN=80X24, KEYBOARD=KBD
- KBD: ENABLED
- ESP: IO=156
- ESPCON: ENABLED
- ESPSER: DEVICE=0
- ESPSER: DEVICE=1
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=MBC, IO=48, DRIVE 0, TYPE=3.5" HD
- FD: MODE=MBC, IO=48, DRIVE 1, TYPE=3.5" HD
- PPIDE: IO=96, MASTER
- PPIDE: IO=96, SLAVE
- SPK: IO=112

`\clearpage`{=latex}

## RetroBrew Z80

### RetroBrew Z80 SBC V2

The SBC V2 is a Zilog Z80 processor board. It's a 100x160mm board that is capable of 
functioning both as a standalone SBC or as attached to the ECB bus.

Previously known as the N8VEM SBC, after Andrews Ham radio call sign, development 
began in 2006 wth V1 and is currently still in development, it launched a tsunami 
of developments based on the Euro Card Bus (ECB) standard.

* Creator: Andrew Lynch
* Github: [SBC-V2-005](https://github.com/b1ackmai1er/SBC-V2-005) (May not be official)
* Github: [SBC-V2-004](https://github.com/b1ackmai1er/SBC-V2-004)
* Retrobrew Wiki: [SBC V2](https://www.retrobrewcomputers.org/doku.php?id=boards:sbc:sbc_v2:start)
* Blog: [Building the SBCV2 Z80](https://simmohacks.com/wordpress/2018/11/17/building-the-retrobrew-computers-ecb-sbcv2-z80-computer)

#### ROM Image File:  SBC_std.rom

|                   |            |
|-------------------|------------|
| Bus               | ECB        |
| Default CPU Speed | 8.000 MHz  |
| Interrupts        | None       |
| System Timer      | None       |
| Serial Default    | 38400 Baud |
| Memory Manager    | SBC        |
| ROM Size          | 512 KB     |
| RAM Size          | 512 KB     |

#### Supported Hardware

- DSRTC: MODE=STD, IO=112
- UART: MODE=SBC, IO=104
- UART: MODE=CAS, IO=128
- UART: MODE=MFP, IO=104
- UART: MODE=4UART, IO=192
- UART: MODE=4UART, IO=200
- UART: MODE=4UART, IO=208
- UART: MODE=4UART, IO=216
- VGA: IO=224, KBD MODE=PS/2, KBD IO=224
- CVDU: MODE=ECB, IO=224, KBD MODE=PS/2, KBD IO=226
- CVDU occupies 905 bytes.
- KBD: ENABLED
- PRP: IO=168
- PRPCON: ENABLED
- PRPSD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=DIO, IO=54, DRIVE 0, TYPE=3.5" HD
- FD: MODE=DIO, IO=54, DRIVE 1, TYPE=3.5" HD
- PPIDE: IO=96, MASTER
- PPIDE: IO=96, SLAVE

`\clearpage`{=latex}

### RetroBrew Z80 SimH

Image for Altair Z80 SimH emulator

#### ROM Image File:  SBC_simh.rom

|                   |               |
|-------------------|---------------|
| Bus               | -             |
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | SimH          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | SBC           |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- SIMRTC: IO=254
- SSER: IO=109
- MD: TYPE=RAM
- MD: TYPE=ROM
- HDSK: IO=253, DEVICE COUNT=2

#### Notes:

- CPU speed and Serial configuration not relevant in emulator

`\clearpage`{=latex}

## N8 Z180 SBC

The N8 is intended to be a “home brew” style computer in the style of early 1980's 
all-in-one home computers with a usable set of features such as color graphics, 
audio, an assortment of mass storage options, a variety of ports, etc. Although 
a bus expansion is supported no additional boards are required.

This configuration is for the N8-2312 and latter (4314) revisions

* Creator: Andrew Lynch
* Retrobrew Wiki: [The N8](https://www.retrobrewcomputers.org/doku.php?id=boards:sbc:n8:n8)
* Blog: [A Z180 based SBC](https://www.vk1zdj.net/?p=525)

#### ROM Image File:  N8_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | ECB           |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | N8            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=136
- ASCI: IO=64, INTERRUPTS ENABLED
- ASCI: IO=65, INTERRUPTS ENABLED
- TMS: MODE=N8, IO=152, SCREEN=40X24, KEYBOARD=PPK
- PPK: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=N8, IO=140, DRIVE 0, TYPE=3.5" HD
- FD: MODE=N8, IO=140, DRIVE 1, TYPE=3.5" HD
- SD: MODE=CSIO, IO=136, UNITS=1
- AY38910: MODE=N8, IO=156, CLOCK=1789772 HZ

#### Notes:

- SD Card interface is configured for CSIO (N8 date code >= 2312)

`\clearpage`{=latex}

## RCBus Z80

### RCBus Z80 CPU Module

Generic Rom Image.

#### ROM Image File:  RCZ80_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 7.372 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### RCBus Z80 CPU Module (KIO)

Generic Rom Image. SIO Serial baud rate managed by CTC

#### ROM Image File:  RCZ80_kio_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 7.372 MHz     |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=STD, IO=136, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=STD, IO=136, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1
- KIO: IO=128
- CTC: IO=132, TIMER MODE=TIMER/16, DIVISOR=9216, HI=256, LO=36, INTERRUPTS ENABLED

`\clearpage`{=latex}

### Z80-512K CPU/RAM/ROM Module

Z80-512K is an RCBus and RC2014* compatible module, designed to run RomWBW firmware 
including CP/M, ZSDOS, and various applications under these OSes. Z80-512K combines
functionality of CPU, RAM, and ROM on a single module, thus saving space on the backplane.

* Creator: Sergey Kiselev
* Google Groups: [Z80-512K](https://groups.google.com/g/rc2014-z80/c/SkOqm_LX910)
* Github: [Z80-512K](https://github.com/skiselev/Z80-512K)

#### ROM Image File:  RCZ80_skz_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 7.372 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### ZRC Z80 CPU Module

ZRC is derived from the ZoRC experiment. The basic notion is that large RAM and fast 
serial upload enable a diskless CP/M SBC. However, just in case that idea didn't work 
out, ZRC has an optional compact flash interface. The targeted software for ZRC is ROMWBW.
ZRC physically contains no ROM and 2MB of RAM.  

In the STD configuration the first 512KB of RAM is loaded with a ROM image from disk 
storage and then handled like ROM. Essentially, an area of the RAM is reserved to act as ROM.

* Creator: Bill Shen
* Retrobrew Wiki: [ZRC, Z80 RAM CPLD for ROMWBW](https://www.retrobrewcomputers.org/doku.php?id=builderpages:plasmo:zrc)
* Google Groups: [ZRC, Z80/RAM/CPLD, minimal CP/M-ready, Z80 SBC](https://groups.google.com/g/retro-comp/c/L3W7TaDnX5A/m/ZxOgl8EIAQAJ)

#### ROM Image File:  RCZ80_zrc_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | ZRC           |
| ROM Size          | 512 KB        |
| RAM Size          | 1536 KB       |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128, INTERRUPTS ENABLED
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### ZRC Z80 CPU Module (RAM)

This profile differs (from STD) only in how the system boots, and how RAM is configured.
Boot occurs directly to RAM, loading HBIOS directly from disk storage rather than via
a pseudo ROM image copied into RAM.

A RAM disk is configured preloaded with files that would normally be on the ROM disk.
There is no ROM disk in this configuration.

The RAM config is the newer approach and provides a more efficient bank layout. 
The intent to replace the STD config with the RAM config.

* Creator: Bill Shen

#### ROM Image File:  RCZ80_zrc_ram_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | ZRC           |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128, INTERRUPTS ENABLED
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### ZRC512 Z80 CPU Module

ZRC512 is a faster and hobbyist-friendly variant of ZRC. 
It is designed specifically for ROM-less RomWBW. HBIOS is loaded from disk at boot

* Creator: Bill Shen
* Google Groups: [Bill Shen's ZRC512 SBC / RC2014 board](https://groups.google.com/g/retro-comp/c/bILDMVI97vo)
* Retrobrew Wiki: [ZRC512, A Hobbyist-friendly Z80 SBC for ROM-less RomWBW](https://www.retrobrewcomputers.org/doku.php?id=builderpages:plasmo:zrc512:zrc512home)

#### ROM Image File:  RCZ80_zrc512_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 22.000 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | ZRC           |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128, INTERRUPTS ENABLED
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### EaZy80-512 Z80 CPU Module

Eazy80-512 is Eazy80 rev2 pc board configured with 512K RAM to run RomWBW. 
The design was derived from modifications to Eazy80 Rev1 that supported RomWBW.

HBIOS is loaded from disk at boot by ROM monitor

(Not to be confused with EasyZ80)

* Creator: Bill Shen
* VCF Forums: [Eazy80, a glue-less, CP/M capable Z80 SBC](https://forum.vcfed.org/index.php?threads/eazy80-a-glue-less-cp-m-capable-z80-sbc.1251160)
* Retrobrew Wiki: [Eazy80 Rev2, Glue-less Configuration](https://www.retrobrewcomputers.org/doku.php?id=builderpages:plasmo:eazy80:eazy80rev2:eazy80rev2home)
* Google Groups: [EaZy80, A Simple80 with KIO](https://groups.google.com/g/retro-comp/c/0cUDbZspHyQ)

#### ROM Image File:  RCZ80_ez512_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 22.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | EZ512         |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=192
- SIO MODE=STD, IO=8, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=STD, IO=8, CHANNEL B, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD occupies 409 bytes.
- SD: MODE=EZ512, IO=2, UNITS=1
- KIO: IO=0
- CTC: IO=4

`\clearpage`{=latex}

### K80W Z80 CPU Module

K80W is similar to K80. It is a 22MHz Z80 SBC with KIO (Z84C90) as the I/O device. 
It is designed to run RomWBW. The current version is rev 2.1 replacing the older K80W rev 1

* Creator: Bill Shen
* Retrobrew Wiki: [K80W Rev2.1, A RomWBW-capable Z80 SBC](https://www.retrobrewcomputers.org/doku.php?id=builderpages:plasmo:k80:k80w_r21)

#### ROM Image File:  RCZ80_k80w_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 22.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=K80W, IO=192
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=STD, IO=136, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=STD, IO=136, CHANNEL B, INTERRUPTS ENABLED
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=EZ512, IO=130, UNITS=1
- KIO: IO=128
- CTC: IO=132

`\clearpage`{=latex}

## RCBus Z180

### RCBus Z180 CPU Module (External)

Generic Rom Image. For use with Z2 bank switched memory board (Z2 external memory management)

#### ROM Image File:  RCZ180_ext_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### RCBus Z180 CPU Module (Native)

Generic Rom Image. For use with linear memory board (Z180 native memory management)

#### ROM Image File:  RCZ180_nat_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### Z1RCC Z180 CPU Module

Z1RCC is a 2“x4” RomWBW-capable Z180 SBC.

Z1RCC has no flash memory on board but has a small (64 bytes) bootstrap ROM in CPLD 
so that Z180 boots from this bootstrap ROM, copies a loader from CF disk to top 32K of RAM, 
runs the loader to bring in the 480K RomWBW image from CF disk, then start RomWBW from 0x0

* Creator: Bill Shen
* Google Groups: [RomWBW for Z80 with 512K RAM 0K ROM](https://groups.google.com/g/retro-comp/c/29DOV4eO6MU)
* Retrobrew Wiki: [Z1RCC, A RC2014-Compatible, RomWBW-Capable Z180 SBC](https://www.retrobrewcomputers.org/doku.php?id=builderpages:plasmo:z1rcc:rev0:home)

#### ROM Image File:  RCZ180_z1rcc_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

## RCBus Z280

### RCBus Z280 CPU Module (External)

Generic Rom Image. For use with Z2 bank switched memory board (Z2 external memory management)

#### ROM Image File:  RCZ280_ext_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 12.000 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- Z2U: IO=16
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### RCBus Z280 CPU Module (Native)

Generic Rom Image. For use with linear memory board (Z280 native memory management)

#### ROM Image File:  RCZ280_nat_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 12.000 MHz    |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=PIO, IO=105, UNITS=1

`\clearpage`{=latex}

### ZZRCC Z280 CPU Module

ZZRCC follows the basic concept of ZRCC that uses a small CPLD to bootstrap from CF disk. 
Because Z280 has a native serial-bootstrap capability, the CPLD is even simpler than that 
of ZRCC. ZZRCC is Z280 operating in Z80-compatible mode. It is designed for RC2014 bus
ZZRCC actually contains no ROM and 512KB of RAM.  

In the STD configuration the first 256KB of RAM is loaded with a ROM image from disk 
storage and then handled like ROM. Essentially, an area of the RAM is reserved to act as ROM.

* Creator: Bill Shen
* Retrobrew Wiki: [ZZRCC, a SBC for RC2014 based on Z280](https://www.retrobrewcomputers.org/doku.php?id=builderpages:plasmo:zzrcc)
* Google Groups: [ZZRCC, Z280 SBC replacing ZZ80RC and ZZ80CF](https://groups.google.com/g/retro-comp/c/lt1t3JEoiCM/m/NYeZdrFuAAAJ)
* Google Groups: [Help porting ROMWBW to ZZRCC](https://groups.google.com/g/retro-comp/c/mBIWW18WXTE/m/E_sehx5fAwAJ)

#### ROM Image File:  RCZ280_zzrcc_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 256 KB        |
| RAM Size          | 256 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE

`\clearpage`{=latex}

### ZZRCC Z280 CPU Module (RAM)

This profile differs (from STD) only in how the system boots, and how RAM is configured.
Boot occurs directly to RAM, loading HBIOS directly from disk storage rather than via
a pseudo ROM image copied into RAM.

A RAM disk is configured preloaded with files that would normally be on the ROM disk.
There is no ROM disk in this configuration.

The RAM config is the newer approach and provides a more efficient bank layout.
The intent to replace the STD config with the RAM config.

* Creator: Bill Shen

#### ROM Image File:  RCZ280_zzrcc_ram_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE

`\clearpage`{=latex}

### ZZ80MB Z280 SBC

ZZ80MB is a Z280-based motherboard with RC2014 expansion slots. It is based on the ZZ80RC-CF design, 
but with two additional expansion slots added. ZZ80MB is designed with an EPROM programmer function 
such that it can boot from serial port, load EPROM programming image through the serial port 
and program an EPROM. This feature can be used to program EPROM for other computers

* Creator: Bill Shen
* Retrobrew Wiki: [ZZ80MB, A Z280-based SBC with RC2014 Expansion](https://www.retrobrewcomputers.org/doku.php?id=builderpages:plasmo:zz80mb:zz80mbr3)

#### ROM Image File:  RCZ280_zz80mb_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 12.000 MHz    |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE

`\clearpage`{=latex}

## eZ80 for RCBus Module

The eZ80 for RCBus/RC2014 is a module designed for the RCBus and RC2014 backplanes.

Its designed as a 'compatible upgrade' to the stock Z80 CPU. The eZ80 is a CPU that was 
first released by Zilog about 20 years ago, and still available from the manufacturer today

* Creator: Dean Netherton
* Github: [eZ80 for the RCBus/RC2014](https://github.com/dinoboards/ez80-for-rc)
* Hackaday: [eZ80 CPU for RC2014 and other backplanes](https://hackaday.io/project/196330-ez80-cpu-for-rc2014-and-other-backplanes)

#### ROM Image File:  RCEZ80_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 20.000 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | EZ80          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- EZ80: CPU DRIVER
- EZ80: SYS TIMER DRIVER
- EZ80: RTC DRIVER
- EZ80: UART DRIVER

`\clearpage`{=latex}

## Rhyophyre Z180 SBC

Single Board Computer featuring Zilog Z180 processor and NEC µPD7220 
Graphics Display Controller

* Creator: Andrew Lynch
* Retrobrew Forums: [Z180 upd7220 GDC SBC](https://www.retrobrewcomputers.org/forum/index.php?t=msg&th=699)
* Github: [rhyophyre](https://github.com/lynchaj/rhyophyre)

#### ROM Image File:  RPH_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | -             |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | None          |
| System Timer      | None          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | RPH           |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=132
- ASCI: IO=64
- ASCI: IO=65
- GDC: MODE=RPH, DISPLAY=EGA, IO=144
- KBD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- PPIDE: IO=136, MASTER
- PPIDE: IO=136, SLAVE

`\clearpage`{=latex}

## S100 Computers Z180 SBC

A Z180 board which contains a flash RAM, a USB port interface and an SD Card that can immediately boot up CPM. 
While it is on an S100 Bus board, initially that board has only 8 significant chips and works as a self contained 
computer outside the bus with a simple 9V power supply.

Later on it can be built up further with more chips, placed in an S100 bus and one by one programed to interface 
with the 100's of S100 bus cards that are out there. It can in fact behave as a S100 bus master or slave 
as defined by the IEEE-696 specs.

* Creator: John Monahan                                                                           |
* Website: [S100 Computers Z180 SBC](http://www.s100computers.com/My%20System%20Pages/Z180%20SBC/Z180%20SBC.htm)

#### ROM Image File:  S100_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | S100          |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 57600 Baud    |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- SCON: IO=0
- MD: TYPE=RAM
- MD: TYPE=ROM
- SD: MODE=SC, IO=12, UNITS=1

#### Notes:

- Z180 SBC SW2 (IOBYTE) Dip Switches:

| Bit | Setting | Function                            |
|-----|---------|-------------------------------------|
| 0   | Off     | Use Z180 ASCI Channel A for console |
|     | On      | Use Propeller Console               |
|     |         |                                     |
| 1   | Off     | Boot to RomWBW Boot Loader          |
|     | On      | Boot to S100 Monitor                |

`\clearpage`{=latex}

## Small Computer Central Z180

Small Computer Central provides an extensive range hardware based around the 
Zilog ecosystem. This section lists configurations specifically for the Z180 processor

If you are using a Z80 processor you will probably be using the general `RCZ80_std`
configuration - [RCBus Z80 CPU Module]. However, please consult 
[Firmware, RomWBW, RCZ80_std](https://smallcomputercentral.com/firmware/firmware-romwbw-rcz80_std/)
for further information and to ensure compatibility with your Z80 system. 

* Creator: Stephen Cousins
* Website: [Small Computer Central](https://smallcomputercentral.com)

### SC126 Z180 SBC

SC126 is a Z180 Motherboard.

* Website: [SC126 – Z180 Motherboard](https://smallcomputercentral.com/rcbus/sc100-series/sc126-z180-motherboard-rc2014/)

#### ROM Image File:  SCZ180_sc126_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | BP80          |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=13, SWIO=0
- DSRTC: MODE=STD, IO=12
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=SC, IO=12, UNITS=1

#### Notes:

- When disabled, watchdog requires /IM to be pulsed.  If an RCBus module
  holds the CPU in WAIT for more than this, the watchdog will fire when
  disabled with random consequences.  The Pico SD does this at power-on.

`\clearpage`{=latex}

### SC130 Z180 SBC

SC130 is an entry-level Z180 Motherboard designed primarily to run RomWBW (and CP/M)

* Website: [SC130 – Z180 Motherboard](https://smallcomputercentral.com/rcbus/sc100-series/sc130-z180-motherboard)

#### ROM Image File:  SCZ180_sc130_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=SC, IO=12, UNITS=1

`\clearpage`{=latex}

### SC131 Z180 Pocket Comp

SC131 is a pocket-sized Z180 RomWBW CP/M computer.

* Website: [SC131 – Z180 Pocket Computer](https://smallcomputercentral.com/sc131-z180-pocket-computer/)

#### ROM Image File:  SCZ180_sc131_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | -             |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- SD: MODE=SC, IO=12, UNITS=1

`\clearpage`{=latex}

### SC140 Z180 CPU Module

SC140 is a Z180 SBC / Z50Bus Card card.

* Website: [SC140 – Z180 SBC / Z50Bus Card](https://smallcomputercentral.com/z50bus-4/sc140-z180-sbc-z50bus-card/)

#### ROM Image File:  SCZ180_sc140_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | Z50           |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=160, SWIO=160
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=144, MASTER
- IDE: MODE=RC, IO=144, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=SC, IO=12, UNITS=1

`\clearpage`{=latex}

### SC503 Z180 CPU Module

SC503 is a Z180 Processor card designed for Z50Bus.

* Website: [SC503 – Z180 Processor (Z50Bus)](https://smallcomputercentral.com/z50bus-4/sc503-z180-processor-z50bus/)

#### ROM Image File:  SCZ180_sc503_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | Z50           |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=160, SWIO=160
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=144, MASTER
- IDE: MODE=RC, IO=144, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=SC, IO=12, UNITS=1

`\clearpage`{=latex}

### SC700 Z180 CPU Module

This configuration is specifically for systems based on the 
Z180 CPU (eg. SC722) with 1MB linear memory (eg. SC721)

* Website: [SC700 Series](https://smallcomputercentral.com/rcbus/sc700-series/)
* Website: [SC721 – RCBus Memory Module](https://smallcomputercentral.com/rcbus/sc700-series/sc721-rcbus-memory-module/)
* Website: [SC722 – RCBus Z180 CPU Module](https://smallcomputercentral.com/rcbus/sc700-series/sc722-rcbus-z180-cpu-module/)

#### ROM Image File:  SCZ180_sc700_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | RCBus         |
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0
- LCD: IO=170, SIZE=20X4
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: IO=128
- UART: IO=136
- UART: IO=160
- UART: IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- SD: MODE=SC, IO=12, UNITS=1

\clearpage`{=latex}

## Z80-Retro SBC

The system comprises a Z80 retro computer board, and optonal VGA text video card, 
and PIO Keyboard and Sound Card. The system uses a custom 60 pin bus on a standard header.

(Not to be confused with a similar named project by 
John Winans presented by John's Basement on youTube)

* Creator: Peter Wilson
* Github: [Z80-Retro](https://github.com/peterw8102/Z80-Retro)
* Github Wiki: [Welcome to the Z80-Retro wiki!](https://github.com/peterw8102/Z80-Retro/wiki)
* OSHWLab: [Simple Z80 SBC](https://oshwlab.com/peterw8102/simple-z80)

#### ROM Image File:  Z80RETRO_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | 60 pin        |
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | None          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- SIO MODE=Z80R, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=Z80R, IO=128, CHANNEL B, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- SD: MODE=Z80R, IO=104, UNITS=1

`\clearpage`{=latex}

## Zeta Z80 SBC

Zeta SBC is an Zilog Z80 based single board computer. It is inspired by Ampro Little Board Z80
and N8VEM project. Zeta SBC is software compatible with N8VEM SBC and Disk I/O boards.

* Creator: Sergey Kiselev
* Retrobrew Wiki: [Zeta SBC](https://www.retrobrewcomputers.org/doku.php?id=boards:sbc:zeta:start)

#### ROM Image File:  ZETA_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | -             |
| Default CPU Speed | 8.000  MHz    |
| Interrupts        | None          |
| System Timer      | None          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | SBC           |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=112
- UART: IO=104
- PPP: IO=96
- PPPCON: ENABLED
- PPPSD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=DIO, IO=54, DRIVE 0, TYPE=3.5" HD

#### Notes:

- If ParPortProp is installed, initial console output is
  determined by JP1:
  - Shorted: console to on-board serial port
  - Open: console to ParPortProp video and keyboard

`\clearpage`{=latex}

## Zeta V2 Z80 SBC

Zeta SBC V2 is a redesigned version of Zeta SBC. 

Compared to the first version this version features updated MMU with four banks, each one of 
those banks can be mapped to any 16 KiB page in 1 MiB on-board memory. It adds Z80 CTC which 
is used for generating periodic interrupts and as a vectored interrupt controller for UART 
and PPI. The FDC is replaced with 37C65. Compared to FDC9266 used in Zeta SBC it integrates 
input/output buffers and floppy disk control latch. Additionally 37C65 FDC is easier to obtain 
than FDC9266. And lastly it is made using CMOS technology and more power efficient than FDC9266

* Creator: Sergey Kiselev
* Github: [Zeta SBC V2](https://github.com/skiselev/zeta_sbc)
* Retrobrew Wiki: [Zeta SBC V2](https://www.retrobrewcomputers.org/doku.php?id=boards:sbc:zetav2:start)

#### ROM Image File:  ZETA2_std.rom

|                   |               |
|-------------------|---------------|
| Bus               | -             |
| Default CPU Speed | 8.000  MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 38400 Baud    |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=112
- UART: IO=104
- PPP: IO=96
- PPPCON: ENABLED
- PPPSD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=ZETA2, IO=48, DRIVE 0, TYPE=3.5" HD
- CTC: IO=32, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED

#### Notes:

- If ParPortProp is installed, initial console output is
  determined by JP1:
  - Shorted: console to on-board serial port
  - Open: console to ParPortProp video and keyboard

# Device Drivers

This section briefly describes each of the possible devices that
may be discovered by RomWBW in your system.

## Character

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| ACIA      | MC68B50 Asynchronous Communications Interface Adapter  |
| ASCI      | Zilog Z180 CPU Built-in Serial Ports                   |
| DUART     | SCC2681 or compatible Dual UART                        |
| ESPCON    | ESP32 Firmware-based Video Console                     |
| ESPSER    | ESP32 Firmware-based Serial Interface                  |
| EZ80UART  | eZ80 Serial Interface                                  |
| LPT       | Parallel I/O Controller                                |
| PIO       | Zilog Parallel Interface Controller                    |
| PPPCON    | ParPortProp Serial Console Interface                   |
| PRPCON    | PropIO Serial Console Interface                        |
| SCON      | S100 Console                                           |
| SIO       | Zilog Serial Port Interface                            |
| SSER      | Simple Serial Interface                                |
| UART      | 16C550 Family Serial Interface                         |
| USB-FIFO  | FT232H-based ECB USB FIFO                              |
| Z2U       | Zilog Z280 CPU Built-in Serial Ports                   |

By default, RomWBW will use the first available character device it
discovers for the initial console.  The following character devices are
scanned in the order shown.  The available character devices depend on
the active platform and configuration.

#. SSER: Simple Serial Interface
#. ASCI: Zilog Z180 CPU Built-in Serial Ports
#. Z2U: Zilog Z280 CPU Built-in Serial Ports
#. UART: 16C550 Family Serial Interface
#. DUART: SCC2681 or compatible Dual UART
#. SIO: Zilog Serial Port Interface
#. EZ80UART: eZ80 Serial Port Interface
#. ACIA: MC68B50 Asynchronous Communications Interface Adapter
#. USB-FIFO: FT232H-based ECB USB FIFO

## Disk

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| CHSD      | CH37x SD Card Interface                                |
| CHUSB     | CH37x USB Drive Interface                              |
| FD        | Intel 8272 or compatible Floppy Disk Controller        |
| HDSK      | SIMH Simulator Hard Disk                               |
| IDE       | IDE/ATA/ATAPI Hard Disk Interface                      |
| IMM       | Zip Drive on PPI (IMM variant)                         |
| MD        | ROM/RAM Disk                                           |
| PPA       | Zip Drive on PPI (PPA variant)                         |
| PPIDE     | 8255 IDE/ATA/ATAPI Hard Disk Interface                 |
| PPPSD     | ParPortProp SD Card Interface                          |
| PRPSD     | PropIO SD Card Interface                               |
| RF        | RAM Floppy Disk Interface                              |
| SD        | SD Card Interface                                      |
| SYQ       | Iomega SparQ Drive on PPI                              |

## Video

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| CVDU      | MC8563-based Video Display Controller                  |
| EF        | EF9345 Video Display Controller                        |
| FV        | S100 FPGA Z80 Onboard VGA/Keyboard                     |
| GDC       | uPD7220 Video Display Controller                       |
| TMS       | TMS9918/38/58 Video Display Controller                 |
| VDU       | MC6845 Family Video Display Controller (*)             |
| VGA       | HD6445CP4-based Video Display Controller               |
| VRC       | VGARC Video Display Controller                         |

Note:

* Reading bytes from the video memory of the VDU board (not Color
  VDU) appears to be problematic. This is only an issue when the driver
  needs to scroll a portion of the screen which is done by applications
  such as WordStar or ZDE. You are likely to see screen corruption in
  this case.

## Keyboard

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| KBD       | 8242 PS/2 Keyboard Controller                          |
| MSXKYB    | MSX Compliant Matrix Keyboard                          |
| NABUKB    | NABU Keyboard                                          |
| PPK       | Matrix Keyboard                                        |

## Audio

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| AY        | AY-3-8910/YM2149 Programmable Sound Generator          |
| SN76489   | SN76489 Programmable Sound Generator                   |
| SPK       | Bit-bang Speaker                                       |
| YM        | YM2612 Programmable Sound Generator                    |

## RTC (RealTime Clock)

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| BQRTC     | BQ4845P Real Time Clock                                |
| DS5RTC    | Maxim DS1305 SPI Real-Time Clock w/ NVRAM              |
| DS7RTC    | Maxim DS1307 PCF I2C Real-Time Clock w/ NVRAM          |
| DS1501RTC | Maxim DS1501/DS1511 Watchdog Real-Time Clock           |
| DSRTC     | Maxim DS1302 Real-Time Clock w/ NVRAM                  |
| EZ80RTC   | eZ80 Real-Time Clock                                   |
| INTRTC    | Interrupt-based Real Time Clock                        |
| PCF       | PCF8584-based I2C Real-Time Clock                      |
| RP5C01    | Ricoh RPC01A Real-Time Clock w/ NVRAM                  |
| SIMRTC    | SIMH Simulator Real-Time Clock                         |

## DsKy (DiSplay KeYpad)

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| FP        | Simple LED & Switch Front Panel                        |
| GM7303    | Prolog 7303 derived Display/Keypad                     |
| H8P       | Heath H8 Display/Keypad                                |
| ICM       | ICM7218-based Display/Keypad on PPI                    |
| LCD       | Hitachi HD44780-based LCD Display                      |
| PKD       | P8279-based Display/Keypad on PPI                      |

## System

| **ID**    | **Description**                                        |
|-----------|--------------------------------------------------------|
| CH        | CH375/376 USB Interface Controller                     |
| CTC       | Zilog Clock/Timer                                      |
| DMA       | Zilog DMA Controller                                   |
| ESP       | ESP32 Firmware-based interface                         |
| EZ80TIMER | eZ80 System Timer                                      |
| KIO       | Zilog Serial/ Parallel Counter/Timer (Z84C90)          |
| PPP       | ParPortProp Host Interface Controller                  |
| PRP       | PropIO Host Interface Controller                       |

# UNA Hardware BIOS

John Coffman has produced a new generation of hardware BIOS called
UNA. The standard RomWBW distribution includes its own hardware
BIOS. However, RomWBW can alternatively be constructed with UNA as
the hardware BIOS portion of the ROM. If you wish to use the UNA
variant of RomWBW, then just program your ROM with the ROM image
called "UNA_std.rom" in the Binary directory. This one image is
suitable on **all** of the platforms and hardware UNA supports.

UNA is customized dynamically using a ROM based setup routine and the
setup is persisted in the system NVRAM of the RTC chip. This means
that the single UNA-based ROM image can be used on most of the
RetroBrew platforms and is easily customized. UNA also supports FAT
file system access that can be used for in-situ ROM programming and
loading system images.

While John is likely to enhance UNA over time, there are currently a
few things that UNA does not support:

* Floppy Drives
* Terminal Emulation
* Zeta 1, N8, RCBus, Easy Z80, and Dyno Systems
* Some older support boards

The UNA version embedded in RomWBW is the latest production release
of UNA. RomWBW will be updated with John's upcoming UNA release with
support for VGA3 as soon as it reaches production status.

Please refer to the
[UNA BIOS Firmware Page](https://www.retrobrewcomputers.org/doku.php?id=software:firmwareos:una:start)
for more information on UNA.

## UNA Usage Notes

- At startup, UNA will display a prompt similar to this:

  `Boot UNA unit number or ROM? [R,X,0..3] (R):`

  You generally want to choose 'R' which will then launch the RomWBW
  loader.  Attempting to boot from a disk using a number at the UNA
  prompt will only work for the legacy (hd512) disk format.  However,
  if you go to the RomWBW loader, you will be able to perform a disk
  boot on either disk format.

- The disk images created and distributed with RomWBW do not have the
  correct system track code for UNA.  In order to boot to disk under
  UNA, you must first use `SYSCOPY` to update the system track of the
  target disk.  The UNA ROM disk has the correct system track files
  for UNA: `CPM.SYS` and `ZSYS.SYS`.  So, you can boot a ROM OS and
  then use one of these files to update the system track.

- The only operating systems supported at this time are CP/M 2 and
  ZSDOS.  NZ-COM is also supported because it uses the ZSDOS CBIOS.
  None of the other RomWBW operating systems are supported such as
  CP/M 3, ZPM3, and p-System.
  
- Some of the RomWBW-specific applications are not UNA compatible.
