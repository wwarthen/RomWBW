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
;DMA_ENABLE_INTERUPTS		.equ	$ab
;DMA_RESET_DISABLE_INTERUPTS	.equ 	$a3
;DMA_ENABLE_AFTER_RETI		.equ	$b7
;DMA_REINIT_STATUS_BYTE		.equ	$8b
;
DMA_RDY				.EQU	%00001000
DMA_FORCE			.EQU	0

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
	.db	"DMA MONITOR\n\r$"
;
MENULP:	CALL	DISPM			; DISPLAY MENU
	CALL	CIN			; GET SELECTION
;
	CP	'D'
	JP	Z,DMATST_D		; DUMP REGISTERS
	CP	'I'
	JP	Z,DMATST_I		; INITIALIZE
	CP	'M'
	JP	Z,DMATST_M		; MEMORY MOVE
	CP	'0'
	JP	Z,DMATST_01
	CP	'1'
	JR	Z,DMATST_01
	CP	'R'
	JP	Z,DMATST_R		; TOGGLE RESET
	CP	'Y'
	JP	Z,DMATST_Y		; TOGGLE READY
	CP	'X'
	JR	Z,DMABYE		; EXIT
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
DMATST_01:
	call	PRTSTRD
	.db	"\n\rTOGGLE PORT\n\r$"
	CALL	DMA_Port01
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
	.db	"\n\rTEST READY\n\r$"
	CALL	DMA_ReadyT
	JP	MENULP
;
DMATST_R:
	call	PRTSTRD
	.db	"\n\rRESET\n\r$"
;	CALL	
	JP	MENULP
;==================================================================================================
; DISPLAY MENU
;==================================================================================================
;
DISPM:	call	PRTSTRD
	.db	"\n\rDMA DEVICE: $"
	LD	C,DMAMODE		; DISPLAY
	LD	A,00000111B		; TARGET
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
	DMAIOSLO
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
	DMAIONOR
	ret
;
DMA_NOTFOUND:
	push	af
	call	PRTSTRD
	.db	" NOT PRESENT$"
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
	.TEXT	"M) Memory to Memory test\n\r"
	.TEXT	"0) DMA Port select test\n\r"
	.TEXT	"1) DMA Latch Port select test\n\r"
	.TEXT	"Y) Ready bit test\n\r"
	.TEXT	"X) Exit\n\r"

	.TEXT	">$"
;
;==================================================================================================
; TOGGLE A PORT ON AND OFF
;==================================================================================================
;
DMA_Port01:
	sub	'0'			; Calculate
	add	a,DMABASE		; Port to
	ld	c,a			; toggle
	ld	b,0
portlp:	push	bc
	call	PRTSTRD
	.db	"\n\rON ...$"
	call	PRTHEXWORD
	push	bc
	ld	b,0
	ld	a,0
portlp1:out	(c),a
	djnz	portlp1
	pop	bc
	call	PRTSTRD
	.db	" OFF$"
	call	delay	
	pop	bc
	djnz	portlp
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
	ld	c,DMABASE+1		; toggle
	ld	b,0
portlp2:push	bc
	call	PRTSTRD
	.db	"\n\rON ...$"
	call	PRTHEXWORD
	ld	a,$FF
	ld	c,DMABASE+1
	out	(c),a
	call	PRTSTRD
	.db	" OFF$"
	call	delay
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

SAVSTK:	.DW	2
	.FILL	64
STACK:	.EQU	$
PROEND:	.EQU	$
;
	.END
