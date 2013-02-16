	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	cache_,17
	PUBLIC cnamept4_
cnamept4_:	lxi d,.2
	call csave
	LXI H,.1+0
	PUSH H
	LXI H,cache_
	PUSH H
	CALL strcpy_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,24
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,3
	POP D
	CALL .eq
	JZ .3
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,63
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,cache_
	PUSH H
	LXI H,.1+17
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+41
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,65
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .4
.6:
	LXI H,.1+61
	PUSH H
	CALL printf_
	POP D
	JMP .5
.7:
	LXI H,.1+66
	PUSH H
	CALL printf_
	POP D
	JMP .5
.8:
	LXI H,.1+72
	PUSH H
	CALL printf_
	POP D
	JMP .5
.4:
	CALL .swt
	DW 2
	DW 0,.7
	DW 1,.6
	DW .8
.5:
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+82
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,66
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .9
.11:
	LXI H,.1+102
	PUSH H
	CALL printf_
	POP D
	JMP .10
.12:
	LXI H,.1+107
	PUSH H
	CALL printf_
	POP D
	JMP .10
.13:
	LXI H,.1+113
	PUSH H
	CALL printf_
	POP D
	JMP .10
.9:
	CALL .swt
	DW 2
	DW 0,.12
	DW 1,.11
	DW .13
.10:
	CALL pager_
.3:
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,67
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,cache_
	PUSH H
	LXI H,.1+123
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+149
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,68
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .14
.16:
	LXI H,.1+169
	PUSH H
	CALL printf_
	POP D
	JMP .15
.17:
	LXI H,.1+178
	PUSH H
	CALL printf_
	POP D
	JMP .15
.18:
	LXI H,.1+188
	PUSH H
	CALL printf_
	POP D
	JMP .15
.19:
	LXI H,.1+198
	PUSH H
	CALL printf_
	POP D
	JMP .15
.20:
	LXI H,.1+208
	PUSH H
	CALL printf_
	POP D
	JMP .15
.14:
	CALL .swt
	DW 4
	DW 0,.16
	DW 1,.17
	DW 2,.18
	DW 3,.19
	DW .20
.15:
	CALL pager_
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,69
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,cache_
	PUSH H
	LXI H,.1+218
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+240
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,84
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .21
.23:
	LXI H,.1+260
	PUSH H
	CALL printf_
	POP D
	JMP .22
.24:
	LXI H,.1+265
	PUSH H
	CALL printf_
	POP D
	JMP .22
.25:
	LXI H,.1+271
	PUSH H
	CALL printf_
	POP D
	JMP .22
.21:
	CALL .swt
	DW 2
	DW 0,.24
	DW 1,.23
	DW .25
.22:
	CALL pager_
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,84
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,1
	POP D
	CALL .eq
	JZ .26
	LXI H,.1+281
	PUSH H
	CALL printf_
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,71
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .27
.29:
	LXI H,.1+301
	PUSH H
	CALL printf_
	POP D
	JMP .28
.30:
	LXI H,.1+306
	PUSH H
	CALL printf_
	POP D
	JMP .28
.31:
	LXI H,.1+312
	PUSH H
	CALL printf_
	POP D
	JMP .28
.27:
	CALL .swt
	DW 2
	DW 0,.30
	DW 1,.29
	DW .31
.28:
	CALL pager_
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,71
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,1
	POP D
	CALL .eq
	JZ .32
	LXI H,cache_
	PUSH H
	LXI H,.1+322
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,72
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .33
.35:
	LXI H,.1+342
	PUSH H
	CALL printf_
	POP D
	JMP .34
.36:
	LXI H,.1+349
	PUSH H
	CALL printf_
	POP D
	JMP .34
.37:
	LXI H,.1+356
	PUSH H
	CALL printf_
	POP D
	JMP .34
.38:
	LXI H,.1+367
	PUSH H
	CALL printf_
	POP D
	JMP .34
.33:
	CALL .swt
	DW 3
	DW 0,.35
	DW 1,.36
	DW 2,.37
	DW .38
.34:
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+377
	PUSH H
	CALL printf_
	POP D
	POP D
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+397
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,75
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .39
.41:
	LXI H,.1+417
	PUSH H
	CALL printf_
	POP D
	JMP .40
.42:
	LXI H,.1+422
	PUSH H
	CALL printf_
	POP D
	JMP .40
.43:
	LXI H,.1+428
	PUSH H
	CALL printf_
	POP D
	JMP .40
.39:
	CALL .swt
	DW 2
	DW 0,.42
	DW 1,.41
	DW .43
.40:
	CALL pager_
.32:
.26:
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,76
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,cache_
	PUSH H
	LXI H,.1+438
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+460
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,78
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .44
.46:
	LXI H,.1+480
	PUSH H
	CALL printf_
	POP D
	JMP .45
.47:
	LXI H,.1+485
	PUSH H
	CALL printf_
	POP D
	JMP .45
.48:
	LXI H,.1+491
	PUSH H
	CALL printf_
	POP D
	JMP .45
.44:
	CALL .swt
	DW 2
	DW 0,.47
	DW 1,.46
	DW .48
.45:
	CALL pager_
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,78
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,1
	POP D
	CALL .eq
	JZ .49
	LXI H,cache_
	PUSH H
	LXI H,.1+501
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,79
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .50
.52:
	LXI H,.1+520
	PUSH H
	CALL printf_
	POP D
	JMP .51
.53:
	LXI H,.1+525
	PUSH H
	CALL printf_
	POP D
	JMP .51
.54:
	LXI H,.1+531
	PUSH H
	CALL printf_
	POP D
	JMP .51
.50:
	CALL .swt
	DW 2
	DW 0,.53
	DW 1,.52
	DW .54
.51:
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+541
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,80
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .55
.57:
	LXI H,.1+561
	PUSH H
	CALL printf_
	POP D
	JMP .56
.58:
	LXI H,.1+568
	PUSH H
	CALL printf_
	POP D
	JMP .56
.59:
	LXI H,.1+575
	PUSH H
	CALL printf_
	POP D
	JMP .56
.60:
	LXI H,.1+586
	PUSH H
	CALL printf_
	POP D
	JMP .56
.55:
	CALL .swt
	DW 3
	DW 0,.57
	DW 1,.58
	DW 2,.59
	DW .60
.56:
	CALL pager_
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,73
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,cache_
	PUSH H
	LXI H,.1+596
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	CALL pager_
	LXI H,cache_
	PUSH H
	LXI H,.1+618
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,83
	DAD D
	MOV E,M
	MVI	D,0
	XCHG
	JMP .61
.63:
	LXI H,.1+638
	PUSH H
	CALL printf_
	POP D
	JMP .62
.64:
	LXI H,.1+643
	PUSH H
	CALL printf_
	POP D
	JMP .62
.65:
	LXI H,.1+649
	PUSH H
	CALL printf_
	POP D
	JMP .62
.61:
	CALL .swt
	DW 2
	DW 0,.64
	DW 1,.63
	DW .65
.62:
	CALL pager_
.49:
	RET
.2 EQU 0
.1:
	DB 115,121,115,99,102,103,45,62,99,110,102,103,100,97,116
	DB 97,0,37,115,46,115,100,99,97,112,97,99,105,116,121
	DB 32,32,32,32,61,32,37,117,75,66,0,37,115,46,115
	DB 100,99,115,105,111,32,32,32,32,32,32,32,32,61,32
	DB 0,84,82,85,69,0,70,65,76,83,69,0,85,110,107
	DB 110,111,119,110,33,33,0,37,115,46,115,100,99,115,105
	DB 111,102,97,115,116,32,32,32,32,61,32,0,84,82,85
	DB 69,0,70,65,76,83,69,0,85,110,107,110,111,119,110
	DB 33,33,0,37,115,46,100,101,102,105,111,98,121,116,101
	DB 32,32,32,32,32,61,32,48,120,37,48,50,120,0,37
	DB 115,46,116,101,114,109,116,121,112,101,32,32,32,32,32
	DB 32,61,32,0,84,69,82,77,95,84,84,89,0,84,69
	DB 82,77,95,65,78,83,73,0,84,69,82,77,95,87,89
	DB 83,69,0,84,69,82,77,95,86,84,53,50,0,85,110
	DB 107,110,111,119,110,33,33,0,37,115,46,114,101,118,105
	DB 115,105,111,110,32,32,32,32,32,32,61,32,37,100,0
	DB 37,115,46,112,114,112,101,110,97,98,108,101,32,32,32
	DB 32,32,61,32,0,84,82,85,69,0,70,65,76,83,69
	DB 0,85,110,107,110,111,119,110,33,33,0,37,115,46,112
	DB 114,112,115,100,101,110,97,98,108,101,32,32,32,61,32
	DB 0,84,82,85,69,0,70,65,76,83,69,0,85,110,107
	DB 110,111,119,110,33,33,0,37,115,46,112,114,112,115,100
	DB 116,114,97,99,101,32,32,32,32,61,32,0,83,73,76
	DB 69,78,84,0,69,82,82,79,82,83,0,69,86,69,82
	DB 89,84,72,73,78,71,0,85,110,107,110,111,119,110,33
	DB 33,0,37,115,46,112,114,112,115,100,99,97,112,97,99
	DB 105,116,121,32,61,32,0,37,115,46,112,114,112,99,111
	DB 110,101,110,97,98,108,101,32,32,61,32,0,84,82,85
	DB 69,0,70,65,76,83,69,0,85,110,107,110,111,119,110
	DB 33,33,0,37,115,46,98,105,111,115,115,105,122,101,32
	DB 32,32,32,32,32,61,32,37,100,0,37,115,46,112,112
	DB 112,101,110,97,98,108,101,32,32,32,32,32,61,32,0
	DB 84,82,85,69,0,70,65,76,83,69,0,85,110,107,110
	DB 111,119,110,33,33,0,37,115,46,112,112,112,115,100,101
	DB 110,97,98,108,101,32,32,61,32,0,84,82,85,69,0
	DB 70,65,76,83,69,0,85,110,107,110,111,119,110,33,33
	DB 0,37,115,46,112,112,112,115,100,116,114,97,99,101,32
	DB 32,32,32,61,32,0,83,73,76,69,78,84,0,69,82
	DB 82,79,82,83,0,69,86,69,82,89,84,72,73,78,71
	DB 0,85,110,107,110,111,119,110,33,33,0,37,115,46,112
	DB 112,112,99,97,112,97,99,105,116,121,32,32,32,61,32
	DB 37,100,0,37,115,46,112,112,112,99,111,110,101,110,97
	DB 98,108,101,32,32,61,32,0,84,82,85,69,0,70,65
	DB 76,83,69,0,85,110,107,110,111,119,110,33,33,0
	extrn	printf_
	extrn	strcpy_
	extrn	pager_
	extrn	.eq
	END
