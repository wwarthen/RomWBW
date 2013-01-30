; scsi2ide.inc 8/7/2011 dwg - macros describing the N8VEM SCSI2IDE

SCSI2IDE_IO_BASE = 0

UART_IO_BASE     = SCSI2IDE_IO_BASE+16

rUART_RDR        = UART_IO_BASE + 0
wUART_TDR        = UART_IO_BASE + 0
wUART_DIV_LO     = UART_IO_BASE + 0
wUART_DIV_HI     = UART_IO_BASE + 1
wUART_IER        = UART_IO_BASE + 1
rUART_IIR        = UART_IO_BASE + 2
wUART_LCR        = UART_IO_BASE + 3
wUART_MCR        = UART_IO_BASE + 4
rUART_LSR        = UART_IO_BASE + 5
rUART_MSR        = UART_IO_BASE + 6
wUART_FCR        = UART_IO_BASE + 7

; eof - scsi2ide.inc

