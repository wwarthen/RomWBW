	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC main_
main_:	lxi d,.2
	call csave
	LXI H,0
	XCHG
	LXI H,8-.2
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .3
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
.3:
	LXI H,1
	XCHG
	LXI H,8-.2
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .4
	LXI H,.1+7
	PUSH H
	CALL printf_
	POP D
.4:
	LXI H,2
	XCHG
	LXI H,8-.2
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .5
	LXI H,.1+14
	PUSH H
	CALL printf_
	POP D
.5:
	RET
.2 EQU 0
.1:
	DB 97,114,103,99,62,48,0,97,114,103,99,62,49,0,97
	DB 114,103,99,62,50,0
	extrn	printf_
	extrn	.lt
	END
