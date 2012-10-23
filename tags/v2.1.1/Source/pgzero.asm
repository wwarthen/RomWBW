;___PGZERO_____________________________________________________________________________________________________________
;
	.ORG	0000H
;
; NORMAL PAGE ZERO SETUP, RET/RETI/RETN AS APPROPRIATE
;
	.FILL	(000H - $),0FFH		; RST 0
	JP	0100H			; JUMP TO BOOT CODE
	.FILL	(008H - $),0FFH		; RST 8
	RET
	.FILL	(010H - $),0FFH		; RST 10
	RET
	.FILL	(018H - $),0FFH		; RST 18
	RET
	.FILL	(020H - $),0FFH		; RST 20
	RET
	.FILL	(028H - $),0FFH		; RST 28
	RET
	.FILL	(030H - $),0FFH		; RST 30
	RET
	.FILL	(038H - $),0FFH		; INT
	RETI
	.FILL	(066H - $),0FFH		; NMI
	RETN
;
	.FILL	(100H - $),0FFH
;
	.END
