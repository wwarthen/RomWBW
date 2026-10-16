======================================
Assembly Language Tools by SLR Systems
======================================

===== Z80ASM by SLR Systems 1983-86 Rel. 1.32 #AB1234 =====

Z80ASM is a relocating macro assembler for CP/M. It takes assembly language
source statements from a disk file, converts them into their binary equivalent,
and stores the output in either a core-image, Intel hex format, or relocatable
object file. The mnemonics recognized are those of Zilog/Mostek. The optional
listing output may be sent to a disk file, the console and/or the printer, in
any combination. Output files may also be generated containing cross-reference
information on each symbol used.

Z80ASM.COM
CONFIG.COM

===== Z80ASM PLUS by SLR Systems 1985-86 Rel. v1.12 #L10068 =====

Referred to as the "Virtual Memory" version which uses disk for working storage,
thus not constrained by RAM.

Z80ASMP.COM
CONFIGP.COM

===== SLR180 by SLR Systems v1.31 Rel. 1.31 #AB1234 =====

SLR180 is a powerful relocating macro assembler for Z80
compatible CP/M systems. It takes assembly language source
statements from a disk file, converts them into their binary
equivalent, and stores the output in either a core-image, Intel
hex format, or relocatable object file. The mnemonics recognized
are those of Zilog/Hitachi. The optional listing output may be
sent to a disk file, the console and/or the printer, in any
combination. Output files may also be generated containing
cross-reference information on each symbol used.

SLR180.COM
180FIG.COM

===== SLRMAC by SLR Systems 1985-86 Rel. 1.32 #K10096 =====

SLRMAC is a relocating macro assembler for Intel 8080 mnemonics

SLRMAC.COM

===== MAKESYM by SLR Systems 1985 =====

MAKESYM is used to produce a .SYM file from the Symbol Table listing
provided by Z80ASM or SLRMAC.  MAKESYM reads a .LST file, converts
the symbol table to a format readable by ZSID, DSD80, etc,
and writes it to a .SYM file on the same drive.

MAKESYM.COM

===== SLRNK SuperLinker by SLR Systems 1983-86 Rel. 1.31 #AB1234 =====

SLRNK is a powerful linking loader for Z80-based CP/M systems.
It takes relocatable binary information in either Microsoft or
SLR Systems format from a disk file, resolves external and entry
point references, and stores the output in memory for execution
or outputs it to a disk file.

SLRNK.COM
LNKFIG.COM

===== SLRNK+ SuperLinker+ by SLR Systems 1985-86 Rel. 2.02 #J10154 =====

Referred to as the "Virtual Memory" version which uses disk for working storage,
thus not constrained by RAM.

Other features include: (advert in Micro Systems Journal Vol.1/No.1)
* HEX files do not fill unused space
* Intermodule crossreference
* EIGHT separate address spaces
* Works with FORTRAN & BASIC
* Generate PRL & SPR files
* Supports manual overlays
* Full 64K output

SLRNKP.COM

===== SLRIB SuperLibrarian by SLR Systems 1984 Rel. 1.30 =====

Librarian that helps you create and maintain SLR-Format libraries.
If you have several often used subroutines, much disk
space can be saved by combining the separate REL modules into a
single library file. Also, since most of the time required to
link a small separate module is the file opening and reading, it
is much faster to open one library file and scan it than to open
several separate files.

SLRIB.COM
LNKFIG.COM (same as the Linker)

===== Z80DIS Disassembler v2.2 =====

Z80DIS  is a disassembler for Z80 based CP/M systems.  Z80DIS  is
designed  to  generate  Z80 mnemonics  and  prepare  an  assembly
language   file   with   many  special  features  for   ease   of
understanding the intent of the disassembled code. The source for
Z80DIS has grown to 8400 lines of pascal code.

Z80 Disassembler program written by KENNETH GIELOW, Palo Alto, CA.

Z80DIS.COM
ZDINSTAL.COM

===== Documentation =====

The manual is available in the Doc/Language directory,
z80asm (SLR Systems).pdf
SL180 (SLR Systems 1985).pdf
SLRNK (SLR Systems 1984).pdf
Z80DIS User Manual (1985).pdf

The file SYNTAX.TXT also has a good tutorial

===== Third Party Documentation =====

A run through of using the assembler is available at
https://8bitlabs.ca/Posts/2023/05/20/learning-z80-asm

And another shorter, but shows linker usage guide
https://pollmyfinger.wordpress.com/2022/01/10/modular-retro-z80-assembly-language-programming-using-slr-systems-z80asm-and-srlnk/
