	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move
	PUBLIC main_
main_:	lxi d,.2
	call csave
	LXI H,12
	PUSH H
	LXI H,.1+0
	PUSH H
	CALL printf_
	POP D
	POP D
	RET
.2 EQU 0
.1:
	DB 37,99,0
	extrn	printf_
	END
