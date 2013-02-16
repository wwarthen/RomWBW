	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC memcmp_
memcmp_:	lxi d,.2
	call csave
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,2-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,10-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,0-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,-2-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .4
.3:
	LXI H,-2-.2
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
.4:
	LXI H,-2-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,12-.2
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .5
	LXI H,0-.2
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
	XCHG
	DCX H
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,4-.2
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
	XCHG
	DCX H
	MOV E,M
	MVI	D,0
	POP H
	CALL .ne
	JZ .6
	LXI H,0
	RET
.6:
	JMP .3
.5:
	LXI H,1
	RET
.2 EQU -6
	PUBLIC memcpy_
memcpy_:	lxi d,.7
	call csave
	LXI H,10-.7
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,2-.7
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,8-.7
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,0-.7
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,-2-.7
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .9
.8:
	LXI H,-2-.7
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
.9:
	LXI H,-2-.7
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,12-.7
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .10
	LXI H,2-.7
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
	XCHG
	DCX H
	MOV E,M
	PUSH D
	LXI H,2-.7
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
	XCHG
	DCX H
	POP D
	MOV M,E
	JMP .8
.10:
	RET
.7 EQU -6
	PUBLIC memset_
memset_:	lxi d,.11
	call csave
	LXI H,8-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,2-.11
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,0-.11
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .13
.12:
	LXI H,0-.11
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
.13:
	LXI H,0-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,12-.11
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .ul
	JZ .14
	LXI H,10-.11
	DAD SP
	MOV E,M
	PUSH D
	LXI H,4-.11
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
	XCHG
	DCX H
	POP D
	MOV M,E
	JMP .12
.14:
	RET
.11 EQU -4
	extrn	.ne
	extrn	.lt
	extrn	.ul
	END
