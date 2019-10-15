***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

Wayne Warthen (wwarthen@gmail.com)
Version 2.9.2-pre.18, 2019-10-14
https://www.retrobrewcomputers.org/

RomWBW is a ROM-based implementation of CP/M-80 2.2 and Z-System for 
all RetroBrew Computers Z80/Z180 hardware platforms including SBC 
1/2, Zeta 1/2, N8, Mark IV, RC2014, SC, and Easy Z80. Virtually all 
RetroBrew hardware is supported including floppy, hard disk (IDE, CF 
Card, SD Card), Video, and keyboard. VT-100 terminal emulation is 
built-in.

The RomWBW ROM loads and runs the built-in operating systems directly
from the ROM and includes a selection of standard/useful applications
accessed via a ROM disk drive.  A RAM disk drive is also provided
to allow temporary file storage.

Pre-built ROM images are included for all platforms.  Detailed system 
customization is achieved by making simple modifications to a 
configuration file and running a build script to generate a custom 
ROM image. All source and build tools are included in the 
distribution. As distributed, the build scripts run under any modern 
32 or 64 bit version of Microsoft Windows.

John Coffman's UNA hardware BIOS is fully supported by RomWBW. In the 
case of UNA, a single ROM image (pre-built) is used for all supported 
platforms and is customized using a ROM-based setup program. See the 
UNA section below for more information.

Quick Start
-----------

A pre-built ROM image is included for each of the hardware platforms 
supported. These ROM images are found in the Binary directory of the 
distribution and have a file extension of ".rom". Simply program the 
ROM of your system with the appropriate ROM image. Please see the 
RomList.txt file in the Binary directory for details on selecting the 
correct ROM image for your system and platform specific information.

=================================================================
=== It is critical that you pick the right ROM image for your ===
=== system.  Please be sure to review the RomList.txt file to ===
=== ensure you pick the right one.                            ===
=================================================================

Connect a serial terminal or computer with terminal emulation 
software to the primary RS-232 port of your CPU board.  A null-modem 
connection is generally required.  Set the line characteristics to 
38400 baud, 8 data bits, 1 stop bit, no parity, and no flow control. 
Select VT-100 terminal emulation.  In the case of the RC2014 with a 
Z80 CPU or Easy Z80, the baud rate is determined by hardware, but is 
normally 115200 baud.  RC2014 with a Z180 CPU defaults to the 
built-in Z180 serial ports and will run at 38400 baud.

Upon power-up, your terminal should display a sign-on banner within 2 
seconds followed by hardware inventory and discovery information.  
When hardware initialization is completed, a boot loader prompt 
allows you to choose a ROM-based operating system, system monitor, or 
boot from a disk device.

CPU Speed
---------

RomWBW ROM images support virtually any CPU speed your system is
running. However, there are some hardware-oriented caveats to be
aware of.

The use of high density floppy disks requires a CPU speed of 8 MHz or
greater.

Upgrading from Previous Versions
--------------------------------

Program a new ROM chip from an image in the new distribution. Install 
the new ROM chip and boot your system. At the boot loader "Boot:" 
prompt, select either CP/M or Z-System to load the OS from ROM.

If you have spare rom chips for your system, it is always safest to
keep your existing, working ROM chip and program a new one so that you
can return to the old one if the new one does not work properly.

If you use a customized ROM image, it is recommended that you first
try the pre-built ROM image first and then move on to generating a
custom image.

It is entirely possible to reprogram your system ROM using the FLASH
utility from Will Sowerbutts on your ROM drive (B:). In this case,
you would need to transfer the new ROM image to your system using
X-Modem. Obviously, there is some risk to this approach since any
issues with the programming or ROM image could result in a
non-functional system.

If your system has any bootable drives, then update the OS image on
each drive using SYSCOPY. For example, if C: is a bootable drive
with the Z-System OS, you would update the OS image on this drive
with the command:

    B>SYSCOPY C:=B:ZSYS.SYS

If you have copies of any of the system utilities on drives other
than the ROM disk drive, you need to copy the latest version of the
programs from the ROM drive (B:) to any drives containing these
programs. For example, if you have a copy of the ASSIGN.COM program
on C:, you would update it from the new ROM using the COPY command:

    B>COPY B:ASSIGN.COM C:

The following programs are maintained with the ROM images and all
copies of these programs should be updated when upgrading to a new
ROM version:

    - ASSIGN.COM
    - FORMAT.COM
    - OSLDR.COM
    - SYSCOPY.COM
    - TALK.COM
    - FDU.COM
    - XM.COM
    - RTC.COM

UNA Hardware BIOS
-----------------

John Coffman has produced a new generation of hardware BIOS called 
UNA. In addition to the classic ROM images, RomWBW comes with a 
UNA-based image that combines the UNA BIOS with the RomWBW OS 
implementations and applications.

UNA is customized dynamically using a ROM based setup routine and the
setup is persisted in the system NVRAM of the RTC chip. This means
that a single UNA-based ROM image can be used on most of the
RetroBrew platforms and is easily customized. UNA also supports FAT
file system access that can be used for in-situ ROM programming and
loading system images.

While John is likely to enhance UNA over time, there are currently a
few things that UNA does not support:

    - Floppy Drives
    - Video/Keyboard/Terminal Emulation
    - Zeta 1, N8, RC2014, SC, and Easy Z80 systems
    - Some older support boards

If you wish to try the UNA variant of RomWBW, then just program your
ROM with the ROM image called "UNA_std.rom" in the Binary directory.
This one image is suitable on all of the platforms and hardware UNA
supports.

Please refer to the RetroBrew Computers Wiki for more information on
UNA.

CP/M vs. Z-System
-----------------

There are two OS variants included in this distribution and you may
choose which one you prefer to use. Both variants are now included
in the pre-built ROM images. You will be given the choice to boot
either CP/M or Z-System at startup.

The traditional Digital Research (DRI) CP/M OS is the first choice.
The Doc directory contains a manual for CP/M usage ("CPM
Manual.pdf"). If you are new to the RetroBrew Computer systems, I
would currently recommend using the CP/M variant to start with simply
because it has gone through more testing and you are less likely to
encounter problems.

The other choice is to use the most popular non-DRI CP/M "clone"
which is generally referred to as Z-System. It is intended to be
functionally equivalent to CP/M and should run all CP/M 2.2 code. It
is optimized for the Z80 CPU (as opposed to 8080 for CP/M) and has
some potentially useful improvements. Please refer to "ZSDOS
Manual.pdf" and "ZCPR Manual.pdf" in the Doc directory for more
information on Z-System usage.

CP/M 3
------

CP/M 3 exists in an experimental state.  CP/M 3 must be started
from a disk drive.  In the distribution archive, in the Binary
directory, you will find a cpm_hd.img file that can be copied
over to a CF or SD Card.  Start your system with this card
installed and boot to CP/M 2.2 or ZSystem as usual.  Switch to
the drive containing the CP/M 3 image and use the CPMLDR command
to load CP/M.  It will ask you for the disk unit number containing
the CP/M 3 system files which are on the disk image you created.

ROM Customization
-----------------

The pre-built ROM images are configured for the basic capabilities of
each platform. If you add board(s) to your system, you will need to
customize your ROM image to include support for the added board(s).

Essentially, the creation of a custom ROM is accomplished by updating
a small configuration file, then running a script to compile the
software and generate the custom ROM image. At this time, the build
process runs on Windows 32 or 64 bit versions. All tools (compilers,
assemblers, etc.) are included in the distribution, so it is not
necessary to setup a build environment on your computer.

For those who are interested in more than basic system customization, 
note that all source code is included (including the operating 
systems).

Note that the ROM customization process does not apply to UNA. All
UNA customization is performed within the ROM setup script.

Complete documentation of the customization process is found in the
ReadMe.txt file in the Source directory.

Inbuilt ROM Applications
------------------------

Additonal software other than the CP/M and Z-System application can
be included in the ROM image for execution from the ROM loader. 

Current inclusions are:

	Monitor     - Z80 debug monitor with hexload capability.
	Forth       - Brad Rodriguez's ANS compatible Forth.
	Basic	    - Nascom 8K BASIC.
	Tasty BASIC - Dimitri Theulings Tiny BASIC implementation.
	
	Note: To exit type B in Monitor and BYE in other applications.
	
Space is available in the ROM image for the inclusion of other 
software. Any inbuild application can be set up to launch 
automatically at startup.

Source Code Respository
-----------------------

All source code and distributions are maintained on GitHub at
"https://github.com/wwarthen/RomWBW".  Code contributions are very
welcome.

Distribution Directory Layout
-----------------------------

The RomWBW distribution is a compressed zip archive file organized in 
a set of directories.  Each of these directories has it's own
ReadMe.txt file describing the contents in detail.  In summary, these
directories are:

  Binary: The final output files of the build process are placed
          here.  Most importantly, are the ROM images with the
	  file names ending in ".rom".

  Doc:    Contains various detailed documentation including the
          operating systems, RomWBW architecture, etc.

  Source: Contains the source code files used to build the software
          and ROM images.
  
  Tools:  Contains the MS Windows programs that are used by the
          build process or that may be useful in setting up your
	  system.

Acknowledgements
----------------

While I have heavily modified much of the code, I want to acknowledge
that much of the work is derived or copied from the work of others in
the RetroBrew Computers project including Andrew Lynch, Dan Werner,
Max Scane, David Giles, John Coffman, and probably many others I am
not clearly aware of (let me know if I omitted someone!).

I especially want to credit Douglas Goodall for contributing code,
time, testing, and advice. He created an entire suite of application
programs to enhance the use of RomWBW. However, he is looking for
someone to continue the maintenance of these applications and they
have become unusable due to changes within RomWBW. As of RomWBW 2.6,
these applications are no longer provided.

David Giles has contributed support for the CSIO support in the SD
Card driver.

The UNA BIOS is a product of John Coffman.

Getting Assistance
------------------

The best way to get assistance with RomWBW or any aspect of the
RetroBrew Computers projects is via the community forum at
"https://www.retrobrewcomputers.org/forum/".

Also feel free to email Wayne Warthen at wwarthen@gmail.com.

Documentation To Do
-------------------

    - Formatting Media
    - Making a Disk Bootable
    - Assigning disks/slices to drives
    - Managing the Console
