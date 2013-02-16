	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	style_,1
	global	vdp_rege_,960
	global	pINFOLIS_,2
	global	metadata_,128
	global	pCNFGDAT_,2
	global	pSYSCFG_,2
	PUBLIC main_
main_:	lxi d,.2
	call csave
	LXI H,-4096
	SHLD hregbc_
	LXI H,-16384
	SHLD hregde_
	CALL diagnose_
	LXI H,-16384
	SHLD pSYSCFG_
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
	RET
.2 EQU -1
	extrn	diagnose_
	extrn	hregde_
	extrn	hregbc_
	extrn	crtlc_
	extrn	crtclr_
	extrn	crtinit_
	END
