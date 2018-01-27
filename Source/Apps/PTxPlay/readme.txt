Universal PT2 and PT3 player for ZX Spectrum and MSX Release 1
(c)2004-2007 S.V.Bulba <vorobey@mail.khstu.ru>
http://bulba.untergrund.net/ (http://bulba.at.kz/)
Release date: 30 of April 2007

Common remarks
--------------

The project is a compact combination of two players: Vortex Tracker II v1.0 PT3
player for ZX Spectrum and Universal PT2 player for ZX Spectrum and MSX
computers. This player is a little slower than standalone players, but more
compact: less than 2K instead of 2.6K (1.6+1).

As bonus there are some additional functions (conditional assembly):

1) ROUT procedure for ZX or MSX;
2) positions counter at (START+11);
3) ability to change channels allocation during playing;
4) checking loop point;
5) disabling official identificator.

New for this release: added PT v3.7 features (commands 1.xx and 2.xx).

Project was compiled in assembler for Win32:

SjASM Z80 Assembler v0.39f
Copyright 2005 Sjoerd Mastijn

Files
-----

PTxPlay.asm - source Z80 assembler code.
PTxPlay.h - same text is prepared for Alasm.
PTxPlay.txt - same text is prepared for ZX Asm 3.10.
PTxPlay - assembled binary code block in minimal configuration for ZX Spectrum
with identificator to load at #C000 address, zeroes at end can be truncated.

Entry points
------------

Before playing at (START+10) set bit 1 for PT2 and reset for PT3 and call START
(loading) address. To detect module type you can use UniSearch by Spectre.

Player is not reallocable, so you need to assemble with other ORG value, if you
want to load code at other than #C000 address, also you can place VARS area to
any other address too. After calling START AY is stop any sounding. At START+10
is located SETUP byte, where bit 0 is used to control looping of melody. At any
time you can set bit 0 to disable loop. Bit 7 can be checked at any moment, it
is set after reaching end of module (finishing playing of last position). Bits
2 and 3 is used for setting channels allocation. Only first three combinations
of these bits are allowed: 0 - ABC, 1 - ACB, 2 - BAC. ABC is used to output
channels "as is". ACB swaps B and C, and BAC swaps A and B. So, any stereo
combinations can be heard: ABC-stereo for the most xUSSR ZX-clones, ACB - East
Europe ones, and BAC - ZS Scorpion 256K.

In current compilation module must be loaded after variables (by default). Of
course, you can change it in source or in assembled code. Also you can specify
module address in HL as follows:

	LD HL,PT3ModuleAddress
	XOR A ;PT3
	LD (START+10),A
	CALL START+3

By calling START you are proceeding INIT procedure, which analyzes module type
bit and prepares corresponding player branches, checks PT3 module version and
prepares corresponding note and volume tables (it is need for correct playing of
modules of different PT3 subversions). Also you can call START after stopping
playing to mute AY sound. In last case you can call START+8 to simple mute AY
sound, to continue playing simply continue calling START+5 as usually.

To play, call START+5 address each 1/50 of second (interrupt). Playing selects
right portamento algorithm for old (v3.5-) and new (v3.6+ or VT II) modules.
During running PLAY subprogram no any interrupts are expected, it is your task
to right call PLAY. For example, next example is totaly right:

	CALL #C000 ;calling init
	EI ;enable interrupts
_LP	HALT ;wait for next interrupt
	CALL #C005 ;call play, player uses 10500 tacts max,
;so no interrupt can be before next HALT
	XOR A ;test keyboard
	IN A,(#FE)
	CPL
	AND 15
	JR Z,_LP
	CALL #C008 ;mute AY sound (you can resume playing from current place)
	RET

At START+11 current position byte can be placed (see conditional assembly keys).
To get common number of position, see module header or use UniSearch by Spectre.

Example of playing without loop:

	LD A,1
	LD (START+10),A
	CALL START
	EI
LOOP	HALT
	CALL START+5
	LD A,(START+10)
	RLA
	JR NC,LOOP
	RET

Read also all comments in source file.

Thanks to Andrey Bogdanovich aka Spectre for help and UniSearch; Ivan Roshin for
tone and volume tables generators; Alfonso D.C. aka Dioniso for info about MSX.

Sergey Bulba

19 of September 2004 - 30 of April 2007
