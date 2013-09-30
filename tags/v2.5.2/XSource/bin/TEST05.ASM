;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test05.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor:  6805
;


        .org    0
bit3    .equ    3
data    .equ    $12
        .block  $46
addz    .equ    $46

        .org    $1007
addr:
        ADC  #data       ;A9 2 NOP 1         
        ADC  ,X          ;F9 1 NOP 1           
        ADC  addr,X      ;D9 3 MZERO 1        
        ADC  addz,X      ;D9 3 MZERO 1        
        ADC  addr        ;C9 3 MZERO 1          
        ADC  addz        ;C9 3 MZERO 1          
        
        ADD  #data       ;AB 2 NOP 1         
        ADD  ,X          ;FB 1 NOP 1              
        ADD  addr,X      ;DB 3 MZERO 1        
        ADD  addz,X      ;DB 3 MZERO 1        
        ADD  addr        ;CB 3 MZERO 1          
        ADD  addz        ;CB 3 MZERO 1          
        
        AND  #data       ;A4 2 NOP 1         
        AND  ,X          ;F4 1 NOP 1              
        AND  addr,X      ;D4 3 MZERO 1        
        AND  addz,X      ;D4 3 MZERO 1        
        AND  addr        ;C4 3 MZERO 1          
        AND  addz        ;C4 3 MZERO 1          
        
        ASLA             ;48 1 NOP 1       
        ASLX             ;58 1 NOP 1       
        ASL  ,X          ;78 1 NOP 1              
        ASL  addz,X      ;68 2 NOP 1              
        ASL  addz        ;38 2 NOP 1
     
        ASRA             ;47 1 NOP 1       
        ASRX             ;57 1 NOP 1       
        ASR  ,X          ;77 1 NOP 1              
        ASR  addz,X      ;37 2 NOP 1
        ASR  addz        ;37 2 NOP 1

loop1:
        BCC  loop1       ;24 2 R1  1           
        BCS  loop1       ;25 2 R1  1           
        BEQ  loop1       ;27 2 R1  1           
        BHCC loop1       ;28 2 R1  1           
        BHCS loop1       ;29 2 R1  1           
        BHI  loop1       ;22 2 R1  1
        BHS  loop1       ;24 2 R1  1           
        BIH  loop1       ;2F 2 R1  1           
        BIL  loop1       ;2E 2 R1  1           
        
        BIT  #data       ;A5 2 NOP 1         
        BIT  ,X          ;F5 1 NOP 1              
        BIT  addr,X      ;D5 3 MZERO 1        
        BIT  addz,X      ;C5 3 MZERO 1          
        BIT  addr        ;C5 3 MZERO 1          
        BIT  addz        ;C5 3 MZERO 1          
     
        BLO  loop1       ;25 2 R1  1           
        BLS  loop1       ;23 2 R1  1           
        BMC  loop1       ;2C 2 R1  1           
        BMI  loop1       ;2B 2 R1  1           
        BMS  loop1       ;2D 2 R1  1           
        BNE  loop1       ;26 2 R1  1           
        BPL  loop1       ;2A 2 R1  1           
        BRA  loop1       ;20 2 R1  1           
        BRN  loop1       ;21 2 R1  1           
        BSR  loop1       ;AD 2 R1  1           

        BRCLR bit3,addz,loop1 ;01 3 MBIT 1
        BRSET bit3,addz,loop1 ;00 3 MBIT 1 

        BCLR bit3,addz   ;11 2 MBIT 1    
        BSET bit3,addz   ;10 2 MBIT 1    
        
        CLC              ;98 1 NOP 1     
        CLI              ;9A 1 NOP 1     
        
        CLRA             ;4F 1 NOP 1       
        CLRX             ;5F 1 NOP 1       
        CLR  ,X          ;7F 1 NOP 1              
        CLR  addz,X      ;6F 2 NOP 1              
        CLR  addz        ;3F 2 NOP 1
        
        CMP  #data       ;A1 2 NOP 1         
        CMP  ,X          ;F1 1 NOP 1              
        CMP  addr,X      ;D1 3 MZERO 1        
        CMP  addz,X      ;D1 3 MZERO 1        
        CMP  addr        ;C1 3 MZERO 1          
        CMP  addz        ;C1 3 MZERO 1          
        
        COMA             ;43 1 NOP 1       
        COMX             ;53 1 NOP 1       
        COM  ,X          ;73 1 NOP 1              
        COM  addz,X      ;63 2 NOP 1              
        COM  addz        ;33 2 NOP 1
        
        CPX  #data       ;A3 2 NOP 1         
        CPX  ,X          ;F3 1 NOP 1              
        CPX  addr,X      ;D3 3 MZERO 1        
        CPX  addz,X      ;D3 3 MZERO 1        
        CPX  addr        ;C3 3 MZERO 1          
        CPX  addz        ;C3 3 MZERO 1          
        
        DECA             ;4A 1 NOP 1       
        DECX             ;5A 1 NOP 1       
        DEX              ;5A 1 NOP 1       
        DEC  ,X          ;7A 1 NOP 1              
        DEC  addz,X      ;6A 2 NOP 1              
        DEC  addz        ;3A 2 NOP 1
        
        EOR  #data       ;A8 2 NOP 1         
        EOR  ,X          ;F8 1 NOP 1              
        EOR  addr,X      ;D8 3 MZERO 1        
        EOR  addz,X      ;D8 3 MZERO 1        
        EOR  addr        ;C8 3 MZERO 1          
        EOR  addz        ;C8 3 MZERO 1          
        
        INCA             ;4C 1 NOP 1       
        INCX             ;5C 1 NOP 1       
        INX              ;5C 1 NOP 1       
        INC  ,X          ;7C 1 NOP 1              
        INC  addz,X      ;6C 2 NOP 1              
        INC  addz        ;3C 2 NOP 1
        
        JMP  ,X          ;FC 1 NOP 1              
        JMP  addr,X      ;DC 3 MZERO 1        
        JMP  addz,X      ;DC 3 MZERO 1        
        JMP  addr        ;CC 3 MZERO 1          
        JMP  addz        ;CC 3 MZERO 1          
        
        JSR  ,X          ;FD 1 NOP 1              
        JSR  addr,X      ;DD 3 MZERO 1        
        JSR  addz,X      ;DD 3 MZERO 1        
        JSR  addr        ;CD 3 MZERO 1          
        JSR  addz        ;CD 3 MZERO 1          
        
        LDA  #data       ;A6 2 NOP 1         
        LDA  ,X          ;F6 1 NOP 1              
        LDA  addr,X      ;D6 3 MZERO 1        
        LDA  addz,X      ;D6 3 MZERO 1        
        LDA  addr        ;C6 3 MZERO 1          
        LDA  addz        ;C6 3 MZERO 1          
        
        LDX  #data       ;AE 2 NOP 1         
        LDX  ,X          ;FE 1 NOP 1              
        LDX  addr,X      ;DE 3 MZERO 1        
        LDX  addz,X      ;DE 3 MZERO 1        
        LDX  addr        ;CE 3 MZERO 1          
        LDX  addz        ;CE 3 MZERO 1          
        
        LSLA             ;48 1 NOP 1       
        LSLX             ;58 1 NOP 1       
        LSL  ,X          ;78 1 NOP 1              
        LSL  addz,X      ;68 2 NOP 1              
        LSL  addz        ;38 2 NOP 1
        
        LSRA             ;44 1 NOP 1       
        LSRX             ;54 1 NOP 1       
        LSR  ,X          ;74 1 NOP 1              
        LSR  addz,X      ;64 2 NOP 1              
        LSR  addz        ;34 2 NOP 1
        
        NEGA             ;40 1 NOP 1       
        NEGX             ;50 1 NOP 1       
        NEG  ,X          ;70 1 NOP 1              
        NEG  addz,X      ;60 2 NOP 1              
        NEG  addz        ;30 2 NOP 1
        
        NOP              ;9D 1 NOP 1     
        
        ORA  #data       ;AA 2 NOP 1         
        ORA  ,X          ;FA 1 NOP 1              
        ORA  addr,X      ;DA 3 MZERO 1        
        ORA  addz,X      ;DA 3 MZERO 1        
        ORA  addr        ;CA 3 MZERO 1          
        ORA  addz        ;CA 3 MZERO 1          
        
        ROLA             ;49 1 NOP 1       
        ROLX             ;59 1 NOP 1       
        ROL  ,X          ;79 1 NOP 1              
        ROL  addz,X      ;69 2 NOP 1              
        ROL  addz        ;39 2 NOP 1
        
        RORA             ;46 1 NOP 1       
        RORX             ;56 1 NOP 1       
        ROR  ,X          ;76 1 NOP 1              
        ROR  addz,X      ;66 2 NOP 1              
        ROR  addz        ;36 2 NOP 1
        
        RSP              ;9C 1 NOP 1     
        RTI              ;80 1 NOP 1     
        RTS              ;81 1 NOP 1     
        
        SBC  #data       ;A2 2 NOP 1         
        SBC  ,X          ;F2 1 NOP 1              
        SBC  addr,X      ;D2 3 MZERO 1        
        SBC  addz,X      ;D2 3 MZERO 1        
        SBC  addr        ;C2 3 MZERO 1          
        SBC  addz        ;C2 3 MZERO 1          
        
        SEC              ;99 1 NOP 1     
        SEI              ;9B 1 NOP 1     
        
        STA  ,X          ;F7 1 NOP 1              
        STA  addr,X      ;D7 3 MZERO 1        
        STA  addz,X      ;D7 3 MZERO 1        
        STA  addr        ;C7 3 MZERO 1          
        STA  addz        ;C7 3 MZERO 1          
        
        STOP             ;8E 1 NOP 1     
        
        STX  ,X          ;FF 1 NOP 1              
        STX  addr,X      ;DF 3 MZERO 1        
        STX  addz,X      ;DF 3 MZERO 1        
        STX  addr        ;CF 3 MZERO 1          
        STX  addz        ;CF 3 MZERO 1          
        
        SUB  #data       ;A0 2 NOP 1         
        SUB  ,X          ;F0 1 NOP 1              
        SUB  addr,X      ;D0 3 MZERO 1        
        SUB  addz,X      ;D0 3 MZERO 1        
        SUB  addr        ;C0 3 MZERO 1          
        SUB  addz        ;C0 3 MZERO 1          
        
        SWI              ;83 1 NOP 1     
        
        TAX              ;97 1 NOP 1     
        
        TSTA             ;4D 1 NOP 1       
        TSTX             ;5D 1 NOP 1       
        TST  ,X          ;7D 1 NOP 1              
        TST  addz,X      ;6D 2 NOP 1              
        TST  addz        ;3D 2 NOP 1
        
        TXA              ;9F 1 NOP 1     
        
        WAIT             ;8F 1 NOP 1     
        .end
