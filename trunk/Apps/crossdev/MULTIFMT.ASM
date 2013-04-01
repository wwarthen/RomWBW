	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	pINFOLIS_,2
	global	metadata_,128
	global	pDPB_,2
	global	pDPH_,2
	global	pSYSCFG_,2
	global	gDrvNum_,2
	global	gDevUnit_,2
	global	gDefLU_,2
	global	gCurLU_,2
	global	gNumLU_,2
	global	gStatus_,2
	global	gRetcode_,2
	global	g1st_,2
	global	gLast_,2
	global	gOverAll_,2
	global	gTT_,1
	global	e5buffer_,128
	PUBLIC dispattr_
dispattr_:	lxi d,.2
	call csave
	LXI H,8-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,27
	PUSH H
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	RET
.2 EQU 0
.1:
	DB 37,99,91,37,115,109,0
	PUBLIC clrline_
clrline_:	lxi d,.4
	call csave
	LDA gTT_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,0
	POP D
	XCHG
	CALL .lt
	JZ .5
	LXI H,0
	PUSH H
	LXI H,2
	PUSH H
	CALL crtlc_
	POP D
	POP D
.5:
	LXI H,13
	PUSH H
	LXI H,.3+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,13
	PUSH H
	LXI H,.3+40
	PUSH H
	CALL printf_
	POP D
	POP D
	RET
.4 EQU 0
.3:
	DB 37,99,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,32,32,32,32,32,32,32,0,32,32,32,32,32
	DB 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB 32,32,37,99,0
	PUBLIC getinfo_
getinfo_:	lxi d,.7
	call csave
	LXI H,-6602
	SHLD ireghl_
	LXI H,8-.7
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD iregbc_
	CALL bioscall_
	LDA irega_
	MOV L,A
	MVI	H,0
	SHLD gStatus_
	LHLD iregbc_
	SHLD gDevUnit_
	LHLD iregde_
	SHLD gCurLU_
	LHLD ireghl_
	SHLD gNumLU_
	RET
.7 EQU 0
	PUBLIC clrdir_
clrdir_:	lxi d,.8
	call csave
	lda gTT_
	ora a
	JNZ .9
	LHLD gDrvNum_
	PUSH H
	LXI H,.6+0
	PUSH H
	CALL printf_
	POP D
	POP D
.9:
	LXI H,128
	PUSH H
	LXI H,229
	PUSH H
	LXI H,e5buffer_
	PUSH H
	CALL memset_
	POP D
	POP D
	POP D
	LXI H,-6629
	SHLD ireghl_
	LHLD gDrvNum_
	SHLD iregbc_
	LXI H,0
	SHLD iregde_
	CALL bioscall_
	LHLD ireghl_
	SHLD pDPH_
	LHLD pDPH_
	LXI D,10
	DAD D
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD pDPB_
	LHLD pDPB_
	LXI D,7
	DAD D
	MOV E,M
	INX H
	MOV D,M
	XCHG
	INX H
	LXI D,2
	XCHG
	CALL .ur
	XCHG
	LXI H,0-.8
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	PUSH H
	LXI H,e5buffer_
	PUSH H
	LXI H,0
	PUSH H
	LHLD pDPB_
	LXI D,13
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LHLD gDrvNum_
	PUSH H
	CALL wrsector_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	LXI H,1
	XCHG
	LXI H,2-.8
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .11
.10:
	LXI H,2-.8
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
	LXI H,2-.8
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,0-.8
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .12
	LXI H,-1
	XCHG
	LXI H,8-.8
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .ne
	JZ .13
	LXI H,10-.8
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DCX H
	PUSH H
	LXI H,10-.8
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL crtlc_
	POP D
	POP D
	LXI H,0-.8
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,2-.8
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .sb
	PUSH H
	LXI H,.6+12
	PUSH H
	CALL printf_
	POP D
	POP D
.13:
	LXI H,1
	PUSH H
	LXI H,e5buffer_
	PUSH H
	LXI H,6-.8
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LHLD pDPB_
	LXI D,13
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LHLD gDrvNum_
	PUSH H
	CALL wrsector_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	JMP .10
.12:
	RET
.8 EQU -4
.6:
	DB 99,108,114,100,105,114,40,37,100,41,32,0,37,51,100
	DB 0
	PUBLIC clrmeta_
clrmeta_:	lxi d,.15
	call csave
	lda gTT_
	ora a
	JNZ .16
	LXI H,8-.15
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.14+0
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .17
.16:
	LXI H,12-.15
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DCX H
	PUSH H
	LXI H,12-.15
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL crtlc_
	POP D
	POP D
	LXI H,.14+13
	PUSH H
	CALL printf_
	POP D
.17:
	LXI H,0
	PUSH H
	LXI H,metadata_
	PUSH H
	LXI H,11
	PUSH H
	LXI H,0
	PUSH H
	LHLD gDrvNum_
	PUSH H
	CALL rdsector_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	LXI H,-23206
	SHLD metadata_
	LHLD pSYSCFG_
	LXI D,24
	DAD D
	MOV E,M
	XCHG
	MOV A,L
	STA metadata_+2
	LXI H,8
	PUSH H
	LXI H,.14+17
	PUSH H
	LXI H,metadata_+4
	PUSH H
	CALL memcpy_
	POP D
	POP D
	POP D
	LHLD gDrvNum_
	MOV A,L
	STA metadata_+12
	LXI H,8-.15
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	SHLD metadata_+13
	LXI H,0
	MOV A,L
	STA metadata_+96
	LXI H,2
	MOV A,L
	STA metadata_+99
	LXI H,5
	MOV A,L
	STA metadata_+100
	LXI H,0
	MOV A,L
	STA metadata_+101
	LXI H,1
	MOV A,L
	STA metadata_+102
	LXI H,16
	PUSH H
	LXI H,.14+26
	PUSH H
	LXI H,metadata_+103
	PUSH H
	CALL memcpy_
	POP D
	POP D
	POP D
	LXI H,36
	MOV A,L
	STA metadata_+119
	LXI H,0
	SHLD metadata_+97
	LXI H,0
	PUSH H
	LXI H,metadata_
	PUSH H
	LXI H,11
	PUSH H
	LXI H,0
	PUSH H
	LHLD gDrvNum_
	PUSH H
	CALL wrsector_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	RET
.15 EQU 0
.14:
	DB 99,108,114,109,101,116,97,40,37,100,41,32,0,109,101
	DB 116,0,109,117,108,116,105,102,109,116,0,91,109,117,108
	DB 116,105,102,111,114,109,97,116,116,101,100,93,0
	PUBLIC physfmt_
physfmt_:	lxi d,.19
	call csave
	LXI H,0
	PUSH H
	LXI H,metadata_
	PUSH H
	LXI H,11
	PUSH H
	LXI H,0
	PUSH H
	LHLD gDrvNum_
	PUSH H
	CALL rdsector_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	LDA metadata_+96
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,1
	POP D
	CALL .eq
	JZ .20
	lda gTT_
	ora a
	JNZ .21
	LXI H,8-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.18+0
	PUSH H
	CALL printf_
	POP D
	POP D
.21:
	LHLD gOverAll_
	MOV A,H
	ORA L
	JNZ .22
	lda gTT_
	ora a
	JNZ .23
	LXI H,.18+21
	PUSH H
	CALL printf_
	POP D
.23:
	LXI H,0
	RET
.22:
	lda gTT_
	ora a
	JNZ .24
	LXI H,.18+47
	PUSH H
	CALL printf_
	POP D
.24:
.20:
	lda gTT_
	ora a
	JNZ .25
	LXI H,13
	PUSH H
	LXI H,10-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.18+69
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	LXI H,-1
	PUSH H
	LXI H,-1
	PUSH H
	LXI H,12-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL clrmeta_
	POP D
	POP D
	POP D
	LXI H,-1
	PUSH H
	LXI H,-1
	PUSH H
	CALL clrdir_
	POP D
	POP D
	JMP .26
.25:
	LXI H,8-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16
	CALL .dv
	XCHG
	LXI H,2-.19
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	PUSH H
	LXI H,4-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,6
	DAD D
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,8-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,240
	CALL .an
	PUSH H
	LXI H,.18+90
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,15
	CALL .an
	XCHG
	LXI H,0-.19
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	LXI D,9
	DAD D
	PUSH H
	LXI H,4-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,6
	DAD D
	PUSH H
	LXI H,12-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL clrmeta_
	POP D
	POP D
	POP D
	LXI H,0-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	LXI D,9
	DAD D
	PUSH H
	LXI H,4-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,6
	DAD D
	PUSH H
	CALL clrdir_
	POP D
	POP D
	LXI H,0-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	LXI D,9
	DAD D
	PUSH H
	LXI H,4-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,6
	DAD D
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.18+97
	PUSH H
	CALL printf_
	POP D
.26:
	LXI H,1
	RET
.19 EQU -4
.18:
	DB 76,85,37,100,32,105,115,32,112,114,111,116,101,99,116
	DB 101,100,44,32,32,0,79,118,101,114,114,105,100,101,32
	DB 105,115,32,110,111,116,32,101,110,97,98,108,101,100,44
	DB 32,0,79,118,101,114,114,105,100,101,32,105,115,32,101
	DB 110,97,98,108,101,100,44,32,0,70,111,114,109,97,116
	DB 116,105,110,103,32,76,85,35,32,37,51,100,37,99,0
	DB 37,51,100,46,46,46,0,79,75,0
	PUBLIC lformat_
lformat_:	lxi d,.28
	call csave
	lda gTT_
	ora a
	JZ .29
	LXI H,0
	XCHG
	LXI H,2-.28
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .31
.30:
	LXI H,2-.28
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
.31:
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16
	CALL .lt
	JZ .32
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	LXI D,8
	DAD D
	PUSH H
	LXI H,4
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.27+0
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .30
.32:
	LXI H,0
	XCHG
	LXI H,2-.28
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .34
.33:
	LXI H,2-.28
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
.34:
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16
	CALL .lt
	JZ .35
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	LXI D,8
	DAD D
	PUSH H
	LXI H,5
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.27+5
	PUSH H
	CALL printf_
	POP D
	JMP .33
.35:
.29:
	LHLD gDrvNum_
	PUSH H
	CALL lugcur_
	POP D
	SHLD gDefLU_
	LHLD g1st_
	XCHG
	LXI H,2-.28
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .37
.36:
	LXI H,2-.28
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
.37:
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LHLD gLast_
	CALL .le
	JZ .38
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LHLD gDrvNum_
	PUSH H
	CALL luscur_
	POP D
	POP D
	LXI H,0
	PUSH H
	LXI H,metadata_
	PUSH H
	LXI H,11
	PUSH H
	LXI H,0
	PUSH H
	LHLD gDrvNum_
	PUSH H
	CALL rdsector_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	LDA metadata_+96
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,1
	POP D
	CALL .eq
	JZ .39
	LXI H,1
	XCHG
	LHLD gOverAll_
	CALL .eq
	JZ .40
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL physfmt_
	POP D
.40:
	JMP .41
.39:
	LXI H,2-.28
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL physfmt_
	POP D
.41:
	JMP .36
.38:
	LHLD gDefLU_
	PUSH H
	LHLD gDrvNum_
	PUSH H
	CALL luscur_
	POP D
	POP D
	RET
.28 EQU -2
.27:
	DB 43,37,50,100,0,45,45,45,0
	PUBLIC dispinfo_
dispinfo_:	lxi d,.43
	call csave
	LXI H,1
	XCHG
	LHLD gRetcode_
	CALL .eq
	JZ .44
	LXI H,1
	RET
.44:
	LHLD gNumLU_
	MOV A,H
	ORA L
	JNZ .45
	LXI H,1
	RET
.45:
	LHLD gDrvNum_
	LXI D,65
	DAD D
	PUSH H
	LXI H,.42+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD gCurLU_
	PUSH H
	LXI H,.42+13
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD gNumLU_
	PUSH H
	LXI H,.42+32
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD gDevUnit_
	LXI D,8
	XCHG
	CALL .rs
	LXI D,240
	CALL .an
	JMP .46
.48:
	LXI H,.42+55
	PUSH H
	CALL printf_
	POP D
	JMP .47
.49:
	LXI H,.42+68
	PUSH H
	CALL printf_
	POP D
	JMP .47
.50:
	LHLD gDevUnit_
	PUSH H
	LXI H,.42+83
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .47
.46:
	CALL .swt
	DW 2
	DW 32,.48
	DW 64,.49
	DW .50
.47:
	CALL clrline_
	LXI H,.42+106
	PUSH H
	CALL printf_
	POP D
	LXI H,1
	SHLD dregbc_
	CALL bdoscall_
	LDA drega_
	MOV L,A
	MVI	H,0
	JMP .51
.53:
.54:
	LXI H,1
	RET
.55:
	LXI H,0
	RET
.51:
	CALL .swt
	DW 2
	DW 89,.53
	DW 121,.54
	DW .55
.52:
	RET
.43 EQU 0
.42:
	DB 10,68,114,105,118,101,32,37,99,58,44,32,0,67,117
	DB 114,114,101,110,116,32,76,85,32,105,115,32,37,100,44
	DB 32,0,78,117,109,98,101,114,32,111,102,32,76,85,39
	DB 115,32,105,115,32,37,100,44,32,0,68,114,105,118,101
	DB 32,105,115,32,73,68,69,0,68,114,105,118,101,32,105
	DB 115,32,80,80,73,68,69,0,68,114,105,118,101,32,105
	DB 115,32,85,110,107,110,111,119,110,33,33,40,37,120,41
	DB 0,87,111,117,108,100,32,121,111,117,32,108,105,107,101
	DB 32,116,111,32,102,111,114,109,97,116,32,116,104,101,32
	DB 108,111,103,105,99,97,108,32,117,110,105,116,115,32,111
	DB 110,32,116,104,105,115,32,100,114,105,118,101,40,89,47
	DB 110,41,63,0
	PUBLIC gather_
gather_:	lxi d,.57
	call csave
	CALL clrline_
	LXI H,1
	SHLD g1st_
	LHLD g1st_
	PUSH H
	LHLD gNumLU_
	DCX H
	PUSH H
	LXI H,.56+0
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	LXI H,-124-.57
	DAD SP
	PUSH H
	CALL gets_
	POP D
	LXI H,-124-.57
	DAD SP
	PUSH H
	CALL strlen_
	POP D
	PUSH H
	LXI H,0
	POP D
	XCHG
	CALL .lt
	JZ .58
	LXI H,-124-.57
	DAD SP
	PUSH H
	CALL atoi_
	POP D
	SHLD g1st_
.58:
	CALL clrline_
	LHLD gNumLU_
	DCX H
	SHLD gLast_
	LHLD gLast_
	PUSH H
	LHLD gNumLU_
	DCX H
	PUSH H
	LXI H,.56+53
	PUSH H
	CALL printf_
	POP D
	POP D
	POP D
	LXI H,-124-.57
	DAD SP
	PUSH H
	CALL gets_
	POP D
	LXI H,-124-.57
	DAD SP
	PUSH H
	CALL strlen_
	POP D
	PUSH H
	LXI H,0
	POP D
	XCHG
	CALL .lt
	JZ .59
	LXI H,-124-.57
	DAD SP
	PUSH H
	CALL atoi_
	POP D
	SHLD gLast_
.59:
	CALL clrline_
	LXI H,0
	SHLD gOverAll_
	LXI H,.56+105
	PUSH H
	CALL printf_
	POP D
	LXI H,1
	SHLD dregbc_
	CALL bdoscall_
	LDA drega_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,89
	POP D
	CALL .eq
	JZ .60
	CALL clrline_
	LXI H,.56+165
	PUSH H
	CALL printf_
	POP D
	LXI H,1
	SHLD dregbc_
	CALL bdoscall_
	LDA drega_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,68
	POP D
	CALL .eq
	JZ .61
	LXI H,1
	SHLD gOverAll_
.61:
	JMP .62
.60:
	LXI H,.56+221
	PUSH H
	CALL printf_
	POP D
.62:
	RET
.57 EQU -128
.56:
	DB 80,108,101,97,115,101,32,101,110,116,101,114,32,102,105
	DB 114,115,116,32,108,111,103,105,99,97,108,32,117,110,105
	DB 116,32,116,111,32,102,111,114,109,97,116,32,48,45,37
	DB 100,32,40,37,100,41,58,0,80,108,101,97,115,101,32
	DB 101,110,116,101,114,32,108,97,115,116,32,108,111,103,105
	DB 99,97,108,32,117,110,105,116,32,116,111,32,102,111,114
	DB 109,97,116,32,48,45,37,100,32,40,37,100,41,58,0
	DB 68,111,32,121,111,117,32,119,97,110,116,32,116,111,32
	DB 111,118,101,114,114,105,100,101,32,97,108,108,32,112,114
	DB 111,116,101,99,116,101,100,32,108,111,103,105,99,97,108
	DB 32,117,110,105,116,115,32,40,89,47,110,41,58,32,0
	DB 68,111,32,121,111,117,32,114,101,97,108,108,121,32,119
	DB 97,110,116,32,116,111,32,68,69,83,84,82,79,89,32
	DB 97,108,108,32,108,111,103,105,99,97,108,32,117,110,105
	DB 116,115,32,40,68,47,110,41,58,32,0,10,0
	PUBLIC main_
main_:	lxi d,.64
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
	XCHG
	MOV A,L
	STA gTT_
	LDA gTT_
	MOV L,A
	MVI	H,0
	PUSH H
	CALL crtinit_
	POP D
	LDA gTT_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,0
	POP D
	XCHG
	CALL .lt
	JZ .65
	CALL crtclr_
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	CALL crtlc_
	POP D
	POP D
.65:
	LXI H,1
	PUSH H
	LXI H,0
	PUSH H
	LXI H,5
	PUSH H
	LXI H,2
	PUSH H
	LXI H,2013
	PUSH H
	LXI H,31
	PUSH H
	LXI H,3
	PUSH H
	LXI H,.63+0
	PUSH H
	CALL printf_
	XCHG
	LXI H,16
	DAD SP
	SPHL
	LXI H,.63+35
	PUSH H
	CALL printf_
	POP D
	LXI H,-6596
	SHLD ireghl_
	CALL bioscall_
	LHLD ireghl_
	SHLD pINFOLIS_
	LXI H,25
	SHLD dregbc_
	CALL bdoscall_
	LDA drega_
	MOV L,A
	MVI	H,0
	SHLD gDrvNum_
	LHLD gDrvNum_
	PUSH H
	CALL getinfo_
	POP D
	CALL dispinfo_
	XCHG
	LXI H,2-.64
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,2-.64
	DAD SP
	mov a,m
	inx h
	ora m
	JNZ .66
	LXI H,.63+81
	PUSH H
	CALL printf_
	POP D
	LXI H,1
	PUSH H
	CALL exit_
	POP D
.66:
	CALL gather_
	CALL lformat_
	RET
.64 EQU -2
.63:
	DB 77,85,76,84,73,70,77,84,46,67,79,77,32,37,100
	DB 47,37,100,47,37,100,32,118,37,100,46,37,100,46,37
	DB 100,46,37,100,0,32,100,119,103,32,45,32,80,114,101
	DB 112,97,114,101,32,110,101,119,32,109,97,115,115,32,115
	DB 116,111,114,97,103,101,32,109,101,100,105,97,32,102,111
	DB 114,32,117,115,101,0,10,70,111,114,109,97,116,32,99
	DB 97,110,99,101,108,108,101,100,32,97,116,32,117,115,101
	DB 114,39,115,32,114,101,113,117,101,115,116,0
	extrn	exit_
	extrn	crtclr_
	extrn	crtinit_
	extrn	atoi_
	extrn	strlen_
	extrn	gets_
	extrn	crtlc_
	extrn	printf_
	extrn	diagnose_
	extrn	hregde_
	extrn	hregbc_
	extrn	luscur_
	extrn	lugcur_
	extrn	wrsector_
	extrn	rdsector_
	extrn	bdoscall_
	extrn	dregbc_
	extrn	drega_
	extrn	bioscall_
	extrn	ireghl_
	extrn	iregde_
	extrn	iregbc_
	extrn	irega_
	extrn	memset_
	extrn	memcpy_
	extrn	.an
	extrn	.eq
	extrn	.ne
	extrn	.lt
	extrn	.le
	extrn	.rs
	extrn	.ur
	extrn	.sb
	extrn	.dv
	END
