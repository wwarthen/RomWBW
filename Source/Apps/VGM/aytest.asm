;------------------------------------------------------------------------------
; AY-3-8910 Test Program
; Tests both AY chips at A0/A1 and E0/E1 ports
;------------------------------------------------------------------------------

#DEFINE .ORG .org
.ORG	0100H

; CP/M BDOS functions
BDOS	.equ	5
C_READ	.equ	1
C_WRITE	.equ	2
C_RAWIO	.equ	6
C_WRITESTR .equ	9
C_CONBUF .equ	10
C_STAT	.equ	11

; CP/M File BDOS functions
F_OPEN	.equ	15
F_CLOSE	.equ	16
F_READ	.equ	20
F_WRITE	.equ	21
F_MAKE	.equ	22
F_DMA	.equ	26

; AY chip 1 at ports A0/A1
AY1ADDR	.equ	0A0H
AY1DATA	.equ	0A1H

; AY chip 2 at ports 50/51 (COLECO mode on RCBUS)
AY2ADDR	.equ	050H
AY2DATA	.equ	051H

start:

	; Print version and banner
	ld	de,AYTEST_VER
	ld	c,C_WRITESTR
	call	BDOS

	ld	de,msg_banner
	ld	c,C_WRITESTR
	call	BDOS

	; Initialize configuration (defaults, ini file, command line, optional interactive)
	call	init_config

	; Show effective configuration
	call	show_config

main_loop:
	; Test first chip
	ld	de,msg_chip1
	ld	c,C_WRITESTR
	call	BDOS

	ld	hl,(ay1_addr)
	ld	(chip_addr),hl
	ld	hl,(ay1_data)
	ld	(chip_data),hl

	call	test_all_channels

	; Test second chip
	ld	de,msg_chip2
	ld	c,C_WRITESTR
	call	BDOS

	ld	hl,(ay2_addr)
	ld	(chip_addr),hl
	ld	hl,(ay2_data)
	ld	(chip_data),hl

	call	test_all_channels

	; Prompt and repeat until key pressed
	ld	de,msg_prompt
	ld	c,C_WRITESTR
	call	BDOS

	ld	c,C_STAT
	call	BDOS
	or	a
	jr	z,main_loop		; no key, repeat tests

	; key available, consume and exit
	ld	c,C_READ
	call	BDOS

	ld	de,msg_done
	ld	c,C_WRITESTR
	call	BDOS

	ret

;------------------------------------------------------------------------------
; Test all three channels on the currently selected chip
;------------------------------------------------------------------------------

test_all_channels:
	; Channel A
	ld	de,msg_cha
	ld	c,C_WRITESTR
	call	BDOS
	ld	a,0			; Channel A
	call	play_channel

	; Channel B
	ld	de,msg_chb
	ld	c,C_WRITESTR
	call	BDOS
	ld	a,1			; Channel B
	call	play_channel

	; Channel C
	ld	de,msg_chc
	ld	c,C_WRITESTR
	call	BDOS
	ld	a,2			; Channel C
	call	play_channel

	ret

;------------------------------------------------------------------------------
; Configuration initialization
;  - Start with built-in defaults
;  - Try to load aytest.ini
;  - Apply command line overrides (-a1 XX, -a2 YY)
;  - If no ini file existed, offer interactive configuration and write aytest.ini
;------------------------------------------------------------------------------

init_config:
	; start with defaults
	ld	hl,AY1ADDR
	ld	(ay1_addr),hl
	ld	hl,AY1DATA
	ld	(ay1_data),hl
	ld	hl,AY2ADDR
	ld	(ay2_addr),hl
	ld	hl,AY2DATA
	ld	(ay2_data),hl

	xor	a
	ld	(cfg_found),a

	; attempt to load aytest.ini
	call	load_cfg

	; apply command line overrides (do not change cfg_found)
	call	parse_cmdline

	; if config file was found, skip interactive configuration
	ld	a,(cfg_found)
	or	a
	ret	nz

	; Offer interactive configuration and write out aytest.ini
	call	interactive_cfg
	ret

;------------------------------------------------------------------------------
; Load configuration from aytest.ini (if it exists)
;------------------------------------------------------------------------------

load_cfg:
	; ensure cfg_fcb control fields are initialized
	call	init_cfg_fcb
	; open aytest.ini
	ld	de,cfg_fcb
	ld	c,F_OPEN
	call	BDOS
	cp	0FFH
	jr	z,cfg_not_found

	ld	a,1
	ld	(cfg_found),a

	; set DMA and read one record into cfg_buf
	ld	de,cfg_buf
	ld	c,F_DMA
	call	BDOS

	ld	de,cfg_fcb
	ld	c,F_READ
	call	BDOS

	; ensure buffer is terminated
	ld	hl,cfg_buf+127
	ld	(hl),0

	; parse buffer
	call	parse_cfg

	; close file
	ld	de,cfg_fcb
	ld	c,F_CLOSE
	call	BDOS

	ret

cfg_not_found:
	xor	a
	ld	(cfg_found),a
	ret

;------------------------------------------------------------------------------
; Parse aytest.ini buffer in cfg_buf
; Lines expected like:
;   A1=A0
;   A2=50
;------------------------------------------------------------------------------

parse_cfg:
	ld	hl,cfg_buf
cfg_loop:
	ld	a,(hl)
	or	a
	ret	z

	cp	'A'
	jr	nz,cfg_next

	inc	hl
	ld	a,(hl)
	cp	'1'
	jr	z,cfg_a1
	cp	'2'
	jr	z,cfg_a2
	jr	cfg_next

cfg_a1:
	inc	hl			; expect '='
	ld	a,(hl)
	cp	'='
	jr	nz,cfg_next
	inc	hl			; first hex digit
	call	parse_hex_byte
	jr	c,cfg_next
	call	set_ay1_from_A
	jr	cfg_next

cfg_a2:
	inc	hl			; expect '='
	ld	a,(hl)
	cp	'='
	jr	nz,cfg_next
	inc	hl			; first hex digit
	call	parse_hex_byte
	jr	c,cfg_next
	call	set_ay2_from_A
	jr	cfg_next

cfg_next:
	inc	hl
	jr	cfg_loop

;------------------------------------------------------------------------------
; Parse command line for -a1 XX and -a2 YY
;------------------------------------------------------------------------------

parse_cmdline:
	ld	hl,081H		; start of command tail
cmd_loop:
	ld	a,(hl)
	or	a
	ret	z

	cp	'-'
	jr	nz,cmd_next

	inc	hl
	ld	a,(hl)
	and	0DFH			; force upper case
	cp	'A'
	jr	nz,cmd_next

	inc	hl
	ld	a,(hl)
	cp	'1'
	jr	z,cmd_opt_a1
	cp	'2'
	jr	z,cmd_opt_a2
	jr	cmd_next

cmd_opt_a1:
	inc	hl
	call	skip_spaces
	call	parse_hex_byte
	jr	c,cmd_loop
	call	set_ay1_from_A
	jr	cmd_loop

cmd_opt_a2:
	inc	hl
	call	skip_spaces
	call	parse_hex_byte
	jr	c,cmd_loop
	call	set_ay2_from_A
	jr	cmd_loop

cmd_next:
	inc	hl
	jr	cmd_loop

;------------------------------------------------------------------------------
; Skip spaces in command tail (HL points into tail, returns at first non-space)
;------------------------------------------------------------------------------

skip_spaces:
	ld	a,(hl)
	cp	' '
	ret	nz
	inc	hl
	jr	skip_spaces

;------------------------------------------------------------------------------
; Interactive configuration when no aytest.ini exists
;------------------------------------------------------------------------------

interactive_cfg:
	; announce that defaults are in use
	ld	de,msg_nocfg
	ld	c,C_WRITESTR
	call	BDOS

	; configure chip 1
	ld	de,msg_cfg1
	ld	c,C_WRITESTR
	call	BDOS

	ld	hl,(ay1_addr)
	ld	a,l
	call	prthex
	call	crlf

	ld	de,msg_enter
	ld	c,C_WRITESTR
	call	BDOS

	call	prompt_hex
	jr	c,skip_cfg1
	call	set_ay1_from_A
skip_cfg1:

	; configure chip 2
	ld	de,msg_cfg2
	ld	c,C_WRITESTR
	call	BDOS

	ld	hl,(ay2_addr)
	ld	a,l
	call	prthex
	call	crlf

	ld	de,msg_enter
	ld	c,C_WRITESTR
	call	BDOS

	call	prompt_hex
	jr	c,skip_cfg2
	call	set_ay2_from_A
skip_cfg2:

	; write aytest.ini with new values
	call	write_cfg
	ret

;------------------------------------------------------------------------------
; Prompt user for a 2-digit hex value
;  - Returns A=parsed value, CY set on error or blank input
;------------------------------------------------------------------------------

prompt_hex:
	ld	de,inp_buf
	ld	c,C_CONBUF
	call	BDOS

	ld	a,(inp_buf+1)		; number of chars entered
	or	a
	jr	z,prompt_hex_err	; blank, treat as no change

	ld	hl,inp_buf+2
	call	parse_hex_byte
	ret

prompt_hex_err:
	scf
	ret

;------------------------------------------------------------------------------
; Write aytest.ini from current configuration
;------------------------------------------------------------------------------

write_cfg:
	; clear buffer (fill with CP/M EOF 1Ah so editors see a normal text file)
	ld	hl,cfg_buf
	ld	de,cfg_buf+1
	ld	bc,127
	ld	(hl),1AH
	ldir

	; ensure cfg_fcb control fields are initialized before create
	call	init_cfg_fcb

	; first line: A1=XX<CR><LF>
	ld	hl,cfg_buf
	ld	(hl),'A'
	inc	hl
	ld	(hl),'1'
	inc	hl
	ld	(hl),'='
	inc	hl
	ld	a,(ay1_addr)		; low byte of ay1_addr
	call	hexascii
	ld	(hl),d
	inc	hl
	ld	(hl),e
	inc	hl
	ld	(hl),13
	inc	hl
	ld	(hl),10
	inc	hl

	; second line: A2=YY<CR><LF>
	ld	(hl),'A'
	inc	hl
	ld	(hl),'2'
	inc	hl
	ld	(hl),'='
	inc	hl
	ld	a,(ay2_addr)		; low byte of ay2_addr
	call	hexascii
	ld	(hl),d
	inc	hl
	ld	(hl),e
	inc	hl
	ld	(hl),13
	inc	hl
	ld	(hl),10
	inc	hl
	ld	(hl),1AH			; CP/M EOF marker after text

	; debug: show first 16 bytes of cfg_buf
	ld	de,msg_dbg_buf
	ld	c,C_WRITESTR
	call	BDOS
	ld	hl,cfg_buf
	ld	b,16
write_dbg_buf_loop:
	ld	a,(hl)
	call	prthex
	ld	a,' '
	call	prtchr
	inc	hl
	djnz	write_dbg_buf_loop
	call	crlf

	; create aytest.ini
	ld	de,cfg_fcb
	ld	c,F_MAKE
	call	BDOS
	push	af
	ld	de,msg_dbg_make
	ld	c,C_WRITESTR
	call	BDOS
	pop	af
	call	prthex
	call	crlf
	cp	0FFH
	ret	z			; on error, skip write

	; debug: show FCB block list (16 bytes at cfg_fcb+16)
	ld	de,msg_dbg_fcb
	ld	c,C_WRITESTR
	call	BDOS
	ld	hl,cfg_fcb+16
	ld	b,16
write_dbg_fcb_loop:
	ld	a,(hl)
	call	prthex
	ld	a,' '
	call	prtchr
	inc	hl
	djnz	write_dbg_fcb_loop
	call	crlf

	ld	de,cfg_buf
	ld	c,F_DMA
	call	BDOS
	push	af
	ld	de,msg_dbg_dma
	ld	c,C_WRITESTR
	call	BDOS
	pop	af
	call	prthex
	call	crlf

	ld	de,cfg_fcb
	ld	c,F_WRITE
	call	BDOS
	push	af
	ld	de,msg_dbg_write
	ld	c,C_WRITESTR
	call	BDOS
	pop	af
	call	prthex
	call	crlf

	; debug: show FCB block list after write
	ld	de,msg_dbg_fcb2
	ld	c,C_WRITESTR
	call	BDOS
	ld	hl,cfg_fcb+16
	ld	b,16
write_dbg_fcb2_loop:
	ld	a,(hl)
	call	prthex
	ld	(hl),a			; no-op store, just avoid warnings
	ld	a,' '
	call	prtchr
	inc	hl
	djnz	write_dbg_fcb2_loop
	call	crlf

	ld	de,cfg_fcb
	ld	c,F_CLOSE
	call	BDOS
	push	af
	ld	de,msg_dbg_close
	ld	c,C_WRITESTR
	call	BDOS
	pop	af
	call	prthex
	call	crlf

	ret

;------------------------------------------------------------------------------
; Hex helpers
;  - parse_hex_byte: HL-> first of two ASCII hex digits, returns byte in A
;                    HL advanced past the two digits, CY set on error
;  - hexascii: convert byte in A to two ASCII hex chars in D(high) and E(low)
;------------------------------------------------------------------------------

parse_hex_byte:
	push	de
	ld	de,0
	ld	a,(hl)
	call	hex_to_nibble
	jr	c,parse_hex_fail
	add	a,a
	add	a,a
	add	a,a
	add	a,a			; shift left 4
	ld	e,a
	inc	hl
	ld	a,(hl)
	call	hex_to_nibble
	jr	c,parse_hex_fail
	add	a,e
	inc	hl
	pop	de
	or	a			; clear carry
	ret

parse_hex_fail:
	pop	de
	scf
	ret

hex_to_nibble:
	cp	'0'
	jr	c,hex_bad
	cp	'9'+1
	jr	c,hex_dec
	and	0DFH			; force upper
	cp	'A'
	jr	c,hex_bad
	cp	'F'+1
	jr	nc,hex_bad
	sub	'A'-10
	ret
hex_dec:
	sub	'0'
	ret
hex_bad:
	scf
	ret

hexascii:
	ld	d,a
	call	hexconv		; low nibble -> A
	ld	e,a
	ld	a,d
	rlca
	rlca
	rlca
	rlca
	call	hexconv
	ld	d,a
	ret

hexconv:
	and	0FH
	add	a,'0'
	cp	'9'+1
	ret	c
	add	a,7
	ret

;------------------------------------------------------------------------------
; Initialize cfg_fcb control fields (EX/S1/S2/RC and block pointers)
;------------------------------------------------------------------------------

init_cfg_fcb:
	; ensure current user/drive (0)
	ld	hl,cfg_fcb
	ld	(hl),0
	; zero bytes 12..31 of FCB (control area)
	ld	hl,cfg_fcb+12
	ld	de,cfg_fcb+13
	ld	bc,20
	ld	(hl),0
	ldir
	ret

;------------------------------------------------------------------------------
; Helpers to set AY port variables from value in A
;------------------------------------------------------------------------------

set_ay1_from_A:
	ld	l,a
	ld	h,0
	ld	(ay1_addr),hl
	inc	a
	ld	l,a
	ld	h,0
	ld	(ay1_data),hl
	ret

set_ay2_from_A:
	ld	l,a
	ld	h,0
	ld	(ay2_addr),hl
	inc	a
	ld	l,a
	ld	h,0
	ld	(ay2_data),hl
	ret

;------------------------------------------------------------------------------
; Show current effective configuration
;------------------------------------------------------------------------------

show_config:
	ld	de,msg_cfg_current
	ld	c,C_WRITESTR
	call	BDOS

	; Chip 1
	ld	de,msg_chip1_short
	ld	c,C_WRITESTR
	call	BDOS
	ld	hl,(ay1_addr)
	ld	a,l
	call	prthex
	ld	a,'/'
	call	prtchr
	ld	hl,(ay1_data)
	ld	a,l
	call	prthex
	call	crlf

	; Chip 2
	ld	de,msg_chip2_short
	ld	c,C_WRITESTR
	call	BDOS
	ld	hl,(ay2_addr)
	ld	a,l
	call	prthex
	ld	a,'/'
	call	prtchr
	ld	hl,(ay2_data)
	ld	a,l
	call	prthex
	call	crlf

	ret

;------------------------------------------------------------------------------
; Play a tone on one channel (A=0 for A, 1 for B, 2 for C)
;------------------------------------------------------------------------------
play_channel:
	push	af			; Save channel number
	
	; Reset the AY chip
	ld	b,14
reset_loop:
	ld	a,14
	sub	b
	call	ay_write_a
	xor	a
	call	ay_write_data
	djnz	reset_loop

	pop	af			; Restore channel number
	push	af
	
	; Set tone period for the channel
	add	a,a			; Channel * 2 = fine tune register
	push	af
	call	ay_write_a
	ld	a,200			; Tone period fine
	call	ay_write_data
	
	pop	af
	inc	a			; Coarse tune register
	call	ay_write_a
	ld	a,1			; Tone period coarse
	call	ay_write_data

	; Mixer - enable tone on this channel only
	; Mixer bits: 0=ToneA, 1=ToneB, 2=ToneC (0=enable, 1=disable)
	ld	a,7
	call	ay_write_a
	pop	af			; Restore channel number
	push	af
	cp	0
	jr	z,mix_a
	cp	1
	jr	z,mix_b
	; Channel C
	ld	a,00111011B		; Enable C only (bit 2 clear)
	jr	mix_done
mix_a:
	ld	a,00111110B		; Enable A only (bit 0 clear)
	jr	mix_done
mix_b:
	ld	a,00111101B		; Enable B only (bit 1 clear)
mix_done:
	call	ay_write_data
	
	; Set volume for this channel only
	pop	af			; Restore channel number  
	add	a,8			; Volume register
	call	ay_write_a
	ld	a,15			; Max volume
	call	ay_write_data

	; Play for 2 seconds
	ld	bc,0
delay1:
	dec	bc
	ld	a,b
	or	c
	jr	nz,delay1
	ld	bc,0
delay2:
	dec	bc
	ld	a,b
	or	c
	jr	nz,delay2

	; Silence
	ld	a,8
	call	ay_write_a
	xor	a
	call	ay_write_data
	ld	a,9
	call	ay_write_a
	xor	a
	call	ay_write_data
	ld	a,10
	call	ay_write_a
	xor	a
	call	ay_write_data
	
	ret

;------------------------------------------------------------------------------
; Write register number in A to chip
;------------------------------------------------------------------------------
ay_write_a:
	push	bc
	ld	bc,(chip_addr)
	out	(c),a
	pop	bc
	ret

;------------------------------------------------------------------------------
; Write data in A to chip
;------------------------------------------------------------------------------
ay_write_data:
	push	bc
	ld	bc,(chip_data)
	out	(c),a
	pop	bc
	ret

;------------------------------------------------------------------------------
; Simple console helpers
;------------------------------------------------------------------------------

crlf:
	ld	e,13
	ld	c,C_WRITE
	call	BDOS
	ld	e,10
	ld	c,C_WRITE
	call	BDOS
	ret

prtchr:
	push	bc
	push	de
	push	hl
	ld	e,a
	ld	c,C_WRITE
	call	BDOS
	pop	hl
	pop	de
	pop	bc
	ret

prthex:
	push	af
	push	de
	call	hexascii
	ld	a,d
	call	prtchr
	ld	a,e
	call	prtchr
	pop	de
	pop	af
	ret

;------------------------------------------------------------------------------
; Data
;------------------------------------------------------------------------------

AYTEST_VER:
	.db	"AYTEST v0.1.0 - 09 Dec 2025",13,10,"$"

msg_banner:
	.db	"AY-3-8910 Chip Tester",13,10
	.db	"Each channel plays for 2 seconds",13,10,"$"
msg_chip1:
	.db	13,10,"Testing Chip 1",13,10,"$"
msg_chip2:
	.db	13,10,"Testing Chip 2",13,10,"$"
msg_cha:
	.db	"  Channel A...$"
msg_chb:
	.db	13,10,"  Channel B...$"
msg_chc:
	.db	13,10,"  Channel C...$"
msg_done:
	.db	13,10,13,10,"Done!",13,10,"$"
msg_prompt:
	.db	13,10,"Press any key to exit, or wait to repeat.",13,10,"$"
msg_nocfg:
	.db	13,10,"No aytest.ini found - using defaults.",13,10,"$"
msg_cfg1:
	.db	13,10,"Chip 1 base port is currently $"
msg_cfg2:
	.db	13,10,"Chip 2 base port is currently $"
msg_enter:
	.db	"Enter new hex value (00-FF) or press ENTER to keep: $"
msg_cfg_current:
	.db	13,10,"AYTEST configuration:",13,10,"$"
msg_chip1_short:
	.db	"  Chip 1 ports: $"
msg_chip2_short:
	.db	"  Chip 2 ports: $"
msg_dbg_buf:
	.db	13,10,"[DBG] BUF:",13,10,"$"
msg_dbg_make:
	.db	"[DBG] F_MAKE rc= $"
msg_dbg_fcb:
	.db	"[DBG] FCB blocks: $"
msg_dbg_dma:
	.db	"[DBG] F_DMA rc= $"
msg_dbg_write:
	.db	"[DBG] F_WRITE rc= $"
msg_dbg_close:
	.db	"[DBG] F_CLOSE rc= $"
msg_dbg_fcb2:
	.db	"[DBG] FCB blocks (post-write): $"

chip_addr:
	.dw	0
chip_data:
	.dw	0

ay1_addr:
	.dw	0
ay1_data:
	.dw	0
ay2_addr:
	.dw	0
ay2_data:
	.dw	0

cfg_found:
	.db	0

; FCB and buffers for aytest.ini and input

cfg_fcb:
	.db	0
	.db	'A','Y','T','E','S','T',' ',' '
	.db	'I','N','I'
	.ds	20

cfg_buf:
	.ds	128

inp_buf:
	.db	2		; max length for hex input
	.db	0		; actual length
	.ds	2		; data

	.END
