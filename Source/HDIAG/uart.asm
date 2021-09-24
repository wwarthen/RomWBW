;
;=======================================================================
; HDIAG UART Driver
;=======================================================================
;
; Assumes the UART conventions for SBC/MBC/Zeta, base port at $68.
; Assuming a UART clock frequency of 1.8432 MHz, the baud rate
; will be 38400.
;
uart_iob	.equ	$68
uart_osc	.equ	1843200
uart_baudrate	.equ	38400
uart_divisor	.equ	uart_osc / uart_baudrate / 16
;
uart_rbr	.equ	uart_iob + 0	; dlab=0: rcvr buffer reg (read only)
uart_thr	.equ	uart_iob + 0	; dlab=0: xmit holding reg (write only)
uart_ier	.equ	uart_iob + 1	; dlab=0: int enable reg
uart_iir	.equ	uart_iob + 2	; int ident register (read only)
uart_fcr	.equ	uart_iob + 2	; fifo control reg (write only)
uart_lcr	.equ	uart_iob + 3	; line control reg
uart_mcr	.equ	uart_iob + 4	; modem control reg
uart_lsr	.equ	uart_iob + 5	; line status reg
uart_msr	.equ	uart_iob + 6	; modem status reg
uart_scr	.equ	uart_iob + 7	; scratch register
uart_dll	.equ	uart_iob + 0	; dlab=1: divisor latch (ls)
uart_dlm	.equ	uart_iob + 1	; dlab=1: divisor latch (ms)
;
;
;
uart_jptbl:
	jp	uart_cinit		; Initialize serial port
	jp	uart_cin		; Read byte
	jp	uart_cout		; Write byte
	jp	uart_cist		; Input status
	jp	uart_cost		; Output Status
;
;
;
uart_cinit:
	; Test for existence
	;;;xor	a			; zero accum
	;;;out	(uart_ier),a		; ier := 0
	;;;ld	a,$80			; dlab bit on
	;;;out	(uart_lcr),a		; output to lcr (dlab regs now active)
	;;;ld	a,$5A			; load test value
	;;;out	(uart_dlm),a		; output to dlm
	;;;in	a,(uart_dlm)		; read it back
	;;;cp	$5A			; check for test value
	;;;ret	nz			; nope, unknown uart or not present
	;;;xor	a			; dlab bit off
	;;;out	(uart_lcr),a		; output to lcr (dlab regs now inactive)
	;;;in	a,(uart_ier)		; read ier
	;;;cp	$5A			; check for test value
	;;;jr	nz,uart_cinit1		; if *not* $5A, good to go
	;;;or	$FF			; signal error
	;;;ret				; done
;
uart_cinit1:
	ld	a,$80			; lcr := dlab on
	out	(uart_lcr),a		; set lcr
	ld	a,uart_divisor & $ff	; low byte of divisor
	out	(uart_dll),a		; set divisor (lsb)
	ld	a,uart_divisor / $100	; high byte of divisor
	out	(uart_dlm),a		; set divisor (msb)
	xor	a			; zero accum
	out	(uart_ier),a		; init ier (no ints)
	ld	a,$03			; value for lcr and mcr
	out	(uart_lcr),a		; lcr := 3, dlab off, 8 data, 1 stop, no parity
	out  	(uart_mcr),a		; mcr := 3, dtr on, rts on
	ld	a,$07			; enable & reset fifo's
	out	(uart_fcr),a		; do it
	xor	a			; signal success
	ret
;
;
;
uart_cin:
	call	uart_cist		; received char ready?
	jr	z,uart_cin		; loop if not
	in	a,(uart_rbr)		; read byte
	ret				; and done
;
;
;
uart_cout:
	push	af			; save incoming
uart_cout1:
	call	uart_cost		; ready for char?
	jr	z,uart_cout1		; loop if not
	pop	af			; restore incoming
	out	(uart_thr),a		; write byte
	ret				; and done
;
;
;
uart_cist:
	in	a,(uart_lsr)		; get status
	and	$01			; isolate bit 0 (receive data ready)
	ret				; a != 0 if char ready, else 0
;
;
;
uart_cost:
	in	a,(uart_lsr)		; get status
	and	$20			; isolate bit 5
	ret				; a != 0 if char ready, else 0
