	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC lugcur_
lugcur_:	lxi d,.2
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
	LHLD xregde_
	RET
.2 EQU 0
	PUBLIC lugnum_
lugnum_:	lxi d,.3
	call csave
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,12-.3
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
	LHLD xreghl_
	RET
.3 EQU 0
	PUBLIC lugdu_
lugdu_:	lxi d,.4
	call csave
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,12-.4
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
	LHLD xregbc_
	LXI D,8
	XCHG
	CALL .ur
	RET
.4 EQU 0
	PUBLIC luscur_
luscur_:	lxi d,.5
	call csave
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,12-.5
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
	LHLD xreghl_
	PUSH H
	LXI H,12-.5
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
	RET
.5 EQU 0
	PUBLIC lusnum_
lusnum_:	lxi d,.6
	call csave
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	LXI H,12-.6
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
	LXI H,10-.6
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LHLD xregde_
	PUSH H
	LHLD xregbc_
	PUSH H
	LXI H,-6599
	PUSH H
	CALL asmif_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	RET
.6 EQU 0
	extrn	asmif_
	extrn	xreghl_
	extrn	xregde_
	extrn	xregbc_
	extrn	.ur
	END
