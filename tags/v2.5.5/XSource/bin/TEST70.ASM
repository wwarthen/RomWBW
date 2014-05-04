;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test70.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: TMS7000
;



R0      .equ 0
R1      .equ 1
R2      .equ 2
R3      .equ 3
R12     .equ 12
R13     .equ 13
R7      .equ 7
data1   .equ $34
data2   .equ $1287
table   .equ $1234
P7      .equ 7

        .org $f000
start:
        ADC  B,A
        ADC  %data1,A
        ADC  %data1,B
        ADC  %data1,R7
        ADC  R12,A    
        ADC  R13,B    
        ADC  R12,R7    

        ADD  B,A    
        ADD  %data1,A
        ADD  %data1,B
        ADD  %data1,R7
        ADD  R12,A    
        ADD  R13,B    
        ADD  R12,R7  

        AND  B,A    
        AND  %data1,A
        AND  %data1,B
        AND  %data1,R7
        AND  R12,A    
        AND  R13,B    
        AND  R12,R7  

        ANDP A,R7  
        ANDP B,R7  
        ANDP %data1,R7

        BTJO B,A,start  
        BTJO %data1,A,start 
        BTJO %data1,B,start 
        BTJO %data1,R7,start 
        BTJO R12,A,start  
        BTJO R13,B,start  
        BTJO R12,R7,start  

loop1
         BTJOP   A,P7,loop1 
         BTJOP   B,P7,loop1 
         BTJOP   %data1,P7,loop1

         BTJZ B,A,loop1
         BTJZ %data1,A,loop1
         BTJZ %data1,B,loop1
         BTJZ %data1,R7,loop1
         BTJZ R12,A,loop1  
         BTJZ R12,B,loop1  
         BTJZ R12,R7,loop1  
         
         BTJZP   A,P7,loop1
         BTJZP   B,P7,loop1
         BTJZP   %data1,P7,loop1 
         
         BR      @start(B)
         BR      @start[B]
         BR      @start
         BR      *R7
         
         CALL    @sub1(B)
         CALL    @sub1 
         CALL    *R7 
         
sub1:    CLR     A  
         CLR     B  
         CLR     R12
         
         CLRC    
         
         CMP     B,A
         CMP     %data1,A
         CMP     %data1,B
         CMP     %data1,R7
         CMP     R12,A   
         CMP     R12,B   
         CMP     R12,R7   
         
         CMPA    @R7(B)
         CMPA    @R7[B]
         CMPA    @R7   
         CMPA    *R7   
         
         DAC     B,A     
         DAC     %data1,A
         DAC     %data1,B
         DAC     %data1,R7
         DAC     R12,A   
         DAC     R12,B   
         DAC     R12,R7   
         
         DEC     A       
         DEC     B       
         DEC     R7   
         
         DECD    A       
         DECD    B       
         DECD    R7   
         
         DINT    
         
         DJNZ    A,loop2   
         DJNZ    B,loop2   
         DJNZ    R12,loop2 
         
         DSB     B,A      
         DSB     %data1,A 
         DSB     %data1,B 
         DSB     %data1,R7 
         DSB     R12,A    
         DSB     R12,B    
         DSB     R12,R7    
         
         EINT    
         
         IDLE    
         
         INC     A
         INC     B
         INC     R7
         
         INV     A    
         INV     B    
         INV     R7
loop2:         
         JMP     loop2
         
         JC      loop2
         JEQ     loop2
         JGE     loop2
         JGT     loop2
         JHS     loop2
         JL      loop2
         JN      loop2
         JNC     loop2
         JNE     loop2
         JNZ     loop2
         JP      loop2
         JPZ     loop2
         JZ      loop2
         
         LDA     @table(B)
         LDA     @table   
         LDA     *R7   
         
         LDSP    
         
         MOV     A,B
         MOV     B,A
         MOV     A,R7
         MOV     B,R7
         MOV     %data1,A
         MOV     %data1,B
         MOV     %data1,R7
         MOV     R12,A      
         MOV     R12,B      
         MOV     R12,R7  
         
         MOVD    %data2,R7
         MOVD    %data2[B],R7
         MOVD    R12,R7      
         
         MOVP    A,P7  
         MOVP    B,P7  
         MOVP    %data1,P7
         MOVP    P7,A    
         MOVP    P7,B    
         
         MPY     B,A      
         MPY     %data1,A 
         MPY     %data1,B 
         MPY     %data1,R7
         MPY     R12,A      
         MPY     R12,B      
         MPY     R12,R7  
         
         NOP    
         
         OR      B,A     
         OR      %data1,A
         OR      %data1,B
         OR      %data1,R7
         OR      R12,A      
         OR      R12,B      
         OR      R12,R7  
         
         ORP     A,P7    
         ORP     B,P7    
         ORP     %data1,P7
         
         POP     A      
         POP     B      
         POP     R7  
         
         POPST
         POP     ST
         
         PUSH    A 
         PUSH    B 
         PUSH    R7
         
         PUSHST  
         PUSH    ST 
         
         RETI    
         
         RETS    
         
         RL      A
         RL      B
         RL      R7
         
         RLC     A    
         RLC     B    
         RLC     R7
         
         RR      A    
         RR      B    
         RR      R7
         
         RRC     A    
         RRC     B    
         RRC     R7
         
         SBB     B,A  
         SBB     %data1,A
         SBB     %data1,B
         SBB     %data1,R7
         SBB     R12,A      
         SBB     R12,B      
         SBB     R12,R7  
         
         SETC   
         
         STA     @table(B)
         STA     @table   
         STA     *R7   
         
         STSP    
         
         SUB     B,A
         SUB     %data1,A
         SUB     %data1,B
         SUB     %data1,R7
         SUB     R12,A      
         SUB     R12,B      
         SUB     R12,R7  
         
         SWAP    A       
         SWAP    B       
         SWAP    R7   
         
         TRAP    0
         TRAP    1
         TRAP    6
         TRAP    12
         TRAP    23
         
         TST     A       
         TSTA    
         TST     B
         TSTB    
         
         XCHB    A
         XCHB    R7
         
         XOR     B,A  
         XOR     %data1,A
         XOR     %data1,B
         XOR     %data1,R7
         XOR     R12,A      
         XOR     R12,B      
         XOR     R12,R7  
         
         XORP    A,P7    
         XORP    B,P7    
         XORP    %data1,P7  
         
         
         .end
         
