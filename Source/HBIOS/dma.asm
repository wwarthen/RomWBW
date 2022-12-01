;==================================================================================================
; Z80 DMA DRIVER
;==================================================================================================
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
DMA_RDY				.EQU	%00001000
DMA_FORCE			.EQU	0

#IF (DMA_USEHS & (DMAMODE=DMAMODE_MBC))
;;;#IF (CPUSPDDEF=SPD_HIGH)
;;;#DEFINE DMAIOSLO LD A,(HB_RTCVAL) \ AND %11110111 \ OUT (RTCIO),A 
;;;#DEFINE DMAIONOR PUSH AF \ LD A,(HB_RTCVAL) \ OR %00001000 \ OUT (RTCIO),A \ POP AF
;;;#ELSE
;;;#DEFINE DMAIOSLO \;
;;;#DEFINE DMAIONOR \;
;;;#ENDIF

#DEFINE DMAIOSLO LD A,(HB_RTCVAL) \ AND ~%00001000 \ OUT (RTCIO),A
#DEFINE DMAIONOR PUSH AF \ LD A,(HB_RTCVAL) \ OUT (RTCIO),A \ POP AF

#ENDIF
;
#IF (DMA_USEHS & (DMAMODE=DMAMODE_ECB))
;;;#IF (CPUSPDDEF=SPD_HIGH)
;;;#DEFINE DMAIOSLO LD A,(HB_RTCVAL) \ OR  %00001000 \ OUT (RTCIO),A 
;;;#DEFINE DMAIONOR PUSH AF \ LD A,(HB_RTCVAL) \ AND %11110111 \ OUT (RTCIO),A \ POP AF
;;;#ELSE
;;;#DEFINE DMAIOSLO \;
;;;#DEFINE DMAIONOR \;
;;;#ENDIF

#DEFINE DMAIOSLO LD A,(HB_RTCVAL) \ OR %00001000 \ OUT (RTCIO),A 
#DEFINE DMAIONOR PUSH AF \ LD A,(HB_RTCVAL) \ OUT (RTCIO),A \ POP AF

#ENDIF

#IF (!DMA_USEHS)
#DEFINE DMAIOSLO \;
#DEFINE DMAIONOR \;
#ENDIF
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
;
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
;
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
;
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
#IF (0)
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
#ENDIF
