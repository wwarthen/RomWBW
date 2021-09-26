;==================================================================================================
; Z80 DMA DRIVER
;==================================================================================================
;
#INCLUDE "std.asm"
;
;
DMA_CONTINUOUS			.equ 	%10111101	; + Pulse
DMA_BYTE			.equ 	%10011101	; + Pulse
DMA_BURST 			.equ	%11011101	; + Pulse
DMA_LOAD			.equ	$cf 		; %11001111
DMA_ENABLE			.equ	$87		; %10000111
DMA_FORCE_READY 		.equ 	$b3
DMA_DISABLE			.equ	$83
DMA_START_READ_SEQUENCE		.equ	$a7
DMA_READ_STATUS_BYTE		.equ	$bf
DMA_READ_MASK_FOLLOWS		.equ	$bb
DMA_RESET			.equ	$c3
;DMA_RESET_PORT_A_TIMING	.equ	$c7
;DMA_RESET_PORT_B_TIMING	.equ	$cb
;DMA_CONTINUE			.equ	$d3
;DMA_DISABLE_INTERUPTS		.equ	$af
;DMA_ENABLE_INTERUPTS		.equ	$ab
;DMA_RESET_DISABLE_INTERUPTS	.equ 	$a3
;DMA_ENABLE_AFTER_RETI		.equ	$b7
;DMA_REINIT_STATUS_BYTE		.equ	$8b
;
DMA_FBACK			.equ	TRUE	; ALLOW FALLBACK TO SOFTWARE
DMA_USEHS			.equ	TRUE	; USE CLOCK DIVIDER
;
;DMAMODE				.SET	DMAMODE_ECB
;
#IF (DMAMODE=DMAMODE_MBC)
DMA_RDY				.EQU	%00000000
DMA_FORCE			.EQU	1
DMA_USEHS			.SET	FALSE
#ENDIF
#IF (DMAMODE=DMAMODE_ECB)
DMA_RDY				.EQU	%00001000
DMA_FORCE			.EQU	0
DMA_USEHS			.SET	TRUE
#ENDIF
;
;==================================================================================================
; MAIN DMA MONITOR ROUTINE
;==================================================================================================
;
	.ORG		$0100
;
MAIN:
	LD	(SAVSTK),SP		; SETUP LOCAL
	LD	SP,STACK		; STACK
;
	call	PRTSTRD			; WELCOME
	.db	"DMA MONITOR\n\r$"
;
MENULP:	CALL	DISPM			; DISPLAY MENU
	CALL	CIN			; GET SELECTION
;
	CP	'D'
	JP	Z,DMATST_D
	CP	'I'
	JP	Z,DMATST_I
	CP	'M'
	JP	Z,DMATST_M
	CP	'R'
	JP	Z,DMATST_R
	CP	'Y'
	JP	Z,DMATST_Y
	CP	'X'
	JR	Z,DMABYE
;
	JR	MENULP
;
DMABYE:	LD	SP,(SAVSTK)		; RESTORE CP/M STACK
	RET
;
DMATST_I:
	call	PRTSTRD
	.db	"\n\rSTART DMA_INIT\n\r$"
	CALL	DMA_INIT
	JP	MENULP
;
DMATST_M:
	call	PRTSTRD
	.db	"\n\rSTART DMAMemMove\n\r$"
	CALL	DMAMemMove
	JP	MENULP
;
DMATST_D:
	call	PRTSTRD
	.db	"\n\rSTART DMARegDump\n\r$"
	CALL	DMARegDump
	JP	MENULP
;
DMATST_Y:
	call	PRTSTRD
	.db	"\n\r\Y READY\n\r$"
;	CALL	
	JP	MENULP
;
DMATST_R:
	call	PRTSTRD
	.db	"R RESET\n\r$"
;	CALL	
	JP	MENULP

;
DISPM:	call	PRTSTRD
	.db	"\n\rDMA DEVICE: $"
	LD	C,DMAMODE_MBC		; DISPLAY
	LD	A,00000011B		; TARGET
	LD	DE,DMA_DEV_STR		; DEVICE
	CALL	PRTIDXMSK
	CALL	NEWLINE
;
	call	PRTSTRD
	.db	"DMA PORT: $"
	LD	A,DMABASE		; DISPLAY
	CALL	PRTHEXBYTE		; DMA PORT
	CALL	NEWLINE
;
	LD	HL,MENU_OPT		; DISPLAY
	CALL	PRTSTR			; MENU OPTIONS
;
	RET
;
#INCLUDE "util.asm"
;
;==================================================================================================
; DMA INITIALIZATION CODE
;==================================================================================================
;
DMA_INIT:
	CALL	NEWLINE
	PRTS("DMA: IO=0x$")		; announce
	LD	A, DMABASE
	CALL	PRTHEXBYTE
;
	LD	A,DMA_FORCE
	out	(DMABASE+1),a		; force ready off
;
#IF (DMA_USEHS)
	ld	a,(HB_RTCVAL)
	or	%00001000		; half
	out	(RTCIO),a		; clock
#ENDIF
;
	call	DMAProbe		; do we have a dma?
	jr	nz,DMA_NOTFOUND
;
	call	PRTSTRD
	.db	" DMA FOUND\n\r$"
;
	ld	hl,DMACode		; program the
	ld	b,DMACode_Len		; dma command
	ld	c,DMABASE		; block
;
	di
	otir				; load dma
	ei
	xor	a			; set status
;
DMA_EXIT:
#IF (DMA_USEHS)
	push	af
	ld	a,(HB_RTCVAL)
	and	%11110111		; full
	out	(RTCIO),a		; clock
	pop	af
#ENDIF
	ret
;
DMA_NOTFOUND:
	push	af
	call	PRTSTRD
	.db	" NOT PRESENT$"

#IF (DMA_FBACK)
	call	PRTSTRD
	.db	". USING SOFTWARE$"
	LD	A,ERR_NOHW
	LD	(DMA_FAIL_FLAG),A
#ENDIF
	pop	af
	jr	DMA_EXIT
;
DMA_FAIL_FLAG:
	.db	0
;	
DMA_DEV_STR:
	.TEXT	"NONE$"
	.TEXT	"ECB$"
	.TEXT	"Z180"
	.TEXT	"Z280$"
	.TEXT	"MBC$"
;
MENU_OPT:
	.TEXT	"\n\r"
	.TEXT	"I) Initialize DMA\n\r"
	.TEXT	"M) Memory to Memory test\n\r"
	.TEXT	"P) Port select test\n\r"
	.TEXT	"R) Reset bit test\n\r"
	.TEXT	"Y) Ready bit test\n\r"
	.TEXT	"X) Exit\n\r"

	.TEXT	">$"
;
;==================================================================================================
; DMA MEMORY MOVE
;==================================================================================================
;
DMAMemMove:
;
	LD	HL,$8000	; PREFILL DESTINATION WITH $55
	LD	A,$55
	LD	(HL),A
	LD	DE,$8001
	LD	BC,4096-1
	LDIR
;
	LD	HL,PROEND	; FILL SOURCE WITH $AA
	LD	A,$AA
	LD	(HL),A
	LD	DE,PROEND+1
	LD	BC,4096-1
	LDIR
;
	LD	HL,PROEND	; DMA COPY
	LD	DE,$8000
	LD	BC,4096-1
	CALL	DMALDIR

;
;	LD	HL,$8400	; PLANT
;	LD	A,$00		; BAD
;	LD	(HL),A		; SEED
;
	LD	A,$AA		; CHECK COPY SUCCESSFULL
	LD	HL,$8000
	LD	BC,4096
NXTCMP:	CPI
	JP	PO,CMPOK
	JR	Z,NXTCMP

	call	PRTHEXWORD
	call	PRTSTRD
	.db	" TEST MEMORY MOVE FAILED\n\r$"
	RET

CMPOK:	call	PRTSTRD
	.db	"TEST MEMORY MOVE SUCCEEDED\n\r$"
	RET
;
;==================================================================================================
; DMA PROBE - WRITE TO ADDRESS REGISTER AND READ BACK
;==================================================================================================
;
DMAProbe:
	ld	a,DMA_RESET	
	out	(DMABASE),a
	ld	a,%01111101 		; R0-Transfer mode, A -> B, start address follows
	out	(DMABASE),a
	ld	a,$cc
	out	(DMABASE),a
	ld	a,$dd
	out	(DMABASE),a
	ld	a,$e5
	out	(DMABASE),a
	ld	a,$1a
	out	(DMABASE),a
	ld	a,DMA_LOAD
	out	(DMABASE),a
;
	ld	a,DMA_READ_MASK_FOLLOWS	; set up
	out	(DMABASE),a		; for 
	ld	a,%00011000		; register
	out	(DMABASE),a		; read
	ld	a,DMA_START_READ_SEQUENCE
	out	(DMABASE),a
;
	in	a,(DMABASE)		; read in 
	ld	c,a			; address
	in	a,(DMABASE)
	ld	b,a
;
	xor	a			; is it
	ld	hl,$ddcc		; a match
	sbc	hl,bc			; return with
	ret	z			; status
	cpl
	ret
;
DMACode		;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111101 	; R0-Transfer mode, A -> B, start address, block length follow
		.dw	0		; R0-Port A, Start address
		.dw	0 		; R0-Block length
		.db	%00010100	; R1-No timing bytes follow, address increments, is memory
		.db	%00010000 	; R2-No timing bytes follow, address increments, is memory
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled
		.db	DMA_CONTINUOUS	; R4-Continuous mode, destination address, interrupt and control byte follow
		.dw	0 		; R4-Port B, Destination address
		.db	%00001100	; R4-Pulse byte follows, Pulse generated
		.db	0		; R4-Pulse offset
		.db	%10010010+DMA_RDY; R5-Stop on end of block, ce/wait multiplexed, READY active config
		.db	DMA_LOAD 	; R6-Command Load
;		.db	DMA_FORCE_READY	; R6-Command Force ready
;		.db	DMA_ENABLE 	; R6-Command Enable DMA
DMACode_Len 	.equ	$-DMACode
;
;==================================================================================================
; DMA COPY BLOCK CODE -  ASSUMES DMA PREINITIALIZED
;==================================================================================================
;
DMALDIR:
	ld	(DMASource),hl		; populate the dma
	ld	(DMADest),de		; register template
	ld	(DMALength),bc
;
	ld	hl,DMACopy		; program the
	ld	b,DMACopy_Len		; dma command
	ld	c,DMABASE		; block
;
#IF (DMA_USEHS)
	ld	a,(HB_RTCVAL)
	or	%00001000		; half
	out	(RTCIO),a		; clock
#ENDIF
	di
	otir				; load and execute dma
	ei
;
	ld	a,DMA_READ_STATUS_BYTE	; check status
	out	(DMABASE),a		; of transfer
	in	a,(DMABASE)		; set non-zero
	and	%00111011		; if failed
	sub	%00011011
#IF (DMA_USEHS)
	push	af
	ld	a,(HB_RTCVAL)
	and	%11110111		; full
	out	(RTCIO),a		; clock
	pop	af
#ENDIF
	ret
;
DMACopy 	;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111101 	; R0-Transfer mode, A -> B, start address, block length follow
DMASource	.dw	0 		; R0-Port A, Start address
DMALength	.dw	0 		; R0-Block length
		.db	%00010100	; R1-No timing bytes follow, address increments, is memory
		.db	%00010000 	; R2-No timing bytes follow, address increments, is memory
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled
		.db	DMA_CONTINUOUS	; R4-Continuous mode, destination address, interrupt and control byte follow
DMADest		.dw	0 		; R4-Port B, Destination address
		.db	%00001100	; R4-Pulse byte follows, Pulse generated
		.db	0		; R4-Pulse offset
;		.db	%10010010+DMA_RDY;R5-Stop on end of block, ce/wait multiplexed, READY active config
		.db	DMA_LOAD 	; R6-Command Load
		.db	DMA_FORCE_READY	; R6-Command Force ready
		.db	DMA_ENABLE 	; R6-Command Enable DMA
DMACopy_Len 	.equ	$-DMACopy
;
;==================================================================================================
; DMA I/O OUT BLOCK CODE - ADDRESS TO I/O PORT
;==================================================================================================
;
DMAOTIR:
	ld	(DMAOutSource),hl	; populate the dma
	ld	(DMAOutDest),a		; register template
	ld	(DMAOutLength),bc	
;
	ld	hl,DMAOutCode		; program the
	ld	b,DMAOut_Len		; dma command
	ld	c,DMABASE		; block
;
#IF (DMA_USEHS)
	ld	a,(HB_RTCVAL)
	or	%00001000		; half
	out	(RTCIO),a		; clock
#ENDIF
	di
	otir				; load and execute dma
	ei
;
	ld	a,DMA_READ_STATUS_BYTE	; check status
	out	(DMABASE),a		; of transfer
	in	a,(DMABASE)		; set non-zero
	and	%00111011		; if failed
	sub	%00011011
;
#IF (DMA_USEHS)
	push	af
	ld	a,(HB_RTCVAL)
	and	%11110111		; full
	out	(RTCIO),a		; clock
	pop	af
#ENDIF
	ret
;
DMAOutCode  	;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111001 	; R0-Transfer mode, B -> A (temp), start address, block length follow	
DMAOutSource	.dw	0 		; R0-Port A, Start address
DMAOutLength	.dw	0 		; R0-Block length

		.db	%00010100	; R1-No timing bytes follow, fixed incrementing address, is memory	
		.db	%00101000 	; R2-No timing bytes follow, address static, is i/o			
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled

		.db	%10100101	; R4-Continuous mode, destination port, interrupt and control byte follow
DMAOutDest	.db	0 		; R4-Port B, Destination port
;		.db	%00001100	; R4-Pulse byte follows, Pulse generated
;		.db	0		; R4-Pulse offset

		.db	%10010010+DMA_RDY;R5-Stop on end of block, ce/wait multiplexed, READY active config	
		.db	DMA_LOAD 	; R6-Command Load							
		.db	%00000101	; R0-Port A is Source							
		.db	DMA_LOAD 	; R6-Command Load							
		.db	DMA_FORCE_READY	; R6-Command Force ready						
		.db	DMA_ENABLE 	; R6-Command Enable DMA							
DMAOut_Len 	.equ	$-DMAOutCode
;
;==================================================================================================
; DMA I/O INPUT BLOCK CODE - I/O PORT TO ADDRESS
;==================================================================================================
;
DMAINIR:
	ld	(DMAInDest),hl		; populate the dma
	ld	(DMAInSource),a		; register template
	ld	(DMAInLength),bc	
;
	ld	hl,DMAInCode		; program the
	ld	b,DMAIn_Len		; dma command
	ld	c,DMABASE		; block
;
#IF (DMA_USEHS)
	ld	a,(HB_RTCVAL)
	or	%00001000		; half
	out	(RTCIO),a		; clock
#ENDIF
	di
	otir				; load and execute dma
	ei
;
	ld	a,DMA_READ_STATUS_BYTE	; check status
	out	(DMABASE),a		; of transfer
	in	a,(DMABASE)		; set non-zero
	and	%00111011		; if failed
	sub	%00011011
;
#IF (DMA_USEHS)
	push	af
	ld	a,(HB_RTCVAL)
	and	%11110111		; full
	out	(RTCIO),a		; clock
	pop	af
#ENDIF
	ret
;
DMAInCode 	;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111001 	; R0-Transfer mode, B -> A, start address, block length follow		
DMAInDest	.dw	0 		; R0-Port A, Start address
DMAInLength	.dw	0 		; R0-Block length
		.db	%00010100	; R1-No timing bytes follow, address increments, is memory		
		.db	%00111000 	; R2-No timing bytes follow, address static, is i/o			
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled
		.db	%10100101	; R4-Continuous mode, destination port, no interrupt, control byte.	
DMAInSource	.db	0 		; R4-Port B, Destination port
;		.db	%00001100	; R4-Pulse byte follows, Pulse generated
;		.db	0		; R4-Pulse offset
		.db	%10010010+DMA_RDY;R5-Stop on end of block, ce/wait multiplexed, READY active config	
		.db	DMA_LOAD 	; R6-Command Load							
		.db	DMA_FORCE_READY	; R6-Command Force ready						
		.db	DMA_ENABLE 	; R6-Command Enable DMA							

DMAIn_Len 	.equ	$-DMAInCode
;
;==================================================================================================
; DEBUG - READ START, DESTINATION AND COUNT REGISTERS
;==================================================================================================
;
;#IF (0)
;
DMARegDump:
	ld	a,DMA_READ_MASK_FOLLOWS
	out	(DMABASE),a
	ld	a,%01111110
	out	(DMABASE),a
	ld	a,DMA_START_READ_SEQUENCE
	out	(DMABASE),a
;
	in	a,(DMABASE)
	ld	c,a
	in	a,(DMABASE)
	ld	b,a
	call	PRTHEXWORD
	ld	a,':'
	call	COUT
;
	in	a,(DMABASE)
	ld	c,a
	in	a,(DMABASE)
	ld	b,a
	call	PRTHEXWORD
	ld	a,':'
	call	COUT
;
	in	a,(DMABASE)
	ld	c,a
	in	a,(DMABASE)
	ld	b,a
	call	PRTHEXWORD
;
	call	NEWLINE
	ret
;#ENDIF


;
;__COUT_______________________________________________________________________
;
;	OUTPUT CHARACTER FROM A
;_____________________________________________________________________________
;
COUT:
	; SAVE ALL INCOMING REGISTERS
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; OUTPUT CHARACTER TO CONSOLE VIA HBIOS
	LD	E,A			; OUTPUT CHAR TO E
	LD	C,CIO_CONSOLE		; CONSOLE UNIT TO C
	LD	B,BF_CIOOUT		; HBIOS FUNC: OUTPUT CHAR
	CALL	$FFF0			; HBIOS OUTPUTS CHARACTER
;
	; RESTORE ALL REGISTERS
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
;__CIN________________________________________________________________________
;
;	INPUT CHARACTER TO A
;_____________________________________________________________________________
;
CIN:
	; SAVE INCOMING REGISTERS (AF IS OUTPUT)
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; INPUT CHARACTER FROM CONSOLE VIA HBIOS
	LD	C,CIO_CONSOLE		; CONSOLE UNIT TO C
	LD	B,BF_CIOIN		; HBIOS FUNC: INPUT CHAR
	CALL	$FFF0			; HBIOS READS CHARACTER
	LD	A,E			; MOVE CHARACTER TO A FOR RETURN
;
	; RESTORE REGISTERS (AF IS OUTPUT)
	POP	HL
	POP	DE
	POP	BC
	RET
;
;__CST________________________________________________________________________
;
;	RETURN INPUT STATUS IN A (0 = NO CHAR, !=0 CHAR WAITING)
;_____________________________________________________________________________
;
CST:
	; SAVE INCOMING REGISTERS (AF IS OUTPUT)
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; GET CONSOLE INPUT STATUS VIA HBIOS
	LD	C,CIO_CONSOLE		; CONSOLE UNIT TO C
	LD	B,BF_CIOIST		; HBIOS FUNC: INPUT STATUS
	CALL	$FFF0			; HBIOS RETURNS STATUS IN A
;
	; RESTORE REGISTERS (AF IS OUTPUT)
	POP	HL
	POP	DE
	POP	BC
	RET

SAVSTK:	.DW	2
	.FILL	64
STACK:	.EQU	$
PROEND:	.EQU	$
;
	.end
