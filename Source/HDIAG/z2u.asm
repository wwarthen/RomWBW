;
;=======================================================================
; HDIAG Z180 UART Driver
;=======================================================================
;
z2u_jptbl:
	jp	z2u_cinit		; Initialize serial port
	jp	z2u_cin			; Read byte
	jp	z2u_cout		; Write byte
	jp	z2u_cist		; Input status
	jp	z2u_cost		; Output Status
;
;
;
z2u_cinit:
	; initialize port here
	or	$FF			; signal failure for now
	ret
;
;
;
z2u_cin:
	call	z2u_cist		; check for char ready
	jr	z,z2u_cin		; if not, loop
	; read byte here
	ret				; done
;
;
;
z2u_cout:
	push	af			; save incoming
z2u_cout1:
	call	z2u_cost		; ready for char?
	jr	z,z2u_cout1		; loop if not
	pop	af			; restore incoming
	; write byte here
	ret				; and done
;
;
;
z2u_cist:
	; check input status here
	ret
;
;
;
z2u_cost:
	; check output status here
	ret				; a != 0 if char ready, else 0
