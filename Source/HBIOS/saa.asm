;======================================================================
;
;	SAA1906A SOUND CHIP DRIVER
;
;======================================================================
;
; THIS IS CURRENTLY JUST A DUMMY DRIVER TO IMPLEMENT A SIMPLE
; HARDWARE RESET AT BOOT FOR THE SAA1906A.
;
; THE DRIVER IS NOT REGISTERED AND THERE IS NO FUNCTION DISPATCHING.
;
	DEVECHO	"SAA: IO="
	DEVECHO SAABASE
	DEVECHO	" HZ\n"
;
;======================================================================
;
;	REGISTERS (16-BIT I/O)
;
SAA_DATA	.EQU	$00 << 8 + SAABASE
SAA_ADR		.EQU	$01 << 8 + SAABASE
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_SAA	.EQU	$
;
	.DW	SIZ_SAA			; MODULE SIZE
	.DW	SAA_INITPHASE		; ADR OF INIT PHASE HANDLER
;
SAA_INITPHASE:
	; INIT PHASE HANDLER, A=PHASE
	CP	HB_PHASE_PREINIT	; PREINIT PHASE?
	JP	Z,SAA_PREINIT		; DO PREINIT
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,SAA_INIT		; DO INIT
	RET				; DONE
;
;======================================================================
;
;	DRIVER PRE-INITIALIZATION
;
;	EARLY HARDWARE DETECTION, RESET, ETC.
;
SAA_PREINIT:
	CALL	SAA_RESET		; RESET CHIP
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
;======================================================================
;
;	DRIVER INITIALIZATION
;
;	ANNOUNCE DEVICE ON CONSOLE. ACTIVATE DEVICE IF REQUIRED.
;	SETUP FUNCTION TABLES. SETUP THE DEVICE.
;	RETURN INITIALIZATION STATUS
;
SAA_INIT:
	CALL	NEWLINE			; ANNOUNCE
	PRTS("SAA: IO=$")
	LD	A,SAABASE
	CALL	PRTHEXBYTE
	;
	; DRIVER NOT REALLY IMPLEMENTED, SO WE DO NOT
	; HAVE A FUNCTION DISPATCHER TO REGISTER HERE (YET).
	;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - RESET
;
;	INITIALIZE DEVICE. SET VOLUME OFF.
;
;======================================================================
;
SAA_RESET:
	;
	; ADD HARDWARE RESET HERE...
	;
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_SAA	.EQU	$
SIZ_SAA	.EQU	END_SAA - ORG_SAA
;	
	MEMECHO	"SAA occupies "
	MEMECHO	SIZ_SAA
	MEMECHO	" bytes.\n"
