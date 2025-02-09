$define{doc_title}{Hardware}$
$include{"Book.h"}$
$define{doc_author}{Mark Pruden \& Wayne Warthen}$
$define{doc_authmail}{}$

# Supported Hardware Platforms

This section contains a summary of the system configuration target
for each of the pre-built ROM images included in the RomWBW
distribution.  

It is intended to help you select the correct ROM
image and understand the basic hardware components supported.
Detailed hardware system configuration information should be obtained
from your system provider/designer.  

The table below summarizes the hardware platforms currently supported
by RomWBW along with the standard pre-built ROM image(s).  

| **Description**                                             | **Bus** | **ROM Image File**           | **Baud Rate** |
|-------------------------------------------------------------|---------|------------------------------|--------------:|
| [RetroBrew Z80 SBC]^1^                                      | ECB     | SBC_std.rom                  | 38400         |
| [RetroBrew Z80 SimH]^1^                                     | -       | SBC_simh.rom                 | 38400         |
| [RetroBrew N8 Z180 SBC]^1^ (date >= 2312)                   | ECB     | N8_std.rom                   | 38400         |
| [Zeta Z80 SBC]^2^, ParPortProp                              | -       | ZETA_std.rom                 | 38400         |
| [Zeta V2 Z80 SBC]^2^, ParPortProp                           | -       | ZETA2_std.rom                | 38400         |
| [Mark IV Z180 SBC]^3^                                       | ECB     | MK4_std.rom                  | 38400         |
| [RCBus Z80 CPU Module]^4^, 512K RAM/ROM                     | RCBus   | RCZ80_std.rom                | 115200        |
| [RCBus Z80 CPU Module]^4^, 512K w/KIO                       | RCBus   | RCZ80_kio_std.rom            | 115200        |
| [RCBus Z180 CPU Module]^4^ w/ ext banking                   | RCBus   | RCZ180_ext_std.rom           | 115200        |
| [RCBus Z180 CPU Module]^4^ w/ native banking                | RCBus   | RCZ180_nat_std.rom           | 115200        |
| [RCBus Z280 CPU Module]^4^ w/ ext banking                   | RCBus   | RCZ280_ext_std.rom           | 115200        |
| [RCBus Z280 CPU Module]^4^ w/ native banking                | RCBus   | RCZ280_nat_std.rom           | 115200        |
| [RCBus eZ80 CPU Module]^13^, 512K RAM/ROM                   | RCBus   | RCEZ80_std.rom               | 115200        |
| [Easy Z80 SBC]^2^                                           | RCBus   | RCZ80_easy_std.rom           | 115200        |
| [Tiny Z80 SBC]^2^                                           | RCBus   | RCZ80_tiny_std.rom           | 115200        |
| [Z80-512K CPU/RAM/ROM Module]^2^                            | RCBus   | RCZ80_skz_std.rom            | 115200        |
| [Small Computer SC126 Z180 SBC]^5^                          | BP80    | SCZ180_sc126_std.rom         | 115200        |
| [Small Computer SC130 Z180 SBC]^5^                          | RCBus   | SCZ180_sc130_std.rom         | 115200        |
| [Small Computer SC131 Z180 Pocket Comp]^5^                  | -       | SCZ180_sc131_std.rom         | 115200        |
| [Small Computer SC140 Z180 CPU Module]^5^                   | Z50     | SCZ180_sc140_std.rom         | 115200        |
| [Small Computer SC503 Z180 CPU Module]^5^                   | Z50     | SCZ180_sc503_std.rom         | 115200        |
| [Small Computer SC700 Z180 CPU Module]^5^                   | RCBus   | SCZ180_sc700_std.rom         | 115200        |
| [Dyno Z180 SBC]^6^                                          | Dyno    | DYNO_std.rom                 | 38400         |
| [Nhyodyne Z80 MBC]^1^                                       | MBC     | MBC_std.rom                  | 38400         |
| [Rhyophyre Z180 SBC]^1^                                     | -       | RPH_std.rom                  | 38400         |
| [Z80 ZRC CPU Module]^7^                                     | RCBus   | RCZ80_zrc_std.rom            | 115200        |
| [Z80 ZRC CPU Module]^7^ ROMless                             | RCBus   | RCZ80_zrc_ram_std.rom        | 115200        |
| [Z80 ZRC512 CPU Module]^7^                                  | RCBus   | RCZ80_zrc512_std.rom         | 115200        |
| [Z80 EaZy80-512 CPU Module]^7^                              | RCBus   | RCZ80_ez512_std.rom          | 115200        |
| [Z80 K80W CPU Module]^7^                                    | RCBus   | RCZ80_k8w_std.rom            | 115200        |
| [Z180 Z1RCC CPU Module]^7^                                  | RCBus   | RCZ180_z1rcc_std.rom         | 115200        |
| [Z280 ZZRCC CPU Module]^7^                                  | RCBus   | RCZ280_zzrcc_std.rom         | 115200        |
| [Z280 ZZRCC CPU Module]^7^ ROMless                          | RCBus   | RCZ280_zzrcc_ram_std.rom     | 115200        |
| [Z280 ZZ80MB SBC]^7^                                        | RCBus   | RCZ280_zz80mb_std.rom        | 115200        |
| [Z80-Retro SBC]^8^                                          | -       | Z80RETRO_std.rom             | 38400         |
| [S100 Computers Z180]^9^                                    | S100    | S100_std.rom                 | 57600         |
| [Duodyne Z80 System]^1^                                     | Duo     | DUO_std.rom                  | 38400         |
| [Heath H8 Z80 System]^10^                                   | H8      | HEATH_std.rom                | 115200        |
| [EP Mini-ITX Z180]^11^                                      | RCBus?  | EPITX_std.rom                | 115200        |
| [NABU w/ RomWBW Option Board]^10^                           | NABU    | NABU_std.rom                 | 115200        |
| [S100 FPGA Z80]^9^                                          | S100    | FZ80_std.rom                 | 9600          |
| [Genesis STD Z180]^12^                                      | STD     | GMZ180_std.rom               | 115200        |

| ^1^Designed by Andrew Lynch
| ^2^Designed by Sergey Kiselev
| ^3^Designed by John Coffman
| ^4^RCBus compliant (multiple products/designers)
| ^5^Designed by Stephen Cousins
| ^6^Designed by Steve Garcia
| ^7^Designed by Bill Shen
| ^8^Designed by Peter Wilson
| ^9^Designed by John Monahan
| ^10^Designed by Les Bird
| ^11^Designed by Alan Cox
| ^12^Designed by Doug Jackson
| ^13^Designed by Dean Netherton

RCBus refers to Spencer Owen's RC2014 bus specification and derivatives
including RC26, RC40, RC80, and BP80.

The RCBus Z180 & Z280 require a separate RAM/ROM memory module. There
are two types of these modules and you must pick the correct ROM for
your type of memory module.  The first option is the same as the 512K
RAM/ROM module for RC/BP80 Bus.  This is called external ("ext") because
the bank switching is performed externally from the CPU.  The second
type of RAM/ROM module has no bank switching logic -- this is called
native ("nat") because the CPU itself provides the bank switching logic.
Only Z180 and Z280 CPUs have the ability to do bank switching in the
CPU, so the ext/nat selection only applies to them.  Z80 CPUs have no
built-in bank switching logic, so they are always configured for
external bank switching.

The standard ROM images will detect and install support for certain
devices and peripherals that are on-board or frequently used with
each platform.  If the device or peripheral is not detected at boot, 
the ROM will simply bypass support appropriately.

In some cases, support for multiple hardware components with potentially
conflicting resource usage are handled by a single ROM image.  It is up
to the user to ensure that no conflicting hardware is in use.

All pre-built ROM images are pure binary files (they are not "hex"
files).  They are intended to be programmed starting at the very start
of the ROM chip (address 0).  Most of the pre-built images are
512KB in size.  If your system utilizes a larger ROM, you can just
program the image into the first 512KB of the ROM for now.

`\clearpage`{=latex}

# Platform Configurations

## RetroBrew Z80 SBC

#### ROM Image File:  SBC_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | None          |
| System Timer      | None          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | SBC           |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=112
- UART: MODE=SBC, IO=104
- UART: MODE=CAS, IO=128
- UART: MODE=MFP, IO=104
- UART: MODE=4UART, IO=192
- UART: MODE=4UART, IO=200
- UART: MODE=4UART, IO=208
- UART: MODE=4UART, IO=216
- SIO MODE=ZP, IO=176, CHANNEL A
- SIO MODE=ZP, IO=176, CHANNEL B
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

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## RetroBrew Z80 SimH

#### ROM Image File:  SBC_simh.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | SimH          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | SBC           |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- SIMRTC: IO=254
- UART: MODE=SBC, IO=104
- UART: MODE=CAS, IO=128
- UART: MODE=MFP, IO=104
- UART: MODE=4UART, IO=192
- UART: MODE=4UART, IO=200
- UART: MODE=4UART, IO=208
- UART: MODE=4UART, IO=216
- SIO MODE=ZP, IO=176, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=ZP, IO=176, CHANNEL B, INTERRUPTS ENABLED
- FONTS occupy 0 bytes.
- MD: TYPE=RAM
- MD: TYPE=ROM
- HDSK: IO=253, DEVICE COUNT=2

#### Notes:

- Image for SimH emulator
- CPU speed and Serial configuration not relevant in emulator

`\clearpage`{=latex}

## RetroBrew N8 Z180 SBC

#### ROM Image File:  N8_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=CAS, IO=128
- UART: MODE=4UART, IO=192
- UART: MODE=4UART, IO=200
- UART: MODE=4UART, IO=208
- UART: MODE=4UART, IO=216
- TMS: MODE=N8, IO=152
- PPK: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=N8, IO=140, DRIVE 0, TYPE=3.5" HD
- FD: MODE=N8, IO=140, DRIVE 1, TYPE=3.5" HD
- SD: MODE=CSIO, IO=136, UNITS=1
- AY38910: MODE=N8, IO=156, CLOCK=1789772 HZ

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present
- SD Card interface is configured for CSIO (N8 date code >= 2312)

`\clearpage`{=latex}

## Zeta Z80 SBC

#### ROM Image File:  ZETA_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 8.000  MHz    |
| Interrupts        | None          |
| System Timer      | None          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | SBC           |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=112
- UART: MODE=SBC, IO=104
- PPP: IO=96
- PPPCON: ENABLED
- PPPSD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=DIO, IO=54, DRIVE 0, TYPE=3.5" HD

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present
- If ParPortProp is installed, initial console output is
  determined by JP1:
  - Shorted: console to on-board serial port
  - Open: console to ParPortProp video and keyboard

`\clearpage`{=latex}

## Zeta V2 Z80 SBC

#### ROM Image File:  ZETA2_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 8.000  MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 38400 Baud    |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=112
- UART: MODE=SBC, IO=104
- PPP: IO=96
- PPPCON: ENABLED
- PPPSD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=ZETA2, IO=48, DRIVE 0, TYPE=3.5" HD
- CTC: IO=32, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present
- If ParPortProp is installed, initial console output is
  determined by JP1:
  - Shorted: console to on-board serial port
  - Open: console to ParPortProp video and keyboard

`\clearpage`{=latex}

## Mark IV Z180 SBC

#### ROM Image File:  MK4_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=CAS, IO=128
- UART: MODE=MFP, IO=104
- UART: MODE=4UART, IO=192
- UART: MODE=4UART, IO=200
- UART: MODE=4UART, IO=208
- UART: MODE=4UART, IO=216
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

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## RCBus Z80 CPU Module

#### ROM Image File:  RCZ80_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 7.372 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=136

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

#### ROM Image File:  RCZ80_kio_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 7.372 MHz     |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=132, TIMER MODE=TIMER/16, DIVISOR=9216, HI=256, LO=36, INTERRUPTS ENABLED

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present
- SIO Serial baud rate managed by CTC

`\clearpage`{=latex}

## RCBus Z180 CPU Module

#### ROM Image File:  RCZ180_ext_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- For use with Z2 bank switched memory board (Z2 external memory management)
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

#### ROM Image File:  RCZ180_nat_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- For use with linear memory board (Z180 native memory management)
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## RCBus Z280 CPU Module

#### ROM Image File:  RCZ280_ext_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 6.000 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- Z2U: IO=16
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- ACIA: IO=128, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE

#### Notes:

- For use with Z2 bank switched memory board (Z2 external memory management)

`\clearpage`{=latex}

#### ROM Image File:  RCZ280_nat_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 6.000 MHz     |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- For use with linear memory board (Z280 native memory management)

`\clearpage`{=latex}

## RCBus eZ80 CPU Module

#### ROM Image File:  RCEZ80_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 20.000 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | EZ80          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218
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

#### Notes:

`\clearpage`{=latex}

## Easy Z80 SBC

#### ROM Image File:  RCZ80_easy_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 10.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- INTRTC: ENABLED
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=136, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Tiny Z80 SBC

#### ROM Image File:  RCZ80_tiny_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 16.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=16, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z80-512K CPU/RAM/ROM Module

#### ROM Image File:  RCZ80_skz_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 7.372 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=136

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Small Computer SC126 Z180 SBC

#### ROM Image File:  SCZ180_sc126_std.rom

|                   |               |
|-------------------|---------------|
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
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- AY38910: MODE=RCZ180, IO=104, CLOCK=1789772 HZ

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present
- When disabled, watchdog requires /IM to be pulsed.  If an RCBus module
  holds the CPU in WAIT for more than this, the watchdog will fire when
  disabled with random consequences.  The Pico SD does this at power-on.

`\clearpage`{=latex}

## Small Computer SC130 Z180 SBC

#### ROM Image File:  SCZ180_sc130_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- AY38910: MODE=RCZ180, IO=104, CLOCK=1789772 HZ

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Small Computer SC131 Z180 Pocket Comp

#### ROM Image File:  SCZ180_sc131_std.rom

|                   |               |
|-------------------|---------------|
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

#### Notes:

`\clearpage`{=latex}

## Small Computer SC140 Z180 CPU Module

#### ROM Image File:  SCZ180_sc140_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Small Computer SC503 Z180 CPU Module

#### ROM Image File:  SCZ180_sc503_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Small Computer SC700 Z180 CPU Module

#### ROM Image File:  SCZ180_sc700_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0
- DSRTC: MODE=STD, IO=12
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- AY38910: MODE=RCZ180, IO=104, CLOCK=1789772 HZ

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Dyno Z180 SBC

#### ROM Image File:  DYNO_std.rom

|                   |               |
|-------------------|---------------|
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

#### Notes:

`\clearpage`{=latex}

## Nhyodyne Z80 MBC

#### ROM Image File:  MBC_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | None          |
| System Timer      | None          |
| Serial Default    | 38400 Baud    |
| Memory Manager    | MBC           |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- PKD: IO=96
- DSRTC: MODE=STD, IO=112
- UART: MODE=SBC, IO=104
- UART: MODE=DUAL, IO=128
- UART: MODE=DUAL, IO=136
- SIO MODE=ZP, IO=176, CHANNEL A
- SIO MODE=ZP, IO=176, CHANNEL B
- PIO: IO=184, CHANNEL A
- PIO: IO=184, CHANNEL B
- PIO: IO=188, CHANNEL A
- PIO: IO=188, CHANNEL B
- LPT: MODE=SPP, IO=232
- CVDU: MODE=MBC, IO=224, KBD MODE=PS/2, KBD IO=226
- TMS: MODE=MBC, IO=152
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
- CTC: IO=176

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Rhyophyre Z180 SBC

#### ROM Image File:  RPH_std.rom

|                   |               |
|-------------------|---------------|
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

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z80 ZRC CPU Module

#### ROM Image File:  RCZ80_zrc_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | ZRC           |
| ROM Size          | 512 KB        |
| RAM Size          | 1536 KB       |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=136

#### Notes:

- ZRC is actually contains no ROM and 2MB of RAM.  The first 512KB
  of RAM is loaded from disk and then handled like ROM.
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

#### ROM Image File:  RCZ80_zrc_ram_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | ZRC           |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=136

#### Notes:

- ROMless boot -- HBIOS is loaded from disk at boot
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z80 ZRC512 CPU Module

#### ROM Image File:  RCZ80_zrc512_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 22.000 MHz    |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | ZRC           |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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
- CTC: IO=136

#### Notes:

- ROMless boot -- HBIOS is loaded from disk at boot
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z80 EaZy80-512 CPU Module

#### ROM Image File:  RCZ80_ez512_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 22.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 115200 Baud   |
| Memory Manager    | EZ512         |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- LCD: IO=218, SIZE=20X4
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
- SIO MODE=STD, IO=8, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=STD, IO=8, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128
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
- SD: MODE=EZ512, IO=2, UNITS=1
- KIO: IO=0
- CTC: IO=4, TIMER MODE=TIMER/16, DIVISOR=4608, HI=256, LO=18, INTERRUPTS ENABLED

#### Notes:

- HBIOS is loaded from disk at boot by ROM monitor
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z80 K80W CPU Module

#### ROM Image File:  RCZ80_k8w_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 22.000 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
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
- CTC: IO=132, TIMER MODE=TIMER/16, DIVISOR=9216, HI=256, LO=36, INTERRUPTS ENABLED

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z180 Z1RCC CPU Module

#### ROM Image File:  RCZ180_z1rcc_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- ROMless boot -- HBIOS is loaded from disk at boot
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z280 ZZRCC CPU Module

#### ROM Image File:  RCZ280_zzrcc_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 256 KB        |
| RAM Size          | 256 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- CH: IO=62
- CH: IO=60
- CHUSB: IO=62
- CHUSB: IO=60
- VRC: IO=0, KBD MODE=VRC, KBD IO=244
- KBD: ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE

#### Notes:

- ZZRCC actually contains no ROM and 512KB of RAM.  The first 256KB
  of RAM is loaded from disk and then handled like ROM.
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

#### ROM Image File:  RCZ280_zzrcc_ram_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 14.745 MHz    |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- ROMless boot -- HBIOS is loaded from disk at boot
- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z280 ZZ80MB SBC

#### ROM Image File:  RCZ280_zz80mb_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 12.000 MHz    |
| Interrupts        | Mode 3        |
| System Timer      | Z280          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z280          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- Z2U: IO=16, INTERRUPTS ENABLED
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
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

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Z80-Retro SBC

#### ROM Image File:  Z80RETRO_std.rom

|                   |               |
|-------------------|---------------|
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
- SD: MODE=, IO=104, UNITS=1
- CTC: IO=64

#### Notes:

`\clearpage`{=latex}

## S100 Computers Z180

#### ROM Image File:  S100_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 57600 Baud    |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0
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

## Duodyne Z80 System

#### ROM Image File:  DUO_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | Mode 2        |
| System Timer      | CTC           |
| Serial Default    | 38400 Baud    |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=148
- PCF: IO=86
- UART: MODE=SBC, IO=88
- UART: MODE=AUX, IO=168
- UART: MODE=DUAL, IO=112
- UART: MODE=DUAL, IO=120
- SIO MODE=ZP, IO=96, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=ZP, IO=96, CHANNEL B, INTERRUPTS ENABLED
- PIO: IO=104, CHANNEL A
- PIO: IO=104, CHANNEL B
- PIO: IO=108, CHANNEL A
- PIO: IO=108, CHANNEL B
- LPT: MODE=SPP, IO=72
- TMS: MODE=MBC, IO=160
- DMA: MODE=DUO, IO=64
- CH: IO=78
- CHUSB: IO=78
- CHSD: IO=78
- ESP: IO=156
- ESPCON: ENABLED
- ESPSER: DEVICE=0
- ESPSER: DEVICE=1
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=DUO, IO=128, DRIVE 0, TYPE=3.5" HD
- FD: MODE=DUO, IO=128, DRIVE 1, TYPE=3.5" HD
- PPIDE: IO=136, MASTER
- PPIDE: IO=136, SLAVE
- SD: MODE=, IO=140, UNITS=1
- SPK: IO=148
- CTC: IO=96, TIMER MODE=COUNTER, DIVISOR=18432, HI=256, LO=72, INTERRUPTS ENABLED
- AY38910: MODE=DUO, IO=164, CLOCK=1789772 HZ

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## Heath H8 Z80 System

#### ROM Image File:  HEATH_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 7.372 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=0, SWIO=0
- DSRTC: MODE=STD, IO=192
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
- SIO MODE=RC, IO=128, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=128, CHANNEL B, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL A, INTERRUPTS ENABLED
- SIO MODE=RC, IO=132, CHANNEL B, INTERRUPTS ENABLED
- ACIA: IO=128, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=RCWDC, IO=80, DRIVE 0, TYPE=3.5" HD
- FD: MODE=RCWDC, IO=80, DRIVE 1, TYPE=3.5" HD
- IDE: MODE=RC, IO=16, MASTER
- IDE: MODE=RC, IO=16, SLAVE
- PPIDE: IO=32, MASTER
- PPIDE: IO=32, SLAVE
- CTC: IO=136

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present

`\clearpage`{=latex}

## EP Mini-ITX Z180

#### ROM Image File:  EPITX_std.rom

|                   |               |
|-------------------|---------------|
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
- UART: MODE=RC, IO=160
- UART: MODE=RC, IO=168
- TMS: MODE=MSX, IO=152
- MD: TYPE=RAM
- MD: TYPE=ROM
- FD: MODE=EPFDC, IO=72, DRIVE 0, TYPE=3.5" HD
- FD: MODE=EPFDC, IO=72, DRIVE 1, TYPE=3.5" HD
- SD: MODE=, IO=66, UNITS=1

#### Notes:

`\clearpage`{=latex}

## NABU w/ RomWBW Option Board

#### ROM Image File:  NABU_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 3.580 MHz     |
| Interrupts        | Mode 1        |
| System Timer      | None          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z2            |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- UART: MODE=NABU, IO=72
- TMS: MODE=NABU, IO=160
- MD: TYPE=RAM
- MD: TYPE=ROM
- PPIDE: IO=96, MASTER
- PPIDE: IO=96, SLAVE
- AY38910: MODE=NABU, IO=65, CLOCK=1789772 HZ

#### Notes:

- TMS video assumes F18A replacement for TMS9918

`\clearpage`{=latex}

## S100 FPGA Z80

#### ROM Image File:  FZ80_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 8.000 MHz     |
| Interrupts        | None          |
| System Timer      | None          |
| Serial Default    | 9600 Baud     |
| Memory Manager    | Z2            |
| ROM Size          | 0 KB          |
| RAM Size          | 512 KB        |

#### Supported Hardware

- FP: LEDIO=255
- SSER: IO=52
- SCON: IO=0
- MD: TYPE=RAM
- PPIDE: IO=48, MASTER
- PPIDE: IO=48, SLAVE
- FP: LEDIO=255
- DS5RTC: RTCIO=104, IO=104
- SSER: IO=52
- SCON: IO=0
- MD: TYPE=RAM
- PPIDE: IO=48, MASTER
- PPIDE: IO=48, SLAVE
- SD: MODE=FZ80, IO=108, UNITS=2

#### Notes:

- Requires matching FPGA code

## Genesis STD Z180

#### ROM Image File:  GMZ180_std.rom

|                   |               |
|-------------------|---------------|
| Default CPU Speed | 18.432 MHz    |
| Interrupts        | Mode 2        |
| System Timer      | Z180          |
| Serial Default    | 115200 Baud   |
| Memory Manager    | Z180          |
| ROM Size          | 512 KB        |
| RAM Size          | 512 KB        |

#### Supported Hardware

- DSRTC: MODE=STD, IO=132
- INTRTC: ENABLED
- ASCI: IO=192, INTERRUPTS ENABLED
- ASCI: IO=193, INTERRUPTS ENABLED
- MD: TYPE=RAM
- MD: TYPE=ROM
- IDE: MODE=GIDE, IO=32, MASTER
- IDE: MODE=GIDE, IO=32, SLAVE
- SD: MODE=GM, IO=132, UNITS=1

#### Notes:

- CPU speed will be dynamically measured at startup if DSRTC is present


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
| FD        | 8272 or compatible Floppy Disk Controller              |
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
| VDU       | MC6845 Family Video Display Controller                 |
| VGA       | HD6445CP4-based Video Display Controller               |
| VRC       | VGARC Video Display Controller                         |

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
| KIO       | Zilog Serial/ Parallel Counter/Timer                   |
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

# Errata

The following errata apply to $doc_product$ $doc_ver$:

* The use of high density floppy disks requires a CPU speed of 8 MHz or 
  greater.

* The PropIO support is based on RomWBW specific firmware. Be sure to 
  program/update your PropIO firmware with the corresponding firmware 
  image provided in the Binary directory of the RomWBW distribution.

* Reading bytes from the video memory of the VDU board (not Color 
  VDU) appears to be problematic. This is only an issue when the driver 
  needs to scroll a portion of the screen which is done by applications 
  such as WordStar or ZDE. You are likely to see screen corruption in 
  this case.

* The RomWBW `TUNE` application will detect an AY-3-8910/YM2149
  Sound Module regardless of whether support for it is included in
  the RomWBW HBIOS configuration.
