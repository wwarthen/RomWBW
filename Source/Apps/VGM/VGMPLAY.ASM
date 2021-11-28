;------------------------------------------------------------------------------
; SN76489 + AY-3-8910 + YM2162 VGM player for CP/M
;------------------------------------------------------------------------------
;
; Based on VGM player by J.B. Langston
; https://github.com/jblang/SN76489
;
; Enhanced with multi-chip support by Marco Maccaferri
;
; YM2162/YM3484, GD3 support, VGM Chip identification, 
; default file type, basic file size checking added by Phil Summers
;
; Assemble with:
;
;   TASM -80 -b VGMPLAY.ASM VGMPLAY.COM
;
;------------------------------------------------------------------------------
; Device and system specific definitions
;------------------------------------------------------------------------------
;
P8X180          .EQU    0                   ; System configuration
RC2014          .EQU    0
SBCECB		.EQU	1

                .IF P8X180
RSEL            .EQU    82H                 ; Primary AY-3-8910 Register selection
RDAT            .EQU    83H                 ; Primary AY-3-8910 Register data
RSEL2           .EQU    88H                 ; Secondary AY-3-8910 Register selection
RDAT2           .EQU    89H                 ; Secondary AY-3-8910 Register data
PSGREG          .EQU    84H                 ; Primary SN76489
PSG2REG         .EQU    8AH                 ; Secondary SN76489
FRAME_DLY       .EQU    48                  ; Frame delay (~ 1/44100)
                .ENDIF

                .IF RC2014
RSEL            .EQU    0D8H                ; Primary AY-3-8910 Register selection
RDAT            .EQU    0D0H                ; Primary AY-3-8910 Register data
RSEL2           .EQU    0A0H                ; Secondary AY-3-8910 Register selection
RDAT2           .EQU    0A1H                ; Secondary AY-3-8910 Register data
PSGREG          .EQU    0FFH                ; Primary SN76489
PSG2REG         .EQU    0FBH                ; Secondary SN76489
FRAME_DLY       .EQU    15                  ; Frame delay (~ 1/44100)
                .ENDIF

                .IF SBCECB
RSEL            .EQU    0D8H			; Primary AY-3-8910 Register selection
RDAT            .EQU    0D0H			; Primary AY-3-8910 Register data
RSEL2           .EQU    0A0H			; Secondary AY-3-8910 Register selection
RDAT2           .EQU    0A1H			; Secondary AY-3-8910 Register data
YMSEL		.EQU	0C0H			; 11000000 a1=0 a0=0
YMDAT		.EQU	0C1H			; 11000001 a1=0 a0=1
YM2SEL		.EQU	0C2H			; 11000010 a1=1 a0=0
YM2DAT		.EQU	0C3H			; 11000011 a1=1 a0=1
PSGREG          .EQU    0C6H			; Primary SN76489
PSG2REG         .EQU    0C7H			; Secondary SN76489
FRAME_DLY       .EQU    10  			; Frame delay (~ 1/44100)

#DEFINE SBCV2004
HB_RTCVAL	.EQU	0FFEEH	
RTCIO		.EQU	070H

                .ENDIF


#DEFINE	setreg(reg,val) \
#DEFCONT \	ld	a,reg 
#DEFCONT \	out	(YMSEL),a 
#DEFCONT \	nop
#DEFCONT \	nop
#DEFCONT \	ld	a,val 
#DEFCONT \	out	(YMDAT),a 

D50		.EQU	500			; 900			;735
D60		.EQU	600			; 1000			;882

;------------------------------------------------------------------------------
; VGM Codes
;------------------------------------------------------------------------------

VGM_GG_W	.EQU	04FH			; GAME GEAR PSG STEREO. WRITE DD TO PORT 0X06
VGM_PSG_W	.EQU	050H			; PSG (SN76489/SN76496) WRITE VALUE DD
VGM_YM2612_W	.EQU	052H			; YM2612 WRITE VALUE DD
VGM_WNS		.EQU	061H			; WAIT N SAMPLES
VGM_W735	.EQU	062H			; WAIT 735 SAMPLES (1/60TH SECOND)
VGM_W882	.EQU	063H			; WAIT 882 SAMPLES (1/50TH SECOND)
VGM_ESD		.EQU	066H			; END OF SOUND DATA

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
EOS             .EQU    '$'                	; end of string marker

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
EXIT
#IFDEF SBCV2004
		CALL	FASTIO
#ENDIF
		CALL	VGMDEVICES		; Display devices used
		CALL	VGMMUTE			; Mute Devices
		
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
;		CALL	PRTHEX32

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

		CALL	CRLF
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
		SET	6,(IX+0)
                INC     HL
                JR      NEXT

PSG             CP      VGM_PSG_W		; Write byte to SN76489.
                JR      NZ, PSG2
                LD      A, (HL)
		INC	HL
                OUT     (PSGREG), A
		LD	IX,VGM_DEV
		SET	0,(IX+0)
                JR      NEXT

PSG2            CP      30H			; Write byte to second SN76489.
                JR      NZ, AY
                LD      A, (HL)
                INC     HL
                OUT     (PSG2REG), A
		LD	IX,VGM_DEV
		SET	1,(IX+0)
                JR      NEXT

;	AY SECTION

AY              CP      0A0H
		JR	NZ,YM
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

;	YM SECTION

YM:		CP      052H
                JR      NZ, YM2

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
YM2:		CP      053H
                JR      NZ,WAITNN

		LD	A,(HL)
		OUT	(YM2SEL),A
		INC	HL
		LD	A,(HL)
		OUT	(YM2DAT),A
		INC	HL
		LD	IX,VGM_DEV
		SET	4,(IX+0)
		JP	NEXT
;	
WAITNN:         CP      61H			; Wait nn samples
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
                LD      HL, D50
                LD      (VGMDLY), HL
                RET
;
WAIT50          CP      VGM_W882		; Wait 882 samples (50Hz)
                JR      NZ, WAIT1
                LD      (VGMPOS), HL
                LD      HL, D60
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
UNK:		LD	IX,VGM_DEV		; Set flag for
		SET	6,(IX+0)		; unknown device
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
		LD	DE,MSG_YM		; YM-2612 Devices
		CALL	CHKDEV
;
		POP	AF
		SRL	A
		SRL	A
;		PUSH	AF
;
		LD	DE,MSG_UNK		; Unknown Device Code detected
;		CALL	CHKDEV
;
CHKDEV:		AND	%00000011		; Display 
		SRL	A			; number of
		ADC	A,'0'			; devices
		CP	'0'
		RET	Z			; Skip if not
		CALL	PRTCHR			; used.
		CALL	PRTSTR
		RET
;
;------------------------------------------------------------------------------
; Mute Devices.
;------------------------------------------------------------------------------
;
VGMMUTE:	LD      A, 9FH              	; Mute all channels on psg
                OUT     (PSGREG), A
                OUT     (PSG2REG), A
                LD      A, 0BFH
                OUT     (PSGREG), A
                OUT     (PSG2REG), A
                LD      A, 0DFH
                OUT     (PSGREG), A
                OUT     (PSG2REG), A
                LD      A, 0FFH
                OUT     (PSGREG), A
                OUT     (PSG2REG), A

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

		setreg($22,$00)			; lfo off
		setreg($27,$00)			; note off ch 0
		setreg($28,$01)			; note off ch 1
		setreg($28,$02)			; note off ch 2
		setreg($28,$03)			; note off ch 3
		setreg($28,$04)			; note off ch 4
		setreg($28,$05)			; note off ch 5
		setreg($28,$06)			; note off ch 6
		setreg($28,$01)			; note off ch 1
		setreg($2b,$00)			; dac off
		setreg($28,$00)			; key off
;
		RET
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
MSG_WELC:	.DB	"VGM Player for RomWBW v0.2, 27-Nov-2021",CR,LF
;		.DB	"J.B. Langston/Marco Maccaferri/Phil Summers",CR,LF
		.DB	0
MSG_BADF:	.DB	"Not a VGM file",CR,LF,0
MSG_PO		.DB	"Played on : ",0
MSG_YM:		.DB	"xYM-2612 ",0
MSG_SN:		.DB	"xSN76489 ",0
MSG_AY:		.DB	"xAY-3-8910 ",0
MSG_UNK		.DB	"xUnsupported device encountered", CR, LF, 0
MSG_EXIT:	.DB	"FINISHED.",CR,LF,0
MSG_NOFILE:     .DB	"File not found", CR, LF, 0
MSG_MEM:	.DB	"File to big", CR, LF, 0
;
;------------------------------------------------------------------------------
; Variables
;------------------------------------------------------------------------------
;
VGMPOS          .DW     0
VGMDLY          .DW     0
VGMUNK_F	.DB	0		; Flag for unknown device
VGM_DEV		.DB	%00000000	; 000YAASS

OLDSTACK        .DW     0		; original stack pointer
                .DS     40H		; space for stack
STACK					; top of stack

;------------------------------------------------------------------------------
; VGM data
;------------------------------------------------------------------------------

VGMDATA
                .END
