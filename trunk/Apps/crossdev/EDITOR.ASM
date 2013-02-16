	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC vdaini_
vdaini_:	lxi d,.2
	call csave
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16384
	CALL .or
	SHLD hregbc_
	LXI H,10-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD hregde_
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD hreghl_
	CALL diagnose_
	LDA hrega_
	MOV L,A
	MVI	H,0
	RET
.2 EQU 0
	PUBLIC bitlook_
bitlook_:	lxi d,.3
	call csave
	LXI H,-32768
	XCHG
	LXI H,2-.3
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,0-.3
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .5
.4:
	LXI H,0-.3
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
.5:
	LXI H,0-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,256
	CALL .lt
	JZ .6
	LXI H,0-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,-2-.3
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .8
.7:
	LXI H,-2-.3
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
	LXI H,-2-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,8
	CALL .lt
	JZ .9
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
	XCHG
	DCX H
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,.1+16
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .7
.9:
	LXI H,.1+24
	PUSH H
	CALL printf_
	POP D
	JMP .4
.6:
	RET
.3 EQU -6
.1:
	DB 97,115,99,105,105,32,61,32,48,120,37,48,50,120,32
	DB 0,48,120,37,48,50,120,32,0,10,0
	PUBLIC vdaqry_
vdaqry_:	lxi d,.11
	call csave
	LXI H,8-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16640
	CALL .or
	SHLD hregbc_
	LXI H,10-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD hreghl_
	CALL diagnose_
	LDA hrega_
	MOV L,A
	MVI	H,0
	RET
.11 EQU 0
	PUBLIC flip_
flip_:	lxi d,.12
	call csave
	LXI H,-32768
	PUSH H
	LXI H,64
	PUSH H
	CALL vdaqry_
	POP D
	POP D
	XCHG
	LXI H,-3-.12
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-32768
	XCHG
	LXI H,2-.12
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,-1-.12
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .14
.13:
	LXI H,-1-.12
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
.14:
	LXI H,-1-.12
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,2048
	CALL .lt
	JZ .15
	LXI H,2-.12
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	MOV E,M
	LXI H,1-.12
	DAD SP
	MOV M,E
	LXI H,1-.12
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,255
	CALL .xr
	XCHG
	LXI H,1-.12
	DAD SP
	MOV M,E
	LXI H,1-.12
	DAD SP
	MOV E,M
	PUSH D
	LXI H,4-.12
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	POP D
	MOV M,E
	LXI H,2-.12
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
	JMP .13
.15:
	LXI H,-32768
	PUSH H
	LXI H,0
	PUSH H
	LXI H,64
	PUSH H
	CALL vdaini_
	POP D
	POP D
	POP D
	RET
.12 EQU -7
	PUBLIC main_
main_:	lxi d,.16
	call csave
	LXI H,1
	XCHG
	LXI H,2-.16
	DAD SP
	MOV M,E
	INX H
	MOV M,D
.17:
	LXI H,1
	XCHG
	LXI H,2-.16
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .eq
	JZ .18
	LXI H,1
	SHLD dregbc_
	CALL bdoscall_
	LDA drega_
	MOV L,A
	MVI	H,0
	JMP .19
.21:
	CALL flip_
	JMP .20
.22:
	LXI H,0
	XCHG
	LXI H,2-.16
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .20
.23:
	LXI H,7
	PUSH H
	LXI H,.10+0
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .20
.19:
	CALL .swt
	DW 2
	DW 3,.22
	DW 102,.21
	DW .23
.20:
	JMP .17
.18:
	CALL flip_
	RET
.16 EQU -2
.10:
	DB 37,99,0
	extrn	printf_
	extrn	bdoscall_
	extrn	dregbc_
	extrn	drega_
	extrn	diagnose_
	extrn	hreghl_
	extrn	hregde_
	extrn	hregbc_
	extrn	hrega_
	extrn	.or
	extrn	.xr
	extrn	.eq
	extrn	.lt
	END
