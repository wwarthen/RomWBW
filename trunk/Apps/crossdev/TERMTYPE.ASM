	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	DSEG
	public	pPriFcb_
pPriFcb_:
	DW 92
	CSEG
	DSEG
	public	pSecFcb_
pSecFcb_:
	DW 108
	CSEG
	DSEG
	public	pDefBuf_
pDefBuf_:
	DW 128
	CSEG
	DSEG
	public	pBIOS_
pBIOS_:
	DW -6656
	CSEG
	global	pDPB_,2
	global	pDPH_,2
	global	pINFOLIS_,2
	global	pCNFGDAT_,2
	DSEG
	public	pSYSCFG_
pSYSCFG_:
	DW -16384
	CSEG
	DSEG
	public	bRun_
bRun_:
	DB 1
	CSEG
	global	c_,1
	DSEG
	public	newtt_
newtt_:
	DB 255
	CSEG
	global	tt_,1
	global	i_,2
	PUBLIC main_
main_:	lxi d,.2
	call csave
	LXI H,-4096
	SHLD hregbc_
	LXI H,-16384
	SHLD hregde_
	CALL diagnose_
	LXI H,0
	SHLD i_
	JMP .4
.3:
	LHLD i_
	INX H
	SHLD i_
.4:
	LHLD i_
	LXI D,25
	XCHG
	CALL .lt
	JZ .5
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	JMP .3
.5:
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,3
	PUSH H
	LXI H,2
	PUSH H
	LXI H,2013
	PUSH H
	LXI H,16
	PUSH H
	LXI H,1
	PUSH H
	LXI H,.1+2
	PUSH H
	CALL printf_
	XCHG
	LXI H,16
	DAD SP
	SPHL
.6:
	LDA bRun_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,1
	POP D
	CALL .eq
	JZ .7
	LXI H,.1+72
	PUSH H
	CALL printf_
	POP D
	LHLD pSYSCFG_
	LXI D,68
	DAD D
	MOV E,M
	XCHG
	MOV A,L
	STA tt_
	LDA tt_
	MOV L,A
	MVI	H,0
	JMP .8
.10:
	LXI H,.1+95
	PUSH H
	CALL printf_
	POP D
	JMP .9
.11:
	LXI H,.1+143
	PUSH H
	CALL printf_
	POP D
	JMP .9
.12:
	LXI H,.1+191
	PUSH H
	CALL printf_
	POP D
	JMP .9
.13:
	LXI H,.1+239
	PUSH H
	CALL printf_
	POP D
	JMP .9
.14:
	LXI H,.1+287
	PUSH H
	CALL printf_
	POP D
	LXI H,.1+306
	PUSH H
	CALL printf_
	POP D
	JMP .9
.8:
	CALL .swt
	DW 4
	DW 0,.10
	DW 1,.11
	DW 2,.12
	DW 3,.13
	DW .14
.9:
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,1
	PUSH H
	LXI H,5
	PUSH H
	CALL asmif_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LDA xrega_
	MOV L,A
	MOV A,L
	STA c_
	LDA c_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,113
	POP D
	CALL .eq
	JZ .15
	LXI H,0
	MOV A,L
	STA bRun_
.15:
	LDA c_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,120
	POP D
	CALL .eq
	JZ .16
	LXI H,0
	MOV A,L
	STA bRun_
.16:
	LDA c_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,81
	POP D
	CALL .eq
	JZ .17
	LXI H,0
	MOV A,L
	STA bRun_
.17:
	LDA c_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,88
	POP D
	CALL .eq
	JZ .18
	LXI H,0
	MOV A,L
	STA bRun_
.18:
	LDA tt_
	MOV L,A
	MVI	H,0
	JMP .19
.21:
	LDA c_
	MOV L,A
	MVI	H,0
	JMP .22
.24:
.25:
	LXI H,1
	MOV A,L
	STA newtt_
	JMP .23
.26:
.27:
	LXI H,2
	MOV A,L
	STA newtt_
	JMP .23
.28:
.29:
	LXI H,3
	MOV A,L
	STA newtt_
	JMP .23
.22:
	CALL .swt
	DW 6
	DW 65,.25
	DW 86,.29
	DW 87,.27
	DW 97,.24
	DW 118,.28
	DW 119,.26
	DW .23
.23:
	JMP .20
.30:
	LDA c_
	MOV L,A
	MVI	H,0
	JMP .31
.33:
.34:
	LXI H,0
	MOV A,L
	STA newtt_
	JMP .32
.35:
.36:
	LXI H,2
	MOV A,L
	STA newtt_
	JMP .32
.37:
.38:
	LXI H,3
	MOV A,L
	STA newtt_
	JMP .32
.31:
	CALL .swt
	DW 6
	DW 84,.34
	DW 86,.38
	DW 87,.36
	DW 116,.33
	DW 118,.37
	DW 119,.35
	DW .32
.32:
	JMP .20
.39:
	LDA c_
	MOV L,A
	MVI	H,0
	JMP .40
.42:
.43:
	LXI H,0
	MOV A,L
	STA newtt_
	JMP .41
.44:
.45:
	LXI H,1
	MOV A,L
	STA newtt_
	JMP .41
.46:
.47:
	LXI H,3
	MOV A,L
	STA newtt_
	JMP .41
.40:
	CALL .swt
	DW 6
	DW 65,.45
	DW 84,.43
	DW 86,.47
	DW 97,.44
	DW 116,.42
	DW 118,.46
	DW .41
.41:
	JMP .20
.48:
	LDA c_
	MOV L,A
	MVI	H,0
	JMP .49
.51:
.52:
	LXI H,0
	MOV A,L
	STA newtt_
	JMP .50
.53:
.54:
	LXI H,1
	MOV A,L
	STA newtt_
	JMP .50
.55:
.56:
	LXI H,2
	MOV A,L
	STA newtt_
	JMP .50
.49:
	CALL .swt
	DW 6
	DW 65,.54
	DW 84,.52
	DW 87,.56
	DW 97,.53
	DW 116,.51
	DW 119,.55
	DW .50
.50:
	JMP .20
.57:
	LXI H,7
	PUSH H
	LXI H,.1+347
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .20
.19:
	CALL .swt
	DW 4
	DW 0,.21
	DW 1,.30
	DW 2,.39
	DW 3,.48
	DW .57
.20:
	LDA newtt_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,255
	POP D
	CALL .ne
	JZ .58
	LDA newtt_
	MOV L,A
	PUSH H
	LHLD pSYSCFG_
	LXI D,68
	DAD D
	POP D
	MOV M,E
	LXI H,-3840
	SHLD hregbc_
	LXI H,-16384
	SHLD hregde_
	CALL diagnose_
.58:
	JMP .6
.7:
	RET
.2 EQU 0
.1:
	DB 10,0,84,69,82,77,84,89,80,69,46,67,79,77,32
	DB 37,100,47,37,100,47,37,100,32,37,100,46,37,100,46
	DB 37,100,46,37,100,32,100,119,103,32,45,32,68,105,115
	DB 112,108,97,121,47,67,104,97,110,103,101,32,84,101,114
	DB 109,105,110,97,108,32,84,121,112,101,10,0,10,84,104
	DB 101,32,84,101,114,109,105,110,97,108,32,84,121,112,101
	DB 32,105,115,32,0,32,84,84,89,44,32,79,112,116,105
	DB 111,110,115,58,32,97,40,110,115,105,41,44,32,119,40
	DB 121,115,101,41,44,32,118,40,116,53,50,41,44,32,113
	DB 40,117,105,116,41,32,63,0,65,78,83,73,44,32,79
	DB 112,116,105,111,110,115,58,32,116,40,116,121,41,44,32
	DB 32,119,40,121,115,101,41,44,32,118,40,116,53,50,41
	DB 44,32,113,40,117,105,116,41,32,63,0,87,89,83,69
	DB 44,32,79,112,116,105,111,110,115,58,32,116,40,116,121
	DB 41,44,32,32,97,40,110,115,105,41,44,32,118,40,116
	DB 53,50,41,44,32,113,40,117,105,116,41,32,63,0,86
	DB 84,53,50,44,32,79,112,116,105,111,110,115,58,32,116
	DB 40,116,121,41,44,32,32,97,40,110,115,105,41,44,32
	DB 119,40,121,115,101,41,44,32,113,40,117,105,116,41,32
	DB 63,0,85,110,107,110,111,119,110,44,32,79,112,116,105
	DB 111,110,115,58,32,0,116,40,116,121,41,44,32,32,97
	DB 40,110,115,105,41,44,32,119,40,121,115,101,41,44,32
	DB 118,40,116,53,50,41,44,32,113,40,117,105,116,41,32
	DB 63,0,37,99,0
	extrn	printf_
	extrn	asmif_
	extrn	xrega_
	extrn	diagnose_
	extrn	hregde_
	extrn	hregbc_
	extrn	.eq
	extrn	.ne
	extrn	.lt
	END
