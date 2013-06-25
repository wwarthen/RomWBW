	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC patch_
patch_:	lxi d,.2
	call csave
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,-6602
	PUSH H
	CALL asmif_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LDA xrega_
	MOV L,A
	MVI	H,0
	LXI D,1
	CALL .eq
	JZ .3
	LXI H,1
	RET
.3:
	LHLD xregbc_
	LXI D,8
	XCHG
	CALL .ur
	XCHG
	LXI H,3-.2
	DAD SP
	MOV M,E
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,9
	CALL .dv
	PUSH H
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LHLD xregbc_
	PUSH H
	LXI H,-6599
	PUSH H
	CALL asmif_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,-6629
	PUSH H
	CALL asmif_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD xreghl_
	MOV A,H
	ORA L
	JNZ .4
	LXI H,1
	RET
.4:
	LHLD xreghl_
	XCHG
	LXI H,1-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,1-.2
	DAD SP
	PUSH H
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DCX H
	XCHG
	POP H
	MOV M,E
	INX H
	MOV M,D
	LXI H,3-.2
	DAD SP
	MOV E,M
	MVI	D,0
	XCHG
	INX H
	PUSH H
	LXI H,3-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	POP D
	MOV M,E
	LXI H,0
	RET
.2 EQU -3
	PUBLIC main_
main_:	lxi d,.5
	call csave
	CALL crtinit_
	CALL crtclr_
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	CALL crtinit_
	POP D
	POP D
	LXI H,.1+0
	PUSH H
	CALL banner_
	POP D
	LXI H,.1+9
	PUSH H
	CALL printf_
	POP D
	LXI H,256
	PUSH H
	LXI H,0
	PUSH H
	LXI H,2
	PUSH H
	CALL patch_
	POP D
	POP D
	POP D
	JMP .6
.8:
	LXI H,.1+41
	PUSH H
	CALL printf_
	POP D
	JMP .7
.9:
	LXI H,7
	PUSH H
	LXI H,.1+53
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .7
.6:
	CALL .swt
	DW 2
	DW 0,.8
	DW 1,.9
	DW .7
.7:
	LXI H,.1+69
	PUSH H
	CALL printf_
	POP D
	LXI H,256
	PUSH H
	LXI H,1
	PUSH H
	LXI H,3
	PUSH H
	CALL patch_
	POP D
	POP D
	POP D
	JMP .10
.12:
	LXI H,.1+101
	PUSH H
	CALL printf_
	POP D
	JMP .11
.13:
	LXI H,7
	PUSH H
	LXI H,.1+113
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .11
.10:
	CALL .swt
	DW 2
	DW 0,.12
	DW 1,.13
	DW .11
.11:
	RET
.5 EQU 0
.1:
	DB 84,87,79,68,82,73,86,69,0,67,111,110,118,101,114
	DB 115,105,111,110,32,111,102,32,67,58,32,116,111,32,80
	DB 80,73,68,69,49,45,76,85,48,32,0,115,117,99,99
	DB 101,115,115,102,117,108,10,0,117,110,115,117,99,99,101
	DB 115,115,102,117,108,37,99,10,0,67,111,110,118,101,114
	DB 115,105,111,110,32,111,102,32,68,58,32,116,111,32,80
	DB 80,73,68,69,49,45,76,85,49,32,0,115,117,99,99
	DB 101,115,115,102,117,108,10,0,117,110,115,117,99,99,101
	DB 115,115,102,117,108,37,99,10,0
	extrn	printf_
	extrn	banner_
	extrn	crtclr_
	extrn	crtinit_
	extrn	asmif_
	extrn	xreghl_
	extrn	xregbc_
	extrn	xrega_
	extrn	.eq
	extrn	.ur
	extrn	.dv
	END
