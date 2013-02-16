	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	pINFOLIS_,2
	global	pDPHMAP_,2
	global	pDPHVEC_,24
	global	metadata_,128
	global	pBIOS_,2
	global	pDPH_,2
	global	pCNFGDAT_,2
	global	pSYSCFG_,2
	global	devunit_,2
	global	dev_,2
	global	unit_,2
	global	currlu_,2
	global	numlu_,2
	global	drivenum_,2
	global	drive_,2
	global	deflu_,2
	global	szTemp_,128
	PUBLIC readsec_
readsec_:	lxi d,.2
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
	PUBLIC haslu_
haslu_:	lxi d,.3
	call csave
	LXI H,8-.3
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL lugnum_
	POP D
	PUSH H
	LXI H,0
	POP D
	XCHG
	CALL .lt
	JZ .4
	LXI H,1
	RET
.4:
	LXI H,0
	RET
.3 EQU 0
	PUBLIC dispdph_
dispdph_:	lxi d,.5
	call csave
	LXI H,-6602
	SHLD ireghl_
	LXI H,12-.5
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,-65
	DAD D
	SHLD iregbc_
	CALL bioscall_
	LDA irega_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,1
	POP D
	CALL .eq
	JZ .6
	RET
.6:
	LXI H,10-.5
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,10-.5
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL crtlc_
	POP D
	POP D
	LXI H,12-.5
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,12-.5
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,-65
	DAD D
	PUSH H
	CALL lugdu_
	POP D
	SHLD devunit_
	LHLD devunit_
	LXI D,240
	CALL .an
	SHLD dev_
	LHLD devunit_
	LXI D,15
	CALL .an
	SHLD unit_
	LXI H,12-.5
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,-65
	DAD D
	PUSH H
	CALL lugcur_
	POP D
	SHLD currlu_
	LHLD dev_
	JMP .7
.9:
	LHLD unit_
	MOV A,H
	ORA L
	JNZ .10
	LXI H,.1+5
	PUSH H
	CALL printf_
	POP D
.10:
	LXI H,1
	XCHG
	LHLD unit_
	CALL .eq
	JZ .11
	LXI H,.1+9
	PUSH H
	CALL printf_
	POP D
.11:
	JMP .8
.12:
	LHLD unit_
	PUSH H
	LXI H,.1+13
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.13:
	LHLD unit_
	PUSH H
	LXI H,.1+18
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.14:
	LHLD unit_
	PUSH H
	LXI H,.1+24
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.15:
	LHLD unit_
	PUSH H
	LXI H,.1+32
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.16:
	LHLD unit_
	PUSH H
	LXI H,.1+40
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.17:
	LHLD unit_
	PUSH H
	LXI H,.1+45
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.18:
	LHLD unit_
	PUSH H
	LXI H,.1+53
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.19:
	LHLD unit_
	PUSH H
	LXI H,.1+61
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .8
.20:
	LXI H,.1+68
	PUSH H
	CALL printf_
	POP D
	JMP .8
.7:
	CALL .swt
	DW 9
	DW 0,.9
	DW 16,.12
	DW 32,.13
	DW 48,.14
	DW 64,.15
	DW 80,.16
	DW 96,.17
	DW 112,.18
	DW 128,.19
	DW .20
.8:
	LXI H,14-.5
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,76
	POP D
	CALL .eq
	JZ .21
	LXI H,14-.5
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,17
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,85
	POP D
	CALL .eq
	JZ .22
	LHLD currlu_
	PUSH H
	LXI H,.1+72
	PUSH H
	CALL printf_
	POP D
	POP D
.22:
.21:
	RET
.5 EQU 0
.1:
	DB 37,99,58,32,0,82,79,77,0,82,65,77,0,70,68
	DB 37,100,0,73,68,69,37,100,0,65,84,65,80,73,37
	DB 100,0,80,80,73,68,69,37,100,0,83,68,37,100,0
	DB 80,82,80,83,68,37,100,0,80,80,80,83,68,37,100
	DB 0,72,68,83,75,37,100,0,85,78,75,0,45,76,85
	DB 37,100,0
	PUBLIC main_
main_:	lxi d,.24
	call csave
	LXI H,8-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,3
	CALL .eq
	JZ .25
	LXI H,10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	INX H
	INX H
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,-43-.24
	DAD SP
	PUSH H
	CALL strcpy_
	POP D
	POP D
	LXI H,10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,4
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,-75-.24
	DAD SP
	PUSH H
	CALL strcpy_
	POP D
	POP D
	LXI H,-77-.24
	DAD SP
	PUSH H
	CALL atoi_
	POP D
	XCHG
	LXI H,0-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-45-.24
	DAD SP
	PUSH H
	CALL strlen_
	POP D
	LXI D,2
	CALL .eq
	JZ .26
	LXI H,-44-.24
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,58
	POP D
	CALL .eq
	JZ .27
	LXI H,-45-.24
	DAD SP
	MOV E,M
	MVI	D,0
	XCHG
	JMP .28
.30:
.31:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,0
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.32:
.33:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,1
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.34:
.35:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,2
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.36:
.37:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,3
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.38:
.39:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,4
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.40:
.41:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,5
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.42:
.43:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,6
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.44:
.45:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,7
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.46:
.47:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,8
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.48:
.49:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,9
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.50:
.51:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,10
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.52:
.53:
	LXI H,0-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,11
	PUSH H
	CALL luscur_
	POP D
	POP D
	JMP .29
.54:
	JMP .29
.28:
	LXI D,-65
	DAD D
	XCHG
	LXI H,-44
	DAD D
	JC .54
	LXI H,.55
	DAD D
	DAD D
	MOV E,M
	INX H
	MOV D,M
	XCHG
	PCHL
.55:	DW .31
	DW .33
	DW .35
	DW .37
	DW .39
	DW .41
	DW .43
	DW .45
	DW .47
	DW .49
	DW .51
	DW .53
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .54
	DW .30
	DW .32
	DW .34
	DW .36
	DW .38
	DW .40
	DW .42
	DW .44
	DW .46
	DW .48
	DW .50
	DW .52
.29:
.27:
.26:
	LXI H,1
	PUSH H
	CALL exit_
	POP D
.25:
	LXI H,-6656
	SHLD pBIOS_
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
	LXI H,.23+0
	PUSH H
	CALL printf_
	XCHG
	LXI H,16
	DAD SP
	SPHL
	LXI H,.23+32
	PUSH H
	CALL printf_
	POP D
	LXI H,-6596
	SHLD ireghl_
	CALL bioscall_
	LHLD ireghl_
	SHLD pINFOLIS_
	LXI H,57
	PUSH H
	LXI H,7
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LHLD pINFOLIS_
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.23+79
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD pINFOLIS_
	LXI D,10
	DAD D
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD pDPHMAP_
	LHLD pDPHMAP_
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,65
	PUSH H
	LXI H,5
	PUSH H
	LXI H,3
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	INX H
	INX H
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,66
	PUSH H
	LXI H,5
	PUSH H
	LXI H,4
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,4
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,67
	PUSH H
	LXI H,5
	PUSH H
	LXI H,5
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,6
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,68
	PUSH H
	LXI H,25
	PUSH H
	LXI H,3
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,8
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,69
	PUSH H
	LXI H,25
	PUSH H
	LXI H,4
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,10
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,70
	PUSH H
	LXI H,25
	PUSH H
	LXI H,5
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,12
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,71
	PUSH H
	LXI H,45
	PUSH H
	LXI H,3
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,14
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,72
	PUSH H
	LXI H,45
	PUSH H
	LXI H,4
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,16
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,73
	PUSH H
	LXI H,45
	PUSH H
	LXI H,5
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,18
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,74
	PUSH H
	LXI H,65
	PUSH H
	LXI H,3
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,20
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,75
	PUSH H
	LXI H,65
	PUSH H
	LXI H,4
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LHLD pDPHMAP_
	LXI D,22
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,76
	PUSH H
	LXI H,65
	PUSH H
	LXI H,5
	PUSH H
	CALL dispdph_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LXI H,25
	SHLD dregbc_
	CALL bdoscall_
	LDA drega_
	MOV L,A
	MVI	H,0
	SHLD drive_
	LXI H,5
	PUSH H
	LXI H,7
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LHLD drive_
	LXI D,65
	DAD D
	PUSH H
	LXI H,.23+100
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD drive_
	PUSH H
	CALL lugdu_
	POP D
	SHLD devunit_
	LHLD devunit_
	LXI D,240
	CALL .an
	SHLD dev_
	LHLD devunit_
	LXI D,15
	CALL .an
	SHLD unit_
	LHLD drive_
	PUSH H
	CALL lugcur_
	POP D
	SHLD currlu_
	LHLD currlu_
	SHLD deflu_
	LHLD drive_
	PUSH H
	CALL lugnum_
	POP D
	SHLD numlu_
	LXI H,31
	PUSH H
	LXI H,7
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LHLD drive_
	PUSH H
	CALL lugnum_
	POP D
	PUSH H
	LXI H,.23+121
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,0
	XCHG
	LHLD numlu_
	CALL .lt
	JZ .56
	LXI H,4
	PUSH H
	LXI H,9
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.23+142
	PUSH H
	CALL printf_
	POP D
	LXI H,30
	PUSH H
	LXI H,9
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.23+164
	PUSH H
	CALL printf_
	POP D
	LXI H,56
	PUSH H
	LXI H,9
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.23+186
	PUSH H
	CALL printf_
	POP D
	LXI H,0
	XCHG
	LXI H,-10-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,39
	DAD D
	XCHG
	LXI H,-12-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-12-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LHLD numlu_
	CALL .gt
	JZ .57
	LHLD numlu_
	XCHG
	LXI H,-12-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
.57:
	LXI H,1
	XCHG
	LXI H,-13-.24
	DAD SP
	MOV M,E
.58:
	LXI H,-13-.24
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,1
	POP D
	CALL .eq
	JZ .59
	LXI H,10
	XCHG
	LXI H,-8-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,-4-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,-6-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .61
.60:
	LXI H,-6-.24
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
.61:
	LXI H,-6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,13
	CALL .lt
	JZ .62
	LXI H,0
	PUSH H
	LXI H,-6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,-4-.24
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.23+208
	PUSH H
	CALL printf_
	POP D
	LXI H,.23+237
	PUSH H
	CALL printf_
	POP D
	JMP .60
.62:
	LXI H,-10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,2-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .64
.63:
	LXI H,2-.24
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
.64:
	LXI H,2-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,-12-.24
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .65
	LXI H,2-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LHLD drive_
	PUSH H
	CALL luscur_
	POP D
	POP D
	LXI H,metadata_
	PUSH H
	LXI H,11
	PUSH H
	LXI H,0
	PUSH H
	LHLD drive_
	PUSH H
	CALL readsec_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LXI H,0
	MOV A,L
	STA metadata_+119
	LDA metadata_+96
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,1
	POP D
	CALL .eq
	JZ .66
	LXI H,.23+266
	PUSH H
	LXI H,-77-.24
	DAD SP
	PUSH H
	CALL strcpy_
	POP D
	POP D
	JMP .67
.66:
	LXI H,.23+268
	PUSH H
	LXI H,-77-.24
	DAD SP
	PUSH H
	CALL strcpy_
	POP D
	POP D
.67:
	LXI H,-4-.24
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
	JMP .68
.70:
	LXI H,3
	PUSH H
	LXI H,-6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL crtlc_
	POP D
	POP D
	LXI H,metadata_+103
	PUSH H
	LXI H,-77-.24
	DAD SP
	PUSH H
	LXI H,6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.23+270
	PUSH H
	CALL printf_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	JMP .69
.71:
	LXI H,29
	PUSH H
	LXI H,-6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL crtlc_
	POP D
	POP D
	LXI H,metadata_+103
	PUSH H
	LXI H,-77-.24
	DAD SP
	PUSH H
	LXI H,6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.23+280
	PUSH H
	CALL printf_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	JMP .69
.72:
	LXI H,55
	PUSH H
	LXI H,-6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL crtlc_
	POP D
	POP D
	LXI H,metadata_+103
	PUSH H
	LXI H,-77-.24
	DAD SP
	PUSH H
	LXI H,6-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.23+290
	PUSH H
	CALL printf_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LXI H,0
	XCHG
	LXI H,-4-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-8-.24
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
	JMP .69
.68:
	CALL .swt
	DW 3
	DW 0,.70
	DW 1,.71
	DW 2,.72
	DW .69
.69:
	JMP .63
.65:
	LXI H,0
	PUSH H
	LXI H,23
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.23+300
	PUSH H
	CALL printf_
	POP D
	LXI H,1
	SHLD dregbc_
	CALL bdoscall_
	LDA drega_
	MOV L,A
	MVI	H,0
	JMP .73
.75:
.76:
.77:
.78:
.79:
	LXI H,0
	XCHG
	LXI H,-13-.24
	DAD SP
	MOV M,E
	JMP .74
.80:
.81:
.82:
	LXI H,39
	XCHG
	LXI H,-10-.24
	DAD SP
	PUSH H
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	XCHG
	POP H
	MOV M,E
	INX H
	MOV M,D
	LXI H,-10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LHLD numlu_
	CALL .gt
	JZ .83
	LXI H,0
	XCHG
	LXI H,-10-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
.83:
	LXI H,-10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,39
	DAD D
	XCHG
	LXI H,-12-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-12-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LHLD numlu_
	CALL .gt
	JZ .84
	LHLD numlu_
	XCHG
	LXI H,-12-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
.84:
	JMP .74
.85:
.86:
	LXI H,39
	XCHG
	LXI H,-10-.24
	DAD SP
	PUSH H
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	XCHG
	CALL .sb
	XCHG
	POP H
	MOV M,E
	INX H
	MOV M,D
	LXI H,-10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,0
	CALL .lt
	JZ .87
	LXI H,0
	XCHG
	LXI H,-10-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
.87:
	LXI H,-10-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,39
	DAD D
	XCHG
	LXI H,-12-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,-12-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LHLD numlu_
	CALL .gt
	JZ .88
	LHLD numlu_
	XCHG
	LXI H,-12-.24
	DAD SP
	MOV M,E
	INX H
	MOV M,D
.88:
	JMP .74
.89:
	LXI H,7
	PUSH H
	LXI H,.23+340
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .74
.73:
	CALL .swt
	DW 10
	DW 3,.79
	DW 32,.82
	DW 78,.80
	DW 80,.85
	DW 81,.75
	DW 88,.77
	DW 110,.81
	DW 112,.86
	DW 113,.76
	DW 120,.78
	DW .89
.74:
	JMP .58
.59:
	LHLD deflu_
	PUSH H
	LHLD drive_
	PUSH H
	CALL luscur_
	POP D
	POP D
.56:
	RET
.24 EQU -83
.23:
	DB 77,65,80,46,67,79,77,32,37,100,47,37,100,47,37
	DB 100,32,118,37,100,46,37,100,46,37,100,32,40,37,100
	DB 41,0,32,100,119,103,32,45,32,83,121,115,116,101,109
	DB 32,83,116,111,114,97,103,101,32,68,114,105,118,101,115
	DB 32,97,110,100,32,76,111,103,105,99,97,108,32,85,110
	DB 105,116,115,0,105,110,102,111,108,105,115,116,46,118,101
	DB 114,115,105,111,110,32,37,100,10,0,67,117,114,114,101
	DB 110,116,32,100,114,105,118,101,32,105,115,32,37,99,58
	DB 0,78,117,109,98,101,114,32,111,102,32,76,85,115,32
	DB 105,115,32,37,100,10,0,76,85,32,80,32,45,45,45
	DB 45,45,76,97,98,101,108,45,45,45,45,45,45,0,76
	DB 85,32,80,32,45,45,45,45,45,76,97,98,101,108,45
	DB 45,45,45,45,45,0,76,85,32,80,32,45,45,45,45
	DB 45,76,97,98,101,108,45,45,45,45,45,45,0,9,9
	DB 9,9,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,32,32,32,32,32,32,32,32,32,0,32,32,32
	DB 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,32,32,32,32,32,32,32,32,0,42,0,32,0
	DB 37,51,100,32,37,115,32,37,115,0,37,51,100,32,37
	DB 115,32,37,115,0,37,51,100,32,37,115,32,37,115,0
	DB 79,112,116,105,111,110,115,40,32,78,40,101,120,116,41
	DB 44,32,80,40,114,101,118,105,111,117,115,41,44,32,81
	DB 40,117,105,116,41,32,41,63,32,0,37,99,0
	extrn	crtclr_
	extrn	crtinit_
	extrn	exit_
	extrn	strlen_
	extrn	atoi_
	extrn	strcpy_
	extrn	printf_
	extrn	crtlc_
	extrn	diagnose_
	extrn	hregde_
	extrn	hregbc_
	extrn	lugnum_
	extrn	luscur_
	extrn	lugcur_
	extrn	lugdu_
	extrn	bdoscall_
	extrn	dregbc_
	extrn	drega_
	extrn	bioscall_
	extrn	ireghl_
	extrn	iregde_
	extrn	iregbc_
	extrn	irega_
	extrn	.an
	extrn	.eq
	extrn	.lt
	extrn	.gt
	extrn	.sb
	END
