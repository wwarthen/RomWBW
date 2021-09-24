;
;=======================================================================
; HDIAG ASCI Driver
;=======================================================================
;
; ASCI0 is programmed with a fixed divisor of 480, resulting in a
; baud rate of 38400 at the standard cpu frequency of 18.432 MHz
;
; The Z180 may relocate it's internal I/O to begin at different
; starting port addresses.  This driver relies upon an HDIAG global
; variable to dynamically adjust to the right port address.
;
;
asci_jptbl:
	jp	asci_cinit			; Initialize serial port
	jp	asci_cin			; Read byte
	jp	asci_cout			; Write byte
	jp	asci_cist			; Input status
	jp	asci_cost			; Output Status
;
;
;
asci_cinit:
	; Detect ASCI
	ld	a,(hd_cpu)		; get cpu type
	cp	hd_cpu_z180
	jr	c, asci_cinit1		; less than Z180, abort
	cp	hd_cpu_z280
	jr	nc, asci_cinit1		; greater than Z180, abort
;	
	; Initialize ASCI
	ld	a,%01100100		; rcv enable, xmit enable, no parity
	out0	(z180_cntla0),a		; set cntla
	ld	a,%00100000		; div 30, div 16, div 1 (38400 baud for 18.432mhz cpu)
	out0	(z180_cntlb0),a		; set cntlb
	ld	a,%01100110		; no cts, no dcd, no break detect
	out0	(z180_asext0),a		; set asext
	xor	a			; no interrupts
	out0	(z180_stat0),a		; set stat0
	xor	a			; signal success
	ret				; done
;
asci_cinit1:
	or	$FF			; signal error
	ret				; done
;
;
;
asci_cin:
	call	asci_cist		; check for char ready
	jr	z,asci_cin		; if not, loop
	in0	a,(z180_rdr0)		; get char
	ret				; done
;
;
;
asci_cout:
	push	af			; save incoming
asci_cout1:
	call	asci_cost		; ready for char?
	jr	z,asci_cout1		; loop if not
	pop	af			; restore incoming
	out0	(z180_tdr0),a		; write byte
	ret				; and done
;
;
;
asci_cist:
	in0	a,(z180_stat0)		; get status
	push	af			; save status
	and	$70			; line error?
	jr	z,asci_cist1		; continue if no errors
;
	; clear line error(s) or nothing further can be received!!!
	in0	a,(z180_cntla0)		; read cntla
	res	3,a			; clear efr (error flag reset)
	out0	(z180_cntla0),a		; update cntla
;
asci_cist1:
	pop	af			; recover original status
	and	$80			; data ready?
	ret
;
;
;
asci_cost:
	in0	a,(z180_stat0)		; get status
	and	$02			; isolate bit 5
	ret				; a != 0 if char ready, else 0
