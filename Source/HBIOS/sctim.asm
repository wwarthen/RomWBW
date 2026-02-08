;___SCTIM______________________________________________________________________________________________________________
;
; Z80 SMALL COMPUTERS SC737 50HZ SYSTEM TIMER
; https://smallcomputercentral.com/rcbus/sc700-series/sc737-rcbus-interrupt-module/
;
; DOES NOT SUPPORT INTERRUPT VECTORS, ONLY USED FOR Z80 INT MODE 1
;
;______________________________________________________________________________________________________________________
;
;
; BIT	READ			WRITE
; 0	TICK BIT 0		<NOT USED>
; 1	TICK BIT 1		<NOT USED>
; 2	<NOT USED>		<NOT USED>
; 3	<NOT USED>		<NOT USED>
; 4	<NOT USED>		<NOT USED>
; 5	<NOT USED>		<NOT USED>
; 6	<NOT USED>		<NOT USED>
; 7	INT REQ ACT		INT ENABLE
;
#IF (INTMODE == 1)
;
	DEVECHO	"SCTIM: IO="
	DEVECHO	SCTIMIO
;
	DEVECHO "\n"
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_SCTIM	.EQU	$
;
	.DW	SIZ_SCTIM		; MODULE SIZE
	.DW	SCTIM_INITPHASE		; ADR OF INIT PHASE HANDLER
;
SCTIM_INITPHASE:
	; INIT PHASE HANDLER, A=PHASE
	CP	HB_PHASE_PREINIT	; PREINIT PHASE?
	JP	Z,SCTIM_PREINIT		; DO PREINIT
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,SCTIM_INIT		; DO INIT
	RET				; DONE
;
;==================================================================================================
; SCTIM PRE-INITIALIZATION
;
; CHECK TO SEE IF A SCTIM EXISTS. IF IT EXISTS, ALL FOUR SCTIM CHANNELS ARE PROGRAMMED TO:
;  INTERRUPTS DISABLED, COUNTER MODE, RISING EDGE TRIGGER, RESET STATE.
;
; IF THE SCTIMTIMER CONFIGURATION IS SET, THEN A PERIOD INTERRUPT TIMER IS SET UP USING SCTIM CHANNELS
; 2 (SCTIMPRECH) & 3 (SCTIMTIMCH). THE TIMER WILL BE SETUP TO 50 OR 60HZ DEPENDING ON CONFIGURATION 
; SETTING TICKFREQ. CHANNEL 3 WILL GENERATE THE TICK INTERRUPT.. 
;==================================================================================================
;
SCTIM_PREINIT:
	; BLINDLY RESET THE SCTIM ASSUMING IT IS THERE.
	XOR	A
	OUT	(SCTIMIO),A
;
	CALL	SCTIM_DETECT		; DO WE HAVE ONE?
	LD	(SCTIM_EXIST),A		; SAVE IT
	RET	NZ			; ABORT IF NONE
;
	LD	HL,SCTIM_INT
	CALL	HB_ADDIM1		; ADD TO IM1 CALL LIST
;
	XOR	A
	RET
;
;==================================================================================================
; DRIVER INITIALIZATION
;==================================================================================================
;
SCTIM_INIT:
	; ANNOUNCE PORT
	CALL	NEWLINE			; FORMATTING
	PRTS("SCTIM:$")			; FORMATTING
;
	PRTS(" IO=0x$")			; FORMATTING
	LD	A,SCTIMIO		; GET BASE PORT
	CALL	PRTHEXBYTE		; PRINT BASE PORT
;
	LD	A,(SCTIM_EXIST)		; IS IT THERE?
	OR	A			; 0 MEANS YES
	JR	Z,SCTIM_INIT1		; CONTINUE TO ENABLE IT
;
	; NOTIFY NO SCTIM HARDWARE
	PRTS(" NOT PRESENT$")
	OR	$FF
	RET
;
SCTIM_INIT1:
	; ENABLE THE TIMER
	OR	$FF			; $FF TO ACCUM
	OUT	(SCTIMIO),A		; ENABLE INTS
	XOR				; SIGNAL SUCCESS
	RET				; DONE
;
;==================================================================================================
; INTERRUPT HANDLER
;==================================================================================================
;
SCTIM_INT:
	IN	A,(SCTIMIO)		; READ PORT
	RLA				; INT ACT BIT TO CF
	JR	NC,SCTIM_INT1		; IF ACTIVE, CONTINUE
	XOR	A			; SIGNAL INT NOT HANDLED
	RET				; AND RETURN
;
SCTIM_INT1:
	; PROCESS THE INTERRUPT
	XOR	A			; ZERO ACCUM
	OUT	(SCTIMIO),A		; ENABLE OFF
	DEC	A			; $FF TO ACCUM
	OUT	(SCTIMIO),A		; ENABLE BACK ON
	JP	HB_TIMINT		; CHAIN TO TIMER PROCESSING
;
;==================================================================================================
; DETECT SCTIM BY READING PORT FOR AT LEAST 20MS LOOKING FOR A VALUE
; CHANGE.
;==================================================================================================
;
; WE ASSUME A WORST CASE OF 30MHZ CPU CLOCK
;
; 20MS = 20000US.  AT 1 MHZ, 1US = 1TS.  AT 30MHZ, 1US = 30TS
; SO, 30TS * 20000US = 600000TS TOTAL
; EACH LOOP IS 46TS, SO 600000TS / 48TS = 12,500 LOOPS
;
SCTIM_DETECT:
	LD	BC,12500		; LOOP CONTROL
	IN	A,(SCTIMIO)		; READ STARTING VALUE
	LD	E,A			; PUT IN E
SCTIM_DETECT1:
	IN	A,(SCTIMIO)		; READ VALUE			; 11
	CP	E			; CHANGED?			; 4
	JR	NZ,SCTIM_DETECT2	; HANDLE SUCCESS		; 7
	INC	BC			; INC LOOP CONTROL		; 6
	LD	A,B			; CHECK FOR			; 4
	OR	C			; ... LOOP TIMEOUT		; 4
	JR	NZ,SCTIM_DETECT1	; LOOP TILL EXHAUSTED		; 12, TOTAL: 48
	OR	$FF			; SIGNAL FAILURE
	RET				; AND DONE
SCTIM_DETECT2:
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
; SCTIM DRIVER DATA STORAGE
;
SCTIM_EXIST	.DB	$FF		; SET TO ZERO IF EXISTS
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_SCTIM	.EQU	$
SIZ_SCTIM	.EQU	END_SCTIM - ORG_SCTIM
;	
	MEMECHO	"SCTIM occupies "
	MEMECHO	SIZ_SCTIM
	MEMECHO	" bytes.\n"
;
#ELSE
	.ECHO	"*** WARNING: SCTIM TIMER DISABLED -- ONLY INTMODE 1 SUPPORTED!!!\n"
#ENDIF

