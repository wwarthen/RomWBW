ZX Command

An adaptation of zxcc-0.5.6 by Wayne Warthen

This directory contains the source files used to build the "zx" tool.  This tool
is essentially just John Elliott's zxcc package version zxcc-0.5.6 modified to
build for Windows and simplified down to just a single command (zx)
which is essentially just the zxcc command.

Please see http://www.seasip.info/Unix/Zxcc/ for more information on zxcc.

Note that this is a Win32 build.  The code has not been updated to build as a 64-bit
binary.  However, Win32 binaries run very nicely under 64 bit Windows.

To build under Open Watcom or Microsoft Visual C++, use the following command:

  cl /Fe"zx.exe" zx.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c dirent.c

To build a debug version, use the following command:

  cl /DDEBUG /Fe"zxdbg.exe" zx.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c dirent.c

WARNING: There seems to be a rare scenario that breaks zx under the Open Watcom build.
CP/M allows a file to be accessed under multiple FCB's without an error.  Open Watcom
will see this as an error.  At present, the only tool I know of that does this is M80.

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

August 21, 2021

- Incorporated filename case insensitivity changes from Curt Mayer
- Incorporated fixes from Tony Nicholson at https://github.com/agn453/ZXCC
  - Emulation of CP/M BDOS function 60 (call resident system extension)
    should be disabled and return 0xFF in both the A and L registers.
  - Change cpm_bdos_10() to return an unsigned result to avoid buffer
    size being interpreted as negative.
  - Fix the emulation of Z80 opcodes for IN (HL),(C) and
    OUT (C),(HL) - opcodes 0xED,0x70 and 0xED,0x71 respectively.
    This is noted in Fred Weigel's AM9511 arithmetic processing unit
    emulation from https://github.com/ratboy666/am9511 in the howto.txt
    description. NB: I have not included Fred's am9511 support at this
    time into ZXCC.
- Fixed parse_to_fcb function in zx.c to handle parsing second automatic
  FCB from command line
- I have not been able to reproduce the multiple FCBs referring to a
  single file issue with Watcom documented above.  Perhaps I fixed it
  and don't remember or I found a bug-fixed version of M80.  Not sure.

Wayne Warthen
wwarthen@gmail.com

--WBW 4:09 PM 8/21/2021