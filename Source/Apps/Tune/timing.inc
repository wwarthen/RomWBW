
;
; Wait for quark play time.  Can use hardware timer if
; supported by hardware or simple delay loop otherwise.
; Delay loop requires QDLY to be pre-set to to achieve
; optimal 20ms wait time.
;
WAITQ	LD	A,(WMOD)		; Get delay mode
	OR	A			; Set flags
	JR	Z,DLY			; Delay mode
;
	; Timer loop
	CALL	TIM2			; Read timer LSB into A
	LD	C,A			; Init prev value
TIM1	PUSH	BC			; Save prev value
	CALL	TIM2			; Read timer LSB into A
	POP	BC			; Recover prev value
	CP	C			; Compare to prev
	RET	NZ			; Done if changed
	JR	TIM1			; Else, loop
;
TIM2	LD	B,$F8			; BIOS SYSGET function
	LD	C,$D0			; TIMER sub-function
	RST	08			; Call BIOS
	LD	A,L			; MSB to A
	RET				; Return to loop
;
	; Delay spin loop (40 tstates per loop)
DLY	LD	BC,(QDLY)		; Load quark delay factor
DLY1	DEC	BC              	; [6]
	NOP				; [4]
	NOP				; [4]
	NOP				; [4]
	NOP				; [4]
	LD	A,B             	; [4]
	OR	C               	; [4]
	JP	NZ,DLY1			; [10]
	RET

;
; Test for timer running to determine if it can be used for delay
; Return string message in DE
; Assigned (WMOD) with 0 if no hardware time, 1 if hardware timer found
;
PROBETIMER:
	LD	B,BF_SYSGET		; HBIOS: GET function
	LD	C,$D0			; TIMER subfunction
	RST	08			; DE:HL := current tick count
	LD	A,L			; DE:HL == 0?
	OR	H
	OR	E
	OR	D
	LD	A,0			; Assume no timer
	LD	DE,MSGDLY		; Delay mode msg
	JR	Z,SETDLY		; If tick count is zero, no timer active
	LD	A,$FF			; Value for timer active
	LD	DE,MSGTIM		; Timer mode msg
SETDLY:
	LD	(WMOD),A		; Save wait mode
	RET
