

**RomWBW ReadMe** \
Version 3.3 \
Wayne Warthen  ([wwarthen@gmail.com](mailto:wwarthen@gmail.com)) \
16 Apr 2023

# Overview

RomWBW software provides a complete, commercial quality implementation
of CP/M (and workalike) operating systems and applications for modern
Z80/180/280 retro-computing hardware systems. A wide variety of
platforms are supported including those produced by these developer
communities:

- [RetroBrew Computers](https://www.retrobrewcomputers.org)
- [RC2014](https://rc2014.co.uk),
  [RC2014-Z80](https://groups.google.com/g/rc2014-z80)
- [retro-comp](https://groups.google.com/forum/#!forum/retro-comp)
- [Small Computer Central](https://smallcomputercentral.com/)

General features include:

- Banked memory services for several banking designs
- Disk drivers for RAM, ROM, Floppy, IDE, CF, and SD
- Serial drivers including UART (16550-like), ASCI, ACIA, SIO
- Video drivers including TMS9918, SY6545, MOS8563, HD6445
- Keyboard (PS/2) drivers via VT8242 or PPI interfaces
- Real time clock drivers including DS1302, BQ4845
- OSes: CP/M 2.2, ZSDOS, CP/M 3, NZ-COM, ZPM3, QPM, p-System, and
  FreeRTOS
- Built-in VT-100 terminal emulation support

RomWBW is distributed as both source code and pre-built ROM and disk
images. Some of the provided software can be launched directly from the
ROM firmware itself:

- System Monitor
- Operating Systems (CP/M 2.2, ZSDOS)
- ROM BASIC (Nascom BASIC and Tasty BASIC)
- ROM Forth

A dynamic disk drive letter assignment mechanism allows mapping
operating system drive letters to any available disk media.
Additionally, mass storage devices (IDE Disk, CF Card, SD Card) support
the use of multiple slices (up to 256 per device). Each slice contains a
complete CP/M filesystem and can be mapped independently to any drive
letter. This overcomes the inherent size limitations in legacy OSes and
allows up to 2GB of accessible storage on a single device.

The pre-built ROM firmware images are generally suitable for most users.
However, it is also very easy to modify and build custom ROM images that
fully tailor the firmware to your specific preferences. All tools
required to build custom ROM firmware under Windows are included – no
need to install assemblers, etc. The firmware can also be built using
Linux or MacOS after confirming a few standard tools have been
installed.

Multiple disk images are provided in the distribution. Most disk images
contain a complete, bootable, ready-to-run implementation of a specific
operating system. A “combo” disk image contains multiple slices, each
with a full operating system implementation. If you use this disk image,
you can easily pick whichever operating system you want to boot without
changing media.

By design, RomWBW isolates all of the hardware specific functions in the
ROM chip itself. The ROM provides a hardware abstraction layer such that
all of the operating systems and applications on a disk will run on any
RomWBW-based system. To put it simply, you can take a disk (or CF/SD
Card) and move it between systems transparently.

A tool is provided that allows you to access a FAT-12/16/32 filesystem.
The FAT filesystem may be coresident on the same disk media as RomWBW
slices or on stand-alone media. This makes exchanging files with modern
OSes such as Windows, MacOS, and Linux very easy.

# Acquiring RomWBW

The [RomWBW Repository](https://github.com/wwarthen/RomWBW) on GitHub is
the official distribution location for all project source and
documentation. The fully-built distribution releases are available on
the [RomWBW Releases Page](https://github.com/wwarthen/RomWBW/releases)
of the repository. On this page, you will normally see a Development
Snapshot as well as recent stable releases. Unless you have a specific
reason, I suggest you stick to the most recent stable release. Expand
the “Assets” drop-down for the release you want to download, then select
the asset named RomWBW-vX.X.X-Package.zip. The Package asset includes
all pre-built ROM and Disk images as well as full source code. The other
assets contain only source code and do not have the pre-built ROM or
disk images.

All source code and distributions are maintained on GitHub. Code
contributions are very welcome.

# Installation & Operation

In general, installation of RomWBW on your platform is very simple. You
just need to program your ROM with the correct ROM image from the RomWBW
distribution. Subsequently, you can write disk images on your disk
drives (IDE disk, CF Card, SD Card, etc.) which then provides even more
functionality.

Complete instructions for installation and operation of RomWBW are found
in the [RomWBW User
Guide](https://github.com/wwarthen/RomWBW/raw/dev/Doc/RomWBW%20User%20Guide.pdf).

## Documentation

Documentation for RomWBW includes:

- [RomWBW User
  Guide](https://github.com/wwarthen/RomWBW/raw/dev/Doc/RomWBW%20User%20Guide.pdf)
- [RomWBW System
  Guide](https://github.com/wwarthen/RomWBW/raw/dev/Doc/RomWBW%20System%20Guide.pdf)
- [RomWBW
  Applications](https://github.com/wwarthen/RomWBW/raw/dev/Doc/RomWBW%20Applications.pdf)
- [RomWBW ROM
  Applications](https://github.com/wwarthen/RomWBW/raw/dev/Doc/RomWBW%20ROM%20Applications.pdf)
- [RomWBW
  Errata](https://github.com/wwarthen/RomWBW/raw/dev/Doc/RomWBW%20Errata.pdf)

# Acknowledgments

I want to acknowledge that a great deal of the code and inspiration for
RomWBW has been provided by or derived from the work of others in the
RetroBrew Computers Community. I sincerely appreciate all of their
contributions. The list below is probably missing many names – please
let me know if I missed you!

- Andrew Lynch started it all when he created the N8VEM Z80 SBC which
  became the first platform RomWBW supported. Some of his original code
  can still be found in RomWBW.

- Dan Werner wrote much of the code from which RomWBW was originally
  derived and he has always been a great source of knowledge and advice.

- Douglas Goodall contributed code, time, testing, and advice in “the
  early days”. He created an entire suite of application programs to
  enhance the use of RomWBW. Unfortunately, they have become unusable
  due to internal changes within RomWBW. As of RomWBW 2.6, these
  applications are no longer provided.

- Sergey Kiselev created several hardware platforms for RomWBW including
  the very popular Zeta.

- David Giles created support for the Z180 CSIO which is now included SD
  Card driver.

- Phil Summers contributed the Forth and BASIC adaptations in ROM, the
  AY-3-8910 sound driver, DMA support, and a long list of general code
  and documentation enhancements.

- Ed Brindley contributed some of the code that supports the RCBus
  platform.

- Spencer Owen created the RC2014 series of hobbyist kit computers which
  has exponentially increased RomWBW usage. Some of his kits include
  RomWBW.

- Stephen Cousins has likewise created a series of hobbyist kit
  computers at Small Computer Central and is distributing RomWBW with
  many of them.

- Alan Cox has contributed some driver code and has provided a great
  deal of advice.

- The CP/NET client files were developed by Douglas Miller.

- Phillip Stevens contributed support for FreeRTOS.

- Curt Mayer contributed the original Linux / MacOS build process.

- UNA BIOS and FDISK80 are the products of John Coffman.

- FLASH4 is a product of Will Sowerbutts.

- CLRDIR is a product of Max Scane.

- Tasty Basic is a product of Dimitri Theulings.

- Dean Netherton contributed the sound driver interface and the SN76489
  sound driver.

- The RomWBW Disk Catalog document was produced by Mykl Orders.

Contributions of all kinds to RomWBW are very welcome.

# Licensing

RomWBW is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your
option) any later version.

RomWBW is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with RomWBW. If not, see <https://www.gnu.org/licenses/>.

Portions of RomWBW were created by, contributed by, or derived from the
work of others. It is believed that these works are being used in
accordance with the intentions and/or licensing of their creators.

If anyone feels their work is being used outside of its intended
licensing, please notify:

> Wayne Warthen  
> <wwarthen@gmail.com>

RomWBW is an aggregate work. It is composed of many individual,
standalone programs that are distributed as a whole to function as a
cohesive system. Each program may have its own licensing which may be
different from other programs within the aggregate.

In some cases, a single program (e.g., CP/M Operating System) is
composed of multiple components with different licenses. It is believed
that in all such cases the licenses are compatible with GPL version 3.

RomWBW encourages code contributions from others. Contributors may
assert their own copyright in their contributions by annotating the
contributed source code appropriately. Contributors are further
encouraged to submit their contributions via the RomWBW source code
control system to ensure their contributions are clearly documented.

All contributions to RomWBW are subject to this license.

# Getting Assistance

The best way to get assistance with RomWBW or any aspect of the
RetroBrew Computers projects is via one of the community forums:

- [RetroBrew Computers Forum](https://www.retrobrewcomputers.org/forum/)
- [RC2014 Google
  Group](https://groups.google.com/forum/#!forum/rc2014-z80)
- [retro-comp Google
  Group](https://groups.google.com/forum/#!forum/retro-comp)

Submission of issues and bugs are welcome at the [RomWBW GitHub
Repository](https://github.com/wwarthen/RomWBW).

Also feel free to email Wayne Warthen at <wwarthen@gmail.com>.
