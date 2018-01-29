Image Writer for Microsoft Windows
Release 1.0.0 - The "Holy cow, we made a 1.0 Release" release.
======
About:
======
This utility is used to read and write raw image files to SD and USB memory devices.
Simply run the utility, point it at your raw image, and then select the
removable device to write to.

This utility can not write CD-ROMs.  USB Floppy is NOT supported at this time.

Future releases and source code are available on our Sourceforge project:
http://sourceforge.net/projects/win32diskimager/

This program is Beta, and has no warranty. It may eat your files,
call you names, or explode in a massive shower of code. The authors take
no responsibility for these possible events.

===================
Build Instructions:
===================
Requirements:
1. Now using QT 5.7/MinGW 5.3.  

Short Version:
1. Install the Qt Full SDK and use QT Creator to build.  
   See DEVEL.txt for details

=============
New Features:
=============
Verify Image - Now you can verify an image file with a device.  This compares
the image file to the device, not the device to the image file (i.e. if you
write a 2G image file to an 8G device, it will only read 2G of the device for
comparison).
Additional checksums - Added SHA1 and SHA256 checksums.
Read Only Allocated Partitions - Option to read only to the end of the defined partition(s).  Ex:  Write a 2G image to a 32G device, reading it to a new file will only read to the end of
the defined partition (2G).
Save last opened folder - The program will now store the last used folder in
the Windows registry and default to it on next execution.
Additional language translations (thanks to devoted users for contributing).

=============
Bugs Fixed
=============
https://bugs.launchpad.net/win32-image-writer
LP: 1285238 - Need to check filename text box for valid filename (not just a directory).
LP: 1323876 - Installer doesn't create the correct permissions on install
LP: 1330125 - Multi-partition SD card only partly copied
https://sourceforge.net/p/win32diskimager/tickets/
SF:  7 - Windows 8 x64 USB floppy access denied. Possibly imaging C drive
SF:  8 - Browse Dialog doesnt open then crashes application
SF:  9 - Cannot Read SD Card
SF: 13 - 0.9.5 version refuses to open read-only image
SF: 15 - Open a image for write, bring window in the background
SF: 27 - Error1: Incorrect function
SF: 35 - Mismatch between allocating and deleting memory buffer
SF: 39 - Miswrote to SSD
SF: 40 - Disk Imager scans whole %USERPROFILE% on start
SF: 45 - Translation files adustment



=============
Known Issues:
=============
*  Lack of reformat capabilities.
*  Lack of file compression support

These are being looked into for future releases.

======
Legal:
======
Image Writer for Windows is licensed under the General Public
License v2. The full text of this license is available in 
GPL-2.

This project uses and includes binaries of the MinGW runtime library,
which is available at http://www.mingw.org

This project uses and includes binaries of the Qt library, licensed under the 
"Library General Public License" and is available at 
http://www.qt-project.org/.

The license text is available in LGPL-2.1

Original version developed by Justin Davis <tuxdavis@gmail.com>
Maintained by the ImageWriter developers (http://sourceforge.net/projects/win32diskimager).

