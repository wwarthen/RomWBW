;
;==================================================================================================
; eZ80 UART DRIVER (SERIAL PORT)
;==================================================================================================
;

UART0_LSR	.EQU	$C5
UART0_THR       .EQU	$C0

LSR_THRE	.EQU	$20

#DEFINE IN0_A(p)	.DB	$ED,$38,p
#DEFINE OUT0_A(p)	.DB	$ED,$39,p

; #DEFINE CALLIL(a,b)	.DB	$5B,$CD \	.DW b	\ .DB b

EZUART_PREINIT:
	LD	E, 'A'
	CALL	EZUART_OUT
	LD	E, 'B'
	CALL	EZUART_OUT
	LD	E, 'C'
	CALL	EZUART_OUT
	LD	E, 'D'
	CALL	EZUART_OUT
	LD	E, 13
	CALL	EZUART_OUT
	LD	E, 10
	CALL	EZUART_OUT
	RET

EZUART_INIT:
	LD	E, '1'
	CALL	EZUART_OUT
	LD	E, '2'
	CALL	EZUART_OUT
	LD	E, '3'
	CALL	EZUART_OUT
	LD	E, '4'
	CALL	EZUART_OUT
	LD	E, 13
	CALL	EZUART_OUT
	LD	E, 10
	CALL	EZUART_OUT

	;call.il, $001000
	.db	$5B,$CD
	.dw	$1000
	.db	$00

	RET

EZUART_IN:

;
; OUT CHAR IN E
EZUART_OUT:
	; WAIT FOR UART TO BE READY FOR TX
WAIT_FOR_TX_READY:
	; IN0	A,(UART0_LSR)		; /*ED38C5*/
	IN0_A	(UART0_LSR)
	AND	LSR_THRE
	JR	Z,WAIT_FOR_TX_READY
     
	; SEND THE CHAR
	LD	A, E
	; OUT0	(UART0_LSR),A		; ED39C0
	OUT0_A	(UART0_THR)
	RET

EZUART_IST:
EZUART_OST:
EZUART_INITDEV:
EZUART_QUERY:
EZUART_DEVICE:
	RET
	
EZUART_FNTBL:
	.DW	EZUART_IN
	.DW	EZUART_OUT
	.DW	EZUART_IST
	.DW	EZUART_OST
	.DW	EZUART_INITDEV
	.DW	EZUART_QUERY
	.DW	EZUART_DEVICE
#IF (($ - EZUART_FNTBL) != (CIO_FNCNT * 2))
	.ECHO	"*** INVALID EZUART FUNCTION TABLE ***\n"
