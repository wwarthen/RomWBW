;
;=======================================================================
; HDIAG SIO Driver
;=======================================================================
;
; Assumes the UART port conventions for RC2014.  Command/status port
; at $80 and read/write data port at $81.
; Assuming a UART clock frequency of 1.8432 MHz, the baud rate
; will be 38400.
;
sio_cmd		.equ	$80		; SIO command/status port
sio_dat		.equ	$81		; SIO read/write port
;
sio_jptbl:
	jp	sio_cinit		; Initialize serial port
	jp	sio_cin			; Read byte
	jp	sio_cout		; Write byte
	jp	sio_cist		; Input status
	jp	sio_cost		; Output Status
;
;
;
sio_cinit:
	; Detect SIO here...
	; Zero the int vector register
	ld	a,2			; select WR2 (int vector)
	out	(sio_cmd+2),a		; do it
	xor	a			; zero accum
	out	(sio_cmd+2),a		; write to WR2
	; Read the int vector register and check for zero
	ld	a,2			; select WR2 (int vector)
	out	(sio_cmd+2),a		; do it
	in	a,(sio_cmd+2)		; get int vector value
	and	$F0			; only top nibble
	ret	nz			; abort if not zero
	; Set test value in int vector register
	ld	a,2			; select WR2 (int vector)
	out	(sio_cmd+2),a		; do it
	ld	a,$FF			; test value
	out	(sio_cmd+2),a		; write to WR2
	; Read the int vector register to confirm value written
	ld	a,2			; select WR2 (int vector)
	out	(sio_cmd+2),a		; do it
	in	a,(sio_cmd+2)		; get int vector value
	and	$F0			; only top nibble
	cp	$F0			; compare
	ret	nz			; abort if miscompare
;
	; Program the SIO, just channel A
	ld	c,sio_cmd		; command port
	ld	hl,sio_initregs		; point to init values
	ld	b,sio_initlen		; count of bytes to write
	otir				; write all values
;
	xor	a			; signal success
	ret				; done
;
;
;
sio_cin:
	call	sio_cist		; check for char ready
	jr	z,sio_cin		; if not, loop
	in	a,(sio_dat)		; read byte
	ret				; done
;
;
;
sio_cout:
	push	af			; save incoming
sio_cout1:
	call	sio_cost		; ready for char?
	jr	z,sio_cout1		; loop if not
	pop	af			; restore incoming
	out	(sio_dat),a		; write byte
	ret				; and done
;
;
;
sio_cist:
	xor	a			; select WR0
	out	(sio_cmd),a		; do it
	in	a,(sio_cmd)		; get status
	and	$01			; isolate rx ready
	ret				; a != 0 if rx ready, else 0
;
;
;
sio_cost:
	xor	a			; select WR0
	out	(sio_cmd),a		; do it
	in	a,(sio_cmd)		; get status
	and	$04			; isolate tx ready (empty)
	ret				; a != 0 if tx ready, else 0
;
; Table for chip register initialization.  Simple setup for clock
; divided by 64.  Assuming a system clock of 7.3728 MHz, this will
; result in a baud rate of 115200 which is standard for RC2014.
;
sio_initregs:
	.db	$00, $18		; wr0: channel reset cmd
	.db	$04, $C4		; wr4: clk baud parity stop bit
	.db	$01, $00		; wr1: no interrupts
	.db	$02, $00		; wr2: im2 vec offset
	.db	$03, $E1		; wr3: 8 bit rcv, cts/dcd auto, rx enable
	.db	$05, $EA		; wr5: dtr, 8 bits send,  tx enable, rts 1 11 0 1 0 1 0 (1=dtr,11=8bits,0=sendbreak,1=txenable,0=sdlc,1=rts,0=txcrc)
;
sio_initlen	.equ	$-sio_initregs

