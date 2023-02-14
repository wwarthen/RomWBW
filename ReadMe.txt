RomWBW ReadMe
Wayne Warthen (wwarthen@gmail.com)
13 Feb 2023



OVERVIEW


RomWBW software provides a complete, commercial quality implementation
of CP/M (and workalike) operating systems and applications for modern
Z80/180/280 retro-computing hardware systems. A wide variety of
platforms are supported including those produced by these developer
communities:

-   RetroBrew Computers
-   RC2014, RC2014-Z80
-   retro-comp
-   Small Computer Central

General features include:

-   Banked memory services for several banking designs
-   Disk drivers for RAM, ROM, Floppy, IDE, CF, and SD
-   Serial drivers including UART (16550-like), ASCI, ACIA, SIO
-   Video drivers including TMS9918, SY6545, MOS8563, HD6445
-   Keyboard (PS/2) drivers via VT8242 or PPI interfaces
-   Real time clock drivers including DS1302, BQ4845
-   OSes: CP/M 2.2, ZSDOS, CP/M 3, NZ-COM, ZPM3, QPM, p-System, and
    FreeRTOS
-   Built-in VT-100 terminal emulation support

RomWBW is distributed as both source code and pre-built ROM and disk
images. Some of the provided software can be launched directly from the
ROM firmware itself:

-   System Monitor
-   Operating Systems (CP/M 2.2, ZSDOS)
-   ROM BASIC (Nascom BASIC and Tasty BASIC)
-   ROM Forth

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



ACQUIRING ROMWBW


The RomWBW Repository on GitHub is the official distribution location
for all project source and documentation. The fully-built distribution
releases are available on the RomWBW Releases Page of the repository. On
this page, you will normally see a Development Snapshot as well as
recent stable releases. Unless you have a specific reason, I suggest you
stick to the most recent stable release. Expand the “Assets” drop-down
for the release you want to download, then select the asset named
RomWBW-vX.X.X-Package.zip. The Package asset includes all pre-built ROM
and Disk images as well as full source code. The other assets contain
only source code and do not have the pre-built ROM or disk images.

All source code and distributions are maintained on GitHub. Code
contributions are very welcome.



INSTALLATION & OPERATION


In general, installation of RomWBW on your platform is very simple. You
just need to program your ROM with the correct ROM image from the RomWBW
distribution. Subsequently, you can write disk images on your disk
drives (IDE disk, CF Card, SD Card, etc.) which then provides even more
functionality.

Complete instructions for installation and operation of RomWBW are found
in the RomWBW User Guide.


Documentation

Documentation for RomWBW includes:

-   RomWBW User Guide
-   RomWBW System Guide
-   RomWBW Applications
-   RomWBW ROM Applications
-   RomWBW Errata



ACKNOWLEDGMENTS


I want to acknowledge that a great deal of the code and inspiration for
RomWBW has been provided by or derived from the work of others in the
RetroBrew Computers Community. I sincerely appreciate all of their
contributions. The list below is probably missing many names – please
let me know if I missed you!

-   Andrew Lynch started it all when he created the N8VEM Z80 SBC which
    became the first platform RomWBW supported. Some of his code can
    still be found in RomWBW.

-   Dan Werner wrote much of the code from which RomWBW was originally
    derived and he has always been a great source of knowledge and
    advice.

-   Douglas Goodall contributed code, time, testing, and advice in “the
    early days”. He created an entire suite of application programs to
    enhance the use of RomWBW. Unfortunately, they have become unusable
    due to internal changes within RomWBW. As of RomWBW 2.6, these
    applications are no longer provided.

-   David Giles created support for the Z180 CSIO which is now included
    SD Card driver.

-   Ed Brindley contributed some of the code that supports the RC2014
    platform.

-   Phil Summers contributed the Forth and BASIC adaptations in ROM, the
    AY-3-8910 sound driver as well as a long list of general code
    enhancements.

-   Spencer Owen created the RC2014 series of hobbyist kit computers
    which has exponentially increased RomWBW usage.

-   Stephen Cousins has likewise created a series of hobbyist kit
    computers at Small Computer Central and is distributing RomWBW with
    many of them.

-   The CP/NET client files were developed by Douglas Miller.

-   Phillip Stevens contributed support for FreeRTOS.

-   Curt Mayer contributed the original Linux / MacOS build process.

-   UNA BIOS and FDISK80 are the products of John Coffman.

-   FLASH4 is a product of Will Sowerbutts.

-   CLRDIR is a product of Max Scane.

-   Tasty Basic is a product of Dimitri Theulings.

-   Dean Netherton contributed the sound driver interface and the
    SN76489 sound driver.

-   The RomWBW Disk Catalog document was produced by Mykl Orders.

Contributions of all kinds to RomWBW are very welcome.



LICENSING


RomWBW is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your
option) any later version.

RomWBW is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with RomWBW. If not, see https://www.gnu.org/licenses/.

Portions of RomWBW were created by, contributed by, or derived from the
work of others. It is believed that these works are being used in
accordance with the intentions and/or licensing of their creators.

If anyone feels their work is being used outside of it’s intended
licensing, please notify:

  Wayne Warthen wwarthen@gmail.com

RomWBW is an aggregate work. It is composed of many individual,
standalone programs that are distributed as a whole to function as a
cohesive system. Each program may have it’s own licensing which may be
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



GETTING ASSISTANCE


The best way to get assistance with RomWBW or any aspect of the
RetroBrew Computers projects is via one of the community forums:

-   RetroBrew Computers Forum
-   RC2014 Google Group
-   retro-comp Google Group

Submission of issues and bugs are welcome at the RomWBW GitHub
Repository.

Also feel free to email Wayne Warthen at wwarthen@gmail.com.
