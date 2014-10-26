CON
	_xinfreq		= 5_000_000			' Quartz is 5MHz
	_clkmode		= xtal1 + pll16x		' System clock is 80MHz

#define DracBladeProp

	CHAR_W			= 80
	CHAR_H			= 30

OBJ
'	vga	: "vga8x8d"
	vga	: "vgacolour"
	vt100	: "vt100"

VAR
	long	params[6]
	long	seed	

PUB main
	vga.start(16, @screen, @cursor, @sync)
	params[0] := @command
	params[1] := @screen
	params[2] := @cursor
	params[3] := @sync
	params[4] := CHAR_W
	params[5] := CHAR_H

	vt100.start(@params)

	seed := cnt

	str(string(27,"[2;34m",27,"[2J",27,"[H","Hello World!",13,10))
	str(string(27,"[7m","Inverse on",13,10))
	str(string(27,"[27m","Inverse off",13,10))
	str(string(27,"[1m","Highlite on",13,10))
	str(string(27,"[2m","Highlite off",13,10))
	str(string(27,"[4m","Underline on ",27,"[1m + highlite ",27,"[2m",27,"[7m + inverse ",27,"[0m all off + default color.",13,10))
	str(string(27,"[40m","BGD 0"))
	str(string(27,"[41m","BGD 1"))
	str(string(27,"[42m","BGD 2"))
	str(string(27,"[43m","BGD 3"))
	str(string(27,"[44m","BGD 4"))
	str(string(27,"[45m","BGD 5"))
	str(string(27,"[46m","BGD 6"))
	str(string(27,"[47m","BGD 7",13,10))

	str(string(27,"[41m"))

	str(string(27,"[30m","FGD 0"))
	str(string(27,"[31m","FGD 1"))
	str(string(27,"[32m","FGD 2"))
	str(string(27,"[33m","FGD 3"))
	str(string(27,"[34m","FGD 4"))
	str(string(27,"[35m","FGD 5"))
	str(string(27,"[36m","FGD 6"))
	str(string(27,"[37m","FGD 7",13,10))
	str(string(27,"[1;40m"))
	str(string(27,"[30m","FGD 0"))
	str(string(27,"[31m","FGD 1"))
	str(string(27,"[32m","FGD 2"))
	str(string(27,"[33m","FGD 3"))
	str(string(27,"[34m","FGD 4"))
	str(string(27,"[35m","FGD 5"))
	str(string(27,"[36m","FGD 6"))
	str(string(27,"[37m","FGD 7",13,10))
	str(string(27,"[2m","The quick brown fox jumps over the lazy dog.", 13, 10))

	str(string("Setting a scroll range below here.",13,10))
	str(string(27,"[24H","This part of the screen remains ",27,"[4mstatic",27,"[24m, since it is below the scrolling region."))
	str(string(27,"[12;23r",27,"[41m"))
	repeat
		chr(27)
		chr("[")
		chr("3")
		chr("0" + rand & 7)
		chr("m")
		chr(27)
		chr("[")
		chr("4")
		chr("0" + rand & 7)
		chr("m")
		str(string("Four score and seven years ago our ",27,"[1mfathers",27,"[2m brought forth, upon this continent, a new ",27,"[1mnation",27,"[2m, conceived in Liberty, and dedicated to the proposition that all men are created equal.   "))
		waitcnt(clkfreq/4 + cnt)


PUB chr(ch)
	command := $100 | ch
	repeat while command

PUB str(strptr) | i
	repeat i from 0 to strsize(strptr)
		chr(byte[strptr][i])

PUB rand
	seed := seed * 1103515245 + 12345 + CNT / 7777
	return seed

DAT
command		long	0
screen		word	$0720[CHAR_W*CHAR_H]
cursor		byte	0,0,%110,0,0,0,0,0
sync		long	0
