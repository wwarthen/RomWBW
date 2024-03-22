;
;=======================================================================
; Zilog PIO Monitor & Hardware Testing Application
;=======================================================================
;
iodef	.equ	$B8	; Default base I/O port address
;
;
;
; Port address offsets from base address
iodata	.equ	0	; Channel A Data
iodatb	.equ	1	; Channel B Data
ioctla	.equ	2	; Channel A Control
ioctlb	.equ	3	; Channel B Control
;
intveca	.equ	0	; Channel A interrupt vector
intvecb	.equ	1	; Channel B interrupt vector
;
iocmd	.equ	$E3	; PS/2 controller command port address
iodat	.equ	$E2	; PS/2 controller data port address
;
cpumhz	.equ	8	; for time delay calculations (not critical)
;
; General operational equates (should not requre adjustment)
;
stksiz	.equ	$40			; Working stack size
buflen	.equ	$80			; Command buffer length
;
ltimout	.equ	0			; 256*10ms = 2.56s
stimout	.equ	10			; 10*10ms = 100ms
;
restart	.equ	$0000			; CP/M restart vector
bdos	.equ	$0005			; BDOS invocation vector
;
bf_sysint			.equ	$FC	; INT function
;		
bf_sysintinfo			.equ	$00	; INT INFO subfunction
bf_sysintget			.equ	$10	; INT GET subfunction
bf_sysintset			.equ	$20	; INT SET subfunction
;
bel	.equ	7	; ASCII bell
bs	.equ	8	; ASCII backspace
lf	.equ	10	; ASCII linefeed
cr	.equ	13	; ASCII carriage return
;
;=======================================================================
;
	.org	$100	; standard CP/M executable
;
;
	; setup stack (save old value)
	ld	(stksav),sp		; save stack
	ld	sp,stack		; set new stack
;
	call	nl
	ld	hl,str_banner		; banner
	call	pstr
;
getport1:
	ld	hl,str_port1
	call	pstr
	ld	a,(iobase)
	call	prthexbyte
	ld	hl,str_port2
	call	pstr
	call	rdln
	ld	ix,cmdbuf
	call	skipws
	or	a
	jr	z,getport2
	call	ishex
	jr	nz,getport1
	call	gethex			; get port value
	jp	c,getport1		; handle overflow
	ld	(iobase),a		; save value
;
getport2:
	call	init
;
	call	main			; do the real work
;
exit:
	call	deinit
;
	call	nl2
	ld	hl,str_exit
	call	pstr
;
	; clean up and return to command processor
	call	nl			; formatting
	ld	sp,(stksav)		; restore stack
	jp	restart			; return to CP/M via restart
;
;=======================================================================
; Initialize
;=======================================================================
;
init:
	; Install interrupt handler in upper mem
	ld	hl,reladr
	ld	de,$A000
	ld	bc,hsiz
	ldir
;       
	; Install interrupt vectors (RomWBW specific!!!)
	ld	hl,inta		; pointer to my interrupt handler
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	e,intveca	; vector idx
	di
	rst	08		; do it
	ld	(orgveca),hl	; save the original vector
	ei			; interrupts back on
	ld	hl,intb		; pointer to my interrupt handler
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	e,intvecb	; vector idx
	di
	rst	08		; do it
	ld	(orgvecb),hl	; save the original vector
	ei			; interrupts back on
;       
	; Load the interrupt vectors
	ld	a,(iobase)
	add	a,ioctla
	ld	c,a
	ld	a,intveca * 2
	out	(c),a
	ld	a,(iobase)
	add	a,ioctlb
	ld	c,a
	ld	a,intvecb * 2
	out	(c),a
;
	; Set the interrupt control words
	ld	a,(iobase)
	add	a,ioctla
	ld	c,a
	ld	a,%10000111
	out	(c),a			; int enab, no mask follows
	;ld	a,%11111111
	;out	(ioctla),a		; no ints in control mode
	ld	a,(iobase)
	add	a,ioctlb
	ld	c,a
	ld	a,%10000111
	out	(c),a			; int enab, no mask follows
	;ld	a,%11111111
	;out	(ioctlb),a		; no ints in control mode
;
	ret
;
deinit:
	call	reset
;
	ld	a,(iobase)
	add	a,ioctla
	ld	c,a
	ld	a,%00010111		; clear interrupt ctl word
	out	(c),a
	ld	a,%11111111		; clear mask
	out	(c),a
	ld	a,%00000000		; clear interrupt vector
	out	(c),a
;
	ld	a,(iobase)
	add	a,ioctlb
	ld	c,a
	ld	a,%00010111		; clear interrupt ctl word
	out	(c),a
	ld	a,%11111111		; clear mask
	out	(c),a
	ld	a,%00000000		; clear interrupt vector
	out	(c),a
;
	; Deinstall interrupt vectors
	ld	hl,(orgveca)	; original vector
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	e,intveca	; vector idx
	di
	rst	08		; do it
	ei			; interrupts back on
	ld	hl,(orgvecb)	; original vector
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	e,intvecb	; vector idx
	di
	rst	08		; do it
	ei			; interrupts back on
	ret
;
;=======================================================================
; Main Program
;=======================================================================
;
main:
	; Prompt
	call	nl2
	ld	hl,str_pre
	call	pstr
	ld	a,(iobase)
	call	prthexbyte
;
	ld	hl,str_int1
	call	pstr
	ld	hl,(intcnta)
	call	prtdec
	ld	hl,str_int2
	call	pstr
	ld	hl,(intcntb)
	call	prtdec
;
	ld	hl,str_pre2
	call	pstr
;
	; Read command line
	call	rdln
	ld	ix,cmdbuf
;	
main1:
	;;;; Upper case the entire command line
	;;;ld	a,(ix)
	;;;or	a
	;;;jr	z,main2
	;;;call	upcase
	;;;ld	(ix),a
	;;;inc	ix
	;;;jr	main1
;
main2:
	ld	ix,cmdbuf
	call	skipws
	or	a			; check for eol
	call	nz,runcmd		; run command if not eol
	jr	main			; loop
;
; Run the command line pointed to by IX
;
runcmd:
	ld	ix,cmdbuf		; point to cmd line
	call	skipws
	or	a			; check for eol
	ret	z			; return if nothing there
;
	ld	a,(ix)			; get character
;
	; Dispatch
	cp	'?'			; Help
	jp	z,help
	cp	'H'			; Help
	jp	z,help
	cp	'X'			; Exit
	jp	z,exit
	cp	'P'			; PIO Base Port
	jp	z,setport
	cp	'Z'			; Reset Chip
	jp	z,reschip
	cp	'W'			; Watch pins
	jp	z,watch
	cp	'I'			; Input pins on channel
	jp	z,input
	cp	'O'			; Output pins on channel
	jp	z,output
	cp	'S'			; Send strobed byte to channel
	jp	z,send
	cp	'R'			; Read strobed byte from channel
	jp	z,receive
	cp	'T'			; Test
	jp	z,test
	jp	err_invcmd		; Invalid command
;
help:
	ld	hl,str_usage
	call	pstr
	ret
;
setport:
	call	findws			; skip command
	call	skipws			; skip white space
	call	ishex			; do we have a number
	jp	nz,err_invcmd		; handle invalid command
	call	gethex
	jp	c,err_invcmd		; handle overflow error
	push	af
	call	deinit
	pop	af
	ld	(iobase),a		; set new port value
	call	init
	ret				; and done
;
reschip:
	ld	hl,str_reschip1
	call	pstr
	call	reset
	ld	hl,str_reschip2
	call	pstr
	ret
;
watch:
	inc	ix			; skip command byte
	call	getchan			; get channel
	jp	nz,err_invcmd		; handle invalid channel
;
	ld	hl,str_watch1
	call	pstr
	ld	a,(channel)
	add	a,'A'
	call	cout
	ld	hl,str_watch2
	call	pstr
	call	nl2			; formatting
	call	ctlport			; set c to ctl port of channel
	ld	a,%11001111		; bit control mode
	out	(c),a			; do it
	ld	a,%11111111		; set all pins to input
	out	(c),a			; do it
	call	dataport		; set c to data port
	ld	a,0
	ld	b,0
	jr	watch2
watch1:
	call	keychk			; key pressed?
	ret	nz			; return if so
	in	a,(c)			; read data port
	cp	b			; same as before
	jr	z,watch1		; loop
watch2:
	ld	b,a			; save in B
	ld	hl,str_watchtag
	call	pstr
	ld	a,b			; restore value read
	call	prthexbyte		; print new value
	jr	watch1
;
input:
	inc	ix			; skip command byte
	call	getchan			; get channel
	jp	nz,err_invcmd		; handle invalid channel
;
	ld	hl,str_input1
	call	pstr
	ld	a,(channel)
	add	a,'A'
	call	cout
	ld	hl,str_input2
	call	pstr
	call	ctlport			; set c to ctl port of channel
	ld	a,%11001111		; bit control mode
	out	(c),a			; do it
	ld	a,%11111111		; set all pins to input
	out	(c),a			; do it
	call	dataport		; set c to data port
	in	a,(c)
	call	prthexbyte
	ret
;
output:
	inc	ix			; skip command byte
	call	getchan			; get channel
	jp	nz,err_invcmd		; handle invalid channel
;
	call	findws			; skip command
	call	skipws			; skip white space
	call	ishex			; do we have a number
	jp	nz,err_invcmd		; handle invalid command
	call	gethex
	jp	c,err_invcmd		; handle overflow error
	push	af
;
	ld	hl,str_output1
	call	pstr
	ld	a,(channel)
	add	a,'A'
	call	cout
	ld	hl,str_output2
	call	pstr
	call	ctlport			; set c to ctl port of channel
	ld	a,%11001111		; bit control mode
	out	(c),a			; do it
	ld	a,%00000000		; set all pins to output
	out	(c),a			; do it
	call	dataport		; set c to data port
	pop	af
	out	(c),a
	call	prthexbyte
	ret
;
send:
	inc	ix			; skip command byte
	call	getchan			; get channel
	jp	nz,err_invcmd		; handle invalid channel
;
	call	findws			; skip command
	call	skipws			; skip white space
	call	ishex			; do we have a number
	jp	nz,err_invcmd		; handle invalid command
	call	gethex
	jp	c,err_invcmd		; handle overflow error
	push	af
;
	ld	hl,str_send1
	call	pstr
	ld	a,(channel)
	add	a,'A'
	call	cout
	ld	hl,str_send2
	call	pstr
	call	ctlport			; set c to ctl port of channel
	ld	a,%00001111		; strobed output mode
	out	(c),a			; do it
	call	dataport		; set c to data port
	pop	af
	out	(c),a
	call	prthexbyte
	ret
;
receive:
	inc	ix			; skip command byte
	call	getchan			; get channel
	jp	nz,err_invcmd		; handle invalid channel
;
	ld	hl,str_receive1
	call	pstr
	ld	a,(channel)
	add	a,'A'
	call	cout
	ld	hl,str_receive2
	call	pstr
	call	ctlport			; set c to ctl port of channel
	ld	a,%01001111		; strobed input mode
	out	(c),a			; do it
	call	dataport		; set c to data port
	in	a,(c)
	call	prthexbyte
	ret
;
test:
	inc	ix			; skip command byte
	ld	a,(ix)			; get character
;
	; Dispatch
	cp	'R'
	jp	z,test_rdbk		; Readback Test
	cp	'L'
	jp	z,test_lpbk		; Loopback Test
	cp	'S'
	jp	z,test_stlp		; Strobed Loopback Test
	jp	err_invcmd
	ret
;
test_rdbk:
	inc	ix			; skip command byte
	call	getchan			; get channel
	jp	nz,err_invcmd		; handle invalid channel
;
	ld	hl,str_rdbk
	call	pstr
	ld	a,(channel)
	add	a,'A'
	call	cout
	call	nl			; formatting
	call	ctlport			; set c to ctl port of channel
	ld	a,%00001111		; mode 0 (output mode)
	out	(c),a			; do it
	call	dataport		; set c to data port
;
	ld	hl,vallist
	ld	b,vallen
test_rdbk0:
	push	hl
	push	bc
	ld	a,(hl)
	call	test_rdbk1
	pop	bc
	pop	hl
	jp	nz,err_fail
	inc	hl
	djnz	test_rdbk0
	ret
;
test_rdbk1:
	ld	b,a
	call	nl
	ld	a,b
	call	prthexbyte
	out	(c),a
	ld	hl,str_arrow
	call	pstr
	in	a,(c)
	call	prthexbyte
	cp	b
	ret
;
test_lpbk:
	ld	hl,str_lpbkAB
	call	pstr
	ld	a,(iobase)	; Test from A
	add	a,ioctla
	ld	d,a
	ld	a,(iobase)	; ... to B
	add	a,ioctlb
	ld	e,a
	push	de
	call	reset
	call	test_lpbk1	; avoid output on both channels
	pop	de
	jp	nz,err_fail
	ld	hl,str_lpbkBA
	call	pstr
	ld	a,d		; switch direction
	ld	d,e
	ld	e,a
	call	reset		; avoid output on both channels
	call	test_lpbk1
	jp	nz,err_fail
	ret
;
test_lpbk1:
	; Setup output channel
	ld	c,d
	ld	a,%11001111		; bit control mode
	out	(c),a			; do it
	ld	a,%00000000		; set all pins to output
	out	(c),a			; do it
;
	; Setup input channel
	ld	c,e
	ld	a,%11001111		; bit control mode
	out	(c),a			; do it
	ld	a,%11111111		; set all pins to input
	out	(c),a			; do it
;	
	; Loop through test values
	dec	d			; point to data port (output)
	dec	d
	dec	e			; point to data port (input)
	dec	e
	ld	hl,vallist
	ld	b,vallen
;
test_lpbk2:
	call	test_lpbk3
	ret	nz
	inc	hl
	djnz	test_lpbk2
	ret
;
test_lpbk3:
	call	nl
	ld	c,d
	ld	a,(hl)
	call	prthexbyte
	out	(c),a
	push	hl
	ld	hl,str_arrow
	call	pstr
	pop	hl
	ld	c,e
	in	a,(c)
	call	prthexbyte
	cp	(hl)
	ret
;
test_stlp:
	ld	hl,str_stlpAB
	call	pstr
	ld	a,(iobase)	; Test from A
	add	a,ioctla
	ld	d,a
	ld	a,(iobase)	; ... to B
	add	a,ioctlb
	ld	e,a
	push	de
	call	reset
	call	test_stlp1	; avoid output on both channels
	pop	de
	jp	nz,err_fail
	ld	hl,str_stlpBA
	call	pstr
	ld	a,d		; switch direction
	ld	d,e
	ld	e,a
	call	reset		; avoid output on both channels
	call	test_stlp1
	jp	nz,err_fail
	ret
;
test_stlp1:
	; Setup output channel
	ld	c,d
	ld	a,%00001111		; strobed output mode
	out	(c),a			; do it
;
	; Setup input channel
	ld	c,e
	ld	a,%01001111		; strobed input mode
	out	(c),a			; do it
;	
	; Loop through test values
	dec	d			; point to data port (output)
	dec	d
	dec	e			; point to data port (input)
	dec	e
	ld	hl,vallist
	ld	b,vallen
;
test_stlp2:
	call	test_stlp3
	ret	nz
	inc	hl
	djnz	test_stlp2
	ret
;
test_stlp3:
	call	nl
	ld	c,d
	ld	a,(hl)
	call	prthexbyte
	out	(c),a
	push	hl
	ld	hl,str_arrow
	call	pstr
	pop	hl
	ld	c,e
	in	a,(c)
	call	prthexbyte
	cp	(hl)
	ret
;
;
;
getchan:
	ld	a,(ix)			; get byte
	sub	'A'			; convert to binary
	cp	2			; check for max value
	ret	nc			; return with NZ if too high
	ld	(channel),a		; save new value
	cp	a			; set ZF
	ret				; done
;
;
;
reset:
	ld	a,(iobase)
	add	a,ioctla
	ld	c,a
	call	reset1
	ld	a,(iobase)
	add	a,ioctlb
	ld	c,a
	jr	reset1
;
reset1:
	ld	a,%01001111		; set mode 1 (input)
	out	(c),a
	;ld	a,%00010111		; clear interrupt ctl word
	;out	(c),a
	;ld	a,%11111111		; clear mask
	;out	(c),a
	;ld	a,%00000000		; clear interrupt vector
	;out	(c),a
	ret
;
;
;
ctlport:
	ld	a,(iobase)		; base port
	add	a,ioctla		; offset to control ports
	ld	c,a			; put in c
	ld	a,(channel)		; get channel
	add	a,c			; combine
	ld	c,a
	ret
;
;
;
dataport:
	ld	a,(iobase)		; base port
	add	a,iodata		; offset to data ports
	ld	c,a			; put in c
	ld	a,(channel)		; get channel
	add	a,c			; combine
	ld	c,a
	ret
;
; Error Handlers
;
err_abort:
	ld	hl,str_err_abort
	jr	err_ret
err_invcmd:
	ld	hl,str_err_invcmd
	jr	err_ret
err_fail:
	ld	hl,str_err_fail
	jr	err_ret
;
err_ret:
	push	hl
	ld	hl,str_err_prefix
	call	pstr
	pop	hl
	jp	pstr
;
str_err_prefix	.db	bel,"\r\n\r\n*** ",0
str_err_abort	.db	"User Aborted",0
str_err_invcmd	.db	"Invalid command, press '?' for help",0
str_err_fail	.db	"Test failed!",0
;
;=======================================================================
; Utility functions
;=======================================================================
;
; Print string at HL on console, null terminated
;
pstr:
	push	af
	push	hl
pstr1:
	ld	a,(hl)			; get next character
	or	a			; set flags
	inc	hl			; bump pointer regardless
	jr	z,pstr2			; done if null
	call	cout			; display character
	jr	pstr1			; loop till done
pstr2:
	pop	hl
	pop	af
	ret
;
; Print volume label string at HL, '$' terminated, 16 chars max
;
pvol:
	ld	b,16			; init max char downcounter
pvol1:
	ld	a,(hl)			; get next character
	cp	'$'			; set flags
	inc	hl			; bump pointer regardless
	ret	z			; done if null
	call	cout			; display character
	djnz	pvol1			; loop till done
	ret				; hit max of 16 chars
;
; Start a newline on console (cr/lf)
;
nl2:
	call	nl			; double newline
nl:
	ld	a,cr			; cr
	call	cout			; send it
	ld	a,lf			; lf
	jp	cout			; send it and return
;
; Print a dot on console
;
pdot:
	push	af
	ld	a,'.'
	call	cout
	pop	af
	ret
;
;
;
keychk:
	call	cst
	or	a
	ret	z
	call	cin
	or	$FF
	ret
;
; Read a string on the console to cmdbuf
;
; Input is zero terminated
;
rdln:
	ld	de,cmdbuf		; init buffer address ptr
rdln_nxt:
	call	cin			; get a character
	cp	bs			; backspace?
	jr	z,rdln_bs		; handle it if so
	cp	cr			; return?
	jr	z,rdln_cr		; handle it if so
;
	; check for non-printing characters
	cp	' '			; first printable is space char
	jr	c,rdln_bel		; too low, beep and loop
	cp	'~'+1			; last printable char
	jr	nc,rdln_bel		; too high, beep and loop
;
	; need to check for buffer overflow here!!!
	ld	hl,cmdbuf+buflen	; max cmd length
	or	a			; clear carry
	sbc	hl,de			; test for max
	jr	z,rdln_bel		; at max, beep and loop
;
	; good to go, echo and store character
	call	upcase
	call	cout			; echo character input
	ld	(de),a			; save in buffer
	inc	de			; inc buffer ptr
	jr	rdln_nxt		; loop till done
;
rdln_bs:
	ld	hl,cmdbuf		; start of buffer
	or	a			; clear carry
	sbc	hl,de			; subtract from cur buf ptr
	jr	z,rdln_bel		; at buf start, just beep
	ld	hl,str_bs		; backspace sequence
	call	pstr			; send it
	dec	de			; backup buffer pointer
	jr	rdln_nxt		; and loop
;
rdln_bel:
	ld	a,bel			; Bell characters
	call	cout			; send it
	jr	rdln_nxt		; and loop
;
rdln_cr:
	xor	a			; null to A
	ld	(de),a			; store terminator
	ret				; and return
;
; Find next whitespace character at buffer adr in DE, returns with first
; whitespace character in A.
;
findws:
	ld	a,(ix)			; get next char
	or	a			; check for eol
	ret	z			; done if so
	cp	' '			; blank?
	ret	z			; nope, done
	inc	ix			; bump buffer pointer
	jr	findws			; and loop
;
; Skip whitespace at buffer adr in DE, returns with first
; non-whitespace character in A.
;
skipws:
	ld	a,(ix)			; get next char
	or	a			; check for eol
	ret	z			; done if so
	cp	' '			; blank?
	ret	nz			; nope, done
	inc	ix			; bump buffer pointer
	jr	skipws			; and loop
;
; Uppercase character in A
;
upcase:
	cp	'a'			; below 'a'?
	ret	c			; if so, nothing to do
	cp	'z'+1			; above 'z'?
	ret	nc			; if so, nothing to do
	and	~$20			; convert character to lower
	ret				; done
;
; Get numeric chars at IX and convert to number returned in A
; Carry flag set on overflow
;
getnum:
	ld	c,0		; C is working register
getnum1:
	ld	a,(ix)		; get the active char
	cp	'0'		; compare to ascii '0'
	jr	c,getnum2	; abort if below
	cp	'9' + 1		; compare to ascii '9'
	jr	nc,getnum2	; abort if above
;
	; valid digit, add new digit to C
	ld	a,c		; get working value to A
	rlca			; multiply by 10
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	add	a,c		; ...
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
	ld	a,(ix)		; get new digit
	sub	'0'		; make binary
	add	a,c		; add in working value
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
;
	inc	ix		; bump to next char
	jr	getnum1		; loop
;
getnum2:	; return result
	ld	a,c		; return result in A
	or	a		; with flags set, CF is cleared
	ret
;
; Get hex chars at IX and convert to binary number returned in A
; Carry flag set on overflow
;
gethex:
	ld	c,0		; C is working register
gethex1:
	ld	a,(ix)		; get the active char
	call	ishex		; is it a hex char?
	jr	nz,gethex9	; abort if not
;
	; valid digit, add new digit to C
	ld	a,c		; get working value to A
	rlca			; multiply by 16
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
	ld	a,(ix)		; get new hex digit
	call	isnum		; regular number?
	jr	z,gethex2	; if so, handle it, else hex char
	sub	'A'-10		; convert to binary
	jr	gethex3		; and continue
gethex2:
	sub	'0'		; convert to binary
gethex3:
	add	a,c		; add in working value
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
;
	inc	ix		; bump to next char
	jr	gethex1		; loop
;
gethex9:	; return result
	ld	a,c		; return result in A
	or	a		; with flags set, CF is cleared
	ret
;
; Is character in A numberic? NZ if not
;
isnum:
	cp	'0'		; compare to ascii '0'
	jr	c,isnum1	; abort if below
	cp	'9' + 1		; compare to ascii '9'
	jr	nc,isnum1	; abort if above
	cp	a		; set Z
	ret
isnum1:
	cp	'0'		; set NZ w/o changing value
	ret			; and done
;
; Is character in A hex? NZ if not
;
ishex:
	call	isnum		; is it a numeric?
	ret	z		; if so, all done
	cp	'A'		; first hex char
	jr	c,ishex1	; abort if below
	cp	'F' + 1		; last hex char
	jr	nc,ishex1	; abort if above
	cp	a		; set Z
	ret			; done
ishex1:
	cp	'0'		; set NZ w/o changing value
	ret			; done
;
; Delay 16us (cpu speed compensated) incuding call/ret invocation
; Register A and flags destroyed
; No compensation for z180 memory wait states
; There is an overhead of 3ts per invocation
;   Impact of overhead diminishes as cpu speed increases
;
; cpu scaler (cpuscl) = (cpuhmz - 2) for 16us + 3ts delay
;   note: cpuscl must be >= 1!
;
; example: 8mhz cpu (delay goal is 16us)
;   loop = ((6 * 16) - 5) = 91ts
;   total cost = (91 + 40) = 131ts
;   actual delay = (131 / 8) = 16.375us
;
	; --- total cost = (loop cost + 40) ts -----------------+
delay:				; 17ts (from invoking call)	|
	ld	a,(cpuscl)	; 13ts				|
;								|
delay1:				;				|
	; --- loop = ((cpuscl * 16) - 5) ts ------------+	|
	dec	a		; 4ts			|	|
	jr	nz,delay1	; 12ts (nz) / 7ts (z)	|	|
	; ----------------------------------------------+	|
;								|
	ret			; 10ts (return)			|
	;-------------------------------------------------------+
;
; Delay 16us * DE (cpu speed compensated)
; Register DE, A, and flags destroyed
; No compensation for z180 memory wait states
; There is a 27ts overhead for call/ret per invocation
;   Impact of overhead diminishes as DE and/or cpu speed increases
;
; cpu scaler (cpuscl) = (cpuhmz - 2) for 16us outer loop cost
;   note: cpuscl must be > 0!
;
; Example: 8MHz cpu, DE=6250 (delay goal is .1 sec or 100,000us)
;   inner loop = ((16 * 6) - 5) = 91ts
;   outer loop = ((91 + 37) * 6250) = 800,000ts
;   actual delay = ((800,000 + 27) / 8) = 100,003us
;
	; --- total cost = (outer loop + 27) ts ------------------------+
vdelay:				; 17ts (from invoking call)		|
;									|
	; --- outer loop = ((inner loop + 37) * de) ts ---------+	|
	ld	a,(cpuscl)	; 13ts				|	|
;								|	|
vdelay1:			;				|	|
	; --- inner loop = ((cpuscl * 16) - 5) ts ------+	|	|
	dec	a		; 4ts			|	|	|
	jr	nz,vdelay1	; 12ts (nz) / 7ts (z)	|	|	|
	; ----------------------------------------------+	|	|
;								|	|
	dec	de		; 6ts				|	|
	ld	a,d		; 4ts				|	|
	or	e		; 4ts				|	|
	jp	nz,vdelay	; 10ts				|	|
	;-------------------------------------------------------+	|
;									|
	ret			; 10ts (final return)			|
	;---------------------------------------------------------------+
;
; Delay about 0.5 seconds
; 500000us / 16us = 31250
;
ldelay:
	push	af
	push	de
	ld	de,31250
	call	vdelay
	pop	de
	pop	af
	ret
;
#if (cpumhz < 3)
cpuscl	.db	1			; cpu scaler must be > 0
#else
cpuscl	.db	cpumhz - 2		; otherwise 2 less than phi mhz
#endif
;
; Print value of a in decimal with leading zero suppression
;
prtdecb:
	push	hl
	push	af
	ld	l,a
	ld	h,0
	call	prtdec
	pop	af
	pop	hl
	ret
;
; Print value of HL in decimal with leading zero suppression
;
prtdec:
	push	bc
	push	de
	push	hl
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
	call	prtdec1
	pop	hl
	pop	de
	pop	bc
	ret
prtdec1:
	ld	a,'0' - 1
prtdec2:
	inc	a
	add	hl,bc
	jr	c,prtdec2
	sbc	hl,bc
	cp	e
	jr	z,prtdec3
	ld	e,0
	call	cout
prtdec3:
	ret
;
; Short delay functions.  No clock speed compensation, so they
; will run longer on slower systems.  The number indicates the
; number of call/ret invocations.  A single call/ret is
; 27 t-states on a z80, 25 t-states on a z180.
;
;			; z80	z180
;			; ----	----
dly64:	call	dly32	; 1728	1600
dly32:	call	dly16	; 864	800
dly16:	call	dly8	; 432	400
dly8:	call	dly4	; 216	200
dly4:	call	dly2	; 108	100
dly2:	call	dly1	; 54	50
dly1:	ret		; 27	25
;
; Add hl,a
;
;   A register is destroyed!
;
addhla:
	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret
;
;
;
prtdot:
	push	af
	ld	a,'.'
	call	cout
	pop	af
	ret
;
; Print the hex byte value in A
;
prthexbyte:
	push	af
	push	de
	call	hexascii
	ld	a,d
	call	cout
	ld	a,e
	call	cout
	pop	de
	pop	af
	ret
;
; Print the hex word value in BC
;
prthexword:
	push	af
	ld	a,b
	call	prthexbyte
	ld	a,c
	call	prthexbyte
	pop	af
	ret
;
; Print the hex dword value in DE:HL
;
prthex32:
	push	bc
	push	de
	pop	bc
	call	prthexword
	push	hl
	pop	bc
	call	prthexword
	pop	bc
	ret
;
; Convert binary value in A to ASCII hex characters in DE
;
hexascii:
	ld	d,a
	call	hexconv
	ld	e,a
	ld	a,d
	rlca
	rlca
	rlca
	rlca
	call	hexconv
	ld	d,a
	ret
;
; Convert low nibble of A to ASCII hex
;
hexconv:
	and	0Fh	     ; low nibble only
	add	a,90h
	daa
	adc	a,40h
	daa
	ret
;
; Output character from A
;
cout:
	; Save all incoming registers
	push	af
	push	bc
	push	de
	push	hl
;
	; Output character to console via BDOS
	ld	e,a			; output char to E
	ld	c,6			; BDOS direct console I/O
	call	bdos			; output character
;
	; Restore all registers
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
; Input character to A
;
cin:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Input character from console via BDOS
cin1:
	ld	e,$FF			; input request
	ld	c,6			; BDOS direct console I/O
	call	bdos			; input character to A
	or	a			; test for zero (no input)
	jr	z,cin1			; loop till we have a char
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
; Return input status in A (0 = no char, != 0 char waiting)
;
cst:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Get console input status via BDOS
	ld	e,$FE			; status
	ld	c,6			; BDOS direct console I/O
	call	bdos			; input status to A
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
;
;
;=======================================================================
; Constants
;=======================================================================
;
str_banner	.db	"Zilog PIO Monitor v0.1, 14-Mar-2022\r\n"
		.db	"Press ? for help$"
str_bs		.db	bs,' ',bs,0
str_port1	.db	"\r\n\r\nEnter PIO port in hex [",0
str_port2	.db	"]:",0
str_pre		.db	"Zilog PIO @ Port 0x",0
str_pre2	.db	"\r\n\r\n>",0
str_exit	.db	"Done, Thank you for using Zilog PIO Monitor!",0
str_reschip1	.db	"\r\n\r\nFull Reset of PIO Chip... ",0
str_reschip2	.db	"Done",0
str_int1	.db	"\r\nChannel A Interrupts=",0
str_int2	.db	", Channel B Interrupts=",0
str_watch1	.db	"\r\n\r\nWatching Channel ",0
str_watch2	.db	", press any to end...",0
str_watchtag	.db	"\rPort Value=0x",0
str_input1	.db	"\r\n\r\nValue of Pins on Channel ",0
str_input2	.db	" = 0x",0
str_output1	.db	"\r\n\r\nSetting Value of Pins on Channel ",0
str_output2	.db	" = 0x",0
str_receive1	.db	"\r\n\r\nReceived from Channel ",0
str_receive2	.db	" = 0x",0
str_send1	.db	"\r\n\r\nSent to Channel ",0
str_send2	.db	" = 0x",0
str_rdbk	.db	"\r\n\r\nReadback Test on Channel ",0
str_arrow	.db	" --> ",0
str_lpbkAB	.db	"\r\n\r\nLoopback Test in Bit Control Mode A->B...\r\n",0
str_lpbkBA	.db	"\r\n\r\nLoopback Test in Bit Control Mode B->A...\r\n",0
str_stlpAB	.db	"\r\n\r\nLoopback Test in Strobed Mode A->B...\r\n",0
str_stlpBA	.db	"\r\n\r\nLoopback Test in Strobed Mode B->A...\r\n",0
str_usage	.db	"\r\n"
		.db	"\r\n  P n  - Set Current PIO Base Port"
		.db	"\r\n  Z    - Reset PIO (both channels)"
		.db	"\r\n  Wc   - Watch Channel c Pin Values (bit control)"
		.db	"\r\n  Oc n - Output Channel c Pin Values (bit control)"
		.db	"\r\n  Ic   - Input Channel c Pin Values (bit control)"
		.db	"\r\n  Sc n - Send Value to Channel c (strobed)"
		.db	"\r\n  Rc   - Receive Value from Channel c (strobed)"
		.db	"\r\n  TRc  - Test Readback on Channel c (bit control)"
		.db	"\r\n  TL   - Test Loopback (bit control)"
		.db	"\r\n  TS   - Test Loopback (strobed)"
		.db	"\r\n  H,?  - Help"
		.db	"\r\n  X    - Exit"
		.db	"\r\n  "
		.db	"\r\n  Loopback tests require hardware loopback (see readme.txt)"
		.db	0
;
;=======================================================================
; Working data
;=======================================================================
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
iobase		.db	iodef		; current I/O base address
channel		.db	0		; current channel
wrkval		.db	0
;
cmdbuf		.fill	buflen+1,0
;
vallist:
	.db	$00,$FF,$AA,$55,$A5,$5A,$FF,$00
vallen	.equ	$ - vallist
;
orgveca	.dw	0		; saved int vector, channel A
orgvecb	.dw	0		; saved int vector, channel B
;
;===============================================================================
; Interrupt Handler
;===============================================================================
;
reladr	.equ	$		; relocation start adr
;
	.org	$A000		; code will run here
;
inta:
;
	ld	hl,(intcnta)
	inc	hl
	ld	(intcnta),hl
;
	or	$ff		; signal int handled
	ret
;
intb:
;
	ld	hl,(intcntb)
	inc	hl
	ld	(intcntb),hl
;
	or	$ff		; signal int handled
	ret
;
intcnta	.dw	0
intcntb	.dw	0
;
hsiz	.equ	$ - $A000	; size of handler to relocate
;
	.org	reladr + hsiz
;
	.end
	