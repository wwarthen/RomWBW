		.page
;********************************************************
; These are I/O functions for the CCS 2710 four-port
; serial I/O board.
;
; Bob Applegate, 02/16/2008
;
SIObase		.equ	0E0H
;
SIODATA		.equ	SIObase
SIOBAUDL	.equ	SIObase		;also used for baud rate
SIOINTEN	.equ	SIObase+1
SIOBAUDH	.equ	SIObase+1	;ditto
SIOIDENT	.equ	SIObase+2
SIOLCTRL	.equ	SIObase+3
SIOMDMCT	.equ	SIObase+4
SIOLSTAT	.equ	SIObase+5
SIOMDMST	.equ	SIObase+6
BAUD03		.equ	0180H	;divisor for 300 baud
BAUD12		.equ	060H	;1200 baud
BAUD_2400	.equ	030h	;2400 baud
BAUD96		.equ	00CH	;9600 baud
DATRDY		.equ	01H	;rec'd data ready
TXMTY		.equ	20H	;transmitter holding reg empty
HSMSK		.equ	20H

BAUD_RATE	.equ	BAUD_2400

;
; This function initializes the main console port for the
; default baud rate.
;
initser:	ld	a,0fH
		out	(SIOMDMCT),a
		ld	a,083H		;enable divisor latch access
		out	(SIOLCTRL),a
		ld	a,BAUD_RATE / 256	;get hi byte
		out	(SIOBAUDH),a
		ld	a,BAUD_RATE % 256	;get low byte
		out	(SIOBAUDL),a
		ld	a,03H		;8 data bits, one stop bit, no parity
		out	(SIOLCTRL),a
		xor	a		;clear acc
		out	(SIOINTEN),a	;disable ints
		out	(SIOLSTAT),a	;clear status
		in	a,(SIODATA)	;clear out any garbage in rec'd data reg
		ret
;
; TTY output of character in C.  Modifies A.
;
ttyout:		IN	A,(SIOLSTAT)		;was A,TTS, read status port
		AND	TXMTY		;check buffer empty bit
		JR	Z,ttyout		;branch if not empty
		LD	A,C
		OUT	(SIODATA),A		;was TTO,A, send out character
		RET			;thassit
;
; Check to see if a character is ready to be read from the TTY.
; Returns TRUE (0ffh) in A is there is a character waiting, or
; FALSE (0) if there is nothing.
;
ttystat:	IN	A,(SIOLSTAT)		;was A,TTS
		AND	DATRDY
		LD	A,TRUE		;was FALSE
		RET	NZ
		CPL
		RET
;
; This gets the next character from the TTY and returns it in A.
; This will block if there is nothing waiting.
;
ttyin:		IN	A,(SIOLSTAT)		;read status reg
		AND	DATRDY		;look for data ready
		JR	Z,ttyin		;wait for char
		IN	a,(SIODATA)		;read character
		RET
		.page
