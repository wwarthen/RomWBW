;
;=======================================================================
; HDIAG ACIA Driver
;=======================================================================
;
acia_cmd	.equ	$80
acia_dat	.equ	$81
;
;
;
acia_jptbl:
	jp	acia_cinit		; Initialize serial port
	jp	acia_cin		; Read byte
	jp	acia_cout		; Write byte
	jp	acia_cist		; Input status
	jp	acia_cost		; Output Status
;
;
;
acia_cinit:
	; Detect ACIA
	ld	a,$03			; master reset
	out	(acia_cmd),a		; apply it
	in	a,(acia_cmd)		; get status
	or	a			; check for zero (expected)
	ret	nz			; abort if not
	ld	a,$02			; clear master reset
	out	(acia_cmd),a		; apply it
	in	a,(acia_cmd)		; get status again
	and	%00001110		; isolate reliable bits
	cp	%00000010		; check for expected value
	ret	nz			; abort if not
	; Initialize ACIA
	ld	a,%00010110             ; default config
	out	(acia_cmd),a		; apply it
	xor	a			; signal success
	ret
;
;
;
acia_cin:
	call	acia_cist		; check for char ready
	jr	z,acia_cin		; if not, loop
	in	a,(acia_dat)		; read byte
	ret				; done
;
;
;
acia_cout:
	push	af			; save incoming
acia_cout1:
	call	acia_cost		; ready for char?
	jr	z,acia_cout1		; loop if not
	pop	af			; restore incoming
	out	(acia_dat),a		; write byte
	ret				; and done
;
;
;
acia_cist:
	in	a,(acia_cmd)		; get status
	and	$01			; isolate rx ready
	ret				; done
;
;
;
acia_cost:
	in	a,(acia_cmd)		; get status
	and	$02			; isolate tx empty
	ret				; done
