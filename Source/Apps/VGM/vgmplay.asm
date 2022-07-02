;------------------------------------------------------------------------------
; SN76489 + AY-3-8910 + YM2162 + YM2151 VGM player for CP/M
;------------------------------------------------------------------------------
;
; Based on VGM player by J.B. Langston
; https://github.com/jblang/SN76489
;
; Enhanced with multi-chip support by Marco Maccaferri
; YM2151 support from Ed Brindley
;
; YM2162/YM3484, GD3 support, VGM Chip identification, 
; default file type, basic file size checking added by Phil Summers
;
; Bugs: YM2151 playback untested & no mute.
;
; Assemble with:
;
;   TASM -80 -b VGMPLAY.ASM VGMPLAY.COM
;
;------------------------------------------------------------------------------
; Device and system specific definitions
;------------------------------------------------------------------------------
;
P8X180          .EQU    0           	        ; System configuration
RC2014          .EQU    0
SBCECB		.EQU	1
MBC		.EQU	0
;
                .IF P8X180
RSEL            .EQU    82H			; Primary AY-3-8910 Register selection
RDAT            .EQU    83H			; Primary AY-3-8910 Register data
RSEL2           .EQU    88H			; Secondary AY-3-8910 Register selection
RDAT2           .EQU    89H			; Secondary AY-3-8910 Register data
PSG1REG         .EQU    84H			; Primary SN76489
PSG2REG         .EQU    8AH			; Secondary SN76489
YM2151_SEL1	.EQU	0B0H			; Primary YM2151 register selection
YM2151_DAT1	.EQU	0B1H			; Primary YM2151 register data
YM2151_SEL2	.EQU	0B2H			; Secondary YM2151 register selection
YM2151_DAT2	.EQU	0B3H			; Secondary YM2151 register data
FRAME_DLY       .EQU    48			; Frame delay (~ 1/44100)
                .ENDIF
;
                .IF RC2014
RSEL            .EQU    0D8H			; Primary AY-3-8910 Register selection
RDAT            .EQU    0D0H			; Primary AY-3-8910 Register data
RSEL2           .EQU    0A0H			; Secondary AY-3-8910 Register selection
RDAT2           .EQU    0A1H			; Secondary AY-3-8910 Register data
PSG1REG         .EQU    0FFH			; Primary SN76489
PSG2REG         .EQU    0FBH			; Secondary SN76489
YM2151_SEL1	.EQU	0FEH			; Primary YM2151 register selection
YM2151_DAT1	.EQU	0FFH			; Primary YM2151 register data
YM2151_SEL2	.EQU	0D0H			; Secondary YM2151 register selection
YM2151_DAT2	.EQU	0D1H			; Secondary YM2151 register data
FRAME_DLY       .EQU    15			; Frame delay (~ 1/44100)
                .ENDIF
;
                .IF SBCECB
RSEL            .EQU    0D8H			; Primary AY-3-8910 Register selection
RDAT            .EQU    0D0H			; Primary AY-3-8910 Register data
RSEL2           .EQU    0A0H			; Secondary AY-3-8910 Register selection
RDAT2           .EQU    0A1H			; Secondary AY-3-8910 Register data
YMSEL		.EQU	0C0H			; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.EQU	0C1H			; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.EQU	0C2H			; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.EQU	0C3H			; Secondary YM2162 11000011 a1=1 a0=1
PSG1REG         .EQU    0C6H			; Primary SN76489
PSG2REG         .EQU    0C7H			; Secondary SN76489
YM2151_SEL1	.EQU	0FEH			; Primary YM2151 register selection
YM2151_DAT1	.EQU	0FFH			; Primary YM2151 register data
YM2151_SEL2	.EQU	0FEH			; Secondary YM2151 register selection
YM2151_DAT2	.EQU	0FFH			; Secondary YM2151 register data
FRAME_DLY       .EQU    8  			; Frame delay (~ 1/44100)
                .ENDIF
;
		.IF MBC
RSEL            .EQU    0A0H			; Primary AY-3-8910 Register selection
RDAT            .EQU    0A1H			; Primary AY-3-8910 Register data
RSEL           	.EQU    0D8H			; Secondary AY-3-8910 Register selection
RDAT           	.EQU    0D0H			; Secondary AY-3-8910 Register data
YMSEL		.EQU	0C0H			; 11000000 a1=0 a0=0
YMDAT		.EQU	0C1H			; 11000001 a1=0 a0=1
YM2SEL		.EQU	0C2H			; 11000010 a1=1 a0=0
YM2DAT		.EQU	0C3H			; 11000011 a1=1 a0=1
PSGREG          .EQU    0C6H			; Primary SN76489
PSG2REG         .EQU    0C7H			; Secondary SN76489
YM2151_SEL1	.EQU	0FEH			; Primary YM2151 register selection
YM2151_DAT1	.EQU	0FFH			; Primary YM2151 register data
YM2151_SEL2	.EQU	0FEH			; Secondary YM2151 register selection
YM2151_DAT2	.EQU	0FFH			; Secondary YM2151 register data
FRAME_DLY       .EQU    10  			; Frame delay (~ 1/44100)
                .ENDIF
;
;------------------------------------------------------------------------------
; Your customer overrides can go in here i.e. ports 
;------------------------------------------------------------------------------
;
RSEL            .SET    09AH			; Primary AY-3-8910 Register selection
RDAT            .SET    09BH			; Primary AY-3-8910 Register data
;
;------------------------------------------------------------------------------
; Frame delay overide values for different processor speeds. 
;------------------------------------------------------------------------------
;
;FRAME_DLY       .SET    10  			; 1Mhz	; not 
;FRAME_DLY       .SET    10  			; 2Mhz	; implemented
;FRAME_DLY       .SET    10  			; 4Mhz	; yet
;FRAME_DLY       .SET    15  			; 8Mhz
;FRAME_DLY       .SET    10  			; 10Mhz
;FRAME_DLY       .SET    20  			; 12Mhz
;
;------------------------------------------------------------------------------
; Frame delay values for pal/ntsc
;------------------------------------------------------------------------------
;
D60		.EQU	735
D50		.EQU	882
;
;------------------------------------------------------------------------------
; Processor speed control for SBCV2004+
;------------------------------------------------------------------------------
;
;#DEFINE 	SBCV2004			; My SBC board at 12Mhz needs this to switch to
HB_RTCVAL	.EQU	0FFEEH			; 6MHz for it to work with the ECB-VGM reliably.
RTCIO		.EQU	070H						

;------------------------------------------------------------------------------
; YM2162 Register write macros
;------------------------------------------------------------------------------
;
#DEFINE	setreg(reg,val) \
#DEFCONT \	ld	a,reg 
#DEFCONT \	out	(YMSEL),a 
#DEFCONT \	ld	a,val 
#DEFCONT \	out	(YMDAT),a 
#DEFCONT \	in	a,(YMSEL)
#DEFCONT \	rlca
#DEFCONT \	jp	c,$-3
;
#DEFINE	setreg2(reg,val) \
#DEFCONT \	ld	a,reg 
#DEFCONT \	out	(YM2SEL),a 
#DEFCONT \	ld	a,val 
#DEFCONT \	out	(YM2DAT),a
#DEFCONT \	in	a,(YMSEL)
#DEFCONT \	rlca
#DEFCONT \	jp	c,$-3 

;------------------------------------------------------------------------------
; VGM Codes
;------------------------------------------------------------------------------

VGM_GG_W	.EQU	04FH			; GAME GEAR PSG STEREO. WRITE DD TO PORT 0X06
VGM_PSG1_W	.EQU	050H			; PSG (SN76489/SN76496) #1 WRITE VALUE DD
VGM_PSG2_W	.EQU	030H			; PSG (SN76489/SN76496) #2 WRITE VALUE DD
VGM_YM26121_W	.EQU	052H			; YM2612 #1 WRITE VALUE DD
VGM_YM26122_W	.EQU	053H			; YM2612 #2 WRITE VALUE DD
VGM_WNS		.EQU	061H			; WAIT N SAMPLES
VGM_W735	.EQU	062H			; WAIT 735 SAMPLES (1/60TH SECOND)
VGM_W882	.EQU	063H			; WAIT 882 SAMPLES (1/50TH SECOND)
VGM_ESD		.EQU	066H			; END OF SOUND DATA
VGM_YM21511_W	.EQU	054H			; YM2612 #1 WRITE VALUE DD
VGM_YM21512_W	.EQU	0A4H			; YM2612 #2WRITE VALUE DD

;------------------------------------------------------------------------------
; Generic CP/M definitions
;------------------------------------------------------------------------------

BOOT            .EQU    0000H               	; boot location
BDOS            .EQU    0005H              	; bdos entry point
FCB             .EQU    005CH              	; file control block
FCBCR           .EQU    FCB + 20H          	; fcb current record
BUFF            .EQU    0080H              	; DMA buffer
TOPM		.EQU	0002H			; Top of memory
	
PRINTF          .EQU    9                  	; BDOS print string function
OPENF           .EQU    15                 	; BDOS open file function
CLOSEF          .EQU    16                 	; BDOS close file function
READF           .EQU    20                 	; BDOS sequential read function
	
CR              .EQU    0DH                	; carriage return
LF              .EQU    0AH                	; line feed

;------------------------------------------------------------------------------
; Program Start
;------------------------------------------------------------------------------

                .ORG    100H

                LD      (OLDSTACK),SP		; save old stack pointer
                LD      SP,STACK		; set new stack pointer

		LD	DE,MSG_WELC		; Welcome Message
		CALL	PRTSTR

		CALL	READVGM			; Read in the VGM file

		CALL	VGMINFO			; Check and display VGM Information

		LD      HL, (VGMDATA + 34H) 	; Determine start of VGM
                LD      A, H			; data.
                OR      L
                JR      NZ, _S1
                LD      HL, 000CH          	; Default location (40H - 34H)
_S1             LD      DE, VGMDATA + 34H
                ADD     HL, DE
                LD      (VGMPOS), HL

                LD      HL,D60             	; VGM delay (60hz)
                LD      (VGMDLY), HL

MAINLOOP	CALL    PLAY                	; Play one frame

                LD      C,6			; Check for keypress
                LD      E,0FFH
                CALL    BDOS
                OR      A
                JR      NZ,EXIT

                LD      HL,(VGMDLY)        	; Frame delay
L1              LD      B,FRAME_DLY
                DJNZ    $
                DEC     HL
                LD      A,H
                OR      L
                JR      NZ,L1

                JR      MAINLOOP
;
;------------------------------------------------------------------------------
; Program Exit
;------------------------------------------------------------------------------
;
EXIT:		CALL	VGMDEVICES		; Display devices used
		CALL	VGMMUTE			; Mute Devices
		
#IFDEF SBCV2004
		CALL	FASTIO
#ENDIF
		LD	DE,MSG_EXIT		
EXIT_ERR:	CALL	PRTSTR			; Generic message or error
                LD      SP, (OLDSTACK)		; Exit to CP/M
                RST     00H
;
;------------------------------------------------------------------------------
; Read VGM file into memory
;------------------------------------------------------------------------------
;
READVGM:	LD	A,(FCB+1)		; Get first char of filename
		CP	' '			; Compare to blank
		LD	DE,MSG_NOFILE		; If blank, missing filename
		JP	Z,EXIT_ERR		; so exit
		LD	A,(FCB+9)		; If the filetype
		CP	' '			; is blanks
		JR	NZ,HASEXT		; then assume
		LD	A,'V'			; type VGM.
		LD	(FCB+9),A
		LD	A,'G'			; Fill in
		LD	(FCB+10),A		; the file
		LD	A,'M'			; extension
		LD	(FCB+11),A

HASEXT:         LD      C,OPENF			; Open File
                LD      DE,FCB
                CALL    BDOS
                INC     A
		LD	DE,MSG_NOFILE
                JP      Z,EXIT_ERR

                XOR     A			; Read VGM file into memory
                LD      (FCBCR), A
                LD      DE, VGMDATA
                LD      (VGMPOS), DE
RLOOP 
;		LD	A,(TOPM)		; CBIOS start
;		SUB	10h			; Less BDOS = Top Memory Page
		LD	A,$D6			; Hardcoded top of memory
		CP	D		
		LD	DE,MSG_MEM
		JP	Z,EXIT_ERR		; Exit top of memory reached
		LD      C, READF
                LD      DE, FCB
                CALL    BDOS
                OR      A
                JR      NZ, RDONE
                LD      HL, BUFF
                LD      DE, (VGMPOS)
                LD      BC, 128
                LDIR
                LD      (VGMPOS), DE
                JR      RLOOP

RDONE           LD      C, CLOSEF		; Close the file
                LD      DE, FCB
                CALL    BDOS
		RET
;
;------------------------------------------------------------------------------
; Display VGM information.
;------------------------------------------------------------------------------
;
VGMINFO:	LD	DE,MSG_BADF		; Check valid file
		LD	HL,VGMDATA
		LD	A,(HL)
		CP	'V'
		JP	NZ,EXIT_ERR
		INC	HL
		LD	A,(HL)
		CP	'g'
		JP	NZ,EXIT_ERR
		INC	HL
		LD	A,(HL)
		CP	'm'
		JP	NZ,EXIT_ERR
		INC	HL
		LD	A,(HL)
		CP	' '
		JP	NZ,EXIT_ERR

		LD	HL,VGMDATA+08H		; Get version in DE:HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		LD	B,(HL)
		INC	HL
		LD	C,(HL)
		EX	DE,HL
		PUSH	BC
		POP	DE
;		CALL	PRTHEX32		; Debug

		LD	HL,(VGMDATA+16H)	; Is GD3 in range?
		LD	A,H
		OR	L
		JR	NZ,SKIP_GD3

		LD	HL,(VGMDATA+14H)	; Is there a GD3 header
		LD	DE,VGMDATA+14H
		ADD	HL,DE
		LD	A,(HL)
		CP	'G'
		JR	NZ,SKIP_GD3
		INC	HL
		LD	A,(HL)
		CP	'd'
		JR	NZ,SKIP_GD3
		INC	HL
		LD	A,(HL)
		CP	'3'
		JR	NZ,SKIP_GD3
		INC	HL
		LD	A,(HL)
		CP	' '
		JR	NZ,SKIP_GD3

		LD	DE,0009H		; Skip version and size
		ADD	HL,DE

		CALL	CRLF
		LD	DE,MSG_TRACK
		CALL	PRTSTR

GD3_NXT:	LD	A,(HL)			; Print English Track
		OR	A
		INC	HL
		INC	HL
		JR	Z,GD3_NXT1
		CALL	PRTCHR
		JR	GD3_NXT

GD3_NXT1:	LD	A,(HL)			; Skip Japanese Track
		OR	A
		INC	HL
		INC	HL
		JR	NZ,GD3_NXT1
;		JR	GD3_NXT1

		LD 	DE,MSG_TITLE
		CALL	PRTSTR

GD3_NXT2:	LD	A,(HL)			; Print English Title
		OR	A
		INC	HL
		INC	HL
		JR	Z,GD3_NXT3
		CALL	PRTCHR
		JR	GD3_NXT2

GD3_NXT3:	CALL	CRLF
SKIP_GD3:	RET
;
;------------------------------------------------------------------------------
; VGM Player.
;------------------------------------------------------------------------------
PLAY
#IFDEF SBCV2004
		CALL	SLOWIO
#ENDIF
		LD	IX,VGM_DEV
                LD      HL, (VGMPOS)		; Start processing VGM commands
NEXT            LD      A, (HL)
                INC     HL
                LD      (VGMPOS), HL
                CP      VGM_ESD			; Restart VGM cmd
                JR      NZ, NEXT1
                LD      HL, (VGMDATA + 1CH)	; Loop offset
                LD      A, H
                OR      L
                JP      Z, EXIT
                LD      DE, VGMDATA + 1CH
                ADD     HL, DE
                LD      (VGMPOS), HL
                JR      NEXT

NEXT1           CP      VGM_GG_W		; Game Gear SN76489 stereo. Ignored
                JR      NZ, PSG
		LD	IX,VGM_DEV
		SET	0,(IX+1)
		INC     HL
		JR      NEXT

;	SN76489 SECTION

PSG             CP      VGM_PSG1_W		; Write byte to SN76489.
                JR      NZ, PSG2
                LD      A, (HL)
		INC	HL
                OUT     (PSG1REG), A
		LD	IX,VGM_DEV
		SET	0,(IX+0)
                JR      NEXT

PSG2            CP      VGM_PSG2_W		; Write byte to second SN76489.
                JR      NZ, AY
                LD      A, (HL)
                INC     HL
                OUT     (PSG2REG), A
		LD	IX,VGM_DEV
		SET	1,(IX+0)
                JR      NEXT

;	AY-3-8910 SECTION

AY              CP      0A0H
		JR	NZ,YM2162_1
		LD      A, (HL)
                INC     HL
                BIT     7, A			; Bit 7=1 for second AY-3-8910
                JR      Z, AY1
                AND     7FH
                OUT     (RSEL2), A
                LD      A, (HL)
                INC     HL
                OUT     (RDAT2), A
		LD	IX,VGM_DEV
		SET	2,(IX+0)
                JR      NEXT
AY1		OUT     (RSEL), A
                LD      A, (HL)
                INC     HL
                OUT     (RDAT), A
		LD	IX,VGM_DEV
		SET	3,(IX+0)
                JR      NEXT

;	YM2612 SECTION

YM2162_1	CP      VGM_YM26121_W
                JR      NZ, YM2162_2
		LD	A,(HL)
		OUT	(YMSEL),A
		INC	HL
		LD	A,(HL)
		OUT	(YMDAT),A
		INC	HL
		LD	IX,VGM_DEV
		SET	4,(IX+0)
		JP	NEXT
;
YM2162_2	CP      VGM_YM26122_W
                JR      NZ,YM2151_1
		LD	A,(HL)
		OUT	(YM2SEL),A
		INC	HL
		LD	A,(HL)
		OUT	(YM2DAT),A
		INC	HL
		LD	IX,VGM_DEV
		SET	4,(IX+0)		; 2nd channel 
		JP	NEXT

;	YM2151 SECTION

YM2151_1	CP      VGM_YM21511_W
                JR      NZ,YM2151_2
		LD	A,(HL)
		OUT	(YM2151_SEL1),A
		INC	HL
		LD	A,(HL)
		OUT	(YM2151_DAT1),A
		INC	HL
		LD	IX,VGM_DEV
		SET	6,(IX+0)
		JP	NEXT
;
YM2151_2	CP      VGM_YM21512_W
                JR      NZ,WAITNN
		LD	A,(HL)
		OUT	(YM2151_SEL2),A
		INC	HL
		LD	A,(HL)
		OUT	(YM2151_DAT2),A
		INC	HL
		LD	IX,VGM_DEV
		SET	7,(IX+0)
		JP	NEXT
;	
WAITNN		CP      VGM_WNS			; Wait nn samples
                JR      NZ, WAIT60
                LD      A, (HL)
                INC     HL
                LD      D, (HL)
                INC     HL
                LD      (VGMPOS), HL
                LD      L, A
                LD      H, D
                LD      (VGMDLY), HL
                RET
;
WAIT60          CP      VGM_W735		; Wait 735 samples (60Hz)
                JR      NZ, WAIT50
                LD      (VGMPOS), HL
                LD      HL, D60
                LD      (VGMDLY), HL
                RET
;
WAIT50          CP      VGM_W882		; Wait 882 samples (50Hz)
                JR      NZ, WAIT1
                LD      (VGMPOS), HL
                LD      HL, D50
                LD      (VGMDLY), HL
                RET
;
WAIT1           CP      70H			; WAIT 0-15 SAMPLES
                JR      C, UNK			; CODES 70-7FH
                CP      80H
                JP      NC, UNK
                SUB     6FH
                LD      L, A
                LD      H, 0
                LD      (VGMDLY), HL
                RET
;
UNK		LD	IX,VGM_DEV		; Set flag for
		SET	0,(IX+1)		; unknown device
		INC	HL			; Try and skip
		JP	NEXT
;
;------------------------------------------------------------------------------
; Display VGM Devices detected during playback.
;------------------------------------------------------------------------------
;
VGMDEVICES:	LD	DE,MSG_PO		; Played on ...
		CALL	PRTSTR
;
		LD	A,(IX+0)
		PUSH	AF
;
		LD	DE,MSG_SN		; SN76489 Devices
		CALL	CHKDEV
;
		POP	AF
		SRL	A
		SRL	A
		PUSH	AF
;
		LD	DE,MSG_AY		; AY-3-8910 Devices
		CALL	CHKDEV
;
		POP	AF
		SRL	A
		SRL	A
		PUSH	AF
;
		LD	DE,MSG_YM2612		; YM-2612 Devices
		CALL	CHKDEV
;
		POP	AF
		SRL	A
		SRL	A
		PUSH	AF
;
		LD	DE,MSG_YM2151		; YM-2151 Devices
		CALL	CHKDEV
;
		POP	AF
;		SRL	A
;		SRL	A
;		PUSH	AF
;
		LD	A,(IX+1)
		LD	DE,MSG_UNK		; Unknown Device Code detected
;		CALL	CHKDEV
;
CHKDEV:		AND	%00000011		; Display 
		RET	Z			; number of
		SRL	A			; devices
		ADC	A,'0'
		CALL	PRTCHR			; Skip if not
		CALL	PRTSTR			; used.
		RET

DEBUG:		PUSH	AF
		LD	A,'*'
		CALL	PRTCHR
		POP	AF
		RET
;
;------------------------------------------------------------------------------
; Mute Devices.
;------------------------------------------------------------------------------
;
VGMMUTE:	LD	A,(IX+0)		; Only mute devices used.
		AND	%00000011
		JR	Z,SKIP1

		LD      A, 9FH              	; Mute all channels on psg
                OUT     (PSG1REG), A
                OUT     (PSG2REG), A
                LD      A, 0BFH
                OUT     (PSG1REG), A
                OUT     (PSG2REG), A
                LD      A, 0DFH
                OUT     (PSG1REG), A
                OUT     (PSG2REG), A
                LD      A, 0FFH
                OUT     (PSG1REG), A
                OUT     (PSG2REG), A

SKIP1:		LD	A,(IX+0)
		AND	%00001100
		JR	Z,SKIP2

		LD      A, 8                	; Mute all channels on ay
                OUT     (RSEL), A
                OUT     (RSEL2), A
                XOR     A
                OUT     (RDAT), A
                OUT     (RDAT2), A
                LD      A, 9
                OUT     (RSEL), A
                OUT     (RSEL2), A
                XOR     A
                OUT     (RDAT), A
                OUT     (RDAT2), A
                LD      A, 10
                OUT     (RSEL), A
                OUT     (RSEL2), A
                XOR     A
                OUT     (RDAT), A
                OUT     (RDAT2), A
		CALL	FASTIO

SKIP2:		LD	A,(IX+0)		; mute all channels on ym2612
		AND	%00110000
		JP	Z,SKIP3

		setreg($22,$00)			; lfo off

		setreg($27,$00)			; Disable independant Channel 3
		setreg($28,$00)			; note off ch 1
		setreg($28,$01)			; note off ch 2
		setreg($28,$02)			; note off ch 3
		setreg($28,$04)			; note off ch 4
		setreg($28,$05)			; note off ch 5
		setreg($28,$06)			; note off ch 6
		setreg($2b,$00)			; dac off

		setreg($b4,$00)			; sound off ch 1-3
		setreg($b5,$00)
		setreg($b6,$00)
		setreg2($b4,$00)		; sound off ch 4-6
		setreg2($b5,$00)
		setreg2($b6,$00)

		setreg($40,$7f)			; ch 1-3 total level minimum
		setreg($41,$7f)
		setreg($42,$7f)
		setreg($44,$7f)
		setreg($45,$7f)
		setreg($46,$7f)
		setreg($48,$7f)
		setreg($49,$7f)
		setreg($4a,$7f)
		setreg($4c,$7f)
		setreg($4d,$7f)
		setreg($4e,$7f)

		setreg2($40,$7f)		; ch 4-6 total level minimum
		setreg2($41,$7f)
		setreg2($42,$7f)
		setreg2($44,$7f)
		setreg2($45,$7f)
		setreg2($46,$7f)
		setreg2($48,$7f)
		setreg2($49,$7f)
		setreg2($4a,$7f)
		setreg2($4c,$7f)
		setreg2($4d,$7f)
		setreg2($4e,$7f)

#if (0)

		setreg($2a,$00)			; dac value

		setreg($24,$00)			; timer A frequency
		setreg($25,$00)			; timer A frequency
		setreg($26,$00)			; time B frequency

		setreg($30,$00)			; ch 1-3 multiply & detune
		setreg($31,$00)
		setreg($32,$00)
		setreg($34,$00)
		setreg($35,$00)
		setreg($36,$00)
		setreg($38,$00)
		setreg($39,$00)
		setreg($3a,$00)
		setreg($3c,$00)
		setreg($3d,$00)
		setreg($3e,$00)

		setreg2($30,$00)		; ch 4-6 multiply & detune
		setreg2($31,$00)
		setreg2($32,$00)
		setreg2($34,$00)
		setreg2($35,$00)
		setreg2($36,$00)
		setreg2($38,$00)
		setreg2($39,$00)
		setreg2($3a,$00)
		setreg2($3c,$00)
		setreg2($3d,$00)
		setreg2($3e,$00)

		setreg($50,$00)			; ch 1-3 attack rate and scaling
		setreg($51,$00)
		setreg($52,$00)
		setreg($54,$00)
		setreg($55,$00)
		setreg($56,$00)
		setreg($58,$00)
		setreg($59,$00)
		setreg($5a,$00)
		setreg($5c,$00)
		setreg($5d,$00)
		setreg($5e,$00)

		setreg2($50,$00)		; ch 4-6 attack rate and scaling
		setreg2($51,$00)
		setreg2($52,$00)
		setreg2($54,$00)
		setreg2($55,$00)
		setreg2($56,$00)
		setreg2($58,$00)
		setreg2($59,$00)
		setreg2($5a,$00)
		setreg2($5c,$00)
		setreg2($5d,$00)
		setreg2($5e,$00)

		setreg($60,$00)			; ch 1-3 decay rate and am enable
		setreg($61,$00)
		setreg($62,$00)
		setreg($64,$00)
		setreg($65,$00)
		setreg($66,$00)
		setreg($68,$00)
		setreg($69,$00)
		setreg($6a,$00)
		setreg($6c,$00)
		setreg($6d,$00)
		setreg($6e,$00)

		setreg2($60,$00)		; ch 4-6 decay rate and am enable
		setreg2($61,$00)
		setreg2($62,$00)
		setreg2($64,$00)
		setreg2($65,$00)
		setreg2($66,$00)
		setreg2($68,$00)
		setreg2($69,$00)
		setreg2($6a,$00)
		setreg2($6c,$00)
		setreg2($6d,$00)
		setreg2($6e,$00)

		setreg($70,$00)			; ch 1-3 sustain rate
		setreg($71,$00)
		setreg($72,$00)
		setreg($74,$00)
		setreg($75,$00)
		setreg($76,$00)
		setreg($78,$00)
		setreg($79,$00)
		setreg($7a,$00)
		setreg($7c,$00)
		setreg($7d,$00)
		setreg($7e,$00)

		setreg2($70,$00)		; ch 4-6 sustain rate
		setreg2($71,$00)
		setreg2($72,$00)
		setreg2($74,$00)
		setreg2($75,$00)
		setreg2($76,$00)
		setreg2($78,$00)
		setreg2($79,$00)
		setreg2($7a,$00)
		setreg2($7c,$00)
		setreg2($7d,$00)
		setreg2($7e,$00)

		setreg($80,$00)			; ch 1-3 release rate and sustain level
		setreg($81,$00)
		setreg($82,$00)
		setreg($84,$00)
		setreg($85,$00)
		setreg($86,$00)
		setreg($88,$00)
		setreg($89,$00)
		setreg($8a,$00)
		setreg($8c,$00)
		setreg($8d,$00)
		setreg($8e,$00)

		setreg2($80,$00)		; ch 4-6 release rate and sustain level
		setreg2($81,$00)
		setreg2($82,$00)
		setreg2($84,$00)
		setreg2($85,$00)
		setreg2($86,$00)
		setreg2($88,$00)
		setreg2($89,$00)
		setreg2($8a,$00)
		setreg2($8c,$00)
		setreg2($8d,$00)
		setreg2($8e,$00)

		setreg($90,$00)			; ch 1-3 ssg-eg
		setreg($91,$00)
		setreg($92,$00)
		setreg($94,$00)
		setreg($95,$00)
		setreg($96,$00)
		setreg($98,$00)
		setreg($99,$00)
		setreg($9a,$00)
		setreg($9c,$00)
		setreg($9d,$00)
		setreg($9e,$00)

		setreg2($90,$00)		; ch 4-6 ssg-eg
		setreg2($91,$00)
		setreg2($92,$00)
		setreg2($94,$00)
		setreg2($95,$00)
		setreg2($96,$00)
		setreg2($98,$00)
		setreg2($99,$00)
		setreg2($9a,$00)
		setreg2($9c,$00)
		setreg2($9d,$00)
		setreg2($9e,$00)

		setreg($a0,$00)			; ch 1-3 frequency
		setreg($a1,$00)
		setreg($a2,$00)
		setreg($a4,$00)
		setreg($a5,$00)
		setreg($a6,$00)
;		setreg($a8,$00)			; ch 3 special mode
;		setreg($a9,$00)
;		setreg($aa,$00)
;		setreg($ac,$00)
;		setreg($ad,$00)
;		setreg($ae,$00)

		setreg2($a0,$00)		; ch 4-6 frequency
		setreg2($a1,$00)
		setreg2($a2,$00)
		setreg2($a4,$00)
		setreg2($a5,$00)
		setreg2($a6,$00)
;		setreg2($a8,$00)		; ch 3 special mode
;		setreg2($a9,$00)
;		setreg2($aa,$00)
;		setreg2($ac,$00)
;		setreg2($ad,$00)
;		setreg2($ae,$00)

		setreg($b0,$00)			; ch 1-3 algorith + feedback
		setreg($b1,$00)
		setreg($b2,$00)
		setreg2($b0,$00)		; ch 4-6 algorith + feedback
		setreg2($b1,$00)
		setreg2($b2,$00)

#endif
		
SKIP3:		LD	A,(IX+0)		; For YM2151 ... Unimplemented
		AND	%11000000
		JP	Z,SKIP4

		; MUTE YM2151

SKIP4		RET
;
;------------------------------------------------------------------------------
; Hardware specific routines.
;------------------------------------------------------------------------------
;
SLOWIO:		
#IFDEF SBCV2004
	PUSH	AF
	LD	A,(HB_RTCVAL)
	OR	%00001000		; SBC-V2-004+ CHANGE
	OUT	(RTCIO),A		; TO HALF CLOCK SPEED
	POP	AF
#ENDIF
	RET
;
FASTIO:
#IFDEF SBCV2004
	LD	A,(HB_RTCVAL)
	AND	%11110111		; SBC-V2-004+ CHANGE TO
	OUT	(RTCIO),A		; NORMAL CLOCK SPEED
#ENDIF
		RET
;
;------------------------------------------------------------------------------
; External routines.
;------------------------------------------------------------------------------
;
#INCLUDE "printing.inc"
;
;------------------------------------------------------------------------------
; Strings and constants.
;------------------------------------------------------------------------------
;
MSG_WELC:	.DB	"VGM Player for RomWBW v0.3, 2-Jul-2022",CR,LF
;		.DB	"J.B. Langston/Marco Maccaferri/Phil Summers",CR,LF
		.DB	0
MSG_BADF:	.DB	"Not a VGM file",CR,LF,0
MSG_PO		.DB	"Played on : ",0
MSG_YM2612:	.DB	"xYM-2612 ",0
MSG_SN:		.DB	"xSN76489 ",0
MSG_AY:		.DB	"xAY-3-8910 ",0
MSG_YM2151:	.DB	"xYM-2151 ",0
MSG_UNK:	.DB	"xUnsupported device encountered", CR, LF, 0
MSG_EXIT:	.DB	"FINISHED.",CR,LF,0
MSG_NOFILE:     .DB	"File not found", CR, LF, 0
MSG_MEM:	.DB	"File to big", CR, LF, 0
MSG_TITLE:	.DB	" from: ",0
MSG_TRACK	.DB	"Playing: ",0
;
;------------------------------------------------------------------------------
; Variables
;------------------------------------------------------------------------------
;
VGMPOS          .DW     0
VGMDLY          .DW     0
VGMUNK_F	.DB	0		; Flag for unknown device
VGM_DEV		.DB	%00000000	; yyYYAASS
		.DB	%00000000	; Unimplemented device flags

OLDSTACK        .DW     0		; original stack pointer
                .DS     40H		; space for stack
STACK					; top of stack

;------------------------------------------------------------------------------
; VGM data
;------------------------------------------------------------------------------

VGMDATA
                .END
