;
;=======================================================================
; I2C Serial ROM Read/Write Utility (SROM)
;=======================================================================
;
; Read or write the contents of a 24LC512 Serial EEPROM via an I2C
; PCF8584 controller.
;
; WBW 2023-09-05: Initial release
; WBW 2023-09-07: Code clean up
;
;=======================================================================
;
; PCF8584 controller port addresses (adjust as needed)
;
pcfbase_sbc	.equ	$F0	; SBC PCF8584 I/O base port address
pcfbase_duo	.equ	$56	; Duodyne PCF8584 I/O base port address
;
; I2C identification (own slave id)
;
pcf_adr		.equ	$55	; Our "own" I2C slave address
;
; 24LC512 ROM id (target device)
;
rom0_adr	.equ	$50	; I2C SROM first I2C address
rom_pgsiz	.equ	128	; SROM page size
;
; General operational equates (should not require adjustment)
;
stksiz		.equ	$40	; Working stack size
;       	                       
restart		.equ	$0000	; CP/M restart vector
bdos		.equ	$0005	; BDOS invocation vector
fcb1		.equ	$005C	; first CP/M parsed FCB
fcb2		.equ	$006C	; second CP/M parsed FCB
;
cr		.equ	13	; carriage return
lf		.equ	10	; line feed
;	                        
ident		.equ	$FFFC	; loc of RomWBW HBIOS ident ptr
;
bf_sysver	.equ	$F1	; BIOS: VER function
bf_sysget	.equ	$F8	; HBIOS: SYSGET function
bf_sysset	.equ	$F9	; HBIOS: SYSGET function
bf_sysgettimer	.equ	$D0	; TIMER subfunction
bf_syssettimer	.equ	$D0	; TIMER subfunction
bf_sysgetsecs	.equ	$D1	; SECONDS subfunction
bf_syssetsecs	.equ	$D1	; SECONDS subfunction
;
; Control register bits
;
pcf_ctl_pin  	.equ  %10000000	; reset				; 0x80
pcf_ctl_eso  	.equ  %01000000	; enable serial output		; 0x40
pcf_ctl_es1  	.equ  %00100000	; register selection bit 1	; 0x20
pcf_ctl_es2  	.equ  %00010000	; register selection bit 2	; 0x10
pcf_ctl_eni  	.equ  %00001000	; enable external interrupt	; 0x08
pcf_ctl_sta  	.equ  %00000100	; generate start		; 0x04
pcf_ctl_sto  	.equ  %00000010	; generate stop			; 0x02
pcf_ctl_ack  	.equ  %00000001	; enable auto acknowledge	; 0x01
;
pcf_op_start	.equ (pcf_ctl_pin | pcf_ctl_eso | pcf_ctl_sta | pcf_ctl_ack)	; 0xC5
pcf_op_stop	.equ (pcf_ctl_pin | pcf_ctl_eso | pcf_ctl_sto | pcf_ctl_ack)	; 0xC3
pcf_op_repstart	.equ (pcf_ctl_eso | pcf_ctl_sta | pcf_ctl_ack)			; 0x45
pcf_op_idle	.equ (pcf_ctl_pin | pcf_ctl_eso | pcf_ctl_ack)			; 0xC1
;
; Status register bits
;
pcf_st_pin  	.equ  %10000000	; pending interrupt not			; 0x80
pcf_st_ini   	.equ  %01000000	; normally 0, 1 if not initialized      ; 0x40
pcf_st_sts   	.equ  %00100000	; stop detected                         ; 0x20
pcf_st_ber   	.equ  %00010000	; bus error detected                    ; 0x10
pcf_st_ad0   	.equ  %00001000	; slave address received = 0x00         ; 0x08
pcf_st_lrb   	.equ  %00001000	; last received bit                     ; 0x08
pcf_st_aas   	.equ  %00000100	; addressed as slave                    ; 0x04
pcf_st_lab   	.equ  %00000010	; lost arbitration                      ; 0x02
pcf_st_bb    	.equ  %00000001	; bus busy not                          ; 0x01
;
; Transmission frequencies
;
pcf_trns_90 	.equ	$00	; 90   KHz
pcf_trns_45 	.equ	$01	; 45   KHz
pcf_trns_11 	.equ	$02	; 11   KHz
pcf_trns_15 	.equ	$03	;  1.5 KHz
;
; Clock chip frequencies
;
pcf_clk_3   	.equ	$00	;  3    MHz
pcf_clk_443 	.equ	$10     ;  4.43 MHz 
pcf_clk_6   	.equ	$14     ;  6    MHz
pcf_clk_8   	.equ	$18     ;  8    MHz
pcf_clk_12  	.equ	$1C     ; 12    MHz
;
; Divisor settings
;
pcf_clk	  	.equ	pcf_clk_12	; $1C
pcf_trns	.equ	pcf_trns_90	; $00
;
; Error codes
;
ec_ok		.equ	0		; No error
ec_bio		.equ	-1		; HBIOS invalid or not present
ec_plt		.equ	-2		; HBIOS platform not supported
ec_usage	.equ	-3		; Command line usage error
ec_init		.equ	-4		; PCF8584 init failed
ec_timeout	.equ	-5		; I2C protocol timeout
ec_nak		.equ	-6		; Unexpected NAK
ec_fopen	.equ	-7		; File open error
ec_fio		.equ	-8		; File I/O error
ec_exists	.equ	-9		; File already exists
ec_verify	.equ	-10		; Data verification mismatch
;
;=======================================================================
;
	.org	$100	; standard CP/M executable
;
;
	; Setup stack (save old value)
	ld	(stksav),sp		; save stack
	ld	sp,stack		; set new stack
;
	; Announce program
	call	crlf
	ld	de,str_banner		; banner
	call	prtstr
;
	call	parse			; parse options
	jr	nz,exit			; abort if problems
;
	call	init			; initialize
	jr	nz,exit			; abort if problems
;
	call	main			; do the real work
;
exit:
	call	prterr
;
	; Announce end of program
	call	crlf2
	ld	de,str_exit
	call	prtstr
;
	; Restore stack and return to OS
	call	crlf			; formatting
	ld	sp,(stksav)		; restore stack
	jp	restart			; return to CP/M via restart
;
;=======================================================================
; Command Line Parsing
;=======================================================================
;
; We take advantage of CP/M OS command line processing which treats
; the first two parameters on the command line as filenames and places
; corresponding FCBs at $5C and $6C.
;
; The first FCB is not actually handled as a file.  Instead, the first
; two characters are used as control parameters.  First character is
; the function to perform (R=read, W=write) and the second character
; is the serial ROM address (0-7) which maps to I2C addresses $50-$57.
;
parse:
	ld	a,(fcb1+1)		; function parm
	cp	'R'			; read?
	jr	z,parse1		; if so, valid, continue
	cp	'W'			; write?
	jr	z,parse1		; if so, valid, continue
	cp	'T'			; write?
	jr	z,parse1		; if so, valid, continue
	cp	'D'			; write?
	jr	z,parse1		; if so, valid, continue
	jp	err_usage		; else, handle usage error
;
parse1:
	ld	(func),a		; save function
	ld	a,(fcb1+2)		; ROM adr parm
	cp	'0'			; start of range
	jp	c,err_usage		; if less, handle usage error
	cp	'7' + 1			; end of range
	jp	nc,err_usage		; if more, handle usage error
	sub	'0'			; convert to binary
	add	a,rom0_adr		; offset to first srom adr
	ld	(romadr),a		; save it
;
	ld	a,(func)		; recall function
	cp	'T'			; test command?
	jr	z,parse_z
;
	ld	a,(fcb2+1)		; first char of page/filename
	cp	' '			; blank?
	jp	z,err_usage		; if so, handle usage error
;
	ld	a,(func)		; recall function
	cp	'D'			; dump command?
	jr	z,parse2		; parse page number
;
	; copy FCB to working location
	ld	hl,fcb2			; parsed CP/M FCB 2
	ld	de,fcb			; our FCB buffer
	ld	bc,16			; only first 16 bytes
	ldir				; copy it
	jr	parse_z
;
parse2:
	; parse page number
	ld	hl,0			; initialize page number
	ld	de,fcb2+1		; pointer to start of page num
parse3:
	ld	a,(de)			; get next char
	inc	de
	cp	' '			; space char?
	jr	z,parse4		; return w/ ZF set
	cp	'0'			; start of range
	jp	c,err_usage		; if less, handle usage error
	cp	'9' + 1			; end of range
	jp	nc,err_usage		; if more, handle usage error
;
	; multiply working page num by 10, then add new digit
	push	hl
	pop	bc
	add	hl,hl
	add	hl,hl
	add	hl,bc
	add	hl,hl
	sub	'0'
	call	addhla
;
	; check for overflow
	ld	a,h
	cp	2
	jp	nc,err_usage
;	
	jr	parse3
;
parse4:
	ld	(page),hl
;
parse_z:
	xor	a
	ret
;
;=======================================================================
; Hardware Initialization
;=======================================================================
;
init:
	call	idbio			; identify hardware BIOS
	cp	1			; is it RomWBW?
	jp	nz,err_bio		; if not, handle error
;
	; Setup I/O ports based on HBIOS platform ID
	ld	a,l			; idbio puts platform id in L
	ld	c,pcfbase_sbc		; assume SBC
	cp	1			; compare to platform id
	jr	z,init1			; if SBC, commit
	ld	c,pcfbase_duo		; assume SBC
	cp	17			; compare to platform id
	jr	z,init1			; if DUO, commit
	jp	err_plt			; unsupported platform error
;
init1:
	; Record and display PCF8584 port addresses
	call	crlf2			; formatting
	ld	de,str_hwmsg1		; first part of h/w message
	call	prtstr			; print it
	ld	a,c			; get base port
	call	prthex			; print port number
	ld	(pcf_dat),a		; save data port
	ld	de,str_hwmsg2		; second part of h/w message
	call	prtstr			; print port number
	inc	a			; bump to data port
	ld	(pcf_ctl),a		; save control port
	call	prthex			; print port number
	ld	de,str_hwmsg3		; third part of h/w message
	call	prtstr			; print it
;
	; Initialize PCF8584
	call	pcf_init		; sets A with result
	ret	nz
;
	; "Reading/Writing/Testing Serial ROM #<n> (I2C address 0xnn)"
	call	crlf2
	ld	a,(func)
	ld	de,str_inforead
	cp	'R'
	call	z,prtstr		; "Reading"
	ld	de,str_infowrite
	cp	'W'
	call	z,prtstr		; "Writing"
	ld	de,str_infotest
	cp	'T'
	call	z,prtstr		; "Testing"
	ld	de,str_infodump
	cp	'D'
	call	z,prtstr		; "Dumping"
	ld	de,str_info1
	call	prtstr			; " Serial ROM #"
	ld	a,(romadr)
	push	af
	sub	rom0_adr
	call	prtdecb			; #
	pop	af
	ld	de,str_info2
	call	prtstr			; " (I2C address "
	call	prthex			; 0x##
	ld	de,str_info3
	call	prtstr			; ")"
;
init2:
	xor	a
	ret
;
;=======================================================================
; Mainline
;=======================================================================
;
main:
	; Get requested function and dispatch
	ld	a,(func)		; get function
	cp	'T'			; SROM test?
	jp	z,test			; if so, do it
	cp	'D'			; SROM dump?
	jp	z,dump			; if so, do it
	cp	'R'			; SROM read
	jp	z,read			; if so, do it
	cp	'W'			; SROM write
	jp	z,write			; if so, do it
	ret				; this should never happen
;
;
;
test:
	call	confirm
	ret	nz
;
	call	fillbufseq
	ld	hl,0
	call	test_write
	ret	nz
	call	fillbufrev
	ld	hl,1
	call	test_write
	ret	nz
	call	fillbufseq
	ld	hl,510
	call	test_write
	ret	nz
	call	fillbufrev
	ld	hl,511
	call	test_write
	ret	nz
;
	ld	hl,0
	call	test_read
	ret	nz
	call	checkseq
	ret	nz
	ld	hl,1
	call	test_read
	ret	nz
	call	checkrev
	ret	nz
	ld	hl,510
	call	test_read
	ret	nz
	call	checkseq
	ret	nz
	ld	hl,511
	call	test_read
	ret	nz
	call	checkrev
	ret	nz
;
	xor	a
	ret
;
;
;
test_read:
	call	crlf2
	ld	de,str_readpage
	call	prtstr
	call	prtdecw
	call	clrbuf
;
	call	readpage
	ret	nz
;
	ld	hl,pagebuf
	ld	c,rom_pgsiz
	call	crlf
	call	dumpbuf
;
	xor	a
	ret
;
;
;
test_write:
	call	crlf2
	ld	de,str_writepage
	call	prtstr
	call	prtdecw
	jp	writepage
;
;
;
dump:
	ld	hl,(page)
	call	crlf2
	ld	de,str_readpage
	call	prtstr
	call	prtdecw
	call	clrbuf
;
	call	readpage
	ret	nz
;	
	ld	hl,pagebuf
	ld	c,rom_pgsiz
	call	crlf
	call	dumpbuf
;
	xor	a
	ret
;
;
;
read:
	; Ensure output file does not exist!
	ld	de,fcb			; FCB pointer
	ld	c,15			; BDOS open file function
	call	bdos			; do it
	cp	$FF			; failed to open?
	jr	z,read0			; if so, good, continue
	call	read_z			; close the file
	jp	err_exists		; handle error
;
read0:	
	; Create output file (must not exist)
	ld	de,fcb			; FCB pointer
	ld	c,22			; BDOS create file function
	call	bdos			; do it
	cp	$FF			; error?
	jp	z,err_fopen		; handle file open error
;
	; SROM read / File write loop
	call	crlf			; formatting
	ld	de,pagebuf		; BDOS DMA is pagebuf
	ld	c,26			; BDOS set DMA function
	call	bdos			; do it
	ld	hl,0			; init SROM page num
;
read1:
	; Read SROM page
	push	hl			; save SROM page num
	call	readpage		; get SROM page
	pop	hl			; restore page num
	jr	nz,read_z		; bail out on error
	inc	hl			; inc page num
;
	; Write page to file
	push	hl			; save SROM page num
	ld	de,fcb			; point to FCB
	ld	c,21			; BDOS write seq function
	call	bdos			; do it
	pop	hl			; restore page num
	or	a			; set flags
	call	nz,err_fio		; handle file I/O error
	jr	nz,read_z		; close file and bail out
;
	; Show progress and loop till done
	call	prtdot			; display progress
	ld	a,h			; check high byte
	cp	2			; done when we hit 512 pages
	jr	nz,read1		; loop till done
	xor	a			; signal success
;
read_z:
	; Close file
	push	af			; preserve status
	ld	de,fcb			; FCB pointer
	ld	c,16			; BDOS close file function
	call	bdos			; do it
	pop	af			; restore status
;
	ret
;
;
;
write:
	; Confirm intent to overwrite SROM
	call	confirm			; confirm SROM overwrite
	ret	nz			; bail out if not confirmed
;
	; Open file
	ld	de,fcb			; FCB pointer
	ld	c,15			; BDOS open file function
	call	bdos			; do it'
	cp	$FF			; error?
	jp	z,err_fopen		; handle file open error
;
	; File read / SROM write loop
	call	crlf			; formatting
	ld	de,pagebuf		; BDOS DMA is pagebuf
	ld	c,26			; BDOS set DMA function
	call	bdos			; do it
	ld	hl,0			; init SROM page num
;
write1:
	; Read page data from file
	push	hl			; save SROM page num
	ld	de,fcb			; FCB pointer
	ld	c,20			; BDOS read file function
	call	bdos			; do it
	pop	hl			; restore SROM page num
	or	a			; set flags
	call	nz,err_fio		; handle file I/O error
	jr	nz,write_z		; close file and bail out
;
	; Write SROM page
	push	hl			; save SROM page num
	call	writepage		; write SROM page
	pop	hl			; restore page num
	jr	nz,read_z		; bail out on error
	inc	hl			; inc page num
;
	; Show progress and loop till done
	call	prtdot			; display progress
	ld	a,h			; check high byte
	cp	2			; done when we hit 512 pages
	jr	nz,write1		; loop till done
	xor	a			; signal success
;
write_z:
	; Close file
	push	af			; preserve status
	ld	de,fcb			; FCB pointer
	ld	c,16			; BDOS close file function
	call	bdos			; do it
	pop	af			; restore status
;
	ret
;
;
;
readpage:
	; Convert page number to byte offset
	add	hl,hl			; * 2
	add	hl,hl			; * 4
	add	hl,hl			; * 8
	add	hl,hl			; * 16
	add	hl,hl			; * 32
	add	hl,hl			; * 64
	add	hl,hl			; * 128
;
	; Read page
	ld	de,pagebuf
	ld	bc,rom_pgsiz
	jp	rom_read
;
;
;
writepage:
	; Convert page number to byte offset
	add	hl,hl			; * 2
	add	hl,hl			; * 4
	add	hl,hl			; * 8
	add	hl,hl			; * 16
	add	hl,hl			; * 32
	add	hl,hl			; * 64
	add	hl,hl			; * 128
;
	; Write page
	ld	de,pagebuf
	ld	bc,rom_pgsiz
	jp	rom_write
;
;
;
clrbuf:
	xor	a
fillbuf:
	push	af
	push	bc
	push	de
	push	hl
	ld	hl,pagebuf
	ld	de,pagebuf + 1
	ld	bc,rom_pgsiz - 1
	ld	(hl),a
	ldir
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
;
;
fillbufseq:
	push	af
	push	bc
	push	de
	push	hl
	xor	a
	ld	b,rom_pgsiz
	ld	hl,pagebuf
fillbufseq1:
	ld	(hl),a
	inc	a
	inc	hl
	djnz	fillbufseq1
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
;
;
fillbufrev:
	push	af
	push	bc
	push	de
	push	hl
	ld	a,rom_pgsiz - 1
	ld	b,rom_pgsiz
	ld	hl,pagebuf
fillbufrev1:
	ld	(hl),a
	dec	a
	inc	hl
	djnz	fillbufrev1
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
;
;
checkseq:
	push	bc
	push	de
	push	hl
	xor	a
	ld	b,rom_pgsiz
	ld	hl,pagebuf
checkseq1:
	cp	(hl)
	call	nz,err_verify
	jr	nz,checkseq_z
	inc	a
	inc	hl
	djnz	checkseq1
	xor	a
checkseq_z:
	pop	hl
	pop	de
	pop	bc
	ret
;
;
;
checkrev:
	push	bc
	push	de
	push	hl
	ld	a,rom_pgsiz - 1
	ld	b,rom_pgsiz
	ld	hl,pagebuf
checkrev1:
	cp	(hl)
	call	nz,err_verify
	jr	nz,checkrev_z
	dec	a
	inc	hl
	djnz	checkrev1
	xor	a
checkrev_z:
	pop	hl
	pop	de
	pop	bc
	ret
;
; Confirm intention to overwrite SROM
;
confirm:
	call	crlf2
	ld	de,str_confirm
	call	prtstr
;
	ld	c,10			; CP/M read line
	ld	de,confirm_buf		; line buffer
	call	bdos			; get line from user
;
	ld	a,(confirm_buf + 1)	; number of chars returned
	or	a			; set flags
	jr	z,confirm1
	ld	a,(confirm_buf + 2)	; get first char entered
	cp	'Y'			; confirmed?
	ret	z			; if so, done, ZF set
	cp	'y'			; lower case variant
	ret	z			; if so, done, ZF set
;
confirm1:
	or	$FF			; signal non-confirm
	ret
;
;=======================================================================
; 24LC512 ROM Routines
;=======================================================================
;
; Write a buffer of data to ROM
; DE=buffer adr
; HL=ROM byte offset
; BC=buffer len
;
rom_write:
	; Move offset to buffer, convert to big endian!!!
	ld	a,h			; high byte
	ld	(adrbuf+0),a		; ... to first buffer pos
	ld	a,l			; low byte
	ld	(adrbuf+1),a		; ... to second buffer pos
;
	; Save count to HL for later
	push	bc			; move count from BC
	pop	hl			; ... to HL
;
	; Generate start condition
	ld	a,(romadr)		; load ROM I2C adress
	rlca				; move to top 7 bits
	res	0,a			; clear low bit for write
	call	pcf_start		; generate start
	jr	nz,rom_write_z		; if error, skip write
;
	; Send ROM address
	push	de			; save buffer pointer
	push	hl			; save buffer length
	ld	hl,2			; 2 byte address
	ld	de,adrbuf		; memory address pointer
	call	pcf_write		; set memory pointer
	pop	hl			; restore buffer length
	pop	de			; restore buffer pointer
	jr	nz,rom_write_z		; if error, skip write
;
	; Write data from buffer
	call	pcf_write		; write the page
;
rom_write_z:
	push	af			; save current status
	call	pcf_stop		; generate stop
	pop	af			; restore status
	ret	nz			; bail out if error status
;
	jr	rom_write_wait		; exit via write wait
;
;
;
rom_write_wait:
	; While SROM is updating page data, it will NAK any
	; start request.  Loop on start requests until an ACK is
	; received or loop timeout.
	ld	b,0			; try 256 times
rom_write_wait1:
	push	bc			; save loop control
	ld	a,(romadr)		; load ROM I2C adress
	rlca				; move to top 7 bits
	res	0,a			; clear low bit for write
	call	pcf_start		; generate start
	jr	nz,rom_write_wait2	; skip ahead
	call	pcf_waitpin		; wait for bus and get status
	;call	prthex
rom_write_wait2:
	push	af			; save current status
	call	pcf_stop		; generate stop
	pop	af			; restore status
	pop	bc			; restore loop control
	cp	$FF			; timeout?
	jp	z,err_timeout		; handle timeout error
	and	pcf_st_lrb		; isolate LRB (ACK bit)
	jr	z,rom_write_wait3	; done
	djnz	rom_write_wait1		; else loop until timeout
	jp	err_timeout		; handle timeout
;
rom_write_wait3:
	;ld	a,b
	;neg
	;call	prthex
	xor	a			; set flags
	ret				; done
;
; Read ROM data into buffer
; DE=buffer adr
; HL=ROM byte offset
; BC=buffer len
;
rom_read:
	; Move offset to buffer, convert to big endian!!!
	ld	a,h			; high byte
	ld	(adrbuf+0),a		; ... to first buffer pos
	ld	a,l			; low byte
	ld	(adrbuf+1),a		; ... to second buffer pos
;
	; Save count to HL for later
	push	bc			; move count from BC
	pop	hl			; ... to HL
;
	; Generate start condition
	ld	a,(romadr)		; load ROM I2C adress
	rlca				; move to top 7 bits
	res	0,a			; clear low bit for write
	call	pcf_start		; generate start
	jr	nz,rom_read_z		; if error, skip write
;
rom_read2:
	; Send ROM address
	push	de			; save buffer pointer
	push	hl			; save buffer length
	ld	hl,2			; 2 byte address
	ld	de,adrbuf		; memory address pointer
	call	pcf_write		; set memory pointer
	pop	hl			; restore buffer length
	pop	de			; restore buffer pointer
	jr	nz,rom_read_z		; if error, bail out
;
	; Repeat start, switch to read
	ld	a,(romadr)		; load ROM I2C address
	rlca				; move to top 7 bits
	set	0,a			; set low bit for read
	call	pcf_repstart		; generate repeat start
	jr	nz,rom_read_z		; if error, bail out
;
	; Read data into buffer
	call	pcf_read		; read the page
;
rom_read_z:
	push	af			; save current status
	call	pcf_stop		; generate stop
	pop	af			; restore status
	or	a			; set flags
	ret				; done
;
;=======================================================================
; PCF8584 Routines
;=======================================================================
;
; General PCF8584 initialization
;
pcf_init:
	; Select S0' (own address) 0x80 -> 0x00
	ld	a,(pcf_ctl)		; ctl port
	ld	c,a			; to C
	ld	a,pcf_ctl_pin  		; PCF reset, select S0'
	out	(c),a			; do it
	nop
	in	a,(c)			; read status
	;call	crlf2
	;call	prtsp
	;call	prthex
	and	$7F	  		; remove pin bit
	jp	nz,err_init		; all should be zero
;
	; Set S0' (own address) 0x55
	dec	c			; data port
	ld	a,pcf_adr		; own address
	out	(c),a			; set own address in S0' (own << 1)
	nop
	in	a,(c)			; read back S0'
	;call	prtsp
	;call	prthex
	cp	pcf_adr			; correct?
	jp	nz,err_init		; if not, init error
;
	; Select S2 (clock) 0xA0 -> 0x20
	inc	c			; ctl port
	ld	a,pcf_ctl_pin | pcf_ctl_es1	; select S2
	out	(c),a			; do it
	nop
	in	a,(c)			; read status
	;call	prtsp
	;call	prthex
	and	07fh			; remove pin bit
	cp	pcf_ctl_es1		; verify S2 selected
	jp	nz,err_init		; it not, init error
;
	; Set S2 (clock) 0x1C
	dec	c			; data port
	ld	a,pcf_trns | pcf_clk	; load clock register s2
	out	(c),a			; do it
	nop
	in	a,(c)			; read back S2
	;call	prtsp
	;call	prthex
	and	$1F	 	  	; only the lower 5 bits are used
	cp	pcf_trns | pcf_clk
	jp	nz,err_init
;
	; Enter idle 0xC1
	inc	c			; ctl port
	ld	a,pcf_op_idle
	out	(c),a  			; do it
	nop
	in	a,(c)			; read status
	;call	prtsp
	;call	prthex
	cp	pcf_st_pin | pcf_st_bb	; expected status
	jp	nz,err_init
;
	xor	a
	ret
;
; Generate an I2C start condition
; A=start byte value (slave address + r/w bit)
;
pcf_start:
	;call	crlf
	;push	de
	;ld	de,str_start
	;call	prtstr
	;pop	de
;
	; Wait for I2C bus clear
	ld	b,a			; move start byte to B
	call	pcf_waitbb		; wait while bus busy
	cp	$FF			; timeout?
	jp	z,err_timeout		; timeout error return
;
	; Set start byte w/ slave address in S0
	ld	a,(pcf_dat)		; data port
	ld	c,a			; ... into C
	;ld	a,b
	;call	prtsp
	;call	prthex
	out	(c),b			; send start byte
;
	; Initiate start operation
	inc	c			; ctl port
	ld	a,pcf_op_start		; command
	out	(c),a			; do it
;
	xor	a			; signal success
	ret				; done
;
; Generate an I2C repeat start condition
; A=start byte value (slave address + r/w bit)
;
pcf_repstart:
	;call	crlf
	;push	de
	;ld	de,str_repstart
	;call	prtstr
	;pop	de
;
	; Send repeat start command
	ld	b,a			; move start byte to B
	ld	a,(pcf_ctl)		; control port
	ld	c,a			; ... into C
	ld	a,pcf_op_repstart	; command
	out	(c),a			; do it
;
	; Set start byte w/ slave address in S0
	ld	a,(pcf_dat)		; data port
	ld	c,a			; ... into C
	;ld	a,b
	;call	prtsp
	;call	prthex
	out	(c),b			; send start byte
;
	xor	a			; signal success
	ret				; done
;
; Generate an I2C stop condition
;
pcf_stop:
	;call	crlf
	;push	de
	;ld	de,str_stop
	;call	prtstr
	;pop	de
;
	ld	a,(pcf_ctl)		; control port
	ld	c,a			; ... into C
	ld	a,pcf_op_stop		; command
	;call	prtsp
	;call	prthex
	out	(c),a			; do it
;
	xor	a			; signal success
	ret				; done
;
; Write bytes to I2C
; HL=byte count to write
; DE=buffer pointer
;
pcf_write:
	;push	af
	;push	bc
	;push	de
	;push	hl
	;push	hl
	;push	de
	;pop	hl
	;call	crlf
	;ld	de,str_write
	;call	prtstr
	;call	prtsp
	;call	prthexword
	;call	prtsp
	;pop	hl
	;call	prthexword
	;call	crlf
	;pop	hl
	;pop	de
	;pop	bc
	;pop	af
;
pcf_write1:
	call	pcf_waitack		; wait for ack
	ret	nz			; abort on failure
;
	ld	a,h			; check for
	or	l			; ... counter exhausted
	ret	z			; if so, done, exit w/ ZF set
;
	ld	a,(pcf_dat)		; data port
	ld	c,a			; ... into C
	ld	a,(de)			; get byte to write
	;call	prtsp
	;call	prthex
	out	(c),a			; send it
;
	dec	hl			; decrement byte counter
	inc	de			; bump buf ptr
	jr	pcf_write1		; loop till done
;
; Read bytes from I2C
; HL=byte count to read
;
pcf_read:
	;push	af
	;push	bc
	;push	de
	;push	hl
	;call	crlf
	;ld	de,str_read
	;call	prtstr
	;call	prtsp
	;call	prthexword
	;call	crlf
	;pop	hl
	;pop	de
	;pop	bc
	;pop	af
;
	; First byte is a "dummy", must be discarded
	call	pcf_waitack		; wait for ack
	ret	nz			; abort on failure
	ld	a,(pcf_dat)		; data port
	ld	c,a			; ... into C
	in	a,(c)			; get dummy byte
;
pcf_read0:
	call	pcf_waitack		; wait for ack
	ret	nz			; abort on failure
;
	; Loop control
	dec	hl			; pre-decrement byte counter
	ld	a,h			; check for
	or	l			; ... counter exhausted - 1
	jr	z,pcf_read2		; handle end game
;
pcf_read1:
	; Get next data byte
	ld	a,(pcf_dat)		; data port
	ld	c,a			; ... into C
	in	a,(c)			; get next byte of ROM
	;call	prtsp
	;call	prthex
	ld	(de),a			; save byte received in buf
	inc	de			; bump buf pointer
;
	jr	pcf_read0		; loop till done
;
pcf_read2:
	; Special treatment for final character
	ld	a,(pcf_ctl)		; control port
	ld	c,a			; ... into C
	ld	a,$40			; prep for neg ack
	out	(c),a			; send it
;
	; Get final data byte
	ld	a,(pcf_dat)		; data port
	ld	c,a			; ... into C
	in	a,(c)			; get next byte of ROM
	;call	prtsp
	;call	prtdot
	;call	prthex
	ld	(de),a			; save byte received in buf
;
	call	pcf_waitpin		; wait for PIN
	cp	$FF			; timeout?
	jp	z,err_timeout		; handle it
;
	xor	a			; signal success
	ret				; done
;
; Wait for I2C bus to not be busy (BB = 1)
; Return PCF status in A, 0xFF for timeout
;
pcf_waitbb:
	push	bc			; save BC
	ld	a,(pcf_ctl)		; control port value
	ld	c,a			; ... into C
	ld	b,0			; timeout counter
;
pcf_waitbb1:
	in	a,(c)			; get status byte
	bit	0,a			; test busy bit (inverted)
	jr	nz,pcf_waitbb_z		; if BB=1, bus clear, return
	djnz	pcf_waitbb1		; loop to keep trying
	or	$FF			; signal timeout
;
pcf_waitbb_z:
	pop	bc			; restore BC
	ret				; done
;
; Wait for PIN (PIN = 0)
; Return PCF status in A, 0xFF for timeout
;
pcf_waitpin:
	push	bc			; save BC
	ld	a,(pcf_ctl)		; control port value
	ld	c,a			; ... into C
	ld	b,0			; timeout counter
;
pcf_waitpin1:
	; Wait till done with send/receive (PIN=0)
	in	a,(c)			; get status byte
	bit	7,a			; test PIN bit
	jr	z,pcf_waitpin_z		; if 0, done
	djnz	pcf_waitpin1		; loop till timeout
	or	$FF			; signal timeout
;
pcf_waitpin_z:
	pop	bc			; restore BC
	ret				; done
;
; Wait for slave (PIN = 0) and check for acknowledge (LRB = 0)
; Return error code
;
pcf_waitack:
	call	pcf_waitpin		; wait for PIN
	cp	$FF			; timeout?
	jp	z,err_timeout		; handle it
	; Evaluate response
	and	pcf_st_lrb		; isolate LRB bit
	jp	nz,err_nak		; handle NAK error
	xor	a			; set status
	ret
;
; Error Handlers
;
err_bio:
	ld	a,ec_bio
	jr	err_ret
;
err_plt:
	ld	a,ec_plt
	jr	err_ret
;
err_usage:
	ld	a,ec_usage
	jr	err_ret
;
err_init:
	ld	a,ec_init
	jr	err_ret
;
err_timeout:
	ld	a,ec_timeout
	jr	err_ret
;
err_nak:
	ld	a,ec_nak
	jr	err_ret
;
err_fopen:
	ld	a,ec_fopen
	jr	err_ret
;
err_fio:
	ld	a,ec_fio
	jr	err_ret
;
err_exists:
	ld	a,ec_exists
	jr	err_ret
;
err_verify:
	ld	a,ec_verify
	jr	err_ret
;
err_ret:
	or	a			; set flags
	ret
;
;
;
prterr:
	push	de
	push	hl
	neg
	rlca
	ld	hl,str_err_table
	call	addhla
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	call	crlf2
	call	prtstr
	pop	hl
	pop	de
	ret
;
;=======================================================================
; Utility Routines
;=======================================================================
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
	ld	hl,($FFFE)	; HL := HBIOS ident location
	ld	a,'W'		; First byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
	inc	hl		; Next byte of ident
	ld	a,~'W'		; Second byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
;
	ld	b,bf_sysver	; HBIOS: VER function
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
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	pop	af
	ret
;
prtsp3:
	call	prtsp
prtsp2:
	call	prtsp
prtsp:
;
	; shortcut to print a space character preserving all regs
	push	af		; save af
	ld	a,' '		; load dot char
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
prtdot:
;
	; shortcut to print a dot character preserving all regs
	push	af		; save af
	ld	a,'.'		; load dot char
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
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
; Print a zero terminated string at (de) without destroying any registers
;
prtstr:
	push	af
	push	de
;
prtstr1:
	ld	a,(de)		; get next char
	or	a
	jr	z,prtstr2
	call	prtchr
	inc	de
	jr	prtstr1
;
prtstr2:
	pop	de		; restore registers
	pop	af
	ret
;
; Print a hex value prefix "0x"
;
prthexpre:
	push	af
	ld	a,'0'
	call	prtchr
	ld	a,'x'
	call	prtchr
	pop	af
	ret
;
; Print the value in A in hex without destroying any registers
;
prthex:
	call	prthexpre
prthex1:
	push	af		; save AF
	push	de		; save DE
	call	hexascii	; convert value in A to hex chars in DE
	ld	a,d		; get the high order hex char
	call	prtchr		; print it
	ld	a,e		; get the low order hex char
	call	prtchr		; print it
	pop	de		; restore DE
	pop	af		; restore AF
	ret			; done
;
; print the hex word value in hl
;
prthexword:
	call	prthexpre
prthexword1:
	push	af
	ld	a,h
	call	prthex1
	ld	a,l
	call	prthex1 
	pop	af
	ret
;
; print the hex dword value in de:hl
;
prthex32:
	call	prthexpre
	push	bc
	push	de
	pop	bc
	call	prthexword1
	push	hl
	pop	bc
	call	prthexword1
	pop	bc
	ret
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
; Dump a buffer in hex and ascii
;
; HL=buffer address
; C=buffer length, 0 for 256 bytes
; Uses AF, BC, DE, HL
;

dumpbuf:
	ld	de,0			; init buffer offset
dumpbuf1:
	call	dumpline
	ld	a,d
	inc	a
	ret	z
	jr	dumpbuf1
;	
dumpline:
	; HL=buf ptr, DE=buf offset, C=bytes left to print
	call	crlf			; start line
	ex	de,hl			; offset in HL
	call	prthexword1		; print in hex
	ld	a,16			; increment
	call	addhla			; ... for next time
	ex	de,hl			; restore DE/HL
	ld	a,':'
	call	prtchr
;
	; hex byte loop, C=bytes to print
	ld	b,16			; bytes per row
	push	bc
	push	hl
dumpline1:
	ld	a,b
	cp	8
	jr	nz,dumpline2
	call	prtsp
	ld	a,'-'
	call	prtchr
;
dumpline2:
	call	prtsp
	ld	a,d
	inc	a
	jr	z,dumpline3
	ld	a,(hl)			; get byte
	inc	hl			; bump position
	call	prthex1			; print it
	dec	c
	jr	nz,dumpline4
	ld	d,$FF			; flag end of buf
	jr	dumpline4
dumpline3:
	call	prtsp
	call	prtsp
dumpline4:
	djnz	dumpline1
;
	call	prtsp
	call	prtsp
	ld	a,'|'
	call	prtchr
;
	; ascii byte loop, C=bytes to print
	pop	hl
	pop	bc
dumpline5:
	ld	a,(hl)			; get real byte
	inc	hl
	call	dumpchar
	dec	c
	jr	z,dumpline6		; if done, just exit loop
	djnz	dumpline5
dumpline6:
	ld	a,'|'
	call	prtchr
	ret
;
dumpchar:
	; Print character.  Replace non-printable with '.'
	cp	' '
	jr	c,dumpchar1		; first printable char is ' '
	cp	'~' + 1
	jr	nc,dumpchar1		; last printable char is '~'
	jp	prtchr			; print and return
dumpchar1:
	ld	a,'.'			; replace with '.'
	jp	prtchr			; print and return
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
delay:
	push	af
	push	hl
	ld	hl,0
delay1:
	ld	a,h
	or	l
	jr	nz,delay1
	pop	hl
	pop	af
	ret
;
;=======================================================================
; String Data
;=======================================================================
;
str_banner		.db	"I2C Serial ROM Utility v0.1, 26-Aug-2023",0
str_hwmsg1		.db	"PCF8584 Data port=",0
str_hwmsg2		.db	", Control/Status port=",0
str_hwmsg3		.db	"",0
str_inforead		.db	"Reading",0
str_infowrite		.db	"Writing",0
str_infotest		.db	"Testing",0
str_infodump		.db	"Dumping",0
str_infodump2		.db	", Page #",0
str_info1		.db	" Serial ROM #",0
str_info2		.db	" (I2C address ",0
str_info3		.db	")",0
str_exit		.db	"Done, Thank you for using I2C Serial ROM Utility!",0
str_confirm		.db	"Serial ROM will be overwritten, continue (y/N)?",0
str_err_ok		.db	"Successful completion",0
str_err_bio		.db	"RomWBW BIOS required, but not present!",0
str_err_plt		.db	"Hardware platform not currently supported!",0
str_err_usage		.db	"Usage:", cr, lf
			.db	"  SROM Tn          Test SROM", cr, lf
			.db	"  SROM Dn <page>   Dump SROM n <page> (0-511)", cr, lf
			.db	"  SROM Rn <file>   Read SROM n into <file>", cr, lf
			.db	"  SROM Wn <file>   Write SROM n from <file>", cr, lf
			.db	"", cr, lf
			.db	"  n=SROM Id (0-7)", 0
str_err_init		.db	"PCF8584 failed during initialization!",0
str_err_timeout		.db	"I2C protocol timeout!",0
str_err_nak		.db	"Slave negative acknowledge!",0
str_err_fopen		.db	"Failed to open specified file!",0
str_err_fio		.db	"File input/output error!",0
str_err_exists		.db	"Output file already exists!",0
str_err_verify		.db	"Data mismatch during verification!",0
str_start		.db	"I2C Start...",0
str_repstart		.db	"I2C Repeat Start...",0
str_stop		.db	"I2C Stop...",0
str_read		.db	"I2C Read...",0
str_write		.db	"I2C Write...",0
str_readpage		.db	"Reading ROM page ",0
str_writepage		.db	"Writing ROM page ",0
str_writepage2		.db	" with Data=",0
;
str_err_table:
	.dw	str_err_ok
	.dw	str_err_bio
	.dw	str_err_plt
	.dw	str_err_usage
	.dw	str_err_init
	.dw	str_err_timeout
	.dw	str_err_nak
	.dw	str_err_fopen
	.dw	str_err_fio
	.dw	str_err_exists
	.dw	str_err_verify
;
;=======================================================================
; Working Data
;=======================================================================
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
pcf_dat		.db	0		; PCF8584 data port
pcf_ctl		.db	0		; PCF8584 control/status port
;
func		.db	0		; Function requested: T/D/R/W
romadr		.db	0		; ROM device I2C address
page		.dw	0		; Page requested for dump
;
confirm_buf	.db	3		; 3 bytes in buffer
		.db	0		; bytes filled by BDOS
		.fill	3,0		; actual character buffer
;
fcb		.fill	36,0		; FCB
;
adrbuf		.fill	2,0		; ROM address buffer (big endian!!!)
pagebuf		.fill	rom_pgsiz,$55	; ROM page buffer
;
;=======================================================================
;
	.end
