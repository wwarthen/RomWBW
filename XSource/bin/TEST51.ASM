;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test51.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: 8051
;


        .AVSYM

labimm:  .EQU    56h
lab2:    .EQU    12h
lab3:    .EQU    1234h
lab5:    .EQU    0feh
labbt_1: .EQU    34h
bit      .equ    81h


        ACALL lab4    ;11    2   JMP 1
lab4:        
        ADD  A,R0     ;28    1   NOP 1
        ADD  A,R1     ;29    1   NOP 1
        ADD  A,R2     ;2A    1   NOP 1
        ADD  A,R3     ;2B    1   NOP 1
        ADD  A,R4     ;2C    1   NOP 1
        ADD  A,R5     ;2D    1   NOP 1
        ADD  A,R6     ;2E    1   NOP 1
        ADD  A,R7     ;2F    1   NOP 1
        ADD  A,@R0    ;26    1   NOP 1
        ADD  A,@R1    ;27    1   NOP 1
        ADD  A,#labimm   ;24    2   NOP 1
        ADD  A,lab2      ;25    2   NOP 1
        
        ADDC A,R0     ;38    1   NOP 1
        ADDC A,R1     ;39    1   NOP 1
        ADDC A,R2     ;3A    1   NOP 1
        ADDC A,R3     ;3B    1   NOP 1
        ADDC A,R4     ;3C    1   NOP 1
        ADDC A,R5     ;3D    1   NOP 1
        ADDC A,R6     ;3E    1   NOP 1
        ADDC A,R7     ;3F    1   NOP 1
        ADDC A,@R0    ;36    1   NOP 1
        ADDC A,@R1    ;37    1   NOP 1
        ADDC A,#labimm     ;34    2   NOP 1
        ADDC A,lab2      ;35    2   NOP 1
        
        AJMP jlab     ;01    2   JMP 1
        
        ANL  A,R0     ;58    1   NOP 1
        ANL  A,R1     ;59    1   NOP 1
        ANL  A,R2     ;5A    1   NOP 1
        ANL  A,R3     ;5B    1   NOP 1
        ANL  A,R4     ;5C    1   NOP 1
        ANL  A,R5     ;5D    1   NOP 1
        ANL  A,R6     ;5E    1   NOP 1
        ANL  A,R7     ;5F    1   NOP 1
        ANL  A,@R0    ;56    1   NOP 1
        ANL  A,@R1    ;57    1   NOP 1
        ANL  A,#labimm
        ANL  A,lab2
        ANL  C,/bit
        ANL  C,bit
        ANL  lab2,A
        ANL  lab2,#labimm
        
        CJNE A,#labimm,jlab   ;b4    3   CR  1
        CJNE A,lab2,jlab      ;b5    3   CR  1
        CJNE R0,#labimm,jlab  ;b8    3   CR  1
        CJNE R1,#labimm,jlab  ;b9    3   CR  1
        CJNE R2,#labimm,jlab  ;ba    3   CR  1
        CJNE R3,#labimm,jlab  ;bb    3   CR  1
        CJNE R4,#labimm,jlab  ;bc    3   CR  1
        CJNE R5,#labimm,jlab  ;bd    3   CR  1
        CJNE R6,#labimm,jlab  ;be    3   CR  1
        CJNE R7,#labimm,jlab  ;bf    3   CR  1
        CJNE @R0,#labimm,jlab ;b6    3   CR  1
        CJNE @R1,#labimm,jlab ;b7    3   CR  1
        
        CLR  A        ;e4    1   NOP 1
        CLR  C        ;c3    1   NOP 1
        CLR  bit
        
        CPL  A        ;f4    1   NOP 1
        CPL  C        ;b3    1   NOP 1
        CPL  bit
        
        DA   A        ;d4    1   NOP 1
        
        DEC  A        ;14    1   NOP 1
        DEC  R0       ;18    1   NOP 1
        DEC  R1       ;19    1   NOP 1
        DEC  R2       ;1A    1   NOP 1
        DEC  R3       ;1B    1   NOP 1
        DEC  R4       ;1C    1   NOP 1
        DEC  R5       ;1D    1   NOP 1
        DEC  R6       ;1E    1   NOP 1
        DEC  R7       ;1F    1   NOP 1
        DEC  @R0      ;16    1   NOP 1
        DEC  @R1      ;17    1   NOP 1
        DEC  lab2     ;15    2   NOP 1
        
        DIV  AB       ;84    1   NOP 1
        
        DJNZ R0,jlab     ;d8    2   NOP 1
        DJNZ R1,jlab     ;d9    2   NOP 1
        DJNZ R2,jlab     ;dA    2   NOP 1
        DJNZ R3,jlab     ;dB    2   NOP 1
        DJNZ R4,jlab     ;dC    2   NOP 1
        DJNZ R5,jlab     ;dD    2   NOP 1
        DJNZ R6,jlab     ;dE    2   NOP 1
        DJNZ R7,jlab     ;dF    2   NOP 1
        DJNZ lab2,jlab   ;d5    3   CR  1
        
        INC  A        ;04    1   NOP 1
        INC  R0       ;08    1   NOP 1
        INC  R1       ;09    1   NOP 1
        INC  R2       ;0A    1   NOP 1
        INC  R3       ;0B    1   NOP 1
        INC  R4       ;0C    1   NOP 1
        INC  R5       ;0D    1   NOP 1
        INC  R6       ;0E    1   NOP 1
        INC  R7       ;0F    1   NOP 1
        INC  @R0      ;06    1   NOP 1
        INC  @R1      ;07    1   NOP 1
        INC  DPTR     ;a3    1   NOP 1
        INC  lab2     ;05    2   NOP 1

jlab:        
        JB   labbt_1,jlab   ;20    3   CR  1
        JBC  labbt_1,jlab   ;10    3   CR  1
        JC   jlab            ;40    2   R1  1
        JMP  @A+DPTR         ;73    1   NOP 1
        JNB  labbt_1,jlab   ;30    3   CR  1
        JNC  jlab            ;50    2   R1  1
        JNZ  jlab            ;70    2   R1  1
        JZ   jlab            ;60    2   R1  1
        
        LCALL lab3       ;12    3   SWAP 1
        
        LJMP lab3        ;02    3   SWAP 1
        
        MOV  A,R0           ;e8    1   NOP 1
        MOV  A,R1           ;e9    1   NOP 1
        MOV  A,R2           ;eA    1   NOP 1
        MOV  A,R3           ;eB    1   NOP 1
        MOV  A,R4           ;eC    1   NOP 1
        MOV  A,R5           ;eD    1   NOP 1
        MOV  A,R6           ;eE    1   NOP 1
        MOV  A,R7           ;eF    1   NOP 1
        MOV  A,@R0          ;e6    1   NOP 1
        MOV  A,@R1          ;e7    1   NOP 1
        MOV  A,#labimm      ;74    2   NOP 1
        MOV  A,lab2         ;e5    2   NOP 1
        MOV  C,bit          ;a2    2   NOP 1
        MOV  DPTR,#labimm   ;90    3   SWAP 1
        MOV  R0,A           ;f8    1   NOP 1
        MOV  R1,A           ;f9    1   NOP 1
        MOV  R2,A           ;fA    1   NOP 1
        MOV  R3,A           ;fB    1   NOP 1
        MOV  R4,A           ;fC    1   NOP 1
        MOV  R5,A           ;fD    1   NOP 1
        MOV  R6,A           ;fE    1   NOP 1
        MOV  R7,A           ;fF    1   NOP 1
        MOV  R0,#labimm     ;78    2   NOP 1
        MOV  R1,#labimm     ;79    2   NOP 1
        MOV  R2,#labimm     ;7A    2   NOP 1
        MOV  R3,#labimm     ;7B    2   NOP 1
        MOV  R4,#labimm     ;7C    2   NOP 1
        MOV  R5,#labimm     ;7D    2   NOP 1
        MOV  R6,#labimm     ;7E    2   NOP 1
        MOV  R7,#labimm     ;7F    2   NOP 1
        MOV  R0,lab2        ;a8    2   NOP 1
        MOV  R1,lab2        ;a9    2   NOP 1
        MOV  R2,lab2        ;aA    2   NOP 1
        MOV  R3,lab2        ;aB    2   NOP 1
        MOV  R4,lab2        ;aC    2   NOP 1
        MOV  R5,lab2        ;aD    2   NOP 1
        MOV  R6,lab2        ;aE    2   NOP 1
        MOV  R7,lab2        ;aF    2   NOP 1
        MOV  @R0,A          ;f6    1   NOP 1
        MOV  @R1,A          ;f7    1   NOP 1
        MOV  @R0,#labimm    ;76    2   NOP 1
        MOV  @R1,#labimm    ;77    2   NOP 1
        MOV  @R0,lab2       ;a6    2   NOP 1
        MOV  @R1,lab2       ;a7    2   NOP 1
        MOV  lab2,A         ;f5    2   NOP 1
        MOV  bit,C          ;92    2   NOP 1
        MOV  lab2,R0        ;88    2   NOP 1
        MOV  lab2,R1        ;89    2   NOP 1
        MOV  lab2,R2        ;8A    2   NOP 1
        MOV  lab2,R3        ;8B    2   NOP 1
        MOV  lab2,R4        ;8C    2   NOP 1
        MOV  lab2,R5        ;8D    2   NOP 1
        MOV  lab2,R6        ;8E    2   NOP 1
        MOV  lab2,R7        ;8F    2   NOP 1
        MOV  lab2,@R0       ;86    2   NOP 1
        MOV  lab2,@R1       ;87    2   NOP 1
        MOV  lab2,#labimm   ;75    3   COMBINE	1
        MOV  lab5,lab2      ;85    3   COMBINE  1
        
        MOVC A,@A+DPTR ;93   1   NOP 1
        MOVC A,@A+PC   ;83    1   NOP 1
        
        MOVX A,@R0    ;e2    1   NOP 1
        MOVX A,@R1    ;e3    1   NOP 1
        MOVX A,@DPTR  ;e0    1   NOP 1
        MOVX @R0,A    ;f2    1   NOP 1
        MOVX @R1,A    ;f3    1   NOP 1
        MOVX @DPTR,A  ;f0    1   NOP 1
        
        MUL  AB       ;a4    1   NOP 1
        
        NOP           ;00    1   NOP 1
        
        ORL  A,R0     ;48    1   NOP 1
        ORL  A,R1     ;49    1   NOP 1
        ORL  A,R2     ;4A    1   NOP 1
        ORL  A,R3     ;4B    1   NOP 1
        ORL  A,R4     ;4C    1   NOP 1
        ORL  A,R5     ;4D    1   NOP 1
        ORL  A,R6     ;4E    1   NOP 1
        ORL  A,R7     ;4F    1   NOP 1
        ORL  A,@R0    ;46    1   NOP 1
        ORL  A,@R1    ;47    1   NOP 1
        ORL  A,#labimm     ;44    2   NOP 1
        ORL  A,lab2      ;45    2   NOP 1
        ORL  C,/bit      ;a0    2   NOP 1
        ORL  C,bit       ;72    2   NOP 1
        ORL  lab2,A      ;42    2   NOP 1
        ORL  lab2,#labimm     ;43    3   COMBINE 1
        
        POP  lab2     ;d0    2   NOP 1
        PUSH lab2     ;c0    2   NOP 1
        
        RET           ;22    1   NOP 1
        RETI          ;32    1   NOP 1
        
        RL   A        ;23    1   NOP 1
        RLC  A        ;33    1   NOP 1
        RR   A        ;03    1   NOP 1
        RRC  A        ;13    1   NOP 1
        
jlab5:
        SETB C        ;d3    1   NOP 1
        SETB bit      ;d2    2   NOP 1
        
        SJMP jlab5    ;80    2   NOP 1
        
        SUBB A,R0     ;98    1   NOP 1
        SUBB A,R1     ;99    1   NOP 1
        SUBB A,R2     ;9A    1   NOP 1
        SUBB A,R3     ;9B    1   NOP 1
        SUBB A,R4     ;9C    1   NOP 1
        SUBB A,R5     ;9D    1   NOP 1
        SUBB A,R6     ;9E    1   NOP 1
        SUBB A,R7     ;9F    1   NOP 1
        SUBB A,@R0    ;96    1   NOP 1
        SUBB A,@R1    ;97    1   NOP 1
        SUBB A,#labimm     ;94    2   NOP 1
        SUBB A,lab2      ;95    2   NOP 1
        
        SWAP A        ;c4    1   NOP 1
        
        XCH  A,R0     ;c8    1   NOP 1
        XCH  A,R1     ;c9    1   NOP 1
        XCH  A,R2     ;cA    1   NOP 1
        XCH  A,R3     ;cB    1   NOP 1
        XCH  A,R4     ;cC    1   NOP 1
        XCH  A,R5     ;cD    1   NOP 1
        XCH  A,R6     ;cE    1   NOP 1
        XCH  A,R7     ;cF    1   NOP 1
        XCH  A,@R0    ;c6    1   NOP 1
        XCH  A,@R1    ;c7    1   NOP 1
        XCH  A,lab2      ;c5    2   NOP 1
        
        XCHD A,@R0    ;d6    1   NOP 1
        XCHD A,@R1    ;d7    1   NOP 1
        
        XRL  A,R0     ;68    1   NOP 1
        XRL  A,R1     ;69    1   NOP 1
        XRL  A,R2     ;6A    1   NOP 1
        XRL  A,R3     ;6B    1   NOP 1
        XRL  A,R4     ;6C    1   NOP 1
        XRL  A,R5     ;6D    1   NOP 1
        XRL  A,R6     ;6E    1   NOP 1
        XRL  A,R7     ;6F    1   NOP 1
        XRL  A,@R0    ;66    1   NOP 1
        XRL  A,@R1    ;67    1   NOP 1
        XRL  A,#labimm     ;64    2   NOP 1
        XRL  A,lab2        ;65    2   NOP 1
        XRL  lab2,A        ;62    2   NOP 1
        XRL  lab2,#labimm  ;63    3   COMBINE 1

        .end
