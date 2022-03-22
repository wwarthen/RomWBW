This is an adaptation of zxcc-0.5.7 for RomWBW by Wayne Warthen.

In general, this is a stripped down variant of John Elliott's zxcc package that
runs under a Windows command line (32 or 64 bit Windows), Linux, or MacOS.
This adaptation implements only the main "zxcc" command.  The other programs
(zxc, zxas, zxlink, and zslibr) are not inluded here because they are fairly
specific to Hi-Tech C.

Please see http://www.seasip.info/Unix/Zxcc/ for more information on the original
version of zxcc.  Also, refer to https://github.com/agn453/ZXCC which has an
updated version of the code.

The included zxcc.html documentation is from the original version, so it does not
reflect the changes made here.

To build under Open Watcom, use Build-OW.cmd.  To build under Microsoft Visual C,
use Build-VC.cmd.  To build under Linux or MacOS, use the Makefile.

The GPL status of everything remains in place and carries forward.

December 5, 2014

After struggling to get the entire zxcc package to build nicely using autoconf,
I finally gave up and took a much more direct approach.  I have extracted just
the source files needed and created a simple batch file to build the tool.  I
realize this could be done much better, but I cheated in the interest of time.

The one "real" change I made in the source code was that I modified the tool
to look for bios.bin in the same directory as the executable is in.  This
just makes it much easier to set up (for me, anyway).

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
- Fixed parse_to_fcb function in zxcc.c to handle parsing second automatic
  FCB from command line

Wayne Warthen
wwarthen@gmail.com

--WBW 4:09 PM 8/21/2021

January 9, 2022

- Running zxcc under WSL (Windows Subsystem for Linux) was gererating output
  that was correct but did not match standard Windows or Linux runs.  This
  turned out to be an assumption in a few places in the code that reading
  into a buffer would not modify the area of the buffer that was beyond
  the space required by the data being read.  Under WSL, this "slack" space
  was mangled.  I made changes in these locations to clean up the slack
  space after such reads.  This fixed WSL runs to produce binary identical
  output.  Although only required by WSL, the changes cause no problems for
  other environments and are actually correct per POSIX.

--WBW 11:56 AM 1/9/2022

- I have attempted to sync my code up with the latest code found in Tony
  Nicholson's GitHub repo at https://github.com/agn453/ZXCC.  The most
  significant difference in my code is that I am using the WIN32 API
  for all disk I/O.  Although the file tracking code is retained, I have
  found this mechanism to fail insome scenarios.  By using the WIN32 API
  I can achieve the same file sharing attributes as Unix which makes the
  file tracking mechanism optional.

--WBW 9:34 AM 2/10/2022

- Added a call to trackFile in fcb_close.  I think it was always
  supposed to be there.  Was not causing any real problems other
  than superfluous attempts by releaseFile to close files that
  were already closed.
  
--WBW 3:58 PM 3/2/2022

