# Tasty Basic

## Introduction
Tasty Basic is a basic interpreter for CP/M and RomWBW ([Warthen, 2021](##References)), based on 
the Z80 port of Palo Alto Tiny Basic ([Gabbard, 2017; Rauskolb, 1976; Wang, 1976](##References)).

## Tasty Basic Language
The Tasty Basic language is based on Palo Alto Tiny Basic, as described in the December 1976
issue of Interface Age ([Rauskolb, 1976](##References)). As such, Tasty Basic shares many of the
same limitations as Palo Alto Basic. All numbers are integers and must be less than or
equal to 32767, and Tasty Basic supports only 26 variables denoted by letters A through Z.

In addition to Tiny Basic's `ABS(n)`, `RND(n)` and `SIZE` functions, Tasty Basic also provides 
statements and functions to read and write memory locations, and allows interaction with I/O ports.

### Statements
Tasty Basic provides two statements to write to memory and I/O ports:

`POKE m,n` Writes the value _n_ to address location _m_

`OUT m,n` Sends the value n to I/O port _m_

Additionally there are statements to define and read constant values:

`DATA m[,n[,...]]` Used to store constant values in the program code. Each DATA statement can define one or more numeric constants separated by commas. `DATA` statements may appear anywhere in the program.

`READ m` Reads the next available data value and assigns it to variable _m_, starting with the first item in the first `DATA` statement.

`RESTORE` Resets the `READ` pointer to the first item of the data list, allowing `DATA` values to be re-read.

#### CP/M Specific Statements
The CP/M version includes two additional statements that allow Tasty Basic programs to be saved 
to, and loaded from, disk:

`LOAD "filename"` Loads the Tasty Basic (`.TBA`) file with the given _filename_ from the current disk drive into memory. Any existing programs and variables are cleared before the program is loaded.

`SAVE "filename"` Persists the program currently in memory in a file with the given _filename_ on the current disk drive.

Refer to [Tasty Basic files](examples/README.md) for details of the `.TBA` file format.

### Functions
Tasty Basic provides the following functions to read from and write to memory locations and I/O ports:

`IN(m)` Returns the byte value read from I/O port _m_

`PEEK(m)` Returns the byte value of address location _m_

`USR(i)`  Accepts a numeric expression _i_ , calls a user-defined machine language routine, and returns the resulting value.

### User defined machine language routines
The `USR(i)` function enables interaction with user defined machine routines.
The entry point for these routines is specified using a platform specific vector
pointing to a default location as shown below. User defined code may be
placed elsewhere in memory by updating the vector values. 
The value _i_ is passed to the routine in the `DE` register, which must also 
contain the result on return.

| Platform | Vector location | Default value |
| --- | --- | --- |
| CP/M | $0BFE/$0BFF | $0C00 |
| RomWBW |  $13FE/$13FF | $1400 |

### Example
The following example shows the bit summation for a given value:

```	
  0000             #IFDEF CPM	
  0C00             	.ORG $0C00	; ie. 3072 dec
  0C00~            #ELSE
  0C00~            	.ORG $1400	; ie. 5120 dec
  0C00             #ENDIF
  0C00             
  0C00 06 00       	LD B,0
  0C02 7A          	LD A,D
  0C03 CD 0E 0C    	CALL COUNT
  0C06 7B          	LD A,E
  0C07 CD 0E 0C    	CALL COUNT
  0C0A 58          	LD E,B
  0C0B 16 00       	LD D,0
  0C0D C9          	RET
  0C0E             COUNT:
  0C0E B7          	OR A
  0C0F C8          	RET Z
  0C10 CB 47       	BIT 0,A
  0C12 28 01       	JR Z,NEXT
  0C14 04          	INC B
  0C15             NEXT:
  0C15 CB 3F       	SRL A
  0C17 18 F5       	JR COUNT
  0C19             
  0C19             	.END
```

```
10 REM -- CP/M VERSION
20 REM -- SEE EXAMPLES DIRECTORY FOR OTHER PLATFORMS
30 FOR I=0 TO 24
40 READ A
50 POKE 3072+I,A
60 NEXT I
70 INPUT P
80 LET Q=USR(P)
90 PRINT "THE BIT SUMMATION OF ",#5,P," IS ",#2,Q
100 GOTO 70
110 DATA 6,0,122,205,14,12,123,205,14,12,88,22,0,201
120 DATA 183,200,203,71,40,1,4,203,63,24,245
```

Note that the Tasty Basic program above is CP/M specific. Examples for other platforms can be found
in the `examples` directory.

## Building Tasty Basic
Building Tasty Basic requires the `uz80as` Z80 assembler v1.12 or later ([Giner, 2021](##References)). 
Alternatively, Windows users can use TASM (Telemark Assembler) ([Anderson, 1998](##References)).

### RomWBW version
Tasty Basic is part of the SBCv2 RomWBW distribution. Please refer to the 
[RomWBW github repository](https://github.com/wwarthen/RomWBW) for details.

### CP/M version
The CP/M version of Tasty Basic can be built using the `-dCPM` flag:

```uz80as -dCPM tastybasic.asm tbasic.com```

The resulting `tbasic.com` command file can be run in CP/M. For example:

```
B>TBASIC ↵

CP/M TASTY BASIC
28902 BYTES FREE

OK
>10 PRINT "HELLO WORLD ", ↵
>RUN ↵
HELLO WORLD 

OK
>BYE ↵

B>
```

## Example BASIC programs

A small number of example Tasty Basic programs are included in the `examples` directory.
Most of these programs are from _BASIC COMPUTER GAMES_ ([Ahl, 1978](##References)), and 
have been modified as required to make them work with Tasty Basic.

## License
In line with Wang's (1976) original Tiny Basic source listing and later derived works
by Rauskolb (1976) and Gabbard (2017), Tasty Basic is licensed under GPL v3.
For license details refer to the enclosed [LICENSE](../master/LICENSE) file.

## References
Ahl, D. H. (Ed.).(1978). _BASIC COMPUTER GAMES_. New York, NY: Workman Publishing  
Anderson, T. N. (1998). _The Telemark Assembler (TASM) User's Manual, Version 3.1._ Issaquah, WA: Squak Valley Software  
b1ackmai1er (2018). _SBC V2_. Retrieved  October 6, 2018, from [https://www.retrobrewcomputers.org/doku.php?id=boards:sbc:sbc_v2:start](https://www.retrobrewcomputers.org/doku.php?id=boards:sbc:sbc_v2:start)  
Gabbard, D. (2017, October 10). _TinyBASIC for the z80 – TinyBASIC 2.0g._ Retrieved September 29, 2108, from [http://retrodepot.net/?p=274](http://retrodepot.net/?p=274)  
Giner, J. (2021, August 1). _Micro Z80 assembler - uz80as._ Retrieved September 19, 2021, from [https://jorgicor.niobe.org/uz80as/](https://jorgicor.niobe.org/uz80as/)   
Rauskolb, P. (1976, December). _DR. WANG'S PALO ALTO TINY BASIC._ Interface Age, (2)1, 92-108. Retrieved from [https://archive.org/stream/InterfaceAge197612/Interface%20Age%201976-12#page/n93/mode/1up](https://archive.org/stream/InterfaceAge197612/Interface%20Age%201976-12#page/n93/mode/1up)  
Wang, L-C. (1976). _Palo Alto Tiny BASIC._ In J. C. Warren Jr. (Ed.), _Dr. Dobb's Journal of COMPUTER Calisthenics & Orthodontia_ (pp. 129-142). Menlo Park, CA: People's Computer Company  
Warthen, W. (2021). _RomWBW, Z80/Z180 System Software._ Retrieved Octover 5, 2021, from [https://github.com/wwarthen/RomWBW](https://github.com/wwarthen/RomWBW)