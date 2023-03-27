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
; default file type, basic file size checking, polled CTC mode
; added by Phil Summers
;
; Bugs: CTC polled timing - predicted 44100 divider is too slow
;
; Assemble with:
;
;   TASM -80 -b VGMPLAY.ASM VGMPLAY.COM
;
; A VGM file can play 44100 samples a second. This may be sound chip
; register commands or PCM data. This player does not support PCM playback
; due to the high processor speed and file size required. Typical VGM files
; available use a much lower sample rate and are playable. Where the processor
; speed is low and the sample rate is high, the playback overhead will cause
; playback speed to be inaccurate. 

;------------------------------------------------------------------------------
; Device and system specific definitions
;------------------------------------------------------------------------------
;
custom		.equ	0           	; System configurations
P8X180          .equ    1
RCBUS           .equ    2
sbcecb		.equ	3		
MBC		.equ	4
;
plt_romwbw	.equ	1		; Build for ROMWBW?
plt_type	.equ	sbcecb		; Select build configuration
debug		.equ	0		; Display port, register, config info
;
;------------------------------------------------------------------------------
; Platform specific definitions. If building for ROMWBW, these may be overridden
;------------------------------------------------------------------------------

#IF (plt_type=custom)
RSEL            .equ    09AH		; Primary AY-3-8910 Register selection
RDAT            .equ    09BH		; Primary AY-3-8910 Register data
RSEL2           .equ    88H		; Secondary AY-3-8910 Register selection
RDAT2           .equ    89H		; Secondary AY-3-8910 Register data
VGMBASE		.equ	$C0
YMSEL		.equ	VGMBASE+00H	; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	VGMBASE+01H	; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	VGMBASE+02H	; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	VGMBASE+03H	; Secondary YM2162 11000011 a1=1 a0=1
PSG1REG         .equ    VGMBASE+04H	; Primary SN76489
PSG2REG         .equ    VGMBASE+05H	; Secondary SN76489
YM2151_SEL1	.equ	VGMBASE+08H	; Primary YM2151 register selection
YM2151_DAT1	.equ	VGMBASE+09H	; Primary YM2151 register data
YM2151_SEL2	.equ	VGMBASE+0AH	; Secondary YM2151 register selection
YM2151_DAT2	.equ	VGMBASE+0BH	; Secondary YM2151 register data
ctcbase		.equ	VGMBASE+0CH	; CTC base address
plt_cpuspd	.equ	6;000000	; Non ROMWBW cpu speed default
FRAME_DLY       .equ    10  		; Frame delay (~ 1/44100)
#ENDIF
;
#IF (plt_type=P8X180)
RSEL            .equ    82H		; Primary AY-3-8910 Register selection
RDAT            .equ    83H		; Primary AY-3-8910 Register data
RSEL2           .equ    88H		; Secondary AY-3-8910 Register selection
RDAT2           .equ    89H		; Secondary AY-3-8910 Register data
PSG1REG         .equ    84H		; Primary SN76489
PSG2REG         .equ    8AH		; Secondary SN76489
YM2151_SEL1	.equ	0B0H		; Primary YM2151 register selection
YM2151_DAT1	.equ	0B1H		; Primary YM2151 register data
YM2151_SEL2	.equ	0B2H		; Secondary YM2151 register selection
YM2151_DAT2	.equ	0B3H		; Secondary YM2151 register data
ctcbase		.equ	000H		; CTC base address
YMSEL		.equ	000H		; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	000H		; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	000H		; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	000H		; Secondary YM2162 11000011 a1=1 a0=1
FRAME_DLY       .equ    48		; Frame delay (~ 1/44100)
plt_cpuspd	.equ	20		; Non ROMWBW cpu speed default
#ENDIF
;
#IF (plt_type=RCBUS)
RSEL            .equ    0D8H		; AYMODE_RCZ80	; Primary AY-3-8910 Register selection
RDAT            .equ    0D0H		; AYMODE_RCZ80	; Primary AY-3-8910 Register data
RSEL2           .equ    000H		; UNDEFINED	; Secondary AY-3-8910 Register selection
RDAT2           .equ    000H		; UNDEFINED	; Secondary AY-3-8910 Register data
PSG1REG         .equ    0FFH		; SNMODE_RC   !	; Primary SN76489
PSG2REG         .equ    0FBH		; SNMODE_RC	; Secondary SN76489
YM2151_SEL1	.equ	0FEH		; ED BRINDLEY	; Primary YM2151 register selection
YM2151_DAT1	.equ	0FFH		; ED BRINDLEY !	; Primary YM2151 register data
YM2151_SEL2	.equ	000H		; UNDEFINED	; Secondary YM2151 register selection
YM2151_DAT2	.equ	000H		; UNDEFINED	; Secondary YM2151 register data
ctcbase		.equ	000H		; UNDEFINED	; CTC base address
YMSEL		.equ	000H		; UNDEFINED	; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	000H		; UNDEFINED	; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	000H		; UNDEFINED	; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	000H		; UNDEFINED	; Secondary YM2162 11000011 a1=1 a0=1
plt_cpuspd	.equ	7;372800	; CPUOSC	; Non ROMWBW cpu speed default
FRAME_DLY       .equ    12				; Frame delay (~ 1/44100)
#ENDIF
;
#IF (plt_type=sbcecb)
RSEL            .equ    09AH		; AYMODE_SCG	; Primary AY-3-8910 Register selection
RDAT            .equ	09BH		; AYMODE_SCG	; Primary AY-3-8910 Register data
RSEL2           .equ    000H		; UNDEFINED	; Secondary AY-3-8910 Register selection
RDAT2           .equ    000H		; UNDEFINED	; Secondary AY-3-8910 Register data
VGMBASE		.equ	$C0				; ECB-VGM V2 base address
YMSEL		.equ	VGMBASE+00H			; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	VGMBASE+01H			; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	VGMBASE+02H			; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	VGMBASE+03H			; Secondary YM2162 11000011 a1=1 a0=1
PSG1REG         .equ    VGMBASE+06H	; SNMODE_VGM	; Primary SN76489
PSG2REG         .equ    VGMBASE+07H	; SNMODE_VGM	; Secondary SN76489
ctcbase		.equ	VGMBASE+0CH			; CTC base address
YM2151_SEL1	.equ	000H		; UNDEFINED	; Primary YM2151 register selection
YM2151_DAT1	.equ	000H		; UNDEFINED	; Primary YM2151 register data
YM2151_SEL2	.equ	000H		; UNDEFINED	; Secondary YM2151 register selection
YM2151_DAT2	.equ	000H		; UNDEFINED	; Secondary YM2151 register data
plt_cpuspd	.equ	8;000000	; CPUOSC	; Non ROMWBW cpu speed default
FRAME_DLY       .equ    13  				; Frame delay (~ 1/44100)
#ENDIF
;
#IF (plt_type=MBC)
RSEL            .equ    0A0H		; AYMODE_MBC	; Primary AY-3-8910 Register selection
RDAT            .equ    0A1H		; AYMODE_MBC	; Primary AY-3-8910 Register data
RSEL2           .equ    000H		; UNDEFINED	; Secondary AY-3-8910 Register selection
RDAT2           .equ    000H		; UNDEFINED	; Secondary AY-3-8910 Register data
YMSEL		.equ	000H		; UNDEFINED	; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	000H		; UNDEFINED	; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	000H		; UNDEFINED	; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	000H		; UNDEFINED	; Secondary YM2162 11000011 a1=1 a0=1
PSG1REG         .equ    000H		; UNDEFINED	; Primary SN76489
PSG2REG         .equ    000H		; UNDEFINED	; Secondary SN76489
ctcbase		.equ	000H		; UNDEFINED	; CTC base address
YM2151_SEL1	.equ	000H		; UNDEFINED	; Primary YM2151 register selection
YM2151_DAT1	.equ	000H		; UNDEFINED	; Primary YM2151 register data
YM2151_SEL2	.equ	000H		; UNDEFINED	; Secondary YM2151 register selection
YM2151_DAT2	.equ	000H		; UNDEFINED	; Secondary YM2151 register data
plt_cpuspd	.equ	8;000000	; CPUOSC	; Non ROMWBW cpu speed default
FRAME_DLY       .equ    13  		; UNDEFINED	; Frame delay (~ 1/44100)

#ENDIF
;
;------------------------------------------------------------------------------
; Configure timing loop 
;------------------------------------------------------------------------------
;
cpu_loop:	.equ	0
ctc_poll:	.equ	1
ctc_int:	.equ	2			; not implemented
;
delay_type:	.equ	cpu_loop		; cpu timed loop or utilize ctc
delay_wait	.equ	0			; funny wait mode for ctc
;
D60		.equ	735			; 735x60=44100 Frame delay values for ntsc
D50		.equ	882			; 882x50=44100 Frame delay values for pal
;
;------------------------------------------------------------------------------
; CTC Defaults 
;------------------------------------------------------------------------------
;
ctcdiv0		 .equ 	1			; Divider chain for 3.579545MHz input
ctcdiv1		 .equ 	1			; Ctc with 3 step divider base address
ctcdiv2		 .equ 	16
ctcdiv3		 .equ 	3			; 3579545 / 1 / 2 / 41 = 43653 = 1% error
;
;------------------------------------------------------------------------------
; Processor speed control for SBCV2004+
;------------------------------------------------------------------------------
;
;#DEFINE 	SBCV2004			; My SBC board at 12Mhz needs this to switch to
HB_RTCVAL	.equ	0FFEEH			; 6MHz for it to work with the ECB-VGM reliably.
RTCIO		.equ	070H						
;
;------------------------------------------------------------------------------
; YM2162 Register write macros - with wait and timeout
;------------------------------------------------------------------------------
;
#DEFINE	s2612reg(reg,val) \
#DEFCONT \	ld	a,reg 
#DEFCONT \	out	(YMSEL),a 
#DEFCONT \	ld	a,val 
#DEFCONT \	out	(YMDAT),a 
#DEFCONT \	ld	b,0
#DEFCONT \	in	a,(YMSEL)
#DEFCONT \	rlca
#DEFCONT \	jp	nc,$+5
#DEFCONT \	djnz	$-6
;
#DEFINE	s2612reg2(reg,val) \
#DEFCONT \	ld	a,reg 
#DEFCONT \	out	(YM2SEL),a 
#DEFCONT \	ld	a,val 
#DEFCONT \	out	(YM2DAT),a
#DEFCONT \	ld	b,0
#DEFCONT \	in	a,(YMSEL)
#DEFCONT \	rlca
#DEFCONT \	jp	nc,$+5
#DEFCONT \	djnz	$-6
;
;------------------------------------------------------------------------------
; YM2151 Register write macros - with wait and timeout
;------------------------------------------------------------------------------
;
; Status Byte: 	Bit
;		7       Busy Flag (1=Busy)
;		6-2     Not Used
;		1       Timer B Overflow (0=No Overflow, 1=Overflow)
;		0       Timer A Overflow (0=No Overflow, 1=Overflow)
;
#DEFINE	s2151reg(reg,val) \
#DEFCONT \	ld	a,reg 
#DEFCONT \	out	(YM2151_SEL1),a 
#DEFCONT \	ld	a,val 
#DEFCONT \	out	(YM2151_DAT1),a 
#DEFCONT \	ld	b,0
#DEFCONT \	in	a,(YM2151_SEL1)
#DEFCONT \	rlca
#DEFCONT \	jp	nc,$+5
#DEFCONT \	djnz	$-6
;
;------------------------------------------------------------------------------
; VGM Codes - see vgmrips.net/wiki/VGM_Specification
;------------------------------------------------------------------------------

VGM_GG_W	.equ	04FH			; GAME GEAR PSG STEREO. WRITE DD TO PORT 0X06
VGM_PSG1_W	.equ	050H			; PSG (SN76489/SN76496) #1 WRITE VALUE DD
VGM_PSG2_W	.equ	030H			; PSG (SN76489/SN76496) #2 WRITE VALUE DD
VGM_YM26121_W	.equ	052H			; YM2612 #1 WRITE VALUE DD
VGM_YM26122_W	.equ	053H			; YM2612 #2 WRITE VALUE DD
VGM_WNS		.equ	061H			; WAIT N SAMPLES
VGM_W735	.equ	062H			; WAIT 735 SAMPLES (1/60TH SECOND)
VGM_W882	.equ	063H			; WAIT 882 SAMPLES (1/50TH SECOND)
VGM_ESD		.equ	066H			; END OF SOUND DATA
VGM_YM21511_W	.equ	054H			; YM2151 #1 WRITE VALUE DD
VGM_YM21512_W	.equ	0A4H			; YM2151 #2 WRITE VALUE DD

;------------------------------------------------------------------------------
; Generic CP/M definitions
;------------------------------------------------------------------------------

BOOT            .equ    0000H               	; boot location
BDOS            .equ    0005H              	; bdos entry point
FCB             .equ    005CH              	; file control block
FCBCR           .equ    FCB + 20H          	; fcb current record
BUFF            .equ    0080H              	; DMA buffer
TOPM		.equ	0002H			; Top of memory
	
PRINTF          .equ    9                  	; BDOS print string function
OPENF           .equ    15                 	; BDOS open file function
CLOSEF          .equ    16                 	; BDOS close file function
READF           .equ    20                 	; BDOS sequential read function
	
CR              .equ    0DH                	; carriage return
LF              .equ    0AH                	; line feed

;------------------------------------------------------------------------------
; Program Start
;------------------------------------------------------------------------------

                .ORG    100H
;
                LD      (OLDSTACK),SP		; save old stack pointer
                LD      SP,STACK		; set new stack pointer
;
		CALL	vgmsetup		; Device setup
		call	welcome			; Welcome message and build debug info
		call	vgmreadr		; read in the vgm file
;
;------------------------------------------------------------------------------
; Play loop
;------------------------------------------------------------------------------
;
MAINLOOP	CALL    PLAY                	; Play one frame
;
		LD	HL,KEYCHK		; Check for keypress
		DEC	(HL)
		JR	NZ,NO_CHK
;
                LD      C,6			; Every 256 commands
                LD      E,0FFH			; because HBIOS calls
                CALL    BDOS			; take a long time
                OR      A
                JR      NZ,EXIT
NO_CHK:
#IF (delay_type==cpu_loop)
vdelay:		.equ	$+1
		ld	hl,vdelay
fdelay:		.equ	$+1
lp1:		LD      B,FRAME_DLY		; 44100 one frame = 0.0000226757 seconds
		DJNZ    $
		DEC     HL
		LD      A,H
		OR      L
		JP      NZ,lp1			; Normally NZ so jp is faster
#ENDIF
;
#IF (delay_type==ctc_poll)
vdelay:		.equ	$+1
		ld	hl,vdelay        	; Frame delay
lp1:		in	a,(ctcch3)		; wait for counter to reach zero
		dec	a
		jr	nz,lp1
#IF (delay_wait)
lp2:		in	a,(ctcch3)		; wait for counter to pass zero
		dec	a
		jr	z,lp2

lp3:		in	a,(ctcch3)		; wait for counter to reach zero
		dec	a
		jr	nz,lp3
#ENDIF			
		DEC     HL
		LD      A,H
		OR      L
		JP      NZ,lp1			; Normally NZ so jp is faster
#ENDIF
;
#IF (delay_type==ctc_int)
#ENDIF
;
                JP      MAINLOOP
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
                JP	BOOT
;
;------------------------------------------------------------------------------
; Read VGM file
;------------------------------------------------------------------------------
;
vgmreadr:
		CALL	READVGM			; Read in the VGM file
		CALL	VGMINFO			; Check and display VGM Information
;
		LD      HL, (VGMDATA + 34H) 	; Determine start of VGM
                LD      A, H			; data.
                OR      L
                JR      NZ, _S1
                LD      HL, 000CH          	; Default location (40H - 34H)
_S1             LD      DE, VGMDATA + 34H
                ADD     HL, DE
                LD      (VGMPOS), HL
;
                LD      HL,D60             	; VGM delay (60hz)
		LD      (vdelay), HL
;
		LD	IX,VGM_DEV		; IX points to device mask
		ret
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
; VGM Player.
;------------------------------------------------------------------------------
PLAY
#IFDEF SBCV2004
		CALL	SLOWIO
#ENDIF
                LD      HL, (VGMPOS)		; Start processing VGM commands
NEXT            LD      A, (HL)
                INC     HL
                LD      (VGMPOS), HL
                CP      VGM_ESD			; Restart VGM cmd
                JR      NZ, NEXT1
                LD      HL, (VGMDATA + 1CH)	; Loop offset
                LD      A, H
                OR      L
		JP	Z, EXIT
                LD      DE, VGMDATA + 1CH
                ADD     HL, DE
                LD      (VGMPOS), HL
                JR      NEXT

NEXT1:
;
;	SN76489 SECTION

PSG             CP      VGM_PSG1_W		; Write byte to SN76489.
                JR      NZ, PSG2
                LD      A, (HL)
		INC	HL
                OUT     (PSG1REG), A
		SET	0,(IX+0)
                JR      NEXT

PSG2            CP      VGM_PSG2_W		; Write byte to second SN76489.
                JR      NZ, AY
                LD      A, (HL)
                INC     HL
                OUT     (PSG2REG), A
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
		SET	2,(IX+0)
                JR      NEXT
AY1		OUT     (RSEL), A
                LD      A, (HL)
                INC     HL
                OUT     (RDAT), A
		SET	3,(IX+0)
                JR      NEXT
;
;	YM2612 SECTION
;
YM2162_1	CP      VGM_YM26121_W
                JR      NZ, YM2162_2
		LD	A,(HL)
		OUT	(YMSEL),A
		INC	HL
		LD	A,(HL)
		OUT	(YMDAT),A
		INC	HL
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
		SET	4,(IX+0)		; 2nd channel 
		JP	NEXT
;
;	YM2151 SECTION
;
YM2151_1	CP      VGM_YM21511_W
		JR      NZ,YM2151_2
		LD	A,(HL)
		OUT	(YM2151_SEL1),A
		INC	HL
		LD	A,(HL)
		OUT	(YM2151_DAT1),A
		INC	HL
		SET	6,(IX+0)
		JP	NEXT
;
YM2151_2	CP      VGM_YM21512_W
                JR      NZ,GG
		LD	A,(HL)
		OUT	(YM2151_SEL2),A
		INC	HL
		LD	A,(HL)
		OUT	(YM2151_DAT2),A
		INC	HL
		SET	7,(IX+0)
		JP	NEXT
;
;	GAME GEAR SN76489 STEREO SECTION
;
GG:		CP      VGM_GG_W		; Stereo steering port value
		JR      NZ, WAITNN
;		SET	0,(IX+1)
		INC     HL
		JP      NEXT
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
                LD      (vdelay), HL
                RET
;
WAIT60          CP      VGM_W735		; Wait 735 samples (60Hz)
                JR      NZ, WAIT50
                LD      (VGMPOS), HL
                LD      HL, D60
                LD      (vdelay), HL
                RET
;
WAIT50:		CP      VGM_W882		; Wait 882 samples (50Hz)
		JR      NZ, WAIT1
		LD      (VGMPOS), HL
		LD      HL, D50
                LD      (vdelay), HL
                RET
;
WAIT1:          CP      70H			; WAIT 0-15 SAMPLES
                JR      C, UNK			; CODES 70-7FH
                CP      80H
                JP      NC, UNK
                SUB     6FH
                LD      L, A
                LD      H, 0
                LD      (vdelay), HL
                RET
;
UNK:		SET	0,(IX+1)		; unknown device
		INC	HL			; Try and skip
#IF (debug)
		ld	a,'u'			; Display unknow command
		call	PRTCHR
		call	PRTDOT
		call	PRTHEX
		ld	a,' '
		call	PRTCHR
#ENDIF
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
#IFDEF SBCV2004
		CALL	FASTIO
#ENDIF

SKIP2:		LD	A,(IX+0)		; mute all channels on ym2612
		AND	%00110000
		JP	Z,SKIP3

		s2612reg($22,$00)		; lfo off

		s2612reg($27,$00)		; Disable independant Channel 3
		s2612reg($28,$00)		; note off ch 1
		s2612reg($28,$01)		; note off ch 2
		s2612reg($28,$02)		; note off ch 3
		s2612reg($28,$04)		; note off ch 4
		s2612reg($28,$05)		; note off ch 5
		s2612reg($28,$06)		; note off ch 6
		s2612reg($2b,$00)		; dac off

		s2612reg($b4,$00)		; sound off ch 1-3
		s2612reg($b5,$00)
		s2612reg($b6,$00)
		s2612reg2($b4,$00)		; sound off ch 4-6
		s2612reg2($b5,$00)
		s2612reg2($b6,$00)

		s2612reg($40,$7f)		; ch 1-3 total level minimum
		s2612reg($41,$7f)
		s2612reg($42,$7f)
		s2612reg($44,$7f)
		s2612reg($45,$7f)
		s2612reg($46,$7f)
		s2612reg($48,$7f)
		s2612reg($49,$7f)
		s2612reg($4a,$7f)
		s2612reg($4c,$7f)
		s2612reg($4d,$7f)
		s2612reg($4e,$7f)

		s2612reg2($40,$7f)		; ch 4-6 total level minimum
		s2612reg2($41,$7f)
		s2612reg2($42,$7f)
		s2612reg2($44,$7f)
		s2612reg2($45,$7f)
		s2612reg2($46,$7f)
		s2612reg2($48,$7f)
		s2612reg2($49,$7f)
		s2612reg2($4a,$7f)
		s2612reg2($4c,$7f)
		s2612reg2($4d,$7f)
		s2612reg2($4e,$7f)

#if (0)

		s2612reg($2a,$00)		; dac value

		s2612reg($24,$00)		; timer A frequency
		s2612reg($25,$00)		; timer A frequency
		s2612reg($26,$00)		; time B frequency

		s2612reg($30,$00)		; ch 1-3 multiply & detune
		s2612reg($31,$00)
		s2612reg($32,$00)
		s2612reg($34,$00)
		s2612reg($35,$00)
		s2612reg($36,$00)
		s2612reg($38,$00)
		s2612reg($39,$00)
		s2612reg($3a,$00)
		s2612reg($3c,$00)
		s2612reg($3d,$00)
		s2612reg($3e,$00)

		s2612reg2($30,$00)		; ch 4-6 multiply & detune
		s2612reg2($31,$00)
		s2612reg2($32,$00)
		s2612reg2($34,$00)
		s2612reg2($35,$00)
		s2612reg2($36,$00)
		s2612reg2($38,$00)
		s2612reg2($39,$00)
		s2612reg2($3a,$00)
		s2612reg2($3c,$00)
		s2612reg2($3d,$00)
		s2612reg2($3e,$00)

		s2612reg($50,$00)		; ch 1-3 attack rate and scaling
		s2612reg($51,$00)
		s2612reg($52,$00)
		s2612reg($54,$00)
		s2612reg($55,$00)
		s2612reg($56,$00)
		s2612reg($58,$00)
		s2612reg($59,$00)
		s2612reg($5a,$00)
		s2612reg($5c,$00)
		s2612reg($5d,$00)
		s2612reg($5e,$00)

		s2612reg2($50,$00)		; ch 4-6 attack rate and scaling
		s2612reg2($51,$00)
		s2612reg2($52,$00)
		s2612reg2($54,$00)
		s2612reg2($55,$00)
		s2612reg2($56,$00)
		s2612reg2($58,$00)
		s2612reg2($59,$00)
		s2612reg2($5a,$00)
		s2612reg2($5c,$00)
		s2612reg2($5d,$00)
		s2612reg2($5e,$00)

		s2612reg($60,$00)		; ch 1-3 decay rate and am enable
		s2612reg($61,$00)
		s2612reg($62,$00)
		s2612reg($64,$00)
		s2612reg($65,$00)
		s2612reg($66,$00)
		s2612reg($68,$00)
		s2612reg($69,$00)
		s2612reg($6a,$00)
		s2612reg($6c,$00)
		s2612reg($6d,$00)
		s2612reg($6e,$00)

		s2612reg2($60,$00)		; ch 4-6 decay rate and am enable
		s2612reg2($61,$00)
		s2612reg2($62,$00)
		s2612reg2($64,$00)
		s2612reg2($65,$00)
		s2612reg2($66,$00)
		s2612reg2($68,$00)
		s2612reg2($69,$00)
		s2612reg2($6a,$00)
		s2612reg2($6c,$00)
		s2612reg2($6d,$00)
		s2612reg2($6e,$00)

		s2612reg($70,$00)		; ch 1-3 sustain rate
		s2612reg($71,$00)
		s2612reg($72,$00)
		s2612reg($74,$00)
		s2612reg($75,$00)
		s2612reg($76,$00)
		s2612reg($78,$00)
		s2612reg($79,$00)
		s2612reg($7a,$00)
		s2612reg($7c,$00)
		s2612reg($7d,$00)
		s2612reg($7e,$00)

		s2612reg2($70,$00)		; ch 4-6 sustain rate
		s2612reg2($71,$00)
		s2612reg2($72,$00)
		s2612reg2($74,$00)
		s2612reg2($75,$00)
		s2612reg2($76,$00)
		s2612reg2($78,$00)
		s2612reg2($79,$00)
		s2612reg2($7a,$00)
		s2612reg2($7c,$00)
		s2612reg2($7d,$00)
		s2612reg2($7e,$00)

		s2612reg($80,$00)		; ch 1-3 release rate and sustain level
		s2612reg($81,$00)
		s2612reg($82,$00)
		s2612reg($84,$00)
		s2612reg($85,$00)
		s2612reg($86,$00)
		s2612reg($88,$00)
		s2612reg($89,$00)
		s2612reg($8a,$00)
		s2612reg($8c,$00)
		s2612reg($8d,$00)
		s2612reg($8e,$00)

		s2612reg2($80,$00)		; ch 4-6 release rate and sustain level
		s2612reg2($81,$00)
		s2612reg2($82,$00)
		s2612reg2($84,$00)
		s2612reg2($85,$00)
		s2612reg2($86,$00)
		s2612reg2($88,$00)
		s2612reg2($89,$00)
		s2612reg2($8a,$00)
		s2612reg2($8c,$00)
		s2612reg2($8d,$00)
		s2612reg2($8e,$00)

		s2612reg($90,$00)		; ch 1-3 ssg-eg
		s2612reg($91,$00)
		s2612reg($92,$00)
		s2612reg($94,$00)
		s2612reg($95,$00)
		s2612reg($96,$00)
		s2612reg($98,$00)
		s2612reg($99,$00)
		s2612reg($9a,$00)
		s2612reg($9c,$00)
		s2612reg($9d,$00)
		s2612reg($9e,$00)

		s2612reg2($90,$00)		; ch 4-6 ssg-eg
		s2612reg2($91,$00)
		s2612reg2($92,$00)
		s2612reg2($94,$00)
		s2612reg2($95,$00)
		s2612reg2($96,$00)
		s2612reg2($98,$00)
		s2612reg2($99,$00)
		s2612reg2($9a,$00)
		s2612reg2($9c,$00)
		s2612reg2($9d,$00)
		s2612reg2($9e,$00)

		s2612reg($a0,$00)		; ch 1-3 frequency
		s2612reg($a1,$00)
		s2612reg($a2,$00)
		s2612reg($a4,$00)
		s2612reg($a5,$00)
		s2612reg($a6,$00)
;		s2612reg($a8,$00)		; ch 3 special mode
;		s2612reg($a9,$00)
;		s2612reg($aa,$00)
;		s2612reg($ac,$00)
;		s2612reg($ad,$00)
;		s2612reg($ae,$00)

		s2612reg2($a0,$00)		; ch 4-6 frequency
		s2612reg2($a1,$00)
		s2612reg2($a2,$00)
		s2612reg2($a4,$00)
		s2612reg2($a5,$00)
		s2612reg2($a6,$00)
;		s2612reg2($a8,$00)		; ch 3 special mode
;		s2612reg2($a9,$00)
;		s2612reg2($aa,$00)
;		s2612reg2($ac,$00)
;		s2612reg2($ad,$00)
;		s2612reg2($ae,$00)

		s2612reg($b0,$00)		; ch 1-3 algorith + feedback
		s2612reg($b1,$00)
		s2612reg($b2,$00)
		s2612reg2($b0,$00)		; ch 4-6 algorith + feedback
		s2612reg2($b1,$00)
		s2612reg2($b2,$00)

#endif
		
SKIP3:		LD	A,(IX+0)		; For YM2151 ... Unimplemented
		AND	%11000000
		JP	Z,SKIP4

		; MUTE YM2151

		s2151reg($14,$30)		; disable timer %00110000		

		s2151reg($0f,$00)		; disable noise
;
		s2151reg($1b,$00)		; CTx output off, LFO waveform

		s2151reg($08,$00)		; key off all channels
		s2151reg($08,$01)
		s2151reg($08,$02)
		s2151reg($08,$03)
		s2151reg($08,$04)
		s2151reg($08,$05)
		s2151reg($08,$06)
		s2151reg($08,$07)

		s2151reg($60,$7f)		; total level = silent
		s2151reg($61,$7f)
		s2151reg($62,$7f)
		s2151reg($63,$7f)
		s2151reg($64,$7f)
		s2151reg($65,$7f)
		s2151reg($66,$7f)
		s2151reg($67,$7f)
		s2151reg($68,$7f)
		s2151reg($69,$7f)
		s2151reg($6A,$7f)
		s2151reg($6B,$7f)
		s2151reg($6C,$7f)
		s2151reg($6D,$7f)
		s2151reg($6E,$7f)
		s2151reg($6F,$7f)
		s2151reg($70,$7f)
		s2151reg($71,$7f)
		s2151reg($72,$7f)
		s2151reg($73,$7f)
		s2151reg($74,$7f)
		s2151reg($75,$7f)
		s2151reg($76,$7f)
		s2151reg($77,$7f)
		s2151reg($78,$7f)
		s2151reg($79,$7f)
		s2151reg($7A,$7f)
		s2151reg($7B,$7f)
		s2151reg($7C,$7f)
		s2151reg($7D,$7f)
		s2151reg($7E,$7f)
		s2151reg($7F,$7f)

		s2151reg($20,$00)		; channel output off, no feedback
		s2151reg($21,$00)
		s2151reg($22,$00)
		s2151reg($23,$00)
		s2151reg($24,$00)
		s2151reg($25,$00)
		s2151reg($26,$00)
		s2151reg($27,$00)
;

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
; PRINT THE nTH STRING IN A LIST OF STRINGS WHERE EACH IS TERMINATED BY 0
; A REGISTER DEFINES THE nTH STRING IN THE LIST TO PRINT AND DE POINTS
; TO THE START OF THE STRING LIST.
;------------------------------------------------------------------------------
;
PRTIDXDEA:
	LD	C,A
	OR	A
PRTIDXDEA1:
	JR	Z,PRTIDXDEA3		; FOUND TARGET SO EXIT 
PRTIDXDEA2:
	LD	A,(DE)			; LOOP UNIT
	INC	DE			; WE REACH
	OR	A			; END OF STRING
	JR	NZ,PRTIDXDEA2
	DEC	C			; AT STRING END. SO GO
	JR	PRTIDXDEA1		; CHECK FOR INDEX MATCH
PRTIDXDEA3:
	CALL	PRTSTR			; DISPLAY THE STRING
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
MSG_WELC:	.DB	"VGM Player v0.4, 11-Dec-2022"
;		.DB	CR,LF, "J.B. Langston/Marco Maccaferri/Ed Brindley/Phil Summers",CR,LF
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
MSG_CPU		.DB	"[cpu]",0
MSG_CTCPOLL	.DB	"[ctc polled]",0
MSG_CTCINT	.DB	"[ctc interrupts]",0
MSG_ROMWBW	.DB	" [romwbw] ",0
MSG_CUSTOM	.DB	" [custom] ",0
MSG_P8X180	.DB	" [p8x180] ",0
MSG_RCBUS	.DB	" [RCBus] ",0
MSG_SBCECB	.DB	" [sbc] ",0
MSG_MBC		.DB	" [mbc] ",0
;
;------------------------------------------------------------------------------
; Variables
;------------------------------------------------------------------------------
;
VGMPOS          .DW     0
KEYCHK		.DB	0		; Counter for keypress checks
;
VGM_DEV		.DB	%00000000	; IX+0 Flags for devices
					; xx...... ym2151 1 & 2
					; ..x..... ym2612 2 (not supported)
					; ...x.... ym2612 1
					; ....xx.. ay-3-8910 1 & 2
					; ......xx sn76489 1 & 2

		.DB	%00000000	; IX+1 Unimplemented device flags & future devices
;
OLDSTACK        .DW     0		; original stack pointer
                .FILL	40H		; space for stack
STACK		.DW	0		; top of stack

;------------------------------------------------------------------------------
; VGM data gets loaded into TPA here
;------------------------------------------------------------------------------
;
VGMDATA:
;
;******************************************************************************
;*********** Initialization code that gets overwritten by VGMDATA *************
;******************************************************************************
;
vgmsetup:
#IF (plt_romwbw==1)
		CALL	cfgports		; Get and setup ports from HBIOS
#ENDIF
;
#IF (delay_type==cpu_loop)
		call	setfdelay		; Setup the frame delay based on cpu speed
#ENDIF
;
#IF (delay_type==ctc_poll)
		call	cfgctc_poll		; If building for polled ctc, initialize it
#ENDIF
;
#IF (delay_type==ctc_int)			; If building for interrupt driven ctc, initialize it
		call	cfgctc_int
#ENDIF
;
#IF (debug)
;		LD	A,0			; tone to validate presence
;TST:		LD	C,PSG1REG
;		OUT	(C),A
;		LD	C,PSG2REG
;		OUT	(C),A
;		JR	TST
#ENDIF
		ret
;
;------------------------------------------------------------------------------
; Welcome
;------------------------------------------------------------------------------
;
welcome:	LD	DE,MSG_WELC		; Welcome Message
		CALL	PRTSTR
;
#IF (plt_romwbw)
		LD	DE,MSG_ROMWBW		; display system type
		CALL	PRTSTR
#ENDIF
;
		LD	A,delay_type		; display build type
		LD	DE,MSG_CPU
		CALL	PRTIDXDEA
;
		LD	A,plt_type		; display system type
		LD	DE,MSG_CUSTOM
		CALL	PRTIDXDEA
		call	CRLF
;
#IF (debug)
#IF (delay_type==cpu_loop)
		ld	a,'f'			; Display frame rate delay
		call	PRTCHR
		call	PRTDOT
		ld	a,(fdelay)
		call	PRTDECB
		LD	A,' '
#ENDIF
		CALL	PRTCHR
		ld	a,'c'
		call	PRTCHR
		call	PRTDOT
		ld	a,ctcdiv0		; Display ctc divider values
		call	PRTDECB
		CALL	PRTDOT
		ld	a,ctcdiv1
		call	PRTDECB
		CALL	PRTDOT
		ld	a,ctcdiv2
		call	PRTDECB
		CALL	PRTDOT
		ld	a,ctcdiv3
		call	PRTDECB
;
#IF (delay_wait)
		ld	a,' '
		CALL	PRTCHR
		LD	A,'w'			; Display if using double wait
		CALL	PRTCHR
#ENDIF
#ENDIF
		CALL	CRLF
		ret
;
;------------------------------------------------------------------------------
; Probe HBIOS for devices and patch in I/O ports for devices
;------------------------------------------------------------------------------
;
cfgports:	ret
;
;------------------------------------------------------------------------------
; Setup frame delay value - Loop count for DJNZ $ loop
;------------------------------------------------------------------------------
;
setfdelay:
#IF (delay_type==cpu_loop)
#IF (plt_romwbw)
		LD	BC,$F8F0		; GET CPU SPEED
		RST	08			; FROM HBIOS
		LD	A,L			; 
#ELSE
		ld	a,plt_cpuspd		; USE STANDALONE CPU SPEED
#ENDIF
		LD	HL,CLKTBL-1		; CPU SPEED
		ADD	A,L			; INDEXES 
		LD	L,A			; INTO
		ADC	A,H			; TABLE
		SUB	L			
		LD	H,A                     ; LOOK IT UP IN THE
		LD	A,(HL)                  ; CLOCK TABLE
;
		LD	(fdelay),A		; SAVE LOOP COUNTER FOR CPU SPEED
		RET
;
;------------------------------------------------------------------------------
; Frame delay values for different processor speeds. 
;------------------------------------------------------------------------------
;
;	    1/44100hz  = 22676ns
;		16Mhz  = 62.5ns  : DJNZ $	= 1 frame delay= 22676ns/13*62.5ns  = 27.91
;		12Mhz  = 83.3ns  : DJNZ $	= 1 frame delay= 22676ns/13*83.3ns  = 20.94
;		10Mhz  = 100ns   : DJNZ $	= 1 frame delay= 22676ns/13*100ns   = 17.44
;		 8Mhz  = 125ns   : DJNZ $	= 1 frame delay= 22676ns/13*125ns   = 13.95
;	    7.3728Mhz  = 135.6ns : DJNZ $	= 1 frame delay= 22676ns/13*135.6ns = 12.86
;		 6Mhz  = 166.6s  : DJNZ $	= 1 frame delay= 22676ns/13*166.6ns = 10.47
;		 4Mhz  = 250ns   : DJNZ $	= 1 frame delay= 22676ns/13*250ns   =  6.98
;		 2Mhz  = 500ns   : DJNZ $	= 1 frame delay= 22676ns/13*500ns   =  3.49
;		 1Mhz  = 1000ns  : DJNZ $	= 1 frame delay= 22676ns/13*1000ns  =  1.74
;
CLKTBL:		.DB	1  		; 1Mhz		; none of these 
		.DB	3  		; 2Mhz		; have been
		.DB	0		; 3Mhz		; validated
		.DB	6  		; 4Mhz
		.DB	0		; 5Mhz
		.DB	10 		; 6Mhz
		.DB	12 		; 7Mhz 7.3728Mhz
		.DB	13 		; 8Mhz
		.DB	0		; 9Mhz
		.DB	17 		; 10Mhz
		.DB	0		; 11Mhz
		.DB	20 		; 12Mhz
		.DB	0		; 13Mhz
		.DB	0		; 14Mhz
		.DB	0		; 15Mhz
		.DB	27 		; 16Mhz
		.DB	0		; 17Mhz
		.DB	0		; 18Mhz
		.DB	0		; 19Mhz
		.DB	0		; 20Mhz
#ENDIF
;
;
;------------------------------------------------------------------------------
; Initialize CTC
;------------------------------------------------------------------------------
;
; %01010011	; CTC DEFAULT CONFIG
; %01010111	; CTC COUNTER MODE CONFIG
; %11010111	; CTC COUNTER INTERRUPT MODE CONFIG
;  |||||||+-- CONTROL WORD FLAG
;  ||||||+--- SOFTWARE RESET
;  |||||+---- TIME CONSTANT FOLLOWS
;  ||||+----- AUTO TRIGGER WHEN TIME CONST LOADED
;  |||+------ RISING EDGE TRIGGER
;  ||+------- TIMER MODE PRESCALER (0=16, 1=256)
;  |+-------- COUNTER MODE
;  +--------- INTERRUPT ENABLE
;
cfgctc_poll:
;
ctcch0		.equ	ctcbase
ctcch1		.equ	ctcbase+1
ctcch2		.equ	ctcbase+2
ctcch3		.equ	ctcbase+3
;
ctccfg0		.equ	%01010011
ctccfg1		.equ	%01010111
ctccfg2		.equ	%01010111
ctccfg3		.equ	%01010111
;
		ld	a,ctccfg0 & $7f	; 	; Channel 0
		out	(ctcch0),a
;	
		ld	a,ctccfg1 & $7f		; Channel 1
		out	(ctcch1),a		; 
		ld	a,ctcdiv1 & $ff		; 
		out	(ctcch1),a		; 
;
		ld	a,ctccfg2 & $7f		; Channel 2
		out	(ctcch2),a		; 
		ld	a,ctcdiv2 & $ff		; 
		out	(ctcch2),a		; 
;
		ld	a,ctccfg3 & $7f		; Channel 3
		out	(ctcch3),a		; 
		ld	a,ctcdiv3 & $ff		; 
		out	(ctcch3),a		; 
;
		ret
;
#IF (debug)	
ctctest:
		ld	b,0

ctclp1:		in	a,(ctcch3)		; wait for counter to reach zero
		dec	a
		jr	nz,ctclp1

ctclp2:		in	a,(ctcch3)		; wait for counter to pass zero
		dec	a
		jr	z,ctclp2

		call	PRTDOT
;
		djnz	ctclp1
#ENDIF
		ret
;
cfgctc_int:
		ret

                .END
