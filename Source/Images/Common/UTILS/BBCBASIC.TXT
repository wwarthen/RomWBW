                              BBC BASIC (Z80)

                         Generic CP/M Version 3.00

                    (C) Copyright R.T.Russell 1982-1999

1. INTRODUCTION

   BBC  BASIC (Z80) has been designed to be as compatible as  possible  with 
   Version 4 of the 6502 BBC BASIC resident in the BBC Micro Master  series.  
   The language syntax is not always identical to that of the 6502  version, 
   but in most cases the Z80 version is more tolerant.

   BBC  BASIC (Z80) is as machine independent as possible and, as  supplied, 
   it  will  run  on any CP/M 2.2 (or later) system using  a  Z80  processor 
   (checks  are carried out to ensure that the processor is a Z80  and  that 
   the version of CP/M is at least 2.2).  It is minimally configured for  an 
   ADM3a-compatible VDU.

   Few  CP/M  systems  offer  colour graphics of  the  quality  provided  as 
   standard  on  the BBC Microcomputer, and no software can  provide  colour 
   high-resolution graphics from a monochrome character-orientated computer.  
   However,  many CP/M system users are interested in the  advanced  program 
   structures  available from BBC BASIC and, within the limitations  of  the 
   host  computer, BBC BASIC (Z80) provides the programming  structures  and 
   the non-graphic commands and functions specified for BBC BASIC.

   In order to make full use of the facilities available in BBC BASIC  (Z80) 
   it is necessary to install a small patch to adapt it to the  capabilities 
   of  the  host  computer.  The source code of the  patch  present  in  the 
   distribution version is supplied as BBCDIST.MAC.

   This  documentation  should be read in conjunction with  a  standard  BBC 
   BASIC  manual.  Only those features which differ from the standard  Acorn 
   versions are documented here.


2. MEMORY UTILISATION

   BBC  BASIC (Z80) requires about 16 Kbytes of code space, resulting  in  a 
   value  of  PAGE  of about &3E00.  The remainder of  the  user  memory  is 
   available  for BASIC programs, variables (heap) and stack.  Depending  on 
   the system configuration, HIMEM can have a value up to &FE00.


3. COMMANDS, STATEMENTS AND FUNCTIONS

   The syntax of BASIC commands,  statements and functions is in most  cases 
   identical  to  that  of  the  BBC  Micro  version  (BASIC  4).   The  few 
   differences are documented here:

   ADVAL
   This function is not implemented.

   CALL
   CALL  sets  up a table in RAM containing details of the  parameters;  the 
   processor's  IX register is set to the address of this  parameter  table.  
   The other processor registers are initialised as follows:

               A is initialised to the least significant byte of A%
               B is initialised to the least significant byte of B%
               C is initialised to the least significant byte of C%
               D is initialised to the least significant byte of D%
               E is initialised to the least significant byte of E%
               F is initialised to the least significant byte of F%
               H is initialised to the least significant byte of H%
               L is initialised to the least significant byte of L%

   The parameter types are:

          Code No.       Parameter Type      Example
              0          Byte (8 bits)       ?A%
              4          Word (32 bits)      !A% or A%
              5          Real (40 bits)      A
            128          Fixed string        $A%
            129          Movable string      A$

   On  entry  to the subroutine the parameter table contains  the  following 
   values:

          Number of parameters     1 byte (at IX)

          Parameter type           1 byte (at IX+1)
          Parameter address        2 bytes (at IX+2, IX+3, LSB first)

          Parameter type           ) repeated as often as necessary
          Parameter address        )

   Except  in  the case of a movable string (normal  string  variable),  the 
   parameter  address  given is the absolute address at which  the  item  is 
   stored.  In the case of movable strings (type 129) it is the address of a 
   4-byte parameter block containing the current length, the maximum  length 
   and the start address of the string (LSB first) in that order.

   Integer  variables  are stored in twos complement form with  their  least 
   significant byte first.

   Fixed  strings are stored as the characters of the string followed  by  a 
   carriage return (&0D).

   Floating point variables are stored in binary floating point format  with 
   their least significant byte first; the fifth byte is the exponent.   The 
   mantissa  is  stored as a binary fraction in sign and  magnitude  format.  
   Bit 7 of the most significant byte is the sign bit and, for the  purposes 
   of calculating the magnitude of the number, this bit is assumed to be set 
   to  one.  The exponent is stored as an integer in excess 127  format  (to 
   find the exponent subtract 127 from the value in the fifth byte).

   If the exponent byte of a floating point number is zero, the number is an 
   integer stored in integer format in the mantissa bytes.  Thus an  integer 
   can be represented in two different ways in a real variable.  For example 
   the value +5 can be stored as:

            05 00 00 00 00         Integer 5
            00 00 00 20 82         (0.5 + 0.125) * 2^3

   COLOUR (COLOR)
   This statement is not implemented.

   DRAW
   This statement is not implemented.

   EDIT
   A command to edit or concatenate and edit the specified program  line(s).  
   The specified lines (including their line numbers) are listed as a single 
   line.   By changing only the line number you can use EDIT to duplicate  a 
   line.

     EDIT 230
     EDIT 200,230

   The  following control functions are active both in the EDIT mode and  in 
   the immediate entry mode (i.e. at the BASIC prompt):

     Move the cursor one character position to the left
     Move the cursor one character position to the right
     Move the cursor to the start of the line
     Move the cursor to the end of the line
     Insert a space at the current cursor position
     Delete the character at the current cursor position
     Backspace and delete the character to the left of the cursor
     Delete all characters to the left of the cursor
     Delete all characters from the cursor to the end of the line

   The choice of which keys activate these functions is made when BBC  BASIC 
   is configured for a particular system.  The distribution version uses ^H, 
   ^I, ^K, ^J, ^A, ^E, DEL (&7F), ^L and ^X.

   To exit EDIT mode and replace the edited line, type RETURN (ENTER).

   To abort the edit and leave the line unchanged, type ESCape.

   ENVELOPE
   This statement is not implemented.

   GET
   This  function  waits for a character to be typed at  the  keyboard,  and 
   returns the ASCII code.

   GET can also be used to read data from a processor I/O port; full  16-bit 
   port addressing is available:

          N% = GET(X%) : REM input from port X%

   INKEY
   This function waits for a specified maximum number of centiseconds for  a 
   character to be typed at the keyboard.  If no character is typed in  that 
   time, the value -1 is returned.  In the distribution version the delay is 
   determined by a simple software timing loop, and may be very  inaccurate.  
   The customisation patch allows this to be adjusted to suit the system  in 
   use.

   INPUT#
   The format of data files is different from that used by the BBC Micro, in 
   part  to improve compatibility with standard CP/M files.  Numeric  values 
   are  stored  as five bytes in the format documented under  CALL;  if  the 
   fifth  byte is zero the value is an integer.  Strings are stored  as  the 
   characters  of the string (in the correct order!) followed by a  carriage 
   return (&0D).

   MODE
   This statement is not implemented.

   MOVE
   This statement is not implemented.

   PLOT
   This statement is not implemented.

   POINT
   This function is not implemented.

   PRINT#
   The format of data files is different from that used by the BBC Micro, in 
   part  to improve compatibility with standard CP/M files.  Numeric  values 
   are  stored  as five bytes in the format documented under  CALL;  if  the 
   fifth  byte is zero the value is an integer.  Strings are stored  as  the 
   characters  of the string (in the correct order!) followed by a  carriage 
   return (&0D).

   PUT
   A  statement to output data to a processor port.  Full 16-bit  addressing 
   is available.

          PUT A%,N% : REM Output N% to port A%

   SOUND
   This statement is not implemented.

   TIME
   This pseudo-variable is not implemented in the distribution version,  but 
   can be supported by means of the customisation patch.  See BBCDIST.MAC.

   USR
   As with CALL, the processor's registers are initialised as follows:

               A is initialised to the least significant byte of A%
               B is initialised to the least significant byte of B%
               C is initialised to the least significant byte of C%
               D is initialised to the least significant byte of D%
               E is initialised to the least significant byte of E%
               F is initialised to the least significant byte of F%
               H is initialised to the least significant byte of H%
               L is initialised to the least significant byte of L%

   USR returns a 32-bit integer result composed of the processor's H, L,  H' 
   and L' registers, with H being the most significant.


4. RESIDENT Z80 ASSEMBLER

   The  in-line  assembler is accessed in exactly the same way as  the  6502 
   assembler  in  the BBC Micro version of BBC BASIC.  That is,  '['  enters 
   assembler mode and ']' exits assembler mode.

   All  standard  Zilog  mnemonics are accepted: ADD, ADC and  SBC  must  be 
   followed by A or HL.  For example, ADD A,C is accepted but ADD C is  not.  
   However, the brackets around the port number in IN and OUT are  optional.  
   Thus  both OUT (5),A and OUT 5,A are accepted.  The instruction IN  F,(C) 
   is not accepted, but the equivalent code is produced from IN (HL),C

   The pseudo-ops DEFB, DEFW and DEFM are included.  DEFM works like EQUS in 
   the 6502 version.


5. OPERATING SYSTEM INTERFACE

   The   following   resident  Operating  System   ("star")   commands   are 
   implemented.  They may be accessed directly (e.g. *BYE) or via the  OSCLI 
   statement (OSCLI "BYE").

   Control characters, lower-case characters, DEL and quotation marks may be 
   incorporated in filenames by using the 'escape' character '|'.   However, 
   there is no equivalent to the BBC Microcomputer's '|!' to set bit 7.

   *BYE
   Returns control to the operating system (CP/M).

   *CPM
   Same as *BYE.

   *. [filespec]
   *DIR [filespec]
   List  the  files which match the (optional) ambiguous  filespec.  If  the 
   filespec is omitted, all .BBC files are listed:
               *DIR           List all .BBC files on the disk
               *DIR B:*.*     List all files on disk B:
               *.*.*          List all files on the current disk

   *DRIVE d:
   Select drive d as the default drive for subsequent disk operations.

   *ERA filespec
   Erase (delete) the specified disk file or files.  The extension  defaults 
   to .BBC if omitted.

   *ESC [ON|OFF]
   *ESC OFF disables the abort action of the ESCape key; after *ESC OFF  the 
   ESCape  key  simply returns the ASCII code ESC (27).  *ESC ON,  or  *ESC, 
   restores the normal action of the ESCape key.

   *EXEC filespec
   Accept  console  input  from  the  specified file  instead  of  from  the 
   keyboard. If the extension is omitted, .BBC is assumed.

   *LOAD filespec aaaa
   Loads  the specified file into memory at address aaaa. The  load  address 
   must be specified. If the extension is omitted, .BBC is assumed.

   *OPT [n]
   Select  the destination for console output characters.  The value n is in 
   the range 0 to 2, as follows:
               
          0    Send characters to the console output
          1    Send characters to the auxiliary output
          2    Send characters to the printer (list) output

   *REN newfile=oldfile
   *RENAME newfile=oldfile
   Renames  'oldfile'  as 'newfile'.  If the extension is omitted,  .BBC  is 
   assumed.

   *RESET
   Rest the disk system (CP/M function 13).  This command does not close any 
   files  nor does it perform any other housekeeping function.   You  should 
   use *RESET after you have changed a disk.

   *SAVE filespec aaaa bbbb
   *SAVE filespec aaaa +llll
   This command saves a specified range of memory to disk. The address range 
   is  specified either as start (aaaa) and end+1 (bbbb) or as start  (aaaa) 
   and length (llll). If the extension is omitted, .BBC is assumed.

   *SPOOL [filespec]
   Copy all subsequent console output to the specified file. If the filename 
   is omitted,  any current spool file is closed and spooling is terminated. 
   If the extension is omitted, .BBC is assumed.

   *TYPE filespec
   Type the specified file to the screen. If the extension is omitted,  .BBC 
   is assumed.

   *| comment
   This is a comment line. Anything following the | is ignored.


6. ERROR MESSAGES AND CODES

   Untrappable:

          No room                       RENUMBER space
          Silly                         LINE space
          Sorry                         Bad program

   Trappable - BASIC:

      1   Out of range             24   Exp range
      2                            25   
      3                            26   No such variable
      4   Mistake                  27   Missing )
      5   Missing ,                28   Bad HEX
      6   Type mismatch            29   No such FN/PROC
      7   No FN                    30   Bad call
      8                            31   Arguments
      9   Missing "                32   No FOR
     10   Bad DIM                  33   Can't match FOR
     11   DIM space                34   FOR variable
     12   Not LOCAL                35
     13   No PROC                  36   No TO
     14   Array                    37
     15   Subscript                38   No GOSUB
     16   Syntax error             39   ON syntax
     17   Escape                   40   ON range
     18   Division by zero         41   No such line
     19   String too long          42   Out of DATA
     20   Too big                  43   No REPEAT
     21   -ve root                 44
     22   Log range                45   Missing #
     23   Accuracy lost

   Trappable - OS:

     190  Directory full           214  File not found
     192  Too many open files      222  Channel
     196  File exists              253  Bad string
     198  Disk full                254  Bad command
     200  Close error              255  CP/M error
     204  Bad name
