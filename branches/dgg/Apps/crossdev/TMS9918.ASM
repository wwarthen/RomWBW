	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	global	style_,1
	global	vdp_rege_,960
	PUBLIC vdp_read_
vdp_read_:	lxi d,.2
	call csave
	LXI H,0
	XCHG
	LXI H,3-.2
	DAD SP
	MOV M,E
	JMP .4
.3:
	LXI H,3-.2
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.4:
	LXI H,3-.2
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,17
	CALL .lt
	JZ .5
	LXI H,152
	PUSH H
	CALL in_
	POP D
	XCHG
	LXI H,2-.2
	DAD SP
	MOV M,E
	LXI H,2-.2
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	JMP .3
.5:
	RET
.2 EQU -2
.1:
	DB 48,120,50,120,32,0
	PUBLIC vdp_disp_
vdp_disp_:	lxi d,.7
	call csave
	LXI H,8-.7
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,40
	CALL .ml
	XCHG
	LXI H,10-.7
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	INX H
	INX H
	INX H
	PUSH H
	CALL vdp_wrvr_
	POP D
	LXI H,0
	XCHG
	LXI H,3-.7
	DAD SP
	MOV M,E
	JMP .9
.8:
	LXI H,3-.7
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.9:
	LXI H,12-.7
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL strlen_
	POP D
	PUSH H
	LXI H,5-.7
	DAD SP
	MOV E,M
	MVI	D,0
	POP H
	CALL .lt
	JZ .10
	LXI H,3-.7
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,12-.7
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,152
	PUSH H
	CALL out_
	POP D
	POP D
	JMP .8
.10:
	RET
.7 EQU -1
	PUBLIC vdp_pad_
vdp_pad_:	lxi d,.11
	call csave
	LXI H,8-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,40
	CALL .ml
	XCHG
	LXI H,10-.11
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	INX H
	INX H
	INX H
	PUSH H
	CALL vdp_wrvr_
	POP D
	LXI H,0
	XCHG
	LXI H,3-.11
	DAD SP
	MOV M,E
	JMP .13
.12:
	LXI H,3-.11
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.13:
	LXI H,12-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL strlen_
	POP D
	PUSH H
	LXI H,5-.11
	DAD SP
	MOV E,M
	MVI	D,0
	POP H
	CALL .lt
	JZ .14
	LXI H,3-.11
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,12-.11
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,152
	PUSH H
	CALL out_
	POP D
	POP D
	JMP .12
.14:
	LXI H,12-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL strlen_
	POP D
	PUSH H
	LXI H,40
	POP D
	XCHG
	CALL .gt
	JZ .15
	LXI H,12-.11
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL strlen_
	POP D
	XCHG
	LXI H,3-.11
	DAD SP
	MOV M,E
	JMP .17
.16:
	LXI H,3-.11
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.17:
	LXI H,3-.11
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,40
	CALL .lt
	JZ .18
	LXI H,32
	PUSH H
	LXI H,152
	PUSH H
	CALL out_
	POP D
	POP D
	JMP .16
.18:
.15:
	RET
.11 EQU -1
	PUBLIC vdp_hz_j_
vdp_hz_j_:	lxi d,.19
	call csave
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,138
	DAD D
	PUSH H
	LXI H,.6+0
	PUSH H
	LXI H,5-.19
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,1
	XCHG
	LXI H,3-.19
	DAD SP
	MOV M,E
	JMP .21
.20:
	LXI H,3-.19
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.21:
	LXI H,3-.19
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,36
	CALL .lt
	JZ .22
	LXI H,1-.19
	DAD SP
	PUSH H
	LXI H,5-.19
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,12-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL vdp_disp_
	POP D
	POP D
	POP D
	JMP .20
.22:
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,136
	DAD D
	PUSH H
	LXI H,.6+3
	PUSH H
	LXI H,5-.19
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,1-.19
	DAD SP
	PUSH H
	LXI H,0
	PUSH H
	LXI H,12-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL vdp_disp_
	POP D
	POP D
	POP D
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,137
	DAD D
	PUSH H
	LXI H,.6+6
	PUSH H
	LXI H,5-.19
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,1-.19
	DAD SP
	PUSH H
	LXI H,36
	PUSH H
	LXI H,12-.19
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	CALL vdp_disp_
	POP D
	POP D
	POP D
	RET
.19 EQU -3
.6:
	DB 37,99,0,37,99,0,37,99,0
	PUBLIC vdp_main_
vdp_main_:	lxi d,.24
	call csave
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,129
	DAD D
	PUSH H
	LXI H,.23+0
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,1
	XCHG
	LXI H,3-.24
	DAD SP
	MOV M,E
	JMP .26
.25:
	LXI H,3-.24
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.26:
	LXI H,3-.24
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,36
	CALL .lt
	JZ .27
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,5-.24
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,0
	PUSH H
	CALL vdp_disp_
	POP D
	POP D
	POP D
	JMP .25
.27:
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,133
	DAD D
	PUSH H
	LXI H,.23+3
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,1
	XCHG
	LXI H,3-.24
	DAD SP
	MOV M,E
	JMP .29
.28:
	LXI H,3-.24
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.29:
	LXI H,3-.24
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,36
	CALL .lt
	JZ .30
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,5-.24
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,23
	PUSH H
	CALL vdp_disp_
	POP D
	POP D
	POP D
	JMP .28
.30:
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,135
	DAD D
	PUSH H
	LXI H,.23+6
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,1
	XCHG
	LXI H,3-.24
	DAD SP
	MOV M,E
	JMP .32
.31:
	LXI H,3-.24
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.32:
	LXI H,3-.24
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,23
	CALL .lt
	JZ .33
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,0
	PUSH H
	LXI H,7-.24
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	CALL vdp_disp_
	POP D
	POP D
	POP D
	JMP .31
.33:
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,131
	DAD D
	PUSH H
	LXI H,.23+9
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,1
	XCHG
	LXI H,3-.24
	DAD SP
	MOV M,E
	JMP .35
.34:
	LXI H,3-.24
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
.35:
	LXI H,3-.24
	DAD SP
	MOV E,M
	MVI	D,0
	LXI H,23
	CALL .lt
	JZ .36
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,36
	PUSH H
	LXI H,7-.24
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	CALL vdp_disp_
	POP D
	POP D
	POP D
	JMP .34
.36:
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,128
	DAD D
	PUSH H
	LXI H,.23+12
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,0
	PUSH H
	LXI H,0
	PUSH H
	CALL vdp_disp_
	POP D
	POP D
	POP D
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,130
	DAD D
	PUSH H
	LXI H,.23+15
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,36
	PUSH H
	LXI H,0
	PUSH H
	CALL vdp_disp_
	POP D
	POP D
	POP D
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,132
	DAD D
	PUSH H
	LXI H,.23+18
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,36
	PUSH H
	LXI H,23
	PUSH H
	CALL vdp_disp_
	POP D
	POP D
	POP D
	LDA style_
	MOV L,A
	MVI	H,0
	LXI D,134
	DAD D
	PUSH H
	LXI H,.23+21
	PUSH H
	LXI H,-41-.24
	DAD SP
	PUSH H
	CALL sprintf_
	POP D
	POP D
	POP D
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,0
	PUSH H
	LXI H,23
	PUSH H
	CALL vdp_disp_
	POP D
	POP D
	POP D
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
	LXI H,20-.24
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.23+24
	PUSH H
	LXI H,-29-.24
	DAD SP
	PUSH H
	CALL sprintf_
	XCHG
	LXI H,18
	DAD SP
	SPHL
	LXI H,-45-.24
	DAD SP
	PUSH H
	LXI H,-43-.24
	DAD SP
	PUSH H
	CALL strlen_
	POP D
	PUSH H
	LXI H,37
	POP D
	XCHG
	CALL .sb
	LXI D,2
	XCHG
	CALL .dv
	PUSH H
	LXI H,1
	PUSH H
	CALL vdp_disp_
	POP D
	POP D
	POP D
	LXI H,2
	PUSH H
	CALL vdp_hz_j_
	POP D
	LXI H,21
	PUSH H
	CALL vdp_hz_j_
	POP D
	RET
.24 EQU -49
.23:
	DB 37,99,0,37,99,0,37,99,0,37,99,0,37,99,0
	DB 37,99,0,37,99,0,37,99,0,37,115,32,37,100,47
	DB 37,100,47,37,100,32,86,101,114,32,37,100,46,37,100
	DB 46,37,100,0
	PUBLIC vdp_clr1_
vdp_clr1_:	lxi d,.38
	call csave
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,64
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,2-.38
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .40
.39:
	LXI H,2-.38
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
.40:
	LXI H,2-.38
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,16384
	CALL .ul
	JZ .41
	LXI H,0
	PUSH H
	LXI H,152
	PUSH H
	CALL out_
	POP D
	POP D
	JMP .39
.41:
	RET
.38 EQU -2
	PUBLIC vdp_setr_
vdp_setr_:	lxi d,.42
	call csave
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,128
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	RET
.42 EQU 0
	PUBLIC vdp_mode_
vdp_mode_:	lxi d,.43
	call csave
	LXI H,80
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,129
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	RET
.43 EQU 0
	PUBLIC vdp_pnt_
vdp_pnt_:	lxi d,.44
	call csave
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,130
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	RET
.44 EQU 0
	PUBLIC vdp_pgt_
vdp_pgt_:	lxi d,.45
	call csave
	LXI H,1
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,132
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	RET
.45 EQU 0
	PUBLIC vdp_colo_
vdp_colo_:	lxi d,.46
	call csave
	LXI H,240
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,135
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	RET
.46 EQU 0
	PUBLIC vdp_load_
vdp_load_:	lxi d,.47
	call csave
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,72
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,-2-.47
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,2-.47
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .49
.48:
	LXI H,2-.47
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
.49:
	LXI H,2-.47
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,256
	CALL .lt
	JZ .50
	LXI H,0
	XCHG
	LXI H,0-.47
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .52
.51:
	LXI H,0-.47
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
.52:
	LXI H,0-.47
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,8
	CALL .lt
	JZ .53
	LXI H,-2-.47
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
	LXI D,charset_
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,152
	PUSH H
	CALL out_
	POP D
	POP D
	JMP .51
.53:
	JMP .48
.50:
	RET
.47 EQU -6
	PUBLIC vdp_fill_
vdp_fill_:	lxi d,.54
	call csave
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,64
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,1-.54
	DAD SP
	MOV M,E
	LXI H,0
	XCHG
	LXI H,2-.54
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .56
.55:
	LXI H,2-.54
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
.56:
	LXI H,2-.54
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,960
	CALL .lt
	JZ .57
	LXI H,1-.54
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,152
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,1-.54
	DAD SP
	PUSH H
	MOV L,M
	INX H
	XCHG
	POP H
	MOV M,E
	LXI H,1-.54
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,128
	POP D
	CALL .eq
	JZ .58
	LXI H,0
	XCHG
	LXI H,1-.54
	DAD SP
	MOV M,E
.58:
	JMP .55
.57:
	RET
.54 EQU -3
	PUBLIC vdp_sync_
vdp_sync_:	lxi d,.59
	call csave
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,64
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,0
	XCHG
	LXI H,0-.59
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	LXI H,0
	XCHG
	LXI H,2-.59
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .61
.60:
	LXI H,2-.59
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
	LXI H,2-.59
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,960
	CALL .lt
	JZ .62
	LXI H,2-.59
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,vdp_rege_
	DAD D
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,152
	PUSH H
	CALL out_
	POP D
	POP D
	JMP .60
.62:
	RET
.59 EQU -4
	PUBLIC func700_
func700_:	lxi d,.63
	call csave
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,0
	PUSH H
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	RET
.63 EQU 0
	PUBLIC vdp_clr__
vdp_clr__:	lxi d,.64
	call csave
	LXI H,0
	XCHG
	LXI H,2-.64
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .66
.65:
	LXI H,2-.64
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
.66:
	LXI H,2-.64
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,960
	CALL .ul
	JZ .67
	LXI H,32
	PUSH H
	LXI H,4-.64
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,vdp_rege_
	DAD D
	POP D
	MOV M,E
	JMP .65
.67:
	RET
.64 EQU -2
	PUBLIC vdp_set__
vdp_set__:	lxi d,.68
	call csave
	LXI H,0
	XCHG
	LXI H,2-.68
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .70
.69:
	LXI H,2-.68
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
.70:
	LXI H,2-.68
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,960
	CALL .ul
	JZ .71
	LXI H,2-.68
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,127
	CALL .an
	PUSH H
	LXI H,4-.68
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,vdp_rege_
	DAD D
	POP D
	MOV M,E
	JMP .69
.71:
	RET
.68 EQU -2
	PUBLIC vdp_num__
vdp_num__:	lxi d,.72
	call csave
	LXI H,0
	XCHG
	LXI H,2-.72
	DAD SP
	MOV M,E
	INX H
	MOV M,D
	JMP .74
.73:
	LXI H,2-.72
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
.74:
	LXI H,2-.72
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,960
	CALL .ul
	JZ .75
	LXI H,2-.72
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,10
	CALL .um
	LXI D,48
	DAD D
	PUSH H
	LXI H,4-.72
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,vdp_rege_
	DAD D
	POP D
	MOV M,E
	JMP .73
.75:
	RET
.72 EQU -2
	PUBLIC vdp_wrvr_
vdp_wrvr_:	lxi d,.76
	call csave
	LXI H,8-.76
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,255
	CALL .an
	XCHG
	LXI H,3-.76
	DAD SP
	MOV M,E
	LXI H,8-.76
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	LXI H,8
	CALL .rs
	LXI D,64
	CALL .or
	XCHG
	LXI H,2-.76
	DAD SP
	MOV M,E
	LXI H,3-.76
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	LXI H,2-.76
	DAD SP
	MOV E,M
	MVI	D,0
	PUSH D
	LXI H,153
	PUSH H
	CALL out_
	POP D
	POP D
	RET
.76 EQU -2
	extrn	sprintf_
	extrn	out_
	extrn	strlen_
	extrn	printf_
	extrn	in_
	extrn	charset_
	extrn	.or
	extrn	.an
	extrn	.eq
	extrn	.lt
	extrn	.ul
	extrn	.gt
	extrn	.rs
	extrn	.sb
	extrn	.ml
	extrn	.dv
	extrn	.um
	END
