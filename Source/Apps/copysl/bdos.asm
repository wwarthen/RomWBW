;
bdos	.EQU 5
;
; Force BDOS to reset (logout) all drives
;
drvrst:
	ld	c,$0D	; BDOS Reset Disk function
	call	bdos	; do it
	;
	ld	c,$25	; BDOS Reset Multiple Drives
	ld 	de,$FFFF ; all drives
	call 	bdos 	; do it
	;
	xor 	a 	; signal success
	ret
;
