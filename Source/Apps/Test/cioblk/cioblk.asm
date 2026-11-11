;===============================================================================
; CIOBLK - Test RomWBW HBIOS CIO block read/write API
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   CIOBLK		API checks, console block write & read tests
;   CIOBLK <unit>	API checks, loopback test on char unit <unit>
;
; Operation:
;   Exercises the non-blocking HBIOS functions BF_CIOBLKIN and BF_CIOBLKOUT.
;
;   API checks verify the function is present and that the documented
;   error returns work (buffer below 8000h, invalid unit, zero length).
;
;   Console mode writes a block of text to the console with repeated
;   BF_CIOBLKOUT calls, then echoes whatever is typed or pasted using
;   BF_CIOBLKIN until ESC is pressed.  Statistics show how many bytes
;   each call moved.
;
;   Loopback mode requires a loopback connector (TX tied to RX, and
;   RTS tied to CTS if hardware flow control is enabled) on the
;   specified unit.  A 00h-FFh pattern is sent while reading back
;   concurrently with interleaved non-blocking calls, and every byte
;   received is verified.  Do not use the console unit.
;
;   All buffers passed to HBIOS are in common RAM (8000h or above) as
;   the API requires.
;_______________________________________________________________________________
;
; Change Log:
;   2026-11-06 [WBW] Initial release
;_______________________________________________________________________________
;
; ToDo:
;_______________________________________________________________________________
;
;===============================================================================
; Definitions
;===============================================================================
;
stksiz	.equ	$40		; Working stack size
;
txbuf	.equ	$9000		; Transmit buffer, page aligned, common RAM
rxbuf	.equ	$9100		; Receive buffer, common RAM
bufend	.equ	$9200		; End of buffers
;
lbsize	.equ	2048		; Loopback test byte count
idlemax	.equ	16384		; Loopback idle passes before timeout
;
chesc	.equ	27		; Escape character
;
#include "../../../ver.inc"
;
#include "../../../HBIOS/hbios.inc"
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100
;
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
;
	call	main		; do the work
;
	call	crlf		; formatting
	ld	sp,(stksav)	; restore stack
	ret			; return to CP/M w/o restart
;
; Main program
;
main:
	call	crlf2		; formatting
	ld	de,msgban	; banner
	call	prtstr		; print it
;
	; confirm RomWBW HBIOS of matching version
	call	idbio		; identify active BIOS
	cp	1		; check for HBIOS
	jp	nz,errbio	; handle BIOS error
	ld	a,rmj << 4 | rmn	; expected HBIOS ver
	cp	d		; compare with result above
	jp	nz,errbio	; handle BIOS error
;
	; make sure our buffers are below the top of the TPA
	ld	a,($0007)	; MSB of BDOS address = top of TPA
	cp	bufend >> 8	; room for buffers?
	jp	c,errmem	; if not, error
;
	; get number of char units
	ld	b,BF_SYSGET	; HBIOS SysGet
	ld	c,BF_SYSGET_CIOCNT	; ... char unit count
	rst	08		; E := count
	ld	a,e		; save it
	ld	(ciocnt),a	; ...
;
	; parse optional unit number from command tail
	ld	a,CIO_CONSOLE	; assume console
	ld	(unit),a	; ...
	xor	a		; assume console mode
	ld	(lbmode),a	; ...
	ld	hl,$81		; command tail
	ld	a,($80)		; tail length
	call	addhl		; point past end
	ld	(hl),0		; null terminate
	ld	hl,$81		; back to start
	call	nonblank	; skip blanks
	or	a		; anything?
	jr	z,main1		; if not, console mode
	cp	'?'		; usage request?
	jp	z,erruse	; show usage
	call	getnum		; A := unit number
	jp	c,errprm	; bad number
	ld	(unit),a	; save it
	ld	hl,ciocnt	; check against
	cp	(hl)		; ... unit count
	jp	nc,errunit	; error if too high
	ld	a,$FF		; set
	ld	(lbmode),a	; ... loopback mode
;
main1:
	call	apitest		; do API checks
	ret	nz		; abort if API missing
;
	ld	a,(lbmode)	; which mode?
	or	a		; set flags
	jr	nz,main2	; loopback mode
;
	call	wrtest		; console block write test
	call	rdtest		; console block read test
	jr	main3		; and finish
;
main2:
	call	lbtest		; loopback test
;
main3:
	; final summary
	call	crlf2		; formatting
	ld	a,(fails)	; failure count
	or	a		; any?
	ld	de,msgpass	; assume all passed
	jr	z,main4		; if none, print it
	ld	de,msgfail	; failures message
	call	prtstr		; print it
	ld	a,(fails)	; failure count
	call	prtdecb		; print it
	ld	de,msgfail2	; suffix
main4:
	call	prtstr		; print message
	xor	a		; done
	ret
;
;===============================================================================
; API checks
;===============================================================================
;
apitest:
	call	crlf2		; formatting
	ld	de,msgapi	; section heading
	call	prtstr		; print it
;
	; zero length write to console: function present?
	ld	de,msgt1	; test description
	call	prtstr		; print it
	ld	b,BF_CIOBLKOUT	; block write
	ld	c,CIO_CONSOLE	; console
	ld	e,0		; zero bytes
	ld	hl,txbuf	; valid buffer
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	cp	ERR_NOFUNC & $FF	; function not implemented?
	jp	z,errnosup	; if so, can't test
	ld	d,ERR_NONE	; expected status
	call	chkres		; check and report
;
	; zero length read from console
	ld	de,msgt2	; test description
	call	prtstr		; print it
	ld	b,BF_CIOBLKIN	; block read
	ld	c,CIO_CONSOLE	; console
	ld	e,0		; zero bytes
	ld	hl,rxbuf	; valid buffer
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	ld	d,ERR_NONE	; expected status
	call	chkres		; check and report
;
	; buffer below 8000h must be rejected
	ld	de,msgt3	; test description
	call	prtstr		; print it
	ld	b,BF_CIOBLKIN	; block read
	ld	c,CIO_CONSOLE	; console
	ld	e,16		; some bytes
	ld	hl,$1000	; buffer in banked memory
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	ld	d,ERR_RANGE & $FF	; expected status
	call	chkres		; check and report
;
	; invalid unit must be rejected
	ld	de,msgt4	; test description
	call	prtstr		; print it
	ld	b,BF_CIOBLKOUT	; block write
	ld	a,(ciocnt)	; first invalid unit
	ld	c,a		; ... to C
	ld	e,16		; some bytes
	ld	hl,txbuf	; valid buffer
	rst	08		; do it
	; the unit is rejected by the HBIOS dispatcher before the block
	; function runs, so E is returned unchanged.  check status only.
	ld	e,0		; ignore count
	ld	d,ERR_NOUNIT & $FF	; expected status
	call	chkres		; check and report
;
	xor	a		; API present
	ret
;
; Check result of an API test call.  D=expected status, A=actual status,
; E=actual count (expected 0).  Prints PASS or FAIL and counts failures.
;
chkres:
	cp	d		; status as expected?
	jr	nz,chkres1	; if not, fail
	ld	a,e		; count
	or	a		; must be zero
	jr	nz,chkres1	; if not, fail
	ld	de,msgok	; pass message
	jp	prtstr		; print it and return
chkres1:
	push	de		; save count
	push	af		; save status
	call	addfail		; count failure
	ld	de,msgbad	; fail message
	call	prtstr		; print it
	pop	af		; status
	call	prthex		; print it
	ld	de,msgbad2	; count label
	call	prtstr		; print it
	pop	de		; count
	ld	a,e		; ...
	call	prtdecb		; print it
	ld	a,')'		; close paren
	jp	prtchr		; print it and return
;
addfail:
	ld	hl,fails	; failure counter
	inc	(hl)		; bump it
	ret
;
;===============================================================================
; Console block write test
;===============================================================================
;
wrtest:
	call	crlf2		; formatting
	ld	de,msgwr	; section heading
	call	prtstr		; print it
	call	crlf2		; formatting
;
	; copy text to common RAM buffer
	ld	hl,wrtxt	; source
	ld	de,txbuf	; destination
	ld	bc,wrlen	; length
	ldir			; copy
;
	call	clrstat		; reset statistics
	ld	hl,txbuf	; buffer
	ld	a,wrlen		; length
	call	blkwrite	; write it all
	ret	nz		; bail out on error (already reported)
;
	; report
	call	crlf		; formatting
	ld	de,msgwrs1	; "Wrote "
	call	prtstr
	ld	a,wrlen		; bytes
	call	prtdecb
	ld	de,msgwrs2	; " bytes in "
	call	prtstr
	ld	hl,(wcalls)	; calls
	call	prtdecw
	ld	de,msgwrs3	; " calls ("
	call	prtstr
	ld	hl,(wzero)	; calls that accepted nothing
	call	prtdecw
	ld	de,msgwrs4	; " accepted 0), max "
	call	prtstr
	ld	a,(wmax)	; max per call
	call	prtdecb
	ld	de,msgwrs5	; " bytes per call"
	call	prtstr
;
	; result must account for every byte
	ld	a,(wtotal)	; bytes counted from returns
	cp	wrlen		; match?
	ret	z		; if so, done
	call	addfail		; else count failure
	ld	de,msgwrbad	; and report
	jp	prtstr
;
; Write A bytes at HL to (unit) using repeated BF_CIOBLKOUT calls,
; accumulating statistics.  Returns NZ on an API error.
;
blkwrite:
	ld	(wptr),hl	; save pointer
	ld	(wrem),a	; save remaining
blkwr1:
	ld	a,(wrem)	; bytes remaining
	or	a		; done?
	ret	z		; if so, return Z
	ld	e,a		; E := count
	ld	b,BF_CIOBLKOUT	; block write
	ld	a,(unit)	; unit
	ld	c,a		; ... to C
	ld	hl,(wptr)	; buffer
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	or	a		; set flags
	jp	nz,apierr	; report API error, return NZ
	call	wstat		; update write statistics with E
	ld	hl,(wptr)	; advance pointer
	ld	a,e		; ... by
	call	addhl		; ... count written
	ld	(wptr),hl	; ...
	ld	a,(wrem)	; reduce
	sub	e		; ... remaining
	ld	(wrem),a	; ...
	jr	blkwr1		; loop
;
;===============================================================================
; Console block read test
;===============================================================================
;
rdtest:
	call	crlf2		; formatting
	ld	de,msgrd	; section heading / prompt
	call	prtstr		; print it
	call	crlf2		; formatting
;
	call	clrstat		; reset statistics
rdtest1:
	ld	b,BF_CIOBLKIN	; block read
	ld	c,CIO_CONSOLE	; console
	ld	e,255		; up to 255 bytes
	ld	hl,rxbuf	; buffer
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	or	a		; set flags
	jp	nz,apierr	; report API error
	ld	a,e		; got anything?
	or	a		; ...
	jr	z,rdtest1	; if not, keep polling
	call	rstat		; update read statistics with E
;
	; look for ESC in what we got
	ld	b,e		; count
	ld	c,0		; bytes before ESC
	ld	hl,rxbuf	; data
rdtest2:
	ld	a,(hl)		; next byte
	cp	chesc		; ESC?
	jr	z,rdtest3	; if so, finish
	inc	hl		; next
	inc	c		; count it
	djnz	rdtest2		; loop through data
;
	; no ESC, echo all of it and keep going
	ld	hl,rxbuf	; data
	ld	a,e		; count
	call	blkwrite	; echo it
	ret	nz		; bail out on error
	jr	rdtest1		; and loop
;
rdtest3:
	; echo bytes ahead of ESC, then report
	ld	a,c		; count before ESC
	or	a		; any?
	ld	hl,rxbuf	; data
	call	nz,blkwrite	; echo them
;
	call	crlf2		; formatting
	ld	de,msgrds1	; "Read "
	call	prtstr
	ld	hl,(rtotal)	; total bytes
	call	prtdecw
	ld	de,msgrds2	; " bytes, "
	call	prtstr
	ld	hl,(rdata)	; calls returning data
	call	prtdecw
	ld	de,msgrds3	; " calls returned data, max "
	call	prtstr
	ld	a,(rmax)	; max per call
	call	prtdecb
	ld	de,msgwrs5	; " bytes per call"
	jp	prtstr
;
;===============================================================================
; Loopback test
;===============================================================================
;
lbtest:
	call	crlf2		; formatting
	ld	de,msglb	; section heading
	call	prtstr		; print it
	ld	a,(unit)	; unit
	call	prtdecb		; print it
	ld	de,msglb2	; rest of heading
	call	prtstr		; print it
;
	; fill transmit buffer with 00h-FFh
	ld	hl,txbuf	; buffer
	xor	a		; first value
lbtest1:
	ld	(hl),a		; store
	inc	hl		; next
	inc	a		; next value
	jr	nz,lbtest1	; loop for 256 bytes
;
	; discard anything already waiting
	ld	b,0		; at most 256 tries
lbtest2:
	push	bc		; save counter
	ld	b,BF_CIOBLKIN	; block read
	ld	a,(unit)	; unit
	ld	c,a		; ... to C
	ld	e,255		; up to 255
	ld	hl,rxbuf	; buffer
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	pop	bc		; restore counter
	or	a		; error?
	jp	nz,apierr	; report it
	ld	a,e		; got anything?
	or	a		; ...
	jr	z,lbtest3	; if not, drained
	djnz	lbtest2		; else keep draining
;
lbtest3:
	call	clrstat		; reset statistics
	ld	hl,0		; zero
	ld	(txcnt),hl	; bytes sent
	ld	(rxcnt),hl	; bytes received
	ld	(errcnt),hl	; mismatches
	ld	(idle),hl	; idle passes
;
lbloop:
	xor	a		; no progress yet
	ld	(prog),a	; ...
;
	; --- transmit side: send as much as the device will take ---
	ld	hl,(txcnt)	; bytes sent so far
	ld	de,lbsize	; total
	ex	de,hl		; HL := total, DE := sent
	or	a		; clear carry
	sbc	hl,de		; HL := bytes left to send
	jr	z,lbrx		; if none, skip transmit
	ld	a,h		; >= 256 left?
	or	a		; ...
	ld	a,255		; assume max
	jr	nz,lbtx1	; if so, use max
	ld	a,l		; else use what is left
lbtx1:
	ld	b,a		; B := limit by remaining
	ld	a,e		; offset in pattern buffer (sent & FFh)
	neg			; A := bytes to end of buffer
	jr	nz,lbtx2	; if offset was 0, ...
	ld	a,255		; ... whole buffer (max 255)
lbtx2:
	cp	b		; take smaller of the two
	jr	c,lbtx3		; A is smaller
	ld	a,b		; B is smaller
lbtx3:
	ld	l,e		; HL := txbuf + offset
	ld	h,txbuf >> 8	; ...
	ld	e,a		; E := count
	ld	b,BF_CIOBLKOUT	; block write
	ld	a,(unit)	; unit
	ld	c,a		; ... to C
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	or	a		; error?
	jp	nz,apierr	; report it
	call	wstat		; update write statistics
	ld	a,e		; anything sent?
	or	a		; ...
	jr	z,lbrx		; if not, go read
	ld	hl,(txcnt)	; bump sent count
	call	addhl		; ...
	ld	(txcnt),hl	; ...
	ld	a,$FF		; note progress
	ld	(prog),a	; ...
;
lbrx:
	; --- receive side: take whatever has arrived ---
	ld	b,BF_CIOBLKIN	; block read
	ld	a,(unit)	; unit
	ld	c,a		; ... to C
	ld	e,255		; up to 255
	ld	hl,rxbuf	; buffer
	rst	08		; do it
	ld	e,d		; E := bytes transferred (returned in D)
	or	a		; error?
	jp	nz,apierr	; report it
	ld	a,e		; got anything?
	or	a		; ...
	jr	z,lbnext	; if not, check progress
	call	rstat		; update read statistics
	ld	a,$FF		; note progress
	ld	(prog),a	; ...
;
	; verify each byte against the expected pattern
	ld	b,e		; count
	ld	hl,rxbuf	; data
lbrx1:
	ld	a,(rxcnt)	; expected value (received & FFh)
	cp	(hl)		; match?
	call	nz,lbmiss	; if not, record mismatch
	push	hl		; bump received count
	ld	hl,(rxcnt)	; ...
	inc	hl		; ...
	ld	(rxcnt),hl	; ...
	pop	hl		; ...
	inc	hl		; next byte
	djnz	lbrx1		; loop
;
lbnext:
	; done when everything has come back
	ld	hl,(rxcnt)	; received
	ld	de,lbsize	; total
	or	a		; clear carry
	sbc	hl,de		; received - total
	jr	nc,lbdone	; if received >= total, done
;
	; track passes without progress for timeout
	ld	a,(prog)	; progress this pass?
	or	a		; ...
	ld	hl,0		; assume reset
	jr	nz,lbnext1	; if progress, reset idle count
	ld	hl,(idle)	; else bump
	inc	hl		; ... idle count
lbnext1:
	ld	(idle),hl	; save idle count
	ld	de,idlemax	; limit
	or	a		; clear carry
	sbc	hl,de		; reached?
	jp	c,lbloop	; if not, keep going
;
	; timed out
	call	addfail		; count failure
	call	crlf		; formatting
	ld	de,msglbto	; timeout message
	call	prtstr		; print it
;
lbdone:
	; report
	call	crlf		; formatting
	ld	de,msglbs1	; "Sent "
	call	prtstr
	ld	hl,(txcnt)
	call	prtdecw
	ld	de,msglbs2	; ", received "
	call	prtstr
	ld	hl,(rxcnt)
	call	prtdecw
	ld	de,msglbs3	; ", mismatches "
	call	prtstr
	ld	hl,(errcnt)
	call	prtdecw
;
	call	crlf		; formatting
	ld	de,msglbs4	; "Write: max "
	call	prtstr
	ld	a,(wmax)
	call	prtdecb
	ld	de,msglbs5	; " bytes in one call, "
	call	prtstr
	ld	hl,(wcalls)
	call	prtdecw
	ld	de,msglbs6	; " calls ("
	call	prtstr
	ld	hl,(wzero)
	call	prtdecw
	ld	de,msglbs7	; " accepted 0)"
	call	prtstr
;
	call	crlf		; formatting
	ld	de,msglbs8	; "Read:  max "
	call	prtstr
	ld	a,(rmax)
	call	prtdecb
	ld	de,msglbs5	; " bytes in one call, "
	call	prtstr
	ld	hl,(rdata)
	call	prtdecw
	ld	de,msglbs9	; " calls returned data"
	call	prtstr
;
	; mismatches are failures
	ld	hl,(errcnt)	; mismatches
	ld	a,h		; any?
	or	l		; ...
	ret	z		; if none, done
	call	addfail		; count failure
	call	crlf		; formatting
	ld	de,msglbm1	; first mismatch at
	call	prtstr
	ld	hl,(misspos)
	call	prtdecw
	ld	de,msglbm2	; ": expected "
	call	prtstr
	ld	a,(missexp)
	call	prthex
	ld	de,msglbm3	; ", got "
	call	prtstr
	ld	a,(missgot)
	jp	prthex
;
; Record a receive mismatch.  A=expected, (HL)=received.
;
lbmiss:
	push	hl		; save pointer
	push	de		; save DE
	ld	de,(errcnt)	; first one?
	ld	c,a		; save expected
	ld	a,d		; ...
	or	e		; ...
	jr	nz,lbmiss1	; if not first, just count
	ld	a,c		; record expected
	ld	(missexp),a	; ...
	ld	a,(hl)		; record received
	ld	(missgot),a	; ...
	ld	hl,(rxcnt)	; record position
	ld	(misspos),hl	; ...
lbmiss1:
	inc	de		; bump mismatch count
	ld	(errcnt),de	; ...
	pop	de		; restore
	pop	hl		; ...
	ret
;
;===============================================================================
; Statistics helpers
;===============================================================================
;
clrstat:
	ld	hl,statbeg	; zero all
	ld	b,statlen	; ... statistics
	xor	a		; ...
clrstat1:
	ld	(hl),a		; ...
	inc	hl		; ...
	djnz	clrstat1	; ...
	ret
;
; Update write statistics with E bytes accepted by one call.
; Preserves DE.
;
wstat:
	ld	hl,(wcalls)	; bump call count
	inc	hl		; ...
	ld	(wcalls),hl	; ...
	ld	a,e		; accepted
	or	a		; zero?
	jr	nz,wstat1	; if not, skip
	ld	hl,(wzero)	; bump zero count
	inc	hl		; ...
	ld	(wzero),hl	; ...
wstat1:
	ld	hl,wtotal	; running total (8-bit, console test only)
	ld	a,(hl)		; ...
	add	a,e		; ...
	ld	(hl),a		; ...
	ld	a,(wmax)	; new max?
	cp	e		; ...
	ret	nc		; if not, done
	ld	a,e		; save new max
	ld	(wmax),a	; ...
	ret
;
; Update read statistics with E bytes returned by one call.
; Preserves DE.
;
rstat:
	ld	hl,(rdata)	; bump calls returning data
	inc	hl		; ...
	ld	(rdata),hl	; ...
	ld	hl,(rtotal)	; add to total
	ld	a,e		; ...
	call	addhl		; ...
	ld	(rtotal),hl	; ...
	ld	a,(rmax)	; new max?
	cp	e		; ...
	ret	nc		; if not, done
	ld	a,e		; save new max
	ld	(rmax),a	; ...
	ret
;
;===============================================================================
; Utility routines
;===============================================================================
;
; Parse a decimal number (0-255) at HL into A.  CF set on error.
;
getnum:
	ld	c,0		; accumulator
	ld	a,(hl)		; first char
	call	isdigit		; must be a digit
	ret	c		; if not, error
getnum1:
	ld	a,(hl)		; next char
	call	isdigit		; digit?
	jr	c,getnum2	; if not, end of number
	sub	'0'		; binary value
	ld	b,a		; save digit
	ld	a,c		; accum * 10
	cp	26		; would overflow?
	ccf			; CF set if so
	ret	c		; error
	add	a,a		; * 2
	ld	c,a		; save * 2
	add	a,a		; * 4
	add	a,a		; * 8
	add	a,c		; * 10
	add	a,b		; + digit
	ret	c		; error on overflow
	ld	c,a		; save
	inc	hl		; next char
	jr	getnum1		; loop
getnum2:
	call	nonblank	; skip trailing blanks
	or	a		; must be end of line
	scf			; assume error
	ret	nz		; if not end, error
	ld	a,c		; result
	or	a		; clear carry
	ret
;
; CF clear if A is an ASCII digit
;
isdigit:
	cp	'0'		; below '0'?
	ret	c		; error
	cp	'9' + 1		; above '9'?
	ccf			; CF set if so
	ret
;
; Identify active BIOS.  RomWBW HBIOS=1, UNA UBIOS=2, else 0
;
idbio:
;
	; Check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,idbio1	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,idbio1	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,idbio1	; if not, not UNA, check others
;
	ld	bc,$04FA	; UNA: get BIOS date and version
	rst	08		; DE := ver, HL := date
;
	ld	a,2		; UNA BIOS id = 2
	ret			; and done
;
idbio1:
	; Check for RomWBW (HBIOS)
	ld	hl,(HB_IDENT)	; HL := HBIOS ident location
	ld	a,'W'		; First byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
	inc	hl		; Next byte of ident
	ld	a,~'W'		; Second byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
;
	ld	b,BF_SYSVER	; HBIOS: VER function
	ld	c,0		; required reserved value
	rst	08		; DE := version, L := platform id
;
	ld	a,1		; HBIOS BIOS id = 1
	ret			; and done
;
idbio2:
	; No idea what this is
	xor	a		; Setup return value of 0
	ret			; and done
;
; Print character in A without destroying any registers
;
prtchr:
	push	af		; save registers
	push	bc
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	b,BF_CIOOUT	; HBIOS function to output a character
	ld	c,CIO_CONSOLE	; write to current console unit
	rst	08		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	pop	af
	ret
;
; Print a zero terminated string at (DE) without destroying any registers
;
prtstr:
	push	af
	push	de
prtstr1:
	ld	a,(de)		; get next char
	or	a
	jr	z,prtstr2
	call	prtchr
	inc	de
	jr	prtstr1
prtstr2:
	pop	de		; restore registers
	pop	af
	ret
;
; Print the value in A in hex without destroying any registers
;
prthex:
	push	af		; save AF
	push	de		; save DE
	call	hexascii	; convert value in A to hex chars in DE
	ld	a,d		; get the high order hex char
	call	prtchr		; print it
	ld	a,e		; get the low order hex char
	call	prtchr		; print it
	ld	a,'h'		; hex suffix
	call	prtchr		; print it
	pop	de		; restore DE
	pop	af		; restore AF
	ret			; done
;
; Convert binary value in A to ascii hex characters in DE
;
hexascii:
	ld	d,a		; save A in D
	call	hexconv		; convert low nibble of A to hex
	ld	e,a		; save it in E
	ld	a,d		; get original value back
	rlca			; rotate high order nibble to low bits
	rlca
	rlca
	rlca
	call	hexconv		; convert nibble
	ld	d,a		; save it in D
	ret			; done
;
; Convert low nibble of A to ascii hex
;
hexconv:
	and	$0F	     	; low nibble only
	add	a,$90
	daa
	adc	a,$40
	daa
	ret
;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
prtdecb:
	push	hl
	ld	h,0
	ld	l,a
	call	prtdecw		; print it
	pop	hl
	ret
;
prtdecw:
	push	af
	push	bc
	push	de
	push	hl
	call	prtdec0
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
prtdec0:
	ld	e,'0'
	ld	bc,-10000
	call	prtdec1
	ld	bc,-1000
	call	prtdec1
	ld	bc,-100
	call	prtdec1
	ld	c,-10
	call	prtdec1
	ld	e,0
	ld	c,-1
prtdec1:
	ld	a,'0' - 1
prtdec2:
	inc	a
	add	hl,bc
	jr	c,prtdec2
	sbc	hl,bc
	cp	e
	ret	z
	ld	e,0
	call	prtchr
	ret
;
; Start a new line
;
crlf2:
	call	crlf		; two of them
crlf:
	push	af		; preserve AF
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	call	prtchr		; print it
	pop	af		; restore AF
	ret
;
; Get the next non-blank character from (HL).
;
nonblank:
	ld	a,(hl)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	hl		; if blank, increment character pointer
	jr	nonblank	; and loop
;
; Add the value in A to HL (HL := HL + A)
;
addhl:
	add	a,l		; A := A + L
	ld	l,a		; Put result back in L
	ret	nc		; if no carry, we are done
	inc	h		; if carry, increment H
	ret			; and return
;
;===============================================================================
; Errors
;===============================================================================
;
erruse:	; command usage error (syntax)
	ld	de,msguse
	jr	err
;
errprm:	; command parameter error (syntax)
	ld	de,msgprm
	jr	err
;
errbio:	; invalid BIOS or version
	ld	de,msgbio
	jr	err
;
errmem:	; TPA too small for buffers
	ld	de,msgmem
	jr	err
;
errunit:	; unit number too high
	ld	de,msgunit
	jr	err
;
errnosup:	; HBIOS lacks block functions
	call	crlf2		; formatting
	ld	de,msgnosup
	call	prtstr
	or	$FF		; signal error
	ret
;
apierr:	; unexpected API error, status in A
	push	af		; save status
	call	addfail		; count failure
	call	crlf2		; formatting
	ld	de,msgapie	; message
	call	prtstr		; print it
	pop	af		; status
	call	prthex		; print it
	or	$FF		; signal error
	ret
;
err:	; print error string and return error signal
	call	crlf2		; print newline
	call	prtstr		; print error string
	or	$FF		; signal error
	ret			; done
;
;===============================================================================
; Storage Section
;===============================================================================
;
ciocnt	.db	0		; number of char units
unit	.db	0		; unit under test
lbmode	.db	0		; non-zero for loopback mode
fails	.db	0		; failure count
;
wptr	.dw	0		; blkwrite pointer
wrem	.db	0		; blkwrite remaining
;
txcnt	.dw	0		; loopback bytes sent
rxcnt	.dw	0		; loopback bytes received
errcnt	.dw	0		; loopback mismatches
idle	.dw	0		; loopback idle passes
prog	.db	0		; loopback progress flag
misspos	.dw	0		; first mismatch position
missexp	.db	0		; first mismatch expected
missgot	.db	0		; first mismatch received
;
statbeg	.equ	$		; statistics (cleared by clrstat)
wcalls	.dw	0		; write calls
wzero	.dw	0		; write calls accepting 0
wmax	.db	0		; max accepted by one write call
wtotal	.db	0		; total accepted (console test)
rdata	.dw	0		; read calls returning data
rtotal	.dw	0		; total bytes read
rmax	.db	0		; max returned by one read call
statlen	.equ	$ - statbeg
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Console write test text (copied to common RAM before use)
;
wrtxt	.db	"  The quick brown fox jumps over the lazy dog.  0123456789",13,10
	.db	"  This text was written with HBIOS BF_CIOBLKOUT block calls.",13,10
	.db	"  Each call writes as many bytes as the device reports room for",13,10
	.db	"  and returns at once, so the caller is never blocked.",13,10
wrlen	.equ	$ - wrtxt
;
; Messages
;
msgban	.db	"CIOBLK v1.0, 06-Nov-2026",13,10
	.db	"Copyright (C) 2026, Wayne Warthen, GNU GPL v3",0
msguse	.db	"Usage: CIOBLK [<unit>]",13,10
	.db	"  no unit: API checks plus console block write and read tests",13,10
	.db	"  <unit>:  API checks plus loopback test on char unit <unit>",13,10
	.db	"           (loopback connector required, not the console)",0
msgprm	.db	"Parameter error (CIOBLK ? for usage)",0
msgbio	.db	"Incompatible BIOS or version, "
	.db	"HBIOS v", '0' + rmj, ".", '0' + rmn, " required",0
msgmem	.db	"TPA too small, buffers at 9000h-91FFh required",0
msgunit	.db	"Invalid char unit number",0
msgnosup .db	"This HBIOS does not implement BF_CIOBLKIN/BF_CIOBLKOUT",0
msgapie	.db	"*** Unexpected API error, status=",0
msgapi	.db	"API checks:",0
msgt1	.db	13,10,"  Zero-length write ............. ",0
msgt2	.db	13,10,"  Zero-length read .............. ",0
msgt3	.db	13,10,"  Buffer below 8000h rejected ... ",0
msgt4	.db	13,10,"  Invalid unit rejected ......... ",0
msgok	.db	"PASS",0
msgbad	.db	"FAIL (status=",0
msgbad2	.db	", count=",0
msgwr	.db	"Console block write test:",0
msgwrs1	.db	"Wrote ",0
msgwrs2	.db	" bytes in ",0
msgwrs3	.db	" calls (",0
msgwrs4	.db	" accepted 0), max ",0
msgwrs5	.db	" bytes per call",0
msgwrbad .db	13,10,"*** FAIL: byte count returned does not match",0
msgrd	.db	"Console block read test: type or paste text, ESC to finish",0
msgrds1	.db	"Read ",0
msgrds2	.db	" bytes, ",0
msgrds3	.db	" calls returned data, max ",0
msglb	.db	"Loopback test on unit ",0
msglb2	.db	", 2048 bytes...",0
msglbto	.db	"*** FAIL: timed out waiting for data",0
msglbs1	.db	"Sent ",0
msglbs2	.db	", received ",0
msglbs3	.db	", mismatches ",0
msglbs4	.db	"Write: max ",0
msglbs5	.db	" bytes in one call, ",0
msglbs6	.db	" calls (",0
msglbs7	.db	" accepted 0)",0
msglbs8	.db	"Read:  max ",0
msglbs9	.db	" calls returned data",0
msglbm1	.db	"*** First mismatch at byte ",0
msglbm2	.db	": expected ",0
msglbm3	.db	", got ",0
msgpass	.db	"All tests passed",0
msgfail	.db	"*** ",0
msgfail2 .db	" test(s) FAILED",0
;
	.end
