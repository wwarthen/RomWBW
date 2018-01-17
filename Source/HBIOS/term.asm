;======================================================================
;	TERMINAL DRIVER FOR SBC PROJECT
;
;	SERIAL PSEUDO-DEVICE DRIVER PROVIDES A TERMINAL EMULATION
;	INTERFACE FOR VDA DEVICES
;
;	WRITTEN BY: WAYNE WARTHEN -- 04/10/2016
;======================================================================
;
; TODO:
;   - HANDLE MULTIPLE INSTANCES
;
;======================================================================
; TERMINAL DRIVER - CONSTANTS
;======================================================================
;
;
;======================================================================
; TERMINAL DRIVER - ATTACH
;======================================================================
;
; A VDA DRIVER CALLS THE ATTACH FUNCTION WHEN IT INITIALIZES TO
; CREATE A TERMINAL EMULATION INSTANCE.  THE VDA DRIVER PASSES
; IN IT'S DISPATCH ADDRESS FOR USE BY THE EMULATION MODULES.  THE
; TERMINAL DRIVER ADDS ITSELF AS AN ENTRY IN THE SERIAL UNIT LIST.
;
; CURRENTLY, ONLY A SINGLE INSTANCE OF THE TERMINAL DRIVER IS SUPPORTED.
; ANY ATTEMPT TO ATTACH AFTER THE FIRST WILL RETURN A FAILURE.
;
;   C: VIDEO UNIT NUMBER OF CALLING VDA DRIVER
;   DE: VDA DRIVER'S DISPATCH ADDRESS
;   HL: VDA DRIVER'S INSTANCE DATA
;
TERM_ATTACH:
;
	LD	A,(TERM_DEVCNT)		; GET NEXT DEVICE NUMBER TO USE
	LD	B,A			; PUT IT IN B
	PUSH	HL			; SAVE VDA INSTANCE DATA PTR
;
	; SETUP EMULATOR MODULE FUNC TBL ADDRESS BASED ON DESIRED EMULATION
	; EMULATOR PASSES BACK IT'S FUNC TBL ADDRESS IN DE
	OR	$FF			; PRESET FAILURE
#IF (VDAEMU == EMUTYP_TTY)
	CALL	TTY_INIT		; INIT TTY, DE := TTY_FNTBL
#ENDIF
#IF (VDAEMU == EMUTYP_ANSI)
	CALL	ANSI_INIT		; INIT ANSI, DE := ANSI_FNTBL
#ENDIF
	POP	HL			; RECOVER VDA INSTANCE DATA  PTR
	RET	NZ			; BAIL OUT ON ERROR
;
	; ADD OURSELVES TO CIO DISPATCH TABLE
	PUSH	DE			; COPY EMULATOR FUNC TBL ADDRESS
	POP	BC			; ... TO BC
	PUSH	HL			; COPY VDA INSTANCE DATA PTR
	POP	DE			; ... TO DE
	CALL	CIO_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED
	LD	(HCB + HCB_CRTDEV),A	; SET OURSELVES AS THE CRT DEVICE
;
	; INCREMENT DEVICE COUNT
	LD	HL,TERM_DEVCNT		; POINT TO DEVICE COUNT
	INC	(HL)			; INCREMENT IT
;
	XOR	A			; SIGNAL SUCCESS
	RET				; RETURN
;
;======================================================================
; TERMINAL DRIVER PRIVATE DATA
;======================================================================
;
TERM_DEVCNT	.DB	0		; TERMINAL DEVICE COUNT
;
;======================================================================
; EMULATION MODULES
;======================================================================
;
#INCLUDE "tty.asm"
#INCLUDE "ansi.asm"
