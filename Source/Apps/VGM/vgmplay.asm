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
; Bugs: YM2151 playback untested & no mute.
;       CTC polled timing - predicted 44100 divider is too slow
;
; Assemble with:
;
;   TASM -80 -b VGMPLAY.ASM VGMPLAY.COM
;
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
custom		.equ	0           	        ; System configurations
P8X180          .equ    1
RC2014          .equ    2
sbcecb		.equ	3			
MBC		.equ	4
;
plt_romwbw	.equ	1			; Build for ROMWBW?
plt_type	.equ	sbcecb			; Select build configuration
debug		.equ	0			; Display port, register, config info
;
#IF (plt_type=custom)
RSEL            .equ    09AH			; Primary AY-3-8910 Register selection
RDAT            .equ    09BH			; Primary AY-3-8910 Register data
RSEL2           .equ    88H			; Secondary AY-3-8910 Register selection
RDAT2           .equ    89H			; Secondary AY-3-8910 Register data
VGMBASE		.equ	$C0
YMSEL		.equ	VGMBASE+00H		; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	VGMBASE+01H		; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	VGMBASE+02H		; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	VGMBASE+03H		; Secondary YM2162 11000011 a1=1 a0=1
PSG1REG         .equ    VGMBASE+08H		; Primary SN76489
PSG2REG         .equ    VGMBASE+09H		; Secondary SN76489
ctcbase		.equ	VGMBASE+0CH		; CTC base address
YM2151_SEL1	.equ	0FEH			; Primary YM2151 register selection
YM2151_DAT1	.equ	0FFH			; Primary YM2151 register data
YM2151_SEL2	.equ	0FEH			; Secondary YM2151 register selection
YM2151_DAT2	.equ	0FFH			; Secondary YM2151 register data
FRAME_DLY       .equ    10  			; Frame delay (~ 1/44100)
plt_cpuspd	.equ	6			; Non ROMWBW cpu speed default
#ENDIF
;
#IF (plt_type=P8X180)
RSEL            .equ    82H			; Primary AY-3-8910 Register selection
RDAT            .equ    83H			; Primary AY-3-8910 Register data
RSEL2           .equ    88H			; Secondary AY-3-8910 Register selection
RDAT2           .equ    89H			; Secondary AY-3-8910 Register data
PSG1REG         .equ    84H			; Primary SN76489
PSG2REG         .equ    8AH			; Secondary SN76489
YM2151_SEL1	.equ	0B0H			; Primary YM2151 register selection
YM2151_DAT1	.equ	0B1H			; Primary YM2151 register data
YM2151_SEL2	.equ	0B2H			; Secondary YM2151 register selection
YM2151_DAT2	.equ	0B3H			; Secondary YM2151 register data
ctcbase		.equ	000H			; CTC base address
YMSEL		.equ	000H			; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	000H			; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	000H			; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	000H			; Secondary YM2162 11000011 a1=1 a0=1
FRAME_DLY       .equ    48			; Frame delay (~ 1/44100)
plt_cpuspd	.equ	20			; Non ROMWBW cpu speed default
#ENDIF
;
#IF (plt_type=RC2014)
RSEL            .equ    0D8H			; Primary AY-3-8910 Register selection
RDAT            .equ    0D0H			; Primary AY-3-8910 Register data
RSEL2           .equ    0A0H			; Secondary AY-3-8910 Register selection
RDAT2           .equ    0A1H			; Secondary AY-3-8910 Register data
PSG1REG         .equ    0FFH			; Primary SN76489
PSG2REG         .equ    0FBH			; Secondary SN76489
YM2151_SEL1	.equ	0FEH			; Primary YM2151 register selection
YM2151_DAT1	.equ	0FFH			; Primary YM2151 register data
YM2151_SEL2	.equ	0D0H			; Secondary YM2151 register selection
YM2151_DAT2	.equ	0D1H			; Secondary YM2151 register data
ctcbase		.equ	000H			; CTC base address
YMSEL		.equ	000H			; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	000H			; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	000H			; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	000H			; Secondary YM2162 11000011 a1=1 a0=1
FRAME_DLY       .equ    12			; Frame delay (~ 1/44100)
plt_cpuspd	.equ	7			; Non ROMWBW cpu speed default
#ENDIF
;
#IF (plt_type=sbcecb)
RSEL            .equ    09AH			; Primary AY-3-8910 Register selection
RDAT            .equ	09BH			; Primary AY-3-8910 Register data
RSEL2           .equ    0A0H			; Secondary AY-3-8910 Register selection
RDAT2           .equ    0A1H			; Secondary AY-3-8910 Register data
VGMBASE		.equ	$C0
YMSEL		.equ	VGMBASE+00H		; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.equ	VGMBASE+01H		; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.equ	VGMBASE+02H		; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.equ	VGMBASE+03H		; Secondary YM2162 11000011 a1=1 a0=1
PSG1REG         .equ    VGMBASE+06H		; Primary SN76489
PSG2REG         .equ    VGMBASE+07H		; Secondary SN76489
ctcbase		.equ	VGMBASE+0CH		; CTC base address
YM2151_SEL1	.equ	0FEH			; Primary YM2151 register selection
YM2151_DAT1	.equ	0FFH			; Primary YM2151 register data
YM2151_SEL2	.equ	0FEH			; Secondary YM2151 register selection
YM2151_DAT2	.equ	0FFH			; Secondary YM2151 register data
FRAME_DLY       .equ    13  			; Frame delay (~ 1/44100)
plt_cpuspd	.equ	8			; Non ROMWBW cpu speed default
#ENDIF
;
#IF (plt_type=MBC)
RSEL            .equ    0A0H			; Primary AY-3-8910 Register selection
RDAT            .equ    0A1H			; Primary AY-3-8910 Register data
RSEL2           .equ    0D8H			; Secondary AY-3-8910 Register selection
RDAT2           .equ    0D0H			; Secondary AY-3-8910 Register data
YMSEL		.equ	0C0H			; 11000000 a1=0 a0=0
YMDAT		.equ	0C1H			; 11000001 a1=0 a0=1
YM2SEL		.equ	0C2H			; 11000010 a1=1 a0=0
YM2DAT		.equ	0C3H			; 11000011 a1=1 a0=1
PSG1REG         .equ    0C6H			; Primary SN76489
PSG2REG         .equ    0C7H			; Secondary SN76489
ctcbase		.equ	000H			; CTC base address
YM2151_SEL1	.equ	0FEH			; Primary YM2151 register selection
YM2151_DAT1	.equ	0FFH			; Primary YM2151 register data
YM2151_SEL2	.equ	0FEH			; Secondary YM2151 register selection
YM2151_DAT2	.equ	0FFH			; Secondary YM2151 register data
FRAME_DLY       .equ    13  			; Frame delay (~ 1/44100)
plt_cpuspd	.equ	8			; Non ROMWBW cpu speed default
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
#DEFINE	setreg(reg,val) \
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
#DEFINE	setreg2(reg,val) \
#DEFCONT \	ld	a,reg 
#DEFCONT \	out	(YM2SEL),a 
#DEFCONT \	ld	a,val 
#DEFCONT \	out	(YM2DAT),a
#DEFCONT \	ld	b,0
#DEFCONT \	in	a,(YMSEL)
#DEFCONT \	rlca
#DEFCONT \	jp	nc,$+5
#DEFCONT \	djnz	$-6

;------------------------------------------------------------------------------
; VGM Codes - see vgmrips.net/wiki/VGM_specification
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
VGM_YM21511_W	.equ	054H			; YM2612 #1 WRITE VALUE DD
VGM_YM21512_W	.equ	0A4H			; YM2612 #2 WRITE VALUE DD

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

                LD      (OLDSTACK),SP		; save old stack pointer
                LD      SP,STACK		; set new stack pointer
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
		call	welcome			; Welcome message and build debug info
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
		LD      (vdelay), HL
;
		LD	IX,VGM_DEV		; IX points to device mask
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
                RST     00H
		DI
		HALT
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

	LD	(fdelay),A		; SAVE LOOP COUNTER FOR CPU SPEED
	RET

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

ctclp1:	in	a,(ctcch3)		; wait for counter to reach zero
	dec	a
	jr	nz,ctclp1

ctclp2:	in	a,(ctcch3)		; wait for counter to pass zero
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
MSG_RC2014	.DB	" [rc2014] ",0
MSG_SBCECB	.DB	" [sbc] ",0
MSG_MBC		.DB	" [mbc] ",0
;
;------------------------------------------------------------------------------
; Variables
;------------------------------------------------------------------------------
;
VGMPOS          .DW     0
;VGMDLY          .DW     0		; Saves number of frames to delay
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
                .DS     40H		; space for stack
STACK					; top of stack

;------------------------------------------------------------------------------
; VGM data
;------------------------------------------------------------------------------

VGMDATA
                .END
