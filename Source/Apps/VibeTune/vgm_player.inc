;===============================================================================
; VGM Player Module for VibeTune
;===============================================================================
; Ported from VGMPLAY.ASM by J.B. Langston, Marco Maccaferri, Ed Brindley
; Adapted for RomWBW VibeTune by J.M. Duraes, 2026-04-09
;
; Processes VGM (Video Game Music) command stream and outputs to sound hardware.
;
; AY-3-8910 port addressing uses TS_PORTS1 / TS_PORTS2 (same variables as
; TurboSound PT3 dual-chip support).  TS_PORTS_SETUP must have been called
; before playback starts so both port pairs are populated.
;
; Supported chips:
;   AY-3-8910 / YM2149  - single chip (TS_PORTS1) and dual chip (TS_PORTS2)
;   OPL2 (YM3812)       - ports OPL3ADDR1 / OPL3DATA1
;   OPL3 (YMF262)       - both banks
;   SN76489 (PSG)       - ports PSGREG / PSG2REG (constants, not HBIOS-detected)
;   YM2151 (OPM)        - ports YM2151SEL / YM2151DAT (RC2014-YM2151 board)
;===============================================================================

;===============================================================================
; VGM_PLAY_FRAME - Process one frame of VGM commands
;===============================================================================
; Processes VGM command stream until a wait command is encountered.
; Returns NZ when a wait has been loaded into vgmdly (caller should then call
; VGM_APPLY_DELAY).  Returns Z when the stream has ended (0x66 with no loop).
;
; Uses: AF, BC, DE, HL
; Modifies: vgmpos, vgmdly
;===============================================================================
VGM_PLAY_FRAME:
	LD	HL,(vgmpos)		; Start processing VGM commands
VGM_NEXT:
	LD	A,(HL)			; Get command byte
	INC	HL			; Advance pointer
	LD	(vgmpos),HL		; Save position
	CP	66H			; 0x66: End / loop
	JR	NZ,VGM_NEXT1
	LD	HL,(vgmdata + 1CH)	; Loop offset from header
	LD	A,H
	OR	L
	RET	Z			; No loop offset = end of stream (Z flag set)
	LD	DE,vgmdata + 1CH
	ADD	HL,DE			; Calculate absolute loop position
	LD	(vgmpos),HL		; Reset position to loop point
	JR	VGM_NEXT

VGM_NEXT1:
	CP	4FH			; 0x4F: Game Gear stereo (ignored)
	JR	NZ,VGM_OPL2
	INC	HL			; Skip one data byte
	LD	(vgmpos),HL
	JR	VGM_NEXT

VGM_OPL2:
	CP	5AH			; 0x5A: Write to OPL2
	JR	NZ,VGM_OPL31
	LD	A,(HL)			; Get register
	INC	HL
	LD	E,A			; Save register for optional TL boost
	OUT	(OPL3ADDR1),A		; Select register
	PUSH	BC
	LD	B,3
	DJNZ	$
	POP	BC
	LD	A,(HL)			; Get data
	INC	HL
	LD	D,A			; Save data
	LD	A,E			; A = register
	SUB	43H
	JR	C,VGM_OPL2_NBOOST
	CP	13H
	JR	NC,VGM_OPL2_NBOOST
	AND	07H
	CP	03H
	JR	NC,VGM_OPL2_NBOOST
	LD	A,D
	AND	0C0H			; keep KSL, clear attenuation for carriers
	JR	VGM_OPL2_WDATA
VGM_OPL2_NBOOST:
	LD	A,D
VGM_OPL2_WDATA:
	OUT	(OPL3DATA1),A		; Write data
	LD	(vgmpos),HL
	JP	VGM_NEXT

VGM_OPL31:
	CP	5EH			; 0x5E: Write to OPL3 bank 1
	JR	NZ,VGM_OPL32
	LD	A,(HL)
	INC	HL
	LD	E,A
	OUT	(OPL3ADDR1),A
	PUSH	BC
	LD	B,3
	DJNZ	$
	POP	BC
	LD	A,(HL)
	INC	HL
	LD	D,A
	LD	A,E
	SUB	43H
	JR	C,VGM_OPL31_NBOOST
	CP	13H
	JR	NC,VGM_OPL31_NBOOST
	AND	07H
	CP	03H
	JR	NC,VGM_OPL31_NBOOST
	LD	A,D
	AND	0C0H
	JR	VGM_OPL31_WDATA
VGM_OPL31_NBOOST:
	LD	A,D
VGM_OPL31_WDATA:
	OUT	(OPL3DATA1),A
	LD	(vgmpos),HL
	JP	VGM_NEXT

VGM_OPL32:
	CP	5FH			; 0x5F: Write to OPL3 bank 2
	JR	NZ,VGM_PSG
	LD	A,(HL)
	INC	HL
	LD	E,A
	OUT	(OPL3ADDR2),A
	PUSH	BC
	LD	B,3
	DJNZ	$
	POP	BC
	LD	A,(HL)
	INC	HL
	LD	D,A
	LD	A,E
	SUB	43H
	JR	C,VGM_OPL32_NBOOST
	CP	13H
	JR	NC,VGM_OPL32_NBOOST
	AND	07H
	CP	03H
	JR	NC,VGM_OPL32_NBOOST
	LD	A,D
	AND	0C0H
	JR	VGM_OPL32_WDATA
VGM_OPL32_NBOOST:
	LD	A,D
VGM_OPL32_WDATA:
	OUT	(OPL3DATA2),A
	LD	(vgmpos),HL
	JP	VGM_NEXT

VGM_PSG:
	CP	50H			; 0x50: Write to SN76489 (primary)
	JR	NZ,VGM_PSG2
	LD	A,(HL)
	INC	HL
	OUT	(PSGREG),A
	LD	(vgmpos),HL
	JP	VGM_NEXT

VGM_PSG2:
	CP	30H			; 0x30: Write to SN76489 (secondary)
	JR	NZ,VGM_YM2151
	LD	A,(HL)
	INC	HL
	OUT	(PSG2REG),A
	LD	(vgmpos),HL
	JP	VGM_NEXT

VGM_YM2151:
	CP	054H			; 0x54: Write register+data to YM2151 (primary)
	JR	NZ,VGM_YM2151_2
	LD	A,(HL)			; Get register byte
	INC	HL
	LD	D,A
	LD	A,(YM2151SELV)
	LD	C,A
	LD	A,D
	OUT	(C),A			; Select register
	LD	A,(HL)			; Get data byte
	INC	HL
	LD	D,A
	LD	A,(YM2151DATV)
	LD	C,A
	LD	A,D
	OUT	(C),A			; Write data
	LD	(vgmpos),HL
	JP	VGM_NEXT

VGM_YM2151_2:
	CP	0A4H			; 0xA4: Write register+data to YM2151 (secondary)
	JR	NZ,VGM_AY
	LD	A,(YM2151SEL2V)
	OR	A
	JR	Z,VGM_YM2151_2_SKIP	; undefined secondary YM2151: consume command only
	LD	A,(HL)			; Get register byte
	INC	HL
	LD	D,A
	LD	A,(YM2151SEL2V)
	LD	C,A
	LD	A,D
	OUT	(C),A			; Select register (secondary)
	LD	A,(HL)			; Get data byte
	INC	HL
	LD	D,A
	LD	A,(YM2151DAT2V)
	LD	C,A
	LD	A,D
	OUT	(C),A			; Write data (secondary)
	LD	(vgmpos),HL
	JP	VGM_NEXT
VGM_YM2151_2_SKIP:
	INC	HL			; skip register byte
	INC	HL			; skip data byte
	LD	(vgmpos),HL
	JP	VGM_NEXT

VGM_AY:
	CP	0A0H			; 0xA0: Write to AY-3-8910
	JR	NZ,VGM_WAITNN
	LD	A,(HL)			; Get register byte
	INC	HL
	BIT	7,A			; Bit 7 = chip 2
	JR	Z,VGM_AY1
	; Chip 2 - use TS_PORTS2
	AND	7FH			; Clear chip-select bit
	LD	C,A			; Save register
	PUSH	HL
	LD	DE,(TS_PORTS2)		; E=RSEL2, D=RDAT2
	LD	A,C
	LD	C,E			; C = RSEL2 port
	OUT	(C),A			; Select register on chip 2
	POP	HL
	LD	A,(HL)			; Get data
	INC	HL
	LD	(vgmpos),HL
	LD	C,D			; C = RDAT2 port
	OUT	(C),A			; Write data to chip 2
	JP	VGM_NEXT

VGM_AY1:
	; Chip 1 - use TS_PORTS1
	LD	C,A			; Save register
	PUSH	HL
	LD	DE,(TS_PORTS1)		; E=RSEL, D=RDAT
	LD	A,C
	LD	C,E			; C = RSEL port
	OUT	(C),A			; Select register
	POP	HL
	LD	A,(HL)			; Get data
	INC	HL
	LD	(vgmpos),HL
	LD	C,D			; C = RDAT port
	OUT	(C),A			; Write data
	JP	VGM_NEXT

VGM_WAITNN:
	CP	61H			; 0x61: Wait nn samples
	JR	NZ,VGM_WAIT60
	LD	A,(HL)			; Low byte of wait count
	INC	HL
	LD	D,(HL)			; High byte
	INC	HL
	LD	(vgmpos),HL
	LD	L,A
	LD	H,D
	LD	(vgmdly),HL
	OR	1			; NZ = wait pending
	RET

VGM_WAIT60:
	CP	62H			; 0x62: Wait 735 samples (60 Hz frame)
	JR	NZ,VGM_WAIT50
	LD	(vgmpos),HL
	LD	HL,735
	LD	(vgmdly),HL
	OR	1
	RET

VGM_WAIT50:
	CP	63H			; 0x63: Wait 882 samples (50 Hz frame)
	JR	NZ,VGM_WAIT1
	LD	(vgmpos),HL
	LD	HL,882
	LD	(vgmdly),HL
	OR	1
	RET

VGM_WAIT1:
	CP	70H			; 0x70-0x7F: Wait 1-16 samples
	JP	C,VGM_SKIP_UNK		; < 0x70: skip unknown command safely
	CP	80H
	JP	NC,VGM_SKIP_UNK		; >= 0x80: skip unknown command safely
	SUB	6FH			; 0x70=1 .. 0x7F=16 samples
	LD	L,A
	LD	H,0
	LD	(vgmdly),HL
	OR	1
	RET

;===============================================================================
; VGM_SKIP_UNK - Skip unsupported VGM commands without desynchronizing stream
;===============================================================================
; Input: A = command byte, HL = pointer to first command parameter
;===============================================================================
VGM_SKIP_UNK:
	CP	67H			; 0x67: data block (0x66 + type + size + data)
	JR	Z,VGM_SKIP_67
	CP	68H			; 0x68: PCM RAM write (12 parameter bytes)
	JR	Z,VGM_SKIP_68
	CP	0E0H			; 0xE0: seek offset (4 bytes)
	JR	Z,VGM_SKIP_4
	CP	0C0H			; 0xC0-0xDF: generally 3-byte payload
	JR	NC,VGM_SKIP_3
	CP	0B0H			; 0xB0-0xBF: generally 2-byte payload
	JR	NC,VGM_SKIP_2
	CP	0A1H			; 0xA1-0xAF: generally 2-byte payload
	JR	NC,VGM_SKIP_2
	CP	90H			; 0x90-0x95 DAC stream cmds (variable, common fixed forms)
	JR	C,VGM_SKIP_RANGE_50_6F
	CP	96H
	JR	C,VGM_SKIP_4
	JR	VGM_SKIP_1		; unknown 0x96-0x9F: conservative 1-byte skip
VGM_SKIP_RANGE_50_6F:
	CP	50H			; 0x50-0x5F writes are 2-byte payload (aa,dd)
	JR	NC,VGM_SKIP_2
	CP	40H			; 0x40-0x4F (except 0x4F handled) often 1-byte payload
	JR	NC,VGM_SKIP_1
	CP	30H			; 0x30-0x3F writes often 1-byte payload
	JR	NC,VGM_SKIP_1
	JR	VGM_SKIP_1		; fallback
VGM_SKIP_1:
	INC	HL
	LD	(vgmpos),HL
	JP	VGM_NEXT
VGM_SKIP_2:
	INC	HL
	INC	HL
	LD	(vgmpos),HL
	JP	VGM_NEXT
VGM_SKIP_3:
	INC	HL
	INC	HL
	INC	HL
	LD	(vgmpos),HL
	JP	VGM_NEXT
VGM_SKIP_4:
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	LD	(vgmpos),HL
	JP	VGM_NEXT
VGM_SKIP_68:
	LD	DE,12
	ADD	HL,DE
	LD	(vgmpos),HL
	JP	VGM_NEXT
VGM_SKIP_67:
	; Format: 67 66 tt ss ss ss ss [data...]
	INC	HL			; skip 0x66 marker byte
	INC	HL			; skip type byte
	LD	E,(HL)			; size byte 0 (LSB)
	INC	HL
	LD	D,(HL)			; size byte 1
	INC	HL
	LD	A,(HL)			; size byte 2
	INC	HL
	LD	C,(HL)			; size byte 3 (MSB)
	INC	HL
	ADD	HL,DE			; add low 16 bits of data size
	LD	(vgmpos),HL
	LD	A,C
	OR	A
	JP	Z,VGM_NEXT
VGM_SKIP_67_PG:
	LD	A,H
	ADD	A,C			; add high-size pages (256-byte chunks)
	LD	H,A
	DEC	C
	JR	NZ,VGM_SKIP_67_PG
	LD	(vgmpos),HL
	JP	VGM_NEXT

;===============================================================================
; VGM_APPLY_DELAY - Burn CPU cycles to match VGM sample rate (~44.1 KHz)
;===============================================================================
; Executes vgmdly tight inner loops, each calibrated via vgmfdly.
;
; Uses: AF, BC, HL
;===============================================================================
VGM_APPLY_DELAY:
	LD	HL,(vgmdly)
VGM_DELAY_LOOP:
	LD	A,(vgmfdly)
	LD	B,A			; vgmfdly iterations per sample
	DJNZ	$			; tight delay loop
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,VGM_DELAY_LOOP
	RET

;===============================================================================
; VGM_BOOST_VOLUME - Maximise OPL carrier operator output level
;===============================================================================
; Only carrier operators (registers 0x43-0x45, 0x4B-0x4D, 0x53-0x55) are
; boosted.  Modulator operators are left unchanged.
;
; Input:  A = OPL register, E = data byte
; Output: E = boosted data (attenuation bits cleared, KSL preserved)
; Uses:   flags only
;===============================================================================
VGM_BOOST_VOLUME:
	CP	43H
	JR	Z,VGM_DO_BOOST
	CP	44H
	JR	Z,VGM_DO_BOOST
	CP	45H
	JR	Z,VGM_DO_BOOST
	CP	4BH
	JR	Z,VGM_DO_BOOST
	CP	4CH
	JR	Z,VGM_DO_BOOST
	CP	4DH
	JR	Z,VGM_DO_BOOST
	CP	53H
	JR	Z,VGM_DO_BOOST
	CP	54H
	JR	Z,VGM_DO_BOOST
	CP	55H
	JR	Z,VGM_DO_BOOST
	RET
VGM_DO_BOOST:
	PUSH	HL
	LD	A,E
	AND	0C0H			; Keep KSL bits only; zero attenuation
	LD	E,A
	POP	HL
	RET

;===============================================================================
; VGM_MUTE_ALL - Silence all sound hardware used during VGM playback
;===============================================================================
; Mutes SN76489, AY-3-8910 (both chips via TS_PORTS1/TS_PORTS2), and OPL3.
;
; Uses: AF, BC, DE, HL
;===============================================================================
VGM_MUTE_ALL:
	; Mute SN76489 channels (primary chip)
	LD	A,9FH			; CH1 volume off
	OUT	(PSGREG),A
	LD	A,0BFH
	OUT	(PSGREG),A		; CH2 volume off
	LD	A,0DFH
	OUT	(PSGREG),A		; CH3 volume off
	LD	A,0FFH
	OUT	(PSGREG),A		; Noise off
	; Secondary SN76489 (if present)
	LD	A,9FH
	OUT	(PSG2REG),A
	LD	A,0BFH
	OUT	(PSG2REG),A
	LD	A,0DFH
	OUT	(PSG2REG),A
	LD	A,0FFH
	OUT	(PSG2REG),A

	; Mute AY-3-8910 volume registers 8, 9, 10 (both chips)
	LD	DE,(TS_PORTS1)		; E=RSEL, D=RDAT
	LD	HL,(TS_PORTS2)		; L=RSEL2, H=RDAT2
	LD	B,3			; 3 channels
	LD	A,8			; Start at volume register 8
VGM_MUTE_LOOP:
	PUSH	AF
	LD	C,E
	OUT	(C),A			; Select register on chip 1
	LD	C,L
	OUT	(C),A			; Select register on chip 2
	XOR	A
	LD	C,D
	OUT	(C),A			; Write 0 to chip 1
	LD	C,H
	OUT	(C),A			; Write 0 to chip 2
	POP	AF
	INC	A
	DJNZ	VGM_MUTE_LOOP

	; Key-off all OPL3 channels (registers 0xB0-0xB8 on both banks)
	LD	C,0B0H
VGM_OPL_KEYOFF:
	LD	A,C
	OUT	(OPL3ADDR1),A
	PUSH	BC
	LD	B,3
	DJNZ	$
	POP	BC
	XOR	A
	OUT	(OPL3DATA1),A
	LD	A,C
	OUT	(OPL3ADDR2),A
	PUSH	BC
	LD	B,3
	DJNZ	$
	POP	BC
	XOR	A
	OUT	(OPL3DATA2),A
	INC	C
	LD	A,C
	CP	0B9H
	JR	NZ,VGM_OPL_KEYOFF

	; Clear remaining OPL3 registers (both banks)
	LD	BC,0100H		; B=count (256), C=start register 0
VGM_OPL3_RESET:
	LD	A,C
	OUT	(OPL3ADDR1),A
	PUSH	BC
	LD	B,3
	DJNZ	$
	POP	BC
	XOR	A
	OUT	(OPL3DATA1),A
	LD	A,C
	OUT	(OPL3ADDR2),A
	PUSH	BC
	LD	B,3
	DJNZ	$
	POP	BC
	XOR	A
	OUT	(OPL3DATA2),A
	INC	C
	DJNZ	VGM_OPL3_RESET
	; OPL3 registers now all cleared (both banks).

	; Key-off all 8 YM2151 channels and set TL to max attenuation.
	; Register 0x08 (key control): slot mask bits [6:3]=0 = key-off, bits [2:0]=channel.
	LD	A,(YM2151SELV)
	OR	A
	RET	Z			; YM2151 unmapped
	LD	B,8			; 8 channels
	LD	E,0			; start at channel 0
VGM_YM_KO:
	LD	A,008H			; key control register
	LD	D,A
	LD	A,(YM2151SELV)
	LD	C,A
	LD	A,D
	OUT	(C),A
	LD	A,E			; channel number (slot mask=0 = all slots key-off)
	LD	D,A
	LD	A,(YM2151DATV)
	LD	C,A
	LD	A,D
	OUT	(C),A
	LD	A,20			; fixed delay: ~338 cycles (~46 us @ 7.4 MHz) > max BUSY time
VGM_YM_KD:
	DEC	A
	JR	NZ,VGM_YM_KD
	INC	E
	DJNZ	VGM_YM_KO
	; Set TL registers 0x60-0x7F to 0x7F (max attenuation = silence)
	LD	E,060H
	LD	B,020H			; 32 operator TL registers
VGM_YM_TL:
	LD	A,E
	LD	D,A
	LD	A,(YM2151SELV)
	LD	C,A
	LD	A,D
	OUT	(C),A
	LD	A,07FH
	LD	D,A
	LD	A,(YM2151DATV)
	LD	C,A
	LD	A,D
	OUT	(C),A
	INC	E
	DJNZ	VGM_YM_TL
	RET
