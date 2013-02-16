	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	pDPHMAP_,2
	global	pDPHVEC_,24
	DSEG
	public	pSYSCFG_
pSYSCFG_:
	DW -16384
	CSEG
	DSEG
	public	map_
map_:
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 1
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 1
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	DB 0
	CSEG
	DSEG
	public	attroff_
attroff_:
	DB 27
	DB 91
	DB 109
	DB 0
	CSEG
	DSEG
	public	attrbold_
attrbold_:
	DB 27
	DB 91
	DB 49
	DB 109
	DB 0
	CSEG
	DSEG
	public	attrlow_
attrlow_:
	DB 27
	DB 91
	DB 50
	DB 109
	DB 0
	CSEG
	DSEG
	public	attrundr_
attrundr_:
	DB 27
	DB 91
	DB 52
	DB 109
	DB 0
	CSEG
	DSEG
	public	attrblnk_
attrblnk_:
	DB 27
	DB 91
	DB 53
	DB 109
	DB 0
	CSEG
	DSEG
	public	attrrevs_
attrrevs_:
	DB 27
	DB 91
	DB 55
	DB 109
	DB 0
	CSEG
	DSEG
	public	attrinvs_
attrinvs_:
	DB 27
	DB 91
	DB 56
	DB 109
	DB 0
	CSEG
	DSEG
	public	graphon_
graphon_:
	DB 27
	DB 70
	DB 0
	CSEG
	DSEG
	public	graphoff_
graphoff_:
	DB 27
	DB 71
	DB 0
	CSEG
	DSEG
	public	atreset_
atreset_:
	DB 48
	DB 0
	CSEG
	DSEG
	public	atbold_
atbold_:
	DB 49
	DB 0
	CSEG
	DSEG
	public	atdim_
atdim_:
	DB 50
	DB 0
	CSEG
	DSEG
	public	atundrsc_
atundrsc_:
	DB 52
	DB 0
	CSEG
	DSEG
	public	atblink_
atblink_:
	DB 53
	DB 0
	CSEG
	DSEG
	public	atrevs_
atrevs_:
	DB 55
	DB 0
	CSEG
	DSEG
	public	athidden_
athidden_:
	DB 56
	DB 0
	CSEG
	DSEG
	public	fgblack_
fgblack_:
	DB 51
	DB 48
	DB 0
	CSEG
	DSEG
	public	fgred_
fgred_:
	DB 51
	DB 49
	DB 0
	CSEG
	DSEG
	public	fggreen_
fggreen_:
	DB 51
	DB 50
	DB 0
	CSEG
	DSEG
	public	fgyellow_
fgyellow_:
	DB 51
	DB 51
	DB 0
	CSEG
	DSEG
	public	fgblue_
fgblue_:
	DB 51
	DB 52
	DB 0
	CSEG
	DSEG
	public	fgmagent_
fgmagent_:
	DB 51
	DB 53
	DB 0
	CSEG
	DSEG
	public	fgcyan_
fgcyan_:
	DB 51
	DB 54
	DB 0
	CSEG
	DSEG
	public	fgwhite_
fgwhite_:
	DB 51
	DB 55
	DB 0
	CSEG
	DSEG
	public	bgblack_
bgblack_:
	DB 52
	DB 48
	DB 0
	CSEG
	DSEG
	public	bgred_
bgred_:
	DB 52
	DB 49
	DB 0
	CSEG
	DSEG
	public	bggreen_
bggreen_:
	DB 52
	DB 50
	DB 0
	CSEG
	DSEG
	public	bgyellow_
bgyellow_:
	DB 52
	DB 51
	DB 0
	CSEG
	DSEG
	public	bgblue_
bgblue_:
	DB 52
	DB 52
	DB 0
	CSEG
	DSEG
	public	bgmagent_
bgmagent_:
	DB 52
	DB 53
	DB 0
	CSEG
	DSEG
	public	bgcyan_
bgcyan_:
	DB 52
	DB 54
	DB 0
	CSEG
	DSEG
	public	bgwhite_
bgwhite_:
	DB 52
	DB 55
	DB 0
	CSEG
	PUBLIC dispattr_
dispattr_:	lxi d,.2
	call csave
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,12-.2
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
	XCHG
	LXI H,10
	DAD SP
	SPHL
	RET
.2 EQU 0
.1:
	DB 37,99,91,37,115,59,37,115,59,37,115,109,0
	PUBLIC main_
main_:	lxi d,.4
	call csave
	LXI H,1
	XCHG
	LXI H,8-.4
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .5
	LXI H,1
	XCHG
	LXI H,2-.4
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .7
.6:
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
.7:
	LXI H,2-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,8-.4
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	CALL .lt
	JZ .8
	LXI H,2-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	XCHG
	LXI H,10-.4
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL atoi_
	POP D
	PUSH H
	LXI H,.3+0
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .6
.8:
	JMP .9
.5:
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
	LXI H,bgblack_
	PUSH H
	LXI H,fggreen_
	PUSH H
	LXI H,atbold_
	PUSH H
	CALL dispattr_
	POP D
	POP D
	POP D
	LXI H,.3+3
	PUSH H
	CALL banner_
	POP D
	LXI H,attroff_
	PUSH H
	LXI H,.3+9
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,bgblack_
	PUSH H
	LXI H,fgcyan_
	PUSH H
	LXI H,atbold_
	PUSH H
	CALL dispattr_
	POP D
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,-4-.4
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .11
.10:
	LXI H,-4-.4
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
	LXI H,-4-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16
	CALL .lt
	JZ .12
	LXI H,-4-.4
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
	LXI H,6
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,-4-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.3+12
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .10
.12:
	LXI H,attroff_
	PUSH H
	LXI H,.3+17
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,-6-.4
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .14
.13:
	LXI H,-6-.4
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
	LXI H,-6-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16
	CALL .lt
	JZ .15
	LXI H,4
	PUSH H
	LXI H,-4-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,7
	DAD D
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,bgblack_
	PUSH H
	LXI H,fgcyan_
	PUSH H
	LXI H,atbold_
	PUSH H
	CALL dispattr_
	POP D
	POP D
	POP D
	LXI H,-6-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.3+20
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,attroff_
	PUSH H
	LXI H,.3+25
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,-4-.4
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .17
.16:
	LXI H,-4-.4
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
	LXI H,-4-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16
	CALL .lt
	JZ .18
	LXI H,-4-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	LXI D,10
	DAD D
	PUSH H
	LXI H,-4-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,7
	DAD D
	PUSH H
	CALL crtlc_
	POP D
	POP D
	LXI H,-6-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	DAD H
	DAD H
	XCHG
	LXI H,-4-.4
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	LXI D,map_
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,1
	POP D
	CALL .eq
	JZ .19
	LXI H,.3+28
	PUSH H
	CALL printf_
	POP D
	JMP .20
.19:
	LXI H,-6-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	XCHG
	DAD H
	DAD H
	DAD H
	DAD H
	XCHG
	LXI H,-4-.4
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	PUSH H
	LXI H,.3+30
	PUSH H
	CALL printf_
	POP D
	POP D
.20:
	JMP .16
.18:
	LXI H,bgblack_
	PUSH H
	LXI H,fgcyan_
	PUSH H
	LXI H,atbold_
	PUSH H
	CALL dispattr_
	POP D
	POP D
	POP D
	LXI H,-6-.4
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.3+33
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,attroff_
	PUSH H
	LXI H,.3+40
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .13
.15:
.9:
	LXI H,0
	RET
.4 EQU -10
.3:
	DB 37,99,0,67,72,65,82,83,0,37,115,0,91,37,120
	DB 93,0,37,115,0,91,37,120,93,0,37,115,0,46,0
	DB 37,99,0,32,32,91,37,120,93,0,37,115,0
	extrn	atoi_
	extrn	printf_
	extrn	banner_
	extrn	crtlc_
	extrn	crtclr_
	extrn	crtinit_
	extrn	diagnose_
	extrn	hregde_
	extrn	hregbc_
	extrn	.eq
	extrn	.lt
	END
