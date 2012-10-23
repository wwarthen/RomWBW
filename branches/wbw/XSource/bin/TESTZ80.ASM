;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: testz80.asm 1.4 1998/02/25 12:18:20 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: Z80
;
; SEPT. 16,1987
; CARL A. WALL
;  VE3APY
;
;

#define equ .equ
#define end .end

n:          equ 20h
nn:         equ 0584h
dddd:       equ 07h
addr16:     equ $1234
port:       equ 3
imm8:       equ 56h    ;immediate data (8 bits)
offset:     equ 7
offset_neg: equ -7

;    try a few cases that have two expressions in the args and
;    one is inside ().
     LD   (IX+offset),n+1+4+8-9
     LD   (IX+offset+5),n-1
     LD   (IX+dddd),n
     LD   (IX+offset),n
     LD   (IX+offset),n

;    Try all possible instructions

     ADC  A,(HL)
     ADC  A,(IX+offset)
     ADC  A,(IX+offset_neg)
     ADC  A,(IY+offset)
     ADC  A,(IY+offset_neg)
     ADC  A,A
     ADC  A,B
     ADC  A,C
     ADC  A,D
     ADC  A,E
     ADC  A,H
     ADC  A,L
     ADC  A,n
     ADC  HL,BC
     ADC  HL,DE
     ADC  HL,HL
     ADC  HL,SP

     ADD  A,(HL)
     ADD  A,(IX+offset)
     ADD  A,(IY+offset)
     ADD  A,A
     ADD  A,B
     ADD  A,C
     ADD  A,D
     ADD  A,E
     ADD  A,H
     ADD  A,L
     ADD  A,n
     ADD  HL,BC
     ADD  HL,DE
     ADD  HL,HL
     ADD  HL,SP
     ADD  IX,BC
     ADD  IX,DE
     ADD  IX,IX
     ADD  IX,SP
     ADD  IY,BC
     ADD  IY,DE
     ADD  IY,IY
     ADD  IY,SP

     AND  (HL)
     AND  (IX+offset)
     AND  (IY+offset)
     AND  A
     AND  B
     AND  C
     AND  D
     AND  E
     AND  H
     AND  L
     AND  n

     BIT  0,(HL)
     BIT  0,(IX+offset)
     BIT  0,(IY+offset)
     BIT  0,A
     BIT  0,B
     BIT  0,C
     BIT  0,D
     BIT  0,E
     BIT  0,H
     BIT  0,L

     BIT  1,(HL)
     BIT  1,(IX+offset)
     BIT  1,(IY+offset)
     BIT  1,A
     BIT  1,B
     BIT  1,C
     BIT  1,D
     BIT  1,E
     BIT  1,H
     BIT  1,L

     BIT  2,(HL)
     BIT  2,(IX+offset)
     BIT  2,(IY+offset)
     BIT  2,A
     BIT  2,B
     BIT  2,C
     BIT  2,D
     BIT  2,E
     BIT  2,H
     BIT  2,L

     BIT  3,(HL)
     BIT  3,(IX+offset)
     BIT  3,(IY+offset)
     BIT  3,A
     BIT  3,B
     BIT  3,C
     BIT  3,D
     BIT  3,E
     BIT  3,H
     BIT  3,L

     BIT  4,(HL)
     BIT  4,(IX+offset)
     BIT  4,(IY+offset)
     BIT  4,A
     BIT  4,B
     BIT  4,C
     BIT  4,D
     BIT  4,E
     BIT  4,H
     BIT  4,L

     BIT  5,(HL)
     BIT  5,(IX+offset)
     BIT  5,(IY+offset)
     BIT  5,A
     BIT  5,B
     BIT  5,C
     BIT  5,D
     BIT  5,E
     BIT  5,H
     BIT  5,L

     BIT  6,(HL)
     BIT  6,(IX+offset)
     BIT  6,(IY+offset)
     BIT  6,A
     BIT  6,B
     BIT  6,C
     BIT  6,D
     BIT  6,E
     BIT  6,H
     BIT  6,L

     BIT  7,(HL)
     BIT  7,(IX+offset)
     BIT  7,(IY+offset)
     BIT  7,A
     BIT  7,B
     BIT  7,C
     BIT  7,D
     BIT  7,E
     BIT  7,H
     BIT  7,L

     CALL C,addr16
     CALL M,addr16
     CALL NC,addr16
     CALL NZ,addr16
     CALL P,addr16
     CALL PE,addr16
     CALL PO,addr16
     CALL Z,addr16
     CALL addr16

     CCF

     CP   (HL)
     CP   (IX+offset)
     CP   (IY+offset)
     CP   A
     CP   B
     CP   C
     CP   D
     CP   E
     CP   H
     CP   L
     CP   imm8
     CPD  
     CPDR  
     CPIR   
     CPI   
     CPL   

     DAA   

     DEC  (HL)
     DEC  (IX+offset)
     DEC  (IY+offset)
     DEC  A
     DEC  B
     DEC  BC
     DEC  C
     DEC  D
     DEC  DE
     DEC  E
     DEC  H
     DEC  HL
     DEC  IX
     DEC  IY
     DEC  L
     DEC  SP
     DI
loop1:
     DJNZ loop1

     EI
     EX   (SP),HL
     EX   (SP),IX
     EX   (SP),IY
     EX   AF,AF'
     EX   DE,HL
     EXX    
     HALT     
     
     IM   0
     IM   1
     IM   2

     IN   A,(C)
     IN   B,(C)
     IN   C,(C)
     IN   D,(C)
     IN   E,(C)
     IN   H,(C)
     IN   L,(C)
     IN   A,(port)

     IN0  B,(n)
     IN0  C,(n)
     IN0  D,(n)
     IN0  E,(n)
     IN0  H,(n)
     IN0  L,(n)

     INC  (HL)
     INC  (IX+offset)
     INC  (IY+offset)
     INC  A
     INC  B
     INC  BC
     INC  C
     INC  D
     INC  DE
     INC  E
     INC  H
     INC  HL
     INC  IX
     INC  IY
     INC  L
     INC  SP

     IND     
     INDR     
     INI
     INIR    
     
     JP   addr16
     JP   (HL)
     JP   (IX)
     JP   (IY)
     JP   C,addr16
     JP   M,addr16
     JP   NC,addr16
     JP   NZ,addr16
     JP   P,addr16
     JP   PE,addr16
     JP   PO,addr16
     JP   Z,addr16

loop2:
     JR   C,loop2
     JR   NC,loop2
     JR   NZ,loop2
     JR   Z,loop2
     JR   loop2

     LD   (BC),A
     LD   (DE),A
     LD   (HL),A
     LD   (HL),B
     LD   (HL),C
     LD   (HL),D
     LD   (HL),E
     LD   (HL),H
     LD   (HL),L
     LD   (HL),n
     LD   (IX+offset),A
     LD   (IX+offset),B
     LD   (IX+offset),C
     LD   (IX+offset),D
     LD   (IX+offset),E
     LD   (IX+offset),H
     LD   (IX+offset),L
     LD   (IX+offset),n
     LD   (IY+offset),A
     LD   (IY+offset),B
     LD   (IY+offset),C
     LD   (IY+offset),D
     LD   (IY+offset),E
     LD   (IY+offset),H
     LD   (IY+offset),L
     LD   (IY+offset),n
     LD   (nn),A
     LD   (nn),BC
     LD   (nn),DE
     LD   (nn),HL
     LD   (nn),IX
     LD   (nn),IY
     LD   (nn),SP
     LD   A,(BC)
     LD   A,(DE)
     LD   A,(HL)
     LD   A,(IX+offset)
     LD   A,(IY+offset)
     LD   A,(nn)
     LD   A,A
     LD   A,B
     LD   A,C
     LD   A,D
     LD   A,E
     LD   A,H
     LD   A,I
     LD   A,L
     LD   A,n
     LD   A,R
     LD   B,(HL)
     LD   B,(IX+offset)
     LD   B,(IY+offset)
     LD   B,A
     LD   B,B
     LD   B,C
     LD   B,D
     LD   B,E
     LD   B,H
     LD   B,L
     LD   B,n
     LD   BC,(nn)
     LD   BC,nn
     LD   C,(HL)
     LD   C,(IX+offset)
     LD   C,(IY+offset)
     LD   C,A
     LD   C,B
     LD   C,C
     LD   C,D
     LD   C,E
     LD   C,H
     LD   C,L
     LD   C,n
     LD   D,(HL)
     LD   D,(IX+offset)
     LD   D,(IY+offset)
     LD   D,A
     LD   D,B
     LD   D,C
     LD   D,D
     LD   D,E
     LD   D,H
     LD   D,L
     LD   D,n
     LD   DE,(nn)
     LD   DE,nn
     LD   E,(HL)
     LD   E,(IX+offset)
     LD   E,(IY+offset)
     LD   E,A
     LD   E,B
     LD   E,C
     LD   E,D
     LD   E,E
     LD   E,H
     LD   E,L
     LD   E,n
     LD   H,(HL)
     LD   H,(IX+offset)
     LD   H,(IY+offset)
     LD   H,A
     LD   H,B
     LD   H,C
     LD   H,D
     LD   H,E
     LD   H,H
     LD   H,L
     LD   H,n
     LD   HL,(nn)
     LD   HL,nn
     LD   I,A
     LD   IX,(nn)
     LD   IX,nn
     LD   IY,(nn)
     LD   IY,nn
     LD   L,(HL)
     LD   L,(IX+offset)
     LD   L,(IY+offset)
     LD   L,A
     LD   L,B
     LD   L,C
     LD   L,D
     LD   L,E
     LD   L,H
     LD   L,L
     LD   L,n
     LD   R,A
     LD   SP,(nn)
     LD   SP,HL
     LD   SP,IX
     LD   SP,IY
     LD   SP,nn

     LDD
     LDDR
     LDI
     LDIR

     MLT  BC
     MLT  DE
     MLT  HL
     MLT  SP

     NEG
     NOP

     OR   (HL)
     OR   (IX+offset)
     OR   (IY+offset)
     OR   A
     OR   B
     OR   C
     OR   D
     OR   E
     OR   H
     OR   L
     OR   imm8

     OTDR
     OTIR

     OUT  (C),A
     OUT  (C),B
     OUT  (C),C
     OUT  (C),D
     OUT  (C),E
     OUT  (C),H
     OUT  (C),L
     OUT  (port),A

     OUT0 (imm8),A
     OUT0 (imm8),B
     OUT0 (imm8),C
     OUT0 (imm8),D
     OUT0 (imm8),E
     OUT0 (imm8),H
     OUT0 (imm8),L

     OUTD
     OUTI
     OTIM
     OTDM
     OTIMR
     OTDMR

     POP  AF
     POP  BC
     POP  DE
     POP  HL
     POP  IX
     POP  IY

     PUSH AF
     PUSH BC
     PUSH DE
     PUSH HL
     PUSH IX
     PUSH IY

     RES  0,(HL)
     RES  0,(IX+offset)
     RES  0,(IY+offset)
     RES  0,A
     RES  0,B
     RES  0,C
     RES  0,D
     RES  0,E
     RES  0,H
     RES  0,L

     RES  1,(HL)
     RES  1,(IX+offset)
     RES  1,(IY+offset)
     RES  1,A
     RES  1,B
     RES  1,C
     RES  1,D
     RES  1,E
     RES  1,H
     RES  1,L

     RES  2,(HL)
     RES  2,(IX+offset)
     RES  2,(IY+offset)
     RES  2,A
     RES  2,B
     RES  2,C
     RES  2,D
     RES  2,E
     RES  2,H
     RES  2,L

     RES  3,(HL)
     RES  3,(IX+offset)
     RES  3,(IY+offset)
     RES  3,A
     RES  3,B
     RES  3,C
     RES  3,D
     RES  3,E
     RES  3,H
     RES  3,L

     RES  4,(HL)
     RES  4,(IX+offset)
     RES  4,(IY+offset)
     RES  4,A
     RES  4,B
     RES  4,C
     RES  4,D
     RES  4,E
     RES  4,H
     RES  4,L

     RES  5,(HL)
     RES  5,(IX+offset)
     RES  5,(IY+offset)
     RES  5,A
     RES  5,B
     RES  5,C
     RES  5,D
     RES  5,E
     RES  5,H
     RES  5,L

     RES  6,(HL)
     RES  6,(IX+offset)
     RES  6,(IY+offset)
     RES  6,A
     RES  6,B
     RES  6,C
     RES  6,D
     RES  6,E
     RES  6,H
     RES  6,L

     RES  7,(HL)
     RES  7,(IX+offset)
     RES  7,(IY+offset)
     RES  7,A
     RES  7,B
     RES  7,C
     RES  7,D
     RES  7,E
     RES  7,H
     RES  7,L

     RET
     RET  C
     RET  M
     RET  NC
     RET  NZ
     RET  P
     RET  PE
     RET  PO
     RET  Z
     RETI
     RETN

     RL   (HL)
     RL   (IX+offset)
     RL   (IY+offset)
     RL   A
     RL   B
     RL   C
     RL   D
     RL   E
     RL   H
     RL   L
     RLA

     RLC  (HL)
     RLC  (IX+offset)
     RLC  (IY+offset)
     RLC  A
     RLC  B
     RLC  C
     RLC  D
     RLC  E
     RLC  H
     RLC  L
     RLCA
     RLD

     RR   (HL)
     RR   (IX+offset)
     RR   (IY+offset)
     RR   A
     RR   B
     RR   C
     RR   D
     RR   E
     RR   H
     RR   L
     RRA

     RRC  (HL)
     RRC  (IX+offset)
     RRC  (IY+offset)
     RRC  A
     RRC  B
     RRC  C
     RRC  D
     RRC  E
     RRC  H
     RRC  L
     RRCA
     RRD

     RST  00H
     RST  08H
     RST  10H
     RST  18H
     RST  20H
     RST  28H
     RST  30H
     RST  38H

     SBC  A,n
     SBC  A,(HL)
     SBC  A,(IX+offset)
     SBC  A,(IY+offset)
     SBC  A,A
     SBC  A,B
     SBC  A,C
     SBC  A,D
     SBC  A,E
     SBC  A,H
     SBC  A,L
     SBC  HL,BC
     SBC  HL,DE
     SBC  HL,HL
     SBC  HL,SP
     SCF

     SET  0,(HL)
     SET  0,(IX+offset)
     SET  0,(IY+offset)
     SET  0,A
     SET  0,B
     SET  0,C
     SET  0,D
     SET  0,E
     SET  0,H
     SET  0,L

     SET  1,(HL)
     SET  1,(IX+offset)
     SET  1,(IY+offset)
     SET  1,A
     SET  1,B
     SET  1,C
     SET  1,D
     SET  1,E
     SET  1,H
     SET  1,L

     SET  2,(HL)
     SET  2,(IX+offset)
     SET  2,(IY+offset)
     SET  2,A
     SET  2,B
     SET  2,C
     SET  2,D
     SET  2,E
     SET  2,H
     SET  2,L

     SET  3,(HL)
     SET  3,(IX+offset)
     SET  3,(IY+offset)
     SET  3,A
     SET  3,B
     SET  3,C
     SET  3,D
     SET  3,E
     SET  3,H
     SET  3,L

     SET  4,(HL)
     SET  4,(IX+offset)
     SET  4,(IY+offset)
     SET  4,A
     SET  4,B
     SET  4,C
     SET  4,D
     SET  4,E
     SET  4,H
     SET  4,L

     SET  5,(HL)
     SET  5,(IX+offset)
     SET  5,(IY+offset)
     SET  5,A
     SET  5,B
     SET  5,C
     SET  5,D
     SET  5,E
     SET  5,H
     SET  5,L

     SET  6,(HL)
     SET  6,(IX+offset)
     SET  6,(IY+offset)
     SET  6,A
     SET  6,B
     SET  6,C
     SET  6,D
     SET  6,E
     SET  6,H
     SET  6,L

     SET  7,(HL)
     SET  7,(IX+offset)
     SET  7,(IY+offset)
     SET  7,A
     SET  7,B
     SET  7,C
     SET  7,D
     SET  7,E
     SET  7,H
     SET  7,L

     SLA  (HL)
     SLA  (IX+offset)
     SLA  (IY+offset)
     SLA  A
     SLA  B
     SLA  C
     SLA  D
     SLA  E
     SLA  H
     SLA  L

     SLP

     SRA  (HL)
     SRA  (IX+offset)
     SRA  (IY+offset)
     SRA  A
     SRA  B
     SRA  C
     SRA  D
     SRA  E
     SRA  H
     SRA  L

     SRL  (HL)
     SRL  (IX+offset)
     SRL  (IY+offset)
     SRL  A
     SRL  B
     SRL  C
     SRL  D
     SRL  E
     SRL  H
     SRL  L
     
     SUB  (HL)
     SUB  (IX+offset)
     SUB  (IY+offset)
     SUB  A
     SUB  B
     SUB  C
     SUB  D
     SUB  E
     SUB  H
     SUB  L
     SUB  n

     TST  A
     TST  B
     TST  C
     TST  D
     TST  E
     TST  (HL)
     TST  n

     XOR  (HL)
     XOR  (IX+offset)
     XOR  (IY+offset)
     XOR  A
     XOR  B
     XOR  C
     XOR  D
     XOR  E
     XOR  H
     XOR  L
     XOR  n
     end
