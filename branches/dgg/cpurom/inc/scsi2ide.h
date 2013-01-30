/*
 *
 * scsi2ide.h - Macros describing the N8VEM SCSI2IDE
 * Friday July 29, 2011 Douglas W. Goodall
 *
 */

#define SCSI2IDE

/* set i/o base to first block of 32 addresses
   possible are 0x00 0x20 0x40 0x60 0x80 0xA0 0xC0 0xE0
   depending oon setting of dip switches on board
*/

#define SCSI2IDE_IO_BASE 0x00

#define IDE_IO_BASE      ( SCSI2IDE_IO_BASE + 0  )
#define SCSI_IO_BASE     ( SCSI2IDE_IO_BASE + 8  )
#define UART_IO_BASE     ( SCSI2IDE_IO_BASE + 16 )
#define DACK_IO_BASE     ( SCSI2IDE_IO_BASE + 24 )

__sfr __at (UART_IO_BASE+0) rUART_RDR;
__sfr __at (UART_IO_BASE+0) wUART_TDR;
__sfr __at (UART_IO_BASE+0) wUART_DIV_LO;
__sfr __at (UART_IO_BASE+1) wUART_DIV_HI;
__sfr __at (UART_IO_BASE+1) wUART_IER;
__sfr __at (UART_IO_BASE+2) rUART_IIR;
__sfr __at (UART_IO_BASE+3) wUART_LCR;
__sfr __at (UART_IO_BASE+4) wUART_MCR;
__sfr __at (UART_IO_BASE+5) rUART_LSR;
__sfr __at (UART_IO_BASE+6) rUART_MSR;
__sfr __at (UART_IO_BASE+7) wUART_FCR;

__sfr __at (SCSI_IO_BASE+0) rSCSI_CSCSID;
__sfr __at (SCSI_IO_BASE+0) wSCSI_OD;
__sfr __at (SCSI_IO_BASE+1) rwSCSI_IC;
__sfr __at (SCSI_IO_BASE+2) rwSCSI_M;
__sfr __at (SCSI_IO_BASE+3) rwSCSI_TC;
__sfr __at (SCSI_IO_BASE+4) rSCSI_CSCSIBS;
__sfr __at (SCSI_IO_BASE+4) wSCSI_SE;
__sfr __at (SCSI_IO_BASE+5) rSCSI_BS;
__sfr __at (SCSI_IO_BASE+5) wSCSI_SDMAS;
__sfr __at (SCSI_IO_BASE+6) rSCSI_ID;
__sfr __at (SCSI_IO_BASE+6) wSCSI_SDMATR;
__sfr __at (SCSI_IO_BASE+7) rSCSI_RPI;
__sfr __at (SCSI_IO_BASE+7) wSCSI_SDMAIR;

