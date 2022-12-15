# ZDE 1.6 (Z-System Display Editor) reconstituted source - MECPARTS 
11/19/2020

Using the source code of [VDE 2.67]
(http://www.classiccmp.org/cpmarchives/cpm/Software/WalnutCD/enterprs/cpm/utils/s/vde267sc.lbr)
as a guide, I've reconstituted the source code for [ZDE 1.6](http://www.classiccmp.org/cpmarchives/cpm/Software/WalnutCD/cpm/editor/zde16.lbr).

The source has been assembled with:

* Al Hawley's ZMAC: assemble as is.
* MicroSoft's M80: rename to ZDE16.MAC, un-comment the first two lines
  and assemble. Use RELHEX to create ZDE16.HEX.
* ZASM (Cromemco's ASMB): Rename to ZDE16.Z80 and assemble. Use RELHEX
to create ZDE16.HEX.

Use MLOAD to create ZDE16.COM.

There are still a couple of routines new to ZDE that I haven't figured
out (yet). But most of them have been sussed out.

## ZDE 1.7 - MECPARTS 11/24/2020

I've fixed the "doesn't preserve timestamps for files larger than a
single extent under ZSDOS" bug that was present in v1.6. The existing
ZDENST16.COM program will work with the 1.7 to set the program up for
your terminal and printer.

## ZDE 1.8 - Lars Nelson 12/3/2022

Added routine to save create time stamp under CP/M Plus since 
CP/M Plus, unlike ZSDOS, has no native ability to set time stamps.