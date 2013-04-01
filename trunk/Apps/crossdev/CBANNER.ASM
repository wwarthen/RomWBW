	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	DSEG
	public	lines_
lines_:
	DW .1+0
	CSEG
.1:
	DB 45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
	DB 45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
	DB 45,45,45,45,45,45,45,45,45,45,0
	DSEG
	public	line1_
line1_:
	DW .2+0
	CSEG
.2:
	DB 49,50,51,52,53,54,55,56,46,49,50,51,32,109,109
	DB 47,100,100,47,121,121,121,121,32,32,86,101,114,115,105
	DB 111,110,32,120,46,120,46,120,46,120,0
	DSEG
	public	line2_
line2_:
	DW .3+0
	CSEG
.3:
	DB 83,47,78,32,67,80,77,56,48,45,68,87,71,45,54
	DB 53,52,51,50,49,32,76,105,99,101,110,115,101,100,32
	DB 117,110,100,101,114,32,71,80,76,51,0
	DSEG
	public	line3_
line3_:
	DW .4+0
	CSEG
.4:
	DB 67,111,112,121,114,105,103,104,116,32,40,67,41,32,50
	DB 48,49,49,45,49,50,32,68,111,117,103,108,97,115,32
	DB 87,46,32,71,111,111,100,97,108,108,0
	PUBLIC sbanner_
sbanner_:	lxi d,.6
	call csave
	LXI H,8-.6
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,.5+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,2013
	PUSH H
	LXI H,31
	PUSH H
	LXI H,3
	PUSH H
	LXI H,.5+4
	PUSH H
	CALL printf_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LXI H,1
	PUSH H
	LXI H,0
	PUSH H
	LXI H,5
	PUSH H
	LXI H,2
	PUSH H
	LXI H,.5+18
	PUSH H
	CALL printf_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	LXI H,.5+39
	PUSH H
	CALL printf_
	POP D
	RET
.6 EQU -128
.5:
	DB 37,115,32,0,37,50,100,47,37,50,100,47,37,52,100
	DB 32,32,0,86,101,114,115,105,111,110,32,37,100,46,37
	DB 100,46,37,100,46,37,100,32,0,67,79,80,82,32,68
	DB 111,117,103,108,97,115,32,71,111,111,100,97,108,108,32
	DB 76,105,99,101,110,115,101,100,32,119,47,71,80,76,118
	DB 51,10,0
	PUBLIC banner_
banner_:	lxi d,.8
	call csave
	LHLD lines_
	PUSH H
	LXI H,.7+0
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,8-.8
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	PUSH D
	LXI H,-122-.8
	DAD SP
	PUSH H
	CALL strcpy_
	POP D
	POP D
.9:
	LXI H,-124-.8
	DAD SP
	PUSH H
	CALL strlen_
	POP D
	PUSH H
	LXI H,12
	POP D
	XCHG
	CALL .gt
	JZ .10
	LXI H,.7+4
	PUSH H
	LXI H,-122-.8
	DAD SP
	PUSH H
	CALL strcat_
	POP D
	POP D
	JMP .9
.10:
	LXI H,-124-.8
	DAD SP
	PUSH H
	LXI H,.7+6
	PUSH H
	CALL printf_
	POP D
	POP D
	LXI H,2013
	PUSH H
	LXI H,31
	PUSH H
	LXI H,3
	PUSH H
	LXI H,.7+10
	PUSH H
	CALL printf_
	XCHG
	LXI H,8
	DAD SP
	SPHL
	LXI H,1
	PUSH H
	LXI H,0
	PUSH H
	LXI H,5
	PUSH H
	LXI H,2
	PUSH H
	LXI H,.7+24
	PUSH H
	CALL printf_
	XCHG
	LXI H,10
	DAD SP
	SPHL
	LHLD line2_
	PUSH H
	LXI H,.7+45
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD line3_
	PUSH H
	LXI H,.7+49
	PUSH H
	CALL printf_
	POP D
	POP D
	LHLD lines_
	PUSH H
	LXI H,.7+53
	PUSH H
	CALL printf_
	POP D
	POP D
	RET
.8 EQU -128
.7:
	DB 37,115,10,0,32,0,37,115,32,0,37,50,100,47,37
	DB 50,100,47,37,52,100,32,32,0,86,101,114,115,105,111
	DB 110,32,37,100,46,37,100,46,37,100,46,37,100,10,0
	DB 37,115,10,0,37,115,10,0,37,115,10,0
	extrn	strcat_
	extrn	strlen_
	extrn	strcpy_
	extrn	printf_
	extrn	.gt
	END
