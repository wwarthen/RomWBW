;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test68.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor:  6801/6803/68HC11
;


data1   .equ    $12
data2   .equ    $1234

        ABA
        ABX

        ADDA #data1      ;8B
        ADDA data1,X     ;AB
        ADDA data1       ;9B
        ADDA data2       ;BB

        ADDB #data1      ;CB
        ADDB data1,X     ;EB
        ADDB data1       ;DB
        ADDB data2       ;FB

        ADCA #data1      ;89
        ADCA data1,X     ;A9
        ADCA data1       ;99
        ADCA data2       ;B9

        ADCB #data1      ;C9
        ADCB data1,X     ;E9
        ADCB data1       ;D9
        ADCB data2       ;F9

        ADDD #data1      ;C3
        ADDD data1,X     ;E3
        ADDD data1       ;D3
        ADDD data2       ;F3

        ANDA #data1      ;84
        ANDA data1,X     ;A4
        ANDA data1       ;94
        ANDA data2       ;B4

        ANDB #data1      ;C4
        ANDB data1,X     ;E4
        ANDB data1       ;D4
        ANDB data2       ;F4

        ASL  data1,X     ;68
        ASL  data1       ;78
        ASL  data2       ;78
        ASLA             ;48
        ASLB             ;58
        ASLD             ;05

        ASR  data1,X     ;  
        ASR  data1       ;  
        ASR  data2       ;  
        ASRA             ;  
        ASRB             ;  

loop1:
        BRA  loop1       ;20
        BRN  loop1       ;21
        BCC  loop1       ;24
        BCS  loop1       ;25
        BEQ  loop1       ;27
        BGE  loop1       ;2C
        BGT  loop1       ;2E
        BHI  loop1       ;22
        BHS  loop1       ;24

        BITA #data1      ;85
        BITA data1,X     ;A5
        BITA data1       ;B5
        BITA data2       ;B5

        BITB #data1      ;C5
        BITB data1,X     ;E5
        BITB data1       ;F5
        BITB data2       ;F5

        BLE  loop1       ;2F
        BLO  loop1       ;25
        BLS  loop1       ;23
        BLT  loop1       ;2D
        BMI  loop1       ;2B
        BNE  loop1       ;26
        BVC  loop1       ;28
        BVS  loop1       ;29
        BPL  loop1       ;2A
        BSR  loop1       ;8D

        CBA
        CLC              ;0C
        CLI              ;0E
        CLR  data1,X     ;6F
        CLR  data1       ;7F
        CLR  data2       ;7F
        CLRA             ;4F
        CLRB             ;5F
        CLV              ;0A

        COM  data1,X     ;63
        COM  data1       ;73
        COM  data2       ;73
        COMA             ;43
        COMB             ;53

        CPX  #data1      ;8C
        CPX  data1,X     ;AC
        CPX  data1       ;9C
        CPX  data2       ;BC

        CMPA #data1      ;  
        CMPA data1,X     ;  
        CMPA data1       ;  
        CMPA data2       ;  

        CMPB #data1      ;  
        CMPB data1,X     ;  
        CMPB data1       ;  
        CMPB data2       ;  

        DAA              ;19

        DEC  data1,X
        DEC  data1
        DEC  data2

        DECA             ;4A
        DECB             ;5A
        DES              ;34
        DEX              ;09

        EORA #data1      ;
        EORA data1,X     ;
        EORA data1       ;
        EORA data2       ;

        EORB #data1      ;
        EORB data1,X     ;
        EORB data1       ;
        EORB data2       ;

        INC  data1,X
        INC  data1
        INC  data2

        INCA             ;4C
        INCB             ;5C
        INS              ;31
        INX              ;08

        JMP  data1,X     ;63
        JMP  data1       ;7E
        JMP  data2       ;7E

        JSR  data1,X     ;AD
        JSR  data1       ;9D
        JSR  data2       ;BD

        LDAA #data1      ;86
        LDAA data1,X     ;A6
        LDAA data1       ;96
        LDAA data2       ;B6

        LDAB #data1      ;C6
        LDAB data1,X     ;E6
        LDAB data1       ;D6
        LDAB data2       ;F6

        LDD  #data1      ;CC
        LDD  data1,X     ;EC
        LDD  data1       ;DC
        LDD  data2       ;FC

        LDS  #data1      ;8E
        LDS  data1,X     ;AE
        LDS  data1       ;9E
        LDS  data2       ;BE

        LDX  #data1      ;CE
        LDX  data1,X     ;EE
        LDX  data1       ;DE
        LDX  data2       ;FE

        LSLA             ;48
        LSLB             ;58
        LSLD             ;05

        LSRA             ;44
        LSRB             ;54
        LSRD             ;04
        LSR  data1,X     ;64
        LSR  data1       ;74
        LSR  data2       ;74

        MUL              ;3D

        NEG  data1,X     ;60
        NEG  data1       ;70
        NEG  data2       ;70
        NEGA             ;40
        NEGB             ;50

        NOP              ;01

        ORAA #data1      ;8A
        ORAA data1,X     ;AA
        ORAA data1       ;BA
        ORAA data2       ;9A

        ORAB #data1      ;CA
        ORAB data1,X     ;EA
        ORAB data1       ;DA
        ORAB data2       ;FA

        PSHA             ;36
        PSHB             ;37
        PSHX             ;3C

        PULA             ;32
        PULB             ;33
        PULX             ;38

        ROL  data1,X     ;69
        ROL  data1       ;79
        ROLA             ;49
        ROLB             ;59

        ROR  data1,X     ;66
        ROR  data1       ;76
        RORA             ;46
        RORB             ;56

        RTI              ;3B
        RTS              ;39

        SBA              ;10

        SBCA #data1      ;82
        SBCA data1,X     ;A2
        SBCA data1       ;92
        SBCA data2       ;B2

        SBCB #data1      ;C2
        SBCB data1,X     ;E2
        SBCB data1       ;D2
        SBCB data2       ;F2

        SEI              ;0F
        SEV              ;0B
        SEC

        STS  data1,X
        STS  data1
        STS  data2

        STAA data1,X     ;A7
        STAA data1       ;97
        STAA data2       ;B7

        STAB data1,X     ;E7
        STAB data1       ;D7
        STAB data2       ;F7

        STD  data1,X     ;ED
        STD  data1       ;DD
        STD  data2       ;FD

        STX  data1,X     ;EF
        STX  data1       ;FF

        SUBA #data1      ;80
        SUBA data1,X     ;A0
        SUBA data1       ;90
        SUBA data2       ;B0

        SUBB #data1      ;C0
        SUBB data1,X     ;E0
        SUBB data1       ;D0
        SUBB data2       ;F0

        SUBD #data1      ;83
        SUBD data1,X     ;A3
        SUBD data1       ;93
        SUBD data2       ;B3

        SWI              ;3F

        TAB              ;16
        TAP              ;06
        TPA              ;07
        TBA              ;17

        TST  data1,X
        TST  data1
        TST  data2

        TSTA             ;4D
        TSTB             ;5D

        TXS              ;35
        TSX              ;30

        WAI              ;3E

;
; Test all the new 68HC11 instructions
;
bmsk    .equ    12h
addr1   .equ    34h
addr2   .equ    5678h
imm     .equ    55h

        ABY                 ;183A
        ADCA    addr1,Y     ;18A9
        ADCB    addr1,Y     ;18E9
        ADDA    addr1,Y     ;18AB
        ADDB    addr1,Y     ;18EB
        ADDD    addr1,Y     ;18E3
        ANDA    addr1,Y     ;18A4
        ANDB    addr1,Y     ;18E4
        ASL     addr1,Y     ;1868
        ASR     addr1,Y     ;1867
lab1        
        BCLR    addr1,Y,bmsk
        BCLR    addr1,X,bmsk
        BCLR    addr1,bmsk 

        BITA    addr1,Y           ;18A5
        BITB    addr1,Y           ;18E5

        BRCLR   addr1,Y,bmsk,lab1
        BRCLR   addr1,X,bmsk,lab1
        BRCLR   addr1,bmsk,lab1 
        BRCLR   addr2,bmsk,lab1 

        BRSET   addr1,Y,bmsk,lab1
        BRSET   addr1,X,bmsk,lab1
        BRSET   addr1,bmsk,lab1 
        BRSET   addr2,bmsk,lab1 

        BSET    addr1,Y,bmsk
        BSET    addr1,X,bmsk
        BSET    addr1,bmsk  

        CLR     addr1,Y     ;186F
        CMPA    addr1,Y     ;18A1
        CMPB    addr1,Y     ;18E1
        COM     addr1,Y     ;1863
        CPD     #imm        ;1A83
        CPD     addr1,X     ;1AA3
        CPD     addr1,Y     ;CDA3
        CPD     addr1       ;1AB3
        CPD     addr2       ;1AB3
        CPX     addr1,Y     ;CDAC
        CPY     #imm        ;188C
        CPY     addr1,Y     ;18AC
        CPY     addr1,X     ;1AAC
        CPY     addr1       ;18BC
        CPY     addr2       ;18BC
        DEC     addr1,Y     ;186A
        DEY                 ;1809
        EORA    addr1,Y     ;18A8
        EORB    addr1,Y     ;18E8
        FDIV                ;03  
        IDIV                ;02  
        INC     addr1,Y     ;186C
        INY                 ;1808
        JMP     addr1,Y     ;186E
        JSR     addr1,Y     ;18AD
        LDAA    addr1,Y     ;18A6
        LDAB    addr1,Y     ;18E6
        LDD     addr1,Y     ;18EC
        LDS     addr1,Y     ;18AE
        LDX     addr1,Y     ;CDEE
        LDY     #imm        ;18CE
        LDY     addr1,Y     ;18EE
        LDY     addr1,X     ;1AEE
        LDY     addr1       ;18FE
        LDY     addr2       ;18FE
        LSL     addr1,Y     ;1868
        LSR     addr1,Y     ;1864
        NEG     addr1,Y     ;1860
        ORAA    addr1,Y     ;18AA
        ORAB    addr1,Y     ;18EA
        PSHY                ;183C
        PULY                ;1838
        ROL     addr1,Y     ;1869
        ROR     addr1,Y     ;1866
        SBCA    addr1,Y     ;18A2
        SBCB    addr1,Y     ;18E2
        STAA    addr1,Y     ;18A7
        STAB    addr1,Y     ;18E7
        STD     addr1,Y     ;18ED
        STS     addr1,Y     ;CDAF
        STX     addr1,Y     ;CDEF
        STY     addr1,Y     ;18EF
        STY     addr1,X     ;1AEF
        STY     addr1       ;18FF
        STY     addr2       ;18FF
        SUBA    addr1,Y     ;18A0
        SUBB    addr1,Y     ;18E0
        SUBD    addr1,Y     ;18A3
        TST     addr1,Y     ;186D
;        TEST                ;
        TSY                 ;1830    2       NOP     4
        TYS                 ;1835    2       NOP     4
        XGDX                ;8F      1       NOP     4
        XGDY                ;188F    2       NOP     4

        .end




