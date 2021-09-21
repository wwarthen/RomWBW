;
;=======================================================================
; Z180 Internal I/O Ports
;=======================================================================
;
; These are offsets from the Z180 I/O base address.
;
z180_cntla0	.equ	$00	; asci0 control a
z180_cntla1	.equ	$01	; asci1 control a
z180_cntlb0	.equ	$02	; asci0 control b
z180_cntlb1	.equ	$03	; asci1 control b
z180_stat0	.equ	$04	; asci0 status
z180_stat1	.equ	$05	; asci1 status
z180_tdr0	.equ	$06	; asci0 transmit
z180_tdr1	.equ	$07	; asci1 transmit
z180_rdr0	.equ	$08	; asci0 receive
z180_rdr1	.equ	$09	; asci1 receive
z180_cntr	.equ	$0a	; csi/o control
z180_trdr	.equ	$0b	; csi/o transmit/receive
z180_tmdr0l	.equ	$0c	; timer 0 data lo
z180_tmdr0h	.equ	$0d	; timer 0 data hi
z180_rldr0l	.equ	$0e	; timer 0 reload lo
z180_rldr0h	.equ	$0f	; timer 0 reload hi
z180_tcr	.equ	$10	; timer control
;		
z180_asext0	.equ	$12	; asci0 extension control (z8s180)
z180_asext1	.equ	$13	; asci1 extension control (z8s180)
;	
z180_tmdr1l	.equ	$14	; timer 1 data lo
z180_tmdr1h	.equ	$15	; timer 1 data hi
z180_rldr1l	.equ	$16	; timer 1 reload lo
z180_rldr1h	.equ	$17	; timer 1 reload hi
z180_frc	.equ	$18	; free running counter
;
z180_astc0l	.equ	$1a	; asci0 time constant lo (z8s180)
z180_astc0h	.equ	$1b	; asci0 time constant hi (z8s180)
z180_astc1l	.equ	$1c	; asci1 time constant lo (z8s180)
z180_astc1h	.equ	$1d	; asci1 time constant hi (z8s180)
z180_cmr	.equ	$1e	; clock multiplier (latest z8s180)
z180_ccr	.equ	$1f	; cpu control (z8s180)
;	
z180_sar0l	.equ	$20	; dma0 source addr lo
z180_sar0h	.equ	$21	; dma0 source addr hi
z180_sar0b	.equ	$22	; dma0 source addr bank
z180_dar0l	.equ	$23	; dma0 dest addr lo
z180_dar0h	.equ	$24	; dma0 dest addr hi
z180_dar0b	.equ	$25	; dma0 dest addr bank
z180_bcr0l	.equ	$26	; dma0 byte count lo
z180_bcr0h	.equ	$27	; dma0 byte count hi
z180_mar1l	.equ	$28	; dma1 memory addr lo
z180_mar1h	.equ	$29	; dma1 memory addr hi
z180_mar1b	.equ	$2a	; dma1 memory addr bank
z180_iar1l	.equ	$2b	; dma1 i/o addr lo
z180_iar1h	.equ	$2c	; dma1 i/o addr hi
z180_iar1b	.equ	$2d	; dma1 i/o addr bank (z8s180)
z180_bcr1l	.equ	$2e	; dma1 byte count lo
z180_bcr1h	.equ	$2f	; dma1 byte count hi
z180_dstat	.equ	$30	; dma status
z180_dmode	.equ	$31	; dma mode
z180_dcntl	.equ	$32	; dma/wait control
z180_il		.equ	$33	; interrupt vector load
z180_itc	.equ	$34	; int/trap control
;	
z180_rcr	.equ	$36	; refresh control
;	
z180_cbr	.equ	$38	; mmu common base register
z180_bbr	.equ	$39	; mmu bank base register
z180_cbar	.equ	$3a	; mmu common/bank area register
;	
z180_omcr	.equ	$3e	; operation mode control
z180_icr	.equ	$3f	; i/o control register
