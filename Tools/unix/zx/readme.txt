ZX Command

An adaptation of zxcc-0.5.6 by Wayne Warthen

This directory contains the source files used to build the "zx" tool.  This tool
is essentially just John Elliott's zxcc package version zxcc-0.5.6 modified to
build for Windows and simplified down to just a single command (zx)
which is essentially just the zxcc command.

Please see http://www.seasip.info/Unix/Zxcc/ for more information on zxcc.

To build under Open Watcom or Microsoft Visual C++, use the following command:

  cl /Fe"zx.exe" zx.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c dirent.c

To build a debug version, use the following command:

  cl /DDEBUG /Fe"zxdbg.exe" zx.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c dirent.c

WARNING: There seems to be a rare scenario that breaks zx under the Open Watcom build.  CP/M allows a file to be accessed
under multiple FCB's without an error.  Open Watcom will see this as an error.  At present, the only tool I know of that does
this is M80.

December 5, 2014

After struggling to get the entire zxcc package to build nicely using autoconf,
I finally gave up and took a much more direct approach.  I have extracted just
the source files needed and created a simple batch file to build the tool.  I
realize this could be done much better, but I cheated in the interest of time.

The one "real" change I made in the source code was that I modified the tool
to look for bios.bin in the same directory as the executable is in.  This
just makes it much easier to set up (for me, anyway).

The GPL status of everything remains in place and carries forward.

Wayne Warthen
wwarthen@gmail.com

March 15, 2017

- Updated to compile under Open Watcom.
- Implemented BDOS console status function.
- Set stdin and stdout to binary mode at startup.

Wayne Warthen
wwarthen@gmail.com