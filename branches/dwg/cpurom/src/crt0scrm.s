;--------------------------------------------------------------------------
;  crt0scrm.s 8/7/2011 dwg - - Generic crt0.s for a Z80 with jump loop
;--------------------------------------------------------------------------


	.area	_HEADER (ABS)
	.org 	0

	.include "scsi2ide.inc"
	.include "ns16550.inc"

scream:

        ld      a,#UART_DLAB
        out    (wUART_LCR),a

        ld      a,#0x00
        out    (wUART_DIV_HI),a

        ld      a,#UART_BAUD_9600
        out    (wUART_DIV_LO),a

        ld      a,#0
        out    (wUART_LCR),a

        ld      a,#0x03
        out     (wUART_LCR),a

        ld      a,#0x03
        out     (wUART_MCR),a

scrmlp:
        in      a,(rUART_LSR)
        and     a,#UART_TBE
        jp      z,scrmlp

        ld      a,#0x30  ; ascii 0 (zero)
        out    (wUART_TDR),a

        jp      scrmlp




