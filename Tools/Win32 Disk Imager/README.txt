Image Writer for Microsoft Windows
Release 0.9.5 - Unnamed Edition 2: The oddly released sequel
======
About:
======
This utility is used to write img files to SD and USB memory devices.
Simply run the utility, point it at your img, and then select the
removable device to write to.

This utility can not write CD-ROMs.

Future releases and source code are available on our Sourceforge project:
http://sourceforge.net/projects/win32diskimager/

This program is Beta , and has no warranty. It may eat your files,
call you names, or explode in a massive shower of code. The authors take
no responsibility for these possible events.

===================
Build Instructions:
===================
Requirements:
1. Now using QT 5.2.1/MinGW 4.8.  Snapshot available in the Build Tools directory at
https://sourceforge.net/projects/win32diskimager/files/Build%20Tools/

Short Version:
1. Install the Qt Full SDK and use QT Creator to build.  Included batch files 
   no longer updated and may be deleted in the future.

=============
New Features:
=============
Build support for QT 5.2/MinGW 4.8.
Some additional language translations.
Now uses Innosetup to create an Installer.

=============
Known Issues:
=============

*  Lack of reformat capabilities.
*  Lack of file compression support
*  Does not work with USB Floppy drives.

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

