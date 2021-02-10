;
;==================================================================================================
; ACIA DRIVER (SERIAL PORT)
;==================================================================================================
;
;  SETUP PARAMETER WORD:
;  +-------+---+-------------------+ +---+---+-----------+---+-------+
;  |       |RTS| ENCODED BAUD RATE | |DTR|XON|  PARITY   |STP| 8/7/6 |
;  +-------+---+---+---------------+ ----+---+-----------+---+-------+
;    F   E   D   C   B   A   9   8     7   6   5   4   3   2   1   0
;       -- MSB (D REGISTER) --           -- LSB (E REGISTER) --
;
;
;  ACIA STATUS REGISTER:
;
;       D7      D6      D5      D4      D3      D2      D1      D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | /IRQ  | PE    | OVRN  | FE    | /CTS  | /DCD  | TDRE  | RDRF  |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  ACIA CONTROL REGISTER:
;
;       D7      D6      D5      D4      D3      D2      D1      D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | RIE   | TC2   | TC1   | WS3   | WS2   | WS1   | CDS2  | CDS1  |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;       RIE:    RECEIVE INTERRUPT ENABLE (RECEIVE DATA REGISTER FULL)
;
;       TC:     TRANSMIT CONTROL (TRANSMIT DATA REGISTER EMPTY)
;               0 0 - /RTS=LOW, TDRE INT DISABLED
;               0 1 - /RTS=LOW, TDRE INT ENABLED
;               1 0 - /RTS=HIGH, TDRE INT DISABLED
;               1 1 - /RTS=LOW, TRANSMIT BREAK, TDRE INT DISABLED
;        
;       WS:     WORD SELECT (DATA BITS, PARITY, STOP BITS)
;               0 0 0 - 7,E,2
;               0 0 1 - 7,O,2
;               0 1 0 - 7,E,1
;               0 1 1 - 7,O,1
;               1 0 0 - 8,N,2
;               1 0 1 - 8,N,1
;               1 1 0 - 8,E,1
;               1 1 1 - 8,O,1
;
;       CDS:    COUNTER DIVIDE SELECT
;               0 0 - DIVIDE BY 1
;               0 1 - DIVIDE BY 16
;               1 0 - DIVIDE BY 64
;               1 1 - MASTER RESET
;
ACIA_BUFSZ      .EQU    32              ; RECEIVE RING BUFFER SIZE
;
ACIA_NONE       .EQU    0
ACIA_ACIA       .EQU    1
;
ACIA_RTSON      .EQU    %10111111       ; BIT MASK TO ASSERT RTS
ACIA_RTSOFF     .EQU    %01000000       ; BIT MASK TO DEASSERT RTS
;
;
;
ACIA_PREINIT:
;
; SETUP THE DISPATCH TABLE ENTRIES
; NOTE: INTS WILL BE DISABLED WHEN PREINIT IS CALLED AND THEY MUST REMIAIN
; DISABLED.
;
        LD      B,ACIA_CFGCNT           ; LOOP CONTROL
        XOR     A                       ; ZERO TO ACCUM
        LD      (ACIA_DEV),A            ; CURRENT DEVICE NUMBER
        LD      IY,ACIA_CFG             ; POINT TO START OF CFG TABLE
ACIA_PREINIT0:
        PUSH    BC                      ; SAVE LOOP CONTROL
        CALL    ACIA_INITUNIT           ; HAND OFF TO GENERIC INIT CODE
        POP     BC                      ; RESTORE LOOP CONTROL
;
        LD      A,(IY+1)                ; GET THE ACIA TYPE DETECTED
        OR      A                       ; SET FLAGS
        JR      Z,ACIA_PREINIT2         ; SKIP IT IF NOTHING FOUND
;        
        PUSH    BC                      ; SAVE LOOP CONTROL
        PUSH    IY                      ; CFG ENTRY ADDRESS
        POP     DE                      ; ... TO DE
        LD      BC,ACIA_FNTBL           ; BC := FUNCTION TABLE ADDRESS
        CALL    NZ,CIO_ADDENT           ; ADD ENTRY IF ACIA FOUND, BC:DE
        POP     BC                      ; RESTORE LOOP CONTROL
;
ACIA_PREINIT2:        
        LD      DE,ACIA_CFGSIZ          ; SIZE OF CFG ENTRY
        ADD     IY,DE                   ; BUMP IY TO NEXT ENTRY
        DJNZ    ACIA_PREINIT0           ; LOOP UNTIL DONE
;
ACIA_PREINIT3:
        XOR     A                       ; SIGNAL SUCCESS
        RET                             ; AND RETURN
;
; ACIA INITIALIZATION ROUTINE
;
ACIA_INITUNIT:
        CALL    ACIA_DETECT             ; DETERMINE ACIA TYPE
        LD      (IY+1),A                ; SAVE IN CONFIG TABLE
        OR      A                       ; SET FLAGS
        RET     Z                       ; ABORT IF NOTHING THERE

        ; UPDATE WORKING ACIA DEVICE NUM
        LD      HL,ACIA_DEV             ; POINT TO CURRENT UART DEVICE NUM
        LD      A,(HL)                  ; PUT IN ACCUM
        INC     (HL)                    ; INCREMENT IT (FOR NEXT LOOP)
        LD      (IY),A                  ; UPDATE UNIT NUM
;
#IF (INTMODE == 1)
        ; ADD IM1 INT CALL LIST ENTRY
        LD      L,(IY+8)                ; GET INT HANDLER PTR
        LD      H,(IY+9)                ; ... INTO HL
        CALL    HB_ADDIM1               ; ADD TO IM1 CALL LIST
#ENDIF
;
        ; IT IS EASY TO SPECIFY A SERIAL CONFIG THAT CANNOT BE IMPLEMENTED
        ; DUE TO THE CONSTRAINTS OF THE ACIA.  HERE WE FORCE A GENERIC
        ; FAILSAFE CONFIG ONTO THE CHANNEL.  IF THE SUBSEQUENT "REAL"
        ; CONFIG FAILS, AT LEAST THE CHIP WILL BE ABLE TO SPIT DATA OUT
        ; AT A RATIONAL BAUD/DATA/PARITY/STOP CONFIG.
        CALL    ACIA_INITSAFE
;
        ; SET DEFAULT CONFIG
        LD      DE,-1                   ; LEAVE CONFIG ALONE
        ; CALL INITDEV TO IMPLEMENT CONFIG, BUT NOTE THAT WE CALL
        ; THE INITDEV ENTRY POINT THAT DOES NOT ENABLE/DISABLE INTS!
        JP      ACIA_INITDEVX           ; IMPLEMENT IT AND RETURN
;
;
;
ACIA_INIT:
        LD      B,ACIA_CFGCNT           ; COUNT OF POSSIBLE ACIA UNITS
        LD      IY,ACIA_CFG             ; POINT TO START OF CFG TABLE
ACIA_INIT1:
        PUSH    BC                      ; SAVE LOOP CONTROL
        LD      A,(IY+1)                ; GET ACIA TYPE
        OR      A                       ; SET FLAGS
        CALL    NZ,ACIA_PRTCFG          ; PRINT IF NOT ZERO
        POP     BC                      ; RESTORE LOOP CONTROL
        LD      DE,ACIA_CFGSIZ          ; SIZE OF CFG ENTRY
        ADD     IY,DE                   ; BUMP IY TO NEXT ENTRY
        DJNZ    ACIA_INIT1              ; LOOP TILL DONE
;
        XOR     A                       ; SIGNAL SUCCESS
        RET                             ; DONE
;
; INTERRUPT HANDLERS
;
#IF (INTMODE != 1)
;
; NO INTERRUPT HANDLERS UNDER INTMODE 0.  GENERATE A PANIC
; IF SOMETHING TRIES TO CALL THEM.
;
ACIA0_INT:
ACIA1_INT:
        CALL    PANIC                   ; NO RETURN
;
#ENDIF
;
#IF (INTMODE == 1)
;
ACIA0_INT:
        LD      IY,ACIA0_CFG            ; POINT TO ACIA0 CFG
        JR      ACIA_INTRCV             ; TRY TO RECEIVE FROM IT AND RETURN
;
#IF (ACIACNT >= 2)
;
ACIA1_INT:
        LD      IY,ACIA1_CFG            ; POINT TO ACIA1 CFG
        JR      ACIA_INTRCV             ; TRY TO RECEIVE FROM IT AND RETURN
;
#ENDIF
;
; HANDLE INT FOR A SPECIFIC CHANNEL
; BASED ON UNIT CFG POINTED TO BY IY
;
ACIA_INTRCV:
        ; CHECK TO SEE IF SOMETHING IS ACTUALLY THERE
        LD      C,(IY+3)                ; CMD/STAT PORT TO C
        IN      A,(C)                   ; GET STATUS
        RRA                             ; READY BIT TO CF
        RET     NC                      ; NOTHING AVAILABLE ON CURRENT CHANNEL
;
ACIA_INTRCV1:
        ; RECEIVE CHARACTER INTO BUFFER
        INC     C                       ; DATA PORT
        IN      A,(C)                   ; READ PORT
        DEC     C                       ; BACK TO CONTROL PORT
        LD      B,A                     ; SAVE BYTE READ
        LD      L,(IY+6)                ; SET HL TO
        LD      H,(IY+7)                ; ... START OF BUFFER STRUCT
        LD      A,(HL)                  ; GET COUNT
        CP      ACIA_BUFSZ              ; COMPARE TO BUFFER SIZE
        JR      Z,ACIA_INTRCV4          ; BAIL OUT IF BUFFER FULL, RCV BYTE DISCARDED
        INC     A                       ; INCREMENT THE COUNT
        LD      (HL),A                  ; AND SAVE IT
        CP      ACIA_BUFSZ / 2          ; BUFFER GETTING FULL?
        JR      NZ,ACIA_INTRCV2         ; IF NOT, BYPASS CLEARING RTS
        LD      A,(ACIA_CMD)            ; CONFIG BYTE W/O RTS BIT
        OR      ACIA_RTSOFF             ; DEASSERT RTS
        OUT     (C),A                   ; DO IT
ACIA_INTRCV2:
        INC     HL                      ; HL NOW HAS ADR OF HEAD PTR
        PUSH    HL                      ; SAVE ADR OF HEAD PTR
        LD      A,(HL)                  ; DEREFERENCE HL
        INC     HL
        LD      H,(HL)
        LD      L,A                     ; HL IS NOW ACTUAL HEAD PTR
        LD      (HL),B                  ; SAVE CHARACTER RECEIVED IN BUFFER AT HEAD
        INC     HL                      ; BUMP HEAD POINTER
        POP     DE                      ; RECOVER ADR OF HEAD PTR
        LD      A,L                     ; GET LOW BYTE OF HEAD PTR
        SUB     ACIA_BUFSZ+4            ; SUBTRACT SIZE OF BUFFER AND POINTER
        CP      E                       ; IF EQUAL TO START, HEAD PTR IS PAST BUF END
        JR      NZ,ACIA_INTRCV3         ; IF NOT, BYPASS
        LD      H,D                     ; SET HL TO
        LD      L,E                     ; ... HEAD PTR ADR
        INC     HL                      ; BUMP PAST HEAD PTR
        INC     HL
        INC     HL
        INC     HL                      ; ... SO HL NOW HAS ADR OF ACTUAL BUFFER START
ACIA_INTRCV3:
        EX      DE,HL                   ; DE := HEAD PTR VAL, HL := ADR OF HEAD PTR
        LD      (HL),E                  ; SAVE UPDATED HEAD PTR
        INC     HL
        LD      (HL),D
        ; CHECK FOR MORE PENDING...
        IN      A,(C)                   ; GET STATUS
        RRA                             ; READY BIT TO CF
        JR      C,ACIA_INTRCV1          ; IF SET, DO SOME MORE
ACIA_INTRCV4:
        OR      $FF                     ; NZ SET TO INDICATE INT HANDLED
        RET                             ; AND RETURN
;
#ENDIF
;
; DRIVER FUNCTION TABLE
;
ACIA_FNTBL:
        .DW     ACIA_IN
        .DW     ACIA_OUT
        .DW     ACIA_IST
        .DW     ACIA_OST
        .DW     ACIA_INITDEV
        .DW     ACIA_QUERY
        .DW     ACIA_DEVICE
#IF (($ - ACIA_FNTBL) != (CIO_FNCNT * 2))
        .ECHO   "*** INVALID ACIA FUNCTION TABLE ***\n"
        !!!     ; FORCE AN ASSEMBLY ERROR
#ENDIF
;
;
;
#IF (INTMODE != 1)
;
ACIA_IN:
        CALL    ACIA_IST                ; CHAR WAITING?
        JR      Z,ACIA_IN               ; LOOP IF NOT
        LD      C,(IY+3)                ; C := ACIA BASE PORT
        INC     C                       ; BUMP TO DATA PORT
        IN      E,(C)                   ; GET BYTE
        XOR     A                       ; SIGNAL SUCCESS
        RET
;
#ELSE
;
ACIA_IN:
        CALL    ACIA_IST                ; SEE IF CHAR AVAILABLE
        JR      Z,ACIA_IN               ; LOOP UNTIL SO
        HB_DI                           ; AVOID COLLISION WITH INT HANDLER
        LD      L,(IY+6)                ; SET HL TO
        LD      H,(IY+7)                ; ... START OF BUFFER STRUCT
        LD      A,(HL)                  ; GET COUNT
        DEC     A                       ; DECREMENT COUNT
        LD      (HL),A                  ; SAVE UPDATED COUNT
        CP      ACIA_BUFSZ / 4          ; BUFFER LOW THRESHOLD
        JR      NZ,ACIA_IN1             ; IF NOT, BYPASS SETTING RTS
        LD      C,(IY+3)                ; C IS CMD/STATUS PORT ADR
        LD      A,(ACIA_CMD)            ; CONFIG BYTE W/O RTS BIT
        AND     ACIA_RTSON              ; ASSERT RTS
        OUT     (C),A                   ; DO IT
ACIA_IN1:
        INC     HL
        INC     HL
        INC     HL                      ; HL NOW HAS ADR OF TAIL PTR
        PUSH    HL                      ; SAVE ADR OF TAIL PTR
        LD      A,(HL)                  ; DEREFERENCE HL
        INC     HL
        LD      H,(HL)
        LD      L,A                     ; HL IS NOW ACTUAL TAIL PTR
        LD      C,(HL)                  ; C := CHAR TO BE RETURNED
        INC     HL                      ; BUMP TAIL PTR
        POP     DE                      ; RECOVER ADR OF TAIL PTR
        LD      A,L                     ; GET LOW BYTE OF TAIL PTR
        SUB     ACIA_BUFSZ+2            ; SUBTRACT SIZE OF BUFFER AND POINTER
        CP      E                       ; IF EQUAL TO START, TAIL PTR IS PAST BUF END
        JR      NZ,ACIA_IN2             ; IF NOT, BYPASS
        LD      H,D                     ; SET HL TO
        LD      L,E                     ; ... TAIL PTR ADR
        INC     HL                      ; BUMP PAST TAIL PTR
        INC     HL                      ; ... SO HL NOW HAS ADR OF ACTUAL BUFFER START
ACIA_IN2:
        EX      DE,HL                   ; DE := TAIL PTR VAL, HL := ADR OF TAIL PTR
        LD      (HL),E                  ; SAVE UPDATED TAIL PTR
        INC     HL
        LD      (HL),D
        LD      E,C                     ; MOVE CHAR TO RETURN TO E
        HB_EI                           ; INTERRUPTS OK AGAIN
        XOR     A                       ; SIGNAL SUCCESS
        RET                             ; AND DONE
;
#ENDIF
;
;
;
ACIA_OUT:
        CALL    ACIA_OST                ; READY FOR CHAR?
        JR      Z,ACIA_OUT              ; LOOP IF NOT
        LD      C,(IY+3)                ; C := ACIA CMD PORT
        INC     C                       ; BUMP TO DATA PORT
        OUT     (C),E                   ; SEND CHAR FROM E
        XOR     A                       ; SIGNAL SUCCESS
        RET
;
;
;
#IF (INTMODE != 1)
;
ACIA_IST:
        LD      C,(IY+3)                ; STATUS PORT
        IN      A,(C)                   ; GET STATUS
        AND     $01                     ; ISOLATE BIT 0 (RX READY)
        JP      Z,CIO_IDLE              ; NOT READY, RETURN VIA IDLE PROCESSING
        XOR     A                       ; ZERO ACCUM
        INC     A                       ; ASCCUM := 1 TO SIGNAL 1 CHAR WAITING
        RET                             ; DONE
;
#ELSE
;
ACIA_IST:
        LD      L,(IY+6)                ; GET ADDRESS
        LD      H,(IY+7)                ; ... OF RECEIVE BUFFER
        LD      A,(HL)                  ; BUFFER UTILIZATION COUNT
        OR      A                       ; SET FLAGS
        JP      Z,CIO_IDLE              ; NOT READY, RETURN VIA IDLE PROCESSING
        RET
;
#ENDIF
;
;
;
ACIA_OST:
        LD      C,(IY+3)                ; CMD PORT
        IN      A,(C)                   ; GET STATUS
        AND     $02                     ; ISOLATE BIT 2 (TX EMPTY)
        JP      Z,CIO_IDLE              ; NOT READY, RETURN VIA IDLE PROCESSING
        XOR     A                       ; ZERO ACCUM
        INC     A                       ; ACCUM := 1 TO SIGNAL 1 BUFFER POSITION
        RET                             ; DONE
;
;
;
ACIA_INITDEV:
        HB_DI                           ; AVOID CONFLICTS
        CALL    ACIA_INITDEVX           ; DO THE REAL WORK
        HB_EI                           ; INTS BACK ON
        RET                             ; DONE
;
; THIS ENTRY POINT BYPASSES DISABLING/ENABLING INTS WHICH IS REQUIRED BY
; PREINIT ABOVE.  PREINIT IS NOT ALLOWED TO ENABLE INTS!
;
ACIA_INITDEVX:
;
#IF (ACIADEBUG)
        CALL    NEWLINE
        PRTS("ACIA$")
        LD      A,(IY+2)
        CALL    PRTDECB
        CALL    COUT
        CALL    PC_COLON
#ENDIF
;
        ; TEST FOR -1 WHICH MEANS USE CURRENT CONFIG (JUST REINIT)
        LD      A,D                     ; TEST DE FOR
        AND     E                       ; ... VALUE OF -1
        INC     A                       ; ... SO Z SET IF -1
        JR      NZ,ACIA_INITDEV1        ; IF DE == -1, REINIT CURRENT CONFIG
;
        ; LOAD EXISTING CONFIG TO REINIT
        LD      E,(IY+4)                ; LOW BYTE
        LD      D,(IY+5)                ; HIGH BYTE        
;
ACIA_INITDEV1:
        LD      (ACIA_NEWCFG),DE        ; SAVE NEW CONFIG
;
#IF (ACIADEBUG)
        PUSH    DE
        POP     BC
        PRTS(" CFG=$")
        CALL    PRTHEXWORD
#ENDIF
;
        LD      A,E                     ; GET CONFIG LSB
        AND     $E0                     ; CHECK FOR DTR, XON, PARITY=MARK/SPACE
        JR      NZ,ACIA_INITFAIL        ; IF ANY BIT SET, FAIL, NOT SUPPORTED
;
        LD      A,D                     ; GET CONFIG MSB
        AND     $1F                     ; ISOLATE ENCODED BAUD RATE
;
#IF (ACIADEBUG)
        PRTS(" ENC=$")
        CALL    PRTHEXBYTE
#ENDIF
;
        ; BAUD RATE
        PUSH    DE                      ; SAVE REQUESTED CONFIG
        LD      L,(IY+10)               ; LOAD CLK FREQ
        LD      H,(IY+11)               ; ... INTO DE:HL
        LD      E,(IY+12)               ; ... "
        LD      D,(IY+13)               ; ... "
        LD      C,75                    ; BAUD RATE ENCODING CONSTANT
        CALL    ENCODE                  ; C = TEST BAUD RATE (ENCODED) = BAUDTST
        POP     DE                      ; GET REQ CONFIG BACK, D = BAUDREQ
;
        ; BIT 4 (DIV 3) OF BAUDREQ AND BAUDTST MUST MATCH!
        LD      A,C                     ; A = BAUDTST
        XOR     D                       ; XOR WITH BAUDREQ
        BIT     4,A                     ; DO BIT 4 VALS MATCH?
        JR      NZ,ACIA_INITFAIL        ; IF NOT, BAIL OUT
;        
        LD      A,C                     ; BAUDTST TO A
        AND     $0F                     ; ISOLATE DIV 2 BAUD BITS
        LD      C,A                     ; C = BAUDTST
;        
        LD      A,D                     ; MSB W/ BAUD RATE TO A
        AND     $0F                     ; ISOLATE DIV 2 BAUD BITS
        LD      L,A                     ; L = BAUDREQ
;        
        LD      A,C                     ; A = BAUDTST
        LD      B,%00000000             ; ACIA VAL FOR DIV 1
        CP      L                       ; BAUDTST = BAUDREQ?
        JR      Z,ACIA_INITBROK         ; IF MATCH, WE ARE DONE
;        
        SUB     4                       ; DIVIDE BY 16 (NOW DIV 16 TOT)
        JR      C,ACIA_INITFAIL         ; FAIL IF UNDERFLOW
        LD      B,%00000001             ; ACIA VAL FOR DIV 16
        CP      L                       ; BAUDTST = BAUDREQ?
        JR      Z,ACIA_INITBROK         ; IF MATCH, WE ARE DONE
;        
        SUB     2                       ; DIVIDE BY 4 (NOW DIV 64 TOT)
        JR      C,ACIA_INITFAIL         ; FAIL IF UNDERFLOW
        LD      B,%00000010             ; ACIA R4 VAL FOR DIV 32
        CP      L                       ; BAUDTST = BAUDREQ?
        JR      Z,ACIA_INITBROK         ; IF MATCH, WE ARE DONE
;
ACIA_INITFAIL:
;
#IF (ACIADEBUG)
        PRTS(" BAD CFG$")        
#ENDIF
;
        OR      $FF
        RET                             ; INVALID CONFIG
;        
ACIA_INITBROK:
        ; REG B HAS WORKING CONFIG VALUE W/ BAUD RATE BITS
        LD      C,B                     ; WORKING VAL TO C
        LD      A,E                     ; LSB OF INCOMING CONFIG
        AND     %00111111               ; ISOLATE LOW 6 BITS TO COMPARE
        LD      B,8                     ; WORD SELECT TABLE SIZE
        LD      HL,ACIA_WSTBL           ; POINT TO TABLE
ACIA_INITWS:
        CP      (HL)                    ; MATCH?
        JR      Z,ACIA_INITWS2          ; IF SO, REG B HAS ACIA VAL + 1
        INC     HL                      ; NEXT ENTRY
        DJNZ    ACIA_INITWS             ; KEEP CHECKING TILL DONE
        JR      ACIA_INITFAIL           ; FAIL IF NO MATCH
        
ACIA_WSTBL:
        .DB     %00001011               ; 8/O/1
        .DB     %00011011               ; 8/E/1
        .DB     %00000011               ; 8/N/1
        .DB     %00000111               ; 8/N/2
        .DB     %00001010               ; 7/O/1
        .DB     %00011010               ; 7/E/1
        .DB     %00001110               ; 7/O/2
        .DB     %00011110               ; 7/E/2

ACIA_INITWS2:
        LD      A,B                     ; PUT FANAL VALUE IN A
        DEC     A                       ; ZERO INDEX ADJUSTMENT
        RLA                             ; MOVE BITS TO
        RLA                             ; ... PROPER LOCATION
        OR      C                       ; COMBINE WITH WORKING VALUE
;
        ; SAVE CONFIG PERMANENTLY NOW
        LD      DE,(ACIA_NEWCFG)        ; GET NEW CONFIG BACK
        LD      (IY+4),E                ; SAVE LOW WORD
        LD      (IY+5),D                ; SAVE HI WORD
;
        JR      ACIA_INITGO
;
ACIA_INITSAFE:
        LD      A,%00010110             ; DEFAULT CONFIG
;
ACIA_INITGO:
;
#IF (INTMODE == 1)
        OR      %10000000               ; ENABLE RCV INT
#ENDIF
;
        LD      (ACIA_CMD),A            ; SAVE SHADOW REGISTER
;
#IF (ACIADEBUG)
        PRTS(" CMD=$")
        CALL    PRTHEXBYTE
        LD      DE,65
        CALL    VDELAY                  ; WAIT FOR FINAL CHAR TO SEND
#ENDIF
;
        ; PROGRAM THE ACIA CHIP
        LD      C,(IY+3)                ; COMMAND PORT
        LD      A,$03                   ; MASTER RESET
        OUT     (C),A                   ; DO IT
        LD      A,(ACIA_CMD)            ; RESTORE CONFIG VALUE
        OUT     (C),A                   ; DO IT
;
#IF (INTMODE == 1)
;
        ; RESET THE RECEIVE BUFFER
        LD      E,(IY+6)
        LD      D,(IY+7)                ; DE := _CNT
        XOR     A                       ; A := 0
        LD      (DE),A                  ; _CNT = 0
        INC     DE                      ; DE := ADR OF _HD
        PUSH    DE                      ; SAVE IT
        INC     DE
        INC     DE
        INC     DE
        INC     DE                      ; DE := ADR OF _BUF
        POP     HL                      ; HL := ADR OF _HD
        LD      (HL),E
        INC     HL
        LD      (HL),D                  ; _HD := _BUF
        INC     HL
        LD      (HL),E
        INC     HL
        LD      (HL),D                  ; _TL := _BUF
;
#ENDIF
;
        XOR     A                       ; SIGNAL SUCCESS
        RET                             ; RETURN
;
;
;
ACIA_QUERY:
        LD      E,(IY+4)                ; FIRST CONFIG BYTE TO E
        LD      D,(IY+5)                ; SECOND CONFIG BYTE TO D
        XOR     A                       ; SIGNAL SUCCESS
        RET                             ; DONE
;
;
;
ACIA_DEVICE:
        LD      D,CIODEV_ACIA           ; D := DEVICE TYPE
        LD      E,(IY)                  ; E := PHYSICAL UNIT
        LD      C,$00                   ; C := DEVICE TYPE, 0x00 IS RS-232
        LD      H,0                     ; H := 0, DRIVER HAS NO MODES
        LD      L,(IY+3)                ; L := BASE I/O ADDRESS
        XOR     A                       ; SIGNAL SUCCESS
        RET
;
; ACIA DETECTION ROUTINE
;
ACIA_DETECT:
        LD      A,(IY+3)                ; BASE PORT ADDRESS
        LD      C,A                     ; PUT IN C FOR I/O
        CALL    ACIA_DETECT2            ; CHECK IT
        JR      Z,ACIA_DETECT1          ; FOUND IT, RECORD IT
        LD      A,ACIA_NONE             ; NOTHING FOUND
        RET                             ; DONE
;       
ACIA_DETECT1:   
        ; ACIA FOUND, RECORD IT 
        LD      A,ACIA_ACIA             ; RETURN CHIP TYPE
        RET                             ; DONE
;
ACIA_DETECT2:
        ; LOOK FOR ACIA AT PORT ADDRESS IN C
        LD      A,$03                   ; MASTER RESET
        OUT     (C),A                   ; DO IT
        IN      A,(C)                   ; GET STATUS
        OR      A                       ; CHECK FOR ZERO
        RET     NZ                      ; RETURN IF NOT ZERO
        LD      A,$02                   ; CLEAR MASTER RESET
        OUT     (C),A                   ; DO IT
        IN      A,(C)                   ; GET STATUS AGAIN
        ; CHECK FOR EXPECTED BITS:
        ;   TDRE=1, DCD & CTS = 0
        AND     %00001110               ; BIT MASK FOR "STABLE" BITS
        CP      %00000010               ; EXPECTED VALUE
        RET                             ; RETURN RESULT, Z = CHIP FOUND
;
;
;
ACIA_PRTCFG:
        ; ANNOUNCE PORT
        CALL    NEWLINE                 ; FORMATTING
        PRTS("ACIA$")                   ; FORMATTING
        LD      A,(IY)                  ; DEVICE NUM
        CALL    PRTDECB                 ; PRINT DEVICE NUM
        PRTS(": IO=0x$")                ; FORMATTING
        LD      A,(IY+3)                ; GET BASE PORT
        CALL    PRTHEXBYTE              ; PRINT BASE PORT

        ; PRINT THE ACIA TYPE
        CALL    PC_SPACE                ; FORMATTING
        LD      A,(IY+1)                ; GET ACIA TYPE BYTE
        RLCA                            ; MAKE IT A WORD OFFSET
        LD      HL,ACIA_TYPE_MAP        ; POINT HL TO TYPE MAP TABLE
        CALL    ADDHLA                  ; HL := ENTRY
        LD      E,(HL)                  ; DEREFERENCE
        INC     HL                      ; ...
        LD      D,(HL)                  ; ... TO GET STRING POINTER
        CALL    WRITESTR                ; PRINT IT
;
        ; ALL DONE IF NO ACIA WAS DETECTED
        LD      A,(IY+1)                ; GET ACIA TYPE BYTE
        OR      A                       ; SET FLAGS
        RET     Z                       ; IF ZERO, NOT PRESENT
;
        PRTS(" MODE=$")                 ; FORMATTING
        LD      E,(IY+4)                ; LOAD CONFIG
        LD      D,(IY+5)                ; ... WORD TO DE
        CALL    PS_PRTSC0               ; PRINT CONFIG
;
        XOR     A
        RET
;
;
;
ACIA_TYPE_MAP:
                .DW     ACIA_STR_NONE
                .DW     ACIA_STR_ACIA

ACIA_STR_NONE   .DB     "<NOT PRESENT>$"
ACIA_STR_ACIA   .DB     "ACIA$"
;
; WORKING VARIABLES
;
ACIA_DEV        .DB     0               ; DEVICE NUM USED DURING INIT
ACIA_CMD        .DB     0               ; COMMAND PORT SHADOW REGISTER
ACIA_NEWCFG     .DW     0               ; TEMP STORE FOR NEW CFG
;
#IF (INTMODE != 1)
;
ACIA0_RCVBUF    .EQU    0
ACIA1_RCVBUF    .EQU    0
;
#ELSE
;
; RECEIVE BUFFERS
;
ACIA0_RCVBUF:
ACIA0_BUFCNT    .DB     0               ; CHARACTERS IN RING BUFFER
ACIA0_HD        .DW     ACIA0_BUF       ; BUFFER HEAD POINTER
ACIA0_TL        .DW     ACIA0_BUF       ; BUFFER TAIL POINTER
ACIA0_BUF       .FILL   ACIA_BUFSZ,0    ; RECEIVE RING BUFFER
ACIA0_BUFEND    .EQU    $               ; END OF BUFFER
ACIA0_BUFSZ     .EQU    $ - ACIA0_BUF   ; SIZE OF RING BUFFER
;
#IF (ACIACNT >= 2)
;
ACIA1_RCVBUF:
ACIA1_BUFCNT    .DB     0               ; CHARACTERS IN RING BUFFER
ACIA1_HD        .DW     ACIA1_BUF       ; BUFFER HEAD POINTER
ACIA1_TL        .DW     ACIA1_BUF       ; BUFFER TAIL POINTER
ACIA1_BUF       .FILL   ACIA_BUFSZ,0    ; RECEIVE RING BUFFER
ACIA1_BUFEND    .EQU    $               ; END OF BUFFER
ACIA1_BUFSZ     .EQU    $ - ACIA1_BUF   ; SIZE OF RING BUFFER
;
#ENDIF
;
#ENDIF
;
; ACIA PORT TABLE
;
ACIA_CFG:
;
ACIA0_CFG:
        ; ACIA MODULE A CONFIG
        .DB     0                       ; DEVICE NUMBER (SET DURING INIT)
        .DB     0                       ; ACIA TYPE (SET DURING INIT)
        .DB     0                       ; MODULE ID
        .DB     ACIA0BASE               ; BASE PORT
        .DW     ACIA0CFG                ; LINE CONFIGURATION
        .DW     ACIA0_RCVBUF            ; POINTER TO RCV BUFFER STRUCT
        .DW     ACIA0_INT                ; INT HANDLER POINTER
        .DW     (ACIA0CLK / ACIA0DIV) & $FFFF   ; CLOCK FREQ AS
        .DW     (ACIA0CLK / ACIA0DIV) >> 16     ; ... DWORD VALUE
;
ACIA_CFGSIZ     .EQU    $ - ACIA_CFG    ; SIZE OF ONE CFG TABLE ENTRY
;
#IF (ACIACNT >= 2)
;
ACIA1_CFG:
        ; ACIA MODULE B CONFIG
        .DB     0                       ; DEVICE NUMBER (SET DURING INIT)
        .DB     0                       ; ACIA TYPE (SET DURING INIT)
        .DB     1                       ; MODULE ID
        .DB     ACIA1BASE               ; BASE PORT
        .DW     ACIA1CFG                ; LINE CONFIGURATION
        .DW     ACIA1_RCVBUF            ; POINTER TO RCV BUFFER STRUCT
        .DW     ACIA1_INT                ; INT HANDLER POINTER
        .DW     (ACIA1CLK / ACIA1DIV) & $FFFF   ; CLOCK FREQ AS
        .DW     (ACIA1CLK / ACIA1DIV) >> 16     ; ... DWORD VALUE
;
#ENDIF
;
ACIA_CFGCNT     .EQU    ($ - ACIA_CFG) / ACIA_CFGSIZ
