	.Title	"RTC"
;
; Program:	rtc.asm
; Author:	Andrew Lynch
; Date:		22 Feb 2007
; Enviroment:	TASM MS-DOS Z80 Cross Assembler source for CP/M
;
;[2011/8/11] VK5DG modified for N8
; Changed base address to $88
; Changed trickle charger value to 2k+2 diodes for DS1210s
;
;[2012/2/7] WBW modified to build for either
;           traditional N8VEM/Zeta or N8 via conditionals
;
;[2013/12/29] WBW modified to build for MK4
;
;[2017/11/29] WBW modified to adjust to RTC in use dynamically
;             using HBIOS platform detection
;
;[2018/11/8] v1.2 PMS Add boot option. Code optimization.
;
;[2019/06/21] v1.3 Finalized RCBus Z180 support.
;
;[2019/08/11] v1.4 Support SCZ180 platform.
;
;[2020/02/02] v1.5 PMS Basic command line support
;
;[2020/05/15] v1.6 Added Warm Start option
;
;[2021/07/10] v1.7 Support MBC (AJL)
;
;[2022/03/27] v1.8 Support RHYOPHYRE
;
;[2023/07/07] v1.9 Support DUODYNE
;
;[2024/09/02] v1.10  Support Genesis STD Z180
;
; Constants
;
mask_data	.EQU	%10000000	; RTC data line
mask_clk	.EQU	%01000000	; RTC Serial Clock line
mask_rd		.EQU	%00100000	; Enable data read from RTC
mask_rst	.EQU	%00010000	; De-activate RTC reset line

PORT_SBC	.EQU	$70		; RTC port for SBC/ZETA
PORT_N8		.EQU	$88		; RTC port for N8
PORT_MK4	.EQU	$8A		; RTC port for MK4
PORT_RCZ80	.EQU	$C0		; RTC port for RCBus
PORT_RCZ180	.EQU	$0C		; RTC port for RCBus
PORT_EZZ80	.EQU	$C0		; RTC port for EZZ80 (actually does not have one!!!)
PORT_SCZ180	.EQU	$0C		; RTC port for SCZ180
PORT_DYNO	.EQU	$0C		; RTC port for DYNO
PORT_RCZ280	.EQU	$C0		; RTC port for RCZ280
PORT_MBC	.EQU	$70		; RTC port for MBC
PORT_RPH	.EQU	$84		; RTC port for RHYOPHYRE
PORT_DUO	.EQU	$94		; RTC port for DUODYNE
PORT_STDZ180 .EQU $84         ; RTC Port for STD Bus Z180 board


BDOS		.EQU	5		; BDOS invocation vector
FCB		.EQU	05CH		; Start of command line

;BID_BOOT	.EQU	$00
;HB_BNKCALL	.EQU	$FFF9

BF_SYSRESET	.EQU	$F0		; RESTART SYSTEM

BF_SYSRES_INT	.EQU	$00		; RESET HBIOS INTERNAL
BF_SYSRES_WARM	.EQU	$01		; WARM START (RESTART BOOT LOADER)
BF_SYSRES_COLD	.EQU	$02		; COLD START

;
; Program
;
	.ORG	0100H

LOOP:
	LD	DE,MSG
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

;	program starts here

	CALL	RTC_INIT		; Program initialization

	CALL	RTC_TOP_LOOP

	LD	C,00H			; CP/M system reset call - shut down
	CALL	0005H
		
	HALT				; This code is never reached


; function HEXSTR
; input number in A
; output upper nibble of number in ASCII in H
; output lower nibble of number in ASCII in L
; uses BC
;
; based on following algorithm:
;
;  const
;    hextab : string = ('0','1','2','3','4','5','6','7','8',
;                       '9','A','B','C','D','E','F');
;
;  PROCEDURE hexstr(n: int): ^string;
;  BEGIN
;    n := n and 255;
;    tmpstr[1] := hextab[n / 16];
;    tmpstr[2] := hextab[n and 15];
;    tmpstr[0] := #2;
;    return @tmpstr;
;  END;


HEXSTR:
	PUSH	BC			;SAVE BC
	LD	B,A
	RLC	A			;DO HIGH NIBBLE FIRST  
	RLC	A
	RLC	A
	RLC	A
	AND	0FH			;ONLY THIS NOW
	ADD	A,30H			;TRY A NUMBER
	CP	3AH			;TEST IT
	JR	C,HEXSTR1		;IF CY SET SAVE 'NUMBER' in H
	ADD	A,07H			;MAKE IT AN ALPHA
HEXSTR1:
	LD	H,A			;SAVE 'ALPHA' in H
	LD	A,B			;NEXT NIBBLE
	AND	0FH			;JUST THIS
	ADD	A,30H			;TRY A NUMBER
	CP	3AH			;TEST IT
	JR	C,HEXSTR2		;IF CY SET SAVE 'NUMBER' in L
	ADD	A,07H			;MAKE IT ALPHA

HEXSTR2:
	LD	L,A			;SAVE 'ALPHA' in L
	POP	BC			;RESTORE BC
	RET


;*****************************************************
;*	GET K.B. DATA & MAKE IT 'HEX'
;*****************************************************

HEXIN:
	PUSH	BC		;SAVE BC REGS.
	CALL	NIBL		;DO A NIBBLE
	RLC	A		;MOVE FIRST BYTE UPPER NIBBLE  
	RLC	A
	RLC	A
	RLC	A
	LD	B,A		;SAVE ROTATED BYTE
	PUSH	BC
		
	CALL NIBL		;DO NEXT NIBBLE
	POP	BC
	ADD	A,B		;COMBINE NIBBLES IN ACC.
	POP	BC		;RESTORE BC
	RET			;DONE  
NIBL:
	LD	C,01H		; CP/M console input call
	CALL	0005H		;GET K.B. DATA
	CP	40H		;TEST FOR ALPHA
	JR	NC,ALPH
	AND	0FH		;GET THE BITS
	RET
ALPH:
	AND	0FH		;GET THE BITS
	ADD	A,09H		;MAKE IT HEX A-F
	RET
	
; function RTC_IN
;
; read a byte from RTC port, return in A
; NOTE: port address is dynamically set in RTC_INIT

RTC_IN:
INP	.EQU	$ + 1
	IN	A,($FF)
	RET
	
; function RTC_OUT
;
; write a byte to RTC port, value in A
; NOTE: port address is dynamically set in RTC_INIT

RTC_OUT:
OUTP	.EQU	$ + 1
	OUT	($FF),A
	RET

; function RTC_BIT_DELAY
;
; based on following algorithm:
;
;  { Make a short delay }
;  PROCEDURE rtc_bit_delay;
;   var
;     x : int;
;  BEGIN
;    x := 3;
;  END;

RTC_BIT_DELAY:				; purpose is to delay ~36 uS or 144 t-states at 4MHz
	PUSH	AF			; 11 t-states
	LD	A,07H			; 7 t-states ADJUST THE TIME 13h IS FOR 4 MHZ
RTC_BIT_DELAY1:
	DEC	A			; 4 t-states DEC COUNTER. 4 T-states = 1 uS.
	JP	NZ,RTC_BIT_DELAY1	; 10 t-states JUMP TO PAUSELOOP2 IF A <> 0.

	NOP				; 4 t-states
	NOP				; 4 t-states
	POP	AF			; 10 t-states
	RET				; 10 t-states (144 t-states total)


; function RTC_RESET
;
; based on following algorithm:
;
;  { Output a RTC reset signal }
;  PROCEDURE rtc_reset;
;  BEGIN
;    out(rtc_base,mask_data + mask_rd);
;    rtc_bit_delay();
;    rtc_bit_delay();
;    out(rtc_base,mask_data + mask_rd + mask_rst);
;    rtc_bit_delay();
;    rtc_bit_delay();
;  END;
;
RTC_RESET:
	LD	A,mask_data + mask_rd
	;OUT	(RTC),A
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY
	CALL	RTC_BIT_DELAY
	LD	A,mask_data + mask_rd + mask_rst
	;OUT	(RTC),A
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY
	CALL	RTC_BIT_DELAY
	RET


; function RTC_RESET_ON
;
; based on following algorithm:
;
;  { Assert RTC reset signal }
;  PROCEDURE rtc_reset_on;
;  BEGIN
;    out(rtc_base,mask_data + mask_rd);
;    rtc_bit_delay();
;    rtc_bit_delay();
;  END;

RTC_RESET_ON:
	LD	A,mask_data + mask_rd
	;OUT	(RTC),A
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY
	CALL	RTC_BIT_DELAY
	RET

; function RTC_RESET_OFF
;
; based on following algorithm:
;
;  { De-assert RTC reset signal }
;  PROCEDURE rtc_reset_off;
;  BEGIN
;    out(rtc_base,mask_data + mask_rd + mask_rst);
;    rtc_bit_delay();
;    rtc_bit_delay();
;  END;

RTC_RESET_OFF:
	LD	A,mask_data + mask_rd + mask_rst
	;OUT	(RTC),A
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY
	CALL	RTC_BIT_DELAY
	RET

; function RTC_WR
; input value in C
; uses A
;
;  PROCEDURE rtc_wr(n : int);
;   var
;    i : int;
;  BEGIN
;    for i := 0 while i < 8 do inc(i) loop
;       if (n and 1) <> 0 then
;          out(rtc_base,mask_rst + mask_data);
;          rtc_bit_delay();
;          out(rtc_base,mask_rst + mask_clk + mask_data);
;       else
;          out(rtc_base,mask_rst);
;          rtc_bit_delay();
;          out(rtc_base,mask_rst + mask_clk);
;       end;
;       rtc_bit_delay();
;       n := shr(n,1);
;    end loop;
;  END;

RTC_WR:
	XOR	A			; set A=0 index counter of FOR loop

RTC_WR1:
	PUSH	AF			; save accumulator as it is the index counter in FOR loop
	LD	A,C			; get the value to be written in A from C (passed value to write in C)
	BIT	0,A			; is LSB a 0 or 1?
	JP	Z,RTC_WR2		; if it's a 0, handle it at RTC_WR2.
					; LSB is a 1, handle it below
					; setup RTC latch with RST and DATA high, SCLK low
	LD	A,mask_rst + mask_data
	;OUT	(RTC),A		; output to RTC latch
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY	; let it settle a while
					; setup RTC with RST, DATA, and SCLK high
	LD	A,mask_rst + mask_clk + mask_data
	;OUT	(RTC),A		; output to RTC latch
	CALL	RTC_OUT
	JP	RTC_WR3		; exit FOR loop 

RTC_WR2:
					; LSB is a 0, handle it below
	LD	A,mask_rst		; setup RTC latch with RST high, SCLK and DATA low
	;OUT	(RTC),A		; output to RTC latch
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY	; let it settle a while
					; setup RTC with RST and SCLK high, DATA low
	LD	A,mask_rst + mask_clk
	;OUT	(RTC),A		; output to RTC latch
	CALL	RTC_OUT

RTC_WR3:
	CALL	RTC_BIT_DELAY	; let it settle a while
	RRC	C			; move next bit into LSB position for processing to RTC
	POP	AF			; recover accumulator as it is the index counter in FOR loop
	INC	A			; increment A in FOR loop (A=A+1)
	CP	$08			; is A < $08 ?
	JP	NZ,RTC_WR1		; No, do FOR loop again
	RET				; Yes, end function and return


; function RTC_RD
; output value in C
; uses A
;
; function RTC_RD
;
;  PROCEDURE rtc_rd(): int ;
;   var
;     i,n,mask : int;
;  BEGIN
;    n := 0;
;    mask := 1;
;    for i := 0 while i < 8 do inc(i) loop
;       out(rtc_base,mask_rst + mask_rd);
;       rtc_bit_delay();
;       if (in(rtc_base) and #1) <> #0 then
;          { Data = 1 }
;          n := n + mask;
;       else
;          { Data = 0 }
;       end;
;       mask := shl(mask,1);
;       out(rtc_base,mask_rst + mask_clk + mask_rd);
;       rtc_bit_delay();
;    end loop;
;    return n;
;  END;

RTC_RD:
	XOR	A			; set A=0 index counter of FOR loop
	LD	C,$00			; set C=0 output of RTC_RD is passed in C
	LD	B,$01			; B is mask value

RTC_RD1:
	PUSH	AF			; save accumulator as it is the index counter in FOR loop
					; setup RTC with RST and RD high, SCLK low
	LD	A,mask_rst + mask_rd
	;OUT	(RTC),A		; output to RTC latch
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY	; let it settle a while
	;IN	A,(RTC)		; input from RTC latch
	CALL	RTC_IN		; input from RTC latch
	BIT	0,A			; is LSB a 0 or 1?
	JP	Z,RTC_RD2		; if LSB is a 1, handle it below
	LD	A,C
	ADD	A,B
	LD	C,A
;	INC	C
					; if LSB is a 0, skip it (C=C+0)
RTC_RD2:
	RLC	B			; move input bit out of LSB position to save it in C
					; setup RTC with RST, SCLK high, and RD high
	LD	A,mask_rst + mask_clk + mask_rd
	;OUT	(RTC),A		; output to RTC latch
	CALL	RTC_OUT
	CALL	RTC_BIT_DELAY	; let it settle
	POP	AF			; recover accumulator as it is the index counter in FOR loop
	INC	A			; increment A in FOR loop (A=A+1)
	CP	$08			; is A < $08 ?
	JP	NZ,RTC_RD1		; No, do FOR loop again
	RET				; Yes, end function and return.  Read RTC value is in C

; function RTC_WRITE
; input address in D
; input value in E
; uses A
;
; based on following algorithm:		
;
;  PROCEDURE rtc_write(address, value: int);
;  BEGIN
;    lock();
;    rtc_reset_off();
;    { Write command }
;    rtc_wr(128 + shl(address and $3f,1));
;    { Write data }
;    rtc_wr(value and $ff);
;    rtc_reset_on();
;    unlock();
;  END;

RTC_WRITE:
	DI				; disable interrupts during critical section
	CALL	RTC_RESET_OFF	; turn off RTC reset
	LD	A,D			; bring into A the address from D
;	AND	$3F			; keep only bits 6 LSBs, discard 2 MSBs
	AND	%00111111		; keep only bits 6 LSBs, discard 2 MSBs
	RLC	A			; rotate address bits to the left
;	ADD	A,$80			; set MSB to one for DS1302 COMMAND BYTE (WRITE)
	ADD	A,%10000000		; set MSB to one for DS1302 COMMAND BYTE (WRITE)
	LD	C,A			; RTC_WR expects write data (address) in reg C
	CALL	RTC_WR		; write address to DS1302
	LD	A,E			; start processing value
	AND	$FF			; seems unnecessary, probably delete since all values are 8-bit
	LD	C,A			; RTC_WR expects write data (value) in reg C
	CALL	RTC_WR		; write address to DS1302
	CALL	RTC_RESET_ON	; turn on RTC reset
	EI
	RET


; function RTC_READ
; input address in D
; output value in C
; uses A
;
; based on following algorithm
;
;  PROCEDURE rtc_read(address: int): int;
;   var
;     n : int;
;  BEGIN
;    lock();
;    rtc_reset_off();
;    { Write command }
;    rtc_wr(128 + shl(address and $3f,1) + 1);
;    { Read data }
;    n := rtc_rd();
;    rtc_reset_on();
;    unlock();
;    return n;
;  END;

RTC_READ:
	DI				; disable interrupts during critical section
	CALL	RTC_RESET_OFF	; turn off RTC reset
	LD	A,D			; bring into A the address from D
	AND	$3F			; keep only bits 6 LSBs, discard 2 MSBs
	RLC	A			; rotate address bits to the left
	ADD	A,$81			; set MSB to one for DS1302 COMMAND BYTE (READ)
	LD	C,A			; RTC_WR expects write data (address) in reg C
	CALL	RTC_WR		; write address to DS1302
	CALL	RTC_RD		; read value from DS1302 (value is in reg C)
	CALL	RTC_RESET_ON	; turn on RTC reset
	EI
	RET


; function RTC_WR_PROTECT
; input D (address) $07
; input E (value) $80
; uses A
;
; based on following algorithm
;
;  PROCEDURE rtc_wr_protect;
;  BEGIN
;    rtc_write(7,128);
;  END;

RTC_WR_PROTECT:
;	LD	D,$07
	LD	D,%00000111
;	LD	E,$80
	LD	E,%10000000
	CALL	RTC_WRITE
	RET


; function RTC_WR_UNPROTECT
; input D (address) $07
; input E (value) $00
; uses A
;
; based on following algorithm
;
;  PROCEDURE rtc_wr_unprotect;
;  BEGIN
;    rtc_write(7,0);
;  END;

RTC_WR_UNPROTECT:
;	LD	D,$07
	LD	D,%00000111
;	LD	E,$00
	LD	E,%00000000
	CALL	RTC_WRITE
	RET


; function RTC_GET_TIME
; input HL (memory address of buffer)
; uses A,C,D,E
;
; based on following algorithm
;
;  PROCEDURE rtc_get_time(var buf: string);
;   var
;     n  : int;
;  BEGIN
;    lock();
;    rtc_reset_off();
;    { Write command, burst read }
;    rtc_wr(255 - 64);
;    { Read seconds }
;    n := rtc_rd(); 0
;    buf[16] := char(((n / 16) and $07)) + '0';
;    buf[17] := char((n and $0f)) + '0';
;    { Read minutes }
;    n := rtc_rd(); 1
;    buf[13] := char(((n / 16) and $07)) + '0';
;    buf[14] := char((n and $0f)) + '0';
;    buf[15] := ':';
;    { Read hours }
;    n := rtc_rd(); 2
;    buf[10] := char(((n / 16) and $03)) + '0';
;    buf[11] := char((n and $0f)) + '0';
;    buf[12] := ':';
;    { Read date }
;    n := rtc_rd(); 3
;    buf[7] := char(((n / 16) and $03)) + '0';
;    buf[8] := char((n and $0f)) + '0';
;    buf[9] := ' ';
;    { Read month }
;    n := rtc_rd(); 4
;    buf[4] := char(((n / 16) and $03)) + '0';
;    buf[5] := char((n and $0f)) + '0';
;    buf[6] := '-';
;    { Read day }
;    n := rtc_rd(); 5
;    {
;    buf[4] := char(((n / 16) and $03)) + '0';
;    buf[4] := char((n and $0f)) + '0';
;    }
;    { Read year }
;    n := rtc_rd(); 6
;    buf[1] := char(((n / 16) and $0f)) + '0';
;    buf[2] := char((n and $0f)) + '0';
;    buf[3] := '-';
;    length(buf) := 17;
;    rtc_reset_on();
;    unlock();
;  END rtc_get_time;

RTC_GET_TIME:
	DI				; disable interrupts during DS1302 read
	CALL	RTC_RESET_OFF		; turn of RTC reset
					;    { Write command, burst read }
	LD	C,%10111111		; (255 - 64)
	CALL	RTC_WR			; send COMMAND BYTE (BURST READ) to DS1302

;    { Read seconds }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	; digit 16
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$07
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+15),A

	; digit 17
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+16),A

;    { Read minutes }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	; digit 13
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$07
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+12),A

	; digit 14
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+13),A

	; digit 15	
	LD	A,':'
	LD	(RTC_PRINT_BUFFER+14),A

;    { Read hours }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	; digit 10
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$03
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+09),A

	; digit 11
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+10),A

	; digit 12
	LD	A,':'
	LD	(RTC_PRINT_BUFFER+11),A

;    { Read date }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	; digit 07
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$03
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+06),A

	; digit 08
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+07),A

	; digit 09
	LD	A,' '
	LD	(RTC_PRINT_BUFFER+08),A

;    { Read month }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	; digit 04
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$03
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+03),A

	; digit 05
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+04),A

	; digit 06
	LD	A,'-'
	LD	(RTC_PRINT_BUFFER+05),A

;    { Read day }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	; digit 04
;	LD	A,C			; put value output in Reg C into accumulator
;	RLC	A
;	RLC	A
;	RLC	A
;	RLC	A
;	AND	$03
;	ADD	A,'0'
;	LD	(RTC_PRINT_BUFFER+03),A

	; digit 04
;	LD	A,C			; put value output in Reg C into accumulator
;	AND	$0F
;	ADD	A,'0'
;	LD	(RTC_PRINT_BUFFER+03),A

; add special code to put "DAY" value at end of string until better solution known

	; digit 18
	LD	A,'-'
	LD	(RTC_PRINT_BUFFER+17),A

	; digit 19
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+18),A

	; digit 20
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+19),A

;    { Read year }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	; digit 01
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+00),A

	; digit 02
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+01),A

	; digit 03
	LD	A,'-'
	LD	(RTC_PRINT_BUFFER+02),A

	CALL	RTC_RESET_ON		; turn RTC reset back on 
	EI				; re-enable interrupts

	RET				; Yes, end function and return


; function RTC_SET_NOW
; uses A, D, E
;
; based on following algorithm
;
;  { Set time to 96-02-18 19:43:00 }
;  PROCEDURE rtc_set_now;
;  BEGIN
;    rtc_wr_unprotect();
;    { Set seconds }
;    rtc_write(0,0);
;    { Set minutes }
;    rtc_write(1,$43);
;    { Set hours }
;    rtc_write(2,$19);
;    { Set date }
;    rtc_write(3,$18);
;    { Set month }
;    rtc_write(4,$02);
;    { Set day }
;    rtc_write(5,$07);
;    { Set year }
;    rtc_write(6,$96);
;    rtc_wr_protect();
;  END;

RTC_SET_NOW:
; set time to 07-02-23 19:45:00-05 <-Friday
	CALL RTC_WR_UNPROTECT
; seconds
	LD	D,$00
	LD	A,(SECONDS)
	LD	E,A
	CALL RTC_WRITE

; minutes
	LD	D,$01
	LD	A,(MINUTES)
	LD	E,A
	CALL RTC_WRITE

; hours
	LD	D,$02
	LD	A,(HOURS)
	LD	E,A
	CALL RTC_WRITE

; date
	LD	D,$03
	LD	A,(DATE)
	LD	E,A
	CALL RTC_WRITE

; month
	LD	D,$04
	LD	A,(MONTH)
	LD	E,A
	CALL RTC_WRITE

; day
	LD	D,$05
	LD	A,(DAY)
	LD	E,A
	CALL RTC_WRITE

; year
	LD	D,$06
	LD	A,(YEAR)
	LD	E,A
	CALL RTC_WRITE

	CALL RTC_WR_PROTECT
	RET

RTC_INIT_NOW:
; set time to Current Time

; year
	LD	DE,RTC_TOP_LOOP1_INIT_YEAR
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	HEXIN
	LD	(YEAR),A

; month
	LD	DE,RTC_TOP_LOOP1_INIT_MONTH
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	HEXIN
	LD	(MONTH),A

; date
	LD	DE,RTC_TOP_LOOP1_INIT_DATE
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	HEXIN
	LD	(DATE),A

; hours
	LD	DE,RTC_TOP_LOOP1_INIT_HOURS
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	HEXIN
	LD	(HOURS),A

; minutes
	LD	DE,RTC_TOP_LOOP1_INIT_MINUTES
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	HEXIN
	LD	(MINUTES),A

; seconds
	LD	DE,RTC_TOP_LOOP1_INIT_SECONDS
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	HEXIN
	LD	(SECONDS),A

; day
	LD	DE,RTC_TOP_LOOP1_INIT_DAY
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	HEXIN
	LD	(DAY),A

	RET


; function RTC_RESTART
;
; uses A, D, E,
;
; based on the following algorithm
;
;  { Restart clock, set seconds to 00 }
;  PROCEDURE rtc_restart;
;  BEGIN
;    rtc_wr_unprotect();
;    { Set seconds }
;    rtc_write(0,0);
;    rtc_wr_protect();
;  END;

RTC_RESTART:
	CALL RTC_WR_UNPROTECT
	LD	D,$00
	LD	E,$00
	CALL RTC_WRITE
	CALL RTC_WR_PROTECT
	RET


; function RTC_CHARGE_ENABLE
;
; uses A, D, E
;
; based on following algorithm
;
;  PROCEDURE rtc_charge_enable;
;  BEGIN
;    rtc_wr_unprotect();
;    { Enable trickle charger, 2kohm, 1 diode }
;    rtc_write(8,$A5);
;    rtc_wr_protect();
;  END;
;
; Trickle Charge Current:
;
; Imax = (5.0V - (0.7 * Ndiode)) / R
; (5.0 - (0.7 * 1)) / 2000 = .00215A = 2.15 milliamps
; (5.0 - (0.7 * 1)) / 8000 = 0.0005375A = .537 milliamps
;

RTC_CHARGE_ENABLE
	CALL	RTC_WR_UNPROTECT
	LD	D,$08
	LD	E,$A5
	CALL	RTC_WRITE
	CALL	RTC_WR_PROTECT
	RET


; function RTC_CHARGE_DISABLE
;
; uses A, D, E
;
; based on following algorithm
;
;  PROCEDURE rtc_charge_disable;
;  BEGIN
;    rtc_wr_unprotect();
;    { Disable trickle charger}
;    rtc_write(8,$00);
;    rtc_wr_protect();
;  END;

RTC_CHARGE_DISABLE
	CALL	RTC_WR_UNPROTECT
	LD	D,$08
	LD	E,$00
	CALL	RTC_WRITE
	CALL	RTC_WR_PROTECT
	RET


; function TEST_BIT_DELAY
;
; based on the following algorithm
;
;
;  PROCEDURE test_bit_delay();
;   var
;     i,t0,t1 : int;
;  BEGIN
;    putln("Testing bit delay...");
;    t0 := sys_time();
;    for i := 0 while i < 1000 do inc(i) loop
;      rtc_bit_delay();
;    end loop;
;    t1 := sys_time();
;    putln(i," rtc_bit_delay calls took ",t1-t0," ms.");
;  END;

RTC_TEST_BIT_DELAY
	LD	DE,TESTING_BIT_DELAY_MSG
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	LD	C,01H			; CP/M console input call
	CALL	0005H

	; test should take approximately 43 seconds based on the following code analysis
	; of Z80 T-states on a 4 MHz processor
	; =(4+15*(7+255*(7+255*(17+144+4+10)+4+10)+10)+7)/4/1000000

	LD	B,$0F
PAUSE:
	LD	C,$FF
PAUSE1:
	LD	A,$FF			; ADJUST THE TIME 13h IS FOR 4 MHZ
PAUSE2:
	CALL	RTC_BIT_DELAY		; CAUSE 36uS DELAY
	DEC	A			; DEC COUNTER.
	JP	NZ,PAUSE2		; JUMP TO PAUSE2 IF A <> 0.
	DEC	C			; DEC COUNTER
	JP	NZ,PAUSE1		; JUMP TO PAUSE1 IF C <> 0.
	DJNZ	PAUSE			; JUMP TO PAUSE IF B <> 0.

	LD	DE,TESTING_BIT_DELAY_OVER
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	RET


; function RTC_HELP
;
; based on following algorithm
;
;  PROCEDURE help();
;  BEGIN
;    putln();
;    putln("rtc: ",version);
;    putln("rtc: Commands: (E)xit (T)ime st(A)rt (S)et (R)aw (L)oop (C)harge (N)ocharge (H)elp");
;  END;

RTC_HELP
	LD	DE,RTC_HELP_MSG
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	RET
	
; function RTC_INIT
;
; Determine RTC port based on hardware platform
; and record it dynamically in code (see RTC_IN and RTC_OUT).
;

RTC_INIT:
	CALL	IDBIO		; Id BIOS, 1=HBIOS, 2=UBIOS
	DEC	A		; Test for HBIOS
	JP	Z,HINIT		; Do HBIOS setup
	DEC	A		; Test for UBIOS
	JP	Z,UINIT		; Do UBIOS setup
;
	; Neither UNA nor RomWBW
	LD	DE,BIOERR	; BIOS error message
	LD	C,9		; BDOS string display function
	CALL	BDOS		; Do it
	JP	0		; Bail out!
;
HINIT:
;
	; Display RomWBW notification string
	LD	DE,HBTAG	; BIOS notification string
	LD	C,9		; BDOS string display function
	CALL	BDOS		; Do it
;
	; Get platform id from RomWBW HBIOS
	LD	B,0F1H		; HBIOS VER function 0xF1
	LD	C,0		; Required reserved value
	RST	08		; Do it, L := Platform ID
	LD	A,L		; Move to A
;
	; Assign correct port to C
	LD	C,PORT_SBC
	LD	DE,PLT_SBC
	CP	$01		; SBC
	JP	Z,RTC_INIT2
	CP	$02		; ZETA
	JP	Z,RTC_INIT2
	CP	$03		; ZETA 2
	JP	Z,RTC_INIT2
;
	LD	C,PORT_N8
	LD	DE,PLT_N8
	CP	$04		; N8
	JP	Z,RTC_INIT2
;
	LD	C,PORT_MK4
	LD	DE,PLT_MK4
	CP	$05		; Mark IV
	JP	Z,RTC_INIT2
;
	LD	C,PORT_RCZ80
	LD	DE,PLT_RCZ80
	CP	$07		; RCBus w/ Z80
	JP	Z,RTC_INIT2
;
	LD	C,PORT_RCZ180
	LD	DE,PLT_RCZ180
	CP	$08		; RCBus w/ Z180
	JP	Z,RTC_INIT2
;
	LD	C,PORT_EZZ80
	LD	DE,PLT_EZZ80
	CP	$09		; Easy Z80
	JP	Z,RTC_INIT2
;
	LD	C,PORT_SCZ180
	LD	DE,PLT_SCZ180
	CP	$0A		; SCZ180
	JP	Z,RTC_INIT2
;
	LD	C,PORT_DYNO
	LD	DE,PLT_DYNO
	CP	11		; DYNO
	JP	Z,RTC_INIT2
;
	LD	C,PORT_RCZ280
	LD	DE,PLT_RCZ280
	CP	12		; RCZ280
	JP	Z,RTC_INIT2
;
	LD	C,PORT_MBC
	LD	DE,PLT_MBC
	CP	13		; MBC
	JP	Z,RTC_INIT2
;
	LD	C,PORT_RPH
	LD	DE,PLT_RPH
	CP	14		; RHYOPHYRE
	JP	Z,RTC_INIT2
;
	LD	C,PORT_DUO
	LD	DE,PLT_DUO
	CP	17		; DUODYNE
	JP	Z,RTC_INIT2
;
	LD	C,PORT_STDZ180
	LD	DE,PLT_STDZ180
	CP	21		; STD Z180
	JP	Z,RTC_INIT2
;

; Unknown platform
	LD	DE,PLTERR	; BIOS error message
	LD	C,9		; BDOS string display function
	CALL	BDOS		; Do it
	JP	0		; Bail out!
;
UINIT:
	;; Display UNA notification string
	;LD	DE,UBTAG	; BIOS notification string
	;LD	C,9		; BDOS string display function
	;CALL	BDOS		; Do it
;
	; Notify UNA not supported at present
	LD	DE,UBERR	; BIOS not support message
	LD	C,9		; BDOS string display function
	CALL	BDOS		; Do it
	JP	0		; Bail out!
	
RTC_INIT2:
	; Record port number in code routines
	LD	A,C
	LD	(INP),A
	LD	(OUTP),A
;
	; Display platform
	LD	C,9		; BDOS string display function
	CALL	BDOS		; Do it
	RET

;
; Identify active BIOS.  RomWBW HBIOS=1, UNA UBIOS=2, else 0
;
IDBIO:
;
	; Check for UNA (UBIOS)
	LD	A,(0FFFDH)	; fixed location of UNA API vector
	CP	0C3H		; jp instruction?
	JR	NZ,IDBIO1	; if not, not UNA
	LD	HL,(0FFFEH)	; get jp address
	LD	A,(HL)		; get byte at target address
	CP	0FDH		; first byte of UNA push ix instruction
	JR	NZ,IDBIO1	; if not, not UNA
	INC	HL		; point to next byte
	LD	A,(HL)		; get next byte
	CP	0E5H		; second byte of UNA push ix instruction
	JR	NZ,IDBIO1	; if not, not UNA, check others
	LD	A,2		; UNA BIOS id = 2
	RET			; and done
;
IDBIO1:
	; Check for RomWBW (HBIOS)
	LD	HL,(0FFFCH)	; HL := HBIOS ident location
	LD	A,'W'		; First byte of ident
	CP	(HL)		; Compare
	JR	NZ,IDBIO2	; Not HBIOS
	INC	HL		; Next byte of ident
	LD	A,~'W'		; Second byte of ident
	CP	(HL)		; Compare
	JR	NZ,IDBIO2	; Not HBIOS
	LD	A,1		; HBIOS BIOS id = 1
	RET			; and done
;
IDBIO2:
	; No idea what this is
	XOR	A		; Setup return value of 0
	RET			; and done


; function RTC_TOP_LOOP
;
; based on following algorithm
;
;  PROCEDURE toploop();
;   var
;     err,i,n,fd  : int;
;  BEGIN
;    putln();
;    help();
;    rtc_reset_on();
;    hold(100);
;    test_bit_delay();
;    rtc_charge_disable();
;    putln("rtc: trickle charger disabled.");
;    loop
;       put("rtc>");
;       gets(line);
;       if line = "exit" then
;          putln("Bye.");
;          exit(0);
;       elsif line = "charge" then
;          putln("Trickle charger enabled.");
;          rtc_charge_enable();
;       elsif line = "nocharge" then
;          putln("Trickle charger disabled.");
;          rtc_charge_disable();
;       elsif line = "start" then
;          rtc_restart();
;          putln("Restarting RTC");
;       elsif line = "t" then
;          rtc_get_time(line);
;          putln("Current time: ",line);
;       elsif line = "raw" then
;          putln();
;          putln("Raw read loop, hit any key to stop...");
;          while read(0,@n,1 + RD_NOWAIT) = 0 loop
;             put(#13,"sec=",hexstr(rtc_read(0))^);
;             put(" min=",hexstr(rtc_read(1))^);
;             hold(500);
;          end loop;
;       elsif line = "loop" then
;          putln();
;          putln("Clock loop, hit any key to stop...");
;          while read(0,@n,1 + RD_NOWAIT) = 0 loop
;             rtc_get_time(line);
;             put(#13,line);
;             hold(200);
;          end loop;
;       elsif line = "set" then
;          putln("Setting RTC time to 96-02-18 19:43:00");
;          rtc_set_now();
;       elsif (line = "help") or (line = "?") then
;          help();
;       elsif length(line) <> 0 then
;          putln("You typed: """,line,"""");
;       end;
;    end loop;
;  END toploop;
;  Note:above code is not fully in sync with current menu code

RTC_TOP_LOOP:
	CALL	RTC_RESET_ON
	CALL	RTC_BIT_DELAY
	CALL	RTC_BIT_DELAY
	CALL	RTC_BIT_DELAY

	LD	A,(FCB+1)		; If there a command line tail
	CP	'/'			; get the command and feed it 
	LD	A,(FCB+2)		; into the input stream
	JR	Z,RTC_UCL		

	LD	DE,CRLF_MSG
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

	CALL	RTC_HELP

RTC_TOP_LOOP_1:
	LD	DE,RTC_TOP_LOOP1_PROMPT
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	
	LD	C,01H			; CP/M console input call
	CALL	0005H
RTC_UCL:
	AND	%01011111		; handle lower case responses to menu

	CP	'L'
	JP	Z,RTC_TOP_LOOP_LOOP
	
	CP	'R'
	JP	Z,RTC_TOP_LOOP_RAW
	
	CP	'G'
	JP	Z,RTC_TOP_LOOP_GET

	CP	'P'
	JP	Z,RTC_TOP_LOOP_PUT
	
	CP	'E'
;	JP	Z,RTC_TOP_LOOP_EXIT
	RET	Z
	
	CP	'H'
	JP	Z,RTC_TOP_LOOP_HELP
	
	CP	'D'
	JP	Z,RTC_TOP_LOOP_DELAY	

	CP	'B'
	JP	Z,RTC_TOP_LOOP_BOOT	

	CP	'W'
	JP	Z,RTC_TOP_LOOP_WARMSTART

	CP	'C'
	JP	Z,RTC_TOP_LOOP_CHARGE

	CP	'N'
	JP	Z,RTC_TOP_LOOP_NOCHARGE

	CP	'A'
	JP	Z,RTC_TOP_LOOP_START

	CP	'S'
	JP	Z,RTC_TOP_LOOP_SET

	CP	'I'
	JP	Z,RTC_TOP_LOOP_INIT
	
	CP	'T'
	JP	Z,RTC_TOP_LOOP_TIME

	LD	DE,CRLF_MSG
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	
	JR	RTC_TOP_LOOP_1

;RTC_TOP_LOOP_EXIT:
;	RET

RTC_TOP_LOOP_HELP:
	CALL	RTC_HELP
	JP	RTC_TOP_LOOP_1
	
RTC_TOP_LOOP_DELAY:
	CALL	RTC_TEST_BIT_DELAY
	JP	RTC_TOP_LOOP_1
	
RTC_TOP_LOOP_BOOT:
	LD	DE,BOOTMSG		; BOOT message
	LD	C,9			; BDOS string display function
	CALL	BDOS			; Do it
	; WAIT FOR MESSAGE TO BE DISPLAYED
	LD	HL,10000
DELAY_LOOP:				; LOOP IS 26TS
	DEC	HL			; 6TS
	LD	A,H			; 4TS
	OR	L			; 4TS
	JR	NZ,DELAY_LOOP		; 12TS
	; RESTART SYSTEM FROM ROM BANK 0, ADDRESS $0000
	LD	B,BF_SYSRESET		; SYSTEM RESTART
	LD	C,BF_SYSRES_COLD	; COLD START
	CALL	$FFF0			; CALL HBIOS
	

RTC_TOP_LOOP_WARMSTART:
	LD	B,BF_SYSRESET		; SYSTEM RESTART
	LD	C,BF_SYSRES_WARM	; WARM START
	CALL	$FFF0			; CALL HBIOS

RTC_TOP_LOOP_CHARGE:
	LD	DE,RTC_TOP_LOOP1_CHARGE
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	RTC_CHARGE_ENABLE
	LD	A,(FCB+1)		; If we came from the
	CP	'/'			; command line
	RET	Z			; exit back to CP/M
	JP	RTC_TOP_LOOP_1

RTC_TOP_LOOP_NOCHARGE:
	LD	DE,RTC_TOP_LOOP1_NOCHARGE
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	RTC_CHARGE_DISABLE
	LD	A,(FCB+1)		; If we came from the
	CP	'/'			; command line
	RET	Z			; exit back to CP/M
	JP	RTC_TOP_LOOP_1

RTC_TOP_LOOP_START:
	LD	DE,RTC_TOP_LOOP1_START
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	RTC_RESTART
	JP	RTC_TOP_LOOP_1
	
RTC_TOP_LOOP_SET:
	LD	DE,RTC_TOP_LOOP1_SET
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	RTC_SET_NOW
	JP	RTC_TOP_LOOP_1

RTC_TOP_LOOP_INIT:
	LD	DE,RTC_TOP_LOOP1_INIT
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	RTC_INIT_NOW
	JP	RTC_TOP_LOOP_1

RTC_TOP_LOOP_TIME:
	LD	DE,RTC_TOP_LOOP1_TIME
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	CALL	RTC_GET_TIME
	LD	DE,RTC_PRINT_BUFFER
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
	LD	A,(FCB+1)		; If we came from the
	CP	'/'			; command line
	RET	Z			; exit back to CP/M
	JP	RTC_TOP_LOOP_1
	
RTC_TOP_LOOP_RAW:
	LD	DE,RTC_TOP_LOOP1_RAW
	LD	C,09H			; CP/M write string to console call
	CALL	0005H
RTC_TOP_LOOP_RAW1:

;	{ Read seconds }
	LD	D,$00			; seconds register in DS1302
	CALL	RTC_READ		; read value from DS1302, value is in Reg C

	; digit 16
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$07
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+15),A

	; digit 17
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+16),A

;	{ Read minutes }

	LD	D,$01			; minutes register in DS1302
	CALL	RTC_READ		; read value from DS1302, value is in Reg C

	; digit 13
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$07
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+12),A

	; digit 14
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	ADD	A,'0'
	LD	(RTC_PRINT_BUFFER+13),A

	; digit 15
	LD	A,':'
	LD	(RTC_PRINT_BUFFER+14),A

	; digits 1-12 and 18-20 are spaces
	LD	A,' '			; space
	LD	(RTC_PRINT_BUFFER+19),A
	LD	(RTC_PRINT_BUFFER+18),A
	LD	(RTC_PRINT_BUFFER+17),A
	LD	(RTC_PRINT_BUFFER+11),A
	LD	(RTC_PRINT_BUFFER+10),A
	LD	(RTC_PRINT_BUFFER+09),A
	LD	(RTC_PRINT_BUFFER+08),A
	LD	(RTC_PRINT_BUFFER+07),A
	LD	(RTC_PRINT_BUFFER+06),A
	LD	(RTC_PRINT_BUFFER+05),A
	LD	(RTC_PRINT_BUFFER+04),A
	LD	(RTC_PRINT_BUFFER+03),A
	LD	(RTC_PRINT_BUFFER+02),A
	LD	(RTC_PRINT_BUFFER+01),A
	LD	(RTC_PRINT_BUFFER+00),A

	LD	DE,RTC_PRINT_BUFFER
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

	LD	C,01H			; CP/M console input call
	CALL	0005H

	CP	' '			; space
	JP	Z,RTC_TOP_LOOP_RAW1

	JP	RTC_TOP_LOOP_1

RTC_TOP_LOOP_LOOP:
	LD	DE,RTC_TOP_LOOP1_LOOP
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

RTC_TOP_LOOP_LOOP1:
	CALL	RTC_GET_TIME

	LD	DE,RTC_PRINT_BUFFER
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

	LD	C,01H			; CP/M console input call
	CALL	0005H

	CP	' '
	JP	Z,RTC_TOP_LOOP_LOOP1	

	JP	RTC_TOP_LOOP_1

RTC_TOP_LOOP_PUT:
	LD	A,$01			; set PUT as true
	LD	(GET_PUT),A
RTC_TOP_LOOP_GET:
	LD	DE,RTC_TOP_LOOP1_GET
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

	CALL	HEXIN			; read NVRAM address
	LD	(PUT_ADR),A		; store for possible PUT later

;	{ Read NVRAM address }
	LD	D,A			; seconds register in DS1302
	CALL	RTC_READ		; read value from DS1302, value is in Reg C

	; first digit
	LD	A,C			; put value output in Reg C into accumulator
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	$0F
	CP	0AH			;TEST FOR NUMERIC & convert to ASCII
	JR	C,NUM1			;if not ALPHA, its numeric and skip
	ADD	A,$07

NUM1:	ADD	A,'0'
	LD	(RTC_GET_BUFFER),A

	; second digit
	LD	A,C			; put value output in Reg C into accumulator
	AND	$0F
	CP	0AH			;TEST FOR NUMERIC & convert to ASCII
	JR	C,NUM2			;if not ALPHA, its numeric and skip
	ADD	A,$07	

NUM2:	ADD	A,'0'
	LD	(RTC_GET_BUFFER+1),A

	LD	DE,CRLF_MSG
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

	LD	DE,RTC_GET_BUFFER
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

	LD	A,(GET_PUT)		; check if GET or PUT mode
	CP	$00
	JP	Z,RTC_GET_PUT_EXIT	; if GET mode, exit

	LD	DE,RTC_TOP_LOOP1_PUT
	LD	C,09H			; CP/M write string to console call
	CALL	0005H

;	{ Write NVRAM address }

	CALL	RTC_WR_UNPROTECT

	CALL	HEXIN			; read NVRAM address
	LD	E,A			; new data for NVRAM register in DS1302
	LD	A,(PUT_ADR)
	LD	D,A			; load address from before

	CALL	RTC_WRITE		; read value from DS1302, value is in Reg C

	CALL	RTC_WR_PROTECT

RTC_GET_PUT_EXIT:
	LD	A,$00			; reset GET mode
	LD	(GET_PUT),A
	JP	RTC_TOP_LOOP_1

;
; Text Strings
;

MSG:
	.TEXT	"Start RTC Program"
CRLF_MSG:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

TESTING_BIT_DELAY_MSG:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Testing bit delay.  Successful test is ~43 sec."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Start clock and press space bar."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

TESTING_BIT_DELAY_OVER:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Test complete.  Stop clock."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_HELP_MSG:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"RTC: Version 1.9"
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Commands: E)xit T)ime st(A)rt S)et R)aw L)oop C)harge N)ocharge D)elay I)nit G)et P)ut B)oot W)arm-start H)elp"
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_PROMPT:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"RTC>"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_CHARGE:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Trickle charger enabled."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_NOCHARGE:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Trickle charger disabled."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_START:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Restart RTC."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_TIME:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Current time: "
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_RAW:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Raw read Loop.  Press SPACE BAR for next."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_LOOP:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Clock Loop.  Press SPACE BAR for next."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_SET:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Set RTC time."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Init date/time."
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_GET:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"Get NVRAM addr:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_PUT:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"NVRAM data:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT_SECONDS:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"SECONDS:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT_MINUTES:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"MINUTES:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT_HOURS:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"HOURS:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT_DATE:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"DATE:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT_MONTH:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"MONTH:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT_DAY:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"DAY:"
	.DB	"$"			; Line terminator

RTC_TOP_LOOP1_INIT_YEAR:
	.DB	0Ah, 0Dh		; line feed and carriage return
	.TEXT	"YEAR:"
	.DB	"$"			; Line terminator

RTC_PRINT_BUFFER:
	.FILL	20,0			; Buffer for formatted date & time to print
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; line terminator

RTC_GET_BUFFER:
	.FILL	2,0			; Buffer for formatted NVRAM data to print
	.DB	0Ah, 0Dh		; line feed and carriage return
	.DB	"$"			; line terminator

BIOERR		.TEXT	"\r\nUnknown BIOS, aborting...\r\n$"
PLTERR		.TEXT	"\r\n\r\nUnknown/unsupported hardware platform, aborting...\r\n$"
UBERR		.TEXT	"\r\nUNA UBIOS is not currently supported, aborting...\r\n$"
HBTAG		.TEXT	"RomWBW HBIOS$"
UBTAG		.TEXT	"UNA UBIOS"
BOOTMSG		.TEXT	"\r\n\r\nRebooting...$"
PLT_SBC		.TEXT	", SBC/Zeta RTC Latch Port 0x70\r\n$"
PLT_N8		.TEXT	", N8 RTC Latch Port 0x88\r\n$"
PLT_MK4		.TEXT	", Mark 4 RTC Latch Port 0x8A\r\n$"
PLT_RCZ80	.TEXT	", RCBus Z80 RTC Module Latch Port 0xC0\r\n$"
PLT_RCZ180	.TEXT	", RCBus Z180 RTC Module Latch Port 0x0C\r\n$"
PLT_EZZ80	.TEXT	", Easy Z80 RTC Module Latch Port 0xC0\r\n$"
PLT_SCZ180	.TEXT	", SC Z180 RTC Module Latch Port 0x0C\r\n$"
PLT_DYNO	.TEXT	", DYNO RTC Module Latch Port 0x0C\r\n$"
PLT_RCZ280	.TEXT	", RCBus Z280 RTC Module Latch Port 0xC0\r\n$"
PLT_MBC		.TEXT	", MBC RTC Latch Port 0x70\r\n$"
PLT_RPH		.TEXT	", RHYOPHYRE RTC Latch Port 0x84\r\n$"
PLT_DUO		.TEXT	", DUODYNE RTC Latch Port 0x70\r\n$"
PLT_STDZ180 .TEXT ", STD Z180 RTC Module latch port 0x84\r\n$"

;
; Generic FOR-NEXT loop algorithm
;
;	LD	A,$00			; set A=0 index counter of FOR loop
;FOR_LOOP:
;	PUSH	AF			; save accumulator as it is the index counter in FOR loop
;	{ contents of FOR loop here }	; setup RTC with RST and RD high, SCLK low
;	POP	AF			; recover accumulator as it is the index counter in FOR loop
;	INC	A			; increment A in FOR loop (A=A+1)
;	CP	$08			; is A < $08 ?
;	JP	NZ,FOR_LOOP		; No, do FOR loop again
;	RET				; Yes, end function and return.  Read RTC value is in C

YEAR	.DB	$18
MONTH	.DB	$11
DATE	.DB	$08
HOURS	.DB	$00
MINUTES	.DB	$00
SECONDS	.DB	$00
DAY	.DB	$05
GET_PUT	.DB	$00

PUT_ADR	.DB	0

	.END

