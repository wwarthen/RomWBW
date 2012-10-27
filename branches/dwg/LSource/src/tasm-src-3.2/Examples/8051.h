;*************************************************************
;*  TASM 8051/8052/80154 SFR BIT/BYTE MNEMONIC EQUATES LIST  *
;*************************************************************

P0      .equ    080H    ;Port 0
SP      .equ    081H    ;Stack pointer
DPL     .equ    082H
DPH     .equ    083H
PCON    .equ    087H
TCON    .equ    088H
TMOD    .equ    089H
TL0     .equ    08AH
TL1     .equ    08BH
TH0     .equ    08CH
TH1     .equ    08DH
P1      .equ    090H    ;Port 1
SCON    .equ    098H
SBUF    .equ    099H
P2      .equ    0A0H    ;Port 2
IE      .equ    0A8H
P3      .equ    0B0H    ;Port 3
IP      .equ    0B8H
T2CON   .equ    0C8H    ;8052, 80154 only
RCAP2L  .equ    0CAH    ;8052, 80154 only
RCAP2H  .equ    0CBH    ;8052, 80154 only
TL2     .equ    0CCH    ;8052, 80154 only
TH2     .equ    0CDH    ;8052, 80154 only
PSW     .equ    0D0H
ACC     .equ    0E0H    ;Accumulator
B       .equ    0F0H    ;Secondary Accumulator
IOCON   .equ    0F8H    ;80154 only

;PORT 0 BITS
P0.0    .equ    080H    ;Port 0 bit 0
P0.1    .equ    081H    ;Port 0 bit 1
P0.2    .equ    082H    ;Port 0 bit 2
P0.3    .equ    083H    ;Port 0 bit 3
P0.4    .equ    084H    ;Port 0 bit 4
P0.5    .equ    085H    ;Port 0 bit 5
P0.6    .equ    086H    ;Port 0 bit 6
P0.7    .equ    087H    ;Port 0 bit 7

;PORT 1 BITS
P1.0    .equ    090H    ;Port 1 bit 0
P1.1    .equ    091H    ;Port 1 bit 1
P1.2    .equ    092H    ;Port 1 bit 2
P1.3    .equ    093H    ;Port 1 bit 3
P1.4    .equ    094H    ;Port 1 bit 4
P1.5    .equ    095H    ;Port 1 bit 5
P1.6    .equ    096H    ;Port 1 bit 6
P1.7    .equ    097H    ;Port 1 bit 7

;PORT 2 BITS
P2.0    .equ    0A0H    ;Port 2 bit 0
P2.1    .equ    0A1H    ;Port 2 bit 1
P2.2    .equ    0A2H    ;Port 2 bit 2
P2.3    .equ    0A3H    ;Port 2 bit 3
P2.4    .equ    0A4H    ;Port 2 bit 4
P2.5    .equ    0A5H    ;Port 2 bit 5
P2.6    .equ    0A6H    ;Port 2 bit 6
P2.7    .equ    0A7H    ;Port 2 bit 7

;PORT 3 BITS
P3.0    .equ    0B0H    ;Port 3 bit 0
P3.1    .equ    0B1H    ;Port 3 bit 1
P3.2    .equ    0B2H    ;Port 3 bit 2
P3.3    .equ    0B3H    ;Port 3 bit 3
P3.4    .equ    0B4H    ;Port 3 bit 4
P3.5    .equ    0B5H    ;Port 3 bit 5
P3.6    .equ    0B6H    ;Port 3 bit 6
P3.7    .equ    0B7H    ;Port 3 bit 7

;ACCUMULATOR BITS
ACC.0   .equ    0E0H    ;Acc bit 0
ACC.1   .equ    0E1H    ;Acc bit 1
ACC.2   .equ    0E2H    ;Acc bit 2
ACC.3   .equ    0E3H    ;Acc bit 3
ACC.4   .equ    0E4H    ;Acc bit 4
ACC.5   .equ    0E5H    ;Acc bit 5
ACC.6   .equ    0E6H    ;Acc bit 6
ACC.7   .equ    0E7H    ;Acc bit 7

;B REGISTER BITS
B.0     .equ    0F0H    ;Breg bit 0
B.1     .equ    0F1H    ;Breg bit 1
B.2     .equ    0F2H    ;Breg bit 2
B.3     .equ    0F3H    ;Breg bit 3
B.4     .equ    0F4H    ;Breg bit 4
B.5     .equ    0F5H    ;Breg bit 5
B.6     .equ    0F6H    ;Breg bit 6
B.7     .equ    0F7H    ;Breg bit 7

;PSW REGISTER BITS
P       .equ    0D0H    ;Parity flag
F1      .equ    0D1H    ;User flag 1
OV      .equ    0D2H    ;Overflow flag
RS0     .equ    0D3H    ;Register bank select 1
RS1     .equ    0D4H    ;Register bank select 0
F0      .equ    0D5H    ;User flag 0
AC      .equ    0D6H    ;Auxiliary carry flag
CY      .equ    0D7H    ;Carry flag

;TCON REGISTER BITS
IT0     .equ    088H    ;Intr 0 type control
IE0     .equ    089H    ;Intr 0 edge flag
IT1     .equ    08AH    ;Intr 1 type control
IE1     .equ    08BH    ;Intr 1 edge flag
TR0     .equ    08CH    ;Timer 0 run
TF0     .equ    08DH    ;Timer 0 overflow
TR1     .equ    08EH    ;Timer 1 run
TF1     .equ    08FH    ;Timer 1 overflow

;SCON REGISTER BITS
RI      .equ    098H    ;RX Intr flag
TI      .equ    099H    ;TX Intr flag
RB8     .equ    09AH    ;RX 9th bit
TB8     .equ    09BH    ;TX 9th bit
REN     .equ    09CH    ;Enable RX flag
SM2     .equ    09DH    ;8/9 bit select flag
SM1     .equ    09EH    ;Serial mode bit 1
SM0     .equ    09FH    ;Serial mode bit 0

;IE REGISTER BITS
EX0     .equ    0A8H    ;External intr 0
ET0     .equ    0A9H    ;Timer 0 intr
EX1     .equ    0AAH    ;External intr 1
ET1     .equ    0ABH    ;Timer 1 intr
ES      .equ    0ACH    ;Serial port intr
ET2     .equ    0ADH    ;Timer 2 intr
;Reserved       0AEH    Reserved
EA      .equ    0AFH    ;Global intr enable

;IP REGISTER BITS
PX0     .equ    0B8H    ;Priority level-External intr 0
PT0     .equ    0B9H    ;Priority level-Timer 0 intr
PX1     .equ    0BAH    ;Priority level-External intr 1
PT1     .equ    0BBH    ;Priority level-Timer 1 intr
PS      .equ    0BCH    ;Priority level-Serial port intr
PT2     .equ    0BDH    ;Priority level-Timer 2 intr
;Reserved       0BEH    Reserved
PCT     .equ    0BFH    ;Global priority level

;IOCON REGISTER BITS  80154 ONLY
ALF     .equ    0F8H    ;Power down port condition
P1HZ    .equ    0F9H    ;Port 1 control
P2HZ    .equ    0FAH    ;Port 2 control
P3HZ    .equ    0FBH    ;Port 3 control
IZC     .equ    0FCH    ;Pullup select
SERR    .equ    0FDH    ;Serial reception error
T32     .equ    0FEH    ;32 bit timer config
WDT     .equ    0FFH    ;Watchdog config

;T2CON REGISTER BITS  8052/80154 ONLY
CP/RL2  .equ    0C8H    ;Timer 2 capture/reload flag
C/T2    .equ    0C9H    ;Timer 2 timer/counter select
TR2     .equ    0CAH    ;Timer 2 start/stop
EXEN2   .equ    0CBH    ;Timer 2 external enable
TCLK    .equ    0CCH    ;TX clock flag
RCLK    .equ    0CDH    ;RX clock flag
EXF2    .equ    0CEH    ;Timer 2 external flag
TF2     .equ    0CFH    ;Timer 2 overflow

