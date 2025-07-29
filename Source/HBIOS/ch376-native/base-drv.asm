
DELAY_FACTOR		.EQU	640

CMD01_RD_USB_DATA0	.EQU	$27	; Read data block from current USB interrupt endpoint buffer or host endpoint receive buffer
					; output: length, data stream

CMD10_WR_HOST_DATA	.EQU	$2C 	; Write a data block to the send buffer of the USB host endpoint
					; input: length, data stream

CH_CMD_RD_USB_DATA0	.EQU	CMD01_RD_USB_DATA0
CH_CMD_WR_HOST_DATA	.EQU	CMD10_WR_HOST_DATA

; HL -> timeout
; returns
; L -> error code

; ---------------------------------
; Function ch_wait_int_and_get_status
; ---------------------------------
_ch_wait_and_get_status
	ld	bc, DELAY_FACTOR

keep_waiting:
	ld	a, $FF
	in	a, (_CH376_COMMAND_PORT & $FF)
	rlca
	jp	nc, _ch_get_status

	dec	bc
	ld	a, b
	or	c
	jr	nz, keep_waiting

	dec	hl
	ld	a, h
	or	l
	jr	nz, _ch_wait_and_get_status

	call	_delay
	ld	a, $FF
	in	a, (_CH376_COMMAND_PORT & $FF)
	bit	4, a			; _CH376_COMMAND_PORT & PARA_STATE_BUSY

	ld	l, $0C 			; USB_ERR_CH376_BLOCKED;
	ret	nz

	ld	l, $0D 			; USB_ERR_CH376_TIMEOUT
	ret

; uint8_t ch_read_data(uint8_t *buffer) __sdcccall(1);
_ch_read_data:
	push	hl
	ld	l, CH_CMD_RD_USB_DATA0
	call	_ch_command
	pop	hl

	call	_delay
	ld	bc, _CH376_DATA_PORT
	in	a, (c)

	or	a
	ret	z

	ld	e, a
	push	af
read_block:
	call	_delay
	in	a, (c)
	ld	(hl), a
	inc	hl
	dec	e
	jr	nz, read_block

	pop	af
	ret

;const uint8_t *ch_write_data(const uint8_t *buffer, uint8_t length)
_ch_write_data:
	ld	l, CH_CMD_WR_HOST_DATA
	call	_ch_command

	ld	iy, 2
	add	iy, sp
	ld	l, (iy+0)
	ld	h, (iy+1)
	ld	a, (iy+2)

	ld	bc, _CH376_DATA_PORT

; _CH376_DATA_PORT = length;
	call	_delay
	out	(c), a

	or	a
	ret	z

	ld	d, a
write_block:
	call	_delay
	ld	a, (hl)
	out	(c), a
	inc	hl
	dec	d
	jr	nz, write_block

	ret
