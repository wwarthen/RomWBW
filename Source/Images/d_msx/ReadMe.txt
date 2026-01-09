===== MSX System Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with RomWBW.
It contains software to launch the MSX system or a MSX (game) ROM.

The source code is maintained in following repository:
https://github.com/b3rendsh/msxbase

== Requirements ==

HBDOS can be used on a Z80 or Z180 RomWBW computer with at least 192KB RAM and 
support for a system timer. MSX BASIC and the MSX ROM loader require a TMS9918A
compatible video card, system timer and 128KB RAM.

hbmsx.com requires a keyboard and VDP that is compliant with the MSX standard.
rcmsx.com uses the console keyboard and text output is displayed on both the
console and video card.
msxrom.com uses the console keyboard and requires a MSX compliant VDP and PSG.

To use HBDOS the first FAT partition on the first large storage media must
contain the MSX command interpreter i.e. the COMMAND.COM file.

Different hardware and software configurations can be supported by using
alternative build options, see source repository.

== Usage ==

Start hbmsx.com or rcmsx.com to load the MSX system HBDOS / Disk BASIC.
Start msxrom.com to load a MSX (game) ROM image e.g. "msxrom arkanoid.rom".

== HBDOS == 

HBDOS is compatible with all functions of MSX-DOS 1 and includes enhancements
to support large disks with standard FAT12 or FAT16 partitions.

It is a CP/M 2.2 work-alike DOS that uses the FAT filesystem. Many text 
applications that work on MSX-DOS 1 or CP/M 2.2 will run without modification. 
Direct disk access, FAT32, i/o byte, user areas and subdirectories are not 
supported.

At the DOS command prompt enter "basic" to start MSX BASIC.

== BASIC ==

All functions of MSX BASIC are available, if HBDOS is loaded then the Disk 
BASIC extension is also available.

Use the IPL command to return to RomWBW i.e. do a cold reboot.

In Disk BASIC use "call system" to return to the DOS command prompt.

== ROM CART ==

The MSX ROM loader supports MSX ROM cartridge images of maximum 32KB.

Not all MSX ROM games will work and some games may require an additional ROM 
patch or additional hardware. When a MSX ROM is running you can reboot RomWBW
by pressing the CTRL+STOP key (default mapped to CTRL+V).

== Console ==

The RomWBW (VT100) console can be used for keyboard input and screen output, 
with some limitations:

Cursor and function keys may not work, use control key combinations or a MSX 
compatible keyboard. 

To paste text into BASIC set the terminal send character delay to at least 40ms.

The MSX BIOS uses VT52 escape sequences, on a VT100 console sometimes an extra 
character is displayed.

The MSX 1 BIOS text mode is set to 40 columns.


-- HJB 01/06/2026
