       CAMELFORTH FOR THE Z80 - BETA TEST VERSION - 16 APRIL 1995
       ==========================================================

This is a BETA TEST version of CamelForth/80, an ANSI Standard Forth for
the Zilog Z80 microprocessor and the CP/M operating system.  This means
that, although I have tested the bulk of this code for correct
functioning, and have fixed several bugs, you may discover new bugs.
I'd appreciate hearing of any such, either

                 by Internet:  bj@camelforth.com

I'll also answer questions and try to solve problems.

                                 * * *

As distributed, CamelForth will assemble to run under CP/M 2.x.  It
determines the highest available RAM location from CP/M, and places its
data areas (stacks, user area, etc.) immediately below that.  The
CamelForth program resides in the bottom of the CP/M program area
(100h), and any user definitions are added immediately after.  CP/M's
default command buffer at 80h is used for the Terminal Input Buffer.

To start CamelForth under CP/M, type the command

        CAMEL80  ...any Forth commands...

CamelForth will execute the rest of the CP/M command line as a Forth
statement, and then enter the Forth interpreter.  To return to CP/M, use
the command

        BYE

Note that CamelForth is CASE SENSITIVE, and all Forth words are in UPPER
CASE.

                    MODIFICATION FOR STANDALONE USE

CamelForth can be easily assembled for a standalone or embedded Z80.
About 6K of PROM and 640 bytes of RAM are used by CamelForth, plus
whatever additional PROM and RAM is needed by your program.  You will
probably need to provide the Z80 reset vector, e.g.

        org 0
        jp reset

You must also add any required hardware initialization, and the Forth
words KEY KEY? and EMIT for your hardware.  You should modify the
'reset' routine to use an equate for end of RAM, e.g.

reset:  ld hl,ramend  ; end of available memory (EM)
        dec h        ; EM-100h
        ld sp,hl     ;      = top of param stack
        inc h        ; EM
         etc.

If you are putting CamelForth in PROM, but want to have a Forth
dictionary in RAM (so you can add new definitions), you'll have to
change the 'enddict' equate (at the end of camel80.azm) to the your
starting RAM address.  Do NOT change the 'lastword' equate.

The Terminal Input Buffer must be moved to a new location in RAM.  The
usual CamelForth usage is 80h bytes below the user area.  TIB can be
redefined as

;X tib     -- a-addr     Terminal Input Buffer
;  HEX -80 USER TIB      below user area
    head TIB,3,TIB,douser
        dw -80h

You should also delete the line

        DW LIT,80h,COUNT,INTERPRET

from the routine COLD.  This line causes the CP/M command "tail" to be
executed as a Forth command...inapplicable in a standalone system.

                                 * * *

This program was written using the Z80MR macro assembler under CP/M.
Z80MR is a freeware assembler, available from GEnie and several other
CP/M archives.  Assemble the CamelForth source files with the commands

        z80mr camel80
        load camel80

Z80MR produces an Intel hex file camel80.hex, and LOAD generates the
file camel80.com.  (Note: do NOT use the version of Z80MR that directly
outputs a .COM file; that version of the assembler has bugs.)  For
embedded applications you probably can skip the LOAD, since most PROM
programmers, PROM emulators, and debug programs will accept Intel hex
files.

If you don't have CP/M, you can use the MYZ80 emulator on an IBM PC, or
you can rewrite the source code for your Z80 macro assembler.

There are TWO WAYS to write embedded programs in CamelForth:

1. If you have CamelForth running on an embedded Z80, you can download
Forth code directly to CamelForth.  This lets you type new words from
the keyboard, test them as they are defined, and re-define them to make
changes.  Or you can edit an ASCII text file, and use a program such as
Procomm to send this file over the serial port to your Z80.  It can take
a few seconds to compile each line, so be sure to leave plenty of delay
after the line.  (I'm working on handshaking to improve this.)  Also be
sure that no line exceeds 80 characters.

2. If you you want to burn your program into PROM, you can add your code
to the file CAMEL80.ASM.  (I recommend creating a separate file and
using the *INCLUDE directive.)  This requires you to convert your Forth
code to assembler code.  To show how this is done, every high-level
Forth word in the file is shown with its equivalent Forth code in a
comment.  Be especially careful with control structures (IF..ELSE..THEN,
BEGIN..UNTIL, DO..LOOP, and the like), and with the Forth word headers.
Reassemble CAMEL80.AZM and burn a PROM (or download to a PROM emulator
or debug monitor), then test.  This is a much slower process, and is
best saved for the final stage when you have a tested & debugged program
that you want to put in PROM.

Disk I/O is not yet supported under CP/M.  However, CamelForth v1.2 will
accept commands from a CP/M SUBMIT file using the XSUB utility.  The
SUBMIT file should contain the commands

        XSUB
        CAMEL80
        ...Forth source code...

This will run CamelForth/80 under XSUB, which will feed the rest of the
file to CamelForth as terminal input.  You can automatically return to
CP/M by putting the CamelForth BYE command in the file.  Then you can
save the modified CamelForth image with the CP/M command

        SAVE nn CAMELNEW.COM

'nn' is the decimal number of pages occupied by the CamelForth
dictionary.  You can determine this value while in CamelForth with the
statement

        DECIMAL HERE 0 256 UM/MOD NIP .

Unfortunately, at the moment there's no way to totally automate this as
part of the SUBMIT file.  And I'm reluctant to add SAVE to CamelForth
when CP/M has a perfectly good SAVE command.

                                 * * *

--------------------------- LICENSE TERMS ------------------------------
CamelForth for the Zilog Z80 Copyright 1994,1995 Bradford J. Rodriguez.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Commercial inquiries should be directed to the author at 
115 First St., #105, Collingwood, Ontario L9Y 4W3 Canada
or via email to bj@camelforth.com
------------------------------------------------------------------------

