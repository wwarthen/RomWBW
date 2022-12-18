;------------------------------------------------------------------------------
; YM2612 sound driver
;	Written by: Phil Summers (b1ackmailer) difficultylevelhigh@gmail.com
;
;------------------------------------------------------------------------------
; References:
;	https://www.smspower.org/maxim/Documents/YM2612
;	https://plutiedev.com/blog/20200103
;	https://www.plutiedev.com/ym2612-registers
;	https://en.wikipedia.org/wiki/Scientific_pitch_notation
;------------------------------------------------------------------------------
; Octave range is A#0-B7+3/4 HBIOS note 0..343
;------------------------------------------------------------------------------
;
YMSEL		.EQU	VGMBASE+00H		; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.EQU	VGMBASE+01H		; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.EQU	VGMBASE+02H		; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.EQU	VGMBASE+03H		; Secondary YM2162 11000011 a1=1 a0=1

;------------------------------------------------------------------------------
; Device capabilities and configuration
;------------------------------------------------------------------------------
;
YM_TONECNT	.EQU	6			; Count number of tone channels
YM_NOISECNT	.EQU	0			; Count number of noise channels
;
YM_PENDING_PERIOD	.DW	0	; PENDING PERIOD (12 BITS)	; ORDER
YM_PENDING_VOLUME	.DB	0	; PENDING VOL (8 BITS)		; SIGNIFICANT
YM_PENDING_DURATION	.DW	0	; PENDING DURATION (16 BITS)
YM_READY		.DB	0	; BIT 0 -> NZ DRIVER IS READY TO RECEIVE PLAY COMMAND
					; BIT 1 -> NZ EXECUTING WITHIN TIMER HANDLER = DO NOT DIS/ENABLE INT
YM_RDY_RST		.DB	0	; FLAG INDICATES IF DEVICE IS IN READY (NZ) OR RESET STATE (Z)
;
;------------------------------------------------------------------------------
; Driver function table and instance data
;------------------------------------------------------------------------------
;
YM_FNTBL:	.DW	YM_RESET
		.DW	YM_VOLUME
		.DW	YM_PERIOD
		.DW	YM_NOTE
		.DW	YM_PLAY
		.DW	YM_QUERY
		.DW	YM_DURATION
		.DW	YM_DEVICE
;
#IF (($ - YM_FNTBL) != (SND_FNCNT * 2))
	.ECHO	"*** INVALID SND FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
YM_IDAT	.EQU	0				; NO INSTANCE DATA FOR THIS DEVICE
;
;------------------------------------------------------------------------------
; YM2162 Initialization
;	Announce device on console. 
;	Setup function tables. Setup the device.
;	Set volume off.
;	Return initialization status
;------------------------------------------------------------------------------
;
YM2612_INIT:	CALL	NEWLINE			; ANNOUNCE
		PRTS("YM:$")
;
		PRTS(" IO=0x$")
		LD	A,YMSEL
		CALL	PRTHEXBYTE
;
		LD	IY, YM_IDAT		; SETUP FUNCTION TABLE
		LD	BC, YM_FNTBL		; POINTER TO INSTANCE DATA
		LD	DE, YM_IDAT		; BC := FUNCTION TABLE ADDRESS
		CALL	SND_ADDENT		; DE := INSTANCE DATA PTR
;
YM_INIT:	ld	hl,ym_cfg
;		call	ym_prog
;		ret
;
;------------------------------------------------------------------------------
; Program ym2612 with a list of register entries
;------------------------------------------------------------------------------
;
ym_prog:	ld	c,(hl)			; get port address
		inc	hl
		ld	d,(hl)			; count of pairs
		inc	hl
;
t_loop:		ld	a,(hl)			; get register to write
		out	(c),a
;	call PRTHEXBYTE
		inc	hl
		inc	c
		ld	a,(hl)			; get value to write
		out	(c),a
;	call PRTHEXBYTE
		ld	b,0			; check device 
nready1:	in	a,(c)           	; ready with timeout
		rlca                    	; 
		jr	nc,ready1       	; bits 7 = busy
		djnz	nready1
;
;		timed out
;
ready1:		inc	hl 
		dec	c 
		dec	d
		jr	nz,t_loop
;
		ld	a,(hl)			; end flag?
		or	a
		jr	nz,ym_prog		; no? restart
		ret
;
;------------------------------------------------------------------------------
; Sound driver function - QUERY and subfunctions
;------------------------------------------------------------------------------
;
YM_QUERY:	LD	A, E
		CP	BF_SNDQ_CHCNT		; SUB FUNCTION 01
		JR	Z, YM_QUERY_CHCNT
;
		CP	BF_SNDQ_VOLUME		; SUB FUNCTION 02
		JR	Z, YM_QUERY_VOLUME
;
		CP	BF_SNDQ_PERIOD		; SUB FUNCTION 03
		JR	Z, YM_QUERY_PERIOD
;
		CP	BF_SNDQ_DEV		; SUB FUNCTION 04
		JR	Z, YM_QUERY_DEV
;
		OR	$FF			; SIGNAL FAILURE
		RET
;
YM_QUERY_CHCNT:	LD	BC,(YM_TONECNT*256)+YM_NOISECNT	
		XOR	A			; RETURN NUMBER OF TONE AND NOISE
		RET				; NOISE CHANNELS IN BC
;
YM_QUERY_PERIOD:LD	HL, (YM_PENDING_PERIOD)	; RETURN 16-BIT PERIOD
		XOR	A			; IN HL REGISTER
		RET
;
YM_QUERY_VOLUME:LD	A, (YM_PENDING_VOLUME)	; RETURN 8-BIT VOLUME
		LD	L, A			; IN L REGISTER
		XOR	A
;		LD	H, A
		RET
;
YM_QUERY_DEV:	LD	B, SNDDEV_YM2612	; RETURN DEVICE IDENTIFIER
		LD	DE, +(YMSEL*256)+YMDAT	; AND ADDRESS AND DATA PORT
		LD	HL, +(YM2SEL*256)+YM2DAT	
		XOR	A
		RET
;
;------------------------------------------------------------------------------
; Sound driver function - DEVICE
;------------------------------------------------------------------------------
;
YM_DEVICE:	LD	D,SNDDEV_YM2612		; D := DEVICE TYPE
		LD	E,0			; E := PHYSICAL UNIT
		LD	C,$00			; C := DEVICE TYPE
		LD	H,0			; H := MODE
		LD	L,YMSEL			; L := BASE I/O ADDRESS
		XOR	A
		RET
;
;------------------------------------------------------------------------------
; Sound driver function - RESET
; Initialize device. Set volume off. Reset volume and tone variables.
;------------------------------------------------------------------------------
;
YM_RESET:	;CALL	AY_CHKREDY		; RETURNS TO OUR CALLER IF NOT READY
;
		PUSH	DE
		PUSH	HL
		CALL	YM_INIT			; SET DEFAULT CHIP CONFIGURATION
;
		XOR	A			; SIGNAL SUCCESS
		LD	(YM_RDY_RST),A		; IN RESET STATE
		LD	(YM_PENDING_VOLUME),A	; SET VOLUME TO ZERO
		LD	H,A
		LD	L,A
		LD	(YM_PENDING_PERIOD),HL	; SET TONE PERIOD TO ZERO
;
		POP	HL
		POP	DE
		RET
;
;------------------------------------------------------------------------------
; Sound driver function - VOLUME
;------------------------------------------------------------------------------
;
YM_VOLUME:	LD	A,L			; SAVE VOLUME
		LD	(YM_PENDING_VOLUME),A
		XOR	A			; SIGNAL SUCCESS
		RET
;
;------------------------------------------------------------------------------
; Sound driver function - NOTE 
;------------------------------------------------------------------------------
;
YM_NOTE:	;CALL	PRTHEXWORDHL
		;CALL	PC_COLON

		LD	DE,40			; Calculate the ym2612 block (octave)
		ADD	HL,DE			; This will go into b13-b11
		LD	DE,48			; HL / DE
		CALL	DIV16			; BC = block (octave) HL = quarter semitone note
;				
		ADD	HL,HL
		LD	DE,ym_notetable		; point HL to frequency entry
		ADD	HL,DE			; for the quarter semitone note

		;CALL	PRTHEXWORDHL
		;CALL	PC_COLON
		;CALL	PRTHEXWORD
		;CALL	PC_COLON
;		
		LD	A,C			; SHIFT OCTAVE INTO RIGHT POSITION
		ADD	A,A			; X2
		ADD	A,A			; X4
		ADD	A,A			; X8 -NEEDS TO BE OR'ED WITH HIGH BYTE
;
		LD	E,(HL)			; COMBINE FREQUENCY ENTRY
		INC	HL			; AND BLOCK (OCTAVE) IN HL
		OR	(HL)
		LD	H,A
		LD	L,E

		;CALL	PRTHEXWORDHL
;
;------------------------------------------------------------------------------
; Sound driver function - PERIOD
;	The format for setting frequency on the ym2612 is 00xxxyyy-yyyyyyyy
;	Where xxx us the octave and yyy-yyyyyyyy is the frequency
;------------------------------------------------------------------------------
;
YM_PERIOD:	LD	A, H			; IF ZERO - ERROR
		OR	L
		JR	Z, YM_PERIOD1
;
		LD	A, H			; MAXIMUM TONE PERIOD IS 11-BITS
		AND	11000000B		; ALLOWED RANGE IS 0001-07FF (2047)
		JR	NZ, YM_PERIOD1		; AND 3 BITS FOR OCTAVE (7)
		LD	(AY_PENDING_PERIOD), HL	; RETURN NZ IF NUMBER TOO LARGE
		RET				; SAVE AND RETURN SUCCESSFUL
;
YM_PERIOD1:	LD	A, $FF			; REQUESTED PERIOD IS LARGER
		LD	(AY_PENDING_PERIOD), A	; THAN THE DEVICE CAN SUPPORT
		LD	(AY_PENDING_PERIOD+1), A; SO SET PERIOD TO FFFF
		RET				; AND RETURN FAILURE
;
;------------------------------------------------------------------------------
;	SOUND DRIVER FUNCTION - DURATION
;------------------------------------------------------------------------------
;
YM_DURATION:	LD	(YM_PENDING_DURATION),HL	; SET TONE DURATION
		XOR	A
		RET
;
;------------------------------------------------------------------------------
; Sound driver function - PLAY
;	D = CHANNEL
;------------------------------------------------------------------------------
;
YM_PLAY:	LD	A,(YM_RDY_RST)		; IF STILL IN RESET
		OR	A			; STATE GO SETUP FOR
		CALL	Z,YM_MAKE_RDY		; PLAYING
;
		ld	hl,(AY_PENDING_PERIOD)	; GET THE PREVIOUSLY SETUP
		ld 	de,ym_playnote+5	; TONE DATA AND
		ld	a,h
		ld	(de),a			; PATCH IT INTO THE
		inc	de			; YM2612 PLAY COMMAND
		inc	de
		ld	a,l
		ld	(de),a
;
		ld	hl,ym_playnote		; NOW PLAY IT
		jp	ym_prog
;
;------------------------------------------------------------------------------
; Make ready for hbios play
;------------------------------------------------------------------------------
;
YM_MAKE_RDY:	CPL
		LD	(YM_RDY_RST),A		; Invert the ready flag
		ld	hl,ym_cfg_ready		; Program ym2612 for playing
		jp	ym_prog
;
;------------------------------------------------------------------------------
; Command sequence to play a note
;------------------------------------------------------------------------------
;
ym_playnote:	.db	part0, 8/2
		.db	$28, $00		; [0] KEY OFF
		.db	$A4, $3F		; [0] Frequency MSB
		.db	$A0, $FF		; [0] Frequency LSB
		.db	$28, $F0		; [0] KEY ON
		.db	$00			; End flag
;
;------------------------------------------------------------------------------
; Quarter semitone values
;------------------------------------------------------------------------------
;
ym_notetable:	.dw	644			; C	; 152
		.dw	653			;  approx
		.dw	663			;  approx
		.dw	672			;  approx	
		.dw	681			; C#	; 156
		.dw	691			;  approx
		.dw	702			;  approx
		.dw	712			;  approx
		.dw	722			; D	; 160
		.dw	733			;  approx
		.dw	744			;  approx
		.dw	754			;  approx
		.dw	765			; D#	; 164
		.dw	776			;  approx
		.dw	788			;  approx
		.dw	799			;  approx
		.dw	810			; E	; 168
		.dw	822			;  approx
		.dw	834			;  approx
		.dw	846			;  approx
		.dw	858			; F	; 172
		.dw	871			;  approx
		.dw	884			;  approx
		.dw	897			;  approx
		.dw	910			; F#	; 176
		.dw	924			;  approx
		.dw	937			;  approx
		.dw	951			;  approx
		.dw	964			; G 	; 180
		.dw	978			;  approx
		.dw	993			;  approx
		.dw	1007			;  approx
		.dw	1021			; G#	; 184
		.dw	1036			;  approx
		.dw	1051			;  approx
		.dw	1066			;  approx
		.dw	1081			; A 	; 188
		.dw	1097			;  approx
		.dw	1114			;  approx
		.dw	1130			;  approx
		.dw	1146			; A#	; 192
		.dw	1163			;  approx
		.dw	1180			;  approx
		.dw	1197			;  approx
		.dw	1214			; B	; 196
		.dw	1232			;  approx
		.dw	1250			;  approx
		.dw	1268			;  approx
;
;------------------------------------------------------------------------------
; Register configuration data for reset state
;------------------------------------------------------------------------------
;	
part0:		.equ	YMSEL
part1:		.equ	YM2SEL
;
ym_cfg:		.db	part0,  24/2
		.db	$22,$00			; [0] lfo off
		.db	$27,$00			; [0] Disable independant Channel 3
		.db	$28,$00			; [0] note off ch 1
		.db	$28,$01			; [0] note off ch 2
		.db	$28,$02			; [0] note off ch 3
		.db	$28,$04			; [0] note off ch 4
		.db	$28,$05			; [0] note off ch 5
		.db	$28,$06			; [0] note off ch 6
		.db	$2b,$00			; [0] dac off
		.db	$b4,$00			; [0] sound off ch 1-3
		.db	$b5,$00	
		.db	$b6,$00	
;
		.db	part1, 6/2
		.db	$b4,$00			; [1] sound off ch 4-6
		.db	$b5,$00			; [1] 
		.db	$b6,$00			; [1] 
;
		.db	part0, 24/2
		.db	$40,$7f			; [0] ch 1-3 total level minimum
		.db	$41,$7f			; [0] 
		.db	$42,$7f			; [0] 
		.db	$44,$7f			; [0] 
		.db	$45,$7f			; [0] 
		.db	$46,$7f			; [0] 
		.db	$48,$7f			; [0] 
		.db	$49,$7f			; [0] 
		.db	$4a,$7f			; [0] 
		.db	$4c,$7f			; [0] 
		.db	$4d,$7f			; [0] 
		.db	$4e,$7f			; [0] 
;
		.db	part1, 24/2
		.db	$40,$7f			; [1] ch 4-6 total level minimum
		.db	$41,$7f			; [1]
		.db	$42,$7f			; [1]
		.db	$44,$7f			; [1]
		.db	$45,$7f			; [1]
		.db	$46,$7f			; [1]
		.db	$48,$7f			; [1]
		.db	$49,$7f			; [1]
		.db	$4a,$7f			; [1]
		.db	$4c,$7f			; [1]
		.db	$4d,$7f			; [1]
		.db	$4e,$7f			; [1]
;
		.db	$00			; End flag
;
;------------------------------------------------------------------------------
; Register configuration data for play
;------------------------------------------------------------------------------
;
ym_cfg_ready:	.db	part0, 20/2
		.db	$22, $00		; [0] Global: LFO disable
		.db	$B0, $30		; [0] Algorithm, Feedback <- pure sine wave
		.db	$3C, $01		; [0] Operator 4.MUL = 1
		.db	$B4, $C0		; [0] Stereo output
		.db	$44, $7F		; [0] Mute operator 3  <- pure sine wave
		.db	$4C, $00		; [0] Max volume for operator 4
		.db	$5C, $1F		; [0] Operator 4.AR = shortest
		.db	$6C, $06		; [0] Operator 4.D1R= 6
		.db	$7C, $1F		; [0] Operator 4.D2R= 31
		.db	$8C, $FF		; [0] Operator 4.SL = 15 / Operator4. RR=15
;		.db	$A4, $3F		; [0] Frequency MSB
;		.db	$A0, 84;$FF		; [0] Frequency LSB
;		.db	$28, $00		; [0] KEY OFF
;		.db	$28, $F0		; [0] KEY ON
;
		.db	$00			; End flag

;------------------------------------------------------------------------------
; Register configuration data for hard reset
;------------------------------------------------------------------------------
;
#IF (0)
ym_cfg_full:	.db	$22,$00			; [0] lfo off
		.db	$27,$00			; [0] Disable independant Channel 3
		.db	$28,$00			; [0] note off ch 1
		.db	$28,$01			; [0] note off ch 2
		.db	$28,$02			; [0] note off ch 3
		.db	$28,$04			; [0] note off ch 4
		.db	$28,$05			; [0] note off ch 5
		.db	$28,$06			; [0] note off ch 6
		.db	$2b,$00			; [0] dac off
		.db	$b4,$00			; [0] sound off ch 1-3
		.db	$b5,$00			; [0] 
		.db	$b6,$00			; [0] 

s2:		.db	$b4,$00			; [1] sound off ch 4-6
		.db	$b5,$00			; [1] 
		.db	$b6,$00			; [1] 

s3:		.db	$40,$7f			; [0] ch 1-3 total level minimum
		.db	$41,$7f			; [0] 
		.db	$42,$7f			; [0] 
		.db	$44,$7f			; [0] 
		.db	$45,$7f			; [0] 
		.db	$46,$7f			; [0] 
		.db	$48,$7f			; [0] 
		.db	$49,$7f			; [0] 
		.db	$4a,$7f			; [0] 
		.db	$4c,$7f			; [0] 
		.db	$4d,$7f			; [0] 
		.db	$4e,$7f			; [0] 
s4:
		.db	$40,$7f			; [1] ch 4-6 total level minimum
		.db	$41,$7f			; [1]
		.db	$42,$7f			; [1]
		.db	$44,$7f			; [1]
		.db	$45,$7f			; [1]
		.db	$46,$7f			; [1]
		.db	$48,$7f			; [1]
		.db	$49,$7f			; [1]
		.db	$4a,$7f			; [1]
		.db	$4c,$7f			; [1]
		.db	$4d,$7f			; [1]
		.db	$4e,$7f			; [1]
s5:
		.db	$2a,$00			; [0]	; dac value
 		.db	$24,$00			; [0]	; timer A frequency
		.db	$25,$00			; [0]	; timer A frequency
		.db	$26,$00			; [0]	; time B frequency
		.db	$30,$00			; [0]	; ch 1-3 multiply & detune
		.db	$31,$00	                ; [0]
		.db	$32,$00	                ; [0]
		.db	$34,$00	                ; [0]
		.db	$35,$00	                ; [0]
		.db	$36,$00	                ; [0]
		.db	$38,$00	                ; [0]
		.db	$39,$00	                ; [0]
		.db	$3a,$00	                ; [0]
		.db	$3c,$00	                ; [0]
		.db	$3d,$00	                ; [0]
		.db	$3e,$00	                ; [0]
s6:
		.db	$30,$00			; [1] ch 4-6 multiply & detune
		.db	$31,$00			; [1]
		.db	$32,$00			; [1]
		.db	$34,$00			; [1]
		.db	$35,$00			; [1]
		.db	$36,$00			; [1]
		.db	$38,$00			; [1]
		.db	$39,$00			; [1]
		.db	$3a,$00			; [1]
		.db	$3c,$00			; [1]
		.db	$3d,$00			; [1]
		.db	$3e,$00			; [1]
s7:                             			
		.db	$50,$00	                ; [0] ch 1-3 attack rate and scaling
		.db	$51,$00	                ; [0]
		.db	$52,$00	                ; [0]
		.db	$54,$00	                ; [0]
		.db	$55,$00	                ; [0]
		.db	$56,$00	                ; [0]
		.db	$58,$00	                ; [0]
		.db	$59,$00	                ; [0]
		.db	$5a,$00	                ; [0]
		.db	$5c,$00	                ; [0]
		.db	$5d,$00	                ; [0]
		.db	$5e,$00	                ; [0]
s8:
		.db	$50,$00			; [1] ch 4-6 attack rate and scaling
		.db	$51,$00			; [1]
		.db	$52,$00			; [1]
		.db	$54,$00			; [1]
		.db	$55,$00			; [1]
		.db	$56,$00			; [1]
		.db	$58,$00			; [1]
		.db	$59,$00			; [1]
		.db	$5a,$00			; [1]
		.db	$5c,$00			; [1]
		.db	$5d,$00			; [1]
		.db	$5e,$00			; [1]
s9:
		.db	$60,$00	                ; [0] ch 1-3 decay rate and am enable
		.db	$61,$00	                ; [0]
		.db	$62,$00	                ; [0]
		.db	$64,$00	                ; [0]
		.db	$65,$00	                ; [0]
		.db	$66,$00	                ; [0]
		.db	$68,$00	                ; [0]
		.db	$69,$00	                ; [0]
		.db	$6a,$00	                ; [0]
		.db	$6c,$00	                ; [0]
		.db	$6d,$00	                ; [0]
		.db	$6e,$00	                ; [0]
s10:
		.db	$60,$00			; [1] ch 4-6 decay rate and am enable
		.db	$61,$00			; [1]
		.db	$62,$00			; [1]
		.db	$64,$00			; [1]
		.db	$65,$00			; [1]
		.db	$66,$00			; [1]
		.db	$68,$00			; [1]
		.db	$69,$00			; [1]
		.db	$6a,$00			; [1]
		.db	$6c,$00			; [1]
		.db	$6d,$00			; [1]
		.db	$6e,$00			; [1]
s11:
		.db	$70,$00	                ; [0] ch 1-3 sustain rate
		.db	$71,$00	                ; [0]
		.db	$72,$00	                ; [0]
		.db	$74,$00	                ; [0]
		.db	$75,$00	                ; [0]
		.db	$76,$00	                ; [0]
		.db	$78,$00	                ; [0]
		.db	$79,$00	                ; [0]
		.db	$7a,$00	                ; [0]
		.db	$7c,$00	                ; [0]
		.db	$7d,$00	                ; [0]
		.db	$7e,$00	                ; [0]
s12:
		.db	$70,$00			; [1] ch 4-6 sustain rate
		.db	$71,$00			; [1]
		.db	$72,$00			; [1]
		.db	$74,$00			; [1]
		.db	$75,$00			; [1]
		.db	$76,$00			; [1]
		.db	$78,$00			; [1]
		.db	$79,$00			; [1]
		.db	$7a,$00			; [1]
		.db	$7c,$00			; [1]
		.db	$7d,$00			; [1]
		.db	$7e,$00			; [1]
s13:
		.db	$80,$00	                ; [0] ch 1-3 release rate and sustain level
		.db	$81,$00	                ; [0]
		.db	$82,$00	                ; [0]
		.db	$84,$00	                ; [0]
		.db	$85,$00	                ; [0]
		.db	$86,$00	                ; [0]
		.db	$88,$00	                ; [0]
		.db	$89,$00	                ; [0]
		.db	$8a,$00	                ; [0]
		.db	$8c,$00	                ; [0]
		.db	$8d,$00	                ; [0]
		.db	$8e,$00	                ; [0]
s14:
		.db	$80,$00			; [1] ch 4-6 release rate and sustain level
		.db	$81,$00			; [1]
		.db	$82,$00			; [1]
		.db	$84,$00			; [1]
		.db	$85,$00			; [1]
		.db	$86,$00			; [1]
		.db	$88,$00			; [1]
		.db	$89,$00			; [1]
		.db	$8a,$00			; [1]
		.db	$8c,$00			; [1]
		.db	$8d,$00			; [1]
		.db	$8e,$00			; [1]
s15:
		.db	$90,$00	                ; [0] ch 1-3 ssg-eg
		.db	$91,$00	                ; [0]
		.db	$92,$00	                ; [0]
		.db	$94,$00	                ; [0]
		.db	$95,$00	                ; [0]
		.db	$96,$00	                ; [0]
		.db	$98,$00	                ; [0]
		.db	$99,$00	                ; [0]
		.db	$9a,$00	                ; [0]
		.db	$9c,$00	                ; [0]
		.db	$9d,$00	                ; [0]
		.db	$9e,$00	                ; [0]
s16:
		.db	$90,$00			; [1] ch 4-6 ssg-eg
		.db	$91,$00			; [1]
		.db	$92,$00			; [1]
		.db	$94,$00			; [1]
		.db	$95,$00			; [1]
		.db	$96,$00			; [1]
		.db	$98,$00			; [1]
		.db	$99,$00			; [1]
		.db	$9a,$00			; [1]
		.db	$9c,$00			; [1]
		.db	$9d,$00			; [1]
		.db	$9e,$00			; [1]
s17:
		.db	$a0,$00	                ; [0] ch 1-3 frequency
		.db	$a1,$00	                ; [0]
		.db	$a2,$00	                ; [0]
		.db	$a4,$00	                ; [0]
		.db	$a5,$00	                ; [0]
		.db	$a6,$00	                ; [0]
;		.db	$a8,$00	                ; [0] ch 3 special mode
;		.db	$a9,$00	                ; [0]
;		.db	$aa,$00	                ; [0]
;		.db	$ac,$00	                ; [0]
;		.db	$ad,$00	                ; [0]
;		.db	$ae,$00	                ; [0]
s18:
		.db	$a0,$00			; [1] ch 4-6 frequency
		.db	$a1,$00			; [1]
		.db	$a2,$00			; [1]
		.db	$a4,$00			; [1]
		.db	$a5,$00			; [1]
		.db	$a6,$00			; [1]
;		.db	$a8,$00			; [1] ch 3 special mode
;		.db	$a9,$00			; [1]
;		.db	$aa,$00			; [1]
;		.db	$ac,$00			; [1]
;		.db	$ad,$00			; [1]
;		.db	$ae,$00			; [1]
s19:
		.db	$b0,$00	                ; [0] ch 1-3 algorith + feedback
		.db	$b1,$00	                ; [0]
		.db	$b2,$00	                ; [0]
s20:
		.db	$b0,$00			; [1] ch 4-6 algorith + feedback
		.db	$b1,$00			; [1]
		.db	$b2,$00			; [1]
;
		.db	$00			; End flag
s21:
#ENDIF
