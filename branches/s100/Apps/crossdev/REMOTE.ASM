	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	style_,1
	global	vdp_rege_,960
	global	pINFOLIS_,2
	global	metadata_,128
	global	szTemp_,128
	global	linenum_,1
	global	counter_,1
	global	outer_,1
	global	inner_,1
	global	limit_,1
	global	index_,2
	global	line_,2
	global	ubyte_,1
	global	bitmask_,1
	global	row_,2
	global	bit_,2
	global	ascii_,2
	global	bool_,2
	global	pCNFGDAT_,2
	global	pSYSCFG_,2
	global	fd_,2
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
	CALL vdp_wrvr_
	POP D
	LXI H,152
	PUSH H
	CALL in_
	POP D
	LXI H,152
	PUSH H
	CALL in_
	POP D
	LXI H,0
	SHLD line_
	JMP .4
.3:
	LHLD line_
	INX H
	SHLD line_
.4:
	LHLD line_
	LXI D,24
	XCHG
	CALL .ul
	JZ .5
	LXI H,0
	PUSH H
	LHLD line_
	INX H
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LHLD line_
	INX H
	PUSH H
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,3-.2
	DAD SP
	MOV M,E
	JMP .7
.6:
	LXI H,3-.2
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.7:
	LXI H,3-.2
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,40
	CALL .lt
	JZ .8
	LXI H,152
	PUSH H
	CALL in_
	POP D
	MOV A,L
	STA ubyte_
	LDA ubyte_
	MOV L,A
	MVI	H,0
	JMP .9
.11:
	LXI H,0
	MOV A,L
	STA ubyte_
	JMP .10
.12:
	LXI H,0
	MOV A,L
	STA ubyte_
	JMP .10
.13:
	LXI H,0
	MOV A,L
	STA ubyte_
	JMP .10
.14:
	LXI H,32
	MOV A,L
	STA ubyte_
	JMP .10
.9:
	CALL .swt
	DW 4
	DW 0,.14
	DW 9,.13
	DW 10,.12
	DW 13,.11
	DW .10
.10:
	lda ubyte_
	ora a
	JZ .15
	LDA ubyte_
	MOV L,A
	MVI	H,0
	PUSH H
	LXI H,.1+11
	PUSH H
	CALL printf_
	POP D
	POP D
.15:
	JMP .6
.8:
	LXI H,50
	PUSH H
	LHLD line_
	INX H
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,.1+14
	PUSH H
	CALL printf_
	POP D
	LHLD line_
	MOV A,H
	ORA L
	JNZ .16
	LXI H,.1+16
	PUSH H
	CALL printf_
	POP D
.16:
	LHLD line_
	LXI D,1
	CALL .eq
	JZ .17
	LXI H,.1+43
	PUSH H
	CALL printf_
	POP D
.17:
	LHLD line_
	LXI D,4
	CALL .eq
	JZ .18
	LXI H,.1+70
	PUSH H
	CALL printf_
	POP D
.18:
	LHLD line_
	LXI D,5
	CALL .eq
	JZ .19
	LXI H,.1+97
	PUSH H
	CALL printf_
	POP D
.19:
	JMP .3
.5:
	LXI H,.1+117
	PUSH H
	CALL printf_
	POP D
	LXI H,1
	SHLD dregbc_
	CALL bdoscall_
	RET
.2 EQU -1
.1:
	DB 108,105,110,101,32,37,50,100,32,124,0,37,99,0,124
	DB 0,32,114,101,109,111,116,101,46,99,111,109,32,49,49
	DB 47,50,49,47,50,48,49,50,32,100,119,103,0,32,32
	DB 32,32,100,105,115,112,108,97,121,32,116,109,115,57,57
	DB 49,56,32,115,99,114,101,101,110,0,32,32,32,78,111
	DB 116,101,58,32,115,101,109,105,45,103,114,97,112,104,105
	DB 99,115,32,110,111,116,0,32,32,32,32,32,32,32,32
	DB 32,115,117,112,112,111,114,116,101,100,46,0,32,40,112
	DB 114,101,115,115,32,101,110,116,101,114,32,116,111,32,101
	DB 120,105,116,41,0
	extrn	printf_
	extrn	in_
	extrn	diagnose_
	extrn	hregde_
	extrn	hregbc_
	extrn	bdoscall_
	extrn	dregbc_
	extrn	crtlc_
	extrn	crtclr_
	extrn	crtinit_
	extrn	vdp_wrvr_
	extrn	.eq
	extrn	.lt
	extrn	.ul
	END
