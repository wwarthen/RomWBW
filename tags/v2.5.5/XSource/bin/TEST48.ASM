;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test48.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: 8048
;


label1  .equ    12H

        ADD  A,R0     
        ADD  A,R1     
        ADD  A,R2     
        ADD  A,R3     
        ADD  A,R4     
        ADD  A,R5     
        ADD  A,R6     
        ADD  A,R7     
        ADD  A,@R0    
        ADD  A,@R1    
        ADD  A,#label1     
        
        ADDC A,R0     
        ADDC A,R1     
        ADDC A,R2     
        ADDC A,R3     
        ADDC A,R4     
        ADDC A,R5     
        ADDC A,R6     
        ADDC A,R7     
        ADDC A,@R0    
        ADDC A,@R1    
        ADDC A,#label1     
        
        ANL  A,R0     
        ANL  A,R1     
        ANL  A,R2     
        ANL  A,R3     
        ANL  A,R4     
        ANL  A,R5     
        ANL  A,R6     
        ANL  A,R7     
        ANL  A,@R0    
        ANL  A,@R1    
        ANL  A,#label1     
        ANL  BUS,#label1   
        ANL  P1,#label1    
        ANL  P2,#label1    
        
        ANLD P4,A     
        ANLD P5,A     
        ANLD P6,A     
        ANLD P7,A     
        
        CALL label1        
        
        CLR  A        
        CLR  C        
        CLR  F0       
        CLR  F1       
        
        CPL  A        
        CPL  C        
        CPL  F0       
        CPL  F1       
        
        DA   A        
        
        DEC  A        
        DEC  R0       
        DEC  R1       
        DEC  R2       
        DEC  R3       
        DEC  R4       
        DEC  R5       
        DEC  R6       
        DEC  R7       
        
        DIS  I        
        DIS  TCNTI    
        
        DJNZ R0,label1     
        DJNZ R1,label1     
        DJNZ R2,label1     
        DJNZ R3,label1     
        DJNZ R4,label1     
        DJNZ R5,label1     
        DJNZ R6,label1     
        DJNZ R7,label1     
        
        EN   DMA      
        EN   FLAGS    
        EN   I        
        EN   TCNTI    
        ENT0 CLK      
        
        IN   A,DBB    
        IN   A,P0     
        IN   A,P1     
        IN   A,P2     
        
        INC  A        
        INC  R0       
        INC  R1       
        INC  R2       
        INC  R3       
        INC  R4       
        INC  R5       
        INC  R6       
        INC  R7       
        INC  @R0      
        INC  @R1      
        
        INS  A,BUS    
        
        JB0  label1        
        JB1  label1        
        JB2  label1        
        JB3  label1        
        JB4  label1        
        JB5  label1        
        JB6  label1        
        JB7  label1        
        
        JMP  label1        
        
        JC   label1        
        JF0  label1        
        JF1  label1        
        JNC  label1        
        JNI  label1        
        JNIBF label1       
        JNT0 label1        
        JNT1 label1        
        JNZ  label1        
        JOBF label1        
        JTF  label1        
        JT0  label1        
        JT1  label1        
        JZ   label1        
        
        JMPP @A       
        
        MOV  A,PSW    
        MOV  A,R0     
        MOV  A,R1     
        MOV  A,R2     
        MOV  A,R3     
        MOV  A,R4     
        MOV  A,R5     
        MOV  A,R6     
        MOV  A,R7     
        MOV  A,T      
        MOV  A,@R0    
        MOV  A,@R1    
        MOV  A,#label1     
        MOV  PSW,A    
        MOV  R0,A     
        MOV  R1,A     
        MOV  R2,A     
        MOV  R3,A     
        MOV  R4,A     
        MOV  R5,A     
        MOV  R6,A     
        MOV  R7,A     
        MOV  R0,#label1    
        MOV  R1,#label1    
        MOV  R2,#label1    
        MOV  R3,#label1    
        MOV  R4,#label1    
        MOV  R5,#label1    
        MOV  R6,#label1    
        MOV  R7,#label1    
        MOV  STS,A    
        MOV  T,A      
        MOV  @R0,A    
        MOV  @R1,A    
        MOV  @R0,#label1   
        MOV  @R1,#label1   
        
        MOVD A,P4     
        MOVD A,P5     
        MOVD A,P6     
        MOVD A,P7     
        MOVD P4,A     
        MOVD P5,A     
        MOVD P6,A     
        MOVD P7,A     
        
        MOVP  A,@A    
        MOVP3 A,@A    
        
        
        MOVX A,@R0    
        MOVX A,@R1    
        MOVX @R0,A    
        MOVX @R1,A    
        
        NOP         
        
        ORL  A,R0     
        ORL  A,R1     
        ORL  A,R2     
        ORL  A,R3     
        ORL  A,R4     
        ORL  A,R5     
        ORL  A,R6     
        ORL  A,R7     
        ORL  A,@R0    
        ORL  A,@R1    
        ORL  A,#label1     
        ORL  BUS,#label1   
        ORL  P1,#label1    
        ORL  P2,#label1    
        
        ORLD P4,A     
        ORLD P5,A     
        ORLD P6,A     
        ORLD P7,A     
        
        OUTL BUS,A    
        OUT  DBB,A    
        OUTL P0,A     
        OUTL P1,A     
        OUTL P2,A     
        
        RAD         
        
        RET  
        RETI 
        RETR 
        
        RL   A
        RLC  A
        RR   A
        RRC  A
        
        SEL  AN0      
        SEL  AN1      
        SEL  MB0      
        SEL  MB1      
        SEL  RB0      
        SEL  RB1      
        
        STOP TCNT     
        STRT CNT      
        STRT T        
        
        SWAP A        
        
        XCH  A,R0     
        XCH  A,R1     
        XCH  A,R2     
        XCH  A,R3     
        XCH  A,R4     
        XCH  A,R5     
        XCH  A,R6     
        XCH  A,R7     
        XCH  A,@R0    
        XCH  A,@R1    
        
        XCHD A,@R0    
        XCHD A,@R1    
        
        XRL  A,R0     
        XRL  A,R1     
        XRL  A,R2     
        XRL  A,R3     
        XRL  A,R4     
        XRL  A,R5     
        XRL  A,R6     
        XRL  A,R7     
        XRL  A,@R0    
        XRL  A,@R1    
        XRL  A,#label1     
        .end
