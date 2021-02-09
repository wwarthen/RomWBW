
        FLASH4 (c) 2014-2020 William R Sowerbutts <will@sowerbutts.com>
                          http://sowerbutts.com/8bit/

= Supported machines =

FLASH4 has been tested and confirmed working on:
 * N8VEM SBCv2
 * N8VEM SBCv2 MegaFlash
 * N8VEM N8-2312
 * N8VEM Mark IV SBC
 * DX-Designs P112
 * ZETA SBC v1
 * ZETA SBC v2
 * RC2014 with 512KB ROM 512KB RAM module

It should work on many other machines that run RomWBW or UNA BIOS.  If you test
it on another machine please let me know the outcome.


= Introduction =

FLASH4 is a CP/M program which can read, write and verify Flash ROM contents to
or from an image file stored on a CP/M filesystem. It is intended for in-system
programming of Flash ROM chips on Z80 and Z180 systems.

FLASH4 aims to support a range of Flash ROM chips and machines. Ideally I would
like to support all Z80/Z180 machines. If FLASH4 does not support your machine
please let me know and I will try to add support.

When writing to the Flash ROM, FLASH4 will only reprogram the sectors whose
contents have changed. This helps to reduce wear on the flash memory, makes the
reprogram operation faster, and reduces the risk of leaving the system
unbootable if power fails during a reprogramming operation. FLASH4 always
performs a full verify operation after writing to the chip to confirm that the
correct data has been loaded.

FLASH4 is reasonably fast. Reprogramming and verifying every sector on a 512KB
SST 39F040 chip takes 21 seconds on my Mark IV SBC, versus 45 seconds to
perform the same task using a USB MiniPro TL866 EEPROM programmer under Linux
on my PC. If only a subset of sectors require reprogramming FLASH4 will be
even faster.

FLASH4 works with binary ROM image files, it does not support Intel Hex format
files. Hex files can be easily converted to or from binaries using "hex2bin" or
the "srec_cat" program from SRecord:

  $ srec_cat image.hex -intel -fill 0xFF 0 0x80000 -output image.bin -binary
  $ srec_cat image.bin -binary -output image.hex -intel

FLASH4 version 1.3 introduces support for programming multiple flash chips.
Some machines use multiple flash chips for larger ROM capacity, for example the
"Megaflash" version of the Retrobrew Computers SBC-V2 contains two 512KB flash
ROMs for a total of 1MB ROM. All flash chips in the system must be of the same
type.

FLASH4 can use several different methods to access the Flash ROM chips. The
best available method is determined automatically at run time. Alternatively
you may provide a command-line option to force the use of a specific method.

FLASH4 will detect the presence of RomWBW, UNA BIOS or P112 B/P BIOS and use
the bank switching methods they provide to map in the flash memory.

If no bank switching method can be auto-detected, and the system has a Z180
CPU, FLASH4 will use the Z180 DMA engine to access the Flash ROM chip. This
does not require any bank switching but it is slower and will not work on all
platforms. 

Z180 DMA access requires the flash ROM to be linearly mapped into the lower
region of physical memory, as it is on the Mark IV SBC (for example). The
N8-2312 has additional memory mapping hardware, consequently Z180 DMA access on
the N8-2312 is NOT SUPPORTED and if forced will corrupt the contents of RAM;
use one of the supported bank switching methods instead.

Z180 DMA access requires the Z180 CPU I/O base control register configured to
locate the internal I/O addresses at 0x40 (ie ICR bits IOA7, IOA6 = 0, 1).


= Usage =

The three basic operations are:

  FLASH4 WRITE filename [options]

  FLASH4 VERIFY filename [options]

  FLASH4 READ filename [options]

The WRITE command will rewrite the flash ROM contents from the named file. The
file size must exactly match the size of the ROM chip. After the WRITE
operation, a VERIFY operation will be performed automatically.

The VERIFY command will read out the flash ROM contents and report if it
matches the contents of the named file. The file size must exactly match the
size of the ROM chip.

The READ command will read out the entire flash ROM contents and write it to
the named file.

FLASH4 will auto-detect most parameters so additional options should not
normally be required.

The "/V" (verbose) option makes FLASH4 print one line per sector, giving a
detailed log of what it did.

The "/P" or "/PARTIAL" option can be used if your ROM chip is larger than the
image you wish to write and you only want to reprogram part of it. To avoid
accidentally flashing the wrong file, the image file must be an exact multiple
of 32KB in length. The portion of the ROM not occupied by the image file is
left either unmodified or erased.

The "/ROM" option can be used when you are using an ROM/EPROM/EEPROM chip which
cannot be programmed in-system and FLASH4 cannot recognise it.  Only the "READ"
and "VERIFY" commands are supported with this option.  This mode assumes a 512K
ROM is fitted, smaller ROMs will be treated as a 512KB ROM with the data
repeated multiple times.

One of the following optional command line arguments may be specified at the
end of the command line to force FLASH4 to use a particular method to access
the flash ROM chip:

BIOS interfaces:
  /ROMWBW         For ROMWBW BIOS version 2.6 and later
  /ROMWBWOLD      For ROMWBW BIOS version 2.5 and earlier
  /UNABIOS        For UNA BIOS

Direct hardware interfaces:
  /Z180DMA        For Z180 DMA
  /P112           For DX-Designs P112
  /N8VEMSBC       For N8VEM SBC (v1, v2), Zeta (v1) SBC

If no option is specified FLASH4 attempts to determine the best available
method automatically.

If RomWBW 2.6+ is in use, and correctly configured, then multiple flash chips
can be detected automatically. Multiple chip operation can also be manually
enabled using the command line options "/1", "/2", "/3" etc up to "/9" to
specify the number of flash chips to program. All flash chips in the system
must be of the same type.


= Supported flash memory chips =

FLASH4 will interrogate your flash ROM chip to identify it automatically.

FLASH4 does not support setting or resetting the protection bits on individual
sectors within Flash ROM devices. If your Flash ROM chip has protected sectors
you will need to unprotect them by other means before FLASH4 can erase and
reprogram them.

AT29C series chips employ an optional "software data protection" feature. This
is supported by FLASH4 and is left activated after programming the chip to
prevent accidental reprogramming of sectors.

The following chips are fully supported and will be programmed sector by
sector:

  AT29F010
  AT29F040
  M29F010
  M29F040
  MX29F040
  SST 39F010
  SST 39F020
  SST 39F040
  AT29C512
  AT29C040
  AT29C010
  AT29C020

The following chips are supported, but have unequal sector sizes, so FLASH4
will only erase and reprogram the entire chip at once:

  AT49F001N
  AT49F001NT
  AT49F002N
  AT49F002NT
  AT49F040


= Compiling =

The software is written in a mix of C and assembler. It builds using the SDCC
toolchain and the SRecord tools. SDCC 3.6 and 3.8 have been tested. A Makefile
is provided to build the executable in Linux and I imagine it can be easily
modified to build in Windows.

You may need to adjust the path to the SDCC libraries in the Makefile if your
installation is not in /usr/local or /usr


= License =

FLASH4 is licensed under the The GNU General Public License version 3 (see
included "LICENSE.txt" file). 

FLASH4 is provided with NO WARRANTY. In no event will the author be liable for
any damages. Use of this program is at your own risk. May cause rifts in space
and time.
