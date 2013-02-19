;
;	monitor.asm  This is main monitor program for my system
;
;


BELL	.EQU	07H
SPACE	.EQU	20H
TAB	.EQU	09H
CR	.EQU	0DH
LF	.EQU	0AH
FF	.EQU	0CH
ESC	.EQU	1BH
DELETE	.EQU	7FH


STARTCPM .EQU   100H   ;LOCATION WHERE CPM WILL BE PLACED FOR COLD BOOT

;---------PORT(S) TO SWITCH MASTER/SLAVE(S)

Z80PORT	.EQU	0D0H		;4 PORTS ON Z80 BOARD FOR MEMORY MANAGEMENT.


BCTL	.EQU	0A0H		;CHANNEL B CONTROL PORT FOR SCC 
ACTL	.EQU	0A1H		;CHANNEL A CONTROL
BDTA	.EQU	0A2H		;CHANNEL B DATA
ADTA	.EQU	0A3H		;CHANNEL A DATA

;-------------- S100Computers IDE HARD DISK CONTROLLER COMMANDS ETC.
IDEAport        .EQU     030H            ;lower 8 bits of IDE interface
IDEBport        .EQU     031H            ;upper 8 bits of IDE interface
IDECport        .EQU     032H            ;control lines for IDE interface
IDECtrl         .EQU     033H            ;8255 configuration port
IDEDrivePort    .EQU     034H            ;To select the 1st or 2nd CF card/drive (Not used with this monitor)

IDE_Reset_Delay .EQU     020H            ;Time delay for reset/initilization (~60 uS, with 10MHz Z80, 2 I/O wait states)

CPM_ADDRESS     .EQU     100H            ;Will place the CPMLDR.COM Loader here with
                                        ;CPMLDR.COM will ALWAYS be on TRK 0,SEC2, (LBA Mode)
SEC_COUNT       .EQU     12              ;CPMLDR.COM requires (currently) 10, 512 byte sectors
                                        ;Add extra just in case
RDcfg8255       .EQU     10010010B       ;Set 8255 IDECport out, IDEAport/B input
WRcfg8255       .EQU     10000000B       ;Set all three 8255 ports output
;
IDEa0line       .EQU     01H             ;direct from 8255 to IDE interface
IDEa1line       .EQU     02H             ;direct from 8255 to IDE interface
IDEa2line       .EQU     04H             ;direct from 8255 to IDE interface
IDEcs0line      .EQU     08H             ;inverter between 8255 and IDE interface
IDEcs1line      .EQU     10H             ;inverter between 8255 and IDE interface
IDEwrline       .EQU     20H             ;inverter between 8255 and IDE interface
IDErdline       .EQU     40H             ;inverter between 8255 and IDE interface
IDEreset        .EQU     80H             ;inverter between 8255 and IDE interface
;
;Symbolic constants for the IDE Drive registers, which makes the
;code more readable than always specifying the address pins
;
REGdata         .EQU     08H             ;IDEcs0line
REGerr          .EQU     09H             ;IDEcs0line + IDEa0line
REGcnt          .EQU     0AH             ;IDEcs0line + IDEa1line
REGsector       .EQU     0BH             ;IDEcs0line + IDEa1line + IDEa0line
REGcyLSB        .EQU     0CH             ;IDEcs0line + IDEa2line
REGcyMSB        .EQU     0DH             ;IDEcs0line + IDEa2line + IDEa0line
REGshd          .EQU     0EH             ;IDEcs0line + IDEa2line + IDEa1line             ;(0EH)
REGCMD          .EQU     0FH             ;IDEcs0line + IDEa2line + IDEa1line + IDEa0line ;(0FH)
REGstatus       .EQU     0FH             ;IDEcs0line + IDEa2line + IDEa1line + IDEa0line
REGcontrol      .EQU     16H             ;IDEcs1line + IDEa2line + IDEa1line
REGastatus      .EQU     17H             ;IDEcs1line + IDEa2line + IDEa1line + IDEa0line

;IDE CMD Constants.  These should never change.
CMDrecal        .EQU     10H
CMDread         .EQU     20H
CMDwrite        .EQU     30H
CMDinit         .EQU     91H
CMDid           .EQU     0ECH
CMDdownspin     .EQU     0E0H
CMDupspin       .EQU     0E1H
;
; IDE Status Register:
;  bit 7: Busy  1=busy, 0=not busy
;  bit 6: Ready 1=ready for CMD, 0=not ready yet
;  bit 5: DF    1=fault occured insIDE drive
;  bit 4: DSC   1=seek complete
;  bit 3: DRQ   1=data request ready, 0=not ready to xfer yet
;  bit 2: CORR  1=correctable error occured
;  bit 1: IDX   vendor specific
;  bit 0: ERR   1=error occured
;
	.ORG	0F000H
	JP	BEGIN

TBL:
	.DW	NOTIMPL		; "@"
	.DW	MEMMAP		; "A" DISPLAY A MAP OF MEMORY
	.DW	NOTIMPL		; "B"
	.DW	NOTIMPL		; "C"
	.DW	DISP		; "D" DISPLAY MEMORY (IN HEX & ASCII)
	.DW	NOTIMPL		; "E" ECHO CHAR IN TO CHAR OUT
	.DW	FILL		; "F" FILL MEMORY WITH A CONSTANT
	.DW	GOTO		; "G" GO TO [ADDRESS]
	.DW	NOTIMPL		; "H"
	.DW	NOTIMPL		; "I"
	.DW	NOTIMPL		; "J" NON-DESTRUCTIVE MEMORY TEST
	.DW	NOTIMPL		; "K"
	.DW	NOTIMPL		; "L"
	.DW	NOTIMPL		; "M"
	.DW	XMEMMAP		; "N" DISPLAY EXTENDED MEMORY SEGEMENT:ADDRESS
	.DW	NOTIMPL		; "O"
	.DW	HBOOTCPM	; "P BOOT IN CPM FROM IDE HARD DISK"
	.DW	QUERY		; "Q" QUERY PORT (IN OR OUT)
	.DW	NOTIMPL		; "R"
	.DW	SUBS		; "S" SUBSTITUTE &/OR EXAMINE MEMORY
	.DW	NOTIMPL		; "T"
	.DW	NOTIMPL		; "U"
	.DW	NOTIMPL		; "V" COMPARE MEMORY
	.DW	NOTIMPL		; "X"
	.DW	NOTIMPL		; "Y"
	.DW	NOTIMPL		; "Z"


SCCINIT:
        .DB      04H		;Point to WR4
        .DB      44H            ;X16 clock,1 Stop,NP
;
        .DB      03H            ;Point to WR3
        .DB      0C1H           ;Enable reciever, Auto Enable, Recieve 8 bits
;       .DB      0E1H           ;Enable reciever, No Auto Enable, Recieve 8 bits (for CTS bit)
;
        .DB      05H            ;Point to WR5
        .DB      0EAH           ;Enable, Transmit 8 bits
;                               ;Set RTS,DTR, Enable
;
        .DB      0BH            ;Point to WR11
        .DB      56H            ;Recieve/transmit clock = BRG
;
        .DB      0CH            ;Point to WR12
;       .DB      40H            ;Low Byte 2400 Baud
;       .DB      1EH            ;Low Byte 4800 Baud
;       .DB      0EH            ;Low Byte 9600 Baud
        .DB      06H            ;Low byte 19,200 Baud
;       .DB      02H            ;Low byte 38,400 Baud <<<<<<<<<<<
;       .DB      00H            ;Low byte 76,800 Baud
;
        .DB      0DH            ;Point to WR13
        .DB      00H            ;High byte for Baud

        .DB      0EH            ;Point to WR14
        .DB      01H            ;Use 4.9152 MHz Clock. Note SD Systems uses a 2.4576 MHz clock, enable BRG
;
        .DB      0FH            ;Point to WR15
        .DB      00H            ;Generate Int with CTS going high
	.DB	 00H
	.DB	 00H
	.DB	 00H
	.DB	 00H
	.DB	 00H

;
;	BEGIN OF CODE -----------------------------------------------------------------------

BEGIN:
 	LD	A,0FFH
 	XOR	A
 	OUT	(Z80PORT+1),A
	
 	LD	A,0H
 	OUT	(Z80PORT+2),A
 	LD	A,04H
 	OUT	(Z80PORT+3),A

        LD      A,ACTL
        LD      C,A
        LD      B,$0E
        LD      HL,SCCINIT
        OTIR

        LD      A,BCTL
        LD      C,A
        LD      B,$0E
        LD      HL,SCCINIT
        OTIR

ZAXXLE:
	LD	SP,AHEAD-4	;SETUP FAKE STACK FRAME
	JP	MEMSZ1		;RETURNS WITH TOP OF RAM IN [HL]
	.DW	AHEAD		;RETURN WILL PICK UP THIS ADDRESS
AHEAD:	
	LD	SP,HL		;[HL] CONTAINS TOP OF RAM
	PUSH	HL
	POP	IX		;SAVE STACK POINTER IN IX FOR FUTURE USE 

	LD	HL,MSG0
	CALL	ZPMSG

	LD	HL,SP_MSG	;PRINT CURRENT STACK LOCATION
	CALL	ZPMSG		

	PUSH	IX		;SP IS STORED HERE FROM ABOVE
	POP	HL
	CALL	HLSP		;PRINT HL/SP
	CALL	CRLF		;THEN CRLF

START:
	LD	DE,START
	PUSH	DE		;EXTRA UNBALANCED POP & [DE] WOULD END UP IN [PC]
	CALL	CRLF
	LD	C,BELL		;A BELL HERE WILL SIGNAL WHEN JOBS ARE DONE
	CALL	CO
	LD	C,'-'
	CALL	CO
	LD	C,'>'
	CALL	CO

STAR0:				;MAIN LOOP.  MONITOR WILL STAY HERE UNTIL CMD.
	CALL	TI
	AND	7FH
	JR	Z,STAR0
	SUB	'@'		;COMMANDS @ TO Z ONLY
	RET	M
	CP	1BH		;A-Z ONLY
	RET	NC
	ADD	A,A
	LD	HL,TBL
	ADD 	A,L
	LD	L,A
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	LD	C,02H
	JP	(HL)		;JUMP TO COMMAND TABLE


MSG0:	.DB	"Z80 ROM MONITOR V1.0 (David Mehaffy 12/24/2011)   $"
SP_MSG	.DB	CR,LF,"SP=$"

ZPMSG:	LD	A,(HL)		;A ROUTINE TO PRINT OUT A STRING @ [HL]
	INC	HL		;UP TO THE FIRST '$'
	CP	'$'
	RET	Z
	LD	C,A
	CALL	CO
	JR	ZPMSG

;THIS IS A CALLED ROUTINE USED TO CALCULATE TOP OF RAM IS USED BY
;THE ERROR TO RESET THE STACK. Returns top of RAM in [HL]


MEMSIZ: PUSH    BC              ;SAVE [BC]
MEMSZ1: LD      HL,0FFFFH       ;START FROM THE TOP DOWN
MEMSZ2: LD      A,(HL)
        CPL
        LD      (HL),A
        CP      (HL)
        CPL                     ;PUT BACK WHAT WAS THERE
        LD      (HL),A
        JP      Z,GOTTOP
        DEC     H               ;TRY 100H BYTES LOWER
        JR      MEMSZ2          ;KEEP LOOKING FOR RAM
GOTTOP: POP     BC              ;RESTORE [BC]
        RET


;ABORT IF ESC  AT CONSOL, PAUSE IF ^S AT CONSOL

CCHK:   CALL    CSTS		;FIRST IS THERE ANYTHING THERE
        RET     Z
        CALL    CI
        CP      'S'-40H
        JR      NZ,CCHK1
CCHK2:  CALL    CSTS            ;WAIT HERE UNTIL ANOTHER INPUT IS GIVEN
        JR      Z,CCHK2
CCHK1:  CP      ESC
        RET     NZ              ;RETURN EXECPT IF ESC

;RESTORE SYSTEM AFTER ERROR

ERROR:  CALL    MEMSIZ          ;GET RAM AVAILABLE - WORKSPACE IN [HL]
        LD      SP,HL           ;SET STACK UP IN WORKSPACE AREA
        LD      C,'*'
        CALL    CO
        JP      START

;PRINT HIGHEST MEMORY FROM BOTTOM

SIZE:
        CALL    MEMSIZ          ;RETURNS WITH [HL]= RAM AVAILABLE-WORKSPACE


LFADR:  CALL    CRLF

;PRINT [HL] AND A SPACE
HLSP:   PUSH    HL
        PUSH    BC
        CALL    LADR
        LD      C,SPACE
        CALL    CO
        POP     BC
        POP     HL
        RET

;PRINT A SPACE

SF488:  LD      C,SPACE
        JP      CO


;CONVERT HEX TO ASCII

CONV:
	AND	0FH
	ADD	A,90H
	DAA
	ADC	A,40H
	DAA
	LD	C,A
	RET

;GET TWO PARAMETERS AND PUT THEM IN [HL] & [DE] THEN CRLF

EXLF:   CALL    HEXSP
        POP     DE
        POP     HL


CRLF:
	PUSH	BC
	LD	C,LF
	CALL	CO
	LD	C,CR
	CALL	CO
	POP	BC
	RET

;PUT THREE PARAMETERS IN [BC] [DE] [HL] THEN CR/LF

EXPR3:  INC     C                       ;ALREADY HAD [C]=2 FROM START
        CALL    HEXSP
        CALL    CRLF
        POP     BC
        POP     DE
        POP     HL
        RET

;GET ONE PARAMETER

EXPR1:  LD      C,01H
HEXSP:  LD      HL,0000
EX0:    CALL    TI
EX1:    LD      B,A
        CALL    NIBBLE
        JR      C,EX2X
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        OR      L
        LD      L,A
        JR      EX0
EX2X:   EX      (SP),HL
        PUSH    HL
        LD      A,B
        CALL    QCHK
        JR      NC,SF560
        DEC     C
        RET     Z
SF560:  JP      NZ,ERROR
        DEC     C
        JR      NZ,HEXSP
        RET
EXF:    LD      C,01H
        LD      HL,0000H
        JR      EX1

;RANGE TEST ROUTINE CARRY SET = RANGE EXCEEDED

HILOX:  CALL    CCHK
        CALL    HILO
        RET     NC
        POP     DE                      ;DROP ONE LEVEL BACK TO START
        RET
HILO:   INC     HL                      ;RANGE CHECK SET CARRY IF [DE]=[HL]
        LD      A,H
        OR      L
        SCF
        RET     Z
        LD      A,E
        SUB     L
        LD      A,D
        SBC     A,H
        RET


;	PRINT [HL] ON CONSOLE

LADR:	LD	A,H
	CALL	LBYTE
	LD	A,L
LBYTE:	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	SF598
	POP	AF
SF598:	CALL	CONV
	JP	CO 


NIBBLE: SUB     30H
        RET     C
        CP      17H
        CCF
        RET     C
        CP      LF
        CCF
        RET     NC
        SUB     07H
        CP      LF
        RET

COPCK:  LD      C,'-'
        CALL    CO

PCHK:   CALL    TI

;TEST FOR DELIMITERS

QCHK:   CP      SPACE
        RET     Z
        CP      ','
        RET     Z
        CP      CR
        SCF
        RET     Z
        CCF
        RET

;KEYBOARD HANDLING ROUTINTE (WILL NOT ECHO CR/LF)
;IT CONVERTS LOWER CASE TO UPPERCASE FOR LOOKUP COMMANDS
;ALSO ^C WILL FOR A JUMP TO BOOT TO CP/M
;ALL OTHER CHARACTERS ARE ECHOED ON CONSOLE

TI:
	CALL 	CI
	CP	CR
	RET	Z
	CP	'C' - 40H	;^C TO BOOT TO CP/M
	JP	Z,FBOOT
	PUSH	BC
	LD	C,A
	CALL	CO
	LD	A,C
	POP	BC
	CP	40H		;LC-.UC
	RET	C
	CP	7BH
	RET	NC
SF574:	AND	5FH
	RET

BITS1:  PUSH    DE                      ;DISPLAY 8 BITS OF [A]
        PUSH    BC
        LD      E,A
        CALL    BITS
        POP     BC
        POP     DE
        RET

BITS:   LD      B,08H                   ;DISPLAY 8 BITS OF [E]
        CALL    SF488
SF76E:  SLA     E
        LD      A,18H
        ADC     A,A
        LD      C,A
        CALL    CO
        DJNZ    SF76E
        RET

;<<<<<<<<<<<<<<<< MAIN CONSOLE ROUTINES <<<<<<<<<<<<<

CO:
        IN      A,(ACTL)
        AND     04H             ;ARE WE READY FOR A CHARACTER
        JR      Z,CO
        LD      A,C
        OUT     (ADTA),A
        RET

CI:
        IN      A,(ACTL)
        AND     01H
        JR      Z,CI
        IN      A,(ADTA)
        RET

CSTS:   IN      A,(ACTL)
        AND     01H
        RET     Z               ;RETURN Z IF NOTHING
        LD      A,0FFH
        XOR     A               ;RETURN FF / NZ IF SOMETHING
        RET

;-------------- BOOT UP CPM FROM HARD DISK ON S100COMPUTERS IDR BOARD ----------------

;BOOT UP THE 8255/IDE Board HARD DISK/Flash Memory Card
;NOTE CODE IS ALL HERE IN CASE A 2716 IS USED

HBOOTCPM:
        POP     HL                      ;CLEAN UP STACK

        CALL    INITILIZE_IDE_BOARD     ;Initilze the 8255 and drive (again just in case)

        LD      D,11100000B             ;Data for IDE SDH reg (512bytes, LBA mode,single drive)
        LD      E,REGshd                ;00001110,(0EH) CS0,A2,A1,
        CALL    IDEwr8D                 ;Write byte to select the MASTER device

        LD      B,0FFH                  ;Delay time to allow a Hard Disk to get up to speed
WaitInit:
        LD      E,REGstatus             ;Get status after initilization
        CALL    IDErd8D                 ;Check Status (info in [D])
        BIT     7,D
        JR      Z,SECREAD               ;Zero, so all is OK to write to drive
                                        ;Delay to allow drive to get up to speed
        PUSH    BC
        LD      BC,0FFFFH
DXLAY2: LD      D,2                     ;May need to adjust delay time to allow cold drive to
DXLAY1: DEC     D                       ;to speed
        JR      NZ,DXLAY1
        DEC     BC
        LD      A,C
        OR      B
        JR      NZ,DXLAY2
        POP     BC
        DJNZ    WaitInit                ;If after 0FFH, 0FEH, 0FDH... 0, then drive initilization problem
IDError:
        LD      HL,DRIVE_NR_ERR         ;Drive not ready
        JP      ABORT_ERR_MSG

SECREAD:                                ;Note CPMLDR will ALWAYS be on TRK 0,SEC 1,Head 0
        CALL    IDEwaitnotbusy          ;Make sure drive is ready
        JR      C,IDError               ;NC if ready

        LD      D,1                     ;Load track 0,sec 1, head 0
        LD      E,REGsector             ;Send info to drive
        CALL    IDEwr8D

        LD      D,0                     ;Send Low TRK#
        LD      E,REGcyLSB
        CALL    IDEwr8D

        LD      D,0                     ;Send High TRK#
        LD      E,REGcyMSB
        CALL    IDEwr8D

        LD      D,SEC_COUNT             ;Count of CPM sectors we wish to read
        LD      E,REGcnt
        CALL    IDEwr8D

        LD      D,CMDread               ;Send read CMD
        LD      E,REGCMD
        CALL    IDEwr8D                 ;Send sec read CMD to drive.
        CALL    IDEwdrq                 ;Wait until it's got the data

        LD      HL,CPM_ADDRESS          ;DMA address where the CPMLDR resides in RAM
        LD      B,0                     ;256X2 bytes
        LD      C,SEC_COUNT             ;Count of sectors X 512
MoreRD16:
        LD      A,REGdata               ;REG regsiter address
        OUT     (IDECport),A

        OR      IDErdline               ;08H+40H, Pulse RD line
        OUT     (IDECport),A

        IN      A,(IDEAport)            ;read the LOWER byte
        LD      (HL),A
        INC     HL
        IN      A,(IDEBport)            ;read the UPPER byte
        LD      (HL),A
        INC     HL

        LD      A,REGdata               ;Deassert RD line
        OUT     (IDECport),A
        DJNZ    MoreRD16
        DEC     C
        JR      NZ,MoreRD16

        LD      E,REGstatus             ;Check the R/W status when done
        CALL    IDErd8D
        BIT     0,D
        JR      NZ,IDEerr1              ;Z if no errors
        LD      HL,STARTCPM
        LD      A,(HL)
        CP      31H                     ;EXPECT TO HAVE 31H @80H IE. LD SP,80H
        JP      Z,STARTCPM              ;AS THE FIRST INSTRUCTION. IF OK JP to 100H in RAM
        JP      ERR_LD1                 ;Boot Sector Data incorrect

IDEerr1:
        LD      HL,IDE_RW_ERROR         ;Drive R/W Error
        JP      ABORT_ERR_MSG


;      ----- SUPPORT ROUTINES --------------

INITILIZE_IDE_BOARD:                    ;Drive Select in [A]. Note leaves selected drive as [A]
        LD      A,RDcfg8255             ;Config 8255 chip (10010010B), read mode on return
        OUT     (IDECtrl),A             ;Config 8255 chip, READ mode

                                        ;Hard reset the disk drive
                                        ;For some reason some CF cards need to the RESET line
                                        ;pulsed very carefully. You may need to play around
        LD      A,IDEreset              ;with the pulse length. Symptoms are: incorrect data comming
        OUT     (IDECport),A            ;back from a sector read (often due to the wrong sector being read)
                                        ;I have a (negative)pulse of 60 uSec. (10Mz Z80, two IO wait states).

        LD      C,IDE_Reset_Delay       ;~60 uS seems to work for the 5 different CF cards I have
ResetDelay:
        DEC     C
        JP      NZ,ResetDelay           ;Delay (reset pulse width)
        XOR     A
        OUT     (IDECport),A            ;No IDE control lines asserted (just bit 7 of port C)

        CALL    DELAY_15                ;Need to delay a little before checking busy status

IDEwaitnotbusy:                         ;Drive READY if 01000000
        LD      B,0FFH
        LD      C,080H                  ;Delay, must be above 80H for 4MHz Z80. Leave longer for slower drives
MoreWait:
        LD      E,REGstatus             ;Wait for RDY bit to be set
        CALL    IDErd8D
        LD      A,D
        AND     11000000B
        XOR     01000000B
        JR      Z,DoneNotBusy
        DJNZ    MoreWait
        DEC     C
        JR      NZ,MoreWait
        SCF                             ;Set carry to indicate an error
        RET
DoneNotBusy:
        OR      A                       ;Clear carry it indicate no error
        RET


                                        ;Wait for the drive to be ready to transfer data.
IDEwdrq:                                ;Returns the drive's status in Acc
        LD      B,0FFH
        LD      C,0FFH                  ;Delay, must be above 80H for 4MHz Z80. Leave longer for slower drives
MoreDRQ:
        LD      E,REGstatus             ;wait for DRQ bit to be set
        CALL    IDErd8D
        LD      A,D
        AND     10001000B
        CP      00001000B
        JR      Z,DoneDRQ
        DJNZ    MoreDRQ
        DEC     C
        JR      NZ,MoreDRQ
        SCF                             ;Set carry to indicate error
        RET
DoneDRQ:
        OR      A                       ;Clear carry
        RET
;
;------------------------------------------------------------------
; Low Level 8 bit R/W to the drive controller.  These are the routines that talk
; directly to the drive controller registers, via the 8255 chip.
; Note the 16 bit I/O to the drive (which is only for SEC Read here) is done directly
; in the routine MoreRD16 for speed reasons.

IDErd8D:                                ;READ 8 bits from IDE register in [E], return info in [D]
        LD      A,E
        OUT     (IDECport),A            ;drive address onto control lines

        OR      IDErdline               ;RD pulse pin (40H)
        OUT     (IDECport),A            ;assert read pin

        IN      A,(IDEAport)
        LD      D,A                     ;return with data in [D]

        LD      A,E                     ;<---Ken Robbins suggestion
        OUT     (IDECport),A            ;Deassert RD pin

        XOR     A
        OUT     (IDECport),A            ;Zero all port C lines
        RET


IDEwr8D:                                ;WRITE Data in [D] to IDE register in [E]
        LD      A,WRcfg8255             ;Set 8255 to write mode
        OUT     (IDECtrl),A

        LD      A,D                     ;Get data put it in 8255 A port
        OUT     (IDEAport),A

        LD      A,E                     ;select IDE register
        OUT     (IDECport),A

        OR      IDEwrline               ;lower WR line
        OUT     (IDECport),A

        LD      A,E                     ;<-- Kens Robbins suggestion, raise WR line
        OUT     (IDECport),A

        XOR     A                       ;Deselect all lines including WR line
        OUT     (IDECport),A

        LD      A,RDcfg8255             ;Config 8255 chip, read mode on return
        OUT     (IDECtrl),A
        RET

ERR_NR: LD      HL,DRIVE_NR_ERR         ;"DRIVE NOT READY
        JP      ABORT_ERR_MSG
ERR_LD: LD      HL,BOOT_LD_ERR          ;"ERROR READING BOOT/LOADER SECTORS"
        JP      ABORT_ERR_MSG
ERR_LD1:LD      HL,BOOT_LD1_ERR         ;"DATA ERROR IN BOOT SECTOR"

ABORT_ERR_MSG:
        CALL    ZPMSG
        JP      BEGIN                  ;BACK TO START OF MONITOR.

DELAY_15:                               ;DELAY ~15 MS
        LD      A,40
DELAY1: LD      B,0
M0:     DJNZ    M0
        DEC     A
        JR      NZ,DELAY1
        RET


;---------------------------------------------------------------

;MEMORY MAP PROGRAM CF.DR.DOBBS VOL 31 P40.
;IT WILL SHOW ON CONSOLE TOTAL MEMORY SUMMARY OF RAM, PROM, AND NO MEMORY

MEMMAP:
	CALL	CRLF
	LD	HL,0
	LD	B,1
MAP1:	LD	E,'R'		;PRINT R FOR RAM
	LD	A,(HL)
	CPL
	LD	(HL),A
	CP	(HL)
	CPL
	LD	(HL),A
	JR	NZ,MAP2
	CP	(HL)
	JR	Z,PRINT
MAP2:	LD	E,'p'
MAP3:	LD	A,0FFH
	CP	(HL)
	JR	NZ,PRINT
	INC	L
	XOR	A
	CP	L
	JR	NZ,MAP3
	LD	E,'.'
PRINT:	LD	L,0
	DEC	B
	JR	NZ,NLINE
	LD	B,16
	CALL	CRLF
	CALL	HXOT4
NLINE:	LD	A,SPACE
	CALL	OTA
	LD	A,E
	CALL	OTA
	INC	H
	JR	NZ,MAP1
	CALL	CRLF
	CALL	CRLF
	JP	START

;16 HEX OUTPUT ROUTINE

HXOT4:
	LD	C,H
	CALL	HXO2
	LD	C,L
HXO2:	LD	A,C
	RRA
	RRA
	RRA
	RRA
	CALL	HXO3
	LD	A,C
HXO3:	AND 	0FH
	CP	10
	JR	C,HADJ
	ADD	A,7
HADJ:	ADD	A,30H
OTA:	PUSH	BC
	LD	C,A
	CALL	CO
	POP	BC
	RET

;DISPLAY MEMORY IN HEX

DISP:   CALL    EXLF                    ;GET PARAMETERS IN [HL],[DE]
        LD      A,L                     ;ROUND OFF ADDRESSES TO XX00H
        AND     0F0H
        LD      L,A
        LD      A,E                     ;FINAL ADDRESS LOWER HALF
        AND     0F0H
        ADD     A,10H                   ;FINISH TO END 0F LINE
SF172:  CALL    LFADR
SF175:  CALL    BLANK
        LD      A,(HL)
        CALL    LBYTE
        CALL    HILOX
        LD      A,L
        AND     0FH
        JR      NZ,SF175
        LD      C,TAB                   ;INSERT A TAB BETWEEN DATA
        CALL    CO
        LD      B,4H                    ;ALSO 4 SPACES
TA11:   LD      C,SPACE
        CALL    CO
        DJNZ    TA11
        LD      B,16                    ;NOW PRINT ASCII (16 CHARACTERS)
        PUSH    DE                      ;TEMPORLY SAVE [DE]
        LD      DE,0010H
        SBC     HL,DE
        POP     DE
T11:    LD      A,(HL)
        AND     7FH
        CP      ' '                     ;FILTER OUT CONTROL CHARACTERS'
        JR      NC,T33
T22:    LD      A,'.'
T33:    CP      07CH
        JR      NC,T22
        LD      C,A                     ;SET UP TO SEND
        CALL    CO
        INC     HL
        DJNZ    T11                     ;REPEAT FOR WHOLE LINE
        JR      SF172

BLANK:  LD      C,' '
        JP      CO

;INSPECT AND / OR MODIFY MEMORY

SUBS:   LD      C,1
        CALL    HEXSP
        POP     HL
SF2E3:  LD      A,(HL)
        CALL    LBYTE
        LD      C,'-'
        CALL    CO
        CALL    PCHK
        RET     C
        JR      Z,SF2FC
        CP      5FH
        JR      Z,SF305
        PUSH    HL
        CALL    EXF
        POP     DE
        POP     HL
        LD      (HL),E
        LD      A,B
        CP      CR
        RET     Z
SF2FC:  INC     HL
SF2FD:  LD      A,L
        AND     07H
        CALL    Z,LFADR
        JR      SF2E3
SF305:  DEC     HL
        JR      SF2FD

;FILL A BLOCK OF MEMORY WITH A VALUE

FILL:   CALL    EXPR3
SF1A5:  LD      (HL),C
        CALL    HILOX
        JR      NC,SF1A5
        POP     DE
        JP      START

;GO TO A RAM LOCATION

GOTO:   LD      C,1                     ;SIMPLE GOTO FIRST GET PARMS.
        CALL    HEXSP
        CALL    CRLF
        POP     HL                      ;GET PARAMETER PUSHED BY EXF
        JP      (HL)


; GET OR OUTPUT TO A PORT

QUERY:  CALL    PCHK
        CP      'O'                     ;OUTPUT TO PORT
        JR      Z,SF77A
        CP      'I'                     ;INPUT FROM PORT
        JP      Z,QQQ1
        LD      C,'*'
        JP      CO                     ;WILL ABORT IF NOT 'I' OR 'O'
QQQ1:   LD      C,1
        CALL    HEXSP
        POP     BC
        IN      A,(C)
        JP      BITS
;
SF77A:  CALL    HEXSP
        POP     DE
        POP     BC
        OUT     (C),E
        RET

;Display Extended memory map for 1MG RAM using IA-2 Z80 Board window registers

XMEMMAP:
        LD      HL,MSG17                ;Get segment (0-F)
        CALL    ZPMSG
        LD      C,1
        CALL    HEXSP                  ;Get 2 or 4 hex digits (count in C).
        POP     HL
        LD      A,L                     ;Get single byte value
        AND     0FH
        EXX
        LD      D,A                     ;Store in D' for 000X:YYYY display below
        SLA     A
        SLA     A
        SLA     A
        SLA     A
        OUT     (Z80PORT+2),A           ;Re-map to first 16K in segment:64K Space
        LD      E,A                     ;store shifted nibble in E'
        LD      HL,0                    ;Will store 0-FFFF for total RAM display (not actual access)
        EXX
        LD      D,0                     ;Total display line count (256 characters, 16lines X 16 characters)

        CALL    CRLF
        LD      HL,0
        LD      B,1
XMAP1:  LD      A,H
        AND     00111111B               ;Wrap 16K window
        LD      H,A
        LD      E,'R'                   ;PRINT R FOR RAM
        LD      A,(HL)
        CPL
        LD      (HL),A
        CP      (HL)
        CPL
        LD      (HL),A                  ;Save it back
        JR      NZ,XMAP2
        CP      (HL)
        JR      Z,XPRINT
XMAP2:  LD      E,'p'
XMAP3:  LD      A,0FFH
        CP      (HL)
        JR      NZ,XPRINT
        INC     L
        XOR     A
        CP      L
        JR      NZ,XMAP3
        LD      E,'.'
XPRINT: LD      L,0
        DEC     B
        JR      NZ,XNLINE
        LD      B,16
        CALL    CRLF
        CALL    SET_WINDOW
        LD      A,SPACE
        JR      XN11
XNLINE: LD      A,SPACE
        CALL    OTA
        LD      A,E
XN11:   CALL    OTA
        INC     H
        INC     D                       ;Are we done yet
        JR      NZ,XMAP1
        CALL    CRLF
        XOR     A
        OUT     (Z80PORT+2),A           ;Set RAM window back to the way it was
        JP      START

SET_WINDOW:                             ;Setup the unique IA-II Z80 board window to address > 64k
        EXX
        LD      C,D                     ;Print seg value
        CALL    HXO2
        LD      C,':'
        CALL    CO
        CALL    HXOT4                   ;Print HL' (not origional HL)

        LD      A,H                     ;get current H being displayed (Already pointed to first 16K window)
NOTW0:  CP      40H
        JR      NZ,NOTW1
        LD      A,E
        ADD     A,04H                   ;Window for 4,5,6,7, set to H from above
        JR      DOWIN
NOTW1:  CP      80H
        JR      NZ,NOTW2
        LD      A,E
        ADD     A,08H                   ;Window for 8,9,A,B set to H from above
        JR      DOWIN
NOTW2:  CP      0C0H
        JR      NZ,NOTW3                ;Must be values in between
        LD      A,E
        ADD     A,0CH                   ;Window for 4,5,6,7, set to H from above
DOWIN:  OUT     (Z80PORT+2),A           ;Re-map to first 16K in segment:64K Space
NOTW3:  LD      A,H
        ADD     A,10H
        LD      H,A
        EXX                             ;Get back normal register set
        RET




NOTIMPL:
	RET

FBOOT:
	RET

DRIVE_NR_ERR:   .DB      BELL,CR,LF
                .DB      "Drive not Ready.",CR,LF,LF,'$'
RESTORE_ERR:    .DB      BELL,CR,LF
                .DB      "Restore Failed.",CR,LF,LF,'$'
BOOT_LD_ERR:    .DB      BELL,CR,LF
                .DB      "Read Error.",CR,LF,LF,'$'
SEEK_ERROR_MSG: .DB      BELL,CR,LF
                .DB      "Seek Error.",CR,LF,LF,'$'
 
BOOT_LD1_ERR:   .DB      BELL,CR,LF
                .DB      "BOOT error.",CR,LF,LF,'$'

IDE_RW_ERROR:   .DB      CR,LF
                .DB      "IDE Drive R/W Error"
                .DB      CR,LF,'$'

MSG17:	.DB	CR,LF
	.DB	"Segement (0-F):$"
	.END	
