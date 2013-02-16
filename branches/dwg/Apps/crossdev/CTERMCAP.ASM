	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	termtype_,1
	DSEG
	public	wy50row_
wy50row_:
	DB 32
	DB 33
	DB 34
	DB 35
	DB 36
	DB 37
	DB 38
	DB 39
	DB 40
	DB 41
	DB 42
	DB 43
	DB 44
	DB 45
	DB 46
	DB 47
	DB 48
	DB 49
	DB 50
	DB 51
	DB 52
	DB 53
	DB 54
	DB 55
	CSEG
	DSEG
	public	wy50col_
wy50col_:
	DB 32
	DB 33
	DB 34
	DB 35
	DB 36
	DB 37
	DB 38
	DB 39
	DB 40
	DB 41
	DB 42
	DB 43
	DB 44
	DB 45
	DB 46
	DB 47
	DB 48
	DB 49
	DB 50
	DB 51
	DB 52
	DB 53
	DB 54
	DB 55
	DB 56
	DB 57
	DB 58
	DB 59
	DB 60
	DB 61
	DB 62
	DB 63
	DB 64
	DB 65
	DB 66
	DB 67
	DB 68
	DB 69
	DB 70
	DB 71
	DB 72
	DB 73
	DB 74
	DB 75
	DB 76
	DB 77
	DB 78
	DB 79
	DB 80
	DB 81
	DB 82
	DB 83
	DB 84
	DB 85
	DB 86
	DB 87
	DB 88
	DB 89
	DB 90
	DB 91
	DB 92
	DB 93
	DB 94
	DB 95
	DB 96
	DB 97
	DB 98
	DB 99
	DB 100
	DB 101
	DB 102
	DB 103
	DB 104
	DB 105
	DB 106
	DB 107
	DB 108
	DB 109
	DB 110
	DB 111
	CSEG
	PUBLIC crtinit_
crtinit_:	lxi d,.2
	call csave
	LXI H,8-.2
	DAD SP
	MOV E,M
	XCHG
	MOV A,L
	STA termtype_
	RET
.2 EQU 0
	PUBLIC crtclr_
crtclr_:	lxi d,.3
	call csave
	LDA termtype_
	MOV L,A
	MVI	H,0
	JMP .4
.6:
	LXI H,0
	XCHG
	LXI H,2-.3
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .8
.7:
	LXI H,2-.3
	DAD SP
	PUSH H
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	INX H
	XCHG
	POP H
	MOV M,E
	INX H
	MOV M,D
.8:
	LXI H,2-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,43
	CALL .lt
	JZ .9
	LXI H,10
	PUSH H
	LXI H,13
	PUSH H
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	JMP .7
.9:
	JMP .5
.10:
	LXI H,27
	PUSH H
	LXI H,.1+5
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .5
.11:
	LXI H,27
	PUSH H
	LXI H,.1+11
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .5
.12:
	LXI H,27
	PUSH H
	LXI H,27
	PUSH H
	LXI H,.1+15
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	JMP .5
.4:
	CALL .swt
	DW 4
	DW 0,.6
	DW 1,.10
	DW 2,.11
	DW 3,.12
	DW .5
.5:
	RET
.3 EQU -2
.1:
	DB 37,99,37,99,0,37,99,91,50,74,0,37,99,43,0
	DB 37,99,74,37,99,72,0
	PUBLIC crtlc_
crtlc_:	lxi d,.14
	call csave
	LDA termtype_
	MOV L,A
	MVI	H,0
	JMP .15
.17:
	JMP .16
.18:
	LXI H,102
	PUSH H
	LXI H,12-.14
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,12-.14
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,27
	PUSH H
	LXI H,.13+0
	PUSH H
	CALL printf_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	JMP .16
.19:
	LXI H,10-.14
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,wy50col_
	DAD D
	DCX H
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,10-.14
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,wy50row_
	DAD D
	DCX H
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,27
	PUSH H
	LXI H,.13+11
	PUSH H
	CALL printf_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	JMP .16
.20:
	LXI H,10-.14
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,32
	DAD D
	PUSH H
	LXI H,10-.14
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,32
	DAD D
	PUSH H
	LXI H,27
	PUSH H
	LXI H,.13+19
	PUSH H
	CALL printf_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	JMP .16
.15:
	CALL .swt
	DW 4
	DW 0,.17
	DW 1,.18
	DW 2,.19
	DW 3,.20
	DW .16
.16:
	RET
.14 EQU -2
.13:
	DB 37,99,91,37,100,59,37,100,37,99,0,37,99,61,37
	DB 99,37,99,0,37,99,89,37,99,37,99,0
	extrn	printf_
	extrn	.lt
	END
