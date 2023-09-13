;==================================================================================================
; Z80 DMA TEST UTILITY - ROMWBW SPECIFIC
;==================================================================================================
;
;==================================================================================================
; PLATFORM CONFIGURATION
;==================================================================================================
;
DMAMODE_NONE	.EQU	0
DMAMODE_ECB	.EQU	1		; ECB-DMA WOLFGANG KABATZKE'S Z80 DMA ECB BOARD
DMAMODE_Z180	.EQU	2		; Z180 INTEGRATED DMA
DMAMODE_Z280	.EQU	3		; Z280 INTEGRATED DMA
DMAMODE_RC	.EQU	4		; RCBUS Z80 DMA
DMAMODE_MBC	.EQU	5		; MBC
DMAMODE_DUO	.EQU	6		; DUO
DMAMODE_VDG	.EQU	7		; VELESOFT DATAGEAR
;
DMAMODE		.EQU	DMAMODE_DUO	; SELECT DMA DEVICE FOR TESTING
;
;==================================================================================================
; SOME DEFAULT PLATFORM CONFIGURATIONS
;==================================================================================================
;
DMABASE		.EQU	$E0		; DMA: DMA BASE ADDRESS
DMALATCH	.EQU	DMABASE+1	; DMA: DMA LATCH ADDRESS
DMAIOTST	.EQU	$68		; AN OUTPUT PORT FOR TESTING - 16C450 SERIAL OUT
;
#IF (DMAMODE==DMAMODE_DUO)
DMABASE		.SET	$40		; DMA: DMA0 BASE ADDRESS
DMALATCH	.SET	$43		; DMA: DMA LATCH ADDRESS
DMAIOTST	.SET	$58		; AN OUTPUT PORT FOR TESTING - 16C450 SERIAL OUT
;DMAIOTST	.SET	$94		; AN ALT OUTPUT PORT FOR TESTING - RTC/SPEAKER/LEDS PORT
#ENDIF
;
;==================================================================================================
; HELPER MACROS AND EQUATES
;==================================================================================================
;
FALSE		.EQU	0
TRUE		.EQU	~FALSE
;
#DEFINE	PRTC(C)	CALL PRTCH \ .DB C	; PRINT CHARACTER C TO CONSOLE - PRTC('X')
#DEFINE	PRTS(S)	CALL PRTSTRD \ .TEXT S	; PRINT STRING S TO CONSOLE - PRTD("HELLO")
#DEFINE	PRTX(X) CALL PRTSTRI \ .DW X	; PRINT STRING AT ADDRESS X TO CONSOLE - PRTI(STR_HELLO)
;
;==================================================================================================
; INTERRUPT TESTING CONFIGURATION
; ASSUMES SYSTEM IS ALREADY CONFIGURED FOR IM2 OPERATION
; INTIDX MUST BE SET TO AN UNUSED INTERRUPT SLOT
;==================================================================================================
;		
INTENABLE	.EQU	TRUE		; ENABLE INT TESTING
INTIDX		.EQU	1		; INT VECTOR INDEX
;
;==================================================================================================
; DMA MODE BYTES - I/O ROUTINES CLEAR b3 AND ONLY PROGRAM LOW ADDRESS
;==================================================================================================
;
DMA_BYTE			.equ 	%10011101	; b7b1b0 = Register		= 1xxxxx01	= Program R4
							; b6b5	 = Transfer Mode	= x00xxxxx	= Byte transfer mode
							; b2	 = start address (low)	= xxxxx1xx	= low address follows (1 byte)
							; b3	 = start address (high) = xxxx1xxx	= high address follows (1 byte)
							; b4	 = int control byte	= xxx1xxxx	= interrupt, pulse or vector byte follow
;
DMA_CONTINUOUS			.equ 	%10111101	; b7b1b0 = Register		= 1xxxxx01	= Program R4
							; b6b5	 = Transfer Mode	= x01xxxxx	= Continuous transfer mode (default)
							; b2	 = start address (low)	= xxxxx1xx	= low address follows (1 byte)
							; b3	 = start address (high) = xxxx1xxx	= high address follows (1 byte)
							; b4	 = int control byte	= xxx1xxxx	= interrupt, pulse or vector byte follow
;
DMA_BURST 			.equ	%11011101	; b7b1b0 = Register		= 1xxxxx01	= Program R4
							; b6b5	 = Transfer Mode	= x10xxxxx	= Burst transfer mode
							; b2	 = start address (low)	= xxxxx1xx	= low address follows (1 byte)
							; b3	 = start address (high) = xxxx1xxx	= high address follows (1 byte)
							; b4	 = int control byte	= xxx1xxxx	= interrupt, pulse or vector byte follow
;
DMA_ICBYTE			.equ	%00001100	; b7	 = Interrupt Cont. Byte	= 0xxxxxxx	= Interrupt Control Byte identifier
							; b6	 = Interrupt on RDY	= x0xxxxxx	= Do not interrupt on RDY
							; b5	 = Status affects vector= xx0xxxxx	= Status does not affect vector
							; b4	 = Interrupt vector byte= xxx0xxxx	= No interrupt vector byte will follow
							; b3	 = Pulse control byte	= xxxx1xxx	= A pulse control byte will follow
							; b2	 = Pulse generation	= xxxxx100	= A pulse will be generated
							; b1	 = Interrupt @ block end= xxxxxx0x	= No interrupt at block end
							; b0	 = Interrupt on match	= xxxxxxx0	= No interrupt on match
;
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
DMA_XMODE			.equ	1		; Byte = 0, Continuous = 1, Burst = 2
;
;==================================================================================================
; ROMWBW HBIOS DEFINITIONS
;==================================================================================================
;
bf_sysint			.equ	$FC	; INT function
bf_sysget			.equ	$F8	; GET function
;		
bf_sysintinfo			.equ	$00	; INT INFO subfunction
bf_sysintget			.equ	$10	; INT GET subfunction
bf_sysintset			.equ	$20	; INT SET subfunction
bf_sysgetcpuspd			.equ	$F3	; GET CPUSPD subfunction
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
	.db	"\n\rDMA Monitor V3.1\n\r$"
;
#IF (INTENABLE)
;
	; Install interrupt handler in upper mem
	ld	hl,reladr
	ld	de,$A000
	ld	bc,hsiz
	ldir
	ld	a,(dmaport)
	ld	(int_dmaport),a
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
	CALL	CINU			; GET SELECTION
	CALL	COUT
;
MENULP1:
	CALL	NEWLINE
	CP	'C'
	JP	Z,DMACFG_C		; CONFIGURE XFER MODE
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
	JP	Z,DMATST_0		; PULSE DMA PORT
	CP	'1'
	JP	Z,DMATST_1		; PULSE LATCH PORT
	CP	'O'
	JP	Z,DMATST_O
	CP	'R'
	JP	Z,DMATST_R		; TOGGLE RESET
	CP	'Y'
	JP	Z,DMATST_Y
	cp	'L'
	jp	z,DMACFG_L		; SET LATCH PORT
	cp	'S'
	jp	z,DMACFG_S		; SET PORT
	cp	'V'
	jp	z,DMACFG_V		; TOGGLE VERBOSE
	CP	'X'
	JP	Z,DMABYE		; EXIT
;
	JR	MENULP
;
DMABYE:
#IF (INTENABLE)
	; Deinstall interrupt vector
	ld	hl,(orgvec)		; original vector
	ld	b,bf_sysint
	ld	c,bf_sysintset		; set new vector
	ld	e,INTIDX		; vector idx
	di
	rst	08			; do it
	ei				; interrupts back on
#ENDIF
;
	LD	SP,(SAVSTK)		; RESTORE CP/M STACK
	RET
;
;==================================================================================================
; CONFIGURE PORT
;==================================================================================================
;
DMACFG_S:
	call	PRTSTRD
	.db	"\n\rSet DMA port address\n\rPort:$"
	call	HEXIN
	ld	hl,dmaport
	ld	(hl),a
#IF (INTENABLE)
	ld	(int_dmaport),a
#ENDIF
	jp	MENULP
;
DMACFG_L:
	call	PRTSTRD
	.db	"\n\rSet Latch port address\n\rPort:$"
	call	HEXIN
	ld	hl,dmalach
	ld	(hl),a
	jp	MENULP
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
DMATST_0:
	call	PRTSTRD
	.db	"\n\rPerforming DMA Port Selection Test\n\r$"
	CALL	DMA_Port0
	ret

DMATST_1:
	call	PRTSTRD
	.db	"\n\rPerforming Latch Port Selection Test\n\r$"
	CALL	DMA_Port1
	ret
;
DMATST_O:
	call	PRTSTRD
	.db	"\n\rTest output to I/O device\n\r$"
	CALL	DMA_ReadyO
	JP	MENULP
;
DMATST_D:
	call	PRTSTRD
	.db	"\n\rRegister dump:\n\r$"
	CALL	DMARegDump
	JP	MENULP
;
DMATST_Y:
	call	PRTSTRD
	.db	"\n\rPerforming Ready Bit Test\n\r$"
	CALL	DMA_ReadyY
	JP	MENULP
;
DMATST_R:
	call	PRTSTRD
	.db	"\n\rPerforming Reset\n\r$"
;	CALL	
	JP	MENULP

DMACFG_C:
	CALL	DMA_XferM
	call	PRTSTRD
	.db	"\n\rTransfer mode change to: $"
	LD	a,(dmaxfer)
	LD	DE,DMA_XFRMODE
	CALL	PRTIDXDEA
	CALL	NEWLINE
	JP	MENULP
;
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
	LD	A,(dmaport)		; DISPLAY
	CALL	PRTHEXBYTE		; DMA PORT
	call	PRTSTRD
	.db	", Latch Port=0x$"
	ld	A,(dmalach)
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
#IF (DMAMODE==DMAMODE_VDG)
	call	PRTSTRD
	.db	"\n\rReset\\Ready Latch unsupported.$"
#ENDIF
	call	PRTSTRD			; DISPLAY SPEED
	.db	"\n\rCPU at $"
	LD	B,bf_sysget
	LD	C,bf_sysgetcpuspd	; GET CURRENT 
	RST	08			; SPEED SETTING
	OR	A
	LD	A,L
	JR	Z,SPDDISP
	LD	A,3
SPDDISP:LD	DE,DMA_SPD_STR
	CALL	PRTIDXDEA
;
	call	PRTSTRD
	.db	"\n\rTransfer Mode: $"	; DIPLAY TRANSFER
	LD	a,(dmaxfer)		; MODE
	LD	DE,DMA_XFRMODE
	CALL	PRTIDXDEA
	CALL	NEWLINE
;
	LD	HL,MENU_OPT		; DISPLAY
	CALL	PRTSTR			; MENU OPTIONS
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
	LD	A,(dmaport)
	CALL	PRTHEXBYTE
;
#IF !(DMAMODE==DMAMODE_VDG)
	ld	a,(dmalach)
	ld	c,a
	LD	A,DMA_FORCE
	out	(c),a			; force ready off
#ENDIF
;
	call	DMAProbe		; do we have a dma?
	jr	nz,DMA_NOTFOUND
;
	call	PRTSTRD
	.db	" DMA Found\n\r$"
;
	ld	hl,DMAInitMode		; setup the 
	call	SETXFER			; transfer mode
	set	3,(hl)			; upper and lower address
;
	ld	hl,DMACode		; program the
	ld	b,DMACode_Len		; dma command
	ld	a,(dmaport)
	ld	c,a		; block
;
	di
	otir				; load dma
	ei
	xor	a			; set status
;
DMA_EXIT:
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
DMACode		;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111101 	; R0-Transfer mode, A -> B, start address, block length follow
		.dw	0		; R0-Port A, Start address
		.dw	0 		; R0-Block length
		.db	%00010100	; R1-No timing bytes follow, address increments, is memory
		.db	%00010000 	; R2-No timing bytes follow, address increments, is memory
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled
DMAInitMode:	.db	DMA_CONTINUOUS	; R4-Transfer mode, destination address, interrupt and control byte follow
		.dw	0 		; R4-Port B, Destination address
		.db	DMA_ICBYTE	; R4-Pulse byte follows, Pulse generated
		.db	0		; R4-Pulse offset
		.db	%10010010+DMA_RDY; R5-Stop on end of block, ce/wait multiplexed, READY active config
		.db	DMA_LOAD 	; R6-Command Load
;		.db	DMA_FORCE_READY	; R6-Command Force ready
;		.db	DMA_ENABLE 	; R6-Command Enable DMA
DMACode_Len 	.equ	$-DMACode
;
;==================================================================================================
; STRINGS
;==================================================================================================
;	
DMA_DEV_STR:
	.TEXT	"NONE$"
	.TEXT	"ECB$"
	.TEXT	"Z180$"
	.TEXT	"Z280$"
	.TEXT	"RCBUS$"
	.TEXT	"MBC$"
	.TEXT	"DUODYNE$"
	.TEXT	"DATAGEAR$"
;
DMA_SPD_STR:
	.TEXT	"half speed.$"
	.TEXT	"full speed.$"
	.TEXT	"double speed.$"
	.TEXT	"unknown speed.$"
;
DMA_XFRMODE:
	.TEXT	"Byte.$"
	.TEXT	"Continuous.$"
	.TEXT	"Burst.$"
;
MENU_OPT:
	.TEXT	"\n\r"
	.TEXT	"C) Change transfer mode\n\r"
	.TEXT	"D) Dump DMA registers\n\r"
	.TEXT	"I) Initialize DMA\n\r"
	.TEXT	"T) Toggle Interrupt Usage\n\r"
	.TEXT	"M) Test Memory-Memory Copy\n\r"
	.TEXT	"N) Test Memory-Memory Copy Iteratively\n\r"
	.TEXT	"O) Memory to I/O Test\n\r"
	.TEXT	"0) Test DMA Port Selection\n\r"
#IF !(DMAMODE==DMAMODE_VDG)
	.TEXT	"1) Test DMA Latch Port Selection\n\r"
	.TEXT	"Y) Test Ready Bit\n\r"
#ENDIF
	.TEXT	"S) Set DMA port\n\r"
	.TEXT	"L) Set Latch port\n\r"
	.TEXT	"V) Verbose status toggle\n\r"
	.TEXT	"X) Exit\n\r"

	.TEXT	">$"
;
;==================================================================================================
; TOGGLE TRANSFER MODE
;==================================================================================================
;
DMA_XferM:				; Set next transfer mode
	ld	a,(dmaxfer)
	inc	a
	cp	3
	jr	nz,NextX
	ld	a,0
NextX:	ld	(dmaxfer),a
	ret
;
;==================================================================================================
; TOGGLE VERBOSE MODE
;==================================================================================================
;
DMACFG_V:
	ld	a,(dmavbs)
	cpl
	ld	(dmavbs),a
	jp	MENULP
;
;==================================================================================================
; OUTPUT A BUFFER OF TEXT TO AN IOPORT
;==================================================================================================
;
DMABUF	.TEXT	"0123456789abcdef"
;DMABUF	.DB	$04,$00,$04,$00,$04,$00,$04,$00,$04,$00,$04,$00,$04,$00,$04,$00,$00,$00,$00 ; SPEAKER
;
DMA_ReadyO:
	call	PRTSTRD
	.db	"\r\nOutputing string to port 0x$"
	ld	a,(tstport)
	call	PRTHEXBYTE
	call	NEWLINE
;
	ld	b,16
IOLoop:	push	bc
	call	NEWLINE
	ld	hl,DMABUF
	ld	a,(tstport)
	ld	bc,16
;
	call	DMAOTIR
;
	pop	bc
	djnz	IOLoop
	call	NEWLINE
	ret
;
;==================================================================================================
; PULSE PORT
;==================================================================================================
;
DMA_Port0:
	ld	a,(dmaport)
	jr	DMA_Port
DMA_Port1:
	ld	a,(dmalach)
DMA_Port:
	call	PRTSTRD
	.db	"\r\nPulsing port 0x$"
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
DMA_ReadyY:
	call	NEWLINE
	ld	a,(dmalach)
	ld	c,a			; toggle
	ld	b,$20			; loop counter
portlp2:push	bc
	ld	a,b
	call	PRTDECB
	call	PRTSTRD
	.db	": ON$"
	call	delay
	ld	a,$FF
	out	(c),a
	call	PRTSTRD
	.db	" -> OFF$"
	call	delay
	call	PRTSTRD
	.db	"\r               \r$"
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
	;LD	HL,$8400	; PLANT
	;LD	A,$00		; BAD
	;LD	(HL),A		; SEED
;
	LD	A,$AA		; CHECK COPY SUCCESSFULL
	LD	HL,$8000
	LD	BC,4096
NXTCMP:	CPI
	JP	PO,CMPOK
	JR	Z,NXTCMP

	DEC	HL
	CALL	PRTHEXWORDHL
	LD	A,' '
	CALL	COUT
	LD	A,(HL)
	CALL	PRTHEXBYTE
	
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
	ld	b,$20			; loop counter
	ld	a,b
	call	PRTDECB
	call	PRTSTRD
	.db	" iterations:\n\r$"
DMAMemTestIterLoop:
	push	bc			; save loop control
	call	DMAMemMove		; do an iteration
	jr	z,DMAMemTestIterOK
	call	PRTSTRD
	.db	" Mismatch\n\r$"
	jr	DMAMemTestIterCont	; continue
;
DMAMemTestIterOK:
	call	PRTSTRD
	.db	" Match\n\r$"
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
	ld	a,(dmaport)
	ld	c,a
	ld	a,DMA_RESET	
	out	(c),a
	ld	a,%01111101 		; R0-Transfer mode, A -> B, start address follows
	out	(c),a
	ld	a,$cc
	out	(c),a
	ld	a,$dd
	out	(c),a
	ld	a,$e5
	out	(c),a
	ld	a,$1a
	out	(c),a
	ld	a,DMA_LOAD
	out	(c),a
;
	ld	a,DMA_READ_MASK_FOLLOWS	; set up
	out	(c),a			; for 
	ld	a,%00011000		; register
	out	(c),a			; read
	ld	a,DMA_START_READ_SEQUENCE
	out	(c),a
;
	in	a,(c)			; read in 
	ld	e,a			; address
	in	a,(c)
	ld	d,a
;
	xor	a			; is it
	ld	hl,$ddcc		; a match
	sbc	hl,de			; return with
	ret	z			; status
	cpl
	ret
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
	ld	hl,DMACopyMode
	call	SETXFER
	set	3,(hl)			; upper and lower address
;
	ld	hl,DMACopy		; program the
	ld	b,DMACopy_Len		; dma command
	ld	a,(dmaport)		; block
	ld	c,a
;
	di
	otir				; load and execute dma
	ei
;
	call	DMASTATUS
	ret
;
DMACopy 	;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111101 	; R0-Transfer mode, A -> B, start address, block length follow
DMASource	.dw	0 		; R0-Port A, Start address
DMALength	.dw	0 		; R0-Block length
		.db	%00010100	; R1-No timing bytes follow, address increments, is memory
		.db	%00010000 	; R2-No timing bytes follow, address increments, is memory
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled
DMACopyMode:	.db	DMA_CONTINUOUS	; R4-Transfer mode. Destination address, interrupt and control byte follow
DMADest		.dw	0 		; R4-Port B, Destination address
		.db	DMA_ICBYTE	; R4-Pulse byte follows, Pulse generated
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
	ld	hl,DMAICopyMode
	call	SETXFER
	set	3,(hl)			; upper and lower address
;
	ld	hl,DMACopyInt		; program the
	ld	b,DMACopyInt_Len	; dma command
	ld	a,(dmaport)		; block
	ld	c,a
;
	di
	otir				; load and execute dma
	ei
;
	call	DMASTATUS
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
DMAICopyMode:	.db	DMA_CONTINUOUS	; R4-Transfer mode, destination address, interrupt and control byte follow
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
	ld	hl,DMAOutMode
	call	SETXFER
	res	3,(hl)			; no upper address
;
	ld	hl,DMAOutCode		; program the
	ld	b,DMAOut_Len		; dma command
	ld	a,(dmaport)		; block
	ld	c,a
;
	di
	otir				; load and execute dma
	ei
;
	call	DMASTATUS
	ret
;
DMAOutCode  	;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111001 	; R0-Transfer mode, B -> A (temp), start address, block length follow	
DMAOutSource	.dw	0 		; R0-Port A, Start address
DMAOutLength	.dw	0 		; R0-Block length

		.db	%00010100	; R1-No timing bytes follow, fixed incrementing address, is memory	
		.db	%00101000 	; R2-No timing bytes follow, address static, is i/o			
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled

DMAOutMode:	.db	DMA_CONTINUOUS	; R4-Transfer Mode, destination port, interrupt and control byte follow
DMAOutDest	.db	0 		; R4-Port B, Destination port
		.db	DMA_ICBYTE	; R4-Pulse byte follows, Pulse generated
		.db	0		; R4-Pulse offset

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
	ld	hl,DMAOutMode
	call	SETXFER
	res	3,(hl)			; no upper address

	ld	hl,DMAInCode		; program the
	ld	b,DMAIn_Len		; dma command
	ld	a,(dmaport)		; block
	ld	c,a
;
	di
	otir				; load and execute dma
	ei
;
	call	DMASTATUS
	ret
;
DMAInCode 	;.db	DMA_DISABLE	; R6-Command Disable DMA
		.db	%01111001 	; R0-Transfer mode, B -> A, start address, block length follow		
DMAInDest	.dw	0 		; R0-Port A, Start address
DMAInLength	.dw	0 		; R0-Block length
		.db	%00010100	; R1-No timing bytes follow, address increments, is memory		
		.db	%00111000 	; R2-No timing bytes follow, address static, is i/o			
		.db	%10000000 	; R3-DMA, interrupt, stop on match disabled
DMAInMode:	.db	DMA_CONTINUOUS	; R4-Transfer mode, destination port, no interrupt, control byte.	
DMAInSource	.db	0 		; R4-Port B, Destination port
		.db	DMA_ICBYTE	; R4-Pulse byte follows, Pulse generated
		.db	0		; R4-Pulse offset
		.db	%10010010+DMA_RDY;R5-Stop on end of block, ce/wait multiplexed, READY active config	
		.db	DMA_LOAD 	; R6-Command Load							
		.db	DMA_FORCE_READY	; R6-Command Force ready						
		.db	DMA_ENABLE 	; R6-Command Enable DMA							

DMAIn_Len 	.equ	$-DMAInCode
;
;==================================================================================================
; SET TRANSFER MODE
;==================================================================================================
;
SETXFER:
	ld	a,(dmaxfer)		; setup the 
	cp	0			; transfer mode
	jr	nz,DMAX1
	ld	a,DMA_BYTE
	jr	DMAX3
DMAX1:	cp	1
	jr	nz,DMAX2
	ld	a,DMA_CONTINUOUS
	jr	DMAX3
DMAX2:	cp	2
	ret	nz
	ld	a,DMA_BURST
DMAX3:	ld	(hl),a
	ret
;
;==================================================================================================
; GET STATUS
;==================================================================================================
;
DMASTATUS:
	ld	a,(dmaxfer)		; if byte mode
	cp	0			; give some time to finish
	jr	nz,DMASTS1

;	ld	b,1
;DMASTS2:call	delay
;	djnz	DMASTS2
;
DMASTS1:ld	a,DMA_READ_STATUS_BYTE	; check status
	out	(c),a			; of transfer
	in	a,(c)
	and	%00111011
;
;	push	af
;	ld	a,DMA_REINIT_STATUS_BYTE
;	out	(c),a
;	pop	af
;
	call	PRTSTRD
	.db	"\n\rReturn Status: $"
	call	PRTHEXBYTE
	call	NEWLINE
;
	ld	c,a
	ld	a,(dmavbs)
	or	a
	jr	z,DMSSTS2
	ld	a,c
;
	ld	a,%00000001
	ld	de,DMASTSBIT0
	call	PRTIDXMSK
;
	ld	a,%00000010
	ld	de,DMASTSBIT1
	call	PRTIDXMSK
;
	ld	a,%00001000
	ld	de,DMASTSBIT3
	call	PRTIDXMSK
;
	ld	a,%00010000
	ld	de,DMASTSBIT4
	call	PRTIDXMSK
;
	ld	a,%00100000
	ld	de,DMASTSBIT5
	call	PRTIDXMSK
;
DMSSTS2:ld	a,c
	ret

DMASTSBIT0:
	.TEXT	"DMA Bus request did not occur after LOAD command\n\r$"
	.TEXT	"DMA Bus request occurred after the LOAD command\n\r$"
DMASTSBIT1:
	.TEXT	"Ready line inactive\n\r$"
	.TEXT	"Ready line active\n\r$"
DMASTSBIT3:
	.TEXT	"Interrupt pending\n\r$"
	.TEXT	"No interrupt pending\n\r$"
DMASTSBIT4:
	.TEXT	"Match found\n\r$"
	.TEXT	"No match found\n\r$"
DMASTSBIT5:
	.TEXT	"End of block reached\n\r$"
	.TEXT	"End of block not reached\n\r$"
;
;==================================================================================================
; DEBUG - READ START, DESTINATION AND COUNT REGISTERS
;==================================================================================================
;
DMARegDump:
	ld	a,(dmaport)
	ld	c,a
	ld	a,DMA_READ_MASK_FOLLOWS
	out	(c),a
	ld	a,%01111110
	out	(c),a
	ld	a,DMA_START_READ_SEQUENCE
	out	(c),a
;
	in	a,(c)
	ld	l,a
	in	a,(c)
	ld	h,a
	call	PRTHEXWORDHL
	ld	a,':'
	call	COUT
;
	in	a,(c)
	ld	l,a
	in	a,(c)
	ld	h,a
	call	PRTHEXWORDHL
	ld	a,':'
	call	COUT
;
	in	a,(c)
	ld	l,a
	in	a,(c)
	ld	h,a
	call	PRTHEXWORDHL
;
	call	NEWLINE
	ret
;
;==================================================================================================
; CONSOLE I/O ROUTINES
;==================================================================================================
;
CIO_CONSOLE	.EQU	$80	; HBIOS DEFAULT CONSOLE
BF_CIOOUT	.EQU	$01	; HBIOS FUNC: OUTPUT CHAR
BF_CIOIN	.EQU	$00	; HBIOS FUNC: INPUT CHAR
BF_CIOIST	.EQU	$02	; HBIOS FUNC: INPUT CHAR STATUS
;
;__CINU_______________________________________________________________________
;
;	INPUT AN UPPERCASE CHARACTER
;_____________________________________________________________________________
;
CINU:	CALL	CIN
	; Force upper case
	CP	'a'			; < 'a'
	RET	C			; IF SO, JUST CONTINUE
	CP	'z'+1			; > 'z'
	RET	NC			; IS SO, JUST CONTINUE
	SUB	'a'-'A'			; CONVERT TO UPPER
	RET
;
;__HEXIN_______________________________________________________________________
;
;	INPUT A HEX BYTE, RETURN VALUE IN A
;_____________________________________________________________________________
;
HEXIN:	CALL	CINU		; GET 1 CHAR INPUT
	push	af
	CALL	ISHEX		; CHECK FOR VALID CHARACTER
	JR	C,HEXIN
	ADD	A,A
	ADD	A,A	
	ADD	A,A
	ADD	A,A
	LD	C,A		; Save top nibble
	pop	af		; Retreive letter
	call	COUT		; and display it
;
HEXIN1:	CALL	CINU		; GET 1 CHAR INPUT
	push	af
	CALL	ISHEX		; CHECK FOR VALID CHARACTER
	JR	C,HEXIN1
;
	or	c
	ld	c,a
	pop	af		; Retreive letter
	call	COUT		; and display it
;
	ld	a,c
	RET
	
;	CF SET MEANS CHARACTER 0-9,A-F

ISHEX:	CP	'0'			; < '0'?
	JR	C,ISHEX1		; YES, NOT 0-9, CHECK A-F
	CP	'9' + 1			; > '9'
	jr	nc,ISHEX1
	sub	'0'			; MUST BE 0-9, RETURN
	ret
ISHEX1:	CP	'A'			; < 'A'?
	ret	c			; YES, NOT A-F, FAIL
	cp	'F' + 1			; > 'F'
	jr	nc,ISHEX2
	sub	'A' - 10
	RET				; MUST BE A-F, RETURN
ISHEX2: SCF
	RET	
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
dmaport	.db	DMABASE
dmalach	.db	DMALATCH
dmaxfer	.db	DMA_XMODE
tstport	.db	DMAIOTST
dmavbs	.db	0
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
	;LD	E,'.'			; OUTPUT CHAR TO E
	;LD	C,CIO_CONSOLE		; CONSOLE UNIT TO C
	;LD	B,BF_CIOOUT		; HBIOS FUNC: OUTPUT CHAR
	;CALL	$FFF0			; HBIOS OUTPUTS CHARACTER

	; According to the DMA doc, you must issue
	; a DMA_DISABLE command prior to a
	; DMA_REINIT_STATUS_BYTE command to avoid a
	; potential race condition.
	ld	a,(int_dmaport)
	ld	c,a
	ld	a,DMA_DISABLE
	out	(c),a
;	
	; The doc confuses me, but apparently it is
	; necessary to reinitialize the status byte
	; when an end-of-block interrupt occurs.  Otherwise,
	; the end-of-block condition remains set and
	; causes the interrupt to fire continuously.
	ld	a,DMA_REINIT_STATUS_BYTE
	out	(c),a
;
	ld	hl,(counter)
	inc	hl
	ld	(counter),hl
;
	or	$ff		; signal int handled
	ret
;
; data referred to in handler must reside in high mem
;
int_dmaport	.db	0	; hi mem copy of dmaport
counter		.dw	0	; interrupt counter
;
hsiz	.equ	$ - $A000	; size of handler to relocate
;
	.org	reladr + hsiz
;
PROEND:	.EQU	$
;
	.END
