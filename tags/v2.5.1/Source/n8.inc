;
; Z180 REGISTERS
;
CPU_BASE	.EQU	40H		; ONLY RELEVANT FOR Z180
;
CPU_CNTLA0	.EQU	CPU_BASE + $00	;ASCI0 control A
CPU_CNTLA1:	.EQU	CPU_BASE+$01	;ASCI1 control A
CPU_CNTLB0:	.EQU	CPU_BASE+$02	;ASCI0 control B
CPU_CNTLB1:	.EQU	CPU_BASE+$03	;ASCI1 control B
CPU_STAT0:	.EQU	CPU_BASE+$04	;ASCI0 status
CPU_STAT1:	.EQU	CPU_BASE+$05	;ASCI1 status
CPU_TDR0:	.EQU	CPU_BASE+$06	;ASCI0 transmit
CPU_TDR1:	.EQU	CPU_BASE+$07	;ASCI1 transmit
CPU_RDR0:	.EQU	CPU_BASE+$08	;ASCI0 receive
CPU_RDR1:	.EQU	CPU_BASE+$09	;ASCI1 receive
CPU_CNTR:	.EQU	CPU_BASE+$0A	;CSI/O control
CPU_TRDR:	.EQU	CPU_BASE+$0B	;CSI/O transmit/receive
CPU_TMDR0L:	.EQU	CPU_BASE+$0C	;Timer 0 data lo
CPU_TMDR0H:	.EQU	CPU_BASE+$0D	;Timer 0 data hi
CPU_RLDR0L:	.EQU	CPU_BASE+$0E	;Timer 0 reload lo
CPU_RLDR0H:	.EQU	CPU_BASE+$0F	;Timer 0 reload hi
CPU_TCR:	.EQU	CPU_BASE+$10	;Timer control
;	
CPU_ASEXT0:	.EQU	CPU_BASE+$12	;ASCI0 extension control (Z8S180)
CPU_ASEXT1:	.EQU	CPU_BASE+$13	;ASCI1 extension control (Z8S180)
;
CPU_TMDR1L:	.EQU	CPU_BASE+$14	;Timer 1 data lo
CPU_TMDR1H:	.EQU	CPU_BASE+$15	;Timer 1 data hi
CPU_RLDR1L:	.EQU	CPU_BASE+$16	;Timer 1 reload lo
CPU_RLDR1H:	.EQU	CPU_BASE+$17	;Timer 1 reload hi
CPU_FRC:	.EQU	CPU_BASE+$18	;Free running counter

CPU_ASTC0L:	.EQU	CPU_BASE+$1A	;ASCI0 Time constant lo (Z8S180)
CPU_ASTC0H:	.EQU	CPU_BASE+$1B	;ASCI0 Time constant hi (Z8S180)
CPU_ASTC1L:	.EQU	CPU_BASE+$1C	;ASCI1 Time constant lo (Z8S180)
CPU_ASTC1H:	.EQU	CPU_BASE+$1D	;ASCI1 Time constant hi (Z8S180)
CPU_CMR:	.EQU	CPU_BASE+$1E	;Clock multiplier (latest Z8S180)
CPU_CCR:	.EQU	CPU_BASE+$1F	;CPU control (Z8S180)
;
CPU_SAR0L:	.EQU	CPU_BASE+$20	;DMA0 source addr lo
CPU_SAR0H:	.EQU	CPU_BASE+$21	;DMA0 source addr hi
CPU_SAR0B:	.EQU	CPU_BASE+$22	;DMA0 source addr bank
CPU_DAR0L:	.EQU	CPU_BASE+$23	;DMA0 dest addr lo
CPU_DAR0H:	.EQU	CPU_BASE+$24	;DMA0 dest addr hi
CPU_DAR0B:	.EQU	CPU_BASE+$25	;DMA0 dest addr bank
CPU_BCR0L:	.EQU	CPU_BASE+$26	;DMA0 byte count lo
CPU_BCR0H:	.EQU	CPU_BASE+$27	;DMA0 byte count hi
CPU_MAR1L:	.EQU	CPU_BASE+$28	;DMA1 memory addr lo
CPU_MAR1H:	.EQU	CPU_BASE+$29	;DMA1 memory addr hi
CPU_MAR1B:	.EQU	CPU_BASE+$2A	;DMA1 memory addr bank
CPU_IAR1L:	.EQU	CPU_BASE+$2B	;DMA1 I/O addr lo
CPU_IAR1H:	.EQU	CPU_BASE+$2C	;DMA1 I/O addr hi
CPU_IAR1B:	.EQU	CPU_BASE+$2D	;DMA1 I/O addr bank (Z8S180)
CPU_BCR1L:	.EQU	CPU_BASE+$2E	;DMA1 byte count lo
CPU_BCR1H:	.EQU	CPU_BASE+$2F	;DMA1 byte count hi
CPU_DSTAT:	.EQU	CPU_BASE+$30	;DMA status
CPU_DMODE:	.EQU	CPU_BASE+$31	;DMA mode
CPU_DCNTL:	.EQU	CPU_BASE+$32	;DMA/WAIT control
CPU_IL:		.EQU	CPU_BASE+$33	;Interrupt vector load
CPU_ITC:	.EQU	CPU_BASE+$34	;INT/TRAP control
;
CPU_RCR:	.EQU	CPU_BASE+$36	;Refresh control
;
CPU_CBR:	.EQU	CPU_BASE+$38	;MMU common base register
CPU_BBR:	.EQU	CPU_BASE+$39	;MMU bank base register
CPU_CBAR	.EQU	CPU_BASE+$3A	;MMU common/bank area register
;
CPU_OMCR:	.EQU	CPU_BASE+$3E	;Operation mode control
CPU_ICR:	.EQU	$3F		;I/O control register (not relocated!!!)
;
; N8 ONBOARD  I/O REGISTERS
;
N8_BASE		.EQU	$80
;
PPIBASE		.EQU	N8_BASE + $00
PPIA		.EQU 	PPIBASE + 0	; PORT A
PPIB		.EQU 	PPIBASE + 1	; PORT B
PPIC		.EQU 	PPIBASE + 2	; PORT C
PPIX	 	.EQU 	PPIBASE + 3	; PPI CONTROL PORT
;
PPI2BASE	.EQU	N8_BASE + $04
PPI2A		.EQU 	PPI2BASE + 0	; PORT A
PPI2B		.EQU 	PPI2BASE + 1	; PORT B
PPI2C		.EQU 	PPI2BASE + 2	; PORT C
PPI2X	 	.EQU 	PPI2BASE + 3	; PPI CONTROL PORT
;
RTC:		.EQU	N8_BASE + $08	;RTC latch and buffer
;FDC:		.EQU	N8_BASE + $0C	;Floppy disk controller
;UTIL:		.EQU	N8_BASE + $10	;Floppy disk utility 
ACR:		.EQU	N8_BASE + $14	;auxillary control register
RMAP:		.EQU	N8_BASE + $16	;ROM page register
VDP:		.EQU	N8_BASE + $18	;Video Display Processor (TMS9918A)
PSG:		.EQU	N8_BASE + $1C	;Programmable Sound Generator (AY-3-8910)
;
DEFACR		.EQU	$1B
