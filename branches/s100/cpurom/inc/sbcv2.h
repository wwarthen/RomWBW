/*
 * sbcv2.h - Macros describing the N8VEM SBC V2
 *
 */

#define SBCV2

/* set i/o base to first block of 32 addresses
   possible are 0x00 0x20 0x40 0x60 0x80 0xA0 0xC0 0xE0
   depending oon setting of dip switches on board
*/

#define SBCV2_IO_BASE 0x00
#define UART_IO_BASE     ( SBCV2_IO_BASE + 0x68 )

__sfr __at (UART_IO_BASE+0) rUART_RBR;
__sfr __at (UART_IO_BASE+0) wUART_THR;
__sfr __at (UART_IO_BASE+0) wUART_DIV_LO;
__sfr __at (UART_IO_BASE+1) wUART_DIV_HI;

__sfr __at (UART_IO_BASE+1) wUART_IER;
__sfr __at (UART_IO_BASE+2) rUART_IIR;
__sfr __at (UART_IO_BASE+3) wUART_LCR;
__sfr __at (UART_IO_BASE+4) wUART_MCR;
__sfr __at (UART_IO_BASE+5) rUART_LSR;
__sfr __at (UART_IO_BASE+6) rUART_MSR;
__sfr __at (UART_IO_BASE+7) wUART_FCR;


#define DISKIO_IDE 0x20

#define DISKIO_FLP 0x30

#define PPORT      0x60

#define MPCL       0x70
__sfr __at (MPCL + 0x08) pMPCL_RAM;
__sfr __at (MPCL + 0x0c) pMPCL_ROM;

#define RAMTARG_CPM  0x2000
#define ROMSTART_CPM 0x0000
#define CCPSIZ_CPM   0x2000

#define LOADER_ORG  0x0000
#define CPM_ORG     0x0A00
#define MON_ORG     0x3800
#define ROM_G       0x5000
#define ROM_F       0x8000
/*
#define VDU_DRV     0xF8100
*/

