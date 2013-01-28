/*
 *
 * ns16550.c
 *
 */

#include "portab.h"

#ifdef SBCV2
#include "sbcv2.h"
#endif

#ifdef SCSI2IDE
#include "scsi2ide.h"
#endif

#include "ns16550.h"

void uart_init(U8 baud)
{
	wUART_LCR    = UART_DLAB;
	wUART_DIV_HI = 0x00;
	wUART_DIV_LO = UART_BAUD_9600;
	wUART_LCR    = 0x03;
	wUART_MCR    = 0x03;
}

U8 uart_conin(void)
{
	while(UART_RDA & rUART_LSR) ;
	return rUART_DATA;
}

void uart_conout(U8 data)
{
	while(UART_TBRE & rUART_LSR) ;
	wUART_DATA = data;
}

/*
 *
 * eof - ns16550.c
 *
 */

