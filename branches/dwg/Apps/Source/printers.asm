; printers.asm 12/25/2011 dwg - 

; Copyright (C) 2011-2012 Douglas Goodall All Rights Reserved.
; For non-commercial use by N8VEM community

	maclib	portab
	maclib	cpmbdos

	extrn	hexref

	cseg

	public	pr$h$nyb
pr$h$nyb:
	enter
	ani	15
	lxi	h,hexref
	add	l
	mov	l,a
	mov	e,m
	mvi	c,CWRITE
	call	BDOS
	leave
	ret

	public	pr$h$byte
pr$h$byte:
	enter
	push 	psw
	rrc
	rrc
	rrc
	rrc
	call	pr$h$nyb
	pop 	psw
	call	pr$h$nyb
	leave
	ret

	public	pr$h$word
pr$h$word:
	enter
	push	h
	mov	a,h
	call	pr$h$byte
	pop	h
	mov	a,l
	call	pr$h$byte
	leave
	ret

	public	pr$d$word
pr$d$word:
	enter
	call	PDEC
	leave
	ret

; From the "99 Bottles of Beer" web page at 
; http://99-bottles-of-beer.net/language-assembler-(8080-8085)-764.html 
; adapted for use in RomWBW/Apps with rmac syntax


; PRINT HL AS A DECIMAL NUMBER (0-65535)

;	public	PDEC
	public	PDEC,PDEC1,PDEC2,PDEC3,PDEC4,PDEC5
PDEC:	XRA	A		; LEADING ZERO FLAG
	STA	PDEC5
	LXI	B, -10000
	CALL	PDEC1
	LXI	B, -1000
	CALL	PDEC1
	LXI	B, -100
	CALL	PDEC1
	MVI	C, -10
	CALL	PDEC1
	MVI	C, -1
	MVI	A, 0FFh		; IF NUMBER IS ZERO, THIS MAKES SURE
	STA	PDEC5		; IT'S PRINTED
PDEC1:	MVI	A, '/'		; "0" - 1
PDEC2:	INR	A
	DAD	B
	JC	PDEC2
	STA	PDEC4		; SUBTRACT BC FROM HL
	MOV	A, L
	SBB	C
	MOV	L, A
	MOV	A, H
	SBB	B
	MOV	H, A
	LDA	PDEC4
	CPI	'0'		; ZERO?
	JNZ	PDEC3
	LDA	PDEC5		; ZERO FLAG SET?
	CPI	0h
	RZ			; COMMENT OUT TO PRINT LEADING ZEROS
PDEC3:	LDA	PDEC4
	CONOUTA			; WAS "CALL PCHAR"
	MVI	A, 0FFh		; SET LEADING ZERO FLAG
	STA	PDEC5
	RET

	dseg

PDEC4:	DB	0		; TEMP FOR 16 BIT SUBTRACTION
PDEC5:	DB	0		; FLAG FOR LEADING ZEROS

	END

; eof - printers.asm

