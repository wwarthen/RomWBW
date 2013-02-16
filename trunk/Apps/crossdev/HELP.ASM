	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC main_
main_:	lxi d,.2
	call csave
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	LXI H,0
	RET
.2 EQU 0
.1:
	DB 72,101,108,112,32,87,111,114,108,100,33,33,10,0
	extrn	printf_
	END
