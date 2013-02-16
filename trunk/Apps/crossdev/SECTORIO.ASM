	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC rdsector_
rdsector_:	lxi d,.2
	call csave
	LXI H,-6629
	SHLD ireghl_
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	LXI H,0
	SHLD iregde_
	CALL bioscall_
	LXI H,-6626
	SHLD ireghl_
	LXI H,10-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	CALL bioscall_
	LXI H,-6623
	SHLD ireghl_
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	CALL bioscall_
	LXI H,-6620
	SHLD ireghl_
	LXI H,14-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	CALL bioscall_
	LXI H,-6617
	SHLD ireghl_
	CALL bioscall_
	LDA irega_
	MOV L,A
	MVI	H,0
	RET
.2 EQU 0
	PUBLIC wrsector_
wrsector_:	lxi d,.3
	call csave
	LXI H,-6629
	SHLD ireghl_
	LXI H,8-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	LXI H,0
	SHLD iregde_
	CALL bioscall_
	LXI H,-6626
	SHLD ireghl_
	LXI H,10-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	CALL bioscall_
	LXI H,-6623
	SHLD ireghl_
	LXI H,12-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	CALL bioscall_
	LXI H,-6620
	SHLD ireghl_
	LXI H,14-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	CALL bioscall_
	LXI H,-6614
	SHLD ireghl_
	LXI H,0
	SHLD iregbc_
	CALL bioscall_
	LDA irega_
	MOV L,A
	MVI	H,0
	RET
.3 EQU 0
	extrn	bioscall_
	extrn	ireghl_
	extrn	iregde_
	extrn	iregbc_
	extrn	irega_
	END
