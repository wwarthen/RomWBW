*  SYSTEM SEGMENT:  SYS.FCP
*  SYSTEM:  ZCPR3
*  CUSTOMIZED BY:  RICHARD CONN

*
*  PROGRAM:  SYSFCP.ASM
*  AUTHOR:  RICHARD CONN
*  VERSION:  1.0
*  DATE:  22 FEB 84
*  PREVIOUS VERSIONS:  NONE
*
VERSION	EQU	10

*
*  Global Library which Defines Addresses for SYSTEM
*
	MACLIB	Z3BASE	; USE BASE ADDRESSES
	MACLIB	SYSFCP	; USE EQUATES FROM HEADER FILE

;
LF	EQU	0AH
CR	EQU	0DH
BELL	EQU	07H
;
BASE	EQU	0
WBOOT	EQU	BASE+0000H		;CP/M WARM BOOT ADDRESS
UDFLAG	EQU	BASE+0004H		;USER NUM IN HIGH NYBBLE, DISK IN LOW
BDOS	EQU	BASE+0005H		;BDOS FUNCTION CALL ENTRY PT
TFCB	EQU	BASE+005CH		;DEFAULT FCB BUFFER
FCB1	EQU	TFCB			;1st and 2nd FCBs
FCB2	EQU	TFCB+16
TBUFF	EQU	BASE+0080H		;DEFAULT DISK I/O BUFFER
TPA	EQU	BASE+0100H		;BASE OF TPA
;
$-MACRO 		;FIRST TURN OFF THE EXPANSIONS
;
; MACROS TO PROVIDE Z80 EXTENSIONS
;   MACROS INCLUDE:
;
;	JR	- JUMP RELATIVE
;	JRC	- JUMP RELATIVE IF CARRY
;	JRNC	- JUMP RELATIVE IF NO CARRY
;	JRZ	- JUMP RELATIVE IF ZERO
;	JRNZ	- JUMP RELATIVE IF NO ZERO
;	DJNZ	- DECREMENT B AND JUMP RELATIVE IF NO ZERO
;
;	@GENDD MACRO USED FOR CHECKING AND GENERATING
;	8-BIT JUMP RELATIVE DISPLACEMENTS
;
@GENDD	MACRO	?DD	;;USED FOR CHECKING RANGE OF 8-BIT DISPLACEMENTS
	IF (?DD GT 7FH) AND (?DD LT 0FF80H)
	DB	100H,?DD	;Displacement Range Error
	ELSE
	DB	?DD
	ENDIF		;;RANGE ERROR
	ENDM
;
;
; Z80 MACRO EXTENSIONS
;
JR	MACRO	?N	;;JUMP RELATIVE
	IF	I8080	;;8080/8085
	JMP	?N
	ELSE		;;Z80
	DB	18H
	@GENDD	?N-$-1
	ENDIF		;;I8080
	ENDM
;
JRC	MACRO	?N	;;JUMP RELATIVE ON CARRY
	IF	I8080	;;8080/8085
	JC	?N
	ELSE		;;Z80
	DB	38H
	@GENDD	?N-$-1
	ENDIF		;;I8080
	ENDM
;
JRNC	MACRO	?N	;;JUMP RELATIVE ON NO CARRY
	IF	I8080	;;8080/8085
	JNC	?N
	ELSE		;;Z80
	DB	30H
	@GENDD	?N-$-1
	ENDIF		;;I8080
	ENDM
;
JRZ	MACRO	?N	;;JUMP RELATIVE ON ZERO
	IF	I8080	;;8080/8085
	JZ	?N
	ELSE		;;Z80
	DB	28H
	@GENDD	?N-$-1
	ENDIF		;;I8080
	ENDM
;
JRNZ	MACRO	?N	;;JUMP RELATIVE ON NO ZERO
	IF	I8080	;;8080/8085
	JNZ	?N
	ELSE		;;Z80
	DB	20H
	@GENDD	?N-$-1
	ENDIF		;;I8080
	ENDM
;
DJNZ	MACRO	?N	;;DECREMENT B AND JUMP RELATIVE ON NO ZERO
	IF	I8080	;;8080/8085
	DCR	B
	JNZ	?N
	ELSE		;;Z80
	DB	10H
	@GENDD	?N-$-1
	ENDIF		;;I8080
	ENDM
*
*  SYSTEM Entry Point
*
	org	fcp		; passed for Z3BASE

	db	'Z3FCP'		; Flag for Package Loader
*
*  **** Command Table for FCP ****
*	This table is FCP-dependent!
*
*	The command name table is structured as follows:
*
*	ctable:
*		DB	'CMNDNAME'	; Table Record Structure is
*		DW	cmndaddress	; 8 Chars for Name and 2 Bytes for Adr
*		...
*		DB	0	; End of Table
*
cnsize	equ	4		; NUMBER OF CHARS IN COMMAND NAME
	db	cnsize	; size of text entries
ctab:
	db	'IF  '
	dw	ifstart
	db	'ELSE'
	dw	ifelse
	db	'FI  '
	dw	ifend
	db	'XIF '
	dw	ifexit
	db	0
;
; Condition Table
;
condtab:
;
	IF	IFOTRUE
	db	'T '		;TRUE
	dw	ifctrue
	db	'F '		;FALSE
	dw	ifcfalse
	ENDIF
;
	IF	IFOEMPTY
	db	'EM'		;file empty
	dw	ifcempty
	ENDIF
;
	IF	IFOERROR
	db	'ER'		;error message
	dw	ifcerror
	ENDIF
;
	IF	IFOEXIST
	db	'EX'		;file exists
	dw	ifcex
	ENDIF
;
	IF	IFOINPUT
	db	'IN'		;user input
	dw	ifcinput
	ENDIF
;
	IF	IFONULL
	db	'NU'
	dw	ifcnull
	ENDIF
;
	IF	IFOTCAP		;Z3 TCAP available
	db	'TC'
	dw	ifctcap
	ENDIF
;
	IF	IFOWHEEL	;Wheel Byte
	db	'WH'
	dw	ifcwheel
	ENDIF
;
	db	0

*
*  Print " IF"
*
prif:
	call	print
	db	'IF',' '+80H
	ret
*
*  Print String (terminated in 0 or MSB Set) at Return Address
*
print:
	IF	NOISE
	mvi	a,' '		;print leading space
	call	conout
	ENDIF		;NOISE
	xthl			; get address
	call	print1
	xthl			; put address
	ret
*
*  Print String (terminated by MSB Set) pted to by HL
*
print1:
	mov	a,m		; done?
	inx	h		; pt to next
	call	conout		; print char
	ora	a		; set MSB flag (M)
	rm			; MSB terminator
	jr	print1

*
*  **** FCP Routines ****
*  All code from here on is FCP-dependent!
*

;
; FCP Command: XIF
;   XIF terminates all IFs, restoring a basic TRUE state
;
ifexit:
	IF	NOISE
	call	nl		;print new line
	ENDIF		;NOISE
	call	iftest		;see if current IF is running and FALSE
	jrz	ifstat		;abort with status message if so
	lxi	h,z3msg+1	;pt to IF flag
	xra	a		;A=0
	mov	m,a		;zero IF flag
	jr	ifendmsg	;print message

;
; FCP Command: FI
;   FI decrements to the previous IF
;
;   Algorithm:
;	Rotate Current IF Bit (1st IF Message) Right 1 Bit Position
;
ifend:
	IF	NOISE
	call	nl		;print new line
	ENDIF		;NOISE
	lxi	h,z3msg+1	;pt to IF flag
	mov	a,m		;get it
	ora	a		;no IF active?
	jrz	ifnderr
ifendmsg:
	IF	NOISE
	push	psw		;save A
	call	print
	db	'T','o'+80H	;prefix to status display
	pop	psw		;get A
	ENDIF		;NOISE
	rrc			;move right 1 bit
	ani	7fh		;mask msb 0
	mov	m,a		;store active bit
	jrnz	ifstat		;print status if IF still active
ifnderr:
	IF	NOISE
	call	print		;print message
	db	'N','o'+80H
	jmp	prif
	ELSE		;NOT NOISE
	ret
	ENDIF		;NOISE

;
; FCP Command: ELSE
;   ELSE complements the Active Bit for the Current IF
;
;   Algorithm:
;	If Current IF is 0 (no IF) or 1 (one IF), then toggle
;		Active IF Bit associated with Current IF
;	Else
;		If Previous IF was Active then toggle
;			Active IF Bit associated with Current IF
;		Else do nothing
;
ifelse:
	IF	NOISE
	call	nl		;print new line
	ENDIF		;NOISE
	lxi	h,z3msg+1	;pt to IF msgs
	mov	a,m		;get current IF
	mov	b,a		;save current IF in B
	inx	h		;pt to active IF message
	rrc			;back up to previous IF level
	ani	7fh		;mask out possible carry
	jrz	iftog		;toggle if IF level is 0 or 1
	ana	m		;determine previous IF status
	jrz	ifstat		;don't toggle, and just print status
iftog:
	mov	a,m		;get active IF message
	cma			;flip bits
	ana	b		;look at only interested bit
	mov	c,a		;result in C
	mov	a,b		;complement IF byte
	cma
	mov	b,a
	mov	a,m		;get active byte
	ana	b		;mask in only uninterested bits
	ora	c		;mask in complement of interested bit
	mov	m,a		;save result and fall thru to print status
;
; Indicate if current IF is True or False
;
ifstat:
	IF	NOISE
	call	prif
	mvi	b,'F'		;assume False
	call	iftest		;see if IF is FALSE (Z if so)
	jrz	ifst1		;Zero means IF F or No IF
	mvi	b,'T'		;set True
ifst1:
	mov	a,b		;get T/F flag and fall thru to print it
	ELSE		;NOT NOISE
	ret
	ENDIF		;NOISE

;
;  Console Output Routine
;
conout:
	push	h		; save regs
	push	d
	push	b
	push	psw
	ani	7fh		; mask MSB
	mov	e,a		; char in E
	mvi	c,2		; output
	call	bdos
	pop	psw		; get regs
	pop	b
	pop	d
	pop	h
	ret

;
;  Output LF (to go with CR from ZCPR3)
;
nl:
	mvi	a,lf		;output LF
	jr	conout

;
; FCP Command: IF
;
ifstart:
	IF	NOISE
	call	nl		;print new line
	ENDIF		;NOISE
	call	iftest		;see if current IF is running and FALSE
;
	IF	NOT COMIF
	jrz	ifcfalse	;raise next IF level to FALSE if so
	ELSE
	jz	ifcf
	ENDIF		;NOT COMIF
;

;****************************************************************
;*								*
;* IF.COM Processing						*
;*								*
;****************************************************************

;
; If IF.COM to be processed, goto ROOT (base of path) and load it
;
	IF	COMIF
;
; Get Current Disk and User in BC
;
	lda	udflag		;get UD
	push	psw		;save UD flag
	ani	0fh		;get disk
	sta	cdisk		;set current disk
	mov	b,a		;B=disk (A=0)
	pop	psw		;get UD flag
	rlc			;get user in low 4 bits
	rlc
	rlc
	rlc
	ani	0fh		;get user
	sta	cuser		;set current user
	mov	c,a		;... in C
;
; Pt to Start of Path
;
	lxi	h,expath	;pt to path
;
; Check for End of Path
;
fndroot:
	mov	a,m		;check for done
	ora	a		;end of path?
	jrz	froot2
;
; Process Next Path Element
;
	cpi	'$'		;current disk?
	jrnz	froot0
	lda	cdisk		;get current disk
	inr	a		;+1 for following -1
froot0:
	dcr	a		;set A=0
	mov	b,a		;set disk
	inx	h		;pt to user
	mov	a,m		;get user
	cpi	'$'		;current user?
	jrnz	froot1
	lda	cuser		;get current user
froot1:
	mov	c,a		;set user
	inx	h		;pt to next
	jr	fndroot
;
; Done with Search - BC Contains ROOT DU
;
froot2:
;
; Log Into ROOT
;
	call	logbc		;log into root DU
;
; Set Address of Next Load and Set DMA for OPEN
;
	lxi	h,100h		;pt to TPA
	shld	nxtload		;set address for next load
	xchg			;DE=100H so don't wipe out buffers
	mvi	c,26		;set DMA
	call	bdos
;
; Try to Open File IF.COM
;
	lxi	d,extfcb	;pt to FCB
	mvi	c,15		;open file
	call	bdos
	inr	a		;check for found
	jz	ifnotfnd
;
; Load File IF.COM
;
ifload:
;
; Set Load Address
;
	lhld	nxtload		;get address of next load
	push	h		;save it
	lxi	d,80h		;pt to following
	dad	d
	shld	nxtload
	pop	d		;get load address
	mvi	c,26		;set DMA
	call	bdos
;
; Read in Block (Sector) and Loop Back if Not Done
;
	lxi	d,extfcb	;read file
	mvi	c,20
	push	d		;save ptr in case of failure (done)
	call	bdos
	pop	d
	ora	a		;OK?
	jz	ifload
;
; Done - Close File
;
	mvi	c,16		;close file
	call	bdos
;
; Reset Environment (DMA and DU) and Run IF.COM
;
	call	reset		;reset DMA and directory
	jmp	tpa		;run IF.COM
;
; Reset DMA Address and Current Disk (in CDISK) and User (in CUSER)
;
reset:
	lxi	d,80h		;reset DMA address
	mvi	c,26
	call	bdos
	lda	cdisk		;return home
	mov	b,a
	lda	cuser
	mov	c,a
;
; Log Into DU in BC
;
logbc:
	mov	e,b		;set disk
	push	b
	mvi	c,14		;select disk
	call	bdos
	pop	b
	mov	e,c		;set user
	mvi	c,32		;select user
	jmp	bdos
;
; IF.COM not found - Process as IF F
;
ifnotfnd:
	call	reset		;return home
	jr	ifcf
;
; Buffers for COMIF
;
nxtload:
	ds	2		;address of next block (sector) to load
cuser:
	ds	1		;current user
cdisk:
	ds	1		;current disk (A=0)
;
	ENDIF		;COMIF
;

	IF	NOT COMIF
;****************************************************************
;*								*
;* Non-IF.COM Processing					*
;*								*
;****************************************************************

;
; Test for Equality if Enabled
;
	IF	IFOEQ
	lxi	h,tbuff+1	;look for '=' in line
tsteq:
	mov	a,m		;get char
	inx	h		;pt to next
	ora	a		;EOL?
	jrz	ifck0		;continue if so
	cpi	'='		;'=' found?
	jrnz	tsteq
	lxi	h,fcb1+1	;compare FCBs
	lxi	d,fcb2+1
	mvi	b,11		;11 bytes
eqtest:
	ldax	d		;compare
	cmp	m
	jrnz	ifcf
	inx	h		;pt to next
	inx	d
	djnz	eqtest
	jr	ifct
	ENDIF		;IFOEQ
;
; Test Condition in FCB1 and file name in FCB2
;   Execute condition processing routine
;
ifck0:
	lxi	d,fcb1+1	;pt to first char in FCB1
;
	IF	IFONEG
	ldax	d		;get it
	sta	negflag		;set negate flag
	cpi	negchar		;is it a negate?
	jrnz	ifck1
	inx	d		;pt to char after negchar
ifck1:
	ENDIF		;IFONEG
;
	IF	IFOREG		;REGISTERS
	call	regtest		;test for register value
	jrnz	runreg
	ENDIF		;IFOREG
;
	call	condtest	;test of condition match
	jrnz	runcond		;process condition
	call	print		;beep to indicate error
	db	bell+80H
	jmp	ifstat		;no condition, display current condition
;
; Process register - register value is in A
;
	IF	IFOREG
runreg:
	push	psw		;save value
	call	getnum		;extract value in FCB2 as a number
	pop	psw		;get value
	cmp	b		;compare against extracted value
	jrz	ifctrue		;TRUE if match
	jr	ifcfalse	;FALSE if non-match
	ENDIF		;IFOREG
;
; Process conditional test - address of conditional routine is in HL
;
runcond:
	pchl			;"call" routine pted to by HL
;
	ENDIF		;NOT COMIF
;

;
; Condition:  NULL (2nd file name)
;
	IF	IFONULL
ifcnull:
	lda	fcb2+1		;get first char of 2nd file name
	cpi	' '		;space = null
	jrz	ifctrue
	jr	ifcfalse
	ENDIF		;IFONULL

;
; Condition:  TCAP
;
	IF	IFOTCAP
ifctcap:
	lda	z3env+80H	;get first char of Z3 TCAP Entry
	cpi	' '+1		;space or less = none
	jrc	ifcfalse
	jr	ifctrue
	ENDIF		;IFOTCAP

;
; Condition:  WHEEL
;
	IF	IFOWHEEL
ifcwheel:
	lhld	z3env+29h	;get address of wheel byte
	mov	a,m		;get byte
	ora	a		;test for true
	jrz	ifcfalse	;FALSE if 0
	jr	ifctrue
	ENDIF		;IFOWHEEL
;
; Condition:  TRUE
;	IFCTRUE  enables an active IF
; Condition:  FALSE
;	IFCFALSE enables an inactive IF
;
ifctrue:
;
	IF	IFONEG
	call	negtest	;test for negate
	jrz	ifcf
	ENDIF		;IFONEG
;
ifct:
	mvi	b,0ffh	;active
	jmp	ifset
ifcfalse:
;
	IF	IFONEG
	call	negtest	;test for negate
	jrz	ifct
	ENDIF		;IFONEG
;
ifcf:
	mvi	b,0	;inactive
	jmp	ifset

;
; Condition: INPUT (from user)
;
	IF	IFOINPUT
ifcinput:
	lxi	h,z3msg+7	;pt to ZEX message byte
	mvi	m,10b		;suspend ZEX input
	push	h		;save ptr to ZEX message byte
	IF	NOT NOISE
	call	nl
	ENDIF		;NOT NOISE
	call	prif
	call	print
	db	'True?',' '+80H
	mvi	c,1		;input from console
	call	bdos
	pop	h		;get ptr to ZEX message byte
	mvi	m,0		;return ZEX to normal processing
	cpi	' '		;yes?
	jrz	ifctrue
	ani	5fh		;mask and capitalize user input
	cpi	'T'		;true?
	jrz	ifctrue
	cpi	'Y'		;yes?
	jrz	ifctrue
	cpi	CR		;yes?
	jrz	ifctrue
	jr	ifcfalse
	ENDIF		;IFOINPUT

;
; Condition: EXIST filename.typ
;
	IF	IFOEXIST
ifcex:
	call	tlog	;log into DU
	lxi	d,fcb2	;pt to fcb
	mvi	c,17	;search for first
	call	bdos
	inr	a	;set zero if error
	jrz	ifcfalse	;return FALSE
	jr	ifctrue		;return TRUE
	ENDIF		;IFOEXIST

;
; Condition: EMPTY filename.typ
;
	IF	IFOEMPTY
ifcempty:
	call	tlog		;log into FCB2's DU
	lxi	d,fcb2		;pt to fcb2
	mvi	c,15		;open file
	push	d		;save fcb ptr
	call	bdos
	pop	d
	inr	a		;not found?
	jrz	ifctrue
	mvi	c,20		;try to read a record
	call	bdos
	ora	a		;0=OK
	jrnz	ifctrue		;NZ if no read
	jr	ifcfalse
	ENDIF		;IFOEMPTY

;
; Condition: ERROR
;
	IF	IFOERROR
ifcerror:
	lda	z3msg+6		;get error byte
	ora	a		;0=TRUE
	jrz	ifctrue
	jr	ifcfalse
	ENDIF		;IFOERROR

;
; **** Support Routines ****
;

;
; Convert chars in FCB2 into a number in B
;
	IF	IFOREG
getnum:
	mvi	b,0	;set number
	lxi	h,fcb2+1	;pt to first char
getn1:
	mov	a,m	;get char
	inx	h	;pt to next
	sui	'0'	;convert to binary
	rc		;done if error
	cpi	10	;range?
	rnc		;done if out of range
	mov	c,a	;value in C
	mov	a,b	;A=old value
	add	a	;*2
	add	a	;*4
	add	b	;*5
	add	a	;*10
	add	c	;add in new digit value
	mov	b,a	;result in B
	jr	getn1	;continue processing
	ENDIF		;IFOREG

;
; Log into DU in FCB2
;
	IF	NOT COMIF
tlog:
	lda	fcb2	;get disk
	ora	a	;current?
	jrnz	tlog1
	mvi	c,25	;get disk
	call	bdos
	inr	a	;increment for following decrement
tlog1:
	dcr	a	;A=0
	mov	e,a	;disk in E
	mvi	c,14
	call	bdos
	lda	fcb2+13	;pt to user
	mov	e,a
	mvi	c,32	;set user
	jmp	bdos
;
	ENDIF		;NOT COMIF

;
; Test of Negate Flag = negchar
;
	IF	IFONEG
negtest:
negflag	equ	$+1		;pointer for in-the-code modification
	mvi	a,0		;2nd byte is filled in
	cpi	negchar		;test for No
	ret
	ENDIF		;IFONEG

;
; Test FCB1 against a single digit (0-9)
;  Return with register value in A and NZ if so
;
	IF	IFOREG
regtest:
	ldax	d		;get digit
	sui	'0'
	jrc	zret		;Z flag for no digit
	cpi	10		;range?
	jrnc	zret		;Z flag for no digit
	lxi	h,z3msg+30H	;pt to registers
	add	l		;pt to register
	mov	l,a
	mov	a,h		;add in H
	aci	0
	mov	h,a
	xra	a		;set NZ
	dcr	a
	mov	a,m		;get register value
	ret
zret:
	xra	a		;set Z
	ret
	ENDIF		;IFOREG

;
; Test to see if a current IF is running and if it is FALSE
;   If so, return with Zero Flag Set (Z)
;   If not, return with Zero Flag Clear (NZ)
; Affect only HL and PSW
;
iftest:
	lxi	h,z3msg+1	;get IF flag
	mov	a,m		;test for active IF
	ora	a
	jrz	ifok		;no active IF
	inx	h		;pt to active flag
	ana	m		;check active flag
	rz			;return Z since IF running and FALSE
ifok:
	xra	a		;return NZ for OK
	dcr	a
	ret

;
; Test FCB1 against condition table (must have 2-char entries)
;  Return with routine address in HL if match and NZ flag
;
	IF	NOT COMIF
condtest:
	lxi	h,condtab	;pt to table
condt1:
	mov	a,m		;end of table?
	ora	a
	rz
	ldax	d		;get char
	mov	b,m		;get other char in B
	inx	h		;pt to next
	inx	d
	cmp	b		;compare entries
	jrnz	condt2
	ldax	d		;get 2nd char
	cmp	m		;compare
	jrnz	condt2
	inx	h		;pt to address
	mov	a,m		;get address in HL
	inx	h
	mov	h,m
	mov	l,a		;HL = address
	xra	a		;set NZ for OK
	dcr	a
	ret
condt2:
	lxi	b,3		;pt to next entry
	dad	b		; ... 1 byte for text + 2 bytes for address
	dcx	d		;pt to 1st char of condition
	jr	condt1
;
	ENDIF		;NOT COMIF
;
; Turn on next IF level
;   B register is 0 if level is inactive, 0FFH is level is active
;   Return with Z flag set if OK
;
ifset:
	lxi	h,z3msg+1	;get IF flag
	mov	a,m
	ora	a		;if no if at all, start 1st one
	jrz	ifset1
	cpi	80h		;check for overflow (8 IFs max)
	jrz	iferr
	inx	h		;pt to active IF byte
	ana	m		;check to see if current IF is TRUE
	jrnz	ifset0		;if TRUE, proceed
	mvi	b,0		;set False IF
ifset0:
	dcx	h		;pt to IF level
	mov	a,m		;get it
	rlc			;advance to next level
	ani	0feh		;only 1 bit on
	mov	m,a		;set IF byte
	jr	ifset2
ifset1:
	inr	a		;A=1
	mov	m,a		;set 1st IF
	inx	h		;clear active IF byte
	mvi	m,0
	dcx	h
ifset2:
	mov	d,a		;get IF byte
	ana	b		;set interested bit
	mov	b,a
	inx	h		;pt to active flag
	mov	a,d		;complement IF byte
	cma
	mov	d,a
	mov	a,m		;get active byte
	ana	d		;mask in only uninterested bits
	ora	b		;mask in complement of interested bit
	mov	m,a		;save result
	call	ifstat		;print status
	xra	a		;return with Z
	ret
iferr:
	call	print		;beep to indicate overflow
	db	bell+80H
	xra	a		;set NZ
	dcr	a
	ret

;
; Test for Size Error
;
	if	($ GT (FCP + FCPS*128))
sizerr	equ	novalue	;FCP is too large for buffer
	endif

	end
