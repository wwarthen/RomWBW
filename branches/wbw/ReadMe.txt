************************************************************
***                     R o m W B W                      ***
***                                                      ***
***       System Software for N8VEM Z80 Projects         ***
************************************************************

Builders: Wayne Warthen (wwarthen@gmail.com)
          Douglas Goodall (douglas_goodall@mac.com)
          David Giles (vk5dg@internode.on.net)

Updated: 2013-05-17
Version: 2.5 Beta 10

This is an adaptation of CP/M-80 2.2 and ZSDOS/ZCPR
targeting ROMs for all N8VEM Z80 hardware variations
including SBC, Zeta, and N8.

NOTE: This is very much a work-in-progress.  It is
severely lacking appropriate documentation.  I am 
happy to answer questions and provide support though.

Acknowledgements
----------------

While I have heavily modified much of the code, I want
to acknowledge that much of this is derived or
copied from the work of others in the N8VEM
project including Andrew Lynch, Dan Werner, Max Scane,
David Giles, John Coffman, and probably many others 
I am not clearly aware of.

I especially want to credit Douglas Goodall for 
contributing code, time, testing, and advice.
He has created an entire suite of application
programs that substantially enhance this ROM.  Everything
in the Apps folder of the distribution came directly
from Douglas and the list includes cpmname, writesys,
assign, slices, termtype, drives, and others.

David Giles has contributed support for building the
ROM under Linux and the CSIO support in the SD Card driver.

Usage Instructions
------------------

The distribution includes many pre-built ROM
images in the Output directory.  The simplest way of
using this ROM is to simply pick the pre-built ROM
that most closely matches your preferences, burn it,
and use it.

Refer to the file called RomList.txt for a complete
list of the ROMs that are included and the required
hardware configuration that they support.

CPU Speed & Baud Rate
---------------------

The startup serial port baud rate in all pre-built
RomWBW variants is 38.4Kbps.  While this speed is
nice in that it provides great display and file
transfer performance, it does push the limits of
slower hardware.  Specifically, XModem v12.5 (the
default XM.COM) on the distribution is unable to
service the serial port fast enough if the CPU is
running at 4MHz.  Your options are to 1) use the
old version of XModem (XM5.COM), put a faster CPU
oscillator in your system (6MHz or above), or
3) decrease the baud rate by building a custom
ROM.

CP/M vs. ZSystem
----------------

There are two OS variants included in this distribution
and you may choose which one you prefer to use.

The traditional Digital Research (DRI) CP/M code is the first
choice.  The ROM images that DO NOT end in "_z" are built
with the traditional CP/M components from DRI.  The Doc
directory contains a manual for CP/M usage (cpm22-m.pdf).
If you are new to the N8VEM systems, I would currently
recommend using the CP/M ROMs to start with simply
because they have gone through more testing and you
are less likely to encounter problems.

The other choice is to use the most popular non-DRI
CP/M "clone" which is generally referred to as
ZSystem.  The ROM images with a "_z" suffix are built
using the ZSystem components (specifically ZSDOS 1.2
and ZCPR 1.0).  These are intended to be
functionally equivalent to CP/M and should run all
CP/M 2.2 code.  They are optimized for the Z80 CPU
(as opposed to 8080 for CP/M) and have some potentially
useful improvements.  Please refer to the Doc directory
and look at the files for zsdos and zcpr (zsdos.pdf &
zcpr.doc as well as ZSystem.txt).

ZSystem builds contain ZSDOS specific files in the
ROM Disk.

Building a Custom ROM
---------------------

I strongly suggest you start with burning one of the
pre-built ROMs and making sure that works first.  Once
you have gotten past that hurdle, you should consider
building a custom ROM.  It is very easy and the
distribution comes with everything that is needed to
run a build on a Windows 32 bit or 64 bit system --
basically Windows XP or above.  There is also a
Linux build now available.

Creating a custom ROM allows you to customize a lot
of useful stuff like adding support for a DSKY if
you have one.

Please refer to the Build.txt file in the Doc directory
for detailed instructions for building a custom ROM.  If
you are using Linux, also read the LinuxBuild.txt file.

Formatting Media
----------------

<TBD>

Creating Bootable Media
-----------------------

<TBD>

Using Slices on Mass Storage Devices
------------------------------------

<TBD>

Managing Console I/O
--------------------

<TBD>

Notes
-----

I realize these instructions are very minimal.  I am happy to answer
questions.  You will find the Google Group 'N8VEM' to be a great
source of information as well.