;==================================================================================================
; Z80 DMA TEST UTILITY
;==================================================================================================
;
FALSE		.EQU	0
TRUE		.EQU	~FALSE
;
; HELPER MACROS
;
#DEFINE	PRTC(C)	CALL PRTCH \ .DB C	; PRINT CHARACTER C TO CONSOLE - PRTC('X')
#DEFINE	PRTS(S)	CALL PRTSTRD \ .TEXT S	; PRINT STRING S TO CONSOLE - PRTD("HELLO")
#DEFINE	PRTX(X) CALL PRTSTRI \ .DW X	; PRINT STRING AT ADDRESS X TO CONSOLE - PRTI(STR_HELLO)
;
; SYSTEM SPEED CAPABILITIES
;
SPD_FIXED	.EQU	0		; PLATFORM SPEED FIXED AND CANNOT CHANGE SPEEDS
SPD_HILO	.EQU	1		; PLATFORM CAN CHANGE BETWEEN TWO SPEEDS
;
; INTERRUPT TESTING CONFIGURATION
; N.B., INTERRUPT TESTING REQUIRES ROMWBW!!!
; ASSUMES SYSTEM IS ALREADY CONFIGURED FOR IM2 OPERATION
; INTIDX MUST BE SET TO AN UNUSED INTERRUPT SLOT
;		
INTENABLE	.EQU	TRUE		; ENABLE INT TESTING
INTIDX		.EQU	1		; INT VECTOR INDEX
;
; SYSTEM SPEED CHARACTERISTICS
;
SPD_UNSUP	.EQU	0		; PLATFORM CAN CHANGE SPEEDS BUT IS UNSUPPORTED
SPD_HIGH	.EQU	1		; PLATFORM CAN CHANGE SPEED, STARTS HIGH
SPD_LOW		.EQU	2		; PLATFORM CAN CHANGE SPEED, STARTS LOW
;
; DMA MODE SELECTIONS
;
DMAMODE_NONE	.EQU	0
DMAMODE_ECB	.EQU	1		; ECB-DMA WOLFGANG KABATZKE'S Z80 DMA ECB BOARD
DMAMODE_Z180	.EQU	2		; Z180 INTEGRATED DMA
DMAMODE_Z280	.EQU	3		; Z280 INTEGRATED DMA
DMAMODE_RC	.EQU	4		; RC2014 Z80 DMA
DMAMODE_MBC	.EQU	5		; MBC
;
DMABASE		.EQU	$E0		; DMA: DMA BASE ADDRESS
RTCIO		.EQU	$70		; RTC / SPEED PORT
HB_RTCVAL	.EQU	$FFEE		; HB_RTCVAL
;
CPUSPDCAP	.EQU	SPD_HILO	; CPU SPEED CHANGE CAPABILITY SPD_FIXED|SPD_HILO
CPUSPDDEF	.EQU	SPD_HIGH	; SPD_UNSUP|SPD_HIGH|SPD_LOW
;
DMAMODE		.EQU	DMAMODE_MBC
DMA_USEHS	.EQU	TRUE		; USE CLOCK DIVIDER
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
DMA_ENABLE_INTERUPTS		.equ	$ab
;DMA_RESET_DISABLE_INTERUPTS	.equ 	$a3
;DMA_ENABLE_AFTER_RETI		.equ	$b7
DMA_REINIT_STATUS_BYTE		.equ	$8b
;
DMA_RDY				.EQU	%00001000
DMA_FORCE			.EQU	0
;
bf_sysint			.equ	$FC	; INT function
;		
bf_sysintinfo			.equ	$00	; INT INFO subfunction
bf_sysintget			.equ	$10	; INT GET subfunction
bf_sysintset			.equ	$20	; INT SET subfunction
;
#IF (DMA_USEHS & (DMAMODE=DMAMODE_MBC))
#IF (CPUSPDDEF=SPD_HIGH)
#DEFINE DMAIOSLO LD A,(HB_RTCVAL) \ AND %11110111 \ OUT (RTCIO),A 
#DEFINE DMAIONOR PUSH AF \ LD A,(HB_RTCVAL) \ OR %00001000 \ OUT (RTCIO),A \ POP AF
#ELSE
#DEFINE DMAIOSLO \;
#DEFINE DMAIONOR \;
#ENDIF
#ENDIF
;
#IF (DMA_USEHS & (DMAMODE=DMAMODE_ECB))
#IF (CPUSPDDEF=SPD_HIGH)
#DEFINE DMAIOSLO LD A,(HB_RTCVAL) \ OR  %00001000 \ OUT (RTCIO),A 
#DEFINE DMAIONOR PUSH AF \ LD A,(HB_RTCVAL) \ AND %11110111 \ OUT (RTCIO),A \ POP AF
#ELSE
#DEFINE DMAIOSLO \;
#DEFINE DMAIONOR \;
#ENDIF
#ENDIF

#IF (!DMA_USEHS)
#DEFINE DMAIOSLO \;
#DEFINE DMAIONOR \;
#ENDIF
;
;==================================================================================================
; MAIN DMA MONITOR ROUTINE
;==================================================================================================
;
	.ORG	$0100
;
MAIN:
	LD	(SAVSTK),SP		; SETUP LOCAL
	LD	SP,STACK		; STACK
;
	call	PRTSTRD			; WELCOME
	.db	"\n\rDMA Monitor V2\n\r$"
;
#IF (INTENABLE)
;
	; Install interrupt handler in upper mem
	ld	hl,reladr
	ld	de,$A000
	ld	bc,hsiz
	ldir
;
	; Install interrupt vector (RomWBW specific!!!)
	ld	hl,int		; pointer to my interrupt handler
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	e,INTIDX	; vector idx
	di
	rst	08		; do it
	ld	(orgvec),hl	; save the original vector
	ei			; interrupts back on
;
#ENDIF
;
MENULP:	CALL	DISPM			; DISPLAY MENU
	CALL	CIN			; GET SELECTION
	; Force upper case
	CP	'a'			; < 'a'
	JR	C,MENULP1		; IF SO, JUST CONTINUE
	CP	'z'+1			; > 'z'
	JR	NC,MENULP1		; IS SO, JUST CONTINUE
	SUB	'a'-'A'			; CONVERT TO UPPER
;
MENULP1:
	CALL	NEWLINE
	CP	'D'
	JP	Z,DMATST_D		; DUMP REGISTERS
	CP	'I'
	JP	Z,DMATST_I		; INITIALIZE
#IF (INTENABLE)
	CP	'T'
	JP	Z,DMATST_T		; TOGGLE INT USAGE
#ENDIF
	CP	'M'
	JP	Z,DMATST_M		; MEMORY COPY
	CP	'N'
	JP	Z,DMATST_N		; MEMORY COPY ITER
	CP	'0'
	JP	Z,DMATST_01
	CP	'1'
	JP	Z,DMATST_01
	CP	'R'
	JP	Z,DMATST_R		; TOGGLE RESET
	CP	'Y'
	JP	Z,DMATST_Y		; TOGGLE READY
	CP	'X'
	JP	Z,DMABYE		; EXIT
;
	JR	MENULP
;
DMABYE:
#IF (INTENABLE)
	; Deinstall interrupt vector
	ld	hl,(orgvec)	; original vector
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	e,INTIDX	; vector idx
	di
	rst	08		; do it
	ei			; interrupts back on
#ENDIF
;
	LD	SP,(SAVSTK)		; RESTORE CP/M STACK
	RET
;
DMATST_I:
	call	PRTSTRD
	.db	"\n\rStart Initialization\n\r$"
	CALL	DMA_INIT
	JP	MENULP
;
#IF (INTENABLE)
;
DMATST_T:
	LD	A,(USEINT)
	XOR	$FF
	LD	(USEINT),A
	JP	MENULP
;
#ENDIF
;
DMATST_M:
	call	PRTSTRD
	.db	"\n\rPerforming Memory-Memory Copy Test\n\r$"
	CALL	DMAMemTest
	JP	MENULP
;
DMATST_N:
	call	PRTSTRD
	.db	"\n\rPerforming Iterative Memory-Memory Copy Test\n\r$"
	CALL	DMAMemTestIter
	JP	MENULP
;
DMATST_01:
	call	PRTSTRD
	.db	"\n\rPerforming Port Selection Test\n\r$"
	CALL	DMA_Port01
	JP	MENULP
;
DMATST_D:
	call	PRTSTRD
	.db	"\n\rDump Registers\n\r$"
	CALL	DMARegDump
	JP	MENULP
;
DMATST_Y:
	call	PRTSTRD
	.db	"\n\rPerforming Ready Bit Test\n\r$"
	CALL	DMA_ReadyT
	JP	MENULP
;
DMATST_R:
	call	PRTSTRD
	.db	"\n\rPerforming Reset\n\r$"
;	CALL	
	JP	MENULP
;==================================================================================================
; DISPLAY MENU
;==================================================================================================
;
DISPM:	call	PRTSTRD
	.db	"\n\rDMA Device: $"
	LD	C,DMAMODE		; DISPLAY
	LD	A,00000111B		; TARGET
	LD	DE,DMA_DEV_STR		; DEVICE
	CALL	PRTIDXMSK
;
	call	PRTSTRD
	.db	", Port=0x$"
	LD	A,DMABASE		; DISPLAY
	CALL	PRTHEXBYTE		; DMA PORT
;
#IF (INTENABLE)
;
	call	PRTSTRD
	.db	"\n\rInterrupts=$"
	LD	A,(USEINT)
	OR	A
	LD	A,'Y'
	JR	NZ,DISPM_INT
	LD	A,'N'
	JR	DISPM_INT
;
DISPM_INT:
	CALL	COUT
;
	call	PRTSTRD
	.db	", Interrupt Count=$"
	ld	hl,(counter)
	call	PRTDEC
;
#ENDIF
;
	call	NEWLINE
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
	DMAIOSLO
;
	call	DMAProbe		; do we have a dma?
	jr	nz,DMA_NOTFOUND
;
	call	PRTSTRD
	.db	" DMA Found\n\r$"
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
	DMAIONOR
	ret
;
DMA_NOTFOUND:
	push	af
	call	PRTSTRD
	.db	" NOT Present$"
	pop	af
	jr	DMA_EXIT
;
DMA_FAIL_FLAG:
	.db	0
;	
DMA_DEV_STR:
	.TEXT	"NONE$"
	.TEXT	"ECB$"
	.TEXT	"Z180$"
	.TEXT	"Z280$"
	.TEXT	"RC2014$"
	.TEXT	"MBC$"
;
MENU_OPT:
	.TEXT	"\n\r"
	.TEXT	"I) Initialize DMA\n\r"
	.TEXT	"T) Toggle Interrupt Usage\n\r"
	.TEXT	"M) Test Memory-Memory Copy\n\r"
	.TEXT	"N) Test Memory-Memory Copy Iteratively\n\r"
	.TEXT	"0) Test DMA Port Selection\n\r"
	.TEXT	"1) Test DMA Latch Port Selection\n\r"
	.TEXT	"Y) Test Ready Bit\n\r"
	.TEXT	"X) Exit\n\r"

	.TEXT	">$"
;
;==================================================================================================
; PULSE PORT
;==================================================================================================
;
DMA_Port01:
	call	PRTSTRD
	.db	"\r\nPulsing port 0x$"
	sub	'0'			; Calculate
	add	a,DMABASE		; Port to
	call	PRTHEXBYTE
	call	NEWLINE
	ld	c,a			; toggle
	ld	b,$20			; loop counter
portlp:	push	bc
	call	PC_PERIOD
	push	bc
	ld	b,0
	ld	a,0
portlp1:out	(c),a
	djnz	portlp1
	pop	bc
	call	delay	
	pop	bc
	djnz	portlp
	call	NEWLINE
	JP	MENULP
;
delay:	push	bc
	ld	bc,0
dlylp:	dec	bc
	ld	a,b
	or	c
	jr	nz,dlylp
	pop	bc
	ret
;
;==================================================================================================
; TOGGLE READY BIT
;==================================================================================================
;
DMA_ReadyT:
	call	NEWLINE
	ld	c,DMABASE+1		; toggle
	ld	b,$20			; loop counter
portlp2:push	bc
	ld	a,b
	call	PRTDECB
	call	PRTSTRD
	.db	": ON$"
	call	delay
	ld	a,$FF
	ld	c,DMABASE+1
	out	(c),a
	call	PRTSTRD
	.db	" -> OFF$"
	call	delay
	call	PRTSTRD
	.db	"\r               \r$"
	ld	c,DMABASE+1
	ld	a,0
	out	(c),a
	pop	bc
	djnz	portlp2
	ret
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
	LD	A,(USEINT)	; USE INTS?
	OR	A		; TEST VALUE
	JR	NZ,DMAMemMove1	; IF SO, DO SO
	CALL	DMALDIR		; ELSE NORMAL DMA
	JR	DMAMemMove2
;
DMAMemMove1:
	CALL	DMALDIRINT	; DMA W/ INTERRUPTS
;
DMAMemMove2:
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
	RET			; RET W/ ZF CLEAR
;
CMPOK:
	RET			; RET W/ ZF SET
;
;==================================================================================================
; DMA MEMORY TEST
;==================================================================================================
;
DMAMemTest:
	call	DMAMemMove	; do a single memory copy
	jr	z,DMAMemTestOK
	jr	DMAMemTestFail
;
DMAMemTestOK:
	call	PRTSTRD
	.db	"\n\rMemory-Memory Test Passed\n\r$"
	ret
;
DMAMemTestFail:
	call	PRTSTRD
	.db	"\n\rMemory-Memory Test Failed\n\r$"
	ret
;
;==================================================================================================
; DMA MEMORY MOVE ITERATIVE
;==================================================================================================
;
DMAMemTestIter:
	ld	b,$20		; loop counter
	call	PRTSTRD
	.db	"\n\rPerforming $"
	ld	a,b
	call	PRTDECB
	call	PRTSTRD
	.db	" iterations, '.'=OK, '*'=Fail\n\r$"
DMAMemTestIterLoop:
	push	bc		; save loop control
	call	DMAMemMove	; do an iteration
	jr	z,DMAMemTestIterOK
	call	PC_ASTERISK	; signal failure
	jr	DMAMemTestIterCont	; continue
;
DMAMemTestIterOK:
	call	PC_PERIOD	; signal pass
;
DMAMemTestIterCont:
	pop	bc
	djnz	DMAMemTestIterLoop
	call	NEWLINE
	ret
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
	DMAIOSLO
	di
	otir				; load and execute dma
	ei
;
	ld	a,DMA_READ_STATUS_BYTE	; check status
	out	(DMABASE),a		; of transfer
	in	a,(DMABASE)		; set non-zero
	and	%00111011		; if failed
	sub	%00011011
	DMAIONOR
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
; DMA COPY BLOCK CODE -  ASSUMES DMA PREINITIALIZED
; INTERRUPT VERSION!
;==================================================================================================
;
DMALDIRINT:
;
#IF (INTENABLE)
;
	ld	(DMASourceInt),hl	; populate the dma
	ld	(DMADestInt),de		; register template
	ld	(DMALengthInt),bc
;
	ld	hl,DMACopyInt		; program the
	ld	b,DMACopyInt_Len	; dma command
	ld	c,DMABASE		; block
;
	DMAIOSLO
	di
	otir				; load and execute dma
	ei
;
	ld	a,DMA_READ_STATUS_BYTE	; check status
	out	(DMABASE),a		; of transfer
	in	a,(DMABASE)		; set non-zero
	and	%00111011		; if failed
	sub	%00011011
	DMAIONOR
;
#ENDIF
;
	ret
;
#IF (INTENABLE)
;
DMACopyInt 	;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111101 	; R0-Transfer mode, A -> B, start address, block length follow
DMASourceInt	.dw	0 		; R0-Port A, Start address
DMALengthInt	.dw	0 		; R0-Block length
		.db	%00010100	; R1-No timing bytes follow, address increments, is memory
		.db	%00010000 	; R2-No timing bytes follow, address increments, is memory
		.db	%10100000 	; R3-DMA, interrupt, stop on match disabled
		.db	DMA_CONTINUOUS	; R4-Continuous mode, destination address, interrupt and control byte follow
DMADestInt	.dw	0 		; R4-Port B, Destination address
		.db	%00011110	; R4-Interrupt control byte: Pulse byte follows, Pulse generated
		.db	0		; R4-Pulse control byte
		.db	INTIDX*2	; R4-Interrupt vector
;		.db	%10010010+DMA_RDY;R5-Stop on end of block, ce/wait multiplexed, READY active config
		.db	%10011010
		.db	DMA_LOAD 	; R6-Command Load
		.db	DMA_FORCE_READY	; R6-Command Force ready
		.db	DMA_ENABLE 	; R6-Command Enable DMA
DMACopyInt_Len 	.equ	$-DMACopyInt
;
#ENDIF
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
	DMAIOSLO
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
	DMAIONOR
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
	DMAIOSLO
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
	DMAIONOR
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
;
CIO_CONSOLE	.EQU	$80	; CONSOLE UNIT TO C
BF_CIOOUT	.EQU	$01	; HBIOS FUNC: OUTPUT CHAR
BF_CIOIN	.EQU	$00	; HBIOS FUNC: INPUT CHAR
BF_CIOIST	.EQU	$02	; HBIOS FUNC: INPUT CHAR STATUS
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
;
USEINT	.DB	FALSE		; USE INTERRUPTS FLAG
;
SAVSTK:	.DW	2
	.FILL	64
STACK:	.EQU	$
;
orgvec	.dw	0		; saved interrupt vector
;
;===============================================================================
; Interrupt Handler
;===============================================================================
;
reladr	.equ	$		; relocation start adr
;
	.org	$A000		; code will run here
;
int:
	; According to the DMA doc, you must issue
	; a DMA_DISABLE command prior to a
	; DMA_REINIT_STATUS_BYTE command to avoid a
	; potential race condition.
	ld	a,DMA_DISABLE
	out	(DMABASE),a
;	
	; The doc confuses me, but apparently it is
	; necessary to reinitialize the status byte
	; when an end-of-block interrupt occurs.  Otherwise,
	; the end-of-block condition remains set and
	; causes the interrupt to fire continuously.
	ld	a,DMA_REINIT_STATUS_BYTE
	out	(DMABASE),a
;
	ld	hl,(counter)
	inc	hl
	ld	(counter),hl
;
	or	$ff		; signal int handled
	ret
;
counter	.dw	0
;
hsiz	.equ	$ - $A000	; size of handler to relocate
;
	.org	reladr + hsiz
;
PROEND:	.EQU	$
;
	.END
