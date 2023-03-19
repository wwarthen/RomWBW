If you just want to use the srecord tools, you can stop reading here.

Following are instructions how I (Jens Heilig) built the srecord tools on Windows:

How to build srecord 1.64 tools on Windows:

PREREQUISITES:
==============
1) MinGW
Download and install mingw-get-inst (I used version 20110530) from http://mingw.sourceforge.net/ Select C++ and MinGW Developer Toolkit during installation.

Start MinGW Shell from the Windows Start Menu.
Install additional packages by entering following commands at the prompt:
(the "$"-sign indicates the shell-prompt. Do not type it)
$ mingw-get.exe install msys-groff-ext
$ mingw-get.exe install gettext

2) Boost Library
Download and install the Boost library from here: http://ascend4.org/Binary_installer_for_Boost_on_MinGW
Copy the newly installed files to you MinGW directory:
$ cp <boost-install-dir>/lib/* /lib/
$ cp -r <boost-install-dir>/include/boost-1_41/boost /include/


3) libgcrpyt library
Download libgcrypt-1.5.0.tar.bz2 and libgpg-error-1.10.tar.bz2 (newer versions should also work) from http://www.gnupg.org/download/index.en.html
cd to the directory where the two downloaded files are (make sure the path to this directory does not contain spaces)
$ tar jxfv libgpg-error-1.10.tar.bz2
$ cd libgpg-error-1.10
$ ./configure --disable-shared --enable-static && make && make install
(the previous step might hang when converting from ISO-8859-2 to UTF-8 late in the build process. Press ctrl-c and proceed)
$ cd ..
$ tar libgcrypt-1.5.0.tar.bz2
$ cd libgcrypt
$ ./configure --disable-shared --enable-static && make && make install

You now have all the prerequisites required to build the srecord tools. Let's proceed.


BUILDING SRECORD TOOLS
======================
cd to the directory where you unpacked the srecord source code.

Starting with srecord version 1.63 (and including version 1.64), it is necessary to modify Makefile.in:
In line 4096 remove the text "bin/test_gecos", so the line becomes:
                bin/test_crc16 bin/test_fletcher16 \               

Reason: This test program cannot be built because it requires the pwd.h header and Linux functions which are not available in MinGW


Finally, start the actual build process:

Start configure for srecord:
$ CPPFLAGS="-static -I/include -I/usr/local/include" LDFLAGS="-L/lib -L/usr/local/lib" CC='gcc -static-libgcc' CXX='g++ -static-libgcc -static-libstdc++' LIBS=-lgpg-error ./configure

After configure has run successfully, start the build process:
$ make

After successful build process, run the tests:
$ make -i sure

All tests should succeed.

Next, reduce the size of the built programs by removing debugging information:
$ cd bin
$ strip *.exe

Finally, move srec_cat.exe, srec_info.exe and srec_cmp.exe from the bin directory to where you want them, you can then delete everything else in the bin-directory.

You should now have working srecord tools!

Good Luck!
Jens Heilig, 2014-06-22
