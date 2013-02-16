	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC copyup_
copyup_:	lxi d,.2
	call csave
	LXI H,-32768
	XCHG
	LXI H,2-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,0-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .4
.3:
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
.4:
	LXI H,0-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,256
	CALL .lt
	JZ .5
	LXI H,0
	XCHG
	LXI H,-2-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .7
.6:
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
.7:
	LXI H,-2-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,8
	CALL .lt
	JZ .8
	LXI H,0-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	DAD H
	LXI D,7
	DAD D
	XCHG
	LXI H,-2-.2
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .sb
	LXI D,charset_
	DAD D
	MOV E,M
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
	POP D
	MOV M,E
	JMP .6
.8:
	JMP .3
.5:
	RET
.2 EQU -6
	PUBLIC main_
main_:	lxi d,.9
	call csave
	CALL copyup_
	LXI H,16448
	SHLD hregbc_
	LXI H,0
	SHLD hregde_
	LXI H,-32768
	SHLD hreghl_
	CALL diagnose_
	LXI H,17472
	SHLD hregbc_
	LXI H,3084
	SHLD hregde_
	CALL diagnose_
	LXI H,0
	XCHG
	LXI H,2-.9
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .11
.10:
	LXI H,2-.9
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
.11:
	LXI H,2-.9
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,600
	CALL .lt
	JZ .12
	LXI H,18240
	SHLD hregbc_
	LXI H,63
	SHLD hregde_
	CALL diagnose_
	JMP .10
.12:
	RET
.9 EQU -2
	extrn	charset_
	extrn	diagnose_
	extrn	hreghl_
	extrn	hregde_
	extrn	hregbc_
	extrn	.lt
	extrn	.sb
	END
