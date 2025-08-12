===== HI-TECH Z80 CP/M C compiler V3.09-17 =====

The HI-TECH C Compiler is a set of software which
translates programs written in the C language to executable
machine code programs. Versions are available which compile
programs for operation under the host operating system, or
which produce programs for execution in embedded systems
without an operating system.

This is the Jun 2, 2025 update 19 released by Tony Nicholson who currently
maintains HI-TECH C at https://github.com/agn453/HI-TECH-Z80-C.

The manual is available in the Doc/Language directory,
HI-TECH Z80 C Compiler Manual.txt.

A good blog post about the HI-TECH C Compiler is available at
https://techtinkering.com/2008/10/22/installing-the-hi-tech-z80-c-compiler-for-cpm/.

== License ==

The HI-TECH Z80 CP/M C compiler V3.09 is provided free of charge for any
use, private or commercial, strictly as-is. No warranty or product
support is offered or implied.

You may use this software for whatever you like, providing you acknowledge
that the copyright to this software remains with HI-TECH Software.

== Enhanced Version ==

User area 1 contains another complete copy of the HI-TECH C Compiler.
It is identical to the copy in user area 0 except for the following files
which were enhanced by Ladislau Szilagyi from his GitHub Repository at
https://github.com/Laci1953/HiTech-C-compiler-enhanced.  The files
take advantage of additional banked memory using the RomWBW HBIOS API.
As such, they require RomWBW to operate.  They should be compatible with
all CP/M and compatible operating systems provided in RomWBW.

The enhanced files are:

- CGEN.COM
- CPP.COM
- OPTIM.COM
- P1.COM
- ZAS.COM

A thread discussing this enhanced version of HI-TECH C is found at
https://groups.google.com/g/rc2014-z80/c/sBCCIpOnnGg.

One of the size optimizations of P1.COM is the removal of the textual
warning and error messages.  The code number for each of these
messages will still be printed.  The textual description for all of
these warnings/errors can be found in the Doc/Language directory,
HI-TECH Z80 C Compiler Messages.txt.

== Sample Application ==

This disk image includes a very small sample application called
HELLO.C that can be used to demonstrate the build process.  The
following commands will build this sample application.

C -V HELLO.C

Then run it by typeing
HELLO
