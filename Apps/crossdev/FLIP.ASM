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
	LHLD hregbc_
	PUSH H
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,10-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD hregde_
	LHLD hregde_
	PUSH H
	LXI H,.1+17
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD hreghl_
	LHLD hreghl_
	PUSH H
	LXI H,.1+34
	PUSH H
	CALL printf_
	POP D
	POP D
	CALL diagnose_
	LDA hrega_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,.1+51
	PUSH H
	CALL printf_
	POP D
	POP D
	LDA hrega_
	MOV L,A
	MVI	H,0
	RET
.2 EQU 0
.1:
	DB 104,114,101,103,98,99,32,61,32,48,120,37,48,52,120
	DB 10,0,104,114,101,103,100,101,32,61,32,48,120,37,48
	DB 52,120,10,0,104,114,101,103,104,108,32,61,32,48,120
	DB 37,48,52,120,10,0,86,68,65,73,78,73,32,99,97
	DB 108,108,101,100,44,32,114,101,116,117,114,110,32,99,111
	DB 100,101,32,119,97,115,32,48,120,37,48,50,120,10,0
	PUBLIC bitlook_
bitlook_:	lxi d,.4
	call csave
	LXI H,-32768
	XCHG
	LXI H,2-.4
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,0-.4
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .6
.5:
	LXI H,0-.4
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
.6:
	LXI H,0-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,256
	CALL .lt
	JZ .7
	LXI H,0-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.3+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,-2-.4
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .9
.8:
	LXI H,-2-.4
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
	LXI H,-2-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,8
	CALL .lt
	JZ .10
	LXI H,2-.4
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
	LXI H,.3+16
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.10:
	LXI H,.3+24
	PUSH H
	CALL printf_
	POP D
	JMP .5
.7:
	RET
.4 EQU -6
.3:
	DB 97,115,99,105,105,32,61,32,48,120,37,48,50,120,32
	DB 0,48,120,37,48,50,120,32,0,10,0
	PUBLIC vdaqry_
vdaqry_:	lxi d,.12
	call csave
	LXI H,8-.12
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16640
	CALL .or
	SHLD hregbc_
	LHLD hregbc_
	PUSH H
	LXI H,.11+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,10-.12
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD hreghl_
	LHLD hreghl_
	LXI D,-32768
	CALL .ne
	JZ .13
	LXI H,.11+17
	PUSH H
	CALL printf_
	POP D
.13:
	CALL diagnose_
	LDA hrega_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,.11+43
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD hregbc_
	LXI D,255
	CALL .an
	PUSH H
	LXI H,.11+83
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD hregde_
	LXI D,8
	XCHG
	CALL .ur
	PUSH H
	LHLD hregde_
	LXI D,8
	XCHG
	CALL .ur
	PUSH H
	LXI H,.11+123
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	LHLD hregde_
	LXI D,255
	CALL .an
	PUSH H
	LHLD hregde_
	LXI D,255
	CALL .an
	PUSH H
	LXI H,.11+167
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	LDA hrega_
	MOV L,A
	MVI	H,0
	RET
.12 EQU 0
.11:
	DB 104,114,101,103,98,99,32,61,32,48,120,37,48,52,120
	DB 10,0,118,100,97,113,114,121,32,115,97,121,115,32,104
	DB 108,32,33,61,32,48,120,56,48,48,48,10,0,86,68
	DB 65,81,82,89,32,99,97,108,108,101,100,44,32,115,116
	DB 97,116,117,115,32,32,32,32,32,32,32,119,97,115,32
	DB 48,120,37,48,50,120,10,0,32,32,32,32,32,32,32
	DB 32,32,32,32,32,32,32,32,118,105,100,101,111,32,109
	DB 111,100,101,32,32,32,119,97,115,32,48,120,37,48,50
	DB 120,10,0,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,32,114,111,119,32,99,111,117,110,116,32,32,32
	DB 32,119,97,115,32,48,120,37,48,50,120,40,37,100,41
	DB 10,0,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,99,111,108,117,109,110,32,99,111,117,110,116,32
	DB 119,97,115,32,48,120,37,48,50,120,40,37,100,41,10
	DB 0
	PUBLIC main_
main_:	lxi d,.15
	call csave
	LXI H,.14+0
	PUSH H
	CALL printf_
	POP D
	LXI H,-32768
	PUSH H
	LXI H,64
	PUSH H
	CALL vdaqry_
	POP D
	POP D
	XCHG
	LXI H,-3-.15
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-32768
	XCHG
	LXI H,2-.15
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,-1-.15
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .17
.16:
	LXI H,-1-.15
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
.17:
	LXI H,-1-.15
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,2048
	CALL .lt
	JZ .18
	LXI H,2-.15
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	MOV E,M
	LXI H,1-.15
	DAD SP
	MOV M,E
	LXI H,1-.15
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,255
	CALL .xr
	XCHG
	LXI H,1-.15
	DAD SP
	MOV M,E
	LXI H,1-.15
	DAD SP
	MOV E,M
	PUSH D
	LXI H,4-.15
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	POP D
	MOV M,E
	LXI H,2-.15
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
	JMP .16
.18:
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
.15 EQU -7
.14:
	DB 102,108,105,112,46,99,111,109,40,99,41,32,49,49,47
	DB 49,53,47,50,48,49,50,32,100,119,103,32,45,32,10
	DB 10,0
	extrn	printf_
	extrn	diagnose_
	extrn	hreghl_
	extrn	hregde_
	extrn	hregbc_
	extrn	hrega_
	extrn	.or
	extrn	.xr
	extrn	.an
	extrn	.ne
	extrn	.lt
	extrn	.ur
	END
