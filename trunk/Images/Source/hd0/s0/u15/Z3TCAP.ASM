; ZCPR3 System Segment: Z3TCAP (Terminal Capabilities File)
; Author: Richard Conn
; Version: 1.3

; Modified slightly and added some more terminals.  13 Sep 84  jww
; More terminals.  25 Sept 84  jww
; More terminals.  12 Oct 84  jww
; More terminals.  28 Oct 84  jww (Version 1.3)

esc	equ	1bh		; Escape character  jww

;
;	Z3TCAP is divided into to main parts -- the index, which contains
; a set of 16-byte entries describing the names of the terminals to follow
; and the main body, which contains the details on the terminals themselves.
; Origin does not make any difference since everything is relative anyway.
; The index is always an integral number of 128-byte blocks in size, and
; each terminal entry in the main body is 128 bytes in size.
;

	ORG	100H	; just for consistency

;
;  Z3TCAP INDEX
;	Structure is:
;		DS	16	; Name of Terminal
;		...
;		DB	'                '	; Blank Entry Marks End
;		DS	16*n	; Required to fill out last 128-byte block
;
	DB	'AA Ambassador   '	;Name of Terminal
	DB	'ADDS Consul 980 '	;Name of Terminal
	DB	'ADDS Regent 20  '	;Name of Terminal
	DB	'ADDS Viewpoint  '	;Name of Terminal
	DB	'ADM 2           '	;Name of Terminal
	DB	'ADM 31          '	;Name of Terminal
	DB	'ADM 3A          '	;Name of Terminal
	DB	'ADM 42          '	;Name of Terminal
	DB	'Bantam 550      '	;Name of Terminal
	DB	'CDC 456         '	;Name of Terminal
	DB	'Concept 100     '	;Name of Terminal
	DB	'Concept 108     '	;Name of Terminal
	DB	'CT82            '	;Name of Terminal
	DB	'DEC VT52        '	;Name of Terminal
	DB	'DEC VT100       '	;Name of Terminal
	DB	'Dialogue 80     '	;Name of Terminal
	DB	'Direct 800/A    '	;Name of Terminal
	DB	'Epson GENEVA    '	;Name of Terminal
	DB	'Epson QX-10     '	;Name of Terminal
	DB	'General Trm 100A'	;Name of Terminal
	DB	'Hazeltine 1420  '	;Name of Terminal
	DB	'Hazeltine 1500  '	;Name of Terminal
	DB	'Hazeltine 1510  '	;Name of Terminal
	DB	'Hazeltine 1520  '	;Name of Terminal
	DB	'H19 (ANSI Mode) '	;Name of Terminal
	DB	'H19 (Heath Mode)'	;Name of Terminal
	DB	'HP 2621         '	;Name of Terminal
	DB	'IBM 3101        '	;Name of Terminal
	DB	'Kaypro II       '	;Name of Terminal
	DB	'Kaypro 10       '	;Name of Terminal
	DB	'Micro Bee       '	;Name of Terminal
	DB	'Microterm ACT IV'	;Name of Terminal
	DB	'Microterm ACT V '	;Name of Terminal
	DB	'NorthStar Advant'	;Name of Terminal
	DB	'Osborne I       '	;Name of Terminal
	DB	'P Elmer 1100    '	;Name of Terminal
	DB	'P Elmer 1200    '	;Name of Terminal
	DB	'Qume QVT 102    '	;Name of Terminal
	DB	'SOROC 120       '	;Name of Terminal
	DB	'Super Bee       '	;Name of Terminal
	DB	'TAB 132         '	;Name of Terminal
	DB	'Teleray 1061    '	;Name of Terminal
	DB	'Teleray 3800    '	;Name of Terminal
	DB	'TTY 4424        '	;Name of Terminal
	DB	'TVI 912         '	;Name of Terminal
	DB	'TVI 920         '	;Name of Terminal
	DB	'TVI 950         '	;Name of Terminal
	DB	'TVI 970         '	;Name of Terminal
	DB	'VC 404          '	;Name of Terminal
	DB	'VC 415          '	;Name of Terminal
	DB	'Visual 200      '	;Name of Terminal
	DB	'WYSE 50         '	;Name of Terminal

	DB	' 1.3            '	; Last Entry
;
;  Compute Space Remaining to Fill 128-byte Block
;
endsp	equ	128-($-$/128*128)
	if	(endsp eq 128)
	DS	0
	else
	DS	endsp
	endif

;
;  TERMS - Terminal Data
;	Structure is:
;		DS	16	; Name of Terminal
;		DS	1	; Char for Cursor UP
;		DS	1	; Char for Cursor DOWN
;		DS	1	; Char for Cursor RIGHT
;		DS	1	; Char for Cursor LEFT
;		DS	1	; Delay After CL
;		DS	1	; Delay After CM
;		DS	1	; Delay After CE
;		DS	N	; CL string, ending in 0
;		DS	N	; CM string, ending in 0
;		DS	N	; CE string, ending in 0
;		DS	N	; SO string, ending in 0
;		DS	N	; SE string, ending in 0
;		DS	N	; TI string, ending in 0
;		DS	N	; TE string, ending in 0
;

; Terminal xxxx
TTABLE:
	DB	'AA Ambassador   '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	156			;CL Delay
	DB	00			;CM Delay
	DB	05			;CE Delay
	DB	esc,'[H',esc,'[J',0	;CL String
	DB	esc,'[%i%d;%dH',0	;CM String
	DB	esc,'[K',0		;CE String
	DB	esc,'[7m',0		;SO String
	DB	esc,'[m',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'ADDS Consul 980 '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',80h,'K'-'@','@',0		;CL String
	DB	'K'-'@','%+@',esc,'E'-'@','%2',0	;CM String
	DB	0			;CE String
	DB	'Y'-'@',1eh,'N'-'@',0	;SO String
	DB	'O'-'@',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'ADDS Regent 20  '	;Name of Terminal
	DB	'Z'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'F'-'@'			;Cursor RIGHT
	DB	'U'-'@'			;Cursor LEFT
	DB	0			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'K',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'ADDS Viewpoint  '	;Name of Terminal
	DB	'Z'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'F'-'@'			;Cursor RIGHT
	DB	'U'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'K',0		;CE String
	DB	'N'-'@',0		;SO String
	DB	'O'-'@',0		;SE String
	DB	esc,'0A',0		;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'ADM 2           '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	0			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,';',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'ADM 31          '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	0			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'*',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	esc,'G1',0		;SO String
	DB	esc,'G0',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'ADM 3A          '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	01			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	0			;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'ADM 42          '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,';',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	esc,'G4',0		;SO String
	DB	esc,'G0',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Bantam 550      '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	20			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'K',0		;CL String
	DB	esc,'X%+ ',esc,'Y%+ ',0	;CM String
	DB	esc,'I',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'CDC 456         '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Y'-'@','X'-'@',0	;CL String
	DB	esc,'1%+ %+ ',0		;CM String
	DB	'V'-'@',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Concept 100     '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	16			;CE Delay
	DB	'L'-'@','L'-'@',0	;CL String
	DB	esc,'a','%+ %+ ',0	;CM String
	DB	esc,'U'-'@',0		;CE String
	DB	esc,'E',esc,'D',0	;SO String
	DB	esc,'d',esc,'e',0	;SE String
	DB	esc,'U',esc,'v  8p',esc,'p',0dh,0	;TI String
	DB	esc,'v    ',80h,80h,80h,80h,80h,80h
	DB	esc,'p',0dh,0ah,0	;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Concept 108     '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	16			;CE Delay
	DB	esc,'?',esc,'E'-'@',0	;CL String
	DB	esc,'a','%+ %+ ',0	;CM String
	DB	esc,'S'-'@',0		;CE String
	DB	esc,'D',0		;SO String
	DB	esc,'d',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'CT82            '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	'%r','K'-'@','%.%.',0	;CM String
	DB	'F'-'@',0		;CE String
	DB	1eh,'V'-'@',0		;SO String
	DB	1eh,'F'-'@',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'DEC VT52        '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'H',esc,'J',0	;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'K',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'DEC VT100       '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	50			;CL Delay
	DB	05			;CM Delay
	DB	03			;CE Delay
	DB	esc,'[;H',esc,'[2J',0	;CL String
	DB	esc,'[%i%d;%dH',0	;CM String
	DB	esc,'[K',0		;CE String
	DB	esc,'[7m',0		;SO String
	DB	esc,'[m',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Dialogue 80     '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	75			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'*',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'t',0		;CE String
	DB	esc,'j',0		;SO String
	DB	esc,'k',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Direct 800/A    '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'[1;1H',esc,'[2J',0	;CL String
	DB	esc,'[%i%d;%dH',0	;CM String
	DB	esc,'[K',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Epson GENEVA    '	;Name of Terminal
	DB	00			;Cursor UP
	DB	00			;Cursor DOWN
	DB	00			;Cursor RIGHT
	DB	00			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'*',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Epson QX-10     '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	esc,')',0		;SO String
	DB	esc,'(',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'General Trm 100A'	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	esc,'f%r%+ %+ ',0	;CM String
	DB	esc,'K',0		;CE String
	DB	esc,'b',0		;SO String
	DB	esc,'a',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Hazeltine 1420  '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,1ch,0		;CL String
	DB	esc,'Q'-'@','%r%.%+ ',0	;CM String
	DB	esc,'O'-'@',0		;CE String
	DB	esc,1fh,0		;SO String
	DB	esc,'Y'-'@',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Hazeltine 1500  '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'~',1ch,0		;CL String
	DB	'~','Q'-'@','%r%.%+ ',0	;CM String (correct - not same
	DB	'~','O'-'@',0		;CE String  as UNIX TERMCAP entry)
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Hazeltine 1510  '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,1ch,0		;CL String
	DB	esc,'Q'-'@','%r%.%+ ',0	;CM String (correct?)
	DB	esc,'O'-'@',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Hazeltine 1520  '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'~',1ch,0		;CL String
	DB	'~','Q'-'@','%r%.%+ ',80h,0	;CM String (correct?)
	DB	'~','O'-'@',0		;CE String
	DB	'~',1fh,0		;SO String
	DB	'~','Y'-'@',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'H19 (ANSI Mode) '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'[2J',0		;CL String
	DB	esc,'[%d;%dH',0		;CM String
	DB	esc,'[K',0		;CE String
	DB	esc,'[7m',0		;SO String
	DB	esc,'[m',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'H19 (Heath Mode)'	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'E',0		;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'K',0		;CE String
	DB	esc,'p',0		;SO String
	DB	esc,'q',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'HP 2621         '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'H',esc,'J',0	;CL String
	DB	esc,'&a%r%dc%dY',0	;CM String
	DB	0			;CE String
	DB	esc,'&dD',0		;SO String
	DB	esc,'&d@',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'IBM 3101        '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'K',0		;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'I',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Kaypro II       '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	0			;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Kaypro 10       '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	'X'-'@',0		;CE String
	DB	esc,'B1',0		;SO String
	DB	esc,'C1',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Micro Bee       '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'E',0		;CL String
	DB	esc,'F%+ %+ ',0		;CM String
	DB	esc,'K',0		;CE String
	DB	esc,'dP',0		;SO String
	DB	esc,'d@',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Microterm ACT IV'	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	'T'-'@','%.%.',0	;CM String
	DB	1eh,0			;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Microterm ACT V '	;Name of Terminal
	DB	'Z'-'@'			;Cursor UP
	DB	'K'-'@'			;Cursor DOWN
	DB	'X'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	'T'-'@','%.%.',0	;CM String
	DB	1eh,0			;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'NorthStar Advant'	;Name of Terminal
	DB	'B'-'@'+80h		;Cursor UP
	DB	'J'-'@'+80h		;Cursor DOWN
	DB	'F'-'@'+80h		;Cursor RIGHT
	DB	'H'-'@'+80h		;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	1EH,0FH,0		;CL String
	DB	ESC,'=%+ %+ ',0		;CM String
	DB	0EH,0			;CE String
	DB	1,0			;SO String
	DB	2,0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Osborne I       '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	esc,')',0		;SO String
	DB	esc,'(',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'P Elmer 1100    '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	132			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'H',esc,'J',0	;CL String
	DB	esc,'X%+ ',esc,'Y%+ ',0	;CM String
	DB	esc,'I',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'P Elmer 1200    '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	132			;CL Delay
	DB	00			;CM Delay
	DB	06			;CE Delay
	DB	esc,'H',esc,'J',0	;CL String
	DB	esc,'X%+ ',esc,'Y%+ ',0	;CM String
	DB	esc,'I',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Qume QVT 102    '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	esc,'(',0		;SO String
	DB	esc,')',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'SOROC 120       '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	02			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'*',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Super Bee       '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	03			;CL Delay
	DB	00			;CM Delay
	DB	03			;CE Delay
	DB	esc,'H',esc,'J',0	;CL String
	DB	esc,'F%r%3%3',0		;CM String
	DB	esc,'K',0		;CE String
	DB	esc,'_1',0		;SO String
	DB	esc,'_0',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'TAB 132         '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	50			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'[;H',esc,'[2J',0	;CL String
	DB	esc,'[%i%d;%dH',0	;CM String
	DB	0			;CE String
	DB	esc,'[7m',0		;SO String
	DB	esc,'[m',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Teleray 1061    '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	01			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'K',0		;CE String
	DB	esc,'RD',0		;SO String
	DB	esc,'R@',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Teleray 3800    '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'K',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'TTY 4424        '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'[2;H',esc,'[J',0	;CL String
	DB	esc,'[%i%2;%2H',esc,'[B',0	;CM String
	DB	esc,'[K',0		;CE String
	DB	esc,'[7m',0		;SO String
	DB	esc,'[m',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'TVI 912         '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	esc,')',0		;SO String
	DB	esc,'(',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'TVI 920         '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'Z'-'@',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'T',0		;CE String
	DB	esc,')',0		;SO String
	DB	esc,'(',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'TVI 950         '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'V'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'*',0		;CL String
	DB	esc,'=%+ %+ ',0		;CM String
	DB	esc,'t',0		;CE String
	DB	esc,')',0		;SO String
	DB	esc,'(',0		;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'TVI 970         '	;Name of Terminal
	DB	0			;Cursor UP
	DB	0			;Cursor DOWN
	DB	0			;Cursor RIGHT
	DB	0			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'[2J',0		;CL String
	DB	esc,'[%2;%2H',0		;CM String
	DB	esc,'[0K',0		;CE String
	DB	esc,'[2;7m',0		;SO String
	DB	esc,'[7;0m',0		;SE String
	DB	esc,'[0;0z',0		;TI String
	DB	esc,'[0;1z',0		;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'VC 404          '	;Name of Terminal
	DB	'Z'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'U'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	40			;CL Delay
	DB	00			;CM Delay
	DB	20			;CE Delay
	DB	'X'-'@',0		;CL String
	DB	'P'-'@','%+ %+ ',0	;CM String
	DB	'V'-'@',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'VC 415          '	;Name of Terminal
	DB	'Z'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'U'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	'L'-'@',0		;CL String
	DB	'P'-'@','%.%.',0	;CM String
	DB	'V'-'@',0		;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'Visual 200      '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'v',0		;CL String
	DB	esc,'Y%+ %+ ',0		;CM String
	DB	esc,'x'			;CE String (4 times)
	DB	esc,'x'
	DB	esc,'x'
	DB	esc,'x'
	DB	0			;End of CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String
; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	'WYSE 50         '	;Name of Terminal
	DB	'K'-'@'			;Cursor UP
	DB	'J'-'@'			;Cursor DOWN
	DB	'L'-'@'			;Cursor RIGHT
	DB	'H'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	esc,'+',0		;CL String
	DB	esc,'%ia%dR%dC',0	;CM String
	DB	esc,'T',0		;CE String
	DB	esc,')',0		;SO String
	DB	esc,'(',0		;SE String
	DB	0			;TI String
	DB	0			;TE String

; Terminal xxxx
	ORG	$/80H*80H+80H		;Next Record
	DB	' 1.3            '	;Name of Terminal
	DB	'E'-'@'			;Cursor UP (Wordstar Defaults)
	DB	'X'-'@'			;Cursor DOWN
	DB	'D'-'@'			;Cursor RIGHT
	DB	'S'-'@'			;Cursor LEFT
	DB	00			;CL Delay
	DB	00			;CM Delay
	DB	00			;CE Delay
	DB	0			;CL String
	DB	0			;CM String
	DB	0			;CE String
	DB	0			;SO String
	DB	0			;SE String
	DB	0			;TI String
	DB	0			;TE String

	END
