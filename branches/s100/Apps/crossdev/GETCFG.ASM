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
	PUBLIC main_
main_:	lxi d,.2
	call csave
	LXI H,-4096
	SHLD hregbc_
	LXI H,-16384
	SHLD hregde_
	CALL diagnose_
	LHLD pSYSCFG_
	LXI D,68
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD pSYSCFG_
	LXI D,68
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	CALL crtinit_
	POP D
	CALL crtclr_
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LHLD pBIOS_
	LXI D,78
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LHLD pBIOS_
	LXI D,77
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LHLD pBIOS_
	LXI D,76
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LHLD pBIOS_
	LXI D,75
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,2012
	PUSH H
	LXI H,23
	PUSH H
	LXI H,7
	PUSH H
	LXI H,.1+10
	PUSH H
	CALL printf_
	XCHG
	LXI H,16
	DAD SP
	SPHL
	LXI H,.1+93
	PUSH H
	LXI H,.1+82
	PUSH H
	CALL fopen_
	POP D
	POP D
	XCHG
	LXI H,2-.2
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,2-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,256
	PUSH H
	LXI H,1
	PUSH H
	LXI H,-16384
	PUSH H
	CALL fwrite_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LXI H,2-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL fclose_
	POP D
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,-6596
	PUSH H
	CALL asmif_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD xreghl_
	SHLD pINFOLIS_
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,25
	PUSH H
	LXI H,5
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
	LDA xrega_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,-6629
	PUSH H
	CALL asmif_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD xreghl_
	SHLD pDPH_
	LHLD pDPH_
	LXI D,10
	DAD D
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD pDPB_
	RET
.2 EQU -2
.1:
	DB 84,84,32,105,115,32,37,100,10,0,71,69,84,67,70
	DB 71,46,67,79,77,32,37,100,47,37,100,47,37,100,32
	DB 37,100,46,37,100,46,37,100,46,37,100,32,100,119,103
	DB 32,45,32,69,108,101,103,97,110,116,108,121,32,69,120
	DB 112,114,101,115,115,101,100,32,67,80,47,77,32,80,114
	DB 111,103,114,97,109,10,0,115,121,115,99,102,103,46,98
	DB 105,110,0,119,0
	extrn	fclose_
	extrn	fwrite_
	extrn	printf_
	extrn	asmif_
	extrn	xreghl_
	extrn	xrega_
	extrn	diagnose_
	extrn	hregde_
	extrn	hregbc_
	extrn	crtlc_
	extrn	crtclr_
	extrn	crtinit_
	extrn	fopen_
	END
